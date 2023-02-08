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
  connectionString = keyring::key_get("redShiftConnectionStringMdcd"),
  user = keyring::key_get("redShiftUserName"),
  password = keyring::key_get("redShiftPassword")
)
cdmDatabaseSchema <- "cdm"
cohortDatabaseSchema <- "scratch_mschuemi2"
cohortTable <- "glove_prediction_cohorts_mdcd"
folder <- "d:/glovehd_MDCD"

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
restrictPlpDataSettings <- PatientLevelPrediction::createRestrictPlpDataSettings(
  sampleSize = 100000
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
baseCovariateSettings <- GloVeHd::createBaseCovariateSettings(type = "binary")
conceptVectors <- readRDS(file.path(folder, "ConceptVectors.rds"))
gloVeCovariateSettings <- createGloVeCovariateSettings(
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
  restrictPlpDataSettings = restrictPlpDataSettings,
  covariateSettings = baseCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesign2 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId1,
  outcomeId = outcomeId1,
  restrictPlpDataSettings = restrictPlpDataSettings,
  covariateSettings = gloVeCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(normalize = FALSE),
  modelSettings = modelSettings
)
modelDesign3 <- PatientLevelPrediction::createModelDesign(
  targetId = targetId1,
  outcomeId = outcomeId1,
  restrictPlpDataSettings = restrictPlpDataSettings,
  covariateSettings = defaultCovariateSettings,
  preprocessSettings = PatientLevelPrediction::createPreprocessSettings(),
  modelSettings = modelSettings
)
modelDesignList <- list(modelDesign1, modelDesign2, modelDesign3)
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

PatientLevelPrediction::viewMultiplePlp(file.path(folder, "Plp"))

runPlp <- readRDS(file.path(folder, "Plp", "Analysis_1", "plpResult", "runPlp.rds"))
runPlp$performanceEvaluation$evaluationStatistics

runPlp <- readRDS(file.path(folder, "Plp", "Analysis_2", "plpResult", "runPlp.rds"))
runPlp$performanceEvaluation$evaluationStatistics

runPlp <- readRDS(file.path(folder, "Plp", "Analysis_3", "plpResult", "runPlp.rds"))
runPlp$performanceEvaluation$evaluationStatistics

# baseCovariateData <- FeatureExtraction::loadCovariateData(file.path(folder, "Plp", "targetId_301_L1", "covariates"))



