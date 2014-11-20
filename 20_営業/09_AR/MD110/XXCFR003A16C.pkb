CREATE OR REPLACE PACKAGE BODY XXCFR003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A16C(body)
 * Description      : 標準請求書税抜
 * MD.050           : MD050_CFR_003_A16_標準請求書税抜
 * MD.070           : MD050_CFR_003_A16_標準請求書税抜
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  chk_inv_all_dept       P 全社出力権限チェック処理                (A-3)
 *  insert_work_table      p ワークテーブルデータ登録                (A-4)
 *  chk_account_data       p 口座情報取得チェック                    (A-5)
 *  start_svf_api          p SVF起動                                 (A-6)
 *  delete_work_table      p ワークテーブルデータ削除                (A-7)
-- Modify 2009.09.10 Ver1.3 Start
 *  put_account_warning    p 顧客紐付け警告出力                      (A-8)
-- Modify 2009.09.10 Ver1.3 End
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.00 SCS 大川 恵      初回作成
 *  2009/03/05    1.1  SCS 大川 恵      共通関数リリースに伴うSVF起動処理変更対応
 *                                      中間テーブルデータ削除処理コメントアウト削除対応
 *  2009/04/14    1.2  SCS 大川 恵      [障害T1_0533] 出力ファイル名変数文字列オーバーフロー対応
 *  2009/09/25    1.3  SCS 廣瀬 真佐人  [共通課題:IE535] 標準請求書の出力概念変更
 *  2009/11/20    1.4  SCS 廣瀬 真佐人  [共通課題:IE691] 単独店の請求先名取得元変更
 *  2009/12/11    1.5  SCS 廣瀬 真佐人  [E_本稼動_00423] 単独店時の出力形式不具合
 *  2010/02/02    1.6  SCS 安川 智博    [E_本稼動_01503] 同一顧客-複数使用目的対応
 *  2010/12/10    1.7  SCS 石渡 賢和    [E_本稼動_05401] パラメータ「請求書発行サイクル」の追加
 *  2011/01/17    1.8  SCS 廣瀬 真佐人  [E_本稼動_00580] ソート順に店舗コード追加
 *  2011/03/10    1.9  SCS 石渡 賢和    [E_本稼動_06753] ソート順の店舗コードの例外条件追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  file_not_exists_expt  EXCEPTION;      -- ファイル存在エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A16C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
  cv_msg_003a16_001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
  cv_msg_003a16_002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
  cv_msg_003a16_003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
  cv_msg_003a16_004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
  cv_msg_003a16_005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_msg_003a16_006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_msg_003a16_007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバックメッセージ
  cv_msg_003a16_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
  cv_msg_003a16_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; -- システムエラーメッセージ
--
  cv_msg_003a16_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_003a16_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ロックエラーメッセージ
  cv_msg_003a16_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; -- データ削除エラーメッセージ
  cv_msg_003a16_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- テーブル挿入エラー
  cv_msg_003a16_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; -- 帳票０件メッセージ
  cv_msg_003a16_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; -- APIエラーメッセージ
  cv_msg_003a16_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- 帳票０件ログメッセージ
  cv_msg_003a16_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- 値取得エラーメッセージ
  cv_msg_003a16_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00038'; -- 振込口座未登録メッセージ
  cv_msg_003a16_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00051'; -- 振込口座未登録情報
  cv_msg_003a16_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00052'; -- 振込口座未登録件数メッセージ
  cv_msg_003a16_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- 共通関数エラーメッセージ
-- Modify 2009.09.10 Ver1.3 Start
  cv_msg_003a16_022  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00079'; -- 請求用顧客コード未定義エラー
  cv_msg_003a16_023  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00080'; -- 顧客関連未設定エラー
  cv_msg_003a16_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00081'; -- パラメータ設定エラー
-- Modify 2009.09.10 Ver1.3 End
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API名
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- コメント
  cv_tkn_get_data    CONSTANT VARCHAR2(30) := 'DATA';             -- 取得対象データ
  cv_tkn_ac_code     CONSTANT VARCHAR2(30) := 'ACCOUNT_CODE';     -- 顧客コード
  cv_tkn_ac_name     CONSTANT VARCHAR2(30) := 'ACCOUNT_NAME';     -- 顧客名
  cv_tkn_lc_name     CONSTANT VARCHAR2(30) := 'KYOTEN_NAME';      -- 拠点名
  cv_tkn_count       CONSTANT VARCHAR2(30) := 'COUNT';            -- カウント数
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- 共通関数名
--
  -- 日本語辞書
  cv_dict_date       CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- 日付パラメータ変換関数
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF起動
--
  cv_dict_ymd4       CONSTANT VARCHAR2(100) := 'CFR000A00007';    -- YYYY"年"MM"月"DD"日"
  cv_dict_ymd2       CONSTANT VARCHAR2(100) := 'CFR000A00008';    -- YY"年"MM"月"DD"日"
  cv_dict_year       CONSTANT VARCHAR2(100) := 'CFR000A00009';    -- 年
  cv_dict_month      CONSTANT VARCHAR2(100) := 'CFR000A00010';    -- 月
  cv_dict_bank       CONSTANT VARCHAR2(100) := 'CFR000A00011';    -- 銀行
  cv_dict_central    CONSTANT VARCHAR2(100) := 'CFR000A00015';    -- 本店
  cv_dict_branch     CONSTANT VARCHAR2(100) := 'CFR000A00012';    -- 支店
  cv_dict_account    CONSTANT VARCHAR2(100) := 'CFR000A00013';    -- 普通
  cv_dict_current    CONSTANT VARCHAR2(100) := 'CFR000A00014';    -- 当座
  cv_dict_zip_mark   CONSTANT VARCHAR2(100) := 'CFR000A00016';    -- 〒
  cv_dict_bank_damy  CONSTANT VARCHAR2(100) := 'CFR000A00017';    -- 銀行ダミーコード
  cv_dict_date_func  CONSTANT VARCHAR2(100) := 'CFR000A00002';    -- 営業日付取得関数
--
  --プロファイル
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
--
  -- 使用DB名
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_REP_ST_INVOICE_EX_TAX';  -- ワークテーブル名
--
  -- 請求書タイプ
  cv_invoice_type    CONSTANT VARCHAR2(1)   := 'S';                        -- ‘S’(標準請求書)
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';       -- ログ出力
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)   := 'Y';         -- 有効フラグ（Ｙ）
--
  cv_status_yes      CONSTANT VARCHAR2(1)   := '1';         -- 有効ステータス（1：有効）
  cv_status_no       CONSTANT VARCHAR2(1)   := '0';         -- 有効ステータス（0：無効）
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';             -- 日付フォーマット（年月日）
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';     -- 日付フォーマット（年月日時分秒
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';           -- 日付フォーマット（年月日スラッシュ付）
  cv_format_date_ymds2  CONSTANT VARCHAR2(8)  := 'YY/MM/DD';             -- 日付フォーマット（2桁年月日スラッシュ付）
--
  cd_max_date           CONSTANT DATE         := TO_DATE('9999/12/31',cv_format_date_ymds);
--
-- Modify 2009.09.10 Ver1.3 Start
  -- 顧客区分
  cv_customer_class_code14 CONSTANT VARCHAR2(2) := '14';      -- 顧客区分14(売掛管理先)
  cv_customer_class_code20 CONSTANT VARCHAR2(2) := '20';      -- 顧客区分20(請求書用)
  cv_customer_class_code10 CONSTANT VARCHAR2(2) := '10';      -- 顧客区分10(顧客)
--
  -- 請求書印刷単位
  cv_invoice_printing_unit_n1 CONSTANT VARCHAR2(2) := '2';    -- 請求書印刷単位:'2'
  cv_invoice_printing_unit_n2 CONSTANT VARCHAR2(2) := '3';    -- 請求書印刷単位:'3'
  cv_invoice_printing_unit_n3 CONSTANT VARCHAR2(2) := '1';    -- 請求書印刷単位:'1'
  cv_invoice_printing_unit_n4 CONSTANT VARCHAR2(2) := '0';    -- 請求書印刷単位:'0'
--
  -- 使用目的
  cv_site_use_code_bill_to CONSTANT VARCHAR(10) := 'BILL_TO';  -- 使用目的：「請求先」
  cv_site_use_code_ship_to CONSTANT VARCHAR(10) := 'SHIP_TO';  -- 使用目的：「出荷先」
-- Add 2010.02.02 Ver1.6 Start
  cv_site_use_stat_act     CONSTANT VARCHAR2(1) := 'A';        -- 使用目的ステータス：有効
-- Add 2010.02.02 Ver1.6 End
--
  -- 顧客関連処理対象ステータス
  cv_acct_relate_status    CONSTANT VARCHAR2(1) := 'A';
--
  -- 顧客関連
  cv_acct_relate_type_bill CONSTANT VARCHAR2(1) := '1';     -- 請求関連
--
-- Modify 2009.09.10 Ver1.3 End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
-- Modify 2009.09.10 Ver1.3 Start
  TYPE rtype_main_data IS RECORD(
    cash_account_id       hz_cust_accounts.cust_account_id%TYPE     --顧客ID
   ,cash_account_number   hz_cust_accounts.account_number%TYPE      --顧客コード
   ,cash_account_name     hz_parties.party_name%TYPE                --顧客顧客名
   ,ship_account_id       hz_cust_accounts.cust_account_id%TYPE     --顧客顧客ID        
   ,ship_account_number   hz_cust_accounts.account_number%TYPE      --顧客顧客コード 
   ,bill_base_code        xxcmm_cust_accounts.bill_base_code%TYPE   --顧客請求拠点コード
   ,bill_postal_code      hz_locations.postal_code%TYPE             --顧客郵便番号      
   ,bill_state            hz_locations.state%TYPE                   --顧客都道府県      
   ,bill_city             hz_locations.city%TYPE                    --顧客市・区        
   ,bill_address1         hz_locations.address1%TYPE                --顧客住所1         
   ,bill_address2         hz_locations.address2%TYPE                --顧客住所2
   ,phone_num             hz_locations.address_lines_phonetic%TYPE  --顧客電話番号
   ,bill_tax_div          xxcmm_cust_accounts.tax_div%TYPE          --顧客消費税区分
   ,bill_invoice_type     hz_cust_site_uses.attribute7%TYPE         --顧客請求書出力形式
   ,bill_payment_term_id  hz_cust_site_uses.payment_term_id%TYPE    --顧客支払条件
-- Add 2010.12.10 Ver1.7 Start
   ,bill_pub_cycle        hz_cust_site_uses.attribute8%TYPE         --請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
  ,cons_inv_flag          hz_customer_profiles.cons_inv_flag%TYPE   --一括請求書式
  );
-- Modify 2009.09.10 Ver1.3 End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_target_date        DATE;                                      -- パラメータ．締日（データ型変換用）
  gn_org_id             NUMBER;                                    -- 組織ID
  gn_set_of_bks_id      NUMBER;                                    -- 会計帳簿ID
  gt_user_dept          per_all_people_f.attribute28%TYPE := NULL; -- ログインユーザ所属部門
  gv_inv_all_flag       VARCHAR2(1) := '0';                        -- 全社出力権限所持部門フラグ
-- Modify 2009.09.10 Ver1.3 Start
  gv_warning_flag       VARCHAR2(1) := cv_status_no;               -- 顧客紐付け警告存在フラグ
-- Modify 2009.09.10 Ver1.3 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--    iv_ar_code1            IN      VARCHAR2,         -- 売掛コード１(請求書)
    iv_custome_cd          IN      VARCHAR2,         -- 顧客番号(顧客)
    iv_invoice_cd          IN      VARCHAR2,         -- 顧客番号(請求用)
    iv_payment_cd          IN      VARCHAR2,         -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
    iv_bill_pub_cycle      IN      VARCHAR2,         -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
-- Modify 2009.09.10 Ver1.3 Start
    ln_count   PLS_INTEGER := 0;     -- カウンタ
-- Modify 2009.09.10 Ver1.3 End
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
--
--##################  固定ステータス初期化部 START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- パラメータ．締日をDATE型に変換する
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_021 -- 共通関数エラー
                                                    ,cv_tkn_func       -- トークン'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_date_func))
                                                    -- 営業日付取得関数
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log             -- ログ出力
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- コンカレントパラメータ１
-- Modify 2009.09.10 Ver1.3 Start
--                                   ,iv_conc_param2  => iv_ar_code1                  -- コンカレントパラメータ２
                                   ,iv_conc_param2  => iv_custome_cd                -- コンカレントパラメータ２
                                   ,iv_conc_param3  => iv_invoice_cd                -- コンカレントパラメータ３
                                   ,iv_conc_param4  => iv_payment_cd                -- コンカレントパラメータ4
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
                                   ,iv_conc_param5  => iv_bill_pub_cycle                           -- コンカレントパラメータ５
-- Add 2010.12.10 Ver1.7 End
                                   ,ov_errbuf       => ov_errbuf                    -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode                   -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);                  -- ユーザー・エラー・メッセージ 
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.09.10 Ver1.3 Start
--
   -- パラメータの整合性チェックを行う。2つ以上入力されていた場合はエラー。
   IF ( iv_custome_cd IS NOT NULL ) THEN ln_count := ln_count + 1; END IF;  -- 顧客番号(顧客)
   IF ( iv_invoice_cd IS NOT NULL ) THEN ln_count := ln_count + 1; END IF;  -- 顧客番号(請求用)
   IF ( iv_payment_cd IS NOT NULL ) THEN ln_count := ln_count + 1; END IF;  -- 顧客番号(売掛管理先)
--
   IF ( ln_count > 1 ) THEN
     -- ログ出力
     lv_errmsg := SUBSTRB(
                    xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                             ,cv_msg_003a16_024 -- プロファイル取得エラー
                    )     
                   ,1
                   ,5000);
     RAISE global_api_expt;
   END IF;
--
-- Modify 2009.09.10 Ver1.3 End
  EXCEPTION
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
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := FND_PROFILE.VALUE(cv_set_of_bks_id);
--
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- 会計帳簿ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id      := FND_PROFILE.VALUE(cv_org_id);
--
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- 組織ID
                          ,1
                          ,5000);
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : chk_inv_all_dept
   * Description      : 全社出力権限チェック処理 (A-3)
   ***********************************************************************************/
  PROCEDURE chk_inv_all_dept(
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inv_all_dept'; -- プログラム名
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
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- 従業員マスタDFF名
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- 従業員マスタDFF28(所属部署)カラム名
--
    -- *** ローカル変数 ***
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; -- 所属部門取得エラー時のメッセージトークン値
    lv_valid_flag  VARCHAR2(1) := 'N'; -- 有効フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ログインユーザ所属部門取得処理
    gt_user_dept := xxcfr_common_pkg.get_user_dept(cn_created_by -- ユーザID
                                                  ,SYSDATE);     -- 取得日付
--
    -- 取得エラー時
    IF (gt_user_dept IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
--
    -- 全社出力権限所持部門判定処理
      lv_valid_flag := xxcfr_common_pkg.chk_invoice_all_dept(gt_user_dept      -- 所属部門コード
                                                            ,cv_invoice_type); -- 請求書タイプ
      IF lv_valid_flag = cv_enabled_yes THEN
        gv_inv_all_flag := '1';
      END IF;
--
  EXCEPTION
--
    -- *** 所属部門が取得できない場合 ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
        AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a16_017 -- 値取得エラー
                                                    ,cv_tkn_get_data   -- トークン'DATA'
                                                    ,lv_token_value)   -- 'ログインユーザ所属部門'
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END chk_inv_all_dept;
--
-- Modify 2009.09.10 Ver1.3 Start
  /**********************************************************************************
   * Procedure Name   : put_account_warning(A-8)
   * Description      : 顧客紐付け警告出力 (A-8)
   ***********************************************************************************/
  PROCEDURE put_account_warning(
    iv_customer_class_code  IN   VARCHAR2,            -- 顧客区分
    iv_customer_code        IN   VARCHAR2,            -- 顧客コード
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_account_warning'; -- プログラム名
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
    lv_data_msg  VARCHAR2(5000);        -- ログ出力メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
    -- 売掛管理先顧客存在なしメッセージ出力
    IF (iv_customer_class_code = cv_customer_class_code14) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a16_023
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- 請求書用顧客存在なしメッセージ出力
    ELSIF (iv_customer_class_code = cv_customer_class_code20) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a16_022
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    END IF;
--
    -- 顧客紐付け警告存在フラグを存在ありに変更する
    gv_warning_flag := cv_status_yes;
--
--###########################  固定部 END   ############################
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END put_account_warning;
--
-- Modify 2009.09.10 Ver1.3 End
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ワークテーブルデータ登録 (A-4)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--    iv_ar_code1             IN   VARCHAR2,            -- 売掛コード１(請求書)
    iv_custome_cd           IN   VARCHAR2,            -- 顧客番号(顧客)
    iv_invoice_cd           IN   VARCHAR2,            -- 顧客番号(請求用)
    iv_payment_cd           IN   VARCHAR2,            -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
    iv_bill_pub_cycle       IN   VARCHAR2,            -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- プログラム名
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
    -- 消費税区分
    cv_syohizei_kbn_te  CONSTANT VARCHAR2(1)  := '1';                      -- 外税
    cv_syohizei_kbn_nt  CONSTANT VARCHAR2(1)  := '4';                      -- 非課税
    -- 請求書出力区分
    cv_inv_prt_type     CONSTANT VARCHAR2(1)  := '1';                       -- 1.伊藤園標準
--
-- Modify 2009.09.10 Ver1.3 Start
    -- 部門
    cv_ffv_set_name_dept CONSTANT fnd_flex_value_sets.flex_value_set_name%TYPE := 'XX03_DEPARTMENT';
--
-- Modify 2009.09.10 Ver1.3 End
    -- *** ローカル変数 ***
    -- 書式整形用変数
    lv_format_date_jpymd4  VARCHAR2(25); -- YYYY"年"MM"月"DD"日"
    lv_format_date_jpymd2  VARCHAR2(25); -- YY"年"MM"月"DD"日"
    lv_format_date_year    VARCHAR2(10); -- 年
    lv_format_date_month   VARCHAR2(10); -- 月
    lv_format_date_bank    VARCHAR2(10); -- 銀行
    lv_format_date_central VARCHAR2(10); -- 本店
    lv_format_date_branch  VARCHAR2(10); -- 支店
    lv_format_date_account VARCHAR2(10); -- 普通
    lv_format_date_current VARCHAR2(10); -- 当座
    lv_format_zip_mark     VARCHAR2(10); -- 〒
    lv_format_bank_dummy   VARCHAR2(10); -- D%
--
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    lv_no_data_msg  VARCHAR2(5000); -- 帳票０件メッセージ
    lv_func_status  VARCHAR2(1);    -- SVF帳票共通関数(0件出力メッセージ)終了ステータス
--
    -- *** ローカル・カーソル ***
-- Modify 2009.09.10 Ver1.3 Start
    -- 顧客取得カーソルタイプ
    TYPE cursor_rec_type IS RECORD(customer_id           xxcmm_cust_accounts.customer_id%TYPE,           -- 顧客区分10顧客ID
                                   customer_code         xxcmm_cust_accounts.customer_code%TYPE,         -- 顧客区分10顧客コード
                                   invoice_printing_unit xxcmm_cust_accounts.invoice_printing_unit%TYPE, -- 顧客区分10請求書印刷単位
-- Add 2011.01.17 Ver1.8 Start
                                   store_code            xxcmm_cust_accounts.store_code%TYPE,            -- 店舗コード
-- Add 2011.01.17 Ver1.8 End
                                   bill_base_code        xxcmm_cust_accounts.bill_base_code%TYPE);       -- 顧客区分10請求拠点コード
    TYPE cursor_ref_type IS REF CURSOR;
    get_all_account_cur cursor_ref_type;
    all_account_rec cursor_rec_type;
    lr_main_data rtype_main_data;
-- Modify 2009.12.11 Ver1.5 Start
    lr_main_data2 rtype_main_data;  --単独店の売掛管理先チェック用
-- Modify 2009.12.11 Ver1.5 End
--
    -- 顧客10取得カーソル文字列
    cv_get_all_account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||            -- 顧客ID
    '       xxca.customer_code         AS customer_code, '||          -- 顧客コード
    '        xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.8 Start
    '       xxca.store_code            AS store_code, '||             -- 店舗コード
-- Add 2011.01.17 Ver1.8 End
    '        xxca.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    ' FROM xxcmm_cust_accounts xxca, '||                                     -- 顧客追加情報
    '      hz_cust_accounts    hzca '||                                      -- 顧客マスタ
    ' WHERE xxca.invoice_printing_unit IN ('''||cv_invoice_printing_unit_n1||''','||
                                          ''''||cv_invoice_printing_unit_n2||''','||
                                          ''''||cv_invoice_printing_unit_n3||''','||
                                          ''''||cv_invoice_printing_unit_n4||''') '|| -- 請求書印刷単位
    ' AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
    ' AND   xxca.customer_id = hzca.cust_account_id ';
--
    -- 顧客10取得カーソル文字列(売掛管理先顧客指定時)
    cv_get_14account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.8 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.8 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     hz_cust_accounts    hzca10, '||                                     -- 顧客10顧客マスタ
    '     hz_cust_acct_sites  hasa10, '||                                     -- 顧客10顧客所在地
    '     hz_cust_site_uses   hsua10, '||                                     -- 顧客10顧客使用目的
    '     hz_cust_accounts    hzca14, '||                                     -- 顧客14顧客マスタ
    '     hz_cust_acct_relate hcar14, '||                                     -- 顧客関連マスタ
    '     hz_cust_acct_sites  hasa14, '||                                     -- 顧客14顧客所在地
    '     hz_cust_site_uses   hsua14 '||                                      -- 顧客14顧客使用目的
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_n1||''','||
                                           ''''||cv_invoice_printing_unit_n2||''') '||   -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.account_number = :iv_customer_code14 '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
-- Add 2010.02.02 Ver1.6 Start
    'AND   hsua14.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010.02.02 Ver1.6 End
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
-- Add 2010.02.02 Ver1.6 Start
    'AND   hsua10.status = '''||cv_site_use_stat_act||''' '||
-- Add 2010.02.02 Ver1.6 End
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id ';
--
    -- 顧客10取得カーソル文字列(請求書用顧客指定時)
    cv_get_20account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.8 Start
    '       xxca10.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.8 End
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
    'WHERE xxca10.invoice_printing_unit = '''||cv_invoice_printing_unit_n3||''' '||    -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.customer_code = :iv_customer_code20 ';
--
    -- 顧客10取得カーソル文字列(顧客指定時)
    cv_get_10account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
-- Add 2011.01.17 Ver1.8 Start
    '       xxca.store_code            AS store_code, '||            -- 店舗コード
-- Add 2011.01.17 Ver1.8 End
    '       xxca.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca, '||                                     -- 顧客追加情報
    '     hz_cust_accounts    hzca '||                                      -- 顧客マスタ
    'WHERE xxca.invoice_printing_unit = '''||cv_invoice_printing_unit_n4||''' '||    -- 請求書印刷単位
    'AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||            -- 顧客区分:10
    'AND   xxca.customer_id = hzca.cust_account_id '||
    'AND   xxca.customer_code = :iv_customer_code10 ';
--
    -- 顧客10取得カーソル
    CURSOR get_10account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT bill_hzca_1.cust_account_id         AS cash_account_id,         --顧客10ID
            bill_hzca_1.account_number          AS cash_account_number,     --顧客10コード
-- Modify 2009.11.20 Ver1.4 Start
--            bill_hzpa_1.party_name              AS cash_account_name,       --顧客10顧客名
            bill_hzca_1.account_name            AS cash_account_name,       --顧客10顧客名
-- Modify 2009.11.20 Ver1.4 End
            bill_hzca_1.cust_account_id         AS ship_account_id,         --顧客10顧客ID        
            bill_hzca_1.account_number          AS ship_account_number,     --顧客10顧客コード 
            bill_hzad_1.bill_base_code          AS bill_base_code,          --顧客10請求拠点コード
            bill_hzlo_1.postal_code             AS bill_postal_code,        --顧客10郵便番号            
            bill_hzlo_1.state                   AS bill_state,              --顧客10都道府県            
            bill_hzlo_1.city                    AS bill_city,               --顧客10市・区              
            bill_hzlo_1.address1                AS bill_address1,           --顧客10住所1               
            bill_hzlo_1.address2                AS bill_address2,           --顧客10住所2
            bill_hzlo_1.address_lines_phonetic  AS phone_num,               --顧客10電話番号
            bill_hzad_1.tax_div                 AS bill_tax_div,            --顧客10消費税区分
            bill_hsua_1.attribute7              AS bill_invoice_type,       --顧客10請求書出力形式      
            bill_hsua_1.payment_term_id         AS bill_payment_term_id,    --顧客10支払条件
-- Add 2010.12.10 Ver1.7 Start
            bill_hsua_1.attribute8              AS bill_pub_cycle,          --顧客10請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
            bill_hcp.cons_inv_flag              AS cons_inv_flag            --一括請求書式
     FROM hz_cust_accounts          bill_hzca_1,              --顧客10顧客マスタ
          xxcmm_cust_accounts       bill_hzad_1,              --顧客10顧客追加情報
          hz_cust_acct_sites        bill_hasa_1,              --顧客10顧客所在地
          hz_locations              bill_hzlo_1,              --顧客10顧客事業所
          hz_cust_site_uses         bill_hsua_1,              --顧客10顧客使用目的
          hz_party_sites            bill_hzps_1,              --顧客10パーティサイト
          hz_parties                bill_hzpa_1,              --顧客10パーティ
          hz_customer_profiles      bill_hcp                  --顧客プロファイル
     WHERE bill_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code10        --顧客10顧客マスタ.顧客区分 = '10'(売掛管理先顧客)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --顧客10顧客マスタ.顧客ID = 顧客10顧客追加情報.顧客ID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --顧客10顧客マスタ.顧客ID = 顧客10顧客所在地.顧客ID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --顧客10顧客所在地.顧客所在地ID = 顧客10顧客使用目的.顧客所在地ID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --顧客10顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.02.02 Ver1.6 Start
     AND   bill_hsua_1.status = cv_site_use_stat_act                         --顧客10顧客使用目的.ステータス = 'A'
-- Add 2010.02.02 Ver1.6 End
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --顧客10顧客所在地.パーティサイトID = 顧客14パーティサイト.パーティサイトID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --顧客10パーティサイト.事業所ID = 顧客10顧客事業所.事業所ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id                       --顧客10顧客マスタ.パーティID = 顧客10.パーティID
     AND   bill_hsua_1.site_use_id = bill_hcp.site_use_id;                   --顧客10顧客使用目的.使用目的ID = 顧客プロファイル.使用目的ID
--
    -- 顧客14取得カーソル
    CURSOR get_14account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT bill_hzca_1.cust_account_id         AS cash_account_id,         --顧客14ID
            bill_hzca_1.account_number          AS cash_account_number,     --顧客14コード
            bill_hzpa_1.party_name              AS cash_account_name,       --顧客14顧客名
            ship_hzca_1.cust_account_id         AS ship_account_id,         --顧客10顧客ID        
            ship_hzca_1.account_number          AS ship_account_number,     --顧客10顧客コード 
            bill_hzad_1.bill_base_code          AS bill_base_code,          --顧客14請求拠点コード
            bill_hzlo_1.postal_code             AS bill_postal_code,        --顧客14郵便番号            
            bill_hzlo_1.state                   AS bill_state,              --顧客14都道府県            
            bill_hzlo_1.city                    AS bill_city,               --顧客14市・区              
            bill_hzlo_1.address1                AS bill_address1,           --顧客14住所1               
            bill_hzlo_1.address2                AS bill_address2,           --顧客14住所2
            bill_hzlo_1.address_lines_phonetic  AS phone_num,               --顧客14電話番号
            bill_hzad_1.tax_div                 AS bill_tax_div,            --顧客14消費税区分
            bill_hsua_1.attribute7              AS bill_invoice_type,       --顧客14請求書出力形式      
            bill_hsua_1.payment_term_id         AS bill_payment_term_id,    --顧客14支払条件
-- Add 2010.12.10 Ver1.7 Start
            bill_hsua_1.attribute8              AS bill_pub_cycle,          --顧客14請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
            bill_hcp.cons_inv_flag              AS cons_inv_flag            --一括請求書式
     FROM hz_cust_accounts          bill_hzca_1,              --顧客14顧客マスタ
          hz_cust_accounts          ship_hzca_1,              --顧客10顧客マスタ
          xxcmm_cust_accounts       bill_hzad_1,              --顧客14顧客追加情報
          hz_cust_acct_sites        bill_hasa_1,              --顧客14顧客所在地
          hz_locations              bill_hzlo_1,              --顧客14顧客事業所
          hz_cust_site_uses         bill_hsua_1,              --顧客14顧客使用目的
          hz_cust_acct_relate       bill_hcar_1,              --顧客関連マスタ(請求関連)
          hz_cust_acct_sites        ship_hasa_1,              --顧客10顧客所在地
          hz_cust_site_uses         ship_hsua_1,              --顧客10顧客使用目的
          hz_party_sites            bill_hzps_1,              --顧客14パーティサイト
          hz_parties                bill_hzpa_1,              --顧客14パーティ
          hz_customer_profiles      bill_hcp                  --顧客プロファイル
     WHERE ship_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --顧客14顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
     AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 顧客10顧客マスタ.顧客ID
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code14        --顧客14顧客マスタ.顧客区分 = '14'(売掛管理先顧客)
     AND   bill_hcar_1.status = cv_acct_relate_status                        --顧客関連マスタ.ステータス = ‘A’
     AND   bill_hcar_1.attribute1 = cv_acct_relate_type_bill                 --顧客関連マスタ.関連分類 = ‘1’ (請求)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --顧客14顧客マスタ.顧客ID = 顧客14顧客追加情報.顧客ID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --顧客14顧客マスタ.顧客ID = 顧客14顧客所在地.顧客ID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --顧客14顧客所在地.顧客所在地ID = 顧客14顧客使用目的.顧客所在地ID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --顧客14顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.02.02 Ver1.6 Start
     AND   bill_hsua_1.status = cv_site_use_stat_act                         --顧客14顧客使用目的.ステータス = 'A'
-- Add 2010.02.02 Ver1.6 End
     AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --顧客10顧客マスタ.顧客ID = 顧客10顧客所在地.顧客ID
     AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --顧客10顧客所在地.顧客所在地ID = 顧客10顧客使用目的.顧客所在地ID
     AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --顧客10顧客使用目的.請求先事業所ID = 顧客14顧客使用目的.使用目的ID
-- Add 2010.02.02 Ver1.6 Start
     AND   ship_hsua_1.status = cv_site_use_stat_act                         --顧客10顧客使用目的.ステータス = 'A'
-- Add 2010.02.02 Ver1.6 End
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --顧客14顧客所在地.パーティサイトID = 顧客14パーティサイト.パーティサイトID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --顧客14パーティサイト.事業所ID = 顧客14顧客事業所.事業所ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id                       --顧客14顧客マスタ.パーティID = 顧客14.パーティID
     AND   bill_hsua_1.site_use_id = bill_hcp.site_use_id;                   --顧客14顧客使用目的.使用目的ID = 顧客プロファイル.使用目的ID
--
    -- 顧客20取得カーソル
    CURSOR get_20account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT xxca20.customer_id             AS bill_account_id,         --顧客20ID
            xxca20.customer_code           AS bill_account_number,     --顧客20コード
            hzpa20.party_name              AS bill_account_name,       --顧客20顧客名
            xxca20.bill_base_code          AS bill_base_code,          --顧客20請求拠点コード
            hzlo20.postal_code             AS bill_postal_code,        --顧客20郵便番号
            hzlo20.state                   AS bill_state,              --顧客20都道府県
            hzlo20.city                    AS bill_city,               --顧客20市・区
            hzlo20.address1                AS bill_address1,           --顧客20住所1
            hzlo20.address2                AS bill_address2,           --顧客20住所2
            hzlo20.address_lines_phonetic  AS phone_num                --顧客20電話番号
     FROM xxcmm_cust_accounts       xxca20,                   --顧客20顧客追加情報
          xxcmm_cust_accounts       xxca10,                   --顧客10顧客追加情報
          hz_cust_accounts          hzca20,                   --顧客21顧客マスタ
          hz_parties                hzpa20,                   --顧客21パーティ
          hz_cust_acct_sites        hcas20,                   --顧客21顧客所在地
          hz_party_sites            hzps20,                   --顧客21パーティサイト
          hz_locations              hzlo20                    --顧客21顧客事業所
     WHERE xxca10.customer_id = iv_customer_id
     AND   hzca20.customer_class_code = cv_customer_class_code20  --顧客20顧客マスタ.顧客区分 = '20'(請求用)
     AND   xxca10.invoice_code = xxca20.customer_code       --顧客10顧客追加情報.請求書用コード = 顧客20顧客追加情報.顧客コード
     AND   hzca20.cust_account_id = xxca20.customer_id      --顧客21顧客マスタ.顧客ID = 顧客21顧客追加情報.顧客コード
     AND   hzca20.party_id = hzpa20.party_id                --顧客21顧客マスタ.パーティID = 顧客21パーティ.パーティID
     AND   hzca20.cust_account_id = hcas20.cust_account_id  --顧客21顧客マスタ.顧客ID = 顧客21所在地.顧客ID
     AND   hcas20.party_site_id = hzps20.party_site_id      --顧客所在地21.パーティサイト = 顧客21パーティサイト.顧客21パーティサイトID
     AND   hzps20.location_id = hzlo20.location_id;         --顧客21パーティサイト.事業所ID = 顧客21顧客事業所.事業所ID
--
    get_20account_rec get_20account_cur%ROWTYPE;
--
    -- 顧客10取得カーソル
    CURSOR get_10address_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT bill_hzca_1.cust_account_id         AS bill_account_id,         --顧客10顧客ID        
            bill_hzca_1.account_number          AS bill_account_number,     --顧客10顧客コード 
-- Modify 2009.11.20 Ver1.4 Start
--            bill_hzpa_1.party_name              AS bill_account_name,       --顧客20顧客名
            bill_hzca_1.account_name            AS bill_account_name,       --顧客10顧客名
-- Modify 2009.11.20 Ver1.4 End
            bill_hzad_1.bill_base_code          AS bill_base_code,          --顧客10請求拠点コード
            bill_hzlo_1.postal_code             AS bill_postal_code,        --顧客10郵便番号            
            bill_hzlo_1.state                   AS bill_state,              --顧客10都道府県            
            bill_hzlo_1.city                    AS bill_city,               --顧客10市・区              
            bill_hzlo_1.address1                AS bill_address1,           --顧客10住所1               
            bill_hzlo_1.address2                AS bill_address2,           --顧客10住所2
            bill_hzlo_1.address_lines_phonetic  AS phone_num                --顧客10電話番号
     FROM hz_cust_accounts          bill_hzca_1,              --顧客10顧客マスタ
          xxcmm_cust_accounts       bill_hzad_1,              --顧客10顧客追加情報
          hz_cust_acct_sites        bill_hasa_1,              --顧客10顧客所在地
          hz_locations              bill_hzlo_1,              --顧客10顧客事業所
          hz_cust_site_uses         bill_hsua_1,              --顧客10顧客使用目的
          hz_party_sites            bill_hzps_1,              --顧客10パーティサイト
          hz_parties                bill_hzpa_1               --顧客10パーティ
     WHERE bill_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code10        --顧客10顧客マスタ.顧客区分 = '10'(売掛管理先顧客)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --顧客10顧客マスタ.顧客ID = 顧客10顧客追加情報.顧客ID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --顧客10顧客マスタ.顧客ID = 顧客10顧客所在地.顧客ID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --顧客10顧客所在地.顧客所在地ID = 顧客10顧客使用目的.顧客所在地ID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --顧客10顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.02.02 Ver1.6 Start
     AND   bill_hsua_1.status = cv_site_use_stat_act                         --顧客10顧客使用目的.ステータス = 'A'
-- Add 2010.02.02 Ver1.6 End
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --顧客10顧客所在地.パーティサイトID = 顧客14パーティサイト.パーティサイトID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --顧客10パーティサイト.事業所ID = 顧客10顧客事業所.事業所ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id;                      --顧客10顧客マスタ.パーティID = 顧客10.パーティID
--
    get_10address_rec get_10address_cur%ROWTYPE;
-- Modify 2009.09.10 Ver1.3 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 日本語文字列取得
    -- ====================================================
    lv_format_date_jpymd4 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd4 )  -- YYYY"年"MM"月"DD"日"
                                    ,1
                                    ,5000);
    lv_format_date_jpymd2 := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                        ,cv_dict_ymd2 )  -- YY"年"MM"月"DD"日"
                                    ,1
                                    ,5000);
    lv_format_date_year := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_year )  -- 年
                                  ,1
                                  ,5000);
    lv_format_date_month := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr   -- 'XXCFR'
                                                                       ,cv_dict_month )  -- 月
                                   ,1
                                   ,5000);
    lv_format_date_bank := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                      ,cv_dict_bank )  -- 銀行
                                  ,1
                                  ,5000);
    lv_format_date_central := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_central )  -- 本店
                                     ,1
                                     ,5000);
    lv_format_date_branch := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                        ,cv_dict_branch )  -- 支店
                                     ,1
                                     ,5000);
    lv_format_date_account := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_account ) -- 普通
                                     ,1
                                     ,5000);
    lv_format_date_current := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr    -- 'XXCFR'
                                                                         ,cv_dict_current ) -- 当座
                                    ,1
                                    ,5000);
    lv_format_zip_mark := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                     ,cv_dict_zip_mark ) -- 〒
                                  ,1
                                  ,5000);
    lv_format_bank_dummy := SUBSTRB(xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr     -- 'XXCFR'
                                                                       ,cv_dict_bank_damy ) -- D
                                   ,1
                                   ,5000);
--
    -- ====================================================
    -- 帳票０件メッセージ取得
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                       ,cv_msg_003a16_014 ) -- 帳票０件メッセージ
                              ,1
                              ,5000);
--
    -- ====================================================
    -- ワークテーブルへの登録
    -- ====================================================
-- Modify 2009.09.10 Ver1.3 Start
    BEGIN
--
-- Modify 2009.12.11 Ver1.5 Start
      lr_main_data2     := NULL;  -- 初期化
-- Modify 2009.12.11 Ver1.5 End
      lr_main_data      := NULL;  -- 初期化
      all_account_rec   := NULL;  -- 初期化
      get_20account_rec := NULL;  -- 初期化
      get_10address_rec := NULL;  -- 初期化
--
      -- 売掛管理先顧客指定時
      IF (iv_payment_cd IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_14account_cur USING iv_payment_cd;
      -- 請求書用顧客指定時
      ELSIF (iv_invoice_cd IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_invoice_cd;
      -- 顧客指定時
      ELSIF (iv_custome_cd IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_custome_cd;
      -- パラメータ指定なし時
      ELSE
        OPEN get_all_account_cur FOR cv_get_all_account_cur;
      END IF;
--
      <<get_account10_loop>>
      LOOP 
        FETCH get_all_account_cur INTO all_account_rec;
        EXIT WHEN get_all_account_cur%NOTFOUND;
--
        -- 請求書印刷単位別に処理を判断する
        IF all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_n1,
                                                     cv_invoice_printing_unit_n2,
                                                     cv_invoice_printing_unit_n3) THEN
          -- 顧客区分14の顧客に紐づく、顧客区分14の顧客を取得
          OPEN get_14account_cur(all_account_rec.customer_id);
          FETCH get_14account_cur INTO lr_main_data;
          CLOSE get_14account_cur;
        ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n4) THEN
          -- 単独店を取得
          OPEN get_10account_cur(all_account_rec.customer_id);
          FETCH get_10account_cur INTO lr_main_data;
          CLOSE get_10account_cur;
-- Modify 2009.12.11 Ver1.5 Start
          -- 出荷先に紐付く売掛管理先が存在しているかチェックする。
          OPEN get_14account_cur(all_account_rec.customer_id);
          FETCH get_14account_cur INTO lr_main_data2;
          CLOSE get_14account_cur;
          -- 売掛管理先がいる時は、売掛管理先を見る。以下3点。
          IF ( lr_main_data2.cash_account_id IS NOT NULL ) THEN
            lr_main_data.bill_tax_div      := lr_main_data2.bill_tax_div;       -- 消費税区分
            lr_main_data.bill_invoice_type := lr_main_data2.bill_invoice_type;  -- 請求書印刷単位
            lr_main_data.cons_inv_flag     := lr_main_data2.cons_inv_flag;      -- 一括請求区分
-- Add 2010.12.10 Ver1.7 Start
            -- 請求書発行サイクルも売掛管理先から
            lr_main_data.bill_pub_cycle    := lr_main_data2.bill_pub_cycle;      -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
          END IF;
          -- 初期化
          lr_main_data2 := NULL;
-- Modify 2009.12.11 Ver1.5 End
        END IF;
--
        -- 紐づく顧客区分14の顧客が存在しない場合
        IF lr_main_data.cash_account_id IS NULL THEN
          -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合、且つ単独店以外
          IF ( ( all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_n1,
                                                           cv_invoice_printing_unit_n2,
                                                           cv_invoice_printing_unit_n3)
               )
           AND ( (all_account_rec.bill_base_code = gt_user_dept)
              OR (gv_inv_all_flag = cv_status_yes)
               )
          ) THEN
            -- 顧客区分14存在なしメッセージ出力
            put_account_warning(iv_customer_class_code => cv_customer_class_code14
                               ,iv_customer_code       => all_account_rec.customer_code
                               ,ov_errbuf              => lv_errbuf
                               ,ov_retcode             => lv_retcode
                               ,ov_errmsg              => lv_errmsg);
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              RAISE global_process_expt;
            END IF;
          END IF;
--
--      --請求書印刷単位 = 'N1'
--
        ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n1)
         AND  ((gv_inv_all_flag = cv_status_yes) OR 
               ((gv_inv_all_flag = cv_status_no) AND  (lr_main_data.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
         AND  (lr_main_data.bill_tax_div IN (cv_syohizei_kbn_te,cv_syohizei_kbn_nt))  -- 消費税区分 IN (外税,非課税)
         AND  (lr_main_data.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
         AND  (lr_main_data.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.7 Start
         AND  (lr_main_data.bill_pub_cycle = NVL(iv_bill_pub_cycle, lr_main_data.bill_pub_cycle))     -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.7 End
        THEN
          OPEN get_10address_cur(all_account_rec.customer_id);
          FETCH get_10address_cur INTO get_10address_rec;
          CLOSE get_10address_cur;
--
          INSERT INTO xxcfr_rep_st_invoice_ex_tax(
            report_id               , -- 帳票ＩＤ
            issue_date              , -- 発行日
            zip_code                , -- 郵便番号
            send_address1           , -- 住所１
            send_address2           , -- 住所２
            send_address3           , -- 住所３
            bill_cust_code          , -- 顧客コード(ソート順２)
            bill_cust_name          , -- 顧客名
            location_name           , -- 担当拠点名
            phone_num               , -- 電話番号
            target_date             , -- 対象年月
            payment_cust_code       , -- 入金先顧客コード
            payment_cust_name       , -- 入金先顧客名
            ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
            payment_due_date        , -- 入金予定日
            bank_account            , -- 振込口座情報
            ship_cust_code          , -- ★納品先顧客コード
            ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.8 Start
            bill_account_number     , -- 請求顧客コード(ソート用)
            store_code              , -- 店舗コード(ソート用)
-- Add 2011.01.17 Ver1.8 End
            slip_date               , -- 伝票日付(ソート順３)
            slip_num                , -- 伝票No(ソート順４)
            slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
            ship_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
            data_empty_message      , -- 0件メッセージ
            created_by              , -- 作成者
            creation_date           , -- 作成日
            last_updated_by         , -- 最終更新者
            last_update_date        , -- 最終更新日
            last_update_login       , -- 最終更新ログイン
            request_id              , -- 要求ID
            program_application_id  , -- アプリケーションID
            program_id              , -- コンカレント・プログラムID
            program_update_date     ) -- プログラム更新日
          SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                 TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                 DECODE(get_10address_rec.bill_postal_code,
                        NULL,NULL,
                        lv_format_zip_mark||SUBSTR(get_10address_rec.bill_postal_code,1,3)||'-'||
                        SUBSTR(get_10address_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                 get_10address_rec.bill_state||get_10address_rec.bill_city                  send_address1    , -- 住所１
                 get_10address_rec.bill_address1                                        send_address2    , -- 住所２
                 get_10address_rec.bill_address2                                        send_address3    , -- 住所３
                 get_10address_rec.bill_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                 get_10address_rec.bill_account_name                                    bill_cust_name   , -- 顧客名
                 xffvv.description                                                  location_name    , -- 担当拠点名
                 xxcfr_common_pkg.get_base_target_tel_num(lr_main_data.cash_account_number)   phone_num        , -- 電話番号
                 SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                 SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                 lr_main_data.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                 lr_main_data.cash_account_name                                payment_cust_name, -- 入金先顧客名
-- Add 2011.01.17 Ver1.8 Start
--                 get_10address_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                 get_10address_rec.bill_account_number   ||' '
               ||LPAD(NVL(all_account_rec.store_code,'0'),10,'0') ||' '
               ||xih.term_name                                                      ar_concat_text   , -- 売掛管理コード連結文字列
-- Add 2011.01.17 Ver1.8 End
                 TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                 CASE
                 WHEN account.bank_account_num IS NULL THEN
                   NULL
                 ELSE
                   DECODE(SUBSTR(account.bank_number,1,1),
                   lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                   CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                     CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                       account.bank_name
                     ELSE
                       account.bank_name ||lv_format_date_bank
                     END
                   ELSE
                    account.bank_name 
                   END||' '||                                                       -- 銀行名
                   CASE WHEN INSTR(account.bank_branch_name
                                  ,lv_format_date_central)>0 THEN
                     account.bank_branch_name
                   ELSE
                     account.bank_branch_name||lv_format_date_branch 
                   END||' '||                                                       -- 支店名
                   DECODE( account.bank_account_type,
                           1,lv_format_date_account,
                           2,lv_format_date_current,
                           account.bank_account_type) ||' '||                       -- 口座種別
                   account.bank_account_num ||' '||                                 -- 口座番号
                   account.account_holder_name||' '||                               -- 口座名義人
                   account.account_holder_name_alt)                                 -- 口座名義人カナ名
                 END                                                                account_data     , -- 振込口座情報
                 xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                 hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.8 Start
                 NULL                                                               bill_account_number,  -- 請求顧客コード(ソート用)
                 LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code       , -- 店舗コード(ソート用)
-- Add 2011.01.17 Ver1.8 End
                 TO_CHAR(DECODE(xil.acceptance_date,
                                NULL,xil.delivery_date,
                                xil.acceptance_date),
                         cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                 xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                 SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                 SUM(xil.tax_amount)                                                ship_tax_sum     , -- 税金額
                 NULL                                                               data_empty_message,-- 0件メッセージ
                 cn_created_by                                                      created_by,             -- 作成者
                 cd_creation_date                                                   creation_date,          -- 作成日
                 cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                 cd_last_update_date                                                last_update_date,       -- 最終更新日
                 cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                 cn_request_id                                                      request_id,             -- 要求ID
                 cn_program_application_id                                          program_application_id, -- アプリケーションID
                 cn_program_id                                                      program_id,
                                                                                    -- コンカレント・プログラムID
                 cd_program_update_date                                             program_update_date     -- プログラム更新日
          FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
               xxcfr_invoice_lines            xil  , -- 請求明細
               hz_cust_accounts               hzca , -- 顧客10顧客マスタ
               hz_parties                     hzp  , -- 顧客10パーティマスタ
               (SELECT all_account_rec.customer_code ship_cust_code,
                       rcrm.customer_id             customer_id,
                       abb.bank_number              bank_number,
                       abb.bank_name                bank_name,
                       abb.bank_branch_name         bank_branch_name,
                       abaa.bank_account_type       bank_account_type,
                       abaa.bank_account_num        bank_account_num,
                       abaa.account_holder_name     account_holder_name,
                       abaa.account_holder_name_alt account_holder_name_alt
                FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                     ar_receipt_method_accounts_all arma , --AR支払方法口座
                     ap_bank_accounts_all           abaa , --銀行口座
                     ap_bank_branches               abb    --銀行支店
                WHERE rcrm.primary_flag = cv_enabled_yes
                  AND lr_main_data.cash_account_id = rcrm.customer_id
                  AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                  AND rcrm.site_use_id IS NOT NULL
                  AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                  AND arma.bank_account_id = abaa.bank_account_id(+)
                  AND abaa.bank_branch_id = abb.bank_branch_id(+)
                  AND arma.org_id = gn_org_id
                  AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
               (SELECT flex_value,
                       description
                FROM   fnd_flex_values_vl ffv
                WHERE  EXISTS
                       (SELECT  'X'
                        FROM    fnd_flex_value_sets
                        WHERE   flex_value_set_name = cv_ffv_set_name_dept
                        AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
          WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
            AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
            AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
            AND xih.set_of_books_id = gn_set_of_bks_id
            AND xih.org_id = gn_org_id
            AND lr_main_data.bill_base_code = xffvv.flex_value
            AND xil.ship_cust_code = all_account_rec.customer_code
            AND hzca.cust_account_id = all_account_rec.customer_id
            AND hzp.party_id = hzca.party_id
          GROUP BY cv_pkg_name,
                   xih.inv_creation_date,
                   DECODE(get_10address_rec.bill_postal_code,
                               NULL,NULL,
                               lv_format_zip_mark||SUBSTR(get_10address_rec.bill_postal_code,1,3)||'-'||
                               SUBSTR(get_10address_rec.bill_postal_code,4,4)),
                   get_10address_rec.bill_state||get_10address_rec.bill_city,
                   get_10address_rec.bill_address1,
                   get_10address_rec.bill_address2,
                   get_10address_rec.bill_account_number,
                   get_10address_rec.bill_account_name,
                   xffvv.description,
                   xih.object_month,
                   lr_main_data.cash_account_number,
                   lr_main_data.cash_account_name,
-- Add 2011.01.17 Ver1.8 Start
--                   get_10address_rec.bill_account_number||' '||xih.term_name,
                 get_10address_rec.bill_account_number   ||' '
               ||LPAD(NVL(all_account_rec.store_code,'0'),10,'0') ||' '
               ||xih.term_name,
-- Add 2011.01.17 Ver1.8 End
                   xih.payment_date,
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END,
                   xil.ship_cust_code,
                   hzp.party_name,
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                   cv_format_date_ymds2),
                   xil.slip_num;
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          --請求書印刷単位 = 'N2','N4'
          ELSIF (all_account_rec.invoice_printing_unit IN(cv_invoice_printing_unit_n2,cv_invoice_printing_unit_n4))
           AND  ((gv_inv_all_flag = cv_status_yes) OR 
                 ((gv_inv_all_flag = cv_status_no) AND  (lr_main_data.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
           AND  (lr_main_data.bill_tax_div IN (cv_syohizei_kbn_te,cv_syohizei_kbn_nt))  -- 消費税区分 IN (外税,非課税)
           AND  (lr_main_data.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
         AND  (lr_main_data.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.7 Start
         AND  (lr_main_data.bill_pub_cycle = NVL(iv_bill_pub_cycle, lr_main_data.bill_pub_cycle))     -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.7 End
          THEN
            INSERT INTO xxcfr_rep_st_invoice_ex_tax(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 入金先顧客コード
              payment_cust_name       , -- 入金先顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- ★納品先顧客コード
              ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.8 Start
              bill_account_number     , -- 請求顧客コード(ソート用)
              store_code              , -- 店舗コード(ソート用)
-- Add 2011.01.17 Ver1.8 End
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              ship_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
              data_empty_message      , -- 0件メッセージ
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                   DECODE(lr_main_data.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(lr_main_data.bill_postal_code,1,3)||'-'||
                          SUBSTR(lr_main_data.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                   lr_main_data.bill_state||lr_main_data.bill_city                  send_address1    , -- 住所１
                   lr_main_data.bill_address1                                        send_address2    , -- 住所２
                   lr_main_data.bill_address2                                        send_address3    , -- 住所３
                   lr_main_data.cash_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                   lr_main_data.cash_account_name                                    bill_cust_name   , -- 顧客名
                   xffvv.description                                                  location_name    , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(lr_main_data.cash_account_number)  phone_num        , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                   lr_main_data.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                   lr_main_data.cash_account_name                                payment_cust_name, -- 入金先顧客名
                   lr_main_data.cash_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                account_data     , -- 振込口座情報
-- Modify 2011.03.10 Ver1.9 Start
--                  xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                   DECODE(all_account_rec.invoice_printing_unit
                         ,cv_invoice_printing_unit_n2                 -- 請求書印刷単位が３の場合は、ソート順としない。
                         ,NULL
                         ,xil.ship_cust_code
                   )                                                                  ship_cust_code   , -- 納品先顧客コード
-- Modify 2011.03.10 Ver1.9 End
                   hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.8 Start
                   DECODE(all_account_rec.invoice_printing_unit
                         ,cv_invoice_printing_unit_n2  -- 請求先顧客が住所である時は、ソート順に考慮する。
                         ,lr_main_data.cash_account_number
                         ,NULL                         -- 単独店である時は、ソート順に考慮しない。(店舗コードが1番目となる)
                   )                                                                  bill_account_number,  -- 請求顧客コード(ソート順)
-- Modify 2011.03.10 Ver1.9 Start
--                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code       , -- 店舗コード(ソート用)
                   DECODE(all_account_rec.invoice_printing_unit
                         ,cv_invoice_printing_unit_n2                 -- 請求書印刷単位が３の場合は、ソート順としない。
                         ,NULL
                         ,LPAD(NVL(all_account_rec.store_code,'0'),10,'0')
                   )                                                                  store_code       , -- 店舗コード(ソート用)
-- Modify 2011.03.10 Ver1.9 End
-- Add 2011.01.17 Ver1.8 End
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                   xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                ship_tax_sum     , -- 税金額
                   NULL                                                               data_empty_message,-- 0件メッセージ
                   cn_created_by                                                      created_by,             -- 作成者
                   cd_creation_date                                                   creation_date,          -- 作成日
                   cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                   cd_last_update_date                                                last_update_date,       -- 最終更新日
                   cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                   cn_request_id                                                      request_id,             -- 要求ID
                   cn_program_application_id                                          program_application_id, -- アプリケーションID
                   cn_program_id                                                      program_id,
                                                                                      -- コンカレント・プログラムID
                   cd_program_update_date                                             program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND lr_main_data.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT flex_value,
                         description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets
                          WHERE   flex_value_set_name = cv_ffv_set_name_dept
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
            WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND lr_main_data.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(lr_main_data.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(lr_main_data.bill_postal_code,1,3)||'-'||
                                 SUBSTR(lr_main_data.bill_postal_code,4,4)),
                     lr_main_data.bill_state||lr_main_data.bill_city,
                     lr_main_data.bill_address1,
                     lr_main_data.bill_address2,
                     lr_main_data.cash_account_number,
                     lr_main_data.cash_account_name,
                     xffvv.description,
                     xih.object_month,
                     lr_main_data.cash_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num;
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
        --請求書印刷単位 = 'N3'
        ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n3)
         AND  (lr_main_data.bill_tax_div IN (cv_syohizei_kbn_te,cv_syohizei_kbn_nt))  -- 消費税区分 IN (外税,非課税)
         AND  (lr_main_data.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 1.伊藤園標準
         AND  (lr_main_data.cons_inv_flag = cv_enabled_yes) -- 一括請求書式 = 'Y'(有効)
-- Add 2010.12.10 Ver1.7 Start
         AND  (lr_main_data.bill_pub_cycle = NVL(iv_bill_pub_cycle, lr_main_data.bill_pub_cycle))     -- 請求書発行サイクル = 入力パラメータ「請求書発行サイクル」
-- Add 2010.12.10 Ver1.7 End
        THEN
          OPEN get_20account_cur(all_account_rec.customer_id);
          FETCH get_20account_cur INTO get_20account_rec;
          CLOSE get_20account_cur;
--
          --顧客区分20の顧客が存在しない場合
          IF get_20account_rec.bill_account_id IS NULL THEN
            -- 全社出力権限部門の場合と、該当顧客の請求拠点がログインユーザの所属部門と一致する場合
            IF (all_account_rec.bill_base_code = gt_user_dept)
            OR (gv_inv_all_flag = cv_status_yes)
            THEN
              -- 顧客区分20存在なしメッセージ出力
              
              put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                 ,iv_customer_code       => all_account_rec.customer_code
                                 ,ov_errbuf              => lv_errbuf
                                 ,ov_retcode             => lv_retcode
                                 ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                RAISE global_process_expt;
              END IF;
            END IF;
          ELSIF ((gv_inv_all_flag = cv_status_yes) OR 
                ((gv_inv_all_flag = cv_status_no) AND  (get_20account_rec.bill_base_code = gt_user_dept)))  -- 請求拠点 = ログインユーザの拠点
          THEN
            INSERT INTO xxcfr_rep_st_invoice_ex_tax(
              report_id               , -- 帳票ＩＤ
              issue_date              , -- 発行日
              zip_code                , -- 郵便番号
              send_address1           , -- 住所１
              send_address2           , -- 住所２
              send_address3           , -- 住所３
              bill_cust_code          , -- 顧客コード(ソート順２)
              bill_cust_name          , -- 顧客名
              location_name           , -- 担当拠点名
              phone_num               , -- 電話番号
              target_date             , -- 対象年月
              payment_cust_code       , -- 入金先顧客コード
              payment_cust_name       , -- 入金先顧客名
              ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
              payment_due_date        , -- 入金予定日
              bank_account            , -- 振込口座情報
              ship_cust_code          , -- ★納品先顧客コード
              ship_cust_name          , -- ★納品先顧客名
-- Add 2011.01.17 Ver1.8 Start
              bill_account_number     , -- 請求顧客コード(ソート用)
              store_code              , -- 店舗コード(ソート用)
-- Add 2011.01.17 Ver1.8 End
              slip_date               , -- 伝票日付(ソート順３)
              slip_num                , -- 伝票No(ソート順４)
              slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
              ship_tax_sum            , -- 伝票税額(伝票番号単位で集計した値)
              data_empty_message      , -- 0件メッセージ
              created_by              , -- 作成者
              creation_date           , -- 作成日
              last_updated_by         , -- 最終更新者
              last_update_date        , -- 最終更新日
              last_update_login       , -- 最終更新ログイン
              request_id              , -- 要求ID
              program_application_id  , -- アプリケーションID
              program_id              , -- コンカレント・プログラムID
              program_update_date     ) -- プログラム更新日
            SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
                   TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
                   DECODE(get_20account_rec.bill_postal_code,
                          NULL,NULL,
                          lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                          SUBSTR(get_20account_rec.bill_postal_code,4,4))                 zip_code         , -- 郵便番号
                   get_20account_rec.bill_state||get_20account_rec.bill_city              send_address1    , -- 住所１
                   get_20account_rec.bill_address1                                        send_address2    , -- 住所２
                   get_20account_rec.bill_address2                                        send_address3    , -- 住所３
                   get_20account_rec.bill_account_number                                  bill_cust_code   , -- 顧客コード(ソート順２)
                   get_20account_rec.bill_account_name                                    bill_cust_name   , -- 顧客名
                   xffvv.description                                                  location_name    , -- 担当拠点名
                   xxcfr_common_pkg.get_base_target_tel_num(get_20account_rec.bill_account_number)   phone_num        , -- 電話番号
                   SUBSTR(xih.object_month,1,4)||lv_format_date_year||
                   SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
                   lr_main_data.cash_account_number                              payment_cust_code, -- 入金先顧客コード
                   lr_main_data.cash_account_name                                payment_cust_name, -- 入金先顧客名
                   get_20account_rec.bill_account_number||' '||xih.term_name          ar_concat_text   , -- 売掛管理コード連結文字列
                   TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
                   CASE
                   WHEN account.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(account.bank_number,1,1),
                     lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                     CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                       CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                         account.bank_name
                       ELSE
                         account.bank_name ||lv_format_date_bank
                       END
                     ELSE
                      account.bank_name 
                     END||' '||                                                       -- 銀行名
                     CASE WHEN INSTR(account.bank_branch_name
                                    ,lv_format_date_central)>0 THEN
                       account.bank_branch_name
                     ELSE
                       account.bank_branch_name||lv_format_date_branch 
                     END||' '||                                                       -- 支店名
                     DECODE( account.bank_account_type,
                             1,lv_format_date_account,
                             2,lv_format_date_current,
                             account.bank_account_type) ||' '||                       -- 口座種別
                     account.bank_account_num ||' '||                                 -- 口座番号
                     account.account_holder_name||' '||                               -- 口座名義人
                     account.account_holder_name_alt)                                 -- 口座名義人カナ名
                   END                                                                account_data     , -- 振込口座情報
-- Modify 2011.03.10 Ver1.9 Start
--                   xil.ship_cust_code                                                 ship_cust_code   , -- 納品先顧客コード
                   NULL                                                               ship_cust_code   , -- 納品先顧客コード
-- Modify 2011.03.10 Ver1.9 End
                   hzp.party_name                                                     ship_cust_name   , -- 納品先顧客名
-- Add 2011.01.17 Ver1.8 Start
                   get_20account_rec.bill_account_number                              bill_account_number,  -- 請求顧客コード(ソート順)
-- Modify 2011.03.10 Ver1.9 Start
--                   LPAD(NVL(all_account_rec.store_code,'0'),10,'0')                   store_code       , -- 店舗コード(ソート用)
                   NULL                                                               store_code       , -- 店舗コード(ソート用)
-- Modify 2011.03.10 Ver1.9 End
-- Add 2011.01.17 Ver1.8 End
                   TO_CHAR(DECODE(xil.acceptance_date,
                                  NULL,xil.delivery_date,
                                  xil.acceptance_date),
                           cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
                   xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
                   SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
                   SUM(xil.tax_amount)                                                ship_tax_sum     , -- 税金額
                   NULL                                                               data_empty_message,-- 0件メッセージ
                   cn_created_by                                                      created_by,             -- 作成者
                   cd_creation_date                                                   creation_date,          -- 作成日
                   cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
                   cd_last_update_date                                                last_update_date,       -- 最終更新日
                   cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
                   cn_request_id                                                      request_id,             -- 要求ID
                   cn_program_application_id                                          program_application_id, -- アプリケーションID
                   cn_program_id                                                      program_id,
                                                                                      -- コンカレント・プログラムID
                   cd_program_update_date                                             program_update_date     -- プログラム更新日
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code,
                         rcrm.customer_id             customer_id,
                         abb.bank_number              bank_number,
                         abb.bank_name                bank_name,
                         abb.bank_branch_name         bank_branch_name,
                         abaa.bank_account_type       bank_account_type,
                         abaa.bank_account_num        bank_account_num,
                         abaa.account_holder_name     account_holder_name,
                         abaa.account_holder_name_alt account_holder_name_alt
                  FROM ra_cust_receipt_methods        rcrm , --支払方法情報
                       ar_receipt_method_accounts_all arma , --AR支払方法口座
                       ap_bank_accounts_all           abaa , --銀行口座
                       ap_bank_branches               abb    --銀行支店
                  WHERE rcrm.primary_flag = cv_enabled_yes
                    AND lr_main_data.cash_account_id = rcrm.customer_id
                    AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
                    AND rcrm.site_use_id IS NOT NULL
                    AND rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND arma.bank_account_id = abaa.bank_account_id(+)
                    AND abaa.bank_branch_id = abb.bank_branch_id(+)
                    AND arma.org_id = gn_org_id
                    AND abaa.org_id = gn_org_id             ) account,    -- 銀行口座ビュー
                 (SELECT flex_value,
                         description
                  FROM   fnd_flex_values_vl ffv
                  WHERE  EXISTS
                         (SELECT  'X'
                          FROM    fnd_flex_value_sets
                          WHERE   flex_value_set_name = cv_ffv_set_name_dept
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv
            WHERE xih.invoice_id = xil.invoice_id                        -- 一括請求書ID
              AND xil.cutoff_date = gd_target_date                       -- パラメータ．締日
              AND xil.ship_cust_code = account.ship_cust_code(+)         -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND get_20account_rec.bill_base_code = xffvv.flex_value
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
            GROUP BY cv_pkg_name,
                     xih.inv_creation_date,
                     DECODE(get_20account_rec.bill_postal_code,
                                 NULL,NULL,
                                 lv_format_zip_mark||SUBSTR(get_20account_rec.bill_postal_code,1,3)||'-'||
                                 SUBSTR(get_20account_rec.bill_postal_code,4,4)),
                     get_20account_rec.bill_state||get_20account_rec.bill_city,
                     get_20account_rec.bill_address1,
                     get_20account_rec.bill_address2,
                     get_20account_rec.bill_account_number,
                     get_20account_rec.bill_account_name,
                     xffvv.description,
                     xih.object_month,
                     lr_main_data.cash_account_number,
                     lr_main_data.cash_account_name,
                     get_20account_rec.bill_account_number||' '||xih.term_name,
                     xih.payment_date,
                     CASE
                     WHEN account.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(account.bank_number,1,1),
                       lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
                       CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
                         CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
                           account.bank_name
                         ELSE
                           account.bank_name ||lv_format_date_bank
                         END
                       ELSE
                        account.bank_name 
                       END||' '||                                                       -- 銀行名
                       CASE WHEN INSTR(account.bank_branch_name
                                      ,lv_format_date_central)>0 THEN
                         account.bank_branch_name
                       ELSE
                         account.bank_branch_name||lv_format_date_branch 
                       END||' '||                                                       -- 支店名
                       DECODE( account.bank_account_type,
                               1,lv_format_date_account,
                               2,lv_format_date_current,
                               account.bank_account_type) ||' '||                       -- 口座種別
                       account.bank_account_num ||' '||                                 -- 口座番号
                       account.account_holder_name||' '||                               -- 口座名義人
                       account.account_holder_name_alt)                                 -- 口座名義人カナ名
                     END,
                     xil.ship_cust_code,
                     hzp.party_name,
                     TO_CHAR(DECODE(xil.acceptance_date,
                                    NULL,xil.delivery_date,
                                    xil.acceptance_date),
                     cv_format_date_ymds2),
                     xil.slip_num;
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          ELSE
            NULL;
          END IF;
--
        ELSE
          NULL;
        END IF;
--
        lr_main_data      := NULL;  -- 初期化
        all_account_rec   := NULL;  -- 初期化
        get_20account_rec := NULL;  -- 初期化
        get_10address_rec := NULL;  -- 初期化
--
      END LOOP get_account10_loop;
--    BEGIN
----
--      INSERT INTO xxcfr_rep_st_invoice_ex_tax(
--        report_id               , -- 帳票ＩＤ
--        issue_date              , -- 発行日
--        zip_code                , -- 郵便番号
--        send_address1           , -- 住所１
--        send_address2           , -- 住所２
--        send_address3           , -- 住所３
--        bill_cust_code          , -- 顧客コード(ソート順２)
--        bill_cust_name          , -- 顧客名
--        location_name           , -- 担当拠点名
--        phone_num               , -- 電話番号
--        target_date             , -- 対象年月
--        payment_cust_code       , -- 売掛コード１（請求書）(ソート順１)
--        ar_concat_text          , -- 売掛管理コード連結文字列(各項目の間にスペースを挿入)
--        ex_tax_charge           , -- 当月お買上げ額
--        tax_sum                 , -- 消費税等
--        total_charge            , -- 当月請求額(税込) 
--        payment_due_date        , -- 入金予定日
--        bank_account            , -- 振込口座情報
--        slip_date               , -- 伝票日付(ソート順３)
--        slip_num                , -- 伝票No(ソート順４)
--        slip_sum                , -- 伝票金額(伝票番号単位で集計した値)
--        data_empty_message      , -- 0件メッセージ
--        created_by              , -- 作成者
--        creation_date           , -- 作成日
--        last_updated_by         , -- 最終更新者
--        last_update_date        , -- 最終更新日
--        last_update_login       , -- 最終更新ログイン
--        request_id              , -- 要求ID
--        program_application_id  , -- アプリケーションID
--        program_id              , -- コンカレント・プログラムID
--        program_update_date     ) -- プログラム更新日
--      SELECT cv_pkg_name                                                        report_id        , -- 帳票ＩＤ
--             TO_CHAR(xih.inv_creation_date,lv_format_date_jpymd4)               issue_date       , -- 発行日
--             DECODE(xih.postal_code,
--                    NULL,NULL,
--                    lv_format_zip_mark||SUBSTR(xih.postal_code,1,3)||'-'||
--                    SUBSTR(xih.postal_code,4,4))                                zip_code         , -- 郵便番号
--             xih.send_address1                                                  send_address1    , -- 住所１
--             xih.send_address2                                                  send_address2    , -- 住所２
--             xih.send_address3                                                  send_address3    , -- 住所３
--             xih.bill_cust_code                                                 bill_cust_code   , -- 顧客コード(ソート順２)
--             xih.send_to_name                                                   bill_cust_name   , -- 顧客名
--             xih.bill_location_name                                             location_name    , -- 担当拠点名
--             xih.agent_tel_num                                                  phone_num        , -- 電話番号
--             SUBSTR(xih.object_month,1,4)||lv_format_date_year||
--             SUBSTR(xih.object_month,5,2)||lv_format_date_month                 target_date      , -- 対象年月
--             xih.payment_cust_code                                              payment_cust_code,
--                                                                                -- 売掛コード１（請求書）(ソート順１)
--             xih.payment_cust_code||' '||xih.bill_cust_code||' '||xih.term_name ar_concat_text   ,
--                                                                                -- 売掛管理コード連結文字列
--             xih.inv_amount_no_tax                                              ex_tax_charge    , -- 税抜請求金額合計
--             xih.tax_amount_sum                                                 tax_sum          , -- 税額合計
--             xih.inv_amount_includ_tax                                          total_charge     , -- 当月請求額(税込)
--             TO_CHAR(xih.payment_date, lv_format_date_jpymd2)                   payment_due_date , -- 入金予定日
--             CASE
--             WHEN account.bank_account_num IS NULL THEN
--               NULL
--             ELSE
--               DECODE(SUBSTR(account.bank_number,1,1),
--               lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
--               CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
--                 CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
--                   account.bank_name
--                 ELSE
--                   account.bank_name ||lv_format_date_bank
--                 END
--               ELSE
--                account.bank_name 
--               END||' '||                                                       -- 銀行名
--               CASE WHEN INSTR(account.bank_branch_name
--                              ,lv_format_date_central)>0 THEN
--                 account.bank_branch_name
--               ELSE
--                 account.bank_branch_name||lv_format_date_branch 
--               END||' '||                                                       -- 支店名
--               DECODE( account.bank_account_type,
--                       1,lv_format_date_account,
--                       2,lv_format_date_current,
--                       account.bank_account_type) ||' '||                       -- 口座種別
--               account.bank_account_num ||' '||                                 -- 口座番号
--               account.account_holder_name||' '||                               -- 口座名義人
--               account.account_holder_name_alt)                                 -- 口座名義人カナ名
--             END                                                                account_data     , -- 振込口座情報
--             TO_CHAR(DECODE(xil.acceptance_date,
--                            NULL,xil.delivery_date,
--                            xil.acceptance_date),
--                     cv_format_date_ymds2)                                      slip_date        , -- 伝票日付(ソート順３)
--             xil.slip_num                                                       slip_num         , -- 伝票No(ソート順４)
--             SUM(xil.ship_amount)                                               slip_sum         , -- 伝票金額(税抜額)
--             NULL                                                               data_empty_message,-- 0件メッセージ
--             cn_created_by                                                      created_by,             -- 作成者
--             cd_creation_date                                                   creation_date,          -- 作成日
--             cn_last_updated_by                                                 last_updated_by,        -- 最終更新者
--             cd_last_update_date                                                last_update_date,       -- 最終更新日
--             cn_last_update_login                                               last_update_login,      -- 最終更新ログイン
--             cn_request_id                                                      request_id,             -- 要求ID
--             cn_program_application_id                                          program_application_id, -- アプリケーションID
--             cn_program_id                                                      program_id,
--                                                                                -- コンカレント・プログラムID
--             cd_program_update_date                                             program_update_date     -- プログラム更新日
--      FROM xxcfr_invoice_headers          xih  , --請求ヘッダ
--           xxcfr_invoice_lines            xil  , -- 請求明細
--           (SELECT rcrm.customer_id             customer_id,
--                   abb.bank_number              bank_number,
--                   abb.bank_name                bank_name,
--                   abb.bank_branch_name         bank_branch_name,
--                   abaa.bank_account_type       bank_account_type,
--                   abaa.bank_account_num        bank_account_num,
--                   abaa.account_holder_name     account_holder_name,
--                   abaa.account_holder_name_alt account_holder_name_alt
--            FROM ra_cust_receipt_methods        rcrm , --支払方法情報
--                 ar_receipt_method_accounts_all arma , --AR支払方法口座
--                 ap_bank_accounts_all           abaa , --銀行口座
--                 ap_bank_branches               abb    --銀行支店
--            WHERE rcrm.primary_flag = cv_enabled_yes
--              AND gd_target_date BETWEEN rcrm.start_date AND NVL(rcrm.end_date ,cd_max_date)
--              AND rcrm.site_use_id IS NOT NULL
--              AND rcrm.receipt_method_id = arma.receipt_method_id(+)
--              AND arma.bank_account_id = abaa.bank_account_id(+)
--              AND abaa.bank_branch_id = abb.bank_branch_id(+)
--              AND arma.org_id = gn_org_id
--              AND abaa.org_id = gn_org_id             ) account , -- 銀行口座ビュー
--           xxcfr_bill_customers_v         xbcv                    --請求先顧客ビュー
--      WHERE xih.invoice_id = xil.invoice_id                       -- 一括請求書ID
--        AND xih.cutoff_date = gd_target_date                      -- パラメータ．締日
--        AND EXISTS (SELECT 'X'
--                    FROM xxcfr_bill_customers_v         xb        --請求先顧客ビュー
--                    WHERE xih.bill_cust_code = xb.bill_customer_code
--                      AND (xb.tax_div = cv_syohizei_kbn_te OR
--                           xb.tax_div = cv_syohizei_kbn_nt)       -- 外税OR非課税
--                      AND xb.inv_prt_type = cv_inv_prt_type       -- 1.伊藤園標準
--                      AND xb.cons_inv_flag = cv_enabled_yes       -- (有効)
--                      AND (xb.receiv_code1 = NVL(iv_ar_code1,xb.receiv_code1 ) )
--                      AND ( (gv_inv_all_flag = cv_status_yes) OR
--                            (gv_inv_all_flag = cv_status_no AND
--                             xb.bill_base_code = gt_user_dept) ) )
--        AND xih.bill_cust_code = xbcv.bill_customer_code
--        AND xbcv.pay_customer_id = account.customer_id(+)
--        AND xih.set_of_books_id = gn_set_of_bks_id
--        AND xih.org_id = gn_org_id
--      GROUP BY cv_pkg_name,
--               xih.inv_creation_date,
--               DECODE(xih.postal_code,
--                           NULL,NULL,
--                           lv_format_zip_mark||SUBSTR(xih.postal_code,1,3)||'-'||
--                           SUBSTR(xih.postal_code,4,4)),
--               xih.send_address1,
--               xih.send_address2,
--               xih.send_address3,
--               xih.bill_cust_code,
--               xih.send_to_name,
--               xih.bill_location_name,
--               xih.agent_tel_num,
--               xih.object_month,
--               xih.payment_cust_code,
--               xih.payment_cust_code||' '||xih.bill_cust_code||' '||xih.term_name,
--               xih.inv_amount_no_tax , -- 税抜請求金額合計
--               xih.tax_amount_sum,     -- 税額合計
--               xih.inv_amount_includ_tax,-- 税込請求金額合計
--               xih.payment_date,
--               CASE
--               WHEN account.bank_account_num IS NULL THEN
--                 NULL
--               ELSE
--                 DECODE(SUBSTR(account.bank_number,1,1),
--                 lv_format_bank_dummy,NULL,                                       -- ダミー銀行の場合はNULL
--                 CASE WHEN TO_NUMBER(account.bank_number)<1000  THEN
--                   CASE WHEN INSTR(account.bank_name,lv_format_date_bank)>0 THEN
--                     account.bank_name
--                   ELSE
--                     account.bank_name ||lv_format_date_bank
--                   END
--                 ELSE
--                  account.bank_name 
--                 END||' '||                                                       -- 銀行名
--                 CASE WHEN INSTR(account.bank_branch_name
--                                ,lv_format_date_central)>0 THEN
--                   account.bank_branch_name
--                 ELSE
--                   account.bank_branch_name||lv_format_date_branch 
--                 END||' '||                                                       -- 支店名
--                 DECODE( account.bank_account_type,
--                         1,lv_format_date_account,
--                         2,lv_format_date_current,
--                         account.bank_account_type) ||' '||                       -- 口座種別
--                 account.bank_account_num ||' '||                                 -- 口座番号
--                 account.account_holder_name||' '||                               -- 口座名義人
--                 account.account_holder_name_alt)                                 -- 口座名義人カナ名
--               END,
--               TO_CHAR(DECODE(xil.acceptance_date,
--                              NULL,xil.delivery_date,
--                              xil.acceptance_date),
--               cv_format_date_ymds2),
--               xil.slip_num;
----
--      gn_target_cnt := SQL%ROWCOUNT;
-- Modify 2009.09.10 Ver1.3 End
--
      -- 登録データが１件も存在しない場合、０件メッセージレコード追加
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_st_invoice_ex_tax (
          data_empty_message           , -- 0件メッセージ
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          lv_no_data_msg               , -- 0件メッセージ
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
--
        -- 警告終了
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a16_016 )  -- 対象データ0件警告
                             ,1
                             ,5000);
        ov_errmsg  := lv_errmsg;
--
        ov_retcode := cv_status_warn;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN  -- 登録時エラー
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a16_013    -- テーブル登録エラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 標準請求書税抜帳票ワークテーブル
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- 成功件数の設定
    gn_normal_cnt := gn_target_cnt;
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : chk_account_data
   * Description      : 口座情報取得チェック (A-5)
   ***********************************************************************************/
  PROCEDURE chk_account_data(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_account_data'; -- プログラム名
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
    ln_target_cnt    NUMBER;         -- 対象件数
    ln_loop_cnt      NUMBER;         -- ループカウンタ
    lv_warn_msg      VARCHAR2(5000);
    lv_bill_data_msg VARCHAR2(5000);
    lv_warn_bill_num VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR sel_no_account_data_cur
    IS
-- Modify 2009.09.10 Ver1.3 Start
--      SELECT xrsi.bill_cust_code  lv_bill_cust_code ,
--             xrsi.bill_cust_name  lv_bill_cust_name ,
--             xrsi.location_name   lv_location_name
      SELECT xrsi.payment_cust_code AS payment_cust_code
            ,xrsi.payment_cust_name AS payment_cust_name
-- Modify 2009.09.10 Ver1.3 End
      FROM xxcfr_rep_st_invoice_ex_tax  xrsi
      WHERE xrsi.request_id  = cn_request_id  -- 要求ID
        AND bank_account IS NULL
-- Modify 2009.09.10 Ver1.3 Start
--      GROUP BY xrsi.bill_cust_code ,
--               xrsi.bill_cust_name,
--               xrsi.location_name
--      ORDER BY xrsi.bill_cust_code ASC;
      GROUP BY xrsi.payment_cust_code
              ,xrsi.payment_cust_name
      ORDER BY xrsi.payment_cust_code ASC;
-- Modify 2009.09.10 Ver1.3 End
--
    TYPE g_sel_no_account_data_ttype IS TABLE OF sel_no_account_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_sel_no_account_tab    g_sel_no_account_data_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 請求書発行対象データが存在する場合以下の処理を実行
    IF ( gn_target_cnt > 0 ) THEN
--
      -- カーソルオープン
      OPEN sel_no_account_data_cur;
--
      -- データの一括取得
      FETCH sel_no_account_data_cur BULK COLLECT INTO lt_sel_no_account_tab;
--
      -- 処理件数のセット
      ln_target_cnt := lt_sel_no_account_tab.COUNT;
--
      -- カーソルクローズ
      CLOSE sel_no_account_data_cur;
--
      -- 対象データが存在する場合ログに出力する
      IF (ln_target_cnt > 0) THEN
--
        -- 振込口座未登録メッセージ出力
        lv_warn_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a16_018);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        -- 顧客コード・顧客名メッセージ出力
        BEGIN
          <<data_loop>>
          FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
            lv_bill_data_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr
                                  ,iv_name         => cv_msg_003a16_019
-- Modify 2009.09.10 Ver1.3 Start
--                                  ,iv_token_name1  => cv_tkn_ac_code
--                                  ,iv_token_value1 => lt_sel_no_account_tab(ln_loop_cnt).lv_bill_cust_code
--                                  ,iv_token_name2  => cv_tkn_ac_name
--                                  ,iv_token_value2 => lt_sel_no_account_tab(ln_loop_cnt).lv_bill_cust_name
--                                  ,iv_token_name3  => cv_tkn_lc_name
--                                  ,iv_token_value3 => lt_sel_no_account_tab(ln_loop_cnt).lv_location_name);
                                  ,iv_token_name1  => cv_tkn_ac_code
                                  ,iv_token_value1 => lt_sel_no_account_tab(ln_loop_cnt).payment_cust_code
                                  ,iv_token_name2  => cv_tkn_ac_name
                                  ,iv_token_value2 => lt_sel_no_account_tab(ln_loop_cnt).payment_cust_name);
-- Modify 2009.09.10 Ver1.3 End
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_bill_data_msg --エラーメッセージ
            );
          END LOOP data_loop;
        END;
        -- 顧客コードの件数をメッセージ出力
        lv_warn_bill_num := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cfr
                        ,iv_name         => cv_msg_003a16_020
                        ,iv_token_name1  => cv_tkn_count
                        ,iv_token_value1 => TO_CHAR(ln_target_cnt)
                       );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_bill_num
        );
--
        --１行改行
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => '' --ユーザー・エラーメッセージ
        );
--
        -- 警告終了
        ov_retcode := cv_status_warn;
--
      END IF;
    END IF;
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
  END chk_account_data;
--
  /**********************************************************************************
   * Procedure Name   : start_svf_api
   * Description      : SVF起動 (A-6)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- プログラム名
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR003A16S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR003A16S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- 出力区分(=1：PDF出力）
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- 拡張子（pdf）
--
    -- *** ローカル変数 ***
    lv_no_data_msg     VARCHAR2(5000);  -- 帳票０件メッセージ
-- Modify 2009.04.14 Ver1.3 Start
--    lv_svf_file_name   VARCHAR2(30);                                 -- 出力ファイル名
    lv_svf_file_name   VARCHAR2(100);
-- Modify 2009.04.14 Ver1.3 END
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- =====================================================
    --  SVF起動 (A-4)
    -- =====================================================
--
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- コンカレント名の設定
      lv_conc_name := cv_pkg_name;
--
    -- ファイルIDの設定
      lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_svf_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      ,iv_conc_name    => lv_conc_name          -- コンカレント名
      ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
      ,iv_file_id      => lv_file_id            -- 帳票ID
      ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
      ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
      ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
      ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
      ,iv_doc_name     => NULL                  -- 文書名
      ,iv_printer_name => NULL                  -- プリンタ名
      ,iv_request_id   => cn_request_id         -- 要求ID
      ,iv_nodata_msg   => NULL                  -- データなしメッセージ
    );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a16_015    -- APIエラー
                                                     ,cv_tkn_api           -- トークン'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF起動
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
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
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ワークテーブルデータ削除 (A-7)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- プログラム名
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
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR del_rep_st_inv_ex_cur
    IS
      SELECT xrsi.rowid        ln_rowid
      FROM xxcfr_rep_st_invoice_ex_tax xrsi -- 標準請求書税抜帳票ワークテーブル
      WHERE xrsi.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_st_inv_ex_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_st_inv_ex_data    g_del_rep_st_inv_ex_ttype;
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
    OPEN del_rep_st_inv_ex_cur;
--
    -- データの一括取得
    FETCH del_rep_st_inv_ex_cur BULK COLLECT INTO lt_del_rep_st_inv_ex_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_del_rep_st_inv_ex_data.COUNT;
--
    -- カーソルクローズ
    CLOSE del_rep_st_inv_ex_cur;
--
    -- 対象データが存在する場合レコードを削除する
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<data_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_rep_st_invoice_ex_tax
          WHERE ROWID = lt_del_rep_st_inv_ex_data(ln_loop_cnt);
--
        -- コミット発行
        COMMIT;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a16_012 -- データ削除エラー
                                                        ,cv_tkn_table         -- トークン'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- 標準請求書税抜帳票ワークテーブル
                              ,1
                              ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a16_011    -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- 標準請求書税抜帳票ワークテーブル
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date         IN      VARCHAR2,         -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--    iv_ar_code1            IN      VARCHAR2,         -- 売掛コード１(請求書)
    iv_custome_cd          IN      VARCHAR2,         -- 顧客番号(顧客)
    iv_invoice_cd          IN      VARCHAR2,         -- 顧客番号(請求用)
    iv_payment_cd          IN      VARCHAR2,         -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
    iv_bill_pub_cycle      IN      VARCHAR2,         -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_target_date         -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--      ,iv_ar_code1            -- 売掛コード１(請求書)
      ,iv_custome_cd          -- 顧客番号(顧客)
      ,iv_invoice_cd          -- 顧客番号(請求用)
      ,iv_payment_cd          -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
      ,iv_bill_pub_cycle      -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  全社出力権限チェック処理(A-3)
    -- =====================================================
    chk_inv_all_dept(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ワークテーブルデータ登録 (A-4)
    -- =====================================================
    insert_work_table(
       iv_target_date         -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--      ,iv_ar_code1            -- 売掛コード１(請求書)
      ,iv_custome_cd          -- 顧客番号(顧客)
      ,iv_invoice_cd          -- 顧客番号(請求用)
      ,iv_payment_cd          -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
      ,iv_bill_pub_cycle      -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
-- Modify 2009.09.10 Ver1.3 Start
    ELSIF (gv_warning_flag = cv_status_yes) THEN  -- 顧客紐付け警告存在時
      ov_retcode := cv_status_warn;
-- Modify 2009.09.10 Ver1.3 End
    END IF;
--
    -- =====================================================
    --  口座情報取得チェック (A-5)
    -- =====================================================
    chk_account_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  SVF起動 (A-6)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode_svf            -- リターン・コード             --# 固定 #
      ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- =====================================================
    --  ワークテーブルデータ削除 (A-7)
    -- =====================================================
    delete_work_table(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  SVF起動APIエラーチェック (A-8)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(エラー処理)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf                 OUT     VARCHAR2,         -- エラー・メッセージ  #固定#
    retcode                OUT     VARCHAR2,         -- エラーコード        #固定#
    iv_target_date         IN      VARCHAR2,         -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--    iv_ar_code1            IN      VARCHAR2          -- 売掛コード１(請求書)
    iv_custome_cd          IN      VARCHAR2,         -- 顧客番号(顧客)
    iv_invoice_cd          IN      VARCHAR2,         -- 顧客番号(請求用)
    iv_payment_cd          IN      VARCHAR2          -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
    lv_errbuf2      VARCHAR2(5000);  -- エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
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
       iv_target_date -- 締日
-- Modify 2009.09.10 Ver1.3 Start
--      ,iv_ar_code1    -- 売掛コード１(請求書)
      ,iv_custome_cd  -- 顧客番号(顧客)
      ,iv_invoice_cd  -- 顧客番号(請求用)
      ,iv_payment_cd  -- 顧客番号(売掛管理先)
-- Modify 2009.09.10 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
      ,iv_bill_pub_cycle -- 請求書発行サイクル
-- Add 2010.12.10 Ver1.7 End
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a16_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
        --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
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
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCFR003A16C;
/
