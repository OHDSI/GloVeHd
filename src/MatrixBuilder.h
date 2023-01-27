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

#ifndef MATRIXBUILDER_H_
#define MATRIXBUILDER_H_

#include <Rcpp.h>
#include "PersonDataIterator.h"
#include "SparseTripletMatrix.h"
using namespace Rcpp;

namespace ohdsi {
namespace glovehd {

class MatrixBuilder {
public:
  MatrixBuilder(const List& _conceptData,
                const DataFrame& _observationPeriodReference,
                const std::vector<double>& _weights,
                const int _windowSize,
                const int _context,
                const std::vector<double>& _conceptIds);
  S4 buildMatrix();
private:
  void processPerson(PersonData& personData);
  
  SparseTripletMatrix<float> matrix;
  PersonDataIterator personDataIterator;
  std::vector<double> weights;
  int windowSize;
  int context;
  std::vector<double> conceptIds;
  std::map<int64_t, int> conceptIdToIndex;
  int priorDays;
  int postDays;
};
}
}

#endif /* MATRIXBUILDER_H_ */
