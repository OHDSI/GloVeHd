DROP TABLE IF EXISTS #sample_chunk;

SELECT person_id,
	observation_period.observation_period_id,
	observation_period_seq_id,
	observation_period_start_date,
	observation_period_end_date
INTO #sample_chunk
FROM @work_database_schema.@sample_table sample_table
INNER JOIN @cdm_database_schema.observation_period
	ON sample_table.observation_period_id = observation_period.observation_period_id
WHERE chunk_id = @chunk_id;