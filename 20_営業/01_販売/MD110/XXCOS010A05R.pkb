CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A05R(body)
 * Description      : 受注エラーリスト
 * MD.050           : 受注エラーリスト MD050_COS_010_A05
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_parameter          パラメータチェック処理(A-2)
 *  get_data               データ取得(A-3)
 *  insert_report_work     帳票ワークテーブルデータ登録(A-4)
 *  delete_edi             EDIテーブルデータ削除(A-5)
 *  execute_svf            SVF起動(A-6)
 *  delete_report_work     帳票ワークテーブルデータ削除(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   K.Kumamoto       新規作成
 *  2009/02/13    1.1   M.Yamaki         [COS_072]エラーリスト種別コードの対応
 *  2009/02/24    1.2   T.Nakamura       [COS_133]メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/06/19    1.3   N.Nishimura      [T1_1437]データパージ不具合対応
 *  2009/07/23    1.4   N.Maeda          [0000300]ロック処理修正
 *  2009/08/03    1.5   M.Sano           [0000902]受注エラーリストの終了ステータス変更
 *  2009/09/29    1.6   N.Maeda          [0001338]プロシージャexecute_svfの独立トランザクション化
 *  2010/01/19    1.7   M.Sano           [E_本稼動_01159]
 *                                       ・入力パラメータの追加
 *                                         (実行区分･拠点･チェーン店･EDI受信日(FROM)･EDI受信日(TO))
 *                                       ・再発行の可能化
 *                                       ・出力対象のエラー情報を制御する機能の追加
 *                                       ・伝票単位でEDIワーク情報を削除できる機能の追加
 *  2012/08/02    1.8   T.Osawa          [E_本稼動_09864]受注エラーリストのカナ店舗名称表示
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
  update_expt               EXCEPTION; --更新エラー
  delete_expt               EXCEPTION; --削除エラー
  execute_svf_expt          EXCEPTION; --SVF起動エラー
  resource_busy_expt        EXCEPTION;     --ロックエラー
-- 2010/01/19 M.Sano Ver.1.7 add start
  profile_expt              EXCEPTION; --プロファイルエラー
-- 2010/01/19 M.Sano Ver.1.7 add end
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS010A05R';                          --パッケージ名
  ct_apl_name                     CONSTANT fnd_application.application_short_name%TYPE := 'XXCOS';   --アプリケーション短縮名
  cv_fmt_date                     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                            --日付書式
  cv_fmt_date8                    CONSTANT VARCHAR2(8) := 'YYYYMMDD';                                --日付書式(ファイル名用)
--
  --メッセージ
  ct_msg_err_list_err             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12101'; --エラーリスト種別エラー
  ct_msg_parameters               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12102'; --パラメータ出力メッセージ
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064'; --取得エラー
  ct_msg_work_tab_name            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12103'; --文字列.受注エラーリスト帳票ワークテーブル
  ct_msg_insert_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010'; --データ登録エラー
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011'; --データ更新エラー
  ct_msg_delete_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012'; --データ削除エラー
  ct_msg_order_work_tab           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00113'; --EDI受注情報ワークテーブル
  ct_msg_dlv_rtn_work_tab         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00117'; --EDI納品返品情報ワークテーブル
  ct_msg_edi_err_tab              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00116'; --EDIエラー情報テーブル
  ct_msg_request_id               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00088'; --文字列.要求ID
  ct_msg_api_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00017'; --API呼出エラーメッセージ
  ct_msg_svf_api                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00041'; --文字列.SVF起動API
  ct_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00018'; --明細0件用メッセージ
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001'; --ロックエラーメッセージ
-- ******************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
  ct_msg_Processed_other          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12104'; --他処理出力済みメッセージ
-- ******************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
-- 2010/01/19 M.Sano Ver.1.7 add start
  cv_msg_profile                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; --プロファイル取得エラーメッセージ
  ct_msg_biz_man_dept_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12105'; --EDIエラーリスト用業務管理部コード
-- 2010/01/19 M.Sano Ver.1.7 add end
--
  --トークン
  cv_tkn_param1                   CONSTANT VARCHAR2(6) := 'PARAM1';
-- 2010/01/19 M.Sano Ver.1.7 add start
  cv_tkn_param2                   CONSTANT VARCHAR2(6) := 'PARAM2';
  cv_tkn_param3                   CONSTANT VARCHAR2(6) := 'PARAM3';
  cv_tkn_param4                   CONSTANT VARCHAR2(6) := 'PARAM4';
  cv_tkn_param5                   CONSTANT VARCHAR2(6) := 'PARAM5';
  cv_tkn_param6                   CONSTANT VARCHAR2(6) := 'PARAM6';
  cv_tkn_profile                  CONSTANT VARCHAR2(7) := 'PROFILE';                                 --トークン.プロファイル
-- 2010/01/19 M.Sano Ver.1.7 add end
  cv_tkn_data                     CONSTANT VARCHAR2(4) := 'DATA';                                    --トークン.データ
  cv_tkn_table_name               CONSTANT VARCHAR2(10) := 'TABLE_NAME';                             --トークン.テーブル名
  cv_tkn_table                    CONSTANT VARCHAR2(10) := 'TABLE';                                  --トークン.テーブル名
  cv_tkn_key                      CONSTANT VARCHAR2(8) := 'KEY_DATA';                                --トークン.キー情報
  cv_tkn_api_name                 CONSTANT VARCHAR2(8) := 'API_NAME';                                --トークンAPI名
--
  --クイックコード
  ct_qc_err_list_type             CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_EDI_CREATE_CLASS';  --参照タイプ.EDI作成元区分
-- 2010/01/19 M.Sano Ver.1.7 add start
  ct_order_err_list_message       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_ORDER_ERR_LIST_MESSAGE';
                                                                                           --参照タイプ.受注エラーリスト出力メッセージ
-- 2010/01/19 M.Sano Ver.1.7 add end
--
  --プロファイル
  ct_prf_organization_code CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE'; --在庫組織コード
-- 2010/01/19 M.Sano Ver.1.7 add start
  ct_prf_biz_man_dept_code CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_EDI_ERR_BIZ_MAN_DEPT_CODE'; --EDIエラーリスト用業務管理部コード
-- 2010/01/19 M.Sano Ver.1.7 add end
--
  --SVF関連
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS010A05R';          -- コンカレント名
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS010A05R';          -- 帳票ＩＤ
  cv_extension              CONSTANT VARCHAR2(100) := '.pdf';                  -- 拡張子（ＰＤＦ）
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS010A05S.xml';      -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS010A05S.vrq';      -- クエリー様式ファイル名
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                     -- 出力区分（ＰＤＦ）
--
  --顧客区分
  cv_cust_class_chain       CONSTANT hz_cust_accounts.customer_class_code%TYPE := '18';
  cv_cust_class_store       CONSTANT hz_cust_accounts.customer_class_code%TYPE := '10';
  cv_cust_class_base        CONSTANT hz_cust_accounts.customer_class_code%TYPE := '1';
--
-- 2010/01/19 M.Sano Ver.1.7 add start
  --再発行区分
  cv_exec_type_new          CONSTANT VARCHAR2(1)   := '0';              -- 再発行区分「新規」
--
  --言語コード
  cv_default_language       CONSTANT VARCHAR2(10)  := USERENV('LANG');  -- 標準言語タイプ
--
  --フラグ
  cv_enabled_flag_yes       CONSTANT VARCHAR2(1)   := 'Y';              -- 有効フラグ「有効」
  cv_output_flag_yes        CONSTANT VARCHAR2(1)   := 'Y';              -- 参照タイプ.属性1～3(出力フラグ)：出力対象
  cv_err_list_out_flag_yes  CONSTANT VARCHAR2(1)   := 'Y';              -- エラーリスト出力済フラグ:Yes
  cv_err_list_out_flag_no0  CONSTANT VARCHAR2(2)   := 'N0';             -- エラーリスト出力済フラグ:No(新規)
  cv_attribute4_d_line      CONSTANT VARCHAR2(1)   := '1';              -- ワークテーブル削除区分:該当行
  cv_attribute4_d_head      CONSTANT VARCHAR2(1)   := '2';              -- ワークテーブル削除区分:伝票単位
--
  --存在チェック出力用
  cv_exists_flag            CONSTANT VARCHAR2(1)   := 'Y';
-- 2010/01/19 M.Sano Ver.1.7 add end
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ情報
  TYPE g_input_rtype IS RECORD (
    err_list_type        VARCHAR2(100) --エラーリスト種別
   ,err_list_type_name   fnd_lookup_values.description%TYPE --エラーリスト種別名
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,request_type           VARCHAR2(100) --再発行区分
   ,base_code              VARCHAR2(100) --拠点コード
   ,edi_chain_code         VARCHAR2(100) --EDIチェーン店コード
   ,edi_received_date_from DATE          --EDI受信日(FROM)
   ,edi_received_date_to   DATE          --EDI受信日(TO)
-- 2010/01/19 M.Sano Ver.1.7 add end
  );
--
  --プロファイル情報
  TYPE g_prf_rtype IS RECORD (
    organization_code    fnd_profile_option_values.profile_option_value%TYPE --在庫組織コード
   ,organization_id      NUMBER --在庫組織ID
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,biz_man_dept_code    fnd_profile_option_values.profile_option_value%TYPE --業務管理部コード
-- 2010/01/19 M.Sano Ver.1.7 add end
  );
--
  --EDIエラー情報格納レコード
  TYPE g_edi_err_rtype IS RECORD (
    base_code            hz_cust_accounts.account_number%TYPE     --拠点コード
   ,base_name            hz_parties.party_name%TYPE               --拠点名称
   ,edi_create_class     xxcos_edi_errors.edi_create_class%TYPE   --EDI作成元区分
   ,chain_code           xxcos_edi_errors.chain_code%TYPE         --チェーン店コード
   ,chain_name           hz_parties.party_name%TYPE               --チェーン店名称
   ,dlv_date             VARCHAR2(10)                             --納品日
   ,invoice_number       xxcos_edi_errors.invoice_number%TYPE     --伝票番号
   ,shop_code            xxcos_edi_errors.shop_code%TYPE          --店舗コード
   ,customer_number      hz_cust_accounts.account_number%TYPE     --顧客コード
   ,shop_name            xxcmm_cust_accounts.cust_store_name%TYPE --店舗名称
-- 2012/08/02 T.Osawa Ver.1.8 add start
   ,shop_name_alt        xxcos_edi_errors.shop_name_alt%TYPE      --店舗名称（カナ）
-- 2012/08/02 T.Osawa Ver.1.8 add end
   ,line_no              xxcos_edi_errors.line_no%TYPE            --行No
   ,item_code            xxcos_edi_errors.item_code%TYPE          --品目コード
   ,edi_item_code        xxcos_edi_errors.edi_item_code%TYPE      --EDI商品コード
-- 2010/01/19 M.Sano Ver.1.7 mod start
--   ,item_name            xxcmn_item_mst_b.item_short_name%TYPE    --品目名称
   ,item_name            xxcos_edi_errors.edi_item_name%TYPE      --品目名称
-- 2010/01/19 M.Sano Ver.1.7 mod end
   ,quantity             xxcos_edi_errors.quantity%TYPE           --本数
   ,unit_price           xxcos_edi_errors.unit_price%TYPE         --原単価
   ,unit_price_amount    NUMBER                                   --原価金額
   ,err_message          xxcos_edi_errors.err_message%TYPE        --エラー内容
   ,edi_err_id           xxcos_edi_errors.edi_err_id%TYPE         --EDIエラーID
   ,delete_flag          xxcos_edi_errors.delete_flag%TYPE        --削除フラグ
   ,work_id              xxcos_edi_errors.work_id%TYPE            --ワークID
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,output_flag          fnd_lookup_values.attribute3%TYPE        --出力フラグ
-- 2010/01/19 M.Sano Ver.1.7 add end
  );
--
  --EDIエラー情報格納テーブル
  TYPE g_edi_err_ttype IS TABLE OF g_edi_err_rtype INDEX BY BINARY_INTEGER;
--
  --受注エラーリスト登録用テーブル
  TYPE g_work_ttype IS TABLE OF xxcos_rep_order_err_list%rowtype INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_input_rec           g_input_rtype; 
  g_input_rec_init      g_input_rtype;
  g_edi_err_tab         g_edi_err_ttype;
  g_process_date        DATE;
-- 2010/01/19 M.Sano Ver.1.7 add start
  g_profile_rec         g_prf_rtype;
-- 2010/01/19 M.Sano Ver.1.7 add end
-- ****************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
  gn_lock_flg           NUMBER := 0;                     -- ロックフラグ
-- ****************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ログ出力
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lb_fnd_file boolean := true;
    lb_out boolean := false;
  BEGIN
    IF (lb_out) THEN
      IF (lb_fnd_file) THEN
        FND_FILE.PUT_LINE(
           which  => which
          ,buff   => buff
        );
      ELSE
        dbms_output.put_line(buff);
      END IF;
    END IF;
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_tkn                                   fnd_new_messages.message_text%TYPE;                    --メッセージ用文字列
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    --入力パラメータの出力
    --==============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => ct_apl_name
                  ,iv_name               => ct_msg_parameters
                  ,iv_token_name1        => cv_tkn_param1
                  ,iv_token_value1       => g_input_rec.err_list_type
-- 2010/01/19 M.Sano Ver.1.7 add start
                  ,iv_token_name2        => cv_tkn_param2
                  ,iv_token_value2       => g_input_rec.request_type
                  ,iv_token_name3        => cv_tkn_param3
                  ,iv_token_value3       => g_input_rec.base_code
                  ,iv_token_name4        => cv_tkn_param4
                  ,iv_token_value4       => g_input_rec.edi_chain_code
                  ,iv_token_name5        => cv_tkn_param5
                  ,iv_token_value5       => TO_CHAR(g_input_rec.edi_received_date_from, cv_fmt_date)
                  ,iv_token_name6        => cv_tkn_param6
                  ,iv_token_value6       => TO_CHAR(g_input_rec.edi_received_date_to, cv_fmt_date)
-- 2010/01/19 M.Sano Ver.1.7 add end
                 );
--
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1行空白
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==============================================================
    --業務日付の取得
    --==============================================================
    g_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
-- 2010/01/19 M.Sano Ver.1.7 add start
    --==============================================================
    --プロファイルの取得(業務管理部コード)
    --==============================================================
    g_profile_rec.biz_man_dept_code := FND_PROFILE.VALUE( ct_prf_biz_man_dept_code );
--
    -- プロファイルが取得できなかった場合 ⇒ プロファイルエラー(業務管理部コード)
    IF ( g_profile_rec.biz_man_dept_code IS NULL ) THEN
      lt_tkn := xxccp_common_pkg.get_msg( ct_apl_name, ct_msg_biz_man_dept_code );
      RAISE profile_expt;
    END IF;
--
-- 2010/01/19 M.Sano Ver.1.7 add end
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
-- 2010/01/19 M.Sano Ver.1.7 add start
    -- *** プロファイル取得エラーハンドラ ***
    WHEN profile_expt THEN
      -- メッセージを取得
      lv_errmsg := xxccp_common_pkg.get_msg( ct_apl_name, cv_msg_profile, cv_tkn_profile, lt_tkn );
      lv_errbuf := lv_errmsg;
      -- 出力項目にセット
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- 2010/01/19 M.Sano Ver.1.7 add end
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
   * Procedure Name   : delete_report_work
   * Description      : 帳票ワークテーブル削除処理(A-7)
   ***********************************************************************************/
  PROCEDURE delete_report_work(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_report_work'; -- プログラム名
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
    lv_table_name VARCHAR2(30);
    lv_key_info VARCHAR2(100);
    lv_errbuf_tmp VARCHAR2(5000);
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
    --受注エラーリスト帳票ワークテーブル削除
    --==============================================================
    BEGIN
      DELETE FROM xxcos_rep_order_err_list xroel
      WHERE xroel.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE delete_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN delete_expt THEN
      --キー情報編集
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf_tmp            --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
       ,iv_item_name1  => ct_msg_request_id
       ,iv_data_value1 => cn_request_id
      );
--
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application   => ct_apl_name
                        ,iv_name          => ct_msg_work_tab_name
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_delete_err
                    ,cv_tkn_table_name
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_report_work;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
--
-- ********* 2009/09/29 N.Maeda 1.6 ADD START ********* --
    PRAGMA AUTONOMOUS_TRANSACTION; -- 独立トランザクション
-- ********* 2009/09/29 N.Maeda 1.6 ADD  END  ********* --
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_file_name VARCHAR2(1000);
    lt_api_name fnd_new_messages.message_text%TYPE;
    lt_msg_nodata fnd_new_messages.message_text%TYPE;
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
    --0件メッセージ取得
    --==============================================================
    lt_msg_nodata := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_nodata
                     );
--
    --==============================================================
    --ファイル名取得
    --==============================================================
    lv_file_name := cv_file_id || TO_CHAR(SYSDATE, cv_fmt_date8) || TO_CHAR(cn_request_id) || cv_extension;
--
    --==============================================================
    --共通関数.SVF起動API実行
    --==============================================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_file_id,
      iv_output_mode          => cv_output_mode_pdf,
      iv_frm_file             => cv_frm_file,
      iv_vrq_file             => cv_vrq_file,
      iv_org_id               => NULL,
      iv_user_name            => NULL,
      iv_resp_name            => NULL,
      iv_doc_name             => NULL,
      iv_printer_name         => NULL,
      iv_request_id           => TO_CHAR( cn_request_id ),
      iv_nodata_msg           => lt_msg_nodata,
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
      RAISE execute_svf_expt;
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN execute_svf_expt THEN
      ROLLBACK;
      --API名取得
      lt_api_name := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_svf_api
                     );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_api_err
                    ,cv_tkn_api_name
                    ,lt_api_name
                   );
--
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
   * Procedure Name   : delete_edi
   * Description      : EDIテーブル削除処理(A-5)
   ***********************************************************************************/
  PROCEDURE delete_edi(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_edi'; -- プログラム名
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
    cv_delete VARCHAR2(1) := 'Y';
    cv_order VARCHAR2(2) := '01';
    cv_dlv_rtn VARCHAR2(2) := '02';
--
    -- *** ローカル変数 ***
    lv_table_name VARCHAR2(30);
    lv_key_info VARCHAR2(100);
    lv_errbuf_tmp VARCHAR2(5000);
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
    --EDIエラーテーブルのエラーリスト出力済フラグの更新
    --==============================================================
    BEGIN
      FOR i IN 1..g_edi_err_tab.COUNT LOOP
-- 2010/01/19 M.Sano Ver.1.7 mod start
--        UPDATE xxcos_edi_errors SET request_id = cn_request_id
--        WHERE edi_err_id = g_edi_err_tab(i).edi_err_id;
        -- エラーリスト出力済フラグが「Y」以外の場合、フラグを更新。
        UPDATE xxcos_edi_errors
        SET    err_list_out_flag       = cv_err_list_out_flag_yes,   -- 受注エラーリスト出力済フラグ
               last_updated_by         = cn_last_updated_by,         -- 最終更新者
               last_update_date        = cd_last_update_date,        -- 最終更新日
               last_update_login       = cn_last_update_login,       -- 最終更新ログイン
               request_id              = cn_request_id,              -- 要求ID
               program_application_id  = cn_program_application_id,  -- コンカレント・プログラム・アプリケーションID
               program_id              = cn_program_id,              -- コンカレント・プログラムID
               program_update_date     = cd_program_update_date      -- プログラム更新日
        WHERE  edi_err_id              = g_edi_err_tab(i).edi_err_id
        AND  (  err_list_out_flag     <> cv_err_list_out_flag_yes
             OR err_list_out_flag     IS NULL );
-- 2010/01/19 M.Sano Ver.1.7 mod end
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        --テーブル名取得
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application   => ct_apl_name
                          ,iv_name          => ct_msg_edi_err_tab
                         );
        RAISE update_expt;
    END;
--
    --==============================================================
    --EDI受注情報ワークテーブル・EDI納品返品情報ワークテーブルの削除
    --==============================================================
    IF (g_input_rec.err_list_type = cv_order) THEN
--
      BEGIN
        --EDI受注情報ワークテーブルの削除
        DELETE FROM xxcos_edi_order_work xeow
        WHERE xeow.order_info_work_id IN (
          SELECT xee.work_id
          FROM   xxcos_edi_errors xee
-- 2010/01/19 M.Sano Ver.1.7 add start
               , fnd_lookup_values    flv
-- 2010/01/19 M.Sano Ver.1.7 add end
          WHERE  xee.request_id = cn_request_id
          AND    xee.delete_flag = cv_delete
-- 2010/01/19 M.Sano Ver.1.7 add start
          -- [クイックコード]条件
          AND    flv.meaning               = xee.err_message_code                   -- メッセージコードが概要と同一
          AND    flv.lookup_type           = ct_order_err_list_message              -- タイプ:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_line                   -- ワークテーブル削除区分：該当行
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
         UNION ALL
          SELECT xeow_d.order_info_work_id
          FROM   xxcos_edi_errors     xee
               , fnd_lookup_values    flv
               , xxcos_edi_order_work xeow_e
               , xxcos_edi_order_work xeow_d
          WHERE  xee.request_id            = cn_request_id                          -- 本コンカレントで更新した要求
          AND    xee.delete_flag           = cv_delete                              -- 削除対象
          -- [クイックコード]条件
          AND    flv.meaning               = xee.err_message_code                   -- メッセージコードが概要と同一
          AND    flv.lookup_type           = ct_order_err_list_message              -- タイプ:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_head                   -- ワークテーブル削除区分：伝票単位
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
          -- [EDIワークTBL_EDIエラー情報に紐付くレコード]条件
          AND    xeow_e.order_info_work_id = xee.work_id                            -- ワークTBLID
          -- [EDIワークTBL_削除対象]条件
          AND    xeow_d.if_file_name       = xeow_e.if_file_name                    -- IFファイル名が同一
          AND    TRUNC(xeow_d.creation_date)
                                           = TRUNC(xeow_e.creation_date)            -- 作成日が同一
          AND    xeow_d.edi_chain_code     = xeow_e.edi_chain_code                  -- 顧客が同一
          AND  (   (  xeow_d.shop_code     = xeow_e.shop_code )
                OR (  xeow_d.shop_code IS NULL AND xeow_e.shop_code IS NULL ))      -- 店コードが同一
          AND  (   (  xeow_d.shop_delivery_date = xeow_e.shop_delivery_date )
                OR (  xeow_d.shop_delivery_date IS NULL
                    AND
                      xeow_e.shop_delivery_date IS NULL ) )                         -- 店舗納品日が同一
          AND    xeow_d.invoice_number     = xeow_e.invoice_number                  -- 伝票番号が同一
-- 2010/01/19 M.Sano Ver.1.7 add end
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          --テーブル名取得
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application   => ct_apl_name
                            ,iv_name          => ct_msg_order_work_tab
                           );
          RAISE delete_expt;
      END;
--
    ELSIF (g_input_rec.err_list_type = cv_dlv_rtn) THEN
--
      BEGIN
        --EDI納品返品情報ワークテーブルの削除
        DELETE FROM xxcos_edi_delivery_work xedw
        WHERE xedw.delivery_return_work_id IN (
          SELECT xee.work_id
          FROM   xxcos_edi_errors xee
-- 2010/01/19 M.Sano Ver.1.7 add start
               , fnd_lookup_values    flv
-- 2010/01/19 M.Sano Ver.1.7 add end
          WHERE  xee.request_id = cn_request_id
          AND    xee.delete_flag = cv_delete
-- 2010/01/19 M.Sano Ver.1.7 add start
          -- [クイックコード]条件
          AND    flv.meaning               = xee.err_message_code                   -- メッセージコードが概要と同一
          AND    flv.lookup_type           = ct_order_err_list_message              -- タイプ:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_line                   -- ワークテーブル削除区分：該当行
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
         UNION ALL
          SELECT xeow_d.delivery_return_work_id
          FROM   xxcos_edi_errors        xee
               , fnd_lookup_values       flv
               , xxcos_edi_delivery_work xeow_e
               , xxcos_edi_delivery_work xeow_d
          WHERE  xee.request_id            = cn_request_id                          -- 本コンカレントで更新した要求
          AND    xee.delete_flag           = cv_delete                              -- 削除対象
          -- [クイックコード]条件
          AND    flv.meaning               = xee.err_message_code                   -- メッセージコードが概要と同一
          AND    flv.lookup_type           = ct_order_err_list_message              -- タイプ:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_head                   -- ワークテーブル削除区分：伝票単位
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
          -- [EDIワークTBL_EDIエラー情報に紐付くレコード]条件
          AND    xeow_e.delivery_return_work_id = xee.work_id                            -- ワークTBLID
          -- [EDIワークTBL_削除対象]条件
          AND    xeow_d.if_file_name       = xeow_e.if_file_name                    -- IFファイル名が同一
          AND    TRUNC(xeow_d.creation_date)
                                           = TRUNC(xeow_e.creation_date)            -- 作成日が同一
          AND    xeow_d.edi_chain_code     = xeow_e.edi_chain_code                  -- 顧客が同一
          AND  (   (  xeow_d.shop_code     = xeow_e.shop_code )
                OR (  xeow_d.shop_code IS NULL AND xeow_e.shop_code IS NULL ))      -- 店コードが同一
          AND  (   (  xeow_d.shop_delivery_date = xeow_e.shop_delivery_date )
                OR (  xeow_d.shop_delivery_date IS NULL
                    AND
                      xeow_e.shop_delivery_date IS NULL ) )                         -- 店舗納品日が同一
          AND    xeow_d.invoice_number     = xeow_e.invoice_number                  -- 伝票番号が同一
-- 2010/01/19 M.Sano Ver.1.7 add end
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          --テーブル名取得
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application   => ct_apl_name
                            ,iv_name          => ct_msg_dlv_rtn_work_tab
                           );
          RAISE delete_expt;
      END;
    END IF;
--
-- 2010/01/19 M.Sano Ver.1.7 del start
--    --==============================================================
--    --EDIエラー情報テーブルの削除
--    --==============================================================
----
--    BEGIN
--      --EDIエラー情報テーブルの削除
--      DELETE FROM xxcos_edi_errors xee
--      WHERE xee.request_id = cn_request_id
--      ;
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errbuf := SQLERRM;
--        --テーブル名取得
--        lv_table_name := xxccp_common_pkg.get_msg(
--                           iv_application   => ct_apl_name
--                          ,iv_name          => ct_msg_edi_err_tab
--                         );
----
--        RAISE delete_expt;
--    END;
-- 2010/01/19 M.Sano Ver.1.7 del end
--
    out_line(buff => cv_prg_name || ' end');
--
  EXCEPTION
    WHEN update_expt THEN
      --キー情報編集
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf_tmp            --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
       ,iv_item_name1  => ct_msg_request_id
       ,iv_data_value1 => cn_request_id
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_update_err
                    ,cv_tkn_table_name
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN delete_expt THEN
      --キー情報編集
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf_tmp            --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
       ,iv_item_name1  => ct_msg_request_id
       ,iv_data_value1 => cn_request_id
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_delete_err
                    ,cv_tkn_table_name
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_edi;
--
  /**********************************************************************************
   * Procedure Name   : insert_report_work
   * Description      : 帳票ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE insert_report_work(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
-- ********* 2009/09/29 N.Maeda 1.6 DEL START ********* --
--    PRAGMA AUTONOMOUS_TRANSACTION;
-- ********* 2009/09/29 N.Maeda 1.6 DEL  END  ********* --
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_report_work'; -- プログラム名
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
    lv_table VARCHAR2(100);
-- 2010/01/19 M.Sano Ver.1.7 add start
    lv_work_idx    NUMBER   := 0;
-- 2010/01/19 M.Sano Ver.1.7 add end
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_work_tab g_work_ttype;
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
    --帳票ワークテーブルの登録
    --==============================================================
    FOR i IN 1..g_edi_err_tab.COUNT LOOP
-- 2010/01/19 M.Sano Ver.1.7 mod start
--      SELECT xxcos_rep_order_err_list_s01.NEXTVAL INTO l_work_tab(i).record_id FROM DUAL;
--      l_work_tab(i).base_code                   := SUBSTRB(g_edi_err_tab(i).base_code,1,4);
--      l_work_tab(i).base_name                   := SUBSTRB(g_edi_err_tab(i).base_name,1,20);
--      l_work_tab(i).edi_create_class            := SUBSTRB(g_edi_err_tab(i).edi_create_class,1,1);
--      l_work_tab(i).edi_create_class_name       := SUBSTRB(g_input_rec.err_list_type_name,1,14);
--      l_work_tab(i).chain_code                  := SUBSTRB(g_edi_err_tab(i).chain_code,1,4);
--      l_work_tab(i).chain_name                  := SUBSTRB(g_edi_err_tab(i).chain_name,1,40);
--      l_work_tab(i).dlv_date                    := SUBSTRB(g_edi_err_tab(i).dlv_date,1,10);
--      l_work_tab(i).invoice_number              := SUBSTRB(g_edi_err_tab(i).invoice_number,1,12);
--      l_work_tab(i).shop_code                   := SUBSTRB(g_edi_err_tab(i).shop_code,1,10);
--      l_work_tab(i).customer_number             := SUBSTRB(g_edi_err_tab(i).customer_number,1,9);
--      l_work_tab(i).shop_name                   := SUBSTRB(g_edi_err_tab(i).shop_name,1,20);
--      l_work_tab(i).line_no                     := g_edi_err_tab(i).line_no;
--      l_work_tab(i).item_code                   := SUBSTRB(g_edi_err_tab(i).item_code,1,7);
--      l_work_tab(i).edi_item_code               := SUBSTRB(g_edi_err_tab(i).edi_item_code,1,20);
--      l_work_tab(i).item_name                   := SUBSTRB(g_edi_err_tab(i).item_name,1,20);
--      l_work_tab(i).quantity                    := g_edi_err_tab(i).quantity;
--      l_work_tab(i).unit_price                  := g_edi_err_tab(i).unit_price;
--      l_work_tab(i).unit_price_amount           := g_edi_err_tab(i).unit_price_amount;
--      l_work_tab(i).err_message                 := SUBSTRB(g_edi_err_tab(i).err_message,1,40);
--      l_work_tab(i).created_by                  := cn_created_by;
--      l_work_tab(i).creation_date               := cd_creation_date;
--      l_work_tab(i).last_updated_by             := cn_last_updated_by;
--      l_work_tab(i).last_update_date            := cd_last_update_date;
--      l_work_tab(i).last_update_login           := cn_last_update_login;
--      l_work_tab(i).request_id                  := cn_request_id;
--      l_work_tab(i).program_application_id      := cn_program_application_id;
--      l_work_tab(i).program_id                  := cn_program_id;
--      l_work_tab(i).program_update_date         := cd_program_update_date;
      -- EDIエラー情報が出力対象(帳票出力フラグが"Y")のレコードのみ登録する。
      IF ( g_edi_err_tab(i).output_flag = cv_output_flag_yes ) THEN
        -- 件数を加算
        lv_work_idx := lv_work_idx + 1;
        -- データを登録
        SELECT xxcos_rep_order_err_list_s01.NEXTVAL INTO l_work_tab(lv_work_idx).record_id FROM DUAL;
        l_work_tab(lv_work_idx).base_code                   := SUBSTRB(g_edi_err_tab(i).base_code,1,4);
        l_work_tab(lv_work_idx).base_name                   := SUBSTRB(g_edi_err_tab(i).base_name,1,20);
        l_work_tab(lv_work_idx).edi_create_class            := SUBSTRB(g_edi_err_tab(i).edi_create_class,1,1);
        l_work_tab(lv_work_idx).edi_create_class_name       := SUBSTRB(g_input_rec.err_list_type_name,1,14);
        l_work_tab(lv_work_idx).chain_code                  := SUBSTRB(g_edi_err_tab(i).chain_code,1,4);
        l_work_tab(lv_work_idx).chain_name                  := SUBSTRB(g_edi_err_tab(i).chain_name,1,40);
        l_work_tab(lv_work_idx).dlv_date                    := SUBSTRB(g_edi_err_tab(i).dlv_date,1,10);
        l_work_tab(lv_work_idx).invoice_number              := SUBSTRB(g_edi_err_tab(i).invoice_number,1,12);
        l_work_tab(lv_work_idx).shop_code                   := SUBSTRB(g_edi_err_tab(i).shop_code,1,10);
        l_work_tab(lv_work_idx).customer_number             := SUBSTRB(g_edi_err_tab(i).customer_number,1,9);
        l_work_tab(lv_work_idx).shop_name                   := SUBSTRB(g_edi_err_tab(i).shop_name,1,20);
-- 2012/08/02 T.Osawa Ver.1.8 add start
        l_work_tab(lv_work_idx).shop_name_alt               := SUBSTRB(g_edi_err_tab(i).shop_name_alt,1,20);
-- 2012/08/02 T.Osawa Ver.1.8 add end
        l_work_tab(lv_work_idx).line_no                     := g_edi_err_tab(i).line_no;
        l_work_tab(lv_work_idx).item_code                   := SUBSTRB(g_edi_err_tab(i).item_code,1,7);
        l_work_tab(lv_work_idx).edi_item_code               := SUBSTRB(g_edi_err_tab(i).edi_item_code,1,20);
        l_work_tab(lv_work_idx).item_name                   := SUBSTRB(g_edi_err_tab(i).item_name,1,20);
        l_work_tab(lv_work_idx).quantity                    := g_edi_err_tab(i).quantity;
        l_work_tab(lv_work_idx).unit_price                  := g_edi_err_tab(i).unit_price;
        l_work_tab(lv_work_idx).unit_price_amount           := g_edi_err_tab(i).unit_price_amount;
        l_work_tab(lv_work_idx).err_message                 := SUBSTRB(g_edi_err_tab(i).err_message,1,40);
        l_work_tab(lv_work_idx).created_by                  := cn_created_by;
        l_work_tab(lv_work_idx).creation_date               := cd_creation_date;
        l_work_tab(lv_work_idx).last_updated_by             := cn_last_updated_by;
        l_work_tab(lv_work_idx).last_update_date            := cd_last_update_date;
        l_work_tab(lv_work_idx).last_update_login           := cn_last_update_login;
        l_work_tab(lv_work_idx).request_id                  := cn_request_id;
        l_work_tab(lv_work_idx).program_application_id      := cn_program_application_id;
        l_work_tab(lv_work_idx).program_id                  := cn_program_id;
        l_work_tab(lv_work_idx).program_update_date         := cd_program_update_date;
      END IF;
-- 2010/01/19 M.Sano Ver.1.7 mod end
--
    END LOOP;
--
    BEGIN
      FORALL i IN 1..l_work_tab.COUNT
        INSERT INTO xxcos_rep_order_err_list VALUES l_work_tab(i);
--
      gn_normal_cnt := l_work_tab.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_table  := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_work_tab_name
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_insert_err
                      ,iv_token_name1   => cv_tkn_table_name
                      ,iv_token_value1  => lv_table
                      ,iv_token_name2   => cv_tkn_key
                      ,iv_token_value2  => NULL
                     );
        RAISE global_api_expt;
    END;
--
    COMMIT;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ROLLBACK;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ROLLBACK;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_report_work;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_tkn  fnd_new_messages.message_text%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR cur_err_list(
      i_input_rec g_input_rtype
    )
    IS
      SELECT base.account_number                                 base_code             --拠点コード
            ,base.party_name                                     base_name             --拠点名称
            ,xee.edi_create_class                                edi_create_class      --EDI作成元区分
            ,xee.chain_code                                      chain_code            --チェーン店コード
            ,chain.party_name                                    chain_name            --チェーン店名称
            ,TO_CHAR(xee.dlv_date,cv_fmt_date)                   dlv_date              --店舗納品日
            ,xee.invoice_number                                  invoice_number        --伝票番号
            ,xee.shop_code                                       shop_code             --店舗コード
            ,store.account_number                                customer_number       --顧客コード
            ,store.cust_store_name                               shop_name             --店舗名称
-- 2012/08/02 T.Osawa Ver.1.8 add start
            ,xee.shop_name_alt                                   shop_name_alt         --店舗名称（カナ）
-- 2012/08/02 T.Osawa Ver.1.8 add end
            ,xee.line_no                                         line_no               --行No
            ,xee.item_code                                       item_code             --品目コード
            ,xee.edi_item_code                                   edi_item_code         --EDI商品コード
-- 2010/01/19 M.Sano Ver.1.7 add start
--            ,ximb.item_short_name                                item_name             --品目名称
            ,xee.edi_item_name                                   item_name             --品目名称
-- 2010/01/19 M.Sano Ver.1.7 add end
            ,xee.quantity                                        quantity              --本数
            ,xee.unit_price                                      unit_price            --原単価
            ,round(xee.quantity * xee.unit_price,1)              unit_price_amount     --原価金額
            ,xee.err_message                                     err_message           --エラー内容
            ,xee.edi_err_id                                      edi_err_id            --エラーID
            ,xee.delete_flag                                     delete_flag           --削除フラグ
            ,xee.work_id                                         work_id               --ワークID
-- 2010/01/19 M.Sano Ver.1.7 add start
            ,CASE
               -- 入力.再発行区分 ＝ 新規                          ⇒ 属性1
               WHEN g_input_rec.request_type  = cv_exec_type_new THEN
                 flv.attribute1
               -- 入力.再発行区分 ≠ 新規, 入力.拠点 ＝ 業務管理部 ⇒ 属性2
               WHEN g_input_rec.request_type <> cv_exec_type_new
                AND g_input_rec.base_code     = g_profile_rec.biz_man_dept_code THEN
                 flv.attribute2
               -- 上記以外                                         ⇒ 属性3
               ELSE
                 flv.attribute3
             END                                                 output_flag           --帳票出力フラグ
-- 2010/01/19 M.Sano Ver.1.7 add end
      FROM   xxcos_edi_errors                                    xee                   --EDIエラーテーブル
-- 2010/01/19 M.Sano Ver.1.7 mod start
--            ,ic_item_mst_b                                       iimb                  --OPM品目マスタ
--            ,xxcmn_item_mst_b                                    ximb                  --OPM品目マスタアドオン
            -- クイックコード(受注エラーリスト出力メッセージ)情報
            ,fnd_lookup_values                                   flv
-- 2010/01/19 M.Sano Ver.1.7 mod end
            --チェーン店情報
            ,(
              SELECT  xca.chain_store_code                       chain_store_code      --チェーン店コード(EDI)
                      ,hp.party_name                             party_name            --顧客名称
              FROM    xxcmm_cust_accounts                        xca                   --顧客マスタアドオン
                      ,hz_cust_accounts                          hca                   --顧客マスタ
                      ,hz_parties                                hp                    --パーティマスタ
              WHERE   hca.cust_account_id = xca.customer_id
              AND     hca.customer_class_code = cv_cust_class_chain
              AND     hp.party_id = hca.party_id
             )                                                   chain                 --チェーン店情報
            --店舗情報
            ,(
              SELECT  xca.chain_store_code                       chain_store_code      --チェーン店コード(EDI)
                      ,xca.store_code                            store_code            --店舗コード
                      ,hca.account_number                        account_number        --顧客コード
                      ,xca.cust_store_name                       cust_store_name       --顧客店舗名称
                      ,xca.delivery_base_code                    delivery_base_code    --納品拠点コード
              FROM    xxcmm_cust_accounts                        xca                   --顧客マスタアドオン
                      ,hz_cust_accounts                          hca                   --顧客マスタ
              WHERE   hca.cust_account_id = xca.customer_id
              AND     hca.customer_class_code = cv_cust_class_store
             )                                                   store                 --店舗情報
            --拠点情報
            ,(
              SELECT  hca.account_number                         account_number        --顧客コード
                      ,hp.party_name                             party_name            --顧客名称
              FROM    hz_cust_accounts                           hca                   --顧客マスタ
                      ,hz_parties                                hp                    --パーティマスタ
              WHERE   hca.customer_class_code = cv_cust_class_base
              AND     hp.party_id = hca.party_id
             )                                                   base                  --拠点情報
            --
      WHERE xee.edi_create_class = i_input_rec.err_list_type
      AND   store.chain_store_code(+) = xee.chain_code
      AND   store.store_code(+) = xee.shop_code
      AND   chain.chain_store_code(+) = xee.chain_code
      AND   base.account_number(+) = store.delivery_base_code
-- 2010/01/19 M.Sano Ver.1.7 mod start
--      AND   iimb.item_no(+) = xee.item_code
--      AND   ximb.item_id(+) = iimb.item_id
--      AND   g_process_date
--        BETWEEN NVL(TRUNC(ximb.start_date_active),g_process_date)
--        AND     NVL(TRUNC(ximb.end_date_active),g_process_date)
      -- [クイックコード]条件
      AND   flv.meaning            = xee.err_message_code                   -- 概要とEDIエラー情報.エラーコードが同一
      AND   flv.lookup_type        = ct_order_err_list_message              -- XXCOS1_ORDER_ERR_LIST_MESSAGE
      AND   flv.enabled_flag       = cv_enabled_flag_yes
      AND   g_process_date   BETWEEN NVL(flv.start_date_active, g_process_date)
                                 AND NVL(flv.end_date_active,   g_process_date)
      AND   flv.language           = cv_default_language
      -- [再発行区分]条件
      AND ( (    (   xee.err_list_out_flag     = cv_err_list_out_flag_no0   -- エラーリスト出力済フラグ：N0 or NULL
                  OR xee.err_list_out_flag    IS NULL )
             AND (   g_input_rec.request_type  = cv_exec_type_new ) )       -- 再発行区分：新規
          OR
            (    xee.err_list_out_flag    <> cv_err_list_out_flag_no0       -- エラーリスト出力済フラグ：N0以外
             AND g_input_rec.request_type <> cv_exec_type_new )      )      -- 再発行区分：新規以外
      -- [拠点コード]条件
      AND ( (    g_input_rec.base_code IS NULL )                            -- 入力.拠点：NULL
          OR
            (    g_input_rec.base_code  = g_profile_rec.biz_man_dept_code 
             AND flv.attribute2         = cv_output_flag_yes             )  -- 入力.拠点：業務管理部
          OR
            (    g_input_rec.base_code   <> g_profile_rec.biz_man_dept_code -- 入力.拠点：業務管理部以外
             AND (   base.account_number  = g_input_rec.base_code
                  OR base.account_number IS NULL ) ) )                      -- 拠点情報.拠点コード : 入力.拠点 or NULL
      -- [チェーン店]条件
      AND (  ( g_input_rec.edi_chain_code IS NULL )
          OR ( g_input_rec.edi_chain_code  = xee.chain_code ) )             -- エラー.チェーン店 : 入力.チェーン店 or NULL
      -- [EDI受信日]条件
      -- 入力.EDI受信日(FROM) ≦ EDIエラー情報.EDI受信日 ≦ 入力.EDI受信日(TO)
      AND TRUNC(xee.edi_received_date) 
            >= NVL( g_input_rec.edi_received_date_from, TRUNC(xee.edi_received_date) )
      AND TRUNC(xee.edi_received_date) 
            <= NVL( g_input_rec.edi_received_date_to,   TRUNC(xee.edi_received_date) )
-- 2010/01/19 M.Sano Ver.1.7 mod end
      ORDER BY base.account_number
              ,xee.chain_code
              ,xee.dlv_date
              ,xee.invoice_number
              ,xee.shop_code
              ,xee.line_no
              ,xee.edi_item_code
      FOR UPDATE OF xee.edi_err_id NOWAIT
      ;
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
    --データ取得
    --==============================================================
    OPEN cur_err_list(g_input_rec);
    FETCH cur_err_list BULK COLLECT INTO g_edi_err_tab;
    CLOSE cur_err_list;
--
    gn_target_cnt := g_edi_err_tab.COUNT;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
    -- *** ロックエラーハンドラ ***
    WHEN resource_busy_expt THEN
-- ******************** 2009/07/23 N.Maeda 1.4 MOD START ******************************* --
      gn_lock_flg := 1; -- ロック中
--      lt_tkn := xxccp_common_pkg.get_msg(ct_apl_name, ct_msg_edi_err_tab);
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     ct_apl_name
--                    ,ct_msg_resource_busy_err
--                    ,cv_tkn_table
--                    ,lt_tkn
--                   );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--      ov_retcode := cv_status_error;
-- ******************** 2009/07/23 N.Maeda 1.4 MOD  END  ******************************* --
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
      IF (cur_err_list%ISOPEN) THEN
        CLOSE cur_err_list;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter'; -- プログラム名
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
    --==============================================================
    --エラーリスト種別チェック
    --==============================================================
    BEGIN
--
      SELECT xlvv.description                               --エラーリスト種別名称
      INTO   g_input_rec.err_list_type_name
      FROM   xxcos_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = ct_qc_err_list_type         --参照タイプ
      AND    xlvv.meaning = g_input_rec.err_list_type       --内容
      AND    xlvv.attribute1 = 'Y'                          --受注エラーリスト入力フラグ
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application        => ct_apl_name
                      ,iv_name               => ct_msg_err_list_err
                     );
        RAISE global_api_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
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
  END chk_parameter;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_err_list_type IN VARCHAR2
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,iv_request_type             IN VARCHAR2 --   再発行区分
   ,iv_base_code                IN VARCHAR2 --   拠点コード
   ,iv_edi_chain_code           IN VARCHAR2 --   チェーン店コード
   ,iv_edi_received_date_from   IN VARCHAR2 --   EDI受信日（FROM）
   ,iv_edi_received_date_to     IN VARCHAR2 --   EDI受信日（TO)
-- 2010/01/19 M.Sano Ver.1.7 add end
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
--2009/06/19  Ver1.3 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
--2009/06/19  Ver1.3 T1_1437  Add end
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
    --初期化
    g_input_rec := g_input_rec_init;
    g_input_rec.err_list_type := iv_err_list_type;
-- 2010/01/19 M.Sano Ver.1.7 add start
    g_input_rec.request_type           := NVL(iv_request_type, cv_exec_type_new);
    g_input_rec.base_code              := iv_base_code;
    g_input_rec.edi_chain_code         := iv_edi_chain_code;
    g_input_rec.edi_received_date_from := TO_DATE(iv_edi_received_date_from, cv_fmt_date);
    g_input_rec.edi_received_date_to   := TO_DATE(iv_edi_received_date_to, cv_fmt_date);
-- 2010/01/19 M.Sano Ver.1.7 add end
--
    -- ===============================================
    -- A-1.初期処理
    -- ===============================================
    init(
      lv_errbuf                   -- エラー・メッセージ
     ,lv_retcode                  -- リターン・コード
     ,lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2.パラメータチェック処理
    -- ===============================================
    chk_parameter(
      lv_errbuf                   -- エラー・メッセージ
     ,lv_retcode                  -- リターン・コード
     ,lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3.データ取得処理
    -- ===============================================
    get_data(
      lv_errbuf                   -- エラー・メッセージ
     ,lv_retcode                  -- リターン・コード
     ,lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- ******************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
    -- ロック中で無い場合
    IF ( gn_lock_flg = 0 ) THEN 
-- ******************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
      IF (gn_target_cnt > 0) THEN
        -- ===============================================
        -- A-4.帳票ワークテーブル登録処理
        -- ===============================================
        insert_report_work(
          lv_errbuf                   -- エラー・メッセージ
         ,lv_retcode                  -- リターン・コード
         ,lv_errmsg                   -- ユーザー・エラー・メッセージ
        );
--
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- A-5.EDIテーブル削除
        -- ===============================================
        delete_edi(
          lv_errbuf                   -- エラー・メッセージ
         ,lv_retcode                  -- リターン・コード
         ,lv_errmsg                   -- ユーザー・エラー・メッセージ
        );
--
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ===============================================
      -- A-6.SVF起動
      -- ===============================================
      execute_svf(
        lv_errbuf                   -- エラー・メッセージ
       ,lv_retcode                  -- リターン・コード
       ,lv_errmsg                   -- ユーザー・エラー・メッセージ
      );
--
-- 2009/06/19  Ver1.3 T1_1437  Mod start
--    --エラーでもワークテーブルを削除する為、エラー情報を保持
--    IF (lv_retcode != cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
      --
      --エラーでもワークテーブルを削除する為、エラー情報を保持
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
--
-- *********** 2009/09/29 N.Maeda 1.6 ADD START ************* --
      IF ( lv_retcode_svf != cv_status_normal  ) THEN
        ROLLBACK;
      END IF;
-- *********** 2009/09/29 N.Maeda 1.6 ADD  END  ************* --
--
-- 2009/06/19  Ver1.3 T1_1437  Mod End
--
      -- ===============================================
      -- A-7.帳票ワークテーブル削除
      -- ===============================================
      IF (gn_target_cnt > 0) THEN
        delete_report_work(
          lv_errbuf                   -- エラー・メッセージ
         ,lv_retcode                  -- リターン・コード
         ,lv_errmsg                   -- ユーザー・エラー・メッセージ
        );
      END IF;
--
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2009/06/19  Ver1.3 T1_1437  Add start
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
-- 2009/06/19  Ver1.3 T1_1437  Add End
-- 
-- 2009/08/03  Ver1.5 0000902  Mod Start
--      IF (gn_target_cnt = 0) THEN
--        ov_retcode := cv_status_warn;
--      END IF;
-- 2010/01/19 M.Sano Ver.1.7 mod start
--      IF ( gn_target_cnt > 0 ) THEN
      IF ( gn_normal_cnt > 0 ) THEN
-- 2010/01/19 M.Sano Ver.1.7 mod end
        ov_retcode := cv_status_warn;
      END IF;
-- 2009/08/03  Ver1.5 0000902  Mod End
-- ******************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
    -- ロック中の場合
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg( ct_apl_name , ct_msg_Processed_other );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
    END IF;
-- ******************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
--
    out_line(buff => cv_prg_name || ' end');
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
    errbuf        OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode       OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_err_list_type IN  VARCHAR2   --   エラーリスト種別
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,iv_request_type             IN VARCHAR2 DEFAULT NULL --   再発行区分
   ,iv_base_code                IN VARCHAR2 DEFAULT NULL --   拠点コード
   ,iv_edi_chain_code           IN VARCHAR2 DEFAULT NULL --   チェーン店コード
   ,iv_edi_received_date_from   IN VARCHAR2 DEFAULT NULL --   EDI受信日（FROM）
   ,iv_edi_received_date_to     IN VARCHAR2 DEFAULT NULL --   EDI受信日（TO)
-- 2010/01/19 M.Sano Ver.1.7 add end
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
    out_line(buff => cv_prg_name || ' start');
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
      iv_err_list_type
-- 2010/01/19 M.Sano Ver.1.7 add start
     ,iv_request_type                             --再発行区分
     ,iv_base_code                                --拠点コード
     ,iv_edi_chain_code                           --チェーン店コード
     ,iv_edi_received_date_from                   --EDI受信日（FROM）
     ,iv_edi_received_date_to                     --EDI受信日（TO)
-- 2010/01/19 M.Sano Ver.1.7 add end
     ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode  -- リターン・コード             --# 固定 #
     ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
-- ******************** 2009/07/23 N.Maeda 1.4 MOD START ******************************* --
    IF ( gn_lock_flg <> 0 ) THEN
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
    END IF;
-- ******************** 2009/07/23 N.Maeda 1.4 MOD  END  ******************************* --
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_target_cnt;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --空白行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
    out_line(buff => cv_prg_name || ' end');
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
END XXCOS010A05R;
/
