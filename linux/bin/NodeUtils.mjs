#!/usr/bin/env -S node --no-warnings --experimental-top-level-await --experimental-json-modules --experimental-import-meta-resolve --experimental-specifier-resolution=node

import fs from 'node:fs';
import path from 'node:path';
import util from 'node:util';
import childProcess from 'node:child_process';
import { createRequire } from 'node:module';


const require = createRequire(import.meta.url);

/**
 * Silence NodeJS warnings for experimental flags.
 * @see [GitHub discussion]{@link https://github.com/nodejs/node/issues/30810}
 */
// const emitOrig = process.emit;
// process.emit = function (name, data, ...args) {
//     if (
//         name?.match(/warning/i)
//         && (
//             data?.name?.match?.(/ExperimentalWarning/i)
//             || data?.match?.(/ExperimentalWarning/i)
//         )
//     ) {
//         return false;
//     }
//
//     return emitOrig.apply(name, data, ...args);
// }


export function log(...args) {
    if (args.length <= 1 && typeof args[0] !== typeof {}) {
        console.log(args[0]);

        return;
    }

    const stringsToLog = args.map(arg => (
        util.inspect(arg, {
            showHidden: true,
            depth: null,
            colors: true,
        })
    ));

    console.log(...stringsToLog);
}


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


/**
 * Runs a command in the shell of choice.
 *
 * Note:
 *
 * `node:child_process.spawn()` runs a (parsed) command string directly, without buffering output,
 * without spawning a shell before that process (though it can if desired).
 * `node:child_process.exec()` runs a command string within a spawned shell, buffering output (1 MB max).
 * This means `exec()` will wait for the process to complete before returning output whereas
 * `spawn()` will allow you to handle output as it is emitted.
 *
 * Generally, `exec()` should be used for short processes and `spawn()` should be used for
 * longer processes due to its ability to stream output to STD(IN|OUT|ERR).
 *
 * Both default to using `/bin/sh` on Unix. This means that if the user's default SHELL
 * isn't `sh`, then many executables (e.g. `node`, `npm`, etc.) won't be on `$PATH`.
 * In both functions, we can specify the shell to use for the executed command, allowing
 * the appropriate env config files (e.g. .bashrc, .zshrc, .profile, etc.) to be sourced first
 * and the aforementioned executables/aliases will be applied.
 * For example, it is necessary to specify a different shell than `/bin/sh` if running commands
 * within an IDE that is started with  a non-login shell or if node/npm are defined in .profile
 * instead of .bashrc (e.g. JetBrains IDEs background processes like ESLint).
 * Likewise, this ensures PATH is inherited, which doesn't always happen by default.
 *
 * @param {string} cmd - Command to run.
 * @param {Object} [options]
 * @param {boolean} [options.runInShell] - If a shell should be spawned before running the command.
 * @param {string} [options.shellToUse] - Specific shell to use (defaults to the `$SHELL` env var, falling back is Bash).
 * @param {boolean} [options.inheritEnv] - If the env vars should be inherited or not.
 * @return {string} - STDOUT of command.
 *
 * @see [`spawn()` vs `exec()`]{@link https://stackoverflow.com/questions/48698234/node-js-spawn-vs-execute}
 * @see [PATH not inherited by `spawn`]{@link https://github.com/nodejs/node/issues/12986#issuecomment-300951831}
 * @see [`sh error: Executable not found` (node, npm, git, etc.)]{@link https://stackoverflow.com/questions/27876557/node-js-configuring-node-path-with-nvm}
 * @see [ENOENT issue with WebStorm]{@link https://youtrack.jetbrains.com/issue/WEB-25141}
 * @see [Debugging ENOENT]{@link https://stackoverflow.com/questions/27688804/how-do-i-debug-error-spawn-enoent-on-node-js}
 * @see [Related WebStorm issue with `git` not found]{@link https://youtrack.jetbrains.com/issue/WI-63428}
 * @see [Related WebStorm issue with `node` not found on WSL]{@link https://youtrack.jetbrains.com/issue/WEB-22794}
 * @see [WebStorm using wrong directory for ESLint]{@link https://youtrack.jetbrains.com/issue/WEB-47258}
 * @see [Related WebStorm ESLint issue for finding root directory]{@link https://youtrack.jetbrains.com/issue/WEB-45381#focus=Comments-27-4342029.0-0}
 */
export function runCmd(cmd, {
    runInShell = true,
    shellToUse = '',
    inheritEnv = true,
} = {}) {
    // `__dirname` doesn't exist in Node ESM, so use `process.cwd()` instead.
    const cwd = process.cwd();
    // Default to using the a more advanced shell than `/bin/sh`.
    const defaultShell = process.env.SHELL || '/bin/bash';
    const shell = shellToUse || defaultShell;
    // Set `env` to undefined if not inheriting from parent.
    // Super short-hand for `inheritEnv ? obj : undefined`
    const env = (inheritEnv || undefined) && {
        PATH: process.env.PATH,
    };

    let stdout = '';

    if (runInShell) {
        stdout = childProcess
            .execSync(cmd, {
                shell,
                cwd,
                env,
            })
            .toString();
    } else {
        stdout = childProcess
            .spawnSync(cmd, {
                shell,
                cwd,
                env,
            })
            .stdout
            .toString();
    }

    // Remove trailing newline
    stdout = stdout.replace(/\n$/g, '');

    return stdout;
}
// console.log(runCmd(`bash -lc 'printpath'`, { runInShell: false }));
// console.log(runCmd(`printpath`, { runInShell: false }));
// console.log(runCmd(`echo $0`, { runInShell: true }));
// console.log(runCmd(`echo $PATH`, { runInShell: false }));


function copyToClipboard(str) {
    const osInfo = childProcess
        .execSync('uname -a')
        .toString()
        .replace(/\n/g, '');

    let copyCommand;
    let pasteCommand;

    if (!osInfo || osInfo.match(/not recognized as an internal or external command/i) || osInfo.match(/^MSYS_/i)) {
        // Windows Command Prompt or Powershell
        copyCommand = 'C:\Windows\System32\cmd.exe /C clip';
        pasteCommand = 'C:\Windows\System32\cmd.exe /C powershell Get-Clipboard'
    } else if (osInfo.match(/microsoft/i)) {
        // Windows WSL
        copyCommand = '/mnt/c/Windows/System32/cmd.exe /C clip';
        pasteCommand = '/mnt/c/Windows/System32/cmd.exe /C powershell Get-Clipboard';
    } else if (osInfo.match(/^MINGW/i)) {
        // Windows Git Bash
        copyCommand = 'clip';
        pasteCommand = 'powershell Get-Clipboard';
    } else if (osInfo.match(/mac|darwin|osx/i)) {
        // Mac
        copyCommand = 'pbcopy';
        pasteCommand = 'pbpaste';
    } else {
        // Linux
        const xclipPath = childProcess
            .execSync('which xclip')
            .toString()
            .replace(/\n/g, '');

        if (xclipPath) {
            // xclip is a user-friendly util for managing the clipboard, but isn't installed by default
            copyCommand = 'xclip -sel clipboard';
            pasteCommand = 'xclip -sel clipboard -o';
        } else {
            copyCommand = 'xsel --clipboard -i';
            pasteCommand = 'xsel --clipboard -0';
        }
    }

    if (copyCommand) {
        const commandToExecute = `echo "${str}" | ${copyCommand}`;

        return childProcess
            .execSync(commandToExecute)
            .toString()
            .replace(/\n/g, '');
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
