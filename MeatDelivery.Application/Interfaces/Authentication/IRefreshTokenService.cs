using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IRefreshTokenService
    {
        string GenerateToken();


    }
}
