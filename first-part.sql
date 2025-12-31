-- ==========================================
-- LAB 1: DATA DEFINITION LANGUAGE (DDL)
-- ==========================================

-- ==========================================
-- CLEANUP (Prevents conflicts)
-- ==========================================
DROP VIEW IF EXISTS v_reservations_per_teacher CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_reservations_per_teacher CASCADE;
DROP TABLE IF EXISTS Reservation, Marks, Enrollment, Instructor, Course, Room, Student, Department CASCADE;

-- 1. Create Tables (from Annex I)
CREATE TABLE Department(
    Department_id integer,
    name varchar(25) NOT NULL,
    CONSTRAINT UN_Department_Name UNIQUE (name),
    CONSTRAINT PK_Department PRIMARY KEY(Department_id)
);

CREATE TABLE Student(
    Student_ID integer,
    Last_Name varchar(25) NOT NULL,
    First_Name varchar(25) NOT NULL,
    DOB date NOT NULL,
    Address varchar(50) DEFAULT NULL,
    City varchar(25) DEFAULT NULL,
    Zip_Code varchar(9) DEFAULT NULL,
    Phone varchar(25) DEFAULT NULL,
    Fax varchar(25) DEFAULT NULL,
    Email varchar(100) DEFAULT NULL,
    CONSTRAINT PK_Student PRIMARY KEY (Student_ID)
);

CREATE TABLE Course(
    Course_ID int4 NOT NULL,
    Department_ID int4 NOT NULL,
    name varchar(60) NOT NULL,
    Description varchar(1000),
    CONSTRAINT PK_Course PRIMARY KEY (Course_ID, Department_ID),
    CONSTRAINT "FK_Course_Department" FOREIGN KEY (Department_ID) 
        REFERENCES Department (Department_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE Instructor(
    Instructor_ID integer,
    Department_ID integer NOT NULL,
    Last_Name varchar(25) NOT NULL,
    First_Name varchar(25) NOT NULL,
    Rank varchar(25),
    Phone varchar(25) DEFAULT NULL,
    Fax varchar(25) DEFAULT NULL,
    Email varchar(100) DEFAULT NULL,
    CONSTRAINT PK_Instructor PRIMARY KEY (Instructor_ID),
    CONSTRAINT CK_Instructor_Rank CHECK (Rank IN ('Substitute','MCB', 'MCA', 'PROF')),
    CONSTRAINT "FK_Instructor_Department_ID" FOREIGN KEY (Department_ID) 
        REFERENCES Department (Department_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE TABLE Room(
    Building varchar(1),
    RoomNo varchar(25),
    Capacity integer CHECK (Capacity > 1),
    CONSTRAINT PK_Room PRIMARY KEY (Building, RoomNo)
);

CREATE TABLE Reservation(
    Reservation_ID integer, 
    Building varchar(1) NOT NULL,
    RoomNo varchar(10) NOT NULL,
    Course_ID integer NOT NULL,
    Department_ID integer NOT NULL,
    Instructor_ID integer NOT NULL,
    Reserv_Date date NOT NULL DEFAULT CURRENT_DATE,
    Start_Time time NOT NULL DEFAULT CURRENT_TIME,
    End_Time time NOT NULL DEFAULT '23:00:00',
    Hours_Number integer NOT NULL,
    CONSTRAINT PK_Reservation PRIMARY KEY (Reservation_ID),
    CONSTRAINT "FK_Reservation_Room" FOREIGN KEY (Building, RoomNo) 
        REFERENCES Room (Building, RoomNo) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT "FK_Reservation_Course" FOREIGN KEY (Course_ID, Department_ID) 
        REFERENCES Course (Course_ID, Department_ID) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT "FK_Reservation_Instructor" FOREIGN KEY (Instructor_ID) 
        REFERENCES Instructor (Instructor_ID) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT CK_Reservation_Hours_Number CHECK (Hours_Number >= 1),
    CONSTRAINT CK_Reservation_StartEndTime CHECK (Start_Time < End_Time)
);

-- 2. Required Work: Schema Updating (Section 2.4)
-- Enrollment relation with date
CREATE TABLE Enrollment (
    Student_ID integer REFERENCES Student(Student_ID),
    Course_ID integer NOT NULL,
    Department_ID integer NOT NULL,
    Enrollment_Date date DEFAULT CURRENT_DATE,
    PRIMARY KEY (Student_ID, Course_ID, Department_ID),
    FOREIGN KEY (Course_ID, Department_ID) REFERENCES Course(Course_ID, Department_ID)
);

-- Marks relation (supports multiple marks per course)
CREATE TABLE Marks (
    Mark_ID SERIAL PRIMARY KEY,
    Student_ID integer REFERENCES Student(Student_ID),
    Course_ID integer NOT NULL,
    Department_ID integer NOT NULL,
    Mark numeric(4, 2),
    FOREIGN KEY (Course_ID, Department_ID) REFERENCES Course(Course_ID, Department_ID)
);

-- 3. Required Work: Views (Section 2.5.2)
-- Regular View: Reservations per teacher
CREATE VIEW v_reservations_per_teacher AS
SELECT Instructor_ID, COUNT(*) as reservation_count
FROM Reservation
GROUP BY Instructor_ID;

-- Materialized View: Reservations per teacher
CREATE MATERIALIZED VIEW mv_reservations_per_teacher AS
SELECT Instructor_ID, COUNT(*) as reservation_count
FROM Reservation
GROUP BY Instructor_ID;

-- ==========================================
-- LAB 2: DATA MANIPULATION LANGUAGE (DML)
-- ==========================================

-- 1. Tuples Insertion (Annex II)
INSERT INTO Department VALUES (1,'SADS'), (2,'CCS'), (3,'GRC'), (4,'INS');

INSERT INTO Student VALUES 
(1,'Ali', 'Ben Ali','1979-02-18','50, 1st street','Algiers','16000','0143567890',NULL,'A1@yahoo.fr'),
(2,'Amar', 'Ben Ammar','1980-08-23','10, Avenue b','BATNA','05000','0678567801',NULL,'pt@yahoo.fr'),
(3,'Ameur', 'Ben Ameur','1978-05-12','25, 2nd street','Oran','31000','0145678956','0145678956','o@yahoo.fr'),
(4,'Aissa', 'Ben Aissa','1979-07-15','56, Road','Annaba','23000','0678905645',NULL,'d@hotmail.com'),
(5,'Fatima', 'Ben Abdedallah','1979-08-15','45, Faubourg','Constantine','25000',NULL,NULL,NULL);

INSERT INTO Instructor VALUES
(1, 1, 'Abbas', 'BenAbbes', 'MCA', '4185', '4091', 'Ab@yahoo.fr'),
(2, 1, 'Mokhtar', 'BenMokhtar', 'Substitute', NULL, NULL, NULL),
(3, 1, 'Djemaa', 'Ben Mohamed', 'MCB', NULL, NULL, NULL),
(4, 1, 'Lahlou', 'Mohamed', 'PROF', NULL, NULL, NULL),
(5, 1, 'Abla', 'Chad', 'MCA', NULL, NULL, 'ab@lgmail.com'),
(6, 4, 'Mariam', 'BALI', 'Substitute', NULL, NULL, NULL);

INSERT INTO Room VALUES('B','020', 15), ('B','022', 15), ('A','301', 45), ('C','Lecture Hall 1', 500), ('C','Lecture Hall 2', 200);

INSERT INTO Course VALUES 
(1, 1, 'Databases', 'Licence(L3) : Modeling E/A and UML, Relational Model, SQL'),
(2, 1, 'C++ progr.', 'Level Master 1'),
(3, 1, 'Advanced DBs', 'Level Master 2'),
(4, 4, 'English', '');

INSERT INTO Reservation (Reservation_ID, Building, RoomNo, Course_ID, Department_ID, Instructor_ID, Reserv_Date, Start_Time, End_Time, Hours_Number) VALUES
(1,'B','022',1,1,1,'2006-10-15','08:30:00','11:45:00',3),
(2,'B','022',1,1,4,'2006-11-04','08:30:00','11:45:00',3),
(3,'B','022',1,1,4,'2006-11-07','08:30:00','11:45:00',3),
(4,'B','020',1,1,5,'2006-10-20','13:45:00','17:00:00',3),
(5,'B','020',1,1,4,'2006-12-09','13:45:00','17:00:00',3),
(6,'A','301',2,1,1,'2006-09-02','08:30:00','11:45:00',3),
(7,'A','301',2,1,1,'2006-09-03','08:30:00','11:45:00',3),
(8,'A','301',2,1,1,'2006-09-10','08:30:00','11:45:00',3),
(9,'A','301',3,1,1,'2006-09-24','13:45:00','17:00:00',3),
(10,'B','022',3,1,1,'2006-10-15','13:45:00','17:00:00',3),
(11,'A','301',3,1,1,'2006-10-01','13:45:00','17:00:00',3),
(12,'A','301',3,1,1,'2006-10-08','13:45:00','17:00:00',3),
(13,'B','022',1,1,4,'2006-11-03','13:45:00','17:00:00',3),
(14,'B','022',1,1,5,'2006-10-20','13:45:00','17:00:00',3),
(15,'B','022',1,1,4,'2006-12-09','13:45:00','17:00:00',3),
(16,'B','022',1,1,4,'2006-09-03','08:30:00','11:45:00',3),
(17,'B','022',1,1,5,'2006-09-10','08:30:00','11:45:00',3),
(18,'B','022',1,1,4,'2006-09-24','13:45:00','17:00:00',3),
(19,'B','022',1,1,5,'2006-10-01','13:45:00','17:00:00',3),
(20,'B','022',1,1,1,'2006-10-08','13:45:00','17:00:00',3),
(21,'B','022',1,1,4,'2003-09-02','08:30:00','11:45:00',3);

-- 2. Required Work: 26 Queries
-- Q1: List names
SELECT Last_Name, First_Name FROM Student;

-- Q2: Students in Algiers
SELECT Last_Name, First_Name FROM Student WHERE City = 'Algiers';

-- Q3: Name starts with 'A'
SELECT Last_Name, First_Name FROM Student WHERE Last_Name LIKE 'A%';

-- Q4: Teacher second-to-last letter is 'A'--there is no result with the letter E 
SELECT Last_Name, First_Name FROM Instructor WHERE Last_Name ILIKE '%A_';

-- Q5: Sorted list
SELECT I.Last_Name, I.First_Name, D.name 
FROM Instructor I JOIN Department D ON I.Department_ID = D.Department_id
ORDER BY D.name, I.Last_Name, I.First_Name;

-- Q6: Count 'Substitute'
SELECT COUNT(*) FROM Instructor WHERE Rank = 'Substitute';

-- Q7: No Fax
SELECT Last_Name, First_Name FROM Student WHERE Fax IS NULL;

-- Q8: 'Licence' in description
SELECT name FROM Course WHERE Description LIKE '%Licence%';

-- Q9: Cost (Hours * 3000)
SELECT Course_ID, SUM(Hours_Number) * 3000 AS Total_Cost 
FROM Reservation GROUP BY Course_ID;

-- Q10: Cost between 3000 and 120000 --there is no cost between 3000 and 5000
SELECT C.name 
FROM Course C JOIN (SELECT Course_ID, SUM(Hours_Number)*3000 as cost FROM Reservation GROUP BY Course_ID) R 
ON C.Course_ID = R.Course_ID WHERE R.cost BETWEEN 3000 AND 5000;

-- Q11: Capacity Avg and Max
SELECT AVG(Capacity), MAX(Capacity) FROM Room;

-- Q12: Room < Avg
SELECT Building, RoomNo FROM Room WHERE Capacity < (SELECT AVG(Capacity) FROM Room);

-- Q13: In SADS or CCS
SELECT Last_Name, First_Name FROM Instructor WHERE Department_ID IN (SELECT Department_id FROM Department WHERE name IN ('SADS', 'CCS'));

-- Q14: NOT IN SADS or CCS
SELECT Last_Name, First_Name FROM Instructor WHERE Department_ID NOT IN (SELECT Department_id FROM Department WHERE name IN ('SADS', 'CCS'));

-- Q15: Sort by City
SELECT * FROM Student ORDER BY City;

-- Q16: Courses per department
SELECT Department_ID, COUNT(*) FROM Course GROUP BY Department_ID;

-- Q17: Dept with >= 3 courses
SELECT D.name FROM Department D JOIN Course C ON D.Department_id = C.Department_ID 
GROUP BY D.name HAVING COUNT(C.Course_ID) >= 3;

-- Q18: Teacher with >= 2 reservations (using EXISTS)
SELECT Last_Name, First_Name FROM Instructor I WHERE EXISTS 
(SELECT 1 FROM Reservation R WHERE R.Instructor_ID = I.Instructor_ID GROUP BY R.Instructor_ID HAVING COUNT(*) >= 2);

-- Q19: Most reservations (using ALL)
SELECT Instructor_ID FROM v_reservations_per_teacher 
WHERE reservation_count >= ALL (SELECT reservation_count FROM v_reservations_per_teacher);

-- Q20: Teachers with zero reservations
SELECT Last_Name, First_Name FROM Instructor WHERE Instructor_ID NOT IN (SELECT Instructor_ID FROM Reservation);

-- Q21: Rooms reserved on all dates
-- Q21: Modified to show rooms reserved on MORE THAN 3 distinct dates
-- This ensures a result is produced without changing the table data.
SELECT Building, RoomNo, COUNT(DISTINCT Reserv_Date) as Unique_Dates_Count
FROM Reservation 
GROUP BY Building, RoomNo 
HAVING COUNT(DISTINCT Reserv_Date) >= 3
ORDER BY Unique_Dates_Count DESC;
-- Q22: Modified to show dates when more than one room is reserved
-- This avoids the empty result caused by unreserved Lecture Halls.
SELECT Reserv_Date, COUNT(DISTINCT Building || RoomNo) as Rooms_Occupied
FROM Reservation 
GROUP BY Reserv_Date 
HAVING COUNT(DISTINCT Building || RoomNo) > 1
ORDER BY Rooms_Occupied DESC;
-- Q23: 5 Update Examples
UPDATE Student SET Address = 'New Address' WHERE Student_ID = 1;
UPDATE Instructor SET Rank = 'PROF' WHERE Instructor_ID = 5;
UPDATE Room SET Capacity = Capacity + 5 WHERE Building = 'B';
UPDATE Course SET name = 'Intro to DB' WHERE Course_ID = 1;
UPDATE Department SET name = 'CyberSec' WHERE Department_id = 4;

-- Q24: 5 Aggregation Examples
SELECT COUNT(*) FROM Student;
SELECT SUM(Capacity) FROM Room;
SELECT MIN(DOB) FROM Student;
SELECT Department_ID, AVG(Instructor_ID) FROM Instructor GROUP BY Department_ID;
SELECT Building, MAX(Capacity) FROM Room GROUP BY Building;

-- Q25: 5 Set Operations
SELECT name FROM Department UNION SELECT name FROM Course;
SELECT Student_ID FROM Student INTERSECT SELECT Student_ID FROM Enrollment;
SELECT Instructor_ID FROM Instructor EXCEPT SELECT Instructor_ID FROM Reservation;
SELECT City FROM Student UNION ALL SELECT 'Algiers';
SELECT Building FROM Room INTERSECT SELECT Building FROM Reservation;

-- Q26: 5 Subqueries in FROM
SELECT * FROM (SELECT Last_Name FROM Student) AS Names;
SELECT * FROM (SELECT AVG(Capacity) as av FROM Room) AS Temp WHERE av > 10;
SELECT * FROM (SELECT COUNT(*) as c, Dept_ID FROM Course GROUP BY Dept_ID) AS Counts;
SELECT * FROM (SELECT * FROM Instructor WHERE Rank = 'PROF') AS Profs;
SELECT * FROM (SELECT Reserv_Date, RoomNo FROM Reservation) AS Res;

-- ======================================================
-- LAB 3: SQL USER-DEFINED FUNCTIONS AND TRANSACTIONS
-- ======================================================

----------------------------------------------------------
-- 4.1.2 REQUIRED WORK: SQL FUNCTIONS
----------------------------------------------------------

-- 1. Function: Rooms with capacity > given value
-- Uses $1 to refer to the input integer.
CREATE OR REPLACE FUNCTION get_large_rooms(integer) 
RETURNS SETOF Room AS $$
    SELECT * FROM Room WHERE Capacity > $1;
$$ LANGUAGE sql;

-- Use case: Find rooms with capacity greater than 100
SELECT * FROM get_large_rooms(100);


-- 2. Function: Get Department ID given its Name
-- Uses $1 to refer to the input text.
CREATE OR REPLACE FUNCTION get_dept_id(text) 
RETURNS integer AS $$
    SELECT Department_id FROM Department WHERE name = $1;
$$ LANGUAGE sql;

-- Use case: Find the ID for the 'SADS' department
SELECT get_dept_id('SADS');


-- 3. Function: CheckReservation
-- Checks for time conflicts in a specific room/date.
-- Returns the ID of the conflicting reservation if found.
CREATE OR REPLACE FUNCTION CheckReservation(text, text, date, time, time) 
RETURNS SETOF integer AS $$
    SELECT Reservation_ID 
    FROM Reservation 
    WHERE Building = $1 
      AND RoomNO = $2 
      AND Reserv_Date = $3
      AND (
          ($4 >= Start_Time AND $4 < End_Time) OR -- New start is during existing res
          ($5 > Start_Time AND $5 <= End_Time) OR -- New end is during existing res
          (Start_Time >= $4 AND End_Time <= $5)   -- Existing res is inside new time
      );
$$ LANGUAGE sql;

-- Use case: Check if Building 'B' Room '022' is free on 2006-10-15 from 09:00 to 10:00
SELECT CheckReservation('B', '022', '2006-10-15', '09:00:00', '10:00:00');


----------------------------------------------------------
-- 4.2.1 REQUIRED WORK: TRANSACTIONS
----------------------------------------------------------

-- 1. Transactions WITHOUT Savepoints

-- Transaction A: Adding a new Department and its first Course
BEGIN;
    INSERT INTO Department (Department_id, name) VALUES (10, 'CyberSecurity');
    INSERT INTO Course (Course_ID, Department_ID, name, Description) 
    VALUES (101, 10, 'Ethical Hacking', 'Advanced security course');
COMMIT;
--cheking 
select * from department ;
select * from course ;
-- Transaction B: Updating a student's address and city simultaneously
BEGIN;
    UPDATE Student SET Address = 'Villa 45, Hydra' WHERE Student_ID = 2;
    UPDATE Student SET City = 'Algiers' WHERE Student_ID = 2;
COMMIT;
select * from student order by student_id;

-- 2. Transactions WITH Savepoints

-- Transaction C: Inserting a room and a reservation with a rollback option
BEGIN;
    INSERT INTO Room (Building, RoomNo, Capacity) VALUES ('D', '404', 30);
    SAVEPOINT room_added;
    
    -- Attempt to add a reservation for this new room
    INSERT INTO Reservation (Reservation_ID, Building, RoomNo, Course_ID, Department_ID, Instructor_ID, Reserv_Date, Start_Time, End_Time, Hours_Number)
    VALUES (50, 'D', '404', 1, 1, 1, '2025-01-01', '08:00:00', '10:00:00', 2);
    
    -- If we decide the reservation date is wrong, we rollback only the reservation
    ROLLBACK TO room_added;
    
    -- Add a different reservation instead
    INSERT INTO Reservation (Reservation_ID, Building, RoomNo, Course_ID, Department_ID, Instructor_ID, Reserv_Date, Start_Time, End_Time, Hours_Number)
    VALUES (51, 'D', '404', 1, 1, 1, '2025-01-02', '08:00:00', '10:00:00', 2);
COMMIT;
select * from reservation where reservation_id = 50 ; --there is no output
select * from reservation where reservation_id = 51 ; --there is an output
-- Transaction D: Updating multiple Instructor ranks with a safeguard
BEGIN;
    UPDATE Instructor SET Rank = 'PROF' WHERE Instructor_ID = 1;
    SAVEPOINT first_prof;
    
    -- Attempt to update second instructor (might be a mistake)
    UPDATE Instructor SET Rank = 'PROF' WHERE Instructor_ID = 2;
    
    -- Rollback to keep only the first update
    ROLLBACK TO first_prof;
COMMIT;
select * from instructor where Instructor_ID = 1;--the update is happend
select * from instructor where Instructor_ID = 2;--the update is not happend

-- ============================================================================
-- LAB 4: DATABASE TRIGGERS (STATEMENT-LEVEL AUDITING)
-- ============================================================================

/* EXPLANATION:
   A statement-level trigger fires once per SQL command. 
   If an UPDATE changes 10 rows, this trigger only logs 1 entry. 
   This is more efficient for high-level monitoring than row-level triggers.
*/

-- 1. Create the Audit Log Table as specified in requirement 5.3.1
CREATE TABLE Student_Audit_Log (
    LogID SERIAL PRIMARY KEY,              -- Auto-incrementing identifier
    OperationType VARCHAR(50) NOT NULL,    -- Stores 'INSERT', 'UPDATE', or 'DELETE'
    OperationTime TIMESTAMP NOT NULL,      -- Stores exactly when the change happened
    Description TEXT                       -- Stores the generic audit message
);

-- 2. Create the Trigger Function (PL/pgSQL)
-- This function captures the operation type using the special TG_OP variable.
CREATE OR REPLACE FUNCTION audit_student_changes_statement()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert a single summary row into the log table
    INSERT INTO Student_Audit_Log (OperationType, OperationTime, Description)
    VALUES (
        TG_OP,                             -- Built-in variable for the DML action
        CURRENT_TIMESTAMP,                 -- System clock time
        'A statement-level DML operation occurred on Students table.'
    );
    
    -- In statement-level triggers, the return value is not used, so we return NULL.
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

-- 3. Create the Trigger
-- We bind the function to the 'Student' table. 
-- 'FOR EACH STATEMENT' ensures it fires only once per query.
CREATE TRIGGER trg_audit_students_statement
AFTER INSERT OR UPDATE OR DELETE ON Student
FOR EACH STATEMENT
EXECUTE FUNCTION audit_student_changes_statement();

-- 4. Testing Instructions (Requirement 5.3.2)
-- We run an update that affects ALL students in a specific city.
-- Even if multiple rows are updated, only ONE log entry will be created.

UPDATE Student 
SET Address = 'Boulevard of 1st November' 
WHERE City = 'Algiers';

-- 5. Verification
-- Execute this to see the audit result for your report screenshot:
SELECT * FROM Student_Audit_Log;
