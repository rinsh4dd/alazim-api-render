using System;
using System.Linq.Expressions;

namespace MeatDelivery.Application.Interfaces.Jobs
{
    public interface IBackgroundJobService
    {
        string Enqueue(Expression<Action> methodCall);
        string Enqueue<T>(Expression<Action<T>> methodCall);
        string Schedule(Expression<Action> methodCall, TimeSpan delay);
        string Schedule<T>(Expression<Action<T>> methodCall, TimeSpan delay);
        void AddOrUpdateRecurring(string recurringJobId, Expression<Action> methodCall, string cronExpression);
        void AddOrUpdateRecurring<T>(string recurringJobId, Expression<Action<T>> methodCall, string cronExpression);
        bool DeleteRecurring(string recurringJobId);
    }
}
