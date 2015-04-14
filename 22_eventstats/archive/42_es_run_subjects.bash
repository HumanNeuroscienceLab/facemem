#!/usr/bin/env bash

# This will run many subjects in parallel

subjects=$(cat ../sublist_all.txt)

echo "Questions"
parallel --no-notice -j 16 --eta \
  ./42_es_run_subject_worker.bash es_opts.txt {} Questions ::: ${subjects}

echo "NoQuestions"
parallel --no-notice -j 16 --eta \
  ./42_es_run_subject_worker.bash es_opts.txt {} NoQuestions ::: ${subjects}
