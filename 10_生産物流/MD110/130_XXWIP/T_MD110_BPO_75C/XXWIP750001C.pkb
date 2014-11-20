CREATE OR REPLACE PACKAGE BODY xxwip750001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip750001c(body)
 * Description      : 振替運賃情報更新
 * MD.050           : 運賃計算（振替） T_MD050_BPO_750
 * MD.070           : 振替運賃情報更新 T_MD070_BPO_75C
 * Version          : 1.19
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_deliveryoff_proc   配車解除対象データ削除処理  -- 内部変更#225 追加
 *
 *  chk_param_proc         パラメータチェック処理(C-1)
 *  get_init               関連データ取得(C-2)
 *
 *  get_order_proc         受注データ抽出処理(C-3)
 *  set_trn                振替運賃情報アドオンデータ設定(C-4)
 *  ins_trn_proc           振替運賃情報アドオン一括登録処理(C-5)
 *  upd_trn_proc           振替運賃情報アドオン一括更新処理(C-6)
 *
 *  get_trn_proc           振替運賃情報アドオン抽出処理(C-7)
 *  set_trn_sum            振替運賃情報サマリーアドオンデータ設定(C-8)
 *  ins_trn_sum_proc       振替運賃情報サマリーアドオン一括登録処理(C-9)
 *  upd_trn_sum_proc       振替運賃情報サマリーアドオン一括更新処理(C-10)
 *
 *  get_trn_sum_proc       振替運賃情報サマリーアドオン抽出処理(C-11)
 *  set_trn_inf            振替情報アドオンデータ設定(C-12)
 *  ins_trn_inf_proc       振替情報アドオン一括登録処理(C-13)
 *  upd_trn_inf_proc       振替情報アドオン一括更新処理(C-14)
 *
 *  upd_deliv_ctrl_proc    運賃計算用コントロール更新処理(C-15)
 *
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/29    1.0  Oracle 和田 大輝  初回作成
 *  2008/05/01    1.1  Oracle 野村 正幸  内部変更要求#59、#75対応
 *  2008/06/09    1.2  Oracle 野村 正幸  TE080指摘事項対応
 *  2008/06/27    1.3  Oracle 丸下 博宣  内部変更要求144
 *  2008/07/29    1.4  Oracle 山根 一浩  ST障害No484対応
 *  2008/09/03    1.5  Oracle 野村 正幸  内部変更要求201_203
 *  2008/09/22    1.6  Oracle 山根 一浩  T_S_552,T_TE080_BPO_750 指摘4対応
 *  2008/10/16    1.7  Oracle 野村 正幸  内部変更#225
 *  2008/10/17    1.8  Oracle 野村 正幸  T_S_465対応
 *  2008/11/06    1.9  Oracle 福田 直樹  統合#537対応
 *  2008/11/06    1.9  Oracle 福田 直樹  統合#563対応
 *  2008/11/28    1.10 Oracle 野村 正幸  本番#222対応
 *  2008/12/06    1.11 Oracle 野村 正幸  本番#532対応
 *  2008/12/13    1.12 Oracle 野村 正幸  本番#721対応
 *  2008/12/15    1.13 SCS    野村 正幸  本番#712対応
 *  2009/01/08    1.14 SCS    野村 正幸  本番#961対応
 *  2009/01/19    1.15 SCS    椎名 昭圭  本番#1003対応
 *  2009/01/27    1.16 SCS    野村 正幸  本番#1078対応
 *  2009/04/06    1.17 SCS    野村 正幸  年度切替対応
 *  2009/06/03    1.18 SCS    野村 正幸  本番#1505対応
 *  2009/12/09    1.19 SCS    吉元 強樹  E_本稼動_00346対応,内部気づき
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
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  lock_expt                  EXCEPTION;  -- ロック取得例外
--
  func_inv_expt              EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(func_inv_expt, -20001);    -- ファンクションエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                CONSTANT VARCHAR2(100) := 'xxwip750001c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_cmn_msg_kbn             CONSTANT VARCHAR2(5) := 'XXCMN';
  gv_wip_msg_kbn             CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- メッセージ番号(XXCMN)
  gv_cmn_msg_75c_008         CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008'; -- 処理件数
  gv_cmn_msg_75c_009         CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; -- 成功件数
  gv_cmn_msg_75c_001         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- 対象データなし
  gv_cmn_msg_75c_010         CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- パラメータエラー
--
  -- メッセージ番号(XXWIP)
  -- 振替運賃情報アドオン処理件数メッセージ
  gv_wip_msg_75c_005         CONSTANT VARCHAR2(15) := 'APP-XXWIP-00005';
  -- 振替情報アドオン処理件数メッセージ
  gv_wip_msg_75c_006         CONSTANT VARCHAR2(15) := 'APP-XXWIP-00006';
  -- 振替運賃情報サマリーアドオン処理件数メッセージ
  gv_wip_msg_75c_008         CONSTANT VARCHAR2(15) := 'APP-XXWIP-00008';
  gv_wip_msg_75c_004         CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ロック詳細メッセージ
--
  gv_wip_msg_75c_009         CONSTANT VARCHAR2(15) := 'APP-XXWIP-30012'; -- 2008/09/22 Add
--
  -- トークン
  gv_tkn_parameter           CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_tkn_value               CONSTANT VARCHAR2(10) := 'VALUE';
  gv_tkn_table               CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key                 CONSTANT VARCHAR2(10) := 'KEY';
  gv_tkn_cnt                 CONSTANT VARCHAR2(10) := 'CNT';
--2008/09/22 Add
  gv_tkn_tbl_name            CONSTANT VARCHAR2(10) := 'TBL_NAME';
  gv_tkn_req_no              CONSTANT VARCHAR2(10) := 'REQ_NO';
--
  -- トークン値
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
  gv_iv_prod_div_name        CONSTANT VARCHAR2(30) := '商品区分';
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
  gv_exchange_type_name      CONSTANT VARCHAR2(30) := '洗替区分';
  gv_party_view_name         CONSTANT VARCHAR2(30) := 'パーティ情報VIEW2';
  gv_deli_ctrl_name          CONSTANT VARCHAR2(30) := '運賃計算用コントロール';
  gv_trans_fare_inf_name     CONSTANT VARCHAR2(30) := '振替運賃情報アドオン';
  gv_trans_fare_sum_name     CONSTANT VARCHAR2(30) := '振替運賃情報サマリーアドオン';
  gv_trans_inf_name          CONSTANT VARCHAR2(30) := '振替情報アドオン';
--
  gv_jurisdicyional_hub_name CONSTANT VARCHAR2(30) := '管轄拠点';
--
  -- YESNO区分
  gv_ktg_yes                 CONSTANT VARCHAR2(1) := 'Y';
  gv_ktg_no                  CONSTANT VARCHAR2(1) := 'N';
--
  -- コンカレントNo(運賃計算用コントロール)
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
/***** 使用しなくなったため、コメントアウト
  gv_con_no_deli             CONSTANT VARCHAR2(1) := '3';   -- 3:振替運賃情報更新
*****/
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
  -- 商品区分
  gv_prod_class_lef          CONSTANT VARCHAR2(1) := '1';   -- 1:リーフ
  gv_prod_class_drk          CONSTANT VARCHAR2(1) := '2';   -- 2:ドリンク
  -- 小口区分
  gv_small_sum_yes           CONSTANT VARCHAR2(1) := '1';   -- 1:小口
  gv_small_sum_no            CONSTANT VARCHAR2(1) := '0';   -- 0:車立
  -- ペナルティ区分
  gv_penalty_yes             CONSTANT VARCHAR2(1) := '1';   -- 1:有り
  gv_penalty_no              CONSTANT VARCHAR2(1) := '0';   -- 0:無し
  -- 入出庫換算関数 変換方法
  gv_rcv_to_inout            CONSTANT VARCHAR2(1)  := '1';  -- 入出庫換算単位から第1単位へ変換
  gv_rcv_to_first            CONSTANT VARCHAR2(1)  := '2';  -- 第1単位から入出庫換算単位へ変換
--
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
  -- コンカレントNO
  gv_con_lef                 CONSTANT VARCHAR2(1) := '3';   -- 1:リーフ
  gv_con_drk                 CONSTANT VARCHAR2(1) := '4';   -- 2:ドリンク
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 振替運賃情報アドオンに格納するレコード
  TYPE order_inf_rec IS RECORD(
    order_header_id      xxwsh_order_headers_all.order_header_id%TYPE,      -- 1.受注ﾍｯﾀﾞｱﾄﾞｵﾝID
    order_type_id        xxwsh_order_headers_all.order_type_id%TYPE,        -- 2.受注タイプID
    request_no           xxwsh_order_headers_all.request_no%TYPE,           -- 3.依頼No
    arrival_date         xxwsh_order_headers_all.arrival_date%TYPE,         -- 4.着荷日
    head_sales_branch    xxwsh_order_headers_all.head_sales_branch%TYPE,    -- 5.管轄拠点
    deliver_from         xxwsh_order_headers_all.deliver_from%TYPE,         -- 6.出荷元保管場所
-- ##### 20080609 MOD TE080指摘事項対応 start #####
/***
    shipping_method_code xxwsh_order_headers_all.shipping_method_code%TYPE, -- 8.配送区分
    deliver_to           xxwsh_order_headers_all.deliver_to%TYPE,           -- 7.出荷先
***/
    deliver_to           xxwsh_order_headers_all.result_deliver_to%TYPE,           -- 7.出荷先_実績
    shipping_method_code xxwsh_order_headers_all.result_shipping_method_code%TYPE, -- 8.配送区分_実績
-- ##### 20080609 MOD TE080指摘事項対応 end   #####
    small_quantity       xxwsh_order_headers_all.small_quantity%TYPE,       -- 9.小口個数
    prod_class           xxwsh_order_headers_all.prod_class%TYPE,           -- 10.商品区分
    arrival_yyyymm       VARCHAR2(6),                                       -- 11.対象年月
    shipping_item_code   xxwsh_order_lines_all.shipping_item_code%TYPE,     -- 12.出荷品目
    shipped_quantity     xxwsh_order_lines_all.shipped_quantity%TYPE,       -- 13.出荷実績数量
    product_class        xxcmn_item_mst_v.product_class%TYPE,               -- 14.商品分類
    conv_unit            xxcmn_item_mst_v.conv_unit%TYPE,                   -- 15.入出庫換算単位
    num_of_cases         xxcmn_item_mst_v.num_of_cases%TYPE,                -- 16.ケース入数
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
--    base_major_division  xxcmn_parties2_v.base_major_division%TYPE,         -- 17.拠点大分類
    base_major_division  xxcmn_cust_accounts2_v.base_major_division%TYPE,   -- 17.拠点大分類
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
    small_amount_class   xxwsh_ship_method_v.small_amount_class%TYPE,       -- 18.小口区分
    penalty_class        xxwsh_ship_method_v.penalty_class%TYPE,            -- 19.ペナルティ区分
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
--    setting_amount       xxwip_leaf_trans_deli_chrgs.setting_amount%TYPE    -- 20.単価(便設定金額)
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
--    setting_amount       xxwip_transfer_fare_inf.price%TYPE                 -- 20.単価(便設定金額)
    setting_amount       xxwip_transfer_fare_inf.price%TYPE,                 -- 20.単価(便設定金額)
    delivery_no          xxwsh_order_headers_all.delivery_no%TYPE            -- 配送No
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
  );
--
  -- 対象データ情報を格納するテーブル型の定義
  TYPE order_inf_tbl IS TABLE OF order_inf_rec INDEX BY PLS_INTEGER;
  gt_order_inf_tbl   order_inf_tbl;
--
  -- *****************************
  -- * 振替運賃情報アドオン 関連
  -- *****************************
  -- 登録PL/SQL表型
  -- 振替運賃情報ID
  TYPE i_trn_fare_inf_id_type        IS TABLE OF xxwip_transfer_fare_inf.transfer_fare_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 対象年月
  TYPE i_trn_target_date_type        IS TABLE OF xxwip_transfer_fare_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE i_trn_request_no_type         IS TABLE OF xxwip_transfer_fare_inf.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE i_trn_goods_classe_type       IS TABLE OF xxwip_transfer_fare_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送日
  TYPE i_trn_delivery_date_type      IS TABLE OF xxwip_transfer_fare_inf.delivery_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE i_trn_jurisdicyional_hub_type IS TABLE OF xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- 出庫元
  TYPE i_trn_delivery_whs_type       IS TABLE OF xxwip_transfer_fare_inf.delivery_whs%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送先
  TYPE i_trn_ship_to_type            IS TABLE OF xxwip_transfer_fare_inf.ship_to%TYPE
  INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE i_trn_item_code_type          IS TABLE OF xxwip_transfer_fare_inf.item_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 単価
  TYPE i_trn_price_type              IS TABLE OF xxwip_transfer_fare_inf.price%TYPE
  INDEX BY BINARY_INTEGER;
  -- 計算数量
  TYPE i_trn_calc_qry_type           IS TABLE OF xxwip_transfer_fare_inf.calc_qry%TYPE
  INDEX BY BINARY_INTEGER;
  -- 実際数量
  TYPE i_trn_actual_qty_type         IS TABLE OF xxwip_transfer_fare_inf.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- 金額
  TYPE i_trn_amount_type             IS TABLE OF xxwip_transfer_fare_inf.amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_trn_fare_inf_id_tab              i_trn_fare_inf_id_type;          -- 振替運賃情報ID
  i_trn_target_date_tab              i_trn_target_date_type;          -- 対象年月
  i_trn_request_no_tab               i_trn_request_no_type;           -- 依頼No
  i_trn_goods_classe_tab             i_trn_goods_classe_type;         -- 商品区分
  i_trn_delivery_date_tab            i_trn_delivery_date_type;        -- 配送日
  i_trn_jurisdicyional_hub_tab       i_trn_jurisdicyional_hub_type;   -- 管轄拠点
  i_trn_delivery_whs_tab             i_trn_delivery_whs_type;         -- 出庫元
  i_trn_ship_to_tab                  i_trn_ship_to_type;              -- 配送先
  i_trn_item_code_tab                i_trn_item_code_type;            -- 品目コード
  i_trn_price_tab                    i_trn_price_type;                -- 単価
  i_trn_calc_qry_tab                 i_trn_calc_qry_type;             -- 計算数量
  i_trn_actual_qty_tab               i_trn_actual_qty_type;           -- 実際数量
  i_trn_amount_tab                   i_trn_amount_type;               -- 金額
--
  -- 更新PL/SQL表型
  -- 振替運賃情報ID
  TYPE u_trn_fare_inf_id_type        IS TABLE OF xxwip_transfer_fare_inf.transfer_fare_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 対象年月
  TYPE u_trn_target_date_type        IS TABLE OF xxwip_transfer_fare_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE u_trn_request_no_type         IS TABLE OF xxwip_transfer_fare_inf.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE u_trn_goods_classe_type       IS TABLE OF xxwip_transfer_fare_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送日
  TYPE u_trn_delivery_date_type      IS TABLE OF xxwip_transfer_fare_inf.delivery_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE u_trn_jurisdicyional_hub_type IS TABLE OF xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- 出庫元
  TYPE u_trn_delivery_whs_type       IS TABLE OF xxwip_transfer_fare_inf.delivery_whs%TYPE
  INDEX BY BINARY_INTEGER;
  -- 配送先
  TYPE u_trn_ship_to_type            IS TABLE OF xxwip_transfer_fare_inf.ship_to%TYPE
  INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE u_trn_item_code_type          IS TABLE OF xxwip_transfer_fare_inf.item_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 単価
  TYPE u_trn_price_type              IS TABLE OF xxwip_transfer_fare_inf.price%TYPE
  INDEX BY BINARY_INTEGER;
  -- 計算数量
  TYPE u_trn_calc_qry_type           IS TABLE OF xxwip_transfer_fare_inf.calc_qry%TYPE
  INDEX BY BINARY_INTEGER;
  -- 実際数量
  TYPE u_trn_actual_qty_type         IS TABLE OF xxwip_transfer_fare_inf.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- 金額
  TYPE u_trn_amount_type             IS TABLE OF xxwip_transfer_fare_inf.amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_trn_fare_inf_id_tab              u_trn_fare_inf_id_type;          -- 振替運賃情報ID
  u_trn_target_date_tab              u_trn_target_date_type;          -- 対象年月
  u_trn_request_no_tab               u_trn_request_no_type;           -- 依頼No
  u_trn_goods_classe_tab             u_trn_goods_classe_type;         -- 商品区分
  u_trn_delivery_date_tab            u_trn_delivery_date_type;        -- 配送日
  u_trn_jurisdicyional_hub_tab       u_trn_jurisdicyional_hub_type;   -- 管轄拠点
  u_trn_delivery_whs_tab             u_trn_delivery_whs_type;         -- 出庫元
  u_trn_ship_to_tab                  u_trn_ship_to_type;              -- 配送先
  u_trn_item_code_tab                u_trn_item_code_type;            -- 品目コード
  u_trn_price_tab                    u_trn_price_type;                -- 単価
  u_trn_calc_qry_tab                 u_trn_calc_qry_type;             -- 計算数量
  u_trn_actual_qty_tab               u_trn_actual_qty_type;           -- 実際数量
  u_trn_amount_tab                   u_trn_amount_type;               -- 金額
--
  -- 振替運賃情報サマリーアドオンに格納するレコード
  TYPE order_summary_rec IS RECORD(
    target_date        xxwip_transfer_fare_inf.target_date%TYPE,          -- 1.対象年月
    request_no         xxwip_transfer_fare_inf.request_no%TYPE,           -- 2.依頼No
    goods_classe       xxwip_transfer_fare_inf.goods_classe%TYPE,         -- 3.商品区分
    jurisdicyional_hub xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE,   -- 4.管轄拠点
    summary_qry        xxwip_transfer_fare_inf.actual_qty%TYPE,           -- 5.振替数量
    leaf_chg_amount    xxwip_transfer_fare_sum.leaf_amount%TYPE,          -- 6.リーフ振替金額
    drink_chg_amount   xxwip_transfer_fare_sum.drink_amount%TYPE          -- 7.ドリンク振替金額
  );
--
  -- 対象データ情報を格納するテーブル型の定義
  TYPE order_summary_tbl IS TABLE OF order_summary_rec INDEX BY PLS_INTEGER;
  gt_order_summary_tbl   order_summary_tbl;
--
  -- ***********************************
  -- * 振替運賃情報サマリーアドオン 関連
  -- ***********************************
  -- 登録PL/SQL表型
  -- 振替運賃情報サマリーID
  TYPE i_trn_fare_sum_id_type         IS TABLE OF xxwip_transfer_fare_sum.transfer_fare_sum_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 対象年月
  TYPE i_trn_fare_sum_target_dt_type  IS TABLE OF xxwip_transfer_fare_sum.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE i_trn_fare_sum_request_no_type IS TABLE OF xxwip_transfer_fare_sum.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE i_trn_fare_sum_goods_cls_type  IS TABLE OF xxwip_transfer_fare_sum.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE i_trn_fare_sum_juris_hub_type  IS TABLE OF xxwip_transfer_fare_sum.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替数量
  TYPE i_trn_fare_sum_actual_qty_type IS TABLE OF xxwip_transfer_fare_sum.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- リーフ振替金額
  TYPE i_trn_fare_sum_leaf_amnt_type  IS TABLE OF xxwip_transfer_fare_sum.leaf_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ドリンク振替金額
  TYPE i_trn_fare_sum_drink_amnt_type IS TABLE OF xxwip_transfer_fare_sum.drink_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_trn_fare_sum_id_tab                 i_trn_fare_sum_id_type;         -- 振替運賃情報サマリーID
  i_trn_fare_sum_target_date_tab        i_trn_fare_sum_target_dt_type;  -- 対象年月
  i_trn_fare_sum_request_no_tab         i_trn_fare_sum_request_no_type; -- 依頼No
  i_trn_fare_sum_goods_clas_tab         i_trn_fare_sum_goods_cls_type;  -- 商品区分
  i_trn_fare_sum_juris_hub_tab          i_trn_fare_sum_juris_hub_type;  -- 管轄拠点
  i_trn_fare_sum_actual_qty_tab         i_trn_fare_sum_actual_qty_type; -- 振替数量
  i_trn_fare_sum_leaf_amount_tab        i_trn_fare_sum_leaf_amnt_type;  -- リーフ振替金額
  i_trn_fare_sum_drk_amount_tab         i_trn_fare_sum_drink_amnt_type; -- ドリンク振替金額
--
  -- 更新PL/SQL表型
  -- 振替運賃情報サマリーID
  TYPE u_trn_fare_sum_id_type         IS TABLE OF xxwip_transfer_fare_sum.transfer_fare_sum_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 対象年月
  TYPE u_trn_fare_sum_target_dt_type  IS TABLE OF xxwip_transfer_fare_sum.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE u_trn_fare_sum_request_no_type IS TABLE OF xxwip_transfer_fare_sum.request_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE u_trn_fare_sum_goods_cls_type  IS TABLE OF xxwip_transfer_fare_sum.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE u_trn_fare_sum_juris_hub_type  IS TABLE OF xxwip_transfer_fare_sum.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替数量
  TYPE u_trn_fare_sum_actual_qty_type IS TABLE OF xxwip_transfer_fare_sum.actual_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- リーフ振替金額
  TYPE u_trn_fare_sum_leaf_amnt_type  IS TABLE OF xxwip_transfer_fare_sum.leaf_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ドリンク振替金額
  TYPE u_trn_fare_sum_drink_amnt_type IS TABLE OF xxwip_transfer_fare_sum.drink_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_trn_fare_sum_id_tab                 u_trn_fare_sum_id_type;         -- 振替運賃情報サマリーID
  u_trn_fare_sum_target_date_tab        u_trn_fare_sum_target_dt_type;  -- 対象年月
  u_trn_fare_sum_request_no_tab         u_trn_fare_sum_request_no_type; -- 依頼No
  u_trn_fare_sum_goods_clas_tab         u_trn_fare_sum_goods_cls_type;  -- 商品区分
  u_trn_fare_sum_juris_hub_tab          u_trn_fare_sum_juris_hub_type;  -- 管轄拠点
  u_trn_fare_sum_actual_qty_tab         u_trn_fare_sum_actual_qty_type; -- 振替数量
  u_trn_fare_sum_leaf_amount_tab        u_trn_fare_sum_leaf_amnt_type;  -- リーフ振替金額
  u_trn_fare_sum_drk_amount_tab         u_trn_fare_sum_drink_amnt_type; -- ドリンク振替金額
--
  -- 振替情報アドオンに格納するレコード
  TYPE trans_inf_rec IS RECORD(
    target_date        xxwip_transfer_fare_sum.target_date%TYPE,          -- 1.対象年月
    goods_classe       xxwip_transfer_fare_sum.goods_classe%TYPE,         -- 2.商品区分
    jurisdicyional_hub xxwip_transfer_fare_sum.jurisdicyional_hub%TYPE,   -- 3.管轄拠点
    summary_qry        xxwip_transfer_fare_sum.actual_qty%TYPE,           -- 4.振替数量
    trans_amount       xxwip_transfer_inf.transfer_amount%TYPE,           -- 5.振替金額
    business_block     xxwip_transfer_inf.business_block%TYPE,            -- 6.営業ブロック
    area_name          xxwip_transfer_inf.area_name%TYPE                  -- 7.地区名
  );
--
  -- 対象データ情報を格納するテーブル型の定義
  TYPE trans_inf_tbl IS TABLE OF trans_inf_rec INDEX BY PLS_INTEGER;
  gt_trans_inf_tbl   trans_inf_tbl;
--
  -- ***********************
  -- * 振替情報アドオン 関連
  -- ***********************
  -- 登録PL/SQL表型
  -- 振替情報ID
  TYPE i_trn_inf_id_type                  IS TABLE OF xxwip_transfer_inf.transfer_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 対象年月
  TYPE i_trn_inf_target_date_type         IS TABLE OF xxwip_transfer_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 営業ブロック
  TYPE i_trn_inf_business_block_type      IS TABLE OF xxwip_transfer_inf.business_block%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE i_trn_inf_goods_classe_type        IS TABLE OF xxwip_transfer_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE i_trn_inf_juris_hub_type           IS TABLE OF xxwip_transfer_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- 地区名
  TYPE i_trn_inf_area_name_type           IS TABLE OF xxwip_transfer_inf.area_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替数量
  TYPE i_trn_inf_transfe_qty_type         IS TABLE OF xxwip_transfer_inf.transfe_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替金額
  TYPE i_trn_inf_transfer_amount_type     IS TABLE OF xxwip_transfer_inf.transfer_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_trn_inf_id_tab                    i_trn_inf_id_type;                  -- 振替情報ID
  i_trn_inf_target_date_tab           i_trn_inf_target_date_type;         -- 対象年月
  i_trn_inf_business_block_tab        i_trn_inf_business_block_type;      -- 営業ブロック
  i_trn_inf_goods_classe_tab          i_trn_inf_goods_classe_type;        -- 商品区分
  i_trn_inf_juris_hub_tab             i_trn_inf_juris_hub_type;           -- 管轄拠点
  i_trn_inf_area_name_tab             i_trn_inf_area_name_type;           -- 地区名
  i_trn_inf_transfe_qty_tab           i_trn_inf_transfe_qty_type;         -- 振替数量
  i_trn_inf_transfer_amount_tab       i_trn_inf_transfer_amount_type;     -- 振替金額
--
  -- 更新PL/SQL表型
  -- 振替情報ID
  TYPE u_trn_inf_id_type                  IS TABLE OF xxwip_transfer_inf.transfer_inf_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 対象年月
  TYPE u_trn_inf_target_date_type         IS TABLE OF xxwip_transfer_inf.target_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 営業ブロック
  TYPE u_trn_inf_business_block_type      IS TABLE OF xxwip_transfer_inf.business_block%TYPE
  INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE u_trn_inf_goods_classe_type        IS TABLE OF xxwip_transfer_inf.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE u_trn_inf_juris_hub_type           IS TABLE OF xxwip_transfer_inf.jurisdicyional_hub%TYPE
  INDEX BY BINARY_INTEGER;
  -- 地区名
  TYPE u_trn_inf_area_name_type           IS TABLE OF xxwip_transfer_inf.area_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替数量
  TYPE u_trn_inf_transfe_qty_type         IS TABLE OF xxwip_transfer_inf.transfe_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- 振替金額
  TYPE u_trn_inf_transfer_amount_type     IS TABLE OF xxwip_transfer_inf.transfer_amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_trn_inf_id_tab                    u_trn_inf_id_type;                  -- 振替情報ID
  u_trn_inf_target_date_tab           u_trn_inf_target_date_type;         -- 対象年月
  u_trn_inf_business_block_tab        u_trn_inf_business_block_type;      -- 営業ブロック
  u_trn_inf_goods_classe_tab          u_trn_inf_goods_classe_type;        -- 商品区分
  u_trn_inf_juris_hub_tab             u_trn_inf_juris_hub_type;           -- 管轄拠点
  u_trn_inf_area_name_tab             u_trn_inf_area_name_type;           -- 地区名
  u_trn_inf_transfe_qty_tab           u_trn_inf_transfe_qty_type;         -- 振替数量
  u_trn_inf_transfer_amount_tab       u_trn_inf_transfer_amount_type;     -- 振替金額
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_sysdate             DATE;             -- システム日付
  gn_user_id             NUMBER;           -- ユーザID
  gn_login_id            NUMBER;           -- 最終更新ログイン
  gn_conc_request_id     NUMBER;           -- 要求ID
  gn_prog_appl_id        NUMBER;           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id     NUMBER;           -- コンカレント・プログラムID
--
  gd_last_process_date   DATE;             -- 前回処理日付
  gv_closed_day          VARCHAR2(1);      -- 締日判定
--
  -- 受注件数
  gn_ins_order_inf_cnt   NUMBER DEFAULT 0; -- 振替運賃情報アドオン 登録用PL/SQL表 件数
  gn_upd_order_inf_cnt   NUMBER DEFAULT 0; -- 振替運賃情報アドオン 更新用PL/SQL表 件数
--
  gn_ins_order_sum_cnt   NUMBER DEFAULT 0; -- 振替運賃情報サマリーアドオン 登録用PL/SQL表 件数
  gn_upd_order_sum_cnt   NUMBER DEFAULT 0; -- 振替運賃情報サマリーアドオン 更新用PL/SQL表 件数
--
  gn_ins_trans_inf_cnt   NUMBER DEFAULT 0; -- 振替情報アドオン 登録用PL/SQL表 件数
  gn_upd_trans_inf_cnt   NUMBER DEFAULT 0; -- 振替情報アドオン 更新用PL/SQL表 件数
--
  gn_order_inf_cnt       NUMBER DEFAULT 0; -- 振替運賃情報アドオン         登録/更新成功件数
  gn_order_sum_cnt       NUMBER DEFAULT 0; -- 振替運賃情報サマリーアドオン 登録/更新成功件数
  gn_trans_inf_cnt       NUMBER DEFAULT 0; -- 振替情報アドオン             登録/更新成功件数
--
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
  gv_prod_div           xxwip_transfer_fare_inf.goods_classe%TYPE; -- 商品区分
  gv_concurrent_no      xxwip_deliverys_ctrl.concurrent_no%TYPE;   -- コンカレントNO
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
--
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
--
  /**********************************************************************************
   * Procedure Name   : del_deliveryoff_proc
   * Description      : 配車解除対象データ削除処理
   ***********************************************************************************/
  PROCEDURE del_deliveryoff_proc(
    iv_request_no    IN         VARCHAR2,     -- 依頼No
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_deliveryoff_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ================================================
    -- = 振替運賃情報アドオン 削除処理
    -- ================================================
    DELETE FROM xxwip_transfer_fare_inf
    WHERE  request_no = iv_request_no;
--
    -- ================================================
    -- = 振替運賃情報サマリーアドオン 削除処理
    -- ================================================
    DELETE FROM xxwip_transfer_fare_sum
    WHERE  request_no = iv_request_no;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_deliveryoff_proc;
--
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
--
  /**********************************************************************************
   * Procedure Name   : chk_param_proc
   * Description      : パラメータチェック処理(C-1)
   ***********************************************************************************/
  PROCEDURE chk_param_proc(
    iv_exchange_type   IN         VARCHAR2,     -- 洗い替え区分
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    iv_prod_div        IN         VARCHAR2,     -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count NUMBER;   -- チェック用カウンター
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- チェック用カウンターの初期化
    ln_count := 0;
--
    -- 入力パラメータの存在チェック
    SELECT COUNT(1) CNT                -- カウント
    INTO   ln_count
    FROM   xxcmn_lookup_values_v xlv   -- クイックコード情報VIEW
    WHERE  xlv.lookup_type = 'XXCMN_YESNO'
    AND    xlv.lookup_code = iv_exchange_type
    AND    ROWNUM          = 1;
--
    -- 洗い替え区分が存在しない場合
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,   gv_cmn_msg_75c_010,
                                            gv_tkn_parameter, gv_exchange_type_name,
                                            gv_tkn_value,     iv_exchange_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
--
  -- 商品区分 コード存在確認
    SELECT COUNT(1) CNT             -- カウント
    INTO   ln_count
    FROM   xxcmn_categories_v xcv   -- カテゴリ情報VIEW
    WHERE  xcv.category_set_name = '商品区分'
    AND    xcv.segment1 = iv_prod_div
    AND    ROWNUM = 1;
--
    -- 商品区分が存在しない場合
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                            gv_cmn_msg_75c_010,
                                            gv_tkn_parameter,
                                            gv_iv_prod_div_name,
                                            gv_tkn_value,
                                            iv_prod_div);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==================================================
    -- パラメータチェックOKであれば、商品区分を設定
    -- ==================================================
    gv_prod_div := iv_prod_div;
--
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_param_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_init
   * Description      : 関連データ取得(C-2)
   ***********************************************************************************/
  PROCEDURE get_init(
    iv_exchange_type IN         VARCHAR2,     -- 洗い替え区分
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_init'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_close_type VARCHAR2(1);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    gd_sysdate          := SYSDATE;                    -- システム日時
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ログインユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ログインID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- コンカレント要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
--
    -- 運賃計算用コントロールのコンカレントNO設定
    -- リーフの場合
    IF (gv_prod_div = gv_prod_class_lef) THEN
      gv_concurrent_no := gv_con_lef ;
--
    -- ドリンクの場合
    ELSE
      gv_concurrent_no := gv_con_drk ;
    END IF;
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
--
    -- 入力パラメータ.洗い替え区分 = NO の場合
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- 運賃計算用コントロールより前回処理日付を取得
      BEGIN
        SELECT xdc.last_process_date    -- 前回処理日付
        INTO   gd_last_process_date
        FROM   xxwip_deliverys_ctrl xdc -- 運賃計算用コントロールアドオン
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
--        WHERE  xdc.concurrent_no = gv_con_no_deli
        WHERE  xdc.concurrent_no = gv_concurrent_no
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
        FOR UPDATE NOWAIT;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
/*****
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_001,
                                                gv_tkn_table,   gv_deli_ctrl_name,
                                                gv_tkn_key,     gv_con_no_deli);
*****/
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                                gv_cmn_msg_75c_001,
                                                gv_tkn_table,
                                                gv_deli_ctrl_name,
                                                gv_tkn_key,
                                                gv_concurrent_no);
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN lock_expt THEN   --*** ロック取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                gv_tkn_table,   gv_deli_ctrl_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    END IF;
--
    -- 前月運賃締め後 判定
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type,   -- 締め区分(Y:締日前、N:締日後)
      lv_errbuf,       -- エラー・メッセージ
      lv_retcode,      -- リターン・コード
      lv_errmsg);      -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 締め判定 設定
    gv_closed_day := lv_close_type;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_proc
   * Description      : 受注データ抽出処理(C-3)
   ***********************************************************************************/
  PROCEDURE get_order_proc(
    iv_exchange_type IN         VARCHAR2,     -- 洗い替え区分
    ov_target_flg    OUT        VARCHAR2,     -- 対象データ有無フラグ 0:無し、1:有り
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データ有無フラグの初期化 デフォルト:データ有り
    ov_target_flg := '1';
--
    -- 受注ヘッダアドオン、受注明細アドオン、パーティ情報VIEW2、OPM品目情報VIEW、
    -- 受注タイプ情報VIEW、配送区分情報VIEW より対象データを取得
    SELECT xoha.order_header_id,                 -- 1.受注ヘッダアドオンID
           xoha.order_type_id,                   -- 2.受注タイプ
           xoha.request_no,                      -- 3.依頼No
           xoha.arrival_date,                    -- 4.着荷日
           xoha.head_sales_branch,               -- 5.管轄拠点
           xoha.deliver_from,                    -- 6.出荷元保管場所
-- ##### 20080609 MOD TE080指摘事項対応 start #####
/***
           xoha.deliver_to,                      -- 7.出荷先
           xoha.shipping_method_code,            -- 8.配送区分
***/
           xoha.result_deliver_to,               -- 7.出荷先_実績
           xoha.result_shipping_method_code,     -- 8.配送区分_実績
-- ##### 20080609 MOD TE080指摘事項対応 end  #####
-- ##### 20081206 Ver.1.11 本番#532対応 start #####
--           xoha.small_quantity,                  -- 9.小口個数
           NVL(xoha.small_quantity, 0),            -- 9.小口個数
-- ##### 20081206 Ver.1.11 本番#532対応 end   #####
           xoha.prod_class,                      -- 10.商品区分
           TO_CHAR(xoha.arrival_date, 'YYYYMM'), -- 11.対象年月(形式:YYYYMM)
           xola.shipping_item_code,              -- 12.出荷品目
-- 2008/07/29 Mod ↓
/*
           xola.shipped_quantity,                -- 13.出荷実績数量
*/
           NVL(xola.shipped_quantity,0),         -- 13.出荷実績数量
-- 2008/07/29 Mod ↑
           ximv.product_class,                   -- 14.商品分類
           ximv.conv_unit,                       -- 15.入出庫換算単位
           ximv.num_of_cases,                    -- 16.ケース入数
           xpv.base_major_division,              -- 17.拠点大分類
           xsmv.small_amount_class,              -- 18.小口区分
           xsmv.penalty_class,                   -- 19.ペナルティ区分
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
--           NULL                                  -- 20.単価(ここではNULLを設定)
           NULL ,                                -- 20.単価(ここではNULLを設定)
           xoha.delivery_no                      -- 配送No
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
    BULK COLLECT INTO gt_order_inf_tbl
    FROM   xxwsh_order_headers_all      xoha,    -- 受注ヘッダアドオン
           xxwsh_order_lines_all        xola,    -- 受注明細アドオン
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
--           xxcmn_parties2_v             xpv,     -- パーティ情報VIEW2
           xxcmn_cust_accounts2_v         xpv,     -- 顧客情報VIEW2
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
           xxcmn_item_mst2_v            ximv,    -- OPM品目情報VIEW
           xxwsh_ship_method_v          xsmv,    -- 配送区分情報VIEW
           xxwsh_oe_transaction_types_v xotv     -- 受注タイプ情報VIEW
    WHERE  xoha.order_header_id       = xola.order_header_id
    AND    xoha.order_type_id         = xotv.transaction_type_id
    AND    xoha.latest_external_flag  = gv_ktg_yes
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    AND    xoha.prod_class            = gv_prod_div -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
    AND    xoha.result_deliver_to           IS NOT NULL   -- 出荷先_実績
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 start *----------*
--    AND    xoha.result_shipping_method_code IS NOT NULL   -- 配送先_実績
--    AND    xoha.result_freight_carrier_code IS NOT NULL   -- 運送業者_実績
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 end   *----------*
    AND    xoha.arrival_date                IS NOT NULL   -- 着荷日
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
-- ********** 20080508 内部変更要求 seq#75 MOD START **********
/***
    AND    xpv.transfer_standard      = '1'      -- 「1:設定振替」
***/
    AND (
            ((xoha.prod_class = gv_prod_class_lef)      -- 商品区分 = リーフ
            AND (xpv.leaf_transfer_std       = '1'))    -- 「1:設定振替」
          OR
            ((xoha.prod_class = gv_prod_class_drk)      -- 商品区分 = ドリンク
            AND (xpv.drink_transfer_std      = '1'))    -- 「1:設定振替」
        )
-- ********** 20080508 内部変更要求 seq#75 MOD END   **********
--
-- ##### 20081106 Ver.1.9 統合#563対応 start #####
-- ##### 20090108 Ver.1.14 本番#961対応 START #####
-- 小口から車立に変更した際削除する必要があるので、車立も抽出対象とする
--    AND 
--      NOT ((xoha.prod_class = gv_prod_class_lef)            -- 商品区分 = リーフの
--            AND (xsmv.small_amount_class = gv_small_sum_no) -- 「0:車立」は除外する
--          )
-- ##### 20090108 Ver.1.14 本番#961対応 END   #####
-- ##### 20081106 Ver.1.9 統合#563対応 end   #####
--
    AND    xotv.shipping_shikyu_class = '1'      -- 「1:出荷依頼」
    AND    xola.shipping_item_code    = ximv.item_no
    AND    xola.delete_flag           = 'N'      -- 削除されていない明細
    AND    FND_DATE.STRING_TO_DATE(TO_CHAR(xoha.arrival_date, 'YYYYMM') || '01', 'YYYYMMDD')
      BETWEEN ximv.start_date_active AND ximv.end_date_active
    AND    xpv.party_number = xoha.head_sales_branch
    AND    FND_DATE.STRING_TO_DATE(TO_CHAR(xoha.arrival_date, 'YYYYMM') || '01', 'YYYYMMDD')
      BETWEEN xpv.start_date_active
        AND NVL(xpv.end_date_active, FND_DATE.STRING_TO_DATE('99991231','YYYYMMDD'))
-- ##### 20080609 MOD TE080指摘事項対応 start #####
/***
    AND    xsmv.ship_method_code      = xoha.shipping_method_code
***/
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 start *----------*
--    AND    xsmv.ship_method_code      = xoha.result_shipping_method_code
    AND    xsmv.ship_method_code(+)      = xoha.result_shipping_method_code
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 end   *----------*
-- ##### 20080609 MOD TE080指摘事項対応 end   #####
    AND    FND_DATE.STRING_TO_DATE(TO_CHAR(xoha.arrival_date, 'YYYYMM') || '01', 'YYYYMMDD')
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 start *----------*
--      BETWEEN xsmv.start_date_active
--        AND NVL(xsmv.end_date_active, FND_DATE.STRING_TO_DATE('99991231','YYYYMMDD'))
      BETWEEN xsmv.start_date_active(+)
        AND NVL(xsmv.end_date_active(+), FND_DATE.STRING_TO_DATE('99991231','YYYYMMDD'))
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 end   *----------*
    AND    (((gv_closed_day = gv_ktg_no)          -- 関連データ取得.前月運賃締日後の場合
      AND ((TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(gd_sysdate, 'YYYYMM'))
-- 2009/12/09 v1.19 T.Yoshimoto Add Start E_本稼動_00346
       -- 関連データ取得.システム日付の年月の翌月
       OR (TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(ADD_MONTHS(gd_sysdate, 1), 'YYYYMM'))))
-- 2009/12/09 v1.19 T.Yoshimoto Add End E_本稼動_00346
        OR (((gv_closed_day = gv_ktg_yes)       -- 関連データ取得.前月運賃締日前の場合
          AND ((TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(gd_sysdate, 'YYYYMM'))
            OR (TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM'))
-- 2009/12/09 v1.19 T.Yoshimoto Add Start E_本稼動_00346
            -- 関連データ取得.システム日付の年月の翌月
            OR (TO_CHAR(xoha.arrival_date, 'YYYYMM') = TO_CHAR(ADD_MONTHS(gd_sysdate, 1), 'YYYYMM')))))
-- 2009/12/09 v1.19 T.Yoshimoto Add End E_本稼動_00346
           )
    AND    (((iv_exchange_type = gv_ktg_no)        -- 入力パラメータ.洗い替え区分 = 「NO」の場合
      AND (((xoha.last_update_date >  gd_last_process_date)
        AND (gd_sysdate        >= xoha.last_update_date))
      OR ((xola.last_update_date >  gd_last_process_date)
        AND (gd_sysdate        >= xola.last_update_date))))
          OR ( iv_exchange_type = gv_ktg_yes ))
    ORDER BY xoha.request_no;
--
    -- 対象データなしの場合
    IF (NOT gt_order_inf_tbl.EXISTS(1)) THEN
      -- 対象データ有無フラグに「無し」を設定
      ov_target_flg := '0';
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_trn
   * Description      : 振替運賃情報アドオンデータ設定(C-4)
   ***********************************************************************************/
  PROCEDURE set_trn(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_trn'; -- プログラム名
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
    -- *** ローカル定数 ***
    cv_reaf_tbl_name  CONSTANT VARCHAR2(50) := 'リーフ振替運賃アドオンマスタ';
    cv_drink_tbl_name CONSTANT VARCHAR2(50) := 'ドリンク振替運賃アドオンマスタ';
--
    -- *** ローカル変数 ***
    ln_flg              NUMBER;   -- 存在チェック用フラグ 「0:無し、1:有り」
    ln_trn_fare_inf_id  NUMBER;   -- ID格納用
    lt_item_id          xxcmn_item_mst_b.item_id%TYPE;   -- 品目ID
--2008/09/22 Add
    ln_msg_flg          NUMBER;
    lv_tbl_name         VARCHAR2(200);
--
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
    lv_request_no      xxwsh_order_headers_all.request_no%TYPE;   -- 依頼No（保持用）
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
    -- 依頼No 初期化
    lv_request_no := NULL;
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
--
    -- 取得した対象データのマスタデータを取得する
    <<gt_order_inf_tbl_loop>>
    FOR ln_index IN gt_order_inf_tbl.FIRST .. gt_order_inf_tbl.LAST LOOP
--
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
-- ##### 20081215 Ver.1.13 本番#712対応 START #####
-- 条件に関係なく初回の依頼Noを削除するようにする為
-- コメントアウト
      -- ==================================================
      -- = 配車NoがNULLの場合
      -- =   配車を解除されている為、振替情報から削除する
      -- ==================================================
--      IF (gt_order_inf_tbl(ln_index).delivery_no IS NULL ) THEN
-- ##### 20081215 Ver.1.13 本番#712対応 END   #####
--
        -- ==================================================
        -- = 取込する出荷依頼の依頼Noは登録前に一度削除する
        -- ==================================================
        -- 依頼番号が変更された場合
        IF ((lv_request_no IS NULL)
          OR (gt_order_inf_tbl(ln_index).request_no <> lv_request_no )) THEN
--
          -- 削除対象 依頼No 設定（brack用）
          lv_request_no := gt_order_inf_tbl(ln_index).request_no;
--
          -- ==================================================
          --  削除処理（削除対象は以下のテーブル）
          --    振替運賃情報アドオン
          --    振替運賃情報サマリーアドオン
          -- ==================================================
          del_deliveryoff_proc(gt_order_inf_tbl(ln_index).request_no ,   -- 依頼No
                               lv_errbuf ,
                               lv_retcode ,
                               lv_errmsg  );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
-- ##### 20081215 Ver.1.13 本番#712対応 START #####
-- 条件に関係なく初回の依頼Noを削除するようにする為
-- コメントアウト
      -- ==================================================
      -- = 配車Noが設定されている場合
      -- =    振替運賃の対象とする
      -- ==================================================
--      ELSE
      -- 振替運賃情報アドオンへの登録は配車のある依頼No且つリーフ車立以外
-- ##### 20090108 Ver.1.14 本番#961対応 START #####
-- 配送Noが登録されている場合と、リーフ車立以外を対象とする
--      IF (gt_order_inf_tbl(ln_index).delivery_no IS NOT NULL ) THEN
      IF ((gt_order_inf_tbl(ln_index).delivery_no IS NOT NULL )
      AND  NOT ((gt_order_inf_tbl(ln_index).prod_class         = gv_prod_class_lef)
      AND       (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no)) ) THEN
-- ##### 20090108 Ver.1.14 本番#961対応 END   #####
-- ##### 20081215 Ver.1.13 本番#712対応 END   #####
--
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
--
--2008/09/22 Add
        ln_msg_flg := 0;
--
        -- 受注データ抽出処理.商品区分 = 「リーフ」の場合
        IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
          -- 受注データ抽出処理.小口区分 = 「車立」の場合
          IF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no) THEN
            -- リーフ振替運賃アドオンマスタより単価(便設定金額)を取得
            BEGIN
              SELECT xltdc.setting_amount              -- 単価(便設定金額)
              INTO   gt_order_inf_tbl(ln_index).setting_amount
              FROM   xxwip_leaf_trans_deli_chrgs xltdc -- リーフ振替運賃アドオンマスタ
              WHERE  FND_DATE.STRING_TO_DATE(
                       gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                     BETWEEN xltdc.start_date_active
                       AND NVL(xltdc.end_date_active
                              ,FND_DATE.STRING_TO_DATE('99991231', 'YYYYMMDD'));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
                -- データが存在しない場合は単価に「0」を設定
                gt_order_inf_tbl(ln_index).setting_amount := 0;
                ln_msg_flg := 1;                                    -- 2008/09/22 Add
            END;
--
          -- 受注データ抽出処理.小口区分 = 「小口」の場合
          ELSIF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_yes) THEN
            -- リーフ振替運賃アドオンマスタより単価(便設定金額)を取得
            BEGIN
              -- 小口個数によって設定金額を取得
              SELECT 
                CASE
-- ##### 20090127 Ver.1.16 本番#1078対応 start #####
                  -- 小口個数＝０の場合、単価を０に設定する
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity = 0) THEN 0
-- ##### 20090127 Ver.1.16 本番#1078対応 end   #####
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number1) THEN
                    xltdc.setting_amount1
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number2) THEN
                    xltdc.setting_amount2
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number3) THEN
                    xltdc.setting_amount3
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number4) THEN
                    xltdc.setting_amount4
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number5) THEN
                    xltdc.setting_amount5
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number6) THEN
                    xltdc.setting_amount6
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number7) THEN
                    xltdc.setting_amount7
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number8) THEN
                    xltdc.setting_amount8
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number9) THEN
                    xltdc.setting_amount9
                  WHEN (gt_order_inf_tbl(ln_index).small_quantity <= xltdc.upper_limit_number10) THEN
                     xltdc.setting_amount10
                  ELSE 0
                END AS setting_amount                   -- 単価(便設定金額)
              INTO  gt_order_inf_tbl(ln_index).setting_amount
              FROM  xxwip_leaf_trans_deli_chrgs xltdc -- リーフ振替運賃アドオンマスタ
              WHERE FND_DATE.STRING_TO_DATE(
                      gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                    BETWEEN xltdc.start_date_active AND xltdc.end_date_active;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
                -- データが存在しない場合は単価に「0」を設定
                gt_order_inf_tbl(ln_index).setting_amount := 0;
                ln_msg_flg := 1;                                    -- 2008/09/22 Add
            END;
--
          END IF;
--
        -- 受注データ抽出処理.商品区分 = 「ドリンク」の場合
        ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
--
          BEGIN
            SELECT CASE
                     WHEN (gt_order_inf_tbl(ln_index).penalty_class = gv_penalty_no) THEN
                       xdtdc.setting_amount
                     WHEN (gt_order_inf_tbl(ln_index).penalty_class = gv_penalty_yes) THEN
                       xdtdc.penalty_amount
                     ELSE 0
                   END AS setting_amount                     -- 便設定金額
            INTO   gt_order_inf_tbl(ln_index).setting_amount
            FROM   xxwip_drink_trans_deli_chrgs xdtdc -- ドリンク振替運賃アドオンマスタ
            WHERE  xdtdc.godds_classification   = gt_order_inf_tbl(ln_index).product_class
            AND    xdtdc.dellivary_classe       = gt_order_inf_tbl(ln_index).shipping_method_code
            AND    xdtdc.foothold_macrotaxonomy = gt_order_inf_tbl(ln_index).base_major_division
            AND    FND_DATE.STRING_TO_DATE(
                     gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                   BETWEEN xdtdc.start_date_active AND xdtdc.end_date_active;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
              -- データが存在しない場合は単価に「0」を設定
              gt_order_inf_tbl(ln_index).setting_amount := 0;
              ln_msg_flg := 2;                                      -- 2008/09/22 Add
          END;
--
        END IF;
--
        -- 抽出したデータを元に振替運賃情報アドオンの存在チェックを行い、存在する場合はロックを行う
        BEGIN
          SELECT xtfi.transfer_fare_inf_id    -- 振替運賃情報ID
          INTO   ln_trn_fare_inf_id
          FROM   xxwip_transfer_fare_inf xtfi -- 振替運賃情報アドオン
          WHERE  xtfi.target_date        = gt_order_inf_tbl(ln_index).arrival_yyyymm
          AND    xtfi.request_no         = gt_order_inf_tbl(ln_index).request_no
          AND    xtfi.goods_classe       = gt_order_inf_tbl(ln_index).prod_class
          AND    xtfi.jurisdicyional_hub = gt_order_inf_tbl(ln_index).head_sales_branch
          AND    xtfi.item_code          = gt_order_inf_tbl(ln_index).shipping_item_code
          FOR UPDATE NOWAIT;
--
          -- 存在する場合は存在チェック用フラグを「1」に設定
          ln_flg := 1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
            -- データが存在しない場合は存在チェック用フラグに「0」を設定
            ln_flg := 0;
          WHEN lock_expt THEN   -- *** ロック取得エラー ***
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                  gv_tkn_table,   gv_trans_fare_inf_name);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- 品目IDの取得
        BEGIN
          SELECT ximv.item_id            -- 品目ID
          INTO   lt_item_id
          FROM   xxcmn_item_mst2_v ximv   -- OPM品目情報VIEW
          WHERE  ximv.item_no = gt_order_inf_tbl(ln_index).shipping_item_code
          AND    FND_DATE.STRING_TO_DATE(
                   gt_order_inf_tbl(ln_index).arrival_yyyymm || '01', 'YYYYMMDD')
                 BETWEEN ximv.start_date_active AND ximv.end_date_active;
        EXCEPTION
          WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN   -- *** データ取得エラー ***
            RAISE global_api_expt;
        END;
--
        -- 存在しない場合は振替運賃情報アドオン登録用PL/SQL表に格納
        IF (ln_flg = 0) THEN
--
          -- 登録用PL/SQL表 件数カウント
          gn_ins_order_inf_cnt := gn_ins_order_inf_cnt + 1;
--
          -- 1.振替運賃情報ID 採番
          SELECT xxwip_transfer_fare_inf_id_s1.NEXTVAL
          INTO   i_trn_fare_inf_id_tab(gn_ins_order_inf_cnt)
          FROM   dual;
--
          -- ****************************************
          -- * 振替運賃情報データ 登録用PL/SQL表 設定
          -- ****************************************
          -- 2.対象年月
          i_trn_target_date_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_yyyymm;
          -- 3.依頼No
          i_trn_request_no_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).request_no;
          -- 4.商品区分
          i_trn_goods_classe_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).prod_class;
          -- 5.配送日
          i_trn_delivery_date_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_date;
          -- 6.管轄拠点
          i_trn_jurisdicyional_hub_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).head_sales_branch;
          -- 7.出庫元
          i_trn_delivery_whs_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_from;
          -- 8.配送先
          i_trn_ship_to_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_to;
          -- 9.品目コード
          i_trn_item_code_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).shipping_item_code;
          -- 10.単価
          i_trn_price_tab(gn_ins_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).setting_amount;
--
          -- 11.計算数量
          -- 受注データ抽出処理.商品区分 = 「ドリンク」の場合
          IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
-- ********** 20080508 内部変更要求 seq#59 MOD START **********
/***
            i_trn_calc_qry_tab(gn_ins_order_inf_cnt) :=
              TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                      gv_rcv_to_first                               -- 変換方法
                     ,lt_item_id                                    -- 品目ID
                     ,gt_order_inf_tbl(ln_index).shipped_quantity   -- 数量
                    ));
***/
            -- 計算数量変換
            i_trn_calc_qry_tab(gn_ins_order_inf_cnt) :=
              xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                    gt_order_inf_tbl(ln_index).shipping_item_code -- 品目コード
                  , gt_order_inf_tbl(ln_index).shipped_quantity);    -- 数量
-- ********** 20080508 内部変更要求 seq#59 MOD END   **********
--
          -- 受注データ抽出処理.商品区分 = 「リーフ」の場合
          ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
            -- 受注データ抽出処理.小口区分 = 「車立」の場合
-- 2008/07/29 Mod ↓
/*
            IF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_no) THEN
*/
            IF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no) THEN
-- 2008/07/29 Mod ↑
              -- 固定で「1」を設定
              i_trn_calc_qry_tab(gn_ins_order_inf_cnt) := 1;
            -- 受注データ抽出処理.小口区分 = 「小口」の場合
-- 2008/07/29 Mod ↓
/*
            ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_yes) THEN
*/
            ELSIF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_yes) THEN
-- 2008/07/29 Mod ↑
              -- 受注データ抽出処理.小口個数を設定
              i_trn_calc_qry_tab(gn_ins_order_inf_cnt) := gt_order_inf_tbl(ln_index).small_quantity;
            END IF;
          END IF;
--
          -- 12.実際数量
-- ********** 20080508 内部変更要求 seq#59 MOD START **********
/***
          i_trn_actual_qty_tab(gn_ins_order_inf_cnt) :=
            TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                    gv_rcv_to_first                               -- 変換方法
                   ,lt_item_id                                    -- 品目ID
                   ,gt_order_inf_tbl(ln_index).shipped_quantity   -- 数量
                 ));
***/
          i_trn_actual_qty_tab(gn_ins_order_inf_cnt) :=
                  xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                        gt_order_inf_tbl(ln_index).shipping_item_code -- 品目コード
                      , gt_order_inf_tbl(ln_index).shipped_quantity); -- 数量
-- ********** 20080508 内部変更要求 seq#59 MOD END   **********
--
-- ##### 20081213 Ver.1.12 本番#721対応 START #####
-- ##### 20081213 Ver.1.12 本番#721対応 END   #####
        -- 「ドリンク」の場合
          IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
            -- 単価 × 計算数量
            i_trn_amount_tab(gn_ins_order_inf_cnt) :=
                gt_order_inf_tbl(ln_index).setting_amount * i_trn_calc_qry_tab(gn_ins_order_inf_cnt);
--
          -- 「リーフ」の場合
          ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
            -- リーフは現状単価を設定（車立については対象外のため、考慮しない）
            i_trn_amount_tab(gn_ins_order_inf_cnt) :=
                                  gt_order_inf_tbl(ln_index).setting_amount;
--
          END IF;
--          -- 13.金額
--          i_trn_amount_tab(gn_ins_order_inf_cnt) :=
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
--          gt_order_inf_tbl(ln_index).setting_amount * i_trn_calc_qry_tab(gn_ins_order_inf_cnt);
   -- ##### 20081106 Ver.1.9 統合#537対応 start #####
--          ROUND(gt_order_inf_tbl(ln_index).setting_amount * i_trn_calc_qry_tab(gn_ins_order_inf_cnt));
--            gt_order_inf_tbl(ln_index).setting_amount;
   -- ##### 20081106 Ver.1.9 統合#537対応 End   #####
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
-- ##### 20081213 Ver.1.12 本番#721対応 END   #####
--
        -- 存在する場合は振替運賃情報アドオン更新用PL/SQL表に格納
        ELSIF (ln_flg = 1) THEN
--
        -- 更新用PL/SQL表 件数カウント
        gn_upd_order_inf_cnt := gn_upd_order_inf_cnt + 1;
--
          -- **************************************
          -- * 振替運賃情報データ 更新用PL/SQL 設定
          -- **************************************
          -- 1.振替運賃情報ID
          u_trn_fare_inf_id_tab(gn_upd_order_inf_cnt) := ln_trn_fare_inf_id;
          -- 2.対象年月
          u_trn_target_date_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_yyyymm;
          -- 3.依頼No
          u_trn_request_no_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).request_no;
          -- 4.商品区分
          u_trn_goods_classe_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).prod_class;
          -- 5.配送日
          u_trn_delivery_date_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).arrival_date;
          -- 6.管轄拠点
          u_trn_jurisdicyional_hub_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).head_sales_branch;
          -- 7.出庫元
          u_trn_delivery_whs_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_from;
          -- 8.配送先
          u_trn_ship_to_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).deliver_to;
          -- 9.品目コード
          u_trn_item_code_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).shipping_item_code;
          -- 10.単価
          u_trn_price_tab(gn_upd_order_inf_cnt)
            := gt_order_inf_tbl(ln_index).setting_amount;
--
          -- 11.計算数量
          -- 受注データ抽出処理.商品区分 = 「ドリンク」の場合
          IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
-- ********** 20080508 内部変更要求 seq#59 MOD START **********
/***
            -- 入出庫換算関数の呼び出し
            u_trn_calc_qry_tab(gn_upd_order_inf_cnt) :=
              TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                      gv_rcv_to_first                               -- 変換方法
                     ,lt_item_id                                    -- 品目ID
                     ,gt_order_inf_tbl(ln_index).shipped_quantity   -- 数量
                   ));
***/
            u_trn_calc_qry_tab(gn_upd_order_inf_cnt) :=
                xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                      gt_order_inf_tbl(ln_index).shipping_item_code -- 品目コード
                    , gt_order_inf_tbl(ln_index).shipped_quantity); -- 数量
-- ********** 20080508 内部変更要求 seq#59 MOD END   **********
--
          -- 受注データ抽出処理.商品区分 = 「リーフ」の場合
          ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
            -- 受注データ抽出処理.小口区分 = 「車立」の場合
-- 2008/07/29 Mod ↓
/*
            IF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_no) THEN
*/
            IF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_no) THEN
-- 2008/07/29 Mod ↑
              -- 固定で「1」を設定
              u_trn_calc_qry_tab(gn_upd_order_inf_cnt) := 1;
            -- 受注データ抽出処理.小口区分 = 「小口」の場合
-- 2008/07/29 Mod ↓
/*
            ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_small_sum_yes) THEN
*/
            ELSIF (gt_order_inf_tbl(ln_index).small_amount_class = gv_small_sum_yes) THEN
-- 2008/07/29 Mod ↑
              -- 受注データ抽出処理.小口個数を設定
              u_trn_calc_qry_tab(gn_upd_order_inf_cnt) := gt_order_inf_tbl(ln_index).small_quantity;
            END IF;
          END IF;
--
-- ********** 20080508 内部変更要求 seq#59 MOD START **********
/***
          -- 12.実際数量
          u_trn_actual_qty_tab(gn_upd_order_inf_cnt) :=
            TRUNC(xxcmn_common_pkg.rcv_ship_conv_qty(
                    gv_rcv_to_first                               -- 変換方法
                   ,lt_item_id                                    -- 品目ID
                   ,gt_order_inf_tbl(ln_index).shipped_quantity   -- 数量
                 ));
***/
          u_trn_actual_qty_tab(gn_upd_order_inf_cnt) :=
                xxwip_common3_pkg.deliv_rcv_ship_conv_qty(
                      gt_order_inf_tbl(ln_index).shipping_item_code -- 品目コード
                    , gt_order_inf_tbl(ln_index).shipped_quantity); -- 数量
-- ********** 20080508 内部変更要求 seq#59 MOD END   **********
--
          -- 13.金額
-- ##### 20081128 Ver.1.10 本番222対応 start #####
          -- 「ドリンク」の場合
          IF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_drk) THEN
            -- 単価 × 計算数量
            u_trn_amount_tab(gn_upd_order_inf_cnt) :=
                gt_order_inf_tbl(ln_index).setting_amount * u_trn_calc_qry_tab(gn_upd_order_inf_cnt);
--
          -- 「リーフ」の場合
          ELSIF (gt_order_inf_tbl(ln_index).prod_class = gv_prod_class_lef) THEN
            -- リーフは現状単価を設定（車立については対象外のため、考慮しない）
            u_trn_amount_tab(gn_upd_order_inf_cnt) :=
                                  gt_order_inf_tbl(ln_index).setting_amount;
--
          END IF;
--
--          u_trn_amount_tab(gn_upd_order_inf_cnt) :=
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
--          gt_order_inf_tbl(ln_index).setting_amount * u_trn_calc_qry_tab(gn_upd_order_inf_cnt);
   -- ##### 20081106 Ver.1.9 統合#537対応 start #####
--          ROUND(gt_order_inf_tbl(ln_index).setting_amount * u_trn_calc_qry_tab(gn_upd_order_inf_cnt));
--            gt_order_inf_tbl(ln_index).setting_amount;
   -- ##### 20081106 Ver.1.9 統合#537対応 End   #####
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
-- ##### 20081128 Ver.1.10 本番222対応 end   #####
        END IF;
--2008/09/22 Add ↓
        IF (ln_msg_flg > 0) THEN
--
          -- リーフ
          IF (ln_msg_flg = 1) THEN
            lv_tbl_name := cv_reaf_tbl_name;
--
          -- ドリンク
          ELSIF (ln_msg_flg = 2) THEN
            lv_tbl_name := cv_drink_tbl_name;
          END IF;
--
          -- メッセージ出力
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                                gv_wip_msg_75c_009,
                                                gv_tkn_tbl_name,
                                                lv_tbl_name,
                                                gv_tkn_req_no,
                                                gt_order_inf_tbl(ln_index).request_no);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END IF;
  --2008/09/22 Add ↑
  --
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
      END IF;
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
--
    END LOOP gt_order_inf_tbl_loop;
--
  EXCEPTION
    WHEN func_inv_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
-- ##### 20081016 Ver.1.7 内部変更#225 start #####
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
-- ##### 20081016 Ver.1.7 内部変更#225 end   #####
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_trn;
--
  /**********************************************************************************
   * Procedure Name   : ins_trn_proc
   * Description      : 振替運賃情報アドオン一括登録処理(C-5)
   ***********************************************************************************/
  PROCEDURE ins_trn_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_trn_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***************************
    -- * 振替運賃情報アドオン 登録
    -- ***************************
    FORALL ln_index IN i_trn_fare_inf_id_tab.FIRST .. i_trn_fare_inf_id_tab.LAST
      INSERT INTO xxwip_transfer_fare_inf     -- 振替運賃情報アドオン
      (transfer_fare_inf_id                   -- 1.振替運賃情報ID
      ,target_date                            -- 2.対象年月
      ,request_no                             -- 3.依頼Ｎｏ
      ,goods_classe                           -- 4.商品区分
      ,delivery_date                          -- 5.配送日
      ,jurisdicyional_hub                     -- 6.管轄拠点
      ,delivery_whs                           -- 7.出庫元
      ,ship_to                                -- 8.配送先
      ,item_code                              -- 9.品目コード
      ,price                                  -- 10.単価
      ,calc_qry                               -- 11.計算数量
      ,actual_qty                             -- 12.実際数量
      ,amount                                 -- 13.金額
      ,created_by                             -- 14.作成者
      ,creation_date                          -- 15.作成日
      ,last_updated_by                        -- 16.最終更新者
      ,last_update_date                       -- 17.最終更新日
      ,last_update_login                      -- 18.最終更新ログイン
      ,request_id                             -- 19.要求ID
      ,program_application_id                 -- 20.コンカレント・プログラム・アプリケーションID
      ,program_id                             -- 21.コンカレント・プログラムID
      ,program_update_date)                   -- 22.プログラム更新日
      VALUES
      (i_trn_fare_inf_id_tab(ln_index)        -- 1.振替運賃情報ID
      ,i_trn_target_date_tab(ln_index)        -- 2.対象年月
      ,i_trn_request_no_tab(ln_index)         -- 3.依頼Ｎｏ
      ,i_trn_goods_classe_tab(ln_index)       -- 4.商品区分
      ,i_trn_delivery_date_tab(ln_index)      -- 5.配送日
      ,i_trn_jurisdicyional_hub_tab(ln_index) -- 6.管轄拠点
      ,i_trn_delivery_whs_tab(ln_index)       -- 7.出庫元
      ,i_trn_ship_to_tab(ln_index)            -- 8.配送先
      ,i_trn_item_code_tab(ln_index)          -- 9.品目コード
      ,i_trn_price_tab(ln_index)              -- 10.単価
      ,i_trn_calc_qry_tab(ln_index)           -- 11.計算数量
      ,i_trn_actual_qty_tab(ln_index)         -- 12.実際数量
      ,i_trn_amount_tab(ln_index)             -- 13.金額
      ,gn_user_id                             -- 14.作成者
      ,gd_sysdate                             -- 15.作成日
      ,gn_user_id                             -- 16.最終更新者
      ,gd_sysdate                             -- 17.最終更新日
      ,gn_login_id                            -- 18.最終更新ログイン
      ,gn_conc_request_id                     -- 19.要求ID
      ,gn_prog_appl_id                        -- 20.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
      ,gn_conc_program_id                     -- 21.コンカレント・プログラムID
      ,gd_sysdate);                           -- 22.プログラム更新日
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_trn_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_trn_proc
   * Description      : 振替運賃情報アドオン一括更新処理(C-6)
   ***********************************************************************************/
  PROCEDURE upd_trn_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_trn_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***************************
    -- * 振替運賃情報アドオン 更新
    -- ***************************
    FORALL ln_index IN u_trn_target_date_tab.FIRST .. u_trn_target_date_tab.LAST
      UPDATE xxwip_transfer_fare_inf xtfi -- 振替運賃情報アドオン
      SET    price                     = u_trn_price_tab(ln_index)      -- 単価
            ,calc_qry                  = u_trn_calc_qry_tab(ln_index)   -- 計算数量
            ,actual_qty                = u_trn_actual_qty_tab(ln_index) -- 実際数量
            ,amount                    = u_trn_amount_tab(ln_index)     -- 金額
            ,last_updated_by           = gn_user_id                 -- 最終更新者
            ,last_update_date          = gd_sysdate                 -- 最終更新日
            ,last_update_login         = gn_login_id                -- 最終更新ログイン
            ,request_id                = gn_conc_request_id         -- 要求ID
            ,program_application_id    = gn_prog_appl_id            -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            ,program_id                = gn_conc_program_id         -- コンカレント・プログラムID
            ,program_update_date       = gd_sysdate                 -- プログラム更新日
      WHERE  xtfi.transfer_fare_inf_id = u_trn_fare_inf_id_tab(ln_index);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_trn_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_trn_proc
   * Description      : 振替運賃情報アドオン抽出処理(C-7)
   ***********************************************************************************/
  PROCEDURE get_trn_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trn_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データの取得
    SELECT xtfi.target_date,            -- 1.対象年月
           xtfi.request_no,             -- 2.依頼No
           xtfi.goods_classe,           -- 3.商品区分
           xtfi.jurisdicyional_hub,     -- 4.管轄拠点
-- 2009/01/19 v1.15 UPDATE START
--           SUM(xtfi.actual_qty),        -- 5.振替数量
           CASE                         -- 5.振替数量
             WHEN (xtfi.goods_classe = gv_prod_class_lef) THEN
               TRUNC(AVG(xtfi.calc_qry))
             WHEN (xtfi.goods_classe = gv_prod_class_drk) THEN
               SUM(xtfi.calc_qry)
           END,
-- 2009/01/19 v1.15 UPDATE END
           CASE                         -- 6.リーフ振替金額
             WHEN (xtfi.goods_classe = gv_prod_class_lef) THEN
               TRUNC(AVG(xtfi.amount))
             WHEN (xtfi.goods_classe = gv_prod_class_drk) THEN
               NULL
             ELSE 0
           END AS leaf_chg_amount,
           CASE                         -- 7.ドリンク振替金額
             WHEN (xtfi.goods_classe = gv_prod_class_lef) THEN
               NULL
             WHEN (xtfi.goods_classe = gv_prod_class_drk) THEN
               SUM(xtfi.amount)
             ELSE 0
           END AS drink_chg_amount
    BULK COLLECT INTO gt_order_summary_tbl
    FROM   xxwip_transfer_fare_inf xtfi       -- 振替運賃情報アドオン
    WHERE  (((gv_closed_day = gv_ktg_no)
             AND (xtfi.target_date = TO_CHAR(gd_sysdate, 'YYYYMM')))
           OR ((gv_closed_day = gv_ktg_yes)   -- 前月運賃締日前の場合
-- 2009/12/10 v1.19 T.Yoshimoto Mod Start 内部気づき
--             AND (xtfi.target_date  = TO_CHAR(gd_sysdate, 'YYYYMM'))
--             OR  (xtfi.target_date  = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM'))))
--
             AND ((xtfi.target_date  = TO_CHAR(gd_sysdate, 'YYYYMM'))
             OR  (xtfi.target_date  = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM')))))
-- 2009/12/10 v1.19 T.Yoshimoto Mod End 内部気づき
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    AND    xtfi.goods_classe  = gv_prod_div   -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
    GROUP BY xtfi.target_date,
             xtfi.request_no,
             xtfi.goods_classe,
             xtfi.jurisdicyional_hub;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_trn_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_trn_sum
   * Description      : 振替運賃情報サマリーアドオンデータ設定(C-8)
   ***********************************************************************************/
  PROCEDURE set_trn_sum(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_trn_sum'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_flg             NUMBER;   -- 存在チェック用フラグ 「0:無し、1:有り」
    ln_trn_fare_sum_id NUMBER;   -- ID格納用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 start *----------*
    IF (gt_order_summary_tbl.COUNT = 0) THEN
      RETURN;
    END IF;
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 end   *----------*
--
    -- 抽出した対象データのレコードを１件ずつ取得する
    <<gt_order_summary_tbl_loop>>
    FOR ln_index IN gt_order_summary_tbl.FIRST .. gt_order_summary_tbl.LAST LOOP
--
      -- 抽出したデータを元に振替運賃情報サマリーアドオンの存在チェックを行い
      -- 存在する場合はロックを行う
      BEGIN
        SELECT xtfs.transfer_fare_sum_id    -- 振替運賃情報サマリーID
        INTO   ln_trn_fare_sum_id
        FROM   xxwip_transfer_fare_sum xtfs -- 振替運賃情報サマリーアドオン
        WHERE  xtfs.target_date        = gt_order_summary_tbl(ln_index).target_date
        AND    xtfs.request_no         = gt_order_summary_tbl(ln_index).request_no
        AND    xtfs.goods_classe       = gt_order_summary_tbl(ln_index).goods_classe
        AND    xtfs.jurisdicyional_hub = gt_order_summary_tbl(ln_index).jurisdicyional_hub
        FOR UPDATE NOWAIT;
--
        -- 存在する場合は存在チェック用フラグを「1」に設定
        ln_flg := 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
          -- データが存在しない場合は存在チェック用フラグに「0」を設定
          ln_flg := 0;
        WHEN lock_expt THEN   -- *** ロック取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                gv_tkn_table,   gv_trans_fare_sum_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- 対象データが存在しない場合は振替運賃情報サマリーアドオン登録用PL/SQL表に格納
      IF (ln_flg = 0) THEN
        -- 登録用PL/SQL表 件数カウント
        gn_ins_order_sum_cnt := gn_ins_order_sum_cnt + 1;
--
        -- ************************************************
        -- * 振替運賃情報サマリーデータ 登録用PL/SQL表 設定
        -- ************************************************
        -- 1.振替運賃情報サマリーID 採番
        SELECT xxwip_transfer_fare_sum_id_s1.NEXTVAL
        INTO   i_trn_fare_sum_id_tab(gn_ins_order_sum_cnt)
        FROM   dual;
--
        -- 2.対象年月
        i_trn_fare_sum_target_date_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).target_date;
        -- 3.依頼No
        i_trn_fare_sum_request_no_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).request_no;
        -- 4.商品区分
        i_trn_fare_sum_goods_clas_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).goods_classe;
        -- 5.管轄拠点
        i_trn_fare_sum_juris_hub_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).jurisdicyional_hub;
        -- 6.振替数量
        i_trn_fare_sum_actual_qty_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).summary_qry;
        -- 7.リーフ振替金額
        i_trn_fare_sum_leaf_amount_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).leaf_chg_amount;
        -- 8.ドリンク振替金額
        i_trn_fare_sum_drk_amount_tab(gn_ins_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).drink_chg_amount;
--
      -- 対象データが存在する場合は振替運賃情報サマリーアドオン更新用PL/SQL表に格納
      ELSIF (ln_flg = 1) THEN
--
        -- 更新用PL/SQL表 件数カウント
        gn_upd_order_sum_cnt := gn_upd_order_sum_cnt + 1;
--
        -- ************************************************
        -- * 振替運賃情報サマリーデータ 更新用PL/SQL表 設定
        -- ************************************************
        -- 1.振替運賃情報サマリーID
        u_trn_fare_sum_id_tab(gn_upd_order_sum_cnt) := ln_trn_fare_sum_id;
        -- 2.対象年月
        u_trn_fare_sum_target_date_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).target_date;
        -- 3.依頼No
        u_trn_fare_sum_request_no_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).request_no;
        -- 4.商品区分
        u_trn_fare_sum_goods_clas_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).goods_classe;
        -- 5.管轄拠点
        u_trn_fare_sum_juris_hub_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).jurisdicyional_hub;
        -- 6.振替数量
        u_trn_fare_sum_actual_qty_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).summary_qry;
        -- 7.リーフ振替金額
        u_trn_fare_sum_leaf_amount_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).leaf_chg_amount;
        -- 8.ドリンク振替金額
        u_trn_fare_sum_drk_amount_tab(gn_upd_order_sum_cnt) :=
          gt_order_summary_tbl(ln_index).drink_chg_amount;
--
      END IF;
--
    END LOOP gt_order_summary_tbl_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_trn_sum;
--
  /**********************************************************************************
   * Procedure Name   : ins_trn_sum_proc
   * Description      : 振替運賃情報サマリーアドオン一括登録処理(C-9)
   ***********************************************************************************/
  PROCEDURE ins_trn_sum_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_trn_sum_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***********************************
    -- * 振替運賃情報サマリーアドオン 登録
    -- ***********************************
    FORALL ln_index IN i_trn_fare_sum_id_tab.FIRST .. i_trn_fare_sum_id_tab.LAST
      INSERT INTO xxwip_transfer_fare_sum        -- 振替運賃情報サマリーアドオン
      (transfer_fare_sum_id                      -- 1.振替運賃情報サマリーID
      ,target_date                               -- 2.対象年月
      ,request_no                                -- 3.依頼No
      ,goods_classe                              -- 4.商品区分
      ,jurisdicyional_hub                        -- 5.管轄拠点
      ,actual_qty                                -- 6.振替数量
      ,leaf_amount                               -- 7.リーフ振替金額
      ,drink_amount                              -- 8.ドリンク振替金額
      ,created_by                                -- 9.作成者
      ,creation_date                             -- 10.作成日
      ,last_updated_by                           -- 11.最終更新者
      ,last_update_date                          -- 12.最終更新日
      ,last_update_login                         -- 13.最終更新ログイン
      ,request_id                                -- 14.要求ID
      ,program_application_id                    -- 15.コンカレント・プログラム・アプリケーションID
      ,program_id                                -- 16.コンカレント・プログラムID
      ,program_update_date)                      -- 17.プログラム更新日
      VALUES
      (i_trn_fare_sum_id_tab(ln_index)           -- 1.振替運賃情報サマリーID
      ,i_trn_fare_sum_target_date_tab(ln_index)  -- 2.対象年月
      ,i_trn_fare_sum_request_no_tab(ln_index)   -- 3.依頼No
      ,i_trn_fare_sum_goods_clas_tab(ln_index)   -- 4.商品区分
      ,i_trn_fare_sum_juris_hub_tab(ln_index)    -- 5.管轄拠点
      ,i_trn_fare_sum_actual_qty_tab(ln_index)   -- 6.振替数量
      ,i_trn_fare_sum_leaf_amount_tab(ln_index)  -- 7.リーフ振替金額
      ,i_trn_fare_sum_drk_amount_tab(ln_index)   -- 8.ドリンク振替金額
      ,gn_user_id                                -- 9.作成者
      ,gd_sysdate                                -- 10.作成日
      ,gn_user_id                                -- 11.最終更新者
      ,gd_sysdate                                -- 12.最終更新日
      ,gn_login_id                               -- 13.最終更新ログイン
      ,gn_conc_request_id                        -- 14.要求ID
      ,gn_prog_appl_id                           -- 15.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
      ,gn_conc_program_id                        -- 16.コンカレント・プログラムID
      ,gd_sysdate);                              -- 17.プログラム更新日
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_trn_sum_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_trn_sum_proc
   * Description      : 振替運賃情報サマリーアドオン一括更新処理(C-10)
   ***********************************************************************************/
  PROCEDURE upd_trn_sum_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_trn_sum_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***********************************
    -- * 振替運賃情報サマリーアドオン 更新
    -- ***********************************
    FORALL ln_index IN u_trn_fare_sum_target_date_tab.FIRST .. u_trn_fare_sum_target_date_tab.LAST
      UPDATE xxwip_transfer_fare_sum xtfs   -- 振替運賃情報サマリーアドオン
      SET    xtfs.actual_qty        = u_trn_fare_sum_actual_qty_tab(ln_index)  -- 振替数量
            ,xtfs.leaf_amount       = u_trn_fare_sum_leaf_amount_tab(ln_index) -- リーフ振替金額
            ,xtfs.drink_amount      = u_trn_fare_sum_drk_amount_tab(ln_index)  -- ドリンク振替金額
            ,xtfs.last_updated_by        = gn_user_id               -- 最終更新者
            ,xtfs.last_update_date       = gd_sysdate               -- 最終更新日
            ,xtfs.last_update_login      = gn_login_id              -- 最終更新ログイン
            ,xtfs.request_id             = gn_conc_request_id       -- 要求ID
            ,xtfs.program_application_id = gn_prog_appl_id          -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            ,xtfs.program_id             = gn_conc_program_id       -- コンカレント・プログラムID
            ,xtfs.program_update_date    = gd_sysdate               -- プログラム更新日
      WHERE  xtfs.transfer_fare_sum_id   = u_trn_fare_sum_id_tab(ln_index);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_trn_sum_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_trn_sum_proc
   * Description      : 振替運賃情報サマリーアドオン抽出処理(C-11)
   ***********************************************************************************/
  PROCEDURE get_trn_sum_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trn_sum_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データの取得
    SELECT xtfs.target_date,            -- 1.対象年月
           xtfs.goods_classe,           -- 2.商品区分
           xtfs.jurisdicyional_hub,     -- 3.管轄拠点
           SUM(xtfs.actual_qty),        -- 4.振替数量
           CASE                         -- 5.振替金額
             WHEN (xtfs.goods_classe = gv_prod_class_lef) THEN
               SUM(xtfs.leaf_amount)
             WHEN (xtfs.goods_classe = gv_prod_class_drk) THEN
               SUM(xtfs.drink_amount)
             ELSE 0
           END AS transfer_amount,
           NULL,                        -- 6.営業ブロック(ここではNULL)
           NULL                         -- 7,地区名(ここではNULL)
    BULK COLLECT INTO gt_trans_inf_tbl
    FROM   xxwip_transfer_fare_sum xtfs -- 振替運賃情報サマリーアドオン
    WHERE  (((gv_closed_day = gv_ktg_no) -- 前月運賃締日後の場合
             AND (xtfs.target_date = TO_CHAR(gd_sysdate, 'YYYYMM')))
           OR ((gv_closed_day = gv_ktg_yes)  -- 前月運賃締日前の場合
-- 2009/12/10 v1.19 T.Yoshimoto Mod Start 内部気づき
--             AND (xtfs.target_date = TO_CHAR(gd_sysdate, 'YYYYMM'))
--             OR  (xtfs.target_date = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM'))))
--
             AND ((xtfs.target_date = TO_CHAR(gd_sysdate, 'YYYYMM'))
             OR  (xtfs.target_date = TO_CHAR(ADD_MONTHS(gd_sysdate, -1), 'YYYYMM')))))
-- 2009/12/10 v1.19 T.Yoshimoto Mod End 内部気づき
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    AND   xtfs.goods_classe = gv_prod_div   -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
    GROUP BY xtfs.target_date,
             xtfs.goods_classe,
             xtfs.jurisdicyional_hub;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_trn_sum_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_trn_inf
   * Description      : 振替情報アドオンデータ設定(C-12)
   ***********************************************************************************/
  PROCEDURE set_trn_inf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_trn_inf'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_flg        NUMBER;   -- 存在チェック用フラグ 「0:無し、1:有り」
    ln_trn_inf_id NUMBER;   -- ID格納用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 start *----------*
    IF (gt_trans_inf_tbl.COUNT = 0) THEN
      RETURN;
    END IF;
-- *----------* 2009/06/03 Ver.1.18 本番#1505対応 end   *----------*
--
    -- 取得した対象データのマスタデータを取得する
    <<gt_trans_inf_tbl_loop>>
    FOR ln_index IN gt_trans_inf_tbl.FIRST .. gt_trans_inf_tbl.LAST LOOP
--
      BEGIN
        SELECT CASE                         -- 営業ブロック
                 WHEN (gt_trans_inf_tbl(ln_index).target_date || '01' <
-- *----------* 2009/04/06 Ver.1.17 年度切替対応 start *----------*
--                   TO_CHAR(xpv.start_date_active, 'YYYYMMDD'))
                   TO_CHAR(TO_DATE(xpv.division_start_date, 'YYYY/MM/DD'), 'YYYYMMDD'))
-- *----------* 2009/04/06 Ver.1.17 年度切替対応 end   *----------*
                 THEN
                   SUBSTR(xpv.old_division_code, 0, 4) -- 旧・本部コードの頭文字4桁
                 WHEN (gt_trans_inf_tbl(ln_index).target_date || '01' >=
-- *----------* 2009/04/06 Ver.1.17 年度切替対応 start *----------*
--                   TO_CHAR(xpv.start_date_active, 'YYYYMMDDD'))
                   TO_CHAR(TO_DATE(xpv.division_start_date, 'YYYY/MM/DD'), 'YYYYMMDD'))
-- *----------* 2009/04/06 Ver.1.17 年度切替対応 end   *----------*
                 THEN
                   SUBSTR(xpv.new_division_code, 0, 4) -- 新・本部コードの頭文字4桁
                 ELSE '0'
--2008/09/22 Mod ↓
/*
               END AS business_block,
               xpv.block_name               -- 地区名
        INTO   gt_trans_inf_tbl(ln_index).business_block,
               gt_trans_inf_tbl(ln_index).area_name
*/
               END AS business_block
        INTO   gt_trans_inf_tbl(ln_index).business_block
--2008/09/22 Mod ↑
-- ##### 20080903 Ver.1.5 内部変更要求201_203 start #####
--        FROM   xxcmn_parties2_v xpv         -- パーティ情報VIEW2
        FROM   xxcmn_cust_accounts2_v xpv         -- 顧客情報VIEW2
-- ##### 20080903 Ver.1.5 内部変更要求201_203 end   #####
        WHERE  xpv.party_number = gt_trans_inf_tbl(ln_index).jurisdicyional_hub
        AND    FND_DATE.STRING_TO_DATE(gt_trans_inf_tbl(ln_index).target_date || '01', 'YYYYMMDD')
-- ********** 20080508 内部変更要求 seq#75 MOD START **********
/***
                 BETWEEN xpv.start_date_active AND xpv.end_date_active
        AND    xpv.transfer_standard = '1'; -- 「1:設定振替」
***/
                 BETWEEN xpv.start_date_active AND xpv.end_date_active;
-- ********** 20080508 内部変更要求 seq#75 MOD END   **********
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_001,
                                                gv_tkn_table,   gv_party_view_name,
                                                gv_tkn_key,     gv_jurisdicyional_hub_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--2008/09/22 Add ↓
      -- 地区名の取得
      BEGIN
        SELECT xlvv.meaning
        INTO   gt_trans_inf_tbl(ln_index).area_name
        FROM   xxcmn_lookup_values2_v xlvv
        WHERE  xlvv.lookup_type = 'XXCMN_AREA'
        AND    xlvv.lookup_code = gt_trans_inf_tbl(ln_index).business_block
        AND ( xlvv.start_date_active <= 
              FND_DATE.STRING_TO_DATE(gt_trans_inf_tbl(ln_index).target_date || '01', 'YYYYMMDD')
         OR xlvv.start_date_active IS NULL )
        AND ( xlvv.end_date_active >= 
              FND_DATE.STRING_TO_DATE(gt_trans_inf_tbl(ln_index).target_date || '01', 'YYYYMMDD')
         OR xlvv.end_date_active IS NULL )
        AND xlvv.enabled_flag = gv_ktg_yes;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
          gt_trans_inf_tbl(ln_index).area_name := NULL;
      END;
--2008/09/22 Add ↑
--
      -- 抽出したデータを元に振替情報アドオンの存在チェックを行い、存在する場合はロックを行う
      BEGIN
        SELECT xti.transfer_inf_id        -- 振替情報ID
        INTO   ln_trn_inf_id
        FROM   xxwip_transfer_inf xti     -- 振替情報アドオン
        WHERE  xti.target_date        = gt_trans_inf_tbl(ln_index).target_date
        AND    xti.goods_classe       = gt_trans_inf_tbl(ln_index).goods_classe
        AND    xti.jurisdicyional_hub = gt_trans_inf_tbl(ln_index).jurisdicyional_hub
        FOR UPDATE NOWAIT;
--
        -- 存在する場合は存在チェック用フラグを「1」に設定
        ln_flg := 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
          -- データが存在しない場合は存在チェック用フラグに「0」を設定
          ln_flg := 0;
        WHEN lock_expt THEN   -- *** ロック取得エラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_004,
                                                gv_tkn_table,   gv_trans_inf_name);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      -- 対象データが存在しない場合は振替情報アドオン登録用PL/SQL表に格納
      IF (ln_flg = 0) THEN
        -- 登録用PL/SQL表 件数カウント
        gn_ins_trans_inf_cnt := gn_ins_trans_inf_cnt + 1;
--
        -- ************************************************
        -- * 振替情報データ 登録用PL/SQL表 設定
        -- ************************************************
        -- 1.振替情報ID
        SELECT xxwip_transfer_inf_id_s1.NEXTVAL
        INTO   i_trn_inf_id_tab(gn_ins_trans_inf_cnt)
        FROM   dual;
--
        -- 2.対象年月
        i_trn_inf_target_date_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).target_date;
        -- 3.営業ブロック
        i_trn_inf_business_block_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).business_block;
        -- 4.商品区分
        i_trn_inf_goods_classe_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).goods_classe;
        -- 5.管轄拠点
        i_trn_inf_juris_hub_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).jurisdicyional_hub;
        -- 6.地区名
        i_trn_inf_area_name_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).area_name;
        -- 7.振替数量
        i_trn_inf_transfe_qty_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).summary_qry;
        -- 8.振替金額
        i_trn_inf_transfer_amount_tab(gn_ins_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).trans_amount;
--
      -- 対象データが存在する場合は振替情報アドオン更新用PL/SQL表に格納
      ELSIF (ln_flg = 1) THEN
--
        -- 更新用PL/SQL表 件数カウント
        gn_upd_trans_inf_cnt := gn_upd_trans_inf_cnt + 1;
--
        -- ************************************************
        -- * 振替情報データ 更新用PL/SQL表 設定
        -- ************************************************
        -- 1.振替情報ID
        u_trn_inf_id_tab(gn_upd_trans_inf_cnt) := ln_trn_inf_id;
        -- 2.対象年月
        u_trn_inf_target_date_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).target_date;
        -- 3.営業ブロック
        u_trn_inf_business_block_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).business_block;
        -- 4.商品区分
        u_trn_inf_goods_classe_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).goods_classe;
        -- 5.管轄拠点
        u_trn_inf_juris_hub_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).jurisdicyional_hub;
        -- 6.地区名
        u_trn_inf_area_name_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).area_name;
        -- 7.振替数量
        u_trn_inf_transfe_qty_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).summary_qry;
        -- 8.振替金額
        u_trn_inf_transfer_amount_tab(gn_upd_trans_inf_cnt) :=
          gt_trans_inf_tbl(ln_index).trans_amount;
--
      END IF;
    END LOOP gt_trans_inf_tbl_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_trn_inf;
--
  /**********************************************************************************
   * Procedure Name   : ins_trn_inf_proc
   * Description      : 振替情報アドオン一括登録処理(C-13)
   ***********************************************************************************/
  PROCEDURE ins_trn_inf_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_trn_inf_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***********************
    -- * 振替情報アドオン 登録
    -- ***********************
    FORALL ln_index IN i_trn_inf_id_tab.FIRST .. i_trn_inf_id_tab.LAST
      INSERT INTO xxwip_transfer_inf              -- 振替情報アドオン
      (transfer_inf_id                            -- 1.振替情報ID
      ,target_date                                -- 2.対象年月
      ,business_block                             -- 3.営業ブロック
      ,goods_classe                               -- 4.商品区分
      ,jurisdicyional_hub                         -- 5.管轄拠点
      ,area_name                                  -- 6.地区名
      ,transfe_qty                                -- 7.振替数量
      ,transfer_amount                            -- 8.振替金額
      ,restore_amount                             -- 9.還元金額
      ,shipping_expenses_a                        -- 10.運送費A
      ,shipping_expenses_b                        -- 11.運送費B
      ,shipping_expenses_c                        -- 12.運消費C
      ,etc_amount                                 -- 13.その他
      ,created_by                                 -- 14.作成者
      ,creation_date                              -- 15.作成日
      ,last_updated_by                            -- 16.最終更新者
      ,last_update_date                           -- 17.最終更新日
      ,last_update_login                          -- 18.最終更新ログイン
      ,request_id                                 -- 19.要求ID
      ,program_application_id                     -- 20.20.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
      ,program_id                                 -- 21.コンカレント・プログラムID
      ,program_update_date)                       -- 22.プログラム更新日
      VALUES
      (i_trn_inf_id_tab(ln_index)                 -- 1.振替情報ID
      ,i_trn_inf_target_date_tab(ln_index)        -- 2.対象年月
      ,i_trn_inf_business_block_tab(ln_index)     -- 3.営業ブロック
      ,i_trn_inf_goods_classe_tab(ln_index)       -- 4.商品区分
      ,i_trn_inf_juris_hub_tab(ln_index)          -- 5.管轄拠点
      ,i_trn_inf_area_name_tab(ln_index)          -- 6.地区名
      ,i_trn_inf_transfe_qty_tab(ln_index)        -- 7.振替数量
      ,i_trn_inf_transfer_amount_tab(ln_index)    -- 8.振替金額
      ,0                                          -- 9.還元金額
      ,0                                          -- 10.運送費A
      ,0                                          -- 11.運送費B
      ,0                                          -- 12.運消費C
      ,0                                          -- 13.その他
      ,gn_user_id                                 -- 14.作成者
      ,gd_sysdate                                 -- 15.作成日
      ,gn_user_id                                 -- 16.最終更新者
      ,gd_sysdate                                 -- 17.最終更新日
      ,gn_login_id                                -- 18.最終更新ログイン
      ,gn_conc_request_id                         -- 19.要求ID
      ,gn_prog_appl_id                            -- 20.ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
      ,gn_conc_program_id                         -- 21.コンカレント・プログラムID
      ,gd_sysdate);                               -- 22.プログラム更新日
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_trn_inf_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_trn_inf_proc
   * Description      : 振替情報アドオン一括更新処理(C-14)
   ***********************************************************************************/
  PROCEDURE upd_trn_inf_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_trn_inf_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***********************
    -- * 振替情報アドオン 更新
    -- ***********************
    FORALL ln_index IN u_trn_inf_target_date_tab.FIRST .. u_trn_inf_target_date_tab.LAST
      UPDATE xxwip_transfer_inf xti      -- 振替情報アドオン
      SET    xti.business_block          = u_trn_inf_business_block_tab(ln_index)  -- 営業ブロック
            ,xti.area_name               = u_trn_inf_area_name_tab(ln_index)       -- 地区名
            ,xti.transfe_qty             = u_trn_inf_transfe_qty_tab(ln_index)     -- 振替数量
            ,xti.transfer_amount         = u_trn_inf_transfer_amount_tab(ln_index) -- 振替金額
            ,xti.last_updated_by        = gn_user_id               -- 最終更新者
            ,xti.last_update_date       = gd_sysdate               -- 最終更新日
            ,xti.last_update_login      = gn_login_id              -- 最終更新ログイン
            ,xti.request_id             = gn_conc_request_id       -- 要求ID
            ,xti.program_application_id = gn_prog_appl_id          -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            ,xti.program_id             = gn_conc_program_id       -- コンカレント・プログラムID
            ,xti.program_update_date    = gd_sysdate               -- プログラム更新日
      WHERE  xti.transfer_inf_id        = u_trn_inf_id_tab(ln_index);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_trn_inf_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_deliv_ctrl_proc
   * Description      : 運賃計算用コントロール更新処理(C-15)
   ***********************************************************************************/
  PROCEDURE upd_deliv_ctrl_proc(
    iv_exchange_type IN         VARCHAR2,     -- 洗い替え区分
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_deliv_ctrl_proc'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入力パラメータ.洗い替え区分 = 「NO」の場合
    IF (iv_exchange_type = gv_ktg_no) THEN
--
      -- 運賃計算用コントロールの前回処理日付を更新
      UPDATE xxwip_deliverys_ctrl xdc   -- 運賃計算用コントロールアドオン
      SET    xdc.last_process_date      = gd_sysdate         -- 前回処理日付
            ,xdc.last_updated_by        = gn_user_id         -- 最終更新者
            ,xdc.last_update_date       = gd_sysdate         -- 最終更新日
            ,xdc.last_update_login      = gn_login_id        -- 最終更新ログイン
            ,xdc.request_id             = gn_conc_request_id -- 要求ID
            ,xdc.program_application_id = gn_prog_appl_id    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑ・ｱﾌﾟﾘｹｰｼｮﾝID
            ,xdc.program_id             = gn_conc_program_id -- コンカレント・プログラムID
            ,xdc.program_update_date    = gd_sysdate         -- プログラム更新日
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
--      WHERE  xdc.concurrent_no          = gv_con_no_deli;
      WHERE  xdc.concurrent_no          = gv_concurrent_no;   -- コンカレントNO
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_deliv_ctrl_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exchange_type  IN         VARCHAR2,     -- 洗い替え区分
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    iv_prod_div       IN         VARCHAR2,     -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message    VARCHAR2(5000);  -- メッセージ出力
    lv_target_flg VARCHAR2(1);     -- 対象データ有無フラグ 0:無し、1:有り
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =========================================
    -- パラメータチェック処理(C-1)
    -- =========================================
    chk_param_proc(
      iv_exchange_type,  -- 洗い替え区分
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
      iv_prod_div,       -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 関連データ取得(C-2)
    -- =========================================
    get_init(
      iv_exchange_type,  -- 洗い替え区分
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 受注データ抽出処理(C-3)
    -- =========================================
    get_order_proc(
      iv_exchange_type,  -- 洗い替え区分
      lv_target_flg,     -- 対象データ有無フラグ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 抽出データが1件以上存在する場合は以下の処理を行う
    IF (lv_target_flg = '1') THEN
--
      -- =========================================
      -- 振替運賃情報アドオンデータ設定(C-4)
      -- =========================================
      set_trn(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替運賃情報アドオン一括登録処理(C-5)
      -- =========================================
      ins_trn_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替運賃情報アドオン一括更新処理(C-6)
      -- =========================================
      upd_trn_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 振替運賃情報アドオン件数設定
      gn_order_inf_cnt := gn_ins_order_inf_cnt + gn_upd_order_inf_cnt;
--
      -- =========================================
      -- 振替運賃情報アドオン抽出処理(C-7)
      -- =========================================
      get_trn_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替運賃情報サマリーアドオンデータ設定(C-8)
      -- =========================================
      set_trn_sum(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替運賃情報サマリーアドオン一括登録処理(C-9)
      -- =========================================
      ins_trn_sum_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替運賃情報サマリーアドオン一括更新処理(C-10)
      -- =========================================
      upd_trn_sum_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 振替運賃情報サマリーアドオン件数設定
      gn_order_sum_cnt := gn_ins_order_sum_cnt + gn_upd_order_sum_cnt;
--
      -- =========================================
      -- 振替運賃情報サマリーアドオン抽出処理(C-11)
      -- =========================================
      get_trn_sum_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替情報アドオンデータ設定(C-12)
      -- =========================================
      set_trn_inf(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替情報アドオン一括登録処理(C-13)
      -- =========================================
      ins_trn_inf_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- 振替情報アドオン一括更新処理(C-14)
      -- =========================================
      upd_trn_inf_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 振替情報アドオン件数設定
      gn_trans_inf_cnt := gn_ins_trans_inf_cnt + gn_upd_trans_inf_cnt;
--
      -- =========================================
      -- 運賃計算用コントロール更新処理(C-15)
      -- =========================================
      upd_deliv_ctrl_proc(
        iv_exchange_type,  -- 洗い替え区分
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode           OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_exchange_type  IN         VARCHAR2,      --   洗替区分
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    iv_prod_div       IN         VARCHAR2       --   商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    lv_message VARCHAR2(5000);  -- ユーザー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_exchange_type,  -- 洗い替え区分
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
      iv_prod_div,       -- 商品区分
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--2008/09/22 Add ↓
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --区切り文字列出力
    -------------------------------------------------------
    -- 入力パラメータ
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '入力パラメータ' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '洗替区分：' || iv_exchange_type ) ;
-- ##### 20081017 Ver.1.8 T_S_465対応 start #####
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '商品区分：' || iv_prod_div ) ;
-- ##### 20081017 Ver.1.8 T_S_465対応 end   #####
--2008/09/22 Add ↑
--
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =========================================
    -- メッセージ出力(C-16)
    -- =========================================
    -- 1.振替運賃情報アドオン処理件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_005);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 2.成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_order_inf_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 3.振替運賃情報サマリーアドオン処理件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_008);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 4.成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_order_sum_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 5.振替情報アドオン処理件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn, gv_wip_msg_75c_006);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 6.成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn, gv_cmn_msg_75c_009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_trans_inf_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
END xxwip750001c;
/
