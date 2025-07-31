--COUNT--
SELECT
	c.client_id, 
	c.name, 
	c.client_type,
	COUNT(asv.service_id) AS total_services
FROM clients AS c
JOIN agreements AS a ON c.client_id = a.client_id
JOIN agreementServices AS asv ON a.agreement_id = asv.agreement_id
GROUP BY c.client_id
ORDER BY total_services DESC;

--SUM--
SELECT 
	EXTRACT(MONTH FROM a.Date) AS month,
	SUM(d.total_amount) AS total_amount
FROM agreements AS a
JOIN documentations AS d ON a.agreement_id = d.agreement_id
WHERE EXTRACT(YEAR FROM a.Date) = 2024
GROUP BY month;

--Multiple GROUP BY--
SELECT
	c.client_id,
	c.name,
	p.payment_type,
	SUM(p.amount) AS total_amount
FROM clients AS c
JOIN payments AS p ON c.client_id = p.client_id
GROUP BY c.client_id, p.payment_type
ORDER BY total_amount DESC;

--HAVING--
SELECT 
	s.staff_id,
	s.name,
	s.surname,
	SUM(d.services_price) AS total_services_price
FROM staff AS s
JOIN agreements AS a ON s.staff_id = a.staff_id
JOIN documentations AS d ON a.agreement_id = d.agreement_id
GROUP BY s.staff_id
HAVING SUM(d.services_price) > 500;

--HAVING(without GROUP BY)--
SELECT 
	SUM(p.amount) AS total_payments
FROM clients AS c
JOIN agreements AS ag ON c.client_id = ag.client_id
JOIN documentations AS d ON ag.agreement_id = d.agreement_id
JOIN payments AS p ON d.documentation_id = p.documentation_id
HAVING SUM(p.amount) > 500;

--ROW_NUMBER()--
WITH MostExpensiveAgreements AS (
	SELECT
		a.description AS description,
		a.date AS date,
		d.total_amount AS amount,
		ROW_NUMBER() OVER (PARTITION BY EXTRACT(MONTH FROM a.Date) ORDER BY d.total_amount DESC) AS row_num
	FROM agreements AS a
	JOIN documentations AS d ON a.agreement_id = d.agreement_id
	WHERE EXTRACT(YEAR FROM a.Date) = 2024
)
SELECT 
	description,
	amount,
	date
FROM MostExpensiveAgreements
WHERE row_num = 1;

--STRING_AGG()--
SELECT
	EXTRACT(MONTH FROM a.Date) AS month,
	s.service_type,
	STRING_AGG(s.description, ', ') AS services_list
FROM agreements AS a
JOIN agreementservices AS asv ON a.agreement_id = asv.agreement_id
JOIN services AS s ON asv.service_id = s.service_id
WHERE EXTRACT(YEAR FROM a.Date) = 2024
GROUP BY month, s.service_type;

--Multiple ORDER BY--
SELECT 
    c.name AS client_name,
   	c.client_type,
    d.total_amount,
    a.date
FROM agreements AS a
JOIN clients AS c ON a.client_id = c.client_id
JOIN documentations AS d ON a.agreement_id = d.agreement_id
ORDER BY c.client_type ASC, d.total_amount DESC, a.date ASC;

--Top Discount--
WITH TopDiscountPerMonth AS (
	SELECT 
	    c.*,
	    SUM(percentage) AS total_discount_percentage,
	    ROW_NUMBER() OVER (ORDER BY SUM(percentage) DESC) AS row_num
	FROM clients AS c
	JOIN agreements AS a ON c.client_id = a.client_id
	JOIN documentations AS d ON a.agreement_id = d.agreement_id
	JOIN documentationDiscounts AS dds ON d.documentation_id = dds.documentation_id
	JOIN discounts AS dis ON dds.discount_id = dis.discount_id
	WHERE EXTRACT(MONTH FROM a.Date) = 7
	GROUP BY c.client_id
)
SELECT 
	name,
	client_type,
	business_type,
	phone_number,
	email,
	total_discount_percentage
FROM TopDiscountPerMonth
WHERE row_num = 1;

--Top Services Count--
WITH TopServiceCountPerQuater AS (
	SELECT 
		c.*,
		a.agreement_id,
		COUNT(asv.service_id) AS services_count,
		ROW_NUMBER() OVER (ORDER BY COUNT(asv.service_id) DESC) AS row_num
	FROM clients AS c
	JOIN agreements AS a ON c.client_id = a.client_id
	JOIN agreementServices AS asv ON a.agreement_id = asv.agreement_id
	WHERE EXTRACT(YEAR FROM a.date) = 2024 AND EXTRACT(QUARTER FROM a.date) = 3
	GROUP BY c.client_id, a.agreement_id
)
SELECT 
	name,
	client_type,
	business_type,
	phone_number,
	email,
	agreement_id,
	services_count
FROM TopServiceCountPerQuater
WHERE row_num = 1;

--Create VIEW--
CREATE VIEW AgreementSummary AS
SELECT 
    a.agreement_id,
    c.name AS client_name,
    c.client_type,
    a.date AS agreement_date,
    s.service_type,
    s.description AS service_description,
    d.total_amount
FROM agreements AS a
JOIN clients AS c ON a.client_id = c.client_id
JOIN agreementservices AS asv ON a.agreement_id = asv.agreement_id
JOIN services AS s ON asv.service_id = s.service_id
JOIN documentations AS d ON a.agreement_id = d.agreement_id;

--Create new VIEW based on previous--
CREATE VIEW HighValueAgreements AS
SELECT 
    ag.agreement_id,
    ag.client_name,
    ag.client_type,
    ag.agreement_date,
    ag.service_type,
    ag.service_description,
    ag.total_amount,
    s.name AS staff_name,
    s.surname AS staff_surname
FROM AgreementSummary AS ag
JOIN agreements AS a ON ag.agreement_id = a.agreement_id
JOIN staff AS s ON a.staff_id = s.staff_id
WHERE ag.total_amount > 500;

ALTER VIEW HighValueAgreements RENAME TO AgreementsOver500;

ALTER VIEW AgreementsOver500 postgres TO admin_role;