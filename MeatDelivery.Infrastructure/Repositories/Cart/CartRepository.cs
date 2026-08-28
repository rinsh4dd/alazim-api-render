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

        public async Task<bool> AddToCartAsync(long customerUserId, AddCartItemDto dto)
        {
            using var connection = _connectionFactory.CreateConnection();

            var optionTable = new DataTable();
            optionTable.Columns.Add("OPTION_ID", typeof(long));

            if (dto.CustomizationOptionIds != null)
            {
                foreach (var optionId in dto.CustomizationOptionIds)
                {
                    optionTable.Rows.Add(optionId);
                }
            }

            var parameters = new DynamicParameters();
            parameters.Add("MODE", "ADD");
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("PRODUCT_ID", dto.ProductId);
            parameters.Add("QUANTITY", dto.Quantity);
            parameters.Add("SPECIAL_INSTRUCTIONS", dto.SpecialInstructions);
            parameters.Add("OPTION_IDS", optionTable.AsTableValuedParameter("dbo.TT_CUSTOMIZATION_OPTION_IDS"));

            await connection.ExecuteAsync(
                "dbo.PR_SAVE_CART_ITEM",
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
    }
}
