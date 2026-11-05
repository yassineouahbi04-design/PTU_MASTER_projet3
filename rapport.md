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

#### 3. Fusion des résultats des deux partitions

Les fichiers GFF obtenus après les deux exécutions d'EviAnn ont été fusionnés en conservant un seul en-tête, afin d'éviter la duplication des métadonnées. Les fichiers FASTA contenant les séquences protéiques prédites ont également été concaténés.

```bash
{
    head -3 part_001.gff
    tail -n +4 part_001.gff
    tail -n +4 part_002.gff
} > A_planci.gff

```

Cette étape a permis d'obtenir un fichier d'annotation GFF et un fichier FASTA protéique regroupant les résultats des deux partitions.

#### 4. Évaluation de l'annotation avec GffCompare**

Afin d'évaluer la qualité de l'annotation produite par EviAnn, GffCompare (version 0.12.10) a été utilisé dans un environnement Conda dédié (`env_gff_compare`). Le fichier GFF produit par EviAnn a été comparé à l'annotation de référence du NCBI.

La comparaison a été réalisée avec la commande suivante :

```bash
gffcompare \
    -r /data/projet3/acanthaster_planci_ref_datas/annotation/ref_annotation.gff \
    -o /data/projet3/annotation_datas/gff_compare_results/run_1_gffcompare_results/result \
    /data/projet3/annotation_datas/eviann_datas/eviann_results/run_1/proteine_annotation_file.gff
```

Les résultats ont été enregistrés dans le dossier `run_1_gffcompare_results`. Le fichier `result.stats` contient les principales statistiques permettant d'évaluer la concordance entre l'annotation prédite et l'annotation de référence.

La comparaison a donné une précision de **92,7 %** et une sensibilité de **60,9 %** au niveau des bases. Au niveau des transcrits, la précision était de **59,7 %** et la sensibilité de **43,4 %**. Pour les introns, la précision atteignait **96,6 %** et la sensibilité **77,4 %**.

Ces résultats indiquent que les introns prédits concordent globalement bien avec ceux de la référence. En revanche, la sensibilité plus faible au niveau des transcrits montre qu'une partie des transcrits présents dans l'annotation de référence n'a pas été retrouvée dans l'annotation produite par EviAnn.

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

#### 3. Fusion des résultats des deux partitions

Chaque exécution d’EviAnn produit, pour chaque partition, un fichier d’annotation au format GFF3 (`.fna.gff`) et un fichier FASTA des protéines prédites (`.fna.proteins.fasta`). EviAnn génère également plusieurs fichiers intermédiaires (alignements protéiques, transcrits, protéines non retenues) qui ne doivent pas être inclus dans l’annotation finale. Les fichiers ont donc été désignés par leur nom exact.

Pour obtenir l’annotation du génome complet, les deux fichiers GFF ont été fusionnés en ne conservant qu’un seul en-tête. L’en-tête de chaque fichier (3 lignes : version du format et identification du programme) a été vérifié au préalable avec `head -4`. Les fichiers protéiques, sans en-tête, ont été concaténés :

```bash
RUN=nom_du_run
P1=eviann_runs/$RUN/genomic_part_001/GCF_054643075.1_COTS_SCS_genomic.part_001.fna
P2=eviann_runs/$RUN/genomic_part_002/GCF_054643075.1_COTS_SCS_genomic.part_002.fna

{ head -3 $P1.gff; tail -n +4 $P1.gff; tail -n +4 $P2.gff; } > analyses/eviann_results/$RUN/proteine_annotation_file.gff
cat $P1.proteins.fasta $P2.proteins.fasta > analyses/eviann_results/$RUN/proteins_sequences_file.fasta
```

L’intégrité des fichiers fusionnés a été contrôlée en vérifiant :
- que leur taille correspond à la somme des fichiers des deux partitions ;
- que l’en-tête n’apparaît qu’une fois (`grep -c "gff-version"`) ;
- que le nombre de transcrits recensés par GffCompare est égal à la somme des transcrits et des ARN longs non codants annoncés par EviAnn pour les deux partitions.

#### 4. Évaluation des annotations avec GffCompare

La qualité des annotations a été évaluée avec GffCompare 0.12.10 (environnement `env_gff_compare`), par comparaison avec l’annotation de référence du NCBI (`ref_annotation.gff` : 47 324 transcrits, 22 001 loci) :

```bash
gffcompare -r acanthaster_planci_ref_datas/annotation/ref_annotation.gff \
  -o analyses/gff_compare_results/${RUN}_gffcompare_results/result \
  analyses/eviann_results/$RUN/proteine_annotation_file.gff
```

GffCompare compare la position et la structure de chaque élément prédit à celles de la référence. Deux métriques sont calculées à plusieurs niveaux (base, exon, intron, chaîne d’introns, transcrit, locus) :
- la **sensibilité**, proportion des éléments de la référence retrouvés par l’annotation, qui mesure sa complétude ;
- la **précision**, proportion des éléments prédits présents dans la référence, qui mesure sa justesse.

Les niveaux sont de plus en plus exigeants : un transcrit n’est considéré comme correct que si l’ensemble de ses introns correspond exactement à la référence. GffCompare indique également la proportion de loci manqués (présents dans la référence mais absents de l’annotation) et de loci nouveaux (prédits mais absents de la référence). Les résultats sont synthétisés dans le fichier `result.stats`.


#### 5. Contrôle qualité des données RNA-seq avec FastQC
Un contrôle qualité des données RNA-seq a été réalisé avec FastQC (version 0.12.1), installé dans un environnement Conda dédié (`env_fastqc`). Cette étape permet d’évaluer la qualité des séquences avant leur utilisation pour l’annotation du génome.

Les analyses concernent les échantillons de gonade, d’estomac, d’épines et deux réplicats de juvéniles. Les rapports ont été générés au format HTML, accompagnés de fichiers ZIP contenant les résultats détaillés.



---

## 3. Résultats

### 3.1. Plan expérimental

Cinq exécutions d’EviAnn ont été évaluées. Elles diffèrent par les données RNA-seq et les protéines d’homologie utilisées, de façon à isoler l’effet de chaque paramètre :

**Tableau 1.** Données utilisées pour chaque exécution d’EviAnn.

| Run | RNA-seq | Protéines d’homologie |
|---|---|---|
| Run_1 | 2 réplicats juvéniles | Asteroidea complet (139 392 séquences) |
| Run_2 | 5 échantillons : 2 juvéniles, gonade, épine, estomac | Asteroidea complet |
| Juvéniles trimés | 2 réplicats juvéniles trimés | Asteroidea sans *A. planci* (98 124 séquences) |
| All RNA-seq, prot. filtrées | 5 échantillons | Asteroidea sans *A. planci* |
| All RNA-seq juv. trimés, prot. filtrées | 5 échantillons, juvéniles trimés | Asteroidea sans *A. planci* |

Une sixième exécution, intégrant de nouveaux tissus (nerf, podia), était en cours au moment de la rédaction et n’a pas pu être évaluée.

### 3.2. Comparaison avec l’annotation de référence

**Tableau 2.** Résultats GffCompare des cinq annotations par rapport à l’annotation de référence du NCBI (sensibilité / précision, en %).

| Niveau | Run_1 | Run_2 | Juvéniles trimés | All RNA-seq, prot. filtrées | All RNA-seq juv. trimés, prot. filtrées |
|---|---|---|---|---|---|
| Base | 60,9 / 92,7 | 73,2 / 85,8 | 56,0 / 91,7 | 66,1 / 85,6 | 66,4 / 85,6 |
| Exon | 68,2 / 81,6 | 76,4 / 78,0 | 60,6 / 84,0 | 67,8 / 80,1 | 68,0 / 80,0 |
| Intron | 77,4 / 96,6 | 85,6 / 93,0 | 66,8 / 95,3 | 74,9 / 93,0 | 75,1 / 92,8 |
| Chaîne d’introns | 44,7 / 62,6 | 53,5 / 52,6 | 34,2 / 59,5 | 40,9 / 50,9 | 41,3 / 50,6 |
| Transcrit | 43,4 / 59,7 | 52,0 / 51,2 | 32,9 / 57,9 | 39,5 / 50,0 | 39,8 / 49,8 |
| Locus | 62,5 / 74,5 | 69,9 / 77,4 | 53,3 / 77,8 | 59,3 / 77,0 | 59,5 / 77,1 |
| Loci manqués | 20,3 % | 15,4 % | 33,2 % | 26,4 % | 26,2 % |
| Loci nouveaux | 3,8 % | 6,0 % | 3,4 % | 5,5 % | 5,6 % |
| Transcrits prédits | 34 395 | 48 062 | 26 898 | 37 350 | 37 875 |
| Transcrits par locus | 1,9 | 2,5 | 1,8 | 2,2 | 2,3 |

Dans les cinq exécutions, la précision reste élevée aux niveaux base (85,6 à 92,7 %) et intron (92,8 à 96,6 %). La sensibilité varie davantage : de 66,8 à 85,6 % au niveau des introns, et de 15,4 à 33,2 % de loci manqués. Dans tous les cas, les scores diminuent du niveau intron au niveau transcrit.

### 3.3. Effet de chaque paramètre

**Tableau 3.** Comparaisons entre exécutions ne différant que par un seul paramètre.

| Comparaison | Paramètre modifié | Loci manqués | Sensibilité transcrit |
|---|---|---|---|
| Run_1 → Run_2 | Ajout de tissus | 20,3 → 15,4 % | 43,4 → 52,0 % |
| Juvéniles trimés → All RNA-seq juv. trimés, prot. filtrées | Ajout de tissus | 33,2 → 26,2 % | 32,9 → 39,8 % |
| Run_2 → All RNA-seq, prot. filtrées | Retrait des protéines d’*A. planci* | 15,4 → 26,4 % | 52,0 → 39,5 % |
| All RNA-seq, prot. filtrées → All RNA-seq juv. trimés, prot. filtrées | Trimming des juvéniles | 26,4 → 26,2 % | 39,5 → 39,8 % |

---

## 4. Discussion

### 4.1. Une annotation précise mais incomplète

Les cinq annotations présentent une précision élevée : les éléments prédits par EviAnn correspondent en grande majorité à la référence, en particulier les introns. Leur principale limite est la sensibilité, puisqu’une partie des gènes de la référence n’est pas retrouvée. La baisse des scores entre le niveau intron et le niveau transcrit est attendue : il suffit d’une seule erreur d’exon pour qu’un transcrit entier soit compté comme incorrect.

### 4.2. Effet de la diversité tissulaire du RNA-seq

L’ajout des tissus gonade, épine et estomac augmente la sensibilité, que le jeu d’homologie contienne ou non les protéines d’*A. planci* (5 et 7 points de loci manqués en moins). Tous les gènes ne sont pas exprimés dans les mêmes tissus ni au même stade de développement : multiplier les tissus permet donc de détecter des gènes absents du transcriptome juvénile.

Cette amélioration s’accompagne d’une légère baisse de la précision, liée à l’augmentation du nombre de transcrits et d’isoformes prédits. Ces éléments absents de la référence ne sont pas nécessairement des erreurs : l’annotation du NCBI n’est pas exhaustive, et certains transcrits spécifiques à un tissu peuvent y être absents.

### 4.3. Effet des protéines d’homologie

Le retrait des 41 268 protéines d’*A. planci* du jeu d’homologie est le paramètre qui a le plus d’impact : à données RNA-seq identiques, les loci manqués passent de 15,4 à 26,4 % et la sensibilité au niveau des transcrits de 52,0 à 39,5 %, alors que la précision reste stable. Ces protéines sont vraisemblablement issues de l’annotation NCBI, qui sert également de référence pour l’évaluation. Les exécutions qui les incluaient (run_1 et run_2) disposaient donc d’une partie de la « réponse », ce qui surestime leurs scores.

### 4.4. Effet du trimming

Le trimming des lectures juvéniles n’a pratiquement aucun effet (moins de 0,5 point d’écart sur l’ensemble des métriques). EviAnn tolère donc la présence d’adaptateurs dans les lectures, probablement parce que l’aligneur HISAT2 ignore les extrémités qui ne s’alignent pas (soft-clipping). La baisse de sensibilité observée pour le run juvéniles trimés s’explique donc par le retrait des protéines d’*A. planci*, et non par le trimming.

### 4.5. Estimation réaliste et perspectives

L’exécution combinant les cinq échantillons RNA-seq et le jeu d’homologie filtré constitue l’estimation la plus réaliste des performances d’EviAnn sur un génome non annoté, comme celui de *Coscinasterias tenuispina*. EviAnn y retrouve 75,1 % des introns et 59,5 % des loci de la référence, avec une précision de 92,8 % au niveau des introns. Ces résultats suggèrent de privilégier la diversité tissulaire du RNA-seq, et de ne pas considérer le trimming comme une étape prioritaire.

L’évaluation repose cependant uniquement sur la comparaison avec l’annotation du NCBI, supposée complète et correcte. Deux outils complémentaires auraient permis de dépasser cette limite :
- **BUSCO**, qui mesure la complétude d’une annotation à partir de gènes conservés en copie unique, indépendamment de toute référence : c’est la seule approche applicable à *C. tenuispina* ;
- **AGAT**, qui fournit des statistiques descriptives sur les gènes (longueur, nombre d’exons, longueur des introns), et aurait permis de caractériser les erreurs de structure.

Ces analyses n’ont pas pu être réalisées en raison des contraintes de mémoire vive et d’espace disque du serveur, qui ont fortement ralenti les exécutions d’EviAnn et empêché l’installation de BUSCO.