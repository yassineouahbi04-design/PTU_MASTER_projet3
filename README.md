# Cahier de laboratoire — Projet 3 : Annotation structurale d'Acanthaster planci

---

## 1. Environnement d'exécution et traçabilité

* **Plateforme de calcul :** serveur universitaire `ptu.bigest-icube.fr` (architecture x86_64).
* **Système d'exploitation :** Ubuntu 24.04.4 LTS (noyau Linux `6.8.0-139-generic`).
* **Gestionnaire de versions :** Git 2.43.0.
* **Gestionnaire d'environnements :** Conda 26.7.2.
* **Environnement centralisé de travail :** `PTU_project`.
* **Outil d'acquisition SRA :** `fasterq-dump` 3.4.1 (SRA-Toolkit).
* **Politique de partage et permissions :**
  * Propriétaire : `ouahbi`, groupe : `projet3`.
  * Droits groupe (`projet3`) : `rwx` (lecture, modification et exécution pour les membres de l'équipe).
  * Droits tiers / enseignant (`others`) : `r-x` (consultation et traversée sans droit d'écriture).
  * Reproductibilité : exclusion des gros volumes de données du dépôt via `.gitignore` (`*.fastq`, `*.fasta`, `.fna.gz`, `fasterq.tmp.*`, dossiers `data_sets/`, `acanthaster_planci_ref_genome/`).

---

## 2. Données d'entrée et acquisition

### 2.1. Génome de référence
* **Espèce :** *Acanthaster planci*
* **Accession NCBI :** `GCF_054643075.1` (assemblage `COTS_SCS`).
* **Répertoire local :** `/data/projet3/acanthaster_planci_ref_genome/`
* **Format :** Assemblage génomique en format FASTA compressé (`.fna.gz`).
* **Méthode d'acquisition :**
  * Ligne de commande :
    ```bash
    wget "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/054/643/075/GCF_054643075.1_COTS_SCS/GCF_054643075.1_COTS_SCS_genomic.fna.gz"
    ```

### 2.2. Données transcriptomiques (RNA-seq) pour le test d'Eviann
* **Identifiants SRA :** `SRR37199246` et `SRR37199247`
* **Répertoire local :** `/data/projet3/data_sets/RNAseq_data_test/`
* **Méthode d'extraction :**
  * Outil : `fasterq-dump`
  * Commandes exécutées dans le répertoire cible :
    ```bash
    fasterq-dump -t . --split-files SRR37199246
    fasterq-dump -t . --split-files SRR37199247
    ```
  * **Gestion de l'espace temporaire :** Utilisation de l'option `-t .` pour forcer l'écriture des fichiers temporaires dans le répertoire courant du projet partagé (`/data/projet3/...`), empêchant ainsi l'outil d'écrire par défaut dans le répertoire personnel (`$HOME`) et de saturer le quota utilisateur.
* **Fichiers obtenus (pour chaque dataset) :**
  * `*_1.fastq` (lectures Forward)
  * `*_2.fastq` (lectures Reverse)
* **Contrôle d'intégrité :** vérification des tailles de fichiers, présence des quatre lignes caractéristiques par lecture FASTQ et nettoyage des dossiers temporaires résiduels.

---

### 2.3 Test d'Eviann sur les données de transcriptomiques et d'homologie

* **Objectif :** Lancer EviAnn avec peu de données sur la machine distante, pour évaluer sa consommation en ressources. 

* **Création d'un envirronnement dedié :**  `eviann` (Eviter le dependency hell) 

* **Installation via conda :** `conda install eviann` version 2.0.6


