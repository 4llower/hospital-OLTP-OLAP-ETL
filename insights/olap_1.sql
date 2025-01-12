-- Total Billing Amount by Doctor (Year to Date)
SELECT 
    dd.fullname AS doctor_name,
    SUM(fb.amount) AS total_billing
FROM dwh.fact_billing fb
JOIN dwh.dim_doctor dd
  ON dd.doctor_id = fb.doctor_id
JOIN dwh.dim_datetime dt
  ON dt.datetime_id = fb.datetime_id
WHERE dt.year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY dd.fullname
ORDER BY SUM(fb.amount) DESC;
