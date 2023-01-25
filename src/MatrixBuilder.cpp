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

#ifndef MATRIXBUILDER_CPP_
#define MATRIXBUILDER_CPP_

#include <ctime>
#include <Rcpp.h>
#include "MatrixBuilder.h"
#include "PersonDataIterator.h"

using namespace Rcpp;

namespace ohdsi {
namespace glovehd {

MatrixBuilder::MatrixBuilder(const List& _conceptData,
                             const DataFrame& _observationPeriodReference,
                             const NumericVector& _weights,
                             const int _windowSize,
                             const int _context,
                             const int _numberOfConcepts) :
matrix(_numberOfConcepts, _numberOfConcepts),
personDataIterator(_conceptData, _observationPeriodReference),
weights(_weights),
windowSize(_windowSize),
context(_context),
numberOfConcepts(_numberOfConcepts) {
  
}

void MatrixBuilder::processPerson(PersonData personData) {
  
}


S4 MatrixBuilder::buildMatrix() {
  while (personDataIterator.hasNext()) {
    PersonData personData = personDataIterator.next();
    processPerson(personData);
  }
  CharacterVector dummy_dimnames(0);
  return matrix.get_sparse_triplet_matrix(dummy_dimnames, dummy_dimnames);
}

}
}

#endif /* MATRIXBUILDER_CPP_ */
