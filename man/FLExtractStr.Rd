% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/FLStringFunctions.R
\name{FLExtractStr}
\alias{FLExtractStr}
\title{Extract parts of strings}
\usage{
FLExtractStr(object, delimiter, stringpos)
}
\arguments{
\item{object}{FLVector of characters}

\item{delimiter}{character}

\item{stringpos}{identifier to reference the
sub-string given by its position}
}
\value{
FLVector
}
\description{
Extract sub-strings separated by a
delimiter and identified by their position.
}
\details{
The DB lytix function called is FlExtractStr.The extract string function is a scaler that
extracts a segment from a string concatenated with delimiter. The position parameter
indicates the location of the delimiter.If the string input doesn't have the delimiter 
indicated, a null is returned. If the last segment doesn't have a trailing delimiter 
but the position is indicated, then the last segment is returned.
}
\section{Constraints}{

row vectors are not supported currently.
}
\examples{
widetable  <- FLTable("tblstringID", "stringID")
flv <- widetable[1:6,"string"]
resultflvector <- FLExtractStr(flv,"A",1)
}
\seealso{
\code{\link[base]{substr}} , \code{\link[base]{strsplit}} for R function reference
implementation.
}

