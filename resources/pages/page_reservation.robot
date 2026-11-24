*** Settings ***
Library    SeleniumLibrary
Resource   ../variables.robot
Resource   ../recapitulatif.robot

*** Variables ***
# Bloc de notification affiché dans la colonne de réservation.
# Il affiche d'abord "Vos dates sont disponibles!" puis, une fois la demande traitée, le message de confirmation.
${RESERVATION_ZONE_NOTIFICATION}    css=.block-body-sidebar > .notify

*** Keywords ***
La confirmation de réservation doit être affichée
    Wait Until Element Contains    ${RESERVATION_ZONE_NOTIFICATION}    ${MESSAGE_RESERVATION_ENVOYEE}    timeout=30s
    Element Should Contain    ${RESERVATION_ZONE_NOTIFICATION}    ${MESSAGE_ATTENTE_CONFIRMATION}
    Log    Réservation envoyée OK : ${MESSAGE_RESERVATION_ENVOYEE} ${MESSAGE_ATTENTE_CONFIRMATION}    console=True
    Set Test Message    Annonce : ${ANNONCE_CHOISIE} | Séjour du ${SEJOUR_ARRIVEE} au ${SEJOUR_DEPART} | Réservation envoyée OK    append=True

Le message de connexion obligatoire doit être affiché
    [Documentation]    Visiteur non connecté : la demande est refusée avec un message d'erreur
    Wait Until Page Contains    ${MESSAGE_CONNEXION_REQUISE}    timeout=30s
    Log    Réservation refusée comme attendu : ${MESSAGE_CONNEXION_REQUISE}    console=True
    Set Test Message    Annonce : ${ANNONCE_CHOISIE} | Visiteur non connecté | Message attendu affiché : ${MESSAGE_CONNEXION_REQUISE}    append=True

Le message d'indisponibilité des dates doit être affiché
    Wait Until Element Contains    ${RESERVATION_ZONE_NOTIFICATION}    ${MESSAGE_DATES_NON_DISPONIBLES}    timeout=20s
    Log    TEST 07-17 : message d'erreur affiché comme attendu : ${MESSAGE_DATES_NON_DISPONIBLES}    console=True
    Set Test Message    Message d'erreur affiché : ${MESSAGE_DATES_NON_DISPONIBLES}.    append=True

La demande ne doit pas être envoyée
    [Documentation]    Vérification négative : après un court délai, aucun message de succès ne doit être apparu.
    ...                Ce délai est volontairement fixe : on ne peut pas attendre l'apparition d'un élément qui ne doit PAS apparaître.
    Sleep    ${DELAI_VERIFICATION_ABSENCE}
    Element Should Contain    ${RESERVATION_ZONE_NOTIFICATION}    ${MESSAGE_DATES_NON_DISPONIBLES}
    Element Should Not Contain    ${RESERVATION_ZONE_NOTIFICATION}    ${MESSAGE_RESERVATION_ENVOYEE}
    Log    TEST 07-17 : aucun message de succès affiché, la deuxième demande n'est pas envoyée    console=True

Relever la réponse du site à la demande
    [Documentation]    Tests 6, 7, 10, 11, 12 et 15 : attend un éventuel message de succès ; sinon relève le message affiché par le site.
    ${succes_affiche}=    Run Keyword And Return Status    Wait Until Element Contains    ${RESERVATION_ZONE_NOTIFICATION}    ${MESSAGE_RESERVATION_ENVOYEE}    timeout=${DELAI_ATTENTE_ACCEPTATION}
    ${zone_visible}=    Run Keyword And Return Status    Element Should Be Visible    ${RESERVATION_ZONE_NOTIFICATION}
    ${reponse}=    Set Variable    (aucun message affiché)
    IF    ${zone_visible}
        ${reponse}=    Get Text    ${RESERVATION_ZONE_NOTIFICATION}
    END
    Set Test Variable    ${SUCCES_AFFICHE}    ${succes_affiche}
    Set Test Variable    ${REPONSE_SITE}    ${reponse}
    Log    Réponse du site à la demande : ${reponse}    console=True

Contrôler que la demande a été refusée
    [Documentation]    Tests 6, 7, 10, 11, 12 et 15 : refus attendu. Si la demande est acceptée (message de succès ou voyage créé), on trace une anomalie et on poursuit.
    [Arguments]    ${nombre_voyages_crees}    ${description}=commençant à la date du jour
    ${acceptee}=    Evaluate    $SUCCES_AFFICHE or int($nombre_voyages_crees) > 0
    Set Test Variable    ${DEMANDE_ACCEPTEE_A_TORT}    ${acceptee}
    IF    ${acceptee}
        Signaler une anomalie    Réservation ${description} acceptée à tort - anomalie détectée - poursuite du test (message du site : ${REPONSE_SITE} ; voyages créés : ${nombre_voyages_crees})
    ELSE
        Log    Demande ${description} refusée comme attendu (message du site : ${REPONSE_SITE})    console=True
        Set Test Message    Demande ${description} refusée comme attendu (message du site : ${REPONSE_SITE}).    append=True
    END

