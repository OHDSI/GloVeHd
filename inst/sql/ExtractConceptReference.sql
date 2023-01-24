SELECT concept.concept_id,
	concept_name,
	domain_id
FROM @cdm_database_schema.concept
INNER JOIN #concept_ids concept_ids
	ON concept.concept_id = concept_ids.concept_id;