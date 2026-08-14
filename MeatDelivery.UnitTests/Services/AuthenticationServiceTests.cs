using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.Extensions.Options;
using Moq;
using Xunit;
using MeatDelivery.Application.DTOs.Auth;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;
using MeatDelivery.Infrastructure.Configurations;
using MeatDelivery.Infrastructure.Services.Authentication;

namespace MeatDelivery.UnitTests.Services
{
    public class AuthenticationServiceTests
    {
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<IOtpVerificationRepository> _mockOtpRepo;
        private readonly Mock<IUserRegistrationRepository> _mockUserRegRepo;
        private readonly Mock<IUserSessionRepository> _mockSessionRepo;
        private readonly Mock<ITokenService> _mockTokenService;
        private readonly Mock<IOtpService> _mockOtpService;
        private readonly IOptions<JwtSettings> _jwtOptions;
        private readonly AuthenticationService _sut;

        public AuthenticationServiceTests()
        {
            _mockUserRepo = new Mock<IUserRepository>();
            _mockOtpRepo = new Mock<IOtpVerificationRepository>();
            _mockUserRegRepo = new Mock<IUserRegistrationRepository>();
            _mockSessionRepo = new Mock<IUserSessionRepository>();
            _mockTokenService = new Mock<ITokenService>();
            _mockOtpService = new Mock<IOtpService>();

            _jwtOptions = Options.Create(new JwtSettings
            {
                SecretKey = "supersecretkey12345678901234567890123456",
                Issuer = "MeatDelivery",
                Audience = "MeatDeliveryApp",
                AccessTokenExpiryMinutes = 60,
                RefreshTokenExpiryDays = 30
            });

            _sut = new AuthenticationService(
                _mockUserRepo.Object,
                _mockOtpRepo.Object,
                _mockUserRegRepo.Object,
                _mockSessionRepo.Object,
                _mockTokenService.Object,
                _mockOtpService.Object,
                _jwtOptions);
        }

        [Fact]
        public async Task SendOtpAsync_WhenSuccessful_ReturnsSuccessResponseWithOtpDetails()
        {
            // Arrange
            var request = new SendOtpRequestDto
            {
                CountryCode = "+971",
                MobileNumber = "501234567"
            };

            string fakeCode = "123456";
            string fakeHash = "hashed_code_xyz";
            var fakeResult = new CreateOtpVerificationResult
            {
                IsSuccess = true,
                Message = "OTP sent successfully.",
                Interval = 60,
                ChallengeId = Guid.NewGuid()
            };

            _mockOtpService.Setup(s => s.GenerateOtpCode()).Returns(fakeCode);
            _mockOtpService.Setup(s => s.HashOtpCode(fakeCode, request.CountryCode, request.MobileNumber)).Returns(fakeHash);

            _mockOtpRepo.Setup(r => r.CreateOtpVerificationAsync(
                request.CountryCode,
                request.MobileNumber,
                fakeHash,
                "AUTHENTICATION",
                It.IsAny<DateTime>(),
                5,
                It.IsAny<Guid?>()))
            .ReturnsAsync(fakeResult);

            // Act
            var result = await _sut.SendOtpAsync(request);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeTrue();
            result.Data.Should().NotBeNull();
            result.Data!.CountryCode.Should().Be("+971");
            result.Data.MobileNumber.Should().Be("501234567");
            result.Data.DevOtpCode.Should().Be(fakeCode);
            result.Message.Should().Be("OTP sent successfully.");
        }

        [Fact]
        public async Task SendOtpAsync_WhenRepoFails_ReturnsFailureResponse()
        {
            // Arrange
            var request = new SendOtpRequestDto
            {
                CountryCode = "+971",
                MobileNumber = "501234567"
            };

            var fakeResult = new CreateOtpVerificationResult
            {
                IsSuccess = false,
                Message = "Too many OTP requests. Please wait.",
                Interval = 120,
                StatusCode = 429
            };

            _mockOtpService.Setup(s => s.GenerateOtpCode()).Returns("123456");
            _mockOtpService.Setup(s => s.HashOtpCode(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>())).Returns("hash");

            _mockOtpRepo.Setup(r => r.CreateOtpVerificationAsync(
                It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(),
                It.IsAny<DateTime>(), It.IsAny<int>(), It.IsAny<Guid?>()))
            .ReturnsAsync(fakeResult);

            // Act
            var result = await _sut.SendOtpAsync(request);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeFalse();
            result.Status.Should().Be(429);
            result.Message.Should().Be("Too many OTP requests. Please wait.");
        }

        [Fact]
        public async Task AuthenticateWithOtpAsync_WhenValid_ReturnsAuthTokenResponseDto()
        {
            // Arrange
            var request = new VerifyOtpRequestDto
            {
                CountryCode = "+971",
                MobileNumber = "501234567",
                OtpCode = "123456",
                ChallengeId = Guid.NewGuid()
            };

            string fakeOtpHash = "hashed_otp";
            string fakeRefreshToken = "raw_refresh_token_123";
            string fakeRefreshTokenHash = "hashed_refresh_token_123";
            string fakeAccessToken = "jwt_access_token_abc";

            var regResult = new CustomerRegistrationResult
            {
                UserId = 1001,
                DocType = "CUS1",
                DocNo = "CUS1-0001",
                SessionId = 500,
                FirstName = "Rashid",
                LastName = "Khan",
                FullName = "Rashid Khan",
                EligibleForOrder = true,
                IsProfileCompleted = true,
                IsNewUser = false
            };

            _mockOtpService.Setup(s => s.HashOtpCode("123456", "+971", "501234567")).Returns(fakeOtpHash);
            _mockTokenService.Setup(t => t.GenerateRefreshToken()).Returns(fakeRefreshToken);
            _mockTokenService.Setup(t => t.HashRefreshToken(fakeRefreshToken)).Returns(fakeRefreshTokenHash);

            _mockUserRegRepo.Setup(r => r.VerifyOtpAndRegisterCustomerAsync(
                "+971", "501234567", fakeOtpHash, null, "EN", fakeRefreshTokenHash,
                It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(),
                It.IsAny<DateTime>(), 5, request.ChallengeId))
            .ReturnsAsync(regResult);

            _mockTokenService.Setup(t => t.GenerateAccessTokenForUser(
                1001, "Rashid Khan", "+971", "501234567", It.IsAny<IEnumerable<string>?>(), 500))
            .Returns(fakeAccessToken);

            // Act
            var result = await _sut.AuthenticateWithOtpAsync(request, "127.0.0.1", "device1", "Android");

            // Assert
            result.Should().NotBeNull();
            result.UserId.Should().Be(1001);
            result.DocNo.Should().Be("CUS1-0001");
            result.AccessToken.Should().Be(fakeAccessToken);
            result.RefreshToken.Should().Be(fakeRefreshToken);
            result.EligibleForOrder.Should().BeTrue();
            result.IsProfileCompleted.Should().BeTrue();
        }
    }
}
