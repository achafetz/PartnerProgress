'variables
    Public compl_fldr
    Public tmplWkbk
    Public OpUnit
    Public SelectedOpUnits
    Public OpUnit_ns
    Public OUpath
    Public OUcompl_fldr
    Public LastRow
    Public LastCol
    Public dataWkbk

Sub PPR_pop()

    Application.ScreenUpdating = False
    
    'set directory
        ChDir "C:\Users\achafetz\Documents\GitHub\PartnerProgress\"
        compl_fldr = "C:\Users\achafetz\Documents\GitHub\PartnerProgress\Reports\"
    ' set template
        Set tmplWkbk = ActiveWorkbook
    ' no site data now --> delete Site TX_NET_NEW tab
        Application.DisplayAlerts = False
        'Sheets("TX_NET_NEW Site").Delete
        Application.DisplayAlerts = True
    'for each OU
        Sheets("RawData").Visible = True
        Sheets("rs").Visible = True
        Sheets("rs").Activate
        Set SelectedOpUnits = Sheets("rs").Range(Cells(2, 10), Cells(37, 10))
        For Each OpUnit In SelectedOpUnits
            OpUnit_ns = Replace(Replace(OpUnit, " ", ""), "'", "")
        'create OU specific folder
            OUpath = compl_fldr & OpUnit_ns & VBA.Format(Now, "yyyy.mm.dd")
            If Len(Dir(OUpath, vbDirectory)) = 0 Then MkDir OUpath
            OUcompl_fldr = OUpath & "\"
        ' open csv
            Workbooks.Open Filename:= _
                 "ExcelOutput\ICPIFactView_SNUbyIM_4Apr2017_" & OpUnit & ".csv" 'update date
            Set dataWkbk = ActiveWorkbook
        'count rows to import over
            LastRow = Range("A1").CurrentRegion.Rows.Count
            LastCol = Range("A1").CurrentRegion.Columns.Count
        'copy over rows to bring in from csv to template
            Range(Cells(2, 1), Cells(LastRow, LastCol)).Select
            Selection.Copy
            tmplWkbk.Activate
            Sheets("RawData").Activate
            Range("A2").Select
            ActiveSheet.Paste
        'hide background tabs
            Sheets("RawData").Visible = False
            Sheets("rs").Visible = False
        'refresh all pivot tables
            ActiveWorkbook.RefreshAll
        'open to main page
            Sheets("Info").Select
        'save OU specific file
            Application.DisplayAlerts = False
            fname = OUcompl_fldr & OpUnit_ns & "_FY17Q1_PartnerProgressReport_v" & VBA.Format(Now, "yyyy.mm.dd") & ".xlsx" 'update quarter
            ActiveWorkbook.SaveAs Filename:=fname, FileFormat:=xlOpenXMLWorkbook
            Application.DisplayAlerts = True
        'clear out data for next OU
            Sheets("RawData").Visible = True
            Sheets("RawData").Activate
            Range(Cells(3, 1), Cells(LastRow, LastCol)).Select
            Selection.Delete
            dataWkbk.Close
    
    Call Zip_All_Files_in_Folder
    
    Next OpUnit
    
     Application.ScreenUpdating = True
     
End Sub


''''''''''''''''''''
''   Zip Folder   ''
''''''''''''''''''''
'Source: http://www.rondebruin.nl/win/s7/win001.htm

Sub Zip_All_Files_in_Folder()
'ABOUT: This sub zips the OU folder that contains the _
data pack and its supplementary files"

    Dim FileNameZip, FolderName
    Dim strDate As String, DefPath As String
    Dim oApp As Object

        DefPath = compl_fldr
        If Right(DefPath, 1) <> "\" Then
            DefPath = DefPath & "\"
        End If
    
        FolderName = OUcompl_fldr
    
        strDate = VBA.Format(Now, "yyyy.mm.dd")
        FileNameZip = DefPath & OpUnit_ns & "PPR" & strDate & ".zip"
    'Create empty Zip File
        NewZip (FileNameZip)

        Set oApp = CreateObject("Shell.Application")
    'Copy the files to the compressed folder
        oApp.Namespace(FileNameZip).CopyHere oApp.Namespace(FolderName).items

    'Keep script waiting until Compressing is done
        On Error Resume Next
        Do Until oApp.Namespace(FileNameZip).items.Count = _
           oApp.Namespace(FolderName).items.Count
            Application.Wait (Now + TimeValue("0:00:01"))
        Loop
        On Error GoTo 0

    'delete unzipped folder
        'If Right(OUcompl_fldr, 1) <> "\" Then OUcompl_fldr = OUcompl_fldr & "\"
        'Kill OUcompl_fldr & "*.*"
        'RmDir OUcompl_fldr
        
End Sub


Sub NewZip(sPath)
    'Create empty Zip File
    'Changed by keepITcool Dec-12-2005
    If Len(Dir(sPath)) > 0 Then Kill sPath
        Open sPath For Output As #1
    Print #1, Chr$(80) & Chr$(75) & Chr$(5) & Chr$(6) & String(18, 0)
    Close #1
End Sub


Function bIsBookOpen(ByRef szBookName As String) As Boolean
    ' Rob Bovey
    On Error Resume Next
    bIsBookOpen = Not (Application.Workbooks(szBookName) Is Nothing)
End Function


Function Split97(sStr As Variant, sdelim As String) As Variant
    'Tom Ogilvy
    Split97 = Evaluate("{""" & _
    Application.Substitute(sStr, sdelim, """,""") & """}")
End Function

