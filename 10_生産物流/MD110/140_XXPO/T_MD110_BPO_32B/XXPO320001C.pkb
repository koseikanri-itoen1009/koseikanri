create or replace PACKAGE BODY xxpo320001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo320001c(body)
 * Description      : 直送仕入・出荷実績作成処理
 * MD.050           : 仕入先出荷実績         T_MD050_BPO_320
 * MD.070           : 直送仕入・出荷実績作成 T_MD070_BPO_32B
 * Version          : 1.21
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ins_rcv_transactions   受入取引オープンIFの作成
 *  get_open_rcv_if        受入オープンIFの受入訂正データ取得
 *  get_open_deli_if       受入オープンIFの搬送訂正データ取得
 *  mod_open_rcv_if        受入オープンIFの受入訂正用データの作成
 *  mod_open_deli_if       受入オープンIFの搬送訂正用データの作成
 *  proc_xxpo_rcv_ins      受入返品実績(アドオン)の作成処理
 *  proc_rcv_if            受入オープンインタフェースの作成処理
 *  set_req_status         出荷依頼/支給依頼ステータスの設定
 *  check_quantity         仕入先出荷数量のチェック
 *  parameter_check        パラメータチェック                           (B-2)
 *  get_rcv_data           受入実績作成対象データ取得                   (B-3)
 *  keep_rcv_data          受入実績情報保持                             (B-4)
 *  set_rcv_data           受入実績情報登録                             (B-5)
 *  check_deli_pat         出荷実績作成パターン判定                     (B-6)
 *  get_new_data           出荷実績作成対象データ取得(新規登録用)       (B-7)
 *  keep_new_data          出荷実績情報保持(新規登録用)                 (B-8)
 *  ins_xxpo_data          受注アドオン情報 更新(新規登録用)            (B-9)
 *  upd_xxpo_data          受注ヘッダアドオン情報 更新
 *                          (最新データを訂正前データに変更)            (B-10)
 *  mod_xxpo_data          受注アドオン情報 登録(訂正データ登録)        (B-11)
 *  get_mod_data           出荷実績数量更新用データ取得(訂正用)         (B-12)
 *  keep_mod_data          出荷実績情報保持(訂正用)                     (B-13)
 *  upd_quantity_data      出荷実績数量 更新(訂正用)                    (B-14)
 *  proc_rcv_exec          受入取引処理起動                             (B-15)
 *  proc_deli_exec         出荷依頼/出荷実績作成処理起動                (B-16)
 *  disp_report            処理結果情報出力                             (B-17)
 *  create_mov_lot         移動ロット詳細作成(新規登録用)               (B-18)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/18    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/16    1.1   Oracle 山根 一浩 変更要求No.58 対応
 *  2008/05/14    1.2   Oracle 山根 一浩 変更要求No.90 対応
 *  2008/05/14    1.3   Oracle 山根 一浩 変更要求No.77 対応
 *  2008/05/22    1.4   Oracle 山根 一浩 変更要求No109対応
 *                                       結合テスト不具合ログ#300_3対応
 *  2008/05/24    1.5   Oracle 高山 洋平 結合テスト不具合ログ##320_3,320_4対応
 *  2008/05/26    1.6   Oracle 山根 一浩 変更要求No120対応
 *  2008/06/11    1.7   Oracle 山根 一浩 不具合ログ#440_63対応
 *  2008/10/24    1.8   Oracle 吉元 強樹 内部変更No174対応
 *  2008/12/04    1.9   Oracle 吉元 強樹 本番障害No420対応
 *  2008/12/06    1.10  Oracle 伊藤 ひとみ 本番障害No528対応
 *  2008/12/15    1.11  Oracle 北寒寺 正夫 本番障害No648対応
 *  2008/12/19    1.12  Oracle 二瓶 大輔 本番障害No648再対応
 *  2008/12/30    1.13  Oracle 吉元 強樹 標準-ｱﾄﾞｵﾝ受入差異対応
 *  2009/01/08    1.14  Oracle 吉元 強樹 受入明細番号採番不備対応
 *  2009/01/13    1.15  Oracle 吉元 強樹 受入明細番号採番不備対応
 *  2009/01/15    1.16  Oracle 吉元 強樹 標準-ｱﾄﾞｵﾝ受入差異対応(訂正処理不備)
 *  2009/03/30    1.17  Oracle 飯田 甫   本番障害No1346対応
 *  2009/09/17    1.18  SCS    吉元 強樹 本番障害No1632対応
 *  2009/12/02    1.19  SCS    吉元 強樹 本稼動障害#263
 *  2011/06/07    1.20  SCS    窪 和重   本稼動障害#1786
 *  2012/03/06    1.21  SCSK   中村 健一 本稼動障害#9118
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
  gn_group_id_cnt  NUMBER := 0;               -- GROUP_ID(カウント)
-- 2009/01/15 v1.16 T.Yoshimoto Add End
-- 2011/06/07 v1.20 K.Kubo Add Start E_本稼動_01786
  gn_po_header_id  po_headers_all.po_header_id%TYPE;  -- 発注ヘッダID
-- 2011/06/07 v1.20 K.Kubo Add End
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
  keep_new_data_expt    EXCEPTION;              -- 出荷実績情報保持エラー
  keep_mod_data_expt    EXCEPTION;              -- 出荷実績情報保持(訂正)エラー
  lock_expt             EXCEPTION;              -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- メッセージ用定数
  gv_pkg_name         CONSTANT VARCHAR2(15) := 'xxpo320001c';       -- パッケージ名
  gv_app_name         CONSTANT VARCHAR2(5)  := 'XXPO';              -- アプリケーション短縮名
--
  -- トークン
  gv_tkn_para_name       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  gv_tkn_po_num          CONSTANT VARCHAR2(20) := 'PO_NUM';
  gv_tkn_conc_id         CONSTANT VARCHAR2(20) := 'CONC_ID';
  gv_tkn_conc_name       CONSTANT VARCHAR2(20) := 'CONC_NAME';
  gv_tkn_count_1         CONSTANT VARCHAR2(20) := 'COUNT_1';
  gv_tkn_count_2         CONSTANT VARCHAR2(20) := 'COUNT_2';
  gv_tkn_item_cd         CONSTANT VARCHAR2(20) := 'ITEM_CD';
  gv_tkn_request_num     CONSTANT VARCHAR2(20) := 'REQUEST_NUM';
  gv_tkn_table_num       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  gv_tkn_target_count_1  CONSTANT VARCHAR2(20) := 'TARGET_COUNT_1';
  gv_tkn_target_count_2  CONSTANT VARCHAR2(20) := 'TARGET_COUNT_2';
--
  -- ユーザー定数
  gn_mode_oth            CONSTANT NUMBER       := 0;
  gn_mode_ins            CONSTANT NUMBER       := 1;
  gn_mode_upd            CONSTANT NUMBER       := 2;
  gn_lot_ctl_on          CONSTANT NUMBER       := 1;
  gv_flg_on              CONSTANT VARCHAR2(1)  := 'Y';
  gv_flg_off             CONSTANT VARCHAR2(1)  := 'N';
  gv_req_status_rect     CONSTANT VARCHAR2(2)  := '07';                     -- 受領済
  gv_req_status_appr     CONSTANT VARCHAR2(2)  := '08';                     -- 出荷実績計上済
  gv_txns_type           CONSTANT VARCHAR2(30) := '1';
  gv_trans_type_receive  CONSTANT VARCHAR2(20) := 'RECEIVE';
  gv_trans_type_correct  CONSTANT VARCHAR2(20) := 'CORRECT';
  gv_dest_type_receive   CONSTANT VARCHAR2(20) := 'RECEIVING';
  gv_trans_type_deliver  CONSTANT VARCHAR2(20) := 'DELIVER';
  gv_dest_type_inv       CONSTANT VARCHAR2(20) := 'INVENTORY';
--
  -- 要求セット
  gv_request_set_name    CONSTANT VARCHAR2(50) := 'XXPO320001Q';
  gv_request_name        CONSTANT VARCHAR2(50) := '直送仕入・出荷実績作成処理 要求セット';
--
  -- 受入取引処理
  gv_rcv_app             CONSTANT VARCHAR2(50) := 'PO';
  gv_rcv_stage           CONSTANT VARCHAR2(50) := 'STAGE10';
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
  gv_rcv_stage2          CONSTANT VARCHAR2(50) := 'STAGE20';
-- 2009/01/15 v1.16 T.Yoshimoto Add End
  gv_rcv_app_name        CONSTANT VARCHAR2(50) := 'RVCTP';
--
  -- 出荷依頼/出荷実績作成処理
  gv_deli_app            CONSTANT VARCHAR2(50) := 'XXWSH';
  gv_deli_stage          CONSTANT VARCHAR2(50) := 'STAGE20';
  gv_deli_app_name       CONSTANT VARCHAR2(50) := 'XXWSH420001C';
--
  gv_document_type       CONSTANT VARCHAR2(2)  := '30';    -- 支給指示
  gv_record_type         CONSTANT VARCHAR2(2)  := '20';    -- 出庫実績
  gv_indicate            CONSTANT VARCHAR2(2)  := '10';    -- 指示
  gv_qty_fixed_type      CONSTANT VARCHAR2(2)  := '30';    -- 数量確定済
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- B-3:受入実績作成対象データ
  TYPE masters_rec IS RECORD(
    po_header_number      po_headers_all.segment1%TYPE,                        -- 発注番号
    po_header_id          po_headers_all.po_header_id%TYPE,                    -- 発注ヘッダID
    vendor_id             po_headers_all.vendor_id%TYPE,                       -- 仕入先ID
    pha_def5              po_headers_all.attribute5%TYPE,                      -- 納入先コード
    attribute9            po_headers_all.attribute9%TYPE,                      -- 依頼番号
    attribute4            po_headers_all.attribute4%TYPE,                      -- 納入日
    h_attribute10         po_headers_all.attribute10%TYPE,                     -- 部署コード
    h_attribute3          po_headers_all.attribute3%TYPE,                      -- 斡旋者ID
    po_line_id            po_lines_all.po_line_id%TYPE,                        -- 発注明細ID
    line_num              po_lines_all.line_num%TYPE,                          -- 明細番号
    item_id               po_lines_all.item_id%TYPE,                           -- 品目ID
    lot_no                po_lines_all.attribute1%TYPE,                        -- ロットNO
    pla_def5              po_lines_all.attribute5%TYPE,                        -- 仕入先出荷日
    attribute6            po_lines_all.attribute6%TYPE,                        -- 仕入先出荷数量
    unit_code             po_lines_all.unit_meas_lookup_code%TYPE,             -- 単位
    attribute10           po_lines_all.attribute10%TYPE,                       -- 発注単位
    -- 2008/05/24 UPD START Y.Takayama
    --pla_qty               po_lines_all.quantity%TYPE,                          -- 入数
    pla_qty               po_lines_all.attribute4%TYPE,                        -- 入数
    -- 2008/05/24 UPD END   Y.Takayama
    attribute7            po_lines_all.attribute7%TYPE,                        -- 受入数量
    source_doc_number     xxpo_rcv_and_rtn_txns.source_document_number%TYPE,   -- 元文書番号
    source_doc_line_num   xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE, -- 元文書明細番号
    xrt_qty               xxpo_rcv_and_rtn_txns.quantity%TYPE,                 -- 数量
    rcv_rtn_quantity      xxpo_rcv_and_rtn_txns.rcv_rtn_quantity%TYPE,         -- 受入返品数量
    conversion_factor     xxpo_rcv_and_rtn_txns.conversion_factor%TYPE,        -- 換算入数
    inv_location_id       xxcmn_item_locations_v.inventory_location_id%TYPE,   -- 保管場所ID
    segment1              xxcmn_vendors_v.segment1%TYPE,                       -- 仕入先番号
    item_no               xxcmn_item_mst_v.item_no%TYPE,                       -- 品目コード
    lot_id                ic_lots_mst.lot_id%TYPE,                             -- ロットID
    attribute1            rcv_shipment_lines.attribute1%TYPE,                  -- 取引ID
    drop_ship_type        po_headers_all.attribute6%TYPE,                      -- 直送区分
    unit_price            po_lines_all.attribute8%TYPE,                        -- 単価
    lot_ctl               xxcmn_item_mst_v.lot_ctl%TYPE,                       -- ロット
    expire_date           ic_lots_mst.expire_date%TYPE,                        -- ロット失効日
    item_idv              xxcmn_item_mst_v.item_id%TYPE,                       -- 品目ID
--
    category_id           rcv_shipment_lines.category_id%TYPE,
    unit_of_measure       rcv_transactions.unit_of_measure%TYPE,
    item_description      rcv_shipment_lines.item_description%TYPE,
    uom_code              rcv_transactions.uom_code%TYPE,
    shipment_header_id    rcv_shipment_lines.shipment_header_id%TYPE,
    shipment_line_id      rcv_shipment_lines.shipment_line_id%TYPE,
    primary_unit_of       rcv_transactions.primary_unit_of_measure%TYPE,
    vendor_site_id        rcv_transactions.vendor_site_id%TYPE,
    organization_id       rcv_transactions.organization_id%TYPE,
    subinventory          rcv_transactions.subinventory%TYPE,
    routing_header_id     rcv_shipment_lines.routing_header_id%TYPE,
    po_line_location_id   rcv_shipment_lines.po_line_location_id%TYPE,
    po_unit_price         rcv_transactions.po_unit_price%TYPE,
    currency_code         rcv_transactions.currency_code%TYPE,
    currency_conv_rate    rcv_transactions.currency_conversion_rate%TYPE,
    po_distribution_id    rcv_shipment_lines.po_distribution_id%TYPE,
    locator_id            rcv_transactions.locator_id%TYPE,
    transaction_id        rcv_transactions.transaction_id%TYPE,
--
    trans_type            rcv_transactions_interface.transaction_type%TYPE,    -- 取引タイプ
    conv_factor           xxpo_rcv_and_rtn_txns.conversion_factor%TYPE,        -- 換算入数
    assen_vendor_id       xxpo_rcv_and_rtn_txns.assen_vendor_id%TYPE,          -- 斡旋者ID
    assen_vendor_code     xxpo_rcv_and_rtn_txns.assen_vendor_code%TYPE,        -- 斡旋者コード
    rcv_qty               NUMBER,                                   -- 受入数量
    rcv_cov_qty           NUMBER,                                   -- 受入数量差分
    def_date4             DATE,
    def_date5             DATE,
    def_qty6              NUMBER,
    def_qty7              NUMBER,
--
    exec_flg              NUMBER                                    -- 処理フラグ
  );
--
  -- 受入オープンインタフェース用
  TYPE mst_b_5_rec IS RECORD(
    category_id               rcv_shipment_lines.category_id%TYPE,
    unit_of_measure           rcv_shipment_lines.unit_of_measure%TYPE,
    item_description          rcv_shipment_lines.item_description%TYPE,
    uom_code                  rcv_transactions.uom_code%TYPE,
    shipment_header_id        rcv_shipment_lines.shipment_header_id%TYPE,
    shipment_line_id          rcv_shipment_lines.shipment_line_id%TYPE,
    primary_unit_of_measure   rcv_transactions.primary_unit_of_measure%TYPE,
    vendor_site_id            rcv_transactions.vendor_site_id%TYPE,
    organization_id           rcv_transactions.organization_id%TYPE,
    subinventory              rcv_transactions.subinventory%TYPE,
    routing_header_id         rcv_shipment_lines.routing_header_id%TYPE,
    transaction_id            rcv_transactions.transaction_id%TYPE,
    po_line_location_id       rcv_shipment_lines.po_line_location_id%TYPE,
    po_unit_price             rcv_transactions.po_unit_price%TYPE,
    currency_code             rcv_transactions.currency_code%TYPE,
    currency_conversion_rate  rcv_transactions.currency_conversion_rate%TYPE,
    po_distribution_id        rcv_shipment_lines.po_distribution_id%TYPE,
    locator_id                rcv_transactions.locator_id%TYPE
  );
--
  -- 出荷実績作成対象データ
  TYPE mst_b_6_rec IS RECORD(
    po_header_id          po_headers_all.po_header_id%TYPE,
    order_header_id       xxwsh_order_headers_all.order_header_id%TYPE,
    req_status            xxwsh_order_headers_all.req_status%TYPE,
    actual_confirm_class  xxwsh_order_headers_all.actual_confirm_class%TYPE
  );
--
  -- 出荷実績作成対象データ(新規登録用)
  TYPE mst_b_7_rec IS RECORD(
    attribute6                   po_lines_all.attribute6%TYPE,
    attribute4                   po_headers_all.attribute4%TYPE,
    req_status                   xxwsh_order_headers_all.req_status%TYPE,
    actual_confirm_class         xxwsh_order_headers_all.actual_confirm_class%TYPE,
    career_id                    xxwsh_order_headers_all.career_id%TYPE,
    freight_carrier_code         xxwsh_order_headers_all.freight_carrier_code%TYPE,
    result_freight_carrier_id    xxwsh_order_headers_all.result_freight_carrier_id%TYPE,
    result_freight_carrier_code  xxwsh_order_headers_all.result_freight_carrier_code%TYPE,
    shipping_method_code         xxwsh_order_headers_all.shipping_method_code%TYPE,
    result_shipping_method_code  xxwsh_order_headers_all.result_shipping_method_code%TYPE,
    shipped_quantity             xxwsh_order_lines_all.shipped_quantity%TYPE,
    order_line_id                xxwsh_order_lines_all.order_line_id%TYPE,
    request_no                   xxwsh_order_lines_all.request_no%TYPE,
    item_no                      xxcmn_item_mst_v.item_no%TYPE,
--
    def_qty6                     NUMBER,
    def_date4                    DATE
  );
--
  -- 出荷実績作成対象データ(訂正用)
  TYPE mst_b_12_rec IS RECORD(
    attribute6                   po_lines_all.attribute6%TYPE,
    shipped_quantity             xxwsh_order_lines_all.shipped_quantity%TYPE,
    order_line_id                xxwsh_order_lines_all.order_line_id%TYPE,
    request_no                   xxwsh_order_lines_all.request_no%TYPE,
    item_no                      xxcmn_item_mst_v.item_no%TYPE,
    item_id                      po_lines_all.item_id%TYPE,
--
    def_qty6                     NUMBER
  );
--
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
  TYPE mst_group_id_rec IS RECORD(
    po_header_id                 po_headers_all.po_header_id%TYPE,     -- 発注ヘッダID
    po_line_id                   po_lines_all.po_line_id%TYPE,         -- 発注明細ID
    group_id                     NUMBER,                               -- グループID
    exec_flg                     NUMBER                                -- 処理フラグ
  );
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_5_tbl  IS TABLE OF mst_b_5_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_6_tbl  IS TABLE OF mst_b_6_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_7_tbl  IS TABLE OF mst_b_7_rec  INDEX BY PLS_INTEGER;
  TYPE mst_b_12_tbl IS TABLE OF mst_b_12_rec INDEX BY PLS_INTEGER;
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
  TYPE mst_group_id_tbl IS TABLE OF mst_group_id_rec INDEX BY PLS_INTEGER;
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
  gt_b_03_mast                masters_tbl;  -- 各マスタへ登録するデータ
  gt_b_05_mast                mst_b_5_tbl;  -- 各マスタへ登録するデータ
  gt_b_06_mast                mst_b_6_tbl;  -- 各マスタへ登録するデータ
  gt_b_07_mast                mst_b_7_tbl;  -- 各マスタへ登録するデータ
  gt_b_12_mast                mst_b_12_tbl; -- 各マスタへ登録するデータ
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
  gt_group_id_mast            mst_group_id_tbl; -- group_id
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_header_number            VARCHAR2(20);
  gn_person_id                fnd_user.employee_id%TYPE;
  gn_group_id                 NUMBER;                     -- グループID
  gn_group_id2                NUMBER;                     -- グループID
  gv_request_no               VARCHAR2(12);               -- 依頼NO
  gn_txns_id                  xxpo_rcv_and_rtn_txns.txns_id%TYPE;
  gv_defaultlot               VARCHAR2(100);              -- デフォルトロット
--
  -- 定数
  gn_created_by               NUMBER;                     -- 作成者
  gd_creation_date            DATE;                       -- 作成日
  gd_last_update_date         DATE;                       -- 最終更新日
  gn_last_update_by           NUMBER;                     -- 最終更新者
  gn_last_update_login        NUMBER;                     -- 最終更新ログイン
  gn_request_id               NUMBER;                     -- 要求ID
  gn_program_application_id   NUMBER;                     -- プログラムアプリケーションID
  gn_program_id               NUMBER;                     -- プログラムID
  gd_program_update_date      DATE;                       -- プログラム更新日
--
  gn_b_3_cnt                  NUMBER;
  gn_b_5_cnt                  NUMBER;
  gn_b_7_cnt                  NUMBER;
  gn_b_9_cnt                  NUMBER;
--
  gn_b_15_flg                 NUMBER;
  gn_b_16_flg                 NUMBER;
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR gc_lock_xrt_cur
  IS
    SELECT xrt.txns_id
    FROM   xxpo_rcv_and_rtn_txns xrt
    WHERE  xrt.source_document_number = gv_header_number
    FOR UPDATE OF xrt.txns_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : check_quantity
   * Description      : 仕入先出荷数量のチェック
   ***********************************************************************************/
  PROCEDURE check_quantity(
    or_retcd           OUT NOCOPY BOOLEAN,      -- チェック結果
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_quantity'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt              NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    or_retcd := TRUE;
--
    SELECT COUNT(pha.po_header_id)
    INTO   ln_cnt
    FROM   po_headers_all pha,                            -- 発注ヘッダ
           po_lines_all  pla                              -- 発注明細
    WHERE  pha.po_header_id = pla.po_header_id
    AND    pha.segment1     = gv_header_number
    AND    pla.attribute6 IS NULL                         -- 仕入先出荷数量が設定されていない
    AND    ROWNUM           = 1;
--
    IF (ln_cnt > 0) THEN
      or_retcd := FALSE;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END check_quantity;
--
  /***********************************************************************************
   * Procedure Name   : set_req_status
   * Description      : 出荷依頼/支給依頼ステータスの設定
   ***********************************************************************************/
  PROCEDURE set_req_status(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_status          OUT NOCOPY VARCHAR2,     -- 結果ステータス
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_req_status'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt              NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ov_status := gv_req_status_appr;                    -- 出荷実績計上済
--
    SELECT  COUNT(pha.po_header_id)
    INTO    ln_cnt
    FROM    po_headers_all pha               -- 発注ヘッダ
           ,po_lines_all pla                 -- 発注明細
    WHERE   pha.po_header_id = pla.po_header_id
    AND     pha.po_header_id = ir_masters_rec.po_header_id
    AND     pla.attribute6 IS NULL
    AND     ROWNUM = 1;
--
    IF (ln_cnt > 0) THEN
      ov_status := gv_req_status_rect;                    -- 受領済
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_req_status;
--
  /***********************************************************************************
   * Procedure Name   : ins_rcv_transactions
   * Description      : 受入取引オープンIFの作成
   ***********************************************************************************/
  PROCEDURE ins_rcv_transactions(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ir_mst_rec      IN OUT NOCOPY mst_b_5_rec,
    in_group_id     IN            NUMBER,
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
    ln_dest_type    IN            NUMBER,       -- 受入(0), 搬送(1)
-- 2008/12/30 v1.13 T.Yoshimoto Add End
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rcv_transactions'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_use_mtl_lot   rcv_transactions_interface.use_mtl_lot%TYPE;
    lv_dest_code     rcv_transactions_interface.destination_type_code%TYPE;
    lv_dest_text     rcv_transactions_interface.destination_context%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_use_mtl_lot := 1;
--
    -- ロット管理品
    IF (ir_masters_rec.lot_ctl = gn_lot_ctl_on) THEN
      ln_use_mtl_lot := 2;
    END IF;
--
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
    -- 受入訂正
--    IF (ir_masters_rec.rcv_cov_qty > 0) THEN
    IF (ln_dest_type = 0) THEN
-- 2008/12/30 v1.13 T.Yoshimoto Add End
      lv_dest_code := gv_dest_type_receive;
      lv_dest_text := gv_dest_type_receive;
--
    -- 搬送訂正
    ELSE
      lv_dest_code := gv_dest_type_inv;
      lv_dest_text := gv_dest_type_inv;
    END IF;
--
    -- 受入取引オープンIFの作成
    INSERT INTO rcv_transactions_interface
    (
         interface_transaction_id
        ,group_id
        ,last_update_date
        ,last_updated_by
        ,creation_date
        ,created_by
        ,last_update_login
        ,transaction_type
        ,transaction_date
        ,processing_status_code
        ,processing_mode_code
        ,transaction_status_code
        ,category_id
        ,quantity
        ,unit_of_measure
        ,item_id
        ,item_description
        ,uom_code
        ,employee_id
        ,shipment_header_id
        ,shipment_line_id
        ,primary_quantity
        ,primary_unit_of_measure
        ,receipt_source_code
        ,vendor_id
        ,vendor_site_id
        ,from_organization_id
        ,from_subinventory
        ,to_organization_id
        ,routing_header_id
        ,routing_step_id
        ,source_document_code
        ,parent_transaction_id
        ,po_header_id
        ,po_line_id
        ,po_line_location_id
        ,po_unit_price
        ,currency_code
        ,currency_conversion_rate
        ,po_distribution_id
        ,inspection_status_code
        ,destination_type_code
        ,locator_id
        ,destination_context
        ,use_mtl_lot
        ,use_mtl_serial
        ,from_locator_id
    )
    SELECT 
         rcv_transactions_interface_s.NEXTVAL              -- interface_transaction_id
        ,in_group_id                                       -- group_id
        ,gd_last_update_date                               -- last_update_date
        ,gn_last_update_by                                 -- last_updated_by
        ,gd_creation_date                                  -- creation_date
        ,gn_created_by                                     -- created_by
        ,gn_last_update_login                              -- last_update_login
        ,gv_trans_type_correct                             -- transaction_type
-- 2008/12/04 v1.9 T.Yoshimoto Mod Start 本番障害#420
        --,SYSDATE                                           -- transaction_date
        ,TO_DATE(ir_masters_rec.pla_def5, 'YYYY/MM/DD')    -- transaction_date(仕入先出荷日)
-- 2008/12/04 v1.9 T.Yoshimoto Mod End 本番障害#420
        ,'PENDING'                                         -- processing_status_code
        ,'BATCH'                                           -- processing_mode_code
        ,'PENDING'                                         -- transaction_status_code
        ,ir_mst_rec.category_id                            -- category_id
        ,ir_masters_rec.rcv_cov_qty                        -- quantity
        ,ir_mst_rec.unit_of_measure                        -- unit_of_measure
        ,ir_masters_rec.item_id                            -- item_id
        ,ir_mst_rec.item_description                       -- item_description
        ,ir_mst_rec.uom_code                               -- uom_code
        ,gn_person_id                                      -- employee_id
        ,ir_mst_rec.shipment_header_id                     -- shipment_header_id
        ,ir_mst_rec.shipment_line_id                       -- shipment_line_id
        -- 2008/05/24 UPD START Y.Takayama
        --,ir_masters_rec.def_qty7                           -- primary_quantity
        ,ir_masters_rec.rcv_cov_qty                        -- primary_quantity
        -- 2008/05/24 UPD END   Y.Takayama
        ,ir_mst_rec.primary_unit_of_measure                -- primary_unit_of_measure
        ,'VENDOR'                                          -- receipt_source_code
        ,ir_masters_rec.vendor_id                          -- vendor_id
        ,ir_mst_rec.vendor_site_id                         -- vendor_site_id
        ,ir_mst_rec.organization_id                        -- from_organization_id
        ,ir_mst_rec.subinventory                           -- from_subinventory
        ,ir_mst_rec.organization_id                        -- to_organization_id
        ,ir_mst_rec.routing_header_id                      -- routing_header_id
        ,1                                                 -- routing_step_id
        ,'PO'                                              -- source_document_code
        ,ir_mst_rec.transaction_id                         -- parent_transaction_id
        ,ir_masters_rec.po_header_id                       -- po_header_id
        ,ir_masters_rec.po_line_id                         -- po_line_id
        ,ir_mst_rec.po_line_location_id                    -- po_line_location_id
        ,ir_mst_rec.po_unit_price                          -- po_unit_price
        ,ir_mst_rec.currency_code                          -- currency_code
        ,ir_mst_rec.currency_conversion_rate               -- currency_conversion_rate
        ,ir_mst_rec.po_distribution_id                     -- po_distribution_id
        ,'NOT INSPECTED'                                   -- inspection_status_code
        ,lv_dest_code                                      -- destination_type_code
        ,ir_mst_rec.locator_id                             -- locator_id
        ,lv_dest_text                                      -- destination_context
        ,ln_use_mtl_lot                                    -- use_mtl_lot
        ,1                                                 -- use_mtl_serial
        ,ir_mst_rec.locator_id                             -- from_locator_id
    FROM DUAL;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END ins_rcv_transactions;
--
  /***********************************************************************************
   * Procedure Name   : get_open_deli_if
   * Description      : 受入オープンIFの搬送訂正用データの取得
   ***********************************************************************************/
  PROCEDURE get_open_deli_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ir_mst_rec      IN OUT NOCOPY mst_b_5_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_open_deli_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    SELECT rsl.category_id
          ,rsl.unit_of_measure
          ,rsl.item_description
          ,rt.uom_code
          ,rsl.shipment_header_id
          ,rsl.shipment_line_id
          ,rt.primary_unit_of_measure
          ,rt.vendor_site_id
          ,rt.organization_id
          ,rt.subinventory
          ,rsl.routing_header_id
          ,rt.transaction_id
          ,rsl.po_line_location_id
          ,rt.po_unit_price
          ,rt.currency_code
          ,rt.currency_conversion_rate
          ,rsl.po_distribution_id
          ,rt.locator_id
    INTO   ir_mst_rec.category_id
          ,ir_mst_rec.unit_of_measure
          ,ir_mst_rec.item_description
          ,ir_mst_rec.uom_code
          ,ir_mst_rec.shipment_header_id
          ,ir_mst_rec.shipment_line_id
          ,ir_mst_rec.primary_unit_of_measure
          ,ir_mst_rec.vendor_site_id
          ,ir_mst_rec.organization_id
          ,ir_mst_rec.subinventory
          ,ir_mst_rec.routing_header_id
          ,ir_mst_rec.transaction_id
          ,ir_mst_rec.po_line_location_id
          ,ir_mst_rec.po_unit_price
          ,ir_mst_rec.currency_code
          ,ir_mst_rec.currency_conversion_rate
          ,ir_mst_rec.po_distribution_id
          ,ir_mst_rec.locator_id
    FROM   rcv_shipment_lines rsl,
           rcv_transactions   rt
    WHERE  rt.transaction_type      = gv_trans_type_deliver
    AND    rt.destination_type_code = gv_dest_type_inv
    AND    rt.destination_context   = gv_dest_type_inv
    AND    rt.shipment_line_id      = rsl.shipment_line_id
    AND    rt.parent_transaction_id in
    (
     SELECT transaction_id 
     FROM   rcv_transactions
     WHERE  parent_transaction_id = -1
     AND    po_header_id          = ir_masters_rec.po_header_id
     AND    po_line_id            = ir_masters_rec.po_line_id
    );
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_open_deli_if;
--
  /***********************************************************************************
   * Procedure Name   : get_open_rcv_if
   * Description      : 受入オープンIFの受入訂正用データの取得
   ***********************************************************************************/
  PROCEDURE get_open_rcv_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ir_mst_rec      IN OUT NOCOPY mst_b_5_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_open_rcv_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    SELECT rsl.category_id
          ,rsl.unit_of_measure
          ,rsl.item_description
          ,rt.uom_code
          ,rsl.shipment_header_id
          ,rsl.shipment_line_id
          ,rt.primary_unit_of_measure
          ,rt.vendor_site_id
          ,rt.organization_id
          ,rt.subinventory
          ,rsl.routing_header_id
          ,rt.transaction_id
          ,rsl.po_line_location_id
          ,rt.po_unit_price
          ,rt.currency_code
          ,rt.currency_conversion_rate
          ,rsl.po_distribution_id
          ,rt.locator_id
    INTO   ir_mst_rec.category_id
          ,ir_mst_rec.unit_of_measure
          ,ir_mst_rec.item_description
          ,ir_mst_rec.uom_code
          ,ir_mst_rec.shipment_header_id
          ,ir_mst_rec.shipment_line_id
          ,ir_mst_rec.primary_unit_of_measure
          ,ir_mst_rec.vendor_site_id
          ,ir_mst_rec.organization_id
          ,ir_mst_rec.subinventory
          ,ir_mst_rec.routing_header_id
          ,ir_mst_rec.transaction_id
          ,ir_mst_rec.po_line_location_id
          ,ir_mst_rec.po_unit_price
          ,ir_mst_rec.currency_code
          ,ir_mst_rec.currency_conversion_rate
          ,ir_mst_rec.po_distribution_id
          ,ir_mst_rec.locator_id
    FROM   rcv_shipment_lines rsl,
           rcv_transactions rt
    WHERE  rt.parent_transaction_id = -1
    AND    rt.transaction_type      = gv_trans_type_receive
    AND    rt.destination_type_code = gv_dest_type_receive
    AND    rt.destination_context   = gv_dest_type_receive
    AND    rt.shipment_line_id      = rsl.shipment_line_id
    AND    rt.po_header_id          = ir_masters_rec.po_header_id
    AND    rt.po_line_id            = ir_masters_rec.po_line_id;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_open_rcv_if;
--
  /***********************************************************************************
   * Procedure Name   : mod_open_rcv_if
   * Description      : 受入オープンIFの受入訂正用データの作成
   ***********************************************************************************/
  PROCEDURE mod_open_rcv_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    in_group_id     IN            NUMBER,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mod_open_rcv_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_mst_rec       mst_b_5_rec;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受入訂正対象データ取得
    get_open_rcv_if(
      ir_masters_rec,
      lr_mst_rec,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 受入取引オープンIFの作成
    ins_rcv_transactions(
      ir_masters_rec,
      lr_mst_rec,
      in_group_id,
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
      0,                  -- 受入(0), 搬送(1)
-- 2008/12/30 v1.13 T.Yoshimoto Add End
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END mod_open_rcv_if;
--
  /***********************************************************************************
   * Procedure Name   : mod_open_deli_if
   * Description      : 受入オープンIFの搬送訂正用データの作成
   ***********************************************************************************/
  PROCEDURE mod_open_deli_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    in_group_id     IN            NUMBER,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mod_open_deli_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_mst_rec       mst_b_5_rec;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 搬送訂正対象データ取得
    get_open_deli_if(
      ir_masters_rec,
      lr_mst_rec,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 受入取引オープンIFの作成
    ins_rcv_transactions(
      ir_masters_rec,
      lr_mst_rec,
      in_group_id,
-- 2008/12/30 v1.13 T.Yoshimoto Add Start
      1,                  -- 受入(0), 搬送(1)
-- 2008/12/30 v1.13 T.Yoshimoto Add End
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ロット管理品
    IF (ir_masters_rec.lot_ctl = gn_lot_ctl_on) THEN
--
      -- 受入ロットオープンIFの作成
      INSERT INTO rcv_lots_interface
      (
           interface_transaction_id
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,lot_num
          ,quantity
          ,transaction_date
          ,expiration_date
          ,primary_quantity
          ,item_id
          ,shipment_line_id
      )
      SELECT
           rcv_transactions_interface_s.CURRVAL   -- interface_transaction_id
          ,gd_last_update_date                    -- last_update_date
          ,gn_last_update_by                      -- last_updated_by
          ,gd_creation_date                       -- creation_date
          ,gn_created_by                          -- created_by
          ,gn_last_update_login                   -- last_update_login
          ,ir_masters_rec.lot_no                  -- lot_num
          ,ABS(ir_masters_rec.rcv_cov_qty)        -- quantity
          ,SYSDATE                                -- transaction_date
          ,ir_masters_rec.expire_date             -- expiration_date
          -- 2008/05/24 UPD START Y.Takayama
          --,ABS(ir_masters_rec.def_qty7)           -- primary_quantity
          ,ABS(ir_masters_rec.rcv_cov_qty)          -- primary_quantity
          -- 2008/05/24 UPD END   Y.Takayama
          ,ir_masters_rec.item_id                 -- item_id
          ,lr_mst_rec.shipment_line_id            -- shipment_line_id
      FROM DUAL;
--
      -- INVロット取引オープンIFの作成
      INSERT INTO mtl_transaction_lots_interface
      (
           transaction_interface_id
          ,source_code
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,lot_number
          ,lot_expiration_date
          ,transaction_quantity
          ,primary_quantity
          ,process_flag
          ,product_code
          ,product_transaction_id
      )
      SELECT
           mtl_material_transactions_s.NEXTVAL    -- transaction_interface_id
          ,'RCV'                                  -- source_code
          ,gd_last_update_date                    -- last_update_date
          ,gn_last_update_by                      -- last_updated_by
          ,gd_creation_date                       -- creation_date
          ,gn_created_by                          -- created_by
          ,gn_last_update_login                   -- last_update_login
          ,ir_masters_rec.lot_no                  -- lot_number
          ,ir_masters_rec.expire_date             -- lot_expiration_date
          ,ABS(ir_masters_rec.rcv_cov_qty)        -- transaction_quantity
          -- 2008/05/24 UPD START Y.Takayama
          --,ABS(ir_masters_rec.def_qty7)         -- primary_quantity
          ,ABS(ir_masters_rec.rcv_cov_qty)        -- primary_quantity
          -- 2008/05/24 UPD START Y.Takayama
          ,'1'                                    -- process_flag
          ,'RCV'                                  -- product_code
          ,rcv_transactions_interface_s.CURRVAL   -- product_transaction_id
      FROM DUAL;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END mod_open_deli_if;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxpo_rcv_ins
   * Description      : 受入返品実績(アドオン)の作成処理
   ***********************************************************************************/
  PROCEDURE proc_xxpo_rcv_ins(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxpo_rcv_ins'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_segment1                po_vendors.segment1%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 取引先コードの取得
    BEGIN
      SELECT pv.segment1
      INTO   lv_segment1
      FROM   po_vendors pv
      WHERE  pv.vendor_id = ir_masters_rec.vendor_id
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_segment1 := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 受入返品実績(アドオン)の作成
    INSERT INTO xxpo_rcv_and_rtn_txns
    (
         txns_id
        ,txns_type
        ,rcv_rtn_number
        ,rcv_rtn_line_number
        ,source_document_number
        ,source_document_line_num
        ,supply_requested_number
        ,drop_ship_type
        ,vendor_id
        ,vendor_code
        ,assen_vendor_id
        ,assen_vendor_code
        ,location_id
        ,location_code
        ,txns_date
        ,item_id
        ,item_code
        ,lot_id
        ,lot_number
        ,rcv_rtn_quantity
        ,rcv_rtn_uom
        ,quantity
        ,uom
        ,conversion_factor
        ,unit_price
        ,department_code
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
    )
    SELECT
         gn_txns_id                                      -- txns_id
        ,gv_txns_type                                    -- txns_type
        ,ir_masters_rec.po_header_number                 -- rcv_rtn_number
-- 2009/01/13 v1.15 T.Yoshimoto Mod Start
        --,ir_masters_rec.line_num                         -- rcv_rtn_line_number
        ,'1'                                             -- rcv_rtn_line_number
-- 2009/01/13 v1.15 T.Yoshimoto Mod End
        ,ir_masters_rec.po_header_number                 -- source_document_number
-- 2009/01/13 v1.15 T.Yoshimoto Mod Start
-- 2009/01/08 v1.14 T.Yoshimoto Mod Start
        ,ir_masters_rec.line_num                         -- source_document_line_num
        --,'1'                                             -- source_document_line_num
-- 2009/01/08 v1.14 T.Yoshimoto Mod End
-- 2009/01/13 v1.15 T.Yoshimoto Mod End
        ,ir_masters_rec.attribute9                       -- supply_requested_number
        ,ir_masters_rec.drop_ship_type                   -- drop_ship_type
        ,ir_masters_rec.vendor_id                        -- vendor_id
        ,lv_segment1                                     -- vendor_code
        ,ir_masters_rec.assen_vendor_id                  -- assen_vendor_id
        ,ir_masters_rec.assen_vendor_code                -- assen_vendor_code
        ,ir_masters_rec.inv_location_id                  -- location_id
        ,ir_masters_rec.pha_def5                         -- location_code
        ,ir_masters_rec.def_date5                        -- txns_date
        ,ir_masters_rec.item_idv                         -- item_id
        ,ir_masters_rec.item_no                          -- item_code
        ,ir_masters_rec.lot_id                           -- lot_id
        ,ir_masters_rec.lot_no                           -- lot_number
        ,ir_masters_rec.def_qty6                         -- rcv_rtn_quantity
        ,ir_masters_rec.attribute10                      -- rcv_rtn_uom
        ,ir_masters_rec.rcv_qty                          -- quantity
        ,ir_masters_rec.unit_code                        -- uom
        ,ir_masters_rec.conv_factor                      -- conversion_factor
        ,ir_masters_rec.unit_price                       -- unit_price
        ,ir_masters_rec.h_attribute10                    -- department_code
        ,gn_created_by                                   -- created_by
        ,gd_creation_date                                -- creation_date
        ,gn_last_update_by                               -- last_updated_by
        ,gd_last_update_date                             -- last_update_date
        ,gn_last_update_login                            -- last_update_login
        ,gn_request_id                                   -- request_id
        ,gn_program_application_id                       -- program_application_id
        ,gn_program_id                                   -- program_id
        ,gd_program_update_date                          -- program_update_date
    FROM DUAL;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_xxpo_rcv_ins;
--
  /***********************************************************************************
   * Procedure Name   : create_mov_lot
   * Description      : 移動ロット詳細作成(新規登録用)(B-18)
   ***********************************************************************************/
  PROCEDURE create_mov_lot(
    ir_mst_b_7_rec  IN OUT NOCOPY mst_b_7_rec,  -- B-7:出荷実績作成対象データ取得
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_mov_lot'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_mov_lot    xxinv_mov_lot_details%ROWTYPE;
    ln_flg        NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- 1.実績日の更新
    BEGIN
      UPDATE xxinv_mov_lot_details
      SET    actual_date            = ir_mst_b_7_rec.def_date4
            ,last_updated_by        = gn_last_update_by
            ,last_update_date       = gd_last_update_date
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  mov_line_id        = ir_mst_b_7_rec.order_line_id
      AND    document_type_code = gv_document_type           -- 支給指示
      AND    record_type_code   = gv_record_type;            -- 出庫実績
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 2.移動ロット詳細(アドオン)から出庫情報の取得
    ln_flg := 1;
    BEGIN
      SELECT xmld.mov_lot_dtl_id                          -- ロット詳細ID
            ,xmld.actual_quantity                         -- 実績数量
      INTO   lr_mov_lot.mov_lot_dtl_id
            ,lr_mov_lot.actual_quantity
      FROM   xxinv_mov_lot_details xmld
      WHERE  xmld.mov_line_id        = ir_mst_b_7_rec.order_line_id
      AND    xmld.document_type_code = gv_document_type           -- 支給指示
      AND    xmld.record_type_code   = gv_record_type;            -- 出庫実績
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_flg := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 3.出庫情報が存在する場合、出庫情報を更新
    IF (ln_flg = 1) THEN
--
      BEGIN
        UPDATE xxinv_mov_lot_details
        SET    actual_quantity        = ir_mst_b_7_rec.def_qty6   -- 実績数量
              ,last_updated_by        = gn_last_update_by
              ,last_update_date       = gd_last_update_date
              ,last_update_login      = gn_last_update_login
              ,request_id             = gn_request_id
              ,program_application_id = gn_program_application_id
              ,program_id             = gn_program_id
              ,program_update_date    = gd_program_update_date
        WHERE mov_lot_dtl_id = lr_mov_lot.mov_lot_dtl_id
        AND   actual_quantity <> ir_mst_b_7_rec.def_qty6;        -- 仕入先出荷数量 <> 実績数量
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
    -- 4.出庫情報が存在しない場合、出庫情報を作成
    ELSE
--
      INSERT INTO xxinv_mov_lot_details
      (
         mov_lot_dtl_id                                  -- ロット詳細ID
        ,mov_line_id                                     -- 明細ID
        ,document_type_code                              -- 文書タイプ
        ,record_type_code                                -- レコードタイプ
        ,item_id                                         -- OPM品目ID
        ,item_code                                       -- 品目
        ,lot_id                                          -- ロットID
        ,lot_no                                          -- ロットNo
        ,actual_date                                     -- 実績日
        ,actual_quantity                                 -- 実績数量
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT xxinv_mov_lot_s1.NEXTVAL                        -- mov_lot_dtl_id
            ,mov_line_id                                     -- 明細ID
            ,document_type_code                              -- 文書タイプ
            ,gv_record_type                                  -- レコードタイプ
            ,item_id                                         -- OPM品目ID
            ,item_code                                       -- 品目
            ,lot_id                                          -- ロットID
            ,lot_no                                          -- ロットNo
            ,ir_mst_b_7_rec.def_date4                        -- 実績日
            ,ir_mst_b_7_rec.def_qty6                         -- 実績数量
            ,gn_created_by                                   -- created_by
            ,gd_creation_date                                -- creation_date
            ,gn_last_update_by                               -- last_updated_by
            ,gd_last_update_date                             -- last_update_date
            ,gn_last_update_login                            -- last_update_login
            ,gn_request_id                                   -- request_id
            ,gn_program_application_id                       -- program_application_id
            ,gn_program_id                                   -- program_id
            ,gd_program_update_date                          -- program_update_date
      FROM   xxinv_mov_lot_details
      WHERE  mov_line_id        = ir_mst_b_7_rec.order_line_id
      AND    document_type_code = gv_document_type           -- 支給指示
      AND    record_type_code   = gv_indicate;               -- 指示
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_mov_lot;
--
  /***********************************************************************************
   * Procedure Name   : proc_rcv_exec
   * Description      : 受入取引処理起動(B-15)
   ***********************************************************************************/
  PROCEDURE proc_rcv_exec(
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
    in_group_id    IN         NUMBER,       -- グループID
    iv_rcv_stage   IN         VARCHAR2,     -- 要求セット.ステージ
-- 2009/01/15 v1.16 T.Yoshimoto Add End
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_rcv_exec'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_ret        BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 要求セットの設定
    lb_ret := FND_SUBMIT.SUBMIT_PROGRAM(gv_rcv_app,
                                        gv_rcv_app_name,
-- 2009/01/15 v1.16 T.Yoshimoto Mod Start
                                        --gv_rcv_stage,
                                        iv_rcv_stage,
                                        'BATCH',
                                        --TO_CHAR(gn_group_id));
                                        TO_CHAR(in_group_id));
-- 2009/01/15 v1.16 T.Yoshimoto Mod End
--
    IF (NOT lb_ret) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10024',
                                            gv_tkn_conc_name,
                                            gv_request_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_b_15_flg := 1;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_rcv_exec;
--
  /***********************************************************************************
   * Procedure Name   : proc_deli_exec
   * Description      : 出荷依頼/出荷実績作成処理起動(B-16)
   ***********************************************************************************/
  PROCEDURE proc_deli_exec(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_deli_exec'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_ret        BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 依頼NOの出力
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30023',
                                          gv_tkn_request_num,
                                          gv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
-- Ver1.11 M.Hokkanji Start
    -- 要求セットの設定
--    lb_ret := FND_SUBMIT.SUBMIT_PROGRAM(gv_deli_app,
--                                        gv_deli_app_name,
--                                        gv_deli_stage,
--                                        NULL,NULL,gv_request_no);
--
--    IF (NOT lb_ret) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
--                                            'APP-XXPO-10024',
--                                            gv_tkn_conc_name,
--                                            gv_request_name);
 --     lv_errbuf := lv_errmsg;
 --     RAISE global_api_expt;
--    END IF;
--
--    gn_b_16_flg := 1;
-- Ver1.11 M.Hokkanji End
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_deli_exec;
--
  /***********************************************************************************
   * Procedure Name   : proc_rcv_if
   * Description      : 受入オープンインタフェースの作成処理
   ***********************************************************************************/
  PROCEDURE proc_rcv_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_rcv_if'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_mst_rec       mst_b_5_rec;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 直接受入
    IF (ir_masters_rec.trans_type = gv_trans_type_receive) THEN
--
      -- 受入ヘッダオープンIFの作成
      INSERT INTO rcv_headers_interface
      (
           header_interface_id
          ,group_id
          ,processing_status_code
          ,receipt_source_code
          ,transaction_type
          ,last_update_date
          ,last_updated_by
          ,last_update_login
          ,creation_date
          ,created_by
          ,vendor_id
          ,expected_receipt_date
          ,validation_flag
      )
      SELECT 
           rcv_headers_interface_s.NEXTVAL                 -- header_interface_id
          ,gn_group_id                                     -- group_id
          ,'PENDING'                                       -- processing_status_code
          ,'VENDOR'                                        -- receipt_source_code
          ,'NEW'                                           -- transaction_type
          ,gd_last_update_date                             -- last_update_date
          ,gn_last_update_by                               -- last_updated_by
          ,gn_last_update_login                            -- last_update_login
          ,gd_creation_date                                -- creation_date
          ,gn_created_by                                   -- created_by
          ,ir_masters_rec.vendor_id                        -- vendor_id
          ,ir_masters_rec.def_date4                        -- expected_receipt_date
          ,gv_flg_on                                       -- validation_flag
      FROM DUAL;
--
      -- 受入取引オープンIFの作成
      INSERT INTO rcv_transactions_interface
      (
           interface_transaction_id
          ,group_id
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,transaction_type
          ,transaction_date
          ,processing_status_code
          ,processing_mode_code
          ,transaction_status_code
          ,quantity
          ,unit_of_measure
          ,item_id
          ,auto_transact_code
          ,receipt_source_code
          ,to_organization_id
          ,source_document_code
          ,po_header_id
          ,po_line_id
          ,po_line_location_id
          ,destination_type_code
          ,subinventory
          ,locator_id
          ,expected_receipt_date
          ,ship_line_attribute1
          ,header_interface_id
          ,validation_flag
      )
      SELECT
           rcv_transactions_interface_s.NEXTVAL            -- interface_transaction_id
          ,gn_group_id                                     -- group_id
          ,gd_last_update_date                             -- last_update_date
          ,gn_last_update_by                               -- last_updated_by
          ,gd_creation_date                                -- creation_date
          ,gn_created_by                                   -- created_by
          ,gn_last_update_login                            -- last_update_login
          ,ir_masters_rec.trans_type                       -- transaction_type
          ,ir_masters_rec.def_date4                        -- transaction_date
          ,'PENDING'                                       -- processing_status_code
          ,'BATCH'                                         -- processing_mode_code
          ,'PENDING'                                       -- transaction_status_code
          -- 2008/05/24 UPD START Y.Takayama
          --,ir_masters_rec.def_qty7                       -- quantity
          ,ir_masters_rec.rcv_cov_qty                      -- quantity
          -- 2008/05/24 UPD END   Y.Takayama
          ,ir_masters_rec.unit_code                        -- unit_of_measure
          ,ir_masters_rec.item_id                          -- item_id
          ,'DELIVER'                                       -- auto_transact_code
          ,'VENDOR'                                        -- receipt_source_code
          ,ir_masters_rec.organization_id                  -- to_organization_id
          ,'PO'                                            -- source_document_code
          ,ir_masters_rec.po_header_id                     -- po_header_id
          ,ir_masters_rec.po_line_id                       -- po_line_id
-- 2009/12/02 v1.19 T.Yoshimoto Mod Start 本稼動障害#263
--          ,ir_masters_rec.po_line_id                       -- po_line_location_id
          ,ir_masters_rec.po_line_location_id              -- po_line_location_id
-- 2009/12/02 v1.19 T.Yoshimoto Mod Start 本稼動障害#263
          ,'INVENTORY'                                     -- destination_type_code
          ,ir_masters_rec.subinventory                     -- subinventory
          ,ir_masters_rec.locator_id                       -- locator_id
          ,ir_masters_rec.def_date4                        -- expected_receipt_date
          ,TO_CHAR(gn_txns_id)                             -- ship_line_attribute1
          ,rcv_headers_interface_s.CURRVAL                 -- header_interface_id
          ,gv_flg_on                                       -- validation_flag
      FROM DUAL;
--
      -- ロット管理品の場合
      IF (ir_masters_rec.lot_ctl = gn_lot_ctl_on) THEN
--
        -- INVロット取引オープンIFの作成
        INSERT INTO mtl_transaction_lots_interface
        (
             transaction_interface_id
            ,last_update_date
            ,last_updated_by
            ,creation_date
            ,created_by
            ,last_update_login
            ,lot_number
            ,transaction_quantity
            ,primary_quantity
            ,product_code
            ,product_transaction_id
        )
        SELECT
             mtl_material_transactions_s.NEXTVAL           -- transaction_interface_id
            ,gd_last_update_date                           -- last_update_date
            ,gn_last_update_by                             -- last_updated_by
            ,gd_creation_date                              -- creation_date
            ,gn_created_by                                 -- created_by
            ,gn_last_update_login                          -- last_update_login
            ,ir_masters_rec.lot_no                         -- lot_number
            -- 2008/05/24 UPD START Y.Takayama
            --,ABS(ir_masters_rec.def_qty7)                -- transaction_quantity
            --,ABS(ir_masters_rec.def_qty7)                -- primary_quantity
            ,ABS(ir_masters_rec.rcv_cov_qty)               -- transaction_quantity
            ,ABS(ir_masters_rec.rcv_cov_qty)               -- primary_quantity
            -- 2008/05/24 UPD END   Y.Takayama
            ,'RCV'                                         -- product_code
            ,rcv_transactions_interface_s.CURRVAL          -- product_transaction_id
        FROM DUAL;
      END IF;
--
    -- 訂正
    ELSIF (ir_masters_rec.trans_type = gv_trans_type_correct) THEN
--
      IF (ir_masters_rec.rcv_cov_qty > 0) THEN
--
-- 2009/01/15 v1.16 T.Yoshimoto Del Start
/*
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id2
        FROM   DUAL;
*/
-- 2009/01/15 v1.16 T.Yoshimoto Del End
--
        -- 受入訂正
        mod_open_rcv_if(
          ir_masters_rec,
          gn_group_id2,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
-- 2009/01/15 v1.16 T.Yoshimoto Del Start
/*
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id
        FROM   DUAL;
*/
-- 2009/01/15 v1.16 T.Yoshimoto Del End
--
        -- 搬送訂正
        mod_open_deli_if(
          ir_masters_rec,
          gn_group_id,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      ELSE
--
-- 2009/01/15 v1.16 T.Yoshimoto Del Start
/*
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id2
        FROM   DUAL;
*/
-- 2009/01/15 v1.16 T.Yoshimoto Del End
--
        -- 搬送訂正
        mod_open_deli_if(
          ir_masters_rec,
          gn_group_id2,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
-- 2009/01/15 v1.16 T.Yoshimoto Del Start
/*
        SELECT rcv_interface_groups_s.NEXTVAL
        INTO   gn_group_id
        FROM   DUAL;
*/
-- 2009/01/15 v1.16 T.Yoshimoto Del End
--
        -- 受入訂正
        mod_open_rcv_if(
          ir_masters_rec,
          gn_group_id,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    gn_b_5_cnt := gn_b_5_cnt + 1;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_rcv_if;
--
  /***********************************************************************************
   * Procedure Name   : upd_xxpo_data
   * Description      : 受注ヘッダアドオン情報 更新(B-10)
   *                    (最新データを訂正前データに変更)
   ***********************************************************************************/
  PROCEDURE upd_xxpo_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxpo_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_order_header_id                xxwsh_order_headers_all.order_header_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受注ヘッダアドオンのロック
    BEGIN
      SELECT xha.order_header_id
      INTO   ln_order_header_id
      FROM   xxwsh_order_headers_all xha
      WHERE  xha.order_header_id = ir_masters_rec.order_header_id
      FOR UPDATE OF xha.order_header_id NOWAIT;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10138');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 受注ヘッダアドオンの更新
    BEGIN
      UPDATE xxwsh_order_headers_all
      SET    latest_external_flag   = gv_flg_off
            ,last_updated_by        = gn_last_update_by
            ,last_update_date       = gd_last_update_date
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  order_header_id        = ir_masters_rec.order_header_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END upd_xxpo_data;
--
  /***********************************************************************************
   * Procedure Name   : mod_xxpo_data
   * Description      : 受注アドオン情報 登録(訂正データ登録)(B-11)
   ***********************************************************************************/
  PROCEDURE mod_xxpo_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mod_xxpo_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR xx_line_cur
    IS
      SELECT order_line_id
      FROM   xxwsh_order_lines_all
      WHERE  order_header_id = ir_masters_rec.order_header_id;
--
    -- *** ローカル・レコード ***
    lr_xx_line_rec xx_line_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受注ヘッダアドオンの作成
    INSERT INTO xxwsh_order_headers_all
    (
           order_header_id
          ,order_type_id
          ,organization_id
          ,header_id
          ,latest_external_flag
          ,ordered_date
          ,customer_id
          ,customer_code
          ,deliver_to_id
          ,deliver_to
          ,shipping_instructions
          ,career_id
          ,freight_carrier_code
          ,shipping_method_code
          ,cust_po_number
          ,price_list_id
          ,request_no
-- 2008/12/19 D.Nihei Add Start
          ,base_request_no
-- 2008/12/19 D.Nihei Add End
          ,req_status
          ,delivery_no
          ,prev_delivery_no
          ,schedule_ship_date
          ,schedule_arrival_date
          ,mixed_no
          ,collected_pallet_qty
          ,confirm_request_class
          ,freight_charge_class
          ,shikyu_instruction_class
          ,shikyu_inst_rcv_class
          ,amount_fix_class
          ,takeback_class
          ,deliver_from_id
          ,deliver_from
          ,head_sales_branch
          ,po_no
          ,prod_class
          ,item_class
          ,no_cont_freight_class
          ,arrival_time_from
          ,arrival_time_to
          ,designated_item_id
          ,designated_item_code
          ,designated_production_date
          ,designated_branch_no
          ,slip_number
          ,sum_quantity
          ,small_quantity
          ,label_quantity
          ,loading_efficiency_weight
          ,loading_efficiency_capacity
          ,based_weight
          ,based_capacity
          ,sum_weight
          ,sum_capacity
          ,mixed_ratio
          ,pallet_sum_quantity
          ,real_pallet_quantity
          ,sum_pallet_weight
          ,order_source_ref
          ,result_freight_carrier_id
          ,result_freight_carrier_code
          ,result_shipping_method_code
          ,result_deliver_to_id
          ,result_deliver_to
          ,shipped_date
          ,arrival_date
          ,weight_capacity_class
          ,actual_confirm_class
          ,notif_status
          ,prev_notif_status
          ,notif_date
          ,new_modify_flg
          ,process_status
          ,performance_management_dept
          ,instruction_dept
          ,transfer_location_id
          ,transfer_location_code
          ,mixed_sign
          ,screen_update_date
          ,screen_update_by
          ,tightening_date
          ,vendor_id
          ,vendor_code
          ,vendor_site_id
          ,vendor_site_code
          ,registered_sequence
          ,tightening_program_id
          ,corrected_tighten_class
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
    )
    SELECT xxwsh_order_headers_all_s1.NEXTVAL         -- order_header_id
          ,order_type_id                              -- order_type_id
          ,organization_id                            -- organization_id
--          ,header_id                                  -- header_id
          ,NULL                                       -- header_id(2008/04/16 修正)
          ,gv_flg_on                                  -- latest_external_flag
          ,ordered_date                               -- ordered_date
          ,customer_id                                -- customer_id
          ,customer_code                              -- customer_code
          ,deliver_to_id                              -- deliver_to_id
          ,deliver_to                                 -- deliver_to
          ,shipping_instructions                      -- shipping_instructions
          ,career_id                                  -- career_id
          ,freight_carrier_code                       -- freight_carrier_code
          ,shipping_method_code                       -- shipping_method_code
          ,cust_po_number                             -- cust_po_number
          ,price_list_id                              -- price_list_id
          ,request_no                                 -- request_no
-- 2008/12/19 D.Nihei Add Start
          ,base_request_no                            -- base_request_no
-- 2008/12/19 D.Nihei Add End
          ,ir_masters_rec.req_status                  -- req_status
          ,delivery_no                                -- delivery_no
          ,prev_delivery_no                           -- prev_delivery_no
          ,schedule_ship_date                         -- schedule_ship_date
          ,schedule_arrival_date                      -- schedule_arrival_date
          ,mixed_no                                   -- mixed_no
          ,collected_pallet_qty                       -- collected_pallet_qty
          ,confirm_request_class                      -- confirm_request_class
          ,freight_charge_class                       -- freight_charge_class
          ,shikyu_instruction_class                   -- shikyu_instruction_class
          ,shikyu_inst_rcv_class                      -- shikyu_inst_rcv_class
          ,amount_fix_class                           -- amount_fix_class
          ,takeback_class                             -- takeback_class
          ,deliver_from_id                            -- deliver_from_id
          ,deliver_from                               -- deliver_from
          ,head_sales_branch                          -- head_sales_branch
          ,po_no                                      -- po_no
          ,prod_class                                 -- prod_class
          ,item_class                                 -- item_class
          ,no_cont_freight_class                      -- no_cont_freight_class
          ,arrival_time_from                          -- arrival_time_from
          ,arrival_time_to                            -- arrival_time_to
          ,designated_item_id                         -- designated_item_id
          ,designated_item_code                       -- designated_item_code
          ,designated_production_date                 -- designated_production_date
          ,designated_branch_no                       -- designated_branch_no
          ,slip_number                                -- slip_number
          ,sum_quantity                               -- sum_quantity
          ,small_quantity                             -- small_quantity
          ,label_quantity                             -- label_quantity
          ,loading_efficiency_weight                  -- loading_efficiency_weight
          ,loading_efficiency_capacity                -- loading_efficiency_capacity
          ,based_weight                               -- based_weight
          ,based_capacity                             -- based_capacity
          ,sum_weight                                 -- sum_weight
          ,sum_capacity                               -- sum_capacity
          ,mixed_ratio                                -- mixed_ratio
          ,pallet_sum_quantity                        -- pallet_sum_quantity
          ,real_pallet_quantity                       -- real_pallet_quantity
          ,sum_pallet_weight                          -- sum_pallet_weight
          ,order_source_ref                           -- order_source_ref
          ,result_freight_carrier_id                  -- result_freight_carrier_id
          ,result_freight_carrier_code                -- result_freight_carrier_code
          ,result_shipping_method_code                -- result_shipping_method_code
          ,result_deliver_to_id                       -- result_deliver_to_id
          ,result_deliver_to                          -- result_deliver_to
          ,shipped_date                               -- shipped_date
          ,arrival_date                               -- arrival_date
          ,weight_capacity_class                      -- weight_capacity_class
          ,gv_flg_off                                 -- actual_confirm_class
          ,notif_status                               -- notif_status
          ,prev_notif_status                          -- prev_notif_status
          ,notif_date                                 -- notif_date
          ,new_modify_flg                             -- new_modify_flg
          ,process_status                             -- process_status
          ,performance_management_dept                -- performance_management_dept
          ,instruction_dept                           -- instruction_dept
          ,transfer_location_id                       -- transfer_location_id
          ,transfer_location_code                     -- transfer_location_code
          ,mixed_sign                                 -- mixed_sign
          ,screen_update_date                         -- screen_update_date
          ,screen_update_by                           -- screen_update_by
          ,tightening_date                            -- tightening_date
          ,vendor_id                                  -- vendor_id
          ,vendor_code                                -- vendor_code
          ,vendor_site_id                             -- vendor_site_id
          ,vendor_site_code                           -- vendor_site_code
          ,registered_sequence                        -- registered_sequence
          ,tightening_program_id                      -- tightening_program_id
          ,corrected_tighten_class                    -- corrected_tighten_class
          ,gn_created_by                              -- created_by
          ,gd_creation_date                           -- creation_date
          ,gn_last_update_by                          -- last_updated_by
          ,gd_last_update_date                        -- last_update_date
          ,gn_last_update_login                       -- last_update_login
          ,gn_request_id                              -- request_id
          ,gn_program_application_id                  -- program_application_id
          ,gn_program_id                              -- program_id
          ,gd_program_update_date                     -- program_update_date
    FROM   xxwsh_order_headers_all
    WHERE  order_header_id      = ir_masters_rec.order_header_id
    AND    latest_external_flag = gv_flg_off;
--
    OPEN xx_line_cur;
--
    <<xx_line_loop>>
    LOOP
      FETCH xx_line_cur INTO lr_xx_line_rec;
      EXIT WHEN xx_line_cur%NOTFOUND;
--
      -- 受注明細アドオンの作成
      INSERT INTO xxwsh_order_lines_all
      (
             order_line_id
            ,order_header_id
            ,order_line_number
            ,header_id
            ,line_id
            ,request_no
            ,shipping_inventory_item_id
            ,shipping_item_code
            ,quantity
            ,uom_code
            ,unit_price
            ,shipped_quantity
            ,designated_production_date
            ,based_request_quantity
            ,request_item_id
            ,request_item_code
            ,ship_to_quantity
            ,futai_code
            ,designated_date
            ,move_number
            ,po_number
            ,cust_po_number
            ,pallet_quantity
            ,layer_quantity
            ,case_quantity
            ,weight
            ,capacity
            ,pallet_qty
            ,pallet_weight
            ,reserved_quantity
            ,automanual_reserve_class
            ,delete_flag
            ,warning_class
            ,warning_date
            ,line_description
            ,rm_if_flg
            ,shipping_request_if_flg
            ,shipping_result_if_flg
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
      )
      SELECT xxwsh_order_lines_all_s1.NEXTVAL           -- order_line_id
            ,xxwsh_order_headers_all_s1.CURRVAL         -- order_header_id
            ,order_line_number                          -- order_line_number
  --          ,header_id                                  -- header_id
  --          ,line_id                                    -- line_id
            ,NULL                                       -- header_id(2008/04/16 修正)
            ,NULL                                       -- line_id(2008/04/16 修正)
            ,request_no                                 -- request_no
            ,shipping_inventory_item_id                 -- shipping_inventory_item_id
            ,shipping_item_code                         -- shipping_item_code
            ,quantity                                   -- quantity
            ,uom_code                                   -- uom_code
            ,unit_price                                 -- unit_price
            ,shipped_quantity                           -- shipped_quantity
            ,designated_production_date                 -- designated_production_date
            ,based_request_quantity                     -- based_request_quantity
            ,request_item_id                            -- request_item_id
            ,request_item_code                          -- request_item_code
            ,ship_to_quantity                           -- ship_to_quantity
            ,futai_code                                 -- futai_code
            ,designated_date                            -- designated_date
            ,move_number                                -- move_number
            ,po_number                                  -- po_number
            ,cust_po_number                             -- cust_po_number
            ,pallet_quantity                            -- pallet_quantity
            ,layer_quantity                             -- layer_quantity
            ,case_quantity                              -- case_quantity
            ,weight                                     -- weight
            ,capacity                                   -- capacity
            ,pallet_qty                                 -- pallet_qty
            ,pallet_weight                              -- pallet_weight
            ,reserved_quantity                          -- reserved_quantity
            ,automanual_reserve_class                   -- automanual_reserve_class
            ,delete_flag                                -- delete_flag
            ,warning_class                              -- warning_class
            ,warning_date                               -- warning_date
            ,line_description                           -- line_description
            ,rm_if_flg                                  -- rm_if_flg
            ,shipping_request_if_flg                    -- shipping_request_if_flg
            ,shipping_result_if_flg                     -- shipping_result_if_flg
            ,gn_created_by                              -- created_by
            ,gd_creation_date                           -- creation_date
            ,gn_last_update_by                          -- last_updated_by
            ,gd_last_update_date                        -- last_update_date
            ,gn_last_update_login                       -- last_update_login
            ,gn_request_id                              -- request_id
            ,gn_program_application_id                  -- program_application_id
            ,gn_program_id                              -- program_id
            ,gd_program_update_date                     -- program_update_date
      FROM   xxwsh_order_lines_all
      WHERE  order_line_id   = lr_xx_line_rec.order_line_id;
--
      -- 移動ロット詳細(アドオン)の作成
      INSERT INTO xxinv_mov_lot_details
      (
         mov_lot_dtl_id                                  -- ロット詳細ID
        ,mov_line_id                                     -- 明細ID
        ,document_type_code                              -- 文書タイプ
        ,record_type_code                                -- レコードタイプ
        ,item_id                                         -- OPM品目ID
        ,item_code                                       -- 品目
        ,lot_id                                          -- ロットID
        ,lot_no                                          -- ロットNo
        ,actual_date                                     -- 実績日
        ,actual_quantity                                 -- 実績数量
-- 2008/12/19 D.Nihei Add Start
        ,before_actual_quantity                          -- 訂正前数量
-- 2008/12/19 D.Nihei Add End
        ,automanual_reserve_class                        -- 自動手動引当区分
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT xxinv_mov_lot_s1.NEXTVAL                        -- mov_lot_dtl_id
            ,xxwsh_order_lines_all_s1.CURRVAL                -- mov_line_id
            ,xmld.document_type_code                         -- document_type_code
            ,xmld.record_type_code                           -- record_type_code
            ,xmld.item_id                                    -- item_id
            ,xmld.item_code                                  -- item_code
            ,xmld.lot_id                                     -- lot_id
            ,xmld.lot_no                                     -- lot_no
            ,xmld.actual_date                                -- actual_date
            ,xmld.actual_quantity                            -- actual_quantity
-- 2008/12/19 D.Nihei Add Start
            ,xmld.actual_quantity                            -- actual_quantity
-- 2008/12/19 D.Nihei Add End
            ,xmld.automanual_reserve_class                   -- automanual_reserve_class
            ,gn_created_by                                   -- created_by
            ,gd_creation_date                                -- creation_date
            ,gn_last_update_by                               -- last_updated_by
            ,gd_last_update_date                             -- last_update_date
            ,gn_last_update_login                            -- last_update_login
            ,gn_request_id                                   -- request_id
            ,gn_program_application_id                       -- program_application_id
            ,gn_program_id                                   -- program_id
            ,gd_program_update_date                          -- program_update_date
      FROM  xxinv_mov_lot_details xmld
      WHERE xmld.mov_line_id = lr_xx_line_rec.order_line_id
      AND   xmld.document_type_code = gv_document_type;             -- 支給指示
--
    END LOOP xx_line_loop;
--
    CLOSE xx_line_cur;
--
    gn_b_9_cnt := gn_b_9_cnt + 1;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (xx_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xx_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (xx_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xx_line_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (xx_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xx_line_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END mod_xxpo_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_quantity_data
   * Description      : 出荷実績数量 更新(訂正用)(B-14)
   ***********************************************************************************/
  PROCEDURE upd_quantity_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_12_rec, -- B-12:出荷実績数量更新用
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_quantity_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受注明細アドオンの更新
    BEGIN
      UPDATE xxwsh_order_lines_all
      SET    shipped_quantity       = ir_masters_rec.def_qty6        -- 出荷実績数量
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  order_line_id = ir_masters_rec.order_line_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 移動ロット詳細(アドオン)の更新
    BEGIN
      UPDATE xxinv_mov_lot_details
      SET    actual_quantity        = ir_masters_rec.def_qty6        -- 実績数量
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  mov_line_id        = ir_masters_rec.order_line_id
      AND    document_type_code = gv_document_type            -- 支給指示
      AND    record_type_code   = gv_record_type;             -- 出庫実績
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END upd_quantity_data;
--
  /***********************************************************************************
   * Procedure Name   : keep_mod_data
   * Description      : 出荷実績情報保持(訂正用)(訂正用)(B-13)
   ***********************************************************************************/
  PROCEDURE keep_mod_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_12_rec, -- B-12:出荷実績数量更新用
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keep_mod_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受注明細アドオンデータなし
    IF (ir_masters_rec.order_line_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10050',
                                            gv_tkn_request_num,
                                            gv_request_no,
                                            gv_tkn_item_cd,
                                            NVL(ir_masters_rec.item_no,ir_masters_rec.item_id));
      RAISE keep_mod_data_expt;
    END IF;
--
    -- ================================
    -- B-14.出荷実績数量 更新(訂正用)
    -- ================================
    upd_quantity_data(
      ir_masters_rec,
      ir_mst_b_6_rec,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN keep_mod_data_expt THEN
      ov_retcode := gv_status_warn;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END keep_mod_data;
--
  /***********************************************************************************
   * Procedure Name   : get_mod_data
   * Description      : 出荷実績数量更新用データ取得(訂正用)(B-12)
   ***********************************************************************************/
  PROCEDURE get_mod_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mod_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_mst_rec           mst_b_12_rec;
    ln_order_line_id     xxwsh_order_lines_all.order_line_id%TYPE;
    ln_mov_lot_dtl_id    xxinv_mov_lot_details.mov_lot_dtl_id%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR xpo_line_cur
    IS
      SELECT  paa.attribute6                   -- 仕入先出荷数量
             ,xoa.shipped_quantity             -- 出荷実績数量
             ,xoa.order_line_id                -- 受注明細アドオンID
             ,xoa.request_no                   -- 依頼NO
             ,xiv.item_no                      -- 品目コード
             ,paa.item_id                      -- 品目ID
      FROM   xxcmn_item_mst_v xiv              -- OPM品目情報VIEW
             ,(SELECT  xha.po_no                        -- 発注NO
                      ,xla.request_no                   -- 依頼NO
                      ,xla.shipping_inventory_item_id   -- 出荷品目ID
                      ,xla.shipped_quantity             -- 出荷実績数量
                      ,xla.order_line_id                -- 受注明細アドオンID
               FROM    xxwsh_order_headers_all xha      -- 受注ヘッダアドオン
                      ,xxwsh_order_lines_all xla        -- 受注明細アドオン
               WHERE  xha.order_header_id = xla.order_header_id
               AND    NVL(xha.latest_external_flag,gv_flg_off) = gv_flg_on   -- 最新フラグ(ON)
               AND    NVL(xha.actual_confirm_class,gv_flg_off) = gv_flg_off  -- 実績計上済区分(OFF)
               AND    NVL(xla.delete_flag,gv_flg_off) = gv_flg_off) xoa      -- 取消フラグ(OFF)
             ,(SELECT  pha.po_header_id
                      ,pla.attribute6
                      ,pha.segment1
                      ,pla.item_id
                      ,pha.attribute9
               FROM    po_headers_all pha               -- 発注ヘッダ
                      ,po_lines_all pla                 -- 発注明細
               WHERE  pha.po_header_id = pla.po_header_id
               AND    pha.po_header_id = ir_masters_rec.po_header_id) paa
      WHERE  paa.segment1   = xoa.po_no(+)
      AND    paa.attribute9 = xoa.request_no(+)
      AND    paa.item_id    = xoa.shipping_inventory_item_id(+)
      AND    paa.item_id    = xiv.inventory_item_id;
--
    -- *** ローカル・レコード ***
    lr_xpo_line_rec xpo_line_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN xpo_line_cur;
--
    <<xpo_line_loop>>
    LOOP
      FETCH xpo_line_cur INTO lr_xpo_line_rec;
      EXIT WHEN xpo_line_cur%NOTFOUND;
--
      lr_mst_rec.attribute6       := lr_xpo_line_rec.attribute6;
      lr_mst_rec.shipped_quantity := lr_xpo_line_rec.shipped_quantity;
      lr_mst_rec.order_line_id    := lr_xpo_line_rec.order_line_id;
      lr_mst_rec.request_no       := lr_xpo_line_rec.request_no;
      lr_mst_rec.item_no          := lr_xpo_line_rec.item_no;
      lr_mst_rec.item_id          := lr_xpo_line_rec.item_id;
--
      lr_mst_rec.def_qty6         := TO_NUMBER(lr_xpo_line_rec.attribute6);
--
        -- 受注明細アドオンのロック
      BEGIN
        SELECT xla.order_line_id
        INTO   ln_order_line_id
        FROM   xxwsh_order_lines_all xla
        WHERE  xla.order_line_id = lr_xpo_line_rec.order_line_id
        FOR UPDATE OF xla.order_line_id NOWAIT;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN lock_expt THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10138');
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 移動ロット詳細(アドオン)のロック
      BEGIN
        SELECT xmld.mov_lot_dtl_id
        INTO   ln_mov_lot_dtl_id
        FROM   xxinv_mov_lot_details xmld
        WHERE  xmld.mov_line_id        = lr_xpo_line_rec.order_line_id
        AND    xmld.document_type_code = gv_document_type        -- 支給指示
        AND    xmld.record_type_code   = gv_record_type          -- 出荷実績
        FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN lock_expt THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10138');
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- ================================
      -- B-13.出荷実績情報保持(訂正用)
      -- ================================
      keep_mod_data(
        lr_mst_rec,
        ir_masters_rec,
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
    END LOOP xpo_line_loop;
--
    CLOSE xpo_line_cur;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (xpo_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xpo_line_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (xpo_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xpo_line_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (xpo_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE xpo_line_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END get_mod_data;
--
  /***********************************************************************************
   * Procedure Name   : ins_xxpo_data
   * Description      : 受注アドオン情報 更新(新規登録用)(B-9)
   ***********************************************************************************/
  PROCEDURE ins_xxpo_data(
    ir_mst_b_7_rec  IN OUT NOCOPY mst_b_7_rec,  -- B-7:出荷実績作成対象データ取得
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    lv_status       IN            VARCHAR2,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxpo_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_req_status      xxwsh_order_headers_all.req_status%TYPE;
    ln_carrier_id      xxwsh_order_headers_all.result_freight_carrier_id%TYPE;
    lv_carrier_code    xxwsh_order_headers_all.result_freight_carrier_code%TYPE;
    lv_method_code     xxwsh_order_headers_all.result_shipping_method_code%TYPE;
    ld_shipped_date    xxwsh_order_headers_all.shipped_date%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 仕入先出荷数量<>出荷実績数量
    IF ((ir_mst_b_7_rec.def_qty6 <> ir_mst_b_7_rec.shipped_quantity)
     OR ((ir_mst_b_7_rec.def_qty6 IS NULL) AND (ir_mst_b_7_rec.shipped_quantity IS NOT NULL))
     OR ((ir_mst_b_7_rec.def_qty6 IS NOT NULL) AND (ir_mst_b_7_rec.shipped_quantity IS NULL))) THEN
--
      -- 出荷依頼/支給依頼ステータス
     lv_req_status := lv_status;
--
      -- 運送業者_実績ID
      IF (ir_mst_b_7_rec.result_freight_carrier_id IS NULL) THEN
        ln_carrier_id := ir_mst_b_7_rec.career_id;
      ELSE
        ln_carrier_id := ir_mst_b_7_rec.result_freight_carrier_id;
      END IF;
--
      -- 運送業者_実績
      IF (ir_mst_b_7_rec.result_freight_carrier_code IS NULL) THEN
        lv_carrier_code := ir_mst_b_7_rec.freight_carrier_code;
      ELSE
        lv_carrier_code := ir_mst_b_7_rec.result_freight_carrier_code;
      END IF;
--
      -- 配送区分_実績
      IF (ir_mst_b_7_rec.result_shipping_method_code IS NULL) THEN
        lv_method_code := ir_mst_b_7_rec.shipping_method_code;
      ELSE
        lv_method_code := ir_mst_b_7_rec.result_shipping_method_code;
      END IF;
--
      ld_shipped_date := ir_mst_b_7_rec.def_date4;
--
      -- 受注ヘッダアドオンの更新
      BEGIN
        UPDATE xxwsh_order_headers_all
        SET    req_status                  = lv_req_status         -- 出荷依頼/支給依頼ステータス
              ,actual_confirm_class        = gv_flg_off            -- 実績計上済区分
              ,shipped_date                = ld_shipped_date       -- 出荷日
              ,result_freight_carrier_id   = ln_carrier_id         -- 運送業者_実績ID
              ,result_freight_carrier_code = lv_carrier_code       -- 運送業者_実績
              ,result_shipping_method_code = lv_method_code        -- 配送区分_実績
              ,last_updated_by             = gn_last_update_by
              ,last_update_date            = gd_last_update_date
              ,last_update_login           = gn_last_update_login
              ,request_id                  = gn_request_id
              ,program_application_id      = gn_program_application_id
              ,program_id                  = gn_program_id
              ,program_update_date         = gd_program_update_date
        WHERE  order_header_id = ir_mst_b_6_rec.order_header_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 受注明細アドオンの更新
      BEGIN
        UPDATE xxwsh_order_lines_all
        SET    shipped_quantity            = ir_mst_b_7_rec.def_qty6   -- 出荷実績数量
              ,last_updated_by             = gn_last_update_by
              ,last_update_date            = gd_last_update_date
              ,last_update_login           = gn_last_update_login
              ,request_id                  = gn_request_id
              ,program_application_id      = gn_program_application_id
              ,program_id                  = gn_program_id
              ,program_update_date         = gd_program_update_date
        WHERE  order_line_id = ir_mst_b_7_rec.order_line_id;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 移動ロット詳細(アドオン)の更新
      BEGIN
        UPDATE xxinv_mov_lot_details
        SET    actual_quantity             = ir_mst_b_7_rec.def_qty6   -- 実績数量
              ,last_updated_by             = gn_last_update_by
              ,last_update_date            = gd_last_update_date
              ,last_update_login           = gn_last_update_login
              ,request_id                  = gn_request_id
              ,program_application_id      = gn_program_application_id
              ,program_id                  = gn_program_id
              ,program_update_date         = gd_program_update_date
        WHERE  mov_line_id        = ir_mst_b_7_rec.order_line_id
        AND    document_type_code = gv_document_type           -- 支給指示
        AND    record_type_code   = gv_record_type;            -- 出庫実績
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      gn_b_9_cnt := gn_b_9_cnt + 1;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END ins_xxpo_data;
--
  /***********************************************************************************
   * Procedure Name   : keep_new_data
   * Description      : 出荷実績情報保持(新規登録用)(B-8)
   ***********************************************************************************/
  PROCEDURE keep_new_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_7_rec,  -- B-7:出荷実績作成対象データ取得
    ir_mst_b_6_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    iv_status       IN            VARCHAR2,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keep_new_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受注明細アドオンデータなし
    IF (ir_masters_rec.order_line_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10050',
                                            gv_tkn_request_num,
                                            gv_request_no,
                                            gv_tkn_item_cd,
                                            ir_masters_rec.item_no);
      RAISE keep_new_data_expt;
    END IF;
--
    -- ================================
    -- B-9.受注アドオン情報 更新(新規登録用)
    -- ================================
    ins_xxpo_data(
      ir_masters_rec,
      ir_mst_b_6_rec,
      iv_status,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ================================
    -- B-18.移動ロット詳細作成(新規登録用)
    -- ================================
    create_mov_lot(
      ir_masters_rec,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN keep_new_data_expt THEN
      ov_retcode := gv_status_warn;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END keep_new_data;
--
  /***********************************************************************************
   * Procedure Name   : get_new_data
   * Description      : 出荷実績作成対象データ取得(新規登録用)(B-7)
   ***********************************************************************************/
  PROCEDURE get_new_data(
    ir_masters_rec  IN OUT NOCOPY mst_b_6_rec,  -- B-6:出荷実績作成パターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_new_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt              NUMBER;
    lr_mst_rec          mst_b_7_rec;
    ln_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE;
    ln_order_line_id    xxwsh_order_lines_all.order_line_id%TYPE;
    ln_wk_header_id     xxwsh_order_headers_all.order_header_id%TYPE;
    ln_wk_line_id       xxwsh_order_lines_all.order_line_id%TYPE;
    lv_status           xxwsh_order_headers_all.req_status%TYPE;
    ln_mov_lot_dtl_id   xxinv_mov_lot_details.mov_lot_dtl_id%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR po_line_cur
    IS
      SELECT  paa.attribute6                   -- 仕入先出荷数量
             ,paa.attribute4                   -- 納入日
             ,xoa.req_status                   -- 出荷依頼/支給指示ステータス
             ,xoa.actual_confirm_class         -- 実績計上済区分
             ,xoa.career_id                    -- 運送業者ID
             ,xoa.freight_carrier_code         -- 運送業者
             ,xoa.result_freight_carrier_id    -- 運送業者_実績ID
             ,xoa.result_freight_carrier_code  -- 運送業者_実績
             ,xoa.shipping_method_code         -- 配送区分
             ,xoa.result_shipping_method_code  -- 配送区分_実績
             ,xoa.shipped_quantity             -- 出荷実績数量
             ,xoa.order_line_id                -- 受注明細アドオンID
             ,xoa.request_no                   -- 依頼NO
             ,xiv.item_no                      -- 品目コード
      FROM    xxcmn_item_mst_v xiv             -- OPM品目情報VIEW
             ,(SELECT  pla.attribute6
                      ,pha.attribute4
                      ,pha.po_header_id
                      ,pha.segment1
                      ,pha.attribute9
                      ,pla.item_id
               FROM    po_headers_all pha               -- 発注ヘッダ
                      ,po_lines_all pla                 -- 発注明細
               WHERE   pha.po_header_id = pla.po_header_id
               AND     pha.po_header_id = ir_masters_rec.po_header_id) paa
             ,(SELECT  xha.po_no                        -- 発注NO
                      ,xha.req_status                   -- 出荷依頼/支給指示ステータス
                      ,xha.actual_confirm_class         -- 実績計上済区分
                      ,xha.career_id                    -- 運送業者ID
                      ,xha.freight_carrier_code         -- 運送業者
                      ,xha.result_freight_carrier_id    -- 運送業者_実績ID
                      ,xha.result_freight_carrier_code  -- 運送業者_実績
                      ,xha.shipping_method_code         -- 配送区分
                      ,xha.result_shipping_method_code  -- 配送区分_実績
                      ,xla.shipped_quantity             -- 出荷実績数量
                      ,xla.order_line_id                -- 受注明細アドオンID
                      ,xla.request_no                   -- 依頼NO
                      ,xla.shipping_inventory_item_id   -- 出荷品目ID
               FROM    xxwsh_order_headers_all xha      -- 受注ヘッダアドオン
                      ,xxwsh_order_lines_all xla        -- 受注明細アドオン
               WHERE  xha.order_header_id = xla.order_header_id
               AND    xha.order_header_id = ir_masters_rec.order_header_id
               AND    NVL(xla.delete_flag,gv_flg_off) = gv_flg_off) xoa
      WHERE  paa.segment1   = xoa.po_no(+)
      AND    paa.attribute9 = xoa.request_no(+)
      AND    paa.item_id    = xoa.shipping_inventory_item_id(+)
      AND    paa.item_id    = xiv.inventory_item_id;
--
    -- *** ローカル・レコード ***
    lr_po_line_rec po_line_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 出荷依頼/支給依頼ステータス設定
    set_req_status(
      ir_masters_rec,
      lv_status,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    OPEN po_line_cur;
--
    <<po_line_loop>>
    LOOP
      FETCH po_line_cur INTO lr_po_line_rec;
      EXIT WHEN po_line_cur%NOTFOUND;
--
      lr_mst_rec.attribute6                  := lr_po_line_rec.attribute6;
      lr_mst_rec.attribute4                  := lr_po_line_rec.attribute4;
      lr_mst_rec.req_status                  := lr_po_line_rec.req_status;
      lr_mst_rec.actual_confirm_class        := lr_po_line_rec.actual_confirm_class;
      lr_mst_rec.career_id                   := lr_po_line_rec.career_id;
      lr_mst_rec.freight_carrier_code        := lr_po_line_rec.freight_carrier_code;
      lr_mst_rec.result_freight_carrier_id   := lr_po_line_rec.result_freight_carrier_id;
      lr_mst_rec.result_freight_carrier_code := lr_po_line_rec.result_freight_carrier_code;
      lr_mst_rec.shipping_method_code        := lr_po_line_rec.shipping_method_code;
      lr_mst_rec.result_shipping_method_code := lr_po_line_rec.result_shipping_method_code;
      lr_mst_rec.shipped_quantity            := lr_po_line_rec.shipped_quantity;
      lr_mst_rec.order_line_id               := lr_po_line_rec.order_line_id;
      lr_mst_rec.request_no                  := lr_po_line_rec.request_no;
      lr_mst_rec.item_no                     := lr_po_line_rec.item_no;
--
      lr_mst_rec.def_qty6  := TO_NUMBER(lr_po_line_rec.attribute6);
      lr_mst_rec.def_date4 := FND_DATE.STRING_TO_DATE(lr_po_line_rec.attribute4,'YYYY/MM/DD');
--
      ln_order_header_id := ir_masters_rec.order_header_id;
      ln_order_line_id   := lr_mst_rec.order_line_id;
--
      IF (ln_order_header_id IS NOT NULL) THEN
        -- 受注ヘッダアドオンのロック
        BEGIN
          SELECT xha.order_header_id
          INTO   ln_wk_header_id
          FROM   xxwsh_order_headers_all xha
          WHERE  xha.order_header_id = ln_order_header_id
          FOR UPDATE OF xha.order_header_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10138');
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      IF ((ln_order_header_id IS NOT NULL) AND (ln_order_line_id IS NOT NULL)) THEN
        -- 受注明細アドオンのロック
        BEGIN
          SELECT xla.order_line_id
          INTO   ln_wk_line_id
          FROM   xxwsh_order_lines_all xla
          WHERE  xla.order_header_id = ln_order_header_id
          AND    xla.order_line_id   = ln_order_line_id
          FOR UPDATE OF xla.order_line_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10138');
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      IF (ln_order_line_id IS NOT NULL) THEN
        -- 移動ロット詳細(アドオン)のロック
        BEGIN
          SELECT xmld.mov_lot_dtl_id
          INTO   ln_mov_lot_dtl_id
          FROM   xxinv_mov_lot_details xmld
          WHERE  xmld.mov_line_id        = ln_order_line_id
          AND    xmld.document_type_code = gv_document_type      -- 支給指示
          AND    xmld.record_type_code   = gv_record_type        -- 出庫実績
          FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10138');
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- ================================
      -- B-8.出荷実績情報保持(新規登録用)
      -- ================================
      keep_new_data(
        lr_mst_rec,
        ir_masters_rec,
        lv_status,
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
      gn_b_7_cnt := gn_b_7_cnt + 1;
--
    END LOOP po_line_loop;
--
    CLOSE po_line_cur;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_line_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_line_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_line_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_line_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END get_new_data;
--
  /***********************************************************************************
   * Procedure Name   : check_deli_pat
   * Description      : 出荷実績作成パターン判定(B-6)
   ***********************************************************************************/
  PROCEDURE check_deli_pat(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_deli_pat'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt            NUMBER;
    lr_mst_rec        mst_b_6_rec;
--
    -- *** ローカル・カーソル ***
    CURSOR po_head_cur
    IS
     SELECT pha.po_header_id                          -- 発注ヘッダID
           ,xha.order_header_id                       -- 受注ヘッダアドオンID
           ,xha.req_status                            -- 出荷依頼／支給指示ステータス
           ,xha.actual_confirm_class                  -- 実績計上済区分
     FROM   po_headers_all pha                        -- 発注ヘッダ
           ,(SELECT xoh.po_no
                   ,xoh.request_no
                   ,xoh.order_header_id
                   ,xoh.req_status
                   ,xoh.actual_confirm_class
             FROM   xxwsh_order_headers_all xoh       -- 受注ヘッダアドオン
             WHERE  xoh.latest_external_flag = gv_flg_on       -- ON
             AND   (xoh.req_status = gv_req_status_rect        -- 受領済
             OR     xoh.req_status = gv_req_status_appr)) xha  -- 出荷実績計上済
     WHERE  pha.segment1   = xha.po_no(+)
     AND    pha.attribute9 = xha.request_no(+)
     AND    pha.segment1   = gv_header_number;
--
    -- *** ローカル・レコード ***
    lr_po_head_rec po_head_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_cnt := 0;
--
    OPEN po_head_cur;
--
    <<po_head_loop>>
    LOOP
      FETCH po_head_cur INTO lr_po_head_rec;
      EXIT WHEN po_head_cur%NOTFOUND;
--
      lr_mst_rec.po_header_id         := lr_po_head_rec.po_header_id;
      lr_mst_rec.order_header_id      := lr_po_head_rec.order_header_id;
      lr_mst_rec.req_status           := lr_po_head_rec.req_status;
      lr_mst_rec.actual_confirm_class := lr_po_head_rec.actual_confirm_class;
--
      -- 受領済
      IF (lr_mst_rec.req_status = gv_req_status_rect) THEN
--
        -- ================================
        -- B-7.出荷実績作成対象データ取得(新規登録用)
        -- ================================
        get_new_data(
          lr_mst_rec,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
--
-- 2008/10/24 v1.18 T.Yoshimoto Mod Start
      -- 出荷実績計上済
      --ELSIF (lr_mst_rec.req_status = gv_req_status_appr) THEN
--
      -- 出荷実績計上済み且つ、実績計上済区分が'Y'の場合
      ELSIF ( (lr_mst_rec.req_status = gv_req_status_appr)
        AND (lr_mst_rec.actual_confirm_class = gv_flg_on) ) THEN
-- 2008/10/24 v1.18 T.Yoshimoto Mod End
--
        -- ================================
        -- B-10.受注ヘッダアドオン情報 更新
        -- ================================
        upd_xxpo_data(
          lr_mst_rec,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ================================
        -- B-11.受注アドオン情報 更新(訂正データ登録用)
        -- ================================
        mod_xxpo_data(
          lr_mst_rec,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ================================
        -- B-12.出荷実績数量更新用データ取得(訂正用)
        -- ================================
        get_mod_data(
          lr_mst_rec,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
--
-- 2008/10/24 v1.18 T.Yoshimoto Add Start
      -- 出荷実績計上済み且つ、実績計上済区分が'Y'以外の場合
      ELSIF ( (lr_mst_rec.req_status = gv_req_status_appr)
        AND (lr_mst_rec.actual_confirm_class <> gv_flg_on) ) THEN
--
        -- ================================
        -- B-7.出荷実績作成対象データ取得(新規登録用)
        -- ================================
        get_new_data(
          lr_mst_rec,
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := lv_retcode;
        END IF;
-- 2008/10/24 v1.18 T.Yoshimoto Add Start
--
      -- その他
      ELSE
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10066',
                                              gv_tkn_table_num,
                                              '発注ヘッダアドオン',
                                              gv_tkn_po_num,
                                              gv_header_number);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP po_head_loop;
--
    CLOSE po_head_cur;
--
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10066',
                                            gv_tkn_table_num,
                                            '発注ヘッダ',
                                            gv_tkn_po_num,
                                            gv_header_number);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_head_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_head_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_head_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_head_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_head_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_head_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END check_deli_pat;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 処理結果レポート出力(B-17)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_report';           -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_dspbuf               VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 受入実績作成対象件数出力メッセージ
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30025',
                                          gv_tkn_target_count_1,
                                          gn_b_3_cnt,
                                          gv_tkn_target_count_2,
                                          gn_b_7_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    -- 処理件数メッセージ
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30028',
                                          gv_tkn_count_1,
                                          gn_b_5_cnt,
                                          gv_tkn_count_2,
                                          gn_b_9_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    -- 処理結果レポートの出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : set_rcv_data
   * Description      : 受入実績情報登録(B-5)
   ***********************************************************************************/
  PROCEDURE set_rcv_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_rcv_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lr_mst_rec       masters_rec;
    ln_flg           NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ln_flg := 0;
--
    <<set_data_loop>>
    FOR i IN 0..gn_b_3_cnt-1 LOOP
      lr_mst_rec := gt_b_03_mast(i);
--
      -- 対象外以外
      IF (lr_mst_rec.exec_flg <> gn_mode_oth) THEN
--
        -- 登録
        IF (lr_mst_rec.exec_flg = gn_mode_ins) THEN
          lr_mst_rec.trans_type := gv_trans_type_receive;
--
        -- 更新
        ELSIF (lr_mst_rec.exec_flg = gn_mode_upd) THEN
          IF (lr_mst_rec.attribute1 IS NULL) THEN
            lr_mst_rec.trans_type := gv_trans_type_receive;
          ELSE
            lr_mst_rec.trans_type := gv_trans_type_correct;
          END IF;
        END IF;
--
        IF (ln_flg = 0) THEN
--
          -- 直接受入
          IF (lr_mst_rec.trans_type = gv_trans_type_receive) THEN
--
            SELECT rcv_interface_groups_s.NEXTVAL
-- 2009/01/15 v1.16 T.Yoshimoto Mod Start
                  ,gn_mode_ins             -- 新規
            INTO   gn_group_id
                  ,gt_group_id_mast(gn_group_id_cnt).exec_flg
-- 2009/01/15 v1.16 T.Yoshimoto Mod End
            FROM   DUAL;
--
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
            gt_group_id_mast(gn_group_id_cnt).group_id := gn_group_id;
            gn_group_id_cnt := gn_group_id_cnt + 1;
--
            ln_flg := 1;
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
          -- 訂正
          ELSIF (lr_mst_rec.trans_type = gv_trans_type_correct) THEN
--
              SELECT rcv_interface_groups_s.NEXTVAL
-- 2009/01/15 v1.16 T.Yoshimoto Mod Start
                    ,gn_mode_upd             -- 訂正
              INTO   gn_group_id2
                  ,gt_group_id_mast(gn_group_id_cnt).exec_flg
-- 2009/01/15 v1.16 T.Yoshimoto Mod End
              FROM   DUAL;
--
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
              gt_group_id_mast(gn_group_id_cnt).group_id := gn_group_id2;
              gn_group_id_cnt := gn_group_id_cnt + 1;
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
--
              SELECT rcv_interface_groups_s.NEXTVAL
-- 2009/01/15 v1.16 T.Yoshimoto Mod Start
                    ,gn_mode_upd             -- 訂正
              INTO   gn_group_id
                  ,gt_group_id_mast(gn_group_id_cnt).exec_flg
-- 2009/01/15 v1.16 T.Yoshimoto Mod End
              FROM   DUAL;
--
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
              gt_group_id_mast(gn_group_id_cnt).group_id := gn_group_id;
              gn_group_id_cnt := gn_group_id_cnt + 1;
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
          END IF;
-- 2009/01/15 v1.16 T.Yoshimoto Del Start
          --ln_flg := 1;
-- 2009/01/15 v1.16 T.Yoshimoto Del End
        END IF;
--
        -- 新規登録
        IF (lr_mst_rec.exec_flg = gn_mode_ins) THEN
          -- 受入返品実績(アドオン)の取引ID
          SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL
          INTO   gn_txns_id
          FROM   DUAL;
        END IF;
--
        -- 仕入先出荷数量
-- 2008/12/30 v1.13 T.Yoshimoto Mod Start
        --IF (lr_mst_rec.def_qty6 > 0) THEN
        -- 受入且つ仕入先出荷実績が0より大きい、又は、訂正の場合OIFへ書き込む
        IF (((lr_mst_rec.trans_type = gv_trans_type_receive) AND (lr_mst_rec.def_qty6 > 0))
          OR (lr_mst_rec.trans_type = gv_trans_type_correct)) THEN
-- 2008/12/30 v1.13 T.Yoshimoto Mod End
--
          -- 受入オープンインタフェースの作成
          proc_rcv_if(
            lr_mst_rec,
            lv_errbuf,          -- エラー・メッセージ           --# 固定 #
            lv_retcode,         -- リターン・コード             --# 固定 #
            lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
        -- 換算入数の設定
        IF (lr_mst_rec.attribute10 = 'CS') THEN
          -- 2008/05/24 UPD START Y.Takayama
          --lr_mst_rec.conv_factor := lr_mst_rec.pla_qty;
          lr_mst_rec.conv_factor := TO_NUMBER(lr_mst_rec.pla_qty);
          -- 2008/05/24 UPD END   Y.Takayama
        ELSE
          lr_mst_rec.conv_factor := 1;
        END IF;
--
        -- 新規登録
        IF (lr_mst_rec.exec_flg = gn_mode_ins) THEN
--
          -- 受入返品実績(アドオン)の作成
          proc_xxpo_rcv_ins(
            lr_mst_rec,
            lv_errbuf,          -- エラー・メッセージ           --# 固定 #
            lv_retcode,         -- リターン・コード             --# 固定 #
            lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- 訂正
        ELSIF (lr_mst_rec.exec_flg = gn_mode_upd) THEN
--
          -- 受入返品実績(アドオン)の更新
          BEGIN
            UPDATE xxpo_rcv_and_rtn_txns
            SET    rcv_rtn_quantity       = lr_mst_rec.def_qty6         -- 受入返品数量
                  ,quantity               = lr_mst_rec.rcv_qty          -- 数量
                  ,conversion_factor      = lr_mst_rec.conv_factor      -- 換算入数
                  ,last_updated_by        = gn_last_update_by
                  ,last_update_date       = gd_last_update_date
                  ,last_update_login      = gn_last_update_login
                  ,request_id             = gn_request_id
                  ,program_application_id = gn_program_application_id
                  ,program_id             = gn_program_id
                  ,program_update_date    = gd_program_update_date
            WHERE  source_document_number   = lr_mst_rec.source_doc_number
            AND    source_document_line_num = lr_mst_rec.source_doc_line_num;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
--
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        -- 発注明細の更新
        BEGIN
          UPDATE po_lines_all
          SET    attribute7             = lr_mst_rec.attribute6     -- 受入数量
                ,last_update_date       = gd_last_update_date
                ,last_updated_by        = gn_last_update_by
                ,last_update_login      = gn_last_update_login
                ,request_id             = gn_request_id
                ,program_application_id = gn_program_application_id
                ,program_id             = gn_program_id
                ,program_update_date    = gd_program_update_date
          WHERE  po_line_id   = lr_mst_rec.po_line_id
          AND    po_header_id = lr_mst_rec.po_header_id;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
    END LOOP set_data_loop;
--
    BEGIN
--
      -- 発注明細更新
      UPDATE po_lines_all
      SET    attribute13            = gv_flg_on                     -- 数量確定フラグ:'Y'
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  po_header_id IN (
        SELECT po_header_id
        FROM   po_headers_all
        WHERE  segment1 = gv_header_number
      );
--
      -- 発注ヘッダ更新
      UPDATE po_headers_all
      SET    attribute1             = gv_qty_fixed_type             -- ステータス:数量確定済('30')
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  segment1 = gv_header_number;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_rcv_data;
--
  /***********************************************************************************
   * Procedure Name   : keep_rcv_data
   * Description      : 受入実績情報保持(B-4)
   ***********************************************************************************/
  PROCEDURE keep_rcv_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keep_rcv_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<keep_data_loop>>
    FOR i IN 0..gn_b_3_cnt-1 LOOP
--
      -- 登録データ
      IF (gt_b_03_mast(i).rcv_rtn_quantity IS NULL) THEN
        gt_b_03_mast(i).exec_flg := gn_mode_ins;
--
      -- 更新データ
      ELSE
        -- 仕入先出荷実績数量<>受入返品数量
        IF ((gt_b_03_mast(i).attribute6 IS NOT NULL)
        AND (gt_b_03_mast(i).rcv_rtn_quantity <> gt_b_03_mast(i).def_qty6)) THEN
          gt_b_03_mast(i).exec_flg := gn_mode_upd;
        ELSE
          gt_b_03_mast(i).exec_flg := gn_mode_oth;
        END IF;
      END IF;
--
      -- 単位<>発注単位
      IF ((gt_b_03_mast(i).unit_code <> gt_b_03_mast(i).attribute10)
      AND (gt_b_03_mast(i).attribute10 = 'CS')) THEN
        -- 2008/05/24 UPD START Y.Takayama
        --gt_b_03_mast(i).rcv_qty := gt_b_03_mast(i).def_qty6 * gt_b_03_mast(i).pla_qty;
        gt_b_03_mast(i).rcv_qty := gt_b_03_mast(i).def_qty6 * TO_NUMBER(gt_b_03_mast(i).pla_qty);
        -- 2008/05/24 UPD END   Y.Takayama
      ELSE
        gt_b_03_mast(i).rcv_qty := gt_b_03_mast(i).def_qty6;
      END IF;
--
      -- 受入数量差分
      -- 計算した受入数量 - 受入返品実績(アドオン)の数量
      -- 2008/05/24 UPD START Y.Takayama
      --gt_b_03_mast(i).rcv_cov_qty := gt_b_03_mast(i).rcv_qty - gt_b_03_mast(i).xrt_qty;
      gt_b_03_mast(i).rcv_cov_qty := gt_b_03_mast(i).rcv_qty - NVL(gt_b_03_mast(i).xrt_qty, 0);
      -- 2008/05/24 UPD END   Y.Takayama
--
    END LOOP keep_data_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END keep_rcv_data;
--
  /***********************************************************************************
   * Procedure Name   : get_rcv_data
   * Description      : 受入実績作成対象データ取得(B-3)
   ***********************************************************************************/
  PROCEDURE get_rcv_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rcv_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    mst_rec           masters_rec;
--
    -- *** ローカル・カーソル ***
    CURSOR po_data_cur
    IS
      SELECT xxpo.segment1 as po_header_number         -- 発注番号
            ,xxpo.po_header_id                         -- 発注ヘッダID
            ,xxpo.vendor_id                            -- 仕入先ID
            ,xxpo.h_attribute5                         -- 納入先コード
            ,xxpo.h_attribute9                         -- 依頼番号
            ,xxpo.h_attribute4                         -- 納入日
            ,xxpo.h_attribute6                         -- 直送区分
            ,xxpo.h_attribute10                        -- 部署コード
            ,xxpo.h_attribute3                         -- 斡旋者ID
            ,xxpo.po_line_id                           -- 発注明細ID
-- 2009/12/02 v1.19 T.Yoshimoto Add Start 本稼動障害#263
            ,xxpo.line_location_id                  -- 発注納入明細ID
-- 2009/12/02 v1.19 T.Yoshimoto Add End 本稼動障害#263
            ,xxpo.line_num                             -- 明細番号
            ,xxpo.item_id                              -- 品目ID
            ,xxpo.l_attribute1 as lot_no               -- ロットNO
            ,xxpo.l_attribute5                         -- 仕入先出荷日
            ,xxpo.l_attribute6                         -- 仕入先出荷数量
            ,xxpo.l_attribute8                         -- 単価
            ,xxpo.unit_meas_lookup_code                -- 単位
            ,xxpo.l_attribute10                        -- 発注単位
            -- 2008/05/24 UPD START Y.Takayama
            --,xxpo.quantity as pla_qty                  -- 入数
            ,xxpo.l_attribute4 as pla_qty                  -- 入数
            -- 2008/05/24 UPD START Y.Takayama
            ,xxpo.l_attribute7                         -- 受入数量
            ,xilv.inventory_location_id                -- 保管場所ID
            ,xvv.segment1                              -- 仕入先番号
            ,xiv.item_no                               -- 品目コード
            ,ilm.lot_id                                -- ロットID
            ,xrt.source_document_number                -- 元文書番号
            ,xrt.source_document_line_num              -- 元文書明細番号
            ,xrt.quantity as xrt_qty                   -- 数量
            ,xrt.rcv_rtn_quantity                      -- 受入返品数量
            ,xrt.conversion_factor                     -- 換算入数
            ,rsl.attribute1                            -- 取引ID
            ,xiv.lot_ctl                               -- ロット
            ,xiv.item_id as item_idv                   -- 品目ID
            ,ilm.expire_date                           -- ロット失効日
      FROM   xxcmn_item_locations_v xilv               -- OPM保管場所情報VIEW
            ,xxcmn_vendors_v xvv                       -- 仕入先情報VIEW
            ,xxcmn_item_mst_v xiv                      -- OPM品目情報VIEW
            ,ic_lots_mst ilm                           -- OPMロットマスタ
            ,xxpo_rcv_and_rtn_txns xrt                 -- 受入返品実績(アドオン)
            ,rcv_shipment_lines rsl                    -- 受入明細
            ,(SELECT pha.po_header_id
                    ,pha.attribute3 as h_attribute3    -- 斡旋者ID
                    ,pha.attribute4 as h_attribute4    -- 納入日
                    ,pha.attribute5 as h_attribute5    -- 納入先コード
                    ,pha.attribute6 as h_attribute6    -- 直送区分
                    ,pha.attribute9 as h_attribute9    -- 依頼番号
                    ,pha.attribute10 as h_attribute10  -- 部署コード
                    ,pha.vendor_id
                    ,pha.segment1
                    ,pla.po_line_id
-- 2009/12/02 v1.19 T.Yoshimoto Add Start 本稼動障害#263
                    ,plla.line_location_id          -- 発注納入明細ID
-- 2009/12/02 v1.19 T.Yoshimoto Add End 本稼動障害#263
                    ,pla.item_id
                    ,pla.line_num
                    ,pla.attribute1 as l_attribute1    -- ロット番号
                    -- 2008/05/24 ADD START Y.Takayama
                    ,pla.attribute4 as l_attribute4    -- 在庫入数
                    -- 2008/05/24 ADD END   Y.Takayama
                    ,pla.attribute5 as l_attribute5    -- 仕入先出荷日
                    ,pla.attribute6 as l_attribute6    -- 仕入先出荷数量
                    ,pla.attribute7 as l_attribute7    -- 受入数量
                    ,pla.attribute8 as l_attribute8    -- 仕入定価
                    ,pla.attribute10 as l_attribute10  -- 発注単位
                    ,pla.unit_meas_lookup_code
                    ,pla.quantity
-- 2008/12/06 H.Itou Add Start
                    ,pla.cancel_flag                   -- 削除フラグ
-- 2008/12/06 H.Itou Add End
              FROM  po_headers_all pha,                -- 発注ヘッダ
                    po_lines_all  pla                  -- 発注明細
-- 2009/12/02 v1.19 T.Yoshimoto Add Start 本稼動障害#263
                   ,po_line_locations_all plla         -- 発注納入明細
-- 2009/12/02 v1.19 T.Yoshimoto Add End 本稼動障害#263
              WHERE pha.po_header_id = pla.po_header_id
-- 2009/12/02 v1.19 T.Yoshimoto Add Start 本稼動障害#263
              AND   plla.po_header_id = pha.po_header_id
              AND   plla.po_line_id   = pla.po_line_id
-- 2009/12/02 v1.19 T.Yoshimoto Add End 本稼動障害#263
             ) xxpo
      WHERE xxpo.h_attribute5 = xilv.segment1
      AND   xxpo.vendor_id    = xvv.vendor_id
      AND   xxpo.item_id      = xiv.inventory_item_id
      AND   NVL(xxpo.l_attribute1,gv_defaultlot) = ilm.lot_no
      AND   xiv.item_id       = ilm.item_id
      AND   xxpo.segment1     = xrt.source_document_number(+)
      AND   xxpo.line_num     = xrt.source_document_line_num(+)
      AND   TO_CHAR(xrt.txns_id) = rsl.attribute1(+)
-- 2008/12/06 H.Itou Add Start
      AND   NVL(xxpo.cancel_flag, 'N') = 'N'            -- 削除済みの明細は対象外
-- 2008/12/06 H.Itou Add End
      AND   xxpo.segment1     = gv_header_number;
--
    -- *** ローカル・レコード ***
    lr_po_data_rec po_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    OPEN po_data_cur;
--
    <<po_data_loop>>
    LOOP
      FETCH po_data_cur INTO lr_po_data_rec;
      EXIT WHEN po_data_cur%NOTFOUND;
--
      mst_rec.po_header_number    := lr_po_data_rec.po_header_number;
      mst_rec.po_header_id        := lr_po_data_rec.po_header_id;
      mst_rec.vendor_id           := lr_po_data_rec.vendor_id;
      mst_rec.pha_def5            := lr_po_data_rec.h_attribute5;
      mst_rec.attribute9          := lr_po_data_rec.h_attribute9;
      mst_rec.attribute4          := lr_po_data_rec.h_attribute4;
      mst_rec.h_attribute10       := lr_po_data_rec.h_attribute10;
      mst_rec.po_line_id          := lr_po_data_rec.po_line_id;
-- 2009/12/02 v1.19 T.Yoshimoto Add Start 本稼動障害#263
      mst_rec.po_line_location_id := lr_po_data_rec.line_location_id;
-- 2009/12/02 v1.19 T.Yoshimoto Add End 本稼動障害#263
      mst_rec.line_num            := lr_po_data_rec.line_num;
      mst_rec.item_id             := lr_po_data_rec.item_id;
      mst_rec.lot_no              := lr_po_data_rec.lot_no;
      mst_rec.pla_def5            := lr_po_data_rec.l_attribute5;
      mst_rec.attribute6          := lr_po_data_rec.l_attribute6;
      mst_rec.unit_code           := lr_po_data_rec.unit_meas_lookup_code;
      mst_rec.attribute10         := lr_po_data_rec.l_attribute10;
      mst_rec.pla_qty             := lr_po_data_rec.pla_qty;
      mst_rec.attribute7          := lr_po_data_rec.l_attribute7;
      mst_rec.source_doc_number   := lr_po_data_rec.source_document_number;
      mst_rec.source_doc_line_num := lr_po_data_rec.source_document_line_num;
      mst_rec.xrt_qty             := lr_po_data_rec.xrt_qty;
      mst_rec.rcv_rtn_quantity    := lr_po_data_rec.rcv_rtn_quantity;
      mst_rec.conversion_factor   := lr_po_data_rec.conversion_factor;
      mst_rec.inv_location_id     := lr_po_data_rec.inventory_location_id;
      mst_rec.segment1            := lr_po_data_rec.segment1;
      mst_rec.item_no             := lr_po_data_rec.item_no;
      mst_rec.lot_id              := lr_po_data_rec.lot_id;
      mst_rec.attribute1          := lr_po_data_rec.attribute1;
      mst_rec.drop_ship_type      := lr_po_data_rec.h_attribute6;
      mst_rec.unit_price          := lr_po_data_rec.l_attribute8;
      mst_rec.lot_ctl             := lr_po_data_rec.lot_ctl;
      mst_rec.expire_date         := lr_po_data_rec.expire_date;
      mst_rec.item_idv            := lr_po_data_rec.item_idv;
      mst_rec.h_attribute3        := lr_po_data_rec.h_attribute3;
--
      mst_rec.def_date4 := FND_DATE.STRING_TO_DATE(lr_po_data_rec.h_attribute4,'YYYY/MM/DD');
      mst_rec.def_date5 := FND_DATE.STRING_TO_DATE(lr_po_data_rec.l_attribute5,'YYYY/MM/DD');
      mst_rec.def_qty6  := TO_NUMBER(lr_po_data_rec.l_attribute6);
      mst_rec.def_qty7  := TO_NUMBER(lr_po_data_rec.l_attribute7);
--
-- 2011/06/07 v1.20 K.Kubo Add Start E_本稼動_01786
      gn_po_header_id             := lr_po_data_rec.po_header_id;               -- 発注ヘッダID
-- 2011/06/07 v1.20 K.Kubo Add End
--
      BEGIN
        SELECT mil.organization_id
              ,mil.subinventory_code
              ,mil.inventory_location_id
        INTO   mst_rec.organization_id
              ,mst_rec.subinventory
              ,mst_rec.locator_id
        FROM  mtl_item_locations mil
        WHERE mil.segment1 = mst_rec.pha_def5;           -- 納入先コード
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          mst_rec.organization_id := NULL;
          mst_rec.subinventory    := NULL;
          mst_rec.locator_id      := NULL;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      IF (mst_rec.h_attribute3 IS NOT NULL) THEN
        mst_rec.assen_vendor_id := TO_NUMBER(mst_rec.h_attribute3);
--
        -- 仕入先マスタの検索
        BEGIN
          SELECT pv.segment1
          INTO   mst_rec.assen_vendor_code
          FROM   xxcmn_vendors2_v pv
          WHERE  pv.vendor_id = mst_rec.assen_vendor_id
          AND    pv.start_date_active <= TRUNC(mst_rec.def_date4)       -- 納入日
          AND    pv.end_date_active >= TRUNC(mst_rec.def_date4)         -- 納入日
          AND    ROWNUM       = 1;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            mst_rec.assen_vendor_id   := NULL;
            mst_rec.assen_vendor_code := NULL;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
      ELSE
        mst_rec.assen_vendor_id   := NULL;
        mst_rec.assen_vendor_code := NULL;
      END IF;
--
      gt_b_03_mast(gn_b_3_cnt) := mst_rec;
--
      gn_b_3_cnt := gn_b_3_cnt + 1;
--
    END LOOP po_data_loop;
--
    CLOSE po_data_cur;
--
    -- データが存在しない
    IF (gn_b_3_cnt < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10066',
                                            gv_tkn_table_num,
                                            '発注明細',
                                            gv_tkn_po_num,
                                            gv_header_number);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 受入返品実績(アドオン)のロック
    BEGIN
      OPEN gc_lock_xrt_cur;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10138');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- グループIDの取得
    SELECT rcv_interface_groups_s.NEXTVAL
    INTO   gn_group_id
    FROM   DUAL;
--
-- 2008/05/14 削除
--    gn_group_id := gn_group_id || TO_NUMBER(gv_header_number);
--
    -- 依頼番号の取得
    SELECT pha.attribute9
    INTO   gv_request_no
    FROM   po_headers_all pha
    WHERE  pha.segment1 = gv_header_number
    AND    ROWNUM = 1;
--
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
    -- 依頼NOの出力
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30023',
                                          gv_tkn_request_num,
                                          gv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (po_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE po_data_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END get_rcv_data;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(B-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_po_number        IN         VARCHAR2,         -- 発注番号
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
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
--
    -- 発注番号がNULL
    IF (iv_po_number IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10102',
                                            gv_tkn_para_name,
                                            '発注番号');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    -- 発注番号入力あり
    ELSE
--
      gv_header_number := iv_po_number;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-30039',
                                            gv_tkn_po_num,
                                            iv_po_number);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- デフォルトロット
    gv_defaultlot := FND_PROFILE.VALUE('IC$DEFAULT_LOT');
--
    -- WHOカラムの取得
    gn_created_by             := FND_GLOBAL.USER_ID;           -- 作成者
    gd_creation_date          := SYSDATE;                      -- 作成日
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- 最終更新者
    gd_last_update_date       := SYSDATE;                      -- 最終更新日
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    gd_program_update_date    := SYSDATE;                      -- プログラム更新日
--    gn_person_id              := FND_GLOBAL.USER_ID;
--
    -- 2008/04/16 修正
    BEGIN
      SELECT employee_id
      INTO   gn_person_id
-- 2009/03/30 H.Iida Mod Start 本番障害#1346対応
      FROM   fnd_user          fu
            ,per_all_people_f  papf
      WHERE  fu.user_id = gn_created_by
      AND    fu.employee_id = papf.person_id
      AND    papf.attribute3 IN ('1', '2')
-- 2009/03/30 H.Iida Mod End
-- 2009/09/17 v1.18 T.Yoshimoto Add Start 本番#1632
      AND    TRUNC(papf.effective_start_date) <= TRUNC(SYSDATE)
      AND    TRUNC(papf.effective_end_date) >= TRUNC(SYSDATE)
-- 2009/09/17 v1.18 T.Yoshimoto Add End 本番#1632
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gn_person_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_po_number    IN            VARCHAR2,       -- 発注番号
    ov_errbuf          OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- プログラム名
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
    ln_req_id     NUMBER;
    lb_ret        BOOLEAN;
    lb_qty_ret    BOOLEAN;
    ln_ret        NUMBER;
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
    ln_group_id_count NUMBER := 0;
-- 2009/01/15 v1.16 T.Yoshimoto Add End
--
    -- ===============================
    -- ローカル・カーソル
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_b_3_cnt    := 0;
    gn_b_5_cnt    := 0;
    gn_b_7_cnt    := 0;
    gn_b_9_cnt    := 0;
    gn_b_15_flg   := 0;
    gn_b_16_flg   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ================================
    -- B-2.パラメータチェック
    -- ================================
    parameter_check(
      iv_po_number,       -- 発注番号
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- B-3.受入実績作成対象データ取得
    -- ================================
    get_rcv_data(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- B-4.受入実績情報保持
    -- ================================
    keep_rcv_data(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 仕入先出荷数量のチェック
    check_quantity(
      lb_qty_ret,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 仕入先出荷数量が全明細に設定あり
    IF (lb_qty_ret) THEN
      -- ================================
      -- B-5.受入実績情報登録
      -- ================================
      set_rcv_data(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
-- 2011/06/07 v1.20 K.Kubo Add Start
    -- ================================
    -- B-20.仕入実績作成処理管理TBLの削除
    -- ================================
    -- 仕入実績情報削除 関数実施
    xxpo_common3_pkg.delete_result(
       gn_po_header_id -- (IN)発注ヘッダＩＤ
      ,lv_errbuf       -- (OUT)エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- (OUT)リターン・コード             --# 固定 #
      ,lv_errmsg       -- (OUT)ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2011/06/07 v1.20 K.Kubo Add End

    -- ================================
    -- B-6.出荷実績作成パターン判定
    -- ================================
    check_deli_pat(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- カーソルが開いていれば
    IF (gc_lock_xrt_cur%ISOPEN) THEN
      -- カーソルのクローズ
      CLOSE gc_lock_xrt_cur;
    END IF;
--
    COMMIT;
--
    -- 異常終了以外
    IF (lv_retcode <> gv_status_error) THEN
--
-- 2009/01/15 v1.16 T.Yoshimoto Del Start
/*
      IF ((gn_b_5_cnt > 0) OR (gn_b_9_cnt > 0)) THEN
--
        IF ((gn_b_5_cnt > 0) AND (gn_group_id2 IS NOT NULL)) THEN
--
          -- 受入取引処理
          ln_ret := FND_REQUEST.SUBMIT_REQUEST(
                        application  => gv_rcv_app              -- アプリケーション短縮名
                       ,program      => gv_rcv_app_name         -- プログラム名
                       ,argument1    => 'BATCH'                 -- 処理モード
                       ,argument2    => TO_CHAR(gn_group_id2)   -- グループID
                      );
--
          IF (ln_ret = 0) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  'APP-XXPO-10056');
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 要求セットの準備
        lb_ret := FND_SUBMIT.SET_REQUEST_SET(gv_app_name, gv_request_set_name);
--
        IF (NOT lb_ret) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10024',
                                                gv_tkn_conc_name,
                                                gv_request_name);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
*/
-- 2009/01/15 v1.16 T.Yoshimoto Del End
--
      -- 受入オープンIFにデータ登録あり
      -- 受注ヘッダアドオンの登録・更新あり
      IF ((gn_b_5_cnt > 0) OR (gn_b_9_cnt > 0)) THEN
--
-- 2009/01/15 v1.16 T.Yoshimoto Add Start
        <<proc_rcv_exec_loop>>
        LOOP
-- 2009/01/15 v1.16 T.Yoshimoto Add End
-- 2009/01/15 v1.16 T.Yoshimoto Mod Start
/*
        -- ================================
        -- B-15.受入取引処理起動
        -- ================================
        proc_rcv_exec(
          lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          lv_retcode,       -- リターン・コード             --# 固定 #
          lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
*/
          -- 新規作成処理
          IF (gt_group_id_mast(ln_group_id_count).exec_flg = gn_mode_ins) THEN
--
            -- 受入取引処理
            ln_ret := FND_REQUEST.SUBMIT_REQUEST(
                          application  => gv_rcv_app              -- アプリケーション短縮名
                         ,program      => gv_rcv_app_name         -- プログラム名
                         ,argument1    => 'BATCH'                 -- 処理モード
                         ,argument2    => TO_CHAR(gt_group_id_mast(ln_group_id_count).group_id)   -- グループID
                        );
            IF (ln_ret = 0) THEN
              RAISE global_api_expt;
            END IF;
--
            EXIT ;  -- ループ処理終了
          END IF;
--
          -- 訂正処理
          IF (gt_group_id_mast(ln_group_id_count).exec_flg = gn_mode_upd) THEN
--
            -- 要求セットの準備
            lb_ret := FND_SUBMIT.SET_REQUEST_SET(gv_app_name, gv_request_set_name);
--
            IF (NOT lb_ret) THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                    'APP-XXPO-10024',
                                                    gv_tkn_conc_name,
                                                    gv_request_name);
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END IF;
--
            -- ================================
            -- B-15.受入取引処理起動(要求セット用訂正1)
            -- ================================
            proc_rcv_exec(
              gt_group_id_mast(ln_group_id_count).group_id,
              gv_rcv_stage,
              lv_errbuf,        -- エラー・メッセージ           --# 固定 #
              lv_retcode,       -- リターン・コード             --# 固定 #
              lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
--
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                    'APP-XXPO-10056');
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            END IF;
--
            ln_group_id_count := ln_group_id_count + 1;
--
            -- ================================
            -- B-15.受入取引処理起動(要求セット用訂正2)
            -- ================================
            proc_rcv_exec(
              gt_group_id_mast(ln_group_id_count).group_id,
              gv_rcv_stage2,
              lv_errbuf,        -- エラー・メッセージ           --# 固定 #
              lv_retcode,       -- リターン・コード             --# 固定 #
              lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
--
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                    'APP-XXPO-10056');
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            END IF;
          END IF;
--
/*
        -- ================================
        -- B-16.出荷依頼/出荷実績作成処理起動
        -- ================================
        proc_deli_exec(
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
*/
--
      -- 要求セットに設定あり
      IF ((gn_b_15_flg = 1) OR (gn_b_16_flg = 1)) THEN
--
        -- 要求セットの発行
        ln_req_id := FND_SUBMIT.SUBMIT_SET(null,FALSE);
--
        -- 処理失敗
        IF (ln_req_id = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                'APP-XXPO-10024',
                                                gv_tkn_conc_name,
                                                gv_request_name);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- 要求IDの表示
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-30021',
                                              gv_tkn_conc_name,
                                              gv_request_name,
                                              gv_tkn_conc_id,
                                              ln_req_id);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          END IF;
--
          -- 訂正処理の終了条件
          EXIT WHEN (ln_group_id_count = gn_group_id_cnt-1);
--
          ln_group_id_count := ln_group_id_count + 1;
--
        END LOOP proc_rcv_exec_loop;
      END IF;
-- 2009/01/15 v1.16 T.Yoshimoto Mod End
--
      -- ================================
      -- B-17.処理結果情報出力
      -- ================================
      disp_report(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--##########################################
--##### その他処理が必要なら、追加する #####
--##########################################
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (gc_lock_xrt_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_lock_xrt_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (gc_lock_xrt_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_lock_xrt_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (gc_lock_xrt_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE gc_lock_xrt_cur;
      END IF;
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
    errbuf           OUT NOCOPY VARCHAR2,           -- エラー・メッセージ           --# 固定 #
    retcode          OUT NOCOPY VARCHAR2,           -- リターン・コード             --# 固定 #
    iv_po_number  IN            VARCHAR2)           -- 1.発注番号
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- 2012/03/06 v1.21 K.Nakamura Add Start
    ln_po_header_id  po_headers_all.po_header_id%TYPE;  -- 発注ヘッダID
    ln_xsrm_cnt      NUMBER;                            -- 仕入実績作成処理管理TBL件数
-- 2012/03/06 v1.21 K.Nakamura Add End
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      iv_po_number,                                -- 1.発注番号
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
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
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
--
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
-- 2012/03/06 v1.21 K.Nakamura Add Start
      -- ================================
      -- D-21.仕入実績作成処理管理TBLの削除(エラー発生時)
      -- ================================
      -- 発注番号入力あり
      IF (iv_po_number IS NOT NULL) THEN
        BEGIN
          SELECT pha.po_header_id po_header_id
          INTO   ln_po_header_id
          FROM   po_headers_all   pha
          WHERE  pha.segment1   = iv_po_number
          AND    ROWNUM         = 1;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
        --
        IF (ln_po_header_id IS NOT NULL) THEN
          -- 件数確認
          SELECT COUNT(xsrm.po_header_id)     xsrm_cnt
          INTO   ln_xsrm_cnt
          FROM   xxpo_stock_result_manegement xsrm
          WHERE  xsrm.po_header_id = ln_po_header_id;
          -- COMMIT前にエラーが発生した場合、削除データが存在するため
          IF (ln_xsrm_cnt > 0) THEN
            BEGIN
              -- 仕入実績情報削除 関数実施
              xxpo_common3_pkg.delete_result(
                                 ln_po_header_id       -- 発注ヘッダID
                                ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
                                ,lv_retcode            -- リターン・コード             --# 固定 #
                                ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                               );
              -- 異常終了は暗黙ロールバックされるため、COMMIT発行
              COMMIT;
            --
            EXCEPTION
              WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM);
            END;
          END IF;
        END IF;
      END IF;
-- 2012/03/06 v1.21 K.Nakamura Add End
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxpo320001c;
/
