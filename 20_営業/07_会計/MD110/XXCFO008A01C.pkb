CREATE OR REPLACE PACKAGE BODY XXCFO008A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO008A01C
 * Description     : 顧客マスタVD釣銭基準額の更新
 * MD.050          : MD050_CFO_008_A01_顧客マスタVD釣銭基準額の更新
 * MD.070          : MD050_CFO_008_A01_顧客マスタVD釣銭基準額の更新
 * Version         : 1.2
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        入力パラメータ値ログ出力処理     (A-1)
 *  get_system_value  P        各種システム値取得処理           (A-2)
 *  get_process_date  P        処理日・処理会計期間取得処理     (A-3)
 *  get_customer_change_balance P 顧客別釣銭残高抽出処理        (A-4)
 *  get_change_unpaid P        未払い・先日付支払データ抽出処理 (A-5)
 *  get_change_back   P        釣銭戻し先日付データ抽出処理     (A-6)
 *  update_xxcmm_cust_accounts P 釣銭金額更新処理               (A-7)
 *  get_other_vd_cust P        VD以外の顧客情報取得処理         (A-8)
 *  set_other_vd_cust P        VD以外の顧客情報保持処理         (A-9)
 *  out_other_vd_cust_header P VD以外の顧客情報ヘッダ出力処理   (A-10)
 *  out_other_vd_cust_detail P VD以外の顧客情報明細出力処理     (A-11)
 *  submain           P        メイン処理プロシージャ
 *  main              P        コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-07    1.0  SCS 加藤 忠   初回作成
 *  2009-06-26    1.1  SCS 佐々木    [0000018]パフォーマンス改善
 *  2009-11-24    1.2  SCS 寺内      [E_本稼動_00017]パフォーマンス改善
 ************************************************************************/
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
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--
  lock_expt                 EXCEPTION;      -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO008A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';        -- アドオン：マスタ・経理・共通のアプリケーション短縮名
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- アドオン：共通・IF領域のアプリケーション短縮名
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_008a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --プロファイル取得エラーメッセージ
  cv_msg_008a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015'; --処理日取得エラーメッセージ
  cv_msg_008a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00016'; --会計期間取得エラーメッセージ
  cv_msg_008a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00017'; --前月会計期間取得エラーメッセージ
  cv_msg_008a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00006'; --VD以外の顧客に釣銭残高が存在する場合の警告メッセージ(ヘッダ)
  cv_msg_008a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00007'; --VD以外の顧客に釣銭残高が存在する場合の警告メッセージ(明細)
  cv_msg_008a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00018'; --値セット取得エラーメッセージ
  cv_msg_008a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; --ロックエラーメッセージ
  cv_msg_008a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020'; --データ更新エラーメッセージ
  cv_msg_008a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; --対象データが0件
  cv_msg_008a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00032'; --データ取得エラーメッセージ
--
  -- トークン
  cv_tkn_prof             CONSTANT VARCHAR2(20) := 'PROF_NAME';                 -- プロファイル名
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';                     -- テーブル名
  cv_tkn_target_date      CONSTANT VARCHAR2(20) := 'TARGET_DATE';               -- 処理日
  cv_tkn_customer_number  CONSTANT VARCHAR2(20) := 'CUSTOMER_NUMBER';           -- 顧客コード
  cv_tkn_customer_name    CONSTANT VARCHAR2(20) := 'CUSTOMER_NAME';             -- 顧客名称
  cv_tkn_kyoten_code      CONSTANT VARCHAR2(20) := 'KYOTEN_CODE';               -- 売上拠点コード
  cv_tkn_kyoten_name      CONSTANT VARCHAR2(20) := 'KYOTEN_NAME';               -- 売上拠点名
  cv_tkn_flex_value       CONSTANT VARCHAR2(20) := 'FLEX_VALUE';                -- 値セット名
  cv_tkn_flex_value_set   CONSTANT VARCHAR2(20) := 'FLEX_VALUE_SET_NAME';       -- 値セット値
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERRMSG';                    -- ORACLEエラーの内容
  cv_tkn_data             CONSTANT VARCHAR2(20) := 'DATA';                        -- エラーデータの説明
--
  -- 日本語辞書
  cv_dict_aplid_sqlgl     CONSTANT VARCHAR2(100) := 'CFO000A00001';               -- "アプリケーションID：SQLGL"
--
  -- プロファイル
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';          -- 会計帳簿ID
  cv_gyotai_chu_vd        CONSTANT VARCHAR2(30) := 'XXCFO1_CUST_GYOTAI_CHU_VD'; -- XXCFO:VD業態中分類コード
--
  -- アプリケーション短縮名
  cv_appl_shrt_name_gl    CONSTANT fnd_application.application_short_name%TYPE := 'SQLGL'; -- アプリケーション短縮名(一般会計)
--
  -- クイックコードタイプ
  cv_type_change_account  CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFO1_CHANGE_ACCOUNT'; -- 釣銭勘定科目コード
  cv_type_cust_gyotai_sho CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMM_CUST_GYOTAI_SHO'; -- 業態分類(小分類)
--
  -- 使用DB名
  gv_tkn_xxca_tab         CONSTANT VARCHAR2(50) := 'XXCMM_CUST_ACCOUNTS';       -- テーブル名：顧客追加情報テーブル
--
  cv_adj_period_flag_n    CONSTANT gl_period_statuses.adjustment_period_flag%TYPE := 'N'; -- 調整期間フラグ(通常期間)
  cv_actual_flag_a        CONSTANT gl_balances.actual_flag%TYPE := 'A';        -- 実績フラグ(実績)
  cv_enabled_flag_y       CONSTANT fnd_lookup_values.enabled_flag%TYPE := 'Y'; -- 有効フラグ(有効)
  cv_currency_code        CONSTANT gl_balances.currency_code%TYPE := 'JPY';    -- 通貨コード(円)
  cv_status_p             CONSTANT gl_je_headers.status%TYPE := 'P';           -- 仕訳ステータス(転記済)
  cv_je_source_pay        CONSTANT gl_je_headers.je_source%TYPE := 'Payables'; -- 仕訳ソースコード(買掛管理)
  cv_je_category_purinv   CONSTANT gl_je_headers.je_category%TYPE := 'Purchase Invoices'; -- 仕訳カテゴリコード(仕入請求書)
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         -- ログ出力
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 顧客別釣銭残高情報配列
  TYPE g_segment5_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_cust_account_id_ttype  IS TABLE OF hz_cust_accounts.cust_account_id%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_sale_base_code_ttype   IS TABLE OF xxcmm_cust_accounts.sale_base_code%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_attribute1_ttype       IS TABLE OF fnd_lookup_values.attribute1%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_change_balance_ttype   IS TABLE OF NUMBER
                                            INDEX BY PLS_INTEGER;
  gt_segment5                   g_segment5_ttype;                     -- 顧客コード
  gt_cust_account_id            g_cust_account_id_ttype;              -- 顧客ID
  gt_sale_base_code             g_sale_base_code_ttype;               -- 売上拠点コード
  gt_attribute1                 g_attribute1_ttype;                   -- 業態分類（中分類）
  gt_change_balance             g_change_balance_ttype;               -- 当月末釣銭残高
--
  -- VD以外顧客情報配列
  TYPE g_other_vd_cust_rtype    IS RECORD(
    flex_value_partner          fnd_flex_values_vl.flex_value%TYPE,   -- 顧客コード
    description_partner         fnd_flex_values_vl.description%TYPE,  -- 顧客名
    flex_value_department       fnd_flex_values_vl.flex_value%TYPE,   -- 売上拠点コード
    description_department      fnd_flex_values_vl.description%TYPE   -- 売上拠点名
  );
  TYPE g_other_vd_cust_ttype    IS TABLE OF g_other_vd_cust_rtype
                                            INDEX BY PLS_INTEGER;
  gt_other_vd_cust              g_other_vd_cust_ttype;                -- VD以外顧客情報配列
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_set_of_bks_id            NUMBER;                                 -- 会計帳簿ID
  gn_gyotai_chu_vd            NUMBER;                                 -- XXCFO:VD業態中分類コード
  gn_appl_id_gl               fnd_application.application_id%TYPE;    -- アプリケーションID(一般会計)
  gd_operation_date           DATE;                                   -- 処理日
  gv_this_period_name         gl_period_statuses.period_name%TYPE;    -- 当月会計期間
  gv_last_period_name         gl_period_statuses.period_name%TYPE;    -- 前月会計期間
  gn_change_unpaid            NUMBER;                                 -- 釣銭未払い金額
  gn_change_back              NUMBER;                                 -- 釣銭戻し先日付金額
  gv_flex_value_partner       fnd_flex_values_vl.flex_value%TYPE;     -- 顧客コード
  gv_description_partner      fnd_flex_values_vl.description%TYPE;    -- 顧客名
  gv_flex_value_department    fnd_flex_values_vl.flex_value%TYPE;     -- 売上拠点コード
  gv_description_department   fnd_flex_values_vl.description%TYPE;    -- 売上拠点名
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_operation_date   IN  VARCHAR2,     --   運用日
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out     -- メッセージ出力
      ,iv_conc_param1  => iv_operation_date    -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ログ出力
      ,iv_conc_param1  => iv_operation_date    -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_system_value
   * Description      : 各種システム値取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_system_value(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_system_value'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- プロファイルからGL会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- 取得エラー時
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_008a01_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFO:VD業態中分類コード取得
    gn_gyotai_chu_vd := TO_NUMBER(FND_PROFILE.VALUE( cv_gyotai_chu_vd ));
    -- 取得エラー時
    IF ( gn_gyotai_chu_vd IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_008a01_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_gyotai_chu_vd ))
                                                                       -- XXCFO:VD業態中分類コード
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「一般会計」のアプリケーションIDを取得
    gn_appl_id_gl := xxccp_common_pkg.get_application( cv_appl_shrt_name_gl );
    -- 取得結果がNULLならばエラー
    IF ( gn_appl_id_gl IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_008a01_011 -- データ取得エラー
                                                    ,cv_tkn_data       -- トークン'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_aplid_sqlgl 
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_system_value;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : 処理日・処理会計期間取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    iv_operation_date   IN  VARCHAR2,     --   運用日
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 当処理で使用する処理日を確定する
    IF ( iv_operation_date IS NULL ) THEN
      -- 業務処理日付取得処理
      gd_operation_date := xxccp_common_pkg2.get_process_date;
      --取得結果がNULLならばエラー
      IF ( gd_operation_date IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                      ,cv_msg_008a01_002 ) -- 処理日取得エラー
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSE
      gd_operation_date := TO_DATE(iv_operation_date,'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    -- 当月会計期間を取得する
    BEGIN
      SELECT glps.period_name period_name
      INTO gv_this_period_name
      FROM gl_period_statuses glps
      WHERE glps.application_id         = gn_appl_id_gl
        AND glps.set_of_books_id        = gn_set_of_bks_id
        AND glps.adjustment_period_flag = cv_adj_period_flag_n
        AND gd_operation_date BETWEEN glps.start_date AND glps.end_date
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                      ,cv_msg_008a01_003  -- 会計期間取得エラー
                                                      ,cv_tkn_target_date -- トークン'TARGET_DATE'
                                                      ,TO_CHAR( gd_operation_date,'YYYY/MM/DD' )) -- 処理日
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- 前月会計期間を取得する
    BEGIN
      SELECT glps.period_name period_name
      INTO gv_last_period_name
      FROM gl_period_statuses glps
      WHERE glps.application_id         = gn_appl_id_gl
        AND glps.set_of_books_id        = gn_set_of_bks_id
        AND glps.adjustment_period_flag = cv_adj_period_flag_n
        AND ADD_MONTHS( gd_operation_date,-1 ) BETWEEN glps.start_date AND glps.end_date
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                      ,cv_msg_008a01_004  -- 前月会計期間取得エラー
                                                      ,cv_tkn_target_date -- トークン'TARGET_DATE'
                                                      ,TO_CHAR( gd_operation_date,'YYYY/MM/DD' )) -- 処理日
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : get_customer_change_balance
   * Description      : 顧客別釣銭残高抽出処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_customer_change_balance(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_customer_change_balance'; -- プログラム名
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
    -- 顧客別釣銭残高抽出
    CURSOR get_customer_change_cur
    IS
      SELECT /*+ LEADING(fnac glcc glbl)
                 USE_NL (fnac glcc glbl)
             */
             glcc.segment5                segment5,         -- 顧客コード
             hzca.cust_account_id         cust_account_id,  -- 顧客ID
             xxca.sale_base_code          sale_base_code,   -- 売上拠点コード
             fnlt.attribute1              attribute1,       -- 業態分類(中分類)
             SUM( glbl.begin_balance_dr -
                  glbl.begin_balance_cr +
                  glbl.period_net_dr -
                  glbl.period_net_cr )    change_balance    -- 当月末釣銭残高
      FROM  gl_code_combinations glcc
           ,gl_balances          glbl
           ,fnd_lookup_values    fnac                       -- クイックコード(釣銭勘定科目コード)
           ,fnd_lookup_values    fnlt                       -- クイックコード(業態分類(小分類))
           ,hz_cust_accounts     hzca
           ,xxcmm_cust_accounts  xxca
-- == 2009/06/26 V1.1 Added START ===============================================================
           ,gl_sets_of_books     gsob
-- == 2009/06/26 V1.1 Added END   ===============================================================
      WHERE glbl.set_of_books_id      = gn_set_of_bks_id
        AND glbl.period_name          = gv_this_period_name
        AND glbl.actual_flag          = cv_actual_flag_a
        AND glbl.currency_code        = cv_currency_code
        AND glcc.code_combination_id  = glbl.code_combination_id
-- == 2009/06/26 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id = gsob.chart_of_accounts_id
        AND gsob.set_of_books_id      = gn_set_of_bks_id
-- == 2009/06/26 V1.1 Added END   ===============================================================
        AND fnac.lookup_type          = cv_type_change_account
        AND fnac.language             = USERENV( 'LANG' )
        AND fnac.enabled_flag         = cv_enabled_flag_y
        AND NVL( fnac.start_date_active,gd_operation_date ) <= gd_operation_date
        AND NVL( fnac.end_date_active,gd_operation_date )   >= gd_operation_date
        AND glcc.segment3             = fnac.lookup_code
        AND glcc.segment5             = hzca.account_number
        AND xxca.customer_id          = hzca.cust_account_id
        AND fnlt.lookup_type          = cv_type_cust_gyotai_sho
        AND fnlt.language             = USERENV( 'LANG' )
        AND fnlt.enabled_flag         = cv_enabled_flag_y
        AND NVL( fnlt.start_date_active,gd_operation_date ) <= gd_operation_date
        AND NVL( fnlt.end_date_active,gd_operation_date )   >= gd_operation_date
        AND xxca.business_low_type   = fnlt.lookup_code
        AND EXISTS (
            SELECT /*+ INDEX(glblmv GL_BALANCES_N1) */
                   'X'
            FROM gl_balances glblmv
            WHERE glblmv.set_of_books_id     = gn_set_of_bks_id
              AND glblmv.currency_code       = cv_currency_code
              AND glblmv.actual_flag         = cv_actual_flag_a
              AND glblmv.period_name         IN ( gv_this_period_name,
                                                  gv_last_period_name )
              AND glblmv.code_combination_id = glbl.code_combination_id
              AND ( glblmv. period_net_dr    <> 0
                 OR glblmv. period_net_cr    <> 0 )
            )
      GROUP BY glcc.segment5,         -- 顧客コード
               hzca.cust_account_id,  -- 顧客ID
               xxca.sale_base_code,   -- 売上拠点コード
               fnlt.attribute1        -- 業態分類(中分類)
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
    -- カーソルオープン
    OPEN get_customer_change_cur;
--
    -- データの一括取得
    FETCH get_customer_change_cur BULK COLLECT INTO
          gt_segment5,
          gt_cust_account_id,
          gt_sale_base_code,
          gt_attribute1,
          gt_change_balance;
--
    -- 対象件数のセット
    gn_target_cnt := gt_segment5.COUNT;
--
    -- カーソルクローズ
    CLOSE get_customer_change_cur;
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
  END get_customer_change_balance;
--
  /**********************************************************************************
   * Procedure Name   : get_change_unpaid
   * Description      : 未払い・先日付支払データ抽出処理 (A-5)
   ***********************************************************************************/
  PROCEDURE get_change_unpaid(
    in_loop_cnt         IN  NUMBER,       --   カレントレコードインデックス
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_change_unpaid'; -- プログラム名
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
    cv_payment_status_y     CONSTANT ap_invoices_all.payment_status_flag%TYPE := 'Y'; -- 支払ステータス(支払済)
    cv_payment_status_n     CONSTANT ap_invoices_all.payment_status_flag%TYPE := 'N'; -- 支払ステータス(未払)
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 釣銭未払い金額を取得する
    BEGIN
      SELECT SUM( NVL( gljl.entered_dr,0 ) -
                  NVL( gljl.entered_cr,0 )) change_unpaid
      INTO gn_change_unpaid
      FROM gl_code_combinations glcc,
           fnd_lookup_values    fnac,
           gl_je_headers        gljh,
           gl_je_lines          gljl,
           ap_invoices_all      apia
-- == 2009/06/26 V1.1 Added START ===============================================================
          ,gl_sets_of_books     gsob
-- == 2009/06/26 V1.1 Added END   ===============================================================
      WHERE gljh.set_of_books_id        = gn_set_of_bks_id
        AND gljh.period_name            IN ( gv_this_period_name,
                                             gv_last_period_name )
        AND gljh.je_source              = cv_je_source_pay      -- 買掛管理
        AND gljh.je_category            = cv_je_category_purinv -- 仕入請求書
        AND gljh.actual_flag            = cv_actual_flag_a
        AND gljh.currency_code          = cv_currency_code
        AND gljh.status                 = cv_status_p
        AND gljh.je_header_id           = gljl.je_header_id
        AND fnac.lookup_type            = cv_type_change_account
        AND fnac.language               = USERENV( 'LANG' )
        AND fnac.enabled_flag           = cv_enabled_flag_y
        AND NVL( fnac.start_date_active,gd_operation_date ) <= gd_operation_date
        AND NVL( fnac.end_date_active,gd_operation_date )   >= gd_operation_date
        AND glcc.segment3               = fnac.lookup_code
        AND glcc.segment5               = gt_segment5( in_loop_cnt )
        AND gljl.code_combination_id    = glcc.code_combination_id
        AND gljl.reference_2            = apia.invoice_id
        AND apia.cancelled_date         IS NULL
        AND (( apia.payment_status_flag = cv_payment_status_n )
          OR ( apia.payment_status_flag = cv_payment_status_y
            AND EXISTS (
                SELECT 'X'
                FROM ap_invoice_payments_all apipa,
                     ap_checks_all           apca
                WHERE apipa.invoice_id = apia.invoice_id
                  AND apca.check_id    = apipa.check_id
                  AND apca.check_date  > gd_operation_date )))
-- == 2009/06/26 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id   = gsob.chart_of_accounts_id
        AND gsob.set_of_books_id        = gn_set_of_bks_id
        AND gljl.period_name            IN ( gv_this_period_name,
                                             gv_last_period_name )
-- == 2009/06/26 V1.1 Added END   ===============================================================
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが取得できない場合、釣銭未払い金額を0とする
        gn_change_unpaid := 0;
    END;
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
  END get_change_unpaid;
--
  /**********************************************************************************
   * Procedure Name   : get_change_back
   * Description      : 釣銭戻し先日付データ抽出処理 (A-6)
   ***********************************************************************************/
  PROCEDURE get_change_back(
    in_loop_cnt         IN  NUMBER,       --   カレントレコードインデックス
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_change_back'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 釣銭戻し先日付金額を取得する
    BEGIN
      SELECT SUM( NVL( gljl.entered_cr,0 ) -
                  NVL( gljl.entered_dr,0 )) change_back
      INTO gn_change_back
      FROM gl_code_combinations glcc,
           fnd_lookup_values    fnac,
           gl_je_headers        gljh,
           gl_je_lines          gljl
-- == 2009/06/26 V1.1 Added START ===============================================================
          ,gl_sets_of_books     gsob
-- == 2009/06/26 V1.1 Added END   ===============================================================
      WHERE gljh.set_of_books_id     = gn_set_of_bks_id
        AND gljh.period_name         = gv_this_period_name
        AND gljh.je_source           <> cv_je_source_pay      -- 買掛管理
        AND gljh.je_category         <> cv_je_category_purinv -- 仕入請求書
        AND gljh.actual_flag         = cv_actual_flag_a
        AND gljh.currency_code       = cv_currency_code
        AND gljh.status              = cv_status_p
        AND gljh.je_header_id        = gljl.je_header_id
        AND fnac.lookup_type         = cv_type_change_account
        AND fnac.language            = USERENV( 'LANG' )
        AND fnac.enabled_flag        = cv_enabled_flag_y
        AND NVL(fnac.start_date_active,gd_operation_date) <= gd_operation_date
        AND NVL(fnac.end_date_active,gd_operation_date)   >= gd_operation_date
        AND glcc.segment3            = fnac.lookup_code
        AND glcc.segment5            = gt_segment5( in_loop_cnt )
        AND gljl.code_combination_id = glcc.code_combination_id
        AND gljl.effective_date      > gd_operation_date
-- == 2009/06/26 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id   = gsob.chart_of_accounts_id
        AND gsob.set_of_books_id        = gn_set_of_bks_id
        AND gljl.period_name            IN ( gv_this_period_name,
                                             gv_last_period_name )
-- == 2009/06/26 V1.1 Added END   ===============================================================
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが取得できない場合、釣銭戻し先日付金額を0とする
        gn_change_back := 0;
    END;
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
  END get_change_back;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcmm_cust_accounts
   * Description      : 釣銭金額更新処理 (A-7)
   ***********************************************************************************/
  PROCEDURE update_xxcmm_cust_accounts(
    in_loop_cnt         IN  NUMBER,       --   カレントレコードインデックス
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xxcmm_cust_accounts'; -- プログラム名
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
    -- テーブルロックカーソル
    CURSOR upd_table_lock_cur
    IS
      SELECT xxca.customer_id  customer_id
      FROM xxcmm_cust_accounts xxca
      WHERE xxca.customer_id = gt_cust_account_id( in_loop_cnt )
      FOR UPDATE OF xxca.customer_id NOWAIT
    ;
--
    -- *** ローカル・レコード ***
    upd_table_lock_rec      upd_table_lock_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 顧客追加情報ロックを行う
    OPEN upd_table_lock_cur;
    FETCH upd_table_lock_cur INTO upd_table_lock_rec;
--
    BEGIN
      UPDATE xxcmm_cust_accounts xxca
      SET xxca.change_amount          = gt_change_balance( in_loop_cnt )
                                      - NVL( gn_change_unpaid,0 )
                                      + NVL( gn_change_back,0 )      -- 釣銭
        , xxca.last_updated_by        = cn_last_updated_by           -- 最終変更者のユーザーID
        , xxca.last_update_date       = cd_last_update_date          -- 最終変更日時
        , xxca.last_update_login      = cn_last_update_login         -- 最終ログインID
        , xxca.request_id             = cn_request_id                -- コンカレントのリクエストID
        , xxca.program_application_id = cn_program_application_id    -- コンカレント・プログラムのアプリケーションID
        , xxca.program_id             = cn_program_id                -- コンカレント・プログラムのプログラムID
        , xxca.program_update_date    = cd_program_update_date       -- コンカレント・プログラムによる最終変更日時
      WHERE CURRENT OF upd_table_lock_cur;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_008a01_009 -- データ更新エラー
                                                      ,cv_tkn_table      -- トークン'TABLE'
                                                      ,xxcfr_common_pkg.get_table_comment(gv_tkn_xxca_tab) --顧客追加情報テーブル
                                                      ,cv_tkn_errmsg     -- トークン'ERRMSG'
                                                      ,SQLERRM )
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- カーソルクローズ
    CLOSE upd_table_lock_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN  -- テーブルロックエラー
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                     ,cv_msg_008a01_008 -- テーブルロックエラー
                                                     ,cv_tkn_table      -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(gv_tkn_xxca_tab)) --顧客追加情報テーブル
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
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
  END update_xxcmm_cust_accounts;
--
  /**********************************************************************************
   * Procedure Name   : get_other_vd_cust
   * Description      : VD以外の顧客情報取得処理 (A-8)
   ***********************************************************************************/
  PROCEDURE get_other_vd_cust(
    in_loop_cnt         IN  NUMBER,       --   カレントレコードインデックス
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_vd_cust'; -- プログラム名
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
    cv_flex_value_set_partner     CONSTANT fnd_flex_value_sets.flex_value_set_name%TYPE := 'XX03_PARTNER';
                                                                      -- 値セット名(AFF顧客)
    cv_flex_value_set_department  CONSTANT fnd_flex_value_sets.flex_value_set_name%TYPE := 'XX03_DEPARTMENT';
                                                                      -- 値セット名(AFF部門)
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 値セット抽出
    CURSOR get_other_vd_cust_cur(
      iv_flex_value_set_name in fnd_flex_value_sets.flex_value_set_name%TYPE,
      iv_flex_value          in fnd_flex_values_vl.flex_value%TYPE)
    IS
      SELECT ffvf.flex_value   flex_value,
             ffvf.description  description
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvf
      WHERE ffvs.flex_value_set_name = iv_flex_value_set_name
        AND ffvs.flex_value_set_id   = ffvf.flex_value_set_id
        AND ffvf.flex_value          = iv_flex_value
    ;
--
    -- *** ローカル・レコード ***
    get_other_vd_cust_rec   get_other_vd_cust_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 顧客名を取得する
    OPEN get_other_vd_cust_cur( cv_flex_value_set_partner,   -- 値セット名(AFF顧客)
                                gt_segment5( in_loop_cnt )); -- 顧客コード
    FETCH get_other_vd_cust_cur INTO get_other_vd_cust_rec;
--
    IF ( get_other_vd_cust_cur%FOUND ) THEN
      gv_flex_value_partner  := get_other_vd_cust_rec.flex_value;
      gv_description_partner := get_other_vd_cust_rec.description;
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo              -- 'XXCFO'
                                                    ,cv_msg_008a01_007           -- 値セット取得エラー
                                                    ,cv_tkn_flex_value           -- トークン'FLEX_VALUE'
                                                    ,gt_segment5( in_loop_cnt )  -- 顧客コード
                                                    ,cv_tkn_flex_value_set       -- トークン'FLEX_VALUE_SET_NAME'
                                                    ,cv_flex_value_set_partner)  -- 値セット名(AFF顧客)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- カーソルクローズ
    CLOSE get_other_vd_cust_cur;
--
    -- 売上拠点名を取得する
    OPEN get_other_vd_cust_cur( cv_flex_value_set_department,         -- 値セット名(AFF部門)
                                gt_sale_base_code( in_loop_cnt )); -- 売上拠点コード
    FETCH get_other_vd_cust_cur INTO get_other_vd_cust_rec;
--
    IF ( get_other_vd_cust_cur%FOUND ) THEN
      gv_flex_value_department  := get_other_vd_cust_rec.flex_value;
      gv_description_department := get_other_vd_cust_rec.description;
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                    -- 'XXCFO'
                                                    ,cv_msg_008a01_007                 -- 値セット取得エラー
                                                    ,cv_tkn_flex_value                 -- トークン'FLEX_VALUE'
                                                    ,gt_sale_base_code( in_loop_cnt )  -- 売上拠点コード
                                                    ,cv_tkn_flex_value_set             -- トークン'FLEX_VALUE_SET_NAME'
                                                    ,cv_flex_value_set_department)     -- 値セット名(AFF部門)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- カーソルクローズ
    CLOSE get_other_vd_cust_cur;
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
  END get_other_vd_cust;
--
  /**********************************************************************************
   * Procedure Name   : set_other_vd_cust
   * Description      : VD以外の顧客情報保持処理 (A-9)
   ***********************************************************************************/
  PROCEDURE set_other_vd_cust(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_other_vd_cust'; -- プログラム名
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
    ln_tab_index    NUMBER;     -- VD以外顧客情報配列格納先索引番号
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
    -- VD以外顧客情報配列格納先索引番号を算出
    ln_tab_index := gt_other_vd_cust.COUNT + 1;
    -- VD以外顧客情報配列へ格納
    gt_other_vd_cust( ln_tab_index ).flex_value_partner     := gv_flex_value_partner;     -- 顧客コード
    gt_other_vd_cust( ln_tab_index ).description_partner    := gv_description_partner;    -- 顧客名
    gt_other_vd_cust( ln_tab_index ).flex_value_department  := gv_flex_value_department;  -- 売上拠点コード
    gt_other_vd_cust( ln_tab_index ).description_department := gv_description_department; -- 売上拠点名
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
  END set_other_vd_cust;
--
  /**********************************************************************************
   * Procedure Name   : out_other_vd_cust_header
   * Description      : VD以外の顧客情報ヘッダ出力処理 (A-10)
   ***********************************************************************************/
  PROCEDURE out_other_vd_cust_header(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_other_vd_cust_header'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- VD以外の顧客に釣銭残高が存在する場合の警告メッセージ(ヘッダ)
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                  ,cv_msg_008a01_005)
                                                 ,1
                                                 ,5000);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
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
  END out_other_vd_cust_header;
--
  /**********************************************************************************
   * Procedure Name   : out_other_vd_cust_detail
   * Description      : VD以外の顧客情報明細出力処理 (A-10)
   ***********************************************************************************/
  PROCEDURE out_other_vd_cust_detail(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_other_vd_cust_detail'; -- プログラム名
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
    ln_loop_cnt     NUMBER;     -- ループカウンタ
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
    <<cust_data_loop>>
    FOR ln_loop_cnt IN gt_other_vd_cust.FIRST..gt_other_vd_cust.LAST LOOP
--
      -- VD以外の顧客に釣銭残高が存在する場合の警告メッセージ(明細)
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo         -- 'XXCFO'
                                                    ,cv_msg_008a01_006
                                                    ,cv_tkn_customer_number -- トークン'CUSTOMER_NUMBER'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).flex_value_partner      -- 顧客コード
                                                    ,cv_tkn_customer_name   -- トークン'CUSTOMER_NAME'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).description_partner     -- 顧客名
                                                    ,cv_tkn_kyoten_code     -- トークン'KYOTEN_CODE'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).flex_value_department   -- 売上拠点コード
                                                    ,cv_tkn_kyoten_name     -- トークン'KYOTEN_NAME'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).description_department) -- 売上拠点名
                                                   ,1
                                                   ,5000);
--
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
--
    END LOOP cust_data_loop;
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
  END out_other_vd_cust_detail;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_operation_date   IN  VARCHAR2,     --   運用日
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_normal_cnt   NUMBER;         -- 正常件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- PL/SQL表の初期化
    gt_segment5.DELETE;         -- 顧客コード
    gt_cust_account_id.DELETE;  -- 顧客ID
    gt_sale_base_code.DELETE;   -- 売上拠点コード
    gt_attribute1.DELETE;       -- 業態分類（中分類）
    gt_change_balance.DELETE;   -- 当月末釣銭残高
    gt_other_vd_cust.DELETE;    -- VD以外顧客情報配列
--
    -- ローカル変数の初期化
    ln_normal_cnt := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       iv_operation_date     -- 運用日
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  各種システム値取得処理(A-2)
    -- =====================================================
    get_system_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  処理日・処理会計期間取得処理(A-3)
    -- =====================================================
    get_process_date(
       iv_operation_date     -- 運用日
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  顧客別釣銭残高抽出処理(A-4)
    -- =====================================================
    get_customer_change_balance(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    IF ( gn_target_cnt > 0 ) THEN
      <<cust_data_loop>>
      FOR ln_loop_cnt IN gt_segment5.FIRST..gt_segment5.LAST LOOP
--
        -- VD顧客なら更新処理、以外はログへ出力
        IF ( gt_attribute1(ln_loop_cnt) = gn_gyotai_chu_vd ) THEN
--
          -- =====================================================
          --  未払い・先日付支払データ抽出処理(A-5)
          -- =====================================================
          get_change_unpaid(
             ln_loop_cnt           -- カレントレコードインデックス
            ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode            -- リターン・コード             --# 固定 #
            ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  釣銭戻し先日付データ抽出処理(A-6)
          -- =====================================================
          get_change_back(
             ln_loop_cnt           -- カレントレコードインデックス
            ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode            -- リターン・コード             --# 固定 #
            ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  釣銭金額更新処理(A-7)
          -- =====================================================
          update_xxcmm_cust_accounts(
             ln_loop_cnt           -- カレントレコードインデックス
            ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode            -- リターン・コード             --# 固定 #
            ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
          -- 更新処理が終わったら正常件数をカウント
          ln_normal_cnt := ln_normal_cnt + 1;
--
        ELSE
--
          -- =====================================================
          --  VD以外の顧客情報取得処理(A-8)
          -- =====================================================
          get_other_vd_cust(
             ln_loop_cnt           -- カレントレコードインデックス
            ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode            -- リターン・コード             --# 固定 #
            ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  VD以外の顧客情報保持処理(A-9)
          -- =====================================================
          set_other_vd_cust(
             lv_errbuf             -- エラー・メッセージ           --# 固定 #
            ,lv_retcode            -- リターン・コード             --# 固定 #
            ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          END IF;
--
        END IF;
      END LOOP cust_data_loop;
--
      -- VD以外の顧客を検出していればログ出力を行う
      IF ( gt_other_vd_cust.COUNT > 0 ) THEN
--
        -- =====================================================
        --  VD以外の顧客情報ヘッダ出力処理(A-10)
        -- =====================================================
        out_other_vd_cust_header(
           lv_errbuf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode            -- リターン・コード             --# 固定 #
          ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  VD以外の顧客情報明細出力処理(A-11)
        -- =====================================================
        out_other_vd_cust_detail(
           lv_errbuf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode            -- リターン・コード             --# 固定 #
          ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    ELSE
      -- 対象データが0件のメッセージ出力を行う
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_008a01_010) -- 対象データが0件
                                                   ,1
                                                   ,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    -- 正常件数のセット
    gn_normal_cnt := ln_normal_cnt;
    -- スキップ件数のセット
    gn_warn_cnt := gt_other_vd_cust.COUNT;
--
    -- VD以外の顧客情報がある場合、警告終了
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
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
    errbuf              OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode             OUT     VARCHAR2,         --    エラーコード     #固定#
    iv_operation_date   IN      VARCHAR2          --    運用日
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
       iv_operation_date    -- 運用日
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
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
    --空行挿入
    FND_FILE.PUT_LINE(
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
END XXCFO008A01C;
/
