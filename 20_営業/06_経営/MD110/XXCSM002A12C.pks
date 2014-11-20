CREATE OR REPLACE PACKAGE XXCSM002A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A12C(spec)
 * Description      : 商品計画リスト(時系列)出力
 * MD.050           : 商品計画リスト(時系列)出力 MD050_CSM_002_A12
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/14    1.0   M.Ohtsuki        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
                errbuf           OUT    NOCOPY VARCHAR2                                             -- エラーメッセージ
               ,retcode          OUT    NOCOPY VARCHAR2                                             -- エラーコード
               ,iv_taisyo_year   IN            VARCHAR2                                             -- 対象年度
               ,iv_kyoten_cd     IN            VARCHAR2                                             -- 拠点コード
               ,iv_cost_kind     IN            VARCHAR2                                             -- 原価種別
               ,iv_kyoten_kaisou IN            VARCHAR2                                             -- 階層
               );
END XXCSM002A12C;
/
