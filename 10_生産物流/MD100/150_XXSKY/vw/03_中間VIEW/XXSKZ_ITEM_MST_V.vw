/*************************************************************************
 * 
 * View  Name      : XXSKZ_ITEM_MST_V
 * Description     : XXSKZ_ITEM_MST_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_ITEM_MST_V
(
 ITEM_ID
,INVENTORY_ITEM_ID
,ITEM_NO
,ITEM_NAME
,ITEM_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
,ACTIVE_FLAG
,PROD_CLASS_CODE
,ITEM_CLASS_CODE
,CROWD_CODE
,LOT_CTL
,NUM_OF_CASES
)
AS
SELECT  IIMB.item_id
       ,MSIB.inventory_item_id
       ,IIMB.item_no
       ,XIMB.item_name
       ,XIMB.item_short_name
       ,XIMB.start_date_active
       ,XIMB.end_date_active
       ,XIMB.active_flag
       ,IIMB.sales_class
       ,IIMB.itemcost_class
       ,CASE
          WHEN TO_DATE( IIMB.attribute3 ) <= SYSDATE
            THEN IIMB.attribute2
            ELSE IIMB.attribute1
        END
       ,IIMB.lot_ctl
        --�y�P�[�X�����z�o���������Z���ăP�[�X���ɕϊ�����ׂɎg�p
       ,CASE
            WHEN    IIMB.attribute24    IS NOT NULL
            AND     IIMB.itemcost_class = '5'               --5:���i�̂�
            THEN
                DECODE( TO_NUMBER(IIMB.attribute11)
                          ,NULL, 1                          --���Z����NULL�Ƃ��Ȃ�
                          ,0   , 1                          --0����΍�
                          ,TO_NUMBER(IIMB.attribute11)
                      )
            ELSE
                1
        END     num_of_cases
  FROM  ic_item_mst_b       IIMB
       ,xxcmn_item_mst_b    XIMB
       ,mtl_system_items_b  MSIB
 WHERE  IIMB.item_id = XIMB.item_id
   AND  IIMB.inactive_ind <> '1'
   AND  MSIB.organization_id = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
   AND  IIMB.item_no = MSIB.segment1
   AND  XIMB.start_date_active <= TRUNC(SYSDATE)
   AND  XIMB.end_date_active   >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_ITEM_MST_V IS 'SKYLINK�p����VIEW OPM�i�ڏ��VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.ITEM_ID            IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.INVENTORY_ITEM_ID  IS 'INV�i��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.ITEM_NO            IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.ITEM_NAME          IS '�i���E������'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.ITEM_SHORT_NAME    IS '�i���E����'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.START_DATE_ACTIVE  IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.END_DATE_ACTIVE    IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.ACTIVE_FLAG        IS '�K�p�σt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.PROD_CLASS_CODE    IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.ITEM_CLASS_CODE    IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.CROWD_CODE         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.LOT_CTL            IS '���b�g�Ǘ��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_ITEM_MST_V.NUM_OF_CASES       IS '�P�[�X����'
/
