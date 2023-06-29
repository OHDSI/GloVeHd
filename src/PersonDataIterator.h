/*
 * @file PersonDataIterator.h
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

#ifndef PERSONDATAITERATOR_H_
#define PERSONDATAITERATOR_H_

#include <Rcpp.h>
#include "AndromedaTableIterator.h"

using namespace Rcpp;

namespace ohdsi {
namespace glovehd {
struct ConceptData {
  ConceptData(int _startDay, int _endDay, int64_t _conceptId) :
  startDay(_startDay),
  endDay(_endDay),
  conceptId(_conceptId) {
  }
  
  bool operator <(const ConceptData& conceptData) const {
    if (startDay == conceptData.startDay) 
      return conceptId < conceptData.conceptId;
    else 
      return (startDay < conceptData.startDay);
  }
  
  bool operator ==(const ConceptData& conceptData) const {
    // Currently not using end date:
    return (startDay == conceptData.startDay  &&
            conceptId == conceptData.conceptId);
  }
  
  int startDay;
  int endDay;
  int64_t  conceptId;
};

struct PersonData {
  PersonData(String _personId,
             String _observationPeriodId,
             int _observationPeriodSeqId,
             Date _observationPeriodStartDate,
             Date _observationPeriodEndDate) :
  personId(_personId),
  observationPeriodId(_observationPeriodId),
  observationPeriodSeqId(_observationPeriodSeqId),
  observationPeriodStartDate(_observationPeriodStartDate),
  observationPeriodEndDate(_observationPeriodEndDate),
  conceptDatas(0) {
    conceptDatas = new std::vector<ConceptData>;
  }

  ~PersonData() {
    delete conceptDatas;
  }

  std::string personId;
  std::string observationPeriodId;
  int observationPeriodSeqId;
  Date observationPeriodStartDate;
  Date observationPeriodEndDate;
  std::vector<ConceptData>* conceptDatas;
};

class PersonDataIterator {
public:
  PersonDataIterator(const List& _conceptData, const DataFrame& _observationPeriodReference,
                     const DataFrame& _conceptAncestor);
  bool hasNext();
  PersonData next();
private:
  AndromedaTableIterator conceptDataIterator;
  
  CharacterVector personIds;
  CharacterVector observationPeriodIds;
  NumericVector observationPeriodSeqIds;
  DateVector observationPeriodStartDates;
  DateVector observationPeriodEndDates;

  NumericVector conceptDataStartDays;
  NumericVector conceptDataEndDays;
  NumericVector conceptDataConceptIds;
  NumericVector conceptDataObservationPeriodSeqIds;

  int observationPeriodCursor;
  int conceptDataCursor;
  bool rollUpConcepts;
  std::unordered_map<int, std::vector<int>> conceptToAncestors;
  void loadNextConceptDatas();
};
}
}

#endif /* PERSONDATAITERATOR_H_ */
