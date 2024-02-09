#!/usr/bin/env -S node --no-warnings --experimental-top-level-await --experimental-json-modules --experimental-import-meta-resolve --experimental-specifier-resolution=node

import path from 'node:path';

import { log, importGlobalModule } from '../../../linux/bin/NodeUtils';


await importGlobalModule('isomorphic-fetch');


const creds = {
    sftp: {
        host: 'sftp://ispa.st9307.homedepot.com',
        username: 'pos',
        password: 'buy4me',
    },
    pos: {
        // Manager and/or ASM
        username: 'asm001',
        password: 'TestMe123!',
        _sub: {
            cashier: {
                username: 'cas025',
                password: 'qa02Test!',
            },
            sku: [
                161640,
                221221,
            ],
        },
    },
    website: {
        url: 'https://hd-qa74.homedepotdev.com',
        _sub: {
            1: {
                username: 'b2btestperksstaguser187@mailinator.com',
                password: 'Test@1234',
            },
            2: {
                username: 'b2btestperksstaguser216@mailinator.com',
                password: 'Test54321',
            },
            3: {
                username: 'b2btestperksstaguser209@mailinator.com',
                password: 'Test1234',
            },
            4: {
                username: 'b2btest50@gmail.com',
                password: 'testqa01',
            },
        },
    },
};


export async function getCreds(app, ...args) {
    if (!app) {
        return creds;
    }

    if (app.match(/all/i) && !('all' in creds)) {
        return creds;
    }

    if (!args.length) {
        return creds[app];
    }

    let subOptions = creds[app];
    let subOptIndex = 0;

    while (args[subOptIndex]) {
        let subOptKey = args[subOptIndex];

        if (!(subOptKey in subOptions)) {
            subOptions = subOptions._sub;
        }

        subOptions = subOptions[subOptKey];

        subOptIndex++
    }

    return subOptions;
}


export async function getVid({
    username,
    password,
    devApiOrigin = 'https://hd-qa74.homedepotdev.com',
    vidKey = false,
} = {}) {
    const logins = {
        'b2btestperksstaguser187@mailinator.com': 'Test@1234',
        'b2btestperksstaguser216@mailinator.com': 'Test54321',
        'b2btestperksstaguser209@mailinator.com': 'Test1234',
        'b2btest50@gmail.com': 'testqa01',
    };

    if (!username) {
        username = Object.entries(logins)[0][0];
    }

    password = password || logins[username];

    const utcInMillis = new Date().getTime();
    const hmacCreationTime = utcInMillis;

    function getCookie(cookieStr, key = '', {
        decodeBase64 = true,
    } = {}) {
        const cookieObj = cookieStr.split('; ').reduce((obj, entry) => {
            const keyVal = entry.split('=');
            const key = decodeURIComponent(keyVal[0]);
            let value = decodeURIComponent(keyVal.slice(1).join('='));

            if (decodeBase64) {
                try {
                    value = atob(value);
                } catch (e) {
                    /* Not a Base64-encoded string */
                }
            }

            obj[key] = value;

            return obj;
        }, {});

        return key ? cookieObj[key] : cookieObj;
    }

    function headersToObj(headers) {
        const headersObj = [ ...headers.entries() ].reduce((obj, [ key, val ]) => {
            obj[key] = val;

            return obj;
        }, {});

        return {
            ...headersObj,
            'set-cookie': headers.getSetCookie().map(entry => entry?.split(';')?.[0]).join('; '),
        };
    }

    const resGetAuthToken = await fetch(`${devApiOrigin}/customer/account/v1/auth/getauthtoken`, {
        headers: {
            timestamp: new Date().getTime(),
            clientId: 'clientId',
        },
    });
    const headersGetAuthToken = headersToObj(resGetAuthToken.headers);
    const { clientAuthToken } = await resGetAuthToken.json();

    const resSignIn = await fetch(`${devApiOrigin}/customer/auth/v1/signin`, {
        method: 'POST',
        credentials: 'include',
        headers: {
            'Accept': `application/json`,
            'Content-Type': `application/json`,
            'User-Agent': `neoload`,
            Cookie: headersGetAuthToken['set-cookie'],
            'cust-acct-client-token': `${clientAuthToken}`,
            'cust-acct-client-timestamp': `${hmacCreationTime}`,
            'cust-acct-client-id': `clientId`,
            'cust-acct-client-delay-token-validation': `444444`,
            'channelId': `1`,
        },
        body: JSON.stringify({
            email: username,
            password: password,
            sessionId: 'sessionId',
        }),
    });
    const headersSignIn = headersToObj(resSignIn.headers);
    const { email, customerType, userID: userId, svocID: svocId } = await resSignIn.json();

    const signinAuthTokenCookieName = customerType?.match?.(/B2C/i) ? 'THD_USER_SESSION' : 'THD_CUSTOMER';
    const signinAuthToken = getCookie(typeof document !== 'undefined' && document.cookie['set-cookie'] || headersSignIn['set-cookie'])[signinAuthTokenCookieName];

    const resGenerateVid = await fetch(`${devApiOrigin}/customer/auth/v1/vid`, {
        method: 'POST',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': 'neoload',
            TMXProfileId: 'tmxProfileId',
            Authorization: signinAuthToken,
            // Cookie: Object.entries({
            //     ...headersGetAuthToken['set-cookie'],
            //     ...headersSignIn['set-cookie'],
            // })
            //     .map(([ key, val ]) => `${key}=${val}`)
            //     .join('; '),
            Cookie: headersSignIn['set-cookie'],
        },
        body: JSON.stringify({
            userId,
            svocId,
        }),
    });

    const { token: vidToken, creationDate: vidCreationDate, ttl: vidTtl } = await resGenerateVid.json();
    const vidTokenKey = vidToken.slice(4);

    if (vidKey) {
        return vidTokenKey;
    } else {
        return vidToken;
    }
}


const thisFileUrl = import.meta.url;
const thisFilePath = new URL(thisFileUrl).pathname;
const thisFileName = path.basename(thisFilePath);

const isMain = !!process.argv?.[1]?.match(new RegExp(`${thisFileName}$`));

if (isMain) {
    const USAGE = `${thisFileName} <app> [SUB-OPTIONS...]
    Gets the credentials to login to the specified \`app\`.

    Options:
        <app>: all, ${Object.keys(creds).join(', ')}

    Sub-options:
        ${`${
            Object.entries(creds)
                .filter(([ app, conf ]) => '_sub' in conf)
                .map(([ app, conf ]) => (
                    `${app}: ${Object.entries(conf._sub)
                        .filter(([ key ]) => !key.match(/_sub/i))
                        .map(([ subApp, subConf ]) => (
                            `${subApp}.[${Object.keys(subConf)}]`
                        )).join(', ')}`
                ))
                .join('\n        ')
        }`}
        vid
        vidKey
    `;

    const [
        nodePath,
        thisFile,
        app,
        ...args
    ] = process.argv;

    if (!app || app.match(/^(-h|help|help)/i) || (typeof fetch === typeof undefined)) {
        console.log(USAGE);

        process.exit(1);
    }

    // log(args.reduce((obj, entry) => {
    //     const [ key, val ] = entry.split('=');
    //
    //     obj[key.replace(/^-+/, '')] = val;
    //
    //     return obj;
    // }, {}));

    let output;

    try {
        output = await getCreds(app, ...args);
    } catch(e) {
        if (app.match(/vid/i)) {
            output = await getVid(...args);
        }
    }

    log(output);
}
