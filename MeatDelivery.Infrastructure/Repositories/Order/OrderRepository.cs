using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Order;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Infrastructure.Repositories.Order
{
    public class OrderRepository : IOrderRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public OrderRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<(long OrderId, string DocNo)> PlaceOrderAsync(
            OrderPlacementPersistenceDto dto,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            // Build TVP for TT_ORDER_ITEMS
            var itemTable = new DataTable();
            itemTable.Columns.Add("ItemTempId", typeof(int));
            itemTable.Columns.Add("ProductId", typeof(long));
            itemTable.Columns.Add("ProductCode", typeof(string));
            itemTable.Columns.Add("ProductNameEn", typeof(string));
            itemTable.Columns.Add("ProductNameAr", typeof(string));
            itemTable.Columns.Add("UnitDescription", typeof(string));
            itemTable.Columns.Add("RegularUnitPrice", typeof(decimal));
            itemTable.Columns.Add("SellingUnitPrice", typeof(decimal));
            itemTable.Columns.Add("CustomizationUnitPrice", typeof(decimal));
            itemTable.Columns.Add("Quantity", typeof(int));
            itemTable.Columns.Add("LineSubtotal", typeof(decimal));
            itemTable.Columns.Add("ProductDiscountAmount", typeof(decimal));
            itemTable.Columns.Add("LineTotal", typeof(decimal));
            itemTable.Columns.Add("SpecialInstructions", typeof(string));

            // Build TVP for TT_ORDER_ITEM_CUSTOMIZATIONS
            var custTable = new DataTable();
            custTable.Columns.Add("ItemTempId", typeof(int));
            custTable.Columns.Add("CustomizationOptionId", typeof(long));
            custTable.Columns.Add("GroupNameEn", typeof(string));
            custTable.Columns.Add("GroupNameAr", typeof(string));
            custTable.Columns.Add("OptionNameEn", typeof(string));
            custTable.Columns.Add("OptionNameAr", typeof(string));
            custTable.Columns.Add("AdditionalPrice", typeof(decimal));

            int itemIndex = 1;
            foreach (var item in dto.Items)
            {
                int currentItemTempId = itemIndex++;

                itemTable.Rows.Add(
                    currentItemTempId,
                    item.ProductId,
                    item.ProductCode ?? string.Empty,
                    item.ProductNameEn,
                    item.ProductNameAr,
                    item.UnitDescription ?? "Kilogram",
                    item.RegularUnitPrice,
                    item.SellingUnitPrice,
                    item.CustomizationUnitPrice,
                    item.Quantity,
                    item.LineSubtotal,
                    item.ProductDiscountAmount,
                    item.LineTotal,
                    (object?)item.SpecialInstructions ?? DBNull.Value
                );

                foreach (var cust in item.Customizations)
                {
                    custTable.Rows.Add(
                        currentItemTempId,
                        cust.CustomizationOptionId,
                        cust.GroupNameEn,
                        cust.GroupNameAr,
                        cust.OptionNameEn,
                        cust.OptionNameAr,
                        cust.AdditionalPrice
                    );
                }
            }

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", dto.CustomerUserId);
            parameters.Add("ADDRESS_ID", dto.AddressId);
            parameters.Add("DELIVERY_DATE", dto.DeliveryDate.ToDateTime(TimeOnly.MinValue));
            parameters.Add("DELIVERY_SLOT_START_TIME", dto.DeliverySlotStartTime);
            parameters.Add("DELIVERY_SLOT_END_TIME", dto.DeliverySlotEndTime);
            parameters.Add("PAYMENT_METHOD", dto.PaymentMethod);
            parameters.Add("DELIVERY_INSTRUCTIONS", dto.DeliveryInstructions);
            parameters.Add("SUBTOTAL", dto.Subtotal);
            parameters.Add("DELIVERY_CHARGE", dto.DeliveryCharge);
            parameters.Add("COUPON_DISCOUNT", dto.CouponDiscount);
            parameters.Add("VAT_AMOUNT", dto.VatAmount);
            parameters.Add("TOTAL_AMOUNT", dto.TotalAmount);
            parameters.Add("ITEMS", itemTable.AsTableValuedParameter("dbo.TT_ORDER_ITEMS"));
            parameters.Add("CUSTOMIZATIONS", custTable.AsTableValuedParameter("dbo.TT_ORDER_ITEM_CUSTOMIZATIONS"));
            parameters.Add("ORDER_ID", dbType: DbType.Int64, direction: ParameterDirection.Output);
            parameters.Add("DOC_NO", dbType: DbType.String, direction: ParameterDirection.Output, size: 50);

            var commandDef = new CommandDefinition(
                "dbo.PR_PLACE_ORDER",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            await connection.ExecuteAsync(commandDef);

            long orderId = parameters.Get<long>("ORDER_ID");
            string docNo = parameters.Get<string>("DOC_NO");

            return (orderId, docNo);
        }

        public async Task<List<CustomerOrderDetailDto>> GetCustomerOrdersAsync(
            long customerUserId,
            GetCustomerOrdersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("ORDER_ID", query.OrderId);
            parameters.Add("ORDER_STATUS", query.OrderStatus?.ToString());
            parameters.Add("PAGE_NUMBER", query.PageNumber);
            parameters.Add("PAGE_SIZE", query.PageSize);

            var commandDef = new CommandDefinition(
                "dbo.PR_GET_CUSTOMER_ORDERS",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            using var grid = await connection.QueryMultipleAsync(commandDef);

            var rawHeaders = (await grid.ReadAsync<dynamic>()).ToList();
            var rawItems = (await grid.ReadAsync<dynamic>()).ToList();
            var rawCusts = (await grid.ReadAsync<dynamic>()).ToList();
            var rawHistory = (await grid.ReadAsync<dynamic>()).ToList();

            // Group Customizations by OrderItemId
            var custMap = rawCusts
                .GroupBy(c => (long)c.OrderItemId)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(c => new OrderItemCustomizationDetailDto
                    {
                        CustomizationOptionId = (long)c.CustomizationOptionId,
                        GroupNameEn = (string)c.GroupNameEn,
                        GroupNameAr = (string)c.GroupNameAr,
                        OptionNameEn = (string)c.OptionNameEn,
                        OptionNameAr = (string)c.OptionNameAr,
                        AdditionalPrice = (decimal)c.AdditionalPrice
                    }).ToList()
                );

            // Group Items by OrderId
            var itemMap = rawItems
                .GroupBy(i => (long)i.OrderId)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(i => new OrderItemDetailDto
                    {
                        OrderItemId = (long)i.OrderItemId,
                        ProductId = (long)i.ProductId,
                        ProductCode = (string)i.ProductCode,
                        ProductNameEn = (string)i.ProductNameEn,
                        ProductNameAr = (string)i.ProductNameAr,
                        ProductImage = (string)i.ProductImage,
                        UnitDescription = (string)i.UnitDescription,
                        RegularUnitPrice = (decimal)i.RegularUnitPrice,
                        SellingUnitPrice = (decimal)i.SellingUnitPrice,
                        CustomizationUnitPrice = (decimal)i.CustomizationUnitPrice,
                        Quantity = (int)i.Quantity,
                        LineSubtotal = (decimal)i.LineSubtotal,
                        ProductDiscountAmount = (decimal)i.ProductDiscountAmount,
                        LineTotal = (decimal)i.LineTotal,
                        SpecialInstructions = (string?)i.SpecialInstructions,
                        Customizations = custMap.TryGetValue((long)i.OrderItemId, out var custs) ? custs : new()
                    }).ToList()
                );

            // Group History by OrderId
            var historyMap = rawHistory
                .GroupBy(h => (long)h.OrderId)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(h => new OrderStatusHistoryDto
                    {
                        OrderStatus = Enum.TryParse<OrderStatus>((string)h.OrderStatus, true, out var st) ? st : OrderStatus.PLACED,
                        Remarks = (string?)h.Remarks,
                        CreatedAt = (DateTime)h.CreatedAt
                    }).ToList()
                );

            // Build CustomerOrderDetailDto list
            var result = new List<CustomerOrderDetailDto>();
            foreach (var h in rawHeaders)
            {
                long orderId = (long)h.OrderId;

                var order = new CustomerOrderDetailDto
                {
                    OrderId = orderId,
                    DocNo = (string)h.DocNo,
                    CustomerUserId = (long)h.CustomerUserId,
                    OrderStatus = Enum.TryParse<OrderStatus>((string)h.OrderStatus, true, out var os) ? os : OrderStatus.PLACED,
                    PaymentMethod = Enum.TryParse<PaymentMethod>((string)h.PaymentMethod, true, out var pm) ? pm : PaymentMethod.COD,
                    PaymentStatus = Enum.TryParse<PaymentStatus>((string)h.PaymentStatus, true, out var ps) ? ps : PaymentStatus.PENDING,
                    CurrencyCode = (string)h.CurrencyCode,
                    Subtotal = (decimal)h.Subtotal,
                    ProductDiscountTotal = (decimal)h.ProductDiscountTotal,
                    CouponId = (long?)h.CouponId,
                    CouponDiscount = (decimal)h.CouponDiscount,
                    DeliveryCharge = (decimal)h.DeliveryCharge,
                    VatAmount = (decimal)h.VatAmount,
                    TotalAmount = (decimal)h.TotalAmount,
                    PlacedAt = (DateTime)h.PlacedAt,
                    DeliveryAddress = new OrderDeliveryAddressPreviewDto
                    {
                        AddressId = (long)h.AddressId,
                        ContactNumber = (string)h.DeliveryContactNumber,
                        AddressType = (string?)h.DeliveryAddressType,
                        BuildingName = (string?)h.DeliveryBuildingName,
                        VillaOrFlatNo = (string)h.DeliveryVillaOrFlatNo,
                        Street = (string)h.DeliveryStreet,
                        Area = (string)h.DeliveryArea,
                        City = (string)h.DeliveryCity,
                        Landmark = (string?)h.DeliveryLandmark,
                        PostalCode = (string?)h.DeliveryPostalCode,
                        Emirate = (string)h.DeliveryEmirate,
                        Latitude = (decimal?)h.DeliveryLatitude,
                        Longitude = (decimal?)h.DeliveryLongitude
                    },
                    DeliverySchedule = new OrderDeliverySchedulePreviewDto
                    {
                        DeliveryDate = DateOnly.FromDateTime((DateTime)h.DeliveryDate),
                        StartTime = (TimeSpan)h.DeliverySlotStartTime,
                        EndTime = (TimeSpan)h.DeliverySlotEndTime
                    },
                    Items = itemMap.TryGetValue(orderId, out var items) ? items : new(),
                    StatusHistory = historyMap.TryGetValue(orderId, out var history) ? history : new()
                };

                result.Add(order);
            }

            return result;
        }

        public async Task<(List<AdminOrderDetailDto> Orders, int TotalCount)> GetAdminOrdersAsync(
            GetAdminOrdersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("ORDER_ID", query.OrderId);
            parameters.Add("SEARCH_TERM", query.SearchTerm);
            parameters.Add("CUSTOMER_USER_ID", query.CustomerUserId);
            parameters.Add("ORDER_STATUS", query.OrderStatus);
            parameters.Add("FROM_DATE", query.FromDate?.ToDateTime(TimeOnly.MinValue));
            parameters.Add("TO_DATE", query.ToDate?.ToDateTime(TimeOnly.MinValue));
            parameters.Add("PAGE_NUMBER", query.PageNumber);
            parameters.Add("PAGE_SIZE", query.PageSize);
            parameters.Add("TOTAL_COUNT", dbType: DbType.Int32, direction: ParameterDirection.Output);

            var commandDef = new CommandDefinition(
                "dbo.PR_GET_ADMIN_ORDERS",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            using var grid = await connection.QueryMultipleAsync(commandDef);

            var rawHeaders = (await grid.ReadAsync<dynamic>()).ToList();
            var rawItems = (await grid.ReadAsync<dynamic>()).ToList();
            var rawCusts = (await grid.ReadAsync<dynamic>()).ToList();
            var rawHistory = (await grid.ReadAsync<dynamic>()).ToList();

            int totalCount = parameters.Get<int>("TOTAL_COUNT");

            // Group Customizations by OrderItemId
            var custMap = rawCusts
                .GroupBy(c => (long)c.OrderItemId)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(c => new OrderItemCustomizationDetailDto
                    {
                        CustomizationOptionId = (long)c.CustomizationOptionId,
                        GroupNameEn = (string)c.GroupNameEn,
                        GroupNameAr = (string)c.GroupNameAr,
                        OptionNameEn = (string)c.OptionNameEn,
                        OptionNameAr = (string)c.OptionNameAr,
                        AdditionalPrice = (decimal)c.AdditionalPrice
                    }).ToList()
                );

            // Group Items by OrderId
            var itemMap = rawItems
                .GroupBy(i => (long)i.OrderId)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(i => new OrderItemDetailDto
                    {
                        OrderItemId = (long)i.OrderItemId,
                        ProductId = (long)i.ProductId,
                        ProductCode = (string)i.ProductCode,
                        ProductNameEn = (string)i.ProductNameEn,
                        ProductNameAr = (string)i.ProductNameAr,
                        ProductImage = (string)i.ProductImage,
                        UnitDescription = (string)i.UnitDescription,
                        RegularUnitPrice = (decimal)i.RegularUnitPrice,
                        SellingUnitPrice = (decimal)i.SellingUnitPrice,
                        CustomizationUnitPrice = (decimal)i.CustomizationUnitPrice,
                        Quantity = (int)i.Quantity,
                        LineSubtotal = (decimal)i.LineSubtotal,
                        ProductDiscountAmount = (decimal)i.ProductDiscountAmount,
                        LineTotal = (decimal)i.LineTotal,
                        SpecialInstructions = (string?)i.SpecialInstructions,
                        Customizations = custMap.TryGetValue((long)i.OrderItemId, out var custs) ? custs : new()
                    }).ToList()
                );

            // Group History by OrderId
            var historyMap = rawHistory
                .GroupBy(h => (long)h.OrderId)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(h => new OrderStatusHistoryDto
                    {
                        OrderStatus = Enum.TryParse<OrderStatus>((string)h.OrderStatus, true, out var st) ? st : OrderStatus.PLACED,
                        Remarks = (string?)h.Remarks,
                        CreatedAt = (DateTime)h.CreatedAt
                    }).ToList()
                );

            // Build AdminOrderDetailDto list
            var result = new List<AdminOrderDetailDto>();
            foreach (var h in rawHeaders)
            {
                long orderId = (long)h.OrderId;

                var order = new AdminOrderDetailDto
                {
                    OrderId = orderId,
                    DocNo = (string)h.DocNo,
                    CustomerUserId = (long)h.CustomerUserId,
                    CustomerFullName = (string)h.CustomerFullName,
                    CustomerMobileNumber = (string)h.CustomerMobileNumber,
                    CustomerCountryCode = (string?)h.CustomerCountryCode,
                    CustomerEmail = (string?)h.CustomerEmail,
                    OrderStatus = Enum.TryParse<OrderStatus>((string)h.OrderStatus, true, out var os) ? os : OrderStatus.PLACED,
                    PaymentMethod = Enum.TryParse<PaymentMethod>((string)h.PaymentMethod, true, out var pm) ? pm : PaymentMethod.COD,
                    PaymentStatus = Enum.TryParse<PaymentStatus>((string)h.PaymentStatus, true, out var ps) ? ps : PaymentStatus.PENDING,
                    CurrencyCode = (string)h.CurrencyCode,
                    Subtotal = (decimal)h.Subtotal,
                    ProductDiscountTotal = (decimal)h.ProductDiscountTotal,
                    CouponId = (long?)h.CouponId,
                    CouponDiscount = (decimal)h.CouponDiscount,
                    DeliveryCharge = (decimal)h.DeliveryCharge,
                    VatAmount = (decimal)h.VatAmount,
                    TotalAmount = (decimal)h.TotalAmount,
                    PlacedAt = (DateTime)h.PlacedAt,
                    DeliveryAddress = new OrderDeliveryAddressPreviewDto
                    {
                        AddressId = (long)h.AddressId,
                        ContactNumber = (string)h.DeliveryContactNumber,
                        AddressType = (string?)h.DeliveryAddressType,
                        BuildingName = (string?)h.DeliveryBuildingName,
                        VillaOrFlatNo = (string)h.DeliveryVillaOrFlatNo,
                        Street = (string)h.DeliveryStreet,
                        Area = (string)h.DeliveryArea,
                        City = (string)h.DeliveryCity,
                        Landmark = (string?)h.DeliveryLandmark,
                        PostalCode = (string?)h.DeliveryPostalCode,
                        Emirate = (string)h.DeliveryEmirate,
                        Latitude = (decimal?)h.DeliveryLatitude,
                        Longitude = (decimal?)h.DeliveryLongitude
                    },
                    DeliverySchedule = new OrderDeliverySchedulePreviewDto
                    {
                        DeliveryDate = DateOnly.FromDateTime((DateTime)h.DeliveryDate),
                        StartTime = (TimeSpan)h.DeliverySlotStartTime,
                        EndTime = (TimeSpan)h.DeliverySlotEndTime
                    },
                    Items = itemMap.TryGetValue(orderId, out var items) ? items : new(),
                    StatusHistory = historyMap.TryGetValue(orderId, out var history) ? history : new()
                };

                result.Add(order);
            }

            return (result, totalCount);
        }

        public async Task<(OrderTrackingRawHeaderDto? Header, List<OrderTrackingStepDto> History)> TrackOrderAsync(
            long orderId,
            long? customerUserId,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("ORDER_ID", orderId);
            parameters.Add("CUSTOMER_USER_ID", customerUserId);

            var commandDef = new CommandDefinition(
                "dbo.PR_TRACK_ORDER",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            using var grid = await connection.QueryMultipleAsync(commandDef);

            var header = (await grid.ReadAsync<OrderTrackingRawHeaderDto>()).FirstOrDefault();
            var historySteps = (await grid.ReadAsync<OrderTrackingStepDto>()).ToList();

            return (header, historySteps);
        }

        public async Task<UpdateOrderStatusResponseDto> UpdateOrderStatusAsync(
            long orderId,
            string orderStatus,
            string? remarks,
            long? adminUserId,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("ORDER_ID", orderId);
            parameters.Add("ORDER_STATUS", orderStatus);
            parameters.Add("REMARKS", remarks);
            parameters.Add("CHANGED_BY_ADMIN_USER_ID", adminUserId);

            var commandDef = new CommandDefinition(
                "dbo.PR_UPDATE_ORDER_STATUS",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            var result = await connection.QueryFirstOrDefaultAsync<UpdateOrderStatusResponseDto>(commandDef);
            return result ?? new UpdateOrderStatusResponseDto { OrderId = orderId, OrderStatus = orderStatus };
        }

        public async Task<CancelOrderResponseDto> CancelOrderAsync(
            long orderId,
            long? customerUserId,
            long? adminUserId,
            string reason,
            string? remarks,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("P_ORDER_ID", orderId);
            parameters.Add("P_CUSTOMER_USER_ID", customerUserId);
            parameters.Add("P_ADMIN_USER_ID", adminUserId);
            parameters.Add("P_CANCEL_REASON", reason);
            parameters.Add("P_REMARKS", remarks);

            var commandDef = new CommandDefinition(
                "dbo.PR_CANCEL_ORDER",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            var result = await connection.QueryFirstOrDefaultAsync<CancelOrderResponseDto>(commandDef);
            return result ?? new CancelOrderResponseDto { OrderId = orderId, NewStatus = "CANCELLED" };
        }
    }
}
