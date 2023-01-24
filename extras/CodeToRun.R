library(InteractionsEval)

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

extractData(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  workDatabaseSchema = workDatabaseSchema,
  sampleTable = sampleTable,
  folder = folder,
  sampleSize = 1e5,
  chunkSize = 2500
) 


# andromeda <- Andromeda::loadAndromeda(file.path(folder, "Data.zip"))
# dplyr::count(andromeda$conceptData)