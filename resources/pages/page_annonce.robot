*** Settings ***
Library    SeleniumLibrary
Library    DateTime
Library    String
Resource   ../variables.robot
Resource   ../recapitulatif.robot
Resource   page_reservation.robot
Resource   page_connexion.robot

*** Variables ***
${ANNONCE_BLOC_RESERVATION}         css=#homey_remove_on_mobile
${ANNONCE_CHAMP_ARRIVEE}            name=arrive
${ANNONCE_CHAMP_DEPART}             name=depart
${ANNONCE_CHAMP_VOYAGEURS}          name=guests
${ANNONCE_BOUTON_PLUS_ADULTE}       css=.sidebar-booking-module-body:nth-child(2) .adult_plus > .fa
${ANNONCE_CHAMP_MESSAGE}            css=#homey_remove_on_mobile textarea[name='guest_message']
${ANNONCE_BOUTON_APPLIQUER}         css=#homey_remove_on_mobile .apply_guests
${ANNONCE_BOUTON_DEMANDE}           id=request_for_reservation

*** Keywords ***
Naviguer vers l'annonce
    [Arguments]    ${url_annonce}
    Go To    ${url_annonce}
    ${titre}=    Get Title
    ${nom_annonce}=    Fetch From Left    ${titre}    ${SPACE}-${SPACE}
    Set Test Variable    ${NOM_ANNONCE}    ${nom_annonce}
    Set Test Variable    ${ANNONCE_CHOISIE}    ${titre} (${url_annonce})
    Log    Annonce choisie : ${ANNONCE_CHOISIE}    console=True

Sélectionner des dates réservables
    [Documentation]    Cherche la première arrivée réservable à partir de "aujourd'hui + décalage initial"
    ...                (décalage d'un jour à chaque fois si les dates sont déjà prises), pour un séjour de N jours.
    [Arguments]    ${decalage_initial}    ${duree_sejour}    ${decalage_maximum}
    ${aujourdhui}=    Get Current Date    result_format=%Y-%m-%d
    Wait Until Element Is Visible    ${ANNONCE_CHAMP_ARRIVEE}
    Click Element    ${ANNONCE_CHAMP_ARRIVEE}
    ${trouve}=    Set Variable    ${FALSE}
    FOR    ${decalage}    IN RANGE    ${decalage_initial}    ${decalage_maximum}
        ${arrivee}=    Add Time To Date    ${aujourdhui}    ${decalage} days    result_format=%Y-%m-%d
        ${reservable}=    Le séjour est réservable    ${arrivee}    ${duree_sejour}
        IF    ${reservable}
            ${depart}=    Add Time To Date    ${arrivee}    ${duree_sejour} days    result_format=%Y-%m-%d
            Click Element    ${ANNONCE_BLOC_RESERVATION} li.day-available[data-formatted-date='${arrivee}']
            Click Element    ${ANNONCE_CHAMP_DEPART}
            Click Element    ${ANNONCE_BLOC_RESERVATION} li.day-available[data-formatted-date='${depart}']
            Set Test Variable    ${SEJOUR_ARRIVEE}    ${arrivee}
            Set Test Variable    ${SEJOUR_DEPART}    ${depart}
            Log    Dates réservables choisies : du ${arrivee} au ${depart} (${duree_sejour} jours)    console=True
            ${trouve}=    Set Variable    ${TRUE}
            BREAK
        END
    END
    IF    not ${trouve}
        Capture Page Screenshot
        ${nb_occupes}=    Get Element Count    ${ANNONCE_BLOC_RESERVATION} li.homey-not-available-for-booking
        Fail    Contrôle de départ : aucune période libre de ${duree_sejour} jours dans le calendrier affiché (${nb_occupes} jour(s) déjà réservé(s) ou en attente). Des réservations de tests précédents sont probablement restées actives : les refuser ou les annuler dans la boîte Réservations de l'hôte, puis relancer.
    END

Le séjour est réservable
    [Documentation]    Vrai si l'arrivée, les jours intermédiaires et le départ sont tous disponibles et affichés
    [Arguments]    ${arrivee}    ${duree_sejour}
    ${total}=    Evaluate    ${duree_sejour} + 1
    FOR    ${i}    IN RANGE    ${total}
        ${jour}=    Add Time To Date    ${arrivee}    ${i} days    result_format=%Y-%m-%d
        ${disponible}=    Run Keyword And Return Status
        ...    Element Should Be Visible    ${ANNONCE_BLOC_RESERVATION} li.day-available[data-formatted-date='${jour}']
        IF    not ${disponible}
            RETURN    ${FALSE}
        END
    END
    RETURN    ${TRUE}

Sélectionner le nombre d'adultes
    [Arguments]    ${nombre}
    Click Element    ${ANNONCE_CHAMP_VOYAGEURS}
    FOR    ${i}    IN RANGE    ${nombre}
        Click Element    ${ANNONCE_BOUTON_PLUS_ADULTE}
    END
    Set Test Variable    ${NB_VOYAGEURS_ENVOYES}    ${nombre}
    Log    Nombre d'adultes : ${nombre}    console=True
    # Le bouton "Appliquer" referme le bloc voyageurs, qui sinon masque le bouton de demande de réservation
    Click Element    ${ANNONCE_BOUTON_APPLIQUER}
    Wait Until Element Is Not Visible    css=#homey_remove_on_mobile .search-guests-wrap

Renseigner le message à l'hôte
    [Documentation]    Anomalie détectée si le champ Message est absent. Dans ce cas on le trace et on poursuit le test.
    [Arguments]    ${message}
    ${present}=    Run Keyword And Return Status    Element Should Be Visible    ${ANNONCE_CHAMP_MESSAGE}
    IF    ${present}
        Input Text    ${ANNONCE_CHAMP_MESSAGE}    ${message}
        Log    Message à l'hôte renseigné    console=True
    ELSE
        Signaler une anomalie    Champ Message absent - anomalie détectée - poursuite du test
    END

Soumettre la demande de réservation
    ${heure_envoi}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Set Test Variable    ${HEURE_ENVOI}    ${heure_envoi}
    Log    Envoi de la demande de réservation à ${heure_envoi}    console=True
    Click Element    ${ANNONCE_BOUTON_DEMANDE}

Sélectionner à nouveau les mêmes dates
    [Documentation]    TEST 07-17 : redemande les dates qui viennent d'être réservées (même arrivée, même départ).
    [Arguments]    ${arrivee}    ${depart}
    Log    TEST 07-17 : nouvelle tentative sur des dates déjà réservées : du ${arrivee} au ${depart}    console=True
    Cliquer sur les dates du calendrier    ${arrivee}    ${depart}

Sélectionner des dates dont l'arrivée est aujourd'hui
    [Documentation]    TEST 07-6 et TEST 07-10 : arrivée = date du jour, départ = date du jour + durée du séjour (0 = même jour).
    [Arguments]    ${duree_sejour}
    ${aujourdhui}=    Get Current Date    result_format=%Y-%m-%d
    ${depart}=        Add Time To Date    ${aujourdhui}    ${duree_sejour} days    result_format=%Y-%m-%d
    Set Test Variable    ${SEJOUR_ARRIVEE}    ${aujourdhui}
    Set Test Variable    ${SEJOUR_DEPART}    ${depart}
    Log    TEST 07-6/07-10 : dates choisies : arrivée AUJOURD'HUI (${aujourdhui}), départ ${depart}    console=True
    Wait Until Element Is Visible    ${ANNONCE_CHAMP_ARRIVEE}
    # Contrôle de départ : ces dates sont imposées (aujourd'hui), on ne peut pas en choisir d'autres. Si elles sont déjà prises, on le dit clairement.
    Contrôler que le jour n'est pas déjà réservé    ${aujourdhui}    arrivée
    Contrôler que le jour n'est pas déjà réservé    ${depart}    départ
    Cliquer sur les dates du calendrier    ${aujourdhui}    ${depart}

Constater que la date passée ne peut pas être sélectionnée
    [Documentation]    TEST 07-7 et TEST 07-11 : le calendrier doit empêcher de choisir une date dans le passé.
    ...                Si la date n'est pas sélectionnable (jour grisé ou absent du calendrier affiché), le test est OK et s'arrête ici.
    ...                Sinon on poursuit le test et on tente la réservation : l'anomalie n'est remontée que si la demande est acceptée.
    [Arguments]    ${decalage_passe}
    ${aujourdhui}=    Get Current Date    result_format=%Y-%m-%d
    ${date_passee}=    Add Time To Date    ${aujourdhui}    ${decalage_passe} days    result_format=%Y-%m-%d
    Wait Until Element Is Visible    ${ANNONCE_CHAMP_ARRIVEE}
    Click Element    ${ANNONCE_CHAMP_ARRIVEE}
    ${selectionnable}=    Get Element Count    ${ANNONCE_BLOC_RESERVATION} li.day-available[data-formatted-date='${date_passee}']
    ${presente}=    Get Element Count    ${ANNONCE_BLOC_RESERVATION} li[data-formatted-date='${date_passee}']
    Log    Date passée testée : ${date_passee} (calendrier : ${presente} jour(s) affiché(s), ${selectionnable} sélectionnable(s))    console=True
    IF    ${selectionnable} == 0
        ${raison}=    Set Variable If    ${presente} > 0    le jour est grisé (non sélectionnable) dans le calendrier    le jour n'est pas affiché dans le calendrier (mois précédent)
        ${message}=    Set Variable    TEST OK : l'utilisateur n'a pas la possibilité de sélectionner une date dans le passé (${date_passee}) : ${raison}. Le système bloque cette possibilité.
        Log    ${message}    console=True
        Pass Execution    ${message}
    END
    # Date cliquable : ce n'est pas une anomalie en soi. On tente l'envoi de la demande ; l'anomalie n'est remontée que si elle est acceptée.
    Log    TEST 07-7/07-11 : la date passée ${date_passee} a pu être sélectionnée : on tente d'envoyer la demande pour savoir si le système l'accepte    console=True

Sélectionner une date passée et une date future disponible
    [Documentation]    TEST 07-7 (passé en arrivée) et TEST 07-11 (passé en départ). La date future est la première date disponible
    ...                à partir de "aujourd'hui + décalage initial" (on saute les dates déjà réservées).
    [Arguments]    ${decalage_passe}    ${decalage_futur_initial}    ${decalage_maximum}    ${passe_en_arrivee}
    ${aujourdhui}=    Get Current Date    result_format=%Y-%m-%d
    ${date_passee}=    Add Time To Date    ${aujourdhui}    ${decalage_passe} days    result_format=%Y-%m-%d
    Wait Until Element Is Visible    ${ANNONCE_CHAMP_ARRIVEE}
    Click Element    ${ANNONCE_CHAMP_ARRIVEE}
    ${date_future}=    Set Variable    ${EMPTY}
    FOR    ${decalage}    IN RANGE    ${decalage_futur_initial}    ${decalage_maximum}
        ${candidate}=    Add Time To Date    ${aujourdhui}    ${decalage} days    result_format=%Y-%m-%d
        ${disponible}=    Le séjour est réservable    ${candidate}    0
        IF    ${disponible}
            ${date_future}=    Set Variable    ${candidate}
            BREAK
        END
    END
    IF    '${date_future}' == ''
        Fail    Aucune date future disponible trouvée dans le calendrier affiché
    END
    ${arrivee}=    Set Variable If    ${passe_en_arrivee}    ${date_passee}    ${date_future}
    ${depart}=     Set Variable If    ${passe_en_arrivee}    ${date_future}    ${date_passee}
    Set Test Variable    ${SEJOUR_ARRIVEE}    ${arrivee}
    Set Test Variable    ${SEJOUR_DEPART}    ${depart}
    Log    TEST 07-7/07-11 : dates choisies : arrivée ${arrivee}, départ ${depart} (date passée : ${date_passee}, date future disponible : ${date_future})    console=True
    Cliquer sur les dates du calendrier    ${arrivee}    ${depart}

Sélectionner une arrivée future et un départ antérieur valide
    [Documentation]    TEST 07-12 : départ = première date future disponible (ni passé, ni aujourd'hui) à partir de "aujourd'hui + décalage initial",
    ...                arrivée = départ + écart. Les deux dates sont valides mais dans le mauvais sens (fin avant début).
    ...                Si le calendrier empêche cette sélection, le test est OK et s'arrête ici ; sinon on tente l'envoi : anomalie seulement si la demande est acceptée.
    [Arguments]    ${decalage_depart_initial}    ${ecart_jours}    ${decalage_maximum}
    ${aujourdhui}=    Get Current Date    result_format=%Y-%m-%d
    Wait Until Element Is Visible    ${ANNONCE_CHAMP_ARRIVEE}
    Click Element    ${ANNONCE_CHAMP_ARRIVEE}
    ${depart}=    Set Variable    ${EMPTY}
    ${arrivee}=    Set Variable    ${EMPTY}
    FOR    ${decalage}    IN RANGE    ${decalage_depart_initial}    ${decalage_maximum}
        ${candidat_depart}=    Add Time To Date    ${aujourdhui}    ${decalage} days    result_format=%Y-%m-%d
        ${candidat_arrivee}=    Add Time To Date    ${candidat_depart}    ${ecart_jours} days    result_format=%Y-%m-%d
        ${depart_ok}=    Le séjour est réservable    ${candidat_depart}    0
        ${arrivee_ok}=    Le séjour est réservable    ${candidat_arrivee}    0
        IF    ${depart_ok} and ${arrivee_ok}
            ${depart}=    Set Variable    ${candidat_depart}
            ${arrivee}=    Set Variable    ${candidat_arrivee}
            BREAK
        END
    END
    IF    '${depart}' == ''
        Fail    Aucun couple de dates futures disponibles (arrivée = départ + ${ecart_jours} jours) trouvé dans le calendrier affiché
    END
    Set Test Variable    ${SEJOUR_ARRIVEE}    ${arrivee}
    Set Test Variable    ${SEJOUR_DEPART}    ${depart}
    Log    TEST 07-12 : dates choisies : arrivée ${arrivee}, départ ${depart} (date de fin antérieure à la date de début)    console=True
    Cliquer sur les dates du calendrier    ${arrivee}    ${depart}
    ${arrivee_lue}=    Get Value    ${ANNONCE_CHAMP_ARRIVEE}
    ${depart_lu}=    Get Value    ${ANNONCE_CHAMP_DEPART}
    Log    TEST 07-12 : champs après sélection : arrivée "${arrivee_lue}", départ "${depart_lu}"    console=True
    IF    '${arrivee_lue}' != '${arrivee}' or '${depart_lu}' != '${depart}'
        ${message}=    Set Variable    TEST OK : l'utilisateur n'a pas la possibilité de choisir une date de fin (${depart}) antérieure à la date de début (${arrivee}) : le calendrier empêche cette sélection (champs : arrivée "${arrivee_lue}", départ "${depart_lu}").
        Log    ${message}    console=True
        Pass Execution    ${message}
    END
    # Dates cliquables : ce n'est pas une anomalie en soi. On tente l'envoi de la demande ; l'anomalie n'est remontée que si elle est acceptée.
    Log    TEST 07-12 : les dates inversées (arrivée ${arrivee}, départ ${depart}) ont pu être sélectionnées : on tente d'envoyer la demande pour savoir si le système l'accepte    console=True

Cliquer sur les dates du calendrier
    [Arguments]    ${arrivee}    ${depart}
    Click Element    ${ANNONCE_CHAMP_ARRIVEE}
    Cliquer sur un jour du calendrier    ${arrivee}    arrivée
    ${calendrier_ouvert}=    Run Keyword And Return Status    Element Should Be Visible    ${ANNONCE_BLOC_RESERVATION} li[data-formatted-date='${depart}']
    IF    not ${calendrier_ouvert}
        Click Element    ${ANNONCE_CHAMP_DEPART}
    END
    Cliquer sur un jour du calendrier    ${depart}    départ

Relever l'état d'un jour du calendrier
    [Documentation]    Retourne l'état du jour et ses classes CSS : ABSENT (non affiché), RESERVE (déjà réservé ou en attente), PASSE (jour passé),
    ...                DISPONIBLE, ou NON_DISPONIBLE (affiché mais ni libre ni réservé, ex. règle du site).
    [Arguments]    ${jour}
    ${jour_calendrier}=    Set Variable    ${ANNONCE_BLOC_RESERVATION} li[data-formatted-date='${jour}']
    ${nombre}=    Get Element Count    ${jour_calendrier}
    IF    ${nombre} == 0    RETURN    ABSENT    ${EMPTY}
    ${classes}=    Get Element Attribute    ${jour_calendrier}    class
    ${classes}=    Evaluate    ' '.join($classes.split())
    IF    'day-pending' in $classes or 'homey-not-available-for-booking' in $classes
        RETURN    RESERVE    ${classes}
    ELSE IF    'past-day' in $classes or 'day-disabled' in $classes
        RETURN    PASSE    ${classes}
    ELSE IF    'day-available' in $classes
        RETURN    DISPONIBLE    ${classes}
    END
    RETURN    NON_DISPONIBLE    ${classes}

Contrôler que le jour n'est pas déjà réservé
    [Documentation]    CONTRÔLE DE DÉPART (tests 6 et 10, dates imposées) : si le jour est déjà réservé, le test s'arrête avec un message explicite
    ...                (au lieu d'un obscur « element click intercepted »). Les autres états (jour grisé, non disponible) sont laissés au test, qui vérifie justement la réponse du site.
    [Arguments]    ${jour}    ${role}
    ${etat}    ${classes}=    Relever l'état d'un jour du calendrier    ${jour}
    Log    Contrôle de départ : jour ${jour} (${role}) : état ${etat} (classes : ${classes})    console=True
    IF    $etat == 'RESERVE'
        Capture Page Screenshot
        Fail    Contrôle de départ : le jour ${jour} (${role}) est déjà réservé ou en attente dans le calendrier (classes : ${classes}). Le test ne peut pas être joué sur des dates imposées : une réservation d'un test précédent est probablement restée active, à refuser ou annuler dans la boîte Réservations de l'hôte.
    END

Cliquer sur un jour du calendrier
    [Documentation]    Clique sur un jour en traçant son état ; si le clic est impossible, l'échec indique l'état et les classes du jour au lieu de l'erreur technique du navigateur.
    [Arguments]    ${jour}    ${role}
    ${etat}    ${classes}=    Relever l'état d'un jour du calendrier    ${jour}
    Log    Calendrier : jour ${jour} (${role}) : état ${etat} (classes : ${classes})    console=True
    IF    $etat == 'ABSENT'
        Capture Page Screenshot
        Fail    Le jour ${jour} (${role}) n'est pas affiché dans le calendrier de l'annonce : impossible de le sélectionner.
    END
    TRY
        Click Element    ${ANNONCE_BLOC_RESERVATION} li[data-formatted-date='${jour}']
    EXCEPT    AS    ${erreur}
        Capture Page Screenshot
        ${resume}=    Evaluate    ($erreur.strip().splitlines() or [''])[0]
        Fail    Clic impossible sur le jour ${jour} (${role}) du calendrier : état ${etat} (classes : ${classes}). Cause probable : jour réservé/indisponible ou calendrier recouvert par un autre élément. Erreur du navigateur : ${resume}
    END

Retenter la demande de réservation
    [Documentation]    Deuxième clic sur "Demande de réservation" (ne modifie pas l'heure d'envoi de la première demande).
    Log    TEST 07-17 : nouvelle tentative de demande de réservation sur les mêmes dates    console=True
    Click Element    ${ANNONCE_BOUTON_DEMANDE}

# ---------- Envoi d'une demande de réservation (étapes partagées par US07 et US08) ----------
Le voyageur se connecte et ouvre l'annonce
    [Arguments]    ${url_annonce}=${URL_ANNONCE_TEST}
    Se connecter en tant que voyageur    ${VOYAGEUR_EMAIL}    ${VOYAGEUR_PASSWORD}
    La connexion doit être confirmée
    Naviguer vers l'annonce    ${url_annonce}

Renseigner le nombre d'adultes et le message puis envoyer la demande
    [Documentation]    Fin commune de la saisie (voyageur connecté ou visiteur) : nombre d'adultes, message à l'hôte, clic sur "Demande de réservation".
    [Arguments]    ${nombre_adultes}=${NOMBRE_ADULTES}
    Sélectionner le nombre d'adultes    ${nombre_adultes}
    Renseigner le message à l'hôte    ${MESSAGE_A_L_HOTE}
    Soumettre la demande de réservation

Le voyageur envoie une demande de réservation sur des dates réservables
    [Documentation]    Connexion du voyageur, choix de la première période réservable, envoi de la demande et contrôle du message de confirmation.
    [Arguments]    ${url_annonce}=${URL_ANNONCE_TEST}    ${nombre_adultes}=${NOMBRE_ADULTES}
    Le voyageur se connecte et ouvre l'annonce    ${url_annonce}
    Sélectionner des dates réservables    ${DECALAGE_JOURS_INITIAL}    ${DUREE_SEJOUR_JOURS}    ${DECALAGE_JOURS_MAXIMUM}
    Renseigner le nombre d'adultes et le message puis envoyer la demande    ${nombre_adultes}
    La confirmation de réservation doit être affichée
