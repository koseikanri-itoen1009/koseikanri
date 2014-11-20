create or replace PACKAGE BODY XXCFR006A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A04C(body)
 * Description      : 入金一括消込アップロード
 * MD.050           : MD050_CFR_006_A04_入金一括消込アップロード
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              p 初期処理                                (A-1)
 *  get_if_data            p ファイルアップロードIFデータ取得処理    (A-2)
 *  devide_item            p デリミタ文字項目分割                    (A-3)
 *  insert_work            p ワークテーブル登録                      (A-4)
 *  check_data             p 妥当性チェック                          (A-5)
 *  get_cust_trx_data      p 取引情報設定                            (A-6)
 *  get_cash_rec_data      p 入金情報設定                            (A-7)
 *  ecxec_apply_api        p 入金消込API起動処理                     (A-8)
 *  proc_end               p 終了処理                                (A-9)
 *  check_data_lock        p 入金情報排他チェック                    (A-10)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/05/26    1.0   SCS 苅込 周平    新規作成
 *  2010/09/02    1.1   SCS 渡辺 学      E_本稼動_00390 追加対応
 *  2011/08/11    1.2   SCS 白川 篤史    E_本稼動_07667 追加対応
 *  2014/02/13    1.3   SCSK 中野 徹也   E_本稼動_11286 追加対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START  #######################
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
--################################  固定部 END  ##################################
--
--#######################  固定グローバル変数宣言部 START  #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;    -- 対象件数
  gn_normal_cnt    NUMBER;    -- 正常件数
  gn_error_cnt     NUMBER;    -- エラー件数
  gn_warn_cnt      NUMBER;    -- スキップ件数
--
--################################  固定部 END  ##################################
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
--################################  固定部 END  ##################################
---- ===============================
  -- ユーザー定義例外
  -- ===============================
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCFR006A04C';     -- パッケージ名
  cv_log               CONSTANT VARCHAR2(100) := 'LOG';              -- コンカレントログ出力先--
  cv_out               CONSTANT VARCHAR2(100) := 'OUTPUT';           -- コンカレント出力先--
  cv_yyyy_mm_dd        CONSTANT VARCHAR2(10)  := 'YYYY-MM-DD';       -- フォーマット
--
  cv_set_of_bks_id     CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  cv_upl_limit_of_count  CONSTANT VARCHAR2(30) := 'XXCFR1_UPL_LIMIT_OF_COUNT'; -- アップロード用対象件数閾値
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  cv_appl_name_cfr     CONSTANT VARCHAR2(10)  := 'XXCFR';            -- アドオン：AR
  cv_appl_name_cmn     CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
  cv_appl_name_ar      CONSTANT VARCHAR2(10)  := 'AR';               -- 標準：AR
--
  cv_closing_status_o  CONSTANT VARCHAR2(1)   := 'O';                -- 会計期間ステータス(オープン)
--
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
  -- 入金ステータス
  cv_status_unapp      CONSTANT VARCHAR2(5)   := 'UNAPP';            -- 未消込
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
--
  -- メッセージ
  cv_msg_006a04_001    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00094'; -- アップロード初期出力メッセージ
  cv_msg_006a04_002    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_006a04_003    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00095'; -- フォーマットエラー
  cv_msg_006a04_004    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00096'; -- 入金データなしエラー
  cv_msg_006a04_005    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00097'; -- 入金データ重複エラー
  cv_msg_006a04_006    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00098'; -- 入金ステータスエラー
  cv_msg_006a04_007    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00099'; -- 入金残高エラー
  cv_msg_006a04_008    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00100'; -- 支払方法セキュリティエラー
  cv_msg_006a04_009    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00101'; -- 文書番号重複エラー
  cv_msg_006a04_010    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00102'; -- 文書番号存在なしエラー
  cv_msg_006a04_011    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00103'; -- 消込金額エラー
  cv_msg_006a04_012    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00104'; -- APIエラーメッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  cv_msg_006a04_013    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00138'; -- 消込済み文書番号エラー
  cv_msg_006a04_014    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00139'; -- ファイルフォーマットエラー
  cv_msg_006a04_015    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00140'; -- 債権閾値チェックエラー(大口)
  cv_msg_006a04_016    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00141'; -- 債権閾値チェックエラー(小口)
  cv_msg_006a04_017    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- テーブルロックエラー
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  -- 日本語辞書参照コード
  cv_dict_cfr_00604001  CONSTANT VARCHAR2(20) := 'CFR006A04001'; -- 入金テーブル
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  -- トークン
  cv_tkn_006a04_001_1  CONSTANT VARCHAR2(30) := 'FILE_NAME';             -- アップロードファイル名
  cv_tkn_006a04_001_2  CONSTANT VARCHAR2(30) := 'CSV_NAME';              -- CSVファイル名
  cv_tkn_006a04_002_1  CONSTANT VARCHAR2(30) := 'PROF_NAME';             -- プロファイル名
  cv_tkn_006a04_003_1  CONSTANT VARCHAR2(30) := 'ROW_COUNT';             -- 行数
  cv_tkn_006a04_003_2  CONSTANT VARCHAR2(30) := 'DATA_INFO';             -- 値
  cv_tkn_006a04_003_3  CONSTANT VARCHAR2(30) := 'INFO';                  -- エラーメッセージ
  cv_tkn_006a04_004_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_004_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- 顧客コード
  cv_tkn_006a04_004_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- 入金日
  cv_tkn_006a04_005_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_005_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- 顧客コード
  cv_tkn_006a04_005_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- 入金日
  cv_tkn_006a04_006_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_006_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- 顧客コード
  cv_tkn_006a04_006_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- 入金日
  cv_tkn_006a04_006_4  CONSTANT VARCHAR2(30) := 'STATUS';                -- ステータス
  cv_tkn_006a04_007_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_007_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- 顧客コード
  cv_tkn_006a04_007_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- 入金日
  cv_tkn_006a04_007_4  CONSTANT VARCHAR2(30) := 'CASH_AMOUNT';           -- 入金残額
  cv_tkn_006a04_007_5  CONSTANT VARCHAR2(30) := 'TRX_AMOUNT_ALL';        -- 消込金額合計
  cv_tkn_006a04_008_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_008_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- 顧客コード
  cv_tkn_006a04_008_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- 入金日
  cv_tkn_006a04_009_1  CONSTANT VARCHAR2(30) := 'DOC_SEQUENCE_VALUE';    -- 文書番号
  cv_tkn_006a04_010_1  CONSTANT VARCHAR2(30) := 'DOC_SEQUENCE_VALUE';    -- 文書番号
  cv_tkn_006a04_011_1  CONSTANT VARCHAR2(30) := 'TRX_NUMBER';            -- 取引番号
  cv_tkn_006a04_011_2  CONSTANT VARCHAR2(30) := 'AMOUNT_DUE_REMAINING';  -- 未回収残高
  cv_tkn_006a04_011_3  CONSTANT VARCHAR2(30) := 'TRX_AMOUNT';            -- 消込金額
  cv_tkn_006a04_012_1  CONSTANT VARCHAR2(30) := 'TRX_NUMBER';            -- 取引番号
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  cv_tkn_006a04_012_2  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_013_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_006a04_013_2  CONSTANT VARCHAR2(30) := 'DOC_SEQUENCE_VALUE';    -- 文書番号
  cv_tkn_006a04_014_1  CONSTANT VARCHAR2(30) := 'FILE_FORMAT';           -- ファイルフォーマット
  cv_tkn_006a04_017_1  CONSTANT VARCHAR2(30) := 'TABLE';                 -- テーブル名
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  cv_tkn_val_006a04_001_1  CONSTANT VARCHAR2(30) := 'APP_XXCFR1_30001';  -- アップロードファイル名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE ttype_work_table         IS TABLE OF xxcfr_apply_upload_work%ROWTYPE
                                   INDEX BY PLS_INTEGER;
--
  TYPE ttype_receipt_number     IS TABLE OF xxcfr_apply_upload_work.receipt_number%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_account_number     IS TABLE OF xxcfr_apply_upload_work.account_number%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_receipt_date       IS TABLE OF xxcfr_apply_upload_work.receipt_date%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_apply_date         IS TABLE OF xxcfr_apply_upload_work.apply_date%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_apply_gl_date      IS TABLE OF xxcfr_apply_upload_work.apply_gl_date%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_doc_sequence_value IS TABLE OF xxcfr_apply_upload_work.doc_sequence_value%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_trx_amount         IS TABLE OF xxcfr_apply_upload_work.trx_amount%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_comments           IS TABLE OF xxcfr_apply_upload_work.comments%TYPE
                                   INDEX BY PLS_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gn_set_of_bks_id    gl_sets_of_books.set_of_books_id%TYPE;         -- 会計帳簿ID
  gn_file_id          xxccp_mrp_file_ul_interface.file_id%TYPE;      -- ファイルID
  gn_trx_amount_sum   xxcfr_apply_upload_work.trx_amount%TYPE;       -- アップロード未回収残高総額
  gn_cash_receipt_id  xxcfr_apply_upload_work.cash_receipt_id%TYPE;  -- 入金内部ID
  gv_receipt_number   xxcfr_apply_upload_work.receipt_number%TYPE;   -- 入金番号
  gv_account_number   xxcfr_apply_upload_work.account_number%TYPE;   -- 顧客コード
  gd_receipt_date     xxcfr_apply_upload_work.receipt_date%TYPE;     -- 入金日
  gv_receipt_date     VARCHAR2(10);                                  -- 入金日(文字)
  gd_receipt_gl_date  ar_cash_receipt_history_all.gl_date%TYPE;      -- 入金GL記帳日
  gd_min_open_date    gl_period_statuses.start_date%TYPE;            -- 最小オープン日
  gb_flag             BOOLEAN := FALSE;  -- 業務チェック用フラグ(チェックに該当すればTRUEとなりエラー終了)
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  gn_normal_trx_amount_sum  xxcfr_apply_upload_work.trx_amount%TYPE;  -- 消込済金額総額
  gn_error_trx_amount_sum   xxcfr_apply_upload_work.trx_amount%TYPE;  -- 未消込金額総額
  gv_threshold_type         fnd_lookup_values.attribute1%TYPE;        -- 閾値区分
  gn_upl_limit_of_count     NUMBER;                                   -- アップロード用対象件数閾値
  gb_warn_flag              BOOLEAN := FALSE;                         -- 警告終了フラグ
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_format IN         VARCHAR2     -- 2.ファイルフォーマット
   ,ov_errbuf      OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg      OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    cv_lookup_ulobj CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCCP1_FILE_UPLOAD_OBJ'; -- ファイルアップロードオブジェクト
    cv_lookup_ulfmt CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_UPLOAD_FORMAT'; -- 入金消込アップロード・ファイルフォーマット
--
    cv_y            CONSTANT VARCHAR2(1)                        := 'Y';
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    -- *** ローカル変数 ***
    lv_file_name  xxccp_mrp_file_ul_interface.file_name%TYPE;  -- エラー・メッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    lv_format_name  fnd_lookup_values.meaning%TYPE;            -- ファイルフォーマット名
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  固定部 END  ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_log               -- ログ出力
      ,iv_conc_param1  => TO_CHAR(gn_file_id)  -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_file_format       -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_out               -- OUTファイル出力
      ,iv_conc_param1  => TO_CHAR(gn_file_id)  -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_file_format       -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --CSVファイル名の取得
    --==============================================================
    -- アップロードCSVファイル名取得
    SELECT file_name                          -- CSVファイル名
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmfui  -- 共通テーブル
    WHERE  xmfui.file_id = gn_file_id         -- ファイルID
    ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --==============================================================
    --ファイルフォーマット名の取得
    --==============================================================
    BEGIN
      -- アップロードファイルフォーマット名取得
      SELECT flv1.meaning     AS meaning                 -- ファイルフォーマット名
            ,flv2.attribute1  AS attribute1              -- 閾値区分
      INTO   lv_format_name
            ,gv_threshold_type
      FROM   fnd_lookup_values flv1                      -- 参照タイプマスタ1
            ,fnd_lookup_values flv2                      -- 参照タイプマスタ2
      WHERE  flv1.lookup_type  = cv_lookup_ulobj         -- 参照タイプ(ファイルアップロードオブジェクト)
      AND    flv1.lookup_code  = iv_file_format          -- 参照コード(ファイルフォーマット)
      AND    flv1.enabled_flag = cv_y                    -- 有効フラグ
      AND    flv1.language     = USERENV('LANG')         -- 言語(JA)
      AND    ( flv1.start_date_active <= TRUNC(SYSDATE)  -- 摘要開始日
            OR flv1.start_date_active IS NULL
             )
      AND    ( flv1.end_date_active   >= TRUNC(SYSDATE)  -- 摘要終了日
            OR flv1.end_date_active   IS NULL
             )
      AND    flv2.lookup_type  = cv_lookup_ulfmt         -- 参照タイプ(入金消込アップロード・ファイルフォーマット)
      AND    flv2.lookup_code  = flv1.lookup_code        -- 参照コード
      AND    flv2.enabled_flag = cv_y                    -- 有効フラグ
      AND    flv2.language     = USERENV('LANG')         -- 言語(JA)
      AND    ( flv2.start_date_active <= TRUNC(SYSDATE)  -- 摘要開始日
            OR flv2.start_date_active IS NULL
             )
      AND    ( flv2.end_date_active   >= TRUNC(SYSDATE)  -- 摘要終了日
            OR flv2.end_date_active   IS NULL
             )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                      ,iv_name         => cv_msg_006a04_014    -- ファイルフォーマットエラー
                                                      ,iv_token_name1  => cv_tkn_006a04_014_1  -- トークン'ファイルフォーマット'
                                                      ,iv_token_value1 => iv_file_format
                             )
                            ,1
                            ,5000
        );
        RAISE global_api_expt;
    END;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    -- アップロードCSVファイル名出力(出力ファイル)
    FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                     ,buff  => xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_name_cfr         -- 'XXCFR'
                                 ,iv_name         => cv_msg_006a04_001        -- アップロード初期出力メッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--                                 ,iv_token_name1  => cv_tkn_006a04_001_2      --「CSV_NAME」
--                                 ,iv_token_value1 => lv_file_name             -- CSVファイル名
                                 ,iv_token_name1  => cv_tkn_006a04_001_1      --「FILE_NAME」
                                 ,iv_token_value1 => lv_format_name           -- アップロードファイル名
                                 ,iv_token_name2  => cv_tkn_006a04_001_2      --「CSV_NAME」
                                 ,iv_token_value2 => lv_file_name             -- CSVファイル名
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
                                )
    );
    -- アップロードCSVファイル名出力(ログファイル)
    FND_FILE.PUT_LINE(which => FND_FILE.LOG
                     ,buff  => xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_name_cfr         -- 'XXCFR'
                                 ,iv_name         => cv_msg_006a04_001        -- アップロード初期出力メッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--                                 ,iv_token_name1  => cv_tkn_006a04_001_2      --「CSV_NAME」
--                                 ,iv_token_value1 => lv_file_name             -- CSVファイル名
                                 ,iv_token_name1  => cv_tkn_006a04_001_1      --「FILE_NAME」
                                 ,iv_token_value1 => lv_format_name           -- アップロードファイル名
                                 ,iv_token_name2  => cv_tkn_006a04_001_2      --「CSV_NAME」
                                 ,iv_token_value2 => lv_file_name             -- CSVファイル名
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
                               )
    );
--
    --==============================================================
    --会計帳簿IDの取得
    --==============================================================
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                    ,iv_name         => cv_msg_006a04_002    -- プロファイル取得エラー
                                                    ,iv_token_name1  => cv_tkn_006a04_002_1  -- トークン'PROF_NAME'
                                                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id)
                           )
                          ,1
                          ,5000
      );
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --カレンダオープン日付の最小値の取得
    --==============================================================
    SELECT MIN(gps.start_date)                                -- 最小オープン日
    INTO   gd_min_open_date
    FROM   gl_period_statuses         gps                     -- 会計期間ステータステーブル
          ,fnd_application            fap                     -- アプリケーション管理マスタ
    WHERE  gps.application_id         = fap.application_id    -- アプリケーションID
    AND    gps.set_of_books_id        = gn_set_of_bks_id      -- 会計帳簿ID
    AND    fap.application_short_name = cv_appl_name_ar       -- アプリケーション短縮名('AR')
    AND    gps.closing_status         = cv_closing_status_o   -- ステータス(オープン)
    ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --==============================================================
    --アップロード用対象件数閾値の取得
    --==============================================================
    -- プロファイルからアップロード用対象件数閾値取得
    gn_upl_limit_of_count := TO_NUMBER(FND_PROFILE.VALUE(cv_upl_limit_of_count));
    -- 取得エラー時
    IF (gn_upl_limit_of_count IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                    ,iv_name         => cv_msg_006a04_002    -- プロファイル取得エラー
                                                    ,iv_token_name1  => cv_tkn_006a04_002_1  -- トークン'PROF_NAME'
                                                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_upl_limit_of_count)
                           )
                          ,1
                          ,5000
      );
      RAISE global_api_expt;
    END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  ##########################################
--
  END proc_init;
--
  /***********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ot_file_data_tbl OUT NOCOPY xxccp_common_pkg2.g_file_data_tbl  -- ファイルアップロードデータ格納配列
   ,ov_errbuf        OUT NOCOPY VARCHAR2                           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT NOCOPY VARCHAR2                           -- リターン・コード             --# 固定 #
   ,ov_errmsg        OUT NOCOPY VARCHAR2                           -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
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
--##################  固定ステータス初期化部 START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    ot_file_data_tbl.DELETE;
--
--###########################  固定部 END  ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --共通アップロードデータ変換処理
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gn_file_id        -- ファイルID
      ,ov_file_data => ot_file_data_tbl  -- 変換後VARCHAR2データ
      ,ov_retcode   => lv_retcode        -- エラー・メッセージ           --# 固定 #
      ,ov_errbuf    => lv_errbuf         -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
--#####################################  固定部 END  ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : devide_item
   * Description      : デリミタ文字項目分割(A-3)
   ***********************************************************************************/
  PROCEDURE devide_item(
    iv_file_data  IN         VARCHAR2          -- ファイルデータ
   ,in_count      IN         PLS_INTEGER       -- カウンタ(行数)
   ,ov_flag       OUT NOCOPY VARCHAR2          -- データ区分
   ,or_work_table OUT NOCOPY xxcfr_apply_upload_work%ROWTYPE  -- 入金消込ワークレコード
   ,ov_errbuf     OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'devide_item'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_look_type   CONSTANT VARCHAR2(100)  := 'XXCFR1_APPLY_UPLOAD';  -- LOOKUP TYPE
    cv_csv_delim   CONSTANT VARCHAR2(1)    := ',';                    -- CSV区切り文字
    cv_duble_quo   CONSTANT VARCHAR2(1)    := '"';                    -- ダブルクオテーション
    cv_1           CONSTANT VARCHAR2(1)    := '1';  -- アップロード対象
    cv_2           CONSTANT VARCHAR2(1)    := '2';  -- アップロード対象外(ダミー値)
--
    -- *** ローカル変数 ***
    lv_item        VARCHAR2(5000);   -- 項目一時格納用
    lb_warn_flag   BOOLEAN;          -- フラグ
--
    -- *** ローカル・カーソル ***
    CURSOR item_check_cur
    IS
    SELECT flv.lookup_code           AS lookup_code  -- 参照タイプコード
          ,TO_NUMBER(flv.meaning)    AS index_num    -- インデックス(項番)
          ,flv.description           AS item_name    -- 項目名称
          ,TO_NUMBER(flv.attribute1) AS item_len     -- 項目長
          ,TO_NUMBER(flv.attribute2) AS item_dec     -- 項目長(小数点以下)
          ,flv.attribute3            AS item_null    -- NULLか
          ,flv.attribute4            AS item_type    -- 項目属性
    FROM   fnd_lookup_values_vl flv                  -- 参照タイプビュー
    WHERE  lookup_type = cv_look_type                -- 参照タイプ
    ORDER BY flv.lookup_code                         -- 参照コード順
    ;
--
    -- *** ローカル・レコード ***
    TYPE ttype_item_check IS TABLE OF item_check_cur%ROWTYPE
                             INDEX BY PLS_INTEGER;
--
    lt_item_check   ttype_item_check;
    lr_work_table   xxcfr_apply_upload_work%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    ov_flag       := NULL;
    or_work_table := NULL;
--
    lr_work_table := NULL;
--
--###########################  固定部 END  ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN item_check_cur;
    FETCH item_check_cur BULK COLLECT INTO lt_item_check;
    CLOSE item_check_cur;
--
    <<item_check_loop>>
    FOR ln_count IN 1..lt_item_check.COUNT LOOP
--
      -- デリミタ文字分割関数
      lv_item := xxccp_common_pkg.char_delim_partition(
                    iv_char     => iv_file_data                       -- ファイルデータ名
                   ,iv_delim    => cv_csv_delim                       -- カンマ
                   ,in_part_num => lt_item_check(ln_count).index_num  -- 項番
                 );
--
--
      -- 囲み文字のダブルクオテーションを削除する
      lv_item := LTRIM(lv_item,cv_duble_quo);  -- 左側
      lv_item := RTRIM(lv_item,cv_duble_quo);  -- 右側
--
      -- 消込フラグ(項番１)の場合はチェックを行わない
      IF ( lt_item_check(ln_count).index_num <> 1 ) THEN
        -- =====================================================
        --  項目長、必須、データ型エラーチェック
        -- =====================================================
        xxccp_common_pkg2.upload_item_check(
           iv_item_name    => lt_item_check(ln_count).item_name -- 項目名称（項目の日本語名）  -- 必須
          ,iv_item_value   => lv_item                           -- 項目の値                    -- 任意
          ,in_item_len     => lt_item_check(ln_count).item_len  -- 項目の長さ                  -- 必須
          ,in_item_decimal => lt_item_check(ln_count).item_dec  -- 項目の長さ（小数点以下）    -- 条件付必須
          ,iv_item_nullflg => lt_item_check(ln_count).item_null -- 必須フラグ（上記定数を設定）-- 必須
          ,iv_item_attr    => lt_item_check(ln_count).item_type -- 項目属性（上記定数を設定）  -- 必須
          ,ov_errbuf       => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
          ,ov_retcode      => lv_retcode                        -- リターン・コード             --# 固定 #
          ,ov_errmsg       => lv_errmsg                         -- ユーザー・エラー・メッセージ --# 固定 #
        ); 
--
        IF    ( lv_retcode = cv_status_error ) THEN  -- エラー
          RAISE global_api_expt;
        ELSIF ( lv_retcode = cv_status_warn  ) THEN  -- 警告時はメッセージ出力
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                             ,iv_name         => cv_msg_006a04_003    -- フォーマットエラー
                                                             ,iv_token_name1  => cv_tkn_006a04_003_1  --「ROW_COUNT」
                                                             ,iv_token_value1 => in_count             -- 行数
                                                             ,iv_token_name2  => cv_tkn_006a04_003_2  --「DATA_INFO」
                                                             ,iv_token_value2 => lv_item              -- 項目の値
                                                             ,iv_token_name3  => cv_tkn_006a04_003_3  --「INFO」
                                                             ,iv_token_value3 => lv_errmsg            -- 共通関数エラーメッセージ
                                     )
          );
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
      -- チェック済みの値を格納
      CASE lt_item_check(ln_count).lookup_code
        WHEN 1 THEN  -- 消込フラグ
--
          -- コメント行
          IF ( NVL( lv_item , cv_2 ) <> cv_1 ) THEN
            ov_retcode := cv_status_warn;  -- アップロード対象としない
            ov_flag := TRIM(lv_item);
            EXIT;  -- プロシージャを抜ける
          END IF;
--
          ov_flag := TRIM(lv_item);
--
      ELSE
--
        NULL;
--
      END CASE;
--
      -- チェック結果が正常である場合
      IF NOT ( gb_flag ) THEN
--
        -- チェック済みの値を格納
        CASE lt_item_check(ln_count).lookup_code
          WHEN 2 THEN  -- 入金日
            lr_work_table.receipt_date       := TO_DATE(lv_item,cv_yyyy_mm_dd);
          WHEN 3 THEN  -- 入金番号
            lr_work_table.receipt_number     := lv_item;
          WHEN 4 THEN  -- 顧客コード
            lr_work_table.account_number     := lv_item;
          WHEN 5 THEN  -- 消込注釈
            lr_work_table.comments           := lv_item;
          WHEN 6 THEN  -- 文書番号
            lr_work_table.doc_sequence_value := lv_item;
          WHEN 7 THEN  -- 消込金額
            lr_work_table.trx_amount         := TO_NUMBER(lv_item);
            -- 消込金額合計
            IF ( gn_trx_amount_sum IS NULL ) THEN
              gn_trx_amount_sum              := lr_work_table.trx_amount;
            ELSE
              gn_trx_amount_sum              := gn_trx_amount_sum + lr_work_table.trx_amount;  
            END IF;
--
        ELSE
--
          NULL;
--
        END CASE;
--
      END IF;
--
    END LOOP item_check_loop;
--
    -- アウトパラメータに設定
    or_work_table := lr_work_table;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
--
      IF ( item_check_cur%ISOPEN ) THEN
        CLOSE item_check_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  ##########################################
--
  END devide_item;
--
  /***********************************************************************************
   * Procedure Name   : insert_work
   * Description      : ワークテーブル登録処理(A-4)
   ***********************************************************************************/
  PROCEDURE insert_work(
    it_receipt_number      IN        ttype_receipt_number      -- 入金番号
   ,it_account_number      IN        ttype_account_number      -- 顧客コード
   ,it_receipt_date        IN        ttype_receipt_date        -- 入金日
   ,it_doc_sequence_value  IN        ttype_doc_sequence_value  -- 文書番号
   ,it_trx_amount          IN        ttype_trx_amount          -- 消込金額
   ,it_comments            IN        ttype_comments            -- 注釈
   ,ov_errbuf             OUT NOCOPY VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT NOCOPY VARCHAR2                  -- リターン・コード             --# 固定 #
   ,ov_errmsg             OUT NOCOPY VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count   PLS_INTEGER;  -- カウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  固定部 END  ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
     -- ワークテーブルに一括登録
     FORALL ln_count IN 1..it_receipt_number.COUNT
       INSERT INTO xxcfr_apply_upload_work(
                      file_id                 -- ファイルID
                     ,receipt_number          -- 入金番号
                     ,account_number          -- 顧客コード
                     ,receipt_date            -- 入金日
                     ,doc_sequence_value      -- 文書番号
                     ,trx_amount              -- 未回収残高
                     ,comments                -- 注釈
                     ,apply_date              -- 消込日
                     ,apply_gl_date           -- 消込GL記帳日
                     ,cash_receipt_id         -- 入金内部ID
                     ,customer_trx_id         -- 取引内部ID
                     ,trx_number              -- 取引番号
                     ,created_by              -- 作成者
                     ,creation_date           -- 作成日
                     ,last_updated_by         -- 最終更新者
                     ,last_update_date        -- 最終更新日
                     ,last_update_login       -- 最終更新ログイン
                     ,request_id              -- 要求ID
                     ,program_application_id  -- コンカレント・プログラム・アプリケーションID
                     ,program_id              -- コンカレント・プログラムID
                     ,program_update_date     -- プログラム更新日
                   )
            VALUES (gn_file_id                       -- ファイルID
                   ,it_receipt_number(ln_count)      -- 入金番号
                   ,it_account_number(ln_count)      -- 顧客コード
                   ,it_receipt_date(ln_count)        -- 入金日
                   ,it_doc_sequence_value(ln_count)  -- 文書番号
                   ,it_trx_amount(ln_count)          -- 未回収残高
                   ,it_comments(ln_count)            -- 注釈
                   ,NULL                             -- 消込日
                   ,NULL                             -- 消込GL記帳日
                   ,NULL                             -- 入金内部ID
                   ,NULL                             -- 取引内部ID
                   ,NULL                             -- 取引番号
                   ,cn_created_by                    -- 作成者
                   ,cd_creation_date                 -- 作成日
                   ,cn_last_updated_by               -- 最終更新者
                   ,cd_last_update_date              -- 最終更新日
                   ,cn_last_update_login             -- 最終更新ログイン
                   ,cn_request_id                    -- 要求ID
                   ,cn_program_application_id        -- コンカレント・プログラム・アプリケーションID
                   ,cn_program_id                    -- コンカレント・プログラムID
                   ,cd_program_update_date           -- プログラム更新日
                   )
       ;
--
    -- 対象件数を取得
    gn_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
--#####################################  固定部 END  ##########################################
--
  END insert_work;
--
  /***********************************************************************************
   * Procedure Name   : check_data
   * Description      : 妥当性チェック(A-5)
   ***********************************************************************************/
  PROCEDURE check_data(
    ov_errbuf         OUT NOCOPY VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT NOCOPY VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg         OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- プログラム名
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
--
    -- ===============================
    -- *** ローカル定数 ***
--
    cv_class_pmt      CONSTANT ar_payment_schedules_all.class%TYPE    := 'PMT';                      -- クラス：入金
    cv_status_unapp   CONSTANT ar_cash_receipts_all.status%TYPE       := 'UNAPP';                    -- ステータス：未消込
    cv_lookup_secu    CONSTANT fnd_lookup_values.lookup_type%TYPE     := 'XXCFR1_RECEIPT_SECURITY';  -- ALL権限部門
    cv_lookup_cash    CONSTANT fnd_lookup_values.lookup_type%TYPE     := 'CHECK_STATUS';             -- 入金ステータス
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    cv_threshold_type_large  CONSTANT fnd_lookup_values.attribute1%TYPE := '1';                     -- 閾値区分(大口)
    cv_threshold_type_small  CONSTANT fnd_lookup_values.attribute1%TYPE := '0';                     -- 閾値区分(小口)
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    cv_y              CONSTANT VARCHAR2(1)                            := 'Y';
--
    -- *** ローカル変数 ***
--
    ln_count         PLS_INTEGER;
--
    -- *** ローカル・カーソル ***
--
    -- 入金情報の一意性チェック(妥当性チェック)
    CURSOR  cash_unique_cur
    IS
      SELECT acr.cash_receipt_id           AS cash_receipt_id       -- 入金内部ID
            ,acrh.gl_date                  AS cash_gl_date          -- 入金GL記帳日
            ,acr.receipt_method_id         AS receipt_method_id     -- 支払方法内部ID
            ,aps.amount_due_remaining * -1 AS cash_amount_remaining -- 入金残額
            ,acr.status                    AS cash_status           -- ステータス
            ,(SELECT flv.meaning  AS meaning
              FROM   fnd_lookup_values flv              -- 参照タイプマスタ
              WHERE  flv.lookup_type = cv_lookup_cash   -- 参照タイプ(入金ステータス)
              AND    flv.language    = USERENV('LANG')  -- 言語
              AND    flv.lookup_code = acr.status       -- 参照コード(ステータス)
             )                             AS cash_status_desc      -- ステータス摘要
        FROM ar_cash_receipts          acr   -- 入金
            ,ar_payment_schedules      aps   -- 支払計画
            ,hz_cust_accounts          hca   -- 顧客マスタ
            ,ar_cash_receipt_history   acrh  -- 入金履歴
       WHERE acr.cash_receipt_id = aps.cash_receipt_id     -- 入金内部ID
         AND acr.cash_receipt_id = acrh.cash_receipt_id    -- 入金内部ID
         AND hca.cust_account_id = acr.pay_from_customer   -- 顧客内部ID
         AND acr.receipt_number  = gv_receipt_number       -- 入金番号
         AND acr.receipt_date    = gd_receipt_date         -- 入金日
         AND hca.account_number  = gv_account_number       -- 顧客コード
         AND aps.class           = cv_class_pmt            -- 入金
         AND acrh.current_record_flag = cv_y               -- 現在行フラグ
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
         AND acr.status               = cv_status_unapp    -- 入金ステータス(UNAPP 未消込)
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
      ;
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
    -- 未消込以外の入金情報取得
    CURSOR  cash_not_unapp_data_cur
    IS
      SELECT acr.cash_receipt_id           AS cash_receipt_id       -- 入金内部ID
            ,acrh.gl_date                  AS cash_gl_date          -- 入金GL記帳日
            ,acr.receipt_method_id         AS receipt_method_id     -- 支払方法内部ID
            ,aps.amount_due_remaining * -1 AS cash_amount_remaining -- 入金残額
            ,acr.status                    AS cash_status           -- ステータス
            ,(SELECT flv.meaning  AS meaning
              FROM   fnd_lookup_values flv              -- 参照タイプマスタ
              WHERE  flv.lookup_type = cv_lookup_cash   -- 参照タイプ(入金ステータス)
              AND    flv.language    = USERENV('LANG')  -- 言語
              AND    flv.lookup_code = acr.status       -- 参照コード(ステータス)
             )                             AS cash_status_desc      -- ステータス摘要
        FROM ar_cash_receipts          acr   -- 入金
            ,ar_payment_schedules      aps   -- 支払計画
            ,hz_cust_accounts          hca   -- 顧客マスタ
            ,ar_cash_receipt_history   acrh  -- 入金履歴
       WHERE acr.cash_receipt_id       =  aps.cash_receipt_id     -- 入金内部ID
         AND acr.cash_receipt_id       =  acrh.cash_receipt_id    -- 入金内部ID
         AND hca.cust_account_id       =  acr.pay_from_customer   -- 顧客内部ID
         AND acr.receipt_number        =  gv_receipt_number       -- 入金番号
         AND acr.receipt_date          =  gd_receipt_date         -- 入金日
         AND hca.account_number        =  gv_account_number       -- 顧客コード
         AND aps.class                 =  cv_class_pmt            -- 入金
         AND acrh.current_record_flag  =  cv_y                    -- 現在行フラグ
         AND acr.status               <>  cv_status_unapp         -- 入金ステータス(UNAPP 未消込 以外)
      ;
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
--
    -- セキュリティチェック
    CURSOR  receipt_method_cur(
              in_receipt_method_id  ar_receipt_methods.receipt_method_id%TYPE  -- 支払方法内部ID
            )
    IS
      SELECT COUNT(ROWNUM)       AS cnt  -- カウンタ
      FROM   xxcfr_dept_relate_v xdrv    -- 所属拠点及び管理元拠点ビュー
      WHERE  ( EXISTS( SELECT NULL
                       FROM   ar_receipt_methods  arm                       -- 支払方法
                       WHERE  arm.receipt_method_id = in_receipt_method_id  -- 支払方法内部ID
                       AND    arm.attribute1        = xdrv.dept_code        -- 支払方法拠点 = 所属拠点 or 管理元拠点
               )
            OR EXISTS( SELECT NULL
                       FROM   fnd_lookup_values        flv                  -- 参照タイプ
                       WHERE  flv.lookup_type          = cv_lookup_secu     -- セキュリティ
                       AND    flv.enabled_flag         = cv_y 
                       AND    flv.language             = USERENV('LANG')    -- JA
                       AND    ( flv.start_date_active <= TRUNC(SYSDATE)     -- 開始日
                             OR flv.start_date_active IS NULL
                              )
                       AND    ( flv.end_date_active   >= TRUNC(SYSDATE)     -- 終了日
                             OR flv.end_date_active   IS NULL
                              )
                       AND    flv.lookup_code = xdrv.dept_code              -- スーパーユーザー = 所属拠点 or 管理元拠点
               )
             )
      ;
--
    -- 取引情報の一意性チェック
    CURSOR  trx_unique_cur
    IS
      SELECT xauw.doc_sequence_value AS doc_sequence_value     -- 文書番号
        FROM xxcfr_apply_upload_work  xauw                     -- 入金消込アップロードワーク
       WHERE xauw.file_id    = gn_file_id                      -- ファイルID
         AND xauw.request_id = cn_request_id                   -- 要求ID
      GROUP BY xauw.doc_sequence_value
      HAVING   COUNT(ROWNUM) > 1                               -- 文書番号が一意でないもの
      ;
--
    -- 取引情報の存在チェック
    CURSOR check_trx_exist_cur
    IS
      SELECT  xauw.doc_sequence_value AS doc_sequence_value    -- 文書番号
      FROM    xxcfr_apply_upload_work xauw                     -- 入金消込アップロードワーク
      WHERE   xauw.file_id    = gn_file_id                     -- ファイルID
        AND   xauw.request_id = cn_request_id                  -- 要求ID
        AND   NOT EXISTS(SELECT NULL
                         FROM   ra_customer_trx  rct           -- 取引テーブル
                         WHERE  xauw.doc_sequence_value = rct.doc_sequence_value  -- 文書番号
              )
     ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    -- 消込済み取引情報の存在チェック
    CURSOR  check_apply_trx_cur(
              in_cash_receipt_id  ar_cash_receipts.cash_receipt_id%TYPE  -- 入金ID
            )
    IS
      SELECT  xauw.doc_sequence_value AS doc_sequence_value          -- 文書番号
      FROM    xxcfr_apply_upload_work        xauw                    -- 入金消込アップロードワーク
             ,ra_customer_trx                rct                     -- 取引テーブル
             ,ar_receivable_applications_all araa                    -- 消込テーブル
      WHERE   xauw.file_id                 = gn_file_id              -- ファイルID
        AND   xauw.request_id              = cn_request_id           -- 要求ID
        AND   xauw.doc_sequence_value      = rct.doc_sequence_value  -- 文書番号
        AND   araa.applied_customer_trx_id = rct.customer_trx_id     -- 取引ID
        AND   araa.display                 = cv_y                    -- 表示フラグ
        AND   araa.cash_receipt_id         = in_cash_receipt_id      -- 入金ID
     ;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    -- *** ローカル・レコード ***
--
    TYPE ttype_cash_unique     IS TABLE OF cash_unique_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_cash_unique             ttype_cash_unique;
--
    TYPE ttype_receipt_method  IS TABLE OF receipt_method_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_receipt_method          ttype_receipt_method;
--
    TYPE ttype_trx_unique      IS TABLE OF trx_unique_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_trx_unique              ttype_trx_unique;
--
    TYPE ttype_check_trx_exist  IS TABLE OF check_trx_exist_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_check_trx_exist          ttype_check_trx_exist;
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
--
    TYPE ttype_cash_not_unapp   IS TABLE OF cash_not_unapp_data_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_cash_not_unapp           ttype_cash_not_unapp;
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
--
    TYPE ttype_check_apply_trx  IS TABLE OF check_apply_trx_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_check_apply_trx          ttype_check_apply_trx;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
------------
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入金番号をチェックする(DB上、入金番号、顧客、入金日で一意となるか)
    BEGIN
--
-- ************ 2010/09/02 1.1 M.Watanabe DEL START ************ --
--      OPEN cash_unique_cur;
--      FETCH cash_unique_cur BULK COLLECT INTO lt_cash_unique;
--      CLOSE cash_unique_cur;
----
--      IF ( lt_cash_unique.COUNT < 1 ) THEN -- 対象の入金が存在しない場合(エラー)
----
--        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                         ,buff  => xxccp_common_pkg.get_msg(
--                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                    ,iv_name         => cv_msg_006a04_004    -- 入金データなしエラー
--                                    ,iv_token_name1  => cv_tkn_006a04_004_1  --「RECEIPT_NUMBER」
--                                    ,iv_token_value1 => gv_receipt_number    -- 入金番号
--                                    ,iv_token_name2  => cv_tkn_006a04_004_2  --「ACCOUNT_NUMBER」
--                                    ,iv_token_value2 => gv_account_number    -- 顧客コード
--                                    ,iv_token_name3  => cv_tkn_006a04_004_3  --「RECEIPT_DATE」
--                                    ,iv_token_value3 => gv_receipt_date      -- 入金日
--                                    )
--        );
----
--        gb_flag := TRUE;
----
--      ELSIF( lt_cash_unique.COUNT > 1 ) THEN  -- 対象の入金が複数存在する場合(エラー)
----
--        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                         ,buff  => xxccp_common_pkg.get_msg(
--                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                    ,iv_name         => cv_msg_006a04_005    -- 入金データ重複エラー
--                                    ,iv_token_name1  => cv_tkn_006a04_005_1  --「RECEIPT_NUMBER」
--                                    ,iv_token_value1 => gv_receipt_number    -- 入金番号
--                                    ,iv_token_name2  => cv_tkn_006a04_005_2  --「ACCOUNT_NUMBER」
--                                    ,iv_token_value2 => gv_account_number    -- 顧客コード
--                                    ,iv_token_name3  => cv_tkn_006a04_005_3  --「RECEIPT_DATE」
--                                    ,iv_token_value3 => gv_receipt_date      -- 入金日
--                                    )
--        );
----
--        gb_flag := TRUE;
----
--      ELSE
----
--        -- 入金ステータスが未消込以外の場合はエラー
--        IF ( lt_cash_unique(1).cash_status = cv_status_unapp ) THEN
----
--          -- アップロード未回収残高の総額以上に入金残額がない場合はエラー
--          IF ( lt_cash_unique(1).cash_amount_remaining >= gn_trx_amount_sum ) THEN
----
--            gn_cash_receipt_id := lt_cash_unique(1).cash_receipt_id;  -- 入金内部IDをグローバル化
--            gd_receipt_gl_date := lt_cash_unique(1).cash_gl_date;     -- 入金GL記帳日をグローバル化
----
--          ELSE
----
--            FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                             ,buff  => xxccp_common_pkg.get_msg(
--                                         iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                        ,iv_name         => cv_msg_006a04_007    -- 入金残高エラー
--                                        ,iv_token_name1  => cv_tkn_006a04_007_1  --「RECEIPT_NUMBER」
--                                        ,iv_token_value1 => gv_receipt_number    -- 入金番号
--                                        ,iv_token_name2  => cv_tkn_006a04_007_2  --「ACCOUNT_NUMBER」
--                                        ,iv_token_value2 => gv_account_number    -- 顧客コード
--                                        ,iv_token_name3  => cv_tkn_006a04_007_3  --「RECEIPT_DATE」
--                                        ,iv_token_value3 => gv_receipt_date      -- 入金日
--                                        ,iv_token_name4  => cv_tkn_006a04_007_4  --「CASH_AMOUNT」
--                                        ,iv_token_value4 => lt_cash_unique(1).cash_amount_remaining  -- 入金残額
--                                        ,iv_token_name5  => cv_tkn_006a04_007_5  --「TRX_AMOUNT_ALL」
--                                        ,iv_token_value5 => gn_trx_amount_sum    -- 消込金額合計
--                                        )
--            );
--            gb_flag := TRUE;
----
--          END IF;
----
--        ELSE
----
--          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                           ,buff  => xxccp_common_pkg.get_msg(
--                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                      ,iv_name         => cv_msg_006a04_006    -- 入金ステータスエラー
--                                      ,iv_token_name1  => cv_tkn_006a04_006_1  -- RECEIPT_NUMBER」
--                                      ,iv_token_value1 => gv_receipt_number    -- 入金番号
--                                      ,iv_token_name2  => cv_tkn_006a04_006_2  --「ACCOUNT_NUMBER」
--                                      ,iv_token_value2 => gv_account_number    -- 顧客コード
--                                      ,iv_token_name3  => cv_tkn_006a04_006_3  --「RECEIPT_DATE」
--                                      ,iv_token_value3 => gv_receipt_date      -- 入金日
--                                      ,iv_token_name4  => cv_tkn_006a04_006_4  --「STATUS」
--                                      ,iv_token_value4 => lt_cash_unique(1).cash_status_desc  -- ステータス摘要
--                                     )
--          );
----
--          gb_flag := TRUE;
----
--        END IF;
----
--      END IF;
-- ************ 2010/09/02 1.1 M.Watanabe DEL END   ************ --
--
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
--
      -- 入金ステータスが UNAPP(未消込) の入金情報を取得する
      OPEN cash_unique_cur;
      FETCH cash_unique_cur BULK COLLECT INTO lt_cash_unique;
      CLOSE cash_unique_cur;
--
      --===================================================================
      -- 入金ステータスが UNAPP(未消込) の入金情報が 2件以上 存在する場合
      --===================================================================
      IF ( lt_cash_unique.COUNT > 1 ) THEN
--
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => xxccp_common_pkg.get_msg(
                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                    ,iv_name         => cv_msg_006a04_005    -- 入金データ重複エラー
                                    ,iv_token_name1  => cv_tkn_006a04_005_1  --「RECEIPT_NUMBER」
                                    ,iv_token_value1 => gv_receipt_number    -- 入金番号
                                    ,iv_token_name2  => cv_tkn_006a04_005_2  --「ACCOUNT_NUMBER」
                                    ,iv_token_value2 => gv_account_number    -- 顧客コード
                                    ,iv_token_name3  => cv_tkn_006a04_005_3  --「RECEIPT_DATE」
                                    ,iv_token_value3 => gv_receipt_date      -- 入金日
                                    )
        );
--
        gb_flag := TRUE;
--
      END IF;
--
      --===================================================================
      -- 入金ステータスが UNAPP(未消込) の入金情報が ゼロ件 の場合
      --===================================================================
      IF ( lt_cash_unique.COUNT = 0 ) THEN
--
        -- 入金ステータスが UNAPP(未消込) 以外 の入金情報を取得する
        OPEN cash_not_unapp_data_cur;
        FETCH cash_not_unapp_data_cur BULK COLLECT INTO lt_cash_not_unapp;
        CLOSE cash_not_unapp_data_cur;
--
        --========================================================================
        -- 入金ステータスが UNAPP(未消込) 以外 の入金情報が ゼロ件 の場合
        --========================================================================
        IF ( lt_cash_not_unapp.COUNT = 0 ) THEN
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_004    -- 入金データなしエラー
                                      ,iv_token_name1  => cv_tkn_006a04_004_1  --「RECEIPT_NUMBER」
                                      ,iv_token_value1 => gv_receipt_number    -- 入金番号
                                      ,iv_token_name2  => cv_tkn_006a04_004_2  --「ACCOUNT_NUMBER」
                                      ,iv_token_value2 => gv_account_number    -- 顧客コード
                                      ,iv_token_name3  => cv_tkn_006a04_004_3  --「RECEIPT_DATE」
                                      ,iv_token_value3 => gv_receipt_date      -- 入金日
                                      )
          );
--
          gb_flag := TRUE;
        --========================================================================
        -- 入金ステータスが UNAPP(未消込) 以外 の入金情報が 1件以上 存在する場合
        --========================================================================
        ELSE
--
          <<cash_err_msg_loop>>
          FOR ln_cnt  IN  1 .. lt_cash_not_unapp.COUNT LOOP
--
            FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                             ,buff  => xxccp_common_pkg.get_msg(
                                         iv_application  => cv_appl_name_cfr                            -- 'XXCFR'
                                        ,iv_name         => cv_msg_006a04_006                           -- 入金ステータスエラー
                                        ,iv_token_name1  => cv_tkn_006a04_006_1                         -- RECEIPT_NUMBER」
                                        ,iv_token_value1 => gv_receipt_number                           -- 入金番号
                                        ,iv_token_name2  => cv_tkn_006a04_006_2                         --「ACCOUNT_NUMBER」
                                        ,iv_token_value2 => gv_account_number                           -- 顧客コード
                                        ,iv_token_name3  => cv_tkn_006a04_006_3                         --「RECEIPT_DATE」
                                        ,iv_token_value3 => gv_receipt_date                             -- 入金日
                                        ,iv_token_name4  => cv_tkn_006a04_006_4                         --「STATUS」
                                        ,iv_token_value4 => lt_cash_not_unapp(ln_cnt).cash_status_desc  -- ステータス摘要
                                       )
            );
--
          END LOOP cash_err_msg_loop;
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
      --===================================================================
      -- 入金ステータスが UNAPP(未消込) の入金情報が 1件 の場合
      --===================================================================
      IF ( lt_cash_unique.COUNT = 1 ) THEN
--
        --===================================================================
        -- 入金の未消込残高と消込金額の合計チェック
        -- 入金の未消込残高 < 消込金額合計 の場合は 入金残高エラー
        --===================================================================
        IF ( lt_cash_unique(1).cash_amount_remaining >= gn_trx_amount_sum ) THEN
--
          gn_cash_receipt_id := lt_cash_unique(1).cash_receipt_id;  -- 入金内部IDをグローバル化
          gd_receipt_gl_date := lt_cash_unique(1).cash_gl_date;     -- 入金GL記帳日をグローバル化
--
        ELSE
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_007    -- 入金残高エラー
                                      ,iv_token_name1  => cv_tkn_006a04_007_1  --「RECEIPT_NUMBER」
                                      ,iv_token_value1 => gv_receipt_number    -- 入金番号
                                      ,iv_token_name2  => cv_tkn_006a04_007_2  --「ACCOUNT_NUMBER」
                                      ,iv_token_value2 => gv_account_number    -- 顧客コード
                                      ,iv_token_name3  => cv_tkn_006a04_007_3  --「RECEIPT_DATE」
                                      ,iv_token_value3 => gv_receipt_date      -- 入金日
                                      ,iv_token_name4  => cv_tkn_006a04_007_4  --「CASH_AMOUNT」
                                      ,iv_token_value4 => lt_cash_unique(1).cash_amount_remaining  -- 入金残額
                                      ,iv_token_name5  => cv_tkn_006a04_007_5  --「TRX_AMOUNT_ALL」
                                      ,iv_token_value5 => gn_trx_amount_sum    -- 消込金額合計
                                      )
          );
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
    -- 支払方法をチェックする(セキュリティ)
    BEGIN
--
      OPEN receipt_method_cur(
             lt_cash_unique(1).receipt_method_id  -- 支払方法内部ID
           );
      FETCH receipt_method_cur BULK COLLECT INTO lt_receipt_method;
      CLOSE receipt_method_cur;
--
      IF ( lt_receipt_method(1).cnt < 1 ) THEN
--
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => xxccp_common_pkg.get_msg(
                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                    ,iv_name         => cv_msg_006a04_008    -- 支払方法セキュリティエラー
                                    ,iv_token_name1  => cv_tkn_006a04_008_1  --「RECEIPT_NUMBER」
                                    ,iv_token_value1 => gv_receipt_number    -- 入金番号
                                    ,iv_token_name2  => cv_tkn_006a04_008_2  --「ACCOUNT_NUMBER」
                                    ,iv_token_value2 => gv_account_number    -- 顧客コード
                                    ,iv_token_name3  => cv_tkn_006a04_008_3  --「RECEIPT_DATE」
                                    ,iv_token_value3 => gv_receipt_date      -- 入金日
                                   )
        );
--
        gb_flag := TRUE;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
    -- 取引番号をチェックする(ファイル内で重複していないか)
    BEGIN
--
      OPEN trx_unique_cur;
      FETCH trx_unique_cur BULK COLLECT INTO lt_trx_unique;
      CLOSE trx_unique_cur;
--
      IF   ( lt_trx_unique.COUNT > 0 ) THEN
--
        <<err_msg_loop>>
        FOR ln_count IN 1..lt_trx_unique.COUNT LOOP
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_009    -- 文書番号重複エラー
                                      ,iv_token_name1  => cv_tkn_006a04_009_1  --「DOC_SEQUENCE_VALUE」
                                      ,iv_token_value1 => lt_trx_unique(ln_count).doc_sequence_value  -- 文書番号
                                     )
          );
--
        END LOOP err_msg_loop;
--
        gb_flag := TRUE;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
--  アップロード対象の文書番号が取引として存在しているかをチェックする。
    BEGIN
--
      OPEN check_trx_exist_cur;
      FETCH check_trx_exist_cur BULK COLLECT INTO lt_check_trx_exist;
      CLOSE check_trx_exist_cur;
--
      -- 取引に存在しない文書番号の場合エラー
      IF ( lt_check_trx_exist.COUNT > 0 ) THEN
--
        <<error_msg_loop>>
        FOR ln_count IN 1..lt_check_trx_exist.COUNT LOOP
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_010    -- 文書番号存在なしエラー
                                      ,iv_token_name1  => cv_tkn_006a04_010_1  --「DOC_SEQUENCE_VALUE」
                                      ,iv_token_value1 => lt_check_trx_exist(ln_count).doc_sequence_value --文書番号
                                     )
          );
--
        END LOOP err_msg_loop;
--
        gb_flag := TRUE;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    -- 消込済み取引情報の存在をチェックする
    BEGIN
--
      IF ( lt_cash_unique.COUNT > 0 ) THEN
--
        OPEN check_apply_trx_cur(
               lt_cash_unique(1).cash_receipt_id  -- 入金ID
             );
        FETCH check_apply_trx_cur BULK COLLECT INTO lt_check_apply_trx;
        CLOSE check_apply_trx_cur;
--
        -- 消込済み取引が存在する文書番号の場合エラー
        IF ( lt_check_apply_trx.COUNT > 0 ) THEN
--
          <<error_msg_loop>>
          FOR ln_count IN 1..lt_check_apply_trx.COUNT LOOP
--
            FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                             ,buff  => xxccp_common_pkg.get_msg(
                                         iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                        ,iv_name         => cv_msg_006a04_013    -- 消込済み文書番号エラー
                                        ,iv_token_name1  => cv_tkn_006a04_013_1  --「RECEIPT_NUMBER」
                                        ,iv_token_value1 => gv_receipt_number    -- 入金番号
                                        ,iv_token_name2  => cv_tkn_006a04_013_2  --「DOC_SEQUENCE_VALUE」
                                        ,iv_token_value2 => lt_check_apply_trx(ln_count).doc_sequence_value -- 文書番号
                                       )
            );
--
          END LOOP err_msg_loop;
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
    -- 大口の場合の消込対象件数とアップロード用対象件数閾値を比較する
    IF (  ( gv_threshold_type = cv_threshold_type_large )  -- 閾値区分が大口
      AND ( gn_target_cnt < gn_upl_limit_of_count ) )      -- 消込対象件数 ＜ アップロード用対象件数閾値
      THEN
      FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                       ,buff  => xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                  ,iv_name         => cv_msg_006a04_015    -- 債権閾値チェックエラー(大口)
                                  )
      );
--
      gb_flag := TRUE;
--
    END IF;
--
    -- 小口の場合の消込対象件数とアップロード用対象件数閾値を比較する
    IF (  ( gv_threshold_type = cv_threshold_type_small )  -- 閾値区分が小口
      AND ( gn_target_cnt >= gn_upl_limit_of_count ) )     -- 消込対象件数 ≧ アップロード用対象件数閾値
      THEN
      FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                       ,buff  => xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                  ,iv_name         => cv_msg_006a04_016    -- 債権閾値チェックエラー(小口)
                                  )
      );
--
      gb_flag := TRUE;
--
    END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
      IF ( cash_unique_cur%ISOPEN ) THEN
        CLOSE cash_unique_cur;
      END IF;
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
      IF ( cash_not_unapp_data_cur%ISOPEN ) THEN
        CLOSE cash_not_unapp_data_cur;
      END IF;
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
      IF ( receipt_method_cur%ISOPEN ) THEN
        CLOSE receipt_method_cur;
      END IF;
      IF ( trx_unique_cur%ISOPEN ) THEN
        CLOSE trx_unique_cur;
      END IF;
      IF ( check_trx_exist_cur%ISOPEN ) THEN
        CLOSE check_trx_exist_cur;
      END IF;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
      IF ( check_apply_trx_cur%ISOPEN ) THEN
        CLOSE check_apply_trx_cur;
      END IF;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  ##########################################
--
  END check_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_trx_data
   * Description      : 取引情報取得(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_trx_data(
    ov_errbuf     OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_trx_data'; -- プログラム名
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
    cv_status_o          gl_period_statuses.closing_status%TYPE          := 'O';    -- ステータス(オープン)
    cv_class_inv         ar_payment_schedules_all.class%TYPE             := 'INV';  -- クラス(取引)
    cv_class_cm          ar_payment_schedules_all.class%TYPE             := 'CM';   -- クラス(クレジットメモ)
    cv_account_class_rec ra_cust_trx_line_gl_dist_all.account_class%TYPE := 'REC';  -- 勘定クラス(売掛/未収金)
    cv_flag_y            ra_customer_trx_all.complete_flag%TYPE          := 'Y';    -- 完了フラグ(完了)
    -- *** ローカル変数 ***
--
    ln_count        PLS_INTEGER := 0;      -- カウンタ
    lb_check_flag   BOOLEAN     := FALSE;  -- 消込金額エラーチェックフラグ
    ld_date         DATE        := NULL;   -- 入金日とSYSDATEを比較し、大きい方を格納
--
    -- *** ローカル・カーソル ***
--
    CURSOR get_trx_id_cur
    IS
      SELECT /*+ LEADING( xauw rct )
                 USE_NL( xauw rct aps rctl gps fap )
             */
              xauw.rowid                      AS row_id                -- ROWID
             ,rct.customer_trx_id             AS customer_trx_id       -- 取引内部ID
             ,rct.trx_number                  AS trx_number            -- 取引番号
             ,xauw.doc_sequence_value         AS doc_sequence_value    -- 文書番号
             ,xauw.trx_amount                 AS trx_amount            -- 消込金額
             ,aps.amount_due_remaining        AS amount_due_remaining  -- 未回収残高
             ,aps.status                      AS stauts                -- ステータス
             ,DECODE(SIGN(rct.trx_date - ld_date)
                    , -1 , ld_date
                    ,  1 , rct.trx_date
                    ,  0 , rct.trx_date
              )                               AS apply_date            -- 消込日
             ,DECODE( gps.closing_status
                    , cv_status_o , DECODE(SIGN(rctl.gl_date - gd_receipt_gl_date)
                                           , -1 , gd_receipt_gl_date
                                           ,  1 , rctl.gl_date
                                           ,  0 , rctl.gl_date
                                    )
                    ,  DECODE(SIGN(gd_min_open_date - gd_receipt_gl_date)
                              , -1 , gd_receipt_gl_date
                              ,  1 , gd_min_open_date
                              ,  0 , gd_min_open_date
                              )
              )                               AS apply_gl_date         -- 消込GL記帳日
      FROM    xxcfr_apply_upload_work     xauw                         -- 入金消込アップロードワーク
             ,ra_customer_trx             rct                          -- 取引テーブル
             ,ar_payment_schedules        aps                          -- 支払計画テーブル
             ,ra_cust_trx_line_gl_dist    rctl                         -- 取引配分テーブル
             ,gl_period_statuses          gps                          -- カレンダ
             ,fnd_application             fap                          -- アプリケーション
      WHERE   rct.customer_trx_id        = aps.customer_trx_id         -- 取引内部ID
        AND   xauw.doc_sequence_value    = rct.doc_sequence_value      -- 文書番号
        AND   rct.customer_trx_id        = rctl.customer_trx_id        -- 取引内部ID
        AND   gps.application_id         = fap.application_id          -- 内部ID
        AND   rctl.gl_date         BETWEEN gps.start_date              -- 開始日
                                       AND gps.end_date                -- 終了日
        AND   gps.set_of_books_id        = gn_set_of_bks_id            -- 会計帳簿ID
        AND   fap.application_short_name = cv_appl_name_ar             -- 標準AR
        AND   rct.complete_flag          = cv_flag_y                   -- 完了フラグ
        AND   xauw.file_id               = gn_file_id                  -- ファイルID
        AND   xauw.request_id            = cn_request_id               -- 要求ID
        AND   rctl.account_class         = cv_account_class_rec        -- 未収／売掛勘定
        AND   aps.class                IN (cv_class_inv                -- 取引
                                          ,cv_class_cm                 -- クレジットメモ
                                       )
     ;
--
    -- *** ローカル・レコード ***
--
    TYPE ttype_row_id               IS TABLE OF rowid
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_customer_trx_id      IS TABLE OF ra_customer_trx.customer_trx_id%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_trx_number           IS TABLE OF ra_customer_trx.trx_number%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_doc_sequence_value   IS TABLE OF xxcfr_apply_upload_work.doc_sequence_value%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_trx_amount           IS TABLE OF xxcfr_apply_upload_work.trx_amount%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_amount_due_remaining IS TABLE OF ar_payment_schedules_all.amount_due_remaining%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_status               IS TABLE OF ar_payment_schedules_all.status%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_apply_date           IS TABLE OF xxcfr_apply_upload_work.apply_date%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_apply_gl_date        IS TABLE OF xxcfr_apply_upload_work.apply_gl_date%TYPE
                                       INDEX BY PLS_INTEGER;
--
    lt_row_id                 ttype_row_id;
    lt_customer_trx_id        ttype_customer_trx_id;
    lt_trx_number             ttype_trx_number;
    lt_doc_sequence_value     ttype_doc_sequence_value;
    lt_trx_amount             ttype_trx_amount;
    lt_amount_due_remaining   ttype_amount_due_remaining;
    lt_status                 ttype_status;
    lt_apply_date             ttype_apply_date;
    lt_apply_gl_date          ttype_apply_gl_date;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    lt_row_id.DELETE;
    lt_customer_trx_id.DELETE;
    lt_trx_number.DELETE;
    lt_doc_sequence_value.DELETE;
    lt_trx_amount.DELETE;
    lt_amount_due_remaining.DELETE;
    lt_status.DELETE;
    lt_apply_date.DELETE;
    lt_apply_gl_date.DELETE;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入金日とSYSDATEを比較し、大きい方を変数に格納する
    IF (gd_receipt_date < SYSDATE) THEN
      ld_date := SYSDATE;
    ELSE
      ld_date := gd_receipt_date;
    END IF;
--
    OPEN get_trx_id_cur;
--
    FETCH get_trx_id_cur BULK COLLECT INTO lt_row_id                -- ROWID
                                          ,lt_customer_trx_id       -- 取引内部ID
                                          ,lt_trx_number            -- 取引番号
                                          ,lt_doc_sequence_value    -- 文書番号
                                          ,lt_trx_amount            -- 消込金額
                                          ,lt_amount_due_remaining  -- 未回収残高
                                          ,lt_status                -- ステータス
                                          ,lt_apply_date            -- 消込日
                                          ,lt_apply_gl_date         -- 消込GL記帳日
    ;
--
    CLOSE get_trx_id_cur;
--
    <<error_msg_loop>>
    FOR ln_count IN 1..lt_row_id.COUNT LOOP
--
      -- ①未回収残高と②消込金額(アップロード)が異なるときはエラーメッセージを出力し、エラー終了とする。
      -- ケース1：① 10,000 ② 10,500  ⇒ 残高以上の消込
      -- ケース2：① 10,000 ②-   100  ⇒ 未回収残高が増える
      -- ケース3：①-10,000 ②-10,500  ⇒ 残高以上の消込
      -- ケース4：①-10,000 ②    100  ⇒ 未回収残高が増える
      IF (  ( SIGN(lt_amount_due_remaining(ln_count))  = SIGN(lt_trx_amount(ln_count)) )  -- 符号が同じである
        AND (  ABS(lt_amount_due_remaining(ln_count)) >=  ABS(lt_trx_amount(ln_count)) )  -- 未回収残高の方が大きい
      ) THEN
--
        NULL;  -- 問題ないので何もしない。
--
      ELSE
--
        -- 未回収残高と消込金額が矛盾しています。
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => xxccp_common_pkg.get_msg(
                                     iv_application  => cv_appl_name_cfr         -- 'XXCFR'
                                    ,iv_name         => cv_msg_006a04_011        -- 消込金額エラー
                                    ,iv_token_name1  => cv_tkn_006a04_011_1      --「TRX_NUMBER」
                                    ,iv_token_value1 => lt_trx_number(ln_count)  -- 取引番号
-- ************ 2010/09/02 1.1 M.Watanabe MOD START ************ --
--                                    ,iv_token_name2  => cv_tkn_006a04_011_2      --「AMOUNT_DUE_REMAINING」
--                                    ,iv_token_value2 => lt_amount_due_remaining(ln_count)  -- 未回収残額
--                                    ,iv_token_name3  => cv_tkn_006a04_011_3      --「TRX_AMOUNT」
--                                    ,iv_token_value3 => lt_trx_amount(ln_count)  -- 消込金額
                                    ,iv_token_name2  => cv_tkn_006a04_010_1               --「DOC_SEQUENCE_VALUE」
                                    ,iv_token_value2 => lt_doc_sequence_value(ln_count)   -- 文書番号
                                    ,iv_token_name3  => cv_tkn_006a04_011_2               --「AMOUNT_DUE_REMAINING」
                                    ,iv_token_value3 => lt_amount_due_remaining(ln_count) -- 未回収残額
                                    ,iv_token_name4  => cv_tkn_006a04_011_3               --「TRX_AMOUNT」
                                    ,iv_token_value4 => lt_trx_amount(ln_count)           -- 消込金額
-- ************ 2010/09/02 1.1 M.Watanabe MOD END   ************ --
                                   )
        );
--
        gb_flag := TRUE;
        lb_check_flag := TRUE;
--
      END IF;
--
    END LOOP error_msg_loop;
--
    -- 業務チェックエラー発生時は更新処理は行わない
    IF NOT( lb_check_flag ) THEN
--
      FORALL ln_count IN 1..lt_row_id.COUNT
  --
        UPDATE xxcfr_apply_upload_work  xauw  -- 入金消込アップロードワーク
           SET xauw.customer_trx_id     = lt_customer_trx_id(ln_count)  -- 取引内部ID
              ,xauw.trx_number          = lt_trx_number(ln_count)       -- 取引番号
              ,xauw.apply_date          = lt_apply_date(ln_count)       -- 消込日
              ,xauw.apply_gl_date       = lt_apply_gl_date(ln_count)    -- 消込GL記帳日
         WHERE xauw.rowid = lt_row_id(ln_count)  -- ROWID
        ;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
      IF ( get_trx_id_cur%ISOPEN ) THEN
        CLOSE get_trx_id_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  ##########################################
--
  END get_cust_trx_data;
--
  /***********************************************************************************
   * Procedure Name   : get_cash_rec_data
   * Description      : 入金情報取得(A-7)
   ***********************************************************************************/
  PROCEDURE get_cash_rec_data(
    ov_errbuf     OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cash_rec_data'; -- プログラム名
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
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    UPDATE xxcfr_apply_upload_work  xauw              -- 入金消込アップロードワーク
       SET xauw.cash_receipt_id = gn_cash_receipt_id  -- 入金内部ID
     WHERE xauw.file_id         = gn_file_id          -- ファイルID
       AND xauw.request_id      = cn_request_id       -- 要求ID
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
--#####################################  固定部 END  ##########################################
--
  END get_cash_rec_data;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : check_data_lock
   * Description      : 入金情報排他チェック(A-10)
   ***********************************************************************************/
  PROCEDURE check_data_lock(
    ov_errbuf     OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data_lock'; -- プログラム名
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
    CURSOR lock_cash_receipt_cur
    IS
      SELECT  xauw.receipt_number  AS receipt_number         -- 入金番号
      FROM    xxcfr_apply_upload_work   xauw                 -- 入金消込アップロードワーク
             ,ar_cash_receipts_all      acra                 -- 入金テーブル
             ,ar_payment_schedules_all  apsa                 -- 支払計画テーブル
      WHERE   xauw.request_id      = cn_request_id           -- 要求ID
        AND   xauw.cash_receipt_id = acra.cash_receipt_id    -- 入金内部ID
        AND   (xauw.cash_receipt_id = apsa.cash_receipt_id   -- 入金内部ID
          OR   xauw.customer_trx_id = apsa.customer_trx_id)  -- 取引内部ID
        FOR UPDATE OF acra.cash_receipt_id                   -- ロック対象：入金テーブル
                     ,apsa.payment_schedule_id               -- ロック対象：支払計画テーブル
                      NOWAIT
     ;
--
    -- *** ローカル・レコード ***
--
    lock_cash_receipt_rec  lock_cash_receipt_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--  ロックを取得する。
    BEGIN
      -- カーソルオープン
      OPEN lock_cash_receipt_cur;
--
      -- データの取得
      FETCH lock_cash_receipt_cur INTO lock_cash_receipt_rec;
--
      -- カーソルクローズ
      CLOSE lock_cash_receipt_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN  -- テーブルロックできなかった
--
        IF ( lock_cash_receipt_cur%ISOPEN ) THEN
          CLOSE lock_cash_receipt_cur;
        END IF;
--
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => SUBSTRB(xxccp_common_pkg.get_msg(
                                             iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                            ,iv_name         => cv_msg_006a04_017    -- テーブルロックエラー
                                            ,iv_token_name1  => cv_tkn_006a04_017_1  -- トークン'PROF_NAME'
                                            ,iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                  cv_appl_name_cfr
                                                                 ,cv_dict_cfr_00604001
                                                                 )
                                          )
                                         ,1
                                         ,5000
                                   )
        );
--
        gb_flag := TRUE;
--
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
      IF ( lock_cash_receipt_cur%ISOPEN ) THEN
        CLOSE lock_cash_receipt_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  ##########################################
--
  END check_data_lock;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  /***********************************************************************************
   * Procedure Name   : ecxec_apply_api
   * Description      : 入金消込API起動処理 (A-8)
   ***********************************************************************************/
  PROCEDURE ecxec_apply_api(
    ov_errbuf     OUT NOCOPY VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  ) 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ecxec_apply_api'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status   VARCHAR2(1);    -- 標準API戻り値(ステータス)
    ln_msg_count       NUMBER;         -- 標準API戻り値(対象件数)
    lv_msg_data        VARCHAR2(2000); -- 標準API戻り値(メッセージ)
--
    ln_count           PLS_INTEGER;    -- カウンタ
--
    -- *** ローカル・カーソル ***
--
    CURSOR get_work_table_cur
    IS
      SELECT   xauw.receipt_number      AS receipt_number      -- 入金番号
              ,xauw.account_number      AS account_number      -- 顧客コード
              ,xauw.receipt_date        AS receipt_date        -- 入金日
              ,xauw.apply_date          AS apply_date          -- 消込日
              ,xauw.apply_gl_date       AS apply_gl_date       -- 消込GL記帳日
              ,xauw.doc_sequence_value  AS doc_sequence_value  -- 文書番号
              ,xauw.cash_receipt_id     AS cash_receipt_id     -- 入金内部ID
              ,xauw.customer_trx_id     AS customer_trx_id     -- 取引内部ID
              ,xauw.trx_number          AS trx_number          -- 取引番号
              ,xauw.trx_amount          AS trx_amount          -- 消込金額
              ,xauw.comments            AS comments            -- 注釈
      FROM     xxcfr_apply_upload_work xauw     -- 入金消込アップロードロードワーク
      WHERE    xauw.file_id    = gn_file_id     -- ファイルID
        AND    xauw.request_id = cn_request_id  -- 要求ID
      ORDER BY xauw.trx_amount ASC              -- 未回収残高の昇順(マイナス額から消込ため)
-- 2014/02/13 Ver.1.3 T.Nakano ADD Start
              ,xauw.doc_sequence_value ASC      -- 文書番号の昇順(アップロードシートと合わせるため)
-- 2014/02/13 Ver.1.3 T.Nakano ADD End
      ;
--
    -- *** ローカル・レコード ***
--
    TYPE ttype_get_work_table IS TABLE OF get_work_table_cur%ROWTYPE
                             INDEX BY PLS_INTEGER;
    lt_get_work_table   ttype_get_work_table;
--
  BEGIN
--
--##################  固定ステータス初期化部 START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--
--###########################  固定部 END  ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    OPEN get_work_table_cur;
--
    FETCH get_work_table_cur BULK COLLECT INTO lt_get_work_table;
--
    CLOSE get_work_table_cur;
--
    <<exe_api_loop>>
    FOR ln_count IN 1..lt_get_work_table.COUNT LOOP
--
      -- 入金消込API起動
      ar_receipt_api_pub.apply(
         p_api_version     =>  1.0                 -- バージョン
        ,p_init_msg_list   =>  FND_API.G_TRUE
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
        ,p_commit          =>  FND_API.G_FALSE
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
        ,x_return_status   =>  lv_return_status    -- ステータス
        ,x_msg_count       =>  ln_msg_count        -- 対象件数
        ,x_msg_data        =>  lv_msg_data         -- メッセージ
        ,p_customer_trx_id =>  lt_get_work_table(ln_count).customer_trx_id  -- 取引ヘッダID
        ,p_cash_receipt_id =>  lt_get_work_table(ln_count).cash_receipt_id  -- 入金ID
        ,p_amount_applied  =>  lt_get_work_table(ln_count).trx_amount       -- 消込金額
        ,p_apply_date      =>  lt_get_work_table(ln_count).apply_date       -- 消込日
        ,p_apply_gl_date   =>  lt_get_work_table(ln_count).apply_gl_date    -- 消込GL記帳日
        ,p_comments        =>  lt_get_work_table(ln_count).comments         -- 注釈
        );
--
      IF (lv_return_status <> 'S') THEN
        --エラー処理
        lv_errmsg := SUBSTRB(
                        xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_cfr      -- 'XXCFR'
                          ,iv_name         => cv_msg_006a04_012     -- APIエラーメッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--                          ,iv_token_name1  => cv_tkn_006a04_012_1   --「TRX_NUMBER」
--                          ,iv_token_value1 => lt_get_work_table(ln_count).trx_number  -- 取引番号
---- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
--                          ,iv_token_name2  => cv_tkn_006a04_010_1                             --「DOC_SEQUENCE_VALUE」
--                          ,iv_token_value2 => lt_get_work_table(ln_count).doc_sequence_value  -- 文書番号
---- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
                          ,iv_token_name1  => cv_tkn_006a04_012_2  --「RECEIPT_NUMBER」
                          ,iv_token_value1 => gv_receipt_number    -- 入金番号
                          ,iv_token_name2  => cv_tkn_006a04_010_1                             --「DOC_SEQUENCE_VALUE」
                          ,iv_token_value2 => lt_get_work_table(ln_count).doc_sequence_value  -- 文書番号
                          ,iv_token_name3  => cv_tkn_006a04_012_1                     --「TRX_NUMBER」
                          ,iv_token_value3 => lt_get_work_table(ln_count).trx_number  -- 請求書番号(取引番号)
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
                        )
                       ,1
                       ,5000
                     );
--
        -- 入金消込APIエラーメッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        -- API標準エラーメッセージが１件の場合
        IF (ln_msg_count = 1) THEN
--
          FND_FILE.PUT_LINE(
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--             which  => FND_FILE.OUTPUT
             which  => FND_FILE.LOG
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
            ,buff   => '・' || lv_msg_data
          );
--
        -- API標準エラーメッセージが複数件の場合
        ELSE
--
          FND_FILE.PUT_LINE(
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--             which  => FND_FILE.OUTPUT
             which  => FND_FILE.LOG
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
            ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
--
          ln_msg_count := ln_msg_count - 1;
--
          <<while_loop>>
          WHILE ln_msg_count > 0 LOOP
--
            FND_FILE.PUT_LINE(
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--               which  => FND_FILE.OUTPUT
               which  => FND_FILE.LOG
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
              ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                           ,1
                                           ,5000
                                         )
            );
--
            ln_msg_count := ln_msg_count - 1;
--
          END LOOP while_loop;
--
        END IF;
--
        gb_flag := TRUE;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
        gb_warn_flag := TRUE;
--
        -- エラーならばロールバック
        ROLLBACK;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
        EXIT;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--      END IF;  -- 'S'以外
      ELSE
        -- 正常ならばコミット
        COMMIT;
--
        gn_normal_cnt := gn_normal_cnt + 1;
--
        gn_normal_trx_amount_sum := gn_normal_trx_amount_sum + lt_get_work_table(ln_count).trx_amount;
--
      END IF;
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    END LOOP exe_api_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ####################################
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
      IF ( get_work_table_cur%ISOPEN ) THEN
        CLOSE get_work_table_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  ##########################################
--
  END ecxec_apply_api;
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : 終了処理(A-9)
   **********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf     OUT NOCOPY VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START  ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_end'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
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
    -- <カーソル名>
--
  BEGIN
--
--##################  固定ステータス初期化部 START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  固定部 END  ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL Start
--    -- 正常終了時はワークテーブル明示削除(異常時はロールバックされる)
--    IF NOT( gb_flag ) THEN
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL End
--
      -- ワークテーブル削除
      DELETE FROM  xxcfr_apply_upload_work  xauw
      WHERE xauw.file_id    = gn_file_id
      AND   xauw.request_id = cn_request_id
      ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL Start
--    END IF;
----
--    -- 異常終了時は入金消込APIを戻す為にROLLBACK実行
--    IF ( gb_flag ) THEN
--      ROLLBACK;
--    END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL End
    -- ファイルアップロードIFテーブル削除
    DELETE FROM  xxccp_mrp_file_ul_interface  xmfui
    WHERE xmfui.file_id = gn_file_id
    ;
--
    -- 異常終了時はファイルアップロードIFテーブル削除のためにCOMMIT実行
    IF ( gb_flag ) THEN
      COMMIT;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ###################################
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
--####################################  固定部 END  ##########################################
--
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_format IN         VARCHAR2    -- ファイルフォーマット
   ,ov_errbuf      OUT NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg      OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START  ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END  ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
   cv_1           CONSTANT VARCHAR2(1)    := '1';  -- アップロード対象
   cv_2           CONSTANT VARCHAR2(1)    := '2';  -- ダミー値
--
    -- *** ローカル変数 ***
-- 変数
    ln_count               PLS_INTEGER;  -- カウンタ
    ln_target_count        PLS_INTEGER;  -- カウンタ(対象件数)
    lv_comment_flag        VARCHAR2(1);
    ln_customer_trx_id     ra_customer_trx_all.customer_trx_id%TYPE;   -- 取引内部ID
    ln_cash_receipt_id     ar_cash_receipts_all.cash_receipt_id%TYPE;  -- 入金内部ID
-- テーブル
    lt_file_data_tbl       xxccp_common_pkg2.g_file_data_tbl;          -- ファイルアップロードデータ格納配列
--
    lt_receipt_number      ttype_receipt_number;      -- 入金番号
    lt_account_number      ttype_account_number;      -- 顧客コード
    lt_receipt_date        ttype_receipt_date;        -- 入金日
    lt_doc_sequence_value  ttype_doc_sequence_value;  -- 文書番号
    lt_trx_amount          ttype_trx_amount;          -- 消込金額
    lt_comments            ttype_comments;            -- 注釈
-- レコード
    lr_work_rtype          xxcfr_apply_upload_work%ROWTYPE; -- 入金消込ワークレコード
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    lt_file_data_tbl.DELETE;
    lt_receipt_number.DELETE;      -- 入金番号
    lt_account_number.DELETE;      -- 顧客コード
    lt_receipt_date.DELETE;        -- 入金日
    lt_doc_sequence_value.DELETE;  -- 文書番号
    lt_trx_amount.DELETE;          -- 消込金額
    lt_comments.DELETE;            -- 注釈
--
    lr_work_rtype := NULL;
--
    ln_target_count    := 0;
    lv_comment_flag    := NULL;
    ln_customer_trx_id := NULL;
    ln_cash_receipt_id := NULL;
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
--
    -- 共通初期処理の呼び出し
    proc_init(
       iv_file_format => iv_file_format  -- ファイルフォーマット
      ,ov_retcode     => lv_retcode      -- エラー・メッセージ           --# 固定 #
      ,ov_errbuf      => lv_errbuf       -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ファイルアップロードIFデータ取得(A-2)
    -- =====================================================
    get_if_data(
       ot_file_data_tbl => lt_file_data_tbl -- ファイルアップロードデータ格納配列
      ,ov_retcode       => lv_retcode       -- エラー・メッセージ           --# 固定 #
      ,ov_errbuf        => lv_errbuf        -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      gn_target_cnt := gn_target_cnt + 1;
      gb_flag := TRUE;
      RAISE global_process_expt;
    END IF;
--
    --配列に格納されているCSV行を1行づつ取得する
    <<main_loop>>
    FOR ln_count IN 1..lt_file_data_tbl.COUNT LOOP
--
      gn_target_cnt := gn_target_cnt + 1;   --処理件数カウント
--
      -- =====================================================
      --  デリミタ文字項目分割(A-3)
      -- =====================================================
      devide_item(
         iv_file_data  => lt_file_data_tbl(ln_count)  -- ファイルデータ
        ,in_count      => ln_count
        ,ov_flag       => lv_comment_flag              -- データ区分(コメント行判定用)
        ,or_work_table => lr_work_rtype                -- 入金消込ワークレコード
        ,ov_retcode    => lv_retcode                   -- エラー・メッセージ           --# 固定 #
        ,ov_errbuf     => lv_errbuf                    -- リターン・コード             --# 固定 #
        ,ov_errmsg     => lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- コメント行(消込フラグが１でない)の項目エラーはスキップ
      IF ( lv_retcode = cv_status_warn ) THEN
--
        -- コメント行は処理対象件数をカウントダウンする
        IF ( NVL( lv_comment_flag , cv_2 ) <> cv_1 ) THEN
          gn_target_cnt := gn_target_cnt - 1;
        END IF;
--
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSE
        -- カウントアップ
        ln_target_count := ln_target_count + 1;
--
        -- 正常データを配列に格納
        lt_receipt_date(ln_target_count)       := lr_work_rtype.receipt_date;        -- 入金日
        lt_receipt_number(ln_target_count)     := lr_work_rtype.receipt_number;      -- 入金番号
        lt_account_number(ln_target_count)     := lr_work_rtype.account_number;      -- 顧客コード
        lt_comments(ln_target_count)           := lr_work_rtype.comments;            -- 消込注釈
        lt_doc_sequence_value(ln_target_count) := lr_work_rtype.doc_sequence_value;  -- 文書番号
        lt_trx_amount(ln_target_count)         := lr_work_rtype.trx_amount;          -- 消込金額
--
      END IF;
--
    END LOOP main_loop;
--
    -- デリミタ文字項目分割(A-3)エラーの時は終了処理(A-9)を行う
    IF ( gb_flag = FALSE ) THEN
--
      -- =====================================================
      --  ワークテーブル登録(A-4)
      -- =====================================================
      insert_work(
         it_receipt_number      => lt_receipt_number      -- 入金番号
        ,it_account_number      => lt_account_number      -- 顧客コード
        ,it_receipt_date        => lt_receipt_date        -- 入金日
        ,it_doc_sequence_value  => lt_doc_sequence_value  -- 文書番号
        ,it_trx_amount          => lt_trx_amount          -- 消込金額
        ,it_comments            => lt_comments            -- 注釈
        ,ov_retcode             => lv_retcode             -- エラー・メッセージ           --# 固定 #
        ,ov_errbuf              => lv_errbuf              -- リターン・コード             --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 入金情報をグローバル変数に格納
      gv_receipt_number := lt_receipt_number(1);  -- 入金番号
      gv_account_number := lt_account_number(1);  -- 顧客コード
      gd_receipt_date   := lt_receipt_date(1);    -- 入金日
      gv_receipt_date   := TO_CHAR(lt_receipt_date(1)
                                  ,cv_yyyy_mm_dd
                           );                     -- 入金日(文字列)
--
      -- 開放
      lt_receipt_number.DELETE;      -- 入金番号
      lt_account_number.DELETE;      -- 顧客コード
      lt_receipt_date.DELETE;        -- 入金日
      lt_doc_sequence_value.DELETE;  -- 文書番号
      lt_trx_amount.DELETE;          -- 消込金額
      lt_comments.DELETE;            -- 注釈
--
      -- =====================================================
      --  妥当性チェック(A-5)
      -- =====================================================
      check_data(
         ov_retcode    => lv_retcode     -- エラー・メッセージ           --# 固定 #
        ,ov_errbuf     => lv_errbuf      -- リターン・コード             --# 固定 #
        ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  取引情報設定(A-6)
      -- =====================================================
      get_cust_trx_data(
         ov_retcode    => lv_retcode     -- エラー・メッセージ           --# 固定 #
        ,ov_errbuf     => lv_errbuf      -- リターン・コード             --# 固定 #
        ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  入金情報設定(A-7)
      -- =====================================================
      get_cash_rec_data(
         ov_retcode    => lv_retcode     -- エラー・メッセージ           --# 固定 #
        ,ov_errbuf     => lv_errbuf      -- リターン・コード             --# 固定 #
        ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
      -- 業務チェック(A-5～A-7)エラー時は入金情報排他チェック(A-10)は行わない
      IF ( gb_flag = FALSE ) THEN
--
        -- =====================================================
        --  入金情報排他チェック(A-10)
        -- =====================================================
        check_data_lock(
           ov_retcode    => lv_retcode     -- エラー・メッセージ           --# 固定 #
          ,ov_errbuf     => lv_errbuf      -- リターン・コード             --# 固定 #
          ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- 入金情報排他チェック(A-10)エラー時は入金消込API起動処理(A-8)は行わない
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
      -- 業務チェック(A-5～A-7)エラー時は入金消込API起動処理(A-8)は行わない
      IF ( gb_flag = FALSE ) THEN
--
        -- =====================================================
        --  入金消込API起動処理(A-8)
        -- =====================================================
        ecxec_apply_api(
           ov_retcode    => lv_retcode       -- エラー・メッセージ           --# 固定 #
          ,ov_errbuf     => lv_errbuf        -- リターン・コード             --# 固定 #
          ,ov_errmsg     => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    -- =====================================================
    --  終了処理(A-9)
    -- =====================================================
    proc_end(
       ov_retcode    => lv_retcode       -- エラー・メッセージ           --# 固定 #
      ,ov_errbuf     => lv_errbuf        -- リターン・コード             --# 固定 #
      ,ov_errmsg     => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ###################################
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
--####################################  固定部 END  ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   エラーメッセージ #固定#
    retcode        OUT NOCOPY   VARCHAR2,   --   エラーコード     #固定#
    iv_file_id     IN  VARCHAR2,            --   1.ファイルID
    iv_file_format IN  VARCHAR2             --   2.ファイルフォーマット
  )
--
--
--###########################  固定部 START  ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
--    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
--    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_app_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00136'; -- 消込済件数金額メッセージ
    cv_unapp_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00137'; -- 未消込件数金額メッセージ
    cv_app_process_no_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00142'; -- 消込処理Noメッセージ
    cv_rec_header_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00143'; -- 処理結果ヘッダメッセージ
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    cv_amt_token       CONSTANT VARCHAR2(10)  := 'AMOUNT';           -- 金額メッセージ用トークン名
    cv_app_count_token    CONSTANT VARCHAR2(10)  := 'APP_COUNT';     -- 消込処理Noメッセージ用トークン名(消込済件数)
    cv_unapp_count_token  CONSTANT VARCHAR2(11)  := 'UNAPP_COUNT';   -- 消込処理Noメッセージ用トークン名(未消込件数)
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END  ####################################
--
--
  BEGIN
--
--###########################  固定部 START  ###########################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    gn_normal_trx_amount_sum := 0;
    gn_error_trx_amount_sum  := 0;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_out
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END  #############################
--
    -- ファイルIDをグローバル変数に確保
    gn_file_id := TO_NUMBER(iv_file_id);
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_file_format => iv_file_format  -- 2.ファイルフォーマット
      ,ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    -- 業務チェックエラーの時は、エラー件数を処理対象件数と同値にする。(全件消込出来なかったの意味)
--    IF ( gb_flag ) THEN
--      gn_error_cnt := gn_target_cnt;
--    ELSE
--      gn_normal_cnt := gn_target_cnt;
--    END IF;
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
--
    gn_error_trx_amount_sum := gn_trx_amount_sum - gn_normal_trx_amount_sum;
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    --エラー時は関数から返却されたメッセージを出力
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
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --処理結果ヘッダ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cfr
                    ,iv_name         => cv_rec_header_msg
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    --成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_name_cmn
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
    --消込済件数金額出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cfr
                    ,iv_name         => cv_app_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name2  => cv_amt_token
                    ,iv_token_value2 => TO_CHAR(gn_normal_trx_amount_sum)
                   );
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    --エラー件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_name_cmn
--                    ,iv_name         => cv_error_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                   );
    --未消込件数金額メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cfr
                    ,iv_name         => cv_unapp_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                    ,iv_token_name2  => cv_amt_token
                    ,iv_token_value2 => TO_CHAR(gn_error_trx_amount_sum)
                   );
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    lv_message_code := cv_normal_msg;
----
--    --エラーがあれば、エラー終了に上書き
--    IF ( gn_error_cnt > 0) THEN
--      lv_message_code := cv_error_msg;
--      retcode := cv_status_error;
--    END IF;
----
    IF ( gb_warn_flag ) THEN
      lv_retcode := cv_status_warn;
    ELSIF ( gb_flag ) THEN
      lv_retcode := cv_status_error;
    END IF;
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => lv_message_code
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --警告終了の場合
    IF ( lv_retcode = cv_status_warn ) THEN
      --１行改行
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
      --消込処理Noメッセージ
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_cfr
                      ,iv_name         => cv_app_process_no_msg
                      ,iv_token_name1  => cv_app_count_token
                      ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                      ,iv_token_name2  => cv_unapp_count_token
                      ,iv_token_value2 => TO_CHAR(gn_error_cnt)
                     );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
  END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    --ステータスセット
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    errbuf := lv_errbuf;
    retcode := lv_retcode;
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  ###################################
--
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
--######################################  固定部 END  ########################################
--
END XXCFR006A04C;
/
