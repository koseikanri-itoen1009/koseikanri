CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS009A07C (body)
 * Description      : 受注一覧ファイル出力
 * MD.050           : 受注一覧ファイル出力 MD050_COS_009_A07
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_parameter        パラメータチェック(A-2)
 *  get_data               対象データ取得(A-3)
 *  output_data            データ出力(A-4)
 *  update_order_line_data 受注明細出力済み更新（EDI取込のみ）(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/06/23    1.0   S.Miyakoshi      新規作成
 *  2010/08/03    1.1   K.Kiriu          [E_本稼動_04125]出力項目の変更
 *  2011/02/04    1.2   OuKou            [E_本稼動_04871]出力項目の追加
 *  2012/09/28    1.3   M.Takasaki       [E_本稼動_10114]パフォーマンス改善
 *  2018/08/02    1.4   N.Koyama         [E_本稼動_15195]受注一覧ファイル出力（EDI用）新規にチェーン店コードで抽出できるようにする
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id;   --PER_BUSINESS_GROUP_ID
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 受注ソース種別取得例外 ***
  global_order_source_get_expt      EXCEPTION;
  --*** 書式チェック例外 ***
  global_format_chk_expt            EXCEPTION;
  --*** 処理対象データ更新例外 ***
  global_data_update_expt           EXCEPTION;
  --*** 対象データロック例外 ***
  global_data_lock_expt             EXCEPTION;
  --*** EDI帳票日付指定なし例外 ***
  global_edi_date_chk_expt          EXCEPTION;
  --*** 受信日 日付逆転チェック例外 ***
  global_date_rever_ocd_chk_expt    EXCEPTION;
  --*** 納品日 日付逆転チェック例外 ***
  global_date_rever_odh_chk_expt    EXCEPTION;
  --*** 対象0件例外 ***
  global_no_data_expt               EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOS009A07C';        -- パッケージ名
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- 販物領域短縮アプリ名
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- 共通領域短縮アプリ名
  --メッセージ
  cv_str_profile_nm              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00047';    -- MO:営業単位
  cv_msg_format_check_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- 日付書式チェックエラーメッセージ
  cv_msg_date_rever_err          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- 日付逆転エラーメッセージ
  cv_msg_update_err              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00011';    -- データ更新エラーメッセージ
  cv_msg_lock_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ロック取得エラーメッセージ
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00003';    -- 対象データなしメッセージ
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
  cv_msg_order_source            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14103';    -- 受注ソース取得エラーメッセージ
  cv_msg_parameter1              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14104';    -- パラメータ出力メッセージ(EDI用)（新規）
  cv_msg_parameter2              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14105';    -- パラメータ出力メッセージ(EDI用)（再出力）
  cv_msg_edi_date_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14110';    -- EDI日付指定なしエラー
  --トークン名
  cv_tkn_nm_para_date            CONSTANT  VARCHAR2(100) :=  'PARA_DATE';                     --受注日(FROM)または受注日(TO)
  cv_tkn_nm_order_source         CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_ID';               --受注ソース
  cv_tkn_nm_base_code            CONSTANT  VARCHAR2(100) :=  'DELIVERY_BASE_CODE';            --納品拠点コード
  cv_tkn_nm_date_from            CONSTANT  VARCHAR2(100) :=  'DATE_FROM';                     --(FROM)
  cv_tkn_nm_date_to              CONSTANT  VARCHAR2(100) :=  'DATE_TO';                       --(TO)
  cv_tkn_nm_s_ordered_date_f_t   CONSTANT  VARCHAR2(100) :=  'SCHEDULE_ORDERED_DATE_FROM_TO'; --納品予定日(FROM),(TO)
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';                    --テーブル名称
  cv_tkn_nm_table_lock           CONSTANT  VARCHAR2(100) :=  'TABLE';                         --テーブル名称(ロックエラー時用)
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';                      --キーデータ
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';                       --プロファイル名(販売領域)
  cv_tkn_nm_rep_out_type         CONSTANT  VARCHAR2(100) :=  'REPORT_OUTPUT_TYPE';            --帳票出力区分
  cv_tkn_nm_chain_code           CONSTANT  VARCHAR2(100) :=  'CHAIN_CODE';                    --チェーン店コード
  cv_tkn_nm_order_c_date_f_t     CONSTANT  VARCHAR2(100) :=  'ORDER_CREATION_DATE_FROM_TO';   --受信日(FROM),(TO)
  cv_tkn_nm_order_source_name    CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_NAME';             --受注ソース名
  --トークン値
  cv_msg_vl_table_ooha           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14101';    --受注テーブル
  cv_msg_vl_table_oola           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14102';    --受注明細テーブル
  cv_msg_vl_min_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN日付
  cv_msg_vl_max_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX日付
  cv_msg_vl_order_c_date_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14106';    --受信日(FROM)
  cv_msg_vl_order_c_date_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14107';    --受信日(TO)
  cv_msg_vl_order_date_h_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14108';    --納品日(FROM)
  cv_msg_vl_order_date_h_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14109';    --納品日(TO)
  cv_msg_vl_order_source_edi     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14111';    --EDI取込
  cv_msg_flag_out                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14112';    --EDI納品予定送信済フラグ名称（対象外）
  --受注明細ステータス
  ct_ln_status_cancelled         CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --取消
  --日付フォーマット
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD型
  cv_yyyy_mm                     CONSTANT  VARCHAR2(100) :=  'YYYY/MM';               --YYYY/MM型
  cv_yyyymmddhhmiss              CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD HH24:MI:SS'; --YYYYMMDDHHMISS型
  cv_hhmiss                      CONSTANT  VARCHAR2(100) :=  'HH24:MI:SS';            --HHMISS型
  --クイックコード参照用
  --使用可能フラグ定数
  ct_enabled_flg_y               CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                         :=  'Y';                             --使用可能
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );               --言語
  cv_type_ost                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_TYPE';           --受注ソース種別
  cv_type_esf                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_EDI_SEND_FLAG';          --EDI送信フラグ
  cv_type_ecl                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_EDI_CONTROL_LIST';       --EDI制御情報
  cv_type_head                   CONSTANT  VARCHAR2(100) :=  'XXCOS1_EXCEL_OUTPUT_HEAD';      --エクセル出力用見出し
  cv_code_ost_009_a07            CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A07%';                --受注ソースのクイックコード
  cv_code_eoh_009a07             CONSTANT  VARCHAR2(100) :=  '009A07%';                       --エクセル出力用見出しのクイックコード
  cv_diff_y                      CONSTANT  VARCHAR2(100) :=  'Y';                             --Y
  --プロファイル関連
  cv_prof_min_date               CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';               -- プロファイル名(MIN日付)
  cv_prof_max_date               CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';               -- プロファイル名(MAX日付)
  --MO:営業単位
  ct_prof_org_id                 CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
  --情報区分
  cv_target_order_01             CONSTANT  VARCHAR2(100) :=  '01';      -- 受注作成対象01
  --出力区分
  cv_output_type_new             CONSTANT  VARCHAR2(1)   :=  '1';       -- 新規出力
  --クイックコード：EDI制御情報の抽出条件
  cv_order_schedule              CONSTANT  VARCHAR2(2)   :=  '21';      -- 納品予定
  --受注カテゴリ
  cv_occ_mixed                   CONSTANT  VARCHAR2(10)  :=  'MIXED';   -- MIXED
  cv_occ_order                   CONSTANT  VARCHAR2(10)  :=  'ORDER';   -- ORDER
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --見出し
  TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
  --受注明細テーブル更新用ROWID型
  TYPE g_lines_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_oola_rowid_tab           g_lines_rowid_ttype;                               --明細ROWID
  gd_proc_date                DATE;                                              --業務日付
  gd_min_date                 DATE;                                              --MIN日付
  gd_max_date                 DATE;                                              --MAX日付
  gn_org_id                   NUMBER;                                            --営業単位
  gv_order_source_edi_chk     oe_order_sources.name%TYPE;                        --受注ソース（EDI取込）
  gv_msg_flag_out             VARCHAR2(10);                                      --EDI納品予定送信済フラグ：対象外
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 受注ソースタイプ：EDI取込の場合
  CURSOR data_edi_cur(
           icp_order_source             VARCHAR2, -- 受注ソース
           icp_delivery_base_code       VARCHAR2, -- 納品拠点コード
           icp_output_type              VARCHAR2, -- 出力区分
           icp_chain_code               VARCHAR2, -- チェーン店コード
           icp_order_creation_date_from DATE,     -- 受信日(FROM)
           icp_order_creation_date_to   DATE,     -- 受信日(TO)
           icp_ordered_date_h_from      DATE,     -- 納品日(FROM)
           icp_ordered_date_h_to        DATE)     -- 納品日(TO)
  IS
    SELECT
      /*+
-- MOD DATE:2012/09/28 AUTHOR:M.Takasaki VER：1.3 CONTENT:E_本稼動_10114 START
--         LEADING(xca)
--         INDEX(xca XXCMM_CUST_ACCOUNTS_N21)
--         INDEX(ooha OE_ORDER_HEADERS_N2)
--         USE_NL(ecl)
         LEADING(xca xeh ooha)
         INDEX(xca XXCMM_CUST_ACCOUNTS_N21)
         INDEX(xeh XXCOS_EDI_HEADERS_N09)
         INDEX(ooha OE_ORDER_HEADERS_N7)
-- MOD DATE:2012/09/28 AUTHOR:M.Takasaki VER：1.3 CONTENT:E_本稼動_10114 END
      */
       xeh.medium_class                      AS medium_class                 -- 媒体区分
      ,xeh.data_type_code                    AS data_type_code               -- データ種コード
      ,xeh.file_no                           AS file_no                      -- ファイルＮｏ
      ,xeh.info_class                        AS info_class                   -- 情報区分
      ,TO_CHAR(xeh.process_date, cv_yyyy_mm_dd)
                                             AS process_date                 -- 処理日
      ,xeh.process_time                      AS process_time                 -- 処理時刻
      ,xeh.base_code                         AS base_code                    -- 拠点（部門）コード
      ,xeh.base_name                         AS base_name                    -- 拠点名（正式名）
      ,xeh.edi_chain_code                    AS edi_chain_code               -- ＥＤＩチェーン店コード
      ,xeh.edi_chain_name                    AS edi_chain_name               -- ＥＤＩチェーン店名（漢字）
      ,xeh.chain_code                        AS chain_code                   -- チェーン店コード
      ,xeh.chain_name                        AS chain_name                   -- チェーン店名（漢字）
      ,xeh.report_code                       AS report_code                  -- 帳票コード
      ,xeh.report_show_name                  AS report_show_name             -- 帳票表示名
      ,xeh.customer_code                     AS customer_code                -- 顧客コード
      ,xeh.customer_name                     AS customer_name                -- 顧客名（漢字）
      ,xeh.company_code                      AS company_code                 -- 社コード
      ,xeh.company_name                      AS company_name                 -- 社名（漢字）
      ,xeh.company_name_alt                  AS company_name_alt             -- 社名（カナ）
      ,xeh.shop_code                         AS shop_code                    -- 店コード
      ,xeh.shop_name                         AS shop_name                    -- 店名（漢字）
      ,xeh.shop_name_alt                     AS shop_name_alt                -- 店名（カナ）
/* 2010/08/03 Ver1.1 Mod Start */
--      ,xeh.delivery_center_code              AS delivery_center_code         -- 納入センターコード
--      ,xeh.delivery_center_name              AS delivery_center_name         -- 納入センター名（漢字）
      ,NVL( xeh.delivery_center_code, xca.deli_center_code )
                                             AS delivery_center_code         -- 納入センターコード
      ,NVL( xeh.delivery_center_name, xca.deli_center_name )
                                             AS delivery_center_name         -- 納入センター名（漢字）
/* 2010/08/03 Ver1.1 Mod End   */
      ,xeh.delivery_center_name_alt          AS delivery_center_name_alt     -- 納入センター名（カナ）
      ,TO_CHAR(xeh.order_date, cv_yyyy_mm_dd)
                                             AS order_date                   -- 発注日
      ,TO_CHAR(xeh.center_delivery_date, cv_yyyy_mm_dd)
                                             AS center_delivery_date         -- センター納品日
      ,TO_CHAR(xeh.result_delivery_date, cv_yyyy_mm_dd)
                                             AS result_delivery_date         -- 実納品日
      ,TO_CHAR(xeh.shop_delivery_date, cv_yyyy_mm_dd)
                                             AS shop_delivery_date           -- 店舗納品日
      ,xeh.invoice_class                     AS invoice_class                -- 伝票区分
      ,xeh.small_classification_code         AS small_classification_code    -- 小分類コード
      ,xeh.small_classification_name         AS small_classification_name    -- 小分類名
      ,xeh.middle_classification_code        AS middle_classification_code   -- 中分類コード
      ,xeh.middle_classification_name        AS middle_classification_name   -- 中分類名
      ,xeh.big_classification_code           AS big_classification_code      -- 大分類コード
      ,xeh.big_classification_name           AS big_classification_name      -- 大分類名
      ,xeh.other_party_department_code       AS other_party_department_code  -- 相手先部門コード
      ,xeh.other_party_order_number          AS other_party_order_number     -- 相手先発注番号
      ,xeh.invoice_number                    AS invoice_number               -- 伝票番号
      ,xeh.check_digit                       AS check_digit                  -- チェックデジット
      ,xeh.order_no_ebs                      AS order_no_ebs                 -- 受注Ｎｏ（ＥＢＳ）
      ,xeh.ar_sale_class                     AS ar_sale_class                -- 特売区分
      ,xeh.delivery_classe                   AS delivery_classe              -- 配送区分
      ,xeh.opportunity_no                    AS opportunity_no               -- 便Ｎｏ
/* 2010/08/03 Ver1.1 Mod Start */
--      ,xeh.area_code                         AS area_code                    -- 地区コード
--      ,xeh.area_name                         AS area_name                    -- 地区名（漢字）
--      ,xeh.area_name_alt                     AS area_name_alt                -- 地区名（カナ）
      ,NVL( xeh.area_code, xca.edi_district_code )
                                             AS area_code                    -- 地区コード
      ,NVL( xeh.area_name, xca.edi_district_name )
                                             AS area_name                    -- 地区名（漢字）
      ,NVL( xeh.area_name_alt, xca.edi_district_kana )
                                             AS area_name_alt                -- 地区名（カナ）
/* 2010/08/03 Ver1.1 Mod End   */
      ,xeh.vendor_code                       AS vendor_code                  -- 取引先コード
      ,xeh.vendor_name                       AS vendor_name                  -- 取引先名（漢字）
      ,xeh.vendor_name1_alt                  AS vendor_name1_alt             -- 取引先名１（カナ）
      ,xeh.vendor_name2_alt                  AS vendor_name2_alt             -- 取引先名２（カナ）
      ,xeh.vendor_tel                        AS vendor_tel                   -- 取引先ＴＥＬ
      ,xeh.vendor_charge                     AS vendor_charge                -- 取引先担当者
      ,xeh.vendor_address                    AS vendor_address               -- 取引先住所（漢字）
      ,xeh.sub_distribution_center_code      AS sub_distribution_center_code -- サブ物流センターコード
      ,xeh.sub_distribution_center_name      AS sub_distribution_center_name -- サブ物流センターコード名
      ,xeh.eos_handwriting_class             AS eos_handwriting_class        -- ＥＯＳ・手書区分
      ,xeh.a1_column                         AS a1_column                    -- Ａ−１欄
      ,xeh.b1_column                         AS b1_column                    -- Ｂ−１欄
      ,xeh.c1_column                         AS c1_column                    -- Ｃ−１欄
      ,xeh.d1_column                         AS d1_column                    -- Ｄ−１欄
      ,xeh.e1_column                         AS e1_column                    -- Ｅ−１欄
      ,xeh.a2_column                         AS a2_column                    -- Ａ−２欄
      ,xeh.b2_column                         AS b2_column                    -- Ｂ−２欄
      ,xeh.c2_column                         AS c2_column                    -- Ｃ−２欄
      ,xeh.d2_column                         AS d2_column                    -- Ｄ−２欄
      ,xeh.e2_column                         AS e2_column                    -- Ｅ−２欄
      ,xeh.a3_column                         AS a3_column                    -- Ａ−３欄
      ,xeh.b3_column                         AS b3_column                    -- Ｂ−３欄
      ,xeh.c3_column                         AS c3_column                    -- Ｃ−３欄
      ,xeh.d3_column                         AS d3_column                    -- Ｄ−３欄
      ,xeh.e3_column                         AS e3_column                    -- Ｅ−３欄
      ,xeh.f1_column                         AS f1_column                    -- Ｆ−１欄
      ,xeh.g1_column                         AS g1_column                    -- Ｇ−１欄
      ,xeh.h1_column                         AS h1_column                    -- Ｈ−１欄
      ,xeh.i1_column                         AS i1_column                    -- Ｉ−１欄
      ,xeh.j1_column                         AS j1_column                    -- Ｊ−１欄
      ,xeh.k1_column                         AS k1_column                    -- Ｋ−１欄
      ,xeh.l1_column                         AS l1_column                    -- Ｌ−１欄
      ,xeh.f2_column                         AS f2_column                    -- Ｆ−２欄
      ,xeh.g2_column                         AS g2_column                    -- Ｇ−２欄
      ,xeh.h2_column                         AS h2_column                    -- Ｈ−２欄
      ,xeh.i2_column                         AS i2_column                    -- Ｉ−２欄
      ,xeh.j2_column                         AS j2_column                    -- Ｊ−２欄
      ,xeh.k2_column                         AS k2_column                    -- Ｋ−２欄
      ,xeh.l2_column                         AS l2_column                    -- Ｌ−２欄
      ,xeh.f3_column                         AS f3_column                    -- Ｆ−３欄
      ,xeh.g3_column                         AS g3_column                    -- Ｇ−３欄
      ,xeh.h3_column                         AS h3_column                    -- Ｈ−３欄
      ,xeh.i3_column                         AS i3_column                    -- Ｉ−３欄
      ,xeh.j3_column                         AS j3_column                    -- Ｊ−３欄
      ,xeh.k3_column                         AS k3_column                    -- Ｋ−３欄
      ,xeh.l3_column                         AS l3_column                    -- Ｌ−３欄
      ,xeh.chain_peculiar_area_header        AS chain_peculiar_area_header   -- チェーン店固有エリア（ヘッダー）
      ,xel.line_no                           AS line_no                      -- 行Ｎｏ
      ,xel.stockout_class                    AS stockout_class               -- 欠品区分
      ,xel.stockout_reason                   AS stockout_reason              -- 欠品理由
      ,xel.product_code_itouen               AS product_code_itouen          -- 商品コード（伊藤園）
      ,xel.product_code1                     AS product_code1                -- 商品コード１
      ,xel.product_code2                     AS product_code2                -- 商品コード２
      ,xel.jan_code                          AS jan_code                     -- ＪＡＮコード
      ,xel.itf_code                          AS itf_code                     -- ＩＴＦコード
      ,xel.extension_itf_code                AS extension_itf_code           -- 内箱ＩＴＦコード
      ,xel.case_product_code                 AS case_product_code            -- ケース商品コード
      ,xel.ball_product_code                 AS ball_product_code            -- ボール商品コード
      ,xel.prod_class                        AS prod_class                   -- 商品区分
      ,xel.product_name                      AS product_name                 -- 商品名（漢字）
      ,xel.product_name1_alt                 AS product_name1_alt            -- 商品名１（カナ）
      ,xel.product_name2_alt                 AS product_name2_alt            -- 商品名２（カナ）
      ,xel.item_standard1                    AS item_standard1               -- 規格１
      ,xel.item_standard2                    AS item_standard2               -- 規格２
      ,xel.qty_in_case                       AS qty_in_case                  -- 入数
      ,xel.num_of_cases                      AS num_of_cases                 -- ケース入数
      ,xel.num_of_ball                       AS num_of_ball                  -- ボール入数
      ,xel.item_color                        AS item_color                   -- 色
      ,xel.item_size                         AS item_size                    -- サイズ
      ,xel.order_uom_qty                     AS order_uom_qty                -- 発注単位数
      ,xel.uom_code                          AS uom_code                     -- 単位
      ,xel.indv_order_qty                    AS indv_order_qty               -- 発注数量（バラ）
      ,xel.case_order_qty                    AS case_order_qty               -- 発注数量（ケース）
      ,xel.ball_order_qty                    AS ball_order_qty               -- 発注数量（ボール）
      ,xel.sum_order_qty                     AS sum_order_qty                -- 発注数量（合計、バラ）
      ,xel.indv_shipping_qty                 AS indv_shipping_qty            -- 出荷数量（バラ）
      ,xel.case_shipping_qty                 AS case_shipping_qty            -- 出荷数量（ケース）
      ,xel.ball_shipping_qty                 AS ball_shipping_qty            -- 出荷数量（ボール）
      ,xel.pallet_shipping_qty               AS pallet_shipping_qty          -- 出荷数量（パレット）
      ,xel.sum_shipping_qty                  AS sum_shipping_qty             -- 出荷数量（合計、バラ）
      ,xel.indv_stockout_qty                 AS indv_stockout_qty            -- 欠品数量（バラ）
      ,xel.case_stockout_qty                 AS case_stockout_qty            -- 欠品数量（ケース）
      ,xel.ball_stockout_qty                 AS ball_stockout_qty            -- 欠品数量（ボール）
      ,xel.sum_stockout_qty                  AS sum_stockout_qty             -- 欠品数量（合計、バラ）
      ,xel.case_qty                          AS case_qty                     -- ケース個口数
      ,xel.fold_container_indv_qty           AS fold_container_indv_qty      -- オリコン（バラ）個口数
      ,xel.order_unit_price                  AS order_unit_price             -- 原単価（発注）
      ,xel.shipping_unit_price               AS shipping_unit_price          -- 原単価（出荷）
      ,xel.order_cost_amt                    AS order_cost_amt               -- 原価金額（発注）
      ,xel.shipping_cost_amt                 AS shipping_cost_amt            -- 原価金額（出荷）
      ,xel.stockout_cost_amt                 AS stockout_cost_amt            -- 原価金額（欠品）
      ,xel.selling_price                     AS selling_price                -- 売単価
      ,xel.order_price_amt                   AS order_price_amt              -- 売価金額（発注）
      ,xel.shipping_price_amt                AS shipping_price_amt           -- 売価金額（出荷）
      ,xel.stockout_price_amt                AS stockout_price_amt           -- 売価金額（欠品）
      ,xel.chain_peculiar_area_line          AS chain_peculiar_area_line     -- チェーン店固有エリア（明細）
      ,CASE xeh.edi_chain_code
         WHEN ecl.chain_code
           THEN dsf.meaning
         ELSE gv_msg_flag_out
       END                                   AS edi_delivery_schedule_flag   -- EDI納品予定送信済フラグ
      ,oola.rowid                            AS row_id                       -- rowid
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER：1.2 CONTENT:E_本稼動_04871 START
      ,xel.general_succeeded_item1           AS general_succeeded_item1      -- 汎用引継ぎ項目１
      ,xel.general_succeeded_item2           AS general_succeeded_item2      -- 汎用引継ぎ項目２
      ,xel.general_succeeded_item3           AS general_succeeded_item3      -- 汎用引継ぎ項目３
      ,xel.general_succeeded_item4           AS general_succeeded_item4      -- 汎用引継ぎ項目４
      ,xel.general_succeeded_item5           AS general_succeeded_item5      -- 汎用引継ぎ項目５
      ,xel.general_succeeded_item6           AS general_succeeded_item6      -- 汎用引継ぎ項目６
      ,xel.general_succeeded_item7           AS general_succeeded_item7      -- 汎用引継ぎ項目７
      ,xel.general_succeeded_item8           AS general_succeeded_item8      -- 汎用引継ぎ項目８
      ,xel.general_succeeded_item9           AS general_succeeded_item9      -- 汎用引継ぎ項目９
      ,xel.general_succeeded_item10          AS general_succeeded_item10     -- 汎用引継ぎ項目１０0
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER：1.2 CONTENT:E_本稼動_04871 END
    FROM
       oe_order_headers_all      ooha    -- 受注ヘッダ
      ,oe_order_lines_all        oola    -- 受注明細
      ,oe_order_sources          oos     -- 受注ソース
      ,xxcmm_cust_accounts       xca     -- 顧客アドオン
      ,xxcos_edi_headers         xeh     -- EDIヘッダ
      ,xxcos_edi_lines           xel     -- EDI明細
      ,( SELECT  flv.attribute1  chain_code
         FROM    fnd_lookup_values  flv
         WHERE   flv.language         = cv_lang
         AND     flv.lookup_type      = cv_type_ecl
         AND     flv.attribute2       = cv_order_schedule
         AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
         AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
         AND     flv.enabled_flag     = ct_enabled_flg_y
         GROUP BY flv.attribute1
       )                         ecl     -- クイックコード：EDI制御情報
      ,( SELECT  flv.lookup_code lookup_code
                ,flv.meaning     meaning
         FROM    fnd_lookup_values  flv
         WHERE   flv.language         = cv_lang
         AND     flv.lookup_type      = cv_type_esf
         AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
         AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
         AND     flv.enabled_flag     = ct_enabled_flg_y
       )                         dsf     -- クイックコード：EDI納品予定送信済フラグ
    WHERE
    -- 受注ヘッダ.受注日の年月＞業務日付−１の年月
        TO_CHAR( TRUNC( NVL( ooha.ordered_date, gd_proc_date ) ), cv_yyyy_mm ) 
     >= TO_CHAR( ADD_MONTHS( TRUNC( gd_proc_date ), -1 ), cv_yyyy_mm )
    -- 情報区分 = NULL OR 01
    AND (
          ooha.global_attribute3 IS NULL
        OR
          ooha.global_attribute3 = cv_target_order_01
        )
    -- 組織ID
    AND ooha.org_id                       = gn_org_id
    -- 受注ヘッダ.ソースID＝受注ソース.ソースID
    AND ooha.order_source_id              = oos.order_source_id
    -- 受注ソース名称（EDI受注、問屋CSV、国際CSV、Online）
    AND oos.name IN ( 
      SELECT  flv.attribute1
      FROM    fnd_lookup_values  flv
      WHERE   flv.language         = cv_lang
      AND     flv.lookup_type      = cv_type_ost
      AND     flv.lookup_code      LIKE cv_code_ost_009_a07
      AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
      AND     flv.enabled_flag     = ct_enabled_flg_y
      --受注ソース（EDI取込・CSV取込・クイック受注入力）
      AND     flv.description = icp_order_source
    )
    -- 受注ヘッダ.顧客ID = 顧客マスタアドオン.顧客ID
    AND ooha.sold_to_org_id        = xca.customer_id
    -- 顧客マスタアドオン.納品拠点コード=パラメータ.拠点コード
    AND xca.delivery_base_code     = icp_delivery_base_code
-- ADD DATE:2012/09/28 AUTHOR:M.Takasaki VER：1.3 CONTENT:E_本稼動_10114 START
    -- EDIヘッダ.変換後顧客コード = 顧客アドオン.顧客コード
    AND xeh.conv_customer_code     = xca.customer_code
-- ADD DATE:2012/09/28 AUTHOR:M.Takasaki VER：1.3 CONTENT:E_本稼動_10114 END
    -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
    AND ooha.header_id             = oola.header_id
    -- 受注明細.ステータス≠取消
    AND oola.flow_status_code NOT IN ( ct_ln_status_cancelled )
    -- 受注ヘッダ.外部システム受注番号＝EDIヘッダ.受注関連番号
    AND ooha.orig_sys_document_ref = xeh.order_connection_number
    -- EDIヘッダ.EDIヘッダID＝EDI明細.EDIヘッダID
    AND xeh.edi_header_info_id     = xel.edi_header_info_id
    -- 受注明細.外部システム受注明細番号＝EDI明細.受注関連明細番号
    AND oola.orig_sys_line_ref     = xel.order_connection_line_number
    AND ( 
      --新規出力の場合
      ( icp_output_type = cv_output_type_new
        --ファイル出力日 IS NULL
        AND oola.global_attribute6 IS NULL
-- Ver1.4 add start
        --顧客マスタ.チェーン店コード＝パラメータ.チェーン店コード
        AND (  icp_chain_code IS NULL
            OR xca.chain_store_code = icp_chain_code
            )
-- Ver1.4 add End
      )
      OR
      --再出力の場合
      ( icp_output_type <> cv_output_type_new
        --ファイル出力日 IS NOT NULL
        AND oola.global_attribute6 IS NOT NULL
        --顧客マスタ.チェーン店コード＝パラメータ.チェーン店コード
        AND (  icp_chain_code IS NULL
            OR xca.chain_store_code = icp_chain_code
            )
        AND (
          --パラメータ受信日がNLLL
          (
            icp_order_creation_date_from IS NULL
            AND icp_order_creation_date_to IS NULL
          )
          --パラメータ受信日に設定あり
          OR (
            --受注ヘッダ.作成日≧パラメータ.受信日（FROM）
            TRUNC( ooha.creation_date )     >= 
                TRUNC( icp_order_creation_date_from )
            --受注ヘッダ.作成日≦パラメータ.受信日（TO）
            AND TRUNC( ooha.creation_date ) <= TRUNC( icp_order_creation_date_to )
          )
        )
        AND (
          --パラメータ納品日がNLLL
          (
            icp_ordered_date_h_from IS NULL
            AND icp_ordered_date_h_to IS NULL
          )
          --パラメータ納品日に設定あり
          OR (
            --受注ヘッダ.納品予定日≧パラメータ.納品日（FROM）
            TRUNC( ooha.request_date )     >= 
                TRUNC( icp_ordered_date_h_from )
            --受注ヘッダ.納品日予定日≦パラメータ.納品日（TO）
            AND TRUNC( ooha.request_date ) <= TRUNC( icp_ordered_date_h_to )
          )
        )
      )
    )
    -- EDI納品予定送信済フラグの名称取得
    AND xeh.edi_delivery_schedule_flag = dsf.lookup_code
    -- EDI制御情報より納品予定を判定
    AND ecl.chain_code(+) = xeh.edi_chain_code
    -- 受注カテゴリ
    AND ooha.order_category_code in ( cv_occ_mixed, cv_occ_order )
    ORDER BY
       xca.chain_store_code  -- チェーン店コード
      ,xca.store_code        -- 店舗コード
      ,ooha.request_date     -- 納品日(ヘッダ)
      ,ooha.cust_po_number   -- 顧客発注番号
      ,ooha.order_number     -- 受注番号
      ,oola.line_number      -- 受注明細番号
    FOR UPDATE OF
       ooha.header_id        -- 受注ヘッダ.ヘッダID
      ,oola.line_id          -- 受注明細.明細ID
    NOWAIT
    ;
--
  --取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF data_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_source                 IN     VARCHAR2,  -- 受注ソース
    iv_delivery_base_code           IN     VARCHAR2,  -- 納品拠点コード
    iv_output_type                  IN     VARCHAR2,  -- 出力区分
    iv_chain_code                   IN     VARCHAR2,  -- チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,  -- 受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  -- 受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  -- 納品日(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,  -- 納品日(TO)
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
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
    lv_para_msg            VARCHAR2(5000);                         -- パラメータ出力メッセージ
    lv_date_item           VARCHAR2(100);                          -- MIN日付/MAX日付
    lv_profile_name        VARCHAR2(100);                          -- 営業単位
    lv_token_value1        VARCHAR2(100);                          -- エラーメッセージに出力するトークン値
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
    --========================================
    -- パラメータ出力処理
    --========================================
    IF ( iv_output_type = cv_output_type_new ) THEN   --EDI（新規）
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter1,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
        iv_token_value3       =>  iv_output_type,
-- Ver1.4 add Start
        iv_token_name4        =>  cv_tkn_nm_chain_code,
        iv_token_value4       =>  iv_chain_code
-- Ver1.4 add End
      );
    ELSE  --EDI（再出力）
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter2,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
        iv_token_value3       =>  iv_output_type,
        iv_token_name4        =>  cv_tkn_nm_chain_code,
        iv_token_value4       =>  iv_chain_code,
        iv_token_name5        =>  cv_tkn_nm_order_c_date_f_t,
        iv_token_value5       =>  iv_order_creation_date_from || ',' || iv_order_creation_date_to,
        iv_token_name6        =>  cv_tkn_nm_s_ordered_date_f_t,
        iv_token_value6       =>  iv_ordered_date_h_from || ',' || iv_ordered_date_h_to
      );
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- MO:営業単位
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
    -- プロファイルが取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcos_short_name,
        iv_name        => cv_str_profile_nm
      );
      --プロファイル名文字列取得
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcos_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MIN日付取得処理
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_min_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MAX日付取得処理
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_max_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 受注ソース種別取得の前処理
    --========================================
    BEGIN
      --EDI取込 受注ソースの名称を取得
      SELECT  flv.description        order_source_edi
      INTO    gv_order_source_edi_chk
      FROM    fnd_lookup_values  flv
      WHERE   flv.language        = cv_lang
      AND     flv.lookup_type     = cv_type_ost
      AND     flv.lookup_code     LIKE cv_code_ost_009_a07
      AND     flv.attribute2      = cv_diff_y               --EDI取込
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_max_date )
      AND     flv.enabled_flag    = ct_enabled_flg_y
      AND     rownum              = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_edi
        );
        RAISE global_order_source_get_expt;
    END;
--
    --========================================
    -- EDI納品予定送信済フラグ名称（対象外）の取得
    --========================================
    gv_msg_flag_out := xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_xxcos_short_name,
                         iv_name               =>  cv_msg_flag_out
                       );
--
  EXCEPTION
    -- *** 受注ソース種別取得例外ハンドラ ***
    WHEN global_order_source_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_order_source,
        iv_token_name1        =>  cv_tkn_nm_order_source_name,
        iv_token_value1       =>  lv_token_value1
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_order_source                 IN     VARCHAR2,     --   受注ソース
    iv_output_type                  IN     VARCHAR2,     --   出力区分
    iv_order_creation_date_from     IN     VARCHAR2,     --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,     --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,     --   納品日(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,     --   納品日(TO)
    od_order_creation_date_from     OUT    DATE,         --   受信日(FROM)_チェックOK
    od_order_creation_date_to       OUT    DATE,         --   受信日(TO)_チェックOK
    od_ordered_date_h_from          OUT    DATE,         --   納品日(FROM)_チェックOK
    od_ordered_date_h_to            OUT    DATE,         --   納品日(TO)_チェックOK
    ov_errbuf                       OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    lv_check_item                    VARCHAR2(100);      -- 受信日(FROM)又は受信日(TO)文言
    lv_check_item1                   VARCHAR2(100);      -- 受信日(FROM)文言
    lv_check_item2                   VARCHAR2(100);      -- 受信日(TO)文言
    ld_order_creation_date_from      DATE;               -- 受信日(FROM)_チェックOK
    ld_order_creation_date_to        DATE;               -- 受信日(TO)_チェックOK
    ld_ordered_date_h_from           DATE;               -- 納品日(ヘッダ)(FROM)_チェックOK
    ld_ordered_date_h_to             DATE;               -- 納品日(ヘッダ)(TO)_チェックOK
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
    --EDI再出力時の日付チェック
    IF ( iv_order_source = gv_order_source_edi_chk ) AND ( iv_output_type <> cv_output_type_new ) THEN
      --受信日、納品日のいづれの入力チェック
      IF ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NULL )
        AND ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NULL )
      THEN
        RAISE global_edi_date_chk_expt;
      END IF;
      --受信日(FROM)必須チェック
      IF ( ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --受信日(TO)必須チェック
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
      --受信日(FROM)、受信日(TO)両方入力された場合
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        --受信日(FROM)書式チェック
        ld_order_creation_date_from := FND_DATE.STRING_TO_DATE( iv_order_creation_date_from, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --受信日(TO)書式チェック
        ld_order_creation_date_to := FND_DATE.STRING_TO_DATE( iv_order_creation_date_to, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_to
          );
          RAISE global_format_chk_expt;
        END IF;
        --受信日(FROM)／--受信日(TO)日付逆転チェック
        IF ( ld_order_creation_date_from > ld_order_creation_date_to ) THEN
          RAISE global_date_rever_ocd_chk_expt;
        END IF;
      END IF;
--
      --納品日(FROM)必須チェック
      IF ( ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --納品日(TO)必須チェック
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_to
        );
        RAISE global_format_chk_expt;
      END IF;
      --納品日(FROM)、納品日(TO)両方入力された場合
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        --納品日(FROM)書式チェック
        ld_ordered_date_h_from := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_from, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --納品日(TO)書式チェック
        ld_ordered_date_h_to := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_to, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_to
          );
          RAISE global_format_chk_expt;
        END IF;
        --納品日(FROM)／--納品日(TO)日付逆転チェック
        IF ( ld_ordered_date_h_from > ld_ordered_date_h_to ) THEN
          RAISE global_date_rever_odh_chk_expt;
        END IF;
      END IF;
--
    END IF;
--
--
    --チェックOK
    od_order_creation_date_from   := ld_order_creation_date_from;
    od_order_creation_date_to     := ld_order_creation_date_to;
    od_ordered_date_h_from        := ld_ordered_date_h_from;
    od_ordered_date_h_to          := ld_ordered_date_h_to;
--
  EXCEPTION
    -- *** 書式チェック例外ハンドラ ***
    WHEN global_format_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_format_check_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***EDI日付指定なし例外ハンドラ ***
    WHEN global_edi_date_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_edi_date_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***受信日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_ocd_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***納品日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_odh_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_order_source                 IN     VARCHAR2,     --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,     --   納品拠点コード
    iv_output_type                  IN     VARCHAR2,     --   出力区分
    iv_chain_code                   IN     VARCHAR2,     --   チェーン店コード
    id_order_creation_date_from     IN     DATE,         --   受信日(FROM)
    id_order_creation_date_to       IN     DATE,         --   受信日(TO)
    id_ordered_date_h_from          IN     DATE,         --   納品日(FROM)
    id_ordered_date_h_to            IN     DATE,         --   納品日(TO)
    ov_errbuf                       OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    lv_tkn_vl_table_name      VARCHAR2(100);                          --テーブル名称(文言)
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
    --対象データ取得
    OPEN  data_edi_cur(
            iv_order_source,                -- 受注ソース
            iv_delivery_base_code,          -- 納品拠点コード
            iv_output_type,                 -- 出力区分
            iv_chain_code,                  -- チェーン店コード
            id_order_creation_date_from,    -- 受信日(FROM)
            id_order_creation_date_to,      -- 受信日(TO)
            id_ordered_date_h_from,         -- 納品日(FROM)
            id_ordered_date_h_to);          -- 納品日(TO)
    FETCH data_edi_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE data_edi_cur;
--
    --処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
  EXCEPTION
--
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( data_edi_cur%ISOPEN ) THEN
        CLOSE data_edi_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_ooha
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( data_edi_cur%ISOPEN ) THEN
        CLOSE data_edi_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-4)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_order_source                 IN     VARCHAR2,  --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,  --   納品拠点コード
    iv_output_type                  IN     VARCHAR2,  --   出力区分
    iv_chain_code                   IN     VARCHAR2,  --   チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,  --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  --   納品日(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,  --   納品日(TO)
    ov_errbuf                       OUT    VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    lv_delimit    CONSTANT  VARCHAR2(10) := '	';    -- 区切り文字
    lv_colon      CONSTANT  VARCHAR2(10) := ':';    -- 処理時刻の区切り文字
--
    -- *** ローカル変数 ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUTデータ編集用
    lv_out_process_time     VARCHAR2(10);           -- 編集後の処理時刻
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR head_cur
    IS
      SELECT  flv.description  head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_lang
      AND     flv.lookup_type   = cv_type_head
      AND     lookup_code    LIKE cv_code_eoh_009a07
      AND     gd_proc_date     >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date     <= NVL( flv.end_date_active,   gd_max_date )
      AND     flv.enabled_flag  = ct_enabled_flg_y
      ORDER BY
              flv.lookup_code
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------
    --データ見出し出力
    ----------------------
    --データの見出しを取得
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    --データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || lv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
--
    ----------------------
    --データ出力
    ----------------------
    --データを取得
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --初期化
      lv_line_data        := NULL;
      lv_out_process_time := NULL;
      --処理時刻の編集
      IF( gt_out_file_tab(i).process_time IS NULL) THEN
        NULL;
      ELSE
        lv_out_process_time := SUBSTR( gt_out_file_tab(i).process_time, 1, 2 ) || lv_colon ||   -- 時
                               SUBSTR( gt_out_file_tab(i).process_time, 3, 2 ) || lv_colon ||   -- 分
                               SUBSTR( gt_out_file_tab(i).process_time, 5, 2 );                 -- 秒
      END IF;
      --データを編集
      lv_line_data :=                  gt_out_file_tab(i).medium_class                 -- 媒体区分
                      || lv_delimit || gt_out_file_tab(i).data_type_code               -- データ種コード
                      || lv_delimit || gt_out_file_tab(i).file_no                      -- ファイルＮｏ
                      || lv_delimit || gt_out_file_tab(i).info_class                   -- 情報区分
                      || lv_delimit || gt_out_file_tab(i).process_date                 -- 処理日
                      || lv_delimit || lv_out_process_time                             -- 処理時刻
                      || lv_delimit || gt_out_file_tab(i).base_code                    -- 拠点（部門）コード
                      || lv_delimit || gt_out_file_tab(i).base_name                    -- 拠点名（正式名）
                      || lv_delimit || gt_out_file_tab(i).edi_chain_code               -- ＥＤＩチェーン店コード
                      || lv_delimit || gt_out_file_tab(i).edi_chain_name               -- ＥＤＩチェーン店名（漢字）
                      || lv_delimit || gt_out_file_tab(i).chain_code                   -- チェーン店コード
                      || lv_delimit || gt_out_file_tab(i).chain_name                   -- チェーン店名（漢字）
                      || lv_delimit || gt_out_file_tab(i).report_code                  -- 帳票コード
                      || lv_delimit || gt_out_file_tab(i).report_show_name             -- 帳票表示名
                      || lv_delimit || gt_out_file_tab(i).customer_code                -- 顧客コード
                      || lv_delimit || gt_out_file_tab(i).customer_name                -- 顧客名（漢字）
                      || lv_delimit || gt_out_file_tab(i).company_code                 -- 社コード
                      || lv_delimit || gt_out_file_tab(i).company_name                 -- 社名（漢字）
                      || lv_delimit || gt_out_file_tab(i).company_name_alt             -- 社名（カナ）
                      || lv_delimit || gt_out_file_tab(i).shop_code                    -- 店コード
                      || lv_delimit || gt_out_file_tab(i).shop_name                    -- 店名（漢字）
                      || lv_delimit || gt_out_file_tab(i).shop_name_alt                -- 店名（カナ）
                      || lv_delimit || gt_out_file_tab(i).delivery_center_code         -- 納入センターコード
                      || lv_delimit || gt_out_file_tab(i).delivery_center_name         -- 納入センター名（漢字）
                      || lv_delimit || gt_out_file_tab(i).delivery_center_name_alt     -- 納入センター名（カナ）
                      || lv_delimit || gt_out_file_tab(i).order_date                   -- 発注日
                      || lv_delimit || gt_out_file_tab(i).center_delivery_date         -- センター納品日
                      || lv_delimit || gt_out_file_tab(i).result_delivery_date         -- 実納品日
                      || lv_delimit || gt_out_file_tab(i).shop_delivery_date           -- 店舗納品日
                      || lv_delimit || gt_out_file_tab(i).invoice_class                -- 伝票区分
                      || lv_delimit || gt_out_file_tab(i).small_classification_code    -- 小分類コード
                      || lv_delimit || gt_out_file_tab(i).small_classification_name    -- 小分類名
                      || lv_delimit || gt_out_file_tab(i).middle_classification_code   -- 中分類コード
                      || lv_delimit || gt_out_file_tab(i).middle_classification_name   -- 中分類名
                      || lv_delimit || gt_out_file_tab(i).big_classification_code      -- 大分類コード
                      || lv_delimit || gt_out_file_tab(i).big_classification_name      -- 大分類名
                      || lv_delimit || gt_out_file_tab(i).other_party_department_code  -- 相手先部門コード
                      || lv_delimit || gt_out_file_tab(i).other_party_order_number     -- 相手先発注番号
                      || lv_delimit || gt_out_file_tab(i).invoice_number               -- 伝票番号
                      || lv_delimit || gt_out_file_tab(i).check_digit                  -- チェックデジット
                      || lv_delimit || gt_out_file_tab(i).order_no_ebs                 -- 受注Ｎｏ（ＥＢＳ）
                      || lv_delimit || gt_out_file_tab(i).ar_sale_class                -- 特売区分
                      || lv_delimit || gt_out_file_tab(i).delivery_classe              -- 配送区分
                      || lv_delimit || gt_out_file_tab(i).opportunity_no               -- 便Ｎｏ
                      || lv_delimit || gt_out_file_tab(i).area_code                    -- 地区コード
                      || lv_delimit || gt_out_file_tab(i).area_name                    -- 地区名（漢字）
                      || lv_delimit || gt_out_file_tab(i).area_name_alt                -- 地区名（カナ）
                      || lv_delimit || gt_out_file_tab(i).vendor_code                  -- 取引先コード
                      || lv_delimit || gt_out_file_tab(i).vendor_name                  -- 取引先名（漢字）
                      || lv_delimit || gt_out_file_tab(i).vendor_name1_alt             -- 取引先名１（カナ）
                      || lv_delimit || gt_out_file_tab(i).vendor_name2_alt             -- 取引先名２（カナ）
                      || lv_delimit || gt_out_file_tab(i).vendor_tel                   -- 取引先ＴＥＬ
                      || lv_delimit || gt_out_file_tab(i).vendor_charge                -- 取引先担当者
                      || lv_delimit || gt_out_file_tab(i).vendor_address               -- 取引先住所（漢字）
                      || lv_delimit || gt_out_file_tab(i).sub_distribution_center_code -- サブ物流センターコード
                      || lv_delimit || gt_out_file_tab(i).sub_distribution_center_name -- サブ物流センターコード名
                      || lv_delimit || gt_out_file_tab(i).eos_handwriting_class        -- ＥＯＳ・手書区分
                      || lv_delimit || gt_out_file_tab(i).a1_column                    -- Ａ−１欄
                      || lv_delimit || gt_out_file_tab(i).b1_column                    -- Ｂ−１欄
                      || lv_delimit || gt_out_file_tab(i).c1_column                    -- Ｃ−１欄
                      || lv_delimit || gt_out_file_tab(i).d1_column                    -- Ｄ−１欄
                      || lv_delimit || gt_out_file_tab(i).e1_column                    -- Ｅ−１欄
                      || lv_delimit || gt_out_file_tab(i).a2_column                    -- Ａ−２欄
                      || lv_delimit || gt_out_file_tab(i).b2_column                    -- Ｂ−２欄
                      || lv_delimit || gt_out_file_tab(i).c2_column                    -- Ｃ−２欄
                      || lv_delimit || gt_out_file_tab(i).d2_column                    -- Ｄ−２欄
                      || lv_delimit || gt_out_file_tab(i).e2_column                    -- Ｅ−２欄
                      || lv_delimit || gt_out_file_tab(i).a3_column                    -- Ａ−３欄
                      || lv_delimit || gt_out_file_tab(i).b3_column                    -- Ｂ−３欄
                      || lv_delimit || gt_out_file_tab(i).c3_column                    -- Ｃ−３欄
                      || lv_delimit || gt_out_file_tab(i).d3_column                    -- Ｄ−３欄
                      || lv_delimit || gt_out_file_tab(i).e3_column                    -- Ｅ−３欄
                      || lv_delimit || gt_out_file_tab(i).f1_column                    -- Ｆ−１欄
                      || lv_delimit || gt_out_file_tab(i).g1_column                    -- Ｇ−１欄
                      || lv_delimit || gt_out_file_tab(i).h1_column                    -- Ｈ−１欄
                      || lv_delimit || gt_out_file_tab(i).i1_column                    -- Ｉ−１欄
                      || lv_delimit || gt_out_file_tab(i).j1_column                    -- Ｊ−１欄
                      || lv_delimit || gt_out_file_tab(i).k1_column                    -- Ｋ−１欄
                      || lv_delimit || gt_out_file_tab(i).l1_column                    -- Ｌ−１欄
                      || lv_delimit || gt_out_file_tab(i).f2_column                    -- Ｆ−２欄
                      || lv_delimit || gt_out_file_tab(i).g2_column                    -- Ｇ−２欄
                      || lv_delimit || gt_out_file_tab(i).h2_column                    -- Ｈ−２欄
                      || lv_delimit || gt_out_file_tab(i).i2_column                    -- Ｉ−２欄
                      || lv_delimit || gt_out_file_tab(i).j2_column                    -- Ｊ−２欄
                      || lv_delimit || gt_out_file_tab(i).k2_column                    -- Ｋ−２欄
                      || lv_delimit || gt_out_file_tab(i).l2_column                    -- Ｌ−２欄
                      || lv_delimit || gt_out_file_tab(i).f3_column                    -- Ｆ−３欄
                      || lv_delimit || gt_out_file_tab(i).g3_column                    -- Ｇ−３欄
                      || lv_delimit || gt_out_file_tab(i).h3_column                    -- Ｈ−３欄
                      || lv_delimit || gt_out_file_tab(i).i3_column                    -- Ｉ−３欄
                      || lv_delimit || gt_out_file_tab(i).j3_column                    -- Ｊ−３欄
                      || lv_delimit || gt_out_file_tab(i).k3_column                    -- Ｋ−３欄
                      || lv_delimit || gt_out_file_tab(i).l3_column                    -- Ｌ−３欄
                      || lv_delimit || gt_out_file_tab(i).chain_peculiar_area_header   -- チェーン店固有エリア（ヘッダー）
                      || lv_delimit || gt_out_file_tab(i).line_no                      -- 行Ｎｏ
                      || lv_delimit || gt_out_file_tab(i).stockout_class               -- 欠品区分
                      || lv_delimit || gt_out_file_tab(i).stockout_reason              -- 欠品理由
                      || lv_delimit || gt_out_file_tab(i).product_code_itouen          -- 商品コード（伊藤園）
                      || lv_delimit || gt_out_file_tab(i).product_code1                -- 商品コード１
                      || lv_delimit || gt_out_file_tab(i).product_code2                -- 商品コード２
                      || lv_delimit || gt_out_file_tab(i).jan_code                     -- ＪＡＮコード
                      || lv_delimit || gt_out_file_tab(i).itf_code                     -- ＩＴＦコード
                      || lv_delimit || gt_out_file_tab(i).extension_itf_code           -- 内箱ＩＴＦコード
                      || lv_delimit || gt_out_file_tab(i).case_product_code            -- ケース商品コード
                      || lv_delimit || gt_out_file_tab(i).ball_product_code            -- ボール商品コード
                      || lv_delimit || gt_out_file_tab(i).prod_class                   -- 商品区分
                      || lv_delimit || gt_out_file_tab(i).product_name                 -- 商品名（漢字）
                      || lv_delimit || gt_out_file_tab(i).product_name1_alt            -- 商品名１（カナ）
                      || lv_delimit || gt_out_file_tab(i).product_name2_alt            -- 商品名２（カナ）
                      || lv_delimit || gt_out_file_tab(i).item_standard1               -- 規格１
                      || lv_delimit || gt_out_file_tab(i).item_standard2               -- 規格２
                      || lv_delimit || gt_out_file_tab(i).qty_in_case                  -- 入数
                      || lv_delimit || gt_out_file_tab(i).num_of_cases                 -- ケース入数
                      || lv_delimit || gt_out_file_tab(i).num_of_ball                  -- ボール入数
                      || lv_delimit || gt_out_file_tab(i).item_color                   -- 色
                      || lv_delimit || gt_out_file_tab(i).item_size                    -- サイズ
                      || lv_delimit || gt_out_file_tab(i).order_uom_qty                -- 発注単位数
                      || lv_delimit || gt_out_file_tab(i).uom_code                     -- 単位
                      || lv_delimit || gt_out_file_tab(i).indv_order_qty               -- 発注数量（バラ）
                      || lv_delimit || gt_out_file_tab(i).case_order_qty               -- 発注数量（ケース）
                      || lv_delimit || gt_out_file_tab(i).ball_order_qty               -- 発注数量（ボール）
                      || lv_delimit || gt_out_file_tab(i).sum_order_qty                -- 発注数量（合計、バラ）
                      || lv_delimit || gt_out_file_tab(i).indv_shipping_qty            -- 出荷数量（バラ）
                      || lv_delimit || gt_out_file_tab(i).case_shipping_qty            -- 出荷数量（ケース）
                      || lv_delimit || gt_out_file_tab(i).ball_shipping_qty            -- 出荷数量（ボール）
                      || lv_delimit || gt_out_file_tab(i).pallet_shipping_qty          -- 出荷数量（パレット）
                      || lv_delimit || gt_out_file_tab(i).sum_shipping_qty             -- 出荷数量（合計、バラ）
                      || lv_delimit || gt_out_file_tab(i).indv_stockout_qty            -- 欠品数量（バラ）
                      || lv_delimit || gt_out_file_tab(i).case_stockout_qty            -- 欠品数量（ケース）
                      || lv_delimit || gt_out_file_tab(i).ball_stockout_qty            -- 欠品数量（ボール）
                      || lv_delimit || gt_out_file_tab(i).sum_stockout_qty             -- 欠品数量（合計、バラ）
                      || lv_delimit || gt_out_file_tab(i).case_qty                     -- ケース個口数
                      || lv_delimit || gt_out_file_tab(i).fold_container_indv_qty      -- オリコン（バラ）個口数
                      || lv_delimit || gt_out_file_tab(i).order_unit_price             -- 原単価（発注）
                      || lv_delimit || gt_out_file_tab(i).shipping_unit_price          -- 原単価（出荷）
                      || lv_delimit || gt_out_file_tab(i).order_cost_amt               -- 原価金額（発注）
                      || lv_delimit || gt_out_file_tab(i).shipping_cost_amt            -- 原価金額（出荷）
                      || lv_delimit || gt_out_file_tab(i).stockout_cost_amt            -- 原価金額（欠品）
                      || lv_delimit || gt_out_file_tab(i).selling_price                -- 売単価
                      || lv_delimit || gt_out_file_tab(i).order_price_amt              -- 売価金額（発注）
                      || lv_delimit || gt_out_file_tab(i).shipping_price_amt           -- 売価金額（出荷）
                      || lv_delimit || gt_out_file_tab(i).stockout_price_amt           -- 売価金額（欠品）
                      || lv_delimit || gt_out_file_tab(i).chain_peculiar_area_line     -- チェーン店固有エリア（明細）
                      || lv_delimit || gt_out_file_tab(i).edi_delivery_schedule_flag   -- EDI納品予定送信済フラグ
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER：1.2 CONTENT:E_本稼動_04871 START
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item1      -- 汎用引継ぎ項目１
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item2      -- 汎用引継ぎ項目２
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item3      -- 汎用引継ぎ項目３
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item4      -- 汎用引継ぎ項目４
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item5      -- 汎用引継ぎ項目５
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item6      -- 汎用引継ぎ項目６
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item7      -- 汎用引継ぎ項目７
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item8      -- 汎用引継ぎ項目８
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item9      -- 汎用引継ぎ項目９
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item10     -- 汎用引継ぎ項目１０
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER：1.2 CONTENT:E_本稼動_04871 END
                      ;
--
      --受注明細テーブル更新のためのROWIDを格納
      gt_oola_rowid_tab(i) := gt_out_file_tab(i).row_id;
--
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( head_cur%ISOPEN ) THEN
        CLOSE head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line_data
   * Description      : 受注明細出力済み更新（EDI取込のみ）(A-5)
   ***********************************************************************************/
  PROCEDURE update_order_line_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line_data'; -- プログラム名
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
    ld_output_date         CONSTANT DATE := SYSDATE;  -- ファイル出力日時
--
    -- *** ローカル変数 ***
    lv_tkn_vl_table_name   VARCHAR2(100);             --対象テーブル名
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
    --受注明細テーブル更新処理
    BEGIN
      FORALL ln_cnt IN 1..gt_oola_rowid_tab.COUNT
        UPDATE 
          oe_order_lines_all      oola
        SET
          oola.global_attribute6      = TO_CHAR( ld_output_date, cv_yyyymmddhhmiss ), -- ファイル出力日時
          oola.last_updated_by        = cn_last_updated_by,                           -- 最終更新者
          oola.last_update_date       = cd_last_update_date,                          -- 最終更新日
          oola.last_update_login      = cn_last_update_login,                         -- 最終更新ログイン
          oola.request_id             = cn_request_id,                                -- 要求ID
          oola.program_application_id = cn_program_application_id,                    -- コンカレント・プログラム・アプリID
          oola.program_id             = cn_program_id,                                -- コンカレント・プログラムID
          oola.program_update_date    = cd_program_update_date                        -- プログラム更新日
        WHERE
          oola.rowid                  = gt_oola_rowid_tab( ln_cnt );                  -- 受注明細ROWID
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        RAISE global_data_update_expt;
    END;
--
  EXCEPTION
    --*** 処理対象データ更新例外 ***
    WHEN global_data_update_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_oola
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_update_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END update_order_line_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_source                 IN     VARCHAR2,  -- 受注ソース
    iv_delivery_base_code           IN     VARCHAR2,  -- 納品拠点コード
    iv_output_type                  IN     VARCHAR2,  -- 出力区分
    iv_chain_code                   IN     VARCHAR2,  -- チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,  -- 受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  -- 受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  -- 納品日(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,  -- 納品日(TO)
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
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
    ld_order_creation_date_from       DATE;            -- 受信日(FROM)_チェックOK
    ld_order_creation_date_to         DATE;            -- 受信日(TO)_チェックOK
    ld_ordered_date_h_from            DATE;            -- 納品日(ヘッダ)(FROM)_チェックOK
    ld_ordered_date_h_to              DATE;            -- 納品日(ヘッダ)(TO)_チェックOK
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
--
    -- ===============================
    -- A-1  初期処理（プロファイル取得）
    -- ===============================
    init(
      iv_order_source,              -- 受注ソース
      iv_delivery_base_code,        -- 納品拠点コード
      iv_output_type,               -- 出力区分
      iv_chain_code,                -- チェーン店コード
      iv_order_creation_date_from,  -- 受信日(FROM)
      iv_order_creation_date_to,    -- 受信日(TO)
      iv_ordered_date_h_from,       -- 納品日(FROM)
      iv_ordered_date_h_to,         -- 納品日(TO)
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  パラメータチェック
    -- ===============================
    check_parameter(
      iv_order_source,              -- 受注ソース
      iv_output_type,               -- 出力区分
      iv_order_creation_date_from,  -- 受信日(FROM)
      iv_order_creation_date_to,    -- 受信日(TO)
      iv_ordered_date_h_from,       -- 納品日(FROM)
      iv_ordered_date_h_to,         -- 納品日(TO)
      ld_order_creation_date_from,  -- 受信日(FROM)_チェックOK
      ld_order_creation_date_to,    -- 受信日(TO)_チェックOK
      ld_ordered_date_h_from,       -- 納品日(FROM)_チェックOK
      ld_ordered_date_h_to,         -- 納品日(TO)_チェックOK
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  対象データ取得
    -- ===============================
    get_data(
      iv_order_source,              -- 受注ソース
      iv_delivery_base_code,        -- 納品拠点コード
      iv_output_type,               -- 出力区分
      iv_chain_code,                -- チェーン店コード
      ld_order_creation_date_from,  -- 受信日(FROM)_チェックOK
      ld_order_creation_date_to,    -- 受信日(TO)_チェックOK
      ld_ordered_date_h_from,       -- 納品日(FROM)_チェックOK
      ld_ordered_date_h_to,         -- 納品日(TO)_チェックOK
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が0件
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- ===============================
    -- A-4  データ出力
    -- ===============================
    output_data(
       iv_order_source                 => iv_order_source                -- 受注ソース
      ,iv_delivery_base_code           => iv_delivery_base_code          -- 納品拠点コード
      ,iv_output_type                  => iv_output_type                 -- 出力区分
      ,iv_chain_code                   => iv_chain_code                  -- チェーン店コード
      ,iv_order_creation_date_from     => ld_order_creation_date_from    -- 受信日(FROM)
      ,iv_order_creation_date_to       => ld_order_creation_date_to      -- 受信日(TO)
      ,iv_ordered_date_h_from          => ld_ordered_date_h_from         -- 納品日(FROM)
      ,iv_ordered_date_h_to            => ld_ordered_date_h_to           -- 納品日(TO)
      ,ov_errbuf                       => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                      => lv_retcode                     -- リターン・コード             --# 固定 #
      ,ov_errmsg                       => lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5  受注明細出力済み更新（EDI取込新規のみ）
    -- ===============================
    IF ( iv_order_source = gv_order_source_edi_chk ) 
      AND ( iv_output_type = cv_output_type_new ) THEN
      update_order_line_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_no_data
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                          OUT    VARCHAR2,  -- エラー・メッセージ  --# 固定 #
    retcode                         OUT    VARCHAR2,  -- リターン・コード    --# 固定 #
    iv_order_source                 IN     VARCHAR2,  -- 受注ソース
    iv_delivery_base_code           IN     VARCHAR2,  -- 納品拠点コード
    iv_output_type                  IN     VARCHAR2,  -- 出力区分
    iv_chain_code                   IN     VARCHAR2,  -- チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,  -- 受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  -- 受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  -- 納品日(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2   -- 納品日(TO)
  )
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_order_source                 -- 受注ソース
      ,iv_delivery_base_code           -- 納品拠点コード
      ,iv_output_type                  -- 出力区分
      ,iv_chain_code                   -- チェーン店コード
      ,iv_order_creation_date_from     -- 受信日(FROM)
      ,iv_order_creation_date_to       -- 受信日(TO)
      ,iv_ordered_date_h_from          -- 納品日(FROM)
      ,iv_ordered_date_h_to            -- 納品日(TO)
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --エラーの場合、成功件数クリア
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS009A07C;
/
