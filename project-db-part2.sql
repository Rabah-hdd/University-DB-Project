/*
-----------------------------------------------------------------------
   PROJECT PART II: SCHEMA EXTENSION & LOGIC
   FILE: project-db-part2.sql
   AUTHOR: [RABAH-HADDADI / MOHAMED-ABBACI / A1]
   DATE: 2026-01-06
   
   IMPORTANT: Execute 'project-db-part1.sql' BEFORE running this script.
-----------------------------------------------------------------------
*/

-- ====================================================================
-- 1. EXTENDING THE SCHEMA: SECTIONS & GROUPS
-- ====================================================================

-- 1.1 Create Section Table
-- one Department has multiple Sections 
CREATE TABLE Academic_Section (
    section_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department_id INTEGER NOT NULL,
    CONSTRAINT fk_section_dept FOREIGN KEY (department_id) -- link to the department table to ensure data integrity
        REFERENCES Department(department_id) --defines the parent table and column being reference
        ON UPDATE CASCADE ON DELETE RESTRICT --if the department ID is updated in the Department table, linked records in the current table are automatically updated 
);

-- 1.2 Create Group Table
-- one Section has multiple Groups 
CREATE TABLE Academic_Group (
    group_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    section_id INTEGER NOT NULL,
    CONSTRAINT fk_group_section FOREIGN KEY (section_id) 
        REFERENCES Academic_Section(section_id) -- parent table ..
        ON UPDATE CASCADE ON DELETE RESTRICT --link the updates 
);

-- 1.3 Update Student Table
-- Link students to their specific Group
ALTER TABLE Student 
ADD COLUMN group_id INTEGER; -- add a column to the student table 

ALTER TABLE Student
ADD CONSTRAINT fk_student_group FOREIGN KEY (group_id)  
    REFERENCES Academic_Group(group_id)
    ON UPDATE CASCADE ON DELETE RESTRICT; -- defin a foreign key link student to the group


-- ====================================================================
-- 2. COURSE MANAGEMENT: ACTIVITIES & FAILING GRADES
-- ====================================================================

-- 2.1 Add "Failing Grade" to Course
-- Default is usually 10.00/20.00
ALTER TABLE Course 
ADD COLUMN failing_grade NUMERIC(4,2) DEFAULT 10.00; -- add failing grade column to the course and defin its threshold 

-- 2.2 Create Activity Table
-- Stores Lectures, Tutorials (TD), and Practicals (TP)
CREATE TABLE Course_Activity (
    activity_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL, -- Needed for composite FK to Course
    activity_type VARCHAR(20) CHECK (activity_type IN ('Lecture', 'Tutorial', 'Practical')),
    
    -- Link to Course (Using the composite key from Part 1)
    CONSTRAINT fk_activity_course FOREIGN KEY (course_id, department_id) 
        REFERENCES Course(course_id, department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT  --use exesting composite foreign key in database design part 1
);

-- ==========================================
-- 3. EXAM MANAGEMENT
-- ==========================================

-- 3.1 Create Exam Table
-- Manages exam schedules, rooms, and dates
CREATE TABLE Exam (
    exam_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL, -- Needed for FK
    exam_type VARCHAR(20) CHECK (exam_type IN ('Midterm', 'Final', 'Resit')),
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    building VARCHAR(1),
    roomno VARCHAR(20),
    
    -- Link to Course
    CONSTRAINT fk_exam_course FOREIGN KEY (course_id, department_id) 
        REFERENCES Course(course_id, department_id),
        
    -- Link to Room (for reservation)
    CONSTRAINT fk_exam_room FOREIGN KEY (building, roomno) 
        REFERENCES Room(building, roomno),

    -- Sanity Check
    CONSTRAINT ck_exam_time CHECK (start_time < end_time) --Ensures logical data validity for time fields
);


-- ====================================================================
-- 4. ATTENDANCE & AUDIT SYSTEM
-- ====================================================================

-- 4.1 Create Attendance Table
-- Tracks if a student was Present/Absent for a specific Activity
CREATE TABLE Attendance (
    attendance_id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL, --fk from student 
    activity_id INTEGER NOT NULL, --fk from activity
    attendance_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(10) CHECK (status IN ('Present', 'Absent', 'Excused')),
    
    CONSTRAINT fk_att_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT fk_att_activity FOREIGN KEY (activity_id) REFERENCES Course_Activity(activity_id)
);

-- 4.2 Create General Audit Table (Requirement 6.2.3)
-- Logs changes to Marks and Attendance  " audit log table "
CREATE TABLE Marks_Attendance_Audit (     
    audit_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(10), --Stores the type of operation : INSERT, UPDATE, DELETE
    operation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50), --stores the name of the table that was modified
    user_name VARCHAR(50),  -- who performed the operation 
    description TEXT   -- information about the change "payload or summary"
);

-- 4.3 Trigger Function for Auditing
CREATE OR REPLACE FUNCTION audit_marks_attendance() RETURNS TRIGGER AS $$ -- it must return trigger
BEGIN
    INSERT INTO Marks_Attendance_Audit (operation_type, table_name, user_name, description)
    VALUES (
        TG_OP,  -- the type of operation that lunch the trigger
        TG_TABLE_NAME, -- the name of table that was modified 
        SESSION_USER, -- the user who initiated the transaction 
        'User ' || SESSION_USER || ' performed ' || TG_OP || ' on table ' || TG_TABLE_NAME --description 
    );
    RETURN NULL; -- Return NULL for AFTER triggers 
END;
$$ LANGUAGE plpgsql;

-- 4.4 Apply Triggers

-- Audit Marks Table (Created in Part 1)

CREATE TRIGGER trg_audit_marks_change  -- defining new trigger 
AFTER INSERT OR UPDATE OR DELETE ON Marks --specifies when the trigger should fire (after DML operation )
FOR EACH STATEMENT --specifies the the tg function should be executed once per sql statment 
EXECUTE FUNCTION audit_marks_attendance(); -- the action 

-- Audit Attendance Table

CREATE TRIGGER trg_audit_attendance_change
AFTER INSERT OR UPDATE OR DELETE ON Attendance
FOR EACH STATEMENT
EXECUTE FUNCTION audit_marks_attendance();



-- ====================================================================
-- 5. REQUIRED FUNCTIONS (FOR PYTHON APP)
-- ====================================================================

-- Function 1: Get list of students by Group Name (Requirement a)
CREATE OR REPLACE FUNCTION get_students_by_group(p_group_name VARCHAR) 
RETURNS TABLE(student_id INTEGER, first_name VARCHAR, last_name VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    SELECT s.student_id, s.first_name, s.last_name
    FROM Student s
    JOIN Academic_Group g ON s.group_id = g.group_id --link student to group
    WHERE g.name = p_group_name; -- filter by the user input 
END;
$$ LANGUAGE plpgsql;

-- Function 2: Get list of students by Section Name (Requirement b)
CREATE OR REPLACE FUNCTION get_students_by_section(p_section_name VARCHAR) 
RETURNS TABLE(student_id INTEGER, first_name VARCHAR, last_name VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    SELECT s.student_id, s.first_name, s.last_name
    FROM Student s
    JOIN Academic_Group g ON s.group_id = g.group_id -- Link 1: Student -> Group
    JOIN Academic_Section sec ON g.section_id = sec.section_id -- Link 2: Group -> Section
    WHERE sec.name = p_section_name;
END;
$$ LANGUAGE plpgsql;

-- Function 3: Check if a student passed a module (Requirement e)
-- Returns TRUE if average mark >= 10 (or defined failing grade)
CREATE OR REPLACE FUNCTION has_student_passed(p_student_id INTEGER, p_course_id INTEGER) 
RETURNS BOOLEAN AS $$
DECLARE
    v_avg_mark NUMERIC;
    v_failing_grade NUMERIC;
BEGIN
    -- Get the course's failing grade threshold
    SELECT failing_grade INTO v_failing_grade FROM Course WHERE course_id = p_course_id LIMIT 1;
    
    -- Calculate average mark for this student in this course
    SELECT AVG(mark_value) INTO v_avg_mark 
    FROM Marks 
    WHERE student_id = p_student_id AND course_id = p_course_id;

    -- Safety Check: If student has no marks yet (result is NULL)

    IF v_avg_mark IS NULL THEN RETURN FALSE; END IF; 
    
    RETURN v_avg_mark >= v_failing_grade;
END;
$$ LANGUAGE plpgsql;

-- Function 4: Get students eligible for Resit (Requirement i)
-- Students who failed the module
CREATE OR REPLACE FUNCTION get_resit_candidates(p_course_id INTEGER) 
RETURNS TABLE(student_name VARCHAR, average_mark NUMERIC) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        (s.last_name || ' ' || s.first_name)::VARCHAR, 
        AVG(m.mark_value)
    FROM Marks m
    JOIN Student s ON m.student_id = s.student_id
    JOIN Course c ON m.course_id = c.course_id AND m.department_id = c.department_id
    WHERE m.course_id = p_course_id 
    GROUP BY s.student_id, c.failing_grade
    HAVING AVG(m.mark_value) < c.failing_grade; -- The "Resit" Condition
END;
$$ LANGUAGE plpgsql;

-- Function 5: Calculate Average Mark by Group (Requirement g)
CREATE OR REPLACE FUNCTION get_avg_mark_by_group(p_course_id INTEGER, p_group_name VARCHAR) 
RETURNS NUMERIC AS $$
DECLARE
    v_avg NUMERIC;
BEGIN
    SELECT AVG(m.mark_value) INTO v_avg
    FROM Marks m
    JOIN Student s ON m.student_id = s.student_id  -- Link Mark to Student
    JOIN Academic_Group g ON s.group_id = g.group_id -- link student to group 
    WHERE m.course_id = p_course_id AND g.name = p_group_name;
    
    RETURN COALESCE(v_avg, 0);
END;
$$ LANGUAGE plpgsql;
-- تم بفضل الله 
