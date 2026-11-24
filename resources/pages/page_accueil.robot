*** Settings ***
Library    SeleniumLibrary
Resource   ../variables.robot

*** Keywords ***
Ouvrir l'application
    Open Browser    ${BASE_URL}    ${BROWSER}    options=${OPTIONS_CHROME}
    Set Window Size    ${LARGEUR_FENETRE}    ${HAUTEUR_FENETRE}

Fermer l'application
    # En cas d'échec, une capture d'écran de la page est ajoutée au log avant la fermeture du navigateur
    Run Keyword If Test Failed    Capture Page Screenshot
    Close Browser
