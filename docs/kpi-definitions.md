# KPI và DAX

Nguồn chính xác là TMDL của SQL model đã lưu. Các công thức dưới đây được trích nguyên văn từ source, không tự tính lại số liệu.

## Quy ước

- Merchandise Value: tổng giá hàng; Freight Value: tổng vận chuyển; Order Value Including Freight: tổng item_gmv.
- AOV chia Orders With Items; Total Orders gồm tất cả trạng thái.
- Payment Value được đối soát riêng với payments, không ép bằng giá trị order items.
- Delivered/SLA dùng trạng thái delivered; tỷ lệ trễ loại lateness thiếu; trung bình delivery loại thiếu và âm.
- Review trung bình bỏ BLANK theo AVERAGE; Review Coverage dùng tổng đơn làm mẫu số.
- Repeat Customers tính hơn một đơn trong context hiện tại; không phải lifetime.
- Các measure KPI dùng FORMAT là chuỗi hiển thị; dùng numeric base measure cho tính toán.

## Phạm vi bộ lọc

| Bộ lọc | Phạm vi |
|---|---|
| Ngày mua / customer state | Cả ba fact |
| Category / seller | FactOrderItem |
| Payment method | FactPayments |
| Ngày giao | Measure USERELATIONSHIP chuyên biệt |

## Danh mục công thức

### Merchandise Value

Bảng: `FactOrderItem`.

```dax
SUM(FactOrderItem[price])
```

### Freight Value

Bảng: `FactOrderItem`.

```dax
SUM(FactOrderItem[freight_value])
```

### Order Value Including Freight

Bảng: `FactOrderItem`.

```dax
SUM(FactOrderItem[item_gmv])
```

### Total Order Items

Bảng: `FactOrderItem`.

```dax
COUNTROWS(FactOrderItem)
```

### Orders With Items

Bảng: `FactOrderItem`.

```dax
DISTINCTCOUNT(FactOrderItem[order_id])
```

### Average Order Value

Bảng: `FactOrderItem`.

```dax
DIVIDE([Order Value Including Freight],[Orders With Items])
```

### KPI Order Value Including Freight

Bảng: `FactOrderItem`.

```dax
VAR v = SUM(FactOrderItem[item_gmv]) RETURN IF ( ISBLANK(v), BLANK(), "R$ " & SWITCH ( TRUE(), ABS(v) >= 1000000, FORMAT(v/1000000,"0.00") & "M", ABS(v) >= 1000, FORMAT(v/1000,"0.00") & "K", FORMAT(v,"0.00") ) )
```

### KPI Merchandise Value

Bảng: `FactOrderItem`.

```dax
VAR v = SUM(FactOrderItem[price]) RETURN IF ( ISBLANK(v), BLANK(), "R$ " & SWITCH ( TRUE(), ABS(v) >= 1000000, FORMAT(v/1000000,"0.00") & "M", ABS(v) >= 1000, FORMAT(v/1000,"0.00") & "K", FORMAT(v,"0.00") ) )
```

### KPI Freight Value

Bảng: `FactOrderItem`.

```dax
VAR v = SUM(FactOrderItem[freight_value]) RETURN IF ( ISBLANK(v), BLANK(), "R$ " & SWITCH ( TRUE(), ABS(v) >= 1000000, FORMAT(v/1000000,"0.00") & "M", ABS(v) >= 1000, FORMAT(v/1000,"0.00") & "K", FORMAT(v,"0.00") ) )
```

### KPI Average Order Value

Bảng: `FactOrderItem`.

```dax
VAR v = DIVIDE(SUM(FactOrderItem[item_gmv]),DISTINCTCOUNT(FactOrderItem[order_id])) RETURN IF ( ISBLANK(v), BLANK(), "R$ " & SWITCH ( TRUE(), ABS(v) >= 1000000, FORMAT(v/1000000,"0.00") & "M", ABS(v) >= 1000, FORMAT(v/1000,"0.00") & "K", FORMAT(v,"0.00") ) )
```

### Total Orders

Bảng: `FactOrders`.

```dax
COUNTROWS(FactOrders)
```

### Ordering Customers

Bảng: `FactOrders`.

```dax
DISTINCTCOUNT(FactOrders[customer_key])
```

### Delivered Orders

Bảng: `FactOrders`.

```dax
CALCULATE([Total Orders],KEEPFILTERS(FactOrders[order_status]="delivered"))
```

### Canceled Orders

Bảng: `FactOrders`.

```dax
CALCULATE([Total Orders],KEEPFILTERS(FactOrders[order_status]="canceled"))
```

### Cancellation Rate

Bảng: `FactOrders`.

```dax
DIVIDE([Canceled Orders],[Total Orders])
```

### Delivery SLA Eligible Orders

Bảng: `FactOrders`.

```dax
CALCULATE([Total Orders],KEEPFILTERS(FactOrders[order_status]="delivered"),KEEPFILTERS(NOT ISBLANK(FactOrders[is_late])))
```

### Late Delivered Orders

Bảng: `FactOrders`.

```dax
CALCULATE([Total Orders],KEEPFILTERS(FactOrders[order_status]="delivered"),KEEPFILTERS(FactOrders[is_late]=1))
```

### Late Delivery Rate

Bảng: `FactOrders`.

```dax
DIVIDE([Late Delivered Orders],[Delivery SLA Eligible Orders])
```

### Average Delivery Days

Bảng: `FactOrders`.

```dax
CALCULATE(AVERAGE(FactOrders[delivery_days]),KEEPFILTERS(FactOrders[order_status]="delivered"),KEEPFILTERS(NOT ISBLANK(FactOrders[delivery_days])),KEEPFILTERS(FactOrders[delivery_days]>=0))
```

### Average Review Score

Bảng: `FactOrders`.

```dax
AVERAGE(FactOrders[review_score])
```

### Reviewed Orders

Bảng: `FactOrders`.

```dax
COUNT(FactOrders[review_score])
```

### Review Coverage

Bảng: `FactOrders`.

```dax
DIVIDE([Reviewed Orders],[Total Orders])
```

### Delivered Orders by Delivery Date

Bảng: `FactOrders`.

```dax
CALCULATE([Delivered Orders],USERELATIONSHIP(FactOrders[delivered_date_key],DimDate[date_key]))
```

### Repeat Customers (Period)

Bảng: `FactOrders`.

```dax
COUNTROWS ( FILTER ( VALUES ( FactOrders[customer_key] ), NOT ISBLANK ( FactOrders[customer_key] ) && CALCULATE ( COUNTROWS ( FactOrders ) ) > 1 ) )
```

### Repeat Rate (Period)

Bảng: `FactOrders`.

```dax
DIVIDE ( COUNTROWS ( FILTER ( VALUES ( FactOrders[customer_key] ), NOT ISBLANK ( FactOrders[customer_key] ) && CALCULATE ( COUNTROWS ( FactOrders ) ) > 1 ) ), DISTINCTCOUNT ( FactOrders[customer_key] ) )
```

### Orders per Customer

Bảng: `FactOrders`.

```dax
DIVIDE ( COUNTROWS ( FactOrders ), DISTINCTCOUNT ( FactOrders[customer_key] ) )
```

### On-Time Review

Bảng: `FactOrders`.

```dax
CALCULATE ( AVERAGE ( FactOrders[review_score] ), KEEPFILTERS ( FactOrders[order_status] = "delivered" ), KEEPFILTERS ( NOT ISBLANK ( FactOrders[is_late] ) ), KEEPFILTERS ( FactOrders[is_late] = 0 ) )
```

### Late Review

Bảng: `FactOrders`.

```dax
CALCULATE ( AVERAGE ( FactOrders[review_score] ), KEEPFILTERS ( FactOrders[order_status] = "delivered" ), KEEPFILTERS ( FactOrders[is_late] = 1 ) )
```

### Payment Value

Bảng: `FactPayments`.

```dax
SUM(FactPayments[payment_value])
```

### KPI Payment Value

Bảng: `FactPayments`.

```dax
VAR v = SUM(FactPayments[payment_value]) RETURN IF ( ISBLANK(v), BLANK(), "R$ " & SWITCH ( TRUE(), ABS(v) >= 1000000, FORMAT(v/1000000,"0.00") & "M", ABS(v) >= 1000, FORMAT(v/1000,"0.00") & "K", FORMAT(v,"0.00") ) )
```

### Paying Orders

Bảng: `FactPayments`.

```dax
DISTINCTCOUNT ( FactPayments[order_id] )
```

### Payment Records

Bảng: `FactPayments`.

```dax
COUNTROWS ( FactPayments )
```

### Average Installments

Bảng: `FactPayments`.

```dax
AVERAGE ( FactPayments[payment_installments] )
```
