using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
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

        public CategoryService(
            ICategoryRepository categoryRepository,
            IValidator<SaveCategoryDto> saveValidator,
            IValidator<GetCategoriesQueryDto> getValidator)
        {
            _categoryRepository = categoryRepository;
            _saveValidator = saveValidator;
            _getValidator = getValidator;
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

            try
            {
                var (items, totalRecords) = await _categoryRepository.GetCategoriesAsync(query, cancellationToken);

                return new PagedResponse<List<CategoryDto>>
                {
                    Success = true,
                    Message = "Categories retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
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
    }
}