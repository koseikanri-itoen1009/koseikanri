/*************************************************************************
 * 
 * VIEW Name       : XXCSO_INVENTORY_ITEMS_V
 * Description     : ���ʗp�F�i�ڃ}�X�^�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2009/02/10         K.Satomura    �EDisc�i�ڃA�h�I���̌���������ITEM_ID
 *                                   ����i�ڃR�[�h�֕ύX�B
 *                                   �E�c�ƌ�����Disc�i�ڌ�����ITEM_COST��
 *                                   ��OPM�i�ڂ�DFF8�֕ύX
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_INVENTORY_ITEMS_V
(
 inventory_item_id
,inventory_item_code
,item_status
,item_full_name
,item_short_name
,case_inc_num
,bowl_inc_num
,jan_code
,itf_code
,business_price
,opm_start_date
,opm_end_date
,fixed_price_new
,case_jan_code
,vessel_group
,nets
,nets_uom_code
)
AS
SELECT
 msib.inventory_item_id
,msib.segment1
,xsib.item_status
,ximb.item_name
,ximb.item_short_name
,iimb.attribute11
,xsib.bowl_inc_num
,iimb.attribute21
,iimb.attribute22
,iimb.attribute8
,ximb.start_date_active
,ximb.end_date_active
,iimb.attribute5
,xsib.case_jan_code
,xsib.vessel_group
,xsib.nets
,xsib.nets_uom_code
FROM
 mtl_system_items_b msib
,xxcmm_system_items_b xsib
,ic_item_mst_b iimb
,xxcmn_item_mst_b ximb
WHERE
msib.organization_id = fnd_profile.value('SO_ORGANIZATION_ID') AND
xsib.item_code = msib.segment1 AND
iimb.item_no = msib.segment1 AND
ximb.item_id = iimb.item_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.inventory_item_id IS '�i��ID';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.inventory_item_code IS '�i���R�[�h';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.item_status IS '�i�ڃX�e�[�^�X';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.item_full_name IS '�i���E������';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.item_short_name IS '�i���E����';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.case_inc_num IS '�P�[�X����';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.bowl_inc_num IS '�{�[������';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.jan_code IS 'JAN�R�[�h';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.itf_code IS 'ITF�R�[�h';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.business_price IS '�c�ƌ���';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.opm_start_date IS '�K�p�J�n���iOPM�i�ڃA�h�I���j';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.opm_end_date IS '�K�p�I�����iOPM�i�ڃA�h�I���j';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.fixed_price_new IS '�艿�i�V�j';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.case_jan_code IS '�P�[�XJAN�R�[�h';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.vessel_group IS '�e��敪';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.nets IS '���e��';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.nets_uom_code IS '���e�ʒP��';
COMMENT ON TABLE XXCSO_INVENTORY_ITEMS_V IS '���ʗp�F�i�ڃ}�X�^�r���[';
