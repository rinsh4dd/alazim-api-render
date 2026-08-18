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
                    await _productRepository.SaveProductMasterAsync(request, cancellationToken);
                    return ApiResponse<ProductDto>.SuccessResponse(null!, "Product deleted successfully.");
                }

                var productMaster = await _productRepository.SaveProductMasterAsync(request, cancellationToken);
                if (productMaster == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Failed to save product master record.");
                }

                long productId = productMaster.ProductId;

                // Sync Weight Options & Prices
                if (request.WeightOptions != null)
                {
                    await _productRepository.SyncProductWeightOptionsAndPricesAsync(productId, request.WeightOptions, cancellationToken);
                }

                // Sync Images
                if (request.Images != null)
                {
                    await _productRepository.SyncProductImagesAsync(productId, request.Images, cancellationToken);
                }

                // Retrieve updated full product object with options and images
                var fullProduct = await _productRepository.GetProductByIdAsync(productId, cancellationToken);

                string message = request.Mode switch
                {
                    Mode.ADD => "Product created successfully.",
                    Mode.EDIT => "Product updated successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<ProductDto>.SuccessResponse(fullProduct!, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<ProductDto>> GetProductByIdAsync(long productId, CancellationToken cancellationToken = default)
        {
            try
            {
                var product = await _productRepository.GetProductByIdAsync(productId, cancellationToken);
                if (product == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Product not found.");
                }

                return ApiResponse<ProductDto>.SuccessResponse(product, "Product details retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }
    }
}
