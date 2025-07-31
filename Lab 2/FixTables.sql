ALTER TABLE Documentations
DROP COLUMN Payment_ID,
ADD COLUMN Services_Price NUMERIC(5, 2) CHECK (Services_Price > 0) NOT NULL,
ADD COLUMN Total_Amount NUMERIC(5, 2) CHECK (Total_Amount > 0) NOT NULL;

ALTER TABLE Payments
ADD COLUMN Client_ID INTEGER REFERENCES Clients(Client_ID) NOT NULL,
ADD COLUMN Documentation_ID INTEGER REFERENCES Documentations(Documentation_ID) NOT NULL;

ALTER TABLE Documentations
ADD CONSTRAINT total_amount_is_valid CHECK (Total_Amount <= Services_Price),
ADD COLUMN Active BOOLEAN DEFAULT TRUE;

ALTER TABLE Payments
ALTER COLUMN Date DROP NOT NULL,
ALTER COLUMN Date SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE Services
ALTER COLUMN Description TYPE VARCHAR(200);

ALTER TABLE deletable_table
DROP CONSTRAINT deletable_table_check,
DROP COLUMN deletable_column1,
DROP COLUMN deletable_column2;

DROP TABLE deletable_table;

ALTER TABLE Documentations
ALTER COLUMN Services_Price TYPE NUMERIC(6, 2),
ALTER COLUMN Total_Amount TYPE NUMERIC(6, 2),
ALTER COLUMN Commission TYPE NUMERIC(6, 2);

ALTER TABLE Address
ALTER COLUMN Address DROP UNIQUE;