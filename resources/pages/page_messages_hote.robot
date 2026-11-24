*** Settings ***
Library    SeleniumLibrary
Resource   ../variables.robot
Resource   ../recapitulatif.robot

*** Variables ***
${MESSAGES_MENU_GAUCHE}             css=.board-panel-menu a[href$='/index.php/messages/']
${MESSAGES_TITRE_PAGE}              css=.dashboard-page-title h1

*** Keywords ***
Ouvrir la boîte Messages
    Log    Hôte : ouverture de la boîte "Messages"    console=True
    Click Element    ${MESSAGES_MENU_GAUCHE}
    Wait Until Element Is Visible    ${MESSAGES_TITRE_PAGE}    timeout=20s
    Element Should Contain    ${MESSAGES_TITRE_PAGE}    Messages

La demande de réservation doit être présente dans la boîte Messages
    [Documentation]    Vérification non bloquante : si la boîte est vide, on trace l'anomalie détectée et on poursuit.
    ${vide}=    Run Keyword And Return Status    Page Should Contain    ${TEXTE_AUCUN_MESSAGE}
    IF    ${vide}
        Signaler une anomalie    Demande de réservation absente dans la boîte « Messages » côté hôte - anomalie détectée - poursuite du test
    ELSE
        Log    La boîte « Messages » côté hôte contient au moins un message    console=True
        Set Test Message    Boîte « Messages » côté hôte non vide.    append=True
    END
