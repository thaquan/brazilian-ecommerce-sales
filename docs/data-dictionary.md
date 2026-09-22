# Data dictionary

Schema vật lý trích từ `fabric/sql/02_create_gold.sql`. DDL không khai báo ràng buộc PK/FK vật lý; khóa dưới đây là khóa logic được kiểm tra bằng validation. Quan hệ semantic model không thay thế constraint SQL.

ZIP là chuỗi để giữ số 0 đầu. Tiền có đơn vị BRL. delivered/estimated date có thể thiếu; is_late thiếu không được coi là on-time. GoldLoadAudit là bảng kỹ thuật ngoài 7 bảng nghiệp vụ.

## DimDate

Grain và khóa logic: Một ngày; date_key.

| Cột | Kiểu | Null |
|---|---|---|
| date_key | int | Không |
| full_date | date | Không |
| year | int | Có |
| quarter | int | Có |
| month_number | int | Có |
| month_name | varchar(20) | Có |
| year_month | varchar(7) | Có |
| week_number | int | Có |
| day_of_week | int | Có |
| day_name | varchar(20) | Có |
| is_weekend | int | Có |

## DimCustomer

Grain và khóa logic: Một customer_unique_id, vị trí hiện tại; customer_key.

| Cột | Kiểu | Null |
|---|---|---|
| customer_key | bigint | Không |
| customer_unique_id | varchar(32) | Không |
| zip_code_prefix | varchar(5) | Có |
| city | varchar(300) | Có |
| state_code | varchar(2) | Có |
| latitude | float | Có |
| longitude | float | Có |

## DimProduct

Grain và khóa logic: Một product_id; product_key.

| Cột | Kiểu | Null |
|---|---|---|
| product_key | bigint | Không |
| product_id | varchar(32) | Không |
| category_pt | varchar(200) | Có |
| category_en | varchar(200) | Có |
| weight_g | int | Có |
| length_cm | int | Có |
| height_cm | int | Có |
| width_cm | int | Có |

## DimSeller

Grain và khóa logic: Một seller_id; seller_key.

| Cột | Kiểu | Null |
|---|---|---|
| seller_key | bigint | Không |
| seller_id | varchar(32) | Không |
| zip_code_prefix | varchar(5) | Có |
| city | varchar(300) | Có |
| state_code | varchar(2) | Có |
| latitude | float | Có |
| longitude | float | Có |

## FactOrders

Grain và khóa logic: Một order_id; order_key.

| Cột | Kiểu | Null |
|---|---|---|
| order_key | bigint | Không |
| order_id | varchar(32) | Không |
| purchase_date_key | int | Không |
| delivered_date_key | int | Có |
| estimated_date_key | int | Có |
| customer_key | bigint | Không |
| order_status | varchar(30) | Có |
| delivery_days | int | Có |
| delay_days | int | Có |
| is_late | int | Có |
| review_score | int | Có |

## FactOrderItem

Grain và khóa logic: Một (order_id, order_item_id); sales_key.

| Cột | Kiểu | Null |
|---|---|---|
| sales_key | bigint | Không |
| order_id | varchar(32) | Không |
| order_item_id | int | Không |
| purchase_date_key | int | Không |
| customer_key | bigint | Không |
| product_key | bigint | Không |
| seller_key | bigint | Không |
| price | decimal(18,2) | Không |
| freight_value | decimal(18,2) | Không |
| item_gmv | decimal(19,2) | Không |

## FactPayments

Grain và khóa logic: Một (order_id, payment_sequential); payment_key.

| Cột | Kiểu | Null |
|---|---|---|
| payment_key | bigint | Không |
| order_id | varchar(32) | Không |
| purchase_date_key | int | Không |
| customer_key | bigint | Không |
| payment_sequential | int | Không |
| payment_type | varchar(30) | Có |
| payment_installments | int | Có |
| payment_value | decimal(18,2) | Không |

## GoldLoadAudit

Grain và khóa logic: Một lượt build Gold thành công; gold_run_id.

| Cột | Kiểu | Null |
|---|---|---|
| gold_run_id | varchar(36) | Không |
| silver_run_id | varchar(36) | Không |
| completed_at | datetime2(6) | Không |
| order_rows | bigint | Không |
| item_rows | bigint | Không |
| payment_rows | bigint | Không |

## Ý nghĩa nghiệp vụ

`item_gmv = price + freight_value`; `review_score` là điểm đánh giá đã tổng hợp về cấp đơn ở Silver; xem notebook cho quy tắc chọn bản ghi. `delivery_days` và `delay_days` do Silver tính; `is_late` so ngày giao thực tế với ngày dự kiến ở mức ngày lịch. `purchase_date_key` là đường lọc ngày mặc định của cả ba fact. `customer_key` liên kết về customer_unique_id thay vì customer_id theo từng đơn.

## Đường quan hệ

DimCustomer.customer_key → cả ba fact.customer_key; DimDate.date_key → cả ba fact.purchase_date_key; DimProduct.product_key và DimSeller.seller_key → FactOrderItem; DimDate.date_key → FactOrders.delivered_date_key Inactive. Chiều lọc dimension → fact. estimated_date_key chỉ là thuộc tính fact trong model hiện tại.
