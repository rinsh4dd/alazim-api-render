using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;

namespace MeatDelivery.Migrations.Services
{
    public interface ISqlScriptExecutor
    {
        Task ExecuteScriptsAsync(
            string connectionString,
            string resourcePrefix,
            Assembly assembly,
            CancellationToken cancellationToken = default);
    }
}
