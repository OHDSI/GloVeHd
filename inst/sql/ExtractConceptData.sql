SELECT observation_period_seq_id,
	concept_id,
	start_day,
	end_day
FROM (
	SELECT observation_period_seq_id,
		visit_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, visit_start_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, visit_end_date) AS end_day
	FROM @cdm_database_schema.visit_occurrence
	INNER JOIN #sample_chunk sample_chunk
		ON visit_occurrence.person_id = sample_chunk.person_id
			AND visit_start_date >= observation_period_start_date
			AND visit_start_date <= observation_period_end_date
	WHERE visit_concept_id != 0
			
	UNION ALL

	SELECT observation_period_seq_id,
		condition_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, condition_start_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, condition_end_date) AS end_day
	FROM @cdm_database_schema.condition_occurrence
	INNER JOIN #sample_chunk sample_chunk
		ON condition_occurrence.person_id = sample_chunk.person_id
			AND condition_start_date >= observation_period_start_date
			AND condition_start_date <= observation_period_end_date
	WHERE condition_concept_id != 0
	
	UNION ALL

	SELECT observation_period_seq_id,
		drug_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, drug_exposure_start_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, drug_exposure_end_date) AS end_day
	FROM @cdm_database_schema.drug_exposure
	INNER JOIN #sample_chunk sample_chunk
		ON drug_exposure.person_id = sample_chunk.person_id
			AND drug_exposure_start_date >= observation_period_start_date
			AND drug_exposure_start_date <= observation_period_end_date
	WHERE drug_concept_id != 0
	
	UNION ALL

	SELECT observation_period_seq_id,
		procedure_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, procedure_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, procedure_date) AS end_day
	FROM @cdm_database_schema.procedure_occurrence
	INNER JOIN #sample_chunk sample_chunk
		ON procedure_occurrence.person_id = sample_chunk.person_id
			AND procedure_date >= observation_period_start_date
			AND procedure_date <= observation_period_end_date
	WHERE procedure_concept_id != 0
	
	UNION ALL

	SELECT observation_period_seq_id,
		device_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, device_exposure_start_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, device_exposure_end_date) AS end_day
	FROM @cdm_database_schema.device_exposure
	INNER JOIN #sample_chunk sample_chunk
		ON device_exposure.person_id = sample_chunk.person_id
			AND device_exposure_start_date >= observation_period_start_date
			AND device_exposure_start_date <= observation_period_end_date
	WHERE device_concept_id != 0
	
	UNION ALL

	SELECT observation_period_seq_id,
		measurement_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, measurement_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, measurement_date) AS end_day
	FROM @cdm_database_schema.measurement
	INNER JOIN #sample_chunk sample_chunk
		ON measurement.person_id = sample_chunk.person_id
			AND measurement_date >= observation_period_start_date
			AND measurement_date <= observation_period_end_date
	WHERE measurement_concept_id != 0
	
	UNION ALL

	SELECT observation_period_seq_id,
		observation_concept_id AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, observation_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, observation_date) AS end_day
	FROM @cdm_database_schema.observation
	INNER JOIN #sample_chunk sample_chunk
		ON observation.person_id = sample_chunk.person_id
			AND observation_date >= observation_period_start_date
			AND observation_date <= observation_period_end_date
	WHERE observation_concept_id != 0
	
	UNION ALL

	SELECT observation_period_seq_id,
		CAST(4306655 AS INT) AS concept_id,
		DATEDIFF(DAY, observation_period_start_date, death_date) AS start_day,
		DATEDIFF(DAY, observation_period_start_date, death_date) AS end_day
	FROM @cdm_database_schema.death
	INNER JOIN #sample_chunk sample_chunk
		ON death.person_id = sample_chunk.person_id
			AND death_date >= observation_period_start_date
			AND death_date <= observation_period_end_date
) tmp;		

	

 