# Dashboard Cyclistic – Analyse et Visualisation des Données 2021

Ce projet est le fruit d'une journée de travail intensif dans le cadre d'un certificat blanc. Il s'inscrit dans le cadre d'une étude de cas business visant à analyser et visualiser les données d'utilisation des vélos de Cyclistic à Chicago pour proposer des recommandations stratégiques.

## Contexte

Cyclistic est une entreprise de partage de vélos à Chicago qui propose désormais une flotte de 5 824 vélos géolocalisés répartis sur 692 stations. Le service est accessible via deux types de clientèle :
- **Cyclistes occasionnels** : Utilisateurs achetant des passes pour une seule course ou une journée complète.
- **Membres annuels** : Utilisateurs souscrivant un abonnement annuel.

L’objectif principal est de comprendre comment les deux types d'utilisateurs utilisent les vélos afin de convertir davantage de cyclistes occasionnels en membres annuels et de déterminer les meilleurs emplacements pour de nouvelles stations.

## Objectifs de l'Étude

Les questions clés auxquelles cette analyse cherche à répondre sont :
- **Usage différencié :** Comment les membres annuels et les cyclistes occasionnels utilisent-ils différemment les vélos Cyclistic ?
- **Conversion :** Pourquoi les cyclistes occasionnels pourraient-ils être incités à souscrire à un abonnement annuel ?
- **Stratégie digitale :** Comment Cyclistic peut-il utiliser les médias numériques pour influencer la conversion ?
- **Implantation de nouvelles stations :** Où recommander l'installation de nouvelles stations en fonction des habitudes d'utilisation, des saisons et de la fréquentation des stations ?

## Data & Méthodologie

### Collecte des Données
- **Source des données :** Les données de base proviennent de fichiers CSV publics disponibles sur le serveur AWS de Divvy Tripdata ([lien](https://divvy-tripdata.s3.amazonaws.com/index.html)).
- **Période :** Année 2021 (fichiers CSV de Janvier à Décembre).

### Pré-traitement et Traitement des Données
- **Nettoyage :** Suppression des trajets présentant des problèmes techniques.
- **Transformation :** Ajout de colonnes pour enrichir l'analyse (ex. durée du trajet, heure de départ, etc.).
- **Export :** Génération d'un dataset clean prêt à être utilisé dans Power BI.

### Analyse et Visualisation
- **Outil de BI :** Power BI
- **Visualisations :**
  - Graphiques interactifs et tableaux croisés dynamiques.
  - Carte géographique illustrant l'implantation des stations et la fréquentation.
- **Accessibilité :** Tous les visuels ont été conçus en tenant compte des besoins des personnes en situation de handicap visuel.

## Livrables

1. **Présentation Slides (PDF)**
   - Contexte et problématique.
   - Méthodologie et outils utilisés.
   - Argumentation claire et vulgarisée pour convaincre les investisseurs.
   - Recommandations sur l’augmentation du taux de conversion et l’implantation de nouvelles stations.

2. **Dashboard Interactif**
   - Visualisations interactives dans Power BI.
   - Carte géographique des stations.
   - Tableaux croisés dynamiques pour explorer les données.
   - **Screenshots du dashboard Power BI :** Ces captures d'écran se trouvent dans le dossier `powerbi/screenshots`.

3. **Fichiers Power BI**
   - Un fichier Power BI complet est disponible en format `.pbit` (template).  
   - **Instructions pour générer le fichier `.pbix` complet :**
     1. Clonez le dépôt et ouvrez le fichier `.pbit` dans Power BI Desktop.
     2. Lors de l'ouverture, Power BI vous demandera de spécifier les sources de données. Sélectionnez le fichier CSV nettoyé (situé dans le dossier `notebook`).
     3. Une fois la source définie, le fichier sera converti en un fichier `.pbix` opérationnel.
     
4. **Code & Analyse Exploratoire**
   - Code de prétraitement et d’analyse contenu dans un Google Colab (accessible dans le dépôt).

## Technologies et Outils

- **Langages et outils de data science :**
  - Python pour le prétraitement et l’analyse exploratoire.
  - Google Colab pour l’exécution du code.
- **Outil de visualisation :**
  - Power BI pour la création du dashboard interactif.
- **Gestion de version :**
  - Git et GitHub pour le suivi des versions et la collaboration.


## Instructions d'Utilisation

1. **Cloner le dépôt :**
   ```bash
   git clone https://github.com/david-b59/PROJECTS/tree/main/Cyclistic-ashboard

2. **Explorer le code :**
* Ouvrez le notebook data_exploration.ipynb dans Google Colab ou Jupyter Notebook pour examiner le processus de nettoyage et de traitement des données.

3. **Préparer le Dashboard Power BI :**
* Ouvrez le fichier Cyclistic_Dashboard.pbit dans Power BI Desktop.
* Lorsque vous y êtes invité, définissez la source de données en sélectionnant le fichier CSV nettoyé situé dans le dossier notebook.
* Cela convertira le fichier en un fichier Power BI opérationnel au format .pbix.

4. Visualiser le Dashboard :
* Une fois le fichier .pbix généré, vous pouvez interagir avec les visualisations dans Power BI Desktop.
* Consultez également les captures d'écran dans le dossier powerbi/screenshots pour un aperçu rapide du dashboard.

## Conclusion
Ce projet a permis de dégager des insights clés sur l'utilisation des vélos par les cyclistes occasionnels et les membres annuels, offrant ainsi une base solide pour formuler des recommandations stratégiques destinées à convertir davantage d'utilisateurs occasionnels en abonnés annuels. L'intégration de visualisations interactives et accessibles garantit que les investisseurs, même sans expertise technique, peuvent comprendre et apprécier la valeur ajoutée de cette analyse.
