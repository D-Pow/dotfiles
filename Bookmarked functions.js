javascript:(function bookmarkUsefulFunctions() {

/*********************************
 ********    Utilities    ********
 ********************************/
const jsFunctionRegex = '^\(?\s*@?(?!if|constructor|switch|runInAction)(?:async )?(function )?(\w+)(?=(?:\s*=?\s*)\(.*\{[\s\n])';

function sortObjectByKeys(obj) {
    return Object.keys(obj).sort().reduce((sortedObj, key) => {
        sortedObj[key] = obj[key];
        return sortedObj;
    }, {});
}

function getCookie(cookie = document.cookie) {
    return cookie.split('; ').reduce((cookieObj, entry) => {
        const keyVal = entry.split('=');
        const key = keyVal[0];
        let value = keyVal.slice(1).join('=');

        cookieObj[key] = value;

        return cookieObj;
    }, {});
}

function resetCookie() {
    document.cookie = 'expires=Thu, 01 Jan 1970 00:00:01 GMT';
}

function getUrlQueryParams(url = window.location.href) {
    return url.split('?')[1].split('&').reduce((queries, queryString) => {
        const keyVals = queryString.split('=');
        const key = keyVals[0];
        const val = keyVals.slice(1).join('=');

        queries[key] = val;

        return queries;
    }, {});
}



/************************************************
 ********    Video manipulation tools    ********
 ***********************************************/
function getVolumeThatCanSurpass1() {
    /* https://stackoverflow.com/a/43794379/5771107 */
    const audioCtx = new AudioContext();
    const audioSource = audioCtx.createMediaElementSource(document.querySelector('video'));
    const audioGain = audioCtx.createGain();
    audioSource.connect(audioGain);
    audioGain.connect(audioCtx.destination);
    window.volume = audioGain.gain;
}

function videoArrowKeyListenerExec() {
    /* useful arrow functionality for video players that don't include it automatically */
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
}



/*********************************
 ********    Kissanime    ********
 ********************************/
function goToNextKissanimeEpisode() {
    const queryParam = window.location.href.match(/(?<=s=).+/g)[0];
    window.location.href = `${document.getElementById('btnNext').parentNode.href}&s=${queryParam}`;
}

function setInnerHtmlToVideoWithSrc() {
    const srcUrl = prompt('Video src URL:');
    const video = document.createElement('video');
    video.controls = true;
    video.autoplay = true;
    video.src = srcUrl;

    document.body.appendChild(video);
    videoArrowKeyListenerExec();
}

/**
 * Rapidvideo.com nests <source /> elements inside <video />
 * each with a 'data-res' field containing the resolution.
 * Get the best one here
 */
function getHighestResVideoFromHtml(htmlText) {
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
}

/**
 * fetch() using CORS proxy
 */
function fetchCors(url) {
    return fetch(
        'https://cors-anywhere.herokuapp.com/' + url,
            {
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                }
            }
    );
}

function getVideoFromRapidvideo(commonHostPromise) {
    return commonHostPromise
        .then(html => {
            const videoSrc = getHighestResVideoFromHtml(html).srcUrl;
            console.log(videoSrc);
            return videoSrc;
        });
}

function getVideoFromMp4upload(commonHostPromise) {
    return commonHostPromise
        .then(html => {
            const videoInfo = html.match(/(?<=video\|)\w+\|\d+/g)[0];
            const [url, port] = videoInfo.split('|');
            const videoSrc = `https://www11.mp4upload.com:${port}/d/${url}/video.mp4`;

            console.log(videoSrc);
            return videoSrc;
        });
}

/**
 * Gets the mp4 file's URL from the nested Rapidvideo iframe
 * at a given kissanime.ru URL.
 *
 * URL must contain the 's' query param
 */
function getVideoFromKissanimeUrl(url = window.location.href) {
    const kissanimeUrlParam = getUrlQueryParams()['s'];
    const videoHostUrlRegex = new RegExp(`(?<=src=")[^"]*${kissanimeUrlParam}.com[^"]*(?=")`, 'g');
    const commonHostPromise = fetch(url)
        .then(res => res.text())
        .then(html => html.match(videoHostUrlRegex)[0])
        .then(mp4Url => fetchCors(mp4Url))
        .then(res => res.text());

    if (url.includes('rapidvideo')) {
        return getVideoFromRapidvideo(commonHostPromise);
    }

    if (url.includes('mp4upload')) {
        return getVideoFromMp4upload(commonHostPromise);
    }

    return Promise.reject('Error: Video URL could not be obtained');
}

/**
 * Downloads all the episodes of a given series from kissanime.ru
 * Call the function after searching for your video and coming upon the
 * episode-list page
 */
function downloadAllKissanimeEpisodes(start, end) {
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
}



/*************************************************
 ********    Make functions accessible    ********
 ************************************************/
window.sortObjectByKeys = sortObjectByKeys;
window.getCookie = getCookie;
window.resetCookie = resetCookie;
window.getVolumeThatCanSurpass1 = getVolumeThatCanSurpass1;
window.videoArrowKeyListenerExec = videoArrowKeyListenerExec;
window.goToNextKissanimeEpisode = goToNextKissanimeEpisode;
window.setInnerHtmlToVideoWithSrc = setInnerHtmlToVideoWithSrc;
window.getHighestResVideoFromHtml = getHighestResVideoFromHtml;
window.fetchCors = fetchCors;
window.getUrlQueryParams = getUrlQueryParams;
window.getVideoFromRapidvideo = getVideoFromRapidvideo;
window.getVideoFromMp4upload = getVideoFromMp4upload;
window.getVideoFromKissanimeUrl = getVideoFromKissanimeUrl;
window.downloadAllKissanimeEpisodes = downloadAllKissanimeEpisodes;


/*
videoArrowKeyListenerExec();  /* Video controls */
/*
getVolumeThatCanSurpass1();  /* Volume to surpass 1 */
/*
getVideoFromKissanimeUrl(window.location.href).then(alert).catch(alert); /* Get this Kissanime video URL */
/*
setInnerHtmlToVideoWithSrc();  /* Set document to <video /> */
/*
goToNextKissanimeEpisode();  /* Next Kissanime */


})();

// Fetch API: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
// Fetch API + CORS: https://developers.google.com/web/ilt/pwa/working-with-the-fetch-api
// Using CORS proxy: https://stackoverflow.com/a/43268098/5771107
// CORS proxy: https://cors-anywhere.herokuapp.com/ + URL (e.g. https://www.rapidvideo.com/e/FUM5608RR8)
// headers: {
//     'X-Requested-With': 'XMLHttpRequest',
//     // rest aren't needed
//     'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
//     'Accept-Encoding': 'gzip, deflate, br',
//     'Accept-Language': 'en-US,en;q=0.9',
//     'Cache-Control': 'no-cache',
//     'Connection': 'keep-alive',
//     // 'Cookie': '__cfduid=d898329e93f1e1c34153c5202cb6e38f51528459175; _ym_uid=1558315021152344108; _ym_d=1558315021; PHPSESSID=2tak4cckqftdssa9b6lgn11gu6; _ym_isad=2; last_watched=FUUCN2549A',
//     'DNT': '1',
//     'Host': 'www.rapidvideo.com',
//     'Pragma': 'no-cache',
//     'Referer': 'https://kissanime.ru/Anime/Boku-no-Hero-Academia-3rd-Season/Episode-059?id=149673&s=rapidvideo',
//     'Upgrade-Insecure-Requests': '1',
//     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36'
// }
