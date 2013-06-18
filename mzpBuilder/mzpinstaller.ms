/*******************************************************************************************************
<SCRIPTFILE>
Created: 2013-00-00
Last Updated: 2013-05-21
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	The installer that comes with the mzp-builder
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2013-05-21: merged the three structs into one single file
</SCRIPTFILE>
*******************************************************************************************************/

try(destroyDialog mzpInstaller.gui.roll_installer)catch()

(
	global mzpInstaller 
	
	struct str_mzpInstaller
	(
		basePath,
		gui,
		uninstall,
		
		--flags
		verbose = true,
		
		--variables
		iniPath,
		mzpPath
	)
	
	struct str_uninstall
	(
		function fn_cleanupTemp =
		(
			/*<FUNCTION>
			Description:
				Cleans the temp folder where the installer and payload have been extracted to.
			Arguments:
			Return:
			</FUNCTION>*/
			
			local dirIO = dotNetClass "system.IO.directory"
			local tempPath = GetINISetting mzpInstaller.iniPath "config" "buildfilename"
			local thePath = symbolicPaths.expandFileName ("$temp/" + tempPath)
			if dirIO.exists thePath do 
			(
				try(dirIO.delete thePath true)catch
				(
					mzpInstaller.gui.fn_addMessage theMessage:"Couldn't delete all files, maybe they're still open."
				)
			)
		),
		
		function fn_cleanupTarget =
		(
			/*<FUNCTION>
			Description:
				Cleans the target-folder where a previous script might have been installed before
			Arguments:
			Return:
			</FUNCTION>*/
			
			local dirIO = dotNetClass "system.IO.directory"
			local targetPath = GetINISetting mzpInstaller.iniPath "config" "targetrootpath"
			local thePath = symbolicPaths.expandFileName targetPath
			local proceed = queryBox ("Proceed to uninstall " + thePath + " agreed?") title:"Uninstall folder"
			if proceed AND dirIO.exists thePath do 
			(
				try(dirIO.delete thePath true)catch
				(
					mzpInstaller.gui.fn_addMessage theMessage:"Couldn't delete all files, maybe they're still open."
				)
			)
		)
	)

	struct str_gui
	(
		roll_installer,
		
		function fn_addMessage theMessage:"" =
		(
			/*<FUNCTION>
			Description:
				Displays a message in the log.
			Arguments:
				<string> theMessage: the message you want to display
			Return:
			</FUNCTION>*/
			
			mzpInstaller.gui.roll_installer.tbxResult.text = (dotnetClass "system.Environment").NewLine + mzpInstaller.gui.roll_installer.tbxResult.text
			mzpInstaller.gui.roll_installer.tbxResult.text = theMessage + mzpInstaller.gui.roll_installer.tbxResult.text
		),
		
		function fn_defineRollouts =
		(
			/*<FUNCTION>
			Description:
				Defines the rollouts.
			Arguments:
				<bool> arg_a: A description of the argument.
			Return:
				<bool> Function returns (anything?).
			</FUNCTION>*/
			
			rollout roll_installer "Install script" width:200 height:290
			(
				button btnInstall "Install" width:190 height:40
				button btnUninstall "Uninstall" width:90 across:2 offset:[-5,0]
				button btnUpdate "Update" width:90 offset:[7,0]
				groupbox gpbList "Scriptfiles to be installed " width:188 height:110 offset:[-6,20]
				dotNetControl lbxNewFiles "listBox" height:90 horizontalScrollbar:true HorizontalExtent:200 offset:[0,-94]
				dotNetControl tbxResult "textBox" readonly:true Multiline:true height:45 width:188 offset:[-6,0]
				button btnShowReadme "Show readme" width:80 across:2 offset:[-9,0]
				button btnOpenFolder "Open scripts folder" width:100 offset:[5,0]
				
				on roll_installer open do
				(
					--get the files from the installer package
					mzpInstaller.iniPath  = (getFiles (mzpInstaller.basePath + "mzpBuilder_*.ini"))[1] 
					mzpInstaller.mzpPath = getINISetting mzpInstaller.iniPath "config" "payload"

					--update the gui with data from the ini-file
					btnInstall.text = "Install" + (getINISetting mzpInstaller.iniPath "Header" "name") + " " + (getINISetting mzpInstaller.iniPath "Header" "version")
						
					--get data from the previously installed script 
					local targetPath = getINISetting mzpInstaller.iniPath "config" "targetrootpath"
					getDirectories (targetPath + "*")
					if (getDirectories (targetPath + "*")).count == 0 do
					(
						btnUninstall.enabled = false
						btnUpdate.enabled = false
					)
					
-- 					tbxResult.scrollBars = tbxResult.scrollBars.vertical
					--populate the listbox
					lbxNewFiles.items.clear()
					local arrFile = for key in (getINISetting mzpInstaller.iniPath "Source") collect getINISetting mzpInstaller.iniPath "Source" key
					lbxNewFiles.items.addRange (for f in arrFile collect dotNetObject "system.string" f)
				)
				
				on roll_installer close do
				(
					mzpInstaller.uninstall.fn_cleanupTemp()
				)
				
				on btnInstall pressed do
				(
					mzpInstaller.uninstall.fn_cleanupTarget()	
					filein (mzpInstaller.basePath + mzpInstaller.mzpPath)
					mzpInstaller.gui.fn_addMessage theMessage:"Script installed"
				)
				
				on btnUninstall pressed do 
				(
					mzpInstaller.uninstall.fn_cleanupTarget()
					mzpInstaller.gui.fn_addMessage theMessage:"Script uninstalled"
				)
				
				on btnUpdate pressed do
				(
					mzpInstaller.uninstall.fn_cleanupTarget()					
					filein (mzpInstaller.basePath + mzpInstaller.mzpPath)
					mzpInstaller.gui.fn_addMessage theMessage:"Script updated"
				)
				
				on btnShowReadme pressed do
				(
					ShellLaunch "notepad" ((getDir #temp) + @"\" + (getINISetting mzpInstaller.iniPath "config" "buildfilename") + @"\readme.txt")
				)
				
				on btnOpenFolder pressed do
				(
					ShellLaunch "explorer" (getDir #userScripts)
				)
				
			)
		),
		
		define = fn_defineRollouts()
	)
	
	mzpInstaller = str_mzpInstaller basePath:(getFilenamePath (getSourceFileName())) --init the struct from the location where the file is at.
	mzpInstaller.uninstall = str_uninstall()
	mzpInstaller.gui = str_gui()
)

createDialog mzpInstaller.gui.roll_installer style:#(#style_toolwindow, #style_sysmenu)