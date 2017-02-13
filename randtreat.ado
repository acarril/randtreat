*! 1.4 Kelsey Larson 13Feb2017
program define randtreat, sortpreserve
	version 11

syntax [if] [in] [ , STrata(varlist numeric) ///
	MUltiple(integer -1) ///
	Unequal(string) ///
	MIsfits(string) ///
	SEtseed(integer -1) ///
	GENerate(name) ///
	RERANDomize(integer 1) ///
	BALance(varlist) ///
	Replace ]

*-------------------------------------------------------------------------------
* Input checks
*-------------------------------------------------------------------------------

* stratvars()
local stratvars `strata'

* unequal()
// If not specified, complete it to be equal fractions according to mult()
if missing("`unequal'") {
	forvalues i = 1/`multiple' {
		local unequal `unequal' 1/`multiple'
	}
}
// If unequal() is specified, perform various checks
else {
	// If mult() is empty, replace it with the number of fractions in unequal()
	if `multiple'==-1  {
		local multiple : list sizeof unequal
	}
	// Check that unequal() has same number of fractions as the number of treatments specified in mult()
	else {
		if `: word count `unequal'' != `multiple' {
			display as error "mult() has to match the number of fractions in unequal()"
			exit 121
		}
	}
	// Check range of fractions
	tokenize `unequal'
	while "`1'" != "" {
		if (`1' <= 0 | `1'>=1) {
			display as error "unequal() must contain a list of fractions each between 0 and 1"
			exit 125
		}
		macro shift
	}
}

* generate and replace 
// replace generate with "treatment" if no name is specified
if missing("`generate'") {
	local generate treatment
}
// If specified, check if 'treatment' variable exists and drop it before the show starts
if !missing("`replace'") {
	capture confirm variable `generate'
	if !_rc drop `generate'
}
//confirm generate variable doesn't exist at this point
cap confirm variable `generate'
if !_rc {
	display as error "`generate' already defined; specify 'replace' to replace `generate' or 'generate()' to assign a different name"
	exit 110
}

// Rerandomize: check that balance vars listed if rerandomize > 1
if `rerandomize' > 1 & missing("`balance'") {
	di as error "rerandomization requires 'balance()' to be specified"
	exit 126
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
forvalues i = 1/`multiple' {
	local treatments `treatments' `i'
}

// local with number of treatments (T)
local T = `multiple'

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
loc best_minp = 0 // set up for rerandomization repeats
loc bestseed = `setseed' // set seed for first loop as best
tempfile best_rand // to contain the results of the best randomization
gen `generate' = .

forval loop = 1 / `rerandomize' {
	* display every 10th loop
	if mod(`loop', 10) == 0 di "loop `loop'"
	* Create some locals and tempvar for randomization
	set seed `setseed'
	local first : word 1 of `randpack'
	gen double `randnum' = runiform()

	* First-pass randomization
	*-------------------------------------------------------------------------------

	// Random sort on strata
	sort `touse' `stratvars' `randnum', stable
	gen long `obs' = _n

	// Assign treatments randomly and according to specified proportions in unequal()
	quietly bysort `touse' `stratvars' (`_n') : replace `generate' = `first' if `touse'
	quietly by `touse' `stratvars' : replace `generate' = ///
		real(word("`randpack'", mod(_n - 1, `J') + 1)) if _n > 1 & `touse'
		
	// Mark misfits as missing values and display that count
	quietly by `touse' `stratvars' : replace `generate' = . if _n > _N - mod(_N,`J')
	quietly count if mi(`generate') & `touse'
	if `loop' == 1 di as text "assignment produces `r(N)' misfits"

	* Dealing with misfits
	*-------------------------------------------------------------------------------
	// wglobal
	if "`misfits'" == "wglobal" {
		quietly replace `generate' = ///
			real(word("`randpackshuffle'", mod(_n - 1, `J') + 1)) if mi(`generate') & `touse'
	}
	// wstrata
	if "`misfits'" == "wstrata" {
		quietly bys `touse' `stratvars' : replace `generate' = ///
			real(word("`randpackshuffle'", mod(_n - 1, `J') + 1)) if mi(`generate') & `touse'
	}
	// global
	if "`misfits'" == "global" {
		quietly replace `generate' = ///
			real(word("`treatmentsshuffle'", mod(_n - 1, `T') + 1)) if mi(`generate') & `touse'
	}
	// strata
	if "`misfits'" == "strata" {
		quietly bys `touse' `stratvars' : replace `generate' = ///
			real(word("`treatmentsshuffle'", mod(_n - 1, `T') + 1)) if mi(`generate') & `touse'
	}
	* Calculate p-values
	*----------------------------------------------------------------------------
	mata: p = 1
	qui if !missing("`balance'") {
		local test
		mata: p = 1 // creates vector for p-values
		* create test for all treatments
		forval x = 1 / `multiple' { 
			local test "`test' `x'.`generate'"
			if `x' != `multiple' local test = "`test' =="
		}
		* perform tests
		foreach var of varlist `balance' {
			regress `var' i.`generate'
			test `test'
			mata: p = (p, `r(p)')
			forval i = 1 / `multiple' {
				test `i'.`generate' == 0
				mata: p = (p, `r(p)')
			}
		}
		* calculate minimum p-value and, if greater than previous min, make new best seed
		mata: findmin(p)
		di "`min(p)'"
		if `r(min)' > `best_minp' {
			noi di "new minp: `r(min)' "
			noi di "new best seed: `setseed'"
			loc best_minp = `r(min)'
			loc bestseed `setseed'
			save `best_rand', replace
		}
	}
	drop `randnum' `obs'
	local setseed = `setseed' + 1 // set up for next loop
			
}
*-------------------------------------------------------------------------------
* Closing the curtains
*-------------------------------------------------------------------------------
if !missing("balance") {
	di "Randomization complete!"
	di "Best seed is `bestseed'"
	di "minimum p-val is `best_minp'"
	
	use `best_rand', clear
}

quietly replace `generate' = `generate' - 1
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

*calculate minimum of vector in mata and return in r(min)
capture mata: mata drop findmin()
mata:
void findmin(real vector c)
{
	real scalar min
	min = min(c)
	st_numscalar("r(min)", min)
}

end


********************************************************************************

/* 
CHANGE LOG
1.4
	- Implemented rerandomization procedure and option
	- Implemented generate() option
1.3
	- sortpreserve as default program option
	- Improve unequal() fractions sum check to be more precise and account for
	sums greater than 1
	- Improvements in setseed option: accept only integers and only set seed if
	option is specified
	- Implement stratification varlist as strata() option with `stratvars' local
	- Rename mult() option to multiple() for consistency and improve efficiency
	of checks related to the option
	- Allow "if" and "in" in syntax
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

*/

