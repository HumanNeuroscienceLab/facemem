#!/usr/bin/env bash

run() {
  echo "$@"
  eval "$@"
  return $?
}

echo
echo "Questions"
run "./31_tsnr_worker.bash --subfile=../sublist_all.txt --runtype=Questions --model=spmg1"

echo
echo "NoQuestions"
run "./31_tsnr_worker.bash --subfile=../sublist_all.txt --runtype=NoQuestions --model=spmg1"
