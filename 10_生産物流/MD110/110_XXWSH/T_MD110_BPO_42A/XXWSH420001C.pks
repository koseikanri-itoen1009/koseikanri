CREATE OR REPLACE PACKAGE xxwsh420001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH420001C(spec)
 * Description      : 出荷依頼/出荷実績作成処理
 * MD.050           : 出荷実績 T_MD050_BPO_420
 * MD.070           : 出荷依頼出荷実績作成処理 T_MD070_BPO_42A
 * Version          : 1.3
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
 *  2008/03/24    1.0   Oracle 北寒寺 正夫 初回作成
 *  2008/05/14    1.1   Oracle 宮田 隆史   MD050指摘事項のNo56反映
 *  2008/05/19    1.2   Oracle 宮田 隆史   依頼NoのTO_NUMBER化廃止
 *  2008/05/22    1.3   Oracle 宮田 隆史   受注明細作成時の単価NULL対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_block        IN VARCHAR2,                 --   ブロック
    iv_deliver_from IN VARCHAR2,                 --   出荷元
    iv_request_no   IN VARCHAR2);                --   依頼No
END xxwsh420001c;
/
