CREATE OR REPLACE PACKAGE XXCSM002A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A10C(spec)
 * Description      : 商品計画リスト（累計）出力
 * MD.050           : 商品計画リスト（累計）出力 MD050_CSM_002_A10
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
 *  2009-1-7      1.0   n.izumi          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,   --   エラーメッセージ #固定#
    retcode         OUT NOCOPY VARCHAR2,   --   エラーコード     #固定#
    iv_p_yyyy       IN  VARCHAR2,          -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,          -- 2.拠点コード
    iv_p_cost_kind  IN  VARCHAR2,          -- 3.原価種別
    iv_p_level      IN  VARCHAR2           -- 4.階層
  );
END XXCSM002A10C;
/
