*** Settings ***
Library    SeleniumLibrary
Library    Collections
Resource   ../variables.robot
Resource   ../recapitulatif.robot

*** Variables ***
# Page "information de paiement" (paiement hors-site) affichée après "Payez maintenant"
${PAIEMENT_MESSAGE_HORS_SITE}       css=.local-payment-info
${PAIEMENT_BOUTON_RETOUR}           css=.block-title .block-right > a.btn-slim

*** Keywords ***
Relever une information de la page de paiement
    [Documentation]    Retourne la valeur affichée en face du libellé (ex. "Code IBAN"), sans le libellé et sur une seule ligne. Retourne ${None} si le libellé est absent.
    [Arguments]    ${libelle}
    ${ligne}=    Set Variable    xpath=(//div[contains(@class,'block-body')]//li[strong[normalize-space()='${libelle}']])[1]
    ${nombre}=    Get Element Count    ${ligne}
    IF    ${nombre} == 0
        RETURN    ${None}
    END
    ${texte}=    Get Text    ${ligne}
    ${valeur}=    Evaluate    ' '.join($texte.replace($libelle, '', 1).split())
    RETURN    ${valeur}

La page de paiement hors-site doit être affichée
    [Documentation]    US08 : message "paiement hors-site" et méthode "Virement bancaire". Un écart est une anomalie détectée (le test se poursuit).
    Wait Until Element Is Visible    ${PAIEMENT_MESSAGE_HORS_SITE}    timeout=20s
    Capture Page Screenshot
    ${message}=    Get Text    ${PAIEMENT_MESSAGE_HORS_SITE}
    ${message_lu}=    Evaluate    ' '.join($message.split())
    Log    US08 : message affiché sur la page de paiement : ${message_lu}    console=True
    IF    $message_lu == $MESSAGE_PAIEMENT_HORS_SITE
        Log    US08 : message de paiement hors-site conforme - OK    console=True
    ELSE
        Signaler une anomalie    Message de paiement hors-site incorrect : "${message_lu}" affiché au lieu de "${MESSAGE_PAIEMENT_HORS_SITE}" - anomalie détectée - poursuite du test
    END
    ${methode}=    Relever une information de la page de paiement    Méthode
    IF    $methode is None
        Signaler une anomalie    Information "Méthode" absente de la page de paiement - anomalie détectée - poursuite du test
    ELSE IF    $methode == $METHODE_PAIEMENT_ATTENDUE
        Log    US08 : méthode de paiement "${methode}" conforme - OK    console=True
    ELSE
        Signaler une anomalie    Méthode de paiement "${methode}" affichée au lieu de "${METHODE_PAIEMENT_ATTENDUE}" - anomalie détectée - poursuite du test
    END

Contrôler une information égale à celle de l'hôte
    [Documentation]    US08 : la valeur affichée au voyageur doit être identique à celle de la page Profil > Paiement de l'hôte.
    [Arguments]    ${libelle}    ${attendu}
    ${lu}=    Relever une information de la page de paiement    ${libelle}
    IF    $lu is None
        Signaler une anomalie    Information "${libelle}" absente de la page de paiement du voyageur - anomalie détectée - poursuite du test
    ELSE IF    $lu == $attendu
        Log    US08 : "${libelle}" : "${lu}" identique à la page de l'hôte - OK    console=True
    ELSE
        Signaler une anomalie    "${libelle}" affiché au voyageur : "${lu}" au lieu de "${attendu}" (page de l'hôte) - anomalie détectée - poursuite du test
    END

Contrôler une adresse comme celle de l'hôte
    [Documentation]    US08 : l'adresse affichée au voyageur doit contenir tous les éléments saisis par l'hôte (Appt, Adresse, Ville, Etat, Code postal).
    ...                Les éléments manquants sont listés dans l'anomalie.
    [Arguments]    ${libelle}    ${rue}    ${appt}    ${ville}    ${etat}    ${code_postal}
    ${lu}=    Relever une information de la page de paiement    ${libelle}
    IF    $lu is None
        Signaler une anomalie    Information "${libelle}" absente de la page de paiement du voyageur - anomalie détectée - poursuite du test
        RETURN
    END
    ${elements}=    Create Dictionary    Adresse=${rue}    Appt=${appt}    Ville=${ville}    Etat=${etat}    Code postal=${code_postal}
    ${manquants}=    Create List
    FOR    ${nom}    ${valeur}    IN    &{elements}
        IF    '${valeur}' != '' and $valeur not in $lu
            Append To List    ${manquants}    ${nom} (${valeur})
        END
    END
    Log    US08 : "${libelle}" affiché au voyageur : "${lu}" (page de l'hôte : ${rue}, ${appt}, ${ville}, ${etat}, ${code_postal})    console=True
    ${nombre}=    Get Length    ${manquants}
    IF    ${nombre} == 0
        Log    US08 : "${libelle}" complet par rapport à la page de l'hôte - OK    console=True
    ELSE
        ${liste}=    Evaluate    ', '.join($manquants)
        Signaler une anomalie    "${libelle}" incomplet côté voyageur : "${lu}" ne contient pas ${liste} (présents dans la page de l'hôte) - anomalie détectée - poursuite du test
    END

Les coordonnées de l'hôte doivent être affichées au voyageur
    [Documentation]    US08 : bénéficiaire, adresse, IBAN, SWIFT, nom et adresse de la banque = ce que l'hôte a saisi dans Profil > Paiement.
    [Arguments]    ${hote}
    Contrôler une information égale à celle de l'hôte    Nom du bénéficiaire    ${hote}[prenom] ${hote}[nom]
    Contrôler une adresse comme celle de l'hôte    Adresse    ${hote}[rue]    ${hote}[appt]    ${hote}[ville]    ${hote}[etat]    ${hote}[code_postal]
    Contrôler une information égale à celle de l'hôte    Code IBAN    ${hote}[iban]
    Contrôler une information égale à celle de l'hôte    SWIFT    ${hote}[swift]
    Contrôler une information égale à celle de l'hôte    Nom de banque    ${hote}[banque]
    Contrôler une adresse comme celle de l'hôte    Adresse de la banque    ${hote}[banque_rue]    ${hote}[banque_appt]    ${hote}[banque_ville]    ${hote}[banque_etat]    ${hote}[banque_code_postal]

Revenir au détail du voyage
    Log    US08 : clic sur le bouton "Retour" de la page de paiement    console=True
    Click Element    ${PAIEMENT_BOUTON_RETOUR}

Les coordonnées de paiement doivent être vides côté voyageur
    [Documentation]    TEST 08-9 : l'hôte n'a rien saisi dans Profil > Paiement, donc bénéficiaire, adresse, IBAN, SWIFT, nom et adresse de la banque
    ...                doivent être vides sur la page de paiement du voyageur. Un libellé absent compte comme vide ; une valeur affichée est une anomalie (le test se poursuit).
    FOR    ${libelle}    IN    Nom du bénéficiaire    Adresse    Code IBAN    SWIFT    Nom de banque    Adresse de la banque
        ${lu}=    Relever une information de la page de paiement    ${libelle}
        IF    $lu is None
            Log    US08 : "${libelle}" absent de la page de paiement (donc vide) - OK    console=True
        ELSE
            # Des séparateurs seuls (ex. ", , ,") ne sont pas une information
            ${vide}=    Evaluate    re.sub(r'[\s,;.\-]', '', $lu) == ''    modules=re
            IF    ${vide}
                Log    US08 : "${libelle}" vide côté voyageur - OK    console=True
            ELSE
                Signaler une anomalie    "${libelle}" affiché au voyageur : "${lu}" alors que l'hôte n'a renseigné aucune information de paiement (doit être vide) - anomalie détectée - poursuite du test
            END
        END
    END
