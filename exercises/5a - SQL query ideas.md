
## Sample query/report requests for participants (Query Agent exercise)

### Beginner — basic aggregation
- Show total sales value and quantity sold for each product category.
- Show total sales value for each store region, for a date range I specify.
- List the top 10 best-selling products by revenue.
- List the top 10 best-selling products by quantity sold.
- Show how many separate orders each store processed.
- Show the average discount percentage given, broken down by product category.

### Intermediate — new reports / views
- Build a monthly sales summary report, similar to the existing weekly one.
- Build a report showing total sales, discounts, and net revenue (after discount) per product.
- Build a scorecard for each store showing total sales, number of order lines, average basket size, and average discount given.
- Add a "net sales amount" column to the daily sales report — finance keeps asking for it.

### Intermediate — trends & rankings (window functions)
- Show the running (cumulative) total of sales over time for each region.
- Show which products moved up or down in ranking week over week within their category.
- Show the top 3 best-selling products for each individual store.

### Advanced — temporal / history
- Show what a specific order looked like at an earlier point in time, before any corrections were made to it.
- Show the full change history of a specific order line — every version of it that ever existed.
- Compare an order's current sales amount to what it was a week ago, to spot orders that were corrected after the fact.

### Advanced — data quality & ETL monitoring
- Show a dashboard of recent data loads: which ones succeeded, which failed, how long they took, and how many rows were rejected.
- Show the trend of rejected rows over time, broken down by source system.
- Find records in the raw incoming data that look invalid or incomplete (missing product, missing store, missing quantity or price).
- Compare how many rows arrived from a data load versus how many actually made it into the final sales data.
- Find products marked as discontinued/inactive that still show recent sales — this shouldn't happen and needs investigating.
- Find sales records where the tax rate charged doesn't match the product's current tax rate, and explain why that can legitimately happen.

### Advanced — cross-tab / pivot reports
- Build a table showing total sales by category across each month, with months as columns.
- Build a table showing total sales by region and category side by side, for easy comparison.

Note: no cost/margin or customer data exists in this model — requests framed around "profit" or "customer" would need to be flagged back rather than assumed.