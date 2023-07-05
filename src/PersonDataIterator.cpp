/*
 * @file PersonDataIterator.cpp
 *
 * This file is part of SelfControlledCaseSeries
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

#ifndef PERSONDATAITERATOR_CPP_
#define PERSONDATAITERATOR_CPP_

#include <Rcpp.h>
#include "PersonDataIterator.h"
#include "AndromedaTableIterator.h"

using namespace Rcpp;

namespace ohdsi {
namespace glovehd {

PersonDataIterator::PersonDataIterator(const List& _conceptData, const DataFrame& _observationPeriodReference,
                                       const DataFrame& _conceptAncestor) :
conceptDataIterator(_conceptData, true), 
observationPeriodStartDates(0), 
observationPeriodEndDates(0), 
observationPeriodCursor(0), 
conceptDataCursor(0),
conceptToAncestors(0) {
  
  personIds = _observationPeriodReference["personId"];
  observationPeriodIds = _observationPeriodReference["observationPeriodId"];
  observationPeriodSeqIds = _observationPeriodReference["observationPeriodSeqId"];
  observationPeriodStartDates = _observationPeriodReference["observationPeriodStartDate"];
  observationPeriodEndDates = _observationPeriodReference["observationPeriodEndDate"];
  
  if (_conceptAncestor.size() == 0) {
    rollUpConcepts = false;
  } else {
    rollUpConcepts = true;
    NumericVector ancestorConceptId = _conceptAncestor["ancestorConceptId"];
    NumericVector descendantConceptId = _conceptAncestor["descendantConceptId"];
    for (int i = 0; i < ancestorConceptId.size(); i++) {
      int id1 = (int)descendantConceptId[i];
      int id2 = (int)ancestorConceptId[i];
      if (conceptToAncestors.find(id1) == conceptToAncestors.end()) {
        std::vector<int> ancestors(1);
        ancestors.push_back(id2);
        conceptToAncestors[id2] = ancestors;
      } else {
        conceptToAncestors[id1].push_back(id2);
      }
    }
  }
  // Rcpp::Rcout << observationPeriodIds.length() << " length\n";
  loadNextConceptDatas();
}


void PersonDataIterator::loadNextConceptDatas() {
  // Load the next batch of concept data from the Andromeda iterator
  List conceptDatas = conceptDataIterator.next();
  conceptDataStartDays = conceptDatas["startDay"];
  conceptDataEndDays = conceptDatas["endDay"];
  conceptDataConceptIds = conceptDatas["conceptId"];
  conceptDataObservationPeriodSeqIds = conceptDatas["observationPeriodSeqId"];
}

bool PersonDataIterator::hasNext() {
  return (observationPeriodCursor < observationPeriodIds.length());
  // return (observationPeriodCursor < 100);
}

PersonData PersonDataIterator::next() {
  int observationPeriodSeqId = observationPeriodSeqIds.at(observationPeriodCursor);
  PersonData nextPerson(personIds.at(observationPeriodCursor),
                        observationPeriodIds.at(observationPeriodCursor),
                        observationPeriodSeqId,
                        observationPeriodStartDates.at(observationPeriodCursor),
                        observationPeriodEndDates.at(observationPeriodCursor));
  observationPeriodCursor++;
  while (conceptDataCursor < conceptDataObservationPeriodSeqIds.length() && 
         conceptDataObservationPeriodSeqIds.at(conceptDataCursor) < observationPeriodSeqId) {
    conceptDataCursor++;
    if (conceptDataCursor == conceptDataObservationPeriodSeqIds.length()){
      if (conceptDataIterator.hasNext()){
        loadNextConceptDatas();
        conceptDataCursor = 0;
      } else {
        break;
      }
    }
  }
  // Environment base = Environment::namespace_env("base");
  // Function message = base["message"];
  while (conceptDataCursor < conceptDataObservationPeriodSeqIds.length() && 
         conceptDataObservationPeriodSeqIds.at(conceptDataCursor) == observationPeriodSeqId) {
    double conceptId = conceptDataConceptIds.at(conceptDataCursor);
    double startDay = conceptDataStartDays.at(conceptDataCursor);
    double endDay = conceptDataEndDays.at(conceptDataCursor);
    if (rollUpConcepts) {
      std::unordered_map<int, std::vector<int>>::iterator iterator = conceptToAncestors.find((int)conceptId);
      if (iterator != conceptToAncestors.end()) {
        for (int ancestorConceptId: iterator->second) {
          ConceptData conceptData(startDay, endDay, (double)ancestorConceptId);
          nextPerson.conceptDatas->push_back(conceptData);
        }
        // message("- concept " + std::to_string(conceptId) + " ancestors: " + std::to_string(iterator->second.size()));
      }
    } else {
      ConceptData conceptData(startDay, endDay, conceptId);
      nextPerson.conceptDatas->push_back(conceptData);
    }
    conceptDataCursor++;
    if (conceptDataCursor == conceptDataObservationPeriodSeqIds.length()){
      if (conceptDataIterator.hasNext()){
        loadNextConceptDatas();
        conceptDataCursor = 0;
      } else {
        break;
      }
    }
  }
  
  // message("- Concept datas: " + std::to_string(nextPerson.conceptDatas->size()));
  std::sort(nextPerson.conceptDatas->begin(), nextPerson.conceptDatas->end());
  auto newEnd = std::unique(nextPerson.conceptDatas->begin(), 
                            nextPerson.conceptDatas->end());
  nextPerson.conceptDatas->erase(newEnd,
                                 nextPerson.conceptDatas->end());
  // message("- Unique concept datas: " + std::to_string(nextPerson.conceptDatas->size()));
  return nextPerson;
}
}
}
#endif /* PERSONDATAITERATOR_CPP_ */
