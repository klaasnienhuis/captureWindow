macroScript captureWindow category:"Klaas Tools" tooltip:"captureWindow 1.0" buttonText:"captureWindow" Icon:#("captureWindow",1)
(
	local theScriptfile = symbolicPaths.expandFileName @"$userScripts\KlaasTools\captureWindow\scriptfiles\captureWindow.ms"
	fileIn theScriptfile quiet:true
)

messageBox "captureWindow v1.0 has now been installed!\n\nTo run it go to:\nCustomize -> Customize User Interface -> Toolbars\nCategory: \"Klaas tools\" and drag \"captureWindow\" to a toolbar.\n\nClick the toolbar icon to run it!"

colorman.reInitIcons()