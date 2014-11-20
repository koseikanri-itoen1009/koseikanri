create or replace PACKAGE BODY XXCOS014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A10C(spec)
 * Description      : 預り金VD納品伝票データ作成
 * MD.050           : 預り金VD納品伝票データ作成 (MD050_COS_014_A10)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  create_header          ヘッダレコード作成処理(A-2)
 *  get_data               データ取得処理(A-3)
 *  out_csv_header         CSVヘッダレコード作成処理(A-4)
 *  out_csv_data           データレコード作成処理(A-5)
 *  out_csv_footer         フッタレコード作成処理(A-6)
 *  delete_work_tbl        ワークテーブル削除処理(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/06    1.0   S.Nakanishi      新規作成
 *  2009/03/19    1.1   S.Nakanishi      障害No.159対応
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
  resource_busy_expt      EXCEPTION;                                          --ロックエラー
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  --
  delete_tbl_expt         EXCEPTION;                                          --テーブル削除エラー
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS014A10C';                  --パッケージ名
--
  cv_apl_name      CONSTANT VARCHAR2(100) := 'XXCOS';                         --アプリケーション名
--
  --プロファイル
  ct_prf_if_header          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';           --XXCCP:ヘッダレコード識別子
  ct_prf_if_data            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';             --XXCCP:データレコード識別子
  ct_prf_if_footer          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';           --XXCCP:フッタレコード識別子
  ct_prf_rep_outbound_dir   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM'; --XXCOS:帳票OUTBOUND出力ディレクトリ(EBS在庫管理)
  ct_prf_utl_max_linesize   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';    --XXCOS:UTL_MAX行サイズ
  --
  --メッセージ
  ct_msg_fopen_err          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';         --ファイルオープンエラーメッセージ
  ct_msg_if_header          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';         --XXCCP:ヘッダレコード識別子
  ct_msg_if_footer          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';         --XXCCP:フッタレコード識別子
  ct_msg_rep_outbound_dir   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00112';         --XXCOS:帳票OUTBOUND出力ディレクトリ
  ct_msg_utl_max_linesize   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';         --XXCOS:UTL_MAX行サイズ
  ct_msg_delete_data        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';         --データ削除エラー
  cv_msg_nodata             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';         --対象データなしメッセージ
  ct_msg_get_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';         --取得エラー
  ct_msg_prf                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';         --プロファイル取得エラー
  ct_msg_input_parameters1  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13651';         --パラメータ出力メッセージ1
  ct_msg_input_parameters2  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13652';         --パラメータ出力メッセージ2
  ct_msg_file_name          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';         --ファイル名出力メッセージ
  ct_msg_work_tab_name      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13653';         --文字列.預り金VD納品伝票ワークテーブル
  ct_msg_group_id           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13654';         --文字列.グループID
  ct_msg_if_data            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';         --XXCCP:データレコード識別子
  ct_msg_resource_busy_err  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';         --ロックエラーメッセージ
--
  --トークン
  cv_tkn_filename           CONSTANT VARCHAR2(100) := 'FILE_NAME';            --ファイル名
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE_NAME';           --テーブル名
  cv_tkn_table2             CONSTANT VARCHAR2(20)  := 'TABLE';                --テーブル
  cv_key_data               CONSTANT VARCHAR2(20)  := 'KEY_DATA';             --編集されたキー情報
  cv_tkn_prm1               CONSTANT VARCHAR2(6)   := 'PARAM1';               --入力パラメータ1
  cv_tkn_prm2               CONSTANT VARCHAR2(6)   := 'PARAM2';               --入力パラメータ2
  cv_tkn_prm3               CONSTANT VARCHAR2(6)   := 'PARAM3';               --入力パラメータ3
  cv_tkn_prm4               CONSTANT VARCHAR2(6)   := 'PARAM4';               --入力パラメータ4
  cv_tkn_prm5               CONSTANT VARCHAR2(6)   := 'PARAM5';               --入力パラメータ5
  cv_tkn_prm6               CONSTANT VARCHAR2(6)   := 'PARAM6';               --入力パラメータ6
  cv_tkn_prm7               CONSTANT VARCHAR2(6)   := 'PARAM7';               --入力パラメータ7
  cv_tkn_prm8               CONSTANT VARCHAR2(6)   := 'PARAM8';               --入力パラメータ8
  cv_tkn_prm9               CONSTANT VARCHAR2(6)   := 'PARAM9';               --入力パラメータ9
  cv_tkn_prm10              CONSTANT VARCHAR2(7)   := 'PARAM10';              --入力パラメータ10
  cv_tkn_prm11              CONSTANT VARCHAR2(7)   := 'PARAM11';              --入力パラメータ11
  cv_tkn_prf                CONSTANT VARCHAR2(7)   := 'PROFILE';              --プロファイル
  cv_tkn_key                CONSTANT VARCHAR2(8)   := 'KEY_DATA';             --キー情報
--
  --その他
       cv_utl_file_mode     CONSTANT VARCHAR2(1)  := 'w';                     --UTL_FILE.オープンモード
       cv_date_fmt          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';              --日付書式
       cv_time_fmt          CONSTANT VARCHAR2(8)  := 'HH24MISS';              --書式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ格納レコード
  TYPE g_input_rtype IS RECORD (
    user_id                  NUMBER                                           --ユーザID
   ,chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE          --EDIチェーン店コード
   ,base_code                xxcmm_cust_accounts.delivery_base_code%TYPE      --拠点コード
   ,base_name                hz_parties.party_name%TYPE                       --拠点名
   ,chain_name               hz_parties.party_name%TYPE                       --チェーン店名
   ,report_code              xxcos_report_forms_register.report_code%TYPE     --帳票コード
   ,report_mode              xxcos_report_forms_register.report_name%TYPE     --帳票様式
   ,ebs_business_series_code VARCHAR2(100)                                    --業務系列コード
   ,file_name                VARCHAR2(100)                                    --ファイル名
   ,report_type_code         xxcos_report_forms_register.data_type_code%TYPE  --帳票種別コード
   ,rep_group_id             NUMBER                                           --グループID
    );
--
  --プロファイル値格納レコード
    TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE   --ヘッダレコード識別子
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE   --データレコード識別子
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE   --フッタレコード識別子
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE   --出力ディレクトリ
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE   --UTL_FILE最大行サイズ
   );
--
  --その他情報格納レコード
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                      --処理日
   ,proc_time                VARCHAR2(6)                                      --処理時刻
   ,organization_id          NUMBER                                           --在庫組織ID
   ,csv_header               VARCHAR2(32767)                                  --CSVヘッダ
   ,process_date             DATE                                             --業務日付
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_input_rec                g_input_rtype;                                   --入力パラメータ情報
  gf_file_handle             UTL_FILE.FILE_TYPE;                              --ファイルハンドル
  g_prf_rec                  g_prf_rtype;                                     --プロファイル情報
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;         --レイアウト定義情報
  g_other_rec                g_other_rtype;                                   --その他情報
  gb_delete                  boolean := TRUE;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1)   := CHR(34);                                  --ダブルクォーテーション
  cv_file_format             CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_file_type_variable;  --在庫
  cv_layout_class            CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_layout_class_order;  --レイアウト区分
  cv_delimiter               CONSTANT VARCHAR2(1)   := CHR(44);                                  --カンマ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
--
    -- *** ローカル変数 ***
--
    lb_error                                 BOOLEAN;                                      --エラー有りフラグ
    lt_tkn                                   fnd_new_messages.message_text%TYPE;           --メッセージ用文字列
--
    -- *** ローカル・カーソル ***
--
    lv_errbuf_all                            VARCHAR2(32767);                              --ログ出力メッセージ格納変数

    -- *** ローカル・レコード ***
--
    l_prf_rec g_prf_rtype;
    l_other_rec g_other_rtype;
    l_record_layout_tab xxcos_common2_pkg.g_record_layout_ttype;
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
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    -- コンカレントプログラム入力項目の出力
    --==============================================================
--
    --入力パラメータ1010の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name                --ファイル名
                                          ,cv_tkn_prm2 , g_input_rec.chain_code               --EDIチェーン店コード
                                          ,cv_tkn_prm3 , g_input_rec.report_code              --帳票コード
                                          ,cv_tkn_prm4 , g_input_rec.user_id                  --ユーザID
                                          ,cv_tkn_prm5 , g_input_rec.base_code                --拠点コード
                                          ,cv_tkn_prm6 , g_input_rec.base_name                --拠点名
                                          ,cv_tkn_prm7 , g_input_rec.chain_name               --チェーン店名
                                          ,cv_tkn_prm8 , g_input_rec.report_type_code         --帳票種別コード
                                          ,cv_tkn_prm9 , g_input_rec.ebs_business_series_code --業務系列コード
                                          ,cv_tkn_prm10, g_input_rec.report_mode              --帳票様式
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --入力パラメータ11の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.rep_group_id                  --グループID
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --==============================================================
    -- 3.1プロファイルの取得(XXCCP:ヘッダレコード識別子)
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
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.2プロファイルの取得(XXCCP:データレコード識別子)
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
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.3プロファイルの取得(XXCCP:フッタレコード識別子)
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
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.4プロファイルの取得(XXCOS:帳票OUTBOUND出力ディレクトリ)
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
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.5 プロファイルの取得(XXCOS:UTL_MAX行サイズ)
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
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
    --==============================================================
    --4.レイアウト定義情報の取得
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
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --5.処理日次取得
    --==============================================================
    l_other_rec.proc_date := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
    --==============================================================
    --グローバル変数のセット
    --==============================================================
    g_prf_rec := l_prf_rec;
    g_other_rec := l_other_rec;
    g_record_layout_tab := l_record_layout_tab;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : create_header
   * Description      : ヘッダレコード作成処理(A-2)
   ***********************************************************************************/
  PROCEDURE create_header(
    ov_errbuf     OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_header'; -- プログラム名
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
      g_prf_rec.if_header                      --付与区分
     ,g_input_rec.ebs_business_series_code             --ＩＦ元業務系列コード
     ,g_input_rec.base_code                            --拠点コード
     ,g_input_rec.base_name                            --拠点名称
     ,g_input_rec.chain_code                           --チェーン店コード
     ,g_input_rec.chain_name                           --チェーン店名称
     ,g_input_rec.report_type_code                     --データ種コード
     ,g_input_rec.report_code                          --帳票コード
     ,g_input_rec.report_mode                          --帳票表示名
     ,g_record_layout_tab.COUNT                        --項目数
     ,NULL                                             --データ件数
     ,lv_retcode                                       --リターンコード
     ,lv_if_header                                     --出力値
     ,lv_errbuf                                        --エラーメッセージ
     ,lv_errmsg                                        --ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ヘッダレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_if_header);
--
  EXCEPTION
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
  END create_header;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_header
   * Description      : CSVヘッダレコード作成処理(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_header(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_header'; -- プログラム名
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
  BEGIN
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
  END out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : データレコード作成処理(A-5)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- プログラム名
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
    lv_key_info            VARCHAR2(100);
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
    --==============================================================
    --データレコード編集
    --==============================================================
--
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
  END out_csv_data;
  /**********************************************************************************
   * Procedure Name   : out_csv_footer
   * Description      : フッタレコード作成処理(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv_footer(
    ov_errbuf     OUT NOCOPY VARCHAR2     --エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_footer'; -- プログラム名
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
    ln_target_cnt    NUMBER;
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
    IF gn_target_cnt > 0 THEN
      ln_target_cnt := gn_target_cnt + 1;--対象データ件数+CSVヘッダレコードの1件
    ELSE
      ln_target_cnt := 0;
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
     ,ln_target_cnt               --レコード件数(+ CSVヘッダレコード)
     ,lv_retcode                  --リターンコード
     ,lv_footer_record            --出力値
     ,lv_errbuf
     ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END out_csv_footer;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_tbl
   * Description      : ワークテーブル削除処理(A-8)
   ***********************************************************************************/
  PROCEDURE delete_work_tbl(
    iv_group_id    IN  NUMBER  ,      --グループID
    ov_errbuf     OUT VARCHAR2,       --エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,       --リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)       --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_tbl'; -- プログラム名
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
    lv_key_info            VARCHAR2(100);
    lv_table_name          VARCHAR2(30);
    lt_tkn                 fnd_new_messages.message_text%TYPE;         --メッセージ用文字列
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
     DELETE from xxcos_deposit_vd_slip_work                 xdvsw                  --預り金VD納品伝票ワークテーブル
     WHERE  xdvsw.group_id = iv_group_id;
--
     COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
    --*** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lt_tkn :=xxccp_common_pkg.get_msg(
                     iv_application   => cv_apl_name
                    ,iv_name          => ct_msg_group_id
                    );
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
       ,iv_item_name1  => lt_tkn                   --グループID
       ,iv_data_value1 => iv_group_id
   );
     --
     --メッセージ生成
     lv_table_name:= xxccp_common_pkg.get_msg(
                     iv_application   => cv_apl_name
                    ,iv_name          => ct_msg_work_tab_name
                    );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_delete_data
                    ,cv_tkn_table
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_work_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
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
    lt_tkn                        fnd_new_messages.message_text%TYPE;         --メッセージ用文字列
    lb_error                      BOOLEAN;
  --テーブル定義
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;              --出力データ情報
  --
    -- *** ローカル・カーソル ***
    CURSOR cur_data_record
    IS
      SELECT
            '01'                                       medium_class               --媒体区分
           ,g_input_rec.report_type_code               data_type_code             --データ種コード
           ,'00'                                       file_no                    --ファイルNo
           ,g_other_rec.proc_date                      process_date               --処理日
           ,g_other_rec.proc_time                      process_time               --処理時刻
           ,g_input_rec.base_code                      base_code                  --拠点（部門）コード
           ,g_input_rec.report_code                    report_code                --帳票コード
           ,g_input_rec.report_mode                    report_show_name           --帳票表示名
           ,xdvsw.company_name                         company_name               --社名（漢字）
           ,xdvsw.shop_code                            shop_code                  --店コード
           ,xdvsw.shop_name                            shop_name                  --店名（漢字）
           ,TO_CHAR(xdvsw.order_date,cv_time_fmt)      order_date                 --発注日
           ,'00000000'                                 result_delivery_date       --実納品日
           ,TO_CHAR(xdvsw.delivery_date,cv_time_fmt)   shop_delivery_date         --店舗納品日
           ,xdvsw.invoice_class                        invoice_class              --伝票区分
           ,xdvsw.classification_code                  big_classification_code    --大分類コード
           ,xdvsw.invoice_number                       invoice_number             --伝票番号
           ,xdvsw.vendor_code                          vendor_code                --取引先コード
           ,xdvsw.vendor_name                          vendor_name                --取引先名（漢字）
           ,xdvsw.sum_amount_title                     f1_column                  --F-1欄
           ,xdvsw.sum_amount                           f2_column                  --F-2欄
           ,xdvsw.line_no                              line_no                    --行No
           ,xdvsw.product_code                         product_code2              --商品コード2
           ,xdvsw.item_name                            product_name               --商品名（漢字）
           ,xdvsw.item_name_upper                      product_name1_alt          --商品名1(カナ)
           ,xdvsw.item_name_lower_l                    product_name2_alt          --商品名2(カナ)
           ,xdvsw.item_name_lower_r                    item_standard2             --規格2(item_name_lower_r)
           ,xdvsw.quantity                             sum_order_qty              --発注数量(合計、バラ)'quantity'
           ,'0'                                        sum_shipping_qty           --出荷数量（合計、バラ）
           ,xdvsw.unit_price                           order_unit_price           --現単価
           ,xdvsw.unit_price                           shipping_unit_price        --原単価（出荷）
           ,xdvsw.cost_amoount                         order_cost_amt             --原価金額（発注）
           ,'0'                                        shipping_cost_amt          --原価金額（出荷）
           ,xdvsw.selling_price                        selling_price              --売単価
           ,xdvsw.selling_amount                       order_price_amt            --売価金額（発注）
           ,'0'                                        shipping_price_amt         --売価金額（出荷）
           ,xdvsw.sum_quantity                         invoice_sum_order_qty      --（伝票計）発注数量（合計、バラ）
           ,'0'                                        invoice_sum_shipping_qty   --（伝票計）出荷数量（合計、バラ）
           ,xdvsw.sum_cost_amount                      invoice_order_cost_amt     --（伝票計）原価金額（発注）
           ,'0'                                        invoice_shipping_cost_amt  --（伝票計）原価金額（出荷）
           ,xdvsw.sum_selling_amount                   invoice_order_price_amt    --（伝票計）売価金額（発注）
           ,'0'                                        invoice_shipping_price_amt --（伝票計）売価金額（出荷）
      FROM  xxcos_deposit_vd_slip_work                 xdvsw                      
      WHERE xdvsw.group_id  = g_input_rec.rep_group_id
      --ロック
      FOR UPDATE OF xdvsw.group_id NOWAIT;--
--
    -- *** ローカル・レコード ***
    l_other_rec                g_other_rtype;          --その他情報
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lb_error := FALSE;
--
    --==============================================================
    --データレコード情報取得
    --==============================================================
    OPEN cur_data_record;
--
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
        l_data_tab('MEDIUM_CLASS')                     --媒体区分
       ,l_data_tab('DATA_TYPE_CODE')                   --データ種コード
       ,l_data_tab('FILE_NO')                          --ファイルNo
       ,l_data_tab('PROCESS_DATE')                     --処理日
       ,l_data_tab('PROCESS_TIME')                     --処理時刻
       ,l_data_tab('BASE_CODE')                        --拠点（部門）コード
       ,l_data_tab('REPORT_CODE')                      --帳票コード
       ,l_data_tab('REPORT_SHOW_NAME')                 --帳票表示名
       ,l_data_tab('COMPANY_NAME')                     --社名（漢字）
       ,l_data_tab('SHOP_CODE')                        --店コード
       ,l_data_tab('SHOP_NAME')                        --店名（漢字）
       ,l_data_tab('ORDER_DATE')                       --発注日
       ,l_data_tab('RESULT_DELIVERY_DATE')             --実納品日
       ,l_data_tab('SHOP_DELIVERY_DATE')               --店舗納品日
       ,l_data_tab('INVOICE_CLASS')                    --伝票区分
       ,l_data_tab('BIG_CLASSIFICATION_CODE')          --大分類コード
       ,l_data_tab('INVOICE_NUMBER')                   --伝票番号
       ,l_data_tab('VENDOR_CODE')                      --取引先コード
       ,l_data_tab('VENDOR_NAME')                      --取引先名（漢字）
       ,l_data_tab('F1_COLUMN')                        --F-1欄
       ,l_data_tab('F2_COLUMN')                        --F-2欄
       ,l_data_tab('LINE_NO')                          --行No
       ,l_data_tab('PRODUCT_CODE2')                    --商品コード2
       ,l_data_tab('PRODUCT_NAME')                     --商品名（漢字）
       ,l_data_tab('PRODUCT_NAME1_ALT')                --商品名1(カナ)
       ,l_data_tab('PRODUCT_NAME2_ALT')                --商品名2(カナ)
       ,l_data_tab('ITEM_STANDARD2')                   --規格2(item_name_lower_r)
       ,l_data_tab('SUM_ORDER_QTY')                    --発注数量(合計、バラ)'quantity'
       ,l_data_tab('SUM_SHIPPING_QTY')                 --出荷数量（合計、バラ）
       ,l_data_tab('ORDER_UNIT_PRICE')                 --現単価
       ,l_data_tab('SHIPPING_UNIT_PRICE')              --原単価（出荷）
       ,l_data_tab('ORDER_COST_AMT')                   --原価金額（発注）
       ,l_data_tab('SHIPPING_COST_AMT')                --原価金額（出荷）
       ,l_data_tab('SELLING_PRICE')                    --売単価
       ,l_data_tab('ORDER_PRICE_AMT')                  --売価金額（発注）
       ,l_data_tab('SHIPPING_PRICE_AMT')               --売価金額（出荷）
       ,l_data_tab('INVOICE_SUM_ORDER_QTY')            --（伝票計）発注数量（合計、バラ）
       ,l_data_tab('INVOICE_SUM_SHIPPING_QTY')         --（伝票計）出荷数量（合計、バラ）
       ,l_data_tab('INVOICE_ORDER_COST_AMT')           --（伝票計）原価金額（発注）
       ,l_data_tab('INVOICE_SHIPPING_COST_AMT')        --（伝票計）原価金額（出荷）
       ,l_data_tab('INVOICE_ORDER_PRICE_AMT')          --（伝票計）売価金額（発注）
       ,l_data_tab('INVOICE_SHIPPING_PRICE_AMT')       --（伝票計）売価金額（出荷）
      ;
      EXIT WHEN cur_data_record%NOTFOUND;
--
      --==============================================================
      --CSVヘッダレコード作成処理(A-4)
      --==============================================================
      IF (cur_data_record%ROWCOUNT = 1) THEN
        out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --データレコード作成処理(A-5)
      --==============================================================
      out_csv_data(
                   l_data_tab
                  ,lv_errbuf
                  ,lv_retcode
                  ,lv_errmsg
                           );
     IF (lv_retcode = cv_status_error) THEN
       RAISE global_api_expt;
     END IF;
--
    END LOOP data_record_loop;
--
IF (cur_data_record%ROWCOUNT = 0) THEN
      ov_retcode := cv_status_error;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name
                    ,iv_name         => cv_msg_nodata
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
END IF;
    --==============================================================
    --フッタレコード作成処理(A-6)
    --==============================================================
    out_csv_footer(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    CLOSE cur_data_record;
--
  EXCEPTION
--
    WHEN resource_busy_expt THEN
      gb_delete := false;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_work_tab_name);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table2
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_data;
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
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
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
    --==============================================================
    --初期処理(A-1)
    --==============================================================
    init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --ヘッダレコード作成処理(A-2)
    --==============================================================
    create_header(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --データレコード取得処理(A-3)
    --==============================================================
    get_data(
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
    errbuf                      OUT VARCHAR2,       --エラー・メッセージ  --# 固定 #
    retcode                     OUT VARCHAR2,       --リターン・コード    --# 固定 #
    iv_file_name                IN VARCHAR2,        -- 1.ファイル名
    iv_chain_code               IN VARCHAR2,        -- 2.チェーン店コード
    iv_report_code              IN VARCHAR2,        -- 3.帳票コード
    in_user_id                  IN NUMBER,          -- 4.ユーザーID
    iv_base_code                IN VARCHAR2,        -- 5.拠点コード
    iv_base_name                IN VARCHAR2,        -- 6.拠点名
    iv_chain_name               IN VARCHAR2,        -- 7.チェーン店名
    iv_report_type_code         IN VARCHAR2,        -- 8.帳票種別コード
    iv_ebs_business_series_code IN VARCHAR2,        -- 9.業務系列コード
    iv_report_mode              IN VARCHAR2,        --10.帳票様式
--
    in_group_id                 IN NUMBER           --12.グループID
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
    lv_retcode_del     VARCHAR2(1);
    --
    l_input_rec        g_input_rtype;
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
    -- 入力パラメータのセット
    -- ===============================================
    l_input_rec.file_name                := iv_file_name;                     -- 1.ファイル名
    l_input_rec.chain_code               := iv_chain_code;                    -- 2.チェーン店コード
    l_input_rec.report_code              := iv_report_code;                   -- 3.帳票コード
    l_input_rec.user_id                  := in_user_id;                       -- 4.ユーザID
    l_input_rec.base_code                := iv_base_code;                     -- 5.拠点コード
    l_input_rec.base_name                := iv_base_name;                     -- 6.拠点名
    l_input_rec.chain_name               := iv_chain_name;                    -- 7.チェーン店名
    l_input_rec.report_type_code         := iv_report_type_code;              -- 8.帳票種別コード
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;      -- 9.業務系列コード
    l_input_rec.report_mode              := iv_report_mode;                   --10.帳票様式
    l_input_rec.rep_group_id             := in_group_id;                      --12.グループID
--
    g_input_rec := l_input_rec;
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
        --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF (lv_retcode != cv_status_warn AND gb_delete = TRUE) THEN
      --==============================================================
      --ワークテーブル削除処理(A-8)
      --==============================================================
      delete_work_tbl(
       g_input_rec.rep_group_id
       ,lv_errbuf
       ,lv_retcode_del
       ,lv_errmsg
      );
      IF ( lv_retcode_del = cv_status_error ) THEN
        gn_normal_cnt := 0;
        gn_error_cnt := gn_target_cnt;
              FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      lv_retcode := cv_status_error;
      END IF;
    END IF;
--

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
  --テーブル削除例外ハンドラ
      WHEN delete_tbl_expt THEN
      errbuf  := lv_errmsg;
      retcode := cv_status_error;
      ROLLBACK;
  --
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
END XXCOS014A10C;
