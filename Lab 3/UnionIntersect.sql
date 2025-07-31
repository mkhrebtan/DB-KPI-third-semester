SELECT City FROM Address WHERE Address_ID IN (SELECT Address_ID FROM Clients)
UNION
SELECT City FROM Address WHERE Address_ID IN (SELECT Address_ID FROM Staff);

SELECT City FROM Address WHERE Address_ID IN (SELECT Address_ID FROM Clients)
INTERSECT
SELECT City FROM Address WHERE Address_ID IN (SELECT Address_ID FROM Staff);