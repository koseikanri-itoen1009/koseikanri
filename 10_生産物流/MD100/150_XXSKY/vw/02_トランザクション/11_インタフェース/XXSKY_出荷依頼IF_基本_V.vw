CREATE OR REPLACE VIEW APPS.XXSKY_o×ËIF_î{_V
(
 ó^Cv
,óú
,o×æ
,o×æ¼
,o×w¦
,Úq­
,ó\[XQÆ
,o×\èú
,×\èú
,pbggp
,pbgñû
,o×³
,o×³¼
,Ç_
,Ç_¼
,üÍ_
,üÍ_¼
,×ÔFROM
,×ÔFROM¼
,×ÔTO
,×ÔTO¼
,f[^^Cv
,^ÆÒ
,^ÆÒ¼
,zæª
,zæª¼
,zNO
,o×ú
,×ú
,EOSf[^íÊ
,EOSf[^íÊ¼
,`p}Ô
,üÉqÉ
,üÉqÉ¼
,qÖÔiæª
,qÖÔiæª¼
,Ëæª
,Ëæª¼
,ñ
,ñ¼
,¾×Ô
,¤iæª
,¤iæª¼
,iÚæª
,iÚæª¼
,QR[h
,óiÚR[h
,óiÚ¼
,óiÚªÌ
,P[X
,Ê
,o×ÀÑÊ
,»¢ú
,ÅLL
,Ü¡úÀ
,àóÊ
,üÉÀÑÊ
,Û¯Xe[^X
,Û¯Xe[^X¼
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
        XSH_XSL.order_type                  --ó^Cv
       ,XSH_XSL.ordered_date                --óú
       ,XSH_XSL.party_site_code             --o×æ
       ,XPSV.party_site_name                --o×æ¼
       ,XSH_XSL.shipping_instructions       --o×w¦
       ,XSH_XSL.cust_po_number              --Úq­
       ,XSH_XSL.order_source_ref            --ó\[XQÆ
       ,XSH_XSL.schedule_ship_date          --o×\èú
       ,XSH_XSL.schedule_arrival_date       --×\èú
       ,XSH_XSL.used_pallet_qty             --pbggp
       ,XSH_XSL.collected_pallet_qty        --pbgñû
       ,XSH_XSL.location_code               --o×³
       ,XLV_SHU.location_name               --o×³¼
       ,XSH_XSL.head_sales_branch           --Ç_
       ,XCAV_KAN.party_name                 --Ç_¼
       ,XSH_XSL.input_sales_branch          --üÍ_
       ,XCAV_NYU.party_name                 --üÍ_¼
       ,XSH_XSL.arrival_time_from           --×ÔFROM
       ,FLV_CHFROM.meaning                  --×ÔFROM¼
       ,XSH_XSL.arrival_time_to             --×ÔTO
       ,FLV_CHTO.meaning                    --×ÔTO¼
       ,XSH_XSL.data_type                   --f[^^Cv
       ,XSH_XSL.freight_carrier_code        --^ÆÒ
       ,XCV.party_name                      --^ÆÒ¼
       ,XSH_XSL.shipping_method_code        --zæª
       ,FLV_HAI.meaning                     --zæª¼
       ,XSH_XSL.delivery_no                 --zNo
       ,XSH_XSL.shipped_date                --o×ú
       ,XSH_XSL.arrival_date                --×ú
       ,XSH_XSL.eos_data_type               --EOSf[^íÊ
       ,FLV_EOS.meaning                     --EOSf[^íÊ¼
       ,XSH_XSL.tranceration_number         --`p}Ô
       ,XSH_XSL.ship_to_location            --üÉqÉ
       ,XILV.description                    --üÉqÉ¼
       ,XSH_XSL.rm_class                    --qÖÔiæª
       ,FLV_KURA.meaning                    --qÖÔiæª¼
       ,XSH_XSL.ordered_class               --Ëæª
       ,XSCV.request_class_name             --Ëæª¼
       ,XSH_XSL.report_post_code            --ñ
       ,XLV_HOU.location_name               --ñ¼
       ,XSH_XSL.line_number                 --¾×Ô
       ,XPCV.prod_class_code                --¤iæª
       ,XPCV.prod_class_name                --¤iæª¼
       ,XICV.item_class_code                --iÚæª
       ,XICV.item_class_name                --iÚæª¼
       ,XCCV.crowd_code                     --QR[h
       ,XSH_XSL.orderd_item_code            --óiÚR[h
       ,XIMV.item_name                      --óiÚ¼
       ,XIMV.item_short_name                --óiÚªÌ
       ,XSH_XSL.case_quantity               --P[X
       ,XSH_XSL.orderd_quantity             --Ê
       ,XSH_XSL.shiped_quantity             --o×ÀÑÊ
-- 2009/03/25 H.Iida MOD START {ÔáQ#1329
--       ,XSH_XSL.designated_production_date  --»¢ú
       ,TO_CHAR( XSH_XSL.designated_production_date, 'YYYY/MM/DD')
                                            --»¢ú
-- 2009/03/25 H.Iida MOD END
       ,XSH_XSL.original_character          --ÅLL
-- 2009/03/25 H.Iida MOD START {ÔáQ#1329
--       ,XSH_XSL.use_by_date                 --Ü¡úÀ
       ,TO_CHAR( XSH_XSL.use_by_date, 'YYYY/MM/DD')
                                            --Ü¡úÀ
-- 2009/03/25 H.Iida MOD END
       ,XSH_XSL.detailed_quantity           --àóÊ
       ,XSH_XSL.ship_to_quantity            --üÉÀÑÊ
       ,XSH_XSL.reserved_status             --Û¯Xe[^X
       ,CASE XSH_XSL.reserved_status        --Û¯Xe[^X¼
           WHEN '1' THEN 'Û¯'
        END
       ,FU_CB.user_name                     --ì¬Ò
       ,TO_CHAR( XSH_XSL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --ì¬ú
       ,FU_LU.user_name                     --ÅIXVÒ
       ,TO_CHAR( XSH_XSL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --ÅIXVú
       ,FU_LL.user_name                     --ÅIXVOC
FROM
        ( SELECT 
             XSHI.order_type                    AS  order_type                  --ó^Cv
            ,XSHI.ordered_date                  AS  ordered_date                --óú
            ,XSHI.party_site_code               AS  party_site_code             --o×æ
            ,XSHI.shipping_instructions         AS  shipping_instructions       --o×w¦
            ,XSHI.cust_po_number                AS  cust_po_number              --Úq­
            ,XSHI.order_source_ref              AS  order_source_ref            --ó\[XQÆ
            ,XSHI.schedule_ship_date            AS  schedule_ship_date          --o×\èú
            ,XSHI.schedule_arrival_date         AS  schedule_arrival_date       --×\èú
            ,XSHI.used_pallet_qty               AS  used_pallet_qty             --pbggp
            ,XSHI.collected_pallet_qty          AS  collected_pallet_qty        --pbgñû
            ,XSHI.location_code                 AS  location_code               --o×³
            ,XSHI.head_sales_branch             AS  head_sales_branch           --Ç_
            ,XSHI.input_sales_branch            AS  input_sales_branch          --üÍ_
            ,XSHI.arrival_time_from             AS  arrival_time_from           --×ÔFROM
            ,XSHI.arrival_time_to               AS  arrival_time_to             --×ÔTO
            ,XSHI.data_type                     AS  data_type                   --f[^^Cv
            ,XSHI.freight_carrier_code          AS  freight_carrier_code        --^ÆÒ
            ,XSHI.shipping_method_code          AS  shipping_method_code        --zæª
            ,XSHI.delivery_no                   AS  delivery_no                 --zNo
            ,XSHI.shipped_date                  AS  shipped_date                --o×ú
            ,XSHI.arrival_date                  AS  arrival_date                --×ú
            ,XSHI.eos_data_type                 AS  eos_data_type               --EOSf[^íÊ
            ,XSHI.tranceration_number           AS  tranceration_number         --`p}Ô
            ,XSHI.ship_to_location              AS  ship_to_location            --üÉqÉ
            ,XSHI.rm_class                      AS  rm_class                    --qÖÔiæª
            ,XSHI.ordered_class                 AS  ordered_class               --Ëæª
            ,XSHI.report_post_code              AS  report_post_code            --ñ
            ,XSLI.line_number                   AS  line_number                 --¾×Ô
            ,XSLI.orderd_item_code              AS  orderd_item_code            --óiÚR[h
            ,XSLI.case_quantity                 AS  case_quantity               --P[X
            ,XSLI.orderd_quantity               AS  orderd_quantity             --Ê
            ,XSLI.shiped_quantity               AS  shiped_quantity             --o×ÀÑÊ
            ,XSLI.designated_production_date    AS  designated_production_date  --»¢ú
            ,XSLI.original_character            AS  original_character          --ÅLL
            ,XSLI.use_by_date                   AS  use_by_date                 --Ü¡úÀ
            ,XSLI.detailed_quantity             AS  detailed_quantity           --àóÊ
            ,XSLI.ship_to_quantity              AS  ship_to_quantity            --üÉÀÑÊ
            ,XSLI.reserved_status               AS  reserved_status             --Û¯Xe[^X
            ,XSHI.creation_date                 AS  creation_date               --ì¬ú
            ,XSHI.last_update_date              AS  last_update_date            --ÅIXVú
            ,XSHI.last_update_login             AS  last_update_login
            ,XSHI.created_by                    AS  created_by
            ,XSHI.last_updated_by               AS  last_updated_by
          FROM 
             xxwsh_shipping_headers_if          XSHI        --o×ËC^tF[XAhIwb_
            ,xxwsh_shipping_lines_if            XSLI        --o×ËC^tF[XAhI¾×
          WHERE
             XSHI.header_id = XSLI.header_id                --o×ËC^tF[XAhIwb_E¾×
        )                                       XSH_XSL
       ,xxsky_party_sites2_v                    XPSV        --o×æ¼æ¾
       ,xxsky_locations2_v                      XLV_SHU     --o×³Ææ¾
       ,xxsky_cust_accounts2_v                  XCAV_KAN    --Ç_¼æ¾
       ,xxsky_cust_accounts2_v                  XCAV_NYU    --üÍ_¼æ¾
       ,fnd_lookup_values                       FLV_CHFROM  --×ÔFROM¼æ¾
       ,fnd_lookup_values                       FLV_CHTO    --×ÔTO¼æ¾p
       ,xxsky_carriers2_v                       XCV         --^ÆÒ¼æ¾
       ,fnd_lookup_values                       FLV_HAI     --zæª¼æ¾p
       ,fnd_lookup_values                       FLV_EOS     --EOSf[^íÊ¼æ¾p
       ,fnd_lookup_values                       FLV_KURA    --qÖÔiæª¼æ¾p
       ,xxsky_item_locations_v                  XILV        --ÛÇqÉ¼æ¾
       ,( SELECT DISTINCT 
             request_class
            ,request_class_name
            ,start_date_active
            ,end_date_active
          FROM  xxwsh_shipping_class2_v
          WHERE request_class IS NOT NULL
        )                                       XSCV        --Ëæªæ¾
       ,xxsky_locations2_v                      XLV_HOU     --ñæ¾
       ,xxsky_item_mst2_v                       XIMV        --iÚ¼æ¾(¤iæªEiÚæªEQR[hæ¾Éàgp)
       ,xxsky_prod_class_v                      XPCV        --¤iæªæ¾
       ,xxsky_item_class_v                      XICV        --iÚæªæ¾
       ,xxsky_crowd_code_v                      XCCV        --QR[hæ¾
       ,fnd_user                                FU_CB       --[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                                FU_LU       --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                                FU_LL       --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins                              FL_LL       --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
WHERE
  --o×æ¼æ¾p
      XSH_XSL.party_site_code = XPSV.party_site_number(+)
  AND XPSV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XPSV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --o×³Ææ¾p
  AND XLV_SHU.LOCATION_CODE(+) = XSH_XSL.location_code
  AND XLV_SHU.START_DATE_ACTIVE(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XLV_SHU.END_DATE_ACTIVE(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --Ç_¼æ¾p
  AND XCAV_KAN.party_number(+) = XSH_XSL.head_sales_branch
  AND XCAV_KAN.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCAV_KAN.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --üÍ_¼æ¾p
  AND XCAV_NYU.party_number(+) = XSH_XSL.input_sales_branch
  AND XCAV_NYU.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCAV_NYU.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --×ÔFROM¼æ¾p
  AND FLV_CHFROM.language(+) = 'JA'
  AND FLV_CHFROM.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
  AND FLV_CHFROM.lookup_code(+) = XSH_XSL.arrival_time_from
  --×ÔTO¼æ¾p
  AND FLV_CHTO.language(+) = 'JA'
  AND FLV_CHTO.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
  AND FLV_CHTO.lookup_code(+) = XSH_XSL.arrival_time_to
  --^ÆÒ¼æ¾p
  AND XSH_XSL.freight_carrier_code = XCV.freight_code(+)
  AND XCV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --zæª¼æ¾p
  AND FLV_HAI.language(+) = 'JA'
  AND FLV_HAI.lookup_type(+) = 'XXCMN_SHIP_METHOD'
  AND FLV_HAI.lookup_code(+) = XSH_XSL.shipping_method_code
  --EOSf[^íÊ¼æ¾p
  AND FLV_EOS.language(+) = 'JA'
  AND FLV_EOS.lookup_type(+) = 'XXCMN_D17'
  AND FLV_EOS.lookup_code(+) = XSH_XSL.eos_data_type
  --qÖÔiæª¼æ¾p
  AND FLV_KURA.language(+) = 'JA'
  AND FLV_KURA.lookup_type(+) = 'XXCMN_L03'
  AND FLV_KURA.lookup_code(+) = XSH_XSL.rm_class
  --ÛÇqÉ¼æ¾p
  AND XSH_XSL.ship_to_location = XILV.segment1(+)
  --Ëæªæ¾p
  AND XSH_XSL.ordered_class = XSCV.request_class(+)
  AND XSCV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XSCV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --ñæ¾p
  AND XLV_HOU.location_code(+) = XSH_XSL.report_post_code
  AND XLV_HOU.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XLV_HOU.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --iÚ¼æ¾p
  AND XIMV.item_no(+) = XSH_XSL.orderd_item_code
  AND XIMV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XIMV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --¤iæªæ¾p
  AND XIMV.item_id = XPCV.item_id(+)
  --iÚæªæ¾p
  AND XIMV.item_id = XICV.item_id(+)
  --QR[hæ¾p
  AND XIMV.item_id = XCCV.item_id(+)
  AND FU_CB.user_id(+)  = XSH_XSL.created_by                    --CREATED_BY¼Ìæ¾p
  AND FU_LU.user_id(+)  = XSH_XSL.last_updated_by               --LAST_UPDATE_BY¼Ìæ¾p
  AND FL_LL.login_id(+) = XSH_XSL.last_update_login             --LAST_UPDATE_LOGIN¼Ìæ¾p
  AND FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_o×ËIF_î{_V IS 'XXSKY_o×ËIF (î{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ó^Cv            IS 'ó^Cv'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.óú                IS 'óú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×æ                IS 'o×æ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×æ¼              IS 'o×æ¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×w¦              IS 'o×w¦'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Úq­              IS 'Úq­'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ó\[XQÆ        IS 'ó\[XQÆ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×\èú            IS 'o×\èú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.×\èú            IS '×\èú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.pbggp      IS 'pbggp'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.pbgñû      IS 'pbgñû'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×³                IS 'o×³'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×³¼              IS 'o×³¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Ç_              IS 'Ç_'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Ç_¼            IS 'Ç_¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.üÍ_              IS 'üÍ_'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.üÍ_¼            IS 'üÍ_¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.×ÔFROM          IS '×ÔFROM'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.×ÔFROM¼        IS '×ÔFROM¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.×ÔTO            IS '×ÔTO'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.×ÔTO¼          IS '×ÔTO¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.f[^^Cv          IS 'f[^^Cv'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.^ÆÒ              IS '^ÆÒ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.^ÆÒ¼            IS '^ÆÒ¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.zæª              IS 'zæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.zæª¼            IS 'zæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.zNO                IS 'zNo'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×ú                IS 'o×ú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.×ú                IS '×ú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.EOSf[^íÊ         IS 'EOSf[^íÊ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.EOSf[^íÊ¼       IS 'EOSf[^íÊ¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.`p}Ô            IS '`p}Ô'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.üÉqÉ              IS 'üÉqÉ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.üÉqÉ¼            IS 'üÉqÉ¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.qÖÔiæª          IS 'qÖÔiæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.qÖÔiæª¼        IS 'qÖÔiæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Ëæª              IS 'Ëæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Ëæª¼            IS 'Ëæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ñ              IS 'ñ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ñ¼            IS 'ñ¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.¾×Ô              IS '¾×Ô'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.¤iæª              IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.¤iæª¼            IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.iÚæª              IS 'iÚæª'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.iÚæª¼            IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.QR[h              IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.óiÚR[h        IS 'óiÚR[h'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.óiÚ¼            IS 'óiÚ¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.óiÚªÌ          IS 'óiÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.P[X              IS 'P[X'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Ê                  IS 'Ê'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.o×ÀÑÊ          IS 'o×ÀÑÊ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.»¢ú                IS '»¢ú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ÅLL              IS 'ÅLL'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Ü¡úÀ              IS 'Ü¡úÀ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.àóÊ              IS 'àóÊ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.üÉÀÑÊ          IS 'üÉÀÑÊ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Û¯Xe[^X        IS 'Û¯Xe[^X'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.Û¯Xe[^X¼      IS 'Û¯Xe[^X¼'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ì¬Ò                IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ì¬ú                IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ÅIXVÒ            IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ÅIXVú            IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKY_o×ËIF_î{_V.ÅIXVOC      IS 'ÅIXVOC'
/
