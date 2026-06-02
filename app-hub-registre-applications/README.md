# Registre d'applications

Application Windows locale PowerShell/WPF pour recenser et lancer des applications developpees avec Codex, Google AI Studio ou publiees sur Google Cloud.

## Reference

`APP-HUB-REGISTRE-2026-04-24`

## Contenu publie

- `open-app-hub.ps1` : interface WPF du registre.
- `launch-app-hub.vbs` : lanceur Windows portable.
- `apps-registry.json` : registre de depart, sans URL Cloud Run personnelle publiee.
- `sync-google-cloud-apps.ps1` : synchronisation Cloud Run via Google Cloud CLI.
- `import-google-apps.ps1` : import depuis un manifeste JSON.
- `register-app.ps1` : ajout manuel d'une application.
- `download-miro-invoices.ps1` : outil local inscrit dans le registre.

## Non publie volontairement

- `miro-invoices/` : dossiers generes pouvant contenir des factures ou brouillons d'email.
- Les URL Cloud Run locales deja synchronisees sur votre poste : elles se regenerent avec `Synchroniser Google Cloud`.
- L'icone Windows locale, pour garder une publication texte simple via le connecteur GitHub.

## Lancement local

Depuis le dossier clone ou telecharge :

```powershell
wscript.exe ".\launch-app-hub.vbs"
```

Voir aussi `README-app-hub.md`.
