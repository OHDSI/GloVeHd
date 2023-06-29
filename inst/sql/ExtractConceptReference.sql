SELECT concept.concept_id,
	concept_name,
	domain_id,
	CASE
		WHEN concept_ids.concept_id IS NULL THEN 0
		ELSE 1
	END AS verbatim
FROM @cdm_database_schema.concept
INNER JOIN (
	SELECT DISTINCT ancestor_concept_id AS concept_id
	FROM @cdm_database_schema.concept_ancestor
	INNER JOIN #concept_ids concept_ids
		ON descendant_concept_id = concept_ids.concept_id
	) all_concept_ids
	ON concept.concept_id = all_concept_ids.concept_id
LEFT JOIN #concept_ids concept_ids
	ON concept.concept_id = concept_ids.concept_id;