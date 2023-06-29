
library(dplyr)
counts <- data$conceptData %>%
  group_by(conceptId) %>%
  summarize(conceptCount = n()) %>%
  ungroup()
ancestorCounts <- counts %>%
  inner_join(data$conceptAncestor, by = join_by(conceptId == descendantConceptId)) %>%
  group_by(ancestorConceptId) %>%
  summarize(conceptCount = sum(conceptCount, na.rm = TRUE)) %>%
  collect()

topAncestors <- ancestorCounts %>% 
  inner_join(data$conceptReference, by = join_by(ancestorConceptId == conceptId), copy = TRUE) %>%
  filter(verbatim == 0) %>%
  arrange(desc(conceptCount)) %>%
  head(1000)

rubbishPattern <- paste("finding$", 
                        "^Disorder of",
                        "^Finding of", 
                        "^Disease of",
                        "^Injury of",
                        "disorder$",
                        "by site$",
                        "by anatomical site$",
                        "by body site$",
                        "by mechanism$",
                        "body region$",
                        "specific body structure$",
                        "^Procedure",
                        "procedure$",
                        "procedures$",
                        "Procedures$",
                        "Services$",
                        "system$",
                        "Concept$",
                        "Product$",
                        "Medicine$",
                        "^Pill$",
                        "^Measurement$",
                        "^Regimes and therapies$",
                        "^Imaging$",
                        "^Care regime$",
                        "^Removal$",
                        "^Therapy$",
                        sep = "|")
removed <- topAncestors[grepl(rubbishPattern, topAncestors$conceptName), ]
remaining <- topAncestors[!grepl(rubbishPattern, topAncestors$conceptName), ]
sum(removed$conceptCount)
sum(remaining$conceptCount)

data$conceptAncestor %>%
  filter(descendantConceptId == 4180938)

ancestors <- data$conceptAncestor %>%
  distinct(ancestorConceptId) %>%
  pull()
descendants <- data$conceptAncestor %>%
  distinct(descendantConceptId) %>%
  pull()
ancestorless <- ancestors[!ancestors %in% descendants]
x <- data$conceptReference %>%
  filter(conceptId %in% ancestorless) %>%
  collect()

