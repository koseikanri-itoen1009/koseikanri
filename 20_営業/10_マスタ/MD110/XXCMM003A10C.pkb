CREATE OR REPLACE PACKAGE BODY xxcmm003a10c
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : xxcmm003a10c(body)
 * Description     : 未取引客チェックリスト
 * MD.050          : MD050_CMM_003_A10_未取引客チェックリスト
 * MD.070          : MD050_CMM_003_A10_未取引客チェックリスト
 * Version         : 1.4
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 * init              P         初期情報抽出処理         (A-1)
 * chk_blance_amount P         売掛残高チェック         (A-3)
 * get_inventory     P         基準在庫数取得           (A-4)
 * make_worktable    P         ワークテーブルデータ登録 (A-6)
 * run_svf_api       P         SVF起動処理              (A-7)
 * termination       P         終了処理                 (A-8)
 * submain           P         メイン処理プロシージャ
 * main              P         コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- -------------- ------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------- ------------------------------------
 *  2009/02/04    1.0  SCS K.Shirasuna  初回作成
 *  2009/03/09    1.1  Yutaka.Kuboshima ファイル出力先のプロファイルの削除
 *                                      物件マスタコード取得の抽出条件を変更
 *  2010/02/12    1.2  Yutaka.Kuboshima 障害E_本稼動_01545 管理元拠点も出力するよう修正
 *  2011/04/18    1.3  Naoki.Horigome   障害E_本稼動_01956,01961,05192
 *                                      ・物件が紐付いていない場合でも基準在庫数,釣銭基準額を出力するよう修正
 *                                      ・業態分類（大分類）に関係なく、物件コードを出力するよう修正
 *                                      ・職責に紐付くアプリケーションではなく、ARの会計期間を取得するよう修正
 *                                      ・担当営業員コード、担当営業員名の取得処理を追加
 *                                      ・顧客に紐付く物件コードの表示方法を修正
 *  2011/05/09    1.4  S.Niki           障害E_本稼動_01956追加対応
 *                                      ・担当営業員の適用終了日について日付書式を修正
 *
 ************************************************************************/
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  --===============================================================
  -- グローバル定数
  --===============================================================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM003A10C';              -- パッケージ名
  cv_appl_short_name        CONSTANT VARCHAR2(5)   := 'XXCMM';                     -- アプリケーション短縮名
  cv_file_type_log          CONSTANT VARCHAR2(5)   := 'LOG';                       -- ログ出力
  cv_customer_class_cust    CONSTANT VARCHAR2(2)   := '10';                        -- 顧客区分：顧客
-- 2010/02/12 Ver1.2 E_本稼動_01545 add start by Yutaka.Kuboshima
  cv_customer_class_base    CONSTANT VARCHAR2(2)   := '1';                         -- 顧客区分：拠点
-- 2010/02/12 Ver1.2 E_本稼動_01545 add end by Yutaka.Kuboshima
  cv_cust_status_mc_cand    CONSTANT VARCHAR2(2)   := '10';                        -- 顧客ステータス：MC候補
  cv_cust_status_mc         CONSTANT VARCHAR2(2)   := '20';                        -- 顧客ステータス：MC
  cv_cust_status_sp_appr    CONSTANT VARCHAR2(2)   := '25';                        -- 顧客ステータス：SP決裁済
  cv_cust_status_stoped     CONSTANT VARCHAR2(2)   := '90';                        -- 顧客ステータス：中止決裁済
  cv_cust_status_except     CONSTANT VARCHAR2(2)   := '99';                        -- 顧客ステータス：対象外
  cv_business_htype_vd      CONSTANT VARCHAR2(2)   := '05';                        -- 業態(大分類)：ベンダー
  cn_undeal_span_vd         CONSTANT NUMBER        := -1;                          -- 未取引期間：ベンダー
  cn_undeal_span_not_vd     CONSTANT NUMBER        := -2;                          -- 未取引期間：ベンダー以外
  cv_lookup_cust_status     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KOKYAKU_STATUS'; -- 参照表：顧客ステータス
  cv_lookup_gyotai_sho      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';     -- 参照表：業態(小分類)
  cv_lookup_gyotai_chu      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_CHU';     -- 参照表：業態(中分類)
  cv_lookup_gyotai_dai      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_DAI';     -- 参照表：業態(大分類)
  cv_flex_department        CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';           -- 値セット名：部門
-- 2009/03/09 modify start
--  cn_instance_stat_deleted  CONSTANT NUMBER        := 6;                           -- インスタンスステータスID：物理削除済
  cv_instance_stat_deleted  CONSTANT VARCHAR2(30)  := '物件削除済';                -- インスタンスステータスID：物理削除済
-- 2009/03/09 modify end
  cv_currency_jpy           CONSTANT VARCHAR2(3)   := 'JPY';                       -- 通貨コード：日本円
  cv_svf_output_mode_pdf    CONSTANT VARCHAR2(1)   := '1';                         -- SVF出力区分：PDF出力
  cv_svf_form_name          CONSTANT VARCHAR2(20)  := 'XXCMM003A10S.xml';          -- フォーム様式ファイル名
  cv_svf_form_name_nodata   CONSTANT VARCHAR2(20)  := 'XXCMM003A10S2.xml';         -- フォーム様式ファイル名(0件用)
  cv_svf_query_name         CONSTANT VARCHAR2(20)  := 'XXCMM003A10S.vrq';          -- クエリー様式ファイル名
  cv_svf_param1             CONSTANT VARCHAR2(20)  := '[REQUEST_ID]=';             -- SVFパラメータ用：要求ID
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ（Y）
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ（N）
  cv_flag_c                 CONSTANT VARCHAR2(1)   := 'C';                         -- フラグ（C）
  cv_format_date_ymd        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                -- 日付フォーマット（年月日）
  cv_format_date_ym         CONSTANT VARCHAR2(7)   := 'YYYY/MM';                   -- 日付フォーマット（年月）
  cv_trunc_month            CONSTANT VARCHAR2(5)   := 'MONTH';                     -- TRUNC関数用
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add start by Shigeto.Niki
  cv_appl_short_nm_ar       CONSTANT VARCHAR2(2)   := 'AR';                        -- アプリケーション短縮名（AR）
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add end by Shigeto.Niki
--
  -- メッセージ番号
  cv_msg_cmm_00002          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002'; -- プロファイル取得エラーメッセージ
  cv_msg_cmm_00047          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00047'; -- 会計期間NULLエラー
  cv_msg_cmm_00339          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00339'; -- ワークテーブル登録エラー
  cv_msg_cmm_00340          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00340'; -- ワークテーブル削除エラー
  cv_msg_cmm_00001          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001'; -- 対象データなしログメッセージ
  cv_msg_cmm_00334          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00334'; -- 明細0件用メッセージ
  cv_msg_cmm_00014          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00014'; -- API呼出エラー
--
  -- トークン
  cv_tkn_ng_profile         CONSTANT VARCHAR2(15)  := 'NG_PROFILE';                                  -- エラープロファイル名
  cv_tkn_err_msg            CONSTANT VARCHAR2(15)  := 'ERR_MSG';                                     -- エラーメッセージ
  cv_tkn_ng_api             CONSTANT VARCHAR2(15)  := 'API_NAME';                                    -- API名称
  cv_tkn_ng_word            CONSTANT VARCHAR2(15)  := 'NG_WORD';                                     -- エラーワード
  cv_tkn_ng_data            CONSTANT VARCHAR2(15)  := 'NG_DATA';                                     -- エラーデータ
  cv_tkn_set_of_bks         CONSTANT VARCHAR2(50)  := '会計帳簿ID';                                  -- プロファイル名：会計帳簿ID
  cv_tkn_account_cd         CONSTANT VARCHAR2(100) := '未取引客チェックリスト用_勘定科目コード';     -- プロファイル名：勘定科目コード
  cv_tkn_resp_key           CONSTANT VARCHAR2(100) := '未取引客チェックリスト用_拠点内務員職責キー'; -- プロファイル名：勘定科目コード
  cv_tkn_period_sets_mn     CONSTANT VARCHAR2(100) := '顧客アドオン機能用会計カレンダ名';            -- プロファイル名：カレンダ名
  cv_tkn_out_file_dir       CONSTANT VARCHAR2(100) := '未取引客チェックリスト用_ファイル出力先';     -- プロファイル名：ファイル出力先
  cv_tkn_out_file_fil       CONSTANT VARCHAR2(100) := '未取引客チェックリスト用_ファイル名';         -- プロファイル名：ファイル名
  cv_tkn_ng_base_cd         CONSTANT VARCHAR2(50)  := '拠点コード';                                  -- メッセージ：拠点コード
  cv_tkn_ng_cust_cd         CONSTANT VARCHAR2(50)  := '顧客コード';                                  -- メッセージ：顧客コード
  cv_tkn_ng_inst_cd         CONSTANT VARCHAR2(50)  := '物件コード';                                  -- メッセージ：物件コード
  cv_tkn_ng_req_id          CONSTANT VARCHAR2(50)  := '要求ID';                                      -- メッセージ：要求ID
  cv_tkn_ng_api_nm          CONSTANT VARCHAR2(50)  := 'SVF 起動';                                    -- API名：SVF起動コンカレント
--
  --プロファイル名
  cv_prof_resp_id           CONSTANT VARCHAR2(50)  := 'RESP_ID';                         -- 職責ID
  cv_prof_set_of_bks_id     CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                -- 会計帳簿ID
  cv_prof_account_value_cd  CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_ACCOUNT_VALUE_CD';  -- 未取引客チェックリスト用勘定科目コード
  cv_prof_domestic_resp_key CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_DOMESTIC_RESP_KEY'; -- 未取引客チェックリスト用拠点内務員職責キー
  cv_prof_period_sets_mn    CONSTANT VARCHAR2(50)  := 'XXCMM1_003A00_GL_PERIOD_MN';      -- 未取引客チェックリスト用カレンダ名
-- 2009/03/09 delete start
--  cv_prof_out_file_dir      CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_OUT_FILE_DIR';      -- 未取引客チェックリスト用ファイル出力先
-- 2009/03/09 delete end
  cv_prof_out_file_fil      CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_OUT_FILE_FIL';      -- 未取引客チェックリスト用ファイル名
--
  --===============================================================
  -- グローバル変数
  --===============================================================
  gn_user_id                   NUMBER;                                              -- ユーザーID
  gn_resp_id                   NUMBER;                                              -- 職責ID
  gt_responsibility_key        fnd_responsibility.responsibility_key%TYPE;          -- 職責キー
  gn_resp_appl_id              NUMBER;                                              -- 職責アプリケーションID
  gt_sale_base_code            per_all_assignments_f.ass_attribute3%TYPE;           -- 拠点コード
  gn_set_of_bks_id             NUMBER;                                              -- 会計帳簿ID
  gt_account_value_cd          fnd_profile_option_values.profile_option_value%TYPE; -- 勘定科目コード
  gt_domestic_resp_key         fnd_profile_option_values.profile_option_value%TYPE; -- 拠点内務員職責キー
  gt_period_sets_mn            fnd_profile_option_values.profile_option_value%TYPE; -- カレンダ名
-- 2009/03/09 delete start
--  gt_out_file_dir              fnd_profile_option_values.profile_option_value%TYPE; -- ファイル出力先
-- 2009/03/09 delete end
  gt_out_file_fil              fnd_profile_option_values.profile_option_value%TYPE; -- ファイル名
  gd_process_date              DATE;                                                -- 業務日付
  gt_p_customer_status_name    fnd_lookup_values.meaning%TYPE;                      -- 顧客ステータス名(パラメータ)
  gt_p_sale_base_name          per_all_assignments_f.ass_attribute3%TYPE;           -- 拠点名(パラメータ)
  gt_instance_number           csi_item_instances.instance_number%TYPE;             -- 物件コード格納用
  gn_inventory_quantity_sum    NUMBER;                                              -- 基準在庫数格納用
  gt_period_name               gl_period_statuses.period_name%TYPE;                 -- 会計期間格納用
  gt_balance_month             xxcmm_rep_undeal_list.balance_month%TYPE;            -- 売掛残高月度格納用
  gn_balance_amount            NUMBER;                                              -- 売掛残高格納用
  gt_no_data_msg               xxcfo_rep_standard_po.data_empty_message%TYPE;       -- 0件メッセージ
  gv_svf_form_name             VARCHAR2(100);                                       -- フォーム様式ファイル名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start by Naoki.Horigome
  gt_employee_name             xxcmm_rep_undeal_list.employee_name%TYPE;            -- 担当営業員名称
  gt_employee_number           xxcmm_rep_undeal_list.employee_number%TYPE;          -- 担当営業員コード
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End   by Naoki.Horigome
--
  --===============================================================
  -- グローバルテーブルタイプ
  --===============================================================
--
  --===============================================================
  -- グローバルテーブル
  --===============================================================
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
--
  -- 未取引客情報抽出カーソル
  CURSOR undeal_cust_cur(
    iv_customer_status IN VARCHAR2  -- 顧客ステータス
   ,iv_sale_base_code  IN VARCHAR2) -- 拠点コード
  IS
    SELECT
           hca.cust_account_id                              cust_account_id         -- 顧客ID
          ,hca.account_number                               account_number          -- 顧客コード
          ,hp.party_name                                    account_name            -- 顧客名称
          ,xcgd.lookup_code                                 business_high_type      -- 業態分類(大分類)
          ,xcgd.meaning                                     business_high_type_name -- 業態分類(大分類)名
          ,TO_CHAR(xca.final_call_date, cv_format_date_ymd) final_call_date         -- 最終訪問日
          ,TO_CHAR(xca.final_tran_date, cv_format_date_ymd) final_tran_date         -- 最終取引日
          ,xca.sale_base_code                               sale_base_code          -- 拠点コード
          ,xdnm.sale_base_name                              sale_base_name          -- 拠点名
          ,hp.duns_number_c                                 status                  -- 顧客ステータス
          ,xcks.meaning                                     status_name             -- 顧客ステータス名
          ,NVL(xca.change_amount,0)                         change_amount           -- 釣銭基準額
    FROM
           hz_cust_accounts    hca                          -- 顧客マスタ
          ,xxcmm_cust_accounts xca                          -- 顧客追加情報マスタ
          ,hz_parties          hp                           -- パーティマスタ
          ,(SELECT
                   flv.lookup_code lookup_code              -- 参照コード
                  ,flv.meaning     meaning                  -- 内容
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_cust_status
            AND    flv.enabled_flag = cv_flag_y) xcks       -- 参照表：顧客ステータス
          ,(SELECT
                   flv.lookup_code lookup_code              -- 参照コード
                  ,flv.meaning     meaning                  -- 内容
                  ,flv.attribute1  attribute1               -- DFF1
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_gyotai_sho
            AND    flv.enabled_flag = cv_flag_y) xcgs       -- 参照表：業態(小分類)
          ,(SELECT
                   flv.lookup_code lookup_code              -- 参照コード
                  ,flv.meaning     meaning                  -- 内容
                  ,flv.attribute1  attribute1               -- DFF1
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_gyotai_chu
            AND    flv.enabled_flag = cv_flag_y) xcgc       -- 参照表：業態(中分類)
          ,(SELECT
                   flv.lookup_code lookup_code              -- 参照コード
                  ,flv.meaning     meaning                  -- 内容
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_gyotai_dai
            AND    flv.enabled_flag = cv_flag_y) xcgd       -- 参照表：業態(大分類)
          ,(SELECT
                   ffv.flex_value      sale_base_code       -- 拠点コード
                  ,ffv.attribute4      sale_base_name       -- 拠点名
            FROM
                   fnd_flex_value_sets ffvs                 -- 値セット定義マスタ
                  ,fnd_flex_values     ffv                  -- 値セット値定義マスタ
            WHERE
                   ffvs.flex_value_set_id   = ffv.flex_value_set_id
            AND    ffv.enabled_flag         = cv_flag_y
            AND    ffv.summary_flag         = cv_flag_n
            AND    ffvs.flex_value_set_name = cv_flex_department) xdnm
                                                            -- 値セット：拠点名
    WHERE
          hca.customer_class_code = cv_customer_class_cust
    AND   hca.cust_account_id     = xca.customer_id
    AND   hca.party_id            = hp.party_id
    AND   hp.duns_number_c        = xcks.lookup_code(+)
    AND   xcgs.attribute1         = xcgc.lookup_code
    AND   xcgc.attribute1         = xcgd.lookup_code
    AND   xcgs.lookup_code        = xca.business_low_type
    AND   xdnm.sale_base_code     = xca.sale_base_code
    AND   ((iv_customer_status IS NOT NULL
            AND hp.duns_number_c = iv_customer_status)
       OR  (iv_customer_status IS NULL
            AND (hp.duns_number_c NOT IN (cv_cust_status_mc_cand
                                         ,cv_cust_status_mc
                                         ,cv_cust_status_sp_appr
                                         ,cv_cust_status_stoped
                                         ,cv_cust_status_except)
               OR hp.duns_number_c IS NULL)))
    AND   ((iv_sale_base_code IS NOT NULL
-- 2010/02/12 Ver1.2 E_本稼動_01545 modify start by Yutaka.Kuboshima
--            AND xca.sale_base_code = iv_sale_base_code)
            AND  (xca.sale_base_code = iv_sale_base_code
               OR EXISTS (SELECT 'X'
                          FROM   hz_cust_accounts    hca2
                                ,xxcmm_cust_accounts xca2
                          WHERE  hca2.cust_account_id      = xca2.customer_id
                            AND  hca2.customer_class_code  = cv_customer_class_base
                            AND  xca2.management_base_code = iv_sale_base_code
                            AND  hca2.account_number       = xca.sale_base_code
                         )
                 ))
-- 2010/02/12 Ver1.2 E_本稼動_01545 modify end by Yutaka.Kuboshima
       OR ((iv_sale_base_code IS NULL
            AND gt_responsibility_key  = gt_domestic_resp_key
-- 2010/02/12 Ver1.2 E_本稼動_01545 modify start by Yutaka.Kuboshima
--            AND xca.sale_base_code     = gt_sale_base_code)
            AND  (xca.sale_base_code     = gt_sale_base_code
               OR EXISTS (SELECT 'X'
                          FROM   hz_cust_accounts    hca2
                                ,xxcmm_cust_accounts xca2
                          WHERE  hca2.cust_account_id      = xca2.customer_id
                            AND  hca2.customer_class_code  = cv_customer_class_base
                            AND  xca2.management_base_code = gt_sale_base_code
                            AND  hca2.account_number       = xca.sale_base_code
                         )
                 ))
-- 2010/02/12 Ver1.2 E_本稼動_01545 modify end by Yutaka.Kuboshima
       OR  (iv_sale_base_code IS NULL
            AND gt_responsibility_key <> gt_domestic_resp_key)))
    AND   ((xcgd.lookup_code  = cv_business_htype_vd
            AND  (xca.final_tran_date < TRUNC(ADD_MONTHS(gd_process_date, cn_undeal_span_vd)
                                             ,cv_trunc_month)
               OR xca.final_tran_date IS NULL))
       OR  (xcgd.lookup_code <> cv_business_htype_vd
            AND  (xca.final_tran_date < TRUNC(ADD_MONTHS(gd_process_date, cn_undeal_span_not_vd)
                                             ,cv_trunc_month)
               OR xca.final_tran_date IS NULL)));
--
  -- 物件コード取得カーソル
-- 2009/03/09 modify start
--  CURSOR get_instance_cur(
--    in_cust_account_id IN NUMBER) -- 顧客ID
--  IS
--    SELECT
--           cii.external_reference install_code -- 物件コード
--    FROM
--           csi_item_instances cii              -- 物件マスタ
--    WHERE
--           cii.owner_party_account_id = in_cust_account_id
--    AND    cii.instance_status_id    <> cn_instance_stat_deleted;
  CURSOR get_instance_cur(
    in_cust_account_id IN NUMBER) -- 顧客ID
  IS
    SELECT
           cii.external_reference install_code -- 物件コード
    FROM
           csi_item_instances cii              -- 物件マスタ
    WHERE
           cii.owner_party_account_id = in_cust_account_id
    AND    NOT EXISTS (SELECT 'X'
                       FROM csi_instance_statuses cis
                       WHERE cis.name               = cv_instance_stat_deleted
                       AND   cii.instance_status_id = cis.instance_status_id)
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add Start by Naoki.Horigome
    ORDER BY install_code ASC;
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add End   by Naoki.Horigome
-- 2009/03/09 modify end
--
  --===============================================================
  -- グローバルレコード型変数
  --===============================================================
--
  --===============================================================
  -- グローバル例外
  --===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期情報抽出処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_cust_status             IN         VARCHAR2,     --   顧客ステータス
    iv_sale_base_code          IN         VARCHAR2,     --   拠点コード
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- コンカレントパラメータログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log             -- ログ出力
      ,iv_conc_param1  => iv_cust_status               -- 顧客ステータス
      ,iv_conc_param2  => iv_sale_base_code            -- 拠点コード
      ,ov_errbuf       => lv_errbuf                    -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                   -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ユーザーIDを取得
    gn_user_id      := fnd_global.user_id;
--
    -- プロファイル：職責アプリケーションIDを取得
    gn_resp_appl_id := fnd_global.resp_appl_id;
--
    -- プロファイル：職責IDを取得
    gn_resp_id      := fnd_profile.value(cv_prof_resp_id);
--
    -- 業務日付取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- ログインユーザの職責キー取得
    SELECT
           fr.responsibility_key                             -- 職責キー
    INTO
           gt_responsibility_key                             -- 職責キー
    FROM
           fnd_responsibility fr                             -- 職責マスタ
    WHERE
           fr.responsibility_id = gn_resp_id
    AND    fr.application_id    = gn_resp_appl_id;           -- 職責アプリケーションID
--
    -- 拠点コード取得
    SELECT
           paaf.ass_attribute5 -- 所属コード(新)
    INTO
           gt_sale_base_code   -- 拠点コード
    FROM
           per_all_people_f      papf -- 従業員マスタ
          ,per_all_assignments_f paaf -- アサイメントマスタ
          ,fnd_user              fu   -- ユーザーマスタ
    WHERE
           fu.user_id           = gn_user_id
    AND    fu.employee_id       = papf.person_id
    AND    papf.person_id       = paaf.person_id
    AND    TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                              AND TRUNC(papf.effective_end_date)
    AND    TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date)
                              AND TRUNC(paaf.effective_end_date);
--
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id    := TO_NUMBER(fnd_profile.value(cv_prof_set_of_bks_id));
--
    -- プロファイルが取得できなかったらエラー
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_set_of_bks
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- プロファイルから勘定科目コード取得
    gt_account_value_cd := fnd_profile.value(cv_prof_account_value_cd);
--
    -- プロファイルが取得できなかったらエラー
    IF (gt_account_value_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_account_cd
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- プロファイルから拠点内務員職責キー取得
    gt_domestic_resp_key := fnd_profile.value(cv_prof_domestic_resp_key);
--
    -- プロファイルが取得できなかったらエラー
    IF (gt_domestic_resp_key IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_resp_key
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- プロファイルからカレンダ名取得
    gt_period_sets_mn   := fnd_profile.value(cv_prof_period_sets_mn);
--
    -- プロファイルが取得できなかったらエラー
    IF (gt_period_sets_mn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_period_sets_mn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- 2009/03/09 delete start
    -- プロファイルからファイル出力先取得
--    gt_out_file_dir     := fnd_profile.value(cv_prof_out_file_dir);
--
    -- プロファイルが取得できなかったらエラー
--    IF (gt_out_file_dir IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_msg_cmm_00002
--                    ,iv_token_name1  => cv_tkn_ng_profile
--                    ,iv_token_value1 => cv_tkn_out_file_dir
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
    --
-- 2009/03/09 delete end
    -- プロファイルからファイル名取得
    gt_out_file_fil     := fnd_profile.value(cv_prof_out_file_fil);
--
    -- プロファイルが取得できなかったらエラー
    IF (gt_out_file_fil IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_out_file_fil
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (iv_cust_status IS NOT NULL) THEN
      -- パラメータ：顧客ステータス名取得
      SELECT
             MAX(flv.meaning) meaning            -- 顧客ステータス名※MAXはエラーで落ちないように
      INTO
             gt_p_customer_status_name           -- 顧客ステータス名
      FROM
             fnd_lookup_values flv
      WHERE
             flv.language     = 'JA'
      AND    flv.lookup_type  = cv_lookup_cust_status
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.lookup_code  = iv_cust_status;
    END IF;
--
    IF (iv_sale_base_code IS NOT NULL) THEN
      -- パラメータ：拠点名取得
      SELECT
             MAX(ffv.attribute4) sale_base_name  -- 拠点名※MAXはエラーで落ちないように
      INTO
             gt_p_sale_base_name                 -- 拠点名
      FROM
             fnd_flex_value_sets ffvs            -- 値セット定義マスタ
            ,fnd_flex_values     ffv             -- 値セット値定義マスタ
      WHERE
             ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffv.enabled_flag         = cv_flag_y
      AND    ffv.summary_flag         = cv_flag_n
      AND    ffvs.flex_value_set_name = cv_flex_department
      AND    ffv.flex_value           = iv_sale_base_code;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      -- コンカレント出力がPDFのため対象外
--      ov_errmsg  := lv_errbuf;
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_blance_amount
   * Description      : 売掛残高チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_blance_amount(
    in_cust_account_id         IN         VARCHAR2,     --   顧客ID
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_blance_amount'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 閉じた最新の会計期間取得
    BEGIN
      SELECT
             period_name      -- 会計期間
            ,balance_month    -- 売掛残高月度
      INTO
             gt_period_name   -- 会計期間
            ,gt_balance_month -- 売掛残高月度
      FROM
            (SELECT
                    gps.period_name                            period_name   -- 会計期間
                   ,TO_CHAR(gps.start_date, cv_format_date_ym) balance_month -- 売掛残高月度
             FROM
                    gl_periods         gp            -- 会計期間マスタ
                   ,gl_period_statuses gps           -- 会計期間ステータス
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add start by Shigeto.Niki
                   ,fnd_application    fa            -- アプリケーションマスタ
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add end by Shigeto.Niki
             WHERE
                    gp.period_name            = gps.period_name
             AND    gp.period_set_name        = gt_period_sets_mn
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify start by Shigeto.Niki
--             AND    gps.application_id        = gn_resp_appl_id
             AND    fa.application_id         = gps.application_id
             AND    fa.application_short_name = cv_appl_short_nm_ar
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify end by Shigeto.Niki
             AND    gps.set_of_books_id       = gn_set_of_bks_id
             AND    gp.adjustment_period_flag = cv_flag_n
             AND    gps.closing_status        = cv_flag_c
             ORDER BY
                    gps.start_date DESC)
      WHERE ROWNUM = 1;
--
      -- 会計期間がNULLだった場合エラー
      IF (gt_period_name IS NULL) THEN
        RAISE NO_DATA_FOUND;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 会計期間NULLエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_msg_cmm_00047
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 売掛残高取得
    BEGIN
      SELECT
             SUM((NVL(jzab.begin_bal_entered_dr, 0) -  -- 月初残高(借方)
                  NVL(jzab.begin_bal_entered_cr, 0)) + -- 月初残高(貸方)
                 (NVL(jzab.period_net_entered_dr, 0) - -- 当月発生累計額(借方)
                  NVL(jzab.period_net_entered_cr, 0))) -- 当月発生累計額(貸方)
                                                       -- 売掛残高
      INTO
             gn_balance_amount           -- 売掛残高
      FROM
             jg_zz_ar_balances_v  jzab   -- JG顧客残高
            ,gl_code_combinations gcc    -- 勘定科目組合せマスタ
      WHERE
             jzab.posted_to_gl_flag   = cv_flag_y
      AND    jzab.set_of_books_id     = gn_set_of_bks_id
      AND    jzab.currency_code       = cv_currency_jpy
      AND    jzab.customer_id         = in_cust_account_id
      AND    jzab.code_combination_id = gcc.code_combination_id
      AND    jzab.period_name         = gt_period_name
      AND    gcc.enabled_flag         = cv_flag_y
      AND    gcc.segment3             = gt_account_value_cd
      GROUP BY
             jzab.customer_id;
    EXCEPTION
      -- 対象データ無し：正常
      WHEN NO_DATA_FOUND THEN
        gn_balance_amount := NULL;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- コンカレント出力がPDFのため対象外
--      ov_errmsg  := lv_errbuf;
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
  END chk_blance_amount;
--
--#####################################  固定部 END   ##########################################
--
  /**********************************************************************************
   * Procedure Name   : get_inventory
   * Description      : 基準在庫数取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_inventory(
    in_cust_account_id         IN         VARCHAR2,     --   顧客ID
    on_inventory_quantity_sum  OUT        NUMBER,       --   基準在庫数
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inventory'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT
           SUM(NVL(xmvc.inventory_quantity, 0)) inventory_quantity -- 基準在庫数
    INTO
           on_inventory_quantity_sum                               -- 基準在庫数
    FROM
           xxcoi_mst_vd_column xmvc                                -- ＶＤコラムマスタ
    WHERE
           xmvc.customer_id = in_cust_account_id
    GROUP BY
           xmvc.customer_id;
--
  EXCEPTION
    -- 対象データ無し：正常
    WHEN NO_DATA_FOUND THEN
      on_inventory_quantity_sum := NULL;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_inventory;
--
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start by Naoki.Horigome
  /**********************************************************************************
   * Procedure Name   : get_employee
   * Description      : 担当営業員名称取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_employee(
    in_cust_account_id         IN         NUMBER,       --   顧客ID
    ov_employee_name           OUT        VARCHAR2,     --   担当営業員名称
    ov_employee_number         OUT        VARCHAR2,     --   担当営業員コード
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_employee'; -- プログラム名
    cv_employee_err_msg  CONSTANT VARCHAR2(30)  := '担当営業員取得エラー';
    cv_employee_err_code CONSTANT VARCHAR2(30)  := '999999';
    cv_max_date          CONSTANT VARCHAR2(10)  := '9999/12/31';
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    SELECT
           xsv.kanji_last || xsv.kanji_first employee_name   -- 担当営業員名称
          ,xsv.employee_number employee_number               -- 担当営業員コード
    INTO
           ov_employee_name
          ,ov_employee_number
    FROM
           xxcos_salesreps_v xsv  -- 担当営業員ビュー
    WHERE
           xsv.cust_account_id = in_cust_account_id
    AND
           gd_process_date BETWEEN xsv.effective_start_date
-- 2011/05/09 Ver1.4 E_本稼動_01956追加対応 modify start by Shigeto.Niki
--                           AND     NVL(xsv.effective_end_date,cv_max_date);
                           AND     NVL(xsv.effective_end_date, TO_DATE(cv_max_date, cv_format_date_ymd));
-- 2011/05/09 Ver1.4 E_本稼動_01956追加対応 modify end by Shigeto.Niki
--
  EXCEPTION
    -- 対象データ無し：正常
    WHEN NO_DATA_FOUND THEN
      ov_employee_name   := cv_employee_err_msg;
      ov_employee_number := cv_employee_err_code;
--
    -- 複数件取得時：正常
    WHEN TOO_MANY_ROWS THEN
      ov_employee_name   := cv_employee_err_msg;
      ov_employee_number := cv_employee_err_code;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_employee;
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End   by Naoki.Horigome
--
  /**********************************************************************************
   * Procedure Name   : make_worktable
   * Description      : ワークテーブルデータ登録(A-6)
   ***********************************************************************************/
  PROCEDURE make_worktable(
    iv_sale_base_code          IN         VARCHAR2,     --   拠点コード
    iv_sale_base_name          IN         VARCHAR2,     --   拠点名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start   by Naoki.Horigome
    iv_employee_number         IN         VARCHAR2,     --   担当営業員コード
    iv_employee_name           IN         VARCHAR2,     --   担当営業員名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End     by Naoki.Horigome
    iv_account_number          IN         VARCHAR2,     --   顧客コード
    iv_account_name            IN         VARCHAR2,     --   顧客名
    iv_status                  IN         VARCHAR2,     --   顧客ステータス
    iv_status_name             IN         VARCHAR2,     --   顧客ステータス名
    iv_business_high_type      IN         VARCHAR2,     --   業態分類（大分類）
    iv_business_high_type_name IN         VARCHAR2,     --   業態分類（大分類）名
    iv_final_call_date         IN         VARCHAR2,     --   最終訪問日
    iv_final_tran_date         IN         VARCHAR2,     --   最終取引日
    iv_instance_number         IN         VARCHAR2,     --   物件コード
    in_inventory_quantity_sum  IN         NUMBER,       --   基準在庫数
    in_change_amount           IN         NUMBER,       --   釣銭基準額
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_worktable'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      INSERT INTO xxcmm_rep_undeal_list xrul( -- 未取引客チェックリストワーク
        request_id              -- 要求ID
       ,p_customer_status_name  -- 顧客ステータス名(パラメータ)
       ,p_base_cd_name          -- 拠点名(パラメータ)
       ,base_code               -- 拠点コード
       ,base_cd_name            -- 拠点名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start   by Naoki.Horigome
       ,employee_number         -- 担当営業員コード
       ,employee_name           -- 担当営業員名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End     by Naoki.Horigome
       ,customer_code           -- 顧客コード
       ,customer_name           -- 顧客名
       ,customer_status         -- 顧客ステータス
       ,customer_status_name    -- 顧客ステータス名
       ,business_high_type      -- 業態分類（大分類）
       ,business_high_type_name -- 業態分類（大分類）名
       ,final_call_date         -- 最終訪問日
       ,final_tran_date         -- 最終取引日
       ,install_code            -- 物件コード
       ,inventory_quantity      -- 在庫
       ,change_amount           -- 釣銭基準額
       ,balance_amount          -- 売掛残高
       ,balance_month           -- 売掛残高月度
       ,undeal_reason           -- 未取引理由
       ,stop_approval_reason    -- 中止事由
       ,created_by              -- 作成者
       ,creation_date           -- 作成日
       ,last_updated_by         -- 最終更新者
       ,last_update_date        -- 最終更新日
       ,last_update_login       -- 最終更新ﾛｸﾞｲﾝ
       ,program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       ,program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       ,program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
      ) VALUES (
        cn_request_id                             -- 要求ID
       ,gt_p_customer_status_name                 -- 顧客ステータス名(パラメータ)
       ,gt_p_sale_base_name                       -- 拠点名(パラメータ)
       ,iv_sale_base_code                         -- 拠点コード
       ,iv_sale_base_name                         -- 拠点名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start   by Naoki.Horigome
       ,iv_employee_number                        -- 担当営業員コード
       ,iv_employee_name                          -- 担当営業員名
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End     by Naoki.Horigome
       ,iv_account_number                         -- 顧客コード
       ,iv_account_name                           -- 顧客名
       ,iv_status                                 -- 顧客ステータス
       ,iv_status_name                            -- 顧客ステータス名
       ,iv_business_high_type                     -- 業態分類（大分類）
       ,iv_business_high_type_name                -- 業態分類（大分類）名
       ,iv_final_call_date                        -- 最終訪問日
       ,iv_final_tran_date                        -- 最終取引日
       ,iv_instance_number                        -- 物件コード
       ,in_inventory_quantity_sum                 -- 在庫
       ,in_change_amount                          -- 釣銭基準額
       ,gn_balance_amount                         -- 売掛残高
       ,gt_balance_month                          -- 売掛残高月度
       ,NULL                                      -- 未取引理由
       ,NULL                                      -- 中止事由
       ,cn_created_by                             -- 作成者
       ,cd_creation_date                          -- 作成日
       ,cn_last_updated_by                        -- 最終更新者
       ,cd_last_update_date                       -- 最終更新日
       ,cn_last_update_login                      -- 最終更新ﾛｸﾞｲﾝ
       ,cn_program_application_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       ,cn_program_id                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       ,cd_program_update_date);                  -- ﾌﾟﾛｸﾞﾗﾑ更新日
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_msg_cmm_00339
                      ,iv_token_name1  => cv_tkn_err_msg
                      ,iv_token_value1 => cv_tkn_ng_base_cd || cv_msg_part || iv_sale_base_code || cv_msg_pnt ||
                                          cv_tkn_ng_cust_cd || cv_msg_part || iv_account_number || cv_msg_pnt ||
                                          cv_tkn_ng_inst_cd || cv_msg_part || iv_instance_number || cv_msg_pnt ||
                                          cv_tkn_ng_req_id || cv_msg_part || cn_request_id || cv_msg_pnt ||
                                          SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 処理対象件数加算
    gn_target_cnt := gn_target_cnt + 1;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- コンカレント出力がPDFのため対象外
--      ov_errmsg  := lv_errbuf;
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
  END make_worktable;
--
  /**********************************************************************************
   * Procedure Name   : run_svf_api
   * Description      : SVF起動処理 (A-7)
   ***********************************************************************************/
  PROCEDURE run_svf_api(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'run_svf_api'; -- プログラム名
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
    lv_svf_param1 VARCHAR2(50); -- SVFパラメータ：要求ID格納用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- パラメータ：要求IDの設定
    lv_svf_param1    := cv_svf_param1 || cn_request_id;
--
    -- ファイル名編集
    gt_out_file_fil  := gt_out_file_fil ||
                        TO_CHAR(cd_creation_date, 'YYYYMMDD') ||
                        TO_CHAR(cn_request_id);
--
    IF (gn_target_cnt = 0) THEN
    -- 対象データ0件の場合
--
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
      -- 0件メッセージをログに出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_msg_cmm_00001
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
--
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
      -- 0件フォーム様式ファイル名設定
      gv_svf_form_name := cv_svf_form_name_nodata;
--
    ELSE
    -- 対象データがあった場合
      gv_svf_form_name := cv_svf_form_name;
    END IF;
--
    -- 帳票0件メッセージ取得
    gt_no_data_msg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name -- アプリケーション短縮名
                       ,cv_msg_cmm_00334   -- 明細0件用メッセージ
                      );
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => cv_pkg_name            -- コンカレント名
     ,iv_file_name    => gt_out_file_fil        -- 出力ファイル名
     ,iv_file_id      => cv_pkg_name            -- 帳票ID
     ,iv_output_mode  => cv_svf_output_mode_pdf -- 出力区分(=1：PDF出力）
     ,iv_frm_file     => gv_svf_form_name       -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_svf_query_name      -- クエリー様式ファイル名
     ,iv_org_id       => NULL                   -- ORG_ID
     ,iv_user_name    => gn_user_id             -- ログイン・ユーザ名
     ,iv_resp_name    => gt_responsibility_key  -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                   -- 文書名
     ,iv_printer_name => NULL                   -- プリンタ名
     ,iv_request_id   => cn_request_id          -- 要求ID
     ,iv_nodata_msg   => gt_no_data_msg         -- データなしメッセージ
     ,iv_svf_param1   => lv_svf_param1          -- svf可変パラメータ1：要求ID
    );
--
    -- エラーの場合
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00014
                    ,iv_token_name1  => cv_tkn_ng_api
                    ,iv_token_value1 => cv_tkn_ng_api_nm
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_tkn_ng_req_id
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => cn_request_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- コンカレント出力がPDFのため対象外
--      ov_errmsg  := lv_errbuf;
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
  END run_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : termination
   * Description      : 終了処理(A-8)
   ***********************************************************************************/
  PROCEDURE termination(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'termination'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 未取引客チェックリストワーク削除
    BEGIN
      DELETE FROM xxcmm_rep_undeal_list xrul
      WHERE xrul.request_id = cn_request_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00340
                    ,iv_token_name1  => cv_tkn_err_msg
                    ,iv_token_value1 => cv_tkn_ng_req_id || cv_msg_part || cn_request_id
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- コンカレント出力がPDFのため対象外
--      ov_errmsg  := lv_errbuf;
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
  END termination;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_cust_status             IN         VARCHAR2,     --   顧客ステータス
    iv_sale_base_code          IN         VARCHAR2,     --   拠点コード
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add Start by Naoki.Horigome
    cv_etc         CONSTANT VARCHAR2(10) := '他'; 
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add End   by Naoki.Horigome
--
    -- *** ローカル変数 ***
    ln_get_instance_cur_cnt NUMBER DEFAULT 0; -- 物件コード取得カーソル件数格納用
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add start by Shigeto.Niki
    lv_external_reference   csi_item_instances.external_reference%TYPE; -- 物件コード
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add end by Shigeto.Niki
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add Start by Naoki.Horigome
    lv_work_reference       csi_item_instances.external_reference%TYPE; -- 複数件チェック用物件コード
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add End   by Naoki.Horigome

--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt          := 0;     -- 対象件数
    gn_normal_cnt          := 0;     -- 正常件数
    gn_error_cnt           := 0;     -- エラー件数
--
    -- =====================================================
    --  初期情報抽出処理(A-1)
    -- =====================================================
    init(
       iv_cust_status                     -- 顧客ステータス
      ,iv_sale_base_code                  -- 拠点コード
      ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                         -- リターン・コード             --# 固定 #
      ,lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  未取引客情報抽出(A-2)
    -- =====================================================
    <<undeal_cust_loop>>
    FOR l_undeal_cust_rec IN undeal_cust_cur(
      iv_cust_status     -- 顧客ステータス
     ,iv_sale_base_code) -- 拠点コード
    LOOP
--
      -- =====================================================
      -- 売掛残高チェック(A-3)
      -- =====================================================
      chk_blance_amount(
        l_undeal_cust_rec.cust_account_id  -- 顧客ID
       ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
       ,lv_retcode                         -- リターン・コード             --# 固定 #
       ,lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
-- 2011/04/13 Ver1.3 E_本稼動_05192 Delete Start by Naoki.Horigome
--      -- 業態(大分類)がベンダーの場合
--      IF (l_undeal_cust_rec.business_high_type = cv_business_htype_vd) THEN
-- 2011/04/13 Ver1.3 E_本稼動_05192 Delete end   by Naoki.Horigome
--
        -- =====================================================
        -- 基準在庫数取得(A-4)
        -- =====================================================
        get_inventory(
          l_undeal_cust_rec.cust_account_id  -- 顧客ID
         ,gn_inventory_quantity_sum          -- 基準在庫数
         ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                         -- リターン・コード             --# 固定 #
         ,lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start by Naoki.Horigome
        -- =====================================================
        -- 担当営業員名称取得(A-5)
        -- =====================================================
        get_employee(
          l_undeal_cust_rec.cust_account_id  -- 顧客ID
         ,gt_employee_name                   -- 担当営業員名称
         ,gt_employee_number                 -- 担当営業員コード
         ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                         -- リターン・コード             --# 固定 #
         ,lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End   by Naoki.Horigome
--
        -- =====================================================
        -- 物件コード取得(A-5)
        -- =====================================================
        -- 物件コードカーソル件数初期化
        ln_get_instance_cur_cnt := 0;
--
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify start by Shigeto.Niki
-- FOR LOOP -> LOOPに変更
--        <<get_instance_loop>>
--        FOR l_get_instance_rec IN get_instance_cur(l_undeal_cust_rec.cust_account_id) LOOP
----
--          -- =====================================================
--          -- ワークテーブルデータ登録(A-6)
--          -- =====================================================
--          make_worktable(
--            l_undeal_cust_rec.sale_base_code          -- 拠点コード
--           ,l_undeal_cust_rec.sale_base_name          -- 拠点名
--           ,l_undeal_cust_rec.account_number          -- 顧客コード
--           ,l_undeal_cust_rec.account_name            -- 顧客名
--           ,l_undeal_cust_rec.status                  -- 顧客ステータス
--           ,l_undeal_cust_rec.status_name             -- 顧客ステータス名
--           ,l_undeal_cust_rec.business_high_type      -- 業態分類（大分類）
--           ,l_undeal_cust_rec.business_high_type_name -- 業態分類（大分類）名
--           ,l_undeal_cust_rec.final_call_date         -- 最終訪問日
--           ,l_undeal_cust_rec.final_tran_date         -- 最終取引日
--           ,NVL(l_get_instance_rec.install_code, 0)   -- 物件コード
--           ,NVL(gn_inventory_quantity_sum, 0)         -- 在庫
--           ,l_undeal_cust_rec.change_amount           -- 釣銭基準額
--           ,lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
--           ,lv_retcode                                -- リターン・コード             --# 固定 #
--           ,lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
--          );
----
--          ln_get_instance_cur_cnt := get_instance_cur%ROWCOUNT;
----
--          IF (lv_retcode = cv_status_error) THEN
--            --(エラー処理)
--            RAISE global_process_expt;
--          END IF;
----
--        END LOOP get_instance_loop;
--
        -- 物件コード初期化
        lv_external_reference := NULL;
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add Start by Naoki.Horigome
        lv_work_reference     := NULL;
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add End   by Naoki.Horigome
        -- カーソルオープン
        OPEN get_instance_cur(l_undeal_cust_rec.cust_account_id);
        -- フェッチ
        FETCH get_instance_cur INTO lv_external_reference;
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add Start by Naoki.Horigome
        -- 1件以上値が取れた場合
        IF lv_external_reference IS NOT NULL THEN
          -- フェッチ
          FETCH get_instance_cur INTO lv_work_reference;
--
          IF get_instance_cur%FOUND THEN
            --  2件以上の場合
            lv_external_reference := lv_external_reference || cv_etc;
          END IF;
        END IF;
-- 2011/04/13 Ver1.3 E_本稼動_05192 Add End   by Naoki.Horigome
--
-- 2011/04/13 Ver1.3 E_本稼動_05192 Delete Start by Naoki.Horigome
--        -- ループ
--        <<get_instance_loop>>
--        LOOP
--
--          -- =====================================================
--          -- ワークテーブルデータ登録(A-6)
--          -- =====================================================
--          make_worktable(
--            l_undeal_cust_rec.sale_base_code          -- 拠点コード
--           ,l_undeal_cust_rec.sale_base_name          -- 拠点名
--           ,l_undeal_cust_rec.account_number          -- 顧客コード
--           ,l_undeal_cust_rec.account_name            -- 顧客名
--           ,l_undeal_cust_rec.status                  -- 顧客ステータス
--           ,l_undeal_cust_rec.status_name             -- 顧客ステータス名
--           ,l_undeal_cust_rec.business_high_type      -- 業態分類（大分類）
--           ,l_undeal_cust_rec.business_high_type_name -- 業態分類（大分類）名
--           ,l_undeal_cust_rec.final_call_date         -- 最終訪問日
--           ,l_undeal_cust_rec.final_tran_date         -- 最終取引日
---- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify start by Shigeto.Niki
----           ,NVL(l_get_instance_rec.install_code, 0)   -- 物件コード
--           ,lv_external_reference                     -- 物件コード
---- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify end by Shigeto.Niki
--           ,NVL(gn_inventory_quantity_sum, 0)         -- 在庫
--           ,l_undeal_cust_rec.change_amount           -- 釣銭基準額
--           ,lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
--           ,lv_retcode                                -- リターン・コード             --# 固定 #
--           ,lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
--          );
----
--          IF (lv_retcode = cv_status_error) THEN
--            --(エラー処理)
--            RAISE global_process_expt;
--          END IF;
--
--          -- フェッチ
--          FETCH get_instance_cur INTO lv_external_reference;
--          -- 終了条件
--          EXIT WHEN (get_instance_cur%NOTFOUND);
----
--        END LOOP get_instance_loop;
-- 2011/04/13 Ver1.3 E_本稼動_05192 Delete End   by Naoki.Horigome
--
        -- カーソルクローズ
        CLOSE get_instance_cur;
--
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add Start by Naoki.Horigome
--
          -- =====================================================
          -- ワークテーブルデータ登録(A-6)
          -- =====================================================
          make_worktable(
            l_undeal_cust_rec.sale_base_code          -- 拠点コード
           ,l_undeal_cust_rec.sale_base_name          -- 拠点名
           ,gt_employee_number                        -- 担当営業員コード
           ,gt_employee_name                          -- 担当営業員名
           ,l_undeal_cust_rec.account_number          -- 顧客コード
           ,l_undeal_cust_rec.account_name            -- 顧客名
           ,l_undeal_cust_rec.status                  -- 顧客ステータス
           ,l_undeal_cust_rec.status_name             -- 顧客ステータス名
           ,l_undeal_cust_rec.business_high_type      -- 業態分類（大分類）
           ,l_undeal_cust_rec.business_high_type_name -- 業態分類（大分類）名
           ,l_undeal_cust_rec.final_call_date         -- 最終訪問日
           ,l_undeal_cust_rec.final_tran_date         -- 最終取引日
           ,lv_external_reference                     -- 物件コード
           ,NVL(gn_inventory_quantity_sum, 0)         -- 在庫
           ,l_undeal_cust_rec.change_amount           -- 釣銭基準額
           ,lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
           ,lv_retcode                                -- リターン・コード             --# 固定 #
           ,lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961,05192 Add End   by Naoki.Horigome
--
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify end by Shigeto.Niki
--
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961 Delete Start by Naoki.Horigome
--      END IF;
      -- 業態(大分類)がベンダー以外の場合
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify start by Shigeto.Niki
--      IF ((l_undeal_cust_rec.business_high_type <> cv_business_htype_vd)
--        OR ((l_undeal_cust_rec.business_high_type = cv_business_htype_vd)
--            AND (ln_get_instance_cur_cnt = 0)))
--      THEN
--      IF (l_undeal_cust_rec.business_high_type <> cv_business_htype_vd) THEN
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify end by Shigeto.Niki
--
--        -- =====================================================
--        -- ワークテーブルデータ登録(A-6)
--        -- =====================================================
--        make_worktable(
--          l_undeal_cust_rec.sale_base_code          -- 拠点コード
--         ,l_undeal_cust_rec.sale_base_name          -- 拠点名
--         ,l_undeal_cust_rec.account_number          -- 顧客コード
--         ,l_undeal_cust_rec.account_name            -- 顧客名
--         ,l_undeal_cust_rec.status                  -- 顧客ステータス
--         ,l_undeal_cust_rec.status_name             -- 顧客ステータス名
--         ,l_undeal_cust_rec.business_high_type      -- 業態分類（大分類）
--         ,l_undeal_cust_rec.business_high_type_name -- 業態分類（大分類）名
--         ,l_undeal_cust_rec.final_call_date         -- 最終訪問日
--         ,l_undeal_cust_rec.final_tran_date         -- 最終取引日
---- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify start by Shigeto.Niki
----         ,NULL                                      -- 物件コード
--         ,lv_external_reference                     -- 物件コード
---- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 modify end by Shigeto.Niki
--         ,NULL                                      -- 在庫
--         ,NULL                                      -- 釣銭基準額
--         ,lv_errbuf                                 -- エラー・メッセージ           --# 固定 #
--         ,lv_retcode                                -- リターン・コード             --# 固定 #
--         ,lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
--        );
----
--        IF (lv_retcode = cv_status_error) THEN
--          --(エラー処理)
--          RAISE global_process_expt;
--        END IF;
----
--      END IF;
-- 
-- 2011/04/13 Ver1.3 E_本稼動_01956,01961 Delete End   by Naoki.Horigome
    END LOOP undeal_cust_loop;
--
    -- =====================================================
    --  SVFコンカレント起動(A-7)
    -- =====================================================
    run_svf_api(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  終了処理(A-8)
    -- =====================================================
    termination(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 警告終了
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- コンカレント出力がPDFのため対象外
--      ov_errmsg  := lv_errbuf;
      ov_errbuf  := SUBSTRB(lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add start by Shigeto.Niki
      IF (get_instance_cur%ISOPEN) THEN
        CLOSE get_instance_cur;
      END IF;
-- 2011/01/07 Ver1.3 E_本稼動_01956,01961,05192 add end by Shigeto.Niki
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
    errbuf                     OUT NOCOPY VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                    OUT NOCOPY VARCHAR2,         --    エラーコード        --# 固定 #
    iv_cust_status             IN         VARCHAR2,         --    顧客ステータス
    iv_sale_base_code          IN         VARCHAR2          --    拠点コード
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCMM';            -- アドオン：マスタ
    cv_cpp_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token           CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
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
       iv_which   => cv_file_type_log
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_cust_status                     -- 顧客ステータス
      ,iv_sale_base_code                  -- 拠点コード
      ,lv_errbuf                          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                         -- リターン・コード             --# 固定 #
      ,lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- =====================================================
    --  終了処理(A-8)
    -- =====================================================
    -- エラーの場合、エラー発生時処理件数を設定する
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;          -- 対象件数
      gn_normal_cnt := 0;          -- 成功件数
      gn_error_cnt  := 1;          -- エラー件数
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --エラーの場合
    IF (lv_retcode = cv_status_error) THEN
      --エラーメッセージ
      errbuf  := lv_errbuf;
      --ステータスセット
      retcode := lv_retcode;
      ROLLBACK;
    END IF;
--
--###########################  固定部 START   #####################################################
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
END xxcmm003a10c;
/
