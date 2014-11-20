CREATE OR REPLACE PACKAGE BODY XXCMN960001C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960001C(body)
 * Description      : 受注アドオンパージ
 * MD.050           : T_MD050_BPO_96A_受注アドオンパージ
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/15   1.00  Hiroshi.Ogawa     新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1';   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2';  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
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
  gn_del_cnt_header         NUMBER;                                             -- 削除件数（受注ヘッダ（アドオン））
  gn_del_cnt_line           NUMBER;                                             -- 削除件数（受注明細（アドオン））
  gn_del_cnt_lot            NUMBER;                                             -- 削除件数（移動ロット詳細（アドオン））
  gt_order_header_id        xxwsh_order_headers_all.order_header_id%TYPE;       -- 対象受注ヘッダアドオンID
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960001C'; -- パッケージ名
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
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_get_priod_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- パージ期間の取得に失敗しました。
    cv_get_profile_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_local_others_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11010';  -- 削除処理に失敗しました。【受注（アドオン）】受注ヘッダアドオンID： ＆KEY
    cv_token_profile       CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key           CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range  CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_purge_range   CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';
--
    cv_shipping            CONSTANT VARCHAR2(2)   := '04';
    cv_sikyu               CONSTANT VARCHAR2(2)   := '08';
    cv_mov_shipping        CONSTANT VARCHAR2(2)   := '10';
    cv_mov_sikyu           CONSTANT VARCHAR2(2)   := '30';
--
    cv_date_format         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '0';                               -- パージタイプ（0:パージ処理期間）
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';                            -- パージ定義コード
--
    -- *** ローカル変数 ***
    ln_del_cnt_header_yet     NUMBER DEFAULT 0;                                 -- 未コミット削除件数（受注ヘッダ（アドオン））
    ln_del_cnt_line_yet       NUMBER DEFAULT 0;                                 -- 未コミット削除件数（受注明細（アドオン））
    ln_del_cnt_lot_yet        NUMBER DEFAULT 0;                                 -- 未コミット削除件数（移動ロット詳細（アドオン））
    ln_purge_period           NUMBER;                                           -- パージ期間
    ld_standard_date          DATE;                                             -- 基準日
    ln_commit_range           NUMBER;                                           -- 分割コミット数
    ln_purge_range            NUMBER;                                           -- パージレンジ
    lv_process_part           VARCHAR2(1000);                                   -- 処理部
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    -- 受注ヘッダ（アドオン）
    CURSOR パージ対象受注ヘッダ（アドオン）取得
      id_基準日  IN DATE
      in_パージレンジ IN NUMBER
    IS
      SELECT 
             受注ヘッダ（アドオン）．受注ヘッダアドオンＩＤ
      FROM 受注ヘッダ（アドオン）バックアップ
           ,    受注ヘッダ（アドオン）
      WHERE 受注ヘッダ（アドオン）バックアップ．ステータス IN ('04','08')
      AND 受注ヘッダ（アドオン）バックアップ．着荷日 >= id_基準日 - in_パージレンジ
      AND 受注ヘッダ（アドオン）バックアップ．着荷日 < id_基準日
      AND 受注ヘッダ（アドオン）．受注ヘッダアドオンID = 受注ヘッダ（アドオン）バックアップ．受注ヘッダアドオンID
      UNION ALL
      SELECT 
             受注ヘッダ（アドオン）．受注ヘッダアドオンＩＤ
      FROM 受注ヘッダ（アドオン）バックアップ
           ,    受注ヘッダ（アドオン）
      WHERE 受注ヘッダ（アドオン）バックアップ．ステータス NOT IN ('04','08')
      AND 受注ヘッダ（アドオン）バックアップ．着荷予定日 >= id_基準日 - in_パージレンジ
      AND 受注ヘッダ（アドオン）バックアップ．着荷予定日 < id_基準日
      AND 受注ヘッダ（アドオン）．受注ヘッダアドオンID = 受注ヘッダ（アドオン）バックアップ．受注ヘッダアドオンID
     */
    CURSOR purge_order_header_cur(
      id_standard_date           DATE
     ,in_purge_range             NUMBER
    )
    IS
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa xoha) INDEX(xohaa XXCMN_OHAA_N15) */
              xoha.order_header_id      AS order_header_id
      FROM    xxcmn_order_headers_all_arc  xohaa
             ,xxwsh_order_headers_all      xoha
      WHERE   xohaa.req_status    IN (cv_shipping, cv_sikyu)
      AND     xohaa.arrival_date  >= id_standard_date - in_purge_range
      AND     xohaa.arrival_date   < id_standard_date
      AND     xoha.order_header_id = xohaa.order_header_id
      UNION ALL
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa xoha) INDEX(xohaa XXCMN_OHAA_N14) */
              xoha.order_header_id      AS order_header_id
      FROM    xxcmn_order_headers_all_arc  xohaa
             ,xxwsh_order_headers_all      xoha
      WHERE   xohaa.req_status         NOT IN (cv_shipping, cv_sikyu)
      AND     xohaa.schedule_arrival_date  >= id_standard_date - in_purge_range
      AND     xohaa.schedule_arrival_date   < id_standard_date
      AND     xoha.order_header_id          = xohaa.order_header_id
    ;
    /*
    -- 受注明細（アドオン）
    CURSOR パージ対象受注明細（アドオン）取得
      it_受注ヘッダアドオンＩＤ IN 受注ヘッダ（アドオン）．受注ヘッダアドオンＩＤ%TYPE
    IS
      SELECT
             受注明細（アドオン）．受注明細アドオンＩＤ
      FROM 受注明細（アドオン）
      WHERE 受注明細（アドオン）．受注ヘッダアドオンＩＤ = in_受注ヘッダアドオンＩＤ
      FOR UPDATE NOWAIT
     */
    CURSOR purge_order_line_cur(
      it_order_header_id         xxwsh_order_headers_all.order_header_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xola XXWSH_OL_N01) */
              xola.order_line_id        AS order_line_id
      FROM    xxwsh_order_lines_all  xola
      WHERE   xola.order_header_id = it_order_header_id
      FOR UPDATE NOWAIT
    ;
    /*
    -- 移動ロット詳細（アドオン）
    CURSOR パージ対象移動ロット詳細（アドオン）取得
      it_受注明細アドオンＩＤ IN 受注明細（アドオン）．受注明細アドオンＩＤ%TYPE
    IS
      SELECT
             移動ロット詳細（アドオン）．ロット詳細ＩＤ
      FROM 移動ロット詳細（アドオン）
      WHERE 移動ロット詳細（アドオン）．明細ＩＤ = in_受注明細アドオンＩＤ
      AND 移動ロット詳細（アドオン）．文書タイプコード IN ('10','30')
      FOR UPDATE NOWAIT
     */
    CURSOR purge_mov_lot_dtl_cur(
      it_order_line_id           xxwsh_order_lines_all.order_line_id%TYPE
    )
    IS
      SELECT  /*+ INDEX(xmld XXINV_MLD_N01) */
              xmld.mov_lot_dtl_id       AS mov_lot_dtl_id
      FROM    xxinv_mov_lot_details  xmld
      WHERE   xmld.mov_line_id        = it_order_line_id
      AND     xmld.document_type_code IN (cv_mov_shipping, cv_mov_sikyu)
      FOR UPDATE NOWAIT
    ;
    -- <カーソル名>レコード型
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
    gn_warn_cnt   := 0;
    gn_del_cnt_header := 0;
    gn_del_cnt_line   := 0;
    gn_del_cnt_lot    := 0;
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
    ln_パージ期間 := パージ期間取得共通関数（cv_パージ定義コード）;
     */
    lv_process_part := 'パージ期間取得';
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_purge_period IS NULL ) THEN
--
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
--
      ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_パージ期間;
--
    iv_proc_dateがNULLでないの場合
--
      ld_基準日 := TO_DATE(iv_proc_date) - ln_パージ期間;
     */
    lv_process_part := 'INパラメータの確認';
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
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ/バックアップ分割コミット数));
    ln_パージレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージレンジ));
     */
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）';
    ln_commit_range := fnd_profile.value(cv_xxcmn_commit_range);
    IF ( ln_commit_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_commit_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_purge_range || '）';
    ln_purge_range  := fnd_profile.value(cv_xxcmn_purge_range);
    IF ( ln_purge_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_purge_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- パージ対象受注ヘッダ（アドオン）取得
    -- ===============================================
    /*
    FOR lr_header_rec IN パージ対象受注ヘッダ（アドオン）取得（ld_基準日，ln_パージレンジ） LOOP
     */
    << purge_order_header_loop >>
    FOR lr_header_rec IN purge_order_header_cur(
                           ld_standard_date
                          ,ln_purge_range
                         )
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
        ln_未コミット削除件数（受注ヘッダ（アドオン）） > 0 かつ MOD(ln_未コミット削除件数（受注ヘッダ（アドオン））, ln_分割コミット数) = 0の場合
         */
        IF (  (ln_del_cnt_header_yet > 0)
          AND (MOD(ln_del_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
--
          /*
          ln_削除件数（受注ヘッダ（アドオン）） := ln_削除件数（受注ヘッダ（アドオン）） + ln_未コミット削除件数（受注ヘッダ（アドオン））;
          ln_削除件数（受注明細（アドオン）） := ln_削除件数（受注明細（アドオン）） + ln_未コミット削除件数（受注明細（アドオン））;
          ln_削除件数（移動ロット詳細（アドオン）） := ln_削除件数（移動ロット詳細（アドオン）） + ln_未コミット削除件数（移動ロット詳細（アドオン））;
          ln_未コミット削除件数（受注ヘッダ（アドオン）） := 0;
          ln_未コミット削除件数（受注明細（アドオン）） := 0;
          ln_未コミット削除件数（移動ロット詳細（アドオン）） := 0;
          COMMIT;
           */
          gn_del_cnt_header     := gn_del_cnt_header + ln_del_cnt_header_yet;
          gn_del_cnt_line       := gn_del_cnt_line   + ln_del_cnt_line_yet;
          gn_del_cnt_lot        := gn_del_cnt_lot    + ln_del_cnt_lot_yet;
          ln_del_cnt_header_yet := 0;
          ln_del_cnt_line_yet   := 0;
          ln_del_cnt_lot_yet    := 0;
          COMMIT;
--
        END IF;
--
      END IF;
--
      /*
      ln_対象件数 := ln_対象件数 + 1;
      ln_対象受注ヘッダアドオンID := lr_header_rec．受注ヘッダアドオンID;
       */
      gn_target_cnt := gn_target_cnt + 1;
      gt_order_header_id := lr_header_rec.order_header_id;
--
      -- ===============================================
      -- パージ対象受注ヘッダ（アドオン）ロック
      -- ===============================================
      /*
      SELECT
            受注ヘッダ（アドオン）．受注ヘッダアドオンID
      FROM 受注ヘッダ（アドオン）,
           受注ヘッダ（アドオン）バックアップ
      WHERE 受注ヘッダ（アドオン）．受注ヘッダアドオンID = lr_header_rec．受注ヘッダアドオンID
        AND 受注ヘッダ（アドオン）．受注ヘッダアドオンID = 受注ヘッダ（アドオン）バックアップ．受注ヘッダアドオンID
      FOR UPDATE NOWAIT
       */
      lv_process_part := 'パージ対象受注ヘッダ（アドオン）ロック';
      SELECT  xoha.order_header_id      AS order_header_id
      INTO    gt_order_header_id
      FROM    xxwsh_order_headers_all  xoha
             ,xxcmn_order_headers_all_arc xohaa
      WHERE   xoha.order_header_id = lr_header_rec.order_header_id
        AND   xoha.order_header_id = xohaa.order_header_id
      FOR UPDATE NOWAIT
      ;
--
      -- ===============================================
      -- パージ対象受注明細（アドオン）取得
      -- ===============================================
      /*
      FOR lr_line_rec IN パージ対象受注明細（アドオン）取得（lr_header_rec．受注ヘッダアドオンID） LOOP
       */
      lv_process_part := 'パージ対象受注明細（アドオン）ロック';
      << purge_order_line_loop >>
      FOR lr_line_rec IN purge_order_line_cur(
                           lr_header_rec.order_header_id
                         )
      LOOP
--
        -- ===============================================
        -- パージ対象移動ロット詳細（アドオン）取得
        -- ===============================================
        /*
        FOR lr_lot_rec IN パージ対象移動ロット詳細（アドオン）取得（lr_line_rec．受注明細アドオンID） LOOP
         */
        lv_process_part := 'パージ対象移動ロット詳細（アドオン）ロック';
        << purge_mov_lot_dtl_loop >>
        FOR lr_lot_rec IN purge_mov_lot_dtl_cur(
                            lr_line_rec.order_line_id
                          )
        LOOP
--
          -- ===============================================
          -- 移動ロット詳細（アドオン）パージ
          -- ===============================================
          /*
          DELETE 移動ロット詳細（アドオン）
          WHERE ロット詳細ID = lr_lot_rec．ロット詳細ID
           */
          lv_process_part := '移動ロット詳細（アドオン）パージ';
          DELETE xxinv_mov_lot_details
          WHERE  mov_lot_dtl_id = lr_lot_rec.mov_lot_dtl_id
          ;
--
          /*
          UPDATE 移動ロット詳細（アドオン）バックアップ
          SET パージ実行日 = SYSDATE
              ,  パージ要求ID = 要求ID
          WHERE ロット詳細ID = lr_lot_rec．ロット詳細ID
           */
          lv_process_part := '移動ロット詳細（アドオン）バックアップ更新';
          UPDATE xxcmn_mov_lot_details_arc
          SET    purge_date       = SYSDATE
                ,purge_request_id = cn_request_id
          WHERE  mov_lot_dtl_id   = lr_lot_rec.mov_lot_dtl_id
          ;
--
          /*
          ln_未コミット削除件数（移動ロット詳細（アドオン）） := ln_未コミット削除件数（移動ロット詳細（アドオン）） + 1;
           */
          ln_del_cnt_lot_yet := ln_del_cnt_lot_yet + 1;
--
        END LOOP purge_mov_lot_dtl_loop;
--
        -- ===============================================
        -- 受注明細（アドオン）パージ
        -- ===============================================
        /*
        DELETE 受注明細（アドオン）
        WHERE 受注明細アドオンID = lr_line_rec．受注明細アドオンID
         */
        lv_process_part := '受注明細（アドオン）パージ';
        DELETE xxwsh_order_lines_all
        WHERE  order_line_id = lr_line_rec.order_line_id
        ;
--
        /*
        UPDATE 受注明細（アドオン）バックアップ
        SET パージ実行日 = SYSDATE
            ,  パージ要求ID = 要求ID
        WHERE 受注明細アドオンID = lr_line_rec．受注明細アドオンID
         */
        lv_process_part := '受注明細（アドオン）バックアップ更新';
        UPDATE xxcmn_order_lines_all_arc
        SET    purge_date       = SYSDATE
              ,purge_request_id = cn_request_id
        WHERE  order_line_id    = lr_line_rec.order_line_id
        ;
--
        /*
        ln_未コミット削除件数（受注明細（アドオン）） := ln_未コミット削除件数（受注明細（アドオン）） + 1;
         */
        ln_del_cnt_line_yet := ln_del_cnt_line_yet + 1;
--
      END LOOP purge_order_line_loop;
--
      -- ===============================================
      -- 受注ヘッダ（アドオン）パージ
      -- ===============================================
      /*
      DELETE 受注ヘッダ（アドオン）
      WHERE 受注ヘッダアドオンID = lr_header_rec．受注ヘッダアドオンID
       */
      lv_process_part := '受注ヘッダ（アドオン）パージ';
      DELETE xxwsh_order_headers_all
      WHERE  order_header_id = lr_header_rec.order_header_id
      ;
--
      /*
      UPDATE 受注ヘッダ（アドオン）バックアップ
      SET パージ実行日 = SYSDATE
          ,  パージ要求ID = 要求ID
      WHERE 受注ヘッダアドオンID = lr_header_rec．受注ヘッダアドオンID
       */
      lv_process_part := '受注ヘッダ（アドオン）バックアップ更新';
      UPDATE xxcmn_order_headers_all_arc
      SET    purge_date       = SYSDATE
            ,purge_request_id = cn_request_id
      WHERE  order_header_id  = lr_header_rec.order_header_id
      ;
--
      /*
      ln_未コミット削除件数（受注ヘッダ（アドオン）） := ln_未コミット削除件数（受注ヘッダ（アドオン）） + 1;
       */
      ln_del_cnt_header_yet := ln_del_cnt_header_yet + 1;
--
    END LOOP purge_order_header_loop;
--
    /*
    ln_削除件数（受注ヘッダ（アドオン）） := ln_削除件数（受注ヘッダ（アドオン）） + ln_未コミット削除件数（受注ヘッダ（アドオン））;
    ln_削除件数（受注明細（アドオン）） := ln_削除件数（受注明細（アドオン）） + ln_未コミット削除件数（受注明細（アドオン））;
    ln_削除件数（移動ロット詳細（アドオン）） := ln_削除件数（移動ロット詳細（アドオン）） + ln_未コミット削除件数（移動ロット詳細（アドオン））;
    ln_未コミット削除件数（受注ヘッダ（アドオン）） := 0;
    ln_未コミット削除件数（受注明細（アドオン）） := 0;
    ln_未コミット削除件数（移動ロット詳細（アドオン）） := 0;
     */
    gn_del_cnt_header     := gn_del_cnt_header + ln_del_cnt_header_yet;
    gn_del_cnt_line       := gn_del_cnt_line   + ln_del_cnt_line_yet;
    gn_del_cnt_lot        := gn_del_cnt_lot    + ln_del_cnt_lot_yet;
    ln_del_cnt_header_yet := 0;
    ln_del_cnt_line_yet   := 0;
    ln_del_cnt_lot_yet    := 0;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt THEN
      NULL;
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
      IF ( gt_order_header_id IS NOT NULL ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_order_header_id)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||cv_msg_part||SQLERRM;
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
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
    cv_token_cnt        CONSTANT VARCHAR2(100) := 'CNT';                         -- 件数メッセージ用トークン名（件数）
    cv_token_cnt_table  CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- 件数メッセージ用トークン名（テーブル名）
    cv_token_cnt_shori  CONSTANT VARCHAR2(100) := 'SHORI';                       -- 件数メッセージ用トークン名（処理名）
    cv_table_cnt_xoha   CONSTANT VARCHAR2(100) := '受注ヘッダ(アドオン)';        -- 件数メッセージ用テーブル名
    cv_table_cnt_xola   CONSTANT VARCHAR2(100) := '受注明細(アドオン)';          -- 件数メッセージ用テーブル名
    cv_table_cnt_xmld   CONSTANT VARCHAR2(100) := '移動ロット明細(アドオン)';    -- 件数メッセージ用テーブル名
    cv_shori_cnt_delete CONSTANT VARCHAR2(100) := '削除';                -- 件数メッセージ用処理名
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-11008';  -- 対象件数： ＆CNT 件
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- 正常件数： ＆CNT 件
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- エラー件数： ＆CNT 件
    cv_proc_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- 処理日： ＆PAR
    cv_par_token        CONSTANT VARCHAR2(100) := 'PAR';              -- 処理日メッセージ用トークン名
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
    --処理日出力
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_proc_date -- 1.処理日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- header削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xoha
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt_header)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --line削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xola
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt_line)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --lot削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_cnt_msg
                    ,iv_token_name1  => cv_token_cnt_table
                    ,iv_token_value1 => cv_table_cnt_xmld
                    ,iv_token_name2  => cv_token_cnt_shori
                    ,iv_token_value2 => cv_shori_cnt_delete
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_del_cnt_lot)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --正常件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_del_cnt_header)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    IF (lv_retcode = cv_status_error) THEN
--
      gn_error_cnt := 1;
--
    ELSE
--
      gn_error_cnt := 0;
--
    END IF;
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
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
END XXCMN960001C;
/
