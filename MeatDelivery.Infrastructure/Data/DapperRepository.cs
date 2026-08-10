using Dapper;
using MeatDelivery.Application.Interfaces;
using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace MeatDelivery.Infrastructure.Data
{
    public sealed class DapperRepository : IDapperRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;
        public DapperRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<T?> QueryFirstOrDefaultAsync<T>(
       string storedProcedure,
       object? parameters = null,
       IDbTransaction? transaction = null)
        {
            if (transaction?.Connection is not null)
            {
                return await transaction.Connection.QueryFirstOrDefaultAsync<T>(
                    storedProcedure,
                    parameters,
                    transaction,
                    commandType: CommandType.StoredProcedure);
            }

            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<T>(
                storedProcedure,
                parameters,
                commandType: CommandType.StoredProcedure);
        }


        public async Task<IEnumerable<T>> QueryAsync<T>(
       string storedProcedure,
       object? parameters = null,
       IDbTransaction? transaction = null)
        {
            if (transaction?.Connection is not null)
            {
                return await transaction.Connection.QueryAsync<T>(
                    storedProcedure,
                    parameters,
                    transaction,
                    commandType: CommandType.StoredProcedure);
            }

            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<T>(
                storedProcedure,
                parameters,
                commandType: CommandType.StoredProcedure);
        }


        public async Task<int> ExecuteAsync(
       string storedProcedure,
       object? parameters = null,
       IDbTransaction? transaction = null)
        {
            if (transaction?.Connection is not null)
            {
                return await transaction.Connection.ExecuteAsync(
                    storedProcedure,
                    parameters,
                    transaction,
                    commandType: CommandType.StoredProcedure);
            }

            using var connection = _connectionFactory.CreateConnection();
            return await connection.ExecuteAsync(
                storedProcedure,
                parameters,
                commandType: CommandType.StoredProcedure);
        }


        public async Task<T> ExecuteScalarAsync<T>(
       string storedProcedure,
       object? parameters = null,
       IDbTransaction? transaction = null)
        {
            if (transaction?.Connection is not null)
            {
                return await transaction.Connection.ExecuteScalarAsync<T>(
                    storedProcedure,
                    parameters,
                    transaction,
                    commandType: CommandType.StoredProcedure);
            }

            using var connection = _connectionFactory.CreateConnection();
            return await connection.ExecuteScalarAsync<T>(
                storedProcedure,
                parameters,
                commandType: CommandType.StoredProcedure);
        }

        public async Task<TReturn> QueryMultipleAsync<TReturn>(
            string storedProcedure,
            Func<SqlMapper.GridReader, Task<TReturn>> map,
            object? parameters = null,
            IDbTransaction? transaction = null)
        {
            if (transaction?.Connection is not null)
            {
                using var multi = await transaction.Connection.QueryMultipleAsync(
                    storedProcedure,
                    parameters,
                    transaction,
                    commandType: CommandType.StoredProcedure);
                return await map(multi);
            }

            using var connection = _connectionFactory.CreateConnection();
            using var multi2 = await connection.QueryMultipleAsync(
                storedProcedure,
                parameters,
                commandType: CommandType.StoredProcedure);
            return await map(multi2);
        }
    }
}
