SELECT 
	staff.staff_id, 
	staff.name, 
	staff.surname, 
	agreements.description AS agreement_description, 
	documentations.services_price AS aggrement_price
FROM documentations
JOIN agreements ON documentations.agreement_id = agreements.agreement_id
JOIN staff ON agreements.staff_id = staff.staff_id
WHERE 
	documentations.services_price > (SELECT AVG(services_price) FROM documentations)
	AND documentations.active = 'false';

SELECT 
	agreements.description, 
	clients.Name AS clientName, 
	staff.Name AS staffName,
	staff.Surname AS staffSurname
FROM agreements
JOIN clients ON agreements.client_id = clients.client_id
JOIN staff ON agreements.staff_id = staff.staff_id;

SELECT d.*, p.payment_type, p.date
FROM documentations AS d
LEFT JOIN payments AS p ON d.documentation_id = p.documentation_id;

SELECT staff.name, staff.surname, agreements.description
FROM agreements
RIGHT JOIN staff ON agreements.staff_id = staff.staff_id
ORDER BY agreements.description DESC;