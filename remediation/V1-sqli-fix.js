// ============================================================
// REMÉDIATION V1 — SQL Injection (CWE-89)
// Composant : /rest/user/login
// ============================================================

// ❌ CODE VULNÉRABLE — Ce qui existe dans Juice Shop
// L'entrée utilisateur est collée directement dans la requête SQL
// Payload d'attaque : email = ' OR 1=1--
// Résultat : connexion sans mot de passe, accès admin

const vulnerableLogin = (email, password) => {
  const query = "SELECT * FROM Users WHERE email = '" 
                + email 
                + "' AND password = '" 
                + password + "'";
  // Si email = ' OR 1=1--
  // La requête SQL devient :
  // SELECT * FROM Users WHERE email = '' OR 1=1--' AND password = '...'
  // OR 1=1 est toujours VRAI → tous les comptes sont retournés
  // Le -- met en commentaire le reste → le mot de passe est ignoré
  console.log("REQUÊTE GÉNÉRÉE (DANGEREUSE) :", query);
  return query;
};

// Démonstration du problème
console.log("=== DÉMONSTRATION VULNÉRABILITÉ ===");
console.log(vulnerableLogin("' OR 1=1--", "nimportequoi"));
console.log("");

// ✅ CODE CORRIGÉ — Requêtes paramétrées
// Le ? est un placeholder : l'entrée utilisateur est TOUJOURS traitée comme donnée
// Jamais comme du code SQL — même si elle contient ' OR 1=1--

const secureLoginQuery = (email, password) => {
  // La requête SQL avec des placeholders (?)
  const query = "SELECT * FROM Users WHERE email = ? AND password = ?";
  
  // Les valeurs sont passées SÉPARÉMENT, jamais concaténées
  const params = [email, password];
  
  console.log("REQUÊTE SÉCURISÉE :", query);
  console.log("PARAMÈTRES (traités comme données) :", params);
  
  // Le driver SQL envoie la requête et les paramètres séparément
  // Même si email = ' OR 1=1--, c'est cherché littéralement dans la BDD
  // Aucun utilisateur n'a cet email → résultat vide → 401 Unauthorized
  return { query, params };
};

console.log("=== DÉMONSTRATION CORRECTION ===");
console.log(secureLoginQuery("' OR 1=1--", "nimportequoi"));
console.log("");

// ✅ AVEC SEQUELIZE ORM (la vraie correction dans Juice Shop)
// Sequelize génère automatiquement des requêtes paramétrées
/*
const secureLoginORM = async (email, password, models) => {
  const user = await models.User.findOne({
    where: {
      email: email,       // Sequelize paramétrise automatiquement
      password: password
    }
  });
  
  if (!user) {
    throw new Error('Identifiants incorrects'); // 401
  }
  return user;
};
*/

// ✅ VALIDATION DES ENTRÉES (défense en profondeur)
const validateInput = (email, password) => {
  const errors = [];
  
  // Vérifier format email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    errors.push("Format email invalide");
  }
  
  // Vérifier mot de passe non vide
  if (!password || password.trim().length === 0) {
    errors.push("Mot de passe requis");
  }
  
  // Bloquer les patterns SQL dangereux (couche supplémentaire)
  const dangerousPatterns = /('|--|;|DROP|INSERT|UPDATE|DELETE|UNION)/i;
  if (dangerousPatterns.test(email) || dangerousPatterns.test(password)) {
    errors.push("Caractères non autorisés détectés");
  }
  
  return errors;
};

console.log("=== TEST VALIDATION ===");
console.log("Email valide :", validateInput("test@email.com", "pass123"));
console.log("Attaque SQL :", validateInput("' OR 1=1--", "x"));

module.exports = { secureLoginQuery, validateInput };