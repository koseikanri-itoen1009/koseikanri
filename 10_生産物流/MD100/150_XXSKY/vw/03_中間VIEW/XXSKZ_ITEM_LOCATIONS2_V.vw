/*************************************************************************
 * 
 * View  Name      : XXSKZ_ITEM_LOCATIONS2_V
 * Description     : XXSKZ_ITEM_LOCATIONS2_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai 初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ITEM_LOCATIONS2_V
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
,DISABLE_DATE
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
       ,MIL.disable_date
       ,HAOU.date_from
       ,NVL( HAOU.date_to, TO_DATE('99991231', 'YYYYMMDD') )
       ,MIL.attribute4
       ,MIL.attribute5
  FROM  ic_whse_mst                 IWM
       ,hr_all_organization_units   HAOU
       ,mtl_item_locations          MIL
 WHERE  IWM.mtl_organization_id = HAOU.organization_id
   AND  HAOU.organization_id    = MIL.organization_id
   AND  MIL.disable_date IS NULL
/
COMMENT ON TABLE APPS.XXSKZ_ITEM_LOCATIONS2_V IS 'SKYLINK用中間VIEW OPM保管場所情報VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.MTL_ORGANIZATION_ID   IS '在庫組織ID'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.INVENTORY_LOCATION_ID IS '倉庫ID'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.WHSE_CODE             IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.WHSE_NAME             IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.ORGN_CODE             IS 'プラントコード'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.CUSTOMER_STOCK_WHSE   IS '相手先在庫管理対象'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.SEGMENT1              IS '保管倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.DESCRIPTION           IS '保管倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.SHORT_NAME            IS '保管倉庫短縮名'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.DISABLE_DATE          IS '無効日'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.DATE_FROM             IS '組織有効開始日'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.DATE_TO               IS '組織有効終了日'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.ALLOW_PICKUP_FLAG     IS '出荷引当対象フラグ'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_LOCATIONS2_V.FREQUENT_WHSE         IS '代表倉庫'
/
