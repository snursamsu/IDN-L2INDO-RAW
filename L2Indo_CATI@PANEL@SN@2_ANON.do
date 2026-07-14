* L2Indo CATI ANONYMIZING DATA
* created by Samuel Nursamsu
* last modified on July 14, 2026

*-------------------------------------------------------------------------------
* PREAMBLES
*-------------------------------------------------------------------------------
	clear
	set more off
	set excelxlsxlargefile on
	macro drop _all
    cap log close
    
    *------------------------
    * Set Globals
    *------------------------
   
    * Will 
    *-----
//         global root "C:\Users\WB454594\OneDrive - WBG\Indonesia\Listening to Indonesia"
//         global base "$root\Data\Baseline"
//         global in "$root\Data\Clean"
//         global out "$root\L2Indo Team Folder\Team Data"

    * Sam
    *-----
        global root "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)"
        global in "$root\Cleaned data"
        global out "$root\Main data"
        global log "$root\Log"

    * Set latest round
    *------------------
    glo R 28
    
    * Log 
    *-----
    log using "$log/2_ANON_R${R}.log", replace
    
********************************************************************************        
********************************************************************************  

	//Passport
	use "$in/l2indo_M00_passport.dta", clear
	dropmiss, force
	drop koboid uuid sid regency district village refuse_text ///
	 hh_name next_date next_call next_fmid next_phone ///
	dur_pp dur_rr dur_sh dur_wb dur_mg dur_ac ///
	dur_in dur_ga hh_name_show dur_tot rurban dur_vw dur_sv
	
	capture drop resp_name
	
	save "$out/anon_l2indo_M00_passport.dta", replace
	
	//Roster
	use "$in/l2indo_M01_roster.dta", clear
	dropmiss, force
	drop koboid uuid sid dur_rr name dob correct_name_date ///
	correct_name correct_dob art_name_old art_name_correct ///
	art_age_correct sekolah_age dewasa_age_nodie dewasa_age ///
	dewasa_age_migrasi art_live art_leave_reason
	
	
	save "$out/anon_l2indo_M01_roster.dta", replace
	
	//Shocks
	use "$in/l2indo_M02_shocks.dta" , clear
	drop koboid uuid sid sh7_other sh11_other sh19_other dur_sh ///
	sh22
	
	save "$out/anon_l2indo_M02_shocks.dta", replace

	//Wellbeing
	use "$in/l2indo_M03_wellbeing.dta", clear
	drop koboid uuid sid wb15_other wb17_other
	dropmiss, force
	
	save "$out/anon_l2indo_M03_wellbeing.dta", replace
	
	//Migration
	use "$in/l2indo_M04_migration.dta" , clear
	dropmiss, force
	drop sid uuid koboid mg25 name age mg3_kab mg8_kab mg12_kab dur_mg
	
	save "$out/anon_l2indo_M04_migration.dta", replace

	//Activity
	use "$in/l2indo_M05_activity.dta", clear
	dropmiss, force
	drop koboid sid fmid uuid name ac7_other
	
	save "$out/anon_l2indo_M05_activity.dta", replace 

	//Views
	use "$in/l2indo_M06_views.dta", clear
	dropmiss, force
	drop koboid uuid sid vw33_other
	
	save "$out/anon_l2indo_M06_views.dta", replace

	//Incomes
	use "$in/l2indo_M07_incomes.dta", clear
	dropmiss, force
	drop inc6 koboid uuid sid

	save "$out/anon_l2indo_M07_incomes.dta", replace

	//Savings
	use "$in/l2indo_M08_savings.dta", clear
	dropmiss, force
	drop koboid uuid sid sv6 sv10_other sv14_other sv20_other sv21_other ///
		sv22_other sv27_other sv35 sv36_12 sv36_13 sv13_other /* sv16_text  sv23_text */
	
	save "$out/anon_l2indo_M08_savings.dta", replace

	//Green agenda
	use "$in/l2indo_M09_greenagenda.dta", clear
	dropmiss, force
	drop  koboid uuid sid
	
	save "$out/anon_l2indo_M09_greenagenda.dta", replace 
	
	//Internet
	use "$in\l2indo_M11_internet.dta" , clear
	dropmiss, force 
	drop koboid uuid sid net2_other net7_other dur_ga
	
	save "$out/anon_l2indo_M11_internet.dta", replace 
	
	//e-commerce
	use "$in\l2indo_M12_ecommerce.dta" , clear
	dropmiss, force
	drop koboid uuid sid ecom_time dur_ga
	
	save "$out/anon_l2indo_M12_ecommerce.dta", replace 
	
	//Trust
	use "$in\l2indo_M13_trust.dta", clear
	dropmiss, force
	drop koboid uuid sid trust_time

	save "$out/anon_l2indo_M13_trust.dta", replace 
	
	//Gasoline
	use "$in/l2indo_M14_gasoline.dta", clear
	
	dropmiss, force
	drop koboid uuid sid
	
	save "$out/anon_l2indo_M14_gasoline.dta", replace
	
	//Coping
	use "$in/l2indo_M15_coping.dta", clear
	
	dropmiss, force
	drop koboid uuid sid 
	
	save "$out/anon_l2indo_M15_coping.dta", replace

	//Air quality monitoring
	use "$in/l2indo_M16_aqm.dta", clear
	
	dropmiss, force
	drop koboid uuid sid 
	
	save "$out/anon_l2indo_M16_aqm.dta", replace    

	//LPG subsidy
	use "$in/l2indo_M17_lpg.dta", clear
	
	dropmiss, force
	drop koboid uuid sid 
	
	save "$out/anon_l2indo_M17_lpg.dta", replace   

	//Electricity subsidy
	use "$in/l2indo_M18_electricity.dta", clear
	
	dropmiss, force
	drop koboid uuid sid 
	
	save "$out/anon_l2indo_M18_electricity.dta", replace   

	//Government spending
	use "$in/l2indo_M19_govspending.dta", clear
	
	dropmiss, force
	drop koboid uuid sid 
	
	save "$out/anon_l2indo_M19_govspending.dta", replace       

	//Housing
	use "$in/l2indo_M20_housing.dta", clear
	
	dropmiss, force
	drop koboid uuid sid 
	
	save "$out/anon_l2indo_M20_housing.dta", replace           
    
	//Inequality
	use "$in/l2indo_M21_inequality.dta", clear
	
	dropmiss, force
	drop koboid uuid sid ineq_krt ineq_krt_name
	
	save "$out/anon_l2indo_M21_inequality.dta", replace    