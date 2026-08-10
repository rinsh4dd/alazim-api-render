using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace MeatDelivery.Application.Interfaces
{
    public interface IDapperRepository
    {
        Task<T?> QueryFirstOrDefaultAsync<T>(
            string storedProcedure,
            object? parameters = null,
            IDbTransaction? transaction = null);

        Task<IEnumerable<T>> QueryAsync<T>(
            string storedProcedure,
            object? parameters = null,
            IDbTransaction? transaction = null);

        Task<int> ExecuteAsync(
            string storedProcedure,
            object? parameters = null,
            IDbTransaction? transaction = null);

        Task<T> ExecuteScalarAsync<T>(
            string storedProcedure,
            object? parameters = null,
            IDbTransaction? transaction = null);

        Task<TReturn> QueryMultipleAsync<TReturn>(
            string storedProcedure,
            Func<Dapper.SqlMapper.GridReader, Task<TReturn>> map,
            object? parameters = null,
            IDbTransaction? transaction = null);
    }

}
