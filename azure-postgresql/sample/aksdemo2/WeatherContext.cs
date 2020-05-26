 using System;
 using Npgsql;
 using Microsoft.EntityFrameworkCore;
 using aksdemo.Models;
 using System.Collections.Generic;

 namespace aksdemo
{
 public class WeatherForecastContext : DbContext
    {
        public int maxretry = 3;
        public TimeSpan interval = TimeSpan.FromMilliseconds(500);
         private static string Host = "<host name>";
        private static string User = "User name";
        private static string DBname = "Database name";
        private static string Password = "Password";
        private static string Port = "Port";

        public DbSet<WeatherForecast> weatherforecast { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
         => optionsBuilder.UseNpgsql(
                    String.Format(
                        "Server={0};Username={1};Database={2};Port={3};Password={4};SSLMode=Prefer",
                        Host,
                        User,
                        DBname,
                        Port,
                        Password),
            options => options.EnableRetryOnFailure());
    }
}