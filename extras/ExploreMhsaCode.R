# Code to explore what the deal is with concept 900000010, which appears to be
# (negative) predictive of everything

# Characteristics of people with and without code ------------------------------
tempCohortTable <- "explore_mhsa_mdcd"
sql <- "
DROP TABLE IF EXISTS @cohort_database_schema.@cohort_table;

SELECT subject_id,
    cohort_start_date,
    cohort_start_date AS cohort_end_date,
    cohort_definition_id
INTO @cohort_database_schema.@cohort_table
FROM (
  SELECT subject_id,
    cohort_start_date,
    cohort_definition_id,
    ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY NEWID()) AS rn
  FROM (
    SELECT observation_period.person_id AS subject_id,
      DATEADD(DAY, 365, observation_period_start_date) AS cohort_start_date,
      CASE WHEN observation_concept_id IS NULL THEN 1 ELSE 2 END AS cohort_definition_id
    FROM @cdm_database_schema.observation_period
    LEFT JOIN @cdm_database_schema.observation
      ON observation_period.person_id = observation.person_id
        AND DATEDIFF(DAY, observation_date, DATEADD(DAY, 365, observation_period_start_date)) <= 30
        AND DATEDIFF(DAY, observation_date, DATEADD(DAY, 365, observation_period_start_date)) >= -30
        AND observation_concept_id = 900000010
    WHERE DATEADD(DAY, 365, observation_period_start_date) <= observation_period_end_date
  ) everyone
) random_order
WHERE rn <= @sample_size;
"
connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(
  connection = connection,
  sql = sql,
  cohort_database_schema = workDatabaseSchema,
  cohort_table = tempCohortTable,
  cdm_database_schema = "cdm",
  sample_size = 10000
)
covSettings <- FeatureExtraction::createDefaultCovariateSettings()
covData <- FeatureExtraction::getDbCovariateData(
  connection = connection,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = workDatabaseSchema,
  cohortTable = tempCohortTable,
  covariateSettings = covSettings,
  aggregated = TRUE
)
FeatureExtraction::saveCovariateData(covData, file.path(folder, "covData.zip"))
DatabaseConnector::disconnect(connection)

covData <- FeatureExtraction::loadCovariateData(file.path(folder, "covData.zip"))
covData0 <- FeatureExtraction::filterByCohortDefinitionId(covData, 1)
covData1 <- FeatureExtraction::filterByCohortDefinitionId(covData, 2)
sdm <- FeatureExtraction::computeStandardizedDifference(covData0, covData1)
attr(covData0, "metaData")
attr(covData1, "metaData")

CohortExplorer::createCohortExplorerApp(
  connection = connection,
  cohortDatabaseSchema = workDatabaseSchema,
  cohortTable = tempCohortTable,
  cdmDatabaseSchema = "cdm",
  cohortDefinitionId = 1,
  sampleSize = 100,
  databaseId = "MDCD",
  exportFolder = "d:/temp/explorerApp2"
)
rstudioapi::openProject("D:/temp/explorerApp2/CohortExplorerShiny")

DatabaseConnector::querySql(connection, "SELECT cohort_definition_id, COUNT(*) FROM scratch_mschuemi2.explore_mhsa_mdcd GROUP BY cohort_definition_id;")

DatabaseConnector::querySql(connection, "SELECT TOP 10 * FROM scratch_mschuemi2.explore_mhsa_mdcd WHERE cohort_definition_id = 1;")
# Exploring cohorts of people without code in history --------------------------
cohortTable <- "glove_prediction_cohorts_mdcd"
sql <- "
DROP TABLE IF EXISTS @cohort_database_schema.@target_cohort_table;

SELECT subject_id,
    cohort_start_date,
    cohort_end_date,
    cohort_definition_id
INTO @cohort_database_schema.@target_cohort_table
FROM @cohort_database_schema.@cohort_table
LEFT JOIN @cdm_database_schema.observation
  ON subject_id = person_id
    AND observation_date >= DATEADD(DAY, -30, cohort_start_date)
    AND observation_date <= cohort_start_date
    AND observation_concept_id = 900000010
WHERE cohort_definition_id = 301
  AND person_id IS NULL;
"
connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(
  connection = connection,
  sql = sql,
  cohort_database_schema = workDatabaseSchema,
  cohort_table = cohortTable,
  target_cohort_table = tempCohortTable,
  cdm_database_schema = "cdm"
)
CohortExplorer::createCohortExplorerApp(
  connection = connection,
  cohortDatabaseSchema = workDatabaseSchema,
  cohortTable = tempCohortTable,
  cdmDatabaseSchema = "cdm",
  cohortDefinitionId = 301,
  sampleSize = 100,
  databaseId = "MDCD",
  exportFolder = "d:/temp/explorerApp"
)

DatabaseConnector::disconnect(connection)

# Exploring cohorts of people without code in history and with lung cancer -----
cohortTable <- "glove_prediction_cohorts_mdcd"
sql <- "
DROP TABLE IF EXISTS @cohort_database_schema.@target_cohort_table;

SELECT target_cohort.subject_id,
    target_cohort.cohort_start_date,
    target_cohort.cohort_end_date,
    target_cohort.cohort_definition_id
INTO @cohort_database_schema.@target_cohort_table
FROM @cohort_database_schema.@cohort_table target_cohort
INNER JOIN @cohort_database_schema.@cohort_table outcome_cohort
  ON target_cohort.subject_id = outcome_cohort.subject_id
    AND outcome_cohort.cohort_start_date > target_cohort.cohort_start_date
    AND outcome_cohort.cohort_start_date <= DATEADD(DAY, 1095, target_cohort.cohort_start_date)
LEFT JOIN @cdm_database_schema.observation
  ON target_cohort.subject_id = person_id
    AND observation_date >= DATEADD(DAY, -30, target_cohort.cohort_start_date)
    AND observation_date <= target_cohort.cohort_start_date
    AND observation_concept_id = 900000010
WHERE target_cohort.cohort_definition_id = 301
  AND outcome_cohort.cohort_definition_id = 298
  AND person_id IS NULL;
"
connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(
  connection = connection,
  sql = sql,
  cohort_database_schema = workDatabaseSchema,
  cohort_table = cohortTable,
  target_cohort_table = tempCohortTable,
  cdm_database_schema = "cdm"
)
CohortExplorer::createCohortExplorerApp(
  connection = connection,
  cohortDatabaseSchema = workDatabaseSchema,
  cohortTable = tempCohortTable,
  cdmDatabaseSchema = "cdm",
  cohortDefinitionId = 301,
  sampleSize = 100,
  databaseId = "MDCD",
  exportFolder = "d:/temp/explorerApp"
)
renderTranslateQuerySql(
  connection = connection,
  sql = "SELECT COUNT(*) FROM @cohort_database_schema.@target_cohort_table;",
  cohort_database_schema = workDatabaseSchema,
  target_cohort_table = tempCohortTable
)
DatabaseConnector::disconnect(connection)
