CREATE OR REPLACE PACKAGE BODY xxwip730002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730002C(BODY)
 * Description      : 運賃更新
 * MD.050           : 運賃計算（トランザクション） T_MD050_BPO_733
 * MD.070           : 運賃更新 T_MD070_BPO_73D
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cal_money_proc         金額計算処理(機能詳細番号無し)
 *  cal_money_proc         金額計算処理(洗替用)(機能詳細番号無し)
 *  chk_param_proc         パラメータチェック処理(D-1)
 *  get_init               関連データ取得(D-2)
 *  chk_close_proc         運賃用締日情報取得(D-3)
 *  get_lock_xd            ロック取得(D-4)
 *
 *  get_xd_data            運賃ヘッダアドオン抽出(D-5)
 *  get_xdc_data           運賃アドオンマスタ抽出(D-6)
 *  set_xd_data            運賃ヘッダアドオンPL/SQL表格納(D-7)
 *
 *  ins_xd_proc            運賃ヘッダアドオン一括登録処理(D-8)
 *  upd_xd_proc            運賃ヘッダアドオン一括更新処理(D-9)
 *  upd_calc_ctrl_proc     運賃計算用コントロール更新処理(D-10)
 *
 *  get_xd_exchange_data   洗替運賃ヘッダアドオン抽出(D-11)
 *  get_xdc_exchange_data  洗替運賃アドオンマスタ抽出(D-12)
 *  set_xd_exchange_data   洗替運賃ヘッダアドオンPL/SQL表格納(D-13)
 *
 *  upd_xd_exchange_proc   洗替運賃ヘッダアドオン一括更新処理(D-14)
 *
 *  upd_xdc_mst_proc       運賃マスタ・運賃用運送業者マスタ更新処理(D-15)
 *
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/03    1.0  Oracle 小松 淳    初版作成
 *  2008/07/11    1.1  Oracle 山根 一浩  変更要求＃96、＃98対応
 *  2008/07/23    1.2  Oracle 野村 正幸  内部変更#132対応
 *  2008/09/16    1.3  Oracle 吉田 夏樹  T_S_570 対応
 *  2008/10/24    1.4  Oracle 野村 正幸  統合#408対応
 *  2009/04/10    1.5  SCS    伊藤ひとみ 本番#432対応
 *  2009/05/01    1.6  SCS    伊藤ひとみ 本番#432(指摘5)対応
 *  2016/06/22    1.7  SCSK   仁木重人   E_本稼動_13659対応
 *
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
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name                CONSTANT VARCHAR2(100) := 'xxwip730002c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_msg_kbn_cmn             CONSTANT VARCHAR2(5) := 'XXCMN';
  gv_msg_kbn_wip             CONSTANT VARCHAR2(5) := 'XXWIP';
--
  -- メッセージ番号(XXCMN)
  gv_msg_cmn_00009           CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; -- 成功件数
  gv_msg_cmn_10001           CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- 対象データなし
  gv_msg_cmn_10010           CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- パラメータエラー
--
  -- メッセージ番号(XXWIP)
  gv_msg_wip_00010           CONSTANT VARCHAR2(15) := 'APP-XXWIP-00010'; -- 運賃ﾍｯﾀﾞｱﾄﾞｵﾝ処理件数
  gv_msg_wip_10008           CONSTANT VARCHAR2(15) := 'APP-XXWIP-10008'; -- 必須項目未入力エラー
  gv_msg_wip_10004           CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ロック詳細メッセージ
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
  gv_msg_wip_10067           CONSTANT VARCHAR2(15) := 'APP-XXWIP-10067'; -- プロファイル取得エラー
  gv_msg_wip_10090           CONSTANT VARCHAR2(15) := 'APP-XXWIP-10090'; -- 文言：商品区分（セキュリティ）
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
--
  -- トークン
  gv_tkn_item                CONSTANT VARCHAR2(10) := 'ITEM';
  gv_tkn_parameter           CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_tkn_value               CONSTANT VARCHAR2(10) := 'VALUE';
  gv_tkn_table               CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key                 CONSTANT VARCHAR2(10) := 'KEY';
  gv_tkn_cnt                 CONSTANT VARCHAR2(10) := 'CNT';
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
  gv_tkn_ng_profile          CONSTANT VARCHAR2(10) := 'NG_PROFILE';
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
--
  -- トークン値
  gv_exchange_type_name      CONSTANT VARCHAR2(30) := '洗替区分';
  gv_deli_ctrl_name          CONSTANT VARCHAR2(30) := '運賃計算用コントロール';
  gv_deli_name               CONSTANT VARCHAR2(30) := '運賃ヘッダアドオン';
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
  gv_deli_comp_name          CONSTANT VARCHAR2(50) := '運賃用運送業者アドオンマスタ';
  gv_deli_charges_name       CONSTANT VARCHAR2(50) := '運賃アドオンマスタ';
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
--
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
  -- プロファイル
  gv_prof_item_div_sec       CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV_SECURITY';  -- プロファイル：商品区分（セキュリティ）
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
--
  -- YESNO区分
  gv_ktg_yes                 CONSTANT VARCHAR2(1) := 'Y';
  gv_ktg_no                  CONSTANT VARCHAR2(1) := 'N';
  -- 支払請求区分
  gv_paycharge_type_1        CONSTANT VARCHAR2(1) := '1';   -- 1:支払運賃
  gv_paycharge_type_2        CONSTANT VARCHAR2(1) := '2';   -- 2:請求運賃
  -- 支払確定区分
  gv_defined_yes             CONSTANT VARCHAR2(1) := 'Y';   -- 支払確定区分｢YES｣
  gv_defined_no              CONSTANT VARCHAR2(1) := 'N';   -- 支払確定区分｢NO｣
  -- 混載区分
  gv_mixed_code_1            CONSTANT VARCHAR2(1) := '1';   -- 1:混載
  gv_mixed_code_2            CONSTANT VARCHAR2(1) := '2';   -- 2:混載以外
  -- コンカレントNo(運賃計算用コントロール)
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
--  gv_con_no_deli             CONSTANT VARCHAR2(1) := '2';   -- 2:運賃更新
  gv_con_no_deli_lef         CONSTANT VARCHAR2(1) := '5';   -- 5:請求更新(リーフ)
  gv_con_no_deli_drk         CONSTANT VARCHAR2(1) := '6';   -- 6:請求更新(ドリンク)
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
  -- 商品区分
  gv_prod_class_lef          CONSTANT VARCHAR2(1) := '1';   -- 1:リーフ
  gv_prod_class_drk          CONSTANT VARCHAR2(1) := '2';   -- 2:ドリンク
  -- 配車タイプ(2008/07/11)
  gv_dispatch_type_1         CONSTANT VARCHAR2(1) := '1';   -- 1:通常配車
  gv_dispatch_type_2         CONSTANT VARCHAR2(1) := '2';   -- 2:伝票なし配車(リーフ小口)
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
  -- 変更フラグ
  gv_change_flg_on           CONSTANT VARCHAR2(1) := '1';   -- 1:変更あり
  gv_change_flg_off          CONSTANT VARCHAR2(1) := '0';   -- 2:変更なし
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 運賃ヘッダアドオン抽出用レコード型
  TYPE rec_extraction_xd IS RECORD(
    delivery_company_code    xxwip_deliverys.delivery_company_code%TYPE,    -- 運送業者
    delivery_no              xxwip_deliverys.delivery_no%TYPE,              -- 配送No
    invoice_no               xxwip_deliverys.invoice_no%TYPE,               -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
    invoice_no2              xxwip_deliverys.invoice_no2%TYPE,              -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
    payments_judgment_classe xxwip_deliverys.payments_judgment_classe%TYPE, -- 支払判断区分
    ship_date                xxwip_deliverys.ship_date%TYPE,                -- 出庫日
    arrival_date             xxwip_deliverys.arrival_date%TYPE,             -- 到着日
    report_date              xxwip_deliverys.report_date%TYPE,              -- 報告日
    judgement_date           xxwip_deliverys.judgement_date%TYPE,           -- 判断日
    goods_classe             xxwip_deliverys.goods_classe%TYPE,             -- 商品区分
    mixed_code               xxwip_deliverys.mixed_code%TYPE,               -- 混載区分
    many_rate                xxwip_deliverys.many_rate%TYPE,                -- 諸料金
    distance                 xxwip_deliverys.distance%TYPE,                 -- 最長距離
    delivery_classe          xxwip_deliverys.delivery_classe%TYPE,          -- 配送区分
    whs_code                 xxwip_deliverys.whs_code%TYPE,                 -- 代表出庫倉庫コード
    code_division            xxwip_deliverys.code_division%TYPE,            -- 代表配送先コード区分
    shipping_address_code    xxwip_deliverys.shipping_address_code%TYPE,    -- 代表配送先コード
    qty1                     xxwip_deliverys.qty1%TYPE,                     -- 個数１
    qty2                     xxwip_deliverys.qty2%TYPE,                     -- 個数２
    delivery_weight1         xxwip_deliverys.delivery_weight1%TYPE,         -- 重量１
    delivery_weight2         xxwip_deliverys.delivery_weight2%TYPE,         -- 重量２
    actual_distance          xxwip_deliverys.actual_distance%TYPE,          -- 最長実際距離
    congestion_charge        xxwip_deliverys.congestion_charge%TYPE,        -- 通行料
    consolid_qty             xxwip_deliverys.consolid_qty%TYPE,             -- 混載数
    order_type               xxwip_deliverys.order_type%TYPE,               -- 代表タイプ
    weight_capacity_class    xxwip_deliverys.weight_capacity_class%TYPE,    -- 重量容積区分
    outside_contract         xxwip_deliverys.outside_contract%TYPE,         -- 契約外区分
    transfer_location        xxwip_deliverys.transfer_location%TYPE,        -- 振替先
    description              xxwip_deliverys.description%TYPE,              -- 運賃摘要
    dispatch_type            xxwip_deliverys.dispatch_type%TYPE,            -- 配車タイプ(2008/07/11)
    bill_picking_amount      xxwip_delivery_company.bill_picking_amount%TYPE-- 請求ピッキング単価
  );
--
  -- 運賃ヘッダアドオン抽出データを格納するテーブル
  TYPE tbl_extraction_xd IS TABLE OF rec_extraction_xd INDEX BY PLS_INTEGER;
  gt_extraction_xd   tbl_extraction_xd;
--
  -- 運賃アドオンマスタ抽出データを格納するレコード変数
  gr_extraction_xdc  xxwip_common3_pkg.delivery_charges_rec;
--
  -- 洗替運賃ヘッダアドオン抽出用レコード型
  TYPE rec_extraction_ex_xd IS RECORD(
    delivery_company_code    xxwip_deliverys.delivery_company_code%TYPE,    -- 運送業者
    delivery_no              xxwip_deliverys.delivery_no%TYPE,              -- 配送No
    judgement_date           xxwip_deliverys.judgement_date%TYPE,           -- 判断日
    goods_classe             xxwip_deliverys.goods_classe%TYPE,             -- 商品区分
    mixed_code               xxwip_deliverys.mixed_code%TYPE,               -- 混載区分
    charged_amount           xxwip_deliverys.charged_amount%TYPE,           -- 請求運賃
    many_rate                xxwip_deliverys.many_rate%TYPE,                -- 諸料金
    distance                 xxwip_deliverys.distance%TYPE,                 -- 最長距離
    delivery_classe          xxwip_deliverys.delivery_classe%TYPE,          -- 配送区分
    qty1                     xxwip_deliverys.qty1%TYPE,                     -- 個数１
    delivery_weight1         xxwip_deliverys.delivery_weight1%TYPE,         -- 重量１
    consolid_qty             xxwip_deliverys.consolid_qty%TYPE,             -- 混載数
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
    before_picking_charge     xxwip_deliverys.picking_charge%TYPE,          -- ピッキング単価(洗替前)
    before_contract_rate      xxwip_deliverys.contract_rate%TYPE,           -- 契約運賃(洗替前)
    before_consolid_surcharge xxwip_deliverys.consolid_surcharge%TYPE,      -- 混載割増金額(洗替前)
    bill_change_flg           xxwip_delivery_company.bill_change_flg%TYPE,  -- 運賃用運送業者マスタ 請求変更フラグ
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
    bill_picking_amount      xxwip_delivery_company.bill_picking_amount%TYPE-- 請求ピッキング単価
  );
--
  -- 洗替運賃ヘッダアドオン抽出データを格納するテーブル
  TYPE tbl_extraction_ex_xd IS TABLE OF rec_extraction_ex_xd INDEX BY PLS_INTEGER;
  gt_extraction_ex_xd   tbl_extraction_ex_xd;
--
  -- 洗替運賃アドオンマスタ抽出データを格納するレコード変数
  gr_extraction_ex_xdc  xxwip_common3_pkg.delivery_charges_rec;
--
  -- ====================================
  -- 運賃ヘッダアドオン登録用PL/SQL表定義
  -- ====================================
--
  -- (登録用)運賃ヘッダーアドオンID
  TYPE t_ins_deliverys_header_id IS TABLE OF xxwip_deliverys.deliverys_header_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)運送業者
  TYPE t_ins_delivery_company_code IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)配送No
  TYPE t_ins_delivery_no IS TABLE OF xxwip_deliverys.delivery_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)送り状No
  TYPE t_ins_invoice_no IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
  -- (登録用)送り状No2
  TYPE t_ins_invoice_no2 IS TABLE OF xxwip_deliverys.invoice_no2%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
  -- (登録用)支払請求区分
  TYPE t_ins_p_b_classe IS TABLE OF xxwip_deliverys.p_b_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)支払判断区分
  TYPE t_ins_payments_judgment_classe IS TABLE OF xxwip_deliverys.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)出庫日
  TYPE t_ins_ship_date IS TABLE OF xxwip_deliverys.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)到着日
  TYPE t_ins_arrival_date IS TABLE OF xxwip_deliverys.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)報告日
  TYPE t_ins_report_date IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)判断日
  TYPE t_ins_judgement_date IS TABLE OF xxwip_deliverys.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)商品区分
  TYPE t_ins_goods_classe IS TABLE OF xxwip_deliverys.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)混載区分
  TYPE t_ins_mixed_code IS TABLE OF xxwip_deliverys.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)請求運賃
  TYPE t_ins_charged_amount IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)契約運賃
  TYPE t_ins_contract_rate IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)差額
  TYPE t_ins_balance IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)合計
  TYPE t_ins_total_amount IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)諸料金
  TYPE t_ins_many_rate IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)最長距離
  TYPE t_ins_distance IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)配送区分
  TYPE t_ins_delivery_classe IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)代表出庫倉庫コード
  TYPE t_ins_whs_code IS TABLE OF xxwip_deliverys.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)代表配送先コード区分
  TYPE t_ins_code_division IS TABLE OF xxwip_deliverys.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)代表配送先コード
  TYPE t_ins_shipping_address_code IS TABLE OF xxwip_deliverys.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)個数１
  TYPE t_ins_qty1 IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)個数２
  TYPE t_ins_qty2 IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)重量１
  TYPE t_ins_delivery_weight1 IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)重量２
  TYPE t_ins_delivery_weight2 IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)混載割増金額
  TYPE t_ins_consolid_surcharge IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)最長実際距離
  TYPE t_ins_actual_distance IS TABLE OF xxwip_deliverys.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)通行料
  TYPE t_ins_congestion_charge IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)ピッキング料
  TYPE t_ins_picking_charge IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)混載数
  TYPE t_ins_consolid_qty IS TABLE OF xxwip_deliverys.consolid_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)代表タイプ
  TYPE t_ins_order_type IS TABLE OF xxwip_deliverys.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)重量容積区分
  TYPE t_ins_weight_capacity_class IS TABLE OF xxwip_deliverys.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)契約外区分
  TYPE t_ins_outside_contract IS TABLE OF xxwip_deliverys.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)差異区分
  TYPE t_ins_output_flag IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)支払確定区分
  TYPE t_ins_defined_flag IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)支払確定戻
  TYPE t_ins_return_flag IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)画面更新有無区分
  TYPE t_ins_form_update_flag IS TABLE OF xxwip_deliverys.form_update_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)振替先
  TYPE t_ins_transfer_location IS TABLE OF xxwip_deliverys.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)外部業者変更回数
  TYPE t_ins_outside_up_count IS TABLE OF xxwip_deliverys.outside_up_count%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)運賃摘要
  TYPE t_ins_description IS TABLE OF xxwip_deliverys.description%TYPE
  INDEX BY BINARY_INTEGER;
  -- (登録用)配車タイプ(2008/07/11)
  TYPE t_ins_dispatch_type IS TABLE OF xxwip_deliverys.dispatch_type%TYPE
  INDEX BY BINARY_INTEGER;
--
  tab_ins_deliverys_header_id           t_ins_deliverys_header_id;
  tab_ins_delivery_company_code         t_ins_delivery_company_code;
  tab_ins_delivery_no                   t_ins_delivery_no;
  tab_ins_invoice_no                    t_ins_invoice_no;
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
  tab_ins_invoice_no2                   t_ins_invoice_no2;
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
  tab_ins_p_b_classe                    t_ins_p_b_classe;
  tab_ins_payments_judgment_clas        t_ins_payments_judgment_classe;
  tab_ins_ship_date                     t_ins_ship_date;
  tab_ins_arrival_date                  t_ins_arrival_date;
  tab_ins_report_date                   t_ins_report_date;
  tab_ins_judgement_date                t_ins_judgement_date;
  tab_ins_goods_classe                  t_ins_goods_classe;
  tab_ins_mixed_code                    t_ins_mixed_code;
  tab_ins_charged_amount                t_ins_charged_amount;
  tab_ins_contract_rate                 t_ins_contract_rate;
  tab_ins_balance                       t_ins_balance;
  tab_ins_total_amount                  t_ins_total_amount;
  tab_ins_many_rate                     t_ins_many_rate;
  tab_ins_distance                      t_ins_distance;
  tab_ins_delivery_classe               t_ins_delivery_classe;
  tab_ins_whs_code                      t_ins_whs_code;
  tab_ins_code_division                 t_ins_code_division;
  tab_ins_shipping_address_code         t_ins_shipping_address_code;
  tab_ins_qty1                          t_ins_qty1;
  tab_ins_qty2                          t_ins_qty2;
  tab_ins_delivery_weight1              t_ins_delivery_weight1;
  tab_ins_delivery_weight2              t_ins_delivery_weight2;
  tab_ins_consolid_surcharge            t_ins_consolid_surcharge;
  tab_ins_actual_distance               t_ins_actual_distance;
  tab_ins_congestion_charge             t_ins_congestion_charge;
  tab_ins_picking_charge                t_ins_picking_charge;
  tab_ins_consolid_qty                  t_ins_consolid_qty;
  tab_ins_order_type                    t_ins_order_type;
  tab_ins_weight_capacity_class         t_ins_weight_capacity_class;
  tab_ins_outside_contract              t_ins_outside_contract;
  tab_ins_output_flag                   t_ins_output_flag;
  tab_ins_defined_flag                  t_ins_defined_flag;
  tab_ins_return_flag                   t_ins_return_flag;
  tab_ins_form_update_flag              t_ins_form_update_flag;
  tab_ins_transfer_location             t_ins_transfer_location;
  tab_ins_outside_up_count              t_ins_outside_up_count;
  tab_ins_description                   t_ins_description;
  tab_ins_dispatch_type                 t_ins_dispatch_type;              -- 2008/07/11
--
  -- 運賃ヘッダアドオン登録用PL/SQL表索引
  gn_ins_cnt    NUMBER;
--
  -- ====================================
  -- 運賃ヘッダアドオン更新用PL/SQL表定義
  -- ====================================
--
  -- (更新用)配送No
  TYPE t_upd_delivery_no IS TABLE OF xxwip_deliverys.delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- (更新用)契約運賃
  TYPE t_upd_contract_rate IS TABLE OF xxwip_deliverys.contract_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)差額
  TYPE t_upd_balance IS TABLE OF xxwip_deliverys.balance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)合計
  TYPE t_upd_total_amount IS TABLE OF xxwip_deliverys.total_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)最長距離
  TYPE t_upd_distance IS TABLE OF xxwip_deliverys.distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)配送区分
  TYPE t_upd_delivery_classe IS TABLE OF xxwip_deliverys.delivery_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)個数１
  TYPE t_upd_qty1 IS TABLE OF xxwip_deliverys.qty1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)個数２
  TYPE t_upd_qty2 IS TABLE OF xxwip_deliverys.qty2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)重量１
  TYPE t_upd_delivery_weight1 IS TABLE OF xxwip_deliverys.delivery_weight1%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)重量２
  TYPE t_upd_delivery_weight2 IS TABLE OF xxwip_deliverys.delivery_weight2%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)諸料金
  TYPE t_upd_many_rate IS TABLE OF xxwip_deliverys.many_rate%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)混載割増金額
  TYPE t_upd_consolid_surcharge IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)通行料
  TYPE t_upd_congestion_charge IS TABLE OF xxwip_deliverys.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)ピッキング料
  TYPE t_upd_picking_charge IS TABLE OF xxwip_deliverys.picking_charge%TYPE
  INDEX BY BINARY_INTEGER;
--
  tab_upd_delivery_no                   t_upd_delivery_no;
  tab_upd_contract_rate                 t_upd_contract_rate;
  tab_upd_balance                       t_upd_balance;
  tab_upd_total_amount                  t_upd_total_amount;
  tab_upd_distance                      t_upd_distance;
  tab_upd_delivery_classe               t_upd_delivery_classe;
  tab_upd_qty1                          t_upd_qty1;
  tab_upd_qty2                          t_upd_qty2;
  tab_upd_delivery_weight1              t_upd_delivery_weight1;
  tab_upd_delivery_weight2              t_upd_delivery_weight2;
  tab_upd_many_rate                     t_upd_many_rate;
  tab_upd_consolid_surcharge            t_upd_consolid_surcharge;
  tab_upd_congestion_charge             t_upd_congestion_charge;
  tab_upd_picking_charge                t_upd_picking_charge;
--
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
--       更新項目追加
--
  -- (更新用)運送業者
  TYPE t_upd_delivery_company_code IS TABLE OF xxwip_deliverys.delivery_company_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)送り状No
  TYPE t_upd_invoice_no IS TABLE OF xxwip_deliverys.invoice_no%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
  -- (更新用)送り状No2
  TYPE t_upd_invoice_no2 IS TABLE OF xxwip_deliverys.invoice_no2%TYPE
  INDEX BY BINARY_INTEGER;
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
  -- (更新用)支払判断区分
  TYPE t_upd_payments_judgment_classe IS TABLE OF xxwip_deliverys.payments_judgment_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)出庫日
  TYPE t_upd_ship_date IS TABLE OF xxwip_deliverys.ship_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)到着日
  TYPE t_upd_arrival_date IS TABLE OF xxwip_deliverys.arrival_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)報告日
  TYPE t_upd_report_date IS TABLE OF xxwip_deliverys.report_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)判断日
  TYPE t_upd_judgement_date IS TABLE OF xxwip_deliverys.judgement_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)商品区分
  TYPE t_upd_goods_classe IS TABLE OF xxwip_deliverys.goods_classe%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)混載区分
  TYPE t_upd_mixed_code IS TABLE OF xxwip_deliverys.mixed_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)請求運賃
  TYPE t_upd_charged_amount IS TABLE OF xxwip_deliverys.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)代表出庫倉庫コード
  TYPE t_upd_whs_code IS TABLE OF xxwip_deliverys.whs_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)代表配送先コード区分
  TYPE t_upd_code_division IS TABLE OF xxwip_deliverys.code_division%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)代表配送先コード
  TYPE t_upd_shipping_address_code IS TABLE OF xxwip_deliverys.shipping_address_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)最長実際距離
  TYPE t_upd_actual_distance IS TABLE OF xxwip_deliverys.actual_distance%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)混載数
  TYPE t_upd_consolid_qty IS TABLE OF xxwip_deliverys.consolid_qty%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)代表タイプ
  TYPE t_upd_order_type IS TABLE OF xxwip_deliverys.order_type%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)重量容積区分
  TYPE t_upd_weight_capacity_class IS TABLE OF xxwip_deliverys.weight_capacity_class%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)契約外区分
  TYPE t_upd_outside_contract IS TABLE OF xxwip_deliverys.outside_contract%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)差異区分
  TYPE t_upd_output_flag IS TABLE OF xxwip_deliverys.output_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)支払確定区分
  TYPE t_upd_defined_flag IS TABLE OF xxwip_deliverys.defined_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)支払確定戻
  TYPE t_upd_return_flag IS TABLE OF xxwip_deliverys.return_flag%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)振替先
  TYPE t_upd_transfer_location IS TABLE OF xxwip_deliverys.transfer_location%TYPE
  INDEX BY BINARY_INTEGER;
  -- (更新用)配車タイプ
  TYPE t_upd_dispatch_type IS TABLE OF xxwip_deliverys.dispatch_type%TYPE
  INDEX BY BINARY_INTEGER;
--
  tab_upd_delivery_company_code         t_upd_delivery_company_code;     -- (更新用)運送業者
  tab_upd_invoice_no                    t_upd_invoice_no;                -- (更新用)送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
  tab_upd_invoice_no2                   t_upd_invoice_no2;               -- (更新用)送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
  tab_upd_payments_judgment_clas        t_upd_payments_judgment_classe;  -- (更新用)支払判断区分
  tab_upd_ship_date                     t_upd_ship_date;                 -- (更新用)出庫日
  tab_upd_arrival_date                  t_upd_arrival_date;              -- (更新用)到着日
  tab_upd_report_date                   t_upd_report_date;               -- (更新用)報告日
  tab_upd_judgement_date                t_upd_judgement_date;            -- (更新用)判断日
  tab_upd_goods_classe                  t_upd_goods_classe;              -- (更新用)商品区分
  tab_upd_mixed_code                    t_upd_mixed_code;                -- (更新用)混載区分
  tab_upd_charged_amount                t_upd_charged_amount;            -- (更新用)請求運賃
  tab_upd_whs_code                      t_upd_whs_code;                  -- (更新用)代表出庫倉庫コード
  tab_upd_code_division                 t_upd_code_division;             -- (更新用)代表配送先コード区分
  tab_upd_shipping_address_code         t_upd_shipping_address_code;     -- (更新用)代表配送先コード
  tab_upd_actual_distance               t_upd_actual_distance;           -- (更新用)最長実際距離
  tab_upd_consolid_qty                  t_upd_consolid_qty;              -- (更新用)混載数
  tab_upd_order_type                    t_upd_order_type;                -- (更新用)代表タイプ
  tab_upd_weight_capacity_class         t_upd_weight_capacity_class;     -- (更新用)重量容積区分
  tab_upd_outside_contract              t_upd_outside_contract;          -- (更新用)契約外区分
  tab_upd_output_flag                   t_upd_output_flag;               -- (更新用)差異区分
  tab_upd_defined_flag                  t_upd_defined_flag;              -- (更新用)支払確定区分
  tab_upd_return_flag                   t_upd_return_flag;               -- (更新用)支払確定戻
  tab_upd_transfer_location             t_upd_transfer_location;         -- (更新用)振替先
  tab_upd_dispatch_type                 t_upd_dispatch_type;             -- (更新用)配車タイプ
--
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
--
  -- 運賃ヘッダアドオン更新用PL/SQL表索引
  gn_upd_cnt    NUMBER;
--
  -- ========================================
  -- 洗替運賃ヘッダアドオン更新用PL/SQL表定義
  -- ========================================
--
  -- (洗替用)配送No
  TYPE t_ex_delivery_no IS TABLE OF xxwip_deliverys.delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- (洗替用)契約運賃
  TYPE t_ex_contract_rate IS TABLE OF xxwip_deliverys.contract_rate%TYPE INDEX BY BINARY_INTEGER;
  -- (洗替用)差額
  TYPE t_ex_balance IS TABLE OF xxwip_deliverys.balance%TYPE INDEX BY BINARY_INTEGER;
  -- (洗替用)合計
  TYPE t_ex_total_amount IS TABLE OF xxwip_deliverys.total_amount%TYPE INDEX BY BINARY_INTEGER;
  -- (洗替用)混載割増金額
  TYPE t_ex_consolid_surcharge IS TABLE OF xxwip_deliverys.consolid_surcharge%TYPE INDEX BY BINARY_INTEGER;
  -- (洗替用)ピッキング料
  TYPE t_ex_picking_charge IS TABLE OF xxwip_deliverys.picking_charge%TYPE INDEX BY BINARY_INTEGER;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
  -- (洗替用)請求運賃
  TYPE t_ex_charged_amount IS TABLE OF xxwip_deliverys.charged_amount%TYPE INDEX BY BINARY_INTEGER;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
--
  tab_ex_delivery_no                    t_ex_delivery_no;
  tab_ex_contract_rate                  t_ex_contract_rate;
  tab_ex_balance                        t_ex_balance;
  tab_ex_total_amount                   t_ex_total_amount;
  tab_ex_consolid_surcharge             t_ex_consolid_surcharge;
  tab_ex_picking_charge                 t_ex_picking_charge;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
  tab_ex_charged_amount                 t_ex_charged_amount;      -- 請求運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
--
  -- 洗替運賃ヘッダアドオン更新用PL/SQL表索引
  gn_ex_cnt     NUMBER;
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
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
  gv_prod_div            VARCHAR2(1);      -- 商品区分
  gv_con_no_deli         VARCHAR2(1);      -- コンカレントNo
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
--
  /**********************************************************************************
   * Procedure Name   : cal_money_proc
   * Description      : 金額計算処理(機能詳細番号無し)
   ***********************************************************************************/
  PROCEDURE cal_money_proc(
    in_goods_classe        IN  xxwip_deliverys.goods_classe%TYPE,               -- 商品区分
    in_mixed_code          IN  xxwip_deliverys.mixed_code%TYPE,                 -- 混載区分
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
    in_charged_amount      IN  xxwip_deliverys.charged_amount%TYPE,             -- 請求運賃
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
    in_shipping_expenses   IN  xxwip_delivery_charges.shipping_expenses%TYPE,   -- 運送料
    in_many_rate           IN  xxwip_deliverys.many_rate%TYPE,                  -- 諸料金
    in_leaf_consolid_add   IN  xxwip_delivery_charges.leaf_consolid_add%TYPE,   -- リーフ混載割増
    in_consolid_qty        IN  xxwip_deliverys.consolid_qty%TYPE,               -- 混載数
    in_qty1                IN  xxwip_deliverys.qty1%TYPE,                       -- 個数1
    in_bill_picking_amount IN  xxwip_delivery_company.bill_picking_amount%TYPE, -- 請求ﾋﾟｯｷﾝｸﾞ単価
    on_balance             OUT NOCOPY xxwip_deliverys.balance%TYPE,             -- 差額
    on_total_amount        OUT NOCOPY xxwip_deliverys.total_amount%TYPE,        -- 合計
    on_consolid_surcharge  OUT NOCOPY xxwip_deliverys.consolid_surcharge%TYPE,  -- 混載割増金額
    on_picking_charge      OUT NOCOPY xxwip_deliverys.picking_charge%TYPE,      -- ピッキング料
    ov_errbuf              OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cal_money_proc'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_balance            NUMBER; -- ｢差額｣算出結果格納用
    ln_total_amount       NUMBER; -- ｢合計｣算出結果格納用
    ln_consolid_surcharge NUMBER; -- ｢混載割増金額｣算出結果格納用
    ln_picking_charge     NUMBER; -- ｢ピッキング料｣算出結果格納用
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
    -- ｢混載割増金額｣の算出
    IF ((in_goods_classe = gv_prod_class_lef)
      AND (in_mixed_code = gv_mixed_code_1))
    THEN
      ln_consolid_surcharge := ROUND(in_leaf_consolid_add * in_consolid_qty);
    ELSE
      ln_consolid_surcharge := 0;
    END IF;
--
    -- ｢ピッキング料｣の算出
    ln_picking_charge := ROUND(in_qty1 * in_bill_picking_amount);
--
    -- ｢合計｣の算出
-- ##### 20081024 Ver.1.4 統合#408対応 START #####
--    ln_total_amount := in_shipping_expenses + ln_consolid_surcharge
--                     + ln_picking_charge    + NVL(in_many_rate, 0);
    -- 合計 ＝ 請求運賃＋混載割増金額＋PIC＋諸料金
    ln_total_amount := NVL(in_charged_amount,0) + ln_consolid_surcharge
                     + ln_picking_charge    + NVL(in_many_rate, 0);
-- ##### 20081024 Ver.1.4 統合#408対応 END   #####
--
    -- ｢差額｣の算出(合計－請求運賃＋混載割増金額＋PIC＋諸料金)
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
--    ln_balance := in_shipping_expenses - ln_total_amount;
-- ##### 20081024 Ver.1.4 統合#408対応 START #####
--    ln_balance := in_charged_amount - ln_total_amount;
    ln_balance := ln_total_amount - (NVL(in_charged_amount,0) + ln_consolid_surcharge
                                       + ln_picking_charge    + NVL(in_many_rate, 0));
-- ##### 20081024 Ver.1.4 統合#408対応 END   #####
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
--
    -- 各算出値をOUT変数にセット
    on_balance            := ln_balance;
    on_total_amount       := ln_total_amount;
    on_picking_charge     := ln_picking_charge;
    on_consolid_surcharge := ln_consolid_surcharge;
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
  END cal_money_proc;
--
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####  運賃マスタ・運賃用運送業者マスタの変更フラグによって、計算し直すかが異なるので、別プロシージャを作成
  /**********************************************************************************
   * Procedure Name   : cal_money_proc
   * Description      : 金額計算処理(洗替用)(機能詳細番号無し)
   ***********************************************************************************/
  PROCEDURE cal_money_proc(
    ir_xd_ex_data          IN         rec_extraction_ex_xd,                     -- 洗替運賃ヘッダーアドオンレコード
    ir_xdc_ex_data         IN         xxwip_common3_pkg.delivery_charges_rec,   -- 洗替運賃アドオンマスタレコード
    on_balance             OUT NOCOPY xxwip_deliverys.balance%TYPE,             -- 差額
    on_total_amount        OUT NOCOPY xxwip_deliverys.total_amount%TYPE,        -- 合計
    on_consolid_surcharge  OUT NOCOPY xxwip_deliverys.consolid_surcharge%TYPE,  -- 混載割増金額
    on_picking_charge      OUT NOCOPY xxwip_deliverys.picking_charge%TYPE,      -- ピッキング料
    on_contract_rate       OUT NOCOPY xxwip_deliverys.contract_rate%TYPE,       -- 契約運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
    on_charged_amount      OUT NOCOPY xxwip_deliverys.charged_amount%TYPE,      -- 請求運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
    ov_errbuf              OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg              OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cal_money_proc'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_balance            NUMBER; -- ｢差額｣算出結果格納用
    ln_total_amount       NUMBER; -- ｢合計｣算出結果格納用
    ln_consolid_surcharge NUMBER; -- ｢混載割増金額｣算出結果格納用
    ln_picking_charge     NUMBER; -- ｢ピッキング料｣算出結果格納用
    ln_contract_rate      NUMBER; -- ｢契約運賃｣算出結果格納用
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
    ln_charged_amount     NUMBER; -- ｢請求運賃｣算出結果格納用
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================
    -- 混載割増金額算出
    -- ==============================
    -- 運賃マスタ(リーフ混載割増)の変更フラグがONの場合、計算する。
    IF (ir_xdc_ex_data.leaf_change_flg = gv_change_flg_on) THEN
      -- リーフで混載の場合
      IF ((ir_xd_ex_data.goods_classe = gv_prod_class_lef)
        AND (ir_xd_ex_data.mixed_code = gv_mixed_code_1))
      THEN
        -- 混載割増料金＝運賃マスタ.リーフ混載割増×運賃ヘッダ.混載数
        ln_consolid_surcharge := ROUND(ir_xdc_ex_data.leaf_consolid_add * ir_xd_ex_data.consolid_qty);
      ELSE
        -- 混載割増料金＝0
        ln_consolid_surcharge := 0;
      END IF;
--
    -- 運賃マスタ変更フラグがOFFの場合、洗替前の混載割増金額を設定
    ELSIF (ir_xdc_ex_data.leaf_change_flg = gv_change_flg_off) THEN
      -- 混載割増料金＝運賃ヘッダ.混載割増料金
      ln_consolid_surcharge := ir_xd_ex_data.before_consolid_surcharge;
    END IF;
--
    -- ==============================
    -- 契約運賃/請求運賃算出
    -- ==============================
    -- 運賃マスタ(運送費)の変更フラグがONの場合、運賃マスタの運送料を設定
    IF (ir_xdc_ex_data.shipping_change_flg = gv_change_flg_on) THEN
      -- 契約運賃＝運賃マスタ.運送費
      ln_contract_rate := ir_xdc_ex_data.shipping_expenses;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
      -- 請求運賃＝運賃マスタ.運送費
      ln_charged_amount :=ir_xdc_ex_data.shipping_expenses;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
--
    -- 運賃マスタ(運送費)の変更フラグがOFFの場合、洗替前の運送料を設定
    ELSIF (ir_xdc_ex_data.shipping_change_flg = gv_change_flg_off) THEN
      -- 契約運賃＝運賃ヘッダ.契約運賃
      ln_contract_rate := ir_xd_ex_data.before_contract_rate;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
      -- 請求運賃＝運賃ヘッダ.請求運賃
      ln_charged_amount :=ir_xd_ex_data.charged_amount;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
    END IF;
--
    -- ==============================
    -- ピッキング料算出
    -- ==============================
    -- 運賃用運送業者マスタ 請求変更フラグがONの場合、計算する。
    IF (ir_xd_ex_data.bill_change_flg = gv_change_flg_on) THEN
      -- ピッキング料＝運賃ヘッダ.個数1×運賃用運送業者マスタ.請求ピッキング単価
      ln_picking_charge := ROUND(ir_xd_ex_data.qty1 * ir_xd_ex_data.bill_picking_amount);
--
    -- 運賃用運送業者マスタ 請求変更フラグがOFFの場合、洗替前の混載割増金額を設定
    ELSIF (ir_xd_ex_data.bill_change_flg = gv_change_flg_off) THEN
      -- ピッキング料＝運賃ヘッダ.ピッキング料
      ln_picking_charge := ir_xd_ex_data.before_picking_charge;
    END IF;
--
    -- ==============================
    -- 合計算出
    -- ==============================
    -- 合計 ＝ 運賃ヘッダ.請求運賃＋混載割増金額＋PIC＋運賃ヘッダ.諸料金
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
--    ln_total_amount := NVL(ir_xd_ex_data.charged_amount,0)
    ln_total_amount := NVL(ln_charged_amount,0)
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
                     + ln_consolid_surcharge
                     + ln_picking_charge
                     + NVL(ir_xd_ex_data.many_rate, 0)
                     ;
--
    -- ==============================
    -- 差額算出
    -- ==============================
    ln_balance := ln_total_amount 
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
--                - (NVL(ir_xd_ex_data.charged_amount,0)
                - (NVL(ln_charged_amount,0)
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
                 + ln_consolid_surcharge
                 + ln_picking_charge
                 + NVL(ir_xd_ex_data.many_rate, 0)
                  );
--
    -- 各算出値をOUT変数にセット
    on_balance            := ln_balance;
    on_total_amount       := ln_total_amount;
    on_picking_charge     := ln_picking_charge;
    on_consolid_surcharge := ln_consolid_surcharge;
    on_contract_rate      := ln_contract_rate;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
    on_charged_amount     := ln_charged_amount;
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
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
  END cal_money_proc;
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
--
  /**********************************************************************************
   * Procedure Name   : chk_param_proc
   * Description      : パラメータチェック処理(D-1)
   ***********************************************************************************/
  PROCEDURE chk_param_proc(
    iv_exchange_type   IN         VARCHAR2,     -- 洗替区分
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
--
    -- *** ローカル変数 ***
    ln_count NUMBER;   -- チェック用カウンタ
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
    -- 必須チェック
    IF (iv_exchange_type IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip
                                           ,gv_msg_wip_10008
                                           ,gv_tkn_item
                                           ,gv_exchange_type_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
    -- 洗替区分が存在しない場合
    IF (ln_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn,   gv_msg_cmn_10010,
                                            gv_tkn_parameter, gv_exchange_type_name,
                                            gv_tkn_value,     iv_exchange_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END chk_param_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_init
   * Description      : 関連データ取得(D-2)
   ***********************************************************************************/
  PROCEDURE get_init(
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    iv_prod_div      IN         VARCHAR2,     -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
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
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル変数 ***
    lv_tkn_msg         VARCHAR2(2000); -- トークン取得用
    -- *** ローカル・例外処理 ***
    get_prof_expt      EXCEPTION ;     -- プロファイル取得例外
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
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
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    gv_prod_div         := NULL;                       -- 商品区分
--
    -- 入力項目.商品区分がNULLの場合、プロファイル値を設定
    IF ( iv_prod_div IS NULL ) THEN
      -- プロファイル値取得
      gv_prod_div := FND_PROFILE.VALUE(gv_prof_item_div_sec);
      -- プロファイル値がNULLの場合
      IF ( gv_prod_div IS NULL ) THEN
        -- トークン取得
        lv_tkn_msg := xxcmn_common_pkg.get_msg( gv_msg_kbn_wip
                                               ,gv_msg_wip_10090
                                              ) ;
        -- メッセージ生成
        lv_errmsg  := xxcmn_common_pkg.get_msg( gv_msg_kbn_wip
                                               ,gv_msg_wip_10067
                                               ,gv_tkn_ng_profile
                                               ,lv_tkn_msg
                                              ) ;
        RAISE get_prof_expt ;
      END IF;
    ELSE
      -- 入力項目.商品区分を設定
      gv_prod_div := iv_prod_div; -- 商品区分
    END IF;
--
    -- 商品区分からコンカレントNo取得
    IF ( gv_prod_div = gv_prod_class_lef ) THEN
      gv_con_no_deli := gv_con_no_deli_lef;  -- リーフ
    ELSE
      gv_con_no_deli := gv_con_no_deli_drk;  -- ドリンク
    END IF;
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
    -- 運賃計算用コントロールより前回処理日付を取得
    BEGIN
      SELECT xdc.last_process_date    -- 前回処理日付
      INTO   gd_last_process_date
      FROM   xxwip_deliverys_ctrl xdc -- 運賃計算用コントロールアドオン
      WHERE  xdc.concurrent_no = gv_con_no_deli
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_cmn_10001,
                                              gv_tkn_table,   gv_deli_ctrl_name,
                                              gv_tkn_key,     gv_con_no_deli);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN lock_expt THEN       --*** ロック取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip, gv_msg_wip_10004,
                                              gv_tkn_table,   gv_deli_ctrl_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    -- *** プロファイル取得例外ハンドラ ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
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
   * Procedure Name   : chk_close_proc
   * Description      : 運賃用締日情報取得(D-3)
   ***********************************************************************************/
  PROCEDURE chk_close_proc(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_close_proc'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_close_type VARCHAR2(1);
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
    -- 前月運賃締め後 判定
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type,   -- 締め区分(Y:締日前、N:締日後)
      lv_errbuf,       -- エラー・メッセージ
      lv_retcode,      -- リターン・コード
      lv_errmsg);      -- ユーザー・エラー・メッセージ
--
    IF (lv_retcode = gv_status_error) THEN
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
  END chk_close_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_lock_xd
   * Description      : ロック取得(D-4)
   ***********************************************************************************/
  PROCEDURE get_lock_xd(
-- ##### 20090410 Ver.1.5 本番#432対応 START #####
    iv_exchange_type IN         VARCHAR2,     -- 洗替区分
-- ##### 20090410 Ver.1.5 本番#432対応 END   #####
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock_xd'; -- プログラム名
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
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
    lv_lock_err_tbl_name VARCHAR2(100);  -- ロックエラー発生テーブル名
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
--
    -- *** ローカル・カーソル ***
    CURSOR cur_lock_xd IS
      SELECT xd.deliverys_header_id AS deliverys_header_id
      FROM   xxwip_deliverys xd
      WHERE  xd.p_b_classe        = gv_paycharge_type_2
      FOR UPDATE NOWAIT;
-- ##### 20090410 Ver.1.5 本番#432対応 START #####
    -- 運賃用運送業者アドオンマスタロック取得
    CURSOR cur_lock_xdco IS
      SELECT xdco.delivery_company_id AS delivery_company_id
      FROM   xxwip_delivery_company xdco              -- 運賃用運送業者アドオンマスタ
      WHERE  xdco.bill_change_flg = gv_change_flg_on  -- 請求変更フラグ:ON
      FOR UPDATE NOWAIT;
--
    -- 運賃アドオンマスタロック取得
    CURSOR cur_lock_xdch IS
      SELECT xdch.delivery_charges_id AS delivery_charges_id
      FROM   xxwip_delivery_charges xdch              -- 運賃アドオンマスタ
      WHERE  xdch.change_flg      = gv_change_flg_on      -- 変更フラグ:ON
      AND    xdch.p_b_classe      = gv_paycharge_type_2   -- 支払請求区分:請求
      FOR UPDATE NOWAIT;
-- ##### 20090410 Ver.1.5 本番#432対応 END   #####
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
-- ##### 20090410 Ver.1.5 本番#432対応 MOD START #####
--    -- 運賃ヘッダアドオンのレコードロックを取得
--    OPEN cur_lock_xd;
--
    -- ==================================
    -- 運賃ヘッダアドオンロックを取得
    -- ==================================
    BEGIN
      OPEN  cur_lock_xd;
      CLOSE cur_lock_xd;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_lock_err_tbl_name := gv_deli_name;
        RAISE lock_expt;
    END;
--
    -- 洗替区分YESの場合、マスタのロック取得
    IF (iv_exchange_type = gv_ktg_yes) THEN
      -- ========================================
      -- 運賃用運送業者アドオンマスタロック取得
      -- ========================================
      BEGIN
        OPEN  cur_lock_xdco;
        CLOSE cur_lock_xdco;
--
      EXCEPTION
        WHEN lock_expt THEN
          lv_lock_err_tbl_name := gv_deli_comp_name;
          RAISE lock_expt;
      END;
--
      -- ========================================
      -- 運賃アドオンマスタロック取得
      -- ========================================
      BEGIN
        OPEN  cur_lock_xdch;
        CLOSE cur_lock_xdch;
--
      EXCEPTION
        WHEN lock_expt THEN
          lv_lock_err_tbl_name := gv_deli_charges_name;
          RAISE lock_expt;
      END;
--
    END IF;
-- ##### 20090410 Ver.1.5 本番#432対応 MOD END   #####
--
  EXCEPTION
--
    -- ロック失敗エラー
    WHEN lock_expt THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip, gv_msg_wip_10004,
-- ##### 20090410 Ver.1.5 本番#432対応 MOD START #####
--                                             gv_tkn_table,   gv_deli_name);
                                             gv_tkn_table,   lv_lock_err_tbl_name);
-- ##### 20090410 Ver.1.5 本番#432対応 MOD END   #####
      lv_errbuf  := lv_errmsg;
      -- OUT変数に書き出し
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_lock_xd;
--
  /**********************************************************************************
   * Procedure Name   : get_xd_data
   * Description      : 運賃ヘッダアドオン抽出(D-5)
   ***********************************************************************************/
  PROCEDURE get_xd_data(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xd_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ld_first_day        DATE;   -- 運賃用締日
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
    IF (gv_closed_day = 'N') THEN
      -- (締日後)当月の初日を取得
      ld_first_day := TRUNC(gd_sysdate, 'MM');
    ELSIF (gv_closed_day = 'Y') THEN
      -- (締日前)先月の月初日を取得
      ld_first_day := TRUNC(ADD_MONTHS(gd_sysdate, -1), 'MM');
    END IF;
--
    -- 運賃ヘッダアドオンデータ抽出
    BEGIN
      SELECT xd.delivery_company_code,       -- 運送業者
             xd.delivery_no,                 -- 配送No
             xd.invoice_no,                  -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
             xd.invoice_no2,                 -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
             xd.payments_judgment_classe,    -- 支払判断区分
             xd.ship_date,                   -- 出庫日
             xd.arrival_date,                -- 到着日
             xd.report_date,                 -- 報告日
             xd.judgement_date,              -- 判断日
             xd.goods_classe,                -- 商品区分
             xd.mixed_code,                  -- 混載区分
             xd.many_rate,                   -- 諸料金
             xd.distance,                    -- 最長距離
             xd.delivery_classe,             -- 配送区分
             xd.whs_code,                    -- 代表出庫倉庫コード
             xd.code_division,               -- 代表配送先コード区分
             xd.shipping_address_code,       -- 代表配送先コード
             xd.qty1,                        -- 個数１
             xd.qty2,                        -- 個数２
             xd.delivery_weight1,            -- 重量１
             xd.delivery_weight2,            -- 重量２
             xd.actual_distance,             -- 最長実際距離
             xd.congestion_charge,           -- 通行料
             xd.consolid_qty,                -- 混載数
             xd.order_type,                  -- 代表タイプ
             xd.weight_capacity_class,       -- 重量容積区分
             xd.outside_contract,            -- 契約外区分
             xd.transfer_location,           -- 振替先
             xd.description,                 -- 運賃摘要
             xd.dispatch_type,               -- 配車タイプ(2008/07/11)
             NVL(xdc.bill_picking_amount, 0) -- 請求ピッキング単価
      BULK COLLECT INTO gt_extraction_xd
      FROM   xxwip_deliverys        xd,  -- 運賃ヘッダアドオン
             xxwip_delivery_company xdc  -- 運賃用運送業者アドオンマスタ
      WHERE  xd.p_b_classe            =  gv_paycharge_type_1
      AND    xd.defined_flag          =  gv_defined_yes
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
      AND    xd.goods_classe          =  gv_prod_div                      -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
      AND    xd.goods_classe          =  xdc.goods_classe(+)
      AND    xd.delivery_company_code =  xdc.delivery_company_code(+)
      AND    xd.judgement_date        >= xdc.start_date_active(+)
      AND    xd.judgement_date        <= xdc.end_date_active(+)
      AND    xd.judgement_date        >= ld_first_day
      AND    xd.last_update_date      >  gd_last_process_date
      AND    xd.last_update_date      <= gd_sysdate
      ORDER BY xd.delivery_no;
    END;
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
  END get_xd_data;
--
  /**********************************************************************************
   * Procedure Name   : get_xdc_data
   * Description      : 運賃アドオンマスタ抽出(D-6)
   ***********************************************************************************/
  PROCEDURE get_xdc_data(
    ir_xd_data    IN  rec_extraction_xd,   --   運賃ヘッダーアドオンレコード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xdc_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    -- (運賃アドオンマスタ)運送費、リーフ混載割増取得
    xxwip_common3_pkg.get_delivery_charges(
      iv_p_b_classe              => gv_paycharge_type_2,              -- 支払請求区分｢請求｣
      iv_goods_classe            => ir_xd_data.goods_classe,          -- 商品区分
      iv_delivery_company_code   => ir_xd_data.delivery_company_code, -- 運送業者
      iv_shipping_address_classe => ir_xd_data.delivery_classe,       -- 配送区分
      iv_delivery_distance       => ir_xd_data.distance,              -- 最長距離
      iv_delivery_weight         => ir_xd_data.delivery_weight1,      -- 重量
      id_target_date             => ir_xd_data.judgement_date,        -- 判断日
      or_delivery_charges        => gr_extraction_xdc,                -- 運賃アドオンレコード
      ov_errbuf                  => lv_errbuf,                        -- エラー・メッセージ
      ov_retcode                 => lv_retcode,                       -- リターン・コード
      ov_errmsg                  => lv_errmsg);                       -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
--
    -- 処理後チェック
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
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
  END get_xdc_data;
--
  /**********************************************************************************
   * Procedure Name   : set_xd_data
   * Description      : 運賃ヘッダアドオンPL/SQL表格納(D-7)
   ***********************************************************************************/
  PROCEDURE set_xd_data(
    ir_xd_data    IN  rec_extraction_xd,   --   運賃ヘッダーアドオンレコード
    ir_xdc_data   IN  xxwip_common3_pkg.delivery_charges_rec,
                                           --   運賃アドオンマスタレコード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_xd_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_cnt                 NUMBER; -- 存在チェック用
    ln_balance             NUMBER; -- ｢差額｣
    ln_total_amount        NUMBER; -- ｢合計｣
    ln_consolid_surcharge  NUMBER; -- ｢混載割増金額｣
    ln_picking_charge      NUMBER; -- ｢ピッキング料｣
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
    -- 登録、更新を判定(存在チェック)
    BEGIN
      SELECT COUNT(xd.deliverys_header_id)
      INTO   ln_cnt
      FROM   xxwip_deliverys xd
      WHERE  xd.p_b_classe  = gv_paycharge_type_2
      AND    xd.delivery_no = ir_xd_data.delivery_no
      AND    ROWNUM         = 1;
    END;
--
    -- ｢差額｣｢合計｣｢混載割増金額｣｢ピッキング料｣の算出
    cal_money_proc(
      in_goods_classe        => ir_xd_data.goods_classe,        -- 商品区分
      in_mixed_code          => ir_xd_data.mixed_code,          -- 混載区分
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
      in_charged_amount      => ir_xdc_data.shipping_expenses,  -- 請求金額（運送費）
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
      in_shipping_expenses   => ir_xdc_data.shipping_expenses,  -- 運送料
      in_many_rate           => ir_xd_data.many_rate,           -- 諸料金
      in_leaf_consolid_add   => ir_xdc_data.leaf_consolid_add,  -- リーフ混載割増
      in_consolid_qty        => ir_xd_data.consolid_qty,        -- 混載数
      in_qty1                => ir_xd_data.qty1,                -- 個数1
      in_bill_picking_amount => ir_xd_data.bill_picking_amount, -- 請求ピッキング単価
      on_balance             => ln_balance,                     -- 差額
      on_total_amount        => ln_total_amount,                -- 合計
      on_consolid_surcharge  => ln_consolid_surcharge,          -- 混載割増金額
      on_picking_charge      => ln_picking_charge,              -- ピッキング料
      ov_errbuf              => lv_errbuf,                      -- エラー・メッセージ
      ov_retcode             => lv_retcode,                     -- リターン・コード
      ov_errmsg              => lv_errmsg);                     -- ユーザー・エラー・メッセージ
--
    -- 処理結果チェック
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (ln_cnt = 0) THEN
--
      -- ***************************************
      -- *** 登録用PL/SQL表格納処理          ***
      -- ***************************************
--
      -- 登録テーブル索引インクリメント
      gn_ins_cnt := gn_ins_cnt + 1;
--
      -- シーケンス取得
      SELECT xxwip_deliverys_id_s1.NEXTVAL
      INTO   tab_ins_deliverys_header_id(gn_ins_cnt)  -- 運賃ヘッダーアドオンID
      FROM   dual;
--
      tab_ins_delivery_company_code(gn_ins_cnt) := ir_xd_data.delivery_company_code;
                                                                                 -- 運送業者
      tab_ins_delivery_no(gn_ins_cnt)           := ir_xd_data.delivery_no;       -- 配送No
      tab_ins_invoice_no(gn_ins_cnt)            := ir_xd_data.invoice_no;        -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
      tab_ins_invoice_no2(gn_ins_cnt)           := ir_xd_data.invoice_no2;        -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
      tab_ins_p_b_classe(gn_ins_cnt)            := gv_paycharge_type_2;          -- 支払請求区
      tab_ins_payments_judgment_clas(gn_ins_cnt) := ir_xd_data.payments_judgment_classe;
                                                                                 -- 支払判断区
      tab_ins_ship_date(gn_ins_cnt)             := ir_xd_data.ship_date;         -- 出庫日
      tab_ins_arrival_date(gn_ins_cnt)          := ir_xd_data.arrival_date;      -- 到着日
      tab_ins_report_date(gn_ins_cnt)           := ir_xd_data.report_date;       -- 報告日
      tab_ins_judgement_date(gn_ins_cnt)        := ir_xd_data.judgement_date;    -- 判断日
      tab_ins_goods_classe(gn_ins_cnt)          := ir_xd_data.goods_classe;      -- 商品区分
      tab_ins_mixed_code(gn_ins_cnt)            := ir_xd_data.mixed_code;        -- 混載区分
      tab_ins_charged_amount(gn_ins_cnt)        := ir_xdc_data.shipping_expenses;-- 請求運賃
      tab_ins_contract_rate(gn_ins_cnt)         := ir_xdc_data.shipping_expenses;-- 契約運賃
      tab_ins_balance(gn_ins_cnt)               := ln_balance;                   -- 差額
      tab_ins_total_amount(gn_ins_cnt)          := ln_total_amount;              -- 合計
      tab_ins_many_rate(gn_ins_cnt)             := ir_xd_data.many_rate;         -- 諸料金
      tab_ins_distance(gn_ins_cnt)              := ir_xd_data.distance;          -- 最長距離
      tab_ins_delivery_classe(gn_ins_cnt)       := ir_xd_data.delivery_classe;   -- 配送区分
      tab_ins_whs_code(gn_ins_cnt)              := ir_xd_data.whs_code;          -- 代表出庫倉庫CD
      tab_ins_code_division(gn_ins_cnt)         := ir_xd_data.code_division;     -- 代表配送先CD区
      tab_ins_shipping_address_code(gn_ins_cnt) := ir_xd_data.shipping_address_code;
                                                                                 -- 代表配送先CD
      tab_ins_qty1(gn_ins_cnt)                  := ir_xd_data.qty1;              -- 個数１
      tab_ins_qty2(gn_ins_cnt)                  := ir_xd_data.qty2;              -- 個数２
      tab_ins_delivery_weight1(gn_ins_cnt)      := ir_xd_data.delivery_weight1;  -- 重量１
      tab_ins_delivery_weight2(gn_ins_cnt)      := ir_xd_data.delivery_weight2;  -- 重量２
      tab_ins_consolid_surcharge(gn_ins_cnt)    := ln_consolid_surcharge;        -- 混載割増金額
      tab_ins_actual_distance(gn_ins_cnt)       := ir_xd_data.actual_distance;   -- 最長実際距離
      tab_ins_congestion_charge(gn_ins_cnt)     := ir_xd_data.congestion_charge; -- 通行料
      tab_ins_picking_charge(gn_ins_cnt)        := ln_picking_charge;            -- ピッキング料
      tab_ins_consolid_qty(gn_ins_cnt)          := ir_xd_data.consolid_qty;      -- 混載数
      tab_ins_order_type(gn_ins_cnt)            := ir_xd_data.order_type;        -- 代表タイプ
      tab_ins_weight_capacity_class(gn_ins_cnt) := ir_xd_data.weight_capacity_class;
                                                                                 -- 重量容積区分
      tab_ins_outside_contract(gn_ins_cnt)      := ir_xd_data.outside_contract;  -- 契約外区分
      tab_ins_output_flag(gn_ins_cnt)           := NULL;                         -- 差異区分
      tab_ins_defined_flag(gn_ins_cnt)          := NULL;                         -- 支払確定区分
      tab_ins_return_flag(gn_ins_cnt)           := NULL;                         -- 支払確定戻
      tab_ins_form_update_flag(gn_ins_cnt)      := 'N';                          -- 画面更新有無区
      tab_ins_transfer_location(gn_ins_cnt)     := ir_xd_data.transfer_location; -- 振替先
      tab_ins_outside_up_count(gn_ins_cnt)      := 0;                            -- 外部業者変更数
      tab_ins_description(gn_ins_cnt)           := ir_xd_data.description;       -- 運賃摘要
--
      -- 2008/07/11
      tab_ins_dispatch_type(gn_ins_cnt)         := ir_xd_data.dispatch_type;     -- 配車タイプ
--
    ELSE
--
      -- ***************************************
      -- *** 更新用PL/SQL表格納処理          ***
      -- ***************************************
--
      -- 更新テーブル索引インクリメント
      gn_upd_cnt := gn_upd_cnt + 1;
--
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
-- 登録時と同じ状態に更新する為、更新項目追加
--
      tab_upd_delivery_company_code(gn_upd_cnt)     := ir_xd_data.delivery_company_code;    -- 運送業者
      tab_upd_invoice_no(gn_upd_cnt)                := ir_xd_data.invoice_no;               -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
      tab_upd_invoice_no2(gn_upd_cnt)               := ir_xd_data.invoice_no2;              -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
      tab_upd_payments_judgment_clas(gn_upd_cnt)    := ir_xd_data.payments_judgment_classe; -- 支払判断区分
      tab_upd_ship_date(gn_upd_cnt)                 := ir_xd_data.ship_date;              -- 出庫日
      tab_upd_arrival_date(gn_upd_cnt)              := ir_xd_data.arrival_date;           -- 到着日
      tab_upd_report_date(gn_upd_cnt)               := ir_xd_data.report_date;            -- 報告日
      tab_upd_judgement_date(gn_upd_cnt)            := ir_xd_data.judgement_date;         -- 判断日
      tab_upd_goods_classe(gn_upd_cnt)              := ir_xd_data.goods_classe;           -- 商品区分
      tab_upd_mixed_code(gn_upd_cnt)                := ir_xd_data.mixed_code;             -- 混載区分
      tab_upd_charged_amount(gn_upd_cnt)            := ir_xdc_data.shipping_expenses;     -- 請求運賃
      tab_upd_whs_code(gn_upd_cnt)                  := ir_xd_data.whs_code;               -- 代表出庫倉庫コード
      tab_upd_code_division(gn_upd_cnt)             := ir_xd_data.code_division;          -- 代表配送先コード区分
      tab_upd_shipping_address_code(gn_upd_cnt)     := ir_xd_data.shipping_address_code;  -- 代表配送先コード
      tab_upd_actual_distance(gn_upd_cnt)           := ir_xd_data.actual_distance;        -- 最長実際距離
      tab_upd_consolid_qty(gn_upd_cnt)              := ir_xd_data.consolid_qty;           -- 混載数
      tab_upd_order_type(gn_upd_cnt)                := ir_xd_data.order_type;             -- 代表タイプ
      tab_upd_weight_capacity_class(gn_upd_cnt)     := ir_xd_data.weight_capacity_class;  -- 重量容積区分
      tab_upd_outside_contract(gn_upd_cnt)          := ir_xd_data.outside_contract;       -- 契約外区分
      tab_upd_output_flag(gn_upd_cnt)               := NULL;     -- 差異区分
      tab_upd_defined_flag(gn_upd_cnt)              := NULL;     -- 支払確定区分
      tab_upd_return_flag(gn_upd_cnt)               := NULL;     -- 支払確定戻
      tab_upd_transfer_location(gn_upd_cnt)         := ir_xd_data.transfer_location;      -- 振替先
      tab_upd_dispatch_type(gn_upd_cnt)             := ir_xd_data.dispatch_type;          -- 配車タイプ
--
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
--
      tab_upd_delivery_no(gn_upd_cnt)        := ir_xd_data.delivery_no;        -- 配送No
      tab_upd_contract_rate(gn_upd_cnt)      := ir_xdc_data.shipping_expenses; -- 契約運賃
      tab_upd_balance(gn_upd_cnt)            := ln_balance;                    -- 差額
      tab_upd_total_amount(gn_upd_cnt)       := ln_total_amount;               -- 合計
      tab_upd_distance(gn_upd_cnt)           := ir_xd_data.distance;           -- 最長距離
      tab_upd_delivery_classe(gn_upd_cnt)    := ir_xd_data.delivery_classe;    -- 配送区分
      tab_upd_qty1(gn_upd_cnt)               := ir_xd_data.qty1;               -- 個数１
      tab_upd_qty2(gn_upd_cnt)               := ir_xd_data.qty2;               -- 個数２
      tab_upd_delivery_weight1(gn_upd_cnt)   := ir_xd_data.delivery_weight1;   -- 重量１
      tab_upd_delivery_weight2(gn_upd_cnt)   := ir_xd_data.delivery_weight2;   -- 重量２
      tab_upd_many_rate(gn_upd_cnt)          := ir_xd_data.many_rate;          -- 諸料金
      tab_upd_consolid_surcharge(gn_upd_cnt) := ln_consolid_surcharge;         -- 混載割増金額
      tab_upd_congestion_charge(gn_upd_cnt)  := ir_xd_data.congestion_charge;  -- 通行料
      tab_upd_picking_charge(gn_upd_cnt)     := ln_picking_charge;             -- ピッキング料
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
  END set_xd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_xd_proc
   * Description      : 運賃ヘッダアドオン一括登録処理(D-8)
   ***********************************************************************************/
  PROCEDURE ins_xd_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xd_proc'; -- プログラム名
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
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
    -- データが存在しない場合は、処理をスキップ
    IF (tab_ins_deliverys_header_id.COUNT = 0) THEN
      RETURN;
    END IF;
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
--
--
    FORALL ln_index IN tab_ins_deliverys_header_id.FIRST .. tab_ins_deliverys_header_id.LAST
      INSERT INTO xxwip_deliverys(
        deliverys_header_id,        -- 運賃ヘッダーアドオンID
        delivery_company_code,      -- 運送業者
        delivery_no,                -- 配送No
        invoice_no,                 -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
        invoice_no2,                -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
        p_b_classe,                 -- 支払請求区分
        payments_judgment_classe,   -- 支払判断区分
        ship_date,                  -- 出庫日
        arrival_date,               -- 到着日
        report_date,                -- 報告日
        judgement_date,             -- 判断日
        goods_classe,               -- 商品区分
        mixed_code,                 -- 混載区分
        charged_amount,             -- 請求運賃
        contract_rate,              -- 契約運賃
        balance,                    -- 差額
        total_amount,               -- 合計
        many_rate,                  -- 諸料金
        distance,                   -- 最長距離
        delivery_classe,            -- 配送区分
        whs_code,                   -- 代表出庫倉庫コード
        code_division,              -- 代表配送先コード区分
        shipping_address_code,      -- 代表配送先コード
        qty1,                       -- 個数１
        qty2,                       -- 個数２
        delivery_weight1,           -- 重量１
        delivery_weight2,           -- 重量２
        consolid_surcharge,         -- 混載割増金額
        actual_distance,            -- 最長実際距離
        congestion_charge,          -- 通行料
        picking_charge,             -- ピッキング料
        consolid_qty,               -- 混載数
        order_type,                 -- 代表タイプ
        weight_capacity_class,      -- 重量容積区分
        outside_contract,           -- 契約外区分
        output_flag,                -- 差異区分
        defined_flag,               -- 支払確定区分
        return_flag,                -- 支払確定戻
        form_update_flag,           -- 画面更新有無区分
        transfer_location,          -- 振替先
        outside_up_count,           -- 外部業者変更回数
        description,                -- 運賃摘要
        dispatch_type,              -- 配車タイプ(2008/07/11)
        created_by,                 -- 作成者
        creation_date,              -- 作成日
        last_updated_by,            -- 最終更新者
        last_update_date,           -- 最終更新日
        last_update_login,          -- 最終更新ログイン
        request_id,                 -- 要求ID
        program_application_id,     -- コンカレント・プログラム・アプリケーションID
        program_id,                 -- コンカレント・プログラムID
        program_update_date         -- プログラム更新日
      ) VALUES (
        tab_ins_deliverys_header_id(ln_index),        -- 運賃ヘッダーアドオンID
        tab_ins_delivery_company_code(ln_index),      -- 運送業者
        tab_ins_delivery_no(ln_index),                -- 配送No
        tab_ins_invoice_no(ln_index),                 -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
        tab_ins_invoice_no2(ln_index),                -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
        tab_ins_p_b_classe(ln_index),                 -- 支払請求区分
        tab_ins_payments_judgment_clas(ln_index),     -- 支払判断区分
        tab_ins_ship_date(ln_index),                  -- 出庫日
        tab_ins_arrival_date(ln_index),               -- 到着日
        tab_ins_report_date(ln_index),                -- 報告日
        tab_ins_judgement_date(ln_index),             -- 判断日
        tab_ins_goods_classe(ln_index),               -- 商品区分
        tab_ins_mixed_code(ln_index),                 -- 混載区分
        tab_ins_charged_amount(ln_index),             -- 請求運賃
        tab_ins_contract_rate(ln_index),              -- 契約運賃
        tab_ins_balance(ln_index),                    -- 差額
        tab_ins_total_amount(ln_index),               -- 合計
        tab_ins_many_rate(ln_index),                  -- 諸料金
        tab_ins_distance(ln_index),                   -- 最長距離
        tab_ins_delivery_classe(ln_index),            -- 配送区分
        tab_ins_whs_code(ln_index),                   -- 代表出庫倉庫コード
        tab_ins_code_division(ln_index),              -- 代表配送先コード区分
        tab_ins_shipping_address_code(ln_index),      -- 代表配送先コード
        tab_ins_qty1(ln_index),                       -- 個数１
        tab_ins_qty2(ln_index),                       -- 個数２
        tab_ins_delivery_weight1(ln_index),           -- 重量１
        tab_ins_delivery_weight2(ln_index),           -- 重量２
        tab_ins_consolid_surcharge(ln_index),         -- 混載割増金額
        tab_ins_actual_distance(ln_index),            -- 最長実際距離
        tab_ins_congestion_charge(ln_index),          -- 通行料
        tab_ins_picking_charge(ln_index),             -- ピッキング料
        tab_ins_consolid_qty(ln_index),               -- 混載数
        tab_ins_order_type(ln_index),                 -- 代表タイプ
        tab_ins_weight_capacity_class(ln_index),      -- 重量容積区分
        tab_ins_outside_contract(ln_index),           -- 契約外区分
        tab_ins_output_flag(ln_index),                -- 差異区分
        tab_ins_defined_flag(ln_index),               -- 支払確定区分
        tab_ins_return_flag(ln_index),                -- 支払確定戻
        tab_ins_form_update_flag(ln_index),           -- 画面更新有無区分
        tab_ins_transfer_location(ln_index),          -- 振替先
        tab_ins_outside_up_count(ln_index),           -- 外部業者変更回数
        tab_ins_description(ln_index),                -- 運賃摘要
        tab_ins_dispatch_type(ln_index),              -- 配車タイプ(2008/07/11)
        gn_user_id,                                   -- 作成者
        gd_sysdate,                                   -- 作成日
        gn_user_id,                                   -- 最終更新者
        gd_sysdate,                                   -- 最終更新日
        gn_login_id,                                  -- 最終更新ログイン
        gn_conc_request_id,                           -- 要求ID
        gn_prog_appl_id,                              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        gn_conc_program_id,                           -- コンカレント・プログラムID
        gd_sysdate);                                  -- プログラム更新日
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
  END ins_xd_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_xd_proc
   * Description      : 運賃ヘッダアドオン一括更新処理(D-9)
   ***********************************************************************************/
  PROCEDURE upd_xd_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xd_proc'; -- プログラム名
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
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
    -- データが存在しない場合は、処理をスキップ
    IF (tab_upd_delivery_no.COUNT = 0) THEN
      RETURN;
    END IF;
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
--
--
    FORALL ln_index IN tab_upd_delivery_no.FIRST .. tab_upd_delivery_no.LAST
      UPDATE xxwip_deliverys
      SET    contract_rate          = tab_upd_contract_rate(ln_index),      -- 契約運賃
             balance                = tab_upd_balance(ln_index),            -- 差額
             total_amount           = tab_upd_total_amount(ln_index),       -- 合計
             distance               = tab_upd_distance(ln_index),           -- 最長距離
             delivery_classe        = tab_upd_delivery_classe(ln_index),    -- 配送区分
             qty1                   = tab_upd_qty1(ln_index),               -- 個数１
             qty2                   = tab_upd_qty2(ln_index),               -- 個数２
             delivery_weight1       = tab_upd_delivery_weight1(ln_index),   -- 重量１
             delivery_weight2       = tab_upd_delivery_weight2(ln_index),   -- 重量２
             many_rate              = tab_upd_many_rate(ln_index),          -- 諸料金
             consolid_surcharge     = tab_upd_consolid_surcharge(ln_index), -- 混載割増金額
             congestion_charge      = tab_upd_congestion_charge(ln_index),  -- 通行料
             picking_charge         = tab_upd_picking_charge(ln_index),     -- ピッキング料
-- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
             delivery_company_code    = tab_upd_delivery_company_code(ln_index),    -- 運送業者
             invoice_no               = tab_upd_invoice_no(ln_index),               -- 送り状No
-- ##### 20080916 Ver.1.3 T_S_570対応 START #####
             invoice_no2              = tab_upd_invoice_no2(ln_index),              -- 送り状No2
-- ##### 20080916 Ver.1.3 T_S_570対応 END #####
             payments_judgment_classe = tab_upd_payments_judgment_clas(ln_index),   -- 支払判断区分
             ship_date                = tab_upd_ship_date(ln_index),                -- 出庫日
             arrival_date             = tab_upd_arrival_date(ln_index),             -- 到着日
             report_date              = tab_upd_report_date(ln_index),              -- 報告日
             judgement_date           = tab_upd_judgement_date(ln_index),           -- 判断日
             goods_classe             = tab_upd_goods_classe(ln_index),             -- 商品区分
             mixed_code               = tab_upd_mixed_code(ln_index),               -- 混載区分
             charged_amount           = tab_upd_charged_amount(ln_index),           -- 請求運賃
             whs_code                 = tab_upd_whs_code(ln_index),                 -- 代表出庫倉庫コード
             code_division            = tab_upd_code_division(ln_index),            -- 代表配送先コード区分
             shipping_address_code    = tab_upd_shipping_address_code(ln_index),    -- 代表配送先コード
             actual_distance          = tab_upd_actual_distance(ln_index),          -- 最長実際距離
             consolid_qty             = tab_upd_consolid_qty(ln_index),             -- 混載数
             order_type               = tab_upd_order_type(ln_index),               -- 代表タイプ
             weight_capacity_class    = tab_upd_weight_capacity_class(ln_index),    -- 重量容積区分
             outside_contract         = tab_upd_outside_contract(ln_index),         -- 契約外区分
             output_flag              = tab_upd_output_flag(ln_index),              -- 差異区分
             defined_flag             = tab_upd_defined_flag(ln_index),             -- 支払確定区分
             return_flag              = tab_upd_return_flag(ln_index),              -- 支払確定戻
             transfer_location        = tab_upd_transfer_location(ln_index),        -- 振替先
             dispatch_type            = tab_upd_dispatch_type(ln_index),            -- 配車タイプ
-- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
             last_updated_by        = gn_user_id,               -- 最終更新者
             last_update_date       = gd_sysdate,               -- 最終更新日
             last_update_login      = gn_login_id,              -- 最終更新ログイン
             request_id             = gn_conc_request_id,       -- 要求ID
             program_application_id = gn_prog_appl_id,          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             program_id             = gn_conc_program_id,       -- コンカレント・プログラムID
             program_update_date    = gd_sysdate                -- プログラム更新日
      WHERE  p_b_classe             = gv_paycharge_type_2
      AND    delivery_no            = tab_upd_delivery_no(ln_index);
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
  END upd_xd_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_calc_ctrl_proc
   * Description      : 運賃計算用コントロール更新処理(D-10)
   ***********************************************************************************/
  PROCEDURE upd_calc_ctrl_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_calc_ctrl_proc'; -- プログラム名
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
    -- 前回処理日付をコンカレント実行時間に更新
    UPDATE xxwip_deliverys_ctrl
    SET    last_process_date      = gd_sysdate,         -- 前回処理日付
           last_updated_by        = gn_user_id,         -- 最終更新者
           last_update_date       = gd_sysdate,         -- 最終更新日
           last_update_login      = gn_login_id,        -- 最終更新ログイン
           request_id             = gn_conc_request_id, -- 要求ID
           program_application_id = gn_prog_appl_id,    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
           program_id             = gn_conc_program_id, -- コンカレント・プログラムID
           program_update_date    = gd_sysdate          -- プログラム更新日
    WHERE  concurrent_no = gv_con_no_deli;
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
  END upd_calc_ctrl_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_xd_exchange_data
   * Description      : 洗替運賃ヘッダアドオン抽出(D-11)
   ***********************************************************************************/
  PROCEDURE get_xd_exchange_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xd_exchange_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ld_first_day        DATE;   -- 運賃用締日
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
    IF (gv_closed_day = 'N') THEN
      -- (締日後)当月の初日を取得
      ld_first_day := TRUNC(gd_sysdate, 'MM');
    ELSIF (gv_closed_day = 'Y') THEN
      -- (締日前)先月の月初日を取得
      ld_first_day := TRUNC(ADD_MONTHS(gd_sysdate, -1), 'MM');
    END IF;
--
    -- 洗替運賃ヘッダアドオンデータ抽出
    BEGIN
      SELECT xd.delivery_company_code,       -- 運送業者
             xd.delivery_no,                 -- 配送No
             xd.judgement_date,              -- 判断日
             xd.goods_classe,                -- 商品区分
             xd.mixed_code,                  -- 混載区分
             xd.charged_amount,              -- 請求運賃
             xd.many_rate,                   -- 諸料金
             xd.distance,                    -- 最長距離
             xd.delivery_classe,             -- 配送区分
             xd.qty1,                        -- 個数１
             xd.delivery_weight1,            -- 重量１
             xd.consolid_qty,                -- 混載数
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
             xd.picking_charge                           before_picking_charge,      -- 請求ピッキング単価(洗替前)
             xd.contract_rate                            before_contract_rate,       -- 契約運賃(洗替前)
             xd.consolid_surcharge                       before_consolid_surcharge,  -- 混載割増金額(洗替前)
             NVL(xdc.bill_change_flg, gv_change_flg_off) bill_change_flg,            -- 運賃用運送業者マスタ 請求変更フラグ
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
             NVL(xdc.bill_picking_amount, 0) -- 請求ピッキング単価
      BULK COLLECT INTO gt_extraction_ex_xd
      FROM   xxwip_deliverys        xd,  -- 運賃ヘッダアドオン
             xxwip_delivery_company xdc  -- 運賃用運送業者アドオンマスタ
      WHERE  xd.p_b_classe            =  gv_paycharge_type_2
-- ##### 20090410 Ver.1.5 本番#432対応 DEL START #####
--      AND    xd.dispatch_type IN (gv_dispatch_type_1,gv_dispatch_type_2)    -- 2008/07/11
-- ##### 20090410 Ver.1.5 本番#432対応 DEL END   #####
      AND    xd.goods_classe IS NOT NULL
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
      AND    xd.goods_classe          =  gv_prod_div                      -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
      AND    xd.goods_classe          =  xdc.goods_classe(+)
      AND    xd.delivery_company_code =  xdc.delivery_company_code(+)
      AND    xd.judgement_date        >= xdc.start_date_active(+)
      AND    xd.judgement_date        <= xdc.end_date_active(+)
      AND    xd.judgement_date        >= ld_first_day
      ORDER BY xd.delivery_no;
    END;
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
  END get_xd_exchange_data;
--
  /**********************************************************************************
   * Procedure Name   : get_xdc_exchange_data
   * Description      : 洗替運賃アドオンマスタ抽出(D-12)
   ***********************************************************************************/
  PROCEDURE get_xdc_exchange_data(
    ir_xd_ex_data IN  rec_extraction_ex_xd,--   洗替運賃ヘッダーアドオンレコード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xdc_exchange_data'; -- プログラム名
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
    -- (洗替運賃アドオンマスタ)運送費、リーフ混載割増取得
    xxwip_common3_pkg.get_delivery_charges(
      iv_p_b_classe              => gv_paycharge_type_2,                 -- 支払請求区分｢請求｣
      iv_goods_classe            => ir_xd_ex_data.goods_classe,          -- 商品区分
      iv_delivery_company_code   => ir_xd_ex_data.delivery_company_code, -- 運送業者
      iv_shipping_address_classe => ir_xd_ex_data.delivery_classe,       -- 配送区分
      iv_delivery_distance       => ir_xd_ex_data.distance,              -- 最長距離
      iv_delivery_weight         => ir_xd_ex_data.delivery_weight1,      -- 重量
      id_target_date             => ir_xd_ex_data.judgement_date,        -- 判断日
      or_delivery_charges        => gr_extraction_ex_xdc,                -- 運賃アドオンレコード
      ov_errbuf                  => lv_errbuf,                           -- エラー・メッセージ
      ov_retcode                 => lv_retcode,                          -- リターン・コード
      ov_errmsg                  => lv_errmsg);                          -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
--
    -- 処理結果チェック
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
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
  END get_xdc_exchange_data;
--
  /**********************************************************************************
   * Procedure Name   : set_xd_exchange_data
   * Description      : 洗替運賃ヘッダアドオンPL/SQL表格納(D-13)
   ***********************************************************************************/
  PROCEDURE set_xd_exchange_data(
    ir_xd_ex_data  IN  rec_extraction_ex_xd,   --   洗替運賃ヘッダーアドオンレコード
    ir_xdc_ex_data IN  xxwip_common3_pkg.delivery_charges_rec,
                                               --   洗替運賃アドオンマスタレコード
    ov_errbuf      OUT NOCOPY VARCHAR2,        --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,        --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_xd_exchange_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_balance             NUMBER; -- ｢差額｣
    ln_total_amount        NUMBER; -- ｢合計｣
    ln_consolid_surcharge  NUMBER; -- ｢混載割増金額｣
    ln_picking_charge      NUMBER; -- ｢ピッキング料｣
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
    ln_contract_rate       NUMBER; -- ｢契約運賃｣
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
    ln_charged_amount      NUMBER; -- 請求運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
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
-- ##### 20090410 Ver.1.5 本番#432対応 MOD START ##### 運賃マスタ・運賃用運送業者マスタの変更フラグによって、計算し直すかが異なるので、別プロシージャを作成
--    -- ｢差額｣｢合計｣｢混載割増金額｣｢ピッキング料｣の算出
--    cal_money_proc(
--      in_goods_classe        => ir_xd_ex_data.goods_classe,        -- 商品区分
--      in_mixed_code          => ir_xd_ex_data.mixed_code,          -- 混載区分
---- ##### 20080723 Ver.1.2 内部変更#132対応 START #####
--      in_charged_amount      => ir_xd_ex_data.charged_amount,      -- 請求運賃
---- ##### 20080723 Ver.1.2 内部変更#132対応 END   #####
--      in_shipping_expenses   => ir_xdc_ex_data.shipping_expenses,  -- 運送料
--      in_many_rate           => ir_xd_ex_data.many_rate,           -- 諸料金
--      in_leaf_consolid_add   => ir_xdc_ex_data.leaf_consolid_add,  -- リーフ混載割増
--      in_consolid_qty        => ir_xd_ex_data.consolid_qty,        -- 混載数
--      in_qty1                => ir_xd_ex_data.qty1,                -- 個数1
--      in_bill_picking_amount => ir_xd_ex_data.bill_picking_amount, -- 請求ピッキング単価
--      on_balance             => ln_balance,                     -- 差額
--      on_total_amount        => ln_total_amount,                -- 合計
--      on_consolid_surcharge  => ln_consolid_surcharge,          -- 混載割増金額
--      on_picking_charge      => ln_picking_charge,              -- ピッキング料
--      ov_errbuf              => lv_errbuf,                      -- エラー・メッセージ
--      ov_retcode             => lv_retcode,                     -- リターン・コード
--      ov_errmsg              => lv_errmsg);                     -- ユーザー・エラー・メッセージ
--
    -- 金額計算処理(洗替用)
    -- ｢差額｣｢合計｣｢混載割増金額｣｢ピッキング料｣｢契約運賃｣の算出
    cal_money_proc(
      ir_xd_ex_data          => ir_xd_ex_data,                  -- 洗替運賃ヘッダーアドオンレコード
      ir_xdc_ex_data         => ir_xdc_ex_data,                 -- 洗替運賃アドオンマスタレコード
      on_balance             => ln_balance,                     -- 差額
      on_total_amount        => ln_total_amount,                -- 合計
      on_consolid_surcharge  => ln_consolid_surcharge,          -- 混載割増金額
      on_picking_charge      => ln_picking_charge,              -- ピッキング料
      on_contract_rate       => ln_contract_rate,               -- 契約運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
      on_charged_amount      => ln_charged_amount,              -- 請求運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
      ov_errbuf              => lv_errbuf,                      -- エラー・メッセージ
      ov_retcode             => lv_retcode,                     -- リターン・コード
      ov_errmsg              => lv_errmsg);                     -- ユーザー・エラー・メッセージ
-- ##### 20090410 Ver.1.5 本番#432対応 MOD END   #####
    -- 処理結果チェック
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
      -- ***************************************
      -- *** 更新用PL/SQL表格納処理          ***
      -- ***************************************
--
      -- 更新テーブル索引インクリメント
      gn_ex_cnt := gn_ex_cnt + 1;
--
      tab_ex_delivery_no(gn_ex_cnt)        := ir_xd_ex_data.delivery_no;        -- 配送No
-- ##### 20090410 Ver.1.5 本番#432対応 MOD START #####
--      tab_ex_contract_rate(gn_ex_cnt)      := ir_xdc_ex_data.shipping_expenses; -- 契約運賃
      tab_ex_contract_rate(gn_ex_cnt)      := ln_contract_rate;                 -- 契約運賃
-- ##### 20090410 Ver.1.5 本番#432対応 MOD END   #####
      tab_ex_balance(gn_ex_cnt)            := ln_balance;                       -- 差額
      tab_ex_total_amount(gn_ex_cnt)       := ln_total_amount;                  -- 合計
      tab_ex_consolid_surcharge(gn_ex_cnt) := ln_consolid_surcharge;            -- 混載割増金額
      tab_ex_picking_charge(gn_ex_cnt)     := ln_picking_charge;                -- ピッキング料
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
      tab_ex_charged_amount(gn_ex_cnt)     := ln_charged_amount;                -- 請求運賃(契約運賃で洗替)
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
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
  END set_xd_exchange_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_xd_exchange_proc
   * Description      : 洗替運賃ヘッダアドオン一括更新処理(D-14)
   ***********************************************************************************/
  PROCEDURE upd_xd_exchange_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xd_exchange_proc'; -- プログラム名
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
    FORALL ln_index IN tab_ex_delivery_no.FIRST .. tab_ex_delivery_no.LAST
      UPDATE xxwip_deliverys
      SET    contract_rate          = tab_ex_contract_rate(ln_index),      -- 契約運賃
             balance                = tab_ex_balance(ln_index),            -- 差額
             total_amount           = tab_ex_total_amount(ln_index),       -- 合計
             consolid_surcharge     = tab_ex_consolid_surcharge(ln_index), -- 混載割増金額
             picking_charge         = tab_ex_picking_charge(ln_index),     -- ピッキング料
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD START #####
             charged_amount         = tab_ex_charged_amount(ln_index),     -- 請求運賃
-- ##### 20090501 Ver.1.6 本番#432(指摘5)対応 ADD END   #####
             last_updated_by        = gn_user_id,               -- 最終更新者
             last_update_date       = gd_sysdate,               -- 最終更新日
             last_update_login      = gn_login_id,              -- 最終更新ログイン
             request_id             = gn_conc_request_id,       -- 要求ID
             program_application_id = gn_prog_appl_id,          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             program_id             = gn_conc_program_id,       -- コンカレント・プログラムID
             program_update_date    = gd_sysdate                -- プログラム更新日
      WHERE  p_b_classe             = gv_paycharge_type_2
      AND    delivery_no            = tab_ex_delivery_no(ln_index);
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
  END upd_xd_exchange_proc;
--
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START ##### 洗替処理が完了したので、マスタの変更フラグをOFFにする。
  /**********************************************************************************
   * Procedure Name   : upd_xdc_mst_proc
   * Description      : 運賃マスタ・運賃用運送業者マスタ更新処理(D-15)
   ***********************************************************************************/
  PROCEDURE upd_xdc_mst_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xdc_mst_proc'; -- プログラム名
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 運賃用運送業者アドオンマスタ請求変更フラグをOFFに変更
    UPDATE xxwip_delivery_company xdco                             -- 運賃用運送業者アドオンマスタ
    SET    xdco.bill_change_flg        = gv_change_flg_off         -- 請求変更フラグ:OFF
          ,xdco.last_updated_by        = gn_user_id                -- 最終更新者
          ,xdco.last_update_date       = gd_sysdate                -- 最終更新日
          ,xdco.last_update_login      = gn_login_id               -- 最終更新ログイン
          ,xdco.request_id             = gn_conc_request_id        -- 要求ID
          ,xdco.program_application_id = gn_prog_appl_id           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,xdco.program_id             = gn_conc_program_id        -- コンカレント・プログラムID
          ,xdco.program_update_date    = gd_sysdate                -- プログラム更新日
    WHERE  xdco.bill_change_flg        = gv_change_flg_on          -- 請求変更フラグ:ON
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    AND    xdco.goods_classe           = gv_prod_div               -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
    ;
--
    -- 運賃アドオンマスタ変更フラグをOFFに変更
    UPDATE xxwip_delivery_charges xdch                             -- 運賃アドオンマスタ
    SET    xdch.change_flg             = gv_change_flg_off         -- 変更フラグ:OFF
          ,xdch.last_updated_by        = gn_user_id                -- 最終更新者
          ,xdch.last_update_date       = gd_sysdate                -- 最終更新日
          ,xdch.last_update_login      = gn_login_id               -- 最終更新ログイン
          ,xdch.request_id             = gn_conc_request_id        -- 要求ID
          ,xdch.program_application_id = gn_prog_appl_id           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,xdch.program_id             = gn_conc_program_id        -- コンカレント・プログラムID
          ,xdch.program_update_date    = gd_sysdate                -- プログラム更新日
    WHERE  xdch.change_flg             = gv_change_flg_on          -- 変更フラグ:ON
    AND    xdch.p_b_classe             = gv_paycharge_type_2       -- 支払請求区分:請求
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    AND    xdch.goods_classe           = gv_prod_div               -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
    ;
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
  END upd_xdc_mst_proc;
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exchange_type  IN         VARCHAR2,     -- 洗替区分
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
    iv_prod_div       IN         VARCHAR2,     -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
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
    gn_ins_cnt     := 0;
    gn_upd_cnt     := 0;
    gn_ex_cnt      := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =========================================
    -- パラメータチェック処理(D-1)
    -- =========================================
    chk_param_proc(
      iv_exchange_type,  -- 洗替区分
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 関連データ取得(D-2)
    -- =========================================
    get_init(
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
      iv_prod_div,       -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 運賃用締日情報取得(D-3)
    -- =========================================
    chk_close_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ロック取得(D-4)
    -- =========================================
    get_lock_xd(
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
      iv_exchange_type,  -- 洗替区分
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 洗替区分による処理の分岐(Y:洗替処理, N:通常処理)
    IF (iv_exchange_type = gv_ktg_no) THEN
      --*********************************************
      --***               通常処理                ***
      --*********************************************
--
      -- =========================================
      -- 運賃ヘッダアドオン抽出(D-5)
      -- =========================================
      get_xd_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 抽出データが１件でも存在する場合、D-6～D-9の処理を実施
      IF (gt_extraction_xd.EXISTS(1) = TRUE) THEN
        -- 抽出データが無くなるまでPL/SQL表格納処理を実施
        <<set_xd_tab_loop>>
        FOR ln_index IN gt_extraction_xd.FIRST .. gt_extraction_xd.LAST LOOP
--
          -- =========================================
          -- 運賃アドオンマスタ抽出(D-6)
          -- =========================================
          get_xdc_data(
            gt_extraction_xd(ln_index),   -- 運賃ヘッダーアドオンレコード
            lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
            lv_retcode,                   -- リターン・コード             --# 固定 #
            lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- =========================================
          -- 運賃ヘッダアドオンPL/SQL表格納(D-7)
          -- =========================================
          set_xd_data(
            gt_extraction_xd(ln_index),   -- 運賃ヘッダーアドオンレコード
            gr_extraction_xdc,            -- 運賃アドオンマスタレコード
            lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
            lv_retcode,                   -- リターン・コード             --# 固定 #
            lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP set_xd_tab_loop;
--
        -- =========================================
        -- 運賃ヘッダアドオン一括登録処理(D-8)
        -- =========================================
        ins_xd_proc(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =========================================
        -- 運賃ヘッダアドオン一括更新処理(D-9)
        -- =========================================
        upd_xd_proc(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- =========================================
      -- 運賃計算用コントロール更新処理(D-10)
      -- =========================================
      upd_calc_ctrl_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSIF (iv_exchange_type = gv_ktg_yes) THEN
--
      -- =========================================
      -- 洗替運賃ヘッダアドオン抽出(D-11)
      -- =========================================
      get_xd_exchange_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 抽出データが１件でも存在する場合、D-12～D-14の処理を実施
      IF (gt_extraction_ex_xd.EXISTS(1) = TRUE) THEN
        -- 抽出データが無くなるまでPL/SQL表格納処理を実施
        <<set_ex_xd_tab_loop>>
        FOR ln_index IN gt_extraction_ex_xd.FIRST .. gt_extraction_ex_xd.LAST LOOP
--
          -- =========================================
          -- 洗替運賃アドオンマスタ抽出(D-12)
          -- =========================================
          get_xdc_exchange_data(
            gt_extraction_ex_xd(ln_index),   -- 洗替運賃ヘッダーアドオンレコード
            lv_errbuf,                       -- エラー・メッセージ           --# 固定 #
            lv_retcode,                      -- リターン・コード             --# 固定 #
            lv_errmsg);                      -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START ##### マスタの変更区分がONの場合のみ、更新。
          IF ( (gt_extraction_ex_xd(ln_index).bill_change_flg = gv_change_flg_on)   -- 運賃用運送業者マスタ 請求変更フラグがON
            OR (gr_extraction_ex_xdc.shipping_change_flg      = gv_change_flg_on)   -- 運賃マスタ(運送費) 変更フラグがON
            OR (gr_extraction_ex_xdc.leaf_change_flg          = gv_change_flg_on) ) -- 運賃マスタ(リーフ混載割増) 変更フラグがON
          THEN
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
            -- =========================================
            -- 洗替運賃ヘッダアドオンPL/SQL表格納(D-13)
            -- =========================================
            set_xd_exchange_data(
              gt_extraction_ex_xd(ln_index),   -- 洗替運賃ヘッダーアドオンレコード
              gr_extraction_ex_xdc,            -- 洗替運賃アドオンマスタレコード
              lv_errbuf,                       -- エラー・メッセージ           --# 固定 #
              lv_retcode,                      -- リターン・コード             --# 固定 #
              lv_errmsg);                      -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START #####
          END IF;
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
--
        END LOOP set_ex_xd_tab_loop;
--
        -- =========================================
        -- 洗替運賃ヘッダアドオン一括更新処理(D-14)
        -- =========================================
        upd_xd_exchange_proc(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
-- ##### 20090410 Ver.1.5 本番#432対応 ADD START ##### 洗替処理が完了したので、マスタの変更フラグをOFFにする。
      -- =========================================
      -- 運賃マスタ・運賃用運送業者マスタ更新処理(D-15)
      -- =========================================
      upd_xdc_mst_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- ##### 20090410 Ver.1.5 本番#432対応 ADD END   #####
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
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
--    iv_exchange_type  IN         VARCHAR2       --   洗替区分
    iv_exchange_type  IN         VARCHAR2,               --   洗替区分
    iv_prod_div       IN         VARCHAR2  DEFAULT NULL  --   商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
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
--###########################  固定部 END   #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
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
      iv_exchange_type,  -- 洗替区分
-- ##### Ver.1.7 E_本稼動_13659対応 START #####
      iv_prod_div,       -- 商品区分
-- ##### Ver.1.7 E_本稼動_13659対応 END   #####
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
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =========================================
    -- メッセージ出力(D-16)
    -- =========================================
    -- 1.運賃ヘッダアドオン処理件数メッセージ
    lv_message := xxcmn_common_pkg.get_msg(gv_msg_kbn_wip, gv_msg_wip_00010);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_message);
--
    -- 2.成功件数出力
    lv_message := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_cmn_00009,
                                           gv_tkn_cnt,
                                           TO_CHAR(gn_ins_cnt + gn_upd_cnt + gn_ex_cnt));
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
END xxwip730002c;
/
