CREATE OR REPLACE PACKAGE xxwip_common2_pkg
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwip_common2_pkg(SPEC)
 * Description            : 生産バッチ一覧画面用関数
 * MD.070(CMD.050)        : なし
 * Version                : 1.1
 *
 * Program List
 * ---------------------- ---- ----- --------------------------------------------------
 *  Name                  Type  Ret   Description
 * ---------------------- ---- ----- --------------------------------------------------
 * save_batch              P         バッチセーブAPI呼出 画面用
 * create_batch            P         バッチ作成API呼出 画面用
 * create_lot              P         ロット採番・ロット作成API呼出 画面用
 * insert_line_allocation  P         明細割当追加API呼出 画面用
 * insert_material_line    P         生産原料詳細追加API呼出 画面用
 * delete_material_line    P         生産原料詳細削除API呼出 画面用
 * reschedule_batch        P         バッチ再スケジュール
 * update_lot_dff          P         ロットマスタ更新API呼出 画面用
 * update_line_allocation  P         明細割当更新API呼出 画面用
 * delete_line_allocation  P         明細割当削除API呼出 画面用
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/08   1.0   T.Oikawa         新規作成
 *  2008/12/22   1.1   Oracle 二瓶 大輔 本番障害#743対応(ロット追加・更新関数)
 *****************************************************************************************/
AS
--
  PROCEDURE save_batch(
    it_batch_id                     IN  gme_batch_header.batch_id%TYPE
  , ov_retcode                      OUT VARCHAR2
  );
--
  PROCEDURE create_batch(
    it_plan_start_date              IN  gme_batch_header.plan_start_date          %TYPE
  , it_plan_cmplt_date              IN  gme_batch_header.plan_cmplt_date          %TYPE
  , it_recipe_validity_rule_id      IN  gme_batch_header.recipe_validity_rule_id  %TYPE     -- 妥当性ルールID
  , it_plant_code                   IN  gme_batch_header.plant_code               %TYPE
  , it_wip_whse_code                IN  gme_batch_header.wip_whse_code            %TYPE
  , in_batch_size                   IN  NUMBER
  , iv_batch_size_uom               IN  VARCHAR2
  , ot_batch_id                     OUT gme_batch_header.batch_id                 %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE create_lot(
    it_item_id                      IN         ic_item_mst_b.item_id%TYPE                   -- 品目ID
  , it_item_no                      IN         ic_item_mst_b.item_no%TYPE                   -- 品目コード
  , ot_lot_id                       OUT NOCOPY ic_lots_mst.lot_id   %TYPE                   -- ロットID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE insert_line_allocation(
    it_item_id                      IN         gme_inventory_txns_gtmp.item_id            %TYPE
  , it_whse_code                    IN         gme_inventory_txns_gtmp.whse_code          %TYPE
  , it_lot_id                       IN         gme_inventory_txns_gtmp.lot_id             %TYPE
  , it_location                     IN         gme_inventory_txns_gtmp.location           %TYPE
  , it_doc_id                       IN         gme_inventory_txns_gtmp.doc_id             %TYPE
  , it_trans_date                   IN         gme_inventory_txns_gtmp.trans_date         %TYPE
  , it_trans_qty                    IN         gme_inventory_txns_gtmp.trans_qty          %TYPE
  , it_completed_ind                IN         gme_inventory_txns_gtmp.completed_ind      %TYPE
  , it_material_detail_id           IN         gme_inventory_txns_gtmp.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE insert_material_line(
    it_batch_id                     IN         gme_material_details.batch_id           %TYPE  -- バッチID
  , it_item_id                      IN         gme_material_details.item_id            %TYPE  -- 品目ID
  , it_item_um                      IN         gme_material_details.item_um            %TYPE  -- 単位
  , it_slit                         IN         gme_material_details.attribute8         %TYPE  -- 投入口
  , it_attribute5                   IN         gme_material_details.attribute5         %TYPE  -- 打込区分
  , it_attribute7                   IN         gme_material_details.attribute7         %TYPE  -- 依頼総数
  , it_attribute13                  IN         gme_material_details.attribute13        %TYPE  -- 出倉庫コード１
  , it_attribute18                  IN         gme_material_details.attribute18        %TYPE  -- 出倉庫コード２
  , it_attribute19                  IN         gme_material_details.attribute19        %TYPE  -- 出倉庫コード３
  , it_attribute20                  IN         gme_material_details.attribute20        %TYPE  -- 出倉庫コード４
  , it_attribute21                  IN         gme_material_details.attribute21        %TYPE  -- 出倉庫コード５
  , ot_material_detail_id           OUT        gme_material_details.material_detail_id %TYPE  -- 生産原料詳細ID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                       -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                       -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                       -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE delete_material_line(
    it_batch_id                     IN         gme_material_details.item_id            %TYPE
  , it_material_detail_id           IN         gme_material_details.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE reschedule_batch(
    it_batch_id                     IN         gme_batch_header.batch_id         %TYPE
  , it_plan_start_date              IN         gme_batch_header.plan_start_date  %TYPE
  , it_plan_cmplt_date              IN         gme_batch_header.plan_cmplt_date  %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE update_lot_dff(
    it_item_id                      IN         ic_lots_mst.item_id     %TYPE              -- 品目ID
  , it_lot_id                       IN         ic_lots_mst.lot_id      %TYPE              -- ロットID
  , it_attribute2                   IN         ic_lots_mst.attribute2  %TYPE DEFAULT NULL -- 固有記号
  , it_attribute13                  IN         ic_lots_mst.attribute13 %TYPE DEFAULT NULL -- タイプ
  , it_attribute14                  IN         ic_lots_mst.attribute14 %TYPE DEFAULT NULL -- ランク1
  , it_attribute15                  IN         ic_lots_mst.attribute15 %TYPE DEFAULT NULL -- ランク2
  , it_attribute16                  IN         ic_lots_mst.attribute16 %TYPE DEFAULT NULL -- 伝票区分
  , it_attribute17                  IN         ic_lots_mst.attribute17 %TYPE DEFAULT NULL -- ラインNo
  , it_attribute18                  IN         ic_lots_mst.attribute18 %TYPE DEFAULT NULL -- 摘要
  , it_attribute23                  IN         ic_lots_mst.attribute23 %TYPE DEFAULT NULL -- ロットステータス
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE update_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE             -- バッチID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE             -- 保留在庫TrID
  , it_trans_qty                    IN         ic_tran_pnd.trans_qty      %TYPE             -- 指示総数
  , it_completed_ind                IN         ic_tran_pnd.completed_ind  %TYPE             -- 完了フラグ
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
  PROCEDURE delete_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE             -- バッチID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE             -- 保留在庫TrID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- リターン・コード
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ
  );
--
END xxwip_common2_pkg;
/
