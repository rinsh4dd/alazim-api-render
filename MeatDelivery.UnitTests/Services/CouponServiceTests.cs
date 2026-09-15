using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using FluentValidation.Results;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Application.Interfaces.Repositories.Coupon;
using MeatDelivery.Infrastructure.Services.Coupon;
using Microsoft.Extensions.Caching.Memory;
using Moq;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class CouponServiceTests
    {
        private readonly Mock<ICouponRepository> _couponRepositoryMock;
        private readonly Mock<ICartCalculationService> _cartCalculationServiceMock;
        private readonly Mock<IValidator<SaveCouponDto>> _saveCouponValidatorMock;
        private readonly Mock<IValidator<ApplyCouponDto>> _applyCouponValidatorMock;
        private readonly Mock<IMemoryCache> _cacheMock;

        private readonly CouponService _service;

        public CouponServiceTests()
        {
            _couponRepositoryMock = new Mock<ICouponRepository>();
            _cartCalculationServiceMock = new Mock<ICartCalculationService>();
            _saveCouponValidatorMock = new Mock<IValidator<SaveCouponDto>>();
            _applyCouponValidatorMock = new Mock<IValidator<ApplyCouponDto>>();
            _cacheMock = new Mock<IMemoryCache>();

            var cacheEntryMock = new Mock<ICacheEntry>();
            _cacheMock.Setup(m => m.CreateEntry(It.IsAny<object>())).Returns(cacheEntryMock.Object);

            _service = new CouponService(
                _couponRepositoryMock.Object,
                _cartCalculationServiceMock.Object,
                _saveCouponValidatorMock.Object,
                _applyCouponValidatorMock.Object,
                _cacheMock.Object
            );
        }

        [Fact]
        public async Task ApplyCouponAsync_ValidRequest_ReturnsSuccessResponse()
        {
            // Arrange
            long customerUserId = 101;
            var dto = new ApplyCouponDto { CouponCode = "PROMO10" };

            _applyCouponValidatorMock
                .Setup(v => v.ValidateAsync(dto, It.IsAny<CancellationToken>()))
                .ReturnsAsync(new ValidationResult());

            var summary = new CustomerCartSummaryDto
            {
                CartId = 1,
                AppliedCoupon = new AppliedCouponDto { CouponCode = "PROMO10", DiscountValue = 10.00m }
            };

            _cartCalculationServiceMock
                .Setup(c => c.CalculateActiveCartAsync(customerUserId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(summary);

            // Act
            var response = await _service.ApplyCouponAsync(customerUserId, dto);

            // Assert
            Assert.True(response.Success);
            Assert.Equal("Coupon code applied successfully.", response.Message);
            Assert.NotNull(response.Data);
            Assert.Equal("PROMO10", response.Data.AppliedCoupon?.CouponCode);

            _couponRepositoryMock.Verify(r => r.ApplyCouponAsync(customerUserId, "PROMO10", It.IsAny<CancellationToken>()), Times.Once);
        }

        [Fact]
        public async Task RemoveCouponAsync_ValidUser_ReturnsSuccessResponse()
        {
            // Arrange
            long customerUserId = 101;
            var summary = new CustomerCartSummaryDto { CartId = 1, AppliedCoupon = null };

            _cartCalculationServiceMock
                .Setup(c => c.CalculateActiveCartAsync(customerUserId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(summary);

            // Act
            var response = await _service.RemoveCouponAsync(customerUserId);

            // Assert
            Assert.True(response.Success);
            Assert.Equal("Coupon code removed successfully.", response.Message);

            _couponRepositoryMock.Verify(r => r.RemoveCouponAsync(customerUserId, It.IsAny<CancellationToken>()), Times.Once);
        }
    }
}
