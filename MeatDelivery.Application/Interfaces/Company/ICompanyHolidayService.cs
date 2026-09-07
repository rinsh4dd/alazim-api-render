using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Company
{
    public interface ICompanyHolidayService
    {
        Task<ApiResponse<List<CompanyHolidayDto>>> GetCompanyHolidaysAsync(GetCompanyHolidaysQueryDto query, CancellationToken cancellationToken = default);
        Task<ApiResponse<object>> SaveCompanyHolidayAsync(SaveCompanyHolidayDto request, CancellationToken cancellationToken = default);
    }
}
