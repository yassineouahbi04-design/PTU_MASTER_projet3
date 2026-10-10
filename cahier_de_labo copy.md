# Cahier de Laboratoire — Projet 3 : Annotation d'*Acanthaster planci*

**Membres du groupe :** Yassine Ouahbi, [Nom Membre 2], [Nom Membre 3]
**Espace de travail (Serveur) :** `/data/projet3/`
**Dépôt distant (GitHub) :** `https://github.com/yassineouahbi04-design/PTU_MASTER_projet3`

## Organisation de l'espace de travail et reproductibilité

  L'arborescence du projet a été restructurée par Yassine le 07/10/2026 pour garantir une séparation stricte des données, des environnements et des résultats. À la racine du projet, nous retrouvons les fichiers de documentation au format Markdown (`README.md`, `cahier_de_labo.md`, `rapport.md`) ainsi que le fichier `.gitignore`. 

  Les données et exécutions sont organisées dans les dossiers principaux suivants :

  * **`acanthaster_planci_ref_datas/` :** centralise l'annotation officielle (`annotation/`) et le génome de référence (`genome/`).

  * **`data_sets/` :** isole les données d'évidences biologiques. Il est scindé en :

    * `homology_data_set/` : contient la base protéique.
    * `RNAseq_data_set/` : contient les sous-dossiers classés par tissu (`gonad_dataset/`, `spine_dataset/`, `stomach_dataset/`), les données de test (`juvenile_data_set/`), l'espace de transit (`sra_downloads/`), le script d'extraction (`convert_rnaseq.sh`) et le fichier manifeste (`rnaseq_list.txt`).

  * **`annotation_datas/` :** ce répertoire maître regroupe toute l'activité et l'évaluation du pipeline. Il est subdivisé en :

    * `eviann_datas/` : contient l'historique des exécutions (`eviann_runs/`) et les fichiers finaux du pipeline (`eviann_results/`).

    * `gff_compare_results/` : contient les évaluations de l'annotation générée face à l'annotation officielle pour chaque run. 

  * **`fastqc_results/` :** répertoire dédié aux rapports de contrôle qualité des lectures.

  La reproductibilité est assurée par le répertoire `conda_environments`. Il contient les environnements virtuels, crés par Shahiran, isolant les dépendances logicielles : 
  
  * `env_ncbi` (`fasterq-dump` v3.4.1)
  * `env_fastqc` (`fastqc` v0.12.1)
  * `env_seqkit` (`seqkit` v2.14.0)
  * `env_eviann` (EviAnn v2.0.6)
  * `env_gff_compare` (`gffcompare` v0.12.10).
  
  Les fichiers de configuration exacts sont sauvegardés dans le sous-dossier `conda_env_exports`.

## Journal des sessions de travail

  **24/09/2026 — Acquisition du génome de référence**

  Yassine a initialisé le projet en téléchargeant l'assemblage de référence d'*Acanthaster planci* depuis le NCBI, puis l'a décompressé.
  ```bash
  mkdir -p /data/projet3/acanthaster_planci_ref_datas/genome/entier_genome/
  
  cd /data/projet3/acanthaster_planci_ref_datas/genome/entier_genome/

  wget "[https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/054/643/075/GCF_054643075.1_COTS_SCS/GCF_054643075.1_COTS_SCS_genomic.fna.gz]"

  gunzip -k GCF_054643075.1_COTS_SCS_genomic.fna.gz
  ```

  **26/09/2026 — Extraction des données test RNA-seq**

  Yassine a extrait les données transcriptomiques de test en paires FASTQ avec l'outil `fasterq-dump` depuis l'environnement `env_ncbi`. 

  Le choix de ces données s'est porté sur ce set pour des raisons purement techniques (test de faisabilité du pipeline et calibrage de l'empreinte mémoire), sans aucune logique biologique sous-jacente. 
  
  Les séquences brutes proviennent du projet NCBI d'accession `PRJNA1422445`, issu d'une étude portant sur le mécanisme d'influence des algues calcifiées sur la croissance et le développement des juvéniles d'étoiles de mer (réalisée par le South China Sea Institute of Oceanology). Cette dernière presente douze runs. Deux d'entre eux (`SRR37199246` et `SRR37199247`) on été choisit sur la base leurs taile (en paire de base), respectivement `8.48 G` et `8.29 G` (les plus élevés).   
  
  L'option `-t .` a été utilisée pour forcer l'écriture des fichiers temporaires dans le répertoire de projet, évitant la saturation de l'espace personnel.

  ```bash 

  conda activate /data/projet3/conda_environments/env_ncbi

  cd /data/projet3/data_sets/RNAseq_data_set/juvenile_data_set/

  fasterq-dump -t . --split-files SRR37199246
  fasterq-dump -t . --split-files SRR37199247
  ```
  
  **27/09/2026 — Test EviAnn**
  
  Un premier test du pipeline EviAnn a été initié par Yassine sur l'assemblage complet du génome au sein d'une session `screen` allouant 8 cœurs. Un fichier `rnaseq_list.txt` a été crée, regroupant les chemins des lectures de test appariées (`SRR37199246` et `SRR37199247`) avec la mention fastq en fin de ligne, pour satisfaire le parser d'EviAnn.    

  ```bash

  # Création du fichier rnaseq_list.txt
  ls /data/projet3/data_sets/RNAseq_data_set/juvenile_data_set/*.fastq > /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt

  # Lancement du pipeline EviAnn
  screen -S eviann_test_1
  
  conda conda_environments/env_eviann

  cd /data/projet3/annotation_datas/eviann_datas/eviann_runs/test_1_run
  
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/entier_genome/GCF_054643075.1_COTS_SCS_genomic.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa 
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt
  -t 8 2>&1 | tee eviann.log
  ``` 
  
  Le processus (tracé dans `test_1_run`) a été brutalement interrompu par le système (`Killed`) lors de l'étape d'alignement avec miniprot. Une seconde tentative sans multithreading (tracée dans `test_2_run`) a également échoué. 
  
  Le diagnostic a révélé que l'empreinte mémoire du génome complet saturait la RAM du serveur (déclenchement de l'OOM Killer).

  **28/09/2026 — Solution au problème EviAnn (run_1)**
  
  Après l’interruption des essais sur le génome entier faute de mémoire, Yassine a réparti le génome en deux fichiers avec SeqKit :

  ```bash
  # On activte l'environnement seqkit
  
  conda activate conda_environments/env_seqkit/
  
  # On lance la commande pour fragmenter le génome en deux

  seqkit split2 -p 2 GCF_054643075.1_COTS_SCS_genomic.fna -O split_genome/
  ```

  À l'aide de cet outil, le génome de référence a été scindé en deux sous-ensembles équilibrés en volume de paires de bases sans rompre aucun scaffold.

  EviAnn a ensuite été lancé séparément sur chaque partie. Les deux exécutions et leurs résultats sont rangés dans `annotation_datas/eviann_datas/eviann_runs/run_1/`, sous `genomic_part_001/` et `genomic_part_002/`.

  Les extraits des journaux EviAnn indiquent qu’un fichier d’annotation GFF a été produit pour chaque partie :

  | Résultat indiqué par EviAnn | Partie 001 | Partie 002 | Somme |
  |---|---:|---:|---:|
  | Genes | 9 559 | 9 013 | 18 572 |
  | Protein coding genes | 9 076 | 8 578 | 17 654 |
  | Processed pseudo gene transcripts | 34 | 31 | 65 |
  | Processed pseudo genes | 34 | 31 | 65 |
  | Transcripts | 17 137 | 16 395 | 33 532 |
  | Long non-coding RNAs | 456 | 407 | 863 |
  | Distinct proteins | 14 713 | 13 908 | 28 621 |

  La colonne « Somme » additionne les compteurs des deux exécutions. Les annotations GFF ont pas la suite été réunies et comparées à l’annotation de référence. On remarque néanmoins que la somme des protéines distinctes dénombrées dans chaque partie ne prouve pas qu’il existe 	22 342 protéines distinctes à l’échelle du génome complet, comme indiqué pour la référence.

  **08/10/2026 — Lancement du run 2 avec l’ensemble des données RNA-seq téléchargées**

  Yassine a relancé EviAnn dans `annotation_datas/eviann_datas/eviann_runs/run_2/genomic_part_001/`, sur la première partie du génome, en allouant 4 cœurs cette fois-ci et en utilisant toutes les données RNA-seq à disposition.   
  
  ```bash 
  # EviAnn a été lancer avec la commande suivante

  eviann.sh  
  -g /data/projet3 /acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna  
  -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa  
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt -t 4 2>&1 | tee eviann.log
  ```
  
  L’option `-r` désigne le fichier `rnaseq_list.txt`, qui regroupe les chemins des paires de fichiers RNA-seq utilisées pour cette exécution, comme expliquer précedement .

  Une première erreur provenait du chemin donné à `-r` : la commande indiquait `RNAseq_data_test` au lieu de `RNAseq_data_set`. Après cette correction, EviAnn a pu lire le manifeste et construire l’index HISAT2, mais l’alignement s’est arrêté avec le message suivant :

  ```text
  [main_samview] fail to read the header from "/dev/stdin".
  Alignment with HISAT2 or transcript assembly with StringTie failed
  ```

  La vérification des chemins à l’intérieur de `rnaseq_list.txt` a ensuite mis en évidence que certains fichiers FASTQ n’étaient pas désignés par le bon chemin. La recherche peut être reproduite avec cette commande, qui affiche le numéro de ligne et le chemin de chaque fichier absent ou vide :

  ```bash
  liste=/data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt

  awk 'NF >= 2 {print NR, $1; print NR, $2}' "$liste" |
  while read -r numero fichier; do
    [ -s "$fichier" ] ||
        printf 'Ligne %s — fichier absent ou vide : %s\n' "$numero" "$fichier"
  done
  ```

  Les chemins erronés du manifeste ont été corrigés, puis EviAnn a été relancé.

  **09/10/2026 — Diagnostic de l’échec du run 2**

  Le journal `eviann.log` indique que miniprot s’est une nouvelle fois arrêté avec le message `Killed` pendant l’alignement des protéines. Les fichiers intermédiaires nécessaires aux étapes suivantes n’ont pas été produits. Le GFF annoncé en fin d’exécution contient 0 gène et n’est pas exploitable.

  Afin de mieux comprendre le problème avec miniprot, ce dernier à été lancé seul sur le meme set de données (RNA-seq et homologie).
  Après avoir activé l’environnement `env_eviann`, nous avons relancé le test avec un seul cœur pour mesurer la mémoire utilisée par miniprot indépendamment d’EviAnn :

  ```bash
  conda conda_environements/env_eviann
  command -v miniprot

  /usr/bin/time -v miniprot -t 1 \
  /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna \
  /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa \
  > /dev/null 2> miniprot_test.log
  ```

  Le test s’est terminé correctement en `2 h 27 min`. Sa consommation maximale de mémoire a été de `7 365 152 Ko`, soit environ `7,0 Go`. Miniprot fonctionne donc seul avec un cœur sur ces données.

  Le test isolé de miniprot ayant réussi avec un cœur, un nouvel essai d’EviAnn a été lancé sur le même génome et avec les mêmes données, en utilisant deux cœurs :

  ```bash
  # Activation de l'environnement EviAnn
  conda conda_environments/env_eviann

  # Déplacement dans le dossier concerné
  cd /data/projet3/annotation_datas/eviann_datas/eviann_runs/run_2/genomic_part_001

  # Lancement du pipeline EviAnn
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt
  -t 2 2>&1 | tee eviann.log
  ```

  
  




  



  


  







  
  
