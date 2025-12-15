/*
//
// Copyright (C) 2019-2021 Jean-François DEL NERO
//
// This file is part of the Pauline control page
//
// Pauline control page may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// Pauline control page is free software; you can redistribute it
// and/or modify  it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Pauline control page is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pauline control page; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
*/

var ws;
var ws2;
var imageTimerVar;

function PaulineConnection()
{
	var ip = location.host;

	var addr = "ws://" + ip + ":8080";
	var addr2 = "ws://" + ip + ":8081";

	/*document.getElementById("txtServer").value = addr;*/

	doConnect(addr,addr2);
}

/* Establish connection. */
function doConnect(addr,addr2)
{
	/* Message to be sent. */
	var msg;

	/* Do connection. */
	ws = new WebSocket(addr);

	/* Register events. */
	ws.onopen = function()
	{
		document.getElementById("taLog").value += ("Connection opened\n");
	};

	/* Deals with messages. */
	ws.onmessage = function (evt)
	{
		var message = evt.data;
		document.getElementById("taLog").value += ("Recv: " + message + "\n");
		
		// Gérer le chargement du fichier drives.script
		if (typeof window.drivesScriptLoading !== 'undefined' && window.drivesScriptLoading) {
			var drivesScriptContentEl = document.getElementById("drives-script-content");
			if (drivesScriptContentEl) {
				// Initialiser le buffer si nécessaire
				if (typeof window.drivesScriptBuffer === 'undefined') {
					window.drivesScriptBuffer = '';
				}
				
				// Ajouter le message au buffer
				// Le message peut contenir plusieurs lignes, on les ajoute telles quelles
				window.drivesScriptBuffer += message;
				
				// Mettre à jour le textarea avec le contenu accumulé
				drivesScriptContentEl.value = window.drivesScriptBuffer;
				
				// Réinitialiser le timer de fin de chargement
				if (window.drivesScriptTimeout) {
					clearTimeout(window.drivesScriptTimeout);
				}
				
				// Si on n'a pas reçu de message depuis 500ms, on considère que le chargement est terminé
				window.drivesScriptTimeout = setTimeout(function() {
					if (window.drivesScriptLoading) {
						window.drivesScriptLoading = false;
						// Analyser le fichier chargé et mettre à jour la console si la fonction existe
						if (typeof parseDrivesScript === 'function' && window.drivesScriptBuffer && window.drivesScriptBuffer.trim() !== '') {
							parseDrivesScript(window.drivesScriptBuffer);
						}
						// Nettoyer le buffer après un court délai
						setTimeout(function() {
							window.drivesScriptBuffer = '';
						}, 2000);
					}
				}, 500);
			}
		}
	};

	ws.onclose = function()
	{
		document.getElementById("taLog").value += ("Connection closed\n");
	};
	
	ws.onerror = function(error)
	{
		document.getElementById("taLog").value += ("Connection error\n");
	};

	/* Do connection. */
	ws2 = new WebSocket(addr2);

	/* Register events. */
	ws2.onopen = function()
	{
		imageTimerVar = setInterval(imageTimer, 250);
	};

	/* Deals with messages. */
	ws2.onmessage = function (evt)
	{
		var img = document.getElementById("imageAnalysis");
		var urlObject = URL.createObjectURL(evt.data);
		img.src = urlObject;
	};

	ws2.onclose = function()
	{
		clearInterval(imageTimerVar);
	};

}

function imageTimer() {
	ws2.send("get_image\n");
}

function updatepreviewsettings()
{
	var log = document.getElementById("taLog").value;
	var txt = "setpreviewimagesettings" + " " + (document.getElementById("graphtimexselection").value * 1000).toString()
										+ " " + document.getElementById("graphtimeyselection").value.toString()
										+ " " + (document.getElementById("graphoffsetxselection").value * 1000).toString()
										+ " " + (document.getElementById("ckbHIGHCONTRAST").checked + 0).toString()
										+ " " + (document.getElementById("ckbFATDOTS").checked + 0).toString()
										+ "\n";
	//alert(txt);
	if (typeof ws !== 'undefined')
	{
		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	}
};

function updatedecoders()
{
	var log = document.getElementById("taLog").value;
	var txt = "setpreviewimagedecoders" + " ";

	if(document.getElementById("ckbISOMFM").checked)
	{
		txt += " ISOMFM";
	}

	if(document.getElementById("ckbISOFM").checked)
	{
		txt += " ISOFM";
	}

	if(document.getElementById("ckbAMIGAMFM").checked)
	{
		txt += " AMIGAMFM";
	}

	if(document.getElementById("ckbAPPLE").checked)
	{
		txt += " APPLE";
	}

	if(document.getElementById("ckbEEMU").checked)
	{
		txt += " EEMU";
	}

	if(document.getElementById("ckbTYCOM").checked)
	{
		txt += " TYCOM";
	}

	if(document.getElementById("ckbMEMBRAIN").checked)
	{
		txt += " MEMBRAIN";
	}

	if(document.getElementById("ckbARBURG").checked)
	{
		txt += " ARBURG";
	}

	if(document.getElementById("ckbAED6200P").checked)
	{
		txt += " AED6200P";
	}

	if(document.getElementById("ckbNORTHSTAR").checked)
	{
		txt += " NORTHSTAR";
	}

	if(document.getElementById("ckbHEATHKIT").checked)
	{
		txt += " HEATHKIT";
	}

	if(document.getElementById("ckbDECRX02").checked)
	{
		txt += " DECRX02";
	}

	if(document.getElementById("ckbC64").checked)
	{
		txt += " C64";
	}

	if(document.getElementById("ckbVictor9K").checked)
	{
		txt += " VICTOR9K";
	}

	if(document.getElementById("ckbQDMO5").checked)
	{
		txt += " QD_MO5";
	}

	txt += "\n";

	//alert(txt);
	if (typeof ws !== 'undefined')
	{
		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	}
};

document.addEventListener("DOMContentLoaded", function(event)
{
/*
	document.getElementById("btConn").onclick = function()
	{
		var txt = document.getElementById("txtServer").value;
		doConnect(txt);
	};
*/

	var element = document.getElementById("btMsg");
	if( element )
	{
		element.onclick = function()
		{
			var txt = document.getElementById("txtMsg").value;
			var log = document.getElementById("taLog").value;

			ws.send(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	}

	var element = document.getElementById("btReboot");
	if( element )
	{
		element.onclick = function()
		{
			if (!confirm('Are you sure you want to reboot the DE10?\n\nThis action will interrupt all ongoing operations.')) {
				return;
			}
			
			// Vérifier que la connexion WebSocket est établie
			if (typeof ws === 'undefined' || !ws || ws.readyState !== WebSocket.OPEN) {
				alert('WebSocket connection not established. Please wait for connection.');
				return;
			}
			
			var txt = "system reboot\n";
			ws.send(txt);
			
			// Écrire dans taLog si l'élément existe
			var taLog = document.getElementById("taLog");
			if (taLog) {
				taLog.value += ("Send: " + txt + "\n");
			}
			
			alert('Reboot command sent. The DE10 will reboot in a few moments.');
		};
	};

	var element = document.getElementById("btHalt");
	if( element )
	{
		element.onclick = function()
		{
			var txt = "system halt\n";
			var log = document.getElementById("taLog").value;

			ws.send(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	/* dump functions */
	var element = document.getElementById("btRecalibrate");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "recalibrate " + document.getElementById("drives-select").value.toString() + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btMove");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString()
			                      + " " + document.getElementById("trackselection").value.toString()
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btMoveUp");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "headstep" + " " + document.getElementById("drives-select").value.toString()
			                     + " " + "1"
			                     + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                     + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btMoveDown");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "headstep" + " " + document.getElementById("drives-select").value.toString()
			                     + " " + "-1"
			                     + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                     + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btCLEANDISKII");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "35"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "0"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "35"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "0"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btCLEANPC");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "82"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "0"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "82"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + "0"
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btautodetect");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			
			// Version simplifiée : la commande system utilise maintenant popen()
			// et envoie automatiquement la sortie en temps réel via WebSocket
			// 2>&1 redirige stderr vers stdout pour capturer aussi les erreurs
			var txt = "system pauline -autodetect 2>&1\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btTestMaxTrack");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var drive = document.getElementById("drives-select").value.toString();
			
			// Version simplifiée : la commande system utilise maintenant popen()
			// et envoie automatiquement la sortie en temps réel via WebSocket
			// 2>&1 redirige stderr vers stdout pour capturer aussi les erreurs
			var txt = "system pauline -testmaxtrack -drive " + drive + " 2>&1\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btONPIN16");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "setio DRIVES_PORT_PIN16";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btOFFPIN16");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "cleario DRIVES_PORT_PIN16";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btONPIN10");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "setio DRIVES_PORT_PIN10";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btOFFPIN10");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "cleario DRIVES_PORT_PIN10";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btONPIN14");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "setio DRIVES_PORT_PIN14";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btOFFPIN14");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "cleario DRIVES_PORT_PIN14";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btONPIN12");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "setio DRIVES_PORT_PIN12";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btOFFPIN12");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "cleario DRIVES_PORT_PIN12";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};
	var element = document.getElementById("btStop");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "stop\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btEject");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "ejectdisk " + document.getElementById("drives-select").value.toString() + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("ckbALTRPM");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;

			if( document.getElementById("ckbALTRPM").checked )
			{
				var txt = "setio DRIVES_PORT_PIN02_OUT\n";
			}
			else
			{
				var txt = "cleario DRIVES_PORT_PIN02_OUT\n";
			}

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btReadTrack");
	if( element )
	{
		element.onclick = function()
		{
			// Validation du profil archiviste
			if (typeof validateDumpForm === 'function' && !validateDumpForm()) {
				return;
			}
			
			var log = document.getElementById("taLog").value;
			var txt = "index_to_dump" + " " + document.getElementById("txtIndexToDumpDelay").value.toString()
									  + "\n";

			txt += "dump_time" + " "  + document.getElementById("txtTrackDumpLenght").value.toString()
									  + "\n";

			if( document.getElementById("ckbAutoIndex").checked )
			{
				var mode = "AUTO_INDEX_NAME";
				var startindex = 1;

			}
			else
			{
				var mode = "MANUAL_INDEX_NAME";
				var startindex = document.getElementById("txtDumpStartIndex").value.toString();
			}

			txt += "dump" + " " + document.getElementById("drives-select").value.toString() + " -1 -1"
						  + " " + document.getElementById("headselection").value.toString()
						  + " " + document.getElementById("headselection").value.toString()
						  + " " + (document.getElementById("ckb50Mhz").checked + 0).toString()
						  + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
						  + " " + (document.getElementById("ckbIGNOREINDEX").checked + 0).toString()
						  + " " + "0"
						  + " " + "\"" + document.getElementById("txtDumpName").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment").value.toString() + "\""
						  + " " + startindex
						  + " " + mode
						  + " " + "\"" + document.getElementById("txtDriveInfos").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpOperator").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment2").value.toString() + "\""
						  + "\n";

			//alert(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");

			ws.send(txt);

		};
	};

	var element = document.getElementById("graphtimexselection");
	if( element )
	{
		element.onmouseup = function()
		{
			updatepreviewsettings();
		};
		element.ontouchend = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("graphoffsetxselection");
	if( element )
	{
		element.onmouseup = function()
		{
			updatepreviewsettings();
		};
		element.ontouchend = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("graphtimeyselection");
	if( element )
	{
		element.onmouseup = function()
		{
			updatepreviewsettings();
		};
		element.ontouchend = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("ckbHIGHCONTRAST");
	if( element )
	{
		element.onclick = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("ckbISOMFM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbISOFM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbAMIGAMFM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbAPPLE");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbEEMU");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbTYCOM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbMEMBRAIN");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbARBURG");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbAED6200P");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbNORTHSTAR");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbHEATHKIT");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbDECRX02");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbFATDOTS");
	if( element )
	{
		element.onclick = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("btReadDisk");
	if( element )
	{
		element.onclick = function()
		{
			// Validation du profil archiviste
			if (typeof validateDumpForm === 'function' && !validateDumpForm()) {
				return;
			}
			
			var log = document.getElementById("taLog").value;
			var txt = "index_to_dump" + " " + document.getElementById("txtIndexToDumpDelay").value.toString()
									  + "\n";

			txt += "dump_time" + " "  + document.getElementById("txtTrackDumpLenght").value.toString()
									  + "\n";

			if( document.getElementById("ckbAutoIndex").checked )
			{
				var mode = "AUTO_INDEX_NAME";
				var startindex = 1;
			}
			else
			{
				var mode = "MANUAL_INDEX_NAME";
				var startindex = document.getElementById("txtDumpStartIndex").value.toString();
			}

			txt += "dump" + " " + document.getElementById("drives-select").value.toString()
						  + " " + document.getElementById("txtDumpMinTrack").value.toString()
						  + " " + document.getElementById("txtDumpMaxTrack").value.toString()
						  + " " + ( (document.getElementById("ckbSIDE0").checked + 0) ^ 1).toString()
						  + " " + (document.getElementById("ckbSIDE1").checked + 0).toString()
						  + " " + (document.getElementById("ckb50Mhz").checked + 0).toString()
						  + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
						  + " " + (document.getElementById("ckbIGNOREINDEX").checked + 0).toString()
						  + " " + "0"
						  + " " + "\"" + document.getElementById("txtDumpName").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment").value.toString() + "\""
						  + " " + startindex
						  + " " + mode
						  + " " + "\"" + document.getElementById("txtDriveInfos").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpOperator").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment2").value.toString() + "\""
						  + "\n";

			//alert(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");

			ws.send(txt);

		};
	};

});

