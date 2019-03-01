' getMaterialColors

Sub Main () 

	Dim C1 As Double
	Dim C2 As Double
	Dim C3 As Double
	Dim nMaterials As Integer

	nMaterials = Material.GetNumberOfMaterials

	Dim materialName As String
	Dim mStringArray() As String

	Open "MaterialColors.txt" For Output As #1

		For i = 1 To nMaterials-1
			materialName = Material.GetNameOfMaterialFromIndex(i)

			Material.GetColour(materialName,C1,C2,C3)
			Print #1, materialName;
			Print #1, vbTab; CStr(C1);
			Print #1, vbTab; CStr(C2);
			Print #1, vbTab; CStr(C3)
		Next i

	Close #1

End Sub
