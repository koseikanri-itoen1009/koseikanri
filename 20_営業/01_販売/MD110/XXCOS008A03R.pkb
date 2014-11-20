CREATE OR REPLACE PACKAGE BODY XXCOS008A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A03R (body)
 * Description      : 直送受注例外データリスト
 * MD.050           : 直送受注例外データリスト MD050_COS_008_A03
 * Version          : 1.18
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   (A-1)初期処理
 *  get_data               (A-2)例外データ取得
 *  insert_rpt_wrk_data    (A-3)ワークテーブルデータ登録
 *  execute_svf            (A-4)SVFコンカレント起動
 *  delete_rpt_wrk_data    (A-5)ワークテーブルデータ削除
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   T.Miyata         新規作成
 *  2009/02/16    1.1   SCS K.NAKAMURA   [COS_002] g,mgからkgへの単位換算の不具合対応
 *  2009/02/19    1.2   K.Atsushiba      get_msgのパッケージ名修正
 *  2009/04/10    1.3   T.Kitajima       [T1_0381]出荷依頼情報の数量0データ除外
 *  2009/05/26    1.4   T.Kitajima       [T1_1183]受注数量のマイナス化
 *  2009/06/17    1.5   N.Nishimura      [T1_1439]対象件数0件時、正常終了とする
 *  2009/06/25    1.6   N.Nishimura      [T1_1437]データパージ不具合対応
 *  2009/07/08    1.7   N.Maeda          [0000484]出荷品目を依頼品目に変更
 *  2009/07/27    1.8   N.Maeda          [0000834]単位設定取得箇所変更対応
 *  2009/10/05    1.9   K.Satomura       [0001369]納品予定日をプロファイルオプション値以降の
 *                                                日時を対象とする
 *  2009/10/07    1.10  K.Satomura       [0001378]帳票ワークテーブルの桁あふれ対応
 *  2009/11/26    1.11  N.Maeda          [E_本稼動_00092] 納品予定日条件のメインSQL取込
 *  2009/12/11    1.12  N.Maeda          [E_本稼動_00238] リスト対象ステータスに'CLOSED'を追加
 *                                       [E_本稼動_00275] 出荷実績未計上データ出荷実績数の取得先修正
 *  2009/12/17    1.12  S.Tomita         [E_本稼動_00275] (追加修正)例外1の出荷依頼情報の数量0データ対象化
 *  2010/01/14    1.13  N.Maeda          [E_本稼動_01090] 例外６取得ＳＱＬの追加
 *  2010/03/25    1.14  N.Maeda          [E_本稼動_01548] 検収予定日違い対応
 *                                       [E_本稼動_02019] PT対応
 *  2010/04/09    1.14  M.Sano           [E_本稼動_02019] PT対応(追加)
 *  2011/03/08    1.15  K.Kiriu          [E_本稼動_04367] 対象月含む以前のデータのみ出力の対応
 *                                                        クローズデータの日付参照不具合対応
 *  2011/04/18    1.16  Y.Kanami         [E_本稼動_06646] ALL指定時の条件に顧客追加対応
 *  2011/11/11    1.17  K.Nakamura       [E_本稼動_08743] 受注あり、出荷なし時の受注ステータス見直し
 *  2014/03/17    1.18  K.Kiru           [E_本稼動_11681] PT対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** プロファイル取得例外 ***
  global_profile_expt         EXCEPTION;
  --*** 業務日付取得例外 ***
  global_proc_date_expt       EXCEPTION;
  --*** データ取得エラー例外ハンドラ ***
  global_select_data_expt     EXCEPTION;
  --*** 処理対象データ登録例外 ***
  global_data_insert_expt     EXCEPTION;
  --*** SVF起動例外 ***
  global_svf_excute_expt      EXCEPTION;
  --*** 処理対象データロック例外 ***
  global_data_lock_expt       EXCEPTION;
  --*** 処理対象データロック例外 ***
  global_insert_data_expt     EXCEPTION;
  --*** 処理対象データ削除例外 ***
  global_delete_data_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS008A03R';        -- パッケージ名
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS008A03R';        -- コンカレント名
--
  -- 帳票出力関連
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS008A03R';        -- 帳票ＩＤ
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS008A03S.xml';    -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS008A03S.vrq';    -- クエリー様式ファイル名
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                   -- 出力区分(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                -- 拡張子(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';               -- 販物短縮アプリ名
--
  --メッセージ
  cv_msg_parameter_note     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11701';    -- パラメータ出力メッセージ
  cv_msg_profile_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00004';    -- プロファイル取得エラー
  cv_msg_process_date_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00014';    -- 業務日付取得エラー
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00018';    -- 明細0件用メッセージ
  cv_msg_select_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00013';    -- データ抽出エラーメッセージ
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00010';    -- データ登録エラーメッセージ
  cv_msg_api_err            CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00017';    -- APIエラーメッセージ
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00001';    -- ロックエラー
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00012';    -- データ削除エラーメッセージ
--
  --トークン名
  cv_tkn_nm_param_name      CONSTANT  VARCHAR2(100) := 'PARAM1';              -- パラメータ：拠点コード
  cv_tkn_nm_prof_name       CONSTANT  VARCHAR2(100) := 'PROFILE';             -- プロファイル名称
  cv_tkn_nm_api_name        CONSTANT  VARCHAR2(100) := 'API_NAME';            -- API名称
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) := 'TABLE_NAME';          -- テーブル名称
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) := 'KEY_DATA';            -- キーデータ
  cv_tkn_nm_lock_table_name CONSTANT  VARCHAR2(100) := 'TABLE';               -- テーブル名称
--
  --トークン値
  cv_msg_vl_api_name        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00041';    -- SVF起動API
  cv_msg_vl_org_name        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00047';    -- MO:営業単位
  cv_msg_vl_max_date_name   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00056';    -- XXCOS:MAX日付
  cv_msg_vl_request_id      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11702';    -- リクエストID
  cv_msg_vl_table_name      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11703';    -- 直送受注例外データリスト帳票ワークテーブル
  cv_msg_vl_lookup_name     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00066';    -- クイックコードマスタ
-- ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
  cv_msg_vl_trans_st_dt     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00196';    -- XXCOS:工場直送例外リスト対象開始年月日
-- ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
-- ******************** 2009/12/11 1.12 N.Maeda ADD START ****************************** --
  cv_msg_vl_closed_month    CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-11704';    -- XXCOS:工場直送例外リストCLOSED取得月数
-- ******************** 2009/12/11 1.12 N.Maeda ADD  END  ****************************** --
--
  --プロファイル
  cv_prof_org_id            CONSTANT  VARCHAR2(100) := 'ORG_ID';              -- 営業単位
  cv_prof_max_date          CONSTANT  VARCHAR2(100) := 'XXCOS1_MAX_DATE';     -- プロファイル名(MAX日付)
-- ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
  cv_prof_trans_st_dt       CONSTANT  VARCHAR2(100) := 'XXCOS1_TRANS_START_YMD'; -- 工場直送例外リスト対象開始年月日
-- ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
-- ******************** 2009/12/11 1.12 N.Maeda ADD START ****************************** --
  cv_prof_target_closed_mon CONSTANT  VARCHAR2(100) := 'XXCOS1_TARGET_CLOSED_MONTH'; -- XXCOS:工場直送例外リストCLOSED取得月数
-- ******************** 2009/12/11 1.12 N.Maeda ADD  END  ****************************** --
--
  --クイックタイプ
  -- 保管場所分類直送特定マスタ
  cv_hokan_direct_type_mst  CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_HOKAN_DIRECT_TYPE_MST';
  -- 非在庫品目コード
  cv_no_inv_item_code       CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_NO_INV_ITEM_CODE';
  -- 重量換算マスタ
  cv_weight_uom_cnv_mst     CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_WEIGHT_UOM_CNV';
--
  --クイックコード
  -- 保管場所分類直送特定マスタ
  cv_hokan_direct_11        CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_DIRECT_11';
--
  -- 日付フォーマット
  cv_yyyymmdd               CONSTANT  VARCHAR2(8)   := 'YYYYMMDD';               -- YYYYMMDD
  cv_fmt_date               CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';             -- YYYY/MM/DD
  cv_yyyymmddhhmiss         CONSTANT  VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- YYYY/MM/DD HH24:MI:SS
--
  -- Y/Nフラグ
  cv_yes_flg                CONSTANT  VARCHAR2(1)   := 'Y';                   -- Yes
  cv_no_flg                 CONSTANT  VARCHAR2(1)   := 'N';                   -- No
--
  -- パラメータ：拠点ALL
  cv_base_all               CONSTANT  VARCHAR2(3)   := 'ALL';                 -- 商品部全量出力判定
--
  -- 顧客区分
  cv_party_type_1           CONSTANT  VARCHAR2(1)   := '1';                   -- 顧客区分：拠点
--
  -- 受注ステータス
  cv_status_booked          CONSTANT  VARCHAR2(10)  := 'BOOKED';              -- 記帳済み
  cv_status_closed          CONSTANT  VARCHAR2(10)  := 'CLOSED';              -- クローズ
  cv_status_cancelled       CONSTANT  VARCHAR2(10)  := 'CANCELLED';           -- 取消
--
  -- 受注ヘッダアドオンステータス
  cv_h_add_status_04        CONSTANT  VARCHAR2(2)   := '04';                  -- 出荷実績計上済
  cv_h_add_status_99        CONSTANT  VARCHAR2(2)   := '99';                  -- 取消
--
  -- 受注明細タイプ
  cv_order                  CONSTANT  VARCHAR2(10)  := 'ORDER';               -- 受注
--
  -- 調査など例外抽出のSQLを特定する為に項目。調査時は値をセットして下さい。
  -- データ区分
-- *********** 2009/11/26 1.11 N.Maeda MOD START *********** --
---- ******************** 2009/10/05 1.9 K.Satomura MOD START ******************************* --
--  --cv_data_class_1           CONSTANT  VARCHAR2(1)   := '';                   -- 例外１取得ＳＱＬ
--  --cv_data_class_2           CONSTANT  VARCHAR2(1)   := '';                   -- 例外２取得ＳＱＬ
--  --cv_data_class_3           CONSTANT  VARCHAR2(1)   := '';                   -- 例外３－１取得ＳＱＬ
--  --cv_data_class_4           CONSTANT  VARCHAR2(1)   := '';                   -- 例外３－２取得ＳＱＬ
--  --cv_data_class_5           CONSTANT  VARCHAR2(1)   := '';                   -- 例外４取得ＳＱＬ
--  --cv_data_class_6           CONSTANT  VARCHAR2(1)   := '';                   -- 例外５取得ＳＱＬ
--  cv_data_class_1           CONSTANT  VARCHAR2(1)   := '1';                   -- 例外１取得ＳＱＬ
--  cv_data_class_2           CONSTANT  VARCHAR2(1)   := '2';                   -- 例外２取得ＳＱＬ
--  cv_data_class_3           CONSTANT  VARCHAR2(1)   := '3';                   -- 例外３－１取得ＳＱＬ
--  cv_data_class_4           CONSTANT  VARCHAR2(1)   := '4';                   -- 例外３－２取得ＳＱＬ
--  cv_data_class_5           CONSTANT  VARCHAR2(1)   := '5';                   -- 例外４取得ＳＱＬ
--  cv_data_class_6           CONSTANT  VARCHAR2(1)   := '6';                   -- 例外５取得ＳＱＬ
---- ******************** 2009/10/05 1.9 K.Satomura MOD END   ******************************* --
  cv_data_class_1           CONSTANT  VARCHAR2(1)   := '';                   -- 例外１取得ＳＱＬ
  cv_data_class_2           CONSTANT  VARCHAR2(1)   := '';                   -- 例外２取得ＳＱＬ
  cv_data_class_3           CONSTANT  VARCHAR2(1)   := '';                   -- 例外３－１取得ＳＱＬ
  cv_data_class_4           CONSTANT  VARCHAR2(1)   := '';                   -- 例外３－２取得ＳＱＬ
  cv_data_class_5           CONSTANT  VARCHAR2(1)   := '';                   -- 例外４取得ＳＱＬ
  cv_data_class_6           CONSTANT  VARCHAR2(1)   := '';                   -- 例外５取得ＳＱＬ
-- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
  cv_data_class_7           CONSTANT  VARCHAR2(1)   := '';                   -- 例外６取得ＳＱＬ
-- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
  cv_user_lang              CONSTANT  fnd_lookup_values.language%TYPE := USERENV( 'LANG' ); -- 'JA'
-- *********** 2009/11/26 1.11 N.Maeda MOD  END  *********** --
-- ******* 2010/03/25 1.14 N.Maeda ADD START ****** --
  cv_key_connect            CONSTANT  VARCHAR2(1)   := ',';
  cv_date_type_1            CONSTANT  VARCHAR2(1)   := '1';
  cv_date_type_2            CONSTANT  VARCHAR2(1)   := '2';
-- ******* 2010/03/25 1.14 N.Maeda ADD  END  ****** --
--
--****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
  cn_ship_zero              CONSTANT  NUMBER        := 0;                    -- 出荷実績0
--****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
-- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
  cn_order_sum_zero         CONSTANT  NUMBER        := 0;                    -- 受注数量0
-- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
-- ******************** 2009/12/11 1.12 N.Maeda ADD START ****************************** --
  cv_month                  CONSTANT  VARCHAR2(100) := 'MONTH';
-- ******************** 2009/12/11 1.12 N.Maeda ADD  END  ****************************** --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 帳票ワーク用テーブル型定義
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_direct_list%ROWTYPE INDEX BY BINARY_INTEGER;
--
-- ******* 2010/03/25 1.14 N.Maeda ADD START ****** --
  TYPE g_sum_rpt_data_ttype IS TABLE OF xxcos_rep_direct_list%ROWTYPE INDEX BY VARCHAR2(2000);
  TYPE g_work_type_rec IS RECORD
    (
         ooa1_deliver_requested_no    oe_order_lines_all.packing_instructions%TYPE
        ,ooa1_item_code               oe_order_lines_all.ordered_item%TYPE
        ,ooa1_order_quantity          NUMBER
        ,ooa1_line_id                 oe_order_lines_all.line_id%TYPE
        ,ooa2_line_no                 xxwsh_order_lines_all.order_line_number%TYPE
        ,ooa2_arrival_date            xxwsh_order_headers_all.arrival_date%TYPE
        ,ooa2_deliver_actual_quantity xxwsh_order_lines_all.shipped_quantity%TYPE
        ,ooa2_uom_code                xxwsh_order_lines_all.uom_code%TYPE
        ,data_type                    VARCHAR2(1)
    );
  TYPE g_work_tab IS TABLE OF g_work_type_rec INDEX BY PLS_INTEGER;
--
  TYPE g_work_check_type_rec IS RECORD
    (
         ooa1_deliver_requested_no    oe_order_lines_all.packing_instructions%TYPE
        ,ooa1_item_code               oe_order_lines_all.ordered_item%TYPE
        ,ooa1_order_quantity          NUMBER
        ,ooa1_line_id                 oe_order_lines_all.line_id%TYPE
        ,ooa1_schedule_dlv_date       oe_order_lines_all.request_date%TYPE
        ,ooa1_min_schedule_inspect_date oe_order_lines_all.attribute4%TYPE
        ,ooa1_max_schedule_inspect_date oe_order_lines_all.attribute4%TYPE
        ,ooa2_line_no                 xxwsh_order_lines_all.order_line_number%TYPE
        ,ooa2_arrival_date            xxwsh_order_headers_all.arrival_date%TYPE
        ,ooa2_deliver_actual_quantity xxwsh_order_lines_all.shipped_quantity%TYPE
        ,ooa2_uom_code                xxwsh_order_lines_all.uom_code%TYPE
    );
  TYPE g_work_check_tab IS TABLE OF g_work_check_type_rec INDEX BY PLS_INTEGER;
--
  TYPE g_work_get_data_rec_type_rec IS RECORD
    (
      base_code                xxcmm_cust_accounts.delivery_base_code%TYPE
     ,base_name                hz_cust_accounts.account_name%TYPE
     ,order_number             oe_order_headers_all.order_number%TYPE       -- 受注ﾍｯﾀﾞ.受注番号
     ,order_line_no            oe_order_lines_all.line_number%TYPE          -- 受注明細.明細番号
     ,line_no                  oe_order_lines_all.line_id%TYPE              -- 受注明細ｱﾄﾞｵﾝ.明細番号
     ,deliver_requested_no     oe_order_lines_all.packing_instructions%TYPE -- 受注明細.梱包指示
     ,deliver_from_whse_number oe_order_lines_all.subinventory%TYPE         -- 受注明細.保管場所
     ,deliver_from_whse_name   mtl_secondary_inventories.description%TYPE   -- 保管場所.保管場所名称
     ,customer_number          hz_cust_accounts.account_number%TYPE         -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ
     ,customer_name            hz_cust_accounts.account_name%TYPE           -- 顧客ﾏｽﾀ.顧客名称
     ,item_code                oe_order_lines_all.ordered_item%TYPE         -- 受注明細.受注品目
     ,item_name                xxcmn_item_mst_b.item_short_name%TYPE        -- OPM品目ｱﾄﾞｵﾝ
     ,schedule_dlv_date        oe_order_lines_all.request_date%TYPE         -- 受注明細.要求日
     ,schedule_inspect_date    oe_order_lines_all.attribute4%TYPE           -- 受注明細.検収予定日
     ,arrival_date             xxwsh_order_headers_all.arrival_date%TYPE    -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日
     ,order_quantity           NUMBER                                       -- 受注明細.受注数量
     ,deliver_actual_quantity  xxwsh_order_lines_all.shipped_quantity%TYPE  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量
     ,uom_code                 oe_order_lines_all.order_quantity_uom%TYPE   -- 受注明細.受注単位
     ,output_quantity          NUMBER                                       -- 差異数
    );
  TYPE g_work_get_data_rec_tab IS TABLE OF g_work_get_data_rec_type_rec INDEX BY PLS_INTEGER;
-- ******* 2010/03/25 1.14 N.Maeda ADD  END  ****** --
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 帳票ワーク内部テーブル
  gt_rpt_data_tab        g_rpt_data_ttype;
-- ******* 2010/03/15 1.15 N.Maeda ADD START ****** --
  gt_work_tab_err_quantity        g_work_tab;
  gt_work_tab_err_req_insp_date   g_work_check_tab;
  gt_work_tab_err_item            g_work_get_data_rec_tab;
  gt_rpt_data_sum_tab             g_sum_rpt_data_ttype;       --データサマリ用
-- ******* 2010/03/15 1.15 N.Maeda ADD  END  ****** --
--
  -- 初期取得
  gd_process_date        DATE;                     -- 業務日付
  gn_org_id              NUMBER;                   -- 営業単位
  gd_max_date            DATE;                     -- MAX日付
--
  --保管場所分類
  gv_subinventory_class  VARCHAR2(2);
--
-- ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
  gd_trans_start_date    DATE; -- 工場直送例外リスト対象開始年月日
-- ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
--
-- ******************** 2009/12/11 1.12 N.Maeda ADD START ****************************** --
  gd_target_closed_month DATE;  -- 工場直送例外リストCLOSED取得月
-- ******************** 2009/12/11 1.12 N.Maeda ADD  END  ****************************** --
-- 2011/03/08 Ver.1.15 Add K.Kiriu Start
  gd_trans_end_date      DATE;  -- ALL用対象終了年月日
-- 2011/03/08 Ver.1.15 Add K.Kiriu End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code  IN  VARCHAR2,     --   1.拠点コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_para_msg      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
-- ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
    lv_trans_start_date VARCHAR2(1000);
-- ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
--
-- ******************** 2009/12/11 1.12 N.Maeda ADD START ****************************** --
    lv_target_closed_month VARCHAR2(1000);
-- ******************** 2009/12/11 1.12 N.Maeda ADD  END  ****************************** --
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
    --==================================
    -- 1.パラメータ出力
    --==================================
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcos_short_name,
                     iv_name               => cv_msg_parameter_note,
                     iv_token_name1        => cv_tkn_nm_param_name,
                     iv_token_value1       => iv_base_code
                   );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --==================================
    -- 2.MO:営業単位
    --==================================
    gn_org_id := FND_PROFILE.VALUE( cv_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_msg_vl_org_name
                         );
      RAISE global_profile_expt;
    END IF;
--
    --==================================
    -- 3.XXCOS:MAX日付
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_msg_vl_max_date_name
                         );
--
      RAISE global_profile_expt;
    END IF;
    gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 4.業務日付取得
    --==================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_expt;
    END IF;
--
    --==================================
    -- 5.参照コード取得（保管場所分類直送特定マスタ）
    --==================================
    BEGIN
      SELECT
        flv.meaning
      INTO
        gv_subinventory_class
      FROM
-- ********** 2009/11/26 1.11 N.Maeda DEL START ********** --
--        fnd_application               fa,
--        fnd_lookup_types              flt,
-- ********** 2009/11/26 1.11 N.Maeda DEL  END  ********** --
        fnd_lookup_values             flv
      WHERE
-- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_short_name
--      AND flv.lookup_type             = cv_hokan_direct_type_mst
          flv.lookup_type             = cv_hokan_direct_type_mst
-- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
      AND flv.lookup_code             = cv_hokan_direct_11
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = cv_yes_flg
-- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
--      AND flv.language                = USERENV( 'LANG' )
      AND flv.language                = cv_user_lang
-- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
      ;
--
   EXCEPTION
     WHEN OTHERS THEN
       lv_table_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_short_name,
                          iv_name        => cv_msg_vl_lookup_name
                        );
       RAISE global_select_data_expt;
   END;
--
-- ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
    --==============================================================
    -- 6.プロファイルの取得(XXCOS:工場直送例外リスト対象開始年月日)
    --==============================================================
    lv_trans_start_date := fnd_profile.value(cv_prof_trans_st_dt);
    --
    -- プロファイルが取得できない場合はエラー
    IF ( lv_trans_start_date IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_msg_vl_trans_st_dt
                         );
      --
      RAISE global_profile_expt;
      --
    END IF;
    --
    gd_trans_start_date := TO_DATE(lv_trans_start_date, cv_fmt_date);
    --
-- ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
--
-- ******************** 2009/12/11 1.12 N.Maeda ADD START ****************************** --
    --==============================================================
    -- 6.プロファイルの取得(XXCOS:工場直送例外リストCLOSED取得月数)
    --==============================================================
    lv_target_closed_month := fnd_profile.value( cv_prof_target_closed_mon );
    --
    -- プロファイルが取得できない場合はエラー
    IF ( lv_target_closed_month IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name,
                           iv_name        => cv_msg_vl_closed_month
                         );
      --
      RAISE global_profile_expt;
      --
    END IF;
    --
    -- 受注例外取得開始日設定(CLOSED分)
    gd_target_closed_month := ADD_MONTHS (  TRUNC ( gd_process_date , cv_month ) 
                                           , ( TO_NUMBER( lv_target_closed_month ) * -1 )
                                         );
    --
-- ******************** 2009/12/11 1.12 N.Maeda ADD  END  ****************************** --
-- 2011/03/08 Ver.1.15 Add K.Kiriu Start
    --ALL用対象終了年月日取得(業務日付の月初)
    gd_trans_end_date := TRUNC( gd_process_date, cv_month );
-- 2011/03/08 Ver.1.15 Add K.Kiriu End
--
  EXCEPTION
    -- プロファイル取得例外
    WHEN global_profile_expt THEN
--
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcos_short_name,
                     iv_name               => cv_msg_profile_err,
                     iv_token_name1        => cv_tkn_nm_prof_name,
                     iv_token_value1       => lv_profile_name
                   );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- 業務日付取得例外
    WHEN global_proc_date_expt THEN
--
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application         => cv_xxcos_short_name,
                     iv_name                => cv_msg_process_date_err
                   );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- データ取得例外
    WHEN global_select_data_expt THEN
--
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application         => cv_xxcos_short_name,
                     iv_name                => cv_msg_select_err,
                     iv_token_name1         => cv_tkn_nm_table_name,
                     iv_token_value1        => lv_table_name,
                     iv_token_name2         => cv_tkn_nm_key_data,
                     iv_token_value2        => NULL
                   );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 例外データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_base_code  IN  VARCHAR2,     --   1.拠点コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_key_info      VARCHAR2(5000);
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
-- ************* 2010/03/12 1.15 N.Maeda ADD START ************* --
    lv_key_index      VARCHAR2(2000);
    lv_next_key_index VARCHAR2(2000);
    lv_exi_data       VARCHAR2(1);
    --
    lt_order_number          oe_order_headers_all.order_number%TYPE;
    lt_line_number           oe_order_lines_all.line_number%TYPE;
    lt_subinventory_code     oe_order_lines_all.subinventory%TYPE;
    lt_subinventory_name     mtl_secondary_inventories.description%TYPE;
    lt_item_code             oe_order_lines_all.ordered_item%TYPE;
    lt_item_name             xxcmn_item_mst_b.item_short_name%TYPE;
    lt_schedule_dlv_date     oe_order_lines_all.request_date%TYPE;
    lt_schedule_inspect_date oe_order_lines_all.attribute4%TYPE;
    lt_delivery_base_code    xxcmm_cust_accounts.delivery_base_code%TYPE;
    lt_base_name             hz_cust_accounts.account_name%TYPE;
    lt_customer_number       hz_cust_accounts.account_number%TYPE;
    lt_customer_name         hz_cust_accounts.account_name%TYPE;
    lt_line_id               oe_order_lines_all.line_id%TYPE;
    ln_order_quantity        NUMBER;
-- ************* 2010/03/12 1.15 N.Maeda ADD  END  ************* --
--
    -- *** ローカル・カーソル ***
--
-- ************* 2010/03/25 1.14 N.Maeda MOD START ************* --
--    CURSOR data_cur
--    IS
--  --** ■例外１取得SQL
--      SELECT
--         ooa1.base_code                  base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,ooa1.base_name                  base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,ooa1.order_number               order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,ooa1.order_line_no              order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,ooa2.line_no                    line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
---- ******************** 2009/10/07 1.10 K.Satomura MOD START ******************************* --
----        ,ooa1.deliver_requested_no       deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--        ,SUBSTRB(ooa1.deliver_requested_no, 1, 12) deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
---- ******************** 2009/10/07 1.10 K.Satomura MOD END   ******************************* --
--        ,ooa1.deliver_from_whse_number   deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
--        ,ooa1.deliver_from_whse_name     deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,ooa1.customer_number            customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
--        ,ooa1.customer_name              customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--        ,ooa1.item_code                  item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--        ,ooa1.item_name                  item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,TRUNC( ooa1.schedule_dlv_date ) schedule_dlv_date        -- 受注ﾍｯﾀﾞ.着日               ：納品予定日
--        ,ooa1.schedule_inspect_date      schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,ooa2.arrival_date               arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--        ,ooa1.order_quantity             order_quantity           -- 受注明細.受注数量           ：受注数
--        ,ooa2.deliver_actual_quantity    deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
---- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
----        ,ooa1.uom_code                   uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--        ,ooa2.uom_code                   uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
---- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
--        ,ooa1.order_quantity
--          - ooa2.deliver_actual_quantity output_quantity          -- 差異数
--        ,cv_data_class_1                 data_class               -- 例外データ１                ：データ区分
--      FROM
--        -- ****** 例外１営業サブクエリ：ooa1 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--             /*+
--               LEADING(ooha)
--               INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--               INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--               USE_NL( ooha hca  )
--               USE_NL( oola mtsi )
--             */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--            ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--            ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--            ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
--            ,oola.packing_instructions  deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
--            ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
--            ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--            ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
--            ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--            ,NVL( oola.attribute6, oola.ordered_item )
--                                        item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
--            ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--            ,oola.request_date          schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
--            ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--            ,ooas.order_quantity        order_quantity           -- 受注明細.受注数量           ：受注数
--            ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
--          FROM
--             oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--            ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
--            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--            ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
--            ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--            ,ic_item_mst_b              iimb  -- OPM品目
--            ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--            -- 最終歴用サブクエリ：ooal
--            ,( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                 /*+
--                   LEADING( ooha )
--                   INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                   INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--                   INDEX(xca xxcmm_cust_accounts_pk)
--                   USE_NL( ooha hca  )
--                   USE_NL( oola mtsi )
--                 */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
----MIYATA DELETE 明細IDでﾍｯﾀﾞ／明細共に特定できるので不要
----                  MAX(ooha.header_id)        header_id   -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID
----                 ,MAX(line_id)               line_id     -- 受注明細.受注明細ID
--                 MAX( line_id )              line_id     -- 受注明細.受注明細ID
----MIYATA DELETE
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
----               AND  ooha.flow_status_code  =  cv_status_booked               -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
----                                                                             -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
----               AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
--               AND  ooha.flow_status_code  IN  ( cv_status_booked , cv_status_closed )    -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED' , 'CLOSED' )
--                                                                             -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--               AND  oola.flow_status_code  <> cv_status_cancelled
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--               AND OOLA.ORG_ID                = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                    fnd_application    fa
----                                   ,fnd_lookup_types   flt
----                                   ,fnd_lookup_values  flv
--                                   fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                      fa.application_id           = flt.application_id
----                                 AND  flt.lookup_type             = flv.lookup_type
----                                 AND  fa.application_short_name   = cv_xxcos_short_name
----                                 AND  flv.lookup_type             = cv_no_inv_item_code
--                                      flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 AND  flv.start_date_active      <= gd_process_date
--                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                 AND flv.language                = USERENV( 'LANG' )
--                                 AND flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
------ ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
----               AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
------ ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--               AND  ( ( oola.flow_status_code = cv_status_closed
--                      AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--                    OR ( oola.flow_status_code <> cv_status_closed
--                      AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--                    )
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--             ) ooal
--             ,
--             -- サマリー用サブクエリ：ooas
--             ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                  /*+
--                    LEADING(ooha)
--                    INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    INDEX(ooha XXCOS_OE_ORDER_LINES_ALL_N23)
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( ooha hca  )
--                    USE_NL( oola mtsi otta ottt )
--                  */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
--                 ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
--                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                        * CASE oola.order_quantity_uom
--                          WHEN msib.primary_unit_of_measure THEN 1
--                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                          ELSE NVL( xicv.conversion_rate, 0 )
--                        END
--                  ) AS order_quantity
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
--                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
--                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
--                 ,xxcos_item_conversions_v   xicv        -- 品目換算View
--                 ,(
--                   SELECT
--                       flv.meaning      AS UOM_CODE
--                     , flv.description  AS CNV_VALUE
--                   FROM
---- ********** 2009/11/26 1.11 N.Maeda DEL START ********** --
----                     fnd_application   fa,
----                     fnd_lookup_types  flt,
---- ********** 2009/11/26 1.11 N.Maeda DEL  END  ********** --
--                     fnd_lookup_values flv
--                   WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                         fa.application_id         = flt.application_id
----                     AND flt.lookup_type           = flv.lookup_type
----                     AND fa.application_short_name = cv_xxcos_short_name
----                     AND flv.enabled_flag          = cv_yes_flg
----                     AND flv.language                = USERENV( 'LANG' )
--                         flv.enabled_flag          = cv_yes_flg
--                     AND flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                     AND flv.start_date_active    <= gd_process_date
--                     AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
--                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
--                 ) item_cnv
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----               AND  ottt.language            = USERENV( 'LANG' )             -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--               AND  ottt.language            = cv_user_lang             -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                    fnd_application    fa
----                                   ,fnd_lookup_types   flt
----                                   ,fnd_lookup_values  flv
--                                   fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                      fa.application_id           = flt.application_id
----                                 AND  flt.lookup_type             = flv.lookup_type
----                                 AND  fa.application_short_name   = cv_xxcos_short_name
----                                 AND  flv.lookup_type             = cv_no_inv_item_code
--                                      flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 AND  flv.start_date_active      <= gd_process_date
--                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                 AND  flv.language                = USERENV( 'LANG' )
--                                 AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                             --     = Disc品目.品目コード
--               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
--               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
--               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
--               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
---- ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
--               AND  TRUNC(oola.request_date)   >= TRUNC(gd_trans_start_date)
---- ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--             ) ooas
--          WHERE
--               ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--          AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--          AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--          AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--          AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
----          AND  ooha.flow_status_code  =  cv_status_booked             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
----                                                                      -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
----          AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
--          AND  ooha.flow_status_code  IN ( cv_status_booked ,cv_status_closed )   -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED' , 'CLOSED' )
--          AND  oola.flow_status_code  <> cv_status_cancelled          -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--          AND  oola.org_id                = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--          AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
--          AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--          AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--          AND  xca.delivery_base_code  =  DECODE( iv_base_code
--                                                 ,cv_base_all
--                                                 ,xca.delivery_base_code
--                                                 ,iv_base_code )
--          AND  hca2.customer_class_code  =  cv_party_type_1               -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--          AND  hca2.account_number       =  xca.delivery_base_code        -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--          AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no   -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
--          AND  iimb.item_id              =  ximb.item_id                  -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--          AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--          AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
----MIYATA DELETE 明細IDでﾍｯﾀﾞ／明細共に特定できるので不要
----          AND  ooha.header_id             = ooal.header_id                -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 最終歴用.受注ﾍｯﾀﾞID
----MIYATA DELETE
--          AND  oola.line_id               = ooal.line_id                  -- 受注明細.受注明細ID = 最終歴用.受注明細ID
--          AND  oola.packing_instructions  = ooas.deliver_requested_no     -- 例外１営業サブクエリ.出荷依頼No = サマリー用サブクエリ.出荷依頼No
--          AND  NVL( oola.attribute6, oola.ordered_item ) = ooas.item_code -- 例外１営業サブクエリ.品目コード = サマリー用サブクエリ.品目コード
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
------ ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
----          AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
------ ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--          AND  ( ( oola.flow_status_code = cv_status_closed
--                 AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--               OR ( oola.flow_status_code <> cv_status_closed
--                 AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--               )
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
--        )
--        ooa1,
--        -- ****** 例外１生産サブクエリ：ooa2 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--             /*+
--               INDEX(xca xxcmm_cust_accounts_pk)
--               USE_NL( xoha xola hca xca )
--             */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--            ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--            ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
----            ,xola.shipping_item_code    item_code                -- 受注明細ｱﾄﾞｵﾝ.出荷品目      ：品目ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--            ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--            ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
---- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
--            ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
---- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
--          FROM
--             xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--            ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--          WHERE
--               xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--          AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--          AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--          AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
---- ********** 2009/12/17 1.12 S.Tomita MOD START ********** --
----****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
----          AND  NVL( xola.shipped_quantity, cn_ship_zero ) != cn_ship_zero  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量が0以外
--          AND  xola.shipped_quantity IS NOT NULL
----****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
---- ********** 2009/12/17 1.12 S.Tomita MOD START ********** --
----MIYATA MODIFY
----          AND  xoha.customer_id          =   hca.cust_account_id       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--          AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
----MIYATA MODIFY
--          AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--          AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                    ,cv_base_all
--                                                    ,xca.delivery_base_code
--                                                    ,iv_base_code )
--        )
--        ooa2
--      WHERE
--           ooa1.deliver_requested_no =   ooa2.deliver_requested_no -- 例外１営業サブクエリ.出荷依頼No = 例外１生産サブクエリ.出荷依頼No
--      AND  ooa1.item_code            =   ooa2.item_code            -- 例外１営業サブクエリ.品目コード = 例外１生産サブクエリ.品目コード
--      AND                                                          -- 例外１営業サブクエリ.受注数 <> 例外１生産サブクエリ.出荷実績数
--        (  ooa1.order_quantity                 <>  ooa2.deliver_actual_quantity
--         OR                                                        -- 例外１営業サブクエリ.納品予定日 <> 例外１生産サブクエリ.着日
--           TRUNC( ooa1.schedule_dlv_date )     <>  ooa2.arrival_date
--         OR
--           (                                                       -- 例外１営業サブクエリ.納品予定日 =  例外１生産サブクエリ.着日
--             ( TRUNC( ooa1.schedule_dlv_date ) =   ooa2.arrival_date )
--             AND
--             ( ooa1.schedule_inspect_date IS NOT NULL )            -- 例外１営業サブクエリ.検収予定日 IS NOT NULL
--             AND                                                   -- 例外１営業サブクエリ.検収予定日 < 例外１生産サブクエリ.着日
--             ( TO_DATE( ooa1.schedule_inspect_date, cv_yyyymmddhhmiss ) < ooa2.arrival_date )
--           )
--        )
----
--      UNION
----
--  --** ■例外２取得SQL
--      SELECT
--         ooa1.base_code                  base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,ooa1.base_name                  base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,ooa1.order_number               order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,ooa1.order_line_no              order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,ooa2.line_no                    line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
---- ******************** 2009/10/07 1.10 K.Satomura MOD START ******************************* --
----        ,ooa1.deliver_requested_no       deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--        ,SUBSTRB(ooa1.deliver_requested_no, 1, 12) deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
---- ******************** 2009/10/07 1.10 K.Satomura MOD END   ******************************* --
--        ,ooa1.deliver_from_whse_number   deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
--        ,ooa1.deliver_from_whse_name     deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,ooa1.customer_number            customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
--        ,ooa1.customer_name              customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--        ,ooa1.item_code                  item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--        ,ooa1.item_name                  item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,TRUNC( ooa1.schedule_dlv_date ) schedule_dlv_date        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着日          ：納品予定日
--        ,ooa1.schedule_inspect_date      schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,ooa2.arrival_date               arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--        ,ooa3.order_quantity             order_quantity           -- 受注明細.受注数量           ：受注数
--        ,ooa2.deliver_actual_quantity    deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
---- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
----        ,ooa1.uom_code                   uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--        ,ooa2.uom_code                   uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
---- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
--        ,ooa3.order_quantity
--          - ooa2.deliver_actual_quantity output_quantity          -- 差異数
--        ,cv_data_class_2                 data_class               -- 例外データ２                ：データ区分
--      FROM
--        -- ****** 例外２営業サブクエリ：ooa1 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--             /*+
--               LEADING(ooha)
--               INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--               INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--               INDEX(mtsi mtl_secondary_inventories_u1 )
--               USE_NL( ooha hca  )
--               USE_NL( oola mtsi  )
--             */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--            ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--            ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--            ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
--            ,oola.packing_instructions  deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
--            ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
--            ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--            ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
--            ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--            ,NVL( oola.attribute6, oola.ordered_item )
--                                        item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
--            ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--            ,oola.request_date          schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
--            ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--            ,oola.ordered_quantity      order_quantity           -- 受注明細.受注数量           ：受注数
--            ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
--          FROM
--             oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--            ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
--            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--            ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
--            ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--            ,ic_item_mst_b              iimb  -- OPM品目
--            ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--            ,( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                 /*+
--                   LEADING(ooha)
--                   INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                   INDEX(MTSI MTL_SECONDARY_INVENTORIES_U1 )
--                   INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--                   USE_NL( ooha hca  )
--                   USE_NL( oola mtsi  )
--                 */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
----MIYATA DELETE 明細IDでﾍｯﾀﾞ／明細共に特定できるので不要
----                  MAX( ooha.header_id )      header_id   -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID
----                 ,MAX( line_id )             line_id     -- 受注明細.受注明細ID
--                 MAX( line_id )             line_id     -- 受注明細.受注明細ID
----MIYATA DELTE
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
----               AND  ooha.flow_status_code  =  cv_status_booked               -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
----                                                                             -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
----               AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
--               AND  ooha.flow_status_code  IN  ( cv_status_booked ,cv_status_closed )  -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED' , 'CLOSED' )
--               AND  oola.flow_status_code  <> cv_status_cancelled            -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--               AND oola.org_id                = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                    fnd_application    fa
----                                   ,fnd_lookup_types   flt
----                                   ,fnd_lookup_values  flv
--                                   fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                      fa.application_id           = flt.application_id
----                                 AND  flt.lookup_type             = flv.lookup_type
----                                 AND  fa.application_short_name   = cv_xxcos_short_name
----                                 AND  flv.lookup_type             = cv_no_inv_item_code
--                                      flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 AND  flv.start_date_active      <= gd_process_date
--                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                 AND  flv.language                = USERENV( 'LANG' )
--                                 AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
------ ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
----               AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
------ ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--               AND  ( ( oola.flow_status_code = cv_status_closed
--                      AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--                    OR ( oola.flow_status_code <> cv_status_closed
--                      AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--                    )
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--             )
--             ooal   -- 最終歴用サブクエリ
--          WHERE
--               ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--          AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--          AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--          AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--          AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
----          AND  ooha.flow_status_code  =  cv_status_booked             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
----                                                                      -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
----          AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
--          AND  ooha.flow_status_code  IN ( cv_status_booked , cv_status_closed )  -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--          AND  oola.flow_status_code  <> cv_status_cancelled          -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--          AND oola.org_id                = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--          AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
--          AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--          AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID   = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--          AND  xca.delivery_base_code  =  DECODE( iv_base_code
--                                                 ,cv_base_all
--                                                 ,xca.delivery_base_code
--                                                 ,iv_base_code )
--          AND  hca2.customer_class_code  =  cv_party_type_1              -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--          AND  hca2.account_number       =  xca.delivery_base_code       -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--          AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
--          AND  iimb.item_id              =  ximb.item_id                 -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--          AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--          AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
----MIYATA DELETE 明細IDでﾍｯﾀﾞ／明細共に特定できるので不要
----          AND  ooha.header_id             = ooal.header_id               -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 最終歴用ｻﾌﾞｸｴﾘ.受注ﾍｯﾀﾞID
----MIYATA DELETE
--          AND  oola.line_id               = ooal.line_id                 -- 受注明細.受注明細ID = 最終歴用ｻﾌﾞｸｴﾘ.受注明細ID
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
------ ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
----          AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
------ ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--          AND  ( ( oola.flow_status_code = cv_status_closed
--                 AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--               OR ( oola.flow_status_code <> cv_status_closed
--                 AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--               )
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
--        )
--        ooa1,
--        -- ****** 例外２生産サブクエリ：ooa2 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--             /*+
--             USE_NL( xoha xola hca xca )
--             */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--            ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--            ,xola.request_item_code       item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
----            ,xola.shipping_item_code    item_code                -- 受注明細ｱﾄﾞｵﾝ.出荷品目      ：品目ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--            ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
---- ******************** 2009/12/11 1.12 N.Maeda MOD START ****************************** --
------MIYATA MODIFY 出荷実績済みではないので数量に変更
------            ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
----            ,xola.quantity              deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.数量          ：出荷実績数
--            ,NVL( xola.shipped_quantity , cn_ship_zero ) deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
---- ******************** 2009/12/11 1.12 N.Maeda MOD  END  ****************************** --
---- ******************** 2009/07/27 1.8 N.Maeda MOD start ******************************* --
--            ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
---- ******************** 2009/07/27 1.8 N.Maeda MOD  end  ******************************* --
----MIYATA MODIFY
--          FROM
--             xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--            ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--          WHERE
--               xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--                                                                       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ NOT IN( 出荷実績計上済 , 取消 )
--          AND  xoha.req_status      NOT IN ( cv_h_add_status_04, cv_h_add_status_99 )
--          AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--          AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
----MIYATA MODIFY
----          AND  xoha.customer_id          =   hca.cust_account_id       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--          AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
----MIYATA MODIFY
--          AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
--          AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                    ,cv_base_all
--                                                    ,xca.delivery_base_code
--                                                    ,iv_base_code )
--        )
--        ooa2,
--        -- ****** 例外２数量サブクエリ：ooa3 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--             /*+
--               LEADING(ooha)
--               INDEX(ooha xxcos_oe_order_headers_all_n11)
--               USE_NL( oola hca xca msib xicv ottt otta mtsi )
--             */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
--            ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
--            ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                   * CASE oola.order_quantity_uom
--                     WHEN msib.primary_unit_of_measure THEN 1
--                     WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                     ELSE NVL( xicv.conversion_rate, 0 )
--                   END
--             ) AS order_quantity
--          FROM
--             oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--            ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--            ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--            ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--            ,mtl_system_items_b         msib        -- Disc品目（営業組織）
--            ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
--            ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
--            ,xxcos_item_conversions_v   xicv        -- 品目換算View
--            ,(
--              SELECT
--                  flv.meaning      AS UOM_CODE
--                , flv.description  AS CNV_VALUE
--              FROM
---- ********** 2009/11/26 1.11 N.Maeda DEL START ********** --
----                fnd_application   fa,
----                fnd_lookup_types  flt,
---- ********** 2009/11/26 1.11 N.Maeda DEL  END  ********** --
--                fnd_lookup_values flv
--              WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                    fa.application_id         = flt.application_id
----                AND flt.lookup_type           = flv.lookup_type
----                AND fa.application_short_name = cv_xxcos_short_name
----                AND flv.enabled_flag          = cv_yes_flg
----                AND flv.language              = USERENV( 'LANG' )
--                    flv.enabled_flag          = cv_yes_flg
--                AND flv.language              = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                AND flv.start_date_active    <= gd_process_date
--                AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
--                AND flv.lookup_type           = cv_weight_uom_cnv_mst
--            ) item_cnv
--          WHERE
--               ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--          AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--          AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--          AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----          AND  ottt.language            = USERENV( 'LANG' )             -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--          AND  ottt.language            = cv_user_lang             -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--          AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--          AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--          AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                        -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--          AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--          AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--          AND  oola.org_id                = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--          AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--          AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                              'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                            FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                               fnd_application    fa
----                              ,fnd_lookup_types   flt
----                              ,fnd_lookup_values  flv
--                              fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                            WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                 fa.application_id           = flt.application_id
----                            AND  flt.lookup_type             = flv.lookup_type
----                            AND  fa.application_short_name   = cv_xxcos_short_name
--                                 flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                            AND  flv.start_date_active      <= gd_process_date
--                            AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                            AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                            AND  flv.language                = USERENV( 'LANG' )
--                            AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                            AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                          )
--          AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--          AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                        -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--          AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                    ,cv_base_all
--                                                    ,xca.delivery_base_code
--                                                    ,iv_base_code )
--                                                                        -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                        --     = Disc品目.品目コード
--          AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
--          AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--          AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
--          AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
--          AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
---- ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
--          AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
---- ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--          GROUP BY
--             oola.packing_instructions
--            ,NVL( oola.attribute6, oola.ordered_item )
--        )
--        ooa3
--      WHERE
--           ooa1.deliver_requested_no       =  ooa2.deliver_requested_no -- 例外２営業サブクエリ.出荷依頼No = 例外２生産サブクエリ.出荷依頼No
--      AND  ooa1.item_code                  =  ooa2.item_code            -- 例外２営業サブクエリ.品目コード = 例外２生産サブクエリ.品目コード
--      AND  ooa1.deliver_requested_no       =  ooa3.deliver_requested_no -- 例外２営業サブクエリ.出荷依頼No = 例外２数量サブクエリ.出荷依頼No
--      AND  ooa1.item_code                  =  ooa3.item_code            -- 例外２営業サブクエリ.品目コード = 例外２数量サブクエリ.品目コード
--      AND  TRUNC( ooa1.schedule_dlv_date ) <  gd_process_date           -- 例外２営業サブクエリ.納品予定日(要求日) < A.1取得の業務日付
----
--      UNION
----
--  --** ■例外３－１取得SQL
--      SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--         /*+
--           LEADING(ooha)
--           INDEX(ooha xxcos_oe_order_headers_all_n11)
--           INDEX(oola xxcos_oe_order_lines_all_n23)
--           USE_NL( ooha hca  )
--           USE_NL( oola mtsi ottt otta )
--         */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--         xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,NULL                       line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
---- ******************** 2009/10/07 1.10 K.Satomura MOD START ******************************* --
----        ,oola.packing_instructions  deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
--        ,SUBSTRB(oola.packing_instructions, 1, 12) deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
---- ******************** 2009/10/07 1.10 K.Satomura MOD END   ******************************* --
--        ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
--        ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
--        ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--        ,NVL( oola.attribute6, oola.ordered_item )
--                                    item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
--        ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,TRUNC( oola.request_date ) schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
--        ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,NULL                       arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
----****************************** 2009/05/26 1.4 T.Kitajima MOD START ******************************--
----        ,oola.ordered_quantity      order_quantity           -- 受注明細.受注数量           ：受注数
--        ,oola.ordered_quantity * 
--          DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                                    order_quantity           -- 受注明細.受注数量           ：受注数
----****************************** 2009/05/26 1.4 T.Kitajima MOD  END  ******************************--
--        ,0                          deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--        ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
--        ,oola.ordered_quantity      output_quantity          -- 差異数
--        ,cv_data_class_3            data_class               -- 例外データ３－１            ：データ区分
--      FROM
--         oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--        ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
--        ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--        ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--        ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
--        ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--        ,ic_item_mst_b              iimb  -- OPM品目
--        ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
----****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
--        ,oe_transaction_types_tl    ottt  -- 受注取引タイプ（摘要）
--        ,oe_transaction_types_all   otta  -- 受注取引タイプマスタ
----****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
--      WHERE
--           ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--      AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
----****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
--      AND  oola.line_type_id        = ottt.transaction_type_id    -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--      AND  ottt.transaction_type_id = otta.transaction_type_id    -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----      AND  ottt.language            = USERENV( 'LANG' )           -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--      AND  ottt.language            = cv_user_lang           -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
----****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
--      AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--      AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--      AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
----      AND  ooha.flow_status_code  =  cv_status_booked             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
----                                                                  -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
----      AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
--      AND  ooha.flow_status_code  IN ( cv_status_booked , cv_status_closed ) -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--      AND  oola.flow_status_code  <> cv_status_cancelled          -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--      AND  oola.org_id                = gn_org_id
------ *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--      AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
--      AND  NOT EXISTS ( SELECT                                    -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                          'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                        FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                           fnd_application    fa
----                          ,fnd_lookup_types   flt
----                          ,fnd_lookup_values  flv
--                          fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                        WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
-----                             fa.application_id           = flt.application_id
-----                        AND  flt.lookup_type             = flv.lookup_type
-----                        AND  fa.application_short_name   = cv_xxcos_short_name
-----                        AND  flv.lookup_type             = cv_no_inv_item_code
--                             flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                        AND  flv.start_date_active      <= gd_process_date
--                        AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                        AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                        AND  flv.language                = USERENV( 'LANG' )
--                        AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                        AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                     )
--      AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--      AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                  -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--      AND  xca.delivery_base_code  =  DECODE( iv_base_code
--                                             ,cv_base_all
--                                             ,xca.delivery_base_code
--                                             ,iv_base_code )
--      AND  hca2.customer_class_code  =  cv_party_type_1              -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--      AND  hca2.account_number       =  xca.delivery_base_code       -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--      AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
--      AND  iimb.item_id              =  ximb.item_id                 -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--      AND  TRUNC( ximb.start_date_active )                   <= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--      AND NOT EXISTS(
--              SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--               /*+
--                 USE_NL( xoha xola hca xca mtsi )
--               */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                'X'                          exists_flag -- EXISTSﾌﾗｸﾞ
--              FROM
--                 xxwsh_order_headers_all     xoha        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--                ,xxwsh_order_lines_all       xola        -- 受注明細ｱﾄﾞｵﾝ
--                ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
--                ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
--              WHERE
--                   xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--              AND  xoha.req_status           <>  cv_h_add_status_99        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ <> 取消
--              AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--              AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
----MIYATA MODIFY
----              AND  xoha.customer_id          =   hca.cust_account_id       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--              AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
----MIYATA MODIFY
--              AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
--              AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                        ,cv_base_all
--                                                        ,xca.delivery_base_code
--                                                        ,iv_base_code )
--              AND  oola.packing_instructions =   xoha.request_no   -- 受注明細.梱包指示 = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No
--                                                                   -- NVL(受注明細.子コード,受注明細.受注品目) = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼品目
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--              AND  NVL( oola.attribute6, oola.ordered_item ) = xola.request_item_code
----              AND  NVL( oola.attribute6, oola.ordered_item ) = xola.shipping_item_code
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--              )
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
------ ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
----      AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
------ ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--        AND  ( ( oola.flow_status_code = cv_status_closed
--               AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--             OR ( oola.flow_status_code <> cv_status_closed
--               AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--             )
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
----
--      UNION
----
--  --** ■例外３－２取得SQL
--      SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--        /*+
--          ORDERED
--          INDEX(haou hr_all_organizaion_units_pk)
--          USE_NL( xoha xola iwm mil haou hca xca hca2 iimb ximb )
--        */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--         xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,NULL                       order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,NULL                       order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--        ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--        ,xoha.deliver_from          deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
---- *********** 2010/01/14 1.13 N.Maeda MOD START *********** --
----        ,xilv.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,mil.description            deliver_from_whse_name
---- *********** 2010/01/14 1.13 N.Maeda MOD  END  *********** --
--        ,xoha.customer_code         customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
--        ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--        ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
----        ,xola.shipping_item_code    item_code                -- 受注明細ｱﾄﾞｵﾝ.出荷品目      ：品目ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--        ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,NULL                       schedule_dlv_date        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着日          ：納品予定日
--        ,NULL                       schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--        ,0                          order_quantity           -- 受注明細.受注数量           ：受注数
--        ,NVL( xola.shipped_quantity, 0 )
--                                    deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--        ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--        ,0 - NVL( xola.shipped_quantity, 0 )
--                                    output_quantity          -- 差異数
--        ,cv_data_class_4            data_class               -- 例外データ３－２            ：データ区分
--      FROM
---- *********** 2010/01/14 1.13 N.Maeda MOD START *********** --
----         xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
----        ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
----        ,xxcmn_item_locations2_v    xilv  -- OPM保管場所ﾏｽﾀ
----        ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
----        ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
----        ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
----        ,ic_item_mst_b              iimb  -- OPM品目
----        ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--         xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--        ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--        ,inv.mtl_item_locations        mil
--        ,hr.hr_all_organization_units  haou
--        ,gmi.ic_whse_mst               iwm
--        ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--        ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--        ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--        ,ic_item_mst_b              iimb  -- OPM品目
--        ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
---- *********** 2010/01/14 1.13 N.Maeda MOD  END  *********** --
--      WHERE
--           xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--      AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--      AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--      AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
----****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
--      AND NVL( xola.shipped_quantity, cn_ship_zero ) != cn_ship_zero -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量が0以外
----****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
---- *********** 2010/01/14 1.13 N.Maeda MOD START *********** --
----      AND  xoha.deliver_from         =   xilv.segment1             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所 = OPM保管場所ﾏｽﾀ.保管倉庫コード
----      AND  xilv.date_from                            <= gd_process_date  -- OPM保管場所ﾏｽﾀ.組織有効開始日 <= 業務日付
----      AND  TRUNC( NVL( xilv.date_to, gd_max_date ) ) >= gd_process_date  -- OPM保管場所ﾏｽﾀ.組織有効開始日 >= 業務日付
--      AND     iwm.mtl_organization_id = haou.organization_id
--      AND     haou.organization_id    = mil.organization_id
--      AND     XOHA.DELIVER_FROM   = mil.segment1
--      AND     haou.date_from         <= gd_process_date
--      AND     TRUNC( NVL( haou.date_to, gd_process_date ) ) >= gd_process_date
---- *********** 2010/01/14 1.13 N.Maeda MOD  END  *********** --
----MIYATA MODIFY
----      AND  xoha.customer_id          =   hca.cust_account_id       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--      AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
----MIYATA MODIFY
--      AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
--      AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                ,cv_base_all
--                                                ,xca.delivery_base_code
--                                                ,iv_base_code )
--      AND  hca2.customer_class_code  =  cv_party_type_1            -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--      AND  hca2.account_number       =  xca.delivery_base_code     -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--      AND  xola.request_item_code   =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = OPM品目.品目ｺｰﾄﾞ
----      AND  xola.shipping_item_code   =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.出荷品目 = OPM品目.品目ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--      AND  iimb.item_id              =  ximb.item_id               -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--      AND  TRUNC( ximb.start_date_active )                   <= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--      AND NOT EXISTS(
--              SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                /*+
--                USE_NL( ooha oola hca xca mtsi )
--                */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                'X'                         exists_flag -- EXISTSﾌﾗｸﾞ
--              FROM
--                 oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--              WHERE
--                   ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--              AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--              AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--              AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--              AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                            -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--              AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--              AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--              AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--              AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                  'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                   fnd_application    fa
----                                  ,fnd_lookup_types   flt
----                                  ,fnd_lookup_values  flv
--                                  fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
-----                                     fa.application_id           = flt.application_id
-----                                AND  flt.lookup_type             = flv.lookup_type
-----                                AND  fa.application_short_name   = cv_xxcos_short_name
-----                                AND  flv.lookup_type             = cv_no_inv_item_code
--                                     flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                AND  flv.start_date_active      <= gd_process_date
--                                AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                AND  flv.language                = USERENV( 'LANG' )
--                                AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                              )
--              AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--              AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                            -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--              AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                        ,cv_base_all
--                                                        ,xca.delivery_base_code
--                                                        ,iv_base_code )
--              AND  xoha.request_no            =  oola.packing_instructions -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No = 受注明細.梱包指示
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--                                                                           -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = NVL(受注明細.子コード,受注明細.受注品目)
--              AND  xola.request_item_code    =  NVL( oola.attribute6, oola.ordered_item )
----                                                                           -- 受注明細ｱﾄﾞｵﾝ.出荷品目 = NVL(受注明細.子コード,受注明細.受注品目)
----              AND  xola.shipping_item_code    =  NVL( oola.attribute6, oola.ordered_item )
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--              )
---- ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
--      AND  TRUNC(xoha.arrival_date)  >= TRUNC(gd_trans_start_date)
---- ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
----
--      UNION
----
--  --** ■例外４取得SQL
--      SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--         /*+
--           ORDERD
--           INDEX( haou hr_all_organizaion_units_pk)
--           USE_NL( XOHA xola iwm mil haou hca xca hca2 iimb ximb )
--         */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--         xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,NULL                       order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,NULL                       order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--        ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--        ,xoha.deliver_from          deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
---- *********** 2010/01/14 1.13 N.Maeda MOD START *********** --
----        ,xilv.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,mil.description            deliver_from_whse_name 
---- *********** 2010/01/14 1.13 N.Maeda MOD  END  *********** --
--        ,xoha.customer_code         customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
--        ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--        ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
----        ,xola.shipping_item_code    item_code                -- 受注明細ｱﾄﾞｵﾝ.出荷品目      ：品目ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--        ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,NULL                       schedule_dlv_date        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着日          ：納品予定日
--        ,NULL                       schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--        ,0                          order_quantity           -- 受注明細.受注数量           ：受注数
--        ,NVL( xola.shipped_quantity, 0 )
--                                    deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--        ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--        ,0 - NVL( xola.shipped_quantity, 0 )
--                                    output_quantity          -- 差異数
--        ,cv_data_class_5            data_class               -- 例外データ４                ：データ区分
--      FROM
---- *********** 2010/01/14 1.13 N.Maeda MOD START *********** --
----         xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
----        ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
----        ,xxcmn_item_locations2_v    xilv  -- OPM保管場所ﾏｽﾀ
----        ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
----        ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
----        ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
----        ,ic_item_mst_b              iimb  -- OPM品目
----        ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--         xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--        ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--        ,inv.mtl_item_locations        mil
--        ,hr.hr_all_organization_units  haou
--        ,gmi.ic_whse_mst               iwm
--        ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--        ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--        ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--        ,ic_item_mst_b              iimb  -- OPM品目
--        ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
---- *********** 2010/01/14 1.13 N.Maeda MOD  END  *********** --
--      WHERE
--           xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--      AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--      AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--      AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
----****************************** 2009/04/10 1.3 T.Kitajima ADD START ******************************--
--      AND NVL( xola.shipped_quantity, cn_ship_zero ) != cn_ship_zero  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量が0以外
----****************************** 2009/04/10 1.3 T.Kitajima ADD  END  ******************************--
---- *********** 2010/01/14 1.13 N.Maeda MOD START *********** --
----      AND  xoha.deliver_from         =   xilv.segment1             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所 = OPM保管場所ﾏｽﾀ.保管倉庫コード
----      AND  xilv.date_from                             <=  gd_process_date  -- OPM保管場所ﾏｽﾀ.組織有効開始日 <= 業務日付
----      AND  TRUNC( NVL( xilv.date_to, gd_max_date ) )  >=  gd_process_date  -- OPM保管場所ﾏｽﾀ.組織有効開始日 >= 業務日付
--        AND     iwm.mtl_organization_id = haou.organization_id
--        AND     haou.organization_id    = mil.organization_id
--        AND     XOHA.DELIVER_FROM   = mil.segment1
--        AND     haou.date_from         <= gd_process_date
--        AND     TRUNC( NVL( haou.date_to, gd_process_date ) ) >= gd_process_date
---- *********** 2010/01/14 1.13 N.Maeda MOD  END  *********** --
----MIYATA MODIFY
----      AND  xoha.customer_id          =   hca.cust_account_id       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--      AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
----MIYATA MODIFY
--      AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
--      AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                ,cv_base_all
--                                                ,xca.delivery_base_code
--                                                ,iv_base_code )
--      AND  hca2.customer_class_code  =  cv_party_type_1            -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--      AND  hca2.account_number       =  xca.delivery_base_code     -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD start ******************************* --
--      AND  xola.request_item_code   =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = OPM品目.品目ｺｰﾄﾞ
----      AND  xola.shipping_item_code   =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.出荷品目 = OPM品目.品目ｺｰﾄﾞ
---- ******************** 2009/07/08 1.7 N.Maeda MOD  end  ******************************* --
--      AND  iimb.item_id              =  ximb.item_id               -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--      AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--      AND NOT EXISTS(
--              SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                 /*+
--                   USE_NL( ooha oola hca xca mtsi )
--                 */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                'X'                       exists_flag -- EXISTSﾌﾗｸﾞ
--              FROM
--                 oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--              WHERE
--                   ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--              AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--              AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--              AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--              AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                            -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--              AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--              AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--              AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--              AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                  'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                   fnd_application    fa
----                                  ,fnd_lookup_types   flt
----                                  ,fnd_lookup_values  flv
--                                  fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                     fa.application_id           = flt.application_id
----                                AND  flt.lookup_type             = flv.lookup_type
----                                AND  fa.application_short_name   = cv_xxcos_short_name
----                                AND  flv.lookup_type             = cv_no_inv_item_code
--                                     flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                AND  flv.start_date_active      <= gd_process_date
--                                AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                                AND  flv.language                = USERENV( 'LANG' )
--                                AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                                AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                              )
--              AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--              AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                            -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--              AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                        ,cv_base_all
--                                                        ,xca.delivery_base_code
--                                                        ,iv_base_code )
--              AND  xoha.request_no            =  oola.packing_instructions  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No = 受注明細.梱包指示
--              )
---- ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
--      AND  TRUNC(xoha.arrival_date)  >= TRUNC(gd_trans_start_date)
---- ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
----
--      UNION
----
--  --** ■例外５取得SQL
--      SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--         /*+
--           LEADING(ooha)
--           INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--           INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--           USE_NL( ooha hca )
--           USE_NL( oola mtsi ottt otta )
--         */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--         xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,NULL                       line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
---- ******************** 2009/10/07 1.10 K.Satomura MOD START ******************************* --
----        ,oola.packing_instructions  deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
--        ,SUBSTRB(oola.packing_instructions, 1, 12) deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
---- ******************** 2009/10/07 1.10 K.Satomura MOD END   ******************************* --
--        ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
--        ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
--        ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--        ,NVL( oola.attribute6, oola.ordered_item )
--                                    item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
--        ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,TRUNC( oola.request_date ) schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
--        ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,NULL                       arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
----****************************** 2009/05/26 1.4 T.Kitajima MOD START ******************************--
----        ,oola.ordered_quantity      order_quantity           -- 受注明細.受注数量           ：受注数
--        ,oola.ordered_quantity * 
--          DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                                    order_quantity           -- 受注明細.受注数量           ：受注数
----****************************** 2009/05/26 1.4 T.Kitajima MOD  END  ******************************--
--        ,0                          deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--        ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
--        ,oola.ordered_quantity      output_quantity          -- 差異数
--        ,cv_data_class_6            data_class               -- 例外データ５                ：データ区分
--      FROM
--         oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--        ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
--        ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--        ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--        ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
--        ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--        ,ic_item_mst_b              iimb  -- OPM品目
--        ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
----****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
--        ,oe_transaction_types_tl    ottt  -- 受注取引タイプ（摘要）
--        ,oe_transaction_types_all   otta  -- 受注取引タイプマスタ
----****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
--      WHERE
--           ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--      AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--      AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
----****************************** 2009/05/26 1.4 T.Kitajima ADD START ******************************--
--      AND  oola.line_type_id        = ottt.transaction_type_id    -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--      AND  ottt.transaction_type_id = otta.transaction_type_id    -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----      AND  ottt.language            = USERENV( 'LANG' )           -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--      AND  ottt.language            = cv_user_lang           -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
----****************************** 2009/05/26 1.4 T.Kitajima ADD  END  ******************************--
--      AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--      AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
----      AND  ooha.flow_status_code  =  cv_status_booked             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
----                                                                  -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
----      AND  oola.flow_status_code  NOT IN ( cv_status_closed, cv_status_cancelled )
--      AND  ooha.flow_status_code  IN  ( cv_status_booked , cv_status_closed )  -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CANCELLED' )
--      AND  oola.flow_status_code  <>  cv_status_cancelled         -- 受注明細.ｽﾃｰﾀｽ <> 'CLOSED'
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--      AND  oola.org_id                = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--      AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
--      AND  NOT EXISTS ( SELECT                                    -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                          'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                        FROM
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
----                           fnd_application    fa
----                          ,fnd_lookup_types   flt
----                          ,fnd_lookup_values  flv
--                          fnd_lookup_values  flv
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                        WHERE
---- ********** 2009/11/26 1.11 N.Maeda MOD START ********** --
-----                             fa.application_id           = flt.application_id
-----                        AND  flt.lookup_type             = flv.lookup_type
-----                        AND  fa.application_short_name   = cv_xxcos_short_name
-----                        AND  flv.lookup_type             = cv_no_inv_item_code
--                             flv.lookup_type             = cv_no_inv_item_code
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                        AND  flv.start_date_active      <= gd_process_date
--                        AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                        AND  flv.enabled_flag            = cv_yes_flg
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
----                        AND  flv.language                = USERENV( 'LANG' )
--                        AND  flv.language                = cv_user_lang
---- ********** 2009/11/26 1.11 N.Maeda MOD  END  ********** --
--                        AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                     )
--      AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--      AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                  -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--      AND  xca.delivery_base_code  =  DECODE( iv_base_code
--                                             ,cv_base_all
--                                             ,xca.delivery_base_code
--                                             ,iv_base_code )
--      AND  hca2.customer_class_code  =  cv_party_type_1              -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--      AND  hca2.account_number       =  xca.delivery_base_code       -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--      AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
--      AND  iimb.item_id              =  ximb.item_id                 -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--      AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--      AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--      AND NOT EXISTS(
--              SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                /*+
--                  USE_NL( xoha xola hca xca )
--                */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                'X'                          exists_flag -- EXISTSﾌﾗｸﾞ
--              FROM
--                 xxwsh_order_headers_all     xoha        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--                ,xxwsh_order_lines_all       xola        -- 受注明細ｱﾄﾞｵﾝ
--                ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
--                ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
--              WHERE
--                   xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--              AND  xoha.req_status           <>  cv_h_add_status_99        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ <> 取消
--              AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--              AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
----MIYATA MODIFY
----              AND  xoha.customer_id          =   hca.cust_account_id       -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--              AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
----MIYATA MODIFY
--              AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID = 顧客追加情報ﾏｽﾀ.顧客ID
--              AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                        ,cv_base_all
--                                                        ,xca.delivery_base_code
--                                                        ,iv_base_code )
--              AND  oola.packing_instructions =   xoha.request_no           -- 受注明細.梱包指示 = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No
--              )
---- ********** 2009/12/11 1.12 N.Maeda MOD START ********** --
------ ********** 2009/11/26 1.11 N.Maeda ADD START ********** --
----      AND  TRUNC(oola.request_date)  >= TRUNC(gd_trans_start_date)
------ ********** 2009/11/26 1.11 N.Maeda ADD  END  ********** --
--      AND  ( ( oola.flow_status_code = cv_status_closed
--             AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--           OR ( oola.flow_status_code <> cv_status_closed
--             AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--           )
---- ********** 2009/12/11 1.12 N.Maeda MOD  END  ********** --
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
----
--      UNION
----
--      -- 例外６取得用ＳＱＬ
--      SELECT
--         ooa1.base_code                  base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--        ,ooa1.base_name                  base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--        ,ooa1.order_number               order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--        ,ooa1.order_line_no              order_line_no            -- 受注明細.明細番号           ：受注明細No
--        ,ooa2.line_no                    line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--        ,SUBSTRB(ooa1.deliver_requested_no, 1, 12) deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--        ,ooa1.deliver_from_whse_number   deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
--        ,ooa1.deliver_from_whse_name     deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--        ,ooa1.customer_number            customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
--        ,ooa1.customer_name              customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--        ,ooa1.item_code                  item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--        ,ooa1.item_name                  item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--        ,TRUNC( ooa1.schedule_dlv_date ) schedule_dlv_date        -- 受注ﾍｯﾀﾞ.着日               ：納品予定日
--        ,ooa1.schedule_inspect_date      schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--        ,ooa2.arrival_date               arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--        ,ooa1.order_quantity             order_quantity           -- 受注明細.受注数量           ：受注数
--        ,ooa2.deliver_actual_quantity    deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--        ,ooa2.uom_code                   uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--        ,ooa1.order_quantity
--          - ooa2.deliver_actual_quantity output_quantity          -- 差異数
--        ,cv_data_class_7                 data_class               -- 例外データ６                ：データ区分
--      FROM
--        -- ****** 例外６営業サブクエリ：ooa1 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--             /*+
--               LEADING(ooha)
--               USE_NL( ooha hca  )
--               USE_NL( oola mtsi  )
--               INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--             */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--            ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--            ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--            ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
--            ,oola.packing_instructions  deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
--            ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
--            ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--            ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
--            ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--            ,NVL( oola.attribute6, oola.ordered_item )
--                                        item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
--            ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--            ,oola.request_date          schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
--            ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--            ,ooas.order_quantity        order_quantity           -- 受注明細.受注数量           ：受注数
--            ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
--          FROM
--             oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--            ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
--            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--            ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
--            ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--            ,ic_item_mst_b              iimb  -- OPM品目
--            ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--            -- 最終歴用サブクエリ：ooal
--            ,( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                 /*+
--                   LEADING(ooha)
--                   USE_NL( ooha hca )
--                   USE_NL( oola mtsi )
--                   INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                 */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                 MAX( line_id )              line_id     -- 受注明細.受注明細ID
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--               AND  ooha.flow_status_code  IN  ( cv_status_booked , cv_status_closed )    -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED' , 'CLOSED' )
--                                                                             -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--               AND  oola.org_id            = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--               AND  oola.flow_status_code  <> cv_status_cancelled
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
--                                   fnd_lookup_values  flv
--                                 WHERE
--                                      flv.lookup_type             = cv_no_inv_item_code
--                                 AND  flv.start_date_active      <= gd_process_date
--                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
--                                 AND flv.language                = cv_user_lang
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
--               AND  ( ( oola.flow_status_code = cv_status_closed
--                      AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--                    OR ( oola.flow_status_code <> cv_status_closed
--                      AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--                    )
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--                 ,TRUNC( oola.request_date )
--             ) ooal
--             ,
--             -- サマリー用サブクエリ：ooas
--             ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--                  /*+
--                    LEADING(ooha)
--                    USE_NL(ooha hca )
--                    USE_NL(oola mtsi )
--                    INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                  */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
--                 ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
--                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                        * CASE oola.order_quantity_uom
--                          WHEN msib.primary_unit_of_measure THEN 1
--                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                          ELSE NVL( xicv.conversion_rate, 0 )
--                        END
--                  ) AS order_quantity
--                 ,TRUNC( oola.request_date ) request_date
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
--                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
--                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
--                 ,xxcos_item_conversions_v   xicv        -- 品目換算View
--                 ,(
--                   SELECT
--                       flv.meaning      AS UOM_CODE
--                     , flv.description  AS CNV_VALUE
--                   FROM
--                     fnd_lookup_values flv
--                   WHERE
--                         flv.enabled_flag          = cv_yes_flg
--                     AND flv.language                = cv_user_lang
--                     AND flv.start_date_active    <= gd_process_date
--                     AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
--                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
--                 ) item_cnv
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
--               AND  ottt.language            = cv_user_lang             -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--               AND  oola.org_id            = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
--                                   fnd_lookup_values  flv
--                                 WHERE
--                                      flv.lookup_type             = cv_no_inv_item_code
--                                 AND  flv.start_date_active      <= gd_process_date
--                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
--                                 AND  flv.language                = cv_user_lang
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                             --     = Disc品目.品目コード
--               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
--               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
--               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
--               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
--               AND  TRUNC(oola.request_date)   >= TRUNC(gd_trans_start_date)
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--                 ,TRUNC( oola.request_date )
--             ) ooas
--          WHERE
--               ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--          AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--          AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--          AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--          AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
----                                                                      -- 受注明細.ｽﾃｰﾀｽ NOT IN( 'CLOSED','CANCELLED')
--          AND  ooha.flow_status_code  IN ( cv_status_booked ,cv_status_closed )   -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED' , 'CLOSED' )
--          AND  oola.flow_status_code  <> cv_status_cancelled          -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--          AND  oola.org_id             = gn_org_id
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--          AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
--          AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--          AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--          AND  xca.delivery_base_code  =  DECODE( iv_base_code
--                                                 ,cv_base_all
--                                                 ,xca.delivery_base_code
--                                                 ,iv_base_code )
--          AND  hca2.customer_class_code  =  cv_party_type_1               -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--          AND  hca2.account_number       =  xca.delivery_base_code        -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--          AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no   -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
--          AND  iimb.item_id              =  ximb.item_id                  -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--          AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--          AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--          AND  oola.line_id               = ooal.line_id                  -- 受注明細.受注明細ID = 最終歴用.受注明細ID
--          AND  oola.packing_instructions  = ooas.deliver_requested_no     -- 例外６営業サブクエリ.出荷依頼No = サマリー用サブクエリ.出荷依頼No
--          AND  NVL( oola.attribute6, oola.ordered_item ) = ooas.item_code -- 例外６営業サブクエリ.品目コード = サマリー用サブクエリ.品目コード
--          AND  ( ( oola.flow_status_code = cv_status_closed
--                 AND TRUNC( oola.request_date ) >= TRUNC( gd_target_closed_month ) )
--               OR ( oola.flow_status_code <> cv_status_closed
--                 AND TRUNC( oola.request_date ) >= TRUNC( gd_trans_start_date ) )
--               )
--          AND TRUNC(oola.request_date) = ooas.request_date
--          AND ooas.order_quantity     != cn_order_sum_zero                -- 受注数量0
--        )
--        ooa1,
--        -- ****** 例外６生産サブクエリ：ooa2 ******
--        ( SELECT
---- *********** 2010/01/14 1.13 N.Maeda ADD START *********** --
--            /*+
--              USE_NL( xoha xola hca xca )
--            */
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--             xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--            ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--            ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--            ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--            ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--            ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--          FROM
--             xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--            ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--          WHERE
--               xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--          AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--          AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--          AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
--          AND  xola.shipped_quantity IS NOT NULL
--          AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
--          AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--          AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                    ,cv_base_all
--                                                    ,xca.delivery_base_code
--                                                    ,iv_base_code )
--        )
--        ooa2
--      WHERE
--           ooa1.deliver_requested_no =   ooa2.deliver_requested_no -- 例外６営業サブクエリ.出荷依頼No = 例外６生産サブクエリ.出荷依頼No
--      AND  ooa1.item_code            =   ooa2.item_code            -- 例外６営業サブクエリ.品目コード = 例外６生産サブクエリ.品目コード
--      AND                                                          -- 例外６営業サブクエリ.受注数 <> 例外６生産サブクエリ.出荷実績数
--        (  ooa1.order_quantity                 <>  ooa2.deliver_actual_quantity
--         OR                                                        -- 例外６営業サブクエリ.納品予定日 <> 例外６生産サブクエリ.着日
--           TRUNC( ooa1.schedule_dlv_date )     <>  ooa2.arrival_date
--         OR
--           (                                                       -- 例外６営業サブクエリ.納品予定日 =  例外６生産サブクエリ.着日
--             ( TRUNC( ooa1.schedule_dlv_date ) =   ooa2.arrival_date )
--             AND
--             ( ooa1.schedule_inspect_date IS NOT NULL )            -- 例外６営業サブクエリ.検収予定日 IS NOT NULL
--             AND                                                   -- 例外６営業サブクエリ.検収予定日 < 例外６生産サブクエリ.着日
--             ( TO_DATE( ooa1.schedule_inspect_date, cv_yyyymmddhhmiss ) < ooa2.arrival_date )
--           )
--        )
---- *********** 2010/01/14 1.13 N.Maeda ADD  END  *********** --
--      ;
--
-- 2010/04/09 Ver.1.14 Del M.Sano Start
--     --** ■例外１取得SQL
--     -- 受注-出荷実績間の数量エラーデータ
--     CURSOR quantity_excep_cur
--     IS
--     SELECT   ooa1.deliver_requested_no      ooa1_deliver_requested_no       -- 受注：出荷依頼No
--             ,ooa1.item_code                 ooa1_item_code                  -- 受注：品目コード
--             ,ooa1.order_quantity            ooa1_order_quantity             -- 受注：受注数
--             ,ooa1.line_id                   ooa1_line_id                    -- 受注：最終履歴_受注明細ID
--             ,ooa2.line_no                   ooa2_line_no                    -- 出荷：明細番号
--             ,ooa2.arrival_date              ooa2_arrival_date               -- 出荷：着荷日
--             ,ooa2.deliver_actual_quantity   ooa2_deliver_actual_quantity    -- 出荷：実績数
--             ,ooa2.uom_code                  ooa2_uom_code                   -- 出荷：単位
--             ,cv_date_type_1                 date_type
--     FROM
--               (
--               /* 受注部分のみ */
--               SELECT
--                  /*+
--                    --LEADING(ooha)
--                    --INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    --INDEX(ooha XXCOS_OE_ORDER_LINES_ALL_N23)
--                    --INDEX(xca xxcmm_cust_accounts_pk)
--                    --USE_NL( ooha hca  )
--                    --USE_NL( oola mtsi otta ottt )
--                    LEADING(ooha)
--                    INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--                    USE_NL( ooha hca  )
--                    USE_NL( oola mtsi )
--                  */
--                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
--                 ,NVL( oola.attribute6,  oola.ordered_item )   item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
--                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                        * CASE oola.order_quantity_uom
--                          WHEN msib.primary_unit_of_measure THEN 1
--                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                          ELSE NVL( xicv.conversion_rate, 0 )
--                        END
--                  )  AS order_quantity
--                 ,MAX(oola.line_id)  line_id
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
--                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
--                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
--                 ,xxcos_item_conversions_v  xicv         -- 品目換算View
--                 ,(
--                   SELECT
--                       flv.meaning      AS UOM_CODE
--                     , flv.description  AS CNV_VALUE
--                   FROM
--                     fnd_lookup_values flv
--                   WHERE
--                         flv.enabled_flag          = cv_yes_flg
--                     AND flv.language              = cv_user_lang
--                     AND flv.start_date_active    <= gd_process_date
--                     AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
--                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
--                 ) item_cnv                              -- 重量換算マスタ
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
--               AND  ottt.language            = cv_user_lang                  -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--               AND  oola.org_id       =  gn_org_id                           -- 受注明細.組織ID = A-1取得の営業単位
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
--                                   applsys.fnd_lookup_values  flv
--                                 WHERE
--                                      flv.lookup_type             = cv_no_inv_item_code
--                                 AND  flv.start_date_active      <= gd_process_date
--                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
--                                 AND  flv.language                = cv_user_lang
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ,'ALL',顧客追加情報ﾏｽﾀ.納品拠点,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----               AND  xca.delivery_base_code     =  DECODE( iv_base_code
----                                                         ,cv_base_all
----                                                         ,xca.delivery_base_code
----                                                         ,iv_base_code )
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                             --     = Disc品目.品目コード
--               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
--               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
--               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
--               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)        -- 受注明細.受注単位 =重量換算マスタ. 単位コード(+)
--               AND  ( ( oola.flow_status_code = cv_status_closed
--                      AND oola.request_date >= to_date(gd_target_closed_month))
--                    OR ( oola.flow_status_code <> cv_status_closed
--                      AND oola.request_date >= to_date(gd_trans_start_date))
--                    )
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--                 ,TRUNC( oola.request_date )
--               ) ooa1
--              ,(
--               /* 生産部分のみ */
--               SELECT
--                  /*+
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( xoha xola hca xca )
--                  */
--                  xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--                 ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--                 ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--                 ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--                 ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--                 ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--               FROM
--                  xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--                 ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--                 ,hz_cust_accounts              hca   -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--               WHERE
--                    xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--               AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--               AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--               AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
--               AND  xola.shipped_quantity IS NOT NULL
--               AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
--               AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----               AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ,'ALL',顧客追加情報ﾏｽﾀ.納品拠点,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                                         ,cv_base_all
----                                                         ,xca.delivery_base_code
----                                                         ,iv_base_code )
--               AND xoha.arrival_date >= to_date(gd_trans_start_date)
--               ) ooa2
--     WHERE
--          ooa1.deliver_requested_no =   ooa2.deliver_requested_no     -- 例外１営業サブクエリ.出荷依頼No =  例外１生産サブクエリ.出荷依頼No
--     AND  ooa1.item_code            =   ooa2.item_code                -- 例外１営業サブクエリ.品目コード =  例外１生産サブクエリ.品目コード
--     AND  ooa1.order_quantity      !=   ooa2.deliver_actual_quantity  -- 例外１営業サブクエリ.受注数    !=  例外１生産サブクエリ.出荷実績数
----     ;
----
--     UNION ALL
----
-- 2010/04/09 Ver.1.14 Del M.Sano End
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--     --** ■例外1-２取得SQL(旧例外２)
--     -- 出荷実績ステータスエラー(納品日経過データのステータスエラー)
--     CURSOR req_status_excep_cur
--     IS
--     SELECT   ooa1.deliver_requested_no      ooa1_deliver_requested_no
    -- =========================================================================
    --** [拠点・ALL指定]例外１
    --** ①、②に該当するエラーデータ抽出SQL
    --**   ① 納品日経過データで出荷実績ステータスが"出荷実績計上済"以外
    --**   ② 受注数量の(出荷依頼No・品目単位での)サマリが"0"
    -- =========================================================================
     CURSOR quantity_excep_cur
     IS
    -- ======================================================
    -- [拠点・ALL指定]例外１
    -- ① 納品日経過データで出荷実績ステータスが"出荷実績計上済"以外
    -- ======================================================
     SELECT   /*+
                LEADING( ooa2 )
                USE_NL( ooa2 ooa1 )
              */
              ooa1.deliver_requested_no      ooa1_deliver_requested_no
-- 2010/04/09 Ver.1.14 Mod M.Sano End
             ,ooa1.item_code                 ooa1_item_code
             ,ooa1.order_quantity            ooa1_order_quantity
             ,ooa1.line_id                   ooa1_line_id
             ,ooa2.line_no                   ooa2_line_no
             ,ooa2.arrival_date              ooa2_arrival_date
             ,ooa2.deliver_actual_quantity   ooa2_deliver_actual_quantity
             ,ooa2.uom_code                  ooa2_uom_code
             ,cv_date_type_2                 date_type
     FROM
       -- ****** 例外２数量サブクエリ：ooa1 ******
       ( SELECT
            /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--            --  LEADING(ooha)
--            --  INDEX(ooha xxcos_oe_order_headers_all_n11)
--            --  USE_NL( oola hca xca msib xicv ottt otta mtsi )
--               LEADING(ooha)
--               INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--               INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--               INDEX(mtsi mtl_secondary_inventories_u1 )
--               USE_NL( ooha hca  )
--               USE_NL( oola mtsi  )
               LEADING( oola )
               INDEX( xca xxcmm_cust_accounts_n15 )
               USE_NL( oola item_cnv ) 
               USE_NL( oola otta ottt )
               USE_NL( ooha hca )
               USE_NL( oola mtsi )
-- 2010/04/09 Ver.1.14 Mod M.Sano End
            */
            oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
           ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
           ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                  * CASE oola.order_quantity_uom
                    WHEN msib.primary_unit_of_measure THEN 1
                    WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                    ELSE NVL( xicv.conversion_rate, 0 )
                  END
            ) AS order_quantity
           ,MAX(oola.line_id)  line_id
         FROM
            oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
           ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
           ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
           ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
           ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
           ,mtl_system_items_b         msib        -- Disc品目（営業組織）
           ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
           ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
           ,xxcos_item_conversions_v   xicv        -- 品目換算View
           ,(
             SELECT
                 flv.meaning      AS UOM_CODE
               , flv.description  AS CNV_VALUE
             FROM
               fnd_lookup_values flv
             WHERE
                   flv.enabled_flag          = cv_yes_flg
               AND flv.language              = cv_user_lang
               AND flv.start_date_active    <= gd_process_date
               AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
               AND flv.lookup_type           = cv_weight_uom_cnv_mst
           ) item_cnv
         WHERE
              ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
         AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
         AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
         AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
         AND  ottt.language            = cv_user_lang                  -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
         AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
         AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
         AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
                                                                       -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
         AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
         AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
         AND  oola.org_id                = gn_org_id
         AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
         AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                             'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                           FROM
                             fnd_lookup_values  flv
                           WHERE
                                flv.lookup_type             = cv_no_inv_item_code
                           AND  flv.start_date_active      <= gd_process_date
                           AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                           AND  flv.enabled_flag            = cv_yes_flg
                           AND  flv.language                = cv_user_lang
                           AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                         )
         AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
         AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
                                                                       -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
-- 2011/03/08 Ver.1.15 Mod K.Kiriu Start
--               AND  ( ( iv_base_code = cv_base_all )
               AND  ( 
                      ( ( iv_base_code = cv_base_all ) AND ( oola.request_date < gd_trans_end_date ) ) --'ALL'の場合、前月納品日(業務日付の月初より前)のみ出力
-- 2011/03/08 Ver.1.15 Mod K.Kiriu End
                      OR
                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
                    )
--         AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                   ,cv_base_all
--                                                   ,xca.delivery_base_code
--                                                   ,iv_base_code )
                                                                       -- NVL(受注明細.子コード,受注明細.受注品目)
                                                                       --     = Disc品目.品目コード
         AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
         AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
                                                                            -- NVL(受注明細.子コード,受注明細.受注品目)
         AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
         AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
         AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
         AND  ( ( oola.flow_status_code = cv_status_closed
                AND oola.request_date >= to_date(gd_target_closed_month))
-- 2011/03/08 Ver.1.15 Mod K.Kiriu Start
--              OR ( oola.flow_status_code <> cv_status_cancelled
              OR ( oola.flow_status_code <> cv_status_closed
-- 2011/03/08 Ver.1.15 Mod K.Kiriu End
                AND oola.request_date >= to_date(gd_trans_start_date))
                AND oola.request_date <  gd_process_date
              )
         GROUP BY
            oola.packing_instructions
           ,NVL( oola.attribute6, oola.ordered_item )
       )
       ooa1,
       -- ****** 例外２生産サブクエリ：ooa2 ******
       ( SELECT
            /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--            USE_NL( xoha xola hca xca )
              LEADING( xoha hca xca )
              INDEX( xca xxcmm_cust_accounts_n15 )
              USE_NL(xoha hca xca )
-- 2010/04/09 Ver.1.14 Mod M.Sano End
            */
            xola.order_line_number           line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
           ,xoha.request_no                  deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
           ,xola.request_item_code           item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
           ,xoha.arrival_date                arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
           ,NVL( xola.shipped_quantity , 0 ) deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
           ,xola.uom_code                    uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
         FROM
            xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
           ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
           ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
           ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
         WHERE
              xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
                                                                      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ NOT IN( 出荷実績計上済 , 取消 )
         AND  xoha.req_status      NOT IN ( cv_h_add_status_04, cv_h_add_status_99 )
         AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
         AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
         AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
         AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
               AND  ( ( iv_base_code = cv_base_all )
                      OR
                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
                    )
--         AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                   ,cv_base_all
--                                                   ,xca.delivery_base_code
--                                                   ,iv_base_code )
         AND nvl(xoha.arrival_date,xoha.schedule_arrival_date) >= to_date(gd_trans_start_date)
       )
       ooa2
     WHERE
          ooa1.deliver_requested_no       =  ooa2.deliver_requested_no -- 例外２営業サブクエリ.出荷依頼No = 例外２生産サブクエリ.出荷依頼No
     AND  ooa1.item_code                  =  ooa2.item_code            -- 例外２営業サブクエリ.品目コード = 例外２生産サブクエリ.品目コード
-- 2010/04/09 Ver.1.14 Del M.Sano Start
----
--     UNION ALL
----
--     -- 例外１-３納品日違い情報
--     SELECT   ooa1.deliver_requested_no      ooa1_deliver_requested_no
--             ,ooa1.item_code                 ooa1_item_code
--             ,ooa1.order_quantity            ooa1_order_quantity
--             ,ooa1.line_id                   ooa1_line_id
--             ,ooa2.line_no                   ooa2_line_no
--             ,ooa2.arrival_date              ooa2_arrival_date
--             ,ooa2.deliver_actual_quantity   ooa2_deliver_actual_quantity
--             ,ooa2.uom_code                  ooa2_uom_code
--             ,cv_date_type_1                 date_type
--     FROM
--               (
--               /* 受注部分のみ */
--               SELECT
--                  /*+
--                   -- LEADING(ooha)
--                    --ORDERD
--                    --INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    --INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--                    --INDEX(xca xxcmm_cust_accounts_pk)
--                    --USE_NL( ooha hca xca )
--                    --USE_NL( oola mtsi otta ottt item_cnv xicv msib )
--                    LEADING(ooha)
--                    INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--                    USE_NL( ooha hca  )
--                    USE_NL( oola mtsi )
--                  */
--                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
--                 ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
--                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                        * CASE oola.order_quantity_uom
--                          WHEN msib.primary_unit_of_measure THEN 1
--                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                          ELSE NVL( xicv.conversion_rate, 0 )
--                        END
--                  ) AS order_quantity
--                 ,TRUNC( oola.request_date )     schedule_dlv_date
--                 ,MAX(oola.line_id)              line_id
--               --  ,oola.attribute4                schedule_inspect_date
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts      xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
--                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
--                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
--                 ,xxcos_item_conversions_v  xicv        -- 品目換算View
--                 ,(
--                   SELECT
--                       flv.meaning      AS UOM_CODE
--                     , flv.description  AS CNV_VALUE
--                   FROM
--                     applsys.fnd_lookup_values flv
--                   WHERE
--                         flv.enabled_flag          = cv_yes_flg
--                     AND flv.language                = cv_user_lang
--                     AND flv.start_date_active    <= sysdate
--                     AND sysdate          <= NVL( flv.end_date_active, gd_max_date )
--                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
--                 ) item_cnv
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
--               AND  ottt.language            = cv_user_lang                  -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = cv_user_lang
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( cv_status_booked,cv_status_closed )
--               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--               AND  oola.org_id       =  gn_org_id                           -- 受注明細.組織ID = A-1取得の営業単位
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   /*+
--                                   USE_NL ( flv )
--                                   */
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
--                                   applsys.fnd_lookup_values  flv
--                                 WHERE
--                                      flv.lookup_type             = cv_no_inv_item_code
--                                 AND  flv.start_date_active      <= sysdate
--                                 AND  sysdate            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
--                                 AND  flv.language                = cv_user_lang
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(cv_base_all,cv_base_all,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----               AND  xca.delivery_base_code     =  DECODE( iv_base_code
----                                                         ,cv_base_all
----                                                         ,xca.delivery_base_code
----                                                         ,iv_base_code )
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                             --     = Disc品目.品目コード
--               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
--               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
--               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
--               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
--               AND  ( ( oola.flow_status_code = cv_status_closed
--                      AND oola.request_date >= to_date(gd_target_closed_month))
--                    OR ( oola.flow_status_code <> cv_status_closed
--                      AND oola.request_date >= to_date(gd_trans_start_date))
--                    )
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--                 ,TRUNC( oola.request_date )
--                 --,oola.attribute4
--               ) ooa1
--              ,(
--               /* 生産部分のみ */
--               SELECT
--                  /*+
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( xoha xola hca xca )
--                  */
--                  xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--                 ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--                 ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--                 ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--                 ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--                 ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--               FROM
--                  xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--                 ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--                 ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--               WHERE
--                    xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--               AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--               AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = cv_yes_flg
--               AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = cv_no_flg
--               AND  xola.shipped_quantity IS NOT NULL
--               AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
--               AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----               AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(cv_base_all,cv_base_all,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                                         ,cv_base_all
----                                                         ,xca.delivery_base_code
----                                                         ,iv_base_code )
--               AND xoha.arrival_date >= to_date(gd_trans_start_date)
--               ) ooa2
--     WHERE
--          ooa1.deliver_requested_no =   ooa2.deliver_requested_no      -- 営業サブクエリ.出荷依頼No =  生産サブクエリ.出荷依頼No
--     AND  ooa1.item_code            =   ooa2.item_code                 -- 営業サブクエリ.品目コード =  生産サブクエリ.品目コード
--     AND  ooa1.order_quantity      !=   0                              -- 営業サブクエリ.受注数    !=  0
--     AND  TRUNC( ooa1.schedule_dlv_date )  !=  ooa2.arrival_date       -- 営業サブクエリ.納品予定日!= 生産サブクエリ.着日
--     --
-- 2010/04/09 Ver.1.14 Del M.Sano End
--     UNION ALL
--     --
--     -- 例外１-４納品日-検収日逆転エラー
--     SELECT   ooa1.deliver_requested_no      ooa1_deliver_requested_no
--             ,ooa1.item_code                 ooa1_item_code
--             ,ooa1.order_quantity            ooa1_order_quantity
--             ,ooa1.line_id                   ooa1_line_id
--             ,ooa2.line_no                   ooa2_line_no
--             ,ooa2.arrival_date              ooa2_arrival_date
--             ,ooa2.deliver_actual_quantity   ooa2_deliver_actual_quantity
--             ,ooa2.uom_code                  ooa2_uom_code
--             ,cv_date_type_1                 date_type
--     FROM
--               (
--               /* 受注部分のみ */
--               SELECT
--                  /*+
--                   -- LEADING(ooha)
--                    ORDERD
--                    INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( ooha hca xca )
--                    USE_NL( oola mtsi otta ottt item_cnv xicv msib )
--                  */
--                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
--                 ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
--                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                        * CASE oola.order_quantity_uom
--                          WHEN msib.primary_unit_of_measure THEN 1
--                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                          ELSE NVL( xicv.conversion_rate, 0 )
--                        END
--                  ) AS order_quantity
--                 ,TRUNC( oola.request_date )     schedule_dlv_date
--                 ,MAX(oola.line_id)              line_id
--                 ,oola.attribute4                schedule_inspect_date
--               FROM
--                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--                 ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts      xca         -- 顧客追加情報ﾏｽﾀ
--                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
--                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
--                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
--                 ,xxcos_item_conversions_v  xicv        -- 品目換算View
--                 ,(
--                   SELECT
--                       flv.meaning      AS UOM_CODE
--                     , flv.description  AS CNV_VALUE
--                   FROM
--                     fnd_lookup_values flv
--                   WHERE
--                         flv.enabled_flag          = cv_yes_flg
--                     AND flv.language                = cv_user_lang
--                     AND flv.start_date_active    <= sysdate
--                     AND sysdate          <= NVL( flv.end_date_active, gd_max_date )
--                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
--                 ) item_cnv
--               WHERE
--                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
--               AND  ottt.language            = cv_user_lang             -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = cv_user_lang
--               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( cv_status_booked,cv_status_closed )
--               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--               AND  oola.org_id       =  gn_org_id                           -- 受注明細.組織ID = A-1取得の営業単位
--               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                   /*+
--                                   USE_NL ( flv )
--                                   */
--                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                                 FROM
--                                   applsys.fnd_lookup_values  flv
--                                 WHERE
--                                      flv.lookup_type             = cv_no_inv_item_code
--                                 AND  flv.start_date_active      <= sysdate
--                                 AND  sysdate            <= NVL( flv.end_date_active, gd_max_date )
--                                 AND  flv.enabled_flag            = cv_yes_flg
--                                 AND  flv.language                = cv_user_lang
--                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                               )
--               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(cv_base_all,cv_base_all,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----               AND  xca.delivery_base_code     =  DECODE( iv_base_code
----                                                         ,cv_base_all
----                                                         ,xca.delivery_base_code
----                                                         ,iv_base_code )
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                             --     = Disc品目.品目コード
--               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
--               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
--               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
--               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
--               AND  ( ( oola.flow_status_code = cv_status_closed
--                      AND oola.request_date >= to_date(gd_target_closed_month))
--                    OR ( oola.flow_status_code <> cv_status_closed
--                      AND oola.request_date >= to_date(gd_trans_start_date))
--                    )
--               GROUP BY
--                  oola.packing_instructions
--                 ,NVL( oola.attribute6, oola.ordered_item )
--                 ,TRUNC( oola.request_date )
--                 ,oola.attribute4
--               ) ooa1
--              ,(
--               /* 生産部分のみ */
--               SELECT
--                  /*+
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( xoha xola hca xca )
--                  */
--                  xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--                 ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--                 ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--                 ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--                 ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--                 ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--               FROM
--                  xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--                 ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--                 ,hz_cust_accounts              hca   -- 顧客ﾏｽﾀ
--                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--               WHERE
--                    xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--               AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--               AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = cv_yes_flg
--               AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = cv_no_flg
--               AND  xola.shipped_quantity IS NOT NULL
--               AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
--               AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----               AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(cv_base_all,cv_base_all,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                                         ,cv_base_all
----                                                         ,xca.delivery_base_code
----                                                         ,iv_base_code )
--               AND xoha.arrival_date >= to_date(gd_trans_start_date)
--               ) ooa2
--     WHERE
--          ooa1.deliver_requested_no =   ooa2.deliver_requested_no      -- 営業サブクエリ.出荷依頼No =  生産サブクエリ.出荷依頼No
--     AND  ooa1.item_code            =   ooa2.item_code                 -- 営業サブクエリ.品目コード =  生産サブクエリ.品目コード
--     AND  ooa1.order_quantity      !=   0                              -- 営業サブクエリ.受注数    !=  0
--     AND  TRUNC( ooa1.schedule_dlv_date )     =  ooa2.arrival_date     -- 営業サブクエリ.納品予定日 = 生産サブクエリ.着日
--     AND  ( ( ooa1.schedule_inspect_date IS NOT NULL )                 -- 営業サブクエリ.検収予定日 IS NOT NULL
--            AND                                                        -- 営業サブクエリ.検収予定日 < 生産サブクエリ.着日
--            ( TO_DATE( ooa1.schedule_inspect_date, cv_yyyymmddhhmiss ) < ooa2.arrival_date )
--          )
--
     UNION ALL
--
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--     --■例外1-5取得SQL
--     -- 受注数量0データ取得
--     SELECT   ooa1.deliver_requested_no      ooa1_deliver_requested_no       -- 受注：出荷依頼No
    -- ======================================================
    -- [拠点・ALL指定]例外１
    -- ② 受注数量の(出荷依頼No・品目単位での)サマリが"0"
    -- ======================================================
     SELECT   /*+
                LEADING( ooa2 )
-- 2014/03/17 Ver.1.18 Add K.Kiriu Start
                USE_NL( ooa2 ooa1 )
-- 2014/03/17 Ver.1.18 Add K.Kiriu End
              */
              ooa1.deliver_requested_no      ooa1_deliver_requested_no       -- 受注：出荷依頼No
-- 2010/04/09 Ver.1.14 Mod M.Sano End
             ,ooa1.item_code                 ooa1_item_code                  -- 受注：品目コード
             ,ooa1.order_quantity            ooa1_order_quantity             -- 受注：受注数
             ,ooa1.line_id                   ooa1_line_id                    -- 受注：最終履歴_受注明細ID
             ,ooa2.line_no                   ooa2_line_no                    -- 出荷：明細番号
             ,ooa2.arrival_date              ooa2_arrival_date               -- 出荷：着荷日
             ,ooa2.deliver_actual_quantity   ooa2_deliver_actual_quantity    -- 出荷：実績数
             ,ooa2.uom_code                  ooa2_uom_code                   -- 出荷：単位
             ,cv_date_type_2                 date_type
     FROM
               (
               /* 受注部分のみ */
               SELECT
                  /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--                    LEADING(ooha)
--                    INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--                    INDEX(ooha XXCOS_OE_ORDER_LINES_ALL_N23)
--                    INDEX(xca xxcmm_cust_accounts_pk)
                    LEADING( oola )
                    INDEX( xca xxcmm_cust_accounts_n15 )
                    USE_NL( oola item_cnv ) 
-- 2010/04/09 Ver.1.14 Mod M.Sano End
                    USE_NL( ooha hca  )
                    USE_NL( oola mtsi otta ottt )
                  */
                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
                 ,NVL( oola.attribute6,  oola.ordered_item )   item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                        * CASE oola.order_quantity_uom
                          WHEN msib.primary_unit_of_measure THEN 1
                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                          ELSE NVL( xicv.conversion_rate, 0 )
                        END
                  )  AS order_quantity
                 ,MAX(oola.line_id)  line_id
               FROM
                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
                 ,xxcos_item_conversions_v  xicv         -- 品目換算View
                 ,(
                   SELECT
                       flv.meaning      AS UOM_CODE
                     , flv.description  AS CNV_VALUE
                   FROM
                     fnd_lookup_values flv
                   WHERE
                         flv.enabled_flag          = cv_yes_flg
                     AND flv.language              = cv_user_lang
                     AND flv.start_date_active    <= gd_process_date
                     AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
                 ) item_cnv                              -- 重量換算マスタ
               WHERE
                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
               AND  ottt.language            = cv_user_lang                  -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
               AND  oola.org_id       =  gn_org_id                           -- 受注明細.組織ID = A-1取得の営業単位
               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                                 FROM
                                   applsys.fnd_lookup_values  flv
                                 WHERE
                                      flv.lookup_type             = cv_no_inv_item_code
                                 AND  flv.start_date_active      <= gd_process_date
                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                 AND  flv.enabled_flag            = cv_yes_flg
                                 AND  flv.language                = cv_user_lang
                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                               )
               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
-- 2011/03/08 Ver.1.15 Mod K.Kiriu Start
--               AND  ( ( iv_base_code = cv_base_all )
               AND  ( 
                      ( ( iv_base_code = cv_base_all ) AND ( oola.request_date < gd_trans_end_date ) )  --'ALL'の場合、前月納品日(業務日付の月初より前)のみ出力
-- 2011/03/08 Ver.1.15 Mod K.Kiriu End
                      OR
                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
                    )
                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ,'ALL',顧客追加情報ﾏｽﾀ.納品拠点,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
--                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
--                                                                             --     = Disc品目.品目コード
               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)        -- 受注明細.受注単位 =重量換算マスタ. 単位コード(+)
               AND  ( ( oola.flow_status_code = cv_status_closed
                      AND oola.request_date >= to_date(gd_target_closed_month))
                    OR ( oola.flow_status_code <> cv_status_closed
                      AND oola.request_date >= to_date(gd_trans_start_date))
                    )
               GROUP BY
                  oola.packing_instructions
                 ,NVL( oola.attribute6, oola.ordered_item )
               ) ooa1
              ,(
               /* 生産部分のみ */
               SELECT
                  /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( xoha xola hca xca )
                    LEADING( xoha hca xca )
                    INDEX( xca xxcmm_cust_accounts_n15 )
                    USE_NL(xoha hca xca )
-- 2010/04/09 Ver.1.14 Mod M.Sano End
                  */
                  xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
                 ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
                 ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
                 ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
                 ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
                 ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
               FROM
                  xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
                 ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
                 ,hz_cust_accounts              hca   -- 顧客ﾏｽﾀ
                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
               WHERE
                    xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
               AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
               AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
               AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
               AND  xola.shipped_quantity IS NOT NULL
               AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
               AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
               AND  ( ( iv_base_code = cv_base_all )
                      OR
                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
                    )
--               AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE(ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ,'ALL',顧客追加情報ﾏｽﾀ.納品拠点,ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
               AND xoha.arrival_date >= to_date(gd_trans_start_date)
               ) ooa2
     WHERE
          ooa1.deliver_requested_no =   ooa2.deliver_requested_no     -- 例外１営業サブクエリ.出荷依頼No =  例外１生産サブクエリ.出荷依頼No
     AND  ooa1.item_code            =   ooa2.item_code                -- 例外１営業サブクエリ.品目コード =  例外１生産サブクエリ.品目コード
     AND  ooa1.order_quantity      !=   ooa2.deliver_actual_quantity
     AND  ooa1.order_quantity       =   0                             -- 例外１営業サブクエリ.受注数    =  0
     ;
--
-- 2010/04/09 Ver.1.14 Add M.Sano Start
    -- =========================================================================
    --** [ALL指定]例外２
    --** ①～④に該当するエラーデータの抽出SQL
    --**   ① 受注あり-出荷実績なし ※出荷依頼No存在なしエラー
    --**   ② 受注あり-出荷実績なし ※明細品目不一致エラー
    --**   ③ 受注なし-出荷実績あり ※出荷依頼No存在なしエラー
    --**   ④ 受注なし-出荷実績あり ※明細品目不一致エラー
    -- =========================================================================
-- 2010/04/09 Ver.1.14 Add M.Sano End
     CURSOR line_item_excep_cur
     IS
    -- ======================================================
    -- [ALL指定]例外２
    -- ① 受注あり-出荷実績なし ※出荷依頼No存在なしエラー
    -- ② 受注あり-出荷実績なし ※明細品目不一致エラー
    -- ======================================================
     SELECT
        /*+
         -- LEADING(ooha)
         -- INDEX(ooha xxcos_oe_order_headers_all_n11)
         -- USE_NL( ooha hca xca hca2 )
         -- USE_NL( oola mtsi ottt otta iimb ximb )
           LEADING(ooha)
           INDEX(ooha xxcos_oe_order_headers_all_n11)
           INDEX(oola xxcos_oe_order_lines_all_n23)
-- 2011/11/11 Ver.1.17 Mod Start
--           USE_NL( ooha hca  )
           USE_NL( ooha hca xca )
-- 2011/11/11 Ver.1.17 Mod End
           USE_NL( oola mtsi ottt otta )
-- 2010/04/09 Ver.1.14 Add M.Sano Start
           USE_NL( oola iimb ximb )
-- 2010/04/09 Ver.1.14 Add M.Sano End
        */
        xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
       ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
       ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
       ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
       ,NULL                       line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
       ,SUBSTRB(oola.packing_instructions, 1, 12) deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
       ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
       ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
       ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
       ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
       ,NVL( oola.attribute6, oola.ordered_item )
                                   item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
       ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
       ,TRUNC( oola.request_date ) schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
       ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
       ,NULL                       arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
       ,oola.ordered_quantity * 
         DECODE ( otta.order_category_code, cv_order, 1, -1 )
                                   order_quantity           -- 受注明細.受注数量           ：受注数
       ,0                          deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
       ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
       ,oola.ordered_quantity      output_quantity          -- 差異数
     FROM
        oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
       ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
       ,hz_cust_accounts            hca   -- 顧客ﾏｽﾀ
       ,xxcmm_cust_accounts      xca   -- 顧客追加情報ﾏｽﾀ
       ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
       ,hz_cust_accounts            hca2  -- 顧客ﾏｽﾀ2
       ,ic_item_mst_b              iimb  -- OPM品目
       ,xxcmn_item_mst_b         ximb  -- OPM品目ｱﾄﾞｵﾝ
       ,oe_transaction_types_tl    ottt  -- 受注取引タイプ（摘要）
       ,oe_transaction_types_all   otta  -- 受注取引タイプマスタ
     WHERE
          ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
     AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
     AND  oola.line_type_id        = ottt.transaction_type_id    -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
     AND  ottt.transaction_type_id = otta.transaction_type_id    -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
     AND  ottt.language            = cv_user_lang           -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
     AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
     AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
     AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
-- 2011/11/11 Ver.1.17 Mod Start
--     AND  ooha.flow_status_code  IN ( cv_status_booked , cv_status_closed ) -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--     AND  oola.flow_status_code  <> cv_status_cancelled          -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
     AND  ooha.flow_status_code  = cv_status_booked              -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
     AND  oola.flow_status_code  = cv_status_booked              -- 受注明細.ｽﾃｰﾀｽ = 'BOOKED'
-- 2011/11/11 Ver.1.17 Mod End
     AND  oola.org_id       = gn_org_id
     AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
     AND  NOT EXISTS ( SELECT                                    -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                         'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                       FROM
                         fnd_lookup_values  flv
                       WHERE
                            flv.lookup_type             = cv_no_inv_item_code
                       AND  flv.start_date_active      <= gd_process_date
                       AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                       AND  flv.enabled_flag            = cv_yes_flg
                       AND  flv.language                = cv_user_lang
                       AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                    )
     AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
     AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
-- 2010/04/09 Ver.1.14 Del M.Sano Start
--                                                                 -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----     AND  xca.delivery_base_code  =  DECODE( iv_base_code
----                                            ,cv_base_all
----                                            ,xca.delivery_base_code
----                                            ,iv_base_code )
-- 2010/04/09 Ver.1.14 Del M.Sano End
     AND  hca2.customer_class_code  =  cv_party_type_1              -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
     AND  hca2.account_number       =  xca.delivery_base_code       -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
     AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
     AND  iimb.item_id              =  ximb.item_id                 -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
     AND  TRUNC( ximb.start_date_active )                   <= gd_process_date   -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
     AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date   -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
     AND NOT EXISTS(
             SELECT
              /*+
                USE_NL( xoha xola hca xca mtsi )
              */
               'X'                          exists_flag -- EXISTSﾌﾗｸﾞ
             FROM
                xxwsh_order_headers_all     xoha        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
               ,xxwsh_order_lines_all       xola        -- 受注明細ｱﾄﾞｵﾝ
               ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
               ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
             WHERE
                  xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
             AND  xoha.req_status           <>  cv_h_add_status_99        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ <> 取消
             AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
             AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
             AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
             AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
-- 2011/04/18 Ver1.16 Mod Start Y.Kanami
             AND  xca.delivery_base_code    =   hca2.account_number       -- 顧客追加情報マスタ.納品拠点 = 顧客マスタ2.顧客コード
-- 2011/04/18 Ver1.16 Mod End Y.Kanami
-- 2010/04/09 Ver.1.14 Del M.Sano Start
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----             AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                                       ,cv_base_all
----                                                       ,xca.delivery_base_code
----                                                       ,iv_base_code )
-- 2010/04/09 Ver.1.14 Del M.Sano End
             AND NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= to_date( gd_trans_start_date )
             AND  oola.packing_instructions =   xoha.request_no   -- 受注明細.梱包指示 = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No
                                                                  -- NVL(受注明細.子コード,受注明細.受注品目) = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼品目
             AND  NVL( oola.attribute6, oola.ordered_item ) = xola.request_item_code
             )
-- 2011/11/11 Ver.1.17 Mod Start
--       AND  ( ( oola.flow_status_code = cv_status_closed
--              AND oola.request_date >= to_date( gd_target_closed_month ) )
--            OR ( oola.flow_status_code <> cv_status_closed
--              AND oola.request_date >= to_date( gd_trans_start_date ) )
--            )
     AND  oola.request_date >= to_date( gd_trans_start_date )
-- 2011/11/11 Ver.1.17 Mod End
-- 2011/03/08 Ver.1.15 Add K.Kiriu Start
       AND  oola.request_date < gd_trans_end_date --前月納品日(業務日付の月初より前)のみ出力
-- 2011/03/08 Ver.1.15 Add K.Kiriu End
     UNION ALL
    -- ======================================================
    -- [ALL指定]例外２
    -- ③ 受注なし-出荷実績あり ※出荷依頼No存在なしエラー
    -- ④ 受注なし-出荷実績あり ※明細品目不一致エラー
    -- ======================================================
     SELECT
       /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--         ORDERED
         LEADING(xoha)
-- 2010/04/09 Ver.1.14 Mod M.Sano End
         INDEX( haou hr_all_organizaion_units_pk )
         USE_NL( xoha xola iwm mil haou hca xca hca2 iimb ximb )
       */
        xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
       ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
       ,NULL                       order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
       ,NULL                       order_line_no            -- 受注明細.明細番号           ：受注明細No
       ,xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
       ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
       ,xoha.deliver_from          deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
       ,mil.description            deliver_from_whse_name
       ,xoha.customer_code         customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
       ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
       ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
       ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
       ,NULL                       schedule_dlv_date        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着日          ：納品予定日
       ,NULL                       schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
       ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
       ,0                          order_quantity           -- 受注明細.受注数量           ：受注数
       ,NVL( xola.shipped_quantity, 0 )
                                   deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
       ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
       ,0 - NVL( xola.shipped_quantity, 0 )
                                   output_quantity          -- 差異数
     FROM
        xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
       ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
       ,mtl_item_locations         mil   -- 
       ,hr_all_organization_units  haou  -- 
       ,ic_whse_mst                iwm   -- 
       ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
       ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
       ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
       ,ic_item_mst_b              iimb  -- OPM品目
       ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
     WHERE
          xoha.order_header_id      = xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
     AND  xoha.req_status           = cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
     AND  xoha.latest_external_flag = cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
     AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
     AND  iwm.mtl_organization_id   = haou.organization_id        -- 
     AND  haou.organization_id      = mil.organization_id         -- 
     AND  xoha.deliver_from         = mil.segment1                -- 
     AND  haou.date_from           <= gd_process_date             -- 
     AND  TRUNC( NVL( haou.date_to, gd_process_date ) ) >= gd_process_date
     AND  xoha.customer_code        = hca.account_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
     AND  hca.cust_account_id       = xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
-- 2010/04/09 Ver.1.14 Del M.Sano Start
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----     AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                               ,cv_base_all
----                                               ,xca.delivery_base_code
----                                               ,iv_base_code )
-- 2010/04/09 Ver.1.14 Del M.Sano End
     AND  hca2.customer_class_code  =  cv_party_type_1            -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
     AND  hca2.account_number       =  xca.delivery_base_code     -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
     AND  xola.request_item_code    =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = OPM品目.品目ｺｰﾄﾞ
     AND  iimb.item_id              =  ximb.item_id               -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
     AND  TRUNC( ximb.start_date_active )                   <= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
     AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
     AND NOT EXISTS(
             SELECT
               /*+
               USE_NL( ooha oola hca xca mtsi )
               */
               'X'                         exists_flag -- EXISTSﾌﾗｸﾞ
             FROM
                oe_order_headers_all        ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
               ,oe_order_lines_all          oola        -- 受注明細ﾃｰﾌﾞﾙ
               ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
               ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
               ,mtl_secondary_inventories   mtsi        -- 保管場所ﾏｽﾀ
             WHERE
                  ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
             AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
             AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
             AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
             AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
                                                                           -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
             AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
             AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
             AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
             AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                                 'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                               FROM
                                 fnd_lookup_values  flv
                               WHERE
                                    flv.lookup_type             = cv_no_inv_item_code
                               AND  flv.start_date_active      <= gd_process_date
                               AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                               AND  flv.enabled_flag            = cv_yes_flg
                               AND  flv.language                = cv_user_lang
                               AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                             )
             AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
             AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
-- 2011/04/18 Ver1.16 Mod Start Y.Kanami
             AND  xca.delivery_base_code    =   hca2.account_number        -- 顧客追加情報マスタ.納品拠点 = 顧客マスタ2.顧客コード
-- 2011/04/18 Ver1.16 Mod End Y.Kanami
                                                                           -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
-- 2010/04/09 Ver.1.14 Del M.Sano Start
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----             AND  xca.delivery_base_code     =  DECODE( iv_base_code
----                                                       ,cv_base_all
----                                                       ,xca.delivery_base_code
----                                                       ,iv_base_code )
-- 2010/04/09 Ver.1.14 Del M.Sano End
             AND  xoha.request_no            =  oola.packing_instructions -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No = 受注明細.梱包指示
                                                                          -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = NVL(受注明細.子コード,受注明細.受注品目)
             AND  xola.request_item_code    =  NVL( oola.attribute6, oola.ordered_item )
             AND  oola.request_date         >= TO_DATE(gd_trans_start_date)
             )
     AND  NVL( xola.shipped_quantity, 0 ) != 0 -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量が0以外
     AND  xoha.arrival_date >= to_date(gd_trans_start_date)
--     ;
--
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
-- 2011/03/08 Ver.1.15 Add K.Kiriu Start
     AND  xoha.arrival_date < gd_trans_end_date --前月着荷日(業務日付の月初より前)のみ出力
-- 2011/03/08 Ver.1.15 Add K.Kiriu End
     ;
--
    -- =========================================================================
    --** [拠点指定]例外２
    --** ①～④に該当するエラーデータの抽出SQL
    --**   ① 受注あり-出荷実績なし ※出荷依頼No存在なしエラー
    --**   ② 受注あり-出荷実績なし ※明細品目不一致エラー
    --**   ③ 受注なし-出荷実績あり ※出荷依頼No存在なしエラー
    --**   ④ 受注なし-出荷実績あり ※明細品目不一致エラー
    -- =========================================================================
     CURSOR line_item_excep_cur_base
     IS
    -- ======================================================
    -- [拠点指定]例外２
    -- ① 受注あり-出荷実績なし ※出荷依頼No存在なしエラー
    -- ② 受注あり-出荷実績なし ※明細品目不一致エラー
    -- ======================================================
     SELECT
        /*+
         LEADING(hca2 xca hca)
         USE_NL( oola mtsi ottt otta )
        */
        xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
       ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
       ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
       ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
       ,NULL                       line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
       ,SUBSTRB(oola.packing_instructions, 1, 12)
                                   deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
       ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
       ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
       ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
       ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
       ,NVL( oola.attribute6, oola.ordered_item )
                                   item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
       ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
       ,TRUNC( oola.request_date ) schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
       ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
       ,NULL                       arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
       ,oola.ordered_quantity * 
         DECODE ( otta.order_category_code, cv_order, 1, -1 )
                                   order_quantity           -- 受注明細.受注数量           ：受注数
       ,0                          deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
       ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
       ,oola.ordered_quantity      output_quantity          -- 差異数
     FROM
        oe_order_headers_all        ooha          -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
       ,oe_order_lines_all          oola          -- 受注明細ﾃｰﾌﾞﾙ
       ,hz_cust_accounts            hca           -- 顧客ﾏｽﾀ
       ,xxcmm_cust_accounts         xca           -- 顧客追加情報ﾏｽﾀ
       ,mtl_secondary_inventories   mtsi          -- 保管場所ﾏｽﾀ
       ,hz_cust_accounts            hca2          -- 顧客ﾏｽﾀ2
       ,ic_item_mst_b               iimb          -- OPM品目
       ,xxcmn_item_mst_b            ximb          -- OPM品目ｱﾄﾞｵﾝ
       ,oe_transaction_types_tl     ottt          -- 受注取引タイプ（摘要）
       ,oe_transaction_types_all    otta          -- 受注取引タイプマスタ
     WHERE
          ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
     AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
     AND  oola.line_type_id        = ottt.transaction_type_id    -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
     AND  ottt.transaction_type_id = otta.transaction_type_id    -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
     AND  ottt.language            = cv_user_lang                -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
     AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
     AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
     AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
-- 2011/11/11 Ver.1.17 Mod Start
--     AND  ooha.flow_status_code  IN ( cv_status_booked , cv_status_closed ) -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--     AND  oola.flow_status_code  <> cv_status_cancelled          -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
     AND  ooha.flow_status_code  =  cv_status_booked             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
     AND  oola.flow_status_code  =  cv_status_booked             -- 受注明細.ｽﾃｰﾀｽ = 'BOOKED'
-- 2011/11/11 Ver.1.17 Mod End
     AND  oola.org_id       = gn_org_id
     AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
     AND  NOT EXISTS ( SELECT                                    -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                         'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                       FROM
                         fnd_lookup_values  flv
                       WHERE
                            flv.lookup_type             = cv_no_inv_item_code
                       AND  flv.start_date_active      <= gd_process_date
                       AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                       AND  flv.enabled_flag            = cv_yes_flg
                       AND  flv.language                = cv_user_lang
                       AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                    )
     AND  ooha.sold_to_org_id       =  hca.cust_account_id          -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
     AND  hca.cust_account_id       =  xca.customer_id              -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
     AND  xca.delivery_base_code    = iv_base_code
     AND  hca2.customer_class_code  =  cv_party_type_1              -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
     AND  hca2.account_number       =  xca.delivery_base_code       -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
     AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
     AND  iimb.item_id              =  ximb.item_id                 -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
     AND  TRUNC( ximb.start_date_active )                   <= gd_process_date   -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
     AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date   -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
     AND NOT EXISTS(
             SELECT
              /*+
                USE_NL( xoha xola hca xca mtsi )
              */
               'X'                          exists_flag -- EXISTSﾌﾗｸﾞ
             FROM
                xxwsh_order_headers_all     xoha        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
               ,xxwsh_order_lines_all       xola        -- 受注明細ｱﾄﾞｵﾝ
               ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
               ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
             WHERE
                  xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
             AND  xoha.req_status           <>  cv_h_add_status_99        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ <> 取消
             AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
             AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
             AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
             AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
             AND  xca.delivery_base_code    =   iv_base_code
             AND NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= to_date( gd_trans_start_date )
             AND  oola.packing_instructions =   xoha.request_no   -- 受注明細.梱包指示 = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No
                                                                  -- NVL(受注明細.子コード,受注明細.受注品目) = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼品目
             AND  NVL( oola.attribute6, oola.ordered_item ) = xola.request_item_code
             )
-- 2011/11/11 Ver.1.17 Mod Start
--       AND  ( ( oola.flow_status_code = cv_status_closed
--              AND oola.request_date >= to_date( gd_target_closed_month ) )
--            OR ( oola.flow_status_code <> cv_status_closed
--              AND oola.request_date >= to_date( gd_trans_start_date ) )
--            )
     AND  oola.request_date >= to_date( gd_trans_start_date )
-- 2011/11/11 Ver.1.17 Mod End
     UNION ALL
    -- ======================================================
    -- [拠点指定]例外２
    -- ③ 受注なし-出荷実績あり ※出荷依頼No存在なしエラー
    -- ④ 受注なし-出荷実績あり ※明細品目不一致エラー
    -- ======================================================
     SELECT
       /*+
         LEADING( xoha hca xca )
         INDEX( haou hr_all_organizaion_units_pk )
         USE_NL( xoha xola iwm mil haou hca xca hca2 iimb ximb )
       */
        xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
       ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
       ,NULL                       order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
       ,NULL                       order_line_no            -- 受注明細.明細番号           ：受注明細No
       ,xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
       ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
       ,xoha.deliver_from          deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
       ,mil.description            deliver_from_whse_name   -- OPM保管場所ﾏｽﾀ.保管場所名称 ：出荷元倉庫名
       ,xoha.customer_code         customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
       ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
       ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
       ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
       ,NULL                       schedule_dlv_date        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着日          ：納品予定日
       ,NULL                       schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
       ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
       ,0                          order_quantity           -- 受注明細.受注数量           ：受注数
       ,NVL( xola.shipped_quantity, 0 )
                                   deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
       ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
       ,0 - NVL( xola.shipped_quantity, 0 )
                                   output_quantity          -- 差異数
     FROM
        xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
       ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
       ,mtl_item_locations         mil   -- OPM保管場所マスタ
       ,hr_all_organization_units  haou  -- 在庫組織マスタ
       ,ic_whse_mst                iwm   -- OPM倉庫マスタ
       ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
       ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
       ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
       ,ic_item_mst_b              iimb  -- OPM品目
       ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
     WHERE
          xoha.order_header_id      = xola.order_header_id        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
     AND  xoha.req_status           = cv_h_add_status_04          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
     AND  xoha.latest_external_flag = cv_yes_flg                  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
     AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
     AND  iwm.mtl_organization_id   = haou.organization_id
     AND  haou.organization_id      = mil.organization_id
     AND  xoha.deliver_from         = mil.segment1                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所 = OPM保管場所ﾏｽﾀ.保管倉庫コード
     AND  haou.date_from           <= gd_process_date             -- OPM保管場所ﾏｽﾀ.組織有効開始日 <= 業務日付
     AND  TRUNC( NVL( haou.date_to, gd_process_date ) ) >= gd_process_date
     AND  xoha.customer_code        = hca.account_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
     AND  hca.cust_account_id       = xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
     AND  xca.delivery_base_code    = iv_base_code                -- 顧客追加情報ﾏｽﾀ.拠点コード = 入力パラメータ.拠点コード
     AND  hca2.customer_class_code  =  cv_party_type_1            -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
     AND  hca2.account_number       =  xca.delivery_base_code     -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
     AND  xola.request_item_code    =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = OPM品目.品目ｺｰﾄﾞ
     AND  iimb.item_id              =  ximb.item_id               -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
     AND  TRUNC( ximb.start_date_active )                   <= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
     AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
     AND NOT EXISTS(
             SELECT
               /*+
               USE_NL( ooha oola hca xca mtsi )
               */
               'X'                         exists_flag -- EXISTSﾌﾗｸﾞ
             FROM
                oe_order_headers_all        ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
               ,oe_order_lines_all          oola        -- 受注明細ﾃｰﾌﾞﾙ
               ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
               ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
               ,mtl_secondary_inventories   mtsi        -- 保管場所ﾏｽﾀ
             WHERE
                  ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
             AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
             AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
             AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
             AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
                                                                           -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
             AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
             AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
             AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
             AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                                 'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                               FROM
                                 fnd_lookup_values  flv
                               WHERE
                                    flv.lookup_type             = cv_no_inv_item_code
                               AND  flv.start_date_active      <= gd_process_date
                               AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                               AND  flv.enabled_flag            = cv_yes_flg
                               AND  flv.language                = cv_user_lang
                               AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                             )
             AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
             AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
             AND  xca.delivery_base_code     =  iv_base_code
             AND  xoha.request_no            =  oola.packing_instructions -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No = 受注明細.梱包指示
                                                                          -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = NVL(受注明細.子コード,受注明細.受注品目)
             AND  xola.request_item_code    =  NVL( oola.attribute6, oola.ordered_item )
             AND  oola.request_date         >= TO_DATE(gd_trans_start_date)
             )
     AND  NVL( xola.shipped_quantity, 0 ) != 0 -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量が0以外
     AND  xoha.arrival_date >= to_date(gd_trans_start_date)
     ;
--     UNION ALL
----
--     --** ■例外2-3取得SQL(旧例外４)
--     -- 受注データなしエラー(出荷実績あり)
----     CURSOR no_order_excep_cur
----     IS
--     SELECT
--        /*+
--          LEADING( xoha )
--          INDEX( haou hr_all_organizaion_units_pk)
--          --USE_NL( xoha hca xca hca2 mil haou iwm )
--          --USE_NL( xola iimb ximb )
--          USE_NL( xoha xola iwm mil haou hca xca hca2 iimb ximb )
--        */
--        xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--       ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--       ,NULL                       order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--       ,NULL                       order_line_no            -- 受注明細.明細番号           ：受注明細No
--       ,xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--       ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
--       ,xoha.deliver_from          deliver_from_whse_number -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.出荷元保管場所：出荷元倉庫番号
--       ,mil.description            deliver_from_whse_name 
--       ,xoha.customer_code         customer_number          -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客          ：顧客番号
--       ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--       ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
--       ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--       ,NULL                       schedule_dlv_date        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着日          ：納品予定日
--       ,NULL                       schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--       ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--       ,0                          order_quantity           -- 受注明細.受注数量           ：受注数
--       ,NVL( xola.shipped_quantity, 0 )
--                                   deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--       ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
--       ,0 - NVL( xola.shipped_quantity, 0 )
--                                   output_quantity          -- 差異数
--     FROM
--        xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--       ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
--       ,mtl_item_locations         mil   -- OPM保管場所マスタ
--       ,ic_whse_mst                iwm   -- 
--       ,hr_all_organization_units  haou  -- 在庫組織マスタ
--       ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--       ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--       ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--       ,ic_item_mst_b              iimb  -- OPM品目
--       ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--     WHERE
--          xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--     AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
--     AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--     AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
--     AND  NVL( xola.shipped_quantity, 0 ) != 0                    -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量が0以外
--     AND  iwm.mtl_organization_id = haou.organization_id
--     AND  haou.organization_id    = mil.organization_id
--     AND  haou.date_from         <= gd_process_date
--     AND  TRUNC( NVL( haou.date_to, gd_process_date ) ) >= gd_process_date
--     AND  xoha.deliver_from   = mil.segment1
--     AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
--     AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID       = 顧客追加情報ﾏｽﾀ.顧客ID
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----     AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                               ,cv_base_all
----                                               ,xca.delivery_base_code
----                                               ,iv_base_code )
--     AND  hca2.customer_class_code  =  cv_party_type_1            -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--     AND  hca2.account_number       =  xca.delivery_base_code     -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--     AND  xola.request_item_code   =  iimb.item_no               -- 受注明細ｱﾄﾞｵﾝ.依頼品目 = OPM品目.品目ｺｰﾄﾞ
--     AND  iimb.item_id              =  ximb.item_id               -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--     AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--     AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--     AND NOT EXISTS(
--             SELECT
--                /*+
--                  USE_NL( ooha hca xca )
--                  USE_NL( oola mtsi )
--                */
--               'X'                       exists_flag -- EXISTSﾌﾗｸﾞ
--             FROM
--                oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--               ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
--               ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
--               ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
--               ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
--             WHERE
--                  ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--             AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--             AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--             AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--             AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--                                                                           -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
--             AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
--             AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
--             AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
--             AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                                 'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                               FROM
--                                 fnd_lookup_values  flv
--                               WHERE
--                                    flv.lookup_type             = cv_no_inv_item_code
--                               AND  flv.start_date_active      <= gd_process_date
--                               AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                               AND  flv.enabled_flag            = cv_yes_flg
--                               AND  flv.language                = cv_user_lang
--                               AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                             )
--             AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--             AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                           -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----             AND  xca.delivery_base_code     =  DECODE( iv_base_code
----                                                       ,cv_base_all
----                                                       ,xca.delivery_base_code
----                                                       ,iv_base_code )
--             AND  xoha.request_no            =  oola.packing_instructions  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No = 受注明細.梱包指示
--             AND  oola.request_date         >= to_date(gd_trans_start_date)
--             )
--     AND  xoha.arrival_date >= to_date(gd_trans_start_date)
----     ;
----
--     UNION ALL
----
----
--     --** ■例外2-4取得SQL(旧例外５)
--     -- 出荷実績なしエラー(受注データあり)
----     CURSOR no_actual_excep_cur
----     IS
--     SELECT
--        /*+
--          LEADING(ooha)
--          INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
--          INDEX(oola XXCOS_OE_ORDER_LINES_ALL_N23)
--          USE_NL( ooha hca )
--          USE_NL( oola mtsi ottt otta iimb ximb )
--        */
--        xca.delivery_base_code     base_code                -- 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ：拠点ｺｰﾄﾞ
--       ,hca2.account_name          base_name                -- 顧客ﾏｽﾀ2.顧客名称           ：拠点名称
--       ,ooha.order_number          order_number             -- 受注ﾍｯﾀﾞ.受注番号           ：受注番号
--       ,oola.line_number           order_line_no            -- 受注明細.明細番号           ：受注明細No
--       ,NULL                       line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
--       ,SUBSTRB(oola.packing_instructions, 1, 12) deliver_requested_no     -- 受注明細.梱包指示           ：出荷依頼No
--       ,oola.subinventory          deliver_from_whse_number -- 受注明細.保管場所           ：出荷元倉庫番号
--       ,mtsi.description           deliver_from_whse_name   -- 保管場所.保管場所名称       ：出荷元倉庫名
--       ,hca.account_number         customer_number          -- 顧客ﾏｽﾀ.顧客ｺｰﾄﾞ            ：顧客番号
--       ,hca.account_name           customer_name            -- 顧客ﾏｽﾀ.顧客名称            ：顧客名
--       ,NVL( oola.attribute6, oola.ordered_item )
--                                   item_code                -- 受注明細.受注品目           ：品目ｺｰﾄﾞ
--       ,ximb.item_short_name       item_name                -- OPM品目ｱﾄﾞｵﾝ                ：品名
--       ,TRUNC( oola.request_date ) schedule_dlv_date        -- 受注明細.要求日             ：納品予定日
--       ,oola.attribute4            schedule_inspect_date    -- 受注明細.検収予定日         ：検収予定日
--       ,NULL                       arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
--       ,oola.ordered_quantity * 
--         DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                                   order_quantity           -- 受注明細.受注数量           ：受注数
--       ,0                          deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
--       ,oola.order_quantity_uom    uom_code                 -- 受注明細.受注単位           ：単位
--       ,oola.ordered_quantity      output_quantity          -- 差異数
--     FROM
--        oe_order_headers_all       ooha  -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
--       ,oe_order_lines_all         oola  -- 受注明細ﾃｰﾌﾞﾙ
--       ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
--       ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
--       ,mtl_secondary_inventories  mtsi  -- 保管場所ﾏｽﾀ
--       ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
--       ,ic_item_mst_b              iimb  -- OPM品目
--       ,xxcmn_item_mst_b           ximb  -- OPM品目ｱﾄﾞｵﾝ
--       ,oe_transaction_types_tl    ottt  -- 受注取引タイプ（摘要）
--       ,oe_transaction_types_all   otta  -- 受注取引タイプマスタ
--     WHERE
--          ooha.header_id    =  oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
--     AND  ooha.org_id       =  gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
--     AND  oola.subinventory =  mtsi.secondary_inventory_name     -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
--     AND  oola.line_type_id        = ottt.transaction_type_id    -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
--     AND  ottt.transaction_type_id = otta.transaction_type_id    -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
--     AND  ottt.language            = cv_user_lang           -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
--     AND  oola.ship_from_org_id  =  mtsi.organization_id         -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
--     AND  mtsi.attribute13       =  gv_subinventory_class        -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
--     AND  ooha.flow_status_code  = cv_status_booked  -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ = 'BOOKED'
--     AND  oola.flow_status_code  NOT IN ( cv_status_cancelled, cv_status_closed )         -- 受注明細.ｽﾃｰﾀｽ NOT IN ('CANCELLED', 'CLOSED')
--     AND  oola.org_id                = gn_org_id
--     AND  oola.packing_instructions  IS NOT NULL                 -- 受注明細.梱包指示 IS NOT NULL
--     AND  NOT EXISTS ( SELECT                                    -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
--                         'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
--                       FROM
--                         fnd_lookup_values  flv
--                       WHERE
--                            flv.lookup_type             = cv_no_inv_item_code
--                       AND  flv.start_date_active      <= gd_process_date
--                       AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                       AND  flv.enabled_flag            = cv_yes_flg
--                       AND  flv.language                = cv_user_lang
--                       AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
--                    )
--     AND  ooha.sold_to_org_id     =  hca.cust_account_id         -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
--     AND  hca.cust_account_id     =  xca.customer_id             -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
--                                                                 -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----     AND  xca.delivery_base_code  =  DECODE( iv_base_code 
----                                            ,cv_base_all
----                                            ,xca.delivery_base_code
----                                            ,iv_base_code  )
--     AND  hca2.customer_class_code  =  cv_party_type_1              -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
--     AND  hca2.account_number       =  xca.delivery_base_code       -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
--     AND  NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no  -- NVL(受注明細.子コード,受注明細.受注品目) = OPM品目.品目ｺｰﾄﾞ
--     AND  iimb.item_id              =  ximb.item_id                 -- OPM品目.品目ID = OPM品目ｱﾄﾞｵﾝ.品目id
--     AND  TRUNC( ximb.start_date_active )                    <=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用開始日 <= 業務日付
--     AND  TRUNC( NVL( ximb.end_date_active, gd_max_date ) )  >=  gd_process_date    -- OPM品目ｱﾄﾞｵﾝ.適用終了日 >= 業務日付
--     AND NOT EXISTS(
--             SELECT
--               /*+
--                 USE_NL( xoha xola hca xca )
--               */
--               'X'                          exists_flag -- EXISTSﾌﾗｸﾞ
--             FROM
--                xxwsh_order_headers_all     xoha        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
--               ,xxwsh_order_lines_all       xola        -- 受注明細ｱﾄﾞｵﾝ
--               ,hz_cust_accounts            hca         -- 顧客ﾏｽﾀ
--               ,xxcmm_cust_accounts         xca         -- 顧客追加情報ﾏｽﾀ
--             WHERE
--                  xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
--             AND  xoha.req_status           <>  cv_h_add_status_99        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ <> 取消
--             AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--             AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
--             AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
--             AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID = 顧客追加情報ﾏｽﾀ.顧客ID
--               AND  ( ( iv_base_code = cv_base_all )
--                      OR
--                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
--                    )
----             AND  xca.delivery_base_code    =   DECODE( iv_base_code       -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
----                                                       ,cv_base_all
----                                                       ,xca.delivery_base_code
----                                                       ,iv_base_code )
--             AND  oola.packing_instructions =   xoha.request_no           -- 受注明細.梱包指示 = 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No
--             AND  NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= to_date( gd_trans_start_date )
--             )
--     AND  ( ( oola.flow_status_code = cv_status_closed
--            AND oola.request_date >= to_date( gd_target_closed_month ) )
--          OR ( oola.flow_status_code <> cv_status_closed
--            AND oola.request_date >= to_date( gd_trans_start_date ) )
--          )
--     ;
-- 2010/04/09 Ver.1.14 Mod M.Sano End
--
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--     --** ■例外３チェックデータ取得SQL
--     CURSOR get_check_data_cur
--     IS
--     SELECT   ooa1.deliver_requested_no      ooa1_deliver_requested_no
    -- =========================================================================
    --** [ALL・拠点指定]例外３
    --** ①～③のチェック対象となる[受注-出荷実績]データ抽出SQL
    --**   ① 数量と出荷依頼実績数量が異なる
    --**   ② 納品予定日と着荷日が異なる
    --**   ③ 納品予定日(着荷日)と検収予定日の妥当性
    -- =========================================================================
     CURSOR get_check_data_cur
     IS
     SELECT   /*+
                LEADING( ooa2 )
                USE_NL( ooa2.xoha ooa1.oola )
              */
              ooa1.deliver_requested_no      ooa1_deliver_requested_no       -- 受注：出荷依頼No
-- 2010/04/09 Ver.1.14 Mod M.Sano End
             ,ooa1.item_code                 ooa1_item_code
             ,ooa1.order_quantity            ooa1_order_quantity
             ,ooa1.line_id                   ooa1_line_id
             ,ooa1.schedule_dlv_date         ooa1_schedule_dlv_date
             ,ooa1.min_schedule_inspect_date ooa1_min_schedule_inspect_date
             ,ooa1.max_schedule_inspect_date ooa1_max_schedule_inspect_date
             ,ooa2.line_no                   ooa2_line_no
             ,ooa2.arrival_date              ooa2_arrival_date
             ,ooa2.deliver_actual_quantity   ooa2_deliver_actual_quantity
             ,ooa2.uom_code                  ooa2_uom_code
     FROM
               (
               /* 受注部分のみ */
               SELECT
                  /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--                    ORDERED
--                    INDEX( ooha XXCOS_OE_ORDER_HEADERS_ALL_N11 )
--                    INDEX( oola XXCOS_OE_ORDER_LINES_ALL_N23 )
--                    INDEX( xca xxcmm_cust_accounts_pk )
                    LEADING( oola )
                    INDEX( xca xxcmm_cust_accounts_n15 )
                    USE_NL( oola item_cnv ) 
-- 2010/04/09 Ver.1.14 Mod M.Sano End
                    USE_NL( ooha hca xca )
                    USE_NL( oola mtsi otta ottt msib xicv )
                  */
                  oola.packing_instructions                    deliver_requested_no     -- 受注明細.梱包指示（出荷依頼No）
                 ,NVL( oola.attribute6, oola.ordered_item )    item_code                -- NVL(受注明細.子コード,受注明細.受注品目)
                 ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                        * CASE oola.order_quantity_uom
                          WHEN msib.primary_unit_of_measure THEN 1
                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                          ELSE NVL( xicv.conversion_rate, 0 )
                        END
                  ) AS order_quantity
                 ,TRUNC( oola.request_date )     schedule_dlv_date
                 ,MAX(oola.line_id)              line_id
                 ,MIN(oola.attribute4)           min_schedule_inspect_date
                 ,MAX(oola.attribute4)           max_schedule_inspect_date
               FROM
                  oe_order_headers_all       ooha        -- 受注ﾍｯﾀﾞﾃｰﾌﾞﾙ
                 ,oe_order_lines_all         oola        -- 受注明細ﾃｰﾌﾞﾙ
                 ,hz_cust_accounts           hca         -- 顧客ﾏｽﾀ
                 ,xxcmm_cust_accounts        xca         -- 顧客追加情報ﾏｽﾀ
                 ,mtl_secondary_inventories  mtsi        -- 保管場所ﾏｽﾀ
                 ,mtl_system_items_b         msib        -- Disc品目（営業組織）
                 ,oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
                 ,oe_transaction_types_all   otta        -- 受注取引タイプマスタ
                 ,xxcos_item_conversions_v   xicv        -- 品目換算View
                 ,(
                   SELECT
                       flv.meaning      AS UOM_CODE
                     , flv.description  AS CNV_VALUE
                   FROM
                     applsys.fnd_lookup_values flv
                   WHERE
                         flv.enabled_flag          = cv_yes_flg
                     AND flv.language                = cv_user_lang
                     AND flv.start_date_active    <= gd_process_date
                     AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
                     AND flv.lookup_type           = cv_weight_uom_cnv_mst
                 ) item_cnv
               WHERE
                    ooha.header_id    =  oola.header_id                      -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
               AND  ooha.org_id       =  gn_org_id                           -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
               AND  oola.line_type_id        = ottt.transaction_type_id      -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
               AND  ottt.transaction_type_id = otta.transaction_type_id      -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
               AND  ottt.language            = cv_user_lang                  -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
               AND  oola.subinventory =  mtsi.secondary_inventory_name       -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
               AND  oola.ship_from_org_id  =  mtsi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
               AND  mtsi.attribute13       =  gv_subinventory_class          -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
                                                                             -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
               AND  ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )
               AND  oola.flow_status_code      <> cv_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
               AND  oola.org_id       =  gn_org_id                           -- 受注明細.組織ID = A-1取得の営業単位
               AND  oola.packing_instructions  IS NOT NULL                   -- 受注明細.梱包指示 IS NOT NULL
               AND  NOT EXISTS ( SELECT                                      -- NVL(受注明細.子コード,受注明細.受注品目)≠非在庫品目コード
                                   'X'                 exists_flag -- EXISTSﾌﾗｸﾞ
                                 FROM
                                   applsys.fnd_lookup_values  flv
                                 WHERE
                                      flv.lookup_type             = cv_no_inv_item_code
                                 AND  flv.start_date_active      <= gd_process_date
                                 AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                 AND  flv.enabled_flag            = cv_yes_flg
                                 AND  flv.language                = cv_user_lang
                                 AND  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code
                               )
               AND  ooha.sold_to_org_id        =  hca.cust_account_id        -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
               AND  hca.cust_account_id        =  xca.customer_id            -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
                                                                             -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
               AND  ( ( iv_base_code = cv_base_all )
                      OR
                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
                    )
--               AND  xca.delivery_base_code     =  DECODE( iv_base_code
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
                                                                             --     = Disc品目.品目コード
               AND  NVL( oola.attribute6, oola.ordered_item ) = msib.segment1
               AND  oola.ship_from_org_id      = msib.organization_id        -- 受注明細.出荷元組織 = Disc品目.組織ID
                                                                             -- NVL(受注明細.子コード,受注明細.受注品目)
               AND  NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)  --     = 品目換算View.品目コード
               AND  oola.order_quantity_uom    = xicv.to_uom_code(+)         -- 受注明細.受注単位 = 品目換算View.変換先単位
               AND  oola.order_quantity_uom    = item_cnv.uom_code(+)
               AND  ( ( oola.flow_status_code = cv_status_closed
                      AND oola.request_date >= to_date(gd_target_closed_month))
                    OR ( oola.flow_status_code <> cv_status_closed
                      AND oola.request_date >= to_date(gd_trans_start_date))
                    )
               GROUP BY
                  oola.packing_instructions
                 ,NVL( oola.attribute6, oola.ordered_item )
                 ,TRUNC( oola.request_date )
               ) ooa1
              ,(
               /* 生産部分のみ */
               SELECT
                  /*+
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--                    INDEX(xca xxcmm_cust_accounts_pk)
--                    USE_NL( xoha xola hca xca )
                    LEADING( xoha hca xca )
                    INDEX( xca xxcmm_cust_accounts_n15 )
                    USE_NL(xoha hca xca )
-- 2010/04/09 Ver.1.14 Mod M.Sano End
                  */
                  xola.order_line_number     line_no                  -- 受注明細ｱﾄﾞｵﾝ.明細番号      ：明細No
                 ,xoha.request_no            deliver_requested_no     -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No        ：出荷依頼No
                 ,xola.request_item_code     item_code                -- 受注明細ｱﾄﾞｵﾝ.依頼品目      ：品目ｺｰﾄﾞ
                 ,xoha.arrival_date          arrival_date             -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.着荷日        ：着日
                 ,xola.shipped_quantity      deliver_actual_quantity  -- 受注明細ｱﾄﾞｵﾝ.出荷実績数量  ：出荷実績数
                 ,xola.uom_code              uom_code                 -- 受注明細ｱﾄﾞｵﾝ.単位          ：単位
               FROM
                  xxwsh_order_headers_all    xoha  -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ
                 ,xxwsh_order_lines_all      xola  -- 受注明細ｱﾄﾞｵﾝ
                 ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
               WHERE
                    xoha.order_header_id      =   xola.order_header_id      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID = 受注明細ｱﾄﾞｵﾝ.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
               AND  xoha.req_status           =   cv_h_add_status_04        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ = 出荷実績計上済
               AND  xoha.latest_external_flag =   cv_yes_flg                -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
               AND  NVL( xola.delete_flag, cv_no_flg ) = cv_no_flg          -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
               AND  xola.shipped_quantity IS NOT NULL
               AND  xoha.customer_code        =   hca.account_number        -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.顧客 = 顧客ﾏｽﾀ.顧客コード
               AND  hca.cust_account_id       =   xca.customer_id           -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
               AND  ( ( iv_base_code = cv_base_all )
                      OR
                      ( iv_base_code != cv_base_all ) AND ( xca.delivery_base_code = iv_base_code )
                    )
--               AND  xca.delivery_base_code    =   DECODE( iv_base_code      -- 顧客追加情報ﾏｽﾀ.納品拠点 = DECODE('ALL','ALL',ﾊﾟﾗﾒｰﾀ.拠点ｺｰﾄﾞ)
--                                                         ,cv_base_all
--                                                         ,xca.delivery_base_code
--                                                         ,iv_base_code )
               AND xoha.arrival_date >= TO_DATE(gd_trans_start_date)
               ) ooa2
     WHERE
          ooa1.deliver_requested_no =   ooa2.deliver_requested_no      -- 営業サブクエリ.出荷依頼No =  生産サブクエリ.出荷依頼No
     AND  ooa1.item_code            =   ooa2.item_code                 -- 営業サブクエリ.品目コード =  生産サブクエリ.品目コード
--     AND  ooa1.order_quantity      !=   0                              -- 営業サブクエリ.受注数    !=  0
--     AND  ooa1.schedule_dlv_date    =   ooa2.arrival_date
--     AND  NVL( TO_DATE(ooa1.min_schedule_inspect_date,cv_yyyymmddhhmiss),ooa1.schedule_dlv_date ) >= ooa1.schedule_dlv_date
--     AND  NVL( TO_DATE(ooa1.max_schedule_inspect_date,cv_yyyymmddhhmiss),ooa1.schedule_dlv_date ) >= ooa1.schedule_dlv_date
-- 2011/03/08 Ver.1.15 Add K.Kiriu Start
    AND   ( 
            ( 
              ( iv_base_code = cv_base_all )
              AND
              ( ( ooa1.schedule_dlv_date < gd_trans_end_date )
                OR
                ( ooa2.arrival_date      < gd_trans_end_date )
              )
            )  --'ALL'の場合、納品日or着荷日が前月(業務日付の月初より前)のみ出力
            OR
            (
              ( iv_base_code != cv_base_all )
            )
          )
-- 2011/03/08 Ver.1.15 Add K.Kiriu End
     ;
--
--
     --** ■検収日不整合データ取得SQL
     CURSOR get_insp_inconsistent_cur (
                                   it_packing_instructions oe_order_lines_all.packing_instructions%TYPE  -- 出荷依頼No
                                  ,it_item_code            oe_order_lines_all.ordered_item%TYPE          -- 品目コード
                                  )
     IS
     SELECT 
            /*+
            USE_NL( oola ooha mtsi iimb ximb hca xca hca2 xicv item_cnv msib ottt otta )
            */
             ooha.order_number                         order_number              -- 受注番号
            ,oola.line_number                          line_number               -- 受注明細番号
            ,oola.subinventory                         subinventory_code         -- 受注：保管場所コード
            ,mtsi.description                          subinventory_name         -- 受注：保管場所名称
            ,NVL( oola.attribute6, oola.ordered_item ) item_code                 -- 受注：品目コード
            ,ximb.item_short_name                      item_name                 -- 受注：品目名
            ,TRUNC(oola.request_date)                  schedule_dlv_date         -- 受注：納品予定日
            ,oola.attribute4                           schedule_inspect_date     -- 受注：検収予定日
            ,xca.delivery_base_code                    base_code                 -- 受注：拠点ｺｰﾄﾞ
            ,hca2.account_name                         base_name                 -- 受注：拠点名称
            ,hca.account_number                        customer_number           -- 受注：顧客番号
            ,hca.account_name                          customer_name             -- 受注：顧客名
            ,oola.line_id                              line_id                   -- 受注：明細ID
--            ,SUM( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
--                        * CASE oola.order_quantity_uom
--                          WHEN msib.primary_unit_of_measure THEN 1
--                          WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
--                          ELSE NVL( xicv.conversion_rate, 0 )
--                        END
--                  ) AS order_quantity
            ,( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                    * CASE oola.order_quantity_uom
                      WHEN msib.primary_unit_of_measure THEN 1
                      WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                      ELSE NVL( xicv.conversion_rate, 0 )
                    END
              ) AS order_quantity
     FROM    oe_order_lines_all         oola  -- 受注明細
            ,oe_order_headers_all       ooha  -- 受注ヘッダ
            ,mtl_secondary_inventories  mtsi  -- 保管場所マスタ
            ,ic_item_mst_b              iimb  -- OPM品目マスタ
            ,xxcmn_item_mst_b           ximb  -- OPM品目アドオン
            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
            ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
            ,xxcos_item_conversions_v  xicv   -- 品目換算View
            ,(
              SELECT
                 flv.meaning      AS UOM_CODE
               , flv.description  AS CNV_VALUE
              FROM
                 fnd_lookup_values flv
              WHERE
                 flv.enabled_flag          = cv_yes_flg
              AND flv.language                = cv_user_lang
              AND flv.start_date_active    <= gd_process_date
              AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
              AND flv.lookup_type           = cv_weight_uom_cnv_mst
              ) item_cnv
             ,inv.mtl_system_items_b         msib        -- Disc品目（営業組織）
             ,ont.oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
             ,ont.oe_transaction_types_all   otta        -- 受注取引タイプマスタ
     WHERE   oola.header_id           =  ooha.header_id
     AND     ooha.org_id              =  gn_org_id                               -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
     AND     oola.line_type_id        =  ottt.transaction_type_id                -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
     AND     ottt.transaction_type_id =  otta.transaction_type_id                -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
     AND     ottt.language            =  cv_user_lang                            -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
     AND     oola.subinventory        =  mtsi.secondary_inventory_name           -- 受注明細.保管場所 = 保管場所マスタ.保管場所
     AND     oola.ship_from_org_id    =  mtsi.organization_id                    -- 受注明細.出荷元組織ID = 保管場所マスタ.在庫組織ID
     AND     mtsi.attribute13         =  gv_subinventory_class                   -- 保管場所区分 = '11':直送
     AND     ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )-- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
     AND     oola.flow_status_code      <> cv_status_cancelled                   -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
     AND     oola.org_id                =  gn_org_id                             -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
     AND     ooha.sold_to_org_id        =  hca.cust_account_id                   -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
     AND     NVL( oola.attribute6, oola.ordered_item ) = msib.segment1           -- NVL( 受注明細.DFF6,受注明細.受注品目) = Disc品目.品目コード
     AND     oola.ship_from_org_id      = msib.organization_id                   -- 受注明細.出荷元組織 = Disc品目.組織ID
     AND     NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)       -- NVL( 受注明細.DFF6,受注明細.受注品目) = 品目換算View.品目コード
     AND     oola.order_quantity_uom    = xicv.to_uom_code(+)                    -- 受注明細.受注単位 = 品目換算View.変換先単位
     AND     oola.order_quantity_uom    = item_cnv.uom_code(+)                   -- 受注明細.受注単位 = 重量換算マスタ.単位コード
--     AND     oola.ship_from_org_id      =  mtsi.organization_id                  -- 受注明細.出荷元組織 = 保管場所マスタ.在庫組織ID
     AND     NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no            -- NVL( 受注明細.DFF6,受注明細.受注品目) = OPM品目.品目コード
     AND     iimb.item_id               =  ximb.item_id                          -- OPM品目.品目ID = OPM品目アドオン.品目ID
     AND     TRUNC( ximb.start_date_active )                   <= gd_process_date-- OPM品目アドオン.適用開始日 ≧ A-1で取得した業務日付
     AND     TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date-- NVL(OPM品目アドオン.適用終了日,A-1で取得したMAX日付)≦ A-1で取得した業務日付
     AND     hca.cust_account_id        =  xca.customer_id                       -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
     AND     hca2.customer_class_code   =  cv_party_type_1                       -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
     AND     hca2.account_number        =  xca.delivery_base_code                -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
     AND     oola.packing_instructions                 = it_packing_instructions -- 受注明細.梱包指示 = 対象となる出荷依頼No
     AND     NVL( oola.attribute6, oola.ordered_item ) = it_item_code            -- NVL(DFF6,受注品目コード) = 対象品目コード
--     GROUP BY
--             oola.subinventory
--            ,mtsi.description
--            ,NVL( oola.attribute6, oola.ordered_item )
--            ,ximb.item_short_name
--            ,TRUNC(oola.request_date)
--            ,oola.attribute4
--            ,xca.delivery_base_code
--            ,hca2.account_name
--            ,hca.account_number
--            ,hca.account_name
     ;
--
     -- 検収日逆転データ取得
     CURSOR get_rev_dlv_inconsistent_cur (
                                   it_packing_instructions oe_order_lines_all.packing_instructions%TYPE  -- 出荷依頼No
                                  ,it_item_code            oe_order_lines_all.ordered_item%TYPE          -- 品目コード
                                  ,it_dlv_date             oe_order_lines_all.request_date%TYPE          -- 納品日
                                  )
     IS
     SELECT 
            /*+
            USE_NL( oola ooha mtsi iimb ximb hca xca hca2 xicv item_cnv msib ottt otta )
            */
             ooha.order_number                         order_number              -- 受注番号
            ,oola.line_number                          line_number               -- 受注明細番号
            ,oola.subinventory                         subinventory_code         -- 受注：保管場所コード
            ,mtsi.description                          subinventory_name         -- 受注：保管場所名称
            ,NVL( oola.attribute6, oola.ordered_item ) item_code                 -- 受注：品目コード
            ,ximb.item_short_name                      item_name                 -- 受注：品目名
            ,TRUNC(oola.request_date)                  schedule_dlv_date         -- 受注：納品予定日
            ,oola.attribute4                           schedule_inspect_date     -- 受注：検収予定日
            ,xca.delivery_base_code                    base_code                 -- 受注：拠点ｺｰﾄﾞ
            ,hca2.account_name                         base_name                 -- 受注：拠点名称
            ,hca.account_number                        customer_number           -- 受注：顧客番号
            ,hca.account_name                          customer_name             -- 受注：顧客名
            ,oola.line_id                              line_id                   -- 受注：明細ID
            ,( oola.ordered_quantity * DECODE ( otta.order_category_code, cv_order, 1, -1 )
                    * CASE oola.order_quantity_uom
                      WHEN msib.primary_unit_of_measure THEN 1
                      WHEN item_cnv.uom_code THEN TO_NUMBER( item_cnv.cnv_value )
                      ELSE NVL( xicv.conversion_rate, 0 )
                    END
              ) AS order_quantity
     FROM    oe_order_lines_all         oola  -- 受注明細
            ,oe_order_headers_all       ooha  -- 受注ヘッダ
            ,mtl_secondary_inventories  mtsi  -- 保管場所マスタ
            ,ic_item_mst_b              iimb  -- OPM品目マスタ
            ,xxcmn_item_mst_b           ximb  -- OPM品目アドオン
            ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
            ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
            ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
            ,xxcos_item_conversions_v  xicv   -- 品目換算View
            ,(
              SELECT
                 flv.meaning      AS UOM_CODE
               , flv.description  AS CNV_VALUE
              FROM
                 fnd_lookup_values flv
              WHERE
                 flv.enabled_flag          = cv_yes_flg
              AND flv.language                = cv_user_lang
              AND flv.start_date_active    <= gd_process_date
              AND gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
              AND flv.lookup_type           = cv_weight_uom_cnv_mst
              ) item_cnv
             ,inv.mtl_system_items_b         msib        -- Disc品目（営業組織）
             ,ont.oe_transaction_types_tl    ottt        -- 受注取引タイプ（摘要）
             ,ont.oe_transaction_types_all   otta        -- 受注取引タイプマスタ
     WHERE   oola.header_id           =  ooha.header_id
     AND     ooha.org_id              =  gn_org_id                               -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
     AND     oola.line_type_id        =  ottt.transaction_type_id                -- 受注明細.明細ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID
     AND     ottt.transaction_type_id =  otta.transaction_type_id                -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 受注取引ﾀｲﾌﾟ.ﾀｲﾌﾟID
     AND     ottt.language            =  cv_user_lang                            -- 受注取引ﾀｲﾌﾟ(摘要).ﾀｲﾌﾟID = 'JA'
     AND     oola.subinventory        =  mtsi.secondary_inventory_name           -- 受注明細.保管場所 = 保管場所マスタ.保管場所
     AND     oola.ship_from_org_id    =  mtsi.organization_id                    -- 受注明細.出荷元組織ID = 保管場所マスタ.在庫組織ID
     AND     mtsi.attribute13         =  gv_subinventory_class                   -- 保管場所区分 = '11':直送
     AND     ooha.flow_status_code      IN ( cv_status_booked, cv_status_closed )-- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ( 'BOOKED','CLOSED' )
     AND     oola.flow_status_code      <> cv_status_cancelled                   -- 受注明細.ｽﾃｰﾀｽ <> 'CANCELLED'
     AND     oola.org_id                =  gn_org_id                             -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
     AND     ooha.sold_to_org_id        =  hca.cust_account_id                   -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
     AND     NVL( oola.attribute6, oola.ordered_item ) = msib.segment1           -- NVL( 受注明細.DFF6,受注明細.受注品目) = Disc品目.品目コード
     AND     oola.ship_from_org_id      = msib.organization_id                   -- 受注明細.出荷元組織 = Disc品目.組織ID
     AND     NVL( oola.attribute6, oola.ordered_item ) = xicv.item_code(+)       -- NVL( 受注明細.DFF6,受注明細.受注品目) = 品目換算View.品目コード
     AND     oola.order_quantity_uom    = xicv.to_uom_code(+)                    -- 受注明細.受注単位 = 品目換算View.変換先単位
     AND     oola.order_quantity_uom    = item_cnv.uom_code(+)                   -- 受注明細.受注単位 = 重量換算マスタ.単位コード
     AND     NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no            -- NVL( 受注明細.DFF6,受注明細.受注品目) = OPM品目.品目コード
     AND     iimb.item_id               =  ximb.item_id                          -- OPM品目.品目ID = OPM品目アドオン.品目ID
     AND     TRUNC( ximb.start_date_active )                   <= gd_process_date-- OPM品目アドオン.適用開始日 ≧ A-1で取得した業務日付
     AND     TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date-- NVL(OPM品目アドオン.適用終了日,A-1で取得したMAX日付)≦ A-1で取得した業務日付
     AND     hca.cust_account_id        =  xca.customer_id                       -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
     AND     hca2.customer_class_code   =  cv_party_type_1                       -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
     AND     hca2.account_number        =  xca.delivery_base_code                -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
     AND     oola.packing_instructions                 = it_packing_instructions -- 受注明細.梱包指示 = 対象となる出荷依頼No
     AND     NVL( oola.attribute6, oola.ordered_item ) = it_item_code            -- NVL(DFF6,受注品目コード) = 対象品目コード
     AND     TO_DATE( oola.attribute4 , cv_yyyymmddhhmiss ) < it_dlv_date;
--
    -- *** ローカル・レコード ***
--    l_data_rec       data_cur%ROWTYPE;
    l_insp_inconsistent_rec  get_insp_inconsistent_cur%ROWTYPE;
    l_rev_dlv_inconsistent_rec get_rev_dlv_inconsistent_cur%ROWTYPE;
-- ************* 2010/03/25 1.14 N.Maeda MOD  END  ************* --
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
    --ループカウント初期化
    ln_idx := 0;
--
-- ************* 2010/03/25 1.14 N.Maeda MOD START ************* --
    --==================================
    -- 1.データ取得
    --==================================
    --** ■例外１取得SQL(旧例外1,2)
    OPEN  quantity_excep_cur;
    FETCH quantity_excep_cur BULK COLLECT INTO gt_work_tab_err_quantity;
    CLOSE quantity_excep_cur;
    --** ■例外２取得SQL(旧例外3,4,5)
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--    OPEN  line_item_excep_cur;
--    FETCH line_item_excep_cur BULK COLLECT INTO gt_work_tab_err_item;
--    CLOSE line_item_excep_cur;
    -- 入力パラメータ『拠点コード』が"ALL"の場合
    IF ( iv_base_code = cv_base_all ) THEN
      OPEN  line_item_excep_cur;
      FETCH line_item_excep_cur BULK COLLECT INTO gt_work_tab_err_item;
      CLOSE line_item_excep_cur;
    -- 入力パラメータ『拠点コード』に拠点コードを指定した場合
    ELSE
      OPEN  line_item_excep_cur_base;
      FETCH line_item_excep_cur_base BULK COLLECT INTO gt_work_tab_err_item;
      CLOSE line_item_excep_cur_base;
    END IF;
-- 2010/04/09 Ver.1.14 Mod M.Sano End
    --** ■例外３取得SQL
    -- 納品予定日(着荷日)、検収予定日エラーデータ
    OPEN  get_check_data_cur;
    FETCH get_check_data_cur BULK COLLECT INTO gt_work_tab_err_req_insp_date;
    CLOSE get_check_data_cur;
--
    -- ============================
    -- ■例外１取得SQL(旧例外1,2)詳細情報取得
    -- ============================
    IF ( gt_work_tab_err_quantity.COUNT != 0 ) THEN
      <<err_quantity_loop>>
      FOR i IN 1..gt_work_tab_err_quantity.COUNT LOOP
      --
        -- 受注数量0以外(受注が取消されている為)
        IF  ( gt_work_tab_err_quantity(i).ooa1_order_quantity != 0 )
        OR  ( gt_work_tab_err_quantity(i).data_type = cv_date_type_2)
        THEN
          -- 初期化
          lt_order_number          := NULL;
          lt_line_number           := NULL;
          lt_subinventory_code     := NULL;
          lt_subinventory_name     := NULL;
          lt_item_code             := NULL;
          lt_item_name             := NULL;
          lt_schedule_dlv_date     := NULL;
          lt_schedule_inspect_date := NULL;
          lt_delivery_base_code    := NULL;
          lt_base_name             := NULL;
          lt_customer_number       := NULL;
          lt_customer_name         := NULL;
          lt_line_id               := NULL;
          ln_order_quantity        := NULL;
          --
          -- =============
          -- 受注詳細情報取得
          -- =============
          SELECT  ooha.order_number                         order_number              -- 受注：受注番号
                 ,oola.line_number                          line_number               -- 受注：明細番号
                 ,oola.subinventory                         subinventory_code         -- 受注：保管場所コード
                 ,mtsi.description                          subinventory_name         -- 受注：保管場所名称
                 ,NVL( oola.attribute6, oola.ordered_item ) item_code                 -- 受注：品目コード
                 ,ximb.item_short_name                      item_name                 -- 受注：品目名
                 ,oola.request_date                         schedule_dlv_date         -- 受注：納品予定日
                 ,oola.attribute4                           schedule_inspect_date     -- 受注：検収予定日
                 ,xca.delivery_base_code                    base_code                 -- 受注：拠点ｺｰﾄﾞ
                 ,hca2.account_name                         base_name                 -- 受注：拠点名称
                 ,hca.account_number                        customer_number           -- 受注：顧客番号
                 ,hca.account_name                          customer_name             -- 受注：顧客名
          INTO    lt_order_number
                 ,lt_line_number
                 ,lt_subinventory_code
                 ,lt_subinventory_name
                 ,lt_item_code
                 ,lt_item_name
                 ,lt_schedule_dlv_date
                 ,lt_schedule_inspect_date
                 ,lt_delivery_base_code
                 ,lt_base_name
                 ,lt_customer_number
                 ,lt_customer_name
          FROM    oe_order_lines_all         oola  -- 受注ヘッダ
                 ,oe_order_headers_all       ooha  -- 受注明細
                 ,mtl_secondary_inventories  mtsi  -- 保管場所マスタ
                 ,ic_item_mst_b              iimb  -- OPM品目マスタ
                 ,xxcmn_item_mst_b           ximb  -- OPM品目アドオン
                 ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
                 ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
          WHERE   oola.header_id         =  ooha.header_id
          AND     oola.line_id           =  gt_work_tab_err_quantity(i).ooa1_line_id
          AND     oola.subinventory      =  mtsi.secondary_inventory_name
          AND     oola.ship_from_org_id  =  mtsi.organization_id
          AND     mtsi.attribute13       =  gv_subinventory_class
          AND     NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no
          AND     iimb.item_id           =  ximb.item_id
          AND     TRUNC( ximb.start_date_active )                   <= gd_process_date
          AND     TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date
          AND     ooha.sold_to_org_id        =  hca.cust_account_id           -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
          AND     hca.cust_account_id        =  xca.customer_id               -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
          AND     hca2.customer_class_code   =  cv_party_type_1               -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
          AND     hca2.account_number        =  xca.delivery_base_code        -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
          ;
--
          -- =======================
          -- キーインデックス作成
          -- =======================
          lv_key_index := NULL;
          lv_key_index := TO_CHAR(lt_delivery_base_code)||cv_key_connect||                                    -- 拠点ｺｰﾄﾞ||','||
                          TO_CHAR(lt_order_number)||cv_key_connect||                                          -- 受注番号||','||
                          TO_CHAR(lt_line_number)||cv_key_connect||                                           -- 受注明細No||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa1_deliver_requested_no)||cv_key_connect||    -- 出荷依頼No||','||
                          TO_CHAR(lt_subinventory_code)||cv_key_connect||                                     -- 保管場所コード||','||
                          TO_CHAR(lt_customer_number)||cv_key_connect||                                       -- 顧客コード||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa1_item_code)||cv_key_connect||               -- 品目コード||','||
                          TO_CHAR(lt_schedule_dlv_date,cv_fmt_date)||cv_key_connect||                         -- 納品予定日||','||
                          TO_CHAR(lt_schedule_inspect_date)||cv_key_connect||                                 -- 検収予定日||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa2_arrival_date,cv_fmt_date)||cv_key_connect||-- 着日||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa1_order_quantity)||cv_key_connect||          -- 受注数||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa2_deliver_actual_quantity)||cv_key_connect|| -- 出荷実績数||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa2_uom_code)||cv_key_connect||                -- 単位||','||
                          TO_CHAR(gt_work_tab_err_quantity(i).ooa2_line_no)                                   -- 明細No
                          ;
--
          IF ( gt_rpt_data_sum_tab.EXISTS( lv_key_index ) ) THEN
            NULL;
          ELSE
--
            -- =============
            -- 取得値セット
            -- =============
            gt_rpt_data_sum_tab( lv_key_index ).base_code         := lt_delivery_base_code;                                   -- ：拠点ｺｰﾄﾞ
            gt_rpt_data_sum_tab( lv_key_index ).base_name         := SUBSTRB(lt_base_name,1,40);                              -- ：拠点名称
            gt_rpt_data_sum_tab( lv_key_index ).order_number      := lt_order_number;                                         -- ：受注番号
            gt_rpt_data_sum_tab( lv_key_index ).order_line_no     := lt_line_number;                                          -- ：受注明細No
            gt_rpt_data_sum_tab( lv_key_index ).line_no           := gt_work_tab_err_quantity(i).ooa2_line_no;                -- ：明細No
            gt_rpt_data_sum_tab( lv_key_index ).deliver_requested_no                                                          -- ：出荷依頼No
                                                                  := SUBSTRB(gt_work_tab_err_quantity(i).ooa1_deliver_requested_no, 1, 12);
            gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_number                                                      -- ：出荷元倉庫番号
                                                                  := lt_subinventory_code;
            gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_name                                                        -- ：出荷元倉庫名
                                                                  := SUBSTRB(lt_subinventory_name,1,20);
            gt_rpt_data_sum_tab( lv_key_index ).customer_number   := lt_customer_number;                                      -- ：顧客番号
            gt_rpt_data_sum_tab( lv_key_index ).customer_name     := SUBSTRB(lt_customer_name,1,20);                          -- ：顧客名
            gt_rpt_data_sum_tab( lv_key_index ).item_code         := gt_work_tab_err_quantity(i).ooa1_item_code;              -- ：品目ｺｰﾄﾞ
            gt_rpt_data_sum_tab( lv_key_index ).item_name         := SUBSTRB(lt_item_name,1,20);                              -- ：品名
            gt_rpt_data_sum_tab( lv_key_index ).schedule_dlv_date := lt_schedule_dlv_date;                                    -- ：納品予定
            gt_rpt_data_sum_tab( lv_key_index ).schedule_inspect_date
                                                                  := TO_DATE(lt_schedule_inspect_date,cv_yyyymmddhhmiss);                                -- ：検収予定日
            gt_rpt_data_sum_tab( lv_key_index ).arrival_date      := gt_work_tab_err_quantity(i).ooa2_arrival_date;           -- ：着日
            gt_rpt_data_sum_tab( lv_key_index ).order_quantity    := gt_work_tab_err_quantity(i).ooa1_order_quantity;         -- ：受注数
            gt_rpt_data_sum_tab( lv_key_index ).deliver_actual_quantity
                                                                  := gt_work_tab_err_quantity(i).ooa2_deliver_actual_quantity;-- ：出荷実績数
            gt_rpt_data_sum_tab( lv_key_index ).uom_code          := gt_work_tab_err_quantity(i).ooa2_uom_code;               -- ：単位
            gt_rpt_data_sum_tab( lv_key_index ).output_quantity   := ( gt_work_tab_err_quantity(i).ooa1_order_quantity        -- ：差異数
                                                                     - gt_work_tab_err_quantity(i).ooa2_deliver_actual_quantity );
            gt_rpt_data_sum_tab( lv_key_index ).data_class        := cv_data_class_1;                                         -- ：データ区分
          END IF;
          --
        END IF;
--
      --
      END LOOP err_quantity_loop;
    END IF;
--
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--    -- ======================
--    -- ■例外３詳細情報取得
--    -- ======================
    -- 例外１(例外１-２,１-５)・例外２のチェック対象受注リストの領域開放
    gt_work_tab_err_quantity.DELETE;
--
    -- ==================================================================
    --** ■『例外１(例外１-１,例外１-３)・例外３』
    --**   ・数量・出荷実績数量違いデータ
    --**   ・納品予定日・着荷日違いデータ
    --**   ・納品予定日(着荷日)、検収予定日エラーデータ
    -- ==================================================================
--
    -- ============================================
    -- 例外１・例外３詳細情報取得
    -- ============================================
-- 2010/04/09 Ver.1.14 Mod M.Sano End
    IF ( gt_work_tab_err_req_insp_date.COUNT != 0 ) THEN
      <<get_check_loop>>
      FOR i IN 1..gt_work_tab_err_req_insp_date.COUNT LOOP
--
        -- 初期化
        lt_order_number          := NULL;
        lt_line_number           := NULL;
        lt_subinventory_code     := NULL;
        lt_subinventory_name     := NULL;
        lt_item_code             := NULL;
        lt_item_name             := NULL;
        lt_schedule_dlv_date     := NULL;
        lt_schedule_inspect_date := NULL;
        lt_delivery_base_code    := NULL;
        lt_base_name             := NULL;
        lt_customer_number       := NULL;
        lt_customer_name         := NULL;
        lv_exi_data              := NULL;
        lt_line_id               := NULL;
        ln_order_quantity        := NULL;
        --
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
        -- ============================================
        -- 対象データが以下の条件を満たすかチェック
        -- ・例外１-１：数量・出荷実績数量違い
        -- ・例外１-３：納品予定日・着荷日違い
        -- ============================================
        IF ( (  gt_work_tab_err_req_insp_date(i).ooa1_order_quantity <> gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity
            AND gt_work_tab_err_req_insp_date(i).ooa1_order_quantity != 0 )
          OR (  gt_work_tab_err_req_insp_date(i).ooa1_schedule_dlv_date <> gt_work_tab_err_req_insp_date(i).ooa2_arrival_date 
            AND gt_work_tab_err_req_insp_date(i).ooa1_order_quantity    != 0 )
        )THEN
          --
          -- 受注詳細情報取得
          SELECT  ooha.order_number                         order_number              -- 受注：受注番号
                 ,oola.line_number                          line_number               -- 受注：明細番号
                 ,oola.subinventory                         subinventory_code         -- 受注：保管場所コード
                 ,mtsi.description                          subinventory_name         -- 受注：保管場所名称
                 ,NVL( oola.attribute6, oola.ordered_item ) item_code                 -- 受注：品目コード
                 ,ximb.item_short_name                      item_name                 -- 受注：品目名
                 ,oola.request_date                         schedule_dlv_date         -- 受注：納品予定日
                 ,oola.attribute4                           schedule_inspect_date     -- 受注：検収予定日
                 ,xca.delivery_base_code                    base_code                 -- 受注：拠点ｺｰﾄﾞ
                 ,hca2.account_name                         base_name                 -- 受注：拠点名称
                 ,hca.account_number                        customer_number           -- 受注：顧客番号
                 ,hca.account_name                          customer_name             -- 受注：顧客名
          INTO    lt_order_number
                 ,lt_line_number
                 ,lt_subinventory_code
                 ,lt_subinventory_name
                 ,lt_item_code
                 ,lt_item_name
                 ,lt_schedule_dlv_date
                 ,lt_schedule_inspect_date
                 ,lt_delivery_base_code
                 ,lt_base_name
                 ,lt_customer_number
                 ,lt_customer_name
          FROM    oe_order_lines_all         oola  -- 受注ヘッダ
                 ,oe_order_headers_all       ooha  -- 受注明細
                 ,mtl_secondary_inventories  mtsi  -- 保管場所マスタ
                 ,ic_item_mst_b              iimb  -- OPM品目マスタ
                 ,xxcmn_item_mst_b           ximb  -- OPM品目アドオン
                 ,hz_cust_accounts           hca   -- 顧客ﾏｽﾀ
                 ,xxcmm_cust_accounts        xca   -- 顧客追加情報ﾏｽﾀ
                 ,hz_cust_accounts           hca2  -- 顧客ﾏｽﾀ2
          WHERE   oola.header_id         =  ooha.header_id
          AND     oola.line_id           =  gt_work_tab_err_req_insp_date(i).ooa1_line_id
          AND     oola.subinventory      =  mtsi.secondary_inventory_name
          AND     oola.ship_from_org_id  =  mtsi.organization_id
          AND     mtsi.attribute13       =  gv_subinventory_class
          AND     NVL( oola.attribute6, oola.ordered_item ) = iimb.item_no
          AND     iimb.item_id           =  ximb.item_id
          AND     TRUNC( ximb.start_date_active )                   <= gd_process_date
          AND     TRUNC( NVL( ximb.end_date_active, gd_max_date ) ) >= gd_process_date
          AND     ooha.sold_to_org_id        =  hca.cust_account_id           -- 受注ﾍｯﾀﾞ.顧客ID = 顧客ﾏｽﾀ.顧客ID
          AND     hca.cust_account_id        =  xca.customer_id               -- 顧客ﾏｽﾀ.顧客ID  = 顧客追加情報ﾏｽﾀ.顧客ID
          AND     hca2.customer_class_code   =  cv_party_type_1               -- 顧客ﾏｽﾀ2.顧客区分 = '1':拠点
          AND     hca2.account_number        =  xca.delivery_base_code        -- 顧客ﾏｽﾀ2.顧客ｺｰﾄﾞ = 顧客追加情報ﾏｽﾀ.納品拠点ｺｰﾄﾞ
          ;
--
          -- キーインデックス作成
          lv_key_index := NULL;
          lv_key_index := TO_CHAR(lt_delivery_base_code)||cv_key_connect||                                         -- 拠点ｺｰﾄﾞ||','||
                          TO_CHAR(lt_order_number)||cv_key_connect||                                               -- 受注番号||','||
                          TO_CHAR(lt_line_number)||cv_key_connect||                                                -- 受注明細No||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no)||cv_key_connect||    -- 出荷依頼No||','||
                          TO_CHAR(lt_subinventory_code)||cv_key_connect||                                          -- 保管場所コード||','||
                          TO_CHAR(lt_customer_number)||cv_key_connect||                                            -- 顧客コード||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_item_code)||cv_key_connect||               -- 品目コード||','||
                          TO_CHAR(lt_schedule_dlv_date,cv_fmt_date)||cv_key_connect||                              -- 納品予定日||','||
                          TO_CHAR(lt_schedule_inspect_date)||cv_key_connect||                                      -- 検収予定日||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_arrival_date,cv_fmt_date)||cv_key_connect||-- 着日||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_order_quantity)||cv_key_connect||          -- 受注数||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity)||cv_key_connect|| -- 出荷実績数||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_uom_code)||cv_key_connect||                -- 単位||','||
                          TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_line_no)                                   -- 明細No
                          ;
--
          -- キーインデックスに該当データが存在しない場合、出力対象リストに格納
          IF ( gt_rpt_data_sum_tab.EXISTS( lv_key_index ) ) THEN
            NULL;
          ELSE
--
            gt_rpt_data_sum_tab( lv_key_index ).base_code         := lt_delivery_base_code;                                   -- ：拠点ｺｰﾄﾞ
            gt_rpt_data_sum_tab( lv_key_index ).base_name         := SUBSTRB(lt_base_name,1,40);                              -- ：拠点名称
            gt_rpt_data_sum_tab( lv_key_index ).order_number      := lt_order_number;                                         -- ：受注番号
            gt_rpt_data_sum_tab( lv_key_index ).order_line_no     := lt_line_number;                                          -- ：受注明細No
            gt_rpt_data_sum_tab( lv_key_index ).line_no           := gt_work_tab_err_req_insp_date(i).ooa2_line_no;           -- ：明細No
            gt_rpt_data_sum_tab( lv_key_index ).deliver_requested_no                                                          -- ：出荷依頼No
                                                                  := SUBSTRB(gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no, 1, 12);
            gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_number                                                      -- ：出荷元倉庫番号
                                                                  := lt_subinventory_code;
            gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_name                                                        -- ：出荷元倉庫名
                                                                  := SUBSTRB(lt_subinventory_name,1,20);
            gt_rpt_data_sum_tab( lv_key_index ).customer_number   := lt_customer_number;                                      -- ：顧客番号
            gt_rpt_data_sum_tab( lv_key_index ).customer_name     := SUBSTRB(lt_customer_name,1,20);                          -- ：顧客名
            gt_rpt_data_sum_tab( lv_key_index ).item_code         := gt_work_tab_err_req_insp_date(i).ooa1_item_code;         -- ：品目ｺｰﾄﾞ
            gt_rpt_data_sum_tab( lv_key_index ).item_name         := SUBSTRB(lt_item_name,1,20);                              -- ：品名
            gt_rpt_data_sum_tab( lv_key_index ).schedule_dlv_date := lt_schedule_dlv_date;                                    -- ：納品予定
            gt_rpt_data_sum_tab( lv_key_index ).schedule_inspect_date
                                                                  := TO_DATE(lt_schedule_inspect_date,cv_yyyymmddhhmiss);     -- ：検収予定日
            gt_rpt_data_sum_tab( lv_key_index ).arrival_date      := gt_work_tab_err_req_insp_date(i).ooa2_arrival_date;      -- ：着日
            gt_rpt_data_sum_tab( lv_key_index ).order_quantity    := gt_work_tab_err_req_insp_date(i).ooa1_order_quantity;    -- ：受注数
            gt_rpt_data_sum_tab( lv_key_index ).deliver_actual_quantity
                                                                  := gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity;
                                                                                                                              -- ：出荷実績数
            gt_rpt_data_sum_tab( lv_key_index ).uom_code          := gt_work_tab_err_req_insp_date(i).ooa2_uom_code;          -- ：単位
            gt_rpt_data_sum_tab( lv_key_index ).output_quantity   := ( gt_work_tab_err_req_insp_date(i).ooa1_order_quantity   -- ：差異数
                                                                     - gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity );
            gt_rpt_data_sum_tab( lv_key_index ).data_class        := cv_data_class_1;                                         -- ：データ区分
          END IF;
        END IF;
--
-- 2010/04/09 Ver.1.14 Mod M.Sano End
        -- 検収日逆転チェック
        IF  ( gt_work_tab_err_req_insp_date(i).ooa1_min_schedule_inspect_date IS NOT NULL                    -- 検収日最小値 IS NOT NULL
            AND gt_work_tab_err_req_insp_date(i).ooa1_max_schedule_inspect_date IS NOT NULL )                -- 検収日最大値 IS NOT NULL
        AND ( ( TO_DATE(gt_work_tab_err_req_insp_date(i).ooa1_min_schedule_inspect_date,cv_yyyymmddhhmiss)   -- 検収日最小値または検収日最大値が
                 < gt_work_tab_err_req_insp_date(i).ooa1_schedule_dlv_date )                                 --   納品日よりも後
            OR  ( TO_DATE(gt_work_tab_err_req_insp_date(i).ooa1_max_schedule_inspect_date,cv_yyyymmddhhmiss)
                 < gt_work_tab_err_req_insp_date(i).ooa1_schedule_dlv_date ) ) THEN
        --
          <<rev_dade_loop>>
          FOR l_rev_dlv_inconsistent_rec IN get_rev_dlv_inconsistent_cur (
                                                                    gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no -- 出荷依頼No
                                                                   ,gt_work_tab_err_req_insp_date(i).ooa1_item_code            -- 品目コード
                                                                   ,gt_work_tab_err_req_insp_date(i).ooa1_schedule_dlv_date    -- 納品予定日
                                                                   ) LOOP
          --
            lt_order_number          := l_rev_dlv_inconsistent_rec.order_number;              -- 受注：受注番号
            lt_line_number           := l_rev_dlv_inconsistent_rec.line_number;               -- 受注：受注明細番号
            lt_subinventory_code     := l_rev_dlv_inconsistent_rec.subinventory_code;         -- 受注：保管場所コード
            lt_subinventory_name     := l_rev_dlv_inconsistent_rec.subinventory_name;         -- 受注：保管場所名称
            lt_item_code             := l_rev_dlv_inconsistent_rec.item_code;                 -- 受注：品目コード
            lt_item_name             := l_rev_dlv_inconsistent_rec.item_name;                 -- 受注：品目名
            lt_schedule_dlv_date     := l_rev_dlv_inconsistent_rec.schedule_dlv_date;         -- 受注：納品予定日
            lt_schedule_inspect_date := l_rev_dlv_inconsistent_rec.schedule_inspect_date;     -- 受注：検収予定日
            lt_delivery_base_code    := l_rev_dlv_inconsistent_rec.base_code;                 -- 受注：拠点ｺｰﾄﾞ
            lt_base_name             := l_rev_dlv_inconsistent_rec.base_name;                 -- 受注：拠点名称
            lt_customer_number       := l_rev_dlv_inconsistent_rec.customer_number;           -- 受注：顧客番号
            lt_customer_name         := l_rev_dlv_inconsistent_rec.customer_name;             -- 受注：顧客名
            lt_line_id               := l_rev_dlv_inconsistent_rec.line_id;                   -- 受注：明細ID
            ln_order_quantity        := l_rev_dlv_inconsistent_rec.order_quantity;            -- 受注：受注数量
          ---- =======================
            -- キーインデックス作成
            -- =======================
            lv_key_index := NULL;
            lv_key_index := TO_CHAR(lt_delivery_base_code)||cv_key_connect||                                        -- 拠点ｺｰﾄﾞ||','||
                            TO_CHAR(lt_order_number)||cv_key_connect||                                              -- 受注番号||','||
                            TO_CHAR(lt_line_number)||cv_key_connect||                                               -- 受注明細No||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no)||cv_key_connect||   -- 出荷依頼No||','||
                            TO_CHAR(lt_subinventory_code)||cv_key_connect||                                         -- 保管場所コード||','||
                            TO_CHAR(lt_customer_number)||cv_key_connect||                                           -- 顧客コード||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_item_code)||cv_key_connect||              -- 品目コード||','||
                            TO_CHAR(lt_schedule_dlv_date,cv_fmt_date)||cv_key_connect||                             -- 納品予定日||','||
                            TO_CHAR(lt_schedule_inspect_date||cv_key_connect)||                                     -- 検収予定日||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_arrival_date,cv_fmt_date)||cv_key_connect||   -- 着日||','||
                            TO_CHAR(ln_order_quantity)||cv_key_connect||                                            -- 受注数||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity)||cv_key_connect||-- 出荷実績数||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_uom_code)||cv_key_connect||               -- 単位
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_line_no)                                  -- 明細No
                            ;
            --
            IF ( gt_rpt_data_sum_tab.EXISTS( lv_key_index ) ) THEN
              NULL;
            ELSE
--
              -- =============
              -- 取得値セット
              -- =============
              gt_rpt_data_sum_tab( lv_key_index ).base_code         := lt_delivery_base_code;                                   -- ：拠点ｺｰﾄﾞ
              gt_rpt_data_sum_tab( lv_key_index ).base_name         := SUBSTRB(lt_base_name,1,40);                              -- ：拠点名称
              gt_rpt_data_sum_tab( lv_key_index ).order_number      := lt_order_number;                                         -- ：受注番号
              gt_rpt_data_sum_tab( lv_key_index ).order_line_no     := lt_line_number;                                          -- ：受注明細No
              gt_rpt_data_sum_tab( lv_key_index ).line_no           := gt_work_tab_err_req_insp_date(i).ooa2_line_no;           -- ：明細No
              gt_rpt_data_sum_tab( lv_key_index ).deliver_requested_no                                                          -- ：出荷依頼No
                                                                    := SUBSTRB(gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no, 1, 12);
              gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_number                                                      -- ：出荷元倉庫番号
                                                                    := lt_subinventory_code;
              gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_name                                                        -- ：出荷元倉庫名
                                                                    := SUBSTRB(lt_subinventory_name,1,20);
              gt_rpt_data_sum_tab( lv_key_index ).customer_number   := lt_customer_number;                                      -- ：顧客番号
              gt_rpt_data_sum_tab( lv_key_index ).customer_name     := SUBSTRB(lt_customer_name,1,20);                          -- ：顧客名
              gt_rpt_data_sum_tab( lv_key_index ).item_code         := gt_work_tab_err_req_insp_date(i).ooa1_item_code;         -- ：品目ｺｰﾄﾞ
              gt_rpt_data_sum_tab( lv_key_index ).item_name         := SUBSTRB(lt_item_name,1,20);                              -- ：品名
              gt_rpt_data_sum_tab( lv_key_index ).schedule_dlv_date := lt_schedule_dlv_date;                                    -- ：納品予定日
              gt_rpt_data_sum_tab( lv_key_index ).schedule_inspect_date
                                                                    := TO_DATE(lt_schedule_inspect_date,cv_yyyymmddhhmiss);                                -- ：検収予定日
              gt_rpt_data_sum_tab( lv_key_index ).arrival_date      := gt_work_tab_err_req_insp_date(i).ooa2_arrival_date;      -- ：着日
              gt_rpt_data_sum_tab( lv_key_index ).order_quantity    := ln_order_quantity;                                       -- ：受注数
              gt_rpt_data_sum_tab( lv_key_index ).deliver_actual_quantity                                                       -- ：出荷実績数
                                                                    := gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity;
              gt_rpt_data_sum_tab( lv_key_index ).uom_code          := gt_work_tab_err_req_insp_date(i).ooa2_uom_code;          -- ：単位
              gt_rpt_data_sum_tab( lv_key_index ).output_quantity   := ( gt_work_tab_err_req_insp_date(i).ooa1_order_quantity   -- ：差異数(受注数量-実績数量)
                                                                       - gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity );
              gt_rpt_data_sum_tab( lv_key_index ).data_class        := cv_data_class_6;                                       -- ：データ区分
            END IF;
          --
          END LOOP rev_dade_loop;
        --
        END IF;
        -- 初期化
        lt_order_number          := NULL;
        lt_line_number           := NULL;
        lt_subinventory_code     := NULL;
        lt_subinventory_name     := NULL;
        lt_item_code             := NULL;
        lt_item_name             := NULL;
        lt_schedule_dlv_date     := NULL;
        lt_schedule_inspect_date := NULL;
        lt_delivery_base_code    := NULL;
        lt_base_name             := NULL;
        lt_customer_number       := NULL;
        lt_customer_name         := NULL;
        lv_exi_data              := NULL;
        lt_line_id               := NULL;
        ln_order_quantity        := NULL;
--
        -- 検収日NULLデータ存在確認用sql
        -- 検収日の最小値が取得されている場合、NULLデータ確認を行う。
        IF ( gt_work_tab_err_req_insp_date(i).ooa1_min_schedule_inspect_date IS NOT NULL ) THEN
          BEGIN
            SELECT cv_yes_flg
            INTO   lv_exi_data
            FROM   oe_order_lines_all exi_oola
            WHERE  exi_oola.packing_instructions = gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no
            AND    NVL( exi_oola.attribute6, exi_oola.ordered_item )  = gt_work_tab_err_req_insp_date(i).ooa1_item_code
            AND    TRUNC( exi_oola.request_date ) = gt_work_tab_err_req_insp_date(i).ooa1_schedule_dlv_date
            AND    exi_oola.attribute4 IS NULL
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
            AND    exi_oola.flow_status_code IN ( cv_status_booked, cv_status_closed )
-- 2010/04/09 Ver.1.14 Mod M.Sano End
            AND    ROWNUM = 1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
        END IF;
--
        -- ==============================
        -- 検収日違いチェック(受注情報中の確認)
        -- ==============================
        IF (   -- 検収日が最大値と最小値で異なる
             ( NVL( gt_work_tab_err_req_insp_date(i).ooa1_min_schedule_inspect_date,cv_yes_flg )
                               != NVL( gt_work_tab_err_req_insp_date(i).ooa1_max_schedule_inspect_date,cv_yes_flg ) 
             )
             OR (   -- 検収日の最小値が取得されているのに、検収日NULLデータが存在している(検収日設定漏れデータ)
                  gt_work_tab_err_req_insp_date(i).ooa1_min_schedule_inspect_date IS NOT NULL
                  AND
                  lv_exi_data IS NOT NULL
                )
           )
        THEN
        --
          -- ========================
          -- 受注情報取得
          -- ========================
          <<insp_inconsistent_loop>>
          FOR l_insp_inconsistent_rec IN get_insp_inconsistent_cur (
                                                                    gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no
                                                                   ,gt_work_tab_err_req_insp_date(i).ooa1_item_code
                                                                   ) LOOP
          --
            lt_order_number          := l_insp_inconsistent_rec.order_number;              -- 受注：受注番号
            lt_line_number           := l_insp_inconsistent_rec.line_number;               -- 受注：受注明細番号
            lt_subinventory_code     := l_insp_inconsistent_rec.subinventory_code;         -- 受注：保管場所コード
            lt_subinventory_name     := l_insp_inconsistent_rec.subinventory_name;         -- 受注：保管場所名称
            lt_item_code             := l_insp_inconsistent_rec.item_code;                 -- 受注：品目コード
            lt_item_name             := l_insp_inconsistent_rec.item_name;                 -- 受注：品目名
            lt_schedule_dlv_date     := l_insp_inconsistent_rec.schedule_dlv_date;         -- 受注：納品予定日
            lt_schedule_inspect_date := l_insp_inconsistent_rec.schedule_inspect_date;     -- 受注：検収予定日
            lt_delivery_base_code    := l_insp_inconsistent_rec.base_code;                 -- 受注：拠点ｺｰﾄﾞ
            lt_base_name             := l_insp_inconsistent_rec.base_name;                 -- 受注：拠点名称
            lt_customer_number       := l_insp_inconsistent_rec.customer_number;           -- 受注：顧客番号
            lt_customer_name         := l_insp_inconsistent_rec.customer_name;             -- 受注：顧客名
            lt_line_id               := l_insp_inconsistent_rec.line_id;                   -- 受注：明細ID
            ln_order_quantity        := l_insp_inconsistent_rec.order_quantity;            -- 受注：受注数量
            --
--            -- 検収日単位で受注数量と出荷実績数量が同じでない場合
--            IF ( ln_order_quantity != gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity )
--               AND
--               -- 検収日単位の受注数量0以外
--               ( ln_order_quantity != 0 )
--            THEN
            -- =======================
            -- 受注、明細番号取得
            -- =======================
--            BEGIN
--              SELECT
--                      ooha.order_number         -- 受注番号
--                     ,oola.line_number          -- 受注明細番号
--              INTO    lt_order_number
--                     ,lt_line_number
--              FROM    oe_order_lines_all   oola
--                     ,oe_order_headers_all ooha
--              WHERE   oola.header_id = ooha.header_id
--              AND     oola.line_id   = lt_line_id
--              ;
--            EXCEPTION
--              WHEN OTHERS THEN
--                NULL;
--            END;
            -- =======================
            -- キーインデックス作成
            -- =======================
            lv_key_index := NULL;
            lv_key_index := TO_CHAR(lt_delivery_base_code)||cv_key_connect||                                        -- 拠点ｺｰﾄﾞ||','||
                            TO_CHAR(lt_order_number)||cv_key_connect||                                              -- 受注番号||','||
                            TO_CHAR(lt_line_number)||cv_key_connect||                                               -- 受注明細No||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no)||cv_key_connect||   -- 出荷依頼No||','||
                            TO_CHAR(lt_subinventory_code)||cv_key_connect||                                         -- 保管場所コード||','||
                            TO_CHAR(lt_customer_number)||cv_key_connect||                                           -- 顧客コード||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa1_item_code)||cv_key_connect||              -- 品目コード||','||
                            TO_CHAR(lt_schedule_dlv_date,cv_fmt_date)||cv_key_connect||                             -- 納品予定日||','||
                            TO_CHAR(lt_schedule_inspect_date||cv_key_connect)||                                     -- 検収予定日||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_arrival_date,cv_fmt_date)||cv_key_connect||   -- 着日||','||
                            TO_CHAR(ln_order_quantity)||cv_key_connect||                                            -- 受注数||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity)||cv_key_connect||-- 出荷実績数||','||
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_uom_code)||cv_key_connect||               -- 単位
                            TO_CHAR(gt_work_tab_err_req_insp_date(i).ooa2_line_no)                                  -- 明細No
                            ;
            --
            IF ( gt_rpt_data_sum_tab.EXISTS( lv_key_index ) ) THEN
              NULL;
            ELSE
--
              -- =============
              -- 取得値セット
              -- =============
              gt_rpt_data_sum_tab( lv_key_index ).base_code         := lt_delivery_base_code;                                   -- ：拠点ｺｰﾄﾞ
              gt_rpt_data_sum_tab( lv_key_index ).base_name         := SUBSTRB(lt_base_name,1,40);                              -- ：拠点名称
              gt_rpt_data_sum_tab( lv_key_index ).order_number      := lt_order_number;                                         -- ：受注番号
              gt_rpt_data_sum_tab( lv_key_index ).order_line_no     := lt_line_number;                                          -- ：受注明細No
              gt_rpt_data_sum_tab( lv_key_index ).line_no           := gt_work_tab_err_req_insp_date(i).ooa2_line_no;           -- ：明細No
              gt_rpt_data_sum_tab( lv_key_index ).deliver_requested_no                                                          -- ：出荷依頼No
                                                                    := SUBSTRB(gt_work_tab_err_req_insp_date(i).ooa1_deliver_requested_no, 1, 12);
              gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_number                                                      -- ：出荷元倉庫番号
                                                                    := lt_subinventory_code;
              gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_name                                                        -- ：出荷元倉庫名
                                                                    := SUBSTRB(lt_subinventory_name,1,20);
              gt_rpt_data_sum_tab( lv_key_index ).customer_number   := lt_customer_number;                                      -- ：顧客番号
              gt_rpt_data_sum_tab( lv_key_index ).customer_name     := SUBSTRB(lt_customer_name,1,20);                          -- ：顧客名
              gt_rpt_data_sum_tab( lv_key_index ).item_code         := gt_work_tab_err_req_insp_date(i).ooa1_item_code;         -- ：品目ｺｰﾄﾞ
              gt_rpt_data_sum_tab( lv_key_index ).item_name         := SUBSTRB(lt_item_name,1,20);                              -- ：品名
              gt_rpt_data_sum_tab( lv_key_index ).schedule_dlv_date := lt_schedule_dlv_date;                                    -- ：納品予定日
              gt_rpt_data_sum_tab( lv_key_index ).schedule_inspect_date
                                                                    := TO_DATE(lt_schedule_inspect_date,cv_yyyymmddhhmiss);                                -- ：検収予定日
              gt_rpt_data_sum_tab( lv_key_index ).arrival_date      := gt_work_tab_err_req_insp_date(i).ooa2_arrival_date;      -- ：着日
              gt_rpt_data_sum_tab( lv_key_index ).order_quantity    := ln_order_quantity;                                       -- ：受注数
              gt_rpt_data_sum_tab( lv_key_index ).deliver_actual_quantity                                                       -- ：出荷実績数
                                                                    := gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity;
              gt_rpt_data_sum_tab( lv_key_index ).uom_code          := gt_work_tab_err_req_insp_date(i).ooa2_uom_code;          -- ：単位
              gt_rpt_data_sum_tab( lv_key_index ).output_quantity   := ( gt_work_tab_err_req_insp_date(i).ooa1_order_quantity   -- ：差異数(受注数量-実績数量)
                                                                       - gt_work_tab_err_req_insp_date(i).ooa2_deliver_actual_quantity );
              gt_rpt_data_sum_tab( lv_key_index ).data_class        := cv_data_class_6;                                       -- ：データ区分
            END IF;
            --
--            END IF;
--
          END LOOP insp_inconsistent_loop;
        --
        END IF;
--
      END LOOP get_check_loop;
    END IF;
--
-- 2010/04/09 Ver.1.14 Mod M.Sano Start
--    -- =================
--    -- 例外２情報サマリ
--    -- =================
    -- 例外１・例外３のチェック対象受注リストの領域開放
    gt_work_tab_err_req_insp_date.DELETE;
--
    -- ===================================================================
    --** ■例外２(旧例外3-1,3-2,4,5)：受注・出荷実績紐付けチェック
    --**   ・受注あり-出荷実績なし ※受注、出荷実績間の明細品目不一致エラー
    --**   ・受注なし-出荷実績あり ※受注、出荷実績間の明細品目不一致エラー
    --**   ・受注なし-出荷実績あり ※出荷依頼No存在なしエラー
    --**   ・受注あり-出荷実績なし ※出荷依頼No存在なしエラー
    -- ===================================================================
--
    -- ==================================
    -- 例外２詳細情報取得
    -- ==================================
-- 2010/04/09 Ver.1.14 Mod M.Sano End
    IF ( gt_work_tab_err_item.COUNT != 0 ) THEN
      <<line_item_excep_sum_loop>>
      FOR i IN 1..gt_work_tab_err_item.COUNT LOOP
      --
        -- =======================
        -- キーインデックス作成
        -- =======================
        lv_key_index := NULL;
        lv_key_index := TO_CHAR(gt_work_tab_err_item(i).base_code)||cv_key_connect||                          -- 拠点ｺｰﾄﾞ||','||
                        TO_CHAR(gt_work_tab_err_item(i).order_number)||cv_key_connect||                       -- 受注番号||','||
                        TO_CHAR(gt_work_tab_err_item(i).order_line_no)||cv_key_connect||                      -- 受注明細No||','||
                        TO_CHAR(gt_work_tab_err_item(i).deliver_requested_no)||cv_key_connect||               -- 出荷依頼No||','||
                        TO_CHAR(gt_work_tab_err_item(i).deliver_from_whse_number)||cv_key_connect||           -- 保管場所コード||','||
                        TO_CHAR(gt_work_tab_err_item(i).customer_number)||cv_key_connect||                    -- 顧客コード||','||
                        TO_CHAR(gt_work_tab_err_item(i).item_code)||cv_key_connect||                          -- 品目コード||','||
                        TO_CHAR(gt_work_tab_err_item(i).schedule_dlv_date,cv_fmt_date)||cv_key_connect||      -- 納品予定日||','||
                        TO_CHAR(gt_work_tab_err_item(i).schedule_inspect_date)||cv_key_connect||              -- 検収予定日||','||
                        TO_CHAR(gt_work_tab_err_item(i).arrival_date,cv_fmt_date)||cv_key_connect||           -- 着日||','||
                        TO_CHAR(gt_work_tab_err_item(i).order_quantity)||cv_key_connect||                     -- 受注数||','||
                        TO_CHAR(gt_work_tab_err_item(i).deliver_actual_quantity)||cv_key_connect||            -- 出荷実績数||','||
                        TO_CHAR(gt_work_tab_err_item(i).uom_code)||cv_key_connect||                           -- 単位
                        TO_CHAR(gt_work_tab_err_item(i).line_no)                                              -- 明細No
                        ;
      --
        IF ( gt_rpt_data_sum_tab.EXISTS( lv_key_index ) ) THEN
          NULL;
        ELSE
--
          -- =============
          -- 取得値セット
          -- =============
          gt_rpt_data_sum_tab( lv_key_index ).base_code         := gt_work_tab_err_item(i).base_code;                    -- ：拠点ｺｰﾄﾞ
          gt_rpt_data_sum_tab( lv_key_index ).base_name         := SUBSTRB(gt_work_tab_err_item(i).base_name,1,40);      -- ：拠点名称
          gt_rpt_data_sum_tab( lv_key_index ).order_number      := gt_work_tab_err_item(i).order_number;                 -- ：受注番号
          gt_rpt_data_sum_tab( lv_key_index ).order_line_no     := gt_work_tab_err_item(i).order_line_no;                -- ：受注明細No
          gt_rpt_data_sum_tab( lv_key_index ).line_no           := gt_work_tab_err_item(i).line_no;                      -- ：明細No
          gt_rpt_data_sum_tab( lv_key_index ).deliver_requested_no                                                       -- ：出荷依頼No
                                                                := SUBSTRB(gt_work_tab_err_item(i).deliver_requested_no, 1, 12);
          gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_number                                                   -- ：出荷元倉庫番号
                                                                := gt_work_tab_err_item(i).deliver_from_whse_number;
          gt_rpt_data_sum_tab( lv_key_index ).deliver_from_whse_name                                                     -- ：出荷元倉庫名
                                                                := SUBSTRB(gt_work_tab_err_item(i).deliver_from_whse_name,1,20);
          gt_rpt_data_sum_tab( lv_key_index ).customer_number   := gt_work_tab_err_item(i).customer_number;              -- ：顧客番号
          gt_rpt_data_sum_tab( lv_key_index ).customer_name     := SUBSTRB(gt_work_tab_err_item(i).customer_name,1,20);  -- ：顧客名
          gt_rpt_data_sum_tab( lv_key_index ).item_code         := gt_work_tab_err_item(i).item_code;                    -- ：品目ｺｰﾄﾞ
          gt_rpt_data_sum_tab( lv_key_index ).item_name         := SUBSTRB(gt_work_tab_err_item(i).item_name,1,20);      -- ：品名
          gt_rpt_data_sum_tab( lv_key_index ).schedule_dlv_date := gt_work_tab_err_item(i).schedule_dlv_date;            -- ：納品予定日
          gt_rpt_data_sum_tab( lv_key_index ).schedule_inspect_date                                                      -- ：検収予定日
                                                                := TO_DATE(gt_work_tab_err_item(i).schedule_inspect_date,cv_yyyymmddhhmiss);
          gt_rpt_data_sum_tab( lv_key_index ).arrival_date      := gt_work_tab_err_item(i).arrival_date;                 -- ：着日
          gt_rpt_data_sum_tab( lv_key_index ).order_quantity    := gt_work_tab_err_item(i).order_quantity;               -- ：受注数
          gt_rpt_data_sum_tab( lv_key_index ).deliver_actual_quantity                                                    -- ：出荷実績数
                                                                := gt_work_tab_err_item(i).deliver_actual_quantity;
          gt_rpt_data_sum_tab( lv_key_index ).uom_code          := gt_work_tab_err_item(i).uom_code;                     -- ：単位
          gt_rpt_data_sum_tab( lv_key_index ).output_quantity   := gt_work_tab_err_item(i).output_quantity;              -- ：差異数(受注数量-実績数量)
          gt_rpt_data_sum_tab( lv_key_index ).data_class        := cv_data_class_3;                                      -- ：データ区分
--
        END IF;
--
      --
      END LOOP line_item_excep_sum_loop;
    END IF;
--
-- 2010/04/09 Ver.1.14 Add M.Sano Start
    -- 例外２該当データリストの領域開放
    gt_work_tab_err_item.DELETE;
-- 2010/04/09 Ver.1.14 Add M.Sano End
--
    -- ======================
    -- サマリデータの登録用変数への移し変え
    -- ======================
    IF ( gt_rpt_data_sum_tab.COUNT != 0 ) THEN
    --
      -- 初回インデックスを作成
      lv_next_key_index := gt_rpt_data_sum_tab.FIRST;
      --
      WHILE ( lv_next_key_index IS NOT NULL ) LOOP
      --
        -- レコードIDの取得
        SELECT  xxcos_rep_direct_list_s01.nextval
        INTO    ln_record_id
        FROM    dual
        ;
        -- インデックスカウントアップ
        ln_idx := ln_idx + 1;
        --
        gt_rpt_data_tab( ln_idx ).record_id                := ln_record_id;
        gt_rpt_data_tab( ln_idx ).base_code                := gt_rpt_data_sum_tab(lv_next_key_index).base_code;
        gt_rpt_data_tab( ln_idx ).base_name                := gt_rpt_data_sum_tab(lv_next_key_index).base_name;
        gt_rpt_data_tab( ln_idx ).order_number             := gt_rpt_data_sum_tab(lv_next_key_index).order_number;
        gt_rpt_data_tab( ln_idx ).order_line_no            := gt_rpt_data_sum_tab(lv_next_key_index).order_line_no;
        gt_rpt_data_tab( ln_idx ).line_no                  := gt_rpt_data_sum_tab(lv_next_key_index).line_no;
        gt_rpt_data_tab( ln_idx ).deliver_requested_no     := gt_rpt_data_sum_tab(lv_next_key_index).deliver_requested_no;
        gt_rpt_data_tab( ln_idx ).deliver_from_whse_number := gt_rpt_data_sum_tab(lv_next_key_index).deliver_from_whse_number;
        gt_rpt_data_tab( ln_idx ).deliver_from_whse_name   := gt_rpt_data_sum_tab(lv_next_key_index).deliver_from_whse_name;
        gt_rpt_data_tab( ln_idx ).customer_number          := gt_rpt_data_sum_tab(lv_next_key_index).customer_number;
        gt_rpt_data_tab( ln_idx ).customer_name            := gt_rpt_data_sum_tab(lv_next_key_index).customer_name;
        gt_rpt_data_tab( ln_idx ).item_code                := gt_rpt_data_sum_tab(lv_next_key_index).item_code;
        gt_rpt_data_tab( ln_idx ).item_name                := gt_rpt_data_sum_tab(lv_next_key_index).item_name;
        gt_rpt_data_tab( ln_idx ).schedule_dlv_date        := gt_rpt_data_sum_tab(lv_next_key_index).schedule_dlv_date;
        gt_rpt_data_tab( ln_idx ).schedule_inspect_date    := gt_rpt_data_sum_tab(lv_next_key_index).schedule_inspect_date;
        gt_rpt_data_tab( ln_idx ).arrival_date             := gt_rpt_data_sum_tab(lv_next_key_index).arrival_date;
        gt_rpt_data_tab( ln_idx ).order_quantity           := gt_rpt_data_sum_tab(lv_next_key_index).order_quantity;
        gt_rpt_data_tab( ln_idx ).deliver_actual_quantity  := gt_rpt_data_sum_tab(lv_next_key_index).deliver_actual_quantity;
        gt_rpt_data_tab( ln_idx ).uom_code                 := gt_rpt_data_sum_tab(lv_next_key_index).uom_code;
        gt_rpt_data_tab( ln_idx ).output_quantity          := gt_rpt_data_sum_tab(lv_next_key_index).output_quantity;
        gt_rpt_data_tab( ln_idx ).data_class               := gt_rpt_data_sum_tab(lv_next_key_index).data_class;
        gt_rpt_data_tab( ln_idx ).created_by               := cn_created_by;
        gt_rpt_data_tab( ln_idx ).creation_date            := cd_creation_date;
        gt_rpt_data_tab( ln_idx ).last_updated_by          := cn_last_updated_by;
        gt_rpt_data_tab( ln_idx ).last_update_date         := cd_last_update_date;
        gt_rpt_data_tab( ln_idx ).last_update_login        := cn_last_update_login;
        gt_rpt_data_tab( ln_idx ).request_id               := cn_request_id;
        gt_rpt_data_tab( ln_idx ).program_application_id   := cn_program_application_id;
        gt_rpt_data_tab( ln_idx ).program_id               := cn_program_id;
        gt_rpt_data_tab( ln_idx ).program_update_date      := cd_program_update_date;
        --
        --次のインデックスを設定
        lv_next_key_index := gt_rpt_data_sum_tab.NEXT(lv_next_key_index);
      --
      END LOOP;
    --
    END IF;
--
--
--    --==================================
--    -- 1.データ取得
--    --==================================
--    <<loop_get_data>>
--    FOR l_data_rec IN data_cur LOOP
---- *********** 2009/11/26 1.11 N.Maeda DEL START *********** --
------ ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
----      IF (
----           (     l_data_rec.data_class IN (cv_data_class_1, cv_data_class_2, cv_data_class_3, cv_data_class_6)
----             AND l_data_rec.schedule_dlv_date >= TRUNC(gd_trans_start_date)
----           )
----         OR
----           (     l_data_rec.data_class IN (cv_data_class_4, cv_data_class_5)
----             AND l_data_rec.arrival_date >= TRUNC(gd_trans_start_date)
----           )
----         )
----      THEN
------ ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
---- *********** 2009/11/26 1.11 N.Maeda DEL  END  *********** --
--      -- レコードIDの取得
--      BEGIN
----
--        SELECT
--          xxcos_rep_direct_list_s01.nextval
--        INTO
--          ln_record_id
--        FROM
--          dual
--        ;
--      END;
----
--      -- カウントアップ
--      ln_idx := ln_idx + 1;
----
--      -- 変数へ格納
--      gt_rpt_data_tab( ln_idx ).record_id                := ln_record_id;                          -- レコードID 
--      gt_rpt_data_tab( ln_idx ).base_code                := l_data_rec.base_code;                  -- 拠点コード
--                                                                                                   -- 拠点名称
--      gt_rpt_data_tab( ln_idx ).base_name                := SUBSTRB( l_data_rec.base_name, 1, 40 );
--      gt_rpt_data_tab( ln_idx ).order_number             := l_data_rec.order_number;               -- 受注番号
--      gt_rpt_data_tab( ln_idx ).order_line_no            := l_data_rec.order_line_no;              -- 受注明細No.
--      gt_rpt_data_tab( ln_idx ).line_no                  := l_data_rec.line_no;                    -- 明細No.
--      gt_rpt_data_tab( ln_idx ).deliver_requested_no     := l_data_rec.deliver_requested_no;       -- 出荷依頼No
--      gt_rpt_data_tab( ln_idx ).deliver_from_whse_number := l_data_rec.deliver_from_whse_number;   -- 出荷元倉庫番号
--                                                                                                   -- 出荷元倉庫名
--      gt_rpt_data_tab( ln_idx ).deliver_from_whse_name   := SUBSTRB( l_data_rec.deliver_from_whse_name, 1, 20 );
--      gt_rpt_data_tab( ln_idx ).customer_number          := l_data_rec.customer_number;            -- 顧客番号
--                                                                                                   -- 顧客名
--      gt_rpt_data_tab( ln_idx ).customer_name            := SUBSTRB( l_data_rec.customer_name, 1, 20 );
--      gt_rpt_data_tab( ln_idx ).item_code                := l_data_rec.item_code;                  -- 品目コード
--      gt_rpt_data_tab( ln_idx ).item_name                := SUBSTRB( l_data_rec.item_name, 1, 20 );-- 品名
--      gt_rpt_data_tab( ln_idx ).schedule_dlv_date        := l_data_rec.schedule_dlv_date;          -- 納品予定日
--                                                                                                   -- 検収予定日
--      gt_rpt_data_tab( ln_idx ).schedule_inspect_date    := TO_DATE( l_data_rec.schedule_inspect_date, cv_yyyymmddhhmiss );
--      gt_rpt_data_tab( ln_idx ).arrival_date             := l_data_rec.arrival_date;               -- 着日
--      gt_rpt_data_tab( ln_idx ).order_quantity           := l_data_rec.order_quantity;             -- 受注数
--      gt_rpt_data_tab( ln_idx ).deliver_actual_quantity  := l_data_rec.deliver_actual_quantity;    -- 出荷実績数
--      gt_rpt_data_tab( ln_idx ).uom_code                 := l_data_rec.uom_code;                   -- 単位
--      gt_rpt_data_tab( ln_idx ).output_quantity          := l_data_rec.output_quantity;            -- 差異数
--      gt_rpt_data_tab( ln_idx ).data_class               := l_data_rec.data_class;                 -- データ区分
--      gt_rpt_data_tab( ln_idx ).created_by               := cn_created_by;                         -- 作成者
--      gt_rpt_data_tab( ln_idx ).creation_date            := cd_creation_date;                      -- 作成日
--      gt_rpt_data_tab( ln_idx ).last_updated_by          := cn_last_updated_by;                    -- 最終更新者
--      gt_rpt_data_tab( ln_idx ).last_update_date         := cd_last_update_date;                   -- 最終更新日
--      gt_rpt_data_tab( ln_idx ).last_update_login        := cn_last_update_login;                  -- 最終更新ﾛｸﾞｲﾝ
--      gt_rpt_data_tab( ln_idx ).request_id               := cn_request_id;                         -- 要求ID
--      gt_rpt_data_tab( ln_idx ).program_application_id   := cn_program_application_id;             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--      gt_rpt_data_tab( ln_idx ).program_id               := cn_program_id;                         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--      gt_rpt_data_tab( ln_idx ).program_update_date      := cd_program_update_date;                -- ﾌﾟﾛｸﾞﾗﾑ更新日
----
---- *********** 2009/11/26 1.11 N.Maeda DEL START *********** --
------ ******************** 2009/10/05 1.9 K.Satomura ADD START ******************************* --
----      END IF;
------ ******************** 2009/10/05 1.9 K.Satomura ADD END   ******************************* --
---- *********** 2009/11/26 1.11 N.Maeda DEL  END  *********** --
--    END LOOP loop_get_data;
--
-- ************* 2010/03/25 1.14 N.Maeda MOD  END  ************* --
    --処理件数カウント
    gn_target_cnt := gt_rpt_data_tab.COUNT;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ワークテーブルデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- プログラム名
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
    lv_table_name    VARCHAR2(5000);
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
    --==================================
    -- 1.帳票ワークテーブル登録処理
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
--
      FORALL i IN 1..gt_rpt_data_tab.COUNT
        INSERT INTO
          xxcos_rep_direct_list
        VALUES
          gt_rpt_data_tab(i)
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- 正常件数
    gn_normal_cnt := gt_rpt_data_tab.COUNT;
--
  EXCEPTION
    --帳票ワークテーブル登録失敗
    WHEN global_insert_data_expt THEN
--
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application         => cv_xxcos_short_name,
                         iv_name                => cv_msg_vl_table_name
                       );
--
      ov_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application        => cv_xxcos_short_name,
                         iv_name               => cv_msg_insert_err,
                         iv_token_name1        => cv_tkn_nm_table_name,
                         iv_token_value1       => lv_table_name,
                         iv_token_name2        => cv_tkn_nm_key_data,
                         iv_token_value2       => NULL
                       );
--
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
  END insert_rpt_wrk_data;
--
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動(A-4)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg       VARCHAR2(5000);
    lv_file_name        VARCHAR2(100);
    lv_tkn_vl_api_name  VARCHAR2(100);
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
    --明細0件用メッセージ取得
    lv_nodata_msg := xxccp_common_pkg.get_msg(
                       iv_application        => cv_xxcos_short_name,
                       iv_name               => cv_msg_no_data_err
                     );
--
    --出力ファイル名編集
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF起動
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_report_id,
      iv_output_mode          => cv_output_mode,
      iv_frm_file             => cv_frm_file,
      iv_vrq_file             => cv_vrq_file,
      iv_org_id               => NULL,
      iv_user_name            => NULL,
      iv_resp_name            => NULL,
      iv_doc_name             => NULL,
      iv_printer_name         => NULL,
      iv_request_id           => TO_CHAR( cn_request_id ),
      iv_nodata_msg           => lv_nodata_msg,
      iv_svf_param1           => NULL,
      iv_svf_param2           => NULL,
      iv_svf_param3           => NULL,
      iv_svf_param4           => NULL,
      iv_svf_param5           => NULL,
      iv_svf_param6           => NULL,
      iv_svf_param7           => NULL,
      iv_svf_param8           => NULL,
      iv_svf_param9           => NULL,
      iv_svf_param10          => NULL,
      iv_svf_param11          => NULL,
      iv_svf_param12          => NULL,
      iv_svf_param13          => NULL,
      iv_svf_param14          => NULL,
      iv_svf_param15          => NULL
    );
    --SVF起動失敗
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF起動例外 ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name := xxccp_common_pkg.get_msg(
                              iv_application        => cv_xxcos_short_name,
                              iv_name               => cv_msg_vl_api_name
                            );
--
      ov_errmsg          := xxccp_common_pkg.get_msg(
                              iv_application        => cv_xxcos_short_name,
                              iv_name               => cv_msg_api_err,
                              iv_token_name1        => cv_tkn_nm_api_name,
                              iv_token_value1       => lv_tkn_vl_api_name
                            );
--
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-5)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
    lv_request_name  VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
        xrdl.record_id rec_id              -- レポートID
      FROM
        xxcos_rep_direct_list xrdl         -- 直送受注例外データリスト帳票ワークテーブル
      WHERE
        xrdl.request_id = cn_request_id    -- リクエストID
      FOR UPDATE NOWAIT
      ;
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
    --処理対象データロック
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
--
    EXCEPTION
      --処理対象データロック例外
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
--
    END;
--
    --処理対象データ削除
    BEGIN
      --対象データ削除
      DELETE
      FROM 
        xxcos_rep_direct_list xrdl          -- 直送受注例外データリスト帳票ワークテーブル
      WHERE
        xrdl.request_id = cn_request_id     -- リクエストID
      ;
--
    EXCEPTION
      --処理対象データ削除失敗
      WHEN OTHERS THEN
        RAISE global_delete_data_expt;
--
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application        => cv_xxcos_short_name,
                         iv_name               => cv_msg_vl_table_name
                       );
--
      ov_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application        => cv_xxcos_short_name,
                         iv_name               => cv_msg_lock_err,
                         iv_token_name1        => cv_tkn_nm_lock_table_name,
                         iv_token_value1       => lv_table_name
                       );
--
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    --*** 処理対象データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      lv_table_name   := xxccp_common_pkg.get_msg(
                           iv_application       => cv_xxcos_short_name,
                           iv_name              => cv_msg_vl_table_name
                         );
--
      lv_request_name := xxccp_common_pkg.get_msg(
                           iv_application       => cv_xxcos_short_name,
                           iv_name              => cv_msg_vl_request_id
                         );
--
      xxcos_common_pkg.makeup_key_info(
                           iv_item_name1      => lv_request_name,
                           iv_data_value1     => TO_CHAR( cn_request_id ),
                           ov_key_info        => lv_key_info,             --編集されたキー情報
                           ov_errbuf          => lv_errbuf,               --エラーメッセージ
                           ov_retcode         => lv_retcode,              --リターンコード
                           ov_errmsg          => lv_errmsg                --ユーザ・エラー・メッセージ
      );
--
      ov_errmsg     :=  xxccp_common_pkg.get_msg(
                          iv_application      => cv_xxcos_short_name,
                          iv_name             => cv_msg_delete_err,
                          iv_token_name1      => cv_tkn_nm_table_name,
                          iv_token_value1     => lv_table_name,
                          iv_token_name2      => cv_tkn_nm_key_data,
                          iv_token_value2     => lv_key_info
                        );
--
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code  IN  VARCHAR2,     --   1.拠点コード
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
--2009/06/25  Ver1.6 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
--2009/06/25  Ver1.6 T1_1437  Add end
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
    -- A-1  初期処理
    -- ===============================
    init(
      iv_base_code,      -- 1.拠点コード
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  例外データ取得
    -- ===============================
    get_data(
      iv_base_code,      -- 1.拠点コード
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ワークテーブルデータ登録
    -- ===============================
    insert_rpt_wrk_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  SVFコンカレント起動
    -- ===============================
    execute_svf(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
-- 2009/06/25  Ver1.6  T1_1437  Mod Start
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
--
    --
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
-- 2009/06/25  Ver1.6 T1_1437  Mod End
--
    -- ===============================
    -- A-5  ワークテーブルデータ削除
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/25  Ver1.6 T1_1437  Add start
    --エラーの場合、ロールバックするのでここでコミット
    COMMIT;
--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
-- 2009/06/25  Ver1.6 T1_1437  Add End
--
    --明細0件時ステータス制御処理
--****************************** 2009/06/17 1.5 N.Nishimura MOD START ******************************--
--    IF ( gn_target_cnt = 0 ) THEN
    IF ( gn_target_cnt <> 0 ) THEN
--****************************** 2009/06/17 1.5 N.Nishimura MOD  END  ******************************--
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_base_code  IN  VARCHAR2       --   1.拠点コード
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
       iv_which   => cv_log_header_log
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
       iv_base_code  -- 1.拠点コード
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
/****
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
****/
    --
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
                     iv_application  => cv_appl_short_name
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
END XXCOS008A03R;
/
