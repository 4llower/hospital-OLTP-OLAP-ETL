INSERT INTO DimSpecialty (SpecialtyName)
SELECT DISTINCT Specialty
FROM oltp_db.Doctors
WHERE Specialty IS NOT NULL
ON CONFLICT (SpecialtyName) DO NOTHING;

INSERT INTO DimDoctor (DoctorID, FullName, SpecialtyID, Phone, Email)
SELECT
    DoctorID,
    FullName,
    (SELECT SpecialtyID FROM DimSpecialty WHERE SpecialtyName = Doctors.Specialty LIMIT 1) AS SpecialtyID,
    Phone,
    Email
FROM oltp_db.Doctors
WHERE NOT EXISTS (
    SELECT 1 FROM DimDoctor WHERE DimDoctor.DoctorID = Doctors.DoctorID
);

INSERT INTO DimPatient (PatientID, FullName, BirthDate, Gender, Phone, Email, Address)
SELECT
    PatientID,
    FullName,
    BirthDate,
    Gender,
    Phone,
    Email,
    Address
FROM oltp_db.Patients
WHERE NOT EXISTS (
    SELECT 1 FROM DimPatient WHERE DimPatient.PatientID = Patients.PatientID
);

INSERT INTO DimTime (TimeID, AppointmentDate, Year, Month, DayOfWeek)
SELECT
    EXTRACT(YEAR FROM AppointmentDate) * 10000 + EXTRACT(MONTH FROM AppointmentDate) * 100 + EXTRACT(DAY FROM AppointmentDate) AS TimeID,
    AppointmentDate,
    EXTRACT(YEAR FROM AppointmentDate) AS Year,
    EXTRACT(MONTH FROM AppointmentDate) AS Month,
    EXTRACT(DOW FROM AppointmentDate) AS DayOfWeek
FROM oltp_db.Appointments
WHERE NOT EXISTS (
    SELECT 1 FROM DimTime WHERE DimTime.AppointmentDate = Appointments.AppointmentDate
);

-- FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACTS!!!!!
INSERT INTO FactAppointments (DoctorID, PatientID, TimeID, AppointmentCount, TotalAmountBilled)
SELECT
    DoctorID,
    PatientID,
    (SELECT TimeID FROM DimTime WHERE AppointmentDate = Appointments.AppointmentDate LIMIT 1),
    COUNT(*) AS AppointmentCount,
    SUM(Billing.Amount) AS TotalAmountBilled
FROM oltp_db.Appointments AS Appointments
JOIN oltp_db.Billing AS Billing ON Appointments.AppointmentID = Billing.AppointmentID
WHERE NOT EXISTS (
    SELECT 1 FROM FactAppointments WHERE FactAppointments.DoctorID = Appointments.DoctorID
    AND FactAppointments.PatientID = Appointments.PatientID
    AND FactAppointments.TimeID = (SELECT TimeID FROM DimTime WHERE AppointmentDate = Appointments.AppointmentDate LIMIT 1)
);

INSERT INTO FactBilling (PatientID, AppointmentID, TimeID, AmountBilled, BillingStatus)
SELECT
    PatientID,
    AppointmentID,
    (SELECT TimeID FROM DimTime WHERE AppointmentDate = Appointments.AppointmentDate LIMIT 1),
    Amount,
    Status
FROM oltp_db.Billing AS Billing
JOIN oltp_db.Appointments AS Appointments ON Appointments.AppointmentID = Billing.AppointmentID
WHERE NOT EXISTS (
    SELECT 1 FROM FactBilling WHERE FactBilling.PatientID = Billing.PatientID
    AND FactBilling.AppointmentID = Billing.AppointmentID
    AND FactBilling.TimeID = (SELECT TimeID FROM DimTime WHERE AppointmentDate = Appointments.AppointmentDate LIMIT 1)
);


-- Handle Slowly Changing Dimension (SCD Type 2) for DimInsurance
WITH NewInsurance AS (
    SELECT
        PatientID,
        Provider,
        PolicyNumber,
        ExpirationDate,
        StartDate,
        EndDate
    FROM oltp_db.InsuranceDetails
    WHERE NOT EXISTS (
        SELECT 1
        FROM DimInsurance
        WHERE DimInsurance.PatientID = InsuranceDetails.PatientID
        AND DimInsurance.Provider = InsuranceDetails.Provider
        AND DimInsurance.PolicyNumber = InsuranceDetails.PolicyNumber
        AND DimInsurance.StartDate = InsuranceDetails.StartDate
    )
)
INSERT INTO DimInsurance (PatientID, Provider, PolicyNumber, ExpirationDate, StartDate, EndDate, IsCurrent)
SELECT
    PatientID,
    Provider,
    PolicyNumber,
    ExpirationDate,
    StartDate,
    EndDate,
    TRUE
FROM NewInsurance;

UPDATE DimInsurance
SET EndDate = CURRENT_DATE, IsCurrent = FALSE
WHERE PatientID IN (SELECT PatientID FROM NewInsurance)
AND EndDate IS NULL;




