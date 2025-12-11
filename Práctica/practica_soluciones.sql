-- Query B: Doctores de General Medicine
SELECT 
    p.name AS "Doctor Name", 
    m.name AS "Medication", 
    pr.date AS "Date"
FROM physician p
JOIN affiliated_with a ON p.employeeid = a.physicianid
JOIN department d ON a.departmentid = d.departmentid
JOIN prescribes pr ON p.employeeid = pr.physicianid
JOIN medication m ON pr.medicationid = m.code
WHERE d.name = 'General Medicine'
  AND (pr.date LIKE '%2023%' OR pr.date LIKE '%2024%');
  
-- Query C: Pacientes con estancia mas larga/corta
-- Parte 1: El ingreso mas largo (Longest Stay)
SELECT 
    p.name AS "Patient Name",
    s.roomid AS "Room Number",
    b.blockfloorid AS "Floor",
    b.blockcodeid AS "Block",
    DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) AS "Duration",
    'Longest Stay' AS "Type"
FROM stay s
JOIN patient p ON s.patientid = p.ssn
JOIN room r ON s.roomid = r.roomnumber
JOIN block b ON r.blockfloorid = b.blockfloorid AND r.blockcodeid = b.blockcodeid
ORDER BY Duration DESC
LIMIT 1

UNION

-- Parte 2: El ingreso mas corto (Shortest Stay)
SELECT 
    p.name AS "Patient Name",
    s.roomid AS "Room Number",
    b.blockfloorid AS "Floor",
    b.blockcodeid AS "Block",
    DATEDIFF(STR_TO_DATE(s.end_time, '%d/%m/%Y'), STR_TO_DATE(s.start_time, '%d/%m/%Y')) AS "Duration",
    'Shortest Stay' AS "Type"
FROM stay s
JOIN patient p ON s.patientid = p.ssn
JOIN room r ON s.roomid = r.roomnumber
JOIN block b ON r.blockfloorid = b.blockfloorid AND r.blockcodeid = b.blockcodeid
ORDER BY Duration ASC
LIMIT 1;
