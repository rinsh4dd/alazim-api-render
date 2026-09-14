using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Invoice;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Invoice
{
    public interface IInvoiceService
    {
        Task<ApiResponse<OrderInvoiceDto>> GetInvoiceByOrderIdAsync(long orderId, long? customerUserId = null, CancellationToken cancellationToken = default);
    }
}
