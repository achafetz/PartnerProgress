Attribute VB_Name = "PPR_pop"
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
    Public pd
    Public proj_path
    Public release_type
    Public rng
       
Sub loadform()
    'prompt for form to load to choose OUs to run
    frmRunSel.Show

End Sub
Sub PPRpop()

    Application.ScreenUpdating = False

    'set directory
        Set proj_path = Range("proj_path")
        compl_fldr = proj_path & "Reports\"
    ' set template
        Set tmplWkbk = ActiveWorkbook
    'unhide sheets
        Sheets("RawData").Visible = True
        Sheets("rs").Visible = True
    'update quartiles in Pivot Table Calculated fields
        Sheets("Partner Comparison").Activate
        'in quartile 1?
        ActiveSheet.PivotTables("Partner Comparison").CalculatedFields("in-qtl_1"). _
            StandardFormula = "= IF(Achieved<" & Range("qtl_1") & ",Achieved,0)"
        'in quartile 2?
        ActiveSheet.PivotTables("Partner Comparison").CalculatedFields("in-qtl_2"). _
            StandardFormula = "= IF(AND(Achieved>=" & Range("qtl_1") & ",Achieved<=" & Range("qtl_2") & "),Achieved,0)"
        'in quartile 3?
        ActiveSheet.PivotTables("Partner Comparison").CalculatedFields("in-qtl_3"). _
            StandardFormula = "=IF(AND(Achieved>" & Range("qtl_2") & ",Achieved<=" & Range("qtl_4") & "),Achieved,0)"
        'in quartile 4?
        ActiveSheet.PivotTables("Partner Comparison").CalculatedFields("in-qtl_4"). _
            StandardFormula = "= IF(Achieved>" & Range("qtl_4") & ",Achieved,0)"
    'add dates for saving and release type (initial or clean)
        Sheets("rs").Activate
        Set pd = Range("pd")
        Set release_type = Range("release_type")
    'open to main page
       Sheets("Info").Select
       ActiveSheet.Unprotect
    'hard code date updated & protect
        Range("C57").Value = "Updated: " & VBA.Format(Now, "yyyy-mm-dd")
        Application.CutCopyMode = False
        Range("C1").Select
        ActiveSheet.Protect DrawingObjects:=True, Contents:=True, Scenarios:=True
        ActiveSheet.EnableSelection = xlNoSelection
    'for each OU
        Sheets("rs").Select
        rng = Range("sel_ous_cnt").Value + 1
        Set SelectedOpUnits = Sheets("rs").Range(Cells(2, 7), Cells(rng, 7))

        For Each OpUnit In SelectedOpUnits
            OpUnit_ns = Replace(Replace(OpUnit, " ", ""), "'", "")
        'create OU specific folder
            OUpath = compl_fldr & "PPR_" & OpUnit_ns & pd
            If Len(Dir(OUpath, vbDirectory)) = 0 Then MkDir OUpath
            OUcompl_fldr = OUpath & "\"
        ' open csv
            Workbooks.Open Filename:= _
                 proj_path & "ExcelOutput\PPRdata_" & OpUnit & "_" & pd & ".csv"
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
        'have user open to Info tab
            Sheets("Info").Select
        'save OU specific file
            Application.DisplayAlerts = False
            fname = OUcompl_fldr & "PartnerProgressReport_" & OpUnit_ns & "_" & pd & release_type & "_" & VBA.Format(Now, "yyyymmdd") & ".xlsx"
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

    MsgBox ("Completed generating PPRs! Close out of this file and open template or report.")
    
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

        strDate = VBA.Format(Now, "yyyymmdd")
        FileNameZip = DefPath & "PPR_" & OpUnit_ns & "_" & pd & release_type & "_" & strDate & ".zip"
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


