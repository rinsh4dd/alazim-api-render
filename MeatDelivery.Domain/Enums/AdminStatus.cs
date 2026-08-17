using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum AdminStatus
    {
        ACTIVE,
        INACTIVE,
        LOCKED
    }
}
