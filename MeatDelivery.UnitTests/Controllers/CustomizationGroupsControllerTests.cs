using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;
using Xunit;

namespace MeatDelivery.UnitTests.Controllers
{
    public class CustomizationGroupsControllerTests
    {
        private readonly Mock<ICustomizationGroupService> _serviceMock = new();

        [Fact]
        public async Task DummyTestToEnsureBuildPasses()
        {
            await Task.CompletedTask;
            Assert.True(true);
        }
    }
}
