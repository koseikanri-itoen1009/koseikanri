CREATE OR REPLACE PACKAGE BODY xxwsh_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwsh_common_pkg(BODY)
 * Description            : 共通関数(BODY)
 * MD.070(CMD.050)        : なし
 * Version                : 1.50
 *
 * Program List
 *  ----------------------   ---- ----- --------------------------------------------------
 *   Name                    Type  Ret   Description
 *  ----------------------   ---- ----- --------------------------------------------------
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
 *  convert_mixed_ship_method F    VAR   混載配送区分変換関数                -- 2008/10/15 H.Itou Add 統合テスト指摘298
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
 *  2008/08/20   1.20  Oracle 北寒寺正夫[配車解除関数] T_3_569対応   運賃区分設定時に各ヘッダに最大配送区分、基本重量、基本容積を設定するように変更
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
 *  2008/11/13   1.29  SCS    伊藤ひとみ[重量容積小口個数更新関数] 統合テスト指摘311対応
 *  2008/11/25   1.30  SCS    北寒寺正夫[配車解除関数] 本番障害#84対応
 *  2008/11/27   1.31  SCS    椎名昭圭  [依頼Noコンバート関数] 本番障害#179対応
 *  2008/12/02   1.32  SCS    野村正幸  本番#318対応
 *  2008/12/13   1.33  SCS    二瓶大輔  本番#568対応(配車解除関数ログ出力追加)
 *  2008/12/15   1.34  SCS    伊藤ひとみ[重量容積小口個数関数]メッセージ格納変数の桁を増やす対応
 *  2008/12/16   1.35  SCS    二瓶大輔  本番#568対応(配車解除関数変数定義修正)
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
 *  2012/07/18   1.50  SCSK   菅原大輔  E_本稼動_09810対応
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
  no_data                   EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gn_status_normal CONSTANT NUMBER := 0;
  gn_status_error  CONSTANT NUMBER := 1;
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common_pkg'; -- パッケージ名
--
--add start 1.14
  gv_freight_charge_yes CONSTANT VARCHAR2(1) := '1';
--add end 1.14
-- 2008/08/04 Add H.Itou Start
  -- コード区分
  code_class_whse       CONSTANT VARCHAR2(10) := '4';  -- 倉庫
  code_class_ship       CONSTANT VARCHAR2(10) := '9';  -- 出荷
  code_class_supply     CONSTANT VARCHAR2(10) := '11'; -- 支給
-- 2008/08/04 Add H.Itou End
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
  -- 特別横持更新関数
  gv_process_type_plus        CONSTANT VARCHAR2(2) :=  '0';    -- 処理区分 0：加算
  gv_process_type_minus       CONSTANT VARCHAR2(2) :=  '1';    -- 処理区分 1：減算
-- 2009/08/18 H.Itou Add End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 移動依頼/指示のレコード型
  TYPE mov_req_instr_rec IS RECORD(
    mov_line_id             xxinv_mov_req_instr_lines.mov_line_id%TYPE,
    ship_to_locat_id        xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE,
    schedule_arrival_date   xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE,
    item_short_name         xxcmn_item_mst2_v.item_short_name%TYPE,
    description             mtl_item_locations.description%TYPE
  );
  -- 配車解除可否チェック(出荷)のレコード型
  TYPE chk_ship_rec IS RECORD(
    order_header_id   xxwsh_order_headers_all.order_header_id%TYPE,
    req_status        xxwsh_order_headers_all.req_status%TYPE,
    request_no        xxwsh_order_headers_all.request_no%TYPE,
    notif_status      xxwsh_order_headers_all.notif_status%TYPE,
    prev_notif_status xxwsh_order_headers_all.prev_notif_status%TYPE,
    shipped_quantity  xxwsh_order_lines_all.shipped_quantity%TYPE,
    ship_to_quantity  xxwsh_order_lines_all.ship_to_quantity%TYPE,
-- Ver1.20 M.Hokkanji START
    shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE,
    prod_class                  xxwsh_order_headers_all.prod_class%TYPE,
    based_weight                xxwsh_order_headers_all.based_weight%TYPE,
    based_capacity              xxwsh_order_headers_all.based_capacity%TYPE,
    weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class%TYPE,
    deliver_from                xxwsh_order_headers_all.deliver_from%TYPE,
    deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE,
    schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE,
    sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE,
    sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE,
    sum_pallet_weight           xxwsh_order_headers_all.sum_pallet_weight%TYPE,
    freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE,
    loading_efficiency_weight   xxwsh_order_headers_all.loading_efficiency_weight%TYPE,
    loading_efficiency_capacity xxwsh_order_headers_all.loading_efficiency_capacity%TYPE
-- Ver1.20 M.Hokkanji END
  );
  -- 配車解除可否チェック(支給)のレコード型
  TYPE chk_supply_rec IS RECORD(
    order_header_id   xxwsh_order_headers_all.order_header_id%TYPE,
    req_status        xxwsh_order_headers_all.req_status%TYPE,
    request_no        xxwsh_order_headers_all.request_no%TYPE,
    notif_status      xxwsh_order_headers_all.notif_status%TYPE,
    prev_notif_status xxwsh_order_headers_all.prev_notif_status%TYPE,
    shipped_quantity  xxwsh_order_lines_all.shipped_quantity%TYPE,
    ship_to_quantity  xxwsh_order_lines_all.ship_to_quantity%TYPE,
-- Ver1.20 M.Hokkanji START
    shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE,
    prod_class                  xxwsh_order_headers_all.prod_class%TYPE,
    based_weight                xxwsh_order_headers_all.based_weight%TYPE,
    based_capacity              xxwsh_order_headers_all.based_capacity%TYPE,
    weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class%TYPE,
    deliver_from                xxwsh_order_headers_all.deliver_from%TYPE,
    vendor_site_code            xxwsh_order_headers_all.vendor_site_code%TYPE,
    schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE,
    sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE,
    sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE,
    freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE,
    loading_efficiency_weight   xxwsh_order_headers_all.loading_efficiency_weight%TYPE,
    loading_efficiency_capacity xxwsh_order_headers_all.loading_efficiency_capacity%TYPE
-- Ver1.20 M.Hokkanji END
  );
  -- 配車解除可否チェック(移動)のレコード型
  TYPE chk_move_rec IS RECORD(
    mov_hdr_id                    xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,
    status                        xxinv_mov_req_instr_headers.status%TYPE,
    mov_num                       xxinv_mov_req_instr_headers.mov_num%TYPE,
    notif_status                  xxinv_mov_req_instr_headers.notif_status%TYPE,
    prev_notif_status             xxinv_mov_req_instr_headers.prev_notif_status%TYPE,
    shipped_quantity              xxinv_mov_req_instr_lines.shipped_quantity%TYPE,
    ship_to_quantity              xxinv_mov_req_instr_lines.ship_to_quantity%TYPE,
-- Ver1.20 M.Hokkanji START
    shipping_method_code          xxinv_mov_req_instr_headers.shipping_method_code%TYPE,
    item_class                    xxinv_mov_req_instr_headers.item_class%TYPE,
    based_weight                  xxinv_mov_req_instr_headers.based_weight%TYPE,
    based_capacity                xxinv_mov_req_instr_headers.based_capacity%TYPE,
    weight_capacity_class         xxinv_mov_req_instr_headers.weight_capacity_class%TYPE,
    shipped_locat_code            xxinv_mov_req_instr_headers.shipped_locat_code%TYPE,
    ship_to_locat_code            xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE,
    schedule_ship_date            xxinv_mov_req_instr_headers.schedule_ship_date%TYPE,
    sum_weight                    xxinv_mov_req_instr_headers.sum_weight%TYPE,
    sum_capacity                  xxinv_mov_req_instr_headers.sum_capacity%TYPE,
    sum_pallet_weight             xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE,
    freight_charge_class          xxinv_mov_req_instr_headers.freight_charge_class%TYPE,
    loading_efficiency_weight     xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE,
    loading_efficiency_capacity   xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE
-- Ver1.20 M.Hokkanji END
  );
  -- 重量容積小口個数更新(出荷)のレコード型
  TYPE ship_rec IS RECORD(
    shipped_quantity    xxwsh_order_lines_all.shipped_quantity%TYPE,
    shipping_item_code  xxwsh_order_lines_all.shipping_item_code%TYPE,
    conv_unit           xxcmn_item_mst_v.conv_unit%TYPE,
    num_of_cases        xxcmn_item_mst_v.num_of_cases%TYPE,
    num_of_deliver      xxcmn_item_mst_v.num_of_deliver%TYPE,
    order_line_id       xxwsh_order_lines_all.order_line_id%TYPE
  );
  -- 重量容積小口個数更新(支給)のレコード型
  TYPE supply_rec IS RECORD(
    shipping_item_code  xxwsh_order_lines_all.shipping_item_code%TYPE,
    shipped_quantity    xxwsh_order_lines_all.shipped_quantity%TYPE,
    order_line_id       xxwsh_order_lines_all.order_line_id%TYPE
  );
  -- 重量容積小口個数更新(移動)のレコード型
  TYPE move_rec IS RECORD(
    shipped_quantity    xxinv_mov_req_instr_lines.shipped_quantity%TYPE,
    item_code           xxinv_mov_req_instr_lines.item_code%TYPE,
    conv_unit           xxcmn_item_mst_v.conv_unit%TYPE,
    num_of_cases        xxcmn_item_mst_v.num_of_cases%TYPE,
    num_of_deliver      xxcmn_item_mst_v.num_of_deliver%TYPE,
    mov_line_id         xxinv_mov_req_instr_lines.mov_line_id%TYPE
  );
  -- 明細更新項目のレコード型
  TYPE update_rec IS RECORD(
    update_weight                 NUMBER,
    update_capacity               NUMBER,
    update_pallet_weight          NUMBER,
    update_line_id                NUMBER
  );
--
  -- 移動依頼/指示のテーブル型
  TYPE mov_req_instr_tbl IS
    TABLE OF mov_req_instr_rec INDEX BY PLS_INTEGER;
  -- 受注明細アドオンID
  TYPE order_line_id_tbl IS
    TABLE OF xxwsh_order_lines_all.order_line_id%TYPE INDEX BY PLS_INTEGER;
  -- 移動明細ID
  TYPE mov_line_id_tbl IS
    TABLE OF xxinv_mov_req_instr_lines.mov_line_id%TYPE INDEX BY PLS_INTEGER;
  -- 入庫先ID
  TYPE ship_to_locat_id_tbl IS
    TABLE OF xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE INDEX BY PLS_INTEGER;
  -- 実績数量
  TYPE schedule_arrival_date_tbl IS
    TABLE OF xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE INDEX BY PLS_INTEGER;
  -- 品名・略称
  TYPE item_short_name_tbl IS
    TABLE OF xxcmn_item_mst2_v.item_short_name%TYPE INDEX BY PLS_INTEGER;
  -- 保管場所名
  TYPE description_tbl IS
    TABLE OF mtl_item_locations.description%TYPE INDEX BY PLS_INTEGER;
  -- ロット詳細ID
  TYPE mov_lot_dtl_id_tbl IS
    TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY PLS_INTEGER;
  -- ロットID
  TYPE lot_id_tbl IS
    TABLE OF xxinv_mov_lot_details.lot_id%TYPE INDEX BY PLS_INTEGER;
  -- OPM品目ID
  TYPE item_id_tbl IS
    TABLE OF xxinv_mov_lot_details.item_id%TYPE INDEX BY PLS_INTEGER;
  -- 実績数量
  TYPE actual_quantity_tbl IS
    TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY PLS_INTEGER;
  -- ロットNo
  TYPE lot_no_tbl IS
    TABLE OF xxinv_mov_lot_details.lot_no%TYPE INDEX BY PLS_INTEGER;
--
  -- 配車解除可否チェック(出荷)
  TYPE chk_ship_tbl IS
    TABLE OF chk_ship_rec INDEX BY PLS_INTEGER;
--
  -- 配車解除可否チェック(支給)
  TYPE chk_supply_tbl IS
    TABLE OF chk_supply_rec INDEX BY PLS_INTEGER;
--
  -- 配車解除可否チェック(移動)
  TYPE chk_move_tbl IS
    TABLE OF chk_move_rec INDEX BY PLS_INTEGER;
--
  -- 重量容積小口個数更新(出荷)のテーブル型
  TYPE get_ship_tbl IS
    TABLE OF ship_rec INDEX BY PLS_INTEGER;
--
  -- 重量容積小口個数更新(支給)のテーブル型
  TYPE get_supply_tbl IS
    TABLE OF supply_rec INDEX BY PLS_INTEGER;
--
  -- 重量容積小口個数更新(移動)のテーブル型
  TYPE get_move_tbl IS
    TABLE OF move_rec INDEX BY PLS_INTEGER;
--
  -- 明細更新項目のテーブル型
  TYPE get_update_tbl IS
    TABLE OF update_rec INDEX BY PLS_INTEGER;
-- Ver1.25 M.Hokkanji Start
  -- 受注明細アドオンID
  TYPE order_header_id_tbl IS
    TABLE OF xxwsh_order_headers_all.order_header_id%TYPE INDEX BY PLS_INTEGER;
-- Ver1.25 M.Hokkanji End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_mov_req_instr_tbl            mov_req_instr_tbl;         -- 移動依頼/指示の結合配列
  gt_order_line_id_tbl            order_line_id_tbl;         -- 受注明細アドオンID
-- Ver1.25 M.Hokkanji Start
  gt_order_header_id_tbl          order_header_id_tbl;       -- 受注ヘッダID
-- Ver1.25 M.Hokkanji End
--2008/09/03 Y.Kawano DEL Start
--  gt_mov_line_id_tbl              mov_line_id_tbl;           -- 移動明細ID
--  gt_ship_to_locat_id_tbl         ship_to_locat_id_tbl;      -- 入庫先ID
--  gt_schedule_arrival_date_tbl    schedule_arrival_date_tbl; -- 入庫予定日
--  gt_item_short_name_tbl          item_short_name_tbl;       -- 摘要
--  gt_description_tbl              description_tbl;           -- 保管場所
--2008/09/03 Y.Kawano DEL End
  gt_mov_lot_dtl_id_tbl           mov_lot_dtl_id_tbl;        -- ロット詳細ID
  gt_lot_id_tbl                   lot_id_tbl;                -- ロットID
  gt_item_id_tbl                  item_id_tbl;               -- OPM品目ID
  gt_actual_quantity_tbl          actual_quantity_tbl;       -- 実績数量
  gt_lot_no_tbl                   lot_no_tbl;                -- ロットNo
-- 2008/12/15 D.Nihei Del Start 配車解除関数へ移動
--  gt_chk_ship_tbl                 chk_ship_tbl;              -- 配車解除可否チェック(出荷)
--  gt_chk_supply_tbl               chk_supply_tbl;            -- 配車解除可否チェック(支給)
--  gt_chk_move_tbl                 chk_move_tbl;              -- 配車解除可否チェック(移動)
-- 2008/12/15 D.Nihei Del End
--
  /**********************************************************************************
   * Function Name    : get_max_ship_method
   * Description      : 最大配送区分算出関数
   ***********************************************************************************/
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
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'get_max_ship_method';    --プログラム名
    cv_object                 CONSTANT VARCHAR2(1)   := '1';                      --対象
    cv_leaf                   CONSTANT VARCHAR2(1)   := '1';                      --リーフ
    cv_drink                  CONSTANT VARCHAR2(1)   := '2';                      --ドリンク
    cv_weight                 CONSTANT VARCHAR2(1)   := '1';                      --重量
    cv_capacity               CONSTANT VARCHAR2(1)   := '2';                      --容積
    cv_deliver_to             CONSTANT VARCHAR2(1)   := '9';                      --配送先
    cv_base                   CONSTANT VARCHAR2(1)   := '1';                      --拠点
    cv_all_4                  CONSTANT VARCHAR2(4)   := 'ZZZZ';                   --2008/07/11 変更要求対応#95
    cv_all_9                  CONSTANT VARCHAR2(9)   := 'ZZZZZZZZZ';              --2008/07/11 変更要求対応#95
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_standard_date      DATE;                                                   --基準日
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 必須入力パラメータチェック
    IF ((iv_code_class1                 IS NULL) OR
         (iv_entering_despatching_code1 IS NULL) OR
         (iv_code_class2                IS NULL) OR
         (iv_entering_despatching_code2 IS NULL) OR
         ((iv_prod_class                IS NULL) OR
           (iv_prod_class               NOT IN (cv_leaf, cv_drink))) OR
         ((iv_weight_capacity_class     IS NULL) OR
           (iv_weight_capacity_class    NOT IN (cv_weight, cv_capacity))) OR
         ((iv_auto_process_type         IS NOT NULL) AND
           (iv_auto_process_type        <> cv_object))) THEN
      RETURN gn_status_error;
    END IF;
--
    -- 「基準日(適用日基準日)」が指定されない場合はシステム日付
    IF ( id_standard_date IS NULL) THEN
      ld_standard_date := TRUNC(SYSDATE);
    ELSE
      ld_standard_date := TRUNC(id_standard_date);
    END IF;
--
    -------- 1. 倉庫(個別コード)－配送先(個別コード) -------------------
    BEGIN
      SELECT xdlv2.ship_method,
             xdlv2.drink_deadweight,
             xdlv2.leaf_deadweight,
             xdlv2.drink_loading_capacity,
             xdlv2.leaf_loading_capacity,
             xdlv2.palette_max_qty
      INTO   ov_max_ship_methods,
             on_drink_deadweight,
             on_leaf_deadweight,
             on_drink_loading_capacity,
             on_leaf_loading_capacity,
             on_palette_max_qty
      FROM   (SELECT xdlv2.ship_methods_id,
                     MAX(xdlv2.ship_method)
                       OVER(PARTITION BY
                         xdlv2.code_class1,
                         xdlv2.entering_despatching_code1,
                         xdlv2.code_class2,
                         xdlv2.entering_despatching_code2
                       ) max_ship
             FROM    xxcmn_delivery_lt2_v xdlv2,
                     xxwsh_ship_method2_v xsmv2
             WHERE   (CASE
                       -- ドリンク積載重量
                       WHEN ((iv_prod_class             =  cv_drink) AND
                              (iv_weight_capacity_class =  cv_weight)) THEN
                         xdlv2.drink_deadweight
                       -- リーフ積載重量
                       WHEN ((iv_prod_class             =  cv_leaf) AND
                              (iv_weight_capacity_class =  cv_weight)) THEN
                         xdlv2.leaf_deadweight
                       -- ドリンク積載容積
                       WHEN ((iv_prod_class             =  cv_drink) AND
                              (iv_weight_capacity_class =  cv_capacity)) THEN
                         xdlv2.drink_loading_capacity
                       -- リーフ積載容積
                       WHEN ((iv_prod_class             =  cv_leaf) AND
                              (iv_weight_capacity_class =  cv_capacity)) THEN
                         xdlv2.leaf_loading_capacity
                     END) > 0
             -- コード区分１
             AND     xdlv2.code_class1                  =  iv_code_class1
             -- 入出庫場所コード１
             AND     xdlv2.entering_despatching_code1   =  iv_entering_despatching_code1  --個別
             -- コード区分２
             AND     xdlv2.code_class2                  =  iv_code_class2
             -- 入出庫場所コード２
             AND     xdlv2.entering_despatching_code2   =  iv_entering_despatching_code2  --個別
             -- 適用開始日(配送L/T)
             AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                       (xdlv2.lt_start_date_active      IS NULL))
             -- 適用終了日(配送L/T)
             AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                       (xdlv2.lt_end_date_active        IS NULL))
             -- 適用開始日(出荷方法)
             AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                       (xdlv2.sm_start_date_active      IS NULL))
             -- 適用終了日(出荷方法)
             AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                       (xdlv2.sm_end_date_active        IS NULL))
             -- 混載区分
             AND     ((xsmv2.mixed_class                <> cv_object) OR
                       (xsmv2.mixed_class               IS NULL))
             -- 自動配車対象区分
             AND     ((iv_auto_process_type             IS NULL) OR
                       (xsmv2.auto_process_type         =  cv_object))
             -- 有効開始日
             AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                       (xsmv2.start_date_active         IS NULL))
             -- 有効終了日
             AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                       (xsmv2.end_date_active           IS NULL))
             AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
             ) max_ship_method,
             xxcmn_delivery_lt2_v xdlv2
      -- 適用開始日(配送L/T)
      WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
               (xdlv2.lt_start_date_active              IS NULL))
      -- 適用終了日(配送L/T)
      AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
               (xdlv2.lt_end_date_active                IS NULL))
      -- 適用開始日(出荷方法)
      AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
               (xdlv2.sm_start_date_active              IS NULL))
      -- 適用終了日(出荷方法)
      AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
               (xdlv2.sm_end_date_active                IS NULL))
      AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
      AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
    ------------- 2008/07/11 変更要求対応#95 ADD START --------------------------------------
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
-- 2008/08/04 Del H.Itou Start
--        IF (iv_code_class2 <> cv_deliver_to) THEN  -- コード区分２<>「9:配送」の場合は再検索しない
--          RAISE no_data;
--        END IF;
-- 2008/08/04 Del H.Itou End
--
        ---------- 2. 倉庫(ALL値)－配送先(個別コード) -------------------------------
        BEGIN
          SELECT xdlv2.ship_method,
                 xdlv2.drink_deadweight,
                 xdlv2.leaf_deadweight,
                 xdlv2.drink_loading_capacity,
                 xdlv2.leaf_loading_capacity,
                 xdlv2.palette_max_qty
          INTO   ov_max_ship_methods,
                 on_drink_deadweight,
                 on_leaf_deadweight,
                 on_drink_loading_capacity,
                 on_leaf_loading_capacity,
                 on_palette_max_qty
          FROM   (SELECT xdlv2.ship_methods_id,
                         MAX(xdlv2.ship_method)
                           OVER(PARTITION BY
                             xdlv2.code_class1,
                             xdlv2.entering_despatching_code1,
                             xdlv2.code_class2,
                             xdlv2.entering_despatching_code2
                           ) max_ship
                 FROM    xxcmn_delivery_lt2_v xdlv2,
                         xxwsh_ship_method2_v xsmv2
                 WHERE   (CASE
                           -- ドリンク積載重量
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.drink_deadweight
                           -- リーフ積載重量
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.leaf_deadweight
                           -- ドリンク積載容積
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.drink_loading_capacity
                           -- リーフ積載容積
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.leaf_loading_capacity
                         END) > 0
                 -- コード区分１
                 AND     xdlv2.code_class1                  =  iv_code_class1
                 -- 入出庫場所コード１
                 AND     xdlv2.entering_despatching_code1   =  cv_all_4     --ALL'Z'
                 -- コード区分２
                 AND     xdlv2.code_class2                  =  iv_code_class2
                 -- 入出庫場所コード２
                 AND     xdlv2.entering_despatching_code2   =  iv_entering_despatching_code2  --個別
                 -- 適用開始日(配送L/T)
                 AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                           (xdlv2.lt_start_date_active      IS NULL))
                 -- 適用終了日(配送L/T)
                 AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                           (xdlv2.lt_end_date_active        IS NULL))
                 -- 適用開始日(出荷方法)
                 AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                           (xdlv2.sm_start_date_active      IS NULL))
                 -- 適用終了日(出荷方法)
                 AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                           (xdlv2.sm_end_date_active        IS NULL))
                 -- 混載区分
                 AND     ((xsmv2.mixed_class                <> cv_object) OR
                           (xsmv2.mixed_class               IS NULL))
                 -- 自動配車対象区分
                 AND     ((iv_auto_process_type             IS NULL) OR
                           (xsmv2.auto_process_type         =  cv_object))
                 -- 有効開始日
                 AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                           (xsmv2.start_date_active         IS NULL))
                 -- 有効終了日
                 AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                           (xsmv2.end_date_active           IS NULL))
                 AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                 ) max_ship_method,
                 xxcmn_delivery_lt2_v xdlv2
          -- 適用開始日(配送L/T)
          WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                   (xdlv2.lt_start_date_active              IS NULL))
          -- 適用終了日(配送L/T)
          AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.lt_end_date_active                IS NULL))
          -- 適用開始日(出荷方法)
          AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                   (xdlv2.sm_start_date_active              IS NULL))
          -- 適用終了日(出荷方法)
          AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.sm_end_date_active                IS NULL))
          AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
          AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ------------- 3. 倉庫(個別コード)－配送先(ALL値) -----------------------------
            BEGIN
              SELECT xdlv2.ship_method,
                     xdlv2.drink_deadweight,
                     xdlv2.leaf_deadweight,
                     xdlv2.drink_loading_capacity,
                     xdlv2.leaf_loading_capacity,
                     xdlv2.palette_max_qty
              INTO   ov_max_ship_methods,
                     on_drink_deadweight,
                     on_leaf_deadweight,
                     on_drink_loading_capacity,
                     on_leaf_loading_capacity,
                     on_palette_max_qty
              FROM   (SELECT xdlv2.ship_methods_id,
                             MAX(xdlv2.ship_method)
                               OVER(PARTITION BY
                                 xdlv2.code_class1,
                                 xdlv2.entering_despatching_code1,
                                 xdlv2.code_class2,
                                 xdlv2.entering_despatching_code2
                               ) max_ship
                     FROM    xxcmn_delivery_lt2_v xdlv2,
                             xxwsh_ship_method2_v xsmv2
                     WHERE   (CASE
                               -- ドリンク積載重量
                               WHEN ((iv_prod_class             =  cv_drink) AND
                                      (iv_weight_capacity_class =  cv_weight)) THEN
                                 xdlv2.drink_deadweight
                               -- リーフ積載重量
                               WHEN ((iv_prod_class             =  cv_leaf) AND
                                      (iv_weight_capacity_class =  cv_weight)) THEN
                                 xdlv2.leaf_deadweight
                               -- ドリンク積載容積
                               WHEN ((iv_prod_class             =  cv_drink) AND
                                      (iv_weight_capacity_class =  cv_capacity)) THEN
                                 xdlv2.drink_loading_capacity
                               -- リーフ積載容積
                               WHEN ((iv_prod_class             =  cv_leaf) AND
                                      (iv_weight_capacity_class =  cv_capacity)) THEN
                                 xdlv2.leaf_loading_capacity
                             END) > 0
                     -- コード区分１
                     AND     xdlv2.code_class1                  =  iv_code_class1
                     -- 入出庫場所コード１
                     AND     xdlv2.entering_despatching_code1   =  iv_entering_despatching_code1    --個別
                     -- コード区分２
                     AND     xdlv2.code_class2                  =  iv_code_class2
-- 2008/08/04 Mod H.Itou Start
                     -- 入出庫場所コード２
                       -- コード区分が9:出荷の場合、ZZZZZZZZZ
                     AND   (((iv_code_class2                     = code_class_ship)
                         AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                       -- コード区分が4:配送先 OR 11:支給 の場合、ZZZZ
                       OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                         AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                     AND     xdlv2.entering_despatching_code2   =  cv_all_9          --ALL'Z'
-- 2008/08/04 Mod H.Itou End
                     -- 適用開始日(配送L/T)
                     AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                               (xdlv2.lt_start_date_active      IS NULL))
                     -- 適用終了日(配送L/T)
                     AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                               (xdlv2.lt_end_date_active        IS NULL))
                     -- 適用開始日(出荷方法)
                     AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                               (xdlv2.sm_start_date_active      IS NULL))
                     -- 適用終了日(出荷方法)
                     AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                               (xdlv2.sm_end_date_active        IS NULL))
                     -- 混載区分
                     AND     ((xsmv2.mixed_class                <> cv_object) OR
                               (xsmv2.mixed_class               IS NULL))
                     -- 自動配車対象区分
                     AND     ((iv_auto_process_type             IS NULL) OR
                               (xsmv2.auto_process_type         =  cv_object))
                     -- 有効開始日
                     AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                               (xsmv2.start_date_active         IS NULL))
                     -- 有効終了日
                     AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                               (xsmv2.end_date_active           IS NULL))
                     AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                     ) max_ship_method,
                     xxcmn_delivery_lt2_v xdlv2
              -- 適用開始日(配送L/T)
              WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                       (xdlv2.lt_start_date_active              IS NULL))
              -- 適用終了日(配送L/T)
              AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                       (xdlv2.lt_end_date_active                IS NULL))
              -- 適用開始日(出荷方法)
              AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                       (xdlv2.sm_start_date_active              IS NULL))
              -- 適用終了日(出荷方法)
              AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                       (xdlv2.sm_end_date_active                IS NULL))
              AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
              AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ----------- 4. 倉庫(ALL値)－配送先(ALL値) -------------------------------
                BEGIN
                  SELECT xdlv2.ship_method,
                         xdlv2.drink_deadweight,
                         xdlv2.leaf_deadweight,
                         xdlv2.drink_loading_capacity,
                         xdlv2.leaf_loading_capacity,
                         xdlv2.palette_max_qty
                  INTO   ov_max_ship_methods,
                         on_drink_deadweight,
                         on_leaf_deadweight,
                         on_drink_loading_capacity,
                         on_leaf_loading_capacity,
                         on_palette_max_qty
                  FROM   (SELECT xdlv2.ship_methods_id,
                                 MAX(xdlv2.ship_method)
                                   OVER(PARTITION BY
                                     xdlv2.code_class1,
                                     xdlv2.entering_despatching_code1,
                                     xdlv2.code_class2,
                                     xdlv2.entering_despatching_code2
                                   ) max_ship
                         FROM    xxcmn_delivery_lt2_v xdlv2,
                                 xxwsh_ship_method2_v xsmv2
                         WHERE   (CASE
                                   -- ドリンク積載重量
                                   WHEN ((iv_prod_class             =  cv_drink) AND
                                          (iv_weight_capacity_class =  cv_weight)) THEN
                                     xdlv2.drink_deadweight
                                   -- リーフ積載重量
                                   WHEN ((iv_prod_class             =  cv_leaf) AND
                                          (iv_weight_capacity_class =  cv_weight)) THEN
                                     xdlv2.leaf_deadweight
                                   -- ドリンク積載容積
                                   WHEN ((iv_prod_class             =  cv_drink) AND
                                          (iv_weight_capacity_class =  cv_capacity)) THEN
                                     xdlv2.drink_loading_capacity
                                   -- リーフ積載容積
                                   WHEN ((iv_prod_class             =  cv_leaf) AND
                                          (iv_weight_capacity_class =  cv_capacity)) THEN
                                     xdlv2.leaf_loading_capacity
                                 END) > 0
                         -- コード区分１
                         AND     xdlv2.code_class1                  =  iv_code_class1
                         -- 入出庫場所コード１
                         AND     xdlv2.entering_despatching_code1   =  cv_all_4          --ALL'Z'
                         -- コード区分２
                         AND     xdlv2.code_class2                  =  iv_code_class2
-- 2008/08/04 Mod H.Itou Start
                     -- 入出庫場所コード２
                       -- コード区分が9:出荷の場合、ZZZZZZZZZ
                     AND   (((iv_code_class2                     = code_class_ship)
                         AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                       -- コード区分が4:配送先 OR 11:支給 の場合、ZZZZ
                       OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                         AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                     AND     xdlv2.entering_despatching_code2   =  cv_all_9          --ALL'Z'
-- 2008/08/04 Mod H.Itou End
                         -- 適用開始日(配送L/T)
                         AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                                   (xdlv2.lt_start_date_active      IS NULL))
                         -- 適用終了日(配送L/T)
                         AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                                   (xdlv2.lt_end_date_active        IS NULL))
                         -- 適用開始日(出荷方法)
                         AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                                   (xdlv2.sm_start_date_active      IS NULL))
                         -- 適用終了日(出荷方法)
                         AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                                   (xdlv2.sm_end_date_active        IS NULL))
                         -- 混載区分
                         AND     ((xsmv2.mixed_class                <> cv_object) OR
                                   (xsmv2.mixed_class               IS NULL))
                         -- 自動配車対象区分
                         AND     ((iv_auto_process_type             IS NULL) OR
                                   (xsmv2.auto_process_type         =  cv_object))
                         -- 有効開始日
                         AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                                   (xsmv2.start_date_active         IS NULL))
                         -- 有効終了日
                         AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                                   (xsmv2.end_date_active           IS NULL))
                         AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                         ) max_ship_method,
                         xxcmn_delivery_lt2_v xdlv2
                  -- 適用開始日(配送L/T)
                  WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                           (xdlv2.lt_start_date_active              IS NULL))
                  -- 適用終了日(配送L/T)
                  AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                           (xdlv2.lt_end_date_active                IS NULL))
                  -- 適用開始日(出荷方法)
                  AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                           (xdlv2.sm_start_date_active              IS NULL))
                  -- 適用終了日(出荷方法)
                  AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                           (xdlv2.sm_end_date_active                IS NULL))
                  AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
                  AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
                --------- 上記1.から4.で参照して該当なしの場合 -------------------
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    RAISE no_data;
--
                END;  -- 4.
            END;  -- 3.
        END;  -- 2.
    ----------- 2008/07/11 変更要求対応#95 ADD END ------------------------------------
--
    /*----- 2008/07/11 変更要求対応#95 DEL START -------------------------------------
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
--
      -- ｢コード区分2｣が配送先の場合
      IF (iv_code_class2 = cv_deliver_to) THEN
        BEGIN
          SELECT xdlv2.ship_method,
                 xdlv2.drink_deadweight,
                 xdlv2.leaf_deadweight,
                 xdlv2.drink_loading_capacity,
                 xdlv2.leaf_loading_capacity,
                 xdlv2.palette_max_qty
          INTO   ov_max_ship_methods,
                 on_drink_deadweight,
                 on_leaf_deadweight,
                 on_drink_loading_capacity,
                 on_leaf_loading_capacity,
                 on_palette_max_qty
          FROM   (SELECT xdlv2.ship_methods_id,
                         MAX(xdlv2.ship_method)
                           OVER(PARTITION BY
                             xdlv2.code_class1,
                             xdlv2.entering_despatching_code1,
                             xdlv2.code_class2,
                             xdlv2.entering_despatching_code2
                           ) max_ship
                 FROM    xxcmn_delivery_lt2_v xdlv2,
                         xxwsh_ship_method2_v xsmv2
                 WHERE   (CASE
                           -- ドリンク積載重量
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.drink_deadweight
                           -- リーフ積載重量
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_weight)) THEN
                             xdlv2.leaf_deadweight
                           -- ドリンク積載容積
                           WHEN ((iv_prod_class             =  cv_drink) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.drink_loading_capacity
                           -- リーフ積載容積
                           WHEN ((iv_prod_class             =  cv_leaf) AND
                                  (iv_weight_capacity_class =  cv_capacity)) THEN
                             xdlv2.leaf_loading_capacity
                         END) > 0
                 -- コード区分１
                 AND     xdlv2.code_class1                  =  iv_code_class1
                 -- 入出庫場所コード１
                 AND     xdlv2.entering_despatching_code1   =  iv_entering_despatching_code1
                 -- コード区分２
                 AND     xdlv2.code_class2                  =  cv_base
                 -- 入出庫場所コード２
                 AND     xdlv2.entering_despatching_code2   =
                           (SELECT  xcas2.base_code
                           FROM     xxcmn_cust_acct_sites2_v   xcas2
                           WHERE    xcas2.ship_to_no           =  iv_entering_despatching_code2
                           AND      ((xcas2.start_date_active  <= ld_standard_date) OR
                                      (xcas2.start_date_active IS NULL))
                           AND      ((xcas2.end_date_active    >= ld_standard_date) OR
                                      (xcas2.end_date_active   IS NULL)))
                 -- 適用開始日(配送L/T)
                 AND     ((xdlv2.lt_start_date_active       <= ld_standard_date) OR
                           (xdlv2.lt_start_date_active      IS NULL))
                 -- 適用終了日(配送L/T)
                 AND     ((xdlv2.lt_end_date_active         >= ld_standard_date) OR
                           (xdlv2.lt_end_date_active        IS NULL))
                 -- 適用開始日(出荷方法)
                 AND     ((xdlv2.sm_start_date_active       <= ld_standard_date) OR
                           (xdlv2.sm_start_date_active      IS NULL))
                 -- 適用終了日(出荷方法)
                 AND     ((xdlv2.sm_end_date_active         >= ld_standard_date) OR
                           (xdlv2.sm_end_date_active        IS NULL))
                 -- 混載区分
                 AND     ((xsmv2.mixed_class                <> cv_object) OR
                           (xsmv2.mixed_class               IS NULL))
                 -- 自動配車対象区分
                 AND     ((iv_auto_process_type             IS NULL) OR
                           (xsmv2.auto_process_type         =  cv_object))
                 -- 有効開始日
                 AND     ((xsmv2.start_date_active          <= ld_standard_date) OR
                           (xsmv2.start_date_active         IS NULL))
                 -- 有効終了日
                 AND     ((xsmv2.end_date_active            >= ld_standard_date) OR
                           (xsmv2.end_date_active           IS NULL))
                 AND     xdlv2.ship_method                  =  xsmv2.ship_method_code
                 ) max_ship_method,
                 xxcmn_delivery_lt2_v xdlv2
          -- 適用開始日(配送L/T)
          WHERE  ((xdlv2.lt_start_date_active               <= ld_standard_date) OR
                   (xdlv2.lt_start_date_active              IS NULL))
          -- 適用終了日(配送L/T)
          AND    ((xdlv2.lt_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.lt_end_date_active                IS NULL))
          -- 適用開始日(出荷方法)
          AND    ((xdlv2.sm_start_date_active               <= ld_standard_date) OR
                   (xdlv2.sm_start_date_active              IS NULL))
          -- 適用終了日(出荷方法)
          AND    ((xdlv2.sm_end_date_active                 >= ld_standard_date) OR
                   (xdlv2.sm_end_date_active                IS NULL))
          AND    max_ship_method.ship_methods_id            =  xdlv2.ship_methods_id
          AND    max_ship_method.max_ship                   =  xdlv2.ship_method;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE no_data;
--
        END;
--
      ELSE
        RAISE no_data;
--
      END IF;
      ---------- 2008/07/11 変更要求対応#95 DEL END ---------------------------------*/
--
    END;  -- 1.
--
    RETURN gn_status_normal;
--
  EXCEPTION
--
    WHEN no_data THEN
      RETURN gn_status_error;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_max_ship_method;
--
  /**********************************************************************************
   * Function Name    : get_oprtn_day
   * Description      : 稼働日算出関数
   ***********************************************************************************/
  FUNCTION get_oprtn_day(
    id_date             IN  DATE,         -- 日付
    iv_whse_code        IN  VARCHAR2,     -- 保管倉庫コード
    iv_deliver_to_code  IN  VARCHAR2,     -- 配送先コード
    in_lead_time        IN  NUMBER,       -- リードタイム
    iv_prod_class       IN  VARCHAR2,     -- 商品区分
    od_oprtn_day        OUT NOCOPY DATE   -- 稼働日日付
-- 2009/06/25 H.Itou Add Start 本番障害#1463対応 日付＋LTも算出できるよう変更
   ,in_type             IN  NUMBER        -- -1:日付－LT, 1:日付＋LT
-- 2009/06/25 H.Itou Add End
    )
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_oprtn_day';  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_leaf       CONSTANT VARCHAR2(1)   := '1';              -- リーフ
    cv_drink      CONSTANT VARCHAR2(1)   := '2';              -- ドリンク
    cn_active     CONSTANT NUMBER        := 0;
--
    -- *** ローカル変数 ***
    lv_calender_cd    VARCHAR2(100);    -- カレンダーコード
    ld_date           DATE;             -- チェック日付
    ln_days           NUMBER;           -- チェック日数
    ln_check_flag     NUMBER;           -- チェックフラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- ローカル変数初期化
    lv_calender_cd  := NULL;      -- カレンダーコード
    ld_date         := id_date;   -- チェック日付
    ln_days         := 0;         -- チェック日数
    ln_check_flag   := NULL;      -- チェックフラグ
--
    -- **************************************************
    -- *** パラメータチェック
    -- **************************************************
    -- 「日付」チェック
    IF (id_date IS NULL) THEN
      RETURN gn_status_error;
    END IF;
--
    -- 「保管倉庫コード」と「配送先コード」の両方がNULL、
    -- 又は、両方がNOT NULLの場合はエラー
    IF (((iv_whse_code IS NULL) AND (iv_deliver_to_code IS NULL)) 
       OR ((iv_whse_code IS NOT NULL) AND (iv_deliver_to_code IS NOT NULL))) THEN
      RETURN gn_status_error;
    END IF;
--
    -- 「リードタイム」チェック
    IF ((in_lead_time IS NULL) OR (in_lead_time < 0)) THEN
      RETURN gn_status_error;
    END IF;
--
    -- 「商品区分」チェック
    IF ((iv_prod_class IS NULL) OR (iv_prod_class NOT IN (cv_leaf, cv_drink))) THEN
      RETURN gn_status_error;
    END IF;
--
    -- **************************************************
    -- *** カレンダーコード取得
    -- **************************************************
    -- カレンダコード取得関数を呼び、製造カレンダヘッダに存在するカレンダコードの場合、取得する
    BEGIN
      SELECT  msh.calendar_no
      INTO    lv_calender_cd
      FROM    mr_shcl_hdr   msh,
              mr_shcl_dtl   msd
      WHERE   msh.calendar_id   = msd.calendar_id
      AND     msd.delete_mark   = cn_active
      AND     msh.calendar_no   = xxcmn_common_pkg.get_calender_cd(iv_whse_code,
                                                                 iv_deliver_to_code,
                                                                 iv_prod_class)
      AND     ROWNUM            = 1
      ;
--
    -- カレンダコードが取得できなかった場合は、エラー
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN gn_status_error;
--
    END;
--
    -- **************************************************
    -- *** ループ処理
    -- **************************************************
    -- チェック日数の値がリードタイムより大きくなるまでループ
    <<oprtn_day_loop>>
    WHILE (ln_days <= in_lead_time) LOOP
      -- 稼働日チェック関数を呼び出す
      ln_check_flag := xxcmn_common_pkg.check_oprtn_day(ld_date,
                                                        lv_calender_cd);
      -- チェックフラグが稼働日の場合
      IF (ln_check_flag = 0) THEN
        od_oprtn_day := ld_date;
        ln_days      := ln_days + 1;
      END IF;
-- 2009/06/25 H.Itou Mod Start 本番障害#1463対応 日付＋LTも算出できるよう変更
--      ld_date := ld_date - 1;
      ld_date := ld_date + in_type;
-- 2009/06/25 H.Itou Mod End
    END LOOP oprtn_day_loop;
--
    RETURN gv_status_normal;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_oprtn_day;
--
-- 2009/06/25 H.Itou Add Start 本番障害#1436対応 INパラメータTYPEがない場合はTYPE=-1(日付－LT)。
  /**********************************************************************************
   * Function Name    : get_oprtn_day
   * Description      : 稼働日算出関数(日付－LT)
   ***********************************************************************************/
  FUNCTION get_oprtn_day(
    id_date             IN  DATE,         -- 日付
    iv_whse_code        IN  VARCHAR2,     -- 保管倉庫コード
    iv_deliver_to_code  IN  VARCHAR2,     -- 配送先コード
    in_lead_time        IN  NUMBER,       -- リードタイム
    iv_prod_class       IN  VARCHAR2,     -- 商品区分
    od_oprtn_day        OUT NOCOPY DATE   -- 稼働日日付
    )
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_oprtn_day';  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_retcode    NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- 稼働日算出関数(日付－LT 固定)
    ln_retcode := get_oprtn_day(
                    id_date            => id_date            -- 日付
                   ,iv_whse_code       => iv_whse_code       -- 保管倉庫コード
                   ,iv_deliver_to_code => iv_deliver_to_code -- 配送先コード
                   ,in_lead_time       => in_lead_time       -- リードタイム
                   ,iv_prod_class      => iv_prod_class      -- 商品区分
                   ,od_oprtn_day       => od_oprtn_day       -- 稼働日日付
                   ,in_type            => -1                 -- -1:日付－LT 固定
                  );
--
    RETURN ln_retcode;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_oprtn_day;
-- 2009/06/25 H.Itou Add End
  /**********************************************************************************
   * Function Name    : get_same_request_number
   * Description      : 同一依頼No検索関数
   ***********************************************************************************/
  FUNCTION get_same_request_number(
    iv_request_no         IN  xxwsh_order_headers_all.request_no%TYPE,      -- 1.依頼No
    on_same_request_count OUT NUMBER,                                       -- 2.同一依頼No件数
    on_order_header_id    OUT xxwsh_order_headers_all.order_header_id%TYPE) -- 3.同一依頼Noの受注ヘッダアドオンID
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_same_order_number'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_cancel           CONSTANT VARCHAR2(2)   := '99';                    --取消
--
-- ##### 20081202 Ver.1.32 本番#318対応 START #####
-- 2008/12/15 H.Itou Mod Start
--    lv_except_msg                    VARCHAR2(200);                          -- エラーメッセージ
    lv_except_msg                    VARCHAR2(4000);                        -- エラーメッセージ
-- 2008/12/15 H.Itou Mod End
    cv_get_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-10013';     -- 取得エラー
    cv_msg_kbn              CONSTANT VARCHAR2(5)   := 'XXWSH';               -- 出荷
    cv_tkn_table            CONSTANT VARCHAR2(20)  := 'TABLE';               -- TABLE
    cv_xoha                 CONSTANT VARCHAR2(100) := '受注ヘッダアドオン';
    cv_tkn_type             CONSTANT VARCHAR2(20)  := 'TYPE';                -- TYPE
    cv_tkn_no_type          CONSTANT VARCHAR2(20)  := 'NO_TYPE';             -- NO_TYPE
    cv_request_no           CONSTANT VARCHAR2(10)  := '依頼No';
    cv_tkn_request_no       CONSTANT VARCHAR2(20)  := 'REQUEST_NO';          -- REQUEST_NO
    cv_log_level            CONSTANT VARCHAR2(1)   := '6';                   -- ログレベル
    cv_colon                CONSTANT VARCHAR2(1)   := ':';                   -- コロン
-- ##### 20081202 Ver.1.32 本番#318対応 END   #####
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 入力パラメータチェック
    IF ( iv_request_no IS NULL ) THEN
      RETURN gn_status_error;
    END IF;
--
    -- 同一依頼Noの件数カウント
    SELECT COUNT(1)
    INTO   on_same_request_count
    FROM   xxwsh_order_headers_all  xoha
    WHERE  xoha.req_status  <> cv_cancel
    AND    xoha.request_no  =  iv_request_no
    ;
--
    IF (on_same_request_count > 1)
    THEN
--
      BEGIN
        -- 同一依頼Noの受注ヘッダアドオンID取得
        SELECT MAX(xoha.order_header_id)
        INTO   on_order_header_id
        FROM   (SELECT xoha.order_header_id,
                       MAX(xoha.last_update_date)
                         OVER(PARTITION BY
                           xoha.request_no
                         )  max_date
               FROM    xxwsh_order_headers_all  xoha
               WHERE   xoha.req_status             IN ('04', '08')  --出荷(04)と支給(08)実績計上済
               AND     NVL(xoha.latest_external_flag, 'N')   <> 'Y'
               AND     NVL(xoha.actual_confirm_class, 'N')   =  'Y'
               AND     xoha.request_no             =  iv_request_no
               )  max_order_headers,
               xxwsh_order_headers_all  xoha
        WHERE  max_order_headers.order_header_id   =  xoha.order_header_id
        AND    max_order_headers.max_date          =  xoha.last_update_date
        ;
--
-- 2008/08/11 H.Itou Add Start  変更要求#174 受注ヘッダIDを取得できない場合はエラーを返す。
      IF (on_order_header_id IS NULL) THEN
        RETURN gn_status_error;
      END IF;
-- 2008/08/11 H.Itou Add End
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
-- 2008/08/11 H.Itou Mod Start  変更要求#174 実績計上済区分がYのデータがない場合はエラーを返す。
--          NULL;
          RETURN gn_status_error;
-- 2008/08/11 H.Itou Mod End
--
      END;
--
    ELSIF (on_same_request_count = 1) THEN
--
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
      BEGIN
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
--
        SELECT xoha.order_header_id
        INTO   on_order_header_id
        FROM   xxwsh_order_headers_all  xoha
        WHERE  xoha.req_status  <> cv_cancel
        AND    xoha.request_no  =  iv_request_no
        ;
-- ##### 20081202 Ver.1.21 本番#318対応 START #####
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn        , cv_get_err,
                                                    cv_tkn_table      , cv_xoha,
                                                    cv_tkn_type       , NULL,
                                                    cv_tkn_no_type    , NULL,
                                                    cv_tkn_request_no , iv_request_no);
          FND_LOG.STRING(cv_log_level, gv_pkg_name
                        || cv_colon
                        || cv_prg_name, lv_except_msg);
          RETURN gn_status_error;
      END;
-- ##### 20081202 Ver.1.21 本番#318対応 END   #####
--
    ELSE
      -- 指定した依頼Noは存在しません。
      RETURN gn_status_error;
    END IF;
    RETURN gn_status_normal;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);      
--
--###################################  固定部 END   #########################################
--
  END get_same_request_number;
--
--
  /**********************************************************************************
   * Function Name    : convert_request_number
   * Description      : 依頼Noコンバート関数
   ***********************************************************************************/
  FUNCTION convert_request_number(
    iv_conv_div             IN  VARCHAR2,                                -- 1.変換区分
    iv_pre_conv_request_no  IN  VARCHAR2,                                -- 2.変換前依頼No
    ov_aft_conv_request_no  OUT xxwsh_order_headers_all.request_no%TYPE) -- 3.変換後依頼No
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_request_number'; --プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 文字列長チェック定数
    cn_nine_chars   CONSTANT NUMBER      := 9;   --  9文字
    cn_twelve_chars CONSTANT NUMBER      := 12;  -- 12文字
    -- 補完文字列
    cn_supplement_chars CONSTANT VARCHAR2(3) := '000';  -- 000
-- 2008/11/27 v1.31 ADD START
    cv_ship_drink   CONSTANT VARCHAR2(3) := '900';
    cv_ship_leaf    CONSTANT VARCHAR2(3) := '930';
-- 2008/11/27 v1.31 ADD END
--
    -- *** ローカル変数 ***
    lv_wsh_or_base_code VARCHAR2(4);
    ln_mast_count1      NUMBER;
    ln_mast_count2      NUMBER;
    ld_date_char        DATE;
-- 2008/11/27 v1.31 ADD START
    lv_ship_chk         VARCHAR2(3);
-- 2008/11/27 v1.31 ADD END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 入力パラメータチェック
    IF (( iv_conv_div IS NULL ) OR ( iv_pre_conv_request_no IS NULL )) THEN
      RETURN gn_status_error;
    END IF;
    --
    -- 変換区分のチェック
    -- 変換区分-> 1：拠点からのInBound用、2：拠点へのOutBound用
    IF    ( iv_conv_div = '1' ) THEN
      -- [拠点からのInbound]
      -- 変換前依頼Noチェック(9桁)
      IF ( LENGTHB( iv_pre_conv_request_no ) = cn_nine_chars ) THEN
        -- 9桁を12桁に変換
        ov_aft_conv_request_no :=
          SUBSTR( iv_pre_conv_request_no, 1 , 4 )
          || cn_supplement_chars
          || SUBSTR( iv_pre_conv_request_no, 5 , 5 );
      ELSE
        RETURN gn_status_error;
      END IF;
    --
    ELSIF ( iv_conv_div = '2' ) THEN
      -- [拠点へのOutbound]
      -- 変換前依頼Noチェック(12桁)
      IF ( LENGTHB( iv_pre_conv_request_no ) = cn_twelve_chars ) THEN
        -- 変換前依頼Noの先頭4文字を取得
        lv_wsh_or_base_code := SUBSTR( iv_pre_conv_request_no, 1 , 4 );
-- 2008/11/27 v1.31 ADD START
        -- 出荷情報チェックとして先頭3文字を取得
        lv_ship_chk := SUBSTR( lv_wsh_or_base_code, 1, 3 );
--
       -- ドリンクまたはリーフの出荷情報の場合
       IF ( lv_ship_chk IN ( cv_ship_drink, cv_ship_leaf ) ) THEN
         -- 4桁目以降の9桁へ変換
         ov_aft_conv_request_no := SUBSTR( iv_pre_conv_request_no, 4 );
--
       ELSE
-- 2008/11/27 v1.31 ADD END
        -- 顧客マスタチェック
        SELECT COUNT(1)
        INTO   ln_mast_count1
--        FROM   hz_parties       hp,
--               hz_cust_accounts hca
        FROM   xxcmn_parties2_v       hp,
               xxcmn_cust_accounts2_v hca
        WHERE  lv_wsh_or_base_code  = hp.party_number
               AND
               hp.party_id          = hca.party_id
        ;
        -- OPM保管場所マスタチェック
        SELECT COUNT(1)
        INTO   ln_mast_count2
        FROM   xxcmn_item_locations_v xilv
        WHERE  lv_wsh_or_base_code  = xilv.segment1
        ;
        -- 何れかのマスタに存在したか？
        IF (( ln_mast_count1 > 0 ) OR (ln_mast_count2 > 0 )) THEN
          -- 9桁変換
          ov_aft_conv_request_no :=
            SUBSTR( iv_pre_conv_request_no, 1 , 4 )
            || SUBSTR( iv_pre_conv_request_no, 8 , 5 );          
        ELSE
          --先頭4桁年月チェック(年月でない場合はエラー)
          BEGIN
            SELECT TO_DATE(SUBSTR( iv_pre_conv_request_no, 1 , 4 ),'YYMM')
            INTO   ld_date_char
            FROM   DUAL;
          EXCEPTION
            WHEN OTHERS THEN
              RETURN gn_status_error;
          END;
          -- 9桁変換
          ov_aft_conv_request_no :=
            SUBSTR( iv_pre_conv_request_no, 3 , 2 )
            || SUBSTR( iv_pre_conv_request_no, 6 , 7 );
--
        END IF;
-- 2008/11/27 ADD START
       END IF;
-- 2008/11/27 ADD END
      ELSE
        RETURN gn_status_error;
      END IF;
    ELSE
      RETURN gn_status_error;
    END IF;
--
    RETURN gn_status_normal;
--
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END convert_request_number;
--
--
  /**********************************************************************************
   * Function Name    : get_max_pallet_qty
   * Description      : 最大パレット枚数算出関数
   ***********************************************************************************/
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
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_max_pallet_qty'; --プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_deliver_to CONSTANT VARCHAR2(1)   := '9';                  --配送先
    cv_base       CONSTANT VARCHAR2(1)   := '1';                  --拠点
    cv_all_4      CONSTANT VARCHAR2(4)   := 'ZZZZ';               --2008/07/11 変更要求対応#95
    cv_all_9      CONSTANT VARCHAR2(9)   := 'ZZZZZZZZZ';          --2008/07/11 変更要求対応#95
--
    -- *** ローカル変数 ***
    ld_standard_date DATE;                                        --基準日
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
    lv_ship_methods  xxcmn_ship_methods.ship_method%TYPE;         --配送区分
-- 2008/10/15 H.Itou Add End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 必須入力パラメータチェック
    IF (  ( iv_code_class1                IS NULL ) 
       OR ( iv_entering_despatching_code1 IS NULL )
       OR ( iv_code_class2                IS NULL )
       OR ( iv_entering_despatching_code2 IS NULL )
       OR ( iv_ship_methods               IS NULL )) THEN
      RETURN gn_status_error;
    END IF;
--
    -- 「基準日(適用日基準日)」が指定されない場合はシステム日付
    IF ( id_standard_date IS NULL) THEN
      ld_standard_date := TRUNC(SYSDATE);
    ELSE
      ld_standard_date := TRUNC(id_standard_date);
    END IF;
--
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
    -- 混載配送区分を配送区分に変換
    lv_ship_methods := convert_mixed_ship_method(
                         it_ship_method_code => iv_ship_methods   -- IN 混載配送区分
                       );
-- 2008/10/15 H.Itou Add End
--
    ------------ 1. 倉庫(個別コード)－配送先(個別コード) --------------------------
    BEGIN
      SELECT
        xdlv2.drink_deadweight,                                             -- ドリンク積載重量
        xdlv2.leaf_deadweight,                                              -- リーフ積載重量
        xdlv2.drink_loading_capacity,                                       -- ドリンク積載容積
        xdlv2.leaf_loading_capacity,                                        -- リーフ積載容積
        xdlv2.palette_max_qty                                               -- パレット最大枚数
      INTO
        on_drink_deadweight,
        on_leaf_deadweight,
        on_drink_loading_capacity,
        on_leaf_loading_capacity,
        on_palette_max_qty
      FROM
        xxcmn_delivery_lt2_v  xdlv2
      WHERE
        xdlv2.code_class1                 =  iv_code_class1                 -- コード区分１
        AND
        xdlv2.entering_despatching_code1  =  iv_entering_despatching_code1  -- 入出庫場所コード１（個別）
        AND
        xdlv2.code_class2                 =  iv_code_class2                 -- コード区分２
        AND
        xdlv2.entering_despatching_code2  =  iv_entering_despatching_code2  -- 入出庫場所コード２（個別）
        AND
        xdlv2.lt_start_date_active       <=  ld_standard_date               -- 適用開始日(配送L/T)
        AND
        xdlv2.lt_end_date_active         >=  ld_standard_date               -- 適用終了日(配送L/T)
        AND
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
--        xdlv2.ship_method                 =  iv_ship_methods                -- 出荷方法
        xdlv2.ship_method                 =  lv_ship_methods                -- 出荷方法
-- 2008/10/15 H.Itou Add End
        AND
        xdlv2.sm_start_date_active       <=  ld_standard_date               -- 適用開始日(出荷方法)
        AND
        xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- 適用終了日(出荷方法)
--
    ------------- 2008/07/11 変更要求対応#95 ADD START --------------------------------------
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
-- 2008/08/04 Del H.Itou Start
--        IF (iv_code_class2 <> cv_deliver_to) THEN  -- コード区分２<>「9:配送」の場合は再検索しない
--          RAISE no_data;
--        END IF;
-- 2008/08/04 Del H.Itou End
--
        --------------- 2. 倉庫(ALL値)－配送先(個別コード) --------------------------
        BEGIN
          SELECT
            xdlv2.drink_deadweight,                                             -- ドリンク積載重量
            xdlv2.leaf_deadweight,                                              -- リーフ積載重量
            xdlv2.drink_loading_capacity,                                       -- ドリンク積載容積
            xdlv2.leaf_loading_capacity,                                        -- リーフ積載容積
            xdlv2.palette_max_qty                                               -- パレット最大枚数
          INTO
            on_drink_deadweight,
            on_leaf_deadweight,
            on_drink_loading_capacity,
            on_leaf_loading_capacity,
            on_palette_max_qty
          FROM
            xxcmn_delivery_lt2_v  xdlv2
          WHERE
            xdlv2.code_class1                 =  iv_code_class1                 -- コード区分１
            AND
            xdlv2.entering_despatching_code1  =  cv_all_4                       -- 入出庫場所コード１（ALL'Z'）
            AND
            xdlv2.code_class2                 =  iv_code_class2                 -- コード区分２
            AND
            xdlv2.entering_despatching_code2  =  iv_entering_despatching_code2  -- 入出庫場所コード２（個別）
            AND
            xdlv2.lt_start_date_active       <=  ld_standard_date               -- 適用開始日(配送L/T)
            AND
            xdlv2.lt_end_date_active         >=  ld_standard_date               -- 適用終了日(配送L/T)
            AND
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
--            xdlv2.ship_method                 =  iv_ship_methods                -- 出荷方法
            xdlv2.ship_method                 =  lv_ship_methods                -- 出荷方法
-- 2008/10/15 H.Itou Add End
            AND
            xdlv2.sm_start_date_active       <=  ld_standard_date               -- 適用開始日(出荷方法)
            AND
            xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- 適用終了日(出荷方法)
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -------------- 3. 倉庫(個別コード)－配送先(ALL値) ------------------------
            BEGIN
              SELECT
                xdlv2.drink_deadweight,                                             -- ドリンク積載重量
                xdlv2.leaf_deadweight,                                              -- リーフ積載重量
                xdlv2.drink_loading_capacity,                                       -- ドリンク積載容積
                xdlv2.leaf_loading_capacity,                                        -- リーフ積載容積
                xdlv2.palette_max_qty                                               -- パレット最大枚数
              INTO
                on_drink_deadweight,
                on_leaf_deadweight,
                on_drink_loading_capacity,
                on_leaf_loading_capacity,
                on_palette_max_qty
              FROM
                xxcmn_delivery_lt2_v  xdlv2
              WHERE
                xdlv2.code_class1                 =  iv_code_class1                 -- コード区分１
                AND
                xdlv2.entering_despatching_code1  =  iv_entering_despatching_code1  -- 入出庫場所コード１（個別）
                AND
                xdlv2.code_class2                 =  iv_code_class2                 -- コード区分２
-- 2008/08/04 Mod H.Itou Start
                -- 入出庫場所コード２
                AND
                  -- コード区分が9:出荷の場合、ZZZZZZZZZ
                      (((iv_code_class2                     = code_class_ship)
                    AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                  -- コード区分が4:配送先 OR 11:支給 の場合、ZZZZ
                  OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                    AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                AND
--                xdlv2.entering_despatching_code2  =  cv_all_9                       -- 入出庫場所コード２（ALL'Z'）
-- 2008/08/04 Mod H.Itou End
                AND
                xdlv2.lt_start_date_active       <=  ld_standard_date               -- 適用開始日(配送L/T)
                AND
                xdlv2.lt_end_date_active         >=  ld_standard_date               -- 適用終了日(配送L/T)
                AND
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
--                xdlv2.ship_method                 =  iv_ship_methods                -- 出荷方法
                xdlv2.ship_method                 =  lv_ship_methods                -- 出荷方法
-- 2008/10/15 H.Itou Add End
                AND
                xdlv2.sm_start_date_active       <=  ld_standard_date               -- 適用開始日(出荷方法)
                AND
                xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- 適用終了日(出荷方法)
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -------------- 4. 倉庫(ALL値)－配送先(ALL値) ---------------------------
                BEGIN
                  SELECT
                    xdlv2.drink_deadweight,                                             -- ドリンク積載重量
                    xdlv2.leaf_deadweight,                                              -- リーフ積載重量
                    xdlv2.drink_loading_capacity,                                       -- ドリンク積載容積
                    xdlv2.leaf_loading_capacity,                                        -- リーフ積載容積
                    xdlv2.palette_max_qty                                               -- パレット最大枚数
                  INTO
                    on_drink_deadweight,
                    on_leaf_deadweight,
                    on_drink_loading_capacity,
                    on_leaf_loading_capacity,
                    on_palette_max_qty
                  FROM
                    xxcmn_delivery_lt2_v  xdlv2
                  WHERE
                    xdlv2.code_class1                 =  iv_code_class1                 -- コード区分１
                    AND
                    xdlv2.entering_despatching_code1  =  cv_all_4                       -- 入出庫場所コード１（ALL'Z'）
                    AND
                    xdlv2.code_class2                 =  iv_code_class2                 -- コード区分２
-- 2008/08/04 Mod H.Itou Start
                -- 入出庫場所コード２
                AND
                  -- コード区分が9:出荷の場合、ZZZZZZZZZ
                      (((iv_code_class2                     = code_class_ship)
                    AND (xdlv2.entering_despatching_code2   = cv_all_9))          --ALL'Z'
                  -- コード区分が4:配送先 OR 11:支給 の場合、ZZZZ
                  OR   ((iv_code_class2                     IN (code_class_whse, code_class_supply))
                    AND (xdlv2.entering_despatching_code2   = cv_all_4)))         --ALL'Z'
--                AND
--                xdlv2.entering_despatching_code2  =  cv_all_9                       -- 入出庫場所コード２（ALL'Z'）
-- 2008/08/04 Mod H.Itou End
                    AND
                    xdlv2.lt_start_date_active       <=  ld_standard_date               -- 適用開始日(配送L/T)
                    AND
                    xdlv2.lt_end_date_active         >=  ld_standard_date               -- 適用終了日(配送L/T)
                    AND
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
--                    xdlv2.ship_method                 =  iv_ship_methods                -- 出荷方法
                    xdlv2.ship_method                 =  lv_ship_methods                -- 出荷方法
-- 2008/10/15 H.Itou Add End
                    AND
                    xdlv2.sm_start_date_active       <=  ld_standard_date               -- 適用開始日(出荷方法)
                    AND
                    xdlv2.sm_end_date_active         >=  ld_standard_date ;             -- 適用終了日(出荷方法)
--
                -------------- 上記1.から4.で参照して該当なしの場合 ---------------------
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    RAISE no_data;
--
                END;  -- 4.
            END;  -- 3.
        END;  -- 2.
    ----------- 2008/07/11 変更要求対応#95 ADD END ------------------------------------
--
    /*----- 2008/07/11 変更要求対応#95 DEL START -------------------------------------
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
--
      IF (iv_code_class2 = cv_deliver_to) THEN
        BEGIN
          SELECT
            xdlv2.drink_deadweight,                                             -- ドリンク積載重量
            xdlv2.leaf_deadweight,                                              -- リーフ積載重量
            xdlv2.drink_loading_capacity,                                       -- ドリンク積載容積
            xdlv2.leaf_loading_capacity,                                        -- リーフ積載容積
            xdlv2.palette_max_qty                                               -- パレット最大枚数
          INTO
            on_drink_deadweight,
            on_leaf_deadweight,
            on_drink_loading_capacity,
            on_leaf_loading_capacity,
            on_palette_max_qty
          FROM
            xxcmn_delivery_lt2_v  xdlv2
          WHERE
            xdlv2.code_class1                 =  iv_code_class1                 -- コード区分１
            AND
            xdlv2.entering_despatching_code1  =  iv_entering_despatching_code1  -- 入出庫場所コード１
            AND
            xdlv2.code_class2                 =  cv_base                        -- コード区分２
            AND
            xdlv2.entering_despatching_code2  =
              (SELECT  xcas2.base_code
              FROM    xxcmn_cust_acct_sites2_v  xcas2
              WHERE   xcas2.ship_to_no         = iv_entering_despatching_code2
              AND     xcas2.start_date_active <= id_standard_date
              AND     xcas2.end_date_active   >= id_standard_date)              -- 入出庫場所コード２
            AND
            xdlv2.lt_start_date_active       <=  ld_standard_date               -- 適用開始日(配送L/T)
            AND
            xdlv2.lt_end_date_active         >=  ld_standard_date               -- 適用終了日(配送L/T)
            AND
            xdlv2.ship_method                 =  iv_ship_methods                -- 出荷方法
            AND
            xdlv2.sm_start_date_active       <=  ld_standard_date               -- 適用開始日(出荷方法)
            AND
            xdlv2.sm_end_date_active         >=  ld_standard_date;              -- 適用終了日(出荷方法)
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE no_data;
--
        END;
--
      ELSE
        RAISE no_data;
--
      END IF;
      ---------- 2008/07/11 変更要求対応#95 DEL END ---------------------------------*/
--
    END;  --1.
--
    RETURN gn_status_normal;
--
  EXCEPTION
--
    WHEN no_data THEN
      RETURN gn_status_error;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_max_pallet_qty;
--
  /**********************************************************************************
   * Function Name    : check_tightening_status
   * Description      : 締めステータスチェック関数
   ***********************************************************************************/
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
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'check_tightening_status'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_all                CONSTANT NUMBER        := -999;                      -- ALL(数値項目)
    cv_all                CONSTANT VARCHAR2(3)   := 'ALL';                     -- ALL(文字項目)
    cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                       -- YES
    cv_no                 CONSTANT VARCHAR2(1)   := 'N';                       -- NO
    cv_close              CONSTANT VARCHAR2(1)   := '1';                       -- 締め
    cv_cancel             CONSTANT VARCHAR2(1)   := '2';                       -- 解除
    cv_inside_err         CONSTANT VARCHAR2(2)   := '-1';                      -- 内部エラー
    cv_close_proc_n_enfo  CONSTANT VARCHAR2(1)   := '1';                       -- 締め処理未実施
    cv_first_close_fin    CONSTANT VARCHAR2(1)   := '2';                       -- 初回締め済
    cv_close_cancel       CONSTANT VARCHAR2(1)   := '3';                       -- 締め解除
    cv_re_close_fin       CONSTANT VARCHAR2(1)   := '4';                       -- 再締め済
    cv_customer_class_code_1 CONSTANT VARCHAR2(1)   := '1';                    -- 顧客区分：1
    cv_prod_class_1       CONSTANT VARCHAR2(1)   := '1';                       -- 商品区分：1
    cv_prod_class_2       CONSTANT VARCHAR2(1)   := '2';                       -- 商品区分：2
    cv_sales_branch_category_0 CONSTANT VARCHAR2(1)   := '0';                    -- 拠点カテゴリ：0
--
    -- *** ローカル変数 ***
    ln_count                  NUMBER;            -- カウント件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    BEGIN
      -- 締め解除状態チェック
      -- パラメータ「拠点」が入力された場合
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- 「拠点」および、「拠点」に紐付く「拠点カテゴリ」で解除レコードを検索      
-- 2009/01/21 H.Itou Mod Start 本番#1053対応
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_cancel
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.41 M.Hokkanji Start
                AND    ((xtc.sales_branch_category = cv_all) OR
                        (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                                    , cv_prod_class_2, xcav.drink_base_category
                                                                    , cv_prod_class_1, xcav.leaf_base_category)
                                                         FROM  xxcmn_cust_accounts2_v xcav
                                                        WHERE xcav.party_number      =  iv_sales_branch
                                                          AND xcav.start_date_active <= id_ship_date
                                                          AND xcav.end_date_active   >= id_ship_date)))
-- Ver1.41 M.Hokkanji End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel)
                ;
-- 2009/01/21 H.Itou Mod End
--
        -- 合致するデータがあれば｢締め解除｣を返す
-- Ver1.13 Start
--        IF (ln_count = 1) THEN
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        -- 複数レコード取得された場合は｢内部エラー｣を返す
--        ELSIF (ln_count > 1) THEN
--          RETURN cv_inside_err;
        END IF;
-- Ver1.13 End
--
      -- パ3ラメータ「拠点カテゴリ」が入力された場合
-- Ver1.13 Start
      ELSIF ((iv_sales_branch_category IS NOT NULL)
        AND (iv_sales_branch_category <> 'ALL'
          AND iv_sales_branch_category <> cv_sales_branch_category_0)) THEN
--      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
-- Ver1.13 End
--      ELSIF (iv_sales_branch_category IS NOT NULL) THEN
        -- 「拠点カテゴリ」および、「拠点カテゴリ」に紐付く全ての「拠点」で解除レコードを検索
-- 2009/01/21 H.Itou Mod Start 本番#1053対応
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_cancel
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel)
                ;
-- 2009/01/21 H.Itou Mod End
--
        -- 合致するデータが1件でもあれば｢締め解除｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
--
      -- パラメータ「拠点」および「拠点カテゴリ」が'ALL'の場合
-- Ver1.13 Start
      ELSIF (NVL(iv_sales_branch,cv_all) = cv_all)
        AND (NVL(iv_sales_branch_category,cv_all) IN (cv_all,cv_sales_branch_category_0)) THEN
--      ELSIF (iv_sales_branch = cv_all) AND (iv_sales_branch_category = cv_all) THEN
-- Ver1.13 End
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
-- Ver1.13 Start
-- 使用していないテーブルのため削除
--               ,xxcmn_cust_accounts2_v    xcav
-- Ver1.13 End
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
-- Ver1.41 M.Hokkanji Start
-- 入力パラメータより小さい値で締め解除されている場合は締め解除を返す（大きい単位での上書きをさせないため）
--        AND     xtc.sales_branch          =  cv_all
--        AND     xtc.sales_branch_category =  cv_all
-- Ver1.41 M.Hokkanji End
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_cancel;
--
        -- 合致するデータが1件でもあれば｢締め解除｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
      END IF;
--
      -- 再締め状態チェック
      -- パラメータ「拠点」が入力された場合
--      IF (iv_sales_branch IS NOT NULL) THEN
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- 「拠点」および、「拠点」に紐付く「拠点カテゴリ」で解除レコードを検索
-- 2009/01/21 H.Itou Mod Start 本番#1053対応
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =   cv_all
-- Ver1.41 M.Hokkanji Start
                AND    ((xtc.sales_branch_category = cv_all) OR
                        (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                                    , cv_prod_class_2, xcav.drink_base_category
                                                                    , cv_prod_class_1, xcav.leaf_base_category)
                                                         FROM  xxcmn_cust_accounts2_v xcav
                                                        WHERE xcav.party_number      =  iv_sales_branch
                                                          AND xcav.start_date_active <= id_ship_date
                                                          AND xcav.end_date_active   >= id_ship_date)))
-- Ver1.41 M.Hokkanji End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- 2009/01/21 H.Itou Mod End
--
        -- 合致するデータがあれば｢再締め済み｣を返す
-- Ver1.13 Start
--        IF (ln_count = 1) THEN
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        -- 複数レコード取得された場合は｢内部エラー｣を返す
--        ELSIF (ln_count > 1) THEN
--          RETURN cv_inside_err;
        END IF;
-- Ver1.13 End
--
      -- パラメータ「拠点カテゴリ」が入力された場合
-- Ver1.13 Start
      ELSIF ((iv_sales_branch_category IS NOT NULL)
        AND (iv_sales_branch_category <> 'ALL'
          AND iv_sales_branch_category <> cv_sales_branch_category_0)) THEN
--      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
-- Ver1.13 End
--      ELSIF (iv_sales_branch_category IS NOT NULL) THEN
        -- 「拠点カテゴリ」および、「拠点カテゴリ」に紐付く全ての「拠点」で解除レコードを検索
-- 2009/01/21 H.Itou Mod Start 本番#1053対応
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- 2009/01/21 H.Itou Mod End
--
        -- 合致するデータが1件でもあれば｢再締め済み｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
--
      -- パラメータ「拠点」および「拠点カテゴリ」が'ALL'の場合
-- Ver1.13 Start
      ELSIF (NVL(iv_sales_branch,cv_all) = cv_all)
        AND (NVL(iv_sales_branch_category,cv_all) IN (cv_all,cv_sales_branch_category_0)) THEN
--      ELSIF (iv_sales_branch = cv_all) AND (iv_sales_branch_category = cv_all) THEN
-- Ver1.13 End
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
-- Ver1.41 M.Hokkanji Start
--        AND     xtc.sales_branch          =  cv_all
--        AND     xtc.sales_branch_category =  cv_all
-- Ver1.41 M.Hokkanji End
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_close;
--
        -- 合致するデータが1件でもあれば｢再締め済み｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
      END IF;
--
      -- 初回締め状態チェック
      -- パラメータ「拠点」が入力された場合
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- 「拠点」および、「拠点」に紐付く「拠点カテゴリ」で解除レコードを検索
-- 2009/01/21 H.Itou Mod Start 本番#1053対応
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_yes
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.41 M.Hokkanji Start
                AND    ((xtc.sales_branch_category = cv_all) OR
                        (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                                    , cv_prod_class_2, xcav.drink_base_category
                                                                    , cv_prod_class_1, xcav.leaf_base_category)
                                                         FROM  xxcmn_cust_accounts2_v xcav
                                                        WHERE xcav.party_number      =  iv_sales_branch
                                                          AND xcav.start_date_active <= id_ship_date
                                                          AND xcav.end_date_active   >= id_ship_date)))
-- Ver1.41 M.Hokkanji End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- 2009/01/21 H.Itou Mod End
--
        -- 合致するデータがあれば｢初回締め済｣を返す
-- Ver1.13 Start
--        IF (ln_count = 1) THEN
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        -- 複数レコード取得された場合は｢内部エラー｣を返す
--        ELSIF (ln_count > 1) THEN
--          RETURN cv_inside_err;
        END IF;
-- Ver1.13 End
--
      -- パラメータ「拠点カテゴリ」が入力された場合
-- Ver1.13 Start
      ELSIF ((iv_sales_branch_category IS NOT NULL)
        AND (iv_sales_branch_category <> 'ALL'
          AND iv_sales_branch_category <> cv_sales_branch_category_0)) THEN
--      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
-- Ver1.13 End
        -- 「拠点カテゴリ」および、「拠点カテゴリ」に紐付く全ての「拠点」で解除レコードを検索
-- 2009/01/21 H.Itou Mod Start 本番#1053対応
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_yes
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- 2009/01/21 H.Itou Mod End
--
        -- 合致するデータが1件でもあれば｢初回締め済｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
--
      -- パラメータ「拠点」および「拠点カテゴリ」が'ALL'の場合
-- Ver1.13 Start
      ELSIF (NVL(iv_sales_branch,cv_all) = cv_all)
        AND (NVL(iv_sales_branch_category,cv_all) IN (cv_all,cv_sales_branch_category_0)) THEN
--V1.13 mod      ELSIF (iv_sales_branch = cv_all) AND (iv_sales_branch_category = cv_all) THEN
--      ELSIF (NVL(iv_sales_branch, cv_all) = cv_all) AND (NVL(iv_sales_branch_category, cv_all) = cv_all) THEN
-- Ver1.13 End
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
-- Ver1.41 M.Hokkanji Start
--        AND     xtc.sales_branch          =  cv_all
--        AND     xtc.sales_branch_category =  cv_all
-- Ver1.41 M.Hokkanji End
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_yes
        AND     xtc.tighten_release_class =  cv_close;
--
        -- 合致するデータが1件でもあれば｢初回締め済｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
      END IF;
--
      -- 合致するデータがない場合は｢締め処理未実施｣を返す
      RETURN cv_close_proc_n_enfo;
--
    EXCEPTION
      -- その他の例外時には｢内部エラー｣を返す
      WHEN OTHERS THEN
        RETURN cv_inside_err;
    END;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_tightening_status;
--
  /**********************************************************************************
   * Function Name    : update_line_items
   * Description      : 重量容積小口個数更新関数
   ***********************************************************************************/
  FUNCTION update_line_items(
    iv_biz_type             IN  VARCHAR2,                                -- 1.業務種別
    iv_request_no           IN  VARCHAR2)                                -- 2.依頼No/移動番号
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_items'; --プログラム名
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_ship_req             CONSTANT VARCHAR2(1)   := '1';                   -- 出荷依頼
    cv_supply_req           CONSTANT VARCHAR2(1)   := '2';                   -- 支給依頼
    cv_move_req             CONSTANT VARCHAR2(1)   := '3';                   -- 移動指示
    cv_flag_yes             CONSTANT VARCHAR2(1)   := 'Y';                   -- YES
    cv_flag_no              CONSTANT VARCHAR2(1)   := 'N';                   -- NO
    cv_ship                 CONSTANT VARCHAR2(1)   := '1';                   -- 出荷
    cv_supply               CONSTANT VARCHAR2(1)   := '2';                   -- 支給
    cv_move                 CONSTANT VARCHAR2(1)   := '3';                   -- 移動
    cv_shiped_confirm       CONSTANT VARCHAR2(2)   := '04';                  -- 出荷実績計上済
    cv_shiped_confirm_prov  CONSTANT VARCHAR2(2)   := '08';                  -- 出荷実績計上済(支給)
    cv_shiped_report        CONSTANT VARCHAR2(2)   := '04';                  -- 出庫報告有
    cv_delivery_report      CONSTANT VARCHAR2(2)   := '06';                  -- 入出庫報告有
    cv_include              CONSTANT VARCHAR2(1)   := '1';                   -- 対象
    cv_whse                 CONSTANT VARCHAR2(1)   := '4';                   -- 倉庫
    cv_deliver_to           CONSTANT VARCHAR2(1)   := '9';                   -- 配送先
    cv_supply_to            CONSTANT VARCHAR2(2)   := '11';                  -- 支給先
    cv_product              CONSTANT VARCHAR2(1)   := '1';                   -- 製品
    cv_colon                CONSTANT VARCHAR2(1)   := ':';                   -- コロン
    cv_log_level            CONSTANT VARCHAR2(1)   := '6';                   -- ログレベル
    cv_msg_kbn              CONSTANT VARCHAR2(5)   := 'XXWSH';               -- 出荷
-- 2008/11/13 H.Itou Add Start 統合テスト指摘311
    cv_mode_result          CONSTANT VARCHAR2(1)   := '2';                   -- 指示/実績区分 2:実績
-- 2008/11/13 H.Itou Add End
    cv_xoha                 CONSTANT VARCHAR2(100) := '受注ヘッダアドオン';
    cv_xola                 CONSTANT VARCHAR2(100) := '受注明細アドオン';
    cv_mrih                 CONSTANT VARCHAR2(100) := '移動依頼/指示ヘッダ(アドオン)';
    cv_mril                 CONSTANT VARCHAR2(100) := '移動依頼/指示明細(アドオン)';
    cv_xcs                  CONSTANT VARCHAR2(100) := '配車配送計画(アドオン)';
    cv_small_sum_class      CONSTANT VARCHAR2(100) := '小口区分';
    cv_carriers_info        CONSTANT VARCHAR2(100) := '配車基準情報';
    cv_order_lines_item_mst CONSTANT VARCHAR2(100) := '受注明細アドオン･OPM品目マスタ';
    cv_mov_lines_item_mst   CONSTANT VARCHAR2(100) := '移動依頼/指示明細(アドオン)･OPM品目マスタ';
    cv_order_mov_headers    CONSTANT VARCHAR2(100)
      := '受注ヘッダアドオン･移動依頼/指示明細(アドオン)';
    cv_type_ship            CONSTANT VARCHAR2(10)  := '出荷';
    cv_type_supply          CONSTANT VARCHAR2(10)  := '支給';
    cv_type_move            CONSTANT VARCHAR2(10)  := '移動';
    cv_request_no           CONSTANT VARCHAR2(10)  := '依頼No';
    cv_move_no              CONSTANT VARCHAR2(10)  := '移動番号';
    cv_tkn_table            CONSTANT VARCHAR2(20)  := 'TABLE';               -- TABLE
    cv_tkn_api_name         CONSTANT VARCHAR2(20)  := 'API_NAME';            -- API_NAME
    cv_tkn_type             CONSTANT VARCHAR2(20)  := 'TYPE';                -- TYPE
    cv_tkn_no_type          CONSTANT VARCHAR2(20)  := 'NO_TYPE';             -- NO_TYPE
    cv_tkn_request_no       CONSTANT VARCHAR2(20)  := 'REQUEST_NO';          -- REQUEST_NO
    cv_tkn_def_line_num     CONSTANT VARCHAR2(20)  := 'DEFAULT_LINE_NUMBER'; -- DEFAULT_LINE_NUMBER
    cv_tkn_err_msg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';             -- ERR_MSG
    cv_para_err             CONSTANT VARCHAR2(100) := 'APP-XXWSH-10012';     -- 入力パラメータエラー
    cv_get_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-10013';     -- 取得エラー
    cv_api_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-10014';     -- API実行エラー
    cv_update_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-10015';     -- 更新エラー
    cv_get_carry_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-10016';     -- 取得エラー(配車)
    cv_api_carry_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-10017';     -- API実行エラー(配車)
    cv_update_carry_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-10018';     -- 更新エラー(配車)
-- Ver1.46 M.Hokkanji Start
    cv_spot_sale_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-10025';     -- データ取得エラー
    cv_token_data           CONSTANT VARCHAR2(4)   := 'DATA';                -- メッセージトークン(DATA)
-- Ver1.46 M.Hokkanji End
    cv_api_xoha             CONSTANT VARCHAR2(100) := '受注ヘッダアドオンから項目を取得';
    cv_api_xola             CONSTANT VARCHAR2(100) := '受注明細アドオンから項目を取得';
    cv_api_mrih             CONSTANT VARCHAR2(100) := '移動依頼/指示ヘッダ(アドオン)から項目を取得';
    cv_api_mril             CONSTANT VARCHAR2(100) := '移動依頼/指示明細(アドオン)から項目を取得';
    cv_api_xcs              CONSTANT VARCHAR2(100) := '配車配送計画（アドオン）から項目を取得';
    cv_api_xoha_im          CONSTANT VARCHAR2(100)
      := '受注明細アドオン、OPM品目マスタから項目を取得';
    cv_api_mril_im          CONSTANT VARCHAR2(100)
      := '移動依頼/指示明細(アドオン)、OPM品目マスタから項目を取得';
    cv_api_xoha_mrih        CONSTANT VARCHAR2(100)
      := '受注ヘッダアドオン、移動依頼/指示明細(アドオン)から項目を取得';
    cv_api_small_sum_class  CONSTANT VARCHAR2(30)  := '小口区分の取得';
    cv_api_carriers_info    CONSTANT VARCHAR2(30)  := '配車基準情報の取得';
    cv_api_calc_total_value CONSTANT VARCHAR2(100) := '積載効率チェック(合計値算出)';
    cv_api_weight           CONSTANT VARCHAR2(100) := '重量積載効率算出';
    cv_api_capacity         CONSTANT VARCHAR2(100) := '容積積載効率算出';
    cv_api_lock             CONSTANT VARCHAR2(100) := 'ロック処理';
    cv_api_update_line_item CONSTANT VARCHAR2(100) := '重量容積小口個数更新関数';
-- Ver1.46 M.Hokkanji Start
    cv_spot_sale_ship_name  CONSTANT VARCHAR2(8)   := '庭先出荷';
-- Ver1.46 M.Hokkanji End
--
    -- *** ローカル変数 ***
    ln_pallet_waight                NUMBER;                     -- パレット重量
    lv_small_sum_class              VARCHAR2(1);                -- 小口区分
    ld_date                         DATE;                       -- 基準日
    lv_syohin_class                 VARCHAR2(2);                -- 商品区分
-- Ver1.46 M.Hokkanji Start
    ln_transaction_id_spot_sale     NUMBER;                     -- 出庫形態ID(庭先出庫)
    lv_weight_check_flag            VARCHAR2(1);                -- 積載率チェックフラグ
-- Ver1.46 M.Hokkanji End
-- 2008/12/15 H.Itou Mod Start
--    lv_except_msg                   VARCHAR2(200);              -- エラーメッセージ
    lv_except_msg                   VARCHAR2(32767);            -- エラーメッセージ
-- 2008/12/15 H.Itou Mod End
    ln_counter                      NUMBER;                     -- カウント変数
    lv_tkn_biz_type                 VARCHAR2(100);              -- トークン_業務種別
    lv_tkn_request_no               VARCHAR2(100);              -- トークン_依頼No/移動番号
    -- 受注ヘッダアドオン
    lv_req_status                   VARCHAR2(2);                -- ステータス
    lv_result_shipping_method_code  VARCHAR2(2);                -- 配送区分_実績
    lv_result_deliver_to            VARCHAR2(9);                -- 出荷先_実績
    lv_deliver_from                 VARCHAR2(4);                -- 出荷元保管場所
    lv_delivery_no                  VARCHAR2(12);               -- 配送No
    ln_order_header_id              NUMBER;                     -- 受注ヘッダアドオンID
    ld_shipped_date                 DATE;                       -- 出荷日
    lv_prod_class                   VARCHAR2(2);                -- 商品区分
    ln_real_pallet_quantity         NUMBER;                     -- パレット実績枚数
    lv_vendor_site_code             VARCHAR2(100);              -- 取引先サイト
--add start 1.14
    lv_freight_charge_class         xxwsh_order_headers_all.freight_charge_class%TYPE; --運賃区分
--add end 1.14
-- Ver1.46 M.Hokkanji Start
    ln_order_type_id                NUMBER;                     -- 受注タイプID
-- Ver1.46 M.Hokkanji End
    -- 受注明細アドオン
    ln_shipped_quantity             NUMBER;                     -- 出荷実績数量
    lv_shipping_item_code           VARCHAR2(7);                -- 出荷品目
    lv_conv_unit                    VARCHAR2(240);              -- 入出庫換算単位
    lv_num_of_cases                 VARCHAR2(240);              -- ケース入数
    lv_num_of_deliver               VARCHAR2(240);              -- 出荷入数
    ln_order_line_id                NUMBER;                     -- 受注明細アドオンID
    -- 移動依頼/指示ヘッダ(アドオン)
    lv_status                       VARCHAR2(100);              -- ステータス
    lv_actual_shipping_method_code  VARCHAR2(100);              -- 配送区分
    ln_mov_hdr_id                   NUMBER;                     -- 移動ヘッダID
    lv_shipped_locat_code           VARCHAR2(100);              -- 出庫元保管場所
    lv_ship_to_locat_code           VARCHAR2(100);              -- 入庫先保管場所
    lv_product_flg                  VARCHAR2(100);              -- 製品識別区分
    ld_actual_ship_date             DATE;                       -- 出庫実績日
    lv_item_class                   VARCHAR2(2);                -- 商品区分
    ln_out_pallet_qty               NUMBER;                     -- パレット枚数（出）
    -- 移動依頼/指示明細(アドオン)
    lv_item_code                    VARCHAR2(100);              -- 品目
    ln_mov_line_id                  NUMBER;                     -- 移動明細ID
    -- 共通関数｢積載効率チェック｣OUTパラメータ
    lv_retcode                      VARCHAR2(1);                -- リターンコード
    lv_errmsg_code                  VARCHAR2(100);              -- エラーメッセージコード
    lv_errmsg                       VARCHAR2(100);              -- エラーメッセージ
    lv_loading_over_class           VARCHAR2(100);              -- 積載オーバー区分
    lv_ship_methods                 VARCHAR2(100);              -- 出荷方法
    ln_load_efficiency_weight       NUMBER;                     -- 重量積載効率
    ln_load_efficiency_capacity     NUMBER;                     -- 容積積載効率
    lv_mixed_ship_method            VARCHAR2(100);              -- 混載配送区分
    -- 合計値
    ln_sum_weight                   NUMBER;                     -- 合計重量
    ln_sum_capacity                 NUMBER;                     -- 合計容積
    ln_sum_pallet_weight            NUMBER;                     -- 合計パレット重量
    -- 配車配送計画更新
    lv_default_line_number          VARCHAR2(100);              -- 基準明細No
    lv_process_class                VARCHAR2(100);              -- 処理種別
    lv_attribute1                   VARCHAR2(100);              -- 出荷支給区分
    -- ヘッダ更新項目
    ln_update_sum_weight            NUMBER;                     -- 積載重量合計
    ln_update_sum_capacity          NUMBER;                     -- 積載容積合計
    ln_update_sum_pallet_weight     NUMBER;                     -- 合計パレット重量
    ln_update_small_quantity        NUMBER;                     -- 小口個数
    ln_update_load_effi_weight      NUMBER;                     -- 重量積載効率
    ln_update_load_effi_capacity    NUMBER;                     -- 容積積載効率
    -- 明細更新項目
    lv_update_delivery_no           VARCHAR2(12);               -- 配送No
    ln_update_weight                NUMBER;                     -- 重量
    ln_update_capacity              NUMBER;                     -- 容積
    ln_update_pallet_weight         NUMBER;                     -- パレット重量
    ln_update_order_line_id         NUMBER;                     -- 明細ID
    ln_update_mov_line_id           NUMBER;                     -- 移動明細ID
    -- WHOカラム
    ln_user_id                      NUMBER;                     -- ログインしているユーザーのID取得
    ln_login_id                     NUMBER;                     -- 最終更新ログイン
    ln_conc_request_id              NUMBER;                     -- 要求ID
    ln_prog_appl_id                 NUMBER;                     -- プログラム・アプリケーションID
    ln_conc_program_id              NUMBER;                     -- プログラムID
    ld_sysdate                      DATE;                       -- システム現在日付
    -- テーブル変数
    lt_ship_tab                     get_ship_tbl;               -- 出荷
    lt_supply_tab                   get_supply_tbl;             -- 支給
    lt_move_tab                     get_move_tbl;               -- 移動
    lt_update_tbl                   get_update_tbl;             -- 明細更新項目
--
    -- *** ローカル・カーソル ***
    -- 出荷カーソル
    CURSOR  ship_cur IS
      --SELECT  xola.shipped_quantity,                    -- 出荷実績数量
      SELECT  NVL(xola.shipped_quantity, 0) AS shipped_quantity, -- 出荷実績数量
              xola.shipping_item_code,                  -- 出荷品目
              ximv.conv_unit,                           -- 入出庫換算単位
              ximv.num_of_cases,                        -- ケース入数
              ximv.num_of_deliver,                      -- 出荷入数
              xola.order_line_id                        -- 受注明細アドオンID
      FROM    xxwsh_order_lines_all         xola,       -- 受注明細アドオン
              xxcmn_item_mst_v              ximv        -- OPM品目情報VIEW
      WHERE   xola.order_header_id              =  ln_order_header_id
      AND     NVL(xola.delete_flag, cv_flag_no) <> cv_flag_yes
      AND     ximv.item_no                      =  xola.shipping_item_code
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    -- 支給カーソル
    CURSOR  supply_cur IS
      SELECT  xola.shipping_item_code,                  -- 出荷品目
              --xola.shipped_quantity,                    -- 出荷実績数量
              NVL(xola.shipped_quantity, 0) AS shipped_quantity, -- 出荷実績数量
              xola.order_line_id                        -- 受注明細アドオンID
      FROM    xxwsh_order_lines_all         xola        -- 受注明細アドオン
      WHERE   xola.order_header_id              =  ln_order_header_id
      AND     NVL(xola.delete_flag, cv_flag_no) <> cv_flag_yes
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    -- 移動カーソル
    CURSOR  move_cur IS
      --SELECT  mril.shipped_quantity,                    -- 出庫実績数量
      SELECT  NVL(mril.shipped_quantity, 0) AS shipped_quantity, -- 出庫実績数量
              mril.item_code,                           -- 品目
              ximv.conv_unit,                           -- 入出庫換算単位
              ximv.num_of_cases,                        -- ケース入数
              ximv.num_of_deliver,                      -- 出荷入数
              mril.mov_line_id                          -- 移動明細ID
      FROM    xxinv_mov_req_instr_lines     mril,       -- 移動依頼/指示明細(アドオン)
              xxcmn_item_mst_v              ximv        -- OPM品目情報VIEW
      WHERE   mril.mov_hdr_id               =  ln_mov_hdr_id
      AND     mril.delete_flg               <> cv_flag_yes
      AND     ximv.item_no                  =  mril.item_code
      FOR UPDATE OF mril.mov_line_id NOWAIT;
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    lock_expt                  EXCEPTION;  -- ロック取得例外
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- プロファイル取得
    ln_pallet_waight := TO_NUMBER(FND_PROFILE.VALUE('XXWSH_PALLET_WEIGHT')); -- パレット重量
--
    -- 入力パラメータチェック
    IF (( iv_biz_type IS NULL ) OR ( iv_request_no IS NULL )) THEN
      lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_para_err);
      FND_LOG.STRING(cv_log_level, gv_pkg_name
                    || cv_colon
                    || cv_prg_name, lv_except_msg);
      RETURN gn_status_error;
--
    END IF;
--
    -- トークンの値を設定
    IF (iv_biz_type = cv_ship) THEN
      lv_tkn_biz_type   := cv_type_ship;
      lv_tkn_request_no := cv_request_no;
    ELSIF (iv_biz_type = cv_supply) THEN
      lv_tkn_biz_type   := cv_type_supply;
      lv_tkn_request_no := cv_request_no;
    ELSIF (iv_biz_type = cv_move) THEN
      lv_tkn_biz_type   := cv_type_move;
      lv_tkn_request_no := cv_move_no;
    END IF;
--
-- Ver1.46 M.Hokkanji Start
    BEGIN
      SELECT xottv.transaction_type_id
        INTO ln_transaction_id_spot_sale
        FROM xxwsh_oe_transaction_types_v xottv
       WHERE xottv.transaction_type_name = cv_spot_sale_ship_name;
    EXCEPTION
      WHEN OTHERS THEN
        lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_spot_sale_err
                                                 ,cv_token_data, cv_spot_sale_ship_name);
        FND_LOG.STRING(cv_log_level, gv_pkg_name
                      || cv_colon
                      || cv_prg_name, lv_except_msg);
        RETURN gn_status_error;
    END;
-- Ver1.46 M.Hokkanji End
    -- WHOカラム情報取得
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    ld_sysdate           := SYSDATE;                      -- システム現在日付
--
    -- セーブポイントを取得します
    SAVEPOINT advance_sp;
--
    -- **************************************************
    -- *** 1.業務種別が出荷の場合
    -- **************************************************
    IF (iv_biz_type = cv_ship) THEN
--
      BEGIN
--
        BEGIN
          -- (1)受注ヘッダアドオンから項目を取得
          -- ロックを取得する
          SELECT  xoha.req_status,                      -- ステータス
                  --xoha.result_shipping_method_code,     -- 配送区分_実績
                  NVL(xoha.result_shipping_method_code,
                      xoha.shipping_method_code),       -- 配送区分_実績、NULLのときは、配送区分を取得
                  --xoha.result_deliver_to,               -- 出荷先_実績
                  NVL(xoha.result_deliver_to,
                      xoha.deliver_to),                 -- 出荷先_実績、NULLのときは、出荷先を取得
                  xoha.deliver_from,                    -- 出荷元保管場所
                  xoha.delivery_no,                     -- 配送No
                  xoha.order_header_id,                 -- 受注ヘッダアドオンID
                  --xoha.shipped_date,                    -- 出荷日
                  NVL(xoha.shipped_date,
                      xoha.schedule_ship_date),         -- 出荷日、NULLのときは、出荷予定日を取得
                  xoha.prod_class,                      -- 商品区分
                  --xoha.real_pallet_quantity             -- パレット実績枚数
                  NVL(xoha.real_pallet_quantity, 0)     -- パレット実績枚数、NULLのときは、0を設定
--add start 1.14
                 ,freight_charge_class                  -- 運賃区分
--add end 1.14
-- Ver1.46 M.Hokkanji Start
                 ,order_type_id
-- Ver1.46 M.Hokkanji End
          INTO    lv_req_status,
                  lv_result_shipping_method_code,
                  lv_result_deliver_to,
                  lv_deliver_from,
                  lv_delivery_no,
                  ln_order_header_id,
                  ld_shipped_date,
                  lv_prod_class,
                  ln_real_pallet_quantity
--add start 1.14
                 ,lv_freight_charge_class
--add end 1.14
-- Ver1.46 M.Hokkanji Start
                 ,ln_order_type_id
-- Ver1.46 M.Hokkanji End
          FROM    xxwsh_order_headers_all       xoha,       -- 受注ヘッダアドオン
                  xxwsh_oe_transaction_types2_v ott2        -- 受注タイプ情報VIEW
          WHERE   xoha.request_no                             =  iv_request_no
          AND     xoha.order_type_id                          =  ott2.transaction_type_id
          AND     ott2.shipping_shikyu_class                  =  cv_ship_req
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes
          --AND     ott2.start_date_active  <= xoha.shipped_date
          --AND     xoha.shipped_date       <= NVL(ott2.end_date_active, xoha.shipped_date)
          AND     ott2.start_date_active  <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
          AND     NVL(xoha.shipped_date, xoha.schedule_ship_date)
                                                             <= NVL(ott2.end_date_active, NVL(xoha.shipped_date, xoha.schedule_ship_date))
          FOR UPDATE OF xoha.order_header_id NOWAIT;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level, gv_pkg_name
                          || cv_colon
                          || cv_prg_name, lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                  cv_tkn_api_name, cv_api_xoha,
                                                  cv_tkn_type, lv_tkn_biz_type,
                                                  cv_tkn_no_type, lv_tkn_request_no,
                                                  cv_tkn_request_no, iv_request_no,
                                                  cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- 取得したステータスが｢出荷実績計上済｣以外の場合は返り値に0：成功OR対象外を返し終了
        IF (lv_req_status <> cv_shiped_confirm) THEN
          RETURN gn_status_normal;
        END IF;
--
        -- 取得した配送Noを配車配送計画更新項目としてセット
        lv_update_delivery_no := lv_delivery_no;
--
--add start 1.14
        IF lv_freight_charge_class = gv_freight_charge_yes THEN
--add end 1.14
          BEGIN
            -- (2)取得した配送区分_実績をもとにクイックコード｢XXCMN_SHIP_METHOD｣から小口区分を取得
            SELECT  xsm2.small_amount_class
            INTO    lv_small_sum_class
            FROM    xxwsh_ship_method2_v    xsm2
            WHERE   xsm2.ship_method_code   =  lv_result_shipping_method_code
            AND     xsm2.start_date_active  <= ld_shipped_date
            AND     ld_shipped_date         <= NVL(xsm2.end_date_active, ld_shipped_date);
--
          EXCEPTION
            -- 取得できなかった場合は返り値に1：処理エラーを返し終了
            WHEN NO_DATA_FOUND THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                    cv_tkn_table, cv_small_sum_class,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
            WHEN OTHERS THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_xoha_im,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END;
--add start 1.14
        END IF;
--add end 1.14
--
        BEGIN
        -- カウント変数の初期化
        ln_counter := 0;
--
          -- (3)受注明細アドオン、OPM品目マスタから項目を取得
          -- ロックを取得する
          <<ship_loop>>
          FOR get_ship_data IN ship_cur LOOP
            lt_ship_tab(ln_counter).shipped_quantity    := get_ship_data.shipped_quantity;
            lt_ship_tab(ln_counter).shipping_item_code  := get_ship_data.shipping_item_code;
            lt_ship_tab(ln_counter).conv_unit           := get_ship_data.conv_unit;
            lt_ship_tab(ln_counter).num_of_cases        := get_ship_data.num_of_cases;
            lt_ship_tab(ln_counter).num_of_deliver      := get_ship_data.num_of_deliver;
            lt_ship_tab(ln_counter).order_line_id       := get_ship_data.order_line_id;
--
            -- (4)共通関数｢積載効率チェック(合計値算出)｣を呼び出す
            xxwsh_common910_pkg.calc_total_value(
              lt_ship_tab(ln_counter).shipping_item_code, -- 出荷品目
              lt_ship_tab(ln_counter).shipped_quantity,   -- 出荷実績数量
              lv_retcode,                                 -- リターンコード
              lv_errmsg_code,                             -- エラーメッセージコード
              lv_errmsg,                                  -- エラーメッセージ
              ln_sum_weight,                              -- 合計重量
              ln_sum_capacity,                            -- 合計容積
              ln_sum_pallet_weight,                       -- 合計パレット重量
-- 2008/10/06 H.Itou Add Start 統合テスト指摘240 INパラメータ.基準日を追加
              ld_shipped_date,                            -- 出荷日
-- 2008/10/06 H.Itou Add End
-- 2008/11/13 H.Itou Add Start 統合テスト指摘311
              cv_mode_result                              -- 指示/実績区分 2:実績 固定
-- 2008/11/13 H.Itou Add End
              );
--
            -- リターンコードが'1'(異常)の場合は返り値に1：処理エラーを返し終了
            IF (lv_retcode = gn_status_error) THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_calc_total_value,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, lv_errmsg);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- 正常時は更新項目に値を追加
            ELSE
-- 2008/08/07 H.Itou Add Start 変更要求#173 積載重量合計・積載容積合計がNULLにならないように、NVLする。
              ln_sum_weight        := NVL(ln_sum_weight, 0);       -- 合計重量
              ln_sum_capacity      := NVL(ln_sum_capacity, 0);     -- 合計容積
              ln_sum_pallet_weight := NVL(ln_sum_pallet_weight, 0);-- 合計パレット数
-- 2008/08/07 H.Itou Add End
              -- 【明細更新項目】
              lt_update_tbl(ln_counter).update_weight            :=  ln_sum_weight;
              lt_update_tbl(ln_counter).update_capacity          :=  ln_sum_capacity;
              lt_update_tbl(ln_counter).update_pallet_weight     :=  ln_sum_pallet_weight;
              lt_update_tbl(ln_counter).update_line_id :=  lt_ship_tab(ln_counter).order_line_id;
--
              --【ヘッダ更新項目】
              ln_update_sum_weight        :=  NVL(ln_update_sum_weight, 0)        + ln_sum_weight;
              ln_update_sum_capacity      :=  NVL(ln_update_sum_capacity, 0)      + ln_sum_capacity;
--2008/12/16 1.36 Mod Start 明細数分加算しているのを修正
--              ln_update_sum_pallet_weight :=  NVL(ln_update_sum_pallet_weight, 0)
--                                              + (ln_real_pallet_quantity * ln_pallet_waight);
              ln_update_sum_pallet_weight := (NVL(ln_real_pallet_quantity,0) * NVL(ln_pallet_waight,0));
--2008/12/16 1.36 Mod End
--
              -- ①(3)で取得した出荷実績数量が0の場合
              IF (lt_ship_tab(ln_counter).shipped_quantity = 0) THEN
-- Ver1.37 M.Hokkanji Start
                ln_update_small_quantity := NVL(ln_update_small_quantity, 0);
                --NULL;
-- Ver1.37 M.Hokkanji End
--
              -- ②(3)で取得した出荷入数が設定されている場合
-- 2008/08/07 H.Itou Mod Start 内部課題#32 出荷入数 > 0 に条件変更。
--              ELSIF (lt_ship_tab(ln_counter).num_of_deliver IS NOT NULL) THEN
              ELSIF (lt_ship_tab(ln_counter).num_of_deliver > 0 ) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity := NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start 変更要求#166 明細単位で整数に切り上げ、合計する。
--                                            + (ROUND(lt_ship_tab(ln_counter).shipped_quantity
                                            + (CEIL(lt_ship_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                            / lt_ship_tab(ln_counter).num_of_deliver));
--
              -- ③(3)で取得したケース入数が設定されている場合
-- 2008/08/07 H.Itou Mod Start 内部課題#32 入出庫換算単位 IS NOT NULL に条件変更。
--              ELSIF (lt_ship_tab(ln_counter).num_of_cases IS NOT NULL) THEN
              ELSIF (lt_ship_tab(ln_counter).conv_unit IS NOT NULL) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity := NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start 変更要求#166 明細単位で整数に切り上げ、合計する。
--                                            + (ROUND(lt_ship_tab(ln_counter).shipped_quantity
                                            + (CEIL(lt_ship_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                            / lt_ship_tab(ln_counter).num_of_cases));
--
              -- ④いずれの条件にも当てはまらない場合
              ELSE
                ln_update_small_quantity  := NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start 変更要求#166 明細単位で整数に切り上げ、合計する。
--                                             + lt_ship_tab(ln_counter).shipped_quantity;
                                             + CEIL(lt_ship_tab(ln_counter).shipped_quantity);
-- 2008/08/07 H.Itou Mod End
--
              END IF;
--
            END IF;
--
            -- カウント変数をインクリメント
            ln_counter := ln_counter + 1;
--
          END LOOP ship_loop;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_order_lines_item_mst,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                  cv_tkn_api_name, cv_order_lines_item_mst,
                                                  cv_tkn_type, lv_tkn_biz_type,
                                                  cv_tkn_no_type, lv_tkn_request_no,
                                                  cv_tkn_request_no, iv_request_no,
                                                  cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        -- 変数初期化
        lv_retcode      :=NULL;   -- リターンコード
        lv_errmsg_code  :=NULL;   -- エラーメッセージコード
        lv_errmsg       :=NULL;   -- エラーメッセージ
-- Ver1.46 M.Hokkanji Start
        ln_update_load_effi_capacity := NULL;
        ln_update_load_effi_weight   := NULL;
-- Ver1.46 M.Hokkanji End
--
-- 2008/08/07 H.Itou Mod Start 変更要求#173 積載効率算出条件は、配送Noではなく、運賃区分で判定
        -- (5)(1)で配送Noが設定されている場合、共通関数｢積載効率チェック(積載効率算出)｣を呼び出す
--mod start 1.14
----        IF (lv_update_delivery_no IS NOT NULL) THEN
--        IF (lv_update_delivery_no IS NOT NULL 
--        AND lv_freight_charge_class = gv_freight_charge_yes) THEN
-- Ver1.46 M.Hokkanji Start
        -- 運賃区分「1」の場合
--        IF (lv_freight_charge_class = gv_freight_charge_yes) THEN
        -- 運賃区分「1」の場合
        -- 受注タイプが庭先出庫の場合
        IF  (lv_freight_charge_class = gv_freight_charge_yes) AND
            (ln_order_type_id <> ln_transaction_id_spot_sale) THEN
-- Ver1.46 M.Hokkanji End
--mod end 1.14
-- 2008/08/07 H.Itou Mod End
-- 2008/08/07 H.Itou Del Start 変更要求#173 重量積載効率算出は積載合計重量の値に関わらず算出する。
--          -- 合計重量が設定されている場合
--          IF (ln_update_sum_weight > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- 重量積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            (CASE
              -- ①(2)で取得した小口区分が｢対象｣の場合
              WHEN (lv_small_sum_class = cv_include) THEN
                ln_update_sum_weight
              -- ②(2)で取得した小口区分が｢対象｣以外の場合
              ELSE
                ln_update_sum_weight + NVL(ln_update_sum_pallet_weight, 0)
            END),                                     -- 1.合計重量
            NULL,                                     -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            lv_deliver_from,                          -- 4.入出庫場所コード１
            cv_deliver_to,                            -- 5.コード区分２
            lv_result_deliver_to,                     -- 6.入出庫場所コード２
            lv_result_shipping_method_code,           -- 7.出荷方法
            lv_prod_class,                            -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_shipped_date,                          -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した重量積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 重量積載効率算出は積載合計重量の値に関わらず算出する。
--          END IF;
-- 2008/08/07 H.Itou Del End
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 容積積載効率算出は積載合計容積の値に関わらず算出する。
--          -- 合計容積が設定されている場合
--          IF (ln_update_sum_capacity > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- 容積積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.合計重量
            ln_update_sum_capacity,                   -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            lv_deliver_from,                          -- 4.入出庫場所コード１
            cv_deliver_to,                            -- 5.コード区分２
            lv_result_deliver_to,                     -- 6.入出庫場所コード２
            lv_result_shipping_method_code,           -- 7.出荷方法
            lv_prod_class,                            -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_shipped_date,                          -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した容積積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 容積積載効率算出は積載合計重量の値に関わらず算出する。
--          END IF;
-- 2008/08/07 H.Itou Del End
--  
        END IF;
--
        BEGIN
          <<order_lines_update_loop>>
          FOR i IN lt_update_tbl.FIRST .. lt_update_tbl.LAST LOOP
            -- (6)受注明細アドオンを明細更新項目に登録されている内容で更新
            UPDATE  xxwsh_order_lines_all           xola            -- 受注明細アドオン
            SET     xola.weight                   =  lt_update_tbl(i).update_weight,
                    xola.capacity                 =  lt_update_tbl(i).update_capacity,
                    xola.pallet_weight            =  lt_update_tbl(i).update_pallet_weight,
                    xola.last_updated_by          =  ln_user_id,
                    xola.last_update_date         =  ld_sysdate,
                    xola.last_update_login        =  ln_login_id,
                    xola.request_id               =  ln_conc_request_id,
                    xola.program_application_id   =  ln_prog_appl_id,
                    xola.program_id               =  ln_conc_program_id,
                    xola.program_update_date      =  ld_sysdate
            WHERE   xola.order_line_id            =  lt_update_tbl(i).update_line_id;
--
          END LOOP order_lines_update_loop;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (7)受注ヘッダアドオンをヘッダ更新項目に登録されている内容で更新
          UPDATE  xxwsh_order_headers_all         xoha            -- 受注ヘッダアドオン
-- 2008/08/07 H.Itou Mod Start 変更要求#173 運積載重量合計、積載容積合計は、運賃区分の条件無しに更新
----mod start 1.14
--          -- 積載重量合計
--          SET     xoha.sum_weight         = ln_update_sum_weight,
--          -- 積載容積合計
--                  xoha.sum_capacity       = ln_update_sum_capacity,
--          -- 積載重量合計
--          SET     xoha.sum_weight         = 
--                   (CASE
--                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
--                       ln_update_sum_weight
--                     ELSE
--                       xoha.sum_weight
--                    END),
--          -- 積載容積合計
--                  xoha.sum_capacity       =
--                   (CASE
--                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
--                       ln_update_sum_capacity
--                     ELSE
--                       xoha.sum_capacity
--                    END),
----mod end 1.14
          -- 積載重量合計
          SET     xoha.sum_weight         = ln_update_sum_weight,
          -- 積載容積合計
                  xoha.sum_capacity       = ln_update_sum_capacity,
-- 2008/08/07 H.Itou Mod End
          -- 合計パレット重量
                  xoha.sum_pallet_weight  = ln_update_sum_pallet_weight,
          -- 小口個数
                  xoha.small_quantity     = ln_update_small_quantity,
          -- 重量積載効率
                  xoha.loading_efficiency_weight =
                   (CASE
-- 2008/08/07 H.Itou Mod Start 変更要求#173
----mod start 1.14
----                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                     WHEN (lv_update_delivery_no IS NOT NULL OR lv_freight_charge_class = gv_freight_charge_yes) THEN
----mod end 1.14
--                       ln_update_load_effi_weight
--                     ELSE
--                       xoha.loading_efficiency_weight
                     -- 運賃区分「1」の場合、処理で取得した値を更新
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_weight
--
                     -- 上記以外の場合、NULLを更新
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
          -- 容積積載効率
                  xoha.loading_efficiency_capacity  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start 変更要求#173
----mod start 1.14
----                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                     WHEN (lv_update_delivery_no IS NOT NULL OR lv_freight_charge_class = gv_freight_charge_yes) THEN
----mod end 1.14
--                       ln_update_load_effi_capacity
--                     ELSE
--                       xoha.loading_efficiency_capacity
                     -- 運賃区分「1」の場合、処理で取得した値を更新
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_capacity
                     -- 上記以外の場合、NULLを更新
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
-- 2008/08/07 H.Itou Add Start 変更要求#173
          -- 基本重量
                  xoha.based_weight =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_weight
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 基本容積
                  xoha.based_capacity =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_capacity
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 配送区分
                  xoha.shipping_method_code =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.shipping_method_code
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 配送区分_実績
                  xoha.result_shipping_method_code =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.result_shipping_method_code
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
-- 2008/08/07 H.Itou Add End
                  xoha.last_updated_by           =  ln_user_id,
                  xoha.last_update_date          =  ld_sysdate,
                  xoha.last_update_login         =  ln_login_id,
                  xoha.request_id                =  ln_conc_request_id,
                  xoha.program_application_id    =  ln_prog_appl_id,
                  xoha.program_id                =  ln_conc_program_id,
                  xoha.program_update_date       =  ld_sysdate
          WHERE   xoha.order_header_id           =  ln_order_header_id;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    -- **************************************************
    -- *** 2.業務種別が支給の場合
    -- **************************************************
    ELSIF (iv_biz_type = cv_supply) THEN
--
      BEGIN
--
        BEGIN
          -- (1)受注ヘッダアドオンから項目を取得
          -- ロックを取得する
          SELECT  xoha.req_status,                      -- ステータス
                  --xoha.result_shipping_method_code,     -- 配送区分_実績
                  NVL(xoha.result_shipping_method_code,
                      xoha.shipping_method_code),       -- 配送区分_実績、NULLのときは、配送区分を取得
                  xoha.vendor_site_code,                -- 取引先サイト
                  xoha.deliver_from,                    -- 出荷元保管場所
                  xoha.delivery_no,                     -- 配送No
                  xoha.order_header_id,                 -- 受注ヘッダアドオンID
                  --xoha.shipped_date,                    -- 出荷日
                  NVL(xoha.shipped_date,
                      xoha.schedule_ship_date),         -- 出荷日、NULLのときは、出荷予定日を取得
                  xoha.prod_class                       -- 商品区分
-- 2008/08/07 H.Itou Add Start 変更要求#173 運賃区分取得追加
                 ,xoha.freight_charge_class             -- 運賃区分
-- 2008/08/07 H.Itou Add End
          INTO    lv_req_status,
                  lv_result_shipping_method_code,
                  lv_result_deliver_to,
                  lv_deliver_from,
                  lv_delivery_no,
                  ln_order_header_id,
                  ld_shipped_date,
                  lv_prod_class
-- 2008/08/07 H.Itou Add Start 変更要求#173 運賃区分取得追加
                 ,lv_freight_charge_class
-- 2008/08/07 H.Itou Add End
          FROM    xxwsh_order_headers_all       xoha,       -- 受注ヘッダアドオン
                  xxwsh_oe_transaction_types2_v ott2        -- 受注タイプ情報VIEW
          WHERE   xoha.request_no                             =  iv_request_no
          AND     xoha.order_type_id                          =  ott2.transaction_type_id
          AND     ott2.shipping_shikyu_class                  =  cv_supply_req
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes
          --AND     ott2.start_date_active  <= xoha.shipped_date
          --AND     xoha.shipped_date       <= NVL(ott2.end_date_active, xoha.shipped_date)
          AND     ott2.start_date_active  <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
          AND     NVL(xoha.shipped_date, xoha.schedule_ship_date)
                                                             <= NVL(ott2.end_date_active, NVL(xoha.shipped_date, xoha.schedule_ship_date))
          FOR UPDATE OF xoha.order_header_id NOWAIT;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- 取得したステータスが｢出荷実績計上済｣以外の場合は返り値に0：成功OR対象外を返し終了
        IF (lv_req_status <> cv_shiped_confirm_prov) THEN
          RETURN gn_status_normal;
--
        END IF;
--
        -- 取得した配送Noを配車配送計画更新項目としてセット
        lv_update_delivery_no := lv_delivery_no;
--
        BEGIN
        -- カウント変数の初期化
        ln_counter := 0;
--
          -- (2)受注明細アドオンから項目を取得
          -- ロックを取得する
          <<supply_loop>>
          FOR get_supply_data IN supply_cur LOOP
            lt_supply_tab(ln_counter).shipping_item_code := get_supply_data.shipping_item_code;
            lt_supply_tab(ln_counter).shipped_quantity   := get_supply_data.shipped_quantity;
            lt_supply_tab(ln_counter).order_line_id      := get_supply_data.order_line_id;
--
            -- (3)共通関数｢積載効率チェック(合計値算出)｣を呼び出す
            xxwsh_common910_pkg.calc_total_value(
              lt_supply_tab(ln_counter).shipping_item_code,   -- 出荷品目
              lt_supply_tab(ln_counter).shipped_quantity,     -- 出荷実績数量
              lv_retcode,              -- リターンコード
              lv_errmsg_code,          -- エラーメッセージコード
              lv_errmsg,               -- エラーメッセージ
              ln_sum_weight,           -- 合計重量
              ln_sum_capacity,         -- 合計容積
              ln_sum_pallet_weight,    -- 合計パレット重量
-- 2008/10/06 H.Itou Add Start 統合テスト指摘240 INパラメータ.基準日を追加
              ld_shipped_date,         -- 出荷日
-- 2008/10/06 H.Itou Add End
-- 2008/11/13 H.Itou Add Start 統合テスト指摘311
              cv_mode_result           -- 指示/実績区分 2:実績 固定
-- 2008/11/13 H.Itou Add End
              );
--
            -- リターンコードが'1'(異常)の場合は返り値に1：処理エラーを返し終了
            IF (lv_retcode = gn_status_error) THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_calc_total_value,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, lv_errmsg);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- 正常時は更新項目に値を追加
            ELSE
-- 2008/08/07 H.Itou Add Start 変更要求#173 積載重量合計・積載容積合計がNULLにならないように、NVLする。
              ln_sum_weight        := NVL(ln_sum_weight, 0);       -- 合計重量
              ln_sum_capacity      := NVL(ln_sum_capacity, 0);     -- 合計容積
              ln_sum_pallet_weight := NVL(ln_sum_pallet_weight, 0);-- 合計パレット数
-- 2008/08/07 H.Itou Add End
              -- 【明細更新項目】
              lt_update_tbl(ln_counter).update_weight            :=  ln_sum_weight;
              lt_update_tbl(ln_counter).update_capacity          :=  ln_sum_capacity;
              lt_update_tbl(ln_counter).update_line_id :=  lt_supply_tab(ln_counter).order_line_id;
--
              --【ヘッダ更新項目】
              ln_update_sum_weight    := NVL(ln_update_sum_weight, 0)   + ln_sum_weight;
              ln_update_sum_capacity  := NVL(ln_update_sum_capacity, 0) + ln_sum_capacity;
--
            END IF;
--
          -- カウント変数をインクリメント
          ln_counter := ln_counter + 1;
--
          END LOOP supply_loop;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- 変数初期化
        lv_retcode      :=NULL;   -- リターンコード
        lv_errmsg_code  :=NULL;   -- エラーメッセージコード
        lv_errmsg       :=NULL;   -- エラーメッセージ
--
-- 2008/08/07 H.Itou Mod Start 変更要求#173 積載効率算出条件は、配送Noではなく、運賃区分で判定
--        -- (4)(1)で配送Noが設定されている場合、共通関数｢積載効率チェック(積載効率算出)｣を呼び出す
--        IF (lv_update_delivery_no IS NOT NULL) THEN
        -- 運賃区分「1」の場合
        IF (lv_freight_charge_class = gv_freight_charge_yes) THEN
-- 2008/08/07 H.Itou Mod End
-- 2008/08/07 H.Itou Del Start 変更要求#173 重量積載効率算出は積載合計重量の値に関わらず算出する。
--          -- 合計重量が設定されている場合
--          IF (ln_update_sum_weight > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- 重量積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            ln_update_sum_weight,                     -- 1.合計重量
            NULL,                                     -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            lv_deliver_from,                          -- 4.入出庫場所コード１
            cv_supply_to,                             -- 5.コード区分２
            lv_result_deliver_to,                     -- 6.入出庫場所コード２
            lv_result_shipping_method_code,           -- 7.出荷方法
            lv_prod_class,                            -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_shipped_date,                          -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した重量積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 重量積載効率算出は積載合計重量の値に関わらず算出する。
--          END IF;
-- 2008/08/07 H.Itou Del End
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 容積積載効率算出は積載合計容積の値に関わらず算出する。
--           -- 合計容積が設定されている場合
--        IF (ln_update_sum_capacity > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- 容積積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.合計重量
            ln_update_sum_capacity,                   -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            lv_deliver_from,                          -- 4.入出庫場所コード１
            cv_supply_to,                             -- 5.コード区分２
            lv_result_deliver_to,                     -- 6.入出庫場所コード２
            lv_result_shipping_method_code,           -- 7.出荷方法
            lv_prod_class,                            -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_shipped_date,                          -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
          END IF;
--
          -- 取得した容積積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
        END IF;
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 容積積載効率算出は積載合計容積の値に関わらず算出する。
--        END IF;
-- 2008/08/07 H.Itou Del End
--
        BEGIN
          <<order_lines_update_loop>>
          FOR i IN lt_update_tbl.FIRST .. lt_update_tbl.LAST LOOP
            -- (5)受注明細アドオンを更新項目に登録されている内容で更新
            UPDATE  xxwsh_order_lines_all           xola            -- 受注明細アドオン
            SET     xola.weight                   =  lt_update_tbl(i).update_weight,
                    xola.capacity                 =  lt_update_tbl(i).update_capacity,
                    xola.last_updated_by          =  ln_user_id,
                    xola.last_update_date         =  ld_sysdate,
                    xola.last_update_login        =  ln_login_id,
                    xola.request_id               =  ln_conc_request_id,
                    xola.program_application_id   =  ln_prog_appl_id,
                    xola.program_id               =  ln_conc_program_id,
                    xola.program_update_date      =  ld_sysdate
            WHERE   xola.order_line_id            =  lt_update_tbl(i).update_line_id;
--
          END LOOP order_lines_update_loop;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xola,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (6)受注ヘッダアドオンをヘッダ更新項目に登録されている内容で更新
          UPDATE  xxwsh_order_headers_all         xoha            -- 受注ヘッダアドオン
          -- 積載重量合計
          SET     xoha.sum_weight                 = ln_update_sum_weight,
          -- 積載容積合計
                  xoha.sum_capacity               = ln_update_sum_capacity,
          -- 重量積載効率
                  xoha.loading_efficiency_weight  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start 変更要求#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_weight
--                     ELSE
--                       xoha.loading_efficiency_weight
                     -- 運賃区分「1」の場合、処理で取得した値を更新
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_weight
                     -- 上記以外の場合、NULLを更新
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
          -- 容積積載効率
                  xoha.loading_efficiency_capacity  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start 変更要求#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_capacity
--                     ELSE
--                       xoha.loading_efficiency_capacity
                     -- 運賃区分「1」の場合、処理で取得した値を更新
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_capacity
                     -- 上記以外の場合、NULLを更新
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
-- 2008/08/07 H.Itou Add Start 変更要求#173
          -- 基本重量
                  xoha.based_weight =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_weight
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 基本容積
                  xoha.based_capacity =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.based_capacity
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 配送区分
                  xoha.shipping_method_code =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.shipping_method_code
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 配送区分_実績
                  xoha.result_shipping_method_code =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         xoha.result_shipping_method_code
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
-- 2008/08/07 H.Itou Add End
                  xoha.last_updated_by           =  ln_user_id,
                  xoha.last_update_date          =  ld_sysdate,
                  xoha.last_update_login         =  ln_login_id,
                  xoha.request_id                =  ln_conc_request_id,
                  xoha.program_application_id    =  ln_prog_appl_id,
                  xoha.program_id                =  ln_conc_program_id,
                  xoha.program_update_date       =  ld_sysdate
          WHERE   xoha.order_header_id           =  ln_order_header_id;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_xoha,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    -- **************************************************
    -- *** 3.業務種別が移動の場合
    -- **************************************************
    ELSIF (iv_biz_type = cv_move) THEN
--
      BEGIN
--
        BEGIN
          -- (1)移動依頼/指示ヘッダ(アドオン)から項目を取得
          -- ロックを取得する
          SELECT  mrih.status,                            -- ステータス
                  --mrih.actual_shipping_method_code,       -- 配送区分_実績
                  NVL(mrih.actual_shipping_method_code,
                      mrih.shipping_method_code),         -- 配送区分_実績、NULLのときは、配送区分を取得
                  mrih.delivery_no,                       -- 配送No
                  mrih.mov_hdr_id,                        -- 移動ヘッダID
                  mrih.shipped_locat_code,                -- 出庫元保管場所
                  mrih.ship_to_locat_code,                -- 入庫先保管場所
                  mrih.product_flg,                       -- 製品識別区分
                  --mrih.actual_ship_date,                  -- 出庫実績日
                  NVL(mrih.actual_ship_date,
                      mrih.schedule_ship_date),           -- 出庫実績日、NULLのときは、出庫予定日を取得
                  mrih.item_class,                        -- 商品区分
                  --mrih.out_pallet_qty                     -- パレット枚数（出）
                  NVL(mrih.out_pallet_qty, 0)             -- パレット枚数（出）、NULLのときは、0を設定
-- 2008/08/07 H.Itou Add Start 変更要求#173 運賃区分取得追加
                 ,mrih.freight_charge_class               -- 運賃区分
-- 2008/08/07 H.Itou Add End
          INTO    lv_status,
                  lv_actual_shipping_method_code,
                  lv_delivery_no,
                  ln_mov_hdr_id,
                  lv_shipped_locat_code,
                  lv_ship_to_locat_code,
                  lv_product_flg,
                  ld_actual_ship_date,
                  lv_item_class,
                  ln_out_pallet_qty
-- 2008/08/07 H.Itou Add Start 変更要求#173 運賃区分取得追加
                 ,lv_freight_charge_class
-- 2008/08/07 H.Itou Add End
          FROM    xxinv_mov_req_instr_headers      mrih   -- 移動依頼/指示ヘッダ(アドオン)
          WHERE   mrih.mov_num             =    iv_request_no
          FOR UPDATE OF mrih.mov_hdr_id NOWAIT;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        -- 取得したステータスが｢出庫報告有｣、｢入出庫報告有｣以外の場合は
        -- 返り値に0：成功OR対象外を返し終了
        IF (lv_status NOT IN (cv_shiped_report, cv_delivery_report)) THEN
          RETURN gn_status_normal;
        END IF;
--
        -- 取得した配送Noを配車配送計画更新項目としてセット
        lv_update_delivery_no := lv_delivery_no;
--
        BEGIN
        -- カウント変数の初期化
        ln_counter := 0;
--
          -- (3)移動依頼/指示明細(アドオン)、OPM品目マスタから項目を取得
          -- ロックを取得する
          <<move_loop>>
          FOR get_move_data IN move_cur LOOP
            lt_move_tab(ln_counter).shipped_quantity := get_move_data.shipped_quantity;
            lt_move_tab(ln_counter).item_code        := get_move_data.item_code;
            lt_move_tab(ln_counter).conv_unit        := get_move_data.conv_unit;
            lt_move_tab(ln_counter).num_of_cases     := get_move_data.num_of_cases;
            lt_move_tab(ln_counter).num_of_deliver   := get_move_data.num_of_deliver;
            lt_move_tab(ln_counter).mov_line_id      := get_move_data.mov_line_id;
--
            -- (4)共通関数｢積載効率チェック(合計値算出)｣を呼び出す
            xxwsh_common910_pkg.calc_total_value(
              lt_move_tab(ln_counter).item_code,        -- 品目
              lt_move_tab(ln_counter).shipped_quantity, -- 出荷実績数量
              lv_retcode,                               -- リターンコード
              lv_errmsg_code,                           -- エラーメッセージコード
              lv_errmsg,                                -- エラーメッセージ
              ln_sum_weight,                            -- 合計重量
              ln_sum_capacity,                          -- 合計容積
              ln_sum_pallet_weight,                     -- 合計パレット重量
-- 2008/10/06 H.Itou Add Start 統合テスト指摘240 INパラメータ.基準日を追加
              ld_actual_ship_date,                      -- 出庫日
-- 2008/10/06 H.Itou Add End
-- 2008/11/13 H.Itou Add Start 統合テスト指摘311
              cv_mode_result                            -- 指示/実績区分 2:実績 固定
-- 2008/11/13 H.Itou Add End
              );
--
            -- リターンコードが'1'(異常)の場合は返り値に1：処理エラーを返し終了
            IF (lv_retcode = gn_status_error) THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_calc_total_value,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, lv_errmsg);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- 正常時は更新項目に値を追加
            ELSE
-- 2008/08/07 H.Itou Add Start 変更要求#173 積載重量合計・積載容積合計がNULLにならないように、NVLする。
              ln_sum_weight        := NVL(ln_sum_weight, 0);       -- 合計重量
              ln_sum_capacity      := NVL(ln_sum_capacity, 0);     -- 合計容積
              ln_sum_pallet_weight := NVL(ln_sum_pallet_weight, 0);-- 合計パレット数
-- 2008/08/07 H.Itou Add End
              -- 【明細更新項目】
              lt_update_tbl(ln_counter).update_weight         :=  ln_sum_weight;
              lt_update_tbl(ln_counter).update_capacity       :=  ln_sum_capacity;
              lt_update_tbl(ln_counter).update_pallet_weight  :=  ln_sum_pallet_weight;
              lt_update_tbl(ln_counter).update_line_id :=  lt_move_tab(ln_counter).mov_line_id;
--
              --【ヘッダ更新項目】
              ln_update_sum_weight        :=  NVL(ln_update_sum_weight, 0)   + ln_sum_weight;
              ln_update_sum_capacity      :=  NVL(ln_update_sum_capacity, 0) + ln_sum_capacity;
--2008/12/16 1.36 Mod Start 明細数分加算しているのを修正
--              ln_update_sum_pallet_weight :=  NVL(ln_update_sum_pallet_weight, 0)
--                                              + (ln_out_pallet_qty * ln_pallet_waight);
              ln_update_sum_pallet_weight := (NVL(ln_out_pallet_qty,0) * NVL(ln_pallet_waight,0));
--2008/12/16 1.36 Mod End

--
              -- ①(1)で取得した製品識別区分が｢製品｣以外の場合
              IF (lv_product_flg <> cv_product) THEN
-- Ver1.37 M.Hokkanji Start
                ln_update_small_quantity := NVL(ln_update_small_quantity, 0);
                --NULL;
-- Ver1.37 M.Hokkanji End
--
              -- ②(3)で取得した出庫実績数量が0の場合
              ELSIF (lt_move_tab(ln_counter).shipped_quantity = 0) THEN
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
                                              + lt_move_tab(ln_counter).shipped_quantity;
--
              -- ③(3)で取得した出荷入数が設定されている場合
-- 2008/08/07 H.Itou Mod Start 内部課題#32 出荷入数 > 0 に条件変更。
--              ELSIF (lt_move_tab(ln_counter).num_of_deliver IS NOT NULL) THEN
              ELSIF (lt_move_tab(ln_counter).num_of_deliver > 0 ) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start 変更要求#166 明細単位で整数に切り上げ、合計する。
--                                              + ROUND(lt_move_tab(ln_counter).shipped_quantity
                                              + CEIL(lt_move_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                              / lt_move_tab(ln_counter).num_of_deliver);
--
-- 2008/08/07 H.Itou Mod Start 内部課題#32 入出庫換算単位 IS NOT NULL に条件変更。
              -- ④(3)で取得したケース入数が設定されている場合
--              ELSIF (lt_move_tab(ln_counter).num_of_cases IS NOT NULL) THEN
              ELSIF (lt_move_tab(ln_counter).conv_unit IS NOT NULL) THEN
-- 2008/08/07 H.Itou Mod End
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start 変更要求#166 明細単位で整数に切り上げ、合計する。
--                                              + ROUND(lt_move_tab(ln_counter).shipped_quantity
                                              + CEIL(lt_move_tab(ln_counter).shipped_quantity
-- 2008/08/07 H.Itou Mod End
                                              / lt_move_tab(ln_counter).num_of_cases);
--
              -- ⑤いずれの条件にも当てはまらない場合
              ELSE
                ln_update_small_quantity  :=  NVL(ln_update_small_quantity, 0)
-- 2008/08/07 H.Itou Mod Start 変更要求#166 明細単位で整数に切り上げ、合計する。
--                                              + lt_move_tab(ln_counter).shipped_quantity;
                                             + CEIL(lt_move_tab(ln_counter).shipped_quantity);
-- 2008/08/07 H.Itou Mod End
--
              END IF;
--
            END IF;
--
            -- カウント変数をインクリメント
            ln_counter := ln_counter + 1;
--
          END LOOP move_loop;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                      cv_tkn_table, cv_mov_lines_item_mst,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_mril_im,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, SQLERRM);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        -- 変数初期化
        lv_retcode      :=NULL;   -- リターンコード
        lv_errmsg_code  :=NULL;   -- エラーメッセージコード
        lv_errmsg       :=NULL;   -- エラーメッセージ
--
-- 2008/08/07 H.Itou Mod Start 変更要求#173 積載効率算出条件は、配送Noではなく、運賃区分で判定
--        -- (5)(1)で配送Noが設定されている場合、共通関数｢積載効率チェック(積載効率算出)｣を呼び出す
--        IF (lv_update_delivery_no IS NOT NULL) THEN
        -- 運賃区分「1」の場合
        IF (lv_freight_charge_class = gv_freight_charge_yes) THEN
-- 2008/08/07 H.Itou Mod End
-- 2008/08/07 H.Itou Del Start 変更要求#173 重量積載効率算出は積載合計重量の値に関わらず算出する。
--          -- 合計重量が設定されている場合
--          IF (ln_update_sum_weight > 0) THEN
-- 2008/08/07 H.Itou Del End
--
          BEGIN
            -- 取得した配送区分_実績をもとにクイックコード｢XXCMN_SHIP_METHOD｣から小口区分を取得
            SELECT  xsm2.small_amount_class
            INTO    lv_small_sum_class
            FROM    xxwsh_ship_method2_v    xsm2
            WHERE   xsm2.ship_method_code   =  lv_actual_shipping_method_code
            AND     xsm2.start_date_active  <= ld_actual_ship_date
            AND     ld_actual_ship_date     <= NVL(xsm2.end_date_active, ld_actual_ship_date);
--
          EXCEPTION
            -- 取得できなかった場合は返り値に1：処理エラーを返し終了
            WHEN NO_DATA_FOUND THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_err,
                                                        cv_tkn_table, cv_small_sum_class,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
              RETURN gn_status_error;
--
            -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
            WHEN OTHERS THEN
              lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                        cv_tkn_api_name, cv_api_small_sum_class,
                                                        cv_tkn_type, lv_tkn_biz_type,
                                                        cv_tkn_no_type, lv_tkn_request_no,
                                                        cv_tkn_request_no, iv_request_no,
                                                        cv_tkn_err_msg, SQLERRM);
              FND_LOG.STRING(cv_log_level,gv_pkg_name
                            || cv_colon
                            || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END;
--
          -- 重量積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            (CASE
              -- ①(2)で取得した小口区分が｢対象｣の場合
              WHEN (lv_small_sum_class = cv_include) THEN
                ln_update_sum_weight
              -- ②(2)で取得した小口区分が｢対象｣以外の場合
              ELSE
                ln_update_sum_weight + NVL(ln_update_sum_pallet_weight, 0)
            END),                                     -- 1.合計重量
            NULL,                                     -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            lv_shipped_locat_code,                    -- 4.入出庫場所コード１
            cv_whse,                                  -- 5.コード区分２
            lv_ship_to_locat_code,                    -- 6.入出庫場所コード２
            lv_actual_shipping_method_code,           -- 7.出荷方法
            lv_item_class,                            -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_actual_ship_date,                      -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した重量積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 重量積載効率算出は積載合計重量の値に関わらず算出する。
--          END IF;
-- 2008/08/07 H.Itou Del End
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 容積積載効率算出は積載合計容積の値に関わらず算出する。
--          -- 合計容積が設定されている場合
--          IF (ln_update_sum_capacity > 0) THEN
-- 2008/08/07 H.Itou Del End
          -- 容積積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.合計重量
            ln_update_sum_capacity,                   -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            lv_shipped_locat_code,                    -- 4.入出庫場所コード１
            cv_whse,                                  -- 5.コード区分２
            lv_ship_to_locat_code,                    -- 6.入出庫場所コード２
            lv_actual_shipping_method_code,           -- 7.出荷方法
            lv_item_class,                            -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_actual_ship_date,                      -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した容積積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
-- 2008/08/07 H.Itou Del Start 変更要求#173 容積積載効率算出は積載合計容積の値に関わらず算出する。
--          END IF;
-- 2008/08/07 H.Itou Del End
--
        END IF;
--
        BEGIN
          <<mov_lines_update_loop>>
          FOR i IN lt_update_tbl.FIRST .. lt_update_tbl.LAST LOOP
            -- (6)移動依頼/指示明細(アドオン)を明細更新項目に登録されている内容で更新
            UPDATE  xxinv_mov_req_instr_lines       mril            -- 移動依頼/指示明細(アドオン)
            SET     mril.weight                   =  lt_update_tbl(i).update_weight,
                    mril.capacity                 =  lt_update_tbl(i).update_capacity,
                    mril.pallet_weight            =  lt_update_tbl(i).update_pallet_weight,
                    mril.last_updated_by          =  ln_user_id,
                    mril.last_update_date         =  ld_sysdate,
                    mril.last_update_login        =  ln_login_id,
                    mril.request_id               =  ln_conc_request_id,
                    mril.program_application_id   =  ln_prog_appl_id,
                    mril.program_id               =  ln_conc_program_id,
                    mril.program_update_date      =  ld_sysdate
            WHERE   mril.mov_line_id              =  lt_update_tbl(i).update_line_id;
--
          END LOOP mov_lines_update_loop;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_mril,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (7)移動依頼/指示ヘッダ(アドオン)をヘッダ更新項目に登録されている内容で更新
          UPDATE  xxinv_mov_req_instr_headers       mrih            -- 移動依頼/指示ヘッダ(アドオン)
          -- 積載重量合計
          SET     mrih.sum_weight         = ln_update_sum_weight,
          -- 積載容積合計
                  mrih.sum_capacity       = ln_update_sum_capacity,
          -- 合計パレット重量
                  mrih.sum_pallet_weight  = ln_update_sum_pallet_weight,
          -- 小口個数
                  mrih.small_quantity    =
                   (CASE
                     WHEN (lv_product_flg = cv_product) THEN
                       ln_update_small_quantity
                     ELSE
                       mrih.small_quantity
                   END),
          -- 重量積載効率
                  mrih.loading_efficiency_weight =
                   (CASE
-- 2008/08/07 H.Itou Mod Start 変更要求#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_weight
--                     ELSE
--                       mrih.loading_efficiency_weight
                     -- 運賃区分「1」の場合、処理で取得した値を更新
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_weight
                     -- 上記以外の場合、NULLを更新
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
          -- 容積積載効率
                  mrih.loading_efficiency_capacity  =
                   (CASE
-- 2008/08/07 H.Itou Mod Start 変更要求#173
--                     WHEN (lv_update_delivery_no IS NOT NULL) THEN
--                       ln_update_load_effi_capacity
--                     ELSE
--                       mrih.loading_efficiency_capacity
                     -- 運賃区分「1」の場合、処理で取得した値を更新
                     WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                       ln_update_load_effi_capacity
                     -- 上記以外の場合、NULLを更新
                     ELSE
                       NULL
-- 2008/08/07 H.Itou Mod End
                   END),
-- 2008/08/07 H.Itou Add Start 変更要求#173
          -- 基本重量
                  mrih.based_weight =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.based_weight
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 基本容積
                  mrih.based_capacity =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.based_capacity
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 配送区分
                  mrih.shipping_method_code =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.shipping_method_code
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
          -- 配送区分_実績
                  mrih.actual_shipping_method_code =
                    (CASE
                       -- 運賃区分「1」の場合、更新しない（現在の値で更新）
                       WHEN (lv_freight_charge_class = gv_freight_charge_yes) THEN
                         mrih.actual_shipping_method_code
                       -- 上記以外の場合、NULLを更新
                       ELSE
                         NULL
                     END),
-- 2008/08/07 H.Itou Add End
                  mrih.last_updated_by           =  ln_user_id,
                  mrih.last_update_date          =  ld_sysdate,
                  mrih.last_update_login         =  ln_login_id,
                  mrih.request_id                =  ln_conc_request_id,
                  mrih.program_application_id    =  ln_prog_appl_id,
                  mrih.program_id                =  ln_conc_program_id,
                  mrih.program_update_date       =  ld_sysdate
          WHERE   mrih.mov_hdr_id                =  ln_mov_hdr_id;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_err,
                                                      cv_tkn_table, cv_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_err_msg, SQLERRM);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    END IF;
--
    -- **************************************************
    -- *** 4.配車配送計画更新
    -- **************************************************
    -- 変数初期化
    lv_result_shipping_method_code      := NULL;   -- 配送区分_実績
    lv_result_deliver_to                := NULL;   -- 出荷先_実績
    lv_deliver_from                     := NULL;   -- 出荷元保管場所
    lv_small_sum_class                  := NULL;   -- 小口区分
    ln_sum_weight                       := NULL;   -- 合計重量
    ln_sum_capacity                     := NULL;   -- 合計容積
    ln_sum_pallet_weight                := NULL;   -- 合計パレット重量
-- Ver1.46 M.Hokkanji Start
    ln_order_type_id                    := NULL;   -- 受注タイプID
    lv_weight_check_flag                := '0';    -- 積載率チェックフラグ
    ln_update_load_effi_capacity        := NULL;   -- 積載率(容積)
    ln_update_load_effi_weight          := NULL;   -- 積載率(重量)
-- Ver1.46 M.Hokkanji End
--
    -- 上記1.～3.の処理で配車配送計画更新項目.配送Noが設定されている場合
    IF (lv_update_delivery_no IS NOT NULL) THEN
--
      BEGIN
--
        BEGIN
          -- (1)配車配送計画（アドオン）から配送区分_実績、基準明細Noを取得
          -- ロックを取得する
          --SELECT  xcs.result_shipping_method_code,      -- 配送区分_実績
          SELECT  NVL(xcs.result_shipping_method_code,
                      xcs.delivery_type),               -- 配送区分_実績、NULLのときは、配送区分
                  xcs.default_line_number               -- 基準明細No
          INTO    lv_result_shipping_method_code,
                  lv_default_line_number
          FROM    xxwsh_carriers_schedule    xcs         -- 配車配送計画（アドオン）
          WHERE   xcs.delivery_no         =  lv_update_delivery_no
          FOR UPDATE OF xcs.transaction_id NOWAIT;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_xcs,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_xcs,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
          RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (2)積載効率算出に必要な項目を取得
          SELECT  xoha.vendor_site_code,                  -- 取引先サイト
                  xoha.deliver_from,                      -- 出荷元保管場所
                  --xoha.result_deliver_to,                 -- 出荷先_実績
                  NVL(xoha.result_deliver_to,
                      xoha.deliver_to),                   -- 出荷先_実績、NULLのときは、出荷先を取得
                  xott.shipping_shikyu_class,             -- 出荷支給区分
                  --xoha.shipped_date,                      -- 出荷日
                  NVL(xoha.shipped_date,
                      xoha.schedule_ship_date),           -- 出荷日、NULLのときは、出荷予定日を取得
                  xoha.prod_class                         -- 商品区分
-- Ver1.46 M.Hokkanji Start
                 ,xoha.order_type_id                      -- 受注タイプID
-- Ver1.46 M.Hokkanji End
          INTO    lv_vendor_site_code,
                  lv_deliver_from,
                  lv_result_deliver_to,
                  lv_attribute1,
                  ld_date,
                  lv_syohin_class
-- Ver1.46 M.Hokkanji Start
                 ,ln_order_type_id
-- Ver1.46 M.Hokkanji End
          FROM    xxwsh_order_headers_all       xoha,       -- 受注ヘッダアドオン
                  xxwsh_oe_transaction_types_v  xott        -- 受注タイプ情報VIEW
          WHERE   xoha.request_no                             =  lv_default_line_number
          AND     xoha.order_type_id                          =  xott.transaction_type_id
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes;
--
          -- 上記処理で取得できた場合、処理種別をセット
          -- ①出荷支給区分が｢出荷依頼｣の場合
          IF (lv_attribute1 = cv_ship_req) THEN
            lv_process_class := cv_ship;
          -- ②出荷支給区分が｢支給依頼｣の場合
          ELSIF (lv_attribute1 = cv_supply_req) THEN
            lv_process_class := cv_supply;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              -- 上記処理で取得できなかった場合、積載効率算出に必要な項目を取得
              SELECT  mrih.shipped_locat_code,                -- 出庫元保管場所
                      mrih.ship_to_locat_code,                -- 入庫先保管場所
                      --mrih.actual_ship_date,                  -- 出庫実績日
                      NVL(mrih.actual_ship_date,
                          mrih.schedule_ship_date),           -- 出庫実績日、NULLのときは、出庫予定日を取得
                      mrih.item_class                         -- 商品区分
              INTO    lv_shipped_locat_code,
                      lv_ship_to_locat_code,
                      ld_date,
                      lv_syohin_class
              FROM    xxinv_mov_req_instr_headers      mrih   -- 移動依頼/指示ヘッダ(アドオン)
              WHERE   mrih.mov_num                =  lv_default_line_number;
--
              -- 上記処理で取得できた場合、処理種別に｢移動｣をセット
                lv_process_class := cv_move;
--
            EXCEPTION
              -- 取得できなかった場合は返り値に1：処理エラーを返し終了
              WHEN NO_DATA_FOUND THEN
                -- セーブポイントへロールバック
                ROLLBACK TO advance_sp;
                lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_carriers_info,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
                FND_LOG.STRING(cv_log_level,gv_pkg_name
                              || cv_colon
                              || cv_prg_name,lv_except_msg);
                RETURN gn_status_error;
--
              -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
              WHEN OTHERS THEN
                -- セーブポイントへロールバック
                ROLLBACK TO advance_sp;
                lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_carriers_info,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
                FND_LOG.STRING(cv_log_level,gv_pkg_name
                              || cv_colon
                              || cv_prg_name,lv_except_msg);
                RETURN gn_status_error;
--
            END;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
                lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_carriers_info,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (3)取得した配送区分_実績をもとにクイックコード｢XXCMN_SHIP_METHOD｣から小口区分を取得
          SELECT  xsm2.small_amount_class
          INTO    lv_small_sum_class
          FROM    xxwsh_ship_method2_v    xsm2
          WHERE   xsm2.ship_method_code   =  lv_result_shipping_method_code
          AND     xsm2.start_date_active  <= ld_date
          AND     ld_date                 <= NVL(xsm2.end_date_active, ld_date);
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_small_sum_class,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_small_sum_class,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        BEGIN
          -- (4)各ヘッダの積載重量合計、積載容積合計、合計パレット重量の合計値を取得
          SELECT  SUM(xomh.sum_weight),
                  SUM(xomh.sum_capacity),
                  SUM(xomh.sum_pallet_weight)
          INTO    ln_sum_weight,
                  ln_sum_capacity,
                  ln_sum_pallet_weight
          FROM
            ((SELECT xoha.sum_weight,
                    xoha.sum_capacity,
                    xoha.sum_pallet_weight
            FROM    xxwsh_order_headers_all         xoha
            WHERE   xoha.delivery_no                            =  lv_update_delivery_no
            AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes)
            UNION ALL
            (SELECT mrih.sum_weight,
                    mrih.sum_capacity,
                    mrih.sum_pallet_weight
            FROM    xxinv_mov_req_instr_headers     mrih
            WHERE   mrih.delivery_no            =  lv_update_delivery_no)) xomh;
--
        EXCEPTION
          -- 取得できなかった場合は返り値に1：処理エラーを返し終了
          WHEN NO_DATA_FOUND THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_get_carry_err,
                                                      cv_tkn_table, cv_order_mov_headers,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_xoha_mrih,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
        -- (5)配車配送計画更新項目をセット
        -- 積載重量合計
        -- ①(3)で取得した小口区分が｢対象｣の場合
        IF (lv_small_sum_class = cv_include) THEN
          ln_update_weight := ln_sum_weight;
        -- ②(3)で取得した小口区分が｢対象｣以外の場合
        ELSE
          ln_update_weight := ln_sum_weight + ln_sum_pallet_weight;
        END IF;
--
        -- 積載容積合計
        ln_update_capacity := ln_sum_capacity;
--
-- Ver1.46 M.Hokkanji Start
        -- 基準明細が庭先出庫の場合は積載率算出を行わない
        IF (ln_order_type_id = ln_transaction_id_spot_sale) THEN
          lv_weight_check_flag := '1';
        END IF;
-- Ver1.46 M.Hokkanji End
--
        -- 変数初期化
        lv_retcode      :=NULL;   -- リターンコード
        lv_errmsg_code  :=NULL;   -- エラーメッセージコード
        lv_errmsg       :=NULL;   -- エラーメッセージ
--
-- Ver1.46 M.Hokkanji Start
        -- (6)共通関数｢積載効率チェック(積載効率算出)｣を呼び出す
        -- 合計重量が設定されている場合
        -- 基準明細の出庫形態が庭先出庫以外の場合
--        IF (ln_sum_weight IS NOT NULL) THEN
        IF (ln_sum_weight IS NOT NULL) AND
           (lv_weight_check_flag = '0') THEN
-- Ver1.46 M.Hokkanji End
          -- ①重量積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            ln_sum_weight,                         -- 1.合計重量
            NULL,                                  -- 2.合計容積
            cv_whse,                               -- 3.コード区分１
            (CASE
              -- ①(2)で取得した処理種別が出荷もしくは支給の場合
              WHEN (lv_process_class IN (cv_ship_req, cv_supply_req)) THEN
                lv_deliver_from
              -- ②(2)で取得した処理種別が移動の場合
              WHEN (lv_process_class = cv_move_req) THEN
                lv_shipped_locat_code
            END),                                     -- 4.入出庫場所コード１
            (CASE
              -- ①(2)で取得した処理種別が出荷の場合
              WHEN (lv_process_class = cv_ship_req) THEN
                cv_deliver_to
              -- ②(2)で取得した処理種別が支給の場合
              WHEN (lv_process_class = cv_supply_req) THEN
                cv_supply_to
              -- ③(2)で取得した処理種別が移動の場合
              WHEN (lv_process_class = cv_move_req) THEN
                cv_whse
            END),                                     -- 5.コード区分２
            (CASE
              -- ①(2)で取得した処理種別が出荷の場合
              WHEN (lv_process_class = cv_ship_req) THEN
                lv_result_deliver_to
              -- ②(2)で取得した処理種別が支給の場合
              WHEN (lv_process_class = cv_supply_req) THEN
                lv_vendor_site_code
              -- ③(2)で取得した処理種別が移動の場合
              WHEN (lv_process_class = cv_move_req) THEN
                lv_ship_to_locat_code
            END),                                     -- 6.入出庫場所コード２
            lv_result_shipping_method_code,           -- 7.出荷方法
            lv_syohin_class,                          -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_date,                                  -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_weight,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した重量積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_weight := ln_load_efficiency_weight;
--
        END IF;
--
-- Ver1.46 M.Hokkanji Start
        -- 合計容積が設定されている場合
        -- 基準明細の出庫形態が庭先出庫以外の場合
--        IF (ln_sum_capacity > 0) THEN
        IF (ln_sum_capacity IS NOT NULL) AND
           (lv_weight_check_flag = '0') THEN
-- Ver1.46 M.Hokkanji End
          -- ②容積積載効率算出
          xxwsh_common910_pkg.calc_load_efficiency(
            NULL,                                     -- 1.合計重量
            ln_sum_capacity,                          -- 2.合計容積
            cv_whse,                                  -- 3.コード区分１
            (CASE
              -- ①(2)で取得した処理種別が出荷もしくは支給の場合
              WHEN (lv_process_class IN (cv_ship_req, cv_supply_req)) THEN
                lv_deliver_from
              -- ②(2)で取得した処理種別が移動の場合
              WHEN (lv_process_class = cv_move_req) THEN
                lv_shipped_locat_code
            END),                                     -- 4.入出庫場所コード１
            (CASE
              -- ①(2)で取得した処理種別が出荷の場合
              WHEN (lv_process_class = cv_ship_req) THEN
                cv_deliver_to
              -- ②(2)で取得した処理種別が支給の場合
              WHEN (lv_process_class = cv_supply_req) THEN
                cv_supply_to
              -- ③(2)で取得した処理種別が移動の場合
              WHEN (lv_process_class = cv_move_req) THEN
                cv_whse
            END),                                     -- 5.コード区分２
            (CASE
              -- ①(2)で取得した処理種別が出荷の場合
              WHEN (lv_process_class = cv_ship_req) THEN
                lv_result_deliver_to
              -- ②(2)で取得した処理種別が支給の場合
              WHEN (lv_process_class = cv_supply_req) THEN
                lv_vendor_site_code
              -- ③(2)で取得した処理種別が移動の場合
              WHEN (lv_process_class = cv_move_req) THEN
                lv_ship_to_locat_code
            END),                                     -- 6.入出庫場所コード２
            lv_result_shipping_method_code,           -- 7.出荷方法
            lv_syohin_class,                          -- 8.商品区分
            NULL,                                     -- 9.自動配車対象区分
            ld_date,                                  -- 10.基準日(適用日基準日)
            lv_retcode,                               -- 11.リターンコード
            lv_errmsg_code,                           -- 12.エラーメッセージコード
            lv_errmsg,                                -- 13.エラーメッセージ
            lv_loading_over_class,                    -- 14.積載オーバー区分
            lv_ship_methods,                          -- 15.出荷方法
            ln_load_efficiency_weight,                -- 16.重量積載効率
            ln_load_efficiency_capacity,              -- 17.容積積載効率
            lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合は返り値に1：エラーを返し終了
          IF (lv_retcode = gn_status_error) THEN
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                      cv_tkn_api_name, cv_api_capacity,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number,
                                                      cv_tkn_err_msg, lv_errmsg);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
          END IF;
--
          -- 取得した容積積載効率をヘッダ更新用項目にセット
          ln_update_load_effi_capacity := ln_load_efficiency_capacity;
--
        END IF;
--
        BEGIN
          -- (7)配車配送計画(アドオン)を更新項目に登録されている内容で更新
          UPDATE  xxwsh_carriers_schedule       xcs         -- 配車配送計画（アドオン）
          SET     xcs.sum_loading_weight          =  ln_update_weight,             -- 積載重量合計
                  xcs.sum_loading_capacity        =  ln_update_capacity,           -- 積載容積合計
                  xcs.loading_efficiency_weight   =  ln_update_load_effi_weight,   -- 重量積載効率
                  xcs.loading_efficiency_capacity =  ln_update_load_effi_capacity, -- 容積積載効率
                  xcs.last_updated_by             =  ln_user_id,
                  xcs.last_update_date            =  ld_sysdate,
                  xcs.last_update_login           =  ln_login_id,
                  xcs.request_id                  =  ln_conc_request_id,
                  xcs.program_application_id      =  ln_prog_appl_id,
                  xcs.program_id                  =  ln_conc_program_id,
                  xcs.program_update_date         =  ld_sysdate
          WHERE   xcs.delivery_no                 =  lv_update_delivery_no;
--
        EXCEPTION
          -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
          WHEN OTHERS THEN
            -- セーブポイントへロールバック
            ROLLBACK TO advance_sp;
            lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_update_carry_err,
                                                      cv_tkn_table, cv_xcs,
                                                      cv_tkn_type, lv_tkn_biz_type,
                                                      cv_tkn_no_type, lv_tkn_request_no,
                                                      cv_tkn_request_no, iv_request_no,
                                                      cv_tkn_def_line_num, lv_default_line_number);
            FND_LOG.STRING(cv_log_level,gv_pkg_name
                          || cv_colon
                          || cv_prg_name,lv_except_msg);
            RETURN gn_status_error;
--
        END;
--
      EXCEPTION
        -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
        WHEN OTHERS THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_carry_err,
                                                    cv_tkn_api_name, cv_api_update_line_item,
                                                    cv_tkn_type, lv_tkn_biz_type,
                                                    cv_tkn_no_type, lv_tkn_request_no,
                                                    cv_tkn_request_no, iv_request_no,
                                                    cv_tkn_def_line_num, lv_default_line_number);
          FND_LOG.STRING(cv_log_level,gv_pkg_name
                        || cv_colon
                        || cv_prg_name,lv_except_msg);
        RETURN gn_status_error;
--
      END;
--
    END IF;
--
    RETURN gn_status_normal;
--
  EXCEPTION
    -- ロック処理エラー
    WHEN lock_expt THEN
      -- セーブポイントへロールバック
      ROLLBACK TO advance_sp;
      lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                cv_tkn_api_name, cv_api_lock,
                                                cv_tkn_type, lv_tkn_biz_type,
                                                cv_tkn_no_type, lv_tkn_request_no,
                                                cv_tkn_request_no, iv_request_no,
                                                cv_tkn_err_msg, SQLERRM);
      FND_LOG.STRING(cv_log_level,gv_pkg_name
                    || cv_colon
                    || cv_prg_name,lv_except_msg);
      -- 返り値に1：処理エラーを返し終了
      RETURN gn_status_error;
--
    -- その他の例外が発生した場合は返り値に1：処理エラーを返し終了
    WHEN OTHERS THEN
      -- セーブポイントへロールバック
      ROLLBACK TO advance_sp;
      lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_api_err,
                                                cv_tkn_api_name, cv_api_update_line_item,
                                                cv_tkn_type, lv_tkn_biz_type,
                                                cv_tkn_no_type, lv_tkn_request_no,
                                                cv_tkn_request_no, iv_request_no,
                                                cv_tkn_err_msg, SQLERRM);
      FND_LOG.STRING(cv_log_level,gv_pkg_name
                    || cv_colon
                    || cv_prg_name,lv_except_msg);
      RETURN gn_status_error;
--
--###############################  固定例外処理部 START   ###################################
--
--    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END update_line_items;
--
  /**********************************************************************************
   * Function Name    : cancel_reserve
   * Description      : 引当解除関数
   ***********************************************************************************/
  FUNCTION cancel_reserve(
    iv_biz_type             IN         VARCHAR2,                              -- 1.業務種別
    iv_request_no           IN         VARCHAR2,                              -- 2.依頼No/移動番号
    in_line_id              IN         NUMBER,                                -- 3.明細ID
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 4.エラーメッセージ
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'cancel_reserve';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';               -- YES
    cv_flag_no             CONSTANT VARCHAR2(1)   := 'N';               -- NO
    cv_enc_cancel_err      CONSTANT VARCHAR2(2)   := '-1';              -- 引当解除失敗
    cv_compl               CONSTANT VARCHAR2(1)   := '0';               -- 成功
    cv_para_check_err      CONSTANT VARCHAR2(1)   := '1';               -- パラメータチェックエラー
    cv_enc_cancel_nodata   CONSTANT VARCHAR2(1)   := '2';               -- 引当解除データ無し
-- 2009/01/14 Y.Yamamoto #991 add start
    cv_sub_check_warn      CONSTANT VARCHAR2(1)   := '3';               -- 減数チェックワーニング
-- 2009/01/14 Y.Yamamoto #991 add end
    cv_ship                CONSTANT VARCHAR2(1)   := '1';               -- 出荷
    cv_supply              CONSTANT VARCHAR2(1)   := '2';               -- 支給
    cv_move                CONSTANT VARCHAR2(1)   := '3';               -- 移動
    cv_ship_req            CONSTANT VARCHAR2(1)   := '1';               -- 出荷依頼
    cv_supply_req          CONSTANT VARCHAR2(1)   := '2';               -- 支給依頼
    cv_cate_order          CONSTANT VARCHAR2(10)  := 'ORDER';           -- 受注
    cv_cate_return         CONSTANT VARCHAR2(10)  := 'RETURN';          -- 返品
    cv_auto_enc            CONSTANT VARCHAR2(2)   := '10';              -- 自動引当
    cv_ship_req_type       CONSTANT VARCHAR2(2)   := '10';              -- 出荷依頼
    cv_supply_instr_type   CONSTANT VARCHAR2(2)   := '30';              -- 支給指示
    cv_move_type           CONSTANT VARCHAR2(2)   := '20';              -- 移動
    cv_instr_rec_type      CONSTANT VARCHAR2(2)   := '10';              -- 指示
    cv_app_name_xxcmn      CONSTANT VARCHAR2(5)   := 'XXCMN';           -- アプリケーション短縮名
    cv_app_name_xxwsh      CONSTANT VARCHAR2(5)   := 'XXWSH';           -- アプリケーション短縮名
    cv_msg_para_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10001'; -- パラメータ指定不正
    cv_msg_object_nodata   CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10002'; -- 対象データ無し
    cv_msg_xmld_del_err    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10003'; -- 移動ロット詳細削除失敗
    cv_msg_xola_update_err CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10004'; -- 受注明細アドオン更新失敗
    cv_msg_supply_chk_warn CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10111'; -- 供給数の減数チェック警告
    cv_msg_mril_update_err CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10005'; -- 移動依頼/指示明細更新失敗
    cv_msg_lock_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10006'; -- ロック処理エラー
--
    -- *** ローカル変数 ***
    ln_can_enc_qty                NUMBER;           -- 引当可能数
    ln_user_id                    NUMBER;           -- ログインしているユーザーのID取得
    ln_login_id                   NUMBER;           -- 最終更新ログイン
    ln_conc_request_id            NUMBER;           -- 要求ID
    ln_prog_appl_id               NUMBER;           -- プログラム・アプリケーションID
    ln_conc_program_id            NUMBER;           -- プログラムID
    ld_sysdate                    DATE;             -- システム現在日付
    TYPE dummy_tble IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    ln_dummy                      dummy_tble;       -- ロック用ダミー変数
--2008/09/03 Y.Kawano ADD Start
    lt_mov_line_id           xxinv_mov_req_instr_lines.mov_line_id%TYPE;             -- 移動明細ID
    lt_ship_to_locat_id      xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE;      -- 入庫先ID
    lt_schedule_arrival_date xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE; -- 入庫予定日
    lt_item_short_name       ic_item_mst_b.attribute25%TYPE;                         -- 保管場所名称
    lt_description           hr_locations_all.description%TYPE;                      -- 保管場所
--2008/09/03 Y.Kawano ADD End
-- 2009/05/07 H.Itou ADD START 本番障害#1443
   lv_retcode                     VARCHAR2(1);      -- リターンコード
-- 2009/05/07 H.Itou ADD END
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    lock_expt                  EXCEPTION;  -- ロック取得例外
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 入力パラメータチェック
    IF ((iv_biz_type  IS NULL) OR
       (iv_request_no IS NULL)) THEN
         -- パラメータ指定不正
         ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_para_err);
         RETURN cv_enc_cancel_err;                        -- 引当解除失敗
    END IF;
--
    -- WHOカラム情報取得
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    ld_sysdate           := SYSDATE;                      -- システム現在日付
--
    -- セーブポイントを取得します
    SAVEPOINT advance_sp;
--
    -- **************************************************
    -- *** 業務種別が出荷の場合
    -- **************************************************
    IF (iv_biz_type = cv_ship) THEN
      -- 検索処理を行います
      SELECT xola.order_line_id                             -- 受注明細アドオンID
      BULK COLLECT INTO
             gt_order_line_id_tbl
      FROM   xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
             xxwsh_order_lines_all              xola,       -- 受注明細アドオン
             xxwsh_oe_transaction_types_v       xott        -- 受注タイプ情報VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_ship_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      AND    xoha.order_header_id                       =  xola.order_header_id
      AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
      AND    xola.order_line_id                         =  NVL(in_line_id, xola.order_line_id)
      AND    xola.automanual_reserve_class              =  cv_auto_enc
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
      -- 取得できない場合はエラー
      IF (gt_order_line_id_tbl.COUNT = 0) THEN
        -- 対象データ無し
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_object_nodata);
        RETURN cv_enc_cancel_nodata;                    -- 引当解除データ無し
      END IF;
--
      <<gt_order_line_id_tbl_loop>>
      FOR i IN gt_order_line_id_tbl.FIRST .. gt_order_line_id_tbl.LAST LOOP
        BEGIN
          -- ロック処理を行います
          SELECT xmld.mov_lot_dtl_id
          BULK COLLECT INTO ln_dummy
          FROM   xxinv_mov_lot_details          xmld        -- 移動ロット詳細(アドオン)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_ship_req_type
          AND    xmld.record_type_code          =  cv_instr_rec_type
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
          -- 削除処理を行います
          DELETE
          FROM   xxinv_mov_lot_details          xmld        -- 移動ロット詳細(アドオン)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_ship_req_type
          AND    xmld.record_type_code          =  cv_instr_rec_type;
--
        EXCEPTION
          WHEN lock_expt THEN
            -- ロック処理エラー
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
            ROLLBACK TO advance_sp;                   -- エラーの場合はセーブポイントにロールバック
            RETURN cv_enc_cancel_err;                 -- 引当解除失敗
--
          WHEN OTHERS THEN
            -- 移動ロット詳細(アドオン)削除失敗
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xmld_del_err);
            ROLLBACK TO advance_sp;                   -- エラーの場合はセーブポイントにロールバック
            RETURN cv_enc_cancel_err;                 -- 引当解除失敗
--
        END;
--
        BEGIN
          -- 更新処理を行います
          UPDATE xxwsh_order_lines_all              xola        -- 受注明細アドオン
          SET    xola.reserved_quantity             =  NULL,    -- 引当数
                 xola.automanual_reserve_class      =  NULL,    -- 自動手動引当区分
                 xola.last_updated_by               =  ln_user_id,
                 xola.last_update_date              =  ld_sysdate,
                 xola.last_update_login             =  ln_login_id,
                 xola.request_id                    =  ln_conc_request_id,
                 xola.program_application_id        =  ln_prog_appl_id,
                 xola.program_id                    =  ln_conc_program_id,
                 xola.program_update_date           =  ld_sysdate
          WHERE  xola.order_line_id                 =  gt_order_line_id_tbl(i)
          AND    NVL(xola.delete_flag, cv_flag_no)  =  cv_flag_no;
--
        EXCEPTION
          -- エラーの場合はセーブポイントにロールバック
          WHEN OTHERS THEN
            -- 受注明細アドオン更新失敗
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xola_update_err);
            ROLLBACK TO advance_sp;
            RETURN cv_enc_cancel_err;                       -- 引当解除失敗
--
        END;
--
      END LOOP gt_order_line_id_tbl_loop;
--
      -- 正常終了の場合
      RETURN cv_compl;
--
    -- **************************************************
    -- *** 業務種別が支給の場合
    -- **************************************************
    ELSIF (iv_biz_type = cv_supply) THEN
      -- 検索処理を行います
      SELECT xola.order_line_id                             -- 受注明細アドオンID
      BULK COLLECT INTO
             gt_order_line_id_tbl
      FROM   xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
             xxwsh_order_lines_all              xola,       -- 受注明細アドオン
             xxwsh_oe_transaction_types_v       xott        -- 受注タイプ情報VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_supply_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      AND    xoha.order_header_id                       =  xola.order_header_id
      AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
      AND    xola.order_line_id                         =  NVL(in_line_id, xola.order_line_id)
      AND    xola.automanual_reserve_class              =  cv_auto_enc
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
      -- 取得できない場合はエラー
      IF (gt_order_line_id_tbl.COUNT = 0) THEN
        -- 対象データ無し
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_object_nodata);
        RETURN cv_enc_cancel_nodata;                    -- 引当解除データ無し
      END IF;
--
      <<gt_order_line_id_tbl_loop>>
      FOR i IN gt_order_line_id_tbl.FIRST .. gt_order_line_id_tbl.LAST LOOP
        BEGIN
          -- ロック処理を行います
          SELECT xmld.mov_lot_dtl_id
          BULK COLLECT INTO ln_dummy
          FROM   xxinv_mov_lot_details          xmld              -- 移動ロット詳細(アドオン)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_supply_instr_type
          AND    xmld.record_type_code          =  cv_instr_rec_type
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
          -- 削除処理を行います
          DELETE
          FROM   xxinv_mov_lot_details          xmld              -- 移動ロット詳細(アドオン)
          WHERE  xmld.mov_line_id               =  gt_order_line_id_tbl(i)
          AND    xmld.document_type_code        =  cv_supply_instr_type
          AND    xmld.record_type_code          =  cv_instr_rec_type;
--
        EXCEPTION
          WHEN lock_expt THEN
            -- ロック処理エラー
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
            ROLLBACK TO advance_sp;                   -- エラーの場合はセーブポイントにロールバック
            RETURN cv_enc_cancel_err;                 -- 引当解除失敗
--
          WHEN OTHERS THEN
            -- 移動ロット詳細(アドオン)削除失敗
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xmld_del_err);
            ROLLBACK TO advance_sp;                   -- エラーの場合はセーブポイントにロールバック
            RETURN cv_enc_cancel_err;                 -- 引当解除失敗
--
        END;
--
        BEGIN
          -- 更新処理を行います
          UPDATE xxwsh_order_lines_all              xola              -- 受注明細アドオン
          SET    xola.reserved_quantity             =  NULL,          -- 引当数
                 xola.automanual_reserve_class      =  NULL,          -- 自動手動引当区分
                 xola.last_updated_by               =  ln_user_id,
                 xola.last_update_date              =  ld_sysdate,
                 xola.last_update_login             =  ln_login_id,
                 xola.request_id                    =  ln_conc_request_id,
                 xola.program_application_id        =  ln_prog_appl_id,
                 xola.program_id                    =  ln_conc_program_id,
                 xola.program_update_date           =  ld_sysdate
          WHERE  xola.order_line_id                 =  gt_order_line_id_tbl(i)
          AND    NVL(xola.delete_flag, cv_flag_no)  =  cv_flag_no;
--
        EXCEPTION
          -- エラーの場合はセーブポイントにロールバック
          WHEN OTHERS THEN
            -- 受注明細アドオン更新失敗
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xola_update_err);
            ROLLBACK TO advance_sp;
            RETURN cv_enc_cancel_err;                             -- 引当解除失敗
--
        END;
--
      END LOOP gt_order_line_id_tbl_loop;
--
      -- 正常終了の場合
      RETURN cv_compl;
--
    -- **************************************************
    -- *** 業務種別が移動の場合
    -- **************************************************
    ELSIF (iv_biz_type = cv_move) THEN
      -- 検索処理を行います
      SELECT mril.mov_line_id,                                  -- 移動明細ID
             mrih.ship_to_locat_id,                             -- 入庫先ID
             mrih.schedule_arrival_date,                        -- 入庫予定日
             xim2.item_short_name,                              -- 品名・略称
             xilv.description                                   -- 保管場所名
      BULK COLLECT INTO
             gt_mov_req_instr_tbl
      FROM   xxinv_mov_req_instr_headers      mrih,             -- 移動依頼/指示ヘッダ(アドオン)
             xxinv_mov_req_instr_lines        mril,             -- 移動依頼/指示明細(アドオン)
             xxcmn_item_mst2_v                xim2,             -- OPM品目情報VIEW2
             xxcmn_item_locations_v           xilv              -- OPM保管場所情報VIEW
      WHERE  mrih.mov_num                     =  iv_request_no
      AND    mrih.mov_hdr_id                  =  mril.mov_hdr_id
      AND    NVL(mril.delete_flg, cv_flag_no) =  cv_flag_no
      AND    mril.mov_line_id                 =  NVL(in_line_id, mril.mov_line_id)
      AND    mril.automanual_reserve_class    =  cv_auto_enc
      AND    mril.item_id                     =  xim2.item_id
      AND    xim2.start_date_active           <= mrih.schedule_ship_date
      AND    mrih.schedule_ship_date          <= NVL(xim2.end_date_active, mrih.schedule_ship_date)
-- 2009/01/14 Y.Yamamoto #991 update start
--      AND    mrih.shipped_locat_id            =  xilv.inventory_location_id
      AND    mrih.ship_to_locat_id            =  xilv.inventory_location_id
-- 2009/01/14 Y.Yamamoto #991 update end
      FOR UPDATE OF mril.mov_line_id NOWAIT;
--
      -- 取得できない場合はエラー
      IF (gt_mov_req_instr_tbl.COUNT = 0) THEN
        -- 対象データ無し
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_object_nodata);
        RETURN cv_enc_cancel_nodata;                    -- 引当解除データ無し
      END IF;
--
      <<gt_mov_req_instr_tbl_loop>>
      FOR i IN gt_mov_req_instr_tbl.FIRST .. gt_mov_req_instr_tbl.LAST LOOP
--2008/09/03 Y.Kawano MOD Start
--        gt_mov_line_id_tbl(i)           := gt_mov_req_instr_tbl(i).mov_line_id;
--        gt_ship_to_locat_id_tbl(i)      := gt_mov_req_instr_tbl(i).ship_to_locat_id;
--        gt_schedule_arrival_date_tbl(i) := gt_mov_req_instr_tbl(i).schedule_arrival_date;
--        gt_item_short_name_tbl(i)       := gt_mov_req_instr_tbl(i).item_short_name;
--        gt_description_tbl(i)           := gt_mov_req_instr_tbl(i).description;
        --初期化
        lt_mov_line_id           := NULL;
        lt_ship_to_locat_id      := NULL;
        lt_schedule_arrival_date := NULL;
        lt_item_short_name       := NULL;
        lt_description           := NULL;
        --
        lt_mov_line_id           := gt_mov_req_instr_tbl(i).mov_line_id;
        lt_ship_to_locat_id      := gt_mov_req_instr_tbl(i).ship_to_locat_id;
        lt_schedule_arrival_date := gt_mov_req_instr_tbl(i).schedule_arrival_date;
        lt_item_short_name       := gt_mov_req_instr_tbl(i).item_short_name;
        lt_description           := gt_mov_req_instr_tbl(i).description;
--2008/09/03 Y.Kawano MOD End
--
        BEGIN
          -- 検索処理を行います
          SELECT xmld.mov_lot_dtl_id,                             -- ロット詳細ID
                  xmld.lot_id,                                     -- ロットID
                  xmld.item_id,                                    -- OPM品目ID
                  xmld.actual_quantity,                            -- 実績数量
                  xmld.lot_no                                      -- ロットNo
          BULK COLLECT INTO gt_mov_lot_dtl_id_tbl,
                  gt_lot_id_tbl,
                  gt_item_id_tbl,
                  gt_actual_quantity_tbl,
                  gt_lot_no_tbl
          FROM   xxinv_mov_lot_details          xmld              -- 移動ロット詳細(アドオン)
--2008/09/03 Y.Kawano MOD Start
--          WHERE  xmld.mov_line_id               =  gt_mov_line_id_tbl(i)
          WHERE  xmld.mov_line_id               =  lt_mov_line_id
--2008/09/03 Y.Kawano MOD End
          AND    xmld.document_type_code        =  cv_move_type
          AND    xmld.record_type_code          =  cv_instr_rec_type
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
          <<gt_mov_lot_dtl_id_tbl_loop>>
          FOR j IN gt_mov_lot_dtl_id_tbl.FIRST .. gt_mov_lot_dtl_id_tbl.LAST LOOP
--2008/09/03 Y.Kawano MOD Start
--            -- 共通関数(引当可能数算出API)の呼び出し
--            ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_qty(gt_ship_to_locat_id_tbl(j),
--                                                               gt_item_id_tbl(j),
--                                                               gt_lot_id_tbl(j),
--                                                               gt_schedule_arrival_date_tbl(j));
--            IF ((ln_can_enc_qty - gt_actual_quantity_tbl(i)) < 0) THEN
--              -- 供給数の減数チェックワーニング
--              ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,
--                                                    cv_msg_supply_chk_warn,
--                                                    'LOCATION',
--                                                    gt_description_tbl(i),
--                                                    'ITEM',
--                                                    gt_item_short_name_tbl(i),
--                                                    'LOT',
--                                                    gt_lot_no_tbl(i));
            -- 共通関数(引当可能数算出API)の呼び出し
            ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_qty(lt_ship_to_locat_id,
                                                               gt_item_id_tbl(j),
                                                               gt_lot_id_tbl(j),
                                                               lt_schedule_arrival_date);
            IF ((ln_can_enc_qty - gt_actual_quantity_tbl(j)) < 0) THEN
              -- 供給数の減数チェックワーニング
              ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,
                                                    cv_msg_supply_chk_warn,
                                                    'LOCATION',
                                                    lt_description,
                                                    'ITEM',
                                                    lt_item_short_name,
                                                    'LOT',
                                                    gt_lot_no_tbl(j));
-- 2009/05/07 H.Itou MOD START 本番障害#1443 減数チェック警告時も引当解除する。
----2008/09/03 Y.Kawano MOD End
--              ROLLBACK TO advance_sp;
---- 2009/01/14 Y.Yamamoto #991 update start
----              RETURN cv_enc_cancel_err;                             -- 引当解除データ無し
--              RETURN cv_sub_check_warn;                             -- 減数チェックワーニング
---- 2009/01/14 Y.Yamamoto #991 update end
              lv_retcode := cv_sub_check_warn;    -- リターンコード(減数警告)
-- 2009/05/07 H.Itou MOD END
            END IF;
--
            -- 削除処理を行います
            DELETE
            FROM   xxinv_mov_lot_details          xmld              -- 移動ロット詳細(アドオン)
            WHERE  xmld.mov_lot_dtl_id            =  gt_mov_lot_dtl_id_tbl(j);
--
          END LOOP gt_mov_lot_dtl_id_tbl_loop;
--
        EXCEPTION
          WHEN lock_expt THEN
            -- ロック処理エラー
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
            ROLLBACK TO advance_sp;                 -- エラーの場合はセーブポイントにロールバック
            RETURN cv_enc_cancel_err;                 -- 引当解除失敗
--
            WHEN OTHERS THEN
              -- 移動ロット詳細(アドオン)削除失敗
              ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_xmld_del_err);
              ROLLBACK TO advance_sp;                 -- エラーの場合はセーブポイントにロールバック
              RETURN cv_enc_cancel_err;                 -- 引当解除失敗
--
        END;
--
        BEGIN
          -- 更新処理を行います
          UPDATE xxinv_mov_req_instr_lines      mril              -- 移動依頼/指示明細(アドオン)
          SET    mril.reserved_quantity         =  NULL,          -- 引当数
                 mril.automanual_reserve_class  =  NULL,          -- 自動手動引当区分
                 mril.last_updated_by           =  ln_user_id,
                 mril.last_update_date          =  ld_sysdate,
                 mril.last_update_login         =  ln_login_id,
                 mril.request_id                =  ln_conc_request_id,
                 mril.program_application_id    =  ln_prog_appl_id,
                 mril.program_id                =  ln_conc_program_id,
                 mril.program_update_date       =  ld_sysdate
--2008/09/03 Y.Kawano MOD Start
--          WHERE  mril.mov_line_id               =  gt_mov_line_id_tbl(i);
          WHERE  mril.mov_line_id               =  lt_mov_line_id;
--2008/09/03 Y.Kawano MOD End
--
        EXCEPTION
          -- エラーの場合はセーブポイントにロールバック
          WHEN OTHERS THEN
            -- 移動依頼/指示明細(アドオン)更新失敗
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_mril_update_err);
            ROLLBACK TO advance_sp;
            RETURN cv_enc_cancel_err;                             -- 引当解除失敗
--
        END;
--
      END LOOP gt_mov_req_instr_tbl_loop;
--
-- 2009/05/07 H.Itou ADD START 本番障害#1443
      IF (lv_retcode = cv_sub_check_warn) THEN    -- リターンコード(減数警告)
        RETURN cv_sub_check_warn;
--
      ELSE
-- 2009/05/07 H.Itou ADD END
        -- 正常終了の場合
        RETURN cv_compl;
-- 2009/05/07 H.Itou ADD START 本番障害#1443
      END IF;
-- 2009/05/07 H.Itou ADD END
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN
      -- ロック処理エラー
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
      ROLLBACK TO advance_sp;
      RETURN cv_enc_cancel_err;                             -- 引当解除失敗
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END cancel_reserve;
--
-- 2008/10/23 v1.28 D.Nihei Del Start TE_080_600 No22(対応完了後削除予定)
  /**********************************************************************************
   * Function Name    : cancel_careers_schedule
   * Description      : 配車解除関数
   ***********************************************************************************/
  FUNCTION cancel_careers_schedule(
    iv_biz_type             IN         VARCHAR2,                              -- 1.業務種別
    iv_request_no           IN         VARCHAR2,                              -- 2.依頼No/移動番号
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 3.エラーメッセージ
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'cancel_careers_schedule';  -- プログラム名
    cv_app_name_xxwsh      CONSTANT VARCHAR2(5)   := 'XXWSH';            -- アプリケーション短縮名
    cv_msg_lock_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10006';  -- ロック処理エラー
    cv_career_cancel_err   CONSTANT VARCHAR2(2)   := '-1';               -- 配車解除失敗
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    lock_expt                  EXCEPTION;  -- ロック取得例外
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  BEGIN
--
    RETURN cancel_careers_schedule(
               iv_biz_type
             , iv_request_no
             , '1'
             , ov_errmsg);
--
  EXCEPTION 
    WHEN lock_expt THEN
      -- ロック処理エラー
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
      RETURN cv_career_cancel_err;                             -- 配車解除失敗
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END cancel_careers_schedule;
-- 2008/10/23 v1.28 D.Nihei Del End
--
  /**********************************************************************************
   * Function Name    : cancel_careers_schedule
   * Description      : 配車解除関数
   ***********************************************************************************/
  FUNCTION cancel_careers_schedule(
    iv_biz_type             IN         VARCHAR2,                              -- 1.業務種別
    iv_request_no           IN         VARCHAR2,                              -- 2.依頼No/移動番号
-- 2008/10/23 v1.28 D.Nihei Add Start TE080_BPO_600 No22
    iv_calcel_flag          IN         VARCHAR2,                              -- 3.配車解除フラグ 1:解除、0:通知ステータス更新のみ
-- 2008/10/23 v1.28 D.Nihei Add End
    ov_errmsg               OUT NOCOPY VARCHAR2)                              -- 4.エラーメッセージ
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'cancel_careers_schedule';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_career_cancel_err   CONSTANT VARCHAR2(2)   := '-1';               -- 配車解除失敗
    cv_compl               CONSTANT VARCHAR2(1)   := '0';                -- 成功
    cv_para_check_err      CONSTANT VARCHAR2(1)   := '1';                -- パラメータチェックエラー
    cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';                -- YES
    cv_flag_no             CONSTANT VARCHAR2(1)   := 'N';                -- NO
    cv_new                 CONSTANT VARCHAR2(1)   := 'N';                -- 新規
    cv_amend               CONSTANT VARCHAR2(1)   := 'M';                -- 修正
    cv_ship                CONSTANT VARCHAR2(1)   := '1';                -- 出荷
    cv_supply              CONSTANT VARCHAR2(1)   := '2';                -- 支給
    cv_move                CONSTANT VARCHAR2(1)   := '3';                -- 移動
    cv_ship_req            CONSTANT VARCHAR2(1)   := '1';                -- 出荷依頼
    cv_supply_req          CONSTANT VARCHAR2(1)   := '2';                -- 支給依頼
    cv_cate_order          CONSTANT VARCHAR2(10)  := 'ORDER';            -- 受注
    cv_app_name_xxwsh      CONSTANT VARCHAR2(5)   := 'XXWSH';            -- アプリケーション短縮名
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
    cv_app_name_xxcmn      CONSTANT VARCHAR2(5)   := 'XXCMN';            -- アプリケーション短縮名
-- 2009/08/18 H.Itou Add End
    cv_tkn_request_no      CONSTANT VARCHAR2(10)  := 'REQUEST_NO';       -- トークン名
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
    cv_msg_process_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-05002';  -- 処理失敗
-- 2009/08/18 H.Itou Add End
    cv_msg_para_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10001';  -- パラメータ指定不正
    cv_msg_lock_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10006';  -- ロック処理エラー
    cv_msg_del_req_instr   CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10007';  -- 依頼/指示解除エラー
    cv_msg_up_req_instr    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10008';  -- 依頼/指示更新エラー
    cv_msg_ship_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10009';  -- 出荷依頼エラー
    cv_msg_supply_err      CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10010';  -- 支給依頼エラー
    cv_msg_move_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10011';  -- 移動指示エラー
    cv_msg_new_modify_err  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10019';  -- 新規修正区分エラー
-- Ver1.20 M.Hokkanji START
    cv_msg_ship_max_err    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10020';  -- 出荷依頼エラー(共通関数)
    cv_msg_supply_max_err  CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10021';  -- 支給依頼エラー(共通関数)
    cv_msg_move_max_err    CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10022';  -- 移動指示エラー(共通関数)
    cv_tkn_program         CONSTANT VARCHAR2(15)  := 'PROGRAM';          -- トークン名
-- Ver1.20 M.Hokkanji END
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
    cv_tkn_process         CONSTANT VARCHAR2(15)  := 'PROCESS';          -- トークン名
-- 2009/08/18 H.Itou Add End
    cv_tightening          CONSTANT VARCHAR2(2)   := '03';               -- 締め済み
    cv_adjustment          CONSTANT VARCHAR2(2)   := '03';               -- 調整中
    cv_received            CONSTANT VARCHAR2(2)   := '07';               -- 受領済み
    cv_deci_noti           CONSTANT VARCHAR2(3)   := '40';               -- 確定通知済
    cv_not_noti            CONSTANT VARCHAR2(3)   := '10';               -- 未通知
    cv_re_noti             CONSTANT VARCHAR2(3)   := '20';               -- 再通知要
    cv_msg_com             CONSTANT VARCHAR2(1)   := ',';                -- カンマ
    --
    cv_tkn_biz_type        CONSTANT VARCHAR2(30)  := 'BIZ_TYPE';         -- 処理種別
    cv_tkn_ship_char       CONSTANT VARCHAR2(30)  := '出荷依頼No';       -- 出荷依頼No
    cv_tkn_supl_char       CONSTANT VARCHAR2(30)  := '支給依頼No';       -- 支給依頼No
    cv_tkn_move_char       CONSTANT VARCHAR2(30)  := '移動番号';         -- 移動番号
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
    cv_tkn_upd_assignment  CONSTANT VARCHAR2(100) := '割当セットAPI起動';-- 処理名
-- 2009/08/18 H.Itou Add End
-- Ver1.20 M.Hokkanji START
    cv_code_kbn_mov        CONSTANT VARCHAR2(1)   := '4';                -- 移動
    cv_code_kbn_ship       CONSTANT VARCHAR2(1)   := '9';                -- 出荷
    cv_code_kbn_supply     CONSTANT VARCHAR2(2)   := '11';               -- 支給
    cv_prod_class_1        CONSTANT VARCHAR2(1)   := '1';                -- 商品区分：1
    cv_prod_class_2        CONSTANT VARCHAR2(1)   := '2';                -- 商品区分：2
    cv_tkn_max_char        CONSTANT VARCHAR2(30)  := '最大配送区分の取得';     -- トークン「最大配送区分」
    cv_tkn_small_char      CONSTANT VARCHAR2(30)  := '小口区分の取得';         -- トークン「小口区分」
    cv_tkn_weight_char     CONSTANT VARCHAR2(30)  := '積載効率(重量)の取得';   -- トークン「積載効率(重量)」
    cv_tkn_cap_char        CONSTANT VARCHAR2(30)  := '積載効率(容積)の取得';   -- トークン「積載効率(容積)」
    cv_include             CONSTANT VARCHAR2(1)   := '1';                -- 小口区分(対象)
-- Ver1.20 M.Hokkanji END
-- 2008/10/23 v1.28 D.Nihei Add Start TE080_BPO_600 No22
    cv_cancel_flag_on      CONSTANT VARCHAR2(1)   := '1';                -- 配車解除フラグ：ON
    cv_cancel_flag_off     CONSTANT VARCHAR2(1)   := '0';                -- 配車解除フラグ：OFF
-- 2008/10/23 v1.28 D.Nihei Add End
-- 2009/02/10 H.Itou Add Start 本番障害#863対応
    cv_cancel_flag_judge CONSTANT VARCHAR2(2) := '2';                    -- 配車解除フラグ：重量オーバーの場合のみ配車解除
    cv_over_flag_on      CONSTANT VARCHAR2(2) := '1';                    -- 積載オーバーフラグ ON
    cv_over_flag_off     CONSTANT VARCHAR2(2) := '0';                    -- 積載オーバーフラグ OFF
    cv_weight            CONSTANT VARCHAR2(30)   :=  '1';                -- 重量容積区分：重量
    cv_capacity          CONSTANT VARCHAR2(30)   :=  '2';                -- 重量容積区分：容積
-- 2009/02/10 H.Itou Add End
-- 2008/09/03 H.Itou Add Start PT 1-2_8対応
    cv_delivery_mixed_flag_deli CONSTANT VARCHAR2(1) := '1'; -- 配送No/混載元No識別フラグ「配送No」
    cv_delivery_mixed_flag_mix  CONSTANT VARCHAR2(1) := '2'; -- 配送No/混載元No識別フラグ「混載元No」
    cv_delivery_mixed_flag_no   CONSTANT VARCHAR2(1) := '0'; -- 配送No/混載元No識別フラグ「配送No、混載元No共になし」
-- 2008/09/03 H.Itou Add End
--
    cv_tkn_req_mov_no      CONSTANT VARCHAR2(30)  := 'REQ_MOV';          -- 依頼No/移動番号
-- 2008/09/03 H.Itou Add Start PT 1-2_8対応
    -- =============================
    -- 出荷データ取得SQL
    -- =============================
    cv_ship_select CONSTANT VARCHAR2(32000) := 
         '  SELECT xoha.order_header_id             order_header_id             ' -- 受注ヘッダアドオンID
      || '        ,xoha.req_status                  req_status                  ' -- ステータス
      || '        ,xoha.request_no                  request_no                  ' -- 依頼No
      || '        ,xoha.notif_status                notif_status                ' -- 通知ステータス
      || '        ,xoha.prev_notif_status           prev_notif_status           ' -- 前回通知ステータス
      || '        ,xola.shipped_quantity            shipped_quantity            ' -- 出荷実績数量
      || '        ,xola.ship_to_quantity            ship_to_quantity            ' -- 入庫実績実績数量
      || '        ,xoha.shipping_method_code        shipping_method_code        ' -- 配送区分
      || '        ,xoha.prod_class                  prod_class                  ' -- 商品区分
      || '        ,xoha.based_weight                based_weight                ' -- 基本重量
      || '        ,xoha.based_capacity              based_capacity              ' -- 基本容積
      || '        ,xoha.weight_capacity_class       weight_capacity_class       ' -- 重量容積区分
      || '        ,xoha.deliver_from                deliver_from                ' -- 出荷元
      || '        ,xoha.deliver_to                  deliver_to                  ' -- 配送先
      || '        ,xoha.schedule_ship_date          schedule_ship_date          ' -- 出庫予定日
      || '        ,xoha.sum_weight                  sum_weight                  ' -- 積載重量合計
      || '        ,xoha.sum_capacity                sum_capacity                ' -- 積載容積合計
      || '        ,xoha.sum_pallet_weight           sum_pallet_weight           ' -- 合計パレット重量
      || '        ,xoha.freight_charge_class        freight_charge_class        ' -- 運賃区分
      || '        ,xoha.loading_efficiency_weight   loading_efficiency_weight   ' -- 積載率(重量)
      || '        ,xoha.loading_efficiency_capacity loading_efficiency_capacity ' -- 積載率(容積)
      ;
    cv_ship_from CONSTANT VARCHAR2(32000) := 
         '  FROM   xxwsh_order_headers_all          xoha  '     -- 受注ヘッダアドオン
      || '        ,xxwsh_order_lines_all            xola  '     -- 受注明細アドオン
      || '        ,xxwsh_oe_transaction_types2_v    xott  '     -- 受注タイプ情報VIEW
      ;
    cv_ship_where CONSTANT VARCHAR2(32000) := 
         '  WHERE                                                                         '
            -- *** 結合条件 *** --
      || '         xoha.order_header_id                =  xola.order_header_id            ' -- 結合条件 受注ヘッダアドオン AND 受注明細アドオン
      || '  AND    xoha.order_type_id                  =  xott.transaction_type_id        ' -- 結合条件 受注ヘッダアドオン AND 受注タイプ情報VIEW
      || '  AND    xott.start_date_active             <= TRUNC( xoha.schedule_ship_date ) ' -- 結合条件 受注ヘッダアドオン AND 受注タイプ情報VIEW
      || '  AND    NVL(xott.end_date_active, TO_DATE(''99991231'',''YYYYMMDD''))          ' -- 結合条件 受注ヘッダアドオン AND 受注タイプ情報VIEW
      || '                                            >= TRUNC( xoha.schedule_ship_date ) '
            -- *** 抽出条件 *** --
      || '  AND    NVL(xoha.latest_external_flag, ''' || cv_flag_no || ''') = ''' || cv_flag_yes   || ''' ' -- 抽出条件 受注ヘッダアドオン.最新フラグ：「Y」
      || '  AND    NVL(xola.delete_flag,          ''' || cv_flag_no || ''') = ''' || cv_flag_no    || ''' ' -- 抽出条件 受注明細アドオン.削除フラグ：「N」
      || '  AND    xott.shipping_shikyu_class                               = ''' || cv_ship_req   || ''' ' -- 抽出条件 受注タイプ情報VIEW.出荷支給区分：「1：出荷依頼」
      || '  AND    xott.order_category_code                                 = ''' || cv_cate_order || ''' ' -- 抽出条件 受注タイプ情報VIEW.受注カテゴリコード：「ORDER：受注」
      ;
    cv_ship_where_request_no CONSTANT VARCHAR2(32000) := 
         '  AND    xoha.request_no  = :lv_search_key_no   '; -- 抽出条件 受注ヘッダアドオン.依頼No：「IN依頼No」
    cv_ship_where_delivery_no CONSTANT VARCHAR2(32000) := 
         '  AND    xoha.delivery_no = :lv_search_key_no   '  -- 抽出条件 受注ヘッダアドオン.配送No：ロック取得時に取得した配送No/混載元No
      || '  AND    xoha.delivery_no IS NOT NULL           '  -- 抽出条件 受注ヘッダアドオン.配送NoがNULLでない
      ;
    cv_ship_where_mixed_no CONSTANT VARCHAR2(32000) := 
         '  AND    xoha.mixed_no    = :lv_search_key_no   '  -- 抽出条件 受注ヘッダアドオン.混載元No：ロック取得時に取得した配送No/混載元No
      || '  AND    xoha.delivery_no IS NULL               '  -- 抽出条件 受注ヘッダアドオン.配送NoがNULL
      ;
    cv_ship_order_by CONSTANT VARCHAR2(32000) := 
         '  ORDER BY order_header_id     ';  -- 受注ヘッダアドオン.受注ヘッダアドオンID
    cv_union_all CONSTANT VARCHAR2(32000) := 
         '  UNION ALL ';
--
    -- =============================
    -- 支給データ取得SQL
    -- =============================
    cv_supply_select CONSTANT VARCHAR2(32000) := 
         '  SELECT xoha.order_header_id             order_header_id             ' -- 受注ヘッダアドオンID
      || '        ,xoha.req_status                  req_status                  ' -- ステータス
      || '        ,xoha.request_no                  request_no                  ' -- 依頼No
      || '        ,xoha.notif_status                notif_status                ' -- 通知ステータス
      || '        ,xoha.prev_notif_status           prev_notif_status           ' -- 前回通知ステータス
      || '        ,xola.shipped_quantity            shipped_quantity            ' -- 出荷実績数量
      || '        ,xola.ship_to_quantity            ship_to_quantity            ' -- 入庫実績実績数量
      || '        ,xoha.shipping_method_code        shipping_method_code        ' -- 配送区分
      || '        ,xoha.prod_class                  prod_class                  ' -- 商品区分
      || '        ,xoha.based_weight                based_weight                ' -- 基本重量
      || '        ,xoha.based_capacity              based_capacity              ' -- 基本容積
      || '        ,xoha.weight_capacity_class       weight_capacity_class       ' -- 重量容積区分
      || '        ,xoha.deliver_from                deliver_from                ' -- 出荷元
      || '        ,xoha.vendor_site_code            vendor_site_code            ' -- 取引先サイト
      || '        ,xoha.schedule_ship_date          schedule_ship_date          ' -- 出庫予定日
      || '        ,xoha.sum_weight                  sum_weight                  ' -- 積載重量合計
      || '        ,xoha.sum_capacity                sum_capacity                ' -- 積載容積合計
      || '        ,xoha.freight_charge_class        freight_charge_class        ' -- 運賃区分
      || '        ,xoha.loading_efficiency_weight   loading_efficiency_weight   ' -- 積載率(重量)
      || '        ,xoha.loading_efficiency_capacity loading_efficiency_capacity ' -- 積載率(容積)
      ;
    cv_supply_from CONSTANT VARCHAR2(32000) := 
         '  FROM   xxwsh_order_headers_all          xoha  '     -- 受注ヘッダアドオン
      || '        ,xxwsh_order_lines_all            xola  '     -- 受注明細アドオン
      || '        ,xxwsh_oe_transaction_types2_v    xott  '     -- 受注タイプ情報VIEW
      ;
    cv_supply_where CONSTANT VARCHAR2(32000) := 
         '  WHERE                                                                          '
            -- *** 結合条件 *** --
      || '         xoha.order_header_id                =  xola.order_header_id            ' -- 結合条件 受注ヘッダアドオン AND 受注明細アドオン
      || '  AND    xoha.order_type_id                  =  xott.transaction_type_id        ' -- 結合条件 受注ヘッダアドオン AND 受注タイプ情報VIEW
      || '  AND    xott.start_date_active             <= TRUNC( xoha.schedule_ship_date ) ' -- 結合条件 受注ヘッダアドオン AND 受注タイプ情報VIEW
      || '  AND    NVL(xott.end_date_active, TO_DATE(''99991231'',''YYYYMMDD''))          ' -- 結合条件 受注ヘッダアドオン AND 受注タイプ情報VIEW
      || '                                            >= TRUNC( xoha.schedule_ship_date ) '
            -- *** 抽出条件 *** --
      || '  AND    NVL(xoha.latest_external_flag, ''' || cv_flag_no || ''') = ''' || cv_flag_yes   || ''' ' -- 抽出条件 受注ヘッダアドオン.最新フラグ：「Y」
      || '  AND    NVL(xola.delete_flag,          ''' || cv_flag_no || ''') = ''' || cv_flag_no    || ''' ' -- 抽出条件 受注明細アドオン.削除フラグ：「N」
      || '  AND    xott.shipping_shikyu_class                               = ''' || cv_supply_req || ''' ' -- 抽出条件 受注タイプ情報VIEW.出荷支給区分：「2：支給依頼」
      || '  AND    xott.order_category_code                                 = ''' || cv_cate_order || ''' ' -- 抽出条件 受注タイプ情報VIEW.受注カテゴリコード：「ORDER：受注」
      ;
    cv_supply_where_request_no CONSTANT VARCHAR2(32000) := 
         '  AND    xoha.request_no  = :lv_search_key_no   '; -- 抽出条件 受注ヘッダアドオン.依頼No：「IN依頼No」
    cv_supply_where_delivery_no CONSTANT VARCHAR2(32000) := 
         '  AND    xoha.delivery_no = :lv_search_key_no   '; -- 抽出条件 受注ヘッダアドオン.配送No：ロック取得時に取得した配送No
    cv_supply_order_by CONSTANT VARCHAR2(32000) := 
         '  ORDER BY xoha.order_header_id     ';  -- 受注ヘッダアドオン.受注ヘッダアドオンID
-- 2008/09/03 H.Itou Add End
--
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
    lv_errbuf               VARCHAR2(5000);           --   エラー・メッセージ           --# 固定 #
-- 2009/08/18 H.Itou Add End
    -- *** ローカル変数 ***
    lv_status               VARCHAR2(2);              -- ステータス
    lv_delivery_no          VARCHAR2(12);             -- 配送No
    ln_shipped_quantity     NUMBER;                   -- 出荷実績数量
    ln_ship_to_quantity     NUMBER;                   -- 入庫実績数量
    ln_no_count             NUMBER;                   -- 配車解除不可カウント
    ln_data_count           NUMBER;                   -- データ存在カウント
    lv_msg_ship_err         VARCHAR2(500);            -- ユーザーエラーメッセージ(出荷)
    lv_msg_supply_err       VARCHAR2(500);            -- ユーザーエラーメッセージ(支給)
    lv_msg_move_err         VARCHAR2(500);            -- ユーザーエラーメッセージ(移動)
-- Ver1.20 M.Hokkanji START
    lv_msg_ship_max_err     VARCHAR2(500);            -- ユーザーエラーメッセージ(出荷)(最大配送区分)
    lv_msg_supply_max_err   VARCHAR2(500);            -- ユーザーエラーメッセージ(支給)(最大配送区分)
    lv_msg_move_max_err     VARCHAR2(500);            -- ユーザーエラーメッセージ(移動)(最大配送区分)
    lv_msg_ship_small_err   VARCHAR2(500);            -- ユーザーエラーメッセージ(出荷)(小口区分)
    lv_msg_move_small_err   VARCHAR2(500);            -- ユーザーエラーメッセージ(移動)(小口区分)
    lv_msg_ship_wei_err     VARCHAR2(500);            -- ユーザーエラーメッセージ(出荷)(積載効率(重量))
    lv_msg_supply_wei_err   VARCHAR2(500);            -- ユーザーエラーメッセージ(支給)(積載効率(重量))
    lv_msg_move_wei_err     VARCHAR2(500);            -- ユーザーエラーメッセージ(移動)(積載効率(重量))
    lv_msg_ship_cap_err     VARCHAR2(500);            -- ユーザーエラーメッセージ(出荷)(積載効率(容積))
    lv_msg_supply_cap_err   VARCHAR2(500);            -- ユーザーエラーメッセージ(支給)(積載効率(容積))
    lv_msg_move_cap_err     VARCHAR2(500);            -- ユーザーエラーメッセージ(移動)(積載効率(容積))
    lv_err_chek             VARCHAR2(1);              -- エラー継続チェック用のフラグ
-- Ver1.20 M.Hokkanji END
    ln_user_id              NUMBER;                   -- ログインしているユーザーのID取得
    ln_login_id             NUMBER;                   -- 最終更新ログイン
    ln_conc_request_id      NUMBER;                   -- 要求ID
    ln_prog_appl_id         NUMBER;                   -- プログラム・アプリケーションID
    ln_conc_program_id      NUMBER;                   -- プログラムID
    ld_sysdate              DATE;                     -- システム現在日付
    ln_dummy                NUMBER;                   -- ロック用ダミー変数
    --
    lv_new_modify_flg       VARCHAR2(1);              -- 新規修正フラグ
-- Ver1.20 M.Hokkanji START
    lt_max_ship_methods             xxcmn_ship_methods.ship_method%TYPE;            -- 最大配送区分
    lt_drink_deadweight             xxcmn_ship_methods.drink_deadweight%TYPE;       -- ドリンク積載重量
    lt_leaf_deadweight              xxcmn_ship_methods.leaf_deadweight%TYPE;        -- リーフ積載重量
    lt_drink_loading_capacity       xxcmn_ship_methods.drink_loading_capacity%TYPE; -- ドリンク積載容積
    lt_leaf_loading_capacity        xxcmn_ship_methods.leaf_loading_capacity%TYPE;  -- リーフ積載容積
    lt_palette_max_qty              xxcmn_ship_methods.palette_max_qty%TYPE;        -- パレット最大枚数
    ln_ret_code                     NUMBER;                                         -- リターンコード
    -- 小口区分取得用変数
    lv_small_sum_class              VARCHAR2(1);                                    -- 小口区分
    -- 共通関数｢積載効率チェック｣OUTパラメータ
    lv_retcode                      VARCHAR2(1);                                    -- リターンコード
    lv_errmsg_code                  VARCHAR2(100);                                  -- エラーメッセージコード
    lv_errmsg                       VARCHAR2(100);                                  -- エラーメッセージ
    lv_loading_over_class           VARCHAR2(100);                                  -- 積載オーバー区分
    lv_ship_methods                 VARCHAR2(100);                                  -- 出荷方法
    ln_load_efficiency_weight       NUMBER;                                         -- 重量積載効率
    ln_load_efficiency_capacity     NUMBER;                                         -- 容積積載効率
    lv_mixed_ship_method            VARCHAR2(100);                                  -- 混載配送区分
    ln_sum_weight                   NUMBER;                                         -- 合計重量
    ln_sum_capacity                 NUMBER;                                         -- 合計容積
-- 2009/02/10 H.Itou Add Start 本番障害#863対応
    ln_deli_sum_w                   NUMBER := 0;                                    -- 積載重量合計(配車用)
    ln_deli_sum_c                   NUMBER := 0;                                    -- 積載容積合計(配車用)
    ln_deli_sum_pallet_w            NUMBER := 0;                                    -- 合計パレット重量(配車用)
    ln_deli_load_efficiency_w       NUMBER := 0;                                    -- 重量積載効率(配車用)
    ln_deli_load_efficiency_c       NUMBER := 0;                                    -- 容積積載効率(配車用)
    lv_over_flag                    VARCHAR2(1) := cv_over_flag_off;                -- 積載オーバーフラグ
    -- 積載効率(配車用)算出に使用
    lv_entering_despatching_code1   xxwsh_order_headers_all.deliver_from%TYPE;          -- 入出庫場所コード１
    lv_code_class2                  VARCHAR2(2);                                        -- コード区分２
    lv_entering_despatching_code2   xxwsh_order_headers_all.deliver_to%TYPE;            -- 入出庫場所コード２
    lv_prod_class                   xxwsh_order_headers_all.prod_class%TYPE;            -- 商品区分
    ld_standard_date                DATE;                                               -- 基準日(適用日基準日)
    lv_weight_capacity_class        xxwsh_order_headers_all.weight_capacity_class%TYPE; -- 重量容積区分
    lv_ship_method                  xxwsh_carriers_schedule.delivery_type%TYPE;         -- 配送区分
    lv_default_line_number          xxwsh_carriers_schedule.default_line_number%TYPE;   -- 明細基準No
    ln_mixed_ratio                  NUMBER := 0;                                        -- 混載率
-- 2009/02/10 H.Itou Add End
-- Ver1.20 M.Hokkanji END
-- 2008/09/03 H.Itou Add Start PT 1-2_8対応
    lv_delivery_mixed_flag          VARCHAR2(1); -- 配送No/混載元No識別フラグ
    lv_sql                          VARCHAR2(32767); -- 動的SQL用
    lv_where_search_key             VARCHAR2(32767); -- 検索キーWHERE句
    lv_search_key_no                VARCHAR2(32767); -- 検索キー
-- 2008/09/03 H.Itou Add End
-- 2008/12/13 D.Nihei Add Start
    lv_log                          VARCHAR2(32767); -- ログ出力用変数
-- 2008/12/13 D.Nihei Add End
-- Ver1.45 M.Hokkanji Start
    lv_skip_flag                    VARCHAR2(1) := '0';                                    -- 配車解除後続処理判断用
-- Ver1.45 M.Hokkanji End
--

    -- *** ローカル・カーソル ***
-- 2008/09/03 H.Itou Add Start PT 1-2_8対応
    TYPE ref_cursor   IS REF CURSOR ;
    cur_ship_data     ref_cursor ;  -- 出荷データ
    cur_supply_data   ref_cursor ;  -- 支給データ
-- 2008/09/03 H.Itou Add End
-- 2009/02/20 D.Nihei Add Start 本番障害#1034対応
      -- 受注ヘッダアドオンのロック取得
    CURSOR  ship_lock_cur IS
-- 2012/07/18 D.Sugahara 1.50 Mod Start(ヒント句追加）
      SELECT /*+ INDEX ( xoha xxwsh_oh_n24 ) INDEX ( xoha xxwsh_oh_n23 ) */
-- 2012/07/18 D.Sugahara 1.50 Mod End
              1
      FROM   xxwsh_order_headers_all     xoha       -- 受注ヘッダアドオン
-- 2012/07/18 D.Sugahara 1.50 Mod Start
--      WHERE  NVL(xoha.delivery_no, xoha.mixed_no)       =  lv_delivery_no
      WHERE  ((xoha.delivery_no = lv_delivery_no) OR
              (xoha.delivery_no IS NULL AND xoha.mixed_no = lv_delivery_no))
-- 2012/07/18 D.Sugahara 1.50 Mod End
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
      FOR UPDATE OF xoha.order_header_id NOWAIT
    ;
      -- 移動依頼ヘッダアドオンのロック取得
    CURSOR  mov_lock_cur IS
      SELECT 1
      FROM   xxinv_mov_req_instr_headers mrih       -- 移動依頼/指示ヘッダ(アドオン)
      WHERE  mrih.delivery_no =  lv_delivery_no
      FOR UPDATE OF mrih.mov_hdr_id NOWAIT
    ;
-- 2009/02/20 D.Nihei Add End
--
    -- *** ローカル・レコード ***
-- 2008/12/15 D.Nihei Add Start
    lt_chk_ship_tbl   chk_ship_tbl;              -- 配車解除可否チェック(出荷)
    lt_chk_supply_tbl chk_supply_tbl;            -- 配車解除可否チェック(支給)
    lt_chk_move_tbl   chk_move_tbl;              -- 配車解除可否チェック(移動)
-- 2008/12/15 D.Nihei Add Start
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    lock_expt                  EXCEPTION;  -- ロック取得例外
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- カウント変数初期化
    ln_no_count   := 0;
    ln_data_count := 0;
-- 2008/12/15 D.Nihei Add Start
    -- 初期化を行う
    lt_chk_ship_tbl.DELETE;              -- 配車解除可否チェック(出荷)
    lt_chk_supply_tbl.DELETE;            -- 配車解除可否チェック(支給)
    lt_chk_move_tbl.DELETE;              -- 配車解除可否チェック(移動)
-- 2008/12/15 D.Nihei Add Start
--
    -- WHOカラム情報取得
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    ld_sysdate           := SYSDATE;                      -- システム現在日付
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := '【業務種別】'        || iv_biz_type 
         || '【依頼No/移動番号】' || iv_request_no 
         || '【配車解除フラグ】'  || iv_calcel_flag
         || '【ユーザID】'        || ln_user_id
         || '【要求ID】'          || ln_conc_request_id
         || '【プログラムID】'    || ln_conc_program_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
    -- **************************************************
    -- *** 0.パラメータチェック処理
    -- **************************************************
    IF ( ( iv_biz_type    IS NULL ) 
     OR  ( iv_biz_type    NOT IN ( cv_ship, cv_supply, cv_move ) ) 
-- 2008/10/23 v1.28 D.Nihei Mod Start TE080_BPO_600 No22
--     OR  (iv_request_no IS NULL)) THEN
     OR  ( iv_request_no  IS NULL ) 
     OR  ( iv_calcel_flag IS NULL ) ) 
    THEN
-- 2008/10/23 v1.28 D.Nihei Mod End
         -- パラメータ指定不正
         ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_para_err);
         RETURN cv_para_check_err;                          -- パラメータチェックエラー
    END IF;
--
    -- **************************************************
    -- *** 1.配車済みチェック処理
    -- **************************************************
    -- 出荷依頼のチェック
    -- 検索処理を行い、ロックを取得します。
    IF ( iv_biz_type = cv_ship ) THEN
      SELECT xoha.req_status,                               -- ステータス
-- Ver1.20 M.Hokkanji Start
--             xoha.delivery_no                             -- 配送No
             NVL(xoha.delivery_no,xoha.mixed_no)            -- 配送No/混載元No
-- Ver1.20 M.Hokkanji End
      INTO   lv_status,
             lv_delivery_no
      FROM   xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
             xxwsh_oe_transaction_types2_v      xott        -- 受注タイプ情報VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_ship_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    xott.start_date_active                    <=  trunc( xoha.schedule_ship_date )
      AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
                                                       >= trunc( xoha.schedule_ship_date )
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
-- Ver1.30 M.Hokkanji Start
      FOR UPDATE OF xoha.order_header_id NOWAIT;
--      FOR UPDATE NOWAIT;
-- Ver1.30 M.Hokkanji End
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【出荷：ステータス】' || lv_status 
         || '【配送No/混載元No】'  || lv_delivery_no;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
    -- 支給依頼のチェック
    -- 検索処理を行い、ロックを取得します。
    ELSIF ( iv_biz_type = cv_supply ) THEN
      SELECT xoha.req_status,                               -- ステータス
             xoha.delivery_no                               -- 配送No
      INTO   lv_status,
             lv_delivery_no
      FROM   xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
             xxwsh_oe_transaction_types2_v      xott        -- 受注タイプ情報VIEW
      WHERE  xoha.request_no                            =  iv_request_no
      AND    xoha.order_type_id                         =  xott.transaction_type_id
      AND    xott.shipping_shikyu_class                 =  cv_supply_req
      AND    xott.order_category_code                   =  cv_cate_order
      AND    xott.start_date_active                    <= trunc( xoha.schedule_ship_date )
      AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
                                                       >= trunc( xoha.schedule_ship_date )
      AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
-- Ver1.30 M.Hokkanji Start
      FOR UPDATE OF xoha.order_header_id NOWAIT;
--      FOR UPDATE NOWAIT;
-- Ver1.30 M.Hokkanji End
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【支給：ステータス】' || lv_status 
         || '【配送No】'           || lv_delivery_no;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
    -- 移動指示のチェック
    -- 検索処理を行い、ロックを取得します。
    ELSIF (iv_biz_type = cv_move) THEN
      SELECT mrih.status,                                   -- ステータス
             mrih.delivery_no                               -- 配送No
      INTO   lv_status,
             lv_delivery_no
      FROM   xxinv_mov_req_instr_headers        mrih        -- 移動依頼/指示ヘッダ(アドオン)
      WHERE  mrih.mov_num                       =  iv_request_no
-- Ver1.30 M.Hokkanji Start
      FOR UPDATE OF mrih.mov_hdr_id NOWAIT;
--      FOR UPDATE NOWAIT;
-- Ver1.30 M.Hokkanji End
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【移動：ステータス】' || lv_status 
         || '【配送No】'           || lv_delivery_no;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
    END IF;
-- 2009/02/20 D.Nihei Add Start 本番障害#1034対応
    -- 配送(混載元)Noが取得できた場合、配送No単位でロックを取得する。
    IF ( lv_delivery_no IS NOT NULL ) THEN
      -- 受注ヘッダアドオンのロック取得
      OPEN  ship_lock_cur;
      CLOSE ship_lock_cur;
      -- 移動依頼ヘッダアドオンのロック取得
      OPEN  mov_lock_cur;
      CLOSE mov_lock_cur;
    END IF;
-- 2009/02/20 D.Nihei Add End
--
    -- **************************************************
    -- *** 2.配車解除可否チェック(出荷)
    -- **************************************************
-- 2008/09/03 H.Itou Add Start PT 1-2_8対応 動的SQLに変更。
    -- 業務種別が「1：出荷」以外で、DBの配送No・混載元Noに値がない場合、検索を行わない。
    IF ( ( iv_biz_type    <> cv_ship )
     AND ( lv_delivery_no IS NULL    ) ) THEN
      NULL;
--
    -- 上記以外の場合、検索実行
    ELSE
      -- INパラメータ.業務種別が「1：出荷」かつ、DBの配送No・混載元NoがNULLの場合、依頼Noで検索
      IF ( ( iv_biz_type = cv_ship ) 
       AND ( lv_delivery_no IS NULL ) ) THEN
        -- SQL生成
        lv_sql := cv_ship_select
               || cv_ship_from
               || cv_ship_where
               || cv_ship_where_request_no
               || cv_ship_order_by
               ;
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【出荷：検索キー(依頼No)】' || iv_request_no; 
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
        -- カーソルオープン
        OPEN cur_ship_data FOR lv_sql
        USING iv_request_no   -- 検索キー(依頼No)
        ;
--
      -- 上記以外の場合、配送No・混載元Noで検索
      ELSE
        -- SQL生成
        lv_sql := cv_ship_select
               || cv_ship_from
               || cv_ship_where
               || cv_ship_where_delivery_no
               || cv_union_all
               || cv_ship_select
               || cv_ship_from
               || cv_ship_where
               || cv_ship_where_mixed_no
               || cv_ship_order_by
               ;
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【出荷：検索キー(配送No/混載元No)】' || lv_delivery_no; 
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
        -- カーソルオープン
        OPEN cur_ship_data FOR lv_sql
        USING lv_delivery_no   -- 検索キー(配送No/混載元No)
             ,lv_delivery_no   -- 検索キー(配送No/混載元No)
        ;
      END IF;
--
      -- バルクフェッチ
      FETCH cur_ship_data BULK COLLECT INTO lt_chk_ship_tbl;
      -- カーソルクローズ
      CLOSE cur_ship_data;
--
    END IF;
--
--    SELECT xoha.order_header_id,                          -- 受注ヘッダアドオンID
--           xoha.req_status,                               -- ステータス
--           xoha.request_no,
--           xoha.notif_status,
--           xoha.prev_notif_status,
--           xola.shipped_quantity,                         -- 出荷実績数量
--           xola.ship_to_quantity,                         -- 入庫実績実績数量
---- Ver1.20 M.Hokkanji START
--           xoha.shipping_method_code,                     -- 配送区分
--           xoha.prod_class,                               -- 商品区分
--           xoha.based_weight,                             -- 基本重量
--           xoha.based_capacity,                           -- 基本容積
--           xoha.weight_capacity_class,                    -- 重量容積区分
--           xoha.deliver_from,                             -- 出荷元
--           xoha.deliver_to,                               -- 配送先
--           xoha.schedule_ship_date,                       -- 出庫予定日
--           xoha.sum_weight,                               -- 積載重量合計
--           xoha.sum_capacity,                             -- 積載容積合計
--           xoha.sum_pallet_weight,                        -- 合計パレット重量
--           xoha.freight_charge_class,                     -- 運賃区分
--           xoha.loading_efficiency_weight,                -- 積載率(重量)
--           xoha.loading_efficiency_capacity               -- 積載率(容積)
---- Ver1.20 M.Hokkanji END
--    BULK COLLECT INTO
--           lt_chk_ship_tbl
--    FROM   xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
--           xxwsh_order_lines_all              xola,       -- 受注明細アドオン
--           xxwsh_oe_transaction_types2_v       xott        -- 受注タイプ情報VIEW
--    WHERE  (((iv_biz_type = cv_ship) AND (lv_delivery_no IS NULL) AND
--             (xoha.request_no = iv_request_no))
--    OR     (((iv_biz_type <> cv_ship) OR
--           ((iv_biz_type = cv_ship) AND (lv_delivery_no IS NOT NULL))) AND
---- Ver1.20 M.Hokkanji START
--             (NVL(xoha.delivery_no,xoha.mixed_no) = lv_delivery_no)))
----             (xoha.delivery_no = lv_delivery_no)))
---- Ver1.20 M.Hokkanji End
--    AND    xoha.order_type_id                         =  xott.transaction_type_id
--    AND    xoha.order_header_id                       =  xola.order_header_id
--    AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
--    AND    xott.shipping_shikyu_class                 =  cv_ship_req
--    AND    xott.order_category_code                   =  cv_cate_order
--    AND    xott.start_date_active                     <= trunc( xoha.schedule_ship_date )
--    AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
--                                                      >= trunc( xoha.schedule_ship_date )
--    AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
--    ORDER BY xoha.order_header_id;
-- 2008/09/03 H.Itou Mod End
    IF  ( lt_chk_ship_tbl.COUNT > 0 ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【出荷：配車解除ロジック：件数】' || lt_chk_ship_tbl.COUNT;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- データが存在する場合はカウント
      ln_data_count := ln_data_count + 1;
      -- 取得したレコードの分だけループ
      <<lt_chk_ship_tbl_loop>>
      FOR i IN lt_chk_ship_tbl.FIRST .. lt_chk_ship_tbl.LAST LOOP
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '　【依頼No】'      || lt_chk_ship_tbl(i).request_no 
         || '【ステータス】'  || lt_chk_ship_tbl(i).req_status 
         || '【出荷実績数量】'|| lt_chk_ship_tbl(i).shipped_quantity;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
--
        -- ステータスが｢入力中｣｢拠点確定｣｢締め済み｣で出荷実績数量がNULLでないデータは配車解除不可
        IF ( ( lt_chk_ship_tbl(i).req_status       <= cv_tightening) AND
             ( lt_chk_ship_tbl(i).shipped_quantity IS NOT NULL     ) ) THEN
          ln_no_count := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
          IF (lv_msg_ship_err IS NULL) THEN
            lv_msg_ship_err := lt_chk_ship_tbl(i).request_no;
          ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--            lv_msg_ship_err := lv_msg_ship_err
--                               || cv_msg_com
--                               || lt_chk_ship_tbl(i).request_no;
            lv_msg_ship_err := SUBSTRB( lv_msg_ship_err || cv_msg_com || lt_chk_ship_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
-- Ver1.20 M.Hokkanji END
          END IF;
--
        -- ステータスが｢出荷実績計上済｣｢取消｣のデータは配車解除不可
        ELSIF (lt_chk_ship_tbl(i).req_status > cv_tightening) THEN
          IF (lv_msg_ship_err IS NULL) THEN
-- Ver1.20 M.Hokkanji START
--            lv_msg_ship_err := iv_request_no;
            lv_msg_ship_err := lt_chk_ship_tbl(i).request_no;
-- Ver1.20 M.Hokkanji END
          ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
---- Ver1.20 M.Hokkanji START
--            lv_msg_ship_err := lv_msg_ship_err
--                               || cv_msg_com
--                               || lt_chk_ship_tbl(i).request_no;
----                               || iv_request_no;
---- Ver1.20 M.Hokkanji END
            lv_msg_ship_err := SUBSTRB( lv_msg_ship_err || cv_msg_com || lt_chk_ship_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
          END IF;
          ln_no_count     := ln_no_count + 1;
--
-- Ver1.20 M.Hokkanji START
        ELSE
-- 2008/10/23 v1.28 D.Nihei Mod Start TE080_BPO_600 No22
--          -- 運賃区分が1の場合のみ取得した配送区分、基本重量、基本容積、積載率(重量)、積載率(容積)を更新
--          IF (lt_chk_ship_tbl(i).freight_charge_class = gv_freight_charge_yes) THEN
          -- 運賃区分が1の場合のみ取得した配送区分、基本重量、基本容積、積載率(重量)、積載率(容積)を更新
          -- 且つ配車解除フラグがONの場合、処理をおこなう
          IF ( ( lt_chk_ship_tbl(i).freight_charge_class = gv_freight_charge_yes )
-- 2009/02/10 H.Itou Add Start 本番障害#863対応 配車解除フラグが2の場合も解除用に数値を取得する。
--           AND ( iv_calcel_flag                          = cv_cancel_flag_on     ) ) THEN
           AND ( iv_calcel_flag IN ( cv_cancel_flag_on, cv_cancel_flag_judge ) ) ) THEN
-- 2009/02/10 H.Itou Add End
-- 2008/10/23 v1.28 D.Nihei Mod End
            lv_err_chek := '0'; -- エラーチェックフラグを初期値に戻す
            -- 最大配送区分取得
            ln_ret_code := get_max_ship_method(
                             iv_code_class1                => cv_code_kbn_mov,
                             iv_entering_despatching_code1 => lt_chk_ship_tbl(i).deliver_from,
                             iv_code_class2                => cv_code_kbn_ship,
                             iv_entering_despatching_code2 => lt_chk_ship_tbl(i).deliver_to,
                             iv_prod_class                 => lt_chk_ship_tbl(i).prod_class,
                             iv_weight_capacity_class      => lt_chk_ship_tbl(i).weight_capacity_class,
                             iv_auto_process_type          => NULL,
                             id_standard_date              => lt_chk_ship_tbl(i).schedule_ship_date,
                             ov_max_ship_methods           => lt_max_ship_methods,
                             on_drink_deadweight           => lt_drink_deadweight,
                             on_leaf_deadweight            => lt_leaf_deadweight,
                             on_drink_loading_capacity     => lt_drink_loading_capacity,
                             on_leaf_loading_capacity      => lt_leaf_loading_capacity,
                             on_palette_max_qty            => lt_palette_max_qty);
            IF (ln_ret_code <> gn_status_normal) THEN
              IF (lv_msg_ship_max_err IS NULL) THEN
                lv_msg_ship_max_err := lt_chk_ship_tbl(i).request_no;
              ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                lv_msg_ship_max_err := lv_msg_ship_max_err
--                                   || cv_msg_com
--                                   || lt_chk_ship_tbl(i).request_no;
                lv_msg_ship_max_err := SUBSTRB( lv_msg_ship_max_err || cv_msg_com || lt_chk_ship_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
              END IF;
              ln_no_count     := ln_no_count + 1;
              lv_err_chek     := '1';
            ELSE
              -- 商品区分がドリンクの場合
              IF (lt_chk_ship_tbl(i).prod_class = cv_prod_class_2) THEN
                lt_chk_ship_tbl(i).based_weight       := lt_drink_deadweight;
                lt_chk_ship_tbl(i).based_capacity     := lt_drink_loading_capacity;
              ELSE
-- 2008/12/13 D.Nihei Mod Start ================================================
--                lt_chk_ship_tbl(i).based_weight       := lt_drink_deadweight;
--                lt_chk_ship_tbl(i).based_capacity     := lt_drink_loading_capacity;
                lt_chk_ship_tbl(i).based_weight       := lt_leaf_deadweight;
                lt_chk_ship_tbl(i).based_capacity     := lt_leaf_loading_capacity;
-- 2008/12/13 D.Nihei Mod End   ================================================
              END IF;
              lt_chk_ship_tbl(i).shipping_method_code := lt_max_ship_methods;
            END IF;
--
            -- 最大配送区分の取得に成功している場合
            IF (lv_err_chek = '0') THEN
              BEGIN
--
                -- 取得した配送区分をもとにクイックコード｢XXCMN_SHIP_METHOD｣から小口区分を取得
                SELECT  xsm2.small_amount_class
                  INTO  lv_small_sum_class
                  FROM  xxwsh_ship_method2_v    xsm2
                 WHERE  xsm2.ship_method_code   =  lt_chk_ship_tbl(i).shipping_method_code
                   AND  xsm2.start_date_active  <= lt_chk_ship_tbl(i).schedule_ship_date
                   AND  lt_chk_ship_tbl(i).schedule_ship_date <= NVL(xsm2.end_date_active,
                                                                     lt_chk_ship_tbl(i).schedule_ship_date);
--
              EXCEPTION
                WHEN OTHERS THEN
                  IF (lv_msg_ship_small_err IS NULL) THEN
                    lv_msg_ship_small_err := lt_chk_ship_tbl(i).request_no;
                  ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                    lv_msg_ship_small_err := lv_msg_ship_small_err
--                                           || cv_msg_com
--                                           || lt_chk_ship_tbl(i).request_no;
                    lv_msg_ship_small_err := SUBSTRB( lv_msg_ship_small_err || cv_msg_com || lt_chk_ship_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                  END IF;
                  ln_no_count     := ln_no_count + 1;
                  lv_err_chek     := '1';
              END;
            END IF;
--
            -- 最大配送区分、小口区分の取得に成功している場合
            IF (lv_err_chek = '0') THEN
              IF (lv_small_sum_class = cv_include) THEN
                ln_sum_weight := lt_chk_ship_tbl(i).sum_weight;
              ELSE
                ln_sum_weight := lt_chk_ship_tbl(i).sum_weight + NVL(lt_chk_ship_tbl(i).sum_pallet_weight,0);
              END IF;
              --積載効率(重量)を取得
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 => ln_sum_weight,                             -- 1.合計重量
                in_sum_capacity               =>  NULL,                                     -- 2.合計容積
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
                iv_entering_despatching_code1 =>  lt_chk_ship_tbl(i).deliver_from,          -- 4.入出庫場所コード１
                iv_code_class2                =>  cv_code_kbn_ship,                         -- 5.コード区分２
                iv_entering_despatching_code2 =>  lt_chk_ship_tbl(i).deliver_to,            -- 6.入出庫場所コード２
                iv_ship_method                =>  lt_chk_ship_tbl(i).shipping_method_code,  -- 7.出荷方法
                iv_prod_class                 =>  lt_chk_ship_tbl(i).prod_class,            -- 8.商品区分
                iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
                id_standard_date              =>  lt_chk_ship_tbl(i).schedule_ship_date,    -- 10.基準日(適用日基準日)
                ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
                ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
              -- リターンコードが'1'(異常)の場合はエラーをセット
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_ship_wei_err IS NULL) THEN
                  lv_msg_ship_wei_err := lt_chk_ship_tbl(i).request_no;
                ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                  lv_msg_ship_wei_err := lv_msg_ship_wei_err
--                                           || cv_msg_com
--                                           || lt_chk_ship_tbl(i).request_no;
                  lv_msg_ship_wei_err := SUBSTRB( lv_msg_ship_wei_err || cv_msg_com || lt_chk_ship_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- 異常ではない場合積載率(重量)をセット
                lt_chk_ship_tbl(i).loading_efficiency_weight := ln_load_efficiency_weight;
--
              END IF;
              --積載効率(容積)を取得
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  NULL,                                     -- 1.合計重量
                in_sum_capacity               =>  lt_chk_ship_tbl(i).sum_capacity,          -- 2.合計容積
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
                iv_entering_despatching_code1 =>  lt_chk_ship_tbl(i).deliver_from,          -- 4.入出庫場所コード１
                iv_code_class2                =>  cv_code_kbn_ship,                         -- 5.コード区分２
                iv_entering_despatching_code2 =>  lt_chk_ship_tbl(i).deliver_to,            -- 6.入出庫場所コード２
                iv_ship_method                =>  lt_chk_ship_tbl(i).shipping_method_code,  -- 7.出荷方法
                iv_prod_class                 =>  lt_chk_ship_tbl(i).prod_class,            -- 8.商品区分
                iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
                id_standard_date              =>  lt_chk_ship_tbl(i).schedule_ship_date,    -- 10.基準日(適用日基準日)
                ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
                ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
              -- リターンコードが'1'(異常)の場合はエラーをセット
              IF (lv_retcode = gn_status_error) THEN
                IF (lv_msg_ship_cap_err IS NULL) THEN
                  lv_msg_ship_cap_err := lt_chk_ship_tbl(i).request_no;
                ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                  lv_msg_ship_cap_err := lv_msg_ship_cap_err
--                                           || cv_msg_com
--                                           || lt_chk_ship_tbl(i).request_no;
                  lv_msg_ship_cap_err := SUBSTRB( lv_msg_ship_cap_err || cv_msg_com || lt_chk_ship_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- 異常ではない場合積載率(容積)をセット
                lt_chk_ship_tbl(i).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 M.Hokkanji END
        END IF;
--
      END LOOP lt_chk_ship_tbl_loop;
--
    END IF;
--
    -- **************************************************
    -- *** 3.配車解除可否チェック(移動)
    -- **************************************************
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【移動：検索キー(移動番号)】' || iv_request_no
         || '【(配送No)】'   || lv_delivery_no; 
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
    SELECT mrih.mov_hdr_id,                               -- 移動ヘッダID
           mrih.status,                                   -- ステータス
           mrih.mov_num,
           mrih.notif_status,
           mrih.prev_notif_status,
-- 2008/08/28 H.Itou Mod Start PT 1-2_8 指摘#32
--           mril.shipped_quantity,                         -- 出庫実績数量
           mrih.shipped_quantity,                         -- 出庫実績数量
--           mril.ship_to_quantity                          -- 入庫実績数量
           mrih.ship_to_quantity,                         -- 入庫実績数量
-- 2008/08/28 H.Itou Mod End
-- Ver1.20 M.Hokkanji START
           mrih.shipping_method_code,                     -- 配送区分
           mrih.item_class,                               -- 商品区分
           mrih.based_weight,                             -- 基本重量
           mrih.based_capacity,                           -- 基本容積
           mrih.weight_capacity_class,                    -- 重量容積区分
           mrih.shipped_locat_code,                       -- 出庫元
           mrih.ship_to_locat_code,                       -- 入庫先
           mrih.schedule_ship_date,                       -- 出庫予定日
           mrih.sum_weight,                               -- 積載重量合計
           mrih.sum_capacity,                             -- 積載容積合計
           mrih.sum_pallet_weight,                        -- 合計パレット重量
           mrih.freight_charge_class,                     -- 運賃区分
           mrih.loading_efficiency_weight,                -- 積載率(重量)
           mrih.loading_efficiency_capacity               -- 積載率(容積)
-- Ver1.20 M.Hokkanji END
    BULK COLLECT INTO
           lt_chk_move_tbl
-- 2008/08/28 H.Itou Mod Start PT 1-2_8 指摘#32 OR句があるとINDEXが使われないため、UNION ALLする。
--    FROM   xxinv_mov_req_instr_headers        mrih,       -- 移動依頼/指示ヘッダ(アドオン)
--           xxinv_mov_req_instr_lines          mril        -- 移動依頼/指示明細(アドオン)
--    WHERE  (((iv_biz_type = cv_move) AND (lv_delivery_no IS NULL) AND
--             (mrih.mov_num = iv_request_no))
--    OR     (((iv_biz_type <> cv_move) OR
--           ((iv_biz_type = cv_move) AND (lv_delivery_no IS NOT NULL))) AND
--             (mrih.delivery_no = lv_delivery_no)))
--    AND    mrih.mov_hdr_id                    =  mril.mov_hdr_id
    FROM  (SELECT mrih1.mov_hdr_id                   mov_hdr_id                   -- 移動ヘッダID
                 ,mrih1.status                       status                       -- ステータス
                 ,mrih1.mov_num                      mov_num                      -- 移動番号
                 ,mrih1.notif_status                 notif_status                 -- 通知ステータス
                 ,mrih1.prev_notif_status            prev_notif_status            -- 前回通知ステータス
                 ,mril.shipped_quantity              shipped_quantity             -- 出庫実績数量
                 ,mril.ship_to_quantity              ship_to_quantity             -- 入庫実績数量
                 ,mrih1.shipping_method_code         shipping_method_code         -- 配送区分
                 ,mrih1.item_class                   item_class                   -- 商品区分
                 ,mrih1.based_weight                 based_weight                 -- 基本重量
                 ,mrih1.based_capacity               based_capacity               -- 基本容積
                 ,mrih1.weight_capacity_class        weight_capacity_class        -- 重量容積区分
                 ,mrih1.shipped_locat_code           shipped_locat_code           -- 出庫元
                 ,mrih1.ship_to_locat_code           ship_to_locat_code           -- 入庫先
                 ,mrih1.schedule_ship_date           schedule_ship_date           -- 出庫予定日
                 ,mrih1.sum_weight                   sum_weight                   -- 積載重量合計
                 ,mrih1.sum_capacity                 sum_capacity                 -- 積載容積合計
                 ,mrih1.sum_pallet_weight            sum_pallet_weight            -- 合計パレット重量
                 ,mrih1.freight_charge_class         freight_charge_class         -- 運賃区分
                 ,mrih1.loading_efficiency_weight    loading_efficiency_weight    -- 積載率(重量)
                 ,mrih1.loading_efficiency_capacity  loading_efficiency_capacity  -- 積載率(容積)
           FROM   xxinv_mov_req_instr_headers        mrih1                        -- 移動依頼/指示ヘッダ(アドオン)
                 ,xxinv_mov_req_instr_lines          mril                         -- 移動依頼/指示明細(アドオン)
           WHERE  iv_biz_type      = cv_move
           AND    lv_delivery_no  IS NULL
           AND    mrih1.mov_num    = iv_request_no
           AND    mrih1.mov_hdr_id = mril.mov_hdr_id
           ----------------------
           UNION ALL
           ----------------------
           SELECT mrih1.mov_hdr_id                   mov_hdr_id                   -- 移動ヘッダID
                 ,mrih1.status                       status                       -- ステータス
                 ,mrih1.mov_num                      mov_num                      -- 移動番号
                 ,mrih1.notif_status                 notif_status                 -- 通知ステータス
                 ,mrih1.prev_notif_status            prev_notif_status            -- 前回通知ステータス
                 ,mril.shipped_quantity              shipped_quantity             -- 出庫実績数量
                 ,mril.ship_to_quantity              ship_to_quantity             -- 入庫実績数量
                 ,mrih1.shipping_method_code         shipping_method_code         -- 配送区分
                 ,mrih1.item_class                   item_class                   -- 商品区分
                 ,mrih1.based_weight                 based_weight                 -- 基本重量
                 ,mrih1.based_capacity               based_capacity               -- 基本容積
                 ,mrih1.weight_capacity_class        weight_capacity_class        -- 重量容積区分
                 ,mrih1.shipped_locat_code           shipped_locat_code           -- 出庫元
                 ,mrih1.ship_to_locat_code           ship_to_locat_code           -- 入庫先
                 ,mrih1.schedule_ship_date           schedule_ship_date           -- 出庫予定日
                 ,mrih1.sum_weight                   sum_weight                   -- 積載重量合計
                 ,mrih1.sum_capacity                 sum_capacity                 -- 積載容積合計
                 ,mrih1.sum_pallet_weight            sum_pallet_weight            -- 合計パレット重量
                 ,mrih1.freight_charge_class         freight_charge_class         -- 運賃区分
                 ,mrih1.loading_efficiency_weight    loading_efficiency_weight    -- 積載率(重量)
                 ,mrih1.loading_efficiency_capacity  loading_efficiency_capacity  -- 積載率(容積)
           FROM   xxinv_mov_req_instr_headers        mrih1                        -- 移動依頼/指示ヘッダ(アドオン)
                 ,xxinv_mov_req_instr_lines          mril                         -- 移動依頼/指示明細(アドオン)
           WHERE ((iv_biz_type         <> cv_move)
             OR   ((iv_biz_type         = cv_move)
               AND (lv_delivery_no IS NOT NULL)))
           AND    mrih1.delivery_no     = lv_delivery_no
           AND    mrih1.mov_hdr_id      = mril.mov_hdr_id
           ) mrih
-- 2008/08/28 H.Itou Mod End
    ORDER BY mrih.mov_hdr_id;
--
    IF (lt_chk_move_tbl.COUNT > 0) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【移動：配車解除ロジック：件数】' || lt_chk_move_tbl.COUNT;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- データが存在する場合はカウント
      ln_data_count := ln_data_count + 1;
      -- 取得したレコードの分だけループ
      <<lt_chk_move_tbl_loop>>
      FOR i IN lt_chk_move_tbl.FIRST .. lt_chk_move_tbl.LAST LOOP
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '　【移動番号】'    || lt_chk_move_tbl(i).mov_num 
         || '【ステータス】'  || lt_chk_move_tbl(i).status 
         || '【出庫実績数量】'|| lt_chk_move_tbl(i).shipped_quantity
         || '【入庫実績数量】'|| lt_chk_move_tbl(i).ship_to_quantity;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
--
        -- ステータスが｢依頼中｣｢依頼済｣｢調整中｣で、
        -- 出庫実績数量または入庫実績数量がNULLでないデータは配車解除不可
        IF ( ( lt_chk_move_tbl(i).status <= cv_adjustment ) 
         AND (   ( lt_chk_move_tbl(i).shipped_quantity IS NOT NULL) 
              OR ( lt_chk_move_tbl(i).ship_to_quantity IS NOT NULL) ) ) THEN
          ln_no_count := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
          IF ( lv_msg_move_err IS NULL ) THEN
            lv_msg_move_err := lt_chk_move_tbl(i).mov_num;
          ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--            lv_msg_move_err := lv_msg_move_err
--                               || cv_msg_com
--                               || lt_chk_move_tbl(i).mov_num;
            lv_msg_move_err := SUBSTRB( lv_msg_move_err || cv_msg_com || lt_chk_move_tbl(i).mov_num, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
          END IF;
-- Ver1.20 M.Hokkanji END
--
        -- ステータスが｢出荷実績計上済｣｢取消｣のデータは配車解除不可
        ELSIF ( lt_chk_move_tbl(i).status > cv_adjustment ) THEN
          IF (lv_msg_move_err IS NULL) THEN
-- Ver1.20 M.Hokkanji START
            lv_msg_move_err := lt_chk_move_tbl(i).mov_num;
--            lv_msg_move_err := iv_request_no;
-- Ver1.20 M.Hokkanji END
          ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
---- Ver1.20 M.Hokkanji START
--            lv_msg_move_err := lv_msg_move_err
--                               || cv_msg_com
--                               || lt_chk_move_tbl(i).mov_num;
----                               || iv_request_no;
---- Ver1.20 M.Hokkanji END
            lv_msg_move_err := SUBSTRB( lv_msg_move_err || cv_msg_com || lt_chk_move_tbl(i).mov_num, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
          END IF;
          ln_no_count     := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
        ELSE
-- 2008/10/23 v1.28 D.Nihei Mod Start TE080_BPO_600 No22
--          -- 運賃区分が1の場合のみ取得した配送区分、基本重量、基本容積、積載率(重量)、積載率(容積)を更新
--          IF (lt_chk_move_tbl(i).freight_charge_class = gv_freight_charge_yes) THEN
          -- 運賃区分が1の場合のみ取得した配送区分、基本重量、基本容積、積載率(重量)、積載率(容積)を更新
          -- 且つ配車解除フラグがONの場合、処理をおこなう
          IF ( ( lt_chk_move_tbl(i).freight_charge_class = gv_freight_charge_yes )
-- 2009/02/10 H.Itou Add Start 本番障害#863対応 配車解除フラグが2の場合も解除用に数値を取得する。
--           AND ( iv_calcel_flag                          = cv_cancel_flag_on     ) ) THEN
           AND ( iv_calcel_flag IN ( cv_cancel_flag_on, cv_cancel_flag_judge ) ) ) THEN
-- 2009/02/10 H.Itou Add End
-- 2008/10/23 v1.28 D.Nihei Mod End
            lv_err_chek := '0'; -- エラーチェックフラグを初期値に戻す
            -- 最大配送区分取得
            ln_ret_code := get_max_ship_method(
                             iv_code_class1                => cv_code_kbn_mov,
                             iv_entering_despatching_code1 => lt_chk_move_tbl(i).shipped_locat_code,
                             iv_code_class2                => cv_code_kbn_mov,
                             iv_entering_despatching_code2 => lt_chk_move_tbl(i).ship_to_locat_code,
                             iv_prod_class                 => lt_chk_move_tbl(i).item_class,
                             iv_weight_capacity_class      => lt_chk_move_tbl(i).weight_capacity_class,
                             iv_auto_process_type          => NULL,
                             id_standard_date              => lt_chk_move_tbl(i).schedule_ship_date,
                             ov_max_ship_methods           => lt_max_ship_methods,
                             on_drink_deadweight           => lt_drink_deadweight,
                             on_leaf_deadweight            => lt_leaf_deadweight,
                             on_drink_loading_capacity     => lt_drink_loading_capacity,
                             on_leaf_loading_capacity      => lt_leaf_loading_capacity,
                             on_palette_max_qty            => lt_palette_max_qty);
            IF ( ln_ret_code <> gn_status_normal ) THEN
              IF ( lv_msg_move_max_err IS NULL ) THEN
                lv_msg_move_max_err := lt_chk_move_tbl(i).mov_num;
              ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                lv_msg_move_max_err := lv_msg_move_max_err
--                                   || cv_msg_com
--                                   || lt_chk_move_tbl(i).mov_num;
                lv_msg_move_max_err := SUBSTRB( lv_msg_move_max_err || cv_msg_com || lt_chk_move_tbl(i).mov_num, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
              END IF;
              ln_no_count     := ln_no_count + 1;
              lv_err_chek     := '1';
            ELSE
              -- 商品区分がドリンクの場合
              IF ( lt_chk_move_tbl(i).item_class = cv_prod_class_2 ) THEN
                lt_chk_move_tbl(i).based_weight       := lt_drink_deadweight;
                lt_chk_move_tbl(i).based_capacity     := lt_drink_loading_capacity;
              ELSE
-- 2008/12/13 D.Nihei Mod Start ================================================
--                lt_chk_move_tbl(i).based_weight       := lt_drink_deadweight;
--                lt_chk_move_tbl(i).based_capacity     := lt_drink_loading_capacity;
                lt_chk_move_tbl(i).based_weight       := lt_leaf_deadweight;
                lt_chk_move_tbl(i).based_capacity     := lt_leaf_loading_capacity;
-- 2008/12/13 D.Nihei Mod End   ================================================
              END IF;
              lt_chk_move_tbl(i).shipping_method_code := lt_max_ship_methods;
            END IF;
--
            -- 最大配送区分の取得に成功している場合
            IF ( lv_err_chek = '0' ) THEN
              BEGIN
--
                -- 取得した配送区分をもとにクイックコード｢XXCMN_SHIP_METHOD｣から小口区分を取得
                SELECT  xsm2.small_amount_class
                  INTO  lv_small_sum_class
                  FROM  xxwsh_ship_method2_v    xsm2
                 WHERE  xsm2.ship_method_code   =  lt_chk_move_tbl(i).shipping_method_code
                   AND  xsm2.start_date_active  <= lt_chk_move_tbl(i).schedule_ship_date
                   AND  lt_chk_move_tbl(i).schedule_ship_date <= NVL(xsm2.end_date_active,
                                                                     lt_chk_move_tbl(i).schedule_ship_date);
--
              EXCEPTION
                WHEN OTHERS THEN
                  IF ( lv_msg_move_small_err IS NULL ) THEN
                    lv_msg_move_small_err := lt_chk_move_tbl(i).mov_num;
                  ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                    lv_msg_move_small_err := lv_msg_move_small_err
--                                           || cv_msg_com
--                                           || lt_chk_move_tbl(i).mov_num;
                    lv_msg_move_small_err := SUBSTRB( lv_msg_move_small_err || cv_msg_com || lt_chk_move_tbl(i).mov_num, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                  END IF;
                  ln_no_count     := ln_no_count + 1;
                  lv_err_chek     := '1';
              END;
            END IF;
--
            -- 最大配送区分、小口区分の取得に成功している場合
            IF ( lv_err_chek = '0' ) THEN
              IF ( lv_small_sum_class = cv_include ) THEN
-- Ver1.22 M.Hokkanji START
--                ln_sum_weight := lt_chk_ship_tbl(i).sum_weight;
                ln_sum_weight := lt_chk_move_tbl(i).sum_weight;
-- Ver1.22 M.Hokkanji END
              ELSE
-- Ver1.22 M.Hokkanji START
--                ln_sum_weight := lt_chk_ship_tbl(i).sum_weight + NVL(lt_chk_ship_tbl(i).sum_pallet_weight,0);
                ln_sum_weight := lt_chk_move_tbl(i).sum_weight + NVL(lt_chk_move_tbl(i).sum_pallet_weight,0);
-- Ver1.22 M.Hokkanji END
              END IF;
              --積載効率(重量)を取得
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  ln_sum_weight,                            -- 1.合計重量
                in_sum_capacity               =>  NULL,                                     -- 2.合計容積
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
                iv_entering_despatching_code1 =>  lt_chk_move_tbl(i).shipped_locat_code,    -- 4.入出庫場所コード１
                iv_code_class2                =>  cv_code_kbn_mov,                          -- 5.コード区分２
                iv_entering_despatching_code2 =>  lt_chk_move_tbl(i).ship_to_locat_code,    -- 6.入出庫場所コード２
                iv_ship_method                =>  lt_chk_move_tbl(i).shipping_method_code,  -- 7.出荷方法
                iv_prod_class                 =>  lt_chk_move_tbl(i).item_class,            -- 8.商品区分
                iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
                id_standard_date              =>  lt_chk_move_tbl(i).schedule_ship_date,    -- 10.基準日(適用日基準日)
                ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
                ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
              -- リターンコードが'1'(異常)の場合はエラーをセット
              IF ( lv_retcode = gn_status_error ) THEN
                IF ( lv_msg_move_wei_err IS NULL ) THEN
                  lv_msg_move_wei_err := lt_chk_move_tbl(i).mov_num;
                ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                  lv_msg_move_wei_err := lv_msg_move_wei_err
--                                           || cv_msg_com
--                                           || lt_chk_move_tbl(i).mov_num;
                  lv_msg_move_wei_err := SUBSTRB( lv_msg_move_wei_err || cv_msg_com || lt_chk_move_tbl(i).mov_num, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- 異常ではない場合積載率(重量)をセット
                lt_chk_move_tbl(i).loading_efficiency_weight := ln_load_efficiency_weight;
--
              END IF;
              --積載効率(容積)を取得
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  NULL,                                     -- 1.合計重量
                in_sum_capacity               =>  lt_chk_move_tbl(i).sum_capacity,          -- 2.合計容積
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
                iv_entering_despatching_code1 =>  lt_chk_move_tbl(i).shipped_locat_code,    -- 4.入出庫場所コード１
                iv_code_class2                =>  cv_code_kbn_mov,                          -- 5.コード区分２
                iv_entering_despatching_code2 =>  lt_chk_move_tbl(i).ship_to_locat_code,    -- 6.入出庫場所コード２
                iv_ship_method                =>  lt_chk_move_tbl(i).shipping_method_code,  -- 7.出荷方法
                iv_prod_class                 =>  lt_chk_move_tbl(i).item_class,            -- 8.商品区分
                iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
                id_standard_date              =>  lt_chk_move_tbl(i).schedule_ship_date,    -- 10.基準日(適用日基準日)
                ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
                ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
              -- リターンコードが'1'(異常)の場合はエラーをセット
              IF ( lv_retcode = gn_status_error ) THEN
                IF ( lv_msg_move_cap_err IS NULL ) THEN
                  lv_msg_move_cap_err := lt_chk_move_tbl(i).mov_num;
                ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                  lv_msg_move_cap_err := lv_msg_move_cap_err
--                                           || cv_msg_com
--                                           || lt_chk_move_tbl(i).mov_num;
                  lv_msg_move_cap_err := SUBSTRB( lv_msg_move_cap_err || cv_msg_com || lt_chk_move_tbl(i).mov_num, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- 異常ではない場合積載率(容積)をセット
                lt_chk_move_tbl(i).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 M.Hokkanji END
        END IF;
--
      END LOOP lt_chk_move_tbl_loop;
--
    END IF;
--
    -- **************************************************
    -- *** 4.配車解除可否チェック(支給)
    -- **************************************************
-- 2008/09/03 H.Itou Mod Start PT 1-2_8対応
    -- 業務種別が「2：支給」以外で、DBの配送No・混載元Noに値がない場合、検索を行わない。
    IF ( ( iv_biz_type    <> cv_supply ) 
     AND ( lv_delivery_no IS NULL      ) ) THEN
      NULL;
--
    -- 上記以外の場合、検索実行
    ELSE
      -- INパラメータ.業務種別が「2：支給」かつ、DBの配送NoがNULLの場合、依頼Noで検索
      IF ( ( iv_biz_type     = cv_supply ) 
       AND ( lv_delivery_no IS NULL      ) ) THEN
        lv_where_search_key := cv_supply_where_request_no;
        lv_search_key_no    := iv_request_no;
--
      -- 上記以外は配送Noで検索
      ELSE
        lv_where_search_key := cv_supply_where_delivery_no;
        lv_search_key_no    := lv_delivery_no;
--
      END IF;
--
      -- SQL生成
      lv_sql := cv_supply_select
             || cv_supply_from
             || cv_supply_where
             || lv_where_search_key
             || cv_supply_order_by
             ;
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【支給：検索キー】' || lv_search_key_no; 
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- カーソルオープン
      OPEN cur_supply_data FOR lv_sql
      USING lv_search_key_no;  -- 検索キー（依頼Noか配送No/混載元No)
      -- バルクフェッチ
      FETCH cur_supply_data BULK COLLECT INTO lt_chk_supply_tbl;
      -- カーソルクローズ
      CLOSE cur_supply_data;
    END IF;
--
--
--    SELECT xoha.order_header_id,                          -- 受注ヘッダアドオンID
--           xoha.req_status,                               -- ステータス
--           xoha.request_no,
--           xoha.notif_status,
--           xoha.prev_notif_status,
--           xola.shipped_quantity,                         -- 出荷実績数量
--           xola.ship_to_quantity,                         -- 入庫実績実績数量
---- Ver1.20 M.Hokkanji START
--           xoha.shipping_method_code,                     -- 配送区分
--           xoha.prod_class,                               -- 商品区分
--           xoha.based_weight,                             -- 基本重量
--           xoha.based_capacity,                           -- 基本容積
--           xoha.weight_capacity_class,                    -- 重量容積区分
--           xoha.deliver_from,                             -- 出荷元
--           xoha.vendor_site_code,                         -- 取引先サイト
--           xoha.schedule_ship_date,                       -- 出庫予定日
--           xoha.sum_weight,                               -- 積載重量合計
--           xoha.sum_capacity,                             -- 積載容積合計
--           xoha.freight_charge_class,                     -- 運賃区分
--           xoha.loading_efficiency_weight,                -- 積載率(重量)
--           xoha.loading_efficiency_capacity               -- 積載率(容積)
---- Ver1.20 M.Hokkanji END
--    BULK COLLECT INTO
--           lt_chk_supply_tbl
--    FROM   xxwsh_order_headers_all            xoha,       -- 受注ヘッダアドオン
--           xxwsh_order_lines_all              xola,       -- 受注明細アドオン
--           xxwsh_oe_transaction_types2_v       xott        -- 受注タイプ情報VIEW
--    WHERE  (((iv_biz_type = cv_supply) AND (lv_delivery_no IS NULL) AND
--             (xoha.request_no = iv_request_no))
--    OR     (((iv_biz_type <> cv_supply) OR
--           ((iv_biz_type = cv_supply) AND (lv_delivery_no IS NOT NULL))) AND
--             (xoha.delivery_no = lv_delivery_no)))
--    AND    xoha.order_type_id                         =  xott.transaction_type_id
--    AND    xoha.order_header_id                       =  xola.order_header_id
--    AND    NVL(xola.delete_flag, cv_flag_no)          =  cv_flag_no
--    AND    xott.shipping_shikyu_class                 =  cv_supply_req
--    AND    xott.order_category_code                   =  cv_cate_order
--    AND    xott.start_date_active                     <= trunc( xoha.schedule_ship_date )
--    AND    NVL(xott.end_date_active,to_date('99991231','YYYYMMDD')) 
--                                                      >= trunc( xoha.schedule_ship_date )
--    AND    NVL(xoha.latest_external_flag, cv_flag_no) =  cv_flag_yes
--    ORDER BY xoha.order_header_id;
-- 2008/09/03 H.Itou Mod End
--
    IF ( lt_chk_supply_tbl.COUNT > 0 ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【支給：配車解除ロジック：件数】' || lt_chk_supply_tbl.COUNT;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- データが存在する場合はカウント
      ln_data_count := ln_data_count + 1;
      -- 取得したレコードの分だけループ
      <<lt_chk_supply_tbl_loop>>
      FOR i IN lt_chk_supply_tbl.FIRST .. lt_chk_supply_tbl.LAST LOOP
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '　【依頼No】'      || lt_chk_supply_tbl(i).request_no 
         || '【ステータス】'  || lt_chk_supply_tbl(i).req_status 
         || '【出荷実績数量】'|| lt_chk_supply_tbl(i).shipped_quantity
         || '【入庫実績数量】'|| lt_chk_supply_tbl(i).ship_to_quantity;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
        -- ステータスが｢入力中｣｢入力済｣｢受領済｣で、
        -- 出荷実績数量または入庫実績数量がNULLでないデータは配車解除不可
        IF ( ( lt_chk_supply_tbl(i).req_status <= cv_received) 
         AND (   ( lt_chk_supply_tbl(i).shipped_quantity IS NOT NULL ) 
              OR ( lt_chk_supply_tbl(i).ship_to_quantity IS NOT NULL ) ) ) THEN
          ln_no_count := ln_no_count + 1;
-- Ver1.20 M.Hokkanji START
          IF ( lv_msg_supply_err IS NULL ) THEN
            lv_msg_supply_err := lt_chk_supply_tbl(i).request_no;
          ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--            lv_msg_supply_err := lv_msg_supply_err
--                                 || cv_msg_com
--                                 || lt_chk_supply_tbl(i).request_no;
            lv_msg_supply_err := SUBSTRB( lv_msg_supply_err || cv_msg_com || lt_chk_supply_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
          END IF;
-- Ver1.20 M.Hokkanji END
--
        -- ステータスが｢出荷実績計上済｣｢取消｣のデータは配車解除不可
        ELSIF ( lt_chk_supply_tbl(i).req_status > cv_received ) THEN
          IF ( lv_msg_supply_err IS NULL ) THEN
-- Ver1.20 M.Hokkanji START
--            lv_msg_supply_err := iv_request_no;
            lv_msg_supply_err := lt_chk_supply_tbl(i).request_no;
-- Ver1.20 M.Hokkanji END
          ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
---- Ver1.20 M.Hokkanji START
--            lv_msg_supply_err := lv_msg_supply_err
--                                 || cv_msg_com
--                                 || lt_chk_supply_tbl(i).request_no;
----                                 || iv_request_no;
---- Ver1.20 M.Hokkanji END
            lv_msg_supply_err := SUBSTRB( lv_msg_supply_err || cv_msg_com || lt_chk_supply_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
          END IF;
          ln_no_count       := ln_no_count + 1;
--
-- Ver1.20 M.Hokkanji START
        ELSE
-- 2008/10/23 v1.28 D.Nihei Mod Start TE080_BPO_600 No22
--          -- 運賃区分が1の場合のみ取得した配送区分、基本重量、基本容積、積載率(重量)、積載率(容積)を更新
--          IF (lt_chk_supply_tbl(i).freight_charge_class = gv_freight_charge_yes) THEN
          -- 運賃区分が1の場合のみ取得した配送区分、基本重量、基本容積、積載率(重量)、積載率(容積)を更新
          -- 且つ配車解除フラグがONの場合、処理をおこなう
          IF ( ( lt_chk_supply_tbl(i).freight_charge_class = gv_freight_charge_yes )
-- 2009/02/10 H.Itou Add Start 本番障害#863対応 配車解除フラグが2の場合も解除用に数値を取得する。
--           AND ( iv_calcel_flag                          = cv_cancel_flag_on     ) ) THEN
           AND ( iv_calcel_flag IN ( cv_cancel_flag_on, cv_cancel_flag_judge ) ) ) THEN
-- 2009/02/10 H.Itou Add End
-- 2008/10/23 v1.28 D.Nihei Mod End
            lv_err_chek := '0'; -- エラーチェックフラグを初期値に戻す
            -- 最大配送区分取得
            ln_ret_code := get_max_ship_method(
                             iv_code_class1                => cv_code_kbn_mov,
                             iv_entering_despatching_code1 => lt_chk_supply_tbl(i).deliver_from,
                             iv_code_class2                => cv_code_kbn_supply,
                             iv_entering_despatching_code2 => lt_chk_supply_tbl(i).vendor_site_code,
                             iv_prod_class                 => lt_chk_supply_tbl(i).prod_class,
                             iv_weight_capacity_class      => lt_chk_supply_tbl(i).weight_capacity_class,
                             iv_auto_process_type          => NULL,
                             id_standard_date              => lt_chk_supply_tbl(i).schedule_ship_date,
                             ov_max_ship_methods           => lt_max_ship_methods,
                             on_drink_deadweight           => lt_drink_deadweight,
                             on_leaf_deadweight            => lt_leaf_deadweight,
                             on_drink_loading_capacity     => lt_drink_loading_capacity,
                             on_leaf_loading_capacity      => lt_leaf_loading_capacity,
                             on_palette_max_qty            => lt_palette_max_qty);
            IF ( ln_ret_code <> gn_status_normal ) THEN
              IF ( lv_msg_supply_max_err IS NULL ) THEN
                lv_msg_supply_max_err := lt_chk_supply_tbl(i).request_no;
              ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                lv_msg_supply_max_err := lv_msg_supply_max_err
--                                   || cv_msg_com
--                                   || lt_chk_supply_tbl(i).request_no;
                lv_msg_supply_max_err := SUBSTRB( lv_msg_supply_max_err || cv_msg_com || lt_chk_supply_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
              END IF;
              ln_no_count     := ln_no_count + 1;
              lv_err_chek     := '1';
            ELSE
              -- 商品区分がドリンクの場合
              IF ( lt_chk_supply_tbl(i).prod_class = cv_prod_class_2 ) THEN
                lt_chk_supply_tbl(i).based_weight       := lt_drink_deadweight;
                lt_chk_supply_tbl(i).based_capacity     := lt_drink_loading_capacity;
              ELSE
-- 2008/12/13 D.Nihei Mod Start ================================================
--                lt_chk_supply_tbl(i).based_weight       := lt_drink_deadweight;
--                lt_chk_supply_tbl(i).based_capacity     := lt_drink_loading_capacity;
                lt_chk_supply_tbl(i).based_weight       := lt_leaf_deadweight;
                lt_chk_supply_tbl(i).based_capacity     := lt_leaf_loading_capacity;
-- 2008/12/13 D.Nihei Mod End   ================================================
              END IF;
              lt_chk_supply_tbl(i).shipping_method_code := lt_max_ship_methods;
            END IF;
--
            -- 最大配送区分の取得に成功している場合
            IF ( lv_err_chek = '0' ) THEN
              --積載効率(重量)を取得
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  lt_chk_supply_tbl(i).sum_weight,          -- 1.合計重量
                in_sum_capacity               =>  NULL,                                     -- 2.合計容積
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
                iv_entering_despatching_code1 =>  lt_chk_supply_tbl(i).deliver_from,        -- 4.入出庫場所コード１
                iv_code_class2                =>  cv_code_kbn_supply,                       -- 5.コード区分２
                iv_entering_despatching_code2 =>  lt_chk_supply_tbl(i).vendor_site_code,    -- 6.入出庫場所コード２
                iv_ship_method                =>  lt_chk_supply_tbl(i).shipping_method_code, -- 7.出荷方法
                iv_prod_class                 =>  lt_chk_supply_tbl(i).prod_class,          -- 8.商品区分
                iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
                id_standard_date              =>  lt_chk_supply_tbl(i).schedule_ship_date,    -- 10.基準日(適用日基準日)
                ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
                ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
              -- リターンコードが'1'(異常)の場合はエラーをセット
              IF ( lv_retcode = gn_status_error ) THEN
                IF ( lv_msg_supply_wei_err IS NULL ) THEN
                  lv_msg_supply_wei_err := lt_chk_supply_tbl(i).request_no;
                ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                  lv_msg_supply_wei_err := lv_msg_supply_wei_err
--                                           || cv_msg_com
--                                           || lt_chk_supply_tbl(i).request_no;
                  lv_msg_supply_wei_err := SUBSTRB( lv_msg_supply_wei_err || cv_msg_com || lt_chk_supply_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- 異常ではない場合積載率(重量)をセット
                lt_chk_supply_tbl(i).loading_efficiency_weight := ln_load_efficiency_weight;
--
              END IF;
              --積載効率(容積)を取得
              xxwsh_common910_pkg.calc_load_efficiency(
                in_sum_weight                 =>  NULL,                                     -- 1.合計重量
                in_sum_capacity               =>  lt_chk_supply_tbl(i).sum_capacity,        -- 2.合計容積
                iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
                iv_entering_despatching_code1 =>  lt_chk_supply_tbl(i).deliver_from,        -- 4.入出庫場所コード１
                iv_code_class2                =>  cv_code_kbn_supply,                       -- 5.コード区分２
                iv_entering_despatching_code2 =>  lt_chk_supply_tbl(i).vendor_site_code,    -- 6.入出庫場所コード２
                iv_ship_method                =>  lt_chk_supply_tbl(i).shipping_method_code,  -- 7.出荷方法
                iv_prod_class                 =>  lt_chk_supply_tbl(i).prod_class,          -- 8.商品区分
                iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
                id_standard_date              =>  lt_chk_supply_tbl(i).schedule_ship_date,    -- 10.基準日(適用日基準日)
                ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
                ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
                ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
                ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
                ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
                on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
                on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
                ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
              -- リターンコードが'1'(異常)の場合はエラーをセット
              IF ( lv_retcode = gn_status_error ) THEN
                IF ( lv_msg_supply_cap_err IS NULL ) THEN
                  lv_msg_supply_cap_err := lt_chk_supply_tbl(i).request_no;
                ELSE
-- 2009/02/20 D.Nihei Mod Start 本番障害#1210対応
--                  lv_msg_supply_cap_err := lv_msg_supply_cap_err
--                                           || cv_msg_com
--                                           || lt_chk_supply_tbl(i).request_no;
                  lv_msg_supply_cap_err := SUBSTRB( lv_msg_supply_cap_err || cv_msg_com || lt_chk_supply_tbl(i).request_no, 1, 493 );
-- 2009/02/20 D.Nihei Mod End
                END IF;
                ln_no_count     := ln_no_count + 1;
                lv_err_chek     := '1';
              ELSE
                -- 異常ではない場合積載率(容積)をセット
                lt_chk_supply_tbl(i).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
              END IF;
--
            END IF;
--
          END IF;
-- Ver1.20 M.Hokkanji END
        END IF;
--
      END LOOP lt_chk_supply_tbl_loop;
--
    END IF;
--
-- 2009/02/10 H.Itou Add Start 本番障害#863対応
-- Ver1.45 M.Hokkanji Start
    lv_skip_flag  := '0';
-- Ver1.45 M.Hokkanji End
    -- **************************************************
    -- *** XX.配車解除判定処理
    -- **************************************************
    -- 配車あり、配車解除フラグ：2 積載オーバーの場合のみ配車解除の場合
    -- 配車解除するかどうか判定し、配車解除しない場合は配車配送計画と混載率を更新する。
    IF ( ( lv_delivery_no IS NOT NULL )
    AND  ( iv_calcel_flag = cv_cancel_flag_judge ) ) THEN
      -- ============================
      -- 配車の重量・容積合計取得
      -- ============================
      SELECT  SUM(xomh.sum_weight)
             ,SUM(xomh.sum_capacity)
             ,SUM(xomh.sum_pallet_weight)
      INTO    ln_deli_sum_w
             ,ln_deli_sum_c
             ,ln_deli_sum_pallet_w
      FROM   (-- 受注データ
-- 2012/07/18 D.Sugahara 1.50 Mod Start(ヒント句追加）
              SELECT  /*+ INDEX ( xoha xxwsh_oh_n24 ) INDEX ( xoha xxwsh_oh_n23 ) */
-- 2012/07/18 D.Sugahara 1.50 Mod End
                      xoha.sum_weight                 sum_weight
                     ,xoha.sum_capacity               sum_capacity
                     ,NVL(xoha.sum_pallet_weight, 0)  sum_pallet_weight
              FROM    xxwsh_order_headers_all         xoha
-- 2012/07/18 D.Sugahara 1.50 Mod Start
---- 2009/02/20 D.Nihei Mod Start 本番障害#863対応
----              WHERE   xoha.delivery_no                            =  lv_delivery_no
--              WHERE   NVL(xoha.delivery_no, xoha.mixed_no)        =  lv_delivery_no
              WHERE  ((xoha.delivery_no = lv_delivery_no) OR
                      (xoha.delivery_no IS NULL AND xoha.mixed_no = lv_delivery_no))
---- 2009/02/20 D.Nihei Mod End
-- 2012/07/18 D.Sugahara 1.50 Mod End
              AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes
              -- 移動データ
              UNION ALL
              SELECT  mrih.sum_weight                 sum_weight
                     ,mrih.sum_capacity               sum_capacity
                     ,NVL(mrih.sum_pallet_weight, 0)  sum_pallet_weight
              FROM    xxinv_mov_req_instr_headers     mrih
              WHERE   mrih.delivery_no            =  lv_delivery_no) xomh
      ;
--
-- Ver1.45 M.Hokkanji Start
      BEGIN
-- Ver1.45 M.Hokkanji End
        -- ============================
        -- 配車配送計画情報取得
        -- ============================
        SELECT xcs.delivery_type          ship_method
              ,xcs.default_line_number    default_line_number
              ,xsm2.small_amount_class    small_amount_class
        INTO   lv_ship_method                                   -- 配送区分
              ,lv_default_line_number                           -- 基準明細No
              ,lv_small_sum_class                               -- 小口区分
        FROM   xxwsh_carriers_schedule xcs                      -- 配車配送計画（アドオン）
              ,xxwsh_ship_method2_v    xsm2                     -- 出荷方法
        WHERE  xcs.delivery_type       = xsm2.ship_method_code
        AND    xsm2.start_date_active <= xcs.schedule_ship_date
        AND    xcs.schedule_ship_date <= NVL(xsm2.end_date_active, xcs.schedule_ship_date)
        AND    xcs.delivery_no         = lv_delivery_no
        FOR UPDATE OF xcs.transaction_id NOWAIT
        ;
-- Ver1.45 M.Hokkanji Start
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_skip_flag := '1';
          lv_over_flag := cv_over_flag_off;
      END;
      IF (lv_skip_flag = '0') THEN
-- Ver1.45 M.Hokkanji End
--
        -- ============================
        -- 配車配送計画の基準明細情報取得
        -- ============================
        BEGIN
          -- 受注ヘッダを検索
          SELECT  xoha.deliver_from                    entering_despatching_code1
                 ,CASE
                    -- 出荷支給区分が出荷の場合、コード区分「出荷」
                    WHEN ( xott.shipping_shikyu_class = cv_ship_req ) THEN
                      cv_code_kbn_ship
--
                    -- 出荷支給区分が支給の場合、コード区分「支給」
                    WHEN ( xott.shipping_shikyu_class = cv_supply_req ) THEN
                      cv_code_kbn_supply
                  END                                  code_class2
                 ,CASE
                    -- 出荷支給区分が出荷の場合、出荷先
                    WHEN ( xott.shipping_shikyu_class = cv_ship_req ) THEN
                      xoha.deliver_to
--
                    -- 出荷支給区分が支給の場合、取引先
                    WHEN ( xott.shipping_shikyu_class = cv_supply_req ) THEN
                      xoha.vendor_site_code
                  END                                  entering_despatching_code2
                 ,xoha.schedule_ship_date              standard_date
                 ,xoha.prod_class                      prod_class
                 ,xoha.weight_capacity_class           weight_capacity_class
          INTO    lv_entering_despatching_code1        -- 入出庫場所コード１
                 ,lv_code_class2                       -- コード区分２
                 ,lv_entering_despatching_code2        -- 入出庫場所コード２
                 ,ld_standard_date                     -- 基準日
                 ,lv_prod_class                        -- 商品区分
                 ,lv_weight_capacity_class             -- 重量容積区分
          FROM    xxwsh_order_headers_all       xoha   -- 受注ヘッダアドオン
                 ,xxwsh_oe_transaction_types_v  xott   -- 受注タイプ情報VIEW
          WHERE   xoha.request_no                             =  lv_default_line_number
          AND     xoha.order_type_id                          =  xott.transaction_type_id
          AND     NVL(xoha.latest_external_flag, cv_flag_no)  =  cv_flag_yes
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 受注データを検索できない場合は、移動データを検索する。
            SELECT  mrih.shipped_locat_code              entering_despatching_code1
                   ,cv_code_kbn_mov                      code_class2
                   ,mrih.ship_to_locat_code              entering_despatching_code2
                   ,mrih.schedule_ship_date              standard_date
                   ,mrih.item_class                      prod_class                  -- 商品区分
                   ,mrih.weight_capacity_class           weight_capacity_class
            INTO    lv_entering_despatching_code1        -- 入出庫場所コード１
                   ,lv_code_class2                       -- コード区分２
                   ,lv_entering_despatching_code2        -- 入出庫場所コード２
                   ,ld_standard_date                     -- 基準日
                   ,lv_prod_class                        -- 商品区分
                   ,lv_weight_capacity_class             -- 重量容積区分
            FROM    xxinv_mov_req_instr_headers   mrih   -- 移動依頼/指示ヘッダ(アドオン)
            WHERE   mrih.mov_num =  lv_default_line_number
            ;
        END;
--
        -- 積載重量合計(配車用)算出
        -- 小口の場合、積載重量にパレット重量を加算しない
        IF ( lv_small_sum_class = cv_include ) THEN
          ln_deli_sum_w := ln_deli_sum_w;
--
        -- 小口でない場合、積載重量合計にパレット重量を加算
        ELSE
          ln_deli_sum_w := ln_deli_sum_w + ln_deli_sum_pallet_w;
        END IF;
--
        -- ============================
        -- 積載オーバーかどうか判定
        -- ============================
        lv_over_flag := cv_over_flag_off; -- 積載オーバーフラグOFF
--
        -- 積載重量合計(配車用)がNULLでない場合
        IF ( ln_deli_sum_w IS NOT NULL ) THEN
          -- 重量積載効率(配車用)を取得
          xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                 =>  ln_deli_sum_w,                            -- 1.合計重量
            in_sum_capacity               =>  NULL,                                     -- 2.合計容積
            iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
            iv_entering_despatching_code1 =>  lv_entering_despatching_code1,            -- 4.入出庫場所コード１
            iv_code_class2                =>  lv_code_class2,                           -- 5.コード区分２
            iv_entering_despatching_code2 =>  lv_entering_despatching_code2,            -- 6.入出庫場所コード２
            iv_ship_method                =>  lv_ship_method,                           -- 7.出荷方法
            iv_prod_class                 =>  lv_prod_class,                            -- 8.商品区分
            iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
            id_standard_date              =>  ld_standard_date,                         -- 10.基準日(適用日基準日)
            ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
            ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
            ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
            ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
            ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
            on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
            on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
            ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合はエラーをセット
          IF ( lv_retcode = gn_status_error ) THEN
            -- エラー
            ov_errmsg := '配車解除判定処理:積載効率 エラー:' || lv_errmsg ;
            RETURN cv_career_cancel_err;
          END IF;
--
          -- 重量容積区分が重量で、積載オーバーの場合
          IF ( ( lv_weight_capacity_class =  cv_weight )
          AND  ( lv_loading_over_class = cv_over_flag_on ) ) THEN
            -- 積載オーバーなので、配車解除する。
            lv_over_flag := cv_over_flag_on;
--
          -- 積載オーバーでない場合
          ELSE
            ln_deli_load_efficiency_w := ln_load_efficiency_weight; -- 重量積載効率(配車用)
          END IF;
        END IF;
--
        -- 積載容積合計(配車用)がNULLでない場合
        IF ( ln_deli_sum_c IS NOT NULL ) THEN
          -- 容積積載効率(配車用)を取得
          xxwsh_common910_pkg.calc_load_efficiency(
            in_sum_weight                 =>  NULL,                                     -- 1.合計重量
            in_sum_capacity               =>  ln_deli_sum_c,                            -- 2.合計容積
            iv_code_class1                =>  cv_code_kbn_mov,                          -- 3.コード区分１
            iv_entering_despatching_code1 =>  lv_entering_despatching_code1,            -- 4.入出庫場所コード１
            iv_code_class2                =>  lv_code_class2,                           -- 5.コード区分２
            iv_entering_despatching_code2 =>  lv_entering_despatching_code2,            -- 6.入出庫場所コード２
            iv_ship_method                =>  lv_ship_method,                           -- 7.出荷方法
            iv_prod_class                 =>  lv_prod_class,                            -- 8.商品区分
            iv_auto_process_type          =>  NULL,                                     -- 9.自動配車対象区分
            id_standard_date              =>  ld_standard_date,                         -- 10.基準日(適用日基準日)
            ov_retcode                    =>  lv_retcode,                               -- 11.リターンコード
            ov_errmsg_code                =>  lv_errmsg_code,                           -- 12.エラーメッセージコード
            ov_errmsg                     =>  lv_errmsg,                                -- 13.エラーメッセージ
            ov_loading_over_class         =>  lv_loading_over_class,                    -- 14.積載オーバー区分
            ov_ship_methods               =>  lv_ship_methods,                          -- 15.出荷方法
            on_load_efficiency_weight     =>  ln_load_efficiency_weight,                -- 16.重量積載効率
            on_load_efficiency_capacity   =>  ln_load_efficiency_capacity,              -- 17.容積積載効率
            ov_mixed_ship_method          =>  lv_mixed_ship_method);                    -- 18.混載配送区分
--
          -- リターンコードが'1'(異常)の場合はエラーをセット
          IF ( lv_retcode = gn_status_error ) THEN
            -- エラー
            ov_errmsg := '配車解除判定処理:積載効率 エラー:' || lv_errmsg ;
            RETURN cv_career_cancel_err;
          END IF;
--
          -- 重量容積区分が容積で、積載オーバーの場合
          IF ( ( lv_weight_capacity_class =  cv_capacity )
          AND  ( lv_loading_over_class = cv_over_flag_on ) ) THEN
            -- 積載オーバーなので、配車解除する。
            lv_over_flag := cv_over_flag_on;
--
          -- 積載オーバーでない場合
          ELSE
            ln_deli_load_efficiency_c := ln_load_efficiency_capacity; -- 容積積載効率(配車用))
          END IF;
        END IF;
--
        -- 積載オーバーでない場合
        IF ( lv_over_flag = cv_over_flag_off ) THEN
          -- ============================
          -- 配車配送計画更新
          -- ============================
          UPDATE  xxwsh_carriers_schedule       xcs         -- 配車配送計画（アドオン）
          SET     xcs.sum_loading_weight          =  ln_deli_sum_w,               -- 積載重量合計
                  xcs.sum_loading_capacity        =  ln_deli_sum_c,               -- 積載容積合計
                  xcs.loading_efficiency_weight   =  ln_deli_load_efficiency_w,   -- 重量積載効率
                  xcs.loading_efficiency_capacity =  ln_deli_load_efficiency_c,   -- 容積積載効率
                  xcs.last_updated_by             =  ln_user_id,
                  xcs.last_update_date            =  ld_sysdate,
                  xcs.last_update_login           =  ln_login_id,
                  xcs.request_id                  =  ln_conc_request_id,
                  xcs.program_application_id      =  ln_prog_appl_id,
                  xcs.program_id                  =  ln_conc_program_id,
                  xcs.program_update_date         =  ld_sysdate
          WHERE   xcs.delivery_no                 =  lv_delivery_no
          ;
--
          -- ============================
          -- 混載率更新
          -- ============================
          -- 出荷の場合
          <<lt_chk_ship_tbl_loop>>
          FOR i IN 1 .. lt_chk_ship_tbl.COUNT LOOP
            -- 受注ヘッダアドオンIDが前のレコードと同じでない場合
            IF ( ( i = lt_chk_ship_tbl.FIRST ) 
            OR   ( lt_chk_ship_tbl(i).order_header_id <> lt_chk_ship_tbl(i - 1).order_header_id ) ) THEN
              -- 混載率算出のための重量算出
              -- 小口の場合
              IF ( lv_small_sum_class = cv_include ) THEN
                ln_sum_weight := lt_chk_ship_tbl(i).sum_weight;
--
              -- 小口でない場合、積載重量合計にパレット重量を加算
              ELSE
                ln_sum_weight := lt_chk_ship_tbl(i).sum_weight + NVL(lt_chk_ship_tbl(i).sum_pallet_weight, 0);
              END IF;
--
              -- 混載率算出
              -- 重量の場合
              IF ( lv_weight_capacity_class =  cv_weight ) THEN
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                -- 重量が0でない場合のみ混載率算出
                IF (NVL(ln_deli_sum_w, 0) = 0) THEN
                  ln_mixed_ratio := 0;
--
                ELSE
-- 2009/02/27 H.Itou Add End
                  ln_mixed_ratio := ROUND( ln_sum_weight / ln_deli_sum_w * 100, 2 );
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                END IF;
-- 2009/02/27 H.Itou Add End
--
              -- 容積の場合
              ELSIF ( lv_weight_capacity_class =  cv_capacity ) THEN
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                -- 重量が0でない場合のみ混載率算出
                IF (NVL(ln_deli_sum_c, 0) = 0) THEN
                  ln_mixed_ratio := 0;
--
                ELSE
-- 2009/02/27 H.Itou Add End
                  ln_mixed_ratio := ROUND( lt_chk_ship_tbl(i).sum_capacity / ln_deli_sum_c * 100, 2 );
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                END IF;
-- 2009/02/27 H.Itou Add End
              END IF;
--
              -- 受注ヘッダアドオン更新処理
              UPDATE xxwsh_order_headers_all            xoha                  -- 受注ヘッダアドオン
              SET    xoha.mixed_ratio                   =  ln_mixed_ratio,    -- 混載率
                     xoha.last_updated_by               =  ln_user_id,
                     xoha.last_update_date              =  ld_sysdate,
                     xoha.last_update_login             =  ln_login_id,
                     xoha.request_id                    =  ln_conc_request_id,
                     xoha.program_application_id        =  ln_prog_appl_id,
                     xoha.program_id                    =  ln_conc_program_id,
                     xoha.program_update_date           =  ld_sysdate
              WHERE  xoha.order_header_id               =  lt_chk_ship_tbl(i).order_header_id
              ;
            END IF;
          END LOOP lt_chk_ship_tbl_loop;
--
          -- 支給の場合
          <<lt_chk_supply_tbl_loop>>
          FOR i IN 1 .. lt_chk_supply_tbl.COUNT LOOP
            -- 受注ヘッダアドオンIDが前のレコードと同じでない場合
            IF ( ( i = lt_chk_supply_tbl.FIRST ) 
            OR   ( lt_chk_supply_tbl(i).order_header_id <> lt_chk_supply_tbl(i - 1).order_header_id ) ) THEN
              -- 混載率算出
              -- 重量の場合
              IF ( lv_weight_capacity_class =  cv_weight ) THEN
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                -- 重量が0でない場合のみ混載率算出
                IF (NVL(ln_deli_sum_w, 0) = 0) THEN
                  ln_mixed_ratio := 0;
--
                ELSE
-- 2009/02/27 H.Itou Add End
                  ln_mixed_ratio := ROUND( lt_chk_supply_tbl(i).sum_weight / ln_deli_sum_w * 100, 2 );
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                END IF;
-- 2009/02/27 H.Itou Add End
--
              -- 容積の場合
              ELSIF ( lv_weight_capacity_class =  cv_capacity ) THEN
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                -- 重量が0でない場合のみ混載率算出
                IF (NVL(ln_deli_sum_c, 0) = 0) THEN
                  ln_mixed_ratio := 0;
--
                ELSE
-- 2009/02/27 H.Itou Add End
                  ln_mixed_ratio := ROUND( lt_chk_supply_tbl(i).sum_capacity / ln_deli_sum_c * 100, 2 );
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                END IF;
-- 2009/02/27 H.Itou Add End
              END IF;
--
              -- 受注ヘッダアドオン更新処理
              UPDATE xxwsh_order_headers_all            xoha                  -- 受注ヘッダアドオン
              SET    xoha.mixed_ratio                   =  ln_mixed_ratio,    -- 混載率
                     xoha.last_updated_by               =  ln_user_id,
                     xoha.last_update_date              =  ld_sysdate,
                     xoha.last_update_login             =  ln_login_id,
                     xoha.request_id                    =  ln_conc_request_id,
                     xoha.program_application_id        =  ln_prog_appl_id,
                     xoha.program_id                    =  ln_conc_program_id,
                     xoha.program_update_date           =  ld_sysdate
              WHERE  xoha.order_header_id               =  lt_chk_supply_tbl(i).order_header_id
              ;
            END IF;
          END LOOP lt_chk_supply_tbl_loop;
--
          -- 移動の場合
          <<lt_chk_move_tbl_loop>>
          FOR i IN 1 .. lt_chk_move_tbl.COUNT LOOP
            -- 移動ヘッダIDが前のレコードと同じでない場合
            IF ( ( i = lt_chk_move_tbl.FIRST ) 
            OR   ( lt_chk_move_tbl(i).mov_hdr_id <> lt_chk_move_tbl(i - 1).mov_hdr_id ) ) THEN
              -- 混載率算出のための重量算出
              -- 小口の場合
              IF ( lv_small_sum_class = cv_include ) THEN
                ln_sum_weight := lt_chk_move_tbl(i).sum_weight;
--
              -- 小口でない場合、積載重量合計にパレット重量を加算
              ELSE
                ln_sum_weight := lt_chk_move_tbl(i).sum_weight + NVL(lt_chk_move_tbl(i).sum_pallet_weight, 0);
              END IF;
--
              -- 重量の場合
              IF ( lv_weight_capacity_class =  cv_weight ) THEN
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
              -- 重量が0でない場合のみ混載率算出
                IF (NVL(ln_deli_sum_w, 0) = 0) THEN
                  ln_mixed_ratio := 0;
--
                ELSE
-- 2009/02/27 H.Itou Add End
                  ln_mixed_ratio := ROUND( ln_sum_weight / ln_deli_sum_w * 100, 2 );
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                END IF;
-- 2009/02/27 H.Itou Add End
--
              -- 容積の場合
              ELSIF ( lv_weight_capacity_class =  cv_capacity ) THEN
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
              -- 重量が0でない場合のみ混載率算出
                IF (NVL(ln_deli_sum_c, 0) = 0) THEN
                  ln_mixed_ratio := 0;
--
                ELSE
-- 2009/02/27 H.Itou Add End
                  ln_mixed_ratio := ROUND( lt_chk_move_tbl(i).sum_capacity / ln_deli_sum_c * 100, 2 );
-- 2009/02/27 H.Itou Add Start 本番障害#863対応
                END IF;
-- 2009/02/27 H.Itou Add End
              END IF;
--
              -- 移動依頼/指示ヘッダ(アドオン)更新処理
              UPDATE xxinv_mov_req_instr_headers        mrih                  -- 移動依頼/指示ヘッダ(アドオン)
              SET    mrih.mixed_ratio                   =  ln_mixed_ratio,    -- 混載率
                     mrih.last_updated_by               =  ln_user_id,
                     mrih.last_update_date              =  ld_sysdate,
                     mrih.last_update_login             =  ln_login_id,
                     mrih.request_id                    =  ln_conc_request_id,
                     mrih.program_application_id        =  ln_prog_appl_id,
                     mrih.program_id                    =  ln_conc_program_id,
                     mrih.program_update_date           =  ld_sysdate
              WHERE  mrih.mov_hdr_id                    =  lt_chk_move_tbl(i).mov_hdr_id
              ;
            END IF;
          END LOOP lt_chk_move_tbl_loop;
        END IF;
-- Ver1.45 M.Hokkanji Start
      END IF;
-- Ver1.45 M.Hokkanji End
    END IF;
--
-- 2009/02/10 H.Itou Add End
    -- **************************************************
    -- *** 5.配車解除処理
    -- **************************************************
-- 2008/10/23 v1.28 D.Nihei Mod Start TE080_BPO_600 No22
--    IF (lv_delivery_no IS NOT NULL) THEN
    IF ( ( lv_delivery_no IS NOT NULL         )
-- 2009/02/10 H.Itou Mod Start 本番障害#863対応
     -- 配車解除フラグがONか、配車解除フラグ：2 で配車解除判定処理で配車解除と判定された場合、配車解除処理
--     AND ( iv_calcel_flag = cv_cancel_flag_on ) ) THEN
     AND ( ( ( iv_calcel_flag = cv_cancel_flag_on )
          OR ( ( iv_calcel_flag = cv_cancel_flag_judge )
            AND ( lv_over_flag   = cv_over_flag_on ) ) ) ) ) THEN
-- 2009/02/10 H.Itou Mod End
-- 2008/10/23 v1.28 D.Nihei Mod End
--
      -- 配車解除不可のデータが存在する場合はエラー
      IF ( ln_no_count > 0 ) THEN
        -- 2.配車解除可否チェック(出荷)でエラーメッセージが出力された場合
        IF ( lv_msg_ship_err IS NOT NULL ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                cv_msg_ship_err,
                                                cv_tkn_request_no,
                                                lv_msg_ship_err);
        END IF;
--
        -- 2.配車解除可否チェック(移動)でエラーメッセージが出力された場合
        IF ( ( lv_msg_move_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_err);
--
        ELSIF ( ( lv_msg_move_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_err);
        END IF;
--
        -- 2.配車解除可否チェック(支給)でエラーメッセージが出力された場合
        IF ( ( lv_msg_supply_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_err);
--
        ELSIF ( ( lv_msg_supply_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_err,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_err);
        END IF;
-- Ver1.20 M.Hokkanji START
        -- 出荷最大配送区分エラー
        IF ( ( lv_msg_ship_max_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_max_err);
--
        ELSIF ( ( lv_msg_ship_max_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_max_err);
        END IF;
        -- 出荷小口区分エラー
        IF ( ( lv_msg_ship_small_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_small_err);
--
        ELSIF ( ( lv_msg_ship_small_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_small_err);
        END IF;
        -- 出荷積載効率(重量)エラー
        IF ( ( lv_msg_ship_wei_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_wei_err);
--
        ELSIF ( ( lv_msg_ship_wei_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_wei_err);
        END IF;
        -- 出荷積載効率(容積)エラー
        IF ( ( lv_msg_ship_cap_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_cap_err);
--
        ELSIF ( ( lv_msg_ship_cap_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_ship_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_ship_cap_err);
        END IF;
        -- 支給最大配送区分エラー
        IF ( ( lv_msg_supply_max_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_max_err);
--
        ELSIF ( ( lv_msg_supply_max_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_max_err);
        END IF;
        -- 支給積載効率(重量)エラー
        IF ( ( lv_msg_supply_wei_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_wei_err);
--
        ELSIF ( ( lv_msg_supply_wei_err IS NOT NULL ) AND (ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_wei_err);
        END IF;
        -- 支給積載効率(容積)エラー
        IF ( ( lv_msg_supply_cap_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_cap_err);
--
        ELSIF ( ( lv_msg_supply_cap_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_supply_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_supply_cap_err);
        END IF;
        -- 移動最大配送区分エラー
        IF ( ( lv_msg_move_max_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) )THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_max_err);
--
        ELSIF ( ( lv_msg_move_max_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_max_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_max_err);
        END IF;
        -- 移動小口区分エラー
        IF ( ( lv_msg_move_small_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_small_err);
--
        ELSIF ( ( lv_msg_move_small_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL )  )THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_small_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_small_err);
        END IF;
        -- 移動積載効率(重量)エラー
        IF ( ( lv_msg_move_wei_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_wei_err);
--
        ELSIF ( ( lv_msg_move_wei_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_weight_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_wei_err);
        END IF;
        -- 移動積載効率(容積)エラー
        IF ( ( lv_msg_move_cap_err IS NOT NULL ) AND ( ov_errmsg IS NULL ) ) THEN
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_cap_err);
--
        ELSIF ( ( lv_msg_move_cap_err IS NOT NULL ) AND ( ov_errmsg IS NOT NULL ) ) THEN
          ov_errmsg := ov_errmsg
                       || CHR(10)
                       || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                   cv_msg_move_max_err,
                                                   cv_tkn_program,
                                                   cv_tkn_cap_char,
                                                   cv_tkn_request_no,
                                                   lv_msg_move_cap_err);
        END IF;
-- Ver1.20 M.Hokkanji END
--
        RETURN cv_career_cancel_err;
--
      -- 対象のデータが存在しない場合はエラー
      ELSIF ( ln_data_count <= 0 ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_del_req_instr);
        RETURN cv_career_cancel_err;
--
      END IF;
--
      IF ( lt_chk_ship_tbl.COUNT > 0 ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【出荷：配送No更新：受注ヘッダID】';
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
        -- 取得したレコードの分だけループ
        <<lt_chk_ship_tbl_loop>>
        FOR i IN lt_chk_ship_tbl.FIRST .. lt_chk_ship_tbl.LAST LOOP
--
          -- 受注ヘッダアドオンIDが前のレコードと同じでない場合
          IF ( ( i = lt_chk_ship_tbl.FIRST ) 
            OR ( lt_chk_ship_tbl(i).order_header_id <> lt_chk_ship_tbl(i - 1).order_header_id ) ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log
         || ' '      || lt_chk_ship_tbl(i).order_header_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
            -- 受注ヘッダアドオン更新処理
            UPDATE xxwsh_order_headers_all            xoha          -- 受注ヘッダアドオン
            SET    xoha.prev_delivery_no              =                     -- 前回配送No
                   (CASE
                     WHEN xoha.notif_status = cv_deci_noti THEN
                       xoha.delivery_no
                     ELSE
                       xoha.prev_delivery_no
                   END),
                   xoha.delivery_no                   =  NULL,              -- 配送No
                   xoha.mixed_ratio                   =  NULL,              -- 混載率
-- Ver1.20 M.Hokkanji START
                   xoha.shipping_method_code          =  lt_chk_ship_tbl(i).shipping_method_code, -- 配送区分
                   xoha.based_weight                  =  lt_chk_ship_tbl(i).based_weight, -- 基本重量
                   xoha.based_capacity                =  lt_chk_ship_tbl(i).based_capacity, -- 基本容積
                   xoha.loading_efficiency_weight     =  lt_chk_ship_tbl(i).loading_efficiency_weight, -- 積載効率(重量)
                   xoha.loading_efficiency_capacity   =  lt_chk_ship_tbl(i).loading_efficiency_capacity, -- 積載効率(容積)
--                   xoha.mixed_no                      =  NULL,              -- 混載元No
-- Ver1.20 M.Hokkanji END
                   xoha.last_updated_by               =  ln_user_id,
                   xoha.last_update_date              =  ld_sysdate,
                   xoha.last_update_login             =  ln_login_id,
                   xoha.request_id                    =  ln_conc_request_id,
                   xoha.program_application_id        =  ln_prog_appl_id,
                   xoha.program_id                    =  ln_conc_program_id,
                   xoha.program_update_date           =  ld_sysdate
            WHERE  xoha.order_header_id               =  lt_chk_ship_tbl(i).order_header_id;
--
          END IF;
--
        END LOOP lt_chk_ship_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
--      ELSIF (lt_chk_supply_tbl.COUNT > 0) THEN
      END IF;
      IF ( lt_chk_supply_tbl.COUNT > 0 ) THEN
-- Ver1.20 M.Hokkanji END
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【支給：配送No更新：受注ヘッダID】';
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
        -- 取得したレコードの分だけループ
        <<lt_chk_supply_tbl_loop>>
        FOR i IN lt_chk_supply_tbl.FIRST .. lt_chk_supply_tbl.LAST LOOP
--
          -- 受注ヘッダアドオンIDが前のレコードと同じでない場合
          IF ( ( i = lt_chk_supply_tbl.FIRST ) 
            OR ( lt_chk_supply_tbl(i).order_header_id <> lt_chk_supply_tbl(i - 1).order_header_id ) ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log
         || ' '      || lt_chk_supply_tbl(i).order_header_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
            -- 受注ヘッダアドオン更新処理
            UPDATE xxwsh_order_headers_all            xoha          -- 受注ヘッダアドオン
            SET    xoha.prev_delivery_no              =             -- 前回配送No
                   (CASE
                     WHEN ( xoha.notif_status = cv_deci_noti ) THEN
                       xoha.delivery_no
                     ELSE
                       xoha.prev_delivery_no
                    END ) ,
                   xoha.delivery_no                   =  NULL,              -- 配送No
                   xoha.mixed_ratio                   =  NULL,              -- 混載率
-- Ver1.20 M.Hokkanji START
                   xoha.shipping_method_code          =  lt_chk_supply_tbl(i).shipping_method_code,        -- 配送区分
                   xoha.based_weight                  =  lt_chk_supply_tbl(i).based_weight,                -- 基本重量
                   xoha.based_capacity                =  lt_chk_supply_tbl(i).based_capacity,              -- 基本容積
                   xoha.loading_efficiency_weight     =  lt_chk_supply_tbl(i).loading_efficiency_weight,   -- 積載効率(重量)
                   xoha.loading_efficiency_capacity   =  lt_chk_supply_tbl(i).loading_efficiency_capacity, -- 積載効率(容積)
--                   xoha.mixed_no                      =  NULL,                                             -- 混載元No
-- Ver1.20 M.Hokkanji END
                   xoha.last_updated_by               =  ln_user_id,
                   xoha.last_update_date              =  ld_sysdate,
                   xoha.last_update_login             =  ln_login_id,
                   xoha.request_id                    =  ln_conc_request_id,
                   xoha.program_application_id        =  ln_prog_appl_id,
                   xoha.program_id                    =  ln_conc_program_id,
                   xoha.program_update_date           =  ld_sysdate
            WHERE  xoha.order_header_id               =  lt_chk_supply_tbl(i).order_header_id;
--
          END IF;
--
        END LOOP lt_chk_supply_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
        END IF;
        IF ( lt_chk_move_tbl.COUNT > 0 ) THEN
--      ELSIF (lt_chk_move_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【移動：配送No更新：移動依頼ヘッダID】';
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
        -- 取得したレコードの分だけループ
        <<lt_chk_move_tbl_loop>>
        FOR i IN lt_chk_move_tbl.FIRST .. lt_chk_move_tbl.LAST LOOP
--
          -- 移動ヘッダIDが前のレコードと同じでない場合
          IF ( ( i = lt_chk_move_tbl.FIRST ) 
           OR  ( lt_chk_move_tbl(i).mov_hdr_id <> lt_chk_move_tbl(i - 1).mov_hdr_id ) ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log
         || ' '      || lt_chk_move_tbl(i).mov_hdr_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
            -- 移動依頼/指示ヘッダ(アドオン)更新処理
            UPDATE xxinv_mov_req_instr_headers        mrih     -- 移動依頼/指示ヘッダ(アドオン)
            SET    mrih.prev_delivery_no              =                     -- 前回配送No
                   (CASE
                     WHEN ( mrih.notif_status = cv_deci_noti ) THEN
                       mrih.delivery_no
                     ELSE
                       mrih.prev_delivery_no
                    END ) ,
                   mrih.delivery_no                   =  NULL,              -- 配送No
                   mrih.mixed_ratio                   =  NULL,              -- 混載率
-- Ver1.20 M.Hokkanji START
                   mrih.shipping_method_code          =  lt_chk_move_tbl(i).shipping_method_code,        -- 配送区分
                   mrih.based_weight                  =  lt_chk_move_tbl(i).based_weight,                -- 基本重量
                   mrih.based_capacity                =  lt_chk_move_tbl(i).based_capacity,              -- 基本容積
                   mrih.loading_efficiency_weight     =  lt_chk_move_tbl(i).loading_efficiency_weight,   -- 積載効率(重量)
                   mrih.loading_efficiency_capacity   =  lt_chk_move_tbl(i).loading_efficiency_capacity, -- 積載効率(容積)
--                   xoha.mixed_no                      =  NULL,                                         -- 混載元No
-- Ver1.20 M.Hokkanji END
                   mrih.last_updated_by               =  ln_user_id,
                   mrih.last_update_date              =  ld_sysdate,
                   mrih.last_update_login             =  ln_login_id,
                   mrih.request_id                    =  ln_conc_request_id,
                   mrih.program_application_id        =  ln_prog_appl_id,
                   mrih.program_id                    =  ln_conc_program_id,
                   mrih.program_update_date           =  ld_sysdate
            WHERE  mrih.mov_hdr_id                    =  lt_chk_move_tbl(i).mov_hdr_id;
--
          END IF;
--
        END LOOP lt_chk_move_tbl_loop;
--
      END IF;
--
-- Ver1.22 M.Hokkanji START
      BEGIN
-- Ver1.22 M.Hokkanji END
        -- 配車配送計画(アドオン)ロック処理
        SELECT xcs.transaction_id
        INTO   ln_dummy
        FROM   xxwsh_carriers_schedule        xcs              -- 配車配送計画(アドオン)
        WHERE  xcs.delivery_no                = lv_delivery_no
-- Ver1.30 M.Hokkanji Start
        FOR UPDATE OF xcs.delivery_no NOWAIT;
--        FOR UPDATE NOWAIT;
-- Ver1.30 M.Hokkanji End
--
        -- 配車配送計画(アドオン)削除処理
        DELETE
        FROM   xxwsh_carriers_schedule        xcs              -- 配車配送計画(アドオン)
        WHERE  xcs.delivery_no                = lv_delivery_no;
-- Ver1.22 M.Hokkanji START
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; -- 対象データがない場合はエラーとしない
      END;
-- Ver1.22 M.Hokkanji END
--
--
    -- 配送Noが設定されていない場合
    ELSE
      -- 配車解除不可のデータが存在する場合は関連項目更新処理を行わず正常終了する。
      IF (ln_no_count > 0) THEN
        -- 正常終了
        RETURN cv_compl;
      END IF;
    END IF;
--
    -- **************************************************
    -- *** 6.関連項目更新処理
    -- **************************************************
    -- 対象のデータが存在しない場合はエラー
    IF ( ln_data_count <= 0 ) THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_up_req_instr);
      RETURN cv_career_cancel_err;
    END IF;
--
    IF ( lt_chk_ship_tbl.COUNT > 0 ) THEN
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【出荷：通知ステータス更新：受注ヘッダID】';
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- 取得したレコードの分だけループ
      <<lt_chk_ship_tbl_loop>>
      FOR i IN lt_chk_ship_tbl.FIRST .. lt_chk_ship_tbl.LAST LOOP
--
        -- 受注ヘッダアドオンIDが前のレコードと同じでない場合
        IF ( ( i = lt_chk_ship_tbl.FIRST)
          OR ( lt_chk_ship_tbl(i).order_header_id <> lt_chk_ship_tbl(i - 1).order_header_id ) ) THEN
--
          -- 新規修正フラグ
          IF ( lt_chk_ship_tbl(i).notif_status = cv_deci_noti ) THEN
            --通知ステータス＝確定通知済 の場合：修正
            lv_new_modify_flg := cv_amend;
          ELSIF ( ( lt_chk_ship_tbl(i).prev_notif_status = cv_deci_noti ) 
            AND   ( lt_chk_ship_tbl(i).notif_status      = cv_re_noti   ) ) THEN
            --前回通知ステータス＝確定通知済 かつ
            --  通知ステータス＝再通知要の場合：修正
            lv_new_modify_flg := cv_amend;
          ELSIF ( lt_chk_ship_tbl(i).notif_status = cv_not_noti ) THEN
            --通知ステータス＝未通知の場合：新規
            lv_new_modify_flg := cv_new;
          ELSE
            --上記以外はエラー
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_new_modify_err,
                                                  cv_tkn_biz_type,   cv_tkn_ship_char,
                                                  cv_tkn_req_mov_no, lt_chk_ship_tbl(i).request_no
                                                  );
            RETURN cv_career_cancel_err;                          -- 新規修正フラグエラー
          END IF;
--
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log
         || ' '      || lt_chk_ship_tbl(i).order_header_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
          -- 受注ヘッダアドオン更新処理
          UPDATE xxwsh_order_headers_all            xoha          -- 受注ヘッダアドオン
          SET    xoha.prev_notif_status             =             -- 前回通知ステータス
                 (CASE                                                    -- 追加
                   WHEN (xoha.notif_status = cv_deci_noti) THEN           -- 追加
                     xoha.notif_status                                    -- 追加
                   ELSE                                                   -- 追加
                     xoha.prev_notif_status                               -- 追加
                  END),                                                   -- 追加
                 xoha.notif_status                  =                     -- 通知ステータス
                 (CASE
                   WHEN (xoha.notif_status = cv_deci_noti) THEN
                     cv_re_noti
                   --WHEN (xoha.notif_status = cv_not_noti) THEN
                   --  cv_not_noti
                   ELSE                                                   -- 追加
                     xoha.notif_status                                    -- 追加
                 END),
                 xoha.notif_date                    =  NULL,              -- 確定通知実施日時
                 --xoha.new_modify_flg                =                     -- 新規修正フラグ
                 --(CASE
                 --  WHEN (xoha.notif_status = cv_deci_noti) THEN
                 --    cv_amend
                 --  WHEN ((xoha.prev_notif_status = cv_deci_noti) AND
                 --         (xoha.notif_status = cv_re_noti)) THEN
                 --    cv_amend
                 --  WHEN (xoha.notif_status = cv_not_noti) THEN
                 --    cv_new
                 --END),
                 xoha.new_modify_flg                =  lv_new_modify_flg,    -- 新規修正フラグ
                 xoha.last_updated_by               =  ln_user_id,
                 xoha.last_update_date              =  ld_sysdate,
                 xoha.last_update_login             =  ln_login_id,
                 xoha.request_id                    =  ln_conc_request_id,
                 xoha.program_application_id        =  ln_prog_appl_id,
                 xoha.program_id                    =  ln_conc_program_id,
                 xoha.program_update_date           =  ld_sysdate
          WHERE  xoha.order_header_id               =  lt_chk_ship_tbl(i).order_header_id;
--
        END IF;
--
      END LOOP lt_chk_ship_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
      END IF;
      IF ( lt_chk_supply_tbl.COUNT > 0 ) THEN
--    ELSIF (lt_chk_supply_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【支給：通知ステータス更新：受注ヘッダID】';
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- 取得したレコードの分だけループ
      <<lt_chk_supply_tbl_loop>>
      FOR i IN lt_chk_supply_tbl.FIRST .. lt_chk_supply_tbl.LAST LOOP
--
        -- 受注ヘッダアドオンIDが前のレコードと同じでない場合
        IF ( ( i = lt_chk_supply_tbl.FIRST ) 
         OR  ( lt_chk_supply_tbl(i).order_header_id <> lt_chk_supply_tbl(i - 1).order_header_id ) ) THEN
--
          -- 新規修正フラグ
          IF ( lt_chk_supply_tbl(i).notif_status = cv_deci_noti ) THEN
            --通知ステータス＝確定通知済 の場合：修正
            lv_new_modify_flg := cv_amend;
          ELSIF ( ( lt_chk_supply_tbl(i).prev_notif_status = cv_deci_noti ) 
            AND   ( lt_chk_supply_tbl(i).notif_status      = cv_re_noti   ) ) THEN
            --前回通知ステータス＝確定通知済 かつ
            --  通知ステータス＝再通知要の場合：修正
            lv_new_modify_flg := cv_amend;
          ELSIF ( lt_chk_supply_tbl(i).notif_status = cv_not_noti ) THEN
            --通知ステータス＝未通知の場合：新規
            lv_new_modify_flg := cv_new;
          ELSE
            --上記以外はエラー
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_new_modify_err,
                                                  cv_tkn_biz_type,   cv_tkn_supl_char,
                                                  cv_tkn_req_mov_no, lt_chk_supply_tbl(i).request_no
                                                  );
            RETURN cv_career_cancel_err;                          -- 新規修正フラグエラー
          END IF;
--
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log
         || ' '      || lt_chk_supply_tbl(i).order_header_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
          -- 受注ヘッダアドオン更新処理
          UPDATE xxwsh_order_headers_all            xoha          -- 受注ヘッダアドオン
          SET    xoha.prev_notif_status             =             -- 前回通知ステータス
                 (CASE                                                    -- 追加
                   WHEN (xoha.notif_status = cv_deci_noti) THEN           -- 追加
                     xoha.notif_status                                    -- 追加
                   ELSE                                                   -- 追加
                     xoha.prev_notif_status                               -- 追加
                 END),                                                    -- 追加
                 xoha.notif_status                  =                     -- 通知ステータス
                 (CASE
                   WHEN (xoha.notif_status = cv_deci_noti) THEN
                     cv_re_noti
                   --WHEN (xoha.notif_status = cv_not_noti) THEN
                   --  cv_not_noti
                   ELSE                                                   -- 追加
                     xoha.notif_status                                    -- 追加
                 END),
                 xoha.notif_date                    =  NULL,              -- 確定通知実施日時
                 --xoha.new_modify_flg                =                     -- 新規修正フラグ
                 --(CASE
                 --  WHEN (xoha.notif_status = cv_deci_noti) THEN
                 --    cv_amend
                 --  WHEN ((xoha.prev_notif_status = cv_deci_noti) AND
                 --         (xoha.notif_status = cv_re_noti)) THEN
                 --    cv_amend
                 --  WHEN (xoha.notif_status = cv_not_noti) THEN
                 --    cv_new
                 --END),
                 xoha.new_modify_flg                =  lv_new_modify_flg,    -- 新規修正フラグ
                 xoha.last_updated_by               =  ln_user_id,
                 xoha.last_update_date              =  ld_sysdate,
                 xoha.last_update_login             =  ln_login_id,
                 xoha.request_id                    =  ln_conc_request_id,
                 xoha.program_application_id        =  ln_prog_appl_id,
                 xoha.program_id                    =  ln_conc_program_id,
                 xoha.program_update_date           =  ld_sysdate
          WHERE  xoha.order_header_id               =  lt_chk_supply_tbl(i).order_header_id;
--
        END IF;
--
      END LOOP lt_chk_supply_tbl_loop;
--
-- Ver1.20 M.Hokkanji START
      END IF;
      IF ( lt_chk_move_tbl.COUNT > 0 ) THEN
--    ELSIF (lt_chk_move_tbl.COUNT > 0) THEN
-- Ver1.20 M.Hokkanji END
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log || CHR(10)
         || '【移動：通知ステータス更新：移動依頼ヘッダID】';
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
      -- 取得したレコードの分だけループ
      <<lt_chk_move_tbl_loop>>
      FOR i IN lt_chk_move_tbl.FIRST .. lt_chk_move_tbl.LAST LOOP
--
        -- 移動ヘッダIDが前のレコードと同じでない場合
        IF ( ( i = lt_chk_move_tbl.FIRST ) 
          OR ( lt_chk_move_tbl(i).mov_hdr_id <> lt_chk_move_tbl(i - 1).mov_hdr_id ) ) THEN
--
-- 2009/08/18 H.Itou Add Start 本番#1581対応(営業システム:特別横持マスタ対応)
          -- 確定通知済の場合
          IF (lt_chk_move_tbl(i).notif_status = cv_deci_noti) THEN
            ---------------------------------------------------------
            -- 割当セットAPI起動
            ---------------------------------------------------------
            xxcop_common_pkg2.upd_assignment(
              iv_mov_num      => lt_chk_move_tbl(i).mov_num          -- 移動番号
             ,iv_process_type => gv_process_type_minus               -- 処理区分(0：加算、1：減算)
             ,ov_errbuf       => lv_errbuf                           --   エラー・メッセージ           --# 固定 #
             ,ov_retcode      => lv_retcode                          --   リターン・コード             --# 固定 #
             ,ov_errmsg       => lv_errmsg                           --   ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーの場合、処理終了
            IF (lv_retcode = gv_status_error) THEN
              -- エラーメッセージ取得
              ov_errmsg := xxcmn_common_pkg.get_msg(
                             cv_app_name_xxcmn                     -- アプリケーション名:XXCMN
                            ,cv_msg_process_err                    -- メッセージコード:処理失敗
                            ,cv_tkn_process ,cv_tkn_upd_assignment -- トークン:PROCESS = 割当セットAPI起動
                          );
              ov_errmsg := lv_errmsg || ' (移動番号:' || lt_chk_move_tbl(i).mov_num || ')' || lv_errmsg || lv_errbuf;
--
              RETURN cv_career_cancel_err;
            END IF;
          END IF;
-- 2009/08/18 H.Itou Add End
          -- 新規修正フラグ
          IF ( lt_chk_move_tbl(i).notif_status = cv_deci_noti ) THEN
            --通知ステータス＝確定通知済 の場合：修正
            lv_new_modify_flg := cv_amend;
          ELSIF ( ( lt_chk_move_tbl(i).prev_notif_status = cv_deci_noti ) 
            AND   ( lt_chk_move_tbl(i).notif_status      = cv_re_noti   ) ) THEN
            --前回通知ステータス＝確定通知済 かつ
            --  通知ステータス＝再通知要の場合：修正
            lv_new_modify_flg := cv_amend;
          ELSIF ( lt_chk_move_tbl(i).notif_status = cv_not_noti ) THEN
            --通知ステータス＝未通知の場合：新規
            lv_new_modify_flg := cv_new;
          ELSE
            --上記以外はエラー
            ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_new_modify_err,
                                                  cv_tkn_biz_type,   cv_tkn_move_char,
                                                  cv_tkn_req_mov_no, lt_chk_move_tbl(i).mov_num
                                                  );
            RETURN cv_career_cancel_err;                          -- 新規修正フラグエラー
          END IF;
--
-- 2008/12/13 D.Nihei Add Start ================================================
BEGIN
  lv_log := lv_log
         || ' '      || lt_chk_move_tbl(i).mov_hdr_id;
EXCEPTION
  WHEN  OTHERS THEN
    NULL;
END;
-- 2008/12/13 D.Nihei Add End   ================================================
          -- 移動依頼/指示ヘッダ(アドオン)更新処理
          UPDATE xxinv_mov_req_instr_headers        mrih       -- 移動依頼/指示ヘッダ(アドオン)
          --SET    mrih.prev_notif_status             =  mrih.notif_status, -- 前回通知ステータス
          --       mrih.notif_status                  =                     -- 通知ステータス
          --       (CASE
          --         WHEN (mrih.notif_status = cv_deci_noti) THEN
          --           cv_re_noti
          --         WHEN (mrih.notif_status = cv_not_noti) THEN
          --           cv_not_noti
          --       END),
          SET    mrih.prev_notif_status             =             -- 前回通知ステータス
                 (CASE                                                    -- 追加
                   WHEN (mrih.notif_status = cv_deci_noti) THEN           -- 追加
                     mrih.notif_status                                    -- 追加
                   ELSE                                                   -- 追加
                     mrih.prev_notif_status                               -- 追加
                 END),                                                    -- 追加
                 mrih.notif_status                  =                     -- 通知ステータス
                 (CASE
                   WHEN (mrih.notif_status = cv_deci_noti) THEN
                     cv_re_noti
                   ELSE                                                   -- 追加
                     mrih.notif_status                                    -- 追加
                 END),
                 mrih.notif_date                    =  NULL,              -- 確定通知実施日時
                 --mrih.new_modify_flg                =                     -- 新規修正フラグ
                 --(CASE
                 --  WHEN (mrih.notif_status = cv_deci_noti) THEN
                 --    cv_amend
                 --  WHEN ((mrih.prev_notif_status = cv_deci_noti) AND
                 --         (mrih.notif_status = cv_re_noti)) THEN
                 --    cv_amend
                 --  WHEN (mrih.notif_status = cv_not_noti) THEN
                 --    cv_new
                 --END),
                 mrih.new_modify_flg                =  lv_new_modify_flg,    -- 新規修正フラグ
                 mrih.last_updated_by               =  ln_user_id,
                 mrih.last_update_date              =  ld_sysdate,
                 mrih.last_update_login             =  ln_login_id,
                 mrih.request_id                    =  ln_conc_request_id,
                 mrih.program_application_id        =  ln_prog_appl_id,
                 mrih.program_id                    =  ln_conc_program_id,
                 mrih.program_update_date           =  ld_sysdate
          WHERE  mrih.mov_hdr_id                    =  lt_chk_move_tbl(i).mov_hdr_id;
--
        END IF;
--
      END LOOP lt_chk_move_tbl_loop;
--
    END IF;
--
-- 2008/12/13 D.Nihei Add Start ================================================
          FND_LOG.STRING('6', gv_pkg_name || gv_msg_cont || cv_prg_name, SUBSTRB(lv_log, 1, 4000));
-- 2008/12/13 D.Nihei Add End   ================================================
    -- 正常終了
    RETURN cv_compl;
--
  EXCEPTION 
    WHEN lock_expt THEN
-- 2009/02/20 D.Nihei Add Start 本番障害#1034対応
      IF (ship_lock_cur%ISOPEN) THEN
        CLOSE ship_lock_cur;
      END IF;
      IF (mov_lock_cur%ISOPEN) THEN
        CLOSE mov_lock_cur;
      END IF;
-- 2009/02/20 D.Nihei Add End
      -- ロック処理エラー
-- 2009/02/20 D.Nihei Add Start 本番障害#1034対応
--      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
      ov_errmsg := '依頼No/移動番号:' || iv_request_no || ' ' || '配送No:' || lv_delivery_no || ' ' || xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
-- 2009/02/20 D.Nihei Add End
      RETURN cv_career_cancel_err;                             -- 配車解除失敗
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END cancel_careers_schedule;
-- Ver1.25 M.Hokkanji Start
  /**********************************************************************************
   * Function Name    : update_mixed_no
   * Description      : 混載元No更新関数
   ***********************************************************************************/
  FUNCTION update_mixed_no(
    iv_mixed_no             IN         VARCHAR2,
    ov_errmsg               OUT NOCOPY VARCHAR2)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'update_mixed_no';  -- プログラム名
    cv_null_mixed_no_err   CONSTANT VARCHAR2(2)   := '-1';                    -- 混載元NoNULL更新失敗
    cv_compl               CONSTANT VARCHAR2(1)   := '0';                     -- 成功
    cv_no_data_err         CONSTANT VARCHAR2(1)   := '1';                     -- 対象データ無し
    cv_app_name_xxcmn      CONSTANT VARCHAR2(5)   := 'XXCMN';           -- アプリケーション短縮名
    cv_app_name_xxwsh      CONSTANT VARCHAR2(5)   := 'XXWSH';           -- アプリケーション短縮名
    cv_msg_lock_err        CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10006'; -- ロック処理エラー
    cv_msg_get_err         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10023'; -- 出荷依頼取得エラー
    cv_msg_upd_err         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-10024'; -- 混載元No更新エラー
    cv_msg_tkn_mixed_no    CONSTANT VARCHAR2(15)  := 'MIXED_NO';        -- メッセージトークン「混載元No」
    cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';               -- YES
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ln_user_id                    NUMBER;           -- ログインしているユーザーのID取得
    ln_login_id                   NUMBER;           -- 最終更新ログイン
    ln_conc_request_id            NUMBER;           -- 要求ID
    ln_prog_appl_id               NUMBER;           -- プログラム・アプリケーションID
    ln_conc_program_id            NUMBER;           -- プログラムID
    ld_sysdate                    DATE;             -- システム現在日付
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    lock_expt                  EXCEPTION;  -- ロック取得例外
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- WHOカラム情報取得
    ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
    ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
    ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    ld_sysdate           := SYSDATE;                      -- システム現在日付
--
    -- セーブポイントを取得します
    SAVEPOINT advance_sp;
    -- 検索処理を行います
    SELECT xoha.order_header_id                -- 受注ヘッダアドオンID
    BULK COLLECT INTO
           gt_order_header_id_tbl
    FROM   xxwsh_order_headers_all xoha        -- 受注ヘッダアドオン
    WHERE  xoha.mixed_no             = iv_mixed_no
    AND    xoha.latest_external_flag =  cv_flag_yes
    FOR UPDATE OF xoha.order_header_id NOWAIT;
--
    -- 取得できない場合はエラー
    IF (gt_order_header_id_tbl.COUNT = 0) THEN
      -- 対象データ無し
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                            cv_msg_get_err,
                                            cv_msg_tkn_mixed_no,
                                            iv_mixed_no);
      RETURN cv_no_data_err;                    -- 引当解除データ無し
    END IF;
--
    <<gt_order_header_id_tbl_loop>>
    FOR i IN gt_order_header_id_tbl.FIRST .. gt_order_header_id_tbl.LAST LOOP
--
      BEGIN
        -- 更新処理を行います
        UPDATE xxwsh_order_headers_all              xoha      -- 受注ヘッダアドオン
        SET    xoha.mixed_no                      =  NULL,
               xoha.last_updated_by               =  ln_user_id,
               xoha.last_update_date              =  ld_sysdate,
               xoha.last_update_login             =  ln_login_id,
               xoha.request_id                    =  ln_conc_request_id,
               xoha.program_application_id        =  ln_prog_appl_id,
               xoha.program_id                    =  ln_conc_program_id,
               xoha.program_update_date           =  ld_sysdate
        WHERE  xoha.order_header_id               =  gt_order_header_id_tbl(i);
--
      EXCEPTION
        -- エラーの場合はセーブポイントにロールバック
        WHEN OTHERS THEN
          -- 混載元No更新失敗
          ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh,
                                                cv_msg_upd_err,
                                                cv_msg_tkn_mixed_no,
                                                iv_mixed_no
                                                );
          ROLLBACK TO advance_sp;
          RETURN cv_null_mixed_no_err;                             -- 混載元NoNULL更新失敗
--
      END;
--
    END LOOP gt_order_header_id_tbl_loop;
--
    -- 正常終了の場合
    RETURN cv_compl;
  EXCEPTION
    WHEN lock_expt THEN
      -- ロック処理エラー
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxwsh, cv_msg_lock_err);
      ROLLBACK TO advance_sp;
      RETURN cv_null_mixed_no_err;                             -- 混載元NoNULL更新失敗
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END update_mixed_no;
-- Ver1.25 M.Hokkanji End
--
-- 2008/10/15 H.Itou Add Start 統合テスト指摘298
  /**********************************************************************************
   * Function Name    : convert_mixed_ship_method
   * Description      : 混載配送区分変換関数
   ***********************************************************************************/
  FUNCTION convert_mixed_ship_method(
    it_ship_method_code IN  xxwsh_ship_method_v.ship_method_code%TYPE -- 配送区分コード
  )
    RETURN xxwsh_ship_method_v.ship_method_code%TYPE                  -- 配送区分コード（混載なし）
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_mixed_ship_method';  --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_ship_method_code    xxwsh_ship_method2_v.ship_method_code%TYPE; -- 配送区分コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- 配送区分コードがNULLならNULLを返す。
    IF (it_ship_method_code IS NULL) THEN
      RETURN NULL;
    END IF;
--
    -- **************************************************
    -- *** 配送区分取得
    -- **************************************************
    BEGIN
      SELECT xsmv.ship_method_code   ship_method_code           -- 配送区分コード
      INTO   lt_ship_method_code
      FROM   xxwsh_ship_method_v     xsmv                       -- 配送区分情報VIEW
      WHERE  xsmv.mixed_ship_method_code = it_ship_method_code  -- 混載配送区分コード
      ;
--
    EXCEPTION
      -- 取得できない場合は、「混載」配送区分ではないので、同じものを返す。
      WHEN NO_DATA_FOUND THEN
        lt_ship_method_code := it_ship_method_code;
--
    END;
--
    RETURN lt_ship_method_code;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END convert_mixed_ship_method;
-- 2008/10/15 H.Itou Add End
--
-- 2009/01/08 H.Itou Add Start 本番障害#894
  /**********************************************************************************
   * Function Name    : chk_sourcing_rules
   * Description      : 物流構成存在チェック関数
   ***********************************************************************************/
  FUNCTION chk_sourcing_rules(
    it_item_code          IN  xxcmn_sourcing_rules.item_code%TYPE          -- 1.品目コード
   ,it_base_code          IN  xxcmn_sourcing_rules.base_code%TYPE          -- 2.管轄拠点
   ,it_ship_to_code       IN  xxcmn_sourcing_rules.ship_to_code%TYPE       -- 3.配送先
   ,it_delivery_whse_code IN  xxcmn_sourcing_rules.delivery_whse_code%TYPE -- 4.出庫倉庫
   ,id_standard_date      IN  DATE                                         -- 5.基準日(適用日基準日)
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_sourcing_rules'; --プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_all_item   CONSTANT VARCHAR2(7)  := 'ZZZZZZZ'; -- 全品目
--
    -- *** ローカル変数 ***
    lt_delivery_whse_code  xxcmn_sourcing_rules.delivery_whse_code%TYPE;
--
    -- *** ローカル・カーソル ***
    -- 配送先でチェック
    CURSOR cur_chk_ship_to_code(lt_item_code  xxcmn_sourcing_rules.item_code%TYPE)
    IS
      SELECT xsr.delivery_whse_code  delivery_whse_code -- 出庫倉庫
      FROM   xxcmn_sourcing_rules  xsr                  -- 物流構成アドオンマスタ
      WHERE  xsr.item_code          = lt_item_code      -- 品目コード
      AND    xsr.ship_to_code       = it_ship_to_code   -- 配送先
      AND    xsr.start_date_active <= id_standard_date  -- 適用開始日
      AND    xsr.end_date_active   >= id_standard_date  -- 適用終了日
    ;
--
    -- 管轄拠点でチェック
    CURSOR cur_chk_base_code(lt_item_code  xxcmn_sourcing_rules.item_code%TYPE)
    IS
      SELECT xsr.delivery_whse_code  delivery_whse_code -- 出庫倉庫
      FROM   xxcmn_sourcing_rules  xsr                  -- 物流構成アドオンマスタ
      WHERE  xsr.item_code          = lt_item_code      -- 品目コード
      AND    xsr.base_code          = it_base_code      -- 管轄拠点
      AND    xsr.start_date_active <= id_standard_date  -- 適用開始日
      AND    xsr.end_date_active   >= id_standard_date  -- 適用終了日
    ;
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -----------------------------------------------
    -- 1.品目/配送先をキーに出庫倉庫を取得       --
    -----------------------------------------------
    OPEN  cur_chk_ship_to_code(it_item_code);
    FETCH cur_chk_ship_to_code INTO lt_delivery_whse_code;
    CLOSE cur_chk_ship_to_code;
--
    -----------------------------------------------
    -- 2.品目/管轄拠点をキーに出庫倉庫を取得     --
    -----------------------------------------------
    -- 上記1にて取得できなかった場合
    IF (lt_delivery_whse_code IS NULL) THEN
      OPEN  cur_chk_base_code(it_item_code);
      FETCH cur_chk_base_code INTO lt_delivery_whse_code;
      CLOSE cur_chk_base_code;
    END IF;
--
    -----------------------------------------------
    -- 3.全品目/配送先をキーに出庫倉庫を取得     --
    -----------------------------------------------
    -- 上記2にて取得できなかった場合
    IF (lt_delivery_whse_code IS NULL) THEN
      OPEN  cur_chk_ship_to_code(cv_all_item);
      FETCH cur_chk_ship_to_code INTO lt_delivery_whse_code;
      CLOSE cur_chk_ship_to_code;
    END IF;
--
    -----------------------------------------------
    -- 4.全品目/管轄拠点をキーに出庫倉庫を取得   --
    -----------------------------------------------
    -- 上記3にて取得できなかった場合
    IF (lt_delivery_whse_code IS NULL) THEN
      OPEN  cur_chk_base_code(cv_all_item);
      FETCH cur_chk_base_code INTO lt_delivery_whse_code;
      CLOSE cur_chk_base_code;
    END IF;
--
    -- 取得した出庫倉庫が同じ場合、正常
    IF (lt_delivery_whse_code = it_delivery_whse_code) THEN
      RETURN gv_status_normal;
--
    -- 取得した出庫倉庫が違う場合、エラー
    ELSE
      RETURN gv_status_error;
    END IF;
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END chk_sourcing_rules;
-- 2009/01/08 H.Itou Add End
END xxwsh_common_pkg;
/
