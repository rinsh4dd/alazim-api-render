using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum UserStatus
    {
        PENDING,
        ACTIVE,
        BLOCKED,
        INACTIVE
    }
}
