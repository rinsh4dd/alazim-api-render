using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces.Product;
using MeatDelivery.Application.Interfaces.Repositories.Product;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Catalog
{
    public class ProductService : IProductService
    {
        private readonly IProductRepository _productRepository;
        private readonly IValidator<SaveProductDto> _saveProductValidator;

        public ProductService(
            IProductRepository productRepository,
            IValidator<SaveProductDto> saveProductValidator)
        {
            _productRepository = productRepository;
            _saveProductValidator = saveProductValidator;
        }

        public async Task<ApiResponse<ProductDto>> SaveProductAsync(SaveProductDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _saveProductValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<ProductDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                if (request.Mode == Mode.DELETE)
                {
                    await _productRepository.SaveProductFullAsync(request, cancellationToken);
                    return ApiResponse<ProductDto>.SuccessResponse(null!, "Product deleted successfully.");
                }

                var fullProduct = await _productRepository.SaveProductFullAsync(request, cancellationToken);
                if (fullProduct == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Failed to save product record.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Product created successfully.",
                    Mode.EDIT => "Product updated successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<ProductDto>.SuccessResponse(fullProduct, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }
    }
}
