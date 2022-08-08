#!/bin/sh

NAME=bigbang-sops

fp=$(\
  gpg --list-keys --fingerprint \
  | grep "bigbang-dev-environment" -B 1 \
  | grep -v "${NAME}" \
  | tr -d ' ' \
  | sed -e 's/Keyfingerprint=//g'\
)
export fp

echo "$fp"
