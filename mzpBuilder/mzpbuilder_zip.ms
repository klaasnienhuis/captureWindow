/*******************************************************************************************************
<SCRIPTFILE>
Created: 2013-00-00
Last Updated: 2013-00-00
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Zip methods, bundled
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	date: change
</SCRIPTFILE>
*******************************************************************************************************/

(
	struct str_zip
	(
		function fn_makeZipList arrPath =
		(
			/*<FUNCTION>
			Description:
				Makes a tmp-file which serves as input for the zipping-process.
			Arguments:
				<array> arrPath: An array of filepaths. They need to have a common root
			Return:
				a file on disk
				<string> the path to the generated file
			</FUNCTION>*/
			
			-- generate a temporary file with the list of files to be archived
			--TODO: check if an alternative folder is an option
			local theZipListPath = "C:/temp/" + "~mzpBuilderZipList.tmp" -- targetPath --need a path without any spaces!!
			if doesFileExist theZipListPath then deleteFile theZipListPath else makeDir (getFilenamePath theZipListPath)-- delete old tmp file if it exists or create the folder
			
			local theZipList
			try (theZipList = createFile theZipListPath) catch (print "File: " + theZipListPath + "cannot be created"; return false)
			for thePath in arrPath do format "%\n" thePath to:theZipList
			flush theZipList
			close theZipList
			
			--return the path to the listfile
			theZipListPath
		),
		
		
		function fn_zipFiles zipPath arrPath rootPath =
		(
			/*<FUNCTION>
			Description:
				packages files together in a zipfile. Uses the max-native maxzip.exe to perform the zipping.
			Arguments:
				<mzpBuilder struct> theData: the struct which contains the relevant data bundled in a struct
			Return:
				<string> the path of the generated zipfile
			</FUNCTION>*/
			
			--create the ziplist. This is the list of files which need to be zipped
			local theTempFilePath = this.fn_makeZipList arrPath
			
			--prep the filename and file
			if doesFileExist zipPath then deleteFile zipPath else makedir (getFilenamePath zipPath)-- delete old mzp file if it exists or create the folder
			
			--create a commandstring
			local zipUtil = (getDir #maxRoot) + "maxzip.exe" --this is the zip-program. It's shipped with 3dsMax
			local cmd = "" as stringStream
			format "\"%\" \"%\" @%" zipUtil zipPath theTempFilePath to:cmd -- thanks to ofer_z--zipFile needs to be a mapped drive?
			
			local curDir = sysInfo.currentDir -- store current system dir
			sysInfo.currentDir = rootPath-- set system folder (zip tree begins here)
			(hiddendosCommand cmd exitcode:&exitcode) --EXECUTE THE ZIPPING
			sysInfo.currentDir = curDir -- restore old system dir
			
			--output the code returned by maxzip. For a list of possible codes, check here: http://www.info-zip.org/mans/zip.html#DIAGNOSTICS
			if exitcode == 0 then exitcode = "normal"
			format "zip-status: % \n" exitcode
			
			zipPath --return the path of the zipfile
		)
	)
	
	mzpBuilder.zip = str_zip()
)
