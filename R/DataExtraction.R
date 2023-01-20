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
#' @param folder                       Path to a folder in the local file system where the data will
#'                                     be written.
#' @param sampleSize                   The number of observation periods to be included in the sample.
#' @param chunkSize                    The number of observation periods in a chunk. Larger chunk sizes
#'                                     will be faster, but may lead to memory issues on the server.
#'                                     
#' @export
extractData <- function(connectionDetails,
                        cdmDatabaseSchema,
                        workDatabaseSchema,
                        sampleTable = "glovehd_sample",
                        folder,
                        sampleSize = 10000,
                        chunkSize = 2500) {
  errorMessages <- checkmate::makeAssertCollection()
  checkmate::assertClass(connectionDetails, "ConnectionDetails", add = errorMessages)
  checkmate::assertCharacter(cdmDatabaseSchema, len = 1, add = errorMessages)
  checkmate::assertCharacter(workDatabaseSchema, len = 1, add = errorMessages)
  checkmate::assertCharacter(sampleTable, len = 1, add = errorMessages)
  checkmate::assertCharacter(folder, len = 1, add = errorMessages)
  checkmate::assertInt(sampleSize, lower = 0, add = errorMessages)
  checkmate::assertInt(chunkSize, lower = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)
  DatabaseConnector::assertTempEmulationSchemaSet(connectionDetails$dbms)
  
  if (!dir.exists(folder)) {
    dir.create(folder)
  }
  
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
  DatabaseConnector::executeSql(connection, sql)
  
  sql <- "SELECT MAX(chunk_id) AS value FROM @work_database_schema.@sample_table;"
  numberOfChunks <- DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = sql,
    work_database_schema = workDatabaseSchema,
    sample_table = sampleTable
  )[1, 1]
  
  for (i in seq_len(numberOfChunks)) {
    message(sprintf("- Fetching chunk %d of %d", i, numberOfChunks))
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
    
    andromeda <- Andromeda::andromeda()
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
      snakeCaseToCamelCase = TRUE
      # integerAsNumeric = FALSE
    )
    
    Andromeda::saveAndromeda(andromeda, file.path(folder, sprintf("Data_%d.zip", i)))
    sql <- "DROP TABLE #sample_chunk;"
    DatabaseConnector::renderTranslateExecuteSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  }

}