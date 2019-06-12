# `randtreat`
Stata program for random treatment assignment with unequal treatment fractions and dealing with misfits.

## Description

**`randtreat`** is a Stata program that performs random treatment assignment. It can handle an arbitrary number of treatments and unequal treatment fractions, which are common in real-world randomized control trials. Stratified randomization can be achieved by optionally specifying a variable list that defines multiple strata. It also provides several methods to deal with *misfits*, a practical issue that arises in treatment assignment whenever observations can't be neatly distributed among treatments (see [References](#References)). The command performs all tasks in a way that marks misfit observations and provides several methods to deal with those misfits.

**Please refer to the help file for further details.**


## Installation

### Github repository

You can install the most updated version of this program directly from Github.
This can be done without any additional packages by executing
```stata
net install randtreat, from("https://raw.github.com/acarril/randtreat/master/") replace
```
However, it might be more convenient to install and maintain it using Haghish's excellent [Github package](https://github.com/haghish/github):
```stata
net install github, from("https://haghish.github.io/github/")
github install acarril/randtreat
```

### SSC repository

An outdated version of this program can also be found in the SSC repository:

```stata
ssc install randtreat
```


## References

One of the first to discuss the *misfits* issue were Bruhn and McKenzie (2011),
in a [World Bank Blog post](http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata).
A generalization of the problem and details of the Stata implementation can be found in
[Carril, 2017](https://www.stata-journal.com/article.html?article=st0490).
