# Registre d'applications

Ce dossier contient un lanceur local pour retrouver les applications et scripts que nous ajoutons ensemble.

## Carte d'identite

- Reference a donner a Codex pour retrouver cette application : `APP-HUB-REGISTRE-2026-04-24`
- Derniere mise a jour de l'application : `2026-06-02 09:20`
- Dossier local : `C:\Users\laure\Documents\Codex\2026-04-24\app-hub-registre-applications`
- Lanceur : `launch-app-hub.vbs`

Le registre accepte maintenant plusieurs origines :

- `codex` pour les applications developpees avec Codex,
- `gai-studio` pour les applications developpees avec Google AI Studio,
- `google-cloud` pour les services recenses depuis Google Cloud,
- `other` pour le reste.

Si l'auteur n'est pas `Moi`, il est affiche directement sur la carte de l'application.

## Ouvrir le registre

```powershell
.\open-app-hub.ps1
```

Le registre affiche :

- une zone de recherche,
- une carte par application,
- le tag d'origine et la categorie sur une meme ligne,
- l'auteur externe quand il existe,
- un bouton `Lancer` pour ouvrir un script local ou une URL d'application,
- un bouton `Voir source` pour ouvrir le script ou le projet Google Cloud,
- un bouton `Outils` qui regroupe `Ouvrir AI Studio` et `Synchroniser Google Cloud`,
- un bouton `?` pour lire cette notice depuis l'application,
- une case `Favoris` pour n'afficher que les applications favorites.

Chaque carte permet aussi de copier les informations de l'application. Le pictogramme a cote du nom copie uniquement la reference de l'application. Les descriptions et les chemins techniques sont selectionnables pour faciliter le copier-coller. Les favoris se pilotent avec la petite etoile en haut a droite de chaque carte ; l'etoile est un vrai bouton a etat, sauvegarde dans le registre, puis redessine la liste.

## Connexion Google

Le bouton `Ouvrir AI Studio` ouvre Google AI Studio dans le navigateur. La connexion se fait directement chez Google.

Le bouton `Synchroniser Google Cloud` utilise Google Cloud CLI (`gcloud`) :

1. si vous n'etes pas connectee, il lance `gcloud auth login`,
2. il liste les projets Google Cloud visibles pour votre compte,
3. il importe les services Cloud Run dans le registre.

Important : Google AI Studio stocke ses apps dans l'environnement Google et peut les deployer vers Cloud Run ou GitHub. A ce stade, la synchronisation automatique fiable se fait donc via les apps deployees sur Google Cloud, ou via un manifeste JSON. Pour identifier clairement une app AI Studio deployee sur Cloud Run, ajoutez un label :

```text
origin=gai-studio
```

Vous pouvez aussi ajouter :

```text
author=Nom
app=Nom application
```

## Ajouter une application locale

```powershell
.\register-app.ps1 `
  -Name "Mon outil" `
  -ScriptPath ".\mon-script.ps1" `
  -Description "Ce que fait l'outil." `
  -Category "Outils" `
  -Origin codex `
  -Author "Moi" `
  -Tags Codex,outil,test `
  -Arguments "-Mode rapide"
```

## Ajouter une application Google AI Studio

```powershell
.\register-app.ps1 `
  -Name "Assistant contrats" `
  -Description "Application creee avec Google AI Studio." `
  -Category "Applications IA" `
  -Origin gai-studio `
  -Author "Moi" `
  -Tags "GAI Studio",Gemini,Juridique `
  -AccessUrl "https://assistant-contrats.example.com" `
  -GoogleProject "mon-projet-google-cloud" `
  -CloudService "cloud-run/assistant-contrats"
```

## Importer depuis Google AI Studio ou Google Cloud

Preparez un manifeste JSON au format de `google-apps-manifest.example.json`, puis lancez :

```powershell
.\import-google-apps.ps1 -ManifestPath .\google-apps-manifest.example.json
```

Ce manifeste peut etre produit manuellement, depuis un inventaire Google Cloud, ou depuis des labels de services comme :

- `origin=gai-studio`,
- `author=Nom`,
- `app=<nom application>`.

Les applications sont stockees dans :

```text
.\apps-registry.json
```
