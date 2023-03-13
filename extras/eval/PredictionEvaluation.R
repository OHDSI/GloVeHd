# Code for evaluating GloVe in the context of 3 patient-level prediction problems

targetId1 <- 301    # People aged 45-65 with a visit in 2013, no prior cancer
outcomeId1 <- 298   # Lung cancer
targetId2 <- 10460  # People aged 10- with major depressive disorder
outcomeId2 <- 10461 # Bipolar disorder
targetId3 <- 9938   # People aged 55=85 with a visit in 2012-2014, no prior dementia
outcomeId3 <- 6243  # Dementia

# MDCD
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  connectionString = keyring::key_get("redShiftConnectionStringOhdaMdcd"),
  user = keyring::key_get("redShiftUserName"),
  password = keyring::key_get("redShiftPassword")
)
cdmDatabaseSchema <- "cdm_truven_mdcd_v2321"
cohortDatabaseSchema <- "scratch_mschuemi"
cohortTable <- "glove_prediction_cohorts_mdcd"
folder <- "d:/glovehd_MDCD"

# Optum EHR
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  connectionString = keyring::key_get("redShiftConnectionStringOhdaOptumEhr"),
  user = keyring::key_get("temp_user"),
  password = keyring::key_get("temp_password")
)
cdmDatabaseSchema <- "cdm_optum_ehr_v2247"
cohortDatabaseSchema <- "scratch_mschuemi"
cohortTable <- "glove_prediction_cohorts_optum_ehr"
folder <- "d:/glovehd_OptumEhr"

# Get cohort definitions -------------------------------------------------------
ROhdsiWebApi::authorizeWebApi(
  baseUrl = Sys.getenv("baseUrl"),
  authMethod = "windows")
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  cohortIds = c(targetId1, outcomeId1, targetId2, outcomeId2, targetId3, outcomeId3),
  generateStats = TRUE,
  baseUrl =Sys.getenv("baseUrl")
)
saveRDS(cohortDefinitionSet, "extras/eval/cohortDefinitionSet.rds")

# Generate cohorts -------------------------------------------------------------
cohortDefinitionSet <- readRDS("extras/eval/cohortDefinitionSet.rds")
connection <- DatabaseConnector::connect(connectionDetails)
cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable)
CohortGenerator::createCohortTables(
  connection = connection,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames
)
CohortGenerator::generateCohortSet(
  connection = connection,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames,
  cohortDefinitionSet = cohortDefinitionSet
)
DatabaseConnector::disconnect(connection)

# Run prediction ---------------------------------------------------------------
restrictPlpDataSettings1 <- PatientLevelPrediction::createRestrictPlpDataSettings(
  sampleSize = 100000
)
restrictPlpDataSettings2 <- PatientLevelPrediction::createRestrictPlpDataSettings(
  sampleSize = 10000
)
populationSettings1 = PatientLevelPrediction::createStudyPopulationSettings(
  washoutPeriod = 365,
  riskWindowStart = 1,
  startAnchor = "cohort start",
  riskWindowEnd = 1095,
  endAnchor = "cohort start",
  removeSubjectsWithPriorOutcome = TRUE,
  priorOutcomeLookback = 999999,
  requireTimeAtRisk = FALSE
)
populationSettings2 = PatientLevelPrediction::createStudyPopulationSettings(
  washoutPeriod = 365,
  riskWindowStart = 2,
  startAnchor = "cohort start",
  riskWindowEnd = 365,
  endAnchor = "cohort start",
  removeSubjectsWithPriorOutcome = TRUE,
  priorOutcomeLookback = 999999,
  requireTimeAtRisk = FALSE
)
demographicsCovariateSettings <- FeatureExtraction::createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAgeGroup = TRUE,
  useDemographicsRace = TRUE,
  useDemographicsEthnicity = TRUE
)
baseCovariateSettings <- GloVeHd::createBaseCovariateSettings(type = "binary")
conceptVectors <- readRDS(file.path(folder, "ConceptVectors.rds"))
gloVeCovariateSettings <- GloVeHd::createGloVeCovariateSettings(
  baseCovariateSettings = baseCovariateSettings,
  conceptVectors = conceptVectors
)
defaultCovariateSettings <- FeatureExtraction::createDefaultCovariateSettings()
defaultCovariateSettings$DemographicsIndexYear <- FALSE
defaultCovariateSettings$DemographicsIndexMonth <- FALSE
modelSettings <- PatientLevelPrediction::setLassoLogisticRegression()
modelDesign1 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId1,
  outcomeId = outcomeId1,
  populationSettings = populationSettings1,
  restrictPlpDataSettings = restrictPlpDataSettings1,
  covariateSettings = list(baseCovariateSettings, demographicsCovariateSettings),
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign2 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId1,
  outcomeId = outcomeId1,
  populationSettings = populationSettings1,
  restrictPlpDataSettings = restrictPlpDataSettings1,
  covariateSettings = list(gloVeCovariateSettings, demographicsCovariateSettings),
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(normalize = FALSE),
  modelSettings = modelSettings
)
modelDesign3 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId1,
  outcomeId = outcomeId1,
  populationSettings = populationSettings1,
  restrictPlpDataSettings = restrictPlpDataSettings1,
  covariateSettings = defaultCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign4 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId1,
  outcomeId = outcomeId1,
  populationSettings = populationSettings1,
  restrictPlpDataSettings = restrictPlpDataSettings1,
  covariateSettings = demographicsCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign5 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId2,
  outcomeId = outcomeId2,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = list(baseCovariateSettings, demographicsCovariateSettings),
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign6 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId2,
  outcomeId = outcomeId2,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = list(gloVeCovariateSettings, demographicsCovariateSettings),
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(normalize = FALSE),
  modelSettings = modelSettings
)
modelDesign7 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId2,
  outcomeId = outcomeId2,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = defaultCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign8 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId2,
  outcomeId = outcomeId2,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = demographicsCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign9 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId3,
  outcomeId = outcomeId3,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = list(baseCovariateSettings, demographicsCovariateSettings),
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign10 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId3,
  outcomeId = outcomeId3,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = list(gloVeCovariateSettings, demographicsCovariateSettings),
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(normalize = FALSE),
  modelSettings = modelSettings
)
modelDesign11 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId3,
  outcomeId = outcomeId3,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = defaultCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign12 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId3,
  outcomeId = outcomeId3,
  populationSettings = populationSettings2,
  restrictPlpDataSettings = restrictPlpDataSettings2,
  covariateSettings = demographicsCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)

modelDesignList <- list(
  modelDesign1, 
  modelDesign2, 
  modelDesign3, 
  modelDesign4, 
  modelDesign5, 
  modelDesign6, 
  modelDesign7, 
  modelDesign8, 
  modelDesign9,
  modelDesign10, 
  modelDesign11, 
  modelDesign12
)
databaseDetails <- PatientLevelPrediction::createDatabaseDetails(
  connectionDetails = connectionDetails, 
  cdmDatabaseSchema = cdmDatabaseSchema, 
  cdmDatabaseName = cdmDatabaseSchema, 
  cdmDatabaseId = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema, 
  cohortTable = cohortTable, 
  outcomeDatabaseSchema = cohortDatabaseSchema, 
  outcomeTable = cohortTable
)
ParallelLogger::addDefaultFileLogger(
  fileName = file.path(folder, "Plp", "log.txt"), 
  name = "PLPLOG"
)
results <- PatientLevelPrediction::runMultiplePlp(
  databaseDetails = databaseDetails, 
  modelDesignList = modelDesignList,
  saveDirectory = file.path(folder, "Plp")
)
ParallelLogger::unregisterLogger("PLPLOG")

# View results ----------------------------------------------------------------
PatientLevelPrediction::viewMultiplePlp(file.path(folder, "Plp"))

library(dplyr)
getStats <- function(analysisId) {
  runPlp <- readRDS(file.path(folder, "Plp", sprintf("Analysis_%d", analysisId), "plpResult", "runPlp.rds"))
  return(tibble(
    trainPopulationSize = as.numeric(runPlp$performanceEvaluation$evaluationStatistics$value[[20]]),
    trainOutcomeCount = as.numeric(runPlp$performanceEvaluation$evaluationStatistics$value[[21]]),
    testAUC = as.numeric(runPlp$performanceEvaluation$evaluationStatistics$value[[3]]),
    testBrierScore = as.numeric(runPlp$performanceEvaluation$evaluationStatistics$value[[7]])
  ))
}


results <- tibble(
  outcome = rep(c("Lung cancer", "Bipolar disorder", "Dementia"), each = 4),
  covariates = rep(c("Verbatim concepts + demographics", "GloVe + demographics", "FeatureExtraction default", "Demographics"), 3)
)

stats <- lapply(1:12, getStats)
stats <- bind_rows(stats)
results <- bind_cols(results, stats)
readr::write_csv(results, file.path(folder, "Results.csv"))

baseCovariateData <- FeatureExtraction::loadCovariateData(file.path(folder, "Plp", "targetId_301_L1", "covariates"))
covariateData <- FeatureExtraction::loadCovariateData(file.path(folder, "Plp", "targetId_301_L2", "covariates"))



sum(as.numeric(rownames(conceptVectors)) == 900000010)
