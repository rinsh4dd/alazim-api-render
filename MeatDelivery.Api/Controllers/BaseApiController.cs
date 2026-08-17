using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Shared.Constants;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    public abstract class BaseApiController : ControllerBase
    {
        protected IActionResult Success<T>(T data, string message = ResponseMessages.Success)
        {
            return Ok(ApiResponse<T>.SuccessResponse(data, message, HttpContext.TraceIdentifier));
        }

        protected IActionResult CreatedResponse<T>(T data, string message = ResponseMessages.Created)
        {
            return StatusCode(StatusCodes.Status201Created,
                ApiResponse<T>.SuccessResponse(data, message, HttpContext.TraceIdentifier));
        }

        protected IActionResult Failure(string message, List<string>? errors = null)
        {
            return Ok(ApiResponse<object>.FailureResponse(
                message,
                errors,
                HttpContext.TraceIdentifier));
        }

        protected IActionResult UnauthorizedResponse(string message = "Unauthorized access.")
        {
            return StatusCode(StatusCodes.Status401Unauthorized,
                ApiResponse<object>.FailureResponse(
                    message,
                    new List<string> { message },
                    HttpContext.TraceIdentifier,
                    status: 0));
        }

        protected IActionResult NotFoundResponse(string message = "Resource not found.")
        {
            return StatusCode(StatusCodes.Status404NotFound,
                ApiResponse<object>.FailureResponse(
                    message,
                    new List<string> { message },
                    HttpContext.TraceIdentifier,
                    status: 0));
        }

        protected IActionResult BadRequestResponse(string message, List<string>? errors = null)
        {
            return BadRequest(ApiResponse<object>.FailureResponse(
                message,
                errors,
                HttpContext.TraceIdentifier,
                status: 0));
        }
    }
}
