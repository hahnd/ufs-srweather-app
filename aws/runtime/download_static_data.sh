#! /bin/bash

# setup the directory
static_data_root="/data/static"
mkdir -p "${static_data_root}"
cd "${static_data_root}" || exit 1

# download the data from S3
aws s3 cp s3://srw-data/NaturalEarth.tar.gz .
aws s3 cp s3://srw-data/climo_fields_netcdf.tar.gz .
aws s3 cp s3://srw-data/fix_am.tar.gz .
aws s3 cp s3://srw-data/fix_orog.tar.gz .

# unpack the files and clean up
for file in NaturalEarth.tar.gz climo_fields_netcdf.tar.gz fix_am.tar.gz fix_orog.tar.gz; do
  tar -xvzf ${file}
  rm -f ${file}
done

# download and unpack the FV3GFS model data
curl https://ufs-data.s3.amazonaws.com/public_release/ufs-srweather-app-v1.0.0/ic/gst_model_data.tar.gz | tar -xzv

# update bashrc with data paths
echo "export FIXgsm=\"${static_data_root}/fix_am\"" | tee -a ~/.bashrc
echo "export TOPO_DIR=\"${static_data_root}/fix_orog\"" | tee -a ~/.bashrc
echo "export SFC_CLIMO_INPUT_DIR=\"${static_data_root}/climo_fields_netcdf\"" | tee -a ~/.bashrc
echo "export USE_USER_STAGED_EXTRN_FILES=\"TRUE\"" | tee -a ~/.bashrc
echo "export EXTRN_MDL_SOURCE_BASEDIR_ICS=\"${static_data_root}/model_data/FV3GFS\"" | tee -a ~/.bashrc
echo "export EXTRN_MDL_SOURCE_BASEDIR_LBCS=\"${static_data_root}/model_data/FV3GFS\"" | tee -a ~/.bashrc

# remind user to source their bashrc file
echo "!!! Source your bashrc file !!!"
echo "  source ~/.bashrc"
