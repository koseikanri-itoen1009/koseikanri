CREATE OR REPLACE PACKAGE BODY APPS.XXCSO006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO006A02C(body)
 * Description      : EBS(ファイルアップロードI/F)に取込まれた訪問実績データをタスクに取込みます。
 *                    
 * MD.050           : MD050_CSO_006_A02_訪問実績データ格納
 *                    
 * Version          : 1.7
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                                        (A-1)
 *  get_profile_info            プロファイル値取得                              (A-2)
 *  get_visit_data              訪問実績データ抽出処理                          (A-3)
 *  get_inupd_data              登録（A-8）、更新（A-9）処理で必要なデータ取得  (A-4)
 *  data_proper_check           データ妥当性チェック                            (A-5)
 *  chk_mst_is_exists           マスタ存在チェック                              (A-6)
 *  get_visit_same_data         同一訪問実績データ抽出                          (A-7)
 *  insert_visit_data           訪問実績データ登録                              (A-8)
 *  update_visit_data           訪問実績データ更新                              (A-9)
 *  delete_if_data              ファイルデータ削除処理                          (A-11)
 *  submain                     メイン処理プロシージャ(
 *                                セーブポイント設定                            (A-10)
 *                              )
 *  main                        コンカレント実行ファイル登録プロシージャ(
 *                                終了処理                                      (A-12)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-01    1.0   Kichi.Cho        新規作成
 *  2009-03-16    1.1   Kazuo.Satomura   仕様変更対応(障害ID62)
 *                                       ・顧客セキュリティ要件対応
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2009-05-14    1.4   Kazuo.Satomura   T1_0931対応
 *  2009-05-28    1.5   Kazuo.Satomura   T1_0137対応
 *  2009-07-16    1.6   Kazuo.Satomura   0000070対応
 *  2009-09-08    1.7   Daisuke.Abe      0001312対応
 *  2010-02-15    1.8   T.Maruyama       E_本稼動_01130対応
 *****************************************************************************************/
-- 
-- #######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal       CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn         CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error        CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part            CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont            CONSTANT VARCHAR2(3) := '.';
--
-- #######################  固定グローバル定数宣言部 END   #########################
--
-- #######################  固定グローバル変数宣言部 START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- 対象件数
  gn_normal_cnt          NUMBER;                    -- 正常件数
  gn_error_cnt           NUMBER;                    -- エラー件数
--
-- #######################  固定グローバル変数宣言部 END   #########################
--
-- #######################  固定共通例外宣言部 START       #########################
--
  --*** 処理部共通例外 ***
  global_process_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  固定共通例外宣言部 END         #########################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO006A02C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';                 -- アクティブ
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- 有効
--
  -- CSVファイルの項目順番
  cn_employee_number     CONSTANT NUMBER        := 2;                   -- 社員コード
  cn_account_number      CONSTANT NUMBER        := 3;                   -- 顧客コード
  cn_visit_ymd           CONSTANT NUMBER        := 5;                   -- 訪問日
  cn_visit_time          CONSTANT NUMBER        := 6;                   -- 開始時刻
  cn_description         CONSTANT NUMBER        := 7;                   -- 詳細内容
  -- CSVファイルの訪問区分
  cn_visit_dff_0         CONSTANT NUMBER        := 0;                   -- 区分なし
  -- CSVファイルの項目名称
  cv_employee_number_nm  CONSTANT VARCHAR2(100) := '社員コード';        -- 社員コード
  cv_account_number_nm   CONSTANT VARCHAR2(100) := '顧客コード';        -- 顧客コード
  cv_visit_nm            CONSTANT VARCHAR2(100) := '訪問日時';          -- 訪問日時
  cv_visit_dff1_nm       CONSTANT VARCHAR2(100) := '拡販活動';          -- 拡販活動
  cv_visit_dff2_nm       CONSTANT VARCHAR2(100) := '販促フォロー';      -- 販促フォロー
  cv_visit_dff3_nm       CONSTANT VARCHAR2(100) := '店頭調査';          -- 店頭調査
  cv_visit_dff4_nm       CONSTANT VARCHAR2(100) := 'クレーム対応';      -- クレーム対応
  cv_visit_dff5_nm       CONSTANT VARCHAR2(100) := '売り場支援';        -- 売り場支援
  cv_visit_dff6_nm       CONSTANT VARCHAR2(100) := '導入チェック（お茶）';   -- 導入チェック（お茶）
  cv_visit_dff7_nm       CONSTANT VARCHAR2(100) := '導入チェック（野菜）';   -- 導入チェック（野菜）
  cv_visit_dff8_nm       CONSTANT VARCHAR2(100) := '導入チェック（その他）'; -- 導入チェック（その他）
  cv_visit_dff9_nm       CONSTANT VARCHAR2(100) := '導入チェック（リーフ）'; -- 導入チェック（リーフ）
  cv_visit_dff10_nm      CONSTANT VARCHAR2(100) := '導入チェック（チルド）'; -- 導入チェック（チルド）
--
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- プロファイル取得エラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ抽出エラー
    -- データ抽出エラー（ファイルアップロードI/Fテーブル）
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00025';
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- パラメータNULLエラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00027';  -- 訪問実績データフォーマットチェックエラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00028';  -- NUMBER型チェックエラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';  -- 日付書式エラー
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00030';  -- サイズチェックエラー
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- マスタチェックエラー
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00117';  -- 訪問日が締め日を過ぎているエラー
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00118';  -- データ登録、更新、削除エラー
    -- データ削除エラー（ファイルアップロードI/Fテーブル）
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00033';
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00034';  -- ロックエラー
    -- ロックエラーメッセージ(ファイルアップロードI/Fテーブル) 
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00035';
    -- マスタチェック（顧客マスタ）ダミー顧客コードセット
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00036';
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- アップロードファイル名称抽出エラー
    -- コンカレント入力パラメータ
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- パラメータファイルID
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- パラメータフォーマットパターン
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- CSVファイル名称
  /* 2009.07.16 K.Satomura 0000070対応 START */
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00578';  -- タスク存在エラー
  /* 2009.07.16 K.Satomura 0000070対応 END */
--
  -- トークンコード
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_process         CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< プロファイル値取得 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'ダミー顧客コード = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '訪問実績データを抽出しました。';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := '<< 必要なデータ取得 >>';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '訪問区分コードを抽出しました。';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'パーティID = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'パーティ名称 = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '顧客ステータス = ';
  cv_debug_msg15          CONSTANT VARCHAR2(200) := 'ファイルデータ削除しました。';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '<< 訪問実績データ抽出 >>';
  cv_debug_msg19          CONSTANT VARCHAR2(200) := '<< ファイルデータ削除 >>';
  cv_debug_msg22          CONSTANT VARCHAR2(200) := 'ロールバックしました。';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 行単位データを格納する配列
  TYPE g_col_data_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  /* 2009.05.14 K.Satomura T1_0931対応 START */
  TYPE g_dff_cd_array IS VARRAY(10) OF fnd_lookup_values_vl.lookup_code%TYPE;
  /* 2009.05.14 K.Satomura T1_0931対応 END */
  -- 訪問実績データ＆関連情報抽出データ
  TYPE g_visit_data_rtype IS RECORD(
    employee_number      per_people_f.employee_number%TYPE,        -- 社員コード
    account_number       hz_cust_accounts.account_number%TYPE,     -- 顧客コード
    visit_date           DATE,                                     -- 訪問日時
    description          jtf_tasks_tl.description%TYPE,            -- 詳細内容
    /* 2009.05.14 K.Satomura T1_0931対応 START */
    --dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 拡販活動
    --dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 販促フォロー
    --dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 店頭調査
    --dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- クレーム対応
    --dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 売り場支援
    --dff6_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 導入チェック（お茶）
    --dff7_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 導入チェック（野菜）
    --dff8_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 導入チェック（その他）
    --dff9_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 導入チェック（リーフ）
    --dff10_cd             fnd_lookup_values_vl.lookup_code%TYPE,    -- 導入チェック（チルド）
    dff_cd_table         g_dff_cd_array,                           -- 訪問区分用配列
    /* 2009.05.14 K.Satomura T1_0931対応 END */
    resource_id          jtf_rs_resource_extns.resource_id%TYPE,   -- リソースID
    party_id             hz_parties.party_id%TYPE,                 -- パーティID
    party_name           hz_parties.party_name%TYPE,               -- パーティ名称
    customer_status      hz_parties.duns_number_c%TYPE             -- 顧客ステータス
  );
  -- CSVファイル項目の順番(訪問区分)
  TYPE g_csv_order_rtype IS RECORD(
    dff1_num             NUMBER,                                   -- 拡販活動順番
    dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff2_num             NUMBER,                                   -- 販促フォロー順番
    dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff3_num             NUMBER,                                   -- 店頭調査順番
    dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff4_num             NUMBER,                                   -- クレーム対応順番
    dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff5_num             NUMBER,                                   -- 売り場支援順番
    dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff6_num             NUMBER,                                   -- 導入チェック（お茶）順番
    dff6_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff7_num             NUMBER,                                   -- 導入チェック（野菜）順番
    dff7_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff8_num             NUMBER,                                   -- 導入チェック（その他）順番
    dff8_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff9_num             NUMBER,                                   -- 導入チェック（リーフ）順番
    dff9_cd              fnd_lookup_values_vl.lookup_code%TYPE,    -- 区分コード
    dff10_num            NUMBER,                                   -- 導入チェック（チルド）順番
    dff10_cd             fnd_lookup_values_vl.lookup_code%TYPE     -- 区分コード
  );
  -- *** ユーザー定義グローバル例外 ***
  global_skip_error_expt EXCEPTION;
  global_lock_expt       EXCEPTION;                                -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  g_file_data_tab        xxccp_common_pkg2.g_file_data_tbl;
  g_visit_data_rec       g_visit_data_rtype;                       -- 訪問実績データレコード
  g_csv_order_rec        g_csv_order_rtype;                        -- CSVファイル項目の順番(訪問区分)
--
  gt_file_id             xxccp_mrp_file_ul_interface.file_id%TYPE; -- ファイルID
  gv_fmt_ptn             VARCHAR2(20);                             -- フォーマットパターン
  gt_party_id            hz_parties.party_id%TYPE;                 -- パーティID
  gt_party_name          hz_parties.party_name%TYPE;               -- パーティ名称
  gt_customer_status     hz_parties.duns_number_c%TYPE;            -- 顧客ステータス
  gb_task_inup_rollback_flag     BOOLEAN := FALSE;                 -- TRUE : ロールバック
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- ファイルアップロード名称(参照タイプテーブル)
    cv_file_upload_lookup_type     CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_visit_data_lookup_code      CONSTANT VARCHAR2(30)  := '620';
    -- *** ローカル変数 ***
    lv_file_upload_nm              VARCHAR2(30);    -- ファイルアップロード名称
    -- メッセージ出力用
    lv_msg                         VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入力パラメータメッセージ出力
    -- ファイルIDメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name              -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_17         -- メッセージコード
                ,iv_token_name1  => cv_tkn_file_id           -- トークンコード1
                ,iv_token_value1 => TO_CHAR(gt_file_id)      -- トークン値1
              );
--
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' || CHR(10) || lv_msg
    );
    -- ファイルIDログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_msg
    );
--
    -- フォーマットパターンメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name              -- アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_18         -- メッセージコード
                   ,iv_token_name1  => cv_tkn_fmt_ptn           -- トークンコード1
                   ,iv_token_value1 => gv_fmt_ptn               -- トークン値1
                 );
--
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => lv_msg || CHR(10)
    );
--
    -- 入力パラメータファイルIDのNULLチェック
    IF gt_file_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_04         -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロード名称抽出
    BEGIN
--
      -- 参照タイプテーブルからファイルアップロード名称抽出
      SELECT lvvl.meaning                                         -- 内容
      INTO   lv_file_upload_nm
      FROM   fnd_lookup_values_vl lvvl                            -- 参照タイプテーブル
      WHERE  lvvl.lookup_type = cv_file_upload_lookup_type
        AND TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
              AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
        AND lvvl.enabled_flag = cv_enabled_flag
        AND lvvl.lookup_code = cv_visit_data_lookup_code;
--    
      -- ファイルアップロード名称メッセージ
      lv_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_19         -- メッセージコード
                    ,iv_token_name1  => cv_tkn_file_upload_nm    -- トークンコード1
                    ,iv_token_value1 => lv_file_upload_nm        -- トークン値1
                   );
--
      -- ファイルアップロード名称メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg || CHR(10)
      );
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg || CHR(10)
      );
--
    EXCEPTION
      -- ファイルアップロード名称抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16           -- メッセージコード
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_profile_info(
     ov_dummy_acc_num    OUT NOCOPY VARCHAR2  -- ダミー顧客コード              -- # 固定 #
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_profile_info';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- プロファイル名 (XXCSO: 訪問実績データ格納用ダミー顧客コード)
    cv_prfnm_dummy_acc_num      CONSTANT VARCHAR2(30)   := 'XXCSO1_VISIT_DMMY_CUST_CD';
--
    -- *** ローカル変数 ***
    lv_dummy_acc_num            VARCHAR2(30);                           -- ダミー顧客コード
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
       cv_prfnm_dummy_acc_num
      ,lv_dummy_acc_num
    ); -- ダミー顧客コード
--
    -- プロファイル値取得に失敗した場合
    IF (lv_dummy_acc_num IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_nm               -- トークンコード1
                     ,iv_token_value1 => cv_prfnm_dummy_acc_num       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_dummy_acc_num := lv_dummy_acc_num;
--
      -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) || cv_debug_msg2 || lv_dummy_acc_num || CHR(10)
    );
--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 処理例外ハンドラ ***
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
-- #####################################  固定部 END   ##########################################
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_data
   * Description      : 訪問実績データ抽出処理 (A-3)
   ***********************************************************************************/
--
  PROCEDURE get_visit_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
    -- *** ローカル変数 ***
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;          -- ファイル名
    lt_file_content_type xxccp_mrp_file_ul_interface.file_content_type%TYPE;  -- ファイル区分
    lt_file_data         xxccp_mrp_file_ul_interface.file_data%TYPE;             -- ファイルデータ
    lt_file_format       xxccp_mrp_file_ul_interface.file_format%TYPE;        -- ファイルフォーマット
    -- メッセージ出力用
    lv_msg               VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      -- ファイルデータ抽出
      SELECT xmfui.file_name file_name                                        -- ファイル名
            ,xmfui.file_content_type file_content_type
            ,xmfui.file_data file_date                                        -- ファイルデータ
            ,xmfui.file_format file_format
      INTO   lt_file_name
            ,lt_file_content_type
            ,lt_file_data
            ,lt_file_format
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_14                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                         -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm                     -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id                     -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                         -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm                     -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id                     -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード2
                       ,iv_token_value3 => SQLERRM                            -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gt_file_id         -- ファイルID
      ,ov_file_data => g_file_data_tab    -- ファイルデータ
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                        -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03                   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl                         -- トークンコード1
                     ,iv_token_value1 => cv_if_table_nm                     -- トークン値1
                     ,iv_token_name2  => cv_tkn_file_id                     -- トークンコード2
                     ,iv_token_value2 => TO_CHAR(gt_file_id)                -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード2
                     ,iv_token_value3 => lv_errbuf                          -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- CSVファイル名メッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name              -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_20         -- メッセージコード
                ,iv_token_name1  => cv_tkn_csv_file_nm       -- トークンコード1
                ,iv_token_value1 => lt_file_name             -- トークン値1
              );
    -- CSVファイル名メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10)
    );
    -- CSVファイル名ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg || CHR(10)
    );
    -- データ抽出ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg16 || CHR(10) || cv_debug_msg3 || CHR(10)
    );
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END get_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inupd_data
   * Description      : 登録（A-8）、更新（A-9）処理で必要なデータ取得 (A-4)
   ***********************************************************************************/
--
  PROCEDURE get_inupd_data(
     iv_dummy_acc_num    IN         VARCHAR2  -- ダミー顧客コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_inupd_data';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_activity_lookup_type     CONSTANT VARCHAR2(100) := 'XXCSO1_VISIT_ACTIVITY_NUMBER';
    cv_kubun_lookup_type        CONSTANT VARCHAR2(100) := 'XXCSO_ASN_HOUMON_KUBUN';
    cv_account_table_vl_nm      CONSTANT VARCHAR2(100) := '顧客マスタビュー';
    cv_lookup_table_nm          CONSTANT VARCHAR2(100) := '参照タイプテーブル';
--
    -- *** ローカル・カーソル *** 
    CURSOR l_houmon_kubun_cur
    IS
      SELECT xvan.lookup_code num                                     -- 順番
            ,xahk.lookup_code code                                    -- 訪問区分コード
            ,xvan.meaning meaning                                     -- 内容
      FROM   fnd_lookup_values_vl xvan
            ,fnd_lookup_values_vl xahk
      WHERE  xvan.lookup_type = cv_activity_lookup_type
        AND  TRUNC(SYSDATE) BETWEEN TRUNC(xvan.start_date_active)
               AND TRUNC(NVL(xvan.end_date_active, SYSDATE))
        AND  xvan.enabled_flag = cv_enabled_flag
        AND  xahk.lookup_type = cv_kubun_lookup_type
        AND  TRUNC(SYSDATE) BETWEEN TRUNC(xahk.start_date_active)
               AND TRUNC(NVL(xahk.end_date_active, SYSDATE))
        AND  xahk.enabled_flag = cv_enabled_flag
        AND  xvan.meaning = xahk.meaning;
--
    -- *** ローカル・レコード *** 
    l_houmon_kubun_rec l_houmon_kubun_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. 参照タイプテーブルから訪問区分コードの取得 *** --
    BEGIN
--
      -- カーソルオープン
      OPEN l_houmon_kubun_cur;
--
      <<houmon_kubun_loop>>
      LOOP
        FETCH l_houmon_kubun_cur INTO l_houmon_kubun_rec;
--
        EXIT WHEN l_houmon_kubun_cur%NOTFOUND
          OR l_houmon_kubun_cur%ROWCOUNT = 0;
--
        -- 訪問区分
        IF (l_houmon_kubun_rec.meaning = cv_visit_dff1_nm) THEN
        -- 拡販活動
          g_csv_order_rec.dff1_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff1_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff2_nm) THEN
        -- 販促フォロー
          g_csv_order_rec.dff2_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff2_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff3_nm) THEN
        -- 店頭調査
          g_csv_order_rec.dff3_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff3_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff4_nm) THEN
        -- クレーム対応
          g_csv_order_rec.dff4_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff4_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff5_nm) THEN
        -- 売り場支援
          g_csv_order_rec.dff5_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff5_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff6_nm) THEN
        -- 導入チェック（お茶）
          g_csv_order_rec.dff6_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff6_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff7_nm) THEN
        -- 導入チェック（野菜）
          g_csv_order_rec.dff7_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff7_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff8_nm) THEN
        -- 導入チェック（その他）
          g_csv_order_rec.dff8_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff8_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff9_nm) THEN
        -- 導入チェック（リーフ）
          g_csv_order_rec.dff9_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff9_cd := l_houmon_kubun_rec.code;
        ELSIF (l_houmon_kubun_rec.meaning = cv_visit_dff10_nm) THEN
        -- 導入チェック（チルド）
          g_csv_order_rec.dff10_num := l_houmon_kubun_rec.num;
          g_csv_order_rec.dff10_cd := l_houmon_kubun_rec.code;
        END IF;
--
      END LOOP houmon_kubun_loop;
--
      -- 件数が0件の場合
      IF (l_houmon_kubun_cur%ROWCOUNT = 0) THEN
        RAISE NO_DATA_FOUND;
      END IF;
      -- カーソル・クローズ
      CLOSE l_houmon_kubun_cur;
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg4 || CHR(10) || cv_debug_msg5
      );
--
    EXCEPTION
      -- 抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        -- カーソル・クローズ
        IF (l_houmon_kubun_cur%ISOPEN) THEN
          CLOSE l_houmon_kubun_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_lookup_table_nm           -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- *** 2. ダミー顧客コードでパーティID、パーティ名称と顧客ステータスの取得 *** --
    BEGIN
--
      SELECT xcav.party_id                                              -- パーティID
            ,xcav.party_name                                            -- パーティ名称
            ,xcav.customer_status                                       -- 顧客ステータス
      INTO   gt_party_id
            ,gt_party_name
            ,gt_customer_status
      FROM   xxcso_cust_accounts_v xcav
      WHERE  xcav.account_number = iv_dummy_acc_num
        AND xcav.account_status = cv_active_status
        AND xcav.party_status = cv_active_status;
--
        -- ログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg6 || gt_party_id || '、' ||
                     cv_debug_msg7 || gt_party_name || '、' ||
                     cv_debug_msg8 || gt_customer_status || CHR(10)
        );
--
    EXCEPTION
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_account_table_vl_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END get_inupd_data;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : 妥当性チェック (A-5)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_base_value       IN  VARCHAR2                -- 当該行データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ           -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード             -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_format_col_cnt       CONSTANT NUMBER        := 26;                   -- 項目数
    cn_employee_number_len  CONSTANT NUMBER        := 5;                    -- 社員コードバイト数
    cn_account_number_len   CONSTANT NUMBER        := 9;                    -- 顧客コードバイト数
    cn_activity_kubun_len   CONSTANT NUMBER        := 1;                    -- 活動内容バイト数
    cn_description_cut_len  CONSTANT NUMBER        := 2000;                 -- 詳細内容範囲
    cv_visit_date_fmt       CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI'; -- DATE型
--
    -- *** ローカル変数 ***
    l_col_data_tab            g_col_data_ttype;      -- 分割後項目データを格納する配列
    lv_item_nm                VARCHAR2(100);         -- 該当項目名
    lv_visit_date             VARCHAR2(100);         -- 訪問日時
    lb_return                 BOOLEAN;               -- リターンステータス
    /* 2009.05.14 K.Satomura T1_0931対応 START */
    ln_array_count            NUMBER;
    /* 2009.05.14 K.Satomura T1_0931対応 END */
--
    lv_tmp                    VARCHAR2(2000);
    ln_pos                    NUMBER;
    ln_cnt                    NUMBER := 1;
    lb_format_flag            BOOLEAN := TRUE;
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- 項目数を取得
    IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := iv_base_value;
      LOOP
        ln_pos := INSTR(lv_tmp, cv_comma);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.項目数チェック
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_base_val              -- トークンコード1
                       ,iv_token_value1 => iv_base_value                -- トークン値1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
--
    -- 2.データ型（半角数字／日付）のチェック、サイズチェック
    ELSE
--
     -- 共通関数によって分割した項目データテーブルの取得
     FOR i IN 1..cn_format_col_cnt LOOP
       l_col_data_tab(i) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, i), '"');
     END LOOP;
--
      lb_return  := TRUE;
      lv_item_nm := '';
--
      -- 1). NUMBER型チェック
      IF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff1_num)) = FALSE) THEN
        -- 拡販活動
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff1_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff2_num)) = FALSE) THEN
        -- 販促フォロー
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff2_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff3_num)) = FALSE) THEN
        -- 店頭調査
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff3_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff4_num)) = FALSE) THEN
        -- クレーム対応
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff4_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff5_num)) = FALSE) THEN
        -- 売り場支援
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff5_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff6_num)) = FALSE) THEN
        -- 導入チェック（お茶）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff6_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff7_num)) = FALSE) THEN
        -- 導入チェック（野菜）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff7_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff8_num)) = FALSE) THEN
        -- 導入チェック（その他）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff8_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff9_num)) = FALSE) THEN
        -- 導入チェック（リーフ）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff9_nm;
      ELSIF (xxccp_common_pkg.chk_number(l_col_data_tab(g_csv_order_rec.dff10_num)) = FALSE) THEN
        -- 導入チェック（チルド）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff10_nm;
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 2). 日付書式チェック
      -- 訪問日時
       /* 2010.02.15 T.Maruyama E_本稼動_01130対応 START */
      --lv_visit_date := l_col_data_tab(cn_visit_ymd) || ' ' || l_col_data_tab(cn_visit_time);
      lv_visit_date := REPLACE(l_col_data_tab(cn_visit_ymd), '-', '/') || ' ' || l_col_data_tab(cn_visit_time);
       /* 2010.02.15 T.Maruyama E_本稼動_01130対応 END */
      lb_return := xxcso_util_common_pkg.check_date(lv_visit_date, cv_visit_date_fmt);
      IF (lb_return = FALSE) THEN
        lv_item_nm := cv_visit_nm;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 3). サイズチェック
      IF ((l_col_data_tab(cn_employee_number) IS NULL)
          OR (LENGTHB(l_col_data_tab(cn_employee_number)) <> cn_employee_number_len)) THEN
        -- 社員コード
        lb_return  := FALSE;
        lv_item_nm := cv_employee_number_nm;
      ELSIF (LENGTHB(l_col_data_tab(cn_account_number)) <> cn_account_number_len) THEN
        -- 顧客コード(NULL 可能)
        lb_return  := FALSE;
        lv_item_nm := cv_account_number_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff1_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_activity_kubun_len)) THEN
        -- 拡販活動
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff1_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff2_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_activity_kubun_len)) THEN
        -- 販促フォロー
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff2_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff3_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_activity_kubun_len)) THEN
        -- 店頭調査
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff3_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff4_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_activity_kubun_len)) THEN
        -- クレーム対応
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff4_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff5_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_activity_kubun_len)) THEN
        -- 売り場支援
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff5_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff6_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_activity_kubun_len)) THEN
        -- 導入チェック（お茶）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff6_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff7_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_activity_kubun_len)) THEN
        -- 導入チェック（野菜）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff7_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff8_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_activity_kubun_len)) THEN
        -- 導入チェック（その他）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff8_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff9_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_activity_kubun_len)) THEN
        -- 導入チェック（リーフ）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff9_nm;
      ELSIF ((l_col_data_tab(g_csv_order_rec.dff10_num) IS NULL)
             OR (LENGTHB(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_activity_kubun_len)) THEN
        -- 導入チェック（チルド）
        lb_return  := FALSE;
        lv_item_nm := cv_visit_dff10_nm;
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                  -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
    END IF;
--
    -- 行単位データをレコードにセット
    g_visit_data_rec.employee_number := l_col_data_tab(cn_employee_number);             -- 社員コード
    g_visit_data_rec.account_number  := l_col_data_tab(cn_account_number);              -- 顧客コード
    g_visit_data_rec.visit_date      := TO_DATE(lv_visit_date, cv_visit_date_fmt);      -- 訪問日時
    g_visit_data_rec.description  := SUBSTRB(l_col_data_tab(cn_description), 1, cn_description_cut_len); -- 詳細内容
    /* 2009.05.14 K.Satomura T1_0931対応 START */
    -- 拡販活動
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff1_cd := g_csv_order_rec.dff1_cd;
    --END IF;
    ---- 販促フォロー
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff2_cd := g_csv_order_rec.dff2_cd;
    --END IF;
    ---- 店頭調査
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff3_cd := g_csv_order_rec.dff3_cd;
    --END IF;
    ---- クレーム対応
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff4_cd := g_csv_order_rec.dff4_cd;
    --END IF;
    ---- 売り場支援
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff5_cd := g_csv_order_rec.dff5_cd;
    --END IF;
    ---- 導入チェック（お茶）
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff6_cd := g_csv_order_rec.dff6_cd;
    --END IF;
    ---- 導入チェック（野菜）
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff7_cd := g_csv_order_rec.dff7_cd;
    --END IF;
    ---- 導入チェック（その他）
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff8_cd := g_csv_order_rec.dff8_cd;
    --END IF;
    ---- 導入チェック（リーフ）
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff9_cd := g_csv_order_rec.dff9_cd;
    --END IF;
    ---- 導入チェック（チルド）
    --IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_visit_dff_0) THEN
    --  g_visit_data_rec.dff10_cd := g_csv_order_rec.dff10_cd;
    --END IF;
    ln_array_count := 1;
    g_visit_data_rec.dff_cd_table := g_dff_cd_array();
    g_visit_data_rec.dff_cd_table.EXTEND(10);
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff1_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff1_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff2_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff2_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff3_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff3_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff4_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff4_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff5_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff5_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff6_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff6_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff7_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff7_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff8_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff8_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff9_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff9_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    IF (TO_NUMBER(l_col_data_tab(g_csv_order_rec.dff10_num)) <> cn_visit_dff_0) THEN
      g_visit_data_rec.dff_cd_table(ln_array_count) := g_csv_order_rec.dff10_cd;
      ln_array_count                                := ln_array_count + 1;
      --
    END IF;
    --
    /* 2009.05.14 K.Satomura T1_0931対応 END */
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : マスタ存在チェック (A-6)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     iv_base_value       IN  VARCHAR2         -- 当該行データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_get_process                CONSTANT VARCHAR2(100) := '抽出';
    cv_resource_table_vl_nm       CONSTANT VARCHAR2(100) := 'リソースマスタビュー';
    cv_account_table_vl_nm        CONSTANT VARCHAR2(100) := '顧客マスタビュー';
    cv_employee_number_nm         CONSTANT VARCHAR2(100) := '社員コード';
    cv_account_number_nm          CONSTANT VARCHAR2(100) := '顧客コード';
    cv_false                      CONSTANT VARCHAR2(100) := 'FALSE';
    cv_cust_class_code_cust       CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '10'; -- 顧客区分＝顧客
    cv_cust_class_code_cyclic     CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '15'; -- 顧客区分＝巡回
    cv_cust_class_code_tonya      CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '16'; -- 顧客区分＝問屋帳合先
    cv_cust_status_mc_candidate   CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '10'; -- 顧客ステータス＝ＭＣ候補
    cv_cust_status_mc             CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '20'; -- 顧客ステータス＝ＭＣ
    cv_cust_status_sp_decision    CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '25'; -- 顧客ステータス＝ＳＰ決裁済
    cv_cust_status_approved       CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '30'; -- 顧客ステータス＝承認済
    cv_cust_status_customer       CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '40'; -- 顧客ステータス＝顧客
    cv_cust_status_break          CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '50'; -- 顧客ステータス＝休止
    cv_cust_status_abort_approved CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '90'; -- 顧客ステータス＝中止決裁済
    cv_cust_status_not_applicable CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '99'; -- 顧客ステータス＝対象外
    -- *** ローカル変数 ***
    lv_gl_period_statuses     VARCHAR2(100); -- 「訪問日時」に該当する対象の会計期間がクローズ
    ld_visite_date            DATE;          -- 訪問日時
    -- メッセージ出力用
    lv_msg                         VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. 社員コードのマスタ存在チェック *** --
--
    ld_visite_date := TRUNC(g_visit_data_rec.visit_date);
--
    BEGIN
      -- *** リソースマスタビューからリソースIDを抽出 *** --
      SELECT xrv.resource_id resource_id                                -- リソースID
      INTO   g_visit_data_rec.resource_id
      FROM   xxcso_resources_v xrv
      WHERE  xrv.employee_number = g_visit_data_rec.employee_number
        AND ld_visite_date
          BETWEEN TRUNC(xrv.employee_start_date) AND TRUNC(NVL(xrv.employee_end_date, ld_visite_date))
        AND ld_visite_date
          BETWEEN TRUNC(xrv.resource_start_date) AND TRUNC(NVL(xrv.resource_end_date, ld_visite_date))
        AND ld_visite_date
          BETWEEN TRUNC(xrv.assign_start_date) AND TRUNC(NVL(xrv.assign_end_date, ld_visite_date))
        AND ld_visite_date
          BETWEEN TRUNC(xrv.start_date) AND TRUNC(NVL(xrv.end_date, ld_visite_date));
--
    EXCEPTION
      -- 抽出件数が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_resource_table_vl_nm      -- トークン値1
                       ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
                       ,iv_token_value2 => cv_employee_number_nm        -- トークン値2
                       ,iv_token_name3  => cv_tkn_base_val              -- トークンコード3
                       ,iv_token_value3 => iv_base_value                -- トークン値3
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_resource_table_vl_nm      -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                       ,iv_token_name3  => cv_tkn_process               -- トークンコード3
                       ,iv_token_value3 => cv_get_process               -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg               -- トークンコード4
                       ,iv_token_value4 => SQLERRM                      -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
     -- *** 2. 顧客コードのマスタ存在チェック *** --
    BEGIN
--
      -- *** 1. パーティID、パーティ名称と顧客ステータスを抽出 *** --
      SELECT xcav.party_id                                              -- パーティID
            ,xcav.party_name                                            -- パーティ名称
            ,xcav.customer_status                                       -- 顧客ステータス
      INTO   g_visit_data_rec.party_id
            ,g_visit_data_rec.party_name
            ,g_visit_data_rec.customer_status
      FROM   xxcso_cust_accounts_v xcav
      WHERE  xcav.account_number = g_visit_data_rec.account_number
      AND    ((
                 /* 2009.05.28 K.Satomura T1_0137対応 START */
                 --xcav.customer_class_code = cv_cust_class_code_cust
                 NVL(xcav.customer_class_code, cv_cust_class_code_cust) = cv_cust_class_code_cust
                 /* 2009.05.28 K.Satomura T1_0137対応 START */
             AND xcav.customer_status IN (cv_cust_status_mc_candidate, cv_cust_status_mc, cv_cust_status_sp_decision,
                                          cv_cust_status_approved, cv_cust_status_customer, cv_cust_status_break)
             )
      OR     (
                 xcav.customer_class_code IN (cv_cust_class_code_cyclic, cv_cust_class_code_tonya)
             AND xcav.customer_status IN (cv_cust_status_abort_approved, cv_cust_status_not_applicable)
             ))
      ;
--
    EXCEPTION
      -- 抽出件数が0件の場合
      WHEN NO_DATA_FOUND THEN
--
        /* 2009.07.16 K.Satomura 0000070対応 START */
        -- ダミー顧客コードから取得したパーティID、パーティ名称と顧客ステータスをセット
        --g_visit_data_rec.party_id := gt_party_id;
        --g_visit_data_rec.party_name := gt_party_name;
        --g_visit_data_rec.customer_status := gt_customer_status;
--
        --lv_msg := xxccp_common_pkg.get_msg(
        --                iv_application  => cv_app_name                  -- アプリケーション短縮名
        --               ,iv_name         => cv_tkn_number_15             -- メッセージコード
        --               ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
        --               ,iv_token_value1 => cv_account_table_vl_nm       -- トークン値1
        --               ,iv_token_name2  => cv_tkn_item                  -- トークンコード2
        --               ,iv_token_value2 => cv_account_number_nm         -- トークン値2
        --               ,iv_token_name3  => cv_tkn_base_val              -- トークンコード3
        --               ,iv_token_value3 => iv_base_value                -- トークン値3
        --             );
        --lv_errbuf := lv_msg;
--
        -- メッセージを出力
        --fnd_file.put_line(
        --   which  => FND_FILE.OUTPUT
        --  ,buff   => lv_msg
        --);
--
        -- ログ出力
        --fnd_file.put_line(
        --   which  => FND_FILE.LOG
        --  ,buff   => lv_errbuf 
        --);
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item            -- トークンコード1
                       ,iv_token_value1 => cv_account_number_nm   -- トークン値1
                       ,iv_token_name2  => cv_tkn_tbl             -- トークンコード2
                       ,iv_token_value2 => cv_account_table_vl_nm -- トークン値2
                       ,iv_token_name3  => cv_tkn_base_val        -- トークンコード3
                       ,iv_token_value3 => iv_base_value          -- トークン値3
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
        --
        /* 2009.07.16 K.Satomura 0000070対応 END */
      -- 抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_account_table_vl_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                       ,iv_token_name3  => cv_tkn_process               -- トークンコード3
                       ,iv_token_value3 => cv_get_process               -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg               -- トークンコード4
                       ,iv_token_value4 => SQLERRM                      -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    -- *** 3. 「訪問日時」に該当する対象の会計期間がクローズされているかをチェック *** --
    -- 会計期間チェック関数を使用
      lv_gl_period_statuses := xxcso_util_common_pkg.check_ar_gl_period_status(g_visit_data_rec.visit_date);
--
    -- チェック関数のリターン値が'FALSE'(クローズされている)の場合
    IF lv_gl_period_statuses = cv_false THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_base_val              -- トークンコード1
                     ,iv_token_value1 => iv_base_value                -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_same_data
   * Description      : 同一訪問実績データ抽出 (A-7)
   ***********************************************************************************/
--
  PROCEDURE get_visit_same_data(
     on_task_id               OUT NOCOPY NUMBER               -- タスクＩＤ
    ,on_obj_ver_num           OUT NOCOPY NUMBER               -- オブジェクトバージョン番号
    ,on_task_count            OUT NOCOPY NUMBER               -- 抽出件数
    ,iv_base_value            IN  VARCHAR2                    -- 当該行データ
    ,ov_errbuf                OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_same_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_get_process       CONSTANT VARCHAR2(100) := '抽出';
    cv_task_table_nm     CONSTANT VARCHAR2(100) := 'タスクテーブル';
    cv_code_employee     CONSTANT VARCHAR2(100) := 'RS_EMPLOYEE';
    cv_code_party        CONSTANT VARCHAR2(100) := 'PARTY';
    cv_deleted_flag_n    CONSTANT VARCHAR2(100) := 'N';
    /* 2009.07.16 K.Satomura 0000070対応 START */
    cv_task_close        CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_CLOSED_ID';
    cv_visit_date_fmt1   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI';
    cv_visit_date_fmt2   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
    cd_sysdate           CONSTANT DATE          := TO_DATE(TO_CHAR(SYSDATE, cv_visit_date_fmt1), cv_visit_date_fmt2);
    /* 2009.07.16 K.Satomura 0000070対応 END */
    -- *** ローカル・カーソル ***
    CURSOR l_task_cur
    IS
      SELECT task.task_id task_id                                               -- タスクID
            ,task.object_version_number obj_ver_num                             -- オブジェクトバージョン番号
      FROM   jtf_tasks_b task
      WHERE  task.owner_id = g_visit_data_rec.resource_id
        AND  task.owner_type_code = cv_code_employee
        AND  task.source_object_id = g_visit_data_rec.party_id
        AND  task.source_object_type_code = cv_code_party
        AND  task.actual_end_date = g_visit_data_rec.visit_date
        AND  task.deleted_flag = cv_deleted_flag_n
      ORDER BY task.last_update_date DESC
      FOR UPDATE NOWAIT;
    -- *** ローカル・レコード *** 
    l_task_rec l_task_cur%ROWTYPE;
--
    /* 2009.07.16 K.Satomura 0000070対応 START */
    CURSOR l_task_cur2
    IS
      SELECT task.task_id task_id                   -- タスクID
            ,task.object_version_number obj_ver_num -- オブジェクトバージョン番号
      FROM   jtf_tasks_b task
      WHERE  task.owner_id                = g_visit_data_rec.resource_id
      AND    task.owner_type_code         = cv_code_employee
      AND    task.source_object_id        = g_visit_data_rec.party_id
      AND    task.source_object_type_code = cv_code_party
      AND    task.actual_end_date         = g_visit_data_rec.visit_date
      AND    task.deleted_flag            = cv_deleted_flag_n
      AND    task.task_status_id          = TO_NUMBER(fnd_profile.value(cv_task_close))
      ORDER BY task.last_update_date DESC
      FOR UPDATE NOWAIT;
    /* 2009.07.16 K.Satomura 0000070対応 END */
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. タスクテーブルからタスクIDとオブジェクトバージョン番号を取得 *** --
    BEGIN
--
      -- 抽出件数
      on_task_count := 0;
      -- カーソルオープン
      /* 2009.07.16 K.Satomura 0000070対応 START */
      IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        -- 訪問日時が未来日付の場合
      /* 2009.07.16 K.Satomura 0000070対応 END */
        OPEN l_task_cur;
      /* 2009.07.16 K.Satomura 0000070対応 START */
      ELSE
        -- 訪問日時が現在日時を含む過去日付の場合
        OPEN l_task_cur2;
        --
      END IF;
      /* 2009.07.16 K.Satomura 0000070対応 END */
--
      <<task_id_loop>>
      LOOP
        /* 2009.07.16 K.Satomura 0000070対応 START */
        IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        /* 2009.07.16 K.Satomura 0000070対応 END */
          FETCH l_task_cur INTO l_task_rec;
        /* 2009.07.16 K.Satomura 0000070対応 START */
        ELSE
          FETCH l_task_cur2 INTO l_task_rec;
          --
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 END */
--
        /* 2009.07.16 K.Satomura 0000070対応 START */
        IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        /* 2009.07.16 K.Satomura 0000070対応 END */
          EXIT WHEN l_task_cur%NOTFOUND OR l_task_cur%ROWCOUNT = 0;
        /* 2009.07.16 K.Satomura 0000070対応 START */
        ELSE
          EXIT WHEN l_task_cur2%NOTFOUND OR l_task_cur2%ROWCOUNT = 0;
          --
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 END */
--
        -- 抽出件数
        /* 2009.07.16 K.Satomura 0000070対応 START */
        IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
        /* 2009.07.16 K.Satomura 0000070対応 END */
          on_task_count := l_task_cur%ROWCOUNT;
        /* 2009.07.16 K.Satomura 0000070対応 START */
        ELSE
          on_task_count := l_task_cur2%ROWCOUNT;
          --
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 END */
        -- タスクID
        on_task_id    := l_task_rec.task_id;
        -- オブジェクトバージョン番号
        on_obj_ver_num := l_task_rec.obj_ver_num;
--
        EXIT;
      END LOOP task_id_loop;
--
      -- カーソル・クローズ
      /* 2009.07.16 K.Satomura 0000070対応 START */
      IF (g_visit_data_rec.visit_date > cd_sysdate) THEN
      /* 2009.07.16 K.Satomura 0000070対応 END */
        CLOSE l_task_cur;
      /* 2009.07.16 K.Satomura 0000070対応 START */
      ELSE
        CLOSE l_task_cur2;
        --
      END IF;
      /* 2009.07.16 K.Satomura 0000070対応 END */
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        -- カーソル・クローズ
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 START */
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 END */
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                         -- トークンコード1
                       ,iv_token_value1 => cv_task_table_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val                    -- トークンコード2
                       ,iv_token_value2 => iv_base_value                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_skip_error_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        -- カーソル・クローズ
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 START */
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        /* 2009.07.16 K.Satomura 0000070対応 END */
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_task_table_nm             -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                       ,iv_token_value2 => iv_base_value                -- トークン値2
                       ,iv_token_name3  => cv_tkn_process               -- トークンコード3
                       ,iv_token_value3 => cv_get_process               -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg               -- トークンコード4
                       ,iv_token_value4 => SQLERRM                      -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    /* 2009.07.16 K.Satomura 0000070対応 START */
    IF ((g_visit_data_rec.visit_date <= cd_sysdate)
      AND on_task_count > 0)
    THEN
      -- 訪問日時が現在を含む過去日付でタスクが存在した場合はスキップ。
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_21 -- メッセージコード
                     ,iv_token_name1  => cv_tkn_base_val  -- トークンコード1
                     ,iv_token_value1 => iv_base_value    -- トークン値1
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
      --
    END IF;
    /* 2009.07.16 K.Satomura 0000070対応 END */
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_visit_same_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_visit_data
   * Description      : 訪問実績データ登録 (A-8)
   ***********************************************************************************/
--
  PROCEDURE insert_visit_data(
     iv_base_value        IN  VARCHAR2                    -- 当該行データ
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_insert_process    CONSTANT VARCHAR2(100) := '登録';
    cv_task_table_nm     CONSTANT VARCHAR2(100) := 'タスクテーブル';
    /* 2009.07.16 K.Satomura 0000070対応 START */
    ct_task_status_open  CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_OPEN_ID'; 
    cv_visit_date_fmt1   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI';
    cv_visit_date_fmt2   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
    /* 2009.07.16 K.Satomura 0000070対応 END */
    -- *** ローカル変数 ***
    ln_task_id         NUMBER;            -- タスクID
    /* 2009.07.16 K.Satomura 0000070対応 START */
    lt_task_status_id  jtf_task_statuses_b.task_status_id%TYPE; -- タスクステータスＩＤ
    /* 2009.07.16 K.Satomura 0000070対応 END */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 訪問実績データ登録 
    -- =======================
    /* 2009.07.16 K.Satomura 0000070対応 START */
    IF (g_visit_data_rec.visit_date > TO_DATE(TO_CHAR(SYSDATE, cv_visit_date_fmt1), cv_visit_date_fmt2)) THEN
      -- 訪問日時が未来の場合は、タスクステータスはオープンで登録する。
      lt_task_status_id := TO_NUMBER(fnd_profile.value(ct_task_status_open));
      --
    ELSE
      lt_task_status_id := NULL;
      --
    END IF;
    --
    /* 2009.07.16 K.Satomura 0000070対応 END */
    xxcso_task_common_pkg.create_task(
       g_visit_data_rec.resource_id        -- リソースID
      ,g_visit_data_rec.party_id           -- パーティID
      ,g_visit_data_rec.party_name         -- パーティ名称
      ,g_visit_data_rec.visit_date         -- 訪問日時
      ,g_visit_data_rec.description        -- 詳細内容
      /* 2009.07.16 K.Satomura 0000070対応 START */
      ,lt_task_status_id                   -- タスクステータスＩＤ
      /* 2009.07.16 K.Satomura 0000070対応 END */
      /* 2009.05.14 K.Satomura T1_0931対応 START */
      --,g_visit_data_rec.dff1_cd            -- 拡販活動
      --,g_visit_data_rec.dff2_cd            -- 販促フォロー
      --,g_visit_data_rec.dff3_cd            -- 店頭調査
      --,g_visit_data_rec.dff4_cd            -- クレーム対応
      --,g_visit_data_rec.dff5_cd            -- 売り場支援
      --,g_visit_data_rec.dff6_cd            -- 導入チェック（お茶）
      --,g_visit_data_rec.dff7_cd            -- 導入チェック（野菜）
      --,g_visit_data_rec.dff8_cd            -- 導入チェック（その他）
      --,g_visit_data_rec.dff9_cd            -- 導入チェック（リーフ）
      --,g_visit_data_rec.dff10_cd           -- 導入チェック（チルド）
      ,g_visit_data_rec.dff_cd_table(1)      -- 拡販活動
      ,g_visit_data_rec.dff_cd_table(2)      -- 販促フォロー
      ,g_visit_data_rec.dff_cd_table(3)      -- 店頭調査
      ,g_visit_data_rec.dff_cd_table(4)      -- クレーム対応
      ,g_visit_data_rec.dff_cd_table(5)      -- 売り場支援
      ,g_visit_data_rec.dff_cd_table(6)      -- 導入チェック（お茶）
      ,g_visit_data_rec.dff_cd_table(7)      -- 導入チェック（野菜）
      ,g_visit_data_rec.dff_cd_table(8)      -- 導入チェック（その他）
      ,g_visit_data_rec.dff_cd_table(9)      -- 導入チェック（リーフ）
      ,g_visit_data_rec.dff_cd_table(10)     -- 導入チェック（チルド）
      /* 2009.05.14 K.Satomura T1_0931対応 END */
      ,'0'
      ,'2'
      ,NULL
      /* 2009.09.08 D.Abe 0001312対応 START */
      --,gt_customer_status
      ,g_visit_data_rec.customer_status
      /* 2009.09.08 D.Abe 0001312対応 END */
      ,ln_task_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    -- 正常ではない場合
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_11             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                     ,iv_token_value1 => cv_task_table_nm             -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                     ,iv_token_value2 => iv_base_value                -- トークン値2
                     ,iv_token_name3  => cv_tkn_process               -- トークンコード3
                     ,iv_token_value3 => cv_insert_process            -- トークン値3
                     ,iv_token_name4  => cv_tkn_err_msg               -- トークンコード4
                     ,iv_token_value4 => lv_errmsg                    -- トークン値4
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : update_visit_data
   * Description      : 訪問実績データ更新 (A-9)
   ***********************************************************************************/
--
  PROCEDURE update_visit_data(
     in_task_id           IN  NUMBER                      -- タスクＩＤ
    ,in_obj_ver_num       IN  NUMBER                      -- オブジェクトバージョン番号
    ,iv_base_value        IN  VARCHAR2                    -- 当該行データ
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'update_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_update_process    CONSTANT VARCHAR2(100) := '更新';
    cv_task_table_nm     CONSTANT VARCHAR2(100) := 'タスクテーブル';
    /* 2009.07.16 K.Satomura 0000070対応 START */
    ct_task_status_open  CONSTANT VARCHAR2(100) := 'XXCSO1_TASK_STATUS_OPEN_ID'; 
    cv_visit_date_fmt1   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI';
    cv_visit_date_fmt2   CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
    /* 2009.07.16 K.Satomura 0000070対応 END */
    --
    -- *** ローカル変数 ***
    /* 2009.07.16 K.Satomura 0000070対応 START */
    lt_task_status_id jtf_task_statuses_b.task_status_id%TYPE; -- タスクステータスＩＤ
    /* 2009.07.16 K.Satomura 0000070対応 END */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    /* 2009.07.16 K.Satomura 0000070対応 START */
    IF (g_visit_data_rec.visit_date > TO_DATE(TO_CHAR(SYSDATE, cv_visit_date_fmt1), cv_visit_date_fmt2)) THEN
      -- 訪問日時が未来の場合は、タスクステータスはオープンで登録する。
      lt_task_status_id := TO_NUMBER(fnd_profile.value(ct_task_status_open));
      --
    ELSE
      lt_task_status_id := NULL;
      --
    END IF;
    --
    /* 2009.07.16 K.Satomura 0000070対応 END */
    -- =======================
    -- 訪問実績データ更新 
    -- =======================
    xxcso_task_common_pkg.update_task(
       in_task_id                         -- タスクID
      ,g_visit_data_rec.resource_id       -- リソースID
      ,g_visit_data_rec.party_id          -- パーティID
      ,g_visit_data_rec.party_name        -- パーティ名称
      ,g_visit_data_rec.visit_date        -- 訪問日時
      ,g_visit_data_rec.description       -- 詳細内容
      ,in_obj_ver_num
      /* 2009.07.16 K.Satomura 0000070対応 START */
      ,lt_task_status_id                   -- タスクステータスＩＤ
      /* 2009.07.16 K.Satomura 0000070対応 END */
      /* 2009.05.14 K.Satomura T1_0931対応 START */
      --,g_visit_data_rec.dff1_cd            -- 拡販活動
      --,g_visit_data_rec.dff2_cd            -- 販促フォロー
      --,g_visit_data_rec.dff3_cd            -- 店頭調査
      --,g_visit_data_rec.dff4_cd            -- クレーム対応
      --,g_visit_data_rec.dff5_cd            -- 売り場支援
      --,g_visit_data_rec.dff6_cd            -- 導入チェック（お茶）
      --,g_visit_data_rec.dff7_cd            -- 導入チェック（野菜）
      --,g_visit_data_rec.dff8_cd            -- 導入チェック（その他）
      --,g_visit_data_rec.dff9_cd            -- 導入チェック（リーフ）
      --,g_visit_data_rec.dff10_cd           -- 導入チェック（チルド）
      ,g_visit_data_rec.dff_cd_table(1)      -- 拡販活動
      ,g_visit_data_rec.dff_cd_table(2)      -- 販促フォロー
      ,g_visit_data_rec.dff_cd_table(3)      -- 店頭調査
      ,g_visit_data_rec.dff_cd_table(4)      -- クレーム対応
      ,g_visit_data_rec.dff_cd_table(5)      -- 売り場支援
      ,g_visit_data_rec.dff_cd_table(6)      -- 導入チェック（お茶）
      ,g_visit_data_rec.dff_cd_table(7)      -- 導入チェック（野菜）
      ,g_visit_data_rec.dff_cd_table(8)      -- 導入チェック（その他）
      ,g_visit_data_rec.dff_cd_table(9)      -- 導入チェック（リーフ）
      ,g_visit_data_rec.dff_cd_table(10)     -- 導入チェック（チルド）
      /* 2009.05.14 K.Satomura T1_0931対応 END */
      ,'0'
      ,'2'
      ,NULL
/* 2009.09.08 D.Abe 0001312対応 START */
      --,gt_customer_status
      ,g_visit_data_rec.customer_status
/* 2009.09.08 D.Abe 0001312対応 END */
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    -- 正常ではない場合
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_11             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                     ,iv_token_value1 => cv_task_table_nm             -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_val              -- トークンコード2
                     ,iv_token_value2 => iv_base_value                -- トークン値2
                     ,iv_token_name3  => cv_tkn_process               -- トークンコード3
                     ,iv_token_value3 => cv_update_process            -- トークン値3
                     ,iv_token_name4  => cv_tkn_err_msg               -- トークンコード4
                     ,iv_token_value4 => lv_errmsg                    -- トークン値4
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : ファイルデータ削除処理 (A-11)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      -- ファイルデータ削除
      DELETE FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id;
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || cv_debug_msg19 || CHR(10) || cv_debug_msg15 || CHR(10)
      );
--
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                         -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm                     -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id                     -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード2
                       ,iv_token_value3 => SQLERRM                            -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;                                                    -- # 任意 #
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_visit_data_start     CONSTANT NUMBER := 3;   -- 3件目から実際の訪問実績データ
--
    -- *** ローカル変数 ***
    lv_base_value           VARCHAR2(5000);         -- 当該行データ
    lv_dummy_acc_num        VARCHAR2(30);           -- ダミー顧客コード
    ln_task_id              NUMBER;                 -- タスクＩＤ
    ln_obj_ver_num          NUMBER;                 -- オブジェクトバージョン番号
    ln_task_count           NUMBER;                 -- 抽出件数
--
    -- *** ローカル例外 ***
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
       ov_errbuf  => lv_errbuf           -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              -- # 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.プロファイル値取得 
    -- ========================================
    get_profile_info(
       ov_dummy_acc_num => lv_dummy_acc_num -- ダミー顧客コード
      ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.訪問実績データ抽出処理 
    -- ========================================
    get_visit_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-3で抽出したファイルデータサイズが4件以上の場合
    IF (g_file_data_tab.COUNT >= (cn_visit_data_start + 1)) THEN
      -- ==================================================
      -- A-4.登録（A-8）、更新（A-9）処理で必要なデータ取得 
      -- ==================================================
      get_inupd_data(
         iv_dummy_acc_num => lv_dummy_acc_num -- ダミー顧客コード
        ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
        ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
        ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ファイルデータループ(最後の行は合計のため「最後の行-1」まで)
      <<get_visit_data_loop>>
      FOR i IN cn_visit_data_start..(g_file_data_tab.COUNT - 1) LOOP
--
        BEGIN
--
          -- レコードクリア
          g_visit_data_rec := NULL;
--
          -- 対象件数カウント
          gn_target_cnt := gn_target_cnt + 1;
--
          lv_base_value := g_file_data_tab(i);
--
          -- =================================================
          -- A-5.データ妥当性チェック (レコードにデータセット)
          -- =================================================
          data_proper_check(
             iv_base_value    => lv_base_value    -- 当該行データ
            ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- =============================
          -- A-6.マスタ存在チェック 
          -- =============================
          chk_mst_is_exists(
             iv_base_value    => lv_base_value    -- 当該行データ
            ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- =============================
          -- A-7.同一訪問実績データ抽出 
          -- =============================
          -- 抽出件数をクリア
          ln_task_count := 0;
--
          get_visit_same_data(
             on_task_id       => ln_task_id       -- タスクＩＤ
            ,on_obj_ver_num   => ln_obj_ver_num   -- オブジェクトバージョン番号
            ,on_task_count    => ln_task_count    -- 抽出件数
            ,iv_base_value    => lv_base_value    -- 当該行データ
            ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- A-10.SAVEPOINT発行
          SAVEPOINT visit;
--
          IF (ln_task_count = 0) THEN
            -- =============================
            -- A-8.訪問実績データ登録 
            -- =============================
            insert_visit_data(
               iv_base_value    => lv_base_value    -- 当該行データ
              ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
              ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_skip_error_expt;
            END IF;
          ELSE
            -- =============================
            -- A-9.訪問実績データ更新 
            -- =============================
            update_visit_data(
               in_task_id       => ln_task_id       -- タスクＩＤ
              ,in_obj_ver_num   => ln_obj_ver_num   -- オブジェクトバージョン番号
              ,iv_base_value    => lv_base_value    -- 当該行データ
              ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
              ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              gb_task_inup_rollback_flag := TRUE;
              RAISE global_skip_error_expt;
            END IF;
          END IF;
          -- 成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** スキップ例外ハンドラ ***
          WHEN global_skip_error_expt THEN
            gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
            lv_retcode := cv_status_warn;
--
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_errbuf                  -- エラーメッセージ
            );
--
            -- ロールバック
            IF gb_task_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK
              gb_task_inup_rollback_flag := FALSE;
              -- ログ出力
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
              );
            END IF;
--        
          -- *** スキップ例外OTHERSハンドラ ***
          WHEN OTHERS THEN
            gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
            lv_retcode := cv_status_warn;
--
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_errbuf                  -- エラーメッセージ
            );
--
            -- ロールバック
            IF gb_task_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT visit;          -- ROLLBACK
              gb_task_inup_rollback_flag := FALSE;
              -- ログ出力
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
              );
            END IF;
--
          END;
      END LOOP get_visit_data_loop;
--
      ov_retcode := lv_retcode;                -- リターン・コード
    END IF;
--
    -- =============================
    -- A-11.ファイルデータ削除処理 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- エラー・メッセージ  -- # 固定 #
    ,retcode       OUT NOCOPY VARCHAR2          -- リターン・コード    -- # 固定 #
    ,in_file_id    IN         NUMBER            -- ファイルID
    ,iv_fmt_ptn    IN         VARCHAR2          -- フォーマットパターン
  )    
--
-- ###########################  固定部 START   ###########################
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
-- ###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  固定部 END   #############################
--
    -- *** 入力パラメータをセット
    gt_file_id := in_file_id;
    gv_fmt_ptn := iv_fmt_ptn;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf    -- エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-12.終了処理 
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''               -- 空行
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージ
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCSO006A02C;
/
