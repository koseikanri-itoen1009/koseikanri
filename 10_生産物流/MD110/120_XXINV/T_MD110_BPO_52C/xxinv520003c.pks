CREATE OR REPLACE PACKAGE xxinv520003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv520003c(spec)
 * Description      : 品目振替(予定)
 * MD.050           : 品目振替 T_MD050_BPO_520
 * MD.070           : 品目振替 T_MD070_BPO_52C
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
 *  2008/11/11    1.0  Oracle 二瓶 大輔  初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT  NOCOPY VARCHAR2, --   エラーメッセージ #固定#
    retcode            OUT  NOCOPY VARCHAR2, --   エラーコード     #固定#
    iv_process_type    IN          VARCHAR2, --   1.処理区分(1:予定,2:予定訂正,3:予定取消,4:実績)
    iv_plan_batch_id   IN          VARCHAR2, --   2.バッチID(予定)
    iv_inv_loc_code    IN          VARCHAR2, --   3.保管倉庫コード
    iv_from_item_no    IN          VARCHAR2, --   4.振替元品目No
    iv_lot_no          IN          VARCHAR2, --   5.振替元ロットNo
    iv_to_item_no      IN          VARCHAR2, --   6.振替先品目No
    iv_quantity        IN          VARCHAR2, --   7.数量
    iv_sysdate         IN          VARCHAR2, --   8.品目振替予定日
    iv_remarks         IN          VARCHAR2, --   9.摘要
    iv_item_chg_aim    IN          VARCHAR2  --  10.品目振替目的
  );
END xxinv520003c;
/
