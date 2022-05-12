NAME=bigbang-sops

export fp=$(gpg --list-keys --fingerprint | grep "bigbang-dev-environment" -B 1 | grep -v "${NAME}" | tr -d ' ' | tr -d 'Keyfingerprint=')
echo $fp
