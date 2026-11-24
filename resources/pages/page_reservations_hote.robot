*** Settings ***
Library    SeleniumLibrary
Library    BuiltIn
Library    DateTime
Library    Collections
Resource   ../variables.robot
Resource   ../recapitulatif.robot
Resource   page_connexion.robot

*** Variables ***
${RESERVATIONS_MENU_GAUCHE}         css=.board-panel-menu a[href$='/index.php/reservations/']
${RESERVATIONS_TABLEAU}             css=.dashboard-reservation-table table
# Ligne du tableau (Réservations ou Voyages) retrouvée par son ID : {ID} est remplacé par l'ID dans les mots-clés ci-dessous
${LIGNE_TABLEAU_PAR_ID}             //tr[td[@data-label='ID'][normalize-space()='{ID}']]
${RESERVATIONS_BOUTON_REFUSER}      css=.dashboard-sidebar > #decline-reservation-btn
${RESERVATIONS_CHAMP_MOTIF}         xpath=//div[@id='decline-reservation']/div/form/div/textarea
${RESERVATIONS_BOUTON_VALIDER_REFUS}    id=decline
# Page de détails d'une réservation (côté hôte) : boutons de la colonne de droite
${RESERVATIONS_STATUT_DETAIL}           css=.block-head .title .label
${RESERVATIONS_ZONE_PAIEMENT}           css=.dashboard-sidebar .payment-list
${RESERVATIONS_ALERTE_SUCCES}           css=.dashboard-area .alert-success
${RESERVATIONS_BOUTON_ANNULER}          css=.dashboard-sidebar > #cancel-reservation-btn
${RESERVATIONS_CHAMP_MOTIF_ANNULATION}  id=reason
${RESERVATIONS_BOUTON_VALIDER_ANNULATION}    id=cancelled
${RESERVATIONS_NOMBRE_NUITS}            xpath=//ul[contains(@class,'detail-list-2-cols')]//li[contains(normalize-space(.),'nuit')]/strong
${RESERVATIONS_PREMIERE_LIGNE_PAIEMENT}    css=.dashboard-sidebar .payment-list li:first-child
${RESERVATIONS_LIGNE_IMPOTS}            xpath=(//aside[contains(@class,'dashboard-sidebar')]//div[@class='payment-list']//li[contains(normalize-space(.),'Impôts')])[1]
${RESERVATIONS_BOUTON_CONFIRMER}        css=.dashboard-sidebar > .confirm-offsite-reservation
${RESERVATIONS_BOUTON_FRAIS}            css=.dashboard-sidebar > button[data-target='#modal-extra-expenses']
${RESERVATIONS_BOUTON_REMISE}           css=.dashboard-sidebar > button[data-target='#modal-discount']
${RESERVATIONS_CHAMP_NOM_FRAIS}         css=#modal-extra-expenses .enter_expense_name
${RESERVATIONS_CHAMP_VALEUR_FRAIS}      css=#modal-extra-expenses .enter_expense_value
${RESERVATIONS_BOUTON_AJOUTER_FRAIS}    id=add_more_expense
${RESERVATIONS_BOUTON_ENREGISTRER_FRAIS}    id=save_expenses
${RESERVATIONS_CHAMP_NOM_REMISE}        css=#modal-discount .enter_discount_name
${RESERVATIONS_CHAMP_VALEUR_REMISE}     css=#modal-discount .enter_discount_value
${RESERVATIONS_BOUTON_AJOUTER_REMISE}   id=add_more_discount
${RESERVATIONS_BOUTON_ENREGISTRER_REMISE}    id=save_discounts

*** Keywords ***
Ouvrir la boîte Réservations
    Log    Hôte : ouverture de la boîte "Réservations"    console=True
    Click Element    ${RESERVATIONS_MENU_GAUCHE}
    Wait Until Element Is Visible    ${RESERVATIONS_TABLEAU}    timeout=20s

La demande envoyée doit être présente dans la boîte Réservations
    [Documentation]    Retrouve la ligne de la demande envoyée grâce à son ID (le même que l'ID du voyage côté voyageur), puis contrôle arrivée, départ, voyageurs, annonce, statut,
    ...                puis contrôle statut, date/heure de la demande, adresse. L'ID de la réservation est tracé.
    [Arguments]    ${id_attendu}    ${arrivee}    ${depart}    ${voyageurs}    ${nom_annonce}    ${adresse}    ${statut}    ${heure_envoi}    ${tolerance_minutes}
    ${critere}=    Set Variable    //div[contains(@class,'dashboard-reservation-table')]//tbody/tr[td[@data-label='ID'][normalize-space()='${id_attendu}'] and td[@data-label='Arrivée'][normalize-space()='${arrivee}'] and td[@data-label='Départ'][normalize-space()='${depart}'] and td[@data-label='Voyageurs'][normalize-space()='${voyageurs}'] and td[@data-label='Statut'][contains(normalize-space(),'${statut}')] and td[@data-label='Adresse'][contains(.,'${nom_annonce}')]]
    Log    Recherche côté hôte de la réservation ${id_attendu} : annonce ${nom_annonce}, arrivée ${arrivee}, départ ${depart}, ${voyageurs} voyageur(s), statut ${statut}    console=True
    ${nombre}=    Get Element Count    xpath=${critere}
    IF    ${nombre} == 0
        Capture Page Screenshot
        Fail    Réservation ${id_attendu} non trouvée côté hôte avec les mêmes données (arrivée ${arrivee}, départ ${depart}, ${voyageurs} voyageur(s), statut ${statut})
    END
    Log    ${nombre} ligne(s) correspondante(s) trouvée(s), la plus récente est contrôlée    console=True
    ${ligne}=    Set Variable    (${critere})[1]
    ${id}=       Get Text    xpath=${ligne}/td[@data-label='ID']
    Should Match Regexp    ${id}    ^#[0-9]+$
    Should Be Equal    ${id}    ${id_attendu}
    ${statut_lu}=    Get Text    xpath=${ligne}/td[@data-label='Statut']
    Should Contain    ${statut_lu}    ${statut}
    ${adresse_lue}=    Get Text    xpath=${ligne}/td[@data-label='Adresse']
    Should Contain    ${adresse_lue}    ${nom_annonce}
    Should Contain    ${adresse_lue}    ${adresse}
    ${date_lue}=    Get Text    xpath=${ligne}/td[@data-label='Date']
    ${match}    ${jour}    ${heure}=    Should Match Regexp    ${date_lue}    ([0-9]{4}-[0-9]{2}-[0-9]{2})\\s+([0-9]{1,2}:[0-9]{2})
    # Le site affiche l'heure sans zéro devant avant 10h (ex. 9:01) : on la complète (09:01)
    ${heure}=    Evaluate    '{:0>5}'.format($heure)
    ${date_demande}=    Set Variable    ${jour} ${heure}:00
    ${ecart}=    Subtract Date From Date    ${heure_envoi}    ${date_demande}
    # Le site affiche l'heure sur 12 h sans AM/PM (ex. 3:36 pour 15:36) : on compare modulo 12 h pour accepter les deux cas
    ${ecart_minutes}=    Evaluate    min(abs(${ecart}) % 43200, 43200 - abs(${ecart}) % 43200) / 60
    Log    Date/heure de la demande côté hôte : ${date_demande} (envoyée à ${heure_envoi}, écart ${ecart_minutes} min)    console=True
    Should Be True    ${ecart_minutes} <= ${tolerance_minutes}    Écart date/heure trop grand : ${ecart_minutes} min (maximum ${tolerance_minutes})
    Log    Réservation ${id} trouvée côté hôte : statut ${statut_lu}, ${adresse_lue}, du ${arrivee} au ${depart}, ${voyageurs} voyageur(s) - OK    console=True
    Set Test Message    Réservation ${id} reçue côté hôte (statut ${statut}, du ${arrivee} au ${depart}, ${voyageurs} voyageur(s)).    append=True

Refuser la réservation pour nettoyer les données de test
    [Documentation]    NETTOYAGE : l'hôte refuse la réservation créée par le test, ce qui libère les dates du calendrier.
    [Arguments]    ${id}    ${motif}
    Log    NETTOYAGE : l'hôte refuse la réservation ${id} créée par le test pour libérer les dates du calendrier    level=WARN    console=True
    Cliquer sur le lien Actions de la ligne    ${id}
    Wait Until Element Is Visible    ${RESERVATIONS_BOUTON_REFUSER}    timeout=20s
    Log    NETTOYAGE : détail de la réservation ${id} ouvert, clic sur "Refuser"    console=True
    Click Element    ${RESERVATIONS_BOUTON_REFUSER}
    Wait Until Element Is Visible    ${RESERVATIONS_CHAMP_MOTIF}    timeout=20s
    Input Text    ${RESERVATIONS_CHAMP_MOTIF}    ${motif}
    Log    NETTOYAGE : motif du refus saisi : ${motif}    console=True
    Click Element    ${RESERVATIONS_BOUTON_VALIDER_REFUS}
    Wait Until Element Is Not Visible    ${RESERVATIONS_CHAMP_MOTIF}    timeout=20s
    Log    NETTOYAGE : refus de la réservation ${id} envoyé    console=True

Le refus de la réservation doit être constaté
    [Documentation]    Contrôle non bloquant : le nettoyage ne doit pas faire échouer un test dont la vérification principale est réussie.
    [Arguments]    ${id}    ${statut_refus}
    ${menu_ok}=    Run Keyword And Return Status    Ouvrir la boîte Réservations
    IF    not ${menu_ok}
        Go To    ${BASE_URL}index.php/reservations/
        Wait Until Element Is Visible    ${RESERVATIONS_TABLEAU}    timeout=20s
    END
    ${statut_lu}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    IF    '${statut_refus}' in '''${statut_lu}'''
        Log    NETTOYAGE OK : la réservation ${id} a maintenant le statut ${statut_lu}, les dates sont libérées    console=True
        Set Test Message    Nettoyage OK : réservation ${id} refusée (statut ${statut_lu}).    append=True
    ELSE
        Signaler une anomalie    Nettoyage non confirmé - anomalie détectée : la réservation ${id} a le statut "${statut_lu}" au lieu de "${statut_refus}"
    END

Une seule réservation doit exister pour les dates demandées
    [Documentation]    TEST 07-17 : les réservations refusées (anciens essais) sont ignorées ; il doit rester exactement une réservation.
    [Arguments]    ${arrivee}    ${depart}    ${voyageurs}    ${nom_annonce}
    ${critere}=    Set Variable    //div[contains(@class,'dashboard-reservation-table')]//tbody/tr[td[@data-label='Arrivée'][normalize-space()='${arrivee}'] and td[@data-label='Départ'][normalize-space()='${depart}'] and td[@data-label='Voyageurs'][normalize-space()='${voyageurs}'] and td[@data-label='Adresse'][contains(.,'${nom_annonce}')] and not(contains(normalize-space(td[@data-label='Statut']),'REFUS')) and not(contains(normalize-space(td[@data-label='Statut']),'ANNUL'))]
    ${nombre}=    Get Element Count    xpath=${critere}
    Log    TEST 07-17 : ${nombre} réservation(s) non refusée(s) côté hôte pour les dates du ${arrivee} au ${depart}    console=True
    Should Be Equal As Integers    ${nombre}    1    Il devrait y avoir 1 seule réservation pour ces dates, il y en a ${nombre}

Revenir à la liste des réservations
    [Documentation]    Depuis une page de détails : retour au tableau des réservations (menu de gauche, sinon adresse directe).
    ${menu_ok}=    Run Keyword And Return Status    Ouvrir la boîte Réservations
    IF    not ${menu_ok}
        Go To    ${BASE_URL}index.php/reservations/
        Wait Until Element Is Visible    ${RESERVATIONS_TABLEAU}    timeout=20s
    END

Ouvrir la page de détails de paiement de la réservation
    [Documentation]    US08 : l'hôte ouvre le détail de la réservation depuis le tableau (lien de la colonne Actions) et vérifie
    ...                les informations de paiement : nombre de nuits, prix par nuit, taux d'imposition.
    [Arguments]    ${id}    ${nuits_attendues}
    Log    US08 : l'hôte ouvre la page de détails de paiement de la réservation ${id}    console=True
    Cliquer sur le lien Actions de la ligne    ${id}
    Wait Until Element Is Visible    ${RESERVATIONS_ZONE_PAIEMENT}    timeout=20s
    ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    Log    US08 : page de détails de la réservation ${id} ouverte (statut affiché : ${statut})    console=True
    Capture Page Screenshot
    ${nuits}=    Get Text    ${RESERVATIONS_NOMBRE_NUITS}
    ${prix}=     Get Text    ${RESERVATIONS_PREMIERE_LIGNE_PAIEMENT}
    ${impots}=   Get Text    ${RESERVATIONS_LIGNE_IMPOTS}
    # Le site coupe ces textes sur plusieurs lignes : on les remet sur une seule ligne pour des logs lisibles
    ${nuits}=    Evaluate    ' '.join($nuits.split())
    ${prix}=    Evaluate    ' '.join($prix.split())
    ${impots}=    Evaluate    ' '.join($impots.split())
    Log    US08 : nombre de nuits : ${nuits} | prix par nuit : ${prix} | taux d'imposition : ${impots}    console=True
    IF    '${nuits}' != '${nuits_attendues}'
        Signaler une anomalie    Nombre de nuits affiché ${nuits} au lieu de ${nuits_attendues} - anomalie détectée - poursuite du test
    END
    ${prix_ok}=    Run Keyword And Return Status    Should Match Regexp    ${prix}    [0-9.,]+€\\s*x\\s*[0-9]+\\s*nuit
    IF    not ${prix_ok}
        Signaler une anomalie    Prix par nuit non lisible sur la ligne "${prix}" - anomalie détectée - poursuite du test
    END
    ${impots_ok}=    Run Keyword And Return Status    Should Match Regexp    ${impots}    Impôts\\s+[0-9.,]+%
    IF    not ${impots_ok}
        Signaler une anomalie    Taux d'imposition non lisible sur la ligne "${impots}" - anomalie détectée - poursuite du test
    END

Les actions de confirmation doivent être disponibles
    [Documentation]    US08 : sur la page de détails, l'hôte doit retrouver les 3 actions : confirmer la disponibilité, ajouter des frais supplémentaires, faire une remise.
    ${confirmer}=    Run Keyword And Return Status    Element Should Be Visible    ${RESERVATIONS_BOUTON_CONFIRMER}
    ${frais}=        Run Keyword And Return Status    Element Should Be Visible    ${RESERVATIONS_BOUTON_FRAIS}
    ${remise}=       Run Keyword And Return Status    Element Should Be Visible    ${RESERVATIONS_BOUTON_REMISE}
    Log    US08 : action "Confirmer la disponibilité" disponible : ${confirmer}    console=True
    Log    US08 : action "Ajouter des frais supplémentaires" disponible : ${frais}    console=True
    Log    US08 : action "Faire une remise" disponible : ${remise}    console=True
    IF    not ${confirmer}
        Capture Page Screenshot
        Fail    Action "Confirmer la disponibilité" absente de la page de détails
    END
    IF    not ${frais}
        Signaler une anomalie    Action "Ajouter des frais supplémentaires" absente - anomalie détectée - poursuite du test
    END
    IF    not ${remise}
        Signaler une anomalie    Action "Faire une remise" absente - anomalie détectée - poursuite du test
    END

Confirmer la réservation avec un frais supplémentaire et une remise
    [Documentation]    US08 : l'hôte ajoute un frais supplémentaire et une remise, puis confirme la disponibilité.
    [Arguments]    ${id}    ${nom_frais}    ${valeur_frais}    ${nom_remise}    ${valeur_remise}
    Log    US08 : l'hôte ajoute le frais supplémentaire "${nom_frais}" de ${valeur_frais}    console=True
    Remplir et enregistrer une fenêtre de saisie    ${RESERVATIONS_BOUTON_FRAIS}    ${RESERVATIONS_CHAMP_NOM_FRAIS}    ${RESERVATIONS_CHAMP_VALEUR_FRAIS}    ${RESERVATIONS_BOUTON_AJOUTER_FRAIS}    ${RESERVATIONS_BOUTON_ENREGISTRER_FRAIS}    ${nom_frais}    ${valeur_frais}
    Log    US08 : frais supplémentaire enregistré    console=True
    Log    US08 : l'hôte ajoute la remise "${nom_remise}" de ${valeur_remise}    console=True
    Remplir et enregistrer une fenêtre de saisie    ${RESERVATIONS_BOUTON_REMISE}    ${RESERVATIONS_CHAMP_NOM_REMISE}    ${RESERVATIONS_CHAMP_VALEUR_REMISE}    ${RESERVATIONS_BOUTON_AJOUTER_REMISE}    ${RESERVATIONS_BOUTON_ENREGISTRER_REMISE}    ${nom_remise}    ${valeur_remise}
    Log    US08 : remise enregistrée    console=True
    Capture Page Screenshot
    Log    US08 : l'hôte confirme la disponibilité de la réservation ${id}    console=True
    Click Element    ${RESERVATIONS_BOUTON_CONFIRMER}
    # Le site ne met pas la page à jour tout seul : il faut la rafraîchir pour voir le nouveau statut (on réessaie jusqu'à 30 s)
    ${change}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    30s    3s    Rafraîchir la page jusqu'à ce que le statut ne soit plus NOUVEAU
    ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    Log    US08 : après rafraîchissement, statut affiché sur la page de détails : "${statut}" (modifié : ${change})    console=True
    ${alerte_ok}=    Run Keyword And Return Status    Element Should Be Visible    ${RESERVATIONS_ALERTE_SUCCES}
    IF    ${alerte_ok}
        ${message}=    Get Text    ${RESERVATIONS_ALERTE_SUCCES}
        Log    US08 : message du site : ${message}    console=True
    ELSE
        Log    US08 : aucun message de succès affiché après la confirmation    console=True
    END
    Capture Page Screenshot
    Set Test Message    Réservation ${id} confirmée par l'hôte (frais "${nom_frais}" ${valeur_frais}, remise "${nom_remise}" ${valeur_remise}).    append=True

Remplir et enregistrer une fenêtre de saisie
    [Documentation]    Ouvre la fenêtre (frais supplémentaires ou remise), saisit le nom et la valeur, puis enregistre.
    ...                La fenêtre met un instant à s'afficher (animation) : tant que le champ n'est pas utilisable, on réessaie (15 s maximum).
    [Arguments]    ${bouton_ouvrir}    ${champ_nom}    ${champ_valeur}    ${bouton_ajouter}    ${bouton_enregistrer}    ${nom}    ${valeur}
    # On attend que la fenêtre précédente soit complètement refermée (fond grisé disparu)
    Run Keyword And Ignore Error    Wait Until Page Does Not Contain Element    css=.modal-backdrop    timeout=10s
    Wait Until Keyword Succeeds    15s    1s    Ouvrir la fenêtre et saisir    ${bouton_ouvrir}    ${champ_nom}    ${champ_valeur}    ${nom}    ${valeur}
    Click Element    ${bouton_ajouter}
    Click Element    ${bouton_enregistrer}
    Wait Until Element Is Not Visible    ${champ_nom}    timeout=20s

Ouvrir la fenêtre et saisir
    [Arguments]    ${bouton_ouvrir}    ${champ_nom}    ${champ_valeur}    ${nom}    ${valeur}
    # Clic normal ; si le navigateur ne peut pas atteindre le bouton (ex. MoveTargetOutOfBounds après l'enregistrement précédent), clic par JavaScript
    ${clic_ok}=    Run Keyword And Return Status    Click Element    ${bouton_ouvrir}
    IF    not ${clic_ok}
        Log    US08 : clic normal impossible sur le bouton ${bouton_ouvrir}, clic par JavaScript    console=True
        ${bouton}=    Get WebElement    ${bouton_ouvrir}
        Execute Javascript    arguments[0].scrollIntoView({block: 'center'}); arguments[0].click();    ARGUMENTS    ${bouton}
    END
    Wait Until Element Is Visible    ${champ_nom}    timeout=10s
    # Plus de pause fixe : on clique dans le champ dès que l'animation de la fenêtre est terminée (le clic échoue tant qu'il n'est pas utilisable)
    Wait Until Keyword Succeeds    5s    200ms    Click Element    ${champ_nom}
    # Chaque saisie est relue : si le champ est resté vide (saisie non prise en compte), on recommence (sinon le site affiche l'alerte « Les deux champs sont obligatoires »)
    Wait Until Keyword Succeeds    10s    500ms    Saisir et vérifier la valeur d'un champ    ${champ_nom}    ${nom}
    Wait Until Keyword Succeeds    10s    500ms    Saisir et vérifier la valeur d'un champ    ${champ_valeur}    ${valeur}

Saisir et vérifier la valeur d'un champ
    [Documentation]    Saisit une valeur puis relit le champ ; échoue si la valeur lue est différente (ce qui déclenche une nouvelle tentative).
    [Arguments]    ${champ}    ${valeur}
    Click Element    ${champ}
    Input Text    ${champ}    ${valeur}
    ${lue}=    Get Value    ${champ}
    Should Be Equal As Strings    ${lue}    ${valeur}    Saisie non prise en compte dans le champ ${champ} : "${lue}" au lieu de "${valeur}"

Rafraîchir la page jusqu'à ce que le statut ne soit plus NOUVEAU
    Reload Page
    Wait Until Element Is Visible    ${RESERVATIONS_STATUT_DETAIL}    timeout=15s
    ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    Should Not Contain    ${statut}    ${STATUT_RESERVATION_ATTENDU}

Le statut de la réservation confirmée doit être
    [Documentation]    US08 : statut attendu côté hôte après confirmation (ATTENTE DE PAIEMENT). Un libellé différent (ex. PAIEMENT EN ATTENTE)
    ...                est une anomalie détectée et le test se poursuit ; un statut resté NOUVEAU (ou refusé) fait échouer le test.
    [Arguments]    ${id}    ${statut_attendu}    ${statut_initial}    ${statut_refus}
    Revenir à la liste des réservations
    ${statut_lu}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    Log    US08 : statut de la réservation ${id} côté hôte après confirmation : "${statut_lu}" (attendu : "${statut_attendu}")    console=True
    ${conforme}=    Evaluate    $statut_attendu in $statut_lu
    ${non_confirme}=    Evaluate    $statut_initial in $statut_lu or $statut_refus in $statut_lu or $statut_lu.strip() == ''
    IF    ${conforme}
        Log    US08 : statut ${statut_lu} conforme côté hôte    console=True
        Set Test Message    Statut hôte : ${statut_lu}.    append=True
    ELSE IF    ${non_confirme}
        Capture Page Screenshot
        Fail    La réservation ${id} n'a pas été confirmée : statut côté hôte "${statut_lu}" au lieu de "${statut_attendu}"
    ELSE
        Signaler une anomalie    Libellé du statut incorrect côté hôte - anomalie détectée - poursuite du test : "${statut_lu}" affiché au lieu de "${statut_attendu}"
    END

Les frais supplémentaires et la remise doivent être pris en compte côté hôte
    [Documentation]    US08 : le détail de la réservation confirmée contient le frais supplémentaire et la remise ; le total du détail et du tableau sont cohérents.
    [Arguments]    ${id}    ${nuits_attendues}    ${nom_frais}    ${valeur_frais}    ${nom_remise}    ${valeur_remise}
    Ouvrir la page de détails de paiement de la réservation    ${id}    ${nuits_attendues}
    ${total}=    Contrôler le frais et la remise dans le détail de paiement    côté hôte    ${nom_frais}    ${valeur_frais}    ${nom_remise}    ${valeur_remise}
    Revenir à la liste des réservations
    Le total du tableau doit correspondre au total du détail    côté hôte    ${id}    ${total}

Le statut de la réservation dans le tableau doit être
    [Documentation]    US08 : contrôle strict du statut de la ligne (ex. RÉSERVÉ) dans le tableau des réservations de l'hôte.
    [Arguments]    ${id}    ${statut_attendu}
    ${statut_lu}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    Log    US08 : statut de la réservation ${id} dans le tableau de l'hôte : "${statut_lu}" (attendu : "${statut_attendu}")    console=True
    ${conforme}=    Evaluate    $statut_attendu in $statut_lu
    IF    not ${conforme}
        Capture Page Screenshot
        Fail    La réservation ${id} a le statut "${statut_lu}" dans le tableau de l'hôte au lieu de "${statut_attendu}"
    END
    Set Test Message    Statut hôte (tableau) : ${statut_lu}.    append=True

Ouvrir le détail de la réservation
    [Arguments]    ${id}
    Log    US08 : l'hôte ouvre le détail de la réservation ${id}    console=True
    Cliquer sur le lien Actions de la ligne    ${id}
    Wait Until Element Is Visible    ${RESERVATIONS_STATUT_DETAIL}    timeout=20s
    Capture Page Screenshot

Le statut du détail de la réservation doit être
    [Documentation]    US08 : statut affiché dans le titre de la page de détails. Un écart est une anomalie détectée (le tableau a déjà été contrôlé).
    [Arguments]    ${id}    ${statut_attendu}
    ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    IF    $statut_attendu in $statut
        Log    US08 : détail de la réservation ${id} au statut ${statut} - OK    console=True
    ELSE
        Signaler une anomalie    Détail de la réservation ${id} : statut "${statut}" au lieu de "${statut_attendu}" - anomalie détectée - poursuite du test
    END

Annuler la réservation pour nettoyer les données de test
    [Documentation]    NETTOYAGE (tests 9 et 12) : depuis le détail d'une réservation RÉSERVÉ, l'hôte clique sur "Annuler", saisit un motif et clique sur "Soumettre".
    [Arguments]    ${id}    ${motif}    ${statut_annule}
    Log    NETTOYAGE : l'hôte annule la réservation ${id} créée par le test pour libérer les dates du calendrier    level=WARN    console=True
    Click Element    ${RESERVATIONS_BOUTON_ANNULER}
    Wait Until Element Is Visible    ${RESERVATIONS_CHAMP_MOTIF_ANNULATION}    timeout=20s
    Input Text    ${RESERVATIONS_CHAMP_MOTIF_ANNULATION}    ${motif}
    Log    NETTOYAGE : motif d'annulation saisi : ${motif}    console=True
    Click Element    ${RESERVATIONS_BOUTON_VALIDER_ANNULATION}
    Log    NETTOYAGE : annulation de la réservation ${id} envoyée    console=True
    # Le site peut mettre à jour la page tout seul (attente ciblée de 5 s max) ; sinon on la rafraîchit (jusqu'à 30 s)
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    ${RESERVATIONS_CHAMP_MOTIF_ANNULATION}    timeout=10s
    Run Keyword And Ignore Error    Wait Until Element Contains    ${RESERVATIONS_STATUT_DETAIL}    ${statut_annule}    timeout=5s
    ${ok}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    30s    3s    Rafraîchir le détail de la réservation jusqu'au statut    ${statut_annule}
    ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    Capture Page Screenshot
    IF    ${ok}
        Log    NETTOYAGE OK : le détail de la réservation ${id} est au statut ${statut}    console=True
    ELSE
        Signaler une anomalie    Nettoyage non confirmé - anomalie détectée : le détail de la réservation ${id} affiche "${statut}" au lieu de "${statut_annule}"
    END

Rafraîchir le détail de la réservation jusqu'au statut
    [Arguments]    ${statut_attendu}
    ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    ${ok}=    Evaluate    $statut_attendu in $statut
    IF    not ${ok}
        Reload Page
        Wait Until Element Is Visible    ${RESERVATIONS_STATUT_DETAIL}    timeout=15s
        ${statut}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
        Should Contain    ${statut}    ${statut_attendu}
    END

L'annulation de la réservation doit être constatée dans le tableau
    [Documentation]    NETTOYAGE (tests 9 et 12) : contrôle non bloquant du statut ANNULÉ dans le tableau des réservations.
    [Arguments]    ${id}    ${statut_annule}
    Revenir à la liste des réservations
    ${statut_lu}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    IF    $statut_annule in $statut_lu
        Log    NETTOYAGE OK : la réservation ${id} a le statut ${statut_lu} dans le tableau, les dates sont libérées    console=True
        Set Test Message    Nettoyage OK : réservation ${id} annulée (statut ${statut_lu}).    append=True
    ELSE
        Signaler une anomalie    Nettoyage non confirmé - anomalie détectée : la réservation ${id} a le statut "${statut_lu}" dans le tableau au lieu de "${statut_annule}"
    END

# ---------- TEST 08-9 : la réservation ne doit pas être passée à RÉSERVÉ ----------
Le statut de la réservation non payée doit être conservé
    [Documentation]    TEST 08-9 : dans le tableau de l'hôte puis dans le détail, la réservation doit rester "ATTENTE DE PAIEMENT" et non RÉSERVÉ.
    ...                RÉSERVÉ = anomalie (paiement accepté à tort) ; autre libellé que celui attendu = anomalie. Le test se poursuit. On reste ensuite sur la page de détails.
    [Arguments]    ${id}    ${statut_attendu}    ${statut_reserve}
    ${statut_tableau}=    Relever le statut d'une réservation dans le tableau    ${id}
    Contrôler le statut d'une réservation non payée    le tableau de l'hôte    ${id}    ${statut_tableau}    ${statut_attendu}    ${statut_reserve}
    Ouvrir le détail de la réservation    ${id}
    ${statut_detail}=    Get Text    ${RESERVATIONS_STATUT_DETAIL}
    Contrôler le statut d'une réservation non payée    la page de détails de la réservation    ${id}    ${statut_detail}    ${statut_attendu}    ${statut_reserve}

Contrôler le statut d'une réservation non payée
    [Arguments]    ${lieu}    ${id}    ${statut_lu}    ${statut_attendu}    ${statut_reserve}
    Log    US08 : statut de la réservation ${id} dans ${lieu} : "${statut_lu}" (attendu : "${statut_attendu}", interdit : "${statut_reserve}")    console=True
    IF    $statut_reserve in $statut_lu
        Signaler une anomalie    Réservation ${id} au statut "${statut_lu}" dans ${lieu} alors que le paiement aurait dû être bloqué - anomalie détectée - poursuite du test
    ELSE IF    $statut_attendu in $statut_lu
        Log    US08 : statut ${statut_lu} conforme dans ${lieu} - OK    console=True
    ELSE
        Signaler une anomalie    Libellé du statut incorrect dans ${lieu} - anomalie détectée - poursuite du test : "${statut_lu}" affiché au lieu de "${statut_attendu}"
    END

# ---------- Nettoyage de sécurité (utilisé par le Teardown des tests US08) ----------
Relever le statut d'une réservation dans le tableau
    [Documentation]    Retourne le statut de la ligne de la réservation dans le tableau de l'hôte, ou une chaîne vide si la réservation n'y figure pas.
    [Arguments]    ${id}
    ${nombre}=    Compter les lignes du tableau pour l'ID    ${id}
    IF    ${nombre} == 0    RETURN    ${EMPTY}
    ${statut}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    RETURN    ${statut}

Nettoyer la réservation de test selon son statut
    [Documentation]    NETTOYAGE DE SÉCURITÉ : l'hôte étant connecté, on lit le statut de la réservation puis :
    ...                déjà REFUSÉ ou ANNULÉ → rien à faire ; RÉSERVÉ → annulation ; autre statut (NOUVEAU, PAIEMENT EN ATTENTE...) → refus.
    [Arguments]    ${id}    ${motif_refus}    ${motif_annulation}    ${statut_refus}    ${statut_annule}    ${statut_reserve}
    Revenir à la liste des réservations
    ${statut}=    Relever le statut d'une réservation dans le tableau    ${id}
    Log    NETTOYAGE DE SÉCURITÉ : statut actuel de la réservation ${id} : "${statut}"    level=WARN    console=True
    IF    $statut == ''
        Signaler une anomalie    Nettoyage de sécurité impossible - anomalie détectée : la réservation ${id} est introuvable dans le tableau de l'hôte
    ELSE IF    $statut_refus in $statut or $statut_annule in $statut
        Log    NETTOYAGE DE SÉCURITÉ : la réservation ${id} est déjà ${statut}, rien à faire    console=True
    ELSE IF    $statut_reserve in $statut
        Ouvrir le détail de la réservation    ${id}
        Annuler la réservation pour nettoyer les données de test    ${id}    ${motif_annulation}    ${statut_annule}
        L'annulation de la réservation doit être constatée dans le tableau    ${id}    ${statut_annule}
    ELSE
        Refuser la réservation pour nettoyer les données de test    ${id}    ${motif_refus}
        Le refus de la réservation doit être constaté    ${id}    ${statut_refus}
    END

Nettoyer les réservations de test retrouvées par leurs dates
    [Documentation]    NETTOYAGE DE SÉCURITÉ quand l'ID de la réservation n'est pas connu (le test a échoué juste après l'envoi de la demande) :
    ...                on cherche dans le tableau de l'hôte les réservations NOUVEAU de l'annonce, avec les mêmes dates, envoyées AUJOURD'HUI, et on les refuse.
    [Arguments]    ${arrivee}    ${depart}    ${nom_annonce}    ${statut_nouveau}    ${motif_refus}    ${statut_refus}
    ${aujourdhui}=    Get Current Date    result_format=%Y-%m-%d
    ${critere}=    Set Variable    //div[contains(@class,'dashboard-reservation-table')]//tbody/tr[td[@data-label='Arrivée'][normalize-space()='${arrivee}'] and td[@data-label='Départ'][normalize-space()='${depart}'] and td[@data-label='Adresse'][contains(.,'${nom_annonce}')] and contains(normalize-space(td[@data-label='Statut']),'${statut_nouveau}') and contains(td[@data-label='Date'],'${aujourdhui}')]/td[@data-label='ID']
    ${cellules}=    Get WebElements    xpath=${critere}
    ${ids}=    Create List
    FOR    ${cellule}    IN    @{cellules}
        ${texte}=    Get Text    ${cellule}
        Append To List    ${ids}    ${texte}
    END
    ${nombre}=    Get Length    ${ids}
    Log    NETTOYAGE DE SÉCURITÉ : ${nombre} réservation(s) ${statut_nouveau} envoyée(s) aujourd'hui pour ${nom_annonce} du ${arrivee} au ${depart} : ${ids}    level=WARN    console=True
    FOR    ${id}    IN    @{ids}
        Refuser la réservation pour nettoyer les données de test    ${id}    ${motif_refus}
        Le refus de la réservation doit être constaté    ${id}    ${statut_refus}
    END

# ---------- Étapes partagées par US07 et US08, nettoyage de sécurité (Teardown) et bloc Paiement partagé avec la page Voyages ----------
La réservation doit être présente côté hôte avec les données envoyées
    [Documentation]    L'hôte est sur sa page Réservations : même ID, mêmes dates, même nombre de voyageurs, statut NOUVEAU, date/heure de la demande.
    [Arguments]    ${adresse_annonce}=${ADRESSE_ANNONCE_ATTENDUE}
    La demande envoyée doit être présente dans la boîte Réservations    ${ID_VOYAGE}    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${NB_VOYAGEURS_ENVOYES}    ${NOM_ANNONCE}    ${adresse_annonce}    ${STATUT_RESERVATION_ATTENDU}    ${HEURE_ENVOI}    ${TOLERANCE_HEURE_MINUTES}

L'hôte retrouve la nouvelle réservation au statut NOUVEAU
    [Documentation]    Étapes communes : l'utilisateur se déconnecte, l'hôte se connecte et retrouve la réservation au statut NOUVEAU dans sa boîte Réservations
    ...                (mêmes dates, même nombre de voyageurs, date/heure de la demande).
    [Arguments]    ${hote_email}=${HOTE_EMAIL}    ${hote_mot_de_passe}=${HOTE_PASSWORD}    ${adresse_annonce}=${ADRESSE_ANNONCE_ATTENDUE}
    L'utilisateur se déconnecte puis l'hôte se connecte    ${hote_email}    ${hote_mot_de_passe}
    Ouvrir la boîte Réservations
    La réservation doit être présente côté hôte avec les données envoyées    ${adresse_annonce}

Nettoyer la réservation de test par un refus
    [Documentation]    NETTOYAGE : l'hôte, sur sa page Réservations, refuse la réservation de test (${ID_VOYAGE}) pour libérer les dates, puis on constate le statut REFUSÉ.
    Refuser la réservation pour nettoyer les données de test    ${ID_VOYAGE}    ${MOTIF_REFUS}
    Le refus de la réservation doit être constaté    ${ID_VOYAGE}    ${STATUT_REFUS_ATTENDU}

Terminer le test avec nettoyage de sécurité
    [Documentation]    Teardown : si le test a échoué après l'envoi de la demande, l'hôte refuse la réservation (ou l'annule si elle est RÉSERVÉ) pour libérer les dates ;
    ...                puis enregistrement du résultat et fermeture du navigateur.
    ...                La capture d'écran de l'échec est prise AVANT le nettoyage, pour garder la page où le test s'est arrêté.
    Run Keyword If Test Failed    Run Keyword And Ignore Error    Capture Page Screenshot
    TRY
        Nettoyer la réservation créée par un test en échec
    FINALLY
        Fermer l'application et enregistrer le résultat
    END

Nettoyer la réservation créée par un test en échec
    [Documentation]    Ne fait rien si le test a réussi. ID connu : statut lu puis refus/annulation. ID inconnu : recherche par dates (réservations NOUVEAU envoyées aujourd'hui).
    IF    '${TEST STATUS}' != 'FAIL'    RETURN
    IF    $ID_VOYAGE == '' and $HEURE_ENVOI == ''
        Log    NETTOYAGE DE SÉCURITÉ : le test a échoué avant l'envoi d'une demande de réservation, rien à nettoyer    level=WARN    console=True
        RETURN
    END
    Log    NETTOYAGE DE SÉCURITÉ : le test a échoué, vérification des réservations créées par le test (ID connu : "${ID_VOYAGE}")    level=WARN    console=True
    # Dans un Teardown, Robot poursuit les étapes même après un échec : chaque étape est donc gardée, et on s'arrête à la première qui échoue
    ${hote_connecte}=    Run Keyword And Return Status    Se connecter en tant qu'hôte du test
    IF    not ${hote_connecte}
        Capture Page Screenshot
        Signaler une anomalie    Nettoyage de sécurité impossible - anomalie détectée : connexion de l'hôte refusée. Réservation à refuser/annuler à la main (ID "${ID_VOYAGE}", dates ${SEJOUR_ARRIVEE} au ${SEJOUR_DEPART}, annonce ${NOM_ANNONCE})
        RETURN
    END
    ${liste_ouverte}=    Run Keyword And Return Status    Ouvrir la boîte Réservations
    IF    not ${liste_ouverte}
        Capture Page Screenshot
        Signaler une anomalie    Nettoyage de sécurité impossible - anomalie détectée : boîte Réservations de l'hôte inaccessible. Réservation à refuser/annuler à la main (ID "${ID_VOYAGE}", dates ${SEJOUR_ARRIVEE} au ${SEJOUR_DEPART}, annonce ${NOM_ANNONCE})
        RETURN
    END
    TRY
        IF    $ID_VOYAGE != ''
            Nettoyer la réservation de test selon son statut    ${ID_VOYAGE}    ${MOTIF_REFUS}    ${MOTIF_ANNULATION}    ${STATUT_REFUS_ATTENDU}    ${STATUT_ANNULE_ATTENDU}    ${STATUT_RESERVE_ATTENDU}
        ELSE IF    $SEJOUR_ARRIVEE != '' and $SEJOUR_DEPART != ''
            Nettoyer les réservations de test retrouvées par leurs dates    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${NOM_ANNONCE}    ${STATUT_RESERVATION_ATTENDU}    ${MOTIF_REFUS}    ${STATUT_REFUS_ATTENDU}
        END
    EXCEPT    AS    ${erreur}
        ${resume}=    Evaluate    ($erreur.strip().splitlines() or [''])[0]
        Signaler une anomalie    Nettoyage de sécurité impossible - anomalie détectée : une réservation de test est peut-être encore active (ID "${ID_VOYAGE}", dates ${SEJOUR_ARRIVEE} au ${SEJOUR_DEPART}), à supprimer à la main (${resume})
    END

Se connecter en tant qu'hôte du test
    [Documentation]    Déconnecte proprement le compte courant (comme dans les tests), puis connecte l'hôte propriétaire de l'annonce du test
    ...                (jtahote2 pour le TEST 08-9 d'US08, sinon l'hôte par défaut). Si la déconnexion normale est impossible, on supprime les cookies.
    ${deconnecte}=    Run Keyword And Return Status    Se déconnecter
    IF    not ${deconnecte}
        Delete All Cookies
    END
    Go To    ${BASE_URL}
    ${email_hote}=    Set Variable    ${HOTE_EMAIL}
    ${mot_de_passe_hote}=    Set Variable    ${HOTE_PASSWORD}
    IF    $HOTE_DU_TEST_EMAIL != ''
        ${email_hote}=    Set Variable    ${HOTE_DU_TEST_EMAIL}
        ${mot_de_passe_hote}=    Set Variable    ${HOTE_DU_TEST_PASSWORD}
    END
    Se connecter en tant qu'hôte    ${email_hote}    ${mot_de_passe_hote}
    La connexion doit être confirmée

Relever le montant d'une ligne du détail de paiement
    [Documentation]    Lit le montant (nombre) de la ligne du bloc Paiement dont le libellé contient ${nom}. Retourne ${None} si la ligne est absente.
    [Arguments]    ${nom}
    ${ligne}=    Set Variable    xpath=(//aside[contains(@class,'dashboard-sidebar')]//div[@class='payment-list']//li[contains(normalize-space(.),"${nom}")]/span)[1]
    ${nombre}=    Get Element Count    ${ligne}
    IF    ${nombre} == 0
        RETURN    ${None}
    END
    ${texte}=    Get Text    ${ligne}
    ${montant}=    Evaluate    float($texte.replace('€','').replace(',','').replace(' ',''))
    RETURN    ${montant}

Contrôler le frais et la remise dans le détail de paiement
    [Documentation]    US08 : le bloc Paiement doit contenir la ligne du frais supplémentaire (montant positif) et de la remise (montant négatif),
    ...                et le total doit être égal à la somme des lignes. Toute différence est une anomalie détectée (le test se poursuit).
    [Arguments]    ${cote}    ${nom_frais}    ${valeur_frais}    ${nom_remise}    ${valeur_remise}
    ${attendu_frais}=     Evaluate    float($valeur_frais)
    ${attendu_remise}=    Evaluate    -float($valeur_remise)
    ${montant_frais}=     Relever le montant d'une ligne du détail de paiement    ${nom_frais}
    ${montant_remise}=    Relever le montant d'une ligne du détail de paiement    ${nom_remise}
    IF    $montant_frais is None
        Signaler une anomalie    Frais supplémentaire "${nom_frais}" absent du détail de paiement ${cote} - anomalie détectée - poursuite du test
    ELSE IF    $montant_frais == $attendu_frais
        Log    US08 : frais supplémentaire "${nom_frais}" : ${montant_frais}€ affiché ${cote} - OK    console=True
    ELSE
        Signaler une anomalie    Frais supplémentaire "${nom_frais}" affiché ${cote} à ${montant_frais}€ au lieu de ${attendu_frais}€ - anomalie détectée - poursuite du test
    END
    IF    $montant_remise is None
        Signaler une anomalie    Remise "${nom_remise}" absente du détail de paiement ${cote} - anomalie détectée - poursuite du test
    ELSE IF    $montant_remise == $attendu_remise
        Log    US08 : remise "${nom_remise}" : ${montant_remise}€ affichée ${cote} - OK    console=True
    ELSE
        Signaler une anomalie    Remise "${nom_remise}" affichée ${cote} à ${montant_remise}€ au lieu de ${attendu_remise}€ - anomalie détectée - poursuite du test
    END
    # Cohérence : somme des lignes = total
    ${lignes}=    Get WebElements    css=.dashboard-sidebar .payment-list li:not(.payment-due) > span
    ${somme}=    Set Variable    ${0}
    FOR    ${element}    IN    @{lignes}
        ${texte}=    Get Text    ${element}
        ${somme}=    Evaluate    ${somme} + float($texte.replace('€','').replace(',','').replace(' ',''))
    END
    ${texte_total}=    Get Text    css=.dashboard-sidebar .payment-list li.payment-due > span
    ${total}=    Evaluate    float($texte_total.replace('€','').replace(',','').replace(' ',''))
    IF    abs($somme - $total) < 0.01
        Log    US08 : total ${cote} cohérent : ${total}€ = somme des lignes (${somme}€)    console=True
    ELSE
        Signaler une anomalie    Total du détail de paiement ${cote} incohérent : ${total}€ affiché pour une somme de lignes de ${somme}€ - anomalie détectée - poursuite du test
    END
    RETURN    ${total}

Le total du tableau doit correspondre au total du détail
    [Documentation]    US08 : la colonne Total du tableau doit afficher le même total que le détail de la réservation (frais et remise inclus).
    [Arguments]    ${cote}    ${id}    ${total_detail}
    ${texte}=    Relever la colonne d'une ligne du tableau    ${id}    Total
    ${total_tableau}=    Evaluate    float($texte.replace('€','').replace(',','').replace(' ',''))
    IF    abs($total_tableau - $total_detail) < 0.01
        Log    US08 : total du tableau ${cote} (${total_tableau}€) identique au détail - OK    console=True
    ELSE
        Signaler une anomalie    Total du tableau ${cote} (${total_tableau}€) différent du total du détail (${total_detail}€) pour la réservation ${id} - anomalie détectée - poursuite du test
    END

# ---------- Lignes des tableaux Réservations / Voyages, retrouvées par leur ID (partagé avec la page Voyages) ----------
Relever la colonne d'une ligne du tableau
    [Documentation]    Texte de la cellule ${colonne} (Statut, Total...) de la ligne dont l'ID est ${id}.
    [Arguments]    ${id}    ${colonne}
    ${ligne}=    Evaluate    $LIGNE_TABLEAU_PAR_ID.replace('{ID}', $id)
    ${texte}=    Get Text    xpath=${ligne}/td[@data-label='${colonne}']
    RETURN    ${texte}

Cliquer sur le lien Actions de la ligne
    [Documentation]    Ouvre le détail de la ligne dont l'ID est ${id} (lien « Détails » de la colonne Actions).
    [Arguments]    ${id}
    ${ligne}=    Evaluate    $LIGNE_TABLEAU_PAR_ID.replace('{ID}', $id)
    Click Element    xpath=${ligne}//td[@data-label='Actions']//a

Compter les lignes du tableau pour l'ID
    [Documentation]    Nombre de lignes du tableau dont l'ID est ${id} (0 si la réservation n'y figure pas).
    [Arguments]    ${id}
    ${ligne}=    Evaluate    $LIGNE_TABLEAU_PAR_ID.replace('{ID}', $id)
    ${nombre}=    Get Element Count    xpath=${ligne}
    RETURN    ${nombre}
