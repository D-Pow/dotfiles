#!/usr/bin/env -S node --experimental-top-level-await --experimental-json-modules --experimental-import-meta-resolve --experimental-specifier-resolution=node

import fs from 'fs';
import path from 'path';
import childProcess from 'child_process';
import { createRequire } from 'module';


const require = createRequire(import.meta.url);


/**
 * Imports a module by name, checking the local `node_modules/` directory first,
 * followed by the global one if it doesn't exist.
 *
 * This helps account for the fact that [global modules can't be imported]{@link https://stackoverflow.com/questions/7970793/how-do-i-import-global-modules-in-node-i-get-error-cannot-find-module-module}.
 * This function is only needed for MJS files when `NODE_PATH` doesn't include the global `node_modules/` dir.
 * CJS files automatically include the global `node_modules/` regardless of the existence of `NODE_PATH`.
 *
 * @param {string} name - Module name to import.
 * @param {Object} [options]
 * @param {Boolean} [options.useRequire] - If `require` should be used instead of a dynamic `import` (will fallback to `require` if `import()` fails).
 * @return {any} - The resolved module.
 * @throws {ModuleNotFoundError} - If the module can't be found.
 */
export async function importGlobalModule(packageName, {
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


const thisFileUrl = import.meta.url;
const thisFilePath = new URL(thisFileUrl).pathname;
const thisFileName = path.basename(thisFilePath);

const isMain = !!process.argv?.[1]?.match(new RegExp(`${thisFileName}$`));

if (isMain) {
    const USAGE = `\`import { X } from '${thisFileName}';\`
    Contains utils for importing packages installed globally, which isn't supported by default for
    ESM/MJS files.

    If \`NODE_PATH\` is set to the global \`node_modules\` directory, then \`module.createRequire()(pkg)\`
    would work, but not \`import 'pkg'\` nor \`await import(pkg)\`.
    Alternatively, if this file is included in the directory of a JavaScript project that has the
    package installed, then it'll work automatically.
    `;

    console.log(USAGE);

    process.exit(1);
}
