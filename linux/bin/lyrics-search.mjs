#!/usr/bin/env -S node --experimental-top-level-await --experimental-json-modules --experimental-import-meta-resolve --experimental-specifier-resolution=node

import fs from 'fs';
import path from 'path';
import childProcess from 'child_process';
import { createRequire } from 'module';


const require = createRequire(import.meta.url);

/**
 * Import the [isomorphic-fetch]{@link https://www.npmjs.com/package/isomorphic-fetch}
 * `fetch` polyfill for easy use in back-end scripts.
 */
await importGlobalModule('isomorphic-fetch');


/**
 * Imports a module by name, checking the local `node_modules/` directory first,
 * followed by the global one if it doesn't exist.
 *
 * This helps account for the fact that [global modules can't be imported]{@link https://stackoverflow.com/questions/7970793/how-do-i-import-global-modules-in-node-i-get-error-cannot-find-module-module}.
 * This function is only needed for MJS files when `NODE_PATH` isn't defined.
 * CJS files automatically include the global `node_modules/` regardless of the existence of `NODE_PATH`.
 *
 * @param {string} name - Module name to import.
 * @param {Object} [options]
 * @param {Boolean} [options.useRequire] - If `require` should be used instead of a dynamic `import` (will fallback to `require` if `import()` fails).
 * @return {any} - The resolved module.
 * @throws {ModuleNotFoundError} - If the module can't be found.
 */
async function importGlobalModule(packageName, {
    useRequire = false,
} = {}) {
    const nodeModulesPackageDirLocal = path.resolve(
        childProcess
            .execSync('npm root')
            .toString()
            .replace(/\n/g, ''),
        packageName,
    );
    const nodeModulesPackageDirGlobal = path.resolve(
        childProcess
            .execSync('npm root --global')
            .toString()
            .replace(/\n/g, ''),
        packageName,
    );

    let nodeModulesPackageDir = nodeModulesPackageDirLocal;

    if (!fs.existsSync(nodeModulesPackageDirLocal)) {
        nodeModulesPackageDir = nodeModulesPackageDirGlobal;
    }


    if (!useRequire) {
        try {
            return await import(nodeModulesPackageDir);
        } catch (moduleNotFoundOrModuleResolutionDoesntSupportDirectoryImports) {
            // Ignore, use `require` fallback below
        }
    }


    try {
        return require(nodeModulesPackageDir);
    } catch {
        throw new Error(`Module "${packageName}" could not be found in either "${nodeModulesPackageDirLocal}" or "${nodeModulesPackageDirGlobal}" directories.`)
    }
}


function getApiUrl(artist, song) {
    return `https://api.lyrics.ovh/v1/${artist}/${song}`;
}


export async function getLyrics(artist, song) {
    try {
        const res = await fetch(getApiUrl(artist, song));
        const json = await res.json();
        const { lyrics } = json;

        const asciiLyrics = lyrics
            .replace(/\r(?=\n)/g, '')  // CRLF => LF
            .replace(/[\u2018\u2019]/g, "'")  // Fancy apostrophe => normal
            .replace(/[\u201C\u201D]/g, '"')  // Fancy double-quote => normal
            .replace(/[\u2013\u2014]/g, "-")  // Fancy dashes => hyphens
            .replace(/\u2026/g, '...')
            .replace(/\n\n/g, '\n');  // Collapsed/single-character ellipses => normal

        return asciiLyrics;
    } catch (e) {
        console.error(
            `Could not obtain lyrics for artist "${artist}" and song "${song}"`,
            '\n',
            `Are you sure you spelled it correctly?`,
            '\n',
            e,
        );
    }
}


const thisFileUrl = import.meta.url;
const thisFilePath = new URL(thisFileUrl).pathname;
const thisFileName = path.basename(thisFilePath);

const isMain = !!process.argv?.[1]?.match(new RegExp(`${thisFileName}$`));

if (isMain) {
    const USAGE = `${thisFileName} '<artist>' '<song>'
    Gets the lyrics for the specified artist's song.
    Lyrics will be returned as an ASCII string, replacing all fancy single/double quotes,
    single-char ellipses, dashes, CRLF, etc. with their Unix/ASCII counterparts.

    If the artist or song have spaces in them, surround them with quotes.

    Requires npm-installing 'isomorphic-fetch' globally and setting \`NODE_PATH\` to that global
    \`node_modules\` directory, or placing this file in the directory of a JavaScript project
    that has installed it.

    Call the script directly, not from \`node\`. For example, call via
    \`./${thisFileName} Anberlin 'Feel Good Drag'\`
    but not
    \`node ./${thisFileName} Anberlin 'Feel Good Drag'\`
    `;

    const [
        nodePath,
        thisFile,
        artist,
        song,
    ] = process.argv;

    if (!artist || !song || (typeof fetch === typeof undefined)) {
        console.log(USAGE);

        process.exit(1);
    }

    console.log(await getLyrics(artist, song));
}
