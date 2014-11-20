CREATE OR REPLACE PACKAGE BODY XXCMN960008C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960008C(body)
 * Description      : 配車配送計画アドオンパージ
 * MD.050           : T_MD050_BPO_96H_配車配送計画アドオンパージ
 * Version          : 1.00
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/11/13   1.00  宮本             新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by      CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date   CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date
                     CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login
                     CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id 
                     CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id      CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    
                     CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
--
  cv_purge_type      CONSTANT VARCHAR2(1)  := '0';                        --ﾊﾟｰｼﾞﾀｲﾌﾟ(0:ﾊﾟｰｼﾞ期間)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9601';                     --ﾊﾟｰｼﾞ定義ｺｰﾄﾞ
--
  --=============
  --メッセージ
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_purge_range      
                     CONSTANT VARCHAR2(50) := 'XXCMN_PURGE_RANGE';        --XXCMN:パージレンジ
  --XXCMN:パージ/バックアップ分割コミット数
  cv_xxcmn_commit_range     
                     CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
  cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- 件数メッセージ用トークン名（件数）
  cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- 件数メッセージ用トークン名（テーブル名）
  cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- 件数メッセージ用トークン名（処理名）
  cv_table_cnt_xcs    CONSTANT VARCHAR2(100) := '配車配送計画';                -- 件数メッセージ用テーブル名
  cv_shori_cnt_target CONSTANT VARCHAR2(100) := '対象';                -- 件数メッセージ用処理名
  cv_shori_cnt_delete CONSTANT VARCHAR2(100) := '削除';                -- 件数メッセージ用処理名
  cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '正常';                -- 件数メッセージ用処理名
  cv_shori_cnt_error  CONSTANT VARCHAR2(100) := 'エラー';                -- 件数メッセージ用処理名
  cv_get_priod_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11011';          --パージ期間取得失敗
  cv_get_profile_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';          --ﾌﾟﾛﾌｧｲﾙ値取得失敗
  cv_token_profile    CONSTANT VARCHAR2(50) := 'NG_PROFILE';               --ﾌﾟﾛﾌｧｲﾙ取得MSG用ﾄｰｸﾝ名
  cv_proc_date_msg    CONSTANT VARCHAR2(50) := 'APP-XXCMN-11014';          --処理日出力
  cv_par_token        CONSTANT VARCHAR2(10) := 'PAR';                      --処理日MSG用ﾄｰｸﾝ名
  cv_others_err_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11024';          --削除処理失敗
  cv_token_key        CONSTANT VARCHAR2(10) := 'KEY';                      --削除処理MSG用ﾄｰｸﾝ名
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                       -- 対象件数
  gn_normal_cnt             NUMBER;                                       -- 正常件数
  gn_error_cnt              NUMBER;                                       -- エラー件数
  gn_del_cnt                NUMBER;                                       -- 削除件数
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
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960008C';  -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,     --   1.処理日
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf               VARCHAR2(5000);                      -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                         -- リターン・コード
    lv_errmsg               VARCHAR2(5000);                      -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_del_cnt_yet          NUMBER DEFAULT 0;                    -- 未コミット削除件数
    ln_purge_period         NUMBER;                              -- パージ期間
    ld_standard_date        DATE;                                -- 基準日
    ln_commit_range         NUMBER;                              -- 分割コミット数
    ln_purge_range          NUMBER;                              -- パージレンジ
    lt_transaction_id       xxwsh_carriers_schedule.transaction_id%TYPE;

--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
/*
    CURSOR パージ対象配車配送計画（アドオン）取得
      id_基準日  IN DATE
      in_パージレンジ IN NUMBER
    IS
      SELECT 
             配車配送計画（アドオン）．トランザクションＩＤ
      FROM 配車配送計画（アドオン）バックアップ
           ,   配車配送計画（アドオン）
      WHERE 配車配送計画（アドオン）バックアップ．着荷日 IS NOT NULL
      AND 配車配送計画（アドオン）バックアップ．着荷日 >= id_基準日 - in_パージレンジ
      AND 配車配送計画（アドオン）バックアップ．着荷日 < id_基準日
      AND 配車配送計画（アドオン）．トランザクションID = 配車配送計画（アドオン）バックアップ．トランザクションID
      UNION ALL
      SELECT 
             配車配送計画（アドオン）．トランザクションＩＤ
      FROM 配車配送計画（アドオン）バックアップ
           ,   配車配送計画（アドオン）
      WHERE 配車配送計画（アドオン）バックアップ．着荷日 IS NULL
      AND 配車配送計画（アドオン）バックアップ．着荷予定日 >= id_基準日 - in_パージレンジ
      AND 配車配送計画（アドオン）バックアップ．着荷予定日 < id_基準日
      AND 配車配送計画（アドオン）．トランザクションID = 配車配送計画（アドオン）バックアップ．トランザクションID
*/
--
  CURSOR purge_carriers_schedule_cur(
      id_standard_date      DATE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT 
        xcs.transaction_id AS transaction_id
      FROM
        xxcmn_carriers_schedule_arc xcsa
       ,xxwsh_carriers_schedule     xcs
      WHERE
          xcsa.arrival_date IS NOT NULL
        AND xcsa.arrival_date >= id_standard_date - in_purge_range
        AND xcsa.arrival_date  < id_standard_date
        AND xcs.transaction_id = xcsa.transaction_id
      UNION ALL
      SELECT 
        xcs.transaction_id AS transaction_id
      FROM
        xxcmn_carriers_schedule_arc xcsa
       ,xxwsh_carriers_schedule     xcs
      WHERE
          xcsa.arrival_date IS NULL
        AND xcsa.schedule_arrival_date >= id_standard_date - in_purge_range
        AND xcsa.schedule_arrival_date < id_standard_date
        AND xcs.transaction_id = xcsa.transaction_id
      ;
    -- <カーソル名>レコード型
    TYPE purge_carriers_schedule_ttype IS TABLE OF purge_carriers_schedule_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_purge_carrier_schedule_tab       purge_carriers_schedule_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode        := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_del_cnt        := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- パージ期間取得
    -- ===============================================
    /*
    ln_パージ期間 := バックアップ期間/パージ期間取得関数（cv_パージタイプ,cv_パージコード）;
     */
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
--
    /*
    ln_パージ期間がNULLの場合
      ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                            iv_アプリケーション短縮名  => cv_appl_short_name
                           ,iv_メッセージコード        => cv_get_priod_msg
                          );
      ov_リターンコード := cv_status_error;
      RAISE local_process_expt 例外処理
     */
    IF ( ln_purge_period IS NULL ) THEN
--
      --パージ期間の取得に失敗しました。
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    /*
    iv_proc_dateがNULLの場合
      ld_基準日 := 処理日取得共通関数より取得した処理日 - ln_パージ期間;
--
    iv_proc_dateがNULLでない場合
      ld_基準日 := TO_DATE(iv_proc_date) - ln_パージ期間;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ分割コミット数);
    */
    BEGIN
      ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
--
      /* ln_分割コミット数がNULLの場合
           ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                       iv_アプリケーション短縮名  => cv_appl_short_name
                      ,iv_メッセージコード         => cv_get_profile_msg
                      ,iv_トークン名1  => cv_token_profile
                      ,iv_トークン値1 => cv_xxcmn_commit_range
                     );
           ov_リターンコード := cv_status_error;
           RAISE local_process_expt 例外処理
      */
--
      IF ( ln_commit_range IS NULL ) THEN
        -- プロファイル[ NG_PROFILE ]の取得に失敗しました。
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '分割コミット数:' || TO_CHAR(ln_commit_range));
--
    /*
    ln_パージレンジ   := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージレンジ);
    */
    BEGIN
      ln_purge_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
--
      /*
      ln_パージレンジがNULLの場合
      ov_エラーメッセージ := xxcmn_common_pkg.get_msg(
                     iv_アプリケーション短縮名  => cv_appl_short_name
                    ,iv_メッセージコード         => cv_get_profile_msg
                    ,iv_トークン名1  => cv_token_profile
                    ,iv_トークン値1 => cv_xxcmn_purge_range
                   );
      ov_リターンコード := cv_status_error;
      RAISE local_process_expt 例外処理
      */
      IF ( ln_purge_range IS NULL ) THEN
        -- プロファイル[ NG_PROFILE ]の取得に失敗しました。
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_purge_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_purge_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
--
    -- ===============================================
    -- パージ対象配車配送計画（アドオン）取得
    -- ===============================================
    /*
    OPEN パージ対象配車配送計画（アドオン）取得（ld_基準日，ln_パージレンジ）;
    FETCH パージ対象配車配送計画（アドオン）取得  BULK COLLECT INTO lt_配車配送計画;
    */
    OPEN purge_carriers_schedule_cur(ld_standard_date,ln_purge_range);
    FETCH purge_carriers_schedule_cur BULK COLLECT INTO l_purge_carrier_schedule_tab;
--
    /*
    パージ対象件数を取得する
    gn_対象件数 := 配車配送計画.COUNT
    */
    gn_target_cnt          := l_purge_carrier_schedule_tab.COUNT;
--
    /*
    フェッチ行が存在した場合は
    FOR ln_main_idx in 1 .. lt_配車配送計画.COUNT  LOOP  パージ対象配車配送計画（アドオン）取得
    */
    IF ( l_purge_carrier_schedule_tab.COUNT ) > 0 THEN
      << purge_carriers_schedule >>
      FOR ln_main_idx in 1 .. l_purge_carrier_schedule_tab.COUNT
      LOOP
--
        -- ===============================================
        -- 分割コミット
        -- ===============================================
        /*
        NVL(ln_分割コミット数, 0) <> 0の場合
         */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
          /*
          ln_未コミット削除件数（配車配送計画（アドオン）） > 0 かつ
           MOD(ln_未コミット削除件数（配車配送計画（アドオン））, ln_分割コミット数) = 0の場合
          */
          IF (  (ln_del_cnt_yet > 0)
            AND (MOD(ln_del_cnt_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_削除件数（配車配送計画（アドオン）） := ln_削除件数（配車配送計画（アドオン））
                                                             + ln_未コミット削除件数（配車配送計画（アドオン））;
            ln_未コミット削除件数（配車配送計画（アドオン）） := 0;
            COMMIT;
            */
            gn_del_cnt     := gn_del_cnt + ln_del_cnt_yet;
            ln_del_cnt_yet := 0;
            COMMIT;
--
          END IF;
--
        END IF;
--
        /*
        lt_トランザクションID := lt_配車配送計画．トランザクションID;
        */
        lt_transaction_id      := l_purge_carrier_schedule_tab(ln_main_idx).transaction_id;
--
        -- ===============================================
        -- パージ対象配車配送計画（アドオン）、バックアップ共にロック
        -- ===============================================
        /*
        SELECT
              配車配送計画（アドオン）．トランザクションID
        FROM 配車配送計画（アドオン）
             配車配送計画（アドオン）バックアップ
        WHERE 配車配送計画（アドオン）．トランザクションID =l_配車配送計画_tab(ln_main_idx)．トランザクションID
        AND 配車配送計画（アドオン）．トランザクションID = 配車配送計画（アドオン）バックアップ．トランザクションID
        FOR UPDATE NOWAIT
         */
        SELECT
          xcs.transaction_id
        INTO
          lt_transaction_id
        FROM
           xxwsh_carriers_schedule     xcs
          ,xxcmn_carriers_schedule_arc xcsa
        WHERE
          xcs.transaction_id = l_purge_carrier_schedule_tab(ln_main_idx).transaction_id
        AND xcs.transaction_id = xcsa.transaction_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- 配車配送計画（アドオン）パージ
        -- ===============================================
        /*
        DELETE 配車配送計画（アドオン）
        WHERE トランザクションID = l_配車配送計画_tab(ln_main_idx)．トランザクションID
         */
        DELETE FROM
          xxwsh_carriers_schedule
        WHERE
          transaction_id = l_purge_carrier_schedule_tab(ln_main_idx).transaction_id
        ;
--
        /*
        UPDATE 配車配送計画（アドオン）バックアップ
        SET パージ実行日 = SYSDATE
            ,  パージ要求ID = 要求ID
        WHERE トランザクションID = l_配車配送計画_tab(ln_main_idx)．トランザクションID
         */
        UPDATE
          xxcmn_carriers_schedule_arc
        SET
          purge_date          = SYSDATE
         ,purge_request_id    = cn_request_id
        WHERE
          transaction_id = l_purge_carrier_schedule_tab(ln_main_idx).transaction_id
        ;
--
        /*
        ln_未コミット削除件数（配車配送計画（アドオン）） := ln_未コミット削除件数（配車配送計画（アドオン）） + 1;
        */
        ln_del_cnt_yet := ln_del_cnt_yet + 1;
--
      /*
      END LOOP パージ対象配車配送計画（アドオン）取得;
      */
      END LOOP purge_carriers_schedule;
--
      /*
      ln_削除件数（配車配送計画（アドオン）） := ln_削除件数（配車配送計画（アドオン））
                                                            + ln_未コミット削除件数（配車配送計画（アドオン））;
      ln_未コミット削除件数（配車配送計画（アドオン）） := 0;
      */
      gn_del_cnt     := gn_del_cnt + ln_del_cnt_yet;
      ln_del_cnt_yet := 0;
    END IF;
--
  -- ===============================================
  -- 例外処理
  -- ===============================================
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
      IF ( lt_transaction_id IS NOT NULL ) THEN
        --削除処理に失敗しました。【配車配送計画（アドオン）】取引ID： KEY
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(lt_transaction_id)
                     );
        gn_error_cnt := gn_error_cnt + 1;
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_proc_date  IN  VARCHAR2       --   1.処理日
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- ログ出力処理
    -- ===============================================
    --パラメータ(処理日： PAR)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 対象件数出力(対象件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_target
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 削除件数出力(削除件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 正常件数出力(正常件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_normal
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt)      --削除件数
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力(エラー件数： CNT 件)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xcs
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_error
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- -----------------------
    --  処理判定(submain)
    -- -----------------------
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力(出力の表示)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
--
      --エラー出力(ログの表示)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- ===============================================
    -- 終了処理
    -- ===============================================
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  -- ===============================================
  -- 例外処理
  -- ===============================================
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
END XXCMN960008C;
/
