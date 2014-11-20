CREATE OR REPLACE PACKAGE BODY XXCCP005A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP005A03C(body)
 * Description      : 営業員ノルマ登録処理
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
  cn_last_update_login      CONSTANT NUMBER      := -1;                                 --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := -1;                                 --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := -1;                                 --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := -1;                                 --PROGRAM_ID
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP005A03C';                 -- プログラム名
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
    cn_csv_file_col_num       CONSTANT NUMBER      := 10;                                 -- CSVファイル項目数
    --業務日付
    ld_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date;
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
    lt_path_data_tab  gt_rec_data_ttype;
    --処理固有の変数
    ld_date          DATE;                --日付型チェック用
    lv_err_flg       VARCHAR2(1) := 'N';  --警告チェック用
    ln_cnt           NUMBER      := '1';  --1行目の実行モード取得用
    lv_exec_flag     VARCHAR2(1);         --1行目の実行モード
    ln_dummy         NUMBER;              --存在チェック用
--
    --営業員別月別計画登録データカーソル
    CURSOR data_cur
    IS
      SELECT   xdpw.execute_mode    execute_mode  --実行モード
              ,xdpw.condition_1     condition_1   --条件１（拠点）
              ,xdpw.condition_2     condition_2   --条件２（営業員ＣＤ）
              ,xdpw.condition_3     condition_3   --条件３（年月）
              ,xdpw.condition_4     condition_4   --条件４（年度)
              ,xdpw.num_column_1    num_column_1  --変更値NUM１（基本売上）
              ,xdpw.num_column_2    num_column_2  --変更値NUM２（目標売上）
              ,xdpw.num_column_3    num_column_3  --変更値NUM３（訪問）
              ,xdpw.chr_column_1    chr_column_1  --変更値CHAR１（入力区分）
              ,xdpw.chr_column_2    chr_column_2  --変更値CHAR２（データ最終更新機能区分）
      FROM     xxccp_data_patch_work xdpw
      WHERE    xdpw.file_id       = ln_file_id
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
        ,chr_column_1
        ,num_column_1
        ,num_column_2
        ,num_column_3
        ,chr_column_2
      ) VALUES (
         ln_file_id                                 -- ファイルID
        ,ln_seq                                     -- データシーケンス
        ,lt_path_data_tab(ln_line_cnt)(1)           -- 実行モード
        ,lt_path_data_tab(ln_line_cnt)(2)           -- 条件値１（拠点）
        ,lt_path_data_tab(ln_line_cnt)(3)           -- 条件値２（営業員CD）
        ,lt_path_data_tab(ln_line_cnt)(4)           -- 条件値３（年月）
        ,lt_path_data_tab(ln_line_cnt)(5)           -- 条件値４（年度）
        ,lt_path_data_tab(ln_line_cnt)(6)           -- 変更値CHAR１（入力区分）
        ,lt_path_data_tab(ln_line_cnt)(7)           -- 変更値NUM１（基本売上）
        ,lt_path_data_tab(ln_line_cnt)(8)           -- 変更値NUM２（目標売上）
        ,lt_path_data_tab(ln_line_cnt)(9)           -- 変更値NUM３（訪問）
        ,lt_path_data_tab(ln_line_cnt)(10)          -- 変更値CHAR２（データ最終更新機能区分）
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
    /*         データ登録処理           */
    /************************************/
     --ヘッダ出力
     fnd_file.put_line(
        which  => FND_FILE.OUTPUT
       ,buff   =>  '"'||  'base_code'                       ||'","'||
                          'employee_number'                 ||'","'||
                          'year_month'                      ||'","'||
                          'fiscal_year'                     ||'","'||
                          'input_type'                      ||'","'||
                          'bsc_sls_prsn_total_amt'          ||'","'||
                          'tgt_sales_prsn_total_amt'        ||'","'||
                          'vis_prsn_total_amt'              ||'","'||
                          'data_last_update_func_type'      ||'","'||
                          'created_by'                      ||'","'||
                          'creation_date'                   ||'","'||
                          'last_updated_by'                 ||'","'||
                          'last_update_date'                ||'","'||
                          'last_update_login'               ||'","'||
                          'request_id'                      ||'","'||
                          'program_application_id'          ||'","'||
                          'program_id'                      ||'","'||
                          'program_update_date'             ||'"'
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
        ln_cnt       := ln_cnt + 1; --2行目以降は取得しない
      END IF;
--
      BEGIN
        --年月型チェック
        ld_date  := TO_DATE (data_rec.condition_3,'YYYY/MM');
        --年度型チェック
        ld_date  := TO_DATE (data_rec.condition_4,'YYYY');
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
           ,buff  =>  '"'|| data_rec.condition_1              || '","'  --拠点コード
                         || data_rec.condition_2              || '","'  --営業員CD
                         || data_rec.condition_3              || '","'  --年月
                         || data_rec.condition_4              || '","'  --年度
                         || data_rec.chr_column_1             || '","'  --入力区分
                         || TO_CHAR(data_rec.num_column_1)    || '","'  --基本計画
                         || TO_CHAR(data_rec.num_column_2)    || '","'  --目標計画
                         || TO_CHAR(data_rec.num_column_3)    || '","'  --訪問計画
                         || data_rec.chr_column_2             || '","'  --データ最終更新機能区分
                         || ''                                || '","'  --作成者
                         || ''                                || '","'  --作成日
                         || ''                                || '","'  --最終更新者
                         || ''                                || '","'  --最終更新日
                         || ''                                || '","'  --最終ログイン
                         || ''                                || '","'  --要求ID
                         || ''                                || '","'  --プログラムアプリケーションID
                         || ''                                || '","'  --プログラムID
                         || ''                                || '","'  --プログラム更新日
                         || '型が不正です。'                            --警告メッセージ
        );
        -- 警告件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      --データ存在チェック
      IF ( lv_err_flg <> 'Y' ) THEN
--
        BEGIN
          SELECT xspmp.sls_prsn_mnthly_pln_id
          INTO   ln_dummy
          FROM   xxcso_sls_prsn_mnthly_plns xspmp
          WHERE  xspmp.base_code       = data_rec.condition_1
          AND    xspmp.employee_number = data_rec.condition_2
          AND    xspmp.year_month      = data_rec.condition_3
          AND    xspmp.fiscal_year     = data_rec.condition_4
          ;
          -- 既に登録がある場合警告ログ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
             ,buff  =>  '"'|| data_rec.condition_1            || '","'  --拠点コード
                           || data_rec.condition_2            || '","'  --営業員CD
                           || data_rec.condition_3            || '","'  --年月
                           || data_rec.condition_4            || '","'  --年度
                           || data_rec.chr_column_1           || '","'  --入力区分
                           || TO_CHAR(data_rec.num_column_1)  || '","'  --基本計画
                           || TO_CHAR(data_rec.num_column_2)  || '","'  --目標計画
                           || TO_CHAR(data_rec.num_column_3)  || '","'  --訪問計画
                           || data_rec.chr_column_2           || '","'  --データ最終更新機能区分
                           || ''                              || '","'  --作成者
                           || ''                              || '","'  --作成日
                           || ''                              || '","'  --最終更新者
                           || ''                              || '","'  --最終更新日
                           || ''                              || '","'  --最終ログイン
                           || ''                              || '","'  --要求ID
                           || ''                              || '","'  --プログラムアプリケーションID
                           || ''                              || '","'  --プログラムID
                           || ''                              || '","'  --プログラム更新日
                           || '該当のデータが存在します。'             --警告メッセージ
          );
          lv_err_flg := 'Y';
          -- 警告件数カウント
          gn_warn_cnt := gn_warn_cnt + 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;  --登録なし(正常)
        END;
--
      END IF;
--
      IF ( lv_err_flg <> 'Y' ) THEN
        --登録後確認用データ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>  '"'|| data_rec.condition_1                                     || '","'  --拠点コード
                         || data_rec.condition_2                                     || '","'  --営業員CD
                         || data_rec.condition_3                                     || '","'  --年月
                         || data_rec.condition_4                                     || '","'  --年度
                         || data_rec.chr_column_1                                    || '","'  --入力区分
                         || TO_CHAR(data_rec.num_column_1)                           || '","'  --基本計画
                         || TO_CHAR(data_rec.num_column_2)                           || '","'  --目標計画
                         || TO_CHAR(data_rec.num_column_3)                           || '","'  --訪問計画
                         || data_rec.chr_column_2                                    || '","'  --データ最終更新機能区分
                         || TO_CHAR(cn_last_updated_by)                              || '","'  --作成者
                         || TO_CHAR(cd_last_update_date,'YYYY/MM/DD HH24:MI:SS')     || '","'  --作成日
                         || TO_CHAR(cn_last_updated_by)                              || '","'  --最終更新者
                         || TO_CHAR(cd_last_update_date,'YYYY/MM/DD HH24:MI:SS')     || '","'  --最終更新日
                         || TO_CHAR(cn_last_update_login)                            || '","'  --最終ログイン
                         || TO_CHAR(cn_last_updated_by)                              || '","'  --要求ID
                         || TO_CHAR(cn_program_application_id)                       || '","'  --プログラムアプリケーションID
                         || TO_CHAR(cn_program_id)                                   || '","'  --プログラムID
                         || TO_CHAR(cd_program_update_date,'YYYY/MM/DD HH24:MI:SS')  || '"'    --プログラム更新日
        );
      END IF;
--
      --正常データで実行モードが更新の場合のみ
      IF ( ( lv_err_flg <> 'Y' ) AND ( lv_exec_flag = '1' ) )  THEN
--
        --営業員計画表データ登録
        INSERT INTO xxcso_sls_prsn_mnthly_plns (
            sls_prsn_mnthly_pln_id
           ,base_code
           ,employee_number
           ,year_month
           ,fiscal_year
           ,input_type
           ,bsc_sls_prsn_total_amt
           ,tgt_sales_prsn_total_amt
           ,vis_prsn_total_amt
           ,data_last_update_func_type
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login
           ,request_id
           ,program_application_id
           ,program_id
           ,program_update_date
        ) VALUES (
            xxcso_sls_prsn_mnthly_plns_s01.nextval       --内部ID
           ,data_rec.condition_1                         --拠点コード
           ,data_rec.condition_2                         --営業員CD
           ,data_rec.condition_3                         --年月
           ,data_rec.condition_4                         --年度
           ,data_rec.chr_column_1                        --入力区分
           ,data_rec.num_column_1                        --基本計画
           ,data_rec.num_column_2                        --目標計画
           ,data_rec.num_column_3                        --訪問計画
           ,data_rec.chr_column_2                        --データ最終更新機能区分
           ,cn_last_updated_by                           --作成者
           ,cd_last_update_date                          --作成日
           ,cn_last_updated_by                           --最終更新者
           ,cd_last_update_date                          --最終更新日
           ,cn_last_update_login                         --最終ログイン
           ,cn_last_updated_by                           --要求ID
           ,cn_program_application_id                    --プログラムアプリケーションID
           ,cn_program_id                                --プログラムID
           ,cd_program_update_date                       --プログラム更新日
        )
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
END XXCCP005A03C;
/
