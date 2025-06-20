using System;
using System.Data.SqlClient;
using System.Threading;

class Program
{
    // !!! IMPORTANT !!!
    // UPDATE THIS CONNECTION STRING to point to your database.
    private static readonly string _connectionString = "Server=your_server_name;Database=your_database_name;Integrated Security=True;";

    static void Main(string[] args)
    {
        Console.WriteLine("--- DEMONSTRATION OF CONNECTION POOLING TRAP ---");
        Console.WriteLine("Press any key to start the 'Careless Process' that pollutes the pool.");
        Console.ReadKey();

        RunCarelessProcess();

        Console.WriteLine("\n-------------------------------------------------");
        Console.WriteLine("Connection pool is now polluted.");
        Console.WriteLine("Press any key to start the 'Victim Process' that reuses the connection.");
        Console.ReadKey();

        RunVictimProcess();

        Console.WriteLine("\n-------------------------------------------------");
        Console.WriteLine("Demonstration complete. Press any key to exit.");
        Console.ReadKey();
    }

    /// <summary>
    /// This method opens a connection, changes the isolation level,
    /// and then "closes" it, returning the polluted connection to the pool.
    /// </summary>
    private static void RunCarelessProcess()
    {
        Console.WriteLine("\n1. Starting 'Careless Process'...");
        try
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                connection.Open();

                // Get the Server Process ID (SPID) and initial isolation level
                using (var command = new SqlCommand("SELECT @@SPID, CASE transaction_isolation_level WHEN 0 THEN 'Unspecified' WHEN 1 THEN 'ReadUncommitted' WHEN 2 THEN 'ReadCommitted' WHEN 3 THEN 'RepeatableRead' WHEN 4 THEN 'Serializable' WHEN 5 THEN 'Snapshot' END FROM sys.dm_exec_sessions WHERE session_id = @@SPID;", connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        reader.Read();
                        Console.WriteLine($"   SPID: {reader[0]}, Initial Isolation Level: {reader[1]}");
                    }
                }

                // Pollute the connection by changing the isolation level
                Console.WriteLine("   Action: Setting isolation level to SERIALIZABLE.");
                using (var command = new SqlCommand("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;", connection))
                {
                    command.ExecuteNonQuery();
                }

                 // Confirm the change
                using (var command = new SqlCommand("SELECT CASE transaction_isolation_level WHEN 4 THEN 'Serializable' ELSE 'Other' END FROM sys.dm_exec_sessions WHERE session_id = @@SPID;", connection))
                {
                     Console.WriteLine($"   Confirmation: Isolation level is now '{command.ExecuteScalar()}'.");
                }

                Console.WriteLine("   Action: Closing the connection (returning it to the pool).");
            } // The 'using' block calls connection.Close() here
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred: {ex.Message}");
        }
    }

    /// <summary>
    /// This method opens a new connection, which will be the one from the pool.
    /// It then demonstrates the impact of the inherited isolation level.
    /// </summary>
    private static void RunVictimProcess()
    {
        Console.WriteLine("\n2. Starting 'Victim Process'...");
        try
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                connection.Open();

                string inheritedLevel = "";
                // Check the SPID and isolation level upon connecting
                using (var command = new SqlCommand("SELECT @@SPID, CASE transaction_isolation_level WHEN 0 THEN 'Unspecified' WHEN 1 THEN 'ReadUncommitted' WHEN 2 THEN 'ReadCommitted' WHEN 3 THEN 'RepeatableRead' WHEN 4 THEN 'Serializable' WHEN 5 THEN 'Snapshot' END FROM sys.dm_exec_sessions WHERE session_id = @@SPID;", connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        reader.Read();
                        inheritedLevel = reader[1].ToString();
                        Console.WriteLine($"   SPID: {reader[0]}, INHERITED Isolation Level: {inheritedLevel}");
                    }
                }

                if (inheritedLevel == "Serializable")
                {
                    Console.WriteLine("\n   SUCCESS! The victim process inherited the SERIALIZABLE isolation level.");
                    Console.WriteLine("   Now, we will attempt a SELECT that will be blocked by an external transaction.");
                    Console.WriteLine("   Go to SSMS and run the 'Blocking Script' now. Then come back here.");

                    // Give user time to run the SSMS script
                    Thread.Sleep(5000); 
                    
                    try
                    {
                        Console.WriteLine("   Attempting to run 'SELECT * FROM dbo.Widgets'...");
                        using (var command = new SqlCommand("SELECT * FROM dbo.Widgets;", connection))
                        {
                            command.ExecuteNonQuery();
                        }
                        Console.WriteLine("   ...SELECT completed without blocking (this shouldn't happen if SSMS script is running).");
                    }
                    catch (SqlException ex)
                    {
                        // A timeout exception (error -2) proves the command was blocked.
                        if (ex.Number == -2) {
                             Console.WriteLine("\n   SUCCESS! The SELECT query timed out, which proves it was blocked by the external transaction in SSMS.");
                             Console.WriteLine("   This blocking occurred because this process inherited the SERIALIZABLE isolation level.");
                        } else {
                            Console.WriteLine($"   An unexpected SQL error occurred: {ex.Message}");
                        }
                    }

                }
                else
                {
                    Console.WriteLine("Demonstration failed. The isolation level was not inherited.");
                }

            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred: {ex.Message}");
        }
    }
}