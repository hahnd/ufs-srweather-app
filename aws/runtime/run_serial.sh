#! /bin/bash

# Copyright UCAR (C) 2022

# set and create experiment directory
export WORKDIR="/data"
export EXPTDIR="/data/experiments/test_CONUS_25km_GFSv15p2"
mkdir -p ${EXPTDIR}
cd ${EXPTDIR} || exit 1

# set other environment variables for the run
export MACHINE="LINUX"
export LAYOUT_X=2
export LAYOUT_Y=2
export RUN_CMD_UTILS="mpirun -np 4"
