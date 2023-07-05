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

# options(andromedaTempFolder = "d:/andromedaTemp")
# folder <- "d:/glovehd_MDCD"
# library(dplyr)
# library(Matrix)

#' Create concept co-occurrence matrix
#'
#' @param data           An Andromeda object as created using [extractData()].
#' @param rollUpConcepts Should concepts be expanded to include all their ancestors 
#'                       as well?
#'
#' @return 
#' Returns a spare matrix containing the concept co-occurrences. For your 
#' convenience, the concept reference is attached as an attribute.
#' 
#' @export
createMatrix <- function(data, rollUpConcepts = TRUE) {
  errorMessages <- checkmate::makeAssertCollection()
  checkmate::assertClass(data, "Andromeda", add = errorMessages)
  checkmate::assertLogical(rollUpConcepts, len = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)
  startTime <- Sys.time()
  
  observationPeriodReference <- data$observationPeriodReference %>%
    arrange(.data$observationPeriodSeqId) %>%
    collect()
  
  if (rollUpConcepts) {
    conceptReference <- data$conceptReference %>%
      collect()
    conceptAncestor <- data$conceptAncestor %>%
      collect() 
    message("Removing generic concepts and extreme descendants from ancestor tree")
    genericConceptIds <- getGenericConceptIds(conceptReference)
    extremeDescendantIds <- getExtremeDescendantConceptIds(conceptAncestor)
    conceptAncestor <- conceptAncestor %>%
      filter(!.data$ancestorConceptId %in% genericConceptIds,
             !.data$descendantConceptId %in% genericConceptIds) %>%
      filter((!.data$descendantConceptId %in% extremeDescendantIds) | 
               (.data$descendantConceptId == .data$ancestorConceptId))
    remainingConceptIds <- unique(c(
      conceptAncestor %>%
        distinct(.data$ancestorConceptId) %>%
        pull(),
      conceptAncestor %>%
        distinct(.data$descendantConceptId) %>%
        pull()
    ))
    conceptReference <- conceptReference %>%
      filter(.data$conceptId %in% remainingConceptIds)
  } else {
    conceptReference <- data$conceptReference %>%
      filter(.data$verbatim == 1) %>%
      collect()
    conceptAncestor <- tibble()
  }
  
  conceptData <- data$conceptData %>%
    arrange(.data$observationPeriodSeqId)
  
  context <- 0 #Symmetrical
  windowSize <- 15
  weights <- 1 / (1 + abs(seq_len(windowSize) - (windowSize + 1) / 2))
  message("Constructing co-occurrence matrix")
  matrix <- buildMatrix(conceptData = conceptData, 
                        observationPeriodReference = observationPeriodReference, 
                        weights = weights, 
                        windowSize = windowSize, 
                        context = context, 
                        conceptIds = conceptReference$conceptId,
                        conceptAncestor = conceptAncestor)
  attr(matrix, "conceptReference") <- conceptReference
  
  delta <- Sys.time() - startTime
  message(paste("Constructing co-occurrence matrix took", signif(delta, 3), attr(delta, "units")))
  return(matrix)
}

getConceptReference <- function(conceptIds, matrix) {
  attr(matrix, "conceptReference")  %>%
    filter(.data$conceptId %in% as.numeric(conceptIds)) %>%
    return()
}

getGenericConceptIds <- function(conceptReference) {
  pattern <- paste("finding$", 
                   "^Disorder of",
                   "^Finding of", 
                   "^Disease of",
                   "^Injury of",
                   "disorder$",
                   "by site$",
                   "by anatomical site$",
                   "by body site$",
                   "by mechanism$",
                   "body region$",
                   "specific body structure$",
                   "^Procedure",
                   "procedure$",
                   "procedures$",
                   "Procedures$",
                   "Services$",
                   "system$",
                   "Concept$",
                   "Product$",
                   "Medicine$",
                   "^Pill$",
                   "^Measurement$",
                   "^Regimes and therapies$",
                   "^Imaging$",
                   "^Care regime$",
                   "^Removal$",
                   "^Therapy$",
                   sep = "|")
  conceptReference %>%
    filter(grepl(pattern, .data$conceptName)) %>%
    pull(.data$conceptId) %>%
    return()
}

getExtremeDescendantConceptIds <- function(conceptAncestor) {
  conceptIds <- conceptAncestor %>%
    group_by(.data$descendantConceptId) %>%
    summarise(count = n()) %>%
    filter(.data$count > 100) %>%
    pull(.data$descendantConceptId)
  return(conceptIds)
}
