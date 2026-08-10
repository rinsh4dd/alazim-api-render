using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.DTOs.Auth
{
    public sealed class UserContextDto
    {
        public Guid UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public IList<string> Roles { get; set; } = new List<string>();
        public IList<string> Permissions { get; set; } = new List<string>();
    }
}
