CREATE OR REPLACE PACKAGE BODY xxcmn770016cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770016cp(body)
 * Description      : 出庫実績表(プロト)
 * MD.050/070       : 月次〆処理(経理)Issue1.0 (T_MD050_BPO_770)
 *                    月次〆処理(経理)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_check_param_info      PROCEDURE : パラメータチェック(F-1)
 *  prc_submit_request        PROCEDURE : 帳票コンカレント実行(F-1)
 *  prc_param_init            PROCEDURE : 起動パラメータ設定(F-1)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/17    1.0   Y.Itou           新規作成
 *  2008/05/16    1.1   T.Endou          不具合ID:77F-09対応  処理年月パラYYYYM入力対応
 *  2008/12/18    1.2   A.Shiina         子コンカレントを起動したら終了
 *
 *****************************************************************************************/
--
--##### 固定グローバル定数宣言部 START #############################################################
--
  -- ======================================================
  -- コンカレントステータス
  -- ======================================================
  gv_status_normal    CONSTANT  VARCHAR2(1) := '0' ;
  gv_status_warn      CONSTANT  VARCHAR2(1) := '1' ;
  gv_status_error     CONSTANT  VARCHAR2(1) := '2' ;
--
  -- ======================================================
  -- テンプレート設定用（FND_REQUEST.ADD_LAYOUT）
  -- ======================================================
  gc_temp_language    CONSTANT  VARCHAR2(2) := 'JA' ;    -- 言語
  gc_temp_territory   CONSTANT  VARCHAR2(2) := 'JP' ;    -- 地域
  gc_output_format    CONSTANT  VARCHAR2(3) := 'PDF' ;   -- 出力フォーマット
--
  -- ======================================================
  -- メッセージ編集用
  -- ======================================================
  gv_msg_part         CONSTANT  VARCHAR2(3) := ' : ' ;
  gv_msg_cont         CONSTANT  VARCHAR2(3) := '.';
--
--##### 固定グローバル定数宣言部 END   #############################################################
--
--##### 固定グローバル変数宣言部 START #############################################################
--
  -- ======================================================
  -- テンプレート設定用（FND_REQUEST.ADD_LAYOUT）
  -- ======================================================
  gv_temp_appl_name             VARCHAR2(20) ;            -- アプリケーション短縮名
  gv_temp_program_id            VARCHAR2(20) ;            -- テンプレート名
--
  -- ======================================================
  -- コンカレント起動用（FND_REQUEST.SUBMIT_REQUEST）
  -- ======================================================
  gv_conc_appl_name             VARCHAR2(20) ;              -- アプリケーション短縮名
  gv_conc_program_id            VARCHAR2(20) ;              -- プログラム名
  gv_argument1                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０１
  gv_argument2                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０２
  gv_argument3                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０３
  gv_argument4                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０４
  gv_argument5                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０５
  gv_argument6                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０６
  gv_argument7                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０７
  gv_argument8                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０８
  gv_argument9                  VARCHAR2(100) := CHR(0) ;   -- パラメータ０９
  gv_argument10                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１０
  gv_argument11                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１１
  gv_argument12                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１２
  gv_argument13                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１３
  gv_argument14                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１４
  gv_argument15                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１５
  gv_argument16                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１６
  gv_argument17                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１７
  gv_argument18                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１８
  gv_argument19                 VARCHAR2(100) := CHR(0) ;   -- パラメータ１９
  gv_argument20                 VARCHAR2(100) := CHR(0) ;   -- パラメータ２０
--
--##### 固定グローバル定数宣言部 END   #############################################################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gc_pkg_name         CONSTANT  VARCHAR2(20) := 'xxcmn770016cp' ;   -- パッケージ名
  gc_sub_pkg_name     CONSTANT  VARCHAR2(20) := 'xxcmn770026c' ;   -- パッケージ名(ｻﾌﾞｺﾝｶﾚﾝﾄ)
  gc_appl_name        CONSTANT  VARCHAR2(20) := 'XXCMN' ;          -- メッセージ用
  gc_temp_appl_name   CONSTANT  VARCHAR2(20) := 'XXCMN' ;          -- アプリ短縮名（Template）
  gc_conc_appl_name   CONSTANT  VARCHAR2(20) := 'XXCMN' ;          -- アプリ短縮名（Concurrent）
--
  -- ===============================
  -- ユーザー変数グローバル定数
  -- ===============================
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
    proc_from                 VARCHAR2(6)       -- 01 : 処理年月FROM
   ,proc_to                   VARCHAR2(6)       -- 02 : 処理年月TO
   ,rcv_pay_div               VARCHAR2(5)       -- 03 : 受払区分
   ,rcv_pay_div_name          VARCHAR2(20)      --    : 受払区分名
   ,prod_div                  VARCHAR2(1)       -- 04 : 商品区分
   ,prod_div_name             VARCHAR2(20)      --    : 商品区分名
   ,item_div                  VARCHAR2(1)       -- 05 : 品目区分
   ,item_div_name             VARCHAR2(20)      --    : 品目区分名
   ,result_post               VARCHAR2(4)       -- 06 : 成績部署
   ,result_post_name          VARCHAR2(20)      --    : 成績部署名
   ,whse_code                 VARCHAR2(4)       -- 07 : 倉庫コード
   ,whse_code_name            VARCHAR2(20)      --    : 倉庫名
   ,party_code                VARCHAR2(4)       -- 08 : 出荷先コード
   ,party_code_name           VARCHAR2(20)      --    : 出荷先名
   ,crowd_type                VARCHAR2(1)       -- 09 : 郡種別
   ,crowd_code                VARCHAR2(4)       -- 10 : 郡コード
   ,acnt_crowd_code           VARCHAR2(4)       -- 11 : 経理群コード
  ) ;
--
--##### 固定共通例外宣言部 START ###################################################################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--##### 固定共通例外宣言部 END   ###################################################################
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : パラメータチェック(F-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info (
    ir_param           IN     rec_param_data   -- 01.入力パラメータ群
   ,ov_errbuf          OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT    VARCHAR2         --    リターン・コード             --# 固定 #
   ,ov_errmsg          OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    lc_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- プログラム名
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
    -- -------------------------------
    -- エラーメッセージ出力用
    -- -------------------------------
    -- エラーコード
    lc_err_code_01        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010' ;
    -- トークン名
    lc_token_name_01      CONSTANT VARCHAR2(100) := 'PARAMETER' ;
    lc_token_name_02      CONSTANT VARCHAR2(100) := 'VALUE' ;
    -- トークン値
    lc_token_value_01_01  CONSTANT VARCHAR2(100) := '処理年月（FROM）' ;
    lc_token_value_01_02  CONSTANT VARCHAR2(100) := '処理年月（TO）' ;
    -- 日付フォーマット
    lc_char_m_format      CONSTANT VARCHAR2(100) := 'YYYYMM' ;
--
    -- *** ローカル変数 ***
    -- -------------------------------
    -- エラーメッセージ出力用
    -- -------------------------------
    lv_err_code                    VARCHAR2(100) ;
    lv_token_name_01               VARCHAR2(100) ;
    lv_token_name_02               VARCHAR2(100) ;
    lv_token_value_01              VARCHAR2(100) ;
    lv_token_value_02              VARCHAR2(100) ;
--
    -- -------------------------------
    -- エラーハンドリング用
    -- -------------------------------
    ld_work_date                   DATE; -- 変換チェック用
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt           EXCEPTION ;     -- パラメータチェック例外
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 処理年月FROM
    -- ====================================================
    -- 日付変換チェック
    ld_work_date :=  FND_DATE.STRING_TO_DATE( ir_param.proc_from, lc_char_m_format );
    IF ( ld_work_date IS NULL ) THEN
      lv_err_code       := lc_err_code_01 ;
      lv_token_name_01  := lc_token_name_01 ;
      lv_token_name_02  := lc_token_name_02 ;
      lv_token_value_01 := lc_token_value_01_01 ;
      lv_token_value_02 := ir_param.proc_from ;
      RAISE parameter_check_expt ;
    END IF ;
    -- ====================================================
    -- 処理年月TO
    -- ====================================================
    -- 日付変換チェック
    ld_work_date :=  FND_DATE.STRING_TO_DATE( ir_param.proc_to, lc_char_m_format );
    IF ( ld_work_date IS NULL ) THEN
      lv_err_code       := lc_err_code_01 ;
      lv_token_name_01  := lc_token_name_01 ;
      lv_token_name_02  := lc_token_name_02 ;
      lv_token_value_01 := lc_token_value_01_02 ;
      lv_token_value_02 := ir_param.proc_to ;
      RAISE parameter_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( iv_application   => gc_appl_name
                                            ,iv_name          => lv_err_code
                                            ,iv_token_name1   => lv_token_name_01
                                            ,iv_token_name2   => lv_token_name_02
                                            ,iv_token_value1  => lv_token_value_01
                                            ,iv_token_value2  => lv_token_value_02 ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_param_init
   * Description      : 起動パラメータ設定(F-1)
   ***********************************************************************************/
  PROCEDURE prc_param_init (
    ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
   ,ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
   ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- =====================================================
    -- ローカル定数
    -- =====================================================
    lc_prg_name     CONSTANT  VARCHAR2(100) := 'prc_param_init' ;     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ローカル変数
    -- =====================================================
    -- -------------------------------
    -- 項目編集用
    -- -------------------------------
    lv_program_id             VARCHAR2(100)  ;      -- プログラム名
    lv_report_id              VARCHAR2(100)  ;      -- 帳票名
--
  BEGIN
--
    -- ======================================================
    -- テンプレート設定用変数の編集１
    -- ======================================================
    gv_temp_appl_name  := gc_temp_appl_name ;
--
    -- ======================================================
    -- コンカレント起動用変数の編集１
    -- ======================================================
    gv_conc_appl_name  := gc_conc_appl_name ;
    gv_argument1       := ir_param.proc_from ;        -- 01 : 処理年月FROM
    gv_argument2       := ir_param.proc_to ;          -- 02 : 処理年月TO
    gv_argument3       := ir_param.rcv_pay_div ;      -- 03 : 受払区分
    gv_argument4       := ir_param.prod_div ;         -- 04 : 商品区分
    gv_argument5       := ir_param.item_div ;         -- 05 : 品目区分
    gv_argument6       := ir_param.result_post ;      -- 06 : 成績部署
    gv_argument7       := ir_param.whse_code ;        -- 07 : 倉庫コード
    gv_argument8       := ir_param.party_code ;       -- 08 : 出荷先コード
    gv_argument9       := ir_param.crowd_type ;       -- 09 : 郡種別
    gv_argument10      := ir_param.crowd_code ;       -- 10 : 郡コード
    gv_argument11      := ir_param.acnt_crowd_code ;  -- 11 : 経理群コード
--
    -- =====================================================
    -- 起動コンカレントの選定
    -- =====================================================
--
    -- 集計パターン１設定 (集計：1.成績部署、2.品目区分、3.倉庫、4.出荷先)
    IF  ( ir_param.result_post IS NULL )
    AND ( ir_param.whse_code   IS NULL )
    AND ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_01 ;
--
    -- 集計パターン２設定 (集計：1.成績部署、2.品目区分、3.倉庫)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_02 ;
--
    -- 集計パターン３設定 (集計：1.成績部署、2.品目区分、3.出荷先)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_03 ;
--
    -- 集計パターン４設定 (集計：1.成績部署、2.品目区分)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_04 ;
--
    -- 集計パターン５設定 (集計：1.品目区分、2.倉庫、3.出荷先)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_05 ;
--
    -- 集計パターン６設定 (集計：1.品目区分、2.倉庫)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_06 ;
--
    -- 集計パターン７設定 (集計：1.品目区分、2.出荷先)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_07 ;
--
    -- 集計パターン８設定 (集計：1.品目区分)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      gv_argument12 := xxcmn770016cp.gc_rtf_name_08 ;
    END IF;
--
    -- =====================================================
    -- テンプレート設定用変数の編集
    -- =====================================================
    gv_temp_program_id := gv_argument12 || 'C';
 --
   -- =====================================================
    -- コンカレント設定用変数の編集
    -- =====================================================
    gv_conc_program_id := gc_sub_pkg_name;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
  END prc_param_init ;
--
--##### 固定プロシージャ START #####################################################################
  /**********************************************************************************
   * Procedure Name   : prc_submit_request
   * Description      : 帳票コンカレント実行(F-1)
   ***********************************************************************************/
  PROCEDURE prc_submit_request (
    ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
   ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- =====================================================
    -- 定数宣言
    -- =====================================================
    -- -------------------------------
    -- メッセージ出力用
    -- -------------------------------
    lc_prg_name             CONSTANT VARCHAR2(100) := 'prc_submit_request' ; -- プログラム名
    lc_err_code_template    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10134' ;
    lc_err_code_submit      CONSTANT VARCHAR2(100) := 'APP-XXCMN-10135' ;
    lc_err_code_wait        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10136' ;
    -- -------------------------------
    -- エラーハンドリング
    -- -------------------------------
    lc_dev_status_nomal     CONSTANT VARCHAR2(100) := 'NORMAL' ;
    lc_dev_status_warn      CONSTANT VARCHAR2(100) := 'WARNING' ;
    lc_dev_status_error     CONSTANT VARCHAR2(100) := 'ERROR' ;
--
    -- =====================================================
    -- 変数宣言
    -- =====================================================
    -- -------------------------------
    -- 終了ステータス
    -- -------------------------------
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
    -- -------------------------------
    -- 戻り値・アウトパラメータ
    -- -------------------------------
    lb_ret                  BOOLEAN ;
    ln_req_id               NUMBER ;
    lv_ret_phase            VARCHAR2(1000) ;
    lv_ret_status           VARCHAR2(1000) ;
    lv_ret_dev_phase        VARCHAR2(1000) ;
    lv_ret_dev_status       VARCHAR2(1000) ;
    lv_ret_message          VARCHAR2(1000) ;
--
  BEGIN
--
    -- =====================================================
    -- 出力帳票の指定
    -- =====================================================
    lb_ret := FND_REQUEST.ADD_LAYOUT (
                template_appl_name  => gv_temp_appl_name        -- アプリケーション短縮名
               ,template_code       => gv_temp_program_id       -- テンプレート名
               ,template_language   => gc_temp_language         -- 言語
               ,template_territory  => gc_temp_territory        -- 地域
               ,output_format       => gc_output_format         -- 出力フォーマット
              ) ;
    -- エラーの場合
    IF ( lb_ret = FALSE ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg (
                      iv_application   => gc_appl_name
                     ,iv_name          => lc_err_code_template
                   ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- =====================================================
    -- サブコンカレントの呼び出し
    -- =====================================================
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                   application       => gv_conc_appl_name    -- アプリケーション短縮名
                  ,program           => gv_conc_program_id   -- プログラム名
                  ,start_time        => SYSDATE              -- 実行日
                  ,argument1         => gv_argument1         -- パラメータ０１
                  ,argument2         => gv_argument2         -- パラメータ０２
                  ,argument3         => gv_argument3         -- パラメータ０３
                  ,argument4         => gv_argument4         -- パラメータ０４
                  ,argument5         => gv_argument5         -- パラメータ０５
                  ,argument6         => gv_argument6         -- パラメータ０６
                  ,argument7         => gv_argument7         -- パラメータ０７
                  ,argument8         => gv_argument8         -- パラメータ０８
                  ,argument9         => gv_argument9         -- パラメータ０９
                  ,argument10        => gv_argument10        -- パラメータ１０
                  ,argument11        => gv_argument11        -- パラメータ１１
                  ,argument12        => gv_argument12        -- パラメータ１２
                  ,argument13        => gv_argument13        -- パラメータ１３
                  ,argument14        => gv_argument14        -- パラメータ１４
                  ,argument15        => gv_argument15        -- パラメータ１５
                  ,argument16        => gv_argument16        -- パラメータ１６
                  ,argument17        => gv_argument17        -- パラメータ１７
                  ,argument18        => gv_argument18        -- パラメータ１８
                  ,argument19        => gv_argument19        -- パラメータ１９
                  ,argument20        => gv_argument20        -- パラメータ２０
                 ) ;
    -- エラーの場合
    IF ( ln_req_id = 0 ) THEN
      ROLLBACK ;
      lv_errmsg := xxcmn_common_pkg.get_msg (
                     iv_application   => gc_appl_name
                    ,iv_name          => lc_err_code_submit
                   ) ;
      RAISE global_api_expt ;
    END IF ;
--
-- 2008/12/18 v1.2 DELETE START
/*
    COMMIT ;
--
    -- =====================================================
    -- 待機処理
    -- =====================================================
    lb_ret := FND_CONCURRENT.WAIT_FOR_REQUEST (
                request_id   => ln_req_id          -- 要求ＩＤ
               ,interval     => 5                  -- スリープ時間
               ,phase        => lv_ret_phase       -- OUT : 要求フェーズ
               ,status       => lv_ret_status      -- OUT : 要求ステータス
               ,dev_phase    => lv_ret_dev_phase   -- OUT : 要求フェーズ（定数）
               ,dev_status   => lv_ret_dev_status  -- OUT : 要求ステータス（定数）
               ,message      => lv_ret_message     -- OUT : 完了メッセージ
              ) ;
    -- エラーの場合
    IF ( lb_ret = FALSE ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg (
                     iv_application   => gc_appl_name
                    ,iv_name          => lc_err_code_wait
                   ) ;
      RAISE global_api_expt ;
    END IF;
--
    -- サブコンカレントが異常終了した場合
    IF ( lv_ret_dev_status = lc_dev_status_error ) THEN
      ov_retcode := gv_status_error ;
--
    -- サブコンカレントが警告終了した場合
    ELSIF ( lv_ret_dev_status = lc_dev_status_warn ) THEN
      ov_retcode := gv_status_warn ;
--
    END IF ;
--
*/
-- 2008/12/18 v1.2 DELETE END
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
  END prc_submit_request ;
--##### 固定プロシージャ END   #####################################################################
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_from          IN    VARCHAR2  --   01 : 処理年月FROM
     ,iv_proc_to            IN    VARCHAR2  --   02 : 処理年月TO
     ,iv_rcv_pay_div        IN    VARCHAR2  --   03 : 受払区分
     ,iv_prod_div           IN    VARCHAR2  --   04 : 商品区分
     ,iv_item_div           IN    VARCHAR2  --   05 : 品目区分
     ,iv_result_post        IN    VARCHAR2  --   06 : 成績部署
     ,iv_whse_code          IN    VARCHAR2  --   07 : 倉庫コード
     ,iv_party_code         IN    VARCHAR2  --   08 : 出荷先コード
     ,iv_crowd_type         IN    VARCHAR2  --   09 : 郡種別
     ,iv_crowd_code         IN    VARCHAR2  --   10 : 郡コード
     ,iv_acnt_crowd_code    IN    VARCHAR2  --   11 : 経理群コード
     ,ov_errbuf            OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT    VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT    VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- パラメータ格納
    -- =====================================================
    lr_param_rec.proc_from       := iv_proc_from;          -- 処理年月FROM
    lr_param_rec.proc_to         := iv_proc_to;            -- 処理年月TO
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;        -- 受払区分
    lr_param_rec.prod_div        := iv_prod_div;           -- 商品区分
    lr_param_rec.item_div        := iv_item_div;           -- 品目区分
    lr_param_rec.result_post     := iv_result_post;        -- 成績部署
    lr_param_rec.whse_code       := iv_whse_code;          -- 倉庫コード
    lr_param_rec.party_code      := iv_party_code;         -- 出荷先コード
    lr_param_rec.crowd_type      := iv_crowd_type;         -- 郡種別
    lr_param_rec.crowd_code      := iv_crowd_code;         -- 郡コード
    lr_param_rec.acnt_crowd_code := iv_acnt_crowd_code;    -- 経理群コード
--
    -- =====================================================
    -- パラメータチェック
    -- =====================================================
    prc_check_param_info (
      ir_param          => lr_param_rec       -- 入力パラメータ群
     ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 起動パラメータ設定
    -- =====================================================
    prc_param_init (
      ir_param          => lr_param_rec       -- 入力パラメータ群
     ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 帳票コンカレント実行
    -- =====================================================
    prc_submit_request (
      ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  --   01 : 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : 処理年月TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : 受払区分
     ,iv_prod_div        IN    VARCHAR2  --   04 : 商品区分
     ,iv_item_div        IN    VARCHAR2  --   05 : 品目区分
     ,iv_result_post     IN    VARCHAR2  --   06 : 成績部署
     ,iv_whse_code       IN    VARCHAR2  --   07 : 倉庫コード
     ,iv_party_code      IN    VARCHAR2  --   08 : 出荷先コード
     ,iv_crowd_type      IN    VARCHAR2  --   09 : 郡種別
     ,iv_crowd_code      IN    VARCHAR2  --   10 : 郡コード
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : 経理群コード
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
        iv_proc_from        => iv_proc_from         --   01 : 処理年月FROM
       ,iv_proc_to          => iv_proc_to           --   02 : 処理年月TO
       ,iv_rcv_pay_div      => iv_rcv_pay_div       --   03 : 受払区分
       ,iv_prod_div         => iv_prod_div          --   04 : 商品区分
       ,iv_item_div         => iv_item_div          --   05 : 品目区分
       ,iv_result_post      => iv_result_post       --   06 : 成績部署
       ,iv_whse_code        => iv_whse_code         --   07 : 倉庫コード
       ,iv_party_code       => iv_party_code        --   08 : 出荷先コード
       ,iv_crowd_type       => iv_crowd_type        --   09 : 郡種別
       ,iv_crowd_code       => iv_crowd_code        --   10 : 郡コード
       ,iv_acnt_crowd_code  => iv_acnt_crowd_code   --   11 : 経理群コード
       ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode          => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxcmn770016cp ;
/
