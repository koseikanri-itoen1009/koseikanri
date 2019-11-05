create or replace
PACKAGE BODY XXCCP008A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A07C(body)
 * Description      : 資産移管修正アップロード処理
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 * Name                      Description
 * ------------------------- ------------------------------------------------------------
 * chk_period                会計期間チェック
 * submain                   メイン処理プロシージャ
 * main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 * Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2019/10/17    1.0   Y.Ohishi         E_本稼動_15982  新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal            CONSTANT  VARCHAR2(1) := xxccp_common_pkg.set_status_normal;     --正常:0
  cv_status_warn              CONSTANT  VARCHAR2(1) := xxccp_common_pkg.set_status_warn;       --警告:1
  cv_status_error             CONSTANT  VARCHAR2(1) := xxccp_common_pkg.set_status_error;      --異常:2
  --WHOカラム
  cn_created_by               CONSTANT  NUMBER      := fnd_global.user_id;                --CREATED_BY
  cd_creation_date            CONSTANT  DATE        := SYSDATE;                           --CREATION_DATE
  cn_last_updated_by          CONSTANT  NUMBER      := fnd_global.user_id;                --LAST_UPDATED_BY
  cd_last_update_date         CONSTANT  DATE        := SYSDATE;                           --LAST_UPDATE_DATE
  cn_last_update_login        CONSTANT  NUMBER      := fnd_global.login_id;               --LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT  NUMBER      := fnd_global.conc_request_id;        --REQUEST_ID
  cn_program_application_id   CONSTANT  NUMBER      := fnd_global.prog_appl_id;           --PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT  NUMBER      := fnd_global.conc_program_id;        --PROGRAM_ID
  cd_program_update_date      CONSTANT  DATE        := SYSDATE;                           --PROGRAM_UPDATE_DATE
  cv_msg_part                 CONSTANT  VARCHAR2(3) := ' : ';
  cv_msg_cont                 CONSTANT  VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                            VARCHAR2(2000);
  gn_target_cnt                         NUMBER;                                 -- 対象件数
  gn_normal_cnt                         NUMBER;                                 -- 正常件数
  gn_error_cnt                          NUMBER;                                 -- エラー件数
  gn_warn_cnt                           NUMBER;                                 -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
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
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCCP008A07C';        -- プログラム名
  cv_flag_y                   CONSTANT  VARCHAR2(1)   := 'Y';                   -- Y
  cv_flag_n                   CONSTANT  VARCHAR2(1)   := 'N';                   -- N
  -- 日付書式
  cv_date_format_1            CONSTANT  VARCHAR2(8)   := 'YYYYMMDD';            -- 入力
  cv_date_format_2            CONSTANT  VARCHAR2(7)   := 'YYYY-MM';             -- 会計期間
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;                                             -- 業務日付
  gt_chart_of_account_id      gl_sets_of_books.chart_of_accounts_id%TYPE;       -- 科目体系ID
  gt_application_short_name   fnd_application.application_short_name%TYPE;      -- GLアプリケーション短縮名
  gt_id_flex_code             fnd_id_flex_structures_vl.id_flex_code%TYPE;      -- キーフレックスコード
  -- 初期値情報
  g_init_rec                  xxcff_common1_pkg.init_rtype;
  -- アプリケーション短縮名
  cv_msg_kbn_cff              CONSTANT  VARCHAR2(5)   := 'XXCFF';               -- アドオン：共通・IF領域
  -- メッセージ名
  cv_msg_name_00258           CONSTANT  VARCHAR2(20)  := 'APP-XXCFF1-00258';    -- 共通関数エラー
  cv_msg_name_50130           CONSTANT  VARCHAR2(20)  := 'APP-XXCFF1-50130';    -- 初期処理
  -- トークン名
  cv_tkn_func_name            CONSTANT  VARCHAR2(100) := 'FUNC_NAME';           -- 共通関数名
  cv_tkn_info                 CONSTANT  VARCHAR2(100) := 'INFO';                -- 詳細情報
  cv_tkn_line_no              CONSTANT  VARCHAR2(100) := 'LINE_NO';             -- 行番号
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  --アップロードデータカーソル
  CURSOR data_cur( in_file_id NUMBER )
  IS
    SELECT    xdpw.file_id              file_id                                 -- ファイルID
             ,xdpw.data_sequence        data_sequence                           -- データシーケンス
             ,xdpw.condition_1          condition_1                             -- 条件1(資産番号)
             ,xdpw.condition_2          condition_2                             -- 条件2(台帳)
             ,xdpw.chr_column_1         chr_column_1                            -- 文字値1(振替日)
             ,xdpw.chr_column_2         chr_column_2                            -- 文字値2(部門コード)
             ,xdpw.chr_column_3         chr_column_3                            -- 文字値3(勘定科目)
             ,xdpw.chr_column_4         chr_column_4                            -- 文字値4(補助科目)
             ,xdpw.chr_column_5         chr_column_5                            -- 文字値5(申告地)
             ,xdpw.chr_column_6         chr_column_6                            -- 文字値6(部門)
             ,xdpw.chr_column_7         chr_column_7                            -- 文字値7(事業所)
             ,xdpw.chr_column_8         chr_column_8                            -- 文字値8(場所)
             ,xdpw.chr_column_9         chr_column_9                            -- 文字値9(本社工場区分)
    FROM     xxccp_data_patch_work      xdpw
    WHERE    xdpw.file_id = in_file_id
    ORDER BY xdpw.data_sequence;
--
  data_rec data_cur%ROWTYPE;
--
  -- セグメント値配列(EBS標準関数fnd_flex_ext用)
  g_segments_tab               fnd_flex_ext.segmentarray;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック
   ***********************************************************************************/
  PROCEDURE chk_period(
    iv_trans_date  IN  VARCHAR2,        -- 振替日
    in_record_cnt  IN  NUMBER,          -- レコード番号
    ov_errbuf      OUT VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT  VARCHAR2(100) := 'chk_period';          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                           VARCHAR2(5000);                         -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1);                            -- リターン・コード
    lv_errmsg                           VARCHAR2(5000);                         -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_yes                    CONSTANT  VARCHAR2(1) := 'Y';
--
    -- *** ローカル変数 ***
    lv_deprn_run              fa_deprn_periods.deprn_run%TYPE := NULL;          -- 減価償却実行フラグ
    lv_period_name            fa_deprn_periods.period_name%TYPE;                -- 会計期間名
--
    -- *** ローカル・カーソル ***
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
    -- 振替日のチェックおよび形式変換
    BEGIN
      SELECT TO_CHAR( TO_DATE( iv_trans_date , cv_date_format_1 ) , cv_date_format_2 )   period_name
      INTO   lv_period_name
      FROM   DUAL
      ;
    EXCEPTION
      -- 変換でエラーが発生した場合
      WHEN OTHERS THEN
        -- メッセージ編集
        lv_errmsg := '行番号：' || in_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 振替日が存在しない日付です。';
        RAISE chk_period_expt;
    END;
--
    -- 会計期間チェック
    BEGIN
      SELECT  fdp.deprn_run         AS deprn_run                      -- 減価償却実行フラグ
      INTO    lv_deprn_run
      FROM    fa_deprn_periods         fdp                            -- 減価償却期間
      WHERE   fdp.book_type_code    =  data_rec.condition_2
      AND     fdp.period_name       =  lv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- 会計期間の取得件数がゼロ件の場合
      WHEN NO_DATA_FOUND THEN
        -- メッセージ編集
        lv_errmsg := '行番号：' || in_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 会計期間が存在しないかクローズ済です。';
        RAISE chk_period_expt;
    END;
--
    -- 減価償却が実行されている場合
    IF lv_deprn_run = cv_yes THEN
        -- メッセージ編集
        lv_errmsg := '行番号：' || in_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 会計期間がオープン状態ではありません。';
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- エラーメッセージをセット
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- 終了ステータスは警告とする
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id      IN  VARCHAR2,       -- ファイルID
    iv_fmt_ptn      IN  VARCHAR2,       -- フォーマットパターン
    ov_errbuf       OUT VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  )
--
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT  VARCHAR2(100) := 'submain';   -- プログラム名
    cn_segment_cnt            CONSTANT  NUMBER        := 8;           -- セグメント数
    cn_one                    CONSTANT  NUMBER        := 1;           
    cv_flg_yes                CONSTANT  VARCHAR2(1)   := 'Y';         -- フラグYes
    cv_pending                CONSTANT  VARCHAR2(7)   := 'PENDING';   -- ステータス(PENDING)
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                           VARCHAR2(5000);               -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1);                  -- リターン・コード
    lv_errmsg                           VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --参照タイプ用変数
    --CSV項目数
    cn_csv_file_col_num       CONSTANT  NUMBER       := 11;                     -- CSVファイル項目数
    cn_trans_date_length      CONSTANT  NUMBER       := 8;                      -- 振替日桁数
    -- セグメント値
    cv_segment1               CONSTANT VARCHAR2(30)  := '001';                  -- 会社コード
    cv_segment5               CONSTANT VARCHAR2(30)  := '000000000';            -- 顧客コード
    cv_segment6               CONSTANT VARCHAR2(30)  := '000000';               -- 企業コード
    cv_segment7               CONSTANT VARCHAR2(30)  := '0';                    -- 予備１
    cv_segment8               CONSTANT VARCHAR2(30)  := '0';                    -- 予備２
--
    -- *** ローカル変数 ***
    --業務日付
    lt_exp_code_comb_id       gl_code_combinations.code_combination_id%TYPE;    -- 減価償却費勘定CCID
    lt_location_id            gl_code_combinations.code_combination_id%TYPE;    -- 事業所CCID
    --アップロード用変数
    lv_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;       -- CSVファイル名
    l_file_data_tab           xxccp_common_pkg2.g_file_data_tbl;                -- 行単位データ格納用配列
    ln_col_num                NUMBER;                                           -- 項目数取得用
    ln_line_cnt               NUMBER;                                           -- CSVファイル各行参照用カウンタ
    ln_line_cnt_2             NUMBER  := 0;                                     -- CSVファイル各行参照用カウンタ
    ln_column_cnt             NUMBER;                                           -- CSVファイル各列参照用カウンタ
    ln_file_id                NUMBER  := TO_NUMBER(iv_file_id);                 -- ファイルID
    ln_record_cnt             NUMBER  := 0;                                     -- 処理件数用カウンタ
    ln_skip_cnt               NUMBER  := 0;                                     -- 項目過不足件数用カウンタ
    ln_current_units          fa_additions_b.current_units%TYPE;                -- 単位変更
    lv_err_flg                VARCHAR2(1)  DEFAULT 'N';                         -- エラーフラグ
    --データチェック用変数
    lv_condition_1            xxccp_data_patch_work.condition_1%TYPE;
    lb_ret                    BOOLEAN;                                          -- 関数リターンコード
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    TYPE gt_col_data_ttype    IS TABLE OF VARCHAR2(5000)    INDEX BY BINARY_INTEGER;      -- 1次元配列（項目）
    TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;      -- 2次元配列（レコード）（項目）
    lt_path_data_tab  gt_rec_data_ttype;
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
    -- ファイル名出力
    --==============================================================
    SELECT  xmfui.file_name             file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'ファイル名称                  ：'||lv_file_name
    );
--
    --改行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
    -- 0件エラー(ヘッダのみでもエラーとする)
    IF (l_file_data_tab.COUNT <= 1 ) THEN
      -- メッセージ編集
      lv_errmsg := 'アップロードファイルにデータがありません。';
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      RAISE global_api_others_expt;
    END IF;
--
    --タイトル行は除外、データ行から取得する
    <<line_loop>>
    FOR ln_line_cnt IN 2 .. l_file_data_tab.COUNT LOOP
      --項目数取得
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        -- 過不足件数加算
        ln_skip_cnt := ln_skip_cnt + 1;
         -- メッセージ編集
         lv_errmsg := '['|| (ln_line_cnt - 1) || '行目] アップロードファイルの項目数に過不足があります。';
         -- メッセージ出力
         FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff   => lv_errmsg
         );
      ELSE
        -- 行番号を設定
        ln_line_cnt_2 := ln_line_cnt_2 + 1;
        lt_path_data_tab(ln_line_cnt_2)(0) := ln_line_cnt - 1;
--
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割
          lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                               iv_char     => l_file_data_tab(ln_line_cnt)
                                                              ,iv_delim    => ','
                                                              ,in_part_num => ln_column_cnt
                                                          );
          --ダブルクォーテーション削除
          lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt) := SUBSTR(
                                                            lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt) 
                                                           ,2
                                                           ,LENGTH(lt_path_data_tab(ln_line_cnt_2)(ln_column_cnt)) - 2
                                                          );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    --==============================================================
    -- アップロードデータをパッチ用テーブルへ登録
    --==============================================================
    <<ins_line_loop>>
    FOR ln_line_cnt IN 1 .. lt_path_data_tab.COUNT LOOP
--
      --パッチ用テーブル登録
      INSERT INTO xxccp_data_patch_work (
         file_id
        ,data_sequence
        ,condition_1
        ,condition_2
        ,chr_column_1
        ,chr_column_2
        ,chr_column_3
        ,chr_column_4
        ,chr_column_5
        ,chr_column_6
        ,chr_column_7
        ,chr_column_8
        ,chr_column_9
      ) VALUES (
         ln_file_id                                         -- ファイルID
        ,lt_path_data_tab(ln_line_cnt)( 0)                  -- データシーケンス
        ,lt_path_data_tab(ln_line_cnt)( 1)                  -- 条件値1（資産番号）
        ,lt_path_data_tab(ln_line_cnt)( 2)                  -- 条件値2（台帳）
        ,lt_path_data_tab(ln_line_cnt)( 3)                  -- 文字値1（振替日）
        ,lt_path_data_tab(ln_line_cnt)( 4)                  -- 文字値2（減価償却費勘定．部門）
        ,lt_path_data_tab(ln_line_cnt)( 5)                  -- 文字値3（減価償却費勘定．勘定科目）
        ,lt_path_data_tab(ln_line_cnt)( 6)                  -- 文字値4（減価償却費勘定．補助科目）
        ,lt_path_data_tab(ln_line_cnt)( 7)                  -- 文字値5（事業所．申告地）
        ,lt_path_data_tab(ln_line_cnt)( 8)                  -- 文字値6（事業所．管理部門）
        ,lt_path_data_tab(ln_line_cnt)( 9)                  -- 文字値7（事業所．事業所）
        ,lt_path_data_tab(ln_line_cnt)(10)                  -- 文字値8（事業所．場所）
        ,lt_path_data_tab(ln_line_cnt)(11)                  -- 文字値9（事業所．本社/工場区分）
      );
--
      --対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP ins_line_loop;
--
    --==============================================================
    -- ファイルIFデータ削除
    --==============================================================
    DELETE
    FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = ln_file_id
    ;
--
    lt_path_data_tab.DELETE;
--
    --==============================================================
    -- データチェック処理
    --==============================================================
    --対象データ抽出
    OPEN data_cur(
           in_file_id => ln_file_id
         );
--
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      -- エラーフラグ初期化
      lv_err_flg    := cv_flag_n;
      -- 行番号を取得
      ln_record_cnt := data_rec.data_sequence;
--
      -- 資産番号チェック
      IF ( data_rec.condition_1 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 台帳チェック
      IF ( data_rec.condition_2 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 台帳が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 振替日チェック
      IF ( data_rec.chr_column_1 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.chr_column_1 || ' 振替日が未設定です。';
        -- メッセージ出力処理
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      -- 振替日桁数チェック
      ELSIF ( LENGTH( data_rec.chr_column_1 ) <> cn_trans_date_length ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.chr_column_1 || ' 振替日が８桁ではありません。';
        -- メッセージ出力処理
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 減価償却費勘定．部門チェック
      IF ( data_rec.chr_column_2 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 減価償却費勘定．部門が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 減価償却費勘定．勘定科目チェック
      IF ( data_rec.chr_column_3 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 減価償却費勘定．勘定科目が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 減価償却費勘定．補助科目チェック
      IF ( data_rec.chr_column_4 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 減価償却費勘定．補助科目が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 事業所．申告地チェック
      IF ( data_rec.chr_column_5 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 事業所．申告地が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 事業所．管理部門チェック
      IF ( data_rec.chr_column_6 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 事業所．管理部門が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 事業所．事業所チェック
      IF ( data_rec.chr_column_7 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 事業所．事業所が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 事業所．場所チェック
      IF ( data_rec.chr_column_8 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 事業所．場所が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 事業所．本社/工場区分チェック
      IF ( data_rec.chr_column_9 IS NULL ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 事業所．本社/工場区分が未設定です。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- 資産番号一意チェック
      BEGIN
        IF ( data_rec.condition_1 IS NOT NULL ) AND
           ( data_rec.condition_2 IS NOT NULL ) THEN
          SELECT xdpw.condition_1         condition_1
          INTO   lv_condition_1
          FROM   xxccp_data_patch_work    xdpw
          WHERE  xdpw.file_id     = ln_file_id
          AND    xdpw.condition_1 = data_rec.condition_1
          AND    xdpw.condition_2 = data_rec.condition_2
          ;
        END IF;
      EXCEPTION
      --一意制約エラー
        WHEN TOO_MANY_ROWS THEN
          -- エラーフラグをYに設定
          lv_err_flg := cv_flag_y;
          -- メッセージ編集
          lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' がファイル内で一意ではありません。';
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
      END;
--
      -- 資産番号と台帳の組み合わせチェック
      BEGIN
        IF ( data_rec.condition_1 IS NOT NULL ) AND
           ( data_rec.condition_2 IS NOT NULL ) THEN
          SELECT fab.current_units      current_units
          INTO   ln_current_units
          FROM   fa_additions_b         fab                   -- 資産詳細情報
                ,fa_books               fb                    -- 資産台帳情報
          WHERE  fab.asset_number    =  data_rec.condition_1  -- 資産番号
          AND    fab.asset_id        =  fb.asset_id
          AND    fb.book_type_code   =  data_rec.condition_2  -- 台帳名
          AND    fb.date_ineffective IS NULL                  -- 無効ではない
          ;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- エラーフラグをYに設定
          lv_err_flg := cv_flag_y;
          -- メッセージ編集
          lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' が台帳：' || data_rec.condition_2 || ' に存在しません。';
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
      END;
--
      -- 会計期間チェック
      chk_period(
         data_rec.chr_column_1          -- 振替日
        ,ln_record_cnt                  -- レコード行数
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_warn) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
--
      -- ===============================
      -- 減価償却費勘定CCID取得
      -- ===============================
      -- セグメント値配列初期化
      g_segments_tab.DELETE;
      -- セグメント値配列設定(SEG1:会社)
      g_segments_tab(1) := cv_segment1;
      -- セグメント値配列設定(SEG2:部門コード)
      g_segments_tab(2) := data_rec.chr_column_2;
      -- セグメント値配列設定(SEG3:償却科目)
      g_segments_tab(3) := data_rec.chr_column_3;
      -- セグメント値配列設定(SEG4:補助科目)
      g_segments_tab(4) := data_rec.chr_column_4;
      -- セグメント値配列設定(SEG5:顧客コード)
      g_segments_tab(5) := cv_segment5;
      -- セグメント値配列設定(SEG6:企業コード)
      g_segments_tab(6) := cv_segment6;
      -- セグメント値配列設定(SEG7:予備１)
      g_segments_tab(7) := cv_segment7;
      -- セグメント値配列設定(SEG8:予備２)
      g_segments_tab(8) := cv_segment8;
--
      -- CCID取得関数呼び出し
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => gt_application_short_name         -- アプリケーション短縮名(GL)
                  ,key_flex_code           => gt_id_flex_code                   -- キーフレックスコード
                  ,structure_number        => gt_chart_of_account_id            -- 勘定科目体系番号
                  ,validation_date         => gd_process_date                   -- 日付チェック
                  ,n_segments              => cn_segment_cnt                    -- セグメント数
                  ,segments                => g_segments_tab                    -- セグメント値配列
                  ,combination_id          => lt_exp_code_comb_id               -- 減価償却費勘定CCID
                );
--
      -- 共通関数エラー
      IF NOT lb_ret THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 減価償却費勘定が正しくありません。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      END IF;
--
      -- ===============================
      -- 事業所CCID取得
      -- ===============================
      -- 事業所マスタチェック
      xxcff_common1_pkg.chk_fa_location(
         iv_segment1      => data_rec.chr_column_5                -- 申告地
        ,iv_segment2      => data_rec.chr_column_6                -- 部門
        ,iv_segment3      => data_rec.chr_column_7                -- 事業所
        ,iv_segment4      => data_rec.chr_column_8                -- 場所
        ,iv_segment5      => data_rec.chr_column_9                -- 本社工場区分
        ,on_location_id   => lt_location_id                       -- 事業所CCID
        ,ov_errbuf        => lv_errbuf                            -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode       => lv_retcode                           -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg                            -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- 共通関数エラー
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- エラーフラグをYに設定
        lv_err_flg := cv_flag_y;
        -- メッセージ編集
        lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' 事業所が正しくありません。';
        -- メッセージ出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg
        );
      END IF;
--
      IF ( lv_err_flg = cv_flag_n ) THEN
      --==============================================================
      -- 振替OIF登録
      --==============================================================
--        BEGIN
          INSERT INTO xx01_transfer_oif(
             transfer_oif_id                                                -- 振替OIF内部ID
            ,book_type_code                                                 -- 台帳
            ,asset_number                                                   -- 資産番号
            ,created_by                                                     -- 作成者ID
            ,creation_date                                                  -- 作成日
            ,last_updated_by                                                -- 最終更新者
            ,last_update_date                                               -- 最終更新日
            ,last_update_login                                              -- 最終更新ログインID
            ,request_id                                                     -- リクエストID
            ,program_application_id                                         -- アプリケーションID
            ,program_id                                                     -- プログラムID
            ,program_update_date                                            -- プログラム最終更新日
            ,transaction_date_entered                                       -- 振替日
            ,transaction_units                                              -- 単位変更
            ,posting_flag                                                   -- 転記チェックフラグ
            ,status                                                         -- ステータス
            ,segment1                                                       -- 減価償却費勘定セグメント1
            ,segment2                                                       -- 減価償却費勘定セグメント2
            ,segment3                                                       -- 減価償却費勘定セグメント3
            ,segment4                                                       -- 減価償却費勘定セグメント4
            ,segment5                                                       -- 減価償却費勘定セグメント5
            ,segment6                                                       -- 減価償却費勘定セグメント6
            ,segment7                                                       -- 減価償却費勘定セグメント7
            ,segment8                                                       -- 減価償却費勘定セグメント8
            ,loc_segment1                                                   -- 事業所フレックスフィールド1
            ,loc_segment2                                                   -- 事業所フレックスフィールド2
            ,loc_segment3                                                   -- 事業所フレックスフィールド3
            ,loc_segment4                                                   -- 事業所フレックスフィールド4
            ,loc_segment5                                                   -- 事業所フレックスフィールド5
          ) VALUES (
             xx01_transfer_oif_s.NEXTVAL                                    -- 振替OIF内部ID
            ,data_rec.condition_2                                           -- 台帳
            ,data_rec.condition_1                                           -- 資産番号
            ,cn_created_by                                                  -- 作成者ID
            ,cd_creation_date                                               -- 作成日
            ,cn_last_updated_by                                             -- 最終更新者
            ,cd_last_update_date                                            -- 最終更新日
            ,cn_last_update_login                                           -- 最終更新ログインID
            ,cn_request_id                                                  -- 要求ID
            ,cn_program_application_id                                      -- コンカレント・プログラム・アプリケーションID
            ,cn_program_id                                                  -- コンカレント・プログラムID
            ,cd_program_update_date                                         -- プログラム更新日
            ,TO_DATE( data_rec.chr_column_1 , cv_date_format_1 )            -- 振替日
            ,ln_current_units                                               -- 単位変更
            ,cv_flg_yes                                                     -- 転記チェックフラグ(固定値Y)
            ,cv_pending                                                     -- ステータス(PENDING)
            ,cv_segment1                                                    -- 減価償却費勘定セグメント1
            ,data_rec.chr_column_2                                          -- 減価償却費勘定セグメント2
            ,data_rec.chr_column_3                                          -- 減価償却費勘定セグメント3
            ,data_rec.chr_column_4                                          -- 減価償却費勘定セグメント4
            ,cv_segment5                                                    -- 減価償却費勘定セグメント5
            ,cv_segment6                                                    -- 減価償却費勘定セグメント6
            ,cv_segment7                                                    -- 減価償却費勘定セグメント7
            ,cv_segment8                                                    -- 減価償却費勘定セグメント8
            ,data_rec.chr_column_5                                          -- 事業所フレックスフィールド1
            ,data_rec.chr_column_6                                          -- 事業所フレックスフィールド2
            ,data_rec.chr_column_7                                          -- 事業所フレックスフィールド3
            ,data_rec.chr_column_8                                          -- 事業所フレックスフィールド4
            ,data_rec.chr_column_9                                          -- 事業所フレックスフィールド5
          );
          -- 成功件数加算
          gn_normal_cnt := gn_normal_cnt + 1;
--        END;
      ELSE
        -- スキップ件数加算
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
    END LOOP;
--
    CLOSE data_cur;
--
    --改行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --ワークテーブル削除
    DELETE
    FROM   xxccp_data_patch_work xdpw
    WHERE  xdpw.file_id = ln_file_id
    ;
--
    -- 対象件数加算
    gn_target_cnt := gn_target_cnt + ln_skip_cnt;
    -- スキップ件数加算
    gn_warn_cnt   := gn_warn_cnt   + ln_skip_cnt;
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
      -- メッセージ編集
      lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' ' || lv_errbuf;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errmsg
      );
      ROLLBACK;  --更新分ロールバック
--
      --ファイルIFデータ削除
      DELETE
      FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id
      ;
--
      --ワークテーブル削除
      DELETE
      FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id
      ;
--
      IF ( data_cur%ISOPEN ) THEN
          CLOSE data_cur;
      END IF;
--
      --データ削除のコミット
      COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      -- メッセージ編集
      lv_errmsg := '行番号：' || ln_record_cnt || ' 資産番号：' || data_rec.condition_1 || ' ' || SQLERRM;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errmsg
      );
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE
      FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = ln_file_id
      ;
--
      --ワークテーブル削除
      DELETE
      FROM xxccp_data_patch_work xdpw
      WHERE  xdpw.file_id = ln_file_id
      ;
--
      IF ( data_cur%ISOPEN ) THEN
          CLOSE data_cur;
      END IF;
--
      COMMIT;    --データ削除のコミット
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,       -- リターン・コード    --# 固定 #
    iv_file_id      IN  VARCHAR2,       -- ファイルID
    iv_fmt_ptn      IN  VARCHAR2        -- フォーマットパターン
  )
--
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT  VARCHAR2(100) := 'main';                -- プログラム名
    cv_appl_short_name        CONSTANT  VARCHAR2(10)  := 'XXCCP';               -- アドオン：共通・IF領域
    cv_target_rec_msg         CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90000';    -- 対象件数メッセージ
    cv_success_rec_msg        CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90001';    -- 成功件数メッセージ
    cv_error_rec_msg          CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90002';    -- エラー件数メッセージ
    cv_skip_rec_msg           CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90003';    -- スキップ件数メッセージ
    cv_cnt_token              CONSTANT  VARCHAR2(10)  := 'COUNT';               -- 件数メッセージ用トークン名
    cv_normal_msg             CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90004';    -- 正常終了メッセージ
    cv_warn_msg               CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90005';    -- 警告終了メッセージ
    cv_error_msg              CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-90006';    -- エラー終了全ロールバック
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                           VARCHAR2(5000);                         -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1);                            -- リターン・コード
    lv_errmsg                           VARCHAR2(5000);                         -- ユーザー・エラー・メッセージ
    lv_message_code                     VARCHAR2(100);                          -- 終了メッセージコード
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
    -- ===============================
    -- 初期値情報取得
    -- ===============================
    xxcff_common1_pkg.init(
       or_init_rec  => g_init_rec           -- 初期値情報
      ,ov_errbuf    => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 共通関数がエラーの場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00258      -- メッセージ
                     ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                     ,iv_token_value1 => 0                      -- トークン値1
                     ,iv_token_name2  => cv_tkn_func_name       -- トークンコード2
                     ,iv_token_value2 => cv_msg_name_50130      -- トークン値2
                     ,iv_token_name3  => cv_tkn_info            -- トークンコード3
                     ,iv_token_value3 => lv_errmsg              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 初期値をグローバル変数に格納
    gd_process_date            := g_init_rec.process_date;               -- 業務日付
    gt_chart_of_account_id     := g_init_rec.chart_of_accounts_id;       -- 科目体系ID
    gt_application_short_name  := g_init_rec.gl_application_short_name;  -- GLアプリケーション短縮名
    gt_id_flex_code            := g_init_rec.id_flex_code;               -- キーフレックスコード
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_file_id   -- ファイルID
      ,iv_fmt_ptn   -- フォーマットパターン
      ,lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --成功件数クリア
      gn_normal_cnt := 0;
      --スキップ件数クリア
      gn_warn_cnt   := 0;
      --エラー件数
      gn_error_cnt  := gn_target_cnt;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
    IF   (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn)   THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error)  THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
--
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => errbuf
      );
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => errbuf
      );
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => errbuf
      );
      ROLLBACK;
  END main;
--
END XXCCP008A07C;
/