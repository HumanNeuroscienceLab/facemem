#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
  echo "usage: $0 roi-name (njobs [16])"
  exit 2
fi

name="$1"
njobs=${2:-16}

# Questions
./22_group_task_worker.bash --subfile=../sublist_all.txt --runtype=Questions --region=${name} --njobs=$njobs

# NoQuestions
./22_group_task_worker.bash --subfile=../sublist_all.txt --runtype=NoQuestions --region=${name} --njobs=$njobs
