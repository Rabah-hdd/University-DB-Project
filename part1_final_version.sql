/*
-----------------------------------------------------------------------
   PROJECT PART I: UNIVERSITY DATABASE SCHEMA & DATA
   FILE: University_Schema_And_Data.sql
   AUTHOR: [RABAH-HADDADI /MOHAMED-ABBACI / A1]
   DATE: 2026-01-06
-----------------------------------------------------------------------
*/

-- ====================================================================
-- 1. DATA DEFINITION LANGUAGE (DDL) - TABLE CREATION
-- ====================================================================

-- 1.1 Department Table
CREATE TABLE Department (
    department_id INTEGER NOT NULL,
    name VARCHAR(25) NOT NULL,
    CONSTRAINT un_department_name UNIQUE (name)
);

-- 1.2 Student Table
CREATE TABLE Student (
    student_id INTEGER NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    first_name VARCHAR(25) NOT NULL,
    dob DATE NOT NULL,
    address VARCHAR(50) DEFAULT NULL,
    city VARCHAR(25) DEFAULT NULL,
    zip_code VARCHAR(9) DEFAULT NULL,
    phone VARCHAR(15) DEFAULT NULL,
    fax VARCHAR(15) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL
);

-- 1.3 Room Table
CREATE TABLE Room (
    building VARCHAR(1) NOT NULL,
    roomno VARCHAR(20) NOT NULL,
    capacity INTEGER,
    CONSTRAINT room_capacity_check CHECK (capacity > 1)
);

-- 1.4 Course Table
CREATE TABLE Course (
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    name VARCHAR(60) NOT NULL,
    description VARCHAR(1000)
);

-- 1.5 Instructor Table
CREATE TABLE Instructor (
    instructor_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    first_name VARCHAR(25) NOT NULL,
    rank VARCHAR(25),
    phone VARCHAR(15) DEFAULT NULL,
    fax VARCHAR(15) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL,
    CONSTRAINT ck_instructor_rank CHECK (rank IN ('Substitute', 'MCB', 'MCA', 'PROF'))
);

-- 1.6 Reservation Table
CREATE TABLE Reservation (
    reservation_id INTEGER NOT NULL,
    building VARCHAR(1) NOT NULL,
    roomno VARCHAR(20) NOT NULL,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    instructor_id INTEGER NOT NULL,
    reserv_date DATE DEFAULT CURRENT_DATE NOT NULL,
    start_time TIME DEFAULT CURRENT_TIME NOT NULL,
    end_time TIME DEFAULT '23:00:00' NOT NULL,
    hours_number INTEGER NOT NULL,
    CONSTRAINT ck_reservation_hours_number CHECK (hours_number >= 1),
    CONSTRAINT ck_reservation_startendtime CHECK (start_time < end_time)
);

-- 1.7 Enrollment Table (Schema Update 2.4)
CREATE TABLE Enrollment (
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE NOT NULL
);

-- 1.8 Marks Table (Schema Update 2.4)
CREATE TABLE Marks (
    mark_id SERIAL NOT NULL, -- Using SERIAL for auto-increment
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    mark_value NUMERIC(5,2) NOT NULL,
    mark_type VARCHAR(50)
);

-- 1.9 Student Audit Log Table (Lab 4)
CREATE TABLE Student_Audit_Log (
    audit_id SERIAL NOT NULL, -- Using SERIAL for auto-increment
    operation_type VARCHAR(10) NOT NULL,
    audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50) DEFAULT SESSION_USER,
    description TEXT
);

-- ====================================================================
-- 2. CONSTRAINTS (Primary & Foreign Keys)
-- ====================================================================

-- 2.1 Primary Keys
ALTER TABLE Department ADD CONSTRAINT pk_department PRIMARY KEY (department_id);
ALTER TABLE Student ADD CONSTRAINT pk_student PRIMARY KEY (student_id);
ALTER TABLE Room ADD CONSTRAINT pk_room PRIMARY KEY (building, roomno);
ALTER TABLE Course ADD CONSTRAINT pk_course PRIMARY KEY (course_id, department_id);
ALTER TABLE Instructor ADD CONSTRAINT pk_instructor PRIMARY KEY (instructor_id);
ALTER TABLE Reservation ADD CONSTRAINT pk_reservation PRIMARY KEY (reservation_id);
ALTER TABLE Enrollment ADD CONSTRAINT pk_enrollment PRIMARY KEY (student_id, course_id, department_id);
ALTER TABLE Marks ADD CONSTRAINT pk_marks PRIMARY KEY (mark_id);
ALTER TABLE Student_Audit_Log ADD CONSTRAINT pk_student_audit_log PRIMARY KEY (audit_id);

-- 2.2 Foreign Keys
-- Course -> Department
ALTER TABLE Course 
    ADD CONSTRAINT fk_course_department FOREIGN KEY (department_id) 
    REFERENCES Department(department_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Instructor -> Department
ALTER TABLE Instructor 
    ADD CONSTRAINT fk_instructor_department FOREIGN KEY (department_id) 
    REFERENCES Department(department_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Reservation -> Course
ALTER TABLE Reservation 
    ADD CONSTRAINT fk_reservation_course FOREIGN KEY (course_id, department_id) 
    REFERENCES Course(course_id, department_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Reservation -> Instructor
ALTER TABLE Reservation 
    ADD CONSTRAINT fk_reservation_instructor FOREIGN KEY (instructor_id) 
    REFERENCES Instructor(instructor_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Reservation -> Room
ALTER TABLE Reservation 
    ADD CONSTRAINT fk_reservation_room FOREIGN KEY (building, roomno) 
    REFERENCES Room(building, roomno) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Enrollment -> Course
ALTER TABLE Enrollment 
    ADD CONSTRAINT fk_enroll_course FOREIGN KEY (course_id, department_id) 
    REFERENCES Course(course_id, department_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Enrollment -> Student
ALTER TABLE Enrollment 
    ADD CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) 
    REFERENCES Student(student_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Marks -> Course
ALTER TABLE Marks 
    ADD CONSTRAINT fk_marks_course FOREIGN KEY (course_id, department_id) 
    REFERENCES Course(course_id, department_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;

-- Marks -> Student
ALTER TABLE Marks 
    ADD CONSTRAINT fk_marks_student FOREIGN KEY (student_id) 
    REFERENCES Student(student_id) 
    ON UPDATE RESTRICT ON DELETE RESTRICT;


-- ====================================================================
-- 3. DATA INSERTION
-- ====================================================================

-- Department Data
INSERT INTO Department (department_id, name) VALUES (1, 'SADS');
INSERT INTO Department (department_id, name) VALUES (2, 'CCS');
INSERT INTO Department (department_id, name) VALUES (3, 'GRC');
INSERT INTO Department (department_id, name) VALUES (4, 'INS');
INSERT INTO Department (department_id, name) VALUES (10, 'DBMS');

-- Room Data
INSERT INTO Room (building, roomno, capacity) VALUES ('B', '020', 15);
INSERT INTO Room (building, roomno, capacity) VALUES ('B', '022', 15);
INSERT INTO Room (building, roomno, capacity) VALUES ('A', '301', 45);
INSERT INTO Room (building, roomno, capacity) VALUES ('C', 'Lecture Hall 1', 500);
INSERT INTO Room (building, roomno, capacity) VALUES ('C', 'Lecture Hall 2', 200);

-- Student Data
INSERT INTO Student (student_id, last_name, first_name, dob, address, city, zip_code, phone, fax, email) VALUES 
(1, 'Ali', 'Ben Ali', '1979-02-18', '50, 1st street', 'Algiers', '16000', '0143567890', NULL, 'A1@yahoo.fr'),
(2, 'Amar', 'Ben Ammar', '1980-08-23', '10, Avenue b', 'BATNA', '05000', '0678567801', NULL, 'pt@yahoo.fr'),
(3, 'Ameur', 'Ben Ameur', '1978-05-12', '25, 2nd street', 'Oran', '31000', '0145678956', '0145678956', 'o@yahoo.fr'),
(4, 'Aissa', 'Ben Aissa', '1979-07-15', '56, Road', 'Annaba', '23000', '0678905645', NULL, 'd@hotmail.com'),
(5, 'Fatima', 'Ben Abdedallah', '1979-08-15', '45, Faubourg', 'Constantine', '25000', NULL, NULL, NULL);

-- Course Data
INSERT INTO Course (course_id, department_id, name, description) VALUES 
(1, 1, 'Databases', 'Licence(L3) : Modeling E/A and UML, Relational Model, Relational Algebra, Relational calculs,SQL, NFs and FDs'),
(2, 1, 'C++ progr.', 'Level Master 1'),
(3, 1, 'Advanced DBs', 'Level Master 2 -Program Licence and Master 1'),
(4, 4, 'English', '');

-- Instructor Data
INSERT INTO Instructor (instructor_id, department_id, last_name, first_name, rank, phone, fax, email) VALUES 
(1, 1, 'Abbas', 'BenAbbes', 'MCA', '4185', '4091', 'Ab@yahoo.fr'),
(2, 1, 'Mokhtar', 'BenMokhtar', 'Substitute', NULL, NULL, NULL),
(3, 1, 'Djemaa', 'Ben Mohamed', 'MCB', NULL, NULL, NULL),
(4, 1, 'Lahlou', 'Mohamed', 'PROF', NULL, NULL, NULL),
(5, 1, 'Abla', 'Chad', 'MCA', NULL, NULL, 'ab@lgmail.com'),
(6, 4, 'Mariam', 'BALI', 'Substitute', NULL, NULL, NULL);

-- Reservation Data
INSERT INTO Reservation VALUES (1, 'B', '022', 1, 1, 1, '2006-10-15', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (2, 'B', '022', 1, 1, 4, '2006-11-04', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (3, 'B', '022', 1, 1, 4, '2006-11-07', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (4, 'B', '020', 1, 1, 5, '2006-10-20', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (5, 'B', '020', 1, 1, 4, '2006-12-09', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (6, 'A', '301', 2, 1, 1, '2006-09-02', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (7, 'A', '301', 2, 1, 1, '2006-09-03', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (8, 'A', '301', 2, 1, 1, '2006-09-10', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (9, 'A', '301', 3, 1, 1, '2006-09-24', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (10, 'B', '022', 3, 1, 1, '2006-10-15', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (11, 'A', '301', 3, 1, 1, '2006-10-01', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (12, 'A', '301', 3, 1, 1, '2006-10-08', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (13, 'B', '022', 1, 1, 4, '2006-11-03', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (14, 'B', '022', 1, 1, 5, '2006-10-20', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (15, 'B', '022', 1, 1, 4, '2006-12-09', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (16, 'B', '022', 1, 1, 4, '2006-09-03', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (17, 'B', '022', 1, 1, 5, '2006-09-10', '08:30:00', '11:45:00', 3);
INSERT INTO Reservation VALUES (18, 'B', '022', 1, 1, 4, '2006-09-24', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (19, 'B', '022', 1, 1, 5, '2006-10-01', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (20, 'B', '022', 1, 1, 1, '2006-10-08', '13:45:00', '17:00:00', 3);
INSERT INTO Reservation VALUES (21, 'B', '022', 1, 1, 4, '2003-09-02', '08:30:00', '11:45:00', 3);


-- ====================================================================
-- 4. VIEWS & MATERIALIZED VIEWS
-- ====================================================================

-- 4.1 Regular View: Number of reservations per teacher
CREATE VIEW instructor_reservation_count AS
 SELECT i.instructor_id,
    i.first_name,
    i.last_name,
    count(r.reservation_id) AS total_reservations
   FROM instructor i
     LEFT JOIN reservation r ON i.instructor_id = r.instructor_id
  GROUP BY i.instructor_id, i.first_name, i.last_name
  ORDER BY (count(r.reservation_id)) DESC;

-- 4.2 Materialized View
CREATE MATERIALIZED VIEW instructor_reservation_mv AS
 SELECT instructor_id,
    first_name,
    last_name,
    total_reservations
   FROM instructor_reservation_count
  WITH NO DATA;

-- Refresh Materialized View
REFRESH MATERIALIZED VIEW instructor_reservation_mv;


-- ====================================================================
-- 5. FUNCTIONS
-- ====================================================================

-- 5.1 Simple Calculation Function
CREATE OR REPLACE FUNCTION calculate(t real) RETURNS real
    LANGUAGE sql
    AS $$
    SELECT $1 * 0.06;
$$;

-- 5.2 Get Department ID by Name
CREATE OR REPLACE FUNCTION get_department_id_by_name(dept_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    dept_id_result INT4;
BEGIN
    SELECT department_id INTO dept_id_result
    FROM Department
    WHERE name = dept_name;

    IF dept_id_result IS NULL THEN
        RAISE EXCEPTION 'Department with name % not found.', dept_name;
    END IF;

    RETURN dept_id_result;
END;
$$;

-- 5.3 Get Rooms by Capacity
CREATE OR REPLACE FUNCTION get_rooms_by_capacity(min_capacity integer) RETURNS TABLE(room_no character varying, building character varying, capacity integer)
    LANGUAGE sql
    AS $$
    SELECT
        roomno,
        building,
        capacity
    FROM
        Room
    WHERE
        capacity >= min_capacity;
$$;

-- 5.4 Check Reservation Conflict (Scalar: Returns ID of conflict or 0)
CREATE OR REPLACE FUNCTION check_reservation_conflict(p_building text, p_roomno text, p_res_date date, p_start_time time without time zone, p_end_time time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict_id INTEGER;
BEGIN
    SELECT 
        reservation_id INTO conflict_id
    FROM 
        Reservation R
    WHERE
        R.building = p_building
        AND R.roomno = p_roomno
        AND R.reserv_date = p_res_date
        AND (R.start_time, R.end_time) OVERLAPS (p_start_time, p_end_time)
    LIMIT 1;

    IF conflict_id IS NOT NULL THEN
        RETURN conflict_id;
    ELSE
        RETURN 0;
    END IF;
END;
$$;

-- 5.5 Audit Function (For Trigger)
CREATE OR REPLACE FUNCTION log_student_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Student_Audit_Log (operation_type, description)
    VALUES (
        TG_OP, 
        'Operation ' || TG_OP || ' executed on Student table by ' || SESSION_USER || ' at ' || NOW()
    );
    RETURN NULL; -- Required for AFTER triggers
END;
$$;


-- ====================================================================
-- 6. TRIGGERS
-- ====================================================================

CREATE TRIGGER trg_audit_students_statement 
AFTER INSERT OR DELETE OR UPDATE ON Student 
FOR EACH STATEMENT 
EXECUTE FUNCTION log_student_changes();


-- ====================================================================
-- 7. DATA MANIPULATION LANGUAGE (DML) - LAB 2 QUERIES
-- ====================================================================

-- 1. List of last names and first names of students.
SELECT last_name, first_name FROM Student;

-- 2. List of students who live in a chosen city (e.g., 'Algiers').
SELECT last_name, first_name FROM Student WHERE city = 'Algiers';

-- 3. List of students whose last name starts with 'A'.
SELECT last_name, first_name FROM Student WHERE last_name LIKE 'A%';

-- 4. Teachers whose second-to-last letter of the last name is 'E'.
SELECT last_name, first_name FROM Instructor WHERE last_name LIKE '%E_';

-- 5. Teachers sorted by department name, then last name, then first name.
SELECT I.last_name, I.first_name, D.name 
FROM Instructor I 
JOIN Department D ON I.department_id = D.department_id 
ORDER BY D.name ASC, I.last_name ASC, I.first_name ASC;

-- 6. How many teachers have the grade 'Substitute'.
SELECT COUNT(*) FROM Instructor WHERE rank = 'Substitute';

-- 7. Students who do not have a Fax number (NULL).
SELECT last_name, first_name FROM Student WHERE fax IS NULL;

-- 8. Titles of courses whose description includes 'Licence'.
SELECT name FROM Course WHERE description LIKE '%Licence%';

-- 9. Cost of each course (assuming 1 hour = 3000 DA).
SELECT C.name, SUM(R.hours_number * 3000) as total_cost
FROM Reservation R
JOIN Course C ON R.course_id = C.course_id AND R.department_id = C.department_id
GROUP BY C.name;

-- 10. Courses whose cost is between 3000 and 5000 DA.
SELECT C.name, SUM(R.hours_number * 3000) as total_cost
FROM Reservation R
JOIN Course C ON R.course_id = C.course_id AND R.department_id = C.department_id
GROUP BY C.name
HAVING SUM(R.hours_number * 3000) BETWEEN 3000 AND 5000;

-- 11. Average capacity and maximum capacity of rooms.
SELECT AVG(capacity) as avg_capacity, MAX(capacity) as max_capacity FROM Room;

-- 12. Rooms whose capacity is less than the average capacity.
SELECT * FROM Room WHERE capacity < (SELECT AVG(capacity) FROM Room);

-- 13. Teachers belonging to departments 'SADS' or 'CCS' (Using IN).
SELECT I.last_name, I.first_name 
FROM Instructor I 
JOIN Department D ON I.department_id = D.department_id
WHERE D.name IN ('SADS', 'CCS');

-- 14. Teachers belonging neither to 'SADS' nor 'CCS'.
SELECT I.last_name, I.first_name 
FROM Instructor I 
JOIN Department D ON I.department_id = D.department_id
WHERE D.name NOT IN ('SADS', 'CCS');

-- 15. Sort students by city.
SELECT * FROM Student ORDER BY city;

-- 16. How many courses are associated with each department?
SELECT D.name, COUNT(C.course_id) 
FROM Department D 
LEFT JOIN Course C ON D.department_id = C.department_id
GROUP BY D.name;

-- 17. Departments where number of courses >= 3.
SELECT D.name, COUNT(C.course_id) 
FROM Department D 
LEFT JOIN Course C ON D.department_id = C.department_id
GROUP BY D.name
HAVING COUNT(C.course_id) >= 3;

-- 18. Teachers with at least two reservations (Using EXISTS).
SELECT last_name, first_name 
FROM Instructor I
WHERE EXISTS (
    SELECT 1 FROM Reservation R 
    WHERE R.instructor_id = I.instructor_id 
    GROUP BY R.instructor_id 
    HAVING COUNT(*) >= 2
);

-- 19. Teachers with the most reservations (Using View & ALL).
SELECT first_name, last_name 
FROM instructor_reservation_count
WHERE total_reservations >= ALL (SELECT total_reservations FROM instructor_reservation_count);

-- 20. Teachers who do not have any reservations.
SELECT last_name, first_name 
FROM Instructor 
WHERE instructor_id NOT IN (SELECT DISTINCT instructor_id FROM Reservation);

-- 21. Rooms reserved on all dates stored in the database.
SELECT building, roomno 
FROM Room R
WHERE NOT EXISTS (
    SELECT DISTINCT reserv_date FROM Reservation
    EXCEPT
    SELECT reserv_date FROM Reservation RES WHERE RES.building = R.building AND RES.roomno = R.roomno
);

-- 22. Dates on which all rooms are reserved.
SELECT DISTINCT reserv_date 
FROM Reservation R1
WHERE NOT EXISTS (
    SELECT building, roomno FROM Room
    EXCEPT
    SELECT building, roomno FROM Reservation R2 WHERE R2.reserv_date = R1.reserv_date
);

-- 23. 5 Examples including UPDATE clause.
UPDATE Student SET city = 'Oran' WHERE student_id = 1;
UPDATE Room SET capacity = capacity + 5 WHERE building = 'B';
UPDATE Instructor SET rank = 'PROF' WHERE last_name = 'BenAbbes';
UPDATE Course SET description = 'Updated Description' WHERE course_id = 1;
UPDATE Reservation SET hours_number = 2 WHERE reservation_id = 1;

-- 24. 5 Examples of Aggregation.
SELECT COUNT(*) FROM Student;
SELECT building, SUM(capacity) FROM Room GROUP BY building;
SELECT department_id, COUNT(*) FROM Instructor GROUP BY department_id;
SELECT MAX(hours_number) FROM Reservation;
SELECT AVG(hours_number) FROM Reservation;

-- 25. 5 Examples of Set Operations.
SELECT city FROM Student UNION SELECT 'Paris';
SELECT city FROM Student INTERSECT SELECT city FROM Student WHERE student_id = 2;
SELECT student_id FROM Student EXCEPT SELECT student_id FROM Enrollment;
SELECT name FROM Department UNION ALL SELECT name FROM Department;
SELECT course_id FROM Course INTERSECT SELECT course_id FROM Reservation;

-- 26. 5 Examples of Querying inside FROM clause.
SELECT * FROM (SELECT last_name, city FROM Student) AS sub;
SELECT max_cap FROM (SELECT MAX(capacity) as max_cap FROM Room) AS sub;
SELECT avg_hours FROM (SELECT AVG(hours_number) as avg_hours FROM Reservation) AS sub;
SELECT * FROM (SELECT name FROM Department WHERE department_id = 1) AS sub;
SELECT count_id FROM (SELECT COUNT(*) as count_id FROM Instructor) AS sub;


-- ====================================================================
-- 8. TRANSACTIONS
-- ====================================================================

-- 1. Transaction Simple 1
BEGIN;
    INSERT INTO Department (department_id, name) VALUES (20, 'Physics');
    INSERT INTO Course (course_id, department_id, name, description) VALUES (101, 20, 'Mechanics', 'Intro to Mechanics');
COMMIT;

-- 2. Transaction Simple 2
BEGIN;
    UPDATE Room SET capacity = 60 WHERE roomno = '022' AND building = 'B';
    UPDATE Room SET capacity = 55 WHERE roomno = '020' AND building = 'B';
COMMIT;

-- 3. Transaction with Savepoint 1
BEGIN;
    INSERT INTO Student (student_id, last_name, first_name, dob) VALUES (99, 'Test', 'User', '2000-01-01');
    SAVEPOINT sp_student_inserted;
    -- ROLLBACK TO sp_student_inserted; -- Uncomment to test rollback
COMMIT;

-- 4. Transaction with Savepoint 2
BEGIN;
    INSERT INTO Reservation (reservation_id, building, roomno, course_id, department_id, instructor_id, hours_number)
    VALUES (100, 'B', '022', 1, 1, 1, 2);
    SAVEPOINT reservation_made;
    RELEASE SAVEPOINT reservation_made;
COMMIT;