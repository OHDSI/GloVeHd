% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CovariateBuilder.R
\name{createBaseCovariateSettings}
\alias{createBaseCovariateSettings}
\title{Create base covariate settings}
\usage{
createBaseCovariateSettings(
  type = "binary",
  windowStart = c(-365, -180, -30),
  windowEnd = c(0, 0, 0),
  analysisIdOffset = 930
)
}
\arguments{
\item{type}{Either "binary" or "count".}

\item{windowStart}{A vector representing the start (in days relative to cohort start) of windows.}

\item{windowEnd}{A vector representing the end (in days relative to cohort start) of windows.}

\item{analysisIdOffset}{The first analysis ID to use for the covariates.
Each time window will receive a separate analysis
ID. The last 3 digits of the covariate IDs will be
the analysis ID.}
}
\value{
An object of type \code{covariateSettings}, to be used with prediction models.
}
\description{
Create base covariate settings
}
