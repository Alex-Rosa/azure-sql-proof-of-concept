from sqlalchemy import create_engine, text
import time

# Set up the SQLAlchemy engine with connection pooling
engine = create_engine(
    "mssql+pyodbc://localhost/navitaire?driver=ODBC+Driver+17+for+SQL+Server",
    pool_size=5,      # Maximum number of connections in the pool
    max_overflow=2,   # Additional connections beyond the pool size
    pool_timeout=10,  # Timeout for acquiring a connection
    echo=True         # Prints SQLAlchemy connection logs (helpful for debugging)
)

# Function to open, close, and reuse connections in a cycle
def connection_cycle(repeats):
    for i in range(repeats):
        print(f"Cycle {i + 1}: Opening a connection...")
        # Acquire a connection from the pool
        with engine.connect() as conn:
            # Simulate a query or operation
            result = conn.execute(text("SELECT GETDATE() AS 'current_time'"))
            for row in result:
                print(f"Current time from database: {row[0]}")
            
            # Simulate some delay to observe connection reuse
            time.sleep(1)
        
        # The connection is automatically closed and returned to the pool
        print(f"Cycle {i + 1}: Connection closed and returned to the pool.\n")

# Run the connection cycle
connection_cycle(repeats=15)
