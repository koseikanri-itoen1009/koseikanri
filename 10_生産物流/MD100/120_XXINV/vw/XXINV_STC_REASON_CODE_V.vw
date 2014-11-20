CREATE OR REPLACE VIEW xxinv_stc_reason_code_v
(
  REASON_CODE
 ,REASON_NAME
)
AS 
SELECT FLV.LOOKUP_CODE
      ,FLV.MEANING AS REASON_NAME
FROM   XXCMN_RCV_PAY_MST XRPM
      ,FND_LOOKUP_VALUES FLV
WHERE    XRPM.USE_DIV_INVENT     = 'Y'
AND    FLV.LOOKUP_TYPE         = 'XXCMN_NEW_DIVISION'
AND    FLV.LANGUAGE            = 'JA'
AND    FLV.LOOKUP_CODE         = XRPM.NEW_DIV_INVENT
GROUP BY FLV.LOOKUP_CODE
        ,FLV.MEANING
;
--
COMMENT ON COLUMN xxinv_stc_reason_code_v.REASON_CODE  IS '事由コード';
COMMENT ON COLUMN xxinv_stc_reason_code_v.REASON_NAME  IS '事由コード名称';
--
COMMENT ON TABLE  xxinv_stc_reason_code_v IS '在庫_値セット用VIEW_事由コード' ;
/