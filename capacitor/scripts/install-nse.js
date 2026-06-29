#!/usr/bin/env node
/**
 * Aide à l'installation de la cible NSE iOS — BEST-EFFORT.
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
const hasNSE = /PushproofNotificationExtension/.test(project)
  || /Notification Service Extension/i.test(project);
if (hasNSE) {
  ok('Une cible NSE semble déjà présente. Vérifiez les points ci-dessous.');
} else {
  warn("Aucune cible NSE détectée — à créer manuellement (procédure ci-dessous).");
}

const bundleId = detectBundleId(project);
const appGroup = bundleId ? `group.${bundleId}` : 'group.<BUNDLE_ID>';

log('\nProcédure (référence officielle, ~3 min dans Xcode) :\n');
log('  1. Xcode → File → New → Target → "Notification Service Extension"');
log('     Nom : PushproofNotificationExtension (PAS "PushproofNSE" — conflit SPM)');
if (bundleId) log(`     Bundle id suggéré : ${bundleId}.nse`);
log('  2. Remplacez le NotificationService.swift généré par :');
log('');
log('        import PushproofNSE');
log('        class NotificationService: PushproofNotificationService {}');
log('');
log('  3. Ajoutez le Swift Package Pushproof (https://github.com/csurbier/pushproofsdk) :');
log('     PushproofCore → cible App, PushproofNSE (produit SPM) → extension.');
log('  4. Activez App Groups sur App ET extension, MÊME groupe :');
log(`     ${appGroup}`);
log(`  5. (extension) Info.plist → clé "PushproofAppGroup" = ${appGroup} (à la racine, pas dans NSExtension)`);
log('  6. Backend iOS : notification visible (alert) + "mutable-content": 1 dans APNs.');
log('     (Android reste data-only — voir pushproof.dev/docs/#payload-android)');
log('  7. Committez le dossier ios/ (ou rejouez ce script après chaque `cap add ios`).');
log('\nGuide complet : https://pushproof.dev/docs/#ios-nse\n');

function detectBundleId(proj) {
  const m = proj.match(/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/);
  if (!m) return null;
  let id = m[1].trim().replace(/"/g, '');
  if (id.includes('$(')) return null;
  return id;
}
