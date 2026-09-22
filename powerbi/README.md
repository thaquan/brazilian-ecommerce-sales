> Ghi chú cập nhật 21/09/2026: nội dung triển khai/kiểm tra dưới đây được giữ theo thời điểm ghi nhận. Xem [trạng thái và evidence mới nhất](../docs/testing.md). Không suy luận test đã đạt chỉ từ hướng dẫn cấu hình.

# Olist Analytics — Power BI report

Open `RPT_Olist_Analytics.pbip` in Power BI Desktop and sign in with access to the Fabric semantic model `WS_Olist_Demo / SM_Olist_Analytics`. The report uses a live connection; data is not bundled in this folder.

The six native Power BI pages adapt the sidebar, cards and chart layout of [AdminLTE v4](https://adminlte.io/themes/v4/index.html): Overview, Sales & Sellers, Customers, Delivery & Reviews, Payments and Data Health. This is a Power BI implementation of the design reference, not an embedded HTML dashboard.

The left sidebar uses the native Page Navigator, with the current page highlighted. Every page has a **Home** button in its upper-right corner, configured with Page navigation to Overview (not history-based Back). In Power BI Desktop/edit mode, hold **Ctrl** while clicking navigation buttons. In Service reading mode, click normally. See [Microsoft's navigator guide](https://learn.microsoft.com/en-us/power-bi/create-reports/button-navigators). Navigation update captures are in `screenshots/navigation/`.

## Model and filter contract

- Purchase date and customer state slicers belong to synchronized groups on the five business pages.
- Category and seller filters apply to item-level analysis on Sales & Sellers. They do not propagate to the independent order and payment facts.
- Payment method filters payment records on Payments.
- Overview charts have cross-filter interactions disabled; use its slicers to compare KPIs across facts.
- Data Health is independent of business slicers. It shows successful Gold load history and current fact counts, not detailed DQ outcomes or failed pipeline runs.
- Order value includes freight. Average order value uses orders with items. Payment value is a separate metric.
- Repeat customers have more than one order within the selected period. Customer geography uses the current dimension record.
- Delivery analysis uses purchase date. Late delivery rate excludes unknown lateness; average delivery days excludes missing and negative values.

The shared semantic model is unchanged. `definition/reportExtensions.json` contains 21 report-local measures for compact currency cards, repeat customers, payment metrics and load monitoring. Definitions are also recorded in `build-manifest.json`.

## Verification — 18 September 2026

PBIR validation succeeded with **0 errors and 0 warnings**; see `validation.json`. All six pages were rendered in the connected Power BI Desktop instance and visually inspected. Captures are in `screenshots/final/`. Larger category lists and detail matrices use native scrollbars.

Observed unfiltered values:

| Metric | Value |
| --- | ---: |
| Total orders | 99,441 |
| Ordering customers | 96,096 |
| Order value including freight | R$15,843,553.24 |
| Merchandise value | R$13,591,643.70 |
| Freight value | R$2,251,909.54 |
| Order items | 112,650 |
| Payment value | R$16,008,872.12 |
| Payment records | 103,886 |
| Repeat customers in the full period | 2,997 |
| Late delivery rate | 6.77% |

These are rendering checks, not a new SQL reconciliation. Schema validation does not prove interactive behavior. Remaining acceptance checks: select a state and date range, confirm synchronized slicers across pages, test category/seller and payment-method scope, exercise Reset filters and navigation, then compare the filtered results with SQL.

RLS roles, role membership tests, publishing and sharing have not been completed in this report build. Stage 8 remains open until those checks and deployment steps are complete.

## Editing and regeneration

`build-report.cjs` is the reproducible layout source. From this folder, run:

```powershell
node .\build-report.cjs
```

Regeneration overwrites generated page visuals, theme and report-local measures. Preserve any manual Desktop edits before running it. Validate PBIR again and reload Desktop after regeneration. The report connection comes from the existing `definition.pbir`.

The local authoring tools are installed under the workspace root at `.tools/powerbi/node_modules/.bin/`; use the `.cmd` launchers on Windows. The blank starting report is preserved in `_before_adminlte_20260918`. The approved design brief is in `_brief/report-spec.md`.
