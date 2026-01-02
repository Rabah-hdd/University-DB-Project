import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import db_connection  # This imports the file you just saved

class UniversityApp:
    def __init__(self, root):
        self.root = root
        self.root.title("University Database Manager")
        self.root.geometry("900x600")

        # 1. Create the Tab Control (Notebook)
        self.tabs = ttk.Notebook(root)
        self.tabs.pack(expand=1, fill="both")

        # 2. Create the Tabs (Frames)
        self.tab_home = ttk.Frame(self.tabs)
        self.tab_students = ttk.Frame(self.tabs)
        self.tab_instructors = ttk.Frame(self.tabs)
        self.tab_results = ttk.Frame(self.tabs)

        # 3. Add Tabs to the Notebook
        self.tabs.add(self.tab_home, text="Home")
        self.tabs.add(self.tab_students, text="Manage Students")
        self.tabs.add(self.tab_instructors, text="Manage Instructors")
        self.tabs.add(self.tab_results, text="Results & Stats")

        # 4. Build the "Home" Tab Content
        self.build_home_tab()

    def build_home_tab(self):
        # Title Label
        title = tk.Label(self.tab_home, text="University Management System", font=("Helvetica", 24, "bold"))
        title.pack(pady=40)

        # Status Label
        status_lbl = tk.Label(self.tab_home, text="System Status: Ready", font=("Arial", 12), fg="green")
        status_lbl.pack(pady=10)

        # Test Connection Button
        btn_test = tk.Button(self.tab_home, text="Test Database Connection", 
                             font=("Arial", 14), bg="#dddddd", 
                             command=self.test_db_connection)
        btn_test.pack(pady=20)

    def test_db_connection(self):
        # This function calls your db_connection.py file
        conn = db_connection.get_connection()
        if conn:
            messagebox.showinfo("Success", "Connected to PostgreSQL Database 'final-check' Successfully!")
            conn.close()
        else:
            messagebox.showerror("Error", "Failed to connect. Check your password in db_connection.py")

if __name__ == "__main__":
    root = tk.Tk()
    app = UniversityApp(root)
    root.mainloop()