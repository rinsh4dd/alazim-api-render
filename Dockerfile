# Stage 1: Build & Publish
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files for efficient Docker layer caching
COPY ["MeatDelivery.Api/MeatDelivery.Api.csproj", "MeatDelivery.Api/"]
COPY ["MeatDelivery.Application/MeatDelivery.Application.csproj", "MeatDelivery.Application/"]
COPY ["MeatDelivery.Domain/MeatDelivery.Domain.csproj", "MeatDelivery.Domain/"]
COPY ["MeatDelivery.Infrastructure/MeatDelivery.Infrastructure.csproj", "MeatDelivery.Infrastructure/"]
COPY ["MeatDelivery.Migrations/MeatDelivery.Migrations.csproj", "MeatDelivery.Migrations/"]
COPY ["MeatDelivery.Plugins/MeatDelivery.Plugins.csproj", "MeatDelivery.Plugins/"]
COPY ["MeatDelivery.Shared/MeatDelivery.Shared.csproj", "MeatDelivery.Shared/"]
COPY ["MeatDelivery.Worker/MeatDelivery.Worker.csproj", "MeatDelivery.Worker/"]

# Restore NuGet dependencies
RUN dotnet restore "MeatDelivery.Api/MeatDelivery.Api.csproj"

# Copy entire source code
COPY . .

# Build and publish the API in Release mode
WORKDIR "/src/MeatDelivery.Api"
RUN dotnet publish "MeatDelivery.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Runtime Image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Copy published binaries
COPY --from=build /app/publish .

# Render assigns port dynamically or defaults to 8080
ENV ASPNETCORE_HTTP_PORTS=8080
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080

# Run API
ENTRYPOINT ["dotnet", "MeatDelivery.Api.dll"]
