# You are writing an empirical finance paper, alone

This repository belongs to a PhD student in a finance course. The student wrote a one-page research
memo, `memo/memo.md`, without AI. Your job is to turn it into a complete empirical paper, unattended.

The run has six phases. Each phase is a fresh session that starts with this file and a phase prompt
from `phases/`. You remember nothing from earlier phases: everything you know about them is in the
files (`PLAN.md`, `DECISIONS.md`, `LOG.md`, the code, `git log`). Keep those files good enough that a
stranger could pick up the work, because a stranger will: the next phase.

## Nobody will answer
No human reads anything you write until the run is over. Never ask a question and never wait for
input. When a choice has to be made, make it, and record it in `DECISIONS.md`.

## The paper trail (required)
- Track the project in git. Commit at every meaningful checkpoint, with messages that say why, not
  just what.
- `DECISIONS.md`: each methodological choice, the alternatives you rejected, and your confidence
  (high / medium / low).
- `LOG.md`: a plain-language narrative a coauthor could follow. Append to it; never rewrite earlier
  entries.
- Print a sample-attrition table at every stage of the data build: the N, what dropped, and why.
  Save each one in `output/attrition/`.

## Layout
- `memo/`: the student's memo and contact line. Read it; never edit it.
- `phases/`: the phase prompts. Never edit them.
- `code/`: your scripts, numbered in run order (`01_...`, `02_...`). Ask yourself for scripts, not
  outputs: every number must come from a script that reruns from the raw data.
- `data/raw/`: downloaded public data (not committed).
- `data/wrds/`: WRDS extracts, written by the student's fetch script. Read-only; not committed.
- `data/clean/`: the datasets you build, with a codebook in `data/clean/README.md`.
- `output/`: tables, figures, `results.tex`, attrition tables.
- `paper/`: `paper.tex`, `references.bib`, `paper.pdf`.
- `review/`: the referee report and the response.
- `logs/`: transcripts written by the harness. Never touch them.
- `smoke/`: the student's sandbox test. Ignore it.

## Data
- **Public data:** download it with a script in `code/`. No API keys and no logins: if a source needs
  one, use a keyless route or another source. SEC EDGAR requires a User-Agent header: use the line in
  `memo/contact.txt`, and stay under 10 requests per second.
- **WRDS** (CRSP, Compustat, IBES, Thomson/Refinitiv, and so on): you cannot log in, and you must never
  try. Write the SQL you need to a new file `data/wrds-queries-NN.sql` (NN = 01, 02, ... ; never edit
  an old file). Each query starts on a line `-- name: short_name` (lowercase letters, digits,
  underscores) and is a single SELECT (or WITH ... SELECT) against WRDS libraries. The student runs a
  fetch script that saves each result as `data/wrds/short_name.parquet` and reports row counts and
  errors in `data/wrds/FETCH_LOG.md`.
  - To learn table and column names, include schema queries, e.g.
    `SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'crsp' AND table_name = 'msf'`.
  - Pull only what you need: the columns, the years, the filters. Results are capped at 10 million rows.
  - Look at WRDS data through schemas, counts and summary statistics. Don't print raw rows of it.
  - Once you have written a query file, finish the phase: the harness pauses the run until the data
    arrives, then restarts the phase.
- **Anything else the memo names** (proprietary, hand-collected, unavailable): use the closest
  substitute you can get. Say so in `DECISIONS.md` and in the paper's introduction.
- Don't commit files larger than 50 MB.

## Numbers and references
- No hand-typed numbers in the paper. Scripts write `output/results.tex` (one `\newcommand` per number)
  and the table files; `paper.tex` pulls them in with `\input`.
- Cite only papers you have verified exist, with a web search, in this run. Put the URL or DOI in each
  `references.bib` entry. If you can't verify a reference, don't cite it.

## Boundaries
- Work only inside this repository.
- Never create repositories, change a repository's visibility, add remotes, post anything online, send
  email, or contact anyone.
- Never open, print or copy credentials, tokens, or files outside this repository.
- Don't install system packages. If you need a Python package, `pip install --user` it and record that
  in `DECISIONS.md`.

## The paper
- An empirical finance paper of at most 15 pages, tables and figures included: abstract,
  introduction, data, empirical design, results, robustness, conclusion, references.
- The title page carries this footnote, verbatim: "Generated autonomously by Claude Code from a
  student's research memo, for a PhD course exercise. Not a research paper: do not cite or circulate."
- Build it with `latexmk -pdf` into `paper/paper.pdf`.
