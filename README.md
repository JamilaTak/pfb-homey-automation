# pfb-homey-automation
Projet de Fin de Bloc B - Homey - Automatisation de tests
Tests automatisés avec Robot Framework et SeleniumLibrary.
URL du site à tester : http://livraison3.testacademy.fr/

## Prérequis
- Python 3.10 ou plus récent (ici 3.15.0)
- Google Chrome (ou Firefox) installé
- Git

## Installation
1. Cloner le dépôt :
   ```
   git clone https://github.com/JamilaTak/pfb-homey-automation
   cd pfb-homey-automation
   ```
2. Créer un environnement virtuel :
   ```
   python -m venv venv
   venv\Scripts\activate
   ```
3. Installer les dépendances :
   ```
   pip install -r requirements.txt
   ```

## Lancer les tests
Tous les tests :
##---------------TODO à mettre à jour : 
```
robot -d results tests/
```

Un seul fichier :
##---------------TODO à mettre à jour : 
```
robot -d results tests/login.robot
```

Les rapports (`report.html`, `log.html`) sont générés dans le dossier `results/`.

## Structure du projet
- fichier requirements.txt : dépendances
- fichier .gitignore
- `tests/` : les suites de tests (.robot) - un fichier par User Story
- `resources/` : mots-clés et variables réutilisables
- `results/` : rapports générés (non versionnés) et ignorés par Git (grâce au fichier .gitignore)
- `Jenkinsfile/` : fichier de pipeline CI/CD Jenkins

## Auteur
Jamila TAKKI
