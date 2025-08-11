-- Useful analytics queries for dashboards & reporting

-- 1) Top accounts by transaction volume (last 30 days)
WITH recent AS (
  SELECT account_id, SUM(amount) as total_amount
  FROM transactions
  WHERE timestamp >= now() - interval '30 days'
  GROUP BY account_id
)
SELECT * FROM recent ORDER BY total_amount DESC LIMIT 20;

-- 2) Suspicious transactions with context
SELECT a.alert_id, a.transaction_id, a.account_id, a.score, t.amount, t.currency, t.timestamp, m.category
FROM alerts a
JOIN transactions t ON a.transaction_id = t.transaction_id
LEFT JOIN merchants m ON t.merchant_id = m.merchant_id
ORDER BY a.created_at DESC
LIMIT 200;

-- 3) Rolling average of transaction count per account (window function)
SELECT account_id, timestamp::date as day,
       COUNT(*) OVER (PARTITION BY account_id ORDER BY timestamp RANGE BETWEEN '6 days'::interval PRECEDING AND CURRENT ROW) as rolling_7d_count
FROM transactions
ORDER BY account_id, day
LIMIT 100;

-- 4) Materialized view candidate: daily summary
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_summary AS
SELECT date_trunc('day', timestamp) as day,
       count(*) as tx_count, sum(amount) as total_amount,
       sum(CASE WHEN t.amount > 10000 THEN 1 ELSE 0 END) as large_tx
FROM transactions t
GROUP BY 1;

-- 5) Example OLAP query on warehouse
SELECT d.year, d.month, m.category, SUM(f.amount) as total_amount, SUM(CASE WHEN f.is_suspicious THEN 1 ELSE 0 END) as suspicious_count
FROM warehouse.fact_transactions f
JOIN warehouse.dim_date d ON f.date_id = d.date_id
JOIN warehouse.dim_merchant m ON f.merchant_sk = m.merchant_sk
GROUP BY d.year, d.month, m.category
ORDER BY d.year DESC, d.month DESC;
