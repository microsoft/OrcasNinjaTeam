using System;
using Microsoft.EntityFrameworkCore;
using NpgsqlTypes;
using System.ComponentModel.DataAnnotations.Schema;

namespace aksdemo.Models
{
    public class WeatherForecast
    {
        public int id { get; set; }

        [NotMapped]
        public DateTime day { get; set; }

        public int tempf { get; set; }

        public int tempc { get; set; }
        public string summary { get; set; }
    }
}