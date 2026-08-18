using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.Extensions.Caching.Memory;
using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Application.Interfaces.Category;
using MeatDelivery.Application.Interfaces.Repositories.Category;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Catalog
{
    public class CategoryService : ICategoryService
    {
        private readonly ICategoryRepository _categoryRepository;
        private readonly IValidator<SaveCategoryDto> _saveValidator;
        private readonly IValidator<GetCategoriesQueryDto> _getValidator;
        private readonly IMemoryCache _cache;
        private static readonly List<string> CacheKeys = new();

        public CategoryService(
            ICategoryRepository categoryRepository,
            IValidator<SaveCategoryDto> saveValidator,
            IValidator<GetCategoriesQueryDto> getValidator,
            IMemoryCache cache)
        {
            _categoryRepository = categoryRepository;
            _saveValidator = saveValidator;
            _getValidator = getValidator;
            _cache = cache;
        }

        public async Task<ApiResponse<CategoryDto>> SaveCategoryAsync(SaveCategoryDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _saveValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CategoryDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _categoryRepository.SaveCategoryAsync(request, cancellationToken);

                if (result == null)
                {
                    return ApiResponse<CategoryDto>.FailureResponse("Failed to process category request.");
                }

                // Invalidate category listing cache on mutation
                InvalidateCategoryCache();

                string message = request.Mode switch
                {
                    Mode.ADD => "Category created successfully.",
                    Mode.EDIT => "Category updated successfully.",
                    Mode.DELETE => "Category deleted successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<CategoryDto>.SuccessResponse(result, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<CategoryDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<PagedResponse<List<CategoryDto>>> GetCategoriesAsync(GetCategoriesQueryDto query, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(query);

            var validationResult = await _getValidator.ValidateAsync(query, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return new PagedResponse<List<CategoryDto>>
                {
                    Success = false,
                    Message = "Validation failed.",
                    Errors = errors,
                    Data = new List<CategoryDto>()
                };
            }

            string cacheKey = $"cat_list_p{query.PageNumber}_s{query.PageSize}_q{query.SearchTerm}_cid{query.CategoryId}_a{query.IsActive}_v{query.IsVisible}_sb{query.SortBy}_so{query.SortOrder}";

            if (_cache.TryGetValue(cacheKey, out PagedResponse<List<CategoryDto>>? cachedResponse) && cachedResponse != null)
            {
                return cachedResponse;
            }

            try
            {
                var (items, totalRecords) = await _categoryRepository.GetCategoriesAsync(query, cancellationToken);

                var response = new PagedResponse<List<CategoryDto>>
                {
                    Success = true,
                    Message = "Categories retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };

                var cacheOptions = new MemoryCacheEntryOptions()
                    .SetAbsoluteExpiration(TimeSpan.FromMinutes(15))
                    .SetSlidingExpiration(TimeSpan.FromMinutes(5));

                _cache.Set(cacheKey, response, cacheOptions);
                lock (CacheKeys)
                {
                    if (!CacheKeys.Contains(cacheKey)) CacheKeys.Add(cacheKey);
                }

                return response;
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<CategoryDto>>
                {
                    Success = false,
                    Message = ex.Message,
                    Data = new List<CategoryDto>()
                };
            }
        }

        private static void InvalidateCategoryCache()
        {
            lock (CacheKeys)
            {
                CacheKeys.Clear();
            }
        }
    }
}