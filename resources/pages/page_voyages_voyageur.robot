*** Settings ***
Library    SeleniumLibrary
Library    DateTime
Resource   ../variables.robot
Resource   ../recapitulatif.robot
Resource   page_reservations_hote.robot
Resource   page_annonce.robot

*** Variables ***
${VOYAGES_MENU_UTILISATEUR}         css=.account-loggedin
${VOYAGES_LIEN_MENU_UTILISATEUR}    xpath=//header[@id='homey_nav_sticky']//div[contains(@class,'account-dropdown')]//a[contains(@href,'/index.php/reservations/')]
${VOYAGES_TABLEAU}                  css=.dashboard-reservation-table table
${VOYAGES_STATUT_DETAIL}            css=.block-head .title .label
${VOYAGES_ZONE_PAIEMENT}            css=.dashboard-sidebar .payment-list
${VOYAGES_BOUTON_PAYEZ}             css=.dashboard-sidebar > a.btn-success
${VOYAGES_MARQUER_PAYE}             css=.mark-as-paid
${VOYAGES_CONFIRMER_POPUP}          css=.modal-footer > .btn-primary
${VOYAGES_PREMIERE_LIGNE_PAIEMENT}  css=.dashboard-sidebar .payment-list li:first-child
${VOYAGES_LIGNE_IMPOTS}             xpath=(//aside[contains(@class,'dashboard-sidebar')]//div[@class='payment-list']//li[contains(normalize-space(.),'Impôts')])[1]
${VOYAGES_TOTAL_DETAIL}             css=.dashboard-sidebar .payment-list li.payment-due > span
${VOYAGES_ALERTE_SUCCES}            css=.dashboard-area .alert-success
${VOYAGES_ALERTE_ERREUR}            css=.dashboard-area .alert-danger, .dashboard-area .alert-warning, .dashboard-area .alert-error

*** Keywords ***
Ouvrir la page Voyages
    Log    Voyageur : ouverture de la page "Voyages" (menu du nom d'utilisateur)    console=True
    Click Element    ${VOYAGES_MENU_UTILISATEUR}
    Wait Until Element Is Visible    ${VOYAGES_LIEN_MENU_UTILISATEUR}
    Click Element    ${VOYAGES_LIEN_MENU_UTILISATEUR}
    Wait Until Element Is Visible    ${VOYAGES_TABLEAU}    timeout=20s

Le voyage envoyé doit être présent dans la page Voyages
    [Documentation]    Côté voyageur la demande s'appelle un "voyage". On retrouve la ligne de la demande envoyée
    ...                et on mémorise son ID (${ID_VOYAGE}), identique à l'ID de la réservation côté hôte.
    [Arguments]    ${arrivee}    ${depart}    ${voyageurs}    ${nom_annonce}    ${adresse}    ${statut}    ${heure_envoi}    ${tolerance_minutes}
    ${critere}=    Set Variable    //div[contains(@class,'dashboard-reservation-table')]//tbody/tr[td[@data-label='Arrivée'][normalize-space()='${arrivee}'] and td[@data-label='Départ'][normalize-space()='${depart}'] and td[@data-label='Voyageurs'][normalize-space()='${voyageurs}'] and td[@data-label='Adresse'][contains(.,'${nom_annonce}')]]
    Log    Recherche côté voyageur : annonce ${nom_annonce}, arrivée ${arrivee}, départ ${depart}, ${voyageurs} voyageur(s)    console=True
    ${nombre}=    Get Element Count    xpath=${critere}
    IF    ${nombre} == 0
        Capture Page Screenshot
        Fail    Voyage non trouvé côté voyageur (arrivée ${arrivee}, départ ${depart}, ${voyageurs} voyageur(s))
    END
    ${ligne}=    Set Variable    (${critere})[1]
    ${id}=    Get Text    xpath=${ligne}/td[@data-label='ID']
    Should Match Regexp    ${id}    ^#[0-9]+$
    Set Test Variable    ${ID_VOYAGE}    ${id}
    ${statut_lu}=    Get Text    xpath=${ligne}/td[@data-label='Statut']
    Should Contain    ${statut_lu}    ${statut}
    ${adresse_lue}=    Get Text    xpath=${ligne}/td[@data-label='Adresse']
    Should Contain    ${adresse_lue}    ${adresse}
    ${date_lue}=    Get Text    xpath=${ligne}/td[@data-label='Date']
    ${match}    ${jour}    ${heure}=    Should Match Regexp    ${date_lue}    ([0-9]{4}-[0-9]{2}-[0-9]{2})\\s+([0-9]{1,2}:[0-9]{2})
    # Le site affiche l'heure sans zéro devant avant 10h (ex. 9:01) : on la complète (09:01)
    ${heure}=    Evaluate    '{:0>5}'.format($heure)
    ${ecart}=    Subtract Date From Date    ${heure_envoi}    ${jour} ${heure}:00
    # Le site affiche l'heure sur 12 h sans AM/PM (ex. 3:36 pour 15:36) : on compare modulo 12 h pour accepter les deux cas
    ${ecart_minutes}=    Evaluate    min(abs(${ecart}) % 43200, 43200 - abs(${ecart}) % 43200) / 60
    Should Be True    ${ecart_minutes} <= ${tolerance_minutes}    Écart date/heure trop grand : ${ecart_minutes} min (maximum ${tolerance_minutes})
    Log    Voyage ${id} trouvé côté voyageur : statut ${statut_lu}, ${jour} ${heure}, du ${arrivee} au ${depart}, ${voyageurs} voyageur(s) - OK    console=True
    Set Test Message    Voyage ${id} créé côté voyageur (statut ${statut_lu}).    append=True

Tracer les lignes comptées
    [Documentation]    Trace l'ID et le statut de chaque ligne retenue par un critère de comptage (pour comprendre un nombre inattendu).
    [Arguments]    ${critere}
    ${lignes}=    Get WebElements    xpath=${critere}
    FOR    ${ligne}    IN    @{lignes}
        ${texte}=    Get Text    ${ligne}
        ${texte}=    Evaluate    ' '.join($texte.split())
        Log    Ligne comptée : ${texte}    console=True
    END

Un seul voyage doit exister pour les dates demandées
    [Documentation]    TEST 07-17 : les voyages refusés (anciens essais) sont ignorés ; il doit rester exactement un voyage.
    [Arguments]    ${arrivee}    ${depart}    ${voyageurs}    ${nom_annonce}
    ${critere}=    Set Variable    //div[contains(@class,'dashboard-reservation-table')]//tbody/tr[td[@data-label='Arrivée'][normalize-space()='${arrivee}'] and td[@data-label='Départ'][normalize-space()='${depart}'] and td[@data-label='Voyageurs'][normalize-space()='${voyageurs}'] and td[@data-label='Adresse'][contains(.,'${nom_annonce}')] and not(contains(normalize-space(td[@data-label='Statut']),'REFUS')) and not(contains(normalize-space(td[@data-label='Statut']),'ANNUL'))]
    ${nombre}=    Get Element Count    xpath=${critere}
    Tracer les lignes comptées    ${critere}
    Log    TEST 07-17 : ${nombre} voyage(s) non refusé(s) côté voyageur pour les dates du ${arrivee} au ${depart}    console=True
    Should Be Equal As Integers    ${nombre}    1    Il devrait y avoir 1 seul voyage pour ces dates, il y en a ${nombre}

Relever le nombre de voyages créés pour les dates demandées
    [Documentation]    Tests 6, 7, 10, 11, 12 et 15 : compte les voyages non refusés pour ces dates (0 attendu) et retourne le nombre.
    [Arguments]    ${arrivee}    ${depart}    ${voyageurs}    ${nom_annonce}
    ${critere}=    Set Variable    //div[contains(@class,'dashboard-reservation-table')]//tbody/tr[td[@data-label='Arrivée'][normalize-space()='${arrivee}'] and td[@data-label='Départ'][normalize-space()='${depart}'] and td[@data-label='Voyageurs'][normalize-space()='${voyageurs}'] and td[@data-label='Adresse'][contains(.,'${nom_annonce}')] and not(contains(normalize-space(td[@data-label='Statut']),'REFUS')) and not(contains(normalize-space(td[@data-label='Statut']),'ANNUL'))]
    ${nombre}=    Get Element Count    xpath=${critere}
    Tracer les lignes comptées    ${critere}
    Log    Voyages créés : ${nombre} voyage(s) non refusé(s) côté voyageur pour les dates du ${arrivee} au ${depart}    console=True
    RETURN    ${nombre}

Le statut du voyage doit être
    [Documentation]    US08 : après confirmation par l'hôte, le voyage (même ID que la réservation) doit avoir le statut attendu (DISPONIBLE).
    [Arguments]    ${id}    ${statut_attendu}
    ${statut_lu}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    Log    US08 : statut du voyage ${id} côté voyageur : "${statut_lu}" (attendu : "${statut_attendu}")    console=True
    ${conforme}=    Evaluate    $statut_attendu in $statut_lu
    IF    not ${conforme}
        Capture Page Screenshot
        Fail    Le voyage ${id} a le statut "${statut_lu}" côté voyageur au lieu de "${statut_attendu}"
    END
    Log    US08 : statut ${statut_lu} conforme côté voyageur    console=True
    Set Test Message    Statut voyageur : ${statut_lu}.    append=True

Les frais supplémentaires et la remise doivent être affichés côté voyageur
    [Documentation]    US08 : le voyageur ouvre le détail de son voyage (lien "Payez maintenant"), contrôle le statut, le frais supplémentaire,
    ...                la remise et la cohérence des totaux (détail et tableau Voyages).
    [Arguments]    ${id}    ${statut_attendu}    ${nom_frais}    ${valeur_frais}    ${nom_remise}    ${valeur_remise}
    Log    US08 : le voyageur ouvre le détail du voyage ${id}    console=True
    Cliquer sur le lien Actions de la ligne    ${id}
    Wait Until Element Is Visible    ${VOYAGES_ZONE_PAIEMENT}    timeout=20s
    Capture Page Screenshot
    ${statut_detail}=    Get Text    ${VOYAGES_STATUT_DETAIL}
    IF    '${statut_attendu}' in '''${statut_detail}'''
        Log    US08 : statut ${statut_detail} affiché aussi dans le détail du voyage ${id} - OK    console=True
    ELSE
        Signaler une anomalie    Statut du détail du voyage ${id} : "${statut_detail}" au lieu de "${statut_attendu}" - anomalie détectée - poursuite du test
    END
    ${total}=    Contrôler le frais et la remise dans le détail de paiement    côté voyageur    ${nom_frais}    ${valeur_frais}    ${nom_remise}    ${valeur_remise}
    Ouvrir la page Voyages
    Le total du tableau doit correspondre au total du détail    côté voyageur    ${id}    ${total}

Ouvrir le détail du voyage pour payer
    [Documentation]    US08 : depuis le tableau Voyages, clic sur "Payez maintenant" de la ligne du voyage (statut DISPONIBLE).
    [Arguments]    ${id}
    Log    US08 : le voyageur clique sur "Payez maintenant" pour le voyage ${id}    console=True
    Cliquer sur le lien Actions de la ligne    ${id}
    Wait Until Element Is Visible    ${VOYAGES_ZONE_PAIEMENT}    timeout=20s
    Capture Page Screenshot

Contrôler une information du séjour sur le détail du voyage
    [Arguments]    ${libelle}    ${attendu}
    ${lu}=    Get Text    xpath=//ul[contains(@class,'detail-list-2-cols')]/li[contains(normalize-space(.),'${libelle}')]/strong
    IF    $lu == str($attendu)
        Log    US08 : ${libelle} : ${lu} conforme sur le détail du voyage - OK    console=True
    ELSE
        Signaler une anomalie    ${libelle} affiché ${lu} au lieu de ${attendu} sur le détail du voyage - anomalie détectée - poursuite du test
    END

Les informations du séjour et du paiement doivent être affichées côté voyageur
    [Documentation]    US08 : page de paiement détaillé : arrivée, départ, nombre de nuits, voyageurs, puis prix x nuits, frais de nettoyage, impôts.
    ...                (Le frais supplémentaire et la remise sont déjà contrôlés plus haut dans le test.) Tout écart est une anomalie détectée.
    [Arguments]    ${arrivee}    ${depart}    ${nuits}    ${voyageurs}
    Contrôler une information du séjour sur le détail du voyage    Arrivée    ${arrivee}
    Contrôler une information du séjour sur le détail du voyage    Départ    ${depart}
    Contrôler une information du séjour sur le détail du voyage    nuit    ${nuits}
    # Le libellé est « Voyageur » au singulier quand il n'y en a qu'un : on cherche la racine commune
    Contrôler une information du séjour sur le détail du voyage    Voyageur    ${voyageurs}
    # Prix par nuit x nombre de nuits
    ${ligne_prix}=    Get Text    ${VOYAGES_PREMIERE_LIGNE_PAIEMENT}
    # Texte remis sur une seule ligne (le site le coupe sur plusieurs lignes) pour des logs lisibles
    ${ligne_prix}=    Evaluate    ' '.join($ligne_prix.split())
    ${prix_ok}=    Run Keyword And Return Status    Should Match Regexp    ${ligne_prix}    ([0-9.,]+)€\\s*x\\s*([0-9]+)\\s*nuits?\\s*([0-9.,]+)€
    IF    ${prix_ok}
        ${m}    ${prix}    ${nb}    ${montant}=    Should Match Regexp    ${ligne_prix}    ([0-9.,]+)€\\s*x\\s*([0-9]+)\\s*nuits?\\s*([0-9.,]+)€
        ${attendu_montant}=    Evaluate    float($prix.replace(',','')) * int($nb)
        ${montant_lu}=    Evaluate    float($montant.replace(',',''))
        Log    US08 : prix par nuit ${prix}€ x ${nb} nuit(s) = ${montant_lu}€    console=True
        IF    $nb != str($nuits)
            Signaler une anomalie    Nombre de nuits ${nb} dans la ligne de prix au lieu de ${nuits} - anomalie détectée - poursuite du test
        END
        IF    abs($attendu_montant - $montant_lu) > 0.01
            Signaler une anomalie    Ligne de prix incohérente : ${prix}€ x ${nb} nuit(s) devrait donner ${attendu_montant}€ et non ${montant_lu}€ - anomalie détectée - poursuite du test
        END
    ELSE
        Signaler une anomalie    Ligne "prix x nombre de nuits" non lisible : "${ligne_prix}" - anomalie détectée - poursuite du test
    END
    # Frais de nettoyage
    ${nettoyage}=    Relever le montant d'une ligne du détail de paiement    Frais de nettoyage
    IF    $nettoyage is None
        Signaler une anomalie    Ligne "Frais de nettoyage" absente du détail de paiement - anomalie détectée - poursuite du test
    ELSE
        Log    US08 : frais de nettoyage : ${nettoyage}€ - OK    console=True
    END
    # Impôts
    ${ligne_impots}=    Get Text    ${VOYAGES_LIGNE_IMPOTS}
    ${ligne_impots}=    Evaluate    ' '.join($ligne_impots.split())
    ${impots_ok}=    Run Keyword And Return Status    Should Match Regexp    ${ligne_impots}    Impôts\\s+[0-9.,]+%\\s*[0-9.,]+€
    IF    ${impots_ok}
        Log    US08 : impôts : ${ligne_impots} - OK    console=True
    ELSE
        Signaler une anomalie    Ligne "Impôts" non lisible : "${ligne_impots}" - anomalie détectée - poursuite du test
    END

Cliquer sur Payez maintenant avec le prix affiché
    [Documentation]    US08 : le prix affiché sur le bouton doit être le total du détail ; puis clic pour accéder à la page de paiement hors-site.
    ${texte_total}=    Get Text    ${VOYAGES_TOTAL_DETAIL}
    ${total}=    Evaluate    float($texte_total.replace('€','').replace(',','').replace(' ',''))
    ${bouton}=    Get Text    ${VOYAGES_BOUTON_PAYEZ}
    ${prix_ok}=    Run Keyword And Return Status    Should Match Regexp    ${bouton}    Payez maintenant\\s+[0-9.,]+€
    IF    ${prix_ok}
        ${m}    ${prix_bouton}=    Should Match Regexp    ${bouton}    Payez maintenant\\s+([0-9.,]+)€
        ${prix_bouton_nombre}=    Evaluate    float($prix_bouton.replace(',',''))
        IF    abs($prix_bouton_nombre - $total) < 0.01
            Log    US08 : le bouton affiche "${bouton}", égal au total du détail (${total}€) - OK    console=True
        ELSE
            Signaler une anomalie    Prix du bouton "${bouton}" différent du total du détail (${total}€) - anomalie détectée - poursuite du test
        END
    ELSE
        Signaler une anomalie    Le bouton "Payez maintenant" n'affiche pas de prix : "${bouton}" - anomalie détectée - poursuite du test
    END
    Click Element    ${VOYAGES_BOUTON_PAYEZ}

Le voyageur paye sa demande avec Marquer comme payé
    [Documentation]    US08 : sur la page de détails, clic sur l'icône "Marquer comme payé" puis sur "Confirmer" dans la pop-up ; le voyage doit passer à RÉSERVÉ.
    [Arguments]    ${id}    ${statut_attendu}
    Wait Until Element Is Visible    ${VOYAGES_MARQUER_PAYE}    timeout=20s
    Log    US08 : le voyageur clique sur "Marquer comme payé" (voyage ${id})    console=True
    Click Element    ${VOYAGES_MARQUER_PAYE}
    Wait Until Element Is Visible    ${VOYAGES_CONFIRMER_POPUP}    timeout=20s
    Capture Page Screenshot
    Log    US08 : pop-up de confirmation affichée, clic sur "Confirmer"    console=True
    Click Element    ${VOYAGES_CONFIRMER_POPUP}
    # Le site peut mettre à jour la page tout seul (attente ciblée de 5 s max) ; sinon on la rafraîchit (jusqu'à 30 s)
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    ${VOYAGES_CONFIRMER_POPUP}    timeout=10s
    Run Keyword And Ignore Error    Wait Until Element Contains    ${VOYAGES_STATUT_DETAIL}    ${statut_attendu}    timeout=5s
    ${statut_ok}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    30s    3s    Rafraîchir le détail du voyage jusqu'au statut    ${statut_attendu}
    ${statut}=    Get Text    ${VOYAGES_STATUT_DETAIL}
    Log    US08 : statut affiché sur le détail du voyage ${id} après paiement : "${statut}" (attendu : "${statut_attendu}")    console=True
    Capture Page Screenshot
    IF    not ${statut_ok}
        Fail    Le voyage ${id} n'est pas passé au statut "${statut_attendu}" après le paiement (statut affiché : "${statut}")
    END
    ${alerte_ok}=    Run Keyword And Return Status    Element Should Be Visible    ${VOYAGES_ALERTE_SUCCES}
    IF    ${alerte_ok}
        ${message}=    Get Text    ${VOYAGES_ALERTE_SUCCES}
        Log    US08 : message du site : ${message}    console=True
    END
    Set Test Message    Voyage ${id} payé par le voyageur (statut ${statut}).    append=True

Rafraîchir le détail du voyage jusqu'au statut
    [Arguments]    ${statut_attendu}
    ${statut}=    Get Text    ${VOYAGES_STATUT_DETAIL}
    ${ok}=    Evaluate    $statut_attendu in $statut
    IF    not ${ok}
        Reload Page
        Wait Until Element Is Visible    ${VOYAGES_STATUT_DETAIL}    timeout=15s
        ${statut}=    Get Text    ${VOYAGES_STATUT_DETAIL}
        Should Contain    ${statut}    ${statut_attendu}
    END

Le voyageur tente de payer alors que l'hôte n'a pas de coordonnées de paiement
    [Documentation]    TEST 08-9 : clic sur "Marquer comme payé" puis "Confirmer". Le site DOIT bloquer le paiement : si le bouton ou la pop-up est indisponible, ou si le voyage
    ...                reste DISPONIBLE, le test est OK. Si le voyage passe au statut RÉSERVÉ, c'est une anomalie (paiement accepté à tort) et le test se poursuit.
    [Arguments]    ${id}    ${statut_reserve}
    Set Test Variable    ${PAIEMENT_ACCEPTE_A_TORT}    ${FALSE}
    ${bouton}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${VOYAGES_MARQUER_PAYE}    timeout=10s
    IF    not ${bouton}
        Capture Page Screenshot
        Log    US08 : bouton "Marquer comme payé" indisponible pour le voyage ${id} : paiement bloqué par le site - OK    console=True
        Set Test Message    Paiement bloqué par le site (bouton "Marquer comme payé" indisponible).    append=True
        RETURN
    END
    Log    US08 : le voyageur tente de payer le voyage ${id} avec "Marquer comme payé" (l'hôte n'a pas de coordonnées de paiement)    console=True
    Click Element    ${VOYAGES_MARQUER_PAYE}
    ${popup}=    Run Keyword And Return Status    Wait Until Element Is Visible    ${VOYAGES_CONFIRMER_POPUP}    timeout=10s
    Capture Page Screenshot
    IF    ${popup}
        Log    US08 : pop-up de confirmation affichée, clic sur "Confirmer"    console=True
        Click Element    ${VOYAGES_CONFIRMER_POPUP}
    ELSE
        Log    US08 : aucune pop-up de confirmation après le clic sur "Marquer comme payé" (blocage probable par le site)    console=True
    END
    Run Keyword And Ignore Error    Wait Until Element Is Not Visible    ${VOYAGES_CONFIRMER_POPUP}    timeout=10s
    # Le site ne met pas toujours la page à jour : attente ciblée du statut RÉSERVÉ, puis on rafraîchit jusqu'à 2 fois avant de conclure
    ${statut}=    Set Variable    ${EMPTY}
    FOR    ${essai}    IN RANGE    3
        ${statut_present}=    Run Keyword And Return Status    Element Should Be Visible    ${VOYAGES_STATUT_DETAIL}
        IF    ${statut_present}
            ${statut}=    Get Text    ${VOYAGES_STATUT_DETAIL}
        END
        IF    $statut_reserve in $statut    BREAK
        IF    ${essai} < 2
            ${mis_a_jour}=    Run Keyword And Return Status    Wait Until Element Contains    ${VOYAGES_STATUT_DETAIL}    ${statut_reserve}    timeout=3s
            IF    not ${mis_a_jour}
                Reload Page
                Wait Until Element Is Visible    ${VOYAGES_STATUT_DETAIL}    timeout=15s
            END
        END
    END
    Capture Page Screenshot
    ${erreur_affichee}=    Run Keyword And Return Status    Element Should Be Visible    ${VOYAGES_ALERTE_ERREUR}
    IF    ${erreur_affichee}
        ${message_erreur}=    Get Text    ${VOYAGES_ALERTE_ERREUR}
        Log    US08 : message d'erreur du site : ${message_erreur}    console=True
    END
    Log    US08 : statut affiché sur le détail du voyage ${id} après la tentative de paiement : "${statut}"    console=True
    IF    $statut_reserve in $statut
        Set Test Variable    ${PAIEMENT_ACCEPTE_A_TORT}    ${TRUE}
        Signaler une anomalie    Paiement accepté à tort : le voyage ${id} est passé au statut "${statut}" alors que l'hôte n'a renseigné aucune information de paiement - anomalie détectée - poursuite du test
    ELSE
        Log    US08 : paiement bloqué par le site, le voyage ${id} reste au statut "${statut}" - OK    console=True
        Set Test Message    Paiement bloqué par le site (statut ${statut}).    append=True
    END

Le statut du voyage doit être resté
    [Documentation]    TEST 08-9 : dans le tableau Voyages, le voyage doit être toujours DISPONIBLE et non RÉSERVÉ. Tout écart est une anomalie (le test se poursuit).
    [Arguments]    ${id}    ${statut_attendu}    ${statut_interdit}
    ${statut_lu}=    Relever la colonne d'une ligne du tableau    ${id}    Statut
    Log    US08 : statut du voyage ${id} dans le tableau du voyageur : "${statut_lu}" (attendu : "${statut_attendu}", interdit : "${statut_interdit}")    console=True
    IF    $statut_interdit in $statut_lu
        Signaler une anomalie    Voyage ${id} au statut "${statut_lu}" dans le tableau du voyageur au lieu de "${statut_attendu}" (le paiement aurait dû être bloqué) - anomalie détectée - poursuite du test
    ELSE IF    $statut_attendu in $statut_lu
        Log    US08 : statut ${statut_lu} conforme dans le tableau du voyageur - OK    console=True
        Set Test Message    Statut voyageur (tableau) : ${statut_lu}.    append=True
    ELSE
        Signaler une anomalie    Voyage ${id} au statut "${statut_lu}" dans le tableau du voyageur au lieu de "${statut_attendu}" - anomalie détectée - poursuite du test
    END

# ---------- Demande retrouvée dans les voyages (étapes partagées par US07 et US08) ----------
Le voyageur envoie une demande de réservation et la retrouve dans ses voyages
    [Documentation]    Étapes communes : demande de réservation (voir ci-dessus), puis contrôle du voyage (statut À L'ÉTUDE) dans la page Voyages du voyageur.
    ...                On mémorise ainsi l'ID du voyage (${ID_VOYAGE}), identique à l'ID de la réservation côté hôte.
    [Arguments]    ${url_annonce}=${URL_ANNONCE_TEST}    ${adresse_annonce}=${ADRESSE_ANNONCE_ATTENDUE}    ${nombre_adultes}=${NOMBRE_ADULTES}
    Le voyageur envoie une demande de réservation sur des dates réservables    ${url_annonce}    ${nombre_adultes}
    # Côté voyageur la demande est un "voyage" : on mémorise son ID pour la retrouver côté hôte
    Ouvrir la page Voyages
    Le voyage doit être présent dans Voyages avec les données envoyées    ${adresse_annonce}

Le voyage doit être présent dans Voyages avec les données envoyées
    [Arguments]    ${adresse_annonce}=${ADRESSE_ANNONCE_ATTENDUE}
    Le voyage envoyé doit être présent dans la page Voyages    ${SEJOUR_ARRIVEE}    ${SEJOUR_DEPART}    ${NB_VOYAGEURS_ENVOYES}    ${NOM_ANNONCE}    ${adresse_annonce}    ${STATUT_VOYAGE_ATTENDU}    ${HEURE_ENVOI}    ${TOLERANCE_HEURE_MINUTES}
