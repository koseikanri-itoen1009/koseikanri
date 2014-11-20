CREATE OR REPLACE PACKAGE xx03_file_download_pkg
AS
/*****************************************************************************************
 * 
 * Copyright(c) Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name           : xx03_file_download_pkg(spec)
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
 *
 *****************************************************************************************/
--
-- ダウンロードするファイルのBFILEオブジェクトを用意する。
  PROCEDURE prepare_file(
     iv_file_name IN  VARCHAR2    -- 1.BFILEオブジェクトの指すファイル名
    ,ov_errbuf    OUT VARCHAR2    -- (固定)エラー・メッセージ
    ,ov_retcode   OUT VARCHAR2    -- (固定)リターン・コード
    ,ov_errmsg    OUT VARCHAR2    -- (固定)ユーザー・エラー・メッセージ
  );
--
END xx03_file_download_pkg;
/
