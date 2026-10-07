* L2Indo CATI MERGING DOFILE - AUTOMATED
* created by Samuel Nursamsu
* last modified on September 29, 2026

* auto-discovery + auto-harmonization refactor
* --------------------------------------------
* 1. File discovery is automatic. For each module the program asks the folder
*    which l2ind_*_<module>.dta files actually exist (via the `dir' extended
*    macro function). Rounds that did not run a module are simply absent from
*    the list, so you never maintain per-module date lists again. New modules
*    in later rounds are picked up with no code change — just add the module
*    name to the `modules' list at the bottom.
* 2. Type harmonization is automatic. Before appending, each module scans its
*    files, finds variables that appear as string in some rounds and numeric in
*    others, and forces those to string. That replaces the hand-written
*    `tostring' / `capture drop' blocks you had per module.
* 3. Change or add the date list to capture which versions to use
*
* NOTE: `tostring ... , force' can lose precision on genuinely numeric vars that
* were accidentally stored as string in one round.

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
   
//     * Will
//         global root "C:\Users\WB454594\OneDrive - WBG\Indonesia\Listening to Indonesia"
//         global base "$root\Data\Baseline"
//         global in "$root\Data\dta"
//         global out "$root\Data\Clean"

    * Sam
    *-----
        global root "C:\Users\wb594719\OneDrive - WBG\EEAPV IDN Documents\Listening to Indonesia (L2INDO)"
        global in "$root\Temp data"
        global out "$root\Cleaned data"
        global log "$root\Log"

    * Set latest round
    *------------------
    glo R 30
    
    * Log 
    *-----
    log using "$log/1_MERGE_R${R}.log", replace
    
********************************************************************************        
********************************************************************************        
        
*-------------------------------------------------------------------------------
* FILE VERSION DATES — update this list when new rounds arrive
*-------------------------------------------------------------------------------
    global dates ///
        20240331 20240430 20240605 20240708 20240801 20240903 20241002 ///
        20241101 20241201 20250101 20250201 20250301 20250401 20250501 ///
        20250601 20250701 20250801 20250802 20250902 20251002 20251102 ///
        20251202 20260102 20260202 20260301 20260401 20260501 20260601 ///
        20260701 20260801

*-------------------------------------------------------------------------------
* GENERIC MERGE ENGINE
*-------------------------------------------------------------------------------
capture program drop mergemod
program define mergemod
    args mod

    * Build file list from global dates
    local flist ""
    foreach d of global dates {
        cap confirm file "$in/l2ind_`d'_`mod'.dta"
        if _rc == 0 {
            local flist `flist' l2ind_`d'_`mod'.dta
        }
    }
    
    local n : word count `flist'
    if `n' == 0 {
        di as error "  >> [`mod'] no files found — skipped."
        exit
    }
    di as text _n "==============================================================="
    di as text "Module `mod' : `n' file(s) found"

    *---------------------------------------------------------------
    * 2. Pass 1 — load each file, clean hhid, cache it, record types
    *---------------------------------------------------------------
    local strv ""
    local numv ""
    local k = 0
    foreach f of local flist {
        local ++k
        quietly use "$in/`f'", clear

        * consistent hhid cleaning (only touches string hhid)
        capture confirm string variable hhid
        if !_rc {
            quietly replace hhid = trim(itrim(hhid))
            quietly replace hhid = subinstr(hhid, "B", "825", .)
            quietly replace hhid = subinstr(hhid, "C", "825", .)
            capture destring hhid, replace
        }

        tempfile cache`k'
        quietly save `cache`k''

        foreach v of varlist _all {
            if substr("`:type `v''", 1, 3) == "str" {
                local strv `strv' `v'
            }
            else {
                local numv `numv' `v'
            }
        }
    }

    * variables that are string in some rounds AND numeric in others
    local conflict : list strv & numv
    if "`conflict'" != "" {
        di as text "  type conflicts forced to string: `conflict'"
    }

    *----------------------------------------------------------------
    * 3. Pass 2 — harmonize conflict vars in every cache, then append
    *----------------------------------------------------------------
    forvalues j = 1/`k' {
        quietly use `cache`j'', clear
        foreach v of local conflict {
            capture tostring `v', replace force
        }
        quietly save `cache`j'', replace
    }

    quietly use `cache1', clear
    forvalues j = 2/`k' {
        append using `cache`j''
    }

    *---------------------------------------------------------------
    * 4. Finalize
    *---------------------------------------------------------------
    capture confirm variable date
    if !_rc capture gen mofd = mofd(date)

    * Deduplicate (in case multiple file versions exist for the same round)
    capture confirm variable fmid
    if !_rc {
        bys hhid fmid mofd: keep if _n==1
    }
    else {
        bys hhid mofd: keep if _n==1
    }

    quietly save "$out/l2indo_`mod'.dta", replace
    di as result "  >> saved l2indo_`mod'.dta   (N = " _N ", vars = " c(k) ")"
end

*-------------------------------------------------------------------------------
* RUN: list every module once; discovery/harmonization is handled per module
*-------------------------------------------------------------------------------

    local modules ///
        M00_passport   M01_roster     M02_schoolmiss M02_shocks     ///
        M03_wellbeing  M04_migration  M05_activity   M06_views      ///
        M07_incomes    M08_savings    M09_greenagenda M10_experiment ///
        M11_internet   M12_ecommerce  M13_trust      M14_gasoline   ///
        M15_coping     M16_aqm        M17_lpg        M18_electricity ///
        M19_govspending M20_housing   M21_inequality

    foreach mod of local modules {
        mergemod `mod'
    }

********************************************************************************
********************************************************************************

log close
