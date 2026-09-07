#!/bin/bash
# ============================================================
# Script de vérification des remédiations
# Lancer avec : bash remediation/verification-tests.sh
# ============================================================

BASE_URL="http://localhost:3000"
PASS=0
FAIL=0

echo "======================================"
echo "  TESTS DE VÉRIFICATION — JUICE SHOP"
echo "======================================"

# ── TEST 1 : SQL Injection ──────────────────────────────────
echo ""
echo "[TEST 1] SQL Injection sur /rest/user/login"
echo "  Payload : ' OR 1=1--"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${BASE_URL}/rest/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"' OR 1=1--\",\"password\":\"x\"}")

if [ "$HTTP_CODE" = "401" ]; then
  echo "  RÉSULTAT : ✅ PASS — Injection bloquée (HTTP $HTTP_CODE)"
  PASS=$((PASS+1))
else
  echo "  RÉSULTAT : ❌ FAIL — Injection NON bloquée (HTTP $HTTP_CODE)"
  FAIL=$((FAIL+1))
fi

# ── TEST 2 : XSS ────────────────────────────────────────────
echo ""
echo "[TEST 2] XSS sur le champ recherche"
echo "  Payload : <script>alert('XSS')</script>"

RESPONSE=$(curl -s "${BASE_URL}/rest/products/search?q=%3Cscript%3Ealert%28%27XSS%27%29%3C%2Fscript%3E")

if echo "$RESPONSE" | grep -q "<script>"; then
  echo "  RÉSULTAT : ❌ FAIL — XSS non filtré (script tag présent dans la réponse)"
  FAIL=$((FAIL+1))
else
  echo "  RÉSULTAT : ✅ PASS — XSS filtré ou encodé"
  PASS=$((PASS+1))
fi

# ── TEST 3 : Exposition API utilisateurs ────────────────────
echo ""
echo "[TEST 3] Exposition données /api/Users (sans authentification)"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "${BASE_URL}/api/Users")

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
  echo "  RÉSULTAT : ✅ PASS — API protégée (HTTP $HTTP_CODE)"
  PASS=$((PASS+1))
else
  echo "  RÉSULTAT : ❌ FAIL — API non protégée (HTTP $HTTP_CODE)"
  FAIL=$((FAIL+1))
fi

# ── RÉSUMÉ ──────────────────────────────────────────────────
echo ""
echo "======================================"
echo "  RÉSUMÉ : $PASS PASS / $((PASS+FAIL)) TESTS"
echo "======================================"

if [ $FAIL -eq 0 ]; then
  echo "  ✅ Tous les tests passent !"
  exit 0
else
  echo "  ❌ $FAIL test(s) échoué(s) — vulnérabilités encore présentes"
  exit 1
fi