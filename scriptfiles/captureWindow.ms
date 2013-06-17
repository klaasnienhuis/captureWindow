/*******************************************************************************************************
<SCRIPTFILE>
Created: 2013-06-07
Last Updated: 2013-6-17
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2013

Description:
	Capture windows anywhere on screen to images. A window can be any control, menubar, window or viewport inside and outside 3dsMax
	
	DenisT: tracks the mouse on the entire screen
	http://forums.cgsociety.org/showthread.php?f=98&t=987387&page=1&pp=15&highlight=WM_MOUSEMOVE
	
	Getting the window under the mouse
	http://msdn.microsoft.com/en-us/library/windows/desktop/ms633558%28v=vs.85%29.aspx
	
	Drawing stuff anywhere on screen
	http://social.msdn.microsoft.com/Forums/en-US/csharpgeneral/thread/c581ef21-2833-47e5-90d7-9b8c4f38646c/

	http://captureitplus.codeplex.com/SourceControl/latest#1930684
Usage:
	RUN IT

Features:
	click on a window to capture it 
	shows a preview of the capture in the script-window
	stores screencaptures on disk
	
Wishlist:
	show an outline around the window which is about to be captured, similar to what most capture programs out there do
Changelog:
	date: change
</SCRIPTFILE>
*******************************************************************************************************/

(
	escapeEnable = false -- turn off MAXScript escape processing
	try(destroyDialog captureWindow.roll_captureWindow)catch()
	global captureWindow = undefined
	
	struct str_captureWindow
	(
		mouse_timer, --this timer is used to listen to the mouse-events
		intPtr = dotnetClass "System.intPtr", --this is an abbreviation of the class. It should speed up some methods
		gui,
		
		--the c# classes, these are created within the c# assembly
		GetWindows,
		VMouse,
		
		--other stuff
		hWnd = undefined, --store the current hWnd onder the mouse globally
		capturePath = (getdir #temp), --the location to store the captured images
		rolloutSettings, --this struct manages some sticky rollout settings
		rolloutPos, --this is a place to store the rolloutposition 
		
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
		
		function fn_createUser32Assembly forceRecompile:false =
		(
			/*<FUNCTION>
			Description:
				creates c# an assembly on the fly. 
				This assembly contains methods to capture mouse and key activity and enables screencaptures
			Arguments:
				<bool> arg_a: A description of the argument.
			Return:
			</FUNCTION>*/
			
			if (forceRecompile or 
				(classof ::User32Assembly) != dotNetObject or 
				((::User32Assembly.GetType()).ToString()) != "System.Reflection.Assembly") do
			(
				str="using System;\n"
				str+="using System.Runtime.InteropServices;\n"
				str+="using System.Drawing;\n"
				str+="namespace ScreenCapture\n"
				str+="{\n"
				
				str += "public class VMouse\n"
				str += "{\n"
				 --get keycodes here: http://msdn.microsoft.com/en-us/library/dd375731%28v=VS.85%29.aspx
				str += "	private const int VK_LBUTTON = 0x01;\n"
				str += "	private const int KEY_PRESSED = 0x80;\n"
				str += "	private const int VK_ESCAPE = 0x1B;\n" --catching the escape key is problematic and resulted in major errors
				
				str += "	[DllImport(\"user32.dll\", CharSet = CharSet.Auto, ExactSpelling = true)]\n"
				str += "	public static extern short GetKeyState(int virtualKeyCode);\n"
				
				str += "	public int IsPressed(int key) { return (GetKeyState(key) & KEY_PRESSED); }\n"
				
				--report the mousebutton or escape key
				str += "	public int MouseButtons()\n"
				str += "	{\n"
				str += "		int buttons = 0;\n"
				str += "		buttons += IsPressed(VK_LBUTTON) >> 4;\n" -->> operator stands for bit shift
				str += "		buttons += IsPressed(VK_ESCAPE) >> 1;\n"
				str += "		return buttons;\n"
				str += "	}\n"
				str += "}\n"
				
				str+="class GetWindows\n"
				str+="{\n"
				str+="	 public struct POINT { public int x; public int y; }\n"
				str+="	 public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }\n"
				
				--what window is under the cursor?
				str+="	 [DllImport(\"user32.dll\")]\n"
				str+="	 private static extern IntPtr WindowFromPoint(POINT lpPoint);\n" 
				str+="	 [DllImport(\"user32.dll\")]\n"
				str+="	 private static extern bool GetCursorPos(out POINT lpPoint);\n" 
				str+="	 public static IntPtr GetWindowUnderCursor()\n"
				str+="   {\n"
				str+="       POINT ptCursor;\n"
				str+="       if (!(GetCursorPos(out ptCursor)))\n"
				str+="       return IntPtr.Zero;"
				str+="       return WindowFromPoint(ptCursor);"
				str+="    }\n"
				
				--how big is it? and where exactly?
				str+="	 [DllImport(\"user32.dll\")]\n"
				str+="	 private static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);\n" 
				str+="	 public int[] GetWindowRect(IntPtr hWnd)\n"
				str+="   {\n"
				str+="       RECT rect;\n"
				str+="       if (GetWindowRect(hWnd, out rect))\n"
				str+="       {\n"
				str+="           return new int[4] {rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top };\n"
				str+="       }\n"
				str+="       else return null;\n"
				str+="    }\n"
				
				--capture a window to an image
				str+="	 public static void CaptureWindow(string fullPath, int x, int y, int width, int height)\n"
				str+="   {\n"
				str+="       using (var bitmap = new Bitmap(width, height))\n"
				str+="       {\n"
				str+="       	using (Graphics G = Graphics.FromImage(bitmap))\n"
				str+="       	{\n"
				str+="      		Size mysize = new Size(width,height);\n"
				str+="       		G.CopyFromScreen(x, y, 0, 0, mysize);\n"
				str+="       		bitmap.Save(fullPath);\n"
				str+="       		bitmap.Dispose();\n"
				str+="      	 }\n"
				str+="       }\n"
				str+="    }\n"
				str+="}\n"
				str+="}\n"
				csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
				compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"
				compilerParams.ReferencedAssemblies.addRange #("System.dll","System.Windows.Forms.dll","System.Drawing.dll")
				compilerParams.GenerateInMemory = true
				compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(str)
			
				if (compilerResults.Errors.Count > 0 ) then
				(
					errs = stringstream ""
					for i = 0 to (compilerResults.Errors.Count-1) do
					(
						err = compilerResults.Errors.Item[i]
						format "Error:% Line:% Column:% %\n" err.ErrorNumber err.Line err.Column err.ErrorText to:errs 
					)
					MessageBox (errs as string) title: "Errors encountered while compiling C# code"
					format "%\n" errs
					::User32Assembly = undefined
					return undefined
				)
				else
				(
					::User32Assembly = compilerResults.CompiledAssembly
				)
				
				GetWindows = compilerResults.CompiledAssembly.CreateInstance "ScreenCapture.GetWindows"
				VMouse = compilerResults.CompiledAssembly.CreateInstance "ScreenCapture.VMouse"
			)
		),

		assembly = fn_createUser32Assembly()
		
	)
	
	global captureWindow = str_captureWindow()
)	
	
--separating these structs from the rootstruct into their own scope helps the startup process
(
	struct myRollloutFunctions
	(
		function fn_getSettingsFile thePath mode:#load rolloutName:"roll" =
		(
			/*<FUNCTION>
			Description:
				Checks if the file exists, if not: creates the path and reports it to the listener.
			Arguments:
				<string> thePath: the path to the settingsFile.
				<enum mode #load #save: the mode
				<string> rolloutName: the name of the rollout we're saving stuff for
			Return:
				<bool> true if the file exists, false if not
			</FUNCTION>*/
			
			if doesFileExist thePath then
			(
				format "% settingsfile for % at %.\n" (mode as string) rolloutName (getFilenamePath thePath)
				return true
			)else
			(
				makeDir (getFilenamePath thePath)
				format "settingsfile didn't exist. Folder has been created at %.\n" (getFilenamePath thePath)
				return false
			)
		),
		
		fn saveControlSettings myRollout cfgFile =
		(
			fn_getSettingsFile cfgFile mode:#save rolloutName:myRollout.title
			try
			(
				for ctrl in myRollout.controls where matchPattern (ctrl as string) pattern:"*_save*" do
				(
					case classof ctrl of
					(
						ComboBoxControl : setIniSetting cfgFile "Comboboxes" ctrl.name (ctrl.selection as string) --aimed at dropdownlists
						SpinnerControl : 
						(
							setIniSetting cfgFile "Spinners_value" ctrl.name (ctrl.value as string)
							setIniSetting cfgFile "Spinners_enabled" ctrl.name (ctrl.enabled as string)
						)
						SliderControl : setIniSetting cfgFile "Sliders" ctrl.name (ctrl.value as string)
						CheckButtonControl : setIniSetting cfgFile "CheckButtons" ctrl.name (ctrl.state as string)
						CheckBoxControl : setIniSetting cfgFile "CheckBoxes" ctrl.name (ctrl.state as string)
						EditTextControl : setIniSetting cfgFile "EditTexts" ctrl.name ctrl.text
						ColorPickerControl : setIniSetting cfgFile "ColorPickers" ctrl.name (ctrl.color as string)
						RadioControl : setIniSetting cfgFile "RadioButtons" ctrl.name (ctrl.state as string)
						dotnetcontrol: 
						(
							case of
							(
								(matchpattern (ctrl as string) pattern:"*System.Windows.Forms.TextBox*" ): setIniSetting cfgFile "Dotnetcontrols" (ctrl as string) ctrl.text
							)
						)
					)
				)
			)catch(print "Some saving errors have occured while saving settings for the gui.")
		), -- end storeControlSettings
		
		fn loadControlSettings myRollout cfgFile =
		(
			local proceed = fn_getSettingsFile cfgFile mode:#load rolloutName:myRollout.title
			if proceed do
			(
				try
				(
					for ctrl in myRollout.controls where matchPattern (ctrl as string) pattern:"*_save*" do
					(
						case classof ctrl of
						(
							ComboBoxControl : ctrl.selection = execute (getIniSetting cfgFile "Comboboxes" ctrl.name) --aimed at dropdownlists
							SpinnerControl : 
							(
								ctrl.value = execute (getIniSetting cfgFile "Spinners_value" ctrl.name)
								ctrl.enabled = execute (getIniSetting cfgFile "Spinners_enabled" ctrl.name)
							)
							SliderControl : ctrl.value = execute (getIniSetting cfgFile "Sliders" ctrl.name)
							CheckButtonControl : ctrl.state = execute (getIniSetting cfgFile "CheckButtons" ctrl.name)
							CheckBoxControl : ctrl.state = execute (getIniSetting cfgFile "CheckBoxes" ctrl.name)
							EditTextControl : ctrl.text = getIniSetting cfgFile "EditTexts" ctrl.name
							ColorPickerControl : ctrl.color = execute (getIniSetting cfgFile "ColorPickers" ctrl.name)
							RadioControl : ctrl.state = execute (getIniSetting cfgFile "RadioButtons" ctrl.name)
							dotnetcontrol: 
							(
								case of
								(
									(matchpattern (ctrl as string) pattern:"*System.Windows.Forms.TextBox*" ): ctrl.text = getIniSetting cfgFile "Dotnetcontrols" (ctrl as string)--setIniSetting cfgFile "RadioButtons" ctrl (ctrl.text as string)
								)
							)
							
						)
					)
				)catch(print "Some loading errors have occured or reverting to default settings")
			)
			
		), -- end loadControlSettings
		
		--ROLLOUT POSITIONS
		fn saveRolloutPosition myRollout cfgFile =
		(
			try(setIniSetting cfgFile "UI" "Position" ((GetDialogPos myRollout) as string))catch()
		), -- end saveRolloutPosition
		
		fn loadRolloutPosition myRollout cfgFile = 
		(
			try( SetDialogPos myRollout (execute(getIniSetting cfgFile "UI" "Position")) )catch(print "Reverting to default rolloutposition")
		), -- end loadRolloutPosition
		
		--FLOATER POSITIONS
		fn saveFloaterPosition myFloater cfgFile =
		(
			try(setIniSetting cfgFile "UI" "FloaterPosition" ((myFloater.pos) as string))catch()
		),
		
		fn loadFloaterPosition myFloater cfgFile = 
		(
			try( myFloater.pos = (execute(getIniSetting cfgFile "UI" "FloaterPosition")) )catch(print "Reverting to default floaterposition")
		)
		
		
	)
	
	struct str_gui
	(
		rootstruct,
		roll_captureWindow, --the rollout		
		
		function event_grabWindow =
		(
			/*<FUNCTION>
			Description:
				captures a window when the mouse is clicked.
			Arguments:
				<bool> arg_a: A description of the argument.
			Return:
				<string> the filepath to the capture
			</FUNCTION>*/
			
			fn mouseTimerTick s e =
			(
				/*<FUNCTION>
				Description:
					this method is run on every tick It checks out the window the mouse is over and captures it if the mouse has been clicked.
				Arguments:
				Return:
				</FUNCTION>*/
				
				--we need the location and size of the currect window under the mouse. A window can be any control on screen, insode or outside 3dsMax
				captureWindow.hWnd = captureWindow.GetWindows.GetWindowUnderCursor() 
				local theRect = captureWindow.GetWindows.GetWindowRect (dotnetObject captureWindow.intPtr captureWindow.hWnd) 
				
				--either capture the window as an image or cancel the operation
				case (captureWindow.VMouse.MouseButtons()) of
				(
					8: --left mouseclick
					(
						try
						(
							--get the image
							local thePath = captureWindow.capturePath + @"\captureWindow_capture_" +  (captureWindow.fn_dateStamp()) + ".jpg" --use jpg, not png. png's need specific conditions which, when not handled, makes this line crap out
							captureWindow.GetWindows.CaptureWindow thePath theRect[1] theRect[2] theRect[3] theRect[4]
							captureWindow.mouse_timer.Stop()
								
							--reset the rollout position
							SetDialogPos captureWindow.gui.roll_captureWindow captureWindow.rolloutPos
							captureWindow.gui.roll_captureWindow.height = 380		
								
							--show the bitmap in the picturebox
							local theImage = (dotNetClass "System.Drawing.Image").fromFile thePath
							local theCopiedBitmap = dotNetObject "System.Drawing.bitmap" theImage
							theImage.dispose()
							captureWindow.gui.roll_captureWindow.picCapture.image = theCopiedBitmap
						)catch
						(print "please try again")
					)
					64: --escape key
					(
						captureWindow.mouse_timer.Stop()
						
						--reset the rollout position
						SetDialogPos captureWindow.gui.roll_captureWindow captureWindow.rolloutPos
					)
				)
			)
			
			--set up a timer to listen to a mouseclick
			--mouse capture code mostly by DenisT
			try(captureWindow.mouse_timer.Dispose()) catch()
			captureWindow.mouse_timer = dotnetobject "System.Timers.Timer"
			captureWindow.mouse_timer.interval = 80
			dotnet.addEventHandler captureWindow.mouse_timer "Elapsed" mouseTimerTick
			captureWindow.mouse_timer.Start()			
		),
		
		function fn_defineRollout =
		(
			rollout roll_captureWindow "Capture Window - Klaas Nienhuis - www.klaasnienhuis.nl"
			(
				local rootstruct = captureWindow
				local myIniFile = "$plugcfg\captureWindow_rolloutSettings.ini"
	
				button btnCapture "Capture window" offset:[-180,0] height:40 width:120
				groupBox grpLocation " Captured images location " offset:[125,-49] width:350 height:43
				edittext edtSaveZipPath_save "" text:"Pick a location" width:230 offset:[129,-30] across:3 enabled:true tooltip:"The location to save the zipfiles in"
				button btnPickSaveZipPath "..." offset:[140,-30] width:25 height:18 tooltip:"Pick a location to save the zipfile" enabled:true
				button btnOpenLocation "Open folder" offset:[35,-30] height:18
				dotNetControl	picCapture "System.Windows.Forms.picturebox" offset:[-1,10] width:475 height:320 visible:true
				
				on roll_captureWindow open do
				(
					rootstruct.rolloutSettings.loadRolloutPosition roll_captureWindow myIniFile
					rootstruct.rolloutSettings.loadControlSettings roll_captureWindow myIniFile
					rootstruct.capturePath = edtSaveZipPath_save.text
					
					picCapture.sizeMode = picCapture.sizeMode.zoom
					picCapture.backColor = picCapture.backColor.fromARGB 50 50 50
					if (GetDialogPos roll_captureWindow).x < 0 do SetDialogPos roll_captureWindow [0,0]					
				)
				on roll_captureWindow close do
				(
					rootstruct.rolloutSettings.saveRolloutPosition roll_captureWindow myIniFile
					rootstruct.rolloutSettings.saveControlSettings roll_captureWindow myIniFile
					
					try(rootstruct.mouse_timer.Dispose()) catch()
					picCapture.image = undefined
					picCapture.dispose()
					
				)
				
				on btnPickSaveZipPath pressed do
				(
					rootstruct.capturePath = getSavePath  caption:"Pick a location to save the zipfile to"
					edtSaveZipPath_save.text = rootstruct.capturePath
				)
				
				on btnCapture pressed do
				(
 					--move the rollout away to enable the capture of a window
					rootstruct.rolloutPos = GetDialogPos roll_captureWindow
					SetDialogPos roll_captureWindow [-500,-500]
					
					local thePath
					try(thePath = rootstruct.gui.event_grabWindow())catch(SetDialogPos roll_captureWindow rootstruct.rolloutPos)
-- 					thePath = captureWindow.gui.event_grabWindow()
 				)
				
				on btnOpenLocation pressed do
				(
					--opens the directory 
					ShellLaunch "explorer" rootstruct.capturePath		
				)
			)
		),
		
		define = fn_defineRollout()
	)
	
	captureWindow.rolloutSettings = myRollloutFunctions()
	captureWindow.gui = str_gui rootstruct:captureWindow	
)

CreateDialog captureWindow.gui.roll_captureWindow 500 50 style:#(#style_toolwindow, #style_sysmenu)