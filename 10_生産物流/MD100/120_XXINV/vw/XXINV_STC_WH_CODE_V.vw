CREATE OR REPLACE VIEW xxinv_stc_wh_code_v
(
  WHSE_DIV
 ,WHSE_CODE
 ,WHSE_NAME
)
AS 
SELECT '1'             AS WHSE_DIV
      ,IWM.WHSE_CODE
      ,IWM.WHSE_NAME 
FROM   IC_WHSE_MST               IWM
      ,HR_ALL_ORGANIZATION_UNITS HAOU
WHERE  IWM.MTL_ORGANIZATION_ID = HAOU.ORGANIZATION_ID
AND    HAOU.DATE_FROM <= trunc(sysdate)
AND  ( HAOU.DATE_TO >= trunc(sysdate)
    OR HAOU.DATE_TO IS NULL )
GROUP BY IWM.WHSE_CODE
        ,IWM.WHSE_NAME
UNION
SELECT '2' AS WHSE_DIV
      ,MIL.SEGMENT1    AS WHSE_CODE
      ,MIL.DESCRIPTION AS WHSE_NAME 
FROM   MTL_ITEM_LOCATIONS MIL
      ,HR_ALL_ORGANIZATION_UNITS HAOU
WHERE  MIL.ATTRIBUTE4 = '1'
AND    HAOU.ORGANIZATION_ID  = MIL.ORGANIZATION_ID
AND    HAOU.DATE_FROM       <= trunc(sysdate)
AND ( (HAOU.DATE_TO         >= trunc(sysdate))
  OR  (HAOU.DATE_TO IS NULL ) )
AND    MIL.DISABLE_DATE IS NULL
;
--
COMMENT ON COLUMN xxinv_stc_wh_code_v.WHSE_DIV   IS '�q�ɋ敪';
COMMENT ON COLUMN xxinv_stc_wh_code_v.WHSE_CODE  IS '�q�ɃR�[�h';
COMMENT ON COLUMN xxinv_stc_wh_code_v.WHSE_NAME  IS '�q�ɖ���';
--
COMMENT ON TABLE  xxinv_stc_wh_code_v IS '�݌�_�l�Z�b�g�pVIEW_�q��/�ۊǑq�ɃR�[�h' ;
/