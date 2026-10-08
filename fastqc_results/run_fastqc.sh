#!/bin/bash

# Chemins des données et des résultats
DATA="/data/projet3/data_sets/RNAseq_data_set"
OUT="/data/projet3/fastqc_results"

# Analyse FastQC Gonad
echo "Début FastQC Gonad"
fastqc -t 4 -o "$OUT/Gonad" "$DATA"/gonad_dataset/*.fastq

# Analyse FastQC Stomach
echo "Début FastQC Stomach"
fastqc -t 4 -o "$OUT/Stomach" "$DATA"/stomach_dataset/*.fastq

# Analyse FastQC Spine
echo "Début FastQC Spine"
fastqc -t 4 -o "$OUT/Spine" "$DATA"/spine_dataset/*.fastq

