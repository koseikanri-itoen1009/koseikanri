/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_STC_TRANS_V
 * Description     : 計画_入出庫情報ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-02-25    1.0   SCS.Goto         新規作成
 *  2009-03-24    1.1   SCS.Goto         xxcop_stc_trans_p1_mvに無い項目を削除
 *
 ************************************************************************/
--
CREATE OR REPLACE FORCE VIEW APPS.XXCOP_STC_TRANS_V
  (
    "WHSE_CODE"
  , "ORGANIZATION_ID"
  , "OWNERSHIP_CODE"
  , "INVENTORY_LOCATION_ID"
--20090324_Ver1.1_SCS.Goto_DEL_START
--  , "LOCATION_CODE"
--  , "LOCATION"
--20090324_Ver1.1_SCS.Goto_DEL_END
  , "ITEM_ID"
  , "ITEM_NO"
--20090324_Ver1.1_SCS.Goto_DEL_START
--  , "ITEM_NAME"
--  , "ITEM_SHORT_NAME"
--  , "CASE_CONTENT"
--20090324_Ver1.1_SCS.Goto_DEL_END
  , "LOT_ID"
  , "LOT_NO"
  , "MANUFACTURE_DATE"
  , "UNIQE_SIGN"
  , "EXPIRATION_DATE"
  , "ARRIVAL_DATE"
  , "LEAVING_DATE"
  , "STATUS"
  , "REASON_CODE"
  , "REASON_CODE_NAME"
  , "VOUCHER_NO"
--20090324_Ver1.1_SCS.Goto_DEL_START
--  , "UKEBARAISAKI_ID"
--20090324_Ver1.1_SCS.Goto_DEL_END
  , "UKEBARAISAKI_NAME"
--20090324_Ver1.1_SCS.Goto_DEL_START
--  , "DELIVER_TO_ID"
--20090324_Ver1.1_SCS.Goto_DEL_END
  , "DELIVER_TO_NAME"
  , "STOCK_QUANTITY"
  , "LEAVING_QUANTITY"
  ) AS 
  SELECT xst.whse_code
        ,xst.organization_id
        ,xst.ownership_code
        ,xst.inventory_location_id
--20090324_Ver1.1_SCS.Goto_DEL_START
--        ,xst.location_code
--        ,xst.location
--20090324_Ver1.1_SCS.Goto_DEL_END
        ,xst.item_id
        ,xst.item_no
--20090324_Ver1.1_SCS.Goto_DEL_START
--        ,xst.item_name
--        ,xst.item_short_name
--        ,xst.case_content
--20090324_Ver1.1_SCS.Goto_DEL_END
        ,xst.lot_id
        ,xst.lot_no
        ,xst.manufacture_date
        ,xst.uniqe_sign
        ,xst.expiration_date
        ,xst.arrival_date
        ,xst.leaving_date
        ,xst.status
        ,xst.reason_code
        ,xst.reason_code_name
        ,xst.voucher_no
--20090324_Ver1.1_SCS.Goto_DEL_START
--        ,xst.ukebaraisaki_id
--20090324_Ver1.1_SCS.Goto_DEL_END
        ,xst.ukebaraisaki_name
--20090324_Ver1.1_SCS.Goto_DEL_START
--        ,xst.deliver_to_id
--20090324_Ver1.1_SCS.Goto_DEL_END
        ,xst.deliver_to_name
        ,xst.stock_quantity
        ,xst.leaving_quantity
  FROM xxcop_stc_trans_p1_mv xst
  ;
/
--
COMMENT ON TABLE APPS.XXCOP_STC_TRANS_V IS '計画_入出庫情報ビュー'
/
--
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.WHSE_CODE IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ORGANIZATION_ID IS '在庫組織ID'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.OWNERSHIP_CODE IS '名義コード'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.INVENTORY_LOCATION_ID IS '保管倉庫ID'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOCATION_CODE IS '保管倉庫コード'
--/
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOCATION IS '保管倉庫名'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_ID IS '品目ID'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_NO IS '品目コード'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_NAME IS '品目正式名'
--/
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_SHORT_NAME IS '品目略称'
--/
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.CASE_CONTENT IS 'ケース入数'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOT_ID IS 'ロットID'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOT_NO IS 'ロットNO'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.MANUFACTURE_DATE IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.UNIQE_SIGN IS '固有記号'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.EXPIRATION_DATE IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ARRIVAL_DATE IS '着日'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LEAVING_DATE IS '発日'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.STATUS IS 'ステータス'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.REASON_CODE IS '事由コード'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.REASON_CODE_NAME IS '事由コード名'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.VOUCHER_NO IS '伝票NO'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.UKEBARAISAKI_ID IS '受払先ID'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.UKEBARAISAKI_NAME IS '受払先'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.DELIVER_TO_ID IS '配送先ID'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.DELIVER_TO_NAME IS '配送先'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.STOCK_QUANTITY IS '入庫数'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LEAVING_QUANTITY IS '出庫数'
/
