using MeatDelivery.Domain.Entities.Authentication;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IUserRepository
    {
        Task<User?> GetByIdAsync(long userId, CancellationToken cancellationToken = default);
        Task<User?> GetByMobileAsync(string countryCode, string mobileNumber, CancellationToken cancellationToken = default);
    }
}
