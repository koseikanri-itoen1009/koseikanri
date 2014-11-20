CREATE OR REPLACE PACKAGE BODY XXCMM007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM007A01C(body)
 * Description      : 顧客の標準画面よりメンテナンスされた名称・住所情報を、
 *                  : パーティアドオンマスタへ反映し、内容の同期を行います。
 * MD.050           : 生産顧客情報同期 MD050_CMM_005_A04
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_parties_data       処理対象データ抽出(A-2)
 *  chk_linkage_item       連携項目チェック(A-3)
 *  upd_xxcmn_parties      パーティアドオン更新(A-4)
 *  ins_xxcmn_parties      パーティアドオン登録(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/18    1.0   Masayuki.Sano    新規作成
 *  2009/02/26    1.1   Masayuki.Sano    結合テスト動作不正対応
 *  2010/02/15    1.2   Yutaka.Kuboshima 障害E_本稼動_01419 差分テーブルにパーティサイトアドオンを追加
 *                                                          パーティアドオンの初期値を変更
 *  2010/02/18    1.3   Yutaka.Kuboshima 障害E_本稼動_01419 PT対応
 *  2010/02/23    1.4   Yutaka.Kuboshima 障害E_本稼動_01419 連携項目チェックエラー時でも正常終了するよう修正
 *  2010/05/28    1.5   Shigeto.Niki     障害E_本稼動_02876 顧客名称または住所情報が変更された場合に更新するよう修正
 *                                                          営業組織IDを修正
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
  no_output_data_expt       EXCEPTION;  -- 対象データ無し例外
  size_over_expt            EXCEPTION;  -- 生産連携項目サイズオーバー例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCMM007A01C';  -- パッケージ名
  -- ■ アプリケーション短縮名
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30) := 'XXCMM';      -- マスタ
  cv_app_name_xxccp   CONSTANT VARCHAR2(30) := 'XXCCP';      -- 共通・IF
  -- ■ カスタム・プロファイル・オプション
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--  cv_pro_init01       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT01';
--                                 -- XXCMN:パーティアドオンマスタ登録画面_引当順初期値
--  cv_pro_init03       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT03';
--                                 -- XXCMN:パーティアドオンマスタ登録画面_振替グループ初期値
--  cv_pro_init04       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT04';
--                                 -- XXCMN:パーティアドオンマスタ登録画面_物流ブロック初期値
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
  cv_pro_init05       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT05';
                                 -- XXCMN:パーティアドオンマスタ登録画面_拠点大分類初期値
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--  cv_pro_init06       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT16';
--                                 -- XXCMN:パーティアドオンマスタ登録画面_ドリンク運賃振替基準初期値
--  cv_pro_init07       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT17';
--                                 -- XXCMN:パーティアドオンマスタ登録画面_リーフ運賃振替基準初期値 
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
  cv_pro_sys_ctrl_cal CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';
                                 -- システム稼動日カレンダコード定義プロファイル
  -- ■ メッセージ・コード（エラー/警告）
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_msg_00031        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00305';  -- 期間指定エラー
  cv_msg_00015        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00015';  -- 組織ID取得エラー
  cv_msg_00008        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00008';  -- ロックエラーメッセージ
  cv_msg_00702        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00702';  -- 生産連携項目サイズ警告メッセージ
  cv_msg_00700        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00700';  -- パーティアドオン更新エラーメッセージ
  cv_msg_00701        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00701';  -- パーティアドオン登録エラーメッセージ
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';  -- システムエラー
-- 2009/02/26 ADD by M.Sano End
  -- ■ メッセージ・コード（コンカレント・出力）
  cv_msg_00038        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00038';  -- 入力パラメータメッセージ
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- 対象データ無し
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_warn_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  -- ■ トークン
  cv_tok_ng_profile   CONSTANT VARCHAR2(20) := 'NG_PROFILE';    -- プロファイル名
  cv_tok_ng_ou_name   CONSTANT VARCHAR2(20) := 'NG_OU_NAME';    -- 組織定義名
  cv_tok_ng_table     CONSTANT VARCHAR2(20) := 'NG_TABLE';      -- エラーテーブル名
  cv_tok_cust_cd      CONSTANT VARCHAR2(20) := 'CUST_CD';       -- 顧客コード
  cv_tok_party_id     CONSTANT VARCHAR2(20) := 'PARTY_ID';      -- パーティID
  cv_tok_col_name     CONSTANT VARCHAR2(20) := 'COL_NAME';      -- カラム名称
  cv_tok_col_size     CONSTANT VARCHAR2(20) := 'COL_SIZE';      -- カラム桁数
  cv_tok_data_size    CONSTANT VARCHAR2(20) := 'DATA_SIZE';     -- 取得データのサイズ
  cv_tok_data_val     CONSTANT VARCHAR2(20) := 'DATA_VAL';      -- 取得テータの値内容
  cv_tok_count        CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tok_param        CONSTANT VARCHAR2(20) := 'PARAM';
  cv_tok_value        CONSTANT VARCHAR2(20) := 'VALUE';
  -- ■ トークン値
  cv_tvl_sys_ctrl_cal CONSTANT VARCHAR2(80) := 'XXCMM:顧客アドオン機能用システム稼働日カレンダコード値';
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--  cv_tvl_pro_init01   CONSTANT VARCHAR2(80) := 'XXCMN:パーティアドオンマスタ登録画面_引当順初期値';
--  cv_tvl_pro_init03   CONSTANT VARCHAR2(80) := 'XXCMN:パーティアドオンマスタ登録画面_振替グループ初期値';
--  cv_tvl_pro_init04   CONSTANT VARCHAR2(80) := 'XXCMN:パーティアドオンマスタ登録画面_物流ブロック初期値';
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
  cv_tvl_pro_init05   CONSTANT VARCHAR2(80) := 'XXCMN:パーティアドオンマスタ登録画面_拠点大分類初期値';
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--  cv_tvl_pro_init06   CONSTANT VARCHAR2(80) := 'XXCMN:パーティアドオンマスタ登録画面_ドリンク運賃振替基準初期値';
--  cv_tvl_pro_init07   CONSTANT VARCHAR2(80) := 'XXCMN:パーティアドオンマスタ登録画面_リーフ運賃振替基準初期値';
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
  cv_tvl_sales_ou     CONSTANT VARCHAR2(20) := 'SALES-OU';
  cv_tvl_itoe_ou_mfg  CONSTANT VARCHAR2(20) := 'ITOE-OU-MFG';
  cv_tvl_update_from  CONSTANT VARCHAR2(20) := '処理日(From)';
  cv_tvl_update_to    CONSTANT VARCHAR2(20) := '処理日(To)  ';
  cv_tvl_auto_st      CONSTANT VARCHAR2(20) := '[]:自動取得値[';   -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動(開始)
  cv_tvl_auto_en      CONSTANT VARCHAR2(1)  := ']';                -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名_自動(終了)
  cv_tvl_para_st      CONSTANT VARCHAR2(1)  := '[';                -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名(開始)
  cv_tvl_para_en      CONSTANT VARCHAR2(1)  := ']';                -- ｺﾝｶﾚﾝﾄ･ﾊﾟﾗﾒｰﾀ名(終了)
  cv_tvl_upd_tbl_name CONSTANT VARCHAR2(20) := 'パーティアドオン'; -- 更新・登録対象となるテーブル
  -- ■ データフォーマット
  cv_datetime_fmt     CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt         CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 add start by Shigeto.Niki
  cv_max_date         CONSTANT VARCHAR2(10) := '9999/12/31';       -- MAX日付
  cv_null             CONSTANT VARCHAR2(2)  := 'X';                -- NULLの代替文字
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 add end by Shigeto.Niki  
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 所属マスタIF出力（自販機管理）レイアウト
  TYPE xxcmn_parties_rtype IS RECORD
  (
     party_id                   hz_cust_accounts.party_id%TYPE             -- パーティID
    ,account_number             hz_cust_accounts.account_number%TYPE       -- 顧客コード
    ,party_name                 hz_parties.party_name%TYPE                 -- 顧客名称
    ,party_short_name           hz_cust_accounts.account_name%TYPE         -- 顧客略称
    ,party_name_alt             hz_parties.organization_name_phonetic%TYPE -- 顧客カナ名
    ,state                      hz_locations.state%TYPE                    -- 都道府県
    ,city                       hz_locations.city%TYPE                     -- 市区町村
    ,address1                   hz_locations.address1%TYPE                 -- 住所１
    ,address2                   hz_locations.address2%TYPE                 -- 住所２
    ,phone                      hz_locations.address_lines_phonetic%TYPE   -- 電話番号
    ,fax                        hz_locations.address4%TYPE                 -- FAX番号
    ,postal_code                hz_locations.postal_code%TYPE              -- 郵便番号
    ,xxcmn_perties_active_flag  VARCHAR2(1)                                -- パーティアドオン有無フラグ
  );
--
  -- 所属マスタIF出力（自販機管理）レイアウト テーブルタイプ
  TYPE xxcmn_parties_ttype IS TABLE OF xxcmn_parties_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ
  gv_in_proc_date_from        VARCHAR2(50);   -- 処理日(FROM)
  gv_in_proc_date_to          VARCHAR2(50);   -- 処理日(TO)
  -- データ・プロファイル
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--  gv_pro_init01     fnd_profile_option_values.profile_option_value%TYPE;  -- 引当順初期値
--  gv_pro_init03     fnd_profile_option_values.profile_option_value%TYPE;  -- 振替グループ初期値
--  gv_pro_init04     fnd_profile_option_values.profile_option_value%TYPE;  -- 物流ブロック初期値
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
  gv_pro_init05     fnd_profile_option_values.profile_option_value%TYPE;  -- 拠点大分類初期値
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--  gv_pro_init06     fnd_profile_option_values.profile_option_value%TYPE;  -- ドリンク運賃振替基準初期値
--  gv_pro_init07     fnd_profile_option_values.profile_option_value%TYPE;  -- リーフ運賃振替基準初期値
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
  gv_sys_ctrl_cal   fnd_profile_option_values.profile_option_value%TYPE;  -- カレンダーコード
  -- 処理の対象となるテーブル
  gt_parties_tab  xxcmn_parties_ttype;  -- 住所情報
  -- 日付関連
  gd_process_date             DATE;           -- 業務日付
  gv_process_start_datetime   VARCHAR2(50);   -- 処理開始日時(フォーマット：YYYY/MM/DD HH24:MI:SS)
  gd_proc_date_from           DATE;           -- 処理日(FROM) ※入力パラメータの処理用
  gd_proc_date_to             DATE;           -- 処理日(TO)   ※入力パラメータの処理用
  -- データのキー情報
  gv_sal_org_id      hr_all_organization_units.organization_id%TYPE; -- 営業側の組織ID
  gv_mfg_org_id      hr_all_organization_units.organization_id%TYPE; -- 生産側の組織ID
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
    -- *** ローカル定数 ****
    cv_min_time               CONSTANT VARCHAR2(10) := ' 00:00:00';
    cv_max_time               CONSTANT VARCHAR2(10) := ' 23:59:59';
    -- *** ローカル変数 ***
    ld_prev_process_date DATE;          -- 前業務日付
    lv_proc_date_tmp     VARCHAR2(20);  -- 処理日(一時格納用)
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
    --１．処理開始日時を取得します。
    --==============================================================
    gv_process_start_datetime := TO_DATE(SYSDATE, cv_datetime_fmt);
--
    --=========================:=====================================
    --２．業務日付を取得する。
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    --==============================================================
    --３．前業務日付を取得します。
    --==============================================================
    -- カレンダーコードを取得する。
    gv_sys_ctrl_cal    := FND_PROFILE.VALUE(cv_pro_sys_ctrl_cal);
    -- カレンダーコードが取得できない場合、プロファイル取得エラー
    IF ( gv_sys_ctrl_cal IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_sys_ctrl_cal  -- 値      :カレンダーコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 前業務日付を取得する。
    ld_prev_process_date := xxccp_common_pkg2.get_working_day(
                              id_date          => gd_process_date
                             ,in_working_day   => -1
                             ,iv_calendar_code => gv_sys_ctrl_cal
                           );
--
    --==============================================================
    -- ４．処理日(From)と処理日(To)の設定
    --==============================================================
    -- 処理日(From)を"YYYY/MM/DD 00:00:00"形式で取得
    -- (パラメータ未入力の場合、前業務日付の翌日をセット)
    IF ( gv_in_proc_date_from IS NULL ) THEN
      lv_proc_date_tmp := TO_CHAR(ld_prev_process_date + 1, cv_date_fmt) || cv_min_time;
    ELSE
      lv_proc_date_tmp := gv_in_proc_date_from || cv_min_time;
    END IF;
    -- 取得した処理日(From)を日付型に変換
    gd_proc_date_from := TO_DATE(lv_proc_date_tmp, cv_datetime_fmt);
    -- 処理日(To)を"YYYY/MM/DD 23:59:59"形式で取得
    -- (パラメータ未入力の場合、業務日付をセット)
    IF ( gv_in_proc_date_to IS NULL ) THEN
      lv_proc_date_tmp := TO_CHAR(gd_process_date, cv_date_fmt) || cv_max_time;
    ELSE
      lv_proc_date_tmp := gv_in_proc_date_to || cv_max_time;
    END IF;
    -- 取得した処理日(To)を日付型に変換
    gd_proc_date_to := TO_DATE(lv_proc_date_tmp, cv_datetime_fmt);
--
    --==============================================================
    --５．パラメータチェックを行います。
    --==============================================================
    -- "最終更新日(From) > 最終更新日(To)"の場合、パラメータエラー
    IF ( gd_proc_date_from > gd_proc_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00031         -- エラー:期間指定エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --６．プロファイルの取得を行います。
    --==============================================================
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:パーティアドオンマスタ登録画面_引当順初期値
--    gv_pro_init01    := FND_PROFILE.VALUE(cv_pro_init01);
--    -- XXCMN:パーティアドオンマスタ登録画面_振替グループ初期値
--    gv_pro_init03    := FND_PROFILE.VALUE(cv_pro_init03);
--    -- XXCMN:パーティアドオンマスタ登録画面_物流ブロック初期値
--    gv_pro_init04    := FND_PROFILE.VALUE(cv_pro_init04);
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
    -- XXCMN:パーティアドオンマスタ登録画面_拠点大分類初期値
    gv_pro_init05    := FND_PROFILE.VALUE(cv_pro_init05);
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:パーティアドオンマスタ登録画面_ドリンク運賃振替基準初期値
--    gv_pro_init06    := FND_PROFILE.VALUE(cv_pro_init06);
--    -- XXCMN:パーティアドオンマスタ登録画面_リーフ運賃振替基準初期値 
--    gv_pro_init07    := FND_PROFILE.VALUE(cv_pro_init07);
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
--
    --==============================================================
    --７．プロファイル取得失敗時、以下の例外処理を行います。
    --==============================================================
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:パーティアドオンマスタ登録画面_引当順初期値
--    IF ( gv_pro_init01 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- マスタ
--                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
--                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init01    -- 値      :引当順初期値
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    -- XXCMN:パーティアドオンマスタ登録画面_振替グループ初期値
--    IF ( gv_pro_init03 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- マスタ
--                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
--                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init03    -- 値      :振替グループ初期値
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    -- XXCMN:パーティアドオンマスタ登録画面_物流ブロック初期値
--    IF ( gv_pro_init04 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- マスタ
--                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
--                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init04    -- 値      :物流ブロック初期値
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
    -- XXCMN:パーティアドオンマスタ登録画面_拠点大分類初期値
    IF ( gv_pro_init05 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_pro_init05    -- 値      :拠点大分類初期値
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:パーティアドオンマスタ登録画面_ドリンク運賃振替基準初期値
--    IF ( gv_pro_init06 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- マスタ
--                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
--                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init06    -- 値      :ドリンク運賃振替基準初期値
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    -- XXCMN:パーティアドオンマスタ登録画面_リーフ運賃振替基準初期値
--    IF ( gv_pro_init07 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- マスタ
--                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
--                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init07    -- 値      :リーフ運賃振替基準初期値
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2010/02/15 Ver1.2 E_本稼動_01419 delete end by Yutaka.Kuboshima
--
    --==============================================================
    --８．営業側の組織IDを取得します。
    --==============================================================
    BEGIN
      SELECT haou.organization_id organization_id -- 営業組織ID
      INTO   gv_sal_org_id
      FROM   hr_all_organization_units haou       -- 人事組織マスタテーブル
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki
--      WHERE  haou.name = 'SALES-OU'
      WHERE  haou.name = cv_tvl_sales_ou
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki
      AND    ROWNUM    = 1
      ;
    EXCEPTION
      -- 対象データが見つからなかった場合
      WHEN NO_DATA_FOUND THEN
        gv_sal_org_id := NULL;
      -- 上記以外の場合
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --９．営業組織ID取得確認
    --==============================================================
    IF ( gv_sal_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00015         -- エラー  :組織ID取得エラー
                     ,iv_token_name1  => cv_tok_ng_ou_name    -- トークン:NG_OU_NAME
                     ,iv_token_value1 => cv_tvl_sales_ou      -- 値      :'SALES-OU'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --１０．生産側の組織IDを取得します。
    --==============================================================
    BEGIN
      SELECT haou.organization_id organization_id -- 生産組織ID
      INTO   gv_mfg_org_id
      FROM   hr_all_organization_units haou       -- 人事組織マスタテーブル
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki
--      WHERE  haou.name = 'ITOE-OU-MFG'
      WHERE  haou.name = cv_tvl_itoe_ou_mfg
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki
      AND    ROWNUM    = 1
      ;
    EXCEPTION
      -- 対象データが見つからなかった場合
      WHEN NO_DATA_FOUND THEN
        gv_mfg_org_id := NULL;
      -- 上記以外の場合
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --１１．生産組織ID取得確認
    --==============================================================
    IF ( gv_mfg_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00015         -- エラー  :組織ID取得エラー
                     ,iv_token_name1  => cv_tok_ng_ou_name    -- トークン:NG_OU_NAME
                     ,iv_token_value1 => cv_tvl_itoe_ou_mfg   -- 値      :'ITOE-OU-MFG'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
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
   * Procedure Name   : get_parties_data
   * Description      : 処理対象データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_parties_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_parties_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 add start by Shigeto.Niki
    cv_flag_a                 CONSTANT VARCHAR2(1)  := 'A';   -- 有効フラグA
    cv_customer_class_cust    CONSTANT VARCHAR2(2)  := '10';  -- 顧客区分：顧客
    cv_customer_class_base    CONSTANT VARCHAR2(2)  := '1';   -- 顧客区分：拠点
    cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';
    cv_flag_no                CONSTANT VARCHAR2(1)  := 'N';
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 add end by Shigeto.Niki
--
    -- *** ローカルカーソル***
-- 2010/02/18 Ver1.3 E_本稼動_01419 delete start by Yutaka.Kuboshima
-- ロックカーソルと取得カーソルを一本にする
--    CURSOR parties_data_lock_cur(
--       id_proc_date_from DATE
--      ,id_proc_date_to   DATE
--      ,it_sal_org_id     hr_all_organization_units.organization_id%TYPE
--      ,it_mfg_org_id     hr_all_organization_units.organization_id%TYPE)
--    IS
--      SELECT xcp.party_id        AS party_id  -- (列)パーティID
--      FROM   hz_cust_accounts       hca       -- (table)顧客マスタテーブル
--            ,hz_parties             hpt       -- (table)パーティテーブル
--            ,hz_party_sites         hps       -- (table)パーティサイトテーブル
--            ,hz_cust_acct_sites_all hsa       -- (table)顧客所在地テーブル
--            ,hz_locations           hlo       -- (table)顧客事業所テーブル
--            ,xxcmn_parties          xcp       -- (table)パーティアドオンテーブル
--      WHERE  hca.party_id        = hpt.party_id
--      AND    hca.party_id        = hps.party_id
--      AND    hca.cust_account_id = hsa.cust_account_id
--      AND    hps.party_site_id   = hsa.party_site_id
--      AND    hps.location_id     = hlo.location_id
--      AND    hca.party_id        = xcp.party_id
--      AND    hps.status          = 'A'                  -- (条件)パーティサイトテーブルが有効
--      AND    hca.customer_class_code IN ('1','10')      -- (条件)拠点または顧客
--      AND    hsa.org_id          = it_sal_org_id        -- (条件)組織が営業組織である
--      AND    EXISTS( /* 生産OUを保有するもの */
--               SELECT 'X'
--               FROM   hz_cust_acct_sites_all   hsa1 -- (table)顧客所在地テーブル
--               WHERE  hsa1.cust_account_id = hca.cust_account_id
--               AND    hsa1.status          = 'A'
--               AND    hsa1.org_id          = it_mfg_org_id
--             )
--      AND    (   hca.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hsa.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hlo.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR EXISTS( 
--                   SELECT xcp1.party_id
--                   FROM   xxcmn_parties xcp1        -- (table)パーティアドオンテーブル
--                   WHERE  xcp1.party_id = hca.party_id
--                   AND    xcp1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_本稼動_01419 add start by Yutaka.Kuboshima
--              -- パーティサイトアドオンを差分テーブルに追加
--              OR EXISTS(
--                   SELECT xps1.party_site_id
--                   FROM   xxcmn_party_sites xps1
--                   WHERE  xps1.party_id = hca.party_id
--                   AND    xps1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_本稼動_01419 add end by Yutaka.Kuboshima
--             )                                          -- (条件)最終更新日が処理日(From～To)の範囲内
--      FOR UPDATE OF xcp.party_id  NOWAIT
--      ;
-- 2010/02/18 Ver1.3 E_本稼動_01419 delete end by Yutaka.Kuboshima
--
    -- パーティアドオン取得カーソル
    CURSOR parties_data_cur(
       id_proc_date_from DATE
      ,id_proc_date_to   DATE
      ,it_sal_org_id     hr_all_organization_units.organization_id%TYPE
      ,it_mfg_org_id     hr_all_organization_units.organization_id%TYPE)
    IS
-- 2010/02/18 Ver1.3 E_本稼動_01419 modify start by Yutaka.Kuboshima
--      SELECT hca.party_id                   AS party_id                   -- (列)パーティID
      -- ヒント句の追加
      SELECT /*+ FIRST_ROWS LEADING(def hca) INDEX(hca HZ_CUST_ACCOUNTS_U1) */
-- 2010/02/18 Ver1.3 E_本稼動_01419 modify end by Yutaka.Kuboshima
             hca.party_id                   AS party_id                   -- (列)パーティID
            ,hca.account_number             AS account_number             -- (列)顧客コード
            ,hpt.party_name                 AS party_name                 -- (列)顧客名称
            ,hca.account_name               AS party_short_name           -- (列)顧客略称
            ,hpt.organization_name_phonetic AS party_name_alt             -- (列)顧客カナ名
            ,hlo.state                      AS state                      -- (列)都道府県
            ,hlo.city                       AS city                       -- (列)市区町村
            ,hlo.address1                   AS address1                   -- (列)住所１
            ,hlo.address2                   AS address2                   -- (列)住所２
            ,hlo.address_lines_phonetic     AS phone                      -- (列)電話番号
            ,hlo.address4                   AS fax                        -- (列)FAX番号
            ,hlo.postal_code                AS postal_code                -- (列)郵便番号
            ,CASE
               WHEN (
                 SELECT xcpt.party_id
                 FROM   xxcmn_parties  xcpt         -- (table)パーティアドオンテーブル
                 WHERE  xcpt.party_id = hca.party_id
                 AND    ROWNUM = 1
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki
--               ) IS NOT NULL THEN 'Y'
--               ELSE               'N'
               ) IS NOT NULL THEN cv_flag_yes
               ELSE               cv_flag_no
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki
             END                            AS xxcmn_perties_active_flag  -- (列)パーティアドオン有無
      FROM   hz_cust_accounts       hca             -- (table)顧客マスタテーブル
            ,hz_parties             hpt             -- (table)パーティテーブル
            ,hz_party_sites         hps             -- (table)パーティサイトテーブル
            ,hz_cust_acct_sites_all hsa             -- (table)顧客所在地テーブル
            ,hz_locations           hlo             -- (table)顧客事業所テーブル
-- 2010/02/18 Ver1.3 E_本稼動_01419 add start by Yutaka.Kuboshima
            ,xxcmn_parties          xcp             -- (table)パーティアドオンテーブル
            ,(SELECT hca1.cust_account_id   cust_account_id
              FROM   hz_cust_accounts hca1
              WHERE  hca1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT hcas2.cust_account_id   cust_account_id
              FROM   hz_cust_acct_sites_all hcas2
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki
--              WHERE  hcas2.org_id = 2190
              WHERE  hcas2.org_id = it_sal_org_id
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki
                AND  hcas2.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT /*+ USE_NL(hl3 hps3 hp3 hca3) */
                     hca3.cust_account_id   cust_account_id
              FROM   hz_cust_accounts hca3
                    ,hz_parties       hp3
                    ,hz_party_sites   hps3
                    ,hz_locations     hl3
              WHERE  hca3.party_id    = hp3.party_id
                AND  hp3.party_id     = hps3.party_id
                AND  hps3.location_id = hl3.location_id
                AND  hl3.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT hca4.cust_account_id   cust_account_id
              FROM   hz_cust_accounts hca4
                    ,xxcmn_parties    xp4
              WHERE  hca4.party_id = xp4.party_id
                AND  xp4.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT hca5.cust_account_id   cust_account_id
              FROM   hz_cust_accounts  hca5
                    ,xxcmn_party_sites xps5
              WHERE  hca5.party_id = xps5.party_id
                AND  xps5.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
             ) def                                 -- 差分対象レコード
-- 2010/02/18 Ver1.3 E_本稼動_01419 add end by Yutaka.Kuboshima
      WHERE  hca.party_id        = hpt.party_id
      AND    hca.party_id        = hps.party_id
      AND    hca.cust_account_id = hsa.cust_account_id
      AND    hps.party_site_id   = hsa.party_site_id
      AND    hps.location_id     = hlo.location_id
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki
--      AND    hps.status          = 'A'                  -- (条件)パーティサイトテーブルが有効
--      AND    hca.customer_class_code IN ('1','10')      -- (条件)拠点または顧客
      AND    hps.status          = cv_flag_a            -- (条件)パーティサイトテーブルが有効
      AND    hca.customer_class_code IN (cv_customer_class_base , cv_customer_class_cust)      -- (条件)拠点または顧客
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki    
      AND    hsa.org_id          = it_sal_org_id        -- (条件)組織が営業組織である
      AND    EXISTS( /* 生産OUを保有するもの */
               SELECT 'X'
               FROM   hz_cust_acct_sites_all   hsa1 -- (table)顧客所在地テーブル
               WHERE  hsa1.cust_account_id = hca.cust_account_id
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki
--               AND    hsa1.status          = 'A'
               AND    hsa1.status          = cv_flag_a
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki
               AND    hsa1.org_id          = it_mfg_org_id
             )
-- 2010/02/18 Ver1.3 E_本稼動_01419 modify start by Yutaka.Kuboshima
--      AND    (   hca.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hsa.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hlo.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR EXISTS( 
--                   SELECT xcp1.party_id
--                   FROM   xxcmn_parties xcp1        -- (table)パーティアドオンテーブル
--                   WHERE  xcp1.party_id = hca.party_id
--                   AND    xcp1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_本稼動_01419 add start by Yutaka.Kuboshima
--              -- パーティサイトアドオンを差分テーブルに追加
--              OR EXISTS(
--                   SELECT xps1.party_site_id
--                   FROM   xxcmn_party_sites xps1
--                   WHERE  xps1.party_id = hca.party_id
--                   AND    xps1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_本稼動_01419 add end by Yutaka.Kuboshima
--             )                                          -- (条件)最終更新日が処理日(From～To)の範囲内
      AND    hps.party_id        = xcp.party_id(+)
      AND    hca.cust_account_id = def.cust_account_id
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 add start by Shigeto.Niki
      -- 顧客名称または住所情報が不一致のものを抽出
      AND   (NVL(xcp.party_name, cv_null)       <> NVL(SUBSTRB(hpt.party_name, 1, 60), cv_null)
       OR    NVL(xcp.party_short_name, cv_null) <> NVL(SUBSTRB(hca.account_name, 1, 20), cv_null)
       OR    NVL(xcp.party_name_alt, cv_null)   <> NVL(SUBSTRB(hpt.organization_name_phonetic, 1, 30), cv_null)
       OR    NVL(xcp.zip, cv_null)              <> NVL(SUBSTRB(hlo.postal_code, 1, 8), cv_null)
       OR    NVL(xcp.address_line1, cv_null)    <> NVL(SUBSTRB(hlo.state || hlo.city || hlo.address1 || hlo.address2,  1, 30), cv_null)
       OR    NVL(xcp.address_line2, cv_null)    <> NVL(SUBSTRB(hlo.state || hlo.city || hlo.address1 || hlo.address2, 31, 30), cv_null)
       OR    NVL(xcp.phone, cv_null)            <> NVL(SUBSTRB(hlo.address_lines_phonetic, 1, 15), cv_null)
       OR    NVL(xcp.fax, cv_null)              <> NVL(SUBSTRB(hlo.address4, 1,15), cv_null))
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 add end by Shigeto.Niki
      FOR UPDATE OF xcp.party_id  NOWAIT
-- 2010/02/18 Ver1.3 E_本稼動_01419 modify end by Yutaka.Kuboshima
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
-- 2010/02/18 Ver1.3 E_本稼動_01419 delete start by Yutaka.Kuboshima
--    --==============================================================
--    -- １．処理対象となるパーティアドオンのレコードロックを行います。
--    --==============================================================
--    BEGIN
--      OPEN  parties_data_lock_cur(gd_proc_date_from, gd_proc_date_to, gv_sal_org_id, gv_mfg_org_id);
--      CLOSE parties_data_lock_cur;
----
--    --==============================================================
--    -- ２．ロックに失敗した場合、ロックエラー
--    --==============================================================
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name_xxcmm    -- マスタ
--                       ,iv_name         => cv_msg_00008         -- エラー  :ロックエラー
--                       ,iv_token_name1  => cv_tok_ng_table      -- トークン:NG_TABLE
--                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- 値      :パーティアドオン
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--    END;
--
-- 2010/02/18 Ver1.3 E_本稼動_01419 delete end by Yutaka.Kuboshima
--
    --==============================================================
    -- ３．処理対象となるパーティアドオンの抽出し、
    --     結果を配列に格納します。
    --==============================================================
-- 2010/02/18 Ver1.3 E_本稼動_01419 modify start by Yutaka.Kuboshima
--    -- パーティアドオン取得カーソルのオープン
--    OPEN parties_data_cur(gd_proc_date_from, gd_proc_date_to, gv_sal_org_id, gv_mfg_org_id);
--    -- 処理対象となるパーティアドオンの取得
--    <<output_data_loop>>
--    LOOP
--      FETCH parties_data_cur BULK COLLECT INTO gt_parties_tab;
--      EXIT WHEN parties_data_cur%NOTFOUND;
--    END LOOP output_data_loop;
--    -- パーティアドオン取得カーソルのクローズ
--    CLOSE parties_data_cur;
    --==============================================================
    -- １．処理対象となるパーティアドオンのレコードロックと、
    --     処理対象レコードの抽出結果を配列に格納します。
    --==============================================================
    BEGIN
      -- パーティアドオン取得カーソルのオープン
      OPEN parties_data_cur(gd_proc_date_from, gd_proc_date_to, gv_sal_org_id, gv_mfg_org_id);
      -- 処理対象となるパーティアドオンの取得
      <<output_data_loop>>
      LOOP
        FETCH parties_data_cur BULK COLLECT INTO gt_parties_tab;
        EXIT WHEN parties_data_cur%NOTFOUND;
      END LOOP output_data_loop;
      -- パーティアドオン取得カーソルのクローズ
      CLOSE parties_data_cur;
    --==============================================================
    -- ２．ロックに失敗した場合、ロックエラー
    --==============================================================
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- マスタ
                       ,iv_name         => cv_msg_00008         -- エラー  :ロックエラー
                       ,iv_token_name1  => cv_tok_ng_table      -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- 値      :パーティアドオン
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2010/02/18 Ver1.3 E_本稼動_01419 modify end by Yutaka.Kuboshima
    -- 件数を取得
    gn_target_cnt := gt_parties_tab.COUNT;
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
  END get_parties_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_linkage_item
   * Description      : 連携項目チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_linkage_item(
    it_parties_rec  IN  xxcmn_parties_rtype,  -- 1.パーティアドオン更新データ
    ov_errbuf         OUT VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_linkage_item'; -- プログラム名
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
    cv_party_name_col_name           CONSTANT VARCHAR2(20) := '顧客名称';
    cn_party_name_col_size           CONSTANT NUMBER := 60;  -- (サイズ)顧客名称
    cv_party_short_name_col_name     CONSTANT VARCHAR2(20) := '略称';
    cn_party_short_name_col_size     CONSTANT NUMBER := 20;  -- (サイズ)顧客略称
    cv_party_name_alt_col_name       CONSTANT VARCHAR2(20) := 'カナ名';
    cv_party_name_alt_col_size       CONSTANT NUMBER := 30;  -- (サイズ)顧客カナ名
    cv_postal_code_col_name          CONSTANT VARCHAR2(20) := '郵便番号';
    cn_postal_code_col_size          CONSTANT NUMBER := 8;   -- (サイズ)郵便番号
    cv_address_line_col_name         CONSTANT VARCHAR2(20) := '住所';
    cn_address_line_col_size         CONSTANT NUMBER := 60;  -- (サイズ)住所
    cv_phone_col_name                CONSTANT VARCHAR2(20) := '電話番号';
    cn_phone_col_size                CONSTANT NUMBER := 15;  -- (サイズ)電話番号
    cv_fax_col_name                  CONSTANT VARCHAR2(20) := 'FAX番号';
    cn_fax_col_size                  CONSTANT NUMBER := 15;  -- (サイズ)FAX番号
    -- *** ローカル変数 ***
    lt_party_id    xxcmn_parties.party_id%TYPE;           -- パーティID
    lt_cust_cd     hz_cust_accounts.account_number%TYPE;  -- 顧客コード
    lv_data_value  VARCHAR2(2000);  -- 挿入・更新対象データの内容
    ln_data_size   NUMBER;          -- 挿入・更新対象データのサイズ
    lb_is_checked  BOOLEAN;         -- サイズチェックフラグ（チェックあり⇒TRUE チェックなし⇒FALSE)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lt_party_id := it_parties_rec.party_id;
    lt_cust_cd  := it_parties_rec.account_number;
    lb_is_checked := FALSE;
--
    --==============================================================
    -- １．顧客名称の取得データサイズをチェック
    --==============================================================
    -- 顧客名称の値を取得
    lv_data_value := it_parties_rec.party_name;
    -- 顧客名称のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- 顧客名称のサイズが60Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cn_party_name_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_party_name_col_name       -- 値      :顧客名称
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cn_party_name_col_size       -- 値      :顧客名称(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :顧客名称(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :顧客名称(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- ２．略称の取得データサイズをチェック
    --==============================================================
    -- 略称の値を取得
    lv_data_value := it_parties_rec.party_short_name;
    -- 略称のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- 略称のサイズが20Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cn_party_short_name_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_party_short_name_col_name -- 値      :略称
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cn_party_short_name_col_size -- 値      :略称(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :略称(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :略称(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- ３．カナ名の取得データサイズをチェック
    --==============================================================
    -- カナ名の値を取得
    lv_data_value := it_parties_rec.party_name_alt;
    -- カナ名のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- カナ名のサイズが30Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cv_party_name_alt_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_party_name_alt_col_name   -- 値      :カナ名
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cv_party_name_alt_col_size   -- 値      :カナ名(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :カナ名(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :カナ名(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- ４．郵便番号の取得データサイズをチェック
    --==============================================================
    -- 郵便番号の値を取得
    lv_data_value := it_parties_rec.postal_code;
    -- 郵便番号のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- 郵便番号のサイズが8Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cn_postal_code_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_postal_code_col_name      -- 値      :郵便番号
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cn_postal_code_col_size      -- 値      :郵便番号(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :郵便番号(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :郵便番号(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- ５．住所の取得データサイズをチェック
    --==============================================================
    -- 住所の値を取得
    lv_data_value := it_parties_rec.state || it_parties_rec.city
                      || it_parties_rec.address1 || it_parties_rec.address2;
    -- 住所のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- 住所のサイズが60Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cn_address_line_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_address_line_col_name     -- 値      :住所
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cn_address_line_col_size     -- 値      :住所(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :住所(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :住所(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- ６．電話番号の取得データサイズをチェック
    --==============================================================
    -- 電話番号の値を取得
    lv_data_value := it_parties_rec.phone;
    -- 電話番号のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- 電話番号のサイズが15Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cn_phone_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_phone_col_name            -- 値      :電話番号
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cn_phone_col_size            -- 値      :電話番号(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :電話番号(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :電話番号(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- ７．FAX番号の取得データサイズをチェック
    --==============================================================
    -- FAX番号の値を取得
    lv_data_value := it_parties_rec.fax;
    -- FAX番号のサイズを取得
    ln_data_size  := LENGTHB(lv_data_value);
    -- FAX番号のサイズが15Byte以上の場合、警告メッセージ出力
    IF ( ln_data_size > cn_fax_col_size ) THEN
        --(警告メッセージを取得)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- マスタ
                       ,iv_name         => cv_msg_00702                 -- エラー  :生産連携項目サイズ警告
                       ,iv_token_name1  => cv_tok_ng_table              -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd               -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id              -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- 値      :パーティID(値)
                       ,iv_token_name4  => cv_tok_col_name              -- トークン:COL_NAME
                       ,iv_token_value4 => cv_fax_col_name              -- 値      :FAX番号
                       ,iv_token_name5  => cv_tok_col_size              -- トークン:COL_SIZE
                       ,iv_token_value5 => cn_fax_col_size              -- 値      :FAX番号(最大サイズ)
                       ,iv_token_name6  => cv_tok_data_size             -- トークン:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- 値      :FAX番号(対象のサイズ)
                       ,iv_token_name7  => cv_tok_data_val              -- トークン:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- 値      :FAX番号(対象の内容)
                     );
        --(警告メッセージを出力(出力・ログ）)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(フラグをセット）
        lb_is_checked := TRUE;
    END IF;
--
-- 2010/02/23 Ver1.4 E_本稼動_01419 delete start by Yutaka.Kuboshima
-- チェックエラー時でも正常終了させるため削除
--  -- ステータスのチェック
--  IF ( lb_is_checked = TRUE ) THEN
--    RAISE size_over_expt;
--  END IF;
-- 2010/02/23 Ver1.4 E_本稼動_01419 delete end by Yutaka.Kuboshima
--
  EXCEPTION
    -- *** 生産連携項目サイズオーバ例外 ***
    WHEN size_over_expt THEN
      ov_retcode := cv_status_warn;
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
  END chk_linkage_item;
--
  /**********************************************************************************
   * Procedure Name   : upd_xxcmn_parties
   * Description      : パーティアドオン更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_xxcmn_parties(
    it_parties_rec  IN  xxcmn_parties_rtype,  -- 1.パーティアドオン更新データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxcmn_parties'; -- プログラム名
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
    lt_party_id     xxcmn_parties.party_id%TYPE;           -- パーティID
    lt_cust_cd      hz_cust_accounts.account_number%TYPE;  -- 顧客コード
    lv_address_line VARCHAR2(60);
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
    -- １．パーティアドオンを更新
    --==============================================================
    -- 初期設定
    lt_party_id     := it_parties_rec.party_id;
    lt_cust_cd      := it_parties_rec.account_number;
    lv_address_line := SUBSTRB(it_parties_rec.state || it_parties_rec.city
                        || it_parties_rec.address1 || it_parties_rec.address2,1,60);
    -- 更新
    BEGIN
      UPDATE xxcmn_parties xpts   -- (table)パーティアドオン
      SET    xpts.party_name        = SUBSTRB(it_parties_rec.party_name, 1, 60)
            ,xpts.party_short_name  = SUBSTRB(it_parties_rec.party_short_name, 1, 20)
            ,xpts.party_name_alt    = SUBSTRB(it_parties_rec.party_name_alt, 1, 30)
            ,xpts.zip               = SUBSTRB(it_parties_rec.postal_code, 1, 8)
            ,xpts.address_line1     = SUBSTRB(lv_address_line,  1, 30)
            ,xpts.address_line2     = SUBSTRB(lv_address_line, 31, 30)
            ,xpts.phone             = SUBSTRB(it_parties_rec.phone, 1, 15)
            ,xpts.fax               = SUBSTRB(it_parties_rec.fax, 1,15)
            --WHOカラム
            ,last_updated_by        = cn_last_updated_by
            ,last_update_date       = cd_last_update_date
            ,last_update_login      = cn_last_update_login
            ,request_id             = cn_request_id
            ,program_application_id = cn_program_application_id
            ,program_id             = cn_program_id
            ,program_update_date    = cd_program_update_date
      WHERE  xpts.party_id          = lt_party_id
      ;
--
    --==============================================================
    -- ２．更新失敗時、下記エラーメッセージ表示
    --==============================================================
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- マスタ
                       ,iv_name         => cv_msg_00700         -- エラー  :パーティアドオン更新エラー
                       ,iv_token_name1  => cv_tok_ng_table      -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd       -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd           -- 値      :顧客コード(値)
                       ,iv_token_name3  => cv_tok_party_id      -- トークン:PARTY_ID
                       ,iv_token_value3 => lt_party_id          -- 値      :パーティID(値)
                     );
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
  END upd_xxcmn_parties;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxcmn_parties
   * Description      : パーティアドオン登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_xxcmn_parties(
    it_parties_rec  IN  xxcmn_parties_rtype,  -- 1.パーティアドオン更新データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxcmn_parties'; -- プログラム名
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
    lt_party_id     xxcmn_parties.party_id%TYPE;           -- パーティID
    lt_cust_cd      hz_cust_accounts.account_number%TYPE;  -- 顧客コード
    lv_address_line VARCHAR2(60);
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
    -- １．パーティアドオンを登録
    --==============================================================
    -- 初期設定
    lt_party_id     := it_parties_rec.party_id;
    lt_cust_cd      := it_parties_rec.account_number;
    lv_address_line := SUBSTRB(it_parties_rec.state || it_parties_rec.city
                        || it_parties_rec.address1 || it_parties_rec.address2,1,60);
    -- 登録
    BEGIN
      --XXXXデータ挿入処理
      INSERT INTO xxcmn_parties (
         party_id               -- (列名)パーティーID
        ,start_date_active      -- (列名)適用開始日
        ,end_date_active        -- (列名)適用終了日
        ,party_name             -- (列名)正式名
        ,party_short_name       -- (列名)略称
        ,party_name_alt         -- (列名)カナ名
        ,zip                    -- (列名)郵便番号
        ,address_line1          -- (列名)住所１
        ,address_line2          -- (列名)住所２
        ,phone                  -- (列名)電話番号
        ,fax                    -- (列名)FAX番号
        ,reserve_order          -- (列名)引当順
        ,drink_transfer_std     -- (列名)ドリンク運賃振替基準
        ,leaf_transfer_std      -- (列名)リーフ運賃振替基準
        ,transfer_group         -- (列名)振替グループ
        ,distribution_block     -- (列名)物流ブロック
        ,base_major_division    -- (列名)拠点大分類
        ,eos_detination         -- (列名)EOS宛先
        ,created_by             -- (列名)作成者
        ,creation_date          -- (列名)作成日
        ,last_updated_by        -- (列名)最終更新者
        ,last_update_date       -- (列名)最終更新日
        ,last_update_login      -- (列名)最終更新ﾛｸﾞｲﾝ
        ,request_id             -- (列名)要求ID
        ,program_application_id -- (列名)ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id             -- (列名)ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date    -- (列名)ﾌﾟﾛｸﾞﾗﾑ更新日
      )VALUES(
         lt_party_id                                       -- (値)パーティーID
-- 2010/02/15 Ver1.2 E_本稼動_01419 modify start by Yutaka.Kuboshima
--        ,gd_process_date + 1                               -- (値)適用開始日
        ,gd_process_date                                  -- (値)適用開始日
-- 2010/02/15 Ver1.2 E_本稼動_01419 modify end by Yutaka.Kuboshima
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify start by Shigeto.Niki    
--        ,TO_DATE('99991231', 'YYYYMMDD')                   -- (値)適用終了日
        ,TO_DATE(cv_max_date , cv_date_fmt)                -- (値)適用終了日
-- 2010/05/28 Ver1.5 障害：E_本稼動_02876 modify end by Shigeto.Niki    
        ,SUBSTRB(it_parties_rec.party_name, 1, 60)         -- (値)正式名
        ,SUBSTRB(it_parties_rec.party_short_name, 1, 20)   -- (値)略称
        ,SUBSTRB(it_parties_rec.party_name_alt, 1, 30)     -- (値)カナ名
        ,SUBSTRB(it_parties_rec.postal_code, 1, 8)         -- (値)郵便番号
        ,SUBSTRB(lv_address_line,  1, 30)                  -- (値)住所１
        ,SUBSTRB(lv_address_line, 31, 30)                  -- (値)住所２
        ,SUBSTRB(it_parties_rec.phone, 1, 15)              -- (値)電話番号
        ,SUBSTRB(it_parties_rec.fax, 1, 15)                -- (値)FAX番号
-- 2010/02/15 Ver1.2 E_本稼動_01419 modify start by Yutaka.Kuboshima
--        ,gv_pro_init01                                     -- (値)引当順
--        ,gv_pro_init06                                     -- (値)ドリンク運賃振替基準
--        ,gv_pro_init07                                     -- (値)リーフ運賃振替基準
--        ,gv_pro_init03                                     -- (値)振替グループ
--        ,gv_pro_init04                                     -- (値)物流ブロック
         -- 初期値をNULLに変更
        ,NULL                                              -- (値)引当順
        ,NULL                                              -- (値)ドリンク運賃振替基準
        ,NULL                                              -- (値)リーフ運賃振替基準
        ,NULL                                              -- (値)振替グループ
        ,NULL                                              -- (値)物流ブロック
-- 2010/02/15 Ver1.2 E_本稼動_01419 modify end by Yutaka.Kuboshima
        ,gv_pro_init05                                     -- (値)拠点大分類
        ,NULL                                              -- (値)EOS宛先
        ,cn_created_by                                     -- (値)作成者
        ,cd_creation_date                                  -- (値)作成日
        ,cn_last_updated_by                                -- (値)最終更新者
        ,cd_last_update_date                               -- (値)最終更新日
        ,cn_last_update_login                              -- (値)最終更新ﾛｸﾞｲﾝ
        ,cn_request_id                                     -- (値)要求ID
        ,cn_program_application_id                         -- (値)ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,cn_program_id                                     -- (値)ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,cd_program_update_date                            -- (値)ﾌﾟﾛｸﾞﾗﾑ更新日
      );
--
    --==============================================================
    -- ２．登録失敗時、下記エラーメッセージ表示
    --==============================================================
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- マスタ
                       ,iv_name         => cv_msg_00701         -- エラー  :パーティアドオン登録エラー
                       ,iv_token_name1  => cv_tok_ng_table      -- トークン:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- 値      :パーティアドオン
                       ,iv_token_name2  => cv_tok_cust_cd       -- トークン:CUST_CD
                       ,iv_token_value2 => lt_cust_cd           -- 値      :顧客コード(値)
                     );
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
  END ins_xxcmn_parties;
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
    ln_idx     NUMBER;          -- 数値
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_yes       CONSTANT VARCHAR2(1) := 'Y';
    cv_flag_no        CONSTANT VARCHAR2(1) := 'N';
--
    -- *** ローカル変数 ***
    lv_tvl_para       VARCHAR2(100);  -- トークンに格納する値
    lv_out_msg        VARCHAR2(5000); -- 出力用
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
    -- ===============================================
    -- A-1.初期処理
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 入力パラメータ(処理日(From))の出力メッセージを取得
    -- ・処理日(From)がNULL     ⇒ 処理日（From） ： [] : 自動取得[YYYY/MM/DD]
    -- ・処理日(From)がNULL以外 ⇒ 処理日（From） ： [YYYY/MM/DD]
    IF ( gv_in_proc_date_from IS NULL ) THEN
      lv_tvl_para := cv_tvl_auto_st || TO_CHAR(gd_proc_date_from, cv_date_fmt) || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    ELSE
      lv_tvl_para := cv_tvl_para_st || gv_in_proc_date_from || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- 入力パラメータ(処理日(From))をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 入力パラメータ(処理日(To))の出力メッセージを取得
    -- ・処理日(To)がNULL     ⇒ 処理日（To） ： [] : 自動取得[YYYY/MM/DD]
    -- ・処理日(To)がNULL以外 ⇒ 処理日（To） ： [YYYY/MM/DD]
    IF ( gv_in_proc_date_to IS NULL ) THEN
      lv_tvl_para := cv_tvl_auto_st || TO_CHAR(gd_proc_date_to, cv_date_fmt) || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    ELSE
      lv_tvl_para := cv_tvl_para_st || gv_in_proc_date_to || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- 入力パラメータ(処理日(To))をコンカレント･出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 初期処理の実行結果チェック
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2．処理対象データ抽出
    -- ===============================================
    get_parties_data(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- 件数チェック
    IF ( gn_target_cnt = 0 ) THEN
      --(メッセージ出力)
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00001
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_out_msg
      );
      --(例外をスロー）
      RAISE no_output_data_expt;
    END IF;
--
    <<ins_parties_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      -- ===============================================
      -- A-3．連携項目チェック
      -- ===============================================
      chk_linkage_item(
         it_parties_rec  => gt_parties_tab(ln_idx)  -- ループAのカーソル(A-2で取得したデータの1レコード)
        ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
        ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 処理結果チェック(エラー)
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      -- 処理結果チェック(警告)
      ELSIF (lv_retcode = cv_status_warn) THEN
        --(リターン・コードに警告をセット）
        ov_retcode := cv_status_warn;
      END IF;
--
      -- ===============================================
      -- A-4．パーティアドオン更新
      -- ===============================================
      IF ( gt_parties_tab(ln_idx).xxcmn_perties_active_flag = cv_flag_yes ) THEN
        upd_xxcmn_parties(
           it_parties_rec  => gt_parties_tab(ln_idx)  -- ループAのカーソル(A-2で取得したデータの1レコード)
          ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 処理結果チェック(エラー)
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
--
      -- ===============================================
      -- A-5. パーティアドオン登録
      -- ===============================================
      ELSIF ( gt_parties_tab(ln_idx).xxcmn_perties_active_flag = cv_flag_no ) THEN
        ins_xxcmn_parties(
           it_parties_rec  => gt_parties_tab(ln_idx)  -- ループAのカーソル(A-2で取得したデータの1レコード)
          ,ov_errbuf       => lv_errbuf               -- エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode              -- リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- 処理結果チェック
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          RAISE global_process_expt;
        END IF;
      END IF;
      -- 成功件数を更新
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP ins_parties_loop;
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
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,        --   エラーコード     #固定#
    iv_proc_date_from     IN     VARCHAR2,        --   1.処理日(FROM)
    iv_proc_date_to       IN     VARCHAR2)        --   2.処理日(TO)
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
    gv_in_proc_date_from := iv_proc_date_from;
    gv_in_proc_date_to   := iv_proc_date_to;
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
    -- A-6. 終了処理
    -- ===============================================
    -- リターン・コードが異常終了の場合のメッセージ出力 、 件数の算出
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー件数の登録
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
    IF (retcode = cv_status_normal OR retcode = cv_status_warn ) THEN
      COMMIT;
    ELSIF (retcode = cv_status_error) THEN
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
END XXCMM007A01C;
/
