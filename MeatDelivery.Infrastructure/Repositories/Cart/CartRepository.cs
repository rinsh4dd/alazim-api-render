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

        public async Task<(dynamic? Header, List<dynamic> Items, List<dynamic> Options)> GetActiveCartRawDataAsync(long customerUserId)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var gridReader = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMER_ACTIVE_CART",
                new { CUSTOMER_USER_ID = customerUserId },
                commandType: CommandType.StoredProcedure
            );

            var header = (await gridReader.ReadAsync<dynamic>()).FirstOrDefault();
            var items = (await gridReader.ReadAsync<dynamic>()).ToList();
            var options = (await gridReader.ReadAsync<dynamic>()).ToList();

            return (header, items, options);
        }

        private static DataTable CreateSelectionTable(List<CustomizationSelectionDto>? selections)
        {
            var dt = new DataTable();
            dt.Columns.Add("OPTION_ID", typeof(long));
            dt.Columns.Add("SELECTED_VALUE", typeof(decimal));

            var addedOptionIds = new HashSet<long>();

            if (selections != null && selections.Count > 0)
            {
                foreach (var sel in selections)
                {
                    if (sel.OptionId > 0 && !addedOptionIds.Contains(sel.OptionId))
                    {
                        dt.Rows.Add(sel.OptionId, sel.CustomValue.HasValue ? (object)sel.CustomValue.Value : DBNull.Value);
                        addedOptionIds.Add(sel.OptionId);
                    }
                }
            }

            return dt;
        }

        public async Task<bool> AddToCartAsync(long customerUserId, AddCartItemDto dto)
        {
            using var connection = _connectionFactory.CreateConnection();
            var selectionTable = CreateSelectionTable(dto.Customizations);

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("PRODUCT_ID", dto.ProductId);
            parameters.Add("QUANTITY", dto.Quantity);
            parameters.Add("SPECIAL_INSTRUCTIONS", dto.SpecialInstructions);
            parameters.Add("OPTION_SELECTIONS", selectionTable.AsTableValuedParameter("dbo.TT_CUSTOMIZATION_SELECTIONS"));

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
            var selectionTable = CreateSelectionTable(dto.Customizations);

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("CART_ITEM_ID", dto.CartItemId);
            parameters.Add("SPECIAL_INSTRUCTIONS", dto.SpecialInstructions);
            parameters.Add("OPTION_SELECTIONS", selectionTable.AsTableValuedParameter("dbo.TT_CUSTOMIZATION_SELECTIONS"));

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
