*** Settings ***
Documentation     US08 - Traiter une réservation
...               TEST 08-1 : une demande envoyée par un voyageur est reçue par l'hôte dans sa page Réservations, au statut NOUVEAU,
...               avec les mêmes dates de début et de fin et le même nombre de voyageurs + nettoyage (refus par l'hôte)
...               TEST 08-5 : l'hôte confirme la réservation (avec un frais supplémentaire et une remise) ; statut ATTENTE DE PAIEMENT côté hôte, DISPONIBLE côté voyageur + nettoyage (refus par l'hôte)
...               TEST 08-9 : l'hôte jtahote2 n'a pas renseigné ses informations de paiement (page Profil > Paiement vide = prérequis) : le voyageur ne doit pas pouvoir marquer le voyage comme payé ; il reste DISPONIBLE (RÉSERVÉ = anomalie) + nettoyage (annulation par l'hôte)
...               TEST 08-12 : le voyageur paye la demande confirmée (paiement hors-site, Marquer comme payé) ; statut RÉSERVÉ côté voyageur et côté hôte + nettoyage (annulation par l'hôte)
Library           SeleniumLibrary
Resource          ../resources/pages/page_accueil.robot
Resource          ../resources/pages/page_connexion.robot
Resource          ../resources/pages/page_annonce.robot
Resource          ../resources/pages/page_reservation.robot
Resource          ../resources/pages/page_voyages_voyageur.robot
Resource          ../resources/pages/page_reservations_hote.robot
Resource          ../resources/pages/page_profil_hote.robot
Resource          ../resources/pages/page_paiement_voyageur.robot
Resource          ../resources/variables.robot
Resource          ../resources/recapitulatif.robot

Test Setup        Ouvrir l'application
# Si le test échoue en cours de route, la réservation créée est nettoyée avant la fermeture du navigateur
Test Teardown     Terminer le test avec nettoyage de sécurité
# Génère le tableau récapitulatif et le fichier results/recapitulatif_US08.csv
Suite Teardown    Afficher le récapitulatif des tests    US08


*** Test Cases ***

# ---------- TEST 08-1 ----------
TEST 08-1 - CAS NOMINAL - L'hôte reçoit la nouvelle réservation au statut NOUVEAU
    [Documentation]    TEST 08-1 : quand un voyageur envoie avec succès une demande de réservation, l'hôte de l'annonce la reçoit
    ...                dans sa page Réservations au statut NOUVEAU, avec les bonnes dates de début et de fin et le bon nombre de voyageurs.
    [Tags]    US08    P2    nominal    TEST08-1
    # Le voyageur envoie une demande de réservation (mot-clé commun)
    Le voyageur envoie une demande de réservation et la retrouve dans ses voyages
    # L'hôte consulte sa page Réservations : la réservation est présente, au statut NOUVEAU, avec les mêmes dates et le même nombre de voyageurs
    L'hôte retrouve la nouvelle réservation au statut NOUVEAU
    # Nettoyage : l'hôte refuse la réservation de test pour libérer les dates du calendrier
    Nettoyer la réservation de test par un refus

# ---------- TEST 08-5 ----------
TEST 08-5 - CAS NOMINAL - L'hôte confirme la réservation
    [Documentation]    TEST 08-5 : copie du TEST 08-1, mais l'hôte CONFIRME la réservation (avec un frais supplémentaire et une remise) au lieu de la refuser.
    ...                Côté hôte le statut devient ATTENTE DE PAIEMENT ; côté voyageur le voyage devient DISPONIBLE avec les frais et la remise affichés.
    ...                Nettoyage en fin de test : l'hôte refuse la réservation confirmée pour libérer les dates du calendrier.
    [Tags]    US08    P2    nominal    TEST08-5
    # Le voyageur envoie une demande de réservation (mot-clé commun)
    Le voyageur envoie une demande de réservation et la retrouve dans ses voyages
    # L'hôte retrouve la réservation au statut NOUVEAU avant de la confirmer (mot-clé commun)
    L'hôte retrouve la nouvelle réservation au statut NOUVEAU
    # L'hôte confirme la réservation (mot-clé commun)
    L'hôte confirme la réservation avec un frais supplémentaire et une remise, et contrôle son statut
    # Le voyageur contrôle le même voyage (même ID) (mot-clé commun)
    Le voyageur contrôle son voyage confirmé (statut DISPONIBLE, frais et remise)
    # Nettoyage : l'hôte refuse la réservation confirmée pour libérer les dates du calendrier
    L'utilisateur se déconnecte puis l'hôte se connecte
    Ouvrir la boîte Réservations
    Nettoyer la réservation de test par un refus

# ---------- TEST 08-9 ----------
TEST 08-9 - CAS D'ERREUR - Le voyageur ne peut pas payer si l'hôte n'a pas de coordonnées de paiement
    [Documentation]    TEST 08-9 : copie du TEST 08-12 avec un nouvel hôte (jtahote2) et une nouvelle annonce (jta-maroc-13). Cet hôte n'a PAS renseigné ses informations de paiement
    ...                (prérequis bloquant : sa page Profil > Paiement doit être vide). Le voyageur ne doit donc pas pouvoir marquer le voyage comme payé :
    ...                le voyage reste DISPONIBLE (côté voyageur) et ATTENTE DE PAIEMENT (côté hôte). S'il passe à RÉSERVÉ, c'est une anomalie tracée (le test se poursuit).
    ...                Nettoyage en fin de test : l'hôte ANNULE la réservation (statut ANNULÉ).
    [Tags]    US08    P2    erreur    TEST08-9
    # L'hôte du test et sa connexion de nettoyage de sécurité
    Set Test Variable    ${HOTE_DU_TEST_EMAIL}    ${HOTE2_EMAIL}
    Set Test Variable    ${HOTE_DU_TEST_PASSWORD}    ${HOTE2_PASSWORD}
    # ----- Prérequis (bloquant) : la page Profil > Paiement de l'hôte jtahote2 est vide -----
    Se connecter en tant qu'hôte    ${HOTE2_EMAIL}    ${HOTE2_PASSWORD}
    La connexion doit être confirmée
    Relever les coordonnées de paiement de l'hôte
    Les coordonnées de paiement de l'hôte doivent être vides    ${COORDONNEES_HOTE}
    Se déconnecter
    # Le voyageur envoie une demande de réservation sur l'annonce jta-maroc-13 (mot-clé commun)
    Le voyageur envoie une demande de réservation et la retrouve dans ses voyages    ${URL_ANNONCE_TEST08_9}    ${ADRESSE_ANNONCE_TEST08_9}
    # L'hôte jtahote2 retrouve la réservation au statut NOUVEAU (mot-clé commun)
    L'hôte retrouve la nouvelle réservation au statut NOUVEAU    ${HOTE2_EMAIL}    ${HOTE2_PASSWORD}    ${ADRESSE_ANNONCE_TEST08_9}
    # L'hôte confirme la réservation (mot-clé commun)
    L'hôte confirme la réservation avec un frais supplémentaire et une remise, et contrôle son statut
    # Le voyageur contrôle son voyage DISPONIBLE (mot-clé commun)
    Le voyageur contrôle son voyage confirmé (statut DISPONIBLE, frais et remise)
    # ----- Tentative de paiement par le voyageur : le site doit la bloquer -----
    Ouvrir le détail du voyage pour payer    ${ID_VOYAGE}
    Les informations du séjour et du paiement doivent être affichées côté voyageur    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${DUREE_SEJOUR_JOURS}    ${NB_VOYAGEURS_ENVOYES}
    Cliquer sur Payez maintenant avec le prix affiché
    La page de paiement hors-site doit être affichée
    Les coordonnées de paiement doivent être vides côté voyageur
    Revenir au détail du voyage
    Le voyageur tente de payer alors que l'hôte n'a pas de coordonnées de paiement    ${ID_VOYAGE}    ${STATUT_RESERVE_ATTENDU}
    Ouvrir la page Voyages
    Le statut du voyage doit être resté    ${ID_VOYAGE}    ${STATUT_CONFIRME_ATTENDU_VOYAGEUR}    ${STATUT_RESERVE_ATTENDU}
    # ----- Contrôle côté hôte jtahote2 : toujours ATTENTE DE PAIEMENT, jamais RÉSERVÉ -----
    L'utilisateur se déconnecte puis l'hôte se connecte    ${HOTE2_EMAIL}    ${HOTE2_PASSWORD}
    Ouvrir la boîte Réservations
    Le statut de la réservation non payée doit être conservé    ${ID_VOYAGE}    ${STATUT_CONFIRME_ATTENDU_HOTE}    ${STATUT_RESERVE_ATTENDU}
    # ----- Nettoyage : l'hôte annule la réservation pour libérer les dates du calendrier -----
    Annuler la réservation pour nettoyer les données de test    ${ID_VOYAGE}    ${MOTIF_ANNULATION}    ${STATUT_ANNULE_ATTENDU}
    L'annulation de la réservation doit être constatée dans le tableau    ${ID_VOYAGE}    ${STATUT_ANNULE_ATTENDU}

# ---------- TEST 08-12 ----------
TEST 08-12 - CAS NOMINAL - Le voyageur paye la réservation confirmée
    [Documentation]    TEST 08-12 : copie du TEST 08-5 (sans son nettoyage de fin) puis le voyageur PAIE son voyage DISPONIBLE (paiement hors-site, "Marquer comme payé").
    ...                Le voyage et la réservation passent au statut RÉSERVÉ côté voyageur et côté hôte.
    ...                Nettoyage en fin de test : l'hôte ANNULE la réservation (statut ANNULÉ).
    [Tags]    US08    P2    nominal    TEST08-12
    # Le voyageur envoie une demande de réservation (mot-clé commun)
    Le voyageur envoie une demande de réservation et la retrouve dans ses voyages
    # L'hôte retrouve la réservation au statut NOUVEAU avant de la confirmer (mot-clé commun)
    L'hôte retrouve la nouvelle réservation au statut NOUVEAU
    # L'hôte confirme la réservation (mot-clé commun)
    L'hôte confirme la réservation avec un frais supplémentaire et une remise, et contrôle son statut
    # L'hôte relève ses coordonnées bancaires (Profil > Paiement) : elles serviront de référence pour la page de paiement du voyageur
    Relever les coordonnées de paiement de l'hôte
    # Le voyageur contrôle le même voyage (même ID) (mot-clé commun)
    Le voyageur contrôle son voyage confirmé (statut DISPONIBLE, frais et remise)
    # ----- Paiement par le voyageur (suite du TEST 08-12) -----
    Ouvrir le détail du voyage pour payer    ${ID_VOYAGE}
    Les informations du séjour et du paiement doivent être affichées côté voyageur    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${DUREE_SEJOUR_JOURS}    ${NB_VOYAGEURS_ENVOYES}
    Cliquer sur Payez maintenant avec le prix affiché
    La page de paiement hors-site doit être affichée
    Les coordonnées de l'hôte doivent être affichées au voyageur    ${COORDONNEES_HOTE}
    Revenir au détail du voyage
    Le voyageur paye sa demande avec Marquer comme payé    ${ID_VOYAGE}    ${STATUT_RESERVE_ATTENDU}
    Ouvrir la page Voyages
    Le statut du voyage doit être    ${ID_VOYAGE}    ${STATUT_RESERVE_ATTENDU}
    # ----- Contrôle côté hôte -----
    L'utilisateur se déconnecte puis l'hôte se connecte
    Ouvrir la boîte Réservations
    Le statut de la réservation dans le tableau doit être    ${ID_VOYAGE}    ${STATUT_RESERVE_ATTENDU}
    Ouvrir le détail de la réservation    ${ID_VOYAGE}
    Le statut du détail de la réservation doit être    ${ID_VOYAGE}    ${STATUT_RESERVE_ATTENDU}
    # ----- Nettoyage : l'hôte annule la réservation pour libérer les dates du calendrier -----
    Annuler la réservation pour nettoyer les données de test    ${ID_VOYAGE}    ${MOTIF_ANNULATION}    ${STATUT_ANNULE_ATTENDU}
    L'annulation de la réservation doit être constatée dans le tableau    ${ID_VOYAGE}    ${STATUT_ANNULE_ATTENDU}

*** Keywords ***
# ---------- Étapes communes aux tests 5, 9 et 12 (celles communes à US07 et US08 sont dans resources/etapes_communes.robot) ----------
L'hôte confirme la réservation avec un frais supplémentaire et une remise, et contrôle son statut
    [Documentation]    Étapes communes aux tests 5, 9 et 12 : détail de paiement, actions disponibles, confirmation avec frais et remise,
    ...                statut côté hôte, frais et remise pris en compte côté hôte.
    Ouvrir la page de détails de paiement de la réservation    ${ID_VOYAGE}    ${DUREE_SEJOUR_JOURS}
    Les actions de confirmation doivent être disponibles
    # L'hôte CONFIRME la réservation avec un frais supplémentaire et une remise
    Confirmer la réservation avec un frais supplémentaire et une remise    ${ID_VOYAGE}    ${FRAIS_SUPPLEMENTAIRE_NOM}    ${FRAIS_SUPPLEMENTAIRE_VALEUR}    ${REMISE_NOM}    ${REMISE_VALEUR}
    Le statut de la réservation confirmée doit être    ${ID_VOYAGE}    ${STATUT_CONFIRME_ATTENDU_HOTE}    ${STATUT_RESERVATION_ATTENDU}    ${STATUT_REFUS_ATTENDU}
    Les frais supplémentaires et la remise doivent être pris en compte côté hôte    ${ID_VOYAGE}    ${DUREE_SEJOUR_JOURS}    ${FRAIS_SUPPLEMENTAIRE_NOM}    ${FRAIS_SUPPLEMENTAIRE_VALEUR}    ${REMISE_NOM}    ${REMISE_VALEUR}

Le voyageur contrôle son voyage confirmé (statut DISPONIBLE, frais et remise)
    [Documentation]    Étapes communes aux tests 5, 9 et 12 : l'utilisateur se déconnecte, le voyageur se connecte et contrôle le voyage (même ID) :
    ...                statut DISPONIBLE, frais supplémentaire et remise affichés.
    L'utilisateur se déconnecte puis le voyageur se connecte
    Ouvrir la page Voyages
    Le statut du voyage doit être    ${ID_VOYAGE}    ${STATUT_CONFIRME_ATTENDU_VOYAGEUR}
    Les frais supplémentaires et la remise doivent être affichés côté voyageur    ${ID_VOYAGE}    ${STATUT_CONFIRME_ATTENDU_VOYAGEUR}    ${FRAIS_SUPPLEMENTAIRE_NOM}    ${FRAIS_SUPPLEMENTAIRE_VALEUR}    ${REMISE_NOM}    ${REMISE_VALEUR}
