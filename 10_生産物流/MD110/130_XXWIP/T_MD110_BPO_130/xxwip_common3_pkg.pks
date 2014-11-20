create or replace PACKAGE xxwip_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip_common3_pkg(SPEC)
 * Description            : 共通関数(XXWIP)(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.4
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  check_lastmonth_close   P        前月運賃締後チェック
 *  get_ship_method         P        配送区分情報VIEW抽出
 *  get_delivery_distance   P        配送距離アドオンマスタ抽出 
 *  get_delivery_company    P        運賃用運送業者アドオンマスタ抽出
 *  get_delivery_charges    P        運賃アドオンマスタ抽出
 *  get_deliverys_ctrl      P        運賃計算用コントロール抽出
 *  update_deliverys_ctrl   P        運賃計算用コントロール更新
 *  change_code_division    P        運賃コード区分変換
 *  deliv_rcv_ship_conv_qty F   NUM  運賃入出庫換算関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/02/20  1.0    M.Nomura        新規作成
 *  2008/03/18  1.1    M.Nomura        運賃計算用 追加
 *  2008/07/17  1.2    M.Nomura        変更要求#96、#98対応・内部課題32対応
 *  2008/10/01  1.3    Y.Kawano        内部変更#220,T_S_500対応
 *  2008/11/27  1.4    D.Nihei         本番障害#173対応
 *
 *****************************************************************************************/
--
--
  -- ===============================
  -- グローバル型
  -- ===============================
--
  -- **************************************************
  -- 配送区分情報VIEW抽出
  -- **************************************************
  -- 配送区分情報VIEW取得用PL/SQL表型
  TYPE ship_method_rec IS RECORD(
      small_amount_class  xxwsh_ship_method2_v.small_amount_class%TYPE -- 小口区分
    , mixed_class         xxwsh_ship_method2_v.mixed_class%TYPE        -- 混載区分
  );
--
  -- **************************************************
  -- 配送距離アドオンマスタ抽出
  -- **************************************************
  -- 配送距離アドオンマスタ抽出取得用PL/SQL表型
  TYPE delivery_distance_rec IS RECORD(
      post_distance         xxwip_delivery_distance.post_distance%TYPE          -- 車立距離
    , small_distance        xxwip_delivery_distance.small_distance%TYPE         -- 小口距離
    , consolid_add_distance xxwip_delivery_distance.consolid_add_distance%TYPE  -- 混載割増距離
    , actual_distance       xxwip_delivery_distance.actual_distance%TYPE        -- 実際距離
  );
--
  -- **************************************************
  -- 運賃用運送業者アドオンマスタ抽出
  -- **************************************************
  -- 運賃用運送業者アドオンマスタ抽出取得用PL/SQL表型
  TYPE delivery_company_rec IS RECORD(
      small_weight          xxwip_delivery_company.small_weight%TYPE         -- 小口重量
    , pay_picking_amount    xxwip_delivery_company.pay_picking_amount%TYPE   -- 支払ピッキング単価
    , bill_picking_amount   xxwip_delivery_company.bill_picking_amount%TYPE  -- 請求ピッキング単価
  );
--
  -- **************************************************
  -- 運賃アドオンマスタ抽出
  -- **************************************************
  -- 運賃アドオンマスタ抽出取得用PL/SQL表型
  TYPE delivery_charges_rec IS RECORD(
      shipping_expenses   xxwip_delivery_charges.shipping_expenses%TYPE   -- 運送費
    , leaf_consolid_add   xxwip_delivery_charges.leaf_consolid_add%TYPE   -- リーフ混載割増
  );
--
  -- ********** 共通 定数 **********
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- 前月運賃締後チェック
  PROCEDURE check_lastmonth_close(
    ov_close_type   OUT NOCOPY VARCHAR2,           -- 締め区分（Y：締め前、N：締め後）
    ov_errbuf       OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2);   -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 配送区分情報VIEW抽出
  PROCEDURE get_ship_method(
    iv_ship_method_code IN  xxwsh_ship_method2_v.ship_method_code%TYPE,           -- 配送区分
    id_target_date      IN  DATE,                                                 -- 判断日
    or_dlvry_dstn       OUT ship_method_rec,                                      -- 配送区分レコード
    ov_errbuf           OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY  VARCHAR2,    -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY  VARCHAR2);   -- ユーザー・エラー・メッセージ  --# 固定 #
--
  -- 配送距離アドオンマスタ抽出
  PROCEDURE get_delivery_distance(
    iv_goods_classe           IN  xxwip_delivery_distance.goods_classe%TYPE,          -- 商品区分
    iv_delivery_company_code  IN  xxwip_delivery_distance.delivery_company_code%TYPE, -- 運送業者
    iv_origin_shipment        IN  xxwip_delivery_distance.origin_shipment%TYPE,       -- 出庫倉庫
    iv_code_division          IN  xxwip_delivery_distance.code_division%TYPE,         -- コード区分
    iv_shipping_address_code  IN  xxwip_delivery_distance.shipping_address_code%TYPE, -- 配送先コード
    id_target_date            IN  DATE,                                               -- 判断日
    or_delivery_distance      OUT delivery_distance_rec,                              -- 配送距離レコード
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ                  --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- リターン・コード                    --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2);   -- ユーザー・エラー・メッセージ        --# 固定 #
--
  -- 運賃用運送業者アドオンマスタ抽出
  PROCEDURE get_delivery_company(
    iv_goods_classe           IN  xxwip_delivery_company.goods_classe%TYPE,           -- 商品区分
    iv_delivery_company_code  IN  xxwip_delivery_company.delivery_company_code%TYPE,  -- 運送業者
    id_target_date            IN  DATE,                                               -- 判断日
    or_delivery_company       OUT delivery_company_rec,                               -- 運賃用運送業者レコード
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ          --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- リターン・コード            --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2);   -- ユーザー・エラー・メッセージ--# 固定 #
--
  -- 運賃アドオンマスタ抽出
  PROCEDURE get_delivery_charges(
    iv_p_b_classe               IN  xxwip_delivery_charges.p_b_classe%TYPE,             -- 支払請求区分
    iv_goods_classe             IN  xxwip_delivery_charges.goods_classe%TYPE,           -- 商品区分
    iv_delivery_company_code    IN  xxwip_delivery_charges.delivery_company_code%TYPE,  -- 運送業者
    iv_shipping_address_classe  IN  xxwip_delivery_charges.shipping_address_classe%TYPE,-- 配送区分
    iv_delivery_distance        IN  xxwip_delivery_charges.delivery_distance%TYPE,      -- 運賃距離
    iv_delivery_weight          IN  xxwip_delivery_charges.delivery_weight%TYPE,        -- 重量
    id_target_date              IN  DATE,                                               -- 判断日
    or_delivery_charges         OUT delivery_charges_rec,                               -- 運賃アドオンレコード
    ov_errbuf                   OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ          --# 固定 #
    ov_retcode                  OUT NOCOPY  VARCHAR2,    -- リターン・コード            --# 固定 #
    ov_errmsg                   OUT NOCOPY  VARCHAR2);   -- ユーザー・エラー・メッセージ--# 固定 #
--
  -- 運賃コード区分変換
  PROCEDURE change_code_division(
    iv_deliver_to_code_class  IN  xxwsh_carriers_schedule.deliver_to_code_class%TYPE, -- 配送先コード区分
    od_code_division          OUT xxwip_delivery_distance.code_division%TYPE,         -- コード区分（運賃用）
    ov_errbuf                 OUT NOCOPY  VARCHAR2,    -- エラー・メッセージ          --# 固定 #
    ov_retcode                OUT NOCOPY  VARCHAR2,    -- リターン・コード            --# 固定 #
    ov_errmsg                 OUT NOCOPY  VARCHAR2);   -- ユーザー・エラー・メッセージ--# 固定 #
--
  -- 運賃入出庫換算関数
  FUNCTION deliv_rcv_ship_conv_qty(
    in_item_cd    IN VARCHAR2,          -- 品目コード
    in_qty        IN NUMBER)            -- 変換対象の数量
    RETURN NUMBER;                      -- 変換結果の数量
--
END xxwip_common3_pkg;
/
