using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Data;
using System;
using System.Data;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Data
{
    public sealed class UnitOfWork : IUnitOfWork
    {
        private readonly IDbConnectionFactory _connectionFactory;
        private IDbConnection? _connection;
        private IDbTransaction? _transaction;
        private bool _disposed;

        public UnitOfWork(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public IDbConnection Connection
        {
            get
            {
                if (_connection == null || _connection.State == ConnectionState.Closed)
                {
                    _connection = _connectionFactory.CreateConnection();
                }
                return _connection;
            }
        }

        public IDbTransaction? Transaction => _transaction;

        public bool HasActiveTransaction => _transaction != null && _transaction.Connection != null;

        public async Task<IDbTransaction> BeginTransactionAsync(CancellationToken cancellationToken = default)
        {
            if (HasActiveTransaction)
            {
                throw new InvalidOperationException("A transaction is already active for this UnitOfWork session.");
            }

            var conn = Connection;
            if (conn.State != ConnectionState.Open)
            {
                if (conn is System.Data.Common.DbConnection dbConn)
                {
                    await dbConn.OpenAsync(cancellationToken);
                }
                else
                {
                    conn.Open();
                }
            }

            _transaction = conn.BeginTransaction();
            return _transaction;
        }

        public async Task CommitAsync(CancellationToken cancellationToken = default)
        {
            if (!HasActiveTransaction || _transaction == null)
            {
                throw new InvalidOperationException("No active transaction to commit.");
            }

            try
            {
                if (_transaction is System.Data.Common.DbTransaction dbTx)
                {
                    await dbTx.CommitAsync(cancellationToken);
                }
                else
                {
                    _transaction.Commit();
                }
            }
            finally
            {
                DisposeTransaction();
            }
        }

        public async Task RollbackAsync(CancellationToken cancellationToken = default)
        {
            if (!HasActiveTransaction || _transaction == null)
            {
                return;
            }

            try
            {
                if (_transaction is System.Data.Common.DbTransaction dbTx)
                {
                    await dbTx.RollbackAsync(cancellationToken);
                }
                else
                {
                    _transaction.Rollback();
                }
            }
            finally
            {
                DisposeTransaction();
            }
        }

        private void DisposeTransaction()
        {
            _transaction?.Dispose();
            _transaction = null;
        }

        public void Dispose()
        {
            if (_disposed) return;

            if (HasActiveTransaction)
            {
                _transaction?.Rollback();
            }

            DisposeTransaction();

            if (_connection != null)
            {
                if (_connection.State != ConnectionState.Closed)
                {
                    _connection.Close();
                }
                _connection.Dispose();
                _connection = null;
            }

            _disposed = true;
        }

        public async ValueTask DisposeAsync()
        {
            if (_disposed) return;

            if (HasActiveTransaction && _transaction is System.Data.Common.DbTransaction dbTx)
            {
                await dbTx.RollbackAsync();
            }
            else if (HasActiveTransaction)
            {
                _transaction?.Rollback();
            }

            DisposeTransaction();

            if (_connection != null)
            {
                if (_connection is System.Data.Common.DbConnection dbConn)
                {
                    await dbConn.CloseAsync();
                    await dbConn.DisposeAsync();
                }
                else
                {
                    _connection.Close();
                    _connection.Dispose();
                }
                _connection = null;
            }

            _disposed = true;
        }
    }
}
