using System;
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
        private readonly IValidator<SaveCategoryDto> _validator;

        public CategoryService(ICategoryRepository categoryRepository,IValidator<SaveCategoryDto> validator)
        {
            _categoryRepository = categoryRepository;
            _validator = validator;
        }

        public async Task<ApiResponse<CategoryDto>> SaveCategoryAsync(SaveCategoryDto request,CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _validator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CategoryDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _categoryRepository.SaveCategoryAsync(
                    request,
                    cancellationToken);

                if (result == null)
                {
                    return ApiResponse<CategoryDto>.FailureResponse(
                        "Failed to process category request.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Category created successfully.",
                    Mode.EDIT => "Category updated successfully.",
                    Mode.DELETE => "Category deleted successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<CategoryDto>.SuccessResponse(
                    result,
                    message);
            }
            catch (Exception ex)
            {
                return ApiResponse<CategoryDto>.FailureResponse(ex.Message);
            }
        }
    }
}