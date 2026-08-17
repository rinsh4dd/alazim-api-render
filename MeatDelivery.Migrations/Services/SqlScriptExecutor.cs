using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Migrations.Services
{
    public sealed class SqlScriptExecutor : ISqlScriptExecutor
    {
        private readonly ILogger<SqlScriptExecutor> _logger;

        public SqlScriptExecutor(ILogger<SqlScriptExecutor> logger)
        {
            _logger = logger;
        }

        public async Task ExecuteScriptsAsync(
            string connectionString,
            string resourcePrefix,
            Assembly assembly,
            CancellationToken cancellationToken = default)
        {
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync(cancellationToken);

            await EnsureVersionTableAsync(connection);

            var scripts = assembly
                .GetManifestResourceNames()
                .Where(x => x.StartsWith(resourcePrefix, StringComparison.OrdinalIgnoreCase))
                .OrderBy(x => x)
                .ToList();

            foreach (var scriptResource in scripts)
            {
                var scriptName = Path.GetFileName(scriptResource.Replace('.', '_'));
                var baseMatch = Regex.Match(scriptResource, @"\d{4}_[A-Za-z0-9_]+");
                var baseScriptName = baseMatch.Success ? baseMatch.Value : scriptName;

                if (await IsScriptAppliedAsync(connection, scriptName, baseScriptName))
                {
                    _logger.LogInformation("Skipping already applied script: {ScriptName}", scriptName);
                    continue;
                }

                using var stream = assembly.GetManifestResourceStream(scriptResource)
                    ?? throw new InvalidOperationException($"Script not found: {scriptResource}");

                using var reader = new StreamReader(stream);
                var sql = await reader.ReadToEndAsync(cancellationToken);

                var stopwatch = Stopwatch.StartNew();

                await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

                try
                {
                    // Split SQL script into batches on T-SQL GO statements
                    var batches = Regex.Split(
                        sql,
                        @"^\s*GO\s*$",
                        RegexOptions.IgnoreCase | RegexOptions.Multiline);

                    foreach (var batch in batches)
                    {
                        var trimmedBatch = batch.Trim();
                        if (!string.IsNullOrWhiteSpace(trimmedBatch))
                        {
                            await connection.ExecuteAsync(trimmedBatch, transaction: transaction);
                        }
                    }

                    stopwatch.Stop();

                    await RecordScriptExecutionAsync(
                        connection,
                        transaction,
                        scriptName,
                        stopwatch.ElapsedMilliseconds,
                        ComputeChecksum(sql));

                    await transaction.CommitAsync(cancellationToken);

                    _logger.LogInformation("Applied script: {ScriptName}", scriptName);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to execute script: {ScriptName}", scriptName);

                    try
                    {
                        if (connection.State == ConnectionState.Open)
                        {
                            await transaction.RollbackAsync(cancellationToken);
                        }
                    }
                    catch (Exception rollbackEx)
                    {
                        _logger.LogWarning(rollbackEx, "Failed to rollback transaction for script: {ScriptName}", scriptName);
                    }

                    throw;
                }
            }
        }

        private static async Task EnsureVersionTableAsync(IDbConnection connection)
        {
            const string sql = """
            IF NOT EXISTS (
                SELECT 1
                FROM sys.tables
                WHERE name = 'SchemaVersions'
                  AND schema_id = SCHEMA_ID('dbo'))
            BEGIN
                CREATE TABLE dbo.SchemaVersions
                (
                    ScriptName      NVARCHAR(255) NOT NULL PRIMARY KEY,
                    AppliedOn       DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
                    ExecutionTimeMs INT           NULL,
                    AppliedBy       NVARCHAR(100) NULL,
                    Checksum        NVARCHAR(64)  NULL
                );
            END
            """;

            await connection.ExecuteAsync(sql);
        }

        private static async Task<bool> IsScriptAppliedAsync(
            IDbConnection connection,
            string scriptName,
            string baseScriptName)
        {
            const string sql = """
            SELECT COUNT(1)
            FROM dbo.SchemaVersions
            WHERE ScriptName = @ScriptName 
               OR ScriptName LIKE '%' + @BaseScriptName + '%';
            """;

            var count = await connection.ExecuteScalarAsync<int>(
                sql,
                new { ScriptName = scriptName, BaseScriptName = baseScriptName });

            return count > 0;
        }

        private static async Task RecordScriptExecutionAsync(
            IDbConnection connection,
            IDbTransaction transaction,
            string scriptName,
            long executionTimeMs,
            string checksum)
        {
            const string sql = """
            INSERT INTO dbo.SchemaVersions
            (
                ScriptName,
                AppliedOn,
                ExecutionTimeMs,
                AppliedBy,
                Checksum
            )
            VALUES
            (
                @ScriptName,
                SYSUTCDATETIME(),
                @ExecutionTimeMs,
                SYSTEM_USER,
                @Checksum
            );
            """;

            await connection.ExecuteAsync(
                sql,
                new
                {
                    ScriptName = scriptName,
                    ExecutionTimeMs = executionTimeMs,
                    Checksum = checksum
                },
                transaction);
        }

        private static string ComputeChecksum(string content)
        {
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(content));
            return Convert.ToHexString(bytes);
        }
    }
}
