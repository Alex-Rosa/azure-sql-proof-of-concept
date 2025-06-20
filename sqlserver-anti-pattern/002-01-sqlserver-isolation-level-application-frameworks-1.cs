using System;
using System.Data.SqlClient;
using System.Transactions;

class Program
{
    // !!! IMPORTANT !!!
    // UPDATE THIS CONNECTION STRING to point to your database.
    private static readonly string _connectionString = "Server=your_server_name;Database=your_database_name;Integrated Security=True;";

    static void Main(string[] args)
    {
        Console.WriteLine("--- TransactionScope Default Behavior Demo ---");

        try
        {
            // By default, `new TransactionScope()` uses Serializable isolation.
            Console.WriteLine("1. Starting a transaction with default TransactionScope()...");
            using (var scope = new TransactionScope())
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    connection.Open();
                    Console.WriteLine("2. Connection opened within the transaction scope.");

                    // Let's verify the actual isolation level in SQL Server
                    string actualIsolationLevel = "";
                    using (var command = new SqlCommand("SELECT CASE transaction_isolation_level WHEN 4 THEN 'Serializable' ELSE 'Other' END FROM sys.dm_exec_sessions WHERE session_id = @@SPID;", connection))
                    {
                        actualIsolationLevel = command.ExecuteScalar()?.ToString();
                    }
                    
                    Console.WriteLine($"\n   >>> PROOF: The actual isolation level for this session is: {actualIsolationLevel} <<<\n");

                    if (actualIsolationLevel != "Serializable")
                    {
                        Console.WriteLine("   Warning: The isolation level is not Serializable. The demo may not work as expected.");
                    }

                    // Perform a simple read that covers a range of data.
                    // This will place a range lock due to the Serializable isolation level.
                    Console.WriteLine("3. Reading from the Widgets table to lock a range (WHERE WidgetName LIKE '%Spanner%')...");
                    using (var command = new SqlCommand("SELECT COUNT(*) FROM dbo.Widgets WHERE WidgetName LIKE '%Spanner%';", connection))
                    {
                        int count = (int)command.ExecuteScalar();
                        Console.WriteLine($"   Found {count} widget(s) matching the criteria.");
                    }

                    Console.WriteLine("\n-------------------------------------------------");
                    Console.WriteLine("4. The transaction is now active and holding locks.");
                    Console.WriteLine("   Go to SSMS and run the 'INSERT Script' now.");
                    Console.WriteLine("   You will see that the INSERT command hangs (is blocked).");
                    Console.WriteLine("   Press any key in this window to complete the transaction and release the locks.");
                    Console.ReadKey();

                    // If we get here, the transaction will be completed.
                    scope.Complete();
                    Console.WriteLine("-------------------------------------------------");
                    Console.WriteLine("\n5. TransactionScope Complete() called. The transaction is committed.");
                    Console.WriteLine("   The INSERT in SSMS should now be unblocked and complete immediately.");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred: {ex.Message}");
        }

        Console.WriteLine("\nDemonstration complete. Press any key to exit.");
        Console.ReadKey();
    }
}