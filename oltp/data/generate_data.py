import random
from faker import Faker
import pandas as pd

fake = Faker()

num_records = 100

def generate_doctors():
    doctors = []
    for _ in range(num_records):
        doctor_name = fake.name()
        specialty = random.choice(['Cardiology', 'Neurology', 'Pediatrics', 'Orthopedics', 'Dermatology'])
        phone = fake.phone_number()
        email = fake.email()
        doctors.append([doctor_name, specialty, phone, email])
    return pd.DataFrame(doctors, columns=['FullName', 'Specialty', 'Phone', 'Email'])

def generate_patients():
    patients = []
    for _ in range(num_records):
        patient_name = fake.name()
        birth_date = fake.date_of_birth(minimum_age=18, maximum_age=90).strftime('%Y-%m-%d')
        gender = random.choice(['M', 'F'])
        phone = fake.phone_number()
        email = fake.email()
        address = fake.address()
        patients.append([patient_name, birth_date, gender, phone, email, address])
    return pd.DataFrame(patients, columns=['FullName', 'BirthDate', 'Gender', 'Phone', 'Email', 'Address'])

def generate_appointments(doctors, patients):
    appointments = []
    for _ in range(num_records):
        doctor = random.choice(doctors)
        patient = random.choice(patients)
        appointment_date = fake.date_this_year(before_today=True, after_today=False)
        reason = random.choice(['Routine checkup', 'Follow-up visit', 'Flu symptoms', 'Injury', 'General consultation'])
        status = random.choice(['Completed', 'Cancelled', 'No-show'])
        appointments.append([doctor['FullName'], patient['FullName'], patient['BirthDate'], appointment_date, reason, status])
    return pd.DataFrame(appointments, columns=['DoctorFullName', 'PatientFullName', 'PatientBirthDate', 'AppointmentDate', 'Reason', 'Status'])

def generate_medical_records(patients, doctors):
    medical_records = []
    for _ in range(num_records):
        patient = random.choice(patients)
        doctor = random.choice(doctors)
        diagnosis = random.choice(['Hypertension', 'Diabetes', 'Asthma', 'Back pain', 'Skin rash'])
        treatment = random.choice(['Medication prescribed', 'Physical therapy', 'Lifestyle changes advised', 'Surgery recommended'])
        notes = fake.text(max_nb_chars=100)
        medical_records.append([patient['FullName'], patient['BirthDate'], doctor['FullName'], fake.date_this_year(), diagnosis, treatment, notes])
    return pd.DataFrame(medical_records, columns=['PatientFullName', 'PatientBirthDate', 'DoctorFullName', 'Date', 'Diagnosis', 'Treatment', 'Notes'])

def generate_billing(patients, appointments):
    billing = []
    for _ in range(num_records):
        patient = random.choice(patients)
        appointment = random.choice(appointments)
        amount = round(random.uniform(100, 500), 2)
        billing_date = fake.date_this_year()
        status = random.choice(['Paid', 'Pending', 'Overdue'])
        billing.append([patient['FullName'], patient['BirthDate'], appointment['DoctorFullName'], appointment['AppointmentDate'], amount, billing_date, status])
    return pd.DataFrame(billing, columns=['PatientFullName', 'PatientBirthDate', 'DoctorFullName', 'AppointmentDate', 'Amount', 'BillingDate', 'Status'])

def generate_prescriptions(medical_records):
    prescriptions = []
    for _ in range(num_records):
        record = random.choice(medical_records)
        medication = random.choice(['Aspirin', 'Metformin', 'Ibuprofen', 'Amoxicillin', 'Lisinopril'])
        dosage = random.choice(['1 tablet daily', '2 tablets twice a day', '5 mg once a day', '10 mg twice a day'])
        frequency = random.choice(['Daily', 'Twice a day', 'Once a week', 'As needed'])
        notes = fake.text(max_nb_chars=100)
        prescriptions.append([record['PatientFullName'], record['PatientBirthDate'], record['DoctorFullName'], record['Date'], medication, dosage, frequency, notes])
    return pd.DataFrame(prescriptions, columns=['PatientFullName', 'PatientBirthDate', 'DoctorFullName', 'RecordDate', 'Medication', 'Dosage', 'Frequency', 'Notes'])

def generate_insurance_details(patients):
    insurance_details = []
    for _ in range(num_records):
        patient = random.choice(patients)
        provider = random.choice(['Blue Cross', 'Aetna', 'Cigna', 'United Health', 'Kaiser'])
        policy_number = fake.bothify(text='??-#####-####')
        expiration_date = fake.date_this_decade()
        insurance_details.append([patient['FullName'], patient['BirthDate'], provider, policy_number, expiration_date])
    return pd.DataFrame(insurance_details, columns=['PatientFullName', 'PatientBirthDate', 'Provider', 'PolicyNumber', 'ExpirationDate'])

def generate_appointment_feedback(appointments):
    feedback = []
    for _ in range(num_records):
        appointment = random.choice(appointments)
        rating = random.randint(1, 5)
        comments = fake.text(max_nb_chars=200)
        feedback_date = fake.date_this_year()
        feedback.append([appointment['PatientFullName'], appointment['DoctorFullName'], appointment['AppointmentDate'], rating, comments, feedback_date])
    return pd.DataFrame(feedback, columns=['PatientFullName', 'DoctorFullName', 'AppointmentDate', 'Rating', 'Comments', 'FeedbackDate'])

# Generate data
doctors = generate_doctors()
patients = generate_patients()
appointments = generate_appointments(doctors.to_dict('records'), patients.to_dict('records'))
medical_records = generate_medical_records(patients.to_dict('records'), doctors.to_dict('records'))
billing = generate_billing(patients.to_dict('records'), appointments.to_dict('records'))
prescriptions = generate_prescriptions(medical_records.to_dict('records'))
insurance_details = generate_insurance_details(patients.to_dict('records'))
appointment_feedback = generate_appointment_feedback(appointments.to_dict('records'))

doctors.to_csv('./generated/Doctors.csv', index=False)
patients.to_csv('./generated/Patients.csv', index=False)
appointments.to_csv('./generated/Appointments.csv', index=False)
medical_records.to_csv('./generated/MedicalRecords.csv', index=False)
billing.to_csv('./generated/Billing.csv', index=False)
prescriptions.to_csv('./generated/Prescriptions.csv', index=False)
insurance_details.to_csv('./generated/InsuranceDetails.csv', index=False)
appointment_feedback.to_csv('./generated/AppointmentFeedback.csv', index=False)

print("Data generation completed and saved as CSV files.")
