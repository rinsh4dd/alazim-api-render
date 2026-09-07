using System;

namespace MeatDelivery.Domain.Entities.Company
{
    public class CompanyHoliday
    {
        public long CompanyHolidayId { get; set; }
        public long CompanyConfigId { get; set; }
        public DateTime HolidayDate { get; set; }
        public string HolidayType { get; set; } = "HOLIDAY";
        public bool IsFullDay { get; set; } = true;
        public TimeSpan? StartTime { get; set; }
        public TimeSpan? EndTime { get; set; }
        public string? ReasonEn { get; set; }
        public string? ReasonAr { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
