SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

clear buffer;

set feed off
set linesize 300
set pagesize 5000
set underline '='
set serveroutput on size 1000000
set trimspool on

set head off

------------＜タイトル行＞
SELECT
         '売上拠点コード'
  ||','||'拠点名'
  ||','||'納品者コード'
  ||','||'納品者名'
  ||','||'納品日'
  ||','||'顧客コード'
  ||','||'顧客名'
  ||','||'納品伝票番号'
  ||','||'カード売区分'
  ||','||'（伝票）売上金額'
  ||','||'（伝票）現金カード併用額'
  ||','||'（VD）現金売りトータル販売金額'
  ||','||'（VD）カードトータル販売金額'
  ||','||'（VD）総販売金額'
  ||','||'差額'
FROM  dual
;
select a.sales_base_code       || ',' ||
       a.base_name             || ',' ||
       a.dlv_by_code           || ',' ||
       a.full_name             || ',' ||
       a.delivery_date         || ',' ||
       a.ship_to_customer_code || ',' ||
       a.ACCOUNT_NAME          || ',' ||
       a.dlv_invoice_number    || ',' ||
       a.meaning               || ',' ||
       a.sale_amount_sum       || ',' ||
       a.Cash_And_Card         || ',' ||
       a.cash_total_sales_amt  || ',' ||
       a.card_total_sales_amt  || ',' ||
       a.total_sales_amt       || ',' ||
       a.difference
from  (
------------＜現金売上差異チェック＞
SELECT
   xseh.sales_base_code              as sales_base_code      -- 売上拠点コード
  ,xrsv.base_name                    as base_name            -- 拠点名
  ,xseh.dlv_by_code                  as dlv_by_code          -- 納品者コード
  ,xev.full_name                     as full_name            -- 納品者名
  ,xseh.delivery_date                as delivery_date        -- 納品日
--  ,xseh.hht_dlv_input_date              "HHT納品入力日時
--  ,xseh.order_no_hht                    "受注No(HHT)
--  ,xseh.digestion_ln_number             "受注No(HHT)枝番
  ,xseh.ship_to_customer_code        as ship_to_customer_code-- 顧客コード
  ,xca.ACCOUNT_NAME                  as ACCOUNT_NAME         -- 顧客名
  ,xseh.dlv_invoice_number           as dlv_invoice_number   -- 納品伝票番号
  ,xcsc_v.meaning                    as meaning              -- カード売区分
  ,xseh.sale_amount_sum              as sale_amount_sum      --（伝票）売上金額
  ,sum(xsel.Cash_And_Card)           as Cash_And_Card        --（伝票）現金カード併用額
  ,xseh.cash_total_sales_amt         as cash_total_sales_amt -- （VD）現金売りトータル販売金額
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt as card_total_sales_amt  -- （VD）カードトータル販売金額
  ,xseh.total_sales_amt              as total_sales_amt      -- 総販売金額
  ,xseh.cash_total_sales_amt - xseh.sale_amount_sum  as difference -- 差額
FROM
   xxcos.xxcos_sales_exp_headers   xseh
  ,XXCOS.Xxcos_Sales_Exp_Lines     xsel
  ,apps.xxcso_employees_v3         xev
  ,apps.XXCSO_RESOURCES_SECURITY_V xrsv
  ,apps.xxcso_cust_accounts_v      xca
  ,(SELECT  lookup_code
           ,meaning
    FROM    applsys.fnd_lookup_values
    WHERE   language     = 'JA'
    AND     enabled_flag = 'Y'
    AND     lookup_type  = 'XXCOS1_CARD_SALE_CLASS'
    ) xcsc_v                                      -- カード売区分
WHERE xseh.sales_base_code     = xrsv.base_code
and   Xseh.Sales_Exp_Header_Id = Xsel.Sales_Exp_Header_Id
and   xseh.dlv_by_code         = xev.employee_number
and   xseh.ship_to_customer_code = xca.ACCOUNT_NUMBER
AND   xseh.card_sale_class     = xcsc_v.lookup_code(+)   -- カード売区分
/* バインド変数はコメントアウト運用でお願いします。消さないでください！追加はOKです */
--AND xseh.dlv_invoice_number = :invoice                 -- 納品伝票番号
--AND xseh.ship_to_customer_code = :cust                 -- 顧客コード
--AND xseh.sales_base_code = :sbase                      -- 売上拠点
AND xseh.delivery_date >= trunc(sysdate-30)                 -- 納品日
--AND xseh.delivery_date BETWEEN  TO_DATE(:sddate) AND TO_DATE(:eddate)  -- 納品日From-To
and xseh.card_sale_class = '0'                --カード売区分：現金
and xseh.hht_received_flag  = 'Y'             --HHT受信フラグ
and xseh.sale_amount_sum <> xseh.cash_total_sales_amt   -- 売上金額合計≠現金売りトータル販売金額
GROUP BY xseh.sales_base_code, xrsv.base_name, xseh.dlv_by_code, xev.full_name, xseh.delivery_date, xseh.ship_to_customer_code, xca.ACCOUNT_NAME, xseh.dlv_invoice_number, xcsc_v.meaning, xseh.sale_amount_sum, xseh.cash_total_sales_amt, xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt, xseh.total_sales_amt, xseh.cash_total_sales_amt - xseh.sale_amount_sum
union all
------------＜カード売上差異チェック＞
SELECT
   xseh.sales_base_code              as sales_base_code      -- 売上拠点コード
  ,xrsv.base_name                    as base_name            -- 拠点名
  ,xseh.dlv_by_code                  as dlv_by_code          -- 納品者コード
  ,xev.full_name                     as full_name            -- 納品者名
  ,xseh.delivery_date                as delivery_date        -- 納品日
--  ,xseh.hht_dlv_input_date              "HHT納品入力日時"
--  ,xseh.order_no_hht                    "受注No(HHT)"
--  ,xseh.digestion_ln_number             "受注No(HHT)枝番"
  ,xseh.ship_to_customer_code        as ship_to_customer_code-- 顧客コード
  ,xca.ACCOUNT_NAME                  as ACCOUNT_NAME         -- 顧客名
  ,xseh.dlv_invoice_number           as dlv_invoice_number   -- 納品伝票番号
  ,xcsc_v.meaning                    as meaning              -- カード売区分
  ,xseh.sale_amount_sum              as sale_amount_sum      --（伝票）売上金額
  ,sum(xsel.Cash_And_Card)           as Cash_And_Card        --（伝票）現金カード併用額
  ,xseh.cash_total_sales_amt         as cash_total_sales_amt -- （VD）現金売りトータル販売金額
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt as card_total_sales_amt  -- （VD）カードトータル販売金額
  ,xseh.total_sales_amt              as total_sales_amt      -- 総販売金額
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt - xseh.sale_amount_sum  as difference -- 差額
FROM
   xxcos.xxcos_sales_exp_headers   xseh
  ,XXCOS.Xxcos_Sales_Exp_Lines     xsel
  ,apps.xxcso_employees_v3         xev
  ,apps.XXCSO_RESOURCES_SECURITY_V xrsv
  ,apps.xxcso_cust_accounts_v      xca
  ,(SELECT  lookup_code
           ,meaning
    FROM    applsys.fnd_lookup_values
    WHERE   language     = 'JA'
    AND     enabled_flag = 'Y'
    AND     lookup_type  = 'XXCOS1_CARD_SALE_CLASS'
   ) xcsc_v                                      -- カード売区分
WHERE xseh.sales_base_code     = xrsv.base_code
and   Xseh.Sales_Exp_Header_Id = Xsel.Sales_Exp_Header_Id
and   xseh.dlv_by_code         = xev.employee_number
and   xseh.ship_to_customer_code = xca.ACCOUNT_NUMBER
AND   xseh.card_sale_class     = xcsc_v.lookup_code(+)   -- カード売区分
/* バインド変数はコメントアウト運用でお願いします。消さないでください！追加はOKです */
--AND   xseh.dlv_invoice_number = :invoice                  -- 納品伝票番号
--AND xseh.ship_to_customer_code = :cust                      -- 顧客コード
--AND xseh.sales_base_code = :sbase                         -- 売上拠点
AND xseh.delivery_date >= trunc(sysdate-30)                  -- 納品日
--AND xseh.delivery_date BETWEEN  TO_DATE(:sddate) AND TO_DATE(:eddate)  -- 納品日From-To
and xseh.card_sale_class = '1'                --カード売区分：カード
and xseh.hht_received_flag  = 'Y'             --HHT受信フラグ
and xseh.sale_amount_sum <> (xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt)   -- 売上金額合計≠カード売トータル販売金額
group by    xseh.sales_base_code
  ,xrsv.base_name
  ,xseh.dlv_by_code
  ,xev.full_name
  ,xseh.delivery_date
  ,xseh.ship_to_customer_code
  ,xca.ACCOUNT_NAME
  ,xseh.dlv_invoice_number
  ,xcsc_v.meaning
  ,xseh.sale_amount_sum
  ,xseh.cash_total_sales_amt
  ,xseh.ppcard_total_sales_amt + xseh.idcard_total_sales_amt
  ,xseh.total_sales_amt
order by 1,3,5,6,7,8 desc) a
;
exit;

