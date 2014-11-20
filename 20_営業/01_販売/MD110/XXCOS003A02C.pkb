CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A02C(body)
 * Description      : 単価マスタIF出力（データ抽出）
 * MD.050           : 単価マスタIF出力（データ抽出） MD050_COS_003_A02
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-0．初期処理
 *  proc_main_loop         A-1．データ抽出
 *  proc_upd_n_target_line A-8. 販売実績明細対象外データ更新
 *  proc_upd_skip_line     A-7. 販売実績明細スキップデータ更新
 *  proc_insert_upm_work   A-4．単価マスタワークテーブル登録
 *  proc_update_upm_work   A-3．単価マスタワークテーブル更新
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05   1.0    K.Okaguchi       新規作成
 *  2009/02/23   1.1    K.Okaguchi       [障害COS_111] 非在庫品目を抽出しないようにする。
 *  2009/02/24   1.2    T.Nakamura       [障害COS_130] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/05/28   1.3    S.Kayahara       [障害T1_1176] 単価の導出に端数処理追加
 *  2009/06/09   1.4    N.Maeda          [障害T1_1401] 端数処理取得テーブル修正
 *  2009/07/17   1.5    K.Shirasuna      [障害PT_00016]「単価マスタIF出力」処理の性能改善
 *  2009/08/04   1.6    M.Sano           [障害0000933] 『単価マスタIF出力』PTの考慮
 *  2009/08/17   1.7    M.Sano           [障害0001044] 「単価マスタIF出力」処理の性能改善
 *  2009/08/25   1.8    K.Kiriu          [障害0001163] 「単価マスタIF出力」処理の性能改善
 *                                       [障害0000451] 単価の桁あふれ対応
 *  2009/10/15   1.9    N.Maeda          [障害0001524] 出力金額取得方法修正
 *  2009/12/13   1.10   K.Atsushiba      [E_本稼動_00290] 納品VD顧客の単価が連携されない
 *  2009/12/17   1.11   N.Maeda          [E_本稼動_00489] 処理対象基準数量桁数条件追加
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER DEFAULT 0;                    -- 対象件数
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- 正常件数
  gn_error_cnt     NUMBER DEFAULT 0;                    -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_data_check_expt    EXCEPTION;     -- データチェック時のエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A02C'; -- パッケージ名
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーション名
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- アドオン：共通・IF領域
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
/* 2009/08/25 Ver1.8 Add Start */
  cv_tkn_cust             CONSTANT VARCHAR2(20) := 'CUST_CODE';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM_CODE';
  cv_tkn_dlv_date         CONSTANT VARCHAR2(20) := 'DLV_DATE';
  cv_tkn_unit_price       CONSTANT VARCHAR2(20) := 'UNIT_PRICE';
/* 2009/08/25 Ver1.8 Add End   */
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
/* 2009/08/25 Ver1.8 Add Start */
  cv_flag_w               CONSTANT VARCHAR2(1)  := 'W';                   --スキップ
  cv_flag_s               CONSTANT VARCHAR2(1)  := 'S';                   --対象外
/* 2009/08/25 Ver1.8 Add End   */
  cv_correct              CONSTANT VARCHAR2(30) := '1';                   --取消訂正区分　=　1（訂正）
  cv_invoice_class_dliv   CONSTANT VARCHAR2(1)  := '1';                   --納品伝票区分 = 1(納品)
  cv_invoice_class_d_co   CONSTANT VARCHAR2(1)  := '3';                   --納品伝票区分 = 3(納品訂正)
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ロックエラー
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    --ロック取得エラー
  cv_msg_insert_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';    --データ登録エラーメッセージ
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    --データ更新エラーメッセージ
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    --データ抽出エラーメッセージ
  cv_tkn_tm_w_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10852';    -- 単価マスタワークテーブル
  cv_tkn_exp_l_tbl        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10701';    -- 販売実績明細テーブル
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- 顧客コード
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- 品名コード
  cv_tkn_exp_line_id      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10702';    -- 販売実績明細ID
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- パラメータなし
  cv_tkn_sales_cls_nml    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10703';    -- 通常
  cv_tkn_sales_cls_sls    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10704';    -- 特売
  cv_tkn_fnd_lookup_v     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00066';    -- クイックコードテーブル
  cv_tkn_lookup_type      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00075';    -- クイックコード.参照タイプ
  cv_tkn_meaning          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00089';    -- クイックコード.内容
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
  cv_tkn_customer_err     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10705';    -- 顧客階層ビュー取得エラー
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  cv_tkn_exp_header_id    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10706';    -- 販売実績ヘッダID
  cv_msg_n_target_upd_err CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10707';    -- 販売明細対象外データ更新エラー
  cv_msg_edit_unit_price  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10708';    -- 単価編集メッセージ
/* 2009/08/25 Ver1.8 Add End   */
  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A02'; --参照タイプ　業態小分類
  cv_lookup_type_no_inv   CONSTANT VARCHAR2(30) := 'XXCOS1_NO_INV_ITEM_CODE'; --参照タイプ　非在庫品目
  cv_lookup_type_sals_cls CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS';   -- 参照タイプ　売上区分
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
----****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
--  cv_amount_up            CONSTANT VARCHAR2(5)  := 'UP';                  -- 消費税_端数(切上)
--  cv_amount_down          CONSTANT VARCHAR(5)   := 'DOWN';                -- 消費税_端数(切捨て)
--  cv_amount_nearest       CONSTANT VARCHAR(10)  := 'NEAREST';             -- 消費税_端数(四捨五入)
----****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
  cv_msg_comma            CONSTANT VARCHAR2(20) := ', ';                  -- カンマ
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  cv_fmt_date             CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- 日付フォーマット
/* 2009/08/25 Ver1.8 Add End   */
/* 2009/12/13 Ver1.10 Add Start */
  cv_lookup_cd_delivery_vd CONSTANT VARCHAR2(20) := 'XXCOS_003_A02_04';    -- 納品VD
  cv_tkn_lookup_code       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00078';    -- クイックコード.コード
  cv_tkn_lookup_type1      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00077';    -- クイックコード.タイプ
  cv_tkn_sales_cls_vd      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10709';    -- ベンダ売上
/* 2009/12/13 Ver1.10 Add End */
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
  cn_max_standard_qty      CONSTANT NUMBER := 5;                           -- 基準数量取得最大桁数
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--メッセージ出力用キー情報
  gv_msg_tkn_tm_w_tbl         fnd_new_messages.message_text%TYPE   ;--'単価マスタワークテーブル'
  gv_msg_tkn_exp_l_tbl        fnd_new_messages.message_text%TYPE   ;--'販売実績明細テーブル'
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ;--'顧客コード'
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ;--'品名コード'
  gv_msg_tkn_exp_line_id      fnd_new_messages.message_text%TYPE   ;--'販売実績明細ID'
  gv_msg_tkn_sales_cls_nml    fnd_new_messages.message_text%TYPE   ;--通常
  gv_msg_tkn_sales_cls_sls    fnd_new_messages.message_text%TYPE   ;--特売
  gv_msg_tkn_fnd_lookup_v     fnd_new_messages.message_text%TYPE   ;--クイックコード
  gv_msg_tkn_lookup_type      fnd_new_messages.message_text%TYPE   ;--参照タイプ
  gv_msg_tkn_meaning          fnd_new_messages.message_text%TYPE   ;--内容
  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
  gv_item_code                xxcos_unit_price_mst_work.item_code%TYPE;
  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;
/* 2009/08/25 Ver1.8 Add Start */
  gv_msg_tkn_exp_header_id    fnd_new_messages.message_text%TYPE   ;--'販売実績ヘッダID'
/* 2009/08/25 Ver1.8 Add End   */
  gd_nml_prev_dlv_date        xxcos_unit_price_mst_work.nml_prev_dlv_date%TYPE;     --通常 前回 納品日
  gd_nml_bef_prev_dlv_date    xxcos_unit_price_mst_work.nml_bef_prev_dlv_date%TYPE; --通常 前々回 納品日
  gd_sls_prev_dlv_date        xxcos_unit_price_mst_work.sls_prev_dlv_date%TYPE;     --特売 前回 納品日
  gd_sls_bef_prev_dlv_date    xxcos_unit_price_mst_work.sls_bef_prev_dlv_date%TYPE; --特売 前々回 納品日
  gd_nml_prev_clt_date        xxcos_unit_price_mst_work.nml_prev_clt_date%TYPE;     --通常 前回 作成日
  gd_nml_bef_prev_clt_date    xxcos_unit_price_mst_work.nml_bef_prev_clt_date%TYPE; --通常 前々回 作成日
  gd_sls_prev_clt_date        xxcos_unit_price_mst_work.sls_prev_clt_date%TYPE;     --特売 前回 作成日
  gd_sls_bef_prev_clt_date    xxcos_unit_price_mst_work.sls_bef_prev_clt_date%TYPE; --特売 前々回 作成日
  gv_sales_cls_nml            fnd_lookup_values.lookup_code%TYPE;
  gv_sales_cls_sls            fnd_lookup_values.lookup_code%TYPE;
  gv_bf_sales_exp_header_id   xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
  gn_warn_tran_count          NUMBER DEFAULT 0;
  gn_new_warn_count           NUMBER DEFAULT 0;
  gn_tran_count               NUMBER DEFAULT 0;
  gn_unit_price               NUMBER;
  gn_skip_cnt                 NUMBER DEFAULT 0;                    -- 単価マスタ更新対象外件数
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
  gv_language                 fnd_lookup_values.language%TYPE;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  gv_edit_unit_price_flag     VARCHAR2(1);              --単価編集フラグ
  gv_empty_line_flag          VARCHAR2(1) DEFAULT 'N';  --終了時の空白行制御フラグ
/* 2009/08/25 Ver1.8 Add End   */
/* 2009/12/13 Ver1.10 Add Start */
  gv_delivery_vd              VARCHAR2(2);
  gv_vd_sales_cls             VARCHAR2(2);
  gv_msg_lookup_code      fnd_new_messages.message_text%TYPE;   --参照タイプ
  gv_msg_lookup_type      fnd_new_messages.message_text%TYPE;   --参照タイプ
  gv_msg_sales_cls_vd     fnd_new_messages.message_text%TYPE;   --特売
/* 2009/12/13 Ver1.10 Add Start */
--
--カーソル
  CURSOR main_cur
  IS
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--    SELECT  xseh.sales_exp_header_id          sales_exp_header_id               --販売実績ヘッダID
    SELECT  /*+ leading(xsel) use_nl(xseh xsel) index(xsel xxcos_sales_exp_lines_n02) */
            xseh.sales_exp_header_id          sales_exp_header_id               --販売実績ヘッダID
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
           ,xseh.ship_to_customer_code        ship_to_customer_code             --顧客【納品先】
           ,xseh.orig_delivery_date           delivery_date                     --納品日（オリジナル納品日）
           ,xseh.tax_rate                     tax_rate                          --消費税率
           ,xsel.item_code                    item_code                         --品目コード
           ,xsel.standard_unit_price_excluded standard_unit_price_excluded      --税抜基準単価
           ,xsel.standard_unit_price          standard_unit_price               --基準単価
           ,xsel.standard_qty                 standard_qty                      --基準数量
           ,xsel.creation_date                creation_date                     --作成日
           ,xsel.sales_exp_line_id            sales_exp_line_id                 --販売実績明細ID
/* 2009/12/13 Ver1.10 Mod Start */
           ,CASE xseh.cust_gyotai_sho
               WHEN gv_delivery_vd THEN DECODE(xsel.sales_class ,gv_vd_sales_cls,gv_sales_cls_nml,xsel.sales_class)
               ELSE xsel.sales_class
            END                               sales_class
--           ,xsel.sales_class                  sales_class                       --売上区分
/* 2009/12/13 Ver1.10 Mod End */
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hca.tax_rounding_rule             tax_round_rule                 --税金-端数処理
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xchv.bill_tax_round_rule          tax_round_rule
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    FROM    xxcos_sales_exp_headers xseh
           ,xxcos_sales_exp_lines   xsel
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hz_cust_accounts                  hca
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xxcos_cust_hierarchy_v              xchv                           -- 顧客階層ビュー
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    WHERE   (xseh.cancel_correct_class IS NULL
           OR
             xseh.order_no_hht         IS NULL )
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----    AND     hca.account_number           = xseh.ship_to_customer_code
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--    AND     xchv.ship_account_number   = xseh.ship_to_customer_code
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    AND     xseh.dlv_invoice_class = cv_invoice_class_dliv
    AND     xseh.sales_exp_header_id =  xsel.sales_exp_header_id
/* 2009/12/13 Ver1.10 Mod Start */
    AND    ( ( xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls))
              OR
             ( xseh.cust_gyotai_sho    = gv_delivery_vd ) AND ( xsel.sales_class = gv_vd_sales_cls ))
--    AND     xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls)
/* 2009/12/13 Ver1.10 Mod End */
    
/* 2009/08/25 Ver1.8 Mod Start */
--    AND     xsel.unit_price_mst_flag = cv_flag_off
    AND     xsel.unit_price_mst_flag IN ( cv_flag_off, cv_flag_w )
/* 2009/08/25 Ver1.8 Mod End   */
    AND     NOT EXISTS
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--            (SELECT NULL
            (SELECT /*+ use_nl(flvl) */
                    NULL
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
             FROM   fnd_lookup_values flvl
             WHERE  flvl.lookup_type         = cv_lookup_type_gyotai
/* 2009/12/13 Ver1.10 Add Start */
             AND    flvl.lookup_code         != cv_lookup_cd_delivery_vd
/* 2009/12/13 Ver1.10 Add End */
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--             AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--             AND    flvl.language            = USERENV('LANG')
             AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
             AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                              AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
             AND     flvl.enabled_flag        = cv_flag_on
             AND xseh.cust_gyotai_sho = meaning )
    AND     NOT EXISTS
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
---            (SELECT NULL
            (SELECT /*+ use_nl(flvl) */
                    NULL
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
             FROM   fnd_lookup_values flvl
             WHERE  flvl.lookup_type         = cv_lookup_type_no_inv
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--             AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--             AND    flvl.language            = USERENV('LANG')
             AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
             AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                              AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
             AND     flvl.enabled_flag        = cv_flag_on
             AND xsel.item_code = lookup_code )
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    AND LENGTH( ABS( xsel.standard_qty ) )  <= cn_max_standard_qty
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    UNION
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--    SELECT  xseh.sales_exp_header_id          sales_exp_header_id               --販売実績ヘッダID
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--    SELECT  /*+ leading(inl1.inl2.xsel) use_nl(inl1.inl2.xsel inl1.inl2.xseh) */
    SELECT  /*+ leading(inl1.inl2.xsel) use_nl(inl1 xseh xsel) */
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
            xseh.sales_exp_header_id          sales_exp_header_id               --販売実績ヘッダID
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
           ,xseh.ship_to_customer_code        ship_to_customer_code             --顧客【納品先】
           ,xseh.orig_delivery_date           delivery_date                     --納品日（オリジナル納品日）
           ,xseh.tax_rate                     tax_rate                          --消費税率
           ,xsel.item_code                    item_code                         --品目コード
           ,xsel.standard_unit_price_excluded standard_unit_price_excluded      --税抜基準単価
           ,xsel.standard_unit_price          standard_unit_price               --基準単価
           ,xsel.standard_qty                 standard_qty                      --基準数量
           ,xsel.creation_date                creation_date                     --作成日
           ,xsel.sales_exp_line_id            sales_exp_line_id                 --販売実績明細ID
/* 2009/12/13 Ver1.10 Mod Start */
           ,CASE xseh.cust_gyotai_sho
               WHEN gv_delivery_vd THEN DECODE(xsel.sales_class ,gv_vd_sales_cls,gv_sales_cls_nml,xsel.sales_class)
               ELSE xsel.sales_class
            END                              sales_class
--           ,xsel.sales_class                  sales_class                       --売上区分
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hca.tax_rounding_rule             tax_round_rule                 --税金-端数処理
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xchv.bill_tax_round_rule          tax_round_rule
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    FROM    xxcos_sales_exp_headers xseh
           ,xxcos_sales_exp_lines   xsel
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hz_cust_accounts                  hca
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xxcos_cust_hierarchy_v              xchv                           -- 顧客階層ビュー
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--           ,(SELECT  MAX(xseh.digestion_ln_number) digestion_ln_number
           ,(SELECT  /*+ use_nl(inl2 xseh) */
                     MAX(xseh.digestion_ln_number) digestion_ln_number
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                    ,inl2.order_no_hht
             FROM   xxcos_sales_exp_headers xseh
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--                   ,(SELECT xseh.order_no_hht order_no_hht
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--                   ,(SELECT /*+ index(xsel xxcos_sales_exp_lines_n02) */
                   ,(SELECT /*+ index(xsel xxcos_sales_exp_lines_n02) use_nl(xsel xseh) */
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                             xseh.order_no_hht order_no_hht
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
                     FROM    xxcos_sales_exp_headers xseh
                            ,xxcos_sales_exp_lines   xsel
                     WHERE   xseh.cancel_correct_class = cv_correct
                     AND     xseh.digestion_ln_number  = 1
                     AND     xseh.dlv_invoice_class IN (cv_invoice_class_dliv,cv_invoice_class_d_co)
/* 2009/08/25 Ver1.8 Mod Start */
--                     AND     xsel.unit_price_mst_flag  = cv_flag_off
                     AND     xsel.unit_price_mst_flag IN ( cv_flag_off, cv_flag_w )
/* 2009/08/25 Ver1.8 Mod End   */
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--                     AND     NOT EXISTS(SELECT NULL
                     AND     NOT EXISTS(SELECT /*+ use_nl(flvl) */
                                               NULL
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                                        FROM   fnd_lookup_values       flvl
                                        WHERE  flvl.lookup_type       = cv_lookup_type_gyotai
/* 2009/12/13 Ver1.10 Add Start */
                                        AND    flvl.lookup_code       != cv_lookup_cd_delivery_vd
/* 2009/12/13 Ver1.10 Add End */
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--                                        AND    flvl.security_group_id = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type
--                                                                                                ,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--                                        AND     flvl.language             = USERENV('LANG')
                                        AND     flvl.language             = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
                                        AND     TRUNC(SYSDATE)            BETWEEN flvl.start_date_active
                                                                          AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
                                        AND     flvl.enabled_flag         = cv_flag_on
                                        AND     xseh.cust_gyotai_sho      = flvl.meaning)
                     AND     xseh.sales_exp_header_id  =  xsel.sales_exp_header_id
                   ) inl2
             WHERE   xseh.order_no_hht = inl2.order_no_hht
             GROUP BY inl2.order_no_hht
            ) inl1
    WHERE   inl1.order_no_hht        = xseh.order_no_hht
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----    AND     hca.account_number           = xseh.ship_to_customer_code
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--    AND     xchv.ship_account_number   = xseh.ship_to_customer_code
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    AND     inl1.digestion_ln_number = xseh.digestion_ln_number
    AND     xseh.sales_exp_header_id = xsel.sales_exp_header_id
/* 2009/12/13 Ver1.10 Mod Start */
    AND    ( ( xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls))
              OR
             ( xseh.cust_gyotai_sho    = gv_delivery_vd ) AND ( xsel.sales_class = gv_vd_sales_cls ))
--    AND     xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls)
/* 2009/12/13 Ver1.10 Mod End */
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--    AND     NOT EXISTS(SELECT NULL
    AND     NOT EXISTS(SELECT /*+ use_nl(flvl) */
                              NULL
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                       FROM   fnd_lookup_values flvl
                       WHERE  flvl.lookup_type         = cv_lookup_type_no_inv
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--                       AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--                       AND    flvl.language            = USERENV('LANG')
                       AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
                       AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                                        AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
                       AND     flvl.enabled_flag        = cv_flag_on
                       AND xsel.item_code = lookup_code )
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    AND LENGTH( ABS( xsel.standard_qty ) )  <= cn_max_standard_qty
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    ORDER BY sales_exp_header_id
    ;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
    main_rec main_cur%ROWTYPE;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
--  TYPE gt_ship_account IS TABLE OF xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE
--                          INDEX BY xxcos_cust_hierarchy_v.ship_account_number%TYPE; -- 税金-端数処理保持テーブル型
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
/* 2009/08/25 Ver1.8 Add Start */
  TYPE gt_upd_header   IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE
                          INDEX BY BINARY_INTEGER;                                  -- 更新用ヘッダID保持テーブル型
  TYPE gt_upd_line     IS TABLE OF ROWID
                          INDEX BY BINARY_INTEGER;                                  -- 更新用明細ID保持テーブル型
/* 2009/08/25 Ver1.8 Add End   */
  -- ===============================
  -- ユーザー定義グローバル表
  -- ===============================
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
--  gt_ship_account_tbl gt_ship_account;                                              -- 税金-端数処理保持テーブル
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  gt_upd_header_tab   gt_upd_header;                                                -- 更新用ヘッダID保持テーブル型
/* 2009/08/25 Ver1.8 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***

    -- *** ローカル変数 ***
    lv_msg_tkn_sales_cls fnd_new_messages.message_text%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

-- 2009/02/24 T.Nakamura Ver.1.2 add start
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- マルチバイトの固定値をメッセージより取得
    --==============================================================
    gv_msg_tkn_tm_w_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_w_tbl
                                                           );
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
    gv_msg_tkn_exp_l_tbl        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_l_tbl
                                                           );
    gv_msg_tkn_exp_line_id      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_line_id
                                                           );
    gv_msg_tkn_sales_cls_nml    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_nml
                                                           );
    gv_msg_tkn_sales_cls_sls    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_sls
                                                           );
    gv_msg_tkn_fnd_lookup_v     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_fnd_lookup_v
                                                           );
    gv_msg_tkn_lookup_type      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_type
                                                           );
    gv_msg_tkn_meaning          := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_meaning
                                                           );
/* 2009/08/25 Ver1.8 Add Start */
    gv_msg_tkn_exp_header_id    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_header_id
                                                           );
/* 2009/08/25 Ver1.8 Add End   */
/* 2009/12/13 Ver1.10 Add Start */
    gv_msg_lookup_code      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_code);
    gv_msg_lookup_type      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_type1);
    gv_msg_sales_cls_vd     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_vd);
/* 2009/12/13 Ver1.10 Add Start */
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
    --==============================================================
    -- 使用言語を取得
    --==============================================================
    gv_language                 := USERENV('LANG');
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
    --==============================================================
    -- 売上区分を参照タイプより取得
    --==============================================================
    BEGIN
   --通常
      lv_msg_tkn_sales_cls := gv_msg_tkn_sales_cls_nml; --メッセージ用変数に格納
      SELECT flvl.lookup_code lookup_code
      INTO   gv_sales_cls_nml
      FROM   fnd_lookup_values       flvl
      WHERE  flvl.lookup_type         = cv_lookup_type_sals_cls
      AND    flvl.meaning             = gv_msg_tkn_sales_cls_nml
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--      AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--      AND    flvl.language            = USERENV('LANG')
      AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
      AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                      AND NVL(flvl.end_date_active,TRUNC(SYSDATE))
      AND    flvl.enabled_flag        = cv_flag_on
      ;

     --特売
      lv_msg_tkn_sales_cls := gv_msg_tkn_sales_cls_sls; --メッセージ用変数に格納
      SELECT flvl.lookup_code lookup_code
      INTO   gv_sales_cls_sls
      FROM   fnd_lookup_values flvl
      WHERE  flvl.lookup_type         = cv_lookup_type_sals_cls
      AND    flvl.meaning             = gv_msg_tkn_sales_cls_sls
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--      AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--      AND    flvl.language            = USERENV('LANG')
      AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
      AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                      AND NVL(flvl.end_date_active,TRUNC(SYSDATE))
      AND    flvl.enabled_flag        = cv_flag_on
      ;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- エラー・メッセージ
                                        ,ov_retcode     => lv_retcode                     -- リターン・コード
                                        ,ov_errmsg      => lv_errmsg                      --ユーザー・エラー・メッセージ
                                        ,ov_key_info    => gv_key_info                    --キー情報
                                        ,iv_item_name1  => gv_msg_tkn_lookup_type         --項目名称1
                                        ,iv_data_value1 => cv_lookup_type_sals_cls        --データの値1
                                        ,iv_item_name2  => gv_msg_tkn_meaning             --項目名称2
                                        ,iv_data_value2 => lv_msg_tkn_sales_cls           --データの値2
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
/* 2009/12/13 Ver1.10 Add Start */
    -- 納品VDの業態小分類コード取得
    BEGIN
      SELECT flv.meaning
      INTO   gv_delivery_vd
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type  = cv_lookup_type_gyotai
      AND    flv.lookup_code  = cv_lookup_cd_delivery_vd
      AND    flv.enabled_flag = cv_flag_on
      AND    TRUNC(SYSDATE)   BETWEEN flv.start_date_active
                              AND NVL(flv.end_date_active,TRUNC(SYSDATE))
      AND    flv.language     = gv_language;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- エラー・メッセージ
                                        ,ov_retcode     => lv_retcode                     -- リターン・コード
                                        ,ov_errmsg      => lv_errmsg                      --ユーザー・エラー・メッセージ
                                        ,ov_key_info    => gv_key_info                    --キー情報
                                        ,iv_item_name1  => gv_msg_lookup_type         --項目名称1
                                        ,iv_data_value1 => cv_lookup_type_gyotai        --データの値1
                                        ,iv_item_name2  => gv_msg_lookup_code             --項目名称2gv_msg_tkn_meaning
                                        ,iv_data_value2 => cv_lookup_cd_delivery_vd       --データの値2
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
    --
    -- ベンダー売上の売上区分取得
    BEGIN
      SELECT flv.lookup_code lookup_code
      INTO   gv_vd_sales_cls
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type         = cv_lookup_type_sals_cls
      AND    flv.meaning             = gv_msg_sales_cls_vd
      AND    flv.language            = gv_language
      AND    TRUNC(SYSDATE)           BETWEEN flv.start_date_active
                                      AND NVL(flv.end_date_active,TRUNC(SYSDATE))
      AND    flv.enabled_flag        = cv_flag_on
      ;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- エラー・メッセージ
                                        ,ov_retcode     => lv_retcode                     -- リターン・コード
                                        ,ov_errmsg      => lv_errmsg                      --ユーザー・エラー・メッセージ
                                        ,ov_key_info    => gv_key_info                    --キー情報
                                        ,iv_item_name1  => gv_msg_lookup_type         --項目名称1
                                        ,iv_data_value1 => cv_lookup_type_sals_cls        --データの値1
                                        ,iv_item_name2  => gv_msg_tkn_meaning             --項目名称2
                                        ,iv_data_value2 => gv_msg_sales_cls_vd        --データの値2
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
/* 2009/12/13 Ver1.10 Add End */
--
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
/* 2009/08/25 Ver1.8 Add Start */
  /**********************************************************************************
   * Procedure Name   : proc_upd_n_target_line
   * Description      : A-8．販売実績明細対象外データ更新
   ***********************************************************************************/
  PROCEDURE proc_upd_n_target_line(
    ov_errbuf             OUT VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_n_target_line'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_upd_line_tab  gt_upd_line;  --明細更新用
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      --販売実績明細ロック(対象外データ全て)
      SELECT /*+ INDEX(xsel xxcos_sales_exp_lines_n02) */
             xsel.ROWID row_id
      BULK COLLECT INTO
             lt_upd_line_tab
      FROM   xxcos_sales_exp_lines xsel
      WHERE  xsel.unit_price_mst_flag = cv_flag_off  --当処理終了後に"N"で残っているもの
      FOR UPDATE OF
             xsel.sales_exp_line_id
      NOWAIT
      ;
--
      --販売実績明細更新
      FORALL i IN 1..lt_upd_line_tab.COUNT
        UPDATE xxcos_sales_exp_lines xsel
        SET    xsel.unit_price_mst_flag        = cv_flag_s                  --単価マスタ作成済フラグ(対象外)
              ,xsel.last_updated_by            = cn_last_updated_by         --最終更新者
              ,xsel.last_update_date           = cd_last_update_date        --最終更新日
              ,xsel.last_update_login          = cn_last_update_login       --最終更新ログイン
              ,xsel.request_id                 = cn_request_id              --要求ID
              ,xsel.program_application_id     = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
              ,xsel.program_id                 = cn_program_id              --コンカレント・プログラムID
              ,xsel.program_update_date        = cd_program_update_date     --プログラム更新日
        WHERE  xsel.ROWID  = lt_upd_line_tab(i)
        ;
--
    EXCEPTION
      WHEN OTHERS THEN
--
        lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        --ロックエラーの場合
        IF ( SQLCODE = cn_lock_error_code ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           cv_application
                          ,cv_msg_lock
                          ,cv_tkn_lock
                          ,gv_msg_tkn_exp_l_tbl
                        );
        --その他の場合
        ELSE
          lv_errmsg := xxccp_common_pkg.get_msg(
                          cv_application
                         ,cv_msg_n_target_upd_err
                       );
        END IF;
        --出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --エラーメッセージ
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --エラーメッセージ
        );
        ov_retcode := cv_status_warn;
--
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_n_target_line;
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_skip_line
   * Description      : A-7．販売実績明細スキップデータ更新
   ***********************************************************************************/
  PROCEDURE proc_upd_skip_line(
    it_sales_header_tab   IN  gt_upd_header,  --   更新対象ヘッダID
    ov_errbuf             OUT VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_skip_line'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_buf     VARCHAR2(5000);      --エラー・メッセージ(キー情報編集用)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_upd_line_tab   gt_upd_line;  --明細更新用(ヘッダ単位で保持)
    lt_upd_line_tab_f gt_upd_line;  --初期化用
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FOR i IN 1..it_sales_header_tab.COUNT LOOP
--
      BEGIN
--
        --初期化
        lt_upd_line_tab := lt_upd_line_tab_f;
--
        --販売実績明細ロック(ヘッダ単位)
        SELECT xsel.ROWID row_id
        BULK COLLECT INTO
               lt_upd_line_tab
        FROM   xxcos_sales_exp_lines xsel
        WHERE  xsel.sales_exp_header_id = it_sales_header_tab(i)
        FOR UPDATE OF
               xsel.sales_exp_line_id
        NOWAIT
        ;
--
        --販売実績明細更新(ヘッダ単位)
        FORALL j IN 1..lt_upd_line_tab.COUNT
          UPDATE xxcos_sales_exp_lines xsel
          SET    unit_price_mst_flag        = cv_flag_w                  --単価マスタ作成済フラグ(警告)
                ,last_updated_by            = cn_last_updated_by         --最終更新者
                ,last_update_date           = cd_last_update_date        --最終更新日
                ,last_update_login          = cn_last_update_login       --最終更新ログイン
                ,request_id                 = cn_request_id              --要求ID
                ,program_application_id     = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
                ,program_id                 = cn_program_id              --コンカレント・プログラムID
                ,program_update_date        = cd_program_update_date     --プログラム更新日
          WHERE  xsel.ROWID  = lt_upd_line_tab(j)
          ;
--
      EXCEPTION
        WHEN OTHERS THEN
--
          lv_errbuf := SQLERRM;
          --ロックエラーの場合
          IF ( SQLCODE = cn_lock_error_code ) THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             cv_application
                            ,cv_msg_lock
                            ,cv_tkn_lock
                            ,gv_msg_tkn_exp_l_tbl
                          );
          --その他の場合
          ELSE
            xxcos_common_pkg.makeup_key_info(
               ov_errbuf      => lv_buf                     --エラー・メッセージ
              ,ov_retcode     => lv_retcode                 --リターン・コード
              ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
              ,ov_key_info    => gv_key_info                --キー情報
              ,iv_item_name1  => gv_msg_tkn_exp_header_id   --項目名称1
              ,iv_data_value1 => it_sales_header_tab(i)     --データの値1
            );
            lv_errmsg := xxccp_common_pkg.get_msg(
                            cv_application
                           ,cv_msg_update_err
                           ,cv_tkn_table_name
                           ,gv_msg_tkn_exp_l_tbl
                           ,cv_tkn_key_data
                           ,gv_key_info
                         );
          END IF;
--
          --警告データを全てエラー件数とする
          gn_error_cnt := gn_warn_cnt;
--
          RAISE global_api_expt;
--
      END;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_skip_line;
/* 2009/08/25 Ver1.8 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : proc_insert_upm_work
   * Description      : A-4．単価マスタワークテーブル登録
   ***********************************************************************************/
  PROCEDURE proc_insert_upm_work(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_insert_upm_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
      -- ===============================
      --A-4．単価マスタワークテーブル登録
      -- ===============================
        BEGIN
          CASE
            WHEN main_rec.sales_class   = gv_sales_cls_nml THEN
              INSERT INTO xxcos_unit_price_mst_work(
                 customer_number          --顧客コード
                ,item_code                --品名コード
                ,nml_prev_unit_price      --通常　前回　単価
                ,nml_prev_dlv_date        --通常　前回　納品年月日
                ,nml_prev_qty             --通常　前回　数量
                ,nml_prev_clt_date        --通常　前回　作成日
                ,file_output_flag         --ファイル出力済フラグ
                --WHOカラム
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )VALUES(
                 main_rec.ship_to_customer_code        --顧客コード
                ,main_rec.item_code                    --品名コード
                ,gn_unit_price                         --通常　前回　単価
                ,main_rec.delivery_date                --通常　前回　納品年月日
                ,main_rec.standard_qty                 --通常　前回　数量
                ,main_rec.creation_date                --通常　前回　作成日
                ,cv_flag_off                           --ファイル出力済フラグ
                ,cn_created_by
                ,cd_creation_date
                ,cn_last_updated_by
                ,cd_last_update_date
                ,cn_last_update_login
                ,cn_request_id
                ,cn_program_application_id
                ,cn_program_id
                ,cd_program_update_date
               );
            WHEN main_rec.sales_class   = gv_sales_cls_sls THEN
              INSERT INTO xxcos_unit_price_mst_work(
                 customer_number          --顧客コード
                ,item_code                --品名コード
                ,sls_prev_unit_price      --特売　前回　単価
                ,sls_prev_dlv_date        --特売　前回　納品年月日
                ,sls_prev_qty             --特売　前回　数量
                ,sls_prev_clt_date        --特売　前回　作成日
                ,file_output_flag         --ファイル出力済フラグ
                --WHOカラム
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )VALUES(
                 main_rec.ship_to_customer_code        --顧客コード
                ,main_rec.item_code                    --品名コード
                ,gn_unit_price                         --特売　前回　単価
                ,main_rec.delivery_date                --特売　前回　納品年月日
                ,main_rec.standard_qty                 --特売　前回　数量
                ,main_rec.creation_date                --特売　前回　作成日
                ,cv_flag_off                           --ファイル出力済フラグ
                ,cn_created_by
                ,cd_creation_date
                ,cn_last_updated_by
                ,cd_last_update_date
                ,cn_last_update_login
                ,cn_request_id
                ,cn_program_application_id
                ,cn_program_id
                ,cd_program_update_date
               );
          END CASE;
/* 2009/08/25 Ver1.8 Add Start */
          gv_edit_unit_price_flag := cv_flag_on; --単価編集フラグ'Y'
/* 2009/08/25 Ver1.8 Add End   */
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                     -- リターン・コード
                                            ,ov_errmsg      => lv_errmsg                      --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                    --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_cust_code           --項目名称1
                                            ,iv_data_value1 => main_rec.ship_to_customer_code --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_item_code           --項目名称2
                                            ,iv_data_value2 => main_rec.item_code             --データの値2
                                            );
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_tm_w_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            ov_retcode := cv_status_warn;
            ov_errmsg  := lv_errmsg;
        END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_insert_upm_work;

  /**********************************************************************************
   * Procedure Name   : proc_update_upm_work
   * Description      : A-3．単価マスタワークテーブル更新
   ***********************************************************************************/
  PROCEDURE proc_update_upm_work(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_upm_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_update_pattern NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_update_pattern := '';
      -- ===============================
      --A-3．単価マスタワークテーブル更新
      -- ===============================
 --①売上区分が通常かつ、販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 --よりも新しいレコードが発生した場合
    IF    (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date > gd_nml_prev_dlv_date)
    THEN
      ln_update_pattern := 1;

 --②売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 --よりも古い、かつ単価マスタワークテーブルの「通常　前々回　納品年月日」よりも新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date >  gd_nml_bef_prev_dlv_date)
    THEN
      ln_update_pattern := 2;

 --③売上区分が特売かつ、販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 --よりも新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date > gd_sls_prev_dlv_date)
    THEN
      ln_update_pattern := 3;

 --④売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 --よりも古い、かつ単価マスタワークテーブルの「特売　前々回　納品年月日」よりも新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date)
    THEN
      ln_update_pattern := 4;

 --⑤売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に「通常　前回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「通常　前々回　納品年月日」よりも新しい、
 --かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date > gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_prev_clt_date)
    THEN
      ln_update_pattern := 1;

 --⑥売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「通常　前々回　納品年月日」よりも新しい、
 --かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date > gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date)
    THEN
      ln_update_pattern := 2;

 --⑦売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「通常　前々回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_prev_clt_date)
    THEN
      ln_update_pattern := 1;

 --⑧売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「通常　前々回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが古い、
 --かつ単価マスタワークテーブルの「通常　前々回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date
    AND    main_rec.creation_date > gd_nml_bef_prev_clt_date)
    THEN
      ln_update_pattern := 2;

 --⑨売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「通常　前々回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが古い、
 --かつ単価マスタワークテーブルの「通常　前々回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date
    AND    main_rec.creation_date < gd_nml_bef_prev_clt_date)
    THEN
      NULL;

 --⑩売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「特売　前々回　納品年月日」よりも新しい、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_prev_clt_date)
    THEN
      ln_update_pattern := 3;

 --⑪売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「特売　前々回　納品年月日」よりも新しい、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date)
    THEN
      ln_update_pattern := 4;

 --⑫売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「特売　前々回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_prev_clt_date)
    THEN
      ln_update_pattern := 3;

 --⑬売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「特売　前々回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが古い、
 --かつ単価マスタワークテーブルの「特売　前々回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date
    AND    main_rec.creation_date > gd_sls_bef_prev_clt_date)
    THEN
      ln_update_pattern := 4;

 --⑭売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」と同じ、
 --かつ単価マスタワークテーブルの「特売　前々回　納品年月日」　と同じ、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが古い、
 --かつ単価マスタワークテーブルの「特売　前々回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date
    AND    main_rec.creation_date < gd_sls_bef_prev_clt_date)
    THEN
      NULL;

 --⑮売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 --よりも古いレコードが発生し、かつ単価マスタワークテーブルの「通常　前々回　納品年月日」が未設定の場合
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml
    AND    main_rec.delivery_date   <  gd_nml_prev_dlv_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 2;

 --⑯売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 -- よりも古い、かつ単価マスタワークテーブルの「通常　前々回　納品年月日」と同じ、
 -- かつ単価マスタワークテーブルの「通常　前々回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_bef_prev_clt_date)
    THEN
      ln_update_pattern := 2;

 --⑰売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 -- よりも古い、かつ単価マスタワークテーブルの「通常　前々回　納品年月日」と同じ、
 -- かつ単価マスタワークテーブルの「通常　前々回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_bef_prev_clt_date)
    THEN
      NULL;

 --⑱売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 -- よりも古いレコードが発生し、かつ単価マスタワークテーブルの「特売　前々回　納品年月日」が未設定の場合
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   <  gd_sls_prev_dlv_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 4;

 --⑲売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 -- よりも古い、かつ単価マスタワークテーブルの「特売　前々回　納品年月日」と同じ、
 -- かつ単価マスタワークテーブルの「特売　前々回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_bef_prev_clt_date)
    THEN
      ln_update_pattern := 4;

 --⑳売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 -- よりも古い、かつ単価マスタワークテーブルの「特売　前々回　納品年月日」と同じ、
 -- かつ単価マスタワークテーブルの「特売　前々回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_bef_prev_clt_date)
    THEN
      NULL;

 --21.売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 -- と同じレコードが発生し、かつ単価マスタワークテーブルの「通常　前々回　納品年月日」が未設定、
 -- かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml
    AND    main_rec.delivery_date   =  gd_nml_prev_dlv_date
    AND    main_rec.creation_date   >  gd_nml_prev_clt_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 1;

 --22.売上区分が通常かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「通常　前回　納品年月日」
 -- と同じレコードが発生し、かつ単価マスタワークテーブルの「通常　前々回　納品年月日」が未設定、
 -- かつ単価マスタワークテーブルの「通常　前回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml
    AND    main_rec.delivery_date   =  gd_nml_prev_dlv_date
    AND    main_rec.creation_date   <  gd_nml_prev_clt_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 2;

 --23.売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 -- と同じレコードが発生し、かつ単価マスタワークテーブルの「特売　前々回　納品年月日」が未設定、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが新しいレコードが発生した場合
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   =  gd_sls_prev_dlv_date
    AND    main_rec.creation_date   >  gd_sls_prev_clt_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 3;

 --24.売上区分が特売かつ、　販売実績ヘッダテーブル.納品日に単価マスタワークテーブルの「特売　前回　納品年月日」
 -- と同じレコードが発生し、かつ単価マスタワークテーブルの「特売　前々回　納品年月日」が未設定、
 --かつ単価マスタワークテーブルの「特売　前回　作成日」より販売実績の作成日のほうが古いレコードが発生した場合
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   =  gd_sls_prev_dlv_date
    AND    main_rec.creation_date   <  gd_sls_prev_clt_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 4;

 --25.売上区分が通常かつ、単価マスタワークテーブルの「通常　前回　納品年月日」　が未設定の場合
    ELSIF (main_rec.sales_class =  gv_sales_cls_nml
    AND    gd_nml_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 1;

 --26.売上区分が特売かつ、単価マスタワークテーブルの「特売　前回　納品年月日」　が未設定の場合
    ELSIF (main_rec.sales_class =  gv_sales_cls_sls
    AND    gd_sls_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 3;

  --上記以外
    ELSE
      NULL;
    END IF;
    BEGIN
    --パターン１
      CASE
        WHEN ln_update_pattern = 1 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    nml_prev_unit_price        = gn_unit_price                         --通常　前回　単価
                ,nml_prev_dlv_date          = main_rec.delivery_date                --通常　前回　納品年月日
                ,nml_prev_qty               = main_rec.standard_qty                 --通常　前回　数量
                ,nml_prev_clt_date          = main_rec.creation_date                --通常　前回　作成日
                ,nml_bef_prev_dlv_date      = nml_prev_dlv_date                     --通常　前々回　納品年月日
                ,nml_bef_prev_qty           = nml_prev_qty                          --通常　前々回　数量
                ,nml_bef_prev_clt_date      = nml_prev_clt_date                     --通常　前々回　作成日
                ,file_output_flag           = cv_flag_off                           --ファイル出力済フラグ
                ,last_updated_by            = cn_last_updated_by                    --最終更新者
                ,last_update_date           = cd_last_update_date                   --最終更新日
                ,last_update_login          = cn_last_update_login                  --最終更新ログイン
                ,request_id                 = cn_request_id                         --要求ID
                ,program_application_id     = cn_program_application_id             --コンカレント・プログラム・アプリケーションID
                ,program_id                 = cn_program_id                         --コンカレント・プログラムID
                ,program_update_date        = cd_program_update_date                --プログラム更新日
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
/* 2009/08/25 Ver1.8 Add Start */
          gv_edit_unit_price_flag := cv_flag_on; --単価編集フラグ'Y'
/* 2009/08/25 Ver1.8 Add End   */
        WHEN ln_update_pattern = 2 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    nml_bef_prev_dlv_date      = main_rec.delivery_date                --通常　前々回　納品年月日
                ,nml_bef_prev_qty           = main_rec.standard_qty                 --通常　前々回　数量
                ,nml_bef_prev_clt_date      = main_rec.creation_date                --通常　前々回　作成日
                ,file_output_flag           = cv_flag_off                           --ファイル出力済フラグ
                ,last_updated_by            = cn_last_updated_by                    --最終更新者
                ,last_update_date           = cd_last_update_date                   --最終更新日
                ,last_update_login          = cn_last_update_login                  --最終更新ログイン
                ,request_id                 = cn_request_id                         --要求ID
                ,program_application_id     = cn_program_application_id             --コンカレント・プログラム・アプリケーションID
                ,program_id                 = cn_program_id                         --コンカレント・プログラムID
                ,program_update_date        = cd_program_update_date                --プログラム更新日
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
        WHEN ln_update_pattern = 3 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    sls_prev_unit_price        = gn_unit_price                         --特売　前回　単価
                ,sls_prev_dlv_date          = main_rec.delivery_date                --特売　前回　納品年月日
                ,sls_prev_qty               = main_rec.standard_qty                 --特売　前回　数量
                ,sls_prev_clt_date          = main_rec.creation_date                --特売　前回　作成日
                ,sls_bef_prev_dlv_date      = sls_prev_dlv_date                     --特売　前々回　納品年月日
                ,sls_bef_prev_qty           = sls_prev_qty                          --特売　前々回　数量
                ,sls_bef_prev_clt_date      = sls_prev_clt_date                     --特売　前々回　作成日
                ,file_output_flag           = cv_flag_off                           --ファイル出力済フラグ
                ,last_updated_by            = cn_last_updated_by                    --最終更新者
                ,last_update_date           = cd_last_update_date                   --最終更新日
                ,last_update_login          = cn_last_update_login                  --最終更新ログイン
                ,request_id                 = cn_request_id                         --要求ID
                ,program_application_id     = cn_program_application_id             --コンカレント・プログラム・アプリケーションID
                ,program_id                 = cn_program_id                         --コンカレント・プログラムID
                ,program_update_date        = cd_program_update_date                --プログラム更新日
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
/* 2009/08/25 Ver1.8 Add Start */
          gv_edit_unit_price_flag := cv_flag_on; --単価編集フラグ'Y'
/* 2009/08/25 Ver1.8 Add End   */
        WHEN ln_update_pattern = 4 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    sls_bef_prev_dlv_date      = main_rec.delivery_date                --特売　前々回　納品年月日
                ,sls_bef_prev_qty           = main_rec.standard_qty                 --特売　前々回　数量
                ,sls_bef_prev_clt_date      = main_rec.creation_date                --特売　前々回　作成日
                ,file_output_flag           = cv_flag_off                           --ファイル出力済フラグ
                ,last_updated_by            = cn_last_updated_by                    --最終更新者
                ,last_update_date           = cd_last_update_date                   --最終更新日
                ,last_update_login          = cn_last_update_login                  --最終更新ログイン
                ,request_id                 = cn_request_id                         --要求ID
                ,program_application_id     = cn_program_application_id             --コンカレント・プログラム・アプリケーションID
                ,program_id                 = cn_program_id                         --コンカレント・プログラムID
                ,program_update_date        = cd_program_update_date                --プログラム更新日
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
        ELSE
          gn_skip_cnt := gn_skip_cnt + 1;
      END CASE;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                -- エラー・メッセージ
                                        ,ov_retcode     => lv_retcode               -- リターン・コード
                                        ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
                                        ,ov_key_info    => gv_key_info              --キー情報
                                        ,iv_item_name1  => gv_msg_tkn_cust_code     --項目名称1
                                        ,iv_data_value1 => gv_customer_number       --データの値1
                                        ,iv_item_name2  => gv_msg_tkn_item_code     --項目名称2
                                        ,iv_data_value2 => main_rec.item_code       --データの値2
                                        );
        lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_update_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_tm_w_tbl
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        ov_retcode := cv_status_warn;
        ov_errmsg  := lv_errmsg;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_update_upm_work;
--
  /**********************************************************************************
   * Procedure Name   : proc_main_loop（ループ部）
   * Description      : A-1データ抽出
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- メインループ処理
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    upm_work_exp      EXCEPTION;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
    get_tax_rule_exp  EXCEPTION;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message_code          VARCHAR2(20);
    ln_update_pattrun        NUMBER;
    lv_sales_exp_line_id     xxcos_sales_exp_lines.sales_exp_line_id%TYPE; --処理用ダミー変数
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
----****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
--    ln_unit_price            NUMBER;
----****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
----****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
--    lv_tax_round_rule        xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE; --税金-端数処理ルール
----****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
/* 2009/08/25 Ver1.8 Add Start */
    ln_skip_seq              PLS_INTEGER := 0;  --スキップデータテーブルの添字
    ln_unit_price_length     NUMBER;            --単価の整数部の長さ取得変数
    ln_unit_price_org        NUMBER;            --メッセージ用編集前単価
/* 2009/08/25 Ver1.8 Add End   */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    <<main_loop>>
    LOOP
      FETCH main_cur INTO main_rec;
      EXIT WHEN main_cur%NOTFOUND;
      BEGIN
        -- ===============================
        --販売実績ヘッダIDブレイク判定
        -- ===============================
        --エラーカウント
        gn_warn_tran_count     := gn_warn_tran_count + gn_new_warn_count;
        --1ループ内エラー初期化
        gn_new_warn_count := 0;
/* 2009/08/25 Ver1.8 Add Start */
        gv_edit_unit_price_flag := cv_flag_off; --単価編集フラグ初期化
        ln_unit_price_length    := NULL;        --単価の整数部の長さ取得変数の初期化
        ln_unit_price_org       := NULL;        --メッセージ用編集前単価の初期化
/* 2009/08/25 Ver1.8 Add End   */
--
        IF (main_rec.sales_exp_header_id <> gv_bf_sales_exp_header_id) THEN
          IF (gn_warn_tran_count > 0) THEN
            ROLLBACK;
            gn_warn_cnt := gn_warn_cnt + gn_tran_count;
/* 2009/08/25 Ver1.8 Add Start */
            --警告になった販売実績ヘッダID編集
            ln_skip_seq                    := ln_skip_seq + 1;
            gt_upd_header_tab(ln_skip_seq) := gv_bf_sales_exp_header_id;
/* 2009/08/25 Ver1.8 Add End   */
          ELSE
            COMMIT;
            gn_normal_cnt := gn_normal_cnt + gn_tran_count;
          END IF;
          gn_warn_tran_count := 0;
          gn_tran_count      := 0;
        END IF;
--
        --ブレイク判定キー入れ替え
        gv_bf_sales_exp_header_id := main_rec.sales_exp_header_id;
--
--
        --件数カウンタ
        gn_target_cnt := gn_target_cnt + 1;
        gn_tran_count := gn_tran_count + 1;
--
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
--        -- ===============================
--        -- 税金-端数処理情報の取得
--        -- ===============================
--        IF (gt_ship_account_tbl.EXISTS(main_rec.ship_to_customer_code)) THEN
--          lv_tax_round_rule := gt_ship_account_tbl(main_rec.ship_to_customer_code);
--        ELSE
--          BEGIN
--            SELECT xchv.bill_tax_round_rule
--            INTO   lv_tax_round_rule
--            FROM   xxcos_cust_hierarchy_v xchv -- 顧客階層ビュー
--            WHERE  xchv.ship_account_number = main_rec.ship_to_customer_code;
--          EXCEPTION
--            WHEN OTHERS THEN
--              RAISE get_tax_rule_exp;
--          END;
--          --
--          IF lv_tax_round_rule IS NULL THEN
--            RAISE get_tax_rule_exp;
--          ELSE
--            gt_ship_account_tbl(main_rec.ship_to_customer_code) := lv_tax_round_rule;
--          END IF;
--        END IF;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
        -- ===============================
        --単価の導出
        -- ===============================
-- ***************** 2009/10/15 1.9 N.Maeda MOD START ***************** --
----****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
--        --変数の代入
--        ln_unit_price := main_rec.standard_unit_price_excluded * (1 + (main_rec.tax_rate / 100));
----****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--        IF main_rec.standard_unit_price_excluded = main_rec.standard_unit_price THEN
----****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/05/28 1.3  S.Kayahara MOD START ******************************--
--   --       gn_unit_price := trunc(main_rec.standard_unit_price_excluded * (1 + (main_rec.tax_rate / 100)),0);
--          -- 切上げ
----          IF main_rec.tax_round_rule    = cv_amount_up THEN
--          IF lv_tax_round_rule    = cv_amount_up THEN
--            -- 小数点が存在する場合
--            IF (ln_unit_price - TRUNC(ln_unit_price) <> 0 ) THEN
--              gn_unit_price := TRUNC(ln_unit_price,2) + 0.01;
--            ELSE gn_unit_price := ln_unit_price;
--            END IF;
--          -- 切捨て
----          ELSIF main_rec.tax_round_rule = cv_amount_down THEN
--          ELSIF lv_tax_round_rule = cv_amount_down THEN
--            gn_unit_price := TRUNC(ln_unit_price,2);
--          -- 四捨五入
----          ELSIF main_rec.tax_round_rule = cv_amount_nearest THEN
--          ELSIF lv_tax_round_rule = cv_amount_nearest THEN
--            gn_unit_price := ROUND(ln_unit_price,2);
--          END IF;
----****************************** 2009/05/28 1.3  S.Kayahara MOD END ******************************--
----****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
--        ELSE
--          gn_unit_price := main_rec.standard_unit_price;
--        END IF;
--
        gn_unit_price := main_rec.standard_unit_price;
--
-- ***************** 2009/10/15 1.9 N.Maeda MOD  END  ***************** --
/* 2009/08/25 Ver1.8 Add Start */
--
        --単価の整数部の長さを取得
        ln_unit_price_length :=  LENGTHB( TO_CHAR( TRUNC(gn_unit_price) ) );
        --単価の整数部が4桁を超える場合
        IF ( ln_unit_price_length > 4 ) THEN
          --編集前の単価を退避
          ln_unit_price_org := gn_unit_price;
          --整数部が下4桁になるように編集(小数部はそのまま)
          gn_unit_price     := TO_NUMBER( SUBSTRB( TO_CHAR(gn_unit_price), ln_unit_price_length -3 ) );
        END IF;
--
/* 2009/08/25 Ver1.8 Add End   */
        -- ===============================
        -- A-2．単価マスタワークテーブルレコードロック
        -- ===============================
        BEGIN
          gv_tkn_lock_table := gv_msg_tkn_tm_w_tbl;
          SELECT  xupm.customer_number       customer_number       --顧客コード
                 ,xupm.item_code             item_code             --品目コード
                 ,xupm.nml_prev_dlv_date     nml_prev_dlv_date     --通常　前回　納品年月日
                 ,xupm.nml_bef_prev_dlv_date nml_bef_prev_dlv_date --通常　前々回　納品年月日
                 ,xupm.sls_prev_dlv_date     sls_prev_dlv_date     --特売　前回　納品年月日
                 ,xupm.sls_bef_prev_dlv_date sls_bef_prev_dlv_date --特売　前々回　納品年月日
                 ,xupm.nml_prev_clt_date     nml_prev_clt_date     --通常　前回　作成日
                 ,xupm.nml_bef_prev_clt_date nml_bef_prev_clt_date --通常　前々回　作成日
                 ,xupm.sls_prev_clt_date     sls_prev_clt_date     --特売　前回　作成日
                 ,xupm.sls_bef_prev_clt_date sls_bef_prev_clt_date --特売　前々回　作成日
          INTO    gv_customer_number       --顧客コード
                 ,gv_item_code             --品目コード
                 ,gd_nml_prev_dlv_date     --通常　前回　納品年月日
                 ,gd_nml_bef_prev_dlv_date --通常　前々回　納品年月日
                 ,gd_sls_prev_dlv_date     --特売　前回　納品年月日
                 ,gd_sls_bef_prev_dlv_date --特売　前々回　納品年月日
                 ,gd_nml_prev_clt_date        --通常　前回　作成日
                 ,gd_nml_bef_prev_clt_date    --通常　前々回　作成日
                 ,gd_sls_prev_clt_date        --特売　前回　作成日
                 ,gd_sls_bef_prev_clt_date    --特売　前々回　作成日
          FROM    xxcos_unit_price_mst_work xupm
          WHERE   xupm.customer_number = main_rec.ship_to_customer_code
          AND     xupm.item_code       = main_rec.item_code
          FOR UPDATE NOWAIT
          ;

        -- ===============================
        --A-3．単価マスタワークテーブル更新
        -- ===============================
          proc_update_upm_work(
                               lv_errbuf   -- エラー・メッセージ           --# 固定 #
                              ,lv_retcode  -- リターン・コード             --# 固定 #
                              ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE upm_work_exp;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
        -- ===============================
        --A-4．単価マスタワークテーブル登録
        -- ===============================
            proc_insert_upm_work(
                                 lv_errbuf   -- エラー・メッセージ           --# 固定 #
                                ,lv_retcode  -- リターン・コード             --# 固定 #
                                ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE upm_work_exp;
            END IF;
        END;
/* 2009/08/25 Ver1.8 Add Start */
        --単価を設定(更新)するパターン、かつ、単価が編集されている場合
        IF ( ln_unit_price_length > 4 )
          AND
           ( gv_edit_unit_price_flag = cv_flag_on )
        THEN
          --単価編集メッセージを表示する
          lv_errmsg := xxccp_common_pkg.get_msg(
                          cv_application
                         ,cv_msg_edit_unit_price
                         ,cv_tkn_cust
                         ,main_rec.ship_to_customer_code
                         ,cv_tkn_item
                         ,main_rec.item_code
                         ,cv_tkn_dlv_date
                         ,TO_CHAR(main_rec.delivery_date, cv_fmt_date)
                         ,cv_tkn_unit_price
                         ,TO_CHAR(ln_unit_price_org)
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          --終了メッセージの空行制御用にフラグを立てる
          gv_empty_line_flag := cv_flag_on;
        END IF;
/* 2009/08/25 Ver1.8 Add End   */
        BEGIN
          -- ===============================
          --A-5．販売実績明細テーブルレコードロック
          -- ===============================
          gv_tkn_lock_table := gv_msg_tkn_exp_l_tbl;
          SELECT  xsel.sales_exp_line_id sales_exp_line_id       --販売実績明細ID
          INTO    lv_sales_exp_line_id                           --販売実績明細ID
          FROM    xxcos_sales_exp_lines  xsel
          WHERE   xsel.sales_exp_line_id = main_rec.sales_exp_line_id
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                     -- リターン・コード
                                            ,ov_errmsg      => lv_errmsg                      --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                    --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_exp_line_id         --項目名称1
                                            ,iv_data_value1 => main_rec.sales_exp_line_id     --データの値1
                                            );
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_select_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_exp_l_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            RAISE;
        END;
--
        -- ===============================
        --A-6． 販売実績明細テーブルステータス更新
        -- ===============================
        BEGIN
          UPDATE xxcos_sales_exp_lines
          SET    unit_price_mst_flag        = cv_flag_on                            --単価マスタ作成済フラグ
                ,last_updated_by            = cn_last_updated_by                    --最終更新者
                ,last_update_date           = cd_last_update_date                   --最終更新日
                ,last_update_login          = cn_last_update_login                  --最終更新ログイン
                ,request_id                 = cn_request_id                         --要求ID
                ,program_application_id     = cn_program_application_id             --コンカレント・プログラム・アプリケーションID
                ,program_id                 = cn_program_id                         --コンカレント・プログラムID
                ,program_update_date        = cd_program_update_date                --プログラム更新日
          WHERE  sales_exp_line_id          = main_rec.sales_exp_line_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  -- エラー・メッセージ
                                            ,ov_retcode     => lv_retcode                 -- リターン・コード
                                            ,ov_errmsg      => lv_errmsg                  --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info                --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_exp_line_id     --項目名称1
                                            ,iv_data_value1 => main_rec.sales_exp_line_id --データの値1
                                            );
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_exp_l_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --エラーメッセージ
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --エラーメッセージ
                             );
            ov_retcode := cv_status_warn;
            gn_new_warn_count := gn_new_warn_count + 1;
        END;
--
      EXCEPTION
        WHEN upm_work_exp THEN
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_errmsg --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --エラーメッセージ
                           );

          ov_errmsg  := lv_errmsg;
          ov_errbuf  := lv_errbuf;
          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
        WHEN get_tax_rule_exp THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_tkn_customer_err
                                                , cv_tkn_key_data
                                                , gv_msg_tkn_cust_code || cv_msg_part ||
                                                  main_rec.ship_to_customer_code || cv_msg_comma ||
                                                  gv_msg_tkn_exp_line_id || cv_msg_part ||
                                                  main_rec.sales_exp_line_id
                                                );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_errmsg --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errmsg --エラーメッセージ
                           );

          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_tkn_lock_table
                                                 );
          ELSE
            ov_errmsg  := NULL;
          END IF;
--
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --エラーメッセージ
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --エラーメッセージ
                           );
          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
      END;
--
    END LOOP main_loop;
--
    --エラーカウント
    gn_warn_tran_count     := gn_warn_tran_count + gn_new_warn_count;
--
    IF (gn_warn_tran_count > 0) THEN
      ROLLBACK;
      gn_warn_cnt := gn_warn_cnt + gn_tran_count;
      ov_errmsg := NULL;
      ov_errbuf := NULL;
/* 2009/08/25 Ver1.8 Add Start */
      --警告になった販売実績ヘッダID編集
      ln_skip_seq                    := ln_skip_seq + 1;
      gt_upd_header_tab(ln_skip_seq) := gv_bf_sales_exp_header_id;
/* 2009/08/25 Ver1.8 Add End   */
    ELSE
      COMMIT;
      gn_normal_cnt := gn_normal_cnt + gn_tran_count;
    END IF;
--
/* 2009/08/25 Ver1.8 Add Start */
    -- ==================================
    --A-7．販売実績明細スキップデータ更新
    -- ==================================
    proc_upd_skip_line(
       gt_upd_header_tab  --更新対象ヘッダIDテーブル型
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    --A-8．販売実績明細対象外データ更新
    -- ================================
    proc_upd_n_target_line(
       lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
/* 2009/08/25 Ver1.8 Add End   */
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_main_loop;
--

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ


--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- Loop1 メイン　A-1データ抽出
    -- ===============================
    open main_cur;
    proc_main_loop(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)

    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- A-0．初期処理
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submainの呼び出し（実際の処理はsubmainで行う）
      -- ===============================================
      submain(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;

--
    -- ===============================================
    -- A-7．終了処理
    -- ===============================================
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
/* 2009/08/25 Ver1.8 Mod Start */
    --正常終了でメッセージを出力した場合
    ELSIF ( gv_empty_line_flag = cv_flag_on ) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
/* 2009/08/25 Ver1.8 Mod End   */
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS003A02C;
/
