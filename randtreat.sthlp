{smcl}
{* *! version 1.3 November 2016}{...}
{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :{hi:randtreat} {hline 2}}Random treatment assignment and dealing with misfits{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:randtreat} {ifin}
[{cmd:,} {it:options}]
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synoptset 20 tabbed}{...}
{synopt:{opth st:rata(varlist)}} specify a list of variables to conduct a stratified assignment{p_end}
{synopt:{opth mu:ltiple(integer)}} specify number of treatment groups; default is {cmd:multiple(2)}{p_end}
{synopt:{opt u:nequal(fractions)}} specify fractions for unequal treatments; default is {cmd:unequal(1/2 1/2)}{p_end}
{synopt:{opt mi:sfits(method)}} specify a method to deal with "misfits" (see below); {it:method} may be missing (default), strata, global, wstrata or wglobal{p_end}
{synopt:{opt gen:erate(newvar)} specify a name for the randomization variable; default is {cmd:generate(treatment)}{p_end}
{synopt:{opt rerand:omize(integer)}} specify number of rerandomizations; default is {cmd:rerandomize(1)}{p_end}
{synopt:{opt bal:ance(varlist)}} specify variables to check for balance on rerandomizations. {p_end}
{synopt:{opt se:tseed(#)}} specify random-number seed to replicate assignment{p_end}
{synopt:{opt r:eplace}} replace {bf:treatment} values{p_end}
{p 4 6 2}

{title:Description}

{pstd}
The {cmd:randtreat} command performs random treatment assignment.
{cmd:randtreat}'s purpose is twofold: to easily randomize multiple, unequal treatments across strata and to provide methods to deal with "misfits" (see below).
The program presumes that the current dataset corresponds to units (e.g. individuals, firms, etc.) to be randomly allocated to treatment statuses.

{pstd}
When run, it creates a new variable whose values indicate the random treatment assignment allocation.
The seed can be set with the {opt setseed()} option, so the random assignment can be replicated.
Although the command defaults to two treatments, more {it:equally} proportioned treatments can be specified with the {opt multiple()} option.
Alternatively, multiple treatments of {it:unequal} proportions can be specified with the {opt unequal()} option.
A stratified assignment can be performed using the {opth strata(varlist)} option.
If specified, the random assignment will be carried out for each strata defined by the unique combinations of values of {varlist}.
The program can also carry out rerandomizations, selecting the randomization with the minimum maximum p-value of treatment on the variables in {opt balance(varlist)}.

{pstd}
Whenever the number of observations in a given stratum is not a multiple of the number of treatments or the least common multiple of the treatment fractions, then that stratum is going to have "misfits", that is, observations that can't be neatly distributed among the treatments.
When run, {cmd:randtreat} reports the number of misfits produced by the assignment in the current dataset.
Misfits are automatically marked with missing values in the {bf:treatment} variable, but {cmd:randtreat} provides several methods to deal with them.
The method can be specified with the {opt misfits()} option.

{pstd}
One of the firsts to discuss the misfits problem were Bruhn and McKenzie (2011),
in a {browse "http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata":World Bank Blog post}.
A generalization of the problem and details of the Stata implementation can be found in 
{browse "https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment":Carril, 2016}, or a related {browse "http://alvarocarril.com/resources/randtreat":blog post}.

{dlgtab:Options}

{phang}
{opth strata(varlist)} is used to perform a stratified allocation on the variables in {varlist}.
If specified, the random assignment will be carried out in each stratum identified by the unique combination of the {varlist} variables' values.
Notice that this option is almost identical to using {cmd:by} (see {manhelp by D}), except that the command is not independently run for the specified variables, because global existence of misfits across strata must be accounted for.

{phang}
{opth multiple(integer)} specifies the number of treatments to be assigned.
The default (and minimum) is {cmd:multiple(2)}, unless the {opt unequal()} option is specified (see below).

{phang}
{opt unequal(fractions)} is used to specify unequal treatment fractions.
Each fraction must be of the form a/b and must belong to (0,1).
Fractions must be separated by spaces and their sum must add up exactly to 1.
For example, {cmd:unequal(1/2 1/4 1/4)} will randomly assign half of the observations to the "control" group and then divide evenly the rest of the observations into two treatments.
Notice that this option implicitly defines the number of treatments (e.g. 3), so when {opt unequal()} is used, {opt mult()} is redundant and should be avoided.

{phang}
{opt generate(newvar)} specifies the name of the new variable to be created or the variable to be replaced. The default is {opt generate(treatment)}.

{phang}
{opt misfits(method)} specifies which method to use in order to deal with misfits.
More details on the internal workings of these methods are available in {browse "https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment":Carril, 2016}.
The available {it:method}s are:

{phang2}
{it: missing} is the default option and simply leaves misfit observations as missing values in {bf:treatment}, so the user can later deal with misfits as he sees fit.

{phang2}
{it: strata} randomly allocates misfits independently accross all strata, without weighting treatments as specified in {opt unequal}.
This method prioritizes balance of misfits' treatment allocation within each stratum (they can't differ by more than 1), but may harm original treatment fractions if the number of misfits is large.

{phang2}
{it: global} randomly allocates all misfits globally, without weighting treatments as specified in {opt unequal}.
This method prioritizes global balance of misfits' treatment allocation (they can't differ by more than 1), but may harm original treatment fractions if the number of misfits is large.

{phang2}
{it: wstrata} randomly allocates misfits independently accross all strata, weighting treatments as specified in {opt unequal}.
This ensures that the fractions specified in {bf:unequal()} affect the within-distribution of treatments among misfits, so overall balance of unequal treatments should be (almost) attained.
However, this method doesn't ensure the balance of misfits' treatment allocation within each stratum (they could differ by more than 1).

{phang2}
{it: wglobal} randomly allocates all misfits globally, weighting treatments as specified in {opt unequal}.
This ensures balance at the the global level and also respects unequal fractions of treatments, even when the number of misfits is large.
However, this method doesn't ensure the global balance of misfits' treatment allocation (they could differ by more than 1).
The downside is that this method could produce even greater unbalance at the finer level (in each stratum), specially if the number of misfits is relatively large.

{phang}
{opt rerandomize(integer)} specifies the number of rerandomizations that should be performed.
The rerandomization will select the randomization with the minimum maximum p-value from regressing the treatments on the balance variables specified by {opt balance(varlist)}.
When rerandomizing, the program will use the seed set in {opt setseed(#)} for the first randomization, and then will increase the seed by 1 for each subsequent loop.
When the program has completed the number of randomizations set by {opt rerandomize(integer)}, it will return the randomization with the minimum maximum p-value.

{phang}
{opt balance(varlist)} specifies the variables that should be used for rerandomization, and has no impact if not used in conjunction with rerandomize.
The rerandomization procedure keeps the randomization with the minimum maximum p-value created by regressing the i.treatment on the balance variables.

{phang}
{opt setseed(#)} specifies the initial value of the random-number seed used to assign treatments.
It can be set so that the random treatment assignment can be replicated.
See {help set seed:set seed} for more information.

{phang}
{opt replace} checks that the {bf:treatment} variable exists and, if so, it replaces it.
This is useful if one is trying different specifications for {cmd:randtreat} and wishes to avoid dropping the {bf:treatment} variable every time.

{title:Examples}

{pstd}
I suggest you {cmd:{help tabulate} {bf:treatment}} with the {cmd:missing} option after running each example.
First, load the fictional blood-pressure data:

	{cmd:sysuse bpwide, clear}

{pstd}
Basic usage:

	{cmd:randtreat}
	{cmd:randtreat, replace mult(5)}

{pstd}
Define stratification variables and unequal treatments, dealing with misfits:

	{cmd:randtreat, replace unequal(1/2 1/3 1/6)}
	{cmd:randtreat, replace unequal(1/2 1/3 1/6) strata(sex agegrp) misfits(strata)}
	{cmd:randtreat, replace unequal(1/2 1/3 1/6) strata(sex agegrp) misfits(overall)}

{pstd}	
Choose very unbalanced treatment fractions and dealing with misfits with and without weights:

	{cmd:randtreat, replace unequal(2/5 1/5 1/5 1/5) misfits(global) setseed(12345)}
	{cmd:randtreat, replace unequal(2/5 1/5 1/5 1/5) misfits(wglobal) setseed(12345)}

{title:Notes}

{pstd}
Beware of (ab)using {opt unequal()} with fractions that yield a large least common multiple (LCM), because that may produce a large number of misfits. Consider for example:
	
	{cmd: sysuse bpwide, clear}
	{cmd: randtreat, unequal(2/5 1/3 3/20 3/20)}
	{cmd: tab treatment, missing}
	
{pstd}
Since the LCM of the specified fractions is 60, the theoretical maximum number of misfits per stratum could be 59.
In this particular dataset, this configuration produces 58 misfits, which is a relatively large number given that the dataset has 120 observations.

{title:Author}

{pstd}Alvaro Carril{break}
Research Analyst at J-PAL LAC{break}
acarril@fen.uchile.cl

{title:Acknowledgements}

{pstd}
I'm indebted to several "random helpers" at the Random Help Google user group and in the Statalist Forum, who provided coding advice and snippets.
Colleagues at the J-PAL LAC office, specially Olivia Bordeu and Diego Escobar, put up with my incoherent ideas and helped me steer this into something mildly useful.

{title:References}

{phang}Bruhn, Miriam, and David McKenzie. 2011. Tools of the Trade: Doing Stratified Randomization with Uneven Numbers in Some Strata. Blog. The World Bank: Impact Evaluations.
{browse "http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata"}.

{phang}Carril, Alvaro. 2016. Dealing with misfits in random treatment assignment. Working Paper. DOI: 10.13140/RG.2.1.2859.8807
{browse "https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment"}.

