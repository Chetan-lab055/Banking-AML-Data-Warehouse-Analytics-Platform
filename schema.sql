-- OLTP (normalized) schema for transaction ingestion
-- Use PostgreSQL 14+

CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT PRIMARY KEY,
    name TEXT,
    date_of_birth DATE,
    country TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id TEXT PRIMARY KEY,
    customer_id TEXT REFERENCES customers(customer_id),
    account_type TEXT,
    opened_at TIMESTAMP,
    status TEXT
);

CREATE TABLE IF NOT EXISTS merchants (
    merchant_id TEXT PRIMARY KEY,
    name TEXT,
    category TEXT,
    country TEXT
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id TEXT PRIMARY KEY,
    account_id TEXT REFERENCES accounts(account_id),
    merchant_id TEXT REFERENCES merchants(merchant_id),
    amount NUMERIC(15,2),
    currency CHAR(3),
    timestamp TIMESTAMP,
    channel TEXT,
    status TEXT,
    raw JSONB
);

-- Simple alerts table
CREATE TABLE IF NOT EXISTS alerts (
    alert_id SERIAL PRIMARY KEY,
    transaction_id TEXT,
    account_id TEXT,
    alert_type TEXT,
    score NUMERIC,
    created_at TIMESTAMP DEFAULT now(),
    resolved BOOLEAN DEFAULT FALSE
);
