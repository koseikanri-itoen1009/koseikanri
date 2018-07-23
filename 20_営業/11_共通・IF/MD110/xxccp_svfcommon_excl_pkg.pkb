CREATE OR REPLACE PACKAGE BODY apps.xxccp_svfcommon_excl_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxccp_svfcommon_excl_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  submit_svf_request        P           SVF帳票共通関数(専用マネージャ実行のSVFコンカレントの起動)
 *  no_data_msg               F     CHAR  SVF帳票共通関数(0件出力メッセージ)
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2018-07-11    1.0  Kazuhiro.Nara    新規作成 [障害E_本稼動_15005]対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal;          -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;            -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;           -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER         := fnd_global.user_id;                          -- CREATED_BY
  cd_creation_date          CONSTANT DATE           := SYSDATE;                                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER         := fnd_global.user_id;                          -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE           := SYSDATE;                                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER         := fnd_global.login_id;                         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER         := fnd_global.conc_request_id;                  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER         := fnd_global.prog_appl_id;                     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER         := fnd_global.conc_program_id;                  -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE           := SYSDATE;                                     -- PROGRAM_UPDATE_DATE
  -- 記号
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
  cv_msg_sq                 CONSTANT VARCHAR2(3)    := '''';
  --
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
--
  -- ===============================
  -- ユーザー定義パッケージ内グローバル定数
  -- ===============================
  -- その他
  cb_NULL                   CONSTANT BOOLEAN        := NULL;
  cb_FALSE                  CONSTANT BOOLEAN        := FALSE;
  cb_TURE                   CONSTANT BOOLEAN        := TRUE;
  cv_log_mode               CONSTANT VARCHAR2(30)   := 'LOG';                                       -- 出力モード：ログ出力
  cv_output_mode            CONSTANT VARCHAR2(30)   := 'OUTPUT';                                    -- 出力モード：画面出力
  cv_part_bs                CONSTANT VARCHAR2(3)    := '\\';                                        -- ウィンドウズのディレクトリ階層は\\で表記
  cv_part_sl                CONSTANT VARCHAR2(3)    := '/';                                         -- Linuxのディレクトリ階層は/で表記
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--  cv_pkg_name               CONSTANT VARCHAR2(30)   := 'xxccp_svfcommon_pkg';                       -- PKG名
  cv_pkg_name               CONSTANT VARCHAR2(30)   := 'xxccp_svfcommon_excl_pkg';                       -- PKG名
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
  cv_applcation_xxccp       CONSTANT VARCHAR2(30)   := 'XXCCP';                                     -- アプリケーション短縮名
  cv_pdf_dir                CONSTANT VARCHAR2(30)   := 'PDF';                                       -- PDFファイル格納ディレクトリ
  cv_form_dir               CONSTANT VARCHAR2(30)   := 'Form';                                      -- フォーム様式ファイル格納ディレクトリ
  cv_query_dir              CONSTANT VARCHAR2(30)   := 'Query';                                     -- クエリ様式ファイル格納ディレクトリ
--
--  要求フェーズと要求ステータス定数
  cv_phase_comp             CONSTANT VARCHAR2(30)   := 'COMPLETE';                                  -- 要求フェーズ：完了
  cv_status_nomal           CONSTANT VARCHAR2(30)   := 'NORMAL';                                    -- 要求ステータス：正常
--
  -- ===============================
  -- メッセージ関連定数
  -- ===============================
  -- エラーメッセージ用メッセージID
  cv_err_prm_unjust       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10015';                            -- パラメータ値不正
  cv_err_prm_required     CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10004';                            -- パラメータ必須エラー
  cv_err_prm_length       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10006';                            -- パラメータ長エラー
  cv_err_date_accession   CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10112';                            -- データ取得エラー
  cv_err_exec_conc        CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10026';                            -- コンカレントステータス異常終了
  cv_err_prog_start       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-91001';                            -- 対象Prog起動エラー
  cv_err_process          CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-91005';                            -- 対象処理エラー
  cv_err_get_profile      CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10032';                            -- プロファイル取得エラー
  cv_err_end              CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10003';                            -- 異常終了メッセージ
  --
  --情報ログ用メッセージID
  cv_info_appl_name       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00002';                            -- 起動対象アプリケーション短縮名表示
  cv_info_conc_name       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00003';                            -- 起動対象コンカレント短縮名表示
  cv_info_prm             CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00005';                            -- パラメータ表示
  cv_info_request_end     CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00007';                            -- 要求の正常終了情報表示
  cv_info_request_start   CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-91002';                            -- 要求の正常な開始を表示
  --
  --メッセージトークン
  cv_token_item           CONSTANT VARCHAR2(30)   := 'ITEM';
  cv_token_value          CONSTANT VARCHAR2(30)   := 'VALUE';
  cv_token_number         CONSTANT VARCHAR2(30)   := 'NUMBER';
  cv_token_prmval         CONSTANT VARCHAR2(30)   := 'PARAM_VALUE';
  cv_token_appl_name      CONSTANT VARCHAR2(30)   := 'AP_SHORT_NAME';
  cv_token_conc_name      CONSTANT VARCHAR2(30)   := 'CONC_SHORT_NAME';
  cv_token_req_id         CONSTANT VARCHAR2(30)   := 'REQ_ID';
  cv_token_phase          CONSTANT VARCHAR2(30)   := 'PHASE';
  cv_token_staus          CONSTANT VARCHAR2(30)   := 'STATUS';
  cv_token_proc           CONSTANT VARCHAR2(30)   := 'PROCESS';
  cv_token_prog           CONSTANT VARCHAR2(30)   := 'PROGRAM';
  cv_token_id             CONSTANT VARCHAR2(30)   := 'ID';
  cv_token_prof_name      CONSTANT VARCHAR2(30)   := 'PROFILE_NAME';
--
--  メッセージトークン値用定数(INパラメータ関連)
  cv_token_v_prm01        CONSTANT VARCHAR2(50)   := 'コンカレント名';
  cv_token_v_prm02        CONSTANT VARCHAR2(50)   := '出力ファイル名';
  cv_token_v_prm03        CONSTANT VARCHAR2(50)   := '帳票ID';
  cv_token_v_prm04        CONSTANT VARCHAR2(50)   := '出力区分';
  cv_token_v_prm05        CONSTANT VARCHAR2(50)   := 'フォーム様式ファイル名';
  cv_token_v_prm06        CONSTANT VARCHAR2(50)   := 'クエリー様式ファイル名';
  cv_token_v_prm07        CONSTANT VARCHAR2(50)   := 'ORG_ID';
  cv_token_v_prm08        CONSTANT VARCHAR2(50)   := 'ログイン・ユーザ名';
  cv_token_v_prm09        CONSTANT VARCHAR2(50)   := 'ログイン・ユーザの職責';
  cv_token_v_prm10        CONSTANT VARCHAR2(50)   := '文書名';
  cv_token_v_prm11        CONSTANT VARCHAR2(50)   := 'プリンタ名';
  cv_token_v_prm12        CONSTANT VARCHAR2(50)   := '要求ID';
  cv_token_v_prm13        CONSTANT VARCHAR2(50)   := 'データなしメッセージ';
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD START
  cv_token_v_prm29        CONSTANT VARCHAR2(50)   := 'SVF専用マネージャコード';
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD END
  cv_token_v_prm14        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ01';
  cv_token_v_prm15        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ02';
  cv_token_v_prm16        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ03';
  cv_token_v_prm17        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ04';
  cv_token_v_prm18        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ05';
  cv_token_v_prm19        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ06';
  cv_token_v_prm20        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ07';
  cv_token_v_prm21        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ08';
  cv_token_v_prm22        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ09';
  cv_token_v_prm23        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ10';
  cv_token_v_prm24        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ11';
  cv_token_v_prm25        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ12';
  cv_token_v_prm26        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ13';
  cv_token_v_prm27        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ14';
  cv_token_v_prm28        CONSTANT VARCHAR2(50)   := 'svf可変パラメータ15';
--
--  メッセージトークン値用定数(DB取得項目関連)
  cv_token_v_db_val_of    CONSTANT VARCHAR2(50)   := 'OUTFILE_PATH';
--
--  メッセージトークン値用定数(その他)
  cv_token_v_svf_conc     CONSTANT VARCHAR2(50)   := 'SVFコンカレント';
  cv_token_v_wait_ftp     CONSTANT VARCHAR2(50)   := 'SVFコンカレント終了待ち処理';
  cv_token_v_ftp_conc     CONSTANT VARCHAR2(50)   := 'ファイル転送コンカレント';
  cv_token_v_wait_svf     CONSTANT VARCHAR2(50)   := 'ファイル転送コンカレント終了待ち処理';
--
--  その他のメッセージ用
  cv_msg_part_mb          CONSTANT VARCHAR2(4)    := '：  ';
  cv_plofile_msg          CONSTANT VARCHAR2(30)   := 'プロファイル ';
  cv_outpath_msg          CONSTANT VARCHAR2(30)   := '出力PDFパス  ';
  cv_add_cond_msg         CONSTANT VARCHAR2(30)   := '条件句設定   ';                               -- TEST時結果表示用メッセージ
--
--  その他
-- 
  cn_chk_svfprm_len       CONSTANT NUMBER := 230 ;                                                  -- SVF可変パラメータチェック時の最大文字長
  -- ===============================
  -- ユーザー定義パッケージ内グローバル型
  -- ===============================
--
  -- コンカレント起動用パラメータ変数
  TYPE  gt_conc_argument IS RECORD(
      appl                  VARCHAR2(4000)  DEFAULT   NULL,                                         -- アプリケーションの短縮名
      prog                  VARCHAR2(4000)  DEFAULT   NULL,                                         -- コンカレント・プログラムの短縮名
      descr                 VARCHAR2(4000)  DEFAULT   NULL,                                         --「コンカレント要求」フォームに表示される要求の説明
      startt                VARCHAR2(4000)  DEFAULT   NULL,                                         -- 要求の実行を開始する時刻
      sub                   BOOLEAN         DEFAULT   FALSE,                                        -- サブ要求として扱われる場合にTRUE
      arg001                VARCHAR2(4000)  DEFAULT   CHR(0),                                       -- 000 - 100 コンカレント要求の引数
      arg002                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg003                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg004                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg005                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg006                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg007                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg008                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg009                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg010                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg011                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg012                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg013                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg014                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg015                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg016                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg017                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg018                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg019                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg020                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg021                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg022                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg023                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg024                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg025                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg026                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg027                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg028                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg029                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg030                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg031                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg032                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg033                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg034                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg035                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg036                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg037                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg038                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg039                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg040                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg041                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg042                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg043                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg044                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg045                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg046                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg047                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg048                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg049                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg050                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg051                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg052                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg053                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg054                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg055                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg056                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg057                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg058                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg059                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg060                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg061                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg062                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg063                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg064                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg065                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg066                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg067                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg068                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg069                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg070                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg071                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg072                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg073                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg074                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg075                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg076                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg077                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg078                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg079                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg080                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg081                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg082                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg083                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg084                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg085                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg086                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg087                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg088                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg089                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg090                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg091                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg092                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg093                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg094                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg095                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg096                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg097                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg098                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg099                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg100                VARCHAR2(4000)  DEFAULT   CHR(0)
    );
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Private Function
   * Function  Name   :output_log
   * Description      :メッセージの取得とLOG出力を同時に行うプロシージャ
   * PARAMETERS       :xxccp_common_pkg.get_msgと同じ
   ***********************************************************************************/
  PROCEDURE output_log(   iv_appl             IN VARCHAR2 DEFAULT NULL,
                          iv_name             IN VARCHAR2 DEFAULT NULL,
                          iv_token_01         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val01      IN VARCHAR2 DEFAULT NULL,
                          iv_token_02         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val02      IN VARCHAR2 DEFAULT NULL,
                          iv_token_03         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val03      IN VARCHAR2 DEFAULT NULL,
                          iv_token_04         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val04      IN VARCHAR2 DEFAULT NULL,
                          iv_token_05         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val05      IN VARCHAR2 DEFAULT NULL,
                          iv_token_06         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val06      IN VARCHAR2 DEFAULT NULL,
                          iv_token_07         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val07      IN VARCHAR2 DEFAULT NULL,
                          iv_token_08         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val08      IN VARCHAR2 DEFAULT NULL,
                          iv_token_09         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val09      IN VARCHAR2 DEFAULT NULL,
                          iv_token_10         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val10      IN VARCHAR2 DEFAULT NULL
                          )
  IS
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'output_log';
    lv_output_msg           VARCHAR2(4000) := NULL;                                                 -- 取得メッセージ格納変数
  BEGIN
    -- メッセージの取得
    lv_output_msg := xxccp_common_pkg.get_msg(
      iv_application    =>  iv_appl           ,                                                     --アプリケーション短縮名
      iv_name           =>  iv_name           ,                                                     --メッセージコード
      iv_token_name1    =>  iv_token_01       ,                                                     --トークンコード1
      iv_token_value1   =>  iv_token_val01    ,                                                     --トークン値1
      iv_token_name2    =>  iv_token_02       ,                                                     --トークンコード2
      iv_token_value2   =>  iv_token_val02    ,                                                     --トークン値2
      iv_token_name3    =>  iv_token_03       ,                                                     --トークンコード3
      iv_token_value3   =>  iv_token_val03    ,                                                     --トークン値4
      iv_token_name4    =>  iv_token_04       ,                                                     --トークンコード4
      iv_token_value4   =>  iv_token_val04    ,                                                     --トークン値4
      iv_token_name5    =>  iv_token_05       ,                                                     --トークンコード5
      iv_token_value5   =>  iv_token_val05    ,                                                     --トークン値5
      iv_token_name6    =>  iv_token_06       ,                                                     --トークンコード6
      iv_token_value6   =>  iv_token_val06    ,                                                     --トークン値6
      iv_token_name7    =>  iv_token_07       ,                                                     --トークンコード7
      iv_token_value7   =>  iv_token_val07    ,                                                     --トークン値7
      iv_token_name8    =>  iv_token_08       ,                                                     --トークンコード8
      iv_token_value8   =>  iv_token_val08    ,                                                     --トークン値8
      iv_token_name9    =>  iv_token_09       ,                                                     --トークンコード9
      iv_token_value9   =>  iv_token_val09    ,                                                     --トークン値9
      iv_token_name10   =>  iv_token_10       ,                                                     --トークンコード10
      iv_token_value10  =>  iv_token_val10                                                          --トークン値10
    );
    -- エラーメッセージのログへの出力
    FND_FILE.PUT_LINE(
       which            => FND_FILE.LOG,                                                            -- LOG出力
       buff             => lv_output_msg                                                            -- 出力内容
    );
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
    --
  END output_log;
--
--
  /**********************************************************************************
   * Private Function
   * Function  Name   : start_request
   * Description      : FND_REQUEST.submit_requestの起動
   * PARAMETER        : コンカレントの起動引数
   * RETURN           : 要求ID
   ***********************************************************************************/
  FUNCTION start_request (it_conc_argument     IN OUT gt_conc_argument
                          )
    RETURN NUMBER
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cl_error                CONSTANT NUMBER := 0 ;                                                  -- エラー時の出力内容
  --
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_reqid                NUMBER := NULL ;                                                        -- コンカレント起動時の返り値(要求ID)/エラー時は0が帰ってくる
    --
  BEGIN
  --
--##################  標準機能のコンカレント起動パッケージ呼び出し START   ###################
    ln_reqid := FND_REQUEST.SUBMIT_REQUEST(
        application         =>  it_conc_argument.appl,
        program             =>  it_conc_argument.prog,
        description         =>  it_conc_argument.descr,
        start_time          =>  it_conc_argument.startt,
        sub_request         =>  it_conc_argument.sub,
        argument1           =>  it_conc_argument.arg001,
        argument2           =>  it_conc_argument.arg002,
        argument3           =>  it_conc_argument.arg003,
        argument4           =>  it_conc_argument.arg004,
        argument5           =>  it_conc_argument.arg005,
        argument6           =>  it_conc_argument.arg006,
        argument7           =>  it_conc_argument.arg007,
        argument8           =>  it_conc_argument.arg008,
        argument9           =>  it_conc_argument.arg009,
        argument10          =>  it_conc_argument.arg010,
        argument11          =>  it_conc_argument.arg011,
        argument12          =>  it_conc_argument.arg012,
        argument13          =>  it_conc_argument.arg013,
        argument14          =>  it_conc_argument.arg014,
        argument15          =>  it_conc_argument.arg015,
        argument16          =>  it_conc_argument.arg016,
        argument17          =>  it_conc_argument.arg017,
        argument18          =>  it_conc_argument.arg018,
        argument19          =>  it_conc_argument.arg019,
        argument20          =>  it_conc_argument.arg020,
        argument21          =>  it_conc_argument.arg021,
        argument22          =>  it_conc_argument.arg022,
        argument23          =>  it_conc_argument.arg023,
        argument24          =>  it_conc_argument.arg024,
        argument25          =>  it_conc_argument.arg025,
        argument26          =>  it_conc_argument.arg026,
        argument27          =>  it_conc_argument.arg027,
        argument28          =>  it_conc_argument.arg028,
        argument29          =>  it_conc_argument.arg029,
        argument30          =>  it_conc_argument.arg030,
        argument31          =>  it_conc_argument.arg031,
        argument32          =>  it_conc_argument.arg032,
        argument33          =>  it_conc_argument.arg033,
        argument34          =>  it_conc_argument.arg034,
        argument35          =>  it_conc_argument.arg035,
        argument36          =>  it_conc_argument.arg036,
        argument37          =>  it_conc_argument.arg037,
        argument38          =>  it_conc_argument.arg038,
        argument39          =>  it_conc_argument.arg039,
        argument40          =>  it_conc_argument.arg040,
        argument41          =>  it_conc_argument.arg041,
        argument42          =>  it_conc_argument.arg042,
        argument43          =>  it_conc_argument.arg043,
        argument44          =>  it_conc_argument.arg044,
        argument45          =>  it_conc_argument.arg045,
        argument46          =>  it_conc_argument.arg046,
        argument47          =>  it_conc_argument.arg047,
        argument48          =>  it_conc_argument.arg048,
        argument49          =>  it_conc_argument.arg049,
        argument50          =>  it_conc_argument.arg050,
        argument51          =>  it_conc_argument.arg051,
        argument52          =>  it_conc_argument.arg052,
        argument53          =>  it_conc_argument.arg053,
        argument54          =>  it_conc_argument.arg054,
        argument55          =>  it_conc_argument.arg055,
        argument56          =>  it_conc_argument.arg056,
        argument57          =>  it_conc_argument.arg057,
        argument58          =>  it_conc_argument.arg058,
        argument59          =>  it_conc_argument.arg059,
        argument60          =>  it_conc_argument.arg060,
        argument61          =>  it_conc_argument.arg061,
        argument62          =>  it_conc_argument.arg062,
        argument63          =>  it_conc_argument.arg063,
        argument64          =>  it_conc_argument.arg064,
        argument65          =>  it_conc_argument.arg065,
        argument66          =>  it_conc_argument.arg066,
        argument67          =>  it_conc_argument.arg067,
        argument68          =>  it_conc_argument.arg068,
        argument69          =>  it_conc_argument.arg069,
        argument70          =>  it_conc_argument.arg070,
        argument71          =>  it_conc_argument.arg071,
        argument72          =>  it_conc_argument.arg072,
        argument73          =>  it_conc_argument.arg073,
        argument74          =>  it_conc_argument.arg074,
        argument75          =>  it_conc_argument.arg075,
        argument76          =>  it_conc_argument.arg076,
        argument77          =>  it_conc_argument.arg077,
        argument78          =>  it_conc_argument.arg078,
        argument79          =>  it_conc_argument.arg079,
        argument80          =>  it_conc_argument.arg080,
        argument81          =>  it_conc_argument.arg081,
        argument82          =>  it_conc_argument.arg082,
        argument83          =>  it_conc_argument.arg083,
        argument84          =>  it_conc_argument.arg084,
        argument85          =>  it_conc_argument.arg085,
        argument86          =>  it_conc_argument.arg086,
        argument87          =>  it_conc_argument.arg087,
        argument88          =>  it_conc_argument.arg088,
        argument89          =>  it_conc_argument.arg089,
        argument90          =>  it_conc_argument.arg090,
        argument91          =>  it_conc_argument.arg091,
        argument92          =>  it_conc_argument.arg092,
        argument93          =>  it_conc_argument.arg093,
        argument94          =>  it_conc_argument.arg094,
        argument95          =>  it_conc_argument.arg095,
        argument96          =>  it_conc_argument.arg096,
        argument97          =>  it_conc_argument.arg097,
        argument98          =>  it_conc_argument.arg098,
        argument99          =>  it_conc_argument.arg099,
        argument100         =>  it_conc_argument.arg100
      );
--##################  標準機能のコンカレント起動パッケージ呼び出し END     ###################
  --
      RETURN ln_reqid ;
  --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN cv_status_error ;
    --
  END start_request ;
--
  --
  /**********************************************************************************
   * Function  Name   : submit_svf_request
   * Description      : SVF帳票共通関数(SVFコンカレントの起動)
   ***********************************************************************************/
  PROCEDURE submit_svf_request(ov_retcode      OUT VARCHAR2                                         --リターンコード
                              ,ov_errbuf       OUT VARCHAR2                                         --エラーメッセージ
                              ,ov_errmsg       OUT VARCHAR2                                         --ユーザー・エラーメッセージ
                              ,iv_conc_name    IN  VARCHAR2                                         --コンカレント名
                              ,iv_file_name    IN  VARCHAR2                                         --出力ファイル名
                              ,iv_file_id      IN  VARCHAR2                                         --帳票ID
                              ,iv_output_mode  IN  VARCHAR2  DEFAULT 1                              --出力区分
                              ,iv_frm_file     IN  VARCHAR2                                         --フォーム様式ファイル名
                              ,iv_vrq_file     IN  VARCHAR2                                         --クエリー様式ファイル名
                              ,iv_org_id       IN  VARCHAR2                                          --ORG_ID
                              ,iv_user_name    IN  VARCHAR2                                         --ログイン・ユーザ名
                              ,iv_resp_name    IN  VARCHAR2                                         --ログイン・ユーザの職責名
                              ,iv_doc_name     IN  VARCHAR2  DEFAULT NULL                           --文書名
                              ,iv_printer_name IN  VARCHAR2  DEFAULT NULL                           --プリンタ名
                              ,iv_request_id   IN  VARCHAR2                                         --要求ID
                              ,iv_nodata_msg   IN  VARCHAR2                                         --データなしメッセージ
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD START
                              ,iv_excl_code    IN  VARCHAR2                                         --SVF専用マネージャコード
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD END
                              ,iv_svf_param1   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ1
                              ,iv_svf_param2   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ2
                              ,iv_svf_param3   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ3
                              ,iv_svf_param4   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ4
                              ,iv_svf_param5   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ5
                              ,iv_svf_param6   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ6
                              ,iv_svf_param7   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ7
                              ,iv_svf_param8   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ8
                              ,iv_svf_param9   IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ9
                              ,iv_svf_param10  IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ10
                              ,iv_svf_param11  IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ11
                              ,iv_svf_param12  IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ12
                              ,iv_svf_param13  IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ13
                              ,iv_svf_param14  IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ14
                              ,iv_svf_param15  IN  VARCHAR2  DEFAULT NULL                           --svf可変パラメータ15
                              )
  IS
    -- ===============================
    -- ユーザー宣言ローカル定数
    -- ===============================
    -- 基本情報
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submit_svf_request';
    -- SVF起動コンカレントの引数関連
    cv_svf_app              CONSTANT VARCHAR2(30)   := 'SVF';
    cv_ftp_app              CONSTANT VARCHAR2(30)   := 'XXCCP';
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--    cv_svf_prog             CONSTANT VARCHAR2(30)   := 'SVF_ORA';
--    cv_ftp_prog             CONSTANT VARCHAR2(30)   := 'XXCCP004A02C';
    cv_svf_prog             CONSTANT VARCHAR2(30)   := 'SVF_ORA_';
    cv_ftp_prog             CONSTANT VARCHAR2(30)   := 'XXCCP004A02C_';
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
    cv_orgid                CONSTANT VARCHAR2(100)  := '0';
    cv_op_spool             CONSTANT VARCHAR2(30)   := 'SpoolFileName=';
    cv_op_msg               CONSTANT VARCHAR2(30)   := 'NODATA_MSG=';
    cv_op_cond              CONSTANT VARCHAR2(30)   := 'Condition=';
    cv_opv_cond1            CONSTANT VARCHAR2(30)   := '[REQUEST_ID]=';
    cv_form_mode_4          CONSTANT VARCHAR2(30)   := 'FormMode=4';
    --
    -- システムプロファイル名称定数
    cv_plofile01            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_HOST_NAME'     ;                 -- XXCCP:SVFホスト名
    cv_plofile02            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_LOGIN_USER'    ;                 -- XXCCP:SVFログインユーザ名
    cv_plofile03            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_LOGIN_PASSWORD';                 -- XXCCP:SVFログインパスワード
    cv_plofile04            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_ENV'           ;                 -- XXCCP:SVF実行環境パス
    cv_plofile05            CONSTANT VARCHAR2(30)   := 'XXCCP1_EBS_TEMP_PATH'     ;                 -- XXCCP:EBSサーバ一時ファイル格納PATH
    cv_plofile06            CONSTANT VARCHAR2(30)   := 'XXCCP1_EBS_TEMP_FILENAME' ;                 -- XXCCP:EBSサーバ一時ファイル名
    cv_plofile07            CONSTANT VARCHAR2(30)   := 'XXCCP1_NODATA_MSG'        ;                 -- XXCCP:SVFオプション・データ無しメッセージ
    cv_plofile08            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVFCONC_INTERVAL'  ;                 -- XXCCP:SVFコンカレント監視間隔
    cv_plofile09            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVFCONC_MAXWAIT'   ;                 -- XXCCP:SVFコンカレント最大監視時間
    cv_plofile10            CONSTANT VARCHAR2(30)   := 'XXCCP1_FTPCONC_INTERVAL'  ;                 -- XXCCP:ファイル転送コンカレント監視間隔
    cv_plofile11            CONSTANT VARCHAR2(30)   := 'XXCCP1_FTPCONC_MAXWAIT'   ;                 -- XXCCP:ファイル転送コンカレント最大監視時間
    cv_plofile12            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_DRAIVE'        ;                 -- XXCCP:SVF実行ドライブ名
    --
    -- その他
    cv_mode_pdf             CONSTANT VARCHAR2(1)    := '1';                                         -- 出力区分 1：PDF出力
    cv_mode_rde             CONSTANT VARCHAR2(1)    := '2';                                         -- 出力区分 2：RDE出力
    cv_mode_rep             CONSTANT VARCHAR2(1)    := '3';                                         -- 出力区分 3：ReportMisson出力
    cn_svf_prm_len          CONSTANT NUMBER         := 240;                                         -- SVFコンカレントのパラメータ最大長
    cn_pad_plofile          CONSTANT NUMBER         := 30;                                          -- プロファイル表示時PAD時の詰め数
    cn_pad_prm              CONSTANT NUMBER         := 36;                                          -- パラメータ表示時PAD時の詰め数
    --
    -- ===============================
    -- ユーザー宣言ローカル変数
    -- ===============================
    -- INFO
    lv_step                 VARCHAR2(100) := NULL;
    --
    -- IN PRM
    -- SVF起動コンカレント/ファイル転送コンカレント用変数(プロファイルからの取得値)
    lv_svf_host_name        VARCHAR2(240) := NULL;                                                  -- SVFサーバのHOST名
    lv_svf_login_user       VARCHAR2(240) := NULL;                                                  -- SVFサーバのLoginユーザ名
    lv_svf_login_pass       VARCHAR2(240) := NULL;                                                  -- SVFサーバのLoginパスワード
    lv_svf_spool_dir        VARCHAR2(240) := NULL;                                                  -- spool先ディレクトリパス
    lv_from_dir             VARCHAR2(240) := NULL;                                                  -- Form様式ファイル格納先ディレクトリパス
    lv_quary_dir            VARCHAR2(240) := NULL;                                                  -- Quary様式ファイル格納先ディレクトリパス
    lv_svf_env              VARCHAR2(240) := NULL;                                                  -- SVF実行環境パス
    lv_svfdrive             VARCHAR2(240) := NULL;                                                  -- SVF実行ドライブ名
    lv_ebs_put_fpath        VARCHAR2(240) := NULL;                                                  -- EBS側の取得ファイル絶対パス
    lv_ebs_temp_dir         VARCHAR2(240) := NULL;                                                  -- EBS側の一時LOGファイル格納ディレクトリパス
    lv_ebs_temp_file        VARCHAR2(240) := NULL;                                                  -- EBS側の一時LOGファイル名称
    lv_nodata_msg           VARCHAR2(240) := NULL;                                                  -- デフォルトのNO_DATA_MASSAGE
    lv_svf_interval         VARCHAR2(240) := NULL;                                                  -- SVF起動コンカレントの監視間隔(秒)
    lv_ftp_interval         VARCHAR2(240) := NULL;                                                  -- FTP転送コンカレントの監視間隔(秒)
    lv_svf_maxwait          VARCHAR2(240) := NULL;                                                  -- SVF起動コンカレントの最大終了待ち時間(秒)
    lv_ftp_maxwait          VARCHAR2(240) := NULL;                                                  -- FTP転送コンカレントの最大終了待ち時間(秒)
    -- 編集用変数
    lv_spool_op_edit        VARCHAR2(500) := NULL;
    lv_print_op_edit        VARCHAR2(500) := NULL;
    lv_msg_op_edit          VARCHAR2(500) := NULL;
    lv_cond_001             VARCHAR2(240) := NULL;
    lv_cond_002             VARCHAR2(240) := NULL;
    lv_cond_003             VARCHAR2(240) := NULL;
    lv_cond_004             VARCHAR2(240) := NULL;
    lv_cond_005             VARCHAR2(240) := NULL;
    lv_cond_006             VARCHAR2(240) := NULL;
    lv_cond_007             VARCHAR2(240) := NULL;
    lv_cond_008             VARCHAR2(240) := NULL;
    lv_cond_009             VARCHAR2(240) := NULL;
    lv_cond_010             VARCHAR2(240) := NULL;
    lv_cond_011             VARCHAR2(240) := NULL;
    lv_cond_012             VARCHAR2(240) := NULL;
    lv_cond_013             VARCHAR2(240) := NULL;
    lv_cond_014             VARCHAR2(240) := NULL;
    lv_cond_015             VARCHAR2(240) := NULL;
    ln_cond_cnt             NUMBER := 0;                                                            -- 追加条件の件数カウント 
    -- OUT PRM
    -- FND_REQUEST.SUBMIT_REQUEST返り値格納変数
    ln_svf_reqid            NUMBER := NULL;                                                         -- SVF起動コンカレントのリクエストID
    ln_ftp_reqid            NUMBER := NULL;                                                         -- FTP転送コンカレントのリクエストID
    --
    -- FND_CONCURRENT.WAIT_FOR_REQUEST返り値格納変数
    lv_phase                VARCHAR2(4000) := NULL;                                                 -- 要求フェーズ(FND設定)
    lv_status               VARCHAR2(4000) := NULL;                                                 -- 実行結果(FND設定)
    lv_dev_phase            VARCHAR2(4000) := NULL;                                                 -- 要求フェーズ(英語)
    lv_dev_status           VARCHAR2(4000) := NULL;                                                 -- 実行結果(英語)
    lv_message              VARCHAR2(4000) := NULL;                                                 -- メッセージ
    lb_ret_bool             BOOLEAN := NULL ;                                                       -- 論理型返り値
    --
    -- OTHER
    ln_error_msg_cnt        NUMBER  := 0;                                                           -- エラーメッセージのカウント
    ln_loop_cnt             NUMBER  := 0;                                                           -- LOOPカウント用変数
    -- ===============================
    -- ユーザー宣言ローカルカーソル
    -- ===============================
    --
    -- ===============================
    -- ユーザー宣言ローカルレコード
    -- ===============================
    -- コンカレント引数用
    lt_svf_argument         gt_conc_argument;                                                       -- SVF起動コンカレント用パラメータセット
    lt_ftp_argument         gt_conc_argument;                                                       -- ファイル転送コンカレント用パラメータセット
    --
    -- ===============================
    -- ユーザー宣言ローカル例外
    -- ===============================
    prm_error_expt          EXCEPTION;                                                              -- パラメータのエラー
    date_accession_expt     EXCEPTION;                                                              -- データ取得エラー
    --
  BEGIN
    lv_step         := 'STEP 00.00.00';
    -- ==============================================================
    -- 1.初期処理
    -- ==============================================================
    -- *******************************
    -- 1-1.変数初期化
    -- *******************************
    lv_step         := 'STEP 01.01.00';
    -- OUTパラメータの初期化
    ov_retcode      := cv_status_normal;
    ov_errbuf       := NULL;
    ov_errmsg       := NULL;
    --
    -- *******************************
    -- 1-2.入力パラメータログ出力
    -- *******************************
    -- 1-2.パラメータのログ出力
    -- IN:01.コンカレント名
    lv_step         := 'STEP 01.02.01';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm01, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_conc_name
      );
    --
    -- IN:02.出力ファイル名
    lv_step         := 'STEP 01.02.02';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm02, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_file_name
      );
    --
    -- IN:03.帳票ID
    lv_step         := 'STEP 01.02.03';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm03, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_file_id
      );
    --
    -- IN:04.出力区分
    lv_step         := 'STEP 01.02.04';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm04, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_output_mode
      );
    --
    -- IN:05.フォーム様式ファイル名
    lv_step         := 'STEP 01.02.05';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm05, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_frm_file
      );
    --
    -- IN:06.クエリー様式ファイル名
    lv_step         := 'STEP 01.02.06';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm06, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_vrq_file
      );
    --
    -- IN:07.ORG_ID
    lv_step         := 'STEP 01.02.07';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm07, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_org_id
      );
    --
    -- IN:08.ログイン・ユーザ名
    lv_step         := 'STEP 01.03.08';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm08, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_user_name
      );
    --
    -- IN:09.ログイン・ユーザの職責名
    lv_step         := 'STEP 01.02.09';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm09, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_resp_name
      );
    --
    -- IN:10.文書名
    lv_step         := 'STEP 01.02.10';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm10, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_doc_name
      );
    --
    -- IN:11.プリンタ名
    lv_step         := 'STEP 01.02.11';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm11, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_printer_name
      );
    --
    -- IN:12.要求ID
    lv_step         := 'STEP 01.02.12';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm12, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_request_id
      );
    --
    -- IN:13.データなしメッセージ
    lv_step         := 'STEP 01.02.13';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm13, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_nodata_msg
      );
    --
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD START
    -- IN:29.SVF専用マネージャコード
    lv_step         := 'STEP 01.02.29';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm29, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_excl_code
      );
    --
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD END
    -- IN:14.svf可変パラメータ1
    lv_step         := 'STEP 01.02.14';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm14, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param1
      );
    --
    -- IN:15.svf可変パラメータ2
    lv_step         := 'STEP 01.02.15';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm15, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param2
      );
    --
    -- IN:16.svf可変パラメータ3
    lv_step         := 'STEP 01.02.16';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm16, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param3
      );
    --
    -- IN:17.svf可変パラメータ4
    lv_step         := 'STEP 01.02.17';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm17, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param4
      );
    --
    -- IN:18.svf可変パラメータ5
    lv_step         := 'STEP 01.02.18';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm18, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param5
      );
    --
    -- IN:19.svf可変パラメータ6
    lv_step         := 'STEP 01.02.19';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm19, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param6
      );
    --
    -- IN:20.svf可変パラメータ7
    lv_step         := 'STEP 01.02.20';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm20, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param7
      );
    --
    -- IN:21.svf可変パラメータ8
    lv_step         := 'STEP 01.02.21';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm21, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param8
      );
    --
    -- IN:22.svf可変パラメータ9
    lv_step         := 'STEP 01.02.22';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm22, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param9
      );
    --
    -- IN:23.svf可変パラメータ10
    lv_step         := 'STEP 01.02.23';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm23, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param10
      );
    --
    -- IN:24.svf可変パラメータ11
    lv_step         := 'STEP 01.02.24';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm24, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param11
      );
    --
    -- IN:25.svf可変パラメータ12
    lv_step         := 'STEP 01.02.25';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm25, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param12
      );
    --
    -- IN:26.svf可変パラメータ13
    lv_step         := 'STEP 01.02.26';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm26, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param13
      );
    --
    -- IN:27.svf可変パラメータ14
    lv_step         := 'STEP 01.02.27';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm27, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param14
      );
    --
    -- IN:28.svf可変パラメータ15
    lv_step         := 'STEP 01.02.28';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm28, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param15
      );
    --
--
    -- *******************************
    -- 1-3.入力パラメータチェック
    -- *******************************
    lv_step         := 'STEP 01.03.00';
    -- IN_01.コンカレント名[ iv_conc_name ]のチェック(必須チェック)
    IF (iv_conc_name IS NULL ) THEN
      lv_step         := 'STEP.01.03.01';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm01
        );
    END IF;
    --
    -- IN_02.出力ファイル名[ iv_file_name ]のチェック(必須チェック)
    IF (iv_file_name IS NULL ) THEN
      lv_step         := 'STEP.01.03.02';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm02
        );
    END IF;
    --
    -- IN_03.帳票ID[ iv_file_id ]
    -- 未使用なのでチェック対象外
    --
    -- IN_04.出力区分[ iv_output_mode ]のチェック(整合性チェック)
    IF (iv_output_mode IS NULL OR iv_output_mode NOT IN(cv_mode_pdf)) THEN
      lv_step         := 'STEP.01.03.04';
      -- iv_output_modeがNULLの場合か'1'以外の場合にエラー
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_unjust,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm04
        );
    END IF;
    --
    -- IN_05.フォーム様式ファイル名[ iv_frm_file ]のチェック(必須チェック)
    IF (iv_frm_file IS NULL ) THEN
      lv_step         := 'STEP.01.03.05';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm05
        );
    END IF;
    --
    -- IN_06.クエリー様式ファイル名[ iv_vrq_file ]のチェック(必須チェック)
    IF (iv_vrq_file IS NULL ) THEN
      lv_step         := 'STEP.01.03.06';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm06
        );
    END IF;
    --
    -- IN_07.ORG_ID[ iv_org_id ]
    -- IN_08.ログイン・ユーザ名[ iv_user_name ]
    -- IN_09.ログイン・ユーザの職責名[ iv_resp_name ]
    -- IN_10.文書名[ iv_doc_name ]
    -- IN_11.プリンタ名[ iv_printer_name ]
    -- ↑は未使用なのでチェック対象外
    --
    -- IN_12.要求ID[ iv_request_id ]のチェック(必須チェック)
    IF (iv_request_id IS NULL ) THEN
      lv_step         := 'STEP.01.03.12';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm12
        );
    END IF;
    -- IN_13.データなしメッセージ[ iv_nodata_msg ]のチェック(整合性チェック)
    -- SVFオプションパラメータ【データ無しメッセージ】の作成時にチェック
    --
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD START
    -- IN_29.SVF専用マネージャコード[ iv_excl_code ]のチェック(必須チェック)
    IF (iv_excl_code IS NULL ) THEN
      lv_step         := 'STEP.01.03.29';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm29
        );
    END IF;
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara ADD END
--
    -- IN_14.svf可変パラメータ01[ iv_svf_param1 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param1 IS NOT NULL) AND ( LENGTHB(iv_svf_param1) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param1への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.14';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm14
        );
    END IF;
    --
    -- IN_15.svf可変パラメータ02[ iv_svf_param2 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param2 IS NOT NULL) AND ( LENGTHB(iv_svf_param2) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param2への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.15';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm15
        );
    END IF;
    --
    -- IN_16.svf可変パラメータ03[ iv_svf_param3 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param3 IS NOT NULL) AND ( LENGTHB(iv_svf_param3) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param3への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.16';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm16
        );
    END IF;
    --
    -- IN_17.svf可変パラメータ04[ iv_svf_param4 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param4 IS NOT NULL) AND ( LENGTHB(iv_svf_param4) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param4への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.17';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm17
        );
    END IF;
    --
    -- IN_18.svf可変パラメータ05[ iv_svf_param5 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param5 IS NOT NULL) AND ( LENGTHB(iv_svf_param5) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param5への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.18';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm18
        );
    END IF;
    --
    -- IN_19.svf可変パラメータ06[ iv_svf_param6 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param6 IS NOT NULL) AND ( LENGTHB(iv_svf_param6) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param6への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.19';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm19
        );
    END IF;
    --
    -- IN_20.svf可変パラメータ07[ iv_svf_param7 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param7 IS NOT NULL) AND ( LENGTHB(iv_svf_param7) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param7への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.20';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm20
        );
    END IF;
    --
    -- IN_21.svf可変パラメータ08[ iv_svf_param8 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param8 IS NOT NULL) AND ( LENGTHB(iv_svf_param8) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param8への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.21';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm21
        );
    END IF;
    --
    -- IN_22.svf可変パラメータ09[ iv_svf_param9 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param9 IS NOT NULL) AND ( LENGTHB(iv_svf_param9) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param9への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.22';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm22
        );
    END IF;
    --
    -- IN_23.svf可変パラメータ10[ iv_svf_param10 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param10 IS NOT NULL) AND ( LENGTHB(iv_svf_param10) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param10への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.23';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm23
        );
    END IF;
    --
    -- IN_24.svf可変パラメータ11[ iv_svf_param11 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param11 IS NOT NULL) AND ( LENGTHB(iv_svf_param11) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param11への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.24';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm24
        );
    END IF;
    --
    -- IN_25.svf可変パラメータ12[ iv_svf_param12 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param12 IS NOT NULL) AND ( LENGTHB(iv_svf_param12) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param12への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.25';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm25
        );
    END IF;
    --
    -- IN_26.svf可変パラメータ13[ iv_svf_param13 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param13 IS NOT NULL) AND ( LENGTHB(iv_svf_param13) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param13への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.26';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm26
        );
    END IF;
    --
    -- IN_27.svf可変パラメータ14[ iv_svf_param14 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param14 IS NOT NULL) AND ( LENGTHB(iv_svf_param14) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param14への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.27';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm27
        );
    END IF;
    --
    -- IN_28.svf可変パラメータ15[ iv_svf_param15 ]のチェック(パラメータ長チェック)
    IF ( (iv_svf_param15 IS NOT NULL) AND ( LENGTHB(iv_svf_param15) > cn_chk_svfprm_len ) ) THEN
      -- 入力パラメータiv_svf_param15への入力が有り、その長さが230バイトより大きい場合にエラーとする。
      lv_step         := 'STEP.01.03.28';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm28
        );
    END IF;
    --
--
    -- パラメータのエラーの有無を判断
    IF (ln_error_msg_cnt > 0 ) THEN
      -- エラーがある場合は例外処理へ
      lv_step         := 'STEP 01.03.99';
      RAISE prm_error_expt ;
    END IF;
--
    -- *******************************
    -- 1-4.システムプロファイルからの情報取得
    -- *******************************
    lv_step         := 'STEP 01.04.01';
    -- システムプロファイルから値を取得する
    lv_svf_host_name  := FND_PROFILE.VALUE(cv_plofile01);
    lv_svf_login_user := FND_PROFILE.VALUE(cv_plofile02);
    lv_svf_login_pass := FND_PROFILE.VALUE(cv_plofile03);
    lv_svf_env        := FND_PROFILE.VALUE(cv_plofile04);
    lv_ebs_temp_dir   := FND_PROFILE.VALUE(cv_plofile05);
    lv_ebs_temp_file  := FND_PROFILE.VALUE(cv_plofile06);
    lv_nodata_msg     := FND_PROFILE.VALUE(cv_plofile07);
    lv_svf_interval   := FND_PROFILE.VALUE(cv_plofile08);
    lv_svf_maxwait    := FND_PROFILE.VALUE(cv_plofile09);
    lv_ftp_interval   := FND_PROFILE.VALUE(cv_plofile10);
    lv_ftp_maxwait    := FND_PROFILE.VALUE(cv_plofile11);
    lv_svfdrive       := FND_PROFILE.VALUE(cv_plofile12);
    --
    -- 取得データのログ出力
    lv_step         := 'STEP 01.04.02';
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile01, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_host_name, ' ')  );
--    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile02, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_login_user, ' ') );
--    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile03, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_login_pass, ' ') );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile12, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svfdrive, ' ')       );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile04, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_env, ' ')        );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile05, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ebs_temp_dir, ' ')   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile06, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ebs_temp_file, ' ')  );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile07, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_nodata_msg, ' ')     );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile08, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_interval, ' ')   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile09, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_maxwait, ' ')    );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile10, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ftp_interval, ' ')   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile11, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ftp_maxwait, ' ')    );
    --
    -- *******************************
    -- 1-5.システムプロファイル取得チェックを行います。
    -- *******************************
    lv_step         := 'STEP 01.05.00';
    -- システムプロファイル:XXCCP:SVFホスト名
    IF (lv_svf_host_name IS NULL) THEN
      lv_step         := 'STEP 01.05.01';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile01
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:SVFログインユーザ名
    IF (lv_svf_login_user IS NULL) THEN
      lv_step         := 'STEP 01.05.02';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile02
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:SVFログインパスワード
    IF (lv_svf_login_pass IS NULL) THEN
      lv_step         := 'STEP 01.05.03';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile03
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:SVF実行環境パス
    IF (lv_svf_env IS NULL) THEN
      lv_step         := 'STEP 01.05.04';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile04
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:EBSサーバ一時ファイル格納PATH
    IF (lv_ebs_temp_dir IS NULL) THEN
      lv_step         := 'STEP 01.05.05';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile05
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:EBSサーバ一時ファイル名
    IF (lv_ebs_temp_file IS NULL) THEN
      lv_step         := 'STEP 01.05.06';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile06
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:XXCCP:SVFオプション・データ無しメッセージ
    IF (lv_nodata_msg IS NULL) THEN
      lv_step         := 'STEP 01.05.07';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile07
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:SVFコンカレント監視間隔
    IF (lv_svf_interval IS NULL) THEN
      lv_step         := 'STEP 01.05.08';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile08
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:SVFコンカレント最大監視時間
    IF (lv_svf_maxwait IS NULL) THEN
      lv_step         := 'STEP 01.05.09';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile09
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:ファイル転送コンカレント監視間隔
    IF (lv_ftp_interval IS NULL) THEN
      lv_step         := 'STEP 01.05.10';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile10
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:ファイル転送コンカレント最大監視時間
    IF (lv_ftp_maxwait IS NULL) THEN
      lv_step         := 'STEP 01.05.11';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile11
        );
      --
    END IF;
    --
    -- システムプロファイル:XXCCP:SVF実行ドライブ名
    IF (lv_svfdrive IS NULL) THEN
      lv_step         := 'STEP 01.05.12';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile12
        );
      --
    END IF;
    --
    -- システムプロファイルの取得エラーの有無を判断
    IF (ln_error_msg_cnt > 0 ) THEN
      -- エラーがある場合は例外処理へ
      lv_step         := 'STEP 01.05.99';
      RAISE date_accession_expt ;
    --
    END IF;
    --
    --===============================
    -- EBS側格納ファイル絶対パス取得
    --===============================
    lv_step         := 'STEP 01.06.01';
    BEGIN
      -- 要求IDからOUTFILE_NAMEを取得します。
      SELECT  outfile_name
      INTO    lv_ebs_put_fpath
      FROM    fnd_concurrent_requests
      WHERE   request_id = TO_NUMBER(iv_request_id) ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- データ取得エラーメッセージを出力
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_err_date_accession,
          iv_token_01     => cv_token_number,
          iv_token_val01  => cv_token_v_db_val_of
          );
        --
      RAISE date_accession_expt;
    END;
    --
    -- 取得チェック
    IF (lv_ebs_put_fpath IS NULL) THEN
      -- 取得が出来てない場合はエラーとする
      -- データ取得エラーメッセージを出力
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_date_accession,
        iv_token_01     => cv_token_number,
        iv_token_val01  => cv_token_v_db_val_of
        );
        --
        RAISE date_accession_expt;
    END IF;
    -- メッセージ出力をする
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_outpath_msg || RPAD(cv_token_v_db_val_of, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ebs_put_fpath, ' ')    );
    --
    -- ==============================================================
    -- 2.SVFコンカレントの起動
    -- ==============================================================
    lv_step         := 'STEP 02.00.00';
    -- *******************************
    -- 2-1.SVFコンカレント用オプションパラメータの編集
    -- *******************************
    -- 2-1.起動パラメータの編集
    IF (iv_output_mode = cv_mode_pdf ) THEN
      --===============================
      -- 各種パスの生成
      --===============================
      lv_step         := 'STEP 02.01.00';
      lv_svf_spool_dir  := lv_svf_env   || cv_part_bs ||
                           cv_pdf_dir   ;
      lv_from_dir       := lv_svfdrive  || cv_part_bs ||
                           lv_svf_env   || cv_part_bs ||
                           cv_form_dir  || cv_part_bs ||
                           iv_frm_file  ;
      lv_quary_dir      := lv_svfdrive  || cv_part_bs ||
                           lv_svf_env   || cv_part_bs ||
                           cv_query_dir || cv_part_bs ||
                           iv_vrq_file  ;
      --
      --===============================
      -- ファイルスプール先指定オプションの編集
      --===============================
      lv_step         := 'STEP 02.01.01';
      lv_spool_op_edit := cv_op_spool || lv_svfdrive      || cv_part_bs ||
                                         lv_svf_spool_dir || cv_part_bs ||
                                         iv_file_name;
      --
      --===============================
      -- NO DATAメッセージの編集
      --===============================
      IF (iv_nodata_msg IS NOT NULL) THEN
      -- 入力パラメータのデータ無しメッセージ利用時
        lv_step         := 'STEP 02.01.02';
        IF (LENGTH(cv_op_msg || iv_nodata_msg ) > cn_svf_prm_len ) THEN
          lv_step         := 'STEP 02.01.03';
          -- パラメータを作り込んだ結果が240文字以上ならばエラー
          output_log(
            iv_appl         => cv_applcation_xxccp,
            iv_name         => cv_err_prm_unjust,
            iv_token_01     => cv_token_item,
            iv_token_val01  => cv_token_v_prm13
            );
          --
          RAISE prm_error_expt;
          --
        ELSE
          --
          lv_step         := 'STEP 02.01.04';
          lv_msg_op_edit := cv_op_msg ||iv_nodata_msg ;
        END IF;
      --
      ELSE
      -- デフォルトのデータ無しメッセージ利用時
        lv_step         := 'STEP 02.01.05';
        IF (LENGTH(cv_op_msg || lv_nodata_msg ) > cn_svf_prm_len ) THEN
          lv_step         := 'STEP 02.01.06';
          -- パラメータを作り込んだ結果が240文字以上ならばエラー
          output_log(
            iv_appl         => cv_applcation_xxccp,
            iv_name         => cv_err_prm_unjust,
            iv_token_01     => cv_token_item,
            iv_token_val01  => cv_plofile07
            );
          --
          RAISE date_accession_expt;
          --
        ELSE
          --
          lv_step         := 'STEP 02.01.07';
          lv_msg_op_edit := cv_op_msg ||lv_nodata_msg ;
        END IF;
      --
      END IF;
    --
      --
      --===============================
      -- 追加条件の編集(Condition：要求ID)
      --===============================
      -- 要求ID
      lv_step         := 'STEP 02.01.08';
      --
      --===============================
      -- 追加条件の編集(Condition)
      --===============================
      --svf可変パラメータ1
      IF ( iv_svf_param1  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_001 := cv_op_cond || iv_svf_param1  ;
      END IF;
      --
      --svf可変パラメータ2
      IF ( iv_svf_param2  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_002 := cv_op_cond || iv_svf_param2  ;
      END IF;
      --
      --svf可変パラメータ3
      IF ( iv_svf_param3  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_003 := cv_op_cond || iv_svf_param3  ;
      END IF;
      --
      --svf可変パラメータ4
      IF ( iv_svf_param4  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_004 := cv_op_cond || iv_svf_param4  ;
      END IF;
      --
      --svf可変パラメータ5
      IF ( iv_svf_param5  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_005 := cv_op_cond || iv_svf_param5  ;
      END IF;
      --
      --svf可変パラメータ6
      IF ( iv_svf_param6  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_006 := cv_op_cond || iv_svf_param6  ;
      END IF;
      --
      --svf可変パラメータ7
      IF ( iv_svf_param7  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_007 := cv_op_cond || iv_svf_param7  ;
      END IF;
      --
      --svf可変パラメータ8
      IF ( iv_svf_param8  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_008 := cv_op_cond || iv_svf_param8  ;
      END IF;
      --
      --svf可変パラメータ9
      IF ( iv_svf_param9  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_009 := cv_op_cond || iv_svf_param9  ;
      END IF;
      --
      --svf可変パラメータ10
      IF ( iv_svf_param10 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_010 := cv_op_cond || iv_svf_param10 ;
      END IF;
      --
      --svf可変パラメータ11
      IF ( iv_svf_param11 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_011 := cv_op_cond || iv_svf_param11 ;
      END IF;
      --
      --svf可変パラメータ12
      IF ( iv_svf_param12 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_012 := cv_op_cond || iv_svf_param12 ;
      END IF;
      --
      --svf可変パラメータ13
      IF ( iv_svf_param13 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_013 := cv_op_cond || iv_svf_param13 ;
      END IF;
      --
      --svf可変パラメータ14
      IF ( iv_svf_param14 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_014 := cv_op_cond || iv_svf_param14 ;
      END IF;
      --
      --svf可変パラメータ15
      IF ( iv_svf_param15 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_015 := cv_op_cond || iv_svf_param15 ;
      END IF;
      --
--
--
    -- *******************************
    -- 2-2.SVFコンカレントパラメータの構造体への設定
    -- *******************************
      lv_step         := 'STEP 02.02.01';
      lt_svf_argument.appl    := cv_svf_app;                                                        -- アプリケーション名
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      lt_svf_argument.prog    := cv_svf_prog;                                                       -- プログラム名
      lt_svf_argument.prog    := cv_svf_prog || iv_excl_code;                                       -- プログラム名
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
      lt_svf_argument.arg001  := lv_svf_host_name;                                                  -- SVFサーバHOST名
      lt_svf_argument.arg002  := lv_from_dir;                                                       -- FRM名(フォーム様式ファイルの絶対パス)
      lt_svf_argument.arg003  := lv_quary_dir;                                                      -- QRY名(クエリー様式ファイルの絶対パス)
      lt_svf_argument.arg004  := cv_orgid;                                                          -- Org_id名
      lt_svf_argument.arg005  := lv_spool_op_edit;                                                  -- ファイルスプール先指定オプション
      lt_svf_argument.arg006  := lv_msg_op_edit ;                                                   -- NO DATAメッセージ設定オプション
      lt_svf_argument.arg007  := cv_form_mode_4;                                                    -- フォーム様式ファイルのモードオプション
      --===============================
      -- 追加抽出条件(Condition)の設定
      --===============================
      IF ( ln_cond_cnt = 0 )THEN
        -- 追加条件が無い場合は要求IDを条件句として編集しセットする 
        -- Condition=[REQUEST_ID]=9999999
        lv_cond_001 := cv_op_cond || cv_opv_cond1 || iv_request_id ;
        lt_svf_argument.arg008  :=  lv_cond_001 ;
      ELSE
        -- 追加条件が一つでも在る場合はそのままセットする
        lt_svf_argument.arg008  :=  lv_cond_001 ;                                                   --Condition=svf可変パラメータ01
        lt_svf_argument.arg009  :=  lv_cond_002 ;                                                   --Condition=svf可変パラメータ02
        lt_svf_argument.arg010  :=  lv_cond_003 ;                                                   --Condition=svf可変パラメータ03
        lt_svf_argument.arg011  :=  lv_cond_004 ;                                                   --Condition=svf可変パラメータ04
        lt_svf_argument.arg012  :=  lv_cond_005 ;                                                   --Condition=svf可変パラメータ05
        lt_svf_argument.arg013  :=  lv_cond_006 ;                                                   --Condition=svf可変パラメータ06
        lt_svf_argument.arg014  :=  lv_cond_007 ;                                                   --Condition=svf可変パラメータ07
        lt_svf_argument.arg015  :=  lv_cond_008 ;                                                   --Condition=svf可変パラメータ08
        lt_svf_argument.arg016  :=  lv_cond_009 ;                                                   --Condition=svf可変パラメータ09
        lt_svf_argument.arg017  :=  lv_cond_010 ;                                                   --Condition=svf可変パラメータ10
        lt_svf_argument.arg018  :=  lv_cond_011 ;                                                   --Condition=svf可変パラメータ11
        lt_svf_argument.arg019  :=  lv_cond_012 ;                                                   --Condition=svf可変パラメータ12
        lt_svf_argument.arg020  :=  lv_cond_013 ;                                                   --Condition=svf可変パラメータ13
        lt_svf_argument.arg021  :=  lv_cond_014 ;                                                   --Condition=svf可変パラメータ14
        lt_svf_argument.arg022  :=  lv_cond_015 ;                                                   --Condition=svf可変パラメータ15
      END IF;
    --
    -- ****************************************** テスト時に使用した追加条件句のLOG表示 ************************************************** --
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm14, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_001 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm15, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_002 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm16, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_003 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm17, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_004 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm18, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_005 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm19, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_006 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm20, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_007 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm21, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_008 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm22, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_009 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm23, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_010 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm24, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_011 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm25, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_012 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm26, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_013 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm27, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_014 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm28, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_015 , ' ') );
    -- ************************************************************************************************************************************ --
    --
    END IF ;
    -- 情報ログの出力
    lv_step         := 'STEP 02.02.02';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_appl_name,
      iv_token_01     => cv_token_appl_name,
      iv_token_val01  => cv_svf_app
      );
    --
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_conc_name,
      iv_token_01     => cv_token_conc_name,
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      iv_token_val01  => cv_svf_prog
      iv_token_val01  => lt_svf_argument.prog
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
      );
    --
    -- *******************************
    -- 2-3.SVFコンカレントの実行
    -- *******************************
    lv_step         := 'STEP 02.03.01';
    ln_svf_reqid := start_request(lt_svf_argument);
    --
    -- *******************************
    -- 2-4.SVFコンカレントの実行判断
    -- *******************************
    lv_step         := 'STEP 02.04.00';
    IF (ln_svf_reqid = 0 OR ln_svf_reqid IS NULL) THEN
      lv_step         := 'STEP 02.04.01';
      -- 返り値の要求IDが0かNULLの場合は起動に失敗しているのでエラーとする。
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prog_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_svf_conc
        );
      --
      RAISE global_api_expt;
    --
    ELSE
      -- 起動が成功してる場合は、COMMITしないとSVFが動かない
      lv_step         := 'STEP 02.04.02';
      COMMIT;
      -- コンカレントの起動メッセージを出力する
      --
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_info_request_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_svf_conc,
        iv_token_02     => cv_token_id,
        iv_token_val02  => TO_CHAR(ln_svf_reqid)
        );
    --
    END IF;
    --
    -- ==============================================================
    -- 3.SVFコンカレントの終了待ち
    -- ==============================================================
    -- 3-1.SVFコンカレントのリクエストIDを用いてコンカレントの終了待ちを行う
    lv_step         := 'STEP 03.01.00';
    -- コンカレントの待機
    lb_ret_bool := FND_CONCURRENT.WAIT_FOR_REQUEST(
        request_id          =>  ln_svf_reqid              ,
        interval            =>  TO_NUMBER(lv_svf_interval),
        max_wait            =>  TO_NUMBER(lv_svf_maxwait) ,
        phase               =>  lv_phase                  ,
        status              =>  lv_status                 ,
        dev_phase           =>  lv_dev_phase              ,
        dev_status          =>  lv_dev_status             ,
        message             =>  lv_message
        );
--
    -- ==============================================================
    -- 4.SVFコンカレントの実行結果確認
    -- ==============================================================
    -- *******************************
    -- 4-1.実行結果の判断
    -- *******************************
    IF (lb_ret_bool = cb_TURE ) THEN
      lv_step         := 'STEP 04.01.00';
      -- 待機処理が成功の場合
      -- 実行結果の判断(要求フェーズと要求ステータスより)
      IF (lv_dev_phase = cv_phase_comp AND lv_dev_status = cv_status_nomal ) THEN
        lv_step         := 'STEP 04.01.01';
        -- フェーズ：完了・ステータス：正常の場合には正常終了と見なす
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_info_request_end,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_svf_reqid)
          );
      --
      ELSE
        lv_step         := 'STEP 04.01.02';
        -- 正常完了以外の場合はエラーとして処理する
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_err_exec_conc,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_svf_reqid),
          iv_token_02     => cv_token_phase,
          iv_token_val02  => lv_phase,
          iv_token_03     => cv_token_staus,
          iv_token_val03  => lv_status
          );
        --
        RAISE global_api_expt;
      --
      END IF;
    --
    ELSE
      -- 待機処理が失敗の場合
      lv_step         := 'STEP 04.01.99';
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_process,
        iv_token_01     => cv_token_proc,
        iv_token_val01  => cv_token_v_wait_svf
        );
      --
      RAISE global_api_expt;
      --
    END IF;
--
    -- ==============================================================
    -- 5.ファイル転送コンカレントの起動
    -- ==============================================================
    -- *******************************
    -- 5-1.ファイル転送コンカレントパラメータの構造体への設定
    -- *******************************
    lv_step         := 'STEP 05.01.01';
    lt_ftp_argument.appl    := cv_ftp_app         ;                                               -- アプリケーション名
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--    lt_ftp_argument.prog    := cv_ftp_prog;                                                       -- プログラム名
    lt_ftp_argument.prog    := cv_ftp_prog || iv_excl_code ;                                      -- プログラム名
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
    -- SHELLコンカレント用にパスの\\を/に置き換える
    lt_ftp_argument.arg001  := REPLACE(lv_svf_spool_dir, cv_part_bs, cv_part_sl) ;                -- SVFサーバPDFファイル格納先
    lt_ftp_argument.arg002  := lv_ebs_put_fpath   ;                                               -- EBSサーバ格納PDFファイル絶対パス
    lt_ftp_argument.arg003  := iv_file_name       ;                                               -- PDFファイル名
    lt_ftp_argument.arg004  := lv_ebs_temp_dir    ;                                               -- EBSサーバTempファイル格納先
    lt_ftp_argument.arg005  := lv_ebs_temp_file   ;                                               -- EBSサーバFTPログTempファイル名
    -- 情報ログの出力
    lv_step         := 'STEP 05.01.02';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_appl_name,
      iv_token_01     => cv_token_appl_name,
      iv_token_val01  => cv_ftp_app
      );
    --
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_conc_name,
      iv_token_01     => cv_token_conc_name,
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      iv_token_val01  => cv_ftp_prog
      iv_token_val01  => lt_ftp_argument.prog
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
      );
    --
    -- *******************************
    -- 5-2.ファイル転送コンカレントの実行
    -- *******************************
    lv_step         := 'STEP 05.02.01';
    ln_ftp_reqid := start_request(lt_ftp_argument);
--
    -- *******************************
    -- 5-3.ファイル転送コンカレントの実行判断
    -- *******************************
    lv_step         := 'STEP 05.03.00';
    IF (ln_ftp_reqid = 0 OR ln_ftp_reqid IS NULL) THEN
      lv_step         := 'STEP 05.03.01';
      -- 返り値の要求IDが0かNULLの場合は起動に失敗しているのでエラーとする。
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prog_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_ftp_conc
        );
      --
      RAISE global_api_expt;
    --
    ELSE
      -- 起動が成功してる場合は、COMMITしないとファイル転送コンカレントが動かない
      lv_step         := 'STEP 05.03.02';
      COMMIT;
      -- コンカレントの起動メッセージを出力する
      --
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_info_request_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_ftp_conc,
        iv_token_02     => cv_token_id,
        iv_token_val02  => TO_CHAR(ln_ftp_reqid)
        );
    --
    END IF;
--
    -- ==============================================================
    -- 6.ファイル転送コンカレントの終了待ち
    -- ==============================================================
    -- 6-1.ファイル転送コンカレントのリクエストIDを用いてコンカレントの終了待ちを行う
    lv_step         := 'STEP 06.01.00';
    -- コンカレントの待機
    lb_ret_bool := FND_CONCURRENT.WAIT_FOR_REQUEST(
        request_id          =>  ln_ftp_reqid              ,
        interval            =>  TO_NUMBER(lv_ftp_interval),
        max_wait            =>  TO_NUMBER(lv_ftp_maxwait) ,
        phase               =>  lv_phase                  ,
        status              =>  lv_status                 ,
        dev_phase           =>  lv_dev_phase              ,
        dev_status          =>  lv_dev_status             ,
        message             =>  lv_message
        );
--
    -- ==============================================================
    -- 7.ファイル転送コンカレントの実行結果確認
    -- ==============================================================
    -- *******************************
    -- 7-1.実行結果の判断
    -- *******************************
    IF (lb_ret_bool = cb_TURE ) THEN
      lv_step         := 'STEP 07.01.00';
      -- 待機処理が成功の場合
      -- 実行結果の判断(要求フェーズと要求ステータスより)
      IF (lv_dev_phase = cv_phase_comp AND lv_dev_status = cv_status_nomal ) THEN
        lv_step         := 'STEP 07.01.01';
        -- フェーズ：完了・ステータス：正常の場合には正常終了と見なす
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_info_request_end,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_ftp_reqid)
          );
      --
      ELSE
        lv_step         := 'STEP 07.01.02';
        -- 正常完了以外の場合はエラーとして処理する
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_err_exec_conc,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_ftp_reqid),
          iv_token_02     => cv_token_phase,
          iv_token_val02  => lv_phase,
          iv_token_03     => cv_token_staus,
          iv_token_val03  => lv_status
          );
        --
        RAISE global_api_expt;
      --
      END IF;
    --
    ELSE
      -- 待機処理が失敗の場合
      lv_step         := 'STEP 07.01.99';
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_process,
        iv_token_01     => cv_token_proc,
        iv_token_val01  => cv_token_v_wait_ftp
        );
      --
      RAISE global_api_expt;
    --
    END IF;
  -- 正常終了で処理を抜ける
    ov_retcode  := cv_status_normal;
--
  EXCEPTION
    -- パラメータ不正の場合
    WHEN prm_error_expt THEN
      -- エラーメッセージの出力
      ov_errbuf   := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || SQLERRM , 1, 5000);
      ov_retcode  := cv_status_error;
      ov_errmsg   := xxccp_common_pkg.get_msg(iv_application => cv_applcation_xxccp,
                                              iv_name        => cv_err_end
                                             );
    --
    WHEN date_accession_expt THEN
      -- エラーメッセージの出力
      ov_errbuf   := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || SQLERRM , 1, 5000);
      ov_retcode  := cv_status_error;
      ov_errmsg   := xxccp_common_pkg.get_msg(iv_application => cv_applcation_xxccp,
                                              iv_name        => cv_err_end
                                             ); 
    --
    WHEN global_api_expt THEN
      -- エラーメッセージの出力
      ov_errbuf   := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || SQLERRM , 1, 5000);
      ov_retcode  := cv_status_error;
      ov_errmsg   := xxccp_common_pkg.get_msg(iv_application => cv_applcation_xxccp,
                                              iv_name        => cv_err_end
                                             );
    --
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
  END submit_svf_request;
  --
  --
  /**********************************************************************************
   * Function  Name   : no_data_msg
   * Description      : SVF帳票共通関数(0件出力メッセージ)
   ***********************************************************************************/
  FUNCTION no_data_msg
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD START
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_svfcommon_pkg.no_data_msg';
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_svfcommon_excl_pkg.no_data_msg';
-- Ver.1.0 [障害E_本稼動_15005] SCSK K.Nara MOD END
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'出力対象はありません。');
    RETURN xxccp_common_pkg.set_status_normal;
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
  END no_data_msg;
  --
END xxccp_svfcommon_excl_pkg;
/
