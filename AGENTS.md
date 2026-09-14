# Pragmatic Dapper Clean Architecture & Coding Standards

This document defines the mandatory architecture, database conventions, caching strategy, security, and coding patterns for the **MeatDelivery** backend solution.

---

## 1. Clean Architecture (Pragmatic Dapper Approach)

### Layering Flow
`API Controller` $\rightarrow$ `Application Service (ICouponService)` $\rightarrow$ `Infrastructure Repository (ICouponRepository)` $\rightarrow$ `Dapper Stored Procedure` $\rightarrow$ `Direct DTO Mapping`

* **No Redundant Domain Entities**: For CRUD or reporting modules (e.g. `Coupon`) where Dapper directly populates DTOs (`CouponDto`), domain entity mapping is not required.
* **Separation of Concerns**: Controllers only handle HTTP concerns and user claim extraction; Services orchestrate validation and repository calls; Repositories execute Dapper queries.

---

## 2. Database & Stored Procedure Conventions

### Procedure Naming
* Unified CUD operations: `dbo.PR_SAVE_<ENTITY>` (e.g., `dbo.PR_SAVE_COUPON` supporting `@MODE = 'ADD'`, `'EDIT'`, `'DELETE'`).
* Paginated Search/Read operations: `dbo.PR_GET_<ENTITY>` (e.g., `dbo.PR_GET_COUPONS`).
* Procedure Migration Scripts: Must use `CREATE OR ALTER PROCEDURE` (never wrap `CREATE PROCEDURE` inside `IF NOT EXISTS`).

### Standard Procedure Audit & Soft Delete Columns
All entities must support audit tracking and soft delete:
* `CREATED_BY BIGINT NULL` / `CREATED_AT DATETIME2 DEFAULT (SYSUTCDATETIME())`
* `UPDATED_BY BIGINT NULL` / `UPDATED_AT DATETIME2 NULL`
* `IS_DELETED BIT DEFAULT (0)` / `DELETED_AT DATETIME2 NULL`

> ⚠️ **Soft Delete Rule**: When `@MODE = 'DELETE'`, update `IS_DELETED = 1`, `DELETED_AT = SYSUTCDATETIME()`, and `UPDATED_BY = @ACTIONED_BY`. Never hard-delete records.

### Paginated Query Result Set Order
Paginated stored procedures (`dbo.PR_GET_COUPONS`) **MUST** return result sets in this exact order:
1. **Result Set 1**: `SELECT COUNT(1) AS TotalRecords FROM ...` (Scalar `int`)
2. **Result Set 2**: `SELECT ... OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS FETCH NEXT @PAGE_SIZE ROWS ONLY;`

#### Correct Dapper GridReader Consumption (e.g. CouponRepository)
```csharp
public async Task<(IEnumerable<CouponDto> Items, int TotalRecords)> GetCouponsAsync(GetCouponsQueryDto query, CancellationToken cancellationToken = default)
{
    return await _dapperRepository.QueryMultipleAsync(
        "dbo.PR_GET_COUPONS",
        async grid =>
        {
            var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
            var items = await grid.ReadAsync<CouponDto>();
            return (items, totalRecords);
        },
        new
        {
            COUPON_ID = query.CouponId,
            COUPON_CODE = query.CouponCode,
            COUPON_STATUS = query.CouponStatus,
            SEARCH = query.Search,
            PAGE_NUMBER = query.PageNumber,
            PAGE_SIZE = query.PageSize
        }
    );
}
```

---

## 3. Validation & DTO Standards

* **Clean DTOs**: DTOs must remain pure data contracts (e.g. `SaveCouponDto`). Do **NOT** add `System.ComponentModel.DataAnnotations` attributes (`[Required]`, `[StringLength]`).
* **FluentValidation**: Place validator classes in `MeatDelivery.Application.Validators.<Feature>` (e.g. `SaveCouponDtoValidator`).
* **Execution**: Inject `IValidator<SaveCouponDto>` into `CouponService` and validate before executing repository operations:
  ```csharp
  var validationResult = await _validator.ValidateAsync(request, cancellationToken);
  if (!validationResult.IsValid)
  {
      return ApiResponse<CouponDto>.FailureResponse("Validation failed.", validationResult.Errors.Select(e => e.ErrorMessage).ToList());
  }
  ```

---

## 4. Security & Role Authorization

* **No Hardcoded Magic Strings**: All roles must be referenced via `MeatDelivery.Shared.Constants.UserRoles`.
  ```csharp
  [HttpPost("admin/save")]
  [Authorize(Roles = UserRoles.SuperAdminOrAdmin)]
  ```
* **User Context Extraction**: Use the static extension method `HttpContext.GetUserId()` to extract the current user or admin ID:
  ```csharp
  request.ActionedBy = HttpContext.GetUserId();
  ```

---

## 5. In-Memory Caching & Eviction Flow

* **Service-Level Caching**: Public/Read endpoints (`Get...Async`) use `IMemoryCache` in `MeatDelivery.Infrastructure.Services`.
* **Cache Helper**: Use `CacheHelper.CreateOptions()` and `CacheHelper.InvalidateToken()` from `MeatDelivery.Infrastructure.Helpers`.

```csharp
private static CancellationTokenSource _couponCacheTokenSource = new();

// Read (GET /api/v1/coupons)
string cacheKey = $"coupons:id_{query.CouponId}_code_{query.CouponCode}_status_{query.CouponStatus}_search_{query.Search}_p_{query.PageNumber}_s_{query.PageSize}";
if (_cache.TryGetValue(cacheKey, out PagedResponse<List<CouponDto>>? cached) && cached != null)
    return cached;

var (items, totalRecords) = await _couponRepository.GetCouponsAsync(query, cancellationToken);
var response = new PagedResponse<List<CouponDto>> { ... };
_cache.Set(cacheKey, response, CacheHelper.CreateOptions(_couponCacheTokenSource, TimeSpan.FromMinutes(30)));
return response;

// Write (ADD / EDIT / DELETE)
CacheHelper.InvalidateToken(ref _couponCacheTokenSource);
```

---

## 6. Global Error Handling & TraceId

* **No Service Try-Catch Clutter**: Service methods handle business validation directly. Uncaught runtime exceptions automatically bubble up to `ExceptionHandlingMiddleware`.
* **TraceId**: Controllers populate `response.TraceId = HttpContext.TraceIdentifier;` for all GET and POST responses.
