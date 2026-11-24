*** Settings ***
Library    SeleniumLibrary
Library    Collections
Resource   ../variables.robot
Resource   ../recapitulatif.robot

*** Variables ***
# Page Profil > Paiement de l'hôte (virement bancaire) : identifiants des champs
${PROFIL_PRENOM}                id=ben_first_name
${PROFIL_NOM}                   id=ben_last_name
${PROFIL_RUE}                   id=ben_street_address
${PROFIL_APPT}                  id=ben_apt_suit
${PROFIL_VILLE}                 id=ben_city
${PROFIL_ETAT}                  id=ben_state
${PROFIL_CODE_POSTAL}           id=ben_zip_code
${PROFIL_IBAN}                  id=bank_account
${PROFIL_SWIFT}                 id=swift
${PROFIL_NOM_BANQUE}            id=bank_name
${PROFIL_BANQUE_RUE}            id=wir_street_address
${PROFIL_BANQUE_APPT}           id=wir_aptsuit
${PROFIL_BANQUE_VILLE}          id=wir_city
${PROFIL_BANQUE_ETAT}           id=wir_state
${PROFIL_BANQUE_CODE_POSTAL}    id=wir_zip_code

*** Keywords ***
Relever les coordonnées de paiement de l'hôte
    [Documentation]    US08 : l'hôte (connecté) ouvre Profil > Paiement et on relève le bénéficiaire, son adresse et les coordonnées bancaires.
    ...                Ces valeurs servent ensuite de référence pour contrôler ce que le voyageur voit sur sa page de paiement.
    Log    Hôte : ouverture de la page Profil > Paiement pour relever ses coordonnées bancaires    console=True
    Go To    ${URL_PROFIL_PAIEMENT_HOTE}
    Wait Until Page Contains Element    ${PROFIL_PRENOM}    timeout=20s
    ${c}=    Create Dictionary
    FOR    ${cle}    ${champ}    IN
    ...    prenom    ${PROFIL_PRENOM}
    ...    nom    ${PROFIL_NOM}
    ...    rue    ${PROFIL_RUE}
    ...    appt    ${PROFIL_APPT}
    ...    ville    ${PROFIL_VILLE}
    ...    etat    ${PROFIL_ETAT}
    ...    code_postal    ${PROFIL_CODE_POSTAL}
    ...    iban    ${PROFIL_IBAN}
    ...    swift    ${PROFIL_SWIFT}
    ...    banque    ${PROFIL_NOM_BANQUE}
    ...    banque_rue    ${PROFIL_BANQUE_RUE}
    ...    banque_appt    ${PROFIL_BANQUE_APPT}
    ...    banque_ville    ${PROFIL_BANQUE_VILLE}
    ...    banque_etat    ${PROFIL_BANQUE_ETAT}
    ...    banque_code_postal    ${PROFIL_BANQUE_CODE_POSTAL}
        ${valeur}=    Get Value    ${champ}
        Set To Dictionary    ${c}    ${cle}=${valeur}
    END
    Log    Coordonnées de l'hôte : bénéficiaire ${c}[prenom] ${c}[nom] | adresse ${c}[rue], ${c}[appt], ${c}[ville], ${c}[etat], ${c}[code_postal]    console=True
    Log    Coordonnées de l'hôte : IBAN ${c}[iban] | SWIFT ${c}[swift] | banque ${c}[banque] | adresse banque ${c}[banque_rue], ${c}[banque_appt], ${c}[banque_ville], ${c}[banque_etat], ${c}[banque_code_postal]    console=True
    Set Test Variable    ${COORDONNEES_HOTE}    ${c}

Les coordonnées de paiement de l'hôte doivent être vides
    [Documentation]    TEST 08-9 - PRÉREQUIS BLOQUANT : l'hôte n'a pas initialisé ses informations de paiement. Si un seul champ est rempli, le test s'arrête (Fail)
    ...                car le scénario n'aurait plus de sens.
    [Arguments]    ${hote}
    ${remplis}=    Create List
    FOR    ${cle}    ${valeur}    IN    &{hote}
        ${valeur_nettoyee}=    Evaluate    $valeur.strip()
        IF    $valeur_nettoyee != ''
            Append To List    ${remplis}    ${cle}="${valeur_nettoyee}"
        END
    END
    ${nombre}=    Get Length    ${remplis}
    IF    ${nombre} > 0
        Capture Page Screenshot
        ${liste}=    Evaluate    ', '.join($remplis)
        Fail    Prérequis non rempli : la page Profil > Paiement de l'hôte devrait être vide mais contient ${liste} - test arrêté
    END
    Log    Prérequis OK : la page Profil > Paiement de l'hôte est entièrement vide (15 champs vides)    console=True
