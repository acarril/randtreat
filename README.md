# `randtreat`
Stata program for random treatment assignment with unequal treatment fractions and dealing with misfits.

## Description

**`randtreat`** is a Stata program that performs random treatment assignment. It can handle an arbitrary number of treatments and unequal treatment fractions, which are common in real-world randomized control trials. Stratified randomization can be achieved by optionally specifying a variable list that defines multiple strata. It also provides several methods to deal with *misfits*, a practical issue that arises in treatment assignment whenever observations can't be neatly distributed among treatments (see [References](#References)). The command performs all tasks in a way that marks misfit observations and provides several methods to deal with those misfits.

**Please refer to the help file for further details.**


## Installation

The preferred installation method is via SSC:
```stata
ssc install randtreat
```
Alternatively, you may install it manually by cloning the contents of this repository and adding them to your `ado` path.


## References

One of the first to discuss the *misfits* issue were Bruhn and McKenzie (2011),
in a [World Bank Blog post](http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata).
A generalization of the problem and details of the Stata implementation can be found in
[Carril, 2017](https://www.stata-journal.com/article.html?article=st0490).
