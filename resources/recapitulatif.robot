*** Settings ***
Library    Collections
Library    String
Library    OperatingSystem
Library    SeleniumLibrary
Resource   pages/page_accueil.robot

*** Variables ***
# Noms volontairement différents des variables locales : Robot ne distingue pas majuscules et minuscules
# Données partagées par tous les tests de la suite : statut et anomalies de chaque test
&{DICO_RESULTATS}
&{DICO_ANOMALIES}
@{ORDRE_TESTS}

*** Keywords ***
Signaler une anomalie
    [Documentation]    Trace une anomalie (avertissement dans les logs) et la mémorise pour le tableau récapitulatif de fin.
    [Arguments]    ${message}
    Log    ${message}    level=WARN    console=True
    Mémoriser l'anomalie    ${message}
    # Capture d'écran de la page au moment de l'anomalie (visible dans log.html juste sous l'avertissement ; ignorée si aucun navigateur n'est ouvert)
    ${capture}    ${chemin}=    Run Keyword And Ignore Error    Capture Page Screenshot
    IF    '${capture}' == 'PASS'
        Log    Capture d'écran de l'anomalie : ${chemin}
    END
    Set Test Message    ${message}.    append=True

Mémoriser l'anomalie
    [Arguments]    ${message}
    ${existe}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${DICO_ANOMALIES}    ${TEST NAME}
    IF    not ${existe}
        ${liste}=    Create List
        Set To Dictionary    ${DICO_ANOMALIES}    ${TEST NAME}    ${liste}
    END
    ${liste}=    Get From Dictionary    ${DICO_ANOMALIES}    ${TEST NAME}
    Append To List    ${liste}    ${message}

Enregistrer le résultat du test
    Set To Dictionary    ${DICO_RESULTATS}    ${TEST NAME}    ${TEST STATUS}
    Append To List    ${ORDRE_TESTS}    ${TEST NAME}
    IF    '${TEST STATUS}' == 'FAIL'
        Mémoriser l'anomalie    Échec du test : ${TEST MESSAGE}
    END

Fermer l'application et enregistrer le résultat
    TRY
        Enregistrer le résultat du test
    FINALLY
        Fermer l'application
    END

Afficher le récapitulatif des tests
    [Documentation]    Tableau de fin : numéro et titre de chaque test, statut, anomalies détectées (console, log.html et results/recapitulatif_<US>.csv).
    ...                L'argument est le nom de la User Story (US07 par défaut, US08, ...) : il sert au titre du tableau et au nom du fichier CSV.
    [Arguments]    ${user_story}=US07
    ${separateur}=    Evaluate    '-' * 150
    ${texte}=    Set Variable    ${separateur}\nRÉCAPITULATIF DES TESTS - ${user_story}\n${separateur}
    ${lignes_html}=    Set Variable    ${EMPTY}
    ${entete}=    Create List    Test    Titre    Statut    Nb anomalies    Anomalies détectées
    ${lignes_csv}=    Create List    ${entete}
    ${largeur_titre}=    Evaluate    max([len(n.split(' - ', 1)[1] if ' - ' in n else n) for n in $ORDRE_TESTS] or [10])
    FOR    ${nom}    IN    @{ORDRE_TESTS}
        ${numero}=    Fetch From Left    ${nom}    ${SPACE}-${SPACE}
        ${titre}=     Evaluate    $nom.split(' - ', 1)[1] if ' - ' in $nom else $nom
        ${statut}=    Get From Dictionary    ${DICO_RESULTATS}    ${nom}
        ${a_des_anomalies}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${DICO_ANOMALIES}    ${nom}
        ${texte_anomalies}=    Set Variable    Aucune
        ${texte_anomalies_csv}=    Set Variable    Aucune
        ${nombre_anomalies}=    Set Variable    ${0}
        IF    ${a_des_anomalies}
            ${liste}=    Get From Dictionary    ${DICO_ANOMALIES}    ${nom}
            # L'échec du test lui-même (ligne "Échec du test : ...") n'est pas une anomalie du site : on ne la compte pas
            ${nombre_anomalies}=    Evaluate    len([a for a in $liste if not a.startswith('Échec du test')])
            ${texte_anomalies}=    Evaluate    ' ; '.join($liste)
            # Dans le CSV : une anomalie par ligne dans la même cellule (saut de ligne)
            ${texte_anomalies_csv}=    Evaluate    chr(10).join($liste)
        END
        # Un test PASS qui a tracé des anomalies est affiché "PASS avec anomalies" (le statut Robot du test, lui, reste PASS)
        ${statut_affiche}=    Set Variable If    '${statut}' == 'PASS' and ${nombre_anomalies} > 0    PASS avec anomalies    ${statut}
        ${ligne}=    Evaluate    '{:<10} | {:<{w}} | {:<19} | {:>2} | {}'.format($numero, $titre, $statut_affiche, $nombre_anomalies, $texte_anomalies, w=$largeur_titre)
        ${texte}=    Set Variable    ${texte}\n${ligne}
        ${ligne_csv}=    Create List    ${numero}    ${titre}    ${statut_affiche}    ${nombre_anomalies}    ${texte_anomalies_csv}
        Append To List    ${lignes_csv}    ${ligne_csv}
        ${lignes_html}=    Set Variable    ${lignes_html}<tr><td>${numero}</td><td>${titre}</td><td>${statut_affiche}</td><td>${nombre_anomalies}</td><td>${texte_anomalies}</td></tr>
    END
    ${texte}=    Set Variable    ${texte}\n${separateur}
    Log To Console    \n${texte}
    Log    <table border="1" cellpadding="4" style="border-collapse:collapse"><tr><th>Test</th><th>Titre</th><th>Statut</th><th>Nb anomalies</th><th>Anomalies détectées</th></tr>${lignes_html}</table>    html=True
    Log    ${texte}
    # Fichier de résultat : results/recapitulatif_<US>.csv (s'ouvre dans Excel, séparateur ";")
    ${contenu}=    Evaluate    chr(0xFEFF) + (chr(13) + chr(10)).join(';'.join('"' + str(c).replace('"', '""') + '"' for c in ligne) for ligne in $lignes_csv)
    ${fichier}=    Set Variable    ${OUTPUT DIR}${/}recapitulatif_${user_story}.csv
    Create File    ${fichier}    ${contenu}    encoding=UTF-8
    Log To Console    Récapitulatif enregistré dans : ${fichier}
    Log    Récapitulatif enregistré dans : ${fichier}
