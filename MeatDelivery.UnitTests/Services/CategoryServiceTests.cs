using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using Moq;
using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Application.Interfaces.Repositories.Category;
using MeatDelivery.Application.Validators.Category;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Services.Catalog;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class CategoryServiceTests
    {
        private readonly Mock<ICategoryRepository> _categoryRepoMock = new();
        private readonly SaveCategoryDtoValidator _saveValidator = new();
        private readonly GetCategoriesQueryDtoValidator _getValidator = new();
        private readonly CategoryService _service;

        public CategoryServiceTests()
        {
            _service = new CategoryService(
                _categoryRepoMock.Object,
                _saveValidator,
                _getValidator);
        }

        [Fact]
        public async Task SaveCategoryAsync_AddMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCategoryDto
            {
                Mode = Mode.ADD,
                CategoryNameEn = "Fresh Meat",
                CategoryNameAr = "لحم طازج",
                CategoryCode = "FRESH_MEAT",
                DisplayOrder = 1,
                IsActive = true
            };

            var expectedResponse = new CategoryDto
            {
                CategoryId = 1,
                CategoryCode = "FRESH_MEAT",
                CategoryNameEn = "Fresh Meat",
                CategoryNameAr = "لحم طازج",
                DisplayOrder = 1,
                IsActive = true
            };

            _categoryRepoMock.Setup(r => r.SaveCategoryAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _service.SaveCategoryAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("Fresh Meat", result.Data?.CategoryNameEn);
            Assert.Equal("Category created successfully.", result.Message);
        }

        [Fact]
        public async Task SaveCategoryAsync_AddMode_MissingName_ReturnsValidationFailure()
        {
            // Arrange
            var request = new SaveCategoryDto
            {
                Mode = Mode.ADD,
                CategoryNameEn = "" // Empty name should fail validation
            };

            // Act
            var result = await _service.SaveCategoryAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
            Assert.Contains(result.Errors, e => e.Contains("English category name is required", System.StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task SaveCategoryAsync_EditMode_InvalidId_ReturnsValidationFailure()
        {
            // Arrange
            var request = new SaveCategoryDto
            {
                Mode = Mode.EDIT,
                CategoryId = 0 // Invalid ID
            };

            // Act
            var result = await _service.SaveCategoryAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
            Assert.Contains(result.Errors, e => e.Contains("Valid CategoryId is required", System.StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task GetCategoriesAsync_ValidQuery_ReturnsPagedResult()
        {
            // Arrange
            var query = new GetCategoriesQueryDto { PageNumber = 1, PageSize = 10, SearchTerm = "Meat" };
            var list = new List<CategoryDto>
            {
                new() { CategoryId = 1, CategoryCode = "FRESH_MEAT", CategoryNameEn = "Fresh Meat" }
            };

            _categoryRepoMock.Setup(r => r.GetCategoriesAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync((list, 1));

            // Act
            var result = await _service.GetCategoriesAsync(query);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal(1, result.TotalRecords);
            Assert.Equal(1, result.PageNumber);
            Assert.Equal(10, result.PageSize);
            Assert.Single(result.Data!);
            Assert.Equal("Fresh Meat", result.Data?[0].CategoryNameEn);
        }
    }
}
