CREATE OR REPLACE PACKAGE BODY XXCOS006A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS006A04R (body)
 * Description      : 出荷依頼書
 * MD.050           : 出荷依頼書 MD050_COS_006_A04
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  check_parameter        パラメータチェック処理(A-1)
 *  get_data               データ取得(A-2)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-3)
 *  execute_svf            ＳＶＦ起動(A-4)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   K.Kakishita      新規作成
 *  2009/02/26    1.1   K.Kakishita      帳票コンカレント起動後のワークテーブル削除処理の
 *                                       コメント化を外す。
 *  2009/03/03    1.2   N.Maeda          不要な定数の削除
 *                                       ( ct_qct_cus_class_mst , ct_qcc_cus_class_mst1 )
 *  2009/04/01    1.3   N.Maeda          【ST障害No.T1-0085対応】
 *                                       非在庫品目を非抽出データへ変更
 *                                       【ST障害No.T1-0049対応】
 *                                       備考データ取得カラム名の修正
 *                                       descriptionへのセット内容を修正
 *  2009/06/22    1.4   K.Kiriu          【ST障害No.T1-1437対応】
 *                                       データパージ不具合対応
 *  2009/07/09    1.5   M.Sano           【SCS障害No.0000063対応】
 *                                       情報区分によるデータ作成対象の制御
 *  2009/10/01    1.6   S.Miyakoshi      【SCS障害No.0001378対応】
 *                                       帳票ワークテーブルの桁あふれ対応
 *                                       クイックコード取得時のパフォーマンス対応
 *  2013/03/26    1.7   T.Ishiwata       【E_本稼動_10343対応】
 *                                        パラメータ「出力区分」追加、文言、タイトル変更
 *  2013/05/16    1.8   T.Ishiwata       【E_本稼動_10683対応】
 *                                        ヒント句の見直し
 *  2014/11/14    1.9   K.Oomata         【E_本稼動_12575対応】
 *                                        パラメータ「出力順優先項目」「国際CSV出力」追加。
 *                                        処理対象受注ソース修正。
 *                                       「摘要」欄に顧客発注番号設定するよう修正。
 *                                        SVF共通関数に渡すVRQファイルの設定値修正。
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
  global_proc_date_err_expt   EXCEPTION;
  global_api_err_expt         EXCEPTION;
  global_call_api_expt        EXCEPTION;
  global_date_reversal_expt   EXCEPTION;
  global_insert_data_expt     EXCEPTION;
  global_delete_data_expt     EXCEPTION;
  global_nodata_expt          EXCEPTION;
  global_get_profile_expt     EXCEPTION;
  --*** 処理対象データロック例外 ***
  global_data_lock_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS006A04R';          -- パッケージ名
  --帳票関連
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS006A04R';          -- コンカレント名
  cv_file_id                CONSTANT  VARCHAR2(100) := 'XXCOS006A04R';          -- 帳票ＩＤ
  cv_extension_pdf          CONSTANT  VARCHAR2(100) := '.pdf';                  -- 拡張子（ＰＤＦ）
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS006A04S.xml';      -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS006A04S.vrq';      -- クエリー様式ファイル名
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
  cv_vrq_file1              CONSTANT  VARCHAR2(100) := 'XXCOS006A04S1.vrq';     -- クエリー様式ファイル名(伝票No.優先用)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
  cv_output_mode_pdf        CONSTANT  VARCHAR2(1)   := '1';                     -- 出力区分（ＰＤＦ）
  --アプリケーション短縮名
  ct_xxcos_appl_short_name  CONSTANT  fnd_application.application_short_name%TYPE
                                      := 'XXCOS';                     --販物短縮アプリ名
  ct_xxwsh_appl_short_name  CONSTANT  fnd_application.application_short_name%TYPE
                                      := 'XXWSH';                     --短縮アプリ名
  --販物メッセージ
  ct_msg_lock_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00001';          --ロック取得エラーメッセージ
  ct_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00004';          --プロファイル取得エラー
  ct_msg_date_reversal_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00005';          --日付逆転エラー
  ct_msg_insert_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00010';          --データ登録エラーメッセージ
  ct_msg_delete_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00012';          --データ削除エラーメッセージ
  ct_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';          --データ取得エラーメッセージ
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00014';          --業務日付取得エラー
  ct_msg_call_api_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00017';          --API呼出エラーメッセージ
  ct_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';          --明細0件用メッセージ
  ct_msg_svf_api            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00041';          --ＳＶＦ起動ＡＰＩ
  ct_msg_request            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00042';          --要求ＩＤ
  ct_msg_org_id             CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00047';          --MO:営業単位
  ct_msg_max_date           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00056';          --XXCOS:MAX日付
  ct_msg_company_name       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00058';          --XXCOS:会社名
  ct_msg_parameter          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11451';          --パラメータ出力メッセージ
  ct_msg_ord_dt_from        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11452';          --受注日(From)
  ct_msg_ord_dt_to          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11453';          --受注日(To)
  ct_msg_rpt_wrk_tbl        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11454';          --帳票ワークテーブル
  --トークン
  cv_tkn_table              CONSTANT  VARCHAR2(100) := 'TABLE';                 --テーブル
  cv_tkn_date_from          CONSTANT  VARCHAR2(100) := 'DATE_FROM';             --日付（From)
  cv_tkn_date_to            CONSTANT  VARCHAR2(100) := 'DATE_TO';               --日付（To)
  cv_tkn_profile            CONSTANT  VARCHAR2(100) := 'PROFILE';               --プロファイル
  cv_tkn_table_name         CONSTANT  VARCHAR2(100) := 'TABLE_NAME';            --テーブル名称
  cv_tkn_key_data           CONSTANT  VARCHAR2(100) := 'KEY_DATA';              --キーデータ
  cv_tkn_api_name           CONSTANT  VARCHAR2(100) := 'API_NAME';              --ＡＰＩ名称
  cv_tkn_param1             CONSTANT  VARCHAR2(100) := 'PARAM1';                --第１入力パラメータ
  cv_tkn_param2             CONSTANT  VARCHAR2(100) := 'PARAM2';                --第２入力パラメータ
  cv_tkn_param3             CONSTANT  VARCHAR2(100) := 'PARAM3';                --第３入力パラメータ
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
  cv_tkn_param4             CONSTANT  VARCHAR2(100) := 'PARAM4';                --第４入力パラメータ
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
  cv_tkn_param5             CONSTANT  VARCHAR2(100) := 'PARAM5';                --第５入力パラメータ
  cv_tkn_param6             CONSTANT  VARCHAR2(100) := 'PARAM6';                --第６入力パラメータ
-- 2014/11/14 Ver.1.9 Add K.Oomata End
  cv_tkn_request            CONSTANT  VARCHAR2(100) := 'REQUEST';               --要求ＩＤ
  --プロファイル名称
  ct_prof_org_id            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'ORG_ID';
  ct_prof_max_date          CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_MAX_DATE';
  ct_prof_company_name      CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_COMPANY_NAME';
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
  ct_prof_dlv_cont_name     CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DELIVERY_CONTRACTOR_NAME';          -- XXCOS:運送請負者名
  ct_prof_dlv_cont_address  CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_DELIVERY_CONTRACTOR_ADDRESS';       -- XXCOS:運送請負者住所
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
  --クイックコードタイプ
  ct_qct_order_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_TRAN_TYPE_MST_006_A04';
  ct_qct_order_source       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_ODR_SRC_MST_006_A04';
  ct_qct_hokanbasyo_type    CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_HOKAN_TYPE_MST_006_A04';
  ct_qct_arrival_time       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXWSH_ARRIVAL_TIME';
  ct_xxcos1_no_inv_item_code CONSTANT fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_NO_INV_ITEM_CODE';
  --クイックコード
  ct_qcc_order_type         CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_006_A04%';
  ct_qcc_order_source       CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_006_A04%';
  ct_qcc_hokanbasyo_type    CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_006_A04%';
  --使用可能フラグ定数
  ct_enabled_flag_yes       CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                      := 'Y';                         --使用可能
  --受注ヘッダステータス
  ct_hdr_status_booked      CONSTANT  oe_order_headers_all.flow_status_code%TYPE
                                      := 'BOOKED';                    --記帳済
  --受注明細ステータス
  ct_ln_status_closed       CONSTANT  oe_order_lines_all.flow_status_code%TYPE
                                      := 'CLOSED';                    --クローズ
  ct_ln_status_cancelled    CONSTANT  oe_order_lines_all.flow_status_code%TYPE
                                      := 'CANCELLED';                 --取消
  --使用目的
  ct_site_use_code_ship_to  CONSTANT  hz_cust_site_uses_all.site_use_code%TYPE
                                      := 'SHIP_TO';                   --出荷先
  --受注タイプコード
  ct_tran_type_code_order   CONSTANT  oe_transaction_types_all.transaction_type_code%TYPE
                                      := 'ORDER';                     --ORDEDR
  --換算率デフォルト
  ct_conv_rate_default      CONSTANT  mtl_uom_class_conversions.conversion_rate%TYPE
                                      := 1;                           --換算率
  --存在フラグ
  cv_exists_flag_yes        CONSTANT  VARCHAR2(1)   := 'Y';           --存在あり
  --フォーマット
  cv_fmt_date8              CONSTANT  VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT  VARCHAR2(10)  := 'RRRR/MM/DD';
  cv_fmt_datetime           CONSTANT  VARCHAR2(21)  := 'RRRR/MM/DD HH24:MI:SS';
  --文字定数
  cv_hyphen                 CONSTANT  VARCHAR2(1)   := '-';           --ハイフン
  cv_space                  CONSTANT  VARCHAR2(1)   := ' ';           --スペース
/* 2009/07/09 Ver1.5 Add Start */
  ct_info_class_01          CONSTANT  VARCHAR2(2)   := '01';          --情報区分：「01」
/* 2009/07/09 Ver1.5 Add End */
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
  cv_output_code_01         CONSTANT  VARCHAR2(1)   := '0';           --出力区分：「0」
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 ADD START ************************ --
  --言語コード
  ct_lang            CONSTANT fnd_lookup_values.language%TYPE
                                            := USERENV( 'LANG' );
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 ADD  END  ************************ --
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
  cv_sort_key_0             CONSTANT  VARCHAR2(1)   := '0';           --出力順優先項目：0 出荷元保管場所優先
  cv_sort_key_1             CONSTANT  VARCHAR2(1)   := '1';           --出力順優先項目：1：伝票No.優先
  cv_international_csv_y    CONSTANT  VARCHAR2(1)   := 'Y';           --国際CSV出力：Y 国際CSVを対象とする
  cv_international_csv_n    CONSTANT  VARCHAR2(1)   := 'N';           --国際CSV出力：N 国際CSVを対象としない
  cv_connection_code        CONSTANT  VARCHAR2(3)   := ' : ';
-- 2014/11/14 Ver.1.9 Add K.Oomata End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --帳票ワーク用テーブル型定義
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_deli_req%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --パラメータ
  gt_ship_from_subinv_code            mtl_secondary_inventories.secondary_inventory_name%TYPE;
                                                                      -- 出荷元保管場所
  gd_ordered_date_from                DATE;                           -- 受注日(From)
  gd_ordered_date_to                  DATE;                           -- 受注日(To)
  --初期取得
  gd_process_date                     DATE;                           -- 業務日付
  gn_org_id                           NUMBER;                         -- 営業単位
  gd_max_date                         DATE;                           -- MAX日付
  gv_company_name                     VARCHAR2(30);                   -- 会社名
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
  gt_output_code                      xxcos_rep_deli_req.output_code%TYPE;          --出力区分
  gt_dlv_cont_name                    xxcos_rep_deli_req.dlv_contractor_info%TYPE;  --運送請負者名
  gt_dlv_cont_address                 xxcos_rep_deli_req.dlv_contractor_info%TYPE;  --運送請負者住所
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
  --帳票ワーク内部テーブル
  g_rpt_data_tab                      g_rpt_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ship_from_subinv_code  IN      VARCHAR2,       -- 1.出荷元倉庫
    iv_ordered_date_from      IN      VARCHAR2,       -- 2.受注日（From）
    iv_ordered_date_to        IN      VARCHAR2,       -- 3.受注日（To）
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
    iv_output_code            IN      VARCHAR2,       -- 4.出力区分
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
    iv_sort_key               IN      VARCHAR2,          -- 5.出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
    iv_international_csv      IN      VARCHAR2,          -- 6.国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
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
    --==================================
    -- 1.パラメータ出力
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_parameter,
                                   iv_token_name1        => cv_tkn_param1,
                                   iv_token_value1       => iv_ship_from_subinv_code,
                                   iv_token_name2        => cv_tkn_param2,
                                   iv_token_value2       => iv_ordered_date_from,
                                   iv_token_name3        => cv_tkn_param3,
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata Start
--                                   iv_token_value3       => iv_ordered_date_to
                                   iv_token_value3       => iv_ordered_date_to,
                                   iv_token_name4        => cv_tkn_param4,
-- 2014/11/14 Ver.1.9 Mod K.Oomata Start
--                                   iv_token_value4       => iv_output_code
---- 2013/03/26 Ver.1.7 Mod T.Ishiwata End
                                   iv_token_value4       => iv_output_code,
                                   iv_token_name5        => cv_tkn_param5,
                                   iv_token_value5       => iv_sort_key,
                                   iv_token_name6        => cv_tkn_param6,
                                   iv_token_value6       => iv_international_csv
-- 2014/11/14 Ver.1.9 Mod K.Oomata End
                                 );
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==================================
    -- 2.パラメータ変換
    --==================================
    gt_ship_from_subinv_code  := iv_ship_from_subinv_code;
    gd_ordered_date_from      := TO_DATE( iv_ordered_date_from, cv_fmt_datetime );
    gd_ordered_date_to        := TO_DATE( iv_ordered_date_to, cv_fmt_datetime );
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
    gt_output_code            := iv_output_code;
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter';        -- プログラム名
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
    lv_org_id        VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
    lv_ord_dt_from   VARCHAR2(5000);
    lv_ord_dt_to     VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.業務日付取得
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.MO:営業単位
    --==================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id,
                                   iv_token_value1       => ct_prof_org_id
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --==================================
    -- 3.XXCOS:MAX日付
    --==================================
    lv_max_date               := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date  IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 4.XXCOS:会社名
    --==================================
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--    gv_company_name           := FND_PROFILE.VALUE( ct_prof_company_name );
    gv_company_name           := SUBSTRB( FND_PROFILE.VALUE( ct_prof_company_name ), 1, 30 );
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_company_name IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_company_name
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 5.パラメータチェック
    --==================================
    IF ( gd_ordered_date_from > gd_ordered_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
    --==================================
    -- 6.XXCOS:運送請負者名
    --==================================
    gt_dlv_cont_name     := FND_PROFILE.VALUE( ct_prof_dlv_cont_name );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_dlv_cont_name IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := ct_prof_dlv_cont_name;
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 7.XXCOS:運送請負者住所
    --==================================
    gt_dlv_cont_address   := FND_PROFILE.VALUE( ct_prof_dlv_cont_address );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_dlv_cont_address IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := ct_prof_dlv_cont_address;
      --
      RAISE global_get_profile_expt;
    END IF;
--
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 日付逆転例外ハンドラ ***
    WHEN global_date_reversal_expt THEN
      lv_ord_dt_from          := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_ord_dt_from
                                 );
      lv_ord_dt_to            := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_ord_dt_to
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_date_reversal_err,
                                   iv_token_name1        => cv_tkn_date_from,
                                   iv_token_value1       => lv_ord_dt_from,
                                   iv_token_name2        => cv_tkn_date_to,
                                   iv_token_value2       => lv_ord_dt_to
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
    iv_international_csv   IN VARCHAR2,   -- 国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
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
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
    cv_space_char    CONSTANT VARCHAR2(2) := '　'; -- 全角スペース
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
--
    -- *** ローカル変数 ***
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur
    IS
      SELECT
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
       /*+ OPTIMIZER_FEATURES_ENABLE('10.2.0.3') 
           INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N10)
-- 2013/05/16 Ver.1.8 Add T.Ishiwata Start
           NO_INDEX(ooha XXCOS_OE_ORDER_HEADERS_ALL_N11)
-- 2013/05/16 Ver.1.8 Add T.Ishiwata End
          USE_NL(ooha oola oos otta ottt hla xla hca xca hcsua hcasa hps hp hl msib mucc msi)
       */
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
        oola.subinventory                   subinventory,                 --保管場所
        msi.description                     deliver_from_locat_name,      --出荷元保管場所名称
        xca.delivery_base_code              delivery_base_code,           --納品拠点コード
        xla.location_name                   delivery_base_name,           --納品拠点名
        xla.zip                             delivery_base_post_no,        --納品拠点郵便番号
        xla.address_line1                   delivery_base_address,        --納品拠点住所
        xla.phone                           delivery_base_telephone_no,   --納品拠点電話番号
        xla.fax                             delivery_base_fax_no,         --納品拠点FAX番号
        ooha.order_number                   order_number,                 --伝票NO
        TRUNC( ooha.ordered_date )          ordered_date,                 --出荷依頼日
        TRUNC( oola.schedule_ship_date )    schedule_ship_date,           --出荷日
        oola.request_date                   request_date,                 --着日
        oola.attribute8                     requested_time_from,          --時間指定(From)
        oola.attribute9                     requested_time_to,            --時間指定(To)
        hca.account_number                  delivery_to_code,             --配送先コード
        hp.party_name                       delivery_to_name,             --配送先名
        hl.city                             delivery_to_city,             --配送先都道府県
        hl.state                            delivery_to_state,            --配送先市町村
        hl.address1                         delivery_to_address1,         --配送先住所１
        hl.address2                         delivery_to_address2,         --配送先住所２
        hl.address_lines_phonetic           delivery_to_tel,              --電話番号
-- 2014/11/14 Ver.1.9 Mod K.Oomata Start
--        ooha.shipping_instructions          shipping_instructions,        --出荷指示
        ooha.cust_po_number
        || cv_connection_code ||
        ooha.shipping_instructions          shipping_instructions,        --顧客発注番号 : 出荷指示 (帳票上の摘要欄)
-- 2014/11/14 Ver.1.9 Mod K.Oomata End
        oola.line_number                    line_number,                  --明細番号
        msib.segment1                       item_code,                    --品目コード
        msib.description                    description,                  --摘要
        NVL( mucc.conversion_rate, ct_conv_rate_default )
                                            conversion_rate,              --換算値
        oola.ordered_quantity               ordered_quantity,             --受注数量
        oola.order_quantity_uom             order_quantity_uom,           --受注単位
        oola.attribute7                     remark                        --備考
      FROM
        oe_order_headers_all                ooha,                         --受注ヘッダテーブル
        oe_order_lines_all                  oola,                         --受注明細テーブル
        oe_order_sources                    oos,                          --受注ソースマスタ
        oe_transaction_types_all            otta,                         --受注タイプマスタ
        oe_transaction_types_tl             ottt,                         --受注タイプマスタ
        hr_locations_all                    hla,                          --事業所マスタ
        xxcmn_locations_all                 xla,                          --事業所アドオンマスタ
        hz_cust_accounts                    hca,                          --顧客マスタ
        xxcmm_cust_accounts                 xca,                          --アカウントアドオンマスタ
        hz_cust_site_uses_all               hcsua,                        --顧客使用目的マスタ
        hz_cust_acct_sites_all              hcasa,                        --顧客所在地マスタ
        hz_party_sites                      hps,                          --パーティサイトマスタ
        hz_parties                          hp,                           --パーティマスタ
        hz_locations                        hl,                           --顧客事業所マスタ
        mtl_system_items_b                  msib,                         --品目マスタ
        mtl_uom_class_conversions           mucc,                         --単位変換マスタ
        mtl_secondary_inventories           msi                           --保管場所マスタ
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
        ,xxcos_login_base_info_v       xlbiv
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
      WHERE
        ooha.header_id                      = oola.header_id
      AND ooha.order_type_id                = otta.transaction_type_id
      AND otta.transaction_type_id          = ottt.transaction_type_id
      AND otta.transaction_type_code        = ct_tran_type_code_order
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--            FROM
--              fnd_application               fa,
--              fnd_lookup_types              flt,
--              fnd_lookup_values             flv
--            WHERE
--              fa.application_id             = flt.application_id
--            AND flt.lookup_type             = flv.lookup_type
--            AND fa.application_short_name   = ct_xxcos_appl_short_name
--            AND flv.lookup_type             = ct_qct_order_type
--            AND flv.lookup_code             LIKE ct_qcc_order_type
--            AND flv.meaning                 = ottt.name
--            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
--            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
--            AND flv.language                = USERENV( 'LANG' )
--            AND ROWNUM                      = 1
            FROM
              fnd_lookup_values             flv
            WHERE
                flv.lookup_type             = ct_qct_order_type
            AND flv.lookup_code             LIKE ct_qcc_order_type
            AND flv.meaning                 = ottt.name
            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
            AND flv.language                = ct_lang
            AND ROWNUM                      = 1
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
          )
      AND ottt.language                     = USERENV( 'LANG' )
      AND ooha.order_source_id              = oos.order_source_id
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--            FROM
--              fnd_application               fa,
--              fnd_lookup_types              flt,
--              fnd_lookup_values             flv
--            WHERE
--              fa.application_id             = flt.application_id
--            AND flt.lookup_type             = flv.lookup_type
--            AND fa.application_short_name   = ct_xxcos_appl_short_name
--            AND flv.lookup_type             = ct_qct_order_source
--            AND flv.lookup_code             LIKE ct_qcc_order_source
--            AND flv.meaning                 = oos.name
--            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
--            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
--            AND flv.language                = USERENV( 'LANG' )
--            AND ROWNUM                      = 1
            FROM
              fnd_lookup_values             flv
            WHERE
                flv.lookup_type             = ct_qct_order_source
            AND flv.lookup_code             LIKE ct_qcc_order_source
            AND flv.meaning                 = oos.name
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
            AND (
                 (
                  iv_international_csv       = cv_international_csv_y    --国際CSV出力：Y 国際CSVを対象とする
                  AND
                  NVL(flv.attribute1,cv_international_csv_y) = cv_international_csv_y
                 )
                 OR
                 (
                  iv_international_csv       = cv_international_csv_n    --国際CSV出力：N 国際CSVを対象としない
                  AND
                  flv.attribute1             IS NULL
                 )
                )
-- 2014/11/14 Ver.1.9 Add K.Oomata End
            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
            AND flv.language                = ct_lang
            AND ROWNUM                      = 1
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
          )
      AND ooha.flow_status_code             = ct_hdr_status_booked
      AND oola.flow_status_code             NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata Start
--      AND TRUNC( ooha.ordered_date )        >= gd_ordered_date_from
      AND ooha.ordered_date         >= gd_ordered_date_from
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata End
      AND TRUNC( ooha.ordered_date )        <= NVL( gd_ordered_date_to, gd_max_date )
      AND oola.subinventory                 = msi.secondary_inventory_name
      AND oola.ship_from_org_id             = msi.organization_id
      AND oola.subinventory                 = NVL( gt_ship_from_subinv_code, oola.subinventory )
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--            FROM
--              fnd_application               fa,
--              fnd_lookup_types              flt,
--              fnd_lookup_values             flv
--            WHERE
--              fa.application_id             = flt.application_id
--            AND flt.lookup_type             = flv.lookup_type
--            AND fa.application_short_name   = ct_xxcos_appl_short_name
--            AND flv.lookup_type             = ct_qct_hokanbasyo_type
--            AND flv.lookup_code             LIKE ct_qcc_hokanbasyo_type
--            AND flv.meaning                 = msi.attribute13
--            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
--            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
--            AND flv.language                = USERENV( 'LANG' )
--            AND ROWNUM                      = 1
            FROM
              fnd_lookup_values             flv
            WHERE
                flv.lookup_type             = ct_qct_hokanbasyo_type
            AND flv.lookup_code             LIKE ct_qcc_hokanbasyo_type
            AND flv.meaning                 = msi.attribute13
            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
            AND flv.language                = ct_lang
            AND ROWNUM                      = 1
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
          )
      AND oola.sold_to_org_id               = hca.cust_account_id
      AND hca.cust_account_id               = xca.customer_id
      AND hca.party_id                      = hp.party_id
      AND xca.delivery_base_code            = hla.location_code
      AND hla.location_id                   = xla.location_id
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata Start
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
--              xxcos_login_base_info_v       xlbiv
--            WHERE
--              xlbiv.base_code               = xca.delivery_base_code
--            AND ROWNUM                      = 1
--          )
      AND xlbiv.base_code                   = xca.delivery_base_code
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata End
      AND oola.ship_to_org_id               = hcsua.site_use_id
      AND hcsua.site_use_code               = ct_site_use_code_ship_to
      AND hcsua.cust_acct_site_id           = hcasa.cust_acct_site_id
      AND hcasa.party_site_id               = hps.party_site_id
      AND hps.location_id                   = hl.location_id
      AND oola.inventory_item_id            = msib.inventory_item_id
      AND oola.ship_from_org_id             = msib.organization_id
      AND mucc.inventory_item_id (+)        = oola.inventory_item_id
      AND mucc.to_uom_code (+)              = oola.order_quantity_uom
      AND ooha.org_id                       = gn_org_id
      AND TRUNC( ooha.ordered_date )        >= xla.start_date_active
      AND TRUNC( ooha.ordered_date )        <= NVL( xla.end_date_active, ooha.ordered_date )
/* 2009/07/09 Ver1.5 Add Start */
      AND ct_info_class_01                  =  NVL(ooha.global_attribute3, ct_info_class_01)
/* 2009/07/09 Ver1.5 Add End */
      AND msib.segment1 NOT IN (
            SELECT  look_val.lookup_code
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--            FROM    fnd_lookup_values     look_val,
--                    fnd_lookup_types_tl   types_tl,
--                    fnd_lookup_types      types,
--                    fnd_application_tl    appl,
--                    fnd_application       app
--            WHERE   appl.application_id   = types.application_id
--            AND     app.application_id    = appl.application_id
--            AND     types_tl.lookup_type  = look_val.lookup_type
--            AND     types.lookup_type     = types_tl.lookup_type
--            AND     types.security_group_id   = types_tl.security_group_id
--            AND     types.view_application_id = types_tl.view_application_id
--            AND     types_tl.language = USERENV( 'LANG' )
--            AND     look_val.language = USERENV( 'LANG' )
--            AND     appl.language     = USERENV( 'LANG' )
--            AND     app.application_short_name = ct_xxcos_appl_short_name
--            AND     gd_process_date      >= look_val.start_date_active
--            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--            AND     look_val.enabled_flag = ct_enabled_flag_yes
--            AND     look_val.lookup_type = ct_xxcos1_no_inv_item_code )
            FROM    fnd_lookup_values     look_val
            WHERE   look_val.language = ct_lang
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     look_val.enabled_flag = ct_enabled_flag_yes
            AND     look_val.lookup_type = ct_xxcos1_no_inv_item_code )
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
      ;
--
      --====================================================
      -- 時間指定文字列取得
      --====================================================
      CURSOR xat_cur(
        iv_request_time      IN         VARCHAR2,
        id_ordered_date      IN         DATE
      )
      IS
        SELECT
          flv.lookup_code               lookup_code,
          flv.description               description
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--        FROM
--          fnd_application               fa,
--          fnd_lookup_types              flt,
--          fnd_lookup_values             flv
--        WHERE
--          fa.application_id             = flt.application_id
--        AND flt.lookup_type             = flv.lookup_type
--        AND fa.application_short_name   = ct_xxwsh_appl_short_name
--        AND flt.lookup_type             = ct_qct_arrival_time
--        AND flv.lookup_code             = iv_request_time
--        AND id_ordered_date             >= flv.start_date_active
--        AND id_ordered_date             <= NVL( flv.end_date_active, gd_max_date )
--        AND flv.language                = USERENV( 'LANG' )
--        AND flv.enabled_flag            = ct_enabled_flag_yes
--        AND ROWNUM                      = 1
        FROM
          fnd_lookup_values             flv
        WHERE
            flv.lookup_type             = ct_qct_arrival_time
        AND flv.lookup_code             = iv_request_time
        AND id_ordered_date             >= flv.start_date_active
        AND id_ordered_date             <= NVL( flv.end_date_active, gd_max_date )
        AND flv.language                = ct_lang
        AND flv.enabled_flag            = ct_enabled_flag_yes
        AND ROWNUM                      = 1
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
        ;
    -- *** ローカル・レコード ***
    l_data_rec                          data_cur%ROWTYPE;
    l_xat_rec                           xat_cur%ROWTYPE;
    l_xatf_rec                          xat_cur%ROWTYPE;
    l_xatt_rec                          xat_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_idx          := 0;
--
    --==================================
    -- 1.データ取得
    --==================================
    <<loop_get_data>>
    FOR l_data_rec IN data_cur
    LOOP
      -- レコードIDの取得
      BEGIN
        SELECT
          xxcos_rep_deli_req_s01.NEXTVAL          redord_id
        INTO
          ln_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx                  := ln_idx + 1;
      --内部テーブルセット
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;
      g_rpt_data_tab(ln_idx).despatching_code             := l_data_rec.subinventory;
      g_rpt_data_tab(ln_idx).company_name                 := gv_company_name;
      g_rpt_data_tab(ln_idx).deliver_from_locat_name      := SUBSTRB( l_data_rec.deliver_from_locat_name, 1, 40 );
      g_rpt_data_tab(ln_idx).base_code                    := l_data_rec.delivery_base_code;
      g_rpt_data_tab(ln_idx).base_name                    := l_data_rec.delivery_base_name;
      g_rpt_data_tab(ln_idx).base_post_no                 := l_data_rec.delivery_base_post_no;
      g_rpt_data_tab(ln_idx).base_address                 := l_data_rec.delivery_base_address;
      g_rpt_data_tab(ln_idx).base_telephone_no            := l_data_rec.delivery_base_telephone_no;
      g_rpt_data_tab(ln_idx).base_fax_no                  := l_data_rec.delivery_base_fax_no;
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--      g_rpt_data_tab(ln_idx).entry_number                 := l_data_rec.order_number;
      g_rpt_data_tab(ln_idx).entry_number                 := SUBSTRB( l_data_rec.order_number, 1, 12 );
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
      g_rpt_data_tab(ln_idx).delivery_requested_date      := l_data_rec.ordered_date;
      g_rpt_data_tab(ln_idx).shipped_date                 := l_data_rec.schedule_ship_date;
      g_rpt_data_tab(ln_idx).arrival_date                 := l_data_rec.request_date;
      --時間指定(From)
      l_xatf_rec    := l_xat_rec;
      FOR xat_rec IN xat_cur(
                       iv_request_time      => l_data_rec.requested_time_from,
                       id_ordered_date      => l_data_rec.ordered_date
                     )
      LOOP
        l_xatf_rec  := xat_rec;
      END LOOP;
      --時間指定(To)
      l_xatt_rec    := l_xat_rec;
      FOR xat_rec IN xat_cur(
                       iv_request_time      => l_data_rec.requested_time_to,
                       id_ordered_date      => l_data_rec.ordered_date
                     )
      LOOP
        l_xatt_rec  := xat_rec;
      END LOOP;
      --時間指定
      IF ( ( TRIM( l_xatf_rec.description ) IS NULL )
        AND ( TRIM( l_xatt_rec.description ) IS NULL ) )
      THEN
        g_rpt_data_tab(ln_idx).requested_time             := NULL;
      ELSE
        g_rpt_data_tab(ln_idx).requested_time             := LPAD(
                                                               NVL( TRIM( l_xatf_rec.description ), cv_space ),
                                                               5
                                                             ) || cv_hyphen || TRIM( l_xatt_rec.description );
      END IF;
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--      g_rpt_data_tab(ln_idx).delivery_code                := l_data_rec.delivery_to_code;
      g_rpt_data_tab(ln_idx).delivery_code                := SUBSTRB( l_data_rec.delivery_to_code, 1, 9 );
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
      g_rpt_data_tab(ln_idx).deliver_to_name              := SUBSTRB( l_data_rec.delivery_to_name, 1, 60 );
      g_rpt_data_tab(ln_idx).delivery_address             := SUBSTRB(
                                                               l_data_rec.delivery_to_state ||
                                                               l_data_rec.delivery_to_city ||
                                                               l_data_rec.delivery_to_address1 ||
                                                               l_data_rec.delivery_to_address2,
                                                               1, 60
                                                             );
      g_rpt_data_tab(ln_idx).telephone_no                 := SUBSTRB( l_data_rec.delivery_to_tel, 1, 15 );
      g_rpt_data_tab(ln_idx).description                  := SUBSTRB( l_data_rec.shipping_instructions, 1, 80 );
      g_rpt_data_tab(ln_idx).order_line_number            := l_data_rec.line_number;
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD START ************************ --
--      g_rpt_data_tab(ln_idx).item_code                    := l_data_rec.item_code;
--      g_rpt_data_tab(ln_idx).item_name                    := l_data_rec.description;
      g_rpt_data_tab(ln_idx).item_code                    := SUBSTRB( l_data_rec.item_code, 1, 7 );
      g_rpt_data_tab(ln_idx).item_name                    := SUBSTRB( l_data_rec.description, 1, 40 );
-- ************************ 2009/10/01 S.Miyakoshi Var1.6 MOD  END  ************************ --
      g_rpt_data_tab(ln_idx).content                      := l_data_rec.conversion_rate;
      g_rpt_data_tab(ln_idx).shipment_quantity            := l_data_rec.ordered_quantity;
      g_rpt_data_tab(ln_idx).shipment_uom                 := l_data_rec.order_quantity_uom;
      g_rpt_data_tab(ln_idx).remarks_column               := l_data_rec.remark;
      g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
      g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
      g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
      g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
      g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
      g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
      g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
      g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
      g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
      --
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
      IF( gt_output_code = cv_output_code_01 ) THEN
        g_rpt_data_tab(ln_idx).dlv_contractor_info        := SUBSTRB(gt_dlv_cont_name || cv_space_char || gt_dlv_cont_address,1,160);
      ELSE
        g_rpt_data_tab(ln_idx).dlv_contractor_info        := NULL;
      END IF;
      g_rpt_data_tab(ln_idx).output_code                  := gt_output_code;
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
    END LOOP loop_get_data;
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --対象件数
      gn_target_cnt           := g_rpt_data_tab.COUNT;
    END IF;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-3)
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    --==================================
    -- 1.出荷依頼書帳票ワークテーブル登録処理
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT --SAVE EXCEPTIONS
        INSERT INTO
          xxcos_rep_deli_req
        VALUES
          g_rpt_data_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- 正常件数
    gn_normal_cnt             := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : ＳＶＦ起動(A-4)
   ***********************************************************************************/
  PROCEDURE execute_svf(
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
    iv_sort_key   IN VARCHAR2,      -- 出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_api_name      VARCHAR2(5000);
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
    lv_vrq_file      VARCHAR2(100);   -- クエリー様式ファイル名
-- 2014/11/14 Ver.1.9 Add K.Oomata End
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
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
    --==================================
    -- クエリー様式ファイル名の設定
    --==================================
    -- 出力順優先項目：0 出荷元保管場所優先  の場合
    IF ( iv_sort_key = cv_sort_key_0 ) THEN
      lv_vrq_file := cv_vrq_file;
    -- 出力順優先項目：1：伝票No.優先  の場合
    ELSE
      lv_vrq_file := cv_vrq_file1;
    END IF;
-- 2014/11/14 Ver.1.9 Add K.Oomata End
    --==================================
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg             := xxccp_common_pkg.get_msg(
                                   iv_application          => ct_xxcos_appl_short_name,
                                   iv_name                 => ct_msg_nodata_err
                                 );
    --出力ファイル編集
    lv_file_name              := cv_file_id ||
                                   TO_CHAR( SYSDATE, cv_fmt_date8 ) ||
                                   TO_CHAR( cn_request_id ) ||
                                   cv_extension_pdf
                                 ;
    --==================================
    -- 2.SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_file_id,
      iv_output_mode          => cv_output_mode_pdf,
      iv_frm_file             => cv_frm_file,
-- 2014/11/14 Ver.1.9 Mod K.Oomata Start
--      iv_vrq_file             => cv_vrq_file,
      iv_vrq_file             => lv_vrq_file,
-- 2014/11/14 Ver.1.9 Mod K.Oomata End
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
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt THEN
      lv_api_name             := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END execute_svf;
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
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
        xrdr.record_id        record_id
      FROM
        xxcos_rep_deli_req    xrdr                    --出荷依頼書帳票ワークテーブル
      WHERE
        xrdr.request_id       = cn_request_id         --要求ID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.帳票ワークテーブルデータロック
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.帳票ワークテーブル削除
    --==================================
    BEGIN
      DELETE FROM
        xxcos_rep_deli_req    xrdr
      WHERE
        xrdr.request_id       = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --要求ID文字列取得
        lv_key_info           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_request,
                                   iv_token_name1        => cv_tkn_request,
                                   iv_token_value1       => TO_CHAR( cn_request_id )
                                 );
        --
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_key_info
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
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
    iv_ship_from_subinv_code  IN      VARCHAR2,       -- 1.出荷元倉庫
    iv_ordered_date_from      IN      VARCHAR2,       -- 2.受注日（From）
    iv_ordered_date_to        IN      VARCHAR2,       -- 3.受注日（To）
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
    iv_output_code            IN      VARCHAR2,       -- 4.出力区分
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
    iv_sort_key               IN      VARCHAR2,          -- 5.出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
    iv_international_csv      IN      VARCHAR2,          -- 6.国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
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
/* 2009/06/22 Ver1.4 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
/* 2009/06/22 Ver1.4 Add End   */

--
--###########################  固定部 END   ####################################
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
    gn_warn_cnt               := 0;
--
    -- ===============================
    -- A-0  初期処理
    -- ===============================
    init(
      iv_ship_from_subinv_code  => iv_ship_from_subinv_code,    -- 1.出荷元倉庫
      iv_ordered_date_from      => iv_ordered_date_from,        -- 2.受注日（From）
      iv_ordered_date_to        => iv_ordered_date_to,          -- 3.受注日（To）
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
      iv_output_code            => iv_output_code,              -- 4.出力区分
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
      iv_sort_key               => iv_sort_key,                 -- 5.出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
      iv_international_csv      => iv_international_csv,        -- 6.国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1  パラメータチェック処理
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  データ取得
    -- ===============================
    get_data(
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
      iv_international_csv      => iv_international_csv,        -- 国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  帳票ワークテーブル登録
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-4  ＳＶＦ起動
    -- ===============================
    execute_svf(
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
      iv_sort_key               => iv_sort_key,                 -- 出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
--
/* 2009/06/22 Ver1.4 Mod Start */
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/22 Ver1.4 Mod End   */
--
    -- ===============================
    -- A-3  帳票ワークテーブル削除
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf,                   -- エラー・メッセージ
      ov_retcode                => lv_retcode,                  -- リターン・コード
      ov_errmsg                 => lv_errmsg                    -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
/* 2009/06/22 Ver1.4 Add Start */
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/22 Ver1.4 Add End   */
--
    --明細０件時の警告終了制御
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_ship_from_subinv_code  IN      VARCHAR2,       -- 1.出荷元倉庫
    iv_ordered_date_from      IN      VARCHAR2,       -- 2.受注日（From）
-- 2013/03/26 Ver.1.7 Mod T.Ishiwata Start
--    iv_ordered_date_to        IN      VARCHAR2        -- 3.受注日（To）
    iv_ordered_date_to        IN      VARCHAR2,         -- 3.受注日（To）
-- 2014/11/14 Ver.1.9 Mod K.Oomata Start
--    iv_output_code            IN      VARCHAR2          -- 4.出力区分
---- 2013/03/26 Ver.1.7 Mod T.Ishiwata End
    iv_output_code            IN      VARCHAR2,          -- 4.出力区分
    iv_sort_key               IN      VARCHAR2,          -- 5.出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
    iv_international_csv      IN      VARCHAR2           -- 6.国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Mod K.Oomata End
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
      iv_which    => cv_log_header_log,
      ov_retcode  => lv_retcode,
      ov_errbuf   => lv_errbuf,
      ov_errmsg   => lv_errmsg
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
      iv_ship_from_subinv_code,          -- 1.出荷元倉庫
      iv_ordered_date_from,              -- 2.受注日（From）
      iv_ordered_date_to,                -- 3.受注日（To）
-- 2013/03/26 Ver.1.7 Add T.Ishiwata Start
      iv_output_code,                    -- 4.出力区分
-- 2013/03/26 Ver.1.7 Add T.Ishiwata End
-- 2014/11/14 Ver.1.9 Add K.Oomata Start
      iv_sort_key,                       -- 5.出力順優先項目(0：出荷元保管場所優先、1：伝票No.優先)
      iv_international_csv,              -- 6.国際CSV出力(Y：国際CSVを対象とする、N：国際CSVを対象としない)
-- 2014/11/14 Ver.1.9 Add K.Oomata End
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => NULL
    );
    --対象件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_skip_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => NULL
    );
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error) THEN
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
END XXCOS006A04R;
/
