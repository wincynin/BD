USE hospital_management_system;

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
(SELECT 
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
LIMIT 1)

UNION

(SELECT 
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
LIMIT 1);


-- Query D: Actualización de Medicamentos (Posible Descatalogación)
SET SQL_SAFE_UPDATES = 0;

UPDATE medication m
SET m.description = CONCAT(m.description, ' Possible discontinuation')
WHERE m.code NOT IN (
    SELECT DISTINCT pr.medicationid
    FROM prescribes pr
    JOIN physician phy ON pr.physicianid = phy.employeeid
    JOIN affiliated_with a ON phy.employeeid = a.physicianid
    JOIN department d ON a.departmentid = d.departmentid
    WHERE d.name = 'General Medicine'
      AND (pr.date LIKE '%2023%' OR pr.date LIKE '%2024%')
)
AND m.description NOT LIKE '%Possible discontinuation%'; -- Prevent double labeling

SELECT * FROM medication WHERE description LIKE '%Possible discontinuation%';

SET SQL_SAFE_UPDATES = 1;


-- Query E: Estadísticas de Doctores (Agregación)
SELECT 
    p.name AS "Doctor Name",
    COUNT(u.procedureid) AS "Total Procedures",
    -- COALESCE converts NULL (no activity) to 0 for cleaner output
    COALESCE(SUM(mp.cost), 0) AS "Total Cost",
    COALESCE(AVG(mp.cost), 0) AS "Average Cost"
FROM physician p

-- LEFT JOIN keeps the Doctor even if 'undergoes' is empty (NULL)
LEFT JOIN undergoes u ON p.employeeid = u.physicianid
LEFT JOIN medical_procedure mp ON u.procedureid = mp.code
GROUP BY p.employeeid, p.name
ORDER BY `Total Procedures` DESC;


-- Query F: División Relacional (Doctores "Expertos")
SELECT 
    p.name AS "Doctor Name",
    p.position AS "Position"
FROM physician p
JOIN undergoes u ON p.employeeid = u.physicianid
JOIN medical_procedure mp ON u.procedureid = mp.code
GROUP BY p.employeeid, p.name, p.position
HAVING 
    COUNT(u.procedureid) > 3
    AND
    COUNT(DISTINCT CASE WHEN mp.cost > 5000 THEN mp.code END) = (
        SELECT COUNT(*) 
        FROM medical_procedure 
        WHERE cost > 5000
    );


-- Query G: Enfermería Consistente (Mismo Bloque y Mismo Doctor)
SELECT 
    n.name AS "Nurse Name",
    n.position AS "Position"
FROM nurse n
JOIN on_call oc ON n.employeeid = oc.nurseid
LEFT JOIN undergoes u ON n.employeeid = u.assistingnurseid
GROUP BY n.employeeid, n.name, n.position
HAVING 
    COUNT(DISTINCT oc.blockfloorid, oc.blockcodeid) = 1
    AND 
    COUNT(DISTINCT u.physicianid) <= 1;
    
    
-- Query H: Estadísticas por Medicamento (Moda y Promedios)
SELECT 
    m.code AS "Medication Code",
    m.name AS "Medication Name",
    COUNT(pr.date) AS "Total Prescriptions",
    AVG(pr.dose) AS "Avg Dose",
    (SELECT GROUP_CONCAT(p.name SEPARATOR ', ')
     FROM physician p
     WHERE p.employeeid IN (
         SELECT pr2.physicianid
         FROM prescribes pr2
         WHERE pr2.medicationid = m.code
         GROUP BY pr2.physicianid
         HAVING COUNT(*) = (
             SELECT MAX(cnt)
             FROM (
                 SELECT COUNT(*) as cnt
                 FROM prescribes pr3
                 WHERE pr3.medicationid = m.code
                 GROUP BY pr3.physicianid
             ) as counts
         )
     )
    ) AS "Top Prescriber(s)"
FROM medication m
JOIN prescribes pr ON m.code = pr.medicationid
GROUP BY m.code, m.name
ORDER BY `Total Prescriptions` DESC;


-- Query I: Medicamentos "Universales" (Doctores Multi-Departamento)
SELECT 
    m.name AS "Medication Name"
FROM medication m
JOIN prescribes pr ON m.code = pr.medicationid
JOIN physician p ON pr.physicianid = p.employeeid
WHERE p.employeeid IN (
    -- Filtro 1: Solo miramos doctores con > 1 departamento
    SELECT physicianid 
    FROM affiliated_with 
    GROUP BY physicianid 
    HAVING COUNT(departmentid) > 1
)
GROUP BY m.code, m.name
HAVING 
    -- Condicion: Cantidad de doctores (multi-depto) que recetaron ESTE medicamento...
    COUNT(DISTINCT p.employeeid) = (
        -- ...debe ser igual a la Cantidad TOTAL de doctores (multi-depto) que existen.
        SELECT COUNT(*) 
        FROM (
            SELECT physicianid 
            FROM affiliated_with 
            GROUP BY physicianid 
            HAVING COUNT(departmentid) > 1
        ) as total_multi_dept_docs
    );
    
 
-- Apartado J: Trigger de Verificación de Certificados
DELIMITER //

CREATE TRIGGER check_doctor_certification
BEFORE INSERT ON undergoes
FOR EACH ROW
BEGIN
    DECLARE cert_count INT;
    DECLARE cert_valid INT;
    DECLARE proc_date DATE;
    
    -- Convertimos la fecha del procedimiento (texto) a fecha real
    SET proc_date = STR_TO_DATE(NEW.date, '%d/%m/%Y');

    -- Verificar si existe CUALQUIER certificación para este doctor y procedimiento
    SELECT COUNT(*) INTO cert_count
    FROM trained_in
    WHERE physicianid = NEW.physicianid
      AND treatmentid = NEW.procedureid;

    IF cert_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: El doctor no posee la certificación para este procedimiento.';
    ELSE
        -- Si existe, verificamos que esté vigente en la fecha del procedimiento
        SELECT COUNT(*) INTO cert_valid
        FROM trained_in
        WHERE physicianid = NEW.physicianid
          AND treatmentid = NEW.procedureid
          AND proc_date >= STR_TO_DATE(certificationdate, '%d/%m/%Y')
          AND proc_date <= STR_TO_DATE(certificationexpires, '%d/%m/%Y');

        IF cert_valid = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: La certificación del doctor está caducada o no es válida para la fecha.';
        END IF;
    END IF;
END //

DELIMITER ;

-- ---------------------------------------------------------
-- TEST 1: FALLO - NO CERTIFICADO
-- ---------------------------------------------------------
-- Intentamos que el Dr. Elliot Reid (ID 2), que NO tiene ninguna 
-- certificación en la tabla 'trained_in', haga el procedimiento 1.
-- RESULTADO ESPERADO: Error "El doctor no posee la certificación..."
INSERT INTO undergoes VALUES (100000001, 1, 3215, '02/05/2008', 2, 101);

-- ---------------------------------------------------------
-- TEST 2: FALLO - CERTIFICADO CADUCADO
-- ---------------------------------------------------------
-- El Dr. Turk (ID 3) tiene certificado para proc 1, pero caduca en 2008.
-- Intentamos hacerlo en 2023.
-- RESULTADO ESPERADO: Error "La certificación ... está caducada"
INSERT INTO undergoes VALUES (100000001, 1, 3215, '01/01/2023', 3, 101);

-- ---------------------------------------------------------
-- TEST 3: ÉXITO - TODO CORRECTO
-- ---------------------------------------------------------
-- El Dr. Turk (ID 3) hace el proc 1 en Mayo de 2008 (dentro de su fecha válida).
-- Usamos '3215' como stayid porque existe en tu base de datos.
-- RESULTADO ESPERADO: 1 row affected (Check verde)
INSERT INTO undergoes VALUES (100000001, 1, 3215, '04/05/2008', 3, 101);


-- Apartado K: Configuración de Borrado en Cascada y Trigger de Borrado Seguro
-- Eliminamos las FKs antiguas (nombres genéricos generados por MySQL)
ALTER TABLE appointments DROP FOREIGN KEY appointments_ibfk_1;
ALTER TABLE prescribes DROP FOREIGN KEY prescribes_ibfk_2;
ALTER TABLE stay DROP FOREIGN KEY stay_ibfk_1;
ALTER TABLE undergoes DROP FOREIGN KEY undergoes_ibfk_1;

-- Las recreamos con la regla ON DELETE CASCADE
ALTER TABLE appointments 
ADD CONSTRAINT fk_appointments_patient 
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

ALTER TABLE prescribes 
ADD CONSTRAINT fk_prescribes_patient 
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

ALTER TABLE stay 
ADD CONSTRAINT fk_stay_patient 
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

ALTER TABLE undergoes 
ADD CONSTRAINT fk_undergoes_patient 
FOREIGN KEY (patientid) REFERENCES patient(ssn) ON DELETE CASCADE;

-- Trigger de Borrado Seguro
DELIMITER //

CREATE TRIGGER prevent_patient_deletion
BEFORE DELETE ON patient
FOR EACH ROW
BEGIN
    DECLARE recent_activity INT DEFAULT 0;
    DECLARE future_activity INT DEFAULT 0;
    DECLARE cutoff_date DATE;
    DECLARE today DATE;

    -- Definimos "hoy" y la fecha de corte (hace 3 años)
    SET today = CURDATE(); -- O usa una fecha fija como '2025-01-01' si prefieres simular estar en el futuro
    SET cutoff_date = DATE_SUB(today, INTERVAL 3 YEAR);

    -- Comprobar Citas (Appointments)
    -- Futuras o Recientes (últimos 3 años)
    SELECT COUNT(*) INTO recent_activity
    FROM appointments
    WHERE patientid = OLD.ssn
      AND STR_TO_DATE(start_dt_time, '%d/%m/%Y') >= cutoff_date;

    IF recent_activity > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: No se puede borrar al paciente. Tiene citas recientes o futuras.';
    END IF;

    -- Comprobar Procedimientos (Undergoes)
    SELECT COUNT(*) INTO recent_activity
    FROM undergoes
    WHERE patientid = OLD.ssn
      AND STR_TO_DATE(date, '%d/%m/%Y') >= cutoff_date;

    IF recent_activity > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: No se puede borrar al paciente. Tiene procedimientos recientes.';
    END IF;

    -- Comprobar Recetas (Prescribes)
    SELECT COUNT(*) INTO recent_activity
    FROM prescribes
    WHERE patientid = OLD.ssn
      AND STR_TO_DATE(date, '%d/%m/%Y') >= cutoff_date;

    IF recent_activity > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: No se puede borrar al paciente. Tiene recetas recientes.';
    END IF;

    -- Comprobar Estancias (Stay)
    SELECT COUNT(*) INTO recent_activity
    FROM stay
    WHERE patientid = OLD.ssn
      AND STR_TO_DATE(start_time, '%d/%m/%Y') >= cutoff_date;

    IF recent_activity > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: No se puede borrar al paciente. Tiene estancias hospitalarias recientes.';
    END IF;

END //

DELIMITER ;

-- PRUEBAS DEL TRIGGER
-- 1. Intento Fallido: Borrar paciente con actividad reciente
-- El paciente 100000001 tiene mucha actividad en 2008... espera.
-- En tu base de datos actual, 2008 fue hace MÁS de 3 años respecto a hoy (2025).
-- Para probar el fallo, necesitamos insertarle una cita "hoy" o hace poco.

-- Insertamos una cita "trampa" reciente para el paciente 100000001
INSERT INTO appointments (appointmentid, patientid, physicianid, start_dt_time, end_dt_time, examinationroom)
VALUES (999999, 100000001, 1, DATE_FORMAT(NOW(), '%d/%m/%Y'), DATE_FORMAT(NOW(), '%d/%m/%Y'), 'A');

-- Ahora intentamos borrarlo (DEBERÍA FALLAR)
DELETE FROM patient WHERE ssn = 100000001;

-- 2. Intento Exitoso: Borrar un paciente antiguo o inactivo
-- Creemos un paciente fantasma sin historial
INSERT INTO patient(ssn, name, address, phonenum, insuranceid, pcpid)
VALUES (999999999, 'Ghost Patient', 'Nowhere', '000-0000', 99999999, 1);

-- Lo borramos (DEBERÍA FUNCIONAR)
DELETE FROM patient WHERE ssn = 999999999;


-- Apartado L: Función de Coste Total por Paciente
DELIMITER //

CREATE FUNCTION total_cost_patient(patient_ssn INT) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total INT DEFAULT 0;

    SELECT COALESCE(SUM(mp.cost), 0) INTO total
    FROM undergoes u
    JOIN medical_procedure mp ON u.procedureid = mp.code
    WHERE u.patientid = patient_ssn;

    RETURN total;
END //

DELIMITER ;

-- CONSULTA APARTADO L (Usando la función)
SELECT 
    p.name AS "Patient Name",
    p.address AS "Address",
    total_cost_patient(p.ssn) AS "Total Spent"
FROM patient p
ORDER BY "Total Spent" DESC
LIMIT 1;


-- APARTADO M: Función de Coste de Estancia
DELIMITER //

CREATE FUNCTION calc_stay_cost(p_stayid INT) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    DECLARE v_roomtype VARCHAR(20);
    DECLARE v_daily_rate INT DEFAULT 0;
    DECLARE v_start DATE;
    DECLARE v_end DATE;

    -- Obtenemos datos de la estancia y el tipo de habitación
    SELECT r.roomtype, STR_TO_DATE(s.start_time, '%d/%m/%Y'), STR_TO_DATE(s.end_time, '%d/%m/%Y')
    INTO v_roomtype, v_start, v_end
    FROM stay s
    JOIN room r ON s.roomid = r.roomnumber
    WHERE s.stayid = p_stayid;

    -- Calculamos la duración en días
    SET v_days = DATEDIFF(v_end, v_start);
    
    -- Ajuste: Si entra y sale el mismo día, cobramos 1 día (o el coste sería 0)
    IF v_days <= 0 THEN
        SET v_days = 1;
    END IF;

    -- Determinamos el precio por día según el tipo
    CASE v_roomtype
        WHEN 'ICU' THEN SET v_daily_rate = 500;
        WHEN 'Single' THEN SET v_daily_rate = 300;
        WHEN 'Double' THEN SET v_daily_rate = 150;
        ELSE SET v_daily_rate = 100;
    END CASE;

    -- Devolvemos el coste total
    RETURN (v_days * v_daily_rate);
END //

DELIMITER ;

-- Probamos con una estancia existente
SELECT 
    stayid,
    calc_stay_cost(stayid) AS "Total Stay Cost"
FROM stay
ORDER BY `Total Stay Cost` DESC
LIMIT 5;


-- Apartado N: Procedimiento de Reporte Médico
DELIMITER //

CREATE PROCEDURE physician_report(
    IN p_physician_id INT,
    IN p_start_date VARCHAR(10),
    IN p_end_date VARCHAR(10),
    OUT p_report TEXT
)
BEGIN
    -- Variables para el cursor de citas
    DECLARE done INT DEFAULT 0;
    DECLARE v_app_id INT;
    DECLARE v_pat_name VARCHAR(50);
    DECLARE v_app_date VARCHAR(10);
    DECLARE v_doc_name VARCHAR(50);
    
    -- Variables para el cursor de medicinas
    DECLARE done_meds INT DEFAULT 0;
    DECLARE v_med_name VARCHAR(50);
    DECLARE v_med_count INT;
    
    -- Variable acumuladora del texto final
    DECLARE v_buffer TEXT DEFAULT '';

    -- CURSOR 1: Busca las citas del doctor en el rango
    DECLARE cur_appointments CURSOR FOR 
        SELECT a.appointmentid, p.name, a.start_dt_time
        FROM appointments a
        JOIN patient p ON a.patientid = p.ssn
        WHERE a.physicianid = p_physician_id
          AND STR_TO_DATE(a.start_dt_time, '%d/%m/%Y') >= STR_TO_DATE(p_start_date, '%d/%m/%Y')
          AND STR_TO_DATE(a.start_dt_time, '%d/%m/%Y') <= STR_TO_DATE(p_end_date, '%d/%m/%Y')
        ORDER BY STR_TO_DATE(a.start_dt_time, '%d/%m/%Y');

    -- Handler para cuando se acaben las citas
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Obtenemos el nombre del doctor para el encabezado
    SELECT name INTO v_doc_name FROM physician WHERE employeeid = p_physician_id;
    SET v_buffer = CONCAT('INFORME DE ', v_doc_name, '\n');

    -- Abrimos el cursor de citas
    OPEN cur_appointments;

    read_loop: LOOP
        FETCH cur_appointments INTO v_app_id, v_pat_name, v_app_date;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Añadimos la linea del paciente: "John Smith (24/4/2008)"
        SET v_buffer = CONCAT(v_buffer, v_pat_name, ' (', v_app_date, ')\n');

        -- Sub-bloque para buscar medicinas de ESA cita
        block2: BEGIN
            DECLARE cur_meds CURSOR FOR 
                SELECT m.name 
                FROM prescribes pr
                JOIN medication m ON pr.medicationid = m.code
                WHERE pr.appointmentid = v_app_id;
            
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_meds = 1;

            -- Contamos si hay medicinas antes de abrir el cursor
            SELECT COUNT(*) INTO v_med_count FROM prescribes WHERE appointmentid = v_app_id;

            IF v_med_count = 0 THEN
                SET v_buffer = CONCAT(v_buffer, '# No medications prescribed\n');
            ELSE
                OPEN cur_meds;
                SET done_meds = 0; -- Reiniciamos flag para el bucle interno
                
                med_loop: LOOP
                    FETCH cur_meds INTO v_med_name;
                    IF done_meds THEN
                        LEAVE med_loop;
                    END IF;
                    SET v_buffer = CONCAT(v_buffer, '# ', v_med_name, '\n');
                END LOOP;
                CLOSE cur_meds;
            END IF;
        END block2;

    END LOOP;

    CLOSE cur_appointments;
    
    -- Asignamos el resultado final a la variable de salida
    SET p_report = v_buffer;
END //

DELIMITER ;

-- Probamos con el Doctor 1 (John Dorian) en un rango amplio
CALL physician_report(1, '01/01/2000', '01/01/2030', @resultado);
SELECT @resultado;


/*
-------------------------------------------------------------------------
 Apartado: Vistas y Seguridad
-------------------------------------------------------------------------
*/

-- 1. Creación de la Vista
-- Muestra detalles de recetas de forma simplificada
CREATE OR REPLACE VIEW view_prescribed_medications AS
SELECT 
	pr.patientid AS "Patient SSN",
    m.code AS "Medication Code",
    m.name AS "Medication Name",
    m.brand AS "Brand",
    p.name AS "Patient Name",
    pr.date AS "Date",
    d.name AS "Doctor Name"
FROM prescribes pr
JOIN medication m ON pr.medicationid = m.code
JOIN patient p ON pr.patientid = p.ssn
JOIN physician d ON pr.physicianid = d.employeeid;

-- 2. Creación del Usuario y Permisos
-- Creamos un usuario 'hospital_guest' con contraseña '1234'
DROP USER IF EXISTS 'hospital_guest'@'localhost';
CREATE USER 'hospital_guest'@'localhost' IDENTIFIED BY '1234';

-- Le damos permiso EXCLUSIVAMENTE de lectura (SELECT) sobre la vista
GRANT SELECT ON hospital_management_system.view_prescribed_medications TO 'hospital_guest'@'localhost';

-- Recargamos los privilegios para asegurar que se apliquen
FLUSH PRIVILEGES;