using System;
using Microsoft.Extensions.Options;
using MeatDelivery.Application.Common.Security;
using MeatDelivery.Infrastructure.Security;
using Xunit;

namespace MeatDelivery.UnitTests.Security
{
    public class PasswordSecurityTests
    {
        private readonly IPasswordHasher _hasher;
        private readonly IPasswordGenerator _generator;
        private readonly Xunit.Abstractions.ITestOutputHelper _output;

        public PasswordSecurityTests(Xunit.Abstractions.ITestOutputHelper output)
        {
            _output = output;
            var options = Options.Create(new PasswordHashingOptions { WorkFactor = 12 });
            _hasher = new BcryptPasswordHasher(options);
            _generator = new SecurePasswordGenerator();
        }

        [Fact]
        public void PrintSuperAdminHash()
        {
            var hash = _hasher.Hash("SuperAdmin@2026!");
            _output.WriteLine($"SUPER_ADMIN_HASH: {hash}");
            Assert.True(_hasher.Verify("SuperAdmin@2026!", hash));
        }

        [Fact]
        public void Hash_ValidPassword_ReturnsValidBcryptHash()
        {
            // Arrange
            var password = "SuperSecretAdminPassword123!";

            // Act
            var hash = _hasher.Hash(password);

            // Assert
            Assert.NotNull(hash);
            Assert.StartsWith("$2a$12$", hash);
        }

        [Fact]
        public void Verify_CorrectPassword_ReturnsTrue()
        {
            // Arrange
            var password = "AdminPassword@2026";
            var hash = _hasher.Hash(password);

            // Act
            var isValid = _hasher.Verify(password, hash);

            // Assert
            Assert.True(isValid);
        }

        [Fact]
        public void Verify_IncorrectPassword_ReturnsFalse()
        {
            // Arrange
            var password = "CorrectPassword123!";
            var wrongPassword = "WrongPassword456!";
            var hash = _hasher.Hash(password);

            // Act
            var isValid = _hasher.Verify(wrongPassword, hash);

            // Assert
            Assert.False(isValid);
        }

        [Theory]
        [InlineData(null, "someHash")]
        [InlineData("", "someHash")]
        [InlineData("password", null)]
        [InlineData("password", "")]
        [InlineData("password", "invalid_non_bcrypt_hash")]
        public void Verify_InvalidInputs_ReturnsFalse(string? password, string? hash)
        {
            // Act
            var isValid = _hasher.Verify(password!, hash!);

            // Assert
            Assert.False(isValid);
        }

        [Fact]
        public void Hash_PasswordExceeding72Bytes_ThrowsArgumentException()
        {
            // Arrange (73 UTF-8 bytes)
            var longPassword = new string('A', 73);

            // Act & Assert
            var ex = Assert.Throws<ArgumentException>(() => _hasher.Hash(longPassword));
            Assert.Contains("72-byte", ex.Message);
        }

        [Fact]
        public void Generate_DefaultLength_ReturnsValidSecurePassword()
        {
            // Act
            var password = _generator.Generate(16);

            // Assert
            Assert.Equal(16, password.Length);
            var hash = _hasher.Hash(password);
            Assert.True(_hasher.Verify(password, hash));
        }

        [Fact]
        public void Generate_LengthLessThan12_ThrowsArgumentOutOfRangeException()
        {
            // Act & Assert
            Assert.Throws<ArgumentOutOfRangeException>(() => _generator.Generate(10));
        }

        [Fact]
        public void NeedsRehash_CostLowerThanTarget_ReturnsTrue()
        {
            // Arrange (hash with cost 10)
            var lowerCostHasher = new BcryptPasswordHasher(Options.Create(new PasswordHashingOptions { WorkFactor = 10 }));
            var lowerCostHash = lowerCostHasher.Hash("testPassword");

            // Act (evaluating against cost 11 hasher)
            var needsRehash = _hasher.NeedsRehash(lowerCostHash);

            // Assert
            Assert.True(needsRehash);
        }
    }
}
