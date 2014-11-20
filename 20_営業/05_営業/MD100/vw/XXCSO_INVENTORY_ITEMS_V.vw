/*************************************************************************
 * 
 * VIEW Name       : XXCSO_INVENTORY_ITEMS_V
 * Description     : 共通用：品目マスタビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/02/10         K.Satomura    ・Disc品目アドオンの結合条件をITEM_ID
 *                                   から品目コードへ変更。
 *                                   ・営業原価をDisc品目原価のITEM_COSTか
 *                                   らOPM品目のDFF8へ変更
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
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.inventory_item_id IS '品目ID';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.inventory_item_code IS '品名コード';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.item_status IS '品目ステータス';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.item_full_name IS '品名・正式名';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.item_short_name IS '品名・略称';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.case_inc_num IS 'ケース入数';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.bowl_inc_num IS 'ボール入数';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.jan_code IS 'JANコード';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.itf_code IS 'ITFコード';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.business_price IS '営業原価';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.opm_start_date IS '適用開始日（OPM品目アドオン）';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.opm_end_date IS '適用終了日（OPM品目アドオン）';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.fixed_price_new IS '定価（新）';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.case_jan_code IS 'ケースJANコード';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.vessel_group IS '容器区分';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.nets IS '内容量';
COMMENT ON COLUMN XXCSO_INVENTORY_ITEMS_V.nets_uom_code IS '内容量単位';
COMMENT ON TABLE XXCSO_INVENTORY_ITEMS_V IS '共通用：品目マスタビュー';
