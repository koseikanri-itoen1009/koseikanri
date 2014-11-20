CREATE OR REPLACE PACKAGE xxpo_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxpo_common_pkg(SPEC)
 * Description            : 共通関数(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.2
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  inventory_posting     P    -     在庫数量API（Formsからのコール用）
 *  update_po             F    NUM   発注変更API（Formsからのコール用）
 *  key_delrec_chk        F    NUM   仕入単価マスタ削除前チェック処理（Formsからのコール用）
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/21   1.0   K.Aizawa         新規作成
 *  2008/04/08   1.1   K.Aizawa         発注変更APIを追加
 *  2010/03/01   1.2   M.Miyagawa       仕入単価マスタ削除前チェック処理追加
 *
 *****************************************************************************************/
--  
  PROCEDURE inventory_posting
  ( p_api_version           IN  NUMBER
  , p_init_msg_list         IN  VARCHAR2 DEFAULT FND_API.G_FALSE
  , p_commit                IN  VARCHAR2 DEFAULT FND_API.G_FALSE
  , p_validation_level      IN  NUMBER DEFAULT FND_API.G_VALID_LEVEL_FULL
  , p_trans_type            IN  NUMBER
  , p_item_no               IN  ic_item_mst.item_no%TYPE
  , p_journal_no            IN  ic_jrnl_mst.journal_no%TYPE
  , p_from_whse_code        IN  ic_tran_cmp.whse_code%TYPE
  , p_to_whse_code          IN  ic_tran_cmp.whse_code%TYPE  DEFAULT NULL
  , p_item_um               IN  ic_item_mst.item_um%TYPE    DEFAULT NULL
  , p_item_um2              IN  ic_item_mst.item_um2%TYPE   DEFAULT NULL
  , p_lot_no                IN  ic_lots_mst.lot_no%TYPE     DEFAULT NULL
  , p_sublot_no             IN  ic_lots_mst.sublot_no%TYPE  DEFAULT NULL
  , p_from_location         IN  ic_tran_cmp.location%TYPE   DEFAULT NULL
  , p_to_location           IN  ic_tran_cmp.location%TYPE   DEFAULT NULL
  , p_trans_qty             IN  ic_tran_cmp.trans_qty%TYPE  DEFAULT 0
  , p_trans_qty2            IN  ic_tran_cmp.trans_qty2%TYPE DEFAULT NULL
  , p_qc_grade              IN  ic_tran_cmp.qc_grade%TYPE   DEFAULT NULL
  , p_lot_status            IN  ic_tran_cmp.lot_status%TYPE DEFAULT NULL
  , p_co_code               IN  ic_tran_cmp.co_code%TYPE
  , p_orgn_code             IN  ic_tran_cmp.orgn_code%TYPE
  , p_trans_date            IN  ic_tran_cmp.trans_date%TYPE DEFAULT SYSDATE
  , p_reason_code           IN  ic_tran_cmp.reason_code%TYPE
  , p_user_name             IN  fnd_user.user_name%TYPE     DEFAULT 'OPM'
  , p_journal_comment       IN  ic_jrnl_mst.journal_comment%TYPE
  , p_attribute1            IN  ic_jrnl_mst.attribute1%TYPE          DEFAULT NULL
  , p_attribute2            IN  ic_jrnl_mst.attribute2%TYPE          DEFAULT NULL
  , p_attribute3            IN  ic_jrnl_mst.attribute3%TYPE          DEFAULT NULL
  , p_attribute4            IN  ic_jrnl_mst.attribute4%TYPE          DEFAULT NULL
  , p_attribute5            IN  ic_jrnl_mst.attribute5%TYPE          DEFAULT NULL
  , p_attribute6            IN  ic_jrnl_mst.attribute6%TYPE          DEFAULT NULL
  , p_attribute7            IN  ic_jrnl_mst.attribute7%TYPE          DEFAULT NULL
  , p_attribute8            IN  ic_jrnl_mst.attribute8%TYPE          DEFAULT NULL
  , p_attribute9            IN  ic_jrnl_mst.attribute9%TYPE          DEFAULT NULL
  , p_attribute10           IN  ic_jrnl_mst.attribute10%TYPE         DEFAULT NULL
  , p_attribute11           IN  ic_jrnl_mst.attribute11%TYPE         DEFAULT NULL
  , p_attribute12           IN  ic_jrnl_mst.attribute12%TYPE         DEFAULT NULL
  , p_attribute13           IN  ic_jrnl_mst.attribute13%TYPE         DEFAULT NULL
  , p_attribute14           IN  ic_jrnl_mst.attribute14%TYPE         DEFAULT NULL
  , p_attribute15           IN  ic_jrnl_mst.attribute15%TYPE         DEFAULT NULL
  , p_attribute16           IN  ic_jrnl_mst.attribute16%TYPE         DEFAULT NULL
  , p_attribute17           IN  ic_jrnl_mst.attribute17%TYPE         DEFAULT NULL
  , p_attribute18           IN  ic_jrnl_mst.attribute18%TYPE         DEFAULT NULL
  , p_attribute19           IN  ic_jrnl_mst.attribute19%TYPE         DEFAULT NULL
  , p_attribute20           IN  ic_jrnl_mst.attribute20%TYPE         DEFAULT NULL
  , p_attribute21           IN  ic_jrnl_mst.attribute21%TYPE         DEFAULT NULL
  , p_attribute22           IN  ic_jrnl_mst.attribute22%TYPE         DEFAULT NULL
  , p_attribute23           IN  ic_jrnl_mst.attribute23%TYPE         DEFAULT NULL
  , p_attribute24           IN  ic_jrnl_mst.attribute24%TYPE         DEFAULT NULL
  , p_attribute25           IN  ic_jrnl_mst.attribute25%TYPE         DEFAULT NULL
  , p_attribute26           IN  ic_jrnl_mst.attribute26%TYPE         DEFAULT NULL
  , p_attribute27           IN  ic_jrnl_mst.attribute27%TYPE         DEFAULT NULL
  , p_attribute28           IN  ic_jrnl_mst.attribute28%TYPE         DEFAULT NULL
  , p_attribute29           IN  ic_jrnl_mst.attribute29%TYPE         DEFAULT NULL
  , p_attribute30           IN  ic_jrnl_mst.attribute30%TYPE         DEFAULT NULL
  , p_attribute_category    IN  ic_jrnl_mst.attribute_category%TYPE  DEFAULT NULL
  , p_acctg_unit_no         IN  VARCHAR2  DEFAULT NULL
  , p_acct_no               IN  VARCHAR2  DEFAULT NULL
  , p_txn_type              IN  VARCHAR2  DEFAULT NULL
  , p_journal_ind           IN  VARCHAR2  DEFAULT NULL
  , p_move_entire_qty       IN  VARCHAR2  DEFAULT 'Y'
  , x_ic_jrnl_mst_row       OUT NOCOPY ic_jrnl_mst%ROWTYPE
  , x_ic_adjs_jnl_row1      OUT NOCOPY ic_adjs_jnl%ROWTYPE
  , x_ic_adjs_jnl_row2      OUT NOCOPY ic_adjs_jnl%ROWTYPE
  , x_return_status         OUT NOCOPY VARCHAR2
  , x_msg_count             OUT NOCOPY NUMBER
  , x_msg_data              OUT NOCOPY VARCHAR2
  );
--
  FUNCTION update_po
 (
    x_po_number             IN  VARCHAR2
  , x_release_number        IN  NUMBER
  , x_revision_number       IN  NUMBER
  , x_line_number           IN  NUMBER
  , x_shipment_number       IN  NUMBER
  , new_quantity            IN  NUMBER
  , new_price               IN  NUMBER
  , new_promised_date       IN  DATE
  , launch_approvals_flag   IN  VARCHAR2
  , update_source           IN  VARCHAR2
  , version                 IN  VARCHAR2
  , x_override_date         IN  DATE := NULL
  , p_buyer_name            IN  VARCHAR2  default NULL
  , p_module_name           IN  VARCHAR2 DEFAULT 'xxpo_common_pkg' -- 呼出元モジュール名（ログ出力用）
  , p_package_name          IN  VARCHAR2 DEFAULT 'po_update'       -- 呼出元パッケージ名（ログ出力用
  ) RETURN NUMBER;
--
-- 2010-03-01 M.Miyagawa Add Start E_本稼動_01315対応
  FUNCTION key_delrec_chk
 ( p_supply_to_id             IN VARCHAR2
 , p_item_id                  IN NUMBER
 , p_vendor_id                IN NUMBER
 , p_factory_code             IN VARCHAR2
 , p_futai_code               IN VARCHAR2
 , p_start_date_active        IN VARCHAR2
 , p_end_date_active          IN VARCHAR2
 ) RETURN NUMBER;
-- 2010-03-01 M.Miyagawa Add End
--
END xxpo_common_pkg;
/