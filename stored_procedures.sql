-- Example stored procedures and functions (PL/pgSQL)

-- Function to upsert dim_account and return account_sk
CREATE OR REPLACE FUNCTION warehouse.upsert_account(_account_id TEXT, _customer_id TEXT, _account_type TEXT, _country TEXT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    sk INT;
BEGIN
    SELECT account_sk INTO sk FROM warehouse.dim_account WHERE account_id = _account_id;
    IF sk IS NOT NULL THEN
        UPDATE warehouse.dim_account SET account_type = _account_type, country = _country WHERE account_sk = sk;
        RETURN sk;
    ELSE
        INSERT INTO warehouse.dim_account(account_id, customer_id, account_type, country)
        VALUES(_account_id, _customer_id, _account_type, _country)
        RETURNING account_sk INTO sk;
        RETURN sk;
    END IF;
END;
$$;

-- Similarly upsert merchant
CREATE OR REPLACE FUNCTION warehouse.upsert_merchant(_merchant_id TEXT, _name TEXT, _category TEXT, _country TEXT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    sk INT;
BEGIN
    SELECT merchant_sk INTO sk FROM warehouse.dim_merchant WHERE merchant_id = _merchant_id;
    IF sk IS NOT NULL THEN
        UPDATE warehouse.dim_merchant SET name = _name, category = _category, country = _country WHERE merchant_sk = sk;
        RETURN sk;
    ELSE
        INSERT INTO warehouse.dim_merchant(merchant_id, name, category, country)
        VALUES(_merchant_id, _name, _category, _country)
        RETURNING merchant_sk INTO sk;
        RETURN sk;
    END IF;
END;
$$;

-- Insert transactional fact
CREATE OR REPLACE FUNCTION warehouse.insert_fact_transaction(
    _transaction_id TEXT, _account_id TEXT, _customer_id TEXT, _account_type TEXT,
    _merchant_id TEXT, _merchant_name TEXT, _merchant_cat TEXT, _merchant_country TEXT,
    _date DATE, _amount NUMERIC, _currency CHAR(3), _channel TEXT, _is_suspicious BOOLEAN, _risk_score NUMERIC)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    a_sk INT;
    m_sk INT;
BEGIN
    a_sk := warehouse.upsert_account(_account_id, _customer_id, _account_type, 'IN');
    m_sk := warehouse.upsert_merchant(_merchant_id, _merchant_name, _merchant_cat, _merchant_country);
    INSERT INTO warehouse.fact_transactions(transaction_id, account_sk, merchant_sk, date_id, amount, currency, channel, is_suspicious, risk_score)
    VALUES(_transaction_id, a_sk, m_sk, _date, _amount, _currency, _channel, _is_suspicious, _risk_score);
END;
$$;
