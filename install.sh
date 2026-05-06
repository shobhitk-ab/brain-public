#!/usr/bin/env bash
# Install brain commands into Claude Code as /brain:<name> via symlink.
# Safe to re-run; replaces any existing symlink.

set -euo pipefail

BRAIN_DIR="${BRAIN_DIR:-$HOME/brain}"
CLAUDE_CMDS="${HOME}/.claude/commands"

if [[ ! -d "${BRAIN_DIR}/commands" ]]; then
  echo "ERROR: ${BRAIN_DIR}/commands not found. Is BRAIN_DIR set correctly?" >&2
  exit 1
fi

mkdir -p "${CLAUDE_CMDS}"

# If a 'brain' entry exists and is not a symlink, refuse to clobber.
if [[ -e "${CLAUDE_CMDS}/brain" && ! -L "${CLAUDE_CMDS}/brain" ]]; then
  echo "ERROR: ${CLAUDE_CMDS}/brain exists and is not a symlink. Move it aside and re-run." >&2
  exit 1
fi

ln -sfn "${BRAIN_DIR}/commands" "${CLAUDE_CMDS}/brain"

echo "Installed: ${CLAUDE_CMDS}/brain -> ${BRAIN_DIR}/commands"
echo ""
echo "Commands now available as:"
ls -1 "${BRAIN_DIR}/commands" | sed 's/\.md$//' | sed 's/^/  \/brain:/'
