'use strict';
// Links Pathwise/ into the game's AddOns folder, so a /reload in game picks up
// code changes. The folder comes from $WOW_FOREVER_ADDONS or --dest <dir>.
// An existing AddOns/Pathwise that is a link is replaced; a real folder there
// is never touched (move it away yourself first).
// Run: node tools/link.js [--dest <AddOns folder>]

const fs = require('node:fs');
const path = require('node:path');

const args = process.argv.slice(2);
const i = args.indexOf('--dest');
const dest = i >= 0 ? args[i + 1] : process.env.WOW_FOREVER_ADDONS;
if (!dest || !fs.existsSync(dest) || !fs.statSync(dest).isDirectory()) {
	console.error('No AddOns folder: set WOW_FOREVER_ADDONS or pass --dest <...\\Interface\\AddOns>');
	process.exit(1);
}

const src = path.resolve(__dirname, '..', 'Pathwise');
const target = path.join(dest, 'Pathwise');
let st = null;
try { st = fs.lstatSync(target); } catch { /* not there */ }
if (st && !st.isSymbolicLink()) {
	console.error(`${target} is a real folder, not a link; move it away first.`);
	process.exit(1);
}
if (st) fs.unlinkSync(target);
fs.symlinkSync(src, target, 'dir');
console.log(`linked ${target} -> ${src}`);
