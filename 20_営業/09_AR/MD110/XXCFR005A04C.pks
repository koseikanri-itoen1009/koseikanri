CREATE OR REPLACE PACKAGE XXCFR005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A04C(spec)
 * Description      : ロックボックス消込処理
 * MD.050           : MD050_CFR_005_A04_ロックボックス入金処理
 * MD.070           : MD050_CFR_005_A04_ロックボックス入金処理
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
 *  2010/10/15    1.00 SCS 廣瀬 真佐人  初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2,  -- エラーメッセージ #固定#
    retcode               OUT NOCOPY VARCHAR2,  -- エラーコード     #固定#
    iv_fb_file_name       IN         VARCHAR2,  -- FBファイル名
    iv_table_insert_flag  IN         VARCHAR2   -- ワークテーブル作成フラグ
  );
END XXCFR005A04C;
/
