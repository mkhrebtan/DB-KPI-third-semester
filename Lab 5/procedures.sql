CREATE OR REPLACE PROCEDURE pr_calculate_client_services(
    p_client_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
)
AS $$
DECLARE
	rec RECORD;
BEGIN
    CREATE TEMP TABLE temp_services_summary (
        agreement_id INTEGER,
        service_id INTEGER,
        service_price NUMERIC(6,2)
    ) ON COMMIT DROP;

    INSERT INTO temp_services_summary (agreement_id, service_id, service_price)
    SELECT 
        a.agreement_id,
        s.service_id,
        s.price
    FROM agreements a
    JOIN agreementservices asg ON a.agreement_id = asg.agreement_id
    JOIN services s ON asg.service_id = s.service_id
    WHERE a.client_id = p_client_id
      AND a.date BETWEEN p_start_date AND p_end_date;

    RAISE NOTICE 'Client ID: %, Start Date: %, End Date: %', p_client_id, p_start_date, p_end_date;

    RAISE NOTICE 'Total Services Price: %', 
        (SELECT COALESCE(SUM(service_price), 0) FROM temp_services_summary);

    FOR rec IN 
        SELECT agreement_id, service_id, service_price 
        FROM temp_services_summary
    LOOP
        RAISE NOTICE 'Agreement ID: %, Service ID: %, Price: %', rec.agreement_id, rec.service_id, rec.service_price;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL pr_calculate_client_services(1, '2024-01-01', '2024-12-31');

CREATE OR REPLACE PROCEDURE pr_update_contact_info(
	entity_type VARCHAR(6),
    entity_id INTEGER,
    new_address address.address%TYPE,
    new_phone VARCHAR(12),
    new_email VARCHAR(50)
) AS $$
DECLARE
	v_address_id INTEGER := null;
BEGIN
	v_address_id := (SELECT address_ID FROM address WHERE address = new_address);
	
	IF entity_type = 'Client' THEN
        UPDATE Clients
        SET address_ID = v_address_id,
            phone_Number = new_phone,
            email = new_email
        WHERE Client_ID = entity_id;
    ELSIF entity_type = 'Staff' THEN
        UPDATE Staff
        SET address_ID = v_address_id,
            phone_Number = new_phone,
            email = new_email
        WHERE Staff_ID = entity_id;
    ELSE
        RAISE EXCEPTION 'Invalid entity type: %', entity_type;
    END IF;

	RAISE NOTICE 'Contact info updated for % with ID %', entity_type, entity_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM clients;
SELECT * FROM address;

CALL pr_update_contact_info('Client', 1, '505 Cherry Dr', '6661234567', 'john.doe2@example.com');

CREATE OR REPLACE PROCEDURE pr_update_services_price(p_percent INTEGER)
AS $$
DECLARE
    serv_id INT;
    v_price services.price%TYPE;
BEGIN
    serv_id := 1;
    WHILE serv_id <= (SELECT MAX(service_id) FROM services) LOOP
        SELECT price INTO v_price
        FROM services
        WHERE service_id = serv_id;

	  	UPDATE services
	    SET price = v_price * (1 + p_percent::NUMERIC / 100)
	    WHERE service_id = serv_id;
		
        serv_id := serv_id + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM services;

CALL pr_update_services_price(10);

CREATE OR REPLACE PROCEDURE pr_update_total_amount_for_active_docs()
AS $$
DECLARE
    v_doc_id INT;
    v_service_price documentations.services_price%TYPE;
    v_total_discount NUMERIC(6, 2);
    v_total_amount documentations.total_amount%TYPE;
BEGIN
    FOR v_doc_id, v_service_price IN
        SELECT documentation_id, services_price
        FROM documentations
        WHERE active = TRUE
    LOOP
        SELECT COALESCE(SUM(d.percentage), 0) INTO v_total_discount
        FROM documentationdiscounts AS dd
        JOIN discounts AS d ON dd.discount_id = d.discount_id
        WHERE dd.documentation_id = v_doc_id;
        
        v_total_amount := v_service_price * (1 - v_total_discount / 100);
       
        UPDATE documentations
        SET total_amount = v_total_amount,
			commission = v_total_amount * 0.1
        WHERE documentation_id = v_doc_id;
              
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL pr_update_total_amount_for_active_docs();

SELECT * FROM documentations AS doc
JOIN documentationdiscounts AS dd ON doc.documentation_id = dd.documentation_id
JOIN discounts AS d ON dd.discount_id = d.discount_id;

INSERT INTO documentationdiscounts(documentation_id, discount_id)
VALUES
	(27, 1),
	(28, 1),
	(29, 1);

CREATE OR REPLACE PROCEDURE pr_create_agreement(
    p_client_id INTEGER,
    p_staff_id INTEGER,
    p_services INTEGER[],
	OUT p_agreements_count INTEGER
)
AS $$
DECLARE
    v_agreement_id INTEGER;
    v_total_price documentations.services_price%TYPE := 0;
	v_service_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clients WHERE client_id = p_client_id) THEN
        RAISE EXCEPTION 'Client with ID % does not exist', p_client_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM staff WHERE staff_id = p_staff_id) THEN
        RAISE EXCEPTION 'Staff with ID % does not exist', p_staff_id;
    END IF;

    INSERT INTO agreements (client_id, staff_id, description, date)
    VALUES (p_client_id, p_staff_id, 'New Agreement', CURRENT_DATE)
    RETURNING agreement_id INTO v_agreement_id;

    FOREACH v_service_id IN ARRAY p_services LOOP
        INSERT INTO agreementservices (agreement_id, service_id)
        VALUES (v_agreement_id, v_service_id);

        v_total_price := v_total_price + (SELECT price FROM services WHERE service_id = v_service_id);
    END LOOP;
    
    INSERT INTO documentations (agreement_ID, services_price, total_amount, commission)
    VALUES (v_agreement_id, v_total_price, v_total_price, v_total_price * 0.1);

	SELECT COUNT(*) INTO p_agreements_count FROM agreements AS a WHERE a.client_id = p_client_id; 
END;
$$ LANGUAGE plpgsql;

DROP PROCEDURE pr_create_agreement;

DO $$
DECLARE
	v_client_agreements INTEGER := 0;
BEGIN
	CALL pr_create_agreement(5, 2, ARRAY[4, 13, 5], v_client_agreements);
	RAISE NOTICE 'К-сть угод клієнта: %', v_client_agreements;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM agreements AS a
JOIN agreementservices AS ags ON a.agreement_id = ags.agreement_id
JOIN services AS s ON ags.service_id = s.service_id
JOIN documentations AS doc ON a.agreement_id = doc.agreement_id
WHERE a.description = 'New Agreement';

CREATE OR REPLACE PROCEDURE pr_update_commissions(p_percent INTEGER) 
AS $$
DECLARE
    doc_id INT;
    v_commission NUMERIC(6,2);
BEGIN
    doc_id := 1;
    WHILE doc_id <= (SELECT MAX(Documentation_ID) FROM Documentations) LOOP
        SELECT commission INTO v_commission
        FROM documentations
        WHERE documentation_id = doc_id AND documentations.active = TRUE;

	   	IF v_commission IS NOT NULL THEN
	        UPDATE documentations
	        SET commission = v_commission * (1 + p_percent::NUMERIC / 100)
	        WHERE documentation_id = doc_id;
		END IF;
		
        doc_id := doc_id + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL pr_update_commissions(15);

CREATE OR REPLACE PROCEDURE pr_get_client_services(p_client_id INT)
AS $$
DECLARE
	x RECORD;
BEGIN
	FOR x IN
	    SELECT s.description, s.price
	    FROM services AS s
	    JOIN agreementservices AS asr ON s.service_id = asr.service_id
	    JOIN agreements AS a ON asr.agreement_id = a.agreement_id
	    WHERE a.client_id = p_client_id
	LOOP
		RAISE NOTICE 'Послуга: % | Ціна: %', x.description, x.price;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

DROP PROCEDURE get_client_services;

CALL pr_get_client_services(1);