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

window.getCookie = function(cookie = document.cookie) {
    return cookie.split('; ').reduce((cookieObj, entry) => {
        const keyVal = entry.split('=');
        const key = keyVal[0];
        let value = keyVal.slice(1).join('=');

        cookieObj[key] = value;

        return cookieObj;
    }, {});
};

window.resetCookie = function() {
    document.cookie = 'expires=Thu, 01 Jan 1970 00:00:01 GMT';
};

window.getUrlQueryParams = function(url = window.location.href) {
    return url.split('?')[1].split('&').reduce((queries, queryString) => {
        const keyVals = queryString.split('=');
        const key = keyVals[0];
        const val = keyVals.slice(1).join('=');

        queries[key] = val;

        return queries;
    }, {});
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
 */
window.fetchCors = function(url, options) {
    const corsAnywhereRequiredHeaders = {
        'X-Requested-With': 'XMLHttpRequest'
    };
    const fetchOptions = options
        ? {
            ...options,
            headers: {
                ...options.headers,
                ...corsAnywhereRequiredHeaders
            }
        } : {
            headers: corsAnywhereRequiredHeaders
        };

    return fetch(
        'https://cors-anywhere.herokuapp.com/' + url,
        {...fetchOptions}
    );
};


/************************************
 ********    GitHub utils    ********
 ***********************************/
window.toggleAllGithubFilesChangedOpenStatus = function() {
    const fileCollapseButtonSelector = 'button[aria-label="Toggle diff contents"]';

    [...document.querySelectorAll(fileCollapseButtonSelector)]
        .forEach(elem => elem.click());
};



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

    function getCommonHostPromise(kissanimeUrlParam = getUrlQueryParams()['s']) {
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
toggleAllGithubFilesChangedOpenStatus();  /* toggle "Files changed" tab so they can be viewed easier */


})();
