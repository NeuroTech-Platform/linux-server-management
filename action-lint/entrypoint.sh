#!/bin/sh -l

export PATH="${PATH}:/root/.local/bin"

echo "# Running ansible-lint"
ansible-lint --version
ls -la

if ! ansible-lint --exclude .git --exclude .github -v -c .ansible-lint; then
  echo 'ansible-lint failed.'
  exit 1
fi
