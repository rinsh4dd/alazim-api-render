using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Cart;

namespace MeatDelivery.Infrastructure.Repositories.Cart
{
    public class CartRepository : ICartRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public CartRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        private static DataTable CreateOptionTable(IEnumerable<long>? optionIds)
        {
            var dt = new DataTable();
            dt.Columns.Add("OPTION_ID", typeof(long));

            if (optionIds != null)
            {
                foreach (var id in optionIds)
                {
                    dt.Rows.Add(id);
                }
            }

            return dt;
        }

        public async Task<bool> AddToCartAsync(long customerUserId, AddCartItemDto dto)
        {
            using var connection = _connectionFactory.CreateConnection();
            var optionTable = CreateOptionTable(dto.CustomizationOptionIds);

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("PRODUCT_ID", dto.ProductId);
            parameters.Add("QUANTITY", dto.Quantity);
            parameters.Add("SPECIAL_INSTRUCTIONS", dto.SpecialInstructions);
            parameters.Add("OPTION_IDS", optionTable.AsTableValuedParameter("dbo.TT_CUSTOMIZATION_OPTION_IDS"));

            await connection.ExecuteAsync(
                "dbo.PR_ADD_TO_CART",
                parameters,
                commandType: CommandType.StoredProcedure
            );

            return true;
        }

        public async Task<bool> UpdateCartItemQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("CART_ITEM_ID", dto.CartItemId);
            parameters.Add("QUANTITY", dto.Quantity);

            await connection.ExecuteAsync(
                "dbo.PR_UPDATE_CART_ITEM_QUANTITY",
                parameters,
                commandType: CommandType.StoredProcedure
            );

            return true;
        }

        public async Task<bool> UpdateCartItemCustomizationAsync(long customerUserId, UpdateCartItemCustomizationDto dto)
        {
            using var connection = _connectionFactory.CreateConnection();
            var optionTable = CreateOptionTable(dto.CustomizationOptionIds);

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("CART_ITEM_ID", dto.CartItemId);
            parameters.Add("SPECIAL_INSTRUCTIONS", dto.SpecialInstructions);
            parameters.Add("CUSTOMIZATION_OPTION_IDS", optionTable.AsTableValuedParameter("dbo.TT_CUSTOMIZATION_OPTION_IDS"));

            await connection.ExecuteAsync(
                "dbo.PR_UPDATE_CART_ITEM_CUSTOMIZATION",
                parameters,
                commandType: CommandType.StoredProcedure
            );

            return true;
        }

        public async Task<bool> RemoveCartItemAsync(long customerUserId, RemoveCartItemDto dto)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("CART_ITEM_ID", dto.CartItemId);

            await connection.ExecuteAsync(
                "dbo.PR_REMOVE_CART_ITEM",
                parameters,
                commandType: CommandType.StoredProcedure
            );

            return true;
        }

        public async Task<bool> ClearCartAsync(long customerUserId)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);

            await connection.ExecuteAsync(
                "dbo.PR_CLEAR_CUSTOMER_CART",
                parameters,
                commandType: CommandType.StoredProcedure
            );

            return true;
        }
    }
}
