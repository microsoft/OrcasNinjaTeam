using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using MySql.Data.MySqlClient;

namespace Orcas.Function
{
    public static class mnDBaccess5
    {
        [Function("mnDBaccess5")]
        public static void Run([TimerTrigger("*/5 * * * * *")] MyInfo myTimer, FunctionContext context)
        {
            var logger = context.GetLogger("mnDBaccess5");
         
             string Host = System.Environment.GetEnvironmentVariable("HOST_NAME");
             string User = System.Environment.GetEnvironmentVariable("UID");
             string Password = System.Environment.GetEnvironmentVariable("DBPWD");
             
             string connstring = String.Format(
                 "Server={0};Port=3306;Database=weather;Uid={1};Pwd={2};SslMode=Preferred",
                        Host,
                        User,
                        Password);
             MySqlConnection conn = new MySqlConnection(connstring);
             MySqlCommand cmd1 = new MySqlCommand("SELECT * from weatherhistory LIMIT 100", conn);
             MySqlCommand cmd2 = new MySqlCommand("SELECT SLEEP(2)", conn);
             MySqlCommand cmd3 = new MySqlCommand("INSERT INTO `weather`.`weatherhistory` (`day`, `tempf`, `tempc`, `summary`) VALUES ('2021/5/18', '70', '20', 'sunny');",conn);
            try{
             
             conn.Open();
             
             MySqlDataReader r = cmd1.ExecuteReader();
             logger.LogInformation($"Got DB data  at: {DateTime.Now}");  
             r.Close();
             cmd2.ExecuteNonQuery();
             cmd3.ExecuteNonQuery();
             conn.Close();
             
            }
            catch(Exception e)
            {
                conn.Close();
                logger.LogError($"Got exception {e.Message}  at: {DateTime.Now}");   
            }
        }
    }

    public class MyInfo
    {
        public MyScheduleStatus ScheduleStatus { get; set; }

        public bool IsPastDue { get; set; }
    }

    public class MyScheduleStatus
    {
        public DateTime Last { get; set; }

        public DateTime Next { get; set; }

        public DateTime LastUpdated { get; set; }
    }
}
