# Copyright 2023 Observational Health Data Sciences and Informatics
#
# This file is part of GloVeHd
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# library(dplyr)

#' Create base covariate settings
#'
#' @param type        Either "binary" or "count".
#' @param windowStart A vector representing the start (in days relative to cohort start) of windows.
#' @param windowEnd   A vector representing the end (in days relative to cohort start) of windows.
#'
#' @return
#' An object of type `covariateSettings`, to be used with prediction models.
#' 
#' @export
createBaseCovariateSettings <- function(type = "binary",
                                        windowStart = c(-365, -180, -30),
                                        windowEnd = c(0, 0, 0)) {
  if (type == "binary") {
    sqlFileName <- "DomainConcept.sql"
    subType <- "all"
  } else {
    sqlFileName <- "ConceptCounts.sql"
    subType <- "stratified"
  }
  analyses <- list()
  for (i in seq_along(windowStart)) {
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 100 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 100 + i,
        analysisName = sprintf("Visit concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Visit",
        domainTable	= "visit_occurrence",
        domainConceptId = "visit_concept_id",
        domainStartDate = "visit_start_date",
        domainEndDate = "visit_start_date"
      )
    )
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 200 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 200 + i,
        analysisName = sprintf("Condition concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Condition",
        domainTable	= "condition_occurrence",
        domainConceptId = "condition_concept_id",
        domainStartDate = "condition_start_date",
        domainEndDate = "condition_start_date"
      )
    )
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 300 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 300 + i,
        analysisName = sprintf("Drug concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Drug",
        domainTable	= "drug_exposure",
        domainConceptId = "drug_concept_id",
        domainStartDate = "drug_exposure_start_date",
        domainEndDate = "drug_exposure_start_date"
      )
    )
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 400 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 400 + i,
        analysisName = sprintf("Procedure concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Procedure",
        domainTable	= "procedure_occurrence",
        domainConceptId = "procedure_concept_id",
        domainStartDate = "procedure_date",
        domainEndDate = "procedure_date"
      )
    )
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 500 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 500 + i,
        analysisName = sprintf("Device concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Device",
        domainTable	= "device_exposure",
        domainConceptId = "device_concept_id",
        domainStartDate = "device_exposure_start_date",
        domainEndDate = "device_exposure_start_date"
      )
    )
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 600 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 600 + i,
        analysisName = sprintf("Measurement concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Measurement",
        domainTable	= "measurement",
        domainConceptId = "measurement_concept_id",
        domainStartDate = "measurement_date",
        domainEndDate = "measurement_date"
      )
    )
    analyses[[length(analyses) + 1]] <- FeatureExtraction::createAnalysisDetails(
      analysisId = 700 + i,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = 700 + i,
        analysisName = sprintf("Observation concepts in days %d - %d", windowStart[i], windowEnd[i]),
        startDay = windowStart[i],
        endDay = windowEnd[i],
        subType = subType,
        domainId = "Observation",
        domainTable	= "observation",
        domainConceptId = "observation_concept_id",
        domainStartDate = "observation_date",
        domainEndDate = "observation_date"
      )
    )
    # Skipping death table because we assume patients will have no history of death
  }
  covariateSettings <- FeatureExtraction::createDetailedCovariateSettings(
    analyses = analyses
  )
  return(covariateSettings)
}

#' Create covariates using GloVe
#'
#' @param baseCovariateSettings The base covariate settings as created using the 
#'                              `createBaseCovariateSettings()` function.
#' @param conceptVectors        The global concept vectors as created using the 
#'                              `computeGlobalVectors()` function.
#'
#' @return
#' An object of type `covariateSettings`, to be used with prediction models.
#' 
#' @export
createGloVeCovariateSettings <- function(baseCovariateSettings = createBaseCovariateSettings(),
                                         conceptVectors) {
  covariateSettings <- list(baseCovariateSettings = baseCovariateSettings,
                            conceptVectors = conceptVectors)
  attr(covariateSettings, "fun") <- "GloVeHd:::getGloVeCovariates"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

getGloVeCovariates <- function(connection,
                               oracleTempSchema = NULL,
                               cdmDatabaseSchema,
                               cohortTable = "#cohort_person",
                               cohortId = -1,
                               cdmVersion = "5",
                               rowIdField = "subject_id",
                               covariateSettings,
                               aggregated = FALSE) {
  if (aggregated) {
    stop("Aggregation not supported")
  }
  baseCovariateData <- FeatureExtraction::getDbDefaultCovariateData(
    connection = connection,
    oracleTempSchema = oracleTempSchema,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable,
    cohortId = cohortId,
    cdmVersion = cdmVersion,
    rowIdField = rowIdField,
    covariateSettings = covariateSettings$baseCovariateSettings,
    aggregated = FALSE
  )
  covariateData <- convertCovariateData(baseCovariateData, covariateSettings$conceptVectors)
  return(covariateData)
}

convertCovariateData <- function(baseCovariateData, conceptVectors) {
  message("Deriving GloVe features from concept features")
  newAnalysisRef <- baseCovariateData$analysisRef %>%
    distinct(.data$startDay, .data$endDay) %>%
    collect() %>%
    mutate(analysisId = row_number(),
           analysisName = sprintf("Global vectors days %d - %s", .data$startDay, .data$endDay),
           domainId = "All",
           isBinary = "N",
           missingMeansZero = "Y")
  
  newCovariateData <- Andromeda::andromeda(
    analysisRef = newAnalysisRef
  )
  for (i in seq_len(nrow(newAnalysisRef))) {
    newCovariates <- computeNewCovariatesForWindow(newAnalysisRef[i, ], baseCovariateData, conceptVectors)
    newCovariateRef <- tibble(
      covariateId = seq_len(ncol(conceptVectors)) * 1000 + newAnalysisRef$analysisId[i],
      covariateName = sprintf(
        "Global vector component %d in days %d - %d", 
        seq_len(ncol(conceptVectors)), 
        newAnalysisRef$startDay[i],
        newAnalysisRef$endDay[i]
      ),
      analysisId = newAnalysisRef$analysisId[i],
      conceptId = NA
    )
    if (i == 1) {
      newCovariateData$covariates <- newCovariates
      newCovariateData$covariateRef <- newCovariateRef
    } else {
      Andromeda::appendToTable(newCovariateData$covariates, newCovariates)
      Andromeda::appendToTable(newCovariateData$covariateRef, newCovariateRef)
    }
  }
  attr(newCovariateData, "metaData") <-  attr(baseCovariateData, "metaData")
  class(newCovariateData) <- "CovariateData"
  attr(class(newCovariateData),"package") <- "FeatureExtraction"
  return(newCovariateData)
}
computeNewCovariatesForWindow <- function(window, baseCovariateData, conceptVectors) {
  
  computeAverageConceptVector <- function(rows, rowId) {
    idx <- match(rows$conceptId, conceptIdToIndex)
    sums <- apply(conceptVectors[idx, , drop = FALSE] * rows$covariateValue, 2, sum, na.rm = TRUE)
    n <- sum(rows$covariateValue[!is.na(idx)])
    tibble(
      rowId = rowId$rowId[1],
      covariateId = seq_along(sums) * 1000+ window$analysisId,
      covariateValue = sums / n
    ) %>%
      return()
  }
  
  analysisIds <- baseCovariateData$analysisRef %>%
    filter(
      .data$startDay == !!window$startDay, 
      .data$endDay == !!window$endDay
    ) %>%
    pull("analysisId")
  covariateIds <- baseCovariateData$covariateRef %>%
    filter(.data$analysisId %in% analysisIds) %>%
    pull("covariateId")
  conceptCovariates <- baseCovariateData$covariates %>%
    filter(.data$covariateId %in% covariateIds) %>%
    collect() %>%
    mutate(conceptId = round(.data$covariateId / 1000)) %>%
    select("rowId", "conceptId", "covariateValue")
  conceptIdToIndex <- round(as.numeric(rownames(conceptVectors)))
  newCovariates <- conceptCovariates %>%
    group_by(.data$rowId) %>%
    group_map(computeAverageConceptVector) %>%
    bind_rows()
  return(newCovariates)
}
