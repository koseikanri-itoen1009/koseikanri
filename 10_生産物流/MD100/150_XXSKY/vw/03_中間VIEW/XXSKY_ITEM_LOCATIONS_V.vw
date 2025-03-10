CREATE OR REPLACE VIEW APPS.XXSKY_ITEM_LOCATIONS_V
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
-- [E_{Ò®_14953] SCSK Y.Sekine Del Start
--   AND  MIL.disable_date IS NULL
-- [E_{Ò®_14953] SCSK Y.Sekine Del End
/
COMMENT ON TABLE APPS.XXSKY_ITEM_LOCATIONS_V IS 'SKYLINKpÔVIEW OPMÛÇêîñVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.MTL_ORGANIZATION_ID   IS 'ÝÉgDID'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.INVENTORY_LOCATION_ID IS 'qÉID'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.WHSE_CODE             IS 'qÉR[h'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.WHSE_NAME             IS 'qÉ¼'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.ORGN_CODE             IS 'vgR[h'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.CUSTOMER_STOCK_WHSE   IS 'èæÝÉÇÎÛ'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.SEGMENT1              IS 'ÛÇqÉR[h'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.DESCRIPTION           IS 'ÛÇqÉ¼'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.SHORT_NAME            IS 'ÛÇqÉZk¼'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.DATE_FROM             IS 'gDLøJnú'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.DATE_TO               IS 'gDLøI¹ú'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.ALLOW_PICKUP_FLAG     IS 'o×øÎÛtO'
/
COMMENT ON COLUMN APPS.XXSKY_ITEM_LOCATIONS_V.FREQUENT_WHSE         IS 'ã\qÉ'
/
