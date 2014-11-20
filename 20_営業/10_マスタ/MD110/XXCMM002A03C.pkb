CREATE OR REPLACE PACKAGE BODY XXCMM002A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A03C(body)
 * Description      : 社員データ連携(情報系)
 * MD.050           : 社員データ連携(情報系) MD050_CMM_002_A03
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_people_data        社員データ取得プロシージャ(A-2)
 *  output_csv             CSVファイル出力プロシージャ(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   SCS 福間 貴子    初回作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A03C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_JYOHO_OUT_DIR';       -- 情報系CSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A03_OUT_FILE';     -- 連携用CSVファイル名
  cv_jyugyoin_kbn           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A03_JYUGYOIN_KBN'; -- 従業員区分のダミー値
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
  cv_tkn_jyugoin_kbn_nm     CONSTANT VARCHAR2(20)  := '従業員区分のダミー値';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '社員番号';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := '、氏名 : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- コンカレント入力パラメータなし
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
  cv_msg_00001              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- 対象データ無し
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- 従業員番号重複メッセージ
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
  -- 固定値(設定値、抽出条件)
  cv_company_cd             CONSTANT VARCHAR2(3)   := '001';                        -- 会社コード
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate                DATE;                 -- 処理開始日時
  gv_filepath               VARCHAR2(255);        -- 連携用CSVファイル出力先
  gv_filename               VARCHAR2(255);        -- 連携用CSVファイル名
  gv_jyugyoin_kbn           VARCHAR2(10);         -- 従業員区分のダミー値
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gc_del_flg                CHAR(1);              -- ファイル削除フラグ(対象データ無しの場合)
  gv_warn_flg               VARCHAR2(1);          -- 警告フラグ
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR get_people_data_cur
  IS
    SELECT   SUBSTRB(p.employee_number,1,5) AS employee_number,                                      -- 社員番号
             SUBSTRB(p.last_name || ' ' || p.first_name,1,20) AS kana,                               -- 氏名(カナ)
             SUBSTRB(p.per_information18 || '　' || p.per_information19,1,20) AS kanji,              -- 氏名(漢字)
             SUBSTRB(p.sex,1,1) AS sex,                                                              -- 性別区分
             TO_CHAR(p.effective_start_date,'YYYYMMDD') AS effective_start_date,                     -- 入社年月日
             TO_CHAR(s.actual_termination_date,'YYYYMMDD') AS actual_termination_date,               -- 退職年月日
             SUBSTRB(a.ass_attribute1,1,2) AS ass_attribute1,                                        -- 異動事由コード
             a.ass_attribute2 AS ass_attribute2,                                                     -- 発令日
             SUBSTRB(a.ass_attribute5,1,4) AS ass_attribute5,                                        -- 拠点コード(新)
             SUBSTRB(p.attribute7,1,3) AS attribute7,                                                -- 資格コード(新)
             SUBSTRB(p.attribute8,1,20) AS attribute8,                                               -- 資格名(新)
             SUBSTRB(p.attribute11,1,3) AS attribute11,                                              -- 職位コード(新)
             SUBSTRB(p.attribute12,1,20) AS attribute12,                                             -- 職位名(新)
             SUBSTRB(a.ass_attribute6,1,4) AS ass_attribute6,                                        -- 拠点コード(旧)
             SUBSTRB(p.attribute9,1,3) AS attribute9,                                                -- 資格コード(旧)
             SUBSTRB(p.attribute10,1,20) AS attribute10,                                             -- 資格名(旧)
             SUBSTRB(p.attribute13,1,3) AS attribute13,                                              -- 職位コード(旧)
             SUBSTRB(p.attribute14,1,20) AS attribute14,                                             -- 職位名(旧)
             TO_CHAR(p.creation_date,'YYYYMMDDHH24MISS') AS creation_date,                           -- 作成年月日時分秒
             TO_CHAR(p.last_update_date,'YYYYMMDDHH24MISS') AS last_update_date,                     -- 最終更新年月日時分秒
             SUBSTRB(p.attribute3,1,1) AS attribute3                                                 -- 社員・外部委託区分
    FROM     per_periods_of_service s,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = s.period_of_service_id
    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn
             OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    ORDER BY employee_number
  ;
  TYPE g_people_data_ttype IS TABLE OF get_people_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_people_data            g_people_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- プログラム名
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
    -- ファイルオープンモード
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- 上書き
--
    -- *** ローカル変数 ***
    lb_fexists              BOOLEAN;              -- ファイルが存在するかどうか
    ln_file_size            NUMBER;               -- ファイルの長さ
    ln_block_size           NUMBER;               -- ファイルシステムのブロックサイズ
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =========================================================
    --  処理開始日時を取得
    -- =========================================================
    gd_sysdate := SYSDATE;
    --
    -- =========================================================
    --  固定出力(入力パラメータ部)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_90008           -- コンカレント入力パラメータなし
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入(入力パラメータの下)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- ============================================================================
    --  プロファイルの取得(CSVファイル出力先、CSVファイル名、従業員区分のダミー値)
    -- ============================================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm   -- プロファイル名(CSVファイル出力先)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm   -- プロファイル名(CSVファイル名)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_jyugyoin_kbn := fnd_profile.value(cv_jyugyoin_kbn);
    IF (gv_jyugyoin_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_jyugoin_kbn_nm   -- プロファイル名(従業員区分のダミー値)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =========================================================
    --  固定出力(I/Fファイル名部)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_05102           -- ファイル名出力メッセージ
                    ,iv_token_name1  => cv_tkn_filename        -- トークン(FILE_NAME)
                    ,iv_token_value1 => gv_filename            -- ファイル名
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入(I/Fファイル名の下)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- =========================================================
    --  CSVファイル存在チェック
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00010         -- ファイル作成済みエラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =========================================================
    --  ファイルオープン
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                        ,iv_name         => cv_msg_00003       -- ファイルパス不正エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_people_data
   * Description      : 従業員データ取得プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE get_people_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_people_data';       -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
   -- カーソルオープン
    OPEN get_people_data_cur;
    --
    -- データの一括取得
    FETCH get_people_data_cur BULK COLLECT INTO gt_people_data;
    --
    -- 取得データ件数をセット
    gn_target_cnt := gt_people_data.COUNT;
    --
    -- カーソルクローズ
    CLOSE get_people_data_cur;
    --
    -- 処理対象となるデータが存在するかをチェック
    IF (gn_target_cnt = 0) THEN
      gc_del_flg := '1';
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00001         -- 対象データ無し
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_people_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力プロシージャ(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- プログラム名
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                   -- ループカウンタ
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
    lv_employee_number  VARCHAR2(5);              -- 従業員番号重複チェック用
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
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    lv_employee_number := ' ';
    <<out_loop>>
    FOR ln_loop_cnt IN gt_people_data.FIRST..gt_people_data.LAST LOOP
      -- 従業員番号が重複している場合、警告メッセージを表示
      IF (lv_employee_number = gt_people_data(ln_loop_cnt).employee_number) THEN
        -- 警告フラグにオンをセット
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                   -- 従業員番号重複メッセージ
                        ,iv_token_name1  => cv_tkn_word                                    -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                    -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_people_data(ln_loop_cnt).employee_number    -- NG_WORDのDATA
                                              || cv_tkn_word2
                                              || gt_people_data(ln_loop_cnt).kanji
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
      lv_csv_text := cv_enclosed || cv_company_cd || cv_enclosed || cv_delimiter                      -- 会社コード
        || cv_enclosed || gt_people_data(ln_loop_cnt).employee_number || cv_enclosed || cv_delimiter  -- 社員番号
        || cv_enclosed || gt_people_data(ln_loop_cnt).kana || cv_enclosed || cv_delimiter             -- 従業員氏名（カナ）
        || cv_enclosed || gt_people_data(ln_loop_cnt).kanji || cv_enclosed || cv_delimiter            -- 従業員氏名（漢字）
        || cv_enclosed || gt_people_data(ln_loop_cnt).sex || cv_enclosed || cv_delimiter              -- 性別区分
        || gt_people_data(ln_loop_cnt).effective_start_date || cv_delimiter                           -- 入社年月日
        || gt_people_data(ln_loop_cnt).actual_termination_date || cv_delimiter                        -- 退職年月日
        || cv_enclosed || gt_people_data(ln_loop_cnt).ass_attribute1 || cv_enclosed || cv_delimiter   -- 異動事由コード
        || gt_people_data(ln_loop_cnt).ass_attribute2 || cv_delimiter                                 -- 発令日
        || cv_enclosed || gt_people_data(ln_loop_cnt).ass_attribute5 || cv_enclosed || cv_delimiter   -- 拠点（部門）コード（新）
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute7 || cv_enclosed || cv_delimiter       -- 資格コード(新)
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute8 || cv_enclosed || cv_delimiter       -- 資格名(新)
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute11 || cv_enclosed || cv_delimiter      -- 職位コード(新)
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute12 || cv_enclosed || cv_delimiter      -- 職位名(新)
        || cv_enclosed || gt_people_data(ln_loop_cnt).ass_attribute6 || cv_enclosed || cv_delimiter   -- 拠点（部門）コード（旧）
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute9 || cv_enclosed || cv_delimiter       -- 資格コード(旧)
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute10 || cv_enclosed || cv_delimiter      -- 資格名(旧)
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute13 || cv_enclosed || cv_delimiter      -- 職位コード(旧)
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute14 || cv_enclosed || cv_delimiter      -- 職位名(旧)
        || gt_people_data(ln_loop_cnt).creation_date || cv_delimiter                                  -- 作成年月日時分秒
        || gt_people_data(ln_loop_cnt).last_update_date || cv_delimiter                               -- 最終更新年月日時分秒
        || cv_enclosed || gt_people_data(ln_loop_cnt).attribute3 || cv_enclosed || cv_delimiter       -- 社員・外部委託区分
        || TO_CHAR(gd_sysdate,'YYYYMMDDHH24MISS')                                                     -- 連携日時
      ;
      BEGIN
        -- ファイル書き込み
        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
      EXCEPTION
        -- ファイルアクセス権限エラー
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00007                                 -- ファイルアクセス権限エラー
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSVデータ出力エラー
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00009                                 -- CSVデータ出力エラー
                          ,iv_token_name1  => cv_tkn_word                                  -- トークン(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                                  -- トークン(NG_DATA)
                          ,iv_token_value2 => gt_people_data(ln_loop_cnt).employee_number  -- NG_WORDのDATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      lv_employee_number := gt_people_data(ln_loop_cnt).employee_number;
      --
      -- 処理件数のカウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP out_loop;
    --
    IF (gv_warn_flg = '1') THEN
      -- 空行挿入(処理件数部の上、あるいはエラーメッセージの上)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
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
    gv_warn_flg   := '0';
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =====================================================
    --  初期処理プロシージャ(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  社員データ取得プロシージャ(A-2)
    -- =====================================================
    get_people_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSVファイル出力プロシージャ(A-3)
    -- =====================================================
    output_csv(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  終了処理プロシージャ(A-4)
    -- =====================================================
    -- CSVファイルをクローズする
    UTL_FILE.FCLOSE(gf_file_hand);
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
   * Description      : コンカレント実行プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    -- ファイル削除フラグをクリア
    gc_del_flg := '0';
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf   -- エラー・メッセージ            --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入(処理件数部の上)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      IF (gv_warn_flg = '1') THEN
        -- 空行挿入(警告メッセージとエラーメッセージの間)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        --警告の場合、リターン・コードに警告をセットする
        lv_retcode := cv_status_warn;
      END IF;
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
    -- 空行挿入(終了メッセージの上)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    --
    --CSVファイルがクローズされていなかった場合、クローズする
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
    --対象データ無しの場合、CSVファイルを削除
    IF (gc_del_flg = '1') THEN
      UTL_FILE.FREMOVE(gv_filepath,    -- CSVファイル出力先
                       gv_filename);   -- ファイル名
    END IF;
    --
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
END XXCMM002A03C;
/
