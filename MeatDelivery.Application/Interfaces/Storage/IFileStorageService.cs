using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Storage
{
    public interface IFileStorageService
    {
        Task<string> UploadFileAsync(Stream fileStream, string fileName, string subFolder, CancellationToken cancellationToken = default);
        Task<(byte[] FileBytes, string ContentType, string FileName)> DownloadFileAsync(string relativePath, CancellationToken cancellationToken = default);
        Task<bool> DeleteFileAsync(string relativePath, CancellationToken cancellationToken = default);
    }
}
