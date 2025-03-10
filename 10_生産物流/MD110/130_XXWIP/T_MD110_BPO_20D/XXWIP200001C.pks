CREATE OR REPLACE PACKAGE xxwip200001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip200001c(spec)
 * Description      : 生産バッチ情報ダウンロード
 * MD.050           : 生産バッチ T_MD050_BPO_202
 * MD.070           : 生産バッチ情報ダウンロード T_MD070_BPO_20D
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/16    1.0  Oracle 野村 正幸  初回作成
 *  2008/06/18    1.1  Oracle 二瓶 大輔  ST不具合対応#160
 *  2008/07/11    1.2  Oracle 山根 一浩  I_S_001,I_S_192対応
 *  2008/07/24    1.3  Oracle 山根 一浩  ST障害479対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- エラーメッセージ #固定#
    retcode             OUT NOCOPY VARCHAR2      -- エラーコード     #固定#
  );
END xxwip200001c;
/
