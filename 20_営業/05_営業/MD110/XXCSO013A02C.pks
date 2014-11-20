CREATE OR REPLACE PACKAGE APPS.XXCSO013A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO013A02C(spec)
 * Description      : 自販機管理システムから連携されたリース物件に関連する作業の情報を、
 *                    リースアドオンに反映します。
 * MD.050           :  MD050_CSO_013_A02_CSI→FAインタフェース：（OUT）リース資産情報
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
 *  2009-02-02    1.0   Tomoko.Mori      新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf          OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode         OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_process_div  IN  VARCHAR2           --   処理区分
    ,iv_process_date IN  VARCHAR2           --   処理実行日
  );
END XXCSO013A02C;
/
