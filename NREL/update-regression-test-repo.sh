#!/bin/bash -l

# Script for updating the PeleRegressionTesting repo before it's used in running the tests.
# Set a cron job to cd to the build-test repo in testing directory and then run this script.
# This allows manipulation of all the testing machines by committing updates to the test script.

printf "$(date)\n"
printf "======================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "======================================================\n"

printf "\n\nUpdating PeleRegressionTesting repo...\n\n"
(set -x; pwd && git fetch --all && git reset --hard origin/development && git clean -df && git status -uno) 2>&1
printf "\n======================================================\n\n"