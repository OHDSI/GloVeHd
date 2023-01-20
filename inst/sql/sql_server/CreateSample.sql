{DEFAULT @sample_size = 100000}
{DEFAULT @chunk_size = 25000}

DROP TABLE IF EXISTS @work_database_schema.@sample_table;

SELECT observation_period_id,
	rn AS observation_period_seq_id,
	CEILING(CAST(rn AS FLOAT) / @chunk_size) AS chunk_id
INTO @work_database_schema.@sample_table
FROM (
	SELECT observation_period_id,
		ROW_NUMBER() OVER (ORDER BY NEWID()) AS rn
	FROM @cdm_database_schema.observation_period
	) tmp
WHERE rn <= @sample_size;