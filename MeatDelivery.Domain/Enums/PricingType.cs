using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum PricingType
    {
        ADDITIONAL_PRICE,
        MULTIPLIER,
        PERCENTAGE,
        FIXED_PRICE
    }
}
