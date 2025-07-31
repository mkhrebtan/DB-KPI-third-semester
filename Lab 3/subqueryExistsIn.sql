SELECT * 
FROM Services 
WHERE Service_ID NOT IN (
    SELECT Service_ID 
    FROM AgreementServices 
    WHERE EXISTS (
        SELECT * 
        FROM Agreements 
        WHERE Agreements.Agreement_ID = AgreementServices.Agreement_ID
    )
);