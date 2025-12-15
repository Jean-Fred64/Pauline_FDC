/*
//
// Copyright (C) 2019-2023 Jean-François DEL NERO
//
// This file is part of the Pauline control software
//
// Pauline control software may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// Pauline control software is free software; you can redistribute it
// and/or modify  it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Pauline control software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pauline control software; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>

#include <stdint.h>

#include "libhxcfe.h"

#include "streamhfe_format.h"
#include "fpga.h"

#include "lz4.h"

int getbit(unsigned char * input_data,int bit_offset)
{
	return ( ( input_data[bit_offset>>3] >> ( 0x7 - (bit_offset&0x7) ) ) ) & 0x01;
}

void setbit(unsigned char * input_data,int bit_offset,int state)
{
	if(state)
	{
		input_data[bit_offset>>3] = (unsigned char)( input_data[bit_offset>>3] |  (0x80 >> ( bit_offset&0x7 ) ) );
	}
	else
	{
		input_data[bit_offset>>3] = (unsigned char)( input_data[bit_offset>>3] & ~(0x80 >> ( bit_offset&0x7 ) ) );
	}

	return;
}

int decodestream(fpga_state * state, int drive, streamhfe_track_def * trackdef, unsigned char * unpacked_data, int track, int side)
{
	unsigned int k,l;
	uint16_t *tmp_ptr;
	unsigned char c;
	uint32_t pulses_count;
	uint32_t tmp_dword,cumul;
	uint32_t track_size,trackbase;
	//uint32_t index_position[16];
	//unsigned int p;

	//index_position[0] = 0;

	pulses_count = trackdef->nb_pulses;

	if( pulses_count )
	{
		//p = 0;

		track_size = state->regs->image_track_size_reg[drive];
		trackbase = (track_size/sizeof(unsigned short)) * track;
		tmp_ptr = (uint16_t * )&state->disk_image[drive][trackbase+side];

		if(tmp_ptr)
		{
			k = 0;
			l = 0;
			cumul = 0;
			while(l < pulses_count )
			{
				c = unpacked_data[k++];

				if( !(c & 0x80) )
				{
					cumul += c;
				}
				else
				{
					if( (c & 0xC0) == 0x80 )
					{
						tmp_dword = (((uint32_t)(c & 0x3F) << 8) | unpacked_data[k++]);
						cumul += tmp_dword;
					}
					else
					{
						if( (c & 0xE0) == 0xC0 )
						{
							tmp_dword =  ((uint32_t)(c & 0x1F) << 16);
							tmp_dword |= ((uint32_t)unpacked_data[k++]<<8);
							tmp_dword |= ((uint32_t)unpacked_data[k++]<<0);

							cumul += tmp_dword;
						}
						else
						{
							if( (c & 0xF0) == 0xE0 )
							{
								tmp_dword =  ((uint32_t)(c & 0x0F) << 24);
								tmp_dword |= ((uint32_t)unpacked_data[k++]<<16);
								tmp_dword |= ((uint32_t)unpacked_data[k++]<<8);
								tmp_dword |= ((uint32_t)unpacked_data[k++]<<0);

								cumul += tmp_dword;
							}
							else
							{

							}
						}
					}
				}

				tmp_ptr[(cumul>>4)<<1] |= (0x8000 >> ( cumul&0xF ) );

				l++;
			}

			//index_position[r] = p;
		}
	}

	return 0;
}

unsigned short * load_stream_hfe(fpga_state * state,int drive, char * imgfile, int * tracksize,int * numberoftracks,int double_step)
{
	int i,j,track_array_index;
	FILE * f;
	streamhfe_fileheader header;
	streamhfe_track_def * trackoffsetlist;
	unsigned char * packed_track_data;
	unsigned char * unpacked_track;

	if(!state)
		return NULL;

	f = fopen(imgfile,"rb");
	if( f == NULL )
	{
		printf("Cannot open %s !\n",imgfile);
		return NULL;
	}

	if( fread(&header,sizeof(header),1,f) != 1)
	{
		printf("Cannot read %s !\n",imgfile);
		return NULL;
	}

	if(!strncmp((char*)header.signature,"HxC_Stream_Image",16))
	{
		trackoffsetlist = (streamhfe_track_def*)malloc(sizeof(streamhfe_track_def) * (header.number_of_track*header.number_of_side));
		if(!trackoffsetlist)
			goto error;

		memset( trackoffsetlist, 0, sizeof(streamhfe_track_def) * (header.number_of_track*header.number_of_side));
		fseek( f,header.track_list_offset,SEEK_SET);
		if(fread( trackoffsetlist, sizeof(streamhfe_track_def) * (header.number_of_track*header.number_of_side), 1, f) != 1)
			goto error;

		state->regs->image_track_size_reg[drive] = (trackoffsetlist[0].track_len / 8) * 2;

		index_cfg(state, drive, state->hardsector_count[drive], state->separate_hardsector_signal, (((int)( (float)(BIT_CLOCK/16) * ((float)state->index_len/(float)1000) ) / 1000 ) * 4) );

		alloc_image(state, drive, (trackoffsetlist[0].track_len / 8) * 2, header.number_of_track + 2, state->regs->image_base_address_reg[drive],1);

		for(j=0;j<header.number_of_track;j++)
		{
			for(i=0;i<header.number_of_side;i++)
			{
				printf("Load Track %.3d.%d\n",j,i);

				if(header.number_of_side==2)
					track_array_index = (j<<1) | (i&1);
				else
					track_array_index = j;

				fseek(f, trackoffsetlist[track_array_index].packed_data_offset,SEEK_SET);

				if(trackoffsetlist[track_array_index].packed_data_size)
				{
					packed_track_data = malloc(trackoffsetlist[track_array_index].packed_data_size);
					if(!packed_track_data)
						goto error;

					if(fread(packed_track_data,trackoffsetlist[track_array_index].packed_data_size,1,f)!=1)
						goto error;

					//Unpack data...
					unpacked_track = malloc(trackoffsetlist[track_array_index].unpacked_data_size);
					if(!unpacked_track)
						goto error;

					LZ4_decompress_safe ((const char*)packed_track_data, (char*)unpacked_track, trackoffsetlist[track_array_index].packed_data_size, trackoffsetlist[track_array_index].unpacked_data_size);

					decodestream(state, drive, &trackoffsetlist[track_array_index], unpacked_track, j, i);

					free(unpacked_track);
					free(packed_track_data);
				}

			}
		}

		state->regs->drive_config[drive] |= CFG_DISK_IN_DRIVE;

		if(double_step)
			state->regs->drive_config[drive] |= CFG_DISK_DOUBLE_STEP;
		else
			state->regs->drive_config[drive] &= ~CFG_DISK_DOUBLE_STEP;

		free(trackoffsetlist);
		fclose(f);
		return (unsigned short*)1; // Success
	}
	else
	{
		printf("Invalid header ! (%s)\n",imgfile);
		fclose(f);
		return NULL;
	}

error:
	if(trackoffsetlist)
		free(trackoffsetlist);
	if(f)
		fclose(f);
	return NULL;
}

// Vérifie si un fichier est au format HXC_STREAMHFE
int is_streamhfe_format(const char *filename)
{
	FILE *f;
	streamhfe_fileheader header;
	int is_valid = 0;
	
	if (!filename)
		return 0;
	
	f = fopen(filename, "rb");
	if (!f)
		return 0;
	
	if (fread(&header, sizeof(header), 1, f) == 1)
	{
		if (!strncmp((char*)header.signature, "HxC_Stream_Image", 16))
		{
			is_valid = 1;
		}
	}
	
	fclose(f);
	return is_valid;
}

// Convertit un fichier image vers le format HXC_STREAMHFE
int convert_to_streamhfe(HXCFE* hxcfe, const char *infile, const char *outfile)
{
	int loaderid;
	int ret;
	HXCFE_FLOPPY *floppydisk;
	HXCFE_IMGLDR *imgldr_ctx;
	
	if (!hxcfe)
	{
		printf("Error: libhxcfe not initialized\n");
		return -1;
	}
	
	if (!infile || !outfile)
	{
		printf("Error: Invalid file parameters\n");
		return -1;
	}
	
	imgldr_ctx = hxcfe_imgInitLoader(hxcfe);
	if (!imgldr_ctx)
	{
		printf("Error: Cannot initialize image loader\n");
		return -1;
	}
	
	// Détection automatique du format d'entrée
	loaderid = hxcfe_imgAutoSetectLoader(imgldr_ctx, infile, 0);
	if (loaderid < 0)
	{
		printf("Error: Cannot detect input file format: %s\n", infile);
		hxcfe_imgDeInitLoader(imgldr_ctx);
		return -1;
	}
	
	// Chargement du fichier
	floppydisk = hxcfe_imgLoad(imgldr_ctx, infile, loaderid, &ret);
	if (ret != HXCFE_NOERROR || !floppydisk)
	{
		printf("Error: Cannot load image file: %s (error: %d)\n", infile, ret);
		hxcfe_imgDeInitLoader(imgldr_ctx);
		return -1;
	}
	
	// Conversion vers HXC_STREAMHFE
	loaderid = hxcfe_imgGetLoaderID(imgldr_ctx, "HXC_STREAMHFE");
	if (loaderid < 0)
	{
		printf("Error: HXC_STREAMHFE loader not available\n");
		hxcfe_imgUnload(imgldr_ctx, floppydisk);
		hxcfe_imgDeInitLoader(imgldr_ctx);
		return -1;
	}
	
	// Export vers le format HXC_STREAMHFE
	ret = hxcfe_imgExport(imgldr_ctx, floppydisk, outfile, loaderid);
	if (ret != HXCFE_NOERROR)
	{
		printf("Error: Cannot export to HXC_STREAMHFE format: %s (error: %d)\n", outfile, ret);
		hxcfe_imgUnload(imgldr_ctx, floppydisk);
		hxcfe_imgDeInitLoader(imgldr_ctx);
		return -1;
	}
	
	hxcfe_imgUnload(imgldr_ctx, floppydisk);
	hxcfe_imgDeInitLoader(imgldr_ctx);
	
	printf("Successfully converted %s to %s (HXC_STREAMHFE format)\n", infile, outfile);
	return 0;
}

// Charge un fichier image avec conversion automatique si nécessaire
unsigned short * load_stream_hfe_with_conversion(fpga_state * state, int drive, 
                                                  char * imgfile, int * tracksize, 
                                                  int * numberoftracks, int double_step)
{
	char temp_file[512];
	unsigned short *result = NULL;
	
	if (!state)
	{
		printf("Error: Invalid state\n");
		return NULL;
	}
	
	if (!imgfile)
	{
		printf("Error: Invalid filename\n");
		return NULL;
	}
	
	// Vérifier si le fichier est déjà au format HXC_STREAMHFE
	if (is_streamhfe_format(imgfile))
	{
		// Charger directement
		return load_stream_hfe(state, drive, imgfile, tracksize, numberoftracks, double_step);
	}
	
	// Le fichier n'est pas au format HXC_STREAMHFE, il faut le convertir
	printf("File %s is not in HXC_STREAMHFE format. Converting...\n", imgfile);
	
	if (!state->libhxcfe)
	{
		printf("Error: libhxcfe not initialized, cannot convert file\n");
		return NULL;
	}
	
	// Créer un nom de fichier temporaire pour la conversion
	snprintf(temp_file, sizeof(temp_file), "/tmp/pauline_convert_%d_%ld.hfe", 
	         drive, (long)time(NULL));
	
	// Convertir vers HXC_STREAMHFE
	if (convert_to_streamhfe(state->libhxcfe, imgfile, temp_file) != 0)
	{
		printf("Error: Conversion failed for %s\n", imgfile);
		return NULL;
	}
	
	// Charger le fichier converti
	result = load_stream_hfe(state, drive, temp_file, tracksize, numberoftracks, double_step);
	
	if (result)
	{
		printf("Successfully loaded converted file: %s\n", temp_file);
		// Optionnel : supprimer le fichier temporaire après chargement réussi
		// Note: On garde le fichier temporaire pour debug, mais on pourrait le supprimer
		// unlink(temp_file);
	}
	else
	{
		printf("Error: Failed to load converted file: %s\n", temp_file);
		// Supprimer le fichier temporaire en cas d'erreur
		unlink(temp_file);
	}
	
	return result;
}

// 0XXXXXXX  < 128
// 10XXXXXX XXXXXXXX < 16K
// 110XXXXX XXXXXXXX XXXXXXXX < 6M
// 1110XXXX XXXXXXXX XXXXXXXX XXXXXXXX < 6M

unsigned char * convert_track(fpga_state * state, int drive, int track, int side, unsigned int * tracksize,unsigned int * outbuffersize, unsigned int * number_of_pulses)
{
	unsigned int j,k;

	unsigned int final_track_len;
	unsigned int oldbitpos,bitpos;

	unsigned char  * data_track;
	unsigned int bits_delta,nb_pulses;
	uint32_t track_size,trackbase;
	uint16_t *tmp_ptr, tmp_data;

	// Track size (both sides ! 4 bytes aligned)
	track_size = state->regs->image_track_size_reg[drive];
	trackbase = (track_size/sizeof(unsigned short)) * track;
	tmp_ptr = (uint16_t * )&state->disk_image[drive][trackbase+side];

	//printf("track %d, side %d, len %d\n",track,side,track_size);

	final_track_len = (track_size*8)/2;

	// 16 bits per side alignement (32 bits per track)
	if(final_track_len & 0xF)
		final_track_len = (final_track_len & ~0xF) + 0x10;

	data_track = malloc(final_track_len);

	if( data_track )
	{
		memset(data_track,0,final_track_len);

		k = 0;
		nb_pulses = 0;

		oldbitpos = 0;

		j = 0;
		do
		{
			tmp_data = tmp_ptr[(j>>4)<<1];

			if( tmp_data )
			{
				if( ( ( tmp_data >> ( 0xF - (j&0xF) ) ) ) & 0x01 )
				{
					bitpos = j;

					bits_delta = bitpos - oldbitpos;

					if( bits_delta < 0x00000080)
					{
						data_track[k++] = bits_delta;
					}
					else
					{
						if( bits_delta < 0x00004000)
						{
							data_track[k++] = 0x80 | (bits_delta>>8);
							data_track[k++] = (bits_delta&0xFF);
						}
						else
						{
							if( bits_delta < 0x00200000)
							{
								data_track[k++] = 0xC0 | (bits_delta>>16);
								data_track[k++] = ((bits_delta>>8)&0xFF);
								data_track[k++] = (bits_delta&0xFF);
							}
							else
							{
								if( bits_delta < 0x10000000)
								{
									data_track[k++] = 0xE0 | (bits_delta>>24);
									data_track[k++] = ((bits_delta>>16)&0xFF);
									data_track[k++] = ((bits_delta>>8)&0xFF);
									data_track[k++] = (bits_delta&0xFF);
								}
								else
								{
									data_track[k++] = 0xE0 | 0x0F;
									data_track[k++] = 0xFF;
									data_track[k++] = 0xFF;
									data_track[k++] = 0xFF;
								}
							}
						}
					}

					nb_pulses++;

					oldbitpos = bitpos;
				}

				j++;
			}
			else
			{
				j += 16;
			}
		}while(j<final_track_len);

		*tracksize = final_track_len;
		*outbuffersize = k;
		*number_of_pulses = nb_pulses;
	}

	return data_track;
}

unsigned char * fast_convert_track(fpga_state * state, int drive, int track, int side, unsigned int * tracksize,unsigned int * outbuffersize, unsigned int * number_of_pulses)
{
	unsigned int j;
	unsigned int final_track_len;
	unsigned char  * data_track, *start_data_track;
	unsigned int bits_delta,nb_pulses;
	uint32_t track_size,trackbase;
	uint16_t *tmp_ptr, tmp_data;
	uint16_t lutval;

	track_size = state->regs->image_track_size_reg[drive]; // Both sides track size : 32 bits aligned (16 bits per sides) - In bytes !
	trackbase = (track_size/sizeof(unsigned short)) * track;
	tmp_ptr = (uint16_t * )&state->disk_image[drive][trackbase+side];

	final_track_len = (track_size/2); // length for one side - must be 16 bits / 2 bytes aligned !

	if(final_track_len & 0x1)
		final_track_len = (final_track_len & ~0x1) + 0x1;

	data_track = malloc(final_track_len);
	start_data_track = data_track;

	if( data_track )
	{
		nb_pulses = 0;
		bits_delta = 0;

		j = 0;
		do
		{
			tmp_data = *tmp_ptr;
			tmp_ptr += 2;

			if(!tmp_data)
			{
				bits_delta += 16;
			}
			else
			{
				lutval = state->conv_lut[tmp_data];
				if(lutval)
				{
					bits_delta += (lutval>>8);

					if( bits_delta < 0x00000080)
					{
						*data_track++ = bits_delta;
					}
					else
					{
						if( bits_delta < 0x00004000)
						{
							*data_track++ = 0x80 | (bits_delta>>8);
							*data_track++ = (bits_delta&0xFF);
						}
						else
						{
							if( bits_delta < 0x00200000)
							{
								*data_track++ = 0xC0 | (bits_delta>>16);
								*data_track++ = ((bits_delta>>8)&0xFF);
								*data_track++ = (bits_delta&0xFF);
							}
							else
							{
								if( bits_delta < 0x10000000)
								{
									*data_track++ = 0xE0 | (bits_delta>>24);
									*data_track++ = ((bits_delta>>16)&0xFF);
									*data_track++ = ((bits_delta>>8)&0xFF);
									*data_track++ = (bits_delta&0xFF);
								}
								else
								{
									*data_track++ = 0xE0 | 0x0F;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
								}
							}
						}
					}

					bits_delta = (lutval&0xFF);
					nb_pulses++;
				}
				else
				{

					if( bits_delta < 0x00000080)
					{
						*data_track++ = bits_delta;
					}
					else
					{
						if( bits_delta < 0x00004000)
						{
							*data_track++ = 0x80 | (bits_delta>>8);
							*data_track++ = (bits_delta&0xFF);
						}
						else
						{
							if( bits_delta < 0x00200000)
							{
								*data_track++ = 0xC0 | (bits_delta>>16);
								*data_track++ = ((bits_delta>>8)&0xFF);
								*data_track++ = (bits_delta&0xFF);
							}
							else
							{
								if( bits_delta < 0x10000000)
								{
									*data_track++ = 0xE0 | (bits_delta>>24);
									*data_track++ = ((bits_delta>>16)&0xFF);
									*data_track++ = ((bits_delta>>8)&0xFF);
									*data_track++ = (bits_delta&0xFF);
								}
								else
								{
									*data_track++ = 0xE0 | 0x0F;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
									*data_track++ = 0xFF;
								}
							}
						}
					}

					bits_delta = 0;
					nb_pulses++;
				}
			}

			j += 2;

		}while(j<final_track_len);

		*tracksize = (final_track_len * 8);
		*outbuffersize = (unsigned int)(data_track - start_data_track);
		*number_of_pulses = nb_pulses;
	}

	return start_data_track;
}

int save_stream_hfe(fpga_state * state,int drive, char * imgfile)
{
	streamhfe_fileheader * FILEHEADER;
	streamhfe_track_def * tracks_def;

	FILE * hxcstreamhfefile;
	unsigned int i,j,packedsize;
	unsigned int tracklistlen;
	unsigned char * stream_track;
	unsigned char * packed_track;
	unsigned int stream_track_size;
	unsigned int track_size,number_of_pulses;
	unsigned char tempbuf[512];
	unsigned int max_packed_size,track_index;

	if(!state)
		return 0;

	if(!state->regs->image_max_track_reg[drive])
	{
		printf("Error : Cannot create zero track HFE file");
		return 0;
	}

	hxcstreamhfefile = fopen(imgfile,"wb");
	if( hxcstreamhfefile == NULL )
	{
		printf("Cannot create %s !\n",imgfile);
		return 0;
	}

	FILEHEADER=(streamhfe_fileheader *) malloc(512);
	memset(FILEHEADER,0x00,512);
	memcpy(&FILEHEADER->signature,"HxC_Stream_Image",16);
	FILEHEADER->formatrevision = 0;

	FILEHEADER->flags = 0x00000000;
	FILEHEADER->number_of_track = (unsigned char)state->regs->image_max_track_reg[drive];
	FILEHEADER->number_of_side = 2;
	FILEHEADER->bits_period = DEFAULT_BITS_PERIOD;

	FILEHEADER->floppyinterfacemode = (unsigned char)0;

	//FILEHEADER->flags |= STREAMHFE_HDRFLAG_SINGLE_SIDE;
	//FILEHEADER->flags |= STREAMHFE_HDRFLAG_DOUBLE_STEP;

	fwrite(FILEHEADER,512,1,hxcstreamhfefile);

	FILEHEADER->track_list_offset = ftell(hxcstreamhfefile);

	tracklistlen=((((((FILEHEADER->number_of_track * FILEHEADER->number_of_side)+1)*sizeof(streamhfe_track_def))/512)+1));

	tracks_def = (streamhfe_track_def *) malloc(tracklistlen*512);
	memset(tracks_def,0x00,tracklistlen*512);
	fwrite(tracks_def,tracklistlen*512,1,hxcstreamhfefile);

	//-----------------------------------------------------

	FILEHEADER->index_array_offset = ftell(hxcstreamhfefile);

	memset(&tempbuf,0,512);
	fwrite(&tempbuf,512,1,hxcstreamhfefile);

	//-----------------------------------------------------
	FILEHEADER->track_data_offset = ftell(hxcstreamhfefile);

	alloc_image(state, drive, 0, 0 , 0 ,0);

	//printf("%d tracks, %d sides\n",FILEHEADER->number_of_track,FILEHEADER->number_of_side);

	i=0;
	while(i<(FILEHEADER->number_of_track))
	{
		j=0;
		while(j<(FILEHEADER->number_of_side))
		{
			printf("Save Track %.3d.%d\n",i,j);

			track_size = 0;

			if(FILEHEADER->number_of_side==2)
				track_index = (i<<1) | (j&1);
			else
				track_index = i;

			tracks_def[track_index].flags = STREAMHFE_TRKFLAG_PACKED;
			tracks_def[track_index].packed_data_offset = ftell(hxcstreamhfefile);
			stream_track_size = 0;

			packedsize = 0;
			number_of_pulses = 0;

			//stream_track = convert_track(state, drive, i, j, &track_size, &stream_track_size, &number_of_pulses);
			stream_track = fast_convert_track(state, drive, i, j, &track_size, &stream_track_size, &number_of_pulses);
			if(stream_track)
			{
				max_packed_size = LZ4_compressBound(stream_track_size);
				packed_track = malloc(max_packed_size);
				packedsize = LZ4_compress_default((const char*)stream_track, (char*)packed_track, stream_track_size, max_packed_size);

				//packedsize = stream_track_size;
				//memcpy( (char*)packed_track , (const char*)stream_track, packedsize);

				fwrite(packed_track,packedsize,1,hxcstreamhfefile);

				free(stream_track);
				free(packed_track);
			}

			tracks_def[track_index].packed_data_size = packedsize;
			tracks_def[track_index].unpacked_data_size = stream_track_size;
			tracks_def[track_index].track_len = track_size;
			tracks_def[track_index].nb_pulses = number_of_pulses;

			j++;
		}

		i++;
	}

	fseek( hxcstreamhfefile, FILEHEADER->track_list_offset, SEEK_SET );
	fwrite(tracks_def,tracklistlen*512,1,hxcstreamhfefile);

	fseek( hxcstreamhfefile, 0, SEEK_SET );
	fwrite(FILEHEADER,512,1,hxcstreamhfefile);

	fclose(hxcstreamhfefile);

	printf("%d tracks written to %s\n", FILEHEADER->number_of_track, imgfile);

	free(FILEHEADER);

	return 0;

////////////////////////////////////////:
}

