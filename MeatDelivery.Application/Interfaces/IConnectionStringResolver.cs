using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces
{
    public interface IConnectionStringResolver
    {
        string GetConnectionString();
        string GetMasterConnectionString();
    }
}
