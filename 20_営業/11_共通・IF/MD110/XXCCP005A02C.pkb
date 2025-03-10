CREATE OR REPLACE PACKAGE BODY XXCCP005A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP005A02C(body)
 * Description      : 営業員ノルマ更新処理
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
 *  2012/09/20    1.0   M.Nagai         [E_本稼動_10054]新規作成
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
  cn_last_updated_by        CONSTANT NUMBER      := 10868;                              --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- スキップ件数
  gv_out_msg                VARCHAR2(2000);
  --例外
  global_api_others_expt    EXCEPTION;
--
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP005A02C';                 -- プログラム名
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,     --   1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2,     --   2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
--
  IS
--
    --CSV項目数
    cn_csv_file_col_num       CONSTANT NUMBER      := 8;                                 -- CSVファイル項目数
    --業務日付
    ld_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date;
    ld_date                   DATE;
    ld_date2                  DATE;
    --固定変数
    lv_errbuf                 VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    --アップロード用変数
    lv_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- ファイルアップロード名称
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSVファイル名
    l_file_data_tab  xxccp_common_pkg2.g_file_data_tbl;           -- 行単位データ格納用配列
    ln_col_num       NUMBER;
    ln_line_cnt      NUMBER;
    ln_column_cnt    NUMBER;
    ln_file_id       NUMBER  := TO_NUMBER(iv_file_id);
    ln_seq           NUMBER  := 0;
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    --1次元配列（項目）
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER; --2次元配列（レコード）（項目）
    ln_cnt           NUMBER  := 1; --ループカウンタ
    lt_path_data_tab  gt_rec_data_ttype;
    lv_exec_flag     VARCHAR2(1);
    lv_err_flg       VARCHAR2(1)  DEFAULT 'N';
--
    --営業員別月別計画更新データカーソル
    CURSOR data_cur
    IS
      SELECT   xdpw.execute_mode                execute_mode  --実行モード
              ,xdpw.condition_1                 condition_1   --条件１（拠点）
              ,xdpw.condition_2                 condition_2   --条件２（営業員ＣＤ）
              ,xdpw.condition_3                 condition_3   --条件３（年月）
              ,xdpw.condition_4                 condition_4   --条件４（年度)
              ,xdpw.num_column_1                num_column_1  --変更値１（基本売上）
              ,xdpw.num_column_2                num_column_2  --変更値２（目標売上）
              ,xdpw.num_column_3                num_column_3  --変更値３（訪問）
              ,xspmp.sls_prsn_mnthly_pln_id     sls_prsn_mnthly_pln_id    --テーブル更新キー(ID）
              ,xspmp.bsc_sls_prsn_total_amt     bsc_sls_prsn_total_amt    --更新前（基本売上）
              ,xspmp.tgt_sales_prsn_total_amt   tgt_sales_prsn_total_amt  --更新前（目標売上）
              ,xspmp.vis_prsn_total_amt         vis_prsn_total_amt        --更新前（訪問）
              ,xspmp.last_updated_by            last_updated_by           --更新前最終（更新者）
              ,TO_CHAR(xspmp.last_update_date,'YYYY/MM/DD HH24:MI:SS')
                                                last_update_date          --更新前（最終更新日）
              ,xspmp.last_update_login          last_update_login         --更新前（最終更新ログイン）
              ,xspmp.request_id                 request_id                --更新前（要求ID）
              ,xspmp.program_application_id     program_application_id    --更新前（ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID）
              ,xspmp.program_id                 program_id                --更新前（ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID）
              ,TO_CHAR(xspmp.program_update_date,'YYYY/MM/DD HH24:MI:SS')
                                                program_update_date       --更新前（ﾌﾟﾛｸﾞﾗﾑ更新日）
      FROM     xxccp_data_patch_work      xdpw
              ,xxcso_sls_prsn_mnthly_plns xspmp
      WHERE    xdpw.file_id       = ln_file_id
      AND      xdpw.condition_1   = xspmp.base_code(+)
      AND      xdpw.condition_2   = xspmp.employee_number(+)
      AND      xdpw.condition_3   = xspmp.year_month(+)
      AND      xdpw.condition_4   = xspmp.fiscal_year(+)
      ORDER BY
               xdpw.data_sequence
      ;
--
    data_rec data_cur%ROWTYPE;
--
  BEGIN
--
    -- ファイルID出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'ファイルID                    ：'||iv_file_id
    );
    -- フォーマットパターン出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'パラメータフォーマットパターン：'||iv_fmt_ptn
    );
    -- ファイルアップロード名称出力
    SELECT flv.meaning meaning
    INTO   lv_file_ul_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type = 'XXCCP1_FILE_UPLOAD_OBJ'
    AND    flv.lookup_code = iv_fmt_ptn
    AND    flv.language    = 'JA'
    AND    flv.enabled_flag = 'Y'
    AND    ld_process_date BETWEEN TRUNC(flv.start_date_active) 
                           AND     NVL(flv.end_date_active, ld_process_date)
    ;
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'ファイルアップロード名称      ：'||lv_file_ul_name
    );
    -- ファイル名出力
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
    /************************************/
    /*       アップロードデータ取得     */
    /************************************/
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => ln_file_id       -- ファイルID
      ,ov_file_data => l_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (l_file_data_tab.COUNT <= 1 ) THEN
      lv_errbuf := '対象0件エラー';
      RAISE global_api_others_expt;
    END IF;
--
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --項目数取得
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
         lv_errbuf := '項目数不正エラー';
         RAISE global_api_others_expt;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割
          lt_path_data_tab(ln_line_cnt)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                             iv_char     => l_file_data_tab(ln_line_cnt)
                                                            ,iv_delim    => ','
                                                            ,in_part_num => ln_column_cnt
                                                          );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    <<ins_line_loop>>
    FOR ln_line_cnt IN 2 .. lt_path_data_tab.COUNT LOOP
      --データシーケンス採番
      ln_seq := ln_seq + 1;
      --パッチ用テーブル登録
      INSERT INTO xxccp_data_patch_work (
         file_id
        ,data_sequence
        ,execute_mode
        ,condition_1
        ,condition_2
        ,condition_3
        ,condition_4
        ,num_column_1
        ,num_column_2
        ,num_column_3
      ) VALUES (
         ln_file_id                                                -- ファイルID
        ,ln_seq                                                    -- データシーケンス
        ,lt_path_data_tab(ln_line_cnt)(1)                          -- 実行モード
        ,lt_path_data_tab(ln_line_cnt)(2)                          -- 条件値１
        ,lt_path_data_tab(ln_line_cnt)(3)                          -- 条件値２
        ,lt_path_data_tab(ln_line_cnt)(4)                          -- 条件値３
        ,lt_path_data_tab(ln_line_cnt)(5)                          -- 条件値４
        ,lt_path_data_tab(ln_line_cnt)(6)                          -- 変更値１
        ,lt_path_data_tab(ln_line_cnt)(7)                          -- 変更値２
        ,lt_path_data_tab(ln_line_cnt)(8)                          -- 変更値３
      )
      ;
      --対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP ins_line_loop;
--
    --ファイルIFデータ削除
    DELETE FROM xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = ln_file_id
    ;
--
    lt_path_data_tab.DELETE;
--
    /************************************/
    /*         データ更新処理           */
    /************************************/
--
     --ヘッダ出力
     fnd_file.put_line(
        which  => FND_FILE.OUTPUT
       ,buff   =>    '"'|| 'base_code'                      ||'","'||
                           'employee_number'                ||'","'||
                           'year_month'                     ||'","'||
                           'fiscal_year'                    ||'","'||
                           'bsc_sls_prsn_total_amt'         ||'","'||
                           'after_value'                    ||'","'||
                           'tgt_sales_prsn_total_amt'       ||'","'||
                           'after_value'                    ||'","'||
                           'vis_prsn_total_amt'             ||'","'||
                           'after_value'                    ||'","'||
                           'last_updated_by'                ||'","'||
                           'after_value'                    ||'","'||
                           'last_update_date'               ||'","'||
                           'after_value'                    ||'","'||
                           'last_update_login'              ||'","'||
                           'after_value'                    ||'","'||
                           'request_id'                     ||'","'||
                           'after_value'                    ||'","'||
                           'program_application_id'         ||'","'||
                           'after_value'                    ||'","'||
                           'program_id'                     ||'","'||
                           'after_value'                    ||'","'||
                           'program_update_date'            ||'","'||
                           'after_value'                    ||'"'
     );
--
    --対象データ抽出
    OPEN data_cur;
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      --エラーフラグ初期化
      lv_err_flg := 'N';
--
      --１行目の実行モードを取得
      IF ( ln_cnt = 1 ) THEN
        --実行モードチェック
        IF ( data_rec.execute_mode IS NULL )
          OR( ( data_rec.execute_mode <> '0' )
            AND ( data_rec.execute_mode <> '1' ) ) THEN
           lv_errbuf := '実行モードには0(対象確認)または1(データ更新)の値を入力して下さい。';
           RAISE global_api_others_expt;
        END IF;
        --
        lv_exec_flag := data_rec.execute_mode;
        ln_cnt       := ln_cnt + 1;
      END IF;
--
      BEGIN
        --年月型チェック
        ld_date  := TO_DATE (data_rec.condition_3,'YYYY/MM');
        --年度型チェック
        ld_date2 := TO_DATE (data_rec.condition_4,'YYYY');
      EXCEPTION
        WHEN OTHERS THEN
          --フラグをYに設定
          lv_err_flg := 'Y';
      END;
--
      IF ( lv_err_flg = 'Y' ) THEN
        --警告ログ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
           ,buff  =>    '"'|| data_rec.condition_1              || '","'
                           || data_rec.condition_2              || '","'
                           || data_rec.condition_3              || '","'
                           || data_rec.condition_4              || '","'
                           || data_rec.bsc_sls_prsn_total_amt   || '","'
                           || data_rec.num_column_1             || '","'
                           || data_rec.tgt_sales_prsn_total_amt || '","'
                           || data_rec.num_column_2             || '","'
                           || data_rec.vis_prsn_total_amt       || '","'
                           || data_rec.num_column_3             || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || '型が不正です'                    || '"'
         );
        -- 警告件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      --データ存在チェック
      IF ( ( lv_err_flg <> 'Y' )AND (data_rec.sls_prsn_mnthly_pln_id IS NULL ) )THEN
        -- 警告ログ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>    '"'|| data_rec.condition_1              || '","'
                           || data_rec.condition_2              || '","'
                           || data_rec.condition_3              || '","'
                           || data_rec.condition_4              || '","'
                           || data_rec.bsc_sls_prsn_total_amt   || '","'
                           || data_rec.num_column_1             || '","'
                           || data_rec.tgt_sales_prsn_total_amt || '","'
                           || data_rec.num_column_2             || '","'
                           || data_rec.vis_prsn_total_amt       || '","'
                           || data_rec.num_column_3             || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || ''                                || '","'
                           || '該当のデータが存在しません'      || '"'
        );
        lv_err_flg := 'Y';
        -- 警告件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      IF ( lv_err_flg <> 'Y' ) THEN
        --変更前更新後確認用データ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>    '"'|| data_rec.condition_1              || '","'
                           || data_rec.condition_2              || '","' 
                           || data_rec.condition_3              || '","'
                           || data_rec.condition_4              || '","'
                           || data_rec.bsc_sls_prsn_total_amt   || '","'
                           || data_rec.num_column_1             || '","'
                           || data_rec.tgt_sales_prsn_total_amt || '","'
                           || data_rec.num_column_2             || '","'
                           || data_rec.vis_prsn_total_amt       || '","'
                           || data_rec.num_column_3             || '","'
                           || data_rec.last_updated_by          || '","'
                           || cn_last_updated_by                || '","'
                           || data_rec.last_update_date         || '","'
                           || TO_CHAR(cd_last_update_date,'YYYY/MM/DD HH24:MI:SS')
                                                                || '","'
                           || data_rec.last_update_login        || '","'
                           || cn_last_update_login              || '","'
                           || data_rec.request_id               || '","'
                           || cn_request_id                     || '","'
                           || data_rec.program_application_id   || '","'
                           || cn_program_application_id         || '","'
                           || data_rec.program_id               || '","'
                           || cn_program_id                     || '","'
                           || data_rec.program_update_date      || '","'
                           || TO_CHAR(cd_program_update_date,'YYYY/MM/DD HH24:MI:SS')
                                                                || '"'
        );
      END IF;
--
      --正常データで実行モードが更新の場合のみ
      IF ( ( lv_err_flg <> 'Y' ) AND ( lv_exec_flag = '1' ) )  THEN
        --★営業員計画表データ更新
        UPDATE xxcso_sls_prsn_mnthly_plns xspmp
        SET    xspmp.bsc_sls_prsn_total_amt     = data_rec.num_column_1     --基本売上
              ,xspmp.tgt_sales_prsn_total_amt   = data_rec.num_column_2     --目標売上
              ,xspmp.vis_prsn_total_amt         = data_rec.num_column_3     --訪問
              ,xspmp.last_updated_by            = cn_last_updated_by        --固定
              ,xspmp.last_update_date           = cd_last_update_date       --固定
              ,xspmp.last_update_login          = cn_last_update_login      --固定
              ,xspmp.request_id                 = cn_request_id             --固定
              ,xspmp.program_application_id     = cn_program_application_id --固定
              ,xspmp.program_id                 = cn_program_id             --固定
              ,xspmp.program_update_date        = cd_program_update_date    --固定
        WHERE  xspmp.sls_prsn_mnthly_pln_id     = data_rec.sls_prsn_mnthly_pln_id
        ;
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP;
--
    CLOSE data_cur;
--
    --ワークテーブル削除
    DELETE FROM xxccp_data_patch_work xdpw
    WHERE  xdpw.file_id = ln_file_id
    ;
--
    --警告が１件以上存在した場合、ステータスを警告にする
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id
      ;
      COMMIT;    --データ削除のコミット
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id
      ;
      --ワークテーブル削除
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id
      ;
      COMMIT;    --データ削除のコミット
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
--
--
--###########################  固定部 START   ###########################
--
  IS
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
      RAISE global_api_others_expt;
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
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      --成功件数クリア
      gn_normal_cnt := 0;
      --スキップ件数クリア
      gn_warn_cnt   := 0;
      --エラー件数
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
END XXCCP005A02C;
/
