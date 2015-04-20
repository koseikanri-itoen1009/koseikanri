create or replace PACKAGE BODY XXCOI015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOI015A01C(body)
 * Description      : 取引インタフェースの処理
 * MD.050           : MD050_COI_015_A01_資材取引OIFワーカー起動
 * Version          : 1.2
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  chk_trans_worker          6)取引ワーカー終了チェック
 *  start_trans_worker        5)取引ワーカー起動処理
 *  set_trans_oif_header_id   4)資材取引OIFヘッダID更新処理
 *  get_trans_oif_data        2)資材取引OIFテーブル情報抽出処理
 *                            3)資材取引OIFヘッダID取得処理
 *  init                      1)初期処理
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                            7)終了処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/07/07    1.0   H.Sasaki         新規作成
 *  2009/10/09    1.1   H.Sasaki         [E_最終移行リハ_00458]FETCH方法の変更
 *  2015/04/14    1.2   S.Niki           [E_本稼動_12742]引数2(TABLE)の設定値変更
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(20)   :=  'XXCOI015A01C';
--
  -- アプリケーション短縮名
  cv_appli_short_name_xxcoi   CONSTANT VARCHAR2(10)   :=  'XXCOI';
  cv_appli_short_name_xxccp   CONSTANT VARCHAR2(10)   :=  'XXCCP';
  cv_appli_short_name_inv     CONSTANT VARCHAR2(10)   :=  'INV';
--
  -- ステータス
  cv_status_normal            CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)    :=  xxccp_common_pkg.set_status_error;  -- 異常:2
--
  -- WHOカラム
  cn_created_by               CONSTANT NUMBER         :=  fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by          CONSTANT NUMBER         :=  fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login        CONSTANT NUMBER         :=  fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER         :=  fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER         :=  fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER         :=  fnd_global.conc_program_id;  -- PROGRAM_ID
--
  -- メッセージ
  cv_msg_xxccp1_90000         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90000';  -- 対象件数
  cv_msg_xxccp1_90001         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90001';  -- 成功件数
  cv_msg_xxccp1_90002         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90002';  -- エラー件数
  cv_msg_xxccp1_90003         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90003';  -- 警告件数
  cv_msg_xxccp1_90004         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_xxccp1_90005         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_xxccp1_90006         CONSTANT VARCHAR2(30)   :=  'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  --
  cv_msg_xxcoi_10387          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10387';  -- コンカレント入力パラメータなしメッセージ
  cv_msg_xxcoi_10388          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10388';  -- 取引OIF更新エラー
  cv_msg_xxcoi_10389          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10389';  -- 取引ワーカー起動メッセージ
  cv_msg_xxcoi_10390          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10390';  -- 取引ワーカー起動エラーメッセージ
  cv_msg_xxcoi_10391          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10391';  -- 取引OIF更新件数
  cv_msg_xxcoi_10392          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10392';  -- 取引ワーカー起動件数
  cv_msg_xxcoi_10393          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10393';  -- 取引ワーカー終了メッセージ
  cv_msg_xxcoi_10394          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10394';  -- 取引ワーカーエラー件数
  cv_msg_xxcoi_10395          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10395';  -- 取引OIF対象件数
  cv_msg_xxcoi_10396          CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10396';  -- 取引OIFスキップ件数
--
  -- トークン
  cv_token_count              CONSTANT VARCHAR2(20)   :=  'COUNT';
  cv_token_error_msg          CONSTANT VARCHAR2(20)   :=  'ERR_MSG';
  cv_token_request_id         CONSTANT VARCHAR2(20)   :=  'REQUEST_ID';
  cv_token_base_code          CONSTANT VARCHAR2(20)   :=  'BASE_CODE';
  cv_token_header_id          CONSTANT VARCHAR2(20)   :=  'HEADER_ID';
--
  -- セパレータ
  cv_msg_part                 CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(1)    := '.';
  cv_empty                    CONSTANT VARCHAR2(1)    := '';
--
  -- その他定数
  cv_space                    CONSTANT VARCHAR2(1)    :=  ' ';                          -- 半角スペース
  cn_target_1                 CONSTANT VARCHAR2(1)    :=  1;                            -- 取引モード１：処理対象
  cn_lock_flag_1              CONSTANT VARCHAR2(1)    :=  1;                            -- ロックフラグ１
  cv_prf_check_wait_second    CONSTANT VARCHAR2(30)   :=  'XXCOI1_CHECK_WAIT_SECOND';   -- プロファイル（完了チェック待機時間（秒））
  --
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt               NUMBER  DEFAULT 0;     -- 対象件数
  gn_normal_cnt               NUMBER  DEFAULT 0;     -- 更新件数
  gn_error_cnt                NUMBER  DEFAULT 0;     -- エラー件数
  gn_warn_cnt                 NUMBER  DEFAULT 0;     -- 警告件数
  gn_conc_start_cnt           NUMBER  DEFAULT 0;     -- 取引ワーカー起動回数
  gn_sub_conc_err_cnt         NUMBER  DEFAULT 0;     -- 取引ワーカーエラー件数
  gd_start_date               DATE    DEFAULT NULL;  -- 起動日時
  gn_check_wait_second        NUMBER  DEFAULT NULL;  -- 完了チェック待機時間（秒）
--
  -- 資材取引OIFテーブル情報取得データ格納用レコード変数
  TYPE rec_mtl_trans_oif IS RECORD
    (
      row_id          ROWID                                                 -- ROWID
     ,base_code       mtl_secondary_inventories.attribute7%TYPE             -- 拠点コード
    );
  TYPE tab_data_mtl_trans_oif IS TABLE OF rec_mtl_trans_oif INDEX BY PLS_INTEGER;
  gt_mtl_trans_oif    tab_data_mtl_trans_oif;   -- 資材取引OIFテーブル情報取得データ
  --
  TYPE row_id_tbl     IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_rowid_tbl        row_id_tbl;               -- 資材取引OIF_ROWID
  TYPE base_code_tbl  IS TABLE OF mtl_secondary_inventories.attribute7%TYPE INDEX BY BINARY_INTEGER;
  gt_base_code_tbl    base_code_tbl;            -- 拠点コード
  TYPE header_id_tbl  IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_header_id_tbl    header_id_tbl;            -- 資材取引OIFヘッダID
  TYPE request_id_tbl IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_request_id_tbl   request_id_tbl;           -- 取引ワーカー要求ID
  --
--
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
--
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** ロックエラー ***
  global_lock_fail                EXCEPTION;
  --*** 処理部共通例外 ***
  global_process_expt             EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
  --*** バルクアップデート例外 **
  global_bulk_upd_expt            EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
  PRAGMA EXCEPTION_INIT(global_bulk_upd_expt, -24381);
--
  /**********************************************************************************
   * Procedure Name   : chk_trans_worker
   * Description      : ６）取引ワーカー終了チェック
   ***********************************************************************************/
  PROCEDURE chk_trans_worker(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'chk_trans_worker';              -- プログラム名
    cv_success_c          CONSTANT VARCHAR2(1)  := 'C';                             -- コンカレント.フェーズ：正常
    cv_success_i          CONSTANT VARCHAR2(1)  := 'I';                             -- コンカレント.フェーズ：正常
    cv_success_r          CONSTANT VARCHAR2(1)  := 'R';                             -- コンカレント.フェーズ：正常
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;                              -- エラー・メッセージ
    lv_retcode            VARCHAR2(1)    DEFAULT cv_status_normal;                  -- リターン・コード
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;                              -- ユーザー・エラー・メッセージ
    lv_outmsg             VARCHAR2(5000) DEFAULT NULL;                              -- 出力用メッセージ
    --
    ln_cnt                NUMBER;                                                   -- ループカウンタ
    ln_request_cnt        NUMBER;                                                   -- 要求発行件数
    ln_comp_cnt           NUMBER;                                                   -- 要求完了件数
    lt_phase_code         fnd_concurrent_requests.phase_code%TYPE;                  -- フェーズ
    lt_status_code        fnd_concurrent_requests.status_code%TYPE;                 -- ステータス
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 取引ワーカー終了チェック
    -- ===============================================
    -- 初期化
    ln_cnt          :=  0;                          -- ループカウンタ
    ln_request_cnt  :=  gt_request_id_tbl.COUNT;    -- 要求発行件数
    ln_comp_cnt     :=  0;                          -- 要求完了件数
    --
    <<wait_loop>>
    LOOP
      <<chk_end_loop>>
      FOR ln_cnt IN 1 .. ln_request_cnt LOOP
        --
        IF (gt_request_id_tbl(ln_cnt) IS NOT NULL) THEN
          -- コンカレント要求のフェーズ、ステータスを取得
          SELECT  fcr.phase_code                        -- フェーズ
                 ,fcr.status_code                       -- ステータス
          INTO    lt_phase_code
                 ,lt_status_code
          FROM    fnd_concurrent_requests     fcr       -- コンカレント要求一覧
          WHERE   fcr.request_id    =   gt_request_id_tbl(ln_cnt)
          AND     ROWNUM = 1;
          --
          -- コンカレント終了チェック
          IF (lt_phase_code = 'C') THEN
            IF (lt_status_code IN(cv_success_c, cv_success_i, cv_success_r)) THEN
              -- フェーズ「C:正常」、ステータスC, I, R （いずれも正常）
              -- 完了件数をカウントアップ
              ln_comp_cnt :=  ln_comp_cnt + 1;
              -- 終了した取引ワーカーの要求IDを初期化
              gt_request_id_tbl(ln_cnt) :=  NULL;
            ELSE
              -- フェーズ「C:正常」、ステータスC, I, R （いずれも正常）以外
              --
              -- 取引ワーカーエラー件数カウントアップ
              gn_sub_conc_err_cnt :=  gn_sub_conc_err_cnt + 1;
              --
              -- 取引ワーカー終了メッセージ（正常以外）
              lv_outmsg :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_appli_short_name_xxcoi
                             ,iv_name         => cv_msg_xxcoi_10393
                             ,iv_token_name1  => cv_token_request_id
                             ,iv_token_value1 => TO_CHAR(gt_request_id_tbl(ln_cnt))
                            );
              --
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_outmsg
              );
              --
              -- 終了ステータス警告
              ov_retcode  :=  cv_status_warn;
              -- 完了件数をカウントアップ
              ln_comp_cnt :=  ln_comp_cnt + 1;
              -- 終了した取引ワーカーの要求IDを初期化
              gt_request_id_tbl(ln_cnt) :=  NULL;
            END IF;
          END IF;
        END IF;
        --
      END LOOP chk_end_loop;
      --
      -- 要求発行件数と、要求完了件数が一致した場合、処理を終了
      EXIT WHEN ln_request_cnt = ln_comp_cnt;
      --
      -- 待機処理
      dbms_lock.sleep(gn_check_wait_second);
      --
    END LOOP wait_loop;
    -- 空行出力
    IF (ov_retcode = cv_status_warn) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_trans_worker;
--
  /**********************************************************************************
   * Procedure Name   : start_trans_worker
   * Description      : ５）取引ワーカー起動処理
   ***********************************************************************************/
  PROCEDURE start_trans_worker(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name           CONSTANT VARCHAR2(30) := 'start_trans_worker';            -- プログラム名
    cv_prg_name_inctcw    CONSTANT VARCHAR2(30) := 'INCTCW';                        -- 取引ワーカープログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf             VARCHAR2(5000) DEFAULT NULL;                              -- エラー・メッセージ
    lv_retcode            VARCHAR2(1)    DEFAULT cv_status_normal;                  -- リターン・コード
    lv_errmsg             VARCHAR2(5000) DEFAULT NULL;                              -- ユーザー・エラー・メッセージ
    lv_outmsg             VARCHAR2(5000) DEFAULT NULL;                              -- 出力用メッセージ
    lv_compare_base_code  mtl_secondary_inventories.attribute7%TYPE;                -- 変更比較用拠点コード
    ln_success_cnt        NUMBER;                                                   -- ワーカー起動回数
    ln_error_cnt          NUMBER;                                                   -- ワーカー起動失敗回数
    ln_request_id         NUMBER;                                                   -- ワーカー起動要求ID
    --
    -- 起動結果メッセージ
    TYPE out_msg_tbl IS TABLE OF
      VARCHAR2(5000) INDEX BY BINARY_INTEGER;
    lt_start_success      out_msg_tbl;      -- 起動成功メッセージ
    lt_start_error        out_msg_tbl;      -- 起動失敗メッセージ
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- イニシャライズ
    -- ===============================================
    fnd_global.apps_initialize(
      user_id         =>  cn_created_by               -- ユーザID
     ,resp_id         =>  fnd_global.resp_id          -- 職責ID
     ,resp_appl_id    =>  fnd_global.resp_appl_id     -- 職責アプリケーションID
    );
    -- レコード制御変数の初期化
    ln_success_cnt  :=  0;
    ln_error_cnt    :=  0;
    --
    -- ===============================================
    -- 取引ワーカー起動
    -- ===============================================
    <<start_subconc_loop>>
    FOR ln_cnt IN 1 .. gn_target_cnt LOOP
      IF (   (ln_cnt = 1)
          OR (lv_compare_base_code <> gt_base_code_tbl(ln_cnt))
         )
      THEN
        -- 拠点コード毎に、取引ワーカーを起動
        ln_request_id :=  fnd_request.submit_request(
                            application     =>  cv_appli_short_name_inv     -- INV
                           ,program         =>  cv_prg_name_inctcw          -- INCTCW
                           ,description     =>  NULL
                           ,start_time      =>  NULL
                           ,sub_request     =>  FALSE
                           ,argument1       =>  gt_header_id_tbl(ln_cnt)    -- 資材取引OIFヘッダID
-- == 2015/04/14 V1.2 Modified START ===============================================================
--                           ,argument2       =>  3
                           ,argument2       =>  1
-- == 2015/04/14 V1.2 Modified END ===============================================================
                           ,argument3       =>  0
                           ,argument4       =>  0
                          );
        --
        IF (ln_request_id > 0) THEN
          COMMIT;
          -- レコード型制御変数カウントアップ
          ln_success_cnt  :=  ln_success_cnt + 1;
          -- 起動した取引ワーカーの要求IDを保持
          gt_request_id_tbl(ln_success_cnt)  :=  ln_request_id;
          --
          -- 取引ワーカー起動成功メッセージを保持
          lt_start_success(ln_success_cnt)  :=  xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_appli_short_name_xxcoi
                                                 ,iv_name         => cv_msg_xxcoi_10389
                                                 ,iv_token_name1  => cv_token_request_id
                                                 ,iv_token_value1 => TO_CHAR(ln_request_id)
                                                 ,iv_token_name2  => cv_token_base_code
                                                 ,iv_token_value2 => gt_base_code_tbl(ln_cnt)
                                                );
        ELSE
          ROLLBACK;
          -- 終了ステータスに警告を設定
          ov_retcode  :=  cv_status_warn;
          -- レコード型制御変数カウントアップ
          ln_error_cnt  :=  ln_error_cnt + 1;
          --
          -- 取引ワーカー起動失敗メッセージを保持
          lt_start_error(ln_error_cnt)      :=  xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_appli_short_name_xxcoi
                                                 ,iv_name         => cv_msg_xxcoi_10390
                                                 ,iv_token_name1  => cv_token_header_id
                                                 ,iv_token_value1 => TO_CHAR(gt_header_id_tbl(ln_cnt))
                                                 ,iv_token_name2  => cv_token_base_code
                                                 ,iv_token_value2 => gt_base_code_tbl(ln_cnt)
                                                );
        END IF;
        --
        -- 変更比較用拠点コードの設定
        lv_compare_base_code  :=  gt_base_code_tbl(ln_cnt);
      END IF;
      --
    END LOOP start_subconc_loop;
    --
    -- 取引ワーカー起動回数をカウントアップ
    gn_conc_start_cnt :=  ln_success_cnt;
    --
    -- ===============================================
    -- 取引ワーカー起動状況の出力
    -- ===============================================
    <<success_loop>>
    FOR ln_cnt IN 1 .. ln_success_cnt LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lt_start_success(ln_cnt)
      );
    END LOOP success_loop;
    -- 空行出力
    IF (ln_success_cnt <> 0) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
    --
    <<error_loop>>
    FOR ln_cnt IN 1 .. ln_error_cnt LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lt_start_error(ln_error_cnt)
      );
    END LOOP error_loop;
    -- 空行出力
    IF (ln_error_cnt <> 0) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END start_trans_worker;
--
  /**********************************************************************************
   * Procedure Name   : set_trans_oif_header_id
   * Description      : ４）資材取引OIFヘッダID更新処理
   ***********************************************************************************/
  PROCEDURE set_trans_oif_header_id(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'set_trans_oif_header_id';  -- プログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 資材取引OIFテーブル登録処理
    -- ===============================================
-- == 2009/10/08 V1.1 Modified START ===============================================================
--    FORALL ln_cnt IN gt_mtl_trans_oif.FIRST .. gt_mtl_trans_oif.LAST SAVE EXCEPTIONS
    FORALL ln_cnt IN 1 .. gn_target_cnt SAVE EXCEPTIONS
-- == 2009/10/08 V1.1 Modified END   ===============================================================
      UPDATE  mtl_transactions_interface
      SET     transaction_header_id     =   gt_header_id_tbl(ln_cnt)
             ,lock_flag                 =   cn_lock_flag_1
             ,last_update_date          =   SYSDATE
             ,last_updated_by           =   cn_last_updated_by
             ,last_update_login         =   cn_last_update_login
             ,request_id                =   cn_request_id
             ,program_id                =   cn_program_id
             ,program_application_id    =   cn_program_application_id
             ,program_update_date       =   SYSDATE
      WHERE   ROWID   =   gt_rowid_tbl(ln_cnt);
    --
    -- 更新件数を設定
    gn_normal_cnt :=  gn_target_cnt;
    -- 警告件数を設定
    gn_warn_cnt   :=  0;
--
  EXCEPTION
    -- *** バルクアップデート例外処理 ***
    WHEN global_bulk_upd_expt THEN
      gn_warn_cnt   :=  SQL%BULK_EXCEPTIONS.COUNT;      -- 警告件数
      gn_normal_cnt :=  gn_target_cnt - gn_warn_cnt;    -- 更新件数
      --
      ov_retcode    := cv_status_warn;                  -- ステータス（警告）
      --
      <<output_error_loop>>
      FOR ln_cnt IN 1 .. gn_warn_cnt LOOP
        -- エラーメッセージ生成
        lv_outmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_short_name_xxcoi
                       ,iv_name         => cv_msg_xxcoi_10388
                       ,iv_token_name1  => cv_token_base_code
                       ,iv_token_value1 => gt_base_code_tbl(SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_INDEX)
                       ,iv_token_name2  => cv_token_error_msg
                       ,iv_token_value2 => SQLERRM(-SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_CODE)
                      );
        -- エラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_outmsg
        );
      END LOOP output_error_loop;
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
      --
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_trans_oif_header_id;
--
  /**********************************************************************************
   * Procedure Name   : get_trans_oif_data
   * Description      : ２）資材取引OIFテーブル情報抽出処理
   *                    ３）資材取引OIFヘッダID取得処理
   ***********************************************************************************/
  PROCEDURE get_trans_oif_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'get_trans_oif_data';  -- プログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    --
    lt_trans_header_id    mtl_transactions_interface.transaction_header_id%TYPE;    -- 資材取引OIFヘッダID
    lv_compare_base_code  mtl_secondary_inventories.attribute7%TYPE;                -- 変更比較用拠点コード
-- == 2009/10/08 V1.1 Added START ===============================================================
    ln_cnt          NUMBER  :=  0;
-- == 2009/10/08 V1.1 Added END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 資材取引OIFテーブル情報
    CURSOR  cur_trans_oif_data
    IS
      SELECT    mti.ROWID         row_id                -- ROWID
               ,msi.attribute7    base_code             -- 拠点コード
      FROM      mtl_transactions_interface    mti       -- 資材取引OIF
               ,mtl_secondary_inventories     msi       -- 保管場所マスタ
      WHERE     mti.process_flag        =   cn_target_1
      AND       mti.creation_date      <=   gd_start_date
      AND       mti.subinventory_code   =   msi.secondary_inventory_name
      AND       mti.organization_id     =   msi.organization_id
      ORDER BY  msi.attribute7 ASC
      FOR UPDATE OF mti.transaction_header_id;          -- 資材取引OIFをロック
-- == 2009/10/08 V1.1 Added START ===============================================================
    trans_oif_data_rec    cur_trans_oif_data%ROWTYPE;
-- == 2009/10/08 V1.1 Added END   ===============================================================
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 資材取引OIFテーブル情報取得
    -- ===============================================
    OPEN cur_trans_oif_data;
-- == 2009/10/08 V1.1 Delete START ===============================================================
--    -- バルクフェッチ
--    FETCH cur_trans_oif_data BULK COLLECT INTO gt_mtl_trans_oif;
--    -- カーソルクローズ
--    CLOSE cur_trans_oif_data;
--    --
--    -- 対象件数
--    gn_target_cnt :=  gt_mtl_trans_oif.COUNT;
-- == 2009/10/08 V1.1 Delete END   ===============================================================
--
    -- ===============================================
    -- 資材取引OIFヘッダID取得
    -- ===============================================
-- == 2009/10/08 V1.1 Modified START ===============================================================
--    <<get_header_id_loop>>
--    FOR ln_cnt IN 1 .. gn_target_cnt LOOP
--      -- レコード型にデータを設定
--      gt_rowid_tbl(ln_cnt)      :=  gt_mtl_trans_oif(ln_cnt).row_id;
--      gt_base_code_tbl(ln_cnt)  :=  gt_mtl_trans_oif(ln_cnt).base_code;
--      -- 拠点コード毎に、資材取引OIFヘッダIDを設定
--      IF (   (ln_cnt = 1)
--          OR (lv_compare_base_code <> gt_mtl_trans_oif(ln_cnt).base_code)
--         )
--      THEN
--
    <<get_header_id_loop>>
    LOOP
      FETCH cur_trans_oif_data  INTO  trans_oif_data_rec;
      EXIT WHEN cur_trans_oif_data%NOTFOUND;
      gn_target_cnt :=  gn_target_cnt + 1;
      ln_cnt        :=  ln_cnt + 1;
      --
      -- レコード型にデータを設定
      gt_rowid_tbl(ln_cnt)      :=  trans_oif_data_rec.row_id;
      gt_base_code_tbl(ln_cnt)  :=  trans_oif_data_rec.base_code;
      -- 拠点コード毎に、資材取引OIFヘッダIDを設定
      IF (   (ln_cnt = 1)
          OR (lv_compare_base_code <> trans_oif_data_rec.base_code)
         )
      THEN
-- == 2009/10/08 V1.1 Modified END   ===============================================================
        -- 資材取引OIFヘッダIDを取得
        SELECT  mtl_material_transactions_s.NEXTVAL
        INTO    lt_trans_header_id
        FROM    dual;
        --
        gt_header_id_tbl(ln_cnt)  :=  lt_trans_header_id;
        --
      ELSE
        --
        gt_header_id_tbl(ln_cnt)  :=  lt_trans_header_id;
      END IF;
      --
      -- 変更比較用拠点コードを保持
-- == 2009/10/08 V1.1 Modified START ===============================================================
--      lv_compare_base_code  :=  gt_mtl_trans_oif(ln_cnt).base_code;
      lv_compare_base_code  :=  trans_oif_data_rec.base_code;
-- == 2009/10/08 V1.1 Modified END   ===============================================================
      --
    END LOOP get_header_id_loop;
    --
-- == 2009/10/08 V1.1 Added START ===============================================================
    CLOSE cur_trans_oif_data;
-- == 2009/10/08 V1.1 Added END   ===============================================================
    --
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_trans_oif_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : １）初期処理
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'init';  -- プログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 入力パラメータの出力
    -- ===============================================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi_10387
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_outmsg
    );
    -- 空行を出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    --
    -- ===============================================
    -- 起動時刻の設定
    -- ===============================================
    gd_start_date   :=  SYSDATE;
    --
    -- ===============================================
    -- 完了チェック待機時間の取得
    -- ===============================================
    gn_check_wait_second  :=  NVL(fnd_profile.value(cv_prf_check_wait_second), 60);
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_outmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2
  , ov_retcode      OUT VARCHAR2
  , ov_errmsg       OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- 固定ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'submain';
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;  -- 出力用メッセージ
    ln_warn_flg     NUMBER         DEFAULT 0;     -- 警告フラグ(警告なし:0 警告発生：1)
--
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 対象データなし例外 ***
    target_no_data_expt  EXCEPTION;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- １）初期処理
    -- ===============================================
    init(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ２）資材取引OIFテーブル情報抽出処理
    -- ３）資材取引OIFヘッダID取得処理
    -- ===============================================
    get_trans_oif_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- == 2009/10/08 V1.1 Modified START ===============================================================
--    IF (gt_mtl_trans_oif.COUNT <> 0) THEN
    IF (gn_target_cnt <> 0) THEN
-- == 2009/10/08 V1.1 Modified END   ===============================================================
      -- 資材取引OIFデータが取得された場合、以下を実行
      --
      -- ===============================================
      -- ４）資材取引OIFヘッダID更新処理
      -- ===============================================
      set_trans_oif_header_id(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode  :=  lv_retcode;
      END IF;
      --
      COMMIT;
      --
  --
      -- ===============================================
      -- ５）取引ワーカー起動処理
      -- ===============================================
      start_trans_worker(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode  :=  lv_retcode;
      END IF;
  --
      -- ===============================================
      -- ６）取引ワーカー終了チェック
      -- ===============================================
      IF (gt_request_id_tbl.COUNT <> 0) THEN
        -- 取引ワーカーが１回以上起動されている場合
        chk_trans_worker(
          ov_errbuf   => lv_errbuf
        , ov_retcode  => lv_retcode
        , ov_errmsg   => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode  :=  lv_retcode;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2
  , retcode         OUT VARCHAR2
  )
  IS
--
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(30)  := 'main';  -- プログラム名
--
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラーメッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターンコード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザーエラーメッセージ
    lv_outmsg        VARCHAR2(5000) DEFAULT NULL;              -- メッセージ変数
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- メッセージコード

--
  BEGIN
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf       => lv_errbuf
    , ov_retcode      => lv_retcode
    , ov_errmsg       => lv_errmsg
    );
--
    -- ===============================================
    -- ７）終了処理
    -- ===============================================
    -- ============================
    --  エラー出力
    -- ============================
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_errbuf
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
--
    -- ============================
    --  対象件数出力
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10395
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  更新件数出力
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10391
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  警告件数出力
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10396
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  ワーカー起動回数
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10392
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_conc_start_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  ワーカーエラー件数
    -- ============================
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcoi
                    , iv_name         => cv_msg_xxcoi_10394
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_sub_conc_err_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  エラー件数出力
    -- ============================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                    , iv_name         => cv_msg_xxccp1_90002
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ============================
    --  空行出力
    -- ============================
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ============================
    -- 処理終了メッセージ出力
    -- ============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_outmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                    , iv_name         => lv_message_code
                    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_outmsg
    );
--
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
--
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOI015A01C;
/