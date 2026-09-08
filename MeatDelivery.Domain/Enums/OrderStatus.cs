using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum OrderStatus
    {
        PLACED,
        CONFIRMED,
        PROCESSING,
        OUT_FOR_DELIVERY,
        DELIVERED,
        CANCELLED
    }
}
