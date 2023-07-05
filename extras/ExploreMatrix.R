# Code for checking if the concept co-occurrence matrix was constructed correctlylibrary(GloVeHd)
library(dplyr)
options(andromedaTempFolder = "d:/andromedaTemp")
folder <- "d:/glovehd_MDCD"
matrix <- readRDS(file.path(folder, "Matrix.rds"))
conceptReference <- attr(matrix, "conceptReference")

getVector <- function(conceptId) {
  row <- matrix[which(conceptReference$conceptId == conceptId), ]
  row <- row[row != 0]
  row <- row[order(-row)]
  row <- row[1:100]
  row <- tibble(conceptId = as.numeric(names(row)),
                value = row)
  row <- row %>%
    inner_join(conceptReference, by = join_by(conceptId))
  return(row)
}
x <- getVector(312327)
View(x)
x <- getVector(2005415)
View(x)
