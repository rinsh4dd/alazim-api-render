using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Infrastructure.Services.Cart;
using Moq;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class CartCalculationServiceTests
    {
        private readonly Mock<ICartRepository> _cartRepositoryMock;
        private readonly CartCalculationService _service;

        public CartCalculationServiceTests()
        {
            _cartRepositoryMock = new Mock<ICartRepository>();
            _service = new CartCalculationService(_cartRepositoryMock.Object);
        }

        [Fact]
        public async Task CalculateActiveCartAsync_PercentageDiscount_CalculatesCorrectly()
        {
            // Arrange
            long userId = 1;
            dynamic header = new System.Dynamic.ExpandoObject();
            header.CART_ID = 100L;
            header.CART_STATUS = "ACTIVE";
            header.COUPON_ID = 5L;
            header.COUPON_CODE = "SAVE10";
            header.COUPON_NAME = "10% Off";
            header.DISCOUNT_TYPE = "PERCENTAGE";
            header.DISCOUNT_VALUE = 10.00m;
            header.MAX_DISCOUNT_AMOUNT = null;
            header.MINIMUM_ORDER_AMOUNT = 50.00m;

            dynamic item1 = new System.Dynamic.ExpandoObject();
            item1.CART_ITEM_ID = 1L;
            item1.PRODUCT_ID = 10L;
            item1.PRODUCT_NAME_EN = "Chicken Breast";
            item1.PRODUCT_NAME_AR = "صدر دجاج";
            item1.PRODUCT_IMAGE = null;
            item1.UNIT_DESCRIPTION = "1 KG";
            item1.BASE_PRICE = 100.00m;
            item1.QUANTITY = 2; // Subtotal = 200.00 AED
            item1.SPECIAL_INSTRUCTIONS = null;

            var items = new List<dynamic> { item1 };
            var options = new List<dynamic>();

            _cartRepositoryMock
                .Setup(r => r.GetCartRawDataAsync(userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync((header, items, options));

            // Act
            var result = await _service.CalculateActiveCartAsync(userId);

            // Assert
            Assert.NotNull(result);
            Assert.Equal(200.00m, result.Summary.Subtotal);
            Assert.Equal(20.00m, result.Summary.DiscountAmount); // 10% of 200 = 20 AED
            Assert.Equal(180.00m, result.Summary.DiscountedSubtotal);
            Assert.Equal(180.00m, result.Summary.GrandTotal);
            Assert.NotNull(result.AppliedCoupon);
            Assert.Equal("SAVE10", result.AppliedCoupon.CouponCode);
        }

        [Fact]
        public async Task CalculateActiveCartAsync_PercentageDiscount_CappedByMaxDiscountAmount()
        {
            // Arrange
            long userId = 1;
            dynamic header = new System.Dynamic.ExpandoObject();
            header.CART_ID = 100L;
            header.CART_STATUS = "ACTIVE";
            header.COUPON_ID = 5L;
            header.COUPON_CODE = "BIG50";
            header.COUPON_NAME = "50% Off Capped";
            header.DISCOUNT_TYPE = "PERCENTAGE";
            header.DISCOUNT_VALUE = 50.00m;
            header.MAX_DISCOUNT_AMOUNT = 25.00m; // Max cap 25 AED
            header.MINIMUM_ORDER_AMOUNT = 50.00m;

            dynamic item1 = new System.Dynamic.ExpandoObject();
            item1.CART_ITEM_ID = 1L;
            item1.PRODUCT_ID = 10L;
            item1.PRODUCT_NAME_EN = "Wagyu Beef";
            item1.PRODUCT_NAME_AR = "لحم واجيو";
            item1.PRODUCT_IMAGE = null;
            item1.UNIT_DESCRIPTION = "1 KG";
            item1.BASE_PRICE = 200.00m;
            item1.QUANTITY = 1; // Subtotal = 200.00 AED (50% is 100 AED, but capped at 25 AED)
            item1.SPECIAL_INSTRUCTIONS = null;

            var items = new List<dynamic> { item1 };
            var options = new List<dynamic>();

            _cartRepositoryMock
                .Setup(r => r.GetCartRawDataAsync(userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync((header, items, options));

            // Act
            var result = await _service.CalculateActiveCartAsync(userId);

            // Assert
            Assert.Equal(200.00m, result.Summary.Subtotal);
            Assert.Equal(25.00m, result.Summary.DiscountAmount); // Capped at 25.00 AED
            Assert.Equal(175.00m, result.Summary.GrandTotal);
        }

        [Fact]
        public async Task CalculateActiveCartAsync_FixedDiscount_CalculatesCorrectly()
        {
            // Arrange
            long userId = 1;
            dynamic header = new System.Dynamic.ExpandoObject();
            header.CART_ID = 100L;
            header.CART_STATUS = "ACTIVE";
            header.COUPON_ID = 5L;
            header.COUPON_CODE = "FLAT30";
            header.COUPON_NAME = "30 AED Off";
            header.DISCOUNT_TYPE = "FIXED_AMOUNT";
            header.DISCOUNT_VALUE = 30.00m;
            header.MAX_DISCOUNT_AMOUNT = null;
            header.MINIMUM_ORDER_AMOUNT = 50.00m;

            dynamic item1 = new System.Dynamic.ExpandoObject();
            item1.CART_ITEM_ID = 1L;
            item1.PRODUCT_ID = 10L;
            item1.PRODUCT_NAME_EN = "Lamb Chops";
            item1.PRODUCT_NAME_AR = "ريش غنم";
            item1.PRODUCT_IMAGE = null;
            item1.UNIT_DESCRIPTION = "1 KG";
            item1.BASE_PRICE = 150.00m;
            item1.QUANTITY = 1; // Subtotal = 150.00 AED
            item1.SPECIAL_INSTRUCTIONS = null;

            var items = new List<dynamic> { item1 };
            var options = new List<dynamic>();

            _cartRepositoryMock
                .Setup(r => r.GetCartRawDataAsync(userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync((header, items, options));

            // Act
            var result = await _service.CalculateActiveCartAsync(userId);

            // Assert
            Assert.Equal(150.00m, result.Summary.Subtotal);
            Assert.Equal(30.00m, result.Summary.DiscountAmount);
            Assert.Equal(120.00m, result.Summary.GrandTotal);
        }

        [Fact]
        public async Task CalculateActiveCartAsync_SubtotalBelowMinOrderAmount_DoesNotApplyDiscount()
        {
            // Arrange
            long userId = 1;
            dynamic header = new System.Dynamic.ExpandoObject();
            header.CART_ID = 100L;
            header.CART_STATUS = "ACTIVE";
            header.COUPON_ID = 5L;
            header.COUPON_CODE = "MIN100";
            header.COUPON_NAME = "10% Off Min 100 AED";
            header.DISCOUNT_TYPE = "PERCENTAGE";
            header.DISCOUNT_VALUE = 10.00m;
            header.MAX_DISCOUNT_AMOUNT = null;
            header.MINIMUM_ORDER_AMOUNT = 100.00m;

            dynamic item1 = new System.Dynamic.ExpandoObject();
            item1.CART_ITEM_ID = 1L;
            item1.PRODUCT_ID = 10L;
            item1.PRODUCT_NAME_EN = "Minced Meat";
            item1.PRODUCT_NAME_AR = "لحم مفروم";
            item1.PRODUCT_IMAGE = null;
            item1.UNIT_DESCRIPTION = "1 KG";
            item1.BASE_PRICE = 40.00m;
            item1.QUANTITY = 1; // Subtotal = 40.00 AED (Below min 100 AED)
            item1.SPECIAL_INSTRUCTIONS = null;

            var items = new List<dynamic> { item1 };
            var options = new List<dynamic>();

            _cartRepositoryMock
                .Setup(r => r.GetCartRawDataAsync(userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync((header, items, options));

            // Act
            var result = await _service.CalculateActiveCartAsync(userId);

            // Assert
            Assert.Equal(40.00m, result.Summary.Subtotal);
            Assert.Equal(0.00m, result.Summary.DiscountAmount); // No discount
            Assert.Equal(40.00m, result.Summary.GrandTotal);
            Assert.Null(result.AppliedCoupon);
        }
    }
}
