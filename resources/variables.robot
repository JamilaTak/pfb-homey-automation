*** Variables ***
# ---------- Application ----------
${BASE_URL}                         http://livraison3.testacademy.fr/
${BROWSER}                          chrome
# Options Chrome : évite le pop-up "mot de passe" qui ferait échouer le test
${OPTIONS_CHROME}                   add_experimental_option("prefs", {"credentials_enable_service": False, "profile.password_manager_enabled": False, "profile.password_manager_leak_detection": False}); add_argument("--disable-features=PasswordLeakDetection")
# Taille de fenêtre du fichier .side (le bloc de réservation n'est affiché qu'en grand écran)
${LARGEUR_FENETRE}                  1550
${HAUTEUR_FENETRE}                  830

# ---------- Identifiants de test (voyageur du fichier .side) ----------
${VOYAGEUR_EMAIL}                   jamila.takki2@gmail.com
${VOYAGEUR_PASSWORD}                test

# ---------- Données du scénario US07 (TEST 07-1, TEST 07-2, TEST 07-3) ----------
${URL_ANNONCE_TEST}                 http://livraison3.testacademy.fr/index.php/listing/jta-maroc-12/
${TITRE_TABLEAU_DE_BORD}            Tableau de bord - Livraison 3
# Séjour de 2 jours. Le test cherche la première arrivée réservable à partir de
# "aujourd'hui + DECALAGE_JOURS_INITIAL" ; si les dates sont déjà prises, il se décale jour après jour
# jusqu'à "aujourd'hui + DECALAGE_JOURS_MAXIMUM" (le calendrier n'affiche que 2 mois)
${DUREE_SEJOUR_JOURS}               2
${DECALAGE_JOURS_INITIAL}           14
${DECALAGE_JOURS_MAXIMUM}           60
# TEST 07-1 (cas nominal) et TEST 07-3 (non connecté) : 1 voyageur ; TEST 07-2 (cas nominal) : 3 voyageurs
${NOMBRE_ADULTES}                   1
${NOMBRE_ADULTES_TEST07_2}             3
# Message à l'hôte (champ "Présentez-vous à l'hôte"), utilisé uniquement si le champ est présent
${MESSAGE_A_L_HOTE}                 Bonjour, je souhaite réserver votre logement.
${MESSAGE_RESERVATION_ENVOYEE}      Demande de réservation envoyée.
${MESSAGE_ATTENTE_CONFIRMATION}     Veuillez attendre la confirmation!
# TEST 07-3 : message attendu pour un visiteur non connecté
${MESSAGE_CONNEXION_REQUISE}         Vous devez vous connecter pour effectuer une réservation

# ---------- Compte hôte (propriétaire de l'annonce) - TEST 07-1 et TEST 07-2 ----------
${HOTE_EMAIL}                       jtahote
${HOTE_PASSWORD}                    test
${ADRESSE_ANNONCE_ATTENDUE}         Route d'amizmiz
# Côté voyageur la demande s'appelle un "voyage" ; côté hôte c'est une "réservation"
${STATUT_VOYAGE_ATTENDU}            À L'ÉTUDE
${STATUT_RESERVATION_ATTENDU}       NOUVEAU
# Écart maximal accepté entre l'heure d'envoi de la demande et l'heure affichée côté hôte
${TOLERANCE_HEURE_MINUTES}          10
${TEXTE_AUCUN_MESSAGE}              You don't have any message at this moment.

# ---------- Nettoyage (TEST 07-1 et TEST 07-2) : l'hôte refuse la réservation de test pour libérer le calendrier ----------
${MOTIF_REFUS}                      refus - nettoyage automatique des données de test
${STATUT_REFUS_ATTENDU}             REFUSÉ

# ---------- TEST 07-17 : demande sur des dates déjà réservées ----------
${MESSAGE_DATES_NON_DISPONIBLES}    Vos dates ne sont pas disponibles
# Attente avant de vérifier qu'un message n'apparaît PAS (vérification négative)
${DELAI_VERIFICATION_ABSENCE}       3s

# ---------- TEST 07-6 : demande commençant à la date du jour (arrivée = aujourd'hui, départ = aujourd'hui + DUREE_SEJOUR_JOURS) ----------
# Attente d'un éventuel message de succès (qui signalerait une réservation acceptée à tort)
${DELAI_ATTENTE_ACCEPTATION}        15s

# ---------- TEST 07-10 : une seule journée à la date du jour (arrivée = départ = aujourd'hui) ----------
${DUREE_UNE_JOURNEE_JOURS}          0

# ---------- TEST 07-7 et TEST 07-11 : dates dans le passé (décalages en jours par rapport à aujourd'hui) ----------
# -1 = hier ; 2 = aujourd'hui + 2 jours (date normalement acceptée)
${DECALAGE_PASSE_JOURS}             -1
${DECALAGE_FUTUR_JOURS}             2

# ---------- TEST 07-12 : date de fin antérieure à la date de début ----------
# Arrivée = départ + ECART_INVERSION_JOURS (ex. si aujourd'hui = 20 : arrivée le 24, départ le 22). Les deux dates sont dans le futur et disponibles.
${ECART_INVERSION_JOURS}            2

# ---------- TEST 07-15 : nombre de voyageurs nul ----------
${NOMBRE_VOYAGEURS_NUL}             0



# ---------- Données du scénario US08 (TEST 08-5 : confirmation par l'hôte) ----------
${FRAIS_SUPPLEMENTAIRE_NOM}            frais de cuisine
${FRAIS_SUPPLEMENTAIRE_VALEUR}         50
${REMISE_NOM}                          offre promo bienvenue
${REMISE_VALEUR}                       25
${STATUT_CONFIRME_ATTENDU_HOTE}        ATTENTE DE PAIEMENT
${STATUT_CONFIRME_ATTENDU_VOYAGEUR}    DISPONIBLE

# ---------- Données du scénario US08 (TEST 08-12 : paiement par le voyageur) ----------
${STATUT_RESERVE_ATTENDU}              RÉSERVÉ
${STATUT_ANNULE_ATTENDU}               ANNULÉ
${MOTIF_ANNULATION}                    annulation - nettoyage automatique des données de test
${MESSAGE_PAIEMENT_HORS_SITE}          Veuillez effectuer le paiement hors-site et cliquez sur le bouton "Marquer comme payé".
${METHODE_PAIEMENT_ATTENDUE}           Virement bancaire
${URL_PROFIL_PAIEMENT_HOTE}            ${BASE_URL}index.php/profile/?dpage=payment-method

# ---------- Données du scénario US08 (TEST 08-9 : l'hôte n'a pas renseigné ses informations de paiement) ----------
# Nouvelle annonce et nouvel hôte (jtahote2) dont la page Profil > Paiement est VIDE (prérequis contrôlé par le test)
${URL_ANNONCE_TEST08_9}                   http://livraison3.testacademy.fr/index.php/listing/jta-maroc-13/
${HOTE2_EMAIL}                         jtahote2
${HOTE2_PASSWORD}                      test
# Adresse affichée dans les tableaux pour l'annonce jta-maroc-13 : vide = non contrôlée (à renseigner si on la connaît)
${ADRESSE_ANNONCE_TEST08_9}               ${EMPTY}

# ============================================================================
# Variables de test partagées
# ----------------------------------------------------------------------------
# Ces variables ne sont PAS des réglages : elles sont remplies PENDANT le test
# (Set Test Variable) par un mot-clé, puis relues par les mots-clés suivants.
# Elles sont déclarées ici avec une valeur vide pour qu'on voie toutes les
# données qui circulent entre les étapes. Chaque test repart de cette valeur.
#
#   Variable                  Remplie par (fichier / mot-clé)                         Utilisée pour
#   ------------------------  ------------------------------------------------------  -----------------------------------------
#   ANNONCE_CHOISIE           page_annonce        Naviguer vers l'annonce             message du test / logs
#   NOM_ANNONCE               page_annonce        Naviguer vers l'annonce             retrouver la ligne dans Voyages/Réservations
#   SEJOUR_ARRIVEE            page_annonce        Sélectionner des dates...           contrôles voyageur et hôte
#   SEJOUR_DEPART             page_annonce        Sélectionner des dates...           contrôles voyageur et hôte
#   NB_VOYAGEURS_ENVOYES      page_annonce        Sélectionner le nombre d'adultes    contrôles voyageur et hôte
#   HEURE_ENVOI               page_annonce        Soumettre la demande...             contrôle de l'heure de la demande
#   SUCCES_AFFICHE            page_reservation    Relever la réponse du site...       tests "demande refusée"
#   REPONSE_SITE              page_reservation    Relever la réponse du site...       tests "demande refusée"
#   DEMANDE_ACCEPTEE_A_TORT   page_reservation    Contrôler que la demande a été refusée   décide du nettoyage côté hôte
#   ID_VOYAGE                 page_voyages_voyageur  Le voyage envoyé doit être présent   refus de la réservation (nettoyage)
#   COORDONNEES_HOTE          page_profil_hote    Relever les coordonnées de paiement  comparées à la page de paiement du voyageur (TEST 08-9 et 08-12)
#   HOTE_DU_TEST_EMAIL        tests/US08 (TEST 08-9)  hôte propriétaire de l'annonce      connexion du nettoyage de sécurité (vide = hôte par défaut)
#   HOTE_DU_TEST_PASSWORD     tests/US08 (TEST 08-9)  mot de passe de cet hôte            connexion du nettoyage de sécurité
#   PAIEMENT_ACCEPTE_A_TORT   page_voyages_voyageur  Le voyageur tente de payer...    TEST 08-9 : vrai si le site a accepté le paiement à tort
# ============================================================================
*** Variables ***
${ANNONCE_CHOISIE}             ${EMPTY}
${NOM_ANNONCE}                 ${EMPTY}
${SEJOUR_ARRIVEE}              ${EMPTY}
${SEJOUR_DEPART}               ${EMPTY}
${NB_VOYAGEURS_ENVOYES}        ${EMPTY}
${HEURE_ENVOI}                 ${EMPTY}
${SUCCES_AFFICHE}              ${FALSE}
${REPONSE_SITE}                ${EMPTY}
${DEMANDE_ACCEPTEE_A_TORT}     ${FALSE}
${ID_VOYAGE}                   ${EMPTY}
&{COORDONNEES_HOTE}
${HOTE_DU_TEST_EMAIL}          ${EMPTY}
${HOTE_DU_TEST_PASSWORD}       ${EMPTY}
${PAIEMENT_ACCEPTE_A_TORT}     ${FALSE}
