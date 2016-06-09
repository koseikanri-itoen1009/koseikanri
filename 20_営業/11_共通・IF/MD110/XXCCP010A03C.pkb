CREATE OR REPLACE PACKAGE BODY APPS.XXCCP010A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP010A03C(body)
 * Description      : 問合せ担当拠点更新アップロード
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  output_warn_msg          警告メッセージ出力処理
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/04/27    1.0   Y.Shoji          [E_本稼動_08373]新規作成
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;           --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                      --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;           --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                      --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;   --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                      --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
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
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP010A03C';                 -- プログラム名
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_header_flg             VARCHAR2(1)      DEFAULT 'N';                    -- 警告ヘッダ確認用
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 仕入先更新データカーソル
  CURSOR data_cur( in_file_id NUMBER )
  IS
    SELECT   xdpw.execute_mode  AS execute_mode   --実行モード
            ,xdpw.condition_1   AS condition_1    --仕入先番号
            ,xdpw.chr_column_1  AS chr_column_1   --問合せ担当拠点
    FROM     xxccp_data_patch_work xdpw
    WHERE    xdpw.file_id = in_file_id
    ORDER BY xdpw.data_sequence
    ;
--
  data_rec data_cur%ROWTYPE;
--
--
  /**********************************************************************************
   * Procedure Name   : output_warn_msg
   * Description      : 警告メッセージ出力処理
   **********************************************************************************/
  PROCEDURE output_warn_msg(
    it_data_rec   IN  data_cur%ROWTYPE    --   1.データレコード
   ,iv_message    IN  VARCHAR2            --   2.メッセージ内容
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
--
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_warn_msg'; -- プログラム名
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    IF ( gv_header_flg <> 'Y' ) THEN
      -- 警告ログ用ヘッダ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   =>   '"'||  '実行モード'            ||'","'
                        ||  '仕入先番号'            ||'","'
                        ||  '問合せ担当拠点'        ||'","'
                        ||  '警告メッセージ'        ||'"'
      );
      --ヘッダ出力フラグON
      gv_header_flg := 'Y';
    END IF;
    -- 警告ログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   =>  '"'   || it_data_rec.execute_mode || '","'  --実行モード
                        || it_data_rec.condition_1  || '","'  --仕入先番号
                        || it_data_rec.chr_column_1 || '","'  --問合せ担当拠点
                        || iv_message               || '"'    --警告メッセージ
    );
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
  END output_warn_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2     --   1.ファイルID
   ,iv_fmt_ptn    IN  VARCHAR2     --   2.フォーマットパターン
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
--
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
    --参照タイプ用変数
    cv_lookup_fo              CONSTANT VARCHAR2(25) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_lang                   CONSTANT VARCHAR2(2)  := USERENV('LANG');
    cv_exe_mode_0             CONSTANT VARCHAR2(1)  := '0';
    cv_exe_mode_1             CONSTANT VARCHAR2(1)  := '1';
    --CSV項目数
    cn_csv_file_col_num       CONSTANT NUMBER       := 3;             -- CSVファイル項目数
--
    -- *** ローカル変数 ***
    --アップロード用変数
    lt_file_ul_name   fnd_lookup_values.meaning%TYPE;                 -- ファイルアップロード名称
    lt_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE;     -- CSVファイル名
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;              -- 行単位データ格納用配列
    ln_col_num        NUMBER;                                         -- 項目数取得用
    ln_line_cnt       NUMBER;                                         -- CSVファイル各行参照用カウンタ
    ln_column_cnt     NUMBER;                                         -- CSVファイル各列参照用カウンタ
    ln_file_id        NUMBER  := TO_NUMBER(iv_file_id);               -- ファイルID
    ln_seq            NUMBER  := 0;                                   -- ワークテーブル用シーケンス番号
    ln_head_cnt       NUMBER  := 0;                                   -- ログヘッダ確認用
    ln_cnt            NUMBER  := 1;                                   -- ループカウンタ
    lv_exec_flg       VARCHAR2(1);                                    -- 実行モード
    lv_err_flg        VARCHAR2(1)  DEFAULT 'N';                       -- エラーフラグ
--
    TYPE gt_col_data_ttype       IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;                   -- 1次元配列（項目）
    TYPE gt_rec_data_ttype       IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;                -- 2次元配列（レコード）（項目）
    lt_path_data_tab   gt_rec_data_ttype;
    TYPE lt_vendor_site_id_ttype IS TABLE OF po_vendor_sites.vendor_site_id%TYPE INDEX BY PLS_INTEGER; -- 仕入先サイトID
    lt_vendor_site_id  lt_vendor_site_id_ttype;
    TYPE lt_attribute5_ttype     IS TABLE OF po_vendor_sites.attribute5%TYPE INDEX BY PLS_INTEGER;     -- 問合せ担当拠点
    lt_attribute5      lt_attribute5_ttype;
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'ファイルID                    ：' || iv_file_id
    );
    -- フォーマットパターン出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'パラメータフォーマットパターン：' || iv_fmt_ptn
    );
    --
    --==============================================================
    -- ファイルアップロード名称出力
    --==============================================================
    SELECT flv.meaning  AS meaning
    INTO   lt_file_ul_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_lookup_fo
    AND    flv.lookup_code  = iv_fmt_ptn
    AND    flv.language     = cv_lang
    AND    flv.enabled_flag = 'Y'
    AND    TRUNC(SYSDATE) BETWEEN flv.start_date_active
                          AND     NVL(flv.end_date_active, TRUNC(SYSDATE))
    ;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'ファイルアップロード名称      ：'||lt_file_ul_name
    );
    --
    --==============================================================
    -- ファイル名出力
    --==============================================================
    SELECT  xmfui.file_name  AS file_name
    INTO    lt_file_name
    FROM    xxccp_mrp_file_ul_interface xmfui
    WHERE   xmfui.file_id = ln_file_id
    FOR UPDATE NOWAIT
    ;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'ファイル名                    ：'||lt_file_name
    );
    --
    --改行の出力
    FND_FILE.PUT_LINE(
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
    -- 0件エラー(ヘッダのみでもエラーとする)
    IF (l_file_data_tab.COUNT <= 1 ) THEN
      lv_errbuf := 'アップロードファイルにデータがありません。';
      RAISE global_api_others_expt;
    END IF;
--
    --タイトル行は除外、データ行から取得する
    FOR ln_line_cnt IN 2 .. l_file_data_tab.COUNT LOOP
      --項目数取得
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), ',', NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
         lv_errbuf := '['|| ln_line_cnt || '行目] アップロードファイルの項目数に過不足があります。';
         RAISE global_api_others_expt;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割
          lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                               iv_char     => l_file_data_tab(ln_line_cnt)
                                                              ,iv_delim    => ','
                                                              ,in_part_num => ln_column_cnt
                                                          );
          --ダブルクォーテーション削除
          lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt) := SUBSTR(
                                                            lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt) 
                                                           ,2
                                                           ,LENGTH(lt_path_data_tab(ln_line_cnt - 1)(ln_column_cnt)) - 2
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
      --データシーケンス採番
      ln_seq := ln_seq + 1;
      --パッチ用テーブル登録
      INSERT INTO xxccp_data_patch_work (
         file_id
        ,data_sequence
        ,execute_mode
        ,condition_1
        ,chr_column_1
      ) VALUES (
         ln_file_id                         -- ファイルID
        ,ln_seq                             -- データシーケンス
        ,lt_path_data_tab(ln_line_cnt)(1)   -- 実行モード
        ,lt_path_data_tab(ln_line_cnt)(2)   -- 仕入先番号
        ,lt_path_data_tab(ln_line_cnt)(3)   -- 問合せ担当拠点
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
    DELETE FROM xxccp_mrp_file_ul_interface xmfui
    WHERE xmfui.file_id = ln_file_id
    ;
--
    lt_path_data_tab.DELETE;
--
    --==============================================================
    -- データ確認処理
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
      --初期化
      lv_err_flg     := 'N';    --エラーフラグ
--
      --１行目の実行モードを取得
      IF ( ln_cnt = 1 ) THEN
        -- 実行モードチェック(0、1以外はエラー)
        IF ( data_rec.execute_mode IS NULL )
          OR( ( data_rec.execute_mode <> cv_exe_mode_0 )
            AND ( data_rec.execute_mode <> cv_exe_mode_1 ) ) THEN
           lv_errbuf := '実行モードには0(対象確認)または1(データ更新)の値を入力して下さい。'||data_rec.execute_mode;
           RAISE global_api_others_expt;
        END IF;
        -- 実行モードを変数に格納
        lv_exec_flg := data_rec.execute_mode;
        --
      END IF;
--
      -- 仕入先番号NULLチェック
      IF ( data_rec.condition_1 IS NULL ) THEN
        --エラーフラグをYに設定
        lv_err_flg := 'Y';
        --警告メッセージ出力処理
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '['|| ln_cnt || '行目] 仕入先番号が未設定です。'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        --仕入先番号チェック
        BEGIN
          SELECT pvs.vendor_site_id AS vd_site_id
          INTO   lt_vendor_site_id(ln_cnt)
          FROM   po_vendors      pv   -- 仕入先マスタ
                ,po_vendor_sites pvs  -- 仕入先サイトマスタ
          WHERE  pv.vendor_id               = pvs.vendor_id
            AND  TRUNC(SYSDATE)            >= pv.start_date_active
            AND  TRUNC(SYSDATE)            <= NVL( pv.end_date_active ,TRUNC(SYSDATE) )
            AND  TRUNC(SYSDATE)            <  NVL( pvs.inactive_date  ,TRUNC(SYSDATE) + 1 )
            AND  pv.segment1                = data_rec.condition_1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --エラーフラグをYに設定
            lv_err_flg := 'Y';
            --エラーメッセージ出力処理
            output_warn_msg(
               it_data_rec => data_rec
              ,iv_message  => '[' || ln_cnt || '行目] 仕入先番号：' || data_rec.condition_1 || ' が不正です。'
              ,ov_errbuf   => lv_errbuf
              ,ov_retcode  => lv_retcode
              ,ov_errmsg   => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
            -- エラー件数カウント
            gn_error_cnt := gn_error_cnt + 1;
        END;
      END IF;
--
      -- 問合せ担当拠点NULLチェック
      IF ( data_rec.chr_column_1 IS NULL ) THEN
        --エラーフラグをYに設定
        lv_err_flg := 'Y';
        --エラーメッセージ出力処理
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => '['|| ln_cnt || '行目] 問合せ担当拠点が未設定です。'
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
        --
        --存在チェック(問合せ担当拠点)
        --※hz_partiesは不要だが値セットと条件を同一にする
        BEGIN
          SELECT hca.account_number AS attribute5
          INTO   lt_attribute5(ln_cnt)
          FROM   hz_cust_accounts hca
                ,hz_parties       hp
          WHERE  hca.party_id            = hp.party_id
            AND  hca.customer_class_code = '1'
            AND  hca.account_number      = data_rec.chr_column_1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --エラーフラグをYに設定
            lv_err_flg := 'Y';
            --エラーメッセージ出力処理
            output_warn_msg(
               it_data_rec => data_rec
              ,iv_message  => '[' || ln_cnt || '行目] 問合せ担当拠点：' || data_rec.chr_column_1 || ' が不正です。'
              ,ov_errbuf   => lv_errbuf
              ,ov_retcode  => lv_retcode
              ,ov_errmsg   => lv_errmsg
            );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_api_others_expt;
            END IF;
            -- エラー件数カウント
            gn_error_cnt := gn_error_cnt + 1;
        END;
      END IF;
--
      --更新後確認用データ出力
      IF ( lv_err_flg <> 'Y' ) THEN
        -- ログ用ヘッダ出力
        output_warn_msg(
           it_data_rec => data_rec
          ,iv_message  => NULL
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_others_expt;
        END IF;
      END IF;
--;
      --カウントアップ
      ln_cnt := ln_cnt + 1;
    END LOOP;
--
    --カーソルクローズ
    CLOSE data_cur;
--
    --==============================================================
    -- データ更新処理
    --==============================================================
    --チェックエラーがなく、実行モードが更新の場合のみ更新処理を実施
    IF ( ( gn_error_cnt = 0 ) AND ( lv_exec_flg = cv_exe_mode_1 ) )  THEN
      BEGIN
        FORALL i IN 1..ln_cnt - 1
          UPDATE po_vendor_sites pvs
          SET    pvs.attribute5     = lt_attribute5(i)
          WHERE  pvs.vendor_site_id = lt_vendor_site_id(i)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := '更新処理に失敗しました。';
          RAISE global_api_others_expt;
      END;
--
      -- 成功件数カウント
      gn_normal_cnt := ln_cnt - 1;
    END IF;
--
    --改行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- ログ出力処理
    --==============================================================
    --ログ出力用にカーソルオープン
    OPEN data_cur(
           in_file_id => ln_file_id
         );
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      -- 更新後のデータを表示
      IF ( ln_head_cnt = 0 ) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => 
                  '"仕入先番号",'        ||
                  '"問合せ担当拠点"'
          );
          --ヘッダ出力ずみ
          ln_head_cnt := 1;
      END IF;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   =>'"' ||
                  data_rec.condition_1   || '","' ||
                  data_rec.chr_column_1  || '"'
      );
    END LOOP;
--
    --ワークテーブル削除
    DELETE FROM xxccp_data_patch_work xdpw
    WHERE xdpw.file_id = ln_file_id
    ;
--
    --チェックエラーが１件以上存在した場合、ステータスをエラーにする
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := 1;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      ;
      --ワークテーブル削除
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE xdpw.file_id = ln_file_id
      ;
      --データ削除のコミット
      COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := 1;
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;  --更新分ロールバック
      --ファイルIFデータ削除
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      ;
      --ワークテーブル削除
      DELETE FROM xxccp_data_patch_work xdpw
      WHERE xdpw.file_id = ln_file_id
      ;
      --カーソルクローズ
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
    errbuf        OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode       OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_file_id    IN  VARCHAR2      -- 1.ファイルID
   ,iv_fmt_ptn    IN  VARCHAR2      -- 2.フォーマットパターン
  )
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
      --件数クリア
      gn_normal_cnt := 0;
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
END XXCCP010A03C;
/