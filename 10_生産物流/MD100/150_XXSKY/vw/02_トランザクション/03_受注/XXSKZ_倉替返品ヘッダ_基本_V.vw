/*************************************************************************
 * 
 * View  Name      : XXSKZ_qÖÔiwb__î{_V
 * Description     : XXSKZ_qÖÔiwb__î{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK ì    ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_qÖÔiwb__î{_V
(
 ËNO
,ó^Cv¼
,gD¼
,óú
,ÅVtO
,³ËNO
,Úq
,Úq¼
,o×æ
,o×æ¼
,o×w¦
,¿i\
,¿i\¼
,Xe[^X
,Xe[^X¼
,o×\èú
,×\èú
,o×³ÛÇê
,o×³ÛÇê¼
,Ç_
,Ç_¼
,Ç_ªÌ
,üÍ_
,üÍ_¼
,üÍ_ªÌ
,¤iæª
,¤iæª¼
,iÚæª
,iÚæª¼
,vÊ
,o×æ_ÀÑ
,o×æ_\À
,o×æ_ÀÑ¼
,o×æ_\À¼
,o×ú
,o×ú_\À
,×ú
,×ú_\À
,ÀÑvãÏæª
,mèÊmÀ{ú
,VKC³tO
,VKC³tO¼
,¬ÑÇ
,¬ÑÇ¼
,o^
,o×Ë÷ßú
,ì¬Ò
,ì¬ú
,ÅIXVÒ
,ÅIXVú
,ÅIXVOC
)
AS
SELECT
        XOHA.request_no                  --ËNo
       ,OTTT.name                        --ó^Cv¼
       ,HAOUT.name                       --gD¼
       ,XOHA.ordered_date                --óú
       ,XOHA.latest_external_flag        --ÅVtO
       ,XOHA.base_request_no             --³ËNo
       ,XOHA.customer_code               --Úq
       ,XCA2V01.party_name               --Úq¼
       ,XOHA.deliver_to                  --o×æ
       ,XPS2V01.party_site_name          --o×æ¼
       ,XOHA.shipping_instructions       --o×w¦
       ,XOHA.price_list_id               --¿i\
       ,QLHT.name                        --¿i\¼
       ,XOHA.req_status                  --Xe[^X
       ,FLV01.meaning                    --Xe[^X¼
       ,XOHA.schedule_ship_date          --o×\èú
       ,XOHA.schedule_arrival_date       --×\èú
       ,XOHA.deliver_from                --o×³ÛÇê
       ,XIL2V.description                --o×³ÛÇê¼
       ,XOHA.head_sales_branch           --Ç_
       ,XCA2V02.party_name               --Ç_¼
       ,XCA2V02.party_short_name         --Ç_ªÌ
       ,XOHA.input_sales_branch          --üÍ_
       ,XCA2V03.party_name               --üÍ_¼
       ,XCA2V03.party_short_name         --üÍ_ªÌ
       ,XOHA.prod_class                  --¤iæª
       ,FLV02.meaning                    --¤iæª¼
       ,XOHA.item_class                  --iÚæª
       ,FLV03.meaning                    --iÚæª¼
       ,XOHA.sum_quantity                --vÊ
       ,XOHA.result_deliver_to           --o×æ_ÀÑ
       ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )                            --NVL( o×æ_ÀÑ, o×æ )
                                         --o×æ_\À
       ,XPS2V02.party_site_name          --o×æ_ÀÑ¼
       ,CASE WHEN XOHA.result_deliver_to IS NULL THEN XPS2V01.party_site_name     --o×æ_ÀÑª¶ÝµÈ¢êÍo×æ¼
             ELSE                                     XPS2V02.party_site_name     --o×æ_ÀÑª¶Ý·éêÍo×æ_ÀÑ¼
        END                              --o×æ_\À¼
       ,XOHA.shipped_date                --o×ú
       ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                         --NVL( o×ú, o×\èú )
                                         --o×ú_\À
       ,XOHA.arrival_date                --×ú
       ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                      --NVL( ×ú, ×\èú )
                                         --×ú_\À
       ,XOHA.actual_confirm_class        --ÀÑvãÏæª
       ,TO_CHAR( XOHA.notif_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --mèÊmÀ{ú
       ,XOHA.new_modify_flg              --VKC³tO
       ,FLV04.meaning                    --VKC³tO¼
       ,XOHA.performance_management_dept --¬ÑÇ
       ,XL2V.location_name               --¬ÑÇ¼
       ,XOHA.registered_sequence         --o^
       ,TO_CHAR( XOHA.tightening_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --o×Ë÷ßú
       ,FU_CB.user_name                  --ì¬Ò
       ,TO_CHAR( XOHA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --ì¬ú
       ,FU_LU.user_name                  --ÅIXVÒ
       ,TO_CHAR( XOHA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --ÅIXVú
       ,FU_LL.user_name                  --ÅIXVOC
  FROM  xxcmn_order_headers_all_arc      XOHA    --ówb_iAhIjobNAbv
       ,oe_transaction_types_all     OTTA    --ó^Cv}X^
       ,oe_transaction_types_tl      OTTT    --ó^Cv}X^(ú{ê)
       ,hr_all_organization_units_tl HAOUT   --qÉ(gD¼)
       ,xxskz_cust_accounts2_v       XCA2V01 --SKYLINKpÔVIEW ÚqîñVIEW2(Úq¼)
       ,xxskz_party_sites2_v         XPS2V01 --SKYLINKpÔVIEW zæîñVIEW2(o×æ¼)
       ,qp_list_headers_tl           QLHT    --¿i\
       ,xxskz_item_locations2_v      XIL2V   --SKYLINKpÔVIEW OPMÛÇêîñVIEW2(o×³ÛÇê¼)
       ,xxskz_cust_accounts2_v       XCA2V02 --SKYLINKpÔVIEW ÚqîñVIEW2(Ç_¼)
       ,xxskz_cust_accounts2_v       XCA2V03 --SKYLINKpÔVIEW ÚqîñVIEW2(üÍ_¼)
       ,xxskz_party_sites2_v         XPS2V02 --SKYLINKpÔVIEW zæîñVIEW2(o×æ_ÀÑ¼)
       ,xxskz_locations2_v           XL2V    --SKYLINKpÔVIEW ÆîñVIEW2(¬ÑÇ¼)
       ,fnd_user                     FU_CB   --[U[}X^(CREATED_BY¼Ìæ¾p)
       ,fnd_user                     FU_LU   --[U[}X^(LAST_UPDATE_BY¼Ìæ¾p)
       ,fnd_user                     FU_LL   --[U[}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_logins                   FL_LL   --OC}X^(LAST_UPDATE_LOGIN¼Ìæ¾p)
       ,fnd_lookup_values            FLV01   --NCbNR[h(Xe[^X¼)
       ,fnd_lookup_values            FLV02   --NCbNR[h(¤iæª¼)
       ,fnd_lookup_values            FLV03   --NCbNR[h(iÚæª¼)
       ,fnd_lookup_values            FLV04   --NCbNR[h(VKC³tO¼)
 WHERE
   --qÖÔiîñæ¾
        OTTA.attribute1 = '3'            --qÖÔi
   AND  XOHA.latest_external_flag = 'Y'
   AND  XOHA.order_type_id = OTTA.transaction_type_id
   --ó^Cv¼æ¾
   AND  OTTT.language(+) = 'JA'
   AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
   --gD¼æ¾
   AND  HAOUT.language(+) = 'JA'
   AND  XOHA.organization_id = HAOUT.organization_id(+)
   --Úq¼æ¾
   AND  XOHA.customer_id = XCA2V01.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V01.end_date_active(+)
   --o×æ¼æ¾
   AND  XOHA.deliver_to_id = XPS2V01.party_site_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V01.end_date_active(+)
   --¿i\¼æ¾
   AND  QLHT.language(+) = 'JA'
   AND  XOHA.price_list_id = QLHT.list_header_id(+)
   --oÉ³ÛÇê¼æ¾
   AND  XOHA.deliver_from_id = XIL2V.inventory_location_id(+)
   --Ç_¼æ¾
   AND  XOHA.head_sales_branch = XCA2V02.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V02.end_date_active(+)
   --üÍ_¼æ¾
   AND  XOHA.input_sales_branch = XCA2V03.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V03.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V03.end_date_active(+)
   --o×æ_ÀÑ¼æ¾
   AND  XOHA.result_deliver_to_id = XPS2V02.party_site_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V02.end_date_active(+)
   --¬ÑÇ¼æ¾
   AND  XOHA.performance_management_dept = XL2V.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V.end_date_active(+)
   --WHOJîñæ¾
   AND  XOHA.created_by        = FU_CB.user_id(+)
   AND  XOHA.last_updated_by   = FU_LU.user_id(+)
   AND  XOHA.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
   --yNCbNR[hzXe[^X¼
   AND  FLV01.language(+) = 'JA'                              --¾ê
   AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'     --NCbNR[h^Cv
   AND  FLV01.lookup_code(+) = XOHA.req_status                --NCbNR[h
   --yNCbNR[hz¤iæª¼
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV02.lookup_code(+) = XOHA.prod_class
   --yNCbNR[hziÚæª¼
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXWSH_ITEM_DIV'
   AND  FLV03.lookup_code(+) = XOHA.item_class
   --yNCbNR[hzVKC³tO¼
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV04.lookup_code(+) = XOHA.new_modify_flg
/
COMMENT ON TABLE APPS.XXSKZ_qÖÔiwb__î{_V IS 'SKYLINKpqÖÔiwb_iî{jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ËNO IS 'ËNo'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ó^Cv¼ IS 'ó^Cv¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.gD¼ IS 'gD¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.óú IS 'óú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ÅVtO IS 'ÅVtO'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.³ËNO IS '³ËNo'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Úq IS 'Úq'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Úq¼ IS 'Úq¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×æ IS 'o×æ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×æ¼ IS 'o×æ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×w¦ IS 'o×w¦'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.¿i\ IS '¿i\'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.¿i\¼ IS '¿i\¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Xe[^X IS 'Xe[^X'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Xe[^X¼ IS 'Xe[^X¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×\èú IS 'o×\èú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.×\èú IS '×\èú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×³ÛÇê IS 'o×³ÛÇê'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×³ÛÇê¼ IS 'o×³ÛÇê¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Ç_ IS 'Ç_'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Ç_¼ IS 'Ç_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.Ç_ªÌ IS 'Ç_ªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.üÍ_ IS 'üÍ_'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.üÍ_¼ IS 'üÍ_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.üÍ_ªÌ IS 'üÍ_ªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.¤iæª IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.¤iæª¼ IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.iÚæª IS 'iÚæª'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.iÚæª¼ IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.vÊ IS 'vÊ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×æ_ÀÑ IS 'o×æ_ÀÑ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×æ_\À IS 'o×æ_\À'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×æ_ÀÑ¼ IS 'o×æ_ÀÑ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×æ_\À¼ IS 'o×æ_\À¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×ú IS 'o×ú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×ú_\À IS 'o×ú_\À'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.×ú IS '×ú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.×ú_\À IS '×ú_\À'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ÀÑvãÏæª IS 'ÀÑvãÏæª'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.mèÊmÀ{ú IS 'mèÊmÀ{ú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.VKC³tO IS 'VKC³tO'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.VKC³tO¼ IS 'VKC³tO¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.¬ÑÇ IS '¬ÑÇ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.¬ÑÇ¼ IS '¬ÑÇ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o^ IS 'o^'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.o×Ë÷ßú IS 'o×Ë÷ßú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ì¬Ò IS 'ì¬Ò'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ì¬ú IS 'ì¬ú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ÅIXVÒ IS 'ÅIXVÒ'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ÅIXVú IS 'ÅIXVú'
/
COMMENT ON COLUMN APPS.XXSKZ_qÖÔiwb__î{_V.ÅIXVOC IS 'ÅIXVOC'
/
