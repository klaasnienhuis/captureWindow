/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-11-26
Last Updated: 2013-01-18
Version: 2

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	compile scripts, art and other files to a maxscript mzp-file
	specify paths of the needed files
	create a mzp.run-file
	enter the correct commands in the mzp.run file
	zip the files
	
Usage:
	specifiy a list of files and a list of destinations and run the script to create an mzp-file from it
	you can keep this file with your project and compile your mzp's based on an ini-file repeatedly without much hassle
	
Features:
	zips files from your developing-location to an mzp
	create a run-file which copies and runs files from that mzp-package
	
Wishlist:
	encrypt the scriptfiles in the build-folder only
	a bit more intelligence when handling filepaths
	an integritycheck for the supplied ini-file
	can the ini-file be easier to fill in
	does a gui help? Or does it make stuff more complicated?
Changelog:
	2012-11-26: first setup, used the zip-methods from teh sketchfab script
	2012-11-26: added fn_writeRunFile method to write a runfile
	2012-11-27: added mzpBuilder struct to hold data and retrieve it from an ini-file
	2012-11-27: refactoring. Combined all methods in a single struct. Moved more settings to the ini-file
	2012-11-27: made it as foolproof as possible without creating a gui. It's still a tool for developers, not regular users.
	2012-11-29: edited ini-filestructure. Now the run-file has its own destination
	2012-11-29: undo the last edit. Doesn't seem to work. Added support for a drop-file
	Branch: installReadme
	2012-11-29: also create a readme independently from the mzp-file. Contains info on the installer, license, support and contact information
	2013-01-18: added an option to encrypt all scripts
	2013-01-28: made encryption more specific. Now you point directly to the scripts you want encrypted with an array of indices
	2013-01-28: added the versionnumber to the filename of mzp
	2013-01-28: added a datestamp to the filename of mzp
	2013-05-02: chopping up the script and prepping for distributing as builder/installer
	2013-05-02: peeled off the installer
	2013-05-21: copies all the files for the installer and payload to the build folder
	2013-05-28: builds the popup-message and macro itself. No need to include it manually
	2013-05-30: took out some filepaths and put them into variables.
</SCRIPTFILE>
*******************************************************************************************************/

(
	global mzpBuilder
	
	/***************************************************************************************************
	1 CREATE AN INI-FILE WITH A SCHEME CORRESPONDING TO THE ONE DESCRIBED IN THE FN_GETDATAFROMINI METHOD
	AND FILL IT WITH YOUR OWN DATA
	
	2 THEN EXECUTE THIS FILE TO COMPILE YOUR MZP-FILE
	***************************************************************************************************/
	
	struct str_mzpBuilder
	(
		--structs
		data,
		build,
		zip,
		assetClass,
		
		--flags
		verbose,
				
		--variables
		basePath,
		iniPath,
		
		--paths
		installerPath = @"installer\",
		payloadPath = @"payload\",
		
		function fn_dateStamp =
		(
			/*<FUNCTION>
			Description:
				Create a datestamp string.
			Arguments:
			Return:
				<string> a datestamp YYYY-MM-DD_HH-MM-SS
			</FUNCTION>*/
			
			--a timestamp string
			local arrTime = getLocalTime()
			local theTime = "" as StringStream
			format "%-%-%_%-%-%" arrTime[1] (formattedprint arrTime[2] format:"02d") (formattedprint arrTime[4] format:"02d") (formattedprint arrTime[5] format:"02d") (formattedprint arrTime[6] format:"02d") (formattedprint arrTime[7] format:"02d") to:theTime
			theTime as string
		),
		
		function fn_execute =
		(
			/*<FUNCTION>
			Description:
				Execute the creation of the payload and installer mzp-files
			Arguments:
			Return:
				<string> the path to the mzp-file
			</FUNCTION>*/
			
			--get the ini-file which has all the data stored and harvest the data in the data-struct
			this.iniPath = (getFiles (basePath + "mzpbuilder*.ini"))[1]
			this.data.fn_getDataFromIni this.iniPath
			this.data.fn_getAssetsFromIni this.iniPath
				
			--erase all files from the buildfolder. Make it ready for a new build
			this.build.fn_cleanup this.data payloadLocation:payloadPath installerLocation:installerPath

			--MACRO
			--create the macro and message file. This file adds a macro that executes right after the script has been installed.
			local macroPath = this.build.fn_writeMacroAndMessage this.data theLocation:(payloadPath + @"installer\makeMacro.ms")
			--append the filepath to include it in the runfile and zipfile for the payload
			local macroAsset = this.assetClass relativeSourcePath:(installerPath + (filenameFromPath macroPath)) relativeDestinationPath:(this.data.targetRootPath + installerPath) buildPath:macroPath fileName:(filenameFromPath macroPath)
			this.data.macroAsset = macroAsset
			append this.data.arrAsset macroAsset

			--README
			--create the readme file. This will be bundled with the installer
			this.data.readmeFile = this.build.fn_writeReadmeFile this.data installerLocation:installerPath
				
			--create the filepaths for the zipfiles
			this.data.payloadZipFile = this.data.sourcerootpath + this.data.buildfolder + installerPath + "PAYLOAD_" + this.data.buildfilename + "_" + this.fn_dateStamp() + "_" + (this.data.version as string)+ ".mzp" --this is the zipfile we're creating
			this.data.installerZipfile = this.data.sourcerootpath + this.data.buildfolder + "INSTALLER_" + this.data.buildfilename + "_" + this.fn_dateStamp() + "_" + (this.data.version as string)+ ".mzp" --this is the zipfile we're creating

			--create the runfiles
			this.data.payloadRunFile = this.build.fn_writePayloadRunFile this.data payloadLocation:payloadPath --create an mzp.run file
			this.data.installerRunFile = this.build.fn_writeInstallerRunFile this.data installerLocation:installerPath --create an mzp.run file
				
			--copy the installer scriptfiles to the build-folder
			this.build.fn_insertInstallerFiles this.data installerLocation:installerPath
			this.build.fn_insertPayloadFiles this.data payloadLocation:payloadPath
				
			--create the payload
			local arrPath = this.build.fn_collectFilePaths this.data theType:#payload	
			this.zip.fn_zipFiles this.data.payloadZipFile arrPath (this.data.sourcerootpath + this.data.buildfolder + "payload") --create the mzp-file
			
			--create the installer
			local arrPath = this.build.fn_collectFilePaths this.data theType:#installer	installerLocation:installerPath
			this.zip.fn_zipFiles this.data.installerZipfile arrPath (this.data.sourcerootpath + this.data.buildfolder + "installer")--create the mzp-file
		)

	)

	mzpBuilder = str_mzpBuilder basePath:(getFilenamePath (getSourceFileName())) --init the struct from the location where the file is at.

	--load the other scripts. This loop enables the script to be normal (.ms) or encrypted (.mse)
	local arrScriptfile = getFiles (mzpBuilder.basePath + "mzpbuilder_*.ms*") --add the underscore as we don't want to run this script again in the loop
	for f in arrScriptfile do fileIn f
	
	mzpBuilder.fn_execute()
)
