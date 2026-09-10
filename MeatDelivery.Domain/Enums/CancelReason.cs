using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum CancelReason
    {
        CHANGED_MY_MIND,
        ORDERED_BY_MISTAKE,
        DELIVERY_TIME_TOO_LONG,
        WRONG_DELIVERY_ADDRESS,
        DUPLICATE_ORDER,
        OTHER
    }
}
