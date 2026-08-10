using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace MeatDelivery.Application.Interfaces
{
    public interface IDbConnectionFactory
    {
        IDbConnection CreateConnection();
    }
}
