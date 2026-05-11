#!/usr/bin/env node

import { execSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';

function cmd(cmdStr) {
    return execSync(cmdStr, {
        shell: '/opt/homebrew/bin/bash',
        stdio: 'inherit',
    })
        // .toString()
        // .replace(/\n/g, '');
}



async function testGraphQl() {
    return
// await (await fetch('https://apollo-router-internal-idknsumb.dev.foundation.gsg.pub/', {
await (await fetch('http://localhost:5001', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        // GraphQL Headers for dev
        'x-gsg-user-role': 'MEMBER',
        'x-gsg-user-id': '019c23aa-3d0c-7089-86f1-eacbb5280d48',
        'gsg-identity-payload': 'eyJpc3MiOiJodHRwczovL2tleWNsb2FrLmV4YW1wbGUuY29tL2F1dGgvcmVhbG1zL2Q3NjJiNjFjNDM1NTRhYjZiNzk1ODYwNjU2MjM4OWY1Iiwic3ViIjoiMDE5YzIzYWItZWY5My03NTNjLThiYTgtYzE3Yjc3YmJhOTFlIiwiYXpwIjoid2Vic2l0ZSIsInJlc291cmNlX2FjY2VzcyI6eyJwdWJsaWMtYXBpIjp7InJvbGVzIjpbInJlYWQ6dXNlciIsInJlYWQ6bGVkZ2VyOm9wZXJhdGlvbjphbGwiLCJyZWFkOmxlZGdlcjpvcGVyYXRpb24taGlzdG9yeTphbGwiLCJyZWFkOndhbGxldDo6YWxsIl19fX0=',
    },
    body: JSON.stringify({
        query: `
        query UserLedgerFilter($clientId: ID) {
            userLedgerFilter(clientId: $clientId) {
                sources {
                    value
                    label
                }
                statuses {
                    value
                    label
                }
                retailers {
                    idClient
                    idPool
                }
            }
        }
        `,
        variables: {
            // userId: '019c23aa-3d0c-7089-86f1-eacbb5280d48',
            clientId: 'd762b61c43554ab6b7958606562389f5',
        },
    }),
})).json();
}



const igraalPolandInfo = {
    clientId: 'f9f4557825c74791ac01dc5c72ef7aef',
    memberId: '7aa698b5-6ae5-4047-af1a-471b5eb6c81f',
    userId: '7aa698b5-6ae5-4047-af1a-471b5eb6c81f',
};

const igraalGermanyInfo = {
    clientId: 'c235ee8b371f4e8b8e392330ea359875',
    memberId: '510fcd50-890d-465d-890e-dcc6d9f53996',
};

const igraalFranceInfo = {
    clientId: 'a444a51901d85f3d9eb84ada70cef7f3',
    memberId: '1a43024a-12de-4586-accc-94814ccc7793',
    userId: '1a43024a-12de-4586-accc-94814ccc7793',
};

const locale = 'PL';

const topupAccountBody = {
    amount: {
        amount: '100',
        currency: locale === 'PL' ? 'PLN' : 'EUR',
    },
    clientId: (locale === 'PL' ? igraalPolandInfo : igraalGermanyInfo).clientId,
    memberId: (locale === 'PL' ? igraalPolandInfo : igraalGermanyInfo).memberId,
    metadata: {},
    referenceDate: new Date().toISOString(),
    referenceId: randomUUID(),
    referenceMessage: 'Manual top-up',
    source: 'acquisition_welcome_bonus',
    // threadId: '',
};

const message = {
    id: randomUUID(),
    name: 'command.ledger.request-and-approve-deposit.v4',
    source: 'ssp-ledger-service-app',
    timestamp: new Date().toISOString(),
    type: 'COMMAND',
    body: topupAccountBody,
};


function topupAccount() {
    return cmd(`source $HOME/.profile && sendSqsMessageInLocalstack '${JSON.stringify(message)}'`);
}

topupAccount();
