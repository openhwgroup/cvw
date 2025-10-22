#! /bin/bash
git submodule update
deactivate
export UV_NO_DEV=1
pushd addins/cvw-arch-verif &> /dev/null
uv sync
popd &> /dev/null
