#!/usr/bin/env node --experimental-top-level-await --experimental-json-modules --experimental-specifier-resolution=node --experimental-import-meta-resolve

/**
 * Must be run as a back-end NodeJS script in order to take advantage of the CORS proxy,
 * i.e. overwrite the `Origin` and `Referer` headers.
 */

import 'isomorphic-fetch';

/**
 * Network request to a URL through a CORS proxy.
 *
 * @param {string} url - URL to use in `fetch()`.
 * @param {string} [options.method] - HTTP method to use; default is `GET`.
 * @param {Object} [options.headers] - Headers for  the request; default: `Accept: 'application/json'`, `Content-Type: 'application/json'`, `Cache-Control: 'no-cache'`, `Pragma: 'no-cache'`, `Origin: <url-origin>`, `Referer: <url-origin>`.
 * @param {any} [options.body] - Body for the request; plain objects, arrays, and functions will be stringified, everything else will be passed as-is.
 * @param {string} [options.responseFunc='json'] - Function to call on the response to get the body.
 * @param {RequestInit} [options.otherFetchOptions] - Any other `RequestInit` properties to add that aren't covered above.
 * @returns {{ response: Response, headers: Object, body: any }} - The `fetch` response object (untainted),
 *         response headers as an object, and the body of the response after calling `await response[responseFunc]()`.
 */
async function nextdoorComCorsRequest(url, {
    method,
    headers,
    body,
    responseFunc = 'json',
    otherFetchOptions = {},
} = {}) {
    const { origin } = new URL(url);
    const corsHostUrl = 'https://anime-atsume.herokuapp.com/corsProxy?url=';
    const proxiedUrl = corsHostUrl + encodeURIComponent(url);

    const getVarType = variable => Object.prototype.toString.call(variable);
    const bodyType = getVarType(body);
    const shouldStringify = (
        Array.isArray(body)
        || (bodyType === getVarType({}))
    );
    const shouldToString = (
        (bodyType === getVarType(fetch))
    );

    const res = await fetch(proxiedUrl, {
        method,
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
            Pragma: 'no-cache',
            Origin: origin,
            Referer: origin,
            // 'x-csrftoken': '',
            ...headers,
        },
        body: shouldStringify
                ? JSON.stringify(body)
                : shouldToString
                    ? body.toString()
                    : body,
        ...otherFetchOptions,
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


/**
 * Gets all groups available to the user from the [All groups page]{@link https://nextdoor.com/groups/}
 *
 * @param {string} cookie - Cookie from your own login session; if unspecified, retrieval will be attempted from going to the home page, but it will likely fail.
 * @returns {Object} - The resulting JSON response.
 */
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
                        sha256Hash: '',
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
