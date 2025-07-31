SELECT * FROM documentations
WHERE commission > 15.00 AND active = 'true';

SELECT * FROM discounts
WHERE percentage = 15 OR percentage = 25;

SELECT * FROM payments
WHERE NOT payment_type = 'In cash' AND amount > 100;
