using System;

namespace MeatDelivery.Application.DTOs.Customer
{
    public class UpdateCustomerProfileDto
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public DateTime? Dob { get; set; }
        public string? Gender { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? LanguageCode { get; set; }
    }
}
