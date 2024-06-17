#!/usr/bin/env -S node --experimental-top-level-await --experimental-json-modules --experimental-import-meta-resolve

import path from 'path';
import { importGlobalModule } from './NodeUtils';


/**
 * Import the [isomorphic-fetch]{@link https://www.npmjs.com/package/isomorphic-fetch}
 * `fetch` polyfill for easy use in back-end scripts.
 */
await importGlobalModule('isomorphic-fetch');


function getApiUrl(artist, song) {
    return `https://api.lyrics.ovh/v1/${artist}/${song}`;
}


export async function getLyrics(artist, song) {
    try {
        const res = await fetch(getApiUrl(artist, song));
        const json = await res.json();
        const { lyrics } = json;

        const asciiLyrics = lyrics
            .replace(/\r(?=\n)/g, '')  // CRLF => LF
            .replace(/[\u2018\u2019]/g, "'")  // Fancy apostrophe => normal
            .replace(/[\u201C\u201D]/g, '"')  // Fancy double-quote => normal
            .replace(/[\u2013\u2014]/g, '-')  // Fancy dashes => hyphens
            .replace(/\u2026/g, '...')  // Collapsed/single-character ellipses => normal
            .replace(/\n\n/g, '\n');  // Multi-newlines into one for readability

        return asciiLyrics;
    } catch (e) {
        console.error(
            `Could not obtain lyrics for artist "${artist}" and song "${song}"`,
            '\n',
            `Are you sure you spelled it correctly?`,
            '\n',
            e,
        );
    }
}


const thisFileUrl = import.meta.url;
const thisFilePath = new URL(thisFileUrl).pathname;
const thisFileName = path.basename(thisFilePath);

const isMain = !!process.argv?.[1]?.match(new RegExp(`${thisFileName}$`));

if (isMain) {
    const USAGE = `${thisFileName} '<artist>' '<song>'
    Gets the lyrics for the specified artist's song.
    Lyrics will be returned as an ASCII string, replacing all fancy single/double quotes,
    single-char ellipses, dashes, CRLF, etc. with their Unix/ASCII counterparts.

    If the artist or song have spaces in them, surround them with quotes.
    `;

    const [
        nodePath,
        thisFile,
        artist,
        song,
    ] = process.argv;

    if (!artist || !song || (typeof fetch === typeof undefined)) {
        console.log(USAGE);

        process.exit(1);
    }

    const lyrics = await getLyrics(artist, song);

    console.log(lyrics);
}
