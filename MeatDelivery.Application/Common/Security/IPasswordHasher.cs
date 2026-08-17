namespace MeatDelivery.Application.Common.Security
{
    /// <summary>
    /// Contract for hashing and verifying passwords securely without exposing underlying cryptographic implementation details.
    /// </summary>
    public interface IPasswordHasher
    {
        /// <summary>
        /// Hashes a plain-text password using the configured cryptographic algorithm.
        /// </summary>
        string Hash(string password);

        /// <summary>
        /// Verifies a plain-text password against a stored password hash.
        /// </summary>
        bool Verify(string password, string passwordHash);

        /// <summary>
        /// Checks whether a stored hash requires re-hashing due to upgraded work factor/cost or algorithm changes.
        /// </summary>
        bool NeedsRehash(string passwordHash);
    }
}
