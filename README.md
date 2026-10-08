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

## 3. EviAnn

* **Outil principal :** EviAnn (pipeline d'annotation automatique développé par Aleksey Zimin).
* **Dépôt source :** [https://github.com/   alekseyzimin/EviAnn_release](https://github.com/alekseyzimin/EviAnn_release)
* **Version installée :** EviAnn version 2.0.6
* **Environnement Conda dédié :** `env_eviann`
* **Justification de l'isolation :**
  * EviAnn intègre un ensemble complexe d'outils tiers (aligneurs, prédicteurs et bibliothèques de manipulation de formats) requérant des dépendances strictes.
  * La séparation dans un environnement vierge dédié évite le phénomène de conflit de versions (*dependency hell*) avec les outils du projet général (`env_ncbi`) et garantit une reproductibilité expérimentale totale.

### 3.1. Déroulement des opérations

* **Décompression du génome de référence :**  
   Le fichier FASTA compressé a été dézippé avec conservation de l'archive source :
   ```bash
   gunzip -k /data/projet3/acanthaster_planci_ref_genome/GCF_054643075.1_COTS_SCS_genomic.fna.gz
   ```
* **Activation de l'environnement partagé :**  
    Accès à l'environnement ```Conda``` commun contenant l'ensemble des dépendances (HISAT2, StringTie, TransDecoder, etc.) : 
    ```bash
    conda activate /data/projet3/conda_temporaire/env_eviann
    ```

* **Génération du fichier de liste pour le RNA-seq :** 
    Création du manifeste ```rnaseq_list.txt``` regroupant les chemins des lectures de test appariées (```SRR37199246``` et ```SRR37199247```) avec la mention ```fastq``` en fin de ligne pour satisfaire le parser d'EviAnn :
    ```bash 
    cat << 'EOF' > 
    /data/projet3/eviann_test_run/rnaseq_list.txt
    /data/projet3/data_sets/RNAseq_data_test/SRR37199246_dataset/SRR37199246_1.fastq /data/projet3/data_sets/RNAseq_data_test/SRR37199246_dataset/SRR37199246_2.fastq fastq
    /data/projet3/data_sets/RNAseq_data_test/SRR37199247_dataset/SRR37199247_1.fastq /data/projet3/data_sets/RNAseq_data_test/SRR37199247_dataset/SRR37199247_2.fastq fastq
    EOF
  ```

### 3.2. Lancement du pipeline EviAnn

  * **Lancement :**  
    
    Création d'un fichier dedier au résultats d'EviAnn nomer ` eviann_test_run`. Ouverture d'une session virtuelle `screen` pour maintenir le calcul actif après déconnexion, exécution sur 8 coeur avec redirection des traces vers `eviann.log`, puis détachement de la session :
    ```bash
    screen -S eviann_job

    eviann.sh \
    -g /data/projet3/acanthaster_planci_ref_genome/GCF_054643075.1_COTS_SCS_genomic.fna \
    -p /data/projet3/data_sets/homology_data_test/asteroidea_proteins.faa \
    -r /data/projet3/eviann_test_run/rnaseq_list.txt \ -t 8 2>&1 | tee eviann.log
    ```
    Lors de ce lancement, le pipeline s'est interrompu brutalement au cours de l'étape d'alignement des protéines homologues avec l'outil `miniprot`. Ce crash, marqué par la mention système `Killed`, a été provoqué par le déclenchement de l'OOM Killer du noyau Linux à la suite d'un dépassement de la mémoire vive disponible, problème accentué par l'allocation initiale de 8 cœurs. 

* **Seconde tentative :**
  
    Afin de déterminer si ce blocage résultait d'une saturation ponctuelle du serveur ou de l'empreinte mémoire excessive liée au parallélisme, une seconde tentative a été initiée en retirant la contrainte `-t 8`. Cette dernière c'est soldé par un echec, pour les meme raison que la première tentative.

* **Partitionnement du génome et contournement des limites mémoire :**

    Face à la saturation persistante de la RAM par miniprot, un nouvel environnement Conda dédié et partagé a été créé `(env_seqkit)` dans lequel l'outil `seqkit` a été installé. À l'aide de cet outil, le génome de référence a été scindé en deux sous-ensembles équilibrés en volume de paires de bases sans rompre aucun scaffold. La commande fu la suivante:
    ```bash 
    seqkit split2 -p 2 GCF_054643075.1_COTS_SCS_genomic.fna -O split_genome/
     ```

    Des dossiers de travail distincts (`genomic_part_001`, `genomic_part_002`) ont été mis en place et l'exécution d'EviAnn a été lancée sur la première moitié (`GCF_054643075.1_COTS_SCS_genomic.part_001`) au sein d'une session screen afin de diviser par deux la consommation mémoire, avant d'enchaîner sur la seconde moitié puis de fusionner les deux fichiers GFF3 finaux.

* **Resultats des annoations partionnées :**

    kkkkkk
