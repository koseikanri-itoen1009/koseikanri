CREATE OR REPLACE PACKAGE XXCSM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A01(spec)
 * Description      : 商品計画用過年度販売実績集計
 * MD.050           : 商品計画用過年度販売実績集計 MD050_CSM_002_A01
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
 *  2009/01/07    1.0   S.Son        新規作成
 *  2009/08/04    1.1   T.Tsukino    [障害管理番号0000479]性能改善対応
 *  2010/02/05    1.2   S.Karikomi   [E_本稼動_01247] 
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT  NOCOPY  VARCHAR2,         -- エラーメッセージ
    retcode               OUT  NOCOPY  VARCHAR2          -- エラーコード
--//+DEL START 2010/02/05 E_本稼動_01247 S.Karikomi
--    iv_parallel_value_no  IN   VARCHAR2,                 -- 1.パラレル番号
--//+DEL END 2010/02/05 E_本稼動_01247 S.Karikomi
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    iv_parallel_cnt       IN   VARCHAR2,                 -- 2.パラレル数
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//+DEL START 2010/02/05 E_本稼動_01247 S.Karikomi
--    iv_location_cd        IN   VARCHAR2,                 -- 3.拠点コード
--    iv_item_no            IN   VARCHAR2                  -- 4.品目コード
--//+DEL END 2010/02/05 E_本稼動_01247 S.Karikomi
  );
END XXCSM002A01C;
/
