/*************************************************************************
 * 
 * View  Name      : XXSKZ_¶tÀÑ_î{_V
 * Description     : XXSKZ_¶tÀÑ_î{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/21    1.0   SCSK ì    ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_¶tÀÑ_î{_V
(
 `[NO
,r¤iæª
,r¤iæª¼
,riÚæª
,riÚæª¼
,rQR[h
,riÚR[h
,riÚ¼
,riÚªÌ
,rbgNO
,r»¢Nú
,rÅLL
,rÜ¡úÀ
,dãÊ
,dãPÊ
,ÁHP¿
,üÉæR[h
,üÉæ¼
,×ó
,õl
,W×PÊ
,W×PP¿_¼
,W×PP¿_³
,W×QÊ
,W×QP¿_¼
,W×QP¿_³
,óüPÊ
,óüPP¿_¼
,óüPP¿_³
,óüQÊ
,óüQP¿_¼
,óüQP¿_³
,o×Ê
,o×P¿_¼
,o×P¿_³
,Y¨PiÚR[h
,Y¨PiÚ¼
,Y¨PiÚªÌ
,Y¨PbgNO
,Y¨P»¢Nú
,Y¨PÅLL
,Y¨PÜ¡úÀ
,Y¨PÊ
,Y¨PPÊ
,Y¨QiÚR[h
,Y¨QiÚ¼
,Y¨QiÚªÌ
,Y¨QbgNO
,Y¨Q»¢Nú
,Y¨QÅLL
,Y¨QÜ¡úÀ
,Y¨QÊ
,Y¨QPÊ
,Y¨RiÚR[h
,Y¨RiÚ¼
,Y¨RiÚªÌ
,Y¨RbgNO
,Y¨R»¢Nú
,Y¨RÅLL
,Y¨RÜ¡úÀ
,Y¨RÊ
,Y¨RPÊ
,³P¿üÍ®¹tO
,R[h
,¼
,ÐàP¿_³
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
        XNPT.entry_number                   --`[No
       ,PRODC.prod_class_code               --r¤iæª
       ,PRODC.prod_class_name               --r¤iæª¼
       ,ITEMC.item_class_code               --riÚæª
       ,ITEMC.item_class_name               --riÚæª¼
       ,CROWD.crowd_code                    --rQR[h
       ,XNPT.aracha_item_code               --riÚR[h
       ,XIMV_ARA.item_name                  --riÚ¼
       ,XIMV_ARA.item_short_name            --riÚªÌ
       ,XNPT.aracha_lot_number              --rbgNo
       ,ILM_ARA.attribute1                  --r»¢Nú
       ,ILM_ARA.attribute2                  --rÅLL
       ,ILM_ARA.attribute3                  --rÜ¡úÀ
       ,XNPT.aracha_quantity                --dãÊ
       ,XNPT.aracha_uom                     --dãPÊ
       ,XNPT.processing_unit_price          --ÁHP¿
       ,XNPT.location_code                  --üÉæR[h
       ,XILV_NYUK.description               --üÉæ¼
       ,XNPT.nijirushi                      --×ó
       ,XNPT.description                    --õl
       ,XNPT.collect1_quantity              --W×PÊ
       ,XNPT.collect1_temp_unit_price       --W×PP¿_¼
       ,XNPT.collect1_final_unit_price      --W×PP¿_³
       ,XNPT.collect2_quantity              --W×QÊ
       ,XNPT.collect2_temp_unit_price       --W×QP¿_¼
       ,XNPT.collect2_final_unit_price      --W×QP¿_³
       ,XNPT.receive1_quantity              --óüPÊ
       ,XNPT.receive1_temp_unit_price       --óüPP¿_¼
       ,XNPT.receive1_final_unit_price      --óüPP¿_³
       ,XNPT.receive2_quantity              --óüQÊ
       ,XNPT.receive2_temp_unit_price       --óüQP¿_¼
       ,XNPT.receive2_final_unit_price      --óüQP¿_³
       ,XNPT.shipment_quantity              --o×Ê
       ,XNPT.shipment_temp_unit_price       --o×P¿_¼
       ,XNPT.shipment_final_unit_price      --o×P¿_³
       ,XNPT.byproduct1_item_code           --Y¨PiÚR[h
       ,XIMV_HUK1.item_name                 --Y¨PiÚ¼
       ,XIMV_HUK1.item_short_name           --Y¨PiÚªÌ
       ,XNPT.byproduct1_lot_number          --Y¨PbgNo
       ,ILM_HUK1.attribute1                 --Y¨P»¢Nú
       ,ILM_HUK1.attribute2                 --Y¨PÅLL
       ,ILM_HUK1.attribute3                 --Y¨PÜ¡úÀ
       ,XNPT.byproduct1_quantity            --Y¨PÊ
       ,XNPT.byproduct1_uom                 --Y¨PPÊ
       ,XNPT.byproduct2_item_code           --Y¨QiÚR[h
       ,XIMV_HUK2.item_name                 --Y¨QiÚ¼
       ,XIMV_HUK2.item_short_name           --Y¨QiÚªÌ
       ,XNPT.byproduct2_lot_number          --Y¨QbgNo
       ,ILM_HUK2.attribute1                 --Y¨Q»¢Nú
       ,ILM_HUK2.attribute2                 --Y¨QÅLL
       ,ILM_HUK2.attribute3                 --Y¨QÜ¡úÀ
       ,XNPT.byproduct2_quantity            --Y¨QÊ
       ,XNPT.byproduct2_uom                 --Y¨QPÊ
       ,XNPT.byproduct3_item_code           --Y¨RiÚR[h
       ,XIMV_HUK3.item_name                 --Y¨RiÚ¼
       ,XIMV_HUK3.item_short_name           --Y¨RiÚªÌ
       ,XNPT.byproduct3_lot_number          --Y¨RbgNo
       ,ILM_HUK3.attribute1                 --Y¨R»¢Nú
       ,ILM_HUK3.attribute2                 --Y¨RÅLL
       ,ILM_HUK3.attribute3                 --Y¨RÜ¡úÀ
       ,XNPT.byproduct3_quantity            --Y¨RÊ
       ,XNPT.byproduct3_uom                 --Y¨RPÊ
       ,XNPT.final_unit_price_entered_flg   --³P¿üÍ®¹tO
       ,XNPT.department_code                --R[h
       ,XLV_TORI.location_name              --¼
       ,XNPT.company_final_unit_price       --ÐàP¿_³
       ,FU_CB.user_name                     --ì¬Ò
       ,TO_CHAR( XNPT.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --ì¬ú
       ,FU_LU.user_name                     --ÅIXVÒ
       ,TO_CHAR( XNPT.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --ÅIXVú
       ,FU_LL.user_name                     --ÅIXVOC
FROM	xxpo_namaha_prod_txns     XNPT		--¶tÀÑAhI
       ,xxskz_item_mst2_v         XIMV_ARA	--riÚ¼æ¾p
       ,xxskz_prod_class_v        PRODC     --r¤iæªæ¾p
       ,xxskz_item_class_v        ITEMC     --riÚæªæ¾p
       ,xxskz_crowd_code_v        CROWD     --rQR[hæ¾p
       ,ic_lots_mst               ILM_ARA	--rbgîñæ¾p
       ,xxskz_item_locations2_v   XILV_NYUK --üÉæ¼æ¾p
       ,xxskz_item_mst2_v         XIMV_HUK1 --Y¨1iÚ¼æ¾p
       ,ic_lots_mst               ILM_HUK1  --Y¨1bgîñæ¾p
       ,xxskz_item_mst2_v         XIMV_HUK2 --Y¨2iÚ¼æ¾p
       ,ic_lots_mst               ILM_HUK2  --Y¨2bgîñp
       ,xxskz_item_mst2_v         XIMV_HUK3 --Y¨3iÚ¼æ¾p
       ,ic_lots_mst               ILM_HUK3  --Y¨3bgîñp
       ,xxskz_locations2_v        XLV_TORI  --æ¼æ¾p
       ,fnd_user                  FU_CB   	--[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                  FU_LU   	--[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                  FU_LL   	--[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins                FL_LL   	--OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
WHERE
--riÚ¼æ¾p
      XIMV_ARA.item_id(+) = XNPT.aracha_item_id
  AND XIMV_ARA.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_ARA.end_date_active(+) >= TRUNC(SYSDATE)
--riÚJeSîñæ¾p
  AND XNPT.aracha_item_id = PRODC.item_id(+)
  AND XNPT.aracha_item_id = ITEMC.item_id(+)
  AND XNPT.aracha_item_id = CROWD.item_id(+)
--rbgîñæ¾p
  AND ILM_ARA.item_id(+) = XNPT.aracha_item_id
  AND ILM_ARA.lot_id(+) = XNPT.aracha_lot_id
--üÉæ¼æ¾p
  AND XILV_NYUK.inventory_location_id(+) = XNPT.location_id
--Y¨1iÚ¼æ¾p
  AND XIMV_HUK1.item_id(+) = XNPT.byproduct1_item_id
  AND XIMV_HUK1.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK1.end_date_active(+) >= TRUNC(SYSDATE)
--Y¨1bgîñæ¾p
  AND ILM_HUK1.item_id(+) = XNPT.byproduct1_item_id
  AND ILM_HUK1.lot_id(+) = XNPT.byproduct1_lot_id
--Y¨2iÚ¼æ¾p
  AND XIMV_HUK2.item_id(+) = XNPT.byproduct2_item_id
  AND XIMV_HUK2.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK2.end_date_active(+) >= TRUNC(SYSDATE)
--Y¨2bgîñp
  AND ILM_HUK2.item_id(+) = XNPT.byproduct2_item_id
  AND ILM_HUK2.lot_id(+) = XNPT.byproduct2_lot_id
--Y¨3iÚ¼æ¾p
  AND XIMV_HUK3.item_id(+) = XNPT.byproduct3_item_id
  AND XIMV_HUK3.start_date_active(+) <= TRUNC(SYSDATE)
  AND XIMV_HUK3.end_date_active(+) >= TRUNC(SYSDATE)
--Y¨3bgîñp
  AND ILM_HUK3.item_id(+) = XNPT.byproduct3_item_id
  AND ILM_HUK3.lot_id(+) = XNPT.byproduct3_lot_id
--æ¼æ¾p
  AND XLV_TORI.location_code(+) = XNPT.department_code
  AND XLV_TORI.start_date_active(+) <= TRUNC(SYSDATE)
  AND XLV_TORI.end_date_active(+)   >= TRUNC(SYSDATE)
--[U[}X^(CREATED_BY¼Ìæ¾p)
  AND  FU_CB.user_id(+)  = XNPT.created_by
--[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
  AND  FU_LU.user_id(+)  = XNPT.last_updated_by
--OC}X^E[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
  AND  FL_LL.login_id(+) = XNPT.last_update_login
  AND  FL_LL.user_id = FU_LL.user_id(+)
/	
COMMENT ON TABLE APPS.XXSKZ_¶tÀÑ_î{_V IS 'XXSKZ_¶tÀÑiî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.`[NO                  IS '`[No'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.r¤iæª            IS 'r¤iæª'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.r¤iæª¼          IS 'r¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.riÚæª            IS 'riÚæª'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.riÚæª¼          IS 'riÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.rQR[h            IS 'rQR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.riÚR[h          IS 'riÚR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.riÚ¼              IS 'riÚ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.riÚªÌ            IS 'riÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.rbgNO            IS 'rbgNo'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.r»¢Nú          IS 'r»¢Nú'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.rÅLL            IS 'rÅLL'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.rÜ¡úÀ            IS 'rÜ¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.dãÊ                IS 'dãÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.dãPÊ                IS 'dãPÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ÁHP¿                IS 'ÁHP¿'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.üÉæR[h            IS 'üÉæR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.üÉæ¼                IS 'üÉæ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.×ó                    IS '×ó'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.õl                    IS 'õl'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.W×PÊ              IS 'W×PÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.W×PP¿_¼           IS 'W×PP¿_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.W×PP¿_³           IS 'W×PP¿_³'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.W×QÊ              IS 'W×QÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.W×QP¿_¼           IS 'W×QP¿_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.W×QP¿_³           IS 'W×QP¿_³'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.óüPÊ              IS 'óüPÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.óüPP¿_¼           IS 'óüPP¿_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.óüPP¿_³           IS 'óüPP¿_³'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.óüQÊ              IS 'óüQÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.óüQP¿_¼           IS 'óüQP¿_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.óüQP¿_³           IS 'óüQP¿_³'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.o×Ê                IS 'o×Ê'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.o×P¿_¼             IS 'o×P¿_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.o×P¿_³             IS 'o×P¿_³'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PiÚR[h      IS 'Y¨PiÚR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PiÚ¼          IS 'Y¨PiÚ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PiÚªÌ        IS 'Y¨PiÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PbgNO        IS 'Y¨PbgNo'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨P»¢Nú      IS 'Y¨P»¢Nú'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PÅLL        IS 'Y¨PÅLL'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PÜ¡úÀ        IS 'Y¨PÜ¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PÊ            IS 'Y¨PÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨PPÊ            IS 'Y¨PPÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QiÚR[h      IS 'Y¨QiÚR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QiÚ¼          IS 'Y¨QiÚ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QiÚªÌ        IS 'Y¨QiÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QbgNO        IS 'Y¨QbgNo'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨Q»¢Nú      IS 'Y¨Q»¢Nú'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QÅLL        IS 'Y¨QÅLL'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QÜ¡úÀ        IS 'Y¨QÜ¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QÊ            IS 'Y¨QÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨QPÊ            IS 'Y¨QPÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RiÚR[h      IS 'Y¨RiÚR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RiÚ¼          IS 'Y¨RiÚ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RiÚªÌ        IS 'Y¨RiÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RbgNO        IS 'Y¨RbgNo'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨R»¢Nú      IS 'Y¨R»¢Nú'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RÅLL        IS 'Y¨RÅLL'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RÜ¡úÀ        IS 'Y¨RÜ¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RÊ            IS 'Y¨RÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.Y¨RPÊ            IS 'Y¨RPÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.³P¿üÍ®¹tO    IS '³P¿üÍ®¹tO'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.R[h              IS 'R[h'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.¼                  IS '¼'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ÐàP¿_³             IS 'ÐàP¿_³'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ì¬Ò                  IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ì¬ú                  IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ÅIXVÒ              IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ÅIXVú              IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKZ_¶tÀÑ_î{_V.ÅIXVOC        IS 'ÅIXVOC'
/
