#!/usr/bin/env node
/**
 * Aide à l'installation de la cible NSE iOS (SPEC §6) — BEST-EFFORT.
 *
 * Le format .xcodeproj est non documenté et fragile entre versions de Xcode.
 * Ce script NE patche PAS le projet de force : il vérifie les prérequis et
 * imprime la procédure officielle (manuelle). C'est le chemin supporté.
 *
 *   npx pushproof-install-nse
 */
const fs = require('fs');
const path = require('path');

const cwd = process.cwd();
const iosProject = path.join(cwd, 'ios', 'App', 'App.xcodeproj');
const pbxproj = path.join(iosProject, 'project.pbxproj');

function log(msg) { process.stdout.write(msg + '\n'); }
function ok(msg) { log('  ✅ ' + msg); }
function warn(msg) { log('  ⚠️  ' + msg); }

log('\nPushproof — assistant cible NSE iOS\n');

if (!fs.existsSync(pbxproj)) {
  warn("Projet iOS introuvable (ios/App/App.xcodeproj).");
  warn("Lancez d'abord `npx cap add ios`, puis relancez ce script.");
  process.exit(1);
}
ok('Projet iOS détecté.');

const project = fs.readFileSync(pbxproj, 'utf8');
const hasNSE = /PushproofNSE/.test(project) || /Notification Service Extension/i.test(project);
if (hasNSE) {
  ok('Une cible NSE semble déjà présente. Vérifiez les points ci-dessous.');
} else {
  warn("Aucune cible NSE détectée — à créer manuellement (procédure ci-dessous).");
}

const bundleId = detectBundleId(project);

log('\nProcédure (référence officielle, ~3 min dans Xcode) :\n');
log('  1. Xcode → File → New → Target → "Notification Service Extension"');
log('     Nom : PushproofNSE' + (bundleId ? `   Bundle id : ${bundleId}.nse` : ''));
log('  2. Remplacez le NotificationService.swift généré par :');
log('');
log('        import PushproofNSE');
log('        class NotificationService: PushproofNotificationService {}');
log('');
log('  3. Ajoutez le Swift Package "Pushproof" aux cibles App ET PushproofNSE :');
log('     File → Add Package Dependencies → URL du dépôt → produits');
log('     PushproofCore (App) et PushproofNSE (cible NSE).');
log('  4. Activez App Groups sur App ET PushproofNSE, MÊME groupe :');
log('     ' + (bundleId ? `group.${bundleId}` : 'group.<BUNDLE_ID>'));
log('  5. (NSE) Info.plist → clé "PushproofAppGroup" = ' + (bundleId ? `group.${bundleId}` : 'group.<BUNDLE_ID>'));
log('  6. Vérifiez que votre backend envoie bien "mutable-content": 1 (data-only).');
log('  7. Committez le dossier ios/ (ou rejouez ce script après chaque `cap add ios`).');
log('\nDétails : INSTALL-iOS-NSE.md\n');

function detectBundleId(proj) {
  const m = proj.match(/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/);
  if (!m) return null;
  let id = m[1].trim().replace(/"/g, '');
  // ignore les variantes de test
  if (id.includes('$(')) return null;
  return id;
}
