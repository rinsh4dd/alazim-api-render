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
        private readonly Mock<ICustomizationOptionService> _optionServiceMock = new();
        private readonly Mock<ITemplateGroupMappingService> _mappingServiceMock = new();
        private readonly CustomizationController _controller;

        public CustomizationControllerTests()
        {
            _controller = new CustomizationController(
                _templateServiceMock.Object,
                _groupServiceMock.Object,
                _optionServiceMock.Object,
                _mappingServiceMock.Object)
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

            var actionResult = await _controller.SaveCustomizationTemplate(request, CancellationToken.None);

            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<CustomizationTemplateDto>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal("CTP0000000001", response.Data?.DocNo);
        }

        [Fact]
        public async Task GetCustomizationTemplates_WhenCalled_ReturnsOkObjectResult()
        {
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

            var actionResult = await _controller.GetCustomizationTemplates(query, CancellationToken.None);

            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<PagedResponse<List<CustomizationTemplateDto>>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal(1, response.TotalRecords);
        }

        [Fact]
        public async Task SaveCustomizationGroup_WhenCalled_ReturnsOkObjectResult()
        {
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

            var actionResult = await _controller.SaveCustomizationGroup(request, CancellationToken.None);

            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<CustomizationGroupDto>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal("CUT_TYPE", response.Data?.GroupCode);
        }

        [Fact]
        public async Task SaveCustomizationOption_WhenCalled_ReturnsOkObjectResult()
        {
            var request = new SaveCustomizationOptionDto
            {
                Mode = Mode.ADD,
                CustomizationGroupId = 1,
                OptionCode = "CURRY_CUT",
                OptionNameEn = "Curry Cut",
                OptionNameAr = "تقطيع كاري"
            };

            var apiResponse = ApiResponse<CustomizationOptionDto>.SuccessResponse(
                new CustomizationOptionDto { CustomizationOptionId = 1, OptionCode = "CURRY_CUT" },
                "Customization option created successfully.");

            _optionServiceMock.Setup(s => s.SaveCustomizationOptionAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(apiResponse);

            var actionResult = await _controller.SaveCustomizationOption(request, CancellationToken.None);

            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<CustomizationOptionDto>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal("CURRY_CUT", response.Data?.OptionCode);
        }

        [Fact]
        public async Task SaveTemplateGroupMapping_WhenCalled_ReturnsOkObjectResult()
        {
            var request = new SaveTemplateGroupMappingDto
            {
                CustomizationTemplateId = 1,
                GroupIds = new List<long> { 1, 2 }
            };

            var apiResponse = ApiResponse<List<TemplateGroupMappingDto>>.SuccessResponse(
                new List<TemplateGroupMappingDto>
                {
                    new() { TemplateGroupMappingId = 1, CustomizationTemplateId = 1, CustomizationGroupId = 1 },
                    new() { TemplateGroupMappingId = 2, CustomizationTemplateId = 1, CustomizationGroupId = 2 }
                },
                "Template group mappings updated successfully.");

            _mappingServiceMock.Setup(s => s.SaveTemplateGroupMappingAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(apiResponse);

            var actionResult = await _controller.SaveTemplateGroupMapping(request, CancellationToken.None);

            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<List<TemplateGroupMappingDto>>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal(2, response.Data?.Count);
        }

        [Fact]
        public async Task GetTemplateGroupMappings_WhenCalled_ReturnsOkObjectResult()
        {
            var query = new GetTemplateGroupMappingsQueryDto { PageNumber = 1, PageSize = 10, CustomizationTemplateId = 1 };
            var pagedResponse = new PagedResponse<List<TemplateGroupMappingDto>>
            {
                Success = true,
                Message = "Template group mappings retrieved successfully.",
                Data = new List<TemplateGroupMappingDto>
                {
                    new() { TemplateGroupMappingId = 1, CustomizationTemplateId = 1, CustomizationGroupId = 1 }
                },
                PageNumber = 1,
                PageSize = 10,
                TotalRecords = 1
            };

            _mappingServiceMock.Setup(s => s.GetTemplateGroupMappingsAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync(pagedResponse);

            var actionResult = await _controller.GetTemplateGroupMappings(query, CancellationToken.None);

            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<PagedResponse<List<TemplateGroupMappingDto>>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal(1, response.TotalRecords);
        }
    }
}
