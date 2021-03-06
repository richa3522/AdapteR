% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/platforms.R
\name{FLcreatePlatformsMapping}
\alias{FLcreatePlatformsMapping}
\title{Function to generate platforms mappings for stored procs and UDTs from definitions file.}
\usage{
FLcreatePlatformsMapping(definitions = c("data/platformStoredProcs.RFL",
  "data/platformMatrixUDT.RFL"))
}
\description{
The definitions file has one definition per line
<TD_FNAME>.<PLATFORM>(<TD_ARGS>) <- <PLATFORM_FNAME>(<PLATFORM_ARGS>)
The definitions file for UDTs has one definition per line
<TD_FNAME>.<PLATFORM>(<TD_OUTPUTCOLS>) <- <PLATFORM_FNAME>(<PLATFORM_OUTPUTCOLS>)
}

