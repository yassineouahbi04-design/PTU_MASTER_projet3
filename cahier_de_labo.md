# Cahier de laboratoire

Ce cahier retrace les différentes étapes du projet. Il contient les tâches réalisées par chaque membre du groupe, les données utilisées et leur localisation, les outils et leurs versions, ainsi que les commandes et scripts exécutés.


Etape 1 : récupération des données de référence

•	Identifier l'accès au génome : Trouver la bonne référence officielle d'Acanthaster planci sur le NCBI.

•	Télécharger les fichiers indispensables : Récupérer d'un côté la séquence du génome (FASTA) et de l'autre l'annotation de référence (GFF3).

•	Organiser et nettoyer l'espace de travail : Ranger ces fichiers dans un dossier dédié sur le serveur et configurer le .gitignore pour éviter de les envoyer par erreur sur GitHub. Masquer les dossiers cachés (ceux qui commencent par un point comme .ssh ou .cache) avec Files: Exclude (**/.*).

•	Création et activation de l'environnement personnel pour contourner les restrictions d'écriture globales avec conda activate .

•	Installation de l'outil datasets dans env_sa avec conda install -c conda-forge ncbi-datasets-cli et téléchargement du génome de référence GCF_054643075.1 avec datasets download genome accession GCF_054643075.1 --include genome, puis décompression avec unzip ncbi_dataset.zip.




Etape 2 :  Lancement et configuration d'EviAnn

•   Tentative 1 : Lancement d’EviAnn dans une session screen, avec le génome, les protéines homologues et les données RNA-seq, en utilisant 8 cœurs.
Enregistrement du calcul : Les traces d’exécution sont enregistrées dans eviann.log.
--> Échec du lancement : Le calcul s’est arrêté lors de l’alignement avec Miniprot en raison d’un manque de mémoire RAM.

•   Tentative 2 :  Nouveau lancement, mais blocage pour la meme raison .

•   Partitionnement du génome : Division du génome en deux parties à l’aide de Seqkit, puis annotation séparée de chaque partie avec EviAnn afin de réduire la consommation mémoire.

•   Les deux annotations obtenues sont ensuite réunies pour reconstituer l’annotation complète du génome.

---

01/10 

Deux exécutions d’EviAnn ont été réalisées sur les partitions genomic_part_001 et genomic_part_002, permettant d'obtenir pour chacune un fichier GFF3 d’annotation et un fichier FASTA de protéines prédites. Les deux GFF3 ont été fusionnés en conservant un seul en-tête à l’aide de head et tail :

{
  head -3 part_001.gff
  tail -n +4 part_001.gff
  tail -n +4 part_002.gff
} > A_planci.gff

Les fichiers protéiques ne possédant pas d’en-tête commune, ils ont simplement été concaténés avec cat :
cat part_001.proteins.fasta part_002.proteins.fasta > A_planci.proteins.fasta

Les fichiers finaux A_planci.gff (~88 Mo) et A_planci.proteins.fasta (~24 Mo) sont stockés dans /data/projet3/annotation_complete/. Les fichiers originaux des deux partitions ont été conservés.

---
02/10
Évaluation de l’annotation EviAnn par comparaison avec le génome de référence

Afin d’évaluer l’annotation produite par EviAnn, l’annotation génomique de référence correspondant au même assemblage a également été récupérée à l’aide de NCBI Datasets dans l’environnement Conda env_sa.

Le fichier d’annotation de référence genomic.gff a été extrait puis renommé en genome_ref.gff. Il a été placé dans /data/projet3/annotation_complete/, avec le fichier d’annotation EviAnn A_planci.gff et le fichier de protéines prédites A_planci.proteins.fasta.

L’outil gffcompare 0.12.10 a ensuite été installé dans l’environnement partagé env_sa. Les permissions de cet environnement ont été configurées afin que les membres du groupe projet3 puissent utiliser les outils qui y sont installés, sans pouvoir les modifier.

Les fichiers nécessaires à l’évaluation sont ainsi regroupés dans /data/projet3/annotation_complete/ :
A_planci.gff (proteine_annotation_file.gff)
A_planci.proteins.fasta (proteins_sequences_file.fasta)
genome_ref.gff(ref_annotation.gff)



### Comparaison de l’annotation EviAnn avec l’annotation de référence

Afin d’évaluer la qualité de l’annotation produite par EviAnn, une annotation de référence correspondant au même assemblage génomique (*Acanthaster planci*, `GCF_054643075.1`) a été récupérée à l’aide de **NCBI Datasets**.

Le fichier d’annotation de référence a été placé dans :

```text
/data/projet3/acanthaster_planci_datas/annotation/ref_annotation.gff
```

L’annotation produite par EviAnn correspond au fichier :

```text
/data/projet3/eviann_annotations/eviann_split_genome_1/proteine_annotation_file.gff
```

L’outil **gffcompare 0.12.10** a été utilisé pour comparer l’annotation EviAnn à l’annotation de référence. Un problème de permissions empêchait initialement la création des fichiers de sortie dans le dossier contenant l’annotation EviAnn. Le fichier d’annotation a donc été copié dans un dossier de travail accessible, puis la comparaison a été réalisée à partir de cette copie.

Les résultats de la comparaison ont ensuite été placés dans :

```text
/data/projet3/eviann_annotations/gffcompare_result/
```

Les principaux résultats obtenus sont :

* **34 395** transcrits EviAnn contre **47 324** transcrits de référence.
* Sensibilité au niveau des transcrits : **43,4 %**.
* Précision au niveau des transcrits : **59,7 %**.
* Sensibilité au niveau des introns : **77,4 %**.
* Précision au niveau des introns : **96,6 %**.
* **20 535** transcrits présentent une correspondance avec la référence.
* **13 755** loci présentent une correspondance avec la référence.
* **700 loci** sont considérés comme nouveaux par rapport à la référence.

Ces résultats indiquent que l’annotation EviAnn présente une **bonne précision**, notamment au niveau des introns, mais une **sensibilité plus modérée**, en particulier au niveau des transcrits. Une partie des transcrits présents dans l’annotation de référence n’est donc pas retrouvée par EviAnn.

### Mise à disposition de GFFCompare

L’outil **GFFCompare 0.12.10** a été installé dans l’environnement Conda partagé :

```text
/data/projet3/conda/env_sa
```

Les permissions de cet environnement ont été modifiées afin que les membres du groupe `projet3` puissent **lire, modifier et ajouter des logiciels** dans cet environnement partagé.

Pour l’activer :

```bash
conda activate /data/projet3/conda/env_sa
```

Ainsi, les membres du projet peuvent utiliser GFFCompare et installer d’autres outils nécessaires dans le même environnement.



---

# **Étudiant :** Shahiran Kuganaathan  
**Projet :** Annotation du génome d'*Acanthaster planci*  
**Génome utilisé :** `GCF_054643075.1_COTS_SCS` (2026)


## 20/09/2026 — Préparation des environnements Conda

Au début du projet, un dossier contenant des environnements Conda était déjà disponible. Cependant, je n'avais pas les permissions nécessaires pour y créer de nouveaux environnements ou installer d'autres logiciels.

J'ai donc créé temporairement mes propres répertoires pour pouvoir avancer, notamment sur le téléchargement des protéines homologues nécessaires à l'annotation.

### Création des répertoires

```bash
mkdir conda_temporaire
mkdir conda_environment_exports/
```

Le dossier `conda_temporaire` servait à installer les environnements dont j'avais besoin. J'ai également créé `conda_environment_exports` pour conserver les fichiers YAML décrivant les environnements et leurs dépendances, afin de pouvoir les recréer si nécessaire.

Les dossiers ont ensuite été réorganisés par Yassine : `conda_temporaire` a été renommé en `conda_environments`, et les exports se trouvent maintenant dans `conda_environments/conda_env_exports/`.

### Création de l'environnement pour Entrez Direct

Pour récupérer les protéines homologues depuis NCBI, j'ai utilisé Entrez Direct. Cet outil permet de rechercher et de télécharger des séquences directement depuis le terminal, sans avoir à les récupérer une par une sur le site de NCBI.

J'ai créé un environnement Conda pour installer l'outil :

```bash
conda create -p /data/projet3/conda_temporaire/env_ncbi
conda activate /data/projet3/conda_temporaire/env_ncbi
conda install -c bioconda entrez-direct
```

J'ai ensuite vérifié que les commandes étaient accessibles :

```bash
which esearch
which efetch
```

`esearch` sert à rechercher des entrées dans les bases NCBI, tandis que `efetch` permet de récupérer les séquences dans le format souhaité, ici en FASTA.

**Version d'Entrez Direct :** 26.0.

### Création du cahier de laboratoire et gestion des permissions

J'ai créé le fichier du cahier de laboratoire :

```bash
touch cahier_de_labo.md
```

J'ai également modifié les permissions de plusieurs fichiers et dossiers utilisés dans le projet :

```bash
chmod 775 cahier_de_labo.md
chmod 775 conda_environment_exports/
chmod 775 homology_data_test/
chmod 775 conda_temporaire/
```

---

## 20/09/2026 — Recherche et téléchargement des protéines homologues

Avant le téléchargement, j'ai consulté le README d'EviAnn pour connaître les recommandations concernant les protéines homologues utilisées pour l'annotation.

La documentation conseille de fournir des protéines provenant de plusieurs espèces apparentées, avec idéalement **5 à 10 fois plus de séquences que le nombre de protéines attendu** chez l'espèce étudiée.

**Documentation :** https://github.com/alekseyzimin/EviAnn_release/blob/main/README.md

Pour *Acanthaster planci*, l'annotation NCBI du génome `GCF_054643075.1` (2026) indique **18 608 gènes codant des protéines**. J'ai donc pris comme ordre de grandeur un ensemble d'environ **93 040 à 186 080 séquences protéiques homologues**.

J'ai choisi la classe **Asteroidea**, qui regroupe les étoiles de mer, dont *Acanthaster planci*, afin de récupérer des protéines d'organismes proches. Son identifiant taxonomique NCBI est `7588`.

### Téléchargement des protéines

J'ai créé un dossier pour le téléchargement :

```bash
mkdir homology_data_test
```

J'ai ensuite ouvert une session Screen pour laisser le téléchargement se poursuivre sur le serveur en cas de déconnexion SSH :

```bash
screen -S download_proteins
```

Dans cette session, j'ai utilisé la commande suivante :

```bash
esearch -db protein -query "txid7588[Organism:exp]" | efetch -format fasta > asteroidea_proteins.faa
```

La requête récupère les séquences protéiques associées à la classe Asteroidea, sous-groupes inclus, et les enregistre au format FASTA.

### Vérification du téléchargement

Après le téléchargement, j'ai vérifié la présence et la taille du fichier :

```bash
ls -lh /data/projet3/homology_data_test/asteroidea_proteins.faa
```

J'ai ensuite compté les entrées FASTA, identifiées par les lignes commençant par `>` :

```bash
grep -c '^>' /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa
```

**Résultat :** 139 392 séquences protéiques, pour un fichier d'environ 104 Mo.

Cela correspond à environ 7,5 fois les 18 608 gènes codants de l'annotation de référence, ce qui se situe dans la fourchette recommandée par EviAnn.

Après réorganisation des dossiers, le fichier est conservé ici :

`/data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa`

---

## 29/09/2026 – 30/09/2026 — Recherche et téléchargement de données RNA-seq supplémentaires

### Choix des données RNA-seq

Pour l'annotation, nous avions besoin de données RNA-seq provenant de **plusieurs tissus et stades de développement**. Tous les gènes ne sont pas exprimés dans les mêmes tissus ni au même moment : utiliser différents échantillons permet donc d'obtenir des informations sur davantage de transcrits.

Deux échantillons juvéniles étaient déjà disponibles dans le projet. J'ai recherché sur NCBI SRA des données provenant d'autres tissus pour les compléter.

J'ai retenu les accessions suivantes :

- **Gonad :** `SRR37114952`
- **Spine :** `SRR37114948`
- **Stomach :** `SRR37114954`

### Téléchargement des données

Pour récupérer les données RNA-seq depuis NCBI, j'ai utilisé SRA Toolkit, notamment `prefetch`, qui permet de télécharger les fichiers associés aux accessions SRA.

J'ai lancé les téléchargements dans une session Screen :

```bash
screen -S download_rnaseq
```

**Commandes de téléchargement :**

```bash
prefetch SRR37114952 -O /data/projet3/data_sets/RNAseq_data_test/sra_downloads

prefetch SRR37114948 -O /data/projet3/data_sets/RNAseq_data_test/sra_downloads

prefetch SRR37114954 -O /data/projet3/data_sets/RNAseq_data_test/sra_downloads
```

Ces commandes correspondent respectivement aux échantillons Gonad, Spine et Stomach. L'option `-O` permet de préciser le chemin de sortie.

---

## 29/09/2026 – 30/09/2026 — Conversion des fichiers SRA en FASTQ

**Outil :** SRA Toolkit 3.4.1  
**Script :** `/data/projet3/data_sets/RNAseq_data_set/convert_rnaseq.sh`

Après le téléchargement, j'ai converti les trois échantillons SRA au format FASTQ pour pouvoir utiliser les lectures dans les analyses suivantes.

J'ai écrit le script Bash `convert_rnaseq.sh` pour conserver les commandes et effectuer les conversions des trois échantillons.

### Script utilisé

```bash
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
```

L'option `--split-files` permet d'obtenir les deux fichiers de lectures appariées (`_1.fastq` et `_2.fastq`). J'ai utilisé deux threads (`-e 2`), un dossier temporaire défini avec `-t` et un dossier de sortie défini avec `-O`. La commande `set -e` arrête le script en cas d'erreur.

À la fin du script, j'ai ajouté les commandes suivantes pour supprimer les fichiers SRA téléchargés et le dossier temporaire une fois les conversions terminées :

```bash
rm -rf "$BASE/sra_downloads/SRR37114952"
rm -rf "$BASE/sra_downloads/SRR37114948"
rm -rf "$BASE/sra_downloads/SRR37114954"
rm -rf "$TMP"
```

---

## 29/09/2026 — Installation de FastQC et contrôle qualité des données juvéniles

**Outil :** FastQC 0.12.1

J'ai utilisé FastQC pour contrôler la qualité des données RNA-seq avant leur utilisation dans l'annotation. J'ai créé un environnement Conda dédié afin d'installer le logiciel sans modifier les autres environnements du projet.

### Création de l'environnement FastQC

```bash
conda create -p /data/projet3/conda_temporaire/env_fastqc -c conda-forge -c bioconda fastqc
conda activate /data/projet3/conda_temporaire/env_fastqc
fastqc --version
```

Après réorganisation des dossiers, l'environnement se trouve dans :

`/data/projet3/conda_environments/env_fastqc`

### Contrôle qualité des échantillons juvéniles

J'ai lancé FastQC avec quatre threads sur les deux échantillons juvéniles déjà disponibles dans le projet :

```bash
fastqc -t 4 -o /data/projet3/fastqc_results \
/data/projet3/data_sets/RNAseq_data_test/SRR37199246_dataset/SRR37199246_1.fastq \
/data/projet3/data_sets/RNAseq_data_test/SRR37199246_dataset/SRR37199246_2.fastq \
/data/projet3/data_sets/RNAseq_data_test/SRR37199247_dataset/SRR37199247_1.fastq \
/data/projet3/data_sets/RNAseq_data_test/SRR37199247_dataset/SRR37199247_2.fastq
```

Les résultats ont été enregistrés dans `fastqc_results`. J'ai créé deux dossiers pour séparer les rapports :

```bash
mkdir -p Juvenile_Replicat1 Juvenile_Replicat2
mv SRR37199247_* Juvenile_Replicat1/
mv SRR37199246_* Juvenile_Replicat2/
```

Les rapports HTML et ZIP ont été générés pour les quatre fichiers FASTQ.

### Consultation des rapports

J'ai consulté les rapports FastQC pour repérer d'éventuels problèmes de qualité. Dans les deux échantillons juvéniles, `Adapter Content` présente un statut **FAIL**, avec une augmentation des adaptateurs Illumina vers la fin des lectures.

Ces résultats m'ont amené à envisager un **trimming des adaptateurs**, puis une nouvelle annotation avec EviAnn pour comparer les résultats obtenus avec des lectures nettoyées et non nettoyées.

---

## 08/10/2026 — Contrôle qualité des autres échantillons RNA-seq

**Outil :** FastQC 0.12.1  
**Script :** `/data/projet3/fastqc_results/run_fastqc.sh`

J'ai ensuite lancé FastQC sur les trois échantillons supplémentaires : Gonad, Stomach et Spine. J'ai écrit un script Bash pour garder les commandes utilisées et lancer les contrôles qualité par tissu.

### Script utilisé

```bash
#!/bin/bash

DATA="/data/projet3/data_sets/RNAseq_data_set"
OUT="/data/projet3/fastqc_results"

echo "Début FastQC Gonad"
fastqc -t 4 -o "$OUT/Gonad" "$DATA"/gonad_dataset/*.fastq

echo "Début FastQC Stomach"
fastqc -t 4 -o "$OUT/Stomach" "$DATA"/stomach_dataset/*.fastq

echo "Début FastQC Spine"
fastqc -t 4 -o "$OUT/Spine" "$DATA"/spine_dataset/*.fastq
```

Pour chaque tissu, FastQC utilise quatre threads (`-t 4`). Les rapports sont enregistrés dans des sous-dossiers distincts de `fastqc_results`.

---

## 10/10/2026 — Lancement d'EviAnn sur la deuxième partie du génome

J'ai lancé EviAnn sur la deuxième partie du génome d'*Acanthaster planci* (`part_002`), avec les données RNA-seq des cinq échantillons disponibles : Gonad, Spine, Stomach et les deux échantillons juvéniles.

J'ai également utilisé le fichier de **139 392 séquences protéiques homologues** des Asteroidea téléchargé précédemment.

### Commande utilisée

```bash
eviann.sh -t 2 \
-g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_002.fna \
-r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt \
-p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa \
--verbose > eviann_run2_part002.log 2>&1
```

Options utilisées :

- `-t 2` : utilise deux threads.
- `-g` : indique le fichier FASTA de la deuxième partie du génome.
- `-r` : indique le fichier contenant la liste des données RNA-seq.
- `-p` : indique le fichier FASTA des protéines homologues.
- `--verbose` : affiche les messages détaillés du programme.
- `> eviann_run2_part002.log 2>&1` : enregistre la sortie standard et les messages d'erreur dans un fichier log.

---

## Suite envisagée

À partir des résultats FastQC des échantillons juvéniles, je souhaite tester un trimming des adaptateurs. L'objectif est ensuite de relancer EviAnn avec les lectures nettoyées et de comparer les résultats avec ceux de l'analyse réalisée sans trimming.

**Cette étape n'a pas encore été réalisée.**

---

# **Étudiant :** Ouahbi Yassine

**Membres du groupe :** Yassine OAUHBI, Shahiran KUGANAATHAN, Sarah AMZALLAG

**Espace de travail (Serveur) :** `/data/projet3/`

**Dépôt distant (GitHub) :** `https://github.com/yassineouahbi04-design/PTU_MASTER_projet3`

## Organisation de l'espace de travail et reproductibilité

  L'arborescence du projet a été restructurée le 07/10/2026 pour garantir une séparation stricte des données, des environnements et des résultats. À la racine du projet, nous retrouvons les fichiers de documentation au format Markdown (`README.md`, `cahier_de_labo.md`, `rapport.md`) ainsi que le fichier `.gitignore`. 

  Les données et exécutions sont organisées dans les dossiers principaux suivants :

  * **`acanthaster_planci_ref_datas/` :** centralise l'annotation officielle (`annotation/`) et le génome de référence (`genome/`).

  * **`data_sets/` :** isole les données d'évidences biologiques. Il est scindé en :

    * `homology_data_set/` : contient la base protéique.
    * `RNAseq_data_set/` : contient les sous-dossiers classés par tissu (`gonad_dataset/`, `spine_dataset/`, `stomach_dataset/`), les données de test (`juvenile_data_set/`), l'espace de transit (`sra_downloads/`), le script d'extraction (`convert_rnaseq.sh`) et le fichier manifeste (`rnaseq_list.txt`).

  * **`annotation_datas/` :** ce répertoire maître regroupe toute l'activité et l'évaluation du pipeline. Il est subdivisé en :

    * `eviann_datas/` : contient l'historique des exécutions (`eviann_runs/`) et les fichiers finaux fusionnées (`eviann_results/`).

    * `gff_compare_results/` : contient les évaluations de l'annotation générée face à l'annotation officielle pour chaque run. 

  * **`fastqc_results/` :** répertoire dédié aux rapports de contrôle qualité des lectures, organisé par tissu.

  La reproductibilité est assurée par le répertoire `conda_environments`. Il contient les environnements virtuels, crés par Shahiran, isolant les dépendances logicielles : 
  
  * `env_ncbi` (`fasterq-dump` v3.4.1)
  * `env_fastqc` (`fastqc` v0.12.1)
  * `env_seqkit` (`seqkit` v2.14.0)
  * `env_eviann` (EviAnn v2.0.6)
  * `env_gff_compare` (`gffcompare` v0.12.10).
  
  Les fichiers de configuration exacts sont sauvegardés dans le sous-dossier `conda_env_exports`.

## Journal des sessions de travail

  **24/09/2026 — Acquisition du génome de référence**

  J'ai initialisé le projet en téléchargeant l'assemblage de référence d'*Acanthaster planci* depuis le NCBI, puis l'ai décompressé.
  ```bash
  mkdir -p /data/projet3/acanthaster_planci_ref_datas/genome/entier_genome/
  
  cd /data/projet3/acanthaster_planci_ref_datas/genome/entier_genome/

  wget "[https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/054/643/075/GCF_054643075.1_COTS_SCS/GCF_054643075.1_COTS_SCS_genomic.fna.gz]"

  gunzip -k GCF_054643075.1_COTS_SCS_genomic.fna.gz
  ```

  **26/09/2026 — Extraction des données test RNA-seq**

  J'ai extrait les données transcriptomiques de test en paires FASTQ avec l'outil `fasterq-dump` depuis l'environnement `env_ncbi`. 

  Le choix de ces données s'est porté sur ce set pour des raisons purement techniques (test de faisabilité du pipeline et calibrage de l'empreinte mémoire), sans aucune logique biologique sous-jacente. 
  
  Les séquences brutes proviennent du projet NCBI d'accession `PRJNA1422445`, issu d'une étude portant sur le mécanisme d'influence des algues calcifiées sur la croissance et le développement des juvéniles d'étoiles de mer (réalisée par le South China Sea Institute of Oceanology). Cette dernière presente douze runs. Deux d'entre eux (`SRR37199246` et `SRR37199247`) on été choisit sur la base leurs taile (en paire de base), respectivement `8.48 G` et `8.29 G` (les plus élevés).   
  
  L'option `-t .` a été utilisée pour forcer l'écriture des fichiers temporaires dans le répertoire de projet, évitant la saturation de l'espace personnel.

  ```bash 

  conda conda_environments/env_ncbi

  cd data_sets/RNAseq_data_set/juvenile_data_set/

  fasterq-dump -t . --split-files SRR37199246
  fasterq-dump -t . --split-files SRR37199247
  ```

  Les données ont ensuites étaient répartie en 2 fichier, `juvenille_resplicat_1` (qui regoupe les données `SRR37199247`) et `juvenille_replicat_2` (qui regroupe les données `SRR37199246`) 
  
  **27/09/2026 — Test EviAnn**
  
  Un premier test du pipeline EviAnn a été initié sur l'assemblage complet du génome au sein d'une session `screen` allouant 8 cœurs. Un fichier `rnaseq_list.txt` a été crée, regroupant les chemins des lectures de test `juvenile_data_set`, avec la mention fastq en fin de ligne, pour satisfaire le parser d'EviAnn.    

  ```bash

  # Création du fichier rnaseq_list.txt
  ls /data/projet3/data_sets/RNAseq_data_set/juvenile_data_set/*.fastq > /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt

  # Lancement du pipeline EviAnn
  screen -S eviann_test_1
  
  conda conda_environments/env_eviann

  cd annotation_datas/eviann_datas/eviann_runs/test_1_run
  
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/entier_genome/GCF_054643075.1_COTS_SCS_genomic.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa 
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt
  -t 8 2>&1 | tee eviann.log
  ``` 
  
  Le processus (tracé dans `test_1_run`) a été brutalement interrompu par le système (`Killed`) lors de l'étape d'alignement avec miniprot. Une seconde tentative sans multithreading (tracée dans `test_2_run`) a également échoué. 
  
  Le diagnostic a révélé que l'empreinte mémoire du génome complet saturait la RAM du serveur (déclenchement de l'OOM Killer).

  **28/09/2026 — Solution au problème EviAnn (run_1)**
  
  Après l’interruption des essais sur le génome entier faute de mémoire, j'ai réparti le génome en deux fichiers avec SeqKit :

  ```bash
  # On activte l'environnement seqkit
  
  conda activate conda_environments/env_seqkit/
  
  # On lance la commande pour fragmenter le génome en deux, dans un nouveau dossier

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

  J'ai relancé EviAnn dans `annotation_datas/eviann_datas/eviann_runs/run_2/genomic_part_001/`, sur la première partie du génome, en allouant 4 cœurs cette fois-ci et en utilisant toutes les données RNA-seq à disposition.   
  
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
  cd annotation_datas/eviann_datas/eviann_runs/run_2/genomic_part_001

  # Lancement du pipeline EviAnn
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt
  -t 2 2>&1 | tee eviann.log
  ```

  **10/10/2026 — Résultats du run_2 d’EviAnn sur la première partie du génome**

  L’exécution d’EviAnn avec deux cœurs, l’ensemble des données RNA-seq et les protéines d’homologie s’est terminée sur la première partie du génome. Le journal rapporte les résultats suivants :

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 10 353 |
  | Protein coding genes | 9 775 |
  | Processed pseudo gene transcripts | 75 |
  | Processed pseudo genes | 75 |
  | Transcripts | 23 901 |
  | Long non-coding RNAs | 508 |
  | Distinct proteins | 18 061 |

  Les les résultats devront etre fusionner avec ceux de la seconde partie du gènome, puis comparer avec le gènome de réference. 

  **11/10/2026 — Export des environnements**

  Les environnements `env_fastqc`, `env_gff_compare`, `env_ncbi` et `env_seqkit` ont été exporté dans le dossier dedié `conda_env_exports`. 

  La commande fu la suivante :

  ```bash
  conda env export -p /data/projet3/conda_environments/env_... > /data/projet3/conda_environments/conda_env_exports/env_... .yml
  ```

  **28/10/2026 — Réarrangement de l'arborescence**

  L'arborescence a été réaménagée de la manière suivante, suite aux remarques du professeur, par souci de simplicité :
  
  * **`acanthaster_planci_ref_datas/` :** ce dossier reste incahngé. 

  * **`analyses/`:** on y retrouve les dossiers `eviann_results`, `gff_compare_results` et `fastqc_results`. 

  * **`conda_environments/`:** ce dossier rest inchangé.

  * **`data_sets/`:** ce dossier rest inchangé. 

  * **`evian_runs/`:** contient toutes les données des runs eviann.

  **29/10/2026 — EviAnn run_2 genomic_part_002**

 Un run Eviann sur la seconde partie du génome pour le run_2 a été relancé. La raison étant que le run précédent n'ayant pas été lancé avec la même commande, les fichiers ont des des noms et des structures différents, ce qui compliquer un peu les choses poour la fusion des fichiers d'annoation. La commande fu la suivante : 

  ```bash
  # On se dèplace dans le fichier fraichement cree genomic_part__002. 

  cd /data/projet3/eviann_runs/run_2/genomic_part_002_yassine

  # On lance EviAnn. 

  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_002.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_proteins.faa
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt
  -t 2 2>&1 | tee eviann.log
  ```

  Le journal rapporte les résultats suivants :

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 9771  |
  | Protein coding genes | 9258 |
  | Processed pseudo gene transcripts | 46 |
  | Processed pseudo genes | 44 |
  | Transcripts | 23 180 |
  | Long non-coding RNAs | 473 |
  | Distinct proteins | 17 229  |

  **Compression des données RNA-seq**

  Afin de libérer de l’espace sur le serveur, les fichiers de lectures RNA-seq au format `.fastq` ont été compressés individuellement au format `.fastq.gz`. Chaque fichier d’une paire reste séparé, ce qui préserve l’organisation des échantillons.

  ```bash
  racine=/data/projet3/data_sets/RNAseq_data_set

  find "$racine" -type f -name '*.fastq' -print0 |
  while IFS= read -r -d '' fichier; do
    gzip -v -- "$fichier" || exit 1
  done
  ```
  La compression initiale avec `gzip` s’est interrompue après les fichiers des gonades, faute d’espace disque. Pour accélérer la reprise, un environnement Conda dédié à `pigz`, outil de compression utilisant plusieurs cœurs, a été préparé dans le dossier commun du projet :

  ```bash
  conda create --prefix /data/projet3/conda_environments/env_pigz -c conda-forge pigz
  conda activate /data/projet3/conda_environments/env_pigz
  ```
  
  `pigz` a ensuite été lancé avec quatre cœurs pour traiter les fichiers `.fastq` encore présents, un fichier à la fois :

  ```bash
  racine=/data/projet3/data_sets/RNAseq_data_set

  find "$racine" -type f -name '*.fastq' -print0 |
  while IFS= read -r -d '' fichier; do
    if [ -e "$fichier.gz" ]; then
        printf 'Fichier .gz déjà présent, à vérifier : %s.gz\n' "$fichier" >&2
        exit 1
    fi
    pigz -p 4 -v -- "$fichier" || exit 1
  done
  ```

  **30/10/2026 — Fin de la compression des fichiers et modification du manifest rnaseq_list.txt**

  Après plus d'une douzaine d'heures, tous les fichiers ont été compressés. 

  Les chemins du manifeste utilisé par EviAnn ont été mis à jour :

  ```bash
  liste=/data/projet3/data_sets/RNAseq_data_set/rnaseq_list.txt
  sed -i.bak -E 's/\.fastq([[:space:]]|$)/.fastq.gz\1/g' "$liste"
  ```

  La présence des deux fichiers indiqués sur chaque ligne a ensuite été contrôlée via la commande :

  ```bash
  awk 'NF {print $1; print $2}' "$liste" |
  while IFS= read -r fichier; do
    [ -f "$fichier" ] || printf 'Fichier introuvable : %s\n' "$fichier"
  done
  ```

  Aucun chemin manquant n’a été signalé. L’ancienne copie du manifeste, contenant les chemins en .fastq a été supprimée après cette vérification. Le fichier rnaseq_list.txt à utiliser pour les prochains lancements d’EviAnn pointe donc vers les fichiers compressés.

  **31/10/2026 — Nettoyage des fichiers temporaires Git**

  Le dossier `.git` occupait environ 30 Go, comme me l'a fait remarqué mon camarade Shahiran. La commande `git count-objects -vH` a montré que 24,37 Go provenaient de deux fichiers temporaires `tmp_pack_*`, signalés comme fichiers abandonnés par Git.

  ```bash
  cd /data/projet3
  git count-objects -vH
  git status -sb
  df -h /data/projet3
  ```

  Après vérification qu’aucune opération Git n’était en cours, ces deux fichiers temporaires ont été supprimés :

  ```bash
  ps -ef | grep -E '[g]it (gc|repack|pack-objects|add|push|fetch)'
  ls -lh .git/objects/pack/tmp_pack_*
  rm -i -- .git/objects/pack/tmp_pack_*
  ```

  Cette suppression permet de récupérer environ 24 Go sans retirer les commits ni les fichiers du projet. Les objets Git valides restent conservés dans `.git`.

  **Lancement d’EviAnn avec les RNA-seq juvéniles trimés et les données homologies sans les protéines de planci**

  Un manifeste consacré aux deux réplicats juvéniles a été créé. Chaque ligne associe les lectures `R1_paired` et `R2_paired` d’un même réplicat :

  ```bash
  liste=/data/projet3/data_sets/RNAseq_data_set/rnaseq_juveniles_trimes.txt

  cat > "$liste" <<'EOF'
  /data/projet3/trimming_results/juvenile_replicat_1/SRR37199247_R1_paired.fastq.gz /data/projet3/trimming_results/juvenile_replicat_1/SRR37199247_R2_paired.fastq.gz fastq
  /data/projet3/trimming_results/juvenile_replicat_2/SRR37199246_R1_paired.fastq.gz /data/projet3/trimming_results/juvenile_replicat_2/SRR37199246_R2_paired.fastq.gz fastq
  EOF
  ```

  Les fichiers `unpaired`, dont une seule lecture de la paire a survécu au trimming, ne sont pas inclus. Un dossier distinct a été créé pour annoter la première partie du génome sans réutiliser les résultats intermédiaires des runs précédents :

  ```bash
  mkdir -p /data/projet3/eviann_runs/run_juvenile_trimes/genomic_part_001
  ```

  EviAnn a été lancé avec deux cœurs dans une session `screen` sur la seconde partie du gènome dans un premier temps:

  ```bash
  # Activation de l'environnement
  conda activate /data/projet3/conda_environments/env_eviann
  
  # Déplacement dans le bon dossier
  cd /data/projet3/eviann_runs/run_juvenile_trimes/genomic_part_002

  # Lancement d'EviAnn
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_002.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_juveniles_trimes.txt
  -t 2 2>&1 | tee eviann.log
  ```
  
  Le journal rapporte :

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 6955 |
  | protein coding genes | 6594 |
  | processed pseudo gene transcripts| 11 |
  | processed pseudo genes | 10 |
  | transcripts | 12279 |
  | long non-coding RNAs | 354 |
  | distinct proteins | 9601 |

  Suite à ca il a été lancer sur la première partie du gènome en allouant 4 coeurs :

  ```bash
  # Activation de l'environnement
  conda activate /data/projet3/conda_environments/env_eviann
  
  # Déplacement dans le bon dossier
  cd /data/projet3/eviann_runs/run_juvenile_trimes/genomic_part_001

  # Lancement d'EviAnn
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_juveniles_trimes.txt
  -t 4 2>&1 | tee eviann.log
  ```

  Le journal rapporte :

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 8184 |
  | protein coding genes | 7812 |
  | processed pseudo gene transcripts| 26 |
  | processed pseudo genes | 26 |
  | transcripts | 13914 |
  | long non-coding RNAs | 351 |
  | distinct proteins | 11340 |

  **3/11/2026 — Lancement d’EviAnn avec l’ensemble des données RNA-seq et les données d'homologie filtrées** 

  Un nouveau manifeste, `rnaseq_all_compressed_datas.txt`, a été préparé avec les chemins des fichiers RNA-seq compressés (`.fastq.gz`). Chaque ligne associe les deux fichiers d’un échantillon.

  EviAnn a été lancé sur la première partie du génome, avec le fichier de protéines homologues filtrées et le manifeste `rnaseq_all_compressed_datas.txt`.

  ```bash
  eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa
  -r /data/projet3/data_sets/RNAseq_data_set/rnaseq_all_compressed_datas.txt
  -t 4 2>&1 | tee eviann.log
  ```

  Le run a échoué à cause d'un manque d'espace. Pour regeler ce problème de notre coté nous avons supprimer un grosse partie des données des run tout en gardant les fichiers importants (BAM, utilise à GFF compare et Features count), cela a été fait par Shahiran. Les données du run précedent ont été suprimer et un nouveau va etre retenter cette fois ci avec un autre type de données. 

  **Nouvelle annotation à partir des BAM non trimés et des données d'homologie filtrées**

  Les alignements RNA-seq ont été regroupés dans `/data/projet3/data_sets/BAM_data_set/`, avec un dossier distinct pour chaque partie du génome. Deux manifestes ont été créés dans `/data/projet3/manifests_bam/` : `non_trimmed_part_001.txt` et `non_trimmed_part_002.txt`. Chacun contient les chemins de cinq BAM non trimés (épine, estomac, gonade et deux réplicats juvéniles), avec le mot-clé `bam` attendu par EviAnn.

  Une nouvelle annotation a été lancée sur la partie 001 du génome, en utilisant le manifeste correspondant et les protéines d’homologie filtrées pour exclure *Acanthaster planci* :

  ```bash
  eviann.sh 
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna 
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa 
  -r /data/projet3/data_sets/BAM_data_set/manifests_bam/non_trimmed_part_001. txt -t 4 2>&1 | tee eviann.log
  ```
  Au moment de l'alignement avec miniprot le run sur la seconde moitié du gènome à été lancé : 

  ```bash
  eviann.sh 
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_002.fna 
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa 
  -r /data/projet3/data_sets/BAM_data_set/manifests_bam/non_trimmed_part_002.txt -t 4 2>&1 | tee eviann.log
  ```

  Le run sur la premère partie ayant échoué il a été relancé. 

  Le journal rapporte pour la première moitié :

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 9116 |
  | protein coding genes | 8353 |
  | processed pseudo gene transcripts| 38 |
  | processed pseudo genes | 38 |
  | transcripts | 18667 |
  | long non-coding RNAs | 740 |
  | distinct proteins | 13697 |

  Le journal rapporte pour la seconde moitié :

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 8036 |
  | protein coding genes | 7325 |
  | processed pseudo gene transcripts| 14 |
  | processed pseudo genes | 13 |
  | transcripts | 17238 |
  | long non-coding RNAs | 705 |
  | distinct proteins | 12057 |  

  **3/11/2026 — Lancement d’EviAnn avec l’ensemble des données RNA-seq, dont les données juveniles trimmé, et les données d'homologie filtrées**

  Une nouvelle annotation a été lancée sur la partie 001 du génome, en utilisant le manifeste correspondant et les protéines d’homologie filtrées pour exclure *Acanthaster planci* :

  ``` bash
  time eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_002.fna 
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa 
  -r /data/projet3/data_sets/BAM_data_set/manifests_bam/mixte_part_002.txt -t 4 2>&1 | tee eviann.log  
  ```
  
  Le journal rapporte : 

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 9125 |
  | protein coding genes | 8355 |
  | processed pseudo gene transcripts| 39 |
  | processed pseudo genes | 38 |
  | transcripts | 18866 |
  | long non-coding RNAs | 745 |
  | distinct proteins | 13791 |

  Le lancement sur la seconde paritie du génome a été fait mais ce dernier a échoué par manque de RAM, en effet quelqu'un à lancé un programme qui a kill miniprot. 

  EviAnn à donc été relancé avec 2 coeurs pour eviter le meme problème.

  Le journal rapporte : 

  | Élément annoté | Nombre |
  |---|---:|
  | Genes | 8067 |
  | protein coding genes | 7323 |
  | processed pseudo gene transcripts| 14 |
  | processed pseudo genes | 13 |
  | transcripts | 17523 |
  | long non-coding RNAs | 741 |
  | distinct proteins | 12165 |

  **05/11/2026 — Préparation des outils de controle de l'annotation et ajout de données RNA-seq**

  BUSCO et featureCounts ont été installés dans deux environnements Conda distincts : `/data/projet3/conda_environments/env_busco` et `/data/projet3/conda_environments/env_featurecounts`. BUSCO servira à évaluer la complétude des annotations et featureCounts permettra de compter les lectures alignées par gène à partir des BAM et de l’annotation.

  Deux nouveaux jeux de RNA-seq d’*Acanthaster planci* ont été ajoutés pour diversifier les tissus utilisés. 
  
  Le [nerf radial (SRR6378162)](https://www.ncbi.nlm.nih.gov/sra/SRX3472964) et les [pieds ambulacraires (SRR14654944)](https://www.ncbi.nlm.nih.gov/sra/SRX10993458).

  Une tentative de téléchargement avec `prefetch` a échoué lors de la création de fichiers dans `sra_downloads`. Les données ont ensuite été téléchargées directement avec `fastq-dump`. L’option `--split-files` sépare les lectures appariées et `--gzip` produit des fichiers `.fastq.gz`.

  ```bash
  fastq-dump --split-files --gzip --outdir /data/projet3/data_sets/RNAseq_data_set/nerve_dataset SRR6378162

  fastq-dump --split-files --gzip --outdir /data/projet3/data_sets/RNAseq_data_set/podia_dataset SRR14654944
  ```

  Les fichiers sont rangés respectivement dans `nerve_dataset` et `podia_dataset`. Leur qualité et leur intégrité restent à contrôler avant utilisation dans EviAnn. 

  **Contrôle qualité des nouvelles données RNA-seq**

  Un contrôle qualité avec FastQC a été lancé sur les lectures appariées du nerf radial (`SRR6378162`) et des pieds ambulacraires (`SRR14654944`). FastQC lit directement les fichiers `.fastq.gz`. Les deux jeux ont été analysés séparément avec deux threads, après activation de l’environnement dédié.

  ```bash
  # On active l'environement
  conda activate /data/projet3/conda_environments/env_fastqc

  # On crée le fichier de sortie et on lance
  mkdir -p /data/projet3/fastqc_results/nerve_dataset
  fastqc -t 2 -o /data/projet3/fastqc_results/nerve_dataset /data/projet3/data_sets/RNAseq_data_set/nerve_dataset/*.fastq.gz

  mkdir -p /data/projet3/fastqc_results/podia_dataset
  fastqc -t 2 -o /data/projet3/fastqc_results/podia_dataset /data/projet3/data_sets/RNAseq_data_set/podia_dataset/*.fastq.gz
  ```

  **Analyse FastQC et préparation du trimming du nerf radial**

  Les rapports FastQC des deux lectures appariées du nerf radial (`SRR6378162`) ont été examinés. Le fichier R1 contient **30 137 242 lectures de 151 bases** (environ 4,5 Gbp), avec **44 % de GC** et un encodage Phred+33.

  La qualité par base est globalement bonne, mais le signal d’adaptateur **Nextera** atteint environ **46 % des lectures** en fin de R1 et **45 %** en fin de R2. Un signal poly-G apparaît également en fin de lecture. FastQC signale une forte duplication pour R1. Ce résultat ne permet pas, à lui seul, de distinguer les duplications techniques des transcrits fortement exprimés en RNA-seq. Aucune déduplication n’a donc été prévue.

  Un trimming **paired-end** avec Trimmomatic a été préparé pour retirer les adaptateurs Nextera et couper les extrémités de faible qualité. Les sorties sont destinées à `/data/projet3/trimming_results/nerve/`.

  ```bash
  conda activate /data/projet3/conda_environments/env_trimmomatic
  IN=/data/projet3/data_sets/RNAseq_data_set/nerve_dataset
  OUT=/data/projet3/trimming_results/nerve
  ADAPTERS=$(find /data/projet3/conda_environments/env_trimmomatic -type f -name NexteraPE-PE.fa -print -quit)

  [ -n "$ADAPTERS" ] && trimmomatic PE -threads 2 -phred33 "$IN/SRR6378162_1.fastq.gz" "$IN/SRR6378162_2.fastq.gz" "$OUT/SRR6378162_R1_paired.fastq.gz" "$OUT/SRR6378162_R1_unpaired.fastq.gz" "$OUT/SRR6378162_R2_paired.fastq.gz" "$OUT/SRR6378162_R2_unpaired.fastq.gz" "ILLUMINACLIP:$ADAPTERS:2:30:10" SLIDINGWINDOW:4:20 MINLEN:36
  ```

  **Contrôle des données de nerf après trimming**

  FastQC a été réalisé sur les fichiers appariés du nerf. La qualité par base et le contenu en adaptateurs passent désormais les contrôles. Le trimming a conservé **12 636 649 paires** sur les **30 137 242 paires initiales**. Des alertes subsistent notamment pour la composition et la duplication des séquences.

  **Création des manifestes pour EviAnn**

  Un manifeste a été créé pour chaque partie du génome. Chacun reprend les BAM du manifeste mixte correspondant et ajoute les FASTQ du nerf après trimming ainsi que ceux des podia :

  ```bash
  BASE=/data/projet3
  MAN="$BASE/data_sets/BAM_data_set/manifests_bam"
  NER="$BASE/trimming_results/nerve"
  POD="$BASE/data_sets/RNAseq_data_set/podia_dataset"

  for part in 001 002; do
    sortie="$MAN/mixte_nerve_podia_part_$part.txt"

    cp "$MAN/mixte_part_$part.txt" "$sortie"

    printf '%s %s fastq\n' \
        "$NER/SRR6378162_R1_paired.fastq.gz" \
        "$NER/SRR6378162_R2_paired.fastq.gz" >> "$sortie"

    printf '%s fastq\n' \
        "$NER/SRR6378162_R1_unpaired.fastq.gz" >> "$sortie"

    printf '%s %s fastq\n' \
        "$POD/SRR14654944_1.fastq.gz" \
        "$POD/SRR14654944_2.fastq.gz" >> "$sortie"
  done
  ```

  Les BAM des parties `001` et `002` ont été alignés sur des références différentes, d’où la création de deux manifestes. Le fichier `R1_unpaired` est placé sur une ligne distincte. En effet ses **15 408 272 lectures R1** ont survécu au trimming, contrairement à leurs lectures R2 correspondantes. EviAnn peut ainsi les utiliser comme lectures seules, en plus des **12 636 649 paires** conservées.

  **Lancement du run**
  
  On lance EviAnn sur le manifeste mixte_nerve_podia_part_001.txt (contenant les données podia et nerve trimmé ainsi que les chemin des fichiers BAM pour gonad, spine, stomach et juveniles trimé) et les donnée d'homologie filtrées. 

  ```bash
  time eviann.sh
  -g /data/projet3/acanthaster_planci_ref_datas/genome/split_genome/GCF_054643075.1_COTS_SCS_genomic.part_001.fna
  -p /data/projet3/data_sets/homology_data_set/asteroidea_filtre_sans_planci.faa
  -r /data/projet3/data_sets/BAM_data_set/manifests_bam/mixte_nerve_podia_part_001.txt
  -t 4 2>&1 | tee eviann.log
  ```

  
---  

### 28/10/2026 – Libération de l’espace de stockage sur le serveur et suppression des résultats EviAnn devenus inutiles

# **Étudiant :** Shahiran Kuganaathan  

À la suite d'un message transmis par une camarade de promotion, nous avons été informés que Madame Friedrich demandait aux différents groupes de PTU en bioinformatique de faire du tri dans leurs fichiers. En effet, l'espace de stockage occupé par les différents projets commençait à saturer le serveur, rendant son utilisation de plus en plus difficile.

J'ai donc commencé par supprimer les dossiers `test_1_run` et `test_2_run`, qui correspondaient aux premiers essais réalisés avec EviAnn. Ces résultats n'étant plus nécessaires pour la suite de notre projet, leur suppression permettait de libérer plusieurs gigaoctets d'espace de stockage.

J'ai également supprimé les résultats de mon exécution d'EviAnn sur la deuxième partie du génome (`genomic_part_002`), dans le dossier `run_2`. En effet, Yassine avait relancé l'annotation de cette même partie du génome en utilisant une commande différente de celle que j'avais initialement employée.

Pour rappel, nous avions séparé le génome en deux parties afin de réaliser les annotations avec EviAnn. Cependant, pour la suite du projet, nous devions regrouper les annotations obtenues sur ces deux parties afin de pouvoir poursuivre les analyses avec `gffcompare`. Or, les commandes utilisées initialement n'étaient pas identiques, ce qui avait entraîné des différences dans la structure des fichiers de sortie et compliquait leur regroupement.

Yassine a donc relancé l'annotation de la deuxième partie du génome avec une commande permettant d'obtenir une organisation des fichiers de sortie cohérente avec celle de la première partie, afin de faciliter les étapes suivantes.

Mon ancienne exécution étant devenue redondante, j'ai supprimé les fichiers correspondants pour éviter de conserver inutilement plusieurs versions des mêmes résultats et ainsi contribuer à réduire l'espace de stockage occupé par notre projet sur le serveur.

### 31/10/2026 – Modification du jeu de données d’homologie pour exclure *Acanthaster planci*

**Étudiant : Shahiran Kuganaathan**

J'ai décidé de modifier notre jeu de données d'homologie afin d'exclure les protéines d'*Acanthaster planci*. En effet, comme nous cherchons à annoter le génome de cette espèce avec EviAnn, conserver ses protéines déjà annotées risquait de réutiliser des annotations existantes comme preuves d'homologie. L'objectif était donc de privilégier les protéines homologues provenant d'autres espèces d'Asteroidea, afin de rendre notre annotation moins dépendante des annotations déjà disponibles pour *Acanthaster planci*.

Dans un premier temps, j'ai tenté de télécharger un nouveau jeu de données depuis NCBI avec EDirect. Pour cela, j'ai lancé une session `screen` :

```bash
screen -S download_proteins
```

J'ai ensuite utilisé la commande suivante :

```bash
esearch -db protein -query "txid7588[Organism:exp] NOT txid133434[Organism:exp]" | efetch -format fasta > asteroidea_sans_planci.faa
```

Cette commande permet de rechercher les protéines des Asteroidea (`txid7588`) en excluant celles d'*Acanthaster planci* (`txid133434`), puis de télécharger les séquences au format FASTA.

Cependant, plusieurs erreurs `curl (56) OpenSSL SSL_read: unexpected eof while reading` sont apparues au cours du téléchargement. Après m'être renseigné, j'ai constaté que cette erreur correspondait à une interruption inattendue de la connexion avec NCBI. Même si le téléchargement continuait, certaines séquences risquaient potentiellement d'être manquantes ou incomplètes.

J'ai finalement décidé d'interrompre le téléchargement et de réutiliser le fichier initial `asteroidea_proteins.faa`, en supprimant directement les protéines d'*Acanthaster planci* avec la commande `awk` :

```bash
awk '/^>/ {garder = ($0 !~ /\[Acanthaster planci\]/)} garder' asteroidea_proteins.faa > asteroidea_filtre_sans_planci.faa
```

Cette commande permet de retirer les protéines d'*Acanthaster planci* tout en conservant celles des autres espèces. Cette méthode permet également de conserver les mêmes séquences que dans le jeu de données initial, sans dépendre des éventuelles mises à jour de NCBI.

J'ai ensuite vérifié les tailles des fichiers et le nombre de séquences avant et après le filtrage :

```bash
ls -lh asteroidea_proteins.faa asteroidea_filtre_sans_planci.faa

grep -c '^>' asteroidea_proteins.faa
grep -c '^>' asteroidea_filtre_sans_planci.faa
```

Le fichier initial contenait **139 392 séquences (104 Mo)**, contre **98 124 séquences (71 Mo)** après filtrage, soit **41 268 séquences supprimées**.

Pour vérifier que les séquences supprimées correspondaient bien à *Acanthaster planci*, j'ai utilisé :

```bash
grep -ic '^>.*\[Acanthaster planci\]' asteroidea_proteins.faa

grep -ic '^>.*\[Acanthaster planci\]' asteroidea_filtre_sans_planci.faa
```

La première commande a renvoyé **41 268**, correspondant exactement au nombre de séquences supprimées, tandis que la seconde a renvoyé **0**, confirmant qu'aucune entrée portant le nom `[Acanthaster planci]` ne subsistait dans le nouveau fichier.

### 31/10/2026 – Analyse des résultats FastQC et trimming des données RNA-seq juvéniles

**Étudiant : Shahiran Kuganaathan**

Après avoir examiné les rapports FastQC de nos différents échantillons RNA-seq, j'ai constaté que les deux réplicats juvéniles présentaient une quantité importante de séquences d'adaptateurs Illumina. En effet, le module `Adapter Content` indiquait environ **30 % de reads contenant des adaptateurs**.

Ces pourcentages correspondent à la proportion de reads dans lesquels FastQC a détecté des adaptateurs. Leur présence peut notamment s'expliquer par des fragments d'ADNc plus courts que la longueur de séquençage, entraînant la lecture d'une partie des adaptateurs.

En comparaison, les autres échantillons présentaient des pourcentages beaucoup plus faibles, inférieurs à 1 % pour R1 et R2.

Par ailleurs, les dix fichiers présentaient une bonne qualité globale des bases selon le module `Per base sequence quality`. J'ai donc décidé de réaliser un trimming uniquement sur les deux réplicats juvéniles, afin de supprimer les séquences d'adaptateurs sans raccourcir inutilement les reads des autres échantillons.

Pour cela, j'ai choisi d'utiliser **Trimmomatic**, que nous avions déjà étudié en cours, et de l'installer dans un environnement Conda dédié :

```bash
conda create -p /data/projet3/conda_environments/env_trimmomatic -c conda-forge -c bioconda trimmomatic -y
```

Trimmomatic permet notamment de supprimer les adaptateurs en comparant les reads aux séquences d'adaptateurs de référence. Il peut également éliminer les reads devenus trop courts après le nettoyage.

J'ai ensuite créé un script Bash, `trim_juveniles.sh`, dans le dossier `trimming_results`, à l'aide de `nano` :

```bash
nano /data/projet3/trimming_results/trim_juveniles.sh
```

Dans ce script, j'ai d'abord utilisé la commande suivante afin de retrouver le fichier contenant les séquences des adaptateurs Illumina :

```bash
ADAPTERS=$(find /data/projet3/conda_environments/env_trimmomatic -name "TruSeq3-PE.fa" -print -quit)
```

La commande `find` recherche le fichier `TruSeq3-PE.fa` dans l'environnement Conda et enregistre son chemin dans la variable `ADAPTERS`, qui est ensuite utilisée par Trimmomatic.

Pour le trimming des deux réplicats, j'ai utilisé les paramètres suivants :

```bash
"ILLUMINACLIP:${ADAPTERS}:2:30:10:2:true" \
MINLEN:36
```

Le paramètre `ILLUMINACLIP` permet de rechercher et de supprimer les adaptateurs à partir du fichier de référence. Les valeurs indiquées correspondent aux différents seuils utilisés par Trimmomatic pour leur détection. Le paramètre `MINLEN:36` permet quant à lui d'éliminer les reads dont la longueur devient inférieure à 36 nucléotides après le trimming.

Le script contient les commandes de trimming des deux réplicats juvéniles, exécutées successivement. Pour chaque réplicat, quatre fichiers de sortie sont prévus : deux fichiers `paired`, contenant les reads dont les deux partenaires ont été conservés, et deux fichiers `unpaired`, contenant les reads conservés seuls.

Tous les fichiers sont directement enregistrés au format compressé `.fastq.gz`, afin de limiter l'espace de stockage utilisé sur le serveur PTU. Les résultats sont répartis dans les dossiers `Juvenile_Replicat1` et `Juvenile_Replicat2`, avec un fichier `trimmomatic.log` permettant de conserver les statistiques du traitement.

Pour exécuter le script sans devoir maintenir ma connexion au serveur PTU, j'ai prévu de le lancer dans une session `screen` :

```bash
screen -S trimming_juveniles
```

Puis, après activation de l'environnement Conda :

```bash
conda activate /data/projet3/conda_environments/env_trimmomatic

bash /data/projet3/trimming_results/trim_juveniles.sh
```

### 01/11/2026 — Tentatives d’installation de BUSCO

**Étudiant : Shahiran Kuganaathan**

J’ai effectué deux tentatives d’installation de BUSCO 6.1.0 dans un environnement Conda dédié, mais les deux ont échoué avec les erreurs `No space left on device` et `InvalidArchiveError`, indiquant un manque d’espace disque lors du téléchargement et de l’extraction des paquets.

Après avoir effectué des recherches sur Internet pour comprendre l’origine de ces erreurs, j’ai vérifié l’espace de stockage disponible sur le serveur. J’ai constaté que le disque système `/`, d’une capacité de 38 Go et partagé entre les utilisateurs, était presque saturé, contrairement à la partition `/data`, qui disposait encore de plusieurs gigaoctets libres.

Le problème provenait du fonctionnement de Conda : bien que l’environnement BUSCO soit destiné à être installé dans `/data/projet3/conda_environments/`, Conda téléchargeait et extrayait d’abord les dépendances dans le cache personnel `/home/kuganaathan/.conda/pkgs`, situé sur le disque système presque saturé. L’espace disponible sur cette partition était donc insuffisant pour terminer l’installation.



### 01/10/2026 — Fusion et évaluation du run_1

**Étudiante : Sarah Amzallag**

Le génome d’*A. planci* étant trop volumineux pour la mémoire du serveur, il a été coupé en deux parties (`part_001` et `part_002`). Yassine a lancé EviAnn sur chaque partie séparément (run_1 : 2 réplicats juvéniles et protéines d’Asteroidea). Pour chaque partie, EviAnn produit un fichier **GFF**, qui contient l’annotation (gènes, transcrits, exons et introns avec leur position sur le génome), et un fichier **FASTA**, qui contient les séquences des protéines prédites. Mon travail consistait à réunir ces deux moitiés pour obtenir l’annotation du génome entier, puis à évaluer sa qualité.

J’ai d’abord fusionné les deux annotations GFF en un seul fichier. Chaque GFF commence par un en-tête de 3 lignes (format, nom du programme). Pour ne pas le dupliquer, j’ai conservé l’en-tête de la partie 1 (`head -3`), puis ajouté les gènes de la partie 1 et ceux de la partie 2 à partir de la ligne 4 (`tail -n +4`) :

```bash
{ head -3 part_001.gff; tail -n +4 part_001.gff; tail -n +4 part_002.gff; } > A_planci.gff
```

J’ai ensuite fusionné les protéines des deux parties. Les fichiers FASTA n’ayant pas d’en-tête, ils ont simplement été concaténés avec `cat` :

```bash
cat part_001.proteins.fasta part_002.proteins.fasta > A_planci.proteins.fasta
```

J’ai enfin évalué l’annotation avec GffCompare 0.12.10. Cet outil compare l’annotation produite par EviAnn à l’annotation officielle du NCBI, qui sert de référence. Pour chaque gène, transcrit, exon et intron, il vérifie si EviAnn l’a retrouvé exactement au même endroit. Cela permet de mesurer la qualité de notre annotation et de comparer les runs entre eux :

```bash
gffcompare -r /data/projet3/acanthaster_planci_datas/annotation/ref_annotation.gff -o /data/projet3/gffcompare_result/result /data/projet3/gffcompare_result/proteine_annotation_file.gff
```

L’option `-r` indique l’annotation de référence (NCBI), `-o` le dossier et le préfixe des fichiers de sortie, et le dernier fichier est l’annotation EviAnn à évaluer. GffCompare produit plusieurs fichiers :

- `result.stats` : le résumé des scores (sensibilité, précision, éléments manqués ou nouveaux) ;
- `result.tracking` et `result.loci` : la correspondance entre nos transcrits et gènes et ceux de la référence ;
- `result.annotated.gtf` : notre annotation, où chaque transcrit est annoté selon sa correspondance avec la référence ;
- `.tmap` et `.refmap` : la correspondance transcrit par transcrit.

Des droits insuffisants empêchaient d’écrire dans le dossier contenant l’annotation. J’ai donc travaillé sur une copie du fichier. Les fichiers ont ensuite été rangés dans `analyses/` lors de la réorganisation de l’arborescence.

---

### 02/10/2026 – 30/10/2026 — Analyse des résultats du run_1 en attendant les runs suivants

**Étudiante : Sarah Amzallag**

Le délai entre le run_1 et les runs suivants a été long, car le run_2 a échoué plusieurs fois suite à l’arrêt de miniprot par manque de mémoire vive.

Pendant ce temps, j’ai analysé les résultats GffCompare du run_1 (`result.stats`). L’annotation est précise (96,6 % des introns prédits sont corrects) mais incomplète (20,3 % des gènes de la référence ne sont pas retrouvés). Une explication possible est que le run_1 n’utilise que des RNA-seq de juvéniles : les gènes exprimés dans d’autres tissus ne peuvent pas être détectés. Le détail des résultats est présenté dans l’analyse comparative des cinq runs (05/11/2026).

---

### 31/10/2026 — Fusion et évaluation du run_2

**Étudiante : Sarah Amzallag**

Le run_2 utilise 5 échantillons RNA-seq (2 juvéniles, gonade, épine, estomac) et les mêmes protéines que le run_1. L’objectif est de voir si l’ajout de tissus améliore l’annotation. J’ai fusionné les deux parties de la même façon que pour le run_1, puis lancé GffCompare, en utilisant cette fois des jokers `*` pour sélectionner les fichiers :

```bash
{ head -3 eviann_runs/run_2/genomic_part_001/*.gff; tail -n +4 eviann_runs/run_2/genomic_part_001/*.gff; tail -n +4 eviann_runs/run_2/genomic_part_002/*.gff; } > analyses/eviann_results/run_2/proteine_annotation_file.gff

cat eviann_runs/run_2/genomic_part_001/*.fasta eviann_runs/run_2/genomic_part_002/*.fasta > analyses/eviann_results/run_2/proteins_sequences_file.fasta

gffcompare -r acanthaster_planci_ref_datas/annotation/ref_annotation.gff -o analyses/gff_compare_results/run_2_gffcompare_results/result analyses/eviann_results/run_2/proteine_annotation_file.gff
```

Ces fichiers se sont révélés incorrects et ont été refaits le 02/11/2026 (voir ci-dessous).

---

### 02/11/2026 — Run juvéniles trimés, détection d’une erreur et correction

**Étudiante : Sarah Amzallag**

Le run juvéniles trimés (lancé par Yassine) utilise les 2 réplicats juvéniles après trimming (adaptateurs retirés) et les protéines d’Asteroidea sans celles d’*A. planci*. J’ai fusionné ses deux parties avec les mêmes commandes que pour le run_2, puis j’ai vérifié la taille des fichiers obtenus :

```bash
ls -lh analyses/eviann_results/*/proteins_sequences_file.fasta
grep -c '^>' analyses/eviann_results/run_juveniles_trimes/proteins_sequences_file.fasta
```

`ls -lh` affiche la taille des fichiers. `grep -c '^>'` compte les séquences, puisque chaque séquence FASTA commence par `>`. Le fichier de protéines faisait 120 Mo pour le run juvéniles et 230 Mo pour le run_2, contre 24 Mo pour le run_1. Il contenait 53 054 séquences, alors qu’EviAnn annonçait environ 21 000 protéines.

Pour comprendre l’origine de cette différence, j’ai listé les fichiers produits par EviAnn :

```bash
ls -lh eviann_runs/run_2/*/*.fasta eviann_runs/run_2/*/*.gff
```

Dans chaque partie, EviAnn produit deux fichiers FASTA (les protéines `.proteins.fasta` et les transcrits `.transcripts.fasta`) et sept fichiers GFF, dont un seul est l’annotation finale (`.fna.gff`). Les six autres sont des fichiers intermédiaires (alignements de protéines, protéines non utilisées…). Le joker `*` sélectionnait tous ces fichiers. J’avais donc collé les protéines (séquences d’acides aminés) avec les transcrits (séquences nucléotidiques), et l’annotation finale avec les fichiers intermédiaires. GffCompare évaluait ce mélange : ses résultats étaient donc faux pour le run_2 et le run juvéniles.

Le run_1 n’est pas concerné, car il avait été fusionné avec les noms exacts des fichiers. Son annotation fait 88 Mo (46 + 43 Mo, les deux `.fna.gff`) et ses protéines 24 Mo.

J’ai supprimé les fichiers fusionnés et les résultats GffCompare de ces deux runs dans `analyses/`, sans toucher aux résultats d’EviAnn (`eviann_runs/`). Avant de refaire la fusion, j’ai vérifié que l’en-tête de chaque annotation faisait bien 3 lignes, pour ne perdre ni dupliquer aucun gène :

```bash
head -4 eviann_runs/run_2/genomic_part_001/GCF_054643075.1_COTS_SCS_genomic.part_001.fna.gff
```

J’ai ensuite refait les fusions en indiquant le nom exact des fichiers, sans joker : l’annotation finale de la partie 1 avec celle de la partie 2 (`.fna.gff`), et les protéines de la partie 1 avec celles de la partie 2 (`.proteins.fasta`). Exemple pour le run_2 :

```bash
{ head -3 eviann_runs/run_2/genomic_part_001/GCF_054643075.1_COTS_SCS_genomic.part_001.fna.gff; tail -n +4 eviann_runs/run_2/genomic_part_001/GCF_054643075.1_COTS_SCS_genomic.part_001.fna.gff; tail -n +4 eviann_runs/run_2/genomic_part_002/GCF_054643075.1_COTS_SCS_genomic.part_002.fna.gff; } > analyses/eviann_results/run_2/proteine_annotation_file.gff

cat eviann_runs/run_2/genomic_part_001/GCF_054643075.1_COTS_SCS_genomic.part_001.fna.proteins.fasta eviann_runs/run_2/genomic_part_002/GCF_054643075.1_COTS_SCS_genomic.part_002.fna.proteins.fasta > analyses/eviann_results/run_2/proteins_sequences_file.fasta
```

Les mêmes commandes ont été utilisées pour le run juvéniles, en remplaçant `run_2` par `run_juveniles_trimes`. J’ai ensuite vérifié les fichiers obtenus :

```bash
ls -lh analyses/eviann_results/run_2/ analyses/eviann_results/run_juveniles_trimes/
grep -c "gff-version" analyses/eviann_results/run_2/proteine_annotation_file.gff
```

Les tailles correspondent désormais à la somme des deux parties (run_2 : 126 Mo pour l’annotation et 34 Mo pour les protéines ; juvéniles : 67 Mo et 17 Mo). La ligne `gff-version` n’apparaît qu’une fois, ce qui confirme l’absence d’en-tête en double.

J’ai enfin relancé GffCompare sur les deux runs corrigés. GffCompare écrit les fichiers `.tmap` et `.refmap` à côté du fichier analysé : je les ai donc déplacés dans le dossier de résultats correspondant. Exemple pour le run_2 :

```bash
gffcompare -r acanthaster_planci_ref_datas/annotation/ref_annotation.gff -o analyses/gff_compare_results/run_2_gffcompare_results/result analyses/eviann_results/run_2/proteine_annotation_file.gff

mv analyses/eviann_results/run_2/result.proteine_annotation_file.gff.* analyses/gff_compare_results/run_2_gffcompare_results/
```

---

### 05/11/2026 — Fusion et évaluation de deux nouveaux runs avec les protéines filtrées

**Étudiante : Sarah Amzallag**

L’analyse des trois premiers runs laissait une question ouverte : la baisse de sensibilité du run juvéniles trimés pouvait venir du trimming ou du retrait des protéines d’*A. planci*, puisque ces deux paramètres avaient changé en même temps. Deux nouveaux runs EviAnn ont donc été réalisés, chacun ne modifiant qu’un seul paramètre :

- **`run_all_RNA_seq_prot_filtred`** : les 5 échantillons RNA-seq du run_2 (juvéniles non trimés), avec les protéines d’Asteroidea sans *A. planci*. Par rapport au run_2, seules les protéines changent : ce run mesure l’effet du retrait des protéines d’*A. planci*.
- **`run_all_RNA_seq_juveniles_trimes_prot_filtred`** : les 5 échantillons RNA-seq avec les juvéniles trimés, et les mêmes protéines filtrées. Par rapport au run précédent, seul le trimming change : ce run mesure l’effet du trimming.

J’ai fusionné les deux parties de chaque run puis lancé GffCompare, avec la même méthode que pour les runs précédents (voir l’entrée du 02/11/2026) : vérification des en-têtes avec `head -4`, fusion des fichiers `.fna.gff` et `.fna.proteins.fasta` avec leur nom exact, contrôle de la taille et du nombre d’en-têtes, GffCompare, puis déplacement des fichiers `.tmap` et `.refmap`. Les résultats sont rangés dans des dossiers portant le nom de chaque run, dans `analyses/eviann_results/` et `analyses/gff_compare_results/`.

| Run | GFF fusionné | FASTA protéines | En-têtes |
|---|---:|---:|---:|
| `run_all_RNA_seq_prot_filtred` | 96 Mo | 25 Mo | 1 |
| `run_all_RNA_seq_juveniles_trimes_prot_filtred` | 97 Mo | 25 Mo | 1 |

Un troisième run (`run_mixte_nervetrim_podia_all_juvtrim`) était encore en cours d’exécution et n’a pas pu être évalué.

---

### 05/11/2026 — Analyse des résultats GffCompare des cinq runs

**Étudiante : Sarah Amzallag**

Les résultats proviennent des fichiers `result.stats` produits par GffCompare, un par run, dans `analyses/gff_compare_results/`. Chaque fichier compare une annotation EviAnn à l’annotation de référence du NCBI (47 324 transcrits, 22 001 loci).

Pour les trois premiers runs, j’ai vérifié que le nombre de transcrits compté par GffCompare correspondait à la somme des transcrits et des ARN longs non codants annoncés par EviAnn pour les deux parties (34 395, 48 062 et 26 898) : les fusions n’ont ni perdu ni dupliqué de transcrits.

Les mesures utilisées sont les suivantes :

- **Sensibilité** : part des éléments de la référence retrouvés par EviAnn. Elle mesure si l’annotation est complète.
- **Précision** : part des éléments prédits par EviAnn présents dans la référence. Elle mesure si l’annotation est juste.
- **Niveaux** : du plus simple au plus exigeant, base, intron, transcrit (tous les exons doivent être identiques) et locus (le gène est trouvé au bon endroit).
- **Loci manqués** : gènes de la référence absents de notre annotation.
- **Loci nouveaux** : gènes prédits par EviAnn absents de la référence.

| | Run_1 | Run_2 | Juvéniles trimés | All RNA-seq, prot. filtrées | All RNA-seq juv. trimés, prot. filtrées |
|---|---|---|---|---|---|
| RNA-seq | 2 juvéniles | 5 échantillons | 2 juvéniles trimés | 5 échantillons | 5 échantillons (juv. trimés) |
| Protéines | complètes | complètes | sans *A. planci* | sans *A. planci* | sans *A. planci* |
| Base (sens. / préc.) | 60,9 / 92,7 % | 73,2 / 85,8 % | 56,0 / 91,7 % | 66,1 / 85,6 % | 66,4 / 85,6 % |
| Intron (sens. / préc.) | 77,4 / 96,6 % | 85,6 / 93,0 % | 66,8 / 95,3 % | 74,9 / 93,0 % | 75,1 / 92,8 % |
| Transcrit (sens. / préc.) | 43,4 / 59,7 % | 52,0 / 51,2 % | 32,9 / 57,9 % | 39,5 / 50,0 % | 39,8 / 49,8 % |
| Locus (sens. / préc.) | 62,5 / 74,5 % | 69,9 / 77,4 % | 53,3 / 77,8 % | 59,3 / 77,0 % | 59,5 / 77,1 % |
| Loci manqués | 20,3 % | 15,4 % | 33,2 % | 26,4 % | 26,2 % |
| Loci nouveaux | 3,8 % | 6,0 % | 3,4 % | 5,5 % | 5,6 % |
| Transcrits prédits | 34 395 | 48 062 | 26 898 | 37 350 | 37 875 |

La précision reste élevée dans les cinq runs (plus de 92 % au niveau des introns) : ce qu’EviAnn prédit est généralement juste. C’est surtout la sensibilité qui varie. Les scores baissent du niveau intron au niveau transcrit, ce qui est attendu, car un seul exon mal placé suffit pour qu’un transcrit entier soit compté comme faux.

Les cinq runs permettent d’isoler l’effet de chaque paramètre :

| Comparaison | Paramètre modifié | Loci manqués | Effet |
|---|---|---|---|
| Run_1 → run_2 | Ajout de tissus | 20,3 % → 15,4 % | Sensibilité augmentée |
| Juvéniles trimés → all RNA-seq juv. trimés, prot. filtrées | Ajout de tissus | 33,2 % → 26,2 % | Sensibilité augmentée |
| Run_2 → all RNA-seq, prot. filtrées | Retrait des protéines d’*A. planci* | 15,4 % → 26,4 % | Sensibilité diminuée |
| All RNA-seq, prot. filtrées → all RNA-seq juv. trimés, prot. filtrées | Trimming des juvéniles | 26,4 % → 26,2 % | Aucun effet notable |

**Diversité des tissus.** L’ajout de tissus augmente la sensibilité, avec ou sans les protéines d’*A. planci*. Tous les gènes ne sont pas exprimés dans les mêmes tissus : multiplier les tissus permet de détecter davantage de gènes. La précision baisse légèrement, car EviAnn prédit plus de transcrits, dont certains, propres à un tissu, peuvent être absents de la référence.

**Protéines d’homologie.** Le retrait des protéines d’*A. planci* diminue fortement la sensibilité (de 52,0 % à 39,5 % au niveau des transcrits), sans modifier la précision. Ces protéines proviennent probablement de l’annotation NCBI, qui sert aussi de référence : les run_1 et run_2 disposaient donc d’une partie de la « réponse », et leurs scores sont surestimés.

**Trimming.** Le trimming des juvéniles n’a pratiquement aucun effet (moins de 0,5 point d’écart). La baisse observée pour le run juvéniles trimés était donc due au retrait des protéines d’*A. planci*, et non au trimming.

Le run `all RNA-seq juv. trimés, prot. filtrées` est celui qui reflète le mieux les performances d’EviAnn sur un génome non annoté comme celui de *C. tenuispina* : il utilise toutes les données RNA-seq disponibles, sans protéines de l’espèce étudiée. EviAnn y retrouve 75,1 % des introns et 59,5 % des gènes de la référence, avec une précision de 92,8 % au niveau des introns.

---

### 05/11/2026 — Perspectives : évaluation complémentaire avec BUSCO et AGAT

**Étudiante : Sarah Amzallag**

GffCompare évalue nos annotations uniquement par comparaison avec l’annotation du NCBI. Cette approche a deux limites : elle suppose que la référence est complète et correcte, et elle ne sera plus possible pour un génome non annoté comme celui de *Coscinasterias tenuispina*. Deux outils complémentaires auraient permis d’aller plus loin.

**BUSCO** recherche, dans les protéines prédites, un ensemble de gènes conservés présents en une seule copie chez presque toutes les espèces d’un groupe (par exemple les métazoaires ou les échinodermes). Il indique la proportion de ces gènes retrouvés complets, fragmentés, dupliqués ou absents. Il aurait pu être lancé en mode protéines sur nos fichiers fusionnés (`proteins_sequences_file.fasta`) et sur les protéines de référence. Cela aurait permis :

- d’évaluer la complétude de chaque annotation **sans dépendre de l’annotation NCBI** ;
- de vérifier si les gènes « nouveaux » ou « manqués » selon GffCompare correspondent à de vraies erreurs ;
- de disposer d’une méthode d’évaluation applicable à *C. tenuispina*.

**AGAT** calcule des statistiques descriptives sur un fichier GFF (`agat_sp_statistics.pl`) : nombre de gènes, longueur moyenne des gènes, nombre d’exons par transcrit, longueur des introns, etc. Comparer ces statistiques entre nos runs et la référence aurait permis de voir si EviAnn a tendance à produire des gènes trop courts, à fusionner ou à couper des gènes, ou à oublier des exons. Cela aurait aidé à expliquer la baisse des scores au niveau des transcrits.

Ces analyses n’ont pas pu être réalisées. L’installation de BUSCO a échoué faute d’espace sur le disque système (voir l’entrée de Shahiran du 01/11/2026), et une grande partie du temps a été consacrée au téléchargement des données, aux relances d’EviAnn liées au manque de mémoire et à la libération d’espace sur le serveur. Compte tenu du temps restant, il est peu probable qu’elles soient faites avant la fin du projet. Elles constitueraient néanmoins la suite logique de ce travail.