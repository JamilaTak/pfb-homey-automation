*** Settings ***
Library    SeleniumLibrary
Resource   ../variables.robot

*** Variables ***
${CONNEXION_LIEN_SE_CONNECTER}      xpath=//a[contains(text(),'Se connecter')]
${CONNEXION_CHAMP_EMAIL}            name=username
${CONNEXION_CHAMP_MOT_DE_PASSE}     name=password
${CONNEXION_BOUTON_SE_CONNECTER}    css=.homey_login_button
${CONNEXION_ZONE_ERREUR}            css=#modal-login .error
${CONNEXION_MENU_UTILISATEUR}       css=.account-loggedin
${CONNEXION_LIEN_SE_DECONNECTER}    xpath=//header[@id='homey_nav_sticky']//a[contains(text(),'Se déconnecter')]

*** Keywords ***
# Ce mot-clé sait exactement où se trouvent les champs et le bouton
Se connecter en tant que voyageur
    [Arguments]    ${email}    ${mot_de_passe}
    Click Link    ${CONNEXION_LIEN_SE_CONNECTER}
    Wait Until Element Is Visible    ${CONNEXION_CHAMP_EMAIL}
    Saisir dans un champ de connexion    ${CONNEXION_CHAMP_EMAIL}    ${email}
    Saisir dans un champ de connexion    ${CONNEXION_CHAMP_MOT_DE_PASSE}    ${mot_de_passe}
    Click Button     ${CONNEXION_BOUTON_SE_CONNECTER}

Saisir dans un champ de connexion
    [Documentation]    La fenêtre de connexion s'anime à l'ouverture : la saisie peut être perdue (« The username or email field is empty »).
    ...                On vérifie donc que le champ contient bien la valeur saisie, et on recommence jusqu'à 3 fois sinon.
    [Arguments]    ${champ}    ${valeur}
    FOR    ${essai}    IN RANGE    1    4
        Click Element    ${champ}
        Input Text    ${champ}    ${valeur}
        ${saisi}=    Get Value    ${champ}
        IF    $saisi == $valeur    RETURN
        Log    Connexion : saisie non prise en compte dans le champ ${champ} (essai ${essai}/3), nouvelle tentative    level=WARN    console=True
        # Pas de pause fixe : on attend que le champ soit de nouveau visible (la fenêtre a fini de s'animer)
        Run Keyword And Ignore Error    Wait Until Element Is Visible    ${champ}    timeout=5s
    END
    Fail    Impossible de saisir la valeur dans le champ ${champ} de la fenêtre de connexion après 3 essais

# Ce mot-clé vérifie que la connexion a réussi
La connexion doit être confirmée
    ${connecte}=    Run Keyword And Return Status    Wait Until Element Is Not Visible    ${CONNEXION_CHAMP_EMAIL}    timeout=20s
    IF    not ${connecte}
        # Diagnostic : on relève le message d'erreur affiché par le site dans la fenêtre de connexion
        ${erreur_affichee}=    Run Keyword And Return Status    Element Should Be Visible    ${CONNEXION_ZONE_ERREUR}
        ${message_site}=    Set Variable    aucun message d'erreur affiché
        IF    ${erreur_affichee}
            ${message_site}=    Get Text    ${CONNEXION_ZONE_ERREUR}
        END
        Capture Page Screenshot
        Fail    La connexion n'a pas abouti après 20 secondes (fenêtre de connexion toujours affichée). Message du site : ${message_site}
    END
    Title Should Be    ${TITRE_TABLEAU_DE_BORD}

Se connecter en tant qu'hôte
    [Arguments]    ${email}    ${mot_de_passe}
    Log    Connexion en tant qu'hôte (propriétaire de l'annonce) : ${email}    console=True
    Se connecter en tant que voyageur    ${email}    ${mot_de_passe}

Se déconnecter
    Log    Déconnexion du compte courant    console=True
    Click Element    ${CONNEXION_MENU_UTILISATEUR}
    Wait Until Element Is Visible    ${CONNEXION_LIEN_SE_DECONNECTER}
    Click Element    ${CONNEXION_LIEN_SE_DECONNECTER}
    Wait Until Element Is Visible    ${CONNEXION_LIEN_SE_CONNECTER}    timeout=20s

# ---------- Changement de compte (étapes partagées par les tests) ----------
L'utilisateur se déconnecte puis l'hôte se connecte
    [Arguments]    ${email}=${HOTE_EMAIL}    ${mot_de_passe}=${HOTE_PASSWORD}
    Se déconnecter
    Se connecter en tant qu'hôte    ${email}    ${mot_de_passe}
    La connexion doit être confirmée

L'utilisateur se déconnecte puis le voyageur se connecte
    Se déconnecter
    Se connecter en tant que voyageur    ${VOYAGEUR_EMAIL}    ${VOYAGEUR_PASSWORD}
    La connexion doit être confirmée
