CREATE OR REPLACE PACKAGE BODY XXCMN970001C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN970001C(body)
 * Description      : 棚卸月末在庫テーブルパージ
 * MD.050           : T_MD050_BPO_97A_棚卸月末在庫テーブルパージ
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
 *  2012/11/28    1.00  Miyamoto         新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_date_format_s   CONSTANT VARCHAR2(10) := 'YYYYMM';
--
  cv_purge_type      CONSTANT VARCHAR2(1)  := '0';                        --ﾊﾟｰｼﾞﾀｲﾌﾟ(0:ﾊﾟｰｼﾞ期間)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9701';                     --ﾊﾟｰｼﾞ定義ｺｰﾄﾞ
--
  --=============
  --メッセージ
  --=============
  cv_appl_short_name  CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part         CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_purge_range      
                      CONSTANT VARCHAR2(50) := 'XXCMN_PURGE_RANGE_MONTH';        --XXCMN:パージレンジ月数
  cv_xxcmn_commit_range     
                      CONSTANT VARCHAR2(50)   := 'XXCMN_COMMIT_RANGE';   --XXCMN:パージ/バックアップ分割コミット数

--
  cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
  cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- 件数メッセージ用トークン名（件数）
  cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- 件数メッセージ用トークン名（テーブル名）
  cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- 件数メッセージ用トークン名（処理名）
  cv_table_cnt_xsims  CONSTANT VARCHAR2(100) := '棚卸月末在庫';                -- 件数メッセージ用テーブル名
  cv_shori_cnt_target CONSTANT VARCHAR2(100) := '対象';                -- 件数メッセージ用処理名
  cv_shori_cnt_delete CONSTANT VARCHAR2(100) := '削除';                -- 件数メッセージ用処理名
  cv_shori_cnt_normal CONSTANT VARCHAR2(100) := '正常';                -- 件数メッセージ用処理名
  cv_shori_cnt_error  CONSTANT VARCHAR2(100) := 'エラー';                -- 件数メッセージ用処理名
  cv_get_priod_msg    CONSTANT VARCHAR2(50)   := 'APP-XXCMN-11011';      --パージ期間取得失敗
  cv_get_profile_msg  CONSTANT VARCHAR2(50)   := 'APP-XXCMN-10002';      --ﾌﾟﾛﾌｧｲﾙ値取得失敗
  cv_get_param_msg    CONSTANT VARCHAR2(50)   := 'APP-XXCMN-10155';      --パラメータの ＆ERROR_PARAM ( ＆ERROR_VALUE )が不正です
  cv_token_profile    CONSTANT VARCHAR2(50)   := 'NG_PROFILE';           --ﾌﾟﾛﾌｧｲﾙ取得MSG用ﾄｰｸﾝ名
  cv_proc_date_msg    CONSTANT VARCHAR2(50)   := 'APP-XXCMN-11014';      --処理日出力
  cv_par_token        CONSTANT VARCHAR2(50)   := 'PAR';                  --処理日MSG用ﾄｰｸﾝ名
  cv_local_others_msg CONSTANT VARCHAR2(100)  := 'APP-XXCMN-11026';      -- ＆SHORI 処理に失敗しました。【 ＆KINOUMEI 】 ＆KEYNAME ： ＆KEY
  cv_token_param      CONSTANT VARCHAR2(50)   := 'ERROR_PARAM';
  cv_token_value      CONSTANT VARCHAR2(50)   := 'ERROR_VALUE';
  cv_token_shori      CONSTANT VARCHAR2(50)   := 'SHORI';
  cv_token_kinoumei   CONSTANT VARCHAR2(50)   := 'KINOUMEI';
  cv_token_keyname    CONSTANT VARCHAR2(50)   := 'KEYNAME';
  cv_token_key        CONSTANT VARCHAR2(50)   := 'KEY';
  cv_token_proc_date  CONSTANT VARCHAR2(100)  := '処理日';
  cv_token_bkup       CONSTANT VARCHAR2(100)  := 'バックアップ';
  cv_token_sims       CONSTANT VARCHAR2(100)  := '棚卸月末在庫テーブル';
  cv_token_stock_id   CONSTANT VARCHAR2(100)  := '棚卸月末在庫ID';
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN970001C';  -- パッケージ名
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
    ln_del_cnt_yet                  NUMBER DEFAULT 0;                    -- 未コミット削除件数
    ln_purge_period                 NUMBER;                              -- パージ期間
    ln_commit_range                 NUMBER;                              -- 分割コミット数
    ln_purge_range                  NUMBER;                              -- パージレンジ
    lt_invent_monthly_stock_id      xxinv_stc_inventory_month_stck.invent_monthly_stock_id%TYPE;
    lt_standard_ym                  xxcmn_stc_inv_month_stck_arc.invent_ym%TYPE; -- 基準年月
    lv_process_step                 VARCHAR2(100);

--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
/*
    -- 棚卸月末在庫（アドオン）
    CURSOR パージ対象棚卸月末在庫（アドオン）取得
      it_基準年月  IN 棚卸月末在庫（アドオン）バックアップ.棚卸年月%TYPE
      in_パージレンジ IN NUMBER
    IS
      SELECT 
             棚卸月末在庫（アドオン）．棚卸月末在庫ＩＤ
      FROM 棚卸月末在庫（アドオン）バックアップ
           ,   棚卸月末在庫（アドオン）
      WHERE 棚卸月末在庫（アドオン）バックアップ．棚卸年月 >= TO_CHAR(ADD_MONTHS(TO_DATE(it_基準年月，'YYYYMM')，(in_パージレンジ * -1))，'YYYYMM')
      AND 棚卸月末在庫（アドオン）バックアップ．棚卸年月 < iv_基準年月
      AND 棚卸月末在庫（アドオン）．棚卸月末在庫ID = 棚卸月末在庫（アドオン）バックアップ．棚卸月末在庫ID
*/
--
  CURSOR purge_stc_inv_month_stck_cur(
      it_standard_ym        xxcmn_stc_inv_month_stck_arc.invent_ym%TYPE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT 
        xsims.invent_monthly_stock_id AS invent_monthly_stock_id
      FROM
        xxcmn_stc_inv_month_stck_arc       xsimsa
       ,xxinv_stc_inventory_month_stck     xsims
      WHERE
          xsimsa.invent_ym IS NOT NULL
        AND xsimsa.invent_ym >= TO_CHAR(ADD_MONTHS(TO_DATE(it_standard_ym, cv_date_format_s), (in_purge_range * -1)), cv_date_format_s)
        AND xsimsa.invent_ym  < it_standard_ym
        AND xsims.invent_monthly_stock_id = xsimsa.invent_monthly_stock_id
      ;
    -- <カーソル名>レコード型
    TYPE purge_stc_inv_month_stck_ttype IS TABLE OF purge_stc_inv_month_stck_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_purge_stc_inv_month_stck_tab       purge_stc_inv_month_stck_ttype;
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
    lv_process_step := 'パージ期間取得';
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
    lv_process_step := 'パラメータ確認';
    BEGIN
      /*
      iv_proc_dateがNULLの場合
        lv_基準年月 := TO_CHAR(ADD_MONTHS(処理日取得共通関数より取得した処理日，(ln_パージ期間 * -1))，'YYYYMM');
--
      iv_proc_dateがNULLでない場合
        lv_基準年月 := TO_CHAR(ADD_MONTHS(TO_DATE(iv_proc_date, 'YYYY/MM/DD')，(ln_パージ期間 * -1))，'YYYYMM');
       */
      IF ( iv_proc_date IS NULL ) THEN
--
        lt_standard_ym := TO_CHAR(ADD_MONTHS(xxcmn_common4_pkg.get_syori_date, (ln_purge_period * -1)), cv_date_format_s);
--
      ELSE
--
        lt_standard_ym := TO_CHAR(ADD_MONTHS(TO_DATE(iv_proc_date, cv_date_format), (ln_purge_period * -1)), cv_date_format_s);
--
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_param_msg
                      ,iv_token_name1  => cv_token_param
                      ,iv_token_value1 => cv_token_proc_date
                      ,iv_token_name2  => cv_token_value
                      ,iv_token_value2 => iv_proc_date
                     );
        RAISE local_process_expt;
    END;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    lv_process_step := 'プロファイル取得';
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ分割コミット数);
    */
    BEGIN
      ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
    -- パージ対象棚卸月末在庫（アドオン）取得
    -- ===============================================
    lv_process_step := 'バックアップ対象棚卸月末在庫取得';
    /*
    OPEN パージ対象棚卸月末在庫（アドオン）取得（ld_基準日，ln_パージレンジ）;
    FETCH パージ対象棚卸月末在庫（アドオン）取得  BULK COLLECT INTO lt_棚卸月末在庫;
    */
    OPEN purge_stc_inv_month_stck_cur(lt_standard_ym,ln_purge_range);
    FETCH purge_stc_inv_month_stck_cur BULK COLLECT INTO l_purge_stc_inv_month_stck_tab;
--
    /*
    パージ対象件数を取得する
    gn_対象件数 := 棚卸月末在庫.COUNT
    */
    gn_target_cnt          := l_purge_stc_inv_month_stck_tab.COUNT;
--
    /*
    フェッチ行が存在した場合は
    FOR ln_main_idx in 1 .. lt_棚卸月末在庫.COUNT  LOOP  パージ対象棚卸月末在庫（アドオン）取得
    */
    IF ( l_purge_stc_inv_month_stck_tab.COUNT ) > 0 THEN
      << purge_stc_inv_month_stck >>
      FOR ln_main_idx in 1 .. l_purge_stc_inv_month_stck_tab.COUNT
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
          ln_未コミット削除件数 > 0 かつ
           MOD(ln_未コミット削除件数, ln_分割コミット数) = 0の場合
          */
          IF (  (ln_del_cnt_yet > 0)
            AND (MOD(ln_del_cnt_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_削除件数 := ln_削除件数 + ln_未コミット削除件数;
            ln_未コミット削除件数 := 0;
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
        lt_棚卸月末在庫ID := l_purge_stc_inv_month_stck_tab．棚卸月末在庫ID;
        */
        lt_invent_monthly_stock_id      := l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id;
--
        -- ===============================================
        -- パージ対象棚卸月末在庫（アドオン）、バックアップ共にロック
        -- ===============================================
        /*
        SELECT
              棚卸月末在庫(アドオン).棚卸月末在庫ID
        FROM 棚卸月末在庫(アドオン)
             棚卸月末在庫(アドオン)バックアップ
        WHERE 棚卸月末在庫(アドオン).棚卸月末在庫ID =l_棚卸月末在庫_tab(ln_main_idx).棚卸月末在庫ID
        AND 棚卸月末在庫(アドオン).棚卸月末在庫ID = 棚卸月末在庫(アドオン)バックアップ．棚卸月末在庫ID
        FOR UPDATE NOWAIT
        ;
         */
        SELECT
          xsims.invent_monthly_stock_id    AS invent_monthly_stock_id
        INTO
          lt_invent_monthly_stock_id
        FROM
           xxinv_stc_inventory_month_stck     xsims
          ,xxcmn_stc_inv_month_stck_arc       xsimsa
        WHERE
          xsims.invent_monthly_stock_id = l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id
        AND xsims.invent_monthly_stock_id = xsimsa.invent_monthly_stock_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- 棚卸月末在庫（アドオン）パージ
        -- ===============================================
        /*
        DELETE 棚卸月末在庫（アドオン）
        WHERE 棚卸月末在庫ID = l_棚卸月末在庫_tab(ln_main_idx).棚卸月末在庫ID
         */
        DELETE FROM
          xxinv_stc_inventory_month_stck
        WHERE
          invent_monthly_stock_id = l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id
        ;
--
        /*
        UPDATE 棚卸月末在庫（アドオン）バックアップ
        SET パージ実行日 = SYSDATE
            ,  パージ要求ID = 要求ID
        WHERE 棚卸月末在庫ID = l_棚卸月末在庫_tab(ln_main_idx)．棚卸月末在庫ID
         */
        UPDATE
          xxcmn_stc_inv_month_stck_arc
        SET
          purge_date          = SYSDATE
         ,purge_request_id    = cn_request_id
        WHERE
          invent_monthly_stock_id = l_purge_stc_inv_month_stck_tab(ln_main_idx).invent_monthly_stock_id
        ;
--
        /*
        ln_未コミット削除件数 := ln_未コミット削除件数 + 1;
        */
        ln_del_cnt_yet := ln_del_cnt_yet + 1;
--
      /*
      END LOOP パージ対象棚卸月末在庫（アドオン）取得;
      */
      END LOOP purge_stc_inv_month_stck;
--
      /*
      ln_削除件数 := ln_削除件数 + ln_未コミット削除件数;
      ln_未コミット削除件数 := 0;
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
      IF ( lt_invent_monthly_stock_id IS NOT NULL ) THEN
        --＆SHORI 処理に失敗しました。【 ＆KINOUMEI 】 ＆KEYNAME ： ＆KEY
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_token_bkup
                      ,iv_token_name2  => cv_token_kinoumei
                      ,iv_token_value2 => cv_token_sims
                      ,iv_token_name3  => cv_token_keyname
                      ,iv_token_value3 => cv_token_stock_id
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(lt_invent_monthly_stock_id)
                     );
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
        ov_errmsg := lv_process_step||cv_msg_part||SQLERRM;
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
                    ,iv_token_value1 => cv_table_cnt_xsims
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
                    ,iv_token_value1 => cv_table_cnt_xsims
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
                    ,iv_token_value1 => cv_table_cnt_xsims
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
                    ,iv_token_value1 => cv_table_cnt_xsims
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
END XXCMN970001C;
/
