javascript:(function hdBookmarkUsefulFunctions() {

window.mapConfigToObj = function mapConfigToObj(configAsArray) {
    if (
        typeof configAsArray !== typeof []
        || !Array.isArray(configAsArray)
    ) {
        return null;
    }

    return configAsArray.reduce((obj, entry) => {
        let name, value;

        if (Array.isArray(entry)) {
            [ name, value ] = entry;
        } else if (typeof entry === typeof {}) {
            ({ name, value } = entry);
        }

        if (name) {
            obj[name] = value;
        }

        return obj;
    }, {});
};

window.searchConfig = function searchConfig(configObj, keyRegex, valRegex) {
    let config = configObj;

    if (keyRegex) {
        config = Object.entries(config)
            .filter(([ key, val ]) => key?.match?.(keyRegex));
        config = mapConfigToObj(config);
    }

    if (valRegex) {
        config = Object.entries(config)
            .filter(([ key, val ]) => val?.match?.(keyRegex));
        config = mapConfigToObj(config);
    }

    return config;
};

window.getConfig = function getConfig(keyRegex, valRegex) {
    if (!localStorage.hasOwnProperty('config')) {
        return null;
    }

    let config = JSON.parse(localStorage.getItem('config'));
    config = mapConfigToObj(config);

    if (keyRegex || valRegex) {
        config = searchConfig(config, keyRegex, valRegex);
    }

    return config;
};

window.config = getConfig();

window.fetchConfig = async function fetchConfig(keyRegex, valRegex) {
    /* Domain: https://ui-store-checkout-uat.apps-np.homedepot.com */
    const res = await fetch('/parameters/US/st9307?lcp=QA', {
        credentials: 'include',
        headers: {
            Uuid: 'NA',
        },
    });
    const json = await res.json();

    let config = mapConfigToObj(json.parameters);

    if (keyRegex || valRegex) {
        config = searchConfig(config, keyRegex, valRegex);
    }

    return config;
};

})();
