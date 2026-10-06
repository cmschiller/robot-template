#!/usr/bin/env bash
# The robot: writes a paper from memo/memo.md in six phases, with nobody watching.
# Run it inside the course sandbox (the Codespace or container), from the repository root:
#     bash run-paper.sh
# If it stops (a usage limit, a timeout, a WRDS fetch), rerun it: it picks up where it stopped.
# While it works you may do only two things: rerun this script, and run  python fetch_wrds.py  when
# it asks. Don't edit, answer, or re-prompt anything.

set -u
cd "$(dirname "$0")" || exit 1

MODEL=${MODEL:-sonnet}
MAX_ATTEMPTS=4          # per phase; each WRDS round trip inside a phase uses one attempt
PHASES="01-plan 02-data 03-analysis 04-write 05-referee 06-revise"

# The robot commits under its own name, so git log shows who did what.
export GIT_AUTHOR_NAME="Robot (Claude Code)" GIT_AUTHOR_EMAIL="robot@example.invalid"
export GIT_COMMITTER_NAME="Robot (Claude Code)" GIT_COMMITTER_EMAIL="robot@example.invalid"
export GIT_TERMINAL_PROMPT=0

in_sandbox() {
  [ -f /.dockerenv ] || [ -f /run/.containerenv ] || [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ]
}
if ! in_sandbox; then
  echo "This is not the course sandbox. The robot runs with every permission prompt off, so it only"
  echo "runs inside the Codespace or container. See the handout, step 1."
  exit 1
fi
if [ "$(id -u)" = 0 ]; then
  echo "Don't run this as root. In the Codespace or container you are the user 'vscode' by default."
  exit 1
fi
if ! command -v claude >/dev/null 2>&1; then
  echo "Can't find 'claude'. Rebuild the container, or ask the instructor."
  exit 1
fi
if grep -q "PASTE YOUR MEMO" memo/memo.md; then
  echo "First paste your memo into memo/memo.md, exactly as you uploaded it."
  exit 1
fi
if grep -q "REPLACE" memo/contact.txt; then
  echo "First put your name and email in memo/contact.txt (the SEC asks for them)."
  exit 1
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -q
git config --global --add safe.directory "$PWD" 2>/dev/null
mkdir -p logs logs/failed

say() { printf '%s\n' "$*"; printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M')" "$*" >> logs/RUNLOG.txt; }

# WRDS query files the student hasn't fetched yet.
pending_queries() {
  for f in data/wrds-queries-*.sql; do
    [ -e "$f" ] || continue
    [ -e "data/wrds/.fetched-$(basename "$f" .sql)" ] || printf '%s\n' "$f"
  done
}

# Tokens must never reach git, even if the robot printed one.
TOKENS='sk-ant-[A-Za-z0-9_-]{8,}|gh[pousr]_[A-Za-z0-9]{20,}'
redact() {
  grep -rlIE --exclude-dir=.git --exclude-dir=data "$TOKENS" . 2>/dev/null |
    while IFS= read -r f; do sed -i -E "s/$TOKENS/[REDACTED]/g" "$f"; done
}

commit_all() {
  redact
  # Keep files over 50 MB out of git; GitHub rejects them.
  find . -path ./.git -prune -o -type f -size +50M -print | sed 's|^\./||' >> .git/info/exclude
  git add -A >/dev/null 2>&1
  git commit -q -m "$1" >/dev/null 2>&1 || true
  git push -q >/dev/null 2>&1 || true     # a backup copy on GitHub; fine if it fails
}

# One fresh session. The transcript goes to logs/; the exit code says whether the session failed.
run_phase() {
  claude -p --model "$MODEL" --dangerously-skip-permissions --output-format stream-json --verbose \
    < "phases/$1.md" > "logs/$1-$2.jsonl" 2> "logs/$1-$2.err"
  code=$?
  if [ "$code" -eq 0 ] && tail -n 1 "logs/$1-$2.jsonl" | grep -q '"is_error":true'; then code=1; fi
  return "$code"
}

say "run-paper.sh started (model: $MODEL)."
for p in $PHASES; do
  [ -e "logs/$p.done" ] && continue

  if [ -n "$(pending_queries)" ]; then
    say "Paused: the robot is waiting for WRDS data ($(pending_queries | tr '\n' ' '))."
    echo
    echo "Now run:   python fetch_wrds.py     (approve the Duo push on your phone)"
    echo "Then rerun:  bash run-paper.sh"
    exit 0
  fi

  attempts=$(ls logs/"$p"-*.jsonl 2>/dev/null | wc -l)
  if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
    say "Phase $p: $attempts attempts used up; moving on without it."
    touch "logs/$p.done"
    commit_all "harness: gave up on phase $p after $attempts attempts"
    continue
  fi
  a=$((attempts + 1))

  rm -f .phase-done
  say "Phase $p, attempt $a: started."
  start=$(date +%s)
  run_phase "$p" "$a"
  code=$?
  mins=$(( ($(date +%s) - start) / 60 ))

  if [ "$code" -ne 0 ]; then
    why=$(grep -hoiE 'not logged in|(usage|rate) limit[^"\\]{0,80}|limit reached[^"\\]{0,80}' "logs/$p-$a.jsonl" "logs/$p-$a.err" 2>/dev/null | tail -n 1)
    stamp=$(date +%Y%m%d-%H%M)
    mv "logs/$p-$a.jsonl" "logs/failed/$p-$a-$stamp.jsonl"
    mv "logs/$p-$a.err" "logs/failed/$p-$a-$stamp.err"
    say "Phase $p, attempt $a: stopped after $mins min (exit $code). ${why}"
    commit_all "harness: phase $p attempt $a stopped (exit $code)"
    echo
    if printf '%s' "$why" | grep -qi 'not logged in'; then
      echo "Claude Code isn't logged in here. Type  claude , then  /login , paste the code back, type"
      echo "/exit , and rerun:  bash run-paper.sh"
    elif [ -n "$why" ]; then
      echo "The robot stopped at a usage limit. Wait until it resets (claude.ai shows when), then rerun:"
      echo "    bash run-paper.sh     It continues from the start of this phase."
    else
      echo "The robot stopped (see logs/failed/ for the details). Rerun  bash run-paper.sh  once; it"
      echo "continues from the start of this phase. If it stops again the same way, tell the instructor."
    fi
    exit 1
  fi

  if [ -e .phase-done ]; then
    mv .phase-done "logs/$p.done"
    say "Phase $p, attempt $a: done in $mins min. $(head -c 300 "logs/$p.done" | tr '\n' ' ')"
  elif [ -n "$(pending_queries)" ]; then
    say "Phase $p, attempt $a: wrote WRDS queries after $mins min."
  else
    touch "logs/$p.done"
    say "Phase $p, attempt $a: ended after $mins min without marking itself done; moving on."
  fi
  commit_all "harness: phase $p, attempt $a"
done

if [ -f paper/paper.pdf ]; then
  say "All six phases finished."
  echo
  echo "Done. The robot's paper is paper/paper.pdf. Upload it to the week3 folder as"
  echo "robot-paper-XX.pdf (XX = your initials), with the repository's URL in robot-repo-XX.txt."
  echo "Timings and restarts are in logs/RUNLOG.txt. Then delete the Codespace (the repository keeps"
  echo "everything that matters)."
else
  say "All phases ran, but there is no paper/paper.pdf."
  echo "The robot didn't produce paper/paper.pdf. Don't fix it: tell the instructor."
fi
