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

PersonDataIterator::PersonDataIterator(const List& _conceptData, const DataFrame& _observationPeriodReference) :
conceptDataIterator(_conceptData, true), observationPeriodStartDates(0), observationPeriodEndDates(0), observationPeriodCursor(0), conceptDataCursor(0) {
  
  personIds = _observationPeriodReference["personId"];
  observationPeriodIds = _observationPeriodReference["observationPeriodId"];
  observationPeriodSeqIds = _observationPeriodReference["observationPeriodSeqId"];
  observationPeriodStartDates = _observationPeriodReference["observationPeriodStartDate"];
  observationPeriodEndDates = _observationPeriodReference["observationPeriodEndDate"];
  
  loadNextConceptDatas();
}


void PersonDataIterator::loadNextConceptDatas() {
  List conceptDatas = conceptDataIterator.next();
  conceptDataStartDays = conceptDatas["startDay"];
  conceptDataEndDays = conceptDatas["endDay"];
  conceptDataConceptIds = conceptDatas["conceptId"];
  conceptDataObservationPeriodSeqIds = conceptDatas["observationPeriodSeqId"];
}

bool PersonDataIterator::hasNext() {
  return (observationPeriodCursor < observationPeriodIds.length());
}

PersonData PersonDataIterator::next() {
  int observationPeriodSeqId = observationPeriodSeqIds[observationPeriodCursor];
  PersonData nextPerson(personIds[observationPeriodCursor],
                        observationPeriodIds[observationPeriodCursor],
                                            observationPeriodSeqId,
                                            observationPeriodStartDates[observationPeriodCursor],
                                                                       observationPeriodEndDates[observationPeriodCursor]);
  observationPeriodCursor++;
  
  while (conceptDataCursor < conceptDataObservationPeriodSeqIds.length() && conceptDataObservationPeriodSeqIds[conceptDataCursor] < observationPeriodSeqId) {
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
  while (conceptDataCursor < conceptDataObservationPeriodSeqIds.length() && conceptDataObservationPeriodSeqIds[conceptDataCursor] == observationPeriodSeqId) {
    ConceptData conceptData(conceptDataStartDays[conceptDataCursor], conceptDataEndDays[conceptDataCursor], conceptDataConceptIds[conceptDataCursor]);
    nextPerson.conceptDatas -> push_back(conceptData);
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
  return nextPerson;
}
}
}
#endif /* PERSONDATAITERATOR_CPP_ */
