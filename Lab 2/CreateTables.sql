CREATE TYPE ClientType AS ENUM ('Individual', 'Business');
CREATE TYPE ServiceType AS ENUM ('For individual', 'For business');
CREATE TYPE PaymentType AS ENUM ('In cash', 'By bank card');

CREATE TABLE Address(
    Address_ID SERIAL PRIMARY KEY,
    Address VARCHAR(25) NOT NULL UNIQUE,
    City VARCHAR(25) NOT NULL,
    Postal_Code INTEGER
);

CREATE TABLE Clients(
    Client_ID SERIAL PRIMARY KEY,
    Name VARCHAR(25) NOT NULL,
    Client_Type ClientType NOT NULL,
    Business_Type VARCHAR(25),
    Phone_Number VARCHAR(12) UNIQUE,
    Address_ID INTEGER REFERENCES Address(Address_ID) UNIQUE,
    Email VARCHAR(50) UNIQUE
);

CREATE TABLE Staff(
    Staff_ID SERIAL PRIMARY KEY,
    Name VARCHAR(20) NOT NULL,
    Surname VARCHAR(20) NOT NULL,
    Address_ID INTEGER REFERENCES Address(Address_ID) UNIQUE,
    Phone_Number VARCHAR(12) UNIQUE,
    Email VARCHAR(50) UNIQUE
);

CREATE TABLE Services(
    Service_ID SERIAL PRIMARY KEY,
    Description VARCHAR(150) NOT NULL,
    Price NUMERIC(5, 2) CHECK (Price > 0) NOT NULL,
    Service_Type ServiceType NOT NULL
);

CREATE TABLE Discounts(
    Discount_ID SERIAL PRIMARY KEY,
    Description VARCHAR(150) NOT NULL,
    Percentage SMALLINT CHECK (Percentage <= 100 AND Percentage > 0)
);

CREATE TABLE Payments(
    Payment_ID SERIAL PRIMARY KEY,
    Amount NUMERIC(5, 2) CHECK (Amount > 0) NOT NULL,
    Payment_Type PaymentType NOT NULL,
    Date TIMESTAMP NOT NULL
);

CREATE TABLE Agreements(
    Agreement_ID SERIAL PRIMARY KEY,
    Client_ID INTEGER REFERENCES Clients(Client_ID) NOT NULL,
    Staff_ID INTEGER REFERENCES Staff(Staff_ID) NOT NULL,
    Description VARCHAR(150) NOT NULL,
    Date DATE NOT NULL
);

CREATE TABLE AgreementServices(
    Agreement_ID INTEGER REFERENCES Agreements(Agreement_ID) NOT NULL,
    Service_ID INTEGER REFERENCES Services(Service_ID) NOT NULL
);

CREATE TABLE Documentations(
    Documentation_ID SERIAL PRIMARY KEY,
    Agreement_ID INTEGER REFERENCES Agreements(Agreement_ID) UNIQUE NOT NULL,
    Payment_ID INTEGER REFERENCES Payments(Payment_ID) UNIQUE NOT NULL,
    Commission NUMERIC(5, 2) CHECK (Commission > 0) NOT NULL
);

CREATE TABLE DocumentationDiscounts(
    Documentation_ID INTEGER REFERENCES Documentations(Documentation_ID) NOT NULL,
    Discount_ID INTEGER REFERENCES Discounts(Discount_ID) NOT NULL
);

CREATE TABLE deletable_table(
    deletable_column1 INTEGER,
    deletable_column2 INTEGER CHECK (deletable_column2 = deletable_column1)
);
