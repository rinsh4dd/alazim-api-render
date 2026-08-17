using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum Mode
    {
        ADD,
        EDIT,
        DELETE
    }
}
