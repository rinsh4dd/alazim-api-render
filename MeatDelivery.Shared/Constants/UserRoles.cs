namespace MeatDelivery.Shared.Constants
{
    public static class UserRoles
    {
        public const string SuperAdmin = "SUPER_ADMIN";
        public const string Admin = "ADMIN";
        public const string Administrator = "ADMINISTRATOR";
        public const string InventoryManager = "INVENTORY_MANAGER";
        public const string OrderManager = "ORDER_MANAGER";
        public const string CustomerSupport = "CUSTOMER_SUPPORT";
        public const string Customer = "CUSTOMER";
        public const string SuperAdminOrAdmin = "SUPER_ADMIN,ADMIN,ADMINISTRATOR";
        public const string AllAdminRoles = "SUPER_ADMIN,ADMIN,ADMINISTRATOR,INVENTORY_MANAGER,ORDER_MANAGER,CUSTOMER_SUPPORT";
    }
}
