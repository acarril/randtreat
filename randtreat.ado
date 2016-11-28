*! 1.3 Alvaro Carril nov2016
program define randtreat, sortpreserve
	version 11

syntax [ ,	STrata(varlist numeric) ///
			MUlt(integer 2) ///
			Unequal(string) ///
			MIsfits(string) ///
			SEtseed(integer -1) ///
			Replace ]

*-------------------------------------------------------------------------------
* Input checks
*-------------------------------------------------------------------------------

* stratvars()
local stratvars `strata'

* unequal()
// If not specified, complete it to be equal fractions according to mult()
if missing("`unequal'") {
	forvalues i = 1/`mult' {
		local unequal `unequal' 1/`mult'
	}
}
// If unequal() is specified, perform various checks
else {
	// If mult() is empty, replace it with the number of fractions in unequal()
	if `mult'==0  {
		local mult : list sizeof unequal
	}
	// Check that unequal() has same number of fractions as the number of treatments specified in mult()
	local unequal_num : word count `unequal'
	if `unequal_num' != `mult' {
		display as error "mult() has to match the number of fractions in unequal()"
		exit 121
	}
	// Check range of fractions
	tokenize `unequal'
	while "`1'" != "" {
		if (`1' <= 0 | `1'>=1) {
			display as error "unequal() must contain fractions each between 0 and 1 (e.g. 1/2 1/3 1/6)"
			exit 125
		}
		macro shift
	}
}

* replace
// If specified, check if 'treatment' variable exists and drop it before the show starts
if !missing("`replace'") {
	capture confirm variable treatment
	if !_rc drop treatment
}

* misfits()
// If specified, check that a valid option was passed
if !missing("`misfits'") {
	_assert inlist("`misfits'", "missing", "strata", "wstrata", "global", "wglobal"), rc(7) ///
	msg("misfits() argument must be either {it:missing}, {it:strata}, {it:wstrata}, {it:global} or {it:wglobal}")
}

*-------------------------------------------------------------------------------
* Pre-randomization stuff
*-------------------------------------------------------------------------------

// Initial setup
tempvar randnum rank_treat misfit cellid obs
marksample touse, novarlist
quietly count if `touse'
if r(N) == 0 error 2000

// Set seed
if `setseed' != -1 set seed `setseed'

// local with all treatments (B vector)
forvalues i = 1/`mult' {
	local treatments `treatments' `i'
}

// local with number of treatments (T)
local T = `mult'

* Construct randpack
*-------------------------------------------------------------------------------

// local `unequal2' with spaces instead of slashes
local unequal2 = subinstr("`unequal'", "/", " ", .)

// simplify fractions
foreach f of numlist 1/`T' {
	local a : word `=2*`f'-1' of `unequal2'
	local b : word `=2*`f'' of `unequal2'
	gcd `a' `b'
	local a = `a'/`r(gcd)'
	local b = `b'/`r(gcd)'
	local unequal_reduc `unequal_reduc' `a' `b'
}

// tokenize unequal() fractions with 'u' stub
tokenize `unequal'
local i = 1
while "``i''" != "" { 
	local u`i' `"``i''"'
	local i = `i' + 1
}

// tokenize denominators of unequal() with 'den' stub
tokenize `unequal_reduc'
local n = 1
forvalues i = 2(2)`=`T'*2' {
	local den`n' `"``i''"'
	local n = `n' + 1
}
local n = `n' - 1

// local 'denoms' with all denominators
forvalues i = 1/`T' {
	local denoms `denoms' `den`i''
}

// compute least common multiple of all denominators (J)
lcmm `denoms'
local lcm = `r(lcm)'

// auxiliary macro randpack1 with the number of times each treatment should be repeated in the randpack
forvalues i = 1/`T' {
	local randpack1 `randpack1' `lcm'*`u`i''
}

// tokenize randpack1 with 'aux' stub --> three loops may be inefficient
tokenize `randpack1'
forvalues i = 1/`T' {
	local aux`i' = ``i''
}
forvalues i = 1/`T' {
	local randpack2 `randpack2' `aux`i''
}

// generate randpack
forvalues k = 1/`T' {
	forvalues i = 1/`aux`k'' {
		local randpack `randpack' `k'
	}
}
local J `lcm' // size of randpack

* random shuffle of randpack and treatments
mata : st_local("randpackshuffle", invtokens(jumble(tokens(st_local("randpack"))')'))
mata : st_local("treatmentsshuffle", invtokens(jumble(tokens(st_local("treatments"))')'))

* Check sum of fractions
*-------------------------------------------------------------------------------
tokenize `unequal'
while "`1'" != "" {
	local unequal_sum = `unequal_sum'+`1'*`lcm'
	macro shift
}
local unequal_sum = `unequal_sum'/`lcm'
if `unequal_sum' != 1 {
	display as error "fractions in unequal() must add up to 1"
	exit 121
}

*-------------------------------------------------------------------------------
* The actual randomization stuff
*-------------------------------------------------------------------------------

* Create some locals and tempvar for randomization
local first : word 1 of `randpack'
gen double `randnum' = runiform()

* First-pass randomization
// Random sort on strata
sort `touse' `stratvars' `randnum', stable
gen long `obs' = _n
// Assign treatments randomly and according to specified proportions in unequal()
sort `touse' `stratvars' `randnum', stable
quietly bysort `touse' `stratvars' (`_n') : gen treatment = `first' if `touse'
quietly by `touse' `stratvars' : replace treatment = ///
	real(word("`randpack'", mod(_n - 1, `J') + 1)) if _n > 1 & `touse'
	
// Mark misfits as missing values and display that count
quietly by `touse' `stratvars' : replace treatment = . if _n > _N - mod(_N,`J')
quietly count if mi(treatment)
di as text "assignment produces `r(N)' misfits"

* Dealing with misfits
*-------------------------------------------------------------------------------
// wglobal
if "`misfits'" == "wglobal" {
	quietly replace treatment = ///
		real(word("`randpackshuffle'", mod(_n - 1, `J') + 1)) if treatment == .
}
// wstrata
if "`misfits'" == "wstrata" {
	quietly bys `touse' `stratvars' : replace treatment = ///
		real(word("`randpackshuffle'", mod(_n - 1, `J') + 1)) if treatment == .
}
// global
if "`misfits'" == "global" {
	quietly replace treatment = ///
		real(word("`treatmentsshuffle'", mod(_n - 1, `T') + 1)) if treatment == .
}
// strata
if "`misfits'" == "strata" {
	quietly bys `touse' `stratvars' : replace treatment = ///
		real(word("`treatmentsshuffle'", mod(_n - 1, `T') + 1)) if treatment == .
}

*-------------------------------------------------------------------------------
* Closing the curtains
*-------------------------------------------------------------------------------

quietly replace treatment = treatment-1
end

*-------------------------------------------------------------------------------
* Define auxiliary programs
*-------------------------------------------------------------------------------

* Greatest Common Denominator (GCD) of 2 integers
program define gcd, rclass
    if "`2'" == "" {
        return scalar gcd = `1'
    }
    else {
        while `2' {
            local temp2 = `2'
            local 2 = mod(`1',`2')
            local 1 = `temp2'
        }
        return scalar gcd = `1'
    }
end

* Least Common Multiple (LCM) of 2 integers
program define lcm, rclass
    if "`2'" == "" {
        return scalar lcm = `1'
    }
    else {
        gcd `1' `2'
        return scalar lcm = `1' * `2' / r(gcd)
    }
end

* LCM of arbitrarily long list of integers
program define lcmm, rclass
    clear results
    foreach i of local 0 {
        lcm `i' `r(lcm)'
    }
    return scalar lcm = r(lcm)
end

********************************************************************************

/* 
CHANGE LOG
1.3
	- sortpreserve as default program option
	- improve unequal() fractions sum check to be more precise and account for
	sums greater than 1
	- improvements in setseed option: accept only integers and only set seed if
	option is specified
1.2
	- Added separate sub-programs for GCD and LCM (thanks to Nils Enevoldsen)
	- Simplified fractions in unequal()
1.1.1
	- Changed all instances of uneven to unequal, to match paper
	- Minor improvemnts in input checks
	- Lots of edits to comments
1.1.0
	- Reimplemented misfits() w-methods
	- Reimplemented randpack shuffling in Mata
	- Implemented unweighted misfits() methods
	- Implemented sortpreserve option
	- Implemented setseed() option
	- Error messages more akin to official errors
	- Deleted check for varlist with misfits, made no sense (?)
1.0.5
	- Much improved help file
1.0.4
	- No longer need sortlistby module
1.0.3
	- Added misfits() options: overall, strata, missing
	- Depends on sortlistby module
1.0.2
	- Stop the use of egenmore() repeat for the sequence filling (thanks to Nick
	Cox).
	- Code for treatment assignment is now case-independent of wether a varlist 
	is specified or not
	- Fixed an bug in which the assignment without varlist would not be
	reproducible, even after setting the seed
1.0.1
	- Minor code improvements
1.0.0
	- First working version

TODOS (AND IDEAS TO MAKE RANDTREAT EVEN COOLER)
- Use gen(varname) instead of hard-wired 'treatment'. Would loose 'replace' though (?)
- Add support for [if] and [in].
- Support for [by](?) May be redundant/confusing.
- Store in e() and r(): seed? seed stage?
*/

