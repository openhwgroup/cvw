#! /bin/bash
git submodule update
deactivate
pushd addins/cvw-arch-verif &> /dev/null
uv sync --no-dev
popd &> /dev/null
