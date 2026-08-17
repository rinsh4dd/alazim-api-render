using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using MeatDelivery.Application.Common.Security;

namespace MeatDelivery.Infrastructure.Security
{
    /// <summary>
    /// Cryptographically secure random password generator implementing IPasswordGenerator.
    /// </summary>
    public sealed class SecurePasswordGenerator : IPasswordGenerator
    {
        private const string Upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
        private const string Lower = "abcdefghijkmnopqrstuvwxyz";
        private const string Digits = "23456789";
        private const string Special = "!@#$%^&*()-_=+[]{}";

        public string Generate(int length = 16)
        {
            if (length < 12)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(length),
                    "Generated passwords must be at least 12 characters.");
            }

            var characters = new List<char>(length)
            {
                GetRandom(Upper),
                GetRandom(Lower),
                GetRandom(Digits),
                GetRandom(Special)
            };

            var pool = Upper + Lower + Digits + Special;

            while (characters.Count < length)
            {
                characters.Add(GetRandom(pool));
            }

            Shuffle(characters);

            return new string(characters.ToArray());
        }

        private static char GetRandom(string characters)
        {
            return characters[RandomNumberGenerator.GetInt32(characters.Length)];
        }

        private static void Shuffle(IList<char> values)
        {
            for (var i = values.Count - 1; i > 0; i--)
            {
                var j = RandomNumberGenerator.GetInt32(i + 1);
                (values[i], values[j]) = (values[j], values[i]);
            }
        }
    }
}
