const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const root = path.join(__dirname, 'RPT_Olist_Analytics.Report');
const def = path.join(root, 'definition');
const id = s => crypto.createHash('sha256').update(s).digest('hex').slice(0,20);
const write = (p,v) => {fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,JSON.stringify(v,null,2)+'\n');};
const read = p => JSON.parse(fs.readFileSync(p,'utf8').replace(/^﻿/,''));
const lit = v => ({expr:{Literal:{Value:typeof v==='boolean'?String(v):typeof v==='number'?v+'D':"'"+v.replace(/'/g,"''")+"'"}}});
const int = v => ({expr:{Literal:{Value:v+'L'}}});
const fill = c => ({solid:{color:lit(c)}});
const obj = (properties,selector) => [{properties,...(selector?{selector:{id:selector}}:{})}];
const dual = properties => [{properties},{properties,selector:{id:'default'}}];
const C={bg:'#F4F6F9',nav:'#212529',blue:'#0D6EFD',teal:'#087F8C',red:'#C0392B',amber:'#AD6500',ink:'#212529',muted:'#5B6573',line:'#DEE2E6',white:'#FFFFFF'};
const measureTables={};
for(const n of ['Merchandise Value','Freight Value','Order Value Including Freight','Total Order Items','Orders With Items','Average Order Value']) measureTables[n]='FactOrderItem';
for(const n of ['Total Orders','Ordering Customers','Delivered Orders','Canceled Orders','Cancellation Rate','Delivery SLA Eligible Orders','Late Delivered Orders','Late Delivery Rate','Average Delivery Days','Average Review Score','Reviewed Orders','Review Coverage','Delivered Orders by Delivery Date']) measureTables[n]='FactOrders';
measureTables['Payment Value']='FactPayments';
const extensions=[];
function ext(table,name,expression,formatString,dataType='Double',description=''){
  measureTables[name]=table;
  extensions.push({table,name,expression,formatString,dataType,description,displayFolder:'Report metrics'});
}
const cardMoney={};
for(const [n,expr] of [['Order Value Including Freight','SUM(FactOrderItem[item_gmv])'],['Merchandise Value','SUM(FactOrderItem[price])'],['Freight Value','SUM(FactOrderItem[freight_value])'],['Average Order Value','DIVIDE(SUM(FactOrderItem[item_gmv]),DISTINCTCOUNT(FactOrderItem[order_id]))'],['Payment Value','SUM(FactPayments[payment_value])']]){
  const name='KPI '+n;cardMoney[n]=name;
  ext(measureTables[n],name,`VAR v = ${expr} RETURN IF ( ISBLANK(v), BLANK(), "R$ " & SWITCH ( TRUE(), ABS(v) >= 1000000, FORMAT(v/1000000,"0.00") & "M", ABS(v) >= 1000, FORMAT(v/1000,"0.00") & "K", FORMAT(v,"0.00") ) )`,'','Text','Display-only compact BRL value; charts use the numeric model measure.');
}
ext('FactOrders','Repeat Customers (Period)','COUNTROWS ( FILTER ( VALUES ( FactOrders[customer_key] ), NOT ISBLANK ( FactOrders[customer_key] ) && CALCULATE ( COUNTROWS ( FactOrders ) ) > 1 ) )','#,0','Integer','Customers with more than one order within current filters, including all statuses.');
ext('FactOrders','Repeat Rate (Period)','DIVIDE ( COUNTROWS ( FILTER ( VALUES ( FactOrders[customer_key] ), NOT ISBLANK ( FactOrders[customer_key] ) && CALCULATE ( COUNTROWS ( FactOrders ) ) > 1 ) ), DISTINCTCOUNT ( FactOrders[customer_key] ) )','0.0%');
ext('FactOrders','Orders per Customer','DIVIDE ( COUNTROWS ( FactOrders ), DISTINCTCOUNT ( FactOrders[customer_key] ) )','0.00');
ext('FactOrders','On-Time Review','CALCULATE ( AVERAGE ( FactOrders[review_score] ), KEEPFILTERS ( FactOrders[order_status] = "delivered" ), KEEPFILTERS ( NOT ISBLANK ( FactOrders[is_late] ) ), KEEPFILTERS ( FactOrders[is_late] = 0 ) )','0.00');
ext('FactOrders','Late Review','CALCULATE ( AVERAGE ( FactOrders[review_score] ), KEEPFILTERS ( FactOrders[order_status] = "delivered" ), KEEPFILTERS ( FactOrders[is_late] = 1 ) )','0.00');
ext('FactPayments','Paying Orders','DISTINCTCOUNT ( FactPayments[order_id] )','#,0','Integer');
ext('FactPayments','Payment Records','COUNTROWS ( FactPayments )','#,0','Integer');
ext('FactPayments','Average Installments','AVERAGE ( FactPayments[payment_installments] )','0.00','Double','Average per payment record, not per order.');
ext('GoldLoadAudit','Last Gold Load','MAXX ( ALL ( GoldLoadAudit ), GoldLoadAudit[completed_at] )','dd MMM yyyy HH:mm','DateTime');
for(const [name,col] of [['Latest Gold Orders','order_rows'],['Latest Gold Items','item_rows'],['Latest Gold Payments','payment_rows']])
  ext('GoldLoadAudit',name,`MAXX ( TOPN ( 1, ALL ( GoldLoadAudit ), GoldLoadAudit[completed_at], DESC, GoldLoadAudit[gold_run_id], DESC ), GoldLoadAudit[${col}] )`,'#,0','Integer');
ext('GoldLoadAudit','Successful Gold Loads','COUNTROWS ( ALL ( GoldLoadAudit ) )','#,0','Integer');
ext('GoldLoadAudit','Current Order Rows','COUNTROWS ( FactOrders )','#,0','Integer');
ext('GoldLoadAudit','Current Item Rows','COUNTROWS ( FactOrderItem )','#,0','Integer');
ext('GoldLoadAudit','Current Payment Rows','COUNTROWS ( FactPayments )','#,0','Integer');
const extNames=new Set(extensions.map(x=>x.name));
write(path.join(def,'reportExtensions.json'),{$schema:'https://developer.microsoft.com/json-schemas/fabric/item/report/definition/reportExtension/1.0.0/schema.json',name:'extension',entities:[...new Set(extensions.map(x=>x.table))].map(t=>({name:t,measures:extensions.filter(x=>x.table===t).map(({table,...m})=>m)}))});
const column=(t,c)=>({Column:{Expression:{SourceRef:{Entity:t}},Property:c}});
const measure=n=>({Measure:{Expression:{SourceRef:{Entity:measureTables[n],...(extNames.has(n)?{Schema:'extension'}:{})}},Property:n}});
const projection=(field,ref,native,display)=>({field,queryRef:ref,nativeQueryRef:native,...(display?{displayName:display}:{})});
const mp=(n,label)=>projection(measure(n),(extNames.has(n)?'extension.':'')+measureTables[n]+'.'+n,n,label);
const cp=(t,c,label)=>projection(column(t,c),t+'.'+c,c,label);
const ap=(t,c,fn,label)=>projection({Aggregation:{Expression:column(t,c),Function:fn}},`${['Sum','Avg','Count','Min','Max'][fn]}(${t}.${c})`,`${['Sum','Average','Count','Min','Max'][fn]} of ${c}`,label);
function chrome(title,bg=C.white,pad=16){return {
  title:obj({show:lit(!!title),text:lit(title||''),fontSize:lit(13),fontFamily:lit('Segoe UI Semibold'),fontColor:fill(C.ink),titleWrap:lit(false)}),
  subTitle:obj({show:lit(false)}),
  background:obj({show:lit(!!bg),color:fill(bg||C.white),transparency:lit(0)}),
  border:obj({show:lit(!!bg),color:fill(C.line),radius:lit(5),width:lit(1)}),
  padding:obj({top:lit(pad),bottom:lit(pad),left:lit(pad),right:lit(pad)}),
  visualHeader:obj({show:lit(false)}),
  general:obj({altText:lit(title||'Report navigation or annotation'),keepLayerOrder:lit(true)})
};}
const pageNames=['Overview','Sales & Sellers','Customers','Delivery & Reviews','Payments','Data Health'];
const pageIds=pageNames.map((n,i)=>i===0?'9b2921901624d7ca2562':id('olist-page-'+n));
let current,visuals,seq;
function add(type,key,x,y,w,h,queryState,objects={},vco=chrome(''),extra={}){
  const name=id(current.name+'-'+key);
  const v={$schema:'https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.9.0/schema.json',name,position:{x,y,z:++seq*1000,width:w,height:h,tabOrder:seq*1000},visual:{visualType:type,...(queryState?{query:{queryState}}:{}),objects,visualContainerObjects:vco,...extra}};
  visuals.push(v);return v;
}
function text(key,value,x,y,w,h,size=14,color=C.ink,bold=false){return add('textbox',key,x,y,w,Math.max(h,Math.ceil(size*1.6)),null,{general:obj({paragraphs:[{textRuns:[{value,textStyle:{fontFamily:bold?'Segoe UI Semibold':'Segoe UI',fontSize:size+'px',color}}],horizontalTextAlignment:'left'}]})},chrome('',null,0));}
function rect(key,x,y,w,h,color){return add('shape',key,x,y,w,h,null,{shape:obj({tileShape:lit('rectangle')},'default'),fill:obj({show:lit(true),fillColor:fill(color),transparency:lit(0)},'default'),outline:obj({show:lit(false)},'default')},chrome('',null,0));}
function button(key,label,x,y,w,h,action,dest,bg=C.blue){const vco=chrome('',bg,0);vco.border=obj({show:lit(false),radius:lit(4)});vco.visualLink=obj({show:lit(true),type:lit(action),...(dest?{navigationSection:lit(dest)}:{})});return add('actionButton',key,x,y,w,h,null,{text:obj({show:lit(true),text:lit(label),fontColor:fill(C.white),fontSize:lit(11),fontFamily:lit('Segoe UI Semibold')},'default'),fill:obj({show:lit(true),fillColor:fill(bg),transparency:lit(0)},'default'),outline:obj({show:lit(false)},'default'),icon:obj({show:lit(false)},'default')},vco);}
function slicer(key,t,c,label,x,y,w,mode='Dropdown',sync){const v=add('slicer',key,x,y,w,84,{Values:{projections:[cp(t,c)]}},{data:obj({mode:lit(mode)}),header:obj({show:lit(true),text:lit(label),textSize:lit(10),fontColor:fill(C.muted)}),items:obj({textSize:lit(11),fontColor:fill(C.ink)}),selection:obj({selectAllCheckboxEnabled:lit(true),singleSelect:lit(false)}),...(mode==='Between'?{date:obj({textSize:lit(10)}),slider:obj({show:lit(false)})}:{})},chrome('',C.white,10));if(sync)v.visual.syncGroup={groupName:sync,fieldChanges:true,filterChanges:true};return v;}
function kpi(key,n,label,x,y,w=316,h=118,color=C.blue,format){
  // 26pt value (39px) + 11pt label (17px) + 6px spacing + 24px padding = 86px < 118px.
  const v=add('cardVisual',key,x,y,w,h,{Data:{projections:[mp(cardMoney[n]||n,label)]}},{
    value:dual({fontSize:lit(26),fontFamily:lit('Segoe UI Semibold'),fontColor:fill(color),horizontalAlignment:lit('left'),labelDisplayUnits:lit(1),...(format?{customFormatString:lit(format)}:{})}),
    label:dual({show:lit(true),text:lit(label),fontSize:lit(11),fontColor:fill(C.muted),position:lit('belowValue'),horizontalAlignment:lit('left'),textWrap:lit(false)}),
    layout:dual({paddingUniform:int(0),calloutSize:lit(100)}),outline:obj({show:lit(false)},'default'),fillCustom:obj({show:lit(false)},'default'),accentBar:obj({show:lit(true),color:fill(color),position:lit('Left'),width:lit(3)},'default')
  },chrome('',C.white,12));return v;
}
function chart(key,title,type,t,c,m,x,y,w,h,color=C.blue,sortByValue=false){const v=add(type,key,x,y,w,h,{Category:{projections:[cp(t,c)]},Y:{projections:[mp(m)]}},{dataPoint:obj({defaultColor:fill(color)}),legend:obj({show:lit(false)}),categoryAxis:obj({show:lit(true),showAxisTitle:lit(false),fontSize:lit(10),labelColor:fill(C.muted),...(type==='clusteredBarChart'?{preferredCategoryWidth:lit(18),innerPadding:int(25)}:{})}),valueAxis:obj({show:lit(true),showAxisTitle:lit(false),fontSize:lit(10),labelColor:fill(C.muted),gridlineColor:fill('#EDF0F3')}),labels:obj({show:lit(type==='clusteredBarChart'),fontSize:lit(9),color:fill(C.ink),labelPrecision:int(1)})},chrome(title));v.visual.query.sortDefinition={sort:[{field:sortByValue?measure(m):column(t,c),direction:sortByValue?'Descending':'Ascending'}],isDefaultSort:true};return v;}
function top(v,t,c,ft,fc,count=8){
 const col={Column:{Expression:{SourceRef:{Source:'d'}},Property:c}};
 v.filterConfig={filters:[{name:'Filter'+id(v.name+'top'),field:column(t,c),type:'TopN',howCreated:'User',filter:{Version:2,From:[{Name:'subquery',Expression:{Subquery:{Query:{Version:2,From:[{Name:'d',Entity:t,Type:0},{Name:'f',Entity:ft,Type:0}],Select:[{...col,Name:'field'}],OrderBy:[{Direction:2,Expression:{Aggregation:{Expression:{Column:{Expression:{SourceRef:{Source:'f'}},Property:fc}},Function:0}}}],Top:count}}},Type:2},{Name:'d',Entity:t,Type:0}],Where:[{Condition:{In:{Expressions:[col],Table:{SourceRef:{Source:'subquery'}}}}}]}}]};return v;
}
function matrix(key,title,t,c,measures,x,y,w,h){return add('pivotTable',key,x,y,w,h,{Rows:{projections:[cp(t,c)]},Values:{projections:measures.map(n=>typeof n==='string'?mp(n):n)}},{columnHeaders:obj({fontSize:lit(11),fontColor:fill(C.ink),backColor:fill('#EEF2F6'),autoSizeColumnWidth:lit(true),columnAdjustment:lit('growToFit'),wordWrap:lit(true)}),rowHeaders:obj({fontSize:lit(10),fontColor:fill(C.ink),wordWrap:lit(false)}),values:obj({fontSize:lit(10),fontColorPrimary:fill(C.ink),fontColorSecondary:fill(C.ink),backColorPrimary:fill(C.white),backColorSecondary:fill('#F8FAFC')}),grid:obj({rowPadding:lit(3),gridVertical:lit(false),gridHorizontal:lit(true),gridHorizontalColor:fill('#EDF0F3')})},{...chrome(title),stylePreset:obj({name:lit('None')})});}
const X=224,G=16,W=1352;
const subtitles=[
 'Business performance across sales, customers and fulfillment',
 'Product mix and seller contribution — item-level analysis',
 'Customer geography and repeat ordering within the selected period',
 'Delivery reliability and the customer review experience',
 'Payment mix and installments — payment-record analysis',
 'Latest successful Gold load and historical load evidence'
];
for(let i=0;i<pageNames.length;i++){
 current={$schema:'https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.1.0/schema.json',name:pageIds[i],displayName:pageNames[i],displayOption:'FitToPage',width:1600,height:900,objects:{background:obj({color:fill(C.bg),transparency:lit(0)})}};visuals=[];seq=0;
 rect('sidebar',0,0,200,900,C.nav);rect('brand-accent',22,29,5,39,C.blue);
 text('brand','OLIST',39,26,146,39,27,C.white,true);text('brand-sub','COMMERCE ANALYTICS',22,76,170,28,11,'#ADB5BD');
 text('nav-label','WORKSPACE',22,126,164,27,10,'#ADB5BD');
 add('pageNavigator','navigation',12,167,176,338,null,{
  layout:obj({orientation:lit(1),rowCount:int(6),columnCount:int(1),cellPadding:int(12)}),
  text:['default','hover','selected','disabled'].map(state=>({selector:{id:state},properties:{show:lit(true),fontColor:fill(C.white),fontFamily:lit('Segoe UI Semibold'),fontSize:lit(12),horizontalAlignment:lit('left'),leftMargin:int(12)}})),
  fill:['default','hover','selected'].map(state=>({selector:{id:state},properties:{show:lit(true),fillColor:fill(state==='selected'?C.blue:state==='hover'?'#343A40':C.nav),transparency:lit(0)}})),
  outline:['default','hover','selected'].map(state=>({selector:{id:state},properties:{show:lit(false),weight:lit(0)}})),shape:obj({tileShape:lit('rectangleRounded'),rectangleRoundedCurve:int(4)}),pages:obj({showByDefault:lit(true),showHiddenPages:lit(false),showTooltipPages:lit(false)})
 },chrome('',null,0));
 text('nav-footer','BRAZIL / OLIST',22,795,168,27,11,'#CED4DA');text('nav-footer2','Sales • Experience • Operations',22,824,165,48,11,'#ADB5BD');
 text('title',pageNames[i].toUpperCase(),X,24,690,43,28,C.ink,true);
 text('subtitle',subtitles[i],X,69,W,28,13,C.muted);
 const home=button('home','Home',1426,28,150,42,'PageNavigation',pageIds[0]);
 home.visual.objects.text=[{properties:{show:lit(true),text:lit('Home')}},...['default','hover','selected','disabled'].map(state=>({selector:{id:state},properties:{show:lit(true),text:lit('Home'),fontColor:fill(C.white),fontSize:lit(11),fontFamily:lit('Segoe UI Semibold'),horizontalAlignment:lit('center'),verticalAlignment:lit('middle')}}))];
 home.visual.visualContainerObjects.visualLink[0].properties.tooltip=lit('Return to Overview');
 home.visual.visualContainerObjects.general[0].properties.altText=lit('Home: return to Overview');
 if(i!==5){slicer('date','DimDate','full_date','Purchase date',X,108,390,'Between','OlistPurchaseDate');slicer('state','DimCustomer','state_code','Customer state',630,108,230,'Dropdown','OlistCustomerState');button('reset','Reset filters',1426,128,150,42,'ClearAllSlicers');}
 const note=i===5?'Audit records describe successful Gold builds. This page does not certify DQ results or pipeline failures.':i===1?'Category and seller filters apply to item metrics. Order value includes freight; AOV uses orders with items.':i===2?'Repeat customers = more than one order in the selected period. Customer location uses the current dimension record.':i===3?'Date filter uses purchase date. Delivery SLA excludes unknown lateness; delivery-day averages exclude missing/negative values.':i===4?'Payment value is a separate metric from item value. Average installments is calculated per payment record.':'Order value includes freight. All order statuses are included. AOV denominator: orders with items.';
 text('footnote',note,X,858,W,30,11,C.muted);
 if(i===0){
  kpi('value','Order Value Including Freight','Order value incl. freight (BRL)',X,212,326,118,C.blue,'"R$ "0.00,,"M"');
  kpi('orders','Total Orders','Total orders',566,212,326,118,C.teal,'#,0');
  kpi('customers','Ordering Customers','Ordering customers',908,212,326,118,C.blue,'#,0');
  kpi('aov','Average Order Value','Average order value (BRL)',1250,212,326,118,C.teal,'"R$ "#,0.00');
  chart('trend','MONTHLY PERFORMANCE · ORDER VALUE (BRL)','lineChart','DimDate','year_month','Order Value Including Freight',X,350,870,235);
  chart('status','ORDER STATUS','clusteredBarChart','FactOrders','order_status','Total Orders',1110,350,466,235,C.teal,true);
  kpi('late','Late Delivery Rate','Late delivery rate',X,603,438,96,C.red,'0.0%');
  kpi('days','Average Delivery Days','Average delivery days',678,603,438,96,C.amber,'0.0');
  kpi('review','Average Review Score','Average review score / 5',1132,603,444,96,C.teal,'0.00');
  top(chart('categories','TOP 5 CATEGORIES · ORDER VALUE','clusteredBarChart','DimProduct','category_en','Order Value Including Freight',X,718,668,125,C.blue,true),'DimProduct','category_en','FactOrderItem','item_gmv',5);
  top(chart('states','TOP 5 CUSTOMER STATES · ORDER VALUE','clusteredBarChart','DimCustomer','state_code','Order Value Including Freight',908,718,668,125,C.blue,true),'DimCustomer','state_code','FactOrderItem','item_gmv',5);
 }
 if(i===1){
  slicer('category','DimProduct','category_en','Category',876,108,260);slicer('seller-state','DimSeller','state_code','Seller state',1152,108,258);
  kpi('merch','Merchandise Value','Merchandise value (BRL)',X,212,326,118,C.blue,'"R$ "0.00,,"M"');kpi('freight','Freight Value','Freight value (BRL)',566,212,326,118,C.teal,'"R$ "0.00,,"M"');kpi('items','Total Order Items','Order items',908,212,326,118,C.blue,'#,0');kpi('itemorders','Orders With Items','Orders with items',1250,212,326,118,C.teal,'#,0');
  top(chart('categories','TOP 8 CATEGORIES · ORDER VALUE (BRL)','clusteredBarChart','DimProduct','category_en','Order Value Including Freight',X,350,668,285,C.blue,true),'DimProduct','category_en','FactOrderItem','item_gmv');
  chart('sales-trend','MONTHLY MERCHANDISE VALUE (BRL)','lineChart','DimDate','year_month','Merchandise Value',908,350,668,285,C.blue);
  matrix('seller-detail','SELLER PERFORMANCE · SELECT A ROW TO EXPLORE','DimSeller','seller_id',['Orders With Items','Total Order Items','Merchandise Value','Freight Value','Average Order Value'],X,653,W,190);
 }
 if(i===2){
  kpi('customers','Ordering Customers','Ordering customers',X,212,326,118,C.blue,'#,0');kpi('repeat','Repeat Customers (Period)','Repeat customers',566,212,326,118,C.teal,'#,0');kpi('repeat-rate','Repeat Rate (Period)','Repeat customer rate',908,212,326,118,C.teal,'0.0%');kpi('frequency','Orders per Customer','Orders per customer',1250,212,326,118,C.blue,'0.00');
  chart('geo','CUSTOMERS BY STATE','clusteredBarChart','DimCustomer','state_code','Ordering Customers',X,350,668,285,C.blue,true);
  chart('customer-trend','ORDERING CUSTOMERS BY MONTH','lineChart','DimDate','year_month','Ordering Customers',908,350,668,285,C.blue);
  matrix('state-detail','CUSTOMER GEOGRAPHY · CURRENT LOCATION','DimCustomer','state_code',['Ordering Customers','Total Orders','Repeat Customers (Period)','Repeat Rate (Period)','Orders per Customer'],X,653,W,190);
 }
 if(i===3){
  kpi('delivered','Delivered Orders','Delivered orders',X,212,326,118,C.blue,'#,0');kpi('late','Late Delivery Rate','Late delivery rate',566,212,326,118,C.red,'0.0%');kpi('days','Average Delivery Days','Average delivery days',908,212,326,118,C.amber,'0.0');kpi('review','Average Review Score','Average review score / 5',1250,212,326,118,C.teal,'0.00');
  chart('late-trend','LATE DELIVERY RATE BY PURCHASE MONTH','lineChart','DimDate','year_month','Late Delivery Rate',X,350,668,275,C.red);
  chart('review-dist','REVIEW SCORE DISTRIBUTION','clusteredColumnChart','FactOrders','review_score','Reviewed Orders',908,350,668,275,C.teal);
  matrix('delivery-state','DELIVERY BY CUSTOMER STATE','DimCustomer','state_code',['Delivery SLA Eligible Orders','Late Delivery Rate','Average Delivery Days','Average Review Score'],X,643,870,200);
  kpi('ontime-review','On-Time Review','Review · on-time delivery',1110,643,225,96,C.teal,'0.00');kpi('late-review','Late Review','Review · late delivery',1351,643,225,96,C.red,'0.00');
  kpi('review-coverage','Review Coverage','Review coverage',1110,755,466,88,C.blue,'0.0%');
 }
 if(i===4){
  slicer('payment-type','FactPayments','payment_type','Payment method',876,108,300);
  kpi('payment','Payment Value','Payment value (BRL)',X,212,326,118,C.blue,'"R$ "0.00,,"M"');kpi('pay-orders','Paying Orders','Orders with payments',566,212,326,118,C.teal,'#,0');kpi('pay-records','Payment Records','Payment records',908,212,326,118,C.blue,'#,0');kpi('installments','Average Installments','Installments per payment',1250,212,326,118,C.teal,'0.00');
  chart('method','PAYMENT VALUE BY METHOD (BRL)','clusteredBarChart','FactPayments','payment_type','Payment Value',X,350,668,285,C.blue,true);
  chart('payment-trend','PAYMENT VALUE BY PURCHASE MONTH (BRL)','lineChart','DimDate','year_month','Payment Value',908,350,668,285,C.blue);
  chart('installment-dist','PAYMENT RECORDS BY INSTALLMENTS','clusteredColumnChart','FactPayments','payment_installments','Payment Records',X,653,668,190,C.teal);
  matrix('method-detail','PAYMENT METHOD DETAILS','FactPayments','payment_type',['Payment Value','Paying Orders','Average Installments'],908,653,668,190);
 }
 if(i===5){
  text('audit-context','GOLD LOAD MONITORING',X,119,650,36,17,C.teal,true);
  text('audit-help','Latest-load figures use the most recent successful audit record, independent of business-page filters.',X,164,W,30,13,C.muted);
  kpi('lastload','Last Gold Load','Last successful Gold load',X,212,440,118,C.blue,'dd MMM yyyy HH:mm');kpi('audit-orders','Latest Gold Orders','Orders in latest load',680,212,288,118,C.teal,'#,0');kpi('audit-items','Latest Gold Items','Items in latest load',984,212,288,118,C.blue,'#,0');kpi('audit-payments','Latest Gold Payments','Payments in latest load',1288,212,288,118,C.teal,'#,0');
  matrix('history','SUCCESSFUL GOLD LOAD HISTORY','GoldLoadAudit','completed_at',[ap('GoldLoadAudit','order_rows',4,'Orders'),ap('GoldLoadAudit','item_rows',4,'Items'),ap('GoldLoadAudit','payment_rows',4,'Payments')],X,350,W,265);
  kpi('currentorders','Current Order Rows','Current FactOrders rows',X,633,438,118,C.blue,'#,0');kpi('currentitems','Current Item Rows','Current FactOrderItem rows',678,633,438,118,C.blue,'#,0');kpi('currentpayments','Current Payment Rows','Current FactPayments rows',1132,633,444,118,C.blue,'#,0');
  text('audit-limits','Monitoring scope: successful Gold builds and current fact row counts. Detailed DQ tests and failed pipeline runs require their own audit sources.',X,777,W,56,14,C.muted);
 }
 // Overview is intentionally slicer-driven: mixed-grain charts must not imply global cross-filtering.
 // Audit panels remain independent so selecting historical runs never changes latest/current cards.
 if(i===0||i===5){current.visualInteractions=[];const sources=visuals.filter(v=>['lineChart','clusteredBarChart','clusteredColumnChart','pivotTable'].includes(v.visual.visualType));for(const a of sources)for(const b of visuals)if(a!==b&&b.visual.query)current.visualInteractions.push({source:a.name,target:b.name,type:'NoFilter'});}
 if(i===0){
  for(const v of visuals){const p=v.position;if(p.y===212){p.y=204;p.height=104;}else if(p.y===350){p.y=324;p.height=184;}else if(p.y===603){p.y=524;p.height=88;}else if(p.y===718){p.y=628;p.height=215;}}
 }
 if([1,2,4].includes(i)){for(const v of visuals){if(v.position.y===350)v.position.height=230;if(v.position.y===653){v.position.y=596;v.position.height=247;}}}
 const dir=path.join(def,'pages',current.name);
 // Remove only obsolete generated visual files under this exact report page.
 const visualDir=path.join(dir,'visuals');
 if(fs.existsSync(visualDir))for(const old of fs.readdirSync(visualDir)){if(!visuals.some(v=>v.name===old)){const file=path.join(visualDir,old,'visual.json');if(fs.existsSync(file))fs.unlinkSync(file);fs.rmdirSync(path.join(visualDir,old));}}
 write(path.join(dir,'page.json'),current);for(const v of visuals)write(path.join(dir,'visuals',v.name,'visual.json'),v);
}
write(path.join(def,'pages','pages.json'),{$schema:'https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.0.0/schema.json',pageOrder:pageIds,activePageName:pageIds[0]});
const themeName='OlistAdminLTE-20260918a.json';
write(path.join(root,'StaticResources','RegisteredResources',themeName),{name:themeName,dataColors:[C.blue,C.teal,C.amber,C.red,'#6F42C1','#495057'],background:C.white,foreground:C.ink,tableAccent:C.blue,good:C.teal,bad:C.red,neutral:C.amber,textClasses:{label:{fontFace:'Segoe UI',fontSize:11,color:C.muted},title:{fontFace:'Segoe UI Semibold',fontSize:14,color:C.ink},callout:{fontFace:'Segoe UI Semibold',fontSize:26,color:C.ink}},visualStyles:{'*':{'*':{visualHeader:[{show:false}]}},cardVisual:{'*':{padding:[{paddingUniform:0}],layout:[{paddingUniform:0}],spacing:[{verticalSpacing:6}]}}}});
const report=read(path.join(def,'report.json'));report.objects.outspacePane=obj({visible:lit(false),expanded:lit(false)});report.themeCollection.customTheme={name:themeName,type:'RegisteredResources',reportVersionAtImport:{visual:'2.12.0',report:'3.4.0',page:'2.3.1'}};report.resourcePackages=report.resourcePackages.filter(p=>p.name!=='RegisteredResources');report.resourcePackages.push({name:'RegisteredResources',type:'RegisteredResources',items:[{name:themeName,path:themeName,type:'CustomTheme'}]});write(path.join(def,'report.json'),report);
write(path.join(__dirname,'build-manifest.json'),{pages:pageNames.map((name,i)=>({name,id:pageIds[i]})),reportLocalMeasures:extensions.map(x=>({table:x.table,name:x.name,expression:x.expression})),sourceModel:'SM_Olist_Analytics',reference:'AdminLTE v4 Dashboard v2',generatedAt:new Date().toISOString()});
console.log('Generated six report pages and '+extensions.length+' report-local measures.');
