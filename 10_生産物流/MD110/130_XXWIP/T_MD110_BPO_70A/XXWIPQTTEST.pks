CREATE OR REPLACE PACKAGE XXWIPQTTEST
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXWIPQTTEST(spec)
 * Description      : xxwip_common_pkg_test.make_qt_inspectionテスト用コンカレント
 * MD.050           : -
 * MD.070           : -
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2007/12/03     1.0   H.Itou            新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_division          IN  VARCHAR2, -- IN  1.区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
    iv_disposal_div      IN  VARCHAR2, -- IN  2.処理区分     必須（1:追加 2:更新 3:削除）
    iv_lot_id            IN  VARCHAR2, -- IN  3.ロットID     必須
    iv_item_id           IN  VARCHAR2, -- IN  4.品目ID       必須
    iv_qt_object         IN  VARCHAR2, -- IN  5.対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
    iv_batch_id          IN  VARCHAR2, -- IN  6.生産バッチID 区分:1のみ必須
    iv_batch_po_id       IN  VARCHAR2, -- IN  7.明細番号     区分:2のみ必須
    iv_qty               IN  VARCHAR2, -- IN  8.数量         区分:2のみ必須
    iv_prod_dely_date    IN  VARCHAR2, -- IN  9.納入日       区分:2のみ必須
    iv_vendor_line       IN  VARCHAR2, -- IN 10.仕入先コード 区分:2のみ必須
    iv_qt_inspect_req_no IN  VARCHAR2  -- IN 11.検査依頼No   処理区分:2、3のみ必須
  );
END XXWIPQTTEST;
/
