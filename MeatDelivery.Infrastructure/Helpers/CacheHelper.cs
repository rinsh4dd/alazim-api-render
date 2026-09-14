using System;
using System.Threading;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Primitives;

namespace MeatDelivery.Infrastructure.Helpers
{
    public static class CacheHelper
    {
        /// <summary>
        /// Atomically cancels, disposes, and replaces a CancellationTokenSource to invalidate cache entries.
        /// </summary>
        public static void InvalidateToken(ref CancellationTokenSource tokenSource)
        {
            var oldTokenSource = Interlocked.Exchange(ref tokenSource, new CancellationTokenSource());
            oldTokenSource.Cancel();
            oldTokenSource.Dispose();
        }

        /// <summary>
        /// Creates MemoryCacheEntryOptions bound to a CancellationChangeToken.
        /// </summary>
        public static MemoryCacheEntryOptions CreateOptions(CancellationTokenSource tokenSource, TimeSpan duration)
        {
            return new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(duration)
                .AddExpirationToken(new CancellationChangeToken(tokenSource.Token));
        }
    }
}
