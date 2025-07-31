SELECT 
	Name, 
	(SELECT COUNT(*) FROM Agreements WHERE Agreements.Client_ID = Clients.Client_ID) AS agreements
FROM Clients
ORDER BY agreements DESC;

SELECT 
	S.name,
	S.surname,
	Agreements_Count.agreements_total AS agreements
FROM
	staff AS S,
	(SELECT staff_id, COUNT(*) AS agreements_total FROM agreements GROUP BY staff_id) AS Agreements_Count
WHERE
	S.staff_id = Agreements_Count.staff_id;

