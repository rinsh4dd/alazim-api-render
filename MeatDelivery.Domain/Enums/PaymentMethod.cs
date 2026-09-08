using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum PaymentMethod
    {
        COD,
        CARD,
        APPLE_PAY,
        GOOGLE_PAY,
        WALLET
    }
}
