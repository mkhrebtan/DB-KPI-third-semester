CREATE OR REPLACE PROCEDURE p_create_documentations_for_agreements()
AS $$
DECLARE
    agreement_cursor CURSOR FOR
        SELECT 
			a.agreement_id, 
            SUM(s.price) AS total_service_price
        FROM agreements a
        JOIN agreementservices ags ON a.agreement_ID = ags.agreement_id
        JOIN services s ON ags.service_id = s.service_id
        GROUP BY a.agreement_id;
    
    v_agreement_id INTEGER;
    v_total_service_price NUMERIC(6, 2);

    doc_exists BOOLEAN;
BEGIN
    OPEN agreement_cursor;

    LOOP
        FETCH agreement_cursor INTO v_agreement_id, v_total_service_price;

        EXIT WHEN NOT FOUND;

        SELECT EXISTS (
            SELECT 1
            FROM documentations
            WHERE agreement_id = v_agreement_id
        ) INTO doc_exists;

        IF NOT doc_exists THEN
            INSERT INTO Documentations (
                agreement_id, 
                services_price, 
                total_amount, 
                commission, 
                active
            ) VALUES (
                v_agreement_id,
                v_total_service_price,
                v_total_service_price,
                v_total_service_price * 0.1,
                TRUE
            );         
        END IF;
    END LOOP;

    CLOSE agreement_cursor;
END;
$$ LANGUAGE plpgsql;

CALL p_create_documentations_for_agreements();

INSERT INTO agreements(client_id, staff_id, description, date)
VALUES(2, 2, 'new', CURRENT_DATE);

INSERT INTO agreementservices(agreement_id, service_id)
VALUES(30, 20);

SELECT * FROM documentations;

SELECT 
	a.agreement_id, 
	SUM(s.price) AS total_service_price
FROM agreements a
JOIN agreementservices ags ON a.agreement_ID = ags.agreement_id
JOIN services s ON ags.service_id = s.service_id
GROUP BY a.agreement_id;