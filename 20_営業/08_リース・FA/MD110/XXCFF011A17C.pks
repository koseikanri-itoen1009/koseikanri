CREATE OR REPLACE PACKAGE XXCFF011A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF011A17C(spec)
 * Description      : リース会計基準開示データ出力
 * MD.050           : リース会計基準開示データ出力 MD050_CFF_011_A17
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
 *  2008/12/01    1.0   SCS山岸          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_period_name   IN    VARCHAR2,        -- 1.会計期間名
    iv_lease_kind    IN    VARCHAR2,        -- 2.リース種類
    iv_book_class    IN    VARCHAR2,        -- 3.資産台帳区分
    iv_lease_company IN    VARCHAR2         -- 4.リース会社コード
  );
--
END XXCFF011A17C;
/
