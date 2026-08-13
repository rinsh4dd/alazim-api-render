using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum AddressMode
    {
        ADD,
        EDIT,
        DELETE
    }
}
