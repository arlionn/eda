********************************************************************************
* Description of the Program -												   *
* EDA Stata program for automated exploratory data analysis			 		   *
*                                                                              *
* Program Output -                                                             *
*     Creates LaTeX output, pdf/gph graphs, and an optional PDF compiled from  *
*	  the LaTeX source document.											   *
*                                                                              *
* Lines -                                                                      *
*     625                                                                      *
*                                                                              *
********************************************************************************
		
*! eda
*! v 0.0.0
*! 27OCT2015

// If you don't have the tuples program installed you may want to do that
// ssc inst tuples, replace
cap prog drop eda

// Install the estout program for generating tables of statistics
// ssc inst estout, replace
prog def eda

	// Version to use for interpretation of code
	version 14

	// Syntax structure of program	
	syntax [varlist] [using/] [if] [in], Output(string) Root(string)		 ///   
	[ IDvars(varlist) STRok STRok2(varlist) MINNsize(passthru) 				 ///   
	MINCat(passthru) MAXCat(passthru) CATVars(passthru) CONTVars(passthru) 	 ///   
	AUTHorname(string) MISSing scheme(passthru) keepgph PERCent 			 ///   
	GRLABLength(int 50) noBARGRaphs BARGRAphopts(string asis)				 ///   
	noPIECharts PIECHartopts(string asis) noHISTOgrams 						 ///   
	HISTOGramopts(string asis) KDENSity KDENSOpts(string asis) FIVENUMsum 	 ///   
	FNSOpts(string asis) noDISTROplots DISTROPlotopts(string asis) 			 ///   
	noLADDERplots noSCATterplots LFIT LFIT2(string asis) QFIT 				 ///   
	QFIT2(string asis) LOWess LOWess2(string asis) FPFIT FPFIT2(string asis) ///   
	LFITCi LFITCi2(string asis) QFITCi QFITCi2(string asis) FPFITCi 		 ///   
	FPFITCi2(string asis) noBUBBLEplots noBOXplots noMOSAIC noHEATmap 		 ///   
	COMPile PDFLatex(passthru) SLOw]

	// Make the sample to use for the program
	marksample edause, strok novarlist

	// Check percentage option
	if "`percent'" == "" {

		// If percentage is not specified set it to frequency
		loc bartype count
		
	} // End IF Block for percent/count switch

	// If turned on
	else {

		// Set the bartype macro
		loc bartype percent

	} // End ELSE Block for percent option

	// Check author name field	
	if `"`authorname'"' == "" {

		// If null pull the username from the system
		loc authorname `c(username)'
		
	} // End IF Block for author name
	
	// Check slow option
	if "`slow'" != "" {
	
		// Set local macro with sleep command
		loc slow sleep 5000
		
	} // End IF Block for slow option

	// Preserve the current state of the data in memory
	preserve

		// If user specifies data not currently in memory
		if `"`using'"' != "" {

			// Load data if file is specified
			qui: use `varlist' `"`using'"', clear

		} // End IF Block for using file
			
		// Build root directory
		dirfile, p(`"`root'"') rebuild

		// Build graphs subdirectory
		dirfile, p(`"`root'/graphs"') 

		// Build subdirectory for tables
		dirfile, p(`"`root'/tables"') 

		// Check for variable list for strings OK
		if `"`strok'"' != "" & `"`strok2'"' != "" {
		
			// Remove ID Variables from string variable list
			loc strvars : list strok2 - idvars
			
			// Check if varlist option
			if `"`varlist'"' != "" {
			
				// Remove variables not passed as part of varlist
				loc strvars : list strvars & varlist
				
			} // End IF Block to select only variables in the varlist
			
			// Loop over string variables
			foreach i in `strvars' {
			
				// Create a numeric version 
				qui: encode `i', gen(`i'2)
				
				// Apply variable label to numeric version of string variable
				la var `i'2 `"`: var l `i''"'
				
			} // End Loop over string variables

		} // End IF Block for string ok variable list
		
		// If user wants any string variable to be considered 
		else if `"`strok'"' != "" & `"`strok2'"' == "" {

			// Get list of all string variables
			qui: ds, has(type string)
			
			// Store string variables in local macro for later
			loc strvars `r(varlist)'
			
			// Remove any ID variables from string variable list
			loc strvars : list strvars - idvars
			
			// Check if varlist option
			if `"`varlist'"' != "" {
			
				// Remove variables not passed as part of varlist
				loc strvars : list strvars & varlist
				
			} // End IF Block to select only variables in the varlist
			
			// Loop over string variables
			foreach i in `strvars' {
			
				// Create a numeric version 
				qui: encode `i', gen(`i'2)
				
				// Apply variable label to numeric version of string variable
				la var `i'2 `"`: var l `i''"'
				
			} // End Loop over string variables
			
		} // End ELSEIF Block for all strings OK 
		
		// New way to try identifying categorical vs. continuous variables
		qui: ds, not(type string)

		// Store the variables in a new local macro
		loc numvars `r(varlist)'

		// Remove any id variables from the variable list
		loc numvars : list numvars - idvars

		// Check for varlist argument
		if `"`varlist'"' != "" {

			// Only include variables in varlist
			loc numvars : list numvars & varlist
			
		} // End IF Block for varlist argument

		// Classify variables as continuous or categorical
		catorcont `numvars', `minnsize' `mincat' `maxcat' `contvars' 		 ///   
		`catvars' `missing'

		// Store continuous variables
		loc continuous `r(cont)'

		// Store categorical variables
		loc categorical `r(cat)'
		
		// Store number of continuous variables to prevent zero varlists
		loc contvarcount `: word count `continuous''
		
		// Store number of categorical variables to prevent zero varlists
		loc catvarcount `: word count `categorical''

		// Add characteristics to variables to split the var labels for titles
		grlabsplit `continuous' `categorical', grlablength(`grlablength') 

		// Create a new LaTeX File
		file open doc using `"`root'/`output'.tex"', w replace

		// Write a LaTeX file Heading
		file write doc "\documentclass[12pt,oneside,final,letterpaper]{article}" _n
		file write doc "\usepackage{pdflscape}" _n
		file write doc "\usepackage[letterpaper,margin=0.25in]{geometry}" _n
		file write doc "\usepackage{graphicx}" _n
		file write doc "\usepackage[hidelinks]{hyperref}" _n
		file write doc "\usepackage{longtable}" _n
		file write doc "\usepackage[toc,page,titletoc]{appendix}" _n
		file write doc "\DeclareGraphicsExtensions{.pdf, .png}" _n
		file write doc `"\graphicspath{{"`root'/graphs/"}}"' _n
		file write doc `"\title{Exploratory Data Analysis of: \\ $S_FN}"'  _n
		file write doc `"\author{`authorname'}"' _n
		file write doc "\let\mypdfximage\pdfximage" _n
		file write doc "\def\pdfximage{\immediate\mypdfximage}" _n
		file write doc "\begin{document}" _n
		file write doc "\begin{titlepage} \maketitle \end{titlepage}" _n
		file write doc "\newpage\clearpage \tableofcontents \newpage\clearpage" _n
		file write doc "\listoffigures \newpage\clearpage" _n 
		file write doc "\listoftables \newpage\clearpage" _n
		file write doc "\section{Graphs} \newpage\clearpage" _n
		file write doc "\begin{landscape}" _n

		// Make sure the data are stored more efficiently
		qui: compress
		
		/*
		// Build a codebook
		codebook, all mv

		// The inspect command will give a bit more detail regarding the distribution of
		// the data in addition to more meta-data 
		inspect

		// Look at the missing values
		misstable summ

		// And look at patterns of missing data
		misstable pattern
		*/
		
		// Add entry for univariate distributions
		file write doc "\subsection{Univariate Distributions} \newpage\clearpage" _n

		// Add subsubsection header for categorical data
		file write doc "\subsubsection{Categorical Variables} \newpage\clearpage" _n
		
		// Check if user wants bargraphs
		if "`bargraphs'" != "nobargraphs" & !inlist(`catvarcount', 0, .) {

			// Call Bar graph subroutine
			edabar `categorical' if `edause', root(`root') `bargraphopts' 	 ///   
											  bart(`bartype') `scheme' `keepgph'

		} // End IF Block for bar graph creation
		
		// Check if user wants pie charts
		if "`piecharts'" != "nopiecharts" & !inlist(`catvarcount', 0, .) {

			// Call Pie chart subroutine
			edapie `categorical' if `edause', root(`root') `piechartopts' 	 ///   
			`scheme' `keepgph'

		} // End IF Block for pie charts option

		// Add subheading to the LaTeX file
		file write doc "\subsubsection{Continuous Variables} \newpage\clearpage" _n

		// Check if user wants histograms
		if "`histograms'" != "nohistograms" & !inlist(`contvarcount', 0, .) {

			// Call histogram subroutine
			edahist `continuous' if `edause', `histogramopts' `scheme' 		 ///   
			root(`root') `kdensity' kdensopts(`kdensopts') `fivenumsum' 	 ///   
			fnsopts(`fnsopts')

		} // End IF Block for histograms


		// Check for distroplots option
		if "`distroplots'" != "nodistroplots" & !inlist(`contvarcount', 0, .) {

			// Call distribution plot subroutine
			edadistro `continuous' if `edause', root(`root') `scheme' 		 ///   
			`keepgph' distrop(`distroplotopts')

		} // End IF Block for distribution plots

		// Check for ladders
		if "`ladderplots'" != "noladderplots" & !inlist(`contvarcount', 0, .) {

			// Call subroutine for ladders of power graphs
			edaladder `continuous' if `edause', `scheme' `histogramopts' 	 ///   
			root(`root')

		} // End IF Block for ladder of power graphs

		// Header for bivariate/conditional distribution graphs
		file write doc "\subsection{Bivariate Distributions} \newpage\clearpage" _n

		// Check for scatter plot option
		if "`scatterplots'" != "noscatterplots" & !inlist(`contvarcount', 0, .) {

			// Call to scatterplot subroutine
			edascat `continuous' if `edause', `lfit' lfit2(`lfit2')	`qfit' 	 ///   
			qfit2(`qfit2') `lowess' lowess2(`lowess2') `fpfit' 				 ///   
			fpfit2(`fpfit2') `lfitci' lfitci2(`lfitci2') `qfitci' 			 ///   
			qfitci2(`qfitci2') `fpfitci' fpfitci2(`fpfitci2') root(`root') 	 ///   
			`scheme' `keepgph'

		} // End IF Block for scatter plots

		// Check for bubble plots
		if "`bubbleplots'" != "nobubbleplots" & !inlist(`contvarcount', 0, .) {

			// Call subroutine for bubble plots
			edabubble `continuous' if `edause', root(`root') `scheme' `keepgph'

		} // End IF Block for bubble plots


		// Check distro plots again
		if "`distroplots'" != "nodistroplots" & !inlist(`contvarcount', 0, .) {

			// Call subroutine for joint distribution plots
			edadistro `continuous' if `edause', nounivariate root(`root') 	 ///   
			`scheme' `keepgph' distrop(`distroplotopts')

		} // End IF Block for quantile-quantile plots

				
		// Option to generate box plots
		if "`boxplots'" != "noboxplots" & (!inlist(`contvarcount', 0, .) & 	 ///   
		!inlist(`catvarcount', 0, .)) {

			// Create Box Plots
			edabox if `edause', cat(`categorical') cont(`continuous') 		 ///   
			root(`root') `scheme' `keepgph'
			
		} // End IF Block for box plots


		// Check for mosiac/spine plots
		if "`mosaic'" != "nomosaic" & !inlist(`catvarcount', 0, .) {

			// Subroutine used to generate mosaic/spine plots
			edamosaic `categorical' if `edause', root(`root') `scheme'  	 ///   
			`missing' `percent'	`keepgph'

		} // End IF Block for mosaic plot creation


		// Check for correlation heatmap option
		if "`heatmap'" != "noheatmap" & !inlist(`contvarcount', 0, .) {

			// Create heatmap from continuous variables
			edaheat `continuous' if `edause', root(`root') `keepgph'
			
		} // End IF Block for correlation heatmap option


		// Change back to portrait page layout
		file write doc "\end{landscape}" _n

		// Create next section/subsection headers
		file write doc "\section{Descriptive Statistics} \newpage\clearpage" _n
		
		// Adjust variable labels since they get used in the tables
		foreach v of var `categorical' `continuous' {
		
			// Get LaTeX sanitized string of the variable label
			texclean `"`: var l `v''"'
			
			// Relabel the variable
			la var `v' `"`r(clntex'"'
			
		} // End Loop to relabel variables

		// Check for categorical variables
		if !inlist(`catvarcount', 0, .) {

			// Add categorical variable header
			file write doc "\subsection{Categorical Variables} \newpage\clearpage" _n
			
			// Create statistical summaries of all categorical variables
			foreach v of var `categorical' {

				// Use estpost to post the results of the tabulation
				qui: estpost ta `v' if `edause', mi notot

				// Export table to LaTeX file
				esttab . using `"`root'/tables/tab`v'.tex"', uns noobs 		 ///   
				longtable varlabels(`e(labels)') eql("`v'") ml(, none) 		 ///   
				nonum cells("b pct(fmt(a3))") replace						 ///   
				coll("Frequency" "Percentage") ti(`"Distribution of `v'"')
				
				// Add the table to the LaTeX document
				file write doc "\begin{table}[h]" _n
				file write doc `"\input{"`root'/tables/tab`v'"}"' _n
				file write doc "\end{table}" _n

			} // End Loop to build one-way tables

			// Change back to portrait page layout
			file write doc "\begin{landscape}" _n

			// Generate all of the two-way permutations
			tuples `categorical', asis min(2) max(2)

			// Create two-way tables 
			forv i = 1/`ntuples' { 
					
				// Get the first variable
				loc one : word 1 of `tuple`i''
				
				// Get the second variable
				loc two : word 2 of `tuple`i''
					
				// Create cross-tabulation
				qui: estpost ta `one' `two' if `edause', mi notot

				// Export it to LaTeX
				esttab . using `"`root'/tables/tab`one'`two'.tex"', replace  ///   
				varlabels(`e(labels)') eql(`e(eqlabels)') ml(, none) nonum   ///   
				cells("b pct(fmt(a3)) colpct(fmt(a3)) rowpct(fmt(a3))") 	 ///   
				coll("Frequency" "Overall\%" "Column\%" "Row\%") noobs uns 	 ///   
				longtable ti(`"Distribution of `one' by `two'"')

				// Add the table to the LaTeX document
				file write doc "\begin{table}[h]" _n
				file write doc `"\input{"`root'/tables/tab`one'`two'"}"' _n
				file write doc "\end{table}" _n

			} // End Loop for two way tables

			// Change back to portrait page layout
			file write doc "\end{landscape}" _n
			
		} // End IF Block for categorical variables	

		// Check for categorical variables
		if !inlist(`contvarcount', 0, .) {

			file write doc "\subsection{Continuous Variables} \newpage\clearpage" _n	

			// Create summary statistics table for continuous variables
			qui: estpost su `continuous' if `edause', de  quietly

			// Create LaTeX table of parametric descriptive stats
			esttab . using `"`root'/tables/descriptives.tex"', nonum nodep nomti ///   
			noobs ti("Descriptive Statistics of Continuous Variables") 			 ///   
			cells("count mean(fmt(3)) sd(fmt(3))") label replace longtable 		 ///   
			varlabels(`e(labels)') collab("N" "$\mu$" "$\sigma$")				 ///   
			addn("$\mu$ = Average $\sigma$ = Standard Deviation")

			// Create summary statistics table for continuous variables
			qui: estpost su `continuous' if `edause', de  quietly

			// Create table of higher order moment conditions
			esttab . using `"`root'/tables/higherorder.tex"', nodep nomti noobs  ///   
			label cells("skewness(fmt(3)) kurtosis(fmt(3))") replace nonum 		 ///   
			collab("Skewness" "Kurtosis") longtable varlabels(`e(labels)')		 ///   
			ti("Higher Order Moment Conditions")  	
			
			// Create summary statistics table for continuous variables
			qui: estpost su `continuous' if `edause', de  quietly

			// Create LaTeX table of non-parametric stats
			esttab . using `"`root'/tables/orderstats.tex"', nodep nomti noobs 	 ///   
			label ti("Order Statistics") nonum replace varlabels(`e(labels)') 	 ///   
			longtable collab("Min." "25\%ile" "Median" "75\%ile" "Max")			 ///   
			cells("min(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3)) max(fmt(3))") ///
			addn("This is also known as Tukey's Five Number Summary")
			
			// Create correlation matrix
			// estpost correlate `continuous', matrix

			// Create LaTeX table of the correlations table
			// esttab . using correlationtable.tex, not unstack compress noobs

			// Add both tables to LaTeX document
			file write doc "\begin{table}[h]" _n
			file write doc `"\input{"`root'/tables/descriptives"}"' _n
			file write doc "\end{table}" _n
			file write doc "\begin{table}[h]" _n
			file write doc `"\input{"`root'/tables/higherorder"}"' _n
			file write doc "\end{table}" _n
			file write doc "\begin{table}[h]" _n
			file write doc `"\input{"`root'/tables/orderstats"}"' _n
			file write doc "\end{table}"

		} // End IF Block for continuous variables
		
		// Check for categorical variables
		if !inlist(`catvarcount', 0, .) & !inlist(`contvarcount', 0, .) {
		
			// Add file header for conditional distributions
			file write doc "\section{Conditional Descriptive Statistics} \newpage\clearpage" _n

			// Set the maximum matrix size to prevent a matsize error in the loop below
			set matsize 11000

			// Create conditional descriptive statistics
			foreach cat of var `categorical' {

				// Get means/SDs for each category in variable cat
				qui: estpost tabstat `continuous' if `edause', by(`cat') 	 ///   
				s(mean) c(s) 

				// Get cleaned categorical variable name
				texclean "`cat'", r
				
				// Store name in cref
				loc cref `r(clntex)'

				// Create the output table
				esttab . using `"`root'/tables/condmean`cat'.tex"', label 	 ///   
				nomti nonum main(mean) nostar uns longtable replace			 ///   
				coll(`e(labels)') ti("Averages by groups of `cref'")
				
				// Add table to LaTeX document
				file write doc "\begin{table}[h]" _n
				file write doc `"\input{"`root'/tables/condmean`cat'"}"' _n
				file write doc "\end{table}" _n
				
				// Get means/SDs for each category in variable cat
				qui: estpost tabstat `continuous', by(`cat') s(sd) c(s) 

				// Create the output table
				esttab . using `"`root'/tables/condsd`cat'.tex"', label 	 ///   
				nomti nonum main(sd) nostar uns longtable replace			 ///   
				coll(`e(labels)') ti("Standard Deviations by groups of `cref'")

				// Add table to LaTeX document
				file write doc "\begin{table}[h]" _n
				file write doc `"\input{"`root'/tables/condsd`cat'"}"' _n
				file write doc "\end{table}" _n
				
			} // End Loop for conditional descriptive statistics	

		} // End IF Block for categorical and continuous variables	
			
		// Add ending to LaTeX file
		file write doc "\end{document}"

		// Close and save the LaTeX document
		file close doc

		// Check for option to compile LaTeX file
		if "`compile'" != "" {

			// Create bash/batch script to compile source
			maketexcomp "`root'/`output'.tex", scr(`"`root'/makeLaTeX"')	 ///   
			`pdflatex'
			
			// Local with code to execute compiler script
			loc exec `r(comp)'

			// Execute the compile script to make the LaTeX turn into a PDF
			`exec'
			
		} // End IF Block for compilation option	
		
	// Restore data to original state
	restore

// End program definition
end
