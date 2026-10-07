// 1. Check duplicates are gone
use "$in/l2indo_M01_roster.dta", clear
duplicates tag hhid fmid mofd, g(dup)
tab dup
// Should be nearly all 0

// 2. Check hhsize is normal across all rounds
g hhsize_temp = residing==1
bys hhid mofd: egen hhsize = total(hhsize_temp)
bys hhid mofd: keep if _n==1
table round, stat(mean hhsize) stat(max hhsize)
// All rounds should be ~3.5-4.0, no round above 5

// 3. Count observations per round — should be stable
tab round