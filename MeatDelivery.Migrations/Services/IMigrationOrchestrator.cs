namespace MeatDelivery.Migrations.Services
{
    public interface IMigrationOrchestrator
    {
        Task RunAsync();
    }
}
