# Remédiation V5 — Secrets exposés (CWE-798)

## Problème identifié

Des clés secrètes (JWT, base de données, API) sont écrites
directement dans les fichiers de configuration versionnés sur Git.
Toute personne ayant accès au dépôt peut lire ces secrets et
usurper l'identité de l'application ou accéder à la base de données.

## Fichier vulnérable trouvé dans Juice Shop

Dans le fichier config/default.yml de Juice Shop, on trouve :

    secrets:
      jwtSecret: "s3cr3t_k3y_hardcoded_12345"
      cookieSecret: "my-cookie-secret"

Ces valeurs sont visibles par quiconque accède au code source.
Si la clé JWT est connue, un attaquant peut forger un token
d'administrateur et accéder à tout le système sans identifiant.

---

## Remédiation appliquée

### Principe

Ne jamais écrire une valeur secrète directement dans le code.
Les secrets doivent vivre dans des variables d'environnement,
dans un fichier .env qui n'est JAMAIS envoyé sur Git.

### Étape 1 — Créer le fichier .env à la racine du projet

Ce fichier contient les vraies valeurs secrètes.
Il ne sera jamais sur GitHub grâce au .gitignore.

    JWT_SECRET=une_longue_chaine_aleatoire_impossible_a_deviner
    DB_PASSWORD=MotDePasseComplexe2024!
    COOKIE_SECRET=autre_chaine_aleatoire

### Étape 2 — Ajouter .env au fichier .gitignore

    .env
    .env.local
    .env.production
    config/local.yml

Cela empêche Git d'envoyer le fichier .env sur GitHub.

### Étape 3 — Lire les secrets dans le code via process.env

Au lieu d'écrire la valeur en dur, le code la lit
depuis les variables d'environnement :

    require('dotenv').config();

    const jwtSecret = process.env.JWT_SECRET;

    if (!jwtSecret) {
      throw new Error('ERREUR : JWT_SECRET non défini !');
    }

Ainsi le code source ne contient aucune valeur secrète.

### Étape 4 — Vérifier avec Gitleaks

    docker run --rm -v ${PWD}:/path \
      zricethezav/gitleaks:latest \
      detect --source=/path --exit-code=0

Résultat attendu : leaks found: 0

---

## Comparaison Avant / Après

Situation AVANT :
- Le fichier config/default.yml contient jwtSecret en clair
- Ce fichier est sur GitHub
- N'importe qui peut lire la clé et forger un token admin
- Risque : compromission totale de l'application

Situation APRES :
- Le fichier .env contient les secrets
- Le fichier .env est dans .gitignore
- Le fichier .env n'apparait jamais sur GitHub
- Le code lit les secrets via process.env.JWT_SECRET
- Risque : quasi nul si le serveur est bien protégé

---

## Vérification finale

- Gitleaks retourne 0 secrets detectes
- Le fichier .env est bien listé dans .gitignore
- Le fichier .env n'apparait pas sur GitHub
- L'application demarre correctement avec les variables d'environnement
- Aucune valeur secrete n'est visible dans le code source

---

## Pourquoi cette correction est efficace

Les variables d'environnement sont locales au serveur ou
à la machine du développeur. Elles ne sont jamais versionnées.
Même si le dépôt Git est rendu public par erreur, aucun secret
n'est exposé car ils ne sont tout simplement pas dans le code.
C'est la pratique recommandée par OWASP et le standard
"Twelve-Factor App" pour la gestion des secrets applicatifs.