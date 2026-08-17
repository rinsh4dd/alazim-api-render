namespace MeatDelivery.Infrastructure.Security
{
    /// <summary>
    /// Configuration options for BCrypt password hashing.
    /// </summary>
    public sealed class PasswordHashingOptions
    {
        public const string SectionName = "Security:PasswordHashing";

        /// <summary>
        /// BCrypt work factor / cost (default 12, minimum 10, maximum 31).
        /// </summary>
        public int WorkFactor { get; init; } = 12;
    }
}
