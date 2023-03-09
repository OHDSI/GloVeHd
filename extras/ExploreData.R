# Code to explore data in general

# Characteristics of people with and without code ------------------------------
cohortTable <- "temp_cohort"
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
    ROW_NUMBER() OVER (ORDER BY NEWID()) AS rn
  FROM (
    SELECT person_id AS subject_id,
      DATEADD(DAY, 365, observation_period_start_date) AS cohort_start_date,
      CAST(1 AS INT) AS cohort_definition_id
    FROM @cdm_database_schema.observation_period
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
  cohort_table = cohortTable,
  cdm_database_schema = cdmDatabaseSchema,
  sample_size = 1000
)

CohortExplorer::createCohortExplorerApp(
  connection = connection,
  cohortDatabaseSchema = workDatabaseSchema,
  cohortTable = cohortTable,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDefinitionId = 1,
  sampleSize = 100,
  databaseId = "CPRD",
  exportFolder = "d:/temp/explorerAppCprd"
)

DatabaseConnector::disconnect(connection)
# usethis::create_project("d:/temp/explorerAppOptumEhr/CohortExplorerShiny")

shiny::runApp("d:/temp/explorerAppOptumEhr/CohortExplorerShiny")

sql <- "SELECT TOP 10 * 
FROM @cohort_database_schema.@cohort_table
INNER JOIN @cdm_database_schema.observation_period
  ON subject_id = person_id
    AND cohort_start_date >= observation_period_start_date
    AND cohort_start_date <= observation_period_end_date;
"
rows <- DatabaseConnector::renderTranslateQuerySql(
  connection = connection,
  sql = sql,
  cohort_database_schema = workDatabaseSchema,
  cohort_table = cohortTable,
  cdm_database_schema = cdmDatabaseSchema,
  integer64AsNumeric = FALSE
)
View(rows)

DatabaseConnector::executeSql(connection, "COMMIT;")
