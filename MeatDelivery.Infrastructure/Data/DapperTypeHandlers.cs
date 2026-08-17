using System;
using System.Data;
using Dapper;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Infrastructure.Data
{
    public class EnumStringTypeHandler<TEnum> : SqlMapper.TypeHandler<TEnum> where TEnum : struct, Enum
    {
        public override void SetValue(IDbDataParameter parameter, TEnum value)
        {
            parameter.Value = value.ToString();
            parameter.DbType = DbType.String;
        }

        public override TEnum Parse(object value)
        {
            if (value is string stringValue && Enum.TryParse<TEnum>(stringValue, true, out var result))
            {
                return result;
            }
            if (value is int intValue && Enum.IsDefined(typeof(TEnum), intValue))
            {
                return (TEnum)(object)intValue;
            }
            return default;
        }
    }

    public static class DapperTypeHandlerExtensions
    {
        public static void RegisterDapperEnumHandlers()
        {
            SqlMapper.AddTypeHandler(new EnumStringTypeHandler<Gender>());
            SqlMapper.AddTypeHandler(new EnumStringTypeHandler<UserStatus>());
            SqlMapper.AddTypeHandler(new EnumStringTypeHandler<AdminStatus>());
            SqlMapper.AddTypeHandler(new EnumStringTypeHandler<AddressType>());
            SqlMapper.AddTypeHandler(new EnumStringTypeHandler<AddressMode>());
        }
    }
}
