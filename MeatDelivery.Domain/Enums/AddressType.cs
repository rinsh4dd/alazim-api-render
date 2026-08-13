using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum AddressType
    {
        HOME,
        OFFICE,
        OTHER
    }
}
