CREATE OR REPLACE PACKAGE xxcmn_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common2_pkg(SPEC)
 * Description            : 共通関数2(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_引当可能数算出（補足資料）.doc
 * Version                : 1.19
 *
 * Program List
 *  --------------------------- ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------------- ---- ----- --------------------------------------------------
 *  get_inv_onhand_lot            P   なし  ロット    I0  EBS手持在庫
 *  get_inv_lot_in_inout_rpt_qty  P   なし  ロット    I1  実績未取在庫数  移動入庫（入出庫報告有）
 *  get_inv_lot_in_in_rpt_qty     P   なし  ロット    I2  実績未取在庫数  移動入庫（入庫報告有）
 *  get_inv_lot_out_inout_rpt_qty P   なし  ロット    I3  実績未取在庫数  移動出庫（入出庫報告有）
 *  get_inv_lot_out_out_rpt_qty   P   なし  ロット    I4  実績未取在庫数  移動出庫（出庫報告有）
 *  get_inv_lot_ship_qty          P   なし  ロット    I5  実績未取在庫数  出荷
 *  get_inv_lot_provide_qty       P   なし  ロット    I6  実績未取在庫数  支給
 *  get_inv_lot_in_inout_cor_qty  P   なし  ロット    I7  実績未取在庫数  移動入庫訂正（入出庫報告有）
 *  get_inv_lot_out_inout_cor_qty P   なし  ロット    I8  実績未取在庫数  移動出庫訂正（入出庫報告有）
 *  get_sup_lot_inv_in_qty        P   なし  ロット    S1  供給数  移動入庫予定
 *  get_sup_lot_order_qty         P   なし  ロット    S2  供給数  発注受入予定
 *  get_sup_lot_produce_qty       P   なし  ロット    S3  供給数  生産入庫予定
 *  get_sup_lot_inv_out_qty       P   なし  ロット    S4  供給数  実績計上済の移動出庫実績
 *  get_dem_lot_ship_qty          p   なし  ロット    D1  需要数  実績未計上の出荷依頼（IDベース）
 *  get_dem_lot_ship_qty2         p   なし  ロット    D1  需要数  実績未計上の出荷依頼（CODEベース）
 *  get_dem_lot_provide_qty       p   なし  ロット    D2  需要数  実績未計上の支給指示（IDベース）
 *  get_dem_lot_provide_qty2      p   なし  ロット    D2  需要数  実績未計上の支給指示（CODEベース）
 *  get_dem_lot_inv_out_qty       P   なし  ロット    D3  需要数  実績未計上の移動指示
 *  get_dem_lot_inv_in_qty        P   なし  ロット    D4  需要数  実績計上済の移動入庫実績
 *  get_dem_lot_produce_qty       P   なし  ロット    D5  需要数  実績未計上の生産投入予定
 *  get_dem_lot_order_qty         P   なし  ロット    D6  需要数  実績未計上の相手先倉庫発注入庫予定
 *  get_inv_onhand                P   なし  非ロット  I0  EBS手持在庫
 *  get_inv_in_inout_rpt_qty      P   なし  非ロット  I1  実績未取在庫数  移動入庫（入出庫報告有）
 *  get_inv_in_in_rpt_qty         P   なし  非ロット  I2  実績未取在庫数  移動入庫（入庫報告有）
 *  get_inv_out_inout_rpt_qty     P   なし  非ロット  I3  実績未取在庫数  移動出庫（入出庫報告有）
 *  get_inv_out_out_rpt_qty       P   なし  非ロット  I4  実績未取在庫数  移動出庫（出庫報告有）
 *  get_inv_ship_qty              P   なし  非ロット  I5  実績未取在庫数  出荷
 *  get_inv_provide_qty           P   なし  非ロット  I6  実績未取在庫数  支給
 *  get_inv_in_inout_cor_qty      P   なし  非ロット  I7  実績未取在庫数  移動入庫訂正（入出庫報告有）
 *  get_inv_out_inout_cor_qty     P   なし  非ロット  I8  実績未取在庫数  移動出庫訂正（入出庫報告有）
 *  get_sup_inv_in_qty            P   なし  非ロット  S1  供給数  移動入庫予定
 *  get_sup_order_qty             P   なし  非ロット  S2  供給数  発注受入予定
 *  get_sup_inv_out_qty           P   なし  非ロット  S4  供給数  実績計上済の移動出庫実績
 *  get_dem_ship_qty              P   なし  非ロット  D1  需要数  実績未計上の出荷依頼
 *  get_dem_provide_qty           P   なし  非ロット  D2  需要数  実績未計上の支給指示
 *  get_dem_inv_out_qty           P   なし  非ロット  D3  需要数  実績未計上の移動指示
 *  get_dem_inv_in_qty            P   なし  非ロット  D4  需要数  実績計上済の移動入庫実績
 *  get_dem_produce_qty           P   なし  非ロット  D5  需要数  実績未計上の生産投入予定
 *  get_can_enc_total_qty         F   NUM   総引当可能数算出API
 *  get_can_enc_in_time_qty       F   NUM   有効日ベース引当可能数算出API
 *  get_stock_qty                 F   NUM   手持在庫数量算出API
 *  get_can_enc_qty               F   NUM   引当可能数算出API
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/26   1.0   oracle 丸下     新規作成
 *
 *  2008/02/04   抽出元のテーブルは、ビューを使用しない事とする。
 *  2008/04/03   1.1   oracle 丸下     内部変更要求#32 get_stock_qty修正
 *  2008/05/22   1.2   oracle 椎名     内部変更要求#98対応
 *  2008/06/19   1.3   oracle 吉田     結合テスト不具合対応(D6 引数設定の変数(品目コード)変更)
 *  2008/06/24   1.4   oracle 竹本     結合テスト不具合対応(I5,I6 引数設定の変数(品目コード)変更)
 *  2008/06/24   1.4   oracle 新藤     システムテスト不具合対応#75(D5)
 *  2008/07/16   1.5   oracle 北寒寺   変更要求#93対応
 *  2008/07/25   1.6   oracle 北寒寺   結合テスト不具合対応
 *  2008/09/09   1.7   oracle 椎名     PT 6-1_28 指摘44 対応
 *  2008/09/09   1.8   oracle 椎名     PT 6-1_28 指摘44 修正
 *  2008/09/11   1.9   oracle 椎名     PT 6-1_28 指摘73 対応
 *  2008/07/18   1.10  oracle 北寒寺   TE080_BPO540指摘5対応
 *  2008/09/16   1.11  oracle 椎名     TE080_BPO540指摘5修正
 *  2008/09/17   1.12  oracle 椎名     PT 6-1_28 指摘73 追加修正
 *  2008/11/19   1.13  oracle 伊藤     統合テスト指摘681修正
 *  2008/12/02   1.14  oracle 二瓶     本番障害#251対応（条件追加) 
 *  2008/12/15   1.15  oracle 伊藤     本番障害#645対応 D4,S4 予定日でなく実績日で取得する。
 *  2008/12/18   1.16  oracle 伊藤     本番障害#648対応 I5,I6 訂正前数量 - 実績数量を返す。
 *  2008/12/24   1.17  oracle 山本     本番障害#836対応 S3    生産入庫予定抽出条件追加
 *  2009/03/31   1.18  野村            本番障害#1346対応
 *  2010/02/23   1.19  SCS伊藤         E_本稼動_01612対応
 *
 *****************************************************************************************/
--
  -- ロット I0)EBS手持在庫取得プロシージャ
  PROCEDURE get_inv_onhand_lot(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_whse_id     OUT NOCOPY NUMBER,       -- 保管倉庫ID
    on_item_id     OUT NOCOPY NUMBER,       -- 品目ID
    on_lot_id      OUT NOCOPY NUMBER,       -- ロットID
    on_onhand      OUT NOCOPY NUMBER,       -- 手持数量
    ov_whse_code   OUT NOCOPY VARCHAR2,     -- 保管倉庫コード
    ov_rep_whse    OUT NOCOPY VARCHAR2,     -- 代表倉庫
    ov_item_code   OUT NOCOPY VARCHAR2,     -- 品目コード
    ov_lot_no      OUT NOCOPY VARCHAR2,     -- ロットNO
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I1)実績未取在庫数  移動入庫（入出庫報告有）
  PROCEDURE get_inv_lot_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I2)実績未取在庫数  移動入庫（入庫報告有）
  PROCEDURE get_inv_lot_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I3)実績未取在庫数  移動出庫（入出庫報告有）
  PROCEDURE get_inv_lot_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I4)実績未取在庫数  移動出庫（出庫報告有）
  PROCEDURE get_inv_lot_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I5)実績未取在庫数  出荷
  PROCEDURE get_inv_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I6)実績未取在庫数  支給
  PROCEDURE get_inv_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
  PROCEDURE get_inv_lot_in_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
  PROCEDURE get_inv_lot_out_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット S1)供給数  移動入庫予定
  PROCEDURE get_sup_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット S2)供給数  発注受入予定
  PROCEDURE get_sup_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    iv_item_code   IN VARCHAR2,             -- 品目コード
    iv_lot_no      IN VARCHAR2,             -- ロットNO
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット S3)供給数  生産入庫予定
  PROCEDURE get_sup_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット S4)供給数  実績計上済の移動出庫実績
  PROCEDURE get_sup_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット D1)需要数  実績未計上の出荷依頼
  PROCEDURE get_dem_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
-- 2008/09/10 V1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- 品目ID
    in_item_code   IN VARCHAR2,             -- 品目
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- 品目ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2008/09/10 v1.8 ADD START
  -- ロット D1)需要数  実績未計上の出荷依頼（CODEベース）
  PROCEDURE get_dem_lot_ship_qty2(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_code   IN VARCHAR2,             -- 品目
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2008/09/10 v1.8 ADD END
  -- ロット D2)需要数  実績未計上の支給指示
  PROCEDURE get_dem_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
-- 2008/09/10 V1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- 品目ID
    in_item_code   IN VARCHAR2,             -- 品目
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- 品目ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2008/09/10 v1.8 ADD START
  -- ロット D2)需要数  実績未計上の支給指示（CODEベース）
  PROCEDURE get_dem_lot_provide_qty2(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_code   IN VARCHAR2,             -- 品目
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2008/09/10 v1.8 ADD END
  -- ロット D3)需要数  実績未計上の移動指示
  PROCEDURE get_dem_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット D4)需要数  実績計上済の移動入庫実績
  PROCEDURE get_dem_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット D5)需要数  実績未計上の生産投入予定
  PROCEDURE get_dem_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    in_item_id     IN NUMBER,               -- 品目ID
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ロット D6)需要数  実績未計上の相手先倉庫発注入庫予定
  PROCEDURE get_dem_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    iv_item_code   IN VARCHAR2,             -- 品目コード
    in_lot_id      IN NUMBER,               -- ロットID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I0)EBS手持在庫
  PROCEDURE get_inv_onhand(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_whse_id     OUT NOCOPY NUMBER,       -- 保管倉庫ID
    on_item_id     OUT NOCOPY NUMBER,       -- 品目ID
    on_onhand      OUT NOCOPY NUMBER,       -- 手持数量
    ov_whse_code   OUT NOCOPY VARCHAR2,     -- 保管倉庫コード
    ov_rep_whse    OUT NOCOPY VARCHAR2,     -- 代表倉庫
    ov_item_code   OUT NOCOPY VARCHAR2,     -- 品目コード
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I1)実績未取在庫数  移動入庫（入出庫報告有）
  PROCEDURE get_inv_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I2)実績未取在庫数  移動入庫（入庫報告有）
  PROCEDURE get_inv_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I3)実績未取在庫数  移動出庫（入出庫報告有）
  PROCEDURE get_inv_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I4)実績未取在庫数  移動出庫（出庫報告有）
  PROCEDURE get_inv_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I5  実績未取在庫数  出荷
  PROCEDURE get_inv_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I6)実績未取在庫数  支給
  PROCEDURE get_inv_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
  PROCEDURE get_inv_in_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
  PROCEDURE get_inv_out_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    on_before_qty  OUT NOCOPY NUMBER,       -- 訂正前数量
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  S1)供給数  移動入庫予定
  PROCEDURE get_sup_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  S2)供給数  発注受入予定
  PROCEDURE get_sup_order_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    iv_item_code   IN VARCHAR2,             -- 品目コード
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  S4)供給数  実績計上済の移動出庫実績
  PROCEDURE get_sup_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  D1)需要数  実績未計上の出荷依頼
  PROCEDURE get_dem_ship_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  D2)需要数  実績未計上の支給指示
  PROCEDURE get_dem_provide_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    iv_item_code   IN VARCHAR2,             -- 品目コード
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  D3)需要数  実績未計上の移動指示
  PROCEDURE get_dem_inv_out_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  D4)需要数  実績計上済の移動入庫実績
  PROCEDURE get_dem_inv_in_qty(
    in_whse_id     IN NUMBER,               -- 保管倉庫ID
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 非ロット  D5)需要数  実績未計上の生産投入予定
  PROCEDURE get_dem_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- 保管倉庫コード
    in_item_id     IN NUMBER,               -- 品目ID
    id_eff_date    IN DATE,                 -- 有効日付
    on_qty         OUT NOCOPY NUMBER,       -- 数量
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ユーザー・エラー・メッセージ --# 固定 #
--
--  有効日ベース引当可能数算出APIと統合
--  -- 総引当可能数算出API
--  FUNCTION get_can_enc_total_qty(
--    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
--    in_item_id          IN NUMBER,                    -- OPM品目ID
--    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
--    RETURN NUMBER;                                    -- 総引当可能数
----
  -- 有効日ベース引当可能数算出API
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE    DEFAULT NULL)      -- 有効日
    RETURN NUMBER;                                    -- 引当可能数
--
  -- 手持在庫数量算出API
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ロットID
    RETURN NUMBER;                                    -- 手持在庫数量
--
  -- 引当可能数算出API
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM保管倉庫ID
    in_item_id          IN NUMBER,                    -- OPM品目ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ロットID
    in_active_date      IN DATE)                      -- 有効日
    RETURN NUMBER;                                    -- 引当可能数
--
END xxcmn_common2_pkg;
/
