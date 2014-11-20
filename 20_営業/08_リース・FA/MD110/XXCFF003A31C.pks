CREATE OR REPLACE PACKAGE XXCFF003A31C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A31C(spec)
 * Description      : リース契約登録一覧
 * MD.050           : リース契約登録一覧 MD050_CFF_003_A31
 * Version          : 1.0
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
 *  2009/01/05    1.0   SCS山岸          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   エラーメッセージ #固定#
    retcode              OUT VARCHAR2,      --   エラーコード     #固定#
    iv_lease_st_date_fr  IN  VARCHAR2,      -- 1.リース開始日FROM
    iv_lease_st_date_to  IN  VARCHAR2,      -- 2.リース開始日TO
    iv_lease_company     IN  VARCHAR2,      -- 3.リース会社コード
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.リース種別FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.リース種別TO
    iv_lease_type        IN  VARCHAR2       -- 6.リース区分
  );
END XXCFF003A31C;
/
