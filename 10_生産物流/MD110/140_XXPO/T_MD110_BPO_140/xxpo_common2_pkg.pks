CREATE OR REPLACE PACKAGE xxpo_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxpo_common2_pkg(SPEC)
 * Description            : 共通関数(有償支給用)(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  update_order_data         F    N     全数入出庫 入出庫実績登録処理
 *  get_unit_price            F    N     価格表単価取得処理
 *  update_order_unit_price   P    -     受注明細アドオン単価更新処理
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/12   1.0   D.Nihei         新規作成
 *
 *****************************************************************************************/
--
  -- 全数入出庫 入出庫実績登録処理
  FUNCTION update_order_data(
    in_order_header_id    IN  NUMBER         -- 受注ヘッダアドオンID
   ,iv_record_type_code   IN  VARCHAR2       -- レコードタイプ(20：出庫実績、30：入庫実績)
   ,id_actual_date        IN  DATE           -- 実績日(入庫日・出庫日)
   ,in_created_by         IN  NUMBER         -- 作成者
   ,id_creation_date      IN  DATE           -- 作成日
   ,in_last_updated_by    IN  NUMBER         -- 最終更新者
   ,id_last_update_date   IN  DATE           -- 最終更新日
   ,in_last_update_login  IN  NUMBER         -- 最終更新ログイン
  ) 
  RETURN NUMBER;
--
  -- 価格表単価取得処理
  FUNCTION get_unit_price(
    in_inventory_item_id  IN  NUMBER         -- INV品目ID
   ,iv_list_id_vendor     IN  VARCHAR2       -- 取引先別価格表ID
   ,iv_list_id_represent  IN  VARCHAR2       -- 代表価格表ID
   ,id_arrival_date       IN  DATE           -- 適用日(入庫日)
  )
  RETURN NUMBER;
--
  -- 受注明細アドオン単価更新処理
  PROCEDURE update_order_unit_price(
    in_order_header_id    IN  xxwsh_order_lines_all.order_header_id%TYPE     -- 受注ヘッダアドオンID
   ,iv_list_id_vendor     IN  VARCHAR2                                       -- 取引先別価格表ID
   ,iv_list_id_represent  IN  VARCHAR2                                       -- 代表価格表ID
   ,id_arrival_date       IN  xxwsh_order_headers_all.arrival_date%TYPE      -- 適用日(入庫日)
   ,iv_return_flag        IN  VARCHAR2                                       -- 返品フラグ
   ,iv_item_class_code    IN  xxcmn_item_categories2_v.segment1%TYPE         -- 品目区分
   ,iv_item_no            IN  xxcmn_item_categories2_v.item_no%TYPE          -- OPM品目コード
   ,ov_retcode            OUT NOCOPY VARCHAR2                                -- エラーコード
   ,ov_errmsg             OUT NOCOPY VARCHAR2                                -- エラーメッセージ
   ,ov_system_msg         OUT NOCOPY VARCHAR2                                -- システムメッセージ
  );
--
END xxpo_common2_pkg;
/
