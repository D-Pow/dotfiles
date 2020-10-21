// Useful bookmarked functions
javascript:(function setUsefulFunctions() {

window.deepCopyObj = obj => JSON.parse(JSON.stringify(obj));

window.getAllStoriesInPR = () => {
    return [...document.querySelectorAll('tr td.message')].reduce((set, td) => {
        set.add(td.innerText.match(/MAS-\d{3,4}/)[0]);
        return set;
    }, new Set())
};

window.getAxios = () => {
    const s = document.createElement('script');
    s.src = 'https://cdnjs.cloudflare.com/ajax/libs/axios/0.18.0/axios.js';
    document.body.appendChild(s);
};

window.c = content => {
    copy(content);
};

window.getNewAuth = newUserId => {
    return btoa(JSON.stringify({
        anon: false,
        customer: {
            userName: 'ETrade',
            userId: String(newUserId)
        }
    }));
};

window.getAllPortfoliosProducts = () => {
    var deepCopyObj = obj => JSON.parse(JSON.stringify(obj));

    return deepCopyObj($r.props.model.portfolioAllocationResponse).reduce((allPortfolios, portfolio) => {
        const allPortfolioProducts = portfolio.assetGroup.reduce((allProducts, assetGroup) => {
            const allGroupProducts = assetGroup.assetClass.reduce((groupProducts, assetClass) => {
                const assetClassProducts = assetClass.assetSubClass.reduce((assetSubClassProducts, assetSubClass) => {
                    return assetSubClassProducts.concat([...assetSubClass.product]);
                }, []);

                return groupProducts.concat(assetClassProducts);
            }, []);

            return allProducts.concat(allGroupProducts);
        }, []);

        allPortfolios[portfolio.id] = allPortfolioProducts;

        return allPortfolios;
    }, {});
};

})();

// fetch with necessary headers from RequestService
fetch('https://us.sit.etrade.com/phx/mutual_fund_etf/prebuilt_portfolios/public/getETFAllocation', {
    method: 'POST',
    credentials: 'include',
    headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'stk1': pageConfig.uaa_vt
    },
    body: JSON.stringify({
        accountId: "84517794",
        cash: 647,
        portfolioType: "Aggressive",
        productType: "MF"
    })
}).then(res => res.json()).then(console.log)




let designCdnLink = document.createElement('link');
designCdnLink.rel = 'stylesheet';
designCdnLink.href = 'https://cdn.sit.etrade.net/1/wm/20190206/0.0/xeon/edesign-language-latest/edesign-language.css';
document.head.appendChild(designCdnLink);

axios({
    url: 'https://us.sit.etrade.com/aip/getplansummarylist.json?w_id=neo-widgets-AipCenter1',
    method: 'post',
    data: {
        planStatuses: ['0', '1', '2', '3', '4', '9']
    }
}).then(response => {
    console.log(response);
});




/**
 * ADP
 */

// get average overtime
[...document.querySelectorAll('div[data-e2e="total-hours-value"]')].reduce((total, elm) => {
    return total + Number(elm.innerText.replace(/[^\d.]/g, ''));
}, 0) / 11 // 11 = number of paychecks

// get total pay for the year
[...document.querySelectorAll('div[data-e2e="gross-pay-amount"]')].reduce((total, el) => {
    return total + Number(el.textContent.replace(/[^\d.]/g, ''));
}, 0)







// get number of premarket dashboard PRs
let results = {};
Array.from(document.getElementsByClassName('summary')).forEach(entry => {
    const html = entry.outerHTML;
    const members = ['Powell', 'Shivam', 'Deepak', 'Meghan', 'Bilal', 'Geoff'];
    const times = ['Aug', 'Sep', 'Oct'];
    for (let time of times) {
        if (html.includes(time)) {
            if (time === 'Aug' && html[html.indexOf('Aug')-3] === '0') {
                continue;
            }
            for (let member of members) {
                if (html.includes(member)) {
                    let count = results[member] || 0;
                    count++;
                    results[member] = count;
                }
            }
        }
    }
})

/*
Powell: 17
Deepak: 15
Bilal:   8
Meghan:  7
Shivam:  3
 */