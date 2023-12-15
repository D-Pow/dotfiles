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

    const specifiedCreds = await getCreds(app, ...args);

    log(specifiedCreds);
}
