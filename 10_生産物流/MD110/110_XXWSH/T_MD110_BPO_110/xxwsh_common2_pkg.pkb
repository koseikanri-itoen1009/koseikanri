CREATE OR REPLACE PACKAGE BODY xxwsh_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common2_pkg(BODY)
 * Description            : 共通関数(OAF用)(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.3
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  copy_order_data         F    NUM   受注情報コピー処理
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/04/08   1.0   H.Itou          新規作成
 *  2008/12/06   1.1   T.Miyata        コピー作成時、出荷実績インタフェース済フラグをN(固定)とする。
 *  2008/12/16   1.2   D.Nihei         追加対象：実績計上済区分を追加。
 *  2008/12/19   1.3   M.Hokkanji      移動ロット詳細複写時に訂正前実績数量を追加
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common2_pkg'; -- パッケージ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Function Name   : copy_order_data
   * Description      : 受注情報コピー処理
   ***********************************************************************************/
  FUNCTION copy_order_data(
    it_header_id     IN  xxwsh_order_lines_all.order_header_id%TYPE )          -- 受注ヘッダアドオンID
  RETURN NUMBER  -- 新規受注ヘッダアドオンID
  IS 
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_order_data'; --プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
-- Ver1.3 M.Hokkanji Start
    -- *** ローカル定数 ***
    cv_document_type_code_10  CONSTANT VARCHAR2(2) := '10';     -- 出荷
    cv_document_type_code_30  CONSTANT VARCHAR2(2) := '30';     -- 移動
-- Ver1.3 M.Hokkanji End
    -- *** ローカル変数 ***
    lt_header_id xxwsh_order_headers_all.order_header_id%TYPE;  -- 受注ヘッダID
    lt_line_id   xxwsh_order_headers_all.order_header_id%TYPE;  -- 受注明細ID
--
    -- *** ローカル・カーソル ***
    -- 受注ヘッダアドオンカーソル
    CURSOR order_header_cur IS
      SELECT xoha.order_header_id             order_header_id             -- 受注ヘッダアドオンID
            ,xoha.order_type_id               order_type_id               -- 受注タイプID
            ,xoha.organization_id             organization_id             -- 組織ID
            ,xoha.latest_external_flag        latest_external_flag        -- 最新フラグ
            ,xoha.ordered_date                ordered_date                -- 受注日
            ,xoha.customer_id                 customer_id                 -- 顧客ID
            ,xoha.customer_code               customer_code               -- 顧客
            ,xoha.deliver_to_id               deliver_to_id               -- 出荷先ID
            ,xoha.deliver_to                  deliver_to                  -- 出荷先
            ,xoha.shipping_instructions       shipping_instructions       -- 出荷指示
            ,xoha.career_id                   career_id                   -- 運送業者ID
            ,xoha.freight_carrier_code        freight_carrier_code        -- 運送業者
            ,xoha.shipping_method_code        shipping_method_code        -- 配送区分
            ,xoha.cust_po_number              cust_po_number              -- 顧客発注
            ,xoha.price_list_id               price_list_id               -- 価格表
            ,xoha.request_no                  request_no                  -- 依頼No
-- 2008/12/16 D.Nihei Add Start 本番障害#759対応
            ,xoha.base_request_no             base_request_no             -- 元依頼No
-- 2008/12/16 D.Nihei Add End
            ,xoha.req_status                  req_status                  -- ステータス
            ,xoha.delivery_no                 delivery_no                 -- 配送No
            ,xoha.prev_delivery_no            prev_delivery_no            -- 前回配送No
            ,xoha.schedule_ship_date          schedule_ship_date          -- 出荷予定日
            ,xoha.schedule_arrival_date       schedule_arrival_date       -- 着荷予定日
            ,xoha.mixed_no                    mixed_no                    -- 混載元No
            ,xoha.collected_pallet_qty        collected_pallet_qty        -- パレット回収枚数
            ,xoha.confirm_request_class       confirm_request_class       -- 物流担当確認依頼区分
            ,xoha.freight_charge_class        freight_charge_class        -- 運賃区分
            ,xoha.shikyu_instruction_class    shikyu_instruction_class    -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class       shikyu_inst_rcv_class       -- 支給指示受領区分
            ,xoha.amount_fix_class            amount_fix_class            -- 有償金額確定区分
            ,xoha.takeback_class              takeback_class              -- 引取区分
            ,xoha.deliver_from_id             deliver_from_id             -- 出荷元ID
            ,xoha.deliver_from                deliver_from                -- 出荷元保管場所
            ,xoha.head_sales_branch           head_sales_branch           -- 管轄拠点
            ,xoha.input_sales_branch          input_sales_branch          -- 入力拠点
            ,xoha.po_no                       po_no                       -- 発注No
            ,xoha.prod_class                  prod_class                  -- 商品区分
            ,xoha.item_class                  item_class                  -- 品目区分
            ,xoha.no_cont_freight_class       no_cont_freight_class       -- 契約外運賃区分
            ,xoha.arrival_time_from           arrival_time_from           -- 着荷時間FROM
            ,xoha.arrival_time_to             arrival_time_to             -- 着荷時間TO
            ,xoha.designated_item_id          designated_item_id          -- 製造品目ID
            ,xoha.designated_item_code        designated_item_code        -- 製造品目
            ,xoha.designated_production_date  designated_production_date  -- 製造日
            ,xoha.designated_branch_no        designated_branch_no        -- 製造枝番
            ,xoha.slip_number                 slip_number                 -- 送り状No
            ,xoha.sum_quantity                sum_quantity                -- 合計数量
            ,xoha.small_quantity              small_quantity              -- 小口個数
            ,xoha.label_quantity              label_quantity              -- ラベル枚数
            ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- 重量積載効率
            ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- 容積積載効率
            ,xoha.based_weight                based_weight                -- 基本重量
            ,xoha.based_capacity              based_capacity              -- 基本容積
            ,xoha.sum_weight                  sum_weight                  -- 積載重量合計
            ,xoha.sum_capacity                sum_capacity                -- 積載容積合計
            ,xoha.mixed_ratio                 mixed_ratio                 -- 混載率
            ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- パレット合計枚数
            ,xoha.real_pallet_quantity        real_pallet_quantity        -- パレット実績枚数
            ,xoha.sum_pallet_weight           sum_pallet_weight           -- 合計パレット重量
            ,xoha.order_source_ref            order_source_ref            -- 受注ソース参照
            ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- 運送業者_実績ID
            ,xoha.result_freight_carrier_code result_freight_carrier_code -- 運送業者_実績
            ,xoha.result_shipping_method_code result_shipping_method_code -- 配送区分_実績
            ,xoha.result_deliver_to_id        result_deliver_to_id        -- 出荷先_実績ID
            ,xoha.result_deliver_to           result_deliver_to           -- 出荷先_実績
            ,xoha.shipped_date                shipped_date                -- 出荷日
            ,xoha.arrival_date                arrival_date                -- 着荷日
            ,xoha.weight_capacity_class       weight_capacity_class       -- 重量容積区分
            ,xoha.notif_status                notif_status                -- 通知ステータス
            ,xoha.prev_notif_status           prev_notif_status           -- 前回通知ステータス
            ,xoha.notif_date                  notif_date                  -- 確定通知実施日時
            ,xoha.new_modify_flg              new_modify_flg              -- 新規修正フラグ
            ,xoha.process_status              process_status              -- 処理経過ステータス
            ,xoha.performance_management_dept performance_management_dept -- 成績管理部署
            ,xoha.instruction_dept            instruction_dept            -- 指示部署
            ,xoha.transfer_location_id        transfer_location_id        -- 振替先ID
            ,xoha.transfer_location_code      transfer_location_code      -- 振替先
            ,xoha.mixed_sign                  mixed_sign                  -- 混載記号
            ,xoha.screen_update_date          screen_update_date          -- 画面更新日時
            ,xoha.screen_update_by            screen_update_by            -- 画面更新者
            ,xoha.tightening_date             tightening_date             -- 出荷依頼締め日時
            ,xoha.vendor_id                   vendor_id                   -- 取引先ID
            ,xoha.vendor_code                 vendor_code                 -- 取引先
            ,xoha.vendor_site_id              vendor_site_id              -- 取引先サイトID
            ,xoha.vendor_site_code            vendor_site_code            -- 取引先サイト
            ,xoha.registered_sequence         registered_sequence         -- 登録順序
            ,xoha.tightening_program_id       tightening_program_id       -- 締めコンカレントID
            ,xoha.corrected_tighten_class     corrected_tighten_class     -- 締め後修正区分
      FROM   xxwsh_order_headers_all          xoha                        -- 受注ヘッダアドオン
      WHERE  xoha.order_header_id = it_header_id;                         -- INパラメータ.受注ヘッダアドオンID
--
    -- 受注明細アドオンカーソル
    CURSOR order_line_cur(ln_header_id NUMBER) IS
      SELECT xola.order_header_id             order_header_id             -- 受注ヘッダアドオンID
            ,xola.order_line_id               order_line_id               -- 受注明細アドオンID
            ,xola.order_line_number           order_line_number           -- 明細番号
            ,xola.request_no                  request_no                  -- 依頼No
            ,xola.shipping_inventory_item_id  shipping_inventory_item_id  -- 出荷品目ID
            ,xola.shipping_item_code          shipping_item_code          -- 出荷品目
            ,xola.quantity                    quantity                    -- 数量
            ,xola.uom_code                    uom_code                    -- 単位
            ,xola.unit_price                  unit_price                  -- 単価
            ,xola.shipped_quantity            shipped_quantity            -- 出荷実績数量
            ,xola.designated_production_date  designated_production_date  -- 指定製造日
            ,xola.based_request_quantity      based_request_quantity      -- 拠点依頼数量
            ,xola.request_item_id             request_item_id             -- 依頼品目ID
            ,xola.request_item_code           request_item_code           -- 依頼品目
            ,xola.ship_to_quantity            ship_to_quantity            -- 入庫実績数量
            ,xola.futai_code                  futai_code                  -- 付帯コード
            ,xola.designated_date             designated_date             -- 指定日付（リーフ）
            ,xola.move_number                 move_number                 -- 移動No
            ,xola.po_number                   po_number                   -- 発注No
            ,xola.cust_po_number              cust_po_number              -- 顧客発注
            ,xola.pallet_quantity             pallet_quantity             -- パレット数
            ,xola.layer_quantity              layer_quantity              -- 段数
            ,xola.case_quantity               case_quantity               -- ケース数
            ,xola.weight                      weight                      -- 重量
            ,xola.capacity                    capacity                    -- 容積
            ,xola.pallet_qty                  pallet_qty                  -- パレット枚数
            ,xola.pallet_weight               pallet_weight               -- パレット重量
            ,xola.reserved_quantity           reserved_quantity           -- 引当数
            ,xola.automanual_reserve_class    automanual_reserve_class    -- 自動手動引当区分
            ,xola.delete_flag                 delete_flag                 -- 削除フラグ
            ,xola.warning_class               warning_class               -- 警告区分
            ,xola.warning_date                warning_date                -- 警告日付
            ,xola.line_description            line_description            -- 摘要
            ,xola.rm_if_flg                   rm_if_flg                   -- 倉替返品インタフェース済フラグ
            ,xola.shipping_request_if_flg     shipping_request_if_flg     -- 出荷依頼インタフェース済フラグ
            ,xola.shipping_result_if_flg      shipping_result_if_flg      -- 出荷実績インタフェース済フラグ
      FROM   xxwsh_order_lines_all            xola                        -- 受注明細アドオン
      WHERE  xola.order_header_id = ln_header_id;                         -- 受注ヘッダアドオンID
--
    -- 移動ロット詳細アドオンカーソル
    CURSOR mov_lot_dtl_cur(ln_line_id NUMBER) IS
      SELECT xmld.mov_lot_dtl_id            mov_lot_dtl_id            -- ロット詳細ID
            ,xmld.mov_line_id               mov_line_id               -- 明細ID
            ,xmld.document_type_code        document_type_code        -- 文書タイプ
            ,xmld.record_type_code          record_type_code          -- レコードタイプ
            ,xmld.item_id                   item_id                   -- OPM品目ID
            ,xmld.item_code                 item_code                 -- 品目
            ,xmld.lot_id                    lot_id                    -- ロットID
            ,xmld.lot_no                    lot_no                    -- ロットNo
            ,xmld.actual_date               actual_date               -- 実績日
            ,xmld.actual_quantity           actual_quantity           -- 実績数量
            ,xmld.automanual_reserve_class  automanual_reserve_class  -- 自動手動引当区分
      FROM   xxinv_mov_lot_details          xmld                      -- 移動ロット詳細アドオン
-- Ver1.3 M.Hokkanji Start
     WHERE   xmld.mov_line_id = ln_line_id                            -- 受注明細アドオンID
       AND   xmld.document_type_code IN (cv_document_type_code_10
                                        ,cv_document_type_code_30);   -- 文書タイプ
--      WHERE  xmld.mov_line_id = ln_line_id;                           -- 受注明細アドオンID
-- Ver1.3 M.Hokkanji End
--
    -- *** ローカル・レコード ***
    order_header_rec  order_header_cur%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- 受注ヘッダアドオンID取得
    SELECT xxwsh_order_headers_all_s1.NEXTVAL header_id
    INTO   lt_header_id
    FROM   DUAL;
--
    -- 受注ヘッダ情報取得
    OPEN  order_header_cur;
    FETCH order_header_cur INTO order_header_rec;
    CLOSE order_header_cur;
--
    -- ***********************************************
    -- ***  受注ヘッダアドオンコピー作成処理       ***
    -- ***********************************************
    INSERT INTO xxwsh_order_headers_all xoha(
       xoha.order_header_id              -- 受注ヘッダアドオンID
      ,xoha.order_type_id                -- 受注タイプID
      ,xoha.organization_id              -- 組織ID
      ,xoha.latest_external_flag         -- 最新フラグ
      ,xoha.ordered_date                 -- 受注日
      ,xoha.customer_id                  -- 顧客ID
      ,xoha.customer_code                -- 顧客
      ,xoha.deliver_to_id                -- 出荷先ID
      ,xoha.deliver_to                   -- 出荷先
      ,xoha.shipping_instructions        -- 出荷指示
      ,xoha.career_id                    -- 運送業者ID
      ,xoha.freight_carrier_code         -- 運送業者
      ,xoha.shipping_method_code         -- 配送区分
      ,xoha.cust_po_number               -- 顧客発注
      ,xoha.price_list_id                -- 価格表
      ,xoha.request_no                   -- 依頼No
-- 2008/12/16 D.Nihei Add Start 本番障害#759対応
      ,xoha.base_request_no              -- 元依頼No
-- 2008/12/16 D.Nihei Add End
      ,xoha.req_status                   -- ステータス
      ,xoha.delivery_no                  -- 配送No
      ,xoha.prev_delivery_no             -- 前回配送No
      ,xoha.schedule_ship_date           -- 出荷予定日
      ,xoha.schedule_arrival_date        -- 着荷予定日
      ,xoha.mixed_no                     -- 混載元No
      ,xoha.collected_pallet_qty         -- パレット回収枚数
      ,xoha.confirm_request_class        -- 物流担当確認依頼区分
      ,xoha.freight_charge_class         -- 運賃区分
      ,xoha.shikyu_instruction_class     -- 支給出庫指示区分
      ,xoha.shikyu_inst_rcv_class        -- 支給指示受領区分
      ,xoha.amount_fix_class             -- 有償金額確定区分
      ,xoha.takeback_class               -- 引取区分
      ,xoha.deliver_from_id              -- 出荷元ID
      ,xoha.deliver_from                 -- 出荷元保管場所
      ,xoha.head_sales_branch            -- 管轄拠点
      ,xoha.input_sales_branch           -- 入力拠点
      ,xoha.po_no                        -- 発注No
      ,xoha.prod_class                   -- 商品区分
      ,xoha.item_class                   -- 品目区分
      ,xoha.no_cont_freight_class        -- 契約外運賃区分
      ,xoha.arrival_time_from            -- 着荷時間FROM
      ,xoha.arrival_time_to              -- 着荷時間TO
      ,xoha.designated_item_id           -- 製造品目ID
      ,xoha.designated_item_code         -- 製造品目
      ,xoha.designated_production_date   -- 製造日
      ,xoha.designated_branch_no         -- 製造枝番
      ,xoha.slip_number                  -- 送り状No
      ,xoha.sum_quantity                 -- 合計数量
      ,xoha.small_quantity               -- 小口個数
      ,xoha.label_quantity               -- ラベル枚数
      ,xoha.loading_efficiency_weight    -- 重量積載効率
      ,xoha.loading_efficiency_capacity  -- 容積積載効率
      ,xoha.based_weight                 -- 基本重量
      ,xoha.based_capacity               -- 基本容積
      ,xoha.sum_weight                   -- 積載重量合計
      ,xoha.sum_capacity                 -- 積載容積合計
      ,xoha.mixed_ratio                  -- 混載率
      ,xoha.pallet_sum_quantity          -- パレット合計枚数
      ,xoha.real_pallet_quantity         -- パレット実績枚数
      ,xoha.sum_pallet_weight            -- 合計パレット重量
      ,xoha.order_source_ref             -- 受注ソース参照
      ,xoha.result_freight_carrier_id    -- 運送業者_実績ID
      ,xoha.result_freight_carrier_code  -- 運送業者_実績
      ,xoha.result_shipping_method_code  -- 配送区分_実績
      ,xoha.result_deliver_to_id         -- 出荷先_実績ID
      ,xoha.result_deliver_to            -- 出荷先_実績
      ,xoha.shipped_date                 -- 出荷日
      ,xoha.arrival_date                 -- 着荷日
      ,xoha.weight_capacity_class        -- 重量容積区分
-- 2008/12/16 D.Nihei Add Start 本番障害#759対応
      ,xoha.actual_confirm_class         -- 実績計上済区分
-- 2008/12/16 D.Nihei Add End
      ,xoha.notif_status                 -- 通知ステータス
      ,xoha.prev_notif_status            -- 前回通知ステータス
      ,xoha.notif_date                   -- 確定通知実施日時
      ,xoha.new_modify_flg               -- 新規修正フラグ
      ,xoha.process_status               -- 処理経過ステータス
      ,xoha.performance_management_dept  -- 成績管理部署
      ,xoha.instruction_dept             -- 指示部署
      ,xoha.transfer_location_id         -- 振替先ID
      ,xoha.transfer_location_code       -- 振替先
      ,xoha.mixed_sign                   -- 混載記号
      ,xoha.screen_update_date           -- 画面更新日時
      ,xoha.screen_update_by             -- 画面更新者
      ,xoha.tightening_date              -- 出荷依頼締め日時
      ,xoha.vendor_id                    -- 取引先ID
      ,xoha.vendor_code                  -- 取引先
      ,xoha.vendor_site_id               -- 取引先サイトID
      ,xoha.vendor_site_code             -- 取引先サイト
      ,xoha.registered_sequence          -- 登録順序
      ,xoha.tightening_program_id        -- 締めコンカレントID
      ,xoha.corrected_tighten_class      -- 締め後修正区分
      ,xoha.created_by                   -- 作成者
      ,xoha.creation_date                -- 作成日
      ,xoha.last_updated_by              -- 最終更新者
      ,xoha.last_update_date             -- 最終更新日
      ,xoha.last_update_login)           -- 最終更新ログイン
    VALUES(
       lt_header_id                                  -- 受注ヘッダアドオンID
      ,order_header_rec.order_type_id                -- 受注タイプID
      ,order_header_rec.organization_id              -- 組織ID
      ,order_header_rec.latest_external_flag         -- 最新フラグ
      ,order_header_rec.ordered_date                 -- 受注日
      ,order_header_rec.customer_id                  -- 顧客ID
      ,order_header_rec.customer_code                -- 顧客
      ,order_header_rec.deliver_to_id                -- 出荷先ID
      ,order_header_rec.deliver_to                   -- 出荷先
      ,order_header_rec.shipping_instructions        -- 出荷指示
      ,order_header_rec.career_id                    -- 運送業者ID
      ,order_header_rec.freight_carrier_code         -- 運送業者
      ,order_header_rec.shipping_method_code         -- 配送区分
      ,order_header_rec.cust_po_number               -- 顧客発注
      ,order_header_rec.price_list_id                -- 価格表
      ,order_header_rec.request_no                   -- 依頼No
-- 2008/12/16 D.Nihei Add Start 本番障害#759対応
      ,order_header_rec.base_request_no              -- 元依頼No
-- 2008/12/16 D.Nihei Add End
      ,order_header_rec.req_status                   -- ステータス
      ,order_header_rec.delivery_no                  -- 配送No
      ,order_header_rec.prev_delivery_no             -- 前回配送No
      ,order_header_rec.schedule_ship_date           -- 出荷予定日
      ,order_header_rec.schedule_arrival_date        -- 着荷予定日
      ,order_header_rec.mixed_no                     -- 混載元No
      ,order_header_rec.collected_pallet_qty         -- パレット回収枚数
      ,order_header_rec.confirm_request_class        -- 物流担当確認依頼区分
      ,order_header_rec.freight_charge_class         -- 運賃区分
      ,order_header_rec.shikyu_instruction_class     -- 支給出庫指示区分
      ,order_header_rec.shikyu_inst_rcv_class        -- 支給指示受領区分
      ,order_header_rec.amount_fix_class             -- 有償金額確定区分
      ,order_header_rec.takeback_class               -- 引取区分
      ,order_header_rec.deliver_from_id              -- 出荷元ID
      ,order_header_rec.deliver_from                 -- 出荷元保管場所
      ,order_header_rec.head_sales_branch            -- 管轄拠点
      ,order_header_rec.input_sales_branch           -- 入力拠点
      ,order_header_rec.po_no                        -- 発注No
      ,order_header_rec.prod_class                   -- 商品区分
      ,order_header_rec.item_class                   -- 品目区分
      ,order_header_rec.no_cont_freight_class        -- 契約外運賃区分
      ,order_header_rec.arrival_time_from            -- 着荷時間FROM
      ,order_header_rec.arrival_time_to              -- 着荷時間TO
      ,order_header_rec.designated_item_id           -- 製造品目ID
      ,order_header_rec.designated_item_code         -- 製造品目
      ,order_header_rec.designated_production_date   -- 製造日
      ,order_header_rec.designated_branch_no         -- 製造枝番
      ,order_header_rec.slip_number                  -- 送り状No
      ,order_header_rec.sum_quantity                 -- 合計数量
      ,order_header_rec.small_quantity               -- 小口個数
      ,order_header_rec.label_quantity               -- ラベル枚数
      ,order_header_rec.loading_efficiency_weight    -- 重量積載効率
      ,order_header_rec.loading_efficiency_capacity  -- 容積積載効率
      ,order_header_rec.based_weight                 -- 基本重量
      ,order_header_rec.based_capacity               -- 基本容積
      ,order_header_rec.sum_weight                   -- 積載重量合計
      ,order_header_rec.sum_capacity                 -- 積載容積合計
      ,order_header_rec.mixed_ratio                  -- 混載率
      ,order_header_rec.pallet_sum_quantity          -- パレット合計枚数
      ,order_header_rec.real_pallet_quantity         -- パレット実績枚数
      ,order_header_rec.sum_pallet_weight            -- 合計パレット重量
      ,order_header_rec.order_source_ref             -- 受注ソース参照
      ,order_header_rec.result_freight_carrier_id    -- 運送業者_実績ID
      ,order_header_rec.result_freight_carrier_code  -- 運送業者_実績
      ,order_header_rec.result_shipping_method_code  -- 配送区分_実績
      ,order_header_rec.result_deliver_to_id         -- 出荷先_実績ID
      ,order_header_rec.result_deliver_to            -- 出荷先_実績
      ,order_header_rec.shipped_date                 -- 出荷日
      ,order_header_rec.arrival_date                 -- 着荷日
      ,order_header_rec.weight_capacity_class        -- 重量容積区分
-- 2008/12/16 D.Nihei Add Start 本番障害#759対応
      ,'N'                                           -- 実績計上済区分
-- 2008/12/16 D.Nihei Add End
      ,order_header_rec.notif_status                 -- 通知ステータス
      ,order_header_rec.prev_notif_status            -- 前回通知ステータス
      ,order_header_rec.notif_date                   -- 確定通知実施日時
      ,order_header_rec.new_modify_flg               -- 新規修正フラグ
      ,order_header_rec.process_status               -- 処理経過ステータス
      ,order_header_rec.performance_management_dept  -- 成績管理部署
      ,order_header_rec.instruction_dept             -- 指示部署
      ,order_header_rec.transfer_location_id         -- 振替先ID
      ,order_header_rec.transfer_location_code       -- 振替先
      ,order_header_rec.mixed_sign                   -- 混載記号
      ,order_header_rec.screen_update_date           -- 画面更新日時
      ,order_header_rec.screen_update_by             -- 画面更新者
      ,order_header_rec.tightening_date              -- 出荷依頼締め日時
      ,order_header_rec.vendor_id                    -- 取引先ID
      ,order_header_rec.vendor_code                  -- 取引先
      ,order_header_rec.vendor_site_id               -- 取引先サイトID
      ,order_header_rec.vendor_site_code             -- 取引先サイト
      ,order_header_rec.registered_sequence          -- 登録順序
      ,order_header_rec.tightening_program_id        -- 締めコンカレントID
      ,order_header_rec.corrected_tighten_class      -- 締め後修正区分
      ,FND_GLOBAL.USER_ID          -- 作成者
      ,SYSDATE                     -- 作成日
      ,FND_GLOBAL.USER_ID          -- 最終更新者
      ,SYSDATE                     -- 最終更新日
      ,FND_GLOBAL.LOGIN_ID         -- 最終更新ログイン
    );
--
    -- ***********************************************
    -- ***  受注ヘッダアドオン最新フラグ更新処理   ***
    -- ***********************************************
    -- 前回履歴の最新フラグを「N」に更新する。
    UPDATE xxwsh_order_headers_all xoha
    SET    xoha.latest_external_flag = 'N'                         -- 最新フラグ
          ,xoha.last_updated_by      = FND_GLOBAL.USER_ID          -- 最終更新者
          ,xoha.last_update_date     = SYSDATE                     -- 最終更新日
          ,xoha.last_update_login    = FND_GLOBAL.LOGIN_ID         -- 最終更新ログイン
    WHERE xoha.order_header_id       = order_header_rec.order_header_id;  -- 受注ヘッダアドオンID
--
    <<order_line_loop>>
    FOR  order_line_rec IN order_line_cur(order_header_rec.order_header_id)
    LOOP
      -- 受注明細アドオンID取得
      SELECT xxwsh_order_lines_all_s1.NEXTVAL line_id
      INTO   lt_line_id
      FROM   DUAL;
--
      -- *********************************************
      -- ***  受注明細アドオンコピー作成処理       ***
      -- *********************************************
      INSERT INTO xxwsh_order_lines_all xola(
         xola.order_line_id                 -- 受注明細アドオンID
        ,xola.order_header_id               -- 受注ヘッダアドオンID
        ,xola.order_line_number             -- 明細番号
        ,xola.request_no                    -- 依頼No
        ,xola.shipping_inventory_item_id    -- 出荷品目ID
        ,xola.shipping_item_code            -- 出荷品目
        ,xola.quantity                      -- 数量
        ,xola.uom_code                      -- 単位
        ,xola.unit_price                    -- 単価
        ,xola.shipped_quantity              -- 出荷実績数量
        ,xola.designated_production_date    -- 指定製造日
        ,xola.based_request_quantity        -- 拠点依頼数量
        ,xola.request_item_id               -- 依頼品目ID
        ,xola.request_item_code             -- 依頼品目
        ,xola.ship_to_quantity              -- 入庫実績数量
        ,xola.futai_code                    -- 付帯コード
        ,xola.designated_date               -- 指定日付（リーフ）
        ,xola.move_number                   -- 移動No
        ,xola.po_number                     -- 発注No
        ,xola.cust_po_number                -- 顧客発注
        ,xola.pallet_quantity               -- パレット数
        ,xola.layer_quantity                -- 段数
        ,xola.case_quantity                 -- ケース数
        ,xola.weight                        -- 重量
        ,xola.capacity                      -- 容積
        ,xola.pallet_qty                    -- パレット枚数
        ,xola.pallet_weight                 -- パレット重量
        ,xola.reserved_quantity             -- 引当数
        ,xola.automanual_reserve_class      -- 自動手動引当区分
        ,xola.delete_flag                   -- 削除フラグ
        ,xola.warning_class                 -- 警告区分
        ,xola.warning_date                  -- 警告日付
        ,xola.line_description              -- 摘要
        ,xola.rm_if_flg                     -- 倉替返品インタフェース済フラグ
        ,xola.shipping_request_if_flg       -- 出荷依頼インタフェース済フラグ
        ,xola.shipping_result_if_flg        -- 出荷実績インタフェース済フラグ
        ,xola.created_by                    -- 作成者
        ,xola.creation_date                 -- 作成日
        ,xola.last_updated_by               -- 最終更新者
        ,xola.last_update_date              -- 最終更新日
        ,xola.last_update_login)            -- 最終更新ログイン
      VALUES(
         lt_line_id                                   -- 受注明細アドオンID
        ,lt_header_id                                 -- 受注ヘッダアドオンID
        ,order_line_rec.order_line_number             -- 明細番号
        ,order_line_rec.request_no                    -- 依頼No
        ,order_line_rec.shipping_inventory_item_id    -- 出荷品目ID
        ,order_line_rec.shipping_item_code            -- 出荷品目
        ,order_line_rec.quantity                      -- 数量
        ,order_line_rec.uom_code                      -- 単位
        ,order_line_rec.unit_price                    -- 単価
        ,order_line_rec.shipped_quantity              -- 出荷実績数量
        ,order_line_rec.designated_production_date    -- 指定製造日
        ,order_line_rec.based_request_quantity        -- 拠点依頼数量
        ,order_line_rec.request_item_id               -- 依頼品目ID
        ,order_line_rec.request_item_code             -- 依頼品目
        ,order_line_rec.ship_to_quantity              -- 入庫実績数量
        ,order_line_rec.futai_code                    -- 付帯コード
        ,order_line_rec.designated_date               -- 指定日付（リーフ）
        ,order_line_rec.move_number                   -- 移動No
        ,order_line_rec.po_number                     -- 発注No
        ,order_line_rec.cust_po_number                -- 顧客発注
        ,order_line_rec.pallet_quantity               -- パレット数
        ,order_line_rec.layer_quantity                -- 段数
        ,order_line_rec.case_quantity                 -- ケース数
        ,order_line_rec.weight                        -- 重量
        ,order_line_rec.capacity                      -- 容積
        ,order_line_rec.pallet_qty                    -- パレット枚数
        ,order_line_rec.pallet_weight                 -- パレット重量
        ,order_line_rec.reserved_quantity             -- 引当数
        ,order_line_rec.automanual_reserve_class      -- 自動手動引当区分
        ,order_line_rec.delete_flag                   -- 削除フラグ
        ,order_line_rec.warning_class                 -- 警告区分
        ,order_line_rec.warning_date                  -- 警告日付
        ,order_line_rec.line_description              -- 摘要
        ,order_line_rec.rm_if_flg                     -- 倉替返品インタフェース済フラグ
        ,order_line_rec.shipping_request_if_flg       -- 出荷依頼インタフェース済フラグ
-- 2008/12/06 T.Miyata Modify Start #484 コピー作成時にはIFされていないため、出荷実績インタフェース済フラグをNとする。
--        ,order_line_rec.shipping_result_if_flg        -- 出荷実績インタフェース済フラグ
        ,'N'                         -- 出荷実績インタフェース済フラグ
-- 2008/12/06 T.Miyata Modify End #484
        ,FND_GLOBAL.USER_ID          -- 作成者
        ,SYSDATE                     -- 作成日
        ,FND_GLOBAL.USER_ID          -- 最終更新者
        ,SYSDATE                     -- 最終更新日
        ,FND_GLOBAL.LOGIN_ID         -- 最終更新ログイン
      );
--
      -- *********************************************
      -- ***  移動ロット詳細アドオンコピー作成処理 ***
      -- *********************************************
      <<mov_lot_dtl_loop>>
      FOR mov_lot_dtl_rec IN mov_lot_dtl_cur(order_line_rec.order_line_id)
      LOOP
        INSERT INTO xxinv_mov_lot_details xmld(
           xmld.mov_lot_dtl_id              -- ロット詳細ID
          ,xmld.mov_line_id                 -- 明細ID
          ,xmld.document_type_code          -- 文書タイプ
          ,xmld.record_type_code            -- レコードタイプ
          ,xmld.item_id                     -- OPM品目ID
          ,xmld.item_code                   -- 品目
          ,xmld.lot_id                      -- ロットID
          ,xmld.lot_no                      -- ロットNo
          ,xmld.actual_date                 -- 実績日
          ,xmld.actual_quantity             -- 実績数量
-- Ver1.3 M.Hokkanji Start
          ,xmld.before_actual_quantity      -- 訂正前実績数量
-- Ver1.3 M.Hokkanji End
          ,xmld.automanual_reserve_class    -- 自動手動引当区分
          ,xmld.created_by                  -- 作成者
          ,xmld.creation_date               -- 作成日
          ,xmld.last_updated_by             -- 最終更新者
          ,xmld.last_update_date            -- 最終更新日
          ,xmld.last_update_login)          -- 最終更新ログイン
        VALUES(
           xxinv_mov_lot_s1.NEXTVAL                    -- ロット詳細ID
          ,lt_line_id                                  -- 明細ID
          ,mov_lot_dtl_rec.document_type_code          -- 文書タイプ
          ,mov_lot_dtl_rec.record_type_code            -- レコードタイプ
          ,mov_lot_dtl_rec.item_id                     -- OPM品目ID
          ,mov_lot_dtl_rec.item_code                   -- 品目
          ,mov_lot_dtl_rec.lot_id                      -- ロットID
          ,mov_lot_dtl_rec.lot_no                      -- ロットNo
          ,mov_lot_dtl_rec.actual_date                 -- 実績日
          ,mov_lot_dtl_rec.actual_quantity             -- 実績数量
-- Ver1.3 M.Hokkanji Start
-- EBSに登録されているデータを打ち消すため実績数量をセット
          ,mov_lot_dtl_rec.actual_quantity             -- 訂正前実績数量
-- Ver1.3 M.Hokkanji End
          ,mov_lot_dtl_rec.automanual_reserve_class    -- 自動手動引当区分
          ,FND_GLOBAL.USER_ID          -- 作成者
          ,SYSDATE                     -- 作成日
          ,FND_GLOBAL.USER_ID          -- 最終更新者
          ,SYSDATE                     -- 最終更新日
          ,FND_GLOBAL.LOGIN_ID         -- 最終更新ログイン
        );
      END LOOP mov_lot_dtl_loop;
    END LOOP order_line_loop;
--
    -- 受注ヘッダアドオンIDを返す。
    RETURN lt_header_id;
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      IF (order_header_cur%ISOPEN) THEN
        CLOSE order_header_cur;
      END IF;
      IF (order_line_cur%ISOPEN) THEN
        CLOSE order_line_cur;
      END IF;
--
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END copy_order_data;
--
END xxwsh_common2_pkg;
/
