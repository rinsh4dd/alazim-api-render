using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Order;

namespace MeatDelivery.Application.Interfaces.Repositories.Order
{
    public class OrderPlacementPersistenceDto
    {
        public long CustomerUserId { get; set; }
        public long AddressId { get; set; }
        public DateOnly DeliveryDate { get; set; }
        public TimeSpan DeliverySlotStartTime { get; set; }
        public TimeSpan DeliverySlotEndTime { get; set; }
        public string PaymentMethod { get; set; } = "COD";
        public string? DeliveryInstructions { get; set; }
        public decimal Subtotal { get; set; }
        public decimal DeliveryCharge { get; set; }
        public decimal CouponDiscount { get; set; }
        public decimal VatAmount { get; set; }
        public decimal TotalAmount { get; set; }
        public List<OrderItemPersistenceDto> Items { get; set; } = new();
    }

    public class OrderItemPersistenceDto
    {
        public long ProductId { get; set; }
        public string ProductCode { get; set; } = string.Empty;
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string UnitDescription { get; set; } = string.Empty;
        public decimal RegularUnitPrice { get; set; }
        public decimal SellingUnitPrice { get; set; }
        public decimal CustomizationUnitPrice { get; set; }
        public int Quantity { get; set; }
        public decimal LineSubtotal { get; set; }
        public decimal ProductDiscountAmount { get; set; }
        public decimal LineTotal { get; set; }
        public string? SpecialInstructions { get; set; }
        public List<OrderItemCustomizationPersistenceDto> Customizations { get; set; } = new();
    }

    public class OrderItemCustomizationPersistenceDto
    {
        public long CustomizationOptionId { get; set; }
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal AdditionalPrice { get; set; }
    }

    public class OrderTrackingRawHeaderDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string CurrentStatus { get; set; } = string.Empty;
        public string PaymentMethod { get; set; } = string.Empty;
        public string PaymentStatus { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public DateTime PlacedAtUae { get; set; }
        public DateTime DeliveryDate { get; set; }
        public TimeSpan DeliverySlotStartTime { get; set; }
        public TimeSpan DeliverySlotEndTime { get; set; }
        public string DeliveryContactNumber { get; set; } = string.Empty;
        public string DeliveryAddressSummary { get; set; } = string.Empty;
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
    }

    public interface IOrderRepository
    {
        Task<(long OrderId, string DocNo)> PlaceOrderAsync(
            OrderPlacementPersistenceDto dto,
            CancellationToken cancellationToken = default);

        Task<List<CustomerOrderDetailDto>> GetCustomerOrdersAsync(
            long customerUserId,
            GetCustomerOrdersQueryDto query,
            CancellationToken cancellationToken = default);

        Task<(List<AdminOrderDetailDto> Orders, int TotalCount)> GetAdminOrdersAsync(
            GetAdminOrdersQueryDto query,
            CancellationToken cancellationToken = default);

        Task<(OrderTrackingRawHeaderDto? Header, List<OrderTrackingStepDto> History)> TrackOrderAsync(
            long orderId,
            long? customerUserId,
            CancellationToken cancellationToken = default);

        Task<UpdateOrderStatusResponseDto> UpdateOrderStatusAsync(
            long orderId,
            string orderStatus,
            string? remarks,
            long? adminUserId,
            CancellationToken cancellationToken = default);

        Task<CancelOrderResponseDto> CancelOrderAsync(
            long orderId,
            long? customerUserId,
            long? adminUserId,
            string reason,
            string? remarks,
            CancellationToken cancellationToken = default);
    }
}
