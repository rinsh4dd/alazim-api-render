using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Moq;
using Xunit;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Customer;
using MeatDelivery.Application.Interfaces.Repositories.Customer;
using MeatDelivery.Domain.Entities.Addresses;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Services.Customer;

namespace MeatDelivery.UnitTests.Services
{
    public class CustomerServiceTests
    {
        private readonly Mock<ICustomerRepository> _mockCustomerRepo;
        private readonly CustomerService _sut; // System Under Test

        public CustomerServiceTests()
        {
            _mockCustomerRepo = new Mock<ICustomerRepository>();
            _sut = new CustomerService(_mockCustomerRepo.Object);
        }

        [Fact]
        public async Task GetCustomerProfileAsync_WhenUserExists_ReturnsSuccessResponse()
        {
            // Arrange
            long userId = 1001;
            var fakeProfile = new CustomerProfileDto
            {
                UserId = userId,
                CountryCode = "+971",
                MobileNumber = "501234567",
                FirstName = "Rashid",
                LastName = "Khan",
                FullName = "Rashid Khan",
                EligibleForOrder = true,
                IsProfileCompleted = true
            };

            _mockCustomerRepo
                .Setup(r => r.GetCustomerProfileAsync(userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(fakeProfile);

            // Act
            var result = await _sut.GetCustomerProfileAsync(userId);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeTrue();
            result.Data.Should().NotBeNull();
            result.Data.FirstName.Should().Be("Rashid");
            result.Data.EligibleForOrder.Should().BeTrue();
            result.Data.IsProfileCompleted.Should().BeTrue();
        }

        [Fact]
        public async Task GetCustomerProfileAsync_WhenUserDoesNotExist_Returns404Failure()
        {
            // Arrange
            long nonExistentUserId = 9999;
            _mockCustomerRepo
                .Setup(r => r.GetCustomerProfileAsync(nonExistentUserId, It.IsAny<CancellationToken>()))
                .ReturnsAsync((CustomerProfileDto?)null);

            // Act
            var result = await _sut.GetCustomerProfileAsync(nonExistentUserId);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeFalse();
            result.Status.Should().Be(404);
            result.Message.Should().Be("Customer profile not found.");
        }

        [Fact]
        public async Task UpdateCustomerProfileAsync_WhenValid_ReturnsSuccessWithUpdatedProfile()
        {
            // Arrange
            long userId = 1001;
            var request = new UpdateCustomerProfileDto
            {
                FirstName = "Rashid",
                LastName = "Khan",
                Email = "rashid@example.com",
                Dob = new DateTime(1995, 5, 10),
                Gender = Gender.MALE
            };

            var updatedProfile = new CustomerProfileDto
            {
                UserId = userId,
                FirstName = "Rashid",
                LastName = "Khan",
                Email = "rashid@example.com",
                EligibleForOrder = true,
                IsProfileCompleted = true
            };

            _mockCustomerRepo
                .Setup(r => r.UpdateCustomerProfileAsync(request, userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(updatedProfile);

            // Act
            var result = await _sut.UpdateCustomerProfileAsync(request, userId);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeTrue();
            result.Data.EligibleForOrder.Should().BeTrue();
            result.Message.Should().Be("Profile updated successfully");
        }

        [Fact]
        public async Task SaveCustomerAddressAsync_WhenAddingAddress_ReturnsSuccessWithAddressId()
        {
            // Arrange
            long userId = 1001;
            long newAddressId = 55;
            var request = new SaveCustomerAddressDto
            {
                Mode = AddressMode.ADD,
                BuildingName = "Al Azima Tower",
                VillaOrFlatNo = "A-402",
                Street = "Sheikh Zayed Road",
                Area = "Downtown",
                City = "Dubai",
                Emirate = "Dubai"
            };

            _mockCustomerRepo
                .Setup(r => r.SaveCustomerAddressAsync(request, userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(newAddressId);

            // Act
            var result = await _sut.SaveCustomerAddressAsync(request, userId);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeTrue();
            result.Message.Should().Be("Address added successfully.");
        }

        [Fact]
        public async Task SetDefaultCustomerAddressAsync_WhenValid_ReturnsSuccess()
        {
            // Arrange
            long userId = 1001;
            long addressId = 55;

            _mockCustomerRepo
                .Setup(r => r.SetDefaultCustomerAddressAsync(addressId, userId, It.IsAny<CancellationToken>()))
                .ReturnsAsync(true);

            // Act
            var result = await _sut.SetDefaultCustomerAddressAsync(addressId, userId);

            // Assert
            result.Should().NotBeNull();
            result.Success.Should().BeTrue();
            result.Message.Should().Be("Default delivery address updated successfully.");
        }
    }
}
