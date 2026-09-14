using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Primitives;
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
        private readonly IValidator<UpdateProductImageDto> _updateImageValidator;
        private readonly IValidator<UpdateProductPriceDto> _updatePriceValidator;
        private readonly IValidator<GetPriceHistoryQueryDto> _getPriceHistoryValidator;
        private readonly IValidator<ManageAttributesDto> _manageAttributesValidator;
        private readonly IMemoryCache _cache;

        private static CancellationTokenSource _guestProductsCacheTokenSource = new();

        public ProductService(
            IProductRepository productRepository,
            IValidator<SaveProductDto> saveProductValidator,
            IValidator<UpdateProductStatusDto> updateStatusValidator,
            IValidator<UpdateProductImageDto> updateImageValidator,
            IValidator<UpdateProductPriceDto> updatePriceValidator,
            IValidator<GetPriceHistoryQueryDto> getPriceHistoryValidator,
            IValidator<ManageAttributesDto> manageAttributesValidator,
            IMemoryCache cache)
        {
            _productRepository = productRepository;
            _saveProductValidator = saveProductValidator;
            _updateStatusValidator = updateStatusValidator;
            _updateImageValidator = updateImageValidator;
            _updatePriceValidator = updatePriceValidator;
            _getPriceHistoryValidator = getPriceHistoryValidator;
            _manageAttributesValidator = manageAttributesValidator;
            _cache = cache;
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
                    InvalidateGuestProductsCache();
                    return ApiResponse<ProductDto>.SuccessResponse(null!, "Product deleted successfully.");
                }

                var productMaster = await _productRepository.SaveProductAsync(request, cancellationToken);
                if (productMaster == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Failed to save product record.");
                }

                InvalidateGuestProductsCache();

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

        public async Task<PagedResponse<List<CustomerProductDto>>> GetCustomerProductsAsync(long? customerUserId, GetCustomerProductsQueryDto query, CancellationToken cancellationToken = default)
        {
            query ??= new GetCustomerProductsQueryDto();

            try
            {
                // Cache Guest Mode responses (when customerUserId is null or 0)
                if (!customerUserId.HasValue || customerUserId.Value <= 0)
                {
                    string cacheKey = $"guest_products:prod_{query.ProductId}_cat_{query.CategoryId}_search_{query.SearchTerm}_p_{query.PageNumber}_s_{query.PageSize}";

                    if (_cache.TryGetValue(cacheKey, out PagedResponse<List<CustomerProductDto>>? cachedResponse) && cachedResponse != null)
                    {
                        return cachedResponse;
                    }

                    var (guestItems, guestTotal) = await _productRepository.GetCustomerProductsAsync(null, query, cancellationToken);
                    var guestResponse = new PagedResponse<List<CustomerProductDto>>
                    {
                        Success = true,
                        Message = "Customer products retrieved successfully.",
                        Data = guestItems,
                        PageNumber = query.PageNumber,
                        PageSize = query.PageSize,
                        TotalRecords = guestTotal
                    };

                    var cacheOptions = new MemoryCacheEntryOptions()
                        .SetAbsoluteExpiration(TimeSpan.FromMinutes(15))
                        .AddExpirationToken(new CancellationChangeToken(_guestProductsCacheTokenSource.Token));

                    _cache.Set(cacheKey, guestResponse, cacheOptions);

                    return guestResponse;
                }

                // Logged-In Customer Mode -> Dynamic call for personalized Wishlist & Order ranking
                var (items, totalRecords) = await _productRepository.GetCustomerProductsAsync(customerUserId, query, cancellationToken);
                return new PagedResponse<List<CustomerProductDto>>
                {
                    Success = true,
                    Message = "Customer products retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<CustomerProductDto>>
                {
                    Success = false,
                    Message = ex.Message,
                    Data = new List<CustomerProductDto>()
                };
            }
        }

        public async Task<ApiResponse<List<ProductDto>>> GetFreshPicksAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var items = await _productRepository.GetFreshPicksProductsAsync(cancellationToken);
                return ApiResponse<List<ProductDto>>.SuccessResponse(items, "Fresh picks retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<ProductDto>>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<List<ProductDto>>> GetFeaturedProductsAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var items = await _productRepository.GetFeaturedProductsAsync(cancellationToken);
                return ApiResponse<List<ProductDto>>.SuccessResponse(items, "Featured products retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<ProductDto>>.FailureResponse(ex.Message);
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

                InvalidateGuestProductsCache();

                string statusText = result.IsActive ? "activated" : "deactivated";
                return ApiResponse<ProductDto>.SuccessResponse(result, $"Product {statusText} successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<ProductDto>> UpdateProductImageAsync(UpdateProductImageDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _updateImageValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<ProductDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _productRepository.UpdateProductImageAsync(request, cancellationToken);
                if (result == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Product not found or failed to update image.");
                }

                InvalidateGuestProductsCache();

                return ApiResponse<ProductDto>.SuccessResponse(result, "Product images updated successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<ProductDto>> UpdateProductPriceAsync(UpdateProductPriceDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _updatePriceValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<ProductDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _productRepository.UpdateProductPriceAsync(request, cancellationToken);
                if (result == null)
                {
                    return ApiResponse<ProductDto>.FailureResponse("Product not found or failed to update price.");
                }

                InvalidateGuestProductsCache();

                return ApiResponse<ProductDto>.SuccessResponse(result, "Product price updated successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<ProductDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<PagedResponse<List<ProductPriceHistoryDto>>> GetPriceHistoryAsync(GetPriceHistoryQueryDto query, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(query);

            var validationResult = await _getPriceHistoryValidator.ValidateAsync(query, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return new PagedResponse<List<ProductPriceHistoryDto>>
                {
                    Success = false,
                    Message = "Validation failed.",
                    Errors = errors,
                    Data = new List<ProductPriceHistoryDto>()
                };
            }

            try
            {
                var (items, totalRecords) = await _productRepository.GetPriceHistoryAsync(query, cancellationToken);
                return new PagedResponse<List<ProductPriceHistoryDto>>
                {
                    Success = true,
                    Message = "Price history retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<ProductPriceHistoryDto>>
                {
                    Success = false,
                    Message = ex.Message,
                    Data = new List<ProductPriceHistoryDto>()
                };
            }
        }

        public async Task<ApiResponse<List<ProductDto>>> ManageProductAttributesAsync(ManageAttributesDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _manageAttributesValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<List<ProductDto>>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var items = await _productRepository.ManageProductAttributesAsync(request, cancellationToken);
                InvalidateGuestProductsCache();
                return ApiResponse<List<ProductDto>>.SuccessResponse(items, $"Product attributes updated successfully for mode '{request.Mode}'.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<ProductDto>>.FailureResponse(ex.Message);
            }
        }

        private static void InvalidateGuestProductsCache()
        {
            var oldTokenSource = Interlocked.Exchange(ref _guestProductsCacheTokenSource, new CancellationTokenSource());
            oldTokenSource.Cancel();
            oldTokenSource.Dispose();
        }
    }
}
