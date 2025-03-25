#!/usr/bin/env node

import childProcess from 'node:child_process';
import {
    copyToClipboard,
    cliPrompt,
} from '../../../linux/bin/NodeUtils.mjs';


const hmacCreationTime = Date.now();

const giftCards = {
    '98081550000375908410349': {
        pin: 3653,
    },
    '98081550000375915341008': {
        pin: 2746,
    },
};

const couponBarcodes = {
    transactionLevel: {
        barcode: '98153000003090752399641951',
    },
    itemLevel: [
        {
            sku: '172036',
            barcode: '98153000003091157079816478',
        },
        {
            sku: 148634,
            barcode: 98153000003097051638900333,
            promo: 30970,
        },
        {
            sku: 148490,
            barcode: 98153000003097115881451045,
            promo: 30971,
        },
        {
            sku: 148264,
            barcode: 98153000003097806992645380,
            promo: 30978,
        },
    ],
};
/*
Gift Cards
98081550000366096830687 1014 - $5
98081550000366103507013 3011 - $5
98081550000366113262161 9943 - $10
98081550000366126630735 6220 - $10
98081550000366130322550 7605 - $25
*/
// Candy SKU: 198656, 199314
// Coke SKU: 751139
const users = {
    'b2btestperksstaguser216@mailinator.com': {
        password: 'Test54321',
        userId: '042050999502B2280U',
        svocId: '0420509994FAB2280S',
        phoneNumber: '4346468756',
        pids: [
            // 'P1352A745A584B8780', // CC - 9702 - Local CLS, CustomerInfoV3ResponseTransformer.java line 352, spoof hdWalletAuthorized to always true
            // 'P1352B0EE700CB8780', // CC Pro Allowance - hdpass apr1
            // 'P124F797AB98607A80', // CC - MASTERCARD card
            // 'P1352A7DD71E5B8780', // CC Primary - Em Cappai

            'P135892215F27E2C00', // CC Primary purchaser card
            // 'P13565AE1297521E60', // CC Primary Prox card
            // 'P13569AD8CAFF2EFE0', // Juan single card, HD Pass only
            // 'P1256E1223C34F2700', // Amex HD Pass only

            // 'P12529749F7A49CF60', // Coupon: $1 St9307 HD Wallet 1% Off
            // 'P1252974C39EB9CF60', // Coupon: $1 St9307 HD Wallet 1% Off

            // 'P1252974CF7AD9CF60', // All coupons
            // 'P1252974A3BD09CF60',
            // 'P1252974A69BF9CF60',
            // 'P1252A6D8BD089CF60',
            // 'P1252A6D793C49CF60',
            // 'P1252A6CBC3A39CF60',
            // 'P1252A6D58BE29CF60',
            // 'P1252A6D9ACC19CF60',
            // 'P1252A6E1FBD79CF60',
            // 'P1252A6D680969CF60',
        ],
    },
    'b2btestwithoutbenefits@yopmail.com': {  // Non-military
        password: 'Test5544@',
        userId: '052B7CCDDDFF9E5E0U',
        svocId: '052B7CCDDDCD1E5E0S',
        pids: [
            'P135700EAAAC0E12A0',
        ],
    },
    'b2btestadmin@yopmail.com': {
        password: 'Test7878@',
        userId: '042B5CD4AE804E240U',
        svocId: '042B5CD4AE564E240S',
        pids: [
            // 'P1356EB719D53DD260',
            'P13587D45601A055A0', // PLCC
        ],
    },
    'b2btestperksstaguser209@mailinator.com': {
        password: 'Test1234',
        userId: '04201FA82A72E8F40U',
        svocIdAdmin: '04201FA82A6668F40S',
        svocIdPurchaser: '0420509994FAB2280S',
        get svocId() {
            return this.svocIdAdmin;
        },
        pids: [
            // 'P125216B44975E7F80',
            'P124F7981FAF307A80', // 216's admin card
        ],
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
        svocIdPurchaser: '0420509994FAB2280S',
        get svocId() {
            return this.svocIdPurchaser;
        },
        pids: [
            'P1352A7DD71E5B8780', // b2b216's "Em Cappai" Pro Allowance (active) & HD Pass CC
            // 'P12522C5CB16DE7BC0', // CC
            // 'P125217B41470E7F80', // PXD
            // "P13528CF6B85F78E00", // PXD
            // 'P125217B5407DE7F80', // Free snack
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
        svocIdAdmin: '052941539C102DE60S',
        svocIdPurchaser: '0420509994FAB2280S',
        get svocId() {
            return this.svocIdPurchaser;
        },
        pids: [
            // 'P124F797A46F107A80', // b2b216's Pro Allowance only CC
            'P1352A7DD71E5B8780', // b2b216's "Em Cappai" Pro Allowance (active) & HD Pass CC
            'P13548149F7DD8C0A0', // HD Pass CC (not b2b216's) "Personal HD Pass"
            // "P12551C098FCACFE80", // $25 PXD
            'P1255C773B180FC480', // $25 PXD
            // 'P12529749F7A49CF60', // Coupon 1
            // 'P1252974C39EB9CF60', // Coupon 2
            // 'P1252974CF7AD9CF60',
            // 'P1252974A3BD09CF60',
            // 'P1252974A69BF9CF60',
            // 'P1252A6D8BD089CF60',
            // 'P1252A6D793C49CF60',
            // 'P1252A6CBC3A39CF60',
            // 'P1252A6D58BE29CF60',
            // 'P1252A6D9ACC19CF60',
            // 'P1252A6E1FBD79CF60',
            // 'P1252A6D680969CF60',
        ],
    },
    'platformstage3@yopmail.com': {
        password: 'TestMe123!',
        userId: '05279610D85A35BB0U',
        svocId: '05279610D850B5BB0S',
        pids: [],
    },
    '2851540_5@dummy.com': {
        userId: '0513D4436F12E3980U',
        svocId: '0300EF2B79F5E2D26S',
        phoneNumber: '2851540100',
        pids: [],
    },
};



export function headersToObj(headersEntriesArray) {
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

// process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
export async function hdFetch(url, opts, {
    domain = 'https://hd-qa74.homedepotdev.com',
    // domain = 'https://184.25.166.81',
    // domain = 'https://23.47.178.14',
    // domain = 'https://23.216.70.70',
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


export async function getHmacToken() {
    return await hdFetch('/customer/account/v1/auth/getauthtoken', {
        headers: {
            timestamp: hmacCreationTime,
            clientId: 'clientId',
        },
    });
}


export async function signIn(email, password, {
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


export async function generateVid({
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
// let count = 0;
// console.log(count++, { userId, svocId });
    if (!userId && !svocId) {
        ({ userID: userId, svocID: svocId } = body);
// console.log(count++, { userId, svocId });

        if (!userId && !svocId && email in users) {
            ({ userID: userId, svocID: svocId } = users[email]);
// console.log(count++, { userId, svocId });
        }
    }
// console.log(count++, { userId, svocId });
    if (!headers?.cookie?.hasOwnProperty('THD_CUSTOMER')) {
        const defaultUserEmail = Object.keys(users)[0];
        const tmpRes = await signIn(defaultUserEmail, users[defaultUserEmail].password);

        headers.cookie = tmpRes.headers.cookie;
    }

    const queryForShortVids = longVid ? '' : `?pattern=v2vid`; /* userId=${userId}&svocId=${svocId}& */
    const genVid = async () => await hdFetch(`/customer/auth/v1/vid${queryForShortVids}`, {
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
    let res = await genVid();
    let genVidAttempts = 1;
    const maxGenVidAttempts = 20;

    while (
        // res.body?.token?.match(/^(\d*_)?v?\d_[^_]+_[^_]+_.*-+.*$/i)
        res?.body?.token?.split('_')?.slice(-1)?.[0]?.match(/-/g)
        && genVidAttempts < maxGenVidAttempts
    ) {
        genVidAttempts++;
        res = await genVid();
    }

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
            [ payments.creditCards, 'credit card', true ],
            [ payments.pxds, 'PXD', true ],
            [ payments.coupons, 'coupon', true ],
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
            const chosenPidIndex = await cliPrompt(`Choose ${prompt}${multi ? '(s) (comma-separated)' : ''}:\n${
                pidsNames.map((cardNickName, i) => `\t${i}: ${cardNickName}`).join('\n')
            }\n > `);

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


export async function getPayments({
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
        ?.map(({ cardNickName, paymentId, paymentType, hdWalletAuthorized, t2cPrimary, isDefault, cardNumberLast4 }) => ({ cardNickName, paymentId, paymentType, hdWalletAuthorized, t2cPrimary, isDefault, cardNumberLast4 }));
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
        ?.map(({ cardNickName, paymentId, paymentType, gcBalance }) => ({ cardNickName: `${cardNickName} - ${gcBalance}`, paymentId, paymentType, gcBalance }));

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



function parseArgs(args = process.argv, scriptName = import.meta.url.match(/(?<=[\/\\])[^\/]+$/)?.[0]) {
    const argsIndexOfJsFile = args.findIndex(cliArg => cliArg?.match(/\.[mc]?[tj]s[x]?$/));
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
        args: [],
    }
    const parsedScriptArgs = scriptArgs.reduce((argMap, arg, argIndex, arr) => {
        const nextArg = arr[argIndex + 1];

        switch(arg) {
            case '-u':
            case '--user':
                argMap.email = nextArg;
                argMap.password = users[argMap.email]?.password ?? argMap.password;
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
                if (
                    argMap.pids === defaultUser.pids
                    || argMap.pids === users[argMap.email]?.pids
                ) {
                    argMap.pids = [];
                }

                if (nextArg) {
                    argMap.pids.push(nextArg);
                }

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
                argMap.args.push(arg);
                break;
        }

        return argMap;
    }, defaultArgs);

    if (parsedScriptArgs.help) {
        console.log(`
Usage: ${scriptName} [options]

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
    const thisFileName = import.meta.url.match(/(?<=[\/\\])[^\/]+$/)?.[0];
    const argsIndexOfJsFile = argv.findIndex(cliArg => cliArg?.match(/\.[mc]?[tj]s[x]?$/));
    const isMain = (
        argsIndexOfJsFile >= 0
        && argv[argsIndexOfJsFile]?.includes(thisFileName)
    );

    if (!isMain) {
        // User didn't run this script directly, so exit without calling `main()`
        return;
    }

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
