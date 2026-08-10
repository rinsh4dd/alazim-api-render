using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IPasswordHasher
    {
        string HashPassword(string password);

        bool VerifyPassword(
            string password,
            string passwordHash);
    }
}
