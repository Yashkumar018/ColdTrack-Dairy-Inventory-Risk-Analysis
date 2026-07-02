# ColdTrack: Dairy Inventory Risk Analysis

## Project Background

This project is built on a real dairy supply chain dataset — 4 years of operational data (2019–2022) sourced directly from a working dairy distribution network. During initial exploration, one core problem became impossible to ignore: the entire network runs on a **fixed reorder quantity model** that has no connection to actual demand.

The result? Two failures happening at the same time, in the same network.

Locations sitting on excess inventory are holding products in cold storage well past their average shelf life — and by the time those products are dispatched, the delivery window has already expired. On the other side, locations running short are so understocked that a single restocking event requires **3 or more separate transport cycles** just to hit minimum threshold — burning logistics cost for no reason.

This analysis was built to quantify both failures, trace them back to their root cause, and put forward a clear path to fix it.

![image alt](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/71089cc91062e336068b622870b34706962b5bf2/screenshorts/cover_page.png)

The analysis is structured across three dashboard pages:

- **Risk Overview** — What is happening?
- **Root Cause Analysis** — Why is it happening?
- **Optimization Strategy** — What needs to change?

| Resource | Link |
|---|---|
| Interactive Power BI Dashboard | [Download here](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/b0f25a41b8e88dbe3d5f8324e2aeaba297a8c9f9/ColdTrack%20Dairy%20Risk%20Analysis.pbix) |
| SQL Data Cleaning Queries | [View here](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/b0f25a41b8e88dbe3d5f8324e2aeaba297a8c9f9/Sql%20queries/coldtrack_cleaning_queries.sql) |
| SQL Analysis Report | [Download here](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/b0f25a41b8e88dbe3d5f8324e2aeaba297a8c9f9/Sql%20queries/ColdTrack_SQL_Analysis.docx) |

---

## Data Structure & Initial Checks

The dataset contains key operational fields — `reorder_quantity`, `minimum_stock_threshold`, `brand`, `shelf_life_days`, `storage_condition`, `delivery_gap`, and `deliver_window_expiry` — across **4,325 records** spanning 11 dairy brands and multiple storage conditions.

<img width="149" height="276" alt="Image" src="https://github.com/user-attachments/assets/ae0428a8-941b-4437-b47d-4bf69d0f3091" />

Prior to beginning the analysis, a full round of data quality checks was conducted — covering null values, duplicate records, inconsistent categorical labels, negative quantity entries, price outliers, and mixed date formats.

Both the raw and cleaned versions of the dataset are available for download **[here](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/tree/b0f25a41b8e88dbe3d5f8324e2aeaba297a8c9f9/Data)**.

---

## Executive Summary

### Risk Overview — What Happened?

Out of 4,325 deliveries over 4 years, **1,761 resulted in delivery window expiry** — the product had already crossed its usable shelf life window before it reached the customer.

The numbers tell the story directly: where deliveries ran late, the **average delay was 30 days**. The **average product shelf life is 29 days**. The supply chain is, on average, one day too slow for the products it is moving — and that one day is costing the business every single delivery cycle.

Breaking it down by brand — **Amul (450) and Mother Dairy (372)** sit at the top. These are not just the biggest brands in this dataset — these are the two most trusted dairy brands in India. If expiry keeps happening at this rate, that trust erodes fast — and that is a much bigger problem than cold storage cost.

Seasonally, expiry peaks in **October, July, and June** — right at the pressure points of the calendar. Pre-festival demand surges, summer peak periods — exactly when supply chains are stretched thin and cold-chain lapses are most likely to slip through.

![image alt](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/71089cc91062e336068b622870b34706962b5bf2/screenshorts/risk_overview.png)

**Key Insights:**

- 40.7% of all deliveries over 4 years resulted in expiry — nearly 1 in 2 deliveries failed to reach the customer within the usable window
- Average delivery delay (30 days) exceeds average shelf life (29 days) — the distribution cycle is structurally misaligned with the perishability of the products it handles
- Amul and Mother Dairy together account for 822 expired deliveries — sustained expiry at this scale is a direct threat to brand equity and retailer trust
- Expiry peaks in October and June, coinciding with pre-festival demand surges when supply chain stress is at its highest
- The problem is not isolated to one brand or one product — it is systemic across all 11 brands, pointing to a supply chain planning failure

---

### Root Cause Analysis — Why Did It Happen?

The fixed reorder quantity model is running the network blind — and that is where both failures come from.

Of the 4,325 records, **2,000+ are classified as overstock** and **918 as understock** — simultaneously. Overstocked locations keep receiving inventory on schedule regardless of what is sitting in storage. That inventory accumulates beyond the product's average shelf life. By the time it is dispatched, the window is already closed.

From a storage condition standpoint, **Refrigerated (715) and Frozen (561)** recorded the highest expiry volumes — the two most temperature-sensitive and cost-intensive cold-chain categories in the network.

On the understock side, **32 restocking events** required 3 or more separate transport cycles to bring stock back to minimum threshold. Each of those extra trips is a cost with zero return.

![image alt](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/71089cc91062e336068b622870b34706962b5bf2/screenshorts/root_cause_analysis.png)

**Key Insights:**

- Fixed reorder quantity creates a dual failure — overstock and understock occurring simultaneously across the same network
- Overstocked inventory sits in cold storage beyond the 29-day average shelf life, making delivery window expiry inevitable before dispatch even begins
- Refrigerated and Frozen — the highest-cost storage conditions — account for the largest share of expiry volume
- 32 restocking events required 3+ transport cycles — reorder quantities are materially misaligned with minimum stock requirements at key locations
- This is not a demand problem. It is a planning problem — entirely caused by the absence of demand-sensitive replenishment logic

---

### Optimization Strategy — What Needs to Change?

The fix is not complex. The system just needs to stop being blind to demand.

The starting point is implementing a formal **Reorder Point (ROP)** — so that stock replenishment is triggered at the right time based on actual consumption, not a fixed calendar:

#### Reorder Point = (Average Daily Sales × Lead Time) + Safety Stock
#### Assumed Lead Time: 6 days | Safety Stock: Minimum Stock Threshold



![image alt](https://github.com/Yashkumar018/ColdTrack-Dairy-Inventory-Risk-Analysis/blob/71089cc91062e336068b622870b34706962b5bf2/screenshorts/Optimization_Strategy.png)

Beyond the reorder point, three interventions will close the remaining gaps:

**1. Demand-Based Dynamic Planning**
Replace fixed reorder quantities with quantities calculated from actual sales velocity per SKU per location. This resolves both the overstock and understock conditions simultaneously.

**2. FEFO — First Expiry, First Out**
Warehouse dispatch sequencing must be based on expiry date, not arrival date. The product closest to expiry goes out first — every time. This directly reduces cold storage duration and cuts avoidable expiry losses.

**3. Seasonal Safety Stock Adjustment**
Increase safety stock by 20–30% ahead of peak demand periods — Diwali, Holi, Eid, summer months. This absorbs demand spikes without triggering the multi-trip restocking cycles that are currently inflating transport costs.

If these three changes are implemented, the analysis estimates **₹141K in cold storage costs** — calculated as 12% of unit value × delivery delay for expired refrigerated and frozen shipments over 4 years — can be prevented. That is approximately **₹35K annually**, recovered purely through better planning.

---

## Recommendations & Action Plan

**Implement the Reorder Point formula using actual lead time and sales data**
Stop triggering replenishment on a fixed cycle. Tie it to consumption. This is the foundational change everything else builds on.

**Replace fixed reorder quantities with demand-based dynamic planning**
Location-level sales velocity should determine how much stock is ordered — not a static number. This resolves the dual failure of overstock and understock simultaneously.

**Enforce FEFO (First Expiry, First Out) in warehouse dispatch**
The product with the shortest remaining shelf life goes out first — every time. This alone can materially reduce cold storage duration and expiry losses.

**Increase safety stock 20–30% during festival and peak demand seasons**
Diwali, Holi, Eid, summer — these periods are predictable. Plan for them. The 32 multi-trip restocking events in this dataset are largely a peak-season failure that better safety stock buffers would have prevented.

**Track daily sales per SKU to improve demand forecasting accuracy**
The reorder point formula is only as good as the sales data feeding it. Daily tracking per product per location keeps the system calibrated over time.

---

*Prepared by Yash Kumar*
