# Stata program: `randtreat`
Random treatment assignment with unequal treatment fractions and dealing with misfits.

## Installation
Download all files from this repository and add them to your personal ado path. The command is also available on the SSC repository.

## Description
**`randtreat`** is a Stata program that performs random treatment assignment. It can handle an arbitrary number of treatments and unequal treatment fractions, which are common in real-world randomized control trials. Stratified randomization can be achieved by optionally specifying a variable list that defines multiple strata. It also provides several methods to deal with *misfits*, a practical issue that arises in treatment assignment whenever observations can't be neatly distributed among treatments. The command performs all tasks in a way that marks misfit observations and provides several methods to deal with those misfits.

When run, it creates a new variable named `treatment` that encodes the treatment allocation. The default number of treatments is two (a control group and a treatment group), but more can be specified with the `mult(integer)` option. Also, unequal fractions of treatments may be specified using the  `unequal(fractions)` option. Random assignment with all these options can be done within each strata defined by the unique combinations of values of `varlist`. The data will be sorted by `varlist` and `treatment`, unless the `sortpreserve` option is issued. The seed can be set with the `setseed(#)` option, so the random assignment can be replicated.

When the number of observations in a given stratum is not a multiple of the number of even treatments, each stratum will have *misfits* (i.e. units that can't be neatly distributed among the treatments). If unequal treatments are specified, then the problem arises whenever the number of observations in a given stratum is not a multiple of the least common multiple (LCM) of the fractions' denominators. When the command is run, it will display the number of misfits that the current setup yields. By specifying `misfits(method)`, one can choose how to deal with those misfits.

**Please refer to the help file for further detail.**

## References
One of the first to discuss the 'misfits' issue were Bruhn and McKenzie (2011),
in a [World Bank Blog post](http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata). A generalization of the problem and details of the Stata implementation can be found in 
[Carril, 2016](https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment).
