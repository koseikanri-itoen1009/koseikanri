/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_STC_TRANS_V
 * Description     : �v��_���o�ɏ��r���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-02-25    1.0   SCS.Goto         �V�K�쐬
 *  2009-03-24    1.1   SCS.Goto         xxcop_stc_trans_p1_mv�ɖ������ڂ��폜
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
COMMENT ON TABLE APPS.XXCOP_STC_TRANS_V IS '�v��_���o�ɏ��r���['
/
--
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.WHSE_CODE IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ORGANIZATION_ID IS '�݌ɑg�DID'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.OWNERSHIP_CODE IS '���`�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.INVENTORY_LOCATION_ID IS '�ۊǑq��ID'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOCATION_CODE IS '�ۊǑq�ɃR�[�h'
--/
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOCATION IS '�ۊǑq�ɖ�'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_ID IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_NO IS '�i�ڃR�[�h'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_NAME IS '�i�ڐ�����'
--/
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ITEM_SHORT_NAME IS '�i�ڗ���'
--/
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.CASE_CONTENT IS '�P�[�X����'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOT_ID IS '���b�gID'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LOT_NO IS '���b�gNO'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.MANUFACTURE_DATE IS '�����N����'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.UNIQE_SIGN IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.EXPIRATION_DATE IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.ARRIVAL_DATE IS '����'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LEAVING_DATE IS '����'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.STATUS IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.REASON_CODE IS '���R�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.REASON_CODE_NAME IS '���R�R�[�h��'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.VOUCHER_NO IS '�`�[NO'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.UKEBARAISAKI_ID IS '�󕥐�ID'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.UKEBARAISAKI_NAME IS '�󕥐�'
/
--20090324_Ver1.1_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.DELIVER_TO_ID IS '�z����ID'
--/
--20090324_Ver1.1_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.DELIVER_TO_NAME IS '�z����'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.STOCK_QUANTITY IS '���ɐ�'
/
COMMENT ON COLUMN APPS.XXCOP_STC_TRANS_V.LEAVING_QUANTITY IS '�o�ɐ�'
/
