CREATE TABLE IF NOT EXISTS DimSpecialty (
    SpecialtyID SERIAL PRIMARY KEY,
    SpecialtyName VARCHAR(100) UNIQUE
);

CREATE TABLE IF NOT EXISTS DimDoctor (
    DoctorID INT PRIMARY KEY,
    FullName VARCHAR(100),
    SpecialtyID INT,
    Phone VARCHAR(25),
    Email VARCHAR(100),
    FOREIGN KEY (SpecialtyID) REFERENCES DimSpecialty(SpecialtyID)
);

CREATE TABLE IF NOT EXISTS DimPatient (
    PatientID INT PRIMARY KEY,
    FullName VARCHAR(100),
    BirthDate DATE,
    Gender CHAR(1),
    Phone VARCHAR(25),
    Email VARCHAR(100),
    Address VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS DimTime (
    TimeID INT PRIMARY KEY,
    AppointmentDate TIMESTAMP,
    Year INT,
    Month INT,
    DayOfWeek INT
);

CREATE TABLE IF NOT EXISTS DimInsurance (
    InsuranceID SERIAL PRIMARY KEY,
    PatientID INT,
    Provider VARCHAR(100),
    PolicyNumber VARCHAR(50),
    ExpirationDate DATE,
    StartDate DATE,
    EndDate DATE,
    IsCurrent BOOLEAN,
    FOREIGN KEY (PatientID) REFERENCES DimPatient(PatientID)
);

CREATE TABLE IF NOT EXISTS FactAppointments (
    DoctorID INT,
    PatientID INT,
    TimeID INT,
    AppointmentCount INT,
    TotalAmountBilled DECIMAL(10,2),
    PRIMARY KEY (DoctorID, PatientID, TimeID),
    FOREIGN KEY (DoctorID) REFERENCES DimDoctor(DoctorID),
    FOREIGN KEY (PatientID) REFERENCES DimPatient(PatientID),
    FOREIGN KEY (TimeID) REFERENCES DimTime(TimeID)
);

CREATE TABLE IF NOT EXISTS FactBilling (
    PatientID INT,
    AppointmentID INT,
    TimeID INT,
    AmountBilled DECIMAL(10,2),
    BillingStatus VARCHAR(50),
    PRIMARY KEY (PatientID, AppointmentID, TimeID),
    FOREIGN KEY (PatientID) REFERENCES DimPatient(PatientID),
    FOREIGN KEY (TimeID) REFERENCES DimTime(TimeID)
);
