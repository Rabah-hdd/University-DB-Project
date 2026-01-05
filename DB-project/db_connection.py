import psycopg2
from tkinter import messagebox

def get_connection():
    try:
        conn = psycopg2.connect(
            host="localhost",
            # UPDATED: In your screenshot, the active database is 'final-check'
            database="test",  
            
            # UPDATED: The user shown in your screenshot is 'postgres'
            user="postgres",        
            
            # CRITICAL: Delete this text and type your actual pgAdmin login password
            password="bouh@000", 
            
            port="5432"
        )
        return conn
    except Exception as e:
        messagebox.showerror("Connection Error", f"Error connecting to DB: {e}")
        return None