*! 1.0.5 Alvaro Carril 31oct2015
program define randtreat
	version 11

syntax [varlist(default=none)] /// 
[, Sortvar(varname) MUlt(integer 0) MIsfits(string) Uneven(string) Replace]

********************
*** Input checks ***
********************

*** uneven() ***
* If not specified, complete uneven() to be... even.
if missing("`uneven'") {
	if `mult'==0  {
		local mult = 2
	}
	forvalues i = 1/`mult' {
		local uneven `uneven' 1/`mult'
	}
}
* If uneven() is specified.
else {
	* If the user didn't enter mult(), then replace it with the number of fractions in uneven().
	if `mult'==0  {
		local mult : list sizeof uneven
	}
	* Check that uneven() has same number of fractions as the number of treatments specified in mult().
	local uneven_num : word count `uneven'
	if `uneven_num' != `mult' {
		display as error "Error: mult() has to be an integer equal to the number of fractions in uneven() (first treatment is control). Otherwise don't use mult()."
		exit 121
	}
	* Check that values add up to 1.
	tokenize `uneven'
	while "`1'" ~= "" {
		local uneven_sum = `uneven_sum'+`1'
		macro shift
	}
	if `uneven_sum' < .9999 {
		display as error "Error: fractions in uneven() must add up to 1."
		exit 121
	}
	* Check range of values.
	tokenize `uneven'
	while "`1'" ~= "" {
		if (`1' <= 0 | `1'>=1) {
			display as error "Error: values of uneven() must be fractions between 0 and 1 (e.g. 1/2 1/3 1/6)."
			exit 125
		}
		macro shift
	}
}
*** sortvar() ***
* Sorting on sortvar() if specified, issue a warning if not.
capture sort `sortvar'
if _rc != 0 {
	display as text "Warning: initial sortvar() wasn't specified."
}
*** replace ***
* If replace option is specified, check if 'treatment' variable exists and then drop it before the show starts.
if !missing("`replace'") {
	capture confirm variable treatment
	if !_rc {
		drop treatment
		display as text "Warning: {bf:treatment} values were replaced."
	}
}
*** misfit() ***
if !missing("`misfits'") {
	* Check that misfits() isn't specified without stratification variables.
	if missing("`varlist'") {
	display as error "Error: the misfits() option cannot be specified if no stratification variables are specified."
	exit 184
	}
	else {
	* If stratification variables are specified, check that a valid option was passed.
	_assert inlist("`misfits'", "strata", "overall", "ranked", "missing"), rc(7) ///
	msg("Error: misfits() argument must be either {it:strata}, {it:overall}, {it:ranked} or {it:missing}.")
	}
}
***********************************
*** The pre-randomization stuff ***
***********************************

* Some tempvars and the interestingvar.
tempvar randnum rank_treat misfit cellid obs

* Marksample
marksample touse, novarlist
quietly count if `touse'
if r(N) == 0 error 2000

*** Determining minimum "randomization pack" for all treatments.
* Tokenize uneven() with stub 'u'.
tokenize `uneven'
local i = 1 	
while "``i''" != "" { 
	local u`i' `"``i''"'
	local i = `i' + 1 
}
* Tokenize denominators of uneven() with 'den' stub.
local uneven2 = subinstr("`uneven'", "/", " ", .)
tokenize `uneven2'
local size : list sizeof uneven2
local n = 1
forvalues i = 2(2)`size' {
	local den`n' `"``i''"'
	local n = `n' + 1
}
* Create local 'denoms' with all denominators.
forvalues i = 1/`size' {
	local denoms `denoms' `den`i''
}
* LCM of denominators.
forvalues x = 2/1000 {
	local check 0
	local size : list sizeof denoms
	foreach number of local denoms {
		if mod(`x', `number') == 0 {
			local check = `check' + 1
		}
	}
	if `check' == `size' {
		local lcm = `x'
		continue, break
	}
}
* Auxiliary macro randpack1 with the number of times each treatment should be repeated in the randpack.
local size : list sizeof uneven
forvalues i = 1/`size' {
	local randpack1 `randpack1' `lcm'*`u`i''
}
* Tokenize randpack1 with 'aux' stub (the three loops may be inefficient).
tokenize `randpack1'
forvalues i = 1/`size' {
	local aux`i' = ``i''
}
forvalues i = 1/`size' {
	local randpack2 `randpack2' `aux`i''
}
forvalues k = 1/`size' {
	forvalues i = 1/`aux`k'' {
		local randpack `randpack' `k'
	}
}
* Create some locals and tempvar for randomization.
local nvals : word count `randpack'
local first : word 1 of `randpack'
local randpack_size : list sizeof randpack
gen double `randnum' = runiform()

**************************************
*** The actual randomization stuff ***
**************************************

*** First-pass randomization***

* Random sory on strata.
sort `touse' `varlist' `randnum', stable
gen long `obs' = _n

* Assign treatments randomly and according to specified proportions in uneven().
sort `touse' `varlist' `randnum', stable
quietly bysort `touse' `varlist' (`obs') : gen treatment = `first' if `touse'
quietly by `touse' `varlist' : replace treatment = ///
	real(word("`randpack'", mod(_n - 1, `randpack_size') + 1)) if _n > 1 & `touse' 
quietly by `touse' `varlist' : replace treatment = . if _n > _N - mod(_N,`randpack_size')

*** Dealing with misfits ***

* Generate random randpack, `randrandpack'
local N=_N
if `N'<`n' qui set obs `n' 
tempvar rank By
qui gen `rank'=_n in 1/`n'
qui gen double `By'=uniform() in 1/`n'
sort `By' in 1/`n'
forv i=1/`n' {
	local list `"`list'`: word `=`rank'[`i']' of `randpack'' "'
}
sort `rank' in 1/`n'
if `N'<`n' qui drop in `=`N'+1'/`n' 
local list: list retok list
di `"`list'"'
local randrandpack = "`list'"

* Method = overall
if "`misfits'" == "overall" {
	quietly replace treatment = ///
		real(word("`randrandpack'", mod(_n - 1, `randpack_size') + 1)) if treatment == .
}
* Method = strata
if "`misfits'" == "strata" {
	quietly bys `touse' `varlist' : replace treatment = ///
		real(word("`randrandpack'", mod(_n - 1, `randpack_size') + 1)) if treatment == .
}

*** End stuff ***
* Decrease treatment numbers, just so control is 0.
quietly replace treatment = treatment-1
* Nicer sorting (debatable).
sort `varlist' treatment, stable
end

********************************************************************************

/* 

CHANGE LOG
1.0.5
	- Much improved help file.
1.0.4
	- No longer need sortlistby module.
1.0.3
	- Added misfits() options: overall, strata, missing.
	- Depends on sortlistby module.
1.0.2
	- Stop the use of egenmore() repeat for the sequence filling (thanks to Nick
	Cox).
	- Code for treatment assignment is now case-independent of wether a varlist 
	is specified or not.
	- Fixed an bug in which the assignment without varlist would not be
	reproducible, even after setting the seed.
1.0.1
	- Minor code improvements. 
1.0.0
	- First working version.

TODOS (AND IDEAS TO MAKE RANDTREAT EVEN COOLER)
- Use gen(varname) instead of hard-wired 'treatment'. Would loose 'replace' though (?)
- Add support for [if] and [in].
- Support for [by](?) May be redundant/confusing.
- Store in e() and r(): seed? seed stage?

net from https://raw.github.com/acarril/personal/master/
*/

