library(InteractionsEval)

options(andromedaTempFolder = "d:/andromedaTemp")
maxCores <- max(24, parallel::detectCores())

# MDCD
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "redshift",
                                                                connectionString = keyring::key_get("redShiftConnectionStringMdcd"),
                                                                user = keyring::key_get("redShiftUserName"),
                                                                password = keyring::key_get("redShiftPassword"))
cdmDatabaseSchema <- "cdm"
workDatabaseSchema <- "scratch_mschuemi2"
sampleTable <- "glovehd_mdcd"
folder <- "d:/glovehd_MDCD"

# Optum EHR
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "redshift",
                                                                connectionString = keyring::key_get("redShiftConnectionStringOhdaOptumEhr"),
                                                                user = keyring::key_get("temp_user"),
                                                                password = keyring::key_get("temp_password"))
cdmDatabaseSchema <- "cdm_optum_ehr_v2247"
workDatabaseSchema <- "scratch_mschuemi"
sampleTable <- "glovehd_optum_ehr"
folder <- "d:/glovehd_OptumEhr"
