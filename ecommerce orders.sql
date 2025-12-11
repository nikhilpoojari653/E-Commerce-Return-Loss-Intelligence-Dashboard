SELECT * FROM ecom_orders;

--- Category return rates
SELECT category,
    COUNT(*) AS total_orders,
    SUM(returned) AS total_returns,
    ROUND((SUM(returned) / COUNT(*)) * 100, 2) AS return_rate,
    SUM(refund_loss) AS total_refund_loss
FROM ecom_orders
GROUP BY category
ORDER BY return_rate DESC;		

--- Return Reason Breakdown for Fashion
SELECT 
    return_reason,
    COUNT(*) AS count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM ecom_orders WHERE category='Fashion' AND returned=1)) * 100, 2) AS percent
FROM ecom_orders
WHERE category='Fashion' AND returned=1
GROUP BY return_reason
ORDER BY count DESC;

--- Delivery Delay Buckets vs Return Probability
SELECT delay_bucket,
    COUNT(*) AS total_orders,
    SUM(returned) AS total_returns,
    ROUND((SUM(returned) / COUNT(*)) * 100, 2) AS return_rate_pct
FROM (SELECT *, CASE
            WHEN delivery_delay_days <= 0 THEN 'On-time'
            WHEN delivery_delay_days BETWEEN 1 AND 3 THEN '1-3 days'
            WHEN delivery_delay_days BETWEEN 4 AND 7 THEN '4-7 days'
            ELSE '>7 days'
        END AS delay_bucket
    FROM ecom_orders
) AS b
GROUP BY delay_bucket
ORDER BY return_rate_pct DESC;

--- Top Risky Sellers (MySQL)
SELECT 
    seller_id,
    COUNT(*) AS orders,
    SUM(returned) AS returns,
    SUM(refund_loss) AS refund_loss,
    ROUND((SUM(returned) / COUNT(*)) * 100, 2) AS return_rate_pct
FROM ecom_orders
GROUP BY seller_id
HAVING orders > 50
ORDER BY return_rate_pct DESC
LIMIT 20;

--- RFM Segments — High Return Customers
CREATE TEMPORARY TABLE rfm AS
SELECT 
    customer_id,
    MIN(recency_days) AS recency,
    SUM(frequency) AS frequency,
    SUM(monetary) AS monetary,
    SUM(returned) AS total_returns,
    COUNT(*) AS orders
FROM ecom_orders
GROUP BY customer_id;

--- Segment by Recency & Frequency
SELECT 
    CASE 
        WHEN recency < 90 THEN 'Recent'
        WHEN recency BETWEEN 90 AND 365 THEN 'Active'
        ELSE 'Cold'
    END AS recency_seg,
    
    CASE 
        WHEN frequency >= 5 THEN 'HighF'
        WHEN frequency BETWEEN 2 AND 4 THEN 'MidF'
        ELSE 'LowF'
    END AS freq_seg,

    COUNT(*) AS customers,
    SUM(total_returns) AS returns,
    ROUND((SUM(total_returns) / SUM(orders)) * 100, 2) AS return_rate_pct
FROM rfm
GROUP BY recency_seg, freq_seg
ORDER BY return_rate_pct DESC;










