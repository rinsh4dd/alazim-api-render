using System;

namespace MeatDelivery.Domain.Entities.Authentication
{
    public class CreateOtpVerificationResult
    {
        public bool IsSuccess { get; set; }
        public int StatusCode { get; set; }
        public string Message { get; set; } = string.Empty;
        public int Interval { get; set; }
        public long OtpId { get; set; }
        public Guid ChallengeId { get; set; }
        public int ResendCount { get; set; }
    }
}
