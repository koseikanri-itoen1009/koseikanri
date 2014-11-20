CREATE OR REPLACE PACKAGE xxwsh_common910_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh_common910_pkg(spec)
 * Description      : 生産物流共通（出荷・移動チェック）
 * MD.050           : 生産物流共通（出荷・移動チェック）T_MD050_BPO_910
 * MD.070           : なし
 * Version          : 1.37
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  calc_total_value       P         B.積載効率チェック(合計値算出)
 *  calc_load_efficiency   P         C.積載効率チェック(積載効率算出)
 *  check_lot_reversal     P         D.ロット逆転防止チェック
 *  check_lot_reversal2    P         D.ロット逆転防止チェック(依頼No指定あり)
 *  check_fresh_condition  P         E.鮮度条件チェック
 *  get_fresh_pass_date    P         E.鮮度条件合格製造日取得
 *  calc_lead_time         P         F.リードタイム算出
 *  check_shipping_judgment
 *                         P         G.出荷可否チェック
 *
 * Change Record
 * ------------ ----- ---------------- -------------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -------------------------------------------------
 *  2008/03/13   1.0   ORACLE石渡賢和   新規作成
 *  2008/05/19   1.1   ORACLE石渡賢和   メッセージ修正
 *  2008/05/23   1.2   ORACLE北寒寺正夫 鮮度条件チェックのOTHERS例外処理コードを
 *                                      global_api_others_exptに変更
 *                                      鮮度条件チェックの入力パラメータをロットNoから
 *                                      ロットIDに変更
 *  2008/05/24   1.3   ORACLE北寒寺正夫 鮮度条件チェックの鮮度条件区分のエラーチェックに
 *                                      NULLの場合を追加。
 *                                      鮮度条件区分が一般の場合、賞味期限がセットされて
 *                                      いない場合、エラーとするように修正
 *  2008/05/28   1.4   ORACLE石渡賢和   [ロット逆転防止チェック]
 *                                      移動ロット詳細のレコードタイプ値を修正
 *  2008/05/30   1.5   ORACLE椎名昭圭   内部変更要求#116対応
 *  2008/06/02   1.6   ORACLE石渡賢和   [出荷可否チェック] フォーキャストの抽出条件変更
 *                                      [積載効率チェック(積載効率算出)]抽出条件改良
 *  2008/06/13   1.7   ORACLE石渡賢和   [ロット逆転防止チェック] 移動指示の着日条件を変更
 *  2008/06/19   1.8   ORACLE山根一浩   内部変更要求No143対応
 *  2008/06/26   1.9   ORACLE石渡賢和   [出荷可否チェック] 移動指示の着日条件を変更
 *  2008/07/08   1.10  ORACLE椎名昭圭   [出荷可否チェック] ST不具合#405対応
 *  2008/07/14   1.11  ORACLE福田直樹   [積載効率チェック(積載効率算出)] 変更要求対応#95
 *  2008/07/17   1.12  ORACLE福田直樹   [積載効率チェック(積載効率算出)] 変更要求対応#95のバグ対応
 *  2008/07/30   1.13  ORACLE高山洋平   [出荷可否チェック]内部変更要求#182対応
 *  2008/08/04   1.14  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] 変更要求対応#95のバグ対応
 *  2008/08/06   1.14  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] 変更要求対応#164対応
 *  2008/08/22   1.15  ORACLE伊藤ひとみ [出荷可否チェック] PT 2-2_15 指摘20
 *  2008/09/05   1.16  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] PT 6-2_34 指摘#34対応
 *  2008/09/08   1.17  ORACLE椎名昭圭   [ロット逆転防止チェック] PT 6-1_28 指摘#44対応
 *  2008/09/11   1.18  ORACLE椎名昭圭   [ロット逆転防止チェック] PT 6-1_28 指摘#73対応
 *  2008/09/17   1.19  ORACLE椎名昭圭   [ロット逆転防止チェック] PT 6-1_28 指摘#73追加修正
 *  2008/10/06   1.20  ORACLE伊藤ひとみ [積載効率チェック(合計値算出)] 統合テスト指摘240対応 積載効率チェック(合計値算出)基準日ありを追加
 *  2008/10/15   1.21  ORACLE伊藤ひとみ [積載効率チェック(積載効率算出)] 統合テスト指摘298対応
 *  2008/10/15   1.22  ORACLE伊藤ひとみ [鮮度条件チェック] 統合テスト指摘379対応
 *  2008/11/04   1.23  ORACLE伊藤ひとみ [ロット逆転防止チェック] T_S_573対応
 *  2008/11/12   1.24  ORACLE伊藤ひとみ [積載効率チェック(合計値算出)] 統合テスト指摘597対応
 *  2008/11/12   1.25  ORACLE伊藤ひとみ [積載効率チェック(合計値算出)] 統合テスト指摘311対応
 *  2008/12/07   1.26  ORACLE北寒寺正夫 [出荷可否チェック]本番障害#318対応
 *  2008/12/23   1.27  ORACLE北寒寺正夫 [積載効率チェック(合計値算出)] 本番指摘#781対応
 *  2009/01/22   1.28  SCS   伊藤ひとみ [ロット逆転防止チェック(依頼No指定あり)] 本番障害#1000対応
 *  2009/01/23   1.29  SCS   伊藤ひとみ [鮮度条件合格製造日取得] 本番障害#936対応
 *  2009/01/26   1.30  SCS   二瓶大輔   [ロット逆転防止チェック] 本番障害#936対応
 *  2009/03/03   1.31  SCS   風間由紀   [出荷可否チェック] 本番障害#1243対応
 *  2009/03/19   1.32  SCS   飯田甫     [積載効率チェック(合計値算出)] 統合テスト指摘311対応
 *  2009/04/23   1.33  SCS   風間由紀   [リードタイム算出] 本番障害#1398対応
 *  2009/10/15   1.37  SCS   伊藤ひとみ [ロット逆転防止チェック] 本番障害#1661対応
 *****************************************************************************************/
--
-- 2008/10/06 H.Itou Del Start 統合テスト指摘240
--  -- 積載効率チェック(合計値算出)
--  PROCEDURE calc_total_value(
--    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.品目コード
--    in_quantity                   IN  NUMBER,                                              -- 2.数量
--    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.リターンコード
--    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.エラーメッセージコード
--    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.エラーメッセージ
--    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.合計重量
--    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.合計容積
--    on_sum_pallet_weight          OUT NOCOPY NUMBER                                        -- 8.合計パレット重量
--    );
-- 2008/10/06 H.Itou Del End
--
-- 2008/10/06 H.Itou Add Start 統合テスト指摘240基準値あり
  -- 積載効率チェック(合計値算出)
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.品目コード
    in_quantity                   IN  NUMBER,                                              -- 2.数量
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.エラーメッセージ
    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.合計重量
    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.合計容積
    on_sum_pallet_weight          OUT NOCOPY NUMBER,                                       -- 8.合計パレット重量
    id_standard_date              IN  DATE                                                 -- 9.基準日(適用日基準日)
    );
-- 2008/10/06 H.Itou Add End
--
-- 2008/11/12 H.Itou Add Start 統合テスト指摘311 指示/実績区分あり
  -- 積載効率チェック(合計値算出)
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 1.品目コード
    in_quantity                   IN  NUMBER,                                              -- 2.数量
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 3.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 4.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 5.エラーメッセージ
    on_sum_weight                 OUT NOCOPY NUMBER,                                       -- 6.合計重量
    on_sum_capacity               OUT NOCOPY NUMBER,                                       -- 7.合計容積
    on_sum_pallet_weight          OUT NOCOPY NUMBER,                                       -- 8.合計パレット重量
    id_standard_date              IN  DATE,                                                -- 9.基準日(適用日基準日)
    iv_mode                       IN  VARCHAR2                                             -- 10.指示/実績区分 1:指示 2:実績
    );
-- 2008/11/12 H.Itou Add End
--
  -- 積載効率チェック(積載効率算出)
  PROCEDURE calc_load_efficiency(
    in_sum_weight                 IN  NUMBER,                                              -- 1.合計重量
    in_sum_capacity               IN  NUMBER,                                              -- 2.合計容積
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 3.コード区分１
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 4.入出庫場所コード１
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 5.コード区分２
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 6.入出庫場所コード２
    iv_ship_method                IN  xxcmn_ship_methods.ship_method%TYPE,                 -- 7.出荷方法
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 8.商品区分
    iv_auto_process_type          IN  VARCHAR2,                                            -- 9.自動配車対象区分
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 10.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 11.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 12.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 13.エラーメッセージ
    ov_loading_over_class         OUT NOCOPY VARCHAR2,                                     -- 14.積載オーバー区分
    ov_ship_methods               OUT NOCOPY xxcmn_ship_methods.ship_method%TYPE,          -- 15.出荷方法
    on_load_efficiency_weight     OUT NOCOPY NUMBER,                                       -- 16.重量積載効率
    on_load_efficiency_capacity   OUT NOCOPY NUMBER,                                       -- 17.容積積載効率
    ov_mixed_ship_method          OUT NOCOPY VARCHAR2);                                    -- 18.混載配送区分
--
  -- ロット逆転防止チェック
  PROCEDURE check_lot_reversal(
    iv_lot_biz_class              IN  VARCHAR2,                                            -- 1.ロット逆転処理種別
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 2.品目コード
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,                             -- 3.ロットNo
    iv_move_to_id                 IN  NUMBER,                                              -- 4.配送先ID/取引先サイトID/入庫先ID
    iv_arrival_date               IN  DATE,                                                -- 5.着日
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 6.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 7.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 8.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 9.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER,                                       -- 10.処理結果
    on_reversal_date              OUT NOCOPY DATE);                                        -- 11.逆転日付
--
-- 2009/01/22 H.Itou Add Start 本番#1000対応
  -- ロット逆転防止チェック(依頼No指定あり)
  PROCEDURE check_lot_reversal2(
    iv_lot_biz_class              IN  VARCHAR2,                                            -- 1.ロット逆転処理種別
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,                       -- 2.品目コード
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,                             -- 3.ロットNo
    iv_move_to_id                 IN  NUMBER,                                              -- 4.配送先ID/取引先サイトID/入庫先ID
    iv_arrival_date               IN  DATE,                                                -- 5.着日
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 6.基準日(適用日基準日)
    iv_request_no                 IN  xxwsh_order_headers_all.request_no%TYPE,             -- 7.依頼No
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER,                                       -- 11.処理結果
    on_reversal_date              OUT NOCOPY DATE);                                        -- 12.逆転日付
-- 2009/01/22 H.Itou Add End
  -- 鮮度条件チェック
  PROCEDURE check_fresh_condition(
    iv_move_to_id                 IN  NUMBER,                                              -- 1.配送先ID
    iv_lot_id                     IN  ic_lots_mst.lot_id%TYPE,                             -- 2.ロットId
    iv_arrival_date               IN  DATE,                                                -- 3.着荷日
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 4.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 5.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 6.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 7.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER,                                       -- 8.処理結果
    od_standard_date              OUT NOCOPY DATE                                          -- 9.基準日付
  );
--
-- 2009/01/23 H.Itou Add Start 本番#936対応
   -- 鮮度条件合格製造日取得
  PROCEDURE get_fresh_pass_date(
    it_move_to_id                 IN  NUMBER                         -- 1.配送先
   ,it_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE  -- 2.品目コード
   ,id_arrival_date               IN  DATE                           -- 3.着荷予定日
   ,id_standard_date              IN  DATE   DEFAULT SYSDATE         -- 4.基準日(適用日基準日)
   ,od_manufacture_date           OUT NOCOPY DATE                    -- 5.鮮度条件合格製造日
   ,ov_retcode                    OUT NOCOPY VARCHAR2                -- 6.リターンコード
   ,ov_errmsg                     OUT NOCOPY VARCHAR2                -- 8.エラーメッセージ
  );
-- 2009/01/23 H.Itou Add End
--
  -- リードタイム算出
  PROCEDURE calc_lead_time(
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 1.コード区分FROM
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 2.入出庫場所コードFROM
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 3.コード区分TO
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 4.入出庫場所コードTO
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 5.商品区分
    in_transaction_type_id        IN  xxwsh_oe_transaction_types_v.transaction_type_id%type, -- 6.出庫形態ID
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 7.基準日(適用日基準日)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.エラーメッセージ
    on_lead_time                  OUT NOCOPY NUMBER,                                       -- 11.生産物流LT／引取変更LT
    on_delivery_lt                OUT NOCOPY NUMBER                                        -- 12.配送LT
  );
--
  -- 出荷可否チェック
  PROCEDURE check_shipping_judgment(
    iv_check_class                IN  VARCHAR2,                                            -- 1.チェック方法区分
    iv_base_cd                    IN  VARCHAR2,                                            -- 2.拠点CD
    in_item_id                    IN  xxcmn_item_mst_v.inventory_item_id%TYPE,             -- 3.品目ID
    in_amount                     IN  NUMBER,                                              -- 4.数量
    id_date                       IN  DATE,                                                -- 5.対象日付
    in_deliver_from_id            IN  NUMBER,                                              -- 6.出荷元ID
    iv_request_no                 IN  VARCHAR2,                                            -- 7.依頼No
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.リターンコード
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.エラーメッセージコード
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.エラーメッセージ
    on_result                     OUT NOCOPY NUMBER                                        -- 11.処理結果
  );
--
END xxwsh_common910_pkg;
/
