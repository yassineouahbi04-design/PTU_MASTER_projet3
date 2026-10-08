# Cahier de laboratoire — Annotation structurale du génome d'Acanthaster planci

---

## 1. Introduction

  Ce projet est consacré à l'annotation structurale critique du génome d'*Acanthaster planci*, une espèce d'échinoderme communément appelée l'étoile de mer « couronne d'épines ». Cet organisme présente un intérêt écologique et biologique majeur : en tant que prédateur corallivore réputé pour ses épisodes de prolifération destructeurs sur les récifs coralliens, disposer d'une annotation précise de ses gènes est indispensable pour étudier les bases moléculaires de son développement, de sa toxicité et de sa physiologie. L'objectif scientifique consiste à déployer le pipeline moderne d'annotation automatique EviAnn (version 2.0.6, développé par Aleksey Zimin et publié dans *Nature Methods*). Cet outil intègre deux sources majeures d'évidences biologiques pour reconstruire la structure des gènes : des données transcriptomiques issues du séquençage d'ARN (RNA-seq) alignées avec HISAT2 et assemblées avec StringTie, ainsi que des alignements de protéines homologues issus d'espèces proches réalisés via miniprot.

  L'enjeu central de cette étude ne réside pas uniquement dans l'obtention d'une annotation brute, mais dans l'optimisation rationnelle des ressources de calcul et des jeux de données d'entrée. Sur le plan méthodologique, nous cherchons à définir le plan expérimental optimal : identifier la quantité minimale de données nécessaire pour atteindre une annotation de haute fidélité, tout en évaluant l'impact de la diversité tissulaire du RNA-seq et de la distance phylogénétique des protéines d'homologie (au sein des *Asteroidea* ou d'autres clades d'échinodermes). Pour évaluer la qualité des prédictions, les annotations obtenues seront confrontées à l'annotation officielle du NCBI via l'outil GffCompare (analyse de la sensibilité, de la précision et de la structure exonique) et des métriques de complétude génique via BUSCO. À terme, les protocoles optimisés sur *Acanthaster planci* serviront de guide pour annoter un génome d'échinoderme non annoté, tel que *Coscinasterias tenuispina*.

  Dans ce cadre, ce document formalise le rapport d'étape de la Phase 1. Cette phase préliminaire se concentre sur la validation technique et le calibrage matériel : tester le comportement d'EviAnn sur le serveur universitaire partagé `ptu.bigest-icube.fr`, diagnostiquer les limites imposées par la mémoire vive (RAM), et concevoir une stratégie de partitionnement génomique garantissant l'intégrité biologique des séquences.

---

## 2. Matériel et méthodes

### 2.1. Plateforme d'exécution et gestion collaborative
  Les opérations sont exécutées sur le serveur universitaire mutualisé `ptu.bigest-icube.fr` (architecture x86_64, Ubuntu 24.04.4 LTS, noyau Linux `6.8.0-139-generic`). Les calculs et analyses sont centralisés dans le répertoire de travail partagé `/data/projet3`.
  * **Politique d'accès :** Propriétaire `ouahbi`, groupe système `projet3` configuré en `rwx` pour permettre une édition transparente par l'ensemble des collaborateurs du projet, et droits `r-x` pour les tiers et l'enseignant.
  * **Persistance des processus :** Les commandes longues sont exécutées au sein de sessions `screen` détachables (`Ctrl + A` puis `D`), maintenant les calculs en tâche de fond indépendamment des déconnexions du terminal.
  * **Gestion de version :** Suivi sous Git (v2.43.0) couplé à un fichier `.gitignore` filtrant explicitement les fichiers volumineux (> 50 Mo) pour respecter les contraintes de GitHub (séquences FASTA/FASTQ, index HISAT2 `.ht2`, fichiers temporaires `.tmp`, répertoires de données).

### 2.2. Gestion des environnements virtuels (Conda) (metre les versions)
  Afin d'éviter tout conflit de dépendances logicielles (*dependency hell*) et garantir une isolation stricte des outils, plusieurs environnements dédiés ont été déployés dans le répertoire partagé `conda_environments/` :
  * **`env_ncbi` :** environnement dédié à l'acquisition des données publiques, incluant les outils de requêtage NCBI et le SRA-Toolkit (`fasterq-dump`).
  * **`env_fastqc` :** environnement réservé à l'évaluation et au contrôle qualité des lectures brutes de séquençage RNA-seq (FastQC).
  * **`env_seqkit` :** environnement mobilisé pour les statistiques descriptives et le partitionnement équilibré des assemblages FASTA (`seqkit`).
  * **`env_eviann` :** environnement maître intégrant le pipeline EviAnn et son écosystème d'alignement, d'assemblage et de prédiction (HISAT2, StringTie, TransDecoder, `miniprot`).
  * **`env_gff_compare` :** environnement dédié à l'évaluation comparative des annotations et au calcul des métriques de précision/sensibilité (`gffcompare`).
  * **`conda_env_exports/` :** répertoire d'archivage des exports d'environnements (fichiers de spécification `.yml`), assurant la traçabilité et la reproductibilité expérimentale complète du projet.

### 2.3. Organisation et acquisition des données d'entrée

  L'ensemble des données brutes et intermédiaires est organisé sous deux répertoires principaux afin de séparer les données propres à l'organisme de référence des jeux de données d'évidences biologiques (homologie et transcriptomique) :

  #### 1. Données de référence de l'organisme (`acanthaster_planci_ref_datas/`)
  Ce dossier centralise le matériel génomique et l'annotation officielle :
  * **`annotation/` :** contient le fichier d'annotation de référence NCBI (`ref_annotation.gff`) destiné à l'évaluation comparative des performances d'EviAnn via GffCompare lors de la Phase 3.
  * **`genome/` :** structure le matériel de séquence nucléotidique :
    * `entier_genome/` : héberge l'assemblage complet original d'*Acanthaster planci* (`GCF_054643075.1_COTS_SCS`).
    * `split_genome/` : regroupe les deux sous-ensembles équilibrés générés par `seqkit split2` (`part_001.fna` et `part_002.fna`) pour l'exécution séquentielle sous contrainte mémoire.

  #### 2. Jeux de données d'évidences biologiques (`data_sets/`)
  Ce répertoire isole les données alimentant les modules prédictifs du pipeline :
  * **`homology_data_set/` :** contient la base de données de protéines homologues du clade des *Asteroidea* (`asteroidea_proteins.faa`).
  * **`RNAseq_data_set/` :** regroupe les séquences transcriptomiques structurées par condition et tissu afin de préparer le plan expérimental de la Phase 2 (évaluation de la diversité tissulaire) :
  * `test_data_set/` : données transcriptomiques initiales mobilisées pour les tests techniques de la Phase 1.
  * `gonad_dataset/` : données RNA-seq spécifiques des gonades.
  * `spine_dataset/` : données RNA-seq isolées des épines.
  * `stomach_dataset/` : données RNA-seq prélevées sur l'estomac.
  * `sra_downloads/` : espace de transit pour le téléchargement brut des archives SRA depuis le NCBI.
  * `convert_rnaseq.sh` : script shell automatisant l'extraction des archives SRA en paires de fichiers FASTQ avec gestion de l'espace temporaire local.
  * `rnaseq_list.txt` : fichier répertoriant les chemins absolus des paires de lectures FASTQ formaté selon les exigences du parseur d'EviAnn.

### 2.4. Test et optimisation du protocole d'annotation (Pipeline EviAnn)
  La conception du protocole final d'exécution a nécessité une phase d'ajustement face aux contraintes matérielles du serveur lors de l'utilisation du pipeline EviAnn.

  #### 1. Phase de calibrage et limites matérielles
  Les premières exécutions sur l'assemblage complet d'*Acanthaster planci* ont été menées dans les espaces de travail `eviann_runs/eviann_test_run/` et `eviann_runs/eviann_test_2_run/`. 
  
  * **Tentative multithreadée (`-t 8`) :** interrompue par l'OOM Killer (*Out Of Memory Killer*) du noyau Linux lors de l'étape d'alignement des protéines homologues via `miniprot`, en raison de l'empreinte mémoire beacoup trop importante.
  
  * **Tentative séquentielle :** relancée sans l'argument `-t 8` pour contraindre la charge mémoire à un seul thread, cette exécution a également abouti à un échec (`Killed`) au même stade, confirmant que l'indexation de la base protéique sur la totalité du génome dépassait intrinsèquement la capacité physique en RAM de la machine. 

  #### 2. Protocole final retenu (partitionnement)
  Pour surmonter cette limitation technique, un partitionnement du génome et une exécution séquentielle par lots a été effectué:
  
  1. **Partitionnement :** le génome a été découpé en deux sous-ensembles équilibrés en volume cumulé de paires de bases via `seqkit split2 -p 2` (`genomic_part_001.fna` et `genomic_part_002.fna`), sans altérer l'intégrité des scaffolds.

  2. **Exécution :** la réduction par deux de l'assemblage a permis de maintenir la charge mémoire sous le seuil critique. La commande type, exécutée au sein d'une session `screen` depuis le répertoire `eviann_runs/eviann_run_1/`, est la suivante :
   ```bash
   eviann.sh \
     -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna \
     -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa \
     -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt \
     -t 8 2>&1 | tee eviann_runs/eviann_run_1/eviann_p1.log
  ```
