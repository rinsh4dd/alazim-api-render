using System;
using System.Text;
using Microsoft.Extensions.Options;
using MeatDelivery.Application.Common.Security;

namespace MeatDelivery.Infrastructure.Security
{
    /// <summary>
    /// BCrypt implementation of IPasswordHasher using configurable work factor and OWASP security recommendations.
    /// </summary>
    public sealed class BcryptPasswordHasher : IPasswordHasher
    {
        private const int MaxBcryptInputBytes = 72;
        private readonly int _workFactor;

        public BcryptPasswordHasher(IOptions<PasswordHashingOptions> options)
        {
            _workFactor = options?.Value?.WorkFactor ?? 12;

            if (_workFactor is < 10 or > 31)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(options),
                    "BCrypt work factor must be between 10 and 31 (OWASP recommends >= 10).");
            }
        }

        public string Hash(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new ArgumentException("Password cannot be null or whitespace.", nameof(password));
            }

            var byteCount = Encoding.UTF8.GetByteCount(password);
            if (byteCount > MaxBcryptInputBytes)
            {
                throw new ArgumentException($"Password exceeds the BCrypt {MaxBcryptInputBytes}-byte UTF-8 limit.", nameof(password));
            }

            return BCrypt.Net.BCrypt.HashPassword(password, workFactor: _workFactor);
        }

        public bool Verify(string password, string passwordHash)
        {
            if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(passwordHash))
            {
                return false;
            }

            try
            {
                return BCrypt.Net.BCrypt.Verify(password, passwordHash);
            }
            catch
            {
                // Malformed/invalid stored hash. Authentication fails safely.
                return false;
            }
        }

        public bool NeedsRehash(string passwordHash)
        {
            if (string.IsNullOrWhiteSpace(passwordHash))
            {
                return true;
            }

            try
            {
                return BCrypt.Net.BCrypt.PasswordNeedsRehash(passwordHash, _workFactor);
            }
            catch
            {
                return true;
            }
        }
    }
}
