CREATE OR REPLACE PACKAGE xxpo440007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440007c(spec)
 * Description      : 支給価格変更処理
 * MD.050           : 有償支給            T_MD050_BPO_440
 * MD.070           : 支給価格変更処理    T_MD070_BPO_44O
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
 *  2008/05/15    1.0   Oracle 山根 一浩 初回作成
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode           OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_dept_code   IN            VARCHAR2,         -- 1.担当部署コード
    iv_from_date   IN            VARCHAR2,         -- 2.入庫日(FROM)
    iv_to_date     IN            VARCHAR2,         -- 3.入庫日(TO)
    iv_prod_class  IN            VARCHAR2,         -- 4.商品区分
    iv_item_class  IN            VARCHAR2,         -- 5.品目区分
    iv_vendor_code IN            VARCHAR2,         -- 6.取引先コード
    iv_item_code   IN            VARCHAR2,         -- 7.品目コード
    iv_request_no  IN            VARCHAR2);        -- 8.依頼No
END xxpo440007c;
/
