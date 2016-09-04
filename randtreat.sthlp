{smcl}
{* *! version 1.2 August 2016}{...}
{cmd:help randtreat}{...}
{hline}

{title:Title}

{pstd}
{hi:randtreat} {hline 2} Random treatment assignment with unequal treatment fractions and dealing with misfits.

{title:Syntax}

{p 8 16 2}
{cmd:randtreat} [{varlist}]
[, {opt r:eplace} {opt so:rtpreserve} {opt se:tseed(#)} {opt mu:lt(integer)} {opt u:nequal(fractions)} {opt mi:sfits(method)}]
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synoptset 20 tabbed}{...}
{synopt:{opt r:eplace}} replace {bf:treatment} values{p_end}
{synopt:{opt so:rtpreserve}} preserve sort order{p_end}
{synopt:{opt se:tseed(#)}} specify random-number seed or state{p_end}
{synopt:{opt mu:lt(integer)}} specify number of treatments, including control (default is 2){p_end}
{synopt:{opt u:nequal(fractions)}} specify fractions for unequal treatments{p_end}
{synopt:{opt mi:sfits(method)}} specify which method to use to deal with misfits (see below){p_end}

{p 4 6 2}

{title:Description}

{pstd}
The {cmd:randtreat} command performs random treatment assignment.
It can handle an arbitrary number of treatments and unequal treatment fractions, which are common in real-world randomized control trials.
Stratified randomization can be achieved by optionally specifying a variable list that defines multiple strata.
It also provides several methods to deal with 'misfits', a practical issue that arises in treatment assignment whenever observations can't be neatly distributed among treatments.
The command performs all tasks in a way that marks misfit observations and provides several methods to deal with those misfits.

{pstd}
When run, it creates a new variable named {bf:treatment} that encodes the treatment allocation.
The default number of treatments is two (a control group and a treatment group), but more can be specified with the {opt mu:lt(integer)} option.
Also, unequal fractions of treatments may be specified using the {opt u:nequal(fractions)} option.
Random assignment with all these options can be done within each strata defined by the unique combinations of values of {varlist}.
The data will be sorted by {varlist} and {bf:treatment}, unless the {opt so:rtpreserve} option is issued.
The seed can be set with the {opt se:tseed(#)} option, so the random assignment can be replicated.

{pstd}
When the number of observations in a given stratum is not a multiple of the number of even treatments, each stratum will have 'misfits' (i.e. units that can't be neatly distributed among the treatments).
If unequal treatments are specified, then the problem arises whenever the number of observations in a given stratum is not a multiple of the least common multiple (LCM) of the fractions' denominators.
When the command is run, it will display the number of misfits that the current setup yields.
By specifying {opt mi:sfits(method)}, one can choose how to deal with those misfits.

{pstd}
One of the first to discuss the 'misfits' issue were Bruhn and McKenzie (2011),
in a {browse "http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata":World Bank Blog post}.
A generalization of the problem and details of the Stata implementation can be found in 
{browse "https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment":Carril, 2016}.

{dlgtab:Options}

{phang}
{opt r:eplace} checks that the {bf:treatment} variable exists and, if so, it replaces it.
This is useful if one is trying different specifications for {cmd:randtreat} and wishes to avoid {help drop:dropping} the {bf:treatment} variable every time.

{phang}
{opt so:rtpreserve} preserves the sorting order of the database. If not issued, the command will sort the data by {varlist} and {bf:treatment}.

{phang}
{opt se:tseed(#)} specifies the initial value of the random-number seed used to assign treatments.
It can be set so that the random treatment assignment can be replicated.
See {help set seed:set seed} for more information.

{phang}
{opt mu:lt(integer)} specifies the number of treatments (including a control group) that will be randomized.
If not specified, it defaults to two (0 and 1), unless the {opt u:nequal()} option is specified (see below).

{phang}
{opt u:nequal(fractions)} serves two purposes.
 Explicitly, it defines unequal fractions for treatments.
 For example, specifying {opt u:nequal(1/2 1/4 1/4)} will randomly assign half of the observations to the control group and then divide evenly the rest of the observations amongst two treatments.
 Also, it implicitly defines the number of treatments. For example, in the aforementioned specification we implicitly defined 3 treatments (0, 1, 2).
 So when the {opt u:nequal()} option is used, {opt mu:lt()} is redundant and should be avoided.
 Only fractions can be specified, so {opt u:nequal(.5 .25 .25)}, though equivalent to our example, is not allowed. Each fraction must be belong in (0,1) and their sum must add up exactly to 1.

{phang}
{opt mi:sfits(method)} specifies which method to use in order to deal with misfits.
More details on the internal workings of these methods are available in {browse "https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment":my working paper}.
The available {it:methods} are:

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

{title:Examples}
I suggest you {cmd:{help tabulate} {bf:treatment}} with the {cmd:missing} option after running each example.

	{cmd:sysuse bpwide, clear}

Basic usage:
	{cmd:randtreat}
	{cmd:randtreat, sortpreserve}
	{cmd:randtreat, replace mult(5)}

Define stratification variables and unequal treatments, dealing with misfits:
	{cmd:randtreat sex agegrp, r u(1/2 1/3 1/6)}
	{cmd:randtreat sex agegrp, r u(1/2 1/3 1/6) misfits(strata)}
	{cmd:randtreat sex agegrp, r u(1/2 1/3 1/6) mi(overall)}
	
Choose very unbalanced treatment fractions and dealing with misfits with and without weights:
	{cmd:randtreat, r unequal(2/5 1/5 1/5 1/5) mi(global) se(12345)}
	{cmd:randtreat, r unequal(2/5 1/5 1/5 1/5) mi(wglobal) se(12345)}


{title:Notes}
{pstd}
Beware of (ab)using the {opt u:nequal()} with fractions that yield a large least common multiple (LCM), because that may produce a large number of misfits. Consider for example:
	
	{cmd: sysuse bpwide, clear}
	{cmd: randtreat, unequal(2/5 1/3 3/20 3/20)}
	{cmd: tab treatment, missing}
	
{pstd}
Since the LCM of the specified fractions is 60, the theoretical maximum number of misfits per stratum could be 59.
In this particular dataset, this configuration produces 58 misfits, which is a relatively large number (dataset has 120 observations).

{title:Author}
{pstd}Alvaro Carril{break}
Research Analyst at J-PAL LAC{break}
acarril@fen.uchile.cl

{title:Acknowledgements}
{pstd}
I'm indebted to several "random helpers" at the Random Help Google user group and in the Statalist Forum, who provided coding advice and snippets.
Colleagues at the J-PAL LAC office, specially Olivia Bordeu and Diego Escobar, put up with my incoherent ideas and helped me steer this into something mildly useful.

{title:References}
{phang}Bruhn, Miriam, and David McKenzie. 2011. Tools of the Trade: Doing Stratified Randomization with Uneven Numbers in Some Strata.ù Blog. The World Bank: Impact Evaluations.
{browse "http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-unequal-numbers-in-some-strata"}.

{phang}Carril, Alvaro. 2016. Dealing with misfits in random treatment assignment.ù Working Paper. DOI: 10.13140/RG.2.1.2859.8807
{browse "https://www.researchgate.net/publication/292091060_Dealing_with_misfits_in_random_treatment_assignment"}.

.
