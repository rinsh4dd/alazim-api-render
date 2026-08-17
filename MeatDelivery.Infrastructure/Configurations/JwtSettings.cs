namespace MeatDelivery.Infrastructure.Configurations
{
    public sealed class JwtSettings
    {
        public const string SectionName = "JwtSettings";

        public string SecretKey { get; set; } = string.Empty;
        public string Issuer { get; set; } = string.Empty;
        public string Audience { get; set; } = string.Empty;
        public int AccessTokenExpiryMinutes { get; set; }
        public int AdminAccessTokenExpiryMinutes { get; set; } = 1440; // 1 day in minutes
        public int RefreshTokenExpiryDays { get; set; }
    }
}
