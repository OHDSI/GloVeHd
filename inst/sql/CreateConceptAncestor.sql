SELECT ancestor_concept_id,
	descendant_concept_id
INTO #concept_ancestor
FROM @cdm_database_schema.concept_ancestor
INNER JOIN @cdm_database_schema.concept descendant
	ON descendant_concept_id = descendant.concept_id
INNER JOIN @cdm_database_schema.concept ancestor
	ON ancestor_concept_id = ancestor.concept_id
INNER JOIN #concept_ids concept_ids
	ON descendant_concept_id = concept_ids.concept_id
WHERE descendant.domain_id != 'Drug' 
	OR ancestor.concept_class_id = 'Ingredient' 
	OR ancestor.vocabulary_id = 'ATC';