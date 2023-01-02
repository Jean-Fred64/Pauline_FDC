# Commandes SSH Pauline floppy drive simulator

```
/home/pauline/Drives_Simulation # pauline -help
HxC Floppy Emulator : Pauline floppy drive simulator / floppy drive dumper control software v1.3.3.1
Copyright (C) 2006-2021 Jean-Francois DEL NERO
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute it
under certain conditions;

Options:
  -help                         : This help
  -license                      : Print the license
  -verbose                      : Verbose mode
  -home_folder:[path]           : Set the base folder
  -initscript:[path]            : Set the init script path
  -reset                        : FPGA reset
  -drive:[drive nb]             : select the drive number
  -load:[filename]              : load the a image
  -save:[filename]              : Save the a image
  -headrecal                    : recalibrate the head
  -headstep:[tracknb][          : move the head
  -selsrc:[id]                  : drive simulation select source line
  -motsrc:[id]                  : drive simulation motor source line
  -pin02mode:[id]               : drive simulation pin 2 status line mode
  -pin34mode:[id]               : drive simulation pin 34 status line mode
  -writeprotectdrive:[0/1]      : drive simulation write protect (0 or 1)
  -enabledrive                  : drive enable
  -disabledrive                 : drive disable
  -finput:[filename]            : Input file image
  -foutput:[filename]           : Output file image
  -readdsk                      : Read a Disk
  -writedsk                     : Write a Disk
  -highres                      : High sampling rate (50Mhz/20ns instead of 25Mhz/40ns)
  -start_track:[side number]    : Disk dump : first track number (default 0)
  -max_track:[side number]      : Disk dump : last track number (default 79)
  -start_side:[side number]     : Disk dump : first side number (default 0)
  -max_side:[side number]       : Disk dump : last side number (default 1)
  -track_rd_time:[time (ms)]    : Disk dump : track dump duration (ms) (default 800ms)
  -after_index_delay:[time (us)]: Disk dump : index to track dump delay (us) (default 100000us)
  -autodetect                   : drives auto-detection
  -testmaxtrack                 : drives max track auto-detection
  -set:[io name]
  -clear:[io name]
  -get:[io name]
  -led1src / led2src:[io name]
  -ioslist
  -ejectdisk
  -setiohigh:[io number]
  -setiolow:[io number]
  -setiohz:[io number]
  -sound:[frequency]
  -test_interface

Drive Simulation select lines ID (-selsrc & -motsrc ID):
  0 : Always deasserted
  1 : Always asserted
  8 : SEL0/MOTEA  (Pin 10)
  9 : SEL1/DRVSB  (Pin 12)
  10: SEL2/DRVSA  (Pin 14)
  11: SEL3        (Pin 6)
  12: MTRON/MOTEB (Pin 16)
  13: EXTERNAL IO (J5 - Pin 4)

Drive Simulation status lines ID (-pin02mode & -pin34mode ID):
  0 : Low state
  1 : High state
  2 : nReady
  3 : Ready
  4 : nDensity
  5 : Density
  6 : nDiskChange (mode 1 : Head step clear)
  7 : DiskChange  (mode 1 : Head step clear)
  8 : nDiskChange (mode 2 : Head step clear + timer/timeout clear)
  9 : DiskChange  (mode 2 : Head step clear + timer/timeout clear)
  10: nDiskChange (mode 3 : timer/timeout clear)
  11: DiskChange  (mode 3 : timer/timeout clear)
  12: nDiskChange (mode 4 : floppy_dc_reset input clear)
  13: DiskChange  (mode 4 : floppy_dc_reset input clear)

Signal input mux (-led1src & -led2src ID):
  0 : LED gpio register
  1 : Floppy pin 10 drive 0 selection output
  2 : Floppy pin 12 drive 1 selection output
  3 : Floppy pin 14 drive 2 selection output
  4 : Floppy pin 6  drive 3 selection output
  5 : Floppy pin 16 Motor on output
  6 : Floppy step output
  7 : Floppy dir output
  8 : Floppy side1 output
  9 : Floppy index input
 10 : Floppy pin 2 input
 11 : Floppy pin 34 input
 12 : Floppy write protect input
 13 : Floppy data input
 14 : Floppy write gate output
 15 : Floppy write data output
 16 : Host pin 10 / sel 0 input
 17 : Host pin 12 / sel 1 input
 18 : Host pin 14 / sel 2 input
 19 : Host pin 16 / sel 3 input
 20 : Host pin 6  / mot on input
 21 : Host step input
 22 : Host dir input
 23 : Host side1 input
 24 : Host write gate input
 25 : Host write data input
 26 : IO input 0
 27 : IO input 1
 28 : IO input 2
 29 : IO input 3
 30 : IO input 4
 31 : IO input 5
```

Drive on PIN14/DS2/DRVSA found !!! Samsung 3.5"  

-----

*00:09 mardi 9 février 2021*
### Pour la simulation : 
**1 ere étape** : convertir le fichier image en stream hfe :
```
hxcfe -conv:HXC_STREAMHFE -finput:monfichier.img
```  
**2 eme étape** chargement en mémoire de l'image et activation de la simulation :
```
pauline -reset -load:dos7.hfe -drive:0 -selsrc:9 -motsrc:12 -enabledrive
```  
avec 
```
Drive Simulation select lines ID (-selsrc & -motsrc ID):
  0 : Always deasserted
  1 : Always asserted
  8 : SEL0/MOTEA  (Pin 10)
  9 : SEL1/DRVSB  (Pin 12)
  10: SEL2/DRVSA  (Pin 14)
  11: SEL3        (Pin 6)
  12: MTRON/MOTEB (Pin 16)

Drive Before the Twist Sees
SEL0/MOTEA  (Pin 10)
SEL1/DRVSB  (Pin 12)
SEL2/DRVSA  (Pin 14)
MTRON/MOTEB (Pin 16)

Drive After the Twist Sees
MTRON/MOTEB  (Pin 10)
SEL2/DRVSA  (Pin 12)
SEL1/DRVSB  (Pin 14)
SEL0/MOTEA (Pin 16)
```

Une fois activée la simulation est complètement matériel : le logiciel pauline ne joue aucun rôle après le chargement.  
jusqu’à 4 lecteurs peuvent être simulés en même temps.  
  
Pour le chargement il suffit de changer le paramètre drive et les sources de sélection. (ne pas faire de -reset pour le chargement des autres lecteurs).
  
il faut penser à sauvegarder l'image avec d'éteindre la carte :  
```
pauline -save:monfichier.hfe -drive:0
```  

## Pour la simulation sur PC88 (donc interface Shugart) : 
**1 ere étape** : convertir le fichier image en stream hfe :    
```
hxcfe -conv:HXC_STREAMHFE -finput:monfichier.img/.d88
```  

**2 eme étape** chargement en mémoire de l'image et activation de la simulation :  
```
pauline -reset -load:monfichier_img.hfe  -drive:0 -pin02mode:6 -pin34mode:2 -selsrc:8 -motsrc:12 -enabledrive
```  

Pour activer d'autre lecteurs:  
```
pauline -load:monfichier_2_img.hfe  -drive:1 -pin02mode:6 -pin34mode:2 -selsrc:9 -motsrc:12 -enabledrive
```  
pour le drive "B"

*22:30 vendredi 12 novembre 2021*  
## les options pin02mode et pin34mode.
```
Drive Simulation status lines ID (-pin02mode & -pin34mode ID):
  0 : Low state
  1 : High state
  2 : nReady
  3 : Ready
  4 : nDensity
  5 : Density
  6 : nDiskChange (mode 1 : Head step clear)
  7 : DiskChange  (mode 1 : Head step clear)
  8 : nDiskChange (mode 2 : Head step clear + timer/timeout clear)
  9 : DiskChange  (mode 2 : Head step clear + timer/timeout clear)
  10: nDiskChange (mode 3 : timer/timeout clear)
  11: DiskChange  (mode 3 : timer/timeout clear)
  12: nDiskChange (mode 4 : floppy_dc_reset input clear)
  13: DiskChange  (mode 4 : floppy_dc_reset input clear)
```
avec pour PC : ```-pin34mode:6``` et ```-pin02mode:0 ou 1 selon la densité du disque```. 
c'est via ces 2 signaux que le PC sait qu'il y a eu un changement de disque et quelle densité (DD ou HD).  

-----

*00:44 dimanche 14 novembre 2021*  
Bilan des tests avec 2 PC 
- Zenith Z-station 510 486 DX2 66 PhoenixBIOS v4.03 18/11/1994
- i7 870 CM H55M-S2H bios AMI 02/06/2012

impossible de charger un disk 360k sur une config paramètrée avec une lecteur 1,2 M dans le bios

Commandes utilisées :

```
pauline -reset -load:"DOS622 - 360k.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  

```
pauline -reset -load:"DOS622 - 360k.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive
```  

```
pauline -reset -load:"DOS622 - 360k.hfe" -doublestep -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  

```
pauline -reset -load:"DOS622 - 360k.hfe" -doublestep -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive
```  

Cela fonctionne correctement si on paramètre le lecteur en 360K dans le bios.  
Pas vu de différence avec -pin02mode:0 ou -pin02mode:1 et avec ou sans commande -doublestep  

```
pauline -reset -doublestep -load:"GW BASIC TO16 v3_21.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  
```
pauline -reset -load:"UTILITIES TO16 v3_21.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  

-----

## Registres de Pauline
```
pauline -regs
FPGA Registers :
control_reg : 0x00008001
-- Drive 0 : --
image_base_address_reg : 0x25800000
image_track_size_reg : 0x001312D0
image_max_track_reg : 0x00000056
floppy_track_offset : 0x00004000
drive_config : 0x00C95261
drv_index_len : 0x00000C35
drv_track_index_start : 0x00000000
floppy_track_pos : 0x00000000
```
```
FPGA Registers :
control_reg : 0x00008001
-- Drive 0 : --
image_base_address_reg : 0x25800000
image_track_size_reg : 0x001312D0
image_max_track_reg : 0x00000056
floppy_track_offset : 0x00015800
drive_config : 0x00C95261
drv_index_len : 0x00000C35
drv_track_index_start : 0x00000000
floppy_track_pos : 0x00000016
```
```
-- Drive 0 : --
image_base_address_reg : 0x25800000
image_track_size_reg : 0x001312E0
image_max_track_reg : 0x00000030
floppy_track_offset : 0x00004000
drive_config : 0x02C95260
drv_index_len : 0x00000C35
drv_track_index_start : 0x00000000
floppy_track_pos : 0x00000000
```

drive_config : 0x00C95261 => sans -doublestep  
drive_config : 0x02C95260 => avec -doublestep  



```
pauline -reset -doublestep -load:"DOS622 - 360k.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  
```
pauline -reset -load:"DOS622 - 360k.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  

drive_config : 0x02C95260 avec le -doublestep et drive_config : 0x00C95260 sans la commande  

```
pauline -reset -doublestep -load:"GOLF_360K.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive
```  

-----

## Activation des LED

LED verte pin 12 drive A / LED rouge pin Host write gate input  
```
pauline -led1src:17 -led2src:24
```  

LED verte pin 12 drive B / LED rouge pin Host write gate input /   
```
pauline -led1src:17 -led2src:24
```  

```
pauline -reset -load:"Dos622-1_img.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  
```
pauline -reset -load:"Dos622-2_img.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  
```
pauline -reset -load:"Dos622-3_img.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

```
pauline -save:"DOS622 - 360k - 01.hfe" -drive:0
```  

```
pauline -reset -load:"Sysinfo _ Speedisk (NORTON 8_0)_img.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  
```
pauline -reset -load:"dos7.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

### COMMANDS

## BOOT DISK 3.5 HD
```
pauline -reset -load:"DOS622_img.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

## Sauvegarde
```
pauline -save:"DOS622 - 144M - FORMAT.hfe" -drive:0
```  

## Active lecteur A en 3,5" HD et DD et 5,25" HD sans disquette 
```
pauline -reset -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

## Active lecteur B en 3,5" HD et DD et 5,25" HD sans disquette 
```
pauline -reset -drive:1 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

```
pauline -reset -doublestep -load:"GW BASIC TO16 v3_21.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

## Blank DISK Drive A:
```
pauline -reset -load:"DOS622 - 360K_40.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -led1src:17 -led2src:24 -enabledrive
``` 

```
pauline -reset -load:"DOS622 - 12M_80.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -led1src:17 -led2src:24 -enabledrive
```  

```
pauline -reset -load:"DOS622 - 720K_80.hfe" -drive:0 -pin34mode:6 -pin02mode:0 -selsrc:9 -motsrc:12 -led1src:17 -led2src:24 -enabledrive
```  

```
pauline -reset -load:"DOS622 - 144M_80.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -led1src:17 -led2src:24 -enabledrive
```  

```
pauline -reset -load:"DOS622 - 288M_82.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -led1src:17 -led2src:24 -enabledrive
```  

```
pauline -reset -load:"Windows 98 Second Edition Boot FR.hfe" -drive:0 -pin34mode:6 -pin02mode:1 -selsrc:9 -motsrc:12 -enabledrive -led1src:17 -led2src:24
```  

```
pauline -save:"Windows 98 Second Edition Boot FR.hfe" -drive:0
```  
