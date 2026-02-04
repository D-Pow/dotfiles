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
