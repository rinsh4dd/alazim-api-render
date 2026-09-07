using System;

namespace MeatDelivery.Application.DTOs.Company
{
    public class GetCompanyHolidaysQueryDto
    {
        public long? CompanyHolidayId { get; set; }
        public long? CompanyConfigId { get; set; }
        public DateTime? HolidayDate { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public string? HolidayType { get; set; }
        public bool? IsActive { get; set; }
    }
}
