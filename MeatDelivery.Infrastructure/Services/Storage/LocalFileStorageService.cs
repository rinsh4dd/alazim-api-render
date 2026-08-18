using MeatDelivery.Application.Interfaces.Storage;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.Hosting;
using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Services.Storage
{
    public sealed class LocalFileStorageService : IFileStorageService
    {
        private readonly IHostEnvironment _environment;
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".webp", ".pdf", ".doc", ".docx" };
        private const long MaxFileSizeInBytes = 5 * 1024 * 1024; // 5 MB Max

        public LocalFileStorageService(IHostEnvironment environment)
        {
            _environment = environment;
        }

        public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string subFolder, CancellationToken cancellationToken = default)
        {
            if (fileStream == null || fileStream.Length == 0)
            {
                throw new ArgumentException("File stream is empty or invalid.", nameof(fileStream));
            }

            if (fileStream.Length > MaxFileSizeInBytes)
            {
                throw new InvalidOperationException("File size exceeds maximum allowed limit of 5 MB.");
            }

            var extension = Path.GetExtension(fileName).ToLowerInvariant();
            if (!AllowedExtensions.Contains(extension))
            {
                throw new InvalidOperationException($"File extension '{extension}' is not allowed.");
            }

            var rootPath = _environment.ContentRootPath;
            var targetFolder = Path.Combine(rootPath, "Uploads", subFolder);

            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }

            var uniqueFileName = $"{Guid.NewGuid():N}_{DateTime.UtcNow.Ticks}{extension}";
            var fullPath = Path.Combine(targetFolder, uniqueFileName);

            using (var destinationStream = File.Create(fullPath))
            {
                await fileStream.CopyToAsync(destinationStream, cancellationToken);
            }

            // Return relative path suitable for URL serving
            return Path.Combine("Uploads", subFolder, uniqueFileName).Replace("\\", "/");
        }

        public async Task<(byte[] FileBytes, string ContentType, string FileName)> DownloadFileAsync(string relativePath, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(relativePath))
            {
                throw new ArgumentException("File path is invalid.", nameof(relativePath));
            }

            var fullPath = Path.Combine(_environment.ContentRootPath, relativePath.Replace("/", "\\"));

            if (!File.Exists(fullPath))
            {
                throw new FileNotFoundException($"File not found at path '{relativePath}'.");
            }

            var provider = new FileExtensionContentTypeProvider();
            if (!provider.TryGetContentType(fullPath, out var contentType))
            {
                contentType = "application/octet-stream";
            }

            var fileBytes = await File.ReadAllBytesAsync(fullPath, cancellationToken);
            var originalName = Path.GetFileName(fullPath);

            return (fileBytes, contentType, originalName);
        }

        public Task<bool> DeleteFileAsync(string relativePath, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(relativePath))
            {
                return Task.FromResult(false);
            }

            var fullPath = Path.Combine(_environment.ContentRootPath, relativePath.Replace("/", "\\"));

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
                return Task.FromResult(true);
            }

            return Task.FromResult(false);
        }
    }
}
