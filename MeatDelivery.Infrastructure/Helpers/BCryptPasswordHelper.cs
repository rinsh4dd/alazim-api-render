using System;
using System.Security.Cryptography;
using System.Text;

namespace MeatDelivery.Infrastructure.Helpers
{
    /// <summary>
    /// Static helper class for BCrypt password hashing, verification, and secure password generation.
    /// </summary>
    public static class BCryptPasswordHelper
    {
        private const int DefaultWorkFactor = 11;
        private const string UpperChars = "ABCDEFGHJKLMNPQRSTUVWXYZ";
        private const string LowerChars = "abcdefghijkmnopqrstuvwxyz";
        private const string DigitChars = "23456789";
        private const string SpecialChars = "!@#$%^&*()-_=+[]{}";

        /// <summary>
        /// Hashes a plain-text password using BCrypt with cryptographic salt and work factor.
        /// </summary>
        /// <param name="plainPassword">The plain-text password to hash.</param>
        /// <param name="workFactor">BCrypt work factor cost (default is 11, which equals 2048 rounds).</param>
        /// <returns>The generated BCrypt hash string.</returns>
        public static string Hash(string plainPassword, int workFactor = DefaultWorkFactor)
        {
            if (string.IsNullOrWhiteSpace(plainPassword))
            {
                throw new ArgumentException("Password cannot be null or empty.", nameof(plainPassword));
            }

            if (workFactor < 4 || workFactor > 31)
            {
                throw new ArgumentOutOfRangeException(nameof(workFactor), "Work factor must be between 4 and 31.");
            }

            return BCrypt.Net.BCrypt.HashPassword(plainPassword, workFactor);
        }

        /// <summary>
        /// Verifies a plain-text password against a stored BCrypt hash.
        /// </summary>
        /// <param name="plainPassword">The plain-text password to verify.</param>
        /// <param name="passwordHash">The stored BCrypt hash string.</param>
        /// <returns>True if password matches hash; otherwise false.</returns>
        public static bool Verify(string? plainPassword, string? passwordHash)
        {
            if (string.IsNullOrWhiteSpace(plainPassword) || string.IsNullOrWhiteSpace(passwordHash))
            {
                return false;
            }

            try
            {
                return BCrypt.Net.BCrypt.Verify(plainPassword, passwordHash);
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Determines whether a stored hash requires re-hashing due to upgraded work factor.
        /// </summary>
        /// <param name="passwordHash">The stored hash.</param>
        /// <param name="targetWorkFactor">The desired work factor cost (default 11).</param>
        /// <returns>True if hash should be regenerated; otherwise false.</returns>
        public static bool NeedsRehash(string? passwordHash, int targetWorkFactor = DefaultWorkFactor)
        {
            if (string.IsNullOrWhiteSpace(passwordHash))
            {
                return true;
            }

            try
            {
                // BCrypt hash format: $2a$11$...
                var parts = passwordHash.Split('$');
                if (parts.Length >= 3 && int.TryParse(parts[2], out var currentWorkFactor))
                {
                    return currentWorkFactor < targetWorkFactor;
                }
            }
            catch
            {
                return true;
            }

            return false;
        }

        /// <summary>
        /// Generates a cryptographically strong random password for user creation or temporary resets.
        /// </summary>
        /// <param name="length">Length of password (minimum 8, default 16).</param>
        /// <param name="includeSpecialChars">Whether to include special symbols.</param>
        /// <returns>A secure random password string.</returns>
        public static string GenerateRandomPassword(int length = 16, bool includeSpecialChars = true)
        {
            if (length < 8) length = 8;

            var charPool = UpperChars + LowerChars + DigitChars + (includeSpecialChars ? SpecialChars : string.Empty);
            var result = new StringBuilder(length);

            // Ensure at least one of each category
            result.Append(UpperChars[RandomNumberGenerator.GetInt32(UpperChars.Length)]);
            result.Append(LowerChars[RandomNumberGenerator.GetInt32(LowerChars.Length)]);
            result.Append(DigitChars[RandomNumberGenerator.GetInt32(DigitChars.Length)]);
            if (includeSpecialChars)
            {
                result.Append(SpecialChars[RandomNumberGenerator.GetInt32(SpecialChars.Length)]);
            }

            // Fill the remaining length randomly
            while (result.Length < length)
            {
                result.Append(charPool[RandomNumberGenerator.GetInt32(charPool.Length)]);
            }

            // Shuffle chars using Fisher-Yates
            var chars = result.ToString().ToCharArray();
            for (int i = chars.Length - 1; i > 0; i--)
            {
                int j = RandomNumberGenerator.GetInt32(i + 1);
                (chars[i], chars[j]) = (chars[j], chars[i]);
            }

            return new string(chars);
        }
    }
}
