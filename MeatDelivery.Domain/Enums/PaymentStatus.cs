using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum PaymentStatus
    {
        PENDING,
        SUCCESS,
        FAILED,
        CANCELLED,
        REFUNDED
    }
}
