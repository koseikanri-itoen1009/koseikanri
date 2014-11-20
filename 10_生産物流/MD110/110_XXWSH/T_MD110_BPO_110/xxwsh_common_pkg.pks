CREATE OR REPLACE PACKAGE xxwsh_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common_pkg(SPEC)
 * Description            : 共通関数(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.49
 *
 * Program List
 *  ---------------------    ---- ----- --------------------------------------------------
 *   Name                    Type  Ret   Description
 *  ---------------------    ---- ----- --------------------------------------------------
 *  get_max_ship_method       F    NUM   最大配送区分算出関数
 *  get_oprtn_day             F    NUM   稼働日算出関数
 *  get_same_request_number   F    NUM   同一依頼No検索関数
 *  convert_request_number    F    NUM   依頼Noコンバート関数
 *  get_max_pallet_qty        F    NUM   最大パレット枚数算出関数
 *  check_tightening_status   F    NUM   締めステータスチェック関数
 *  update_line_items         F    NUM   重量容積小口個数更新関数
 *  cancel_reserve            F    NUM   引当解除関数
 *  cancel_careers_schedule   F    NUM   配車解除関数
 *  update_mixed_no           F    VAR   混載元No更新関数(出荷依頼画面専用)
 *  convert_mixed_ship_method F    VAR   混載配送区分変換関数
 *  chk_sourcing_rules        F    VAR   物流構成存在チェック関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/02/01   1.0   Oracle 椎名昭圭  新規作成
 *  2008/05/16   1.1   Oracle 椎名昭圭  [配車解除関数]3.配車解除可否チェック(移動)の
 *                                      変数gt_chk_move_tblの変数名違いを修正
 *  2008/05/20   1.2   Oracle 石渡賢和  [依頼Noコンバート関数]
 *                                      標準のテーブルをアドオンViewに変更
 *  2008/05/21   1.3   Oracle 椎名昭圭  内部変更要求#111対応
 *  2008/05/23   1.4   Oracle 石渡賢和  [同一依頼No検索関数]
 *  2008/05/29   1.5   Oracle 椎名昭圭  [重量容積小口個数更新関数]複数の明細に対応
 *  2008/06/03   1.6   Oracle 北寒寺正夫 [配車解除関数]440不具合ログ#45対応
 *                                       実績計上済もしくは実績数量が入力されている場合は
 *                                       関連項目更新処理を実行せず正常終了するように修正
 *  2008/06/03   1.7   Oracle 上原正好  内部変更要求#80対応[締めステータスチェック関数]
 *                                      パラメータ「拠点」の追加 検索条件修正
 *  2008/06/03   1.8   Oracle 上原正好  [配車解除関数]440不具合ログ#44対応
 *                                      有償支給の'出荷実績計上済'ステータスを'08'に修正
 *  2008/06/04   1.9   Oracle 山本恭久  [重量容積小口個数更新関数]440不具合ログ#61対応
 *  2008/06/26   1.10  Oracle 北寒寺正夫 エラー時のメッセージにSQLERRMを追加
 *  2008/06/27   1.11  Oracle 椎名昭圭  [引当解除関数]業務種別移動の場合、
 *                                      明細に紐付く複数ロットに対応
 *  2008/06/30   1.12  Oracle 椎名昭圭  [最大配送区分算出関数]最大配送区分抽出時の条件修正
 *  2008/07/02   1.13  Oracle 福田直樹  [締めステータスチェック関数]拠点・拠点カテゴリ共に未入力時、
 *                                      初回締め処理判定不正の対応(ST不具合対応#366)
 *  2008/07/04   1.13  Oracle 北寒寺正夫[締めステータスチェック関数]拠点カテゴリ=0をALLとして
 *                                      扱うように修正。
 *                                      ST#320不具合対応
 *  2008/07/09   1.14  Oracle 熊本和郎  [重量容積小口個数更新関数] ST障害#430対応
 *  2008/07/11   1.15  Oracle 福田直樹  [最大配送区分算出関数]変更要求対応#95
 *  2008/07/11   1.16  Oracle 福田直樹  [最大パレット枚数算出関数]変更要求対応#95
 *  2008/08/04   1.17  Oracle 伊藤ひとみ[最大配送区分算出関数][最大パレット枚数算出関数]
 *                                       コード区分2 = 4,11の場合、入出庫場所コード2 = ZZZZで検索する。
 *  2008/08/07   1.18  Oracle 伊藤ひとみ[重量容積小口個数更新関数]
 *                                       内部課題#32   小口個数･･･出荷入数 > 0の場合に出荷入数で計算するように変更
 *                                       変更要求#166  小口個数･･･明細単位で切り上げて集計するように変更
 *                                       変更要求##173 重量積載効率/容積積載効率･･･運賃区分「1」の時、無条件で取得するように変更
 *                                                     運賃区分「1」の時･･･重量積載効率/容積積載効率  処理で取得した値に更新
 *                                                     運賃区分「1」でない時･･･重量積載効率/容積積載効率/基本重量/基本容積/配送区分 NULLに更新
 *                                                     常に更新･･･積載重量合計/積載容積合計/パレット合計枚数/小口個数
 *  2008/08/11   1.19  Oracle 伊藤ひとみ[同一依頼No検索関数]変更要求#174 実績計上済区分Yのデータが1件もない場合は、エラーを返す。
 *  2008/08/20   1.20  Oracle 北寒寺正夫[配車解除関数] T_3_569対応   各ヘッダに最大配送区分、基本重量、基本容積を設定するように変更
 *                                                     TE_080_400指摘No77対応 受注ヘッダの混載元Noをクリアしないように変更
 *                                                     開発気づき対応 拠点配車が正しく解除されない問題を修正
 *                                                                    領域またいで混載した場合に正しく解除されない問題を修正
 *                                                                    配車解除時のエラーメッセージが正しく出力されない問題を修正
 *  2008/08/28   1.21  Oracle 伊藤ひとみ[配車解除関数] PT 1-2_8 指摘#32対応
 *  2008/09/02   1.22  Oracle 北寒寺正夫[配車解除関数] 統合テスト環境不具合対応
 *  2008/09/03   1.23  Oracle 河野優子  [引当解除関数] 統合テスト不具合対応 移動：複数明細・複数ロット解除対応
 *  2008/09/03   1.24  Oracle 伊藤ひとみ[配車解除関数] PT 1-2_8 指摘#59対応
 *  2008/09/17   1.25  Oracle 北寒寺正夫[混載元No更新関数] T_TE080_BPO_400指摘77により出荷依頼画面で使用するため新規追加
 *                                                         ※FORMSではON_UPDATE以外でUPDATE文を発行できないため外出し
 *  2008/10/06   1.26  Oracle 伊藤ひとみ[重量容積小口個数更新関数] 統合テスト指摘240対応 積載効率チェック(合計値算出)にパラメータ.基準日追加
 *  2008/10/15   1.27  Oracle 伊藤ひとみ[混載配送区分変換関数][最大パレット枚数算出関数] 統合テスト指摘298対応
 *  2008/10/23   1.28  Oracle 二瓶大輔  [配車解除関数] TE080_BPO_600 No22対応
 *  2008/11/13   1.29  Oracle 伊藤ひとみ[重量容積小口個数更新関数] 統合テスト指摘311対応
 *  2008/11/25   1.30  Oracle 北寒寺正夫[配車解除関数] 本番障害#84対応
 *  2008/11/27   1.31  Oracle 椎名昭圭  [依頼Noコンバート関数] 本番障害#179対応
 *  2008/12/02   1.32  Oracle 野村正幸  本番#318対応
 *  2008/12/13   1.33  Oracle 二瓶大輔  本番#568対応(配車解除関数ログ出力追加)
 *  2008/12/15   1.34  Oracle 伊藤ひとみ[重量容積小口個数関数]メッセージ格納変数の桁を増やす対応
 *  2008/12/16   1.35  Oracle 二瓶大輔  本番#568対応(配車解除関数変数定義修正)
 *  2008/12/16   1.36  SCS    菅原大輔  本番#744対応(パレット重量計算不正)
 *  2008/12/25   1.37  SCS    北寒寺正夫本番#790対応(重量容積小口個数更新関数(小口個数NULL対応)
 *  2009/01/08   1.38  SCS    伊藤ひとみ[物流構成存在チェック関数]本番#894対応
 *  2009/01/14   1.39  SCS    山本恭久  [引当解除関数]本番#991対応
 *  2009/01/21   1.40  SCS    伊藤ひとみ[締めステータスチェック関数]本番#1053対応
 *  2009/01/27   1.41  SCS    北寒寺正夫[締めステータスチェック関数]本番#1089対応
 *  2009/02/10   1.42  SCS    伊藤ひとみ[配車解除関数]本番#863対応
 *  2009/02/20   1.43  SCS    二瓶大輔  [配車解除関数]本番#863対応(混載対応)
 *                                      [配車解除関数]本番#1034対応
 *                                      [配車解除関数]本番#1210対応
 *  2009/02/27   1.44  SCS    伊藤ひとみ[配車解除関数]本番#863対応(再対応)
 *  2009/03/04   1.45  SCS    北寒寺正夫[配車解除関数]本番#1268対応
 *  2009/03/05   1.46  SCS    北寒寺正夫[重量容積小口個数更新関数]本番#1068対応
 *  2009/05/07   1.47  SCS    伊藤ひとみ[引当解除関数]本番#1443対応 減数チェックエラー時も引当を解除する。
 *  2009/06/25   1.48  SCS    伊藤ひとみ[稼働日算出関数]本番#1463対応 日付＋LTも算出できるよう変更
 *  2009/08/18   1.49  SCS    伊藤ひとみ[配車解除関数]本番#1581対応(営業システム:特別横持マスタ対応)
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
  -- ===============================
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- 最大配送区分算出関数
  FUNCTION get_max_ship_method(
    -- 1.コード区分１
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,
    -- 2.入出庫場所コード１
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,
    -- 3.コード区分２
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,
    -- 4.入出庫場所コード２
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,
    -- 5.商品区分
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,
    -- 6.重量容積区分
    iv_weight_capacity_class      IN  VARCHAR2,
    -- 7.自動配車対象区分
    iv_auto_process_type          IN  VARCHAR2,
    -- 8.基準日(適用日基準日)
    id_standard_date              IN  DATE,
    -- 9.最大配送区分
    ov_max_ship_methods           OUT xxcmn_ship_methods.ship_method%TYPE,
    -- 10.ドリンク積載重量
    on_drink_deadweight           OUT xxcmn_ship_methods.drink_deadweight%TYPE,
    -- 11.リーフ積載重量
    on_leaf_deadweight            OUT xxcmn_ship_methods.leaf_deadweight%TYPE,
    -- 12.ドリンク積載容積
    on_drink_loading_capacity     OUT xxcmn_ship_methods.drink_loading_capacity%TYPE,
    -- 13.リーフ積載容積
    on_leaf_loading_capacity      OUT xxcmn_ship_methods.leaf_loading_capacity%TYPE,
    -- 14.パレット最大枚数
    on_palette_max_qty            OUT xxcmn_ship_methods.palette_max_qty%TYPE)
    RETURN NUMBER;
--
-- 2009/06/25 H.Itou Add Start 本番障害#1463対応 日付＋LTも算出できるよう変更
  -- 稼働日算出関数
  FUNCTION get_oprtn_day(
    id_date             IN  DATE,         -- 日付
    iv_whse_code        IN  VARCHAR2,     -- 保管倉庫コード
    iv_deliver_to_code  IN  VARCHAR2,     -- 配送先コード
    in_lead_time        IN  NUMBER,       -- リードタイム
    iv_prod_class       IN  VARCHAR2,     -- 商品区分
    od_oprtn_day        OUT NOCOPY DATE,  -- 稼働日日付
    in_type             IN  NUMBER        -- -1:日付－LT, 1:日付＋LT
    )
    RETURN NUMBER;
-- 2009/06/25 H.Itou Add End
--
  -- 稼働日算出関数
  FUNCTION get_oprtn_day(
    id_date             IN  DATE,         -- 日付
    iv_whse_code        IN  VARCHAR2,     -- 保管倉庫コード
    iv_deliver_to_code  IN  VARCHAR2,     -- 配送先コード
    in_lead_time        IN  NUMBER,       -- リードタイム
    iv_prod_class       IN  VARCHAR2,     -- 商品区分
    od_oprtn_day        OUT NOCOPY DATE)  -- 稼働日日付
    RETURN NUMBER;
--
  -- 同一依頼No検索関数
  FUNCTION get_same_request_number(
    iv_request_no          IN  xxwsh_order_headers_all.request_no%TYPE,       -- 1.依頼No
    on_same_request_count  OUT NUMBER,                                        -- 2.同一依頼No件数
    on_order_header_id     OUT xxwsh_order_headers_all.ORDER_HEADER_ID%TYPE)  -- 3.同一依頼Noの受注ヘッダアドオンID
    RETURN NUMBER;
--
  -- 依頼Noコンバート関数
  FUNCTION convert_request_number(
    iv_conv_div             IN  VARCHAR2,                                     -- 1.変換区分
    iv_pre_conv_request_no  IN  VARCHAR2,                                     -- 2.変換前依頼No
    ov_aft_conv_request_no  OUT xxwsh_order_headers_all.request_no%TYPE)      -- 3.変換後依頼No
    RETURN NUMBER;
--
  -- 最大パレット枚数算出関数
  FUNCTION get_max_pallet_qty(
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 1.コード区分１
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 2.入出庫場所コード１
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 3.コード区分２
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 4.入出庫場所コード２
    id_standard_date              IN  DATE,                                                -- 5.基準日(適用日基準日)
    iv_ship_methods               IN  xxcmn_ship_methods.ship_method%TYPE,                 -- 6.配送区分
    on_drink_deadweight           OUT xxcmn_ship_methods.drink_deadweight%TYPE,            -- 7.ドリンク積載重量
    on_leaf_deadweight            OUT xxcmn_ship_methods.leaf_deadweight%TYPE,             -- 8.リーフ積載重量
    on_drink_loading_capacity     OUT xxcmn_ship_methods.drink_loading_capacity%TYPE,      -- 9.ドリンク積載容積
    on_leaf_loading_capacity      OUT xxcmn_ship_methods.leaf_loading_capacity%TYPE,       -- 10.リーフ積載容積
    on_palette_max_qty            OUT xxcmn_ship_methods.palette_max_qty%TYPE)             -- 11.パレット最大枚数
    RETURN NUMBER;
--
  -- 締めステータスチェック関数
  FUNCTION check_tightening_status(
    -- 1.受注タイプID
    in_order_type_id          IN  xxwsh_tightening_control.order_type_id%TYPE,
    -- 2.出荷元保管場所
    iv_deliver_from           IN  xxwsh_tightening_control.deliver_from%TYPE,
    -- 3.拠点
    iv_sales_branch           IN  xxwsh_tightening_control.sales_branch%TYPE,
    -- 4.拠点カテゴリ
    iv_sales_branch_category  IN  xxwsh_tightening_control.sales_branch_category%TYPE,
    -- 5.生産物流LT
    in_lead_time_day          IN  xxwsh_tightening_control.lead_time_day%TYPE,
    -- 6.出庫日
    id_ship_date              IN  xxwsh_tightening_control.schedule_ship_date%TYPE,
    -- 7.商品区分
    iv_prod_class             IN  xxwsh_tightening_control.prod_class%TYPE)
    RETURN VARCHAR2;
--
  -- 重量容積小口個数更新関数
  FUNCTION update_line_items(
    iv_biz_type             IN  VARCHAR2,                                     -- 1.業務種別
    iv_request_no           IN  VARCHAR2)                                     -- 2.依頼No/移動番号
    RETURN NUMBER;
--
  -- 引当解除関数
  FUNCTION cancel_reserve(
    iv_biz_type             IN         VARCHAR2,                              -- 1.業務種別
    iv_request_no           IN         VARCHAR2,                              -- 2.依頼No/移動番号
    in_line_id              IN         NUMBER,                                -- 3.明細ID
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 4.エラーメッセージ
    RETURN VARCHAR2;
--
-- 2008/10/23 v1.28 D.Nihei Del Start TE_080_600 No22(対応完了後削除予定)
  -- 配車解除関数
  FUNCTION cancel_careers_schedule(
    iv_biz_type             IN         VARCHAR2,                              -- 1.業務種別
    iv_request_no           IN         VARCHAR2,                              -- 2.依頼No/移動番号
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 3.エラーメッセージ
    RETURN VARCHAR2;
-- 2008/10/23 v1.28 D.Nihei Del End
  -- 配車解除関数
  FUNCTION cancel_careers_schedule(
    iv_biz_type             IN         VARCHAR2,                              -- 1.業務種別
    iv_request_no           IN         VARCHAR2,                              -- 2.依頼No/移動番号
-- 2008/10/23 v1.28 D.Nihei Add Start TE_080_600 No22
    iv_calcel_flag          IN         VARCHAR2,                              -- 3.配車解除フラグ 1:解除、0:通知ステータス更新のみ
-- 2008/10/23 v1.28 D.Nihei Add End
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 4.エラーメッセージ
    RETURN VARCHAR2;
-- Ver1.25 M.Hokkanji Start
  -- 混載元No更新関数
  FUNCTION update_mixed_no(
    iv_mixed_no             IN         VARCHAR2,
    ov_errmsg               OUT NOCOPY VARCHAR2)
    RETURN VARCHAR2;
-- Ver1.25 M.Hokkanji End
--
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
  -- 混載配送区分変換関数
  FUNCTION convert_mixed_ship_method(
    it_ship_method_code IN  xxwsh_ship_method_v.ship_method_code%TYPE -- 配送区分コード
  ) RETURN xxwsh_ship_method_v.ship_method_code%TYPE;                 -- 配送区分コード（混載なし）
-- 2008/10/15 H.Itou Add End
--
-- 2009/01/08 H.Itou Add Start 本番障害#894
  -- 物流構成存在チェック関数
  FUNCTION chk_sourcing_rules(
    it_item_code          IN  xxcmn_sourcing_rules.item_code%TYPE          -- 1.品目コード
   ,it_base_code          IN  xxcmn_sourcing_rules.base_code%TYPE          -- 2.管轄拠点
   ,it_ship_to_code       IN  xxcmn_sourcing_rules.ship_to_code%TYPE       -- 3.配送先
   ,it_delivery_whse_code IN  xxcmn_sourcing_rules.delivery_whse_code%TYPE -- 4.出庫倉庫
   ,id_standard_date      IN  DATE                                         -- 5.基準日(適用日基準日)
  ) RETURN VARCHAR2;
-- 2009/01/08 H.Itou Add End
--
END xxwsh_common_pkg;
/
