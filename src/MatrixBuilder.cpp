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
#include <string>
#include <Rcpp.h>
#include "MatrixBuilder.h"
#include "PersonDataIterator.h"

using namespace Rcpp;

namespace ohdsi {
namespace glovehd {

MatrixBuilder::MatrixBuilder(const List& _conceptData,
                             const DataFrame& _observationPeriodReference,
                             const std::vector<double>& _weights,
                             const int _windowSize,
                             const int _context,
                             const std::vector<double>& _conceptIds,
                             const DataFrame& _conceptAncestor) :
matrix(_conceptIds.size(), _conceptIds.size()),
personDataIterator(_conceptData, _observationPeriodReference, _conceptAncestor),
weights(_weights),
windowSize(_windowSize),
context(_context),
conceptIds(_conceptIds),
conceptIdToIndex() {
  switch(context) {
  case 0:
    // Symmetrical context
    priorDays = _windowSize / 2;
    postDays = _windowSize / 2;
    break;
  case -1:
    // Left context
    priorDays = _windowSize;
    postDays = 0;
    break;
  default:
    ::Rf_error("Illegal context");
  }
  for (unsigned int i = 0; i < _conceptIds.size(); i++) {
    conceptIdToIndex[_conceptIds[i]] = i;
    // if (conceptIdToIndex.size() % 1000 == 0) {
    //   Environment base = Environment::namespace_env("base");
    //   Function message = base["message"];
    //   message("- Concepts in matrix: " + std::to_string(conceptIdToIndex.size()));
    // }
  }
}

void MatrixBuilder::processPerson(PersonData& personData) {
  int priorCursor = 0;
  int postCursor = 0;
  int currentDay = -1;
  int conceptDataSize = personData.conceptDatas->size();
  // conceptData is sorted and unique by startDay and conceptId (by PersonDataIterator)
  for (std::vector<ConceptData>::iterator conceptData = personData.conceptDatas->begin(); 
       conceptData != personData.conceptDatas->end(); 
       ++conceptData) {
    if (conceptData->startDay > currentDay) {
      currentDay = conceptData->startDay;
      while (personData.conceptDatas->at(priorCursor).startDay < currentDay - priorDays && 
             priorCursor < conceptDataSize - 1)
        priorCursor++;
      while (personData.conceptDatas->at(postCursor).startDay < currentDay + postDays && 
             postCursor < conceptDataSize - 1)
        postCursor++;
      if (personData.conceptDatas->at(postCursor).startDay > currentDay + postDays)
        postCursor--;
    }
    for (int i = priorCursor; i <= postCursor; i++) {
      ConceptData contextConceptData = personData.conceptDatas->at(i);
      // if (contextConceptData.startDay != currentDay && 
      //     contextConceptData.conceptId != conceptData->conceptId) {
      double weight = weights.at(contextConceptData.startDay - currentDay + priorDays);
      int index = conceptIdToIndex[conceptData->conceptId];
      int contextIndex = conceptIdToIndex[contextConceptData.conceptId];
      matrix.add(index, contextIndex, weight);
      // }
    }
  }
}


S4 MatrixBuilder::buildMatrix() {
  while (personDataIterator.hasNext()) {
    PersonData personData = personDataIterator.next();
    processPerson(personData);
  }
  CharacterVector dimNames(conceptIds.size());
  for (unsigned int i = 0; i < conceptIds.size(); i++) {
    dimNames[i] = std::to_string((int) conceptIds[i]);
  }
  return matrix.get_sparse_triplet_matrix(dimNames, dimNames);
}

}
}

#endif /* MATRIXBUILDER_CPP_ */
