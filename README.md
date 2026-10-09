# Hand it to the robot

A course exercise: an agent writes an empirical paper from your one-page idea memo, alone, inside a
sandbox. A classmate then referees what it wrote. The handout (`week2-hand-it-to-the-robot.pdf`, in
the course folder) has every step and the rules; this is the short version.

## Step 1: the sandbox
1. On this repository's GitHub page: **Use this template → Create a new repository**. Make it
   **private**.
2. In your new repository: **Code → Codespaces → Create codespace on main**. The first build takes a
   few minutes. (Docker on your own machine works too; see the handout.)
3. In the Codespace's terminal: type `claude`, then `/login`. Open the link, sign in, paste the code
   back, then `/exit`.
4. Run `bash smoke-test.sh` and read what it prints.

## Step 2: the robot
1. Paste your memo into `memo/memo.md`, exactly as you uploaded it. Put your name and email in
   `memo/contact.txt`. Commit both.
2. Run `bash run-paper.sh`. Then leave it alone.
3. If it stops at a usage limit, rerun it once the limit resets. If it asks for WRDS data, run
   `python fetch_wrds.py`, approve the Duo push, and rerun `bash run-paper.sh`.
4. When it finishes, upload `paper/paper.pdf` as `robot-paper-XX.pdf`, and the repository's URL as
   `robot-repo-XX.txt`, to the course folder's `week3/`. Add the instructor to the repository.

## What's in here
- `CLAUDE.md`: the robot's standing instructions. Every student's robot gets the same ones.
- `phases/`: the six phase prompts (plan, data, analysis, write, referee, revise).
- `run-paper.sh`: runs the phases, one fresh session each, and logs every transcript to `logs/`.
- `fetch_wrds.py`: fetches the WRDS data the robot asks for. You run it; the robot never sees your
  password.
- `smoke-test.sh`: checks the sandbox.
- `.devcontainer/`: the sandbox itself.
