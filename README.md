# pfb-homey-automation
Projet de Fin de Bloc B - Homey - Automatisation de tests.
Tests automatisés avec Robot Framework et SeleniumLibrary.
URL du site à tester : http://livraison3.testacademy.fr/

## Prérequis
- Python 3.10 ou plus récent (ici 3.15.0)
- robotframework==7.5
- robotframework-seleniumlibrary==6.9.0
- selenium==4.51.0
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
      
## Exécuter les tests sur un poste avec le projet déjà installé

Dans le terminal de VS Code :
1. Ouvrir le dossier pfb-homey-automation dans VS Code.
2. Ouvrir le terminal : menu Terminal > Nouveau terminal. Il s'ouvre déjà à la racine du projet.
3. Taper une commande au choix (exemples ci-dessous) :
   ```
   robot --outputdir results tests/
   robot --outputdir results --include TEST07-7 tests/
   ```

OU 

Avec cmd Windows :
1. Ouvrir cmd.
2. Aller à la racine du projet (adapter le chemin à son poste) :
   ```
   cd C:\GitHub\pfb-homey-automation
   ```
3. Vérifier qu'on est au bon endroit : la commande `dir` doit afficher `tests`, `resources`, `README.md`...
   ```
   dir
   ```
4. Lancer les mêmes commandes au choix :
   ```
   robot --outputdir results tests/
   robot --outputdir results --include TEST07-7 tests/
   ```

Si Robot ne se lance pas, vérifier l'installation avec `robot --version`.


## Exécuter les tests en local
Depuis le dossier racine du projet (avec l'environnement virtuel activé s'il y en a un).

Exécuter UN SEUL fichier de test (ou une User Story) :
```
robot --outputdir results tests/US07_demande_reservation.robot
robot --outputdir results tests/US08_traiter_reservation.robot
```

Exécuter TOUS les tests :
```
robot --outputdir results tests/
```

Exécuter uniquement les tests P1 :
```
robot --outputdir results --include P1 tests/
```

Lancer UN test précis (le numéro du test est précédé de celui de la User Story) :
```
robot --outputdir results --include TEST07-1 tests/
robot --outputdir results --include TEST08-12 tests/
```

Autres filtres possibles :
```
robot --outputdir results --include US07 tests/
robot --outputdir results --include US07ANDnominal tests/
robot --outputdir results --include TEST07-6ORTEST07-10 tests/
```

Marqueurs (tags) disponibles :
- User Story : `US07`, `US08`
- Priorité : `P1` pour la US07, `P2` pour la US08
- Type de cas : `nominal`, `exception`, `erreur` (définitions ci-dessous)
- Numéro de test : `TEST07-1`, `TEST07-2`, ... , `TEST08-1`, `TEST08-5`, `TEST08-9`, `TEST08-12`

Type de cas (qui est à l'origine du problème ?) :
- `nominal` : scénario normal, tout se passe bien, le résultat attendu est un succès.
- `exception` : l'utilisateur fait une action interdite ou invalide (saisie incorrecte, date impossible, non connecté...) et le système doit la refuser.
- `erreur` : l'action de l'utilisateur est normale, mais l'état du système ou des données ne permet pas de la réussir (donnée manquante, configuration absente, incohérence...).

Tests codés :
- US07 (P1) : 07-1 et 07-2 (nominal) ; 07-3, 07-6, 07-7, 07-10, 07-11, 07-12, 07-15, 07-17 (exception)
- US08 (P2) : 08-1, 08-5 et 08-12 (nominal) ; 08-9 (erreur)

## Résultats
Les rapports sont générés dans le dossier `results/` :
- `log.html` et `report.html` : rapports Robot Framework (traces détaillées et captures d'écran)
- `recapitulatif_US07.csv`, `recapitulatif_US08.csv` : tableau récapitulatif de chaque User Story
  (affiché aussi dans la console et dans le log)

Un test qui détecte une anomalie du site (message « … - anomalie détectée - poursuite du test »)
reste exécuté jusqu'au bout : il apparaît « PASS avec anomalies » dans le récapitulatif,
avec le nombre d'anomalies et une capture d'écran par anomalie.

Les données créées par les tests (demandes de réservation) sont nettoyées à la fin de chaque test.

## Structure du projet
- `requirements.txt` : dépendances Python
- `.gitignore` : fichiers exclus de Git (résultats, captures, fichiers Python temporaires)
- `tests/` : les suites de tests (.robot), un fichier par User Story (scénarios en français, aucun détail technique)
  - `US07_demande_reservation.robot`
  - `US08_traiter_reservation.robot`
- `resources/` : mots-clés et variables réutilisables
  - `variables.robot` : toutes les données de test (URL, identifiants, dates, textes attendus)
  - `recapitulatif.robot` : tableau récapitulatif, anomalies, captures d'écran
  - `pages/` : un fichier par page du site (sélecteurs et mots-clés de la page)
    - `page_accueil.robot`, `page_connexion.robot`, `page_annonce.robot`, `page_reservation.robot`
    - `page_voyages_voyageur.robot`, `page_paiement_voyageur.robot`
    - `page_reservations_hote.robot`, `page_messages_hote.robot`, `page_profil_hote.robot`
- `results/` : rapports générés (non versionnés, ignorés par Git grâce au fichier `.gitignore`)
- `Jenkinsfile` : pipeline CI/CD Jenkins (clone du dépôt, installation des dépendances, exécution des tests, archivage des rapports)


Les sélecteurs sont uniquement dans `resources/pages/`, les données uniquement dans `resources/variables.robot`.

## Auteur
Jamila TAKKI
