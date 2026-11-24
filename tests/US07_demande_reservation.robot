*** Settings ***
Documentation     US07 - Effectuer une demande de réservation
...               TEST 07-1 : voyageur connecté, tous les champs valides (cas nominal) + réception côté hôte + nettoyage (refus par l'hôte)
...               TEST 07-2 : voyageur connecté, tous les champs valides avec 3 voyageurs + réception côté hôte + nettoyage (refus par l'hôte)
...               TEST 07-3 : visiteur non connecté, 1 voyageur (cas d'exception)
...               TEST 07-6 : demande commençant à la date du jour (doit être refusée)
...               TEST 07-7 : demande commençant hier, dans le passé (OK si la date passée n'est pas sélectionnable)
...               TEST 07-10 : demande pour une seule journée à la date du jour (doit être refusée)
...               TEST 07-11 : demande se terminant hier, dans le passé (OK si la date passée n'est pas sélectionnable)
...               TEST 07-12 : date de fin antérieure à la date de début, deux dates futures valides (OK si le calendrier l'empêche)
...               TEST 07-15 : demande avec 0 voyageur (doit être refusée)
...               TEST 07-17 : demande sur des dates déjà réservées (message d'erreur, aucune 2e réservation)
Library           SeleniumLibrary
Resource          ../resources/pages/page_accueil.robot
Resource          ../resources/pages/page_connexion.robot
Resource          ../resources/pages/page_annonce.robot
Resource          ../resources/pages/page_reservation.robot
Resource          ../resources/pages/page_voyages_voyageur.robot
Resource          ../resources/pages/page_messages_hote.robot
Resource          ../resources/pages/page_reservations_hote.robot
Resource          ../resources/variables.robot
Resource          ../resources/recapitulatif.robot

Test Setup        Ouvrir l'application
# Si le test échoue en cours de route, la réservation créée est nettoyée avant la fermeture du navigateur
Test Teardown     Terminer le test avec nettoyage de sécurité
Suite Teardown    Afficher le récapitulatif des tests


*** Test Cases ***

# ---------- TEST 07-1 ----------
TEST 07-1 - CAS NOMINAL - Faire une demande de réservation
    [Documentation]    TEST 07-1 : un voyageur connecté peut envoyer une demande de réservation avec tous les champs valides
    [Tags]    US07    P1    nominal    TEST07-1
    Une demande valide est envoyée par le voyageur puis reçue par l'hôte    ${NOMBRE_ADULTES}

# ---------- TEST 07-2 ----------
TEST 07-2 - CAS NOMINAL - Faire une demande de réservation avec 3 voyageurs
    [Documentation]    TEST 07-2 : identique au TEST 07-1, mais avec 3 voyageurs
    [Tags]    US07    P1    nominal    TEST07-2
    Une demande valide est envoyée par le voyageur puis reçue par l'hôte    ${NOMBRE_ADULTES_TEST07_2}

# ---------- TEST 07-3 ----------
TEST 07-3 - CAS EXCEPTION - Réservation sans être connecté
    [Documentation]    TEST 07-3 : un visiteur non connecté ne peut pas réserver : un message l'invite à se connecter
    [Tags]    US07    P1    exception    TEST07-3
    Naviguer vers l'annonce    ${URL_ANNONCE_TEST}
    Sélectionner des dates réservables    ${DECALAGE_JOURS_INITIAL}    ${DUREE_SEJOUR_JOURS}    ${DECALAGE_JOURS_MAXIMUM}
    Renseigner le nombre d'adultes et le message puis envoyer la demande
    Le message de connexion obligatoire doit être affiché

# ---------- TEST 07-6 ----------
TEST 07-6 - CAS EXCEPTION - Demande de réservation commençant à la date du jour
    [Documentation]    TEST 07-6 : identique au TEST 07-1 mais l'arrivée est aujourd'hui et le départ est postérieur.
    ...                Le système ne doit pas accepter la demande ; si elle est acceptée, c'est tracé en anomalie détectée.
    [Tags]    US07    P1    exception    TEST07-6
    Le voyageur se connecte et ouvre l'annonce
    Sélectionner des dates dont l'arrivée est aujourd'hui    ${DUREE_SEJOUR_JOURS}
    Renseigner le nombre d'adultes et le message puis envoyer la demande
    Contrôler que la demande a été refusée et nettoyer si elle a été acceptée

# ---------- TEST 07-7 ----------
TEST 07-7 - CAS EXCEPTION - Demande de réservation commençant dans le passé
    [Documentation]    TEST 07-7 : identique au TEST 07-6 mais l'arrivée est hier (dans le passé) et le départ est aujourd'hui + 2 jours.
    ...                Si le calendrier empêche de choisir la date passée, le test est OK. Sinon la demande est tentée et, si elle est
    ...                acceptée, c'est tracé en anomalie détectée.
    [Tags]    US07    P1    exception    TEST07-7
    Le voyageur se connecte et ouvre l'annonce
    Constater que la date passée ne peut pas être sélectionnée    ${DECALAGE_PASSE_JOURS}
    Sélectionner une date passée et une date future disponible    ${DECALAGE_PASSE_JOURS}    ${DECALAGE_FUTUR_JOURS}    ${DECALAGE_JOURS_MAXIMUM}    ${TRUE}
    Renseigner le nombre d'adultes et le message puis envoyer la demande
    Contrôler que la demande a été refusée et nettoyer si elle a été acceptée    commençant dans le passé (hier) et finissant dans le futur

# ---------- TEST 07-10 ----------
TEST 07-10 - CAS EXCEPTION - Demande de réservation pour une seule journée à la date du jour
    [Documentation]    TEST 07-10 : identique au TEST 07-6 mais l'arrivée ET le départ sont aujourd'hui (une seule journée).
    ...                Le système ne doit pas accepter la demande ; si elle est acceptée, c'est tracé en anomalie détectée.
    [Tags]    US07    P1    exception    TEST07-10
    Le voyageur se connecte et ouvre l'annonce
    Sélectionner des dates dont l'arrivée est aujourd'hui    ${DUREE_UNE_JOURNEE_JOURS}
    Renseigner le nombre d'adultes et le message puis envoyer la demande
    Contrôler que la demande a été refusée et nettoyer si elle a été acceptée    d'une seule journée à la date du jour

# ---------- TEST 07-11 ----------
TEST 07-11 - CAS EXCEPTION - Demande de réservation se terminant dans le passé
    [Documentation]    TEST 07-11 : identique au TEST 07-6 mais l'arrivée est aujourd'hui + 2 jours et le départ est hier (dans le passé).
    ...                Si le calendrier empêche de choisir la date passée, le test est OK. Sinon la demande est tentée et, si elle est
    ...                acceptée, c'est tracé en anomalie détectée.
    [Tags]    US07    P1    exception    TEST07-11
    Le voyageur se connecte et ouvre l'annonce
    Constater que la date passée ne peut pas être sélectionnée    ${DECALAGE_PASSE_JOURS}
    Sélectionner une date passée et une date future disponible    ${DECALAGE_PASSE_JOURS}    ${DECALAGE_FUTUR_JOURS}    ${DECALAGE_JOURS_MAXIMUM}    ${FALSE}
    Renseigner le nombre d'adultes et le message puis envoyer la demande
    Contrôler que la demande a été refusée et nettoyer si elle a été acceptée    se terminant dans le passé (hier)

# ---------- TEST 07-12 ----------
TEST 07-12 - CAS EXCEPTION - Demande de réservation dont la date de fin est antérieure à la date de début
    [Documentation]    TEST 07-12 : arrivée et départ sont deux dates futures valides (ni passé, ni aujourd'hui) mais la date de fin est
    ...                antérieure à la date de début (ex. du 24 au 22). Si le calendrier empêche cette sélection, le test est OK.
    ...                Sinon la demande est tentée et, si elle est acceptée, c'est tracé en anomalie détectée.
    [Tags]    US07    P1    exception    TEST07-12
    Le voyageur se connecte et ouvre l'annonce
    Sélectionner une arrivée future et un départ antérieur valide    ${DECALAGE_FUTUR_JOURS}    ${ECART_INVERSION_JOURS}    ${DECALAGE_JOURS_MAXIMUM}
    Renseigner le nombre d'adultes et le message puis envoyer la demande
    Contrôler que la demande a été refusée et nettoyer si elle a été acceptée    dont la date de fin est antérieure à la date de début

# ---------- TEST 07-15 ----------
TEST 07-15 - CAS EXCEPTION - Demande de réservation avec un nombre de voyageurs nul
    [Documentation]    TEST 07-15 : identique au TEST 07-1 mais avec 0 voyageur. Le système ne doit pas accepter la demande ;
    ...                si elle est acceptée, c'est tracé en anomalie détectée.
    [Tags]    US07    P1    exception    TEST07-15
    Le voyageur se connecte et ouvre l'annonce
    Sélectionner des dates réservables    ${DECALAGE_JOURS_INITIAL}    ${DUREE_SEJOUR_JOURS}    ${DECALAGE_JOURS_MAXIMUM}
    Renseigner le nombre d'adultes et le message puis envoyer la demande    ${NOMBRE_VOYAGEURS_NUL}
    Contrôler que la demande a été refusée et nettoyer si elle a été acceptée    avec un nombre de voyageurs nul

# ---------- TEST 07-17 ----------
TEST 07-17 - CAS EXCEPTION - Demande de réservation sur des dates déjà réservées
    [Documentation]    TEST 07-17 : une première demande réserve des dates ; une deuxième demande sur les mêmes dates affiche
    ...                un message d'erreur et n'est pas envoyée (une seule réservation existe côté voyageur et côté hôte).
    [Tags]    US07    P1    exception    TEST07-17
    Le voyageur envoie une demande de réservation sur des dates réservables
    # Deuxième demande sur exactement les mêmes dates, désormais déjà réservées
    Sélectionner à nouveau les mêmes dates    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}
    Le message d'indisponibilité des dates doit être affiché
    Retenter la demande de réservation
    La demande ne doit pas être envoyée
    # Une seule demande doit exister côté voyageur (un "voyage")
    Ouvrir la page Voyages
    Un seul voyage doit exister pour les dates demandées    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${NB_VOYAGEURS_ENVOYES}    ${NOM_ANNONCE}
    Le voyage doit être présent dans Voyages avec les données envoyées
    # Une seule réservation doit exister côté hôte
    L'utilisateur se déconnecte puis l'hôte se connecte
    Ouvrir la boîte Réservations
    Une seule réservation doit exister pour les dates demandées    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${NB_VOYAGEURS_ENVOYES}    ${NOM_ANNONCE}
    La réservation doit être présente côté hôte avec les données envoyées
    Nettoyer la réservation de test par un refus


*** Keywords ***
Une demande valide est envoyée par le voyageur puis reçue par l'hôte
    [Documentation]    Tests 1 et 2 : le voyageur envoie une demande valide et la retrouve dans ses voyages ; l'hôte la reçoit dans ses Messages et dans ses Réservations
    ...                (statut NOUVEAU, mêmes dates, même nombre de voyageurs) ; nettoyage : l'hôte refuse la réservation de test.
    [Arguments]    ${nombre_adultes}
    Le voyageur envoie une demande de réservation et la retrouve dans ses voyages    nombre_adultes=${nombre_adultes}
    # Vérification côté hôte (la même demande s'appelle une "réservation") : les demandes envoyées doivent être reçues par le propriétaire de l'annonce
    L'utilisateur se déconnecte puis l'hôte se connecte
    Ouvrir la boîte Messages
    La demande de réservation doit être présente dans la boîte Messages
    Ouvrir la boîte Réservations
    La réservation doit être présente côté hôte avec les données envoyées
    Nettoyer la réservation de test par un refus

Contrôler que la demande a été refusée et nettoyer si elle a été acceptée
    [Documentation]    Fin commune des tests 6, 7, 10, 11, 12 et 15 (demande qui doit être refusée par le site).
    ...                Relève la réponse du site, compte les voyages créés côté voyageur, trace une anomalie si la demande a été acceptée,
    ...                puis dans ce cas seulement l'hôte refuse la réservation créée pour nettoyer les données de test.
    ...                Variables de test utilisées (posées par les étapes précédentes) : voir resources/variables.robot, section "Variables de test partagées".
    [Arguments]    ${description}=commençant à la date du jour
    Relever la réponse du site à la demande
    Ouvrir la page Voyages
    ${nombre_voyages}=    Relever le nombre de voyages créés pour les dates demandées    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${NB_VOYAGEURS_ENVOYES}    ${NOM_ANNONCE}
    Contrôler que la demande a été refusée    ${nombre_voyages}    ${description}
    IF    ${DEMANDE_ACCEPTEE_A_TORT}
        Le voyage doit être présent dans Voyages avec les données envoyées
        L'utilisateur se déconnecte puis l'hôte se connecte
        Ouvrir la boîte Réservations
        Nettoyer la réservation de test par un refus
    END
