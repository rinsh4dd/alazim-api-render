using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Company;

namespace MeatDelivery.Application.Interfaces.Repositories.Company
{
    public interface ICompanyHolidayRepository
    {
        Task<List<CompanyHolidayDto>> GetCompanyHolidaysAsync(GetCompanyHolidaysQueryDto query, CancellationToken cancellationToken = default);
        Task<long> SaveCompanyHolidayAsync(SaveCompanyHolidayDto request, CancellationToken cancellationToken = default);
    }
}
