Phase 1 of 6: plan.

Read CLAUDE.md and memo/memo.md. Nothing else exists yet.

1. Write PLAN.md:
   - the research question, in one sentence, and the hypothesis;
   - the empirical design: sample, unit of observation, the main specification written as an
     equation, and the identifying assumption in plain words;
   - the data, source by source, and how you will get each one (public download, or WRDS);
   - the main table and the main figure you intend to produce;
   - the robustness checks you will run.
2. For every public source, check now, with one quick request, that it is reachable without a login.
   Replace any source that isn't.
3. If you need WRDS data, write data/wrds-queries-01.sql: schema queries for every table you plan to
   use, plus any data queries you are already sure about.
4. Start DECISIONS.md and LOG.md. Commit.

Don't download or build any data yet. When PLAN.md is complete, create the file .phase-done with one
line saying what you did.
