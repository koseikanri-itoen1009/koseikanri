CREATE OR REPLACE VIEW xxwsh_tightened_list_v
(
  CONCURRENT_ID,
  MEANING,
  ORDER_TYPE_ID,
  TRANSACTION_TYPE_NAME,
  DELIVER_FROM,
  SALES_BRANCH,
  SALES_BRANCH_CATEGORY,
  SALES_BRANCH_CATEGORY_NAME,
  LEAD_TIME_DAY,
  LEAD_TIME_DAY_NAME,
  SCHEDULE_SHIP_DATE,
  TIGHTENING_DATE,
  BASE_RECORD_CLASS,
  PROD_CLASS
)
AS
SELECT
    XTC.CONCURRENT_ID
    ,'出庫形態:'         || RPAD(DECODE(XTC.ORDER_TYPE_ID
                                       ,-999,'ALL'
                                       ,XOTTV.TRANSACTION_TYPE_NAME)
                                ,10,' ')
     || ', ' || '出元:'   || RPAD(XTC.DELIVER_FROM,4,' ')
     || ', ' || '拠:'     || RPAD(XTC.SALES_BRANCH,4,' ')
     || ', ' || '拠カ:'   || RPAD(XLVV1.MEANING,20,' ')
     || ', ' || 'LT:'     || RPAD(XLVV2.MEANING,4,' ')
     || ', ' || '出日:'   || TO_CHAR(XTC.SCHEDULE_SHIP_DATE,'YYYY/MM/DD')
     || ', ' || '締日時:' || TO_CHAR(XTC.TIGHTENING_DATE,'YYYY/MM/DD HH24:MI')
     || ', ' || '基準:'   || RPAD(XTC.BASE_RECORD_CLASS,4,' ')
    ,XTC.ORDER_TYPE_ID
    ,DECODE(XTC.ORDER_TYPE_ID,-999,'ALL',XOTTV.TRANSACTION_TYPE_NAME)
    ,XTC.DELIVER_FROM
    ,XTC.SALES_BRANCH
    ,XTC.SALES_BRANCH_CATEGORY
    ,XLVV1.MEANING
    ,XTC.LEAD_TIME_DAY
    ,XLVV2.MEANING
    ,TO_CHAR(XTC.SCHEDULE_SHIP_DATE,'YYYY/MM/DD')
    ,TO_CHAR(XTC.TIGHTENING_DATE,'YYYY/MM/DD HH24:MI')
    ,XTC.BASE_RECORD_CLASS
    ,XTC.PROD_CLASS
FROM
    XXWSH_TIGHTENING_CONTROL XTC
    ,XXWSH_OE_TRANSACTION_TYPES_V XOTTV
    ,XXCMN_LOOKUP_VALUES_V XLVV1
    ,XXCMN_LOOKUP_VALUES_V XLVV2
    ,XXCMN_LOOKUP_VALUES_V XLVV3
WHERE XTC.TIGHTEN_RELEASE_CLASS = '1'
AND   DECODE(XTC.ORDER_TYPE_ID,-999,NULL,XTC.ORDER_TYPE_ID) = XOTTV.TRANSACTION_TYPE_ID (+)
AND   DECODE(XTC.SALES_BRANCH_CATEGORY
            ,'ALL',NULL
            ,XTC.SALES_BRANCH_CATEGORY) = XLVV1.LOOKUP_CODE(+)
AND   XLVV1.LOOKUP_TYPE(+) = 'XXWSH_401_BASE_CATEGORY'
AND   XTC.LEAD_TIME_DAY  = TO_NUMBER(XLVV2.ATTRIBUTE1)
AND   XLVV2.LOOKUP_TYPE  = 'XXWSH_LEAD_TIME_DAY'
AND   XTC.TIGHTEN_RELEASE_CLASS = XLVV3.LOOKUP_CODE
AND   XLVV3.LOOKUP_TYPE = 'XXWSH_TIGHTEN_RELEASE_CLASS'
;
--
COMMENT ON COLUMN xxwsh_tightened_list_v.concurrent_id               IS '締め処理ID';
COMMENT ON COLUMN xxwsh_tightened_list_v.meaning
                  IS '出庫形態,出庫元,拠点,拠点カテゴリ,LT,出庫日,締め日時,基準,商品区分';
COMMENT ON COLUMN xxwsh_tightened_list_v.order_type_id               IS '出庫形態ID';
COMMENT ON COLUMN xxwsh_tightened_list_v.transaction_type_name       IS '出庫形態';
COMMENT ON COLUMN xxwsh_tightened_list_v.deliver_from                IS '出庫元';
COMMENT ON COLUMN xxwsh_tightened_list_v.sales_branch                IS '拠点';
COMMENT ON COLUMN xxwsh_tightened_list_v.sales_branch_category       IS '拠点カテゴリ';
COMMENT ON COLUMN xxwsh_tightened_list_v.sales_branch_category_name  IS '拠点カテゴリ名';
COMMENT ON COLUMN xxwsh_tightened_list_v.lead_time_day               IS '生産物流LT';
COMMENT ON COLUMN xxwsh_tightened_list_v.lead_time_day_name          IS '生産物流LT名';
COMMENT ON COLUMN xxwsh_tightened_list_v.schedule_ship_date          IS '出庫日';
COMMENT ON COLUMN xxwsh_tightened_list_v.tightening_date             IS '締め実施日時';
COMMENT ON COLUMN xxwsh_tightened_list_v.base_record_class           IS '基準レコード区分';
COMMENT ON COLUMN xxwsh_tightened_list_v.prod_class                  IS '商品区分';
--
COMMENT ON TABLE  xxwsh_tightened_list_v IS '締め処理実施済リストVIEW';
