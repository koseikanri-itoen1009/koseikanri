CREATE OR REPLACE PACKAGE xxpo310002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310002c(spec)
 * Description      : HHT発注情報IF
 * MD.050           : 受入実績            T_MD050_BPO_310
 * MD.070           : HHT発注情報IF       T_MD070_BPO_31E
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
 *  2008/04/08    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/21    1.1   Oracle 山根 一浩 変更要求No43対応
 *  2008/05/23    1.2   Oracle 藤井 良平 結合テスト不具合（シナリオ4-1）
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_from_date  IN            VARCHAR2,         -- 1.納入日(FROM)
    iv_to_date    IN            VARCHAR2,         -- 2.納入日(TO)
    iv_inv_code   IN            VARCHAR2,         -- 3.納入先コード
    iv_vendor_id  IN            VARCHAR2);        -- 4.取引先コード
END xxpo310002c;
/
