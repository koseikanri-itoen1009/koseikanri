CREATE OR REPLACE PACKAGE xxwip_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip_common_pkg(SPEC)
 * Description            : 共通関数(XXWIP)(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.23
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  update_duty_status     P          業務ステータス更新関数
 *  insert_material_line   P          原料明細追加関数
 *  update_material_line   P          原料明細更新関数
 *  delete_material_line   P          原料明細削除関数
 *  get_batch_no           F   VAR    バッチNo取得関数
 *  lot_execute            P          ロット追加・更新関数
 *  insert_line_allocation P          明細割当追加関数
 *  update_line_allocation P          明細割当更新関数
 *  delete_line_allocation P          明細割当削除関数
 *  update_lot_dff_api     P          ロットマスタDFF更新(生産バッチ用)
 *  update_inv_price       P          在庫単価更新関数
 *  update_trust_price     P          委託加工費更新関数
 *  get_business_date      P          営業日取得
 *  make_qt_inspection     P          品質検査依頼情報作成
 *  get_can_stock_qty      F          手持在庫数量算出API(投入実績用)
 *  change_trans_date_all  P          処理日付更新関数
 *
 * Change Record
 * ------------ ----- ------------------ -----------------------------------------------
 *  Date         Ver.  Editor             Description
 * ------------ ----- ------------------ -----------------------------------------------
 *  2007/11/13   1.0   H.Itou             新規作成
 *  2008/05/28   1.1   Oracle 二瓶 大輔   結合テスト不具合対応(委託加工費更新関数修正)
 *  2008/06/02   1.2   Oracle 二瓶 大輔   内部変更要求#130(委託加工費更新関数修正)
 *  2008/06/12   1.3   Oracle 二瓶 大輔   システムテスト不具合対応#78(委託加工費更新関数修正)
 *  2008/06/25   1.4   Oracle 二瓶 大輔   システムテスト不具合対応#75
 *  2008/06/27   1.5   Oracle 二瓶 大輔   結合テスト不具合対応(原料追加関数修正)
 *  2008/07/02   1.6   Oracle 伊藤ひとみ  システムテスト不具合対応#343(荒茶製造情報取得関数修正)
 *  2008/07/10   1.7   Oracle 二瓶 大輔   システムテスト不具合対応#315(在庫単価取得関数修正)
 *  2008/07/14   1.8   Oracle 伊藤ひとみ  結合不具合 指摘2対応  品質検査依頼情報作成で更新の場合、検査予定日・結果を更新しない。
 *  2008/08/25   1.9   Oracle 伊藤ひとみ  内部変更要求#189対応(品質検査依頼情報作成修正)更新・削除で検査依頼NoがNULLの場合、処理を行わない。
 *  2008/09/03   1.10  Oracle 二瓶 大輔   統合障害#46対応(処理日付更新関数修正)
 *  2008/09/10   1.11  Oracle 二瓶 大輔   統合障害#112対応(ロット追加・更新関数)
 *  2008/09/10   1.12  Oracle 二瓶 大輔   結合テスト指摘対応No30
 *  2008/10/09   1.13  Oracle 二瓶 大輔   統合障害#169対応(手持在庫数量算出API(投入実績用))
 *  2008/11/14   1.14  Oracle 二瓶 大輔   統合障害#649対応(委託加工費更新関数)
 *  2008/11/17   1.15  Oracle 二瓶 大輔   統合障害#678対応(処理日付更新関数)
 *  2008/12/22   1.16  Oracle 二瓶 大輔   本番障害#743対応(ロット追加・更新関数)
 *  2008/12/25   1.17  Oracle 二瓶 大輔   本番障害#851対応(手持在庫数量算出API(投入実績用))
 *  2009/01/15   1.18  Oracle 二瓶 大輔   本番障害#836恒久対応�U(業務ステータス更新関数)
 *  2009/01/30   1.19  Oracle 二瓶 大輔   本番障害#4対応(ランク3追加)
 *                                        本番障害#666対応(実績開始日修正)
 *  2009/02/16   1.20  Oracle 二瓶 大輔   本番障害#1198対応
 *  2009/02/16   1.21  Oracle 伊藤 ひとみ 本番障害#32,1096対応(品質検査依頼情報作成 数量加算 ロットステータス初期化)
 *  2009/02/27   1.22  Oracle 伊藤 ひとみ 本番障害#32再対応(品質検査依頼情報作成)
 *  2009/03/09   1.23  Oracle 伊藤 ひとみ 本番障害#32再対応(品質検査依頼情報作成)
 *****************************************************************************************/
--
  -- ステータス更新関数
  PROCEDURE update_duty_status(
    in_batch_id           IN  NUMBER,      -- 1.更新対象のバッチID
    iv_duty_status        IN  VARCHAR2,    -- 2.更新ステータス
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- バッチNo取得関数
  FUNCTION get_batch_no(
    it_batch_id    gme_batch_header.batch_id%TYPE)      -- 1.更新対象のバッチID
-- 2009/02/16 D.Nihei Mod Start 内部変更要求#189
--  RETURN NUMBER;
  RETURN VARCHAR2;
-- 2009/02/16 D.Nihei Mod End
--
  -- 原料明細追加関数
  PROCEDURE insert_material_line(
    ir_material_detail    IN  gme_material_details%ROWTYPE,
    or_material_detail    OUT NOCOPY gme_material_details%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 原料明細更新関数
  PROCEDURE update_material_line(
    ir_material_detail    IN  gme_material_details%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 原料明細削除関数
  PROCEDURE delete_material_line(
    in_batch_id           IN  NUMBER,     -- 生産バッチID
    in_mtl_dtl_id         IN  NUMBER,     -- 生産原料詳細ID
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
  -- ロット追加・更新関数
  PROCEDURE lot_execute(
    ir_lot_mst            IN  ic_lots_mst%ROWTYPE,                 -- OPMロットマスタ
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,          -- 品目コード
    it_line_type          IN  gme_material_details.line_type%TYPE, -- ラインタイプ
    it_item_class_code    IN  mtl_categories_b.segment1%TYPE,      -- 品目区分
    it_lot_no_prod        IN  ic_lots_mst.lot_no%TYPE,             -- 完成品のロットNo
    or_lot_mst            OUT NOCOPY ic_lots_mst%ROWTYPE,          -- OPMロットマスタ
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 明細割当追加関数
  PROCEDURE insert_line_allocation(
    ir_tran_row_in        IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 明細割当更新関数
  PROCEDURE update_line_allocation(
    ir_tran_row_in        IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 明細割当削除関数
  PROCEDURE delete_line_allocation(
    ir_tran_row_in        IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 在庫単価更新関数
  PROCEDURE update_inv_price(
    it_batch_id           IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
  -- 委託加工費更新関数
  PROCEDURE update_trust_price(
    it_batch_id           IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 営業日取得
  PROCEDURE get_business_date(
    id_date               IN  DATE,        -- IN  1.日付
    in_period             IN  NUMBER,      -- IN  2.期間
    od_business_date      OUT NOCOPY DATE,        -- OUT 1.日付の○○営業日後の日付
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 品質検査依頼情報作成
  PROCEDURE make_qt_inspection(
    it_division          IN  xxwip_qt_inspection.division%TYPE,         -- IN  1.区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
    iv_disposal_div      IN  VARCHAR2,                                  -- IN  2.処理区分     必須（1:追加 2:更新 3:削除）
    it_lot_id            IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  3.ロットID     必須
    it_item_id           IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  4.品目ID       必須
    iv_qt_object         IN  VARCHAR2,                                  -- IN  5.対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
    it_batch_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  6.生産バッチID 処理区分3以外かつ区分:1のみ必須
    it_batch_po_id       IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  7.明細番号     処理区分3以外かつ区分:2のみ必須
    it_qty               IN  xxwip_qt_inspection.qty%TYPE,              -- IN  8.数量         処理区分3以外かつ区分:2のみ必須
    it_prod_dely_date    IN  xxwip_qt_inspection.prod_dely_date%TYPE,   -- IN  9.納入日       処理区分3以外かつ区分:2のみ必須
    it_vendor_line       IN  xxwip_qt_inspection.vendor_line%TYPE,      -- IN 10.仕入先コード 処理区分3以外かつ区分:2のみ必須
    it_qt_inspect_req_no IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 11.検査依頼No   処理区分:2、3のみ必須
    ot_qt_inspect_req_no OUT NOCOPY xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- OUT 1.検査依頼No
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
  -- 手持在庫数量算出API(投入実績用)
  FUNCTION get_can_stock_qty(
    in_batch_id         IN NUMBER,                    -- バッチID
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
  RETURN NUMBER;
--
  -- 処理日付更新関数
  PROCEDURE change_trans_date_all(
    in_batch_id           IN  NUMBER,             -- 生産バッチID
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
END xxwip_common_pkg;
/
