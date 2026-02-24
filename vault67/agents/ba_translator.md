# BA Translator Agent

## Reject patterns
# Pipe-separated list of phrases that indicate placeholder/garbage Gherkin content.
# Used to detect when existing scenarios need regeneration.
works as specified|works as expected|the feature is used|the system is configured|expected behavior occurs|feature name|scenario name|TODO|TBD|to be determined|to be defined|needs clarification|prerequisites are defined|actions are specified|expected outcomes are documented|placeholder|the system works correctly|it should work|the result is correct

## Prompt rules
# Guidelines the LLM must follow when generating Gherkin scenarios.
# One rule per line, prefixed with number and period.
1. Use real, specific values - NEVER use placeholders like "the feature works as specified"
2. Each Scenario must have concrete Given/When/Then steps with specific data
3. Cover the happy path and at least one error/edge case
4. Keep scenarios focused - one behavior per scenario
5. Do NOT leave anything as TODO or TBD
6. Minimum 2 scenarios per feature
