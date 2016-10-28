### R code from vignette source 'Rcpp-extending.Rnw'

###################################################
### code chunk number 1: Rcpp-extending.Rnw:45-50
###################################################
prettyVersion <- packageDescription("Rcpp")$Version
prettyDate <- format(Sys.Date(), "%B %e, %Y")
require(inline)
require(highlight)
require(Rcpp)


###################################################
### code chunk number 3: Rcpp-extending.Rnw:92-108
###################################################
code <- '
// we get a list from R
List input(input_) ;

// pull std::vector<double> from R list
// this is achieved through an implicit call to Rcpp::as
std::vector<double> x = input["x"] ;

// return an R list
// this is achieved through implicit call to Rcpp::wrap
return List::create(
    _["front"] = x.front(),
    _["back"]  = x.back()
    ) ;
'
writeLines( code, "code.cpp" )


###################################################
### code chunk number 4: Rcpp-extending.Rnw:110-111
###################################################
external_highlight( "code.cpp", type = "LATEX", doc = FALSE )


###################################################
### code chunk number 5: Rcpp-extending.Rnw:114-120
###################################################
fx <- cxxfunction( signature( input_ = "list"),
	paste( readLines( "code.cpp" ), collapse = "\n" ),
	plugin = "Rcpp"
	)
input <- list( x = seq(1, 10, by = 0.5) )
fx( input )


###################################################
### code chunk number 13: Rcpp-extending.Rnw:326-327
###################################################
unlink( "code.cpp" )


