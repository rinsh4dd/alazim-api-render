using System;

namespace MeatDelivery.Domain.Entities.Company
{
    public class CompanyConfig
    {
        public long CompanyConfigId { get; set; }
        public string CompanyCode { get; set; } = string.Empty;
        public string CompanyNameEn { get; set; } = string.Empty;
        public string? CompanyNameAr { get; set; }
        public string? LegalName { get; set; }

        public string? AddressLine1 { get; set; }
        public string? AddressLine2 { get; set; }
        public string? Landmark { get; set; }
        public string? City { get; set; }
        public string? State { get; set; }
        public string? CountryCode { get; set; }
        public string? PostalCode { get; set; }

        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public string? GooglePlaceId { get; set; }

        public string? ContactCountryCode { get; set; }
        public string? ContactNumber { get; set; }
        public string? WhatsappNumber { get; set; }
        public string? Email { get; set; }
        public string? WebsiteUrl { get; set; }
        public string? LogoUrl { get; set; }

        public int AdvanceDeliveryDays { get; set; } = 7;

        public bool IsActive { get; set; } = true;
        public long? CreatedByAdminUserId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
