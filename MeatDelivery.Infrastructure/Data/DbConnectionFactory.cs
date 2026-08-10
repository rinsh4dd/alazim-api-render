using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using MeatDelivery.Application.Interfaces;
using System;
using System.Data;

namespace MeatDelivery.Infrastructure.Data
{
    public sealed class DbConnectionFactory : IDbConnectionFactory
    {
        private readonly string _connectionString;

        public DbConnectionFactory(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? configuration.GetConnectionString("MasterDb")
                ?? throw new InvalidOperationException("DefaultConnection configuration string is missing.");
        }

        public IDbConnection CreateConnection()
        {
            return new SqlConnection(_connectionString);
        }
    }
}
