/*******************************************************************************************************
<SCRIPTFILE>
Created: 2013-00-00
Last Updated: 2013-00-00
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	A dataObject with the contents of the ini-file deserialized into a struct
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	date: change
</SCRIPTFILE>
*******************************************************************************************************/

(
	struct str_data
	(
		rootStruct,
		
		arrAsset,
		runAssets = #(),
		macroAsset ,
		installerAssets = #(),
		
		--taken from the ini
-- 		arrSource = #(),
-- 		arrDestination = #(),
-- 		runIndices = #(),
		name = "scriptname",
		description = "A short description of the script",
		version = 0,
		sourcerootpath="",
		targetrootpath="",
		buildfilename="",
		buildfolder="",
-- 		encryptscripts=false,
-- 		encryptIndices = #(),		
		installMessage="None provided",
		license="None provided",
		support="None provided",
		contact="None provided",
		
		--generated internally
		payloadRunFile,
		installerRunFile,
		payloadZipFile,
		installerZipfile,
		readmeFile,
		
		function fn_getDataFromIni iniPath =
		(
			/*<FUNCTION>
			Description:
				Gets all needed data from an ini-file and stores it in a struct.
				Expected structure:
					[Header]
						name=...
						description=...
						version=... (integer)
					[config]
						targetrootpath=... --the root on the client machine where the installer will be copied
						sourcerootpath=... --the common root of all files which need to be packaged
						buildfilename=... --the filename of the resulting build
						buildfilepath=... --the filepath of the resulting build
						encryptscripts=boolean --encrypts all scripts if set to true. Make sure the script itself is prepared for this
					[Source] source and destination need to have the same amount of entries. Source[1] corresponds with Destination[1] and so on
						1=filename with extension. Path relative to the rootpath entered above
						2=...
					[Destination]
						1=filepath ending with a backslash. This is a path on the machine of the user who executes the mzp
						2=...
					[RunIndices]zero or more indices. Each index matches a source-file. These indexed files are also setup to run in the mzp-file
						1=...(integer)
						2=...
					[About]
						installMessage=... a message which is displayed in a readme-file. This should reduce paranoia when installing an mzp from someone you don't know.
						license=..the license for the script
						support=... contact information for support
						contact=... general contact information
			Arguments:
				<string> iniPath: the path to the ini-file which contains the data
			Return:
				<struct> an mzpBuilder struct
			</FUNCTION>*/
			
			name = GetINISetting iniPath "Header" "name"
			description = GetINISetting iniPath "Header" "description"
			version = (GetINISetting iniPath "Header" "version") as float
			installMessage = GetINISetting iniPath "About" "installMessage"
			license = GetINISetting iniPath "About" "license"
			support = GetINISetting iniPath "About" "support"
			contact = GetINISetting iniPath "About" "contact"
		),
		
		function fn_getAssetsFromIni iniPath =
		(
			/*<FUNCTION>
			Description:
				Gets all assets from the ini and creates an asset-struct for each of them.
			Arguments:
				<string> iniPath: the path to the ini-file which contains the data
			Return:
				the assets are stored in the data-struct
			</FUNCTION>*/
			
			local arrSource = for n in (GetINISetting iniPath "Source") collect GetINISetting iniPath "Source" n
			local arrDestination = for n in (GetINISetting iniPath "Destination") collect GetINISetting iniPath "Destination" n
			local encryptIndices = execute (GetINISetting iniPath "Encrypt" "theArray")
			targetrootpath = GetINISetting iniPath "config" "targetrootpath"
			sourcerootpath = GetINISetting iniPath "config" "sourcerootpath"
			buildfolder = GetINISetting iniPath "config" "buildfolder"
			buildfilename = GetINISetting iniPath "config" "buildfilename"
			local runIndices = for n in (GetINISetting iniPath "RunIndices") collect (GetINISetting iniPath "RunIndices" n) as integer
			local encryptscripts = GetINISetting iniPath "Encrypt" "encryptscripts" as booleanclass			
			
			local arrAsset = #()
			for n = 1 to arrSource.count do
			(
				local theAsset = rootStruct.assetClass()
				theAsset.relativeSourcePath = arrSource[n]
				theAsset.relativeDestinationPath = arrDestination[n]
				theAsset.sourcePath = sourcerootpath + arrSource[n]
				theAsset.buildPath = sourcerootpath + buildfolder + rootStruct.payloadPath + arrSource[n]
				theAsset.destinationPath = arrDestination[n] + (filenameFromPath arrSource[n])
				if encryptscripts do if (findItem encryptIndices n) != 0 do theAsset.doEncrypt = true
				if (findItem runIndices n) != 0 do theAsset.doRun = true
				append arrAsset theAsset
			)
			rootStruct.data.runAssets = for a in arrAsset where a.doRun == true collect a
			rootStruct.data.arrAsset = arrAsset
			
			--add the installer-files to the assets
			local arrInstaller = getFiles (mzpBuilder.basePath + "mzpinstaller*.ms*")
			append arrInstaller iniPath
			for n = 1 to arrInstaller.count do
			(
				local theAsset = rootStruct.assetClass()
				theAsset.relativeSourcePath = filenameFromPath arrInstaller[n]
				theAsset.fileName = filenameFromPath arrInstaller[n]
				theAsset.sourcePath = arrInstaller[n] --filenameFromPath
				theAsset.buildPath = sourcerootpath + buildfolder + rootStruct.installerPath + (filenameFromPath arrInstaller[n])
				append installerAssets theAsset
			)
			
		)
	)
	
	struct str_asset
	(
		relativeSourcePath = "",
		relativeDestinationPath = "",
		sourcePath = "",
		buildPath = "",
		destinationPath = "",
		fileName = "",
		doEncrypt = false,
		doRun = false
	)
	
	mzpBuilder.data = str_data rootStruct:mzpBuilder
	mzpBuilder.assetClass = str_asset
)
