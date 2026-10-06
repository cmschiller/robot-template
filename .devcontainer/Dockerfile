# The course sandbox: the only things inside are this repository, Python, LaTeX and Claude Code.
# Nothing from your laptop is in here: no home folder, no SSH keys, no Dropbox, no other repositories.
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# LaTeX, enough for an article with tables, figures and a bibliography. (The base image's Yarn
# package source has an expired signing key and breaks apt-get update; we don't need Yarn.)
RUN rm -f /etc/apt/sources.list.d/yarn.list \
 && apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y --no-install-recommends \
      texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended \
      texlive-science texlive-bibtex-extra latexmk lmodern \
 && rm -rf /var/lib/apt/lists/*

# Python packages, pinned so that every student's robot works in the same environment.
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Claude Code, installed for the non-root user: skip-all mode refuses to run as root. All of its
# settings and the login live in ~/.claude, which a Docker user can keep in a named volume.
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash && mkdir -p /home/vscode/.claude \
 && if [ -f /home/vscode/.claude.json ]; then mv /home/vscode/.claude.json /home/vscode/.claude/.claude.json; fi
ENV PATH="/home/vscode/.local/bin:${PATH}" \
    CLAUDE_CONFIG_DIR="/home/vscode/.claude"
