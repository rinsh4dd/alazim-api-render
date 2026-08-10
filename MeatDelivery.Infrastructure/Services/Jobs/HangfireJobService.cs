using Hangfire;
using MeatDelivery.Application.Interfaces.Jobs;
using System;
using System.Linq.Expressions;

namespace MeatDelivery.Infrastructure.Services.Jobs
{
    public sealed class HangfireJobService : IBackgroundJobService
    {
        public string Enqueue(Expression<Action> methodCall)
        {
            return BackgroundJob.Enqueue(methodCall);
        }

        public string Enqueue<T>(Expression<Action<T>> methodCall)
        {
            return BackgroundJob.Enqueue(methodCall);
        }

        public string Schedule(Expression<Action> methodCall, TimeSpan delay)
        {
            return BackgroundJob.Schedule(methodCall, delay);
        }

        public string Schedule<T>(Expression<Action<T>> methodCall, TimeSpan delay)
        {
            return BackgroundJob.Schedule(methodCall, delay);
        }

        public void AddOrUpdateRecurring(string recurringJobId, Expression<Action> methodCall, string cronExpression)
        {
            RecurringJob.AddOrUpdate(recurringJobId, methodCall, cronExpression);
        }

        public void AddOrUpdateRecurring<T>(string recurringJobId, Expression<Action<T>> methodCall, string cronExpression)
        {
            RecurringJob.AddOrUpdate(recurringJobId, methodCall, cronExpression);
        }

        public bool DeleteRecurring(string recurringJobId)
        {
            RecurringJob.RemoveIfExists(recurringJobId);
            return true;
        }
    }
}
