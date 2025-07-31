CREATE OR REPLACE VIEW agreements_total_info AS
SELECT
    a.agreement_id,
    SUM(s.price) AS sum_price,
    doc.documentation_id,
    doc.services_price,
    doc.total_amount,
    doc.commission,
    doc.active
FROM agreements AS a
JOIN agreementservices AS asr ON a.agreement_id = asr.agreement_id
JOIN services AS s ON asr.service_id = s.service_id
JOIN documentations AS doc ON a.agreement_id = doc.agreement_id
GROUP BY a.agreement_id, doc.documentation_id, doc.services_price, doc.total_amount, doc.commission, doc.active;

CREATE OR REPLACE FUNCTION f_add_delete_service_discount_trigger()
RETURNS TRIGGER 
AS $$
DECLARE
	doc_row RECORD;
	v_doc_id INTEGER;
	v_serv_price NUMERIC;
	v_total_amount NUMERIC;
	v_total_dis NUMERIC;
BEGIN
	IF TG_TABLE_NAME = 'agreementservices' THEN
		SELECT 			
			atf.documentation_id,
			sum_price AS services_price,
			SUM(d.percentage) AS total_discount
		INTO doc_row
		FROM agreements_total_info AS atf
		LEFT JOIN documentationdiscounts AS dd ON atf.documentation_id = dd.documentation_id
		LEFT JOIN discounts AS d ON dd.discount_id = d.discount_id
		WHERE active = true AND atf.agreement_id = (CASE WHEN TG_OP = 'DELETE' THEN OLD.agreement_id ELSE NEW.agreement_id END)
		GROUP BY atf.documentation_id, sum_price;
	ELSIF TG_TABLE_NAME = 'documentationdiscounts' THEN
		SELECT 			
			atf.documentation_id,
			sum_price AS services_price,
			SUM(d.percentage) AS total_discount
		INTO doc_row
		FROM agreements_total_info AS atf
		LEFT JOIN documentationdiscounts AS dd ON atf.documentation_id = dd.documentation_id
		LEFT JOIN discounts AS d ON dd.discount_id = d.discount_id
		WHERE active = true AND atf.documentation_id = (CASE WHEN TG_OP = 'DELETE' THEN OLD.documentation_id ELSE NEW.documentation_id END)
		GROUP BY atf.documentation_id, sum_price;
	END IF;

	IF doc_row IS NULL THEN
        RETURN NULL;
    END IF;

	v_doc_id := doc_row.documentation_id;
    v_serv_price := doc_row.services_price;
    v_total_dis := doc_row.total_discount;

	IF TG_TABLE_NAME = 'agreementservices' THEN
			UPDATE documentations
			SET services_price = v_serv_price
			WHERE documentation_id = v_doc_id;
	END IF;

	v_total_amount := v_serv_price * (1 - COALESCE(v_total_dis, 0) / 100);

	UPDATE documentations
        SET total_amount = v_total_amount,
			commission = v_total_amount * 0.1
        WHERE documentation_id = v_doc_id;
	
	IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER agreement_services_trigger
AFTER INSERT OR DELETE ON agreementservices
FOR EACH ROW
EXECUTE FUNCTION f_add_delete_service_discount_trigger();

CREATE OR REPLACE TRIGGER documentation_discounts_trigger
AFTER INSERT OR DELETE ON documentationdiscounts
FOR EACH ROW
EXECUTE FUNCTION f_add_delete_service_discount_trigger();

INSERT INTO documentationdiscounts(documentation_id, discount_id)
VALUES
	(30, 1);

DELETE FROM documentationdiscounts
WHERE documentation_id = 30 AND discount_id = 1;

INSERT INTO agreementservices(agreement_id, service_id)
VALUES (30, 4);

CREATE OR REPLACE FUNCTION f_update_service_discount_trigger()
RETURNS TRIGGER 
AS $$
DECLARE  
	doc_ids INTEGER[];
	doc_row RECORD;
	v_doc_id INTEGER;
	v_serv_price NUMERIC;
	v_total_amount NUMERIC;
	v_total_dis NUMERIC;
BEGIN
	IF TG_TABLE_NAME = 'services' THEN
		SELECT ARRAY(
			SELECT
				doc.documentation_id
			FROM agreements AS a
			JOIN agreementservices AS asr ON a.agreement_id = asr.agreement_id
			JOIN services AS s ON asr.service_id = s.service_id
			JOIN documentations AS doc ON a.agreement_id = doc.agreement_id
			WHERE s.service_id = NEW.service_id
		) INTO doc_ids;
	ELSIF TG_TABLE_NAME = 'discounts' THEN
		SELECT ARRAY(
			SELECT
				doc.documentation_id
			FROM documentations AS doc
			JOIN documentationdiscounts AS dd ON doc.documentation_id = dd.documentation_id
			JOIN discounts AS d ON dd.discount_id = d.discount_id
			WHERE d.discount_id = NEW.discount_id
		) INTO doc_ids;	
	END IF;
	
	FOR doc_row IN
		SELECT 			
			atf.documentation_id,
			sum_price AS services_price,
			SUM(d.percentage) AS total_discount	
		FROM agreements_total_info AS atf
		LEFT JOIN documentationdiscounts AS dd ON atf.documentation_id = dd.documentation_id
		LEFT JOIN discounts AS d ON dd.discount_id = d.discount_id
		WHERE active = true AND atf.documentation_id = ANY(doc_ids)
		GROUP BY atf.documentation_id, sum_price
	LOOP
		v_doc_id := doc_row.documentation_id;
        v_serv_price := doc_row.services_price;
        v_total_dis := doc_row.total_discount;
		
		IF TG_TABLE_NAME = 'services' THEN
			UPDATE documentations
			SET services_price = v_serv_price
			WHERE documentation_id = v_doc_id;
		END IF;

		v_total_amount := v_serv_price * (1 - COALESCE(v_total_dis, 0) / 100);
       
        UPDATE documentations
        SET total_amount = v_total_amount,
			commission = v_total_amount * 0.1
        WHERE documentation_id = v_doc_id;
	END LOOP;
	
	IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER services_price_update_trigger
AFTER UPDATE OF price ON services
FOR EACH ROW
WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION f_update_service_discount_trigger();

CREATE OR REPLACE TRIGGER discounts_percentage_update_trigger
AFTER UPDATE OF percentage ON discounts
FOR EACH ROW
WHEN (OLD.percentage IS DISTINCT FROM NEW.percentage)
EXECUTE FUNCTION f_update_service_discount_trigger();

UPDATE services 
SET price = 88.00
WHERE service_id = 4;

UPDATE discounts 
SET percentage = 10
WHERE discount_id = 1;