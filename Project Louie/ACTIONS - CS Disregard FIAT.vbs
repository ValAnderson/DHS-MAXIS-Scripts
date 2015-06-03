'Created by Ilse Ferris from Hennepin County, Gay Sikkink from Sterns County, and Charles Potter from Anoka County.

'STATS GATHERING----------------------------------------------------------------------------------------------------
name_of_script = "ACTIONS - CS Disregard FIAT.vbs"
start_time = timer

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN		'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF default_directory = "C:\DHS-MAXIS-Scripts\Script Files\" THEN			'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		ELSEIF beta_agency = "" or beta_agency = True then							'If you're a beta agency, you should probably use the beta branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/BETA/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else																		'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/RELEASE/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		End if
		SET req = CreateObject("Msxml2.XMLHttp.6.0")				'Creates an object to get a FuncLib_URL
		req.open "GET", FuncLib_URL, FALSE							'Attempts to open the FuncLib_URL
		req.send													'Sends request
		IF req.Status = 200 THEN									'200 means great success
			Set fso = CreateObject("Scripting.FileSystemObject")	'Creates an FSO
			Execute req.responseText								'Executes the script code
		ELSE														'Error message, tells user to try to reach github.com, otherwise instructs to contact Veronica with details (and stops script).
			MsgBox 	"Something has gone wrong. The code stored on GitHub was not able to be reached." & vbCr &_ 
					vbCr & _
					"Before contacting Veronica Cary, please check to make sure you can load the main page at www.GitHub.com." & vbCr &_
					vbCr & _
					"If you can reach GitHub.com, but this script still does not work, ask an alpha user to contact Veronica Cary and provide the following information:" & vbCr &_
					vbTab & "- The name of the script you are running." & vbCr &_
					vbTab & "- Whether or not the script is ""erroring out"" for any other users." & vbCr &_
					vbTab & "- The name and email for an employee from your IT department," & vbCr & _
					vbTab & vbTab & "responsible for network issues." & vbCr &_
					vbTab & "- The URL indicated below (a screenshot should suffice)." & vbCr &_
					vbCr & _
					"Veronica will work with your IT department to try and solve this issue, if needed." & vbCr &_ 
					vbCr &_
					"URL: " & FuncLib_URL
					script_end_procedure("Script ended due to error connecting to GitHub.")
		END IF
	ELSE
		FuncLib_URL = "C:\BZS-FuncLib\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================

'DIALOG
'===========================================================================================================================
BeginDialog CSD_FIAT_dlg, 0, 0, 161, 95, "Child Support Disregard FIATer"
  EditBox 60, 5, 90, 15, case_number
  EditBox 60, 25, 20, 15, footer_month
  EditBox 130, 25, 20, 15, footer_year
  EditBox 75, 50, 75, 15, worker_signature
  ButtonGroup ButtonPressed
    OkButton 35, 70, 50, 15
    CancelButton 90, 70, 50, 15
  Text 10, 10, 50, 10, "Case Number:"
  Text 10, 30, 50, 10, "Footer Month:"
  Text 85, 30, 45, 10, "Footer Year:"
  Text 10, 55, 60, 10, "Worker Signature:"
EndDialog


'============================================================================================================================

EMConnect ""

'Finds the case number
call find_variable("Case Nbr: ", case_number, 8)
case_number = trim(case_number)
case_number = replace(case_number, "_", "")
If IsNumeric(case_number) = False then case_number = ""

'Finds the benefit month
EMReadScreen on_SELF, 4, 2, 50
IF on_SELF = "SELF" THEN
CALL find_variable("Benefit Period (MM YY): ", footer_month, 2)
IF footer_month <> "" THEN CALL find_variable("Benefit Period (MM YY): " & footer_month & " ", footer_year, 2)
ELSE
CALL find_variable("Month: ", footer_month, 2)
IF footer_month <> "" THEN CALL find_variable("Month: " & footer_month & " ", footer_year, 2)
END IF

'Warning/instruction box
MsgBox "This script is intended for use for Family Cash cases (DWP/MFIP)." & vbnewline & vbNewLine &_
		vbTab & "- If this case has adult caregivers and minor caregivers in its " & vbNewline &_
		vbTab & "   household composition please refer to CM0017.15.03 for child and" & vbNewLine &_
		vbtab & "   spousal support income budgeting" & vbNewLine &_
		vbTab & "- If the case is involved in a sanction please process manually" & vbNewLine & vbNewLine &_
		"The script will now display all household members on the case. Please check" & vbNewLine &_
		"the boxes next to the eligible DWP/MFIP assistance unit members."

check_for_maxis(true)

DO
	DO
		DO
			DO
				Dialog CSD_FIAT_dlg
				IF buttonpressed = cancel THEN stopscript
				If case_number = "" then MsgBox "You must have a case number to continue."
			LOOP until case_number <> ""
			If worker_signature = "" then Msgbox "Please sign your case note"
		LOOP until worker_signature <> ""
		If footer_month = "" then MsgBox "You must have a starting footer month to continue."
	LOOP until footer_month <> ""
	If footer_year = "" then MsgBox "You must have a starting footer year to continue."
Loop until footer_year <> ""


back_to_self

'starting at requested month
EMwritescreen footer_month, 20, 43
EMwritescreen footer_year, 20, 46

check_for_maxis(true)
CALL navigate_to_MAXIS_screen("STAT", "MEMB")
Do
	EMReadScreen reference_number, 2, 4, 33
	person_array = person_array & reference_number & "~~" 
	transmit
	EMReadScreen memb_edit, 5, 24, 2
Loop until memb_edit = "ENTER"

person_array = trim(person_array)
person_array = split(person_array, "~~")

number_of_people = ubound(person_array)
DIM Household_array()
ReDim Household_array(number_of_people, 6)


'Checking for family cash
CALL navigate_to_MAXIS_screen("CASE", "CURR")

call find_variable("DWP: ", DWP_cash_status, 7)
call find_variable("MFIP: ", MFIP_cash_status, 7)
IF DWP_cash_status = "" AND MFIP_cash_status = "" THEN script_end_procedure("This case does not seem to have MFIP or DWP open or pending. Please review case number or prog and try again.")


FOR a = 1 to number_of_people
	FOR b = 0 to 6
		Household_array(a, b) = ""
	NEXT
NEXT

'array map
'(i, 0) = HH Ref #
'(i, 1) = MFIP elig t/f
'(i, 2) = mfip budg cycle
'(i, 3) = dwp elig t/f
'(i, 4) = dwp child support disregard
'(i, 5) = Unea retro child support total
'(i, 0) = Unea prosp child support total

person_count = 1
For each person in person_array
	If person <> "" THEN
		Household_array(person_count, 0) = person
		person_count = person_count + 1
	End If
Next

pare_row = 8
FOR i = 1 to number_of_people
	CALL navigate_to_MAXIS_screen("STAT", "PARE")
	Do
		EmReadScreen child_reference, 2, pare_row, 24
		If child_reference = Household_array(i, 0) Then
'			Household_array(i, 1) = TRUE
'			Household_array(i, 3) = TRUE
			Household_array(i, 4) = TRUE
			exit do
		ELSE
'			Household_array(i, 1) = FALSE
'			Household_array(i, 3) = FALSE
			Household_array(i, 4) = FALSE
			pare_row = pare_row + 1
			IF pare_row = 18 Then
				PF20
				pare_row = 8
			End If
			EmReadScreen pare_edit, 4, 24, 2
			IF pare_edit = "THIS" Then exit do
		END If
	Loop
Next

FOR i = 1 to number_of_people	
	IF Household_array(i, 4) = TRUE THEN
		CALL navigate_to_MAXIS_screen("STAT", "UNEA")
		EMwritescreen Household_array(i, 0), 20, 76
		EMwritescreen "01", 20, 79
		Transmit
		Household_array(i, 5) = 0
		Household_array(i, 6) = 0
		DO
			EMReadScreen current_panel, 1, 2, 73
			EMReadScreen total_panels, 1, 2, 78
			EmReadScreen UNEA_type, 2, 5, 37
			IF UNEA_type = "08" or UNEA_type = "36" or UNEA_type = "39" THEN
				EMReadScreen retro_unea, 9, 18, 38
				retro_unea = Trim(retro_unea)
				if retro_unea = "" THEN retro_unea = 0
				Household_array(i, 5) = Household_array(i, 5) + retro_unea
				EMReadScreen prosp_unea, 9, 18, 67		
				prosp_unea = Trim(prosp_unea)
				if prosp_unea = "" THEN prosp_unea = 0
				Household_array(i, 6) = Household_array(i, 6) + prosp_unea
				CS_found = TRUE
			END IF
			Transmit
		LOOP until current_panel = total_panels
	END If
Next

'if no CS UNEA is found the script ends
IF CS_found <> True THEN script_end_procedure("A child support UNEA panel was not found for Child HH members. Please check to make sure the panel is assigned to the correct person.")

back_to_self




'ELIG portion
IF DWP_cash_status <> "" Then
	CALL navigate_to_MAXIS_screen("ELIG", "DWP")
	FOR i = 1 to number_of_people
'		IF Household_array(i, 3) = TRUE Then
'			msgbox Household_array(i, 0) & vbCr & Household_array(i, 1) & vbCr & Household_array(i, 2) & vbCr & Household_array(i, 3) & vbCr & Household_array(i, 4) & vbCr & Household_array(i, 5) & vbCr & Household_array(i, 6)
			dwpr_row = 7
			DO
				EMReadScreen DWPR_ref, 2, dwpr_row, 5
				IF DWPR_ref = Household_array(i, 0) THEN
					EMReadScreen DWP_elig_status, 1, dwpr_row, 57
					IF DWP_elig_status = "I" Then
						Household_array(i, 3) = FALSE
						Exit do
					ELSEIF DWP_elig_status = "E" THEN
						Household_array(i, 3) = True
						Exit do
					END If
				END If
				dwpr_row = dwpr_row + 1
				If dwpr_row = 18 THEN 
					PF8
					dwpr_row = 7
					EmReadScreen dwpr_edit, 4, 24, 2
				END If
			LOOP Until dwpr_edit = "THIS"
'		End If
	Next
	
	number_of_kids = 0
	
	FOR i = 1 to number_of_people 
		IF Household_array(i, 3) = TRUE & Household_array(i, 6) <> 0 & Household_array(i, 4) = TRUE Then
			number_of_kids = number_of_kids + 1
		End If
	NEXT
	
	disregard_limit = 0
	IF number_of_kids = 0 Then 
		script_end_procedure("No children were found eligible for DWP and are receiving Child Support. Please review case.")
	ElseIF number_of_kids = 1 Then
		disregard_limit = 100
	Elseif number_of_kids > 1 Then
		disregard_limit = 200
	End if
	
	PF9
	EMwritescreen "04", 10, 41
	transmit
	EMwritescreen "DWB1", 20, 71
	transmit
	EMwritescreen "x", 8, 41
	transmit
	Emwaitready 1, 1000
	applied_dwp_disregard = 0
	For i = 1 to number_of_people		
		If Household_array(i, 3) = TRUE Then
			IF Household_array(i, 4) = TRUE Then
				EMwritescreen "        ", 17, 50
				applied_dwp_disregard = applied_dwp_disregard + Household_array(i, 6)
				If applied_dwp_disregard > disregard_limit THEN 
					applied_dwp_disregard = applied_dwp_disregard - Household_array(i, 6)
					Household_array(i, 6) = disregard_limit - applied_dwp_disregard
				End if
				EMwritescreen Household_array(i, 6), 17, 50
				Transmit
				Transmit
			Else
				transmit
			End If
		End if
	Next
ELSEIF MFIP_cash_status <> "" Then
	CALL navigate_to_MAXIS_screen("FIAT", "")
	EMwritescreen "03", 4, 34
	EMwritescreen "x", 9, 22
	transmit
	
	number_of_kids = 0
		FOR i = 1 to number_of_people 
		IF Household_array(i, 3) = TRUE AND Household_array(i, 6) <> 0 AND Household_array(i, 4) = TRUE Then
			number_of_kids = number_of_kids + 1
		End If
	NEXT
	
	disregard_limit = 0
	IF number_of_kids = 0 Then 
		script_end_procedure("No children were found eligible for DWP and are receiving Child Support. Please review case.")
	ElseIF number_of_kids = 1 Then
		disregard_limit = 100
	Elseif number_of_kids > 1 Then
		disregard_limit = 200
	End if	

	applied_mfip_disregard = 0
	FOR i = 1 to number_of_people
		IF Household_array(i, 4) = True THEN
			fmsl_row = 9
			DO
				EMReadSCreen fmsl_ref_num, 2, fmsl_row, 12
				EMReadScreen mfip_elig_status, 4, fmsl_row, 55
				EMReadScreen budget_retro_pro, 1, fmsl_row, 78
				IF fmsl_ref_num = Household_array(i, 0) AND mfip_elig_status = "ELIG" THEN 
					CALL write_value_and_transmit("X", fmsl_row, 8)
					EMWriteScreen "        ", 21, 44
					IF budget_retro_pro = "P" THEN 
						applied_mfip_disregard = applied_mfip_disregard + Household_array(i, 6)
						IF applied_mfip_disregard > disregard_limit THEN 
							applied_mfip_disregard = applied_mfip_disregard - Household_array(i, 6)
							Household_array(i, 6) = disregard_limit - applied_mfip_disregard
						END IF
						CALL write_value_and_transmit(Household_array(i, 6), 21, 44)
					ELSEIF budget_retro_pro = "R" THEN
						applied_mfip_disregard = applied_mfip_disregard + Household_array(i, 5)
						IF applied_mfip_disregard > disregard_limit THEN 
							applied_mfip_disregard = applied_mfip_disregard - Household_array(i, 5)
							Household_array(i, 5) = disregard_limit - applied_mfip_disregard
						END IF
						CALL write_value_and_transmit(Household_array(i, 5), 21, 44)
					END IF
					EXIT DO
				ELSE
					fmsl_row = fmsl_row + 1
					IF fmsl_row = 15 THEN 
						PF8
						fmsl_row = 9
						EMReadScreen no_more_people, 14, 24, 12
						IF no_more_people = no_more_people = "NO MORE PEOPLE" THEN EXIT DO
					END IF
				END IF
			LOOP 
		END IF
	NEXT	
END IF
	

script_end_procedure("Success!")