CREATE TABLE IF NOT EXISTS Doctors (
    DoctorID SERIAL PRIMARY KEY,
    FullName VARCHAR(100),
    Specialty VARCHAR(100),
    Phone VARCHAR(25),
    Email VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Patients (
    PatientID SERIAL PRIMARY KEY,
    FullName VARCHAR(100),
    BirthDate DATE,
    Gender CHAR(1),
    Phone VARCHAR(25),
    Email VARCHAR(100),
    Address VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Appointments (
    AppointmentID SERIAL PRIMARY KEY,
    DoctorFullName VARCHAR(100),
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    AppointmentDate DATE,
    Reason VARCHAR(255),
    Status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS MedicalRecords (
    RecordID SERIAL PRIMARY KEY,
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    DoctorFullName VARCHAR(100),
    Date DATE,
    Diagnosis VARCHAR(255),
    Treatment TEXT,
    Notes TEXT
);

CREATE TABLE IF NOT EXISTS Billing (
    BillID SERIAL PRIMARY KEY,
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    DoctorFullName VARCHAR(100),
    AppointmentDate DATE,
    Amount DECIMAL(10, 2),
    BillingDate DATE,
    Status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Prescriptions (
    PrescriptionID SERIAL PRIMARY KEY,
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    DoctorFullName VARCHAR(100),
    RecordDate DATE,
    Medication VARCHAR(100),
    Dosage VARCHAR(50),
    Frequency VARCHAR(50),
    Notes TEXT
);

CREATE TABLE IF NOT EXISTS InsuranceDetails (
    InsuranceID SERIAL PRIMARY KEY,
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    Provider VARCHAR(100),
    PolicyNumber VARCHAR(50),
    ExpirationDate DATE
);

CREATE TABLE IF NOT EXISTS AppointmentFeedback (
    FeedbackID SERIAL PRIMARY KEY,
    PatientFullName VARCHAR(100),
    DoctorFullName VARCHAR(100),
    AppointmentDate DATE,
    Rating INT,
    Comments TEXT,
    FeedbackDate DATE
);

CREATE TEMP TABLE Doctors_temp (
    FullName VARCHAR(100),
    Specialty VARCHAR(100),
    Phone VARCHAR(25),
    Email VARCHAR(100)
);

COPY Doctors_temp(FullName, Specialty, Phone, Email)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/Doctors.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO Doctors (FullName, Specialty, Phone, Email)
SELECT FullName, Specialty, Phone, Email
FROM Doctors_temp
WHERE NOT EXISTS (
    SELECT 1 FROM Doctors d WHERE d.FullName = Doctors_temp.FullName
);

CREATE TEMP TABLE Patients_temp (
    FullName VARCHAR(100),
    BirthDate DATE,
    Gender CHAR(1),
    Phone VARCHAR(25),
    Email VARCHAR(100),
    Address VARCHAR(255)
);

COPY Patients_temp(FullName, BirthDate, Gender, Phone, Email, Address)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/Patients.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO Patients (FullName, BirthDate, Gender, Phone, Email, Address)
SELECT FullName, BirthDate, Gender, Phone, Email, Address
FROM Patients_temp
WHERE NOT EXISTS (
    SELECT 1 FROM Patients p WHERE p.FullName = Patients_temp.FullName AND p.BirthDate = Patients_temp.BirthDate
);

CREATE TEMP TABLE Appointments_temp (
    DoctorFullName VARCHAR(100),
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    AppointmentDate DATE,
    Reason VARCHAR(255),
    Status VARCHAR(50)
);

COPY Appointments_temp(DoctorFullName, PatientFullName, PatientBirthDate, AppointmentDate, Reason, Status)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/Appointments.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO Appointments (DoctorFullName, PatientFullName, PatientBirthDate, AppointmentDate, Reason, Status)
SELECT DoctorFullName, PatientFullName, PatientBirthDate, AppointmentDate, Reason, Status
FROM Appointments_temp
WHERE NOT EXISTS (
    SELECT 1 FROM Appointments a WHERE a.DoctorFullName = Appointments_temp.DoctorFullName
    AND a.PatientFullName = Appointments_temp.PatientFullName
    AND a.PatientBirthDate = Appointments_temp.PatientBirthDate
    AND a.AppointmentDate = Appointments_temp.AppointmentDate
);

CREATE TEMP TABLE MedicalRecords_temp (
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    DoctorFullName VARCHAR(100),
    Date DATE,
    Diagnosis VARCHAR(255),
    Treatment TEXT,
    Notes TEXT
);

COPY MedicalRecords_temp(PatientFullName, PatientBirthDate, DoctorFullName, Date, Diagnosis, Treatment, Notes)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/MedicalRecords.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO MedicalRecords (PatientFullName, PatientBirthDate, DoctorFullName, Date, Diagnosis, Treatment, Notes)
SELECT PatientFullName, PatientBirthDate, DoctorFullName, Date, Diagnosis, Treatment, Notes
FROM MedicalRecords_temp
WHERE NOT EXISTS (
    SELECT 1 FROM MedicalRecords m WHERE m.PatientFullName = MedicalRecords_temp.PatientFullName
    AND m.PatientBirthDate = MedicalRecords_temp.PatientBirthDate
    AND m.DoctorFullName = MedicalRecords_temp.DoctorFullName
    AND m.Date = MedicalRecords_temp.Date
);

CREATE TEMP TABLE Billing_temp (
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    DoctorFullName VARCHAR(100),
    AppointmentDate DATE,
    Amount DECIMAL(10, 2),
    BillingDate DATE,
    Status VARCHAR(50)
);

COPY Billing_temp(PatientFullName, PatientBirthDate, DoctorFullName, AppointmentDate, Amount, BillingDate, Status)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/Billing.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO Billing (PatientFullName, PatientBirthDate, DoctorFullName, AppointmentDate, Amount, BillingDate, Status)
SELECT PatientFullName, PatientBirthDate, DoctorFullName, AppointmentDate, Amount, BillingDate, Status
FROM Billing_temp
WHERE NOT EXISTS (
    SELECT 1 FROM Billing b WHERE b.PatientFullName = Billing_temp.PatientFullName
    AND b.PatientBirthDate = Billing_temp.PatientBirthDate
    AND b.DoctorFullName = Billing_temp.DoctorFullName
    AND b.AppointmentDate = Billing_temp.AppointmentDate
);

CREATE TEMP TABLE Prescriptions_temp (
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    DoctorFullName VARCHAR(100),
    RecordDate DATE,
    Medication VARCHAR(100),
    Dosage VARCHAR(50),
    Frequency VARCHAR(50),
    Notes TEXT
);

COPY Prescriptions_temp(PatientFullName, PatientBirthDate, DoctorFullName, RecordDate, Medication, Dosage, Frequency, Notes)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/Prescriptions.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO Prescriptions (PatientFullName, PatientBirthDate, DoctorFullName, RecordDate, Medication, Dosage, Frequency, Notes)
SELECT PatientFullName, PatientBirthDate, DoctorFullName, RecordDate, Medication, Dosage, Frequency, Notes
FROM Prescriptions_temp
WHERE NOT EXISTS (
    SELECT 1 FROM Prescriptions p WHERE p.PatientFullName = Prescriptions_temp.PatientFullName
    AND p.PatientBirthDate = Prescriptions_temp.PatientBirthDate
    AND p.DoctorFullName = Prescriptions_temp.DoctorFullName
    AND p.RecordDate = Prescriptions_temp.RecordDate
);

CREATE TEMP TABLE InsuranceDetails_temp (
    PatientFullName VARCHAR(100),
    PatientBirthDate DATE,
    Provider VARCHAR(100),
    PolicyNumber VARCHAR(50),
    ExpirationDate DATE
);

COPY InsuranceDetails_temp(PatientFullName, PatientBirthDate, Provider, PolicyNumber, ExpirationDate)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/InsuranceDetails.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO InsuranceDetails (PatientFullName, PatientBirthDate, Provider, PolicyNumber, ExpirationDate)
SELECT PatientFullName, PatientBirthDate, Provider, PolicyNumber, ExpirationDate
FROM InsuranceDetails_temp
WHERE NOT EXISTS (
    SELECT 1 FROM InsuranceDetails i WHERE i.PatientFullName = InsuranceDetails_temp.PatientFullName
    AND i.PatientBirthDate = InsuranceDetails_temp.PatientBirthDate
    AND i.Provider = InsuranceDetails_temp.Provider
    AND i.PolicyNumber = InsuranceDetails_temp.PolicyNumber
);

CREATE TEMP TABLE AppointmentFeedback_temp (
    PatientFullName VARCHAR(100),
    DoctorFullName VARCHAR(100),
    AppointmentDate DATE,
    Rating INT,
    Comments TEXT,
    FeedbackDate DATE
);

COPY AppointmentFeedback_temp(PatientFullName, DoctorFullName, AppointmentDate, Rating, Comments, FeedbackDate)
FROM 'D:/EHU/Databases/coursework/oltp/data/generated/AppointmentFeedback.csv'
DELIMITER ',' CSV HEADER;

-- Insert data into AppointmentFeedback table, avoiding duplicates
INSERT INTO AppointmentFeedback (PatientFullName, DoctorFullName, AppointmentDate, Rating, Comments, FeedbackDate)
SELECT PatientFullName, DoctorFullName, AppointmentDate, Rating, Comments, FeedbackDate
FROM AppointmentFeedback_temp
WHERE NOT EXISTS (
    SELECT 1 FROM AppointmentFeedback af WHERE af.PatientFullName = AppointmentFeedback_temp.PatientFullName
    AND af.DoctorFullName = AppointmentFeedback_temp.DoctorFullName
    AND af.AppointmentDate = AppointmentFeedback_temp.AppointmentDate
);

DROP TABLE IF EXISTS Doctors_temp, Patients_temp, Appointments_temp, MedicalRecords_temp, Billing_temp, Prescriptions_temp, InsuranceDetails_temp, AppointmentFeedback_temp;
