using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Order
{
    public interface IOrderService
    {
        Task<ApiResponse<PlaceOrderResponseDto>> PlaceOrderAsync(
            long customerUserId,
            PlaceOrderRequestDto request,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<List<CustomerOrderDetailDto>>> GetCustomerOrdersAsync(
            long customerUserId,
            GetCustomerOrdersQueryDto query,
            CancellationToken cancellationToken = default);

        Task<PagedResponse<List<AdminOrderDetailDto>>> GetAdminOrdersAsync(
            GetAdminOrdersQueryDto query,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<OrderTrackingResponseDto>> TrackOrderAsync(
            long orderId,
            long? customerUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<UpdateOrderStatusResponseDto>> UpdateOrderStatusAsync(
            UpdateOrderStatusDto request,
            long? adminUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<CancelOrderResponseDto>> CancelOrderAsync(
            CancelOrderDto request,
            long? customerUserId,
            long? adminUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<RescheduleOrderResponseDto>> RescheduleOrderAsync(
            RescheduleOrderDto request,
            long customerUserId,
            CancellationToken cancellationToken = default);
    }
}
