/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dlv_headers_info_v
 * Description     : 納品伝票ヘッダ情報ビュー
 * Version         : 1.10
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/08    1.0   T.Tyou           新規作成
 *  2009/04/09    1.1   K.kiriu          [T1_0248]百貨店HHT区分と百貨店画面種別の不整合修正
 *                                       [T1_0259]納品者の結合不正対応
 *  2009/06/03    1.2   K.Kiriu          [T1_1269]パフォーマンス対応
 *  2009/07/06    1.3   T.Miyata         [0000409]パフォーマンス対応
 *  2009/08/03    1.4   K.Kiriu          [0000872]パフォーマンス対応
 *  2009/09/01    1.5   K.Kiriu          [0000929]有効訪問件数のカウント方法変更対応
 *  2009/09/03    1.6   M.Sano           [0001227]パフォーマンス対応
 *                                       (業務日付の取得方法変更)
 *  2009/11/27    1.7   M.Sano           [E_本稼動_00130]重複データ対応
 *  2009/12/16    1.8   K.Kiriu          [E_本稼動_00244]売上値引のみのデータ(ヘッダのみ作成)対応
 *  2011/03/22    1.9   M.Hirose         [E_本稼動_06590]オーダーNoの追加
 *  2011/04/18    1.10  M.Hirose         [E_本稼動_07075]営業担当員ビューの削除
 *                                                       ヒント句修正
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_dlv_headers_info_v
(
  order_no_hht,
  digestion_ln_number,
  order_no_ebs,
  base_code,
  performance_by_code,
  source_name,
  dlv_by_code,
  dlv_by_name,
  hht_invoice_no,
  dlv_date,
  inspect_date,
  sales_classification,
  sales_invoice,
  card_sale_class,
  card_sale_name,
  dlv_time,
  customer_number,
  customer_name,
  input_class,
  input_name,
  consumption_tax_class,
  abs_total_amount,
  total_amount,
  abs_sale_discount_amount,
  sale_discount_amount,
  abs_sales_consumption_tax,
  sales_consumption_tax,
  abs_tax_include,
  tax_include,
  keep_in_code,
  department_screen_class,
  department_screen_name,
  red_black_flag,
  customer_status,
  employee_number,
  business_low_type,
  change_out_time_100,
  change_out_time_10,
  stock_forward_flag,
  stock_forward_date,
  results_forward_flag,
  results_forward_date,
  cancel_correct_class,
  created_by,
  creation_date,
  last_updated_by,
  last_update_date,
  last_update_login,
  request_id,
  program_application_id,
  program_id,
  program_update_date,
  customer_id
  ,party_id
  ,resource_id
/* 2011/03/22 Ver1.9 Add Start */
  ,order_number
/* 2011/03/22 Ver1.9 Add End   */
)
AS
SELECT
/* 2011/04/18 Ver1.10 Mod Start */
--/* 2009/08/03 Ver1.4 Add Start */
--       /*+ LEADING(xdh) */
--/* 2009/08/03 Ver1.4 Add End   */
       /*+
          LEADING(xdh cust custadd hp papf papf_dlv csc ic dsc pd)
          USE_NL (xdh cust custadd hp papf papf_dlv csc ic dsc pd)
       */
/* 2011/04/18 Ver1.10 Mod End */
/* 2009/11/27 Ver1.7 Mod Start */
       DISTINCT
/* 2009/11/27 Ver1.7 Mod End   */
       xdh.order_no_hht order_no_hht,                              --受注No.（HHT)
       xdh.digestion_ln_number digestion_ln_number,                --枝番
       xdh.order_no_ebs order_no_ebs,                              --受注No.（EBS）
       xdh.base_code base_code,                                    --拠点コード
       xdh.performance_by_code performance_by_code,                --成績者コード
       papf.per_information18||' '||papf.per_information19 source_name,                             --成績者名称
       xdh.dlv_by_code dlv_by_code,                                --納品者コード
/* 2009/04/09 Ver1.1 Mod Start */
--       xsv.kanji_last || ' ' || xsv.kanji_first dlv_by_name,       --納品者名称
       papf_dlv.per_information18||' '||papf_dlv.per_information19 dlv_by_name,                     --納品者名称
/* 2009/04/09 Ver1.1 Mod End   */
       xdh.hht_invoice_no hht_invoice_no,                          --伝票No.
       xdh.dlv_date dlv_date,                                      --納品日
       xdh.inspect_date inspect_date,                              --検収日
       xdh.sales_classification sales_classification,              --売上分類区分
       xdh.sales_invoice sales_invoice,                            --売上伝票区分
       xdh.card_sale_class card_sale_class,                        --カード売区分
       csc.meaning card_sale_name,                                 --カード売区分表示用
       xdh.dlv_time dlv_time,                                      --時間
       xdh.customer_number customer_number,                        --顧客コード
/* 2011/04/18 Ver1.10 Mod Start */
--       xsv.party_name customer_name ,                              --顧客名称
       hp.party_name customer_name ,                               --顧客名称
/* 2011/04/18 Ver1.10 Mod End   */
       xdh.input_class input_class,                                --入力区分
       ic.meaning input_name,                                      --入力区分表示用
       xdh.consumption_tax_class consumption_tax_class,            --消費税区分
       abs( xdh.total_amount ) abs_total_amount,                   --合計金額（画面用:絶対値）
/* 2009/12/16 Ver1.28 Mod Start */
--       xdh.total_amount total_amount,                              --合計金額（DB値）
       DECODE(
         ( SELECT 1
           FROM   xxcos_dlv_lines xdl
           WHERE  xdl.order_no_hht        = xdh.order_no_hht
           AND    xdl.digestion_ln_number = xdh.digestion_ln_number
           AND    ROWNUM                  = 1
         )
         , 1, xdh.total_amount
         , NULL
       ) total_amount,                                             --合計金額（DB値）
/* 2009/12/16 Ver1.28 Mod END   */
       abs( xdh.sale_discount_amount ) abs_sale_discount_amount,   --売上値引金額（画面用:絶対値）
       xdh.sale_discount_amount sale_discount_amount,              --売上値引金額（DB値）
       abs( xdh.sales_consumption_tax ) abs_sales_consumption_tax, --売上消費税額（画面用:絶対値）
       xdh.sales_consumption_tax sales_consumption_tax,            --売上消費税額（DB値）
       abs( xdh.tax_include ) abs_tax_include,                     --税込金額（画面用:絶対値）
/* 2009/12/16 Ver1.28 Mod Start */
--       xdh.tax_include tax_include,                                --税込金額（DB値）
       DECODE(
         ( SELECT 1
           FROM   xxcos_dlv_lines xdl
           WHERE  xdl.order_no_hht        = xdh.order_no_hht
           AND    xdl.digestion_ln_number = xdh.digestion_ln_number
           AND    ROWNUM                  = 1
         )
         , 1, xdh.tax_include
         , NULL
       ) tax_include,                                              --合計金額（DB値）
/* 2009/12/16 Ver1.28 Mod END   */
       xdh.keep_in_code keep_in_code,                              --預け先コード
       xdh.department_screen_class department_screen_class,        --百貨店画面種別
       dsc.meaning department_screen_name,                         --百貨店画面種別表示用
       xdh.red_black_flag red_black_flag,                          --赤黒フラグ
       hp.duns_number_c customer_status,                           --顧客ステータス
/* 2009/11/27 Ver1.7 Mod Start */
--       xsv.employee_number employee_number,                        --営業員コード
       NULL employee_number,                                       --営業員コード(null)
/* 2009/11/27 Ver1.7 Mod End   */
       custadd.business_low_type business_low_type,                --業態小分類
       xdh.change_out_time_100 change_out_time_100,                --つり銭切れ時間100円
       xdh.change_out_time_10 change_out_time_10,                  --つり銭切れ時間10円
       xdh.stock_forward_flag stock_forward_flag,                  --入出庫転送済フラグ
       xdh.stock_forward_date stock_forward_date,                  --入出庫転送済日付
       xdh.results_forward_flag results_forward_flag,              --販売実績連携済フラグ
       xdh.results_forward_date results_forward_date,              --販売実績連携済日付
       xdh.cancel_correct_class cancel_correct_class,              --取消・訂正区分
       xdh.created_by,
       xdh.creation_date,
       xdh.last_updated_by,
       xdh.last_update_date,
       xdh.last_update_login,
       xdh.request_id,
       xdh.program_application_id,
       xdh.program_id,
       xdh.program_update_date
       ,custadd.customer_id customer_id                            --明細のコラムNO結合のため
/* 2009/09/01 Mod Start */
--       ,xsv.party_id
--       ,xsv.resource_id
       ,NULL                                                      --有効訪問は新規登録時のみの為
       ,NULL                                                      --有効訪問は新規登録時のみの為
/* 2009/09/01 Mod End   */
/* 2011/03/22 Ver1.9 Add Start */
       ,xdh.order_number                                          -- オーダーNo
/* 2011/03/22 Ver1.9 Add End   */
FROM
       xxcos_dlv_headers    xdh,                                  --納品ヘッダテーブル
       xxcmm_cust_accounts  custadd,                              --顧客アドオン
/* 2011/04/18 Ver1.10 Mod Start */
--       xxcos_salesreps_v    xsv,                                  --担当者営業員ビュー(顧客関連)
       hz_cust_accounts     cust,                                 --顧客マスタ
/* 2011/04/18 Ver1.10 Mod End   */
       hz_parties           hp,                                   --party
       per_all_people_f     papf,                                 --従業員マスタ
/* 2009/04/09 Ver1.1 Add Start */
       per_all_people_f     papf_dlv,                             --従業員マスタ(納品者)
/* 2009/04/09 Ver1.1 Add End   */
/* 2009/08/03 Ver1.4 Mod Start */
--       (
--       --カード売区分
--/* 2009/06/03 Ver1.2 Mod Start */
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
----       AND     look_val.lookup_type = 'XXCOS1_CARD_SALE_CLASS'
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
----       AND     look_val.enabled_flag = 'Y'
----       ORDER BY look_val.lookup_code]
--       SELECT  xlvv.lookup_code        lookup_code
--              ,xlvv.meaning            meaning
--              ,xlvv.start_date_active  start_date_active
--              ,xlvv.end_date_active    end_date_active
--       FROM    xxcos_lookup_values_v  xlvv
--       WHERE   xlvv.lookup_type    = 'XXCOS1_CARD_SALE_CLASS'
--       AND     xlvv.attribute1     = 'Y'
--/* 2009/06/03 Ver1.2 Mod End   */
--       ) csc,
--       (
--       --入力区分
--/* 2009/06/03 Ver1.2 Mod Start */
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
----       AND     look_val.lookup_type = 'XXCOS1_INPUT_CLASS'
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
----       AND     look_val.enabled_flag = 'Y'
----       ORDER BY look_val.lookup_code
--       SELECT  xlvv.lookup_code        lookup_code
--              ,xlvv.meaning            meaning
--              ,xlvv.start_date_active  start_date_active
--              ,xlvv.end_date_active    end_date_active
--       FROM    xxcos_lookup_values_v  xlvv
--       WHERE   xlvv.lookup_type = 'XXCOS1_INPUT_CLASS'
--       AND     xlvv.attribute1  = 'Y'
--/* 2009/06/03 Ver1.2 Mod End   */
--       ) ic,
--       (
--       --百貨店画面種別
--/* 2009/06/03 Ver1.2 Mod Start */
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
----       AND     look_val.lookup_type = 'XXCOS1_DEPARTMENT_SCREEN_CLASS'
----       AND     app.application_short_name = 'XXCOS'
----       AND     types.lookup_type = types_tl.lookup_type
----       AND     types.security_group_id = types_tl.security_group_id
----       AND     types.view_application_id = types_tl.view_application_id
----       AND     types_tl.language = userenv('LANG')
--/* 2009/04/09 Ver1.1 Del Start */
----       AND     look_val.attribute2 = 'Y'
--/* 2009/04/09 Ver1.1 Del End   */
----       AND     xxccp_common_pkg2.get_process_date      >= 
----         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
----       AND     xxccp_common_pkg2.get_process_date      <= 
----         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
----       AND     look_val.enabled_flag = 'Y'
--/* 2009/04/09 Ver1.1 Del Start */
----       ORDER BY look_val.lookup_code
--/* 2009/04/09 Ver1.1 Del End   */
----       ) dsc
--       SELECT  xlvv.lookup_code        lookup_code
--              ,xlvv.meaning            meaning
--              ,xlvv.start_date_active  start_date_active
--              ,xlvv.end_date_active    end_date_active
--       FROM    xxcos_lookup_values_v  xlvv
--       WHERE   xlvv.lookup_type = 'XXCOS1_DEPARTMENT_SCREEN_CLASS'
--       ) dsc,
--/* 2009/06/03 Ver1.2 Mod End   */
--/* 2009/06/03 Ver1.2 Add Start */
       fnd_lookup_values    csc,  -- カード売区分
       fnd_lookup_values    ic,   -- 入力区分
       fnd_lookup_values    dsc,  -- 百貨店画面種別
/* 2009/08/03 Ver1.4 Mod End   */
       (
       --営業日
/* 2009/09/03 Ver1.6 Mod Start */
--       SELECT xxccp_common_pkg2.get_process_date process_date
--       FROM   DUAL
       SELECT TRUNC( xpd.process_date ) process_date
       FROM   xxccp_process_dates xpd
/* 2009/09/03 Ver1.6 Mod End   */
       ) pd
/* 2009/06/03 Ver1.2 Add End   */
/* 2011/04/18 Ver1.10 Mod Start */
--WHERE  xdh.customer_number = xsv.account_number
--AND    xsv.cust_account_id = custadd.customer_id 
--AND    hp.party_id         = xsv.party_id
WHERE  xdh.customer_number  = cust.account_number
AND    cust.cust_account_id = custadd.customer_id 
AND    hp.party_id          = cust.party_id
/* 2011/04/18 Ver1.10 Mod End   */
/* 2009/04/09 Ver1.1 Del Start */
--AND    xdh.dlv_by_code     = xsv.employee_number   --2009/01/09追加
/* 2009/04/09 Ver1.1 Del End   */
/* 2009/07/06 Ver1.3 Mod Start   */
--/* 2009/06/03 Ver1.2 Mod Start   */
----AND    (xdh.dlv_date >=  
----  NVL(xsv.effective_start_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
----AND    xdh.dlv_date <=  
----  NVL(xsv.effective_end_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
----OR
----       add_months( xdh.dlv_date, -1 ) >=  
----       NVL(xsv.effective_start_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
----AND    add_months( xdh.dlv_date, -1 ) <=  
----       NVL(xsv.effective_end_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
----       )
----AND    xdh.card_sale_class = csc.lookup_code(+)
----AND    xdh.input_class IN (
----        ic.lookup_code
----       )
--AND    (
--         xdh.dlv_date >=
--           NVL( xsv.effective_start_date, FND_DATE.STRING_TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
--         AND
--         xdh.dlv_date <=  
--           NVL( xsv.effective_end_date, FND_DATE.STRING_TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
--       OR
--         add_months( xdh.dlv_date, -1 ) >=  
--           NVL( xsv.effective_start_date, FND_DATE.STRING_TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
--         AND
--         add_months( xdh.dlv_date, -1 ) <=  
--           NVL( xsv.effective_end_date, FND_DATE.STRING_TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
--       )
--AND    xdh.card_sale_class  = csc.lookup_code
--AND    pd.process_date     >= NVL(csc.start_date_active, pd.process_date)
--AND    pd.process_date     <= NVL(csc.end_date_active, pd.process_date)
--AND    xdh.input_class      = ic.lookup_code
--AND    pd.process_date     >= NVL(ic.start_date_active, pd.process_date)
--AND    pd.process_date     <= NVL(ic.end_date_active, pd.process_date)
--/* 2009/06/03 Ver1.2 Mod End   */
/* 2009/08/03 Ver1.4 Mod Start */
--AND    (
--         xdh.dlv_date >=
--           NVL( xsv.effective_start_date, TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
--         AND
--         xdh.dlv_date <=  
--           NVL( xsv.effective_end_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
--       OR
--         add_months( xdh.dlv_date, -1 ) >=  
--           NVL( xsv.effective_start_date, TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
--         AND
--         add_months( xdh.dlv_date, -1 ) <=  
--           NVL( xsv.effective_end_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
--       )
--AND    xdh.card_sale_class  = csc.lookup_code
--AND    pd.process_date     >= NVL(csc.start_date_active, pd.process_date)
--AND    pd.process_date     <= NVL(csc.end_date_active, pd.process_date)
--AND    xdh.input_class      = ic.lookup_code
--AND    pd.process_date     >= NVL(ic.start_date_active, pd.process_date)
--AND    pd.process_date     <= NVL(ic.end_date_active, pd.process_date)
--/* 2009/07/06 Ver1.3 Mod End   */
/* 2011/04/18 Ver1.10 Del Start */
--AND    (
--         xdh.dlv_date BETWEEN  NVL( xsv.effective_start_date, TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
--                      AND      NVL( xsv.effective_end_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
--       OR
--         ADD_MONTHS( xdh.dlv_date, -1 ) BETWEEN  NVL( xsv.effective_start_date, TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
--                                        AND      NVL( xsv.effective_end_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
--       )
/* 2011/04/18 Ver1.10 Del End   */
AND    csc.lookup_type      = 'XXCOS1_CARD_SALE_CLASS'
AND    csc.lookup_code      = xdh.card_sale_class
AND    csc.attribute1       = 'Y'
AND    csc.language         = 'JA'
AND    csc.enabled_flag     = 'Y'
AND    pd.process_date      BETWEEN  NVL( csc.start_date_active, pd.process_date )
                            AND      NVL( csc.end_date_active, pd.process_date )
AND    ic.lookup_type       = 'XXCOS1_INPUT_CLASS'
AND    ic.lookup_code       =  xdh.input_class
AND    ic.attribute1        = 'Y'
AND    ic.language          = 'JA'
AND    ic.enabled_flag      = 'Y'
AND    pd.process_date      BETWEEN  NVL( ic.start_date_active, pd.process_date )
                            AND      NVL( ic.end_date_active, pd.process_date )
/* 2009/08/03 Ver1.4 Mod End   */
/* 2009/04/09 Ver1.1 Mod Start */
--AND  ( xdh.department_screen_class IS NULL    --2009/02/06追加 仕様変更のため
--       OR
--       xdh.department_screen_class IN (
--         dsc.lookup_code
--       )
--     )
/* 2009/08/03 Ver1.4 Mod Start */
--AND    xdh.department_screen_class = dsc.lookup_code
--/* 2009/04/09 Ver1.1 Mod End   */
--/* 2009/06/03 Ver1.2 Add Start */
--AND    pd.process_date     >= NVL(dsc.start_date_active, pd.process_date)
--AND    pd.process_date     <= NVL(dsc.end_date_active, pd.process_date)
--/* 2009/06/03 Ver1.2 Add End   */
--/* 2009/04/09 Ver1.1 Add Start */
AND    dsc.lookup_type      = 'XXCOS1_DEPARTMENT_SCREEN_CLASS'
AND    dsc.lookup_code      =  xdh.department_screen_class
AND    dsc.language         = 'JA'
AND    dsc.enabled_flag     = 'Y'
AND    pd.process_date      BETWEEN  NVL( dsc.start_date_active, pd.process_date )
                            AND      NVL( dsc.end_date_active, pd.process_date )
/* 2009/08/03 Ver1.4 Mod End   */
AND    xdh.dlv_by_code     = papf_dlv.employee_number
/* 2009/06/03 Ver1.2 Mod Start */
--AND    xdh.dlv_date >=
--  NVL(papf_dlv.effective_start_date, FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--AND    xdh.dlv_date <=
--  NVL(papf_dlv.effective_end_date, FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
/* 2009/08/03 Ver1.4 Mod Start */
--AND    xdh.dlv_date        >= papf_dlv.effective_start_date
--AND    xdh.dlv_date        <= papf_dlv.effective_end_date
AND    xdh.dlv_date        BETWEEN   papf_dlv.effective_start_date
                           AND       papf_dlv.effective_end_date
/* 2009/08/03 Ver1.4 Mod End   */
/* 2009/06/03 Ver1.2 Mod End   */
/* 2009/04/09 Ver1.1 Add End   */
AND    xdh.performance_by_code = papf.employee_number    --2009/01/09変更 納品者ー＞成績者
/* 2009/06/03 Ver1.2 Mod Start */
--AND    xdh.dlv_date >=
--  NVL(papf.effective_start_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--AND    xdh.dlv_date <=
--  NVL(papf.effective_end_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
/* 2009/08/03 Ver1.4 Mod Start */
--AND    xdh.dlv_date            >= papf.effective_start_date
--AND    xdh.dlv_date            <= papf.effective_end_date
AND    xdh.dlv_date        BETWEEN   papf.effective_start_date
                           AND       papf.effective_end_date
/* 2009/08/03 Ver1.4 Mod End   */
/* 2009/06/03 Ver1.2 Mod End   */
;
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.order_no_hht                IS  '受注No.(HHT)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.digestion_ln_number         IS  '枝番';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.order_no_ebs                IS  '受注No.(EBS)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.base_code                   IS  '拠点コード';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.performance_by_code         IS  '成績者コード';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.source_name                 IS  '成績者名称';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_by_code                 IS  '納品者コード';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_by_name                 IS  '納品者名称';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.hht_invoice_no              IS  '伝票No.';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_date                    IS  '納品日';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.inspect_date                IS  '検収日';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sales_classification        IS  '売上分類区分';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sales_invoice               IS  '売上伝票区分';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.card_sale_class             IS  'カード売区分';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.card_sale_name              IS  'カード売区分表示用';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_time                    IS  '時間';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_number             IS  '顧客コード';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_name               IS  '顧客名称';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.input_class                 IS  '入力区分';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.input_name                  IS  '入力区分表示用';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.consumption_tax_class       IS  '消費税区分';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_total_amount            IS  '合計金額(画面用:絶対値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.total_amount                IS  '合計金額(DB値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_sale_discount_amount    IS  '売上値引金額(画面用:絶対値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sale_discount_amount        IS  '売上値引金額(DB値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_sales_consumption_tax   IS  '売上消費税額(画面用:絶対値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sales_consumption_tax       IS  '売上消費税額(DB値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_tax_include             IS  '税込金額(画面用:絶対値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.tax_include                 IS  '税込金額(DB値)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.keep_in_code                IS  '預け先コード';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.department_screen_class     IS  '百貨店画面種別';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.department_screen_name      IS  '百貨店画面種別表示用';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.red_black_flag              IS  '赤黒フラグ';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_status             IS  '顧客ステータス';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.employee_number             IS  '営業員コード';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.business_low_type           IS  '業態小分類';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.change_out_time_100         IS  'つり銭切れ時間100円';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.change_out_time_10          IS  'つり銭切れ時間10円';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.stock_forward_flag          IS  '入出庫転送済フラグ';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.stock_forward_date          IS  '入出庫転送済日付';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.results_forward_flag        IS  '販売実績連携済フラグ';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.results_forward_date        IS  '販売実績連携済日付';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.cancel_correct_class        IS  '取消・訂正区分';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.created_by                  IS  '作成者';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.creation_date               IS  '作成日';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.last_updated_by             IS  '最終更新者';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.last_update_date            IS  '最終更新日';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.last_update_login           IS  '最終更新ログイン';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.request_id                  IS  '要求ID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.program_application_id      IS  'コンカレント・プログラムアプリケーションID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.program_id                  IS  'コンカレント・プログラムID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.program_update_date         IS  'プログラム更新日'; 
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_id                 IS  '顧客ID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.party_id                    IS  'パーティID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.resource_id                 IS  'リソースID';
/* 2011/03/22 Ver1.9 Add Start */
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.order_number                IS  'オーダーNo';
/* 2011/03/22 Ver1.9 Add End   */
--
COMMENT ON  TABLE   xxcos_dlv_headers_info_v                             IS  '納品伝票ヘッダ情報ビュー';
