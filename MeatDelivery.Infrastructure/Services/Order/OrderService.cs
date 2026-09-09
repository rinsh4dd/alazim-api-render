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
        private readonly FluentValidation.IValidator<UpdateOrderStatusDto> _updateOrderStatusValidator;

        public OrderService(
            ICartCalculationService cartCalculationService,
            ICustomerRepository customerRepository,
            IOrderRepository orderRepository,
            FluentValidation.IValidator<UpdateOrderStatusDto> updateOrderStatusValidator)
        {
            _cartCalculationService = cartCalculationService;
            _customerRepository = customerRepository;
            _orderRepository = orderRepository;
            _updateOrderStatusValidator = updateOrderStatusValidator ?? throw new ArgumentNullException(nameof(updateOrderStatusValidator));
        }

        public async Task<ApiResponse<PlaceOrderResponseDto>> PlaceOrderAsync(
            long customerUserId,
            PlaceOrderRequestDto request,
            CancellationToken cancellationToken = default)
        {
            // 1. Validate Active Cart & Calculate Exact Pricing
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

            // 3. Build Persistence DTO with Exact Pre-Calculated Prices
            decimal deliveryCharge = 0.00m;
            decimal subtotal = cartSummary.Summary.Subtotal;
            decimal couponDiscount = 0.00m;
            decimal totalAmount = subtotal - couponDiscount + deliveryCharge;

            var persistenceDto = new OrderPlacementPersistenceDto
            {
                CustomerUserId = customerUserId,
                AddressId = selectedAddr.AddressId,
                DeliveryDate = request.DeliveryDate,
                DeliverySlotStartTime = request.DeliverySlotStartTime,
                DeliverySlotEndTime = request.DeliverySlotEndTime,
                PaymentMethod = request.PaymentMethod.ToString(),
                DeliveryInstructions = request.DeliveryInstructions,
                Subtotal = subtotal,
                DeliveryCharge = deliveryCharge,
                CouponDiscount = couponDiscount,
                VatAmount = 0.00m,
                TotalAmount = totalAmount,
                Items = cartSummary.Items.Select(item => new OrderItemPersistenceDto
                {
                    ProductId = item.ProductId,
                    ProductCode = string.Empty,
                    ProductNameEn = item.ProductNameEn,
                    ProductNameAr = item.ProductNameAr,
                    UnitDescription = item.UnitDescription ?? "Unit",
                    RegularUnitPrice = item.UnitPrice,
                    SellingUnitPrice = item.UnitPrice,
                    CustomizationUnitPrice = item.TotalCustomizationExtraPrice,
                    Quantity = item.Quantity,
                    LineSubtotal = item.UnitPrice * item.Quantity,
                    ProductDiscountAmount = 0.00m,
                    LineTotal = item.LineTotalPrice,
                    SpecialInstructions = item.SpecialInstructions,
                    Customizations = item.CustomizationOptions.Select(opt => new OrderItemCustomizationPersistenceDto
                    {
                        CustomizationOptionId = opt.CustomizationOptionId,
                        GroupNameEn = opt.GroupNameEn,
                        GroupNameAr = opt.GroupNameAr,
                        OptionNameEn = opt.OptionNameEn,
                        OptionNameAr = opt.OptionNameAr,
                        AdditionalPrice = opt.OptionPrice
                    }).ToList()
                }).ToList()
            };

            // 4. Execute Place Order Stored Procedure (dbo.PR_PLACE_ORDER)
            var (orderId, docNo) = await _orderRepository.PlaceOrderAsync(persistenceDto, cancellationToken);

            // 5. Construct Response
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

        public async Task<ApiResponse<List<CustomerOrderDetailDto>>> GetCustomerOrdersAsync(
            long customerUserId,
            GetCustomerOrdersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var orders = await _orderRepository.GetCustomerOrdersAsync(customerUserId, query, cancellationToken);
            return ApiResponse<List<CustomerOrderDetailDto>>.SuccessResponse(orders, "Customer orders retrieved successfully.");
        }

        public async Task<PagedResponse<List<AdminOrderDetailDto>>> GetAdminOrdersAsync(
            GetAdminOrdersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var (orders, totalCount) = await _orderRepository.GetAdminOrdersAsync(query, cancellationToken);

            return new PagedResponse<List<AdminOrderDetailDto>>
            {
                Success = true,
                Status = 1,
                Message = "Admin orders retrieved successfully.",
                Data = orders,
                PageNumber = query.PageNumber,
                PageSize = query.PageSize,
                TotalRecords = totalCount
            };
        }

        public async Task<ApiResponse<OrderTrackingResponseDto>> TrackOrderAsync(
            long orderId,
            long? customerUserId,
            CancellationToken cancellationToken = default)
        {
            var (header, historySteps) = await _orderRepository.TrackOrderAsync(orderId, customerUserId, cancellationToken);
            if (header == null)
            {
                return ApiResponse<OrderTrackingResponseDto>.FailureResponse("Order tracking details not found or access denied.");
            }

            var response = new OrderTrackingResponseDto
            {
                OrderId = header.OrderId,
                DocNo = header.DocNo,
                CurrentStatus = header.CurrentStatus,
                PaymentMethod = header.PaymentMethod,
                PaymentStatus = header.PaymentStatus,
                TotalAmount = header.TotalAmount,
                PlacedAtUae = header.PlacedAtUae,
                DeliveryDate = DateOnly.FromDateTime(header.DeliveryDate),
                DeliverySlotStartTime = header.DeliverySlotStartTime,
                DeliverySlotEndTime = header.DeliverySlotEndTime,
                DeliveryContactNumber = header.DeliveryContactNumber,
                DeliveryAddressSummary = header.DeliveryAddressSummary,
                Latitude = header.Latitude,
                Longitude = header.Longitude,
                TrackingSteps = historySteps
            };

            return ApiResponse<OrderTrackingResponseDto>.SuccessResponse(response, "Order tracking details retrieved successfully.");
        }

        public async Task<ApiResponse<UpdateOrderStatusResponseDto>> UpdateOrderStatusAsync(
            UpdateOrderStatusDto request,
            long? adminUserId,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _updateOrderStatusValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<UpdateOrderStatusResponseDto>.FailureResponse("Validation failed.", errors);
            }

            var result = await _orderRepository.UpdateOrderStatusAsync(
                request.OrderId,
                request.OrderStatus,
                request.Remarks,
                adminUserId,
                cancellationToken);

            return ApiResponse<UpdateOrderStatusResponseDto>.SuccessResponse(result, $"Order status updated successfully to {result.OrderStatus}.");
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
