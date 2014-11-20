CREATE OR REPLACE PACKAGE BODY XXCMM005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A04C(body)
 * Description      : 所属マスタIF出力（自販機管理）
 * MD.050           : 所属マスタIF出力（自販機管理） MD050_CMM_005_A04
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_csv_file          ファイルオープン処理(A-2)
 *  chk_count_top_dept     最上位部門件数取得(A-3)
 *  get_output_data        処理対象データ抽出(A-4)
 *  output_csv_data        抽出情報出力(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/12    1.0   Masayuki.Sano    新規作成
 *  2009/02/26    1.1   Masayuki.Sano    結合テスト動作不正対応
 *  2009/03/09    1.2   Yuuki.Nakamura   ファイル出力先プロファイル名称変更
 *  2009/04/20    1.3   Yutaka.Kuboshima 障害T1_0590の対応
 *  2009/05/15    1.4   Yutaka.Kuboshima 障害T1_1026の対応
 *  2009/05/21    1.5   Yutaka.Kuboshima 障害T1_1129の対応
 *  2009/06/05    1.6   Yutaka.Kuboshima 障害T1_1320の対応
 *  2009/06/09    1.7   Yutaka.Kuboshima 障害T1_1320の対応
 *  2009/09/02    1.8   Yutaka.Kuboshima 障害0001222の対応
 *  2009/10/02    1.9   Shigeto.Niki     障害I_E_542、E_T3_00469の対応
 *  2011/03/23    1.10  Naoki.Horigome   E_本稼動_02541、02550対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  no_output_data_expt       EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM005A04C';                  -- パッケージ名
  -- ■ アプリケーション短縮名
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30)  := 'XXCMM';                      -- マスタ
  cv_app_name_xxccp   CONSTANT VARCHAR2(30)  := 'XXCCP';                      -- 共通・IF
  -- ■ カスタム・プロファイル・オプション(XXCMM:所属マスタIF出力(自販機管理)連携用)
--ver.1.2 2009/03/09 mod by Yuuki.Nakamura start
--  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_005A04_OUT_FILE_DIR';  -- CSVファイル出力先
  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_JIHANKI_OUT_DIR';        -- CSVファイル出力先
--ver.1.2 2009/03/09 mod by Yuuki.Nakamura end
  cv_pro_out_file_fil CONSTANT VARCHAR2(50) := 'XXCMM1_005A04_OUT_FILE_FIL';  -- CSVファイル名
-- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
  cv_aff_dept_dummy_cd CONSTANT VARCHAR2(50)  := 'XXCMM1_AFF_DEPT_DUMMY_CD';    -- AFFダミー部門コード
-- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
  -- ■ メッセージ・コード（エラー）
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';            -- プロファイル取得エラー
  cv_msg_00010        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';            -- CSVファイル存在チェック
  cv_msg_00031        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00031';            -- 期間指定エラー
  cv_msg_00003        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';            -- ファイルパス不正エラー
-- 2009/05/15 Ver1.4 delete start by Yutaka.Kuboshima
--  cv_msg_00500        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00500';            -- 部門階層エラー
-- 2009/05/15 Ver1.4 delete end by Yutaka.Kuboshima
  cv_msg_00009        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';            -- CSVデータ出力エラー
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';            -- システムエラー
-- 2009/02/26 ADD by M.Sano End
  -- ■ メッセージ・コード（コンカレント・出力）
  cv_msg_00038        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00038';            -- 入力パラメータメッセージ
  cv_msg_05132        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';            -- ファイル名出力メッセージ
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';            -- 対象データ無し
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';            -- 対象件数メッセージ
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';            -- 成功件数メッセージ
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';            -- エラー件数メッセージ
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';            -- 正常終了メッセージ
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';            -- エラー終了全ロールバック
  -- ■ トークン
  cv_tok_ng_profile   CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  cv_tok_ffv_set_name CONSTANT VARCHAR2(15) := 'FFV_SET_NAME';                -- 値セット名
  cv_tok_count        CONSTANT VARCHAR2(10) := 'COUNT';
  cv_tok_ng_word      CONSTANT VARCHAR2(10) := 'NG_WORD';
  cv_tok_ng_data      CONSTANT VARCHAR2(10) := 'NG_DATA';
  cv_tok_param        CONSTANT VARCHAR2(5)  := 'PARAM';
  cv_tok_value        CONSTANT VARCHAR2(5)  := 'VALUE';
  cv_tok_filename     CONSTANT VARCHAR2(10) := 'FILE_NAME';                   -- ファイル名
  -- ■ トークン値
  cv_tvl_out_file_dir CONSTANT VARCHAR2(70) := 'XXCMM:所属マスタ（自販機管理）連携用CSVファイル出力先';
  cv_tvl_out_file_fil CONSTANT VARCHAR2(70) := 'XXCMM:所属マスタ（自販機管理）連携用CSVファイル名';
  cv_tvl_ffv_set_name CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT';
  cv_tvl_dept_code    CONSTANT VARCHAR2(20) := '所属コード'; 
  cv_tvl_update_from  CONSTANT VARCHAR2(20) := '最終更新日(from)';
  cv_tvl_update_to    CONSTANT VARCHAR2(20) := '最終更新日(to)  ';
  cv_tvl_auto_st      CONSTANT VARCHAR2(20) := '[]:自動取得値['; -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動(開始)
  cv_tvl_auto_en      CONSTANT VARCHAR2(1)  := ']';              -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動(終了)
  cv_tvl_para_st      CONSTANT VARCHAR2(1)  := '[';              -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名(開始)
  cv_tvl_para_en      CONSTANT VARCHAR2(1)  := ']';              -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名(終了)
-- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
  cv_tvl_dummy_code   CONSTANT VARCHAR2(50)  := 'AFFダミー部門コード';        -- AFFダミー部門コード
-- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
  -- ■ その他
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_format2     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_datetime_format  CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
-- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
  cv_flag_parent      CONSTANT VARCHAR2(1)   := 'P';                          -- フラグ：P(親)
-- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
-- 2009/05/21 Ver1.5 add start by Yutaka.Kuboshima
  cv_lookup_area      CONSTANT VARCHAR2(30) := 'XXCMN_AREA';                  -- 参照タイプ(地区名)
  cv_y_flag           CONSTANT VARCHAR2(1)  := 'Y';                           -- 有効フラグ(Y)
  cv_language_ja      CONSTANT VARCHAR2(2)  := 'JA';                          -- 言語(JA)
-- 2009/05/21 Ver1.5 add end by Yutaka.Kuboshima
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
  cv_cust_sts_stop    CONSTANT VARCHAR2(2)  := '90';                          -- 顧客ステータス(中止決裁済)
-- 2009/06/05 Ver1.6 add end by Yutaka.Kuboshima
-- 2011/03/23 Ver1.10 add start by Naoki.Horigome
  cv_asterisk         CONSTANT VARCHAR2(2)  := '＊';
-- 2011/03/23 Ver1.10 add end   by Naoki.Horigome
-- 
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 所属マスタIF出力（自販機管理）レイアウト
  TYPE output_data_rtype IS RECORD
  (
     dpt_cd                xxcmm_hierarchy_dept_v.dpt6_cd%TYPE                 -- 部門コード
    ,dpt_name              xxcmm_hierarchy_dept_v.dpt6_name%TYPE               -- 部門名称
    ,dpt_abbreviate        xxcmm_hierarchy_dept_v.dpt6_abbreviate%TYPE         -- 部門略称
-- 2009/10/02 Ver1.9 mod start by Shigeto.Niki
--     ,dpt_sort_num          xxcmm_hierarchy_dept_v.dpt6_sort_num%TYPE           -- 並び順
    ,dpt_div               xxcmm_hierarchy_dept_v.dpt6_div%TYPE                -- 部門区分
--     ,district_cd           xxcmm_hierarchy_dept_v.dpt6_old_cd%TYPE             -- 地区コード
    ,main_base_code        xxcmm_hierarchy_dept_v.dpt6_old_cd%TYPE             -- 最新本部コード
-- 2009/10/02 Ver1.9 mod end by Shigeto.Niki
    ,xhdv_last_update_date xxcmm_hierarchy_dept_v.last_update_date%TYPE        -- 最終更新日
    ,user_div              hz_cust_accounts.attribute8%TYPE                    -- 利用者区分
    ,customer_class_code   hz_cust_accounts.customer_class_code%TYPE           -- 顧客区分
    ,start_date_active     xxcmn_parties.start_date_active%TYPE                -- 適用開始日
    ,end_date_active       xxcmn_parties.end_date_active%TYPE                  -- 適用終了日
    ,party_name            xxcmn_parties.party_name%TYPE                       -- 正式名
    ,party_short_name      xxcmn_parties.party_short_name%TYPE                 -- 略称
    ,party_name_alt        xxcmn_parties.party_name_alt%TYPE                   -- カナ名
    ,address_line1         xxcmn_parties.address_line1%TYPE                    -- 住所１
    ,address_line2         xxcmn_parties.address_line2%TYPE                    -- 住所２
    ,zip                   xxcmn_parties.zip%TYPE                              -- 郵便番号
    ,phone                 xxcmn_parties.phone%TYPE                            -- 電話番号
    ,fax                   xxcmn_parties.fax%TYPE                              -- FAX番号
    ,xpty_last_update_date xxcmn_parties.last_update_date%TYPE                 -- 最終更新日
    ,flex_value_set_id     xxcmm_hierarchy_dept_v.flex_value_set_id%TYPE       -- 値セットID
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
    ,stop_approval_date    xxcmm_cust_accounts.stop_approval_date%TYPE         -- 中止決裁日
    ,customer_status       hz_parties.duns_number_c%TYPE                       -- 顧客ステータス
    ,hp_last_update_date   hz_parties.last_update_date%TYPE                    -- 最終更新日
-- 2009/06/05 Ver1.6 add end by Yutaka.Kuboshima
  );
--
  -- 所属マスタIF出力（自販機管理）レイアウト テーブルタイプ
  TYPE output_data_ttype IS TABLE OF output_data_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_process_date       VARCHAR2(50);     -- 業務日付(フォーマット：YYYY/MM/DD)
-- 2011/03/23 Ver1.10 add start by Naoki.Horigome
  gv_next_proc_date     VARCHAR2(8);      -- 翌業務日付(フォーマット：YYYYMMDD)
-- 2011/03/23 Ver1.10 add end   by Naoki.Horigome
  -- 入力パラメータ
  gv_update_from        VARCHAR2(50);     -- 最終更新日(FROM)
  gv_update_to          VARCHAR2(50);     -- 最終更新日(TO)
  -- 処理用
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;  -- CSVファイル出力先
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;  -- CSVファイル名
-- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
  gv_aff_dept_dummy_cd  fnd_profile_option_values.profile_option_value%TYPE;  -- AFFダミー部門コード
-- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
  gf_file_handler       UTL_FILE.FILE_TYPE;                                   -- CSVファイル出力用ハンドラ
  gt_out_tab            output_data_ttype;                                    -- 所属マスタIF出力データ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lb_file_exists   BOOLEAN;        -- ファイル存在判断
    ln_file_length   NUMBER(30);     -- ファイルの文字列数
    lbi_block_size   BINARY_INTEGER; -- ブロックサイズ
    lv_update_from   VARCHAR2(10);   -- チェック用最終更新日(From)
    lv_update_to     VARCHAR2(10);   -- チェック用最終更新日(To)
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
    --１．プロファイルの取得を行います。
    --==============================================================
    -- XXCMM: 所属マスタIF出力（自販機管理）連携用CSVファイル出力先を取得
    gv_csv_file_dir    := FND_PROFILE.VALUE(cv_pro_out_file_dir);
    -- XXCMM: 所属マスタIF出力（自販機管理）連携用CSVファイル出力先の取得内容チェック
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_dir  -- 値      :CSVファイル出力先
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCMM: 所属マスタIF出力（自販機管理）連携用CSVファイル名を取得
    gv_csv_file_name    := FND_PROFILE.VALUE(cv_pro_out_file_fil);
    -- XXCMM: 所属マスタIF出力（自販機管理）連携用CSVファイル名の取得内容チェック
    IF ( gv_csv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_fil  -- 値      :CSVファイル名
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
    -- XXCMM:AFFダミー部門コードを取得
    gv_aff_dept_dummy_cd := FND_PROFILE.VALUE(cv_aff_dept_dummy_cd);
    -- XXCMM:AFFダミー部門コードの取得内容チェック
    IF ( gv_aff_dept_dummy_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_dummy_code    -- 値      :AFFダミー部門コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
    --==============================================================
    --２．CSVファイル存在チェックを行います。
    --==============================================================
    -- ファイル情報を取得
    UTL_FILE.FGETATTR(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- ファイル重複チェック(ファイル存在の有無)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00010         -- エラー:CSVファイル存在チェック
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --３．業務日付を取得します。
    --==============================================================
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_date_format);
--
-- 2011/03/23 Ver1.10 add start by Naoki.Horigome
    --==============================================================
    --４．翌業務日付を取得します。
    --==============================================================
    gv_next_proc_date := TO_CHAR(xxccp_common_pkg2.get_process_date + 1, cv_date_format2);
-- 2011/03/23 Ver1.10 add end   by Naoki.Horigome
--
    --==============================================================
    --５．パラメータチェックを行います。
    --==============================================================
    -- "最終更新日(From) > 最終更新日(To)"の場合、パラメータエラー
    lv_update_from := NVL(gv_update_from, gv_process_date);
    lv_update_to   := NVL(gv_update_to,   gv_process_date);
    IF ( lv_update_from > lv_update_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00031         -- エラー:期間指定エラー
                   );
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_file
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- プログラム名
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- ファイルオープンモード(書き込みモード)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- オープンモード'W'(出力)でオープンします。
    -- ===============================================
    BEGIN
      -- ファイルを開く
      gf_file_handler := UTL_FILE.FOPEN(
                            location   => gv_csv_file_dir     -- 出力先
                           ,filename   => gv_csv_file_name    -- ファイル名
                           ,open_mode  => cv_csv_mode_w       -- ファイルオープンモード
                        );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        -- メッセージを取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm  -- マスタ
                       ,iv_name         => cv_msg_00003       -- エラー:ファイルパス不正エラー
                     );
        lv_errbuf := lv_errmsg;
        -- 例外をスロー
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
-- 2009/05/15 Ver1.4 delete start by Yutaka.Kuboshima
  /**********************************************************************************
   * Procedure Name   : chk_count_top_dept
   * Description      : 最上位部門件数取得(A-3)
   ***********************************************************************************/
--  PROCEDURE chk_count_top_dept(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_count_top_dept'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル変数 ***
--    ln_top_dept_cnt NUMBER;
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    --==============================================================
--    -- 1.最上位部門の件数を取得します。
--    --==============================================================
--    BEGIN
--      SELECT COUNT(1)
--      INTO   ln_top_dept_cnt
--      FROM   fnd_flex_value_sets ffvs  -- 値セット定義マスタ
--            ,fnd_flex_values     ffvl  -- 値セット値定義マスタ
--      WHERE  ffvs.flex_value_set_id = ffvl.flex_value_set_id
--      AND    ffvl.enabled_flag = 'Y'
--      AND    ffvl.summary_flag = 'Y'
--      AND    ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
--      AND    xxccp_common_pkg2.get_process_date BETWEEN
--                   NVL(ffvl.start_date_active, TO_DATE('19000101','YYYYMMDD'))
--               AND NVL(ffvl.end_date_active, TO_DATE('99991231','YYYYMMDD'))
---- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
--      AND    ffvl.flex_value <> gv_aff_dept_dummy_cd
---- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
--      AND    NOT EXISTS (
--               SELECT 'X'
--               FROM   fnd_flex_value_norm_hierarchy ffvh
--               WHERE  ffvh.flex_value_set_id = ffvl.flex_value_set_id
--               AND    ffvl.flex_value BETWEEN ffvh.child_flex_value_low
--                                          AND ffvh.child_flex_value_high
---- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
--               AND    ffvh.range_attribute   = cv_flag_parent
--             )
--      AND    EXISTS (
--               SELECT 'X'
--               FROM   fnd_flex_value_norm_hierarchy ffvh2
--               WHERE  ffvh2.flex_value_set_id = ffvl.flex_value_set_id
--               AND    ffvh2.parent_flex_value = ffvl.flex_value
--               AND    ffvh2.range_attribute   = cv_flag_parent
--             )
---- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
----
--    --==============================================================
--    -- 2．最上位部門件数が1件以外の場合、部門階層エラー
--    --==============================================================
--    IF ( ln_top_dept_cnt <> 1 ) THEN
--      -- エラーメッセージを出力後、異常終了
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm        -- マスタ
--                     ,iv_name         => cv_msg_00500             -- エラー:部門階層エラー
--                     ,iv_token_name1  => cv_tok_ffv_set_name      -- トークン  :FFV_SET_NAME
--                     ,iv_token_value1 => cv_tvl_ffv_set_name      -- トークン値:XX03_DEPARTMENT
--                     ,iv_token_name2  => cv_tok_count             -- トークン  :COUNT
--                     ,iv_token_value2 => TO_CHAR(ln_top_dept_cnt) -- トークン値:最上位階層の件数
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
---- 2009/02/26 ADD by M.Sano Start
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxccp    -- マスタ
--                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
--                   );
---- 2009/02/26 ADD by M.Sano End
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
---- 2009/02/26 ADD by M.Sano Start
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxccp    -- マスタ
--                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
--                   );
---- 2009/02/26 ADD by M.Sano End
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END chk_count_top_dept;
--
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
  /**********************************************************************************
   * Procedure Name   : get_output_data
   * Description      : 処理対象データ抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_output_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_output_data'; -- プログラム名
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
    cv_time_min    VARCHAR2(10) := ' 00:00:00';
    cv_time_max    VARCHAR2(10) := ' 23:59:59';
    
    -- *** ローカル変数 ***
    ld_update_from DATE;
    ld_update_to   DATE;
--
    -- *** ローカルカーソル***
    CURSOR output_data_cur(
       id_last_update_date_from DATE
      ,id_last_update_date_to   DATE)
    IS
      SELECT xhdv.dpt6_cd                  dpt_cd                 -- 部門コード
            ,xhdv.dpt6_name                dpt_name               -- 部門名称
            ,xhdv.dpt6_abbreviate          dpt_abbreviate         -- 部門略称
-- 2009/10/02 Ver1.9 mod start by Shigeto.Niki
--             ,xhdv.dpt6_sort_num            dpt_sort_num           -- 並び順
            ,xhdv.dpt6_div                 dpt_div                -- 部門区分
--             ,xhdv.dpt6_old_cd              district_cd            -- 地区コード
               -- 最新本部コードを取得
            ,  CASE
                 WHEN (xhdv.dpt6_start_date_active IS NULL) THEN xhdv.dpt6_old_cd  --新本部コード
                 WHEN (xhdv.dpt6_start_date_active <= TO_CHAR(id_last_update_date_to + 1, cv_date_format2 ) )
                                                            THEN xhdv.dpt6_new_cd  --新本部コード
                 ELSE                                            xhdv.dpt6_old_cd  --旧本部コード
               END                                           AS  main_base_code    --最新本部コード
-- 2009/10/02 Ver1.9 mod end by Shigeto.Niki            
            ,xhdv.last_update_date         xhdv_last_update_date  -- 最終更新日
            ,hzac.attribute8               user_div               -- 利用者区分
            ,hzac.customer_class_code      customer_class_code    -- 顧客区分
            ,xpty.start_date_active        start_date_active      -- 適用開始日
            ,xpty.end_date_active          end_date_active        -- 適用終了日
            ,xpty.party_name               party_name             -- 正式名
            ,xpty.party_short_name         party_short_name       -- 略称
            ,xpty.party_name_alt           party_name_alt         -- カナ名
            ,xpty.address_line1            address_line1          -- 住所１
            ,xpty.address_line2            address_line2          -- 住所２
            ,xpty.zip                      zip                    -- 郵便番号
            ,xpty.phone                    phone                  -- 電話番号
            ,xpty.fax                      fax                    -- FAX番号
            ,xpty.last_update_date         xpty_last_update_date  -- 最終更新日
            ,xhdv.flex_value_set_id        flex_value_set_id      -- 値セットID
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
            ,xca.stop_approval_date        stop_approval_date     -- 中止決裁日
            ,hp.duns_number_c              customer_status        -- 顧客ステータス
            ,hp.last_update_date           hp_last_update_date    -- 最終更新日
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
--
-- 2009/09/02 Ver1.8 modify start by Yutaka.Kuboshima
--      FROM   xxcmm_hierarchy_dept_v   xhdv  -- (TABLE)部門階層ビュー
      FROM   xxcmm_hierarchy_dept_all_v xhdv  -- (TABLE)全部門階層ビュー
-- 2009/09/02 Ver1.8 modify end by Yutaka.Kuboshima
--
            ,hz_cust_accounts         hzac  -- (TABLE)顧客マスタ
            ,xxcmn_parties            xpty  -- (TABLE)パーティアドオンマスタ
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
            ,xxcmm_cust_accounts      xca   -- (TABLE)顧客追加情報マスタ
            ,hz_parties               hp    -- (TABLE)パーティマスタ
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
      WHERE  xhdv.dpt6_cd             = hzac.account_number
      AND    hzac.customer_class_code = '1' -- 抽出対象：拠点
      AND    hzac.party_id            = xpty.party_id
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
      AND    hzac.party_id            = hp.party_id
      AND    hzac.cust_account_id     = xca.customer_id
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
-- 2009/06/05 Ver1.6 delete start by Yutaka.Kuboshima
--      AND    xpty.start_date_active BETWEEN id_last_update_date_from
--                                        AND id_last_update_date_to
-- 2009/06/05 Ver1.6 delete end by Yutaka.Kuboshima
      AND    (  ( xhdv.last_update_date BETWEEN id_last_update_date_from
                                            AND id_last_update_date_to  )
             OR ( xpty.last_update_date BETWEEN id_last_update_date_from 
                                            AND id_last_update_date_to  )
-- 2009/10/02 Ver1.9 add start by Shigeto.Niki
             OR ( xhdv.dpt6_start_date_active BETWEEN TO_CHAR(id_last_update_date_from + 1, cv_date_format2 ) 
                                                  AND TO_CHAR(id_last_update_date_to + 1, cv_date_format2 ) ) 
-- 2009/10/02 Ver1.9 add end by Shigeto.Niki
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
             OR (  hp.last_update_date  BETWEEN id_last_update_date_from
                                            AND id_last_update_date_to
               AND hp.duns_number_c = cv_cust_sts_stop ) )
-- 2009/06/05 Ver1.6 add end by Yutaka.Kuboshima
-- 2009/06/09 Ver1.7 add start by Yutaka.Kuboshima
      AND    xpty.start_date_active = (SELECT MAX(xpv.start_date_active)
                                       FROM xxcmn_parties xpv
                                       WHERE xpv.party_id = xpty.party_id)
-- 2009/06/09 Ver1.7 add end by Yutaka.Kuboshima
      ORDER BY
             xhdv.dpt6_cd ASC
      ;
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
    -- 検索条件に挿入する日時を作成する。
    --==============================================================
    -- 最終更新日(From)を作成(YYYY/MM/DD 00:00:00)
    ld_update_from := TO_DATE(NVL(gv_update_from, gv_process_date) || cv_time_min, cv_datetime_format);
    -- 最終更新日(To)を作成  (YYYY/MM/DD 23:59:59)
    ld_update_to   := TO_DATE(NVL(gv_update_to, gv_process_date)   || cv_time_max, cv_datetime_format);
--
    --==============================================================
    -- 所属マスタIF情報を取得し、結果を配列に格納します。
    --==============================================================
    -- CSV出力データ取得カーソルのオープン
    OPEN output_data_cur(ld_update_from, ld_update_to);
    -- CSV出力データ取得の取得
    <<output_data_loop>>
    LOOP
      FETCH output_data_cur BULK COLLECT INTO gt_out_tab;
      EXIT WHEN output_data_cur%NOTFOUND;
    END LOOP output_data_loop;
    -- CSV出力データ取得カーソルのクローズ
    CLOSE output_data_cur;
    -- 件数を取得
    gn_target_cnt := gt_out_tab.COUNT;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_output_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : 抽出情報出力(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_data'; -- プログラム名
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
    -- 文字
    cv_sep                  CONSTANT VARCHAR2(1)   := ',';          -- 区切り文字
    cv_dqu                  CONSTANT VARCHAR2(1)   := '"';          -- ダブルクォーテーション
    cv_hyphen               CONSTANT VARCHAR2(1)   := '-';          -- ハイフン
    -- デフォルト文字数
    cv_def_phone_len        CONSTANT NUMBER        := 6; 
    -- 項目
    cv_term_code            CONSTANT VARCHAR2(4)   := '0000';       -- チームコード
    cv_stop_using_flg       CONSTANT VARCHAR2(1)   := '0';          -- 利用停止フラグ
    cv_create_prep_code     CONSTANT VARCHAR2(5)   := '99999';      -- 作成担当者コード
    cv_create_dept          CONSTANT VARCHAR2(6)   := '999999';     -- 作成部署
    cv_create_prog_id       CONSTANT VARCHAR2(10)  := 'BUKKEN_2UD'; -- 作成プログラムID
    cv_update_prep_code     CONSTANT VARCHAR2(5)   := '99999';      -- 更新担当者コード
    cv_update_dept          CONSTANT VARCHAR2(6)   := '999999';     -- 更新部署
    cv_update_prog_id       CONSTANT VARCHAR2(10)  := 'BUKKEN_2UD'; -- 更新プログラムID
    -- フォーマット
-- 2009/04/20 Ver1.3 modify start by Yutaka.Kuboshima
--    cv_last_update_fmt      CONSTANT VARCHAR2(10)  := 'DDHH24MISS'; -- 最終更新日時時分秒フォーマット
    cv_last_update_fmt      CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS'; -- 最終更新日時年月日時分秒フォーマット
-- 2009/04/20 Ver1.3 modify start by Yutaka.Kuboshima
    -- *** ローカル変数 ***
    lv_outline              VARCHAR2(2400);                         -- 出力内容(行)
    ln_idx                  NUMBER;
    -- 一時変数
    ln_phone_st             NUMBER; -- 抽出する電話番号の開始位置
    ln_phone_len            NUMBER; -- 抽出する電話番号の文字数
    ln_hyphen_idx           NUMBER; -- 次ハイフンの位置
    -- 項目
    lv_dept_code            VARCHAR2(4);                -- 所属コード
    lv_address_line         VARCHAR2(60);               -- 所属住所
    lv_phone_1              xxcmn_parties.phone%TYPE;   -- 電話番号1
    lv_phone_2              xxcmn_parties.phone%TYPE;   -- 電話番号2
    lv_phone_3              xxcmn_parties.phone%TYPE;   -- 電話番号3
    lv_district_code        VARCHAR2(6);                -- 地区コード
    lv_district_name        VARCHAR2(16);               -- 地区名称
-- 2009/04/20 Ver1.3 modify start by Yutaka.Kuboshima
--    lv_last_update_date     VARCHAR2(8);                -- 最終更新日時時分秒
    lv_last_update_date     VARCHAR2(14);                -- 最終更新日時年月日時分秒時分秒
-- 2009/04/20 Ver1.3 modify start by Yutaka.Kuboshima
--
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
    lv_end_date_active      VARCHAR2(8);
-- 2009/06/05 Ver1.6 add end by Yutaka.Kuboshima
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
    -- 取得した所属マスタIFの情報を、CSVファイルへ出力
    --==============================================================
    <<output_csv_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      -- ■ 所属コードを取得
      lv_dept_code := SUBSTRB(gt_out_tab(ln_idx).dpt_cd, 1, 4);
--
      -- ■ 所属住所を取得
      lv_address_line := SUBSTRB(gt_out_tab(ln_idx).address_line1 || gt_out_tab(ln_idx).address_line2, 1, 60);
--
      -- ■ 市外局番を取得
      IF ( gt_out_tab(ln_idx).phone IS NULL ) THEN
        lv_phone_1    := NULL;
      ELSE
        -- 抽出開始位置を算出
        ln_phone_st   := 1;
        -- "-"の位置を取得
        ln_hyphen_idx := INSTRB(gt_out_tab(ln_idx).phone, cv_hyphen, ln_phone_st, 1);
        -- パーティアドオンの電話番号の市外局番を取得
        -- ･"-"が見つかった   ⇒ 開始位置0"-"の位置までを抽出
        -- ･"-"が見つからない ⇒ 6文字固定
        IF ( ln_hyphen_idx > 0 ) THEN
          ln_phone_len := ln_hyphen_idx; 
          lv_phone_1   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, ln_phone_len); 
        ELSE
          lv_phone_1   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, cv_def_phone_len);
        END IF;
      END IF;
--
      -- ■ 市内局番を取得
      IF ( lv_phone_1 IS NULL ) THEN
        lv_phone_2    := NULL;
      ELSE
        -- 抽出開始位置を算出
        ln_phone_st   := ln_phone_st + LENGTHB(lv_phone_1);
        -- "-"の位置を取得(市外局番の次文字以降)
        ln_hyphen_idx := INSTRB(gt_out_tab(ln_idx).phone, cv_hyphen, ln_phone_st, 1);
        -- パーティアドオンの電話番号の市内局番を取得
        -- ･"-"が見つかった   ⇒ 市外局番の次文字0"-"の位置
        -- ･"-"が見つからない ⇒ 6文字固定
        IF ( ln_hyphen_idx > 0 ) THEN
          ln_phone_len := ln_hyphen_idx - ln_phone_st + 1; 
          lv_phone_2   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, ln_phone_len);
        ELSE
          lv_phone_2   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, cv_def_phone_len);
        END IF;
      END IF;
--
      -- ■ 加入者番号を取得
      IF ( lv_phone_2 IS NULL ) THEN
        lv_phone_3   := NULL;
      ELSE
        -- 抽出開始位置を算出
        ln_phone_st  := ln_phone_st + LENGTHB(lv_phone_2);
        -- パーティアドオンの電話番号の加入者番号を取得(市内局番の次文字0末端)
        ln_phone_len := LENGTHB(gt_out_tab(ln_idx).phone) - ln_phone_st + 1;
        lv_phone_3   := SUBSTRB(gt_out_tab(ln_idx).phone, ln_phone_st, ln_phone_len);
      END IF;
--
      -- ■ 地区名称を取得
-- 2009/10/13 Ver1.9 mod start by Shigeto.Niki
--        IF ( gt_out_tab(ln_idx).district_cd IS NOT NULL ) THEN
        IF ( gt_out_tab(ln_idx).main_base_code IS NOT NULL ) THEN
-- 2009/10/13 Ver1.9 mod end by Shigeto.Niki
        BEGIN
-- 2009/05/21 Ver1.5 modify start by Yutaka.Kuboshima
--          SELECT SUBSTRB(ffvl.attribute4, 1, 16)
--          INTO   lv_district_name
--          FROM   fnd_flex_values   ffvl
--          WHERE  ffvl.flex_value_set_id = gt_out_tab(ln_idx).flex_value_set_id
--          AND    ffvl.flex_value        = gt_out_tab(ln_idx).district_cd
-- 2011/03/23 Ver1.10 mod start by Naoki.Horigome
--        SELECT SUBSTRB(flv.meaning, 1, 16)
        SELECT NVL(SUBSTRB(flv.meaning, 1, 16), cv_asterisk)
-- 2011/03/23 Ver1.10 mod end   by Naoki.Horigome
        INTO lv_district_name
        FROM fnd_lookup_values flv
        WHERE flv.lookup_type  = cv_lookup_area
          AND flv.enabled_flag = cv_y_flag
          AND flv.language     = cv_language_ja
-- 2009/10/13 Ver1.9 mod start by Shigeto.Niki
--          AND flv.lookup_code  = gt_out_tab(ln_idx).district_cd
          AND flv.lookup_code  = SUBSTRB(gt_out_tab(ln_idx).main_base_code, 1 ,4)
-- 2009/10/13 Ver1.9 mod end by Shigeto.Niki
          ;
-- 2009/05/21 Ver1.5 modify end by Yutaka.Kuboshima
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
-- 2011/03/23 Ver1.10 mod start by Naoki.Horigome
--            lv_district_name := '';
            lv_district_name := cv_asterisk;
-- 2011/03/23 Ver1.10 mod end   by Naoki.Horigome
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      ELSE
-- 2011/03/23 Ver1.10 mod start by Naoki.Horigome
--        lv_district_name := '';
        lv_district_name := cv_asterisk;
-- 2011/03/23 Ver1.10 mod end   by Naoki.Horigome
      END IF;
--
      -- ■ 最終更新日時時分秒を取得
      IF ( gt_out_tab(ln_idx).xhdv_last_update_date > gt_out_tab(ln_idx).xpty_last_update_date ) THEN
-- 2009/06/05 Ver1.6 modify start by Yutaka.Kuboshima
--        lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).xhdv_last_update_date, cv_last_update_fmt);
        IF ( gt_out_tab(ln_idx).xhdv_last_update_date > gt_out_tab(ln_idx).hp_last_update_date ) THEN
          lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).xhdv_last_update_date, cv_last_update_fmt);
        ELSE
          lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).hp_last_update_date, cv_last_update_fmt);
        END IF;
-- 2009/06/05 Ver1.6 modify end by Yutaka.Kuboshima
      ELSE
-- 2009/06/05 Ver1.6 modify start by Yutaka.Kuboshima
--        lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).xpty_last_update_date, cv_last_update_fmt);
        IF ( gt_out_tab(ln_idx).xpty_last_update_date > gt_out_tab(ln_idx).hp_last_update_date ) THEN
          lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).xpty_last_update_date, cv_last_update_fmt);
        ELSE
          lv_last_update_date := TO_CHAR(gt_out_tab(ln_idx).hp_last_update_date, cv_last_update_fmt);
        END IF;
-- 2009/06/05 Ver1.6 modify end by Yutaka.Kuboshima
      END IF;
--
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
      -- ■ 適用終了日を取得
      IF ( gt_out_tab(ln_idx).customer_status = cv_cust_sts_stop ) THEN
        lv_end_date_active := TO_CHAR(gt_out_tab(ln_idx).stop_approval_date, cv_date_format2);
      ELSE
        lv_end_date_active := TO_CHAR(gt_out_tab(ln_idx).end_date_active, cv_date_format2);
      END IF;
-- 2009/06/05 Ver1.6 add start by Yutaka.Kuboshima
--
      -- ■ 出力データ作成
      -- 1.利用者区分
      lv_outline := cv_dqu || SUBSTRB(gt_out_tab(ln_idx).user_div, 1, 2) || cv_dqu;
      -- 2.所属コード
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_dept_code || cv_dqu;
      -- 3.チームコード
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_term_code  || cv_dqu;
      -- 4.適用開始日
-- 2011/03/23 Ver1.10 mod start by Naoki.Horigome
--      lv_outline := lv_outline || cv_sep || TO_CHAR(gt_out_tab(ln_idx).start_date_active, cv_date_format2);
      lv_outline := lv_outline || cv_sep || gv_next_proc_date;
-- 2011/03/23 Ver1.10 mod end   by Naoki.Horigome
      -- 5.適用終了日
-- 2009/06/05 Ver1.6 modify start by Yutaka.Kuboshima
--      lv_outline := lv_outline || cv_sep || TO_CHAR(gt_out_tab(ln_idx).end_date_active, cv_date_format2);
      lv_outline := lv_outline || cv_sep || lv_end_date_active;
-- 2009/06/05 Ver1.6 modify end by Yutaka.Kuboshima
      -- 6.所属名（正式名）
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).party_name, 1, 40) || cv_dqu;
      -- 7.所属名（略称）
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).party_short_name, 1, 20) || cv_dqu;
      -- 8.所属名（カナ）
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).party_name_alt, 1, 20) || cv_dqu;
      -- 9.チーム名（正式名）
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 10.チーム名（略称）
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 11.作業担当者コード１
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 12.作業担当者コード２
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 13.所属住所
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_address_line || cv_dqu;
      -- 14.郵便番号
-- 2009/04/20 Ver1.3 modify start by Yutaka.Kuboshima
--      lv_outline := lv_outline || cv_sep || SUBSTRB(gt_out_tab(ln_idx).zip, 1, 20);
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).zip, 1, 7) || cv_dqu;
-- 2009/04/20 Ver1.3 modify end by Yutaka.Kuboshima
      -- 15.電話番号１
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_phone_1 || cv_dqu;
      -- 16.電話番号２
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_phone_2 || cv_dqu;
      -- 17.電話番号３
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_phone_3 || cv_dqu;
      -- 18.ＦＡＸ番号
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).fax, 1, 15) || cv_dqu;
-- 2009/10/13 Ver1.9 mod start by Shigeto.Niki
      -- 19.地区コード
--       lv_outline := lv_outline || cv_sep || cv_dqu || lv_district_code || cv_dqu;
      lv_outline := lv_outline || cv_sep || cv_dqu || SUBSTRB(gt_out_tab(ln_idx).main_base_code, 1 ,6) || cv_dqu;
-- 2009/10/13 Ver1.9 mod end by Shigeto.Niki
      -- 20.地区名称
      lv_outline := lv_outline || cv_sep || cv_dqu || lv_district_name || cv_dqu;
      -- 21.申請先コード
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 22.依頼先利用者区分
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 23.依頼先所属コード
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_dqu;
      -- 24.利用停止フラグ
      lv_outline := lv_outline || cv_sep || cv_stop_using_flg;
      -- 25.作成担当者コード
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_create_prep_code || cv_dqu;
      -- 26.作成部署
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_create_dept || cv_dqu;
      -- 27.作成プログラムＩＤ
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_create_prog_id || cv_dqu;
      -- 28.更新担当者コード
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_update_prep_code || cv_dqu;
      -- 29.更新部署コード
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_update_dept || cv_dqu;
      -- 30.更新プログラムＩＤ
      lv_outline := lv_outline || cv_sep || cv_dqu || cv_update_prog_id || cv_dqu;
      -- 31.作成日時時分秒
      lv_outline := lv_outline || cv_sep;
      -- 32.更新日時時分秒
      lv_outline := lv_outline || cv_sep || lv_last_update_date;
--
      -- ■ 出力データをcsvファイルに出力する。
      BEGIN
        UTL_FILE.PUT_LINE(gf_file_handler, lv_outline);
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm    -- マスタ
                         ,iv_name         => cv_msg_00009         -- エラー  :CSVデータ出力エラー
                         ,iv_token_name1  => cv_tok_ng_word       -- トークン:NG_WORD
                         ,iv_token_value1 => cv_tvl_dept_code     -- 値      :所属コード
                         ,iv_token_name2  => cv_tok_ng_data       -- トークン:NG_DATA
                         ,iv_token_value2 => lv_dept_code         -- 値      :所属コード(データ)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      --■ 成功件数を更新する。
      gn_normal_cnt := gn_normal_cnt + 1;
   END LOOP output_csv_loop;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- ファイルオープンモード(書き込みモード)
--
    -- *** ローカル変数 ***
    lv_tvl_para        VARCHAR2(100);  -- トークンに格納する値
    lv_out_msg          VARCHAR2(5000); -- 出力用
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
    -- ===============================================
    -- A-1.初期処理
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 入力パラメータ(最終更新日(From))の出力メッセージを取得
    -- ・最終更新日(From)がNULL以外 ⇒ 最終更新日（From） ： [YYYY/MM/DD]
    IF ( gv_update_from IS NOT NULL ) THEN
      lv_tvl_para := cv_tvl_para_st || gv_update_from || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    -- ・最終更新日(From)がNULL     ⇒ 最終更新日（From） ： [] : 自動取得[YYYY/MM/DD]
    ELSE
      lv_tvl_para := cv_tvl_auto_st || gv_process_date || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- 入力パラメータ(最終更新日(From))をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 入力パラメータ(最終更新日(To))の出力メッセージを取得
    -- ・最終更新日(To)がNULL以外 ⇒ 最終更新日（To） ： [YYYY/MM/DD]
    IF ( gv_update_to IS NOT NULL ) THEN
      lv_tvl_para := cv_tvl_para_st || gv_update_to || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    -- ・最終更新日(To)がNULL     ⇒ 最終更新日（To） ： [] : 自動取得[YYYY/MM/DD]
    ELSE
      lv_tvl_para := cv_tvl_auto_st || gv_process_date || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- 入力パラメータ(最終更新日(To))をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ファイル名の出力メッセージを取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_05132
                    ,iv_token_name1  => cv_tok_filename
                    ,iv_token_value1 => gv_csv_file_name
                   );
    -- ファイル名をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 初期処理の実行結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2．ファイルオープン処理(書込モード)
    -- ===============================================
    open_csv_file(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3．最上位部門件数取得
    -- ===============================================
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
--    chk_count_top_dept(
--       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
--      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
--      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
--    );
--    -- 処理結果チェック
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      -- (例外をスロー)
--      RAISE global_process_expt;
--    END IF;
--
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
    -- ===============================================
    -- A-4．処理対象データ抽出
    -- ===============================================
    get_output_data(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- (例外をスロー)
      RAISE global_process_expt;
    END IF;
    -- 0件の場合、メッセージ出力後、処理終了
    IF ( gn_target_cnt = 0 ) THEN
      -- (コンカレント・出力とログへメッセージ出力)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00001         -- エラー  :対象データなし
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- (例外をスロー)
      RAISE no_output_data_expt;
    END IF;
--
    -- ===============================================
    -- A-5．抽出情報出力
    -- ===============================================
    output_csv_data(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー件数を更新する。
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- (例外をスロー)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象データ無し例外ハンドラ ***
    WHEN no_output_data_expt THEN
      ov_retcode := cv_status_normal;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
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
    errbuf                OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,        --   エラーコード     #固定#
    iv_update_from        IN     VARCHAR2,        --   1.最終更新日(FROM)
    iv_update_to          IN     VARCHAR2)        --   2.最終更新日(TO)
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);     -- リターン・コード
    lv_errmsg           VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code     VARCHAR2(100);   -- 終了メッセージコード
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
    -- 入力パラメータの取得
    -- ===============================================
    gv_update_from := iv_update_from;
    gv_update_to   := iv_update_to;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf           => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- A-6．終了処理
    -- ===============================================
    BEGIN
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        lv_retcode := cv_status_error;
    END;
--
    -- ===============================================
    -- エラーメッセージの出力
    -- ===============================================
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
      -- エラー発生時でデータが未取得の場合、各件数は以下に統一して出力する
      IF ( gn_target_cnt = 0 ) THEN
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
      END IF;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- 件数の出力
    -- ===============================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================================
    --終了メッセージ
    -- ===============================================
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
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
END XXCMM005A04C;
/
