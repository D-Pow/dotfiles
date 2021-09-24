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

window.getCookie = function getCookie({ cookie = document.cookie, decodeBase64 = true } = {}) {
    return cookie.split('; ').reduce((cookieObj, entry) => {
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

        cookieObj[key] = value;

        return cookieObj;
    }, {});
};

window.resetCookie = function() {
    document.cookie = 'expires=Thu, 01 Jan 1970 00:00:01 GMT';
};

/**
 * Gets URL query parameter entries as either key-value pairs in an object
 * or as a string formatted how they would appear in the URL bar (e.g. `?a=b&c=d`).
 *
 * Defaults to getting the query parameters from the current page's URL as an object.
 * If `fromObj` is specified, then `fromUrl` will be ignored and a string will be returned instead.
 *
 * @param {Object} input
 * @param {string} [input.fromUrl=window.location.search] - URL to get query parameters from; defaults to current page's URL.
 * @param {Object} [input.fromObj] - Object to convert to query parameter string.
 * @returns {Object} - All query param key-value pairs.
 */
function getQueryParams({
    fromUrl = window.location.search,
    fromObj,
} = {}) {
    if (fromObj) {
        const queryParamEntries = Object.entries(fromObj);

        return queryParamEntries.length > 0
            ? `?${
                queryParamEntries
                    .map(([ queryKey, queryValue ]) => `${encodeURIComponent(queryKey)}=${encodeURIComponent(queryValue)}`)
                    .join('&')
            }`
            : '';
    }

    const urlSearchQuery = fromUrl.split('?')[1];

    return [...new URLSearchParams(urlSearchQuery).entries()]
        .reduce((queryParams, nextQueryParam) => {
            const [ key, value ] = nextQueryParam;
            queryParams[key] = value;
            return queryParams;
        }, {});
}

window.getQueryParams = getQueryParams;

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


/************************************
 ********    Website utils    *******
 ***********************************/
window.githubGetAllFilesChangedByName = function(nameRegex = /./, onlyFileName = false) {
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
        viewedToggle = false
    } = {}
) {
    const fileCollapseButtonSelector = 'button[aria-label="Toggle diff contents"]';
    const viewedToggleButtonElementSelector = '.file-actions .js-replace-file-header-review label';

    const matchingFilesChanged = githubGetAllFilesChangedByName(nameRegex);

    matchingFilesChanged.forEach(({ fileElement }) => {
        if (collapsedToggle) {
            fileElement.querySelector(fileCollapseButtonSelector).click();
        }

        if (viewedToggle) {
            fileElement.querySelector(viewedToggleButtonElementSelector).click();
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
}

window.translateJapanese = translateJapanese;


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
    static TOKEN = 'xoxc-2151647278-2165858577591-2209341454208-707234e4c1034456af547e192cc56e1335ed1d229adce81bc1cca33414d63789';
    /* Get from dev tools - api.slack.com isn't necessarily used, sometimes a company-specific URL is used instead */
    static API_URL_BASE = 'https://nextdoor.slack.com/api';
    /* not sure what this is or why it's needed, but CORS errors are thrown if it's not present (at least at Nextdoor) */
    static API_QUERY_PARAMS = {
        _x_gantry: true
    };

    /*
     * See: https://api.slack.com/methods
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
     * @param {Object} input
     * @param {string} [input.fromUrl=window.location.search] - URL to get query parameters from; defaults to current page's URL.
     * @param {Object} [input.fromObj] - Object to convert to query parameter string.
     * @returns {Object} - All query param key-value pairs.
     */
    static getQueryParams({
        fromUrl = window.location.search,
        fromObj,
    } = {}) {
        if (fromObj) {
            const queryParamEntries = Object.entries(fromObj);

            return queryParamEntries.length > 0
                ? `?${
                    queryParamEntries
                        .map(([ queryKey, queryValue ]) => `${encodeURIComponent(queryKey)}=${encodeURIComponent(queryValue)}`)
                        .join('&')
                }`
                : '';
        }

        const urlSearchQuery = fromUrl.split('?')[1];

        return [...new URLSearchParams(urlSearchQuery).entries()]
            .reduce((queryParams, nextQueryParam) => {
                const [ key, value ] = nextQueryParam;
                queryParams[key] = value;
                return queryParams;
            }, {});
    }


    static getApiUrl(api = '', queryParams = {}) {
        const { API_URL_BASE, API_QUERY_PARAMS, getQueryParams } = SlackInBrowserService;
        const queryParamString = getQueryParams({
            fromObj: Object.assign({}, getQueryParams(), API_QUERY_PARAMS, queryParams)
        });

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
}

window.SlackInBrowserService = SlackInBrowserService;


/************************************************
 ********    Video manipulation tools    ********
 ***********************************************/
window.getVolumeThatCanSurpass1 = function() {
    /* https://stackoverflow.com/a/43794379/5771107 */
    const audioCtx = new AudioContext();
    const audioSource = audioCtx.createMediaElementSource(document.querySelector('video'));
    const audioGain = audioCtx.createGain();
    audioSource.connect(audioGain);
    audioGain.connect(audioCtx.destination);
    window.volume = audioGain.gain;
};

window.videoArrowKeyListenerExec = function() {
    /* useful video seek arrow functionality for video players that don't include it automatically */
    window.seekSpeed = 5;
    window.video = document.querySelector('video');
    document.onkeydown = event => {
        switch(event.key) {
            case 'ArrowLeft':
                window.video.currentTime -= window.seekSpeed;
                break;
            case 'ArrowRight':
                window.video.currentTime += window.seekSpeed;
                break;
            case 'ArrowUp':
                if (event.shiftKey) {
                    window.seekSpeed++;
                } else if (event.ctrlKey && window.volume) {
                    window.volume.value++;
                }
                break;
            case 'ArrowDown':
                if (event.shiftKey) {
                    window.seekSpeed--;
                } else if (event.ctrlKey && window.volume) {
                    window.volume.value--;
                }
                break;
            case 'f':
                window.video.requestFullscreen();
                break;
        }
    }
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
