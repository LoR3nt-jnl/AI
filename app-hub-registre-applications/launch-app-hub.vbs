Dim shell, fso, appFolder, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

appFolder = fso.GetParentFolderName(WScript.ScriptFullName)
command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & appFolder & "\open-app-hub.ps1"""

shell.Run command, 0, False
