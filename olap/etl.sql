create schema if not exists reference;

create table if not exists reference.allowed_specialties (
  specialty varchar(100) primary key
);

insert into reference.allowed_specialties (specialty)
values
('Cardiology'),
('Neurology'),
('Orthopedics')
on conflict (specialty) do nothing;

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

insert into staging.stg_billing (patient_fullname, patient_birthdate, doctor_fullname, appointment_date, amount, billing_date, status)
select
  patient_fullname,
  patient_birthdate,
  doctor_fullname,
  appointment_date,
  amount,
  billing_date,
  status
from fdw_oltp.billing;

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
from staging.stg_patient;

insert into dwh.fact_billing (
  patient_id, doctor_id, amount, billing_date, status
)
select
  p.patient_id,
  d.doctor_id,
  b.amount,
  b.billing_date,
  b.status
from staging.stg_billing b
join dwh.dim_patient p
  on p.fullname = b.patient_fullname
  and p.birthdate = b.patient_birthdate
join dwh.dim_doctor d
  on d.fullname = b.doctor_fullname
  and d.iscurrent = true;

delete from staging.stg_doctor;
delete from staging.stg_patient;
delete from staging.stg_billing;
