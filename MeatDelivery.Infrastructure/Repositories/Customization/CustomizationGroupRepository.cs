using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Customization;

namespace MeatDelivery.Infrastructure.Repositories.Customization
{
    public class CustomizationGroupRepository : ICustomizationGroupRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public CustomizationGroupRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<CustomizationGroupDto?> SaveCustomizationGroupAsync(
            SaveCustomizationGroupDto request,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CustomizationGroupDto>(
                "PR_SAVE_CUSTOMIZATION_GROUP",
                new
                {
                    MODE = request.Mode.ToString(),
                    CUSTOMIZATION_GROUP_ID = request.CustomizationGroupId,
                    GROUP_CODE = request.GroupCode,
                    GROUP_NAME_EN = request.GroupNameEn,
                    GROUP_NAME_AR = request.GroupNameAr,
                    IS_ADDITIONAL_PRICE_AVAILABLE = request.IsAdditionalPriceAvailable,
                    IS_ACTIVE = request.IsActive
                }
            );
        }
    }
}
