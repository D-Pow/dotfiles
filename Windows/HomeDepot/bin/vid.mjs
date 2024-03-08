#!/usr/bin/env node

import childProcess from 'node:child_process';


function copyToClipboard(str) {
    const osInfo = childProcess
        .execSync('uname -a')
        .toString()
        .replace(/\n/g, '');

    let copyCommand;
    let pasteCommand;

    if (!osInfo || osInfo.match(/microsoft/i) || osInfo.match(/not recognized as an internal or external command/i)) {
        // Windows WSL or Command Prompt
        copyCommand = '/mnt/c/Windows/System32/cmd.exe /C clip';
        pasteCommand = '/mnt/c/Windows/System32/cmd.exe /C powershell Get-Clipboard';
    } else if (osInfo.match(/^mingw/i)) {
        // Windows Git Bash
        copyCommand = '/c/Windows/System32/cmd /C clip';
        pasteCommand = '/c/Windows/System32/cmd.exe /C powershell Get-Clipboard';
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



const hmacCreationTime = Date.now();

const users = {
    'b2btestperksstaguser216@mailinator.com': {
        password: 'Test54321',
        userId: '042050999502B2280U',
        svocId: '0420509994FAB2280S',
        pids: [ 'P125216B44975E7F80', 'P12521CD063DAE7F80', 'P124B5F12A9F970620' ],
    },
    'b2btestperksstaguser209@mailinator.com': {
        password: 'Test1234',
        userId: '04201FA82A72E8F40U',
        svocId: '04201FA82A6668F40S',
        pids: [ 'P125216B44975E7F80' ],
    },
    'b2btestperksstaguser187@mailinator.com': {
        password: 'Test@1234',
        userId: '041FD225FD3F55380U',
        svocId: '041FD225FD33D5380S',
        pids: [ 'P125216B44975E7F80' ],
    },
    'b2btest50@gmail.com': {
        password: 'testqa01',
        userId: '041F59C53417BB670U',
        svocId: '041F59C5340DBB670S',
        pids: [ 'P125216B44975E7F80' ],
    },
};



function headersToObj(headersEntriesArray) {
    return headersEntriesArray.reduce((headersObj, [ key, val ]) => {
        if (key.match(/(set-)?cookie/i)) { // or Headers.prototype.getSetCookie()
            const [ newCookieKeyVal, ...newCookieConfigs ] = val.split(';');
            const [ newCookieKey, ...newCookieVals ] = newCookieKeyVal.split('=');
            const newCookieConfig = newCookieConfigs.join(';');
            const cookie = {
                ...headersObj[key],
                ...headersObj.cookie,
                // [newCookieKey]: `${newCookieVals.join('=')};${newCookieConfig}`,
                [newCookieKey]: newCookieVals.join('='),
            };

            headersObj.cookie = cookie;

            return headersObj;
        }

        if (key in headersObj) {
            if (Array.isArray(headersObj[key])) {
                headersObj[key].push(val);
            } else {
                headersObj[key] = [ headersObj[key], val ];
            }
        } else {
            headersObj[key] = val;
        }

        return headersObj;
    }, {});
}


async function hdFetch(url, opts, {
    domain = 'https://hd-qa74.homedepotdev.com',
} = {}) {
    const cookies = opts?.headers?.Cookie;

    delete opts?.headers?.Cookie;

    url = `${domain}${url}`;
    opts = {
        ...opts,
        headers: {
            ...opts?.headers,
            Origin: domain,
            Referer: url,
            'User-Agent': 'neoload',
        },
    };

    opts.headers = new Headers(opts?.headers);

    Object.entries(cookies ?? {})
        .forEach(([ key, val ]) => {
            opts.headers.append('Cookie', `${key}=${val}`);
        });

    const res = await fetch(url, opts);
    const headers = headersToObj([ ...res.clone().headers.entries() ]);
    const body = await (res.clone()).json();

    return {
        res,
        headers,
        body,
    };
}


async function getHmacToken() {
    return await hdFetch('/customer/account/v1/auth/getauthtoken', {
        headers: {
            timestamp: hmacCreationTime,
            clientId: 'clientId',
        },
    });
}


async function signIn(email, password, {
    logErrors = false,
} = {}) {
    password = password ?? users[email]?.password;

    const { headers, body: { clientAuthToken }} = await getHmacToken();
    const headersToPersistBetweenRequests = {
        'cust-acct-client-token': clientAuthToken,
        'cust-acct-client-timestamp': hmacCreationTime,
        'cust-acct-client-id': 'clientId',
        'cust-acct-client-delay-token-validation': '444444',
    };

    let res;

    try {
        res = await hdFetch('/customer/auth/v1/signin', {
            method: 'POST',
            headers: {
                ...headersToPersistBetweenRequests,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                channelId: 1,
                Cookie: headers?.cookie,
            },
            body: JSON.stringify({
                email,
                password,
                sessionId: 'sessionId',
            }),
        });
    } catch (e) {
        if (logErrors) {
            console.error('Error signing in:', e);
        }
    }

    return {
        headers: res?.headers || headers,
        body: res?.body,
        persistHeaders: headersToPersistBetweenRequests,
    };
}


async function generateVid({
    email,
    password,
    userId,
    svocId,
    pids = [],
} = {}) {
    const {
        headers,
        body,
        persistHeaders,
    } = await signIn(email, password)

    if (!userId && !svocId) {
        ({ userID: userId, svocID: svocId } = body);
    }

    const res = await hdFetch('/customer/auth/v1/vid', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...persistHeaders,
            Authorization: headers?.cookie?.THD_USER_SESSION ?? headers?.cookie?.THD_CUSTOMER,
            TMXProfileId: 'tmxProfileId',
            Cookie: headers?.cookie,
        },
        body: JSON.stringify({
            userId,
            svocId,
        }),
    });

    const { token } = res.body;
    const authKey = token?.substr(4);

    const pidsToAppend = pids.length
        ? JSON.stringify({ p_ids: pids })
        : '';
    const pidsBase64 = btoa(pidsToAppend);
    const hdWalletToken = `${token}${pidsBase64 ? `,${pidsBase64}` : ''}`;

    return {
        ...res,
        token,
        authKey,
        pidsBase64,
        hdWalletToken,
    };
}



function parseArgs(args = process.argv) {
    const thisFileName = import.meta.url.match(/(?<=\/)[^\/]+$/)?.[0];
    const argsIndexOfJsFile = process.argv.findIndex(cliArg => cliArg?.match(/\.[mc]?[tj]s[x]?$/));

    if (!(
        argsIndexOfJsFile >= 0
        && process.argv[argsIndexOfJsFile]?.includes(thisFileName)
    )) {
        // User didn't run this script directly, so exit without calling `main()`
        return;
    }

    const scriptArgs = args.slice(argsIndexOfJsFile + 1);
    const defaultUserEmail = Object.entries(users)[0][0];
    const defaultUser = users[defaultUserEmail];
    const defaultArgs = {
        email: defaultUserEmail,
        password: defaultUser.password,
        userId: undefined,
        svocId: undefined,
        pids: defaultUser.pids ?? [],
        copyToClipboard: false,
        help: false,
    }
    const parsedScriptArgs = scriptArgs.reduce((argMap, arg, argIndex, arr) => {
        const nextArg = arr[argIndex + 1];

        switch(arg) {
            case '-u':
            case '--user':
                argMap.email = nextArg;
                argMap.password = users[argMap.email]?.password;
                argMap.userId = users[argMap.email]?.userId;
                argMap.svocId = users[argMap.email]?.svocId;
                argMap.pids = users[argMap.email]?.pids ?? [];
                break;
            case '-P':
            case '--password':
                argMap.password = nextArg;
                break;
            case '-i':
            case '--userId':
                argMap.userId = nextArg;
                break;
            case '-s':
            case '--svocId':
                argMap.svocId = nextArg;
                break;
            case '-p':
            case '--pids':
                argMap.pids.push(nextArg);
                break;
            case '-c':
            case '--copy':
                argMap.copyToClipboard = true;
                break;
            case '-h':
            case '--help':
                argMap.help = true;
                break;
            default:
                break;
        }

        return argMap;
    }, defaultArgs);

    if (parsedScriptArgs.help) {
        console.log(`
Usage: ${thisFileName} [options]

Options:
    -u, --user <email>      The email of the user to sign in as (default: ${defaultUserEmail}).
    -P, --password <pass>   The password of the user to sign in as (default: ${defaultUser.password}).
    -i, --userId <id>       The user ID to use for the VID (default: ${defaultUser.userId}).
    -s, --svocId <id>       The SVOC ID to use for the VID (default: ${defaultUser.svocId}).
    -p, --pids <pid>        PIDs to add to the VID (default for ${defaultUserEmail}: ${defaultUser.pids.join(', ')}).
    -c, --copy              Copy the resulting VID to the clipboard.
    -h, --help              Print this message and exit.

If using one of the following emails, then \`password\`, \`userId\`, and \`svocId\` aren't required:
    ${Object.keys(users).join('\n    ')}
        `);

        return;
    }

    return parsedScriptArgs;
}

async function main(argv = process.argv) {
    const args = parseArgs(argv);

    if (!args) {
        return;
    }

    const res = await generateVid(args);
    const vid = res?.hdWalletToken || res?.token;

    if (vid) {
        console.log(vid);

        if (args.copyToClipboard) {
            copyToClipboard(vid);
        }
    }
}



main()
    .catch(err => {
        console.error('Could not generate vid. Are you using NodeJS >= v21? Were the arguments passed correct?');
        console.error('\n\n');
        console.error(err);
    });



export {
    headersToObj,
    hdFetch,
    getHmacToken,
    signIn,
    generateVid,
};
