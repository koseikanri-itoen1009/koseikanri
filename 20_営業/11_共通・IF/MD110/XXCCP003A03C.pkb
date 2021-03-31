CREATE OR REPLACE PACKAGE BODY XXCCP003A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP003A03C(body)
 * Description      : 問屋請求書削除アップロード処理
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/20    1.0   SCSK Y.Koh       [E_本稼動_16026]新規作成
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
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP003A03C';                 -- プログラム名
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                            -- Y
  --プロファイル
  cv_all_base_allowed       CONSTANT VARCHAR2(100) := 'XXCOK1_WHOLESALE_INVOICE_UPLOAD_ALL_BASE_ALLOWED';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_user_dept_code         VARCHAR2(100) DEFAULT NULL;                               --ユーザ担当拠点
  gv_all_base_allowed       VARCHAR2(1);                                              --カスタム･プロファイル取得変数
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,     --   1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2,     --   2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
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
    --参照タイプ用変数
    cv_lookup_fo              CONSTANT VARCHAR2(25) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_lang                   CONSTANT VARCHAR2(2)  := USERENV('LANG');
    --CSV項目数
    cn_csv_file_col_num       CONSTANT NUMBER       := 15;            -- CSVファイル項目数
--
    -- *** ローカル変数 ***
    --業務日付
    ld_process_date           CONSTANT DATE         := xxccp_common_pkg2.get_process_date;
    --アップロード用変数
    lv_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- ファイルアップロード名称
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSVファイル名
    l_file_data_tab  xxccp_common_pkg2.g_file_data_tbl;           -- 行単位データ格納用配列
    ln_col_num       NUMBER;                                      -- 項目数取得用
    ln_line_cnt      NUMBER;                                      -- CSVファイル各行参照用カウンタ
    ln_column_cnt    NUMBER;                                      -- CSVファイル各列参照用カウンタ
    ln_file_id       NUMBER  := TO_NUMBER(iv_file_id);            -- ファイルID
    ln_cnt           NUMBER  := 1;                                -- ループカウンタ
    ln_data_cnt      NUMBER;                                      -- データ件数用カウンタ
    --アップロードデータ格納用変数
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    -- 1次元配列（項目）
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER; -- 2次元配列（レコード）（項目）
    lt_delete_data_tab  gt_rec_data_ttype;
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
    --==============================================================
    -- コンカレントパラメータ出力
    --==============================================================
    -- ファイルID出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'ファイルID                    ：' || iv_file_id
    );
    -- フォーマットパターン出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'パラメータフォーマットパターン：' || iv_fmt_ptn
    );
--
    --==============================================================
    -- ファイルアップロード名称出力
    --==============================================================
    SELECT flv.meaning meaning
    INTO   lv_file_ul_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_fo
    AND    flv.lookup_code  = iv_fmt_ptn
    AND    flv.language     = cv_lang
    AND    flv.enabled_flag = cv_flag_y
    AND    ld_process_date BETWEEN flv.start_date_active 
                           AND     NVL(flv.end_date_active, ld_process_date)
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'ファイルアップロード名称      ：'||lv_file_ul_name
    );
--
    --==============================================================
    -- ファイル名出力
    --==============================================================
    SELECT  xmfui.file_name file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'ファイル名                    ：'||lv_file_name
    );
--
    --改行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- =============================================================================
    -- プロファイルを取得(全拠点許可フラグ)
    -- =============================================================================
    gv_all_base_allowed := FND_PROFILE.VALUE( cv_all_base_allowed );
--
    IF ( gv_all_base_allowed IS NULL ) THEN
      lv_errbuf := 'プロファイル(全拠点許可フラグ)が取得できませんでした。';
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- ユーザの所属部門を取得
    -- =============================================================================
    gv_user_dept_code := xxcok_common_pkg.get_department_code_f(
                           in_user_id => cn_last_updated_by
                         );
--
    IF ( gv_user_dept_code IS NULL ) THEN
      lv_errbuf := 'ユーザの所属部門が取得できませんでした。';
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- アップロードデータ取得
    --==============================================================
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => ln_file_id       -- ファイルID
      ,ov_file_data => l_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    --タイトル行は除外、データ行から取得する
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --項目数取得
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        lv_errbuf := '['|| ln_line_cnt || '行目] アップロードファイルの項目数に過不足があります。';
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      ELSE
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割
          lt_delete_data_tab(ln_line_cnt)(ln_column_cnt)  := xxccp_common_pkg.char_delim_partition(
                                                                 iv_char     => l_file_data_tab(ln_line_cnt)
                                                                ,iv_delim    => ','
                                                                ,in_part_num => ln_column_cnt
                                                            );
          --ダブルクォーテーション削除
          lt_delete_data_tab(ln_line_cnt)(ln_column_cnt) := REPLACE(lt_delete_data_tab(ln_line_cnt)(ln_column_cnt),'"');
        END LOOP;
        --削除対象件数カウント
        IF  ln_line_cnt > 1 AND lt_delete_data_tab(ln_line_cnt)(01) = '削除'  THEN
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
      END IF;
    END LOOP;
--
    --削除データなし
    IF  gn_target_cnt = 0 THEN
      lv_errbuf := 'アップロードファイルに削除データがありません。';
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    --項目チェック
    FOR ln_line_cnt IN 2 .. lt_delete_data_tab.COUNT LOOP
--
      IF  lt_delete_data_tab(ln_line_cnt)(01) = '削除'  THEN
        --拠点チェック
        IF  gv_all_base_allowed = 'N' AND lt_delete_data_tab(ln_line_cnt)(02) <>  gv_user_dept_code THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => '['|| ln_line_cnt || '行目] 指定した拠点のデータは削除できません。'
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          CONTINUE;
        END IF;
--
        --削除データ存在チェック
        SELECT  COUNT(*)
        INTO    ln_data_cnt
        FROM    xxcok_wholesale_bill_line xwbl
        WHERE   xwbl.wholesale_bill_header_id IN
                ( SELECT  xwbh.wholesale_bill_header_id
                  FROM    xxcok_wholesale_bill_head xwbh
                  WHERE   base_code           =   lt_delete_data_tab(ln_line_cnt)(02)
                  AND     cust_code           =   lt_delete_data_tab(ln_line_cnt)(08)
                  AND     supplier_code       =   lt_delete_data_tab(ln_line_cnt)(04)
                  AND     expect_payment_date =   TO_DATE(lt_delete_data_tab(ln_line_cnt)(06),'YYYY/MM/DD') )
        AND     xwbl.bill_no                  =   lt_delete_data_tab(ln_line_cnt)(10)
        AND     xwbl.status                   IS  NULL
        AND     xwbl.recon_slip_num           IS  NULL;
--
        IF  ln_data_cnt = 0 THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => '['|| ln_line_cnt || '行目] 指定した請求書は存在しないか支払処理済です。'
          );
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
      END IF;
--
    END LOOP;
--
    --==============================================================
    -- 請求書データ削除
    --==============================================================
    IF  gn_warn_cnt > 0 THEN
      --警告が１件以上存在した場合、ステータスを警告にする
      ov_retcode := cv_status_warn;
    ELSE
      --警告がない場合、請求書データを削除する
      FOR ln_line_cnt IN 1 .. lt_delete_data_tab.COUNT LOOP
        IF  lt_delete_data_tab(ln_line_cnt)(01) = '削除'  THEN
          UPDATE  xxcok_wholesale_bill_line xwbl
          SET     xwbl.status             = 'D'                       ,
                  last_updated_by         = cn_last_updated_by        ,
                  last_update_date        = cd_last_update_date       ,
                  last_update_login       = cn_last_update_login      ,
                  request_id              = cn_request_id             ,
                  program_application_id  = cn_program_application_id ,
                  program_id              = cn_program_id             ,
                  program_update_date     = cd_program_update_date
          WHERE   xwbl.wholesale_bill_header_id IN
                  ( SELECT  xwbh.wholesale_bill_header_id
                    FROM    xxcok_wholesale_bill_head xwbh
                    WHERE   base_code           =   lt_delete_data_tab(ln_line_cnt)(02)
                    AND     cust_code           =   lt_delete_data_tab(ln_line_cnt)(08)
                    AND     supplier_code       =   lt_delete_data_tab(ln_line_cnt)(04)
                    AND     expect_payment_date =   TO_DATE(lt_delete_data_tab(ln_line_cnt)(06),'YYYY/MM/DD') )
          AND     xwbl.bill_no                  =   lt_delete_data_tab(ln_line_cnt)(10)
          AND     xwbl.status                   IS  NULL
          AND     xwbl.recon_slip_num           IS  NULL;
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END LOOP;
    END IF;
--
    --==============================================================
    -- ファイルIFデータ削除
    --==============================================================
    DELETE FROM xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = ln_file_id;
--
    lt_delete_data_tab.DELETE;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id;
      --データ削除のコミット
      COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id;
      --データ削除のコミット
      COMMIT;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_id    IN  VARCHAR2,      -- 1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2       -- 2.フォーマットパターン
  )
  IS
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_file_id  -- 1.ファイルID
      ,iv_fmt_ptn  -- 2.フォーマットパターン
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
    WHEN global_process_expt THEN
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
END XXCCP003A03C;
/
