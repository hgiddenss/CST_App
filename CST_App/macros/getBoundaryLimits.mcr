' BoundingBoxLimits

Sub Main ()

	Dim X1 As Double
	Dim Y1 As Double
	Dim Z1 As Double
	Dim X2 As Double
	Dim Y2 As Double
	Dim Z2 As Double
	Dim outputLimits(6) As Double

	Boundary.GetCalculationBox(X1,X2,Y1,Y2,Z1,Z2)

	Open "BoundaryLimits.txt" For Output As #1
       Print #1,  Cstr(X1)
       Print #1,  Cstr(X2)
       Print #1,  Cstr(Y1)
       Print #1,  Cstr(Y2)
       Print #1,  Cstr(Z1)
       Print #1,  Cstr(Z2)
	Close #1

End Sub