using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Application.Interfaces.Company;
using MeatDelivery.Application.Interfaces.Repositories.Company;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Company
{
    public class CompanyHolidayService : ICompanyHolidayService
    {
        private readonly ICompanyHolidayRepository _repository;
        private readonly IValidator<SaveCompanyHolidayDto> _validator;

        public CompanyHolidayService(
            ICompanyHolidayRepository repository,
            IValidator<SaveCompanyHolidayDto> validator)
        {
            _repository = repository;
            _validator = validator;
        }

        public async Task<ApiResponse<List<CompanyHolidayDto>>> GetCompanyHolidaysAsync(GetCompanyHolidaysQueryDto query, CancellationToken cancellationToken = default)
        {
            var list = await _repository.GetCompanyHolidaysAsync(query, cancellationToken);
            return ApiResponse<List<CompanyHolidayDto>>.SuccessResponse(list, "Company holidays retrieved successfully.");
        }

        public async Task<ApiResponse<object>> SaveCompanyHolidayAsync(SaveCompanyHolidayDto request, CancellationToken cancellationToken = default)
        {
            var validationResult = await _validator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<object>.FailureResponse("Validation failed.", errors);
            }

            var holidayId = await _repository.SaveCompanyHolidayAsync(request, cancellationToken);

            string message = request.Mode switch
            {
                Mode.EDIT => "Company holiday updated successfully.",
                Mode.DELETE => "Company holiday deleted successfully.",
                _ => "Company holiday created successfully."
            };

            return ApiResponse<object>.SuccessResponse(new { CompanyHolidayId = holidayId }, message);
        }
    }
}
