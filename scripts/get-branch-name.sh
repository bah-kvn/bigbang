#!/bin/sh

REF=$(git symbolic-ref -q HEAD)
BRANCH=$(basename "$REF")
echo "branch = $BRANCH"
