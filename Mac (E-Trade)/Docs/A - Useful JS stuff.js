getAxios() {
    const s = document.createElement('script');
    s.src = 'https://cdnjs.cloudflare.com/ajax/libs/axios/0.18.0/axios.js';
    document.body.appendChild(s);
}

c(content) {
    copy(content);
}

getNewAuth(newUserId) {
    return btoa(JSON.stringify({
        anon: false,
        customer: {
            userName: 'ETrade',
            userId: String(newUserId)
        }
    }));
}

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