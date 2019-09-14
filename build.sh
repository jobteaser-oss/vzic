#!/bin/bash


# This script does
#
# * download the specified tzdata archive
# * download the specified master zoneinfo archive
# * build vzic
# * run vzic on the downloaded tzdata
# * merge the new zoneinfo into the master zoneinfo
# * archive the result and copy it to the specified output dir
# 
# The URLS for the master zoneinfo and new tzdata are read from settings.config file.
#

set -e

# read settings file
. ./settings.config

#clean build dir
if [ -d build ]; then rm -r build; fi
mkdir -p build

echo "Building $VZIC_RELEASE_NAME"

echo "Downloading tzdata from $VZIC_TZDATA_ARCHIVE_URL"
wget -q -O build/tzdata.tar.gz $VZIC_TZDATA_ARCHIVE_URL

echo "Downloading master zoneinfo from $VZIC_MASTER_ZONEINFO_ARCHIVE_URL"
wget -q -O build/zoneinfo_master.tar.gz $VZIC_MASTER_ZONEINFO_ARCHIVE_URL

echo "Extracting new tzdata"
mkdir -p build/tzdata
tar -xzf build/tzdata.tar.gz -C build/tzdata

echo "Building vzic"
make -B

echo "Running vzic"
./vzic --olson-dir build/tzdata --output-dir build/zoneinfo

echo "Extracting master zoneinfo"
mkdir -p build/zoneinfo_master
tar -xzf build/zoneinfo_master.tar.gz -C build/zoneinfo_master

# define variables used in vzic-merge.pl
export VZIC_ZONEINFO_MASTER=`pwd`/build/zoneinfo_master
export VZIC_ZONEINFO_NEW=`pwd`/build/zoneinfo

echo "Merging"
./vzic-merge.pl

# copy updated zones
cp $VZIC_ZONEINFO_NEW/zones.* $VZIC_ZONEINFO_MASTER 

echo "Creating output archive"
mkdir -p build/out
cd build/zoneinfo
tar -czf "../out/zoneinfo_$VZIC_RELEASE_NAME.tar.gz" * 
cd ../..
