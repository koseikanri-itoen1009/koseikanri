CREATE OR REPLACE PACKAGE BODY XXCSO010A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO010A05C (body)
 * Description      : 契約書確定状況CSV出力
 * MD.050           : 契約書確定状況CSV出力 (MD050_CSO_010A05)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             CSVファイル出力(A-5)
 *  get_contract_data1     契約書情報の取得【新規】(A-2)
 *  get_contract_data2     契約書情報の取得【条件変更】(A-3)
 *  get_contract_data3     契約書情報の取得【確定済】(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/06    1.0   S.Niki           main新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  init_err_expt               EXCEPTION;      -- 初期処理エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO010A05C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- 日付書式
  cv_format_fmt1              CONSTANT VARCHAR2(50)  := 'YYYYMMDD';
  cv_format_fmt2              CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD HH24:MI:SS';
  --
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- 文字列括り
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  -- メッセージコード
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- 業務処理日付取得エラー
  cv_msg_cso_00640            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00640';          -- 売上拠点
  cv_msg_cso_00641            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00641';          -- 契約状況
  cv_msg_cso_00642            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00642';          -- 抽出対象日(FROM)
  cv_msg_cso_00643            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00643';          -- 抽出対象日(TO)
  cv_msg_cso_00644            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00644';          -- 抽出対象日期間大小チェックエラー
  cv_msg_cso_00645            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00645';          -- 契約書確定状況CSVヘッダ
--
  -- トークン
  cv_tkn_base_code            CONSTANT VARCHAR2(20)  := 'BASE_CODE';                 -- 売上拠点
  cv_tkn_status               CONSTANT VARCHAR2(20)  := 'STATUS';                    -- 契約状況
  cv_tkn_date_from            CONSTANT VARCHAR2(20)  := 'DATE_FROM';                 -- 抽出対象日(FROM)
  cv_tkn_date_to              CONSTANT VARCHAR2(20)  := 'DATE_TO';                   -- 抽出対象日(TO)
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
  cv_tkn_val_process_date     CONSTANT VARCHAR2(50)  := '業務処理日付';
  cv_tkn_val_date_from        CONSTANT VARCHAR2(50)  := '抽出対象日（FROM）';
  cv_tkn_val_date_to          CONSTANT VARCHAR2(50)  := '抽出対象日（TO）';
--
  -- 参照タイプ名
  cv_lookup_type_01           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';     -- 業態小分類
  cv_lookup_type_02           CONSTANT VARCHAR2(30)  := 'XXCSO1_010A05_CSV_HEADER';  -- 契約書確定状況CSVヘッダ
  cv_lookup_type_03           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KOKYAKU_STATUS'; -- 顧客ステータス
  cv_lookup_type_04           CONSTANT VARCHAR2(30)  := 'XXCSO1_CONTRACT_STATUS';    -- 契約ステータス
  cv_lookup_type_05           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_STATUS_CD';       -- SP専決ステータス
--
  -- 値セット名
  cv_flex_value_01            CONSTANT VARCHAR2(30)  := 'XXCSO1_CONTRACT_STATUS';    -- 契約状況
--
  cv_flag_yes                 CONSTANT VARCHAR2(1)   := 'Y';                         -- 有効
  cv_language_ja              CONSTANT VARCHAR2(2)  := 'JA';                         -- 日本語
  -- パラメータ
  cv_para_status_1            CONSTANT VARCHAR2(1)   := '1';                         -- 未確定
  cv_para_status_2            CONSTANT VARCHAR2(1)   := '2';                         -- 確定済
  --
  cv_output_log               CONSTANT VARCHAR2(3)   := 'LOG';
  --
  -- 区分
  cv_rec_kbn_1                CONSTANT VARCHAR2(10)  := '新規';                      -- 区分：新規
  cv_rec_kbn_2                CONSTANT VARCHAR2(10)  := '条件変更';                  -- 区分：条件変更
  cv_rec_kbn_3                CONSTANT VARCHAR2(10)  := '確定済';                    -- 区分：確定済
  -- SP専決ヘッダテーブル
  cv_sp_dec_status_3          CONSTANT xxcso_sp_decision_headers.status%TYPE                   := '3';  -- SP専決承認済み
  -- SP専決顧客テーブル
  cv_sp_dec_cust_class_1      CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1';  -- 設置先顧客
  -- 契約管理テーブル
  cv_cooperate_flag_1         CONSTANT xxcso_contract_managements.cooperate_flag%TYPE          := '1';  -- 連携済み
  cv_cont_mng_status_0        CONSTANT xxcso_contract_managements.status%TYPE                  := '0';  -- 作成中
  cv_cont_mng_status_1        CONSTANT xxcso_contract_managements.status%TYPE                  := '1';  -- 確定済
  cv_cont_mng_status_9        CONSTANT xxcso_contract_managements.status%TYPE                  := '9';  -- 取消済
  -- 顧客追加情報
  cv_stop_app_reason_9        CONSTANT xxcmm_cust_accounts.stop_approval_reason%TYPE           := '9';  -- 中止理由(二重登録)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 契約データ格納用変数
  TYPE g_rec_contract_data IS RECORD
    (
      rec_kbn                 VARCHAR2(10)                                            -- 区分
    , cust_code               hz_cust_accounts.account_number%TYPE                    -- 顧客コード
    , cust_name               hz_parties.party_name%TYPE                              -- 顧客名
    , cust_status             VARCHAR2(2)                                             -- 顧客ステータス
    , cust_status_name        VARCHAR2(20)                                            -- 顧客ステータス名
    , gyotai_sho              VARCHAR2(2)                                             -- 業態小分類
    , gyotai_sho_name         fnd_lookup_values_vl.meaning%TYPE                       -- 業態小分類名
    , sale_base_code          xxcmm_cust_accounts.sale_base_code%TYPE                 -- 売上拠点
    , sale_base_name          xxcmn_locations_all.location_name%TYPE                  -- 売上拠点名
    , cnvs_biz_person         xxcmm_cust_accounts.cnvs_business_person%TYPE           -- 獲得者
    , cnvs_biz_person_name    VARCHAR2(100)                                           -- 獲得者名
    , cnvs_base_code          xxcmm_cust_accounts.cnvs_base_code%TYPE                 -- 獲得拠点
    , cnvs_base_name          xxcmn_locations_all.location_name%TYPE                  -- 獲得拠点名
    , contract_number         xxcso_contract_managements.contract_number%TYPE         -- 契約番号
    , contract_management_id  xxcso_contract_managements.contract_management_id%TYPE  -- 契約書ID
    , sp_dec_number           xxcso_sp_decision_headers.sp_decision_number%TYPE       -- SP専決書番号
    , sp_status               xxcso_sp_decision_headers.status%TYPE                   -- SP専決ステータス
    , sp_status_name          VARCHAR2(20)                                            -- SP専決ステータス名
    , cont_creation_date      VARCHAR2(30)                                            -- 契約書作成日
    , cont_last_update_date   VARCHAR2(30)                                            -- 契約書最終更新日
    , cont_status             xxcso_contract_managements.status%TYPE                  -- 契約書ステータス
    , cont_status_name        VARCHAR2(20)                                            -- 契約書ステータス名
    );
  TYPE g_tab_contract_data IS TABLE OF g_rec_contract_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_contract_data            g_tab_contract_data;                      -- 結合配列の定義
  gv_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;  -- 売上拠点
  gv_status                   VARCHAR2(10)   DEFAULT NULL;              -- 契約状況
  gd_date_from                DATE;                                     -- 抽出対象日(FROM)
  gd_date_to                  DATE;                                     -- 抽出対象日(TO)
  gd_process_date             DATE;                                     -- 業務日付
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 新規顧客契約書情報カーソル
  CURSOR get_contract_cur1
  IS
    --SP専決のみで契約なし(新規契約なし)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
           */
           cv_rec_kbn_1                        rec_kbn                                -- 区分
         , hca.account_number                  cust_code                              -- 顧客コード
         , hp.party_name                       cust_name                              -- 顧客名
         , hp.duns_number_c                    cust_status                            -- 顧客ステータス
         , custs.cust_status_name              cust_status_name                       -- 顧客ステータス名
         , xca.business_low_type               gyotai_sho                             -- 業態小分類
         , gyo.business_low_type_name          gyotai_sho_name                        -- 業態小分類名
         , xca.sale_base_code                  sale_base_code                         -- 売上拠点
         , xlv1.location_name                  sale_base_name                         -- 売上拠点名
         , xca.cnvs_business_person            cnvs_biz_person                        -- 獲得者
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- 獲得者名
         , xca.cnvs_base_code                  cnvs_base_code                         -- 獲得拠点
         , xlv2.location_name                  cnvs_base_name                         -- 獲得拠点名
         , NULL                                contract_number                        -- 契約書番号
         , NULL                                contract_management_id                 -- 契約書ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP専決書番号
         , xsdh.status                         sp_status                              -- SP専決ステータス
         , spsts.sp_status_name                sp_status_name                         -- SP専決ステータス名
         , NULL                                cont_creation_date                     -- 契約書作成日
         , NULL                                cont_last_update_date                  -- 契約書最終更新日
         , NULL                                cont_status                            -- 契約書ステータス
         , NULL                                cont_status_name                       -- 契約書ステータス名
    FROM   hz_cust_accounts           hca   -- 顧客マスタ
         , hz_parties                 hp    -- パーティマスタ
         , xxcmm_cust_accounts        xca   -- 顧客追加情報
         , xxcso_sp_decision_custs    xsdc  -- SP専決顧客テーブル
         , xxcso_sp_decision_headers  xsdh  -- SP専決ヘッダテーブル
         , xxcso_locations_v2         xlv1  -- 事業所マスタ(売上拠点)
         , xxcso_locations_v2         xlv2  -- 事業所マスタ(獲得拠点)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- 業態小分類(LOOKUP表)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- 顧客ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP専決ステータス(LOOKUP表)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- 獲得者情報
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- 初回取引日
    AND    (
             ( xca.stop_approval_reason    IS NULL )
             OR
             ( xca.stop_approval_reason    <> cv_stop_app_reason_9 )
           )                                                                      -- 中止理由:二重登録以外
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- 設置先顧客
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND    xsdh.status                     = cv_sp_dec_status_3                   -- SP専決承認済
    AND    xsdh.approval_complete_date    >= gd_date_from                         -- 承認完了日FROM
    AND    xsdh.approval_complete_date    <= NVL( gd_date_to , gd_process_date )  -- 承認完了日TO
    AND    NOT EXISTS (
             SELECT 1
             FROM   xxcso.xxcso_contract_managements xcm
             WHERE  xcm.install_account_id = xsdc.customer_id
           )                                                                      -- 同一顧客で過去に契約が未作成
    UNION ALL
    --確定していない契約で新規(新規契約あり)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
             INDEX(XCM1 XXCSO_CONTRACT_MANAGEMENTS_N01)
           */
           cv_rec_kbn_1                                       rec_kbn                 -- 区分
         , hca.account_number                                 cust_code               -- 顧客コード
         , hp.party_name                                      cust_name               -- 顧客名
         , hp.duns_number_c                                   cust_status             -- 顧客ステータス
         , custs.cust_status_name                             cust_status_name        -- 顧客ステータス名
         , xca.business_low_type                              gyotai_sho              -- 業態小分類
         , gyo.business_low_type_name                         gyotai_sho_name         -- 業態小分類名
         , xca.sale_base_code                                 sale_base_code          -- 売上拠点
         , xlv1.location_name                                 sale_base_name          -- 売上拠点名
         , xca.cnvs_business_person                           cnvs_biz_person         -- 獲得者
         , emp.cnvs_business_person_name                      cnvs_biz_person_name    -- 獲得者名
         , xca.cnvs_base_code                                 cnvs_base_code          -- 獲得拠点
         , xlv2.location_name                                 cnvs_base_name          -- 獲得拠点名
         , xcm1.contract_number                               contract_number         -- 契約書番号
         , xcm1.contract_management_id                        contract_management_id  -- 契約書ID
         , xsdh.sp_decision_number                            sp_dec_number           -- SP専決書番号
         , xsdh.status                                        sp_status               -- SP専決ステータス
         , spsts.sp_status_name                               sp_status_name          -- SP専決ステータス名
         , TO_CHAR( xcm1.creation_date    , cv_format_fmt2 )  cont_creation_date      -- 契約書作成日
         , TO_CHAR( xcm1.last_update_date , cv_format_fmt2 )  cont_last_update_date   -- 契約書最終更新日
         , xcm1.status                                        cont_status             -- 契約書ステータス
         , costs.cont_status_name                             cont_status_name        -- 契約書ステータス名
    FROM   hz_cust_accounts           hca   -- 顧客マスタ
         , hz_parties                 hp    -- パーティマスタ
         , xxcmm_cust_accounts        xca   -- 顧客追加情報
         , xxcso_sp_decision_custs    xsdc  -- SP専決顧客テーブル
         , xxcso_sp_decision_headers  xsdh  -- SP専決ヘッダテーブル
         , xxcso_contract_managements xcm1  -- 契約管理テーブル
         , xxcso_locations_v2         xlv1  -- 事業所マスタ(売上拠点)
         , xxcso_locations_v2         xlv2  -- 事業所マスタ(獲得拠点)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- 業態小分類(LOOKUP表)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- 顧客ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   cont_status
                  , flv.meaning       cont_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_04
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          costs -- 契約書ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP専決ステータス(LOOKUP表)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp  -- 獲得者情報
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xcm1.status                     = costs.cont_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- 初回取引日
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- 設置先顧客
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xsdh.sp_decision_header_id      = xcm1.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND      (
               ( xca.stop_approval_reason  IS NULL )
               OR
               ( xca.stop_approval_reason  <> cv_stop_app_reason_9 )
             )                                                                    -- 中止理由:二重登録以外
    AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                           FROM   xxcso_contract_managements xcm2
                                           WHERE  xcm2.install_account_id = xcm1.install_account_id
                                           AND    xcm2.status             = cv_cont_mng_status_0 -- 作成中
                                         )
    AND    NOT EXISTS (
             SELECT 1
             FROM   xxcso_contract_managements xcm3
             WHERE  xcm3.install_account_id = xcm1.install_account_id
             AND    xcm3.status             = cv_cont_mng_status_1            -- 確定済
             AND    xcm3.cooperate_flag     = cv_cooperate_flag_1             -- マスタ連携済
           )
    AND    TRUNC( xcm1.creation_date )    >= gd_date_from                         -- 契約作成日FROM
    AND    TRUNC( xcm1.creation_date )    <= NVL( gd_date_to , gd_process_date )  -- 契約作成日TO
    ORDER BY sp_dec_number   -- SP専決書番号
  ;
  -- 条件変更未確定契約書情報カーソル
  CURSOR get_contract_cur2
  IS
    --過去に確定済契約があり、該当のSP専決は確定しているが契約なし(条件変更契約なし)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
           */
           cv_rec_kbn_2                        rec_kbn                                -- 区分
         , hca.account_number                  cust_code                              -- 顧客コード
         , hp.party_name                       cust_name                              -- 顧客名
         , hp.duns_number_c                    cust_status                            -- 顧客ステータス
         , custs.cust_status_name              cust_status_name                       -- 顧客ステータス名
         , xca.business_low_type               gyotai_sho                             -- 業態小分類
         , gyo.business_low_type_name          gyotai_sho_name                        -- 業態小分類名
         , xca.sale_base_code                  sale_base_code                         -- 売上拠点
         , xlv1.location_name                  sale_base_name                         -- 売上拠点名
         , xca.cnvs_business_person            cnvs_biz_person                        -- 獲得者
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- 獲得者名
         , xca.cnvs_base_code                  cnvs_base_code                         -- 獲得拠点
         , xlv2.location_name                  cnvs_base_name                         -- 獲得拠点名
         , NULL                                contract_number                        -- 契約書番号
         , NULL                                contract_management_id                 -- 契約書ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP専決書番号
         , xsdh.status                         sp_status                              -- SP専決ステータス
         , spsts.sp_status_name                sp_status_name                         -- SP専決ステータス名
         , NULL                                cont_creation_date                     -- 契約書作成日
         , NULL                                cont_last_update_date                  -- 契約書最終更新日
         , NULL                                cont_status                            -- 契約書ステータス
         , NULL                                cont_status_name                       -- 契約書ステータス名
    FROM   hz_cust_accounts           hca   -- 顧客マスタ
         , hz_parties                 hp    -- パーティマスタ
         , xxcmm_cust_accounts        xca   -- 顧客追加情報
         , xxcso_sp_decision_custs    xsdc  -- SP専決顧客テーブル
         , xxcso_sp_decision_headers  xsdh  -- SP専決ヘッダテーブル
         , xxcso_locations_v2         xlv1  -- 事業所マスタ(売上拠点)
         , xxcso_locations_v2         xlv2  -- 事業所マスタ(獲得拠点)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- 業態小分類(LOOKUP表)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- 顧客ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP専決ステータス(LOOKUP表)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- 獲得者情報
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    (
             ( xca.stop_approval_reason    IS NULL )
             OR
             ( xca.stop_approval_reason    <> cv_stop_app_reason_9 )
           )                                                                      -- 中止理由:二重登録以外
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- 初回取引日
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- 設置先顧客
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND    xsdh.status                     = cv_sp_dec_status_3                   -- SP専決承認済
    AND    xsdh.approval_complete_date    >= gd_date_from                         -- 承認完了日FROM
    AND    xsdh.approval_complete_date    <= NVL( gd_date_to , gd_process_date )  -- 承認完了日TO
    AND    EXISTS (
             SELECT /*+
                      INDEX( XCM1 XXCSO_CONTRACT_MANAGEMENTS_N06 )
                    */
                    1
             FROM   xxcso_contract_managements xcm1
             WHERE  xcm1.install_account_id = xsdc.customer_id
             AND    xcm1.status                 = cv_cont_mng_status_1            -- 確定済
             AND    xcm1.cooperate_flag         = cv_cooperate_flag_1             -- マスタ連携済
             AND    ROWNUM                      = 1
           )                                                                      -- 同一顧客で過去に契約作成済
    AND    NOT EXISTS (
             SELECT 1
             FROM   xxcso_contract_managements xcm2
             WHERE  xcm2.sp_decision_header_id = xsdh.sp_decision_header_id
           )                                                                      -- 該当SPの契約未作成
    UNION ALL
    --最新契約が確定していない条件変更(条件変更契約あり)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
             INDEX(XCM1 XXCSO_CONTRACT_MANAGEMENTS_N01)
           */
           cv_rec_kbn_2                        rec_kbn                                -- 区分
         , xcm1.install_account_number         cust_code                              -- 顧客コード
         , xcm1.install_party_name             cust_name                              -- 顧客名
         , hp.duns_number_c                    cust_status                            -- 顧客ステータス
         , custs.cust_status_name              cust_status_name                       -- 顧客ステータス名
         , xca.business_low_type               gyotai_sho                             -- 業態小分類
         , gyo.business_low_type_name          gyotai_sho_name                        -- 業態小分類名
         , xca.sale_base_code                  sale_base_code                         -- 売上拠点
         , xlv1.location_name                  sale_base_name                         -- 売上拠点名
         , xca.cnvs_business_person            cnvs_biz_person                        -- 獲得者
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- 獲得者名
         , xca.cnvs_base_code                  cnvs_base_code                         -- 獲得拠点
         , xlv2.location_name                  cnvs_base_name                         -- 獲得拠点名
         , xcm1.contract_number                contract_number                        -- 契約書番号
         , xcm1.contract_management_id         contract_management_id                 -- 契約書ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP専決書番号
         , xsdh.status                         sp_status                              -- SP専決ステータス
         , spsts.sp_status_name                sp_status_name                         -- SP専決ステータス名
         , TO_CHAR( xcm1.creation_date    , cv_format_fmt2 )  cont_creation_date      -- 契約書作成日
         , TO_CHAR( xcm1.last_update_date , cv_format_fmt2 )  cont_last_update_date   -- 契約書最終更新日
         , xcm1.status                         cont_status                            -- 契約書ステータス
         , costs.cont_status_name              cont_status_name                       -- 契約書ステータス名
    FROM   hz_cust_accounts           hca   -- 顧客マスタ
         , hz_parties                 hp    -- パーティマスタ
         , xxcmm_cust_accounts        xca   -- 顧客追加情報
         , xxcso_sp_decision_custs    xsdc  -- SP専決顧客テーブル
         , xxcso_sp_decision_headers  xsdh  -- SP専決ヘッダテーブル
         , xxcso_contract_managements xcm1  -- 契約管理テーブル
         , xxcso_locations_v2         xlv1  -- 事業所マスタ(売上拠点)
         , xxcso_locations_v2         xlv2  -- 事業所マスタ(獲得拠点)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND   gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- 業態小分類(LOOKUP表)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- 顧客ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   cont_status
                  , flv.meaning       cont_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_04
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          costs -- 契約書ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP専決ステータス(LOOKUP表)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- 獲得者情報
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    (
             ( xca.stop_approval_reason IS NULL )
             OR
             ( xca.stop_approval_reason <> cv_stop_app_reason_9 )
           )                                                                      -- 中止理由:二重登録以外
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xcm1.status                     = costs.cont_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- 初回取引日
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- 設置先顧客
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xsdh.sp_decision_header_id      = xcm1.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code 
    AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                           FROM   xxcso_contract_managements xcm2
                                           WHERE  xcm2.install_account_id = xcm1.install_account_id
                                           AND    xcm2.status             = cv_cont_mng_status_0 -- 作成中
                                         )                                        -- 最新の契約が未確定
    AND    EXISTS (
             SELECT 1
             FROM   xxcso_contract_managements xcm3
             WHERE  xcm3.install_account_id = xcm1.install_account_id
             AND    xcm3.status             = cv_cont_mng_status_1            -- 確定済
             AND    xcm3.cooperate_flag     = cv_cooperate_flag_1             -- マスタ連携済
           )                                                                      -- 過去に確定済みの契約あり
    AND    TRUNC( xcm1.creation_date )    >= gd_date_from                         -- 契約作成日FROM
    AND    TRUNC( xcm1.creation_date )    <= NVL( gd_date_to , gd_process_date )  -- 契約作成日TO
    ORDER BY sp_dec_number   -- SP専決書番号
  ;
  -- 確定済み契約書情報カーソル
  CURSOR get_contract_cur3
  IS
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
             INDEX(XCM1 XXCSO_CONTRACT_MANAGEMENTS_N01)
           */
           cv_rec_kbn_3                        rec_kbn                                -- 区分
         , xcm1.install_account_number         cust_code                              -- 顧客コード
         , xcm1.install_party_name             cust_name                              -- 顧客名
         , hp.duns_number_c                    cust_status                            -- 顧客ステータス
         , custs.cust_status_name              cust_status_name                       -- 顧客ステータス名
         , xca.business_low_type               gyotai_sho                             -- 業態小分類
         , gyo.business_low_type_name          gyotai_sho_name                        -- 業態小分類名
         , xca.sale_base_code                  sale_base_code                         -- 売上拠点
         , xlv1.location_name                  sale_base_name                         -- 売上拠点名
         , xca.cnvs_business_person            cnvs_biz_person                        -- 獲得者
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- 獲得者名
         , xca.cnvs_base_code                  cnvs_base_code                         -- 獲得拠点
         , xlv2.location_name                  cnvs_base_name                         -- 獲得拠点名
         , xcm1.contract_number                contract_number                        -- 契約書番号
         , xcm1.contract_management_id         contract_management_id                 -- 契約書ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP専決書番号
         , xsdh.status                         sp_status                              -- SP専決ステータス
         , spsts.sp_status_name                sp_status_name                         -- SP専決ステータス名
         , TO_CHAR( xcm1.creation_date    , cv_format_fmt2 )  cont_creation_date      -- 契約書作成日
         , TO_CHAR( xcm1.last_update_date , cv_format_fmt2 )  cont_last_update_date   -- 契約書最終更新日
         , xcm1.status                         cont_status                            -- 契約書ステータス
         , costs.cont_status_name              cont_status_name                       -- 契約書ステータス名
    FROM   hz_cust_accounts           hca   -- 顧客マスタ
         , hz_parties                 hp    -- パーティマスタ
         , xxcmm_cust_accounts        xca   -- 顧客追加情報
         , xxcso_sp_decision_custs    xsdc  -- SP専決顧客テーブル
         , xxcso_sp_decision_headers  xsdh  -- SP専決ヘッダテーブル
         , xxcso_contract_managements xcm1  -- 契約管理テーブル
         , xxcso_locations_v2         xlv1  -- 事業所マスタ(売上拠点)
         , xxcso_locations_v2         xlv2  -- 事業所マスタ(獲得拠点)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- 業態小分類(LOOKUP表)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- 顧客ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   cont_status
                  , flv.meaning       cont_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_04
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          costs -- 契約書ステータス(LOOKUP表)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP専決ステータス(LOOKUP表)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- 獲得者情報
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    (
             ( xca.stop_approval_reason IS NULL )
             OR
             ( xca.stop_approval_reason <> cv_stop_app_reason_9 )
           )                                                                      -- 中止理由:二重登録以外
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xcm1.status                     = costs.cont_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- 初回取引日
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- 設置先顧客
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xsdh.sp_decision_header_id      = xcm1.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code 
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                           FROM   xxcso_contract_managements xcm2
                                           WHERE  xcm2.install_account_id = xcm1.install_account_id
                                           AND    xcm2.status             = cv_cont_mng_status_1      -- 確定済
                                           AND    xcm2.cooperate_flag     = cv_cooperate_flag_1       -- マスタ連携済
                                         )                                        -- 最新が確定済の契約
    AND    TRUNC( xcm1.creation_date )    >= gd_date_from                         -- 契約作成日FROM
    AND    TRUNC( xcm1.creation_date )    <= NVL( gd_date_to , gd_process_date )  -- 契約作成日TO
    ORDER BY sp_dec_number   -- SP専決書番号
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code  IN  VARCHAR2      --   売上拠点
   ,iv_status     IN  VARCHAR2      --   契約状況
   ,iv_date_from  IN  VARCHAR2      --   抽出対象日(FROM)
   ,iv_date_to    IN  VARCHAR2      --   抽出対象日(TO)
   ,ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_base_code              VARCHAR2(1000);  -- 売上拠点出力用
    lv_status                 VARCHAR2(1000);  -- 契約状況出力用
    lv_date_from              VARCHAR2(1000);  -- 抽出対象日(FROM)出力用
    lv_date_to                VARCHAR2(1000);  -- 抽出対象日(TO)出力用
    lv_csv_header             VARCHAR2(5000);  -- CSVヘッダ項目出力用
--
    lv_status_name            VARCHAR2(30);    -- 契約状況ステータス名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --入力パラメータをグローバル変数に格納
    --==============================================================
    gv_base_code   := iv_base_code;
    gv_status      := iv_status;
    gd_date_from   := TO_DATE( iv_date_from , cv_format_fmt1 );
    gd_date_to     := TO_DATE( iv_date_to   , cv_format_fmt1 );
--
    --==============================================================
    --入力パラメータをメッセージ出力
    --==============================================================
    -- 契約状況の名称を取得
    BEGIN
      SELECT ffvt.description     status_name  -- 契約状況名
      INTO   lv_status_name
      FROM   fnd_flex_values      ffv
           , fnd_flex_values_tl   ffvt
           , fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffvt.language            = cv_language_ja
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_flex_value_01
      AND    ffv.flex_value           = gv_status
      AND    ffv.enabled_flag         = cv_flag_yes
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_status_name := NULL;
    END;
--
    -- 売上拠点
    lv_base_code   := xxccp_common_pkg.get_msg(                          -- アップロード名称の出力
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00640              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_base_code              -- トークンコード1
                       ,iv_token_value1 => iv_base_code                  -- トークン値1
                      );
    -- 契約状況
    lv_status      := xxccp_common_pkg.get_msg(                          -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00641              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_status                 -- トークンコード1
                       ,iv_token_value1 => lv_status_name                -- トークン値1
                      );
    -- 抽出対象日(FROM)
    lv_date_from   := xxccp_common_pkg.get_msg(                          -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00642              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_date_from              -- トークンコード1
                       ,iv_token_value1 => iv_date_from                  -- トークン値1
                      );
    -- 抽出対象日(TO)
    lv_date_to     := xxccp_common_pkg.get_msg(                          -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcso             -- アプリケーション短縮名
                      ,iv_name         => cv_msg_cso_00643               -- メッセージコード
                      ,iv_token_name1  => cv_tkn_date_to                 -- トークンコード1
                      ,iv_token_value1 => iv_date_to                     -- トークン値1
                      );
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''           || CHR(10) ||
                 lv_base_code || CHR(10) ||      -- 売上拠点
                 lv_status    || CHR(10) ||      -- 契約状況
                 lv_date_from || CHR(10) ||      -- 抽出対象日(FROM)
                 lv_date_to   || CHR(10)         -- 抽出対象日(TO)
    );
--
    --==================================================
    -- 業務日付取得
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date ;
    -- 業務日付の取得に失敗した場合はエラー
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00011
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 抽出対象日(FROM)の指定チェック
    --==================================================
    -- 抽出対象日(TO)と業務日付の比較
    IF ( gd_date_from > gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00644
         ,iv_token_name1  => cv_tkn_date_from
         ,iv_token_value1 => cv_tkn_val_date_from
         ,iv_token_name2  => cv_tkn_date_to
         ,iv_token_value2 => cv_tkn_val_process_date
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 抽出対象日(TO)の指定チェック
    --==================================================
    -- 抽出対象日(TO)が指定されていた場合にチェックする
    IF  ( gd_date_to IS NOT NULL ) THEN
      -- 抽出対象日(FROM)と抽出対象日(TO)の比較
      IF ( gd_date_from > gd_date_to ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00644
         ,iv_token_name1  => cv_tkn_date_from
         ,iv_token_value1 => cv_tkn_val_date_from
         ,iv_token_name2  => cv_tkn_date_to
         ,iv_token_value2 => cv_tkn_val_date_to
        );
        lv_errbuf  := lv_errmsg;
        RAISE init_err_expt;
      END IF;
    END IF;
--
    --==================================================
    -- CSVヘッダ項目出力
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso
                    ,iv_name         => cv_msg_cso_00645
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_output_str   VARCHAR2(5000)  := NULL;  -- 出力文字列格納用変数
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_data_expt  EXCEPTION;
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
    -- CSV形式のデータ出力
    -- ===============================
    FOR i IN 1..gt_contract_data.COUNT LOOP
      lv_output_str :=                              cv_dqu || gt_contract_data( i ).rec_kbn                 || cv_dqu ;  -- 区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sp_dec_number           || cv_dqu ;  -- SP専決書番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sp_status               || cv_dqu ;  -- SP専決ステータス
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sp_status_name          || cv_dqu ;  -- SP専決ステータス名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_code               || cv_dqu ;  -- 顧客コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_name               || cv_dqu ;  -- 顧客名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_status             || cv_dqu ;  -- 顧客ステータス
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_status_name        || cv_dqu ;  -- 顧客ステータス名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).gyotai_sho              || cv_dqu ;  -- 業態小分類
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).gyotai_sho_name         || cv_dqu ;  -- 業態小分類名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sale_base_code          || cv_dqu ;  -- 売上拠点
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sale_base_name          || cv_dqu ;  -- 売上拠点名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_biz_person         || cv_dqu ;  -- 獲得者
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_biz_person_name    || cv_dqu ;  -- 獲得者名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_base_code          || cv_dqu ;  -- 獲得拠点
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_base_name          || cv_dqu ;  -- 獲得拠点名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).contract_number         || cv_dqu ;  -- 契約書番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).contract_management_id  || cv_dqu ;  -- 契約書ID
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_creation_date      || cv_dqu ;  -- 契約書作成日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_last_update_date   || cv_dqu ;  -- 契約書最終更新日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_status             || cv_dqu ;  -- 契約書ステータス
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_status_name        || cv_dqu ;  -- 契約書ステータス名
--
      -- 作成したCSVデータを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_output_str
      );
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data1
   * Description      : 契約書情報【新規】の取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_contract_data1(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data1'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
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
      -- 初期化
      gt_contract_data.DELETE;
      --
      -- ===============================
      -- 契約書情報【新規】の取得
      -- ===============================
      -- カーソルOPEN
      OPEN  get_contract_cur1;
      -- バルクフェッチ
      FETCH get_contract_cur1 BULK COLLECT INTO gt_contract_data;
      -- カーソルCLOSE
      CLOSE get_contract_cur1;
      -- 件数カウント
      gn_target_cnt := gn_target_cnt + gt_contract_data.COUNT;
--
      -- ===============================
      -- CSVファイル出力(A-5)
      -- ===============================
      output_csv(
        ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE
        IF ( get_contract_cur1%ISOPEN ) THEN
          CLOSE get_contract_cur1;
          RAISE global_process_expt;
        END IF;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_contract_data1;


--
  /**********************************************************************************
   * Procedure Name   : get_contract_data2
   * Description      : 契約書情報【条件変更】の取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_contract_data2(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data2'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
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
      -- 初期化
      gt_contract_data.DELETE;
      --
      -- ===============================
      -- 契約書情報【条件変更】の取得
      -- ===============================
      -- カーソルOPEN
      OPEN  get_contract_cur2;
      -- バルクフェッチ
      FETCH get_contract_cur2 BULK COLLECT INTO gt_contract_data;
      -- カーソルCLOSE
      CLOSE get_contract_cur2;
      -- 件数カウント
      gn_target_cnt := gn_target_cnt + gt_contract_data.COUNT;
--
      -- ===============================
      -- CSVファイル出力(A-5)
      -- ===============================
      output_csv(
        ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE
        IF ( get_contract_cur2%ISOPEN ) THEN
          CLOSE get_contract_cur2;
          RAISE global_process_expt;
        END IF;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_contract_data2;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data3
   * Description      : 契約書情報【確定済】の取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_data3(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data3'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
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
      -- 初期化
      gt_contract_data.DELETE;
      --
      -- ===============================
      -- 契約書情報【確定済】の取得
      -- ===============================
      -- カーソルOPEN
      OPEN  get_contract_cur3;
      -- バルクフェッチ
      FETCH get_contract_cur3 BULK COLLECT INTO gt_contract_data;
      -- カーソルCLOSE
      CLOSE get_contract_cur3;
      -- 件数カウント
      gn_target_cnt := gn_target_cnt + gt_contract_data.COUNT;
--
      -- ===============================
      -- CSVファイル出力(A-5)
      -- ===============================
      output_csv(
        ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE
        IF ( get_contract_cur3%ISOPEN ) THEN
          CLOSE get_contract_cur3;
          RAISE global_process_expt;
        END IF;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_contract_data3;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2     -- 売上拠点
   ,iv_status          IN  VARCHAR2     -- 契約状況
   ,iv_date_from       IN  VARCHAR2     -- 抽出対象日（FROM）
   ,iv_date_to         IN  VARCHAR2     -- 抽出対象日（TO）
   ,ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_base_code       => iv_base_code     -- 売上拠点
     ,iv_status          => iv_status        -- 契約状況
     ,iv_date_from       => iv_date_from     -- 対象期間FROM
     ,iv_date_to         => iv_date_to       -- 対象期間TO
     ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 入力パラメータ.契約状況が「未確定」の場合
    -- ===============================
    IF ( gv_status = cv_para_status_1 ) THEN
      -- ===============================
      -- 契約書情報【新規】の取得(A-2)、CSVファイル出力(A-5)
      -- ===============================
      get_contract_data1(
        ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 契約書情報【条件変更】の取得(A-3)、CSVファイル出力(A-5)
      -- ===============================
      get_contract_data2(
        ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ===============================
    -- 入力パラメータ.契約状況が「確定済」の場合
    -- ===============================
    ELSIF ( gv_status = cv_para_status_2 ) THEN
      -- ===============================
      -- 契約書情報【確定済】の取得(A-4)、CSVファイル出力(A-5)
      -- ===============================
      get_contract_data3(
        ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
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
    errbuf             OUT VARCHAR2     -- エラー・メッセージ  --# 固定 #
   ,retcode            OUT VARCHAR2     -- リターン・コード    --# 固定 #
   ,iv_base_code       IN  VARCHAR2     -- 売上拠点
   ,iv_status          IN  VARCHAR2     -- 契約状況
   ,iv_date_from       IN  VARCHAR2     -- 抽出対象日（FROM）
   ,iv_date_to         IN  VARCHAR2     -- 抽出対象日（TO）
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
       iv_which   => cv_output_log
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
       iv_base_code    => iv_base_code   -- 売上拠点
      ,iv_status       => iv_status      -- 契約状況
      ,iv_date_from    => iv_date_from   -- 抽出対象日(FROM)
      ,iv_date_to      => iv_date_to     -- 抽出対象日(TO)
      ,ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCSO010A05C;
/
