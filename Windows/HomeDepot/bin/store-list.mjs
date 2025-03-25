#!/usr/bin/env node

import util from 'node:util';


function sortStores(storeList) {
    return storeList.sort((a, b) => {
        let {
            buyingOfficeNumber: aBuyingOfficeNumber,
            marketNumber: aMarketNumber,
            number: aStoreNumber,
        } = a;
        let {
            buyingOfficeNumber: bBuyingOfficeNumber,
            marketNumber: bMarketNumber,
            number: bStoreNumber,
        } = b;

        if (typeof a === typeof '') {
            ([ aBuyingOfficeNumber, aMarketNumber, aStoreNumber ] = a?.match?.(/(?<=byo|mkt|.st)\d+/gi));
        }

        if (typeof b === typeof '') {
            ([ bBuyingOfficeNumber, bMarketNumber, bStoreNumber ] = b?.match?.(/(?<=byo|mkt|.st)\d+/gi));
        }

        return (
            (Number(aBuyingOfficeNumber) - Number(bBuyingOfficeNumber))
            || (Number(aMarketNumber) - Number(bMarketNumber))
            || (Number(aStoreNumber) - Number(bStoreNumber))
        );
    });
}


async function getAllStores({
    qa = false,
    asString = false,
} = {}) {
    const res = await fetch(`https://thd-store-info-service.apps${qa ? '-np' : ''}.homedepot.com/stores`, {
        headers: {
            Accept: 'application/json',
        },
    });
    const body = await res.json();
    const allStores = sortStores(body);

    if (asString) {
        return allStores.map(({
            countryCode,
            buyingOfficeNumber,
            marketNumber,
            number,
        }) => `${countryCode}.byo${buyingOfficeNumber}.mkt${marketNumber}.st${number}`);
    }

    return allStores;
}


async function lookupStore(storeList, {
    qa = false,
} = {}) {
    const res = await fetch('https://config-repo-helper.apps-np.homedepot.com/getByoAndMkt', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            ENV: 'PR',
            CALLER: 'CV',
            STORES: `${storeList}`,
        }),
    });
    const body = await res.json();

    try {
        let sortedStores = sortStores(body?.result);

        if (sortedStores == null || sortedStores.length === 0) {
            const storeSet = new Set(storeList.split(','));

            sortedStores = (await getAllStores({ qa }))
                .filter(({ number }) => storeSet.has(number))
                .map(({
                    countryCode,
                    buyingOfficeNumber,
                    marketNumber,
                    number,
                }) => `${countryCode}.byo${buyingOfficeNumber}.mkt${marketNumber}.st${number}: Y`);
        }

        return sortedStores;
    } catch (e) {
        console.error(e);
    }

    return body;
}



function parseArgs(args = process.argv, scriptName = import.meta.url.match(/(?<=[\/\\])[^\/]+$/)?.[0]) {
    const argsIndexOfJsFile = args.findIndex(cliArg => cliArg?.match(/\.[mc]?[tj]s[x]?$/));
    const scriptArgs = args.slice(argsIndexOfJsFile + 1);
    const defaultArgs = {
        qa: false,
        help: false,
        args: [],
    }
    const parsedScriptArgs = scriptArgs.reduce((argMap, arg, argIndex, arr) => {
        const nextArg = arr[argIndex + 1];

        switch(arg) {
            case '-t':
            case '--test':
            case '-q':
            case '--qa':
                argMap.qa = true;
                break;
            case '-h':
            case '--help':
                argMap.help = true;
                break;
            default:
                argMap.args.push(arg);
                break;
        }

        return argMap;
    }, defaultArgs);

    if (parsedScriptArgs.help) {
        console.log(`
Usage: ${scriptName} [OPTIONS...] STORE_NUMBERS...

    Outputs full store string matching the format "Country.byoXXXX.mktYYYY.stZZZZ" for adding to config-repo.
    STORE_NUMBERS is comprised of separate args and/or comma-separated list.

    Examples:
        ${scriptName} 123 456 789
        ${scriptName} '123,456,789'
        ${scriptName} 123 '456,789'

Options:
    -q,-t, --qa,--test      QA/Test store instead of production store.
    -h, --help              Print this message and exit.
        `);

        process.exit();
        return;
    }

    return parsedScriptArgs;
}

function main() {
    const args = parseArgs();

    lookupStore(args.args.join(','), args)
        .then(res => {
            if (Array.isArray(res)) {
                res.forEach(entry => console.log(entry));
            } else {
                console.log(util.inspect(res, {
                    showHidden: true,
                    depth: null,
                    colors: true,
                }));
            }
        })
        .catch(console.error)
        .finally(() => process.exit());
}

main();
