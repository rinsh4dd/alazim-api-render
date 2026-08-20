using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum ProductAttributeMode
    {
        FEATURED,
        PREORDERABLE,
        NEW_ARRIVAL
    }
}
