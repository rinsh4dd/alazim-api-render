using System;
using System.Collections.Generic;
using System.Data;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Common.Helpers
{
    public static class CartSelectionTableHelper
    {
        public static DataTable CreateSelectionTable(List<CustomizationSelectionDto>? selections)
        {
            var dt = new DataTable();
            dt.Columns.Add("OPTION_ID", typeof(long));
            dt.Columns.Add("SELECTED_VALUE", typeof(decimal));

            var addedOptionIds = new HashSet<long>();

            if (selections != null && selections.Count > 0)
            {
                foreach (var sel in selections)
                {
                    if (sel.OptionId > 0 && addedOptionIds.Add(sel.OptionId))
                    {
                        dt.Rows.Add(sel.OptionId, sel.CustomValue.HasValue ? (object)sel.CustomValue.Value : DBNull.Value);
                    }
                }
            }

            return dt;
        }
    }
}
