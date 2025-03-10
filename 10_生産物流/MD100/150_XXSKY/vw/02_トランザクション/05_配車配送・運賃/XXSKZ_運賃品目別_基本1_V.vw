/*************************************************************************
 * 
 * View  Name      : XXSKZ_^ÀiÚÊ_î{1_V
 * Description     : XXSKZ_^ÀiÚÊ_î{1_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ì    ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_^ÀiÚÊ_î{1_V
(
 zNO
,Ë_Ú®NO
,æª
,ó^Cv
,Xe[^X
,Xe[^X¼
,Ç_
,Ç_¼
,^ÆÒ
,^ÆÒ¼
,^ÆÒªÌ
,üÉæ_zæ
,üÉæ_zæ¼
,üÉæ_zæªÌ
,oÉ³
,oÉ³¼
,oÉ³ªÌ
,zæª
,zæª¼
,oÉú
,üÉú
,¤iæª
,¤iæª¼
,iÚæª
,iÚæª¼
,QR[h
,iÚR[h
,iÚ¼Ì
,iÚªÌ
,iÚo
,iÚP[X
,vP[X
,ÏÚdÊv
,ÂªvZp_ÏÚdÊv
,iÚdÊv
,ÂªvZp_iÚdÊv
,vàz
,iÚ_vàz
)
AS
SELECT
        UHK.delivery_no                     --zNo
       ,UHK.request_no                      --Ë_Ú®No
       ,UHK.delivery_item_details_class     --æª
       ,UHK.order_type                      --ó^Cv
       ,UHK.req_status                      --Xe[^X
       ,CASE WHEN UHK.delivery_item_details_class = 'o×'
             THEN FLV01.meaning             --üÉæ_zæ¼
             ELSE FLV00.meaning             --üÉæ_zæ¼
        END
       ,UHK.head_sales_branch               --Ç_
       ,CASE WHEN UHK.delivery_item_details_class = 'o×'
             THEN XCAV.party_name           --Ç_¼
             ELSE XL2V.location_name        --Ç_¼
        END
       ,UHK.freight_carrier_code            --^ÆÒ
       ,XCRV.party_name                     --^ÆÒ¼
       ,XCRV.party_short_name               --^ÆÒªÌ
       ,UHK.ship_to_deliver_to_code         --üÉæ_zæ
       ,CASE WHEN UHK.delivery_item_details_class = 'o×'
             THEN XPSV.party_site_name                --üÉæ_zæ¼
             ELSE XILV1.description                   --üÉæ_zæ¼
        END
       ,CASE WHEN UHK.delivery_item_details_class = 'o×'
             THEN XPSV.party_site_short_name          --üÉæ_zæªÌ
             ELSE XILV1.short_name                    --üÉæ_zæªÌ
        END
       ,UHK.deliver_from                    --oÉ³
       ,XILV.description                    --oÉ³¼
       ,XILV.short_name                     --oÉ³ªÌ
       ,UHK.shipping_method_code            --zæª
       ,FLV02.meaning                       --zæª¼
       ,UHK.shipped_date                    --oÉú
       ,UHK.arrival_date                    --üÉú
       ,PRODC.prod_class_code               --¤iæª
       ,PRODC.prod_class_name               --¤iæª¼
       ,ITEMC.item_class_code               --iÚæª
       ,ITEMC.item_class_name               --iÚæª¼
       ,CROWD.crowd_code                    --QR[h
       ,UHK.item_no                         --iÚR[h
       ,ITEM.item_name                      --iÚ¼Ì
       ,ITEM.item_short_name                --iÚªÌ
       ,UHK.shipped_quantity                --iÚo
       ,UHK.shipped_case_quantity           --iÚP[X
       ,UHK.sum_case_quantity               --vP[X
       ,UHK.sum_loading_weight              --ÏÚdÊv
       ,UHK.calc_sum_loading_weight         --ÂªvZp_ÏÚdÊv
       ,UHK.item_loading_weight             --iÚdÊv
       ,UHK.calc_item_loading_weight        --ÂªvZp_iÚdÊv
       ,UHK.sum_amount                      --vàz
       ,UHK.item_amount                     --iÚ_vàz
  FROM
        xxwip_delivery_item_details     UHK      --iÚÊÂª^À¾×AhI
       ,xxskz_prod_class_v              PRODC    --SKYLINKpÔVIEW ¤iæªVIEW
       ,xxskz_item_class_v              ITEMC    --SKYLINKpÔVIEW iÚæªVIEW
       ,xxskz_crowd_code_v              CROWD    --SKYLINKpÔVIEW QR[hVIEW
       ,xxskz_cust_accounts2_v          XCAV     --SKYLINKpÔVIEW ÚqîñVIEW2(Ç_)
       ,xxskz_locations2_v              XL2V     --SKYLINKpÔVIEW ÆîñVIEW2(Ç_¼)
       ,xxskz_carriers2_v               XCRV     --SKYLINKpÔVIEW ^ÆÒîñVIEW2(^ÆÒ¼)
       ,xxskz_party_sites2_v            XPSV     --SKYLINKpÔVIEW zæîñVIEW2(zæ¼)
       ,xxskz_item_locations2_v         XILV1    --SKYLINKpÔVIEW OPMÛÇêîñVIEW2(üÉæ¼)
       ,xxskz_item_locations2_v         XILV     --SKYLINKpÔVIEW OPMÛÇêîñVIEW2(oÉ³¼)
       ,xxskz_item_mst2_v               ITEM     --SKYLINKpÔVIEW OPMiÚîñVIEW2(iÚîñ)
       ,fnd_lookup_values               FLV00    --NCbNR[h(Xe[^X¼)
       ,fnd_lookup_values               FLV01    --NCbNR[h(Xe[^X¼)
       ,fnd_lookup_values               FLV02    --NCbNR[h(zæª¼)
 WHERE
   -- iÚÌJeSîñæ¾ð
        ITEM.item_id = PRODC.item_id(+)  --¤iæª
   AND  ITEM.item_id = ITEMC.item_id(+)  --iÚæª
   AND  ITEM.item_id = CROWD.item_id(+)  --QR[h
   -- Ç_¼æ¾ð(Ú®)
   AND  UHK.head_sales_branch = XL2V.location_code(+)
   AND  UHK.arrival_date >= XL2V.start_date_active(+)
   AND  UHK.arrival_date <= XL2V.end_date_active(+)
   -- Ç_¼æ¾ð(o×)
   AND  UHK.head_sales_branch = XCAV.party_number(+)
   AND  UHK.arrival_date >= XCAV.start_date_active(+)
   AND  UHK.arrival_date <= XCAV.end_date_active(+)
   -- ^ÆÒ_ÀÑ¼æ¾ð
   AND  UHK.freight_carrier_code = XCRV.freight_code(+)
   AND  UHK.arrival_date >= XCRV.start_date_active(+)
   AND  UHK.arrival_date <= XCRV.end_date_active(+)
   -- Ú®_üÉæ¼æ¾
   AND  UHK.ship_to_deliver_to_code = XILV1.segment1(+)
   -- o×_zæ¼æ¾ð
   AND  UHK.ship_to_deliver_to_code = XPSV.party_site_number(+)
   AND  UHK.arrival_date >= XPSV.start_date_active(+)
   AND  UHK.arrival_date <= XPSV.end_date_active(+)
   -- oÉ³¼æ¾ð
   AND  UHK.deliver_from = XILV.segment1(+)
   -- o×iÚîñæ¾ð
   AND  UHK.item_no = ITEM.item_no(+)
   AND  UHK.arrival_date >= ITEM.start_date_active(+)
   AND  UHK.arrival_date <= ITEM.end_date_active(+)
   -- Xe[^X¼(Ú®)
   AND  FLV00.language(+)    = 'JA'
   AND  FLV00.lookup_type(+) = 'XXINV_MOVE_STATUS'
   AND  FLV00.lookup_code(+) = UHK.req_status
   -- Xe[^X¼(o×)
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
   AND  FLV01.lookup_code(+) = UHK.req_status
   -- zæª¼
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+) = UHK.shipping_method_code
/
COMMENT ON TABLE APPS.XXSKZ_^ÀiÚÊ_î{1_V IS 'SKYLINKp^ÀiÚÊiî{j VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.zNO IS 'zNo'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.Ë_Ú®NO IS 'Ë_Ú®No'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.æª IS 'æª'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.ó^Cv IS 'ó^Cv'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.Xe[^X IS 'Xe[^X'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.Xe[^X¼ IS 'Xe[^X¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.Ç_ IS 'Ç_'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.Ç_¼ IS 'Ç_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.^ÆÒ IS '^ÆÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.^ÆÒ¼ IS '^ÆÒ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.^ÆÒªÌ IS '^ÆÒªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.üÉæ_zæ IS 'üÉæ_zæ'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.üÉæ_zæ¼ IS 'üÉæ_zæ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.üÉæ_zæªÌ IS 'üÉæ_zæªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.oÉ³ IS 'oÉ³'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.oÉ³¼ IS 'oÉ³¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.oÉ³ªÌ IS 'oÉ³ªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.zæª IS 'zæª'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.zæª¼ IS 'zæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.oÉú IS 'oÉú'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.üÉú IS 'üÉú'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.¤iæª IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.¤iæª¼ IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚæª IS 'iÚæª'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚæª¼ IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.QR[h IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚR[h IS 'iÚR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚ¼Ì IS 'iÚ¼Ì'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚªÌ IS 'iÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚo IS 'iÚo'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚP[X IS 'iÚP[X'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.vP[X IS 'vP[X'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.ÏÚdÊv IS 'ÏÚdÊv'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.ÂªvZp_ÏÚdÊv IS 'ÂªvZp_ÏÚdÊv'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚdÊv IS 'iÚdÊv'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.ÂªvZp_iÚdÊv IS 'ÂªvZp_iÚdÊv'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.vàz IS 'vàz'
/
COMMENT ON COLUMN APPS.XXSKZ_^ÀiÚÊ_î{1_V.iÚ_vàz IS 'iÚ_vàz'
/
