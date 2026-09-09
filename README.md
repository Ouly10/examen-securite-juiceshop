# Examen Final — Sécurité des Données
## Application analysée : OWASP Juice Shop
**Auteur** : Ton Prénom NOM
**Formation** : Licence 3 Cybersécurité
**Date** : 2024

---

## Prérequis
- Docker Desktop installé et démarré
- Jenkins accessible sur http://localhost:8080
- Node.js 18+
- Git

---

## Lancer l'application Juice Shop

```bash
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```

Accéder à : http://localhost:3000

---

## Lancer les analyses manuellement

### SAST (Semgrep)
```bash
semgrep scan --config=p/owasp-top-ten --json .
```

### DAST (OWASP ZAP)
```bash
zap-baseline.py -t http://localhost:3000 -r reports/zap-report.html -I
```

### SCA (npm audit)
```bash
npm audit --json > reports/npm-audit-report.json
```

### Secret Detection (Gitleaks)
```bash
gitleaks detect --source=. --report-format=json
```

---

## Pipeline Jenkins

1. Démarrer Jenkins : http://localhost:8080
2. Ouvrir le job `examen-securite-juiceshop`
3. Cliquer **"Lancer un build"**
4. Les rapports sont dans **"Artifacts"** après le build

---

## Outils utilisés

| Outil | Type | Ce qu'il détecte |
|-------|------|-----------------|
| Semgrep | SAST | SQLi, XSS, mauvaises pratiques |
| OWASP ZAP | DAST | XSS, headers manquants, CSRF |
| npm audit | SCA | CVE dans les dépendances npm |
| Gitleaks | Secret Detection | Mots de passe, clés API |

---

## Structure du projet

---

## Vulnérabilités identifiées

| ID | Vulnérabilité | CWE | Sévérité |
|----|--------------|-----|----------|
| V1 | SQL Injection | CWE-89 | Critical |
| V2 | XSS | CWE-79 | High |
| V3 | IDOR | CWE-284 | High |
| V4 | Data Exposure | CWE-200 | High |
| V5 | Secrets exposés | CWE-798 | Critical |
| V6 | Auth faible | CWE-640 | Medium |
| V7 | Dépendances vulnérables | CWE-1035 | High |

---

## Décision de déploiement

**REJECT DEPLOYMENT** — 2 vulnérabilités Critical non corrigées