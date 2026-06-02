# Script local pour recuperer les factures Miro

Le script `download-miro-invoices.ps1` ouvre la page de facturation Miro, demande depuis quelle date il faut recuperer les factures, puis copie les nouveaux PDF dans un dossier propre.

Il peut ensuite preparer un message Gmail avec le destinataire, le sujet et le texte pre-remplis. Le script ouvre aussi le dossier des PDF pour les ajouter en pieces jointes.

## Utilisation

Depuis ce dossier, lancez :

```powershell
.\download-miro-invoices.ps1
```

Le script demande la date de depart au format `AAAA-MM-JJ`, par exemple `2025-12-01`.

## Exemples

Factures depuis le 1er decembre 2025 :

```powershell
.\download-miro-invoices.ps1 -FromDate 2025-12-01
```

Factures depuis le 1er decembre 2025 et email pre-rempli :

```powershell
.\download-miro-invoices.ps1 -FromDate 2025-12-01 -EmailTo "adresse@example.com"
```

Sans etape Gmail :

```powershell
.\download-miro-invoices.ps1 -FromDate 2025-12-01 -SkipGmail
```

Avec l'article d'aide Miro ouvert en plus :

```powershell
.\download-miro-invoices.ps1 -OpenHelp
```

## Resultat

Les fichiers recuperes sont copies dans :

```text
.\miro-invoices\depuis-AAAA-MM-JJ\
```

Exemple :

```text
.\miro-invoices\depuis-2025-12-01\
```

## Limites

- Le script n'utilise pas d'API Miro officielle pour les factures.
- Il vous laisse faire la connexion Miro et le telechargement dans la page `Billing History`.
- Il repere les PDF de facture telecharges apres son lancement, puis les rassemble au meme endroit.
- Pour des raisons de securite du navigateur, Gmail web ne permet pas a un script local d'attacher automatiquement des fichiers. Le script ouvre le dossier des PDF pour les joindre manuellement.
- Le script sauvegarde aussi `gmail-draft-request.json` dans le dossier de sortie. Codex peut l'utiliser pour creer un brouillon Gmail avec pieces jointes via le connecteur Gmail.
