SELECT service_id, description
FROM services
WHERE service_id NOT IN (
    SELECT asv.service_id
    FROM agreements ag
    JOIN agreementServices asv ON ag.agreement_id = asv.agreement_id
    WHERE EXTRACT(MONTH FROM ag.date) = 4
);

SELECT 
	*
FROM clients
WHERE client_id IN (
	SELECT 
	ag.client_id
	FROM agreements AS ag
	JOIN agreementServices AS asv ON ag.agreement_id = asv.agreement_id
	JOIN services AS s ON asv.service_id = s.service_id
	WHERE 
	(s.description ILIKE '%Power of Attorney%' OR s.description ILIKE '%Property Purchase%')
	AND EXTRACT(YEAR FROM ag.date) = 2023
);
