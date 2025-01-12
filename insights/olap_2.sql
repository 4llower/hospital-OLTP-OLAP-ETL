-- Average Satisfaction Rating by Specialty
SELECT 
    s.specialty AS specialty,
    ROUND(AVG(fs.rating), 2) AS avg_rating
FROM dwh.fact_satisfaction fs
JOIN dwh.dim_doctor dd
  ON dd.doctor_id = fs.doctor_id
JOIN dwh.dim_specialty s
  ON s.specialty = dd.specialty
GROUP BY s.specialty
ORDER BY avg_rating DESC;
