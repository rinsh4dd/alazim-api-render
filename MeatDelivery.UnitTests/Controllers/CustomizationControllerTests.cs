using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using MeatDelivery.Api.Controllers.V1.Customization;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;
using Xunit;

namespace MeatDelivery.UnitTests.Controllers
{
    public class CustomizationControllerTests
    {
        private readonly Mock<ICustomizationTemplateService> _templateServiceMock = new();
        private readonly Mock<ICustomizationGroupService> _groupServiceMock = new();
        private readonly CustomizationController _controller;

        public CustomizationControllerTests()
        {
            _controller = new CustomizationController(
                _templateServiceMock.Object,
                _groupServiceMock.Object)
            {
                ControllerContext = new ControllerContext
                {
                    HttpContext = new DefaultHttpContext()
                }
            };
        }

        [Fact]
        public async Task SaveCustomizationTemplate_WhenCalled_ReturnsOkObjectResult()
        {
            // Arrange
            var request = new SaveCustomizationTemplateDto
            {
                Mode = Mode.ADD,
                TemplateNameEn = "Chicken Customization",
                TemplateNameAr = "تخصيص الدجاج"
            };

            var apiResponse = ApiResponse<CustomizationTemplateDto>.SuccessResponse(
                new CustomizationTemplateDto { CustomizationTemplateId = 1, DocNo = "CTP0000000001" },
                "Customization template created successfully.");

            _templateServiceMock.Setup(s => s.SaveCustomizationTemplateAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(apiResponse);

            // Act
            var actionResult = await _controller.SaveCustomizationTemplate(request, CancellationToken.None);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<CustomizationTemplateDto>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal("CTP0000000001", response.Data?.DocNo);
        }

        [Fact]
        public async Task GetCustomizationTemplates_WhenCalled_ReturnsOkObjectResult()
        {
            // Arrange
            var query = new GetCustomizationTemplatesQueryDto { PageNumber = 1, PageSize = 10, Search = "Chicken" };
            var pagedResponse = new PagedResponse<List<CustomizationTemplateDto>>
            {
                Success = true,
                Message = "Customization templates retrieved successfully.",
                Data = new List<CustomizationTemplateDto>
                {
                    new() { CustomizationTemplateId = 1, DocNo = "CTP0000000001", TemplateNameEn = "Chicken Customization" }
                },
                PageNumber = 1,
                PageSize = 10,
                TotalRecords = 1
            };

            _templateServiceMock.Setup(s => s.GetCustomizationTemplatesAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync(pagedResponse);

            // Act
            var actionResult = await _controller.GetCustomizationTemplates(query, CancellationToken.None);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<PagedResponse<List<CustomizationTemplateDto>>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal(1, response.TotalRecords);
        }

        [Fact]
        public async Task SaveCustomizationGroup_WhenCalled_ReturnsOkObjectResult()
        {
            // Arrange
            var request = new SaveCustomizationGroupDto
            {
                Mode = Mode.ADD,
                GroupCode = "CUT_TYPE",
                GroupNameEn = "Cut Type",
                GroupNameAr = "نوع التقطيع"
            };

            var apiResponse = ApiResponse<CustomizationGroupDto>.SuccessResponse(
                new CustomizationGroupDto { CustomizationGroupId = 1, GroupCode = "CUT_TYPE" },
                "Customization group created successfully.");

            _groupServiceMock.Setup(s => s.SaveCustomizationGroupAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(apiResponse);

            // Act
            var actionResult = await _controller.SaveCustomizationGroup(request, CancellationToken.None);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<CustomizationGroupDto>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal("CUT_TYPE", response.Data?.GroupCode);
        }

        [Fact]
        public async Task GetCustomizationGroups_WhenCalled_ReturnsOkObjectResult()
        {
            // Arrange
            var query = new GetCustomizationGroupsQueryDto { PageNumber = 1, PageSize = 10, Search = "CUT" };
            var pagedResponse = new PagedResponse<List<CustomizationGroupDto>>
            {
                Success = true,
                Message = "Customization groups retrieved successfully.",
                Data = new List<CustomizationGroupDto>
                {
                    new() { CustomizationGroupId = 1, GroupCode = "CUT_TYPE", GroupNameEn = "Cut Type" }
                },
                PageNumber = 1,
                PageSize = 10,
                TotalRecords = 1
            };

            _groupServiceMock.Setup(s => s.GetCustomizationGroupsAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync(pagedResponse);

            // Act
            var actionResult = await _controller.GetCustomizationGroups(query, CancellationToken.None);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<PagedResponse<List<CustomizationGroupDto>>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal(1, response.TotalRecords);
        }
    }
}
