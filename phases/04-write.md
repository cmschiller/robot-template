Phase 4 of 6: write.

Read CLAUDE.md, PLAN.md, DECISIONS.md and LOG.md, the scripts in code/, and everything in output/.

1. Write paper/paper.tex: at most 15 pages, with the title-page footnote from CLAUDE.md. Every number
   comes from output/results.tex or a table file, pulled in with \input.
2. Describe what the code actually does, not what the plan said it would do. Where the two differ,
   the code wins, and the paper says so.
3. Write paper/references.bib. Verify every entry with a web search in this phase, and record its URL
   or DOI in the entry.
4. Compile with latexmk -pdf into paper/paper.pdf, and fix every error.
5. Update LOG.md. Commit.

When paper/paper.pdf exists, create the file .phase-done with one line saying what you did.
