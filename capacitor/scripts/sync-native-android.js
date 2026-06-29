#!/usr/bin/env node
/**
 * Vendorise les sources Kotlin natives (cœur Android Pushproof) dans le module
 * Android du wrapper Capacitor.
 *
 * Pourquoi : un package Capacitor est extrait seul dans `node_modules` du
 * consommateur ; il ne peut pas dépendre d'un dossier frère du repo ni d'un
 * artefact Maven non publié. On copie donc le cœur natif (source unique :
 * `android/src/main/java/dev/pushproof/`) dans l'arbre publié du wrapper, à
 * chaque `prepack` (cf. package.json). Les copies sont gitignorées : la source
 * de vérité reste la lib native à la racine du repo.
 */
const fs = require('fs');
const path = require('path');

const FILES = [
  'PushproofCore.kt',
  'ReceiptSender.kt',
  'PushproofMessagingService.kt',
  'NotificationDisplay.kt',
  'AppForeground.kt',
  'CapacitorPushForwarder.kt',
];

const repoRoot = path.resolve(__dirname, '..', '..');
const srcDir = path.join(repoRoot, 'android', 'src', 'main', 'java', 'dev', 'pushproof');
const destDir = path.join(__dirname, '..', 'android', 'src', 'main', 'java', 'dev', 'pushproof');

const HEADER =
  '// AUTO-GÉNÉRÉ par scripts/sync-native-android.js — NE PAS ÉDITER.\n' +
  '// Source de vérité : android/src/main/java/dev/pushproof/ (racine du repo).\n\n';

fs.mkdirSync(destDir, { recursive: true });

let copied = 0;
for (const file of FILES) {
  const from = path.join(srcDir, file);
  const to = path.join(destDir, file);
  if (!fs.existsSync(from)) {
    console.error(`[sync-native-android] introuvable : ${from}`);
    process.exit(1);
  }
  fs.writeFileSync(to, HEADER + fs.readFileSync(from, 'utf8'));
  copied += 1;
}

console.log(`[sync-native-android] ${copied} fichiers vendorisés → capacitor/android/.../dev/pushproof/`);
