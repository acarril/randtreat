{smcl}
{* *! version 1.0.5 October 2015}{...}
{cmd:help randtreat}{...}
{hline}

{title:Title}

{pstd}
{hi:randtreat} {hline 2} Randomly assign treatments.

{title:Syntax}

{p 8 16 2}
{cmd:randtreat} [{varlist}]
[,{opt mu:lt(integer)} {opt u:neven(fractions)} {opt mi:sfits(method)} {opt r:eplace}]
{p_end}

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{synoptset 20 tabbed}{...}

{synopt:{opt mu:lt(integer)}} specify number of treatments, including control (default is 2).{p_end}

{synopt:{opt u:neven(fractions)}} specify fractions for uneven treatments.{p_end}

{synopt:{opt mi:sfits(method)}} specify which method to use to deal with misfits.{p_end}

{synopt:{opt r:eplace}} replace {bf:treatment} variable.{p_end}
{p 4 6 2}


{title:Description}

{pstd}
{cmd:randtreat}'s purpose is twofold: to easily randomize multiple, uneven treatments across strata and to provide methods to deal with 'misfits' (see below).

{pstd}
When run, it creates a new variable named {bf:treatment} that contains randomly assigned treatments.
The default number of treatments is two (a control group and a treatment group), but more can be specified with the {hi:mult(integer)} option.
Also, uneven fractions of treatments may be specified using the {hi:uneven(fractions)} option.
Random assignment with all these options can be done within each strata defined by {varlist}.

{pstd}
When the number of observations in a given stratum is not a multiple of the number of even treatments, each stratum will have 'misfits' (i.e. units that can't be neatly distributed among the treatments). 
The
If uneven treatments are specified, then the problem arises whenever the number of observations in a given stratum is not a multiple of the least common multiple (LCM) of the fractions' denominators.
By specifying {opt mi:sfits(method)}, one can choose how to deal with those misfits.

{dlgtab:Options}

{phang}
{opt r:eplace} checks that the {bf:treatment} variable exists and, if so, it replaces it.
 This is useful if one is trying different specifications for {cmd:randtreat} and wishes to avoid {help drop:dropping} the {bf:treatment} variable every time.

{phang}
{opt mu:lt(integer)} specifies the number of treatments (including a control group) that will be randomized.
If not specified, it defaults to two (0 and 1), unless the {opt u:neven()} option is specified (see below).

{phang}
{opt u:neven(fractions)} serves two purposes.
 Explicitly, it defines uneven fractions for treatments.
 For example, specifying {opt u:neven(1/2 1/4 1/4)} will randomly assign half of the observations to the control group and then divide evenly the rest of the observations amongst two treatments.
 Also, it implicitly defines the number of treatments. For example, in the aforementioned specification we implicitly defined 3 treatments (0, 1, 2).
 So when the {opt u:neven()} option is used, {opt mu:lt()} is redundant and should be avoided.
 Only fractions can be specified, so {opt u:neven(.5 .25 .25)}, though equivalent to our example, is not allowed. Each fraction must be belong in (0,1) and their sum must add up exactly to 1.

{phang}
{opt mi:sfits(method)} specifies which method to use in order to deal with misfits.
The available {it:methods} are:

{phang2}{opt missing} is the default option and simply leaves misfit observations as missing values in {bf:treatment}, so the user can later deal with misfits as he sees fit.

{phang2}{opt strata} randomly allocates misfits independently accross all strata.
It does so by randomizing the 'randpack' and then filling in the misfits in each stratum.
This ensures that the fractions specified in {bf:uneven()} affect the within-distribution of treatments among misfits, so overall balance of uneven treatments should be (almost) attained.
However, this method doesn't ensure the balance of treatments within each stratum (they could differ by more than 1).

{phang2}{opt overall} randomly allocates all misfits globally.
It does so by randomizing the 'randpack' and then filling in the misfits sequentially accross all strata.
This ensures balance at the the global level and also respects uneven fractions of treatments.
The downside is that this method could produce even greater unbalance at the finer level (in each stratum), specially if the number of misfits is relatively large.


{title:Examples}

I suggest you {help tabulate} {bf:treatment} after running each example.

	{cmd:sysuse bpwide, clear}
	
	{cmd:randtreat}
	{cmd:randtreat, mult(5) replace}
	{cmd:randtreat, uneven(2/5 1/5 1/5 1/5) r}
	{cmd:randtreat sex agegrp, u(1/2 1/3 1/6) r}
	{cmd:randtreat sex agegrp, u(1/2 1/3 1/6) r} missing(strata)
	{cmd:randtreat sex agegrp, u(1/2 1/3 1/6) r} mi(overall)


{title:Notes}

{pstd}
Beware of (ab)using the {opt u:neven()} with fractions that yield a large least common multiple (LCM), because that may produce a large number of misfits. Consider for example:
	
	{cmd: sysuse bpwide, clear}
	{cmd: randtreat, uneven(2/5 1/3 3/20 3/20)}
	{cmd: tab treatment, missing}
	
{pstd}
Since the LCM of the specified fractions is 60, the theoretical maximum number of misfits per stratum could be 59.
In this particular dataset, this configuration produces 58 misfits, which is a relatively large number (considering it has 120 observations).

{title:Author}
{pstd}Alvaro Carril, J-PAL LAC, Chile {break}
acarril@fen.uchile.cl

{title:Acknowledgements}
{pstd}
I'm indebted to several "random helpers" at the Random Help Google user group and in the Statalist Forum, who provided coding advice and snippets.

{pstd}
Colleagues at the J-PAL LAC office, specially Olivia Bordeu and Diego Escobar, put up with my incoherent ideas and helped me steer this into something mildly useful.

{title:References}
{phang}Bruhn, Miriam, and David McKenzie. 2009. “In Pursuit of Balance: Randomization in Practice in Development Field Experiments.” American Economic Journal: Applied Economics 1 (4): 200–232.

{phang}Bruhn, Miriam, and David McKenzie. 2015. “Tools of the Trade: Doing Stratified Randomization with Uneven Numbers in Some Strata.” Blog. The World Bank: Impact Evaluations.
{browse "http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-uneven-numbers-in-some-strata"}.
