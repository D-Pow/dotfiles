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
    let config = configObj || getConfig();

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

window.setConfig = function setConfig(configObj, key, val) {
    if (key) {
        configObj[key] = val;
    }

    const configArray = Object.entries(config).map(([ name, value ]) => ({ name, value }));

    localStorage.setItem('config', JSON.stringify(configArray));

    return configArray;
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

window.searchArtifactory = async function searchArtifactory(pkgRegex = /.*/) {
    const artifactoryMavenUrl = new URL('https://maven.artifactory.homedepot.com/ui/packages');

    if (artifactoryMavenUrl.origin !== location.origin) {
        alert(`This must be run on ${artifactoryMavenUrl.origin}. Opening new tab now...`);
        self.open(artifactoryMavenUrl.toString(), '_blank');
    }

    const res = await fetch('https://maven.artifactory.homedepot.com/ui/api/v1/mds/packages?jfLoader=true', {
        method: 'POST',
        mode: 'cors',
        credentials: 'include',
        headers: {
            accept: 'application/json, text/plain, */*',
            'accept-language': 'en-US,en;q=0.9',
            'content-type': 'application/json',
            'x-requested-with': 'XMLHttpRequest',
        },
        body: JSON.stringify({
            graphQL: {
                query: `query (
                    $filter: PackageFilter!,
                    $first: Int,
                    $orderBy: PackageOrder
                ) {
                    packages (filter: $filter, first: $first, orderBy: $orderBy) {
                        edges {
                            node {
                                id,
                                name,
                                created,
                                modified,
                                versionsCount,
                                description,
                                latestVersion,
                                packageType,
                                stats {
                                    downloads,
                                    followers
                                },
                                licenses {
                                    name,
                                    source
                                },
                                tags,
                                vulnerabilities {
                                    critical,
                                    high,
                                    medium,
                                    low,
                                    info,
                                    unknown,
                                    skipped
                                }
                            }
                        },
                        pageInfo {
                            hasNextPage,
                            endCursor
                        }
                    }
                }`,
                variables: {
                    filter: {
                        name: 'homedepot*'
                    },
                    first: 1000,
                    orderBy: {
                        field: 'NAME',
                        direction: 'ASC'
                    }
                }
            },
        }),
    });
    const { data: { packages: { edges, pageInfo: { hasNextPage }}}} = await res.json();

    const packagesInfo = edges
        .map(({ node }) => node)
        .filter(({ name }) => name.match(pkgRegex));

    return packagesInfo;
};

})();
