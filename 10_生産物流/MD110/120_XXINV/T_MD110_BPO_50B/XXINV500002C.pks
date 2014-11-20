CREATE OR REPLACE PACKAGE XXINV500002C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXINV500002C(spec)
 * Description      : 移動指示情報取込
 * MD.050           : 移動依頼 T_MD050_BPO_500
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
 *  2011/03/04    1.0   SCS Y.Kanami    新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT  VARCHAR2,              -- エラーメッセージ #固定#
    retcode             OUT  VARCHAR2,              -- エラーコード     #固定#
    in_shipped_locat_cd IN   VARCHAR2 DEFAULT NULL  -- 出庫元コード
  );
END XXINV500002C;
/
