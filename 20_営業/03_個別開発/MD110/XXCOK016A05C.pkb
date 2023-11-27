CREATE OR REPLACE PACKAGE BODY XXCOK016A05C
AS
/*****************************************************************************************
 * Copyright(c) SCSK, 2023. All rights reserved.
 *
 * Package Name     : XXCOK016A05C(body)
 * Description      : FBデータファイル作成処理で作成されたFBデータを基に、
 *                    仕向銀行の振り分け処理を行います。
 *
 * MD.050           : FBデータファイル振り分け処理 MD050_COK_016_A05
 * Version          : 1.0
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                             Description
 * -------------------------------- ----------------------------------------------------------
 *  init                             初期処理 (A-1)
 *  init_update_data                 初期処理テーブル更新(A-2)
 *  auto_distribute_proc             FBデータ自動振り分け処理(A-3)
 *  manual_distribute_proc           FBデータ按分振り分け処理(A-4)
 *  output_fb_proc                   FBデータ出力処理(A-5)
 *  fb_header_record                 FBヘッダーレコード出力(A-6)
 *  fb_data_record                   FBデータレコードの出力(A-7)
 *  fb_trailer_record                FBトレーラレコードの出力(A-8)
 *  fb_end_record                    FBエンドレコードの出力(A-9)
 *  submain                          メイン処理プロシージャ
 *  main                             コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/11/15    1.0   T.Okuyama        [E_本稼動_19540対応] 新規作成
 *  2023/11/24    1.1   T.Okuyama        [E_本稼動_19540対応] 新規作成
 *
 *****************************************************************************************/
--
  --===============================
  -- グローバル定数
  --===============================
  --ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date            CONSTANT DATE          := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date         CONSTANT DATE          := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date      CONSTANT DATE          := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';                              -- コロン
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';                                -- ピリオド
  --
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK016A05C';                     -- パッケージ名
  -- プロファイル
  cv_prof_org_id              CONSTANT VARCHAR2(35)  := 'ORG_ID';                           -- MO: 営業単位
  cv_prof_acc_type_internal   CONSTANT VARCHAR2(35)  := 'XXCOK1_BM_ACC_TYPE_INTERNAL';      -- XXCOK:販売手数料_当社_口座使用
  -- アプリケーション名
  cv_appli_xxccp              CONSTANT VARCHAR2(5)   := 'XXCCP';               -- 'XXCCP'
  cv_appli_xxcok              CONSTANT VARCHAR2(5)   := 'XXCOK';               -- 'XXCOK'
  -- メッセージ
  cv_msg_cok_10865            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10865';    -- コンカレント入力パラメータ出力メッセージ
  cv_msg_cok_10866            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10866';    -- コンカレント入力パラメータ拡張出力メッセージ
  cv_msg_cok_10867            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10867';    -- FBファイル作成要求ID取得エラー
  cv_msg_cok_10868            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10868';    -- FB他行分仕向銀行取得エラー
  cv_msg_cok_10869            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10869';    -- FB他行分仕向銀行未定義エラー
  cv_msg_cok_10870            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10870';    -- FB他行分仕向銀行整合性エラー
  cv_msg_cok_10871            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10871';    -- FB他行分仕向銀行口座整合性エラー
  cv_msg_cok_10872            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10872';    -- FBデータ明細取得エラー
  cv_msg_cok_10873            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10873';    -- 参照表（当社銀行口座情報）取得エラー
  cv_msg_cok_10874            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10874';    -- FB他行分仕向銀行重複エラー
  cv_msg_cok_10875            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10875';    -- FB用口座銀行整合性エラー
  cv_msg_cok_10876            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10876';    -- 参照表（FB他行分仕向銀行）取得エラー
  cv_msg_cok_10877            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10877';    -- 成功件数、合計金額メッセージ
  cv_msg_cok_10863            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10863';    -- テーブルロック取得エラー
  cv_msg_cok_10864            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10864';    -- テーブル更新エラー
  cv_msg_cok_00003            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';    -- プロファイル値取得エラーメッセージ
  cv_msg_cok_00028            CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';    -- 業務処理日付取得エラーメッセージ
  cv_msg_ccp_90000            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';    -- 抽出件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';    -- エラー件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';    -- ファイル出力件数メッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';    -- 正常終了メッセージ
  cv_msg_ccp_90006            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';    -- エラー終了全ロールバックメッセージ
  -- メッセージ・トークン
  cv_token_request_id         CONSTANT VARCHAR2(15)  := 'REQUEST_ID';             -- 処理パラメータ：FBデータファイル作成時の要求ID
  cv_token_fb_bank1           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK1';  -- 処理パラメータ：他行分仕向銀行1
  cv_token_fb_bank_cnt1       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT1';           -- 処理パラメータ：仕向銀行1への按分件数
  cv_token_fb_bank2           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK2';  -- 処理パラメータ：他行分仕向銀行2
  cv_token_fb_bank_cnt2       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT2';           -- 処理パラメータ：仕向銀行2への按分件数
  cv_token_fb_bank3           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK3';  -- 処理パラメータ：他行分仕向銀行3
  cv_token_fb_bank_cnt3       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT3';           -- 処理パラメータ：仕向銀行3への按分件数
  cv_token_fb_bank4           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK4';  -- 処理パラメータ：他行分仕向銀行4
  cv_token_fb_bank_cnt4       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT4';           -- 処理パラメータ：仕向銀行4への按分件数
  cv_token_fb_bank5           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK5';  -- 処理パラメータ：他行分仕向銀行5
  cv_token_fb_bank_cnt5       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT5';           -- 処理パラメータ：仕向銀行5への按分件数
  cv_token_fb_bank6           CONSTANT VARCHAR2(30)  := 'FB_DISTRIBUTION_BANK6';  -- 処理パラメータ：他行分仕向銀行6
  cv_token_fb_bank_cnt6       CONSTANT VARCHAR2(30)  := 'REQUEST_CNT6';           -- 処理パラメータ：仕向銀行6への按分件数
  cv_token_dist_bank          CONSTANT VARCHAR2(20)  := 'FB_DISTRIBUTION_BANK';   -- 被仕向銀行振り分け銀行
  cv_token_dupli_bank         CONSTANT VARCHAR2(20)  := 'DUPLI_BANK';             -- 重複銀行
  cv_token_profile            CONSTANT VARCHAR2(15)  := 'PROFILE';                -- カスタムプロファイルの物理名
  cv_token_count              CONSTANT VARCHAR2(15)  := 'COUNT';                  -- 件数
  cv_token_amount             CONSTANT VARCHAR2(15)  := 'AMOUNT';                 -- 合計金額
  -- 定数
  cv_log                      CONSTANT VARCHAR2(3)   := 'LOG';                    -- ログ出力指定
  cv_yes                      CONSTANT VARCHAR2(1)   := 'Y';                      -- フラグ:'Y'
  cv_no                       CONSTANT VARCHAR2(1)   := 'N';                      -- フラグ:'N'
  cv_space                    CONSTANT VARCHAR2(1)   := ' ';                      -- スペース1文字
  cv_zero                     CONSTANT VARCHAR2(1)   := '0';                      -- 文字型数字：'0'
  cn_zero                     CONSTANT NUMBER        := 0;                        -- 数値：0
  cv_auto                     CONSTANT VARCHAR2(1)   := 'A';                      -- 自動振り分け実行フラグ:'Y'
  cv_manual                   CONSTANT VARCHAR2(1)   := 'M';                      -- 手動振り分け実行フラグ:'M'
  cv_tkn_tbl                  CONSTANT VARCHAR2(30)  := 'TABLE';                  -- テーブル名
  cv_tkn_err_msg              CONSTANT VARCHAR2(30)  := 'ERR_MSG';                -- エラーメッセージ
  cv_loopup_type              CONSTANT VARCHAR2(30)  := 'LOOPUP_TYPE';            -- 参照タイプ
  cv_loopup_tbl_nm            CONSTANT VARCHAR2(100) := '参照表（FB他行分仕向銀行）';
  cv_wk_tbl_nm                CONSTANT VARCHAR2(100) := 'FBデータ明細ワークテーブル';
  cv_lookup_type_fb           CONSTANT VARCHAR2(50)  := 'XXCMM_FB_DISTRIBUTION_BANK';   -- 参照タイプ：FB他行分仕向銀行
  cv_lookup_type_bank         CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_BANK_ACCOUNT';       -- 参照タイプ：当社銀行口座情報
  cv_lookup_code_bank         CONSTANT VARCHAR2(10)  := 'VDBM_FB';                      -- 参照コード：VDBM振込元口座
  --
  --===============================
  -- グローバル変数
  --===============================
  -- 出力メッセージ
  gv_out_msg                  VARCHAR2(2000) DEFAULT NULL;                            -- 出力メッセージ
  -- カウンタ
  gn_target_cnt               NUMBER         DEFAULT 0;                               -- 対象件数
  gn_error_cnt                NUMBER         DEFAULT 0;                               -- エラー件数
  gn_out_cnt                  NUMBER         DEFAULT 0;                               -- 成功件数（FB明細合計件数）
  gn_out_amount               NUMBER         DEFAULT 0;                               -- FB明細合計金額
  gn_request_id               xxcok_fb_lines_work.request_id%TYPE  DEFAULT NULL;      -- 処理対象要求ID
  gv_default_bank_code        fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;      -- FBデータ作成時の自社銀行

  -- プロファイル
  gt_prof_org_id              fnd_profile_option_values.profile_option_value%TYPE;    -- 営業単位
  gt_prof_acc_type_internal   fnd_profile_option_values.profile_option_value%TYPE;    -- XXCOK:販売手数料_当社_口座使用
  -- 日付
  gd_proc_date                DATE;                                                   -- 業務処理日付
  --=================================
  -- 共通例外
  --=================================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** ロック取得共通例外 ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- プラグマ
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2     -- リターン・コード
  , ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  , in_request_id      IN  NUMBER       -- パラメータ：FBデータファイル作成時の要求ID
  , iv_internal_bank1  IN  VARCHAR2     -- パラメータ：他行分仕向銀行1
  , in_bank_cnt1       IN  NUMBER       -- パラメータ：仕向銀行1への按分件数
  , iv_internal_bank2  IN  VARCHAR2     -- パラメータ：他行分仕向銀行2
  , in_bank_cnt2       IN  NUMBER       -- パラメータ：仕向銀行2への按分件数
  , iv_internal_bank3  IN  VARCHAR2     -- パラメータ：他行分仕向銀行3
  , in_bank_cnt3       IN  NUMBER       -- パラメータ：仕向銀行3への按分件数
  , iv_internal_bank4  IN  VARCHAR2     -- パラメータ：他行分仕向銀行4
  , in_bank_cnt4       IN  NUMBER       -- パラメータ：仕向銀行4への按分件数
  , iv_internal_bank5  IN  VARCHAR2     -- パラメータ：他行分仕向銀行5
  , in_bank_cnt5       IN  NUMBER       -- パラメータ：仕向銀行5への按分件数
  , iv_internal_bank6  IN  VARCHAR2     -- パラメータ：他行分仕向銀行6
  , in_bank_cnt6       IN  NUMBER       -- パラメータ：仕向銀行6への按分件数
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name      CONSTANT       VARCHAR2(100) := 'init';     -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;          -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;          -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;          -- ユーザー・エラー・メッセージ
    ln_errout        NUMBER         DEFAULT 0;             -- エラー出力数
    lb_retcode       BOOLEAN;                              -- メッセージ
    lv_profile       VARCHAR2(35)   DEFAULT NULL;          -- プロファイル
    lv_in_code       fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    lv_bank_code     fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    lv_dupli_code    fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    lv_dupli_name    fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 6.入力パラメータチェック
    -- 入力パラメータ銀行とFB他行分仕向銀行登録のチェックカーソル
    CURSOR fb_lookup_bank_ck_cur(iv_code IN VARCHAR2)
    IS
    SELECT MAX(flv.lookup_code) AS  internal_bank       -- 被仕向銀行振分け銀行
          ,MAX(flv.meaning)     AS  internal_bank_name  -- 被仕向銀行振分け銀行名
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND    flv.lookup_code  = iv_code                   -- 入力パラメータ銀行
    AND    flv.attribute10  = cv_yes                    -- 他行分振分け対象区分
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ORDER BY flv.lookup_code
    ;
--
    -- 7.FB他行分仕向銀行登録チェックカーソル
    CURSOR fb_lookup_bank_dff_ck_cur
    IS
    SELECT MIN(flv.lookup_code) AS  internal_bank       -- 被仕向銀行振分け銀行
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND   (flv.attribute1 IS NULL
      OR   flv.attribute2 IS NULL
      OR   flv.attribute3 IS NULL
      OR   flv.attribute4 IS NULL
      OR   flv.attribute5 IS NULL
      OR   flv.attribute6 IS NULL
      OR   flv.attribute7 IS NULL
      OR   flv.attribute8 IS NULL)
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ;
--
    -- 8.参照表（FB他行分仕向銀行）登録情報と銀行支店マスタの整合性チェックカーソル
    CURSOR fb_bank_number_ck_cur
    IS
    SELECT flv.lookup_code AS  internal_bank            -- 被仕向銀行振分け銀行
          ,abb.bank_number AS  bank_number              -- 銀行番号
    FROM   fnd_lookup_values flv                        -- 参照表（FB他行分仕向銀行）
          ,ap_bank_branches  abb                        -- 銀行支店マスタ
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND    flv.lookup_code  = abb.bank_number(+)        -- 銀行番号
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    GROUP BY flv.lookup_code, abb.bank_number
    ORDER BY flv.lookup_code, abb.bank_number
    ;
--
    -- 9.参照表（FB他行分仕向銀行）振分対象銀行とFB用自社口座銀行のチェックカーソル
    CURSOR fb_internal_bank_ck_cur
    IS
    SELECT flv.attribute1             AS  internal_bank           -- 被仕向銀行振分け銀行
          ,MAX(abaa.eft_requester_id) AS  eft_requester           -- 依頼人コード
    FROM    ap_bank_accounts_all      abaa                        -- 銀行口座マスタ
           ,ap_bank_branches          abb                         -- 銀行支店マスタ
           ,fnd_lookup_values         flv                         -- 参照表（FB他行分仕向銀行）
    WHERE  abaa.bank_branch_id(+)   = abb.bank_branch_id
    AND    abaa.org_id(+)           = TO_NUMBER( gt_prof_org_id ) -- 営業単位
    AND    abaa.account_type(+)     = gt_prof_acc_type_internal   -- 口座使用（'INTERNAL'）
    AND    abaa.eft_requester_id(+) IS NOT NULL
    AND    flv.lookup_type          = cv_lookup_type_fb
    AND    flv.lookup_code          = abb.bank_number
    AND   (flv.attribute9   = cv_yes                              -- 仕向銀行自動振分区分
      OR   flv.attribute10  = cv_yes)                             -- 他行分振分け対象区分
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    GROUP BY flv.attribute1
    ORDER BY flv.attribute1
    ;
--
    -- 10.FB他行分仕向銀行情報と銀行口座マスタの整合性チェックカーソル
    CURSOR fb_bank_accounts_ck_cur
    IS
    SELECT flv.lookup_code AS  internal_bank                      -- 被仕向銀行振分け銀行
    FROM    ap_bank_accounts_all          abaa                    -- 銀行口座マスタ
           ,ap_bank_branches              abb                     -- 銀行支店マスタ
           ,fnd_lookup_values             flv
    WHERE  abaa.bank_branch_id    = abb.bank_branch_id
    AND    abaa.org_id            = TO_NUMBER( gt_prof_org_id )   -- 営業単位
    AND    abaa.account_type      = gt_prof_acc_type_internal     -- 口座使用（'INTERNAL'）
    AND    abaa.eft_requester_id IS NOT NULL
    AND    flv.lookup_type        = cv_lookup_type_fb
    AND    flv.lookup_code        = abb.bank_number
    AND   (abb.bank_number              <> flv.attribute1         -- 銀行番号
      OR   abb.bank_name_alt            <> flv.attribute2         -- 銀行名カナ
      OR   abb.bank_num                 <> flv.attribute3         -- 支店番号
      OR   abb.bank_branch_name_alt     <> flv.attribute4         -- 銀行支店名カナ
      OR   abaa.bank_account_type       <> flv.attribute5         -- 銀行口座種別
      OR   abaa.bank_account_num        <> flv.attribute6         -- 口座番号
      OR   abaa.eft_requester_id        <> flv.attribute7         -- 依頼人コード
      OR   abaa.account_holder_name_alt <> flv.attribute8)        -- 口座名義人カナ（依頼人名）
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ORDER BY flv.lookup_code
    ;
--
    --===============================
    -- ローカル例外
    --===============================
    --*** 初期処理エラー ***
    no_profile_expt            EXCEPTION; -- プロファイル値取得エラー
    init_fail_expt             EXCEPTION; -- 初期処理エラー
    init_warning_expt          EXCEPTION; -- 初期処理警告エラー
    init_othes_expt            EXCEPTION; -- 初期処理例外エラー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    --==========================================================
    --1.入力パラメータチェック
    --==========================================================
    -- FBファイル作成要求ID
    IF( in_request_id IS NULL ) THEN
      -- ジョブ起動の時
      SELECT MAX(request_id) INTO gn_request_id FROM xxcok_fb_lines_work;
      IF( gn_request_id IS NULL ) THEN
        -- FBファイル作成要求IDが取得出来ない時、警告終了
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10872
                        ,iv_token_name1  => cv_token_request_id
                        ,iv_token_value1 => TO_CHAR(gn_request_id)
                       );
        RAISE init_warning_expt;
      END IF;
    ELSE
      -- 随時実行
      SELECT MAX(request_id) INTO gn_request_id FROM xxcok_fb_lines_work WHERE request_id = in_request_id;
      IF( gn_request_id IS NULL ) THEN
        -- パラメータ指定のFBファイル作成要求IDが取得出来ない時、エラー終了
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10867
                        ,iv_token_name1  => cv_token_request_id
                        ,iv_token_value1 => TO_CHAR(gn_request_id)
                       );
        RAISE init_fail_expt;
      END IF;
    END IF;
    --==========================================================
    --2.コンカレント・プログラム入力項目メッセージ出力
    --==========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok
                   ,iv_name         => cv_msg_cok_10865
                   -- FBファイル作成要求ID
                   ,iv_token_name1  => cv_token_request_id
                   ,iv_token_value1 => TO_CHAR(gn_request_id)
                   -- 1.他行分仕訳銀行、按分件数
                   ,iv_token_name2  => cv_token_fb_bank1
                   ,iv_token_value2 => iv_internal_bank1
                   ,iv_token_name3  => cv_token_fb_bank_cnt1
                   ,iv_token_value3 => TO_CHAR(in_bank_cnt1)
                   -- 2.他行分仕訳銀行、按分件数
                   ,iv_token_name4  => cv_token_fb_bank2
                   ,iv_token_value4 => iv_internal_bank2
                   ,iv_token_name5  => cv_token_fb_bank_cnt2
                   ,iv_token_value5 => TO_CHAR(in_bank_cnt2)
                   -- 3.他行分仕訳銀行、按分件数
                   ,iv_token_name6  => cv_token_fb_bank3
                   ,iv_token_value6 => iv_internal_bank3
                   ,iv_token_name7  => cv_token_fb_bank_cnt3
                   ,iv_token_value7 => TO_CHAR(in_bank_cnt3)
                   -- 4.他行分仕訳銀行、按分件数
                   ,iv_token_name8  => cv_token_fb_bank4
                   ,iv_token_value8 => iv_internal_bank4
                   ,iv_token_name9  => cv_token_fb_bank_cnt4
                   ,iv_token_value9 => TO_CHAR(in_bank_cnt4)
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG        -- 出力区分
                   ,iv_message  => lv_errmsg           -- メッセージ
                   ,in_new_line => 0                   -- 改行
                  );
    --==========================================================
    --3.コンカレント・プログラム入力拡張項目メッセージ出力
    --==========================================================
    IF (iv_internal_bank5 || iv_internal_bank6) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_10866
                     -- 5.他行分仕訳銀行、按分件数
                     ,iv_token_name1  => cv_token_fb_bank5
                     ,iv_token_value1 => iv_internal_bank5
                     ,iv_token_name2  => cv_token_fb_bank_cnt5
                     ,iv_token_value2 => TO_CHAR(in_bank_cnt5)
                     -- 6.他行分仕訳銀行、按分件数
                     ,iv_token_name3  => cv_token_fb_bank6
                     ,iv_token_value3 => iv_internal_bank6
                     ,iv_token_name4  => cv_token_fb_bank_cnt6
                     ,iv_token_value4 => TO_CHAR(in_bank_cnt6)
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG        -- 出力区分
                     ,iv_message  => lv_errmsg           -- メッセージ
                     ,in_new_line => 0                   -- 改行
                    );
    END IF;
--
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG         -- 出力区分
                   ,iv_message  => NULL                 -- メッセージ
                   ,in_new_line => 1                    -- 改行
                  );
    --==========================================================
    --4.業務処理日付取得
    --==========================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF( gd_proc_date IS NULL ) THEN
      -- 業務処理日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00028
                     );
      RAISE init_fail_expt;
    END IF;
    --==========================================================
    --5.プロファイルの取得
    --6.カスタム・プロファイルの取得
    --==========================================================
    gt_prof_org_id              := FND_PROFILE.VALUE( cv_prof_org_id );               -- MO: 営業単位
    gt_prof_acc_type_internal   := FND_PROFILE.VALUE( cv_prof_acc_type_internal );    -- XXCOK:販売手数料_当社_口座使用
--
      -- プロファイル値取得エラー
    IF( gt_prof_org_id IS NULL ) THEN
      lv_profile := cv_prof_org_id;
      RAISE no_profile_expt;
    END IF;
    IF( gt_prof_acc_type_internal IS NULL ) THEN
      lv_profile := cv_prof_acc_type_internal;
      RAISE no_profile_expt;
    END IF;
--
    -- FB他行分仕向銀行
    <<fb_bank_ck_loop>>
    FOR i IN 1 .. 6 LOOP
      IF i = 1 THEN
        lv_in_code := iv_internal_bank1;
      ELSIF  i = 2 THEN
        lv_in_code := iv_internal_bank2;
      ELSIF  i = 3 THEN
        lv_in_code := iv_internal_bank3;
      ELSIF  i = 4 THEN
        lv_in_code := iv_internal_bank4;
      ELSIF  i = 5 THEN
        lv_in_code := iv_internal_bank5;
      ELSIF  i = 6 THEN
        lv_in_code := iv_internal_bank6;
      END IF;
--
      IF lv_in_code IS NOT NULL THEN
        -- 入力パラメータ銀行とFB他行分仕向銀行登録のチェック
        OPEN  fb_lookup_bank_ck_cur(lv_in_code);
        FETCH fb_lookup_bank_ck_cur INTO lv_bank_code, lv_dupli_name;
        CLOSE fb_lookup_bank_ck_cur;
        IF( lv_bank_code IS NULL ) THEN
          -- FB他行分仕向銀行取得エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appli_xxcok
                          ,iv_name         => cv_msg_cok_10868
                          ,iv_token_name1  => cv_token_dist_bank
                          ,iv_token_value1 => lv_in_code
                         );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG      -- 出力区分
                         ,iv_message  => lv_errmsg         -- メッセージ
                         ,in_new_line => 0                 -- 改行
                        );
          ln_errout := ln_errout + 1;
        END IF;
        IF i = 1 THEN
          IF   lv_in_code = NVL(iv_internal_bank2,'N') OR lv_in_code = NVL(iv_internal_bank3,'N') OR lv_in_code = NVL(iv_internal_bank4,'N') 
            OR lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 2 THEN
          IF   lv_in_code = NVL(iv_internal_bank3,'N') OR lv_in_code = NVL(iv_internal_bank4,'N') 
            OR lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 3 THEN
          IF   lv_in_code = NVL(iv_internal_bank4,'N') 
            OR lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 4 THEN
          IF   lv_in_code = NVL(iv_internal_bank5,'N') OR lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        ELSIF  i = 5 THEN
          IF   lv_in_code = NVL(iv_internal_bank6,'N') THEN
            lv_dupli_code := lv_in_code;
          END IF;
        END IF;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    IF lv_dupli_code IS NOT NULL THEN
      -- FB他行分仕向銀行パラメータ重複エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10874
                      ,iv_token_name1  => cv_token_dupli_bank
                      ,iv_token_value1 => lv_dupli_code || cv_msg_part || lv_dupli_name
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                     ,iv_message  => lv_errmsg         -- メッセージ
                     ,in_new_line => 0                 -- 改行
                    );
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    --==========================================================
    --7.参照表（FB他行分仕向銀行）の登録チェック
    --==========================================================
    BEGIN
      lv_bank_code := NULL;
      OPEN  fb_lookup_bank_dff_ck_cur;
      FETCH fb_lookup_bank_dff_ck_cur INTO lv_bank_code;
      CLOSE fb_lookup_bank_dff_ck_cur;
--
      IF( lv_bank_code IS NOT NULL ) THEN
        -- FB他行分仕向銀行未定義エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10869
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lv_bank_code
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- 出力区分
                       ,iv_message  => lv_errmsg         -- メッセージ
                       ,in_new_line => 0                 -- 改行
                      );
        lv_errmsg := NULL;
        RAISE init_othes_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --=====================================================================
    --8.参照表（FB他行分仕向銀行）登録情報と銀行支店マスタの整合性チェック
    --=====================================================================
    ln_errout := 0;
    <<fb_bank_ck_loop>>
    FOR lt_bank_ck_rec in fb_bank_number_ck_cur LOOP
      IF( lt_bank_ck_rec.bank_number IS NULL ) THEN
        -- FB他行分仕向銀行整合性エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10870
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lt_bank_ck_rec.internal_bank
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- 出力区分
                       ,iv_message  => lv_errmsg         -- メッセージ
                       ,in_new_line => 0                 -- 改行
                      );
        ln_errout := ln_errout + 1;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    --=====================================================================
    --9.参照表（FB他行分仕向銀行）振分対象銀行とFB用自社口座銀行のチェック
    --=====================================================================
    ln_errout := 0;
    <<fb_bank_ck_loop>>
    FOR lt_internal_bank_rec in fb_internal_bank_ck_cur LOOP
      IF( lt_internal_bank_rec.eft_requester IS NULL ) THEN
        -- FB用自社口座銀行整合性エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10875
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lt_internal_bank_rec.internal_bank
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- 出力区分
                       ,iv_message  => lv_errmsg         -- メッセージ
                       ,in_new_line => 0                 -- 改行
                      );
        ln_errout := ln_errout + 1;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
    --======================================================================
    --10.参照表（FB他行分仕向銀行）登録情報と銀行口座マスタの整合性チェック
    --======================================================================
    ln_errout := 0;
    <<fb_bank_ck_loop>>
    FOR lt_bank_accounts_rec in fb_bank_accounts_ck_cur LOOP
      IF( lt_bank_accounts_rec.internal_bank IS NOT NULL ) THEN
        -- 銀行口座マスタ整合性エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_xxcok
                        ,iv_name         => cv_msg_cok_10871
                        ,iv_token_name1  => cv_token_dist_bank
                        ,iv_token_value1 => lt_bank_accounts_rec.internal_bank
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- 出力区分
                       ,iv_message  => lv_errmsg         -- メッセージ
                       ,in_new_line => 0                 -- 改行
                      );
        ln_errout := ln_errout + 1;
      END IF;
    END LOOP fb_bank_ck_loop;
--
    IF ln_errout > 0 THEN
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    END IF;
--
  EXCEPTION
    -- *** 初期処理警告終了 ***
    WHEN init_warning_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    WHEN init_othes_expt THEN
      -- *** 初期処理例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    WHEN no_profile_expt THEN
      -- *** プロファイル取得例外ハンドラ ***
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxcok
                     ,iv_name         => cv_msg_cok_00003
                     ,iv_token_name1  => cv_token_profile
                     ,iv_token_value1 => lv_profile
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : init_update_data
   * Description      : 初期処理テーブル更新(A-2)
   ***********************************************************************************/
  PROCEDURE init_update_data(
    ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2     -- リターン・コード
  , ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  , iv_internal_bank1  IN  VARCHAR2     -- パラメータ：他行分仕向銀行1
  , in_bank_cnt1       IN  NUMBER       -- パラメータ：仕向銀行1への按分件数
  , iv_internal_bank2  IN  VARCHAR2     -- パラメータ：他行分仕向銀行2
  , in_bank_cnt2       IN  NUMBER       -- パラメータ：仕向銀行2への按分件数
  , iv_internal_bank3  IN  VARCHAR2     -- パラメータ：他行分仕向銀行3
  , in_bank_cnt3       IN  NUMBER       -- パラメータ：仕向銀行3への按分件数
  , iv_internal_bank4  IN  VARCHAR2     -- パラメータ：他行分仕向銀行4
  , in_bank_cnt4       IN  NUMBER       -- パラメータ：仕向銀行4への按分件数
  , iv_internal_bank5  IN  VARCHAR2     -- パラメータ：他行分仕向銀行5
  , in_bank_cnt5       IN  NUMBER       -- パラメータ：仕向銀行5への按分件数
  , iv_internal_bank6  IN  VARCHAR2     -- パラメータ：他行分仕向銀行6
  , in_bank_cnt6       IN  NUMBER       -- パラメータ：仕向銀行6への按分件数
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init_update_data';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --===============================
    -- ローカル変数
    --===============================
    lb_retcode       BOOLEAN;                                                   -- メッセージ
    lv_in_code       fnd_lookup_values.lookup_code%TYPE   DEFAULT NULL;
    ln_in_cnt        NUMBER         DEFAULT 0;                                  -- 按分件数
    lv_tbl_nm        VARCHAR2(100);                                             -- テーブル名
    --===============================
    -- ローカル例外
    --===============================
    init_othes_expt            EXCEPTION; -- 初期処理例外エラー
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR fb_lookup_cur
    IS
      SELECT 'X'
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      FOR UPDATE OF flv.lookup_code NOWAIT;
--
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id = gn_request_id
      FOR UPDATE OF xflw.request_id NOWAIT;
--
    --  FBデータファイル作成時の自社銀行（FBヘッダー）取得カーソル
    CURSOR vdbm_fb_bank_cur
    IS
    SELECT MAX(flv.attribute1) AS  internal_bank       --FBデータファイル作成自社銀行
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_bank
    AND    flv.lookup_code  = cv_lookup_code_bank
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
     -- ========================================================
    -- 1.参照表（FB他行分仕向銀行）テーブルへの按分件数の登録
    -- =========================================================
    lv_tbl_nm := cv_loopup_tbl_nm;
--
    -- ===============================================
    -- 参照表（FB他行分仕向銀行）ロック取得
    -- ===============================================
    OPEN  fb_lookup_cur;
    CLOSE fb_lookup_cur;
    -- ===============================================
    -- 参照表（FB他行分仕向銀行）データ更新
    -- ===============================================
    -- 前回実行の按分件数、明細合計金額をクリア
    BEGIN
      UPDATE fnd_lookup_values flv
      SET    flv.attribute11  = NULL
            ,flv.attribute12  = NULL
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      AND    flv.enabled_flag = cv_yes
      AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                  AND NVL(flv.end_date_active, gd_proc_date)
      AND    flv.language     = USERENV('LANG')
      ;
    EXCEPTION
      -- *** 更新処理エラー ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => lv_tbl_nm                            -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
    -- パラメータ入力された按分件数の登録
    <<fb_bank_ck_loop>>
    FOR i IN 1 .. 6 LOOP
      IF i = 1 THEN
        lv_in_code := iv_internal_bank1;
        ln_in_cnt  := in_bank_cnt1;
      ELSIF  i = 2 THEN
        lv_in_code := iv_internal_bank2;
        ln_in_cnt  := in_bank_cnt2;
      ELSIF  i = 3 THEN
        lv_in_code := iv_internal_bank3;
        ln_in_cnt  := in_bank_cnt3;
      ELSIF  i = 4 THEN
        lv_in_code := iv_internal_bank4;
        ln_in_cnt  := in_bank_cnt4;
      ELSIF  i = 5 THEN
        lv_in_code := iv_internal_bank5;
        ln_in_cnt  := in_bank_cnt5;
      ELSIF  i = 6 THEN
        lv_in_code := iv_internal_bank6;
        ln_in_cnt  := in_bank_cnt6;
      END IF;
      IF NVL (ln_in_cnt, 0 ) = 0 THEN
        ln_in_cnt := NULL;
      END IF;
--
      BEGIN
        UPDATE fnd_lookup_values flv
        SET    flv.attribute11  = TO_CHAR(ln_in_cnt, '999,999')
        WHERE  flv.lookup_type  = cv_lookup_type_fb
        AND    flv.lookup_code  = lv_in_code
        AND    flv.enabled_flag = cv_yes
        AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                    AND NVL(flv.end_date_active, gd_proc_date)
        AND    flv.language     = USERENV('LANG')
        ;
      EXCEPTION
        -- *** 更新処理エラー ***
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                   ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                   ,iv_token_value1 => lv_tbl_nm                            -- トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                   ,iv_token_value2 => SQLERRM                              -- トークン値2
                  );
          lv_errbuf := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END LOOP fb_bank_ck_loop;
--
    -- ===============================================
    -- 2.FBデータ明細ワークテーブル・データ更新
    -- ===============================================
    lv_tbl_nm := cv_wk_tbl_nm;
    --  FBデータファイル作成時の自社銀行取得
    OPEN  vdbm_fb_bank_cur;
    FETCH vdbm_fb_bank_cur INTO gv_default_bank_code;
    CLOSE vdbm_fb_bank_cur;
--
    IF( gv_default_bank_code IS NULL ) THEN
      -- FB自社銀行取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10873
                      ,iv_token_name1  => cv_loopup_type
                      ,iv_token_value1 => cv_lookup_type_bank
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                     ,iv_message  => lv_errmsg         -- メッセージ
                     ,in_new_line => 0                 -- 改行
                    );
      lv_errmsg := NULL;
      RAISE init_othes_expt;
    ELSE
      -- ===============================================
      -- FBデータ明細ワークテーブルロック取得
      -- ===============================================
      OPEN  fb_lines_cur;
      CLOSE fb_lines_cur;
      -- ===============================================
      -- FBデータ明細ワークテーブル・データ更新
      -- ===============================================
      BEGIN
        UPDATE xxcok_fb_lines_work  xflw
        SET    xflw.internal_bank_number = gv_default_bank_code
              ,xflw.implemented_flag     = NULL
        WHERE  xflw.request_id = gn_request_id
        AND    xflw.implemented_flag IS NOT NULL
        ;
      EXCEPTION
        -- *** 更新処理エラー ***
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                   ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                   ,iv_token_value1 => lv_tbl_nm                            -- トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                   ,iv_token_value2 => SQLERRM                              -- トークン値2
                  );
          lv_errbuf := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END IF;
--
  EXCEPTION
    -- *** 初期処理例外ハンドラ ***
    WHEN init_othes_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
    --*** ロックエラー ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10863                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => lv_tbl_nm                            -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
      lv_errbuf := lv_errmsg;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  END init_update_data;
--
  /**********************************************************************************
   * Procedure Name   : auto_distribute_proc
   * Description      : FBデータ自動振り分け処理(A-3)
   ***********************************************************************************/
  PROCEDURE auto_distribute_proc(
    ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2     -- リターン・コード
  , ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name        CONSTANT VARCHAR2(100)   := 'auto_distribute_proc';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --===============================
    -- ローカル変数
    --===============================
    lb_retcode       BOOLEAN;                                                   -- メッセージ
    ln_in_cnt        NUMBER         DEFAULT 0;                                  -- 按分件数
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR fb_lines_cur
    IS
    SELECT 'X'
    FROM   xxcok_fb_lines_work  xflw
    WHERE  xflw.request_id = gn_request_id
    FOR UPDATE OF xflw.request_id NOWAIT
    ;
--
    -- 自動振り分け銀行取得カーソル
    CURSOR get_auto_sub_cur
    IS
    SELECT flv.attribute1 AS  internal_bank            -- 振分銀行
    FROM   xxcok_fb_lines_work  xflw
          ,fnd_lookup_values    flv
    WHERE xflw.request_id = gn_request_id
    AND   flv.lookup_type = cv_lookup_type_fb
    AND   flv.lookup_code = xflw.bank_number
    AND   NVL(flv.attribute9, cv_no) = cv_yes
    AND   flv.enabled_flag = cv_yes
    AND   gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                               AND NVL(flv.end_date_active, gd_proc_date)
    AND   flv.language    = USERENV('LANG')
    ORDER BY xflw.base_code, xflw.supplier_code
    FOR UPDATE OF xflw.request_id NOWAIT
    ;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- FBデータ明細ワークテーブルロック取得
    -- ===============================================
    OPEN  fb_lines_cur;
    CLOSE fb_lines_cur;
    -- ===============================================
    -- FBデータ明細ワークテーブル・データ更新
    -- ===============================================
    BEGIN
      <<fb_bank_ck_loop>>
      -- 自動振り分け実行更新
      FOR lt_auto_sub_rec in get_auto_sub_cur LOOP
        UPDATE xxcok_fb_lines_work  xflw
        SET    xflw.internal_bank_number = lt_auto_sub_rec.internal_bank  -- 仕向金融機関番号
              ,xflw.implemented_flag     = cv_auto                        -- FB振分実行済区分
        WHERE CURRENT OF get_auto_sub_cur
        ;
      END LOOP fb_bank_ck_loop;
    EXCEPTION
      -- *** 更新処理エラー ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ロックエラー ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10863                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
      lv_errbuf := lv_errmsg;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  END auto_distribute_proc;
--
  /**********************************************************************************
   * Procedure Name   : manual_distribute_proc
   * Description      : FBデータ按分振り分け処理(A-4)
   ***********************************************************************************/
  PROCEDURE manual_distribute_proc(
    ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2     -- リターン・コード
  , ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'manual_distribute_proc';     -- プログラム名
    cn_bank_max             CONSTANT NUMBER          := 6;                            -- 按分処理最大6行
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --===============================
    -- ローカル変数
    --===============================
    lb_retcode       BOOLEAN;                                                   -- メッセージ
    ln_in_cnt        NUMBER         DEFAULT 0;                                  -- 按分件数
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id = gn_request_id
      FOR UPDATE OF xflw.request_id NOWAIT;
--
    -- 按分振り分け対象銀行取得カーソル
    CURSOR get_manual_sub_cur
    IS
    SELECT xflw.internal_bank_number AS  internal_bank_number     -- 振分銀行
    FROM   xxcok_fb_lines_work   xflw
    WHERE xflw.request_id = gn_request_id
    AND   xflw.implemented_flag IS NULL
    ORDER BY xflw.base_code, xflw.supplier_code
    FOR UPDATE OF xflw.request_id NOWAIT
    ;
--
    -- 按分振り分け基準銀行取得カーソル
    CURSOR get_source_bank_cur
    IS
    SELECT flv.attribute1                          AS  bank_number       -- 他行分仕向銀行
          ,TO_NUMBER(flv.attribute11, '999,999')   AS  distribute_cnt    -- 按分件数
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_type_fb
    AND    NVL(flv.attribute10, cv_no) = cv_yes              -- 他行分振分け対象区分
    AND    flv.attribute11  IS NOT NULL                      -- 按分件数
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    AND    rownum          <= cn_bank_max                    -- 最大6行
    ORDER BY distribute_cnt, flv.attribute1
    ;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- FBデータ明細ワークテーブルロック取得
    -- ===============================================
    OPEN  fb_lines_cur;
    CLOSE fb_lines_cur;
    -- ===============================================
    -- FBデータ明細ワークテーブル・データ更新
    -- ===============================================
    BEGIN
      -- 按分振り分け実行更新
      <<source_bank_loop>>
      FOR lt_source_bank_rec in get_source_bank_cur LOOP
        <<manual_sub_loop>>
        FOR lt_manual_sub_rec in get_manual_sub_cur LOOP
          IF lt_source_bank_rec.distribute_cnt > ln_in_cnt THEN
            UPDATE xxcok_fb_lines_work  xflw
            SET    xflw.internal_bank_number = lt_source_bank_rec.bank_number  -- 仕向金融機関番号
                  ,xflw.implemented_flag     = cv_manual                       -- FB振分実行済区分
            WHERE CURRENT OF get_manual_sub_cur
            ;
            ln_in_cnt := ln_in_cnt + 1;
          ELSE
            exit;
          END IF;
        END LOOP manual_sub_loop;
        ln_in_cnt := 0;
      END LOOP source_bank_loop;
    EXCEPTION
      -- *** 更新処理エラー ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
        lv_errbuf  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ロックエラー ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10863                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => cv_wk_tbl_nm                         -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
      lv_errbuf  := lv_errmsg;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  END manual_distribute_proc;
--
  /**********************************************************************************
   * Procedure Name   : fb_header_record
   * Description      : FBヘッダーレコード出力(A-6)
   ***********************************************************************************/
  PROCEDURE fb_header_record(
     ov_errbuf                  OUT VARCHAR2                             -- エラー・メッセージ
    ,ov_retcode                 OUT VARCHAR2                             -- リターン・コード
    ,ov_errmsg                  OUT VARCHAR2                             -- ユーザー・エラー・メッセージ
    ,it_header_data_type        IN  VARCHAR2                             -- ヘッダーレコード区分
    ,it_type_code               IN  VARCHAR2                             -- 種別コード
    ,it_code_type               IN  VARCHAR2                             -- コード区分
    ,it_pay_date                IN  VARCHAR2                             -- 振込指定日
    ,it_bank_number             IN  fnd_lookup_values.attribute1%TYPE    -- 銀行番号
    ,it_bank_name_alt           IN  fnd_lookup_values.attribute2%TYPE    -- 銀行名カナ
    ,it_bank_num                IN  fnd_lookup_values.attribute3%TYPE    -- 銀行支店番号
    ,it_bank_branch_name_alt    IN  fnd_lookup_values.attribute4%TYPE    -- 銀行支店名カナ
    ,it_bank_account_type       IN  fnd_lookup_values.attribute5%TYPE    -- 預金種別
    ,it_bank_account_num        IN  fnd_lookup_values.attribute6%TYPE    -- 銀行口座番号
    ,it_eft_requester_id        IN  fnd_lookup_values.attribute7%TYPE    -- 依頼人コード
    ,it_account_holder_name_alt IN  fnd_lookup_values.attribute8%TYPE    -- 口座名義人カナ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fb_header_record';   -- プログラム名
    --================================
    -- ローカル変数
    --================================
    lv_errbuf                VARCHAR2(5000) DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode               VARCHAR2(1)    DEFAULT NULL;       -- リターン・コード
    lv_errmsg                VARCHAR2(5000) DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lb_retcode               BOOLEAN;                           -- メッセージ
    lv_fb_header_data        VARCHAR2(2000) DEFAULT NULL;       -- FB作成ヘッダーデータ
    lv_sc_client_code        VARCHAR2(10)   DEFAULT NULL;       -- DFF7_依頼人コード
    lv_client_name           VARCHAR2(40)   DEFAULT NULL;       -- DFF8_依頼人名
    lv_bank_number           VARCHAR2(4)    DEFAULT NULL;       -- DFF1_仕向金融機関番号
    lv_bank_name_alt         VARCHAR2(15)   DEFAULT NULL;       -- DFF2_仕向金融機関名
    lv_bank_num              VARCHAR2(3)    DEFAULT NULL;       -- DFF3_仕向支店番号
    lv_bank_branch_name_alt  VARCHAR2(15)   DEFAULT NULL;       -- DFF4_仕向支店名
    lv_bank_account_type     VARCHAR2(1)    DEFAULT NULL;       -- DFF5_預金種目（依頼人）
    lv_bank_account_num      VARCHAR2(7)    DEFAULT NULL;       -- DFF6_口座番号（依頼人）
    lv_dummy                 VARCHAR2(17)   DEFAULT NULL;       -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
    lv_sc_client_code       := LPAD( it_eft_requester_id, 10, cv_zero );                  -- DFF7_依頼人コード
    lv_client_name          := RPAD( NVL( it_account_holder_name_alt, cv_space ), 40 );   -- DFF8_依頼人名
    lv_bank_number          := LPAD( NVL( it_bank_number, cv_zero ), 4, cv_zero );        -- DFF1_仕向金融機関番号
    lv_bank_name_alt        := RPAD( NVL( it_bank_name_alt, cv_space ), 15 );             -- DFF2_仕向金融機関名
    lv_bank_num             := LPAD( NVL( it_bank_num, cv_zero ), 3, cv_zero );           -- DFF3_仕向支店番号
    lv_bank_branch_name_alt := RPAD( NVL( it_bank_branch_name_alt, cv_space ), 15 );      -- DFF4_仕向支店名
    lv_bank_account_type    := NVL( it_bank_account_type, cv_zero );                      -- DFF5_預金種目(依頼人)
    lv_bank_account_num     := LPAD( NVL( it_bank_account_num, cv_zero ), 7, cv_zero );   -- DFF6_口座番号(依頼人)
    lv_dummy                := LPAD( cv_space, 17, cv_space );                            -- ダミー
--
    lv_fb_header_data       := it_header_data_type     ||                     -- データ区分
                               it_type_code            ||                     -- 種別コード
                               it_code_type            ||                     -- コード区分
                               lv_sc_client_code       ||                     -- DFF7_依頼人コード
                               lv_client_name          ||                     -- DFF8_依頼人名
                               it_pay_date             ||                     -- 振込指定日
                               lv_bank_number          ||                     -- DFF1_仕向金融機関番号
                               lv_bank_name_alt        ||                     -- DFF2_仕向金融機関名
                               lv_bank_num             ||                     -- DFF3_仕向支店番号
                               lv_bank_branch_name_alt ||                     -- DFF4_仕向支店名
                               lv_bank_account_type    ||                     -- DFF5_預金種目(依頼人)
                               lv_bank_account_num     ||                     -- DFF6_口座番号(依頼人)
                               lv_dummy;                                      -- ダミー
    --=======================================================
    -- FBヘッダーレコード出力
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- 出力区分
                   ,iv_message  => lv_fb_header_data   -- メッセージ
                   ,in_new_line => 0                   -- 改行
                  );
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_header_record;
--
   /**********************************************************************************
   * Procedure Name   : fb_data_record
   * Description      : FBデータレコードの出力(A-7)
   ***********************************************************************************/
  PROCEDURE fb_data_record(
     ov_errbuf                  OUT VARCHAR2                                           -- エラー・メッセージ
    ,ov_retcode                 OUT VARCHAR2                                           -- リターン・コード
    ,ov_errmsg                  OUT VARCHAR2                                           -- ユーザー・エラー・メッセージ
    ,it_data_type               IN  xxcok_fb_lines_work.data_type%TYPE                 -- データレコード区分
    ,it_bank_number             IN  xxcok_fb_lines_work.bank_number%TYPE               -- 被仕向金融機関番号
    ,it_bank_name_alt           IN  xxcok_fb_lines_work.bank_name_alt%TYPE             -- 被仕向金融機関名
    ,it_bank_num                IN  xxcok_fb_lines_work.bank_num%TYPE                  -- 被仕向支店番号
    ,it_bank_branch_name_alt    IN  xxcok_fb_lines_work.bank_branch_name_alt%TYPE      -- 被仕向支店名
    ,it_clearinghouse_no        IN  xxcok_fb_lines_work.clearinghouse_no%TYPE          -- 手形交換所番号
    ,it_bank_account_type       IN  xxcok_fb_lines_work.bank_account_type%TYPE         -- 預金種目
    ,it_bank_account_num        IN  xxcok_fb_lines_work.bank_account_num%TYPE          -- 口座番号
    ,it_account_holder_name_alt IN  xxcok_fb_lines_work.account_holder_name_alt%TYPE   -- 受取人名
    ,it_transfer_amount         IN  xxcok_fb_lines_work.transfer_amount%TYPE           -- 振込金額
    ,it_record_type             IN  xxcok_fb_lines_work.record_type%TYPE               -- 新規レコード
    ,it_base_code               IN  xxcok_fb_lines_work.base_code%TYPE                 -- 拠点コード
    ,it_supplier_code           IN  xxcok_fb_lines_work.supplier_code%TYPE             -- 仕入先コード
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'fb_data_record';   -- プログラム名
    --=================================
    -- ローカル変数
    --=================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;      -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;      -- リターン・コード
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;      -- ユーザー・エラー・メッセージ
    lb_retcode                  BOOLEAN;                          -- メッセージ
    lv_fb_line_data             VARCHAR2(5000) DEFAULT NULL;      -- FB作成明細データ
    lv_transfer_amount          VARCHAR2(10)   DEFAULT NULL;      -- 振込金額
    lv_base_code                VARCHAR2(10)   DEFAULT NULL;      -- 拠点コード
    lv_supplier_code            VARCHAR2(10)   DEFAULT NULL;      -- 仕入先コード
    lv_dummy                    VARCHAR2(17)   DEFAULT NULL;      -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
    lv_transfer_amount := TO_CHAR( NVL( it_transfer_amount, cn_zero ), 'FM0000000000');    -- 振込金額
    lv_base_code       := LPAD( NVL( it_base_code, cv_space ), 10 , cv_zero );             -- 拠点コード
    lv_supplier_code   := LPAD( NVL( it_supplier_code, cv_space ), 10 , cv_zero );         -- 仕入先コード
    lv_dummy           := LPAD( cv_space, 9, cv_space );                                   -- ダミー
--
    lv_fb_line_data    := it_data_type               ||         -- データ区分
                          it_bank_number             ||         -- 被仕向金融機関番号
                          it_bank_name_alt           ||         -- 被仕向金融機関名
                          it_bank_num                ||         -- 被仕向支店番号
                          it_bank_branch_name_alt    ||         -- 被仕向支店名
                          it_clearinghouse_no        ||         -- 手形交換所番号
                          it_bank_account_type       ||         -- 預金種目
                          it_bank_account_num        ||         -- 口座番号
                          it_account_holder_name_alt ||         -- 受取人名
                          lv_transfer_amount         ||         -- 振込金額
                          it_record_type             ||         -- 新規レコード
                          lv_base_code               ||         -- 拠点コード
                          lv_supplier_code           ||         -- 仕入先コード
                          lv_dummy;                             -- ダミー
    --=======================================================
    -- FBデータレコード出力
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- 出力区分
                   ,iv_message  => lv_fb_line_data     -- メッセージ
                   ,in_new_line => 0                   -- 改行
                  );
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_data_record;
--
   /**********************************************************************************
   * Procedure Name   : fb_trailer_record
   * Description      : FBトレーラレコードの出力(A-8)
   ***********************************************************************************/
  PROCEDURE fb_trailer_record(
     ov_errbuf                OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode               OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg                OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    ,in_total_transfer_cnt    IN  NUMBER       -- 明細レコード件数
    ,in_total_transfer_amount IN  NUMBER       -- 振込合計金額
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fb_trailer_record';  -- プログラム名
    cv_data_type  CONSTANT VARCHAR2(1)   := '8';                  -- データ区分
    --=================================
    -- ローカル変数
    --=================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;         -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT NULL;         -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;         -- ユーザー・エラー・メッセージ
    lb_retcode     BOOLEAN;                             -- メッセージ
    lv_fb_trailer  VARCHAR2(2000) DEFAULT NULL;         -- FB作成トレーラレコード
    lv_data_type   VARCHAR2(1)    DEFAULT NULL;         -- データ区分
    lv_total_cnt   VARCHAR2(6)    DEFAULT NULL;         -- 合計件数
    lv_total_amt   VARCHAR2(12)   DEFAULT NULL;         -- 合計金額
    lv_dummy       VARCHAR2(101)  DEFAULT NULL;         -- ダミー
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
--
    lv_data_type  := cv_data_type;                                              -- データ区分
    lv_total_cnt  := LPAD( TO_CHAR( in_total_transfer_cnt ), 6, cv_zero );      -- 明細レコード件数
    lv_total_amt  := LPAD( TO_CHAR( in_total_transfer_amount ), 12, cv_zero );  -- 振込合計金額
    lv_dummy      := LPAD( cv_space, 101, cv_space );                           -- ダミー
--
    lv_fb_trailer := lv_data_type ||            -- データ区分
                     lv_total_cnt ||            -- 合計件数
                     lv_total_amt ||            -- 合計金額
                     lv_dummy;                  -- ダミー
    --=======================================================
    -- FBトレーラレコード出力
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- 出力区分
                   ,iv_message  => lv_fb_trailer       -- メッセージ
                   ,in_new_line => 0                   -- 改行
                  );
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_trailer_record;
--
   /**********************************************************************************
   * Procedure Name   : fb_end_record
   * Description      : FBエンドレコードの出力(A-9)
   ***********************************************************************************/
  PROCEDURE fb_end_record(
     ov_errbuf      OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode     OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg      OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    --================================
    -- ローカル定数
    --================================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'fb_end_record';    -- プログラム名
    cv_data_type CONSTANT VARCHAR2(1)   := '9';                -- データ区分
    cv_at_mark   CONSTANT VARCHAR2(1)   := CHR( 64 );          -- アットマーク
    --================================
    -- ローカル変数
    --================================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;        -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;        -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;        -- ユーザー・エラー・メッセージ
    lb_retcode    BOOLEAN;                            -- メッセージ
    lv_fb_end     VARCHAR2(2000) DEFAULT NULL;        -- FB作成エンドレコード
    lv_data_type  VARCHAR2(1)    DEFAULT NULL;        -- データ区分
    lv_dummy1     VARCHAR2(117)  DEFAULT NULL;        -- ダミー1
    lv_dummy2     VARCHAR2(1)    DEFAULT NULL;        -- ダミー2
    lv_dummy3     VARCHAR2(1)    DEFAULT NULL;        -- ダミー3
--
  BEGIN
    -- ステータス初期化
    ov_retcode   := cv_status_normal;
--
    lv_data_type := cv_data_type;                     -- データ区分
    lv_dummy1    := LPAD( cv_space, 117, cv_space );  -- ダミー1
    lv_dummy2    := cv_at_mark;                       -- ダミー2
    lv_dummy3    := cv_space;                         -- ダミー3
--
    lv_fb_end := lv_data_type ||                -- データ区分
                 lv_dummy1    ||                -- ダミー1
                 lv_dummy2    ||                -- ダミー2
                 lv_dummy3;                     -- ダミー3
    --=======================================================
    -- FBエンドレコード出力
    --=======================================================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     -- 出力区分
                   ,iv_message  => lv_fb_end           -- メッセージ
                   ,in_new_line => 0                   -- 改行
                  );
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END fb_end_record;
--
  /**********************************************************************************
   * Procedure Name   : output_fb_proc
   * Description      : FBデータ出力処理(A-5)
   ***********************************************************************************/
  PROCEDURE output_fb_proc(
     ov_errbuf                  OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode                 OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg                  OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_fb_proc';                           -- プログラム名
    --================================
    -- ローカル変数
    --================================
    lv_errbuf                   VARCHAR2(5000) DEFAULT NULL;                            -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1)    DEFAULT NULL;                            -- リターン・コード
    lv_errmsg                   VARCHAR2(5000) DEFAULT NULL;                            -- ユーザー・エラー・メッセージ
    lb_retcode                  BOOLEAN;                                                -- リターン・コード
    lv_header_rec               VARCHAR2(1)    DEFAULT cv_no;
    lv_bank_code                fnd_lookup_values.lookup_code%TYPE   DEFAULT '0000';
    ln_total_transfer_amount    NUMBER         DEFAULT 0;                               -- FB明細振込合計金額
    ln_total_transfer_cnt       NUMBER         DEFAULT 0;                               -- FB明細レコード件数
    lv_tbl_nm                   VARCHAR2(100)  DEFAULT NULL;                            -- テーブル名
--
    --===============================
    -- ローカル例外
    --===============================
    output_warning_expt         EXCEPTION; -- FB出力処理警告エラー
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- FBデータ取得カーソル
    CURSOR fb_data_cur(gn_request_id IN NUMBER)
    IS
    SELECT xflw.internal_bank_number     AS internal_bank_number          -- 仕向金融機関番号
          ,xflw.header_data_type         AS header_data_type              -- ヘッダーレコード区分
          ,xflw.type_code                AS type_code                     -- 種別コード
          ,xflw.code_type                AS code_type                     -- コード区分
          ,xflw.pay_date                 AS pay_date                      -- 振込指定日
          ,xflw.data_type                AS data_type                     -- データレコード区分
          ,xflw.bank_number              AS bank_number                   -- 被仕向金融機関番号
          ,xflw.bank_name_alt            AS bank_name_alt                 -- 被仕向金融機関名
          ,xflw.bank_num                 AS bank_num                      -- 被仕向支店番号
          ,xflw.bank_branch_name_alt     AS bank_branch_name_alt          -- 被仕向支店名
          ,xflw.clearinghouse_no         AS clearinghouse_no              -- 手形交換所番号
          ,xflw.bank_account_type        AS bank_account_type             -- 預金種目
          ,xflw.bank_account_num         AS bank_account_num              -- 口座番号
          ,xflw.account_holder_name_alt  AS account_holder_name_alt       -- 受取人名
          ,xflw.transfer_amount          AS transfer_amount               -- 振込金額
          ,xflw.record_type              AS record_type                   -- 新規レコード
          ,xflw.base_code                AS base_code                     -- 拠点コード
          ,xflw.supplier_code            AS supplier_code                 -- 仕入先コード
          ,flv.lookup_code               AS lookup_code                   -- 振り分け銀行
          ,flv.meaning                   AS meaning                       -- 振り分け銀行名
          ,flv.attribute1                AS attribute1                    -- FB他行分仕向銀行
          ,flv.attribute2                AS attribute2                    -- FB他行分仕向銀行名カナ
          ,flv.attribute3                AS attribute3                    -- FB他行分仕向銀行支店番号
          ,flv.attribute4                AS attribute4                    -- FB他行分仕向銀行支店名カナ
          ,flv.attribute5                AS attribute5                    -- FB他行分仕向銀行預金種別
          ,flv.attribute6                AS attribute6                    -- FB他行分仕向銀行口座番号
          ,flv.attribute7                AS attribute7                    -- FB他行分仕向銀行依頼人コード
          ,flv.attribute8                AS attribute8                    -- FB他行分仕向銀行依頼人名
    FROM   xxcok_fb_lines_work xflw    -- FBデータ明細ワークテーブル
          ,fnd_lookup_values   flv     -- 参照表（FB他行分仕向銀行）
    WHERE  xflw.request_id  = gn_request_id
    AND    flv.lookup_type  = cv_lookup_type_fb
    AND    flv.lookup_code  = xflw.internal_bank_number
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    ORDER BY xflw.internal_bank_number, xflw.base_code, xflw.supplier_code
    ;
--
    CURSOR fb_lookup_cur
    IS
      SELECT 'X'
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      FOR UPDATE OF flv.lookup_code NOWAIT;
--
    CURSOR fb_lines_cur
    IS
      SELECT 'X'
      FROM   xxcok_fb_lines_work  xflw
      WHERE  xflw.request_id = gn_request_id
      FOR UPDATE OF xflw.request_id NOWAIT;
--
  BEGIN
    -- ステータス初期化
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 参照表（FB他行分仕向銀行）ロック取得
    -- ===============================================
    OPEN  fb_lookup_cur;
    CLOSE fb_lookup_cur;
    lv_tbl_nm := cv_loopup_tbl_nm;
--
    << fb_loop >>
    FOR fb_data_rec IN fb_data_cur(gn_request_id) LOOP
      IF ( fb_data_rec.internal_bank_number <> lv_bank_code ) THEN
        IF ( lv_header_rec = cv_yes ) THEN
          --==================================================
          -- A-8.FBトレーラレコードの出力(A-8)
          --==================================================
          fb_trailer_record(
            ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
          , ov_retcode               => lv_retcode                 -- リターン・コード
          , ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
          , in_total_transfer_cnt    => ln_total_transfer_cnt      -- 明細レコード件数
          , in_total_transfer_amount => ln_total_transfer_amount   -- 明細合計金額
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- A-9.FBエンドレコードの出力(A-9)
          --==================================================
          fb_end_record(
            ov_errbuf      => lv_errbuf            -- エラー・メッセージ
          , ov_retcode     => lv_retcode           -- リターン・コード
          , ov_errmsg      => lv_errmsg            -- ユーザー・エラー・メッセージ
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 明細レコード件数（按分件数）、明細合計金額の登録
          BEGIN
            UPDATE fnd_lookup_values flv
            SET    flv.attribute11 = TO_CHAR(ln_total_transfer_cnt, '999,999')
                  ,flv.attribute12 = TO_CHAR(ln_total_transfer_amount, '999,999,999,999')
            WHERE  flv.lookup_type  = cv_lookup_type_fb
            AND    flv.lookup_code  = lv_bank_code
            AND    flv.enabled_flag = cv_yes
            AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                        AND NVL(flv.end_date_active, gd_proc_date)
            AND    flv.language     = USERENV('LANG')
            ;
          EXCEPTION
            -- *** 更新処理エラー ***
            WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                       ,iv_token_value1 => lv_tbl_nm                            -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                       ,iv_token_value2 => SQLERRM                              -- トークン値2
                      );
              lv_errbuf := lv_errmsg;
              ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_error;
          END;
--
          -- 振込金額合計、レコード件数クリア
          ln_total_transfer_amount := 0;
          ln_total_transfer_cnt    := 0;
        END IF;
        --==================================================
        -- A-6.FB作成ヘッダーデータの出力
        --==================================================
        fb_header_record(
          ov_errbuf                  => lv_errbuf                     -- エラー・メッセージ
        , ov_retcode                 => lv_retcode                    -- リターン・コード
        , ov_errmsg                  => lv_errmsg                     -- ユーザー・エラー・メッセージ
        , it_header_data_type        => fb_data_rec.header_data_type  -- ヘッダーレコード区分
        , it_type_code               => fb_data_rec.type_code         -- 種別コード
        , it_code_type               => fb_data_rec.code_type         -- コード区分
        , it_pay_date                => fb_data_rec.pay_date          -- 振込指定日
        , it_bank_number             => fb_data_rec.attribute1        -- FB他行分仕向銀行
        , it_bank_name_alt           => fb_data_rec.attribute2        -- 銀行名カナ
        , it_bank_num                => fb_data_rec.attribute3        -- 銀行支店番号
        , it_bank_branch_name_alt    => fb_data_rec.attribute4        -- 銀行支店名カナ
        , it_bank_account_type       => fb_data_rec.attribute5        -- 預金種別
        , it_bank_account_num        => fb_data_rec.attribute6        -- 銀行口座番号
        , it_eft_requester_id        => fb_data_rec.attribute7        -- 依頼人コード
        , it_account_holder_name_alt => fb_data_rec.attribute8        -- 依頼人名
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        lv_bank_code  := fb_data_rec.internal_bank_number;
        lv_header_rec := cv_yes;
      END IF;
--
      BEGIN
        --==================================================
        -- A-7.FB作成データレコードの出力(A-6)
        --==================================================
        fb_data_record(
          ov_errbuf                  => lv_errbuf                             -- エラー・メッセージ
        , ov_retcode                 => lv_retcode                            -- リターン・コード
        , ov_errmsg                  => lv_errmsg                             -- ユーザー・エラー・メッセージ
        , it_data_type               => fb_data_rec.data_type                 -- データレコード区分
        , it_bank_number             => fb_data_rec.bank_number               -- 被仕向金融機関番号
        , it_bank_name_alt           => fb_data_rec.bank_name_alt             -- 被仕向金融機関名
        , it_bank_num                => fb_data_rec.bank_num                  -- 被仕向支店番号
        , it_bank_branch_name_alt    => fb_data_rec.bank_branch_name_alt      -- 被仕向支店名
        , it_clearinghouse_no        => fb_data_rec.clearinghouse_no          -- 手形交換所番号
        , it_bank_account_type       => fb_data_rec.bank_account_type         -- 預金種目
        , it_bank_account_num        => fb_data_rec.bank_account_num          -- 口座番号
        , it_account_holder_name_alt => fb_data_rec.account_holder_name_alt   -- 受取人名
        , it_transfer_amount         => fb_data_rec.transfer_amount           -- 振込金額
        , it_record_type             => fb_data_rec.record_type               -- 新規レコード
        , it_base_code               => fb_data_rec.base_code                 -- 拠点コード
        , it_supplier_code           => fb_data_rec.supplier_code             -- 仕入先コード
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 仕向銀行別：振込金額合計、レコード件数
        ln_total_transfer_amount := ln_total_transfer_amount + fb_data_rec.transfer_amount;
        ln_total_transfer_cnt    := ln_total_transfer_cnt    + 1;
        -- 成功件数
        gn_target_cnt := gn_target_cnt + 1;
        gn_out_cnt    := gn_out_cnt    + 1;                             -- FB総合振込金額合計
        gn_out_amount := gn_out_amount + fb_data_rec.transfer_amount;   -- FBレコード総件数
      END;
    END LOOP fb_loop;
    --======================================================
    -- 参照表（FB他行分仕向銀行）情報エラー
    --======================================================
    IF( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_10876
                      ,iv_token_name1  => cv_loopup_type
                      ,iv_token_value1 => cv_lookup_type_fb
                    );
      RAISE output_warning_expt;
    END IF;
    --==================================================
    -- A-8.FBトレーラレコードの出力(A-8)
    --==================================================
    fb_trailer_record(
      ov_errbuf                => lv_errbuf                  -- エラー・メッセージ
    , ov_retcode               => lv_retcode                 -- リターン・コード
    , ov_errmsg                => lv_errmsg                  -- ユーザー・エラー・メッセージ
    , in_total_transfer_cnt    => ln_total_transfer_cnt      -- 明細レコード件数
    , in_total_transfer_amount => ln_total_transfer_amount   -- 振込合計金額
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-9.FBエンドレコードの出力(A-9)
    --==================================================
    fb_end_record(
      ov_errbuf      => lv_errbuf            -- エラー・メッセージ
    , ov_retcode     => lv_retcode           -- リターン・コード
    , ov_errmsg      => lv_errmsg            -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      -- 明細レコード件数（按分件数）、明細合計金額の登録
      UPDATE fnd_lookup_values flv
      SET    flv.attribute11 = TO_CHAR(ln_total_transfer_cnt, '999,999')
            ,flv.attribute12 = TO_CHAR(ln_total_transfer_amount, '999,999,999,999')
      WHERE  flv.lookup_type  = cv_lookup_type_fb
      AND    flv.lookup_code  = lv_bank_code
      AND    flv.enabled_flag = cv_yes
      AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                  AND NVL(flv.end_date_active, gd_proc_date)
      AND    flv.language     = USERENV('LANG')
      ;
--
      -- ===============================================
      -- FBデータ明細ワークテーブルロック取得
      -- ===============================================
      OPEN  fb_lines_cur;
      CLOSE fb_lines_cur;
      lv_tbl_nm := cv_wk_tbl_nm;
--
      --  FBデータ明細ワークテーブルWHO列更新
      UPDATE xxcok_fb_lines_work  xflw
      SET    created_by              = cn_created_by                      -- 作成者
            ,creation_date           = cd_creation_date                   -- 作成日
            ,last_updated_by         = cn_last_updated_by                 -- 最終更新者
            ,last_update_date        = cd_last_update_date                -- 最終更新日
            ,last_update_login       = cn_last_update_login               -- 最終更新ログイン
            ,request_id              = cn_request_id                      -- 要求ID
            ,program_application_id  = cn_program_application_id          -- アプリケーションID
            ,program_id              = cn_program_id                      -- プログラムID
            ,program_update_date     = cd_program_update_date             -- プログラム更新日
      WHERE  xflw.request_id = gn_request_id
      ;
    EXCEPTION
      -- *** 更新処理エラー ***
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10864                     -- メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           -- トークンコード1
                 ,iv_token_value1 => lv_tbl_nm                            -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    --*** ロックエラー ***
    WHEN global_lock_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appli_xxcok                       -- アプリケーション短縮名
                 ,iv_name         => cv_msg_cok_10863                     -- メッセージコード
                 ,iv_token_name1  => lv_tbl_nm                            -- トークンコード1
                 ,iv_token_value1 => cv_loopup_tbl_nm                     -- トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       -- トークンコード2
                 ,iv_token_value2 => SQLERRM                              -- トークン値2
                );
      lv_errbuf := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** FB出力処理警告終了 ***
    WHEN output_warning_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END output_fb_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2     -- リターン・コード
  , ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  , in_request_id      IN  NUMBER       -- パラメータ：FBデータファイル作成時の要求ID
  , iv_internal_bank1  IN  VARCHAR2     -- パラメータ：他行分仕向銀行1
  , in_bank_cnt1       IN  NUMBER       -- パラメータ：仕向銀行1への按分件数
  , iv_internal_bank2  IN  VARCHAR2     -- パラメータ：他行分仕向銀行2
  , in_bank_cnt2       IN  NUMBER       -- パラメータ：仕向銀行2への按分件数
  , iv_internal_bank3  IN  VARCHAR2     -- パラメータ：他行分仕向銀行3
  , in_bank_cnt3       IN  NUMBER       -- パラメータ：仕向銀行3への按分件数
  , iv_internal_bank4  IN  VARCHAR2     -- パラメータ：他行分仕向銀行4
  , in_bank_cnt4       IN  NUMBER       -- パラメータ：仕向銀行4への按分件数
  , iv_internal_bank5  IN  VARCHAR2     -- パラメータ：他行分仕向銀行5
  , in_bank_cnt5       IN  NUMBER       -- パラメータ：仕向銀行5への按分件数
  , iv_internal_bank6  IN  VARCHAR2     -- パラメータ：他行分仕向銀行6
  , in_bank_cnt6       IN  NUMBER       -- パラメータ：仕向銀行6への按分件数
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                        -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                        -- リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                        -- ユーザー・エラー・メッセージ
    lb_retcode                 BOOLEAN        DEFAULT NULL;                        -- メッセージ・リターン・コード
    --
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    ov_retcode := cv_status_normal;
    --==================================================
    -- グローバル変数の初期化
    --==================================================
    gn_target_cnt            := 0;        -- 対象件数
    gn_error_cnt             := 0;        -- エラー件数
    gn_out_cnt               := 0;        -- 成功件数
    --==================================================
    -- A-1.初期処理
    --==================================================
    init(
      ov_errbuf         => lv_errbuf              -- エラー・メッセージ
    , ov_retcode        => lv_retcode             -- リターン・コード
    , ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
    , in_request_id     => in_request_id          -- 処理パラメータ
    , iv_internal_bank1 => iv_internal_bank1      -- パラメータ：他行分仕向銀行1
    , in_bank_cnt1      => in_bank_cnt1           -- パラメータ：仕向銀行1への按分件数
    , iv_internal_bank2 => iv_internal_bank2      -- パラメータ：他行分仕向銀行2
    , in_bank_cnt2      => in_bank_cnt2           -- パラメータ：仕向銀行2への按分件数
    , iv_internal_bank3 => iv_internal_bank3      -- パラメータ：他行分仕向銀行3
    , in_bank_cnt3      => in_bank_cnt3           -- パラメータ：仕向銀行3への按分件数
    , iv_internal_bank4 => iv_internal_bank4      -- パラメータ：他行分仕向銀行4
    , in_bank_cnt4      => in_bank_cnt4           -- パラメータ：仕向銀行4への按分件数
    , iv_internal_bank5 => iv_internal_bank5      -- パラメータ：他行分仕向銀行5
    , in_bank_cnt5      => in_bank_cnt5           -- パラメータ：仕向銀行5への按分件数
    , iv_internal_bank6 => iv_internal_bank6      -- パラメータ：他行分仕向銀行6
    , in_bank_cnt6      => in_bank_cnt6           -- パラメータ：仕向銀行6への按分件数
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-2.初期処理テーブル更新(A-2)
    --==================================================
    init_update_data(
      ov_errbuf         => lv_errbuf              -- エラー・メッセージ
    , ov_retcode        => lv_retcode             -- リターン・コード
    , ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
    , iv_internal_bank1 => iv_internal_bank1      -- パラメータ：他行分仕向銀行1
    , in_bank_cnt1      => in_bank_cnt1           -- パラメータ：仕向銀行1への按分件数
    , iv_internal_bank2 => iv_internal_bank2      -- パラメータ：他行分仕向銀行2
    , in_bank_cnt2      => in_bank_cnt2           -- パラメータ：仕向銀行2への按分件数
    , iv_internal_bank3 => iv_internal_bank3      -- パラメータ：他行分仕向銀行3
    , in_bank_cnt3      => in_bank_cnt3           -- パラメータ：仕向銀行3への按分件数
    , iv_internal_bank4 => iv_internal_bank4      -- パラメータ：他行分仕向銀行4
    , in_bank_cnt4      => in_bank_cnt4           -- パラメータ：仕向銀行4への按分件数
    , iv_internal_bank5 => iv_internal_bank5      -- パラメータ：他行分仕向銀行5
    , in_bank_cnt5      => in_bank_cnt5           -- パラメータ：仕向銀行5への按分件数
    , iv_internal_bank6 => iv_internal_bank6      -- パラメータ：他行分仕向銀行6
    , in_bank_cnt6      => in_bank_cnt6           -- パラメータ：仕向銀行6への按分件数
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-3.FBデータ自動振り分け処理(A-3)
    --==================================================
    auto_distribute_proc(
      ov_errbuf         => lv_errbuf              -- エラー・メッセージ
    , ov_retcode        => lv_retcode             -- リターン・コード
    , ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-4.FBデータ按分振り分け処理(A-4)
    --==================================================
    manual_distribute_proc(
      ov_errbuf         => lv_errbuf              -- エラー・メッセージ
    , ov_retcode        => lv_retcode             -- リターン・コード
    , ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- A-5.FBデータ出力処理(A-5)
    --==================================================
    output_fb_proc(
      ov_errbuf         => lv_errbuf              -- エラー・メッセージ
    , ov_retcode        => lv_retcode             -- リターン・コード
    , ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF( lv_errbuf IS NOT NULL ) THEN
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      END IF;
      ov_retcode := lv_retcode;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf             OUT VARCHAR2     -- エラーメッセージ
  , retcode            OUT VARCHAR2     -- エラーコード
  , in_request_id      IN  NUMBER       -- パラメータ：FBデータファイル作成時の要求ID
  , iv_internal_bank1  IN  VARCHAR2     -- パラメータ：他行分仕向銀行1
  , in_bank_cnt1       IN  NUMBER       -- パラメータ：仕向銀行1への按分件数
  , iv_internal_bank2  IN  VARCHAR2     -- パラメータ：他行分仕向銀行2
  , in_bank_cnt2       IN  NUMBER       -- パラメータ：仕向銀行2への按分件数
  , iv_internal_bank3  IN  VARCHAR2     -- パラメータ：他行分仕向銀行3
  , in_bank_cnt3       IN  NUMBER       -- パラメータ：仕向銀行3への按分件数
  , iv_internal_bank4  IN  VARCHAR2     -- パラメータ：他行分仕向銀行4
  , in_bank_cnt4       IN  NUMBER       -- パラメータ：仕向銀行4への按分件数
  , iv_internal_bank5  IN  VARCHAR2     -- パラメータ：他行分仕向銀行5
  , in_bank_cnt5       IN  NUMBER       -- パラメータ：仕向銀行5への按分件数
  , iv_internal_bank6  IN  VARCHAR2     -- パラメータ：他行分仕向銀行6
  , in_bank_cnt6       IN  NUMBER       -- パラメータ：仕向銀行6への按分件数
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';   -- プログラム名
    cv_bank         CONSTANT VARCHAR2(30)  := '仕向銀行：';
    cv_count        CONSTANT VARCHAR2(30)  := '件数：';
    cv_c_percentage CONSTANT VARCHAR2(30)  := ' 件、 割合：';
    cv_amount       CONSTANT VARCHAR2(30)  := '合計金額 : ';
    cv_a_percentage CONSTANT VARCHAR2(30)  := ' 円、 割合 : ';
    cv_percentage   CONSTANT VARCHAR2(30)  := ' %';
    cv_sub_title    CONSTANT VARCHAR2(50)  := 'FBデータ振り分け処理結果';
    cv_sub_line     CONSTANT VARCHAR2(120) := '---------------------------------------------------------------------------------------------------------------';
    cv_none_proc    CONSTANT VARCHAR2(50)  := '※仕向銀行振り分け未済';
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf           VARCHAR2(5000) DEFAULT NULL;        -- エラー・メッセージ
    lv_retcode          VARCHAR2(1)    DEFAULT NULL;        -- リターン・コード
    lv_errmsg           VARCHAR2(5000) DEFAULT NULL;        -- ユーザー・エラー・メッセージ
    lb_retcode          BOOLEAN;                            -- メッセージ
    ln_line_no          NUMBER         DEFAULT 1;           -- 振り分け処理結果ログ行番
    lv_fb_log           VARCHAR2(2000) DEFAULT NULL;        -- ログ編集
    ln_bank_cnt         NUMBER         DEFAULT 0;           -- FB明細レコード件数
    ln_bank_amount      NUMBER         DEFAULT 0;           -- FB明細合計金額
    ln_bank_zan_cnt     NUMBER         DEFAULT 0;           -- FB明細レコード件数(残)
    ln_bank_zan_amount  NUMBER         DEFAULT 0;           -- FB明細合計金額(残)
    ln_c_percentage     NUMBER         DEFAULT 0;           -- FB明細レコード件数に対する割合[%]
    ln_a_percentage     NUMBER         DEFAULT 0;           -- FB明細合計金額に対する割合[%]
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- FBデータファイル振り分け処理結果ログ出力カーソル
    CURSOR fb_result_log_cur
    IS
    SELECT flv.lookup_code                   AS  internal_bank       -- 振り分け銀行
          ,flv.meaning                       AS  internal_bank_name  -- 振り分け銀行名
          ,flv.attribute11                   AS  attribute11         -- 振り分け件数
          ,flv.attribute12                   AS  attribute12         -- 振り分け金額
          ,COUNT(xflw.internal_bank_number)  AS defaut_bank_count    -- デフォルト銀行への振り分け件数
          ,SUM(xflw.transfer_amount)         AS defaut_bank_amount   -- デフォルト銀行への振り分け金額合計
    FROM   fnd_lookup_values flv
          ,xxcok_fb_lines_work xflw
    WHERE  flv.lookup_code = xflw.INTERNAL_BANK_NUMBER(+)
    AND    xflw.INTERNAL_BANK_NUMBER(+) = gv_default_bank_code
    AND    xflw.IMPLEMENTED_FLAG(+) IS NOT NULL
    AND    flv.lookup_type  = cv_lookup_type_fb
    AND    flv.attribute11 IS NOT NULL
    AND    flv.enabled_flag = cv_yes
    AND    gd_proc_date BETWEEN NVL(flv.start_date_active, gd_proc_date)
                                AND NVL(flv.end_date_active, gd_proc_date)
    AND    flv.language     = USERENV('LANG')
    GROUP BY xflw.internal_bank_number, flv.meaning, flv.attribute11, flv.attribute12, flv.lookup_code
    ORDER BY flv.lookup_code
    ;
--
  BEGIN
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf         => lv_errbuf              -- エラー・メッセージ
     , ov_retcode        => lv_retcode             -- リターン・コード
     , ov_errmsg         => lv_errmsg              -- ユーザー・エラー・メッセージ
     , in_request_id     => in_request_id          -- 処理パラメータ
     , iv_internal_bank1 => iv_internal_bank1      -- パラメータ：他行分仕向銀行1
     , in_bank_cnt1      => in_bank_cnt1           -- パラメータ：仕向銀行1への按分件数
     , iv_internal_bank2 => iv_internal_bank2      -- パラメータ：他行分仕向銀行2
     , in_bank_cnt2      => in_bank_cnt2           -- パラメータ：仕向銀行2への按分件数
     , iv_internal_bank3 => iv_internal_bank3      -- パラメータ：他行分仕向銀行3
     , in_bank_cnt3      => in_bank_cnt3           -- パラメータ：仕向銀行3への按分件数
     , iv_internal_bank4 => iv_internal_bank4      -- パラメータ：他行分仕向銀行4
     , in_bank_cnt4      => in_bank_cnt4           -- パラメータ：仕向銀行4への按分件数
     , iv_internal_bank5 => iv_internal_bank5      -- パラメータ：他行分仕向銀行5
     , in_bank_cnt5      => in_bank_cnt5           -- パラメータ：仕向銀行5への按分件数
     , iv_internal_bank6 => iv_internal_bank6      -- パラメータ：他行分仕向銀行6
     , in_bank_cnt6      => in_bank_cnt6           -- パラメータ：仕向銀行6への按分件数
    );
    --ステータスセット
    retcode := lv_retcode;
    IF( lv_retcode <> cv_status_normal ) THEN
      -- 成功件数
      gn_out_cnt := 0;
      -- エラー件数
      gn_error_cnt := 1;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- 出力区分
                     ,iv_message  => lv_errbuf          -- メッセージ
                     ,in_new_line => 0                  -- 改行
                    );
    END IF;
    --================================================
    -- A-10.終了処理
    --================================================
    -- FBデータ振り分け処理結果ログ出力
    IF( gn_target_cnt > 0 AND gn_error_cnt <> 1) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,cv_sub_title
                     ,0
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,cv_sub_line
                     ,0
                    );
      <<fb_result_loop>>
      FOR lt_result_log_rec in fb_result_log_cur LOOP
        IF lt_result_log_rec.internal_bank = gv_default_bank_code
          AND  lt_result_log_rec.attribute11 <> TO_CHAR(lt_result_log_rec.defaut_bank_count, '999,999') THEN  -- FBデフォルト銀行
          ln_bank_cnt     := lt_result_log_rec.defaut_bank_count;
          ln_bank_amount  := lt_result_log_rec.defaut_bank_amount;
          ln_bank_zan_cnt     := TO_NUMBER(lt_result_log_rec.attribute11, '999,999') - ln_bank_cnt;
          ln_bank_zan_amount  := TO_NUMBER(lt_result_log_rec.attribute12, '999,999,999,999') - ln_bank_amount;
          lt_result_log_rec.attribute11 := TO_CHAR(ln_bank_cnt,    '999,999');
          lt_result_log_rec.attribute12 := TO_CHAR(ln_bank_amount, '999,999,999,999');
        ELSE
          ln_bank_cnt     := TO_NUMBER(lt_result_log_rec.attribute11, '999,999');
          ln_bank_amount  := TO_NUMBER(lt_result_log_rec.attribute12, '999,999,999,999');
        END IF;
        ln_c_percentage := ln_bank_cnt    / gn_out_cnt    * 100;
        ln_a_percentage := ln_bank_amount / gn_out_amount * 100;
        lv_errmsg := TO_CHAR(ln_line_no) || cv_msg_cont
                    || cv_bank   || lt_result_log_rec.internal_bank || cv_space || lt_result_log_rec.internal_bank_name || CHR(9)
                    || cv_count  || lt_result_log_rec.attribute11 || cv_c_percentage
                    || TO_CHAR(TRUNC(ln_c_percentage, 2)) || cv_percentage || CHR(9)
                    || cv_amount || lt_result_log_rec.attribute12 || cv_a_percentage || TO_CHAR(TRUNC(ln_a_percentage, 2))
                    || cv_percentage;
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- 出力区分
                       ,iv_message  => lv_errmsg         -- メッセージ
                       ,in_new_line => 0                 -- 改行
                      );
        ln_line_no := ln_line_no + 1;
      END LOOP fb_result_loop;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,cv_sub_line
                     ,0
                    );
      IF ln_bank_zan_cnt <> 0 THEN
        ln_c_percentage := ln_bank_zan_cnt    / gn_out_cnt    * 100;
        ln_a_percentage := ln_bank_zan_amount / gn_out_amount * 100;
        lv_errmsg := cv_none_proc || CHR(9)
                    || cv_count  || TO_CHAR(ln_bank_zan_cnt, '999,999') || cv_c_percentage
                    || TO_CHAR(TRUNC(ln_c_percentage, 2)) || cv_percentage || CHR(9)
                    || cv_amount || TO_CHAR(ln_bank_zan_amount, '9,999,999,999') || cv_a_percentage || TO_CHAR(TRUNC(ln_a_percentage, 2))
                    || cv_percentage;
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                     ,iv_message  => lv_errmsg         -- メッセージ
                     ,in_new_line => 0                 -- 改行
                    );
      END IF;
      lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,NULL
                    ,1
                   );
   END IF;
    -- 空行
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      FND_FILE.LOG
                     ,NULL
                     ,1
                    );
    END IF;
    --対象件数
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90000
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt, '999,999' )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- 出力区分
                   ,iv_message  => lv_errmsg         -- メッセージ
                   ,in_new_line => 0                 -- 改行
                  );
    --成功件数、合計金額
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxcok   -- XXCOK
                   ,iv_name         => cv_msg_cok_10877
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_out_cnt, '999,999' )
                   ,iv_token_name2  => cv_token_amount
                   ,iv_token_value2 => TO_CHAR( gn_out_amount, '999,999,999,999' )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- 出力区分
                   ,iv_message  => lv_errmsg         -- メッセージ
                   ,in_new_line => 0                 -- 改行
                  );
    --エラー件数
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt, '9,999' )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- 出力区分
                   ,iv_message  => lv_errmsg         -- メッセージ
                   ,in_new_line => 1                 -- 改行
                  );
    --終了メッセージ
    IF( lv_retcode = cv_status_normal ) THEN
      --メッセージ出力（処理が正常終了しました。）
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxccp
                     ,iv_name         => cv_msg_ccp_90004
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                     ,iv_message  => lv_errmsg         -- メッセージ
                     ,in_new_line => 0                 -- 改行
                    );
    ELSE
    --終了ステータスがエラーの場合はROLLBACKする
      ROLLBACK;
--
      --エラー終了（全件処理前の状態に戻しました。）
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appli_xxccp
                     ,iv_name        => cv_msg_ccp_90006
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                     ,iv_message  => lv_errmsg         -- メッセージ
                     ,in_new_line => 0                 -- 改行
                    );
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
END XXCOK016A05C;
/
