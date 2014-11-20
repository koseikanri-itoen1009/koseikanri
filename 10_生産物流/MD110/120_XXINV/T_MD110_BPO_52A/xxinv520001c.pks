CREATE OR REPLACE PACKAGE xxinv520001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV520001C(spec)
 * Description      : 品目振替
 * MD.050           : 品目振替 T_MD050_BPO_520
 * MD.070           : 品目振替 T_MD070_BPO_52A
 * Version          : 1.1
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
 *  2008/01/11    1.0  Oracle 和田 大輝  初回作成
 *  2008/04/28    1.1  Oracle 河野 優子  内部変更要求#
 *  2008/05/22    1.2  Oracle 熊本 和郎  結合テスト障害対応(ステータスチェック・更新処理追加)
 *  2008/05/22    1.3  Oracle 熊本 和郎  結合テスト障害対応(同一パラメータによる実行時のエラー)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT  NOCOPY VARCHAR2, --   エラーメッセージ #固定#
    retcode            OUT  NOCOPY VARCHAR2, --   エラーコード     #固定#
    iv_inv_loc_code    IN          VARCHAR2, --   1.保管倉庫コード
    iv_from_item_no    IN          VARCHAR2, --   2.振替元品目No
    iv_lot_no          IN          VARCHAR2, --   3.振替元ロットNo
    iv_to_item_no      IN          VARCHAR2, --   4.振替先品目No
    iv_quantity        IN          VARCHAR2, --   5.数量
    iv_sysdate         IN          VARCHAR2, --   6.品目振替実績日
    iv_remarks         IN          VARCHAR2, --   7.摘要
    iv_item_chg_aim    IN          VARCHAR2  --   8.品目振替目的
  );
END xxinv520001c;
/
