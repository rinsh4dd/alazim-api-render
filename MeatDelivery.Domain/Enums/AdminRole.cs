using System.Text.Json.Serialization;

namespace MeatDelivery.Domain.Enums
{
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public enum AdminRole
    {
        SUPER_ADMIN,
        ADMINISTRATOR,
        INVENTORY_MANAGER,
        ORDER_MANAGER,
        CUSTOMER_SUPPORT
    }
}
