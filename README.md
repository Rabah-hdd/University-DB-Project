# University Management System (national high school of cyber security 

A comprehensive full-stack database project designed by "rabah haddadi and mohamed abbaci "  to manage university operations. This system integrates a robust (PostgreSQL) backend with a user-friendly **Python (Tkinter)** graphical interface to handle student data, academic courses, grading, attendance, and administrative auditing.

 Features :

1) Database Layer (PostgreSQL /pgadmin4 )
 Core Schema: Manages Students, Departments, Instructors, Courses, Rooms, and Reservations.
 Advanced Logic:
    * ACID Transactions**: Ensures data integrity during complex updates.
    * Automation: Triggers for audit logging (`Student_Audit_Log`) and enforcing business rules.
    * Stored Functions: Custom PL/pgSQL functions for calculating failing grades, resit eligibility, and exclusion lists.
    * Views: Materialized and standard views for statistical reporting.

  Application Layer (Python GUI)
*  Modern Interface : Built with `ttkbootstrap` (Superhero theme) for a clean, dark-mode aesthetic.
*  CRUD Modules: Full Create, Read, Update, Delete operations for all base entities (Students, Instructors, etc.).
* Academic Management:
    * Enrollment: Link students to courses.
    * Marks & Grading: Input grades and automatically process Pass/Fail results.
    * Attendance: Track student presence (Present, Absent, Late).
    *  Reporting Dashboard: One-click generation of complex academic reports (e.g., Failing Students, Resit Candidates).
    *Security Audit**: Real-time visualization of database changes via the Audit Log viewer.

# Prerequisites

* **PostgreSQL** (v12 or higher recommended)
* **Python** (v3.8 or higher)
* **Required Python Libraries**:
    * `psycopg2` (Database adapter)
    * `ttkbootstrap` (GUI theming)
    * `Pillow` (Image handling)


###  Python Environment
Install the required dependencies using pip:
```bash
pip install psycopg2-binary ttkbootstrap Pillow
