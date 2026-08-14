using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Xunit;
using MeatDelivery.Api.Controllers;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Customer;
using MeatDelivery.Application.Interfaces.Customer;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.UnitTests.Controllers
{
    public class CustomerControllerTests
    {
        private readonly Mock<ICustomerService> _mockCustomerService;
        private readonly CustomerController _controller;

        public CustomerControllerTests()
        {
            _mockCustomerService = new Mock<ICustomerService>();
            _controller = new CustomerController(_mockCustomerService.Object);

            // Mock HttpContext with authenticated User claims
            var userClaims = new ClaimsPrincipal(new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, "1001"),
                new Claim(ClaimTypes.MobilePhone, "+971501234567")
            }, "TestAuth"));

            var httpContext = new DefaultHttpContext
            {
                User = userClaims
            };

            _controller.ControllerContext = new ControllerContext
            {
                HttpContext = httpContext
            };
        }

        [Fact]
        public async Task GetProfile_WhenCalled_ReturnsOkWithCustomerProfile()
        {
            // Arrange
            long userId = 1001;
            var fakeProfile = new CustomerProfileDto
            {
                UserId = userId,
                FirstName = "Rashid",
                LastName = "Khan",
                EligibleForOrder = true,
                IsProfileCompleted = true
            };

            var fakeResponse = ApiResponse<CustomerProfileDto>.SuccessResponse(fakeProfile);

            _mockCustomerService
                .Setup(s => s.GetCustomerProfileAsync(userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(fakeResponse);

            // Act
            var actionResult = await _controller.GetProfile(CancellationToken.None);

            // Assert
            var okResult = actionResult.Should().BeOfType<OkObjectResult>().Subject;
            var response = okResult.Value.Should().BeOfType<ApiResponse<CustomerProfileDto>>().Subject;
            response.Success.Should().BeTrue();
            response.Data.FirstName.Should().Be("Rashid");
            response.Data.EligibleForOrder.Should().BeTrue();
        }

        [Fact]
        public async Task SaveCustomerProfile_WhenCalled_ReturnsOkWithUpdatedProfile()
        {
            // Arrange
            long userId = 1001;
            var request = new UpdateCustomerProfileDto
            {
                FirstName = "Rashid",
                LastName = "Khan",
                Email = "rashid@example.com"
            };

            var fakeProfile = new CustomerProfileDto
            {
                UserId = userId,
                FirstName = "Rashid",
                LastName = "Khan",
                Email = "rashid@example.com",
                EligibleForOrder = true,
                IsProfileCompleted = true
            };

            var fakeResponse = ApiResponse<CustomerProfileDto>.SuccessResponse(fakeProfile, "Profile updated successfully");

            _mockCustomerService
                .Setup(s => s.UpdateCustomerProfileAsync(request, userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(fakeResponse);

            // Act
            var actionResult = await _controller.SaveCustomerProfile(request, CancellationToken.None);

            // Assert
            var okResult = actionResult.Should().BeOfType<OkObjectResult>().Subject;
            var response = okResult.Value.Should().BeOfType<ApiResponse<CustomerProfileDto>>().Subject;
            response.Success.Should().BeTrue();
            response.Data.EligibleForOrder.Should().BeTrue();
        }

        [Fact]
        public async Task GetCustomerAddress_WhenCalled_ReturnsOkWithAddressesList()
        {
            // Arrange
            long userId = 1001;
            var query = new GetCustomerAddressQueryDto();
            var addressList = new List<CustomerAddressDto>
            {
                new() { AddressId = 1, BuildingName = "Tower A", City = "Dubai", IsDefault = true }
            };

            var fakeResponse = ApiResponse<List<CustomerAddressDto>>.SuccessResponse(addressList);

            _mockCustomerService
                .Setup(s => s.GetCustomerAddressAsync(query, userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(fakeResponse);

            // Act
            var actionResult = await _controller.GetCustomerAddress(query, CancellationToken.None);

            // Assert
            var okResult = actionResult.Should().BeOfType<OkObjectResult>().Subject;
            var response = okResult.Value.Should().BeOfType<ApiResponse<List<CustomerAddressDto>>>().Subject;
            response.Success.Should().BeTrue();
            response.Data.Should().HaveCount(1);
        }
    }
}
