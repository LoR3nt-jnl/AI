# Extension Chrome : Lecture de sélection (FR)

Cette extension lit **en français** le texte sélectionné dans l'onglet actif grâce à l'API `chrome.tts`.

## Installation (mode développeur)

1. Ouvrez `chrome://extensions`.
2. Activez le mode développeur.
3. Cliquez sur **Charger l'extension non empaquetée**.
4. Sélectionnez ce dossier (`/workspace/AI`).

## Utilisation

1. Sur une page web, sélectionnez un texte.
2. Cliquez sur l'icône de l'extension.
3. Cliquez sur **🔊 Lire en français**.

## Fichiers

- `manifest.json` : déclaration de l'extension (Manifest V3).
- `popup.html` : interface du popup.
- `popup.css` : styles du popup.
- `popup.js` : récupération de la sélection et lecture TTS en `fr-FR`.
