using System;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Coupon;

namespace MeatDelivery.Infrastructure.Repositories.Coupon
{
    public class CouponRepository : ICouponRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public CouponRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }
    }
}
