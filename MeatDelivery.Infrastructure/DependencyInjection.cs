using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Data;
using MeatDelivery.Application.Interfaces.Jobs;
using MeatDelivery.Application.Interfaces.Logging;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Application.Interfaces.Storage;
using MeatDelivery.Infrastructure.Configurations;
using MeatDelivery.Infrastructure.Data;
using MeatDelivery.Infrastructure.Repositories.Authentication;
using MeatDelivery.Infrastructure.Services.Authentication;
using MeatDelivery.Infrastructure.Services.Jobs;
using MeatDelivery.Infrastructure.Services.Logging;
using MeatDelivery.Infrastructure.Services.Storage;
using System.Security.Claims;
using System.Text;

namespace MeatDelivery.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // --------------------------------------------
            // JWT Settings
            // --------------------------------------------
            services.Configure<JwtSettings>(
                configuration.GetSection(JwtSettings.SectionName));

            var jwtSettings = configuration
                .GetSection(JwtSettings.SectionName)
                .Get<JwtSettings>()
                ?? throw new InvalidOperationException(
                    "JwtSettings configuration is missing.");

            if (string.IsNullOrWhiteSpace(jwtSettings.SecretKey) ||
                jwtSettings.SecretKey.Length < 32)
            {
                throw new InvalidOperationException(
                    "JWT SecretKey must be at least 32 characters long.");
            }

            // --------------------------------------------
            // Authentication
            // --------------------------------------------
            services
                .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.RequireHttpsMetadata = false; // Set true in production
                    options.SaveToken = true;

                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidIssuer = jwtSettings.Issuer,

                        ValidateAudience = true,
                        ValidAudience = jwtSettings.Audience,

                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(jwtSettings.SecretKey)),

                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.Zero,

                        NameClaimType = ClaimTypes.Name,
                        RoleClaimType = ClaimTypes.Role
                    };
                });

            // --------------------------------------------
            // Authorization Policies
            // --------------------------------------------
            services.AddAuthorization(options =>
            {
                options.AddPolicy("RequireAdmin",
                    policy => policy.RequireRole("Admin"));

                options.AddPolicy("RequireManager",
                    policy => policy.RequireRole("Admin", "Manager"));

                options.AddPolicy("CanManageUsers",
                    policy => policy.RequireClaim("permission", "users.manage"));

                options.AddPolicy("CanViewReports",
                    policy => policy.RequireClaim("permission", "reports.view"));

                options.AddPolicy("CanManageSettings",
                    policy => policy.RequireClaim("permission", "settings.manage"));
            });

            // --------------------------------------------
            // Database & Unit of Work
            // --------------------------------------------
            DapperTypeHandlerExtensions.RegisterDapperEnumHandlers();
            services.AddScoped<IDbConnectionFactory, DbConnectionFactory>();
            services.AddScoped<IDapperRepository, DapperRepository>();
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            // --------------------------------------------
            // File Storage Service (BE-014)
            // --------------------------------------------
            services.AddScoped<IFileStorageService, LocalFileStorageService>();

            // --------------------------------------------
            // Background Jobs (BE-015)
            // --------------------------------------------
            services.AddScoped<IBackgroundJobService, HangfireJobService>();

            // --------------------------------------------
            // Authentication & Security Services
            // --------------------------------------------
            services.Configure<MeatDelivery.Infrastructure.Security.PasswordHashingOptions>(
                configuration.GetSection(MeatDelivery.Infrastructure.Security.PasswordHashingOptions.SectionName));
            services.AddSingleton<MeatDelivery.Application.Common.Security.IPasswordHasher, MeatDelivery.Infrastructure.Security.BcryptPasswordHasher>();
            services.AddSingleton<MeatDelivery.Application.Common.Security.IPasswordGenerator, MeatDelivery.Infrastructure.Security.SecurePasswordGenerator>();

            services.AddScoped<ITokenService, JwtTokenService>();
            services.AddScoped<IOtpService, OtpService>();

            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IUserSessionRepository, UserSessionRepository>();
            services.AddScoped<IPermissionRepository, PermissionRepository>();
            services.AddScoped<IOtpVerificationRepository, OtpVerificationRepository>();
            services.AddScoped<IUserRegistrationRepository, UserRegistrationRepository>();

            services.AddScoped<IAuthenticationService, AuthenticationService>();

            // Admin Authentication & Management Services & Repositories
            services.AddScoped<MeatDelivery.Application.Interfaces.Repositories.Authentication.IAdminUserRepository, MeatDelivery.Infrastructure.Repositories.Authentication.AdminUserRepository>();
            services.AddScoped<MeatDelivery.Application.Interfaces.Repositories.Authentication.IAdminSessionRepository, MeatDelivery.Infrastructure.Repositories.Authentication.AdminSessionRepository>();
            services.AddScoped<MeatDelivery.Application.Interfaces.Authentication.IAdminAuthenticationService, MeatDelivery.Infrastructure.Services.Authentication.AdminAuthenticationService>();
            services.AddScoped<MeatDelivery.Application.Interfaces.Admin.IAdminUserService, MeatDelivery.Infrastructure.Services.Admin.AdminUserService>();

            // Customer Services & Repositories
            services.AddScoped<MeatDelivery.Application.Interfaces.Repositories.Customer.ICustomerRepository, MeatDelivery.Infrastructure.Repositories.Customer.CustomerRepository>();
            services.AddScoped<MeatDelivery.Application.Interfaces.Customer.ICustomerService, MeatDelivery.Infrastructure.Services.Customer.CustomerService>();

            // Category Domain Services & Repositories
            services.AddMemoryCache();
            services.AddScoped<MeatDelivery.Application.Interfaces.Repositories.Category.ICategoryRepository, MeatDelivery.Infrastructure.Repositories.Catalog.CategoryRepository>();
            services.AddScoped<MeatDelivery.Application.Interfaces.Category.ICategoryService, MeatDelivery.Infrastructure.Services.Catalog.CategoryService>();

            // Product & Measurement Unit Services & Repositories
            services.AddScoped<MeatDelivery.Application.Interfaces.Repositories.Product.IMeasurementUnitRepository, MeatDelivery.Infrastructure.Repositories.Catalog.MeasurementUnitRepository>();
            services.AddScoped<MeatDelivery.Application.Interfaces.Product.IMeasurementUnitService, MeatDelivery.Infrastructure.Services.Catalog.MeasurementUnitService>();

            // Logging
            services.AddScoped<IActivityLogService, ActivityLogService>();

            return services;
        }
    }
}
