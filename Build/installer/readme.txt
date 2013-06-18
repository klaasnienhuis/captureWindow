Welcome to the readme of the captureWindow script. The readme contains a list of the contents of the installer and some instructions on how to install the script.
You can install the mzp-file by dropping it onto any viewport, or by running it from the menu: MAXScript>>Run file...
If you want to check out the contents of the mzp-file yourself, you can unzip it just like a zip-file.

A message from the developer
	This script enables you to capture windows, controls and viewports in 3dsMax
	License: This script can be used freely.
	Support: mail@klaasnienhuis.nl
	Contact: developer www.klaasnienhuis.nl, twitter: klaasnienhuis mail@klaasnienhuis.nl

name "captureWindow"
description "Klaas Nienhuis Scripts"
version 1.0

The following files are copied to your system
	scriptfiles\captureWindow.ms >> $userScripts\KlaasTools\captureWindow\scriptfiles\
	art\captureWindow_16i.bmp >> $userIcons\
	art\captureWindow_24i.bmp >> $userIcons\
	art\captureWindow_24i.ico >> $userIcons\
	installer\makeMacro.ms >> $userScripts\KlaasTools\captureWindow\installer\

The following scripts are executed when installing the script
	$userScripts\KlaasTools\captureWindow\scriptfiles\captureWindow.ms
