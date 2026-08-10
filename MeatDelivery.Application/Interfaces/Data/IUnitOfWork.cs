using System;
using System.Data;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Data
{
    public interface IUnitOfWork : IDisposable, IAsyncDisposable
    {
        IDbConnection Connection { get; }
        IDbTransaction? Transaction { get; }
        bool HasActiveTransaction { get; }

        Task<IDbTransaction> BeginTransactionAsync(CancellationToken cancellationToken = default);
        Task CommitAsync(CancellationToken cancellationToken = default);
        Task RollbackAsync(CancellationToken cancellationToken = default);
    }
}
