Phase 2 of 6: data.

Read CLAUDE.md, PLAN.md, DECISIONS.md and LOG.md, and data/wrds/FETCH_LOG.md if it exists. If an
earlier attempt at this phase started the work, continue from where it stopped (LOG.md and git log
tell you where).

1. Build the analysis dataset with numbered scripts in code/. Download public data with scripts.
2. For WRDS data, write a new data/wrds-queries-NN.sql (see CLAUDE.md) and end the phase without
   creating .phase-done; you will be restarted once the data has arrived. If FETCH_LOG.md reports a
   failed query, fix it in a new query file.
3. Print and save an attrition table at every stage of the build.
4. Save the final dataset(s) in data/clean/, with a short codebook in data/clean/README.md.
5. Update DECISIONS.md and LOG.md. Commit as you go.

When the analysis dataset is built, create the file .phase-done with one line saying what you did.
