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
#' @param analysisIdOffset      The first analysis ID to use for the covariates. 
#'                              Each time window will receive a separate analysis 
#'                              ID. The last 3 digits of the covariate IDs will be 
#'                              the analysis ID.
#'
#' @return
#' An object of type `covariateSettings`, to be used with prediction models.
#' 
#' @export
createBaseCovariateSettings <- function(type = "binary",
                                        windowStart = c(-365, -180, -30),
                                        windowEnd = c(0, 0, 0),
                                        analysisIdOffset = 930) {
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
      analysisId = analysisIdOffset + (i - 1) * 10,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10,
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
      analysisId = analysisIdOffset + (i - 1) * 10 + 1,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10 + 1,
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
      analysisId = analysisIdOffset + (i - 1) * 10 + 2,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10 + 2,
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
      analysisId = analysisIdOffset + (i - 1) * 10 + 3,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10 + 3,
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
      analysisId = analysisIdOffset + (i - 1) * 10 + 4,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10 + 4,
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
      analysisId = analysisIdOffset + (i - 1) * 10 + 5,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10 + 5,
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
      analysisId = analysisIdOffset + (i - 1) * 10 + 6,
      sqlFileName = sqlFileName ,
      parameters = list(
        analysisId = analysisIdOffset + (i - 1) * 10 + 6,
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
#' @param analysisIdOffset      The first analysis ID to use for the covariates. 
#'                              Each time window will receive a separate analysis 
#'                              ID. The last 3 digits of the covariate IDs will be 
#'                              the analysis ID.
#'
#' @return
#' An object of type `covariateSettings`, to be used with prediction models.
#' 
#' @export
createGloVeCovariateSettings <- function(baseCovariateSettings = createBaseCovariateSettings(),
                                         conceptVectors,
                                         analysisIdOffset = 990) {
  # Note: Row names get lost, possibly because settings are converted to JSON and back,
  # so storing separately:
  covariateSettings <- list(baseCovariateSettings = baseCovariateSettings,
                            conceptVectors = conceptVectors,
                            conceptIds = as.numeric(rownames(conceptVectors)),
                            analysisIdOffset = analysisIdOffset)
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
  covariateData <- convertCovariateData(
    baseCovariateData = baseCovariateData, 
    conceptVectors = covariateSettings$conceptVectors,
    conceptIds = covariateSettings$conceptIds,
    analysisIdOffset = covariateSettings$analysisIdOffset)
  return(covariateData)
}

convertCovariateData <- function(baseCovariateData, conceptVectors, conceptIds, analysisIdOffset) {
  message("Deriving GloVe features from concept features")
  newAnalysisRef <- baseCovariateData$analysisRef %>%
    distinct(.data$startDay, .data$endDay) %>%
    collect() %>%
    mutate(analysisId = analysisIdOffset + row_number() - 1,
           analysisName = sprintf("Global vectors days %d - %s", .data$startDay, .data$endDay),
           domainId = "All",
           isBinary = "N",
           missingMeansZero = "Y")
  
  newCovariateData <- Andromeda::andromeda(
    analysisRef = newAnalysisRef
  )
  for (i in seq_len(nrow(newAnalysisRef))) {
    newCovariates <- computeNewCovariatesForWindow(
      window = newAnalysisRef[i, ], 
      baseCovariateData = baseCovariateData, 
      conceptVectors = conceptVectors,
      conceptIds = conceptIds)
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
computeNewCovariatesForWindow <- function(window, baseCovariateData, conceptVectors, conceptIds) {
  
  computeAverageConceptVector <- function(rows, rowId) {
    idx <- match(rows$conceptId, conceptIds)
    if (all(is.na(idx))) {
      return(NULL)
    }
    sums <- apply(conceptVectors[idx, , drop = FALSE] * rows$covariateValue, 2, sum, na.rm = TRUE)
    n <- sum(rows$covariateValue[!is.na(idx)])
    tibble(
      rowId = rowId$rowId[1],
      covariateId = seq_along(sums) * 1000 + window$analysisId,
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
    mutate(conceptId = floor(.data$covariateId / 1000)) %>%
    select("rowId", "conceptId", "covariateValue")
  newCovariates <- conceptCovariates %>%
    group_by(.data$rowId) %>%
    group_map(computeAverageConceptVector) %>%
    bind_rows()
  return(newCovariates)
}
