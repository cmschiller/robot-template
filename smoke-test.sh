#!/usr/bin/env bash
# Step 1: check the sandbox before you launch the robot. Inside the Codespace (or container), from the
# repository root, run:
#     bash smoke-test.sh
# It shows what an agent in here can reach, checks that Claude Code is logged in, and runs one small
# task with every permission prompt turned off. About five minutes.

set -u
cd "$(dirname "$0")" || exit 1
export GIT_AUTHOR_NAME="Robot (Claude Code)" GIT_AUTHOR_EMAIL="robot@example.invalid"
export GIT_COMMITTER_NAME="Robot (Claude Code)" GIT_COMMITTER_EMAIL="robot@example.invalid"

if ! { [ -f /.dockerenv ] || [ -f /run/.containerenv ] || [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ]; }; then
  echo "This is not the course sandbox: you are on your own computer. Stop here and open the"
  echo "repository in its Codespace (or container) first. See the handout, step 1."
  exit 1
fi
git config --global --add safe.directory "$PWD" 2>/dev/null

echo "1. What an agent in here can reach"
echo "   You are: $(whoami), in $(pwd)"
echo "   Your home folder in here:"
ls -A ~ | sed 's/^/     /'
echo "   SSH keys:"
if [ -d ~/.ssh ] && [ -n "$(ls -A ~/.ssh 2>/dev/null)" ]; then ls ~/.ssh | sed 's/^/     /'; else echo "     none"; fi
echo "   Secrets in reach (names only):"
# (GPG_KEY is the Python image's public signing-key ID, not a secret.)
env | cut -d= -f1 | grep -iE 'token|key|secret|passw' | grep -v '^GPG_KEY$' | sed 's/^/     /'
[ -e ~/.claude/.credentials.json ] && echo "     ~/.claude/.credentials.json (your Claude login)"
echo "   Compare with what your own laptop's home folder holds."
echo

echo "2. Is Claude Code logged in?"
if ! out=$(claude -p --model sonnet "Reply with the single word OK." 2>&1); then
  echo "   No. Type  claude  and then  /login . Open the link it prints, sign in, paste the code back,"
  echo "   type  /exit , and rerun this script."
  exit 1
fi
echo "   Yes (it said: $out)"
echo

echo "3. One small task, with every permission prompt off (about two minutes)"
mkdir -p smoke
if ! claude -p --model sonnet --dangerously-skip-permissions "Write smoke/get_unrate.py, a Python \
script that downloads the FRED series UNRATE as CSV from \
https://fred.stlouisfed.org/graph/fredgraph.csv?id=UNRATE (no API key is needed) and plots it to \
smoke/unrate.png. Run it. Commit the smoke folder to git with a message that says why. Then reply with \
one line: the last date in the series and its value."; then
  echo "   The task failed. Rerun this script once; if it fails again, tell the instructor."
  exit 1
fi
echo

echo "4. What it did"
git log -1 --stat 2>/dev/null | sed 's/^/   /'
ls smoke | sed 's/^/   /'
echo
echo "If you see unrate.png and a commit, the sandbox works. Open smoke/unrate.png to look at it."
echo "Next (the handout, step 2): paste your memo into memo/memo.md, fill in memo/contact.txt, and run"
echo "    bash run-paper.sh"
