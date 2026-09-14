using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Invoice;

namespace MeatDelivery.Application.Interfaces.Repositories.Invoice
{
    public interface IInvoiceRepository
    {
        Task<OrderInvoiceDto?> GetInvoiceByOrderIdAsync(long orderId, CancellationToken cancellationToken = default);
    }
}
