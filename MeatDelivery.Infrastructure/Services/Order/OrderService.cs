using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Application.Interfaces.Order;
using MeatDelivery.Application.Interfaces.Repositories.Customer;
using MeatDelivery.Application.Interfaces.Repositories.Order;
using MeatDelivery.Domain.Entities.Addresses;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Order
{
    public class OrderService : IOrderService
    {
        private readonly ICartCalculationService _cartCalculationService;
        private readonly ICustomerRepository _customerRepository;
        private readonly IOrderRepository _orderRepository;

        public OrderService(
            ICartCalculationService cartCalculationService,
            ICustomerRepository customerRepository,
            IOrderRepository orderRepository)
        {
            _cartCalculationService = cartCalculationService;
            _customerRepository = customerRepository;
            _orderRepository = orderRepository;
        }

        public async Task<ApiResponse<PlaceOrderResponseDto>> PlaceOrderAsync(
            long customerUserId,
            PlaceOrderRequestDto request,
            CancellationToken cancellationToken = default)
        {
            // 1. Validate Active Cart
            var cartSummary = await _cartCalculationService.CalculateActiveCartAsync(customerUserId, cancellationToken);
            if (cartSummary == null || !cartSummary.Items.Any())
            {
                return ApiResponse<PlaceOrderResponseDto>.FailureResponse("Active cart is empty. Please add items to cart before placing an order.");
            }

            // 2. Validate Delivery Address
            var addresses = await _customerRepository.GetCustomerAddressAsync(
                new GetCustomerAddressQueryDto { AddressId = request.AddressId },
                customerUserId,
                cancellationToken);

            var selectedAddr = addresses.FirstOrDefault(a => a.AddressId == request.AddressId);
            if (selectedAddr == null)
            {
                return ApiResponse<PlaceOrderResponseDto>.FailureResponse("Selected delivery address is invalid or does not belong to the user.");
            }

            // 3. Execute Set-Based Place Order Stored Procedure (dbo.PR_PLACE_ORDER)
            var (orderId, docNo) = await _orderRepository.PlaceOrderAsync(
                customerUserId,
                request.AddressId,
                request.DeliveryDate,
                request.DeliverySlotStartTime,
                request.DeliverySlotEndTime,
                request.PaymentMethod.ToString(),
                request.DeliveryInstructions,
                cancellationToken);

            // 4. Construct Response
            decimal deliveryCharge = 0.00m;
            decimal subtotal = cartSummary.Summary.Subtotal;
            decimal couponDiscount = 0.00m;
            decimal totalAmount = subtotal - couponDiscount + deliveryCharge;
            var placedAt = DateTime.UtcNow;

            var response = new PlaceOrderResponseDto
            {
                OrderId = orderId,
                DocNo = docNo,
                OrderStatus = MeatDelivery.Domain.Enums.OrderStatus.PLACED,
                PaymentMethod = request.PaymentMethod,
                PaymentStatus = MeatDelivery.Domain.Enums.PaymentStatus.PENDING,
                Subtotal = subtotal,
                ProductDiscountTotal = 0.00m,
                CouponId = null,
                CouponDiscount = couponDiscount,
                DeliveryCharge = deliveryCharge,
                TotalAmount = totalAmount,
                CurrencyCode = "AED",
                PlacedAt = placedAt,
                DeliveryAddress = MapToAddressPreviewDto(selectedAddr),
                DeliverySchedule = new OrderDeliverySchedulePreviewDto
                {
                    DeliveryDate = request.DeliveryDate,
                    StartTime = request.DeliverySlotStartTime,
                    EndTime = request.DeliverySlotEndTime
                },
                Items = cartSummary.Items.Select(MapToItemPreviewDto).ToList()
            };

            return ApiResponse<PlaceOrderResponseDto>.SuccessResponse(response, "Order placed successfully.");
        }

        private static OrderDeliveryAddressPreviewDto MapToAddressPreviewDto(CustomerAddress addr)
        {
            return new OrderDeliveryAddressPreviewDto
            {
                AddressId = addr.AddressId,
                FirstName = addr.FirstName,
                LastName = addr.LastName,
                AddressType = addr.AddressType,
                ContactNumber = addr.ContactNumber,
                BuildingName = addr.BuildingName,
                VillaOrFlatNo = addr.VillaOrFlatNo,
                Street = addr.Street,
                Area = addr.Area,
                Landmark = addr.Landmark,
                City = addr.City,
                Emirate = addr.Emirate,
                PostalCode = addr.PostalCode,
                Latitude = addr.Latitude,
                Longitude = addr.Longitude,
                IsDefault = addr.IsDefault
            };
        }

        private static OrderItemPreviewDto MapToItemPreviewDto(MeatDelivery.Application.DTOs.Cart.CartItemDetailDto item)
        {
            return new OrderItemPreviewDto
            {
                ProductId = item.ProductId,
                ProductNameEn = item.ProductNameEn,
                ProductNameAr = item.ProductNameAr,
                ProductImage = item.ProductImage,
                UnitDescription = item.UnitDescription ?? "Unit",
                RegularUnitPrice = item.UnitPrice,
                SellingUnitPrice = item.UnitPrice,
                CustomizationUnitPrice = item.TotalCustomizationExtraPrice,
                Quantity = item.Quantity,
                LineSubtotal = item.UnitPrice * item.Quantity,
                ProductDiscountAmount = 0.00m,
                LineTotal = item.LineTotalPrice,
                SpecialInstructions = item.SpecialInstructions,
                Customizations = item.CustomizationOptions.Select(opt => new OrderItemCustomizationPreviewDto
                {
                    CustomizationOptionId = opt.CustomizationOptionId,
                    GroupNameEn = opt.GroupNameEn,
                    GroupNameAr = opt.GroupNameAr,
                    OptionCode = opt.OptionCode,
                    OptionNameEn = opt.OptionNameEn,
                    OptionNameAr = opt.OptionNameAr,
                    AdditionalPrice = opt.OptionPrice
                }).ToList()
            };
        }
    }
}
