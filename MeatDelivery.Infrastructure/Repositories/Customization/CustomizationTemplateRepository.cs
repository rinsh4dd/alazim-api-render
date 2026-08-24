using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Customization;

namespace MeatDelivery.Infrastructure.Repositories.Customization
{
    public class CustomizationTemplateRepository : ICustomizationTemplateRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public CustomizationTemplateRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<CustomizationTemplateDto?> SaveCustomizationTemplateAsync(
            SaveCustomizationTemplateDto request,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CustomizationTemplateDto>(
                "PR_SAVE_CUSTOMIZATION_TEMPLATE",
                new
                {
                    MODE = request.Mode.ToString(),
                    CUSTOMIZATION_TEMPLATE_ID = request.CustomizationTemplateId,
                    TEMPLATE_NAME_EN = request.TemplateNameEn,
                    TEMPLATE_NAME_AR = request.TemplateNameAr,
                    DESCRIPTION_EN = request.DescriptionEn,
                    DESCRIPTION_AR = request.DescriptionAr,
                    IS_ACTIVE = request.IsActive
                }
            );
        }
    }
}
