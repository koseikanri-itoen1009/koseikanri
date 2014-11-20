CREATE OR REPLACE PACKAGE BODY XXCSO020A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A06C(body)
 * Description      : EBS(ファイルアップロードI/F)に取込まれたSP専決WF承認組織
 *                    マスタデータをWF承認組織マスタテーブルに取込みます。
 *
 * MD.050           : MD050_CSO_020_A06_SP-WF承認組織マスタ情報一括取込
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                                        (A-1)
 *  get_dcsn_wf_org_data        WF承認組織マスタデータ抽出処理                  (A-2)
 *  data_proper_check           データ妥当性チェック                            (A-3)
 *  chk_mst_is_exists           マスタ存在チェック                              (A-4)
 *  chk_mst_effective_date      同一拠点CDで有効期間が重複する
 *                              データ存在チェック処理(登録用)                  (A-5)
 *  insert_dcsn_wf_org_data     WF承認組織マスタデータ登録                      (A-6)
 *  chk_dcsn_wf_org_exists      WF承認組織マスタデータ存在チェック              (A-7)
 *  chk_mst_effective_date_2    同一拠点CDで有効期間が重複する
 *                              データ存在チェック処理(更新用)                  (A-8)
 *  update_dcsn_wf_org_data     WF承認組織マスタデータ更新                      (A-9)
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
 *  2008-01-06    1.0   Maruyama.Mio     新規作成
 *  2008-01-16    1.0   Maruyama.Mio     レビュー結果反映
 *  2008-01-21    1.0   Maruyama.Mio     更新時WHOカラム修正(作成者・作成日削除),
 *                                       更新区分NULLチェック追加
 *  2008-01-30    1.0   Maruyama.Mio     INパラメータファイルID変数名変更(記述ルール参考)
 *  2008-02-25    1.1   Maruyama.Mio     【障害対応028】有効期間重複チェック不具合対応
 *
 *****************************************************************************************/
-- 
-- #######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO020A06C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- 有効
--
  -- 更新区分デフォルト値
  cv_value_kubun_val_1   CONSTANT VARCHAR2(100) := '1';  -- 更新区分許容値１
  cv_value_kubun_val_2   CONSTANT VARCHAR2(100) := '2';  -- 更新区分許容値２

  -- メッセージコード
  
  -- 初期処理エラー
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00256';  -- パラメータNULLエラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ロックエラー
  -- データ処理エラー（ファイルアップロードI/Fテーブル）
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00259';  -- データ抽出エラー(ファイルアップロードI/Fテーブル)
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00178';  -- データ登録エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00179';  -- データ更新エラー
  -- データチェックエラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00180';  -- WF承認組織マスタデータフォーマットチェックエラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00181';  -- 必須チェックエラー
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00317';  -- 半角英数チェックエラー
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00183';  -- サイズチェックエラー
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00184';  -- DATE型チェックエラー
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00185';  -- 有効開始日・終了日大小チェックエラー
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00186';  -- 更新区分チェックエラー
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00187';  -- マスタチェックエラー
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00188';  -- 更新対象存在チェックエラー
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00189';  -- 有効期間重複エラー
  -- データ削除エラー（ファイルアップロードI/Fテーブル）
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- データ削除エラー
  -- コンカレントパラメータ関連
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- パラメータファイルID
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- パラメータ出力CSVファイル名
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- ファイルアップロード名称抽出エラー
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- パラメータフォーマットパターン
  -- データ抽出エラー
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00497';  -- 事業所マスタデータ抽出エラー
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- SP専決WF承認組織マスタデータ抽出エラー
--
  -- トークンコード
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLMUN';
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_val_kubn        CONSTANT VARCHAR2(20) := 'VALUE_KUBUN';
  cv_tkn_val_start       CONSTANT VARCHAR2(20) := 'VALUE_START';
  cv_tkn_val_end         CONSTANT VARCHAR2(20) := 'VALUE_END';
  cv_tkn_val_loc         CONSTANT VARCHAR2(20) := 'VALUE_LOCATION';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';  
  cv_tkn_loc             CONSTANT VARCHAR2(20) := 'LOCATION';
  cv_tkn_efctv_satrt_dt  CONSTANT VARCHAR2(20) := 'EFFECTIVE_START_DATE';
  cv_tkn_efctv_end_dt    CONSTANT VARCHAR2(20) := 'EFFECTIVE_END_DATE';
  cv_tkn_summary         CONSTANT VARCHAR2(20) := 'SUMMARY';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';

--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg3          CONSTANT VARCHAR2(200) := 'SP専決-WF承認組織マスタデータを抽出しました。';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := 'ファイルデータ削除しました。';
  cv_debug_msg16         CONSTANT VARCHAR2(200) := '<< SP専決-WF承認組織マスタデータ抽出 >>';
  cv_debug_msg19         CONSTANT VARCHAR2(200) := '<< ファイルデータ削除 >>';
  cv_debug_msg22         CONSTANT VARCHAR2(200) := 'ロールバックしました。';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 行単位データを格納する配列
  TYPE g_col_data_ttype  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- マスタデータ存在チェック用拠点コード格納配列
  TYPE g_base_code_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- WF承認組織マスタデータ＆関連情報抽出データ構造体
  TYPE g_dcsn_wf_org_data_rtype IS RECORD(
    update_kubun       VARCHAR2(100),                                     -- 更新区分
    base_code          xxcso_sp_decision_wf_orgs.sends_dept_code1%TYPE,   -- 拠点CD
    effective_st_date  xxcso_sp_decision_wf_orgs.effective_st_date%TYPE,  -- 有効開始日
    effective_ed_date  xxcso_sp_decision_wf_orgs.effective_ed_date%TYPE,  -- 有効終了日
    sends_dept_code1   xxcso_sp_decision_wf_orgs.sends_dept_code1%TYPE,   -- 回送拠点CD1
    sends_dept_code2   xxcso_sp_decision_wf_orgs.sends_dept_code2%TYPE,   -- 回送拠点CD2
    sends_dept_code3   xxcso_sp_decision_wf_orgs.sends_dept_code3%TYPE,   -- 回送拠点CD3
    sends_dept_code4   xxcso_sp_decision_wf_orgs.sends_dept_code4%TYPE,   -- 回送拠点CD4
    sends_dept_code5   xxcso_sp_decision_wf_orgs.sends_dept_code5%TYPE,   -- 回送拠点CD5
    sends_dept_code6   xxcso_sp_decision_wf_orgs.sends_dept_code6%TYPE,   -- 回送拠点CD6
    sends_dept_code7   xxcso_sp_decision_wf_orgs.sends_dept_code7%TYPE,   -- 回送拠点CD7
    sends_dept_code8   xxcso_sp_decision_wf_orgs.sends_dept_code8%TYPE,   -- 回送拠点CD8
    sends_dept_code9   xxcso_sp_decision_wf_orgs.sends_dept_code9%TYPE,   -- 回送拠点CD9
    sends_dept_code10  xxcso_sp_decision_wf_orgs.sends_dept_code10%TYPE,  -- 回送拠点CD10
    excerpt            xxcso_sp_decision_wf_orgs.excerpt%TYPE             -- 摘要
  );
  -- *** ユーザー定義グローバル例外 ***
  global_skip_error_expt EXCEPTION;  -- スキップ例外
  global_lock_expt       EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gt_base_code             g_base_code_ttype;                  -- マスタデータ存在チェック用拠点コード格納変数
--
  g_file_data_tab          xxccp_common_pkg2.g_file_data_tbl;
  g_dcsn_wf_org_data_rec   g_dcsn_wf_org_data_rtype;           -- WF承認組織マスタデータ抽出用レコード
--
  gt_file_id                    xxccp_mrp_file_ul_interface.file_id%TYPE;           -- ファイルID
  gv_fmt_ptn                    VARCHAR2(20);                                       -- フォーマットパターン
  gb_if_del_err_flag            BOOLEAN := FALSE;  -- TRUE : ファイルデータ削除処理実行しない
  gb_wf_org_inup_rollback_flag  BOOLEAN := FALSE;  -- TRUE : ロールバック
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf                  OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode                 OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg                  OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf                   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1);     -- リターン・コード
    lv_errmsg                   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_file_upload_lookup_type  CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_sp_wf_data_lookup_code   CONSTANT VARCHAR2(30)  := '630';
    -- *** ローカル変数 ***
    lv_file_upload_nm           VARCHAR2(30);  -- ファイルアップロード名称
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
    lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_17           -- メッセージコード
                ,iv_token_name1  => cv_tkn_file_id             -- トークンコード1
                ,iv_token_value1 => TO_CHAR(gt_file_id)        -- トークン値1
              );
--
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => '' || CHR(10) || lv_errmsg
    );
    -- ファイルIDログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_errmsg
    );
--
    -- フォーマットパターンメッセージ
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             -- アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_21        -- メッセージコード
                   ,iv_token_name1  => cv_tkn_fmt_ptn          -- トークンコード1
                   ,iv_token_value1 => gv_fmt_ptn              -- トークン値1
                 );
--
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_errmsg || CHR(10)
    );
    -- フォーマットパターンログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_errmsg
    );
--
    -- 入力パラメータファイルIDのNULLチェック
    IF gt_file_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name           -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01      -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      -- TRUE : ファイルデータ削除処理実行しない
      gb_if_del_err_flag := TRUE;
--
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロード名称抽出
    BEGIN
--
      -- 参照タイプテーブルからファイルアップロード名称抽出
      SELECT lvvl.meaning  meaning     -- 内容
      INTO   lv_file_upload_nm         -- ファイルアップロード名称
      FROM   fnd_lookup_values_vl lvvl -- クイックコード
      WHERE  lvvl.lookup_type = cv_file_upload_lookup_type
        AND TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
              AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
        AND lvvl.enabled_flag = cv_enabled_flag
        AND lvvl.lookup_code = cv_sp_wf_data_lookup_code;
--    
      -- ファイルアップロード名称メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name            -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_20       -- メッセージコード
                    ,iv_token_name1  => cv_tkn_file_upload_nm  -- トークンコード1
                    ,iv_token_value1 => lv_file_upload_nm      -- トークン値1
                   );
--
      -- ファイルアップロード名称メッセージ出力
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_errmsg || CHR(10)
      );
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg || CHR(10)
      );
--
    EXCEPTION
      -- ファイルアップロード名称抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_19    -- メッセージコード
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
   * Procedure Name   : get_dcsn_wf_org_data
   * Description      : WF承認組織マスタデータ抽出処理 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_dcsn_wf_org_data(
     ov_errbuf           OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_dcsn_wf_org_data';     -- プログラム名
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
    lt_file_data         xxccp_mrp_file_ul_interface.file_data%TYPE;          -- ファイルデータ
    lt_file_format       xxccp_mrp_file_ul_interface.file_format%TYPE;        -- ファイルフォーマット
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
      SELECT xmfui.file_name          file_name          -- ファイル名
            ,xmfui.file_content_type  file_content_type  -- ファイル区分
            ,xmfui.file_data          file_date          -- ファイルデータ
            ,xmfui.file_format        file_format        -- ファイルフォーマット
      INTO   lt_file_name             -- ファイル名
            ,lt_file_content_type     -- ファイル区分
            ,lt_file_data             -- ファイルデータ
            ,lt_file_format           -- ファイルフォーマット
      FROM   xxccp_mrp_file_ul_interface  xmfui  -- ファイルアップロードI/Fテーブル
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;  -- テーブルロック
      
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg       -- トークンコード2
                       ,iv_token_value2 => SQLERRM              -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード3
                       ,iv_token_value3 => SQLERRM              -- トークン値3
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
                      iv_application  => cv_app_name            -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_03       -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl             -- トークンコード1
                     ,iv_token_value1 => cv_if_table_nm         -- トークン値1
                     ,iv_token_name2  => cv_tkn_file_id         -- トークンコード2
                     ,iv_token_value2 => TO_CHAR(gt_file_id)    -- トークン値2
                     ,iv_token_name3  => cv_tkn_err_msg         -- トークンコード2
                     ,iv_token_value3 => lv_errbuf              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg16 || CHR(10) || cv_debug_msg3 || CHR(10)
    );
--
    -- CSVファイル名メッセージ
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name               -- アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_18          -- メッセージコード
                  ,iv_token_name1  => cv_tkn_csv_file_nm        -- トークンコード1
                  ,iv_token_value1 => lt_file_name              -- トークン値1
                 );
--
    -- CSVファイル名メッセージ出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_errmsg || CHR(10)
    );
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg || CHR(10)
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
  END get_dcsn_wf_org_data;
--

  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : データ妥当性チェック (A-3)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_base_value         IN  VARCHAR2                 -- 当該行データ
    ,o_col_data_tab        OUT NOCOPY g_col_data_ttype  -- 分割後項目データを格納する配列
    ,ov_errbuf             OUT NOCOPY VARCHAR2          -- エラー・メッセージ           -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2          -- リターン・コード             -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- プログラム名
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
    cn_format_col_cnt      CONSTANT NUMBER        := 15;          -- 項目数
    cn_value_kubun_len     CONSTANT NUMBER        := 1;           -- 更新区分バイト数
    cn_value_location_len  CONSTANT NUMBER        := 4;           -- 拠点コードバイト数
    cn_effctv_date_len     CONSTANT NUMBER        := 8;           -- 有効開始・終了日バイト数
    cn_description_len     CONSTANT NUMBER        := 100;         -- 摘要範囲
    cv_effctv_date_fmt     CONSTANT VARCHAR2(100) := 'YYYYMMDD';  -- DATE型
--
    -- *** ローカル変数 ***
    l_col_data_tab         g_col_data_ttype;  -- 分割後項目データを格納する配列
    lv_item_nm             VARCHAR2(100);     -- 該当項目名
    lv_effctv_strt_date    DATE;              -- 有効開始日
    lv_effctv_end_date     DATE;              -- 有効終了日
    lb_return              BOOLEAN;           -- リターンステータス
--
    lv_tmp                 VARCHAR2(2000);
    ln_pos                 NUMBER;
    ln_cnt                 NUMBER := 1;
    lb_format_flag         BOOLEAN := TRUE;
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
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_base_val    -- トークンコード1
                       ,iv_token_value1 => iv_base_value      -- トークン値1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
--
    -- 2.項目のNULLチェック、データ型（半角数字／日付）のチェック、サイズチェック
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
      -- 1). NULLチェック
      IF l_col_data_tab(1) IS NULL THEN
        -- 更新区分
        lb_return  := FALSE;
        lv_item_nm := '更新区分';
      ELSIF l_col_data_tab(2) IS NULL THEN
        -- 拠点CD
        lb_return  := FALSE;
        lv_item_nm := '拠点コード';
      ELSIF l_col_data_tab(3) IS NULL THEN
        -- 有効開始日
        lb_return  := FALSE;
        lv_item_nm := '有効開始日';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                       ,iv_token_value1 => lv_item_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 2). 半角英数型チェック
      IF (xxccp_common_pkg.chk_alphabet_number_only(l_col_data_tab(2)) = FALSE) THEN
        -- 拠点CD
        lb_return  := FALSE;
        lv_item_nm := '拠点コード';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                       ,iv_token_value1 => lv_item_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 3). 日付書式チェック
      -- 有効開始日
      IF (xxcso_util_common_pkg.check_date(l_col_data_tab(3), cv_effctv_date_fmt) = FALSE) THEN
        lb_return := FALSE;
        lv_item_nm := '有効開始日';
      ELSIF (l_col_data_tab(4) IS NOT NULL) THEN
      -- 有効終了日
        IF (xxcso_util_common_pkg.check_date(l_col_data_tab(4), cv_effctv_date_fmt) = FALSE) THEN
          lb_return := FALSE;
          lv_item_nm := '有効終了日';
        END IF;
      END IF;
--
      IF (lb_return = FALSE) THEN
        
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                       ,iv_token_value1 => lv_item_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 4). サイズチェック
      IF (LENGTHB(l_col_data_tab(1)) <> cn_value_kubun_len) THEN
        -- 更新区分
        lb_return  := FALSE;
        lv_item_nm := '更新区分';
      ELSIF (LENGTHB(l_col_data_tab(2)) <> cn_value_location_len) THEN
        -- 拠点CD
        lb_return  := FALSE;
        lv_item_nm := '拠点コード';
      ELSIF (LENGTHB(l_col_data_tab(3)) <> cn_effctv_date_len) THEN
        -- 有効開始日
        lb_return  := FALSE;
        lv_item_nm := '有効開始日';
      ELSIF (LENGTHB(l_col_data_tab(4)) <> cn_effctv_date_len) THEN
        -- 有効終了日
        lb_return  := FALSE;
        lv_item_nm := '有効終了日';
      ELSIF (LENGTHB(l_col_data_tab(5)) <> cn_value_location_len) THEN
        -- 回送拠点CD1
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード1';
      ELSIF (LENGTHB(l_col_data_tab(6)) <> cn_value_location_len) THEN
        -- 回送拠点CD2
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード2';
      ELSIF (LENGTHB(l_col_data_tab(7)) <> cn_value_location_len) THEN
        -- 回送拠点CD3
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード3';
      ELSIF (LENGTHB(l_col_data_tab(8)) <> cn_value_location_len) THEN
        -- 回送拠点CD4
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード4';
      ELSIF (LENGTHB(l_col_data_tab(9)) <> cn_value_location_len) THEN
        -- 回送拠点CD5
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード5';
      ELSIF (LENGTHB(l_col_data_tab(10)) <> cn_value_location_len) THEN
        -- 回送拠点CD6
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード6';
      ELSIF (LENGTHB(l_col_data_tab(11)) <> cn_value_location_len) THEN
        -- 回送拠点CD7
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード7';
      ELSIF (LENGTHB(l_col_data_tab(12)) <> cn_value_location_len) THEN
        -- 回送拠点CD8
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード8';
      ELSIF (LENGTHB(l_col_data_tab(13)) <> cn_value_location_len) THEN
        -- 回送拠点CD9
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード9';
      ELSIF (LENGTHB(l_col_data_tab(14)) <> cn_value_location_len) THEN
        -- 回送拠点CD10
        lb_return  := FALSE;
        lv_item_nm := '回送拠点コード10';
      ELSIF (LENGTHB(l_col_data_tab(15)) > cn_description_len) THEN
        -- 摘要
        lb_return  := FALSE;
        lv_item_nm := '摘要';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item        -- トークンコード1
                       ,iv_token_value1 => lv_item_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 5). 更新区分チェック
      IF ((l_col_data_tab(1) <> cv_value_kubun_val_1) AND
          (l_col_data_tab(1) <> cv_value_kubun_val_2)) THEN
        lb_return  := FALSE;
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_val_kubn    -- トークンコード1
                       ,iv_token_value1 => l_col_data_tab(1)  -- トークン値1
                       ,iv_token_name2  => cv_tkn_base_val    -- トークンコード2
                       ,iv_token_value2 => iv_base_value      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 6). 有効開始日・終了日大小チェック
      IF (l_col_data_tab(4) IS NOT NULL) THEN
        IF (l_col_data_tab(3) > l_col_data_tab(4)) THEN
        lb_return  := FALSE;
        END IF;
--
        IF (lb_return = FALSE) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name        -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_11   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_val_start   -- トークンコード1
                         ,iv_token_value1 => l_col_data_tab(3)  -- トークン値1
                         ,iv_token_name2  => cv_tkn_val_end     -- トークンコード2
                         ,iv_token_value2 => l_col_data_tab(4)  -- トークン値2
                         ,iv_token_name3  => cv_tkn_base_val    -- トークンコード3
                         ,iv_token_value3 => iv_base_value      -- トークン値3
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
--
    END IF;
--
    -- 行単位データをレコードにセット
    g_dcsn_wf_org_data_rec.update_kubun      := l_col_data_tab(1);   -- 更新区分
    g_dcsn_wf_org_data_rec.base_code         := l_col_data_tab(2);   -- 拠点CD
    g_dcsn_wf_org_data_rec.effective_st_date := TO_DATE(l_col_data_tab(3), cv_effctv_date_fmt); -- 有効開始日
    g_dcsn_wf_org_data_rec.effective_ed_date := TO_DATE(l_col_data_tab(4), cv_effctv_date_fmt); -- 有効終了日
    g_dcsn_wf_org_data_rec.sends_dept_code1  := l_col_data_tab(5);   -- 回送拠点CD1
    g_dcsn_wf_org_data_rec.sends_dept_code2  := l_col_data_tab(6);   -- 回送拠点CD2
    g_dcsn_wf_org_data_rec.sends_dept_code3  := l_col_data_tab(7);   -- 回送拠点CD3
    g_dcsn_wf_org_data_rec.sends_dept_code4  := l_col_data_tab(8);   -- 回送拠点CD4
    g_dcsn_wf_org_data_rec.sends_dept_code5  := l_col_data_tab(9);   -- 回送拠点CD5
    g_dcsn_wf_org_data_rec.sends_dept_code6  := l_col_data_tab(10);  -- 回送拠点CD6
    g_dcsn_wf_org_data_rec.sends_dept_code7  := l_col_data_tab(11);  -- 回送拠点CD7
    g_dcsn_wf_org_data_rec.sends_dept_code8  := l_col_data_tab(12);  -- 回送拠点CD8
    g_dcsn_wf_org_data_rec.sends_dept_code9  := l_col_data_tab(13);  -- 回送拠点CD9
    g_dcsn_wf_org_data_rec.sends_dept_code10 := l_col_data_tab(14);  -- 回送拠点CD10
    g_dcsn_wf_org_data_rec.excerpt           := l_col_data_tab(15);  -- 摘要
--
    -- マスタ存在チェック用配列へ格納 デバッグ用(gt_base_code_num := gt_base_code.count;)
    gt_base_code.delete;                     -- 配列初期化
    gt_base_code(1)  := l_col_data_tab(5);   -- 回送拠点CD1
    gt_base_code(2)  := l_col_data_tab(6);   -- 回送拠点CD2
    gt_base_code(3)  := l_col_data_tab(7);   -- 回送拠点CD3
    gt_base_code(4)  := l_col_data_tab(8);   -- 回送拠点CD4
    gt_base_code(5)  := l_col_data_tab(9);   -- 回送拠点CD5
    gt_base_code(6)  := l_col_data_tab(10);  -- 回送拠点CD6
    gt_base_code(7)  := l_col_data_tab(11);  -- 回送拠点CD7
    gt_base_code(8)  := l_col_data_tab(12);  -- 回送拠点CD8
    gt_base_code(9)  := l_col_data_tab(13);  -- 回送拠点CD9
    gt_base_code(10) := l_col_data_tab(14);  -- 回送拠点CD10
    
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
   * Description      : マスタ存在チェック (A-4)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     iv_base_value         IN  VARCHAR2         -- 当該行データ
    ,ov_errbuf             OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_colmun_nm           CONSTANT VARCHAR2(100) := '拠点コード';
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := '事業所マスタ';
    -- *** ローカル変数 ***
    ln_location_code_num   NUMBER;  -- 拠点CDカウント用変数(事業所マスタチェック)
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. 拠点CDのマスタ(事業所マスタ)存在チェック *** --
    BEGIN
      SELECT COUNT(hrl.location_code)  location_code_num  -- 拠点CD数カウント
      INTO   ln_location_code_num  -- 拠点CDカウント用変数(事業所マスタチェック)
      FROM   hr_locations hrl      -- 事業所マスタ
      WHERE  hrl.location_code = g_dcsn_wf_org_data_rec.base_code;
--
    EXCEPTION
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_22                  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                        -- トークンコード1
                       ,iv_token_value1 => cv_locations_table_nm             -- トークン値1
                       ,iv_token_name2  => cv_tkn_item                       -- トークンコード2
                       ,iv_token_value2 => g_dcsn_wf_org_data_rec.base_code  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                    -- トークンコード3
                       ,iv_token_value3 => SQLERRM                           -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    IF (ln_location_code_num = 0) THEN
    -- 抽出件数が0件の場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                         -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_13                    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_clmn                         -- トークンコード1
                     ,iv_token_value1 => cv_colmun_nm                        -- トークン値1
                     ,iv_token_name2  => cv_tkn_tbl                          -- トークンコード2
                     ,iv_token_value2 => cv_locations_table_nm               -- トークン値2
                     ,iv_token_name3  => cv_tkn_item                         -- トークンコード3
                     ,iv_token_value3 => g_dcsn_wf_org_data_rec.base_code    -- トークン値3
                     ,iv_token_name4  => cv_tkn_base_val                     -- トークンコード4
                     ,iv_token_value4 => iv_base_value                       -- トークン値4
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;

--
    -- *** 2. 回送用拠点CDのマスタ(事業所マスタ)存在チェック *** --
    FOR i IN 1..gt_base_code.COUNT LOOP
      IF (gt_base_code(i) IS NOT NULL) THEN
        BEGIN
          SELECT COUNT(hrl.location_code)  location_code_num  -- 拠点CD数カウント
          INTO   ln_location_code_num  -- 拠点CDカウント用変数(事業所マスタチェック)
          FROM   hr_locations hrl      -- 事業所マスタ
          WHERE  hrl.location_code = gt_base_code(i);

--
        EXCEPTION
          -- 抽出に失敗した場合
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_22              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_tbl                    -- トークンコード1
                           ,iv_token_value1 => cv_locations_table_nm         -- トークン値1
                           ,iv_token_name2  => cv_tkn_item                   -- トークンコード2
                           ,iv_token_value2 => gt_base_code(i)               -- トークン値2
                           ,iv_token_name3  => cv_tkn_err_msg                -- トークンコード3
                           ,iv_token_value3 => SQLERRM                       -- トークン値3
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_skip_error_expt;
        END;
      
        IF (ln_location_code_num = 0) THEN
          -- 抽出件数が0件の場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                      -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_13                 -- メッセージコード
                        ,iv_token_name1  => cv_tkn_clmn                      -- トークンコード1
                        ,iv_token_value1 => cv_colmun_nm                     -- トークン値1
                        ,iv_token_name2  => cv_tkn_tbl                       -- トークンコード2
                        ,iv_token_value2 => cv_locations_table_nm            -- トークン値2
                        ,iv_token_name3  => cv_tkn_item                      -- トークンコード3
                        ,iv_token_value3 => gt_base_code(i)                  -- トークン値3
                        ,iv_token_name4  => cv_tkn_base_val                  -- トークンコード4
                        ,iv_token_value4 => iv_base_value                    -- トークン値4
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
    END LOOP;
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
   * Procedure Name   : chk_mst_effective_date
   * Description      : 同一拠点CDで有効期間が重複する
   *                    データ存在チェック処理(登録用) (A-5)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_effective_date(
     iv_base_value         IN  VARCHAR2                    -- 当該行データ
    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'chk_mst_effective_date';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP専決WF承認組織マスタ';
    -- *** ローカル変数 *** 
    ln_base_code_num       NUMBER;   -- 拠点CDカウント用変数(SP専決WF承認組織マスタチェック)
    -- *** ローカル例外 ***
    chk_ffctv_dt_err_expt  EXCEPTION;  -- 有効期間重複例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. 同一拠点CD、有効期間のデータが既に存在するかチェック *** --
    BEGIN
      SELECT COUNT(sdwo.base_code)  location_code_num  -- 拠点CD数カウント
      INTO   ln_base_code_num                -- 拠点CDカウント用変数(SP専決WF承認組織マスタチェック)
      FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP専決WF承認組織マスタ
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.effective_st_date = TRUNC(g_dcsn_wf_org_data_rec.effective_st_date);
--
      IF (ln_base_code_num = 0) THEN
        SELECT COUNT(sdwo.base_code)  location_code_num  -- 拠点CD数カウント
        INTO   ln_base_code_num                -- 拠点CDカウント用変数(SP専決WF承認組織マスタチェック)
        FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP専決WF承認組織マスタ
        WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
        AND    (TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)
               BETWEEN sdwo.effective_st_date
               AND     NVL(TRUNC(sdwo.effective_ed_date), TRUNC(g_dcsn_wf_org_data_rec.effective_st_date))
        OR     TRUNC(sdwo.effective_st_date)
               BETWEEN TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)
               AND     NVL(TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date), TRUNC(sdwo.effective_st_date)));
      END IF;
--
      IF (ln_base_code_num >= 1) THEN
      -- 取得した件数が1件以上の場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                       -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_15                  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_val_loc                    -- トークンコード1
                      ,iv_token_value1 => g_dcsn_wf_org_data_rec.base_code  -- トークン値1
                      ,iv_token_name2  => cv_tkn_val_start                  -- トークンコード2
                      ,iv_token_value2 => TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)              -- トークン値2
                      ,iv_token_name3  => cv_tkn_val_end                    -- トークンコード3
                      ,iv_token_value3 => TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date)              -- トークン値3
                      ,iv_token_name4  => cv_tkn_base_val                   -- トークンコード4
                      ,iv_token_value4 => iv_base_value                     -- トークン値4
                    );
        lv_errbuf := lv_errmsg;
        RAISE chk_ffctv_dt_err_expt;
      END IF;
--
    EXCEPTION
      -- 有効期間が重複するデータが存在した場合
      WHEN chk_ffctv_dt_err_expt THEN
        RAISE global_skip_error_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                    -- トークンコード1
                       ,iv_token_value1 => cv_locations_table_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                -- トークンコード3
                       ,iv_token_value2 => SQLERRM                       -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
--
    END;
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
  END chk_mst_effective_date;

  /**********************************************************************************
   * Procedure Name   : insert_dcsn_wf_org_data
   * Description      : WF承認組織マスタデータ登録 (A-6)
   ***********************************************************************************/
--
  PROCEDURE insert_dcsn_wf_org_data(
     iv_base_value         IN  VARCHAR2                    -- 当該行データ
    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'insert_dcsn_wf_org_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP専決WF承認組織マスタ';
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
    -- WF承認組織マスタデータ登録 
    -- =======================
    BEGIN
      INSERT INTO xxcso_sp_decision_wf_orgs  -- SP専決WF承認組織マスタ
        ( wf_approval_org_id      -- WF承認組織マスタID
         ,base_code               -- 拠点CD
         ,effective_st_date       -- 有効開始日
         ,effective_ed_date       -- 有効終了日
         ,sends_dept_code1        -- 回送拠点CD1
         ,sends_dept_code2        -- 回送拠点CD2
         ,sends_dept_code3        -- 回送拠点CD3
         ,sends_dept_code4        -- 回送拠点CD4
         ,sends_dept_code5        -- 回送拠点CD5
         ,sends_dept_code6        -- 回送拠点CD6
         ,sends_dept_code7        -- 回送拠点CD7
         ,sends_dept_code8        -- 回送拠点CD8
         ,sends_dept_code9        -- 回送拠点CD9
         ,sends_dept_code10       -- 回送拠点CD10
         ,excerpt                 -- 摘要
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
      VALUES
        ( xxcso_sp_decision_wf_orgs_s01.NEXTVAL
         ,g_dcsn_wf_org_data_rec.base_code        
         ,g_dcsn_wf_org_data_rec.effective_st_date
         ,g_dcsn_wf_org_data_rec.effective_ed_date
         ,g_dcsn_wf_org_data_rec.sends_dept_code1 
         ,g_dcsn_wf_org_data_rec.sends_dept_code2 
         ,g_dcsn_wf_org_data_rec.sends_dept_code3 
         ,g_dcsn_wf_org_data_rec.sends_dept_code4 
         ,g_dcsn_wf_org_data_rec.sends_dept_code5 
         ,g_dcsn_wf_org_data_rec.sends_dept_code6 
         ,g_dcsn_wf_org_data_rec.sends_dept_code7 
         ,g_dcsn_wf_org_data_rec.sends_dept_code8 
         ,g_dcsn_wf_org_data_rec.sends_dept_code9 
         ,g_dcsn_wf_org_data_rec.sends_dept_code10
         ,g_dcsn_wf_org_data_rec.excerpt          
         ,cn_created_by            
         ,cd_creation_date         
         ,cn_last_updated_by       
         ,cd_last_update_date      
         ,cn_last_update_login     
         ,cn_request_id            
         ,cn_program_application_id
         ,cn_program_id            
         ,cd_program_update_date   
        );
--
    EXCEPTION
         -- 登録に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl             -- トークンコード1
                       ,iv_token_value1 => cv_locations_table_nm  -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id         -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)    -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg         -- トークンコード3
                       ,iv_token_value3 => SQLERRM                -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
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
  END insert_dcsn_wf_org_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_dcsn_wf_org_exists
   * Description      : WF承認組織マスタデータ存在チェック (A-7)
   ***********************************************************************************/
--
  PROCEDURE chk_dcsn_wf_org_exists(
     iv_base_value          IN  VARCHAR2         -- 当該行データ
    ,ov_wf_approval_org_id  OUT NOCOPY VARCHAR2  -- A-8チェック用WF承認組織マスタID
    ,ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_dcsn_wf_org_exists';  -- プログラム名
--
-- #######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP専決WF承認組織マスタ';
    -- *** ローカル変数 ***
    ct_wf_approval_org_id  xxcso_sp_decision_wf_orgs.wf_approval_org_id%TYPE;  -- A-8チェック用WF承認組織マスタID
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. 更新区分が2の場合の(WF承認組織マスタ)存在チェック *** --
    BEGIN
      SELECT sdwo.wf_approval_org_id  wf_approval_org_id  -- WF承認組織マスタID
      INTO   ct_wf_approval_org_id           -- A-8チェック用WF承認組織マスタID
      FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP専決WF承認組織マスタ
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.effective_st_date = g_dcsn_wf_org_data_rec.effective_st_date;

    ov_wf_approval_org_id := ct_wf_approval_org_id;  -- A-8チェック用WF承認組織マスタIDをアウトパラメータへ
--
    EXCEPTION
      -- 抽出件数が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                               -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_14                          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_val_loc                            -- トークンコード1
                       ,iv_token_value1 => g_dcsn_wf_org_data_rec.base_code          -- トークン値1
                       ,iv_token_name2  => cv_tkn_val_start                          -- トークンコード2
                       ,iv_token_value2 => g_dcsn_wf_org_data_rec.effective_st_date  -- トークン値2
                       ,iv_token_name3  => cv_tkn_base_val                           -- トークンコード3
                       ,iv_token_value3 => iv_base_value                             -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                    -- トークンコード1
                       ,iv_token_value1 => cv_locations_table_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                -- トークンコード3
                       ,iv_token_value2 => SQLERRM                       -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
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
  END chk_dcsn_wf_org_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_effective_date_2
   * Description      : 同一拠点CDで有効期間が重複する
   *                    データ存在チェック処理(更新用) (A-8)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_effective_date_2(
     iv_base_value         IN  VARCHAR2                    -- 当該行データ
    ,iv_wf_approval_org_id IN  VARCHAR2                    -- A-8チェック用WF承認組織マスタID
    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'chk_mst_effective_date_2';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP専決WF承認組織マスタ';
    -- *** ローカル変数 *** 
    ln_count_num           NUMBER;            -- WF承認組織マスタIDカウント用変数(SP専決WF承認組織マスタチェック)
    ct_wf_approval_org_id  xxcso_sp_decision_wf_orgs.wf_approval_org_id%TYPE;  -- A-8チェック用WF承認組織マスタID
    -- *** ローカル例外 ***
    chk_ffctv_dt_err_expt  EXCEPTION;         -- 有効期間重複例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    -- *** 1. 同一拠点CD、有効期間のデータが既に存在するかチェック *** --
    BEGIN
      ct_wf_approval_org_id := iv_wf_approval_org_id;  -- INパラメータを格納

      SELECT COUNT(sdwo.wf_approval_org_id)  wf_approval_org_id_num  -- WF承認組織マスタID数
      INTO   ln_count_num                    -- WF承認組織マスタIDカウント用変数(SP専決WF承認組織マスタチェック)
      FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP専決WF承認組織マスタ
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.wf_approval_org_id <> ct_wf_approval_org_id
      AND    TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date)
             BETWEEN sdwo.effective_st_date
             AND     NVL(TRUNC(sdwo.effective_ed_date), TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date));
--
      IF (ln_count_num >= 1) THEN
      -- 取得した件数が1件以上の場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                      -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_15                                 -- メッセージコード
                      ,iv_token_name1  => cv_tkn_val_loc                                   -- トークンコード1
                      ,iv_token_value1 => g_dcsn_wf_org_data_rec.base_code                 -- トークン値1
                      ,iv_token_name2  => cv_tkn_val_start                                 -- トークンコード2
                      ,iv_token_value2 => TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)  -- トークン値2
                      ,iv_token_name3  => cv_tkn_val_end                                   -- トークンコード3
                      ,iv_token_value3 => TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date)  -- トークン値3
                      ,iv_token_name4  => cv_tkn_base_val                                  -- トークンコード4
                      ,iv_token_value4 => iv_base_value                                    -- トークン値4
                    );
        lv_errbuf := lv_errmsg;
        RAISE chk_ffctv_dt_err_expt;
      END IF;
--
    EXCEPTION
      -- 有効期間が重複するデータが存在した場合
      WHEN chk_ffctv_dt_err_expt THEN
        RAISE global_skip_error_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                    -- トークンコード1
                       ,iv_token_value1 => cv_locations_table_nm         -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                -- トークンコード3
                       ,iv_token_value2 => SQLERRM                       -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
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
  END chk_mst_effective_date_2;
--
  /**********************************************************************************
   * Procedure Name   : update_dcsn_wf_org_data
   * Description      : WF承認組織マスタデータ更新 (A-9)
   ***********************************************************************************/
--
  PROCEDURE update_dcsn_wf_org_data(
     iv_base_value         IN  VARCHAR2                    -- 当該行データ

    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'update_dcsn_wf_org_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);     -- リターン・コード
    lv_errmsg              VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_update_table_nm     CONSTANT VARCHAR2(100) := 'SP専決WF承認組織マスタ';
    -- *** ローカル変数 ***
    ln_wf_approval_org_id  NUMBER;  -- WF承認組織マスタID格納用変数
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
    -- WF承認組織マスタデータ更新 
    -- =======================
    BEGIN
      SELECT  sdwo.wf_approval_org_id  wf_approval_org_id  -- WF承認組織マスタID
      INTO    ln_wf_approval_org_id           -- WF承認組織マスタID格納
      FROM    xxcso_sp_decision_wf_orgs sdwo  -- SP専決WF承認組織マスタ
      WHERE   sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND     sdwo.effective_st_date = g_dcsn_wf_org_data_rec.effective_st_date
      FOR UPDATE NOWAIT;  -- テーブルロック
--
    EXCEPTION
          -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_02     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_update_table_nm   -- トークン値1
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード2
                       ,iv_token_value3 => SQLERRM              -- トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_skip_error_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_update_table_nm   -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg       -- トークンコード3
                       ,iv_token_value2 => SQLERRM              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
--
    END;
--
    BEGIN
      UPDATE xxcso_sp_decision_wf_orgs sdwo  -- SP専決WF承認組織マスタ
      SET
         base_code               =  g_dcsn_wf_org_data_rec.base_code          -- 拠点CD
        ,effective_st_date       =  g_dcsn_wf_org_data_rec.effective_st_date  -- 有効開始日
        ,effective_ed_date       =  g_dcsn_wf_org_data_rec.effective_ed_date  -- 有効終了日
        ,sends_dept_code1        =  g_dcsn_wf_org_data_rec.sends_dept_code1   -- 回送拠点CD1
        ,sends_dept_code2        =  g_dcsn_wf_org_data_rec.sends_dept_code2   -- 回送拠点CD2
        ,sends_dept_code3        =  g_dcsn_wf_org_data_rec.sends_dept_code3   -- 回送拠点CD3
        ,sends_dept_code4        =  g_dcsn_wf_org_data_rec.sends_dept_code4   -- 回送拠点CD4
        ,sends_dept_code5        =  g_dcsn_wf_org_data_rec.sends_dept_code5   -- 回送拠点CD5
        ,sends_dept_code6        =  g_dcsn_wf_org_data_rec.sends_dept_code6   -- 回送拠点CD6
        ,sends_dept_code7        =  g_dcsn_wf_org_data_rec.sends_dept_code7   -- 回送拠点CD7
        ,sends_dept_code8        =  g_dcsn_wf_org_data_rec.sends_dept_code8   -- 回送拠点CD8
        ,sends_dept_code9        =  g_dcsn_wf_org_data_rec.sends_dept_code9   -- 回送拠点CD9
        ,sends_dept_code10       =  g_dcsn_wf_org_data_rec.sends_dept_code10  -- 回送拠点CD10
        ,excerpt                 =  g_dcsn_wf_org_data_rec.excerpt            -- 摘要
        ,last_updated_by         =  cn_last_updated_by           -- 最終更新者
        ,last_update_date        =  cd_last_update_date          -- 最終更新日
        ,last_update_login       =  cn_last_update_login         -- 最終更新ログイン
        ,request_id              =  cn_request_id                -- 要求ID
        ,program_application_id  =  cn_program_application_id    -- コンカレント・プログラム・アプリケーションID
        ,program_id              =  cn_program_id                -- コンカレント・プログラムID
        ,program_update_date     =  cd_program_update_date       -- プログラム更新日
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.effective_st_date = g_dcsn_wf_org_data_rec.effective_st_date;
    
--
    EXCEPTION
      -- 更新に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_update_table_nm   -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード3
                       ,iv_token_value3 => SQLERRM              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
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
  END update_dcsn_wf_org_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : ファイルデータ削除処理 (A-11)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf      OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode     OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg      OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm  CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
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
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg       -- トークンコード2
                       ,iv_token_value3 => SQLERRM              -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;                              -- # 任意 #
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
     ov_errbuf      OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode     OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg      OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode  VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================

    -- *** ローカル変数 ***
    l_col_data_tab         g_col_data_ttype;       -- 分割後項目データを格納する配列
    lv_base_value          VARCHAR2(5000);         -- 当該行データ
    ln_obj_ver_num         NUMBER;                 -- オブジェクトバージョン番号
    ct_wf_approval_org_id  xxcso_sp_decision_wf_orgs.wf_approval_org_id%TYPE;  -- A-8チェック用WF承認組織マスタID
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
    -- A-2.WF承認組織マスタデータ抽出処理 
    -- ========================================
    get_dcsn_wf_org_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ファイルデータループ
    <<dcsn_wf_org_data_loop>>
    FOR i IN 1..g_file_data_tab.COUNT LOOP
--
      BEGIN
--
        -- レコードクリア
        g_dcsn_wf_org_data_rec := NULL;

        -- 対象件数カウント
        gn_target_cnt := gn_target_cnt + 1;

        lv_base_value := g_file_data_tab(i);
--

        -- =================================================
        -- A-3.データ妥当性チェック (レコードにデータセット)
        -- =================================================
        data_proper_check(
           o_col_data_tab   => l_col_data_tab   -- ファイルデータ(行データ)
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
        -- =============================
        -- A-4.マスタ存在チェック 
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
        -- A-2で抽出した更新区分が1の場合
        IF (g_dcsn_wf_org_data_rec.update_kubun = cv_value_kubun_val_1) THEN
--
          -- =====================================
          -- A-5.同一拠点CDで有効期間が重複する
          --     データ存在チェック処理(登録用)
          -- =====================================
--
          chk_mst_effective_date(
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
          -- A-10.SAVEPOINT発行
          SAVEPOINT dcsn_wf_org;
--
          -- =============================
          -- A-6.WF承認組織マスタデータ登録 
          -- =============================
          insert_dcsn_wf_org_data(
             iv_base_value    => lv_base_value    -- 当該行データ
            ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_skip_error_expt;
          END IF;
--
        -- A-2で抽出した更新区分が2の場合
        ELSIF (g_dcsn_wf_org_data_rec.update_kubun = cv_value_kubun_val_2) THEN
--
          -- ========================================
          -- A-7.WF承認組織マスタデータ存在チェック 
          -- ========================================
          chk_dcsn_wf_org_exists(
             iv_base_value          => lv_base_value          -- 当該行データ
            ,ov_wf_approval_org_id  => ct_wf_approval_org_id  -- A-8チェック用WF承認組織マスタID
            ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode             => lv_sub_retcode         -- リターン・コード              -- # 固定 #
            ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- A-10.SAVEPOINT発行
          SAVEPOINT dcsn_wf_org;
--

          -- =====================================
          -- A-8.同一拠点CDで有効期間が重複する
          --     データ存在チェック処理(更新用)
          -- =====================================
          -- A-2で抽出した有効終了日がNULL以外の場合
          IF (g_dcsn_wf_org_data_rec.effective_ed_date IS NOT NULL) THEN
            chk_mst_effective_date_2(
              iv_base_value           => lv_base_value          -- 当該行データ
              ,iv_wf_approval_org_id  => ct_wf_approval_org_id  -- A-8チェック用WF承認組織マスタID
              ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode             => lv_sub_retcode         -- リターン・コード              -- # 固定 #
              ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              RAISE global_skip_error_expt;
            END IF;
          END IF;
--
          -- =============================
          -- A-9.WF承認組織マスタデータ更新 
          -- =============================
          update_dcsn_wf_org_data(
             iv_base_value  => lv_base_value   -- 当該行データ
            ,ov_errbuf      => lv_errbuf       -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode     => lv_sub_retcode  -- リターン・コード              -- # 固定 #
            ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_skip_error_expt;
          END IF;
--
        END IF;
--
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
             which  => fnd_file.output
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
          IF gb_wf_org_inup_rollback_flag = TRUE THEN
            ROLLBACK TO SAVEPOINT dcsn_wf_org;    -- ROLLBACK
            gb_wf_org_inup_rollback_flag := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
            );
          END IF;
--
        --*** 処理部共通例外ハンドラ ***
        WHEN global_process_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- エラー件数カウント
          lv_retcode := cv_status_warn;
--
          -- メッセージ出力
          fnd_file.put_line(
             which  => fnd_file.output
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
          IF gb_wf_org_inup_rollback_flag = TRUE THEN
            ROLLBACK TO SAVEPOINT dcsn_wf_org;    -- ROLLBACK
            gb_wf_org_inup_rollback_flag := FALSE;
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
          IF gb_wf_org_inup_rollback_flag = TRUE THEN
            ROLLBACK TO SAVEPOINT dcsn_wf_org;    -- ROLLBACK
            gb_wf_org_inup_rollback_flag := FALSE;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
            );
          END IF;
--
      END;
--
    END LOOP dcsn_wf_org_data_loop;
--
    ov_retcode := lv_retcode;                -- リターン・コード
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
      -- ファイルデータ削除でのエラー
      gb_if_del_err_flag := TRUE;
--
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      -- ファイルデータ削除処理
      IF (gb_if_del_err_flag = FALSE) THEN
        delete_if_data(
           ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      -- ファイルデータ削除処理
      IF (gb_if_del_err_flag = FALSE) THEN
        delete_if_data(
           ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
      END IF;
--
    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
    ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      -- ファイルデータ削除処理
      IF (gb_if_del_err_flag = FALSE) THEN
        delete_if_data(
           ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
          ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
          ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
        );
      END IF;
--
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
          which  => fnd_file.output
         ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf                  -- エラーメッセージ
       );
--
         IF (gn_normal_cnt IS NOT NULL) THEN
         gn_error_cnt := gn_error_cnt + gn_normal_cnt;
         gn_normal_cnt := 0;  -- 成功件数を全てエラー件数へ
         END IF;
--
    END IF;
--
    -- =======================
    -- A-12.終了処理 
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => fnd_file.output
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
       which  => fnd_file.output
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
       which  => fnd_file.output
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
       which  => fnd_file.output
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
       which  => fnd_file.output
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
END XXCSO020A06C;
/
