using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Invoice;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Data;
using MeatDelivery.Application.Interfaces.Repositories.Invoice;

namespace MeatDelivery.Infrastructure.Repositories.Invoice
{
    public class InvoiceRepository : IInvoiceRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public InvoiceRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<OrderInvoiceDto?> GetInvoiceByOrderIdAsync(long orderId, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_ORDER_INVOICE",
                async grid =>
                {
                    var rawInvoice = (await grid.ReadAsync<dynamic>()).FirstOrDefault();
                    if (rawInvoice == null) return null;

                    var invoice = new OrderInvoiceDto
                    {
                        InvoiceNo = (string)rawInvoice.InvoiceNo,
                        InvoiceDate = (System.DateTime)rawInvoice.InvoiceDate,
                        CompanyNameEn = (string?)rawInvoice.CompanyNameEn,
                        CompanyNameAr = (string?)rawInvoice.CompanyNameAr,
                        CompanyAddress = (string?)rawInvoice.CompanyAddress,
                        CompanyPhone = (string?)rawInvoice.CompanyPhone,
                        CompanyEmail = (string?)rawInvoice.CompanyEmail,
                        OrderId = (long)rawInvoice.OrderId,
                        OrderDocNo = (string)rawInvoice.OrderDocNo,
                        PlacedAt = (System.DateTime)rawInvoice.PlacedAt,
                        OrderStatus = (string)rawInvoice.OrderStatus,
                        CustomerUserId = (long)rawInvoice.CustomerUserId,
                        CustomerName = (string)rawInvoice.CustomerName,
                        CustomerPhone = (string)rawInvoice.CustomerPhone,
                        CustomerEmail = (string?)rawInvoice.CustomerEmail,
                        CurrencyCode = (string)rawInvoice.CurrencyCode,
                        Subtotal = (decimal)rawInvoice.Subtotal,
                        ProductDiscountTotal = (decimal)rawInvoice.ProductDiscountTotal,
                        CouponId = (long?)rawInvoice.CouponId,
                        CouponDiscount = (decimal)rawInvoice.CouponDiscount,
                        DeliveryCharge = (decimal)rawInvoice.DeliveryCharge,
                        TotalAmount = (decimal)rawInvoice.TotalAmount,
                        PaymentMethod = (string)rawInvoice.PaymentMethod,
                        PaymentStatus = (string)rawInvoice.PaymentStatus,
                        DeliveryAddress = new InvoiceAddressDto
                        {
                            AddressId = (long)rawInvoice.AddressId,
                            AddressType = (string)rawInvoice.AddressType,
                            ContactNumber = (string)rawInvoice.ContactNumber,
                            BuildingName = (string)rawInvoice.BuildingName,
                            VillaOrFlatNo = (string)rawInvoice.VillaOrFlatNo,
                            Street = (string)rawInvoice.Street,
                            Area = (string)rawInvoice.Area,
                            Landmark = (string)rawInvoice.Landmark,
                            City = (string)rawInvoice.City,
                            Emirate = (string)rawInvoice.Emirate,
                            PostalCode = (string)rawInvoice.PostalCode,
                            Latitude = (decimal)rawInvoice.Latitude,
                            Longitude = (decimal)rawInvoice.Longitude
                        },
                        DeliverySchedule = new InvoiceScheduleDto
                        {
                            DeliveryDate = rawInvoice.DeliveryDate != null ? rawInvoice.DeliveryDate.ToString() : string.Empty,
                            StartTime = rawInvoice.StartTime != null ? rawInvoice.StartTime.ToString() : string.Empty,
                            EndTime = rawInvoice.EndTime != null ? rawInvoice.EndTime.ToString() : string.Empty
                        }
                    };

                    var items = (await grid.ReadAsync<InvoiceItemDto>()).ToList();
                    var customizations = (await grid.ReadAsync<dynamic>()).ToList();

                    var customizationsLookup = customizations
                        .GroupBy(c => (long)c.OrderItemId)
                        .ToDictionary(
                            g => g.Key,
                            g => g.Select(c => new InvoiceItemCustomizationDto
                            {
                                CustomizationOptionId = (long)c.CustomizationOptionId,
                                GroupNameEn = (string)c.GroupNameEn,
                                GroupNameAr = (string)c.GroupNameAr,
                                OptionNameEn = (string)c.OptionNameEn,
                                OptionNameAr = (string)c.OptionNameAr,
                                AdditionalPrice = (decimal)c.AdditionalPrice
                            }).ToList()
                        );

                    foreach (var item in items)
                    {
                        if (customizationsLookup.TryGetValue(item.OrderItemId, out var itemCusts))
                        {
                            item.Customizations = itemCusts;
                        }
                    }

                    invoice.Items = items;
                    return invoice;
                },
                new { ORDER_ID = orderId }
            );
        }
    }
}
