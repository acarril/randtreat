// the 'make.do' file is automatically created by 'github' package.
// execute the code below to generate the package installation files.
// DO NOT FORGET to update the version of the package, if changed!
// for more information visit http://github.com/haghish/github

make randtreat, replace  toc pkg  version(1.5.1)                             ///
     license("MIT")                                                          ///
     author("Alvaro Carril")                                                 ///
     affiliation("Princeton University")                                     ///
     email("acarril@princeton.edu")                                          ///
     url("https://github.com/acarril/randtreat")                             ///
     title("**`randtreat`** is a Stata program that performs random treatment assignment. It can handle an arbitrary number of treatments and unequal treatment fractions, which are common in real-world randomized control trials. Stratified randomization can be achieved by optionally specifying a variable list that defines multiple strata. It also provides several methods to deal with 'misfits', a practical issue that arises in treatment assignment whenever observations can't be neatly distributed among treatments. The command performs all tasks in a way that marks misfit observations and provides several methods to deal with those misfits.")                                                         ///
     install("randtreat.ado")                                                ///
     ancillary("randtreat.sthlp")
