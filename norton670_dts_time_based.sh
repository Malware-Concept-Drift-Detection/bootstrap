#!/bin/bash

# Extract DTS features from the Norton dataset
# Input data paths
PE_DATASET_PATH="/home/luca/WD/NortonDataset670/MALWARE/"
DATASET_INFO_PATH="/home/luca/WD/NortonDataset670/dataset_info/"
PE_DATASET_TYPE="Norton670"

# Feature extraction output
RAW_DATASETS_BASE_PATH="$(pwd)/raw_dataset/"
DATASET_FILENAMES=("norton670_pe_ember_features.csv")

# Train/test split output directory
SPLITTED_DATASET_PATH="$(pwd)/splitted_dataset/"
# Transcendent output results directory
CD_RESULTS_PATH="$(pwd)/results/"

echo "Performing Train/Test split..."
docker run \
  --name train-test-split-$PE_DATASET_TYPE \
  -e BASE_OUTPUT_PATH="/usr/app/splitted_dataset/" \
  -e PE_DATASET_TYPE="$PE_DATASET_TYPE" \
  -v $RAW_DATASETS_BASE_PATH:/usr/app/raw_dataset/ \
  -v $SPLITTED_DATASET_PATH:/usr/app/splitted_dataset/ \
  ghcr.io/malware-concept-drift-detection/train-test-splits:main

echo "Extracting 'Decoding-the-Secrets' features..."
docker run --rm -it \
  --name feature-extraction-pipeline \
  -e MALWARE_DIR_PATH=/usr/input_data/malware/ \
  -e SPLITTED_DATASET_PATH=/usr/input_data/splitted_dataset/ \
  -e FINAL_DATASET_DIR=/usr/app/data/ \
  -e N_PROCESSES=32 \
  -v $SPLITTED_DATASET_PATH/$PE_DATASET_TYPE/time_split/:/usr/input_data/splitted_dataset/ \
  -v $PE_DATASET_PATH:/usr/input_data/malware/ \
  -v $DATASET_INFO_PATH:/usr/input_data/ \
  -v $(pwd)/data/:/usr/app/data/ \
  ghcr.io/malware-concept-drift-detection/dts-features-extraction:main

echo "Applying Concept drift detection..."
docker run \
  --name transcendent \
  -e BASE_DATASET_PATH=/usr/app/dataset/ \
  -e PE_DATASET_TYPE=$PE_DATASET_PATH \
  -e TRAIN_TEST_SPLIT_TYPE=time_split \
  -v $CD_RESULTS_PATH:/usr/app/models/ \
  -v $SPLITTED_DATASET_PATH:/usr/app/dataset/ \
  ghcr.io/malware-concept-drift-detection/transcendent-multiclass:main
