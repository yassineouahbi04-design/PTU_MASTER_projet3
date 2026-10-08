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
