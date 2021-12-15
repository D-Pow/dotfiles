#!/usr/bin/env node --experimental-top-level-await --experimental-json-modules --experimental-specifier-resolution=node --experimental-import-meta-resolve

/**
 * Must be run as a back-end NodeJS script in order to take advantage of the CORS proxy,
 * i.e. overwrite the `Origin` and `Referer` headers.
 */

import 'isomorphic-fetch';

async function nextdoorComCorsRequest(url, {
    method,
    headers,
    body,
    responseFunc = 'json',
} = {}) {
    const res = await fetch(url, {
        method,
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
            Pragma: 'no-cache',
            Origin: 'https://nextdoor.com',
            Referer: 'https://nextdoor.com',
            'x-csrftoken': 'SVgNbAt4m6gJJKI3cgvmRwlzmd2SMs1HRMyHcI6nuj9fHo589l2R7j615Z5j2mG4',
            ...headers,
        },
        body: body && JSON.stringify(body),
    });

    const response = res.clone();
    const resHeaders = [ ...res.headers ].reduce((obj, [ key, val ]) => {
        if (obj[key]) {
            if (Array.isArray(obj[key])) {
                obj[key].push(val);
            } else {
                obj[key] = [ obj[key], val ];
            }
        } else {
            obj[key] = val;
        }

        return obj;
    }, {});
    const resBody = await res[responseFunc]();

    return {
        response,
        headers: resHeaders,
        body: resBody,
    };
}


async function getGroupsForUser(cookie) {
    if (!cookie) {
        const homePage = await nextdoorComCorsRequest('https://nextdoor.com', { responseFunc: 'text' });
        cookie = homePage.headers['set-cookie'];
    }

    const groups = await nextdoorComCorsRequest(
        'https://nextdoor.com/api/gql/UserGroupsSections?',
        {
            method: 'POST',
            headers: {
                cookie,
                'x-csrftoken': cookie?.match?.(/(?<=csrftoken=)[^;]+/i)?.[0]
            },
            body: {
                operationName: 'UserGroupsSections',
                variables: {
                    excludeSectionItemTypeIds: [],
                    cursors: [],
                },
                extensions: {
                    persistedQuery: {
                        version: 1,
                        sha256Hash: '8584e495bdd0504c0534bd2e91389eb23b7340747b79893e0c4053bd7d698a72',
                    },
                },
            },
        }
    );

    return groups.body;
}


(async () => {
    console.log(await getGroupsForUser(
        // insert cookie here
    ));
})();
