CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS003A07C (body)
 * Description      : ベンダ納品実績パージ
 * MD.050           : ベンダ納品実績パージ MD050_COS_003_A07
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  del_old_data           最大保持期間より過去データ削除(A-2)
 *  del_xxcos_vd_deliv     ベンダ納品実績明細削除(A-4)
 *  submain                メイン処理プロシージャ
 *                           ベンダ納品実績データ抽出(A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/10/06    1.0   K.Nakamura       新規作成
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  gn_target1_cnt   NUMBER;                    -- ヘッダ対象件数
  gn_target2_cnt   NUMBER;                    -- 明細対象件数
  gn_normal1_cnt   NUMBER;                    -- ヘッダ削除件数
  gn_normal2_cnt   NUMBER;                    -- 明細削除件数
  gn_skip1_cnt     NUMBER;                    -- ヘッダスキップ件数
  gn_skip2_cnt     NUMBER;                    -- 明細スキップ件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  -- ロック例外
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  -- 警告時例外
  warn_expt                 EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS003A07C';    -- パッケージ名
  cv_application            CONSTANT VARCHAR2(10)  := 'XXCOS';           -- アプリケーション名(販売)
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';           -- アドオン：共通・IF領域
  -- メッセージ
  cv_msg_no_data_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- 対象データ無しエラー
  cv_msg_profile_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- プロファイル取得エラ
  cv_msg_delete_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00012'; -- データ削除エラーメッセージ
  cv_msg_process_date_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- 業務処理日取得エラー
  cv_msg_lock_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14308'; -- ロック取得エラーメッセージ
  cv_msg_no_param           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなし
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE';          -- プロファイル名
  cv_tkn_table_name         CONSTANT VARCHAR2(20) := 'TABLE_NAME';       -- テーブル名
  cv_tkn_key_data           CONSTANT VARCHAR2(20) := 'KEY_DATA';         -- キー項目
  -- プロファイル
  cv_vd_deliv_hold_month    CONSTANT VARCHAR2(30) := 'XXCOS1_VD_DELIV_HOLD_MONTH';      -- XXCOS:ベンダ納品実績保持月数
  cv_vd_deliv_hold_time     CONSTANT VARCHAR2(30) := 'XXCOS1_VD_DELIV_HOLD_TIME';       -- XXCOS:ベンダ納品実績保持回数
  cv_period_use_data        CONSTANT VARCHAR2(50) := 'XXCOI1_PERIOD_USE_DATA_FORECAST'; -- XXCOI:販売予測データ利用期間
  -- 参照コード
  cv_lookup_type_gyotai     CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03';  -- 業態（小分類）
  -- メッセージ出力文字
  cv_profile_hold_month     CONSTANT VARCHAR2(50) := 'XXCOS:ベンダ納品実績保持月数';           -- プロファイル名
  cv_profile_hold_time      CONSTANT VARCHAR2(50) := 'XXCOS:ベンダ納品実績保持回数';           -- プロファイル名
  cv_profile_use_data       CONSTANT VARCHAR2(50) := 'XXCOI:販売予測データ利用期間';           -- プロファイル名
  cv_xxcos_vd_deliv         CONSTANT VARCHAR2(50) := 'ベンダ納品実績（ヘッダ・明細）テーブル'; -- テーブル名
  cv_xxcos_vd_deliv_headers CONSTANT VARCHAR2(50) := 'ベンダ納品実績ヘッダテーブル';           -- テーブル名
  cv_xxcos_vd_deliv_lines   CONSTANT VARCHAR2(50) := 'ベンダ納品実績明細テーブル';             -- テーブル名
  cv_customer_code          CONSTANT VARCHAR2(20) := '顧客コード';                             -- 項目名
  cv_delete_date            CONSTANT VARCHAR2(20) := '削除日付';                               -- 項目名
  -- 書式
  cv_date_format            CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; -- 日付書式
  -- フラグ
  cv_flag_on                CONSTANT VARCHAR2(1)  := 'Y'; -- 有効フラグ
  cv_forecast_use_flag      CONSTANT VARCHAR2(1)  := 'Y'; -- 販売予測利用フラグ
  -- 言語
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ベンダ納品実績削除情報
  gt_customer_number        xxcos_vd_deliv_headers.customer_number%TYPE; -- 顧客コード
  gt_dlv_date               xxcos_vd_deliv_headers.dlv_date%TYPE;        -- 納品日（削除日付）
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_vd_deliv_hold_month    NUMBER           DEFAULT NULL;      -- ベンダ納品実績保持月数
  gn_vd_deliv_hold_time     NUMBER           DEFAULT NULL;      -- ベンダ納品実績保持回数
  gn_period_use_data        NUMBER           DEFAULT NULL;      -- 販売予測データ利用期間
  gd_process_date           DATE             DEFAULT NULL;      -- 業務日付
  gt_key_info               fnd_new_messages.message_text%TYPE; -- メッセージ出力用キー情報
--
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_msg_no_param
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- 業務処理日を取得
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    -- 業務処理日取得エラーの場合
    IF ( gd_process_date IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_msg_process_date_err
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(ベンダ納品実績保持月数)
    --==============================================================
    BEGIN
      gn_vd_deliv_hold_month := FND_PROFILE.VALUE(cv_vd_deliv_hold_month);
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => cv_profile_hold_month
                     );
        RAISE warn_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( gn_vd_deliv_hold_month IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_hold_month
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(ベンダ納品実績保持回数)
    --==============================================================
    BEGIN
      gn_vd_deliv_hold_time := TO_NUMBER(FND_PROFILE.VALUE(cv_vd_deliv_hold_time));
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => cv_profile_hold_time
                     );
        RAISE warn_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( gn_vd_deliv_hold_time IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_hold_time
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(販売予測データ利用期間)
    --==============================================================
    BEGIN
      gn_period_use_data := TO_NUMBER(FND_PROFILE.VALUE(cv_period_use_data));
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => cv_profile_use_data
                     );
        RAISE warn_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( gn_period_use_data IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_use_data
                   );
      RAISE warn_expt;
    END IF;
--
  EXCEPTION
    -- *** 初期処理警告時例外ハンドラ ***
    WHEN warn_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      -- 警告件数カウントアップ
      gn_warn_cnt := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
   * Procedure Name   : del_old_data
   * Description      : 最大保持期間より過去データ削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_old_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_old_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカル変数 ***
    ln_xvdh_cnt                      NUMBER  DEFAULT 0;     -- ベンダ納品実績ヘッダ件数
    ln_xvdl_cnt                      NUMBER  DEFAULT 0;     -- ベンダ納品実績明細件数
    ld_max_date                      DATE    DEFAULT NULL;  -- 最大保持日付
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ベンダ納品実績レコードロックカーソル
    CURSOR old_data_lock_cur
    IS
      SELECT xvdh.rowid             xvdh_rowid                -- ベンダ納品実績ヘッダ件数
           , xvdl.rowid             xvdl_rowid                -- ベンダ納品実績明細件数
      FROM   xxcos_vd_deliv_headers xvdh                      -- ベンダ納品実績ヘッダ
           , xxcos_vd_deliv_lines   xvdl                      -- ベンダ納品実績明細
      WHERE  xvdh.customer_number   = xvdl.customer_number(+) -- 顧客コード
      AND    xvdh.dlv_date          = xvdl.dlv_date(+)        -- 納品日
      AND    xvdh.dlv_date          < ld_max_date             -- 納品日
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 最大保持日付取得
    ld_max_date := ADD_MONTHS(gd_process_date, - (gn_period_use_data));
--
    -- ベンダ納品実績件数取得
    SELECT xvdhv.xvdh_cnt                              -- ヘッダ件数
         , xvdlv.xvdl_cnt                              -- 明細件数
    INTO   ln_xvdh_cnt
         , ln_xvdl_cnt
    FROM   (
             SELECT /*+ index_ffs(xvdh xxcos_vd_deliv_headers_pk) */
                    COUNT(xvdh.rowid)      xvdh_cnt    -- ヘッダ件数
             FROM   xxcos_vd_deliv_headers xvdh        -- ベンダ納品実績ヘッダ
             WHERE  xvdh.dlv_date        < ld_max_date -- 納品日
           ) xvdhv
         , (
             SELECT /*+ index_ffs(xvdl xxcos_vd_deliv_lines_pk) */
                    COUNT(xvdl.rowid)      xvdl_cnt    -- 明細件数
             FROM   xxcos_vd_deliv_lines   xvdl        -- ベンダ納品実績明細
             WHERE  xvdl.dlv_date        < ld_max_date -- 納品日
           ) xvdlv
    ;
--
    -- ヘッダ対象件数カウントアップ
    gn_target1_cnt := ln_xvdh_cnt;
    -- 明細対象件数カウントアップ
    gn_target2_cnt := ln_xvdl_cnt;
--
    -- 対象データが存在する場合
    IF ( ( gn_target1_cnt > 0)
      OR ( gn_target2_cnt > 0) ) THEN
      --
      -- ロック取得
      OPEN old_data_lock_cur;
      CLOSE old_data_lock_cur;
      --
      -- ヘッダ削除対象が存在する場合
      IF ( gn_target1_cnt > 0) THEN
        BEGIN
          -- ベンダ納品実績ヘッダ削除
          DELETE FROM xxcos_vd_deliv_headers xvdh
          WHERE  xvdh.dlv_date < ld_max_date
          ;
          -- 削除件数カウントアップ
          gn_normal1_cnt := SQL%ROWCOUNT;
        EXCEPTION
          WHEN OTHERS THEN
            -- スキップ件数カウントアップ
            gn_skip1_cnt := gn_target1_cnt;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                            ,ov_retcode     => lv_retcode
                                            ,ov_errmsg      => lv_errmsg
                                            ,ov_key_info    => gt_key_info
                                            ,iv_item_name1  => cv_delete_date
                                            ,iv_data_value1 => TO_CHAR(ld_max_date,cv_date_format));
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_delete_err
                           ,iv_token_name1  => cv_tkn_table_name
                           ,iv_token_value1 => cv_xxcos_vd_deliv_headers
                           ,iv_token_name2  => cv_tkn_key_data
                           ,iv_token_value2 => gt_key_info
                         );
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
            ov_retcode := cv_status_warn;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
        END;
      END IF;
      --
      -- 明細削除対象が存在する場合
      IF ( gn_target2_cnt > 0) THEN
        BEGIN
          -- ベンダ納品実績明細削除
          DELETE FROM xxcos_vd_deliv_lines xvdl
          WHERE  xvdl.dlv_date < ld_max_date
          ;
          -- 削除件数カウントアップ
          gn_normal2_cnt := SQL%ROWCOUNT;
        EXCEPTION
          WHEN OTHERS THEN
            -- スキップ件数カウントアップ
            gn_skip2_cnt := gn_target2_cnt;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                            ,ov_retcode     => lv_retcode
                                            ,ov_errmsg      => lv_errmsg
                                            ,ov_key_info    => gt_key_info
                                            ,iv_item_name1  => cv_delete_date
                                            ,iv_data_value1 => TO_CHAR(ld_max_date,cv_date_format));
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_delete_err
                           ,iv_token_name1  => cv_tkn_table_name
                           ,iv_token_value1 => cv_xxcos_vd_deliv_lines
                           ,iv_token_name2  => cv_tkn_key_data
                           ,iv_token_value2 => gt_key_info
                         );
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
            ov_retcode := cv_status_warn;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
        END;
      END IF;
    END IF;
--
  EXCEPTION
    -- ロック例外
    WHEN lock_expt THEN
      -- スキップ件数カウントアップ
      gn_skip1_cnt := gn_target1_cnt;
      gn_skip2_cnt := gn_target2_cnt;
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
      xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                      ,ov_retcode     => lv_retcode
                                      ,ov_errmsg      => lv_errmsg
                                      ,ov_key_info    => gt_key_info
                                      ,iv_item_name1  => cv_delete_date
                                      ,iv_data_value1 => TO_CHAR(ld_max_date,cv_date_format));
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_lock_err
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => cv_xxcos_vd_deliv
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => gt_key_info
                   );
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_old_data;
--
  /**********************************************************************************
   * Procedure Name   : del_xxcos_vd_deliv
   * Description      : ベンダ納品実績削除(A-4)
   ***********************************************************************************/
  PROCEDURE del_xxcos_vd_deliv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_xxcos_vd_deliv'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_head_cnt                      NUMBER  DEFAULT 0;     -- 対象ヘッダ件数
    ln_line_cnt                      NUMBER  DEFAULT 0;     -- 対象明細件数
    lb_lock_flag                     BOOLEAN DEFAULT FALSE; -- ロックフラグ
    lb_stop_del_flag                 BOOLEAN DEFAULT FALSE; -- ヘッダ削除中止フラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ベンダ納品実績レコードロックカーソル
    CURSOR xxcos_vd_deliv_lock_cur
    IS
      SELECT xvdh.rowid             xvdh_rowid
           , xvdl.rowid             xvdl_rowid
      FROM   xxcos_vd_deliv_headers xvdh                      -- ベンダ納品実績ヘッダ
           , xxcos_vd_deliv_lines   xvdl                      -- ベンダ納品実績明細
      WHERE  xvdh.customer_number   = xvdl.customer_number(+) -- 顧客コード
      AND    xvdh.dlv_date          = xvdl.dlv_date(+)        -- 納品日
      AND    xvdh.customer_number   = gt_customer_number      -- 顧客コード
      AND    xvdh.dlv_date          < gt_dlv_date             -- 納品日
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    lv_errbuf          := NULL;
    lv_errmsg          := NULL;
    ln_head_cnt        := 0;
    ln_line_cnt        := 0;
    lb_lock_flag       := FALSE;
    lb_stop_del_flag   := FALSE;
    gt_key_info        := NULL;
--
    -- ベンダ納品実績件数取得
    SELECT xvdhv.xvdh_cnt                                       -- ヘッダ件数
         , xvdlv.xvdl_cnt                                       -- 明細件数
    INTO   ln_head_cnt
         , ln_line_cnt
    FROM   ( 
             SELECT COUNT(xvdh.rowid)      xvdh_cnt             -- ヘッダ件数
             FROM   xxcos_vd_deliv_headers xvdh                 -- ベンダ納品実績ヘッダ
             WHERE  xvdh.customer_number   = gt_customer_number -- 顧客コード
             AND    xvdh.dlv_date          < gt_dlv_date        -- 納品日
           ) xvdhv
         , ( 
             SELECT COUNT(xvdl.rowid)      xvdl_cnt             -- 明細件数
             FROM   xxcos_vd_deliv_lines   xvdl                 -- ベンダ納品実績明細
             WHERE  xvdl.customer_number   = gt_customer_number -- 顧客コード
             AND    xvdl.dlv_date          < gt_dlv_date        -- 納品日
           ) xvdlv
    ;
    --
    -- ヘッダ対象件数カウントアップ
    gn_target1_cnt := gn_target1_cnt + ln_head_cnt;
    -- 明細対象件数カウントアップ
    gn_target2_cnt := gn_target2_cnt + ln_line_cnt;
    --
    -- 対象データが存在する場合
    IF ( ( ln_head_cnt > 0)
      OR ( ln_line_cnt > 0) ) THEN
      --
      -- ロック取得
      BEGIN
        OPEN xxcos_vd_deliv_lock_cur;
        CLOSE xxcos_vd_deliv_lock_cur;
      EXCEPTION
        WHEN lock_expt THEN
          -- スキップ件数カウントアップ
          gn_skip1_cnt := gn_skip1_cnt + ln_head_cnt;
          gn_skip2_cnt := gn_skip2_cnt + ln_line_cnt;
          IF ( xxcos_vd_deliv_lock_cur%ISOPEN ) THEN
            CLOSE xxcos_vd_deliv_lock_cur;
          END IF;
          lb_lock_flag := TRUE;
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                          ,ov_retcode     => lv_retcode
                                          ,ov_errmsg      => lv_errmsg
                                          ,ov_key_info    => gt_key_info
                                          ,iv_item_name1  => cv_customer_code
                                          ,iv_data_value1 => gt_customer_number
                                          ,iv_item_name2  => cv_delete_date
                                          ,iv_data_value2 => TO_CHAR(gt_dlv_date,cv_date_format));
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_lock_err
                         ,iv_token_name1  => cv_tkn_table_name
                         ,iv_token_value1 => cv_xxcos_vd_deliv
                         ,iv_token_name2  => cv_tkn_key_data
                         ,iv_token_value2 => gt_key_info
                       );
          lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_warn;
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        WHEN OTHERS THEN
          IF ( xxcos_vd_deliv_lock_cur%ISOPEN ) THEN
            CLOSE xxcos_vd_deliv_lock_cur;
          END IF;
          RAISE;
      END;
      --
      -- ロック取得ができた場合
      IF ( lb_lock_flag = FALSE ) THEN
        -- 明細削除対象が存在する場合
        IF ( ln_line_cnt > 0 ) THEN
          --
          BEGIN
            -- ベンダ納品実績明細削除
            DELETE FROM xxcos_vd_deliv_lines xvdl
            WHERE  xvdl.customer_number = gt_customer_number -- 顧客コード
            AND    xvdl.dlv_date        < gt_dlv_date        -- 納品日
            ;
            -- 削除件数カウントアップ
            gn_normal2_cnt := gn_normal2_cnt + SQL%ROWCOUNT;
          EXCEPTION
            WHEN OTHERS THEN
              -- スキップ件数カウントアップ
              gn_skip1_cnt := gn_skip1_cnt + ln_head_cnt;
              gn_skip2_cnt := gn_skip2_cnt + ln_line_cnt;
              -- ヘッダ削除中止フラグ
              lb_stop_del_flag := TRUE;
              xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                              ,ov_retcode     => lv_retcode
                                              ,ov_errmsg      => lv_errmsg
                                              ,ov_key_info    => gt_key_info
                                              ,iv_item_name1  => cv_customer_code
                                              ,iv_data_value1 => gt_customer_number
                                              ,iv_item_name2  => cv_delete_date
                                              ,iv_data_value2 => TO_CHAR(gt_dlv_date,cv_date_format));
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                             ,iv_name         => cv_msg_delete_err
                             ,iv_token_name1  => cv_tkn_table_name
                             ,iv_token_value1 => cv_xxcos_vd_deliv_lines
                             ,iv_token_name2  => cv_tkn_key_data
                             ,iv_token_value2 => gt_key_info
                           );
              lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_warn;
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
          END;
        END IF;
        --
        -- ヘッダ削除対象が存在する場合かつ明細が削除できた場合
        IF (  ( ln_head_cnt > 0 )
          AND ( lb_stop_del_flag = FALSE ) ) THEN
          --
          BEGIN
            -- ベンダ納品実績ヘッダ削除
            DELETE FROM xxcos_vd_deliv_headers xvdh
            WHERE  xvdh.customer_number = gt_customer_number -- 顧客コード
            AND    xvdh.dlv_date        < gt_dlv_date        -- 納品日
            ;
            -- 削除件数カウントアップ
            gn_normal1_cnt := gn_normal1_cnt + SQL%ROWCOUNT;
          EXCEPTION
            WHEN OTHERS THEN
              -- スキップ件数カウントアップ
              gn_skip1_cnt := gn_skip1_cnt + ln_head_cnt;
              xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                              ,ov_retcode     => lv_retcode
                                              ,ov_errmsg      => lv_errmsg
                                              ,ov_key_info    => gt_key_info
                                              ,iv_item_name1  => cv_customer_code
                                              ,iv_data_value1 => gt_customer_number
                                              ,iv_item_name2  => cv_delete_date
                                              ,iv_data_value2 => TO_CHAR(gt_dlv_date,cv_date_format));
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                             ,iv_name         => cv_msg_delete_err
                             ,iv_token_name1  => cv_tkn_table_name
                             ,iv_token_value1 => cv_xxcos_vd_deliv_headers
                             ,iv_token_name2  => cv_tkn_key_data
                             ,iv_token_value2 => gt_key_info
                           );
              lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_warn;
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
          END;
        END IF;
      END IF;
    END IF;
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
  END del_xxcos_vd_deliv;
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
    cv_dummy_char           CONSTANT VARCHAR2(1) := 'X'; -- ダミー文字
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ベンダ納品実績カーソル
    CURSOR xxcos_vd_deliv_cur
    IS
      SELECT xvdhiv1.customer_number                                 customer_number -- 顧客ID
           , xvdhiv1.dlv_date                                        hold_time       -- 保持日付（回数）
           , ADD_MONTHS(gd_process_date, - (gn_vd_deliv_hold_month)) hold_month      -- 保持日付（月数）
           , xvdhiv1.rownumber                                       rownumber       -- 順番
      FROM
           (
             SELECT xvdhv2.customer_number                           customer_number -- 顧客ID
                  , xvdhv2.dlv_date                                  dlv_date        -- 納品日
                  , ROW_NUMBER() OVER (PARTITION BY xvdhv2.customer_number ORDER BY xvdhv2.dlv_date DESC)
                                                                     rownumber       -- 顧客ごとに納品日でソートして順番付け
             FROM
                  (
                    SELECT /*+ LEADING(flv xca xvdh) USE_NL(flv xca xvdh) */
                           xvdh.customer_number   customer_number                 -- 顧客コード
                         , xvdh.dlv_date          dlv_date                        -- 納品日
                    FROM   xxcos_vd_deliv_headers xvdh                            -- ベンダ納品実績ヘッダ
                         , xxcmm_cust_accounts    xca                             -- 顧客追加情報
                         , fnd_lookup_values      flv                             -- クイックコード
                    WHERE  xvdh.customer_number   = xca.customer_code             -- 顧客コード
                    AND    xca.business_low_type  = flv.meaning                   -- 業態（小分類）
                    AND    flv.lookup_type        = cv_lookup_type_gyotai         -- タイプ
                    AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                               AND NVL(flv.end_date_active, gd_process_date)
                                                                                  -- 有効日
                    AND    flv.enabled_flag       = cv_flag_on                    -- 有効フラグ
                    AND    flv.language           = ct_language                   -- 言語
                    AND    xca.calendar_code IS NOT NULL                          -- 稼働日カレンダコード
                    AND EXISTS (
                                 SELECT cv_dummy_char      dummy_char
                                 FROM   bom_calendars      bc                     -- 稼働日カレンダ
                                      , bom_calendar_dates bcd                    -- 稼動日カレンダ日付
                                 WHERE  bc.calendar_code   = bcd.calendar_code    -- カレンダコード
                                 AND    bc.calendar_code   = xca.calendar_code    -- 稼働日カレンダコード
                                 AND    bcd.calendar_date  = xvdh.dlv_date        -- カレンダ日付
                                 AND    bc.attribute1      = cv_forecast_use_flag -- 販売予測利用フラグ（販売予測カレンダ）
                                 AND    bcd.seq_num   IS NOT NULL                 -- 順番（非稼動日を除外）
                               )
                    UNION ALL
                    SELECT /*+ LEADING(flv xca xvdh) USE_NL(flv xca xvdh) */
                           xvdh.customer_number   customer_number              -- 顧客コード
                         , xvdh.dlv_date          dlv_date                     -- 納品日
                    FROM   xxcos_vd_deliv_headers xvdh                         -- ベンダ納品実績ヘッダ
                         , xxcmm_cust_accounts    xca                          -- 顧客追加情報
                         , fnd_lookup_values      flv                          -- クイックコード
                    WHERE  xvdh.customer_number   = xca.customer_code          -- 顧客コード
                    AND    xca.business_low_type  = flv.meaning                -- 業態（小分類）
                    AND    flv.lookup_type        = cv_lookup_type_gyotai      -- タイプ
                    AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                               AND NVL(flv.end_date_active, gd_process_date)
                                                                               -- 有効日
                    AND    flv.enabled_flag       = cv_flag_on                 -- 有効フラグ
                    AND    flv.language           = ct_language                -- 言語
                    AND  (
                           ( xca.calendar_code IS NULL )                       -- 稼働日カレンダコード
                           OR
                           ( xca.calendar_code IS NOT NULL                     -- 稼働日カレンダコード
                           AND NOT EXISTS (
                                            SELECT cv_dummy_char      dummy_char
                                            FROM   bom_calendars      bc                     -- 稼働日カレンダ
                                                 , bom_calendar_dates bcd                    -- 稼動日カレンダ日付
                                            WHERE  bc.calendar_code   = bcd.calendar_code    -- カレンダコード
                                            AND    bc.calendar_code   = xca.calendar_code    -- 稼働日カレンダコード
                                            AND    bc.attribute1      = cv_forecast_use_flag -- 販売予測利用フラグ（販売予測カレンダ）
                                          )
                           )
                         )
                  ) xvdhv2
           ) xvdhiv1
      WHERE  xvdhiv1.rownumber = gn_vd_deliv_hold_time -- ベンダ納品実績の顧客ごとに保持回数のデータを取得
      ORDER BY xvdhiv1.customer_number                 -- 顧客コード
      ;
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
    gn_target1_cnt := 0;
    gn_target2_cnt := 0;
    gn_normal1_cnt := 0;
    gn_normal2_cnt := 0;
    gn_skip1_cnt   := 0;
    gn_skip2_cnt   := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 最大保持期間より過去データ削除(A-2)
    -- ===============================
    del_old_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    -- 警告が発生しても継続する
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ベンダ納品実績データ抽出(A-3)
    -- ===============================
    <<del_vd_deliv_loop>>
    FOR l_xxcos_vd_deliv_rec IN xxcos_vd_deliv_cur LOOP
      -- 初期化
      gt_customer_number := NULL;
      gt_dlv_date        := NULL;
      -- 顧客コード
      gt_customer_number := l_xxcos_vd_deliv_rec.customer_number;
      -- 削除日付
      IF ( l_xxcos_vd_deliv_rec.hold_time >= l_xxcos_vd_deliv_rec.hold_month ) THEN
        gt_dlv_date := l_xxcos_vd_deliv_rec.hold_month;
      ELSE
        gt_dlv_date := l_xxcos_vd_deliv_rec.hold_time;
      END IF;
      --
      -- ===============================
      -- ベンダ納品実績明細削除(A-4)
      -- ===============================
      del_xxcos_vd_deliv(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP xxcos_vd_deliv_loop;
--
    -- 対象件数0件の場合
    IF (  ( gn_target1_cnt = 0 )
      AND ( gn_target2_cnt = 0 ) ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_no_data_err
                   );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
    END IF;
    --
    -- スキップ件数が存在する場合、警告
    IF ( ( gn_skip1_cnt > 0 )
      OR ( gn_skip2_cnt > 0 ) ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 警告例外ハンドラ ***
    WHEN warn_expt THEN
      ov_retcode := cv_status_warn;
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target1_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14301'; -- ヘッダ対象件数メッセージ
    cv_target2_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14302'; -- 明細対象件数メッセージ
    cv_delete1_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14303'; -- ヘッダ削除件数メッセージ
    cv_delete2_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14304'; -- 明細削除件数メッセージ
    cv_skip1_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14305'; -- ヘッダスキップ件数メッセージ
    cv_skip2_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14306'; -- 明細スキップ件数メッセージ
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14307'; -- 警告件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
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
    --
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
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target1_cnt := 0;
      gn_target2_cnt := 0;
      gn_normal1_cnt := 0;
      gn_normal2_cnt := 0;
      gn_skip1_cnt   := 0;
      gn_skip2_cnt   := 0;
      gn_warn_cnt    := 0;
      gn_error_cnt   := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ===============================
    -- 終了処理(A-4)
    -- ===============================
    --ヘッダ対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_target1_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target1_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --明細対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_target2_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ヘッダ削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_delete1_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal1_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --明細削除件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_delete2_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ヘッダスキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_skip1_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip1_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --明細スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_skip2_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
       which  => FND_FILE.OUTPUT
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
--###########################  固定部 END   #######################################################
--
END XXCOS003A07C;
/
