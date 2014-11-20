CREATE OR REPLACE PACKAGE BODY XXCMM006A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A04C(body)
 * Description      : 稼動日カレンダIF出力（情報系）
 * MD.050           : 稼動日カレンダIF出力（情報系) MD050_CMM_006_A04
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             CSVファイル出力処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0   SCS 工藤 真純    初回作成
 *  2010/04/20    1.1   SCS 久保島 豊    E_本稼動_02251対応 プロファイルの変更
 *                                                          (XXCCP1_WORKING_CALENDAR -> XXCMM1_006A04_BUSINS_CAL_CODE)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
--  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1(未使用)
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
--  gn_warn_cnt      NUMBER;                    -- スキップ件数(未使用)
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
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMM';             -- アドオン：マスタ
  cv_common_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- アドオン：共通・IF
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM006A04C';      -- パッケージ名
--
  -- メッセージ番号(マスタ)
  cv_file_data_no_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- 対象データ無しメッセージ
  cv_prf_get_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_file_pass_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';  -- ファイルパス不正エラー
  cv_file_priv_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00007';  -- ファイルアクセス権限エラー
  cv_csv_data_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';  -- CSVデータ出力エラー
  cv_csv_file_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';  -- CSVファイル存在チェック
  -- メッセージ番号(共通・IF)
  cv_file_name         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';  -- ファイル名メッセージ
  cv_input_no_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
--
  -- プロファイル
  cv_prf_dir           CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';  -- 稼働日カレンダ連携用CSVファイル出力先
  cv_prf_fil           CONSTANT VARCHAR2(30) := 'XXCMM1_006A04_OUT_FILE';  -- 稼働日カレンダ連携用CSVファイル名
-- 2010/04/20 Ver1.1 modify start by Y.Kuboshima
--  cv_prf_calender_cd   CONSTANT VARCHAR2(30) := 'XXCCP1_WORKING_CALENDAR';  -- カレンダ名称(アドオン：共通・IF領域)
  cv_prf_calender_cd   CONSTANT VARCHAR2(30) := 'XXCMM1_006A04_BUSINS_CAL_CODE';  -- 稼動日カレンダIF出力用営業稼動カレンダコード
-- 2010/04/20 Ver1.1 modify end by Y.Kuboshima

  -- トークン
  cv_tkn_ng_profile    CONSTANT VARCHAR2(30) := 'NG_PROFILE';        -- プロファイル名
  cv_tkn_ng_word       CONSTANT VARCHAR2(30) := 'NG_WORD';           -- 項目名
  cv_tkn_ng_data       CONSTANT VARCHAR2(30) := 'NG_DATA';           -- データ
  cv_tkn_filename      CONSTANT VARCHAR2(30) := 'FILE_NAME';         -- ファイル名
  cv_prf_dir_nm        CONSTANT VARCHAR2(30) := 'CSVファイル出力先';
  cv_prf_fil_nm        CONSTANT VARCHAR2(30) := 'CSVファイル名';
  cv_prf_calender_nm   CONSTANT VARCHAR2(30) := 'カレンダ名称';
  cv_calender_date_nm  CONSTANT VARCHAR2(30) := 'カレンダー日付';

--
  -- ＣＳＶ用固定値
  cc_itoen             CONSTANT CHAR(3)      := '001';              -- 会社コード（001:固定）
  cd_sysdate           DATE                  := SYSDATE;            -- 処理開始時間
  cc_output            CONSTANT CHAR(1)      := 'w';                -- 出力ステータス
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 稼働日カレンダマスタ情報を格納するレコード
  TYPE csv_out_rec  IS RECORD(
       calendar_ymd    CHAR(8),    -- カレンダー日付
       calendar_flg    NUMBER(1)   -- 稼働日フラグ
  );
--
  -- 稼働日カレンダマスタ情報を格納するテーブル型の定義
  TYPE csv_out_tbl  IS TABLE OF csv_out_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_directory      VARCHAR2(255);         -- プロファイル・ファイルパス名
  gv_file_name      VARCHAR2(255);         -- プロファイル・ファイル名
  gv_calender_cd    VARCHAR2(60);          -- プロファイル・カレンダーコード
  gf_file_hand      UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
  gv_csv_file       VARCHAR2(5000);        -- 出力情報
  gt_csv_out_tbl    csv_out_tbl;           -- 結合配列の定義
  gc_del_flg        CHAR(1) := ' ';        -- CSV削除フラグ('1':削除)

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_chk   boolean;   --存在チェック結果
    lv_file_size  number;    --ファイルサイズ
    lv_block_size number;   --ブロックサイズ
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
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --入力パラメータなしメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================
    -- プロファイル取得
    -- ===============================
    -- 稼働日カレンダ連携用CSVファイル出力先取得
    gv_directory := fnd_profile.value(cv_prf_dir);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_directory IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_dir_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 稼働日カレンダ連携用CSVファイル名取得
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_fil_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- 伊藤園営業日用カレンダコード取得
    gv_calender_cd := FND_PROFILE.VALUE(cv_prf_calender_cd);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_calender_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_calender_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --IFファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_file_name
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_file_name
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================
    -- CSVファイル存在チェック
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- ファイル存在時エラー
    IF (lv_file_chk = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_csv_file_err
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- ===============================
    -- 稼働日カレンダ０件チェック
    -- ===============================

    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   bom_calendar_dates bcd
      WHERE  bcd.calendar_code = gv_calender_cd
      AND    ROWNUM = 1;
    EXCEPTION
      -- データなしの場合エラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- CSVファイルオープン処理
    -- ===============================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(
                      gv_directory    -- 出力先
                     ,gv_file_name    -- CSVファイル名
                     ,cc_output       -- 出力ステータス
                     );
    EXCEPTION
      -- ファイルパス不正エラー
      WHEN UTL_FILE.INVALID_PATH THEN
        gn_target_cnt := 0;
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_pass_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;


    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    lv_sep_com      CONSTANT VARCHAR2(1)  := ',';     -- カンマ
    lv_char_dq      CONSTANT VARCHAR2(1)  := '"';     -- ダブルクォーテーション
--
    -- *** ローカル変数 ***
    lc_last_update   CHAR(14); -- 更新日付(YYYYMMDDHH24MISS)
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
    lc_last_update := TO_CHAR(cd_sysdate, 'YYYYMMDDHH24MISS');
--
    <<gt_csv_out_tbl_loop>>
    FOR out_cnt IN 1 .. gn_target_cnt LOOP
      gv_csv_file   := lv_char_dq || cc_itoen || lv_char_dq   -- 会社コード（固定値:"001")
      || lv_sep_com || gt_csv_out_tbl(out_cnt).calendar_ymd   -- カレンダー日付
      || lv_sep_com || gt_csv_out_tbl(out_cnt).calendar_flg   -- 稼働日フラグ
      || lv_sep_com || lc_last_update                         -- 最終更新日時
      ;
--
      BEGIN
      -- CSVファイルへ出力
        UTL_FILE.PUT_LINE(gf_file_hand,gv_csv_file);

      EXCEPTION
        WHEN UTL_FILE.INVALID_OPERATION THEN       -- ファイルアクセス権限エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_file_priv_err
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN UTL_FILE.WRITE_ERROR THEN   -- CSVデータ出力エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_csv_data_err
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_calender_date_nm
                      ,iv_token_name2  => cv_tkn_ng_data
                      ,iv_token_value2 => gt_csv_out_tbl(out_cnt).calendar_ymd
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;

         -- 正常件数
      gn_normal_cnt := gn_normal_cnt + 1;

    END LOOP gt_csv_out_tbl_loop;


    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
--#################################  固定例外処理部 START   ####################################
--
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 稼働日カレンタテーブル取得カーソル
    CURSOR calender_cur
    IS
      SELECT TO_CHAR(bcd.calendar_date,'YYYYMMDD')   calendar_ymd,  -- カレンダー日付
             DECODE(bcd.seq_num,NULL,0,1)            calendar_flg   -- 稼働日フラグ
      FROM   bom_calendar_dates bcd
      WHERE  bcd.calendar_code = gv_calender_cd
      ORDER  BY calendar_ymd;
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
    gc_del_flg    := ' ';
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 稼働日カレンタテーブル情報取得(A-2)
    -- ====================================
--
    OPEN calender_cur;
--
    <<calender_loop>>
    LOOP
      FETCH calender_cur BULK COLLECT INTO gt_csv_out_tbl;
      EXIT WHEN calender_cur%NOTFOUND;

    END LOOP calender_loop;
--
    CLOSE calender_cur;

    gn_target_cnt := gt_csv_out_tbl.COUNT; -- 処理件数

    -- ===============================
    -- CSVファイル出力処理(A-3)
    -- ===============================
    output_csv(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 成功件数なしの場合
    IF (gn_normal_cnt = 0) THEN
      gc_del_flg    := '1';   --CSV削除
    END IF;

    IF (lv_retcode = cv_status_error) THEN
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
      RAISE global_process_expt;
    END IF;

    -- ===============================
    -- 終了処理(A-4)
    -- ===============================

    -- CSVファイルをクローズする
    UTL_FILE.FCLOSE(gf_file_hand);

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
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
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
    cv_prg_name        CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
--
    -- メッセージ番号(共通・IF)
    cv_target_rec_msg  CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
--    cv_skip_rec_msg    CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(30) := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
--    cv_warn_msg        CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック

    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    ln_cvs_cnt      NUMBER;          -- CSV削除フラグ
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

    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );


--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --異常エラー時は、成功件数０件、エラー件数１件と固定表示
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
    END IF;

    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_error_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
--    ELSIF(lv_retcode = cv_status_warn) THEN --警告終了 未使用
--      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    -- CSVファイルを削除する(対象件数があって成功件数が０件の場合)
    IF  (gc_del_flg = '1')  THEN
      UTL_FILE.FREMOVE(gv_directory,   -- 出力先
                       gv_file_name    -- CSVファイル名
      );
    END IF;

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
END XXCMM006A04C;
/
