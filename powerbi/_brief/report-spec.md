# Olist Analytics — approved AdminLTE design

Approved in conversation: use AdminLTE v4 Dashboard v2 as the primary layout, Dashboard v3 for sales detail; implement six pages on the existing Fabric semantic model.

Design Brief:
  name: Olist Commerce Analytics
  source: https://github.com/ColorlibHQ/AdminLTE
  reference: https://adminlte.io/themes/v4/index2.html
  audience: business leaders and analysts
  canvas: 1600 x 900
  identity: dark sidebar, light canvas, white analytical panels, blue primary accent
  typography: Segoe UI
  colors: {sidebar: '#212529', background: '#F4F6F9', primary: '#0D6EFD', teal: '#087F8C', warning: '#AD6500', negative: '#C0392B'}
  pages: [Overview, Sales & Sellers, Customers, Delivery & Reviews, Payments, Data Health]
  connection: live to SM_Olist_Analytics / WS_Olist_Demo

## Interaction and metric contract
- Date and customer-state slicers affect all business facts; sync them across the five business pages.
- Category and seller belong on Sales only. Do not imply that these dimensions filter orders or payments.
- Overview analytical charts do not cross-filter other panels; use global slicers to compare a consistent scope.
- AOV includes freight and uses orders with items as denominator.
- Customer repeat metrics refer to orders within the selected period, across all order statuses.
- Payment installments are averaged at payment-record grain, not customer/order grain.
- Latest audit metrics use one deterministic latest GoldLoadAudit record (completed_at, then gold_run_id); audit history is separate from current business filters.
- Report-local extension measures supply missing metrics without changing the shared model.
- No fabricated profit, conversion, targets, RLS success, or DQ pass/fail indicators.

## Delivery and verification
PBIR project under powerbi/RPT_Olist_Analytics.Report. Validate with Microsoft authoring CLI, reload Desktop PID identified from status, visually review all six pages and retain screenshots. Fabric publishing/RLS and consumer testing remain subsequent steps; this build does not assign user access.
