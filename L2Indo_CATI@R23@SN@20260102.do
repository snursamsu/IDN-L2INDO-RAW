* L2Indo CATI ROUND 23
* created by Avralt-Od Purevjav ; modified by Samuel Nursamsu
* last modified on July 9, 2026
* making sure that there is no left overs 

*-------------------------------------------------------------------------------
* PREAMBLES
*-------------------------------------------------------------------------------
{		
	clear
	set more off
	set excelxlsxlargefile on
	macro drop _all
// 	set processors 8
	set processors 6
    cap log close
	
	* Set round and user
	********************
	glo LNG ENG 	
	glo R 23
	glo pR 22
	
	scalar user=2 //1=AP, 2=SN, 3=local team
	if (user==1) glo wd "C:\Users\wb463427\OneDrive - WBG\L2Indo\CATI\Round${R}"
	if (user==2) glo wd "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)\raw_KOBO\Round${R}"
	if (user==3) glo wd ""
			
	cd "$wd" //changing directory 
	
	* Specify import file settings
	********************************
	glo M 01
	glo D 02
	glo Y 2026
	
	*Main_Data_-_Listening_To_Indonesia_-_all_versions_-_False_-_2024-04-02-12-30-21
	glo sheet1 "Main Data Round 23 - Listeni..."
	glo version _all_versions_-_False_
// 	glo excel_file Main_Data_-_Listening_To_Indonesia_-${version}-_${Y}-${M}-${D}-${HH}-${MM}-${SS}
	glo excel_file Main_Data_Round_23_Listening_To_Indonesia_all_versions_False_2026
	glo dta_file l2ind
	
	glo date ${Y}${M}${D}	
	glo date_filter "date == mdy($M, $D, $Y)"
	
	* Kobo file
	****************************************************
	glo kobofile "aHinij9CdTV8oFKqawz7cB"
	
	* Set ado folder and install commands if necessary
	****************************************************
	cap adopath - "$wd/ado/"		
	// making sure are there defined commands
	foreach prog in kobo2stata _gwtmean extremes ///
		winsor2 povdeco apoverty ds3 ///
			clonevar confirmdir unique copydesc dropmiss {
				cap which `prog'
					capture if _rc ssc install `prog' , replace all
	}
	adopath + "$wd/ado/"
	
	* Create folders
	********************
		foreach dir in raw zzz call tab	fix dta aud log {
			confirmdir "${wd}/`dir'/"
			if _rc ~= 0 {
				mkdir "${wd}/`dir'"
			}
			confirmdir "${wd}/`dir'/$date"
			if _rc ~= 0 {
				mkdir "${wd}/`dir'/$date"
			}			
		}

	glo kobo "$wd/kobo"
	glo raw "$wd/raw/$date"
	glo xls "$wd/xls"
	glo zzz "$wd/zzz/$date"
	glo call "$wd/call/$date"
	glo fix "$wd/fix/$date"
	glo tab "$wd/tab/$date"
	glo dta "$wd/dta/$date"
	glo aud "$wd/aud/$date"
    glo log "$wd/log/$date"
    

	* Clean old files
	****************************
	local zzzfiles : dir "${zzz}" files "*.dta"
	local rawfiles : dir "${raw}" files "*.dta"	
		foreach file in `zzzfiles' `rawfiles' {
				di 	"`file'" 						
			*shell rm -r $zzz/`file'
			cap erase "$zzz/`file'"
			cap erase "$raw/`file'"

			}
			
    * Log
    ***************************
    log using "$log/log_${date}.log", replace
}			

********************************************************************************
********************************************************************************	

*------------------------------------------------------------------------------*
* Load info from XLS form (kobo file) 
*------------------------------------------------------------------------------*

	
	* Survey sheet of XLS form
	import excel using "$kobo/${kobofile}.xlsx", clear first sheet(survey)

	cap ren A type 
	split type, parse(" ")
	
	rename type1 qtype 
	rename type2 qchoice
	rename name qname	
	
	rename labelEnglisheng lben
	rename labelIndonesianind lbin
	
	glo langlist "en in"
	
	* Corrections to names
	replace qname = subinstr(qname, "-","",.)
	replace qchoice = subinstr(qchoice, "-","",.)
	
	* Corrections to labels
	foreach x in $langlist {
		replace lb`x' = subinstr(lb`x', `"__<span style="color:red">$"', "",.)
		replace lb`x' = subinstr(lb`x', `"{hhid}</span>__"', "",.)
		replace lb`x' = subinstr(lb`x', "$", "",.)		
		
		replace lb`x' = strtrim(stritrim(lb`x'))
		
		replace lb`x' = subinstr(lb`x', char(10), "", .) 

	}
	
	gen lbvarcount = length(lben) - length(subinstr(lben, "{", "", .))
	sum lbvarcount 
	forval x=1/`r(max)' {
		local y = `x'-1
		if (`x'==1) gen lbvarname`x' = regexs(0) if regexm(lben, "[{][a-zA-Z0-9_]+[}]")==1  
		if (`x'>1) gen lbvarname`x' = regexs(0) if regexm(subinstr(lben,lbvarname`y', "",.), "[{][a-zA-Z0-9_]+[}]")==1 
	
		replace lben = subinstr(lben, lbvarname`x', "<DOB>",.) if regexm(lbvarname`x', "artdob")==1	
		replace lben = subinstr(lben, lbvarname`x', "<NAME>",.) if regexm(lbvarname`x', "name")==1
		replace lben = subinstr(lben, lbvarname`x', "<YEAR>",.) if regexm(lbvarname`x', "year")==1
		replace lben = subinstr(lben, lbvarname`x', "<MONTH, YEAR>",.) if regexm(lbvarname`x', "next_call")==1
		replace lben = subinstr(lben, lbvarname`x', "<AGE>",.) if regexm(lbvarname`x', "age")==1
	
	}

	foreach x in $langlist {
		replace lb`x' = subinstr(lb`x', "_", "",.)
	}
		
	list qname lben lbin if regexm(lben, "[{}]")==1 
	
	save "$zzz/kobo_survey_R${R}.dta", replace

	
	* Choices sheet of XLS form
	import excel using "$kobo/${kobofile}.xlsx", clear first sheet(choices)
	
	rename labelEnglisheng lben
	rename labelIndonesianind lbin
	rename list_name lname 
	rename name val
	
	save "$zzz/kobo_choice_R${R}.dta", replace

	
	* Type of variable 
	************************
	use "$zzz/kobo_survey_R${R}.dta", clear 
	drop if qtype=="note"

	levelsof qname, local(qnamelist) clean
	
	foreach nm in `qnamelist' {
		levelsof qtype if qname=="`nm'", local(tname) clean
		glo `nm'_qtype "`tname'"
		
		levelsof qchoice if qname=="`nm'" & qchoice!="", local(cname) clean
		if ("`cname'"!="") glo `nm'_qchoice "`cname'"
	}
	
	* Labels
	************************
	foreach nm in `qnamelist' {
	
		foreach lng in $langlist {
			levelsof lb`lng' if qname=="`nm'", local(lb) clean 
			glo `nm'_lb`lng' "`lb'"
		}
	}
	
	* Select one choices
	preserve
		keep if qtype=="select_one"
		keep qchoice 
		rename qchoice lname 
		gen select_one=1
		duplicates drop
		tempfile selectonelist
		save `selectonelist'
	restore
	
	* Select multiple choices => goes as variable names 
	preserve
		keep if qtype=="select_multiple"
		keep qchoice 
		rename qchoice lname 
		gen select_multiple=1
		duplicates drop
		tempfile selectmultlist
		save `selectmultlist'
	restore


	* Value labels  - SELECT ONE  only
	**************************************
	use  "$zzz/kobo_choice_R${R}.dta", clear
	
	merge m:1 lname using `selectonelist', nogen 
	keep if select_one==1
	
	destring val, replace force
	drop if val==.
	
	levelsof lname, local(choicelist) clean 
	
	foreach cn in `choicelist' {
		
		* All values 
		levelsof val if lname=="`cn'", local(vals) clean 
		glo `cn'_vals "`vals'"
		
		
		* Labels for each value 
		foreach v of global `cn'_vals {
		
			local vn = subinstr("`v'", ".","",.)
			
					foreach lng in $langlist {
						levelsof lb`lng' if lname=="`cn'" & val==`v', local(lb) clean 
						glo `cn'_`vn'_lb`lng' "`lb'"
					
					}
			
		}
	
		* Define value labels 
		local vdef_en ""
		local vdef_in ""

		foreach v of glo `cn'_vals {
		
			local vn = subinstr("`v'", ".","",.)
			
				foreach lng in $langlist {
					local vdef_`lng' `"`vdef_`lng'' `v' "${`cn'_`vn'_lb`lng'}""'
				}
				
		} 
		
		foreach lng in $langlist {
			disp `"`vdef_`lng''"'
			la def `cn'_`lng' `vdef_`lng'', replace
			glo `cn'_`lng' `vdef_`lng''

		}
	
	}
	
	
	* Value labels  - SELECT MULTIPLE  only => goes as variable labels 
	**************************************
	use  "$zzz/kobo_choice_R${R}.dta", clear
	merge m:1 lname using `selectmultlist', nogen 
	keep if select_multiple==1
	replace val = subinstr(val, ".", "",.)
	
	levelsof lname, local(choicelist) clean
	foreach cn in `choicelist' {
		
		* All values 
		levelsof val if lname=="`cn'", local(vals) clean 
		glo `cn'_vals "`vals'"
		
		* Labels for each value 
		foreach v of global `cn'_vals {
					
			foreach lng in $langlist {
				levelsof lb`lng' if lname=="`cn'" & val=="`v'", local(lb) clean 
				glo `cn'_`v'_lb`lng' "`lb'"

			}
		}	
	}

	* Save additional info on globals
	**************************************
	use "$zzz/kobo_survey_R${R}.dta", clear 
	
	drop if qtype=="note"

	gen rq = required 
	replace rq = "1" if required=="true" 
	
	gen rv =relevant
	gen cr = constraint 

	
	levelsof qname, local(qnamelist) clean

	foreach nm in `qnamelist' {
		
		* Required
		qui levelsof rq if qname=="`nm'", local(rq) clean
		glo `nm'_rq "`rq'"
		
		* Relevance
		qui levelsof rv if qname=="`nm'", local(rv) clean
		glo `nm'_rv "`rvt'"		
		
		* Constraint 
		qui levelsof cr if qname=="`nm'", local(cr) clean
		glo `nm'_cr "`cr'"		
		
				
	}
	
	
	* Define labeling as program 
	**************************************
	cap program drop applylab
	program define applylab 
		//Apply labels for all variables in ALL languages
		glo en3 "ENG"
		glo in3 "IND"
		
		foreach ln in en in {
			la lang ${`ln'3}, copy new

			foreach var of varlist _all {
				
				disp `"`var': ${`var'_lb`ln'}"'
				
				if strlen(`"${`var'_lb`ln'}"')>0 {	
					la var `var' `"${`var'_lb`ln'}"'
					note `var ': ${`var'_lb`ln'}
				}
				

				if "${`var'_qtype}"=="select_one" & "${`var'_qchoice}"!="" & substr("`:type `var''",1,3)!="str" { //only numeric vars		
					la def ${`var'_qchoice}_`ln' ${${`var'_qchoice}_`ln'}, replace
					la val `var' ${`var'_qchoice}_`ln'
				}
				if "${`var'_qtype}"=="select_multiple" & "${`var'_qchoice}"!="" {
					foreach v in ${${`var'_qchoice}_vals} {
						la var `var'`v' `"${`var'_lb`ln'}: ${${`var'_qchoice}_`v'_lb`ln'}"'
						note `var'`v': ${`var'_lb`ln'} - ${${`var'_qchoice}_`v'_lb`ln'}
						
					}					
				}	
			}
		}
			
		la lang ${LNG}				
	
	end 
	



*------------------------------------------------------------------------------*
* HH-LEVEL - EXCEL TO STATA 
*------------------------------------------------------------------------------*
{			
	cap confirm file "$zzz/${sheet1}.dta" 
		if _rc ~= 0 {
		
			import excel "${xls}/$excel_file.xlsx", ///
				describe
			return list
			
			import excel "$wd/xls/$excel_file.xlsx", ///
				sheet(${sheet1}) firstrow clear allstring 
				
			destring , replace 

			// Drop  notes 
			drop cover_note
			drop pelaksanaan_survei

			// Apply labels 
			qui applylab //defined above
			
			// Submission time & Durations 
			{
				la var start "Start Date/Time (string)"
					as start ~= "" 
					split start , parse("T" ".") generate(start_) limit(2)
						cap drop start 
				g double start_date = date(start_1, "YMD") , after(deviceid)
				la var start_date "Start Date"
					format start_date %tdCCYY/NN/DD
				g double start_time = clock(start_1+start_2, "YMDhms"), after(start_date)
				la var start_time "Start Time"
					format start_time %tcCCYY/NN/DD_HH:MM
						cap drop start_1 start_2	
					
				la var end "End Date/Time (string)"
					as end ~= ""
					split end , parse(" " "T" ".") generate(end_) limit(2)
						cap drop end 
				g double end_date = date(end_1, "YMD"), after(start_date)
				la var end_date "End Date"
					format end_date %tdCCYY/NN/DD
				g double end_time = clock(end_1+end_2, "YMDhms"), after(start_time)
				la var end_time "End Time"
					format end_time %tcCCYY/NN/DD_HH:MM:SS
						cap drop end_1 end_2
						
				rename _submission_time time
				la var time  "End Date/Time (string)"
					as time ~= ""
					split time , parse(" " "T" ".") generate(sub_) limit(2)
						cap drop time 
				g double date = date(sub_1, "YMD"), after(end_date)
				la var date "Submission Date"
					format date %tdCCYY/NN/DD
				g double time = clock(sub_1+sub_2, "YMDhms"), after(end_time)
				la var time "Submission Time"
					format time %tcCCYY/NN/DD_HH:MM:SS
						cap drop sub_1 sub_2
											
				la var nextcall "Start Date/Time (string)"
					as nextcall ~= "" if agreement == 1, r 
					split nextcall , parse(", ") generate(next_) limit(2)
						cap drop nextcall 
				g double next_date = date(next_2, "YMD") , after(time)
				la var next_date "Next Call Date"
					format next_date %tdCCYY/NN/DD
						cap drop next_1	next_2

				#delimit ;
				glo TIMEVARS 
							" 
								a10
								modul_1_time
								sh_time
								wb_time
								ac_time
								vw_time 
								inc_time
								sv_time 					
							" ; 
				#delimit cr 
			
				//xp_time  
				//net_time  
				//ecom_time
				//mg_time 
								
				foreach t of glo TIMEVARS {
					split `t' , parse(".") generate(t) limit(2)
						cap drop `t'
						//rename `t' `t'_orig
					gen double `t' = clock(t1, "hms")
						format `t' %tcHH:MM:SS
							cap drop t1 t2
	
					/*
					split `t' , parse("T" ".") generate(t) limit(2)
						cap drop `t'
					g double `t' = clock(t1+t2, "YMDhms")
						format `t' %tcCCYY/NN/DD_HH:MM:SS
							cap drop t1 t2
					*/
				}
				
				
				cap drop dur_pp
				g double dur_pp = round((modul_1_time - a10)/60000 , 0.001)
				la var dur_pp  "Duration of Questionnaire Passport (min)"

				/*
				cap drop dur_or	
				g double dur_or = round((time_nr - time_or)/60000, 0.001)
				la var dur_or  "Duration of Old Roster (min)"
				
				cap drop dur_nr	
				g double dur_nr = round((time_sh - time_nr)/60000, 0.001)
				la var dur_nr  "Duration of New Roster (min)"
				*/
				
				cap drop dur_rr 
				g double dur_rr = round((sh_time - modul_1_time)/60000, 0.001)
				la var dur_rr  "Duration of Roster (min)"

				cap drop dur_sh	
				g double dur_sh = round((wb_time - sh_time)/60000, 0.001)
				la var dur_sh  "Duration of Shocks (min)"
					

// 				cap drop dur_wb	
// 				g double dur_wb = round((mg_time - wb_time)/60000, 0.001)
// 				la var dur_wb  "Duration of Wellbeing (min)"

					
				/*
				cap drop dur_mg_pot	
				g double dur_mg_pot = round(( time_mg2 - time_mg1)/60000, 0.001)
				la var dur_mg_pot  "Duration of Potential Migration (min)"
					
				cap drop dur_mg_ret	
				g double dur_mg_ret = round(( time_mg3 - time_mg2)/60000, 0.001)
				la var dur_mg_ret  "Duration of Retunrning Migration (min)"
					
				cap drop dur_mg_liv	
				g double dur_mg_liv = round(( time_mg4 - time_mg3)/60000, 0.001)
				la var dur_mg_liv  "Duration of Living Migration (min)"
				*/	
// 				cap drop dur_mg	
// 				g double dur_mg = round(( ac_time - mg_time)/60000, 0.001)
// 				la var dur_mg  "Duration of Migration (min)"
					
				/*
				cap drop dur_ac_emp	
				g double dur_ac_emp = round((time_ac2 - time_ac1)/60000, 0.001)
				la var dur_ac_emp  "Duration of Employment (min)"
					
				cap drop dur_ac_look	
				g double dur_ac_look = round((time_ac3 - time_ac2)/60000, 0.001)
				la var dur_ac_look  "Duration of Job Search (min)"
				*/
				cap drop dur_ac	
				g double double dur_ac = round((vw_time - ac_time)/60000, 0.001)
				la var dur_ac  "Duration of Activity (min)"
					
				cap drop dur_vw	
				g double dur_vw = round((inc_time - vw_time)/60000, 0.001)
				la var dur_vw  "Duration of Views (min)"
				
				
				cap drop dur_in	
				g double dur_in = round((sv_time - inc_time)/60000, 0.001)
				la var dur_in  "Duration of Incomes (min)"
					
				cap drop dur_sv	
				g double dur_sv = round((end_time - sv_time)/60000, 0.001)
				la var dur_sv  "Duration of Savings (min)"
				
// 				cap drop dur_ga	
// 				g double dur_ga = round((end_time - ga_time)/60000, 0.001)
// 				la var dur_ga  "Duration of Green Agenda (min)"
						
						
				cap drop dur_tot 
				g double dur_tot = round((end_time - start_time)/60000, 0.001)
				la var dur_tot  "Duration of Survey (min)"
					
					cap drop time_* 	
			}
			
			
			// Set of ID variables  
			ren hhid hhid 
			ren _id koboid
			ren _uuid uuid 
			ren _index sid 
			
			// Respondent fmid (here given as hhid+fmid = > to extract fmid)
// 			destring hhid, replace 
			tostring hhid, gen(hhid_string)
			g hhid_string = hhid 
// 			tostring resp_name, gen(resp_name_string) 
			g resp_name_string = resp_name 
			gen resp_fmid = resp_name_string
			replace resp_fmid = subinstr(resp_name_string, hhid_string,"",.)
			destring resp_fmid, replace 
			drop hhid_string
			drop resp_name_string
			order resp_fmid, before(resp_name)
			loc resplab: var lab resp_name 
			
			ren np6 resp_mood 
			ren np5 resp_lang	
			ren np4 next_transfer			
			ren np3 next_phone 	
			ren np2 next_fmid	
			ren np1 next_call 	

			
			//Region identifiers 
			rename a01 ea 			
			rename a02 province 
			rename a03 regency
			rename a04 district 
			rename a05 village
			rename a07 rurban
			rename a06 hhtype 
			
			order hhid koboid uuid sid, first
			
			// Checking duplicates 
			bys hhid (agreement): g N = _N 
				drop if N>1 & agreement == 2
				cap drop N
			unique hhid 
			if `r(N)' ~= `r(unique)' { // if submitted twice 
				bys hhid (start_time end_time time): g n = _n 
					bro if n > 1 
				as n == 1, r
				bys hhid (start_time end_time time): keep if _n == _N
					cap drop n
			}
			
			unique hhid
				as r(N) == r(unique)
				
			// Round number 
			rename a12 round 
			order round, first
			
			drop _* 
			drop deviceid 
			//drop bar_catiid 
			//drop qrcode 
			
			
			// Relabel if necessary
			la lang ENG
			la var round "L2Indo CATI Round"
			la var hhid "L2Indo ID" // Based on the Baseline IDs 
			la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
			la var uuid "UUID (Kobo)" 
			la var sid "Submission ID (Kobo)"
			la var tothhm "Household size (old)"	
			la var resp_fmid "Respondent family member ID"
			
			la var province "Province"
			la var regency "Regency"
			la var district "District"
			la var village "Village"
			la var rurban "Urban/Rural"
			
			la lang IND 
			** here goes labels in Indonesian
									
			la lang ${LNG}
	
			save "$zzz/${sheet1}.dta", replace
		}	
		
}
	
*------------------------------------------------------------------------------*
* INDIVIDUAL-LEVEL - EXCEL TO STATA 
*------------------------------------------------------------------------------*
{			
	import excel "$wd/xls/$excel_file.xlsx", ///
		describe
	return list 
	glo sheetnum `r(N_worksheet)'
	global indsheets ""
	forval w=2/$sheetnum {
		//local sname = subinstr("`r(worksheet_`w')'", "_","",.)
		local sname "`r(worksheet_`w')'"
		glo indsheets "$indsheets `sname'"
	}
	disp "$indsheets"
	
	* HH ROSTER: Old+new members
	**************************
	local sheet "hhmember"
	cap confirm file "$zzz/`sheet'.dta" 
	if _rc ~= 0 {
		import excel "$wd/xls/$excel_file.xlsx", ///
			sheet(`sheet') firstrow clear allstring 
		destring , replace 	
	
	
		// Apply labels
		applylab 

		//rename *_hhid hhid 
		rename art_no fmid
		rename _parent_index sid
		rename _submission__id koboid
		rename _submission__uuid uuid
		
		//Bring HHID from master table
		merge m:1 sid koboid uuid using "$zzz/${sheet1}.dta", keepusing(hhid) nogen
		order hhid, first
		
		//Check duplicates 
		bys hhid fmid: g N = _N
				as N == 1 , r 
					cap drop N

		unique hhid fmid 
			if `r(N)' ~= `r(unique)' {
				bys hhid fmid : g n = _n 
					bro if n > 1 
				as n == 1, r
					drop if n > 1 
						cap drop n
			}

		unique hhid fmid
			as r(N) == r(unique)	
				
				
		// Drop if key info is missing
		drop if ///
				art_name == "" & ///
				art_age == . & ///
				residing == . & ///
				leave_reason ==. 
			
		
		//Rename 
		rename art_name name
		rename art_age age 
		
		//Name
		* already corrected in Kobo 
		
		//Age 
		* already corrected in Kbo
		
		//DOB
		gen dob=""
		replace dob=correct_dob if correct_dob!=""
		replace dob=new_art_dob if dob=="" & new_art_dob!=""
		
		//Gender (here only for new members)
		clonevar gender = new_art_gender 
		
		// Correct new member identifier 
		clonevar new_member_orig = new_member //when new_member==1, next person is new member 
		bys hhid (fmid): replace new_member = new_member_orig[_n-1]
		order name age dob gender relation* residing leave* correct_* new_member, after(fmid)
		
		/*
		// Correct names 	
		replace name = trim(itrim(proper(name))) 
		tostring correct_name , replace
		replace correct_name = "" if correct_name == "."
		replace correct_name = trim(itrim(proper(correct_name))) 
		replace name = correct_name if residing == 3 & correct_name ~= ""
		*/
		
		// Relabel if necessary
		la lang ENG
		la var fmid "Family member ID"
		la var name "Full name of family member (updated)"
		la var age "Age (updated)"
		la var dob "Date of birth (updated/only new members)"
		la var gender "Gender (only new members)"
		la var new_member "New member"
		la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
		la var uuid "UUID (Kobo)" 
		la var sid "Submission ID (Kobo)"
		
		drop _*
		//drop fielddays fieldname days
		//drop calcoldage //already integrated to roster in KOBO
		
		la lang ${LNG}
		save "$zzz/`sheet'.dta" , replace
		
	}
	
	
	* EMPLOYED MEMBERS
	**************************
	local sheet "art_bekerja"
	if regexm("$indsheets", "`sheet'")==1 {	
		cap confirm file "$zzz/`sheet'.dta" 
		if _rc ~= 0 {
			import excel "$wd/xls/$excel_file.xlsx", ///
				sheet(`sheet') firstrow clear allstring 
			destring , replace 	
			

			// Apply labels
			applylab 
			
			// Renaming
			//rename *_hhid hhid 
			rename ac2_id fmid
			rename ac2_name name
			rename _parent_index sid
			rename _submission__id koboid
			rename _submission__uuid uuid
			
			//Bring HHID from master table
			merge m:1 sid koboid uuid using "$zzz/${sheet1}.dta", keepusing(hhid) 
			drop if _merge==2
			drop _merge 
			order hhid, first
			
					
			
			//Check duplicates 
			bys hhid fmid: g N = _N
					as N == 1, r 
						cap drop N

			unique hhid fmid 
				if `r(N)' ~= `r(unique)' {
					bys hhid fmid : g n = _n 
						bro if n > 1 
					as n == 1, r
						drop if n > 1 
							cap drop n
				}

			unique hhid fmid
				as r(N) == r(unique)	
					
							
			// Relabel if necessary
			la lang ENG
			la var fmid "Family member ID"
			la var name "Full name of family member "
		
			la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
			la var uuid "UUID (Kobo)" 
			la var sid "Submission ID (Kobo)"
			
			drop _*
			
			la lang ${LNG}
			save "$zzz/`sheet'.dta" , replace
		}
		
	}
	
	
	* POTENTIAL MIGRANT MEMBERS
	**************************
	local sheet "art_rmigrasi"
	if regexm("$indsheets", "`sheet'")==1 {	
		cap confirm file "$zzz/`sheet'.dta" 
		if _rc ~= 0 {
			import excel "$wd/xls/$excel_file.xlsx", ///
				sheet(`sheet') firstrow clear allstring 
			destring , replace 	
			
			// Apply labels
			applylab 
			
			// Renaming
			//rename *_hhid hhid 
			rename mg2_id fmid
			rename mg2_name name
			rename _parent_index sid
			rename _submission__id koboid
			rename _submission__uuid uuid
					
			//Bring HHID from master table
			merge m:1 sid koboid uuid using "$zzz/${sheet1}.dta", keepusing(hhid) 
			drop if _merge==2
			drop _merge 
			order hhid, first
			
			//Check duplicates 
			bys hhid fmid: g N = _N
					as N == 1, r 
						cap drop N

			unique hhid fmid 
				if `r(N)' ~= `r(unique)' {
					bys hhid fmid : g n = _n 
						bro if n > 1 
					as n == 1, r
						drop if n > 1 
							cap drop n
				}

			unique hhid fmid
				as r(N) == r(unique)	
					
							
			// Relabel if necessary
			la lang ENG
			la var fmid "Family member ID"
			la var name "Full name of family member "
			
			la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
			la var uuid "UUID (Kobo)" 
			la var sid "Submission ID (Kobo)"
			
			drop _*
			
			la lang ${LNG}
			save "$zzz/`sheet'.dta" , replace
		}
	}
	

	* RETURNING MEMBERS
	**************************
	local sheet "art_kmigrasi"
	if regexm("$indsheets", "`sheet'")==1 {		
		cap confirm file "$zzz/`sheet'.dta" 
		if _rc ~= 0 {
			import excel "$wd/xls/$excel_file.xlsx", ///
				sheet(`sheet') firstrow clear allstring 
			destring , replace 	
			
						
			// Apply labels
			applylab 
			
			// Renaming
			//rename *_hhid hhid 
			rename mg7_id fmid
			rename mg7_name name
			rename _parent_index sid
			rename _submission__id koboid
			rename _submission__uuid uuid
		
			//Bring HHID from master table
			merge m:1 sid koboid uuid using "$zzz/${sheet1}.dta", keepusing(hhid) 
			drop if _merge==2
			drop _merge 
			order hhid, first			
	
			
			//Check duplicates 
			bys hhid fmid: g N = _N
					as N == 1, r 
						cap drop N

			unique hhid fmid 
				if `r(N)' ~= `r(unique)' {
					bys hhid fmid : g n = _n 
						bro if n > 1 
					as n == 1, r
						drop if n > 1 
							cap drop n
				}

			unique hhid fmid
				as r(N) == r(unique)	
					
							
			// Relabel if necessary
			la lang ENG
			la var fmid "Family member ID"
			la var name "Full name of family member "
			
			la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
			la var uuid "UUID (Kobo)" 
			la var sid "Submission ID (Kobo)"
			
			drop _*
			
			la lang ${LNG}
			save "$zzz/`sheet'.dta" , replace
		}
	}

	
	* LIVING TEMPORARILY MEMBERS
	**************************
	local sheet "art_migrasi"
	if regexm("$indsheets", "`sheet'")==1 {		
		cap confirm file "$zzz/`sheet'.dta" 
		if _rc ~= 0 {
			import excel "$wd/xls/$excel_file.xlsx", ///
				sheet(`sheet') firstrow clear allstring 
			destring , replace 	
			
			// Apply labels
			applylab 
			
			// Renaming
			//rename *_hhid hhid 
			rename mg11_id fmid
			rename mg11_name name
			rename _parent_index sid
			rename _submission__id koboid
			rename _submission__uuid uuid
					

			//Bring HHID from master table
			merge m:1 sid koboid uuid using "$zzz/${sheet1}.dta", keepusing(hhid) 
			drop if _merge==2
			drop _merge 
			order hhid, first
			
			
			//Check duplicates 
			bys hhid fmid: g N = _N
					as N == 1, r 
						cap drop N

			unique hhid fmid 
				if `r(N)' ~= `r(unique)' {
					bys hhid fmid : g n = _n 
						bro if n > 1 
					as n == 1, r
						drop if n > 1 
							cap drop n
				}

			unique hhid fmid
				as r(N) == r(unique)	
					
							
			// Relabel if necessary
			la lang ENG
			la var fmid "Family member ID"
			la var name "Full name of family member "
			
			la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
			la var uuid "UUID (Kobo)" 
			la var sid "Submission ID (Kobo)"
			
			drop _*
			
			la lang ${LNG}
			save "$zzz/`sheet'.dta" , replace
		}
	}
	
	
	* CHILDREN MISSING SCHOOL
	**************************
	local sheet "art_nosekolah"
	if regexm("$indsheets", "`sheet'")==1 {		
		cap confirm file "$zzz/`sheet'.dta" 
		if _rc ~= 0 {
			import excel "$wd/xls/$excel_file.xlsx", ///
				sheet(`sheet') firstrow clear allstring 
			destring , replace 	
			
			// Apply labels
			applylab 
			
			// Renaming
			//rename *_hhid hhid 
			rename sh17_id fmid
			rename sh17_name name
			rename _parent_index sid
			rename _submission__id koboid
			rename _submission__uuid uuid
					

			//Bring HHID from master table
			merge m:1 sid koboid uuid using "$zzz/${sheet1}.dta", keepusing(hhid) 
			drop if _merge==2
			drop _merge 
			order hhid, first
			
			
			//Check duplicates 
			bys hhid fmid: g N = _N
					as N == 1, r 
						cap drop N

			unique hhid fmid 
				if `r(N)' ~= `r(unique)' {
					bys hhid fmid : g n = _n 
						bro if n > 1 
					as n == 1, r
						drop if n > 1 
							cap drop n
				}

			unique hhid fmid
				as r(N) == r(unique)	
					
							
			// Relabel if necessary
			la lang ENG
			la var fmid "Family member ID"
			la var name "Full name of family member "
			
			la var koboid "Household ID (Kobo)" // Generated by the KOBO system.
			la var uuid "UUID (Kobo)" 
			la var sid "Submission ID (Kobo)"
			
			drop _*
			
			la lang ${LNG}
			save "$zzz/`sheet'.dta" , replace
		}
	}
	
	
}

********************************************************************************
********************************************************************************

*-------------------------------------------------------------------------------
* DATA CLEANING and ASSERTIONS by MODULES
*-------------------------------------------------------------------------------

	* (M0) PASSPORT OF QUESTIONNAIRE
	************************************
	{
		use "$zzz/${sheet1}.dta", clear
		
	// ASSERTIONS 
	
		* Identifiers 
// 		as hhid<. , r
		as koboid<.
		as sid<. 
		as uuid!=""
		
		* Agreement
		as agreement == 1 | agreement == 2
		//as pp_end == 1 if agreement == 1 
		as refuse_text <. if agreement == 2
		as refuse_text ==. if agreement == 1

		* HH size
		as tothhm<. , r 
		/*
		as hhsize_wrong == . 			
		as oldhhsize == fmid_max if newmember == 2 
		as hhsize == fmid_max if newmember == 2  
		//as newmember < . if agreement == 1
		//as newmember ==. if agreement == 2		
		as newmember<. if agreement==1 & sample==1 
		as newmember==. if agreement==1 & sample==2 //automatically asked info about all members
		*/
		
		* Respondent	
		//as resp_fmid == respnum 
		//as resp_name_wrong == . 	
		as resp_gender == 1 | resp_gender == 2 if agreement == 1 , r 
		as resp_gender ==. if agreement == 2 
		//as resp_year <. if agreement == 1
		//as resp_year > 1900 & resp_year < 2006 if agreement == 1
		
		* Start, end, submission and next call time 
		as start_time<.
		as end_time<.
		as time<. 
		as start_date <= date , r 
		as end_date <= date , r //sometimes they submit after interview 
		as next_call<. if agreement==1 , r 
		as next_date<. if agreement==1 , r 
		as next_fmid <. if next_call == 1
		as next_fmid ==. if next_call == 2
		as next_phone <. if next_call == 1, r 
		as next_phone ==. if next_call == 2		
			format next_phone %13.0f
// 		as next_transfer <.  if agreement == 1, r //can be blank if it is the same number as called
		as resp_lang <. if agreement == 1 , r 
		as resp_mood <. if agreement == 1 , r 
		
		
		* Durations 
		//as dur_or >= 0 if agreement == 1
		//as dur_nr >= 0 if agreement == 1 & newmember==1
		//as round(dur_rr) == round(dur_or + dur_nr), r //issue with time stampt time_nr => missing if newmember is missing which is the case for old sample HHs 
		as dur_rr >= 0 if agreement == 1 , r
		as dur_sh >= 0 if agreement == 1 , r
// 		as dur_wb >= 0 if agreement == 1, r
		//as dur_mg_pot >= 0 if agreement == 1 
		//as dur_mg_ret >= 0 if agreement == 1 		
		//as dur_mg_liv >= 0 if agreement == 1 	
// 		as dur_mg >= 0 if agreement == 1, r
		//as dur_ac_emp >= 0 if agreement == 1 	
		//as dur_ac_look >= 0 if agreement == 1	
		as dur_ac >= 0 if agreement == 1, r
		as dur_vw >= 0 if agreement == 1, r
		as dur_in >= 0 if agreement == 1, r
		as dur_sv >= 0 if agreement == 1, r 
		cap as dur_ga >= 0 if agreement == 1, r 
		as dur_tot >= 0 if agreement == 1, r
				
				
	// VARIABLES TO KEEP	
		#delimit; 
		glo keys 
			round 
			hhid 
			koboid
			uuid 
			sid 
			agreement
		;
		glo passportvars
			province
			regency
			district
			village 
			rurban 
			ea 
			hhtype
			date
			time 
			start_time
			end_time
			//ocode
			//deviceid 
			//qrcode 	
			//bar_catiid 
			//replacement
			//replacedhhid
			refuse_text 
			refuse_other
			tothhm
			//newmember 
			//nohhhead
			resp_fmid 
			resp_name 
			resp_gender 
			//resp_year 
			resp_lang 
			resp_mood 
			hh_name
			next_*
			dur_*

		;
		#delimit cr
		
		keep $keys $passportvars 
		order $keys $passportvars 
		la lang ${LNG}
			
		save "$raw/${dta_file}_${date}_M00_passport.dta", replace
	
	}

	* (M1) HH ROSTER
	************************************
	{
		use "$zzz/hhmember.dta", clear
		
		//Assertions
// 			as hhid<. , r 
			as fmid<. , r 
			
			as name!="", r 
			as age<. , r 
			as residing<. if new_member==. , r 
			as leave_reason <. if residing == 2
			as leave_reason ==. if residing == 1
			
			
			cap as correct_name ~= "" if inlist(correct_name_date,2,4)==1, r 
			cap as correct_name == name if inlist(correct_name_date,2,4)==1
			cap as correct_name == "" if inlist(correct_name_date,1,3)==1
			
			as correct_dob ~="" if  inlist(correct_name_date,3,4)==1	
			as art_age_correct ==age if  inlist(correct_name_date,3,4)==1				
			as correct_dob =="" if inlist(correct_name_date,1,2)==1
					
			as new_member==1 | new_member==., r //one mistake in newmember
			
			as art_name_new~="" if new_member<. , r 
			as new_art_gender<. if new_member<. , r 
			as new_art_dob~="" if new_member<. ,r 
			as new_art_age<. if new_member<. , r 
			
			as art_name_new==name if new_member<. , r 
			as new_art_gender==gender if new_member<. , r 
			as new_art_dob==dob if new_member<. , r 
			as new_art_age==age if new_member<. , r 
						
						
					
		cap drop art_dob  
		cap drop art_name_new 
		cap drop new_art_gender 
		cap drop new_art_dob 
		cap drop new_art_age 
		cap drop all_age
		cap drop add_newm 
		cap drop new_member_orig
	
		tempfile roster
		save `roster'

		
		use  "$raw/${dta_file}_${date}_M00_passport.dta", clear 		
		keep $keys tothhm dur_rr  date time
		keep if agreement == 1
		merge 1:m hhid using `roster'
		drop _merge 
		

		unique hhid fmid  
			bys hhid (fmid): g N = _N 
				list hhid sid N tothhm fmid if N!=tothhm
					cap drop N 
		
		la lang ${LNG} 
		save "$raw/${dta_file}_${date}_M01_roster.dta", replace
		
	}
	
	
	* (M2) SHOCKS
	************************************
	{
		use "$zzz/${sheet1}.dta", clear
		
		keep hhid koboid uuid sid agreement wat* sh* //sekolah_art
		keep if agreement == 1
			cap drop agreement 
			cap drop sh_time
			cap drop sh16_warn1 sh16_warn2 //notes
			
			
			
	//ASSERTIONS 
// 		as hhid<. 
		as koboid<.
		as uuid!=""
		as sid<. 
		
		as sh1 ~=. , r 
		tab sh1, m 

		as sh2 ~=. if sh1 == 1 , r
		as sh2 ==. if sh1 == 2 
		as sh2 >= 0 & sh2 <= 30 if sh1 == 1 , r

		as sh3 ~=. if sh1 == 1 , r 
		as sh3 ==. if sh1 == 2 

		as sh4 ~= . , r 
		as (sh4 >= 0 & sh4 <= 24) , r 

		as sh5 ~= . , r 
		as (sh5 >= 0 & sh5 <= 24) , r 

		as sh6 ~= . , r 
		as (sh6_1 >= 0 & sh6 ~= .) if sh6==1 , r
		as sh6_1 == .  if sh6==99
	
		as sh7 ~= . if sh6==1 , r
		as (sh7 >= 1 & sh7 <= 6) | sh7==96 if sh6==1, r
		as sh7_other~= . if sh7==96 
		tab sh7, m 
		ta sh7_other, m

		as sh8 ~= . , r 
		tab sh8, m 

		as sh9_x >0 & sh9_x~=. if sh8 == 2 | sh8 == 3 , r 
		as sh9_x ==. if sh8 == 1 | sh8 ==4

		as sh10 >0 & sh10~=. if sh8 == 2 | sh8 == 3 , r  //sh9_x ~=. 
		as sh10 ==. if sh8 == 1 | sh8 ==4

		as sh11 >0 & sh11~=. if sh8 == 2 | sh8 == 3 , r //sh9_x ~=. 
		as sh11 ==. if sh8 == 1 | sh8 ==4

		tostring sh11_other, replace 
		replace sh11_other = subinstr(sh11_other, ".","",.)
		as sh11_other!="" if sh11==96
		as sh11_other=="" if sh11!=96
		
		
		as sh12~=. , r 
		
		as sh13~=. if sh12==1, r 
		as inrange(sh13,0,30)==1 if sh12==1 , r 
		as sh13==. if inlist(sh12, 2,3)==1
		
		as sh14~=. , r 
		
		as sh15~=. if sh14==1 , r 
		as inrange(sh15,0,30)==1 if sh14==1 , r 
		as sh15==. if inlist(sh14, 2,3)==1
		
		
		as sh16<. ,r 
		as sh17~="" if sh16==1, r 
		as sh17=="" if sh16~=1
		
		as sh19~=. if sh16==1
		as sh19==. if sh16~=1
		
		
		ren sh17* sh17_*
		ren sh21* sh21_*
		ren *, lower 
		
// 		zogs 
// 		loc var ""
// 		loc j = 1 
// 		foreach i of numlist 2/22 {
// 			loc var = "`var' sh`i'"
// 				di "`var'"
// 				cap order sh`i' , after(sh`j')
// 					loc j = `i'
//		
//					
// 		}
// // 		order `var', a(hhid)  seq 
//
// 		order sh2 sh3 sh4 sh5 sh6* sh7* sh8 sh9* sh10 sh11* sh12 sh13 sh14 sh15 ///
// 			sh16 sh17* sh19* sh20 sh21* sh22, after(sh1)
// 		zogs 
		
		la lang ${LNG}


		merge 1:1 koboid hhid sid uuid ///
		using "$raw/${dta_file}_${date}_M00_passport.dta" ///
		, assert(2 3) nogen keep( 3 ) update ///
		keepusing(round date time dur_sh ) 

		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M02_shocks.dta", replace

	}

	
	* (M2) CHILDREN MISSING SCHOOL
	************************************
	{
		use "$zzz/art_nosekolah.dta", clear
		
		//Assertions
// 			as hhid<. , r 
			as fmid<.,r 
			as name!="", r 
			
			as sh18<.
			as sh18<=5

		tempfile schoolmiss
		save `schoolmiss'
		
		use  "$raw/${dta_file}_${date}_M00_passport.dta", clear 		
		keep $keys date time
		keep if agreement == 1
		merge 1:m hhid using `schoolmiss'
		drop _merge 
		

		unique hhid fmid  
	
		
		la lang ${LNG} 
		save "$raw/${dta_file}_${date}_M02_schoolmiss.dta", replace
		
	}
	
	
	* (M3) WELLBEING 
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		
		keep hhid koboid uuid sid round agreement wb* air* telehealth* //rent* home*
			keep if agreement == 1
				cap drop agreement 
				
		cap drop *_warn		
		cap drop *_warn1 
		cap drop *_warn2
		
		
	//ASSERTIONS
// 		as hhid<.
// 		as koboid<.
// 		as uuid!=""
// 		as sid<. 
//		
// 		as wb1<. ,r 
// 		as inrange(wb1, 1,5)==1, r 
// 			ta wb1, m
//		
// 		as wb2<. ,r 
// 		as inrange(wb2, 1,5)==1
// 			ta wb2, m
//		
// 		as wb3<.
// 		as inrange(wb3, 1,5)==1
// 			ta wb3 , m
//		
// 		as wb4<.
// 		as inrange(wb4, 1,5)==1
// 			ta wb4 , m
//		
// 		as wb5<.
// 			ta wb5, m
//		
// 		as wb6<.
// 		as inrange(wb6, 1,3)==1
// 			ta wb6, m
//		
// 		as wb7<.
// 			tab wb7, m 
//			
// 		as wb8<.
// 		as inrange(wb8, 1,3)==1
// 			tab wb8, m
//		
// 		as wb9<.
// 			tab wb9, m 
//		
// 		as wb10<. if wb9==1
// 			tab wb9 wb10, m 
//					
// 		as wb11<.
// 			tab wb11, m 
//		
// 		as wb12<.
// 			tab wb12, m 
//			
// 		as wb13!="" if wb12==1	
// 		as wb13=="" if wb12==2
//		
// 		as wb14<. 
// 			tab wb14, m
//			
// 		tostring wb15, replace 
// 		replace wb15="" if wb15=="."
//		
// 		as wb15!="" if round>=2	
// 		as wb15=="" if round<2
//			
// 		as wb16<=100000 if round>=2
// 		as wb16==. if round<2
		
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time /* dur_wb */ ) 
					
		la lang ${LNG}
		
		save "$raw/${dta_file}_${date}_M03_wellbeing.dta", replace

	}
	
	
	* (M4) MIGRATION  
	*************************************
	{
		** PASSPORT
		**********************
		use "$zzz/${sheet1}.dta", clear
		
		keep hhid koboid uuid sid agreement *mg* OR OS OT OU
		keep if agreement == 1
			cap drop agreement 
	
		ren mg2 mg2_fmid  
		ren mg7 mg7_fmid 
		ren mg11 mg11_fmid  	
				
		reshape long mg2@ mg7@ mg11@ , i(koboid hhid sid) j(fmid)   
	
		// Renaming 		
			rename OR mg22
			rename OS mg23
			rename OT mg24
			rename OU mg25

			
		//ASSERTIONS
// 			as hhid<. 
			as fmid<. , r 
			
	
		//RELABEL	
			foreach x in mg2 mg7 mg11 {
				
				la lang ENG
				loc `x'lab: var lab `x'_fmid
				la var `x'  "``x'lab'"
					note `x': ``x'lab'
					
							
				la lang IND
				loc `x'lab: var lab `x'_fmid
				la var `x'  "``x'lab'"
					note `x': ``x'lab'
			}
			
			
			foreach var in mg22 mg23 mg24 mg25 {
				la lang ENG
				la var `var' `"${`var'_lben}"'
				
				la lang IND
				la var `var' `"${`var'_lbin}"'
			}
			
			
	
		cap rename *_ *
		cap drop mg*_fmid 
		cap drop mg_time
		
		la lang ${LNG}
		
		merge 1:1 koboid hhid sid uuid fmid ///
			using "$raw/${dta_file}_${date}_M01_roster.dta"	///
				, assert(1 2 3) keep(3) nogen update ///keep(1 3)
					keepusing(name age residing date time)
					

		la lang ${LNG}
		save "${zzz}/mig.dta", replace

	
		** POTENTIAL MIGRATION
		**********************
		if regexm("$indsheets", "art_rmigrasi")==1 {	
			use "$zzz/art_rmigrasi.dta", clear

			//ASSERTIONS
// 				as hhid<.
				as fmid<. , r 
				
			
			la lang ${LNG}		
			tempfile potmig
			save `potmig'
		
		}
		** RETURN MIGRATION
		**********************
		if regexm("$indsheets", "art_kmigrasi")==1 {			
			use "$zzz/art_kmigrasi.dta", clear
			
			//ASSERTIONS
// 				as hhid<.
				as fmid<. , r 
				
				
			la lang ${LNG}					
			tempfile retmig
			save `retmig'
		}
		** CURRENT MIGRATION 
		**********************
		if regexm("$indsheets", "art_migrasi")==1 {	
			use "$zzz/art_migrasi.dta", clear
			
			//ASSERTIONS
// 				as hhid<. , r 
				as fmid<. ,r 
				
		
			la lang ${LNG}			
			tempfile livmig
			save `livmig'
		}
		
		** COMBINE MIGRATION 
		**********************
		use  "${zzz}/mig.dta", clear 
		
		** Potential migration
		if regexm("$indsheets", "art_rmigrasi")==1 {	
			merge 1:1 koboid sid hhid fmid   ///
					using `potmig' ///
						, assert(1 2 3) nogen update keep(1 3) ///
							keepusing(mg*)
						
				order mg3 mg4 mg5 , after(mg2)
				replace mg2 = . if mg2 == 0 	
		}

		** Return migration
		if regexm("$indsheets", "art_kmigrasi")==1 {	
			merge 1:1 koboid sid hhid fmid   ///
					using `retmig' ///
						,nogen update keep(1 3) ///
							keepusing(mg*)

				order mg8 mg9, after(mg7)
				replace mg7 = . if mg7 == 0 	
		}
		
		** Current migratns 
		if regexm("$indsheets", "art_migrasi")==1 {	
			merge 1:1 koboid sid hhid fmid  ///
					using `livmig' ///
						, assert(1 2 3) nogen update keep(1 3) ///
							keepusing(mg*)
						
				//order mg12-mg24, after(mg11)
				order mg20 , after(mg19)
				replace mg11 = . if mg11 == 0 	
		}
		
		la lang ${LNG}
		merge m:1 koboid sid hhid  ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing(round /* dur_mg* */ ) 
			
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M04_migration.dta", replace
	}
	
	
	* (M5) ACTIVITY  
	*************************************	
	{
		** PASSPORT
		**********************	
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement ac* reemp* 
		keep if agreement == 1
			cap drop agreement 
		
		ren ac2 ac2_fmid  
		ren ac10 ac10_fmid 
		ren ac12 ac12_fmid  
		ren ac14 ac14_fmid  
		ren ac15 ac15_fmid 

// 		drop ac15 //note 
		
		reshape long  ac2@ ac10@ ac12@ ac14@ ac15_@, i(koboid hhid sid) j(fmid)   
		
		ren ac15_ ac15 
		
		//ASSERTIONS
// 			as hhid<.
			as fmid<.
			

		//RELABEL
			foreach x in ac2 ac10 ac12 ac14  {
				
				la lang ENG
				loc `x'lab: var lab `x'_fmid
				la var `x'  "``x'lab'"
					note `x': ``x'lab'
					
							
				la lang IND
				loc `x'lab: var lab `x'_fmid
				la var `x'  "``x'lab'"
					note `x': ``x'lab'
			}
			
		cap drop ac*_fmid 
		
		la lang ${LNG}
		merge 1:1 koboid hhid sid fmid ///
			using "$raw/${dta_file}_${date}_M01_roster.dta" ///
				, assert(1 2 3) keep(3) nogen update ///keep(1 3)
					keepusing(name age residing /*newmember*/ date time)
					
		la lang ${LNG}	
		save "${zzz}/act.dta", replace		
				
		** CURRENT EMPLOYMENT
		**********************
		if regexm("$indsheets", "art_bekerja")==1 {	
		
			use "$zzz/art_bekerja.dta", clear

			//ASSERTIONS
				

			la lang ${LNG}		
			tempfile emp
			save `emp'
		}
		
		
		** COMBINE EMPLOYMENT
		**********************
		use  "${zzz}/act.dta", clear 
		
		if regexm("$indsheets", "art_bekerja")==1 {	
			merge 1:1 koboid sid hhid fmid  ///name date time
					using `emp' ///
						,  nogen update keep(1 3) ///
							keepusing(ac* *act* )
						
				//order ac3 ac3z ac4 ac5 ac6 ac7  , after(ac2)
				//replace ac2 = 0 if ac2 == . 	
		}
		
		
		la lang ${LNG}
		merge m:1 koboid sid hhid  ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round dur_ac* ) 
			
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M05_activity.dta", replace

	}
	
	
	* (M6) VIEWS
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
			keep hhid koboid uuid sid agreement vw*  
			keep if agreement == 1
				cap drop agreement 
		
		//ASSERTIONS
// 			as hhid<.
			
		
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time dur_vw ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M06_views.dta", replace 
	}
		
		
	* (M7) INCOMES
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement inc* 
		keep if agreement == 1
			cap drop agreement 
			
		//ASSERTIONS
// 			as hhid<.
			
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time dur_in* ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M07_incomes.dta", replace

	}			
	
	
	* (M8) SAVINGS
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement sv* 
		keep if agreement == 1
			cap drop agreement 
			
		//ASSERTIONS
		
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time dur_sv ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M08_savings.dta", replace

	}
		
		
	* (M9) GREEN AGENDA 
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement ga* 
		keep if agreement == 1
		cap drop agreement 
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M09_greenagenda.dta", replace
		
	}
	
	
	* (M10) EXPERIMENTS  
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement xp* 
		keep if agreement == 1
		cap drop agreement 
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M10_experiment.dta", replace
		
	}
	
	
	* (M11) INTERNET   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement net* 
		keep if agreement == 1
		cap drop agreement 
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M11_internet.dta", replace
		
	}
	
	
	* (M12) E-COMMERCE  
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement ecom* 
		keep if agreement == 1
		cap drop agreement 
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M12_ecommerce.dta", replace
		
	}
		
	* (M13) TRUST AND TAX   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement trust* tax* random* 
		keep if agreement == 1
		cap drop agreement 
		
		
		foreach i in a b c d e {
			cap as tax3_`i' == . if trust3_`i'_001 ~=. 
				cap replace tax3_`i' = trust3_`i'_001 if tax3_`i' == .
				
			cap as tax4_`i' == . if trust4_`i' ~=. 
				cap replace tax4_`i' = trust4_`i' if tax4_`i' == .
		}		
		
		cap drop *_001 
		cap drop trust4_* 
		
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M13_trust.dta", replace
		
	}
		
		
	* (M14) GASOLINE PRICE REFORM  
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement modul_14_note-elasticity_supp7
		keep if agreement == 1
		cap drop agreement 
			
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M14_gasoline.dta", replace
		
	}
	
	
	* (M15) COPING STRATEGIES   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement modul_15_note-randomization6A
		keep if agreement == 1
		cap drop agreement 
			
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M15_coping.dta", replace
		
	}

	
    * (M16) AIR QUALITY MONITOR   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement modul_16_note-aqm_10
		keep if agreement == 1
		cap drop agreement 
			
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M16_aqm.dta", replace
		
	}

    
    * (M17) LPG SUBSIDY   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement modul_17_note-lpg_cope3_other
		keep if agreement == 1
		cap drop agreement 
			
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M17_lpg.dta", replace
		
	}    

    
    * (M18) ELECTRICITY SUBSIDY   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement modul_18_note-ele_cope3_other
		keep if agreement == 1
		cap drop agreement 
			
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M18_electricity.dta", replace
		
	}       

    
    * (M19) GOVERNMENT SPENDING   
	*************************************
	{
		use "$zzz/${sheet1}.dta", clear
		keep hhid koboid uuid sid agreement modul_19_note-fiscal3
		keep if agreement == 1
		cap drop agreement 
			
		
		//ASSERTIONS
			
		la lang ${LNG}
		merge 1:1 koboid hhid sid uuid ///
			using "$raw/${dta_file}_${date}_M00_passport.dta" ///
				, assert(2 3) nogen keep( 3 ) update ///
					keepusing( round date time  ) 
					
		
		la lang ${LNG}
		save "$raw/${dta_file}_${date}_M19_govspending.dta", replace
		
	}        
	

********************************************************************************
********************************************************************************

*-------------------------------------------------------------------------------
* FIXES by MODULES
*-------------------------------------------------------------------------------
{
	* (M0) PASSPORT
	************************************
		use "$raw/${dta_file}_${date}_M00_passport.dta", clear

		cap export excel ///
			using "$fix/${dta_file}_${date}_M00_passport.xlsx" ///
				if ${date_filter} , ///
					sheet("$date") firstrow(var) nolabel replace 

		// data fixes 

	
		save "${dta}/${dta_file}_${date}_M00_passport.dta", replace
		

	
	* (M1) ROSTER
	************************************
		use "$raw/${dta_file}_${date}_M01_roster.dta", clear

			cap export excel ///
				using "$fix/${dta_file}_${date}_M01_roster.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 
						
		// data fixes 

		
		save "${dta}/${dta_file}_${date}_M01_roster.dta", replace

	* (M2) SHOCKS
	************************************
		use "$raw/${dta_file}_${date}_M02_shocks.dta", clear
		
			cap export excel ///
				using "$fix/${dta_file}_${date}_M02_shocks.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 
		
		// data fixes 
		
		
		
		save "${dta}/${dta_file}_${date}_M02_shocks.dta", replace
		

	* (M2) CHILDREN MISSING SCHOOL
	************************************
		use "$raw/${dta_file}_${date}_M02_schoolmiss.dta", clear
		
			cap export excel ///
				using "$fix/${dta_file}_${date}_M02_schoolmiss.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 
		
		// data fixes 
		
		
		
		save "${dta}/${dta_file}_${date}_M02_schoolmiss.dta", replace
		
		
		
			
	* (M3) WELLBEING 
	*************************************
		use "$raw/${dta_file}_${date}_M03_wellbeing.dta", clear

			cap export excel ///
				using "$fix/${dta_file}_${date}_M03_wellbeing.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 
	   
		// data fixes 


		
		save "${dta}/${dta_file}_${date}_M03_wellbeing.dta", replace
		


	* (M4) MIGRATION  
	*************************************
		use "$raw/${dta_file}_${date}_M04_migration.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M04_migration.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M04_migration.dta", replace

	
	* (M5) ACTIVITY  
	*************************************	
		use "$raw/${dta_file}_${date}_M05_activity.dta", clear

			cap export excel ///
				using "$fix/${dta_file}_${date}_M05_activity.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 
		

		// data fixes 

		save "${dta}/${dta_file}_${date}_M05_activity.dta", replace

	
	* (M6) VIEWS
	*************************************
		use "$raw/${dta_file}_${date}_M06_views.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M06_views.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 

		
		save "${dta}/${dta_file}_${date}_M06_views.dta", replace
		
			

	* (M7) INCOMES
	*************************************
		use "$raw/${dta_file}_${date}_M07_incomes.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M07_incomes.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 



		save "${dta}/${dta_file}_${date}_M07_incomes.dta", replace


	* (M8) SAVINGS
	*************************************
		use "$raw/${dta_file}_${date}_M08_savings.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M08_savings.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M08_savings.dta", replace
		
		
	
	* (M9) GREEN AGENDA 
	*************************************
		use "$raw/${dta_file}_${date}_M09_greenagenda.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M09_greenagenda.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M09_greenagenda.dta", replace
		
		
	* (M10) EXPERIMENTS 
	*************************************
		use "$raw/${dta_file}_${date}_M10_experiment.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M10_experiment.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M10_experiment.dta", replace		
		
		
		
	* (M11) INTERNET 
	*************************************
		use "$raw/${dta_file}_${date}_M11_internet.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M11_internet.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M11_internet.dta", replace		
		
		
	* (M12) E-COMMERCE 
	*************************************
		use "$raw/${dta_file}_${date}_M12_ecommerce.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M12_ecommerce.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M12_ecommerce.dta", replace
		
		
	* (M13) TRUST and TAX  
	*************************************
		use "$raw/${dta_file}_${date}_M13_trust.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M13_trust.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M13_trust.dta", replace
		
		
	* (M14) GASOLINE PRICE REFORM   
	*************************************
		use "$raw/${dta_file}_${date}_M14_gasoline.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M14_gasoline.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M14_gasoline.dta", replace
		
	* (M15) COPING STRATEGIES   
	*************************************
		use "$raw/${dta_file}_${date}_M15_coping.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M15_coping.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M15_coping.dta", replace

    * (M16) AIR QUALITY MONITOR
	*************************************
		use "$raw/${dta_file}_${date}_M16_aqm.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M16_aqm.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M16_aqm.dta", replace

    * (M17) LPG SUBSIDY
	*************************************
		use "$raw/${dta_file}_${date}_M17_lpg.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M17_lpg.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M17_lpg.dta", replace        
        
    * (M18) ELECTRICITY SUBSIDY
	*************************************
		use "$raw/${dta_file}_${date}_M18_electricity.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M18_electricity.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M18_electricity.dta", replace                

    * (M19) GOVERNMENT SPENDING
	*************************************
		use "$raw/${dta_file}_${date}_M19_govspending.dta", clear

		cap export excel ///
				using "$fix/${dta_file}_${date}_M19_govspending.xlsx" ///
					if ${date_filter} , ///
						sheet("$date") firstrow(var) nolabel replace 

		// data fixes 


		save "${dta}/${dta_file}_${date}_M19_govspending.dta", replace             
}	

log close
	

********************************************************************************
********************************************************************************

/* 
*-------------------------------------------------------------------------------
* CALL LOG CHECKS
*-------------------------------------------------------------------------------
{
	
	* CALL LOGS 
	*************************************	
	{		
		//http://95.142.81.34/exp/export.html
		
		cap confirm file "${xls}/l2indo_calllog_${date}.csv"
		di _rc
		if _rc == 601 {
			di "downloading l2indo_calllog_${date}.csv ....  "
			copy "https://cabinet.z-analytics.tj/api/l2taj/call_log" ///
				"${xls}/l2indo_calllog_${date}.csv" , replace
		} 

		import delimited "${xls}/l2indo_calllog_${date}.csv",  delimiter(";") clear 
			//cap erase "${xls}/l2indo_calllog_${date}.csv"
			
		tostring _all , force replace
		//dropmiss, force
		
		
		destring, replace
		
		drop if status=="Uspeshniy"
		
		ren operator_id opid 
		la var opid "Operator's ID"
		*tostring opid, format(%04.0f) force replace
		
		ren id cid 
		la var cid "Case ID"
		
		ren hh_id hhid 
		la var hhid "Household ID"
			format hhid %9.0f 
		unique opid cid hhid 
		
		sort opid hhid cid 
		drop if opid==""
		unique opid cid hhid 

		/*
		//date/time/duration 
		foreach x in start_time end_time {
			ta `x'
			gen `x'_short= substr(`x', strpos(`x', " ")+1, .)
			replace `x'_short = subinstr(`x'_short, " GMT+0500 (Tajikistan Time)","",.)
			ta `x'_short
		}
		*/
		ren start_time  callstart
		g double call_start = clock(callstart, "YMDhms")
		la var call_start "Call starting time"
		format call_start %tcCCYY/NN/DD_HH:MM:SS

		ren end_time  callend
		g double call_end = clock(callend, "YMDhms")
		la var call_end "Call ending time"
		format call_end %tcCCYY/NN/DD_HH:MM:SS

		gen date = dofc(call_start)
		la var date "Date of Call"
		format date %tdCCYY/NN/DD	
		
		ren status call_status 
		la var call_status "Status of the call"
		
		bys opid hhid (call_start call_end): g call_last = call_status[_N]
		la var call_last "Status of the last call"
		
		cap drop call_dur  
		g double call_dur = round((call_end - call_start)/60000)
		la var call_dur  "Duration of the Call (min)"
		
		
		* bys opid cid hhid (call_start call_end): gen call_try = _n 
		bys opid hhid (call_start call_end): gen call_try = _n 
		
		la var call_try "Number of call tries per HH"
		
		order opid cid hhid date call_start call_end call_dur ///
				call_try call_status call_last 
		sort opid cid hhid date call_start call_end call_dur ///
				call_try call_status call_last 
		
		
		g log_round = .
		la var log_round "Survey Round"
		gen aux = dofc(call_end)
		replace log_round = 1 if dofc(call_end) >= mdy(3, 1, 2024) & dofc(call_end) < .
		keep if log_round == 1
		
		unique hhid if call_status == "SCS" 
		unique hhid if call_last == "SCS" 
		unique hhid if call_status == "SCS"  &  call_last == "SCS" 

		g completed = (call_last == "SCS" & call_status == "SCS" )
		la var completed "Completed calls"

		g refused = (call_last == "RFS")
		la var refused "Refused calls"
		
		g ongoing = ~(completed == 1 | refused == 1)
		la var ongoing "Ongoing calls"	
		
		assert completed + refused + ongoing == 1 
		
		cap drop start_time end_time
			
		save "${call}/${dta_file}_${date}_calllog.dta", replace

	}

	
	* COMPLETED or REFUSED CALLS
	*************************************
	{	
		//successful and refused calls matching with KOBO 	
		use "$call/${dta_file}_${date}_calllog.dta", clear 
		
			cap drop callstart callend 

			merge m:1 hhid ///
				using  "$raw/${dta_file}_${date}_M00_passport.dta" , ///
					assert(1 2 3 4 5) nogen update 		
			
			replace agreement = 1 if completed == 1
			
			drop if ongoing == 1 
			
			*keep if call_last == call_status
			
			bys opid hhid (call_end): keep if _n == _N 
			
	// 		keep if completed == 1 & ///
	// 			(call_status == "Complete"  &  call_last == "Complete") 
		
	// 		merge 1:1 hhid ///
	// 			using  "$dta/${dta_file}_${date}_M0_passport.dta", ///
	// 				assert(3) nogen 
		
		
			export excel ///
				using "${tab}/${dta_file}_${date}_completed.xlsx", ///
				sheet("List of HHIDs ($date)") firstrow(varl) replace
		
		tostring date, format(%tdNN/DD/CCYY) force replace
		
			//tabout opid agreement ///
				//using "${tab}/${dta_file}_${date}_completed_by_operators.xlsx", ///
					//sheet("${date}") style(xlsx) replace 

			//tabout date opid ///
				//using "${tab}/${dta_file}_${date}_completed_by_date.xlsx" ///
					//if agreement == 1 , ///
					//sheet("${date}") style(xlsx) replace 
			//tabout opid date ///
				//using "${tab}/${dta_file}_${date}_duration_by_operators.xlsx" , ///
					//sheet("${date}") style(xlsx) replace ///
						//sum c(mean call_dur)

		 
	}
		
	
	* ONGOING CALLS
	*************************************
	{
		// call count
		use "$call/${dta_file}_${date}_calllog.dta", clear 
		
		bys opid  hhid (call_start call_end): gen n = _n  //cid
		la var n "Order of tries"
		
	 bysort opid  hhid (call_start call_end): gen N = _N //cid
		la var N "Total # of tries"
		
		*replace N = 0 if refusal_reason == 7
		
		// Number of days tried
		bysort hhid date (call_start): gen nd = _n
		la var nd "Order of Tries per day"

		bysort hhid date (call_start): gen Nd = _N
		la var Nd "Total # of Tries per day"

		gen Nd_count_more5 = (Nd >= 5) 
		la var Nd_count_more5 "Days with at least 5 tries"

		gen Nd_count_less5 = (Nd < 5) 
		la var Nd_count_less5 "Days with less than 5 tries"
		*replace Nd_count_less5 = 0 if refusal_reason == 7

		sort opid hhid call_start call_end 

		gen notsameday = 1
		*replace notsameday = 0 if refusal_reason == 7
		bys hhid (call_start): replace notsameday = (date ~= date[_n-1]) 
	   la var notsameday "Different days of Tries"

		replace Nd_count_more5 = Nd_count_more5 * notsameday
		replace Nd_count_less5 = Nd_count_less5 * notsameday

		bysort hhid (call_start): egen Ndays = sum(notsameday)
		la var Ndays "# of different days tried" 
		*replace Ndays = 0 if refusal_reason == 7

		bysort hhid (call_start): egen Ndays_atleast5 = sum(Nd_count_more5)
		la var Ndays_atleast5 "# of Days (>=2 tries)"

		bysort hhid (call_start): egen Ndays_lessthan5 = sum(Nd_count_less5)
		la var Ndays_lessthan5 "# of Days (<2 tries)"

		gen approval_by_will = ""
		la var approval_by_will "Approval by Will"
		

		keep if ongoing == 1 
			
		merge m:1 hhid ///
				using  "$raw/${dta_file}_${date}_M00_passport.dta" , ///
				assert(1 2 3)  keepusing(agreement)
		keep if _merge == 1 
		cap drop _merge 
	
		drop callstart callend
		
		export excel ///
			using "${tab}/${dta_file}_${date}_ongoing.xlsx", ///
			sheet("List of HHIDs ($date)") firstrow(varl) replace 
	}


	* AUDIO LOG: Random sampling (10%)
	*************************************
	{
		use "$dta/${dta_file}_${date}_M00_passport.dta", clear


		* script for adding phone number from callog
		merge 1:m hhid ///
			using "$call/${dta_file}_${date}_calllog.dta" , ///
				keepusing(call_*) keep(3) nogen //chane it in each round !!!
		
		keep if call_status == "SCS" & call_last == "SCS"

		set seed $date 
		keep if $date_filter // including the refusals as well !!!!!!!
		capture drop __* 
		unique hhid
		sample 50 , by(ocode)
		
		
		*keep hhid fmid catiid date_* name age phone_* *_number dialing_phone

	// 	*bysort dialing_phone: gen N=_N
	// 	*bro if N>1

		*merge 1:m dialing_phone using ${aud}/audio_list_${date}.dta, keep(1 3) // assert(2 3)


	// 	gen audlink =""
	// 	la var audlink "Link to the audio file" 
	// 	local max=_N
	// 	di "`max'"
	// 	foreach i of numlist 1/`max' {
	// 	local filename=audfiles[`i']
	// 	local hhid=hhid[`i']
	// 	replace audlink="http://cati.nbt.uz/backup/_audio/`filename'" if _n == `i' 
	// 	di "`filename' `hhid'" 
	// 	*copy "http://cati.nbt.uz/backup/_audio_R05/`filename'" "${aud}/`hhid'_`filename'"
	// 	}

	// 	sort opid hhid call_start call_end 
	// 	su hhid 
	// 	return list
	// 	if `r(N)' > 0 {
	// 		export excel \\\
	// 			hhid opid date  time_called dialing_phone audlink audfiles audfilesize ///
	// 	 using $aud/${dta_file}_${date}_audlog_sample.xlsx , ///
	// 	sheet(all_audiolinks) firstrow(varl) nolabel replace 
	// 	}

		gen intro =.
		la var intro "Was the introduction accurate?"
		gen mood = .
		la var mood "How was the mood of the respondent?"
		gen handling =. 
		la var handling "How the operator is handling the respondent?"
		gen skip = .
		la var skip "How many questions did the operator skip?"
		gen guide = .
		la var guide "Did the operator guide to the answer?"
		gen expl =.
		la var expl "In general, did the operator explain the question correctly?"
		gen misinter =.
		la var misinter "What questions did the operator missinterpret?"
		gen concern =. 
		la var concern "Do you have any concern with this interview?"
		gen lesson =.
		la var lesson "Do you have any lessons from this interview?"
		gen comment =.
		la var comment "Do you have any comments for the next training?"
		gen duration =.
		la var duration "Total duration of the interview (in minute)"

		
		
		
		su hhid 
		return list
		if `r(N)' > 0 {
			export excel ///
				using "$aud/${dta_file}_${date}_audlog_sample.xlsx" , ///
					sheet("$date") firstrow(varl) nolabel  replace 
		}
	}		
	
	
}
		
		
