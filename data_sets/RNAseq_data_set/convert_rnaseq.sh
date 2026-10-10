#!/bin/bash

set -e

BASE="/data/projet3/data_sets/RNAseq_data_test"
TMP="$BASE/sra_tmp"

echo "Conversion gonad..."
fasterq-dump "$BASE/sra_downloads/SRR37114952/SRR37114952.sra" --split-files -e 2 -t "$TMP" -O "$BASE/gonad_dataset"

echo "Conversion spine..."
fasterq-dump "$BASE/sra_downloads/SRR37114948/SRR37114948.sra" --split-files -e 2 -t "$TMP" -O "$BASE/spine_dataset"

echo "Conversion stomach..."
fasterq-dump "$BASE/sra_downloads/SRR37114954/SRR37114954.sra" --split-files -e 2 -t "$TMP" -O "$BASE/stomach_dataset"

echo "Conversions terminees, suppression des fichiers SRA..."

rm -rf "$BASE/sra_downloads/SRR37114952"
rm -rf "$BASE/sra_downloads/SRR37114948"
rm -rf "$BASE/sra_downloads/SRR37114954"
rm -rf "$TMP"

echo "Nettoyage termine."
