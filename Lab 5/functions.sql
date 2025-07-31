CREATE OR REPLACE FUNCTION f_get_services_count(p_agreement_id INTEGER)
RETURNS INTEGER
AS $$
DECLARE
    v_services_count INT;
BEGIN
    SELECT COUNT(*) INTO v_services_count
    FROM agreements AS ag
	JOIN agreementservices AS asr ON ag.agreement_id = asr.agreement_id
    WHERE ag.agreement_id = p_agreement_id;

    RETURN v_services_count;
END;
$$ LANGUAGE plpgsql;

SELECT *, f_get_services_count(agreement_id) AS services_count FROM agreements;

CREATE OR REPLACE FUNCTION f_get_dynamic_record(columns TEXT, table_name TEXT)
RETURNS SETOF RECORD
AS $$
BEGIN
    RETURN QUERY EXECUTE FORMAT('SELECT %s FROM ' || quote_ident(table_name), columns);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM f_get_dynamic_record('services_price, total_amount, commission, active', 'documentations') 
AS t(services_price NUMERIC, total_amount NUMERIC, commission NUMERIC, active BOOLEAN);

CREATE OR REPLACE FUNCTION f_get_clients_with_addresses()
RETURNS TABLE(
    client_id INT,
    name VARCHAR,
    email VARCHAR,
    address VARCHAR,
    city VARCHAR,
    postal_code INTEGER
)
AS $$
BEGIN
    RETURN QUERY
    SELECT c.client_id, c.name, c.email, a.address, a.city, a.postal_code
    FROM clients AS c
    JOIN address AS a ON c.address_id = a.address_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM f_get_clients_with_addresses();