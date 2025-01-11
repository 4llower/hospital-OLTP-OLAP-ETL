CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.stg_doctor (
    fullname VARCHAR(100),
    specialty VARCHAR(100),
    phone VARCHAR(25),
    email VARCHAR(100),
    effective_date TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging.stg_patient (
    fullname VARCHAR(100),
    birthdate DATE,
    gender CHAR(1),
    phone VARCHAR(25),
    email VARCHAR(100),
    address VARCHAR(255),
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staging.stg_billing (
    patient_fullname VARCHAR(100),
    patient_birthdate DATE,
    doctor_fullname VARCHAR(100),
    appointment_date TIMESTAMP,
    amount DECIMAL(10,2),
    billing_date TIMESTAMP,
    status VARCHAR(50),
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE SCHEMA IF NOT EXISTS dwh;

CREATE TABLE IF NOT EXISTS dwh.dim_doctor (
    doctor_id BIGSERIAL PRIMARY KEY,
    fullname VARCHAR(100) NOT NULL,
    specialty VARCHAR(100),
    phone VARCHAR(25),
    email VARCHAR(100),
    effective_date TIMESTAMP,
    expiration_date TIMESTAMP,
    iscurrent BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS dwh.dim_patient (
    patient_id BIGSERIAL PRIMARY KEY,
    fullname VARCHAR(100) NOT NULL,
    birthdate DATE NOT NULL,
    gender CHAR(1),
    phone VARCHAR(25),
    email VARCHAR(100),
    address VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS dwh.dim_specialty (
    specialty_id BIGSERIAL PRIMARY KEY,
    specialty VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS dwh.dim_datetime (
    datetime_id BIGSERIAL PRIMARY KEY,
    full_datetime TIMESTAMP NOT NULL,
    date DATE,
    year INT,
    month INT,
    day INT,
    hour INT,
    minute INT,
    second INT
);

CREATE TABLE IF NOT EXISTS dwh.dim_appointment (
    appointment_id BIGSERIAL PRIMARY KEY,
    reason VARCHAR(255),
    status VARCHAR(50),
    patient_id BIGINT,
    doctor_id BIGINT,
    datetime_id BIGINT
);

CREATE TABLE IF NOT EXISTS dwh.fact_billing (
    billing_id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT,
    doctor_id BIGINT,
    datetime_id BIGINT,
    appointment_id BIGINT,
    amount DECIMAL(10,2),
    billing_date TIMESTAMP,
    status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS dwh.fact_satisfaction (
    satisfaction_id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT,
    doctor_id BIGINT,
    datetime_id BIGINT,
    appointment_id BIGINT,
    rating INT,
    comments TEXT
);

CREATE TABLE IF NOT EXISTS dwh.dim_insurance (
    insurance_id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT,
    provider VARCHAR(100),
    policy_number VARCHAR(50),
    expiration_date DATE
);
