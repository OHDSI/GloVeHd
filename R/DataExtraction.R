# Copyright 2023 Observational Health Data Sciences and Informatics
#
# This file is part of GloVeHd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# library(dplyr)

#' Extract data from the database
#' 
#' @description 
#' Extract data from the server for a random sample of observation periods, and stores them 
#' in the local file system.
#' 
#' 
#' @param connectionDetails            An R object of type `connectionDetails` created using the
#'                                     [DatabaseConnector::createConnectionDetails()] function.
#' @param cdmDatabaseSchema            The name of the database schema that contains the OMOP CDM
#'                                     instance. Requires read permissions to this database. On SQL
#'                                     Server, this should specify both the database and the schema,
#'                                     so for example 'cdm_instance.dbo'.
#' @param workDatabaseSchema           The name of the database schema where work tables can be created.
#' @param sampleTable                  The name of the table where the sampled observation period IDs 
#'                                     will be stored.
#' @param sampleSize                   The number of observation periods to be included in the sample.
#' @param chunkSize                    The number of observation periods in a chunk. Larger chunk sizes
#'                                     will be faster, but may lead to memory issues on the server.
#'                                     
#' @export
extractData <- function(connectionDetails,
                        cdmDatabaseSchema,
                        workDatabaseSchema,
                        sampleTable = "glovehd_sample",
                        sampleSize = 1e6,
                        chunkSize = 25000) {
  errorMessages <- checkmate::makeAssertCollection()
  checkmate::assertClass(connectionDetails, "ConnectionDetails", add = errorMessages)
  checkmate::assertCharacter(cdmDatabaseSchema, len = 1, add = errorMessages)
  checkmate::assertCharacter(workDatabaseSchema, len = 1, add = errorMessages)
  checkmate::assertCharacter(sampleTable, len = 1, add = errorMessages)
  checkmate::assertInt(sampleSize, lower = 0, add = errorMessages)
  checkmate::assertInt(chunkSize, lower = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)
  DatabaseConnector::assertTempEmulationSchemaSet(connectionDetails$dbms)
  
  startTime <- Sys.time()

  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  
  message("Taking sample")
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "CreateSample.sql",
    packageName = "GloVeHd",
    dbms = connectionDetails$dbms,
    cdm_database_schema = cdmDatabaseSchema,
    work_database_schema = workDatabaseSchema,
    sample_table = sampleTable,
    sample_size = sampleSize,
    chunk_size = chunkSize
  )
  DatabaseConnector::executeSql(connection, sql, reportOverallTime = FALSE)
  
  sql <- "SELECT MAX(chunk_id) AS value FROM @work_database_schema.@sample_table;"
  numberOfChunks <- DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = sql,
    work_database_schema = workDatabaseSchema,
    sample_table = sampleTable
  )[1, 1]
  message("Fetching person concept data")
  andromeda <- Andromeda::andromeda()
  pb <- txtProgressBar(style = 3)
  for (i in seq_len(numberOfChunks)) {
    sql <- SqlRender::loadRenderTranslateSql(
      sqlFilename = "CreateChunkTempTable.sql",
      packageName = "GloVeHd",
      dbms = connectionDetails$dbms,
      cdm_database_schema = cdmDatabaseSchema,
      work_database_schema = workDatabaseSchema,
      sample_table = sampleTable,
      chunk_id = i
    )
    DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    
    sql <- SqlRender::loadRenderTranslateSql(
      sqlFilename = "ExtractConceptData.sql",
      packageName = "GloVeHd",
      dbms = connectionDetails$dbms,
      cdm_database_schema = cdmDatabaseSchema
    )
    DatabaseConnector::querySqlToAndromeda(
      connection = connection,
      sql = sql,
      andromeda = andromeda,
      andromedaTableName = "conceptData",
      snakeCaseToCamelCase = TRUE,
      appendToTable = (i != 1)
    )
    
    sql <- "DROP TABLE #sample_chunk;"
    DatabaseConnector::renderTranslateExecuteSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    setTxtProgressBar(pb, i / numberOfChunks)
  }
  close(pb)
  message("Fetching concept reference")
  conceptIds <- andromeda$conceptData %>%
    distinct(.data$conceptId) %>%
    collect()
  DatabaseConnector::insertTable(
    connection = connection,
    tableName = "#concept_ids",
    data = conceptIds,
    dropTableIfExists = TRUE,
    tempTable = TRUE,
    camelCaseToSnakeCase = TRUE
  )
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "CreateConceptAncestor.sql",
    packageName = "GloVeHd",
    dbms = connectionDetails$dbms,
    cdm_database_schema = cdmDatabaseSchema
  )
  DatabaseConnector::executeSql(connection = connection, sql = sql)
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "ExtractConceptAncestor.sql",
    packageName = "GloVeHd",
    dbms = connectionDetails$dbms
  )
  DatabaseConnector::querySqlToAndromeda(
    connection = connection,
    sql = sql,
    andromeda = andromeda,
    andromedaTableName = "conceptAncestor",
    snakeCaseToCamelCase = TRUE
  )
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "ExtractConceptReference.sql",
    packageName = "GloVeHd",
    dbms = connectionDetails$dbms,
    cdm_database_schema = cdmDatabaseSchema
  )
  DatabaseConnector::querySqlToAndromeda(
    connection = connection,
    sql = sql,
    andromeda = andromeda,
    andromedaTableName = "conceptReference",
    snakeCaseToCamelCase = TRUE
  )
  sql <- "DROP TABLE #concept_ids; DROP TABLE #concept_ancestor;"
  DatabaseConnector::renderTranslateExecuteSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  
  message("Fetching observation period reference")
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "ExtractObservationPeriodReference.sql",
    packageName = "GloVeHd",
    dbms = connectionDetails$dbms,
    cdm_database_schema = cdmDatabaseSchema,
    work_database_schema = workDatabaseSchema,
    sample_table = sampleTable
  )
  DatabaseConnector::querySqlToAndromeda(
    connection = connection,
    sql = sql,
    andromeda = andromeda,
    andromedaTableName = "observationPeriodReference",
    snakeCaseToCamelCase = TRUE
  )
  
  delta <- Sys.time() - startTime
  message(paste("Extracting data took", signif(delta, 3), attr(delta, "units")))
  return(andromeda)
}