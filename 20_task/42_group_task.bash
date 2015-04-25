#!/usr/bin/env bash

echo "./43_group_task_worker.bash --subfile=../sublist_all.txt --runtype=Questions --model=spmg1 --njobs=20"
./43_group_task_worker.bash --subfile=../sublist_all.txt --runtype=Questions --model=spmg1 --njobs=20
  
echo "./43_group_task_worker.bash --subfile=../sublist_all.txt --runtype=NoQuestions --model=spmg1 --njobs=20"
./43_group_task_worker.bash --subfile=../sublist_all.txt --runtype=NoQuestions --model=spmg1 --njobs=20
