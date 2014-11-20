CREATE OR REPLACE PACKAGE BODY xx03_file_download_pkg
AS
/*****************************************************************************************
 * 
 * Copyright(c) Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name           : xx03_file_download_pkg(body)
 * Description            : ダウンロードするファイルのBFILEオブジェクトを用意します。
 * MD.070                 : ダウンロードファイル保存 xxxx_MD070_DCC_401_001
 * Version                : 11.5.10.1.5
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *   prepare_file         P          ダウンロードするファイルのBFILEオブジェクトを作成します。
 *
 * Change Record
 *  ------------- ------------- ------------ -----------------------------------------
 *   Date          Ver.          Editor       Description
 *  ------------- ------------- ------------ -----------------------------------------
 *   2005/10/05    11.5.10.1.5   S.Morisawa   新規作成
 *   2009/09/09    11.5.10.1.6   K.Shirasuna  E_T3_00509：RAC構成対応
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : PREPARE_FILE
   * Description      : ダウンロードするファイルのBFILEオブジェクトを作成します。
   ***********************************************************************************/
  PROCEDURE PREPARE_FILE(
     iv_file_name IN  VARCHAR2     -- 1.ファイルパス
    ,ov_errbuf    OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode   OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg    OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
        PRAGMA AUTONOMOUS_TRANSACTION;  --自律トランザクション化
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_download_pkg.prepare_file'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ###############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- PDFファイルを格納するディレクトリ･オブジェクト
    cv_pdf_directory_object CONSTANT VARCHAR2(30) := 'XX03_PDF_DIR';
    -- OUTファイルを格納するディレクトリ・オブジェクト
    cv_out_directory_object CONSTANT VARCHAR2(30) := 'XX03_OUTFILE_DIR';
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
-- ディレクトリパスの統一化(RAC構成対応)
    cv_msg_kbn_cfo          CONSTANT VARCHAR2(5)  := 'XXCFO';            -- アドオン：会計・アドオン領域のアプリケーション短縮名
    cv_msg_00001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; -- プロファイル取得エラーメッセージ
    cv_tkn_prof             CONSTANT VARCHAR2(20) := 'PROF_NAME';        -- トークン：プロファイル名
    --
    cv_rac_db1              CONSTANT VARCHAR2(30) := 'XXCFO1_RAC_DB1';   -- 1号機ディレクトリ情報プロファイル名
    cv_rac_db2              CONSTANT VARCHAR2(30) := 'XXCFO1_RAC_DB2';   -- 2号機ディレクトリ情報プロファイル名
    cv_rac_db3              CONSTANT VARCHAR2(30) := 'XXCFO1_RAC_DB3';   -- 3号機ディレクトリ情報プロファイル名
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
--
    -- *** ローカル変数 ***
    -- 入力ファイルパスのディレクトリ部
    lv_directory ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- 入力ファイルパスのファイル名部
    lv_file ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- PDFファイルが置かれているディレクトリ
    lv_pdf_directory ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- OUTファイルが置かれているディレクトリ
    lv_out_directory ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;
    -- 実際に使用するディレクトリ・オブジェクト名
    lv_directory_object_to_use ALL_DIRECTORIES.DIRECTORY_NAME%TYPE;
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
-- ディレクトリパスの統一化(RAC構成対応)
    -- 1号機ディレクトリ情報プロファイル
    lv_rac_db1 VARCHAR2(100);
    -- 2号機ディレクトリ情報プロファイル
    lv_rac_db2 VARCHAR2(100);
    -- 3号機ディレクトリ情報プロファイル
    lv_rac_db3 VARCHAR2(100);
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    out_of_directory_expt  EXCEPTION; -- ダウンロード可能なディレクトリを外れている。
    illegal_file_name_expt EXCEPTION; -- ファイル名が不正である。
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
    api_expt               EXCEPTION; -- 共通関数例外
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
--
    -- プロファイルからDBディレクトリ情報を取得
    lv_rac_db1 := FND_PROFILE.VALUE(cv_rac_db1); -- 1号機
    -- 取得エラー時
    IF (lv_rac_db1 IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo    -- アプリケーション短縮名
                                                   ,cv_msg_00001      -- プロファイル取得エラー
                                                   ,cv_tkn_prof       -- トークン：プロファイル名
                                                   ,xxcfr_common_pkg.get_user_profile_name(cv_rac_db1))
                                                                      -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE api_expt;
    END IF;
    --
    -- プロファイルからDBディレクトリ情報を取得
    lv_rac_db2 := FND_PROFILE.VALUE(cv_rac_db2); -- 2号機
    -- 取得エラー時
    IF (lv_rac_db2 IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo    -- アプリケーション短縮名
                                                   ,cv_msg_00001      -- プロファイル取得エラー
                                                   ,cv_tkn_prof       -- トークン：プロファイル名
                                                   ,xxcfr_common_pkg.get_user_profile_name(cv_rac_db2))
                                                                      -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE api_expt;
    END IF;
    --
    lv_rac_db3 := FND_PROFILE.VALUE(cv_rac_db3); -- 3号機
    -- 取得エラー時
    IF (lv_rac_db3 IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfo    -- アプリケーション短縮名
                                                   ,cv_msg_00001      -- プロファイル取得エラー
                                                   ,cv_tkn_prof       -- トークン：プロファイル名
                                                   ,xxcfr_common_pkg.get_user_profile_name(cv_rac_db3))
                                                                      -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE api_expt;
    END IF;
    --
--
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
-- PDFが存在するディレクトリを取得。
--
    SELECT
      RTRIM(ad.DIRECTORY_PATH, '/')
    INTO
      lv_pdf_directory
    FROM
      sys.ALL_DIRECTORIES ad
    WHERE
      ad.DIRECTORY_NAME=cv_pdf_directory_object;
--
-- OUTが存在するディレクトリを取得。
--
    SELECT
      RTRIM(ad.DIRECTORY_PATH, '/')
    INTO
      lv_out_directory
    FROM
      sys.ALL_DIRECTORIES ad
    WHERE
      ad.DIRECTORY_NAME=cv_out_directory_object;
--
-- パスを解釈
--
    lv_file := SUBSTR(iv_file_name, INSTR(iv_file_name, '/', -1, 1) + 1);
    lv_directory := SUBSTR(iv_file_name, 1,INSTR(iv_file_name, '/', -1, 1)-1);
--
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
-- ディレクトリパスの統一化(RAC構成対応)
    IF (INSTR(lv_directory, lv_rac_db1) > 0) THEN     -- 1号機
      NULL;
    ELSIF (INSTR(lv_directory, lv_rac_db2) > 0) THEN -- 2号機
      lv_directory := REPLACE(lv_directory, lv_rac_db2, lv_rac_db1);
    ELSIF (INSTR(lv_directory, lv_rac_db3) > 0) THEN -- 3号機
      lv_directory := REPLACE(lv_directory, lv_rac_db3, lv_rac_db1);
    ELSE
      NULL;
    END IF;
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
-- ファイル名をチェック
--
    IF (lv_file IS NULL OR lv_file = '') THEN
      lv_errmsg := xx00_message_pkg.get_msg('XX03','APP-XX03-14147');
      lv_errbuf := lv_errmsg;
      RAISE illegal_file_name_expt;
    END IF;
--
-- ディレクトリをチェックして、使用するディレクトリ・オブジェクトを決定。
--
    IF (lv_directory = lv_pdf_directory) THEN
      lv_directory_object_to_use := cv_pdf_directory_object;
    ELSIF (lv_directory = lv_out_directory) THEN
      lv_directory_object_to_use := cv_out_directory_object;
    ELSE
      lv_errmsg := xx00_message_pkg.get_msg('XX03','APP-XX03-14146');
      lv_errbuf := lv_errmsg;
      RAISE out_of_directory_expt;
    END IF;
--
-- 既にレコードが存在する場合は一旦削除。
--
    DELETE FROM xx03_download_file_pool
    WHERE full_file_name = iv_file_name;
--
-- 新しくレコードを作製。
--
    INSERT INTO xx03_download_file_pool(
       full_file_name
      ,file_data
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       iv_file_name
      ,BFILENAME(lv_directory_object_to_use,lv_file)
      ,xx00_global_pkg.user_id
      ,xx00_date_pkg.get_system_datetime_f
      ,xx00_global_pkg.user_id
      ,xx00_date_pkg.get_system_datetime_f
      ,xx00_global_pkg. login_id
      ,xx00_global_pkg.conc_request_id
      ,xx00_global_pkg.prog_appl_id
      ,xx00_global_pkg.conc_program_id
      ,xx00_date_pkg.get_system_datetime_f
    );
--
    COMMIT;
--
  EXCEPTION
    WHEN out_of_directory_expt THEN                --*** ダウンロード対象外のディレクトリが指定されている。 ***
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
      ROLLBACK;
      RETURN;
    WHEN illegal_file_name_expt THEN               --*** ファイル名が不正である。 ***--
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
      ROLLBACK;
      RETURN;
-- 2009/09/09_ADD_start-11.5.10.1.6---------------------------------------------
    -- *** 共通関数例外ハンドラ ***
    WHEN api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      ROLLBACK;
      RETURN;
-- 2009/09/09_ADD_end-11.5.10.1.6-----------------------------------------------
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END prepare_file;
END xx03_file_download_pkg;
/
