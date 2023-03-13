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

#' Create global vectors
#'
#' @param matrix     A concept co-occurrence matrix as created using [createMatrix()].
#' @param vectorSize The number of dimensions of the resulting global vectors.
#' @param maxCores   The number of parallel cores to use during computation.
#'
#' @return
#' A matrix representing the global vectors. The row names represent the concept IDs.
#' For your convencience, the concept reference is attached as an attribute.
#' 
#' @export
computeGlobalVectors <- function(matrix, vectorSize = 300, maxCores = 1) {
  # Normalize to avoid numerical issues:
  cutoff <- quantile(matrix@x, 0.95)
  matrix@x <- matrix@x / cutoff
  # matrix@x <- pmin(1, matrix@x)
  # matrix@x <- pmin(cutoff, matrix@x)
  glove = text2vec::GlobalVectors$new(rank = vectorSize, x_max = 1) #, learning_rate = 0.01) 
  wv_main = glove$fit_transform(matrix, n_iter = 100, convergence_tol = 0.01, n_threads = maxCores)
  wv_context = glove$components
  word_vectors = wv_main + t(wv_context)
  attr(word_vectors, "conceptReference") <- attr(matrix, "conceptReference")
  return(word_vectors)
}

#' Get similar concepts
#'
#' @param conceptId      The concept ID to use as query.
#' @param conceptVectors The global concept vectors as created using [computeGlobalVectors()].
#' @param n              The number of similar concepts to return.
#'
#' @return
#' Returns a tibble with the concepts most similar to the query concept.
#' 
#' @export
getSimilarConcepts <- function(conceptId, conceptVectors, n = 25) {
  query <- conceptVectors[as.character(conceptId), , drop = FALSE]
  cos_sim <- text2vec::sim2(x = conceptVectors, y = query, method = "cosine", norm = "l2")
  similarity <- head(sort(cos_sim[,1], decreasing = TRUE), n)
  similarity <- tibble(similarity = similarity, conceptId = as.numeric(names(similarity)))
  attr(conceptVectors, "conceptReference")  %>%
    inner_join(similarity, by = "conceptId") %>%
    arrange(desc(similarity)) %>%
    return()
}