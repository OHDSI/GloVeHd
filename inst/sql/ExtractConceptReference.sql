SELECT concept.concept_id,
	concept_name,
	domain_id,
	CASE
		WHEN concept_ids.concept_id IS NULL THEN 0
		ELSE 1
	END AS verbatim
FROM @cdm_database_schema.concept
INNER JOIN (
	SELECT DISTINCT ancestor_concept_id 
	FROM #concept_ancestor
	) ancestor_concept_ids
	ON concept.concept_id = ancestor_concept_id
LEFT JOIN #concept_ids concept_ids
	ON concept.concept_id = concept_ids.concept_id