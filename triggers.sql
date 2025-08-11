-- Triggers in OLTP to flag alerts on suspicious inserts

-- Simple rule-based check: high amount OR rapid withdrawals
CREATE OR REPLACE FUNCTION public.check_transaction_alert()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    alerted BOOLEAN := FALSE;
    score NUMERIC := 0;
BEGIN
    IF NEW.amount > 10000 THEN
        score := score + 0.7;
        alerted := TRUE;
    END IF;

    -- Check number of transactions from same account in last hour
    PERFORM 1 FROM transactions t WHERE t.account_id = NEW.account_id AND t.timestamp > (NEW.timestamp - interval '1 hour') LIMIT 1;
    IF FOUND THEN
        score := score + 0.2;
        alerted := TRUE;
    END IF;

    IF alerted THEN
        INSERT INTO alerts(transaction_id, account_id, alert_type, score) VALUES (NEW.transaction_id, NEW.account_id, 'RULE_BASED', score);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_alert ON transactions;
CREATE TRIGGER trg_check_alert
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION public.check_transaction_alert();
