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


Bien sûr. Pour ton **cahier de labo**, tu peux mettre ça, dans l’ordre de ce que tu as fait aujourd’hui :

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

---  

### 28/10/2026 – Libération de l’espace de stockage sur le serveur et suppression des résultats EviAnn devenus inutiles

# **Étudiant :** Shahiran Kuganaathan  

À la suite d'un message transmis par une camarade de promotion, nous avons été informés que Madame Friedrich demandait aux différents groupes de PTU en bioinformatique de faire du tri dans leurs fichiers. En effet, l'espace de stockage occupé par les différents projets commençait à saturer le serveur, rendant son utilisation de plus en plus difficile.

J'ai donc commencé par supprimer les dossiers `test_1_run` et `test_2_run`, qui correspondaient aux premiers essais réalisés avec EviAnn. Ces résultats n'étant plus nécessaires pour la suite de notre projet, leur suppression permettait de libérer plusieurs gigaoctets d'espace de stockage.

J'ai également supprimé les résultats de mon exécution d'EviAnn sur la deuxième partie du génome (`genomic_part_002`), dans le dossier `run_2`. En effet, Yassine avait relancé l'annotation de cette même partie du génome en utilisant une commande différente de celle que j'avais initialement employée.

Pour rappel, nous avions séparé le génome en deux parties afin de réaliser les annotations avec EviAnn. Cependant, pour la suite du projet, nous devions regrouper les annotations obtenues sur ces deux parties afin de pouvoir poursuivre les analyses avec `gffcompare`. Or, les commandes utilisées initialement n'étaient pas identiques, ce qui avait entraîné des différences dans la structure des fichiers de sortie et compliquait leur regroupement.

Yassine a donc relancé l'annotation de la deuxième partie du génome avec une commande permettant d'obtenir une organisation des fichiers de sortie cohérente avec celle de la première partie, afin de faciliter les étapes suivantes.

Mon ancienne exécution étant devenue redondante, j'ai supprimé les fichiers correspondants pour éviter de conserver inutilement plusieurs versions des mêmes résultats et ainsi contribuer à réduire l'espace de stockage occupé par notre projet sur le serveur.



















  

