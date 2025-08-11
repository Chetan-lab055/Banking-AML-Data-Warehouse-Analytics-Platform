-- Star schema for analytics (OLAP)
-- Fact table stores transactions (denormalized and pre-aggregated columns for speed)

CREATE SCHEMA IF NOT EXISTS warehouse;

CREATE TABLE IF NOT EXISTS warehouse.dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    weekday INT,
    week INT
);

CREATE TABLE IF NOT EXISTS warehouse.dim_account (
    account_sk SERIAL PRIMARY KEY,
    account_id TEXT,
    customer_id TEXT,
    account_type TEXT,
    country TEXT
);

CREATE TABLE IF NOT EXISTS warehouse.dim_merchant (
    merchant_sk SERIAL PRIMARY KEY,
    merchant_id TEXT,
    name TEXT,
    category TEXT,
    country TEXT
);

CREATE TABLE IF NOT EXISTS warehouse.fact_transactions (
    fact_id BIGSERIAL PRIMARY KEY,
    transaction_id TEXT,
    account_sk INT REFERENCES warehouse.dim_account(account_sk),
    merchant_sk INT REFERENCES warehouse.dim_merchant(merchant_sk),
    date_id DATE,
    amount NUMERIC(15,2),
    currency CHAR(3),
    channel TEXT,
    is_suspicious BOOLEAN,
    risk_score NUMERIC,
    created_at TIMESTAMP DEFAULT now()
);

-- Partitioning suggestion (by date)
-- CREATE TABLE warehouse.fact_transactions_y2025 PARTITION OF warehouse.fact_transactions FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
