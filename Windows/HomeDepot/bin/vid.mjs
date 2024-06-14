#!/usr/bin/env node

import childProcess from 'node:child_process';


function copyToClipboard(str) {
    let osInfo;

    try {
        osInfo = childProcess
            .execSync('uname -a', { stdio: 'pipe' })
            .toString()
            .replace(/\n/g, '');
    } catch (unameNotDefinedError) {}

    let copyCommand;
    let pasteCommand;
    let isWindows = false;

    if (!osInfo || osInfo.match(/not recognized as an internal or external command/i) || osInfo.match(/^MSYS_/i)) {
        // Windows Command Prompt or Powershell
        copyCommand = 'C:\\Windows\\System32\\cmd.exe /C clip';
        pasteCommand = 'C:\\Windows\\System32\\cmd.exe /C powershell Get-Clipboard'
        isWindows = true;
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
        let echoPipePrefix = `echo -n "${str}" | `;

        if (isWindows) {
            // Remove quotes since CMD doesn't parse them in a user-friendly way
            echoPipePrefix = `echo -n ${str} | `
        }

        const commandToExecute = `${echoPipePrefix} ${copyCommand}`;

        return childProcess
            .execSync(commandToExecute)
            .toString()
            .replace(/\n/g, '');
    }
}

async function cliPrompt(query) {
    const readline = await import('node:readline/promises');
    // Can only have one interface per prompt, otherwise input will be duplicated on subsequent prompts.
    // See: https://stackoverflow.com/questions/48494624/node-readline-interface-repeating-each-character-multiplicatively
    const terminal = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });
    const cliInput = await terminal.question(query);

    terminal.close();

    return cliInput;
}



const hmacCreationTime = Date.now();

const users = {
    'b2btestperksstaguser216@mailinator.com': {
        password: 'Test54321',
        userId: '042050999502B2280U',
        svocId: '0420509994FAB2280S',
        phoneNumber: '4346468756',
        pids: [
            // 'P1352A745A584B8780', // CC - 9702 - Local CLS, CustomerInfoV3ResponseTransformer.java line 352, spoof hdWalletAuthorized to always true
            // "P1352A7DD71E5B8780", // CC

            // 'P124F797A7AEE07A80', // Pro Allowance CC?
            'P124F797AB98607A80',

            // 'P12529749F7A49CF60', // Coupon: $1 St9307 HD Wallet 1% Off
            // 'P1252974C39EB9CF60', // Coupon: $1 St9307 HD Wallet 1% Off
        ],
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
        pids: [
            // 'P125216B44975E7F80',
        ],
    },
    'b2btest50@gmail.com': {
        password: 'testqa01',
        userId: '041F59C53417BB670U',
        svocId: '041F59C5340DBB670S',
        pids: [
            'P125216B44975E7F80',
        ],
    },
    // admin
    'otpoverridetest1294@yopmail.com': {
        password: 'TestMe123',
        userId: '0529D925EE6C37A60U',
        svocId: '0529D925EE6037A60S',
        pids: [
            //
        ],
    },
    // purchaser
    'otpoverridetest1295@yopmail.com': {
        password: 'TestMe123',
        userId: '0529D9271EB6B7A60U',
        svocId: '0529D925EE6037A60S',
        pids: [
            //
        ],
    },
    'platformstage@yopmail.com': {
        password: 'TestMe123!',
        userId: '0527960EE66BB5BB0U',
        svocIdAdmin: '0527960EE66135BB0S',
        svocIdRunner: '0420509994FAB2280S',
        get svocId() {
            return this.svocIdRunner;
        },
        pids: [
            // 'P12522C5CB16DE7BC0', // CC
            // 'P125217B5407DE7F80', // Free snack
            // 'P125217B41470E7F80', // PXD
            // "P13528CF6B85F78E00", // PXD
            // 'P125217B38B3FE7F80',
            // 'P12526A4F62F4087C0', // $1 off
            // "P125217B658C9E7F80", // $5
            // "P125217B658C9E7F80"
            // "P12525F8BB08B087C0", // $5
        ],
    },
    'platformstagerunner@yopmail.com': {
        password: 'TestMe123!',
        userId: '052941539C1B2DE60U',
        svocId: '052941539C102DE60S',
        pids: [],
    },
    'platformstage3@yopmail.com': {
        password: 'TestMe123!',
        userId: '05279610D85A35BB0U',
        svocId: '05279610D850B5BB0S',
        pids: [],
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

            headersObj.cookie = {
                ...headersObj.cookie,
                ...cookie,
            };

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
        headers: {
            ...(res?.headers || headers),
            cookie: {
                ...res?.headers?.cookie,
                ...headers?.cookie,

            },
        },
        body: res?.body,
        persistHeaders: headersToPersistBetweenRequests,
    };
}


async function generateVid({
    email = Object.keys(users)[0],
    password,
    userId,
    svocId,
    pids = [],
    selectPids,
    longVid,
} = users[Object.keys(users)[0]]) {
    pids = [ ...new Set(pids) ];
    const {
        headers,
        body,
        persistHeaders,
    } = await signIn(email, password);

    if (!userId && !svocId) {
        ({ userID: userId, svocID: svocId } = body);

        if (!userId && !svocId && email in users) {
            ({ userID: userId, svocID: svocId } = users[email]);
        }
    }

    if (!headers?.cookie?.hasOwnProperty('THD_CUSTOMER')) {
        const defaultUserEmail = Object.keys(users)[0];
        const tmpRes = await signIn(defaultUserEmail, users[defaultUserEmail].password);

        headers.cookie = tmpRes.headers.cookie;
    }

    const queryForShortVids = longVid ? '' : `?pattern=v2vid`; /* userId=${userId}&svocId=${svocId}& */
    const res = await hdFetch(`/customer/auth/v1/vid${queryForShortVids}`, {
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

    let payments;

    if (selectPids) {
        payments = await getPayments({
            userId,
            svocId,
            headers: {
                ...persistHeaders,
                cookie: `THD_CUSTOMER=${headers?.cookie?.THD_CUSTOMER}`,
                // Cookie: {
                //     THD_CUSTOMER: headers?.cookie?.THD_CUSTOMER,
                // },
            },
        });

        const pidPrompts = [
            [ payments.creditCards, 'credit card', false ],
            [ payments.pxds, 'PXD', false ],
            [ payments.coupons, 'coupons (comma-separated)', true ],
        ]
            .filter(([ arr ]) => arr?.length);

        for (const [ pidsArray, prompt, multi ] of pidPrompts) {
            // Maintain order via Map
            const pidsMap = new Map(pidsArray.map(({ paymentId, cardNickName, gcBalance, perkTitle, availableBalance }, i) => [
                i,
                {
                    cardNickName: cardNickName ?? perkTitle, // perkTitle only used for coupons
                    paymentId,
                    availableBalance,
                },
            ]));
            const pidsNames = [ ...pidsMap.values() ].map(({ cardNickName }) => cardNickName);
            const chosenPidIndex = await cliPrompt(`Choose ${prompt}:\n${pidsNames.map((cardNickName, i) => `\t${i}: ${cardNickName}`).join('\n')}\n > `);

            if (chosenPidIndex !== '-') {
                if (multi) {
                    const chosenPids = chosenPidIndex
                        .split(',')
                        .map(chosenPid => pidsMap.get(Number(chosenPid))?.paymentId);

                    pids.push(...chosenPids);
                } else {
                    const chosenPid = pidsMap.get(Number(chosenPidIndex));

                    pids.push(chosenPid.paymentId);
                }
            }
        }
    }

    const { token } = res.body;

    if (!token) {
        console.error('Failed to generate VID token! Response:', res.body);

        return;
    }

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
        payments,
    };
}


async function getPayments({
    userId,
    svocId,
    headers,
}) {
    let typeCd = 'cc';
    const resCreditCards = await hdFetch(`/b2b/user/account/${userId}/customer/${svocId}/payment/retrieve?typecd=${typeCd}&ps=100&pn=1&sb=lastedited&asc=false`, {
        headers: {
            'channelId': '1',
            ...headers,
        },
    });
    const creditCards = resCreditCards.body.paymentCards.paymentCard
        ?.filter(({ cardStatus, hdWalletAuthorized, t2cPrimary }) => (
            cardStatus?.match(/(?<!in)Active/i)
            && (
                hdWalletAuthorized?.match(/y/i)
                || t2cPrimary
            )
        ))
        ?.map(({ cardNickName, paymentId, paymentType, hdWalletAuthorized, t2cPrimary, isDefault }) => ({ cardNickName, paymentId, paymentType, hdWalletAuthorized, t2cPrimary, isDefault }));
    // Get primary CC and move it to first in the array
    const primaryCreditCardIndex = creditCards?.findIndex(({ isDefault }) => isDefault) || 0;
    const primaryCreditCard = creditCards?.splice(primaryCreditCardIndex, 1)?.[0];

    if (primaryCreditCard) {
        creditCards?.splice(0, 0, primaryCreditCard);
    }

    typeCd = 'pgc';
    const resPxds = await hdFetch(`/b2b/user/account/${userId}/customer/${svocId}/payment/retrieve?typecd=${typeCd}&ps=100&pn=1&sb=lastedited&asc=false`, {
        headers: {
            'channelId': '1',
            ...headers,
        },
    });
    const pxds = resPxds.body.paymentCards.paymentCard
        ?.filter(({ gcBalance, rewardExpDate, perkTypeStatus }) => (
            Number(gcBalance) > 0
            && new Date() < new Date(rewardExpDate)
            && perkTypeStatus?.match(/(?<!in)Active/i)
        ))
        ?.map(({ cardNickName, paymentId, paymentType, gcBalance }) => ({ cardNickName, paymentId, paymentType, gcBalance }));

    // TODO - Could remove query param to get both PXDs and coupons
    const resCoupons = await hdFetch(`/b2b/user/account/${userId}/customer/${svocId}/perks/info?offerType=offer`, {
        headers: {
            'channelId': '1',
            ...headers,
        },
    });
    const coupons = resCoupons.body.nonProgramPerks
        ?.filter(({ perkStatus, perkType, expirationTime }) => (
            perkStatus?.match(/(?<!in)Active/i)
            && new Date() < new Date(expirationTime)
            && !perkType?.match(/TOOL_RENTAL/i)
        ))
        ?.map(({ perkTitle, paymentId, perkType, availableBalance }) => ({ perkTitle, paymentId, perkType, availableBalance }));

    return {
        primaryCreditCard,
        creditCards,
        pxds,
        coupons,
    };
}



function parseArgs(args = process.argv) {
    const thisFileName = import.meta.url.match(/(?<=[\/\\])[^\/]+$/)?.[0];
    const argsIndexOfJsFile = process.argv.findIndex(cliArg => cliArg?.match(/\.[mc]?[tj]s[x]?$/));
    const isMain = (
        argsIndexOfJsFile >= 0
        && process.argv[argsIndexOfJsFile]?.includes(thisFileName)
    );

    if (!isMain) {
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
        selectPids: false,
        longVid: false,
        copyToClipboard: false,
        help: false,
    }
    const parsedScriptArgs = scriptArgs.reduce((argMap, arg, argIndex, arr) => {
        const nextArg = arr[argIndex + 1];

        switch(arg) {
            case '-u':
            case '--user':
                argMap.email = nextArg;
                argMap.password = argMap.password ?? users[argMap.email]?.password;
                argMap.userId = argMap.userId ?? users[argMap.email]?.userId;
                argMap.svocId = argMap.svocId ?? users[argMap.email]?.svocId;
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
            case '-S':
            case '--select':
                argMap.selectPids = true;
                argMap.pids = [];
                break;
            case '-l':
            case '--long':
                argMap.longVid = true;
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
    -S, --select            Prompt for PIDs to add (type "-" without quotes to not select a PID from the prompt).
    -l, --long              Generate long, v1 VID instead of short, v2 VID.
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
    })
    .finally(() => process.exit());



export {
    headersToObj,
    hdFetch,
    getHmacToken,
    signIn,
    generateVid,
};
