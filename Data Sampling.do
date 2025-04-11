clear all

if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818\week_10\03_assignment\"
}

if c(username)=="suyux" {
	
	global wd "/Users/suyux/Desktop/Education/GU/2025Spring/Experimental Design/ppol6618/week_10/03_assignment/"
}

cd "$wd"

********************************************************************************
* Dataset Genration
********************************************************************************

clear all 
set more off
set seed 2025

clear
set obs 1000

/*polarization is an index scaled from 0:left - 10:right summarized by average 
score of how respondants rate their positions on a set of key policy issues 
(e.g., immigration, gun control, healthcare) and also provide a feeling 
thermometer score (0–100) indicating how strongly they feel about each position.
These respondants will be seperated into 5 groups in our sample: far left (0-2), 
central left (2-4), central (4-6), central right (6-8), far right (8-10). */

gen polarization = runiform(0,10) // limitation here is political attitudes may not be normally distributed

*define groups
gen group = .
replace group = 1 if polarization < 2          // Far left
replace group = 2 if polarization >= 2 & polarization < 4   // Central left
replace group = 3 if polarization >= 4 & polarization < 6   // Central
replace group = 4 if polarization >= 6 & polarization < 8   // Central right
replace group = 5 if polarization >= 8                      // Far right

label define ideogroup 1 "Far Left" 2 "Center Left" 3 "Center" 4 "Center Right" 5 "Far Right"
label values group ideogroup

gen is_extremist = inlist(group,1,5)
gen id = _n

*create pairing ID for each extremist
preserve
keep if is_extremist
gen pairing_type = .
gen random = runiform()
sort random

*create 5 pairing groups (evenly split extremists across pairing types)
gen pairing_group = .
replace pairing_group = 1 if _n <= _N/5
replace pairing_group = 2 if _n > _N/5 & _n <= 2*_N/5
replace pairing_group = 3 if _n > 2*_N/5 & _n <= 3*_N/5
replace pairing_group = 4 if _n > 3*_N/5 & _n <= 4*_N/5
replace pairing_group = 5 if _n > 4*_N/5

label define pairgroup 1 "Control" 2 "Similar" 3 "Mixed-Center" 4 "Opposing" 5 "Polar Opposing"
label values pairing_group pairgroup

tempfile extremists
save `extremists', replace
restore

*merge pairing group info
merge 1:1 id using `extremists', keepusing(pairing_group) nogenerate

*create partner group variable based on pairing_group
gen partner_group = .

*assign target partner groups based on pairing type
replace partner_group = group if pairing_group == 1  // Control: same as self

replace partner_group = 2 if group == 1 & pairing_group == 2  // Similar: Far Left → Center Left
replace partner_group = 4 if group == 5 & pairing_group == 2  // Far Right → Center Right

replace partner_group = 3 if pairing_group == 3               // Mixed-Center: all → Center

replace partner_group = 4 if group == 1 & pairing_group == 4  // Opposing: Far Left → Center Right
replace partner_group = 2 if group == 5 & pairing_group == 4  // Far Right → Center Left

replace partner_group = 5 if group == 1 & pairing_group == 5  // Polar Opposing: Far Left → Far Right
replace partner_group = 1 if group == 5 & pairing_group == 5  // Polar Opposing: Far Right → Far Left

//CODE ADDED BY RONIN BELOW
//Check 1
//Changing data on purpose. Now some people will be assigned group 1 even if they're survey data reports otherwise.
gen random = runiform()
replace group = 1 if random < .05

//Presenting the results in a csv.
sum if group == 1 & polarization < 2 
sum if group == 1 & polarization > 2
preserve
keep if group == 1 & polarization > 2
keep id group polarization
gsort id
export delimited  "Check1.csv"
restore

// Check 2
// It is the process to see if all participants have been successfully assigned to a group

* Check for missing group assignments
count if missing(group)
list id polarization if missing(group)

* Verify all ids have valid group values (should be 1-5)
tab group, missing
count if group < 1 | group > 5 | missing(group)
list id polarization if group < 1 | group > 5 | missing(group)

* Check extremist flag consistency with group assignments
count if is_extremist == 1 & !(group == 1 | group == 5)
list id group is_extremist if is_extremist == 1 & !(group == 1 | group == 5)

count if (group == 1 | group == 5) & is_extremist == 0
list id group is_extremist if (group == 1 | group == 5) & is_extremist == 0

* Simple summary report of group assignments
tab group, missing

//Check 3
//Changing data on purpose. Now some random surveys will have a group assigned even though they shouldn't.
replace pairing_group = floor(runiform(0,5)) if is_extremist == 0 & random < .05

//Presenting the results in a csv.
sum pairing_group if is_extremist == 0 & pairing_group !=.
preserve
keep if is_extremist == 0 & pairing_group !=.
keep id is_extremist pairing_group
gsort id
export delimited  "Check3.csv"
restore

//END OF CODE BY RONIN
