conceptVectors <- readRDS("D:/glovehd_MDCD/ConceptVectors.rds")

conceptReference <- attr(conceptVectors, "conceptReference")

autoCompleteList <- sprintf("%s (%s)", conceptReference$conceptName, conceptReference$conceptId)
