CREATE OR REPLACE PACKAGE BODY APPS.XXCSO015A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A02C(body)
 * Description      : 作業依頼／発注情報(iPro,PO)を自販機管理システムに連携するために、
 *                    CSVファイルを作成します。
 * MD.050           : MD050_自販機-EBSインタフェース：（OUT）作業依頼／発注情報(iPro,PO)
 *                    2008/12/19 16:30
 * Version          : 1.35
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_csv_file          作業依頼／発注情報CSVファイルオープン (A-2)
 *  get_ipro_po_related_data 作業依頼／発注情報関連マスタ情報抽出 (A-4)
 *  update_wk_requisition_proc 作業依頼／発注情報連携対象テーブル更新 (A-6)
 *  create_csv_rec         作業依頼／発注情報CSV出力 (A-7)
 *  close_csv_file         CSVファイルクローズ処理   (A-8)
 *  submain                メイン処理プロシージャ
 *                           作業依頼／発注情報データ抽出 (A-3)
 *                           セーブポイント設定 (A-5)
 *                           作業依頼／発注情報連携対象テーブル削除 (A-9)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-20    1.0   kyo              新規作成
 *  2008-03-03    1.1   K.Satomura       結合障害対応(不具合ＩＤ43,44)
 *                                       ・CSVファイル残存エラーのSQLERRMを削除
 *                                       ・CSV出力レイアウトに「Ａ寸法」を追加
 *  2009-03-10          K.Satomura       結合障害対応(不具合ＩＤ51)
 *                                       ・現設置先顧客情報の取得条件を修正
 *  2009-04-02    1.2   K.Satomura       ＳＴ障害対応(T1_0169対応)
 *  2009-04-06    1.3   D.Abe            ＳＴ障害対応(T1_0306対応)
 *  2009-04-10    1.4   K.Satomura       ＳＴ障害対応(T1_0408,0492対応)
 *  2009-04-30    1.5   K.Satomura       ＳＴ障害対応(T1_0517対応)
 *  2009-05-01    1.6   Tomoko.Mori      T1_0897対応
 *  2009-05-19    1.7   K.Satomura       ＳＴ障害対応(T1_1048対応)
 *  2009-05-21    1.8   M.Maruyama       ＳＴ障害対応(T1_1093対応)
 *  2009-05-22    1.9   K.Satomura       ＳＴ障害対応(T1_1142対応)
 *  2009-05-22    1.10  K.Satomura       ＳＴ障害対応(T1_1152対応)
 *  2009-05-27    1.11  M.Maruyama       ＳＴ障害対応(T1_1218対応)
 *  2009-07-09    1.12  D.Abe            SCS障害対応(0000465対応)
 *  2009-08-05    1.13  K.Satomura       SCS障害対応(0000778対応)
 *  2009-08-10    1.14  K.Satomura       SCS障害対応(0000662対応)
 *  2009-09-04    1.15  D.Abe            SCS障害対応(0001281対応)
 *  2009-09-15    1.16  D.Abe            SCS障害対応(0001358対応)
 *  2009-09-25    1.17  D.Abe            共通課題IE534
 *  2009-11-27    1.18  K.Satomura       E_本稼動_00121対応
 *  2009-12-01    1.19  K.Satomura       E_本稼動_00264対応 依頼日時を固定値で出力する暫定対応
 *  2009-12-05    1.20  Daisuke.Abe      E_本稼動_00334対応
 *  2009-12-14    1.21  T.Maruyama       E_本稼動_00469対応 顧客名称、顧客住所について禁則文字
 *                                       が存在する場合は、該当文字を変換して連携する
 *  2009-12-21    1.22  K.Hosoi          E_本稼動_00563対応
 *  2010-02-01    1.23  T.Maruyama       E_本稼動_01018 電話番号１～３が6バイトを超える場合は
 *                                                      6バイトで切捨てする
 *  2010-02-17    1.24  T.Maruyama       E_本稼動_01603
 *  2010-03-08    1.25  K.Hosoi          E_本稼動_01838対応
 *  2010-04-05    1.26  T.Yoshimoto      E_本稼動_02102対応
 *  2010-05-10    1.26  D.Abe            E_本稼動_02598対応
 *  2011-02-02    1.28  N.Horigome       E_本稼動_02369対応
 *  2011-06-23    1.29  K.Kiriu          E_本稼動_07712対応
 *  2011-07-01    1.30  K.Kiriu          E_本稼動_07712対応(対応変更分)
 *  2011-07-08    1.31  K.Kiriu          E_本稼動_07712対応(担当営業取得変更)
 *  2012-09-28    1.32  K.Taniguchi      E_本稼動_09604対応(担当営業取得変更)
 *  2014-05-16    1.33  Y.Shoji          E_本稼動_11853対応(連携項目：リース区分追加)
 *  2015-06-03    1.34  K.Kiriu          E_本稼動_12984対応(自販機の付帯機器管理に関する改修)
 *  2015-07-27    1.35  K.Kiriu          E_本稼動_13237対応(自販機の付帯機器管理に関する改修追加対応)
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO015A02C';      -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  -- メッセージコード
  cv_tkn_number_01        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_02        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラー
  cv_tkn_number_03        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー
  cv_tkn_number_04        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00154';  -- ロックエラー
  cv_tkn_number_05        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- 作業依頼／発注情報抽出エラー
  cv_tkn_number_06        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00049';  -- 関連マスタ整合性エラー
  cv_tkn_number_07        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00053';  -- 関連マスタ抽出エラー
  cv_tkn_number_08        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00159';  -- 禁則文字チェックエラー
  cv_tkn_number_09        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00153';  -- 更新失敗エラー
  cv_tkn_number_10        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00228';  -- 正常連携
  cv_tkn_number_11        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00045';  -- CSVファイル出力エラー
  cv_tkn_number_12        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラー
  cv_tkn_number_13        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00119';  -- データ削除エラー
  cv_tkn_number_14        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  cv_tkn_number_15        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インターフェースファイル名
  cv_tkn_number_16        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_17        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件エラーメッセージ
  /* 2009.05.22 K.Satomura T1_1142対応 START */
  cv_tkn_number_18        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00570';  -- 電話番号桁数エラー
  /* 2009.05.22 K.Satomura T1_1142対応 END */
  /* 2010.03.08 K.Hosoi E_本稼動_01838対応 START */
  cv_tkn_number_19        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- 参照タイプなしエラーメッセージ
  /* 2010.03.08 K.Hosoi E_本稼動_01838対応 END */
--
  -- トークンコード
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc          CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_csv_fnm          CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_po_num           CONSTANT VARCHAR2(20) := 'PO_NUM';
  cv_tkn_po_line_num      CONSTANT VARCHAR2(20) := 'PO_LINE_NUM';
  cv_tkn_reqst_num        CONSTANT VARCHAR2(20) := 'REQUISITION_NUM';
  cv_tkn_reqst_line_num   CONSTANT VARCHAR2(20) := 'REQUISITION_LINE_NUM';
  cv_tkn_po_distr_num     CONSTANT VARCHAR2(20) := 'PO_DISTRIBUTION_NUM';
  cv_tkn_task_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_item_value       CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
  cv_tkn_check_range      CONSTANT VARCHAR2(20) := 'CHECK_RANGE';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  /* 2009.05.22 K.Satomura T1_1142対応 START */
  cv_tkn_new_old          CONSTANT VARCHAR2(20) := 'NEW_OLD';
  cv_tkn_phone_num        CONSTANT VARCHAR2(20) := 'PHONE_NUM';
  /* 2009.05.22 K.Satomura T1_1142対応 END */
  /* 2010.03.08 K.Hosoi E_本稼動_01838対応 START */
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  /* 2010.03.08 K.Hosoi E_本稼動_01838対応 END */
--
  -- 作業区分
  cn_work_kbn1            CONSTANT NUMBER       := 1;                -- 新台設置
  cn_work_kbn2            CONSTANT NUMBER       := 2;                -- 旧台設置
  cn_work_kbn3            CONSTANT NUMBER       := 3;                -- 新台代替
  cn_work_kbn4            CONSTANT NUMBER       := 4;                -- 旧台代替
  cn_work_kbn5            CONSTANT NUMBER       := 5;                -- 引揚
  cn_work_kbn6            CONSTANT NUMBER       := 6;                -- 店内移動
--
  cb_true                 CONSTANT BOOLEAN      := TRUE;
  cv_zenspace             CONSTANT VARCHAR2(5)  := '　';
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_csv_nm     = ';
  /* 2011-7-08 K.Kiriu E_本稼動_07712対応 MOD START */
--  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_wdrw_base_code = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'ln_org_id     = ';
  /* 2011-7-08 K.Kiriu E_本稼動_07712対応 MOD END */
  cv_debug_msg9           CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg10          CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
--
  /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
  cv_phone_num            CONSTANT VARCHAR2(6)   := '999999';
  /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */

  /* 2011.02.02 N.Horigome E_本稼動_02369対応 START */
  cv_sep_com              CONSTANT VARCHAR2(1)  := ',';
  /* 2011.02.02 N.Horigome E_本稼動_02369対応 END */
  /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
  cv_format_date          CONSTANT VARCHAR2(8)  := 'YYYYMMDD'; -- 日付フォーマット(YYYYMDDD)
  cv_format_time          CONSTANT VARCHAR2(6)  := 'HH24MI';   -- 日付フォーマット(HH24MI)
  cv_one                  CONSTANT VARCHAR2(1)  := '1';        -- 汎用固定値「1」
  cv_two                  CONSTANT VARCHAR2(1)  := '2';        -- 汎用固定値「2」
  cv_yes                  CONSTANT VARCHAR2(1)  := 'Y';        -- 汎用固定値「Y」
  cv_no                   CONSTANT VARCHAR2(1)  := 'N';        -- 汎用固定値「N」
  /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
  gt_company_code_base    xxcso_requisition_lines_v.work_company_code%TYPE;   -- 作業会社CD
  gt_location_code_base   xxcso_requisition_lines_v.work_location_code%TYPE;  -- 作業会社事業所CD
  /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
--
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  -- ロールバックフラグ
  gb_rollback_upd_flg           BOOLEAN := FALSE;                    -- TRUE : ロールバック
--
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
     slip_branch_no          NUMBER                                                    -- 伝票枝番
    ,job_kbn                 NUMBER                                                    -- 作業区分
    ,install_code1           csi_item_instances.external_reference%TYPE                -- 物件コード１
    ,vendor_mode1            po_un_numbers_vl.un_number%TYPE                           -- 機種名１
    ,vendor_number1          csi_item_instances.attribute2%TYPE                        -- 機番１
    ,install_code2           csi_item_instances.external_reference%TYPE                -- 物件コード２
    ,vendor_mode2            csi_item_instances.attribute1%TYPE                        -- 機種名２
    ,vendor_number2          csi_item_instances.attribute2%TYPE                        -- 機番２
    ,requisition_route       VARCHAR2(1)                                               -- 依頼ルート
    ,sale_base_code          xxcso_cust_acct_sites_v.sale_base_code%TYPE               -- 売上拠点コード
    ,reqst_base_code         xxcso_cust_acct_sites_v.sale_base_code%TYPE               -- 依頼部署
    ,employee_number         xxcso_employees_v.employee_number%TYPE                    -- 担当営業員コード
    ,reqst_date              VARCHAR2(8)                                               -- 依頼日
    ,reqst_time              VARCHAR2(4)                                               -- 依頼時間
    ,work_company_code       xxcso_requisition_lines_v.work_company_code%TYPE          -- 作業会社コード
    ,work_location_code      xxcso_requisition_lines_v.work_location_code%TYPE         -- 事業所コード
    ,work_locatn_tel1        VARCHAR2(6)                                               -- 事業所電話１
    ,work_locatn_tel2        VARCHAR2(6)                                               -- 事業所電話２
    ,work_locatn_tel3        VARCHAR2(6)                                               -- 事業所電話３
    ,work_hope_day_type      VARCHAR2(1)                                               -- 作業希望日区分
    ,work_hope_day           xxcso_requisition_lines_v.work_hope_day%TYPE              -- 作業希望日
    ,work_hope_time_type     xxcso_requisition_lines_v.work_hope_time_type%TYPE        -- 作業希望時間区分
    ,work_hope_time          VARCHAR2(4)                                               -- 作業希望時間
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    --,cur_organization_name   xxcso_cust_acct_sites_v.cur_organization_name%TYPE        -- 現設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --,cur_organization_name   xxcso_cust_acct_sites_v.party_name%TYPE                   -- 現設置先名
    ,cur_organization_name   VARCHAR2(4000)                                            -- 現設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --,cur_full_name           VARCHAR2(100)                                             -- 現設置先担当者氏名
    ,cur_full_name           VARCHAR2(4000)                                            -- 現設置先担当者氏名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.04.10 K.Satomura T1_0492対応 START */
    --,cur_phone_number1       VARCHAR2(6)                                               -- 現設置先電話１
    --,cur_phone_number2       VARCHAR2(6)                                               -- 現設置先電話２
    --,cur_phone_number3       VARCHAR2(6)                                               -- 現設置先電話３
    ,cur_phone_number1       VARCHAR2(100)                                               -- 現設置先電話１
    ,cur_phone_number2       VARCHAR2(100)                                               -- 現設置先電話２
    ,cur_phone_number3       VARCHAR2(100)                                               -- 現設置先電話３
    /* 2009.04.10 K.Satomura T1_0492対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --,cur_postal_code         xxcso_cust_acct_sites_v.postal_code%TYPE                  -- 現設置先郵便番号
    --,cur_est_site_adress1    xxcso_cust_acct_sites_v.state%TYPE                        -- 現設置先住所１
    --,cur_est_site_adress2    xxcso_cust_acct_sites_v.city%TYPE                         -- 現設置先住所２
    --,cur_est_site_adress3    xxcso_cust_acct_sites_v.address1%TYPE                     -- 現設置先住所３
    --,cur_est_site_adress4    xxcso_cust_acct_sites_v.address2%TYPE                     -- 現設置先住所４
    ,cur_postal_code         VARCHAR2(4000)                                              -- 現設置先郵便番号
    ,cur_est_site_adress1    VARCHAR2(4000)                                              -- 現設置先住所１
    ,cur_est_site_adress2    VARCHAR2(4000)                                              -- 現設置先住所２
    ,cur_est_site_adress3    VARCHAR2(4000)                                              -- 現設置先住所３
    ,cur_est_site_adress4    VARCHAR2(4000)                                              -- 現設置先住所４
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    ,cur_est_site_adress5    VARCHAR2(20)                                              -- 現設置先住所５
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    --,new_organization_name   xxcso_cust_acct_sites_v.organization_name_phonetic%TYPE   -- 新設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --,new_organization_name   xxcso_cust_acct_sites_v.party_name%TYPE                   -- 新設置先名
    ,new_organization_name   VARCHAR2(4000)                                            -- 新設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --,new_full_name           VARCHAR2(100)                                             -- 新設置先担当者氏名
    ,new_full_name           VARCHAR2(4000)                                             -- 新設置先担当者氏名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.04.10 K.Satomura T1_0492対応 START */
    --,new_phone_number1       VARCHAR2(6)                                               -- 新設置先電話１
    --,new_phone_number2       VARCHAR2(6)                                               -- 新設置先電話２
    --,new_phone_number3       VARCHAR2(6)                                               -- 新設置先電話３
    ,new_phone_number1       VARCHAR2(100)                                               -- 新設置先電話１
    ,new_phone_number2       VARCHAR2(100)                                               -- 新設置先電話２
    ,new_phone_number3       VARCHAR2(100)                                               -- 新設置先電話３
    /* 2009.04.10 K.Satomura T1_0492対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --,new_postal_code         xxcso_cust_acct_sites_v.postal_code%TYPE                  -- 新設置先郵便番号
    --,new_est_site_adress1    xxcso_cust_acct_sites_v.state%TYPE                        -- 新設置先住所１
    --,new_est_site_adress2    xxcso_cust_acct_sites_v.city%TYPE                         -- 新設置先住所２
    --,new_est_site_adress3    xxcso_cust_acct_sites_v.address1%TYPE                     -- 新設置先住所３
    --,new_est_site_adress4    xxcso_cust_acct_sites_v.address2%TYPE                     -- 新設置先住所４
    ,new_postal_code         VARCHAR2(4000)                                              -- 新設置先郵便番号
    ,new_est_site_adress1    VARCHAR2(4000)                                              -- 新設置先住所１
    ,new_est_site_adress2    VARCHAR2(4000)                                              -- 新設置先住所２
    ,new_est_site_adress3    VARCHAR2(4000)                                              -- 新設置先住所３
    ,new_est_site_adress4    VARCHAR2(4000)                                              -- 新設置先住所４
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    ,new_est_site_adress5    VARCHAR2(20)                                              -- 新設置先住所５
    ,withdraw_company_code   xxcso_requisition_lines_v.withdraw_company_code%TYPE      -- 引揚会社コード
    ,withdraw_location_code  xxcso_requisition_lines_v.withdraw_location_code%TYPE     -- 引揚事業所コード
    ,withdraw_process_kbn    VARCHAR2(1)                                               -- 引揚機処理区分
    ,preview_type            xxcso_requisition_lines_v.preview_type%TYPE               -- 下見区分
    ,install_place_type      xxcso_requisition_lines_v.install_place_type%TYPE         -- 設置場所区分
    ,install_place_floor     xxcso_requisition_lines_v.install_place_floor%TYPE        -- 設置場所階数
    ,install_fall_preventn   xxcso_requisition_lines_v.install_fall_prevention%TYPE    -- 設置転倒防止
    ,install_step_type       xxcso_requisition_lines_v.install_step_type%TYPE          -- 設置段差区分
    ,install_inct_type       xxcso_requisition_lines_v.install_inclination_type%TYPE   -- 設置傾斜区分
    ,electric_cost_type      xxcso_requisition_lines_v.electric_construction_type%TYPE -- 電気工事区分
    ,installed_side_type     xxcso_requisition_lines_v.installed_side_type%TYPE        -- 据付面区分
    ,import_step_type        xxcso_requisition_lines_v.import_step_type%TYPE           -- 搬入段差区分
    ,raising_type            xxcso_requisition_lines_v.raising_type%TYPE               -- 手上げ区分
    ,stairs_lift_type        xxcso_requisition_lines_v.stairs_lift_type%TYPE           -- 階段昇降機区分
    ,elevator_kbn            VARCHAR2(1)                                               -- エレベータ区分
    ,elevator_frontage       xxcso_requisition_lines_v.elevator_frontage%TYPE          -- エレベータ間口
    ,elevator_depth          xxcso_requisition_lines_v.elevator_depth%TYPE             -- エレベータ奥行き
    ,unic_type               xxcso_requisition_lines_v.unic_type%TYPE                  -- ユニック区分
    ,remarks                 VARCHAR2(720)                                             -- 備考
    ,creation_date           VARCHAR2(16)                                              -- 作成日時時分秒
    ,last_update_date        VARCHAR2(16)                                              -- 更新日時時分秒
    ,po_header_num           NUMBER                                                    -- 発注番号
    ,po_line_num             NUMBER                                                    -- 発注明細番号
    ,po_distribution_num     NUMBER                                                    -- 発注搬送番号
    ,req_header_num          NUMBER                                                    -- 発注依頼番号
    ,req_line_num            NUMBER                                                    -- 発注依頼明細番号
    ,new_customer_code1      VARCHAR2(9)                                               -- 顧客コード１（新設置先）
    ,cur_customer_code2      VARCHAR2(9)                                               -- 顧客コード２（現設置先）
    ,un_number_id            NUMBER                                                    -- 機種ID
    ,requisition_line_id     NUMBER                                                    -- 発注依頼明細ID
    ,created_by              NUMBER                                                    -- 作成者
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
    ,lease_kbn               VARCHAR2(1)                                               -- リース区分
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    ,install_type            VARCHAR2(1)                                               -- 物件タイプ
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
  );
  /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
  TYPE g_higher_emp_ttype    IS TABLE OF xxcso_employees_v.employee_number%TYPE INDEX BY VARCHAR2( 4 );
  gt_higher_emp_tab          g_higher_emp_ttype;                                       -- 最上位従業員
  /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
--
  -- *** ユーザー定義グローバル例外 ***
  global_skip_expt           EXCEPTION;
  global_lock_expt           EXCEPTION;                              -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate           OUT DATE                 -- システム日付
    ,od_process_date      OUT NOCOPY DATE          -- 業務処理日付
    ,ov_csv_dir           OUT NOCOPY VARCHAR2      -- CSVファイル出力先
    ,ov_csv_nm            OUT NOCOPY VARCHAR2      -- CSVファイル名
    ,ov_wdrw_base_code    OUT NOCOPY VARCHAR2      -- 引揚拠点コード
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    ,on_org_id            OUT NOCOPY NUMBER        -- 営業単位
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
    ,ov_errbuf            OUT NOCOPY VARCHAR2      -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2      -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル名
    -- XXCSO:自販機管理システム連携用CSVファイル出力先
    cv_csv_dir         CONSTANT VARCHAR2(30)   := 'XXCSO1_VM_OUT_CSV_DIR';
    -- XXCSO: 自販機管理システム連携用CSVファイル名(作業依頼/発注情報)
    cv_csv_nm          CONSTANT VARCHAR2(30)   := 'XXCSO1_VM_OUT_CSV_IPRO_OR_PO';
    -- XXCSO: 引揚拠点コード
    cv_wdrw_base_code  CONSTANT VARCHAR(30)    := 'XXCSO1_WITHDRAW_BASE_CODE';
    -- アプリケーション短縮名
    cv_appl_short_name CONSTANT VARCHAR2(10)   := 'XXCCP';
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    -- プロファイル MO:営業単位
    cv_prf_org_id      CONSTANT VARCHAR2(6)    := 'ORG_ID';
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値
    lv_csv_dir                VARCHAR2(2000);             -- CSVファイル出力先
    lv_csv_nm                 VARCHAR2(2000);             -- CSVファイル名
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--    lv_wdrw_base_code         VARCHAR2(2000);             -- 引揚拠点コード
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    ln_org_id                 VARCHAR2(2000);             -- 営業単位
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
    lv_noprm_msg              VARCHAR2(5000);  -- コンカレント入力パラメータなしメッセージ格納用
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value              VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg                    VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =================================
    -- 入力パラメータなしメッセージ出力 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name           --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_14             --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- 業務処理日付取得に失敗した場合
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_16             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- ====================
    -- 変数初期化処理 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    cv_csv_dir
                   ,lv_csv_dir
                   ); -- CSVファイル出力先
    FND_PROFILE.GET(
                    cv_csv_nm
                   ,lv_csv_nm
                   ); -- CSVファイル名
    /* 2009.09.15 D.Abe 0001358対応 START */
    --FND_PROFILE.GET(
    --                cv_wdrw_base_code
    --               ,lv_wdrw_base_code
    --               ); -- 引揚拠点コード
    /* 2009.09.15 D.Abe 0001358対応 END   */
/* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    FND_PROFILE.GET(
                    cv_prf_org_id
                   ,ln_org_id
                   ); -- 営業単位
/* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10)           ||
                 cv_debug_msg6  || lv_csv_dir        || CHR(10) ||
                 cv_debug_msg7  || lv_csv_nm         || CHR(10) ||
                 /* 2009.09.15 D.Abe 0001358対応 START */
                 --cv_debug_msg8  || lv_wdrw_base_code || CHR(10) ||
                 /* 2009.09.15 D.Abe 0001358対応 END   */
                 /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
                 cv_debug_msg8  || ln_org_id         || CHR(10) ||
                 /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
                 ''
    );
--
    -- 取得したCSVファイル名をメッセージ出力する
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name           --アプリケーション短縮名
                ,iv_name         => cv_tkn_number_15      --メッセージコード
                ,iv_token_name1  => cv_tkn_csv_fnm        --トークンコード1
                ,iv_token_value1 => lv_csv_nm             --トークン値1
              );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                   -- 空行の挿入
    );
--
    -- プロファイル値取得に失敗した場合
    -- CSVファイル出力先取得失敗時
    IF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_csv_dir;
    -- CSVファイル名取得失敗時
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_csv_nm;
    -- 引揚拠点コード
    /* 2009.09.15 D.Abe 0001358対応 START */
    --ELSIF (lv_wdrw_base_code IS NULL) THEN
    --  lv_tkn_value := cv_wdrw_base_code;
    /* 2009.09.15 D.Abe 0001358対応 END   */
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    -- 営業単位
    ELSIF ( ln_org_id IS NULL ) THEN
      lv_tkn_value := cv_prf_org_id;
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_csv_dir          :=  lv_csv_dir;          -- CSVファイル出力先
    ov_csv_nm           :=  lv_csv_nm;           -- CSVファイル名
    /* 2009.09.15 D.Abe 0001358対応 START */
    --ov_wdrw_base_code   :=  lv_wdrw_base_code;   -- 引揚拠点コード
    /* 2009.09.15 D.Abe 0001358対応 END   */
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    on_org_id           := TO_NUMBER( ln_org_id );  --営業単位
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : 作業依頼/発注情報CSVファイルオープン(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm         IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- プログラム名
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
    cv_w            CONSTANT VARCHAR2(1) := 'w';
--
    -- *** ローカル変数 ***
    -- ファイル存在チェック戻り値用
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                    ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                    ,iv_token_value1 => iv_csv_dir                   --トークン値1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                    ,iv_token_value2 => iv_csv_nm                    --トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                         location   => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                        /* 2009.08.05 K.Satomura 0000778対応 START */
                        ,max_linesize => 3000
                        /* 2009.08.05 K.Satomura 0000778対応 END */
                      );
      -- *** DEBUG_LOG ***
      -- ファイルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg9    || CHR(10)   ||
                   cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03     --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc       --トークンコード1
                      ,iv_token_value1 => iv_csv_dir           --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --トークンコード2
                      ,iv_token_value2 => iv_csv_nm            --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_ipro_po_related_data
   * Description      : 作業依頼/発注情報の関連顧客、物件情報抽出処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_ipro_po_related_data(
     io_get_data_rec         IN OUT NOCOPY g_get_data_rtype -- 作業依頼/発注情報
    ,id_process_date         IN     DATE                    -- 業務処理日付
    ,iv_wdrw_base_code       IN     VARCHAR2                -- 引揚拠点コード
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    ,iv_org_id               IN     NUMBER                  -- 営業単位
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'get_ipro_po_related_data';  -- プログラム名
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
    cv_no              CONSTANT VARCHAR2(1)   := 'N';
    cv_hyphen          CONSTANT VARCHAR2(1)   := '-';
    cv_syozoku_mst     CONSTANT VARCHAR2(30)  := 'XXCSO1_SYOZOKU_MST';
    cv_vm_type_cd      CONSTANT VARCHAR2(30)  := '1';               -- 自動販売機タイプコード    
    /* 2009.05.21 M.Maruyama T1_1093対応 START */
    cv_adddrss_chr     CONSTANT VARCHAR2(2)   := '＊';              -- 新・現設置左記住所4NULL値置換用文字
    /* 2009.05.21 M.Maruyama T1_1093対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    cv_astrsk          CONSTANT VARCHAR2(2)   := '＊';              -- 新・現設置先担当者名がNULLの場合設定
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    -- 抽出内容名
    cv_un_numbers_tl   CONSTANT VARCHAR2(100) := '国連番号マスタビュー(機種マスタビュー)の機種名';
    cv_install1_info   CONSTANT VARCHAR2(100) := 'インストールベースマスタの設置用物件情報';
    cv_install2_info   CONSTANT VARCHAR2(100) := 'インストールベースマスタの引揚用物件情報';
    cv_account1_info   CONSTANT VARCHAR2(100) := '顧客マスタサイトビューの新設置先顧客情報';
    cv_account2_info   CONSTANT VARCHAR2(100) := '顧客マスタサイトビューの現設置先顧客情報';
    cv_salebase_info   CONSTANT VARCHAR2(100) := '顧客マスタビューの売上拠点コード';
   /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del START */
--    cv_emplbase_info   CONSTANT VARCHAR2(100) := '従業員マスタビューの勤務地拠点コード';
   /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del END */
    cv_syozokum_info   CONSTANT VARCHAR2(100) := '所属マスタの事業所電話番号';
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    cv_temp_info       CONSTANT VARCHAR2(100) := '情報テンプレートの顧客関連情報';
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Mod START */
--    /* 2009.08.10 K.Satomura 0000662対応 START */
--    cv_new_eigyoin_info CONSTANT VARCHAR2(100) := '新設置先顧客担当営業員';
--    cv_now_eigyoin_info CONSTANT VARCHAR2(100) := '現設置先顧客担当営業員';
--    /* 2009.08.10 K.Satomura 0000662対応 END */
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--    cv_account_emp_info CONSTANT VARCHAR2(100) := '営業員担当顧客ビューの従業員番号';
    cv_account_emp_info    CONSTANT VARCHAR2(100) := '最上位の従業員番号';
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Mod END */
    /* 2009.05.22 K.Satomura T1_1142対応 START */
    cn_phone_num_max_legth CONSTANT NUMBER        := 6; -- 電話番号最大桁数
    cv_phone_old           CONSTANT VARCHAR2(100) := '現設置先';
    cv_phone_new           CONSTANT VARCHAR2(100) := '新設置先';
    /* 2009.05.22 K.Satomura T1_1142対応 END */
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
    cv_lease_kbn_info      CONSTANT VARCHAR2(100) := '購買依頼のリース区分';
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
    /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
    cv_cust_name_size  CONSTANT NUMBER := 40; --設置先名連携桁数
    cv_cust_add1_size  CONSTANT NUMBER := 8;  --設置先住所１連携桁数
    cv_cust_add2_size  CONSTANT NUMBER := 20; --設置先住所２連携桁数
    cv_cust_add3_size  CONSTANT NUMBER := 20; --設置先住所３連携桁数
    cv_cust_add4_size  CONSTANT NUMBER := 40; --設置先住所４連携桁数
    /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    cv_full_name_size      CONSTANT NUMBER := 20; --設置先担当者名連携桁数
    cv_inst_at_cstmr_nm    CONSTANT VARCHAR2(100) :=  'INSTALL_AT_CUSTOMER_NAME';   -- 設置先顧客名
    cv_inst_at_zp          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ZIP';             -- 設置先_郵便番号
    cv_inst_at_prfcturs    CONSTANT VARCHAR2(100) :=  'INSTALL_AT_PREFECTURES';     -- 設置先都道府県
    cv_inst_at_cty         CONSTANT VARCHAR2(100) :=  'INSTALL_AT_CITY';            -- 設置先市区
    cv_inst_at_addr1       CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ADDR1';           -- 設置先住所１
    cv_inst_at_addr2       CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ADDR2';           -- 設置先住所２
    cv_inst_at_phn         CONSTANT VARCHAR2(100) :=  'INSTALL_AT_PHONE';           -- 設置先電話番号
    cv_inst_at_emply_nm    CONSTANT VARCHAR2(100) :=  'INSTALL_AT_EMPLOYEE_NAME';   -- 設置先担当者名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2010.03.08 K.Hosoi E_本稼動_01838対応 START */
    cv_yes                    CONSTANT VARCHAR2(1)   :=  'Y';
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
    cv_lease_type          CONSTANT VARCHAR2(10)  := 'LEASE_TYPE';
    cv_xxcs01_lease_kbn    CONSTANT VARCHAR2(16)  := 'XXCSO1_LEASE_KBN';
    cv_lease_kbn           CONSTANT VARCHAR2(9)   := 'LEASE_KBN';
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
    -- プロファイル名
    -- XXCSO:作業依頼IF作業会社自動設定フラグ
    cv_wkcmp_auto_flg         CONSTANT VARCHAR2(100) :=  'XXCSO1_WKCMP_AUTO_FLG';
    -- XXCSO:自拠点作業時作業会社CD
    cv_zikyoten_wkcmp_full_cd CONSTANT VARCHAR2(100) :=  'XXCSO1_ZIKYOTEN_WKCMP_FULL_CD';
    -- 参照タイプ
    cv_wkcmp_auto_mst         CONSTANT VARCHAR2(100) :=  'XXCSO1_WKCMP_AUTO_MST';
    -- 参照タイプなしエラーメッセージ用トークン値
    cv_tkn_value_task_name    CONSTANT VARCHAR2(100) :=  '作業依頼IF自動設定作業会社マスタの';
    /* 2010.03.08 K.Hosoi E_本稼動_01838対応 END */
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    --最上位従業員取得用
    cv_category_employee      CONSTANT VARCHAR2(8)   :=  'EMPLOYEE';
    cv_resource_group_number  CONSTANT VARCHAR2(15)  :=  'RS_GROUP_MEMBER';
    cv_person_type            CONSTANT VARCHAR2( 3)  :=  'EMP';
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
--
    -- *** ローカル変数 ***
    lv_instance_type_code      VARCHAR2(30);            -- インスタンスタイプコード
    -- 取得データ格納用
    ln_job_kbn                 NUMBER;                                                  -- 作業区分
    lv_install_code1           csi_item_instances.external_reference%TYPE;              -- 物件コード１
    lv_vendor_mode1            po_un_numbers_vl.un_number%TYPE;                         -- 機種名１
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
    lv_lease_kbn               VARCHAR2(1);                                             -- リース区分
    lv_lease_kbn_un_numbers    VARCHAR2(1);                                             -- リース区分（機種マスタ）
    lv_lease_kbn_csi_item      VARCHAR2(1);                                             -- リース区分（物件マスタ）
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
    lv_vendor_number1          csi_item_instances.attribute2%TYPE;                      -- 機番１
    lv_install_code2           csi_item_instances.external_reference%TYPE;              -- 物件コード２
    lv_vendor_mode2            csi_item_instances.attribute1%TYPE;                      -- 機種名２
    lv_vendor_number2          csi_item_instances.attribute2%TYPE;                      -- 機番２
    lv_sale_base_code          xxcso_cust_acct_sites_v.sale_base_code%TYPE;             -- 売上拠点コード
    lv_reqst_base_code         xxcso_cust_acct_sites_v.sale_base_code%TYPE;             -- 依頼部署
    lv_work_locatn_tel1        VARCHAR2(6);                                             -- 事業所電話１
    lv_work_locatn_tel2        VARCHAR2(6);                                             -- 事業所電話２
    lv_work_locatn_tel3        VARCHAR2(6);                                             -- 事業所電話３
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    --lv_cur_organization_name   xxcso_cust_acct_sites_v.organization_name_phonetic%TYPE; -- 現設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_cur_organization_name   xxcso_cust_acct_sites_v.party_name%TYPE;                 -- 現設置先名
    lv_cur_organization_name   VARCHAR2(4000);                                          -- 現設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_cur_full_name           VARCHAR2(100);                                            -- 現設置先担当者氏名
    lv_cur_full_name           VARCHAR2(4000);                                            -- 現設置先担当者氏名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    /* 2009.04.10 K.Satomura T1_0492対応 START */
    --lv_cur_phone_number1       VARCHAR2(6);                                             -- 現設置先電話１
    --lv_cur_phone_number2       VARCHAR2(6);                                             -- 現設置先電話２
    --lv_cur_phone_number3       VARCHAR2(6);                                             -- 現設置先電話３
    lv_cur_phone_number1       VARCHAR2(100);                                             -- 現設置先電話１
    lv_cur_phone_number2       VARCHAR2(100);                                             -- 現設置先電話２
    lv_cur_phone_number3       VARCHAR2(100);                                             -- 現設置先電話３
    /* 2009.04.10 K.Satomura T1_0492対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_cur_postal_code         xxcso_cust_acct_sites_v.postal_code%TYPE;                -- 現設置先郵便番号
    --lv_cur_est_site_adress1    xxcso_cust_acct_sites_v.state%TYPE;                      -- 現設置先住所１
    --lv_cur_est_site_adress2    xxcso_cust_acct_sites_v.city%TYPE;                       -- 現設置先住所２
    --lv_cur_est_site_adress3    xxcso_cust_acct_sites_v.address1%TYPE;                   -- 現設置先住所３
    --lv_cur_est_site_adress4    xxcso_cust_acct_sites_v.address2%TYPE;                   -- 現設置先住所４
    lv_cur_postal_code         VARCHAR2(4000);                                            -- 現設置先郵便番号
    lv_cur_est_site_adress1    VARCHAR2(4000);                                            -- 現設置先住所１
    lv_cur_est_site_adress2    VARCHAR2(4000);                                            -- 現設置先住所２
    lv_cur_est_site_adress3    VARCHAR2(4000);                                            -- 現設置先住所３
    lv_cur_est_site_adress4    VARCHAR2(4000);                                            -- 現設置先住所４
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    --lv_new_organization_name   xxcso_cust_acct_sites_v.organization_name_phonetic%TYPE; -- 新設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_new_organization_name   xxcso_cust_acct_sites_v.party_name%TYPE;                 -- 新設置先名
    lv_new_organization_name   VARCHAR2(4000);                                          -- 新設置先名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_new_full_name           VARCHAR2(100);                                             -- 新設置先担当者氏名
    lv_new_full_name           VARCHAR2(4000);                                            -- 新設置先担当者氏名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.04.10 K.Satomura T1_0492対応 START */
    --lv_new_phone_number1       VARCHAR2(6);                                             -- 新設置先電話１
    --lv_new_phone_number2       VARCHAR2(6);                                             -- 新設置先電話２
    --lv_new_phone_number3       VARCHAR2(6);                                             -- 新設置先電話３
    lv_new_phone_number1       VARCHAR2(100);                                             -- 新設置先電話１
    lv_new_phone_number2       VARCHAR2(100);                                             -- 新設置先電話２
    lv_new_phone_number3       VARCHAR2(100);                                             -- 新設置先電話３
    /* 2009.04.10 K.Satomura T1_0492対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_new_postal_code         xxcso_cust_acct_sites_v.postal_code%TYPE;                -- 新設置先郵便番号
    --lv_new_est_site_adress1    xxcso_cust_acct_sites_v.state%TYPE;                      -- 新設置先住所１
    --lv_new_est_site_adress2    xxcso_cust_acct_sites_v.city%TYPE;                       -- 新設置先住所２
    --lv_new_est_site_adress3    xxcso_cust_acct_sites_v.address1%TYPE;                   -- 新設置先住所３
    --lv_new_est_site_adress4    xxcso_cust_acct_sites_v.address2%TYPE;                   -- 新設置先住所４
    lv_new_postal_code         VARCHAR2(4000);                                            -- 新設置先郵便番号
    lv_new_est_site_adress1    VARCHAR2(4000);                                            -- 新設置先住所１
    lv_new_est_site_adress2    VARCHAR2(4000);                                            -- 新設置先住所２
    lv_new_est_site_adress3    VARCHAR2(4000);                                            -- 新設置先住所３
    lv_new_est_site_adress4    VARCHAR2(4000);                                            -- 新設置先住所４
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    lv_new_customer_code1      xxcso_requisition_lines_v.install_at_customer_code%TYPE; -- 顧客コード１（新設置先）
    lv_cur_customer_code2      xxcso_cust_acct_sites_v.account_number%TYPE;             -- 顧客コード２（現設置先）
    lv_work_company_code       xxcso_requisition_lines_v.work_company_code%TYPE;        -- 作業会社コード
    lv_work_location_code      xxcso_requisition_lines_v.work_location_code%TYPE;       -- 事業所コード
    ln_un_number_id            NUMBER;                  -- 機種ID
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del START */
--    ln_created_by              NUMBER;                  -- 作成者
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del END */
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
    lt_empoyee_number          xxcso_employees_v.employee_number%TYPE;                  -- 設置先顧客売上拠点の最上位従業員
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--    lt_emp_customer_code       xxcso_cust_acct_sites_v.account_number%TYPE;             -- 顧客コード(顧客営業担当取得用)
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
    /* 2009.04.10 K.Satomura T1_0492対応 START */
    --lv_cur_phone_number        VARCHAR2(20);            -- 編集用電話番号
    --lv_new_phone_number        VARCHAR2(20);            -- 編集用電話番号
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    --lv_cur_phone_number        xxcso_cust_acct_sites_v.phone_number%TYPE; -- 編集用電話番号
    --lv_new_phone_number        xxcso_cust_acct_sites_v.phone_number%TYPE; -- 編集用電話番号
    lv_cur_phone_number        VARCHAR2(4000);                                            -- 編集用電話番号
    lv_new_phone_number        VARCHAR2(4000);                                            -- 編集用電話番号
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.04.10 K.Satomura T1_0492対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    lt_inst_at_cust_name       xxcso_requisition_lines_v.install_at_customer_name%TYPE; -- 設置先顧客名
    lt_inst_at_zip             xxcso_requisition_lines_v.install_at_zip%TYPE;           -- 設置先_郵便番号
    lt_inst_at_prfcturs        xxcso_requisition_lines_v.install_at_prefectures%TYPE;   -- 設置先都道府県
    lt_inst_at_city            xxcso_requisition_lines_v.install_at_city%TYPE;          -- 設置先市区
    lt_inst_at_addr1           xxcso_requisition_lines_v.install_at_addr1%TYPE;         -- 設置先住所１
    lt_inst_at_addr2           xxcso_requisition_lines_v.install_at_add2%TYPE;          -- 設置先住所２
    lt_inst_at_phone           xxcso_requisition_lines_v.install_at_phone%TYPE;         -- 設置先電話番号
    lt_inst_at_emp_name        xxcso_requisition_lines_v.install_at_employee_name%TYPE; -- 設置先担当者名
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2010.03.08 K.Hosoi E_本稼動_01838対応 START */
    -- プロファイル値取得戻り値
    lv_wkcmp_at_flg            VARCHAR2(2000);
    lv_zktn_wkcmp_fll_cd       VARCHAR2(2000);
    --
    lv_sale_base_code2         xxcso_cust_acct_sites_v.sale_base_code%TYPE;             -- 売上拠点コード
    /* 2010.03.08 K.Hosoi E_本稼動_01838対応 END */
    /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
    ld_reqst_date              DATE;                                             -- 依頼日
    /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
    lv_code                    VARCHAR2(20);            -- 編集用参照コード
    ld_date                    DATE;                    -- 業務処理日付格納用('yyyymmdd'形式)
    lv_log_po_head_num         VARCHAR2(20);            -- ログ用発注番号
    lv_log_po_line_num         VARCHAR2(20);            -- ログ用発注明細番号
    lv_log_po_dist_num         VARCHAR2(20);            -- ログ用発注搬送番号
    lv_log_rq_head_num         VARCHAR2(20);            -- ログ用発注依頼番号
    lv_log_rq_line_num         VARCHAR2(20);            -- ログ用発注依頼明細番号
    ln_num1                    NUMBER;                  -- 1回目のハイフンの位置
    ln_num2                    NUMBER;                  -- 2回目のハイフンの位置
/* 2012-09-28 K.Taniguchi E_本稼動_09604対応 Mod START */
--/* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
--    -- *** ローカル・カーソル ***
--    -- 拠点最上位従業員取得
--    CURSOR
--      cur_employee_number(
--         iv_sale_base_code  VARCHAR2  -- 売上拠点
--        ,id_target_date     DATE      -- 依頼日
--      )
--    IS
--    SELECT papf.employee_number  AS employee_number   --従業員番号
--    FROM   per_person_types          ppt              --従業員タイプ
--          ,per_periods_of_service    ppos             --従業員サービス
--          ,per_all_assignments_f     paaf             --アサイメント
--          ,per_all_people_f          papf             --従業員
--          ,jtf_rs_resource_extns     jrre             --リソース
--          ,jtf_rs_group_members      jrgm             --グループメンバー
--          ,jtf_rs_groups_b           jrgb             --リソースグループ
--          ,jtf_rs_role_relations     jrrr             --役割
--          ,jtf_rs_salesreps          jrs              --営業担当
--    WHERE jrgb.attribute1              = iv_sale_base_code
--    AND   jrgb.group_id                = jrgm.group_id
--    AND   jrgm.delete_flag             = cv_no
--    AND   jrgm.resource_id             = jrre.resource_id
--    AND   jrre.category                = cv_category_employee
--    AND   jrrr.role_resource_id        = jrgm.group_member_id
--    AND   jrrr.role_resource_type      = cv_resource_group_number
--    AND   jrrr.delete_flag             = cv_no
--    AND   jrrr.start_date_active      <= id_target_date
--    AND   NVL( jrrr.end_date_active, id_target_date ) >= id_target_date
--    AND   jrre.source_id               = papf.person_id
--    AND   papf.person_id               = paaf.person_id
--    AND   paaf.period_of_service_id    = ppos.period_of_service_id
--    AND   ppos.actual_termination_date IS NULL
--    AND   papf.person_type_id          = ppt.person_type_id
--    AND   id_target_date BETWEEN papf.effective_start_date
--                             AND papf.effective_end_date
--    AND   ppt.system_person_type       = cv_person_type
--    AND   ppt.active_flag              = cv_yes
--    AND   jrre.resource_id             = jrs.resource_id
--    AND   jrs.org_id                   = iv_org_id
--    AND    TRUNC( jrs.start_date_active ) <= id_target_date
--    AND    TRUNC( NVL( jrs.end_date_active, id_target_date ) )
--                                          >= id_target_date
--    ORDER BY
--          paaf.ass_attribute11   -- 職位順
--         ,ppos.date_start        -- 入社日
--         ,papf.employee_number   -- 従業員番号
--    ;
--
    -- *** ローカル・カーソル ***
    -- 拠点最上位従業員取得
    CURSOR
      cur_employee_number(
         iv_sale_base_code  VARCHAR2  -- 売上拠点
      )
    IS
      SELECT  papf.employee_number    AS employee_number        -- 従業員番号
      FROM    per_all_assignments_f   paaf                      -- アサイメント
             ,per_all_people_f        papf                      -- 従業員
             ,per_periods_of_service  ppos                      -- 従業員サービス
      WHERE   papf.attribute28             = iv_sale_base_code  -- 拠点コード
      AND     paaf.person_id               = papf.person_id     -- 従業員ID
      AND     paaf.period_of_service_id    = ppos.period_of_service_id  -- ｻｰﾋﾞｽ期間ID
      AND     ppos.actual_termination_date IS NULL              -- 退職者でない
      ORDER BY
              paaf.ass_attribute11   -- 職位順
             ,ppos.date_start        -- 入社日
             ,papf.employee_number   -- 従業員番号
    ;
--/* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
/* 2012-09-28 K.Taniguchi E_本稼動_09604対応 Mod END */
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- 業務処理日付を'yyyymmdd'形式で格納
  ld_date                := TRUNC(id_process_date);
  -- 作業区分
  ln_job_kbn             := io_get_data_rec.job_kbn;
  -- 物件コード１
  lv_install_code1       := io_get_data_rec.install_code1;
  -- 機種ID
  ln_un_number_id        := io_get_data_rec.un_number_id;
  -- 物件コード２
  lv_install_code2       := io_get_data_rec.install_code2;
  /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del START */
--  -- 作成者
--  ln_created_by          := io_get_data_rec.created_by;
  /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del END */
  -- 作業会社コード
  lv_work_company_code   := io_get_data_rec.work_company_code;
  -- 事業所コード
  lv_work_location_code  := io_get_data_rec.work_location_code;
  -- 顧客コード１（新設置先）
  lv_new_customer_code1  := io_get_data_rec.new_customer_code1;
  /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
  -- 依頼日
  ld_reqst_date          := TO_DATE(io_get_data_rec.reqst_date,'YYYYMMDD');
  /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
  -- ログ用発注番号
  lv_log_po_head_num     := TO_CHAR(io_get_data_rec.po_header_num);
  -- ログ用発注明細番号
  lv_log_po_line_num     := TO_CHAR(io_get_data_rec.po_line_num);
  -- ログ用発注搬送番号
  lv_log_po_dist_num     := TO_CHAR(io_get_data_rec.po_distribution_num);
  -- ログ用発注依頼番号
  lv_log_rq_head_num     := TO_CHAR(io_get_data_rec.req_header_num);
  -- ログ用発注依頼明細番号
  lv_log_rq_line_num     := TO_CHAR(io_get_data_rec.req_line_num);
  /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
  lt_empoyee_number      := NULL;
  /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
  /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
  -- リース区分
  lv_lease_kbn           := io_get_data_rec.lease_kbn;
  /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
--
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    -- =================
    -- 顧客関連情報
    -- =================
    --発注依頼明細情報ビューの不備により、設置先住所２が取得できないが、ビューの改修による他への影響が大きい為、
    --ビューは修正せず関数により直接情報テンプレートの値を取得する。
    BEGIN
      SELECT xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_cstmr_nm)   -- 設置先顧客名
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_zp)         -- 設置先_郵便番号
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_prfcturs)   -- 設置先都道府県
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_cty)        -- 設置先市区
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_addr1)      -- 設置先住所１
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_addr2)      -- 設置先住所２
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_phn)        -- 設置先電話番号
            ,xxcso_ipro_common_pkg.get_temp_info(io_get_data_rec.requisition_line_id,cv_inst_at_emply_nm)   -- 設置先担当者名
      INTO   lt_inst_at_cust_name
            ,lt_inst_at_zip
            ,lt_inst_at_prfcturs
            ,lt_inst_at_city
            ,lt_inst_at_addr1
            ,lt_inst_at_addr2
            ,lt_inst_at_phone
            ,lt_inst_at_emp_name
      FROM  DUAL
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_temp_info                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                       ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                       ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                       ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                       ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                       ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                       ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                       ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                       ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                       ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_temp_info                 -- トークン値1
                       ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                       ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                       ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                       ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                       ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                       ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                       ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                       ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                       ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                       ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       ,iv_token_name7  => cv_tkn_errmsg                -- トークンコード7
                       ,iv_token_value7 => SQLERRM                      -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    -- =================
    -- 設置用物件情報
    -- =================
--
    -- 作業区分が新台設置、新台代替時
    IF (ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn3) THEN
      BEGIN
        /* 2010.04.05 1.26 T.Yoshimoto E_本稼動_02102対応 Mod START */
        --SELECT punvl.un_number
        --INTO   lv_vendor_mode1
        --FROM   po_un_numbers_vl punvl
        --WHERE  punvl.un_number_id = ln_un_number_id
--
        SELECT punv.un_number
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,punv.attribute13        -- リース区分
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        INTO   lv_vendor_mode1
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,lv_lease_kbn_un_numbers
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        FROM   po_headers ph
              ,po_lines pl
              ,po_un_numbers_vl punv
        WHERE  pl.po_header_id   = ph.po_header_id
        AND    punv.un_number_id = pl.un_number_id
        AND    ph.segment1       = TO_CHAR(io_get_data_rec.po_header_num) --発注番号
        AND    pl.line_num       = io_get_data_rec.po_line_num            --発注明細番号
        /* 2010.04.05 1.26 T.Yoshimoto E_本稼動_02102対応 Mod END */
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_un_numbers_tl             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_un_numbers_tl             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg                -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
      -- 発注配送のリース区分がNULLの場合
      IF lv_lease_kbn IS NULL THEN
        -- 機種マスタのリース区分を取得
        lv_lease_kbn := lv_lease_kbn_un_numbers;
--
        -- 機種マスタのリース区分がNULLの場合
        IF lv_lease_kbn IS NULL THEN
          BEGIN
            -- 購買依頼からリース区分を取得 ※参照タイプ「リース区分（物件）」のコード値を取得
            SELECT flvv.lookup_code
            INTO   lv_lease_kbn
            FROM   apps.fnd_lookup_values_vl       flvv
                  ,icx.por_template_info           pti
                  ,apps.por_template_attributes_v  ptav
            WHERE  flvv.attribute1                             =  pti.attribute_value
            AND    pti.attribute_code                          =  ptav.attribute_code
            AND    flvv.lookup_type                            =  cv_xxcs01_lease_kbn
            AND    TRUNC(NVL(flvv.start_date_active, ld_date)) <= ld_date
            AND    TRUNC(NVL(flvv.end_date_active, ld_date))   >= ld_date
            AND    flvv.enabled_flag                           =  cv_yes
            AND    pti.requisition_line_id                     =  io_get_data_rec.requisition_line_id
            AND    ptav.attribute_name                         =  cv_lease_type
            AND    ptav.node_display_flag                      =  cv_yes
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                  -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_07             -- メッセージコード
                             ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                             ,iv_token_value1 => cv_lease_kbn_info            -- トークン値1
                             ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                             ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                             ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                             ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                             ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                             ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                             ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                             ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                             ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                             ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                             ,iv_token_name7  => cv_tkn_errmsg                -- トークンコード7
                             ,iv_token_value7 => SQLERRM                      -- トークン値7
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        END IF;
      END IF;
      /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
    END IF;
--
    -- 作業区分が旧台設置、旧台代替、店内移動時
    IF (ln_job_kbn = cn_work_kbn2 
         OR ln_job_kbn = cn_work_kbn4
         OR ln_job_kbn = cn_work_kbn6) THEN
      BEGIN
        SELECT ciins.external_reference
              ,ciins.attribute1
              ,ciins.attribute2
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,xxcso_ib_common_pkg.get_ib_ext_attribs(ciins.instance_id,cv_lease_kbn)
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        INTO   lv_install_code1
              ,lv_vendor_mode1
              ,lv_vendor_number1
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,lv_lease_kbn
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        FROM   csi_item_instances ciins
        WHERE  ciins.external_reference = lv_install_code1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_install1_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_install1_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg                -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF; 
--       
    -- ================
    -- 引揚用物件情報
    -- ================
--
    -- 作業区分が旧台代替、旧台代替、引揚時
    IF (ln_job_kbn = cn_work_kbn3 
         OR ln_job_kbn = cn_work_kbn4
         OR ln_job_kbn = cn_work_kbn5) THEN
      BEGIN
        SELECT ciins.external_reference
              ,ciins.attribute1
              ,ciins.attribute2
              ,ciins.instance_type_code
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,xxcso_ib_common_pkg.get_ib_ext_attribs(ciins.instance_id,cv_lease_kbn)
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        INTO   lv_install_code2
              ,lv_vendor_mode2
              ,lv_vendor_number2
              ,lv_instance_type_code
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,lv_lease_kbn_csi_item
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        FROM   csi_item_instances ciins
        WHERE  ciins.external_reference = lv_install_code2
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_install2_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_install2_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg                -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
      -- 引揚の場合
      IF (ln_job_kbn = cn_work_kbn5) THEN
        -- リース区分を取得
        lv_lease_kbn := lv_lease_kbn_csi_item;
      END IF;
      /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
    END IF;  
--
    -- 作業区分が新台設置、旧台設置時
    IF (ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn2) THEN
      -- ================
      -- 現設置先顧客情報
      -- ================
      -- なし
--
      -- ================
      -- 新設置先顧客情報
      -- ================
      BEGIN
        SELECT casv.sale_base_code
              ,casv.sale_base_code
              /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
              --,casv.organization_name_phonetic
              ,casv.party_name
              /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,empv.last_name || cv_zenspace || empv.first_name
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,casv.phone_number
              ,casv.postal_code
              ,casv.state
              ,casv.city
              ,casv.address1
              /* 2009.05.22 K.Satomura T1_1152対応 START */
              --,casv.address2
              ,NVL(casv.address2, cv_adddrss_chr)
              /* 2009.05.22 K.Satomura T1_1152対応 END */
        INTO   lv_sale_base_code
              ,lv_reqst_base_code
              ,lv_new_organization_name
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,lv_new_full_name
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,lv_new_phone_number
              ,lv_new_postal_code
              ,lv_new_est_site_adress1
              ,lv_new_est_site_adress2
              ,lv_new_est_site_adress3
              ,lv_new_est_site_adress4
        FROM   xxcso_cust_acct_sites_v casv
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,xxcso_employees_v       empv
              --,xxcso_cust_resources_v  crsv
              /* 2009.08.10 K.Satomura 0000662対応 END */
        WHERE  casv.account_number    = lv_new_customer_code1
          AND  casv.account_status    = 'A'
          AND  casv.acct_site_status  = 'A'
          AND  casv.party_status      = 'A'
          AND  casv.party_site_status = 'A'
          /* 2009.08.10 K.Satomura 0000662対応 START */
          --AND  casv.account_number    = crsv.account_number
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(crsv.start_date_active, ld_date)) 
          --           AND TRUNC(NVL(crsv.end_date_active, ld_date))
          ----AND  crsv.employee_number   = empv.employee_number
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.end_date, ld_date))
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.employee_start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.employee_end_date, ld_date))
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.assign_start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.assign_end_date, ld_date))
          /* 2009.08.10 K.Satomura 0000662対応 END */
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_account1_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_account1_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg                -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
      -- 情報テンプレートに設置先顧客名が存在する場合はそちらを設定
      IF (lt_inst_at_cust_name IS NOT NULL) THEN
        lv_new_organization_name := lt_inst_at_cust_name;
      END IF;
      --
      -- 情報テンプレートに設置先_郵便番号が存在する場合はそちらを設定
      IF (lt_inst_at_zip IS NOT NULL) THEN
        lv_new_postal_code := lt_inst_at_zip;
      END IF;
      --
      -- 情報テンプレートに設置先都道府県が存在する場合はそちらを設定
      IF (lt_inst_at_prfcturs IS NOT NULL) THEN
        lv_new_est_site_adress1 := lt_inst_at_prfcturs;
      END IF;
      --
      -- 情報テンプレートに設置先市区が存在する場合はそちらを設定
      IF (lt_inst_at_city IS NOT NULL) THEN
        lv_new_est_site_adress2 := lt_inst_at_city;
      END IF;
      --
      -- 情報テンプレートに設置先住所１が存在する場合はそちらを設定
      IF (lt_inst_at_addr1 IS NOT NULL) THEN
        lv_new_est_site_adress3 := lt_inst_at_addr1;
      END IF;
      --
      -- 情報テンプレートに設置先住所２が存在する場合はそちらを設定
      IF (lt_inst_at_addr2 IS NOT NULL) THEN
        lv_new_est_site_adress4 := lt_inst_at_addr2;
      END IF;
      --
      -- 情報テンプレートに設置先電話番号が存在する場合はそちらを設定
      IF (lt_inst_at_phone IS NOT NULL) THEN
        lv_new_phone_number := lt_inst_at_phone;
      END IF;
      --
      -- 情報テンプレートに設置先担当者名が存在する場合はそちらを設定、存在しなければ'＊'を設定
      IF (lt_inst_at_emp_name IS NOT NULL) THEN
        lv_new_full_name := lt_inst_at_emp_name;
      ELSE
        lv_new_full_name := cv_astrsk;
      END IF;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del START */
--      /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
--      -- 依頼部署の格納      
--      BEGIN
--        SELECT (
--                 CASE
--                   /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--                   --WHEN TO_DATE(xev.issue_date, 'yyyy/mm/dd') <= ld_date THEN
--                   WHEN TO_DATE(xev.issue_date, 'yyyy/mm/dd') <= ld_reqst_date THEN
--                   /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                     xev.work_base_code_new  -- 勤務地拠点コード(新)
--                   /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                   --WHEN TO_DATE(xev.issue_date, 'yyyy/mm/dd')  > ld_date THEN
--                   WHEN TO_DATE(xev.issue_date, 'yyyy/mm/dd')  > ld_reqst_date THEN
--                   /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                     xev.work_base_code_old  -- 勤務地拠点コード(旧)
--                   WHEN xev.issue_date IS NULL THEN
--                     xev.work_base_code_old  -- 勤務地拠点コード(旧)
--                 END
--               ) base_code
--        INTO   lv_reqst_base_code
--        FROM   xxcso_employees_v xev
--        WHERE  xev.user_id = ln_created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    ld_date BETWEEN TRUNC(NVL(xev.start_date, ld_date))
--        --                   AND TRUNC(NVL(xev.end_date, ld_date))
--        --AND    ld_date BETWEEN TRUNC(NVL(xev.employee_start_date, ld_date))
--        --                   AND TRUNC(NVL(xev.employee_end_date, ld_date))
--        --AND    ld_date BETWEEN TRUNC(NVL(xev.assign_start_date, ld_date))
--        --                   AND TRUNC(NVL(xev.assign_end_date, ld_date))
--        AND    ld_reqst_date BETWEEN TRUNC(NVL(xev.start_date, ld_reqst_date))
--                           AND TRUNC(NVL(xev.end_date, ld_reqst_date))
--        AND    ld_reqst_date BETWEEN TRUNC(NVL(xev.employee_start_date, ld_reqst_date))
--                           AND TRUNC(NVL(xev.employee_end_date, ld_reqst_date))
--        AND    ld_reqst_date BETWEEN TRUNC(NVL(xev.assign_start_date, ld_reqst_date))
--                           AND TRUNC(NVL(xev.assign_end_date, ld_reqst_date))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--        ;
--        --
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- データが存在しない場合
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name           -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_06      -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
--                         ,iv_token_value1 => cv_emplbase_info      -- トークン値1
--                         ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
--                         ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
--                         ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
--                         ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
--                         ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
--                         ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
--                         ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
--                         ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
--                         ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
--                         ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
--                       );
--          --
--          lv_errbuf := lv_errmsg;
--          RAISE global_skip_expt;
--          --
--          -- 抽出に失敗した場合
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name           -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_07      -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
--                         ,iv_token_value1 => cv_emplbase_info      -- トークン値1
--                         ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
--                         ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
--                         ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
--                         ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
--                         ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
--                         ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
--                         ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
--                         ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
--                         ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
--                         ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
--                         ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
--                         ,iv_token_value7 => SQLERRM               -- トークン値7
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--          --
--      END;
--      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
--      /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del END */
      /* 2009.08.10 K.Satomura 0000662対応 START */
      ---- ==================
      ---- 新設置先営業員情報
      ---- ==================
      --BEGIN
      --  SELECT xev.last_name || cv_zenspace || xev.first_name
      --  INTO   lv_new_full_name
      --  FROM   xxcso_cust_acct_sites_v xca
      --        ,xxcso_employees_v       xev
      --        ,xxcso_cust_resources_v  xcr
      --  WHERE  xca.account_number    = lv_new_customer_code1
      --  AND    xca.account_number    = xcr.account_number
      --  AND    ld_date BETWEEN TRUNC(NVL(xcr.start_date_active, ld_date))
      --  AND    TRUNC(NVL(xcr.end_date_active, ld_date))
      --  AND    xcr.employee_number   = xev.employee_number
      --  AND    ld_date BETWEEN TRUNC(NVL(xev.start_date, ld_date)) 
      --  AND    TRUNC(NVL(xev.end_date, ld_date))
      --  AND    ld_date BETWEEN TRUNC(NVL(xev.employee_start_date, ld_date)) 
      --  AND    TRUNC(NVL(xev.employee_end_date, ld_date))
      --  AND    ld_date BETWEEN TRUNC(NVL(xev.assign_start_date, ld_date))
      --  AND    TRUNC(NVL(xev.assign_end_date, ld_date))
      --  ;
      --  --
      --EXCEPTION
      --  WHEN NO_DATA_FOUND THEN
      --    -- データが存在しない場合
      --    BEGIN
      --      SELECT xev.last_name || cv_zenspace || xev.first_name
      --      INTO   lv_new_full_name
      --      FROM   xxcmm_cust_accounts xca
      --            ,xxcso_employees_v   xev
      --      WHERE  xca.customer_code        = lv_new_customer_code1
      --      AND    xca.cnvs_business_person = xev.employee_number
      --      /* 2009.09.04 D.Abe 0001281対応 START */
      --      AND    ld_date BETWEEN TRUNC(NVL(xev.start_date, ld_date)) 
      --      AND    TRUNC(NVL(xev.end_date, ld_date))
      --      AND    ld_date BETWEEN TRUNC(NVL(xev.employee_start_date, ld_date)) 
      --      AND    TRUNC(NVL(xev.employee_end_date, ld_date))
      --      AND    ld_date BETWEEN TRUNC(NVL(xev.assign_start_date, ld_date))
      --      AND    TRUNC(NVL(xev.assign_end_date, ld_date))
      --      /* 2009.09.04 D.Abe 0001281対応 END */
      --      ;
      --      --
      --    EXCEPTION
      --      WHEN NO_DATA_FOUND THEN
      --        lv_errmsg := xxccp_common_pkg.get_msg(
      --                        iv_application  => cv_app_name           -- アプリケーション短縮名
      --                       ,iv_name         => cv_tkn_number_06      -- メッセージコード
      --                       ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                       ,iv_token_value1 => cv_new_eigyoin_info   -- トークン値1
      --                       ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                       ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                       ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                       ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                       ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                       ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                       ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                       ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                       ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                       ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                     );
      --        --
      --        lv_errbuf := lv_errmsg;
      --        RAISE global_skip_expt;
      --        --
      --      WHEN OTHERS THEN
      --        -- 抽出に失敗した場合
      --        lv_errmsg := xxccp_common_pkg.get_msg(
      --                        iv_application  => cv_app_name           -- アプリケーション短縮名
      --                       ,iv_name         => cv_tkn_number_07      -- メッセージコード
      --                       ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                       ,iv_token_value1 => cv_new_eigyoin_info   -- トークン値1
      --                       ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                       ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                       ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                       ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                       ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                       ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                       ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                       ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                       ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                       ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                       ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
      --                       ,iv_token_value7 => SQLERRM               -- トークン値7
      --                     );
      --        --
      --        lv_errbuf := lv_errmsg;
      --        RAISE global_process_expt;
      --        --
      --    END;
      --    --
      --  WHEN OTHERS THEN
      --    -- 抽出に失敗した場合
      --    lv_errmsg := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_app_name           -- アプリケーション短縮名
      --                   ,iv_name         => cv_tkn_number_07      -- メッセージコード
      --                   ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                   ,iv_token_value1 => cv_new_eigyoin_info   -- トークン値1
      --                   ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                   ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                   ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                   ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                   ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                   ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                   ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                   ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                   ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                   ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                   ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
      --                   ,iv_token_value7 => SQLERRM               -- トークン値7
      --                 );
      --    --
      --    lv_errbuf := lv_errmsg;
      --    RAISE global_process_expt;
      --    --
      --END;
      --
      /* 2009.08.10 K.Satomura 0000662対応 END */
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
--      -- 顧客営業担当員取得用の顧客コード取得
--      lt_emp_customer_code := lv_new_customer_code1; --新設置先顧客コード
--      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
    END IF;
--    
    -- 作業区分が新台代替、旧台代替、引揚の時
    IF (ln_job_kbn = cn_work_kbn3 
          OR ln_job_kbn = cn_work_kbn4 OR ln_job_kbn = cn_work_kbn5) THEN
      -- ================
      -- 現設置先顧客情報
      -- ================
--
      -- 現設置先顧客情報
      BEGIN
        /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
        --SELECT casv.organization_name_phonetic
        SELECT casv.party_name
        /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,empv.last_name || cv_zenspace || empv.first_name
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,casv.phone_number
              ,casv.postal_code
              ,casv.state
              ,casv.city
              ,casv.address1
              /* 2009.05.22 K.Satomura T1_1152対応 START */
              --,casv.address2
              ,NVL(casv.address2, cv_adddrss_chr)
              /* 2009.05.22 K.Satomura T1_1152対応 END */
              /* 2009.04.10 K.Satomura T1_0408対応 START */
              ,casv.account_number
              /* 2009.04.10 K.Satomura T1_0408対応 END */
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
              ,casv.sale_base_code
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
        INTO   lv_cur_organization_name
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,lv_cur_full_name
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,lv_cur_phone_number
              ,lv_cur_postal_code
              ,lv_cur_est_site_adress1
              ,lv_cur_est_site_adress2
              ,lv_cur_est_site_adress3
              ,lv_cur_est_site_adress4
              /* 2009.04.10 K.Satomura T1_0408対応 START */
              ,lv_cur_customer_code2
              /* 2009.04.10 K.Satomura T1_0408対応 END */
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
              ,lv_reqst_base_code
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
        FROM   xxcso_cust_acct_sites_v casv
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,xxcso_employees_v       empv
              --,xxcso_cust_resources_v  crsv
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,csi_item_instances      cii
        WHERE  cii.external_reference     = lv_install_code2
          AND  cii.owner_party_account_id = casv.cust_account_id
          AND  casv.account_status        = 'A'
          AND  casv.acct_site_status      = 'A'
          AND  casv.party_status          = 'A'
          AND  casv.party_site_status     = 'A'
          /* 2009.08.10 K.Satomura 0000662対応 START */
          --AND  casv.account_number        = crsv.account_number
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(crsv.start_date_active, ld_date)) 
          --           AND TRUNC(NVL(crsv.end_date_active, ld_date))
          --AND  crsv.employee_number   = empv.employee_number
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.end_date, ld_date))
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.employee_start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.employee_end_date, ld_date))
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.assign_start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.assign_end_date, ld_date))
          /* 2009.08.10 K.Satomura 0000662対応 END */
        ;
--        
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_account2_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_account2_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
      -- 情報テンプレートに設置先顧客名が存在する場合はそちらを設定
      IF (lt_inst_at_cust_name IS NOT NULL) THEN
        lv_cur_organization_name := lt_inst_at_cust_name;
      END IF;
      --
      -- 情報テンプレートに設置先_郵便番号が存在する場合はそちらを設定
      IF (lt_inst_at_zip IS NOT NULL) THEN
        lv_cur_postal_code := lt_inst_at_zip;
      END IF;
      --
      -- 情報テンプレートに設置先都道府県が存在する場合はそちらを設定
      IF (lt_inst_at_prfcturs IS NOT NULL) THEN
        lv_cur_est_site_adress1 := lt_inst_at_prfcturs;
      END IF;
      --
      -- 情報テンプレートに設置先市区が存在する場合はそちらを設定
      IF (lt_inst_at_city IS NOT NULL) THEN
        lv_cur_est_site_adress2 := lt_inst_at_city;
      END IF;
      --
      -- 情報テンプレートに設置先住所１が存在する場合はそちらを設定
      IF (lt_inst_at_addr1 IS NOT NULL) THEN
        lv_cur_est_site_adress3 := lt_inst_at_addr1;
      END IF;
      --
      -- 情報テンプレートに設置先住所２が存在する場合はそちらを設定
      IF (lt_inst_at_addr2 IS NOT NULL) THEN
        lv_cur_est_site_adress4 := lt_inst_at_addr2;
      END IF;
      --
      -- 情報テンプレートに設置先電話番号が存在する場合はそちらを設定
      IF (lt_inst_at_phone IS NOT NULL) THEN
        lv_cur_phone_number := lt_inst_at_phone;
      END IF;
      --
      -- 情報テンプレートに設置先担当者名が存在する場合はそちらを設定、存在しなければ'＊'を設定
      IF (lt_inst_at_emp_name IS NOT NULL) THEN
        lv_cur_full_name := lt_inst_at_emp_name;
      ELSE
        lv_cur_full_name := cv_astrsk;
      END IF;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
--
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
      /* 2009.08.10 K.Satomura 0000662対応 START */
      ---- ==================
      ---- 現設置先営業員情報
      ---- ==================
      --BEGIN
      --  SELECT xev.last_name || cv_zenspace || xev.first_name
      --  INTO   lv_cur_full_name
      --  FROM   xxcso_cust_acct_sites_v xca
      --        ,xxcso_employees_v       xev
      --        ,xxcso_cust_resources_v  xcr
      --        ,csi_item_instances      cii
      --  WHERE  cii.external_reference     = lv_install_code2
      --  AND    cii.owner_party_account_id = xca.cust_account_id
      --  AND    xca.account_number         = xcr.account_number
      --  AND    ld_date BETWEEN TRUNC(NVL(xcr.start_date_active, ld_date))
      --  AND    TRUNC(NVL(xcr.end_date_active, ld_date))
      --  AND    xcr.employee_number   = xev.employee_number
      --  AND    ld_date BETWEEN TRUNC(NVL(xev.start_date, ld_date))
      --  AND    TRUNC(NVL(xev.end_date, ld_date))
      --  AND    ld_date BETWEEN TRUNC(NVL(xev.employee_start_date, ld_date))
      --  AND    TRUNC(NVL(xev.employee_end_date, ld_date))
      --  AND    ld_date BETWEEN TRUNC(NVL(xev.assign_start_date, ld_date))
      --  AND    TRUNC(NVL(xev.assign_end_date, ld_date))
      --  ;
      --  --
      --EXCEPTION
      --  WHEN NO_DATA_FOUND THEN
      --    -- データが存在しない場合
      --    BEGIN
      --      SELECT xev.last_name || cv_zenspace || xev.first_name
      --      INTO   lv_cur_full_name
      --      FROM   csi_item_instances      cii
      --            ,xxcso_cust_acct_sites_v cas
      --            ,xxcmm_cust_accounts     cac
      --            ,xxcso_employees_v       xev
      --      WHERE  cii.external_reference     = lv_install_code2
      --      AND    cii.owner_party_account_id = cas.cust_account_id
      --      AND    cas.account_number         = cac.customer_code
      --      AND    cac.cnvs_business_person   = xev.employee_number
      --      /* 2009.09.04 D.Abe 0001281対応 START */
      --      AND    ld_date BETWEEN TRUNC(NVL(xev.start_date, ld_date)) 
      --      AND    TRUNC(NVL(xev.end_date, ld_date))
      --      AND    ld_date BETWEEN TRUNC(NVL(xev.employee_start_date, ld_date)) 
      --      AND    TRUNC(NVL(xev.employee_end_date, ld_date))
      --      AND    ld_date BETWEEN TRUNC(NVL(xev.assign_start_date, ld_date))
      --      AND    TRUNC(NVL(xev.assign_end_date, ld_date))
      --      /* 2009.09.04 D.Abe 0001281対応 END */
      --      ;
      --      --
      --    EXCEPTION
      --      WHEN NO_DATA_FOUND THEN
      --        lv_errmsg := xxccp_common_pkg.get_msg(
      --                        iv_application  => cv_app_name           -- アプリケーション短縮名
      --                       ,iv_name         => cv_tkn_number_06      -- メッセージコード
      --                       ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                       ,iv_token_value1 => cv_now_eigyoin_info   -- トークン値1
      --                       ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                       ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                       ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                       ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                       ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                       ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                       ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                       ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                       ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                       ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                     );
      --        --
      --        lv_errbuf := lv_errmsg;
      --        RAISE global_skip_expt;
      --        --
      --      WHEN OTHERS THEN
      --        -- 抽出に失敗した場合
      --        lv_errmsg := xxccp_common_pkg.get_msg(
      --                        iv_application  => cv_app_name           -- アプリケーション短縮名
      --                       ,iv_name         => cv_tkn_number_07      -- メッセージコード
      --                       ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                       ,iv_token_value1 => cv_now_eigyoin_info   -- トークン値1
      --                       ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                       ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                       ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                       ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                       ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                       ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                       ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                       ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                       ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                       ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                       ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
      --                       ,iv_token_value7 => SQLERRM               -- トークン値7
      --                     );
      --        --
      --        lv_errbuf := lv_errmsg;
      --        RAISE global_process_expt;
      --        --
      --    END;
      --    --
      --  WHEN OTHERS THEN
      --    -- 抽出に失敗した場合
      --    lv_errmsg := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_app_name           -- アプリケーション短縮名
      --                   ,iv_name         => cv_tkn_number_07      -- メッセージコード
      --                   ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                   ,iv_token_value1 => cv_now_eigyoin_info   -- トークン値1
      --                   ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                   ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                   ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                   ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                   ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                   ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                   ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                   ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                   ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                   ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                   ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
      --                   ,iv_token_value7 => SQLERRM               -- トークン値7
      --                 );
      --    lv_errbuf := lv_errmsg;
      --    RAISE global_process_expt;
      --END;
      --
      /* 2009.08.10 K.Satomura 0000662対応 END */
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
--      -- 顧客営業担当員取得用の顧客コード取得
--      lt_emp_customer_code := lv_cur_customer_code2; --現設置先顧客コード(引揚の場合)
--      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      -- ================
      -- 新設置先顧客情報
      -- ================

      -- 作業区分が引揚ではない場合
      IF (ln_job_kbn <> cn_work_kbn5) THEN
        BEGIN
          /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
          --SELECT casv.organization_name_phonetic
          SELECT casv.party_name
          /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
                /* 2009.08.10 K.Satomura 0000662対応 START */
                --,empv.last_name || cv_zenspace || empv.first_name
                /* 2009.08.10 K.Satomura 0000662対応 END */
                ,casv.phone_number
                ,casv.postal_code
                ,casv.state
                ,casv.city
                ,casv.address1
                /* 2009.05.22 K.Satomura T1_1152対応 START */
                --,casv.address2
                ,NVL(casv.address2, cv_adddrss_chr)
                /* 2009.05.22 K.Satomura T1_1152対応 END */
                ,casv.account_number
                /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
                ,casv.sale_base_code
                /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
          INTO   lv_new_organization_name
                /* 2009.08.10 K.Satomura 0000662対応 START */
                --,lv_new_full_name
                /* 2009.08.10 K.Satomura 0000662対応 END */
                ,lv_new_phone_number
                ,lv_new_postal_code
                ,lv_new_est_site_adress1
                ,lv_new_est_site_adress2
                ,lv_new_est_site_adress3
                ,lv_new_est_site_adress4
                ,lv_new_customer_code1
                /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
                ,lv_reqst_base_code
                /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
          FROM   xxcso_cust_acct_sites_v casv
                ,csi_item_instances      ciins
                /* 2009.08.10 K.Satomura 0000662対応 START */
                --,xxcso_employees_v       empv
                --,xxcso_cust_resources_v  crsv
                /* 2009.08.10 K.Satomura 0000662対応 END */
          WHERE  ciins.external_reference = lv_install_code2
            AND  ciins.owner_party_account_id    = casv.cust_account_id
            AND  casv.account_status    = 'A'
            AND  casv.acct_site_status  = 'A'
            AND  casv.party_status      = 'A'
            AND  casv.party_site_status = 'A'
            /* 2009.08.10 K.Satomura 0000662対応 START */
            --AND  casv.account_number    = crsv.account_number
            --AND  ld_date 
            --       BETWEEN TRUNC(NVL(crsv.start_date_active, ld_date)) 
            --           AND TRUNC(NVL(crsv.end_date_active, ld_date))
            --AND  crsv.employee_number   = empv.employee_number
            --AND  ld_date 
            --       BETWEEN TRUNC(NVL(empv.start_date, ld_date)) 
            --           AND TRUNC(NVL(empv.end_date, ld_date))
            --AND  ld_date 
            --       BETWEEN TRUNC(NVL(empv.employee_start_date, ld_date)) 
            --           AND TRUNC(NVL(empv.employee_end_date, ld_date))
            --AND  ld_date 
            --       BETWEEN TRUNC(NVL(empv.assign_start_date, ld_date)) 
            --           AND TRUNC(NVL(empv.assign_end_date, ld_date))
            /* 2009.08.10 K.Satomura 0000662対応 END */
          ;
          -- 顧客コード１(新設置先)を格納
          io_get_data_rec.new_customer_code1 := lv_new_customer_code1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- データが存在しない場合
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_06             -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                           ,iv_token_value1 => cv_account1_info             -- トークン値1
                           ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                           ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                           ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                           ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                           ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                           ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                           ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                           ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                           ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                           ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_skip_expt;
            -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_07             -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                           ,iv_token_value1 => cv_account1_info             -- トークン値1
                           ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                           ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                           ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                           ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                           ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                           ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                           ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                           ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                           ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                           ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                           ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                           ,iv_token_value7 => SQLERRM                      -- トークン値7
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
        -- 情報テンプレートに設置先顧客名が存在する場合はそちらを設定
        IF (lt_inst_at_cust_name IS NOT NULL) THEN
          lv_new_organization_name := lt_inst_at_cust_name;
        END IF;
        --
        -- 情報テンプレートに設置先_郵便番号が存在する場合はそちらを設定
        IF (lt_inst_at_zip IS NOT NULL) THEN
          lv_new_postal_code := lt_inst_at_zip;
        END IF;
        --
        -- 情報テンプレートに設置先都道府県が存在する場合はそちらを設定
        IF (lt_inst_at_prfcturs IS NOT NULL) THEN
          lv_new_est_site_adress1 := lt_inst_at_prfcturs;
        END IF;
        --
        -- 情報テンプレートに設置先市区が存在する場合はそちらを設定
        IF (lt_inst_at_city IS NOT NULL) THEN
          lv_new_est_site_adress2 := lt_inst_at_city;
        END IF;
        --
        -- 情報テンプレートに設置先住所１が存在する場合はそちらを設定
        IF (lt_inst_at_addr1 IS NOT NULL) THEN
          lv_new_est_site_adress3 := lt_inst_at_addr1;
        END IF;
        --
        -- 情報テンプレートに設置先住所２が存在する場合はそちらを設定
        IF (lt_inst_at_addr2 IS NOT NULL) THEN
          lv_new_est_site_adress4 := lt_inst_at_addr2;
        END IF;
        --
        -- 情報テンプレートに設置先電話番号が存在する場合はそちらを設定
        IF (lt_inst_at_phone IS NOT NULL) THEN
          lv_new_phone_number := lt_inst_at_phone;
        END IF;
        /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
--
        /* 2009.08.10 K.Satomura 0000662対応 START */
        -- ==================
        -- 新設置先営業員情報
        -- ==================
        lv_new_full_name := lv_cur_full_name;
        --
        /* 2009.08.10 K.Satomura 0000662対応 END */
        -- 売上拠点コードの格納
        BEGIN
          SELECT casv.sale_base_code
          INTO   lv_sale_base_code
          FROM   xxcso_cust_accounts_v   casv
                ,csi_item_instances      ciins
          WHERE  ciins.external_reference = lv_install_code2
            AND  ciins.owner_party_account_id    = casv.cust_account_id
            AND  casv.account_status    = 'A'
            AND  casv.party_status      = 'A'
          ;
  --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- データが存在しない場合
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_06             -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                           ,iv_token_value1 => cv_salebase_info             -- トークン値1
                           ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                           ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                           ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                           ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                           ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                           ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                           ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                           ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                           ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                           ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_skip_expt;
            -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                  -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_07             -- メッセージコード
                           ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                           ,iv_token_value1 => cv_salebase_info             -- トークン値1
                           ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                           ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                           ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                           ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                           ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                           ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                           ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                           ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                           ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                           ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                           ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                           ,iv_token_value7 => SQLERRM                      -- トークン値7
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
--        -- 顧客営業担当員取得用の顧客コード取得
--        lt_emp_customer_code := lv_new_customer_code1; --新設置先顧客コード(引揚以外場合)
--        /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      END IF;
--
      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del START */
--      -- 依頼部署の格納
--      BEGIN
--        SELECT ( CASE
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--                 --WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
--                 WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd') <= ld_reqst_date THEN
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                   empv.work_base_code_new  -- 勤務地拠点コード(新)
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--                 --WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
--                 WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd')  > ld_reqst_date THEN
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                   empv.work_base_code_old  -- 勤務地拠点コード(旧)
--                 WHEN empv.issue_date IS NULL THEN
--                   empv.work_base_code_old  -- 勤務地拠点コード(旧)
--                 END
--               )  base_code  
--        INTO   lv_reqst_base_code
--        FROM   xxcso_employees_v   empv
--        WHERE  empv.user_id = ln_created_by
--          /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--          --AND  ld_date 
--          --       BETWEEN TRUNC(NVL(empv.start_date, ld_date)) 
--          --           AND TRUNC(NVL(empv.end_date, ld_date))
--          --AND  ld_date 
--          --       BETWEEN TRUNC(NVL(empv.employee_start_date, ld_date)) 
--          --           AND TRUNC(NVL(empv.employee_end_date, ld_date))
--          --AND  ld_date 
--          --       BETWEEN TRUNC(NVL(empv.assign_start_date, ld_date)) 
--          --           AND TRUNC(NVL(empv.assign_end_date, ld_date))
--          AND  ld_reqst_date 
--                 BETWEEN TRUNC(NVL(empv.start_date, ld_reqst_date)) 
--                     AND TRUNC(NVL(empv.end_date, ld_reqst_date))
--          AND  ld_reqst_date 
--                 BETWEEN TRUNC(NVL(empv.employee_start_date, ld_reqst_date)) 
--                     AND TRUNC(NVL(empv.employee_end_date, ld_reqst_date))
--          AND  ld_reqst_date 
--                 BETWEEN TRUNC(NVL(empv.assign_start_date, ld_reqst_date)) 
--                     AND TRUNC(NVL(empv.assign_end_date, ld_reqst_date))
--          /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--        ;
----
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- データが存在しない場合
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_emplbase_info             -- トークン値1
--                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
--                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
--                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
--                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
--                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
--                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
--                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
--                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
--                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
--                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_skip_expt;
--          -- 抽出に失敗した場合
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_emplbase_info             -- トークン値1
--                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
--                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
--                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
--                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
--                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
--                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
--                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
--                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
--                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
--                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
--                         ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
--                         ,iv_token_value7 => SQLERRM                      -- トークン値7
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del END */
--
    END IF;
--
    -- 作業区分が店内移動の時
    IF (ln_job_kbn = cn_work_kbn6) THEN
      -- ================
      -- 現設置先顧客情報
      -- ================
      BEGIN
        /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
        --SELECT casv.organization_name_phonetic
        SELECT casv.party_name
        /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,empv.last_name || cv_zenspace || empv.first_name
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,casv.phone_number
              ,casv.postal_code
              ,casv.state
              ,casv.city
              ,casv.address1
              /* 2009.05.22 K.Satomura T1_1152対応 START */
              --,casv.address2
              ,NVL(casv.address2, cv_adddrss_chr)
              /* 2009.05.22 K.Satomura T1_1152対応 END */
              ,casv.account_number
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
              ,casv.sale_base_code
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
        INTO   lv_cur_organization_name
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,lv_cur_full_name
              /* 2009.08.10 K.Satomura 0000662対応 END */
              ,lv_cur_phone_number
              ,lv_cur_postal_code
              ,lv_cur_est_site_adress1
              ,lv_cur_est_site_adress2
              ,lv_cur_est_site_adress3
              ,lv_cur_est_site_adress4
              ,lv_cur_customer_code2
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
              ,lv_reqst_base_code
              /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
        FROM   xxcso_cust_acct_sites_v casv
              ,csi_item_instances      ciins
              /* 2009.08.10 K.Satomura 0000662対応 START */
              --,xxcso_employees_v       empv
              --,xxcso_cust_resources_v  crsv
              /* 2009.08.10 K.Satomura 0000662対応 END */
        WHERE  ciins.external_reference    = lv_install_code1
          AND  ciins.owner_party_account_id = casv.cust_account_id
          AND  casv.account_status    = 'A'
          AND  casv.acct_site_status  = 'A'
          AND  casv.party_status      = 'A'
          AND  casv.party_site_status = 'A'
          /* 2009.08.10 K.Satomura 0000662対応 START */
          --AND  casv.account_number    = crsv.account_number
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(crsv.start_date_active, ld_date)) 
          --           AND TRUNC(NVL(crsv.end_date_active, ld_date))
          --AND  crsv.employee_number   = empv.employee_number
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.end_date, ld_date))
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.employee_start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.employee_end_date, ld_date))
          --AND  ld_date 
          --       BETWEEN TRUNC(NVL(empv.assign_start_date, ld_date)) 
          --           AND TRUNC(NVL(empv.assign_end_date, ld_date))
          /* 2009.08.10 K.Satomura 0000662対応 END */
        ;
--
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
      ---- ================
      ---- 新設置先顧客情報
      ---- ================
      ---- 現設置先顧客情報と同一
      --lv_new_organization_name := lv_cur_organization_name;
      --/* 2009.08.10 K.Satomura 0000662対応 START */
      ----lv_new_full_name         := lv_cur_full_name;
      --/* 2009.08.10 K.Satomura 0000662対応 END */
      --lv_new_phone_number      := lv_cur_phone_number;
      --lv_new_postal_code       := lv_cur_postal_code;
      --lv_new_est_site_adress1  := lv_cur_est_site_adress1;
      --lv_new_est_site_adress2  := lv_cur_est_site_adress2;
      --lv_new_est_site_adress3  := lv_cur_est_site_adress3;
      --lv_new_est_site_adress4  := lv_cur_est_site_adress4;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_account2_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_account2_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
      -- 情報テンプレートに設置先顧客名が存在する場合はそちらを設定
      IF (lt_inst_at_cust_name IS NOT NULL) THEN
        lv_cur_organization_name := lt_inst_at_cust_name;
      END IF;
      --
      -- 情報テンプレートに設置先_郵便番号が存在する場合はそちらを設定
      IF (lt_inst_at_zip IS NOT NULL) THEN
        lv_cur_postal_code := lt_inst_at_zip;
      END IF;
      --
      -- 情報テンプレートに設置先都道府県が存在する場合はそちらを設定
      IF (lt_inst_at_prfcturs IS NOT NULL) THEN
        lv_cur_est_site_adress1 := lt_inst_at_prfcturs;
      END IF;
      --
      -- 情報テンプレートに設置先市区が存在する場合はそちらを設定
      IF (lt_inst_at_city IS NOT NULL) THEN
        lv_cur_est_site_adress2 := lt_inst_at_city;
      END IF;
      --
      -- 情報テンプレートに設置先住所１が存在する場合はそちらを設定
      IF (lt_inst_at_addr1 IS NOT NULL) THEN
        lv_cur_est_site_adress3 := lt_inst_at_addr1;
      END IF;
      --
      -- 情報テンプレートに設置先住所２が存在する場合はそちらを設定
      IF (lt_inst_at_addr2 IS NOT NULL) THEN
        lv_cur_est_site_adress4 := lt_inst_at_addr2;
      END IF;
      --
      -- 情報テンプレートに設置先電話番号が存在する場合はそちらを設定
      IF (lt_inst_at_phone IS NOT NULL) THEN
        lv_cur_phone_number := lt_inst_at_phone;
      END IF;
      --
      -- 情報テンプレートに設置先担当者名が存在する場合はそちらを設定、存在しなければ'＊'を設定
      IF (lt_inst_at_emp_name IS NOT NULL) THEN
        lv_cur_full_name := lt_inst_at_emp_name;
      ELSE
        lv_cur_full_name := cv_astrsk;
      END IF;
      --
      -- ================
      -- 新設置先顧客情報
      -- ================
      -- 現設置先顧客情報と同一
      lv_new_organization_name := lv_cur_organization_name;
      lv_new_full_name         := lv_cur_full_name;
      lv_new_phone_number      := lv_cur_phone_number;
      lv_new_postal_code       := lv_cur_postal_code;
      lv_new_est_site_adress1  := lv_cur_est_site_adress1;
      lv_new_est_site_adress2  := lv_cur_est_site_adress2;
      lv_new_est_site_adress3  := lv_cur_est_site_adress3;
      lv_new_est_site_adress4  := lv_cur_est_site_adress4;
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
--
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
      /* 2009.08.10 K.Satomura 0000662対応 START */
      ---- ==================
      ---- 現設置先営業員情報
      ---- ==================
      --BEGIN
      --  SELECT emp.last_name || cv_zenspace || emp.first_name
      --  INTO   lv_cur_full_name
      --  FROM   xxcso_cust_acct_sites_v cas
      --        ,csi_item_instances      cii
      --        ,xxcso_employees_v       emp
      --        ,xxcso_cust_resources_v  cre
      --  WHERE  cii.external_reference     = lv_install_code1
      --  AND    cii.owner_party_account_id = cas.cust_account_id
      --  AND    cas.account_number    = cre.account_number
      --  AND    ld_date BETWEEN TRUNC(NVL(cre.start_date_active, ld_date))
      --  AND    TRUNC(NVL(cre.end_date_active, ld_date))
      --  AND    cre.employee_number   = emp.employee_number
      --  AND    ld_date BETWEEN TRUNC(NVL(emp.start_date, ld_date))
      --  AND    TRUNC(NVL(emp.end_date, ld_date))
      --  AND    ld_date BETWEEN TRUNC(NVL(emp.employee_start_date, ld_date))
      --  AND    TRUNC(NVL(emp.employee_end_date, ld_date))
      --  AND    ld_date BETWEEN TRUNC(NVL(emp.assign_start_date, ld_date))
      --  AND    TRUNC(NVL(emp.assign_end_date, ld_date))
      --  ;
      --  --
      --  -- ==================
      --  -- 新設置先営業員情報
      --  -- ==================
      --  -- 新設置先営業員情報と同一
      --  lv_new_full_name := lv_cur_full_name;
      --  --
      --EXCEPTION
      --  WHEN NO_DATA_FOUND THEN
      --      -- データが存在しない場合
      --      BEGIN
      --        SELECT emp.last_name || cv_zenspace || emp.first_name
      --        INTO   lv_cur_full_name
      --        FROM   csi_item_instances      cii
      --              ,xxcso_cust_acct_sites_v cas
      --              ,xxcmm_cust_accounts     cac
      --              ,xxcso_employees_v       emp
      --        WHERE  cii.external_reference     = lv_install_code1
      --        AND    cii.owner_party_account_id = cas.cust_account_id
      --        AND    cas.account_number         = cac.customer_code
      --        AND    cac.cnvs_business_person   = emp.employee_number
      --        /* 2009.09.04 D.Abe 0001281対応 START */
      --        AND    ld_date BETWEEN TRUNC(NVL(emp.start_date, ld_date)) 
      --        AND    TRUNC(NVL(emp.end_date, ld_date))
      --        AND    ld_date BETWEEN TRUNC(NVL(emp.employee_start_date, ld_date)) 
      --        AND    TRUNC(NVL(emp.employee_end_date, ld_date))
      --        AND    ld_date BETWEEN TRUNC(NVL(emp.assign_start_date, ld_date))
      --        AND    TRUNC(NVL(emp.assign_end_date, ld_date))
      --        /* 2009.09.04 D.Abe 0001281対応 END */
      --        ;
      --        --
      --        -- ==================
      --        -- 新設置先営業員情報
      --        -- ==================
      --        -- 新設置先営業員情報と同一
      --        lv_new_full_name := lv_cur_full_name;
      --        --
      --      EXCEPTION
      --        WHEN NO_DATA_FOUND THEN
      --          lv_errmsg := xxccp_common_pkg.get_msg(
      --                          iv_application  => cv_app_name           -- アプリケーション短縮名
      --                         ,iv_name         => cv_tkn_number_06      -- メッセージコード
      --                         ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                         ,iv_token_value1 => cv_now_eigyoin_info   -- トークン値1
      --                         ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                         ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                         ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                         ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                         ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                         ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                         ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                         ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                         ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                         ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                       );
      --          --
      --          lv_errbuf := lv_errmsg;
      --          RAISE global_skip_expt;
      --          --
      --        WHEN OTHERS THEN
      --          -- 抽出に失敗した場合
      --          lv_errmsg := xxccp_common_pkg.get_msg(
      --                          iv_application  => cv_app_name           -- アプリケーション短縮名
      --                         ,iv_name         => cv_tkn_number_07      -- メッセージコード
      --                         ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                         ,iv_token_value1 => cv_now_eigyoin_info   -- トークン値1
      --                         ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                         ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                         ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                         ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                         ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                         ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                         ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                         ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                         ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                         ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                         ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
      --                         ,iv_token_value7 => SQLERRM               -- トークン値7
      --                       );
      --          --
      --          lv_errbuf := lv_errmsg;
      --          RAISE global_process_expt;
      --          --
      --      END;
      --      --
      --  WHEN OTHERS THEN
      --    -- 抽出に失敗した場合
      --    lv_errmsg := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_app_name           -- アプリケーション短縮名
      --                   ,iv_name         => cv_tkn_number_07      -- メッセージコード
      --                   ,iv_token_name1  => cv_tkn_task_nm        -- トークンコード1
      --                   ,iv_token_value1 => cv_now_eigyoin_info   -- トークン値1
      --                   ,iv_token_name2  => cv_tkn_po_num         -- トークンコード2
      --                   ,iv_token_value2 => lv_log_po_head_num    -- トークン値2
      --                   ,iv_token_name3  => cv_tkn_po_line_num    -- トークンコード3
      --                   ,iv_token_value3 => lv_log_po_line_num    -- トークン値3
      --                   ,iv_token_name4  => cv_tkn_po_distr_num   -- トークンコード4
      --                   ,iv_token_value4 => lv_log_po_dist_num    -- トークン値4
      --                   ,iv_token_name5  => cv_tkn_reqst_num      -- トークンコード5
      --                   ,iv_token_value5 => lv_log_rq_head_num    -- トークン値5
      --                   ,iv_token_name6  => cv_tkn_reqst_line_num -- トークンコード6
      --                   ,iv_token_value6 => lv_log_rq_line_num    -- トークン値6
      --                   ,iv_token_name7  => cv_tkn_errmsg         -- トークンコード7
      --                   ,iv_token_value7 => SQLERRM               -- トークン値7
      --                 );
      --    lv_errbuf := lv_errmsg;
      --    RAISE global_process_expt;
      --END;
      /* 2009.08.10 K.Satomura 0000662対応 END */
      /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
      -- 売上拠点コードの格納
      BEGIN
        SELECT casv.sale_base_code
        INTO   lv_sale_base_code
        FROM   xxcso_cust_accounts_v   casv
              ,csi_item_instances      ciins
        WHERE  ciins.external_reference = lv_install_code1
          AND  ciins.owner_party_account_id    = casv.cust_account_id
          AND  casv.account_status    = 'A'
          AND  casv.party_status      = 'A'
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_salebase_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
          -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_salebase_info             -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del START */
--      -- 依頼部署の格納
--      BEGIN
--        SELECT ( CASE
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--                 --WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd') <= ld_date THEN
--                 WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd') <= ld_reqst_date THEN
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                   empv.work_base_code_new  -- 勤務地拠点コード(新)
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--                 --WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd')  > ld_date THEN
--                 WHEN TO_DATE(empv.issue_date, 'yyyy/mm/dd')  > ld_reqst_date THEN
--                 /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--                   empv.work_base_code_old  -- 勤務地拠点コード(旧)
--                 WHEN empv.issue_date IS NULL THEN
--                   empv.work_base_code_old  -- 勤務地拠点コード(旧)
--                 END
--               )  base_code  
--        INTO   lv_reqst_base_code
--        FROM   xxcso_employees_v   empv
--        WHERE  empv.user_id = ln_created_by
--          /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--          --AND  ld_date 
--          --       BETWEEN TRUNC(NVL(empv.start_date, ld_date)) 
--          --           AND TRUNC(NVL(empv.end_date, ld_date))
--          --AND  ld_date 
--          --       BETWEEN TRUNC(NVL(empv.employee_start_date, ld_date)) 
--          --           AND TRUNC(NVL(empv.employee_end_date, ld_date))
--          --AND  ld_date 
--          --       BETWEEN TRUNC(NVL(empv.assign_start_date, ld_date)) 
--          --           AND TRUNC(NVL(empv.assign_end_date, ld_date))
--          AND  ld_reqst_date 
--                 BETWEEN TRUNC(NVL(empv.start_date, ld_reqst_date)) 
--                     AND TRUNC(NVL(empv.end_date, ld_reqst_date))
--          AND  ld_reqst_date 
--                 BETWEEN TRUNC(NVL(empv.employee_start_date, ld_reqst_date)) 
--                     AND TRUNC(NVL(empv.employee_end_date, ld_reqst_date))
--          AND  ld_reqst_date 
--                 BETWEEN TRUNC(NVL(empv.assign_start_date, ld_reqst_date)) 
--                     AND TRUNC(NVL(empv.assign_end_date, ld_reqst_date))
--          /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
--        ;
----
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- データが存在しない場合
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_emplbase_info             -- トークン値1
--                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
--                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
--                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
--                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
--                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
--                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
--                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
--                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
--                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
--                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_skip_expt;
--          -- 抽出に失敗した場合
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_app_name                  -- アプリケーション短縮名
--                         ,iv_name         => cv_tkn_number_07             -- メッセージコード
--                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                         ,iv_token_value1 => cv_emplbase_info             -- トークン値1
--                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
--                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
--                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
--                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
--                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
--                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
--                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
--                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
--                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
--                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
--                         ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
--                         ,iv_token_value7 => SQLERRM                      -- トークン値7
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
        /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Del End */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
--      -- 顧客営業担当員取得用の顧客コード取得
--      lt_emp_customer_code := lv_cur_customer_code2; --現設置先顧客コード
--      /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
--
    END IF;
--
/* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--/* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
--    -- ================
--    -- 担当営業員コード
--    -- ================
--    BEGIN
--      SELECT xrcv.employee_number employee_number
--      INTO   lt_empoyee_number
--      FROM   xxcso_resource_custs_v  xrcv --営業員担当顧客ビュー
--      WHERE  xrcv.account_number = lt_emp_customer_code  --各作業区分による設置先顧客コード
--        AND  ld_reqst_date BETWEEN NVL( xrcv.start_date_active, ld_reqst_date )
--                           AND     NVL( xrcv.end_date_active,   ld_reqst_date )
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        -- 顧客担当が存在しない場合は発注依頼作成者を設定
--        lt_empoyee_number := io_get_data_rec.employee_number;
--      WHEN OTHERS THEN
--/* 2011-07-01 K.Kiriu E_本稼動_07712対応 Del START */
----        -- 予期せぬエラーの場合、メッセージを出力し、発注依頼作成者を設定(エラーとせず正常とする)
----        lt_empoyee_number := io_get_data_rec.employee_number;
----
--/* 2011-07-01 K.Kiriu E_本稼動_07712対応 Del END */
--        -- 警告終了とし、データはスキップする
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name                  -- アプリケーション短縮名
--                       ,iv_name         => cv_tkn_number_07             -- メッセージコード
--                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
--                       ,iv_token_value1 => cv_account_emp_info          -- トークン値1
--                       ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
--                       ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
--                       ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
--                       ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
--                       ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
--                       ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
--                       ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
--                       ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
--                       ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
--                       ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
--                       ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
--                       ,iv_token_value7 => SQLERRM                      -- トークン値7
--                     );
--/* 2011-07-01 K.Kiriu E_本稼動_07712対応 Mod START */
----        -- メッセージ出力
----        fnd_file.put_line(
----           which  => FND_FILE.OUTPUT
----          ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
----        );
----        --ログ出力
----        fnd_file.put_line(
----           which  => FND_FILE.LOG
----          ,buff   => cv_pkg_name||cv_msg_cont||
----                     cv_prg_name||cv_msg_part||
----                     lv_errmsg                  -- エラーメッセージ
----        );
----        --変数初期化
----        lv_errmsg := NULL;
----
--        lv_errbuf := lv_errmsg;
--        RAISE global_skip_expt;
--/* 2011-07-01 K.Kiriu E_本稼動_07712対応 Mod END */
--    END;
--/* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add END */
/* 2012-09-28 K.Taniguchi E_本稼動_09604対応 Mod START */
--    -- ================
--    -- 担当営業員コード
--    -- ================
--    -- 設置先顧客の売上拠点で最上位従業員を既に取得している場合
--    IF ( gt_higher_emp_tab.EXISTS( lv_reqst_base_code ) ) THEN
----
--      -- 取得済の最上位営業員を設定
--      lt_empoyee_number := gt_higher_emp_tab( lv_reqst_base_code );
----
--    -- 未取得の場合、カーソルから取得
--    ELSE
----
--      -- 最上位従業員取得
--      OPEN  cur_employee_number (
--        lv_reqst_base_code  -- 設置先顧客の売上拠点
--       ,ld_reqst_date       -- 依頼日
--      );
--      FETCH cur_employee_number INTO lt_empoyee_number;
--      CLOSE cur_employee_number;
----
--      -- コレクションに追加
--      gt_higher_emp_tab( lv_reqst_base_code ) := lt_empoyee_number;
----
--    END IF;
--
    -- ================
    -- 担当営業員コード
    -- ================
--
    -- 設置先顧客の売上拠点の最上位従業員を担当営業員として取得
    -- 最上位従業員取得
    OPEN  cur_employee_number (
      lv_reqst_base_code  -- 設置先顧客の売上拠点
    );
    FETCH cur_employee_number INTO lt_empoyee_number;
    CLOSE cur_employee_number;
/* 2012-09-28 K.Taniguchi E_本稼動_09604対応 Mod END */
--
    -- 最上位担当者が取得できない場合
    IF ( lt_empoyee_number IS NULL ) THEN
        --メッセージを取得しスキップする
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_account_emp_info          -- トークン値1
                       ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                       ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                       ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                       ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                       ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                       ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                       ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                       ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                       ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                       ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                     );
--
        lv_errbuf := lv_errmsg;
        RAISE global_skip_expt;
    END IF;
/* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
    -- ================
    -- 所属マスタ情報
    -- ================
    /* 2010.03.08 K.Hosoi E_本稼動_01838対応 START */
    -- 作業区分が旧台設置、旧台代替、引揚、店内移動の場合
    IF (ln_job_kbn = cn_work_kbn2
      OR ln_job_kbn = cn_work_kbn4
      OR ln_job_kbn = cn_work_kbn5
      OR ln_job_kbn = cn_work_kbn6) THEN
      --
      -- ===================
      -- プロファイル値取得
      -- ===================
      -- XXCSO:旧台作業依頼IF作業会社自動設定フラグ
      FND_PROFILE.GET(
                      cv_wkcmp_auto_flg
                     ,lv_wkcmp_at_flg
                     );
      --
      -- XXCSO:自拠点作業時作業会社CD
      FND_PROFILE.GET(
                      cv_zikyoten_wkcmp_full_cd
                     ,lv_zktn_wkcmp_fll_cd
                     );
      --
      -- 取得したプロファイル値「自動設定フラグ」がNULLの場合は'N'を設定する
      IF (lv_wkcmp_at_flg IS NULL) THEN
        lv_wkcmp_at_flg := cv_no;
      END IF;
      --
      -- ===================
      -- 作業会社自動設定
      -- ===================
      -- 取得したプロファイル値「自動設定フラグ」が'N'の場合
      IF (lv_wkcmp_at_flg = cv_no) THEN
        --
        NULL;
      -- 取得したプロファイル値「自動設定フラグ」が'Y'の場合
      ELSIF (lv_wkcmp_at_flg = cv_yes) THEN
        --
        -- 取得したプロファイル値「自拠点作業時作業会社CD」が当該データの作業会社＋事業所コードと等しい場合
        IF (lv_zktn_wkcmp_fll_cd = lv_work_company_code || lv_work_location_code) THEN
          --
          NULL;
        --
        -- 取得したプロファイル値「自拠点作業時作業会社CD」が当該データの作業会社＋事業所コードと異なる場合
        ELSIF (lv_zktn_wkcmp_fll_cd <> lv_work_company_code || lv_work_location_code) THEN
          -- 作業区分が引揚の場合、売上担当拠点を導出
          IF (ln_job_kbn = cn_work_kbn5) THEN
            BEGIN
              SELECT casv.sale_base_code
              INTO   lv_sale_base_code2
              FROM   xxcso_cust_accounts_v   casv
                    ,csi_item_instances      ciins
              WHERE  ciins.external_reference = lv_install_code2
                AND  ciins.owner_party_account_id    = casv.cust_account_id
                AND  casv.account_status    = 'A'
                AND  casv.party_status      = 'A'
              ;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データが存在しない場合
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_06             -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                               ,iv_token_value1 => cv_salebase_info             -- トークン値1
                               ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                               ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                               ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                               ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                               ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                               ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                               ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                               ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                               ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                               ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_skip_expt;
                -- 抽出に失敗した場合
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                  -- アプリケーション短縮名
                               ,iv_name         => cv_tkn_number_07             -- メッセージコード
                               ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                               ,iv_token_value1 => cv_salebase_info             -- トークン値1
                               ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                               ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                               ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                               ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                               ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                               ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                               ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                               ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                               ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                               ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                               ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                               ,iv_token_value7 => SQLERRM                      -- トークン値7
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
          ELSE
            lv_sale_base_code2 := lv_sale_base_code;
          END IF;
          --
          --参照タイプより作業会社・事業所コードを取得し設定
          BEGIN
            SELECT  flv.attribute1        work_company_code      -- 作業会社CD
                   ,flv.attribute2        work_location_code     -- 作業会社事業所CD
            INTO    lv_work_company_code
                   ,lv_work_location_code
            FROM   fnd_lookup_values_vl flv -- 参照コード
            WHERE  flv.lookup_type                            =  cv_wkcmp_auto_mst
            AND    flv.lookup_code                            =  lv_sale_base_code2
            AND    TRUNC(NVL(flv.start_date_active, ld_date)) <= ld_date
            AND    TRUNC(NVL(flv.end_date_active, ld_date))   >= ld_date
            AND    flv.enabled_flag                           =  cv_yes
            ;
            --
            io_get_data_rec.work_company_code    := lv_work_company_code;  -- 作業会社CD
            io_get_data_rec.work_location_code   := lv_work_location_code; -- 作業会社事業所CD
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            WHEN OTHERS THEN
              lv_errbuf := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name              -- アプリケーション短縮名
                             ,iv_name         => cv_tkn_number_19         -- メッセージコード
                             ,iv_token_name1  => cv_tkn_task_nm           -- トークンコード1
                             ,iv_token_value1 => cv_tkn_value_task_name   -- トークン値1
                             ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
                             ,iv_token_value2 => cv_wkcmp_auto_mst        -- トークン値2
                             ,iv_token_name3  => cv_tkn_errmsg            -- トークンコード2
                             ,iv_token_value3 => SQLERRM                  -- トークン値2
                           );
              --
              RAISE global_process_expt;
              --
          END;
        END IF;
      END IF;
    END IF;
    /* 2010.03.08 K.Hosoi E_本稼動_01838対応 END */
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    -------------------------------------------------------------------------------------
    -- 付帯物の場合、代替時の作業が発注依頼と異なる為、作業会社を発注依頼の作業に合わせる
    -------------------------------------------------------------------------------------
    IF ( io_get_data_rec.install_type = cv_one ) THEN
      --発注依頼で指定した物件の処理の場合、作業会社を保持
      gt_company_code_base               := io_get_data_rec.work_company_code;
      gt_location_code_base              := io_get_data_rec.work_location_code;
    ELSIF( io_get_data_rec.install_type = cv_two ) THEN
      --付帯物の場合、発注依頼で指定した物件と同じ作業会社にする
      io_get_data_rec.work_company_code  := gt_company_code_base;
      io_get_data_rec.work_location_code := gt_location_code_base;
      lv_work_company_code               := gt_company_code_base;
      lv_work_location_code              := gt_location_code_base;
    END IF;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
--
    BEGIN
      -- コード
      lv_code := lv_work_company_code || lv_work_location_code;
      -- 事業所電話１
      lv_work_locatn_tel1 := xxcso_util_common_pkg.get_lookup_attribute(
                                cv_syozoku_mst
                               ,lv_code
                               ,3
                               ,ld_date);
      -- 事業所電話２
      lv_work_locatn_tel2 := xxcso_util_common_pkg.get_lookup_attribute(
                                cv_syozoku_mst
                               ,lv_code
                               ,4
                               ,ld_date);
      
      -- 事業所電話３
      lv_work_locatn_tel3 := xxcso_util_common_pkg.get_lookup_attribute(
                                cv_syozoku_mst
                               ,lv_code
                               ,5
                               ,ld_date);
      /* 2009.04.30 K.Satomura T1_0517対応 START */
      --IF (lv_work_locatn_tel1 IS NULL
      --      OR lv_work_locatn_tel2 IS NULL
      --      OR lv_work_locatn_tel2 IS NULL) THEN
      --      -- データが存在しない場合
      --  lv_errmsg := xxccp_common_pkg.get_msg(
      --                  iv_application  => cv_app_name                  -- アプリケーション短縮名
      --                 ,iv_name         => cv_tkn_number_06             -- メッセージコード
      --                 ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
      --                 ,iv_token_value1 => cv_syozokum_info             -- トークン値1
      --                 ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
      --                 ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
      --                 ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
      --                 ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
      --                 ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
      --                 ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
      --                 ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
      --                 ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
      --                 ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
      --                 ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
      --               );
      --  lv_errbuf := lv_errmsg;
      --  RAISE global_skip_expt;
      --END IF; 
      /* 2009.04.30 K.Satomura T1_0517対応 END */
--
    EXCEPTION
      WHEN global_skip_expt THEN 
         RAISE global_skip_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                       ,iv_token_value1 => cv_syozokum_info             -- トークン値1
                       ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                       ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                       ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                       ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                       ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                       ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                       ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                       ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                       ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                       ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                       ,iv_token_value7 => SQLERRM                      -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--  
    -- *** 作業依頼/発注情報の格納 ***
--
    /* 2009.04.06 D.Abe T1_0306対応 START */
    IF (lv_cur_phone_number IS NOT NULL) THEN
    /* 2009.04.06 D.Abe T1_0306対応 END */
      -- 電話番号編集
      ln_num1    := INSTR(lv_cur_phone_number, cv_hyphen);
      ln_num2    := INSTR(lv_cur_phone_number, cv_hyphen, 1, 2);
--
      /* 2009.09.25 D.Abe IE534対応 START */
      --IF (lv_cur_phone_number IS NULL OR ln_num1 = 0 OR ln_num2 = 0) THEN
      --  lv_cur_phone_number1 := NULL;
      --  lv_cur_phone_number2 := NULL;
      --  lv_cur_phone_number3 := NULL;
      --ELSE
      --  lv_cur_phone_number1 := SUBSTR(lv_cur_phone_number, 1, (ln_num1-1));
      --  lv_cur_phone_number2 := SUBSTR(lv_cur_phone_number, ln_num1 + 1, (ln_num2 - ln_num1 - 1));
      --  lv_cur_phone_number3 := SUBSTR(lv_cur_phone_number, ln_num2 + 1);
      --END IF;
      -- 一つ目のハイフン存在チェック
      IF (ln_num1 = 0) THEN
        lv_cur_phone_number1 := SUBSTR(lv_cur_phone_number, 1
                                                          , cn_phone_num_max_legth);
        lv_cur_phone_number2 := SUBSTR(lv_cur_phone_number, cn_phone_num_max_legth + 1
                                                          , cn_phone_num_max_legth);
        lv_cur_phone_number3 := SUBSTR(lv_cur_phone_number, cn_phone_num_max_legth + 1
                                                            + cn_phone_num_max_legth
                                                          , cn_phone_num_max_legth);
      ELSE
        lv_cur_phone_number1 := SUBSTR(lv_cur_phone_number, 1
                                                          , (ln_num1-1));
        -- 二つ目のハイフン存在チェック
        IF  (ln_num2 = 0) THEN
          lv_cur_phone_number2 := SUBSTR(lv_cur_phone_number, ln_num1 + 1
                                                            , cn_phone_num_max_legth);
          lv_cur_phone_number3 := SUBSTR(lv_cur_phone_number, ln_num1 + 1
                                                              + cn_phone_num_max_legth
                                                            , cn_phone_num_max_legth);
        ELSE
          lv_cur_phone_number2 := SUBSTR(lv_cur_phone_number, ln_num1 + 1
                                                            , (ln_num2 - ln_num1 - 1));
          lv_cur_phone_number3 := SUBSTR(lv_cur_phone_number, ln_num2 + 1);
        END IF;
      END IF;
      /* 2009.09.25 D.Abe IE534対応 END   */
--
      /* 2009.05.19 K.Satomura T1_1048対応 START */
      --ln_num1    := INSTR(lv_new_phone_number, cv_hyphen);
      --ln_num2    := INSTR(lv_new_phone_number, cv_hyphen, 1, 2);
--    --
      --IF (lv_new_phone_number IS NULL OR ln_num1 = 0 OR ln_num2 = 0) THEN
      --  lv_new_phone_number1 := NULL;
      --  lv_new_phone_number2 := NULL;
      --  lv_new_phone_number3 := NULL;
      --ELSE
      --  lv_new_phone_number1 := SUBSTR(lv_new_phone_number, 1, (ln_num1-1));
      --  lv_new_phone_number2 := SUBSTR(lv_new_phone_number, ln_num1 + 1, (ln_num2 - ln_num1 - 1));
      --  lv_new_phone_number3 := SUBSTR(lv_new_phone_number, ln_num2 + 1);
      --END IF;
      /* 2009.05.19 K.Satomura T1_1048対応 END */
    /* 2009.04.06 D.Abe T1_0306対応 START */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    ELSE
      lv_cur_phone_number1 := NULL;
      lv_cur_phone_number2 := NULL;
      lv_cur_phone_number3 := NULL;
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    END IF;
    /* 2009.04.06 D.Abe T1_0306対応 END */
--
    /* 2009.05.19 K.Satomura T1_1048対応 START */
    IF (lv_new_phone_number IS NOT NULL) THEN
      ln_num1 := INSTR(lv_new_phone_number, cv_hyphen);
      ln_num2 := INSTR(lv_new_phone_number, cv_hyphen, 1, 2);
      --
      /* 2009.09.25 D.Abe IE534対応 START */
      --IF (lv_new_phone_number IS NULL
      --  OR ln_num1 = 0
      --  OR ln_num2 = 0)
      --THEN
      --  lv_new_phone_number1 := NULL;
      --  lv_new_phone_number2 := NULL;
      --  lv_new_phone_number3 := NULL;
      --  --
      --ELSE
      --  lv_new_phone_number1 := SUBSTR(lv_new_phone_number, 1, (ln_num1-1));
      --  lv_new_phone_number2 := SUBSTR(lv_new_phone_number, ln_num1 + 1, (ln_num2 - ln_num1 - 1));
      --  lv_new_phone_number3 := SUBSTR(lv_new_phone_number, ln_num2 + 1);
      --  --
      --END IF;
      -- 一つ目のハイフン存在チェック
      IF (ln_num1 = 0) THEN
        lv_new_phone_number1 := SUBSTR(lv_new_phone_number, 1
                                                          , cn_phone_num_max_legth);
        lv_new_phone_number2 := SUBSTR(lv_new_phone_number, cn_phone_num_max_legth + 1
                                                          , cn_phone_num_max_legth);
        lv_new_phone_number3 := SUBSTR(lv_new_phone_number, cn_phone_num_max_legth + 1
                                                            + cn_phone_num_max_legth
                                                          , cn_phone_num_max_legth);
      ELSE
        lv_new_phone_number1 := SUBSTR(lv_new_phone_number, 1
                                                          , (ln_num1-1));
        -- 二つ目のハイフン存在チェック
        IF  (ln_num2 = 0) THEN
          lv_new_phone_number2 := SUBSTR(lv_new_phone_number, ln_num1 + 1
                                                            , cn_phone_num_max_legth);
          lv_new_phone_number3 := SUBSTR(lv_new_phone_number, ln_num1 + 1
                                                              + cn_phone_num_max_legth
                                                            , cn_phone_num_max_legth);
        ELSE
          lv_new_phone_number2 := SUBSTR(lv_new_phone_number, ln_num1 + 1
                                                            , (ln_num2 - ln_num1 - 1));
          lv_new_phone_number3 := SUBSTR(lv_new_phone_number, ln_num2 + 1);
        END IF;
      END IF;
      /* 2009.09.25 D.Abe IE534対応 END   */
      --
    ELSE
      lv_new_phone_number1 := NULL;
      lv_new_phone_number2 := NULL;
      lv_new_phone_number3 := NULL;
      --
    END IF;
    /* 2009.05.19 K.Satomura T1_1048対応 END */
    /* 2009.05.22 K.Satomura T1_1142対応 START */
    -- 電話番号桁数チェック
    IF (LENGTHB(lv_cur_phone_number1) > cn_phone_num_max_legth
      OR LENGTHB(lv_cur_phone_number2) > cn_phone_num_max_legth
      OR LENGTHB(lv_cur_phone_number3) > cn_phone_num_max_legth)
    THEN
      /* 2010.02.01 T.Maruyama E_本稼動_01018対応 START */
      --６桁を超える場合は切捨てする
      lv_cur_phone_number1 := SUBSTRB(lv_cur_phone_number1, 1, cn_phone_num_max_legth);
      lv_cur_phone_number2 := SUBSTRB(lv_cur_phone_number2, 1, cn_phone_num_max_legth);
      lv_cur_phone_number3 := SUBSTRB(lv_cur_phone_number3, 1, cn_phone_num_max_legth);
      
      ---- 現設置先電話桁数エラー
      --lv_errmsg := xxccp_common_pkg.get_msg(
      --                iv_application  => cv_app_name         -- アプリケーション短縮名
      --               ,iv_name         => cv_tkn_number_18    -- メッセージコード
      --               ,iv_token_name1  => cv_tkn_new_old      -- トークンコード1
      --               ,iv_token_value1 => cv_phone_old        -- トークン値1
      --               ,iv_token_name2  => cv_tkn_phone_num    -- トークンコード2
      --               ,iv_token_value2 => lv_cur_phone_number -- トークン値2
      --             );
      ----
      --/* 2009.05.27 M.Maruyama T1_1218対応 START */
      --lv_errbuf := lv_errmsg;
      --RAISE global_skip_expt;
      /* 2010.02.01 T.Maruyama E_本稼動_01018対応 END */
      --
    END IF;
    --
    IF (LENGTHB(lv_new_phone_number1) > cn_phone_num_max_legth
      OR LENGTHB(lv_new_phone_number2) > cn_phone_num_max_legth
      OR LENGTHB(lv_new_phone_number3) > cn_phone_num_max_legth)
    THEN
      /* 2010.02.01 T.Maruyama E_本稼動_01018対応 START */
      --６桁を超える場合は切捨てする
      lv_new_phone_number1 := SUBSTRB(lv_new_phone_number1, 1, cn_phone_num_max_legth);
      lv_new_phone_number2 := SUBSTRB(lv_new_phone_number2, 1, cn_phone_num_max_legth);
      lv_new_phone_number3 := SUBSTRB(lv_new_phone_number3, 1, cn_phone_num_max_legth);
      
      ---- 新設置先電話桁数エラー
      --lv_errmsg := xxccp_common_pkg.get_msg(
      --                iv_application  => cv_app_name         -- アプリケーション短縮名
      --               ,iv_name         => cv_tkn_number_18    -- メッセージコード
      --               ,iv_token_name1  => cv_tkn_new_old      -- トークンコード1
      --               ,iv_token_value1 => cv_phone_new        -- トークン値1
      --               ,iv_token_name2  => cv_tkn_phone_num    -- トークンコード2
      --               ,iv_token_value2 => lv_new_phone_number -- トークン値2
      --             );
      ----
      --lv_errbuf := lv_errmsg;
      --/* 2009.05.27 M.Maruyama T1_1218対応 END */
      --RAISE global_skip_expt;
      /* 2010.02.01 T.Maruyama E_本稼動_01018対応 END */
      --
    END IF;
    --
    /* 2009.05.22 K.Satomura T1_1142対応 END */
    -- 物件コード１
    io_get_data_rec.install_code1          := REPLACE(lv_install_code1, cv_hyphen);
    -- 機種名１
    io_get_data_rec.vendor_mode1           := lv_vendor_mode1;
    -- 機番１
    io_get_data_rec.vendor_number1         := lv_vendor_number1;
    -- 物件コード２
    io_get_data_rec.install_code2          := REPLACE(lv_install_code2, cv_hyphen);
    -- 機種名２
    io_get_data_rec.vendor_mode2           := lv_vendor_mode2;
    -- 機番２
    io_get_data_rec.vendor_number2         := lv_vendor_number2;
    -- 売上拠点コード
    io_get_data_rec.sale_base_code         := lv_sale_base_code;
    -- 依頼部署
    io_get_data_rec.reqst_base_code        := lv_reqst_base_code;
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add START */
    -- 担当営業員コード
    io_get_data_rec.employee_number        := lt_empoyee_number;
    /* 2011-06-23 K.Kiriu E_本稼動_07712対応 Add End */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    ---- 事業所電話１
--    io_get_data_rec.work_locatn_tel1       := lv_work_locatn_tel1;
    ---- 事業所電話２
--    io_get_data_rec.work_locatn_tel2       := lv_work_locatn_tel2;
    ---- 事業所電話３
--    io_get_data_rec.work_locatn_tel3       := lv_work_locatn_tel3;    
    ---- 事業所電話１
    io_get_data_rec.work_locatn_tel1       := NVL(lv_work_locatn_tel1,cv_phone_num);
    ---- 事業所電話２
    io_get_data_rec.work_locatn_tel2       := NVL(lv_work_locatn_tel2,cv_phone_num);
    ---- 事業所電話３
    io_get_data_rec.work_locatn_tel3       := NVL(lv_work_locatn_tel3,cv_phone_num);
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
--
    /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
    --/* 2009.05.21 M.Maruyama T1_1093対応 START */
    ---- -- 現設置先名
    ----io_get_data_rec.cur_organization_name  := lv_cur_organization_name;
    ---- 現設置先名
    --io_get_data_rec.cur_organization_name
    --           := SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(lv_cur_organization_name),1,40);
    --/* 2009.05.21 M.Maruyama T1_1093対応 END */
    -- 現設置先名
    -- 半角変換
    io_get_data_rec.cur_organization_name
               := SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(lv_cur_organization_name)
                          ,1,cv_cust_name_size);
    -- 禁則文字変換
    io_get_data_rec.cur_organization_name
               := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(io_get_data_rec.cur_organization_name)
                         ,1,cv_cust_name_size);
    /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
--
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    -- 現設置先担当者氏名
    --io_get_data_rec.cur_full_name          := lv_cur_full_name;
    -- 禁則文字変換
    io_get_data_rec.cur_full_name
               := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(lv_cur_full_name)
                         ,1,cv_full_name_size);
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    ----------------------
    --現設置先電話
    ----------------------
    -- 現設置先電話１
--    io_get_data_rec.cur_phone_number1      := lv_cur_phone_number1;
    -- 現設置先電話２
--    io_get_data_rec.cur_phone_number2      := lv_cur_phone_number2;
    -- 現設置先電話３
--    io_get_data_rec.cur_phone_number3      := lv_cur_phone_number3;
    IF ((ln_job_kbn = cn_work_kbn3) or (ln_job_kbn = cn_work_kbn4) 
       or (ln_job_kbn = cn_work_kbn5) or (ln_job_kbn = cn_work_kbn6)) THEN
      --作業区分が新台代替／旧台代替／引揚／店内移動の場合
      --電話番号分割後、それぞれNULLになる場合は固定値で埋める
      -- 現設置先電話１
      io_get_data_rec.cur_phone_number1      := NVL(lv_cur_phone_number1,cv_phone_num);
      -- 現設置先電話２
      io_get_data_rec.cur_phone_number2      := NVL(lv_cur_phone_number2,cv_phone_num);
      -- 現設置先電話３
      io_get_data_rec.cur_phone_number3      := NVL(lv_cur_phone_number3,cv_phone_num);
    ELSE
      -- 現設置先電話１
      io_get_data_rec.cur_phone_number1      := NULL;
      -- 現設置先電話２
      io_get_data_rec.cur_phone_number2      := NULL;
      -- 現設置先電話３
      io_get_data_rec.cur_phone_number3      := NULL;
    END IF;    
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */ 
    
    -- 現設置先郵便番号
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    --io_get_data_rec.cur_postal_code        := lv_cur_postal_code;
    io_get_data_rec.cur_postal_code        := SUBSTRB(lv_cur_postal_code, 1, 7);
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
    ---- 現設置先住所１
    --io_get_data_rec.cur_est_site_adress1   := lv_cur_est_site_adress1;
    ---- 現設置先住所２
    --io_get_data_rec.cur_est_site_adress2   := lv_cur_est_site_adress2;
    ---- 現設置先住所３
    --io_get_data_rec.cur_est_site_adress3   := lv_cur_est_site_adress3;
    -- 現設置先住所１
    io_get_data_rec.cur_est_site_adress1   
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_cur_est_site_adress1
                          )
                         ,1,cv_cust_add1_size);
    -- 現設置先住所２
    io_get_data_rec.cur_est_site_adress2  
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_cur_est_site_adress2
                          )
                         ,1,cv_cust_add2_size);
    -- 現設置先住所３
    io_get_data_rec.cur_est_site_adress3
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_cur_est_site_adress3
                          )
                         ,1,cv_cust_add3_size);
    /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
    /* 2009.05.21 M.Maruyama T1_1093対応 START */
    -- -- 現設置先住所４
    --io_get_data_rec.cur_est_site_adress4   := lv_cur_est_site_adress4;
    -- 現設置先住所４
    /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
    --/* 2009.05.22 K.Satomura T1_1152対応 START */
    ----io_get_data_rec.cur_est_site_adress4   := NVL(lv_cur_est_site_adress4,cv_adddrss_chr);
    --io_get_data_rec.cur_est_site_adress4   := lv_cur_est_site_adress4;
    --/* 2009.05.22 K.Satomura T1_1152対応 END */
    io_get_data_rec.cur_est_site_adress4
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_cur_est_site_adress4
                          )
                         ,1,cv_cust_add4_size);
    /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
    -- -- 新設置先名
    --io_get_data_rec.new_organization_name  := lv_new_organization_name;
    /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
    -- 新設置先名
    --io_get_data_rec.new_organization_name  
    --           := SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(lv_new_organization_name),1,40);
    -- 半角変換
    io_get_data_rec.new_organization_name  
               := SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(lv_new_organization_name)
                         ,1,cv_cust_name_size);   
    -- 禁則文字変換
    io_get_data_rec.new_organization_name  
               := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(io_get_data_rec.new_organization_name)
                         ,1,cv_cust_name_size);
    /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
    /* 2009.05.21 M.Maruyama T1_1093対応 END */
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 START */
    -- 新設置先担当者氏名
    --io_get_data_rec.new_full_name          := lv_new_full_name;
    -- 禁則文字変換
    io_get_data_rec.new_full_name
               := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(lv_new_full_name)
                         ,1,cv_full_name_size);
    /* 2009.12.21 K.Hosoi E_本稼動_00563対応 END */
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    ----------------------
    --新設置先電話
    ----------------------
    -- 新設置先電話１
--    io_get_data_rec.new_phone_number1      := lv_new_phone_number1;
    -- 新設置先電話２
--    io_get_data_rec.new_phone_number2      := lv_new_phone_number2;
    -- 新設置先電話３
--    io_get_data_rec.new_phone_number3      := lv_new_phone_number3;

    IF ((ln_job_kbn = cn_work_kbn1) or (ln_job_kbn = cn_work_kbn2) 
       or (ln_job_kbn = cn_work_kbn3) or (ln_job_kbn = cn_work_kbn4)
       or (ln_job_kbn = cn_work_kbn6)) THEN
      --作業区分が新台設置／新台代替／旧台設置／旧台代替／店内移動の場合
      --電話番号分割後、それぞれNULLになる場合は固定値で埋める
      -- 新設置先電話１
      io_get_data_rec.new_phone_number1      := NVL(lv_new_phone_number1,cv_phone_num);
      -- 新設置先電話２
      io_get_data_rec.new_phone_number2      := NVL(lv_new_phone_number2,cv_phone_num);
      -- 新設置先電話３
      io_get_data_rec.new_phone_number3      := NVL(lv_new_phone_number3,cv_phone_num);
    ELSE
      -- 新設置先電話１
      io_get_data_rec.new_phone_number1      := NULL;
      -- 新設置先電話２
      io_get_data_rec.new_phone_number2      := NULL;
      -- 新設置先電話３
      io_get_data_rec.new_phone_number3      := NULL;              
    END IF;
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    
    
    -- 新設置先郵便番号
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    --io_get_data_rec.new_postal_code        := lv_new_postal_code;
    io_get_data_rec.new_postal_code        := SUBSTRB(lv_new_postal_code, 1, 7);
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2009.12.14 T.Maruyama E_本稼動_00469 START */
    ---- 新設置先住所１
    --io_get_data_rec.new_est_site_adress1   := lv_new_est_site_adress1;
    ---- 新設置先住所２
    --io_get_data_rec.new_est_site_adress2   := lv_new_est_site_adress2;
    ---- 新設置先住所３
    --io_get_data_rec.new_est_site_adress3   := lv_new_est_site_adress3;
    --/* 2009.05.21 M.Maruyama T1_1093対応 START */
    ---- -- 新設置先住所４
    ----io_get_data_rec.new_est_site_adress4   := lv_new_est_site_adress4;
    ---- 新設置先住所４
    --/* 2009.05.22 K.Satomura T1_1152対応 START */
    ----io_get_data_rec.new_est_site_adress4   := NVL(lv_new_est_site_adress4,cv_adddrss_chr);
    --io_get_data_rec.new_est_site_adress4   := lv_new_est_site_adress4;
    --/* 2009.05.22 K.Satomura T1_1152対応 END */
    --/* 2009.05.21 M.Maruyama T1_1093対応 END */
    -- 新設置先住所１
    io_get_data_rec.new_est_site_adress1
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_new_est_site_adress1
                          )
                         ,1,cv_cust_add1_size);
    -- 新設置先住所２
    io_get_data_rec.new_est_site_adress2
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_new_est_site_adress2
                          )
                         ,1,cv_cust_add2_size);
    -- 新設置先住所３
    io_get_data_rec.new_est_site_adress3
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_new_est_site_adress3
                          )
                         ,1,cv_cust_add3_size);
    -- 新設置先住所４
    io_get_data_rec.new_est_site_adress4
                       := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                            lv_new_est_site_adress4
                          )
                         ,1,cv_cust_add4_size);
    /* 2009.12.14 T.Maruyama E_本稼動_00469 END */
    -- 顧客コード１（新設置先)
    io_get_data_rec.new_customer_code1     := lv_new_customer_code1;
    -- 顧客コード２（現設置先)
    io_get_data_rec.cur_customer_code2     := lv_cur_customer_code2;
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
    -- リース区分
    io_get_data_rec.lease_kbn              := lv_lease_kbn;
    /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
--  
  EXCEPTION
--
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ipro_po_related_data;
--
  /**********************************************************************************
   * Procedure Name   : update_wk_requisition_proc
   * Description      : 作業依頼／発注情報連携対象テーブル更新処理(A-6)
   ***********************************************************************************/
  PROCEDURE update_wk_requisition_proc(
     i_get_data_rec     IN     g_get_data_rtype        -- 出力用作業依頼/発注情報
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    ,ib_break_flag      IN     BOOLEAN                 -- ブレークフラグ
    ,iv_error_flag      IN     VARCHAR2                -- 発注依頼単位エラーフラグ
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
    ,ov_errbuf          OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ   --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_wk_requisition_proc';  -- プログラム名
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
    cv_no                    CONSTANT  VARCHAR2(1)    := 'N';
    cv_yes                   CONSTANT  VARCHAR2(1)    := 'Y';
    cv_up_process            CONSTANT  VARCHAR2(10)   := '更新';
    cv_check_range           CONSTANT  VARCHAR2(30)   := 'VENDING_MACHINE_SYSTEM';
    cv_table_name            CONSTANT  VARCHAR2(100)  := 'xxcso_wk_requisition_proc';
    cv_wk_req_proc           CONSTANT  VARCHAR2(100)  := '作業依頼／発注情報連携対象テーブル';
    cv_vendor_mode1          CONSTANT  VARCHAR2(100)  := '機種名１';
    cv_vendor_number1        CONSTANT  VARCHAR2(100)  := '機番１';
    cv_vendor_mode2          CONSTANT  VARCHAR2(100)  := '機種名２';
    cv_vendor_number2        CONSTANT  VARCHAR2(100)  := '機番２';
    cv_sale_base_code        CONSTANT  VARCHAR2(100)  := '売上拠点コード';
    cv_reqst_base_code       CONSTANT  VARCHAR2(100)  := '依頼部署';
    cv_employee_number       CONSTANT  VARCHAR2(100)  := '担当営業員コード';
    cv_work_hope_day         CONSTANT  VARCHAR2(100)  := '作業希望日';
    cv_work_hope_time        CONSTANT  VARCHAR2(100)  := '作業希望時間';
    cv_cur_organization_name CONSTANT  VARCHAR2(100)  := '現設置先名';
    cv_cur_full_name         CONSTANT  VARCHAR2(100)  := '現設置先担当者氏名';
    cv_cur_phone_number1     CONSTANT  VARCHAR2(100)  := '現設置先電話１';
    cv_cur_phone_number2     CONSTANT  VARCHAR2(100)  := '現設置先電話２';
    cv_cur_phone_number3     CONSTANT  VARCHAR2(100)  := '現設置先電話３';
    cv_cur_postal_code       CONSTANT  VARCHAR2(100)  := '現設置先郵便番号';
    cv_cur_est_site_adress1  CONSTANT  VARCHAR2(100)  := '現設置先住所１';
    cv_cur_est_site_adress2  CONSTANT  VARCHAR2(100)  := '現設置先住所２';
    cv_cur_est_site_adress3  CONSTANT  VARCHAR2(100)  := '現設置先住所３';
    cv_cur_est_site_adress4  CONSTANT  VARCHAR2(100)  := '現設置先住所４';
    cv_new_organization_name CONSTANT  VARCHAR2(100)  := '新設置先名';
    cv_new_full_name         CONSTANT  VARCHAR2(100)  := '新設置先担当者氏名';
    cv_new_phone_number1     CONSTANT  VARCHAR2(100)  := '新設置先電話１';
    cv_new_phone_number2     CONSTANT  VARCHAR2(100)  := '新設置先電話２';
    cv_new_phone_number3     CONSTANT  VARCHAR2(100)  := '新設置先電話３';
    cv_new_postal_code       CONSTANT  VARCHAR2(100)  := '新設置先郵便番号';
    cv_new_est_site_adress1  CONSTANT  VARCHAR2(100)  := '新設置先住所１';
    cv_new_est_site_adress2  CONSTANT  VARCHAR2(100)  := '新設置先住所２';
    cv_new_est_site_adress3  CONSTANT  VARCHAR2(100)  := '新設置先住所３';
    cv_new_est_site_adress4  CONSTANT  VARCHAR2(100)  := '新設置先住所４';
    cv_install_place_floor   CONSTANT  VARCHAR2(100)  := '設置場所階数';
    cv_elevator_frontage     CONSTANT  VARCHAR2(100)  := 'エレベータ間口';
    cv_elevator_depth        CONSTANT  VARCHAR2(100)  := 'エレベータ奥行き';
    cv_remarks               CONSTANT  VARCHAR2(100)  := '備考';
    cv_new_customer_code1    CONSTANT  VARCHAR2(100)  := '顧客コード１（新設置先）';
    cv_cur_customer_code2    CONSTANT  VARCHAR2(100)  := '顧客コード２（現設置先）';
--
    -- *** ローカル変数 ***
    ld_sys_date              DATE;              -- システム日付
    ln_rqstn_line_id         NUMBER;            -- 発注依頼明細ID
    lv_log_po_head_num       VARCHAR2(20);      -- ログ用発注番号
    lv_log_po_line_num       VARCHAR2(20);      -- ログ用発注明細番号
    lv_log_po_dist_num       VARCHAR2(20);      -- ログ用発注搬送番号
    lv_log_rq_head_num       VARCHAR2(20);      -- ログ用発注依頼番号
    lv_log_rq_line_num       VARCHAR2(20);      -- ログ用発注依頼明細番号
    lb_str_check_flg         BOOLEAN;           -- 禁則文字チェックフラグ
    ln_req_line_id           NUMBER;            -- ロック用発注依頼明細ID
    lv_interface_flag        VARCHAR2(1);       -- ロック用連携フラグ
--
    -- *** ローカル・例外 ***
    update_error_expt       EXCEPTION;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 発注依頼明細ID
    ln_rqstn_line_id     := i_get_data_rec.requisition_line_id;
    -- ログ用発注番号
    lv_log_po_head_num   := TO_CHAR(i_get_data_rec.po_header_num);
    -- ログ用発注明細番号
    lv_log_po_line_num   := TO_CHAR(i_get_data_rec.po_line_num);
    -- ログ用発注搬送番号
    lv_log_po_dist_num   := TO_CHAR(i_get_data_rec.po_distribution_num);
    -- ログ用発注依頼番号
    lv_log_rq_head_num   := TO_CHAR(i_get_data_rec.req_header_num);
    -- ログ用発注依頼明細番号
    lv_log_rq_line_num   := TO_CHAR(i_get_data_rec.req_line_num);
--
    -- ============================
    -- 禁止文字チェック処理
    -- ============================
    -- *** 共通関数がまだ ***
--  

    -- 機種名１
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.vendor_mode1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                       ,iv_token_value1 => cv_vendor_mode1                -- トークン値1
                       ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                       ,iv_token_value2 => i_get_data_rec.vendor_mode1    -- トークン値2
                       ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                       ,iv_token_value3 => cv_check_range                 -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 機番１
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.vendor_number1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_vendor_number1
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.vendor_number1 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 機種名２
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.vendor_mode2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_vendor_mode2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.vendor_mode2 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 機番２
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.vendor_number2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_vendor_number2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.vendor_number2 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 売上拠点コード
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.sale_base_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_sale_base_code
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.sale_base_code 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 依頼部署
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.reqst_base_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_reqst_base_code
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.reqst_base_code 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 担当営業員コード
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.employee_number, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_employee_number
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.employee_number 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 作業希望日
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.work_hope_day, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_work_hope_day
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.work_hope_day 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先名
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_organization_name, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_organization_name
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_organization_name 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先担当者氏名
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_full_name, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_full_name
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_full_name 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先電話１
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_phone_number1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_phone_number1
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_phone_number1 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先電話２
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_phone_number2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_phone_number2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_phone_number2
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先電話３
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_phone_number3, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_phone_number3
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_phone_number3 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先郵便番号
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_postal_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_postal_code
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_postal_code 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先住所1
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_est_site_adress1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_est_site_adress1
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_est_site_adress1 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先住所2
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_est_site_adress2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_est_site_adress2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_est_site_adress2 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先住所3
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_est_site_adress3, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_est_site_adress3
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_est_site_adress3 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 現設置先住所4
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_est_site_adress4, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_est_site_adress4
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_est_site_adress4 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先名
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_organization_name, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_organization_name
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_organization_name 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先担当者氏名
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_full_name, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_full_name
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_full_name 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先電話１
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_phone_number1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_phone_number1
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_phone_number1 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先電話２
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_phone_number2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_phone_number2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_phone_number2
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先電話３
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_phone_number3, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_phone_number3
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_phone_number3 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先郵便番号
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_postal_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_postal_code
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_postal_code 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先住所1
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_est_site_adress1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_est_site_adress1
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_est_site_adress1 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF; 
--
    -- 新設置先住所2
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_est_site_adress2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_est_site_adress2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_est_site_adress2 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先住所3
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_est_site_adress3, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_est_site_adress3
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_est_site_adress3 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 新設置先住所4
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_est_site_adress4, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_est_site_adress4
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_est_site_adress4 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 設置場所階数
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.install_place_floor, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_install_place_floor
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.install_place_floor 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- エレベータ間口
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.elevator_frontage, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_elevator_frontage
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.elevator_frontage 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- エレベータ奥行き
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.elevator_depth, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_elevator_depth
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.elevator_depth 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 備考
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.remarks, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_remarks
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.remarks 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 顧客コード１（新設置先）
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.new_customer_code1, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_new_customer_code1
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.new_customer_code1 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;
--
    -- 顧客コード２（現設置先）
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         i_get_data_rec.cur_customer_code2, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_tkn_number_08
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_cur_customer_code2
                       ,iv_token_name2  => cv_tkn_item_value
                       ,iv_token_value2 => i_get_data_rec.cur_customer_code2 
                       ,iv_token_name3  => cv_tkn_check_range
                       ,iv_token_value3 => cv_check_range
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END IF;

--
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    -- 同一発注依頼最後の行でエラーがない場合、ロック・更新を行う
    IF ( ( ib_break_flag = TRUE ) AND ( iv_error_flag = cv_no ) ) THEN
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
        -- ============================
      -- 更新前のロック処理
      -- ============================
      BEGIN
        SELECT  wkrp.requisition_line_id
               ,wkrp.interface_flag
        INTO    ln_req_line_id
               ,lv_interface_flag 
        FROM    xxcso_wk_requisition_proc wkrp
        WHERE   wkrp.requisition_line_id = ln_rqstn_line_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        -- ロック失敗した場合の例外
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                         ,iv_token_value1 => cv_wk_req_proc               -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
        -- 抽出に失敗した場合の例外
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_06             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                         ,iv_token_value1 => cv_wk_req_proc               -- トークン値1
                         ,iv_token_name2  => cv_tkn_po_num                -- トークンコード2
                         ,iv_token_value2 => lv_log_po_head_num           -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_line_num           -- トークンコード3
                         ,iv_token_value3 => lv_log_po_line_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_distr_num          -- トークンコード4
                         ,iv_token_value4 => lv_log_po_dist_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_reqst_num             -- トークンコード5
                         ,iv_token_value5 => lv_log_rq_head_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_line_num        -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_line_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_errmsg               -- トークンコード7
                         ,iv_token_value7 => SQLERRM                      -- トークン値7
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      BEGIN
        -- ==========================================
        -- 作業依頼／発注情報連携対象テーブル更新処理 
        -- ==========================================
        UPDATE xxcso_wk_requisition_proc
        SET    interface_flag         = cv_yes,
               last_updated_by        = cn_last_updated_by,
               last_update_date       = cd_last_update_date,
               last_update_login      = cn_last_update_login,
               request_id             = cn_request_id,
               program_application_id = cn_program_application_id,
               program_id             = cn_program_id,
               program_update_date    = cd_program_update_date
        WHERE  requisition_line_id    = ln_rqstn_line_id
        ;
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          -- 更新失敗ロールバックフラグの設定
          gb_rollback_upd_flg := TRUE;
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_09             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                         ,iv_token_value1 => cv_table_name                -- トークン値1
                         ,iv_token_name2  => cv_tkn_process               -- トークンコード2
                         ,iv_token_value2 => cv_up_process                -- トークン値2
                         ,iv_token_name3  => cv_tkn_po_num                -- トークンコード3
                         ,iv_token_value3 => lv_log_po_head_num           -- トークン値3
                         ,iv_token_name4  => cv_tkn_po_line_num           -- トークンコード4
                         ,iv_token_value4 => lv_log_po_line_num           -- トークン値4
                         ,iv_token_name5  => cv_tkn_po_distr_num          -- トークンコード5
                         ,iv_token_value5 => lv_log_po_dist_num           -- トークン値5
                         ,iv_token_name6  => cv_tkn_reqst_num             -- トークンコード6
                         ,iv_token_value6 => lv_log_rq_head_num           -- トークン値6
                         ,iv_token_name7  => cv_tkn_reqst_line_num        -- トークンコード7
                         ,iv_token_value7 => lv_log_rq_line_num           -- トークン値7
                         ,iv_token_name8  => cv_tkn_errmsg               -- トークンコード8
                         ,iv_token_value8 => SQLERRM                      -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    END IF;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
--
  EXCEPTION
--
    -- *** データ更新例外ハンドラ ***
    WHEN update_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理例外ハンドラ ***
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
--#####################################  固定部 END   ##########################################
--
  END update_wk_requisition_proc;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : 作業依頼/発注情報CSV出力(A-7)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_get_data_rec      IN  g_get_data_rtype    -- 出力用作業依頼/発注情報
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- プログラム名
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
    /* 2011.02.02 N.Horigome E_本稼動_02369対応 START */
--    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    /* 2011.02.02 N.Horigome E_本稼動_02369対応 END */
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data                    VARCHAR2(5000);   -- 編集データ格納
--  
    lv_log_po_head_num         VARCHAR2(20);     -- 発注番号
    lv_log_po_line_num         VARCHAR2(20);     -- 発注明細番号
    lv_log_po_dist_num         VARCHAR2(20);     -- 発注搬送番号
    lv_log_rq_head_num         VARCHAR2(20);     -- 発注依頼番号
    lv_log_rq_line_num         VARCHAR2(20);     -- 発注依頼明細番号
    -- 正常メッセージ
    lv_info                    VARCHAR2(5000);   -- 正常メッセージ格納
    -- *** ローカル・レコード ***
    l_get_data_rec  g_get_data_rtype;        -- 作業依頼/発注情報
    -- *** ローカル例外 ***
    file_put_line_expt     EXCEPTION;        -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをレコード変数に格納
    l_get_data_rec             := i_get_data_rec; -- 作業依頼/発注情報
    -- 発注番号
    lv_log_po_head_num         := TO_CHAR(l_get_data_rec.po_header_num);
    -- 発注明細番号
    lv_log_po_line_num         := TO_CHAR(l_get_data_rec.po_line_num);    
    -- 発注搬送番号
    lv_log_po_dist_num         := TO_CHAR(l_get_data_rec.po_distribution_num);     
    -- 発注依頼番号
    lv_log_rq_head_num         := TO_CHAR(l_get_data_rec.req_header_num);     
     -- 発注依頼明細番号
    lv_log_rq_line_num         := TO_CHAR(l_get_data_rec.req_line_num);    
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- データ作成
      lv_data := cv_sep_wquot || cv_sep_wquot                                                 -- 伝票番号
        || cv_sep_com || l_get_data_rec.slip_branch_no                                        -- 伝票枝番
        || cv_sep_com || l_get_data_rec.job_kbn                                               -- 作業区分
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_code1         || cv_sep_wquot -- 物件コード１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.vendor_mode1          || cv_sep_wquot -- 機種名１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.vendor_number1        || cv_sep_wquot -- 機番１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_code2         || cv_sep_wquot -- 物件コード２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.vendor_mode2          || cv_sep_wquot -- 機種名２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.vendor_number2        || cv_sep_wquot -- 機番２
        || cv_sep_com || l_get_data_rec.requisition_route                                     -- 依頼ルート
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.sale_base_code        || cv_sep_wquot -- 売上拠点コード
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.reqst_base_code       || cv_sep_wquot -- 依頼部署
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.employee_number       || cv_sep_wquot -- 担当営業員コード
        /* 2009.11.27 E_本稼動_00264 START */
        --|| cv_sep_com || l_get_data_rec.reqst_date                                            -- 依頼日
        --|| cv_sep_com || cv_sep_wquot || l_get_data_rec.reqst_time            || cv_sep_wquot -- 依頼時間
        /* 2009.12.05 D.Abe E_本稼動_00334 対応 START */
        --|| cv_sep_com || '20091120'                                                           -- 依頼日
        --|| cv_sep_com || cv_sep_wquot || '0800'                               || cv_sep_wquot -- 依頼時間
        /* 2009.11.27 E_本稼動_00264 END */
        || cv_sep_com || l_get_data_rec.reqst_date                                            -- 依頼日
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.reqst_time            || cv_sep_wquot -- 依頼時間
        /* 2009.12.05 D.Abe E_本稼動_00334 対応 END */
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_company_code     || cv_sep_wquot -- 作業会社コード
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_location_code    || cv_sep_wquot -- 事業所コード
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_locatn_tel1      || cv_sep_wquot -- 事業所電話１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_locatn_tel2      || cv_sep_wquot -- 事業所電話２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_locatn_tel3      || cv_sep_wquot -- 事業所電話３
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_hope_day_type    || cv_sep_wquot -- 作業希望日区分
        || cv_sep_com || l_get_data_rec.work_hope_day                                         -- 作業希望日
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_hope_time_type   || cv_sep_wquot -- 作業希望時間区分
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.work_hope_time        || cv_sep_wquot -- 作業希望時間
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_organization_name || cv_sep_wquot -- 現設置先名
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_full_name         || cv_sep_wquot -- 現設置先担当者氏名
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_phone_number1     || cv_sep_wquot -- 現設置先電話１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_phone_number2     || cv_sep_wquot -- 現設置先電話２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_phone_number3     || cv_sep_wquot -- 現設置先電話３
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_postal_code       || cv_sep_wquot -- 現設置先郵便番号
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_est_site_adress1  || cv_sep_wquot -- 現設置先住所１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_est_site_adress2  || cv_sep_wquot -- 現設置先住所２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_est_site_adress3  || cv_sep_wquot -- 現設置先住所３
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_est_site_adress4  || cv_sep_wquot -- 現設置先住所４
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 現設置先住所５
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_organization_name || cv_sep_wquot -- 新設置先名
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_full_name         || cv_sep_wquot -- 新設置先担当者氏名
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_phone_number1     || cv_sep_wquot -- 新設置先電話１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_phone_number2     || cv_sep_wquot -- 新設置先電話２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_phone_number3     || cv_sep_wquot -- 新設置先電話３
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_postal_code       || cv_sep_wquot -- 新設置先郵便番号
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_est_site_adress1  || cv_sep_wquot -- 新設置先住所１
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_est_site_adress2  || cv_sep_wquot -- 新設置先住所２
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_est_site_adress3  || cv_sep_wquot -- 新設置先住所３
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_est_site_adress4  || cv_sep_wquot -- 新設置先住所４
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 新設置先住所５
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.withdraw_company_code || cv_sep_wquot -- 引揚会社コード
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.withdraw_location_code|| cv_sep_wquot -- 引揚事業所コード
        || cv_sep_com || l_get_data_rec.withdraw_process_kbn                                  -- 引揚機処理区分
        || cv_sep_com || l_get_data_rec.preview_type                                          -- 下見区分
        || cv_sep_com || l_get_data_rec.install_place_type                                    -- 設置場所区分
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.install_place_floor   || cv_sep_wquot -- 設置場所階数
        || cv_sep_com || l_get_data_rec.install_fall_preventn                                 -- 設置転倒防止
        || cv_sep_com || l_get_data_rec.install_step_type                                     -- 設置段差区分
        || cv_sep_com || l_get_data_rec.install_inct_type                                     -- 設置傾斜区分
        || cv_sep_com || l_get_data_rec.electric_cost_type                                    -- 電気工事区分
        || cv_sep_com || l_get_data_rec.installed_side_type                                   -- 据付面区分
        || cv_sep_com || l_get_data_rec.import_step_type                                      -- 搬入段差区分
        || cv_sep_com || l_get_data_rec.raising_type                                          -- 手上げ区分
        || cv_sep_com || l_get_data_rec.stairs_lift_type                                      -- 階段昇降機区分
        || cv_sep_com || l_get_data_rec.elevator_kbn                                          -- エレベータ区分
        || cv_sep_com || l_get_data_rec.elevator_frontage                                     -- エレベータ間口
        || cv_sep_com || l_get_data_rec.elevator_depth                                        -- エレベータ奥行き
        || cv_sep_com || l_get_data_rec.unic_type                                             -- ユニック区分
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.remarks               || cv_sep_wquot -- 備考
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 事業所コード２
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 事業所電話２１
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 事業所電話２２
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 事業所電話２３
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作業担当者コード２１
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作業担当者名２１
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作業担当者コード２２
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作業担当者名２２
        || cv_sep_com                                                                         -- 実作業日
        || cv_sep_com                                                                         -- 実作業時間１
        || cv_sep_com                                                                         -- 実作業時間２
        || cv_sep_com                                                                         -- 完了区分
        || cv_sep_com                                                                         -- 固定区分
        || cv_sep_com                                                                         -- 固定・Ｍ１０アンカー
        || cv_sep_com                                                                         -- 固定・Ｍ１２アンカー
        || cv_sep_com                                                                         -- 固定・Ｅ型金具
        || cv_sep_com                                                                         -- 固定・Ｓ型金具
        || cv_sep_com                                                                         -- 固定・強化Ｅ型金具
        || cv_sep_com                                                                         -- 据付傾斜
        || cv_sep_com                                                                         -- 据付段差
        || cv_sep_com                                                                         -- Ａ寸法
        || cv_sep_com                                                                         -- へりあき右前
        || cv_sep_com                                                                         -- へりあき左前
        || cv_sep_com                                                                         -- へりあき右後
        || cv_sep_com                                                                         -- へりあき左後
        || cv_sep_com                                                                         -- レべリング右前
        || cv_sep_com                                                                         -- レべリング左前
        || cv_sep_com                                                                         -- レべリング右後
        || cv_sep_com                                                                         -- レべリング左後
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 安全設置基準
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 備考
        || cv_sep_com                                                                         -- 自業確認フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 自業確認者
        || cv_sep_com                                                                         -- 依頼受付フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 依頼受付者
        || cv_sep_com                                                                         -- 完了報告フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 完了報告者
        || cv_sep_com                                                                         -- 完了承認フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 完了承認者
        || cv_sep_com                                                                         -- 経費承認フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 経費承認者
        || cv_sep_com                                                                         -- 履歴作成フラグ
        || cv_sep_com                                                                         -- 完了フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 削除フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作成担当者コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作成部署コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 作成プログラムＩＤ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 更新担当者コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 更新部署コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                                         -- 更新プログラムＩＤ
        || cv_sep_com || TO_CHAR(SYSDATE, 'yyyymmddhh24miss')                                 -- 作成日時時分秒
        || cv_sep_com || TO_CHAR(SYSDATE, 'yyyymmddhh24miss')                                 -- 更新日時時分秒
        || cv_sep_com || l_get_data_rec.po_header_num                                         -- 発注番号
        || cv_sep_com || l_get_data_rec.po_line_num                                           -- 発注明細番号
        || cv_sep_com || l_get_data_rec.po_distribution_num                                   -- 発注搬送番号
        || cv_sep_com || l_get_data_rec.req_header_num                                        -- 発注依頼番号
        || cv_sep_com || l_get_data_rec.req_line_num                                          -- 発注依頼明細番号
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.new_customer_code1    || cv_sep_wquot -- 顧客コード１（新設置先）
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.cur_customer_code2    || cv_sep_wquot -- 顧客コード２（現設置先）
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
        || cv_sep_com || cv_sep_wquot || l_get_data_rec.lease_kbn             || cv_sep_wquot -- リース区分
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
      ;
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
     lv_info := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name                  -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_10             -- メッセージコード
                  ,iv_token_name1  => cv_tkn_po_num                -- トークンコード1
                  ,iv_token_value1 => lv_log_po_head_num           -- トークン値1
                  ,iv_token_name2  => cv_tkn_po_line_num           -- トークンコード2
                  ,iv_token_value2 => lv_log_po_line_num           -- トークン値2
                  ,iv_token_name3  => cv_tkn_po_distr_num          -- トークンコード3
                  ,iv_token_value3 => lv_log_po_dist_num           -- トークン値3
                  ,iv_token_name4  => cv_tkn_reqst_num             -- トークンコード4
                  ,iv_token_value4 => lv_log_rq_head_num           -- トークン値4
                  ,iv_token_name5  => cv_tkn_reqst_line_num        -- トークンコード5
                  ,iv_token_value5 => lv_log_rq_line_num           -- トークン値5
     );
      -- 結果をログに出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_info
      );
      -- 結果を出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_info
      );
--     
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_po_num                -- トークンコード1
                       ,iv_token_value1 => lv_log_po_head_num           -- トークン値1
                       ,iv_token_name2  => cv_tkn_po_line_num           -- トークンコード2
                       ,iv_token_value2 => lv_log_po_line_num           -- トークン値2
                       ,iv_token_name3  => cv_tkn_po_distr_num          -- トークンコード3
                       ,iv_token_value3 => lv_log_po_dist_num           -- トークン値3
                       ,iv_token_name4  => cv_tkn_reqst_num             -- トークンコード4
                       ,iv_token_value4 => lv_log_rq_head_num           -- トークン値4
                       ,iv_token_name5  => cv_tkn_reqst_line_num        -- トークンコード5
                       ,iv_token_value5 => lv_log_rq_line_num           -- トークン値5
                       ,iv_token_name6  => cv_tkn_errmsg               -- トークンコード6
                       ,iv_token_value6 => SQLERRM                      -- トークン値6
        );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : 作業依頼/発注情報CSVファイルクローズ処理(A-8)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm         IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- プログラム名
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
    -- *** ローカル変数 ***
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    -- *** DEBUG_LOG ***
    -- ファイルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10    || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- CSVファイルクローズ失敗・ロールバックフラグ設定
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_12             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                      ,iv_token_value1 => iv_csv_dir                   --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                      ,iv_token_value2 => iv_csv_nm                    --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_csv_nm   || CHR(10) ||
                   ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
   /**********************************************************************************
   * Procedure Name   : delete_wk_requisition_proc
   * Description      : 作業依頼／発注情報連携対象テーブル削除処理(A-9)
   ***********************************************************************************/
  PROCEDURE delete_wk_requisition_proc(
     in_rqstn_line_id   IN     NUMBER                  -- 発注依頼明細ID
    ,ov_errbuf          OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_wk_requisition_proc';  -- プログラム名
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
    cv_yes                   CONSTANT  VARCHAR2(1)    := 'Y';
    cv_table_name            CONSTANT  VARCHAR2(100)  := 'xxcso_wk_requisition_proc';
    -- *** ローカル変数 ***
    ln_rqstn_line_id         NUMBER;            -- 発注依頼明細ID
    -- *** ローカル・例外 ***
    delete_error_expt        EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 発注依頼明細ID
    ln_rqstn_line_id     := in_rqstn_line_id;
--
    BEGIN
      -- ==========================================
      -- 作業依頼／発注情報連携対象テーブル削除処理 
      -- ==========================================
      DELETE FROM xxcso_wk_requisition_proc
      WHERE  requisition_line_id = ln_rqstn_line_id
        AND  interface_flag      = cv_yes  
      ;
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_table_name                -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg               -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_error_expt;
    END;

  EXCEPTION
--
    -- *** データ更新例外ハンドラ ***
    WHEN delete_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理例外ハンドラ ***
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
--#####################################  固定部 END   ##########################################
--
  END delete_wk_requisition_proc;
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
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    cv_work_ipro_po_info      CONSTANT VARCHAR2(50) := '作業依頼/発注情報';
    -- 作業区分のattribute1
    cv_new_etblishmt_att1     CONSTANT VARCHAR2(2)  := '10';
    cv_new_altrntive_att1     CONSTANT VARCHAR2(2)  := '20';
    cv_old_etblishmt_att1     CONSTANT VARCHAR2(2)  := '30';
    cv_old_altrntive_att1     CONSTANT VARCHAR2(2)  := '40';
    cv_withdraw_att1          CONSTANT VARCHAR2(2)  := '50';
    cv_move_att1              CONSTANT VARCHAR2(2)  := '80';
    -- 承認済
    cv_approved               CONSTANT VARCHAR2(10) := 'APPROVED';
    -- 結果'YES'
    cv_y                      CONSTANT VARCHAR2(1)  := 'Y';
    -- 結果'NO'
    cv_n                      CONSTANT VARCHAR2(1)  := 'N';
    -- 引揚処理区分
    cv_withdraw_kbn           CONSTANT VARCHAR2(1)  := '1';
    -- 作業希望日区分
    cv_work_hope_day_type     CONSTANT VARCHAR2(1)  := '2';
    -- 区分
    cv_kbn_0                  CONSTANT VARCHAR2(1)  := '0';
    cv_kbn_1                  CONSTANT VARCHAR2(1)  := '1';
    cv_kbn_2                  CONSTANT VARCHAR2(1)  := '2';
    cv_kbn_3                  CONSTANT VARCHAR2(1)  := '3';
    -- 伝票枝番
    cn_branch_no              CONSTANT NUMBER       :=  0;
    -- 数値
    cn_1                      CONSTANT NUMBER       :=  1;
    -- 依頼ルート
    cn_rout_no                CONSTANT NUMBER       :=  2;
    
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    cv_remarks_byte           CONSTANT NUMBER       :=  240;
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
 --
/* 20090709_abe_0000465 START*/
    cv_concrete_board         CONSTANT VARCHAR2(30) :=  'コンクリート板要';
/* 20090709_abe_0000465 END*/
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
    cv_log_po_header_num      CONSTANT VARCHAR2(100) := '発注番号：';
    cv_log_req_line_num       CONSTANT VARCHAR2(100) := '発注依頼番号：';
    cv_log_cust_code          CONSTANT VARCHAR2(100) := '顧客コード：';
    cv_log_inst_code1         CONSTANT VARCHAR2(100) := '物件コード1：';
    cv_log_inst_code2         CONSTANT VARCHAR2(100) := '物件コード2：';
    /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
    /* 2011.02.02 N.Horigome E_本稼動_02369対応 START */
    cv_sep_punc               CONSTANT VARCHAR2(2)   := '、';
    /* 2011.02.02 N.Horigome E_本稼動_02369対応 END */
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    ld_sysdate                DATE;           -- システム日付
    ld_process_date           DATE;           -- 業務処理日
    lv_wdrw_base_code         VARCHAR2(10);   -- 引揚拠点コード
    lv_csv_dir                VARCHAR2(2000); -- CSVファイル出力先
    lv_csv_nm                 VARCHAR2(2000); -- CSVファイル名
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
    ln_org_id                 NUMBER;         -- 営業単位
    /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd             BOOLEAN;
    -- 備考編集用
    /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
    --lv_remarks                VARCHAR2(240);
    lv_remarks                VARCHAR2(1000);
    /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
    -- 発注依頼明細ID
    ln_rqstn_line_id          NUMBER;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    lb_break_flag             BOOLEAN;                                       -- ブレーク判定用
    lt_req_line_id            po_requisition_lines.requisition_line_id%TYPE; -- ブレーク判定用
    lv_error_flag             VARCHAR2(1);                                   -- 発注依頼単位エラー判定用
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
    /* 2015-07-27 K.Kiriu E_本稼動_13237対応 ADD START */
    ln_po_rec_line_num        NUMBER;                                        -- 発注依頼明細番号（付帯物）
    /* 2015-07-27 K.Kiriu E_本稼動_13237対応 ADD END   */
--
    -- *** ローカル・カーソル ***
    CURSOR get_ipro_po_data_cur
    IS
      /* 2009.08.05 K.Satomura 0000778対応 START */
      --SELECT   prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh prd pd pl ph cev) */
      -- 新台設置
      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh prd pd pl ph) */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2009.08.05 K.Satomura 0000778対応 END */
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn1                     job_kbn                          -- 作業区分
              ,null                             install_code1                    -- 物件コード1
              ,prlv.un_number_id                un_number_id                     -- 機種ID
              ,null                             install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, 'yyyymmdd')       reqst_date          -- 依頼日
              ,TO_CHAR(prlv.creation_date, 'hh24mi')         reqst_time          -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,null                             withdraw_company_code            -- 引揚先（搬入先）
              ,null                             withdraw_location_code           -- 引揚先（搬入先）事業所
              ,null                             withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,prlv.install_at_customer_code    install_at_customer_code         -- 顧客コード１
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--              ,cev.employee_number              employee_number                  -- 担当営業員コード
              ,NULL                             employee_number                  -- 担当営業員コード
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
              ,ph.segment1                      po_header_num                    -- 発注番号
              ,pl.line_num                      po_line_num                      -- 発注明細番号
              ,pd.distribution_num              po_distribution_num              -- 発注搬送番号
              /* 2009.04.02 K.Satomura T1_0169対応 START */
              --,null                             req_header_num                   -- 発注依頼番号
              --,null                             req_line_num                     -- 発注依頼明細番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              /* 2009.04.02 K.Satomura T1_0169対応 END */
              ,ph.segment1                      log_po_header_num                -- ログ用発注番号
              ,pl.line_num                      log_po_line_num                  -- ログ用発注明細番号
              ,pd.distribution_num              log_po_distribution_num          -- ログ用発注搬送番号
              /* 2009.04.02 K.Satomura T1_0169対応 START */
              --,null                             log_req_header_num               -- ログ用発注依頼番号
              --,null                             log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              /* 2009.04.02 K.Satomura T1_0169対応 END */
              ,prh.created_by                   created_by                       -- 作成者
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,pd.attribute1                    lease_kbn                        -- リース区分
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
              ,cv_one                           install_type                     -- 物件タイプ(発注依頼で指定された物件)
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      FROM     xxcso_requisition_lines_v        prlv                             -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh                              -- 発注依頼ヘッダビュー
              ,po_req_distributions             prd                              -- 発注依頼搬送明細ビュー
              ,po_lines                         pl                               -- 発注明細ビュー
              ,po_headers                       ph                               -- 発注ヘッダビュー
              ,po_distributions                 pd                               -- 発注搬送明細ビュー
              ,xxcso_wk_requisition_proc        wrp                    -- 作業依頼／発注情報連携対象テーブル
               /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--              ,xxcso_employees_v                cev                              -- 従業員マスタビュー
               /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      WHERE    prlv.category_kbn          = cv_new_etblishmt_att1
        AND    prlv.requisition_line_id   = prd.requisition_line_id
        AND    prd.distribution_id        = pd.req_distribution_id
        AND    pd.po_header_id            = ph.po_header_id
        AND    pd.po_line_id              = pl.po_line_id
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prh.authorization_status   = cv_approved
        AND    ph.authorization_status    = cv_approved
        AND    prlv.requisition_line_id   = wrp.requisition_line_id
        AND    wrp.interface_flag         = cv_n
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        AND    cev.user_id                = prh.created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.employee_end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.assign_end_date, TRUNC(ld_process_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.employee_end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.assign_end_date, TRUNC(prlv.creation_date))))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      /* 2009.08.05 K.Satomura 0000778対応 START */
      --UNION
      --SELECT   prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      UNION ALL
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh prd pd pl ph cev) */
      -- 新台代替
      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh prd pd pl ph) */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2009.08.05 K.Satomura 0000778対応 END */
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn3                     job_kbn                          -- 作業区分
              ,null                             install_code1                    -- 物件コード1
              ,prlv.un_number_id                un_number_id                     -- 機種ID
              ,prlv.withdraw_install_code       install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, 'yyyymmdd')       reqst_date           -- 依頼日
              ,TO_CHAR(prlv.creation_date, 'hh24mi')         reqst_time           -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,prlv.withdraw_company_code       withdraw_company_code            -- 引揚先（搬入先）
              ,prlv.withdraw_location_code      withdraw_location_code           -- 引揚先（搬入先）事業所
              ,cv_withdraw_kbn                  withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,null                             install_at_customer_code         -- 顧客コード１
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--              ,cev.employee_number              employee_number                  -- 担当営業員コード
              ,NULL                             employee_number                  -- 担当営業員コード
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
              ,ph.segment1                      po_header_num                    -- 発注番号
              ,pl.line_num                      po_line_num                      -- 発注明細番号
              ,pd.distribution_num              po_distribution_num              -- 発注搬送番号
              /* 2009.04.02 K.Satomura T1_0169対応 START */
              --,null                             req_header_num                   -- 発注依頼番号
              --,null                             req_line_num                     -- 発注依頼明細番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              /* 2009.04.02 K.Satomura T1_0169対応 END */
              ,ph.segment1                      log_po_header_num                -- ログ用発注番号
              ,pl.line_num                      log_po_line_num                  -- ログ用発注明細番号
              ,pd.distribution_num              log_po_distribution_num          -- ログ用発注搬送番号
              /* 2009.04.02 K.Satomura T1_0169対応 START */
              --,null                             log_req_header_num               -- ログ用発注依頼番号
              --,null                             log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              /* 2009.04.02 K.Satomura T1_0169対応 END */
              ,prh.created_by                   created_by                       -- 作成者
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,pd.attribute1                    lease_kbn                        -- リース区分
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
              ,cv_one                           install_type                     -- 物件タイプ(発注依頼で指定された物件)
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      FROM     xxcso_requisition_lines_v        prlv                             -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh                              -- 発注依頼ヘッダビュー
              ,po_req_distributions             prd                              -- 発注依頼搬送明細ビュー
              ,po_lines                         pl                               -- 発注明細ビュー
              ,po_headers                       ph                               -- 発注ヘッダビュー
              ,po_distributions                 pd                               -- 発注搬送明細ビュー
              ,xxcso_wk_requisition_proc        wrp                    -- 作業依頼／発注情報連携対象テーブル
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--              ,xxcso_employees_v                cev                              -- 従業員マスタビュー
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      WHERE    prlv.category_kbn          = cv_new_altrntive_att1
        AND    prlv.requisition_line_id   = prd.requisition_line_id
        AND    prd.distribution_id        = pd.req_distribution_id
        AND    pd.po_header_id            = ph.po_header_id
        AND    pd.po_line_id              = pl.po_line_id
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prh.authorization_status   = cv_approved
        AND    ph.authorization_status    = cv_approved
        AND    prlv.requisition_line_id   = wrp.requisition_line_id
        AND    wrp.interface_flag         = cv_n
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        AND    cev.user_id                = prh.created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.employee_end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.assign_end_date, TRUNC(ld_process_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.employee_end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.assign_end_date, TRUNC(prlv.creation_date))))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      /* 2009.08.05 K.Satomura 0000778対応 START */
      --UNION
      --SELECT   prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      UNION ALL
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh cev) */
      -- 旧台設置
      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh ) */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2009.08.05 K.Satomura 0000778対応 END */
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn2                     job_kbn                          -- 作業区分
              ,prlv.install_code                install_code1                    -- 物件コード1
              ,null                             un_number_id                     -- 機種ID
              ,null                             install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, 'yyyymmdd')       reqst_date           -- 依頼日
              ,TO_CHAR(prlv.creation_date, 'hh24mi')         reqst_time           -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,null                             withdraw_company_code            -- 引揚先（搬入先）
              ,null                             withdraw_location_code           -- 引揚先（搬入先）事業所
              ,null                             withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,prlv.install_at_customer_code    install_at_customer_code         -- 顧客コード１
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--              ,cev.employee_number              employee_number                  -- 担当営業員コード
              ,NULL                             employee_number                  -- 担当営業員コード
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
              ,null                             po_header_num                    -- 発注番号
              ,null                             po_line_num                      -- 発注明細番号
              ,null                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                    req_header_num                    -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,null                             log_po_header_num                -- ログ用発注番号
              ,null                             log_po_line_num                  -- ログ用発注明細番号
              ,null                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,null                             lease_kbn                        -- リース区分
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
              ,cv_one                           install_type                     -- 物件タイプ(発注依頼で指定された物件)
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      FROM     xxcso_requisition_lines_v        prlv                             -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh                              -- 発注依頼ヘッダビュー
              ,xxcso_wk_requisition_proc        wrp                    -- 作業依頼／発注情報連携対象テーブル
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--              ,xxcso_employees_v                cev                              -- 従業員マスタビュー
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      WHERE    prlv.category_kbn          = cv_old_etblishmt_att1
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prh.authorization_status   = cv_approved
        AND    prlv.requisition_line_id   = wrp.requisition_line_id
        AND    wrp.interface_flag         = cv_n
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        AND    cev.user_id                = prh.created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.employee_end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.assign_end_date, TRUNC(ld_process_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.employee_end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.assign_end_date, TRUNC(prlv.creation_date))))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      /* 2009.08.05 K.Satomura 0000778対応 START */
      --UNION
      --SELECT   prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      UNION ALL
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh cev) */
      -- 旧台代替
      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh) */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2009.08.05 K.Satomura 0000778対応 END */
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn4                     job_kbn                          -- 作業区分
              ,prlv.install_code                install_code1                    -- 物件コード1
              ,null                             un_number_id                     -- 機種ID
              ,prlv.withdraw_install_code       install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, 'yyyymmdd')       reqst_date           -- 依頼日
              ,TO_CHAR(prlv.creation_date, 'hh24mi')         reqst_time           -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,prlv.withdraw_company_code       withdraw_company_code            -- 引揚先（搬入先）
              ,prlv.withdraw_location_code      withdraw_location_code           -- 引揚先（搬入先）事業所
              ,cv_withdraw_kbn                  withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,null                             install_at_customer_code         -- 顧客コード１
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--              ,cev.employee_number              employee_number                  -- 担当営業員コード
              ,NULL                             employee_number                  -- 担当営業員コード
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
              ,null                             po_header_num                    -- 発注番号
              ,null                             po_line_num                      -- 発注明細番号
              ,null                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,null                             log_po_header_num                -- ログ用発注番号
              ,null                             log_po_line_num                  -- ログ用発注明細番号
              ,null                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,null                             lease_kbn                        -- リース区分
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
              ,cv_one                           install_type                     -- 物件タイプ(発注依頼で指定された物件)
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      FROM     xxcso_requisition_lines_v        prlv                             -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh                              -- 発注依頼ヘッダビュー
              ,xxcso_wk_requisition_proc        wrp                    -- 作業依頼／発注情報連携対象テーブル
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--              ,xxcso_employees_v                cev                              -- 従業員マスタビュー
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      WHERE    prlv.category_kbn          = cv_old_altrntive_att1
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prh.authorization_status   = cv_approved
        AND    prlv.requisition_line_id   = wrp.requisition_line_id
        AND    wrp.interface_flag         = cv_n
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        AND    cev.user_id                = prh.created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.employee_end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.assign_end_date, TRUNC(ld_process_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.employee_end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.assign_end_date, TRUNC(prlv.creation_date))))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      /* 2009.08.05 K.Satomura 0000778対応 START */
      --UNION
      --SELECT   prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      UNION ALL
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh cev) */
      -- 引揚
      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh) */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2009.08.05 K.Satomura 0000778対応 END */
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn5                     job_kbn                          -- 作業区分
              ,null                             install_code1                    -- 物件コード1
              ,null                             un_number_id                     -- 機種ID
              ,prlv.withdraw_install_code       install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, 'yyyymmdd')       reqst_date           -- 依頼日
              ,TO_CHAR(prlv.creation_date, 'hh24mi')         reqst_time           -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,prlv.withdraw_company_code       withdraw_company_code            -- 引揚先（搬入先）
              ,prlv.withdraw_location_code      withdraw_location_code           -- 引揚先（搬入先）事業所
              ,cv_withdraw_kbn                  withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,null                             install_at_customer_code         -- 顧客コード１
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--              ,cev.employee_number              employee_number                  -- 担当営業員コード
              ,NULL                             employee_number                  -- 担当営業員コード
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
              ,null                             po_header_num                    -- 発注番号
              ,null                             po_line_num                      -- 発注明細番号
              ,null                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,null                             log_po_header_num                -- ログ用発注番号
              ,null                             log_po_line_num                  -- ログ用発注明細番号
              ,null                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,null                             lease_kbn                        -- リース区分
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
              ,cv_one                           install_type                     -- 物件タイプ(発注依頼で指定された物件)
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      FROM     xxcso_requisition_lines_v        prlv                             -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh                              -- 発注依頼ヘッダビュー
              ,xxcso_wk_requisition_proc        wrp                    -- 作業依頼／発注情報連携対象テーブル
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--              ,xxcso_employees_v                cev                              -- 従業員マスタビュー
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      WHERE    prlv.category_kbn          = cv_withdraw_att1
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prh.authorization_status   = cv_approved
        AND    prlv.requisition_line_id   = wrp.requisition_line_id
        AND    wrp.interface_flag         = cv_n
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        AND    cev.user_id                = prh.created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.employee_end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.assign_end_date, TRUNC(ld_process_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.employee_end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.assign_end_date, TRUNC(prlv.creation_date))))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      /* 2009.08.05 K.Satomura 0000778対応 START */
      --UNION
      --SELECT   prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      UNION ALL
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh cev) */
      -- 店内移動
      SELECT   /*+ first_rows leading(wrp) use_nl(prlv prh) */
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
      /* 2009.08.05 K.Satomura 0000778対応 END */
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn6                     job_kbn                          -- 作業区分
              ,prlv.install_code                install_code1                    -- 物件コード1
              ,null                             un_number_id                     -- 機種ID
              ,null                             install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, 'yyyymmdd')       reqst_date           -- 依頼日
              ,TO_CHAR(prlv.creation_date, 'hh24mi')         reqst_time           -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,null                             withdraw_company_code            -- 引揚先（搬入先）
              ,null                             withdraw_location_code           -- 引揚先（搬入先）事業所
              ,null                             withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,null                             install_at_customer_code         -- 顧客コード１
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD START */
--              ,cev.employee_number              employee_number                  -- 担当営業員コード
              ,NULL                             employee_number                  -- 担当営業員コード
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 MOD END */
              ,null                             po_header_num                    -- 発注番号
              ,null                             po_line_num                      -- 発注明細番号
              ,null                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,null                             log_po_header_num                -- ログ用発注番号
              ,null                             log_po_line_num                  -- ログ用発注明細番号
              ,null                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
              ,null                             lease_kbn                        -- リース区分
              /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
              ,cv_one                           install_type                     -- 物件タイプ(発注依頼で指定された物件)
              /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      FROM     xxcso_requisition_lines_v        prlv                             -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh                              -- 発注依頼ヘッダビュー
              ,xxcso_wk_requisition_proc        wrp                    -- 作業依頼／発注情報連携対象テーブル
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--              ,xxcso_employees_v                cev                              -- 従業員マスタビュー
              /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      WHERE    prlv.category_kbn          = cv_move_att1
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prh.authorization_status   = cv_approved
        AND    prlv.requisition_line_id   = wrp.requisition_line_id
        AND    wrp.interface_flag         = cv_n
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
--        AND    cev.user_id                = prh.created_by
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 START */
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.employee_end_date, TRUNC(ld_process_date))))
--        --AND    (TRUNC(ld_process_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(ld_process_date))) AND
--        --         TRUNC(NVL(cev.assign_end_date, TRUNC(ld_process_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN TRUNC(NVL(cev.employee_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.employee_end_date, TRUNC(prlv.creation_date))))
--        AND    (TRUNC(prlv.creation_date) BETWEEN(NVL(cev.assign_start_date, TRUNC(prlv.creation_date))) AND
--                 TRUNC(NVL(cev.assign_end_date, TRUNC(prlv.creation_date))))
--        /* 2010.05.10 D.Abe E_本稼動_02598対応 END   */
        /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
      -- 店内移動 ※付帯物（新台代替）
      UNION ALL
      SELECT   /*+
                 LEADING( wrp )
                 USE_NL( wrp prlv prh prd pd ph cii1 cii2)
                 INDEX( wrp XXCSO_WK_REQUISITION_PROC_N01 )
                 INDEX( prlv.prl PO_REQUISITION_LINES_U1 )
               */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn6                     job_kbn                          -- 作業区分
              ,cii2.external_reference          install_code1                    -- 物件コード1
              ,NULL                             un_number_id                     -- 機種ID
              ,NULL                             install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, cv_format_date)   reqst_date          -- 依頼日
              ,TO_CHAR(prlv.creation_date, cv_format_time)   reqst_time          -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,NULL                             withdraw_company_code            -- 引揚先（搬入先）
              ,NULL                             withdraw_location_code           -- 引揚先（搬入先）事業所
              ,NULL                             withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,NULL                             install_at_customer_code         -- 顧客コード１
              ,NULL                             employee_number                  -- 担当営業員コード
              ,NULL                             po_header_num                    -- 発注番号
              ,NULL                             po_line_num                      -- 発注明細番号
              ,NULL                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,NULL                             log_po_header_num                -- ログ用発注番号
              ,NULL                             log_po_line_num                  -- ログ用発注明細番号
              ,NULL                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              ,NULL                             lease_kbn                        -- リース区分
              ,cv_two                           install_type                     -- 物件タイプ(付帯物)
      FROM     xxcso_wk_requisition_proc        wrp      -- 作業依頼／発注情報連携対象テーブル
              ,xxcso_requisition_lines_v        prlv     -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh      -- 発注依頼ヘッダビュー
              ,po_req_distributions             prd      -- 発注依頼搬送明細ビュー
              ,po_distributions                 pd       -- 発注搬送明細ビュー
              ,po_headers                       ph       -- 発注ヘッダビュー
              ,csi_item_instances               cii1     -- 物件マスタ（発注依頼で指定）
              ,csi_item_instances               cii2     -- 物件マスタ（付帯物）
      WHERE    wrp.interface_flag          =  cv_n                              -- 未送信
        AND    wrp.requisition_line_id     =  prlv.requisition_line_id
        AND    prlv.category_kbn           =  cv_new_altrntive_att1             -- 新台代替
        AND    prlv.requisition_header_id  =  prh.requisition_header_id
        AND    prh.authorization_status    =  cv_approved                       -- 承認済(発注依頼)
        AND    prlv.requisition_line_id    =  prd.requisition_line_id
        AND    prd.distribution_id         =  pd.req_distribution_id
        AND    pd.po_header_id             =  ph.po_header_id
        AND    ph.authorization_status     =  cv_approved                       -- 承認済(発注)
        AND    prlv.withdraw_install_code  =  cii1.external_reference
        AND    cii1.instance_type_code     =  cv_one                            -- 発注依頼で指定された物件が自販機
        AND    cii1.owner_party_account_id =  cii2.owner_party_account_id
        AND    prh.segment1                =
                 SUBSTRB( cii2.attribute8, 1, INSTRB(cii2.attribute8,'/') -1 )  -- 指定された物件と同一の発注依頼で作業依頼中
        AND    cii1.external_reference    <>  cii2.external_reference           -- 発注依頼で指定された物件以外
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      -- 店内移動 ※付帯物（旧台代替）
      UNION ALL
      SELECT   /*+
                 LEADING( wrp )
                 USE_NL( wrp prlv prh cii1 cii2 )
                 INDEX( wrp XXCSO_WK_REQUISITION_PROC_N01 )
                 INDEX( prlv.prl PO_REQUISITION_LINES_U1 )
               */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn6                     job_kbn                          -- 作業区分
              ,cii2.external_reference          install_code1                    -- 物件コード1
              ,NULL                             un_number_id                     -- 機種ID
              ,NULL                             install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, cv_format_date)   reqst_date          -- 依頼日
              ,TO_CHAR(prlv.creation_date, cv_format_time)   reqst_time          -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,NULL                             withdraw_company_code            -- 引揚先（搬入先）
              ,NULL                             withdraw_location_code           -- 引揚先（搬入先）事業所
              ,NULL                             withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,NULL                             install_at_customer_code         -- 顧客コード１
              ,NULL                             employee_number                  -- 担当営業員コード
              ,NULL                             po_header_num                    -- 発注番号
              ,NULL                             po_line_num                      -- 発注明細番号
              ,NULL                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,NULL                             log_po_header_num                -- ログ用発注番号
              ,NULL                             log_po_line_num                  -- ログ用発注明細番号
              ,NULL                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              ,NULL                             lease_kbn                        -- リース区分
              ,cv_two                           install_type                     -- 物件タイプ(付帯物)
      FROM     xxcso_wk_requisition_proc        wrp      -- 作業依頼／発注情報連携対象テーブル
              ,xxcso_requisition_lines_v        prlv     -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh      -- 発注依頼ヘッダビュー
              ,csi_item_instances               cii1     -- 物件マスタ（発注依頼で指定）
              ,csi_item_instances               cii2     -- 物件マスタ（付帯物）
      WHERE    wrp.interface_flag          =  cv_n                              -- 未送信
        AND    wrp.requisition_line_id     =  prlv.requisition_line_id
        AND    prlv.category_kbn           =  cv_old_altrntive_att1             -- 旧台代替
        AND    prlv.requisition_header_id  =  prh.requisition_header_id
        AND    prh.authorization_status    =  cv_approved                       -- 承認済(発注依頼)
        AND    prlv.withdraw_install_code  =  cii1.external_reference
        AND    cii1.instance_type_code     =  cv_one                            -- 発注依頼で指定された物件が自販機
        AND    cii1.owner_party_account_id =  cii2.owner_party_account_id
        AND    prh.segment1                =
                 SUBSTRB( cii2.attribute8, 1, INSTRB(cii2.attribute8,'/') -1 )  -- 指定された物件と同一の発注依頼で作業依頼中
        AND    cii1.external_reference    <>  cii2.external_reference           -- 発注依頼で指定された物件以外
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      UNION ALL
      -- 引揚 ※付帯物（引揚）
      SELECT   /*+
                 LEADING( wrp )
                 USE_NL( wrp prlv prh cii1 cii2 )
                 INDEX( wrp XXCSO_WK_REQUISITION_PROC_N01 )
                 INDEX( prlv.prl PO_REQUISITION_LINES_U1 )
               */
               prlv.requisition_line_id         requisition_line_id              -- 発注依頼明細ID
              ,cn_branch_no                     slip_branch_no                   -- 伝票枝番
              ,cn_work_kbn5                     job_kbn                          -- 作業区分
              ,NULL                             install_code1                    -- 物件コード1
              ,NULL                             un_number_id                     -- 機種ID
              ,cii2.external_reference          install_code2                    -- 物件コード2
              ,cn_rout_no                       requisition_route                -- 依頼ルート
              ,TO_CHAR(prlv.creation_date, cv_format_date)   reqst_date          -- 依頼日
              ,TO_CHAR(prlv.creation_date, cv_format_time)   reqst_time          -- 依頼時間
              ,prlv.work_company_code           work_company_code                -- 作業会社事業所
              ,prlv.work_location_code          work_location_code               -- 作業会社事業所
              ,prlv.work_hope_year              work_hope_year                   -- 作業希望年
              ,prlv.work_hope_month             work_hope_month                  -- 作業希望月
              ,prlv.work_hope_day               work_hope_day                    -- 作業希望日
              ,prlv.work_hope_time_type         work_hope_time_type              -- 作業希望時間区分
              ,prlv.work_hope_time_hour         work_hope_time_hour              -- 作業希望時
              ,prlv.work_hope_time_minute       work_hope_time_minute            -- 作業希望分
              ,prlv.withdraw_company_code       withdraw_company_code            -- 引揚先（搬入先）
              ,prlv.withdraw_location_code      withdraw_location_code           -- 引揚先（搬入先）事業所
              ,cv_withdraw_kbn                  withdraw_process_kbn             -- 引揚機処理区分
              ,prlv.preview_type                preview_type                     -- 下見区分
              ,prlv.install_place_type          install_place_type               -- 設置場所区分
              ,prlv.install_place_floor         install_place_floor              -- 設置場所階数
              ,prlv.install_fall_prevention     install_fall_preventn            -- 設置転倒防止
              ,prlv.install_step_type           install_step_type                -- 設置段差区分
              ,prlv.install_inclination_type    install_inclination_type         -- 設置傾斜区分
              ,prlv.electric_construction_type  electric_construction_type       -- 電気工事区分
              ,prlv.installed_side_type         installed_side_type              -- 据付面区分
              ,prlv.import_step_type            import_step_type                 -- 搬入段差区分
              ,prlv.raising_type                raising_type                     -- 手上げ区分
              ,prlv.stairs_lift_type            stairs_lift_type                 -- 階段昇降機区分
              ,prlv.unic_type                   unic_type                        -- ユニック区分
              ,prlv.elevator_frontage           elevator_frontage                -- エレベータ間口
              ,prlv.elevator_depth              elevator_depth                   -- エレベータ奥行き
              ,prlv.concrete_board              concrete_board                   -- コンクリート板
              ,prlv.extension_code_type         extension_code_type              -- 延長コード区分
              ,prlv.extension_code_meter        extension_code_meter             -- 延長コード（ｍ）
              ,prlv.remarks1                    remarks1                         -- 備考１
              ,prlv.remarks2                    remarks2                         -- 備考２
              ,prlv.remarks3                    remarks3                         -- 備考３
              ,NULL                             install_at_customer_code         -- 顧客コード１
              ,NULL                             employee_number                  -- 担当営業員コード
              ,NULL                             po_header_num                    -- 発注番号
              ,NULL                             po_line_num                      -- 発注明細番号
              ,NULL                             po_distribution_num              -- 発注搬送番号
              ,prh.segment1                     req_header_num                   -- 発注依頼番号
              ,prlv.line_num                    req_line_num                     -- 発注依頼明細番号
              ,NULL                             log_po_header_num                -- ログ用発注番号
              ,NULL                             log_po_line_num                  -- ログ用発注明細番号
              ,NULL                             log_po_distribution_num          -- ログ用発注搬送番号
              ,prh.segment1                     log_req_header_num               -- ログ用発注依頼番号
              ,prlv.line_num                    log_req_line_num                 -- ログ用発注依頼明細番号
              ,prh.created_by                   created_by                       -- 作成者
              ,NULL                             lease_kbn                        -- リース区分
              ,cv_two                           install_type                     -- 物件タイプ(付帯物)
      FROM     xxcso_wk_requisition_proc        wrp      -- 作業依頼／発注情報連携対象テーブル
              ,xxcso_requisition_lines_v        prlv     -- 発注依頼明細情報ビュー
              ,po_requisition_headers           prh      -- 発注依頼ヘッダビュー
              ,csi_item_instances               cii1     -- 物件マスタ（発注依頼で指定）
              ,csi_item_instances               cii2     -- 物件マスタ（付帯物）
      WHERE    wrp.interface_flag          =  cv_n                              -- 未送信
        AND    wrp.requisition_line_id     =  prlv.requisition_line_id
        AND    prlv.category_kbn           =  cv_withdraw_att1                  -- 引揚
        AND    prlv.requisition_header_id  =  prh.requisition_header_id
        AND    prh.authorization_status    =  cv_approved                       -- 承認済
        AND    prlv.withdraw_install_code  =  cii1.external_reference
        AND    cii1.instance_type_code     =  cv_one                            -- 発注依頼で指定された物件が自販機
        AND    cii1.owner_party_account_id =  cii2.owner_party_account_id
        AND    prh.segment1                =
                 SUBSTRB( cii2.attribute8, 1, INSTRB(cii2.attribute8,'/') -1 )  -- 指定された物件と同一の発注依頼で作業依頼中
        AND    cii1.external_reference    <>  cii2.external_reference           -- 発注依頼で指定された物件以外
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.lookup_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.lookup_end_date, TRUNC(ld_process_date))))
        AND    (TRUNC(ld_process_date) BETWEEN(NVL(prlv.category_start_date, TRUNC(ld_process_date))) AND
                 TRUNC(NVL(prlv.category_end_date, TRUNC(ld_process_date))))
      ORDER BY
        1   --発注依頼明細ID
       ,55  --物件タイプ(1:発注依頼で指定した物件 2:付帯物)
      /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      ;
--
    -- *** ローカル・レコード ***
    l_get_ipro_po_data_rec      get_ipro_po_data_cur%ROWTYPE;
    l_get_data_rec              g_get_data_rtype;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    -- *** ローカル・テーブル型 ***
    TYPE l_get_ipro_po_data_ttype IS TABLE OF get_ipro_po_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE g_get_data_ttype         IS TABLE OF g_get_data_rtype INDEX BY BINARY_INTEGER;
    l_get_ipro_po_data_tab      l_get_ipro_po_data_ttype; -- カーソルデータ一括取得用
    l_get_data_tbl              g_get_data_ttype;         -- 発注依頼単位の保持用
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
    -- *** ローカル例外 ***
    no_data_expt       EXCEPTION;
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
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
       od_sysdate            => ld_sysdate          -- システム日付
      ,od_process_date       => ld_process_date     -- 業務処理日付
      ,ov_csv_dir            => lv_csv_dir          -- CSVファイル出力先
      ,ov_csv_nm             => lv_csv_nm           -- CSVファイル名
      ,ov_wdrw_base_code     => lv_wdrw_base_code   -- 引揚拠点コード
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL START */
      ,on_org_id             => ln_org_id           -- 営業単位
      /* 2011-07-08 K.Kiriu E_本稼動_07712対応 DEL END */
      ,ov_errbuf             => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode            => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg             => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- =================================================
    -- A-2.（作業依頼/発注情報）CSVファイルオープン
    -- =================================================
    open_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSVファイル出力先
      ,iv_csv_nm    => lv_csv_nm    -- CSVファイル名
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.作業依頼/発注情報データ抽出処理
    -- ========================================
    -- カーソルオープン
    OPEN get_ipro_po_data_cur;
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD START */
--    <<get_data_loop>>
--    LOOP
    -- 変数初期化
    lb_break_flag  := FALSE;
    lv_error_flag  := cv_no;
    lt_req_line_id := NULL;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD END   */
--
    BEGIN
      /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD START */
--      FETCH get_ipro_po_data_cur INTO l_get_ipro_po_data_rec;
      FETCH get_ipro_po_data_cur BULK COLLECT INTO l_get_ipro_po_data_tab;
      CLOSE get_ipro_po_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || ' ' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS') ||
                 ''
      );
      -- 処理対象件数格納
      gn_target_cnt := l_get_ipro_po_data_tab.COUNT;
      /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD END   */
    EXCEPTION
      WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      -- エラーメッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_05             -- メッセージコード 
                     ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                     ,iv_token_value1 => cv_work_ipro_po_info         -- トークン値1
                     ,iv_token_name2  => cv_tkn_errmsg                -- トークンコード2
                     ,iv_token_value2 => SQLERRM                      -- トークン値2
                    );
      lv_errbuf  := lv_errmsg;  
     RAISE global_process_expt;
    END;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
    <<get_data_loop>>
    FOR i IN 1..l_get_ipro_po_data_tab.COUNT LOOP
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
      BEGIN
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD START */
--        -- 処理対象件数格納
--        gn_target_cnt := get_ipro_po_data_cur%ROWCOUNT;
--
--        EXIT WHEN get_ipro_po_data_cur%NOTFOUND
--        OR  get_ipro_po_data_cur%ROWCOUNT = 0;
        -- 初期化
        l_get_ipro_po_data_rec   := NULL;
        -- カーソル行のデータ取得
        l_get_ipro_po_data_rec   := l_get_ipro_po_data_tab(i);
        -----------------------
        -- ブレーク判定の処理
        -----------------------
        -- 最終行でない場合
        IF ( gn_target_cnt <> i ) THEN
          -- 次の行から発注依頼明細IDを取得
          lt_req_line_id := l_get_ipro_po_data_tab(i+1).requisition_line_id;
        ELSE
          -- 最終行の場合NULLを設定
          lt_req_line_id := NULL;
        END IF;
        -- 現レコードと次のレコードの発注依頼明細IDを比較しブレーク判定をする
        IF (
             ( l_get_ipro_po_data_rec.requisition_line_id <> lt_req_line_id )
             OR
             ( lt_req_line_id IS NULL )
           ) THEN
          -- 次のレコードでブレークもしくは、最終行
          lb_break_flag:= TRUE;
        END IF;
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD END   */
--
        -- レコード変数初期化
        l_get_data_rec    := NULL;
        /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
        -- 取得したデータキーをログ出力
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => CHR(10) || '抽出データ　' ||
                     cv_log_po_header_num || l_get_ipro_po_data_rec.po_header_num            || ' ' || -- 発注番号
                     cv_log_req_line_num  || l_get_ipro_po_data_rec.req_header_num           || ' ' || -- 発注依頼明細番号
                     cv_log_cust_code     || l_get_ipro_po_data_rec.install_at_customer_code || ' ' || -- 顧客コード
                     cv_log_inst_code1    || l_get_ipro_po_data_rec.install_code1            || ' ' || -- 物件コード1
                     cv_log_inst_code2    || l_get_ipro_po_data_rec.install_code2            || ' ' || -- 物件コード2
                     ''
        );
        /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
        -- 発注依頼明細ID
        ln_rqstn_line_id  := l_get_ipro_po_data_rec.requisition_line_id;
--
        -- *** 取得データ格納 ***
--        

        -- 発注依頼明細ID
        l_get_data_rec.requisition_line_id     := ln_rqstn_line_id;
        -- 伝票枝番
        l_get_data_rec.slip_branch_no          := l_get_ipro_po_data_rec.slip_branch_no;
        -- 作業区分
        l_get_data_rec.job_kbn                 := l_get_ipro_po_data_rec.job_kbn;
        -- 物件コード1
        l_get_data_rec.install_code1           := l_get_ipro_po_data_rec.install_code1;
        -- 機種ID
        l_get_data_rec.un_number_id            := l_get_ipro_po_data_rec.un_number_id;
        -- 物件コード2
        l_get_data_rec.install_code2           := l_get_ipro_po_data_rec.install_code2;
        -- 依頼ルート
        l_get_data_rec.requisition_route       := l_get_ipro_po_data_rec.requisition_route;
        -- 担当営業員コード
        l_get_data_rec.employee_number         := l_get_ipro_po_data_rec.employee_number;
        -- 依頼日
        l_get_data_rec.reqst_date              := l_get_ipro_po_data_rec.reqst_date;
        -- 依頼時間
        l_get_data_rec.reqst_time              := l_get_ipro_po_data_rec.reqst_time;
        -- 作業会社
        l_get_data_rec.work_company_code       := 
           SUBSTR(l_get_ipro_po_data_rec.work_company_code, 1, 6);
        -- 作業会社事業所
        l_get_data_rec.work_location_code      := 
           SUBSTR(l_get_ipro_po_data_rec.work_location_code, 1, 4);
        -- 作業希望日区分
        l_get_data_rec.work_hope_day_type      := cv_work_hope_day_type;
       -- 作業希望日
        l_get_data_rec.work_hope_day           := l_get_ipro_po_data_rec.work_hope_year 
          || l_get_ipro_po_data_rec.work_hope_month
          || l_get_ipro_po_data_rec.work_hope_day;
        -- 作業希望時間区分
        l_get_data_rec.work_hope_time_type     := 
           SUBSTR(l_get_ipro_po_data_rec.work_hope_time_type, cn_1, cn_1);
        -- 作業希望時間
        l_get_data_rec.work_hope_time          := l_get_ipro_po_data_rec.work_hope_time_hour
          || l_get_ipro_po_data_rec.work_hope_time_minute;
        -- 引揚先（搬入先）
        l_get_data_rec.withdraw_company_code   := 
           SUBSTR(l_get_ipro_po_data_rec.withdraw_company_code, 1, 6);
        -- 引揚先（搬入先）事業所
        l_get_data_rec.withdraw_location_code  := 
           SUBSTR(l_get_ipro_po_data_rec.withdraw_location_code, 1, 4);
        -- 引揚機処理区分
        l_get_data_rec.withdraw_process_kbn    := l_get_ipro_po_data_rec.withdraw_process_kbn;
        -- 下見区分
        l_get_data_rec.preview_type            := 
          SUBSTR(l_get_ipro_po_data_rec.preview_type, cn_1, cn_1);
        -- 設置場所区分
        l_get_data_rec.install_place_type      := 
          SUBSTR(l_get_ipro_po_data_rec.install_place_type, cn_1, cn_1);
        -- 設置場所階数
        l_get_data_rec.install_place_floor     := 
          SUBSTR(l_get_ipro_po_data_rec.install_place_floor, 1, 3);
        -- 設置転倒防止
        l_get_data_rec.install_fall_preventn   := 
          SUBSTR(l_get_ipro_po_data_rec.install_fall_preventn, cn_1, cn_1);
        -- 設置段差区分
        l_get_data_rec.install_step_type       := 
          SUBSTR(l_get_ipro_po_data_rec.install_step_type, cn_1, cn_1);
        -- 設置傾斜区分
        l_get_data_rec.install_inct_type       := 
          SUBSTR(l_get_ipro_po_data_rec.install_inclination_type, cn_1, cn_1);
        -- 電気工事区分
        l_get_data_rec.electric_cost_type      := 
          SUBSTR(l_get_ipro_po_data_rec.electric_construction_type, cn_1, cn_1);
        -- 据付面区分
        l_get_data_rec.installed_side_type     := 
          SUBSTR(l_get_ipro_po_data_rec.installed_side_type, cn_1, cn_1);
        -- 搬入段差区分
        l_get_data_rec.import_step_type        := 
          SUBSTR(l_get_ipro_po_data_rec.import_step_type, cn_1, cn_1);
        -- 手上げ区分
        l_get_data_rec.raising_type            := 
          SUBSTR(l_get_ipro_po_data_rec.raising_type, cn_1, cn_1);
        -- 階段昇降機区分
        l_get_data_rec.stairs_lift_type        := 
          SUBSTR(l_get_ipro_po_data_rec.stairs_lift_type, cn_1, cn_1);
        -- エレベータ間口
        l_get_data_rec.elevator_frontage       := 
          SUBSTR(l_get_ipro_po_data_rec.elevator_frontage, 1 ,3);
        -- エレベータ奥行き
        l_get_data_rec.elevator_depth          := 
          SUBSTR(l_get_ipro_po_data_rec.elevator_depth , 1, 3);
        -- エレベータ区分
        l_get_data_rec.elevator_kbn            := cv_kbn_0;
        IF(l_get_ipro_po_data_rec.elevator_frontage IS NOT NULL
             OR l_get_ipro_po_data_rec.elevator_depth IS NOT NULL) THEN
             l_get_data_rec.elevator_kbn            := cv_kbn_1;
        END IF;
        -- ユニック区分
        l_get_data_rec.unic_type               := 
          SUBSTR(l_get_ipro_po_data_rec.unic_type, cn_1, cn_1);
        -- *** 備考 ***
        lv_remarks  := '';
--
        -- コンクリート板
/* 20090709_abe_0000465 START*/
        IF(l_get_ipro_po_data_rec.concrete_board IS NOT NULL
             AND l_get_ipro_po_data_rec.concrete_board = cv_concrete_board) THEN
        --IF(l_get_ipro_po_data_rec.concrete_board IS NOT NULL) THEN
/* 20090709_abe_0000465 END*/
          lv_remarks  := l_get_ipro_po_data_rec.concrete_board;
        END IF;
--
        -- 延長コード区分・延長コード(m)
        IF(l_get_ipro_po_data_rec.extension_code_type IS NOT NULL) THEN
          IF(lv_remarks IS NOT NULL) THEN
            lv_remarks := lv_remarks || cv_zenspace;
          END IF;
          /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
--          lv_remarks := lv_remarks 
--                          || l_get_ipro_po_data_rec.extension_code_type 
--                          || cv_zenspace 
--                          || l_get_ipro_po_data_rec.extension_code_meter;
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.extension_code_type 
--                          || cv_zenspace 
--                          || l_get_ipro_po_data_rec.extension_code_meter,cv_remarks_byte);
          lv_remarks := substrb(lv_remarks 
                          || l_get_ipro_po_data_rec.extension_code_type 
                          || cv_zenspace 
                          || l_get_ipro_po_data_rec.extension_code_meter,1,cv_remarks_byte);
           /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
           /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
        END IF;
--        
        -- 備考１
        IF(l_get_ipro_po_data_rec.remarks1 IS NOT NULL) THEN
          IF(lv_remarks IS NOT NULL) THEN
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
--            lv_remarks := lv_remarks || cv_zenspace;
            /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
            --lv_remarks := substrb(lv_remarks || cv_zenspace,cv_remarks_byte);
            lv_remarks := substrb(lv_remarks || cv_zenspace,1,cv_remarks_byte);
            /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
          END IF;
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
--          lv_remarks := lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks1;
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks1,cv_remarks_byte);
          /* 2011.02.02 N.Horigome E_本稼動_02369対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks1,1,cv_remarks_byte);
          lv_remarks := substrb(lv_remarks 
                          || REPLACE(l_get_ipro_po_data_rec.remarks1,cv_sep_com,cv_sep_punc),1,cv_remarks_byte);
          /* 2011.02.02 N.Horigome E_本稼動_02369対応 END */
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
        END IF;
--        
        -- 備考２
        IF(l_get_ipro_po_data_rec.remarks2 IS NOT NULL) THEN
          IF(lv_remarks IS NOT NULL) THEN
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
--            lv_remarks := lv_remarks || cv_zenspace;
            /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
--            lv_remarks := substrb(lv_remarks || cv_zenspace,cv_remarks_byte);
            lv_remarks := substrb(lv_remarks || cv_zenspace,1,cv_remarks_byte);
            /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
          END IF;
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */          
--          lv_remarks := lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks2;
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks2,cv_remarks_byte);
          /* 2011.02.02 N.Horigome E_本稼動_02369対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks2,1,cv_remarks_byte);
          lv_remarks := substrb(lv_remarks 
                          || REPLACE(l_get_ipro_po_data_rec.remarks2,cv_sep_com,cv_sep_punc),1,cv_remarks_byte);
          /* 2011.02.02 N.Horigome E_本稼動_02369対応 END */
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
        END IF;
--        
        -- 備考３
        IF(l_get_ipro_po_data_rec.remarks3 IS NOT NULL) THEN
          IF(lv_remarks IS NOT NULL) THEN
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */
--            lv_remarks := lv_remarks || cv_zenspace;
            /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
--            lv_remarks := substrb(lv_remarks || cv_zenspace,cv_remarks_byte);
            lv_remarks := substrb(lv_remarks || cv_zenspace,1,cv_remarks_byte);
            /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */
          END IF;
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 START */ 
--          lv_remarks := lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks3;
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks3,cv_remarks_byte);
          /* 2011.02.02 N.Horigome E_本稼動_02369対応 START */
--          lv_remarks := substrb(lv_remarks 
--                          || l_get_ipro_po_data_rec.remarks3,1,cv_remarks_byte);
          lv_remarks := substrb(lv_remarks 
                          || REPLACE(l_get_ipro_po_data_rec.remarks3,cv_sep_com,cv_sep_punc),1,cv_remarks_byte);
          /* 2011.02.02 N.Horigome E_本稼動_02369対応 END */
          /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
            /* 2009.11.27 K.Satomura E_本稼動_00121対応 END */ 
        END IF;
--      
        /* 2010.02.17 T.Maruyama E_本稼動_01603対応 START */
        --l_get_data_rec.remarks                 := lv_remarks;
        l_get_data_rec.remarks                 := SUBSTRB(xxcso_util_common_pkg.conv_ng_char_vdms(
                                                            lv_remarks
                                                          ), 1, cv_remarks_byte);
        /* 2010.02.17 T.Maruyama E_本稼動_01603対応 END */
        -- 作成日時時分秒
        l_get_data_rec.creation_date           := TO_CHAR(ld_sysdate, 'yyyymmddhh24miss');
        -- 更新日時時分秒
        l_get_data_rec.last_update_date        := TO_CHAR(ld_sysdate, 'yyyymmddhh24miss');
        -- 発注番号
        l_get_data_rec.po_header_num           := l_get_ipro_po_data_rec.po_header_num;
        -- 発注明細番号
        l_get_data_rec.po_line_num             := l_get_ipro_po_data_rec.po_line_num;
        -- 発注搬送番号
        l_get_data_rec.po_distribution_num     := l_get_ipro_po_data_rec.po_distribution_num;
        -- 発注依頼番号
        l_get_data_rec.req_header_num          := l_get_ipro_po_data_rec.req_header_num;
        -- 発注依頼明細番号
        l_get_data_rec.req_line_num            := l_get_ipro_po_data_rec.req_line_num;
        -- 顧客コード１
        l_get_data_rec.new_customer_code1      := l_get_ipro_po_data_rec.install_at_customer_code;
        -- 作成者
        l_get_data_rec.created_by              := l_get_ipro_po_data_rec.created_by;
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD START */
        -- リース区分
        l_get_data_rec.lease_kbn               := l_get_ipro_po_data_rec.lease_kbn;
        /* 2014-05-16 Y.Shoji E_本稼動_11853⑥対応 ADD END */
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
        l_get_data_rec.install_type            := l_get_ipro_po_data_rec.install_type;
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
--

        -- ========================================
        -- A-4.作業依頼/発注情報の関連顧客、物件情報抽出処理
        -- ========================================
        get_ipro_po_related_data(
           io_get_data_rec            => l_get_data_rec          -- 出力用作業依頼/発注情報
          ,id_process_date            => ld_process_date         -- 業務処理日
          ,iv_wdrw_base_code          => lv_wdrw_base_code       -- 引揚拠点コード
          /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD START */
          ,iv_org_id                  => ln_org_id               -- 営業単位
          /* 2011-07-08 K.Kiriu E_本稼動_07712対応 ADD END */
          ,ov_errbuf                  => lv_errbuf               -- エラー・メッセージ   --# 固定 #
          ,ov_retcode                 => lv_sub_retcode          -- リターン・コード     --# 固定 #
          ,ov_errmsg                  => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_expt;
        END IF;
--
        -- ========================================
        -- A-5.(更新失敗用)セーブポイント設定
        -- ========================================
        SAVEPOINT reqst_proc_up;
--
        -- ==================================================
        -- A-6.作業依頼／発注情報連携対象テーブル更新処理
        -- ==================================================
        update_wk_requisition_proc(
           i_get_data_rec            => l_get_data_rec           -- 出力用作業依頼/発注情報
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
          ,ib_break_flag              => lb_break_flag           -- ブレークフラグ
          ,iv_error_flag              => lv_error_flag           -- 発注依頼単位エラーフラグ
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
          ,ov_errbuf                  => lv_errbuf               -- エラー・メッセージ   --# 固定 #
          ,ov_retcode                 => lv_sub_retcode          -- リターン・コード     --# 固定 #
          ,ov_errmsg                  => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_expt;
        END IF;
--
        /* 2015-07-27 K.Kiriu E_本稼動_13237対応 ADD START */
        -- 初期化
        ln_po_rec_line_num := NULL;
        /* 2015-07-27 K.Kiriu E_本稼動_13237対応 ADD END   */
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
        -- チェック・更新でエラーが無い場合、発注依頼単位でデータ保持
        l_get_data_tbl(i) := l_get_data_rec;
        -- 発注依頼単位でエラーがない場合、CSVを出力する
        IF ( ( lb_break_flag = TRUE ) AND ( lv_error_flag = cv_no ) ) THEN
          << output_loop >>
          FOR j IN l_get_data_tbl.FIRST..l_get_data_tbl.LAST LOOP
            -- 初期化
            l_get_data_rec := NULL;
            -- 値を設定
            l_get_data_rec := l_get_data_tbl(j);
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
            /* 2015-07-27 K.Kiriu E_本稼動_13237対応 ADD START */
            -- 発注依頼明細番号設定
            IF ( j = l_get_data_tbl.FIRST ) THEN
              -- 発注依頼単位で最初のデータの発注依頼明細番号を保持
              ln_po_rec_line_num := l_get_data_rec.req_line_num;
            ELSE
              -- 発注依頼単位で複数データがある場合は最初の発注依頼明細番号からの連番とする
              ln_po_rec_line_num          := ln_po_rec_line_num + 1;
              l_get_data_rec.req_line_num := ln_po_rec_line_num;
            END IF;
            /* 2015-07-27 K.Kiriu E_本稼動_13237対応 ADD END   */
            -- ========================================
            -- A-7.作業依頼/発注情報データCSV出力
            -- ========================================
            create_csv_rec(
              i_get_data_rec     =>  l_get_data_rec   -- 出力用作業依頼/発注情報
             ,ov_errbuf          =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
             ,ov_retcode         =>  lv_sub_retcode   -- リターン・コード              --# 固定 #
             ,ov_errmsg          =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
            );
            --
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_rollback_upd_flg := TRUE;
              RAISE global_process_expt;
            END IF;
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
          END LOOP output_loop;
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD START */
          -- 正常件数カウントアップ
--          gn_normal_cnt := gn_normal_cnt + 1;
          gn_normal_cnt := gn_normal_cnt + l_get_data_tbl.COUNT;
        END IF;
--
        -- 発注依頼単位の初期化
        IF ( lb_break_flag = TRUE ) THEN
          l_get_data_tbl.DELETE;    -- 発注依頼単位のテーブルクリア
          lb_break_flag := FALSE;   -- ブレーク用フラグ初期化
          lv_error_flag := cv_no;   -- 発注依頼単位エラーフラグ初期化
        END IF;
--
        /* 2015-06-03 K.Kiriu E_本稼動_12984対応 MOD END   */
      EXCEPTION
        -- *** スキップ例外ハンドラ ***
        WHEN global_skip_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
          -- 1発注依頼で最後の行がエラーの場合、発注依頼単位の初期化
          IF ( lb_break_flag = TRUE ) THEN
            l_get_data_tbl.DELETE;    -- 発注依頼単位のテーブルクリア
            lb_break_flag := FALSE;   -- ブレーク用フラグ初期化
            lv_error_flag := cv_no;   -- 発注依頼単位エラーフラグ初期化
          -- 1発注依頼で最後の以外の場合、エラーフラグON
          ELSE
            -- 発注依頼単位エラーフラグON
            lv_error_flag := cv_yes;
          END IF;
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT reqst_proc_up;          -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg11|| CHR(10)
            );
          END IF;
--
        -- *** スキップ例外OTHERSハンドラ ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode   := cv_status_warn;
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD START */
          -- 1発注依頼で最後の行がエラーの場合、発注依頼単位の初期化
          IF ( lb_break_flag = TRUE ) THEN
            l_get_data_tbl.DELETE;    -- 発注依頼単位のテーブルクリア
            lb_break_flag := FALSE;   -- ブレーク用フラグ初期化
            lv_error_flag := cv_no;   -- 発注依頼単位エラーフラグ初期化
          -- 1発注依頼で最後の以外の場合、エラーフラグON
          ELSE
            -- 発注依頼単位エラーフラグON
            lv_error_flag := cv_yes;
          END IF;
          /* 2015-06-03 K.Kiriu E_本稼動_12984対応 ADD END   */
--
          -- ログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf  ||SQLERRM              -- エラーメッセージ
          );
--
          -- ロールバック
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT reqst_proc_up;          -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg11|| CHR(10)
            );
          END IF;
      END;
--
    END LOOP get_data_loop;
--
    ov_retcode   := lv_retcode;
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 DEL START */
--    -- カーソルクローズ
--    CLOSE get_ipro_po_data_cur;
--    -- *** DEBUG_LOG ***
--    -- カーソルクローズしたことをログ出力
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
--                 ''
--    );
    /* 2015-06-03 K.Kiriu E_本稼動_12984対応 DEL END   */
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_17             --メッセージコード
                   );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- エラーメッセージ
          );
    END IF;
    -- ========================================
    -- A-8.CSVファイルクローズ 
    -- ========================================
    close_csv_file(
       iv_csv_dir   => lv_csv_dir   -- CSVファイル出力先
      ,iv_csv_nm    => lv_csv_nm    -- CSVファイル名
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
/*  2008/12/19 指摘より修正
    -- ==================================================
    -- A-9.作業依頼／発注情報連携対象テーブルデータ削除処理
    -- ==================================================
    delete_wk_requisition_proc(
       in_rqstn_line_id     => ln_rqstn_line_id        -- 発注依頼明細ID
      ,id_sys_date          => ld_sysdate              -- システム日付
      ,ov_errbuf            => lv_errbuf               -- エラー・メッセージ   --# 固定 #
      ,ov_retcode           => lv_retcode              -- リターン・コード     --# 固定 #
      ,ov_errmsg            => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
*/
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_ipro_po_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_ipro_po_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err6 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_ipro_po_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_ipro_po_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_ipro_po_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_ipro_po_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT  NOCOPY  VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       ov_retcode => lv_retcode
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
      ov_errbuf   => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode  => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
 --
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-10.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO015A02C;
/
