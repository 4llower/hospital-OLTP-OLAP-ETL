-- 1) REFERENCE SCHEMA AND TABLES

create schema if not exists reference;

create table if not exists reference.allowed_specialties (
  specialty varchar(100) primary key
);

insert into reference.allowed_specialties (specialty)
values
('Cardiology'),
('Neurology'),
('Orthopedics'),
('Pediatrics'),
('Dermatology')
on conflict (specialty) do nothing;

-- 2) STAGING SCHEMA AND TABLES

create schema if not exists staging;

create table if not exists staging.stg_doctor (
  fullname varchar(100),
  specialty varchar(100),
  phone varchar(25),
  email varchar(100),
  effective_date timestamp default now(),
  last_modified timestamp default current_timestamp
);

create table if not exists staging.stg_patient (
  fullname varchar(100),
  birthdate date,
  gender char(1),
  phone varchar(25),
  email varchar(100),
  address varchar(255),
  last_modified timestamp default current_timestamp
);

create table if not exists staging.stg_billing (
  patient_fullname varchar(100),
  patient_birthdate date,
  doctor_fullname varchar(100),
  appointment_date timestamp,
  amount decimal(10,2),
  billing_date timestamp,
  status varchar(50),
  last_modified timestamp default current_timestamp
);

create table if not exists staging.stg_appointment (
  appointment_id bigint,
  doctor_fullname varchar(100),
  patient_fullname varchar(100),
  patient_birthdate date,
  appointment_date timestamp,
  reason varchar(255),
  status varchar(50),
  last_modified timestamp default current_timestamp
);

create table if not exists staging.stg_insurance (
  patient_fullname varchar(100),
  patient_birthdate date,
  provider varchar(100),
  policy_number varchar(50),
  expiration_date date,
  last_modified timestamp default current_timestamp
);

create table if not exists staging.stg_feedback (
  patient_fullname varchar(100),
  doctor_fullname varchar(100),
  appointment_date timestamp,
  rating int,
  comments text,
  feedback_date timestamp,
  last_modified timestamp default current_timestamp
);

-- 3) OLAP SCHEMA AND TABLES (FACT & DIM)

create schema if not exists dwh;

create table if not exists dwh.dim_specialty (
  specialty_id bigserial primary key,
  specialty varchar(100)
);

create table if not exists dwh.dim_doctor (
  doctor_id bigserial primary key,
  fullname varchar(100) not null,
  specialty varchar(100),
  phone varchar(25),
  email varchar(100),
  effective_date timestamp,
  expiration_date timestamp,
  iscurrent boolean default true
);

create table if not exists dwh.dim_patient (
  patient_id bigserial primary key,
  fullname varchar(100) not null,
  birthdate date not null,
  gender char(1),
  phone varchar(25),
  email varchar(100),
  address varchar(255)
);

create table if not exists dwh.dim_insurance (
  insurance_id bigserial primary key,
  patient_id bigint,
  provider varchar(100),
  policy_number varchar(50),
  expiration_date date
);

create table if not exists dwh.dim_datetime (
  datetime_id bigserial primary key,
  full_datetime timestamp not null,
  date date,
  year int,
  month int,
  day int,
  hour int,
  minute int,
  second int
);

create table if not exists dwh.dim_appointment (
  appointment_id bigserial primary key,
  reason varchar(255),
  status varchar(50),
  patient_id bigint,
  doctor_id bigint,
  datetime_id bigint
);

create table if not exists dwh.fact_billing (
  billing_id bigserial primary key,
  patient_id bigint,
  doctor_id bigint,
  datetime_id bigint,
  appointment_id bigint,
  amount decimal(10,2),
  billing_date timestamp,
  status varchar(50)
);

create table if not exists dwh.fact_satisfaction (
  satisfaction_id bigserial primary key,
  patient_id bigint,
  doctor_id bigint,
  datetime_id bigint,
  appointment_id bigint,
  rating int,
  comments text,
  feedback_date timestamp
);

-- 4) IMPORT FROM FDW TABLES INTO STAGING

insert into staging.stg_doctor (fullname, specialty, phone, email, effective_date)
select
  fullname,
  specialty,
  phone,
  email,
  now()
from fdw_oltp.doctors;

insert into staging.stg_patient (fullname, birthdate, gender, phone, email, address)
select
  fullname,
  birthdate,
  gender,
  phone,
  email,
  address
from fdw_oltp.patients;

insert into staging.stg_billing (
  patient_fullname,
  patient_birthdate,
  doctor_fullname,
  appointment_date,
  amount,
  billing_date,
  status
)
select
  patientfullname,
  patientbirthdate,
  doctorfullname,
  appointmentdate,
  amount,
  billingdate,
  status
from fdw_oltp.billing;

insert into staging.stg_appointment (
  appointment_id,
  doctor_fullname,
  patient_fullname,
  patient_birthdate,
  appointment_date,
  reason,
  status
)
select
  appointmentid,
  doctorfullname,
  patientfullname,
  patientbirthdate,
  appointmentdate,
  reason,
  status
from fdw_oltp.appointments;

insert into staging.stg_insurance (
  patient_fullname,
  patient_birthdate,
  provider,
  policy_number,
  expiration_date
)
select
  patientfullname,
  patientbirthdate,
  provider,
  policynumber,
  expirationdate
from fdw_oltp.insurancedetails;

insert into staging.stg_feedback (
  patient_fullname,
  doctor_fullname,
  appointment_date,
  rating,
  comments,
  feedback_date
)
select
  patientfullname,
  doctorfullname,
  appointmentdate,
  rating,
  comments,
  feedbackdate
from fdw_oltp.appointmentfeedback;

-- 5) VALIDATE STAGING

delete from staging.stg_doctor
where specialty not in (
  select specialty from reference.allowed_specialties
)
or fullname is null
or phone is null
or email is null;

delete from staging.stg_patient
where fullname is null
or birthdate is null
or birthdate > current_date;

delete from staging.stg_billing
where billing_date < now() - interval '12 months'
or amount < 0;

with cte_doctor as (
  select fullname, specialty, min(ctid) as keep_ctid
  from staging.stg_doctor
  group by fullname, specialty
  having count(*) > 1
)
delete from staging.stg_doctor s
using cte_doctor
where s.fullname = cte_doctor.fullname
and s.specialty = cte_doctor.specialty
and s.ctid <> cte_doctor.keep_ctid;

-- 6) INSERT DISTINCT SPECIALTIES INTO dim_specialty

insert into dwh.dim_specialty (specialty)
select distinct specialty
from staging.stg_doctor
where specialty is not null
and specialty <> ''
and not exists (
  select 1
  from dwh.dim_specialty ds
  where ds.specialty = staging.stg_doctor.specialty
);

-- 7) SCD TYPE 2 FOR dim_doctor

do $$
declare
  rec record;
begin
  for rec in
    select * from staging.stg_doctor
  loop
    if exists (
      select 1
      from dwh.dim_doctor
      where fullname = rec.fullname
      and iscurrent = true
    ) then
      update dwh.dim_doctor
      set expiration_date = now(),
          iscurrent = false
      where fullname = rec.fullname
      and iscurrent = true
      and (
        specialty <> rec.specialty
        or phone <> rec.phone
        or email <> rec.email
      );
      insert into dwh.dim_doctor (
        fullname, specialty, phone, email, effective_date, expiration_date, iscurrent
      )
      select
        rec.fullname,
        rec.specialty,
        rec.phone,
        rec.email,
        now(),
        null,
        true
      where not exists (
        select 1
        from dwh.dim_doctor
        where fullname = rec.fullname
        and iscurrent = true
        and specialty = rec.specialty
        and phone = rec.phone
        and email = rec.email
      );
    else
      insert into dwh.dim_doctor (
        fullname, specialty, phone, email, effective_date, expiration_date, iscurrent
      )
      values (
        rec.fullname,
        rec.specialty,
        rec.phone,
        rec.email,
        now(),
        null,
        true
      );
    end if;
  end loop;
end
$$;

-- 8) LOAD dim_patient

insert into dwh.dim_patient (
  fullname, birthdate, gender, phone, email, address
)
select
  fullname,
  birthdate,
  gender,
  phone,
  email,
  address
from staging.stg_patient
where fullname is not null
and birthdate is not null;

-- 9) LOAD dim_insurance

insert into dwh.dim_insurance (
  patient_id, provider, policy_number, expiration_date
)
select
  p.patient_id,
  s.provider,
  s.policy_number,
  s.expiration_date
from staging.stg_insurance s
join dwh.dim_patient p
  on p.fullname = s.patient_fullname
  and p.birthdate = s.patient_birthdate;

-- 10) LOAD dim_datetime

insert into dwh.dim_datetime (
  full_datetime, date, year, month, day, hour, minute, second
)
select distinct
  appointment_date,
  date(appointment_date),
  extract(year from appointment_date)::int,
  extract(month from appointment_date)::int,
  extract(day from appointment_date)::int,
  extract(hour from appointment_date)::int,
  extract(minute from appointment_date)::int,
  extract(second from appointment_date)::int
from staging.stg_appointment
where appointment_date is not null
and not exists (
  select 1
  from dwh.dim_datetime dd
  where dd.full_datetime = staging.stg_appointment.appointment_date
);

insert into dwh.dim_datetime (
  full_datetime, date, year, month, day, hour, minute, second
)
select distinct
  billing_date,
  date(billing_date),
  extract(year from billing_date)::int,
  extract(month from billing_date)::int,
  extract(day from billing_date)::int,
  extract(hour from billing_date)::int,
  extract(minute from billing_date)::int,
  extract(second from billing_date)::int
from staging.stg_billing
where billing_date is not null
and not exists (
  select 1
  from dwh.dim_datetime dd
  where dd.full_datetime = staging.stg_billing.billing_date
);

insert into dwh.dim_datetime (
  full_datetime, date, year, month, day, hour, minute, second
)
select distinct
  feedback_date,
  date(feedback_date),
  extract(year from feedback_date)::int,
  extract(month from feedback_date)::int,
  extract(day from feedback_date)::int,
  extract(hour from feedback_date)::int,
  extract(minute from feedback_date)::int,
  extract(second from feedback_date)::int
from staging.stg_feedback
where feedback_date is not null
and not exists (
  select 1
  from dwh.dim_datetime dd
  where dd.full_datetime = staging.stg_feedback.feedback_date
);

-- 11) LOAD dim_appointment

insert into dwh.dim_appointment (
  reason, status, patient_id, doctor_id, datetime_id
)
select
  s.reason,
  s.status,
  p.patient_id,
  d.doctor_id,
  dt.datetime_id
from staging.stg_appointment s
join dwh.dim_patient p
  on p.fullname = s.patient_fullname
  and p.birthdate = s.patient_birthdate
join dwh.dim_doctor d
  on d.fullname = s.doctor_fullname
  and d.iscurrent = true
join dwh.dim_datetime dt
  on dt.full_datetime = s.appointment_date;

-- 12) FACT BILLING

insert into dwh.fact_billing (
  patient_id,
  doctor_id,
  datetime_id,
  appointment_id,
  amount,
  billing_date,
  status
)
select
  p.patient_id,
  d.doctor_id,
  dd.datetime_id,
  a.appointment_id,
  b.amount,
  b.billing_date,
  b.status
from staging.stg_billing b
join dwh.dim_patient p
  on p.fullname = b.patient_fullname
  and p.birthdate = b.patient_birthdate
join dwh.dim_doctor d
  on d.fullname = b.doctor_fullname
  and d.iscurrent = true
left join dwh.dim_appointment a
  on a.patient_id = p.patient_id
  and a.doctor_id = d.doctor_id
join dwh.dim_datetime dd
  on dd.full_datetime = b.billing_date;

-- 13) FACT SATISFACTION

insert into dwh.fact_satisfaction (
  patient_id,
  doctor_id,
  datetime_id,
  appointment_id,
  rating,
  comments,
  feedback_date
)
select
  p.patient_id,
  d.doctor_id,
  dd.datetime_id,
  a.appointment_id,
  f.rating,
  f.comments,
  f.feedback_date
from staging.stg_feedback f
join dwh.dim_patient p
  on p.fullname = f.patient_fullname
join dwh.dim_doctor d
  on d.fullname = f.doctor_fullname
  and d.iscurrent = true
left join dwh.dim_appointment a
  on a.patient_id = p.patient_id
  and a.doctor_id = d.doctor_id
  and a.appointment_id is not null
join dwh.dim_datetime dd
  on dd.full_datetime = f.feedback_date;

-- 14) CLEAR STAGING

delete from staging.stg_doctor;
delete from staging.stg_patient;
delete from staging.stg_billing;
delete from staging.stg_appointment;
delete from staging.stg_insurance;
delete from staging.stg_feedback;
