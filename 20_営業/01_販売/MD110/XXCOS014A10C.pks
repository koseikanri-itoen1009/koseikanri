create or replace
PACKAGE XXCOS014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A10C(spec)
 * Description      : 預り金VD納品伝票データ作成
 * MD.050           : 預り金VD納品伝票データ作成 (MD050_COS_014_A10)
 * Version          : 1.2
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
 *  2009/03/06    1.0   S.Nakanishi      main新規作成
 *  2009/03/19    1.1   S.Nakanishi      障害No.159対応
 *  2009/04/30    1.2   T.Miyata         [T1_0891]最終行に[/]付与
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                      OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode                     OUT VARCHAR2,       -- リターン・コード    --# 固定 #
    iv_file_name                IN VARCHAR2,        -- 1.ファイル名
    iv_chain_code               IN VARCHAR2,        -- 2.チェーン店コード
    iv_report_code              IN VARCHAR2,        -- 3.帳票コード
    in_user_id                  IN NUMBER,          -- 4.ユーザーID
    iv_base_code                IN VARCHAR2,        -- 5.拠点コード
    iv_base_name                IN VARCHAR2,        -- 6.拠点名
    iv_chain_name               IN VARCHAR2,        -- 7.チェーン店名
    iv_report_type_code         IN VARCHAR2,        -- 8.帳票種別コード
    iv_ebs_business_series_code IN VARCHAR2,        -- 9.業務系列コード
    iv_report_mode              IN VARCHAR2,        --10.帳票様式
    in_group_id                 IN NUMBER           --11.グループID
  );
  --
END XXCOS014A10C;
/
