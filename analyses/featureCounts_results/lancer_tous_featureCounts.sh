#!/bin/bash
set -euo pipefail

BASE=/data/projet3
SAFDIR="$BASE/analyses/featureCounts_SAF"
RESULTS="$BASE/analyses/featureCounts_results"
BAM="$BASE/data_sets/BAM_data_set"
FC="$BASE/conda_environments/env_featurecounts/bin/featureCounts"

RUNS=(
    run_1_juveniles
    run_2_all_RNA_seq
    run_juveniles_trimes
    run_all_RNA_seq_prot_filtred
    run_all_RNA_seq_juveniles_trimes_prot_filtred
    run_mixte_nervetrim_podia_all_juvtrim
)

# Retrouver le bon fichier SAF
get_saf() {
    local run="$1" part="$2"

    SAF="$SAFDIR/$run/part_$part.saf"

    if [[ "$run" == "run_mixte_nervetrim_podia_all_juvtrim" && "$part" == "002" ]]; then
        SAF="$SAFDIR/$run/genomic_part_002.saf"
    fi
}

# Selectionner les BAM selon le run
get_bams() {
    local run="$1" part="$2"
    local N="$BAM/non_trimmed/part_$part"
    local T="$BAM/trimmed/part_$part"

    BAMS=()

    case "$run" in

        run_1_juveniles)
            BAMS=(
                "$N/juvenile_1_SRR37199247.bam"
                "$N/juvenile_2_SRR37199246.bam"
            )
            ;;

        run_juveniles_trimes)
            BAMS=(
                "$T/juvenile_1_SRR37199247.bam"
                "$T/juvenile_2_SRR37199246.bam"
            )
            ;;

        run_2_all_RNA_seq|run_all_RNA_seq_prot_filtred)
            BAMS=(
                "$N/epine_SRR37114948.bam"
                "$N/estomac_SRR37114954.bam"
                "$N/gonade_SRR37114952.bam"
                "$N/juvenile_1_SRR37199247.bam"
                "$N/juvenile_2_SRR37199246.bam"
            )
            ;;

        run_all_RNA_seq_juveniles_trimes_prot_filtred|run_mixte_nervetrim_podia_all_juvtrim)
            BAMS=(
                "$N/epine_SRR37114948.bam"
                "$N/estomac_SRR37114954.bam"
                "$N/gonade_SRR37114952.bam"
                "$T/juvenile_1_SRR37199247.bam"
                "$T/juvenile_2_SRR37199246.bam"
            )

            if [[ "$run" == "run_mixte_nervetrim_podia_all_juvtrim" ]]; then
                BAMS+=(
                    "$T/nerf_SRR6378162_paired.bam"
                    "$N/podia_SRR14654944.bam"
                )
            fi
            ;;
    esac
}

# Verifier tous les fichiers AVANT de lancer les calculs
echo "===== VERIFICATION DES FICHIERS ====="

for run in "${RUNS[@]}"; do
    for part in 001 002; do

        get_saf "$run" "$part"
        get_bams "$run" "$part"

        [ -s "$SAF" ] || {
            echo "SAF manquant : $SAF"
            exit 1
        }

        for fichier in "${BAMS[@]}"; do
            [ -s "$fichier" ] || {
                echo "BAM manquant : $fichier"
                exit 1
            }
        done

        if [[ "$run" == "run_mixte_nervetrim_podia_all_juvtrim" ]]; then
            U="$BAM/trimmed/part_$part/nerf_SRR6378162_R1_unpaired.bam"
            [ -s "$U" ] || {
                echo "BAM manquant : $U"
                exit 1
            }
        fi

        echo "OK : $run partie $part"
    done
done

echo "===== DEBUT DES COMPTAGES ====="

# Compter les fragments pour chaque run et chaque partie
for run in "${RUNS[@]}"; do
    for part in 001 002; do

        get_saf "$run" "$part"
        get_bams "$run" "$part"

        OUT="$RESULTS/$run/part_$part"
        mkdir -p "$OUT"

        echo "=================================="
        echo "RUN : $run"
        echo "PARTIE : $part"
        echo "SAF : $SAF"
        echo "BAM : ${#BAMS[@]}"
        echo "=================================="

        "$FC" -T 4 -F SAF -s 0 -p --countReadPairs \
            -a "$SAF" \
            -o "$OUT/counts_paired.txt" \
            "${BAMS[@]}"

        # Lectures non appariees du nerf
        if [[ "$run" == "run_mixte_nervetrim_podia_all_juvtrim" ]]; then

            "$FC" -T 4 -F SAF -s 0 \
                -a "$SAF" \
                -o "$OUT/counts_nerf_unpaired.txt" \
                "$BAM/trimmed/part_$part/nerf_SRR6378162_R1_unpaired.bam"
        fi

        echo "TERMINE : $run partie $part"
    done
done

echo "=================================="
echo "TOUS LES FEATURECOUNTS SONT TERMINES"
echo "=================================="

touch "$RESULTS/featureCounts_TERMINE_OK.txt"
