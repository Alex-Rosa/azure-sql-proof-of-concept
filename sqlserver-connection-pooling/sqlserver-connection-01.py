from sqlalchemy import create_engine, text
import datetime
import time

# Set up the SQLAlchemy engine with connection pooling
engine = create_engine(
    "mssql+pyodbc://localhost/navitaire?driver=ODBC+Driver+17+for+SQL+Server",
    pool_size=7,      # Maximum number of connections in the pool
    max_overflow=0,   # Additional connections beyond the pool size
    pool_timeout=10,  # Timeout for acquiring a connection
    echo=False         # Prints SQLAlchemy connection logs (helpful for debugging)
)

# Function to test connections and insert current time with a commit
def open_many_connections_and_insert(number_of_connections):
    connections = {}  # Dictionary to store connections, SPIDs, and their last activity time
    try:
        # Attempt to open multiple connections
        for i in range(number_of_connections):  # Adjust based on your desired number of connections
            print(f"Opening connection {i + 1}...")
            conn = engine.connect()  # Acquire a connection from the pool
            transaction = conn.begin()  # Begin a transaction

            try:
                # Retrieve the SPID for this connection
                spid_result = conn.execute(text("SELECT @@SPID AS 'Connection ID'"))
                spid = int(spid_result.fetchone()[0])  # Get the SPID from the result
                print(f"SPID for this connection: {spid}")

                # Track the connection and its SPID along with the last activity time
                current_time = time.time()
                connections[conn] = {"spid": spid, "last_activity": current_time}

                # Insert SPID and current time into the table
                current_time = datetime.datetime.now()
                print(f"Inserted current time: {current_time} and SPID: {spid}")
                conn.execute(
                    text("INSERT INTO connpoolinsert (insert_time, spid) VALUES (:current_time, :spid)"),
                    {"current_time": current_time, "spid": spid}
                )
                
                # Commit the transaction
                transaction.commit()
                print("Transaction committed.")
                                
                # Check for idle connections
                print("Checking for idle connections...")
                for connection, metadata in list(connections.items()):
                    if time.time() - metadata["last_activity"] > 30:  # Idle for more than X seconds
                        print(f"Closing idle connection with SPID: {metadata['spid']}")
                        connection.close()  # Close and return it to the pool
                        del connections[connection]  # Remove from tracking

                # Simulate some delay to observe connection reuse
                print("-----------------------Sleeping for 5 seconds-----------------------")
                time.sleep(5)
                
            except Exception as e:
                # Rollback the transaction if there's an error
                print(f"Error during insert: {e}")
                transaction.rollback()
                print("-----------------------Transaction rolled back-----------------------")
            
    except Exception as e:
        print(f"Error while opening connections: {e}")
    finally:
        # Close all remaining connections at the end
        for connection, metadata in connections.items():
            print(f"Closing remaining connection with SPID: {metadata['spid']}")
            connection.close()

# Call the Function to open, close, and reuse connections in a cycle
open_many_connections_and_insert(30)
