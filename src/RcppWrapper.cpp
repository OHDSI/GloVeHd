/*
 * This file is part of GloVeHd
 *
 * Copyright 2023 Observational Health Data Sciences and Informatics
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __RcppWrapper_cpp__
#define __RcppWrapper_cpp__

#include <Rcpp.h>
#include "MatrixBuilder.h"

using namespace Rcpp;

// [[Rcpp::export]]
S4 buildMatrix(const List& conceptData,
               const DataFrame& observationPeriodReference,
               const std::vector<double>& weights,
               const int windowSize,
               const int context,
               const std::vector<double>& conceptIds,
               const DataFrame& conceptAncestor) {

  using namespace ohdsi::glovehd;

  try {
    MatrixBuilder matrixBuilder(conceptData, observationPeriodReference, weights, windowSize, context, conceptIds, conceptAncestor);
    S4 matrix = matrixBuilder.buildMatrix();
    return matrix;
  } catch (std::exception &e) {
    forward_exception_to_r(e);
  } catch (...) {
    ::Rf_error("c++ exception (unknown reason)");
  }
  return R_NilValue;
}

#endif // __RcppWrapper_cpp__
