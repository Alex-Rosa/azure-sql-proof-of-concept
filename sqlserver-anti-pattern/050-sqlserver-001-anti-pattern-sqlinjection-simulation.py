import pyodbc

# Connection variables
server = 'sqldb-01-257672.database.windows.net'  # Replace with your server name
database = 'AdventureWorksLT-AntiPattern'  # Replace with your database name
username = 'sqladmin'  # Replace with your username
password = '257672MyLabs1234'  # Replace with your password

# Create connection string
connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'

try:
    # Connect to Azure SQL Database
    connection = pyodbc.connect(connection_string)
    print("Connection established successfully!")
    
    # Example query
    cursor = connection.cursor()
    cursor.execute("EXEC dbo.GetCustomerByEmailAntiPattern @Email = 'orlando0@adventure-works.com'' OR 1=1 --';") 
    for row in cursor.fetchall():
        print(row)
    
    # Close the connection
    connection.close()
    print("Connection closed.")

except Exception as e:
    print(f"An error occurred: {e}")

    