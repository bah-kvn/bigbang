#shellcheck disable=all
echo "branch = $(basename $(git symbolic-ref -q HEAD))"
