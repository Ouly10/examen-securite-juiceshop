#!/bin/bash
# ============================================================
# PARTIE 3 - Script de verification des remediations
# Examen Final Securite des Donnees - L3 Cybersecurite
# Lancer avec : bash remediation/verification-tests.sh
# ============================================================

BASE_URL="http://localhost:3000"
PASS=0
FAIL=0

echo "=========================================="
echo "  PARTIE 3 - TESTS DE VERIFICATION"
echo "  JUICE SHOP - REMEDIATIONS"
echo "=========================================="

# ── TEST V1 : SQL Injection ─────────────────────────────────
echo ""
echo "[V1] Test SQL Injection - /rest/user/login"
echo "     Payload utilise : ' OR 1=1--"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${BASE_URL}/rest/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"' OR 1=1--\",\"password\":\"x\"}")

if [ "$HTTP_CODE" = "401" ]; then
  echo "     RESULTAT : PASS - Injection bloquee (HTTP $HTTP_CODE)"
  PASS=$((PASS+1))
else
  echo "     RESULTAT : FAIL - Injection non bloquee (HTTP $HTTP_CODE)"
  echo "     VULNERABILITE CONFIRMEE - Juice Shop est vulnerable"
  FAIL=$((FAIL+1))
fi

# ── TEST V2 : XSS ───────────────────────────────────────────
echo ""
echo "[V2] Test XSS - Champ recherche"
echo "     Payload utilise : <script>alert('XSS')</script>"

RESPONSE=$(curl -s \
  "${BASE_URL}/rest/products/search?q=%3Cscript%3Ealert%28%27XSS%27%29%3C%2Fscript%3E")

if echo "$RESPONSE" | grep -q "script"; then
  echo "     RESULTAT : FAIL - XSS non filtre (script present dans reponse)"
  echo "     VULNERABILITE CONFIRMEE - Juice Shop est vulnerable"
  FAIL=$((FAIL+1))
else
  echo "     RESULTAT : PASS - XSS filtre ou encode"
  PASS=$((PASS+1))
fi

# ── TEST V3 : IDOR ──────────────────────────────────────────
echo ""
echo "[V3] Test IDOR - /api/BasketItems sans authentification"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "${BASE_URL}/api/BasketItems/1")

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
  echo "     RESULTAT : PASS - Acces refuse (HTTP $HTTP_CODE)"
  PASS=$((PASS+1))
else
  echo "     RESULTAT : FAIL - Acces non protege (HTTP $HTTP_CODE)"
  echo "     VULNERABILITE CONFIRMEE - Juice Shop est vulnerable"
  FAIL=$((FAIL+1))
fi

# ── TEST V4 : Exposition donnees ────────────────────────────
echo ""
echo "[V4] Test Exposition - /api/Users sans authentification"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "${BASE_URL}/api/Users")

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
  echo "     RESULTAT : PASS - API protegee (HTTP $HTTP_CODE)"
  PASS=$((PASS+1))
else
  echo "     RESULTAT : FAIL - API exposee (HTTP $HTTP_CODE)"
  echo "     VULNERABILITE CONFIRMEE - Juice Shop est vulnerable"
  FAIL=$((FAIL+1))
fi

# ── TEST V5 : Secrets ───────────────────────────────────────
echo ""
echo "[V5] Test Secrets - Verification .gitignore"

if grep -q ".env" ../.gitignore 2>/dev/null; then
  echo "     RESULTAT : PASS - .env present dans .gitignore"
  PASS=$((PASS+1))
else
  echo "     RESULTAT : FAIL - .env absent du .gitignore"
  FAIL=$((FAIL+1))
fi

# ── RESUME ──────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  PARTIE 3 - RESUME DES TESTS"
echo "  $PASS test(s) PASS / $((PASS+FAIL)) test(s) total"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
  echo "  Toutes les remediations sont effectives"
  exit 0
else
  echo "  $FAIL vulnerabilite(s) encore presente(s) sur Juice Shop"
  echo "  C'est NORMAL : on documente les vulnerabilites existantes"
  echo "  Les fichiers de remediation montrent comment les corriger"
  exit 0
fi