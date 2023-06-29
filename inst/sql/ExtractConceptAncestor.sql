SELECT ancestor_concept_id,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
INNER JOIN #concept_ids concept_ids
	ON descendant_concept_id = concept_ids.concept_id;