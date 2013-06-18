/*******************************************************************************************************
<SCRIPTFILE>
Created: 2013-00-00
Last Updated: 2013-00-00
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Builds a mzp from an ini-file
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	date: change
</SCRIPTFILE>
*******************************************************************************************************/

(
	struct str_build
	(
		function fn_writePayloadRunFile theData payloadLocation: = 
		(
			/*<FUNCTION>
			Description:
				Creates a mzp.run file based on two arrays of strings and some template content
			Arguments:
				<data struct> theData: the struct which contains the relevant data bundled
			Return:
				file on disk
				<string> the path to the mzp.run file
			</FUNCTION>*/
			
			--create the run-file
			local theRunFilePath = theData.sourcerootpath + theData.buildfolder + payloadLocation + "mzp.run" --destination path for the run-file
			if doesFileExist theRunFilePath then deleteFile theRunFilePath else makeDir (getFilenamePath  theRunFilePath)--delete old run file if it exists or create the targetdirectory
			local theRunFile
			try (theRunFile = createFile theRunFilePath) catch (print "File: " + theRunFilePath + "cannot be created"; return false)
			
			--format the content to the file
			format "name \"PAYLOAD %\"\ndescription \"%\"\nversion %\n\n" theData.name theData.description theData.version to:theRunFile --THE HEADER
			for a in theData.arrAsset do 
			(
-- 				if a.doEncrypt do a.relativeSourcePath = substituteString a.relativeSourcePath ".ms" ".mse" --if we're encrypting, the scripts extension needs to be altered
				format "copy \"%\" to \"%\"\n" a.relativeSourcePath a.relativeDestinationPath to:theRunFile --ALL COPY-OPERATIONS
			)
			format "\nrun %\n" (theData.macroAsset.relativeDestinationPath + theData.macroAsset.fileName) to:theRunFile --RUN THE MACRO
			format "\nclear temp on MAX exit" to:theRunFile --CLEANING UP
				
			--close the file
			flush theRunFile
			close theRunFile
			
			--return the path to the run-file
			theRunFilePath
		),
		
		function fn_writeInstallerRunFile theData installerLocation: =
		(
			/*<FUNCTION>
			Description:
				Writes the runfile for the installer. Contains the installer-files with the ini and the payload mzp-file.
			Arguments:
				<data struct> theData: the struct which contains the relevant data bundled
			Return:
				file on disk
				<string> the path to the mzp.run file
			</FUNCTION>*/
			
			--create the run-file
			local theRunFilePath = theData.sourcerootpath + theData.buildfolder + installerLocation + "mzp.run" --destination path for the run-file
			if doesFileExist theRunFilePath then deleteFile theRunFilePath else makeDir (getFilenamePath  theRunFilePath)--delete old run file if it exists or create the targetdirectory
			local theRunFile
			try (theRunFile = createFile theRunFilePath) catch (print "File: " + theRunFilePath + "cannot be created"; return false)
			
			--format the content to the file
			format "name \"INSTALLER %\"\ndescription \"%\"\nversion %\n\n" theData.name theData.description theData.version to:theRunFile --THE HEADER
			format "copy \"%\" to \"%\"\n" (filenameFromPath theData.payloadZipFile) ("$temp" + @"\" + theData.buildfilename + @"\") to:theRunFile --THE PAYLOAD
			for a in theData.installerAssets do format "copy \"%\" to \"%\"\n" a.relativeSourcePath ("$temp" + @"\" + theData.buildfilename + @"\") to:theRunFile --ALSO COPY THE INSTALLER SCRIPT AND INIFILES
			format "copy \"%\" to \"%\"\n" "readme.txt" ("$temp" + @"\" + theData.buildfilename + @"\") to:theRunFile --THE README
			format "drop %\n" ("$temp" + @"\" + theData.buildfilename + @"\mzpinstaller.ms") to:theRunFile
			format "run %\n" ("$temp" + @"\" + theData.buildfilename + @"\mzpinstaller.ms") to:theRunFile
				
			--close the file
			flush theRunFile
			close theRunFile
			
			--return the path to the run-file
			theRunFilePath
		),
		
		function fn_writeReadmeFile theData installerLocation: =
		(
			/*<FUNCTION>
			Description:
				Writes a readme file which is packaged with the installer. It's a readme file which describes the payload
				and includes information stored in the ini-file.
				It's similar to what's described in the run-file for the payload, only human-readable. Also a custom message can be displayed.
			Arguments:
				<mzpBuilder struct> theData: the struct which contains the relevant data bundled in a struct
			Return:
				file on disk
				<string> the path to the readme file
			</FUNCTION>*/
			
			--create the filename and create the file
			local readmeFilePath = theData.sourcerootpath + theData.buildfolder + installerLocation + "readme.txt" --this is the readme-file we're creating
			if doesFileExist readmeFilePath then deleteFile readmeFilePath else makeDir (getFilenamePath  readmeFilePath)--delete old readme file if it exists or create the targetdirectory
			local readmeFile
			try (readmeFile = createFile readmeFilePath) catch (print "File: " + readmeFilePath + "cannot be created"; return false)
			
			--format the content to the file
			format "Welcome to the readme of the % script. The readme contains a list of the contents of the installer and some instructions on how to install the script.\n" theData.buildfilename to:readmeFile
			format "You can install the mzp-file by dropping it onto any viewport, or by running it from the menu: MAXScript>>Run file...\n" to:readmeFile
			format "If you want to check out the contents of the mzp-file yourself, you can unzip it just like a zip-file.\n" to:readmeFile
			format "\nA message from the developer\n\t%\n" theData.installMessage to:readmeFile
			format "\tLicense: %\n" theData.license to:readmeFile
			format "\tSupport: %\n" theData.support to:readmeFile
			format "\tContact: %\n\n" theData.contact to:readmeFile
			format "name \"%\"\ndescription \"%\"\nversion %\n\n" theData.name theData.description theData.version to:readmeFile 
			--format all files which are being copied
			format "The following files are copied to your system\n" to:readmeFile
-- 			for a in theData.arrAsset do format "\t% >> %\n" a.relativeSourcePath a.relativeDestinationPath to:readmeFile 
			for a in theData.arrAsset do 
			(
				if a.doEncrypt do a.relativeSourcePath = substituteString a.relativeSourcePath ".ms" ".mse" --if we're encrypting, the scripts extension needs to be altered
				format "\t% >> %\n" a.relativeSourcePath a.relativeDestinationPath to:readmeFile
			)
				
			format "\n" to:readmeFile	
			--format all files which are being executed
			format "The following scripts are executed when installing the script\n" to:readmeFile
			for a in theData.arrAsset where a.doRun do format "\t%\n" a.destinationPath to:readmeFile
				
			--close the file
			flush readmeFile
			close readmeFile
			
			--return the path to the listfile
			readmeFilePath
		),
		
		function fn_cleanup theData payloadLocation: installerLocation: =
		(
			/*<FUNCTION>
			Description:
				Cleans the folder where the build and installer is going to be.
			Arguments:
			Return:
			</FUNCTION>*/
			
			local dirIO = dotNetClass "system.IO.directory"
			local thePath = symbolicPaths.expandFileName (theData.sourcerootpath + theData.buildfolder)
			if dirIO.exists thePath do dirIO.delete thePath true
				
			makeDir (theData.sourcerootpath + theData.buildfolder + installerLocation) all:true
			makeDir (theData.sourcerootpath + theData.buildfolder + payloadLocation) all:true
		),
		
		function fn_insertInstallerFiles theData installerLocation: =
		(
			/*<FUNCTION>
			Description:
				Insert the installerfiles where the script is staged for build
			Arguments:
			Return:
			</FUNCTION>*/
			
			setINISetting mzpBuilder.iniPath "config" "payload" (filenameFromPath theData.payloadZipFile)
			for theAsset in theData.installerAssets do copyFile theAsset.sourcePath theAsset.buildPath
		),

		function fn_insertPayloadFiles theData payloadLocation: =
		(
			/*<FUNCTION>
			Description:
				Insert the payload where the script is staged for build
				also encrypts the files if needed
			Arguments:
			Return:
				<array> an array of filepaths where the payload files have been moved to
			</FUNCTION>*/
			
			local arrNewSource = #()
			for theAsset in theData.arrAsset do 
			(
				makeDir (getFilenamePath theAsset.buildPath) all:true
				copyFile theAsset.sourcePath theAsset.buildPath
				if theAsset.doEncrypt do 
				(
					encryptScript theAsset.buildPath
					deleteFile theAsset.buildPath --delete the original
					theAsset.buildPath = substituteString theAsset.buildPath ".ms" ".mse"
				)	
				append arrNewSource theAsset.buildPath
			)				
			arrNewSource

		),
		
		function fn_writeMacroAndMessage theData theLocation:@"payload\installer\makeMacro.ms" =
		(
			/*<FUNCTION>
			Description:
				Writes a default macro which enables the user to put the script in a menu, toolbar or keyboard shortcut
				Uses the data from the ini-file such as names, icons and so on.
				It's a bit fragile: it expects the icon-name to be the same as the scriptname for instance
				The macro executes the main script which is indicated in the ini-file by the runindex
			Arguments:
				<data struct> theData: the struct which contains the relevant data bundled
				<verbatim string> theLocation: the location to store the makeMacro script in
			Return:
				file on disk
				<string> the path to the scriptfile
			</FUNCTION>*/
			
			--create the file
			local theFilePath = (theData.sourcerootpath + theData.buildfolder) + theLocation --destination path for the makeMacro-file
			if doesFileExist theFilePath then deleteFile theFilePath else makeDir (getFilenamePath theFilePath)--delete old file if it exists or create the targetdirectory
			local theFile
			try (theFile = createFile theFilePath) catch (print "File: " + theFilePath + "cannot be created"; return false)
			
			local rootScript = theData.runAssets[1].destinationPath
			if theData.runAssets[1].doEncrypt do rootScript = substituteString theData.runAssets[1].destinationPath ".ms" ".mse" 
			--format the content to the file
			format "macroScript % category:\"Klaas Tools\" tooltip:\"% %\" buttonText:\"%\" Icon:#(\"%\",1)\n(\n\t" theData.name theData.name theData.version theData.name theData.name to:theFile
			format "local theScriptfile = symbolicPaths.expandFileName @\"%\"\n\t" rootScript to:theFile
			format "fileIn theScriptfile quiet:true\n)\n\n" to:theFile
			format "messageBox \"% v% has now been installed!\\n\\nTo run it " theData.name theData.version to:theFile
			format "go to:\\nCustomize -> Customize User Interface -> Toolbars\\nCategory: \\\"Klaas tools\\\" " to:theFile
			format "and drag \\\"%\\\" to a toolbar.\\n\\nClick the toolbar icon to run it!\"\n\n" theData.name to:theFile
			format "colorman.reInitIcons()" to:theFile
				
			--close the file
			flush theFile
			close theFile
						
			--return the path to the run-file
			theFilePath
		),
		
		function fn_collectFilePaths theData theType:#payload installerLocation: =
		(
			/*<FUNCTION>
			Description:
				Collects the filepaths for an mzp.
			Arguments:
				<mzpBuilder struct> theData: the struct which contains the relevant data bundled in a struct
				<name enum:#payload | #installer> theType: the type of list
			Return:
				<array> an array of strings
			</FUNCTION>*/
			local arrPath = #()
			case theType of
			(
				#payload: 
				(
					arrPath = for a in theData.arrAsset collect a.relativeSourcePath
					append arrPath (filenameFromPath theData.payloadRunFile)
				)
				#installer: 
				(
					arrPath = for a in theData.installerAssets collect a.fileName
					append arrPath (filenameFromPath theData.payloadZipFile)
					append arrPath (filenameFromPath theData.installerRunFile)
					append arrPath (filenameFromPath theData.readmeFile) --add a readme
					
					for i = 1 to arrPath.count do arrPath[i] = theData.sourcerootpath + theData.buildfolder + installerLocation + arrPath[i]
				)
			)
			arrPath
		)
	)

	mzpBuilder.build = str_build()
)