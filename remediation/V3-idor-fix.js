// ============================================================
// REMÉDIATION V3 — IDOR / Broken Access Control (CWE-284)
// Composant : /api/BasketItems/:id
// ============================================================

// ❌ CODE VULNÉRABLE
// L'ID du panier vient directement de l'URL fournie par le client
// Aucune vérification que ce panier appartient à l'utilisateur connecté
//
// ATTAQUE : utilisateur connecté avec son compte change l'ID dans l'URL
// /api/BasketItems/1  → voit le panier de l'utilisateur n°1
// /api/BasketItems/2  → voit le panier de l'utilisateur n°2
// etc.

const vulnerableBasketAccess = (req, res) => {
  const basketId = req.params.id; // ← vient du client, JAMAIS vérifié !
  
  console.log("ACCÈS AU PANIER ID:", basketId);
  console.log("PROBLÈME: aucune vérification de propriété !");
  
  // N'importe quel utilisateur peut accéder à n'importe quel panier
  // findAll({ where: { BasketId: basketId } })  ← DANGEREUX
};

// ✅ CODE CORRIGÉ
// On croise TOUJOURS l'ID demandé avec l'identité de l'utilisateur connecté
// L'identité vient du JWT signé côté serveur → ne peut pas être falsifiée

const secureBasketAccess = async (req, res, models) => {
  // 1. Qui est connecté ? → extrait du token JWT vérifié par le serveur
  const authenticatedUserId = req.user.data.id;
  
  // 2. Quel panier demande-t-il ?
  const requestedBasketId = req.params.id;
  
  console.log(`Utilisateur ${authenticatedUserId} demande le panier ${requestedBasketId}`);
  
  // 3. Vérification : ce panier appartient-il à cet utilisateur ?
  const basket = await models.Basket.findOne({
    where: {
      id: requestedBasketId,      // L'ID demandé
      UserId: authenticatedUserId  // DOIT correspondre à l'utilisateur connecté
    }
  });
  
  // 4. Si le panier n'existe pas OU n'appartient pas → refus
  if (!basket) {
    console.log("ACCÈS REFUSÉ: le panier n'appartient pas à cet utilisateur");
    return res.status(403).json({
      error: "Accès refusé : vous ne pouvez accéder qu'à votre propre panier"
    });
  }
  
  // 5. Seulement si la vérification passe → retourner les données
  console.log("ACCÈS AUTORISÉ: le panier appartient bien à l'utilisateur");
  const items = await models.BasketItem.findAll({
    where: { BasketId: requestedBasketId }
  });
  
  return res.json(items);
};

// ✅ MIDDLEWARE RÉUTILISABLE pour toutes les routes sensibles
const checkOwnership = (getUserIdFromResource) => {
  return async (req, res, next) => {
    const authenticatedUserId = req.user.data.id;
    const resourceUserId = await getUserIdFromResource(req.params.id);
    
    if (authenticatedUserId !== resourceUserId) {
      return res.status(403).json({ error: "Accès non autorisé" });
    }
    next(); // OK → continuer vers le handler
  };
};

// Simulation pour démonstration
console.log("=== DÉMONSTRATION CONTRÔLE D'ACCÈS ===");

const simulateRequest = (authenticatedUser, requestedBasketId, basketOwner) => {
  console.log(`\nUtilisateur connecté: ${authenticatedUser}`);
  console.log(`Panier demandé: ${requestedBasketId} (appartient à: ${basketOwner})`);
  
  if (authenticatedUser === basketOwner) {
    console.log("RÉSULTAT: ✅ ACCÈS AUTORISÉ");
  } else {
    console.log("RÉSULTAT: ❌ ACCÈS REFUSÉ (403 Forbidden)");
  }
};

simulateRequest("alice@test.com", "panier-1", "alice@test.com"); // OK
simulateRequest("alice@test.com", "panier-2", "bob@test.com");   // REFUSÉ
simulateRequest("hacker@test.com", "panier-1", "alice@test.com"); // REFUSÉ

module.exports = { secureBasketAccess, checkOwnership };