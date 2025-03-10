/*************************************************************************
 * 
 * View  Name      : XXSKZ_ITEM_LOCATIONS_V
 * Description     : XXSKZ_ITEM_LOCATIONS_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ρμ¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ITEM_LOCATIONS_V
(
 MTL_ORGANIZATION_ID
,INVENTORY_LOCATION_ID
,WHSE_CODE
,WHSE_NAME
,ORGN_CODE
,CUSTOMER_STOCK_WHSE
,SEGMENT1
,DESCRIPTION
,SHORT_NAME
,DATE_FROM
,DATE_TO
,ALLOW_PICKUP_FLAG
,FREQUENT_WHSE
)
AS
SELECT  IWM.mtl_organization_id
       ,MIL.inventory_location_id
       ,IWM.whse_code
       ,IWM.whse_name
       ,IWM.orgn_code
       ,IWM.attribute1
       ,MIL.segment1
       ,MIL.description
       ,MIL.attribute12
       ,HAOU.date_from
       ,NVL( HAOU.date_to, TO_DATE('99991231', 'YYYYMMDD') )
       ,MIL.attribute4
       ,MIL.attribute5
  FROM  ic_whse_mst                 IWM
       ,hr_all_organization_units   HAOU
       ,mtl_item_locations          MIL
 WHERE  IWM.mtl_organization_id = HAOU.organization_id
   AND  HAOU.organization_id = MIL.organization_id
   AND  HAOU.date_from <= TRUNC(SYSDATE)
   AND  ( HAOU.date_to IS NULL OR HAOU.date_to >= TRUNC(SYSDATE) )
   AND  MIL.disable_date IS NULL
/
COMMENT ON TABLE APPS.XXSKZ_ITEM_LOCATIONS_V IS 'SKYLINKpΤVIEW OPMΫΗκξρVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.MTL_ORGANIZATION_ID   IS 'έΙgDID'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.INVENTORY_LOCATION_ID IS 'qΙID'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.WHSE_CODE             IS 'qΙR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.WHSE_NAME             IS 'qΙΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.ORGN_CODE             IS 'vgR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.CUSTOMER_STOCK_WHSE   IS 'θζέΙΗΞΫ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.SEGMENT1              IS 'ΫΗqΙR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.DESCRIPTION           IS 'ΫΗqΙΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.SHORT_NAME            IS 'ΫΗqΙZkΌ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.DATE_FROM             IS 'gDLψJnϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.DATE_TO               IS 'gDLψIΉϊ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.ALLOW_PICKUP_FLAG     IS 'oΧψΞΫtO'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS_V.FREQUENT_WHSE         IS 'γ\qΙ'
/
