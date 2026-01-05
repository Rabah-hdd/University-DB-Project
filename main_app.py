import ttkbootstrap as ttk
from ttkbootstrap.constants import *
from tkinter import messagebox, simpledialog
from PIL import Image, ImageTk 
import db_connection
import os

class UniversityApp:
    def __init__(self, root):
        self.root = root
        self.root.title("University Database Manager (Connected to Real DB)")
        self.root.geometry("1400x950")
        
        # --- 1. MAIN MENU STRUCTURE ---
        # Using 'primary' bootstyle for the main tabs to give them a colored accent
        self.main_tabs = ttk.Notebook(root, bootstyle="primary")
        self.main_tabs.pack(expand=1, fill="both", padx=10, pady=10)

        self.tab_home = ttk.Frame(self.main_tabs)
        self.tab_crud = ttk.Frame(self.main_tabs)      
        self.tab_academic = ttk.Frame(self.main_tabs)  
        self.tab_queries = ttk.Frame(self.main_tabs)   
        self.tab_audit = ttk.Frame(self.main_tabs)     

        self.main_tabs.add(self.tab_home, text=" Home ")
        self.main_tabs.add(self.tab_crud, text=" General Data (CRUD) ")
        self.main_tabs.add(self.tab_academic, text=" Academic Management ")
        self.main_tabs.add(self.tab_queries, text=" Reports ")
        self.main_tabs.add(self.tab_audit, text=" Audit Logs ")

        # --- 2. SUB-MENUS ---
        # A. CRUD Sub-menu
        self.crud_tabs = ttk.Notebook(self.tab_crud, bootstyle="info")
        self.crud_tabs.pack(expand=1, fill="both", padx=10, pady=10)
        self.t_stud = ttk.Frame(self.crud_tabs); self.crud_tabs.add(self.t_stud, text="Students")
        self.t_inst = ttk.Frame(self.crud_tabs); self.crud_tabs.add(self.t_inst, text="Instructors")
        self.t_dept = ttk.Frame(self.crud_tabs); self.crud_tabs.add(self.t_dept, text="Departments")
        self.t_cour = ttk.Frame(self.crud_tabs); self.crud_tabs.add(self.t_cour, text="Courses")
        self.t_room = ttk.Frame(self.crud_tabs); self.crud_tabs.add(self.t_room, text="Rooms")

        # B. Academic Sub-menu
        self.acad_tabs = ttk.Notebook(self.tab_academic, bootstyle="info")
        self.acad_tabs.pack(expand=1, fill="both", padx=10, pady=10)
        self.t_res = ttk.Frame(self.acad_tabs); self.acad_tabs.add(self.t_res, text="Reservations")
        self.t_enr = ttk.Frame(self.acad_tabs); self.acad_tabs.add(self.t_enr, text="Enrollment")
        self.t_mark = ttk.Frame(self.acad_tabs); self.acad_tabs.add(self.t_mark, text="Marks")
        self.t_att = ttk.Frame(self.acad_tabs); self.acad_tabs.add(self.t_att, text="Attendance")          
        self.t_grade = ttk.Frame(self.acad_tabs); self.acad_tabs.add(self.t_grade, text="Results Processing") 

        # --- 3. BUILD UI ---
        self.build_home()
        # CRUD
        self.build_students(self.t_stud)
        self.build_instructors(self.t_inst)
        self.build_departments(self.t_dept)
        self.build_courses(self.t_cour)
        self.build_rooms(self.t_room)
        # Academic
        self.build_reservations(self.t_res)
        self.build_enrollment(self.t_enr)
        self.build_marks(self.t_mark)
        self.build_attendance(self.t_att) 
        self.build_grading(self.t_grade) 
        # Reports & Audit
        self.build_queries_tab(self.tab_queries)
        self.build_audit_tab(self.tab_audit)

    # ==========================
    #   HELPER: REAL DB EXECUTION
    # ==========================
    def execute_sql(self, sql, params, callback=None):
        conn = db_connection.get_connection()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute(sql, params)
                conn.commit()
                messagebox.showinfo("Success", "Operation Successful!")
                if callback: callback()
                self.load_audit()
            except Exception as e:
                conn.rollback()
                messagebox.showerror("Database Error", f"Operation Failed:\n{e}")
            finally:
                conn.close()

    def run_query(self, sql, tree, params=None):
        for r in tree.get_children(): tree.delete(r)
        conn = db_connection.get_connection()
        if conn:
            try:
                cur = conn.cursor()
                if params: cur.execute(sql, params)
                else: cur.execute(sql)
                rows = cur.fetchall()
                if rows:
                    if hasattr(self, 'tr_query') and tree == self.tr_query: 
                        cols = [desc[0] for desc in cur.description]
                        tree['columns'] = cols
                        for c in cols: tree.heading(c, text=c); tree.column(c, anchor="center")
                    
                    for row in rows: tree.insert("", "end", values=row)
            except Exception as e: 
                messagebox.showerror("Read Error", f"{e}")
            finally: conn.close()

    def mk_tree(self, parent, cols, style):
        # Added a scrollbar for better UX
        f = ttk.Frame(parent)
        f.pack(expand=True, fill="both", padx=10, pady=10)
        
        tv = ttk.Treeview(f, columns=cols, show="headings", bootstyle=style)
        for c in cols: tv.heading(c, text=c); tv.column(c, anchor="center")
        
        sb = ttk.Scrollbar(f, orient="vertical", command=tv.yview)
        tv.configure(yscrollcommand=sb.set)
        
        tv.pack(side="left", expand=True, fill="both")
        sb.pack(side="right", fill="y")
        return tv

    def mk_ent(self, parent, txt, col):
        ttk.Label(parent, text=txt, font=("Arial", 10, "bold")).pack(side="left", padx=5)
        ent = ttk.Entry(parent, width=12)
        ent.pack(side="left", padx=5)
        return ent

    # ==========================
    #      HOME TAB
    # ==========================
    def build_home(self):
        # 1. LOGO SECTION
        try:
            image_path = "nscs_logo.png" 
            if os.path.exists(image_path):
                img = Image.open(image_path).resize((350, 180), Image.Resampling.LANCZOS)
                self.logo_img = ImageTk.PhotoImage(img) 
                ttk.Label(self.tab_home, image=self.logo_img).pack(pady=(40, 20))
            else:
                ttk.Label(self.tab_home, text="[Logo Missing: nscs_logo.png]", bootstyle="danger").pack(pady=20)
        except: pass

        # 2. TITLE SECTION
        ttk.Label(self.tab_home, text="University Management System", font=("Helvetica", 32, "bold"), bootstyle="primary").pack(pady=10)
        
        # 3. AUTHORS SECTION (Styled Frame)
        f_auth = ttk.Labelframe(self.tab_home, text="  Project Developers  ", padding=20, bootstyle="info")
        f_auth.pack(pady=20)
        ttk.Label(f_auth, text="RABAH HADDADI   &   MOHAMED ESSADEK ABBACI", font=("Arial", 16, "bold"), bootstyle="inverse-info").pack()
        ttk.Label(self.tab_home, text="National School of Cybersecurity (NSCS)", font=("Arial", 14, "italic")).pack(pady=5)

        # 4. CONNECTION TEST
        btn_test = ttk.Button(self.tab_home, text="Test Database Connection", bootstyle="success-outline", command=self.test_db, width=30)
        btn_test.pack(pady=30)
        self.lbl_status = ttk.Label(self.tab_home, text="System Status: Ready", bootstyle="secondary", font=("Arial", 12))
        self.lbl_status.pack()

    def test_db(self):
        conn = db_connection.get_connection()
        if conn: 
            dsn = conn.get_dsn_parameters()
            db_name = dsn.get('dbname')
            self.lbl_status.config(text=f"Connected to: {db_name}", bootstyle="success")
            messagebox.showinfo("Connected", f"Successfully connected to database: {db_name}")
            conn.close()
        else: 
            self.lbl_status.config(text="Connection Failed", bootstyle="danger")

    # ==========================
    #   CRUD TABS (Full CRUD)
    # ==========================
    
    # 1. STUDENTS
    def build_students(self, p):
        f = ttk.Labelframe(p, text="Manage Students", padding=15, bootstyle="success"); f.pack(fill="x", padx=10, pady=5)
        self.e_sid = self.mk_ent(f, "ID:",0); self.e_sfn = self.mk_ent(f, "First:",2); self.e_sln = self.mk_ent(f, "Last:",4)
        self.e_grp = self.mk_ent(f, "Grp:",6); self.e_sec = self.mk_ent(f, "Sec:",8)
        
        ttk.Separator(f, orient='vertical').pack(side="left", padx=15, fill='y') # Visual separator
        
        ttk.Button(f, text="Add", bootstyle="success", command=self.add_stud, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="warning", command=self.upd_stud, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_stud, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Clear", bootstyle="secondary", command=self.load_stud, width=8).pack(side="left", padx=5)
        
        self.tr_stud = self.mk_tree(p, ["ID","First Name","Last Name","Group","Section"], "success")
        self.tr_stud.bind("<<TreeviewSelect>>", self.fill_stud)
        self.load_stud()

    def fill_stud(self, e):
        s = self.tr_stud.selection()
        if s: 
            v = self.tr_stud.item(s)['values']
            self.e_sid.delete(0,'end'); self.e_sid.insert(0,v[0])
            self.e_sfn.delete(0,'end'); self.e_sfn.insert(0,v[1])
            self.e_sln.delete(0,'end'); self.e_sln.insert(0,v[2])
            self.e_grp.delete(0,'end'); self.e_grp.insert(0,v[3])
            self.e_sec.delete(0,'end'); self.e_sec.insert(0,v[4])

    def load_stud(self): self.run_query("SELECT student_id, first_name, last_name, academic_group, section FROM Student ORDER BY student_id", self.tr_stud)
    def add_stud(self): self.execute_sql("INSERT INTO Student (student_id, first_name, last_name, academic_group, section, dob) VALUES (%s,%s,%s,%s,%s, CURRENT_DATE)", (self.e_sid.get(), self.e_sfn.get(), self.e_sln.get(), self.e_grp.get(), self.e_sec.get()), self.load_stud)
    def upd_stud(self): self.execute_sql("UPDATE Student SET first_name=%s, last_name=%s, academic_group=%s, section=%s WHERE student_id=%s", (self.e_sfn.get(), self.e_sln.get(), self.e_grp.get(), self.e_sec.get(), self.e_sid.get()), self.load_stud)
    def del_stud(self): self.execute_sql("DELETE FROM Student WHERE student_id=%s", (self.e_sid.get(),), self.load_stud)

    # 2. INSTRUCTORS
    def build_instructors(self, p):
        f = ttk.Labelframe(p, text="Manage Instructors", padding=15, bootstyle="info"); f.pack(fill="x", padx=10, pady=5)
        self.e_iid = self.mk_ent(f, "ID:",0); self.e_ifn = self.mk_ent(f, "First:",2); self.e_iln = self.mk_ent(f, "Last:",4)
        ttk.Label(f, text="Rank:", font=("Arial", 10, "bold")).pack(side="left", padx=5)
        self.c_irank = ttk.Combobox(f, values=["Substitute","MCB","MCA","PROF"], width=10); self.c_irank.pack(side="left", padx=5); self.c_irank.current(0)
        self.e_idept = self.mk_ent(f, "DeptID:",8)
        
        ttk.Separator(f, orient='vertical').pack(side="left", padx=15, fill='y')

        ttk.Button(f, text="Add", bootstyle="info", command=self.add_inst, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="warning", command=self.upd_inst, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_inst, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Clear", bootstyle="secondary", command=self.load_inst, width=8).pack(side="left", padx=5)
        
        self.tr_inst = self.mk_tree(p, ["ID","First Name","Last Name","Rank","Dept ID"], "info")
        self.tr_inst.bind("<<TreeviewSelect>>", self.fill_inst)
        self.load_inst()

    def fill_inst(self, e):
        s = self.tr_inst.selection()
        if s:
            v = self.tr_inst.item(s)['values']
            self.e_iid.delete(0,'end'); self.e_iid.insert(0,v[0])
            self.e_ifn.delete(0,'end'); self.e_ifn.insert(0,v[1])
            self.e_iln.delete(0,'end'); self.e_iln.insert(0,v[2])
            self.c_irank.set(v[3])
            self.e_idept.delete(0,'end'); self.e_idept.insert(0,v[4])

    def load_inst(self): self.run_query("SELECT instructor_id, first_name, last_name, rank, department_id FROM Instructor ORDER BY instructor_id", self.tr_inst)
    def add_inst(self): self.execute_sql("INSERT INTO Instructor (instructor_id, department_id, last_name, first_name, rank) VALUES (%s,%s,%s,%s,%s)", (self.e_iid.get(), self.e_idept.get(), self.e_iln.get(), self.e_ifn.get(), self.c_irank.get()), self.load_inst)
    def upd_inst(self): self.execute_sql("UPDATE Instructor SET first_name=%s, last_name=%s, rank=%s, department_id=%s WHERE instructor_id=%s", (self.e_ifn.get(), self.e_iln.get(), self.c_irank.get(), self.e_idept.get(), self.e_iid.get()), self.load_inst)
    def del_inst(self): self.execute_sql("DELETE FROM Instructor WHERE instructor_id=%s", (self.e_iid.get(),), self.load_inst)

    # 3. DEPARTMENTS
    def build_departments(self, p):
        f = ttk.Labelframe(p, text="Manage Departments", padding=15, bootstyle="primary"); f.pack(fill="x", padx=10, pady=5)
        self.e_did = self.mk_ent(f, "Dept ID:",0); self.e_dnm = self.mk_ent(f, "Name:",2)
        
        ttk.Separator(f, orient='vertical').pack(side="left", padx=15, fill='y')

        ttk.Button(f, text="Add", bootstyle="primary", command=self.add_dept, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="warning", command=self.upd_dept, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_dept, width=10).pack(side="left", padx=5)
        
        self.tr_dept = self.mk_tree(p, ["ID","Department Name"], "primary")
        self.tr_dept.bind("<<TreeviewSelect>>", self.fill_dept)
        self.load_dept()

    def fill_dept(self, e):
        s = self.tr_dept.selection()
        if s: v = self.tr_dept.item(s)['values']; self.e_did.delete(0,'end'); self.e_did.insert(0,v[0]); self.e_dnm.delete(0,'end'); self.e_dnm.insert(0,v[1])

    def load_dept(self): self.run_query("SELECT * FROM Department ORDER BY department_id", self.tr_dept)
    def add_dept(self): self.execute_sql("INSERT INTO Department VALUES (%s,%s)", (self.e_did.get(), self.e_dnm.get()), self.load_dept)
    def upd_dept(self): self.execute_sql("UPDATE Department SET name=%s WHERE department_id=%s", (self.e_dnm.get(), self.e_did.get()), self.load_dept)
    def del_dept(self): self.execute_sql("DELETE FROM Department WHERE department_id=%s", (self.e_did.get(),), self.load_dept)

    # 4. COURSES
    def build_courses(self, p):
        f = ttk.Labelframe(p, text="Manage Courses", padding=15, bootstyle="info"); f.pack(fill="x", padx=10, pady=5)
        self.e_cid = self.mk_ent(f, "ID:",0); self.e_cnm = self.mk_ent(f, "Name:",2); self.e_cdept = self.mk_ent(f, "DeptID:",4)
        
        ttk.Separator(f, orient='vertical').pack(side="left", padx=15, fill='y')

        ttk.Button(f, text="Add", bootstyle="info", command=self.add_cour, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="warning", command=self.upd_cour, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_cour, width=10).pack(side="left", padx=5)
        
        self.tr_cour = self.mk_tree(p, ["Course ID","Dept ID","Course Name"], "info")
        self.tr_cour.bind("<<TreeviewSelect>>", self.fill_cour)
        self.load_cour()

    def fill_cour(self, e):
        s = self.tr_cour.selection()
        if s: v = self.tr_cour.item(s)['values']; self.e_cid.delete(0,'end'); self.e_cid.insert(0,v[0]); self.e_cdept.delete(0,'end'); self.e_cdept.insert(0,v[1]); self.e_cnm.delete(0,'end'); self.e_cnm.insert(0,v[2])

    def load_cour(self): self.run_query("SELECT course_id, department_id, name FROM Course ORDER BY course_id", self.tr_cour)
    def add_cour(self): self.execute_sql("INSERT INTO Course (course_id, name, department_id) VALUES (%s,%s,%s)", (self.e_cid.get(), self.e_cnm.get(), self.e_cdept.get()), self.load_cour)
    def upd_cour(self): self.execute_sql("UPDATE Course SET name=%s WHERE course_id=%s AND department_id=%s", (self.e_cnm.get(), self.e_cid.get(), self.e_cdept.get()), self.load_cour)
    def del_cour(self): self.execute_sql("DELETE FROM Course WHERE course_id=%s AND department_id=%s", (self.e_cid.get(), self.e_cdept.get()), self.load_cour)

    # 5. ROOMS
    def build_rooms(self, p):
        f = ttk.Labelframe(p, text="Manage Rooms", padding=15, bootstyle="warning"); f.pack(fill="x", padx=10, pady=5)
        self.e_rb = self.mk_ent(f, "Building:",0); self.e_rn = self.mk_ent(f, "Room No:",2); self.e_rc = self.mk_ent(f, "Capacity:",4)
        
        ttk.Separator(f, orient='vertical').pack(side="left", padx=15, fill='y')

        ttk.Button(f, text="Add", bootstyle="warning", command=self.add_rm, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="secondary", command=self.upd_rm, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_rm, width=10).pack(side="left", padx=5)
        
        self.tr_rm = self.mk_tree(p, ["Building","Room No","Capacity"], "warning")
        self.tr_rm.bind("<<TreeviewSelect>>", self.fill_rm)
        self.load_rm()

    def fill_rm(self, e):
        s = self.tr_rm.selection()
        if s: v = self.tr_rm.item(s)['values']; self.e_rb.delete(0,'end'); self.e_rb.insert(0,v[0]); self.e_rn.delete(0,'end'); self.e_rn.insert(0,v[1]); self.e_rc.delete(0,'end'); self.e_rc.insert(0,v[2])

    def load_rm(self): self.run_query("SELECT * FROM Room", self.tr_rm)
    def add_rm(self): self.execute_sql("INSERT INTO Room VALUES (%s,%s,%s)", (self.e_rb.get(), self.e_rn.get(), self.e_rc.get()), self.load_rm)
    def upd_rm(self): self.execute_sql("UPDATE Room SET capacity=%s WHERE building=%s AND roomno=%s", (self.e_rc.get(), self.e_rb.get(), self.e_rn.get()), self.load_rm)
    def del_rm(self): self.execute_sql("DELETE FROM Room WHERE building=%s AND roomno=%s", (self.e_rb.get(), self.e_rn.get()), self.load_rm)

    # ==========================
    #   ACADEMIC TABS
    # ==========================
    
    def build_reservations(self, p):
        f = ttk.Labelframe(p, text="Reservations", padding=15, bootstyle="danger"); f.pack(fill="x", padx=10, pady=5)
        self.e_rid = self.mk_ent(f, "Res ID:",0); self.e_rins = self.mk_ent(f, "Inst ID:",2); self.e_rcid = self.mk_ent(f, "Course ID:",4)
        
        ttk.Button(f, text="Add", bootstyle="danger", command=self.add_res, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="secondary", command=self.del_res, width=10).pack(side="left", padx=5)
        self.tr_res = self.mk_tree(p, ["ID","Instructor","Course","Date","Time"], "danger")
        self.tr_res.bind("<<TreeviewSelect>>", lambda e: self.e_rid.insert(0, self.tr_res.item(self.tr_res.selection())['values'][0]))
        self.load_res()

    def load_res(self): self.run_query("SELECT reservation_id, instructor_id, course_id, reserv_date, start_time FROM Reservation", self.tr_res)
    def add_res(self): self.execute_sql("INSERT INTO Reservation (reservation_id, instructor_id, course_id, department_id, building, roomno, reserv_date, hours_number) VALUES (%s,%s,%s,1,'B','020',CURRENT_DATE,1)", (self.e_rid.get(), self.e_rins.get(), self.e_rcid.get()), self.load_res)
    def del_res(self): self.execute_sql("DELETE FROM Reservation WHERE reservation_id=%s", (self.e_rid.get(),), self.load_res)

    def build_enrollment(self, p):
        f = ttk.Labelframe(p, text="Student Enrollment", padding=15); f.pack(fill="x", padx=10, pady=5)
        self.e_esid = self.mk_ent(f, "Student ID:",0); self.e_ecid = self.mk_ent(f, "Course ID:",2); self.e_edid = self.mk_ent(f, "Dept ID:",4)
        
        ttk.Button(f, text="Enroll", bootstyle="success", command=self.add_enr, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Unenroll", bootstyle="danger", command=self.del_enr, width=10).pack(side="left", padx=5)
        self.tr_enr = self.mk_tree(p, ["Student ID","Course ID","Dept ID","Enroll Date"], "secondary")
        self.tr_enr.bind("<<TreeviewSelect>>", self.fill_enroll_form)
        self.load_enr()

    def fill_enroll_form(self, event):
        sel = self.tr_enr.selection()
        if sel:
            vals = self.tr_enr.item(sel)['values']
            self.e_esid.delete(0,'end'); self.e_esid.insert(0, vals[0])
            self.e_ecid.delete(0,'end'); self.e_ecid.insert(0, vals[1])
            self.e_edid.delete(0,'end'); self.e_edid.insert(0, vals[2])

    def load_enr(self): self.run_query("SELECT student_id, course_id, department_id, enrollment_date FROM Enrollment", self.tr_enr)
    def add_enr(self): self.execute_sql("INSERT INTO Enrollment (student_id, course_id, department_id) VALUES (%s,%s,%s)", (self.e_esid.get(), self.e_ecid.get(), self.e_edid.get()), self.load_enr)
    def del_enr(self): self.execute_sql("DELETE FROM Enrollment WHERE student_id=%s AND course_id=%s", (self.e_esid.get(), self.e_ecid.get()), self.load_enr)

    def build_marks(self, p):
        f = ttk.Labelframe(p, text="Student Marks", padding=15); f.pack(fill="x", padx=10, pady=5)
        self.e_mid = self.mk_ent(f, "Mark ID:",0); self.e_msid = self.mk_ent(f, "Student ID:",2); self.e_mcid = self.mk_ent(f, "Course ID:",4); self.e_mval = self.mk_ent(f, "Value:",6)
        
        ttk.Button(f, text="Add", bootstyle="success", command=self.add_mrk, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="warning", command=self.upd_mrk, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_mrk, width=10).pack(side="left", padx=5)
        self.tr_mrk = self.mk_tree(p, ["Mark ID","Student ID","Course ID","Value"], "secondary")
        self.tr_mrk.bind("<<TreeviewSelect>>", self.fill_mark_form)
        self.load_mrk()

    def fill_mark_form(self, event):
        sel = self.tr_mrk.selection()
        if sel:
            vals = self.tr_mrk.item(sel)['values']
            self.e_mid.delete(0,'end'); self.e_mid.insert(0, vals[0])
            self.e_msid.delete(0,'end'); self.e_msid.insert(0, vals[1])
            self.e_mcid.delete(0,'end'); self.e_mcid.insert(0, vals[2])
            self.e_mval.delete(0,'end'); self.e_mval.insert(0, vals[3])

    def load_mrk(self): self.run_query("SELECT mark_id, student_id, course_id, mark_value FROM Marks", self.tr_mrk)
    def add_mrk(self): self.execute_sql("INSERT INTO Marks (student_id, course_id, department_id, mark_value) VALUES (%s,%s,1,%s)", (self.e_msid.get(), self.e_mcid.get(), self.e_mval.get()), self.load_mrk)
    def upd_mrk(self): self.execute_sql("UPDATE Marks SET mark_value=%s WHERE mark_id=%s", (self.e_mval.get(), self.e_mid.get()), self.load_mrk)
    def del_mrk(self): self.execute_sql("DELETE FROM Marks WHERE mark_id=%s", (self.e_mid.get(),), self.load_mrk)

    def build_attendance(self, p):
        f = ttk.Labelframe(p, text="Attendance Log", padding=15, bootstyle="secondary"); f.pack(fill="x", padx=10, pady=5)
        self.e_asid = self.mk_ent(f, "Student ID:",0); self.e_acid = self.mk_ent(f, "Course ID:",2)
        ttk.Label(f, text="Status:", font=("Arial", 10, "bold")).pack(side="left", padx=5)
        self.c_ast = ttk.Combobox(f, values=["Present","Absent","Late"], width=10); self.c_ast.pack(side="left", padx=5); self.c_ast.current(0)
        
        ttk.Button(f, text="Log", bootstyle="primary", command=self.add_att, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Update", bootstyle="warning", command=self.update_attendance, width=10).pack(side="left", padx=5)
        ttk.Button(f, text="Delete", bootstyle="danger", command=self.del_attendance, width=10).pack(side="left", padx=5)
        self.tr_att = self.mk_tree(p, ["Att ID","Student ID","Course ID","Date","Status"], "secondary")
        self.tr_att.bind("<<TreeviewSelect>>", self.fill_att_form)
        self.load_att()

    def fill_att_form(self, event):
        sel = self.tr_att.selection()
        if sel:
            vals = self.tr_att.item(sel)['values']
            self.att_id_temp = vals[0]
            self.e_asid.delete(0,'end'); self.e_asid.insert(0, vals[1])
            self.e_acid.delete(0,'end'); self.e_acid.insert(0, vals[2])
            self.c_ast.set(vals[4])

    def load_att(self): self.run_query("SELECT attendance_id, student_id, course_id, attendance_date, status FROM Attendance", self.tr_att)
    def add_att(self): self.execute_sql("INSERT INTO Attendance (student_id, course_id, status) VALUES (%s,%s,%s)", (self.e_asid.get(), self.e_acid.get(), self.c_ast.get()), self.load_att)
    def update_attendance(self): 
        if hasattr(self, 'att_id_temp'): self.execute_sql("UPDATE Attendance SET status=%s WHERE attendance_id=%s", (self.c_ast.get(), self.att_id_temp), self.load_att)
    def del_attendance(self): 
        if hasattr(self, 'att_id_temp'): self.execute_sql("DELETE FROM Attendance WHERE attendance_id=%s", (self.att_id_temp,), self.load_att)

    def build_grading(self, p):
        f = ttk.Labelframe(p, text="Deliberation / Results", padding=15, bootstyle="success"); f.pack(fill="x", padx=10, pady=5)
        ttk.Button(f, text="Process Results", bootstyle="success", command=self.proc_grade, width=20).pack(side="left", padx=10)
        self.tr_grade = self.mk_tree(p, ["Student ID","Course ID","Mark","Status"], "success")

    def proc_grade(self):
        for r in self.tr_grade.get_children(): self.tr_grade.delete(r)
        conn = db_connection.get_connection()
        if conn:
            cur = conn.cursor(); cur.execute("SELECT student_id, course_id, mark_value FROM Marks"); rows = cur.fetchall(); conn.close()
            for r in rows:
                status = "PASS" if float(r[2]) >= 10 else "FAIL"
                self.tr_grade.insert("", "end", values=(r[0], r[1], r[2], status))

    # ==========================
    #   REPORTS & AUDIT
    # ==========================
    def build_queries_tab(self, p):
        # Using a colorful grid of buttons for the reports
        f = ttk.Labelframe(p, text="Generate Reports", padding=20, bootstyle="warning"); f.pack(fill="x", padx=10, pady=10)
        
        ttk.Button(f, text="(a) By Group", bootstyle="warning", width=18, command=lambda: self.run_rep("get_students_by_group", "Group")).grid(row=0,column=0,padx=15, pady=10)
        ttk.Button(f, text="(b) By Section", bootstyle="info", width=18, command=lambda: self.run_rep("get_students_by_section", "Section")).grid(row=0,column=1,padx=15, pady=10)
        ttk.Button(f, text="(h) Failing Students", bootstyle="danger", width=18, command=lambda: self.run_query("SELECT * FROM get_failing_students()", self.tr_query)).grid(row=0,column=2,padx=15, pady=10)
        ttk.Button(f, text="(i) Resit Eligible", bootstyle="primary", width=18, command=lambda: self.run_query("SELECT * FROM get_resit_students()", self.tr_query)).grid(row=0,column=3,padx=15, pady=10)
        ttk.Button(f, text="(j) Excluded List", bootstyle="secondary", width=18, command=lambda: self.run_query("SELECT * FROM get_excluded_students()", self.tr_query)).grid(row=0,column=4,padx=15, pady=10)
        
        self.tr_query = self.mk_tree(p, [], "warning")

    def run_rep(self, func, prompt):
        val = simpledialog.askstring("Report Parameter", f"Enter {prompt} Name:")
        if val: self.run_query(f"SELECT * FROM {func}(%s)", self.tr_query, (val,))

    def build_audit_tab(self, p):
        ttk.Button(p, text="Refresh Audit Logs", bootstyle="dark", command=self.load_audit, width=20).pack(pady=10)
        self.tr_audit = self.mk_tree(p, ["Audit ID","Operation","Time","User","Description"], "dark")
        self.load_audit()

    def load_audit(self): self.run_query("SELECT * FROM Student_Audit_Log ORDER BY audit_timestamp DESC", self.tr_audit)

if __name__ == "__main__":
    root = ttk.Window(themename="superhero") 
    app = UniversityApp(root)
    root.mainloop()