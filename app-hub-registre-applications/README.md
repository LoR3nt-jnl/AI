# App Hub Registre Applications

Application Windows locale PowerShell/WPF pour recenser et lancer des applications developpees avec Codex, Google AI Studio ou publiees sur Google Cloud.

## Reference

`APP-HUB-REGISTRE-2026-04-24`

## Contenu publie

- `open-app-hub.ps1` : interface WPF du registre.
- `apps-registry.json` : registre des applications.
- `sync-google-cloud-apps.ps1` : synchronisation Cloud Run via Google Cloud CLI.
- `import-google-apps.ps1` : import depuis un manifeste JSON.
- `register-app.ps1` : ajout manuel d'une application.
- `download-miro-invoices.ps1` : outil local inscrit dans le registre.

Les fichiers generes sous `miro-invoices/` ne sont pas publies car ils peuvent contenir des factures ou brouillons d'email.

## Lancement local

```powershell
wscript.exe ".\launch-app-hub.vbs"
```

Voir aussi `README-app-hub.md`.
