javascript:(function bookmarkUsefulFunctions() {

/*********************************
 ********    Utilities    ********
 ********************************/
const jsFunctionRegex = '^\(?\s*@?(?!if|constructor|switch|runInAction)(?:async )?(function )?(\w+)(?=(?:\s*=?\s*)\(.*\{[\s\n])';

window.sortObjectByKeys = function(obj) {
    return Object.keys(obj).sort().reduce((sortedObj, key) => {
        sortedObj[key] = obj[key];
        return sortedObj;
    }, {});
};

window.getCookie = function getCookie({
    key = '',
    cookie = document.cookie,
    decodeBase64 = true,
} = {}) {
    const cookieObj = cookie.split('; ').reduce((obj, entry) => {
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
};

window.resetCookie = function() {
    document.cookie = 'expires=Thu, 01 Jan 1970 00:00:01 GMT';
};

function getQueryParams(input = self.location.search + self.location.hash, { delimiter, } = {}) {
    let fromString;
    let fromObj;
    let from2dMatrix;

    if (typeof input === typeof '') {
        fromString = input;
    } else if (Array.isArray(input)) {
        from2dMatrix = input;
    } else if (typeof input === typeof {}) {
        fromObj = input;
    } else {
        throw new TypeError(`Type "${typeof input}" is not supported. Please use a string or object.`);
    }

    if (fromObj) {
        fromObj = { ...fromObj };

        const hash = fromObj['#'] || '';

        delete fromObj['#'];

        const getEncodedKeyValStr = (key, val) => `${encodeURIComponent(key)}=${encodeURIComponent(val)}`;

        const queryParamEntries = Object.entries(fromObj);
        const queryString = queryParamEntries.length > 0
            ? `?${
                queryParamEntries
                    .map(([ queryKey, queryValue ]) => {
                        if (Array.isArray(queryValue)) {
                            if (delimiter) {
                                return getEncodedKeyValStr(queryKey, queryValue.join(delimiter));
                            }

                            return queryValue
                                .map(val => getEncodedKeyValStr(queryKey, val))
                                .join('&');
                        }

                        if (queryValue == null) {
                            /* Convert null/undefined to empty string */
                            queryValue = '';
                        } else if (typeof queryValue === typeof {}) {
                            /* Stringify objects, arrays, etc. */
                            return getEncodedKeyValStr(queryKey, JSON.stringify(queryValue));
                        }

                        return getEncodedKeyValStr(queryKey, queryValue);
                    })
                    .join('&')
            }`
            : '';

        return queryString + (hash ? `#${hash}` : '');
    }

    const queryParamsObj = {};
    let urlSearchParamsEntries;

    if (from2dMatrix) {
        const stringifiedMatrixValues = from2dMatrix.map(([ key, value ]) => {
            if (value && (typeof value === typeof {})) {
                /* Arrays are objects so only one `typeof` check is needed */
                value = JSON.stringify(value);
            }

            return [ key, value ];
        });

        urlSearchParamsEntries = [...new URLSearchParams(stringifiedMatrixValues).entries()];
    } else {
        const queryParamHashString = fromString.match(/([?#].*$)/i)?.[0] ?? '';
        const [ urlSearchQuery, hash ] = queryParamHashString.split('#');

        if (hash) {
            queryParamsObj['#'] = hash;
        }

        urlSearchParamsEntries = [...new URLSearchParams(urlSearchQuery).entries()];
    }

    const attemptParseJson = (str) => {
        try {
            return JSON.parse(str);
        } catch (e) {}

        return str;
    };

    return urlSearchParamsEntries
        .reduce((queryParams, nextQueryParam) => {
            let [ key, value ] = nextQueryParam;

            if (delimiter != null) {
                value = value.split(delimiter);
                if (value.length === 0) {
                    value = '';
                } else if (value.length === 1) {
                    value = value[0];
                }
            }

            if (Array.isArray(value)) {
                value = value.map(val => attemptParseJson(val));
            } else {
                value = attemptParseJson(value);
            }

            if (key in queryParams) {
                if (!Array.isArray(value)) {
                    value = [ value ]; /* cast to array for easier boolean logic below */
                }

                /* Remove duplicate entries using a Set, which maintains insertion order in JS */
                let newValuesSet;

                if (Array.isArray(queryParams[key])) {
                    newValuesSet = new Set([
                        ...queryParams[key],
                        ...value,
                    ]);
                } else {
                    newValuesSet = new Set([
                        queryParams[key],
                        ...value,
                    ]);
                }

                queryParams[key] = [ ...newValuesSet ]; /* Cast back to an array */
            } else {
                queryParams[key] = value;
            }

            return queryParams;
        }, queryParamsObj);
};

window.getQueryParams = getQueryParams;


/**
 * Extracts the different segments from a URL segments and adds automatic parsing of query parameters/hash
 * into an object. Also normalizes resulting strings to never contain a trailing slash.
 *
 * @param url - URL to parse for query parameters
 * @returns URL segments.
 */
function getUrlSegments(url = '') {
    let fullUrl = url;
    let protocol = '';
    let domain = '';
    let port = '';
    let origin = '';
    let pathname = '';
    let queryString = '';
    let queryParamHashString = '';
    let hash = '';

    try {
        ({
            href: fullUrl,
            origin,
            protocol,
            hostname: domain,
            port,
            pathname,
            search: queryString,
            hash, /* empty string or '#...' */
        } = new URL(url));
    } catch (e) {
        /*
         * Either `URL` isn't defined or some other error, so try to parse it manually.
         *
         * All regex strings use `*` to mark them as optional when capturing so that
         * they're always the same location in the resulting array, regardless of whether
         * or not they exist.
         *
         * URL segment markers must each ignore all special characters used by
         * those after it to avoid capturing the next segment's content.
         */
        const protocolRegex = '([^:/?#]*://)?'; /* include `://` for `origin` creation below */
        const domainRegex = '([^:/?#]*)'; /* capture everything after the protocol but before the port, pathname, query-params, or hash */
        const portRegex = '(?::)?(\\d*)'; /* colon followed by digits; non-capture must be outside capture group so it isn't included in output */
        const pathnameRegex = '([^?#]*)'; /* everything after the origin (starts with `/`) but before query-params or hash */
        const queryParamRegex = '([^#]*)'; /* everything before the hash (starts with `?`) */
        const hashRegex = '(.*)'; /* anything leftover after the above capture groups have done their job (starts with `#`) */
        const urlPiecesRegex = new RegExp(`^${protocolRegex}${domainRegex}${portRegex}${pathnameRegex}${queryParamRegex}${hashRegex}$`);

        [
            fullUrl,
            protocol,
            domain,
            port,
            pathname,
            queryString,
            hash,
        ] = urlPiecesRegex.exec(url);

        origin = protocol + domain + (port ? `:${port}` : '');
    }

    queryParamHashString = queryString + hash;
    /* protocol can be `undefined` due to having to nest the entire thing in `()?` */
    protocol = (protocol || '').replace(/:\/?\/?/, '');
    /* normalize strings: remove trailing slashes and leading ? or # */
    fullUrl = fullUrl.replace(/\/+(?=\?|#|$)/, ''); /* fullUrl could have `/` followed by query params, hash, or end of string */
    origin = origin.replace(/\/+$/, '');
    pathname = pathname.replace(/\/+$/, '');
    queryString = queryString.substring(1);
    hash = hash.substring(1);

    const queryParamMap = getQueryParams(queryParamHashString);

    return {
        fullUrl,
        protocol,
        domain,
        port,
        origin,
        pathname,
        queryParamHashString,
        queryParamMap,
        queryString,
        hash,
    };
};

window.getUrlSegments = getUrlSegments;


/**
 * Hashes a string using the specified algorithm.
 *
 * Defaults to SHA-256. Available algorithms exist in the `hash.ALGOS` object.
 *
 * @param {string} str - String to hash.
 * @param {typeof hash.ALGOS[keyof hash.ALGOS]} [algo] - Algorithm to use.
 * @returns The hashed string.
 *
 * @see [Crypto.subtle hashing API]{@link https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest#converting_a_digest_to_a_hex_string}
 * @see [Boilerplate crypto utils]{@link https://github.com/D-Pow/react-app-boilerplate/blob/master/src/utils/Crypto.ts}
 */
window.hash = async function hash(str, {
    algo = hash.ALGOS.Sha256,
} = {}) {
    const validAlgorithms = new Set(Object.values(hash.ALGOS));

    if (!validAlgorithms.has(algo)) {
        throw new TypeError(`Error: Hash algorithm "${algo}" not supported. Valid values are: [ ${[ ...validAlgorithms ].join(', ')} ].`);
    }

    /* Encode to (UTF-8) Uint8Array */
    const utf8IntArray = new TextEncoder().encode(str);
    /* Hash the string */
    const hashBuffer = await self.crypto.subtle.digest(algo, utf8IntArray);
    /* Get hex string from buffer/byte array */
    const hashAsciiHex = byteArrayToHexString(new Uint8Array(hashBuffer));

    return hashAsciiHex;
}
hash.ALGOS = {
    Sha1: 'SHA-1',
    Sha256: 'SHA-256',
    Sha384: 'SHA-384',
    Sha512: 'SHA-512',
};;

/** @see [Boilerplate text utils]{@link https://github.com/D-Pow/react-app-boilerplate/blob/master/src/utils/Text.js} */
window.byteArrayToHexString = function byteArrayToHexString(uint8Array, {
    hexPrefix = '',
    hexDelimiter = '',
    asArray = false,
} = {}) {
    const hexStrings = [ ...uint8Array ].map(byte => byte.toString(16).padStart(2, '0'));
    const hexStringsWithPrefixes = hexStrings.map(hexString => `${hexPrefix}${hexString}`);

    if (asArray) {
        return hexStringsWithPrefixes;
    }

    return hexStringsWithPrefixes.join(hexDelimiter);
};


/** @see [Boilerplate Date utils]{@link https://github.com/D-Pow/react-app-boilerplate/blob/master/src/utils/Dates.ts} */
window.diffDateTime = function diffDateTime(
    earlier = new Date(),
    later = new Date(),
) {
    let earlierDate = new Date(earlier);
    let laterDate = new Date(later);

    if (laterDate.valueOf() < earlierDate.valueOf()) {
        const earlierDateOrig = earlierDate;

        earlierDate = laterDate;
        laterDate = earlierDateOrig;
    }

    const diffDateObj = {
        years: laterDate.getFullYear() - earlierDate.getFullYear(),
        months: laterDate.getMonth() - earlierDate.getMonth(),
        dates: laterDate.getDate() - earlierDate.getDate(),
        hours: laterDate.getHours() - earlierDate.getHours(),
        minutes: laterDate.getMinutes() - earlierDate.getMinutes(),
        seconds: laterDate.getSeconds() - earlierDate.getSeconds(),
        milliseconds: laterDate.getMilliseconds() - earlierDate.getMilliseconds(),
    };

    Object.entries(diffDateObj).reverse().forEach(([ key, val ], i, entries) => {
        const nextEntry = entries[i + 1];

        if (!nextEntry) {
            return;
        }

        const [ nextKey, nextVal ] = nextEntry;
        const timeConfig = diffDateTime.ordersOfMagnitude[key];

        if (val < 0) {
            diffDateObj[key] = numberToBaseX(diffDateObj[key], timeConfig.maxValue, { signed: false });
            diffDateObj[nextKey] = nextVal - 1;
        }
    });

    diffDateObj.days = diffDateObj.dates;
    delete diffDateObj.dates;

    return diffDateObj;
};
diffDateTime.ordersOfMagnitude = {
    milliseconds: {
        maxValue: 1,
    },
    seconds: {
        maxValue: 60,
    },
    minutes: {
        maxValue: 60,
    },
    hours: {
        maxValue: 24,
    },
    days: {
        maxValue: 7,
    },
    weeks: {
        maxValue: 4,
    },
    dates: {
        maxValue: 31,
    },
    months: {
        maxValue: 12,
    },
    years: {
        maxValue: 1,
    },
};

/**
 * Mods two numbers with a custom radix; i.e. Makes `num1 % num2` have a max of a
 * certain number, regardless of positive or negative mod value.
 * Helpful for stuff like diffing minutes relative to the max minute possible, 60.
 *
 * e.g. If the date diff of the first date resulted in a negative minute value (-52)
 * and the later date had a positive value (30) and you want to diff the minutes
 * relative to a "radix" of 60, then:
 * min1 = -52
 * min2 = 30
 * -52 % 30 =
 *     -22 (signed)
 *       8 (unsigned)
 */
window.numberToBaseX = function numberToBaseX(num, base, {
    signed = true,
} = {}) {
    const signedModBase = num % base;

    if (!signed) {
        /* Converts e.g. -52 % 30 => 8 instead of -22 */
        return (signedModBase + base) % base;
    }

    return signedModBase;
};


window.getAlphabet = function getAlphabet({
    lowercase = true,
    uppercase = true,
} = {}) {
    const getUpperOrLowerCaseAlphabetFromA = startCharCode => Array.from({ length: 26 })
        .map((nul, index) => index + startCharCode)
        .map(charCode => String.fromCharCode(charCode));
    const alphabetLowercase = getUpperOrLowerCaseAlphabetFromA('a'.charCodeAt(0));
    const alphabetUppercase = getUpperOrLowerCaseAlphabetFromA('A'.charCodeAt(0));

    if (lowercase && uppercase) {
        return [ ...alphabetLowercase, ...alphabetUppercase ];
    }

    if (lowercase) {
        return alphabetLowercase;
    }

    if (uppercase) {
        return alphabetUppercase;
    }
};

window.htmlEscape = str => {
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
};

window.htmlUnescape = str => {
    return str
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#x27;/g, "'")
        .replace(/&#x2F;/g, '/');
};

window.getElementAttributes = elem => [ ...(elem.attributes) ] /* `attributes` is a `NamedNodeMap`: https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap */
    .reduce((attrsObj, { name, value }) => ( /* Grab desired keys from the `Attr` object: https://developer.mozilla.org/en-US/docs/Web/API/Attr */
        (attrsObj[name] = value)
        && attrsObj /*  Use short-circuiting to ensure we always return the `attrsObj` without having to convert this to a full blown function like `(args) => { myLogic; return attrsObj; }` */
        || attrsObj
    ), {});


/**
 * Makes a class iterable, adding an implementation of `Class.prototype[Symbol.iterator]`.
 *
 * @param {Object} cls - Class to make iterable.
 * @param {string} nextLikeFuncName - The name of the function generating values, to be called like an iterator's `next()` function.
 * @param {Object} [options]
 * @param {boolean} [options.force] - Force overwriting of any preexisting iterator implementations.
 * @param {Object} [options.trackItemsOnNextCall] - Keep track of all values returned from the next-like function;
 *                                                  Useful for when items are deleted after being read (e.g. NodeIterator, TreeWalker)
 *                                                  or when the next-like function will generate new items over time and you want the
 *                                                  iterator to track them.
 * @returns {void}
 *
 * @see [Implementation inspiration]{@link https://github.com/whatwg/dom/issues/704}
 * @see [Iterable/Iterator protocols]{@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Iteration_protocols}
 */
function makeClassIterable(cls, nextLikeFuncName, {
    trackItemsOnNextCall = false,
    force = false,
} = {}) {
    const clsName = cls.name || cls.prototype.constructor.name;
    const nextLikeFunc = cls.prototype[nextLikeFuncName];
    const isIterable = cls.prototype[Symbol.iterator] instanceof Function;

    if (!(nextLikeFunc && nextLikeFunc instanceof Function)) {
        throw new TypeError(`${clsName}.prototype.${nextLikeFuncName} is not a function`);
    }

    if (isIterable) {
        console.warn(`${clsName}.prototype[Symbol.iterator] already exists`);

        if (!force) {
            return;
        }

        console.log(`Overwriting ${clsName}.prototype[Symbol.iterator]...`);
    }

    /* Use `function` instead of arrow function so `this` works on the class instance */
    function* iteratorFunc() {
        let nextValue;

        while ((nextValue = this[nextLikeFuncName]()) != null) {
            yield nextValue;
        }
    }

    function makeIterator(trackItems = false) {
        if (trackItems) {
            const values = [];
            let iterator;
            let iteratorExhausted = false;

            /* TODO Extract this out to its own function and make it possible to reset iterators */
            return function* () {
                /*
                 * Neither `makeIterator` nor `iteratorFunc` are bound to the class because `makeIterator`
                 * is not a generator/doesn't return an iterator and is called in the context of the parent
                 * who called this function (e.g. `window` if in dev tools, a different class, or some script).
                 *
                 * Thus, bind `this` to `iteratorFunc` within this anonymous function b/c it is called on
                 * the class instance itself (i.e. when `clsInstance[Symbol.iterator]()` is called), giving
                 * it the correct value of `this`.
                 *
                 * Note: we don't need to `bind(this)` if returning the `iteratorFunc` itself b/c it will
                 * be called on the class instance, not from the parent context nor within another function.
                 */
                const bindIteratorFunc = () => iterator = iteratorFunc.bind(this)();

                if (!iterator) {
                    bindIteratorFunc();
                }

                if (iteratorExhausted) {
                    /*
                     * Delegate this (returned) generator's iterator logic to Array.prototype[Symbol.iterator]
                     * since all items have been deleted.
                     * Then, reset the `iterator` to a new instance from `iteratorFunc` to capture any values
                     * that might be added after the first iteration (which also means don't return from the
                     * function here, either).
                     */
                    yield* values;
                    bindIteratorFunc();
                }

                let value;

                /*
                 * Set the `next()` output to `value` and `done` variables, then use JS' internal/natural return
                 * logic of statement executions to read the `next()` return object's `done` field (which was copied)
                 * into the local variable)
                 */
                while (!({ value } = iterator.next()).done) {
                    values.push(value);
                    yield value;
                }

                iteratorExhausted = true;
            };
        }

        return iteratorFunc;
    }

    cls.prototype[Symbol.iterator] = makeIterator(trackItemsOnNextCall);
};
window.makeClassIterable = makeClassIterable;


/**
 * Finds all Nodes/Elements through custom logic that can't be captured by CSS query selectors.
 *
 * Useful cases include:
 * - innerText
 * - All attribute values (i.e. CSS selector akin to `[.* *= 'my-search-text']`)
 * - Custom "is a parent/child of" logic (i.e. skipping over any elements whose parent is <h1> for performance improvements)
 *
 * @param {function} nodeFilterFunc - Filter function; `(Node) => boolean | NodeFilter.FILTER_[X]`.
 * @param {Object} [options]
 * @param {boolean} [options.useCustomNodeIteratorReturn] - If `nodeFilterFunc` returns a `NodeFilter` property instead of a boolean (see `useNodeIterator` example).
 * @param {Object} [options.useNodeIterator] - If a `NodeIterator` should be used instead of `document.querySelectorAll('*')`;
 *                                             Typically only useful if your filter function wants to return a custom `NodeIterator`
 *                                             value, which is generally only used over `querySelectorAll()` to improve performance
 *                                             by e.g. dropping entire DOM sub-trees so they aren't searched, i.e.
 *                                             `return node.tagName.match(/div/i) ? NodeFilter.FILTER_REJECT : node.innerText === 'hi' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;`.
 * @return {Node[]} - Array of matching [DOM Nodes]{@link https://developer.mozilla.org/en-US/docs/Web/API/Node}.
 *
 * @see [When to use NodeIterator instead of querySelectorAll]{@link https://stackoverflow.com/questions/7941288/when-to-use-nodeiterator/58221592}
 * @see [NodeIterator]{@link https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator}
 * @see [NodeFilter]{@link https://developer.mozilla.org/en-US/docs/Web/API/NodeFilter}
 * @see [CSS Selectors]{@link https://www.w3schools.com/cssref/css_selectors.asp}
 * @see [innerText vs textContent]{@link https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent#differences_from_innertext}
 * @see [Xpath vs TreeWalker vs manual element iteratation]{@link https://stackoverflow.com/questions/3813294/how-to-get-element-by-innertext}
 * @see [Secret CSS Selector finds by attribute, but has no documentation anywhere]{@link https://stackoverflow.com/a/42479114}
 */
function findElementsByAnything(nodeFilterFunc, {
    useNodeIterator = false,
    useCustomNodeIteratorReturn = false,
} = {}) {
    if (useNodeIterator || useCustomNodeIteratorReturn) {
        const nodeIterator = document.createNodeIterator(
            document.body,
            NodeFilter.SHOW_ELEMENT,
            {
                acceptNode(node) {
                    if (useCustomNodeIteratorReturn) {
                        return nodeFilterFunc(node);
                    }

                    return nodeFilterFunc(node) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
                }
            }
        );

        const nodeMatches = [];
        let currentNode;

        while (currentNode = nodeIterator.nextNode()) {
            nodeMatches.push(currentNode);
        }

        return nodeMatches;
    }

    return [ ...document.body.querySelectorAll('*') ].filter(nodeFilterFunc);
};
window.findElementsByAnything = findElementsByAnything;


window.setDocumentReferer = function(url = null, useOrigin = false) {
    if (!url) {
        /*
         * Create  <meta name="referrer" content="never" />
         * This header removes all referrer headers completely
         */
        const meta = document.createElement('meta');
        meta.name = 'referrer';
        meta.content = 'never';
        document.head.appendChild(meta);
        return;
    }

    let referrerUrl = url;

    if (useOrigin) {
        const originRegex = /(?<=https:\/\/)[^/]+/;
        referrerUrl = url.match(originRegex)[0];
    }

    delete document.referrer;
    document.__defineGetter__('referrer', () => referrerUrl);
};

/**
 * fetch() using CORS proxy
 *
 * Fetch API: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
 * Fetch API + CORS: https://developers.google.com/web/ilt/pwa/working-with-the-fetch-api
 * Using CORS proxy: https://stackoverflow.com/a/43268098/5771107
 * CORS proxy: https://cors-anywhere.herokuapp.com/ + URL (e.g. https://www.rapidvideo.com/e/FUM5608RR8)
 *
 * Attempt at using headers for getting video from rapidvideo.com
 * headers: {
 *     'X-Requested-With': 'XMLHttpRequest',
 *     // rest aren't needed
 *     'Accept-Encoding': 'gzip, deflate, br',
 *     'Accept-Language': 'en-US,en;q=0.9',
 *     'Cache-Control': 'no-cache',
 *     'Connection': 'keep-alive',
 *     // 'Cookie': 'key1=val1; key2=val2',
 *     'DNT': '1',
 *     'Host': 'www.rapidvideo.com',
 *     'Pragma': 'no-cache',
 *     'Referer': 'https://kissanime.ru/Anime/Boku-no-Hero-Academia-3rd-Season/Episode-059?id=149673&s=rapidvideo',
 *     'Upgrade-Insecure-Requests': '1',
 *     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36'
 * }
 *
 * @param {string} url - URL for network request.
 * @param {RequestInit} options - Options for `fetch()`.
 * @param {boolean} [useCorsAnywhereApp=false] - Use https://cors-anywhere.herokuapp.com/ (restricted and close to deprecation) instead of Anime Atsume.
 */
window.fetchCors = function(url, options, useCorsAnywhereApp = false) {
    if (useCorsAnywhereApp) {
        const corsAnywhereRequiredHeaders = {
            'X-Requested-With': 'XMLHttpRequest'
        };
        const fetchOptions = options
            ? {
                ...options,
                headers: {
                    ...options?.headers,
                    ...corsAnywhereRequiredHeaders
                }
            } : {
                headers: corsAnywhereRequiredHeaders
            };

        return fetch(
            'https://cors-anywhere.herokuapp.com/' + url,
            {...fetchOptions}
        );
    }

    const animeAtsumeCorsUrl = 'https://anime-atsume.herokuapp.com/corsProxy?url=';
    const defaultAnimeAtsumeCorsOptions = {
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
        },
    };
    const requestOptions = {
        ...options,
        headers: {
            ...defaultAnimeAtsumeCorsOptions.headers,
            ...options?.headers,
        },
    };
    const encodedUrl = animeAtsumeCorsUrl + encodeURIComponent(url);

    return fetch(encodedUrl, requestOptions);
};

window.compareEscapingFunctions = function() {
    /* TL;DR Don't use escape(), use encode() or custom/third-party
     * See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent#description
     */
    const encodedCharsByFunc = Array.from({ length: 256 })
        .reduce((charsThatWillBeEncoded, nil, i) => {
            const asciiChar = String.fromCharCode(i);
            const charEncodes = {
                char: asciiChar
            };

            if (asciiChar !== encodeURI(asciiChar)) {
                charEncodes.encodeURI = encodeURI(asciiChar);
            }

            if (asciiChar !== encodeURIComponent(asciiChar)) {
                charEncodes.encodeURIComponent = encodeURIComponent(asciiChar);
            }

            if (asciiChar !== escape(asciiChar)) {
                charEncodes.escape = escape(asciiChar);
            }

            if (Object.keys(charEncodes).length > 1) {
                charsThatWillBeEncoded.push(charEncodes);
            }

            return charsThatWillBeEncoded;
        }, []);

    console.table(encodedCharsByFunc);

    return encodedCharsByFunc;
};


/**********************************
 ********    Life utils    *******
 *********************************/

window.celsiusFahrenheit = function ({
    c,
    f,
} = {}) {
    if (!c && !f) {
        throw new TypeError('Either `c` or `f` must be specified');
    }

    if (c) {
        return (c * 9/5) + 32;
    }

    if (f) {
        return (f - 32) * 5/9;
    }

    return NaN;
};


window.kilogramsPounds = function ({
    kg,
    lbs,
} = {}) {
    if (!kg && !lbs) {
        throw new TypeError('Either `kg` or `lbs` must be specified');
    }

    const kgToLbsRatio = 2.20462;

    if (lbs) {
        return lbs * (1 / kgToLbsRatio); /* ~ 0.453592 */
    }

    if (kg) {
        return kg * kgToLbsRatio;
    }

    return NaN;
};


window.ouncesPounds = function ({
    oz,
    lbs,
} = {}) {
    if (!oz && !lbs) {
        throw new TypeError('Either `oz` or `lbs` must be specified');
    }

    const ozToLbsRatio = 16;

    if (oz) {
        return oz * (1 / ozToLbsRatio);
    }

    if (lbs) {
        return lbs * ozToLbsRatio;
    }

    return NaN;
};


window.gramsOunces = function ({
    g,
    oz,
} = {}) {
    if (!g && !oz) {
        throw new TypeError('Either `g` or `oz` must be specified');
    }

    const gToOzRatio = 28.3495;

    if (g) {
        return g * (1 / gToOzRatio);
    }

    if (oz) {
        return oz * gToOzRatio;
    }

    return NaN;
};


window.ouncesMilliliters = function ({
    oz,
    ml,
} = {}) {
    if (!oz && !ml) {
        throw new TypeError('Either `oz` or `ml` must be specified');
    }

    const mlToOzRatio = 0.033814;

    if (oz) {
        return oz * (1 / mlToOzRatio);
    }

    if (ml) {
        return ml * mlToOzRatio;
    }

    return NaN;
};


window.inchesMillimeters = function ({
    inches,
    mm,
} = {}) {
    if (!inches && !mm) {
        throw new TypeError('Either `inches` or `mm` must be specified');
    }

    const inchesToMmRatio = 25.4;

    if (mm) {
        return mm / inchesToMmRatio; /* 1 inch = 25.4 mm */
    }

    if (inches) {
        return inches * inchesToMmRatio; /* 1 mm = 0.0393701 in */
    }

    return NaN;
};


/**
 * @typedef BacConfig
 * @property {number} hoursElapsed - Number of hours elapsed while drinking.
 * @property {boolean} isMale - If the person is a male.
 * @property {boolean} isDrinkVolumeOunces - If using oz for drink volume instead of mL.
 * @property {boolean} isBodyWeightPounds - If using lbs for body weight instead of kg.
 */
/**
 * @typedef BacDrink
 * @property {number} drinkVolume - Volume of the drink.
 * @property {number} drinkPercentage - Alcohol percentage of the drink
 * @property {number} hoursElapsed - Number of hours elapsed while drinking.
 */
/**
 * Estimates the blood alcohol concentration (BAC) after drinking over a period of time.
 *
 * Not 100% accurate due to differences in bodies' metabolism and other factors, but gives
 * a reasonable rough estimate.
 *
 * @param {(number | ({ drinks: Array<BacDrink>; } & BacConfig))} drinkVolume - Volume of the drink or drinks/options config object.
 * @param {number} drinkPercentage - Alcohol percentage of the drink.
 * @param {number} bodyWeight - Person's body weight (defaults to lbs; use option to use kg).
 * @param {BacConfig} [options]
 * @returns {number} - Estimated BAC.
 *
 * @see [Wikipedia article supplying the formula]{@link https://en.wikipedia.org/wiki/Blood_alcohol_content#Estimation_by_intake}
 */
window.bac = function bac(drinkVolume, drinkPercentage, bodyWeight, {
    hoursElapsed = 1,
    isMale = true,
    isDrinkVolumeOunces = true,
    isBodyWeightPounds = true,
} = {}) {
    if (typeof drinkVolume === typeof {}) {
        const fullConfig = drinkVolume;

        /* Options with fallback to default values */
        drinkPercentage = drinkPercentage || fullConfig.drinkPercentage;
        bodyWeight = bodyWeight || fullConfig.bodyWeight;
        isMale = fullConfig.isMale || isMale;
        isDrinkVolumeOunces = fullConfig.isDrinkVolumeOunces || isDrinkVolumeOunces;
        isBodyWeightPounds = fullConfig.isBodyWeightPounds || isBodyWeightPounds;

        return fullConfig.drinks.reduce((totalBac, { drinkVolume, drinkPercentage: customDrinkPercentage, hoursElapsed }) => (
            totalBac + bac(drinkVolume, customDrinkPercentage || fullConfig.drinkPercentage, bodyWeight, {
                hoursElapsed,
                isMale,
                isDrinkVolumeOunces,
                isBodyWeightPounds,
            })
        ), 0);
    }


    if (!drinkVolume) {
        throw new Error('`drinkVolume` must be specified.');
    }

    if (!drinkPercentage) {
        throw new Error('`drinkPercentage` must be specified.');
    }

    if (!bodyWeight) {
        throw new Error('`bodyWeight` must be specified.');
    }


    if (isDrinkVolumeOunces) {
        drinkVolume *= 29.5735; /* 1 oz == 29.5735 ml */
    }

    if (isBodyWeightPounds) {
        bodyWeight *= 0.453592; /* 1 lbs == 0.453592 kg */
    }

    const alcoholMassUnit = 1000; /* 1000 g == 1 kg; 16 oz == 1 lb, but no need to worry about that since it's converted to grams above */
    const alcoholMetabolismRate = isMale ? 0.015 : 0.017; /* Males process alcohol slower than females on average */
    const bodyWaterToBodyWeightRatio = isMale ? 0.68 : 0.55; /* Males have less body fat than females, thus have more water */
    /* See: https://www.engineeringtoolbox.com/ethanol-water-mixture-density-d_2162.html */
    const alcoholWaterDensityAt20Celsius = 0.935;
    const alcoholWaterDensityAt25Celsius = 0.931;
    const alcoholWaterDensity = (alcoholWaterDensityAt20Celsius + alcoholWaterDensityAt25Celsius) / 2;

    const bloodDensity = 1.055; /* g/mL */
    const bloodDensityToBloodConcentration = bloodDensity * 100; /* 1% BAC == 1/100 g/mL. See: https://en.wikipedia.org/wiki/Blood_alcohol_content#Units_of_measurement */
    const alcoholMass = (drinkVolume * drinkPercentage) / alcoholMassUnit; /* g => kg. For comparison to body weight */
    const bodyWaterWeight = bodyWaterToBodyWeightRatio * bodyWeight; /* How much alcohol is in the blood, not the tissues */
    const alcoholMetabolismRatePerTime = alcoholMetabolismRate * hoursElapsed; /* How quickly the alcohol is processed */

    const bacNum = (
        (alcoholMass / bodyWaterWeight)
        * bloodDensityToBloodConcentration
        * alcoholWaterDensity
        - alcoholMetabolismRatePerTime
    );

    return Number(bacNum.toFixed(3));
};


/************************************
 ********    Website utils    *******
 ***********************************/

window.githubGetAllFilesChangedByName = function(nameRegex = /./, {
    onlyFileName = false,
} = {}) {
    const filenameLinkSelector = '.file-info a[title]';

    /* Use `title` attribute b/c it has the full filename instead of a truncated filename (...partialDirName/myFile.txt) */
    return [...document.querySelectorAll(filenameLinkSelector)]
        .filter(anchor => anchor.title.match(nameRegex))
        .map(anchor => {
            if (onlyFileName) {
                return anchor.title;
            }

            return {
                fileName: anchor.title,
                fileElement: anchor.parentElement.parentElement,
            };
        });
};
window.githubToggleFilesByName = function(
    nameRegex,
    {
        collapsedToggle = true,
        viewedToggle = false,
    } = {}
) {
    const fileCollapseButtonSelector = 'button[aria-label="Toggle diff contents"]';
    const viewedToggleButtonElementSelector = '.file-actions .js-replace-file-header-review label';

    const matchingFilesChanged = githubGetAllFilesChangedByName(nameRegex);

    matchingFilesChanged.forEach(({ fileElement }) => {
        if (collapsedToggle) {
            fileElement?.querySelector?.(fileCollapseButtonSelector)?.click();
        }

        if (viewedToggle) {
            fileElement?.querySelector?.(viewedToggleButtonElementSelector)?.click();
        }
    });
};
window.githubToggleAllFilesChangedCollapsedStatus = function() {
    githubToggleFilesByName();
};
window.githubToggleAllTestsCollapsedStatus = function() {
    const testAndSnapshotRegex = /((test|spec)\.[jt]sx?)|(\.(snap|storyshot))$/i;
    githubToggleFilesByName(testAndSnapshotRegex);
};
window.githubToggleAllSnapshotsViewedStatus = function() {
    const snapshotExtensionRegex = /\.(snap|storyshot)$/i;
    githubToggleFilesByName(snapshotExtensionRegex, { collapsedToggle: false, viewedToggle: true });
};


window.youtubeGetAllChaptersOfVideo = function() {
    return [ ...document.querySelectorAll('[href*="watch"] ~ span.style-scope.yt-formatted-string') ]
        .map(elem => elem.innerText)
        .filter(str => Boolean(str.trim()))
        .map(str => str.replace(/(^[\s-]*)|([\s-]*)/gi, ''));
};


window.circleCiGetAllFailedTests = function({
    nameRegex = /./,
    onlyFileName = false,
    testNameRegex,
} = {}) {
    const allFailedTestExpandCollapseElems = [...document.querySelectorAll('li[id*=failed-test-]')];
    const allMatchingTestElems = allFailedTestExpandCollapseElems
        .map(elem => {
            const testAndFileNameStr = elem.querySelector('header h4').textContent;
            const separator = ' - ';
            const testAndFileNamesSplit = testAndFileNameStr.split(separator);
            const testName = testAndFileNamesSplit.slice(0, -1).join(separator);
            const fileName = testAndFileNamesSplit[testAndFileNamesSplit.length - 1];

            return {
                testName,
                fileName,
                elem,
            };
        })
        .filter(({ fileName, testName }) => {
            return nameRegex.test(fileName) || testNameRegex?.test(testName);
        });

    if (onlyFileName) {
        return allMatchingTestElems.map(({ fileName }) => fileName);
    }

    return allMatchingTestElems;
};
window.circleCiToggleAllSnapshotTestsExpansion = function() {
    [...document.querySelectorAll('li[id*=failed-test-] [role=button]')]
        .filter(btn => btn.textContent.includes('MatchSnapshot'))
        .forEach(btn => btn.click());
};


window.citiSumChargesForPreviousStatements = function() {
    /* Helpful when "running balance" column doesn't exist */
    return [...document.querySelectorAll('.cA-ada-TRANSACTION_AMT_Column.cA-ada-ls-hide')]
        .map(elem => elem.textContent
            .replace(/[\$,]/g, '')
            .replace('−', '-')
            .trim()
        ).reduce((sum, numStr) => sum + Number(numStr), 0);
};


window.drizlyGetAbvAndPricesFromSearchResults = async function(minAbv = 10) {
    const searchResultElems = [...document.querySelectorAll('.section-body.list-view li')];
    const searchResultInfoPromises = searchResultElems.map(async elem => {
        try {
            const name = elem.innerText.split('\n')[0];
            const price = elem.innerText.match(/\$[\d.]+/)[0];
            const url = elem.children[0].href;
            const res = await fetch(url);
            const text = await res.text();
            const abv = text.match(/ABV[\s\S]*?\d+%/)[0].match(/\d+%/)[0];

            return {
                name,
                price,
                abv
            };
        } catch (e) {
            return null
        }
    });

    const allResolvedNamesWithAbv = await Promise.all(searchResultInfoPromises);
    const allNamesWithAbv = allResolvedNamesWithAbv.filter(Boolean);
    const aboveSpecifiedAbv = allNamesWithAbv.filter(({ abv }) => parseInt(abv) >= minAbv);

    return aboveSpecifiedAbv;
};


window.amazonGetChatLog = function amazonGetChatLog(copyToClipboard = true) {
    const chatLogParentDiv = document.querySelector('.ChatRoller__liveTranscriptWrapper___JJkDd');
    const chatLogEntries = [...chatLogParentDiv.children];

    const amazonChatLog= chatLogEntries.reduce((chatLogs, childElem) => {
        const text = childElem.querySelector('[class*=messageBody]')?.innerText;
        const timeStamp = childElem.querySelector('[class*=timeStamp]')?.innerText;
        const isAgentMessage = childElem.className.includes('agentVariant');

        chatLogs.push({ agent: isAgentMessage, text, timeStamp });

        return chatLogs;
    }, []);

    if (copyToClipboard) {
        copy(amazonChatLog);
    }

    return amazonChatLog;
};


/**
 * Searches Jisho for English <--> Japanese translations.
 *
 * Can also use some meta characters/terms for searching, e.g.
 *   - * (0-Infinite characters)
 *   - ? (0-1 characters)
 *   - tags (#verb, #adjective, #counter, #jlpt-n5, #grade3, etc.)
 *
 * @param {string} query - Query with which to search Jisho.
 * @returns {Promise<Object>} - Jisho search results.
 * @see [Jisho docs]{@link https://jisho.org/docs}
 */
async function translateJapanese(query) {
    const jishoApiUrl = 'https://jisho.org/api/v1/search/words?keyword=';
    const fetchUrl = jishoApiUrl + encodeURIComponent(query);

    const jishoFetch = async (useCorsProxy = false) => {
        const res = useCorsProxy
            ? await fetchCors(fetchUrl)
            : await fetch(fetchUrl);
        const json = await res.json();

        return json;
    };

    try {
        return await jishoFetch();
    } catch (errorProbablyCors) {
        try {
            return await jishoFetch(true);
        } catch (e) {
            console.error(e);
        }
    }
};
window.translateJapanese = translateJapanese;


/**
 * HTTP-based JS Slack service.
 *
 * SDKs would be better for an actual app.
 *
 * @see [API docs]{@link https://api.slack.com/docs}
 * @see [API methods search page]{@link https://api.slack.com/methods}
 * @see [SDKs]{@link https://api.slack.com/tools}
 * @see [New JS/TS SDK]{@link https://github.com/slackapi/bolt-js}
 * @see [Old NodeJS SDK]{@link https://slackapi.github.io/node-slack-sdk/}
 */
class SlackInBrowserService {
    /**
     * @typedef {Object} Channel
     * @property {string} id
     * @property {string} name
     * @property {Object} topic
     * @property {string} topic.value - Short description of the channel.
     * @property {Object} purpose
     * @property {string} purpose.value - Long description of the channel.
     * @property {string[]} shared_team_ids - Array of teams (i.e. servers/organizations) able to view the channel.
     */
    /**
     * @typedef {Object} Member
     * @property {string} id
     * @property {string} name
     */

    /* Get from dev tools - just watch other XHR requests and take a token from one of them */
    static TOKEN = '';
    /* Get from dev tools - api.slack.com isn't necessarily used, sometimes a company-specific URL is used instead */
    static API_URL_BASE = 'https://nextdoor.slack.com/api';
    /* not sure what this is or why it's needed, but CORS errors are thrown if it's not present (at least at Nextdoor) */
    static API_QUERY_PARAMS = {
        _x_gantry: true
    };

    /**
     * Mapping from understandable names to Slack API methods.
     */
    static Apis = {
        GetUserInfo: 'users.identity',
        GetUserChannels: 'users.conversations',
        GetAllUsers: 'users.list',
        GetChannelTypes: 'users.channelSections.list', /* e.g. channel, direct message, starred, etc. */
        GetAllChannelsInServer: 'channels.list',
        GetChannelInfo: 'conversations.info',
        GetChannelMembers: 'conversations.members',
    };

    /**
     * Gets URL query parameter entries as either key-value pairs in an object
     * or as a string formatted how they would appear in the URL bar (e.g. `?a=b&c=d`).
     *
     * Defaults to getting the query parameters from the current page's URL as an object.
     * If `fromObj` is specified, then `fromUrl` will be ignored and a string will be returned instead.
     *
     * @param {(string|Object)} [input=location.search+location.hash] - URL search/hash string to convert to an object, or
     *                                                                  an object to convert to a search+hash string.
     * @returns {(Object|string)} - All query param and hash key-value pairs (if input is a string) or URL search+hash string (if input is an object).
     */
    static getQueryParams(input = self.location.search + self.location.hash) {
        let fromUrl;
        let fromObj;

        if (typeof input === typeof '') {
            fromUrl = input;
        } else if (typeof input === typeof {}) {
            fromObj = input;
        } else {
            throw new TypeError(`Type "${typeof input}" is not supported. Please use a string or object.`);
        }

        if (fromObj) {
            fromObj = { ...fromObj };

            const hash = fromObj['#'] || '';

            delete fromObj['#'];

            const getEncodedKeyValStr = (key, val) => `${encodeURIComponent(key)}=${encodeURIComponent(val)}`;

            const queryParamEntries = Object.entries(fromObj);
            const queryString = queryParamEntries.length > 0
                ? `?${
                    queryParamEntries
                        .map(([ queryKey, queryValue ]) => {
                            if (Array.isArray(queryValue)) {
                                return queryValue
                                    .map(val => getEncodedKeyValStr(queryKey, val))
                                    .join('&');
                            }

                            return getEncodedKeyValStr(queryKey, queryValue);
                        })
                        .join('&')
                }`
                : '';

            return queryString + (hash ? `#${hash}` : '');
        }

        const queryParamHashString = fromUrl.replace(/^\?/, '');
        const [ urlSearchQuery, hash ] = queryParamHashString.split('#');

        const queryParamsObj = {};

        if (hash) {
            queryParamsObj['#'] = hash;
        }

        return [ ...new URLSearchParams(urlSearchQuery).entries() ]
            .reduce((queryParams, nextQueryParam) => {
                const [ key, value ] = nextQueryParam;

                if (key in queryParams) {
                    if (Array.isArray(queryParams[key])) {
                        queryParams[key].push(value);
                    } else {
                        queryParams[key] = [ queryParams[key], value ];
                    }
                } else {
                    queryParams[key] = value;
                }

                return queryParams;
            }, queryParamsObj);
    }


    static getApiUrl(api = '', queryParams = {}) {
        const { API_URL_BASE, API_QUERY_PARAMS, getQueryParams } = SlackInBrowserService;
        const queryParamString = getQueryParams(
            Object.assign(
                {},
                getQueryParams(),
                API_QUERY_PARAMS,
                queryParams
            )
        );

        return `${API_URL_BASE}/${api}${queryParamString}`;
    }

    static async getSlackInfo(api, args = {}) {
        const { getApiUrl, TOKEN } = SlackInBrowserService;
        const res = await fetch(getApiUrl(api), {
            method: 'POST',
            credentials: 'include',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                token: TOKEN,
                ...args
            })
        });
        const json = await res.json();

        return json;
    }

    static async getUserInfo() {
        const { Apis, getSlackInfo } = SlackInBrowserService;
        const res = await getSlackInfo(Apis.GetUserInfo);
        const {
            user: {
                name: username,
                id: userId
            },
            team: {
                id: teamId
            }
        } = res;

        return {
            username,
            userId,
            teamId,
        };
    }

    /**
     * @param {(Object|string)} channelName - Channel to search for.
     *                                        If a string is passed, it will be treated as the channel name;
     *                                        if searching by ID, specify it manually.
     * @param {string} channelName.id
     * @returns {Promise<Channel>}
     */
    static async getChannelInfo(channelName) {
        const { Apis, getSlackInfo } = SlackInBrowserService;

        if (typeof channelName === typeof '') {
            /* search for channel ID from all channels in the server */
            const res = await getSlackInfo(Apis.GetAllChannelsInServer);
            const {
                /** @type {Channel[]} */
                channels
            } = res;

            return channels.find(channel => channel.name === channelName);
        }

        const { id: channelId } = channelName;

        const res = await getSlackInfo(Apis.GetChannelInfo, { channel: channelId });

        return res.channel;
    }

    /**
     * @param {(Object|string)} channelName - Channel whose members to get.
     *                                        If a string is passed, it will be treated as the channel name;
     *                                        if searching by ID, specify it manually.
     * @param {string} channelName.id
     * @returns {Promise<Member>}
     */
    static async getMembersOfChannel(channelName) {
        const { Apis, getSlackInfo, getChannelInfo } = SlackInBrowserService;

        /** @type {Channel} */
        const channel = await getChannelInfo(channelName);
        const { id: channelId, shared_team_ids: teamIds } = channel;

        const membersRes = await getSlackInfo(Apis.GetChannelMembers, { channel: channelId });
        /** @type {Set<string>} */
        const memberIds = new Set(membersRes.members);

        const allUsersWhoCanAccessChannelRes = await Promise.all(teamIds.map(teamId => getSlackInfo(Apis.GetAllUsers, { team_id: teamId })));
        const allUsersWhoCanAccessChannel = allUsersWhoCanAccessChannelRes.flatMap(({ members }) => members);

        const members = allUsersWhoCanAccessChannel.filter(user => memberIds.has(user.id));

        return members.map(user => ({ id: user.id, name: user.name }));
    }
};

window.SlackInBrowserService = SlackInBrowserService;



/************************************************
 ********    Video manipulation tools    ********
 ***********************************************/
function videoArrowKeyListener(event, {
    video = window.video || document.querySelector('video'),
} = {}) {
    let seekSpeed = 5;
    let volumeSpeed = 0.05;

    const exitFullScreen = () => {
        document.exitFullscreen?.() ?? window.exitFullscreen?.();
    };

    switch(event.key) {
        case ' ':
            if (video.paused) {
                video.play();
            } else {
                video.pause();
            }

            break;
        case 'ArrowLeft':
            video.currentTime -= seekSpeed;
            break;
        case 'ArrowRight':
            video.currentTime += seekSpeed;
            break;
        case 'ArrowUp':
            if (event.shiftKey) {
                seekSpeed++;
            } else if (event.ctrlKey && video.gain) {
                video.gain.value++;
            } else {
                video.volume += volumeSpeed;
            }
            break;
        case 'ArrowDown':
            if (event.shiftKey) {
                seekSpeed--;
            } else if (event.ctrlKey && video.gain) {
                video.gain.value--;
            } else {
                video.volume -= volumeSpeed;
            }
            break;
        case 'Escape':
            exitFullScreen();
            break;
        case 'f':
            /* See: https://developer.mozilla.org/en-US/docs/Web/API/Fullscreen_API#methods_on_the_document_interface */
            if (document.fullscreen || document.fullscreenElement || window.fullscreen || window.fullscreenElement) {
                exitFullScreen();
            } else {
                self?.video?.requestFullscreen?.();
            }
            break;
        case 'Enter':
            /* TODO Press "Skip intro" button.
             * We'd have to find an element where any attribute it contains either has a name or value of
             * /Skip(?!\s*\d+\s*(ms|sec|forward|backward|rewind))/i
             * so we can grab "Skip intro" or just "Skip" without grabbing "Skip 10 sec forward" or similar.
             *
             * See:
             * - getElementAttributes()
             * - findElementsByAnything()
             */
            const { origin } = new URL(self.location.href);
            let skipIntroButton;

            if (origin.match(/hulu\.com/i)) {
                skipIntroButton = findElementsByAnything(node => (
                    node.tagName.match(/button/i)
                    && node.innerText?.match(/skip intro/i)
                ))?.[0];

                skipIntroButton.click();
            }
            break;
    }
}
;

window.getVolumeThatCanSurpass1 = function getVolumeThatCanSurpass1(video = window.video || document.querySelector('video')) {
    try {
        /* https://stackoverflow.com/a/43794379/5771107 */
        const audioCtx = new AudioContext();
        const audioSource = audioCtx.createMediaElementSource(video);
        const audioGain = audioCtx.createGain();
        audioSource.connect(audioGain);
        audioGain.connect(audioCtx.destination);
        video.gain = audioGain.gain;
    } catch (e) {
        console.error('Error creating volume that could surpass 100%:', e);
    }
};

window.videoArrowKeyListenerExec = function videoArrowKeyListenerExec(video = window.video || document.querySelector('video')) {
    /* useful video seek arrow functionality for video players that don't include it automatically */

    const isHboMax = !!location.origin.match(/hbomax/i);

    if (!isHboMax) {
        getVolumeThatCanSurpass1();
    }

    window.addEventListener('keydown', videoArrowKeyListener);
    /* Adding the event listener to `window` means that the keys work even if the `<video/>` isn't focused by the user.
     * Though, in case the above doesn't work, you could try adding it to (a child of) `document`. */
    /* document.body.addEventListener('keydown', videoArrowKeyListener); */
};

window.setInnerHtmlToVideoWithSrc = function(src = null, removeReferrerHeader = false) {
    /* first, erase document content */
    document.body.parentElement.innerHTML = '';

    let srcUrl = src;

    if (!src) {
        srcUrl = prompt('Video src URL:');
    }

    if (removeReferrerHeader) {
        setDocumentReferer();
    }

    const video = document.createElement('video');
    video.controls = true;
    video.autoplay = true;
    video.src = srcUrl;

    document.body.appendChild(video);

    videoArrowKeyListenerExec();
};

window.getVideoSrcFromHtml = function(html) {
    const videoTagRegex = /<video[\w\W]*<\/video>/;
    const srcContentRegex = /(?<=src=")[^"]+(?=")/;

    try {
        return html.match(videoTagRegex)[0].match(srcContentRegex)[0];
    } catch (e) {
        return false;
    }
};


/*********************************
 ****    WatchCartoonOnline    ***
 ********************************/
window.getVideoFromWatchCartoonOnline = async function() {
    const videoDivSecretVar = document.body.innerHTML.match(/document.write[^;]+/)[0]
                        .match(/(?<=\()\w+(?=\))/)[0];
    const videoDiv = window[videoDivSecretVar];
    const videoPhpSrc = videoDiv.match(/(?<=src=")[^"]+/)[0];
    const res = await fetch(videoPhpSrc);
    const videoPhpHtml = await res.text();
    const secretVideoSrcUrl = videoPhpHtml.match(/(?<=getJSON\(")[^"]+/)[0];
    /* jquery is already loaded */
    return new Promise(
        resolve => {
            $.getJSON(secretVideoSrcUrl, response => {
                const videoUrlId = response.hd || response.enc;
                const videoUrlServer = response.server;
                const videoUrl = `${videoUrlServer}/getvid?evid=${videoUrlId}`;

                resolve(videoUrl);
            });
        },
        reject => 'Could not obtain video URL'
    );
};



/*********************************
 ********    Kissanime    ********
 ********************************/
window.goToNextKissanimeEpisode = function() {
    const queryParam = window.location.href.match(/(?<=s=).+/g)[0];
    window.location.href = `${document.getElementById('btnNext').parentNode.href}&s=${queryParam}`;
};

/**
 * Rapidvideo.com nests <source /> elements inside <video />
 * each with a 'data-res' field containing the resolution.
 * Get the best one here
 */
window.getHighestResVideoFromRapidVideoHtml = function(htmlText) {
    const videoTagRegex = /<video[\w\W]*<\/video>/;
    const sourceTagRegex = /<source[\w\W]*?>/g;
    const sourceSrcRegex = /(?<=source src=")[^"]*(?=")/;
    const resolutionRegex = /(?<=data-res=")[^"]*(?=")/;

    const videoTag = htmlText.match(videoTagRegex)[0];
    const sourceTags = videoTag.match(sourceTagRegex);
    const videoMapping = sourceTags.map(sourceTag => {
        const resolution = Number(sourceTag.match(resolutionRegex)[0]);
        const srcUrl = sourceTag.match(sourceSrcRegex)[0];

        return { resolution, srcUrl};
    }).sort((a, b) => b.resolution - a.resolution);

    return videoMapping[0];
};

window.getVideoFromRapidvideo = function(commonHostPromise) {
    /* if run on the rapidvideo site itself */
    if (commonHostPromise == null) {
        const videoSrc = getHighestResVideoFromRapidVideoHtml(document.body.innerHTML).srcUrl;
        console.log(videoSrc);
        return Promise.resolve(videoSrc);
    }

    return commonHostPromise
        .then(html => {
            const videoSrc = getHighestResVideoFromRapidVideoHtml(html).srcUrl;
            console.log(videoSrc);
            return videoSrc;
        });
};

window.getVideoFromMp4upload = function(commonHostPromise) {
    function getVideoSrc(html) {
        const videoInfo = html.match(/(?<=video\|)\w+\|\d+/g)[0];
        const wwwPrefix = html.match(/www\d\d/g)[0];
        const [url, port] = videoInfo.split('|');
        const videoSrc = `https://${wwwPrefix}.mp4upload.com:${port}/d/${url}/video.mp4`;

        console.log(videoSrc);
        return videoSrc;
    }

    function setDocumentToSrcWithSpoofedRefererHeader(videoSrc) {
        /* navigating to mp4upload video URL tries to download for some reason
         * so just replace current html with <video src={videoSrc} />
         *
         * Note that we must remove the referrer header since it is `kissanime.com`
         * and the referrer must either be mp4upload or null. Null is easier, so
         * let's do that. Luckily, setInnerHtmlToVideoWithSrc() accepts an optional
         * 'remove referrer' option.
         */
        setInnerHtmlToVideoWithSrc(videoSrc, true);

        /* rejecting with `true` prevents the final `alert()` in getVideoFromKissanimeUrl() */
        return Promise.reject(true);
    }

    return commonHostPromise
        .then(getVideoSrc)
        .then(setDocumentToSrcWithSpoofedRefererHeader);
};

window.getVideoUrlFromNovelplanet =  novaUrl => {
    const hostBaseName = 'novelplanet';
    const novaVideoRetrievalApiPath = '/api/source/';
    const domainVideoSeparatorRegex = new RegExp(`${hostBaseName}([^/]+)/[^/]+/(.*)`); /* e.g. 'https://www.novelplanet.me/v/yxv3gg6pqol' */
    const [ fullUrl, topLevelDomain, videoHashIdentifier ] = novaUrl.match(domainVideoSeparatorRegex);
    const novaVideoRetrievalApiUrl = 'https://www.' + hostBaseName + topLevelDomain + novaVideoRetrievalApiPath + videoHashIdentifier;

    return fetch(novaVideoRetrievalApiUrl, { method: 'POST' }) /* credentials defaults to 'same-origin' */
        .then(res => res.json())
        /* sort in descending order from e.g. `label: '1080p'` */
        .then(json => json.data.sort((obj1, obj2) => parseInt(obj2.label, 10) - parseInt(obj1.label, 10)))
        .then(sortedVideoDataInfo => sortedVideoDataInfo[0].file);
};

/**
 * Gets the mp4 file's URL from the nested Rapidvideo iframe
 * at a given kissanime.ru URL.
 *
 * URL must contain the 's' query param
 */
window.getVideoFromKissanimeUrl = function(url = window.location.href) {
    const getIframeVideoHostUrlRegex = iframeHost => new RegExp(`(?<=src=")[^"]*${iframeHost}[^"]*(?=")`, 'g');

    function getVideoIframeUrl(iframeHost) {
        return fetch(url)
            .then(res => res.text())
            .then(html => html.match(getIframeVideoHostUrlRegex(iframeHost))[0]);
    }

    function getCommonHostPromise(kissanimeUrlParam = getQueryParams()['s']) {
        return getVideoIframeUrl(kissanimeUrlParam)
            .catch(e => open(document.querySelector('iframe#my_video_1').src))
            .then(mp4Url => fetchCors(mp4Url))
            .then(res => res.text());
    }

    if (url.includes('rapidvid')) { /* rapidvideo.com && rapidvid.to */
        /* first, try to get video from kissanime.com
         * if that doesn't work, open rapidvideo url in new tab and try again using innerHTML
         */
        if (!url.includes('kissanime')) {
            return getVideoFromRapidvideo(Promise.resolve(document.body.innerHTML));
        }

        return getVideoFromRapidvideo(getCommonHostPromise());
    }

    if (url.includes('mp4upload')) {
        return getVideoFromMp4upload(getCommonHostPromise());
    }

    if (url.includes('nov')) {
        if (url.includes('kissanime')) {
            return getVideoIframeUrl('novelplanet').then(url => window.location.href = url);
        }

        return getVideoUrlFromNovelplanet(url).then(videoUrl => window.location.href = videoUrl);
    }

    /* Last-ditch effort: try to parse html for video src content */

    const videoSrcFromDocument = getVideoSrcFromHtml(document.body.innerHTML);

    if (videoSrcFromDocument) {
        return Promise.resolve(videoSrcFromDocument);
    }

    return Promise.reject('Error: Video URL could not be obtained');
};

/**
 * Downloads all the episodes of a given series from kissanime.ru
 * Call the function after searching for your video and coming upon the
 * episode-list page
 */
window.downloadAllKissanimeEpisodes = function(start, end) {
    const episodesDiv = document.getElementsByClassName('episodeList')[0];
    const episodeList = episodesDiv.getElementsByTagName('a');
    let episodeLinks = Array.from(episodeList).reduce((viableLinks, currentLink) => {
        /* Remove 'Bookmark', 'Hide', and other undesirable links */
        if (currentLink.text && currentLink.text.includes('Episode')) {
            viableLinks.push(currentLink);
        }
        return viableLinks;
    }, []).reverse(); /* put in order */

    if (start && !end) {
        end = start;
    }

    start = start - 1 || 0;
    end = end || episodeLinks.length;
    episodeLinks = episodeLinks.slice(start, end);

    const videoRequests = episodeLinks.map(a => ({
        name: a.innerText.trim().replace(/\(Sub\) /, ''),
        request: getVideoFromKissanimeUrl(a.href) /* TODO add &s=urlParam */
    }));

    Promise.all(videoRequests.map(episode => episode.request)).then(videoUrls => {
        const downloadCommands = [];

        videoRequests.forEach((video, i) => {
            video.url = videoUrls[i];
            if (window.navigator.platform.includes('Win')) {
                /* windows; write bash command */
                downloadCommands.push("bash -c \"wget -O '/mnt/c/Users/djp93/Downloads/" +
                            video.name + ".mp4' '" + video.url + "'\"");
            } else {
                /* bash */
                downloadCommands.push("wget -O '/mnt/c/Users/djp93/Downloads/" +
                            video.name + ".mp4' '" + video.url + "'");
            }
        });

        const downloadAnchor = document.createElement('a');
        downloadAnchor.download = 'DownloadScript.txt';
        downloadAnchor.href = 'data:text/plain;charset=utf-8,' + encodeURIComponent(downloadCommands.join(' && '));
        downloadAnchor.click();
    });
};



/***********************************************
 ***  Calling function in separate bookmark  ***
 ***********************************************/


/*
videoArrowKeyListenerExec();  /* Video controls */
/*
getVolumeThatCanSurpass1();  /* Volume to surpass 1 */
/*
getVideoFromKissanimeUrl(window.location.href)
    .then(videoUrl => window.location.href = videoUrl)
    .catch(message => {
        if (message !== true) {
            alert(message);
        }
    }); /* if message === true, then setInnerHtmlToVideoWithSrc() is called, so don't alert */
/*
getVideoFromWatchCartoonOnline()
    .then(videoUrl => window.location.href = videoUrl)
    .catch(alert); /* Get video from watchcartoononline */
/*
setInnerHtmlToVideoWithSrc();  /* Set document to <video /> */
/*
goToNextKissanimeEpisode();  /* Next Kissanime */

/*
githubToggleAllFilesChangedCollapsedStatus();  /* toggle "Files changed" tab so they can be viewed easier */
/*
githubToggleAllTestsCollapsedStatus(); /* toggle all tests/snapshots */
/*
githubToggleAllSnapshotsViewedStatus(); /* toggle only snapshots */

})();
