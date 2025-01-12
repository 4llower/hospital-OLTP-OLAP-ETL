-- Patients with the Most Appointments in the Last 3 Months
SELECT 
    a.PatientFullName AS patient_name,
    COUNT(*) AS total_appointments
FROM Appointments a
WHERE a.AppointmentDate >= (CURRENT_DATE - INTERVAL '3 months')
GROUP BY a.PatientFullName
ORDER BY COUNT(*) DESC
LIMIT 5;