namespace MeatDelivery.Application.DTOs.Wishlist
{
    public class GetWishlistQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
