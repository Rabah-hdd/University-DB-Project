import ttkbootstrap as ttk
from ttkbootstrap.constants import *
from tkinter import messagebox
import db_connection

class UniversityApp:
    def __init__(self, root):
        self.root = root
        self.root.title("University Database Manager")
        self.root.geometry("1000x700")
        
        # --- 1. SETUP TABS ---
        self.tabs = ttk.Notebook(root)
        self.tabs.pack(expand=1, fill="both", padx=15, pady=15)

        self.tab_home = ttk.Frame(self.tabs)
        self.tab_students = ttk.Frame(self.tabs)
        self.tab_instructors = ttk.Frame(self.tabs)
        self.tab_results = ttk.Frame(self.tabs)

        self.tabs.add(self.tab_home, text="Home")
        self.tabs.add(self.tab_students, text="Manage Students")
        self.tabs.add(self.tab_instructors, text="Manage Instructors")
        self.tabs.add(self.tab_results, text="Results & Stats")

        # --- 2. BUILD CONTENT ---
        self.build_home_tab()
        self.build_student_tab()

    # ==========================
    #      HOME TAB LOGIC
    # ==========================
    def build_home_tab(self):
        # Title with Green text (success)
        title = ttk.Label(self.tab_home, text="University Management System", 
                          font=("Helvetica", 24, "bold"), bootstyle="success")
        title.pack(pady=40)

        status_lbl = ttk.Label(self.tab_home, text="System Status: Online", 
                               bootstyle="inverse-success", font=("Arial", 12)) 
        status_lbl.pack(pady=10)

        # Green Outline Button
        btn_test = ttk.Button(self.tab_home, text="Test Database Connection", 
                             bootstyle="success-outline", 
                             command=self.test_db_connection)
        btn_test.pack(pady=20)

    def test_db_connection(self):
        conn = db_connection.get_connection()
        if conn:
            messagebox.showinfo("Success", "Connected to PostgreSQL Database Successfully!")
            conn.close()
        else:
            messagebox.showerror("Error", "Failed to connect. Check your password in db_connection.py")

    # ==========================
    #     STUDENT TAB LOGIC
    # ==========================
    def build_student_tab(self):
        # --- A. INPUT AREA (Top) ---
        # Dark Gray background is automatic, Green border text
        frame_input = ttk.Labelframe(self.tab_students, text="Add New Student", padding=20, bootstyle="success")
        frame_input.pack(side="top", fill="x", padx=20, pady=10)

        # Row 1 Inputs
        ttk.Label(frame_input, text="ID:").grid(row=0, column=0, padx=5, pady=5)
        self.ent_id = ttk.Entry(frame_input, width=10)
        self.ent_id.grid(row=0, column=1, padx=5, pady=5)

        ttk.Label(frame_input, text="First Name:").grid(row=0, column=2, padx=5, pady=5)
        self.ent_fname = ttk.Entry(frame_input, width=15)
        self.ent_fname.grid(row=0, column=3, padx=5, pady=5)

        ttk.Label(frame_input, text="Last Name:").grid(row=0, column=4, padx=5, pady=5)
        self.ent_lname = ttk.Entry(frame_input, width=15)
        self.ent_lname.grid(row=0, column=5, padx=5, pady=5)
        
        # Row 2 Inputs
        ttk.Label(frame_input, text="DOB (YYYY-MM-DD):").grid(row=1, column=0, padx=5, pady=5)
        self.ent_dob = ttk.Entry(frame_input, width=15)
        self.ent_dob.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(frame_input, text="City:").grid(row=1, column=2, padx=5, pady=5)
        self.ent_city = ttk.Entry(frame_input, width=15)
        self.ent_city.grid(row=1, column=3, padx=5, pady=5)

        # BUTTONS (Green Theme)
        # Solid Green Button
        btn_add = ttk.Button(frame_input, text="Add Student", bootstyle="success", command=self.add_student)
        btn_add.grid(row=1, column=4, padx=10, pady=5)

        # Green Outline Button
        btn_refresh = ttk.Button(frame_input, text="Refresh List", bootstyle="success-outline", command=self.load_students)
        btn_refresh.grid(row=1, column=5, padx=10, pady=5)

        # Red Button for Delete (Important to keep red for warning)
        btn_delete = ttk.Button(frame_input, text="Delete Selected", bootstyle="danger", command=self.delete_student)
        btn_delete.grid(row=1, column=6, padx=10, pady=5)

        # --- B. DATA TABLE (Bottom) ---
        frame_table = ttk.Frame(self.tab_students)
        frame_table.pack(expand=True, fill="both", padx=20, pady=10)

        columns = ("id", "fname", "lname", "dob", "city")
        
        # 'success' style makes the table headers Green
        self.tree_student = ttk.Treeview(frame_table, columns=columns, show="headings", bootstyle="success")
        
        self.tree_student.heading("id", text="Student ID")
        self.tree_student.heading("fname", text="First Name")
        self.tree_student.heading("lname", text="Last Name")
        self.tree_student.heading("dob", text="Date of Birth")
        self.tree_student.heading("city", text="City")

        for col in columns:
            self.tree_student.column(col, anchor="center")

        scrollbar = ttk.Scrollbar(frame_table, orient="vertical", command=self.tree_student.yview, bootstyle="success-round")
        self.tree_student.configure(yscrollcommand=scrollbar.set)
        
        scrollbar.pack(side="right", fill="y")
        self.tree_student.pack(expand=True, fill="both")

        self.load_students()

    # --- DATABASE FUNCTIONS ---
    def load_students(self):
        for row in self.tree_student.get_children():
            self.tree_student.delete(row)

        conn = db_connection.get_connection()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT student_id, first_name, last_name, dob, city FROM Student ORDER BY student_id")
            rows = cur.fetchall()
            for row in rows:
                self.tree_student.insert("", "end", values=row)
            conn.close()

    def add_student(self):
        s_id = self.ent_id.get()
        f_name = self.ent_fname.get()
        l_name = self.ent_lname.get()
        dob = self.ent_dob.get()
        city = self.ent_city.get()

        if not s_id or not f_name:
            messagebox.showwarning("Input Error", "ID and Name are required!")
            return

        conn = db_connection.get_connection()
        if conn:
            try:
                cur = conn.cursor()
                sql = "INSERT INTO Student (student_id, first_name, last_name, dob, city) VALUES (%s, %s, %s, %s, %s)"
                cur.execute(sql, (s_id, f_name, l_name, dob, city))
                conn.commit()
                messagebox.showinfo("Success", "Student Added!")
                self.load_students()
                # Clear inputs
                self.ent_id.delete(0, 'end')
                self.ent_fname.delete(0, 'end')
                self.ent_lname.delete(0, 'end')
            except Exception as e:
                messagebox.showerror("Database Error", f"Could not add student: {e}")
            finally:
                conn.close()

    def delete_student(self):
        selected_item = self.tree_student.selection()
        if not selected_item:
            messagebox.showwarning("Select", "Please select a student to delete.")
            return
        
        row_values = self.tree_student.item(selected_item)['values']
        student_id = row_values[0]

        conn = db_connection.get_connection()
        if conn:
            try:
                cur = conn.cursor()
                cur.execute("DELETE FROM Student WHERE student_id = %s", (student_id,))
                conn.commit()
                messagebox.showinfo("Deleted", f"Student {student_id} deleted.")
                self.load_students()
            except Exception as e:
                messagebox.showerror("Error", f"Could not delete: {e}")
            finally:
                conn.close()

if __name__ == "__main__":
    # Theme: Superhero = Dark Gray Background
    root = ttk.Window(themename="superhero") 
    app = UniversityApp(root)
    root.mainloop()
