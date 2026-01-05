/*
-----------------------------------------------------------------------
   PROJECT PART II: SCHEMA EXTENSION & LOGIC (FIXED VERSION)
   FILE: project-db-part2.sql
   
   IMPORTANT: Execute 'project-db-part1.sql' BEFORE running this script.
-----------------------------------------------------------------------
*/

-- ====================================================================
-- 1. EXTENDING THE SCHEMA: SECTIONS & GROUPS
-- ====================================================================

-- 1.1 Create Section Table
CREATE TABLE IF NOT EXISTS Academic_Section (
    section_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department_id INTEGER NOT NULL,
    CONSTRAINT fk_section_dept FOREIGN KEY (department_id) 
        REFERENCES Department(department_id) 
        ON UPDATE CASCADE ON DELETE RESTRICT 
);

-- 1.2 Create Group Table
CREATE TABLE IF NOT EXISTS Academic_Group (
    group_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    section_id INTEGER NOT NULL,
    CONSTRAINT fk_group_section FOREIGN KEY (section_id) 
        REFERENCES Academic_Section(section_id) 
        ON UPDATE CASCADE ON DELETE RESTRICT 
);

-- 1.3 Update Student Table
ALTER TABLE Student ADD COLUMN IF NOT EXISTS group_id INTEGER;
ALTER TABLE Student ADD COLUMN IF NOT EXISTS section VARCHAR(50); 
ALTER TABLE Student ADD COLUMN IF NOT EXISTS academic_group VARCHAR(50); 

-- Add FK Constraint safely
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'fk_student_group') THEN
    ALTER TABLE Student 
    ADD CONSTRAINT fk_student_group FOREIGN KEY (group_id) 
    REFERENCES Academic_Group(group_id) 
    ON UPDATE CASCADE ON DELETE RESTRICT;
  END IF;
END $$;


-- ====================================================================
-- 2. COURSE MANAGEMENT
-- ====================================================================

ALTER TABLE Course ADD COLUMN IF NOT EXISTS failing_grade NUMERIC(4,2) DEFAULT 10.00;

-- Activity Table
CREATE TABLE IF NOT EXISTS Course_Activity (
    activity_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL, 
    activity_type VARCHAR(20) CHECK (activity_type IN ('Lecture', 'Tutorial', 'Practical')),
    
    CONSTRAINT fk_activity_course FOREIGN KEY (course_id, department_id) 
        REFERENCES Course(course_id, department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Exam Table
CREATE TABLE IF NOT EXISTS Exam (
    exam_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL, 
    exam_type VARCHAR(20) CHECK (exam_type IN ('Midterm', 'Final', 'Resit')),
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    building VARCHAR(1),
    roomno VARCHAR(20),
    
    CONSTRAINT fk_exam_course FOREIGN KEY (course_id, department_id) 
        REFERENCES Course(course_id, department_id),
    CONSTRAINT fk_exam_room FOREIGN KEY (building, roomno) 
        REFERENCES Room(building, roomno),
    CONSTRAINT ck_exam_time CHECK (start_time < end_time)
);


-- ====================================================================
-- 4. ATTENDANCE & AUDIT SYSTEM (The Error Fix is Here)
-- ====================================================================

-- 4.1 Create Attendance Table
-- FIX: Removed 'fk_att_course' because Course PK is composite (id, dept)
-- but App only sends 'course_id'. We prioritize App functionality here.
CREATE TABLE IF NOT EXISTS Attendance (
    attendance_id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL, 
    course_id INTEGER NOT NULL, 
    attendance_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(10) CHECK (status IN ('Present', 'Absent', 'Late', 'Excused')),
    
    CONSTRAINT fk_att_student FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE
);

-- 4.2 Create Audit Table
CREATE TABLE IF NOT EXISTS Student_Audit_Log (      
    audit_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(20), 
    audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    table_name VARCHAR(50), 
    changed_by VARCHAR(50),  
    description TEXT    
);

-- 4.3 Trigger Function
CREATE OR REPLACE FUNCTION audit_marks_attendance() RETURNS TRIGGER AS $$ 
BEGIN
    INSERT INTO Student_Audit_Log (operation_type, table_name, changed_by, audit_timestamp, description)
    VALUES (
        TG_OP, 
        TG_TABLE_NAME, 
        SESSION_USER, 
        NOW(),
        'User ' || SESSION_USER || ' performed ' || TG_OP || ' on table ' || TG_TABLE_NAME 
    );
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

-- 4.4 Apply Triggers
DROP TRIGGER IF EXISTS trg_audit_marks_change ON Marks;
CREATE TRIGGER trg_audit_marks_change 
AFTER INSERT OR UPDATE OR DELETE ON Marks 
FOR EACH STATEMENT EXECUTE FUNCTION audit_marks_attendance(); 

DROP TRIGGER IF EXISTS trg_audit_attendance_change ON Attendance;
CREATE TRIGGER trg_audit_attendance_change
AFTER INSERT OR UPDATE OR DELETE ON Attendance
FOR EACH STATEMENT
EXECUTE FUNCTION audit_marks_attendance();


-- ====================================================================
-- 5. REPORT FUNCTIONS
-- ====================================================================

-- (a) Students by Group
CREATE OR REPLACE FUNCTION get_students_by_group(p_group_name VARCHAR) 
RETURNS TABLE(student_id INTEGER, first_name VARCHAR, last_name VARCHAR, grp VARCHAR, sec VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    SELECT s.student_id, s.first_name, s.last_name, s.academic_group, s.section
    FROM Student s
    WHERE s.academic_group = p_group_name; 
END;
$$ LANGUAGE plpgsql;

-- (b) Students by Section
CREATE OR REPLACE FUNCTION get_students_by_section(p_section_name VARCHAR) 
RETURNS TABLE(student_id INTEGER, first_name VARCHAR, last_name VARCHAR, grp VARCHAR, sec VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    SELECT s.student_id, s.first_name, s.last_name, s.academic_group, s.section
    FROM Student s
    WHERE s.section = p_section_name;
END;
$$ LANGUAGE plpgsql;

-- (h) Failing Students (< 10)
CREATE OR REPLACE FUNCTION get_failing_students() 
RETURNS TABLE(student_name VARCHAR, course_name VARCHAR, mark NUMERIC) AS $$
BEGIN
    RETURN QUERY 
    SELECT (s.first_name || ' ' || s.last_name)::VARCHAR, c.name, m.mark_value
    FROM Marks m
    JOIN Student s ON m.student_id = s.student_id
    JOIN Course c ON m.course_id = c.course_id
    WHERE m.mark_value < 10;
END;
$$ LANGUAGE plpgsql;

-- (i) Resit Candidates (Between 5 and 10)
CREATE OR REPLACE FUNCTION get_resit_students() 
RETURNS TABLE(student_name VARCHAR, course_name VARCHAR, mark NUMERIC) AS $$
BEGIN
    RETURN QUERY 
    SELECT (s.first_name || ' ' || s.last_name)::VARCHAR, c.name, m.mark_value
    FROM Marks m
    JOIN Student s ON m.student_id = s.student_id
    JOIN Course c ON m.course_id = c.course_id
    WHERE m.mark_value >= 5 AND m.mark_value < 10;
END;
$$ LANGUAGE plpgsql;

-- (g/j) Excluded Students (Absence >= 3)
CREATE OR REPLACE FUNCTION get_excluded_students() 
RETURNS TABLE(student_name VARCHAR, course_name VARCHAR, absence_count BIGINT) AS $$
BEGIN
    RETURN QUERY 
    SELECT (s.first_name || ' ' || s.last_name)::VARCHAR, c.name, COUNT(*)
    FROM Attendance a
    JOIN Student s ON a.student_id = s.student_id
    -- Removed the strict join on Course to avoid missing FK issues
    JOIN Course c ON a.course_id = c.course_id 
    WHERE a.status IN ('Absent', 'Late') 
    GROUP BY s.first_name, s.last_name, c.name
    HAVING COUNT(*) >= 3; 
END;
$$ LANGUAGE plpgsql;
-- Add the missing 'table_name' column to the Audit Log table
ALTER TABLE Student_Audit_Log 
ADD COLUMN IF NOT EXISTS table_name VARCHAR(50);