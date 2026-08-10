using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using MeatDelivery.Shared.Responses;
using System.Net;

namespace MeatDelivery.Api.Filters
{
    public class ValidationFilter : IAsyncActionFilter
    {
        private readonly IServiceProvider _serviceProvider;

        public ValidationFilter(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            foreach (var argument in context.ActionArguments.Values)
            {
                if (argument is null) continue;

                var argumentType = argument.GetType();
                var validatorType = typeof(IValidator<>).MakeGenericType(argumentType);

                if (_serviceProvider.GetService(validatorType) is IValidator validator)
                {
                    var validationContext = new ValidationContext<object>(argument);
                    var validationResult = await validator.ValidateAsync(validationContext);

                    if (!validationResult.IsValid)
                    {
                        var errors = validationResult.Errors
                            .Select(e => e.ErrorMessage)
                            .ToList();

                        var response = new ErrorResponse
                        {
                            Message = "Validation failed.",
                            Errors = errors,
                            TraceId = context.HttpContext.TraceIdentifier
                        };

                        context.Result = new BadRequestObjectResult(response);
                        return;
                    }
                }
            }

            await next();
        }
    }
}
