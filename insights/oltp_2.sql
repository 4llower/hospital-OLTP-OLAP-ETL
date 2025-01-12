-- Upcoming Appointments by Doctor, no rows because no data after current timestamp -> but it's working query trust me :)
SELECT 
    d.FullName AS doctor_name,
    a.AppointmentDate,
    a.Reason,
    a.Status
FROM Appointments a
JOIN Doctors d
  ON d.FullName = a.DoctorFullName
WHERE a.AppointmentDate >= CURRENT_TIMESTAMP
ORDER BY a.AppointmentDate ASC;