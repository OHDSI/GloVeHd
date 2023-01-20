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
) tmp;		

	

 