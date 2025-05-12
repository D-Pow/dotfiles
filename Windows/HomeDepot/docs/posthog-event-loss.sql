WITH ReceivedEventCount AS (
    SELECT
        properties.transactionId,
        COUNT(*) as eventCount,
    FROM events
    WHERE 1=1
        AND timestamp >= (
            CASE
                WHEN {variables.from} NOT IN (NULL, '') THEN toDate({variables.from})
                WHEN {variables.to} NOT IN (NULL, '') THEN toDate({variables.to}) - INTERVAL 7 DAY
                ELSE now() - INTERVAL 7 DAY
            END
        )
        AND timestamp <= (
            CASE
                WHEN {variables.to} NOT IN (NULL, '') THEN toDate({variables.to})
                ELSE now()
            END
        )
        AND properties.transactionId NOT IN (NULL, '', 'No Transaction')
        AND event != 'Start Self Service'
        -- AND properties.transactionVoid = 'false'
        -- AND properties.isSelfCheckoutMode = 'true'
    GROUP BY properties.transactionId
), (
    SELECT
        ReceivedEventCount.transactionId,
        toInt(ReceivedEventCount.eventCount) as receivedEventCount,
        toInt(events.properties.analyticsEventCount) as expectedEventCount,
        CASE
            WHEN (ReceivedEventCount.eventCount / toInt(events.properties.analyticsEventCount)) > 1 THEN 1
            ELSE ReceivedEventCount.eventCount / toInt(events.properties.analyticsEventCount)
        END AS percentReceived,
        events.timestamp,
        formatDateTime(timestamp, '%c-%d-%Y') as ts, -- %c-%d-%Y %H:%i:%s
    FROM
        ReceivedEventCount JOIN events
        ON (ReceivedEventCount.transactionId = events.properties.transactionId)
    WHERE 1=1
        AND events.event = 'Transaction Completed'
        AND events.properties.analyticsEventCount NOT IN (NULL, 0)
    ORDER BY events.timestamp DESC
) AS EventCounts
SELECT
    AVG(receivedEventCount) AS receivedEventCountAvg,
    AVG(expectedEventCount) AS expectedEventCountAvg,
    AVG(percentReceived) AS percentReceivedAvg,
    ts,
FROM EventCounts
GROUP BY ts
ORDER BY toDateTime(ts) ASC
