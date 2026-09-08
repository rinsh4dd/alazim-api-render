using System;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Repositories.Order
{
    public interface IOrderRepository
    {
        Task<(long OrderId, string DocNo)> PlaceOrderAsync(
            long customerUserId,
            long addressId,
            DateOnly deliveryDate,
            TimeSpan deliverySlotStartTime,
            TimeSpan deliverySlotEndTime,
            string paymentMethod,
            string? deliveryInstructions,
            CancellationToken cancellationToken = default);
    }
}
