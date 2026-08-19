using System;
using System.Collections.Generic;
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
        private readonly IValidator<UpdateProductStatusDto> _updateStatusValidator;

        public ProductService(
            IProductRepository productRepository,
            IValidator<SaveProductDto> saveProductValidator,
            IValidator<UpdateProductStatusDto> updateStatusValidator)
        {
            _productRepository = productRepository;
            _saveProductValidator = saveProductValidator;
            _updateStatusValidator = updateStatusValidator;
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
                    await _productRepository.SaveProductAsync(request, cancellationToken);
                    return ApiResponse<ProductDto>.SuccessResponse(null!, "Product deleted successfully.");
                }

                var productMaster = await _productRepository.SaveProductAsync(request, cancellationToken);
                if (productMaster == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Failed to save product record.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Product created successfully.",
                    Mode.EDIT => "Product updated successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<ProductDto>.SuccessResponse(productMaster, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<PagedResponse<List<ProductDto>>> GetProductsAsync(GetProductsQueryDto query, CancellationToken cancellationToken = default)
        {
            query ??= new GetProductsQueryDto();

            try
            {
                var (items, totalRecords) = await _productRepository.GetProductsAsync(query, cancellationToken);
                return new PagedResponse<List<ProductDto>>
                {
                    Success = true,
                    Message = "Products retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<ProductDto>>
                {
                    Success = false,
                    Message = ex.Message,
                    Data = new List<ProductDto>()
                };
            }
        }

        public async Task<ApiResponse<ProductDto>> UpdateProductStatusAsync(UpdateProductStatusDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _updateStatusValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<ProductDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _productRepository.UpdateProductStatusAsync(request, cancellationToken);
                if (result == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Product not found or failed to update status.");
                }

                string statusText = result.IsActive ? "activated" : "deactivated";
                return ApiResponse<ProductDto>.SuccessResponse(result, $"Product {statusText} successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }
    }
}
