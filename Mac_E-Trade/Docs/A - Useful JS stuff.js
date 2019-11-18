// Useful bookmarked functions
javascript:(function setUsefulFunctions() {

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

/* Copied from "Bookmarked functions.js" */
const jsFunctionRegex = '^\(?\s*@?(?!if|constructor|switch|runInAction)(?:async )?(function )?(\w+)(?=(?:\s*=?\s*)\(.*\{[\s\n])';

window.sortObjectByKeys = (obj) => {
    return Object.keys(obj).sort().reduce((sortedObj, key) => {
        sortedObj[key] = obj[key];
        return sortedObj;
    }, {});
};

window.getCookie = (cookie = document.cookie) => {
    return cookie.split('; ').reduce((cookieObj, entry) => {
        const keyVal = entry.split('=');
        const key = keyVal[0];
        let value = keyVal.slice(1).join('=');

        cookieObj[key] = value;

        return cookieObj;
    }, {});
};

window.resetCookie = () => {
    document.cookie = 'expires=Thu, 01 Jan 1970 00:00:01 GMT';
};

window.getUrlQueryParams = (url = window.location.href) => {
    return url.split('?')[1].split('&').reduce((queries, queryString) => {
        const keyVals = queryString.split('=');
        const key = keyVals[0];
        const val = keyVals.slice(1).join('=');

        queries[key] = val;

        return queries;
    }, {});
};

})()

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






// get average overtime
[...document.querySelectorAll('div[data-e2e="total-hours-value"]')].reduce((total, elm) => {
    return total + Number(elm.innerText.replace(/[^\d.]/g, ''));
}, 0) / 11 // 11 = number of paychecks







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