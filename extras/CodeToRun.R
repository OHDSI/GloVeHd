library(GloVeHd)

options(andromedaTempFolder = "d:/andromedaTemp")
maxCores <- max(24, parallel::detectCores())

# Settings ---------------------------------------------------------------------

# MDCD
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  connectionString = keyring::key_get("redShiftConnectionStringMdcd"),
  user = keyring::key_get("redShiftUserName"),
  password = keyring::key_get("redShiftPassword")
)
cdmDatabaseSchema <- "cdm"
workDatabaseSchema <- "scratch_mschuemi2"
sampleTable <- "glovehd_mdcd"
folder <- "d:/glovehd_MDCD"

# Optum EHR
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  connectionString = keyring::key_get("redShiftConnectionStringOhdaOptumEhr"),
  user = keyring::key_get("temp_user"),
  password = keyring::key_get("temp_password")
)
cdmDatabaseSchema <- "cdm_optum_ehr_v2247"
workDatabaseSchema <- "scratch_mschuemi"
sampleTable <- "glovehd_optum_ehr"
folder <- "d:/glovehd_OptumEhr"

# Data fetch -------------------------------------------------------------------
if (!dir.exists(folder)) {
  dir.create(folder)
}

data <- extractData(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  workDatabaseSchema = workDatabaseSchema,
  sampleTable = sampleTable,
  folder = folder,
  sampleSize = 1e5,
  chunkSize = 25000
) 
Andromeda::saveAndromeda(data, file.path(folder, "Data.zip"))

# Co-occurrence matrix construction --------------------------------------------
data <- Andromeda::loadAndromeda(file.path(folder, "Data.zip"))
matrix <- createMatrix(data)
saveRDS(matrix, file.path(folder, "Matrix.rds"))

# Compute global concept vectors -----------------------------------------------
matrix <- readRDS(file.path(folder, "Matrix.rds"))
conceptVectors <- computeGlobalVectors(matrix, vectorSize = 300, maxCores = maxCores)
saveRDS(conceptVectors, file.path(folder, "ConceptVectors.rds"))

# Get similar concepts ---------------------------------------------------------
conceptVectors <- readRDS(file.path(folder, "ConceptVectors.rds"))
getSimilarConcepts(conceptId = 312327, conceptVectors = conceptVectors, n = 25)
getSimilarConcepts(conceptId = 2005415, conceptVectors = conceptVectors, n = 25)
getSimilarConcepts(conceptId = 1124300, conceptVectors = conceptVectors, n = 25)
