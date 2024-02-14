#!/usr/bin/env node


const hmacCreationTime = Date.now();

const users = {
    'b2btestperksstaguser216@mailinator.com': {
        password: 'Test54321',
        userId: '042050999502B2280U',
        svocId: '0420509994FAB2280S',
    },
    'b2btestperksstaguser209@mailinator.com': {
        password: 'Test1234',
        userId: '04201FA82A72E8F40U',
        svocId: '04201FA82A6668F40S',
    },
    'b2btestperksstaguser187@mailinator.com': {
        password: 'Test@1234',
        userId: '041FD225FD3F55380U',
        svocId: '041FD225FD33D5380S',
    },
    'b2btest50@gmail.com': {
        password: 'testqa01',
        userId: '041F59C53417BB670U',
        svocId: '041F59C5340DBB670S',
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


async function signIn(email, password) {
    password = password ?? users[email].password;

    const { headers: { cookie }, body: { clientAuthToken }} = await getHmacToken();
    const res = await hdFetch('/customer/auth/v1/signin', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            channelId: 1,
            'cust-acct-client-token': clientAuthToken,
            'cust-acct-client-timestamp': hmacCreationTime,
            'cust-acct-client-id': 'clientId',
            'cust-acct-client-delay-token-validation': '444444',
            Cookie: cookie,
        },
        body: JSON.stringify({
            email,
            password,
            sessionId: 'sessionId',
        }),
    });

    return {
        headers: res.headers,
        body: res.body,
        persistHeaders: {
            'cust-acct-client-token': clientAuthToken,
            'cust-acct-client-timestamp': hmacCreationTime,
            'cust-acct-client-id': 'clientId',
            'cust-acct-client-delay-token-validation': '444444',
        },
    };
}


async function generateVid(email, {
    pids = [],
} = {}) {
    const { headers, body: { userID: userId, svocID: svocId }, persistHeaders } = await signIn(email);

    const res = await hdFetch('/customer/auth/v1/vid', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...persistHeaders,
            Authorization: headers?.cookie?.THD_USER_SESSION ?? headers?.cookie?.THD_CUSTOMER,
            TMXProfileId: 'tmxProfileId',
            Cookie: headers.cookie,
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



async function main(args = process.argv) {
    const defaultUserEmail = Object.entries(users)[1][0];
    const userEmail = args?.[2] ?? defaultUserEmail;

    return await generateVid(userEmail, { pids: [ 'P12514EBA89B035480', 'P125171CA5C74170E0' ]});
}



const argsIndexOfJsFile = process.argv.findIndex(cliArg => cliArg?.match(/\.[mc]?[tj]s[x]?$/));

if (argsIndexOfJsFile >= 0 && process.argv[argsIndexOfJsFile]?.match(/vid/i)) {
    // User ran this script directly, so call `main()`
    main().then(res => {
        console.log(res.hdWalletToken || res.token);
    });
}


export {
    headersToObj,
    hdFetch,
    getHmacToken,
    signIn,
    generateVid,
};
