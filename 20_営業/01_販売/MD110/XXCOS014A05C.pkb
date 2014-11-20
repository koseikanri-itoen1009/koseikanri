CREATE OR REPLACE PACKAGE BODY APPS.XXCOS014A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A05C (body)
 * Description      : 帳票発行画面(アドオン)で指定した条件を元にEDI経由で取り込んだ在庫情報を、
 *                    帳票サーバ向けにファイルを出力します。
 * MD.050           : 在庫情報データ作成 MD050_COS_014_A05
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  proc_init              初期処理(A-1)
 *  proc_out_header_record ヘッダレコード作成処理(A-2)
 *  proc_get_data          データ取得処理(A-3)
 *  proc_out_csv_header    CSVヘッダレコード作成処理(A-4)
 *  proc_out_data_record   データレコード作成処理(A-5)
 *  proc_out_footer_record フッタレコード作成処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   M.Takano         新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *  2009/02/16    1.3   T.Nakamura       [障害COS_079] プロファイル追加、納品拠点情報取得処理改修
 *  2009/02/17    1.4   T.Nakamura       [障害COS_094] CSV出力項目の修正
 *  2009/02/19    1.5   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.6   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/04/02    1.7   T.Kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/05/27    1.8   K.Tsuboi         [T1_1222] 単位の取得元変更
 *  2009/06/18    1.9   T.Kitajima       [T1_1158] 店舗コードNULL対応
 *  2010/03/09    1.10  T.Nakano         [E_本稼動_01695] EDI取込日の変更
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
  ct_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  ct_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt      EXCEPTION;     --ロックエラー
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A05C'; -- パッケージ名
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --アプリケーション名
--
  --プロファイル
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:ヘッダレコード識別子
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:データレコード識別子
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:フッタレコード識別子
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_INV';         --XXCOS:帳票OUTBOUND出力ディレクトリ(EBS在庫管理)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:会社名
  ct_prf_company_name_kana        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME_KANA';            --XXCOS:会社名カナ
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX行サイズ
  ct_prf_organization_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';            --XXCOI:在庫組織コード
  ct_prf_case_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CASE_UOM_CODE';                --XXCOS:ケース単位コード
  ct_prf_bowl_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BALL_UOM_CODE';                --XXCOS:ボール単位コード
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
  --
  --メッセージ
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:ヘッダレコード識別子
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:データレコード識別子
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:フッタレコード識別子
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00112';                    --XXCOS:帳票OUTBOUND出力ディレクトリ
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:会社名
  ct_msg_company_name_kana        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00098';                    --XXCOS:会社名カナ
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX行サイズ
  ct_msg_organization_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00048';                    --XXCOI:在庫組織コード
  ct_msg_case_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00057';                    --XXCOS:ケース単位コード
  ct_msg_bowl_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00059';                    --XXCOS:ボール単位コード

  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --プロファイル取得エラー
  ct_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00063';                    --メッセージ用文字列.在庫組織ID
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --メッセージ用文字列.顧客マスタ
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --メッセージ用文字列.品目マスタ
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --取得エラー
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --マスタ未登録
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13101';                    --パラメータ出力メッセージ1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13102';                    --パラメータ出力メッセージ2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --ファイルオープンエラーメッセージ
  ct_msg_header_type              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00122';                    --メッセージ用文字列.通常受注
  ct_msg_line_type                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00121';                    --メッセージ用文字列.通常出荷
  cv_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --対象データなしメッセージ

  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --ファイル名出力メッセージ
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --メッセージ用文字列.伝票番号
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --メッセージ用文字列.MO:営業単位
-- 2009/02/16 T.Nakamura Ver.1.3 add end
--
  --トークン
  cv_tkn_data                     CONSTANT VARCHAR2(4)   := 'DATA';                               --データ
  cv_tkn_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                              --テーブル
  cv_tkn_prm1                     CONSTANT VARCHAR2(6)   := 'PARAM1';                             --入力パラメータ1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6)   := 'PARAM2';                             --入力パラメータ2
  cv_tkn_prm3                     CONSTANT VARCHAR2(6)   := 'PARAM3';                             --入力パラメータ3
  cv_tkn_prm4                     CONSTANT VARCHAR2(6)   := 'PARAM4';                             --入力パラメータ4
  cv_tkn_prm5                     CONSTANT VARCHAR2(6)   := 'PARAM5';                             --入力パラメータ5
  cv_tkn_prm6                     CONSTANT VARCHAR2(6)   := 'PARAM6';                             --入力パラメータ6
  cv_tkn_prm7                     CONSTANT VARCHAR2(6)   := 'PARAM7';                             --入力パラメータ7
  cv_tkn_prm8                     CONSTANT VARCHAR2(6)   := 'PARAM8';                             --入力パラメータ8
  cv_tkn_prm9                     CONSTANT VARCHAR2(6)   := 'PARAM9';                             --入力パラメータ9
  cv_tkn_prm10                    CONSTANT VARCHAR2(7)   := 'PARAM10';                            --入力パラメータ10
  cv_tkn_prm11                    CONSTANT VARCHAR2(7)   := 'PARAM11';                            --入力パラメータ11
  cv_tkn_prm12                    CONSTANT VARCHAR2(7)   := 'PARAM12';                            --入力パラメータ12
  cv_tkn_prm13                    CONSTANT VARCHAR2(7)   := 'PARAM13';                            --入力パラメータ13
  cv_tkn_prm14                    CONSTANT VARCHAR2(7)   := 'PARAM14';                            --入力パラメータ14
  cv_tkn_prm15                    CONSTANT VARCHAR2(7)   := 'PARAM15';                            --入力パラメータ15
  cv_tkn_prm16                    CONSTANT VARCHAR2(7)   := 'PARAM16';                            --入力パラメータ16
  cv_tkn_prm17                    CONSTANT VARCHAR2(7)   := 'PARAM17';                            --入力パラメータ17
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                          --ファイル名
  cv_tkn_prf                      CONSTANT VARCHAR2(7)   := 'PROFILE';                            --プロファイル
  cv_tkn_order_no                 CONSTANT VARCHAR2(8)   := 'ORDER_NO';                           --伝票番号
  cv_tkn_key                      CONSTANT VARCHAR2(8)   := 'KEY_DATA';                           --キー情報
--
  --その他
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                  --UTL_FILE.オープンモード
  cv_date_fmt                     CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                            --日付書式
  cv_time_fmt                     CONSTANT VARCHAR2(8)  := 'HH24MISS';                            --時刻書式
  cv_cust_class_base              CONSTANT VARCHAR2(1)  := '1';                                   --顧客区分.拠点
  cv_cust_class_chain             CONSTANT VARCHAR2(2)  := '18';                                  --顧客区分.チェーン店
  cv_cust_class_chain_store       CONSTANT VARCHAR2(2)  := '10';                                  --顧客区分.店舗
  cv_cust_class_uesama            CONSTANT VARCHAR2(2)  := '12';                                  --顧客区分.上様
  cv_prod_class_all               CONSTANT VARCHAR2(1)  := '0';                                   --商品区分.全て
  cv_item_div_h_code_A            CONSTANT VARCHAR2(1)  := 'A';                                   --ヘッダコード
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ格納レコード
  TYPE g_input_rtype IS RECORD (
    user_id                  NUMBER                                              --ユーザID
   ,chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE             --EDIチェーン店コード
   ,chain_name               hz_parties.party_name%TYPE                          --EDIチェーン店名
   ,store_code               xxcmm_cust_accounts.store_code%TYPE                 --EDIチェーン店店舗コード
   ,base_code                xxcmm_cust_accounts.delivery_base_code%TYPE         --納品拠点コード
   ,base_name                hz_parties.party_name%TYPE                          --納品拠点名
   ,file_name                VARCHAR2(100)                                       --IFファイル名
   ,data_type_code           xxcos_report_forms_register.data_type_code%TYPE      --帳票種別コード
   ,ebs_business_series_code VARCHAR2(100)                                       --EBS業務系列コード
   ,info_class               VARCHAR2(100)                                       --情報区分
   ,report_code              xxcos_report_forms_register.report_code%TYPE         --帳票コード
   ,report_name              xxcos_report_forms_register.report_name%TYPE         --帳票様式
   ,item_class               VARCHAR2(100)                                       --商品区分
   ,edi_date_from            VARCHAR2(100)                                       --EDI取込日(FROM)
   ,edi_date_to              VARCHAR2(100)                                       --EDI取込日(TO)
  );
--
  --プロファイル値格納レコード
  TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE --ヘッダレコード識別子
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --データレコード識別子
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --フッタレコード識別子
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --出力ディレクトリ
   ,company_name             fnd_profile_option_values.profile_option_value%TYPE --会社名
   ,company_name_kana        fnd_profile_option_values.profile_option_value%TYPE --会社名カナ
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE最大行サイズ
   ,organization_code        fnd_profile_option_values.profile_option_value%TYPE --在庫組織コード
   ,case_uom_code            fnd_profile_option_values.profile_option_value%TYPE --ケース単位コード
   ,bowl_uom_code            fnd_profile_option_values.profile_option_value%TYPE --ボール単位コード
-- 2009/02/16 T.Nakamura Ver.1.3 add start
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
  );
  --納品拠点情報格納レコード
  TYPE g_base_rtype IS RECORD (
    base_name                hz_parties.party_name%TYPE                          --拠点名
   ,base_name_kana           hz_parties.organization_name_phonetic%TYPE          --拠点名カナ
   ,customer_code            xxcmm_cust_accounts.torihikisaki_code%TYPE          --取引先コード
  );
  --EDIチェーン店情報格納レコード
  TYPE g_chain_rtype IS RECORD (
    chain_name               hz_parties.party_name%TYPE                          --EDIチェーン店名
   ,chain_name_kana          hz_parties.organization_name_phonetic%TYPE          --EDIチェーン店名カナ
  );
  --メッセージ情報格納レコード
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,header_type              fnd_new_messages.message_text%TYPE
   ,line_type                fnd_new_messages.message_text%TYPE
  );
  --その他情報格納レコード
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --処理日
   ,proc_time                VARCHAR2(6)                                         --処理時刻
   ,organization_id          NUMBER                                              --在庫組織ID
   ,csv_header               VARCHAR2(32767)                                     --CSVヘッダ
   ,process_date             DATE                                                --業務日付
  );
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gf_file_handle             UTL_FILE.FILE_TYPE;                                 --ファイルハンドル
  g_input_rec                g_input_rtype;                                      --入力パラメータ情報
  g_prf_rec                  g_prf_rtype;                                        --プロファイル情報
  g_base_rec                 g_base_rtype;                                       --納品拠点情報
  g_chain_rec                g_chain_rtype;                                      --EDIチェーン店情報
  g_msg_rec                  g_msg_rtype;                                        --メッセージ情報
  g_other_rec                g_other_rtype;                                      --その他情報
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --レイアウト定義情報
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                    --ダブルクォーテーション
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                    --カンマ
                                                                                 --可変長
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable;
                                                                                 --在庫
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_stock;
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ログ出力
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := false;
  BEGIN
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
--    IF (lv_debug) THEN
--      dbms_output.put_line(buff);
--    ELSE
--      FND_FILE.PUT_LINE(
--         which  => which
--        ,buff   => buff
--      );
--    END IF;
    NULL;
-- 2009/02/13 T.Nakamura Ver.1.2 mod end
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 共通初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- コンカレントプログラム入力項目の出力
    --==============================================================
    --入力パラメータ1～10の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name
                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.chain_name
                                          ,cv_tkn_prm6 , g_input_rec.store_code
                                          ,cv_tkn_prm7 , g_input_rec.base_code
                                          ,cv_tkn_prm8 , g_input_rec.base_name
                                          ,cv_tkn_prm9 , g_input_rec.data_type_code
                                          ,cv_tkn_prm10, g_input_rec.ebs_business_series_code
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --入力パラメータ11～15の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.info_class
                                          ,cv_tkn_prm12, g_input_rec.report_name
                                          ,cv_tkn_prm13, g_input_rec.edi_date_from
                                          ,cv_tkn_prm14, g_input_rec.edi_date_to
                                          ,cv_tkn_prm15, g_input_rec.item_class
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    --==============================================================
    -- 出力ファイル名の出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    cv_apl_name
                   ,ct_msg_file_name
                   ,cv_tkn_filename
                   ,g_input_rec.file_name
                  );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      out_line(buff => cv_prg_name || ct_msg_part || sqlerrm);
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT NOCOPY VARCHAR2        --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2        --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2        --    ユーザー・エラー・メッセージ --# 固定 #
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
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
    lb_error                                 BOOLEAN;                                               --エラー有りフラグ
    lt_tkn                                   fnd_new_messages.message_text%TYPE;                    --メッセージ用文字列
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all                            VARCHAR2(32767);                                       --ログ出力メッセージ格納変数
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_prf_rec g_prf_rtype;
    l_other_rec g_other_rtype;
    l_record_layout_tab xxcos_common2_pkg.g_record_layout_ttype;
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --エラーフラグ初期化
    lb_error := FALSE;
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    --==============================================================
    -- プロファイルの取得(XXCCP:ヘッダレコード識別子)
    --==============================================================
    l_prf_rec.if_header := FND_PROFILE.VALUE(ct_prf_if_header);
    IF (l_prf_rec.if_header IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCCP:データレコード識別子)
    --==============================================================
    l_prf_rec.if_data := FND_PROFILE.VALUE(ct_prf_if_data);
    IF (l_prf_rec.if_data IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_data);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCCP:フッタレコード識別子)
    --==============================================================
    l_prf_rec.if_footer := FND_PROFILE.VALUE(ct_prf_if_footer);
    IF (l_prf_rec.if_footer IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_footer);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:帳票OUTBOUND出力ディレクトリ)
    --==============================================================
    l_prf_rec.rep_outbound_dir := FND_PROFILE.VALUE(ct_prf_rep_outbound_dir);
    IF (l_prf_rec.rep_outbound_dir IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_rep_outbound_dir);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:会社名)
    --==============================================================
    l_prf_rec.company_name := FND_PROFILE.VALUE(ct_prf_company_name);
    IF (l_prf_rec.company_name IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:会社名カナ)
    --==============================================================
    l_prf_rec.company_name_kana := FND_PROFILE.VALUE(ct_prf_company_name_kana);
    IF (l_prf_rec.company_name_kana IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name_kana);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:UTL_MAX行サイズ)
    --==============================================================
    l_prf_rec.utl_max_linesize := FND_PROFILE.VALUE(ct_prf_utl_max_linesize);
    IF (l_prf_rec.utl_max_linesize IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_utl_max_linesize);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    l_prf_rec.organization_code := FND_PROFILE.VALUE(ct_prf_organization_code);
    IF (l_prf_rec.organization_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_organization_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:ケース単位コード)
    --==============================================================
    l_prf_rec.case_uom_code := FND_PROFILE.VALUE(ct_prf_case_uom_code);
    IF (l_prf_rec.case_uom_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_case_uom_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:ボール単位コード)
    --==============================================================
    l_prf_rec.bowl_uom_code := FND_PROFILE.VALUE(ct_prf_bowl_uom_code);
    IF (l_prf_rec.bowl_uom_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_bowl_uom_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--

    --==============================================================
    -- 処理日付、処理時刻の取得
    --==============================================================
    l_other_rec.proc_date := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
    --==============================================================
    -- 在庫組織IDの取得
    --==============================================================
    IF (l_prf_rec.organization_code IS NOT NULL) THEN
      l_other_rec.organization_id := xxcoi_common_pkg.get_organization_id(l_prf_rec.organization_code);
      IF (l_other_rec.organization_id IS NULL) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_org_id);
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_get_err
                      ,cv_tkn_data
                      ,lt_tkn
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      END IF;
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add start
    --==============================================================
    -- プロファイルの取得(MO:営業単位)
    --==============================================================
    l_prf_rec.org_id := FND_PROFILE.VALUE(ct_prf_org_id);
    IF (l_prf_rec.org_id IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_mo_org_id);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add end
    --==============================================================
    --レイアウト定義情報の取得
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      cv_file_format                              --ファイル形式
     ,cv_layout_class                             --レイアウト区分
     ,l_record_layout_tab                         --レイアウト定義情報
     ,l_other_rec.csv_header                      --CSVヘッダ
     ,lv_errbuf                                   --エラーメッセージ
     ,lv_retcode                                  --リターンコード
     ,lv_errmsg                                   --ユーザ・エラーメッセージ
    );
    IF (lv_retcode != cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージの取得
    --==============================================================
    --顧客マスタ未登録メッセージ取得
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cust_master);
    g_msg_rec.customer_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --品目マスタ未登録メッセージ取得
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_item_master);
    g_msg_rec.item_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --==============================================================
    --グローバル変数のセット
    --==============================================================
    g_prf_rec := l_prf_rec;
    g_other_rec := l_other_rec;
    g_record_layout_tab := l_record_layout_tab;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
--      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_header_record
   * Description      : ヘッダレコード作成処理(A-2)
   ***********************************************************************************/
  PROCEDURE proc_out_header_record(
    ov_errbuf     OUT NOCOPY VARCHAR2      --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2      --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2      --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_header_record'; -- プログラム名
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
    lv_if_header VARCHAR2(32767);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          g_prf_rec.rep_outbound_dir
                         ,g_input_rec.file_name
                         ,cv_utl_file_mode
                         ,g_prf_rec.utl_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,g_input_rec.file_name
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- ヘッダレコード設定値取得
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                         --付与区分
     ,g_input_rec.ebs_business_series_code        --ＩＦ元業務系列コード
     ,g_input_rec.base_code                       --拠点コード
     ,g_input_rec.base_name                       --拠点名称
     ,g_input_rec.chain_code                      --チェーン店コード
     ,g_input_rec.chain_name                      --チェーン店名称
     ,g_input_rec.data_type_code                  --データ種コード
     ,g_input_rec.report_code                     --帳票コード
     ,g_input_rec.report_name                     --帳票表示名
     ,g_record_layout_tab.COUNT                   --項目数
     ,NULL                                        --データ件数
     ,lv_retcode                                  --リターンコード
     ,lv_if_header                                --出力値
     ,lv_errbuf                                   --エラーメッセージ
     ,lv_errmsg                                   --ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      RAISE global_api_expt;
    END IF;
--
    out_line(buff => 'if_header:' || lv_if_header);
    --==============================================================
    -- ヘッダレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_if_header);
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_out_header_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_csv_header
   * Description      : CSVヘッダレコード作成処理(A-4)
   ***********************************************************************************/
  PROCEDURE proc_out_csv_header(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_csv_header'; -- プログラム名
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
   lv_csv_header VARCHAR2(32767);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --CSVヘッダレコードの先頭にデータレコード識別子を付加
    lv_csv_header := cv_siege || g_prf_rec.if_data || cv_siege || cv_delimiter ||
                     g_other_rec.csv_header;
--
    --CSVヘッダレコードの出力
    UTL_FILE.PUT_LINE(gf_file_handle, g_other_rec.csv_header);
--
    out_line(buff => cv_prg_name || ' end');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_data_record
   * Description      : データレコード作成処理(A-5)
   ***********************************************************************************/
  PROCEDURE proc_out_data_record(
    i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_data_record'; -- プログラム名
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
    lv_data_record         VARCHAR2(32767);
    lv_table_name  all_tables.table_name%TYPE;
    lv_key_info            VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --データレコード編集
    --==============================================================
    xxcos_common2_pkg.makeup_data_record(
      i_data_tab                --出力データ情報
     ,cv_file_format            --ファイル形式
     ,g_record_layout_tab       --レイアウト定義情報
     ,g_prf_rec.if_data         --データレコード識別子
     ,lv_data_record            --データレコード
     ,lv_errbuf                 --エラーメッセージ
     ,lv_retcode                --リターンコード
     ,lv_errmsg                 --ユーザ・エラーメッセージ
    );
-- 2009/02/20 T.Nakamura Ver.1.6 add start
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.6 add end
--
    --==============================================================
    --データレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_data_record);
--
    --==============================================================
    --レコード件数インクリメント
    --==============================================================
    gn_target_cnt := gn_target_cnt + 1;
    gn_normal_cnt := gn_normal_cnt + 1;
--
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : フッタレコード作成処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_footer_record'; -- プログラム名
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
    lv_footer_record VARCHAR2(32767);
--
    ln_rec_cnt       NUMBER;
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF gn_target_cnt > 0 THEN
      ln_rec_cnt := gn_target_cnt + 1;
    ELSE
      ln_rec_cnt := 0;
    END IF;
--
    --==============================================================
    --フッタレコード取得
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_footer         --付与区分
     ,NULL                        --IF元業務系列コード
     ,NULL                        --拠点コード
     ,NULL                        --拠点名称
     ,NULL                        --チェーン店コード
     ,NULL                        --チェーン店名称
     ,NULL                        --データ種コード
     ,NULL                        --帳票コード
     ,NULL                        --帳票表示名
     ,NULL                        --項目数
     ,ln_rec_cnt                  --レコード件数(+ CSVヘッダレコード)
     ,lv_retcode                  --リターンコード
     ,lv_footer_record            --出力値
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--     ,ov_errbuf                   --エラーメッセージ
--     ,ov_errmsg                   --ユーザ・エラーメッセージ
     ,lv_errbuf
     ,lv_errmsg
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
    );
-- 2009/02/20 T.Nakamura Ver.1.6 add start
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.6 add end
--
    --==============================================================
    --フッタレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle, lv_footer_record);
--
    --==============================================================
    --ファイルクローズ
    --==============================================================
    UTL_FILE.FCLOSE(gf_file_handle);
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_out_footer_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_data(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data'; -- プログラム名
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
    lt_tkn                fnd_new_messages.message_text%TYPE;                 --メッセージ用文字列
    lv_break_key_old                   VARCHAR2(100);                         --旧ブレイクキー
    lv_break_key_new                   VARCHAR2(100);                         --新ブレイクキー
    lt_cust_po_number     oe_order_headers_all.cust_po_number%TYPE;           --受注ヘッダ（顧客発注）
    lt_line_number        oe_order_lines_all.line_number%TYPE;                --受注明細　（明細番号）
    lt_bargain_class                   VARCHAR2(100);
    lt_last_invoice_number             VARCHAR2(100);
    lt_outbound_flag                   VARCHAR2(100);
    lt_last_bargain_class              VARCHAR2(100);
    lb_error                           BOOLEAN;
  --テーブル定義
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;              --出力データ情報
  --
    -- *** ローカル・カーソル ***
    CURSOR cur_data_record(i_input_rec    g_input_rtype
                          ,i_prf_rec      g_prf_rtype
                          ,i_base_rec     g_base_rtype
                          ,i_chain_rec    g_chain_rtype
                          ,i_msg_rec      g_msg_rtype
                          ,i_other_rec    g_other_rtype
    )
    IS
--******************************************* 2009/06/18 1.9 T.Kitajima MOD START *************************************
--      SELECT
--      ------------------------------------------------------ヘッダ情報------------------------------------------------------------
--             xei.medium_class                                                 medium_class                   --媒体区分
--            ,xei.data_type_code                                               data_type_code                 --データ種コード
--            ,xei.file_no                                                      file_no                        --ファイルＮｏ
--            ,xei.info_class                                                   info_class                     --情報区分
--            ,i_other_rec.proc_date                                            process_date                   --処理日
--            ,i_other_rec.proc_time                                            process_time                   --処理時刻
----******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
----            ,i_input_rec.base_code                                              base_code                     --拠点（部門）コード
----            ,i_base_rec.base_name                                               base_name                     --拠点名（正式名）
----            ,i_base_rec.base_name_kana                                          base_name_alt                 --拠点名（カナ）
--            ,cdm.account_number                                                 base_code                     --拠点（部門）コード
--            ,DECODE( cdm.account_number
--                    ,NULL
--                    ,g_msg_rec.customer_notfound
--                    ,cdm.base_name
--             )                                                                  base_name                     --拠点名（正式名）
--            ,cdm.base_name_kana                                                 base_name_alt                 --拠点名（カナ）
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xei.edi_chain_code                                               edi_chain_code                 --ＥＤＩチェーン店コード
--            ,i_chain_rec.chain_name                                           edi_chain_name                 --ＥＤＩチェーン店名（漢字）
--            ,i_chain_rec.chain_name_kana                                      edi_chain_name_alt             --ＥＤＩチェーン店名（カナ）
--            ,i_input_rec.report_code                                          report_code                    --帳票コード
--            ,i_input_rec.report_name                                          report_show_name               --帳票表示名
--            ,hca.account_number                                               customer_code                  --顧客コード
--            ,hp.party_name                                                    customer_name                  --顧客名（漢字）
--            ,hp.organization_name_phonetic                                    customer_name_alt              --顧客名（カナ）
--            ,xei.company_code                                                 company_code                   --社コード
--            ,xei.company_name_alt                                             company_name_alt               --社名（カナ）
--            ,xei.shop_code                                                    shop_code                      --店コード
--            ,NVL2( xei.shop_name_alt
--                  ,xei.shop_name_alt
--                  ,hp.organization_name_phonetic )                            shop_name_alt                  --店名（カナ）
--            ,NVL2( xei.delivery_center_code
--                  ,xei.delivery_center_code
--                  ,xca.deli_center_code )                                     delivery_center_code           --納入センターコード
--            ,NVL2( xei.delivery_center_name
--                  ,xei.delivery_center_name
--                  ,xca.deli_center_name )                                     delivery_center_name           --納入センター名（漢字）
--            ,xei.delivery_center_name_alt                                     delivery_center_name_alt       --納入センター名（カナ）
--            ,xei.whse_code                                                    whse_code                      --倉庫コード
--            ,xei.whse_name                                                    whse_name                      --倉庫名
--            ,xei.inspect_charge_name                                          inspect_charge_name            --検品担当者名（漢字）
--            ,xei.inspect_charge_name_alt                                      inspect_charge_name_alt        --検品担当者名（カナ）
--            ,xei.return_charge_name                                           return_charge_name             --返品担当者名（漢字）
--            ,xei.return_charge_name_alt                                       return_charge_name_alt         --返品担当者名（カナ）
--            ,xei.receive_charge_name                                          receive_charge_name            --受領担当者名（漢字）
--            ,xei.receive_charge_name_alt                                      receive_charge_name_alt        --受領担当者名（カナ）
--            ,TO_CHAR( xei.order_date,cv_date_fmt )                            order_date                     --発注日
--            ,TO_CHAR( xei.center_delivery_date,cv_date_fmt )                  center_delivery_date           --センター納品日
--            ,TO_CHAR( xei.center_result_delivery_date,cv_date_fmt )           center_result_delivery_date    --センター実納品日
--            ,TO_CHAR( xei.center_shipping_date,cv_date_fmt )                  center_shipping_date           --センター出庫日
--            ,TO_CHAR( xei.center_result_shipping_date,cv_date_fmt )           center_result_shipping_date    --センター実出庫日
--            ,TO_CHAR( xei.data_creation_date_edi_data,cv_date_fmt )           data_creation_date_edi_data    --データ作成日（ＥＤＩデータ中）
--            ,xei.data_creation_time_edi_data                                  data_creation_time_edi_data    --データ作成時刻（ＥＤＩデータ中）
--            ,TO_CHAR( xei.stk_date,cv_date_fmt )                              stk_date                       --在庫日付
--            ,xei.offer_vendor_code_class                                      offer_vendor_code_class        --提供企業取引先コード区分
--            ,xei.whse_vendor_code_class                                       whse_vendor_code_class         --倉庫取引先コード区分
--            ,xei.offer_cycle_class                                            offer_cycle_class              --提供サイクル区分
--            ,xei.stk_type                                                     stk_type                       --在庫種類
--            ,xei.japanese_class                                               japanese_class                 --日本語区分
--            ,xei.whse_class                                                   whse_class                     --倉庫区分
--            ,NVL2( xei.vendor_code
--                  ,xei.vendor_code
--                  ,xca.torihikisaki_code )                                    vendor_code                    --取引先コード
----******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
----            ,i_prf_rec.company_name || i_base_rec.base_name                   vendor_name                    --取引先名（漢字）
----            ,NVL2( xei.vendor_name_alt
----                  ,xei.vendor_name_alt
----                  ,i_prf_rec.company_name_kana || i_base_rec.base_name_kana ) vendor_name_alt                --取引先名（カナ）
--            ,i_prf_rec.company_name || cdm.base_name                          vendor_name                    --取引先名（漢字）
--            ,NVL2( xei.vendor_name_alt
--                  ,xei.vendor_name_alt
--                  ,i_prf_rec.company_name_kana || cdm.base_name_kana )        vendor_name_alt                --取引先名（カナ）
----******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
--            ,xei.check_digit_class                                            check_digit_class              --チェックデジット有無区分
--            ,xei.invoice_number                                               invoice_number                 --伝票番号
--            ,xei.check_digit                                                  check_digit                    --チェックデジット
--            ,xei.chain_peculiar_area_header                                   chain_peculiar_area_header     --チェーン店固有エリア（ヘッダ）
--      ------------------------------------------------------明細情報-------------------------------------------------------------
--            ,xei.product_code_itouen                                          product_code_itouen            --商品コード（伊藤園）
--            ,xei.product_code_other_party                                     product_code_other_party       --商品コード（先方）
--            ,CASE
---- 2009/02/17 T.Nakamura Ver.1.4 mod start
----               WHEN ( xei.uom_code  = i_prf_rec.case_uom_code ) THEN
--               WHEN ( xei.ebs_uom_code  = i_prf_rec.case_uom_code ) THEN
---- 2009/02/17 T.Nakamura Ver.1.4 mod end
--                 xsib.case_jan_code
--               ELSE
--                 iimb.attribute21
--             END                                                              jan_code                       --ＪＡＮコード
--            ,iimb.attribute22                                                 itf_code                       --ＩＴＦコード
--            ,NVL( ximb.item_name,i_msg_rec.item_notfound )                    product_name                   --商品名（漢字）
--            --,ximb.item_name                                                   product_name                   --商品名（漢字）
--            ,NVL2( xei.product_name_alt
--                  ,xei.product_name_alt
--                  ,ximb.item_name_alt )                                       product_name_alt               --商品名（カナ）
--            ,xhpcv.item_div_h_code                                            prod_class                     --商品区分
--            ,xei.active_quality_class                                         active_quality_class           --適用品質区分
--            ,xei.qty_in_case                                                  qty_in_case                    --入数
---- 2009/02/17 T.Nakamura Ver.1.4 mod start
----            ,xei.uom_code                                                     uom_code                       --単位
---- 2009/05/27 K.Tsuboi Ver.1.8 mod start
----            ,xei.ebs_uom_code                                                 uom_code                       --単位
--            ,xei.uom_code                                                     uom_code                       --単位
---- 2009/05/27 K.Tsuboi Ver.1.8 mod end
---- 2009/02/17 T.Nakamura Ver.1.4 mod end
--            ,xei.day_average_shipping_qty                                     day_average_shipping_qty       --一日平均出荷数量
--            ,xei.stk_type_code                                                stk_type_code                  --在庫種別コード
--            ,TO_CHAR( xei.last_arrival_date,cv_date_fmt )                     last_arrival_date              --最終入荷日
--            ,TO_CHAR( xei.use_by_date,cv_date_fmt )                           use_by_date                    --賞味期限
--            ,TO_CHAR( xei.product_date,cv_date_fmt )                          product_date                   --製造日
--            ,xei.upper_limit_stk_case                                         upper_limit_stk_case           --上限在庫（ケース）
--            ,xei.upper_limit_stk_indv                                         upper_limit_stk_indv           --上限在庫（バラ）
--            ,xei.indv_order_point                                             indv_order_point               --発注点（バラ）
--            ,xei.case_order_point                                             case_order_point               --発注点（ケース）
--            ,xei.indv_prev_month_stk_qty                                      indv_prev_month_stk_qty        --前月末在庫数量（バラ）
--            ,xei.case_prev_month_stk_qty                                      case_prev_month_stk_qty        --前月末在庫数量（ケース）
--            ,xei.sum_prev_month_stk_qty                                       sum_prev_month_stk_qty         --前月在庫数量（合計）
--            ,xei.day_indv_order_qty                                           day_indv_order_qty             --発注数量（当日、バラ）
--            ,xei.day_case_order_qty                                           day_case_order_qty             --発注数量（当日、ケース）
--            ,xei.day_sum_order_qty                                            day_sum_order_qty              --発注数量（当日、合計）
--            ,xei.month_indv_order_qty                                         month_indv_order_qty           --発注数量（当月、バラ）
--            ,xei.month_case_order_qty                                         month_case_order_qty           --発注数量（当月、ケース）
--            ,xei.month_sum_order_qty                                          month_sum_order_qty            --発注数量（当月、合計）
--            ,xei.day_indv_arrival_qty                                         day_indv_arrival_qty           --入庫数量（当日、バラ）
--            ,xei.day_case_arrival_qty                                         day_case_arrival_qty           --入庫数量（当日、ケース）
--            ,xei.day_sum_arrival_qty                                          day_sum_arrival_qty            --入庫数量（当日、合計）
--            ,xei.month_arrival_count                                          month_arrival_count            --当月入荷回数
--            ,xei.month_indv_arrival_qty                                       month_indv_arrival_qty         --入庫数量（当月、バラ）
--            ,xei.month_case_arrival_qty                                       month_case_arrival_qty         --入庫数量（当月、ケース）
--            ,xei.month_sum_arrival_qty                                        month_sum_arrival_qty          --入庫数量（当月、合計）
--            ,xei.day_indv_shipping_qty                                        day_indv_shipping_qty          --出庫数量（当日、バラ）
--            ,xei.day_case_shipping_qty                                        day_case_shipping_qty          --出庫数量（当日、ケース）
--            ,xei.day_sum_shipping_qty                                         day_sum_shipping_qty           --出庫数量（当日、合計）
--            ,xei.month_indv_shipping_qty                                      month_indv_shipping_qty        --出庫数量（当月、バラ）
--            ,xei.month_case_shipping_qty                                      month_case_shipping_qty        --出庫数量（当月、ケース）
--            ,xei.month_sum_shipping_qty                                       month_sum_shipping_qty         --出庫数量（当月、合計）
--            ,xei.day_indv_destroy_loss_qty                                    day_indv_destroy_loss_qty      --破棄、ロス数量（当日、バラ）
--            ,xei.day_case_destroy_loss_qty                                    day_case_destroy_loss_qty      --破棄、ロス数量（当日、ケース）
--            ,xei.day_sum_destroy_loss_qty                                     day_sum_destroy_loss_qty       --破棄、ロス数量（当日、合計）
--            ,xei.month_indv_destroy_loss_qty                                  month_indv_destroy_loss_qty    --破棄、ロス数量（当月、バラ）
--            ,xei.month_case_destroy_loss_qty                                  month_case_destroy_loss_qty    --破棄、ロス数量（当月、ケース）
--            ,xei.month_sum_destroy_loss_qty                                   month_sum_destroy_loss_qty     --破棄、ロス数量（当月、合計）
--            ,xei.day_indv_defect_stk_qty                                      day_indv_defect_stk_qty        --不良在庫数量（当日、バラ）
--            ,xei.day_case_defect_stk_qty                                      day_case_defect_stk_qty        --不良在庫数量（当日、ケース）
--            ,xei.day_sum_defect_stk_qty                                       day_sum_defect_stk_qty         --不良在庫数量（当日、合計）
--            ,xei.month_indv_defect_stk_qty                                    month_indv_defect_stk_qty      --不良在庫数量（当月、バラ）
--            ,xei.month_case_defect_stk_qty                                    month_case_defect_stk_qty      --不良在庫数量（当月、ケース）
--            ,xei.month_sum_defect_stk_qty                                     month_sum_defect_stk_qty       --不良在庫数量（当月、合計）
--            ,xei.day_indv_defect_return_qty                                   day_indv_defect_return_qty     --不良返品数量（当日、バラ）
--            ,xei.day_case_defect_return_qty                                   day_case_defect_return_qty     --不良返品数量（当日、ケース）
--            ,xei.day_sum_defect_return_qty                                    day_sum_defect_return_qty      --不良返品数量（当日、合計）
--            ,xei.month_indv_defect_return_qty                                 month_indv_defect_return_qty   --不良返品数量（当月、バラ）
--            ,xei.month_case_defect_return_qty                                 month_case_defect_return_qty   --不良返品数量（当月、ケース）
--            ,xei.month_sum_defect_return_qty                                  month_sum_defect_return_qty    --不良返品数量（当月、合計）
--            ,xei.day_indv_defect_return_rcpt                                  day_indv_defect_return_rcpt    --不良返品受入（当日、バラ）
--            ,xei.day_case_defect_return_rcpt                                  day_case_defect_return_rcpt    --不良返品受入（当日、ケース）
--            ,xei.day_sum_defect_return_rcpt                                   day_sum_defect_return_rcpt     --不良返品受入（当日、合計）
--            ,xei.month_indv_defect_return_rcpt                                month_indv_defect_return_rcpt  --不良返品受入（当月、バラ）
--            ,xei.month_case_defect_return_rcpt                                month_case_defect_return_rcpt  --不良返品受入（当月、ケース）
--            ,xei.month_sum_defect_return_rcpt                                 month_sum_defect_return_rcpt   --不良返品受入（当月、合計）
--            ,xei.day_indv_defect_return_send                                  day_indv_defect_return_send    --不良返品発送（当日、バラ）
--            ,xei.day_case_defect_return_send                                  day_case_defect_return_send    --不良返品発送（当日、ケース）
--            ,xei.day_sum_defect_return_send                                   day_sum_defect_return_send     --不良返品発送（当日、合計）
--            ,xei.month_indv_defect_return_send                                month_indv_defect_return_send  --不良返品発送（当月、バラ）
--            ,xei.month_case_defect_return_send                                month_case_defect_return_send  --不良返品発送（当月、ケース）
--            ,xei.month_sum_defect_return_send                                 month_sum_defect_return_send   --不良返品発送（当月、合計）
--            ,xei.day_indv_quality_return_rcpt                                 day_indv_quality_return_rcpt   --良品返品受入（当日、バラ）
--            ,xei.day_case_quality_return_rcpt                                 day_case_quality_return_rcpt   --良品返品受入（当日、ケース）
--            ,xei.day_sum_quality_return_rcpt                                  day_sum_quality_return_rcpt    --良品返品受入（当日、合計）
--            ,xei.month_indv_quality_return_rcpt                               month_indv_quality_return_rcpt --良品返品受入（当月、バラ）
--            ,xei.month_case_quality_return_rcpt                               month_case_quality_return_rcpt --良品返品受入（当月、ケース）
--            ,xei.month_sum_quality_return_rcpt                                month_sum_quality_return_rcpt  --良品返品受入（当月、合計）
--            ,xei.day_indv_quality_return_send                                 day_indv_quality_return_send   --良品返品発送（当日、バラ）
--            ,xei.day_case_quality_return_send                                 day_case_quality_return_send   --良品返品発送（当日、ケース）
--            ,xei.day_sum_quality_return_send                                  day_sum_quality_return_send    --良品返品発送（当日、合計）
--            ,xei.month_indv_quality_return_send                               month_indv_quality_return_send --良品返品発送（当月、バラ）
--            ,xei.month_case_quality_return_send                               month_case_quality_return_send --良品返品発送（当月、ケース）
--            ,xei.month_sum_quality_return_send                                month_sum_quality_return_send  --良品返品発送（当月、合計）
--            ,xei.day_indv_invent_difference                                   day_indv_invent_difference     --棚卸差異（当日、バラ）
--            ,xei.day_case_invent_difference                                   day_case_invent_difference     --棚卸差異（当日、ケース）
--            ,xei.day_sum_invent_difference                                    day_sum_invent_difference      --棚卸差異（当日、合計）
--            ,xei.month_indv_invent_difference                                 month_indv_invent_difference   --棚卸差異（当月、バラ）
--            ,xei.month_case_invent_difference                                 month_case_invent_difference   --棚卸差異（当月、ケース）
--            ,xei.month_sum_invent_difference                                  month_sum_invent_difference    --棚卸差異（当月、合計）
--            ,xei.day_indv_stk_qty                                             day_indv_stk_qty               --在庫数量（当日、バラ）
--            ,xei.day_case_stk_qty                                             day_case_stk_qty               --在庫数量（当日、ケース）
--            ,xei.day_sum_stk_qty                                              day_sum_stk_qty                --在庫数量（当日、合計）
--            ,xei.month_indv_stk_qty                                           month_indv_stk_qty             --在庫数量（当月、バラ）
--            ,xei.month_case_stk_qty                                           month_case_stk_qty             --在庫数量（当月、ケース）
--            ,xei.month_sum_stk_qty                                            month_sum_stk_qty              --在庫数量（当月、合計）
--            ,xei.day_indv_reserved_stk_qty                                    day_indv_reserved_stk_qty      --保留在庫数（当日、バラ）
--            ,xei.day_case_reserved_stk_qty                                    day_case_reserved_stk_qty      --保留在庫数（当日、ケース）
--            ,xei.day_sum_reserved_stk_qty                                     day_sum_reserved_stk_qty       --保留在庫数（当日、合計）
--            ,xei.month_indv_reserved_stk_qty                                  month_indv_reserved_stk_qty    --保留在庫数（当月、バラ）
--            ,xei.month_case_reserved_stk_qty                                  month_case_reserved_stk_qty    --保留在庫数（当月、ケース）
--            ,xei.month_sum_reserved_stk_qty                                   month_sum_reserved_stk_qty     --保留在庫数（当月、合計）
--            ,xei.day_indv_cd_stk_qty                                          day_indv_cd_stk_qty            --商流在庫数量（当日、バラ）
--            ,xei.day_case_cd_stk_qty                                          day_case_cd_stk_qty            --商流在庫数量（当日、ケース）
--            ,xei.day_sum_cd_stk_qty                                           day_sum_cd_stk_qty             --商流在庫数量（当日、合計）
--            ,xei.month_indv_cd_stk_qty                                        month_indv_cd_stk_qty          --商流在庫数量（当月、バラ）
--            ,xei.month_case_cd_stk_qty                                        month_case_cd_stk_qty          --商流在庫数量（当月、ケース）
--            ,xei.month_sum_cd_stk_qty                                         month_sum_cd_stk_qty           --商流在庫数量（当月、合計）
--            ,xei.day_indv_cargo_stk_qty                                       day_indv_cargo_stk_qty         --積送在庫数量（当日、バラ）
--            ,xei.day_case_cargo_stk_qty                                       day_case_cargo_stk_qty         --積送在庫数量（当日、ケース）
--            ,xei.day_sum_cargo_stk_qty                                        day_sum_cargo_stk_qty          --積送在庫数量（当日、合計）
--            ,xei.month_indv_cargo_stk_qty                                     month_indv_cargo_stk_qty       --積送在庫数量（当月、バラ）
--            ,xei.month_case_cargo_stk_qty                                     month_case_cargo_stk_qty       --積送在庫数量（当月、ケース）
--            ,xei.month_sum_cargo_stk_qty                                      month_sum_cargo_stk_qty        --積送在庫数量（当月、合計）
--            ,xei.day_indv_adjustment_stk_qty                                  day_indv_adjustment_stk_qty    --調整在庫数量（当日、バラ）
--            ,xei.day_case_adjustment_stk_qty                                  day_case_adjustment_stk_qty    --調整在庫数量（当日、ケース）
--            ,xei.day_sum_adjustment_stk_qty                                   day_sum_adjustment_stk_qty     --調整在庫数量（当日、合計）
--            ,xei.month_indv_adjustment_stk_qty                                month_indv_adjustment_stk_qty  --調整在庫数量（当月、バラ）
--            ,xei.month_case_adjustment_stk_qty                                month_case_adjustment_stk_qty  --調整在庫数量（当月、ケース）
--            ,xei.month_sum_adjustment_stk_qty                                 month_sum_adjustment_stk_qty   --調整在庫数量（当月、合計）
--            ,xei.day_indv_still_shipping_qty                                  day_indv_still_shipping_qty    --未出荷数量（当日、バラ）
--            ,xei.day_case_still_shipping_qty                                  day_case_still_shipping_qty    --未出荷数量（当日、ケース）
--            ,xei.day_sum_still_shipping_qty                                   day_sum_still_shipping_qty     --未出荷数量（当日、合計）
--            ,xei.month_indv_still_shipping_qty                                month_indv_still_shipping_qty  --未出荷数量（当月、バラ）
--            ,xei.month_case_still_shipping_qty                                month_case_still_shipping_qty  --未出荷数量（当月、ケース）
--            ,xei.month_sum_still_shipping_qty                                 month_sum_still_shipping_qty   --未出荷数量（当月、合計）
--            ,xei.indv_all_stk_qty                                             indv_all_stk_qty               --総在庫数量（バラ）
--            ,xei.case_all_stk_qty                                             case_all_stk_qty               --総在庫数量（ケース）
--            ,xei.sum_all_stk_qty                                              sum_all_stk_qty                --総在庫数量（合計）
--            ,xei.month_draw_count                                             month_draw_count               --当月引当回数
--            ,xei.day_indv_draw_possible_qty                                   day_indv_draw_possible_qty     --引当可能数量（当日、バラ）
--            ,xei.day_case_draw_possible_qty                                   day_case_draw_possible_qty     --引当可能数量（当日、ケース）
--            ,xei.day_sum_draw_possible_qty                                    day_sum_draw_possible_qty      --引当可能数量（当日、合計）
--            ,xei.month_indv_draw_possible_qty                                 month_indv_draw_possible_qty   --引当可能数量（当月、バラ）
--            ,xei.month_case_draw_possible_qty                                 month_case_draw_possible_qty   --引当可能数量（当月、ケース）
--            ,xei.month_sum_draw_possible_qty                                  month_sum_draw_possible_qty    --引当可能数量（当月、合計）
--            ,xei.day_indv_draw_impossible_qty                                 day_indv_draw_impossible_qty   --引当不能数（当日、バラ）
--            ,xei.day_case_draw_impossible_qty                                 day_case_draw_impossible_qty   --引当不能数（当日、ケース）
--            ,xei.day_sum_draw_impossible_qty                                  day_sum_draw_impossible_qty    --引当不能数（当日、合計）
--            ,xei.day_stk_amt                                                  day_stk_amt                    --在庫金額（当日）
--            ,xei.month_stk_amt                                                month_stk_amt                  --在庫金額（当月）
--            ,xei.remarks                                                      remarks                        --備考
--            ,xei.chain_peculiar_area_line                                     chain_peculiar_area_line       --チェーン店固有エリア（明細）
--      ------------------------------------------------------フッタ情報------------------------------------------------------------
--            ,xei.invoice_day_indv_sum_stk_qty                                 invoice_day_indv_sum_stk_qty   --（計）在庫数量合計（当日、バラ）
--            ,xei.invoice_day_case_sum_stk_qty                                 invoice_day_case_sum_stk_qty   --（計）在庫数量合計（当日、ケース）
--            ,xei.invoice_day_sum_sum_stk_qty                                  invoice_day_sum_sum_stk_qty    --（計）在庫数量合計（当日、合計）
--            ,xei.invoice_month_indv_sum_stk_qty                               invoice_month_indv_sum_stk_qty --（計）在庫数量合計（当月、バラ）
--            ,xei.invoice_month_case_sum_stk_qty                               invoice_month_case_sum_stk_qty --（計）在庫数量合計（当月、ケース）
--            ,xei.invoice_month_sum_sum_stk_qty                                invoice_month_sum_sum_stk_qty  --（計）在庫数量合計（当月、合計）
--            ,xei.invoice_day_indv_cd_stk_qty                                  invoice_day_indv_cd_stk_qty    --（計）商流在庫数量（当日、バラ）
--            ,xei.invoice_day_case_cd_stk_qty                                  invoice_day_case_cd_stk_qty    --（計）商流在庫数量（当日、ケース）
--            ,xei.invoice_day_sum_cd_stk_qty                                   invoice_day_sum_cd_stk_qty     --（計）商流在庫数量（当日、合計）
--            ,xei.invoice_month_indv_cd_stk_qty                                invoice_month_indv_cd_stk_qty  --（計）商流在庫数量（当月、バラ）
--            ,xei.invoice_month_case_cd_stk_qty                                invoice_month_case_cd_stk_qty  --（計）商流在庫数量（当月、ケース）
--            ,xei.invoice_month_sum_cd_stk_qty                                 invoice_month_sum_cd_stk_qty   --（計）商流在庫数量（当月、合計）
--            ,xei.invoice_day_stk_amt                                          invoice_day_stk_amt            --（計）在庫金額（当日）
--            ,xei.invoice_month_stk_amt                                        invoice_month_stk_amt          --（計）在庫金額（当月）
--            ,xei.regular_sell_amt_sum                                         regular_sell_amt_sum           --正販金額合計
--            ,xei.rebate_amt_sum                                               rebate_amt_sum                 --割戻し金額合計
--            ,xei.collect_bottle_amt_sum                                       collect_bottle_amt_sum         --回収容器金額合計
--            ,xei.chain_peculiar_area_footer                                   chain_peculiar_area_footer     --チェーン店固有エリア（フッター）
--      --抽出条件
--      FROM   xxcos_edi_inventory                                              xei                            --EDI在庫情報テーブル
--            ,xxcmm_cust_accounts                                              xca                            --顧客マスタアドオン
--            ,hz_cust_accounts                                                 hca                            --顧客マスタ
--            ,hz_parties                                                       hp                             --パーティマスタ
--            ,ic_item_mst_b                                                    iimb                           --OPM品目マスタ
--            ,xxcmn_item_mst_b                                                 ximb                           --OPM品目マスタアドオン
--            ,mtl_system_items_b                                               msib                           --DISC品目マスタ
--            ,xxcmm_system_items_b                                             xsib                           --DISC品目マスタアドオン
--            ,xxcos_head_prod_class_v                                          xhpcv                          --本社商品区分ビュー
--            ,xxcos_chain_store_security_v                                     xcss                           --チェーン店店舗セキュリティビュー
----******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
--            ,(
--              SELECT hca.account_number                                         account_number               --顧客コード
--                    ,hp.party_name                                              base_name                    --顧客名称
--                    ,hp.organization_name_phonetic                              base_name_kana               --顧客名称(カナ)
--              FROM   hz_cust_accounts                                           hca                          --顧客マスタ
--                    ,xxcmm_cust_accounts                                        xca                          --顧客マスタアドオン
--                    ,hz_parties                                                 hp                           --パーティマスタ
--              WHERE  hca.customer_class_code = cv_cust_class_base
--              AND    xca.customer_id         = hca.cust_account_id
--              AND    hp.party_id             = hca.party_id
--             )                                                                  cdm
----******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
--    --EDI在庫情報テーブル
--    WHERE  xei.data_type_code             = i_input_rec.data_type_code                                       --データ種コード
--      AND  ( i_input_rec.info_class        IS NOT NULL                                                       --情報区分
--         AND xei.info_class               = i_input_rec.info_class
--         OR  i_input_rec.info_class        IS NULL
--      )
--      AND  ( xei.edi_chain_code           = i_input_rec.chain_code )                                         --チェーン店コード
----******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
----      AND  ( i_input_rec.store_code        IS NOT NULL                                                       --店舗コード
----         AND  xei.shop_code               = i_input_rec.store_code
----         AND  xei.shop_code = xcss.chain_store_code
----         OR   i_input_rec.store_code       IS NULL
----         AND  xei.shop_code               = xcss.chain_store_code
----      )
--      AND  xei.shop_code                  = NVL( i_input_rec.store_code, xei.shop_code )                     --店舗コード
----******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
--      AND   TRUNC(xei.data_creation_date_edi_data)                                                           --データ作成日
--             BETWEEN TO_DATE(i_input_rec.edi_date_from, cv_date_fmt )
--             AND     TO_DATE(i_input_rec.edi_date_to  , cv_date_fmt )
--      AND  ( i_input_rec.item_class      != cv_prod_class_all                                                --商品区分
--         AND NVL( xhpcv.item_div_h_code,cv_item_div_h_code_A )
--                                          = i_input_rec.item_class
--         OR  i_input_rec.item_class       = cv_prod_class_all )
--    --顧客アドオン
--      AND  xca.chain_store_code(+)        = xei.edi_chain_code                                               --チェーン店コード
--      AND  xca.store_code(+)              = xei.shop_code                                                    --店舗コード
--    --顧客マスタ
--      AND  ( hca.cust_account_id(+)       = xca.customer_id )                                                --顧客ID
--      AND   ( hca.cust_account_id IS NOT NULL
--        AND   hca.customer_class_code IN ( cv_cust_class_chain_store, cv_cust_class_uesama )
--        OR    hca.cust_account_id IS NULL
--             )                                                                                               --顧客区分
--    --パーティマスタ
--      AND hp.party_id(+) = hca.party_id
--    --OPM品目マスタ
--      AND  iimb.item_no(+)                = xei.item_code                                                    --品目コード
--    --OPM品目アドオン
--      AND  ximb.item_id(+)                = iimb.item_id                                                     --品目ID
--      AND  NVL( xei.center_delivery_date
--              ,NVL( xei.order_date
--                   ,data_creation_date_edi_data ) )
--              BETWEEN ( NVL( ximb.start_date_active                                                          --適用開始日
--                                  ,NVL( xei.center_delivery_date
--                                       ,NVL( xei.order_date
--                                             ,data_creation_date_edi_data  ) ) ) )
--              AND     ( NVL( ximb.end_date_active                                                            --適用終了日
--                                   ,NVL( xei.center_delivery_date
--                                         ,NVL( xei.order_date
--                                             ,data_creation_date_edi_data  ) ) ) )
--    --DISC品目マスタ
--      AND  msib.segment1(+)               = xei.item_code
--      AND  msib.organization_id(+)        = i_other_rec.organization_id                                      --在庫組織ID
--    --DISC品目アドオン
--      AND  xsib.item_code(+)              = msib.segment1                                                    --品目コード
--    --商品区分VIEW
--      AND  xhpcv.segment1(+)              = iimb.item_no                                                     --品目ID
--    --店舗セキュリティVIEW
----******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
----      AND  xcss.chain_code                = i_input_rec.chain_code                                         --チェーン店コード
----      AND  xcss.user_id                   = i_input_rec.user_id                                            --ユーザID
--      AND  xcss.chain_code(+)             = xei.edi_chain_code                                               --チェーン店コード
--      AND  xcss.chain_store_code(+)       = xei.shop_code                                                    --店コード
--      AND  xcss.user_id(+)                = i_input_rec.user_id                                              --ユーザID
----******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
----******************************************* 2009/04/02 1.7 T.Kitajima ADD START *************************************
--      AND xca.delivery_base_code          = cdm.account_number(+)
----******************************************* 2009/04/02 1.7 T.Kitajima ADD  END  *************************************
      SELECT
              xei.medium_class                                                 medium_class                   --媒体区分
             ,xei.data_type_code                                               data_type_code                 --データ種コード
             ,xei.file_no                                                      file_no                        --ファイルＮｏ
             ,xei.info_class                                                   info_class                     --情報区分
             ,i_other_rec.proc_date                                            process_date                   --処理日
             ,i_other_rec.proc_time                                            process_time                   --処理時刻
--******************************************* 2009/06/18 1.9 T.Kitajima MOD  START  *************************************
--             ,cdm.account_number                                                 base_code                     --拠点（部門）コード
--             ,DECODE( cdm.account_number
--                     ,NULL
--                     ,g_msg_rec.customer_notfound
--                     ,cdm.base_name
--              )                                                                  base_name                     --拠点名（正式名）
--             ,cdm.base_name_kana                                                 base_name_alt                 --拠点名（カナ）
             ,DECODE( xei.conv_customer_code
                     ,NULL
                     ,i_input_rec.base_code
                     ,cdm.account_number
              )                                                                base_code                      --拠点（部門）コード
             ,CASE
                WHEN ( xei.conv_customer_code IS NULL ) THEN
                  i_input_rec.base_name
                WHEN ( cdm.account_number IS NULL ) THEN
                  g_msg_rec.customer_notfound
                ELSE
                  cdm.base_name
              END                                                              base_name                      --拠点名（正式名）
             ,DECODE( xei.conv_customer_code
                     ,NULL
                     ,i_base_rec.base_name_kana
                     ,cdm.base_name_kana
              )                                                                base_name_alt                  --拠点名（カナ）
--******************************************* 2009/06/18 1.9 T.Kitajima MOD  END    *************************************
             ,xei.edi_chain_code                                               edi_chain_code                 --ＥＤＩチェーン店コード
             ,i_chain_rec.chain_name                                           edi_chain_name                 --ＥＤＩチェーン店名（漢字）
             ,i_chain_rec.chain_name_kana                                      edi_chain_name_alt             --ＥＤＩチェーン店名（カナ）
             ,i_input_rec.report_code                                          report_code                    --帳票コード
             ,i_input_rec.report_name                                          report_show_name               --帳票表示名
             ,xei.account_number                                               customer_code                  --顧客コード
             ,xei.party_name                                                   customer_name                  --顧客名（漢字）
             ,xei.organization_name_phonetic                                   customer_name_alt              --顧客名（カナ）
             ,xei.company_code                                                 company_code                   --社コード
             ,xei.company_name_alt                                             company_name_alt               --社名（カナ）
             ,xei.shop_code                                                    shop_code                      --店コード
             ,NVL2( xei.shop_name_alt
                   ,xei.shop_name_alt
                   ,xei.organization_name_phonetic )                           shop_name_alt                  --店名（カナ）
             ,NVL2( xei.delivery_center_code
                   ,xei.delivery_center_code
                   ,xei.deli_center_code )                                     delivery_center_code           --納入センターコード
             ,NVL2( xei.delivery_center_name
                   ,xei.delivery_center_name
                   ,xei.deli_center_name )                                     delivery_center_name           --納入センター名（漢字）
             ,xei.delivery_center_name_alt                                     delivery_center_name_alt       --納入センター名（カナ）
             ,xei.whse_code                                                    whse_code                      --倉庫コード
             ,xei.whse_name                                                    whse_name                      --倉庫名
             ,xei.inspect_charge_name                                          inspect_charge_name            --検品担当者名（漢字）
             ,xei.inspect_charge_name_alt                                      inspect_charge_name_alt        --検品担当者名（カナ）
             ,xei.return_charge_name                                           return_charge_name             --返品担当者名（漢字）
             ,xei.return_charge_name_alt                                       return_charge_name_alt         --返品担当者名（カナ）
             ,xei.receive_charge_name                                          receive_charge_name            --受領担当者名（漢字）
             ,xei.receive_charge_name_alt                                      receive_charge_name_alt        --受領担当者名（カナ）
             ,TO_CHAR( xei.order_date,cv_date_fmt )                            order_date                     --発注日
             ,TO_CHAR( xei.center_delivery_date,cv_date_fmt )                  center_delivery_date           --センター納品日
             ,TO_CHAR( xei.center_result_delivery_date,cv_date_fmt )           center_result_delivery_date    --センター実納品日
             ,TO_CHAR( xei.center_shipping_date,cv_date_fmt )                  center_shipping_date           --センター出庫日
             ,TO_CHAR( xei.center_result_shipping_date,cv_date_fmt )           center_result_shipping_date    --センター実出庫日
             ,TO_CHAR( xei.data_creation_date_edi_data,cv_date_fmt )           data_creation_date_edi_data    --データ作成日（ＥＤＩデータ中）
             ,xei.data_creation_time_edi_data                                  data_creation_time_edi_data    --データ作成時刻（ＥＤＩデータ中）
             ,TO_CHAR( xei.stk_date,cv_date_fmt )                              stk_date                       --在庫日付
             ,xei.offer_vendor_code_class                                      offer_vendor_code_class        --提供企業取引先コード区分
             ,xei.whse_vendor_code_class                                       whse_vendor_code_class         --倉庫取引先コード区分
             ,xei.offer_cycle_class                                            offer_cycle_class              --提供サイクル区分
             ,xei.stk_type                                                     stk_type                       --在庫種類
             ,xei.japanese_class                                               japanese_class                 --日本語区分
             ,xei.whse_class                                                   whse_class                     --倉庫区分
             ,NVL2( xei.vendor_code
                   ,xei.vendor_code
                   ,xei.torihikisaki_code )                                    vendor_code                    --取引先コード
--******************************************* 2009/06/18 1.9 T.Kitajima MOD  START  *************************************
--             ,i_prf_rec.company_name || cdm.base_name                          vendor_name                    --取引先名（漢字）
             ,DECODE( xei.conv_customer_code
                     ,NULL
                     ,NULL
                     ,i_prf_rec.company_name || cdm.base_name
              )                                                                vendor_name                    --取引先名（漢字）
--******************************************* 2009/06/18 1.9 T.Kitajima MOD  END    *************************************
             ,NVL2( xei.vendor_name_alt
                   ,xei.vendor_name_alt
                   ,i_prf_rec.company_name_kana || cdm.base_name_kana )        vendor_name_alt                --取引先名（カナ）
             ,xei.check_digit_class                                            check_digit_class              --チェックデジット有無区分
             ,xei.invoice_number                                               invoice_number                 --伝票番号
             ,xei.check_digit                                                  check_digit                    --チェックデジット
             ,xei.chain_peculiar_area_header                                   chain_peculiar_area_header     --チェーン店固有エリア（ヘッダ）
       ------------------------------------------------------明細情報-------------------------------------------------------------
             ,xei.product_code_itouen                                          product_code_itouen            --商品コード（伊藤園）
             ,xei.product_code_other_party                                     product_code_other_party       --商品コード（先方）
             ,CASE
                WHEN ( xei.ebs_uom_code  = i_prf_rec.case_uom_code ) THEN
                  xsib.case_jan_code
                ELSE
                  iimb.attribute21
              END                                                              jan_code                       --ＪＡＮコード
             ,iimb.attribute22                                                 itf_code                       --ＩＴＦコード
             ,NVL( ximb.item_name,i_msg_rec.item_notfound )                    product_name                   --商品名（漢字）
             ,NVL2( xei.product_name_alt
                   ,xei.product_name_alt
                   ,ximb.item_name_alt )                                       product_name_alt               --商品名（カナ）
             ,xhpcv.item_div_h_code                                            prod_class                     --商品区分
             ,xei.active_quality_class                                         active_quality_class           --適用品質区分
             ,xei.qty_in_case                                                  qty_in_case                    --入数
             ,xei.uom_code                                                     uom_code                       --単位
             ,xei.day_average_shipping_qty                                     day_average_shipping_qty       --一日平均出荷数量
             ,xei.stk_type_code                                                stk_type_code                  --在庫種別コード
             ,TO_CHAR( xei.last_arrival_date,cv_date_fmt )                     last_arrival_date              --最終入荷日
             ,TO_CHAR( xei.use_by_date,cv_date_fmt )                           use_by_date                    --賞味期限
             ,TO_CHAR( xei.product_date,cv_date_fmt )                          product_date                   --製造日
             ,xei.upper_limit_stk_case                                         upper_limit_stk_case           --上限在庫（ケース）
             ,xei.upper_limit_stk_indv                                         upper_limit_stk_indv           --上限在庫（バラ）
             ,xei.indv_order_point                                             indv_order_point               --発注点（バラ）
             ,xei.case_order_point                                             case_order_point               --発注点（ケース）
             ,xei.indv_prev_month_stk_qty                                      indv_prev_month_stk_qty        --前月末在庫数量（バラ）
             ,xei.case_prev_month_stk_qty                                      case_prev_month_stk_qty        --前月末在庫数量（ケース）
             ,xei.sum_prev_month_stk_qty                                       sum_prev_month_stk_qty         --前月在庫数量（合計）
             ,xei.day_indv_order_qty                                           day_indv_order_qty             --発注数量（当日、バラ）
             ,xei.day_case_order_qty                                           day_case_order_qty             --発注数量（当日、ケース）
             ,xei.day_sum_order_qty                                            day_sum_order_qty              --発注数量（当日、合計）
             ,xei.month_indv_order_qty                                         month_indv_order_qty           --発注数量（当月、バラ）
             ,xei.month_case_order_qty                                         month_case_order_qty           --発注数量（当月、ケース）
             ,xei.month_sum_order_qty                                          month_sum_order_qty            --発注数量（当月、合計）
             ,xei.day_indv_arrival_qty                                         day_indv_arrival_qty           --入庫数量（当日、バラ）
             ,xei.day_case_arrival_qty                                         day_case_arrival_qty           --入庫数量（当日、ケース）
             ,xei.day_sum_arrival_qty                                          day_sum_arrival_qty            --入庫数量（当日、合計）
             ,xei.month_arrival_count                                          month_arrival_count            --当月入荷回数
             ,xei.month_indv_arrival_qty                                       month_indv_arrival_qty         --入庫数量（当月、バラ）
             ,xei.month_case_arrival_qty                                       month_case_arrival_qty         --入庫数量（当月、ケース）
             ,xei.month_sum_arrival_qty                                        month_sum_arrival_qty          --入庫数量（当月、合計）
             ,xei.day_indv_shipping_qty                                        day_indv_shipping_qty          --出庫数量（当日、バラ）
             ,xei.day_case_shipping_qty                                        day_case_shipping_qty          --出庫数量（当日、ケース）
             ,xei.day_sum_shipping_qty                                         day_sum_shipping_qty           --出庫数量（当日、合計）
             ,xei.month_indv_shipping_qty                                      month_indv_shipping_qty        --出庫数量（当月、バラ）
             ,xei.month_case_shipping_qty                                      month_case_shipping_qty        --出庫数量（当月、ケース）
             ,xei.month_sum_shipping_qty                                       month_sum_shipping_qty         --出庫数量（当月、合計）
             ,xei.day_indv_destroy_loss_qty                                    day_indv_destroy_loss_qty      --破棄、ロス数量（当日、バラ）
             ,xei.day_case_destroy_loss_qty                                    day_case_destroy_loss_qty      --破棄、ロス数量（当日、ケース）
             ,xei.day_sum_destroy_loss_qty                                     day_sum_destroy_loss_qty       --破棄、ロス数量（当日、合計）
             ,xei.month_indv_destroy_loss_qty                                  month_indv_destroy_loss_qty    --破棄、ロス数量（当月、バラ）
             ,xei.month_case_destroy_loss_qty                                  month_case_destroy_loss_qty    --破棄、ロス数量（当月、ケース）
             ,xei.month_sum_destroy_loss_qty                                   month_sum_destroy_loss_qty     --破棄、ロス数量（当月、合計）
             ,xei.day_indv_defect_stk_qty                                      day_indv_defect_stk_qty        --不良在庫数量（当日、バラ）
             ,xei.day_case_defect_stk_qty                                      day_case_defect_stk_qty        --不良在庫数量（当日、ケース）
             ,xei.day_sum_defect_stk_qty                                       day_sum_defect_stk_qty         --不良在庫数量（当日、合計）
             ,xei.month_indv_defect_stk_qty                                    month_indv_defect_stk_qty      --不良在庫数量（当月、バラ）
             ,xei.month_case_defect_stk_qty                                    month_case_defect_stk_qty      --不良在庫数量（当月、ケース）
             ,xei.month_sum_defect_stk_qty                                     month_sum_defect_stk_qty       --不良在庫数量（当月、合計）
             ,xei.day_indv_defect_return_qty                                   day_indv_defect_return_qty     --不良返品数量（当日、バラ）
             ,xei.day_case_defect_return_qty                                   day_case_defect_return_qty     --不良返品数量（当日、ケース）
             ,xei.day_sum_defect_return_qty                                    day_sum_defect_return_qty      --不良返品数量（当日、合計）
             ,xei.month_indv_defect_return_qty                                 month_indv_defect_return_qty   --不良返品数量（当月、バラ）
             ,xei.month_case_defect_return_qty                                 month_case_defect_return_qty   --不良返品数量（当月、ケース）
             ,xei.month_sum_defect_return_qty                                  month_sum_defect_return_qty    --不良返品数量（当月、合計）
             ,xei.day_indv_defect_return_rcpt                                  day_indv_defect_return_rcpt    --不良返品受入（当日、バラ）
             ,xei.day_case_defect_return_rcpt                                  day_case_defect_return_rcpt    --不良返品受入（当日、ケース）
             ,xei.day_sum_defect_return_rcpt                                   day_sum_defect_return_rcpt     --不良返品受入（当日、合計）
             ,xei.month_indv_defect_return_rcpt                                month_indv_defect_return_rcpt  --不良返品受入（当月、バラ）
             ,xei.month_case_defect_return_rcpt                                month_case_defect_return_rcpt  --不良返品受入（当月、ケース）
             ,xei.month_sum_defect_return_rcpt                                 month_sum_defect_return_rcpt   --不良返品受入（当月、合計）
             ,xei.day_indv_defect_return_send                                  day_indv_defect_return_send    --不良返品発送（当日、バラ）
             ,xei.day_case_defect_return_send                                  day_case_defect_return_send    --不良返品発送（当日、ケース）
             ,xei.day_sum_defect_return_send                                   day_sum_defect_return_send     --不良返品発送（当日、合計）
             ,xei.month_indv_defect_return_send                                month_indv_defect_return_send  --不良返品発送（当月、バラ）
             ,xei.month_case_defect_return_send                                month_case_defect_return_send  --不良返品発送（当月、ケース）
             ,xei.month_sum_defect_return_send                                 month_sum_defect_return_send   --不良返品発送（当月、合計）
             ,xei.day_indv_quality_return_rcpt                                 day_indv_quality_return_rcpt   --良品返品受入（当日、バラ）
             ,xei.day_case_quality_return_rcpt                                 day_case_quality_return_rcpt   --良品返品受入（当日、ケース）
             ,xei.day_sum_quality_return_rcpt                                  day_sum_quality_return_rcpt    --良品返品受入（当日、合計）
             ,xei.month_indv_quality_return_rcpt                               month_indv_quality_return_rcpt --良品返品受入（当月、バラ）
             ,xei.month_case_quality_return_rcpt                               month_case_quality_return_rcpt --良品返品受入（当月、ケース）
             ,xei.month_sum_quality_return_rcpt                                month_sum_quality_return_rcpt  --良品返品受入（当月、合計）
             ,xei.day_indv_quality_return_send                                 day_indv_quality_return_send   --良品返品発送（当日、バラ）
             ,xei.day_case_quality_return_send                                 day_case_quality_return_send   --良品返品発送（当日、ケース）
             ,xei.day_sum_quality_return_send                                  day_sum_quality_return_send    --良品返品発送（当日、合計）
             ,xei.month_indv_quality_return_send                               month_indv_quality_return_send --良品返品発送（当月、バラ）
             ,xei.month_case_quality_return_send                               month_case_quality_return_send --良品返品発送（当月、ケース）
             ,xei.month_sum_quality_return_send                                month_sum_quality_return_send  --良品返品発送（当月、合計）
             ,xei.day_indv_invent_difference                                   day_indv_invent_difference     --棚卸差異（当日、バラ）
             ,xei.day_case_invent_difference                                   day_case_invent_difference     --棚卸差異（当日、ケース）
             ,xei.day_sum_invent_difference                                    day_sum_invent_difference      --棚卸差異（当日、合計）
             ,xei.month_indv_invent_difference                                 month_indv_invent_difference   --棚卸差異（当月、バラ）
             ,xei.month_case_invent_difference                                 month_case_invent_difference   --棚卸差異（当月、ケース）
             ,xei.month_sum_invent_difference                                  month_sum_invent_difference    --棚卸差異（当月、合計）
             ,xei.day_indv_stk_qty                                             day_indv_stk_qty               --在庫数量（当日、バラ）
             ,xei.day_case_stk_qty                                             day_case_stk_qty               --在庫数量（当日、ケース）
             ,xei.day_sum_stk_qty                                              day_sum_stk_qty                --在庫数量（当日、合計）
             ,xei.month_indv_stk_qty                                           month_indv_stk_qty             --在庫数量（当月、バラ）
             ,xei.month_case_stk_qty                                           month_case_stk_qty             --在庫数量（当月、ケース）
             ,xei.month_sum_stk_qty                                            month_sum_stk_qty              --在庫数量（当月、合計）
             ,xei.day_indv_reserved_stk_qty                                    day_indv_reserved_stk_qty      --保留在庫数（当日、バラ）
             ,xei.day_case_reserved_stk_qty                                    day_case_reserved_stk_qty      --保留在庫数（当日、ケース）
             ,xei.day_sum_reserved_stk_qty                                     day_sum_reserved_stk_qty       --保留在庫数（当日、合計）
             ,xei.month_indv_reserved_stk_qty                                  month_indv_reserved_stk_qty    --保留在庫数（当月、バラ）
             ,xei.month_case_reserved_stk_qty                                  month_case_reserved_stk_qty    --保留在庫数（当月、ケース）
             ,xei.month_sum_reserved_stk_qty                                   month_sum_reserved_stk_qty     --保留在庫数（当月、合計）
             ,xei.day_indv_cd_stk_qty                                          day_indv_cd_stk_qty            --商流在庫数量（当日、バラ）
             ,xei.day_case_cd_stk_qty                                          day_case_cd_stk_qty            --商流在庫数量（当日、ケース）
             ,xei.day_sum_cd_stk_qty                                           day_sum_cd_stk_qty             --商流在庫数量（当日、合計）
             ,xei.month_indv_cd_stk_qty                                        month_indv_cd_stk_qty          --商流在庫数量（当月、バラ）
             ,xei.month_case_cd_stk_qty                                        month_case_cd_stk_qty          --商流在庫数量（当月、ケース）
             ,xei.month_sum_cd_stk_qty                                         month_sum_cd_stk_qty           --商流在庫数量（当月、合計）
             ,xei.day_indv_cargo_stk_qty                                       day_indv_cargo_stk_qty         --積送在庫数量（当日、バラ）
             ,xei.day_case_cargo_stk_qty                                       day_case_cargo_stk_qty         --積送在庫数量（当日、ケース）
             ,xei.day_sum_cargo_stk_qty                                        day_sum_cargo_stk_qty          --積送在庫数量（当日、合計）
             ,xei.month_indv_cargo_stk_qty                                     month_indv_cargo_stk_qty       --積送在庫数量（当月、バラ）
             ,xei.month_case_cargo_stk_qty                                     month_case_cargo_stk_qty       --積送在庫数量（当月、ケース）
             ,xei.month_sum_cargo_stk_qty                                      month_sum_cargo_stk_qty        --積送在庫数量（当月、合計）
             ,xei.day_indv_adjustment_stk_qty                                  day_indv_adjustment_stk_qty    --調整在庫数量（当日、バラ）
             ,xei.day_case_adjustment_stk_qty                                  day_case_adjustment_stk_qty    --調整在庫数量（当日、ケース）
             ,xei.day_sum_adjustment_stk_qty                                   day_sum_adjustment_stk_qty     --調整在庫数量（当日、合計）
             ,xei.month_indv_adjustment_stk_qty                                month_indv_adjustment_stk_qty  --調整在庫数量（当月、バラ）
             ,xei.month_case_adjustment_stk_qty                                month_case_adjustment_stk_qty  --調整在庫数量（当月、ケース）
             ,xei.month_sum_adjustment_stk_qty                                 month_sum_adjustment_stk_qty   --調整在庫数量（当月、合計）
             ,xei.day_indv_still_shipping_qty                                  day_indv_still_shipping_qty    --未出荷数量（当日、バラ）
             ,xei.day_case_still_shipping_qty                                  day_case_still_shipping_qty    --未出荷数量（当日、ケース）
             ,xei.day_sum_still_shipping_qty                                   day_sum_still_shipping_qty     --未出荷数量（当日、合計）
             ,xei.month_indv_still_shipping_qty                                month_indv_still_shipping_qty  --未出荷数量（当月、バラ）
             ,xei.month_case_still_shipping_qty                                month_case_still_shipping_qty  --未出荷数量（当月、ケース）
             ,xei.month_sum_still_shipping_qty                                 month_sum_still_shipping_qty   --未出荷数量（当月、合計）
             ,xei.indv_all_stk_qty                                             indv_all_stk_qty               --総在庫数量（バラ）
             ,xei.case_all_stk_qty                                             case_all_stk_qty               --総在庫数量（ケース）
             ,xei.sum_all_stk_qty                                              sum_all_stk_qty                --総在庫数量（合計）
             ,xei.month_draw_count                                             month_draw_count               --当月引当回数
             ,xei.day_indv_draw_possible_qty                                   day_indv_draw_possible_qty     --引当可能数量（当日、バラ）
             ,xei.day_case_draw_possible_qty                                   day_case_draw_possible_qty     --引当可能数量（当日、ケース）
             ,xei.day_sum_draw_possible_qty                                    day_sum_draw_possible_qty      --引当可能数量（当日、合計）
             ,xei.month_indv_draw_possible_qty                                 month_indv_draw_possible_qty   --引当可能数量（当月、バラ）
             ,xei.month_case_draw_possible_qty                                 month_case_draw_possible_qty   --引当可能数量（当月、ケース）
             ,xei.month_sum_draw_possible_qty                                  month_sum_draw_possible_qty    --引当可能数量（当月、合計）
             ,xei.day_indv_draw_impossible_qty                                 day_indv_draw_impossible_qty   --引当不能数（当日、バラ）
             ,xei.day_case_draw_impossible_qty                                 day_case_draw_impossible_qty   --引当不能数（当日、ケース）
             ,xei.day_sum_draw_impossible_qty                                  day_sum_draw_impossible_qty    --引当不能数（当日、合計）
             ,xei.day_stk_amt                                                  day_stk_amt                    --在庫金額（当日）
             ,xei.month_stk_amt                                                month_stk_amt                  --在庫金額（当月）
             ,xei.remarks                                                      remarks                        --備考
             ,xei.chain_peculiar_area_line                                     chain_peculiar_area_line       --チェーン店固有エリア（明細）
       ------------------------------------------------------フッタ情報------------------------------------------------------------
             ,xei.invoice_day_indv_sum_stk_qty                                 invoice_day_indv_sum_stk_qty   --（計）在庫数量合計（当日、バラ）
             ,xei.invoice_day_case_sum_stk_qty                                 invoice_day_case_sum_stk_qty   --（計）在庫数量合計（当日、ケース）
             ,xei.invoice_day_sum_sum_stk_qty                                  invoice_day_sum_sum_stk_qty    --（計）在庫数量合計（当日、合計）
             ,xei.invoice_month_indv_sum_stk_qty                               invoice_month_indv_sum_stk_qty --（計）在庫数量合計（当月、バラ）
             ,xei.invoice_month_case_sum_stk_qty                               invoice_month_case_sum_stk_qty --（計）在庫数量合計（当月、ケース）
             ,xei.invoice_month_sum_sum_stk_qty                                invoice_month_sum_sum_stk_qty  --（計）在庫数量合計（当月、合計）
             ,xei.invoice_day_indv_cd_stk_qty                                  invoice_day_indv_cd_stk_qty    --（計）商流在庫数量（当日、バラ）
             ,xei.invoice_day_case_cd_stk_qty                                  invoice_day_case_cd_stk_qty    --（計）商流在庫数量（当日、ケース）
             ,xei.invoice_day_sum_cd_stk_qty                                   invoice_day_sum_cd_stk_qty     --（計）商流在庫数量（当日、合計）
             ,xei.invoice_month_indv_cd_stk_qty                                invoice_month_indv_cd_stk_qty  --（計）商流在庫数量（当月、バラ）
             ,xei.invoice_month_case_cd_stk_qty                                invoice_month_case_cd_stk_qty  --（計）商流在庫数量（当月、ケース）
             ,xei.invoice_month_sum_cd_stk_qty                                 invoice_month_sum_cd_stk_qty   --（計）商流在庫数量（当月、合計）
             ,xei.invoice_day_stk_amt                                          invoice_day_stk_amt            --（計）在庫金額（当日）
             ,xei.invoice_month_stk_amt                                        invoice_month_stk_amt          --（計）在庫金額（当月）
             ,xei.regular_sell_amt_sum                                         regular_sell_amt_sum           --正販金額合計
             ,xei.rebate_amt_sum                                               rebate_amt_sum                 --割戻し金額合計
             ,xei.collect_bottle_amt_sum                                       collect_bottle_amt_sum         --回収容器金額合計
             ,xei.chain_peculiar_area_footer                                   chain_peculiar_area_footer     --チェーン店固有エリア（フッター）
        --抽出条件
        FROM 
             (
               SELECT 1                                                        select_block
                      ,xei.medium_class                                        medium_class                   --媒体区分
                      ,xei.data_type_code                                      data_type_code                 --データ種コード
                      ,xei.file_no                                             file_no                        --ファイルＮｏ
                      ,xei.info_class                                          info_class                     --情報区分
                      ,xei.edi_chain_code                                      edi_chain_code                 --ＥＤＩチェーン店コード
                      ,xei.company_code                                        company_code                   --社コード
                      ,xei.company_name_alt                                    company_name_alt               --社名（カナ）
                      ,xei.shop_code                                           shop_code                      --店コード
                      ,xei.shop_name_alt                                       shop_name_alt                  --店名（カナ）
                      ,xei.delivery_center_code                                delivery_center_code           --納入センターコード
                      ,xei.delivery_center_name                                delivery_center_name           --納入センター名（漢字）
                      ,xei.delivery_center_name_alt                            delivery_center_name_alt       --納入センター名（カナ）
                      ,xei.whse_code                                           whse_code                      --倉庫コード
                      ,xei.whse_name                                           whse_name                      --倉庫名
                      ,xei.inspect_charge_name                                 inspect_charge_name            --検品担当者名（漢字）
                      ,xei.inspect_charge_name_alt                             inspect_charge_name_alt        --検品担当者名（カナ）
                      ,xei.return_charge_name                                  return_charge_name             --返品担当者名（漢字）
                      ,xei.return_charge_name_alt                              return_charge_name_alt         --返品担当者名（カナ）
                      ,xei.receive_charge_name                                 receive_charge_name            --受領担当者名（漢字）
                      ,xei.receive_charge_name_alt                             receive_charge_name_alt        --受領担当者名（カナ）
                      ,xei.order_date                                          order_date                     --発注日
                      ,xei.center_delivery_date                                center_delivery_date           --センター納品日
                      ,xei.center_result_delivery_date                         center_result_delivery_date    --センター実納品日
                      ,xei.center_shipping_date                                center_shipping_date           --センター出庫日
                      ,xei.center_result_shipping_date                         center_result_shipping_date    --センター実出庫日
                      ,xei.data_creation_date_edi_data                         data_creation_date_edi_data    --データ作成日（ＥＤＩデータ中）
----******************************************* 2010/03/09 1.10 T.Nakano UPD START *************************************
                      ,xei.edi_received_date                                   edi_received_date              --EDI受信日
----******************************************* 2010/03/09 1.10 T.Nakano UPD END *************************************
                      ,xei.data_creation_time_edi_data                         data_creation_time_edi_data    --データ作成時刻（ＥＤＩデータ中）
                      ,xei.stk_date                                            stk_date                       --在庫日付
                      ,xei.offer_vendor_code_class                             offer_vendor_code_class        --提供企業取引先コード区分
                      ,xei.whse_vendor_code_class                              whse_vendor_code_class         --倉庫取引先コード区分
                      ,xei.offer_cycle_class                                   offer_cycle_class              --提供サイクル区分
                      ,xei.stk_type                                            stk_type                       --在庫種類
                      ,xei.japanese_class                                      japanese_class                 --日本語区分
                      ,xei.whse_class                                          whse_class                     --倉庫区分
                      ,xei.vendor_code                                         vendor_code                    --取引先コード
                      ,xei.vendor_name_alt                                     vendor_name_alt                --取引先名（カナ）
                      ,xei.check_digit_class                                   check_digit_class              --チェックデジット有無区分
                      ,xei.invoice_number                                      invoice_number                 --伝票番号
                      ,xei.check_digit                                         check_digit                    --チェックデジット
                      ,xei.chain_peculiar_area_header                          chain_peculiar_area_header     --チェーン店固有エリア（ヘッダ）
                      ,xei.product_code_itouen                                 product_code_itouen            --商品コード（伊藤園）
                      ,xei.product_code_other_party                            product_code_other_party       --商品コード（先方）
                      ,xei.ebs_uom_code                                        ebs_uom_code                   --単位コード(EBS)
                      ,xei.product_name_alt                                    product_name_alt               --商品名（カナ）
                      ,xei.active_quality_class                                active_quality_class           --適用品質区分
                      ,xei.qty_in_case                                         qty_in_case                    --入数
                      ,xei.uom_code                                            uom_code                       --単位
                      ,xei.day_average_shipping_qty                            day_average_shipping_qty       --一日平均出荷数量
                      ,xei.stk_type_code                                       stk_type_code                  --在庫種別コード
                      ,xei.last_arrival_date                                   last_arrival_date              --最終入荷日
                      ,xei.use_by_date                                         use_by_date                    --賞味期限
                      ,xei.product_date                                        product_date                   --製造日
                      ,xei.upper_limit_stk_case                                upper_limit_stk_case           --上限在庫（ケース）
                      ,xei.upper_limit_stk_indv                                upper_limit_stk_indv           --上限在庫（バラ）
                      ,xei.indv_order_point                                    indv_order_point               --発注点（バラ）
                      ,xei.case_order_point                                    case_order_point               --発注点（ケース）
                      ,xei.indv_prev_month_stk_qty                             indv_prev_month_stk_qty        --前月末在庫数量（バラ）
                      ,xei.case_prev_month_stk_qty                             case_prev_month_stk_qty        --前月末在庫数量（ケース）
                      ,xei.sum_prev_month_stk_qty                              sum_prev_month_stk_qty         --前月在庫数量（合計）
                      ,xei.day_indv_order_qty                                  day_indv_order_qty             --発注数量（当日、バラ）
                      ,xei.day_case_order_qty                                  day_case_order_qty             --発注数量（当日、ケース）
                      ,xei.day_sum_order_qty                                   day_sum_order_qty              --発注数量（当日、合計）
                      ,xei.month_indv_order_qty                                month_indv_order_qty           --発注数量（当月、バラ）
                      ,xei.month_case_order_qty                                month_case_order_qty           --発注数量（当月、ケース）
                      ,xei.month_sum_order_qty                                 month_sum_order_qty            --発注数量（当月、合計）
                      ,xei.day_indv_arrival_qty                                day_indv_arrival_qty           --入庫数量（当日、バラ）
                      ,xei.day_case_arrival_qty                                day_case_arrival_qty           --入庫数量（当日、ケース）
                      ,xei.day_sum_arrival_qty                                 day_sum_arrival_qty            --入庫数量（当日、合計）
                      ,xei.month_arrival_count                                 month_arrival_count            --当月入荷回数
                      ,xei.month_indv_arrival_qty                              month_indv_arrival_qty         --入庫数量（当月、バラ）
                      ,xei.month_case_arrival_qty                              month_case_arrival_qty         --入庫数量（当月、ケース）
                      ,xei.month_sum_arrival_qty                               month_sum_arrival_qty          --入庫数量（当月、合計）
                      ,xei.day_indv_shipping_qty                               day_indv_shipping_qty          --出庫数量（当日、バラ）
                      ,xei.day_case_shipping_qty                               day_case_shipping_qty          --出庫数量（当日、ケース）
                      ,xei.day_sum_shipping_qty                                day_sum_shipping_qty           --出庫数量（当日、合計）
                      ,xei.month_indv_shipping_qty                             month_indv_shipping_qty        --出庫数量（当月、バラ）
                      ,xei.month_case_shipping_qty                             month_case_shipping_qty        --出庫数量（当月、ケース）
                      ,xei.month_sum_shipping_qty                              month_sum_shipping_qty         --出庫数量（当月、合計）
                      ,xei.day_indv_destroy_loss_qty                           day_indv_destroy_loss_qty      --破棄、ロス数量（当日、バラ）
                      ,xei.day_case_destroy_loss_qty                           day_case_destroy_loss_qty      --破棄、ロス数量（当日、ケース）
                      ,xei.day_sum_destroy_loss_qty                            day_sum_destroy_loss_qty       --破棄、ロス数量（当日、合計）
                      ,xei.month_indv_destroy_loss_qty                         month_indv_destroy_loss_qty    --破棄、ロス数量（当月、バラ）
                      ,xei.month_case_destroy_loss_qty                         month_case_destroy_loss_qty    --破棄、ロス数量（当月、ケース）
                      ,xei.month_sum_destroy_loss_qty                          month_sum_destroy_loss_qty     --破棄、ロス数量（当月、合計）
                      ,xei.day_indv_defect_stk_qty                             day_indv_defect_stk_qty        --不良在庫数量（当日、バラ）
                      ,xei.day_case_defect_stk_qty                             day_case_defect_stk_qty        --不良在庫数量（当日、ケース）
                      ,xei.day_sum_defect_stk_qty                              day_sum_defect_stk_qty         --不良在庫数量（当日、合計）
                      ,xei.month_indv_defect_stk_qty                           month_indv_defect_stk_qty      --不良在庫数量（当月、バラ）
                      ,xei.month_case_defect_stk_qty                           month_case_defect_stk_qty      --不良在庫数量（当月、ケース）
                      ,xei.month_sum_defect_stk_qty                            month_sum_defect_stk_qty       --不良在庫数量（当月、合計）
                      ,xei.day_indv_defect_return_qty                          day_indv_defect_return_qty     --不良返品数量（当日、バラ）
                      ,xei.day_case_defect_return_qty                          day_case_defect_return_qty     --不良返品数量（当日、ケース）
                      ,xei.day_sum_defect_return_qty                           day_sum_defect_return_qty      --不良返品数量（当日、合計）
                      ,xei.month_indv_defect_return_qty                        month_indv_defect_return_qty   --不良返品数量（当月、バラ）
                      ,xei.month_case_defect_return_qty                        month_case_defect_return_qty   --不良返品数量（当月、ケース）
                      ,xei.month_sum_defect_return_qty                         month_sum_defect_return_qty    --不良返品数量（当月、合計）
                      ,xei.day_indv_defect_return_rcpt                         day_indv_defect_return_rcpt    --不良返品受入（当日、バラ）
                      ,xei.day_case_defect_return_rcpt                         day_case_defect_return_rcpt    --不良返品受入（当日、ケース）
                      ,xei.day_sum_defect_return_rcpt                          day_sum_defect_return_rcpt     --不良返品受入（当日、合計）
                      ,xei.month_indv_defect_return_rcpt                       month_indv_defect_return_rcpt  --不良返品受入（当月、バラ）
                      ,xei.month_case_defect_return_rcpt                       month_case_defect_return_rcpt  --不良返品受入（当月、ケース）
                      ,xei.month_sum_defect_return_rcpt                        month_sum_defect_return_rcpt   --不良返品受入（当月、合計）
                      ,xei.day_indv_defect_return_send                         day_indv_defect_return_send    --不良返品発送（当日、バラ）
                      ,xei.day_case_defect_return_send                         day_case_defect_return_send    --不良返品発送（当日、ケース）
                      ,xei.day_sum_defect_return_send                          day_sum_defect_return_send     --不良返品発送（当日、合計）
                      ,xei.month_indv_defect_return_send                       month_indv_defect_return_send  --不良返品発送（当月、バラ）
                      ,xei.month_case_defect_return_send                       month_case_defect_return_send  --不良返品発送（当月、ケース）
                      ,xei.month_sum_defect_return_send                        month_sum_defect_return_send   --不良返品発送（当月、合計）
                      ,xei.day_indv_quality_return_rcpt                        day_indv_quality_return_rcpt   --良品返品受入（当日、バラ）
                      ,xei.day_case_quality_return_rcpt                        day_case_quality_return_rcpt   --良品返品受入（当日、ケース）
                      ,xei.day_sum_quality_return_rcpt                         day_sum_quality_return_rcpt    --良品返品受入（当日、合計）
                      ,xei.month_indv_quality_return_rcpt                      month_indv_quality_return_rcpt --良品返品受入（当月、バラ）
                      ,xei.month_case_quality_return_rcpt                      month_case_quality_return_rcpt --良品返品受入（当月、ケース）
                      ,xei.month_sum_quality_return_rcpt                       month_sum_quality_return_rcpt  --良品返品受入（当月、合計）
                      ,xei.day_indv_quality_return_send                        day_indv_quality_return_send   --良品返品発送（当日、バラ）
                      ,xei.day_case_quality_return_send                        day_case_quality_return_send   --良品返品発送（当日、ケース）
                      ,xei.day_sum_quality_return_send                         day_sum_quality_return_send    --良品返品発送（当日、合計）
                      ,xei.month_indv_quality_return_send                      month_indv_quality_return_send --良品返品発送（当月、バラ）
                      ,xei.month_case_quality_return_send                      month_case_quality_return_send --良品返品発送（当月、ケース）
                      ,xei.month_sum_quality_return_send                       month_sum_quality_return_send  --良品返品発送（当月、合計）
                      ,xei.day_indv_invent_difference                          day_indv_invent_difference     --棚卸差異（当日、バラ）
                      ,xei.day_case_invent_difference                          day_case_invent_difference     --棚卸差異（当日、ケース）
                      ,xei.day_sum_invent_difference                           day_sum_invent_difference      --棚卸差異（当日、合計）
                      ,xei.month_indv_invent_difference                        month_indv_invent_difference   --棚卸差異（当月、バラ）
                      ,xei.month_case_invent_difference                        month_case_invent_difference   --棚卸差異（当月、ケース）
                      ,xei.month_sum_invent_difference                         month_sum_invent_difference    --棚卸差異（当月、合計）
                      ,xei.day_indv_stk_qty                                    day_indv_stk_qty               --在庫数量（当日、バラ）
                      ,xei.day_case_stk_qty                                    day_case_stk_qty               --在庫数量（当日、ケース）
                      ,xei.day_sum_stk_qty                                     day_sum_stk_qty                --在庫数量（当日、合計）
                      ,xei.month_indv_stk_qty                                  month_indv_stk_qty             --在庫数量（当月、バラ）
                      ,xei.month_case_stk_qty                                  month_case_stk_qty             --在庫数量（当月、ケース）
                      ,xei.month_sum_stk_qty                                   month_sum_stk_qty              --在庫数量（当月、合計）
                      ,xei.day_indv_reserved_stk_qty                           day_indv_reserved_stk_qty      --保留在庫数（当日、バラ）
                      ,xei.day_case_reserved_stk_qty                           day_case_reserved_stk_qty      --保留在庫数（当日、ケース）
                      ,xei.day_sum_reserved_stk_qty                            day_sum_reserved_stk_qty       --保留在庫数（当日、合計）
                      ,xei.month_indv_reserved_stk_qty                         month_indv_reserved_stk_qty    --保留在庫数（当月、バラ）
                      ,xei.month_case_reserved_stk_qty                         month_case_reserved_stk_qty    --保留在庫数（当月、ケース）
                      ,xei.month_sum_reserved_stk_qty                          month_sum_reserved_stk_qty     --保留在庫数（当月、合計）
                      ,xei.day_indv_cd_stk_qty                                 day_indv_cd_stk_qty            --商流在庫数量（当日、バラ）
                      ,xei.day_case_cd_stk_qty                                 day_case_cd_stk_qty            --商流在庫数量（当日、ケース）
                      ,xei.day_sum_cd_stk_qty                                  day_sum_cd_stk_qty             --商流在庫数量（当日、合計）
                      ,xei.month_indv_cd_stk_qty                               month_indv_cd_stk_qty          --商流在庫数量（当月、バラ）
                      ,xei.month_case_cd_stk_qty                               month_case_cd_stk_qty          --商流在庫数量（当月、ケース）
                      ,xei.month_sum_cd_stk_qty                                month_sum_cd_stk_qty           --商流在庫数量（当月、合計）
                      ,xei.day_indv_cargo_stk_qty                              day_indv_cargo_stk_qty         --積送在庫数量（当日、バラ）
                      ,xei.day_case_cargo_stk_qty                              day_case_cargo_stk_qty         --積送在庫数量（当日、ケース）
                      ,xei.day_sum_cargo_stk_qty                               day_sum_cargo_stk_qty          --積送在庫数量（当日、合計）
                      ,xei.month_indv_cargo_stk_qty                            month_indv_cargo_stk_qty       --積送在庫数量（当月、バラ）
                      ,xei.month_case_cargo_stk_qty                            month_case_cargo_stk_qty       --積送在庫数量（当月、ケース）
                      ,xei.month_sum_cargo_stk_qty                             month_sum_cargo_stk_qty        --積送在庫数量（当月、合計）
                      ,xei.day_indv_adjustment_stk_qty                         day_indv_adjustment_stk_qty    --調整在庫数量（当日、バラ）
                      ,xei.day_case_adjustment_stk_qty                         day_case_adjustment_stk_qty    --調整在庫数量（当日、ケース）
                      ,xei.day_sum_adjustment_stk_qty                          day_sum_adjustment_stk_qty     --調整在庫数量（当日、合計）
                      ,xei.month_indv_adjustment_stk_qty                       month_indv_adjustment_stk_qty  --調整在庫数量（当月、バラ）
                      ,xei.month_case_adjustment_stk_qty                       month_case_adjustment_stk_qty  --調整在庫数量（当月、ケース）
                      ,xei.month_sum_adjustment_stk_qty                        month_sum_adjustment_stk_qty   --調整在庫数量（当月、合計）
                      ,xei.day_indv_still_shipping_qty                         day_indv_still_shipping_qty    --未出荷数量（当日、バラ）
                      ,xei.day_case_still_shipping_qty                         day_case_still_shipping_qty    --未出荷数量（当日、ケース）
                      ,xei.day_sum_still_shipping_qty                          day_sum_still_shipping_qty     --未出荷数量（当日、合計）
                      ,xei.month_indv_still_shipping_qty                       month_indv_still_shipping_qty  --未出荷数量（当月、バラ）
                      ,xei.month_case_still_shipping_qty                       month_case_still_shipping_qty  --未出荷数量（当月、ケース）
                      ,xei.month_sum_still_shipping_qty                        month_sum_still_shipping_qty   --未出荷数量（当月、合計）
                      ,xei.indv_all_stk_qty                                    indv_all_stk_qty               --総在庫数量（バラ）
                      ,xei.case_all_stk_qty                                    case_all_stk_qty               --総在庫数量（ケース）
                      ,xei.sum_all_stk_qty                                     sum_all_stk_qty                --総在庫数量（合計）
                      ,xei.month_draw_count                                    month_draw_count               --当月引当回数
                      ,xei.day_indv_draw_possible_qty                          day_indv_draw_possible_qty     --引当可能数量（当日、バラ）
                      ,xei.day_case_draw_possible_qty                          day_case_draw_possible_qty     --引当可能数量（当日、ケース）
                      ,xei.day_sum_draw_possible_qty                           day_sum_draw_possible_qty      --引当可能数量（当日、合計）
                      ,xei.month_indv_draw_possible_qty                        month_indv_draw_possible_qty   --引当可能数量（当月、バラ）
                      ,xei.month_case_draw_possible_qty                        month_case_draw_possible_qty   --引当可能数量（当月、ケース）
                      ,xei.month_sum_draw_possible_qty                         month_sum_draw_possible_qty    --引当可能数量（当月、合計）
                      ,xei.day_indv_draw_impossible_qty                        day_indv_draw_impossible_qty   --引当不能数（当日、バラ）
                      ,xei.day_case_draw_impossible_qty                        day_case_draw_impossible_qty   --引当不能数（当日、ケース）
                      ,xei.day_sum_draw_impossible_qty                         day_sum_draw_impossible_qty    --引当不能数（当日、合計）
                      ,xei.day_stk_amt                                         day_stk_amt                    --在庫金額（当日）
                      ,xei.month_stk_amt                                       month_stk_amt                  --在庫金額（当月）
                      ,xei.remarks                                             remarks                        --備考
                      ,xei.chain_peculiar_area_line                            chain_peculiar_area_line       --チェーン店固有エリア（明細）
                      ,xei.invoice_day_indv_sum_stk_qty                        invoice_day_indv_sum_stk_qty   --（計）在庫数量合計（当日、バラ）
                      ,xei.invoice_day_case_sum_stk_qty                        invoice_day_case_sum_stk_qty   --（計）在庫数量合計（当日、ケース）
                      ,xei.invoice_day_sum_sum_stk_qty                         invoice_day_sum_sum_stk_qty    --（計）在庫数量合計（当日、合計）
                      ,xei.invoice_month_indv_sum_stk_qty                      invoice_month_indv_sum_stk_qty --（計）在庫数量合計（当月、バラ）
                      ,xei.invoice_month_case_sum_stk_qty                      invoice_month_case_sum_stk_qty --（計）在庫数量合計（当月、ケース）
                      ,xei.invoice_month_sum_sum_stk_qty                       invoice_month_sum_sum_stk_qty  --（計）在庫数量合計（当月、合計）
                      ,xei.invoice_day_indv_cd_stk_qty                         invoice_day_indv_cd_stk_qty    --（計）商流在庫数量（当日、バラ）
                      ,xei.invoice_day_case_cd_stk_qty                         invoice_day_case_cd_stk_qty    --（計）商流在庫数量（当日、ケース）
                      ,xei.invoice_day_sum_cd_stk_qty                          invoice_day_sum_cd_stk_qty     --（計）商流在庫数量（当日、合計）
                      ,xei.invoice_month_indv_cd_stk_qty                       invoice_month_indv_cd_stk_qty  --（計）商流在庫数量（当月、バラ）
                      ,xei.invoice_month_case_cd_stk_qty                       invoice_month_case_cd_stk_qty  --（計）商流在庫数量（当月、ケース）
                      ,xei.invoice_month_sum_cd_stk_qty                        invoice_month_sum_cd_stk_qty   --（計）商流在庫数量（当月、合計）
                      ,xei.invoice_day_stk_amt                                 invoice_day_stk_amt            --（計）在庫金額（当日）
                      ,xei.invoice_month_stk_amt                               invoice_month_stk_amt          --（計）在庫金額（当月）
                      ,xei.regular_sell_amt_sum                                regular_sell_amt_sum           --正販金額合計
                      ,xei.rebate_amt_sum                                      rebate_amt_sum                 --割戻し金額合計
                      ,xei.collect_bottle_amt_sum                              collect_bottle_amt_sum         --回収容器金額合計
                      ,xei.chain_peculiar_area_footer                          chain_peculiar_area_footer     --チェーン店固有エリア（フッター）
                      ,xei.item_code                                           item_code                      --品目コード
                      ,hca.account_number                                      account_number                 --顧客コード
                      ,hp.party_name                                           party_name                     --顧客名（漢字）
                      ,hp.organization_name_phonetic                           organization_name_phonetic     --顧客名（カナ）
                      ,xca.deli_center_code                                    deli_center_code               --納入センターコード
                      ,xca.deli_center_name                                    deli_center_name               --納入センター名（漢字）
                      ,xca.torihikisaki_code                                   torihikisaki_code              --取引先コード
                      ,xca.delivery_base_code                                  delivery_base_code             --納品拠点コード
                      ,xei.conv_customer_code                                  conv_customer_code             --換算後顧客コード
                 FROM  xxcos_edi_inventory                                     xei                            --EDI在庫情報テーブル
                      ,xxcmm_cust_accounts                                     xca                            --顧客マスタアドオン
                      ,hz_cust_accounts                                        hca                            --顧客マスタ
                      ,hz_parties                                              hp                             --パーティマスタ
                      ,xxcos_chain_store_security_v                            xcss                           --チェーン店店舗セキュリティビュー
                WHERE xei.conv_customer_code     IS NOT NULL
                --顧客アドオン
                  AND xca.chain_store_code        = xei.edi_chain_code                                        --チェーン店コード
                  AND xca.store_code              = xei.shop_code                                             --店舗コード
                --顧客マスタ
                  AND ( hca.cust_account_id       = xca.customer_id )                                         --顧客ID
                  AND hca.customer_class_code    IN ( cv_cust_class_chain_store, cv_cust_class_uesama )
                --パーティマスタ
                  AND hp.party_id                 = hca.party_id
                --店舗セキュリティVIEW
                  AND xcss.chain_code             = xei.edi_chain_code                                        --チェーン店コード
                  AND xcss.chain_store_code       = xei.shop_code                                             --店コード
                  AND xcss.user_id                = i_input_rec.user_id                                       --ユーザID
               UNION
               SELECT 2                                                        select_block
                      ,xei.medium_class                                        medium_class                   --媒体区分
                      ,xei.data_type_code                                      data_type_code                 --データ種コード
                      ,xei.file_no                                             file_no                        --ファイルＮｏ
                      ,xei.info_class                                          info_class                     --情報区分
                      ,xei.edi_chain_code                                      edi_chain_code                 --ＥＤＩチェーン店コード
                      ,xei.company_code                                        company_code                   --社コード
                      ,xei.company_name_alt                                    company_name_alt               --社名（カナ）
                      ,xei.shop_code                                           shop_code                      --店コード
                      ,xei.shop_name_alt                                       shop_name_alt                  --店名（カナ）
                      ,xei.delivery_center_code                                delivery_center_code           --納入センターコード
                      ,xei.delivery_center_name                                delivery_center_name           --納入センター名（漢字）
                      ,xei.delivery_center_name_alt                            delivery_center_name_alt       --納入センター名（カナ）
                      ,xei.whse_code                                           whse_code                      --倉庫コード
                      ,xei.whse_name                                           whse_name                      --倉庫名
                      ,xei.inspect_charge_name                                 inspect_charge_name            --検品担当者名（漢字）
                      ,xei.inspect_charge_name_alt                             inspect_charge_name_alt        --検品担当者名（カナ）
                      ,xei.return_charge_name                                  return_charge_name             --返品担当者名（漢字）
                      ,xei.return_charge_name_alt                              return_charge_name_alt         --返品担当者名（カナ）
                      ,xei.receive_charge_name                                 receive_charge_name            --受領担当者名（漢字）
                      ,xei.receive_charge_name_alt                             receive_charge_name_alt        --受領担当者名（カナ）
                      ,xei.order_date                                          order_date                     --発注日
                      ,xei.center_delivery_date                                center_delivery_date           --センター納品日
                      ,xei.center_result_delivery_date                         center_result_delivery_date    --センター実納品日
                      ,xei.center_shipping_date                                center_shipping_date           --センター出庫日
                      ,xei.center_result_shipping_date                         center_result_shipping_date    --センター実出庫日
                      ,xei.data_creation_date_edi_data                         data_creation_date_edi_data    --データ作成日（ＥＤＩデータ中）
----******************************************* 2010/03/09 1.10 T.Nakano UPD START *************************************
                      ,xei.edi_received_date                                   edi_received_date              --EDI受信日
----******************************************* 2010/03/09 1.10 T.Nakano UPD END *************************************
                      ,xei.data_creation_time_edi_data                         data_creation_time_edi_data    --データ作成時刻（ＥＤＩデータ中）
                      ,xei.stk_date                                            stk_date                       --在庫日付
                      ,xei.offer_vendor_code_class                             offer_vendor_code_class        --提供企業取引先コード区分
                      ,xei.whse_vendor_code_class                              whse_vendor_code_class         --倉庫取引先コード区分
                      ,xei.offer_cycle_class                                   offer_cycle_class              --提供サイクル区分
                      ,xei.stk_type                                            stk_type                       --在庫種類
                      ,xei.japanese_class                                      japanese_class                 --日本語区分
                      ,xei.whse_class                                          whse_class                     --倉庫区分
                      ,xei.vendor_code                                         vendor_code                    --取引先コード
                      ,xei.vendor_name_alt                                     vendor_name_alt                --取引先名（カナ）
                      ,xei.check_digit_class                                   check_digit_class              --チェックデジット有無区分
                      ,xei.invoice_number                                      invoice_number                 --伝票番号
                      ,xei.check_digit                                         check_digit                    --チェックデジット
                      ,xei.chain_peculiar_area_header                          chain_peculiar_area_header     --チェーン店固有エリア（ヘッダ）
                      ,xei.product_code_itouen                                 product_code_itouen            --商品コード（伊藤園）
                      ,xei.product_code_other_party                            product_code_other_party       --商品コード（先方）
                      ,xei.ebs_uom_code                                        ebs_uom_code                   --単位コード(EBS)
                      ,xei.product_name_alt                                    product_name_alt               --商品名（カナ）
                      ,xei.active_quality_class                                active_quality_class           --適用品質区分
                      ,xei.qty_in_case                                         qty_in_case                    --入数
                      ,xei.uom_code                                            uom_code                       --単位
                      ,xei.day_average_shipping_qty                            day_average_shipping_qty       --一日平均出荷数量
                      ,xei.stk_type_code                                       stk_type_code                  --在庫種別コード
                      ,xei.last_arrival_date                                   last_arrival_date              --最終入荷日
                      ,xei.use_by_date                                         use_by_date                    --賞味期限
                      ,xei.product_date                                        product_date                   --製造日
                      ,xei.upper_limit_stk_case                                upper_limit_stk_case           --上限在庫（ケース）
                      ,xei.upper_limit_stk_indv                                upper_limit_stk_indv           --上限在庫（バラ）
                      ,xei.indv_order_point                                    indv_order_point               --発注点（バラ）
                      ,xei.case_order_point                                    case_order_point               --発注点（ケース）
                      ,xei.indv_prev_month_stk_qty                             indv_prev_month_stk_qty        --前月末在庫数量（バラ）
                      ,xei.case_prev_month_stk_qty                             case_prev_month_stk_qty        --前月末在庫数量（ケース）
                      ,xei.sum_prev_month_stk_qty                              sum_prev_month_stk_qty         --前月在庫数量（合計）
                      ,xei.day_indv_order_qty                                  day_indv_order_qty             --発注数量（当日、バラ）
                      ,xei.day_case_order_qty                                  day_case_order_qty             --発注数量（当日、ケース）
                      ,xei.day_sum_order_qty                                   day_sum_order_qty              --発注数量（当日、合計）
                      ,xei.month_indv_order_qty                                month_indv_order_qty           --発注数量（当月、バラ）
                      ,xei.month_case_order_qty                                month_case_order_qty           --発注数量（当月、ケース）
                      ,xei.month_sum_order_qty                                 month_sum_order_qty            --発注数量（当月、合計）
                      ,xei.day_indv_arrival_qty                                day_indv_arrival_qty           --入庫数量（当日、バラ）
                      ,xei.day_case_arrival_qty                                day_case_arrival_qty           --入庫数量（当日、ケース）
                      ,xei.day_sum_arrival_qty                                 day_sum_arrival_qty            --入庫数量（当日、合計）
                      ,xei.month_arrival_count                                 month_arrival_count            --当月入荷回数
                      ,xei.month_indv_arrival_qty                              month_indv_arrival_qty         --入庫数量（当月、バラ）
                      ,xei.month_case_arrival_qty                              month_case_arrival_qty         --入庫数量（当月、ケース）
                      ,xei.month_sum_arrival_qty                               month_sum_arrival_qty          --入庫数量（当月、合計）
                      ,xei.day_indv_shipping_qty                               day_indv_shipping_qty          --出庫数量（当日、バラ）
                      ,xei.day_case_shipping_qty                               day_case_shipping_qty          --出庫数量（当日、ケース）
                      ,xei.day_sum_shipping_qty                                day_sum_shipping_qty           --出庫数量（当日、合計）
                      ,xei.month_indv_shipping_qty                             month_indv_shipping_qty        --出庫数量（当月、バラ）
                      ,xei.month_case_shipping_qty                             month_case_shipping_qty        --出庫数量（当月、ケース）
                      ,xei.month_sum_shipping_qty                              month_sum_shipping_qty         --出庫数量（当月、合計）
                      ,xei.day_indv_destroy_loss_qty                           day_indv_destroy_loss_qty      --破棄、ロス数量（当日、バラ）
                      ,xei.day_case_destroy_loss_qty                           day_case_destroy_loss_qty      --破棄、ロス数量（当日、ケース）
                      ,xei.day_sum_destroy_loss_qty                            day_sum_destroy_loss_qty       --破棄、ロス数量（当日、合計）
                      ,xei.month_indv_destroy_loss_qty                         month_indv_destroy_loss_qty    --破棄、ロス数量（当月、バラ）
                      ,xei.month_case_destroy_loss_qty                         month_case_destroy_loss_qty    --破棄、ロス数量（当月、ケース）
                      ,xei.month_sum_destroy_loss_qty                          month_sum_destroy_loss_qty     --破棄、ロス数量（当月、合計）
                      ,xei.day_indv_defect_stk_qty                             day_indv_defect_stk_qty        --不良在庫数量（当日、バラ）
                      ,xei.day_case_defect_stk_qty                             day_case_defect_stk_qty        --不良在庫数量（当日、ケース）
                      ,xei.day_sum_defect_stk_qty                              day_sum_defect_stk_qty         --不良在庫数量（当日、合計）
                      ,xei.month_indv_defect_stk_qty                           month_indv_defect_stk_qty      --不良在庫数量（当月、バラ）
                      ,xei.month_case_defect_stk_qty                           month_case_defect_stk_qty      --不良在庫数量（当月、ケース）
                      ,xei.month_sum_defect_stk_qty                            month_sum_defect_stk_qty       --不良在庫数量（当月、合計）
                      ,xei.day_indv_defect_return_qty                          day_indv_defect_return_qty     --不良返品数量（当日、バラ）
                      ,xei.day_case_defect_return_qty                          day_case_defect_return_qty     --不良返品数量（当日、ケース）
                      ,xei.day_sum_defect_return_qty                           day_sum_defect_return_qty      --不良返品数量（当日、合計）
                      ,xei.month_indv_defect_return_qty                        month_indv_defect_return_qty   --不良返品数量（当月、バラ）
                      ,xei.month_case_defect_return_qty                        month_case_defect_return_qty   --不良返品数量（当月、ケース）
                      ,xei.month_sum_defect_return_qty                         month_sum_defect_return_qty    --不良返品数量（当月、合計）
                      ,xei.day_indv_defect_return_rcpt                         day_indv_defect_return_rcpt    --不良返品受入（当日、バラ）
                      ,xei.day_case_defect_return_rcpt                         day_case_defect_return_rcpt    --不良返品受入（当日、ケース）
                      ,xei.day_sum_defect_return_rcpt                          day_sum_defect_return_rcpt     --不良返品受入（当日、合計）
                      ,xei.month_indv_defect_return_rcpt                       month_indv_defect_return_rcpt  --不良返品受入（当月、バラ）
                      ,xei.month_case_defect_return_rcpt                       month_case_defect_return_rcpt  --不良返品受入（当月、ケース）
                      ,xei.month_sum_defect_return_rcpt                        month_sum_defect_return_rcpt   --不良返品受入（当月、合計）
                      ,xei.day_indv_defect_return_send                         day_indv_defect_return_send    --不良返品発送（当日、バラ）
                      ,xei.day_case_defect_return_send                         day_case_defect_return_send    --不良返品発送（当日、ケース）
                      ,xei.day_sum_defect_return_send                          day_sum_defect_return_send     --不良返品発送（当日、合計）
                      ,xei.month_indv_defect_return_send                       month_indv_defect_return_send  --不良返品発送（当月、バラ）
                      ,xei.month_case_defect_return_send                       month_case_defect_return_send  --不良返品発送（当月、ケース）
                      ,xei.month_sum_defect_return_send                        month_sum_defect_return_send   --不良返品発送（当月、合計）
                      ,xei.day_indv_quality_return_rcpt                        day_indv_quality_return_rcpt   --良品返品受入（当日、バラ）
                      ,xei.day_case_quality_return_rcpt                        day_case_quality_return_rcpt   --良品返品受入（当日、ケース）
                      ,xei.day_sum_quality_return_rcpt                         day_sum_quality_return_rcpt    --良品返品受入（当日、合計）
                      ,xei.month_indv_quality_return_rcpt                      month_indv_quality_return_rcpt --良品返品受入（当月、バラ）
                      ,xei.month_case_quality_return_rcpt                      month_case_quality_return_rcpt --良品返品受入（当月、ケース）
                      ,xei.month_sum_quality_return_rcpt                       month_sum_quality_return_rcpt  --良品返品受入（当月、合計）
                      ,xei.day_indv_quality_return_send                        day_indv_quality_return_send   --良品返品発送（当日、バラ）
                      ,xei.day_case_quality_return_send                        day_case_quality_return_send   --良品返品発送（当日、ケース）
                      ,xei.day_sum_quality_return_send                         day_sum_quality_return_send    --良品返品発送（当日、合計）
                      ,xei.month_indv_quality_return_send                      month_indv_quality_return_send --良品返品発送（当月、バラ）
                      ,xei.month_case_quality_return_send                      month_case_quality_return_send --良品返品発送（当月、ケース）
                      ,xei.month_sum_quality_return_send                       month_sum_quality_return_send  --良品返品発送（当月、合計）
                      ,xei.day_indv_invent_difference                          day_indv_invent_difference     --棚卸差異（当日、バラ）
                      ,xei.day_case_invent_difference                          day_case_invent_difference     --棚卸差異（当日、ケース）
                      ,xei.day_sum_invent_difference                           day_sum_invent_difference      --棚卸差異（当日、合計）
                      ,xei.month_indv_invent_difference                        month_indv_invent_difference   --棚卸差異（当月、バラ）
                      ,xei.month_case_invent_difference                        month_case_invent_difference   --棚卸差異（当月、ケース）
                      ,xei.month_sum_invent_difference                         month_sum_invent_difference    --棚卸差異（当月、合計）
                      ,xei.day_indv_stk_qty                                    day_indv_stk_qty               --在庫数量（当日、バラ）
                      ,xei.day_case_stk_qty                                    day_case_stk_qty               --在庫数量（当日、ケース）
                      ,xei.day_sum_stk_qty                                     day_sum_stk_qty                --在庫数量（当日、合計）
                      ,xei.month_indv_stk_qty                                  month_indv_stk_qty             --在庫数量（当月、バラ）
                      ,xei.month_case_stk_qty                                  month_case_stk_qty             --在庫数量（当月、ケース）
                      ,xei.month_sum_stk_qty                                   month_sum_stk_qty              --在庫数量（当月、合計）
                      ,xei.day_indv_reserved_stk_qty                           day_indv_reserved_stk_qty      --保留在庫数（当日、バラ）
                      ,xei.day_case_reserved_stk_qty                           day_case_reserved_stk_qty      --保留在庫数（当日、ケース）
                      ,xei.day_sum_reserved_stk_qty                            day_sum_reserved_stk_qty       --保留在庫数（当日、合計）
                      ,xei.month_indv_reserved_stk_qty                         month_indv_reserved_stk_qty    --保留在庫数（当月、バラ）
                      ,xei.month_case_reserved_stk_qty                         month_case_reserved_stk_qty    --保留在庫数（当月、ケース）
                      ,xei.month_sum_reserved_stk_qty                          month_sum_reserved_stk_qty     --保留在庫数（当月、合計）
                      ,xei.day_indv_cd_stk_qty                                 day_indv_cd_stk_qty            --商流在庫数量（当日、バラ）
                      ,xei.day_case_cd_stk_qty                                 day_case_cd_stk_qty            --商流在庫数量（当日、ケース）
                      ,xei.day_sum_cd_stk_qty                                  day_sum_cd_stk_qty             --商流在庫数量（当日、合計）
                      ,xei.month_indv_cd_stk_qty                               month_indv_cd_stk_qty          --商流在庫数量（当月、バラ）
                      ,xei.month_case_cd_stk_qty                               month_case_cd_stk_qty          --商流在庫数量（当月、ケース）
                      ,xei.month_sum_cd_stk_qty                                month_sum_cd_stk_qty           --商流在庫数量（当月、合計）
                      ,xei.day_indv_cargo_stk_qty                              day_indv_cargo_stk_qty         --積送在庫数量（当日、バラ）
                      ,xei.day_case_cargo_stk_qty                              day_case_cargo_stk_qty         --積送在庫数量（当日、ケース）
                      ,xei.day_sum_cargo_stk_qty                               day_sum_cargo_stk_qty          --積送在庫数量（当日、合計）
                      ,xei.month_indv_cargo_stk_qty                            month_indv_cargo_stk_qty       --積送在庫数量（当月、バラ）
                      ,xei.month_case_cargo_stk_qty                            month_case_cargo_stk_qty       --積送在庫数量（当月、ケース）
                      ,xei.month_sum_cargo_stk_qty                             month_sum_cargo_stk_qty        --積送在庫数量（当月、合計）
                      ,xei.day_indv_adjustment_stk_qty                         day_indv_adjustment_stk_qty    --調整在庫数量（当日、バラ）
                      ,xei.day_case_adjustment_stk_qty                         day_case_adjustment_stk_qty    --調整在庫数量（当日、ケース）
                      ,xei.day_sum_adjustment_stk_qty                          day_sum_adjustment_stk_qty     --調整在庫数量（当日、合計）
                      ,xei.month_indv_adjustment_stk_qty                       month_indv_adjustment_stk_qty  --調整在庫数量（当月、バラ）
                      ,xei.month_case_adjustment_stk_qty                       month_case_adjustment_stk_qty  --調整在庫数量（当月、ケース）
                      ,xei.month_sum_adjustment_stk_qty                        month_sum_adjustment_stk_qty   --調整在庫数量（当月、合計）
                      ,xei.day_indv_still_shipping_qty                         day_indv_still_shipping_qty    --未出荷数量（当日、バラ）
                      ,xei.day_case_still_shipping_qty                         day_case_still_shipping_qty    --未出荷数量（当日、ケース）
                      ,xei.day_sum_still_shipping_qty                          day_sum_still_shipping_qty     --未出荷数量（当日、合計）
                      ,xei.month_indv_still_shipping_qty                       month_indv_still_shipping_qty  --未出荷数量（当月、バラ）
                      ,xei.month_case_still_shipping_qty                       month_case_still_shipping_qty  --未出荷数量（当月、ケース）
                      ,xei.month_sum_still_shipping_qty                        month_sum_still_shipping_qty   --未出荷数量（当月、合計）
                      ,xei.indv_all_stk_qty                                    indv_all_stk_qty               --総在庫数量（バラ）
                      ,xei.case_all_stk_qty                                    case_all_stk_qty               --総在庫数量（ケース）
                      ,xei.sum_all_stk_qty                                     sum_all_stk_qty                --総在庫数量（合計）
                      ,xei.month_draw_count                                    month_draw_count               --当月引当回数
                      ,xei.day_indv_draw_possible_qty                          day_indv_draw_possible_qty     --引当可能数量（当日、バラ）
                      ,xei.day_case_draw_possible_qty                          day_case_draw_possible_qty     --引当可能数量（当日、ケース）
                      ,xei.day_sum_draw_possible_qty                           day_sum_draw_possible_qty      --引当可能数量（当日、合計）
                      ,xei.month_indv_draw_possible_qty                        month_indv_draw_possible_qty   --引当可能数量（当月、バラ）
                      ,xei.month_case_draw_possible_qty                        month_case_draw_possible_qty   --引当可能数量（当月、ケース）
                      ,xei.month_sum_draw_possible_qty                         month_sum_draw_possible_qty    --引当可能数量（当月、合計）
                      ,xei.day_indv_draw_impossible_qty                        day_indv_draw_impossible_qty   --引当不能数（当日、バラ）
                      ,xei.day_case_draw_impossible_qty                        day_case_draw_impossible_qty   --引当不能数（当日、ケース）
                      ,xei.day_sum_draw_impossible_qty                         day_sum_draw_impossible_qty    --引当不能数（当日、合計）
                      ,xei.day_stk_amt                                         day_stk_amt                    --在庫金額（当日）
                      ,xei.month_stk_amt                                       month_stk_amt                  --在庫金額（当月）
                      ,xei.remarks                                             remarks                        --備考
                      ,xei.chain_peculiar_area_line                            chain_peculiar_area_line       --チェーン店固有エリア（明細）
                      ,xei.invoice_day_indv_sum_stk_qty                        invoice_day_indv_sum_stk_qty   --（計）在庫数量合計（当日、バラ）
                      ,xei.invoice_day_case_sum_stk_qty                        invoice_day_case_sum_stk_qty   --（計）在庫数量合計（当日、ケース）
                      ,xei.invoice_day_sum_sum_stk_qty                         invoice_day_sum_sum_stk_qty    --（計）在庫数量合計（当日、合計）
                      ,xei.invoice_month_indv_sum_stk_qty                      invoice_month_indv_sum_stk_qty --（計）在庫数量合計（当月、バラ）
                      ,xei.invoice_month_case_sum_stk_qty                      invoice_month_case_sum_stk_qty --（計）在庫数量合計（当月、ケース）
                      ,xei.invoice_month_sum_sum_stk_qty                       invoice_month_sum_sum_stk_qty  --（計）在庫数量合計（当月、合計）
                      ,xei.invoice_day_indv_cd_stk_qty                         invoice_day_indv_cd_stk_qty    --（計）商流在庫数量（当日、バラ）
                      ,xei.invoice_day_case_cd_stk_qty                         invoice_day_case_cd_stk_qty    --（計）商流在庫数量（当日、ケース）
                      ,xei.invoice_day_sum_cd_stk_qty                          invoice_day_sum_cd_stk_qty     --（計）商流在庫数量（当日、合計）
                      ,xei.invoice_month_indv_cd_stk_qty                       invoice_month_indv_cd_stk_qty  --（計）商流在庫数量（当月、バラ）
                      ,xei.invoice_month_case_cd_stk_qty                       invoice_month_case_cd_stk_qty  --（計）商流在庫数量（当月、ケース）
                      ,xei.invoice_month_sum_cd_stk_qty                        invoice_month_sum_cd_stk_qty   --（計）商流在庫数量（当月、合計）
                      ,xei.invoice_day_stk_amt                                 invoice_day_stk_amt            --（計）在庫金額（当日）
                      ,xei.invoice_month_stk_amt                               invoice_month_stk_amt          --（計）在庫金額（当月）
                      ,xei.regular_sell_amt_sum                                regular_sell_amt_sum           --正販金額合計
                      ,xei.rebate_amt_sum                                      rebate_amt_sum                 --割戻し金額合計
                      ,xei.collect_bottle_amt_sum                              collect_bottle_amt_sum         --回収容器金額合計
                      ,xei.chain_peculiar_area_footer                          chain_peculiar_area_footer     --チェーン店固有エリア（フッター）
                      ,xei.item_code                                           item_code                      --品目コード
                      ,NULL                                                    account_number                 --顧客コード
                      ,NULL                                                    party_name                     --顧客名（漢字）
                      ,NULL                                                    organization_name_phonetic     --顧客名（カナ）
                      ,NULL                                                    deli_center_code               --納入センターコード
                      ,NULL                                                    deli_center_name               --納入センター名（漢字）
                      ,NULL                                                    torihikisaki_code              --取引先コード
                      ,NULL                                                    delivery_base_code             --納品拠点コード
                      ,xei.conv_customer_code                                  conv_customer_code             --換算後顧客コード
                 FROM xxcos_edi_inventory                                      xei                            --EDI在庫情報テーブル
                WHERE xei.conv_customer_code     IS NULL
             )                                                                 xei                            --EDI在庫情報テーブル
             ,ic_item_mst_b                                                    iimb                           --OPM品目マスタ
             ,xxcmn_item_mst_b                                                 ximb                           --OPM品目マスタアドオン
             ,mtl_system_items_b                                               msib                           --DISC品目マスタ
             ,xxcmm_system_items_b                                             xsib                           --DISC品目マスタアドオン
             ,xxcos_head_prod_class_v                                          xhpcv                          --本社商品区分ビュー
             ,(
               SELECT hca.account_number                                       account_number                 --顧客コード
                     ,hp.party_name                                            base_name                      --顧客名称
                     ,hp.organization_name_phonetic                            base_name_kana                 --顧客名称(カナ)
               FROM   hz_cust_accounts                                         hca                            --顧客マスタ
                     ,xxcmm_cust_accounts                                      xca                            --顧客マスタアドオン
                     ,hz_parties                                               hp                             --パーティマスタ
               WHERE  hca.customer_class_code     = cv_cust_class_base
               AND    xca.customer_id             = hca.cust_account_id
               AND    hp.party_id                 = hca.party_id
              )                                                                cdm
    --EDI在庫情報テーブル
       WHERE xei.data_type_code                   = i_input_rec.data_type_code                                --データ種コード
         AND (     i_input_rec.info_class        IS NOT NULL                                                  --情報区分
               AND xei.info_class                 = i_input_rec.info_class
               OR  i_input_rec.info_class        IS NULL
             )
         AND xei.edi_chain_code                   = i_input_rec.chain_code                                    --チェーン店コード
         AND (
              (     i_input_rec.store_code       IS NOT NULL                                                  --INパラがNOT NULL
                AND xei.shop_code                 = i_input_rec.store_code                                    --SHOP結合
                AND xei.select_block              = 1
              )
              OR
              (
                i_input_rec.store_code           IS  NULL
              )
             )
----******************************************* 2010/03/09 1.10 T.Nakano MOD START *************************************
--         AND TRUNC(xei.data_creation_date_edi_data)                                                           --データ作成日
         AND TRUNC(xei.edi_received_date)                                                                     --EDI受信日
----******************************************* 2010/03/09 1.10 T.Nakano MOD END *************************************
               BETWEEN TO_DATE(i_input_rec.edi_date_from, cv_date_fmt )
               AND     TO_DATE(i_input_rec.edi_date_to  , cv_date_fmt )
         AND (     i_input_rec.item_class        != cv_prod_class_all                                         --商品区分
               AND NVL( xhpcv.item_div_h_code,cv_item_div_h_code_A )
                                                  = i_input_rec.item_class
               OR  i_input_rec.item_class         = cv_prod_class_all
             )
       --OPM品目マスタ
         AND iimb.item_no(+)                      = xei.item_code                                             --品目コード
       --OPM品目アドオン
         AND ximb.item_id(+)                      = iimb.item_id                                              --品目ID
         AND NVL( xei.center_delivery_date
                 ,NVL( xei.order_date
                      ,data_creation_date_edi_data ) )
             BETWEEN ( NVL( ximb.start_date_active                                                            --適用開始日
                           ,NVL( xei.center_delivery_date
                                ,NVL( xei.order_date
                                     ,data_creation_date_edi_data  ) ) ) )
             AND     ( NVL( ximb.end_date_active                                                              --適用終了日
                           ,NVL( xei.center_delivery_date
                                ,NVL( xei.order_date
                                     ,data_creation_date_edi_data  ) ) ) )
       --DISC品目マスタ
         AND msib.segment1(+)                     = xei.item_code
         AND msib.organization_id(+)              = i_other_rec.organization_id                               --在庫組織ID
       --DISC品目アドオン
         AND xsib.item_code(+)                    = msib.segment1                                             --品目コード
       --商品区分VIEW
         AND xhpcv.segment1(+)                    = iimb.item_no                                              --品目ID
         AND xei.delivery_base_code               = cdm.account_number(+)
--******************************************* 2009/06/18 1.9 T.Kitajima MOD  END  *************************************
      ;
    -- *** ローカル・レコード ***
    l_base_rec                 g_base_rtype;                                                                 --納品拠点情報
    l_chain_rec                g_chain_rtype;                                                                --EDIチェーン店情報
    l_other_rec                g_other_rtype;                                                                --その他情報
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lb_error := FALSE;
--
--******************************************* 2009/06/18 1.9 T.Kitajima ADD START *************************************
    --==============================================================
    --納品拠点情報取得
    --==============================================================
    BEGIN
      SELECT hp.organization_name_phonetic  base_name_kana   --顧客名称(カナ)
      INTO   l_base_rec.base_name_kana
      FROM   hz_cust_accounts               hca              --顧客マスタ
            ,hz_parties                     hp               --パーティマスタ
      WHERE  hca.customer_class_code   = cv_cust_class_base
      AND    hp.party_id               = hca.party_id
      AND    hca.account_number        = g_input_rec.base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_base_rec.base_name_kana := NULL;
    END;
--******************************************* 2009/06/18 1.9 T.Kitajima ADD  END  *************************************
--******************************************* 2009/04/02 1.7 T.Kitajima DEL START *************************************
--    --==============================================================
--    --納品拠点情報取得
--    --==============================================================
--    BEGIN
--      SELECT hp.party_name                                                    base_name                      --顧客名称
--            ,hp.organization_name_phonetic                                    base_name_kana                 --顧客名称(カナ)
--            ,xca.torihikisaki_code                                            customer_code                  --取引先コード
--      INTO   l_base_rec.base_name
--            ,l_base_rec.base_name_kana
--            ,l_base_rec.customer_code
--      FROM   hz_cust_accounts                                                 hca                            --顧客マスタ
--            ,xxcmm_cust_accounts                                              xca                            --顧客マスタアドオン
--            ,hz_parties                                                       hp                             --パーティマスタ
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--            ,hz_cust_acct_sites_all                                           hcas                           --顧客所在地
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--            ,hz_party_sites                                                   hps                            --パーティサイトマスタ
--            ,hz_locations                                                     hl                             --事業所マスタ
--      --顧客マスタ抽出条件
--      WHERE  hca.account_number      = g_input_rec.base_code
--      AND    hca.customer_class_code = cv_cust_class_base
--      --顧客マスタアドオン抽出条件
--      AND    xca.customer_id         = hca.cust_account_id
--      --パーティマスタ抽出条件
--      AND    hp.party_id             = hca.party_id
--     --パーティサイト抽出条件
--      AND    hps.party_id            = hca.party_id
--      --顧客事業所マスタ抽出条件
--      AND    hl.location_id          = hps.location_id
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--      AND    hcas.cust_account_id    = hca.cust_account_id
--      AND    hps.party_site_id       = hcas.party_site_id
--      AND    hcas.org_id             = g_prf_rec.org_id
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--      ;
--
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_base_rec.base_name := g_msg_rec.customer_notfound;
--    END;
--******************************************* 2009/04/02 1.7 T.Kitajima DEL  END  *************************************
--
    --==============================================================
    --チェーン店情報取得
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                    chain_name                     --チェーン店名称
            ,hp.organization_name_phonetic                                    chain_name_kana                --チェーン店名称(カナ)
      INTO   l_chain_rec.chain_name           
            ,l_chain_rec.chain_name_kana
      FROM   xxcmm_cust_accounts                                              xca                            --顧客マスタアドオン
            ,hz_cust_accounts                                                 hca                            --顧客マスタ
            ,hz_parties                                                       hp                             --パーティマスタ
      WHERE  xca.edi_chain_code      = g_input_rec.chain_code
      AND    hca.cust_account_id     = xca.customer_id
      AND    hca.customer_class_code = cv_cust_class_chain
      AND    hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_chain_rec.chain_name := g_msg_rec.customer_notfound;
    END;
--
    --==============================================================
    --グローバル変数の設定
    --==============================================================
    g_base_rec := l_base_rec;
    g_chain_rec := l_chain_rec;
--
    --==============================================================
    --データレコード情報取得
    --==============================================================
    OPEN cur_data_record(
           g_input_rec
          ,g_prf_rec
          ,g_base_rec
          ,g_chain_rec
          ,g_msg_rec
          ,g_other_rec
         );
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
            ------------------------------------------------ヘッダ情報------------------------------------------------
        l_data_tab('MEDIUM_CLASS')                                            --媒体区分
       ,l_data_tab('DATA_TYPE_CODE')                                          --データ種コード
       ,l_data_tab('FILE_NO')                                                 --ファイルＮｏ
       ,l_data_tab('INFO_CLASS')                                              --情報区分
       ,l_data_tab('PROCESS_DATE')                                            --処理日
       ,l_data_tab('PROCESS_TIME')                                            --処理時刻
       ,l_data_tab('BASE_CODE')                                               --拠点（部門）コード
       ,l_data_tab('BASE_NAME')                                               --拠点名（正式名）
       ,l_data_tab('BASE_NAME_ALT')                                           --拠点名（カナ）
       ,l_data_tab('EDI_CHAIN_CODE')                                          --ＥＤＩチェーン店コード
       ,l_data_tab('EDI_CHAIN_NAME')                                          --ＥＤＩチェーン店名（漢字）
       ,l_data_tab('EDI_CHAIN_NAME_ALT')                                      --ＥＤＩチェーン店名（カナ）
       ,l_data_tab('REPORT_CODE')                                             --帳票コード
       ,l_data_tab('REPORT_SHOW_NAME')                                        --帳票表示名
       ,l_data_tab('CUSTOMER_CODE')                                           --顧客コード
       ,l_data_tab('CUSTOMER_NAME')                                           --顧客名（漢字）
       ,l_data_tab('CUSTOMER_NAME_ALT')                                       --顧客名（カナ）
       ,l_data_tab('COMPANY_CODE')                                            --社コード
       ,l_data_tab('COMPANY_NAME_ALT')                                        --社名（カナ）
       ,l_data_tab('SHOP_CODE')                                               --店コード
       ,l_data_tab('SHOP_NAME_ALT')                                           --店名（カナ）
       ,l_data_tab('DELIVERY_CENTER_CODE')                                    --納入センターコード
       ,l_data_tab('DELIVERY_CENTER_NAME')                                    --納入センター名（漢字）
       ,l_data_tab('DELIVERY_CENTER_NAME_ALT')                                --納入センター名（カナ）
       ,l_data_tab('WHSE_CODE')                                               --倉庫コード
       ,l_data_tab('WHSE_NAME')                                               --倉庫名
       ,l_data_tab('INSPECT_CHARGE_NAME')                                     --検品担当者名（漢字）
       ,l_data_tab('INSPECT_CHARGE_NAME_ALT')                                 --検品担当者名（カナ）
       ,l_data_tab('RETURN_CHARGE_NAME')                                      --返品担当者名（漢字）
       ,l_data_tab('RETURN_CHARGE_NAME_ALT')                                  --返品担当者名（カナ）
       ,l_data_tab('RECEIVE_CHARGE_NAME')                                     --受領担当者名（漢字）
       ,l_data_tab('RECEIVE_CHARGE_NAME_ALT')                                 --受領担当者名（カナ）
       ,l_data_tab('ORDER_DATE')                                              --発注日
       ,l_data_tab('CENTER_DELIVERY_DATE')                                    --センター納品日
       ,l_data_tab('CENTER_RESULT_DELIVERY_DATE')                             --センター実納品日
       ,l_data_tab('CENTER_SHIPPING_DATE')                                    --センター出庫日
       ,l_data_tab('CENTER_RESULT_SHIPPING_DATE')                             --センター実出庫日
       ,l_data_tab('DATA_CREATION_DATE_EDI_DATA')                             --データ作成日（ＥＤＩデータ中）
       ,l_data_tab('DATA_CREATION_TIME_EDI_DATA')                             --データ作成時刻（ＥＤＩデータ中）
       ,l_data_tab('STK_DATE')                                                --在庫日付
       ,l_data_tab('OFFER_VENDOR_CODE_CLASS')                                 --提供企業取引先コード区分
       ,l_data_tab('WHSE_VENDOR_CODE_CLASS')                                  --倉庫取引先コード区分
       ,l_data_tab('OFFER_CYCLE_CLASS')                                       --提供サイクル区分
       ,l_data_tab('STK_TYPE')                                                --在庫種類
       ,l_data_tab('JAPANESE_CLASS')                                          --日本語区分
       ,l_data_tab('WHSE_CLASS')                                              --倉庫区分
       ,l_data_tab('VENDOR_CODE')                                             --取引先コード
       ,l_data_tab('VENDOR_NAME')                                             --取引先名（漢字）
       ,l_data_tab('VENDOR_NAME_ALT')                                         --取引先名（カナ）
       ,l_data_tab('CHECK_DIGIT_CLASS')                                       --チェックデジット有無区分
       ,l_data_tab('INVOICE_NUMBER')                                          --伝票番号
       ,l_data_tab('CHECK_DIGIT')                                             --チェックデジット
       ,l_data_tab('CHAIN_PECULIAR_AREA_HEADER')                              --チェーン店固有エリア（ヘッダ）
            -------------------------------------------------明細情報-------------------------------------------------
       ,l_data_tab('PRODUCT_CODE_ITOUEN')                                     --商品コード（伊藤園）
       ,l_data_tab('PRODUCT_CODE_OTHER_PARTY')                                --商品コード（先方）
       ,l_data_tab('JAN_CODE')                                                --ＪＡＮコード
       ,l_data_tab('ITF_CODE')                                                --ＩＴＦコード
       ,l_data_tab('PRODUCT_NAME')                                            --商品名（漢字）
       ,l_data_tab('PRODUCT_NAME_ALT')                                        --商品名（カナ）
       ,l_data_tab('PROD_CLASS')                                              --商品区分
       ,l_data_tab('ACTIVE_QUALITY_CLASS')                                    --適用品質区分
       ,l_data_tab('QTY_IN_CASE')                                             --入数
       ,l_data_tab('UOM_CODE')                                                --単位
       ,l_data_tab('DAY_AVERAGE_SHIPPING_QTY')                                --一日平均出荷数量
       ,l_data_tab('STK_TYPE_CODE')                                           --在庫種別コード
       ,l_data_tab('LAST_ARRIVAL_DATE')                                       --最終入荷日
       ,l_data_tab('USE_BY_DATE')                                             --賞味期限
       ,l_data_tab('PRODUCT_DATE')                                            --製造日
       ,l_data_tab('UPPER_LIMIT_STK_CASE')                                    --上限在庫（ケース）
       ,l_data_tab('UPPER_LIMIT_STK_INDV')                                    --上限在庫（バラ）
       ,l_data_tab('INDV_ORDER_POINT')                                        --発注点（バラ）
       ,l_data_tab('CASE_ORDER_POINT')                                        --発注点（ケース）
       ,l_data_tab('INDV_PREV_MONTH_STK_QTY')                                 --前月末在庫数量（バラ）
       ,l_data_tab('CASE_PREV_MONTH_STK_QTY')                                 --前月末在庫数量（ケース）
       ,l_data_tab('SUM_PREV_MONTH_STK_QTY')                                  --前月在庫数量（合計）
       ,l_data_tab('DAY_INDV_ORDER_QTY')                                      --発注数量（当日、バラ）
       ,l_data_tab('DAY_CASE_ORDER_QTY')                                      --発注数量（当日、ケース）
       ,l_data_tab('DAY_SUM_ORDER_QTY')                                       --発注数量（当日、合計）
       ,l_data_tab('MONTH_INDV_ORDER_QTY')                                    --発注数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_ORDER_QTY')                                    --発注数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_ORDER_QTY')                                     --発注数量（当月、合計）
       ,l_data_tab('DAY_INDV_ARRIVAL_QTY')                                    --入庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_ARRIVAL_QTY')                                    --入庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_ARRIVAL_QTY')                                     --入庫数量（当日、合計）
       ,l_data_tab('MONTH_ARRIVAL_COUNT')                                     --当月入荷回数
       ,l_data_tab('MONTH_INDV_ARRIVAL_QTY')                                  --入庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_ARRIVAL_QTY')                                  --入庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_ARRIVAL_QTY')                                   --入庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_SHIPPING_QTY')                                   --出庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_SHIPPING_QTY')                                   --出庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_SHIPPING_QTY')                                    --出庫数量（当日、合計）
       ,l_data_tab('MONTH_INDV_SHIPPING_QTY')                                 --出庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_SHIPPING_QTY')                                 --出庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_SHIPPING_QTY')                                  --出庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_DESTROY_LOSS_QTY')                               --破棄、ロス数量（当日、バラ）
       ,l_data_tab('DAY_CASE_DESTROY_LOSS_QTY')                               --破棄、ロス数量（当日、ケース）
       ,l_data_tab('DAY_SUM_DESTROY_LOSS_QTY')                                --破棄、ロス数量（当日、合計）
       ,l_data_tab('MONTH_INDV_DESTROY_LOSS_QTY')                             --破棄、ロス数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_DESTROY_LOSS_QTY')                             --破棄、ロス数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_DESTROY_LOSS_QTY')                              --破棄、ロス数量（当月、合計）
       ,l_data_tab('DAY_INDV_DEFECT_STK_QTY')                                 --不良在庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_DEFECT_STK_QTY')                                 --不良在庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_DEFECT_STK_QTY')                                  --不良在庫数量（当日、合計）
       ,l_data_tab('MONTH_INDV_DEFECT_STK_QTY')                               --不良在庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_DEFECT_STK_QTY')                               --不良在庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_DEFECT_STK_QTY')                                --不良在庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_DEFECT_RETURN_QTY')                              --不良返品数量（当日、バラ）
       ,l_data_tab('DAY_CASE_DEFECT_RETURN_QTY')                              --不良返品数量（当日、ケース）
       ,l_data_tab('DAY_SUM_DEFECT_RETURN_QTY')                               --不良返品数量（当日、合計）
       ,l_data_tab('MONTH_INDV_DEFECT_RETURN_QTY')                            --不良返品数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_DEFECT_RETURN_QTY')                            --不良返品数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_DEFECT_RETURN_QTY')                             --不良返品数量（当月、合計）
       ,l_data_tab('DAY_INDV_DEFECT_RETURN_RCPT')                             --不良返品受入（当日、バラ）
       ,l_data_tab('DAY_CASE_DEFECT_RETURN_RCPT')                             --不良返品受入（当日、ケース）
       ,l_data_tab('DAY_SUM_DEFECT_RETURN_RCPT')                              --不良返品受入（当日、合計）
       ,l_data_tab('MONTH_INDV_DEFECT_RETURN_RCPT')                           --不良返品受入（当月、バラ）
       ,l_data_tab('MONTH_CASE_DEFECT_RETURN_RCPT')                           --不良返品受入（当月、ケース）
       ,l_data_tab('MONTH_SUM_DEFECT_RETURN_RCPT')                            --不良返品受入（当月、合計）
       ,l_data_tab('DAY_INDV_DEFECT_RETURN_SEND')                             --不良返品発送（当日、バラ）
       ,l_data_tab('DAY_CASE_DEFECT_RETURN_SEND')                             --不良返品発送（当日、ケース）
       ,l_data_tab('DAY_SUM_DEFECT_RETURN_SEND')                              --不良返品発送（当日、合計）
       ,l_data_tab('MONTH_INDV_DEFECT_RETURN_SEND')                           --不良返品発送（当月、バラ）
       ,l_data_tab('MONTH_CASE_DEFECT_RETURN_SEND')                           --不良返品発送（当月、ケース）
       ,l_data_tab('MONTH_SUM_DEFECT_RETURN_SEND')                            --不良返品発送（当月、合計）
       ,l_data_tab('DAY_INDV_QUALITY_RETURN_RCPT')                            --良品返品受入（当日、バラ）
       ,l_data_tab('DAY_CASE_QUALITY_RETURN_RCPT')                            --良品返品受入（当日、ケース）
       ,l_data_tab('DAY_SUM_QUALITY_RETURN_RCPT')                             --良品返品受入（当日、合計）
       ,l_data_tab('MONTH_INDV_QUALITY_RETURN_RCPT')                          --良品返品受入（当月、バラ）
       ,l_data_tab('MONTH_CASE_QUALITY_RETURN_RCPT')                          --良品返品受入（当月、ケース）
       ,l_data_tab('MONTH_SUM_QUALITY_RETURN_RCPT')                           --良品返品受入（当月、合計）
       ,l_data_tab('DAY_INDV_QUALITY_RETURN_SEND')                            --良品返品発送（当日、バラ）
       ,l_data_tab('DAY_CASE_QUALITY_RETURN_SEND')                            --良品返品発送（当日、ケース）
       ,l_data_tab('DAY_SUM_QUALITY_RETURN_SEND')                             --良品返品発送（当日、合計）
       ,l_data_tab('MONTH_INDV_QUALITY_RETURN_SEND')                          --良品返品発送（当月、バラ）
       ,l_data_tab('MONTH_CASE_QUALITY_RETURN_SEND')                          --良品返品発送（当月、ケース）
       ,l_data_tab('MONTH_SUM_QUALITY_RETURN_SEND')                           --良品返品発送（当月、合計）
       ,l_data_tab('DAY_INDV_INVENT_DIFFERENCE')                              --棚卸差異（当日、バラ）
       ,l_data_tab('DAY_CASE_INVENT_DIFFERENCE')                              --棚卸差異（当日、ケース）
       ,l_data_tab('DAY_SUM_INVENT_DIFFERENCE')                               --棚卸差異（当日、合計）
       ,l_data_tab('MONTH_INDV_INVENT_DIFFERENCE')                            --棚卸差異（当月、バラ）
       ,l_data_tab('MONTH_CASE_INVENT_DIFFERENCE')                            --棚卸差異（当月、ケース）
       ,l_data_tab('MONTH_SUM_INVENT_DIFFERENCE')                             --棚卸差異（当月、合計）
       ,l_data_tab('DAY_INDV_STK_QTY')                                        --在庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_STK_QTY')                                        --在庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_STK_QTY')                                         --在庫数量（当日、合計）
       ,l_data_tab('MONTH_INDV_STK_QTY')                                      --在庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_STK_QTY')                                      --在庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_STK_QTY')                                       --在庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_RESERVED_STK_QTY')                               --保留在庫数（当日、バラ）
       ,l_data_tab('DAY_CASE_RESERVED_STK_QTY')                               --保留在庫数（当日、ケース）
       ,l_data_tab('DAY_SUM_RESERVED_STK_QTY')                                --保留在庫数（当日、合計）
       ,l_data_tab('MONTH_INDV_RESERVED_STK_QTY')                             --保留在庫数（当月、バラ）
       ,l_data_tab('MONTH_CASE_RESERVED_STK_QTY')                             --保留在庫数（当月、ケース）
       ,l_data_tab('MONTH_SUM_RESERVED_STK_QTY')                              --保留在庫数（当月、合計）
       ,l_data_tab('DAY_INDV_CD_STK_QTY')                                     --商流在庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_CD_STK_QTY')                                     --商流在庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_CD_STK_QTY')                                      --商流在庫数量（当日、合計）
       ,l_data_tab('MONTH_INDV_CD_STK_QTY')                                   --商流在庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_CD_STK_QTY')                                   --商流在庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_CD_STK_QTY')                                    --商流在庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_CARGO_STK_QTY')                                  --積送在庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_CARGO_STK_QTY')                                  --積送在庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_CARGO_STK_QTY')                                   --積送在庫数量（当日、合計）
       ,l_data_tab('MONTH_INDV_CARGO_STK_QTY')                                --積送在庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_CARGO_STK_QTY')                                --積送在庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_CARGO_STK_QTY')                                 --積送在庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_ADJUSTMENT_STK_QTY')                             --調整在庫数量（当日、バラ）
       ,l_data_tab('DAY_CASE_ADJUSTMENT_STK_QTY')                             --調整在庫数量（当日、ケース）
       ,l_data_tab('DAY_SUM_ADJUSTMENT_STK_QTY')                              --調整在庫数量（当日、合計）
       ,l_data_tab('MONTH_INDV_ADJUSTMENT_STK_QTY')                           --調整在庫数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_ADJUSTMENT_STK_QTY')                           --調整在庫数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_ADJUSTMENT_STK_QTY')                            --調整在庫数量（当月、合計）
       ,l_data_tab('DAY_INDV_STILL_SHIPPING_QTY')                             --未出荷数量（当日、バラ）
       ,l_data_tab('DAY_CASE_STILL_SHIPPING_QTY')                             --未出荷数量（当日、ケース）
       ,l_data_tab('DAY_SUM_STILL_SHIPPING_QTY')                              --未出荷数量（当日、合計）
       ,l_data_tab('MONTH_INDV_STILL_SHIPPING_QTY')                           --未出荷数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_STILL_SHIPPING_QTY')                           --未出荷数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_STILL_SHIPPING_QTY')                            --未出荷数量（当月、合計）
       ,l_data_tab('INDV_ALL_STK_QTY')                                        --総在庫数量（バラ）
       ,l_data_tab('CASE_ALL_STK_QTY')                                        --総在庫数量（ケース）
       ,l_data_tab('SUM_ALL_STK_QTY')                                         --総在庫数量（合計）
       ,l_data_tab('MONTH_DRAW_COUNT')                                        --当月引当回数
       ,l_data_tab('DAY_INDV_DRAW_POSSIBLE_QTY')                              --引当可能数量（当日、バラ）
       ,l_data_tab('DAY_CASE_DRAW_POSSIBLE_QTY')                              --引当可能数量（当日、ケース）
       ,l_data_tab('DAY_SUM_DRAW_POSSIBLE_QTY')                               --引当可能数量（当日、合計）
       ,l_data_tab('MONTH_INDV_DRAW_POSSIBLE_QTY')                            --引当可能数量（当月、バラ）
       ,l_data_tab('MONTH_CASE_DRAW_POSSIBLE_QTY')                            --引当可能数量（当月、ケース）
       ,l_data_tab('MONTH_SUM_DRAW_POSSIBLE_QTY')                             --引当可能数量（当月、合計）
       ,l_data_tab('DAY_INDV_DRAW_IMPOSSIBLE_QTY')                            --引当不能数（当日、バラ）
       ,l_data_tab('DAY_CASE_DRAW_IMPOSSIBLE_QTY')                            --引当不能数（当日、ケース）
       ,l_data_tab('DAY_SUM_DRAW_IMPOSSIBLE_QTY')                             --引当不能数（当日、合計）
       ,l_data_tab('DAY_STK_AMT')                                             --在庫金額（当日）
       ,l_data_tab('MONTH_STK_AMT')                                           --在庫金額（当月）
       ,l_data_tab('REMARKS')                                                 --備考
       ,l_data_tab('CHAIN_PECULIAR_AREA_LINE')                                --チェーン店固有エリア（明細）
            ------------------------------------------------フッタ情報------------------------------------------------
       ,l_data_tab('INVOICE_DAY_INDV_SUM_STK_QTY')                            --（伝票計）在庫数量合計（当日、バラ）
       ,l_data_tab('INVOICE_DAY_CASE_SUM_STK_QTY')                            --（伝票計）在庫数量合計（当日、ケース）
       ,l_data_tab('INVOICE_DAY_SUM_SUM_STK_QTY')                             --（伝票計）在庫数量合計（当日、合計）
       ,l_data_tab('INVOICE_MONTH_INDV_SUM_STK_QTY')                          --（伝票計）在庫数量合計（当月、バラ）
       ,l_data_tab('INVOICE_MONTH_CASE_SUM_STK_QTY')                          --（伝票計）在庫数量合計（当月、ケース）
       ,l_data_tab('INVOICE_MONTH_SUM_SUM_STK_QTY')                           --（伝票計）在庫数量合計（当月、合計）
       ,l_data_tab('INVOICE_DAY_INDV_CD_STK_QTY')                             --（伝票計）商流在庫数量（当日、バラ）
       ,l_data_tab('INVOICE_DAY_CASE_CD_STK_QTY')                             --（伝票計）商流在庫数量（当日、ケース）
       ,l_data_tab('INVOICE_DAY_SUM_CD_STK_QTY')                              --（伝票計）商流在庫数量（当日、合計）
       ,l_data_tab('INVOICE_MONTH_INDV_CD_STK_QTY')                           --（伝票計）商流在庫数量（当月、バラ）
       ,l_data_tab('INVOICE_MONTH_CASE_CD_STK_QTY')                           --（伝票計）商流在庫数量（当月、ケース）
       ,l_data_tab('INVOICE_MONTH_SUM_CD_STK_QTY')                            --（伝票計）商流在庫数量（当月、合計）
       ,l_data_tab('INVOICE_DAY_STK_AMT')                                     --（伝票計）在庫金額（当日）
       ,l_data_tab('INVOICE_MONTH_STK_AMT')                                   --（伝票計）在庫金額（当月）
       ,l_data_tab('REGULAR_SELL_AMT_SUM')                                    --正販金額合計
       ,l_data_tab('REBATE_AMT_SUM')                                          --割戻し金額合計
       ,l_data_tab('COLLECT_BOTTLE_AMT_SUM')                                  --回収容器金額合計
       ,l_data_tab('CHAIN_PECULIAR_AREA_FOOTER')                              --チェーン店固有エリア（フッター）
      ;
      EXIT WHEN cur_data_record%NOTFOUND;
--
      --==============================================================
      --CSVヘッダレコード作成処理
      --==============================================================
      IF (cur_data_record%ROWCOUNT = 1) THEN
        proc_out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
      END IF;
      --==============================================================
      --データレコード作成処理
      --==============================================================
      proc_out_data_record(
                   l_data_tab
                  ,lv_errbuf
                  ,lv_retcode
                  ,lv_errmsg
                           );
     IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--      RAISE global_process_expt;
       RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
     END IF;
--
    END LOOP data_record_loop;
--
    --==============================================================
    --フッタレコード作成処理
    --==============================================================
    proc_out_footer_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
    END IF;
--
    --対象データ未存在
    IF (gn_target_cnt = 0) THEN
      ov_retcode := cv_status_warn;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name
                    ,iv_name         => cv_msg_nodata
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
    CLOSE cur_data_record;
    out_line(buff => cv_prg_name || ' end');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    --==============================================================
    --初期処理
    --==============================================================
    proc_init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --ヘッダレコード作成処理
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --データレコード取得処理
    --==============================================================
    proc_get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode     := lv_retcode;
    out_line(buff   => cv_prg_name || ' end');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_file_name                IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code               IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code              IN     VARCHAR2,  --  3.帳票コード
    in_user_id                  IN     NUMBER,    --  4.ユーザID
    iv_chain_name               IN     VARCHAR2,  --  5.チェーン店名
    iv_store_code               IN     VARCHAR2,  --  6.店舗コード
    iv_base_code                IN     VARCHAR2,  --  7.拠点コード
    iv_base_name                IN     VARCHAR2,  --  8.拠点名
    iv_data_type_code           IN     VARCHAR2,  --  9.帳票種別コード
    iv_ebs_business_series_code IN     VARCHAR2,  -- 10.業務系列コード
    iv_info_class               IN     VARCHAR2,  -- 11.情報区分
    iv_report_name              IN     VARCHAR2,  -- 12.帳票様式
    iv_edi_date_from            IN     VARCHAR2,  -- 13.EDI取込日(FROM)
    iv_edi_date_to              IN     VARCHAR2,  -- 14.EDI取込日(TO)
    iv_item_class               IN     VARCHAR2   -- 15.商品区分
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out         CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log         CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
    l_input_rec g_input_rtype;
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    -- 入力パラメータのセット
    -- ===============================================
    l_input_rec.user_id                  := in_user_id;                       --  1.ユーザID
    l_input_rec.chain_code               := iv_chain_code;                    --  2.チェーン店コード
    l_input_rec.chain_name               := iv_chain_name;                    --  3.チェーン店名
    l_input_rec.store_code               := iv_store_code;                    --  4.店舗コード
    l_input_rec.base_code                := iv_base_code;                     --  5.拠点コード
    l_input_rec.base_name                := iv_base_name;                     --  6.拠点名
    l_input_rec.file_name                := iv_file_name;                     --  7.ファイル名
    l_input_rec.data_type_code           := iv_data_type_code;                --  8.帳票種別コード
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;      --  9.業務系列コード
    l_input_rec.info_class               := iv_info_class;                    -- 10.情報区分
    l_input_rec.report_code              := iv_report_code;                   -- 11.帳票コード
    l_input_rec.report_name              := iv_report_name;                   -- 12.帳票様式
    l_input_rec.item_class               := iv_item_class;                    -- 13.商品区分
    l_input_rec.edi_date_from            := iv_edi_date_from;                 -- 14.EDI取込日(FROM)
    l_input_rec.edi_date_to              := iv_edi_date_to;                   -- 15.EDI取込日(TO)
--
    g_input_rec := l_input_rec;
--
    -- ===============================================
    -- 初期処理の呼び出し
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- 終了処理
    -- ===============================================
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
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
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/12 T.Nakamura Ver.1.1 mod start
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
    END IF;
-- 2009/02/12 T.Nakamura Ver.1.1 mod end
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
    IF (lv_retcode = cv_status_normal) THEN
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
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_success_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --エラー件数出力
    IF (lv_retcode = cv_status_error) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS014A05C;
/
