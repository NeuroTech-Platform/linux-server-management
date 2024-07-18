#!/bin/sh -l

export PATH="${PATH}:/root/.local/bin"

echo "# Running ansible-lint"
ansible-lint --version

if ! ansible-lint -v; then
  echo 'ansible-lint failed.'
  exit 1
fi
