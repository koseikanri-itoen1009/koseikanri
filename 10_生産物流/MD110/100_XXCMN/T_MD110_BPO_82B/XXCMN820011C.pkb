CREATE OR REPLACE PACKAGE BODY xxcmn820011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXCMN820011(body)
 * Description      : 原価差異表作成
 * MD.050/070       : 標準原価マスタIssue1.0(T_MD050_BPO_820)
 *                    原価差異表作成Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
 * Version          : 1.0
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_check_param_info      PROCEDURE : パラメータチェック(B-1)
 *  prc_submit_request        PROCEDURE : 帳票コンカレント実行
 *  prc_param_init            PROCEDURE : 起動パラメータ設定
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/20    1.0   Masayuki Ikeda   新規作成
 *
 *****************************************************************************************/
--
--##### 固定グローバル定数宣言部 START #############################################################
--
  -- ======================================================
  -- コンカレントステータス
  -- ======================================================
  gv_status_normal    CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn      CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error     CONSTANT VARCHAR2(1) := '2' ;
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
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn820011c' ;   -- パッケージ名
  gc_appl_name            CONSTANT VARCHAR2(20) := 'XXCMN' ;          -- メッセージ用
  gc_temp_appl_name       CONSTANT VARCHAR2(20) := 'XXCMN' ;          -- アプリ短縮名（Template）
  gc_conc_appl_name       CONSTANT VARCHAR2(20) := 'XXCMN' ;          -- アプリ短縮名（Concurrent）
--
  -- ===============================
  -- ユーザー変数グローバル定数
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      report_type       VARCHAR2(1)     -- 表形式
     ,output_type       VARCHAR2(1)     -- 出力形式
     ,fiscal_ym         VARCHAR2(6)     -- 対象年月
     ,prod_div          VARCHAR2(1)     -- 商品区分
     ,item_div          VARCHAR2(1)     -- 品目区分
     ,dept_code         VARCHAR2(4)     -- 部署コード
     ,crowd_code_01     VARCHAR2(4)     -- 群コード１
     ,crowd_code_02     VARCHAR2(4)     -- 群コード２
     ,crowd_code_03     VARCHAR2(4)     -- 群コード３
     ,item_code_01      VARCHAR2(7)     -- 品目コード１
     ,item_code_02      VARCHAR2(7)     -- 品目コード２
     ,item_code_03      VARCHAR2(7)     -- 品目コード３
     ,item_code_04      VARCHAR2(7)     -- 品目コード４
     ,item_code_05      VARCHAR2(7)     -- 品目コード５
     ,vendor_id_01      VARCHAR2(15)    -- 取引先ＩＤ１
     ,vendor_id_02      VARCHAR2(15)    -- 取引先ＩＤ２
     ,vendor_id_03      VARCHAR2(15)    -- 取引先ＩＤ３
     ,vendor_id_04      VARCHAR2(15)    -- 取引先ＩＤ４
     ,vendor_id_05      VARCHAR2(15)    -- 取引先ＩＤ５
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
   * Description      : パラメータチェック(B-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
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
    lc_token_name_01_01   CONSTANT VARCHAR2(100) := 'PARAMETER' ;  
    lc_token_name_01_02   CONSTANT VARCHAR2(100) := 'VALUE' ;  
    -- トークン値
    lc_token_value_01_01  CONSTANT VARCHAR2(100) := '対象年月' ;
--
    -- *** ローカル変数 ***
    -- -------------------------------
    -- エラーメッセージ出力用
    -- -------------------------------
    lv_err_code               VARCHAR2(100) ;
    lv_token_name_01          VARCHAR2(100) ;
    lv_token_name_02          VARCHAR2(100) ;
    lv_token_value_01         VARCHAR2(100) ;
    lv_token_value_02         VARCHAR2(100) ;
--
    -- -------------------------------
    -- エラーハンドリング用
    -- -------------------------------
    ln_ret_num                NUMBER ;        -- 共通関数戻り値：数値型
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt      EXCEPTION ;     -- パラメータチェック例外
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 対象年月
    -- ====================================================
    -- 日付変換チェック
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.fiscal_ym ) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_err_code       := lc_err_code_01 ;
      lv_token_name_01  := lc_token_name_01_01 ;
      lv_token_name_02  := lc_token_name_01_02 ;
      lv_token_value_01 := lc_token_value_01_01 ;
      lv_token_value_02 := ir_param.fiscal_ym ;
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
   * Description      : 起動パラメータ設定
   ***********************************************************************************/
  PROCEDURE prc_param_init
    (
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
    gv_argument2       := ir_param.fiscal_ym ;        -- 対象年月
    gv_argument3       := ir_param.prod_div ;         -- 商品区分
    gv_argument4       := ir_param.item_div ;         -- 品目区分
    gv_argument5       := ir_param.dept_code ;        -- 部署コード
    gv_argument6       := ir_param.crowd_code_01 ;    -- 群コード１
    gv_argument7       := ir_param.crowd_code_02 ;    -- 群コード２
    gv_argument8       := ir_param.crowd_code_03 ;    -- 群コード３
    gv_argument9       := ir_param.item_code_01 ;     -- 品目コード１
    gv_argument10      := ir_param.item_code_02 ;     -- 品目コード２
    gv_argument11      := ir_param.item_code_03 ;     -- 品目コード３
    gv_argument12      := ir_param.item_code_04 ;     -- 品目コード４
    gv_argument13      := ir_param.item_code_05 ;     -- 品目コード５
    gv_argument14      := ir_param.vendor_id_01 ;     -- 取引先ＩＤ１
    gv_argument15      := ir_param.vendor_id_02 ;     -- 取引先ＩＤ２
    gv_argument16      := ir_param.vendor_id_03 ;     -- 取引先ＩＤ３
    gv_argument17      := ir_param.vendor_id_04 ;     -- 取引先ＩＤ４
    gv_argument18      := ir_param.vendor_id_05 ;     -- 取引先ＩＤ５
--
    -- =====================================================
    -- 起動コンカレントの選定
    -- =====================================================
    -- -----------------------------------------------------
    -- 表形式が「品目別取引先別」の場合
    -- -----------------------------------------------------
    IF ( ir_param.report_type = xxcmn820011c.rep_type_item ) THEN
      -- 不要なパラメータをクリア
      gv_argument14 := NULL ;   -- 取引先ＩＤ１
      gv_argument15 := NULL ;   -- 取引先ＩＤ２
      gv_argument16 := NULL ;   -- 取引先ＩＤ３
      gv_argument17 := NULL ;   -- 取引先ＩＤ４
      gv_argument18 := NULL ;   -- 取引先ＩＤ５
--
      -- -----------------------------------------------------
      -- 出力形式が「明細表」の場合
      -- -----------------------------------------------------
      IF ( ir_param.output_type = xxcmn820011c.out_type_dtl ) THEN
        -- -----------------------------------------------------
        -- 部署コードが「全指定」の場合
        -- -----------------------------------------------------
        IF ( ir_param.dept_code = xxcmn820011c.dept_code_all ) THEN
          -- 品目別明細表を指定
          lv_program_id := xxcmn820011c.program_id_03 ;
--
        -- -----------------------------------------------------
        -- 部署コードが「全指定」以外の場合
        -- -----------------------------------------------------
        ELSE
          -- 部署別品目別明細表を指定
          lv_program_id := xxcmn820011c.program_id_01 ;
--
        END IF ;
      -- -----------------------------------------------------
      -- 出力形式が「合計表」の場合
      -- -----------------------------------------------------
      ELSIF ( ir_param.output_type = xxcmn820011c.out_type_sum ) THEN
        -- -----------------------------------------------------
        -- 部署コードが「全指定」の場合
        -- -----------------------------------------------------
        IF ( ir_param.dept_code = xxcmn820011c.dept_code_all ) THEN
          -- 品目別合計表を指定
          lv_program_id := xxcmn820011c.program_id_04 ;
--
        -- -----------------------------------------------------
        -- 部署コードが「全指定」以外の場合
        -- -----------------------------------------------------
        ELSE
          -- 部署別品目別合計表を指定
          lv_program_id := xxcmn820011c.program_id_02 ;
--
        END IF ;
      END IF ;
--
    -- -----------------------------------------------------
    -- 表形式が「取引先別品目別」の場合
    -- -----------------------------------------------------
    ELSIF ( ir_param.report_type = xxcmn820011c.rep_type_vend ) THEN
      -- 不要なパラメータをクリア
      gv_argument9  := NULL ;   -- 品目コード１
      gv_argument10 := NULL ;   -- 品目コード２
      gv_argument11 := NULL ;   -- 品目コード３
      gv_argument12 := NULL ;   -- 品目コード４
      gv_argument13 := NULL ;   -- 品目コード５
--
      -- -----------------------------------------------------
      -- 出力形式が「明細表」の場合
      -- -----------------------------------------------------
      IF ( ir_param.output_type = xxcmn820011c.out_type_dtl ) THEN
        -- -----------------------------------------------------
        -- 部署コードが「全指定」の場合
        -- -----------------------------------------------------
        IF ( ir_param.dept_code = xxcmn820011c.dept_code_all ) THEN
          -- 取引先別明細表を指定
          lv_program_id := xxcmn820011c.program_id_07 ;
--
        -- -----------------------------------------------------
        -- 部署コードが「全指定」以外の場合
        -- -----------------------------------------------------
        ELSE
          -- 部署別取引先別明細表を指定
          lv_program_id := xxcmn820011c.program_id_05 ;
--
        END IF ;
      -- -----------------------------------------------------
      -- 出力形式が「合計表」の場合
      -- -----------------------------------------------------
      ELSIF ( ir_param.output_type = xxcmn820011c.out_type_sum ) THEN
        -- -----------------------------------------------------
        -- 部署コードが「全指定」の場合
        -- -----------------------------------------------------
        IF ( ir_param.dept_code = xxcmn820011c.dept_code_all ) THEN
          -- 取引先別合計表を指定
          lv_program_id := xxcmn820011c.program_id_08 ;
--
        -- -----------------------------------------------------
        -- 部署コードが「全指定」以外の場合
        -- -----------------------------------------------------
        ELSE
          -- 部署別取引先別合計表を指定
          lv_program_id := xxcmn820011c.program_id_06 ;
--
        END IF ;
      END IF ;
    END IF ;
--
    -- ======================================================
    -- テンプレート設定用変数の編集２
    -- ======================================================
    gv_temp_program_id := lv_program_id || 'C' ;
--
    -- ======================================================
    -- コンカレント起動用変数の編集２
    -- ======================================================
    gv_conc_program_id := lv_program_id || 'C' ;
    gv_argument1       := lv_program_id ;             -- 出力形式
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
   * Description      : 帳票コンカレント実行
   ***********************************************************************************/
  PROCEDURE prc_submit_request
    (
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
    lb_ret := FND_REQUEST.ADD_LAYOUT
                (
                  template_appl_name  => gv_temp_appl_name        -- アプリケーション短縮名
                 ,template_code       => gv_temp_program_id       -- テンプレート名
                 ,template_language   => gc_temp_language         -- 言語
                 ,template_territory  => gc_temp_territory        -- 地域
                 ,output_format       => gc_output_format         -- 出力フォーマット
                ) ;
    -- エラーの場合
    IF ( lb_ret = FALSE ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application   => gc_appl_name
                     ,iv_name          => lc_err_code_template ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- =====================================================
    -- サブコンカレントの呼び出し
    -- =====================================================
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                (
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
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application   => gc_appl_name
                     ,iv_name          => lc_err_code_submit ) ;
      RAISE global_api_expt ;
    END IF ;
--
    COMMIT ;
--
    -- =====================================================
    -- 待機処理
    -- =====================================================
    lb_ret := FND_CONCURRENT.WAIT_FOR_REQUEST
                (
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
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application   => gc_appl_name
                     ,iv_name          => lc_err_code_wait ) ;
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
  PROCEDURE submain
    (
      iv_report_type        IN     VARCHAR2         -- 01 : 表形式
     ,iv_output_type        IN     VARCHAR2         -- 02 : 出力形式
     ,iv_fiscal_ym          IN     VARCHAR2         -- 03 : 〆切年月
     ,iv_prod_div           IN     VARCHAR2         -- 04 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 05 : 品目区分
     ,iv_dept_code          IN     VARCHAR2         -- 06 : 所属部署
     ,iv_crowd_code_01      IN     VARCHAR2         -- 07 : 群コード１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 08 : 群コード２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 09 : 群コード３
     ,iv_item_code_01       IN     VARCHAR2         -- 10 : 品目コード１
     ,iv_item_code_02       IN     VARCHAR2         -- 11 : 品目コード２
     ,iv_item_code_03       IN     VARCHAR2         -- 12 : 品目コード３
     ,iv_item_code_04       IN     VARCHAR2         -- 13 : 品目コード４
     ,iv_item_code_05       IN     VARCHAR2         -- 14 : 品目コード５
     ,iv_vendor_id_01       IN     VARCHAR2         -- 15 : 取引先ＩＤ１
     ,iv_vendor_id_02       IN     VARCHAR2         -- 16 : 取引先ＩＤ２
     ,iv_vendor_id_03       IN     VARCHAR2         -- 17 : 取引先ＩＤ３
     ,iv_vendor_id_04       IN     VARCHAR2         -- 18 : 取引先ＩＤ４
     ,iv_vendor_id_05       IN     VARCHAR2         -- 19 : 取引先ＩＤ５
     ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    lc_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
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
    -- 初期処理
    -- =====================================================
    -- パラメータ格納
    lr_param_rec.report_type    := iv_report_type ;     -- 表形式
    lr_param_rec.output_type    := iv_output_type ;     -- 出力形式
    lr_param_rec.fiscal_ym      := iv_fiscal_ym ;       -- 対象年月
    lr_param_rec.prod_div       := iv_prod_div ;        -- 商品区分
    lr_param_rec.item_div       := iv_item_div ;        -- 品目区分
    lr_param_rec.dept_code      := iv_dept_code ;       -- 部署コード
    lr_param_rec.crowd_code_01  := iv_crowd_code_01 ;   -- 群コード１
    lr_param_rec.crowd_code_02  := iv_crowd_code_02 ;   -- 群コード２
    lr_param_rec.crowd_code_03  := iv_crowd_code_03 ;   -- 群コード３
    lr_param_rec.item_code_01   := iv_item_code_01 ;    -- 品目コード１
    lr_param_rec.item_code_02   := iv_item_code_02 ;    -- 品目コード２
    lr_param_rec.item_code_03   := iv_item_code_03 ;    -- 品目コード３
    lr_param_rec.item_code_04   := iv_item_code_04 ;    -- 品目コード４
    lr_param_rec.item_code_05   := iv_item_code_05 ;    -- 品目コード５
    lr_param_rec.vendor_id_01   := iv_vendor_id_01 ;    -- 取引先ＩＤ１
    lr_param_rec.vendor_id_02   := iv_vendor_id_02 ;    -- 取引先ＩＤ２
    lr_param_rec.vendor_id_03   := iv_vendor_id_03 ;    -- 取引先ＩＤ３
    lr_param_rec.vendor_id_04   := iv_vendor_id_04 ;    -- 取引先ＩＤ４
    lr_param_rec.vendor_id_05   := iv_vendor_id_05 ;    -- 取引先ＩＤ５
--
    -- =====================================================
    -- パラメータチェック
    -- =====================================================
    prc_check_param_info
      (
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
    prc_param_init
      (
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
    prc_submit_request
      (
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
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_report_type        IN     VARCHAR2         -- 01 : 表形式
     ,iv_output_type        IN     VARCHAR2         -- 02 : 出力形式
     ,iv_fiscal_ym          IN     VARCHAR2         -- 03 : 〆切年月
     ,iv_prod_div           IN     VARCHAR2         -- 04 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 05 : 品目区分
     ,iv_dept_code          IN     VARCHAR2         -- 06 : 所属部署
     ,iv_crowd_code_01      IN     VARCHAR2         -- 07 : 群コード１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 08 : 群コード２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 09 : 群コード３
     ,iv_item_code_01       IN     VARCHAR2         -- 10 : 品目コード１
     ,iv_item_code_02       IN     VARCHAR2         -- 11 : 品目コード２
     ,iv_item_code_03       IN     VARCHAR2         -- 12 : 品目コード３
     ,iv_item_code_04       IN     VARCHAR2         -- 13 : 品目コード４
     ,iv_item_code_05       IN     VARCHAR2         -- 14 : 品目コード５
     ,iv_vendor_id_01       IN     VARCHAR2         -- 15 : 取引先ＩＤ１
     ,iv_vendor_id_02       IN     VARCHAR2         -- 16 : 取引先ＩＤ２
     ,iv_vendor_id_03       IN     VARCHAR2         -- 17 : 取引先ＩＤ３
     ,iv_vendor_id_04       IN     VARCHAR2         -- 18 : 取引先ＩＤ４
     ,iv_vendor_id_05       IN     VARCHAR2         -- 19 : 取引先ＩＤ５
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    lc_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
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
    submain
      (
        iv_report_type    => iv_report_type     -- 01 : 表形式
       ,iv_output_type    => iv_output_type     -- 02 : 出力形式
       ,iv_fiscal_ym      => iv_fiscal_ym       -- 03 : 〆切年月
       ,iv_prod_div       => iv_prod_div        -- 04 : 商品区分
       ,iv_item_div       => iv_item_div        -- 05 : 品目区分
       ,iv_dept_code      => iv_dept_code       -- 06 : 所属部署
       ,iv_crowd_code_01  => iv_crowd_code_01   -- 07 : 群コード１
       ,iv_crowd_code_02  => iv_crowd_code_02   -- 08 : 群コード２
       ,iv_crowd_code_03  => iv_crowd_code_03   -- 09 : 群コード３
       ,iv_item_code_01   => iv_item_code_01    -- 10 : 品目コード１
       ,iv_item_code_02   => iv_item_code_02    -- 11 : 品目コード２
       ,iv_item_code_03   => iv_item_code_03    -- 12 : 品目コード３
       ,iv_item_code_04   => iv_item_code_04    -- 13 : 品目コード４
       ,iv_item_code_05   => iv_item_code_05    -- 14 : 品目コード５
       ,iv_vendor_id_01   => iv_vendor_id_01    -- 15 : 取引先ＩＤ１
       ,iv_vendor_id_02   => iv_vendor_id_02    -- 16 : 取引先ＩＤ２
       ,iv_vendor_id_03   => iv_vendor_id_03    -- 17 : 取引先ＩＤ３
       ,iv_vendor_id_04   => iv_vendor_id_04    -- 18 : 取引先ＩＤ４
       ,iv_vendor_id_05   => iv_vendor_id_05    -- 19 : 取引先ＩＤ５
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
      errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||lc_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxcmn820011c ;
/
