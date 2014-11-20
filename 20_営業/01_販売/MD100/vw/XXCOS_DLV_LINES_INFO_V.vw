/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dlv_lines_info_v
 * Description     : 納品伝票明細情報ビュー
 * Version         : 1.7
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/08    1.0   T.Tyou           新規作成
 *  2009/02/18    1.1   T.Tyou           受注NO（EBS）を追加
 *  2009/05/28    1.2   K.Kiriu          [T1_1119]明細番号(EBS)を追加
 *  2009/06/09    1.3   K.Kiriu          [T1_1382]基準在庫数量取得不具合の修正
 *  2009/07/06    1.4   T.Miyata         [0000409]パフォーマンス対応
 *  2009/08/03    1.5   K.Kiriu          [0000872]パフォーマンス対応
 *  2009/09/03    1.6   M.Sano           [0001227]パフォーマンス対応
 *                                       (業務日付の取得方法変更)
 *  2012/01/05    1.7   N.Koyama         [E_本稼動_08907]パフォーマンス対応
 *                                       (VD、VD以外にSELECTを分割しUNION ALLにて結合)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_dlv_lines_info_v (
  order_no_hht
 ,line_no_hht
 ,digestion_ln_number
 ,column_no
 ,h_and_c
 ,h_and_c_name
 ,item_code_self
 ,item_name
 ,abs_case_number
 ,case_number
 ,abs_quantity
 ,quantity
 ,sale_class
 ,sale_name
 ,abs_wholesale_unit_ploce
 ,wholesale_unit_ploce
 ,abs_selling_price
 ,selling_price
 ,abs_replenish_number
 ,replenish_number
 ,abs_cash_and_card
 ,cash_and_card
 ,inventory_quantity
 ,content
 ,baracha_div
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
 ,request_id
 ,program_application_id
 ,program_id
 ,program_update_date
 ,sold_out_class
 ,sold_out_time
 ,inventory_item_id
 ,standard_unit
 ,order_no_ebs
/* 2009/05/28 Ver1.2 Add Start */
 ,line_number_ebs
/* 2009/05/28 Ver1.2 Add End   */
 )
AS
SELECT
/* 2009/08/03 Ver1.5 Add Start */
/* 2012/01/05 Ver1.7 Del Start */
--       /*+ INDEX(xmvc xxcoi_mst_vd_column_u01) */
/* 2012/01/05 Ver1.7 Del End */
/* 2009/08/03 Ver1.5 Add End   */
/* 2012/01/05 Ver1.7 Mod Start */
--       xdl.order_no_hht order_no_hht,                              --受注No.（HHT)
       xdh.order_no_hht order_no_hht,                              --受注No.（HHT)
/* 2012/01/05 Ver1.7 Mod End */
       xdl.line_no_hht line_no_hht,                                --行No.
       xdl.digestion_ln_number digestion_ln_number,                --枝番
       xdl.column_no column_no,                                    --コラムNo.
       xdl.h_and_c h_and_c,                                        --H/C
       hac.meaning h_and_c_name,                                   --H/C名称
       xdl.item_code_self item_code_self,                          --品名コード
       cmn_mst.item_name,                                          --品目（名称）
       abs( xdl.case_number ) abs_case_number,                     --ケース数（画面用:絶対値）
       xdl.case_number case_number,                                --ケース数（DB値）
       abs( xdl.quantity ) abs_quantity,                           --数量（画面用:絶対値）
       xdl.quantity quantity,                                      --数量（DB値）
       xdl.sale_class sale_class,                                  --売上区分
       sc.meaning  sale_name,                                      --売上区分(名称)
       abs( xdl.wholesale_unit_ploce ) abs_wholesale_unit_ploce,   --卸単価（画面用:絶対値）
       xdl.wholesale_unit_ploce wholesale_unit_ploce,              --卸単価（DB値）
       abs( xdl.selling_price ) abs_selling_price,                 --売単価（画面用:絶対値）
       xdl.selling_price selling_price,                            --売単価（DB値）
       abs(xdl.replenish_number) abs_replenish_number,             --補充数（画面用:絶対値）
       xdl.replenish_number replenish_number,                      --補充数（DB値）
       abs(xdl.cash_and_card) abs_cash_and_card,                   --現金・カード併用額（画面用:絶対値）
       xdl.cash_and_card cash_and_card,                            --現金・カード併用額（DB値）
/* 2009/09/03 Ver1.6 Mod Start */
--/* 2009/07/06 Ver1.4 Mod Start */
----/* 2009/06/09 Ver1.3 Mod Start */
------       CASE WHEN xdh.dlv_date < xxccp_common_pkg2.get_process_date THEN
----       CASE WHEN TO_CHAR( xdh.dlv_date, 'YYYYMM' ) < TO_CHAR( xxccp_common_pkg2.get_process_date, 'YYYYMM') THEN
--       CASE WHEN TRUNC( xdh.dlv_date, 'MM' ) < TRUNC( xxccp_common_pkg2.get_process_date, 'MM') THEN
       CASE WHEN TRUNC( xdh.dlv_date, 'MM' ) < TRUNC( pd.process_date, 'MM') THEN
----/* 2009/06/09 Ver1.3 Mod End   */
--/* 2009/07/06 Ver1.4 Mod End   */
/* 2009/09/03 Ver1.6 Mod Start */
         xmvc.last_month_inventory_quantity
       ELSE
         xmvc.inventory_quantity
       END inventory_quantity,                                     --基準在庫数
       xdl.content content,                                        --入数
       cmm_item.baracha_div,                                       --バラ茶区分
       xdl.created_by,
       xdl.creation_date,
       xdl.last_updated_by,
       xdl.last_update_date,
       xdl.last_update_login,
       xdl.request_id,
       xdl.program_application_id,
       xdl.program_id,
       xdl.program_update_date,
       xdl.sold_out_class,                                         --売切区分
       xdl.sold_out_time,                                          --売切時間
       xdl.inventory_item_id,                                      --品目ID
       xdl.standard_unit,                                          --基準単位
       xdl.order_no_ebs order_no_ebs,                              --受注No.（EBS）
/* 2009/05/28 Ver1.2 Add Start */
       xdl.line_number_ebs                                         --明細番号(EBS)
/* 2009/05/28 Ver1.2 Add End   */
FROM
       xxcos_dlv_lines       xdl,                             --納品明細テーブル
       xxcos_dlv_headers     xdh,                             --納品ヘッダテーブル
       mtl_system_items_b    mtl_item,
       ic_item_mst_b         ic_item,
       xxcmm_system_items_b  cmm_item,
       xxcmn_item_mst_b      cmn_mst,
/* 2009/08/03 Ver1.5 Mod Start */
--       (
--       --売上区分
--/* 2009/07/06 Ver1.4 Mod Start */
----       SELECT look_val.lookup_code lookup_code
----             ,look_val.meaning meaning
----       FROM    fnd_lookup_values     look_val,
----               fnd_lookup_types_tl   types_tl,
----               fnd_lookup_types      types,
----               fnd_application_tl    appl,
----               fnd_application       app
----       WHERE   appl.application_id   = types.application_id
----       AND     look_val.language     = 'JA'
----       AND     appl.language         = 'JA'
----       AND     types_tl.lookup_type  = look_val.lookup_type
----       AND     app.application_id    = appl.application_id
----       AND     look_val.lookup_type = 'XXCOS1_SALE_CLASS'
----       AND     app.application_short_name = 'XXCOS'
----       AND     types.lookup_type = types_tl.lookup_type
----       AND     types.security_group_id = types_tl.security_group_id
----       AND     types.view_application_id = types_tl.view_application_id
----       AND     types_tl.language = userenv('LANG')
----       AND     xxccp_common_pkg2.get_process_date      >= 
----         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
----       AND     xxccp_common_pkg2.get_process_date      <= 
----         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--       SELECT look_val.lookup_code lookup_code
--             ,look_val.meaning meaning
--       FROM    fnd_lookup_values     look_val
--       WHERE   look_val.language     = 'JA'
--       AND     look_val.lookup_type = 'XXCOS1_SALE_CLASS'
--       AND     xxccp_common_pkg2.get_process_date      >= 
--         NVL(look_val.start_date_active,TO_DATE( '1900/01/01', 'YYYY/MM/DD' ))
--       AND     xxccp_common_pkg2.get_process_date      <= 
--         NVL(look_val.end_date_active,TO_DATE( '9999/12/31', 'YYYY/MM/DD' ))
--/* 2009/07/06 Ver1.4 Mod End   */
--       AND     look_val.enabled_flag = 'Y'
--/* 2009/07/06 Ver1.4 Delete Start */
----       ORDER BY look_val.lookup_code
--/* 2009/07/06 Ver1.4 Delete End   */
--       ) sc,
--       (
--       --H/C区分
--/* 2009/07/06 Ver1.4 Mod Start */
----       SELECT look_val.lookup_code lookup_code
----             ,look_val.meaning meaning
----       FROM    fnd_lookup_values     look_val,
----               fnd_lookup_types_tl   types_tl,
----               fnd_lookup_types      types,
----               fnd_application_tl    appl,
----               fnd_application       app
----       WHERE   appl.application_id   = types.application_id
----       AND     look_val.language     = 'JA'
----       AND     appl.language         = 'JA'
----       AND     types_tl.lookup_type  = look_val.lookup_type
----       AND     app.application_id    = appl.application_id
----       AND     look_val.lookup_type = 'XXCOS1_HC_CLASS'
----       AND     app.application_short_name = 'XXCOS'
----       AND     types.lookup_type = types_tl.lookup_type
----       AND     types.security_group_id = types_tl.security_group_id
----       AND     types.view_application_id = types_tl.view_application_id
----       AND     types_tl.language = userenv('LANG')
----       AND     look_val.attribute1 = 'Y'
----       AND     xxccp_common_pkg2.get_process_date      >= 
----         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
----       AND     xxccp_common_pkg2.get_process_date      <= 
----         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--       SELECT look_val.lookup_code lookup_code
--             ,look_val.meaning meaning
--       FROM    fnd_lookup_values     look_val
--       WHERE   look_val.language     = 'JA'
--       AND     look_val.lookup_type = 'XXCOS1_HC_CLASS'
--       AND     look_val.attribute1 = 'Y'
--       AND     xxccp_common_pkg2.get_process_date      >= 
--         NVL(look_val.start_date_active,TO_DATE( '1900/01/01', 'YYYY/MM/DD' ))
--       AND     xxccp_common_pkg2.get_process_date      <= 
--         NVL(look_val.end_date_active,TO_DATE( '9999/12/31', 'YYYY/MM/DD' ))
--/* 2009/07/06 Ver1.4 Mod End   */
--       AND     look_val.enabled_flag = 'Y'
--/* 2009/07/06 Ver1.4 Delete Start */
----       ORDER BY look_val.lookup_code
--/* 2009/07/06 Ver1.4 Delete End   */
--       ) hac,
       fnd_lookup_values      sc,
       fnd_lookup_values      hac,
       (
       --営業日
/* 2009/09/03 Ver1.6 Mod Start */
--       SELECT xxccp_common_pkg2.get_process_date process_date
--       FROM   DUAL
       SELECT TRUNC( xpd.process_date ) process_date
       FROM   xxccp_process_dates xpd
/* 2009/09/03 Ver1.6 Mod End   */
       )                      pd,
       (
       --在庫組織ID
       SELECT xxcoi_common_pkg.get_organization_id( FND_PROFILE.VALUE(  'XXCOI1_ORGANIZATION_CODE' ) ) organization_id
       FROM   DUAL
       )                      org,
/* 2009/08/03 Ver1.5 Mod End   */
       xxcoi_mst_vd_column    xmvc
       , hz_cust_accounts     cust              
/* 2012/01/05 Ver1.7 Add Start */
       , xxcmm_cust_accounts  xcust
/* 2012/01/05 Ver1.7 Add End */                                                                               
WHERE  xdl.order_no_hht = xdh.order_no_hht
AND    xdl.digestion_ln_number = xdh.digestion_ln_number
/* 2009/08/03 Ver1.5 Mod Start */
--AND    xdl.h_and_c = hac.lookup_code(+)
--AND    xdl.sale_class IN (
--        sc.lookup_code
--       )
AND    hac.lookup_type(+)      = 'XXCOS1_HC_CLASS'
AND    hac.lookup_code(+)      = xdl.h_and_c
AND    hac.language(+)         = 'JA'
AND    hac.enabled_flag(+)     = 'Y'
AND    pd.process_date         BETWEEN  NVL( hac.start_date_active, pd.process_date )
                               AND      NVL( hac.end_date_active, pd.process_date )
AND    sc.lookup_type          = 'XXCOS1_SALE_CLASS'
AND    sc.lookup_code          = xdl.sale_class
AND    sc.language             = 'JA'
AND    sc.enabled_flag         = 'Y'
AND    pd.process_date         BETWEEN  NVL( sc.start_date_active, pd.process_date )
                               AND      NVL( sc.end_date_active, pd.process_date )
/* 2009/08/03 Ver1.5 Mod End   */
AND    xdl.item_code_self = ic_item.item_no
/* 2009/08/03 Ver1.5 Mod Start */
--AND    mtl_item.organization_id =  
--       xxcoi_common_pkg.get_organization_id( FND_PROFILE.VALUE(  'XXCOI1_ORGANIZATION_CODE' ) )
AND    mtl_item.organization_id   = org.organization_id
/* 2009/08/03 Ver1.5 Mod End   */
AND    mtl_item.segment1          = ic_item.item_no
AND    ic_item.item_id            = cmn_mst.item_id
AND    mtl_item.segment1 = cmm_item.item_code
AND    ic_item.item_id            = cmm_item.item_id
/* 2009/08/03 Ver1.5 Mod Start */
--AND    cmn_mst.start_date_active  <= xxccp_common_pkg2.get_process_date
--AND    cmn_mst.end_date_active    >= xxccp_common_pkg2.get_process_date
AND    pd.process_date            BETWEEN cmn_mst.start_date_active
                                  AND     cmn_mst.end_date_active
/* 2009/08/03 Ver1.5 Mod End   */
AND    xdh.customer_number        = cust.account_number  
/* 2012/01/05 Ver1.7 Add Start */
AND    cust.cust_account_id                = xcust.customer_id
AND    xcust.business_low_type   IN ('24','25','27')
/* 2012/01/05 Ver1.7 Add End */
/* 2012/01/05 Ver1.7 Mod Start */
--AND    cust.cust_account_id       = nvl(xmvc.customer_id, cust.cust_account_id)
--AND    xdl.column_no              = xmvc.column_no(+)
AND    cust.cust_account_id       = xmvc.customer_id
AND    xdl.column_no              = xmvc.column_no
/* 2012/01/05 Ver1.7 Mod End */
/* 2011/12/26 Ver1.7 Add Start */
UNION ALL
SELECT
       xdh.order_no_hht order_no_hht,                              --受注No.（HHT)
       xdl.line_no_hht line_no_hht,                                --行No.
       xdl.digestion_ln_number digestion_ln_number,                --枝番
       xdl.column_no column_no,                                    --コラムNo.
       xdl.h_and_c h_and_c,                                        --H/C
       hac.meaning h_and_c_name,                                   --H/C名称
       xdl.item_code_self item_code_self,                          --品名コード
       cmn_mst.item_name,                                          --品目（名称）
       abs( xdl.case_number ) abs_case_number,                     --ケース数（画面用:絶対値）
       xdl.case_number case_number,                                --ケース数（DB値）
       abs( xdl.quantity ) abs_quantity,                           --数量（画面用:絶対値）
       xdl.quantity quantity,                                      --数量（DB値）
       xdl.sale_class sale_class,                                  --売上区分
       sc.meaning  sale_name,                                      --売上区分(名称)
       abs( xdl.wholesale_unit_ploce ) abs_wholesale_unit_ploce,   --卸単価（画面用:絶対値）
       xdl.wholesale_unit_ploce wholesale_unit_ploce,              --卸単価（DB値）
       abs( xdl.selling_price ) abs_selling_price,                 --売単価（画面用:絶対値）
       xdl.selling_price selling_price,                            --売単価（DB値）
       abs(xdl.replenish_number) abs_replenish_number,             --補充数（画面用:絶対値）
       xdl.replenish_number replenish_number,                      --補充数（DB値）
       abs(xdl.cash_and_card) abs_cash_and_card,                   --現金・カード併用額（画面用:絶対値）
       xdl.cash_and_card cash_and_card,                            --現金・カード併用額（DB値）
       NULL inventory_quantity,                                     --基準在庫数
       xdl.content content,                                        --入数
       cmm_item.baracha_div,                                       --バラ茶区分
       xdl.created_by,
       xdl.creation_date,
       xdl.last_updated_by,
       xdl.last_update_date,
       xdl.last_update_login,
       xdl.request_id,
       xdl.program_application_id,
       xdl.program_id,
       xdl.program_update_date,
       xdl.sold_out_class,                                         --売切区分
       xdl.sold_out_time,                                          --売切時間
       xdl.inventory_item_id,                                      --品目ID
       xdl.standard_unit,                                          --基準単位
       xdl.order_no_ebs order_no_ebs,                              --受注No.（EBS）
       xdl.line_number_ebs                                         --明細番号(EBS)
FROM
       xxcos_dlv_lines       xdl,                             --納品明細テーブル
       xxcos_dlv_headers     xdh,                             --納品ヘッダテーブル
       mtl_system_items_b    mtl_item,
       ic_item_mst_b         ic_item,
       xxcmm_system_items_b  cmm_item,
       xxcmn_item_mst_b      cmn_mst,
       fnd_lookup_values      sc,
       fnd_lookup_values      hac,
       (
       --営業日
       SELECT TRUNC( xpd.process_date ) process_date
       FROM   xxccp_process_dates xpd
       )                      pd,
       (
       --在庫組織ID
       SELECT xxcoi_common_pkg.get_organization_id( FND_PROFILE.VALUE(  'XXCOI1_ORGANIZATION_CODE' ) ) organization_id
       FROM   DUAL
       )                      org
       , hz_cust_accounts     cust
       , xxcmm_cust_accounts  xcust
WHERE  xdl.order_no_hht = xdh.order_no_hht
AND    xdl.digestion_ln_number = xdh.digestion_ln_number
AND    hac.lookup_type(+)      = 'XXCOS1_HC_CLASS'
AND    hac.lookup_code(+)      = xdl.h_and_c
AND    hac.language(+)         = 'JA'
AND    hac.enabled_flag(+)     = 'Y'
AND    pd.process_date         BETWEEN  NVL( hac.start_date_active, pd.process_date )
                               AND      NVL( hac.end_date_active, pd.process_date )
AND    sc.lookup_type          = 'XXCOS1_SALE_CLASS'
AND    sc.lookup_code          = xdl.sale_class
AND    sc.language             = 'JA'
AND    sc.enabled_flag         = 'Y'
AND    pd.process_date         BETWEEN  NVL( sc.start_date_active, pd.process_date )
                               AND      NVL( sc.end_date_active, pd.process_date )
AND    xdl.item_code_self = ic_item.item_no
AND    mtl_item.organization_id   = org.organization_id
AND    mtl_item.segment1          = ic_item.item_no
AND    ic_item.item_id            = cmn_mst.item_id
AND    mtl_item.segment1 = cmm_item.item_code
AND    ic_item.item_id            = cmm_item.item_id
AND    pd.process_date            BETWEEN cmn_mst.start_date_active
                                  AND     cmn_mst.end_date_active
AND    xdh.customer_number        = cust.account_number
AND    cust.cust_account_id                = xcust.customer_id
AND    xcust.business_low_type NOT IN ('24','25','27')
/* 2011/12/26 Ver1.7 Add End */
;
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ORDER_NO_HHT              IS '受注No.（HHT)';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LINE_NO_HHT               IS '行No.';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.DIGESTION_LN_NUMBER       IS '枝番';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.COLUMN_NO                 IS 'コラムNo.';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.H_AND_C                   IS 'H/C';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.H_AND_C_NAME              IS 'H/C名称';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ITEM_CODE_SELF            IS '品名コード';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ITEM_NAME                 IS '品目（名称）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_CASE_NUMBER           IS 'ケース数（画面用:絶対値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CASE_NUMBER               IS 'ケース数（DB値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_QUANTITY              IS '数量（画面用:絶対値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.QUANTITY                  IS '数量（DB値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SALE_CLASS                IS '売上区分';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SALE_NAME                 IS '売上区分(名称)';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_WHOLESALE_UNIT_PLOCE  IS '卸単価（画面用:絶対値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.WHOLESALE_UNIT_PLOCE      IS '卸単価（DB値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_SELLING_PRICE         IS '売単価（画面用:絶対値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SELLING_PRICE             IS '売単価（DB値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_REPLENISH_NUMBER      IS '補充数（画面用:絶対値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.REPLENISH_NUMBER          IS '補充数（DB値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_CASH_AND_CARD         IS '現金・カード併用額（画面用:絶対値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CASH_AND_CARD             IS '現金・カード併用額（DB値）';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.INVENTORY_QUANTITY        IS '基準在庫数';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CONTENT                   IS '入数';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.BARACHA_DIV               IS 'バラ茶区分';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CREATED_BY                IS '作成者';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CREATION_DATE             IS '作成日';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LAST_UPDATED_BY           IS '最終更新者';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LAST_UPDATE_DATE          IS '最終更新日';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LAST_UPDATE_LOGIN         IS '最終更新ログイン';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.REQUEST_ID                IS '要求ID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.PROGRAM_APPLICATION_ID    IS 'コンカレント・プログラムアプリケーションID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.PROGRAM_ID                IS 'コンカレント・プログラムID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.PROGRAM_UPDATE_DATE       IS 'プログラム更新日'; 
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SOLD_OUT_CLASS            IS '売切区分';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SOLD_OUT_TIME             IS '売切時間';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.INVENTORY_ITEM_ID         IS '品目ID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.STANDARD_UNIT             IS '基準単位';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ORDER_NO_EBS              IS '受注No.（EBS）';
/* 2009/05/28 Ver1.2 Add Start */
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LINE_NUMBER_EBS           IS '明細番号(EBS)';
/* 2009/05/28 Ver1.2 Add End   */
--
COMMENT ON  TABLE   xxcos_dlv_lines_info_v                           IS '納品伝票明細情報ビュー';
