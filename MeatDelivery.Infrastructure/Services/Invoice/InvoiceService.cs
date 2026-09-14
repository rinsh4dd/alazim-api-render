using System;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Invoice;
using MeatDelivery.Application.Interfaces.Invoice;
using MeatDelivery.Application.Interfaces.Repositories.Invoice;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Invoice
{
    public class InvoiceService : IInvoiceService
    {
        private readonly IInvoiceRepository _invoiceRepository;

        public InvoiceService(IInvoiceRepository invoiceRepository)
        {
            _invoiceRepository = invoiceRepository;
        }

        public async Task<ApiResponse<OrderInvoiceDto>> GetInvoiceByOrderIdAsync(long orderId, long? customerUserId = null, CancellationToken cancellationToken = default)
        {
            if (orderId <= 0)
            {
                return ApiResponse<OrderInvoiceDto>.FailureResponse("Valid OrderId is required.");
            }

            try
            {
                var invoice = await _invoiceRepository.GetInvoiceByOrderIdAsync(orderId, cancellationToken);
                if (invoice == null)
                {
                    return ApiResponse<OrderInvoiceDto>.FailureResponse($"Invoice for Order #{orderId} was not found.");
                }

                // Security check: If customerUserId is provided, verify ownership
                if (customerUserId.HasValue && customerUserId.Value > 0 && invoice.CustomerUserId != customerUserId.Value)
                {
                    return ApiResponse<OrderInvoiceDto>.FailureResponse("Unauthorized access to this order invoice.");
                }

                return ApiResponse<OrderInvoiceDto>.SuccessResponse(invoice, "Order invoice retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<OrderInvoiceDto>.FailureResponse(ex.Message);
            }
        }
    }
}
