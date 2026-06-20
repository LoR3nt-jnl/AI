# Google Tasks → iCloud Reminders sync

Application Node.js/TypeScript qui synchronise uniquement les tâches Google Tasks préfixées par `iOS` vers l'application Rappels iCloud.

## Règles de synchronisation

- Seule la liste Google Tasks nommée `live session` est lue par défaut.
- Seules les tâches actives dont le titre commence par `iOS` sont envoyées vers Rappels.
- Exemple : `iOS prendre rdv chez le coiffeur - Maison`
  - titre créé dans Rappels : `prendre rdv chez le coiffeur`
  - liste Rappels cible : `Maison`
- Si aucune liste n'est indiquée après ` - `, la liste iCloud par défaut est utilisée.
- Si la liste demandée n'existe pas, l'application choisit la liste iCloud au nom le plus proche lorsque la distance est acceptable, sinon la liste par défaut.
- Les tâches déjà envoyées ne sont pas recréées : chaque rappel reçoit un marqueur `GOOGLE_TASK_ID` dans sa description.

## Configuration

1. Créer un client OAuth Google Desktop et télécharger le fichier sous `credentials.json`.
2. Créer un mot de passe spécifique à l'app pour iCloud.
3. Installer les dépendances :

```bash
npm install
```

4. Exporter les variables d'environnement :

```bash
export ICLOUD_USERNAME="votre-identifiant-icloud@example.com"
export ICLOUD_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export ICLOUD_DEFAULT_REMINDER_LIST="Reminders"
```

Variables optionnelles :

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `GOOGLE_TASK_LIST_NAME` | `live session` | Liste Google Tasks à lire |
| `TASK_PREFIX` | `iOS` | Préfixe déclenchant l'upload vers Rappels |
| `FUZZY_LIST_MAX_DISTANCE` | `3` | Distance de Levenshtein maximale pour accepter une liste proche |
| `GOOGLE_CREDENTIALS_PATH` | `credentials.json` | Chemin du client OAuth Google |
| `GOOGLE_TOKEN_PATH` | `token.json` | Cache OAuth local |
| `DRY_RUN` | `false` | Affiche les créations sans écrire dans iCloud |

## Utilisation

Premier lancement, pour autoriser Google Tasks :

```bash
npm run sync
```

Test sans écriture iCloud :

```bash
DRY_RUN=true npm run sync
```

Compilation :

```bash
npm run build
```
