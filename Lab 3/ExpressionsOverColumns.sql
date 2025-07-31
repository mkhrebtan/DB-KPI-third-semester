SELECT documentation_id, services_price - total_amount AS Discount_Amount 
FROM documentations
ORDER BY services_price - total_amount
DESC
LIMIT 1;

SELECT * FROM documentations
WHERE total_amount + commission < 100;