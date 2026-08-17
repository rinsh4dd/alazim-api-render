namespace MeatDelivery.Application.Common.Security
{
    /// <summary>
    /// Contract for generating cryptographically secure random passwords.
    /// </summary>
    public interface IPasswordGenerator
    {
        /// <summary>
        /// Generates a cryptographically strong random password of the specified length.
        /// </summary>
        /// <param name="length">Length of the password (minimum 12).</param>
        /// <returns>A secure random password string.</returns>
        string Generate(int length = 16);
    }
}
