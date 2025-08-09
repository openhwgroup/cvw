#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Append PATH and source command to ~/.bashrc
echo 'export PATH="${WALLY}/bin:${RISCV}/bin:$PATH"' >> "$HOME/.bashrc"
echo 'export CVW_ARCH_VERIF="${WALLY}/addins/cvw-arch-verif"' >> "$HOME/.bashrc"

echo 'source ${WALLY_PYTHON_VENV_DIR}/bin/activate' >> "$HOME/.bashrc"

# Set core dump size (default 300000 KB if not provided)
ulimit -c "${WALLY_CORE_DUMP_SIZE:=300000}"

# Install pre-commit hook if missing
if [ ! -e "$WALLY/.git/hooks/pre-commit" ]; then
    pushd "$WALLY" > /dev/null || exit 1
    echo "Installing pre-commit hooks"
    pre-commit install
    popd > /dev/null || exit 1
fi