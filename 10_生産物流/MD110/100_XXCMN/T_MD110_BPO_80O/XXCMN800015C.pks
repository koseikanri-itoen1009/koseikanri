CREATE OR REPLACE PACKAGE XXCMN800015C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800015C(spec)
 * Description      : ロット情報をCSVファイル出力し、ワークフロー形式で連携します。
 * MD.050           : ロット情報インタフェース<T_MD050_BPO_801>
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
 *  2016/06/23    1.0   K.Kiriu          新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT VARCHAR2        -- エラー・メッセージ  --# 固定 #
   ,retcode                   OUT VARCHAR2        -- リターン・コード    --# 固定 #
   ,iv_item_code              IN  VARCHAR2        -- 1.品目コード
   ,iv_item_div               IN  VARCHAR2        -- 2.品目区分
   ,iv_lot_no                 IN  VARCHAR2        -- 3.ロットNo
   ,iv_subinventory_code      IN  VARCHAR2        -- 4.倉庫コード
   ,iv_effective_date         IN  VARCHAR2        -- 5.有効日
   ,iv_prod_div               IN  VARCHAR2        -- 6.商品区分
  );
END XXCMN800015C;
/
