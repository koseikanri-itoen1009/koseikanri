create or replace PACKAGE BODY xxpo_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name           : xxpo_common3_pkg(BODY)
 * Description            : 共通関数(仕入実績作成処理管理Tblアクセス処理)(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  check_result              F     V     仕入実績情報チェック
 *  insert_result             F     V     仕入実績情報登録
 *  delete_result             P     -     仕入実績情報削除
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2011/06/03   1.0   K.Kubo           新規作成
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo_common3_pkg'; -- パッケージ名
--
  gn_zero          CONSTANT NUMBER := 0;
  gv_ret_succuess  CONSTANT VARCHAR2(1) := '1';
  gv_ret_err       CONSTANT VARCHAR2(1) := '0';

--
  /***********************************************************************************
   * Function Name    : check_result
   * Description      : 仕入実績情報のチェック
   ***********************************************************************************/
  FUNCTION check_result(
    in_po_header_id       IN  NUMBER             -- (IN)発注ヘッダＩＤ
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_result'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_result_count     NUMBER;
--
  BEGIN
--
    -- **************************************
    -- ***          実処理の記述          ***
    -- **************************************
--
--  仕入実績情報のチェック
    SELECT COUNT(*)
    INTO   ln_result_count
    FROM   xxpo_stock_result_manegement xsrm
    WHERE  xsrm.po_header_id = in_po_header_id
    ;
--
    -- 仕入実績情報がない場合、正常"0" を返す
    IF ln_result_count = gn_zero THEN
      --ステータスセット（正常：0）
      RETURN gv_status_normal;
    ELSE
      --ステータスセット（エラー：2）
      RETURN gv_status_error;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END check_result;
--
  /***********************************************************************************
   * Function Name    : insert_result
   * Description      : 仕入実績情報登録
   ***********************************************************************************/
  FUNCTION insert_result(
    in_po_header_id       IN  NUMBER             -- (IN)発注ヘッダＩＤ
   ,iv_po_header_number   IN  VARCHAR2           -- (IN)発注番号
   ,in_created_by         IN  NUMBER             -- (IN)作成者
   ,id_creation_date      IN  DATE               -- (IN)作成日
   ,in_last_updated_by    IN  NUMBER             -- (IN)最終更新者
   ,id_last_update_date   IN  DATE               -- (IN)最終更新日
   ,in_last_update_login  IN  NUMBER             -- (IN)最終更新ログイン
  ) 
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_result'; -- プログラム名
--
  BEGIN
--
    -- **************************************
    -- ***          実処理の記述          ***
    -- **************************************
--
    -- 仕入実績作成処理管理TBLへのINSERT
    INSERT INTO xxpo_stock_result_manegement xsrm
    (
      xsrm.po_header_id              -- 発注ヘッダＩＤ
     ,xsrm.po_header_number          -- 発注番号
     ,xsrm.created_by                -- 作成者
     ,xsrm.creation_date             -- 作成日
     ,xsrm.last_updated_by           -- 最終更新者
     ,xsrm.last_update_date          -- 最終更新日
     ,xsrm.last_update_login         -- 最終更新ログイン
    ) VALUES (
      in_po_header_id                -- 発注ヘッダＩＤ
     ,iv_po_header_number            -- 発注番号
     ,in_created_by                  -- 作成者
     ,id_creation_date               -- 作成日
     ,in_last_updated_by             -- 最終更新者
     ,id_last_update_date            -- 最終更新日
     ,in_last_update_login           -- 最終更新ログイン
    )
    ;
--
    --ステータスセット
    RETURN gv_ret_succuess;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gv_ret_err;
--
--#####################################  固定部 END   #############################################
--
  END insert_result;
--
  /***********************************************************************************
   * Procedure Name   : delete_result
   * Description      : 仕入実績情報削除
   ***********************************************************************************/
  PROCEDURE delete_result(
    in_po_header_id       IN  NUMBER             -- (IN)発注ヘッダID
   ,ov_errbuf             OUT NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg             OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  ) 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'delete_result'; -- プログラム名
    cv_application     CONSTANT VARCHAR2(5)   := 'XXCMN';         -- アプリケーション名
    cv_table_name      CONSTANT VARCHAR2(30)  := '仕入実績作業処理管理テーブル';
    cv_key             CONSTANT VARCHAR2(12)  := '発注ヘッダID';
    cv_msg_xxcmn10001  CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10001';
    cv_token_table     CONSTANT VARCHAR2(5)   := 'TABLE';
    cv_token_key       CONSTANT VARCHAR2(3)   := 'KEY';
--
    ln_count           NUMBER;          -- 仕入実績情報カウント用
--
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- **************************************
    -- ***          実処理の記述          ***
    -- **************************************
--
    -- 変数の初期化
    ln_count := 0;
--
    -- 対象データが存在する場合は、削除を実施
    -- 対象データが存在しない場合は、エラーで返す
    SELECT COUNT(1)
    INTO   ln_count
    FROM   xxpo_stock_result_manegement xsrm
    WHERE  xsrm.po_header_id = in_po_header_id;
--
    IF (ln_count > 0) THEN
      DELETE FROM xxpo_stock_result_manegement xsrm
      WHERE  xsrm.po_header_id = in_po_header_id
      ;
--
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                                       cv_application
                                      ,cv_msg_xxcmn10001
                                      ,cv_token_table
                                      ,cv_table_name
                                      ,cv_token_key
                                      ,cv_key);
--
      lv_retcode  := gv_status_error ;
--
      RAISE NO_DATA_FOUND;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--###########################  固定部 START   #####################################################
--
    -- --*** 値取得エラー例外 ***
    WHEN NO_DATA_FOUND THEN
      -- メッセージセット
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_retcode := gv_status_error;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000);
      ov_errmsg  := SQLERRM;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_retcode :=  gv_status_error ;
      ov_errbuf  :=  SQLCODE ;
      ov_errmsg  :=  SQLERRM ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###########################  固定部 END   #######################################################
--
  END delete_result;
--
END xxpo_common3_pkg;
