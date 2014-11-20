CREATE OR REPLACE PACKAGE BODY xxpo310004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *quantity
 * Package Name     : xxpo310004c(body)
 * Description      : HHT受入実績計上
 * MD.050           : 受入実績            T_MD050_BPO_310
 * MD.070           : HHT受入実績計上     T_MD070_BPO_31G
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  keep_po_head_id        発注ヘッダIDの保持
 *  get_location           倉庫、組織、会社の取得
 *  get_lot_mst            OPMロットマスタの取得
 *  init_proc              前処理                                          (F-1)
 *  other_data_get         受入日により処理対象外となる受入実績情報取得    (F-2)
 *  disp_other_data        受入対象外情報出力                              (F-3)
 *  master_data_get        処理対象の受入情報取得                          (F-4)
 *  proper_check           妥当性チェック                                  (F-5)
 *  insert_open_if         受入オープンIFへの受入情報登録                  (F-6)
 *  insert_rcv_and_rtn     受入返品実績(アドオン)への受入情報登録          (F-7)
 *  upd_po_lines           発注明細更新                                    (F-8)
 *  upd_lot_mst            ロット更新                                      (F-9)
 *  insert_tran            在庫取引に出庫情報登録                          (F-10)
 *  disp_report            処理完了発注情報出力                            (F-11)
 *  upd_status             発注ステータス更新                              (F-12)
 *  commit_open_if         受入オープンIFに登録した内容の反映              (F-13)
 *  del_rcv_txns_if        受入実績IF(アドオン)の全データ削除              (F-14)
 *  term_proc              終了処理                                        (F-15)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/28    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/21    1.1   Oracle 山根 一浩 変更要求No43対応
 *  2008/05/21    1.2   Oracle 山根 一浩 変更要求No109対応
 *                                       結合テスト不具合ログ#300_3対応
 *  2008/05/23    1.3   Oracle 山根 一浩 結合テスト不具合ログ対応
 *  2008/06/26    1.4   Oracle 山根 一浩 結合テスト不具合No84,86対応
 *  2008/07/09    1.5   Oracle 山根 一浩 I_S_192対応
 *  2008/08/06    1.6   Oracle 山根 一浩 課題#32対応
 *  2008/09/25    1.7   Oracle 山根 一浩 指摘23対応
 *  2008/12/30    1.8   Oracle 吉元 強樹 標準-ｱﾄﾞｵﾝ受入差異対応
 *  2008/12/30    1.9   Oracle 吉元 強樹 在庫調整APIパラメータ不備対応
 *  2009/01/23    1.10  Oracle 椎名 昭圭 本番#1047対応
 *  2009/01/27    1.11  Oracle 椎名 昭圭 本番#819対応
 *  2009/01/28    1.12  Oracle 椎名 昭圭 本番#1047対応(再)
 *  2009/02/10    1.13  Oracle 椎名 昭圭 本番#1127対応
 *  2009/03/30    1.14  Oracle 飯田 甫   本番#1346対応
 *  2009/04/03    1.15  Oracle 吉元 強樹 本番#1368対応
 *  2010/04/21    1.16  SCS 伊藤 ひとみ  E_本稼動_02210対応
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
  master_data_get_expt      EXCEPTION;     -- 受入情報取得エラー
  term_proc_expt            EXCEPTION;     -- 終了処理エラー
--
  lock_expt                 EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo310004c';   -- パッケージ名
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';          -- アプリケーション短縮名
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';         -- アプリケーション短縮名
--
  gv_tbl_name      CONSTANT VARCHAR2(100) := 'xxpo_rcv_txns_interface';
--
  -- トークン
  gv_tkn_api_name       CONSTANT VARCHAR2(20) := 'API_NAME';
  gv_tkn_count          CONSTANT VARCHAR2(20) := 'COUNT';
  gv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';
  gv_tkn_h_no           CONSTANT VARCHAR2(20) := 'H_NO';
  gv_tkn_m_no           CONSTANT VARCHAR2(20) := 'M_NO';
  gv_tkn_date           CONSTANT VARCHAR2(20) := 'DATE';
  gv_tkn_name           CONSTANT VARCHAR2(20) := 'NAME';
  gv_tkn_item_no        CONSTANT VARCHAR2(20) := 'ITEM_NO';
  gv_tkn_value          CONSTANT VARCHAR2(20) := 'VALUE';
  gv_tkn_rcv_num        CONSTANT VARCHAR2(20) := 'RCV_NUM';
  gv_tkn_name_vendor    CONSTANT VARCHAR2(20) := 'VENDOR';
  gv_tkn_name_shipment  CONSTANT VARCHAR2(20) := 'SHIPMENT';
  gv_tkn_cnt            CONSTANT VARCHAR2(20) := 'CNT';              -- 2008/09/25
--
  gv_tkn_number_31g_01    CONSTANT VARCHAR2(15) := 'APP-XXPO-10027';
  gv_tkn_number_31g_02    CONSTANT VARCHAR2(15) := 'APP-XXPO-10053';
  gv_tkn_number_31g_03    CONSTANT VARCHAR2(15) := 'APP-XXPO-10054';
  gv_tkn_number_31g_04    CONSTANT VARCHAR2(15) := 'APP-XXPO-10055';
  gv_tkn_number_31g_05    CONSTANT VARCHAR2(15) := 'APP-XXPO-10057';
  gv_tkn_number_31g_06    CONSTANT VARCHAR2(15) := 'APP-XXPO-10058';
  gv_tkn_number_31g_07    CONSTANT VARCHAR2(15) := 'APP-XXPO-10059';
  gv_tkn_number_31g_08    CONSTANT VARCHAR2(15) := 'APP-XXPO-10060';
  gv_tkn_number_31g_09    CONSTANT VARCHAR2(15) := 'APP-XXPO-10076';
  gv_tkn_number_31g_10    CONSTANT VARCHAR2(15) := 'APP-XXPO-30026';
  gv_tkn_number_31g_11    CONSTANT VARCHAR2(15) := 'APP-XXPO-30027';
  gv_tkn_number_31g_12    CONSTANT VARCHAR2(15) := 'APP-XXPO-10022';
--
  --2008/09/25 Add
  gv_tkn_number_31g_13    CONSTANT VARCHAR2(15) := 'APP-XXPO-10269';
  gv_tkn_number_31g_14    CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';    -- 処理件数
  gv_tkn_number_31g_15    CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';    -- 成功件数
  gv_tkn_number_31g_16    CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';    -- エラー件数
  gv_tkn_number_31g_17    CONSTANT VARCHAR2(15) := 'APP-XXPO-10293'; -- 2010/04/21 v1.16 H.Itou Add E_本稼動_02210
--
  gv_tkn_name_vendor_code   CONSTANT VARCHAR2(50) := '取引先コード';
  gv_tkn_name_location_code CONSTANT VARCHAR2(50) := '納入先コード';
  gv_tkn_name_item_code     CONSTANT VARCHAR2(50) := '品目コード';
  gv_tkn_name_lot_number    CONSTANT VARCHAR2(50) := 'ロットNo';
  gv_tkn_name_rcv_date      CONSTANT VARCHAR2(50) := '受入日';       -- 2010/04/21 v1.16 H.Itou Add E_本稼動_02210
--
  gv_tbl_name_po_head       CONSTANT VARCHAR2(50) := '発注ヘッダ';
  gv_tbl_name_po_line       CONSTANT VARCHAR2(50) := '発注明細';
  gv_tbl_name_lot_mast      CONSTANT VARCHAR2(50) := 'OPMロットマスタ';
--
  -- 受入取引処理
  gv_appl_name           CONSTANT VARCHAR2(50) := 'PO';
  gv_prg_name            CONSTANT VARCHAR2(50) := 'RVCTP';
  gv_exec_mode           CONSTANT VARCHAR2(50) := 'BATCH';
--
  gv_add_status_zmi      CONSTANT VARCHAR2(5)  := '20';              -- 発注作成済
  gv_add_status_rcv_on   CONSTANT VARCHAR2(5)  := '25';              -- 受入あり
  gv_add_status_num_zmi  CONSTANT VARCHAR2(5)  := '30';              -- 数量確定済
  gv_add_status_qty_zmi  CONSTANT VARCHAR2(5)  := '35';              -- 金額確定済
  gv_add_status_end      CONSTANT VARCHAR2(5)  := '99';              -- 取消済み     2008/09/25 Add
  gv_po_type_rev         CONSTANT VARCHAR2(1)  := '3';               -- 相手先在庫
-- 2009/01/23 v1.10 ADD START
  gv_prod_class_leaf     CONSTANT VARCHAR2(1)  := '1';               -- リーフ
-- 2009/01/23 v1.10 ADD END
  gv_prod_class_code     CONSTANT VARCHAR2(1)  := '2';               -- ドリンク
-- 2008/12/30 v1.8 T.Yoshimoto Add Start
  gv_item_class_code     CONSTANT VARCHAR2(1)  := '5';               -- 製品
-- 2008/12/30 v1.8 T.Yoshimoto Add End
  gv_txns_type_po        CONSTANT VARCHAR2(1)  := '1';               -- 受入
  gn_lot_ctl_on          CONSTANT NUMBER       := 1;                 -- ロット管理品
  gv_flg_on              CONSTANT VARCHAR2(1)  := 'Y';
  gv_flg_off             CONSTANT VARCHAR2(1)  := 'N';
  gv_one_space           CONSTANT VARCHAR2(1)  := ' ';
-- 2009/03/30 H.Iida ADD START 本番障害#1346
  gv_prf_org_id          CONSTANT VARCHAR2(100) := 'ORG_ID';         -- プロファイル：ORG_ID
-- 2009/03/30 H.Iida ADD END
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- F-2:発注情報取得対象外データ
  TYPE other_rec IS RECORD(
    src_doc_num        xxpo_rcv_txns_interface.source_document_number%TYPE,   -- 元文書番号
    src_doc_line_num   xxpo_rcv_txns_interface.source_document_line_num%TYPE, -- 元文書明細番号
    item_code          xxpo_rcv_txns_interface.item_code%TYPE,                -- 品目コード
    rcv_date           xxpo_rcv_txns_interface.rcv_date%TYPE,                 -- 受入日
    txns_id            xxpo_rcv_txns_interface.txns_id%TYPE,                  -- 取引ID
--
    exec_flg            NUMBER                                    -- 処理フラグ
  );
--
  -- F-4:発注情報取得対象データ
  TYPE masters_rec IS RECORD(
    txns_id            xxpo_rcv_txns_interface.txns_id%TYPE,                  -- 取引ID
    src_doc_num        xxpo_rcv_txns_interface.source_document_number%TYPE,   -- 元文書番号
    vendor_code        xxpo_rcv_txns_interface.vendor_code%TYPE,              -- 取引先コード
    vendor_name        xxpo_rcv_txns_interface.vendor_name%TYPE,              -- 取引先名
    promised_date      xxpo_rcv_txns_interface.promised_date%TYPE,            -- 納入日
    location_code      xxpo_rcv_txns_interface.location_code%TYPE,            -- 納入先コード
    location_name      xxpo_rcv_txns_interface.location_name%TYPE,            -- 納入先名
    src_doc_line_num   xxpo_rcv_txns_interface.source_document_line_num%TYPE, -- 元文書明細番号
    item_code          xxpo_rcv_txns_interface.item_code%TYPE,                -- 品目コード
    item_name          xxpo_rcv_txns_interface.item_name%TYPE,                -- 品目名称
    lot_number         xxpo_rcv_txns_interface.lot_number%TYPE,               -- ロットNo
    producted_date     xxpo_rcv_txns_interface.producted_date%TYPE,           -- 製造日
    koyu_code          xxpo_rcv_txns_interface.koyu_code%TYPE,                -- 固有記号
    quantity           xxpo_rcv_txns_interface.quantity%TYPE,                 -- 指示数量
    rcv_quantity_uom   xxpo_rcv_txns_interface.rcv_quantity_uom%TYPE,         -- 単位コード
    po_description     xxpo_rcv_txns_interface.po_line_description%TYPE,      -- 明細摘要
    rcv_date           xxpo_rcv_txns_interface.rcv_date%TYPE,                 -- 受入日
    rcv_quantity       xxpo_rcv_txns_interface.rcv_quantity%TYPE,             -- 受入数量
    rcv_description    xxpo_rcv_txns_interface.rcv_line_description%TYPE,     -- 受入明細摘要
    po_header_id       po_headers_all.po_header_id%TYPE,                      -- 発注ヘッダID
    segment1           po_headers_all.segment1%TYPE,                          -- 発注番号
    attribute6         po_headers_all.attribute6%TYPE,                        -- 直送区分
    attribute11        po_headers_all.attribute11%TYPE,                       -- 発注区分
    vendor_id          po_headers_all.vendor_id%TYPE,                         -- 取引先ID
    delivery_code      po_headers_all.attribute5%TYPE,                        -- 納入先コード
    department_code    po_headers_all.attribute10%TYPE,                       -- 部署コード
    po_line_id         po_lines_all.po_line_id%TYPE,                          -- 発注明細ID
    line_num           po_lines_all.line_num%TYPE,                            -- 明細番号
    item_id            po_lines_all.item_id%TYPE,                             -- 品目ID
    unit_price         po_lines_all.unit_price%TYPE,                          -- 単価
    lot_no             po_lines_all.attribute1%TYPE,                          -- ロットNo
    unit_code          po_lines_all.unit_meas_lookup_code%TYPE,               -- 単位
    attribute10        po_lines_all.attribute10%TYPE,                         -- 発注単位
    lot_id             ic_lots_mst.lot_id%TYPE,                               -- ロットID
    attribute4         ic_lots_mst.attribute4%TYPE,                           -- 納入日(初回)
    attribute5         ic_lots_mst.attribute5%TYPE,                           -- 納入日(最終)
    item_idv           ic_lots_mst.item_id%TYPE,                              -- 品目ID
    opm_item_id        xxcmn_item_mst_v.item_id%TYPE,                         -- OPM品目ID
    num_of_cases       xxcmn_item_mst_v.num_of_cases%TYPE,                    -- ケース入数
    vendor_stock_whse  xxcmn_vendor_sites_v.vendor_stock_whse%TYPE,           -- 相手先在庫入庫先
    prod_class_code    xxcmn_item_categories3_v.prod_class_code%TYPE,         -- 商品区分
--
-- 2008/12/30 v1.8 T.Yoshimoto Add Start
    item_class_code   xxcmn_item_categories3_v.item_class_code%TYPE,          -- 品目区分
-- 2008/12/30 v1.8 T.Yoshimoto Add End
--
    lot_ctl            xxcmn_item_mst_v.lot_ctl%TYPE,                         -- ロット
    item_no            xxcmn_item_mst_v.item_no%TYPE,                         -- 品目コード
--
    vendor_no          xxcmn_vendors_v.segment1%TYPE,                         -- 仕入先番号
--
    from_whse_code     ic_tran_cmp.whse_code%TYPE,                            -- 倉庫
    co_code            ic_tran_cmp.co_code%TYPE,                              -- 会社
    orgn_code          ic_tran_cmp.orgn_code%TYPE,                            -- 組織
--
    organization_id       mtl_item_locations.organization_id%TYPE,
    subinventory_code     mtl_item_locations.subinventory_code%TYPE,
    inventory_location_id mtl_item_locations.inventory_location_id%TYPE,
--
    -- 2008/08/06 Add ↓
    conv_unit          xxcmn_item_mst_v.conv_unit%TYPE,                       -- 入出庫換算単位
    -- 2008/08/06 Add ↑
--
    def4_date          DATE,                                                  -- 納入日(初回)
    def5_date          DATE,                                                  -- 納入日(最終)
--
    check_result       VARCHAR(1),                               -- 妥当性チェック結果
--
    exec_flg           NUMBER,                                    -- 処理フラグ
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
    line_location_id   po_line_locations_all.line_location_id%TYPE            -- 納入明細ID
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
  );
--
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE other_tbl    IS TABLE OF other_rec    INDEX BY PLS_INTEGER;
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
  -- 取引ID
  TYPE reg_txns_id           IS TABLE OF xxpo_rcv_txns_interface.txns_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- 元文書番号
  TYPE reg_src_doc_num       IS TABLE OF xxpo_rcv_txns_interface.source_document_number   %TYPE INDEX BY BINARY_INTEGER;
  -- 取引先コード
  TYPE reg_vendor_code       IS TABLE OF xxpo_rcv_txns_interface.vendor_code              %TYPE INDEX BY BINARY_INTEGER;
  -- 納入日
  TYPE reg_promised_date     IS TABLE OF xxpo_rcv_txns_interface.promised_date            %TYPE INDEX BY BINARY_INTEGER;
  -- 納入先コード
  TYPE reg_location_code     IS TABLE OF xxpo_rcv_txns_interface.location_code            %TYPE INDEX BY BINARY_INTEGER;
  -- 元文書明細番号
  TYPE reg_src_doc_line_num  IS TABLE OF xxpo_rcv_txns_interface.source_document_line_num %TYPE INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE reg_item_code         IS TABLE OF xxpo_rcv_txns_interface.item_code                %TYPE INDEX BY BINARY_INTEGER;
  -- ロットNo
  TYPE reg_lot_number        IS TABLE OF xxpo_rcv_txns_interface.lot_number               %TYPE INDEX BY BINARY_INTEGER;
  -- 単位コード
  TYPE reg_rcv_quantity_uom  IS TABLE OF xxpo_rcv_txns_interface.rcv_quantity_uom         %TYPE INDEX BY BINARY_INTEGER;
  -- 明細摘要
  TYPE reg_po_description    IS TABLE OF xxpo_rcv_txns_interface.po_line_description      %TYPE INDEX BY BINARY_INTEGER;
  -- 受入日
  TYPE reg_rcv_date          IS TABLE OF xxpo_rcv_txns_interface.rcv_date                 %TYPE INDEX BY BINARY_INTEGER;
  -- 受入数量
  TYPE reg_rcv_quantity      IS TABLE OF xxpo_rcv_txns_interface.rcv_quantity             %TYPE INDEX BY BINARY_INTEGER;
  -- 発注ヘッダID
  TYPE reg_po_header_id      IS TABLE OF po_headers_all.po_header_id                      %TYPE INDEX BY BINARY_INTEGER;
  -- 直送区分
  TYPE reg_attribute6        IS TABLE OF po_headers_all.attribute6                        %TYPE INDEX BY BINARY_INTEGER;
  -- 取引先ID
  TYPE reg_vendor_id         IS TABLE OF po_headers_all.vendor_id                         %TYPE INDEX BY BINARY_INTEGER;
  -- 発注明細ID
  TYPE reg_po_line_id        IS TABLE OF po_lines_all.po_line_id                          %TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE reg_line_num          IS TABLE OF po_lines_all.line_num                            %TYPE INDEX BY BINARY_INTEGER;
  -- 品目ID
  TYPE reg_item_id           IS TABLE OF po_lines_all.item_id                             %TYPE INDEX BY BINARY_INTEGER;
  -- 単価
  TYPE reg_unit_price        IS TABLE OF po_lines_all.unit_price                          %TYPE INDEX BY BINARY_INTEGER;
  -- ロットNo
  TYPE reg_lot_no            IS TABLE OF po_lines_all.attribute1                          %TYPE INDEX BY BINARY_INTEGER;
  -- 単位
  TYPE reg_unit_code         IS TABLE OF po_lines_all.unit_meas_lookup_code               %TYPE INDEX BY BINARY_INTEGER;
  -- 発注単位
  TYPE reg_attribute10       IS TABLE OF po_lines_all.attribute10                         %TYPE INDEX BY BINARY_INTEGER;
  -- ロットID
  TYPE reg_lot_id            IS TABLE OF ic_lots_mst.lot_id                               %TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE reg_rtn_quantity      IS TABLE OF xxpo_rcv_and_rtn_txns.quantity                   %TYPE INDEX BY BINARY_INTEGER;
  -- 換算入数
  TYPE reg_conversion_factor IS TABLE OF xxpo_rcv_and_rtn_txns.conversion_factor          %TYPE INDEX BY BINARY_INTEGER;
  -- 部署コード
  TYPE reg_department_code   IS TABLE OF xxpo_rcv_and_rtn_txns.department_code            %TYPE INDEX BY BINARY_INTEGER;
  -- HEADER_INTERFACE_ID
  TYPE reg_head_if_id        IS TABLE OF rcv_headers_interface.header_interface_id                  %TYPE INDEX BY BINARY_INTEGER;
  -- INTERFACE_TRANSACTION_ID
  TYPE reg_if_tran_id        IS TABLE OF rcv_transactions_interface.interface_transaction_id        %TYPE INDEX BY BINARY_INTEGER;
  -- TRANSACTION_INTERFACE_ID
  TYPE reg_tran_if_id        IS TABLE OF mtl_transaction_lots_interface.transaction_interface_id    %TYPE INDEX BY BINARY_INTEGER;
  -- TRANSACTION_QUANTITY
  TYPE reg_trans_qty         IS TABLE OF mtl_transaction_lots_interface.transaction_quantity        %TYPE INDEX BY BINARY_INTEGER;
  -- PRODUCT_TRANSACTION_ID
  TYPE reg_trans_id          IS TABLE OF mtl_transaction_lots_interface.product_transaction_id      %TYPE INDEX BY BINARY_INTEGER;
  -- TO_ORGANIZATION_ID
  TYPE reg_organization_id   IS TABLE OF rcv_transactions_interface.to_organization_id              %TYPE INDEX BY BINARY_INTEGER;
  -- SUBINVENTORY
  TYPE reg_subinventory      IS TABLE OF rcv_transactions_interface.subinventory                    %TYPE INDEX BY BINARY_INTEGER;
  -- LOCATOR_ID
  TYPE reg_locator_id        IS TABLE OF rcv_transactions_interface.locator_id                      %TYPE INDEX BY BINARY_INTEGER;
-- 2008/05/21 v1.2 Add
  TYPE reg_opm_item_id       IS TABLE OF xxpo_rcv_and_rtn_txns.item_id                              %TYPE INDEX BY BINARY_INTEGER;
-- 2008/05/21 v1.2 Add
-- 2008/06/26 v1.4 Add
  -- 受入返品明細番号
  TYPE reg_rtn_line_num      IS TABLE OF xxpo_rcv_and_rtn_txns.rcv_rtn_line_number                  %TYPE INDEX BY BINARY_INTEGER;
-- 2008/06/26 v1.4 Add
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
  -- 納入明細ID
  TYPE reg_line_location_id  IS TABLE OF po_line_locations_all.line_location_id                     %TYPE INDEX BY BINARY_INTEGER;
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  gt_other_tbl                 other_tbl;    -- 各マスタへ登録するデータ
  gt_master_tbl                masters_tbl;  -- 各マスタへ登録するデータ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_inv_ship_rsn             VARCHAR2(100);              -- 相手先在庫出庫事由
  gv_close_date               VARCHAR2(6);                -- CLOSE年月日
  gn_group_id                 rcv_headers_interface.group_id%TYPE;              -- グループID
  gn_proc_flg                 NUMBER;
  gn_org_txns_cnt             NUMBER;
  gn_proper_error             NUMBER;
  gn_lot_count                NUMBER;
  gn_head_count               NUMBER;
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
  gv_user_name                fnd_user.user_name%TYPE;    -- ユーザ名
-- 2009/03/30 H.Iida ADD START 本番障害#1346
  gv_org_id                   VARCHAR2(1000);             -- ORG_ID
-- 2009/03/30 H.Iida ADD END
--
  -- 項目テーブル型定義
  gt_org_txns_id       reg_txns_id;           -- 取引ID(削除用)
  gt_txns_id           reg_txns_id;           -- 取引ID
  gt_src_doc_num       reg_src_doc_num;       -- 元文書番号
  gt_vendor_code       reg_vendor_code;       -- 取引先コード
  gt_promised_date     reg_promised_date;     -- 納入日
  gt_location_code     reg_location_code;     -- 納入先コード
  gt_src_doc_line_num  reg_src_doc_line_num;  -- 元文書明細番号
  gt_item_code         reg_item_code;         -- 品目コード
  gt_lot_number        reg_lot_number;        -- ロットNo
  gt_rcv_quantity_uom  reg_rcv_quantity_uom;  -- 単位コード
  gt_po_description    reg_po_description;    -- 明細摘要
  gt_rcv_date          reg_rcv_date;          -- 受入日
  gt_rcv_quantity      reg_rcv_quantity;      -- 受入数量
  gt_po_header_id      reg_po_header_id;      -- 発注ヘッダID
  gt_attribute6        reg_attribute6;        -- 直送区分
  gt_vendor_id         reg_vendor_id;         -- 取引先ID
  gt_po_line_id        reg_po_line_id;        -- 発注明細ID
  gt_line_num          reg_line_num;          -- 明細番号
  gt_item_id           reg_item_id;           -- 品目ID
  gt_unit_price        reg_unit_price;        -- 単価
  gt_lot_no            reg_lot_no;            -- ロットNo
  gt_unit_code         reg_unit_code;         -- 単位
  gt_attribute10       reg_attribute10;       -- 発注単位
  gt_lot_id            reg_lot_id;            -- ロットID
  gt_rtn_quantity      reg_rtn_quantity;      -- 数量
  gt_conversion_factor reg_conversion_factor; -- 換算入数
  gt_department_code   reg_department_code;   -- 部署コード
--
  gt_head_if_id        reg_head_if_id;        -- HEADER_INTERFACE_ID
  gt_if_tran_id        reg_if_tran_id;        -- INTERFACE_TRANSACTION_ID
  gt_tran_if_id        reg_tran_if_id;        -- TRANSACTION_INTERFACE_ID
  gt_calc_quantity     reg_rcv_quantity;      -- 計算数量
  gt_trans_qty         reg_trans_qty;         -- TRANSACTION_QUANTITY
  gt_trans_id          reg_trans_id;          -- PRODUCT_TRANSACTION_ID
  gt_trans_lot         reg_lot_number;        -- ロットNo
--
  gt_keep_header_id    reg_po_header_id;      -- 発注ヘッダID
--
  gt_organization_id   reg_organization_id;   -- TO_ORGANIZATION_ID
  gt_subinventory      reg_subinventory;      -- SUBINVENTORY
  gt_locator_id        reg_locator_id;        -- LOCATOR_ID
--
-- 2008/05/21 v1.2 Add
  gt_opm_item_id       reg_opm_item_id;        -- OPM品目ID
-- 2008/05/21 v1.2 Add
-- 2008/06/26 v1.4 Add
  gt_rtn_line_num      reg_rtn_line_num;       -- 受入返品明細番号
-- 2008/06/26 v1.4 Add
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
  gt_line_location_id reg_line_location_id;    -- 納入明細ID
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
--
  /**********************************************************************************
   * Procedure Name   : keep_po_head_id
   * Description      : 発注ヘッダIDを重複せずに保持する
   ***********************************************************************************/
  PROCEDURE keep_po_head_id(
    in_head_id      IN            po_headers_all.po_header_id%TYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'keep_po_head_id';       -- プログラム名
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
    ln_qty         NUMBER;
    ln_flg         NUMBER;
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
    -- 入力あり
    IF (in_head_id IS NOT NULL) THEN
--
      IF (gn_head_count = 0) THEN
        gt_keep_header_id(gn_head_count) := in_head_id;
        gn_head_count := gn_head_count + 1;
--
      ELSE
        ln_flg := 0;
--
        <<check_loop>>
        FOR i IN 0..gn_head_count-1 LOOP
--
          -- 同じ値が存在する
          IF (gt_keep_header_id(i) = in_head_id) THEN
            ln_flg := 1;
            EXIT check_loop;
          END IF;
--
        END LOOP check_loop;
--
        -- 同じ値が存在しない
        IF (ln_flg = 0) THEN
          gt_keep_header_id(gn_head_count) := in_head_id;
          gn_head_count := gn_head_count + 1;
        END IF;
      END IF;
    END IF;
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
  END keep_po_head_id;
--
  /***********************************************************************************
   * Procedure Name   : get_location
   * Description      : 倉庫、組織、会社の取得
   ***********************************************************************************/
  PROCEDURE get_location(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location'; -- プログラム名
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
    SELECT xilv.whse_code                         -- 倉庫
          ,xilv.orgn_code                         -- 組織
          ,som.co_code                            -- 会社
    INTO   ir_mst_rec.from_whse_code
          ,ir_mst_rec.orgn_code
          ,ir_mst_rec.co_code
    FROM   xxcmn_item_locations_v xilv            -- OPM保管場所情報VIEW
          ,sy_orgn_mst_b som                      -- OPMプラントマスタ
    WHERE  xilv.orgn_code = som.orgn_code
    AND    xilv.segment1  = ir_mst_rec.vendor_stock_whse
    AND    ROWNUM         = 1;
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
  END get_location;
--
  /***********************************************************************************
   * Procedure Name   : get_lot_mst
   * Description      : OPMロットマスタの取得
   ***********************************************************************************/
  PROCEDURE get_lot_mst(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
    ir_lot_rec         OUT NOCOPY ic_lots_mst%ROWTYPE,
    ir_lot_cpg_rec     OUT NOCOPY ic_lots_cpg%ROWTYPE,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_mst'; -- プログラム名
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
    BEGIN
      SELECT ilm.item_id
            ,ilm.lot_id
            ,ilm.lot_no
            ,ilm.sublot_no
            ,ilm.lot_desc
            ,ilm.qc_grade
            ,ilm.expaction_code
            ,ilm.expaction_date
            ,ilm.lot_created
            ,ilm.expire_date
            ,ilm.retest_date
            ,ilm.strength
            ,ilm.inactive_ind
            ,ilm.origination_type
            ,ilm.shipvend_id
            ,ilm.vendor_lot_no
            ,ilm.creation_date
            ,ilm.last_update_date
            ,ilm.created_by
            ,ilm.last_updated_by
            ,ilm.trans_cnt
            ,ilm.delete_mark
            ,ilm.text_code
            ,ilm.last_update_login
            ,ilm.program_application_id
            ,ilm.program_id
            ,ilm.program_update_date
            ,ilm.request_id
            ,ilm.attribute1
            ,ilm.attribute2
            ,ilm.attribute3
            ,ilm.attribute4
            ,ilm.attribute5
            ,ilm.attribute6
            ,ilm.attribute7
            ,ilm.attribute8
            ,ilm.attribute9
            ,ilm.attribute10
            ,ilm.attribute11
            ,ilm.attribute12
            ,ilm.attribute13
            ,ilm.attribute14
            ,ilm.attribute15
            ,ilm.attribute16
            ,ilm.attribute17
            ,ilm.attribute18
            ,ilm.attribute19
            ,ilm.attribute20
            ,ilm.attribute21
            ,ilm.attribute22
            ,ilm.attribute23
            ,ilm.attribute24
            ,ilm.attribute25
            ,ilm.attribute26
            ,ilm.attribute27
            ,ilm.attribute28
            ,ilm.attribute29
            ,ilm.attribute30
            ,ilm.attribute_category
            ,ilm.odm_lot_number
      INTO   ir_lot_rec.item_id
            ,ir_lot_rec.lot_id
            ,ir_lot_rec.lot_no
            ,ir_lot_rec.sublot_no
            ,ir_lot_rec.lot_desc
            ,ir_lot_rec.qc_grade
            ,ir_lot_rec.expaction_code
            ,ir_lot_rec.expaction_date
            ,ir_lot_rec.lot_created
            ,ir_lot_rec.expire_date
            ,ir_lot_rec.retest_date
            ,ir_lot_rec.strength
            ,ir_lot_rec.inactive_ind
            ,ir_lot_rec.origination_type
            ,ir_lot_rec.shipvend_id
            ,ir_lot_rec.vendor_lot_no
            ,ir_lot_rec.creation_date
            ,ir_lot_rec.last_update_date
            ,ir_lot_rec.created_by
            ,ir_lot_rec.last_updated_by
            ,ir_lot_rec.trans_cnt
            ,ir_lot_rec.delete_mark
            ,ir_lot_rec.text_code
            ,ir_lot_rec.last_update_login
            ,ir_lot_rec.program_application_id
            ,ir_lot_rec.program_id
            ,ir_lot_rec.program_update_date
            ,ir_lot_rec.request_id
            ,ir_lot_rec.attribute1
            ,ir_lot_rec.attribute2
            ,ir_lot_rec.attribute3
            ,ir_lot_rec.attribute4
            ,ir_lot_rec.attribute5
            ,ir_lot_rec.attribute6
            ,ir_lot_rec.attribute7
            ,ir_lot_rec.attribute8
            ,ir_lot_rec.attribute9
            ,ir_lot_rec.attribute10
            ,ir_lot_rec.attribute11
            ,ir_lot_rec.attribute12
            ,ir_lot_rec.attribute13
            ,ir_lot_rec.attribute14
            ,ir_lot_rec.attribute15
            ,ir_lot_rec.attribute16
            ,ir_lot_rec.attribute17
            ,ir_lot_rec.attribute18
            ,ir_lot_rec.attribute19
            ,ir_lot_rec.attribute20
            ,ir_lot_rec.attribute21
            ,ir_lot_rec.attribute22
            ,ir_lot_rec.attribute23
            ,ir_lot_rec.attribute24
            ,ir_lot_rec.attribute25
            ,ir_lot_rec.attribute26
            ,ir_lot_rec.attribute27
            ,ir_lot_rec.attribute28
            ,ir_lot_rec.attribute29
            ,ir_lot_rec.attribute30
            ,ir_lot_rec.attribute_category
            ,ir_lot_rec.odm_lot_number
      FROM   ic_lots_mst ilm
      WHERE  ilm.lot_id        = ir_mst_rec.lot_id
      AND    ilm.item_id       = ir_mst_rec.item_idv
      AND    ROWNUM            = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_12);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    BEGIN
      SELECT ilc.item_id
            ,ilc.lot_id
            ,ilc.ic_matr_date
            ,ilc.ic_hold_date
            ,ilc.created_by
            ,ilc.creation_date
            ,ilc.last_update_date
            ,ilc.last_updated_by
            ,ilc.last_update_login
      INTO   ir_lot_cpg_rec.item_id
            ,ir_lot_cpg_rec.lot_id
            ,ir_lot_cpg_rec.ic_matr_date
            ,ir_lot_cpg_rec.ic_hold_date
            ,ir_lot_cpg_rec.created_by
            ,ir_lot_cpg_rec.creation_date
            ,ir_lot_cpg_rec.last_update_date
            ,ir_lot_cpg_rec.last_updated_by
            ,ir_lot_cpg_rec.last_update_login
      FROM   ic_lots_cpg ilc
      WHERE  ilc.lot_id  = ir_lot_rec.lot_id
      AND    ilc.item_id = ir_lot_rec.item_id
      AND    ROWNUM      = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_12);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
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
  END get_lot_mst;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 前処理(F-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'init_proc';       -- プログラム名
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
    lb_retcd  BOOLEAN;
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
    -- 受入実績インターフェース(アドオン)のロック
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_app_name, gv_tbl_name);
--
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_02);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 相手先在庫出庫事由
    gv_inv_ship_rsn := FND_PROFILE.VALUE('XXPO_CTPTY_INV_SHIP_RSN');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_inv_ship_rsn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_09);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
--
    gv_user_name              := FND_GLOBAL.USER_NAME;         -- ユーザ名
--
    gv_close_date             := xxcmn_common_pkg.get_opminv_close_period;  -- CLOSE年月日
--
    -- GMI系API呼出のセットアップ
    lb_retcd  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    IF NOT (lb_retcd) THEN
      RAISE global_api_expt;
    END IF;
--
    -- グループID取得
    SELECT rcv_interface_groups_s.NEXTVAL
    INTO   gn_group_id
    FROM   DUAL;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : other_data_get
   * Description      : 処理対象外受入実績情報取得(F-2)
   ***********************************************************************************/
  PROCEDURE other_data_get(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'other_data_get';       -- プログラム名
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
    oth_rec           other_rec;
    ln_cnt            NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR other_data_cur
    IS
      SELECT  xrti.source_document_number
             ,xrti.source_document_line_num
             ,xrti.item_code
             ,xrti.rcv_date
             ,xrti.txns_id
      FROM    xxpo_rcv_txns_interface xrti
      WHERE  TO_CHAR(xrti.rcv_date,'YYYYMM') <= gv_close_date;
--
    -- *** ローカル・レコード ***
    lr_other_data_rec other_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_cnt := 0;
--
    OPEN other_data_cur;
--
    <<other_data_loop>>
    LOOP
      FETCH other_data_cur INTO lr_other_data_rec;
      EXIT WHEN other_data_cur%NOTFOUND;
--
      oth_rec.src_doc_num      := lr_other_data_rec.source_document_number;
      oth_rec.src_doc_line_num := lr_other_data_rec.source_document_line_num;
      oth_rec.item_code        := lr_other_data_rec.item_code;
      oth_rec.rcv_date         := lr_other_data_rec.rcv_date;
      oth_rec.txns_id          := lr_other_data_rec.txns_id;
--
      gt_other_tbl(ln_cnt)     := oth_rec;
--
      ln_cnt := ln_cnt + 1;
--
      gt_org_txns_id(gn_org_txns_cnt) := oth_rec.txns_id;
      gn_org_txns_cnt := gn_org_txns_cnt + 1;
--
    END LOOP other_data_loop;
--
    CLOSE other_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (other_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE other_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (other_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE other_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (other_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE other_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END other_data_get;
--
  /**********************************************************************************
   * Procedure Name   : disp_other_data
   * Description      : 受入対象外情報出力(F-3)
   ***********************************************************************************/
  PROCEDURE disp_other_data(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'disp_other_data';       -- プログラム名
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
    oth_rec           other_rec;
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
    <<other_disp_loop>>
    FOR i IN 0..gt_other_tbl.COUNT-1 LOOP
      oth_rec := gt_other_tbl(i);
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_08,
                                            gv_tkn_h_no,
                                            oth_rec.src_doc_num,
                                            gv_tkn_m_no,
                                            oth_rec.src_doc_line_num,
                                            gv_tkn_date,
                                            TO_CHAR(oth_rec.rcv_date,'YYYY/MM/DD'),
                                            gv_tkn_item_no,
                                            oth_rec.item_code
                                            );
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END LOOP other_disp_loop;
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
  END disp_other_data;
--
  /**********************************************************************************
   * Procedure Name   : master_data_get
   * Description      : 処理対象の受入情報取得(F-4)
   ***********************************************************************************/
  PROCEDURE master_data_get(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'master_data_get';       -- プログラム名
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
    ln_po_header_id   po_headers_all.po_header_id%TYPE;
    ln_po_line_id     po_lines_all.po_line_id%TYPE;
    ln_lot_id         ic_lots_mst.lot_id%TYPE;
--
    mst_rec           masters_rec;
    ln_cnt            NUMBER;
    ln_num            NUMBER;
    ln_qty            NUMBER;
--
    lv_tbl_name       VARCHAR2(100);
--
    -- *** ローカル・カーソル ***
    CURSOR mst_data_cur
    IS
      SELECT xrti.txns_id                  -- 取引ID
            ,xrti.source_document_number   -- 元文書番号
            ,xrti.vendor_code              -- 取引先コード
            ,xrti.vendor_name              -- 取引先名
            ,xrti.promised_date            -- 納入日
            ,xrti.location_code            -- 納入先コード
            ,xrti.location_name            -- 納入先名
            ,xrti.source_document_line_num -- 元文書明細番号
            ,xrti.item_code                -- 品目コード
            ,xrti.item_name                -- 品目名称
            ,xrti.lot_number               -- ロットNo
            ,xrti.producted_date           -- 製造日
            ,xrti.koyu_code                -- 固有記号
            ,xrti.quantity                 -- 指示数量
            ,xrti.po_line_description      -- 明細摘要
            ,xrti.rcv_date                 -- 受入日
            ,xrti.rcv_quantity             -- 受入数量
            ,xrti.rcv_quantity_uom         -- 単位コード
            ,xrti.rcv_line_description     -- 受入明細摘要
            ,xxpo.po_header_id             -- 発注ヘッダID
            ,xxpo.h_segment1               -- 発注番号
            ,xxpo.h_attribute11            -- 発注区分
            ,xxpo.vendor_id                -- 取引先ID
            ,xxpo.h_attribute5             -- 納入先コード
            ,xxpo.h_attribute6             -- 直送区分
            ,xxpo.h_attribute10            -- 部署コード
            ,xxpo.po_line_id               -- 発注明細ID
            ,xxpo.line_num                 -- 明細番号
            ,xxpo.item_id                  -- 品目ID
            ,xxpo.unit_price               -- 単価
            ,xxpo.l_attribute1             -- ロットNo
            ,xxpo.unit_meas_lookup_code    -- 単位
            ,xxpo.l_attribute10            -- 発注単位
            ,xivv.lot_id                   -- ロットID
            ,xivv.attribute4               -- 納入日(初回)
            ,xivv.attribute5               -- 納入日(最終)
            ,xivv.opm_item_id              -- OPM品目ID
            ,xivv.num_of_cases             -- ケース入数
            ,xivv.lot_ctl                  -- ロット
            ,xivv.item_no                  -- 品目コード
            ,xivv.item_idv                 -- 品目ID
            ,xsv.vendor_stock_whse         -- 相手先在庫入庫先
            ,xicv.prod_class_code          -- 商品区分
-- 2008/12/30 v1.8 T.Yoshimoto Add Start
            ,xicv.item_class_code          -- 品目区分
-- 2008/12/30 v1.8 T.Yoshimoto Add End
            ,xvv.segment1                  -- 仕入先番号
--2008/08/06 Add ↓
            ,xivv.conv_unit                -- 入出庫換算単位
--2008/08/06 Add ↑
--2008/09/25 Add ↓
            ,xxpo.l_cancel_flag            -- 取消フラグ
--2008/09/25 Add ↑
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
            ,xxpo.line_location_id         -- 納入明細ID
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
-- 2010/04/21 v1.16 H.Itou Add Start E_本稼動_02210
            ,TO_DATE(xxpo.h_attribute4,'YYYY/MM/DD')    schedule_delivery_date   -- 納入日
-- 2010/04/21 v1.16 H.Itou Add End
      FROM   xxpo_rcv_txns_interface xrti                 -- 受入実績IF(アドオン)
            ,xxcmn_vendors_v xvv                          -- 仕入先情報VIEW
            ,xxcmn_vendor_sites_v xsv                     -- 仕入先サイト情報VIEW
            ,xxcmn_item_categories3_v xicv                -- OPM品目カテゴリ割当情報VIEW3
            ,(SELECT pha.segment1 as h_segment1        -- 発注番号
                    ,pha.po_header_id                  -- 発注ヘッダID
                    ,pha.vendor_id                     -- 仕入先ID
                    ,pha.attribute1  as h_attribute1   -- ステータス
                    ,pha.attribute4  as h_attribute4   -- 納入日
                    ,pha.attribute5  as h_attribute5   -- 納入先コード
                    ,pha.attribute6  as h_attribute6   -- 直送区分
                    ,pha.attribute10 as h_attribute10  -- 部署コード
                    ,pha.attribute11 as h_attribute11  -- 発注区分
                    ,pla.po_line_id                    -- 発注明細ID
                    ,pla.line_num                      -- 明細番号
                    ,pla.item_id                       -- 品目ID
                    ,pla.unit_price                    -- 単価
                    ,pla.quantity                      -- 数量
                    ,pla.unit_meas_lookup_code         -- 単位
                    ,pla.attribute1  as l_attribute1   -- ロットNO
                    ,pla.attribute2  as l_attribute2   -- 工場コード
                    ,pla.attribute4  as l_attribute4   -- 在庫入数
                    ,pla.attribute7  as l_attribute7   -- 受入数量
                    ,pla.attribute10 as l_attribute10  -- 発注単位
                    ,pla.attribute11 as l_attribute11  -- 発注数量
--2008/09/25 Add ↓
                    ,pla.cancel_flag as l_cancel_flag  -- 取消フラグ
--2008/09/25 Add ↑
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
                    ,plla.line_location_id             -- 納入明細ID
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
             FROM    po_headers_all pha                   -- 発注ヘッダ
                    ,po_lines_all pla                     -- 発注明細
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
                    ,po_line_locations_all plla           -- 発注納入明細
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
             WHERE   pha.po_header_id = pla.po_header_id
--2008/09/25 Mod ↓
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
             AND     plla.po_line_id = pla.po_line_id
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
/*
             AND     pha.attribute1 >= gv_add_status_zmi             -- 発注作成済:20
             AND     pha.attribute1 < gv_add_status_qty_zmi) xxpo    -- 金額確定済:35
*/
             AND     ((pha.attribute1 >= gv_add_status_zmi         -- 発注作成済:20
             AND     pha.attribute1 < gv_add_status_qty_zmi)       -- 金額確定済:35
-- 2009/03/30 H.Iida ADD START 本番障害#1346
             AND     pha.org_id        = TO_NUMBER(gv_org_id)
-- 2009/03/30 H.Iida ADD END
              OR     pha.attribute1 = gv_add_status_end)) xxpo     -- 取消済み:99
--2008/09/25 Mod ↑
            ,(SELECT xiv.item_no                       -- 品目コード
                    ,xiv.num_of_cases                  -- ケース入数
                    ,xiv.lot_ctl                       -- ロット
-- 2008/12/30 v1.8 T.Yoshimoto Mod Start 取得ID不正
--2008/09/25 Mod ↓
                    ,xiv.item_id as opm_item_id        -- OPM品目ID
                    --,xiv.inventory_item_id as opm_item_id  -- OPM品目ID     -- 
--2008/09/25 Mod ↑
-- 2008/12/30 v1.8 T.Yoshimoto Mod End 取得ID不正
--2008/08/06 Add ↓
                    ,xiv.conv_unit                     -- 入出庫換算単位
--2008/08/06 Add ↑
                    ,ilm.lot_no                        -- ロットNo
                    ,ilm.lot_id                        -- ロットID
                    ,ilm.item_id as item_idv           -- 品目ID
                    ,ilm.attribute4                    -- 納入日(初回)
                    ,ilm.attribute5                    -- 納入日(最終)
              FROM   xxcmn_item_mst_v xiv                 -- OPM品目情報VIEW
                    ,ic_lots_mst ilm                      -- OPMロットマスタ
              WHERE xiv.item_id = ilm.item_id(+)) xivv
      WHERE  xrti.source_document_number   = xxpo.h_segment1(+)
      AND    xrti.source_document_line_num = xxpo.line_num(+)
      AND    xrti.vendor_code              = xvv.segment1(+)
      AND    xrti.item_code                = xivv.item_no(+)
      AND    xrti.lot_number               = xivv.lot_no(+)
      AND    xivv.opm_item_id              = xicv.item_id(+)
      AND    xxpo.vendor_id                = xsv.vendor_id(+)
      AND    xxpo.l_attribute2             = xsv.vendor_site_code(+)
      AND    TO_CHAR(xrti.rcv_date,'YYYYMM') > gv_close_date
      ORDER BY xrti.source_document_number,xrti.source_document_line_num;
--
    -- *** ローカル・レコード ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_cnt := 0;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      -- 順番の取得
      SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL
      INTO   ln_num
      FROM   DUAL;
--
      mst_rec.txns_id            := ln_num;
      mst_rec.src_doc_num        := lr_mst_data_rec.source_document_number;
      mst_rec.vendor_code        := lr_mst_data_rec.vendor_code;
      mst_rec.vendor_name        := lr_mst_data_rec.vendor_name;
      mst_rec.promised_date      := lr_mst_data_rec.promised_date;
      mst_rec.location_code      := lr_mst_data_rec.location_code;
      mst_rec.location_name      := lr_mst_data_rec.location_name;
      mst_rec.src_doc_line_num   := lr_mst_data_rec.source_document_line_num;
      mst_rec.item_code          := lr_mst_data_rec.item_code;
      mst_rec.item_name          := lr_mst_data_rec.item_name;
      mst_rec.lot_number         := lr_mst_data_rec.lot_number;
      mst_rec.producted_date     := lr_mst_data_rec.producted_date;
      mst_rec.koyu_code          := lr_mst_data_rec.koyu_code;
      mst_rec.quantity           := lr_mst_data_rec.quantity;
      mst_rec.rcv_quantity_uom   := lr_mst_data_rec.rcv_quantity_uom;
      mst_rec.po_description     := lr_mst_data_rec.po_line_description;
      mst_rec.rcv_date           := lr_mst_data_rec.rcv_date;
      mst_rec.rcv_quantity       := lr_mst_data_rec.rcv_quantity;
      mst_rec.rcv_description    := lr_mst_data_rec.rcv_line_description;
      mst_rec.po_header_id       := lr_mst_data_rec.po_header_id;
      mst_rec.segment1           := lr_mst_data_rec.h_segment1;
      mst_rec.attribute6         := lr_mst_data_rec.h_attribute6;
      mst_rec.attribute11        := lr_mst_data_rec.h_attribute11;
      mst_rec.department_code    := lr_mst_data_rec.h_attribute10;
      mst_rec.vendor_id          := lr_mst_data_rec.vendor_id;
      mst_rec.delivery_code      := lr_mst_data_rec.h_attribute5;
      mst_rec.po_line_id         := lr_mst_data_rec.po_line_id;
      mst_rec.line_num           := lr_mst_data_rec.line_num;
      mst_rec.item_id            := lr_mst_data_rec.item_id;
      mst_rec.unit_price         := lr_mst_data_rec.unit_price;
      mst_rec.lot_no             := lr_mst_data_rec.l_attribute1;
      mst_rec.unit_code          := lr_mst_data_rec.unit_meas_lookup_code;
      mst_rec.attribute10        := lr_mst_data_rec.l_attribute10;
      mst_rec.lot_id             := lr_mst_data_rec.lot_id;
      mst_rec.attribute4         := lr_mst_data_rec.attribute4;
      mst_rec.attribute5         := lr_mst_data_rec.attribute5;
      mst_rec.opm_item_id        := lr_mst_data_rec.opm_item_id;
      mst_rec.num_of_cases       := lr_mst_data_rec.num_of_cases;
      mst_rec.lot_ctl            := lr_mst_data_rec.lot_ctl;
      mst_rec.item_no            := lr_mst_data_rec.item_no;
      mst_rec.item_idv           := lr_mst_data_rec.item_idv;
      mst_rec.vendor_stock_whse  := lr_mst_data_rec.vendor_stock_whse;
      mst_rec.prod_class_code    := lr_mst_data_rec.prod_class_code;
-- 2008/12/30 v1.8 T.Yoshimoto Add Start
      mst_rec.item_class_code    := lr_mst_data_rec.item_class_code;
-- 2008/12/30 v1.8 T.Yoshimoto Add End
      mst_rec.vendor_no          := lr_mst_data_rec.segment1;
--
      -- 2008/08/06 Add ↓
      mst_rec.conv_unit          := lr_mst_data_rec.conv_unit;
      -- 2008/08/06 Add ↑
--
      mst_rec.def4_date          := FND_DATE.STRING_TO_DATE(mst_rec.attribute4,'YYYY/MM/DD');
      mst_rec.def5_date          := FND_DATE.STRING_TO_DATE(mst_rec.attribute5,'YYYY/MM/DD');
-- 2009/04/03 v1.15 T.Yoshimoto Add Start 本番#1368
      mst_rec.line_location_id   := lr_mst_data_rec.line_location_id;
-- 2009/04/03 v1.15 T.Yoshimoto Add End 本番#1368
--
--2008/09/25 Add ↓
      -- 取消フラグが取り消し:'Y'
      IF (lr_mst_data_rec.l_cancel_flag = gv_flg_on) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_13,
                                              gv_tkn_h_no,
                                              lr_mst_data_rec.h_segment1,
                                              gv_tkn_m_no,
                                              lr_mst_data_rec.line_num,
                                              gv_tkn_date,
                                              TO_CHAR(lr_mst_data_rec.rcv_date,'YYYY/MM/DD'),
                                              gv_tkn_item_no,
                                              lr_mst_data_rec.item_no);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt := gn_warn_cnt + 1;
-- 2009/01/27 v1.11 ADD START
--
      -- 受入実績インタフェース(アドオン)の元文書番号、元文書明細番号をもとに発注情報を取得できる
      ELSIF (mst_rec.po_header_id IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_05,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_date,
                                              TO_CHAR(mst_rec.rcv_date,'YYYY/MM/DD'),
                                              gv_tkn_item_no,
                                              mst_rec.item_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
      -- 受入実績インタフェース(アドオン)の取引先コードが該当発注の取引先と同一か。
      ELSIF (mst_rec.vendor_code <> NVL(mst_rec.vendor_no,gv_one_space)) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_vendor_code,
                                              gv_tkn_value,
                                              mst_rec.vendor_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
      -- 受入実績インタフェース(アドオン)の納入先コードが該当発注の納入先と同一か。
      ELSIF (mst_rec.location_code <> NVL(mst_rec.delivery_code,gv_one_space)) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_location_code,
                                              gv_tkn_value,
                                              mst_rec.location_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
      -- 受入実績インタフェース(アドオン)のロットNoが該当発注のロットNoと同一か。
      ELSIF (NVL(mst_rec.lot_number,gv_one_space) <> NVL(mst_rec.lot_no,gv_one_space)) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_lot_number,
                                              gv_tkn_value,
                                              mst_rec.lot_number);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
      -- 受入実績インタフェース(アドオン)の品目コードが該当発注の品目と同一か。
      ELSIF (mst_rec.item_code <> NVL(mst_rec.item_no,gv_one_space)) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_item_code,
                                              gv_tkn_value,
                                              mst_rec.item_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
      -- 受入数量 が正数であること。
      ELSIF (mst_rec.rcv_quantity < 0) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_07,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_rcv_num,
                                              TO_CHAR(mst_rec.rcv_quantity));
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
-- 2009/01/27 v1.11 ADD END
-- 2010/04/21 v1.16 H.Itou Add Start E_本稼動_02210
      -- IF.受入日の年月が、発注ヘッダ.納入日の年月と同一か。
      ELSIF (TO_CHAR(mst_rec.rcv_date, 'YYYYMM') <> TO_CHAR(lr_mst_data_rec.schedule_delivery_date, 'YYYYMM')) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_rcv_date,
                                              gv_tkn_value,
                                              TO_CHAR(mst_rec.rcv_date,'YYYY/MM/DD'));
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
--
      -- IF.受入日が、未来の場合、エラー
      ELSIF (mst_rec.rcv_date > TRUNC(SYSDATE)) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_17,
                                              gv_tkn_h_no,
                                              mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_rcv_date,
                                              gv_tkn_value,
                                              TO_CHAR(mst_rec.rcv_date,'YYYY/MM/DD'));
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        gn_warn_cnt     := gn_warn_cnt + 1;
        gn_proper_error := 1;
-- 2010/04/21 v1.16 H.Itou Add End
      ELSE
--2008/09/25 Add ↑
--
        -- 項目の設定
        gt_txns_id(ln_cnt)           := mst_rec.txns_id;
        gt_src_doc_num(ln_cnt)       := mst_rec.src_doc_num;
        gt_vendor_code(ln_cnt)       := mst_rec.vendor_code;
        gt_promised_date(ln_cnt)     := mst_rec.promised_date;
        gt_location_code(ln_cnt)     := mst_rec.location_code;
        gt_src_doc_line_num(ln_cnt)  := mst_rec.src_doc_line_num;
        gt_item_code(ln_cnt)         := mst_rec.item_code;
        gt_lot_number(ln_cnt)        := mst_rec.lot_number;
-- 2008/05/23 v1.3 Changed
--      gt_rcv_quantity_uom(ln_cnt)  := mst_rec.rcv_quantity_uom;
        gt_rcv_quantity_uom(ln_cnt)  := mst_rec.unit_code;
-- 2008/05/23 v1.3 Changed
        gt_po_description(ln_cnt)    := mst_rec.po_description;
        gt_rcv_date(ln_cnt)          := mst_rec.rcv_date;
-- 2009/01/28 v1.12 DELETE START
--        gt_rcv_quantity(ln_cnt)      := mst_rec.rcv_quantity;
-- 2009/01/28 v1.12 DELETE END
        gt_po_header_id(ln_cnt)      := mst_rec.po_header_id;
        gt_attribute6(ln_cnt)        := mst_rec.attribute6;
        gt_vendor_id(ln_cnt)         := mst_rec.vendor_id;
        gt_po_line_id(ln_cnt)        := mst_rec.po_line_id;
        gt_line_num(ln_cnt)          := mst_rec.line_num;
        gt_item_id(ln_cnt)           := mst_rec.item_id;
        gt_unit_price(ln_cnt)        := mst_rec.unit_price;
        gt_lot_no(ln_cnt)            := mst_rec.lot_no;
        gt_unit_code(ln_cnt)         := mst_rec.unit_code;
        gt_attribute10(ln_cnt)       := mst_rec.attribute10;
        gt_lot_id(ln_cnt)            := mst_rec.lot_id;
        gt_department_code(ln_cnt)   := mst_rec.department_code;
-- 2008/05/21 v1.2 Add
        gt_opm_item_id(ln_cnt)       := mst_rec.item_idv;
-- 2008/05/21 v1.2 Add
-- 2009/04/03 v1.5 T.Yoshimoto Add Start 本番#1368
        gt_line_location_id(ln_cnt)  := mst_rec.line_location_id;
-- 2009/04/03 v1.5 T.Yoshimoto Add End 本番#1368
--
        -- 発注ヘッダ保持
        keep_po_head_id(
          mst_rec.po_header_id,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        gt_conversion_factor(ln_cnt) := 1;
        ln_qty := mst_rec.rcv_quantity;
--
/* 2008/08/06 Mod ↓
        -- ドリンク製品(入出庫換算単位あり) の場合
        IF ((mst_rec.prod_class_code = gv_prod_class_code) 
         AND (mst_rec.unit_code <> mst_rec.attribute10)) THEN
          ln_qty := ln_qty * NVL(mst_rec.num_of_cases,1);
          gt_conversion_factor(ln_cnt) := NVL(mst_rec.num_of_cases,1);
--
        END IF;
2008/08/06 Mod ↑ */
--
-- 2009/01/23 v1.10 UPDATE START
/*
        -- ドリンク製品(入出庫換算単位あり) の場合
        IF ((mst_rec.prod_class_code = gv_prod_class_code)
-- 2008/12/30 v1.8 T.Yoshimoto Add Start
         AND (mst_rec.item_class_code = gv_item_class_code)
-- 2008/12/30 v1.8 T.Yoshimoto Add End
         AND (mst_rec.conv_unit IS NOT NULL)) THEN
*/
        -- ドリンク製品(入出庫換算単位あり)または、
        -- リーフ製品(入出庫換算単位あり)の場合
        IF (
             (
               (mst_rec.prod_class_code = gv_prod_class_code)
               OR
               (mst_rec.prod_class_code = gv_prod_class_leaf)
             )
               AND (mst_rec.item_class_code = gv_item_class_code)
                 AND (mst_rec.conv_unit IS NOT NULL)
           ) THEN
-- 2009/01/23 v1.10 UPDATE END
          ln_qty := ln_qty * mst_rec.num_of_cases;
          gt_conversion_factor(ln_cnt) := mst_rec.num_of_cases;
        END IF;
--
        gt_calc_quantity(ln_cnt) := ln_qty;
        gt_rtn_quantity(ln_cnt) := ln_qty;
-- 2009/01/28 v1.12 ADD START
        gt_rcv_quantity(ln_cnt)  := ln_qty;
-- 2009/01/28 v1.12 ADD END
--
        IF (mst_rec.delivery_code IS NOT NULL) THEN
          BEGIN
            SELECT mil.organization_id
                  ,mil.subinventory_code
                  ,mil.inventory_location_id
            INTO   mst_rec.organization_id
                  ,mst_rec.subinventory_code
                  ,mst_rec.inventory_location_id
            FROM  mtl_item_locations mil
            WHERE mil.segment1 = mst_rec.delivery_code;           -- 納入先コード
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              mst_rec.organization_id       := NULL;
              mst_rec.subinventory_code     := NULL;
              mst_rec.inventory_location_id := NULL;
--
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
--
        ELSE
          mst_rec.organization_id       := NULL;
          mst_rec.subinventory_code     := NULL;
          mst_rec.inventory_location_id := NULL;
        END IF;
--
        gt_master_tbl(ln_cnt) := mst_rec;
--
        -- 発注ヘッダのロック
        IF (mst_rec.po_header_id IS NOT NULL) THEN
--
          BEGIN
            SELECT pha.po_header_id
            INTO   ln_po_header_id
            FROM   po_headers_all pha
            WHERE  pha.po_header_id = mst_rec.po_header_id
-- 2009/03/30 H.Iida ADD START 本番障害#1346
            AND    pha.org_id       = TO_NUMBER(gv_org_id)
-- 2009/03/30 H.Iida ADD END
            FOR UPDATE OF pha.po_header_id NOWAIT;
--
          EXCEPTION
            WHEN lock_expt THEN
              lv_tbl_name := gv_tbl_name_po_head;
              RAISE master_data_get_expt;
--
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        -- 発注明細のロック
        IF (mst_rec.po_line_id IS NOT NULL) THEN
--
          BEGIN
            SELECT pla.po_line_id
            INTO   ln_po_line_id
            FROM   po_lines_all pla
            WHERE  pla.po_line_id = mst_rec.po_line_id
-- 2009/03/30 H.Iida ADD START 本番障害#1346
            AND    pla.org_id     = TO_NUMBER(gv_org_id)
-- 2009/03/30 H.Iida ADD END
            FOR UPDATE OF pla.po_line_id NOWAIT;
--
          EXCEPTION
            WHEN lock_expt THEN
              lv_tbl_name := gv_tbl_name_po_line;
              RAISE master_data_get_expt;
--
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        -- OPMロットマスタのロック
        IF ((mst_rec.lot_id IS NOT NULL)
          AND (mst_rec.lot_no IS NOT NULL)
          AND (mst_rec.item_idv IS NOT NULL)) THEN
--
          BEGIN
            SELECT ilm.lot_id
            INTO   ln_lot_id
            FROM   ic_lots_mst ilm
            WHERE  ilm.item_id = mst_rec.item_idv
            AND    ilm.lot_id  = mst_rec.lot_id
            AND    ilm.lot_no  = mst_rec.lot_no
            FOR UPDATE OF ilm.lot_id NOWAIT;
--
          EXCEPTION
            WHEN lock_expt THEN
              lv_tbl_name := gv_tbl_name_lot_mast;
              RAISE master_data_get_expt;
--
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        SELECT rcv_headers_interface_s.NEXTVAL
        INTO   ln_num
        FROM   DUAL;
        gt_head_if_id(ln_cnt) := ln_num;
--
        SELECT rcv_transactions_interface_s.NEXTVAL
        INTO   ln_num
        FROM   DUAL;
        gt_if_tran_id(ln_cnt) := ln_num;
--
        -- ロット管理品
        IF (mst_rec.lot_ctl = gn_lot_ctl_on) THEN
          gt_trans_id(gn_lot_count)  := gt_if_tran_id(ln_cnt);
          gt_trans_qty(gn_lot_count) := ABS(gt_calc_quantity(ln_cnt));
          gt_trans_lot(gn_lot_count) := gt_lot_number(ln_cnt);
          gn_lot_count := gn_lot_count + 1;
        END IF;
--
        gt_organization_id(ln_cnt) := mst_rec.organization_id;
        gt_subinventory(ln_cnt)    := mst_rec.subinventory_code;
        gt_locator_id(ln_cnt)      := mst_rec.inventory_location_id;
--
        ln_cnt := ln_cnt + 1;
--
--2008/09/25 Add ↓
      END IF;
--2008/09/25 Add ↑
--
      gt_org_txns_id(gn_org_txns_cnt) := lr_mst_data_rec.txns_id;
      gn_org_txns_cnt := gn_org_txns_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
    WHEN master_data_get_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_01,
                                            gv_tkn_table,
                                            lv_tbl_name);
--
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||ov_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (mst_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END master_data_get;
--
-- 2009/01/27 v1.11 DELETE START
  /**********************************************************************************
   * Procedure Name   : proper_check
   * Description      : 妥当性チェック(F-5)
   ***********************************************************************************/
/*  PROCEDURE proper_check(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'proper_check';       -- プログラム名
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
    lr_mst_rec        masters_rec;
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
    <<chk_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
      lv_retcode := gv_status_normal;
      lr_mst_rec := gt_master_tbl(i);
--
      -- 受入実績インタフェース(アドオン)の元文書番号、元文書明細番号をもとに発注情報を取得できる
      IF (lr_mst_rec.po_header_id IS NULL) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_05,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_date,
                                              TO_CHAR(lr_mst_rec.rcv_date,'YYYY/MM/DD'),
                                              gv_tkn_item_no,
                                              lr_mst_rec.item_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- 受入実績インタフェース(アドオン)の取引先コードが該当発注の取引先と同一か。
      IF ((lv_retcode = gv_status_normal)
        AND (lr_mst_rec.vendor_code <> NVL(lr_mst_rec.vendor_no,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_vendor_code,
                                              gv_tkn_value,
                                              lr_mst_rec.vendor_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- 受入実績インタフェース(アドオン)の納入先コードが該当発注の納入先と同一か。
      IF ((lv_retcode = gv_status_normal)
        AND (lr_mst_rec.location_code <> NVL(lr_mst_rec.delivery_code,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_location_code,
                                              gv_tkn_value,
                                              lr_mst_rec.location_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- 受入実績インタフェース(アドオン)のロットNoが該当発注のロットNoと同一か。
      IF ((lv_retcode = gv_status_normal)
        AND (NVL(lr_mst_rec.lot_number,gv_one_space) <> NVL(lr_mst_rec.lot_no,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_lot_number,
                                              gv_tkn_value,
                                              lr_mst_rec.lot_number);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- 受入実績インタフェース(アドオン)の品目コードが該当発注の品目と同一か。
      IF ((lv_retcode = gv_status_normal)
        AND (lr_mst_rec.item_code <> NVL(lr_mst_rec.item_no,gv_one_space))) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_06,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_name,
                                              gv_tkn_name_item_code,
                                              gv_tkn_value,
                                              lr_mst_rec.item_code);
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
      -- 受入数量 が正数であること。
      IF ((lv_retcode = gv_status_normal) AND (lr_mst_rec.rcv_quantity < 0)) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_07,
                                              gv_tkn_h_no,
                                              lr_mst_rec.src_doc_num,
                                              gv_tkn_m_no,
                                              lr_mst_rec.src_doc_line_num,
                                              gv_tkn_rcv_num,
                                              TO_CHAR(lr_mst_rec.rcv_quantity));
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        lv_retcode := gv_status_warn;
        ov_retcode := gv_status_warn;
      END IF;
--
    END LOOP chk_loop;
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
  END proper_check;
--
*/
-- 2009/01/27 v1.11 DELETE END
  /**********************************************************************************
   * Procedure Name   : insert_open_if
   * Description      : 受入オープンIFへの受入情報登録(F-6)
   ***********************************************************************************/
  PROCEDURE insert_open_if(
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_open_if';       -- プログラム名
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
    ln_qty         NUMBER;
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
    -- ***   受入ヘッダオープンIF一括登録  ***
    -- ***************************************
    FORALL itp_cnt IN 0 .. gt_master_tbl.COUNT-1
      INSERT INTO rcv_headers_interface
      ( header_interface_id
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
      VALUES
      ( gt_head_if_id(itp_cnt)                      -- header_interface_id
       ,gn_group_id                                 -- group_id
       ,'PENDING'                                   -- processing_status_code
       ,'VENDOR'                                    -- receipt_source_code
       ,'NEW'                                       -- transaction_type
       ,gd_last_update_date                         -- last_update_date
       ,gn_last_update_by                           -- last_updated_by
       ,gn_last_update_login                        -- last_update_login
       ,gd_creation_date                            -- creation_date
       ,gn_created_by                               -- created_by
       ,gt_vendor_id(itp_cnt)                       -- vendor_id
       ,gt_promised_date(itp_cnt)                   -- expected_receipt_date
       ,'Y'                                         -- validation_flag
      );
--
    -- *************************************************
    -- ***   受入トランザクションオープンIF一括登録  ***
    -- *************************************************
    FORALL itp_cnt IN 0 .. gt_master_tbl.COUNT-1
      INSERT INTO rcv_transactions_interface
      ( interface_transaction_id
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
      VALUES
      ( gt_if_tran_id(itp_cnt)                      -- interface_transaction_id
       ,gn_group_id                                 -- group_id
       ,gd_last_update_date                         -- last_update_date
       ,gn_last_update_by                           -- last_updated_by
       ,gd_creation_date                            -- creation_date
       ,gn_created_by                               -- created_by
       ,gn_last_update_login                        -- last_update_login
       ,'RECEIVE'                                   -- transaction_type
       ,gt_rcv_date(itp_cnt)                        -- transaction_date
       ,'PENDING'                                   -- processing_status_code
       ,'BATCH'                                     -- processing_mode_code
       ,'PENDING'                                   -- transaction_status_code
       ,gt_calc_quantity(itp_cnt)                   -- quantity
       ,gt_rcv_quantity_uom(itp_cnt)                -- unit_of_measure
       ,gt_item_id(itp_cnt)                         -- item_id
       ,'DELIVER'                                   -- auto_transact_code
       ,'VENDOR'                                    -- receipt_source_code
       ,gt_organization_id(itp_cnt)                 -- to_organization_id
       ,'PO'                                        -- source_document_code
       ,gt_po_header_id(itp_cnt)                    -- po_header_id
       ,gt_po_line_id(itp_cnt)                      -- po_line_id
-- 2009/04/03 v1.15 T.Yoshimoto Mod Start 本番#1368
--       ,gt_po_line_id(itp_cnt)                      -- po_line_location_id
       ,gt_line_location_id(itp_cnt)                -- po_line_location_id
-- 2009/04/03 v1.15 T.Yoshimoto Mod End 本番#1368
       ,'INVENTORY'                                 -- destination_type_code
       ,gt_subinventory(itp_cnt)                    -- subinventory
       ,gt_locator_id(itp_cnt)                      -- locator_id
       ,gt_promised_date(itp_cnt)                   -- expected_receipt_date
       ,gt_txns_id(itp_cnt)                         -- ship_line_attribute1
       ,gt_head_if_id(itp_cnt)                      -- header_interface_id
       ,'Y'                                         -- validation_flag
      );
--
    -- ***************************************
    -- ***   受入ヘッダオープンIF一括登録  ***
    -- ***************************************
    FORALL itp_cnt IN 0 .. gn_lot_count-1
      INSERT INTO mtl_transaction_lots_interface
      ( transaction_interface_id
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
      VALUES
      ( mtl_material_transactions_s.NEXTVAL         -- transaction_interface_id
       ,gd_last_update_date                         -- last_update_date
       ,gn_last_update_by                           -- last_updated_by
       ,gd_creation_date                            -- creation_date
       ,gn_created_by                               -- created_by
       ,gn_last_update_login                        -- last_update_login
       ,gt_trans_lot(itp_cnt)                       -- lot_number
       ,gt_trans_qty(itp_cnt)                       -- transaction_quantity
       ,gt_trans_qty(itp_cnt)                       -- primary_quantity
       ,'RCV'                                       -- product_code
       ,gt_trans_id(itp_cnt)                        -- product_transaction_id
      );
--
    gn_proc_flg := 1;
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
  END insert_open_if;
--
  /**********************************************************************************
   * Procedure Name   : insert_rcv_and_rtn
   * Description      : 受入返品実績(アドオン)への受入情報登録(F-7)
   ***********************************************************************************/
  PROCEDURE insert_rcv_and_rtn(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_rcv_and_rtn';       -- プログラム名
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
    ln_count      NUMBER;
    lv_doc_num    xxpo_rcv_and_rtn_txns.source_document_number%TYPE;
    ln_line_num   xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE;
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
-- 2008/06/26 v1.4 Add
    <<number_get_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
      IF ((i = 0)
       OR (lv_doc_num <> gt_src_doc_num(i))
       OR (ln_line_num <> gt_src_doc_line_num(i))) THEN
--
        lv_doc_num  := gt_src_doc_num(i);
        ln_line_num := gt_src_doc_line_num(i);
--
        -- 件数取得
        SELECT COUNT(xrrt.txns_id)
        INTO   ln_count
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.source_document_number   = lv_doc_num
        AND    xrrt.source_document_line_num = ln_line_num
        AND    ROWNUM = 1;
      END IF;
--
      ln_count := ln_count + 1;
      gt_rtn_line_num(i) := ln_count;
    END LOOP number_get_loop;
-- 2008/06/26 v1.4 Add
--
    -- ***************************************
    -- ***  受入返品実績(アドオン)一括登録 ***
    -- ***************************************
    FORALL itp_cnt IN 0 .. gt_master_tbl.COUNT-1
      INSERT INTO xxpo_rcv_and_rtn_txns
        ( txns_id
         ,rcv_rtn_number
         ,rcv_rtn_line_number
         ,txns_type
         ,source_document_number
         ,source_document_line_num
         ,drop_ship_type
         ,vendor_id
         ,vendor_code
         ,location_code
         ,txns_date
         ,item_id
         ,item_code
         ,lot_id
         ,lot_number
         ,quantity
         ,uom
         ,rcv_rtn_quantity
         ,rcv_rtn_uom
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
      VALUES
      (   gt_txns_id(itp_cnt)               -- txns_id
         ,gt_src_doc_num(itp_cnt)           -- rcv_rtn_number
-- 2008/06/26 v1.4 Add
--         ,gt_src_doc_line_num(itp_cnt)      -- rcv_rtn_line_number
         ,gt_rtn_line_num(itp_cnt)          -- rcv_rtn_line_number
-- 2008/06/26 v1.4 Add
         ,gv_txns_type_po                   -- txns_type
         ,gt_src_doc_num(itp_cnt)           -- source_document_number
         ,gt_src_doc_line_num(itp_cnt)      -- source_document_line_num
         ,gt_attribute6(itp_cnt)            -- drop_ship_type
         ,gt_vendor_id(itp_cnt)             -- vendor_id
         ,gt_vendor_code(itp_cnt)           -- vendor_code
         ,gt_location_code(itp_cnt)         -- location_code
         ,gt_rcv_date(itp_cnt)              -- txns_date
-- 2008/05/21 v1.2 Add
--         ,gt_item_id(itp_cnt)               -- item_id
         ,gt_opm_item_id(itp_cnt)            -- opm_item_id
-- 2008/05/21 v1.2 Add
         ,gt_item_code(itp_cnt)             -- item_code
         ,gt_lot_id(itp_cnt)                -- lot_id
         ,gt_lot_no(itp_cnt)                -- lot_number
         ,gt_rtn_quantity(itp_cnt)          -- quantity
         ,gt_unit_code(itp_cnt)             -- uom
         ,gt_rcv_quantity(itp_cnt)          -- rcv_rtn_quantity
         ,gt_attribute10(itp_cnt)           -- rcv_rtn_uom
         ,gt_conversion_factor(itp_cnt)     -- conversion_factor
         ,gt_unit_price(itp_cnt)            -- unit_price
         ,gt_department_code(itp_cnt)       -- department_code
         ,gn_created_by                     -- created_by
         ,gd_creation_date                  -- creation_date
         ,gn_last_update_by                 -- last_updated_by
         ,gd_last_update_date               -- last_update_date
         ,gn_last_update_login              -- last_update_login
         ,gn_request_id                     -- request_id
         ,gn_program_application_id         -- program_application_id
         ,gn_program_id                     -- program_id
         ,gd_program_update_date            -- program_update_date
      );
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
  END insert_rcv_and_rtn;
--
  /**********************************************************************************
   * Procedure Name   : upd_po_lines
   * Description      : 発注明細更新(F-8)
   ***********************************************************************************/
  PROCEDURE upd_po_lines(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'upd_po_lines';       -- プログラム名
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
    -- ***************************************
    -- ***         発注明細一括更新        ***
    -- ***************************************
    FORALL item_cnt IN 0 .. gt_master_tbl.COUNT-1
      UPDATE po_lines_all
-- 2008/06/26 v1.4 Add
--      SET  attribute7             = TO_CHAR(gt_rcv_quantity(item_cnt))
-- 2008/06/26 v1.4 Add
      SET  attribute7         = TO_CHAR(TO_NUMBER(NVL(attribute7,'0'))+gt_rcv_quantity(item_cnt))
          ,attribute13            = gv_flg_on
          ,last_updated_by        = gn_last_update_by
          ,last_update_date       = gd_last_update_date
          ,last_update_login      = gn_last_update_login
          ,request_id             = gn_request_id
          ,program_application_id = gn_program_application_id
          ,program_id             = gn_program_id
          ,program_update_date    = gd_program_update_date
      WHERE po_line_id = gt_po_line_id(item_cnt);
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
  END upd_po_lines;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_mst
   * Description      : ロット更新(F-9)
   ***********************************************************************************/
  PROCEDURE upd_lot_mst(
    ir_mst_rec      IN OUT NOCOPY masters_rec,      -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'upd_lot_mst';       -- プログラム名
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
    ln_flg            NUMBER;
    lv_return_status  VARCHAR2(1);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lr_lot_rec        ic_lots_mst%ROWTYPE;
    lr_lot_cpg_rec    ic_lots_cpg%ROWTYPE;
    ld_def4_date      DATE;                   -- 納入日(初回)
    ld_def5_date      DATE;                   -- 納入日(最終)
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
    ln_flg := 0;
--
    -- OPMロットマスタの取得
    get_lot_mst(
      ir_mst_rec,
      lr_lot_rec,
      lr_lot_cpg_rec,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    ld_def4_date := FND_DATE.STRING_TO_DATE(lr_lot_rec.attribute4,'YYYY/MM/DD');
    ld_def5_date := FND_DATE.STRING_TO_DATE(lr_lot_rec.attribute5,'YYYY/MM/DD');
--
    -- 納入日(初回)がNULL または 納入日(初回) > 受入日
    IF ((lr_lot_rec.attribute4 IS NULL) OR (ld_def4_date > ir_mst_rec.rcv_date)) THEN
      lr_lot_rec.attribute4 := TO_CHAR(ir_mst_rec.rcv_date,'YYYY/MM/DD');
      ln_flg := 1;
    END IF;
--
    -- 納入日(最終)がNULL または 納入日(最終) < 受入日
    IF ((lr_lot_rec.attribute5 IS NULL) OR (ld_def5_date < ir_mst_rec.rcv_date)) THEN
      lr_lot_rec.attribute5 := TO_CHAR(ir_mst_rec.rcv_date,'YYYY/MM/DD');
      ln_flg := 1;
    END IF;
--
    -- 更新あり
    IF (ln_flg = 1) THEN
--
      -- WHOカラム設定
      lr_lot_rec.last_update_date       := gd_last_update_date;
      lr_lot_rec.last_updated_by        := gn_last_update_by;
      lr_lot_rec.last_update_login      := gn_last_update_login;
      lr_lot_rec.program_application_id := gn_program_application_id;
      lr_lot_rec.program_id             := gn_program_id;
      lr_lot_rec.program_update_date    := gd_program_update_date;
      lr_lot_rec.request_id             := gn_request_id;
--
      lr_lot_cpg_rec.last_update_date   := gd_last_update_date;
      lr_lot_cpg_rec.last_updated_by    := gn_last_update_by;
      lr_lot_cpg_rec.last_update_login  := gn_last_update_login;
--
      -- ロットマスタの更新
      GMI_LOTUPDATE_PUB.UPDATE_LOT(
         P_API_VERSION      => 1.0
        ,P_INIT_MSG_LIST    => FND_API.G_FALSE
        ,P_COMMIT           => FND_API.G_FALSE
        ,P_VALIDATION_LEVEL => FND_API.G_VALID_LEVEL_FULL
        ,X_RETURN_STATUS    => lv_return_status
        ,X_MSG_COUNT        => ln_msg_count
        ,X_MSG_DATA         => lv_msg_data
        ,P_LOT_REC          => lr_lot_rec
        ,P_LOT_CPG_REC      => lr_lot_cpg_rec
        );
--
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              'APP-XXCMN-10018',
                                              gv_tkn_api_name,
                                              'GMI_LOTUPDATE_PUB.UPDATE_LOT');
--
        FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                         P_ENCODED       => FND_API.G_FALSE,
                         P_DATA          => lv_msg_data,
                         P_MSG_INDEX_OUT => ln_msg_count );
--
        lv_errbuf := lv_msg_data;
        RAISE global_api_expt;
      END IF;
    END IF;
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
  END upd_lot_mst;
--
  /**********************************************************************************
   * Procedure Name   : insert_tran
   * Description      : 在庫取引に出庫情報登録(F-10)
   ***********************************************************************************/
  PROCEDURE insert_tran(
    ir_mst_rec      IN OUT NOCOPY masters_rec,      -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'insert_tran';       -- プログラム名
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
    ln_num              NUMBER;
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
--
    lr_qty_rec          GMIGAPI.qty_rec_typ;
    lr_ic_jrnl_mst_row  ic_jrnl_mst%ROWTYPE;
    lr_ic_adjs_jnl_row1 ic_adjs_jnl%ROWTYPE;
    lr_ic_adjs_jnl_row2 ic_adjs_jnl%ROWTYPE;
--
    ln_qty              NUMBER;
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
    -- 倉庫、会社、組織の取得
    get_location(
      ir_mst_rec,
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    lr_qty_rec.trans_type     := 2;                              -- 取引タイプ(2:調整即時)
    lr_qty_rec.reason_code    := gv_inv_ship_rsn;                -- 事由コード
    lr_qty_rec.trans_date     := ir_mst_rec.promised_date;       -- 取引日
    lr_qty_rec.from_location  := ir_mst_rec.vendor_stock_whse;   -- 出庫元
    lr_qty_rec.item_no        := ir_mst_rec.item_code;           -- 品目NO
    lr_qty_rec.lot_no         := ir_mst_rec.lot_no;              -- ロットNO
    lr_qty_rec.item_um        := ir_mst_rec.unit_code;           -- 単位
    lr_qty_rec.user_name      := gv_user_name;                   -- ユーザ名
--
    lr_qty_rec.from_whse_code := ir_mst_rec.from_whse_code;      -- 倉庫
    lr_qty_rec.co_code        := ir_mst_rec.co_code;             -- 会社
    lr_qty_rec.orgn_code      := ir_mst_rec.orgn_code;           -- 組織
-- 2008/12/30 v1.9 T.Yoshimoto Add Start
    lr_qty_rec.attribute1     := ir_mst_rec.txns_id;             -- 取引ID
-- 2008/12/30 v1.9 T.Yoshimoto Add End
--
    ln_qty := ir_mst_rec.rcv_quantity;
--
-- 2009/01/23 v1.10 UPDATE START
/*
    -- ドリンク製品(入出庫換算単位あり) の場合
    IF ((ir_mst_rec.prod_class_code = gv_prod_class_code)
-- 2008/12/30 v1.8 T.Yoshimoto Add Start
     AND (ir_mst_rec.item_class_code = gv_item_class_code)
-- 2008/12/30 v1.8 T.Yoshimoto Add End
     AND (ir_mst_rec.conv_unit IS NOT NULL)) THEN
*/
    -- ドリンク製品(入出庫換算単位あり)または、
    -- リーフ製品(入出庫換算単位あり)の場合
    IF (
         (
           (ir_mst_rec.prod_class_code = gv_prod_class_code)
           OR
           (ir_mst_rec.prod_class_code = gv_prod_class_leaf)
         )
           AND (ir_mst_rec.item_class_code = gv_item_class_code)
             AND (ir_mst_rec.conv_unit IS NOT NULL)
       ) THEN
-- 2009/01/23 v1.10 UPDATE END
      ln_qty := ln_qty * ir_mst_rec.num_of_cases;
    END IF;
--
/* 2008/08/06 Mod ↓
    -- ドリンク製品(入出庫換算単位あり) の場合
    IF ((ir_mst_rec.prod_class_code = gv_prod_class_code)
     AND (ir_mst_rec.unit_code <> ir_mst_rec.attribute10)) THEN
      ln_qty := ln_qty * NVL(ir_mst_rec.num_of_cases,1);
    END IF;
2008/08/06 Mod ↑ */
--
    lr_qty_rec.trans_qty := ln_qty * (-1);
--
    -- 在庫トランザクションの作成
    GMIPAPI.Inventory_Posting(
       P_API_VERSION       => 3.0
      ,P_INIT_MSG_LIST     => FND_API.G_FALSE
      ,P_COMMIT            => FND_API.G_FALSE
      ,P_VALIDATION_LEVEL  => FND_API.G_VALID_LEVEL_FULL
      ,P_QTY_REC           => lr_qty_rec
      ,X_IC_JRNL_MST_ROW   => lr_ic_jrnl_mst_row
      ,X_IC_ADJS_JNL_ROW1  => lr_ic_adjs_jnl_row1
      ,X_IC_ADJS_JNL_ROW2  => lr_ic_adjs_jnl_row2
      ,X_RETURN_STATUS     => lv_return_status
      ,X_MSG_COUNT         => ln_msg_count
      ,X_MSG_DATA          => lv_msg_data
      );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            'APP-XXCMN-10018',
                                            gv_tkn_api_name,
                                            'GMIPAPI.INVENTORY_POSTING');
--
      lv_msg_data := lv_errmsg;
--
      xxcmn_common_pkg.put_api_log(
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      lv_errmsg := lv_msg_data;
      lv_errbuf := lv_msg_data;
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
  END insert_tran;
--
  /**********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 処理完了発注情報出力(F-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ir_mst_rec      IN OUT NOCOPY masters_rec,      -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'disp_report';       -- プログラム名
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
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31g_10,
                                          gv_tkn_h_no,
                                          ir_mst_rec.src_doc_num,
                                          gv_tkn_m_no,
                                          ir_mst_rec.src_doc_line_num,
                                          gv_tkn_name_vendor,
                                          ir_mst_rec.vendor_code,
                                          gv_tkn_name_shipment,
                                          ir_mst_rec.location_code);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : upd_status
   * Description      : 発注ステータス更新(F-12)
   ***********************************************************************************/
  PROCEDURE upd_status(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'upd_status';       -- プログラム名
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
    lr_mst_rec          masters_rec;
    lt_po_header_id     reg_po_header_id;
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
    -- 発注ヘッダのステータス：「発注作成済」⇒「受入あり」に更新
    FORALL item_cnt IN 0 .. gn_head_count-1
      UPDATE po_headers_all
      SET    attribute1             = gv_add_status_rcv_on
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  po_header_id = gt_keep_header_id(item_cnt)
      AND    attribute1   = gv_add_status_zmi;
--
    -- 全ての発注明細の数量確定フラグが「Y」となった場合には、
    -- 現在の発注ヘッダのステータスが「数量確定済」未満であれば「数量確定済」に更新
    FORALL item_cnt IN 0 .. gn_head_count-1
      UPDATE po_headers_all pha
      SET    pha.attribute1         = gv_add_status_num_zmi
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE  pha.po_header_id = gt_keep_header_id(item_cnt)
      AND    NOT EXISTS (
        SELECT pla.po_header_id
        FROM   po_lines_all pla
        WHERE  NVL(pla.attribute13,gv_flg_off) <> gv_flg_on
        AND    pla.po_header_id = pha.po_header_id
-- 2009/02/10 v1.13 ADD START
        AND    pla.cancel_flag <> gv_flg_on
-- 2009/02/10 v1.13 ADD END
-- 2009/03/30 H.Iida ADD START 本番障害#1346
        AND    pla.org_id       = TO_NUMBER(gv_org_id)
-- 2009/03/30 H.Iida ADD END
      )
      AND    pha.attribute1 < gv_add_status_num_zmi;
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
  END upd_status;
--
  /**********************************************************************************
   * Procedure Name   : commit_open_if
   * Description      : 受入オープンIFに登録した内容の反映(F-13)
   ***********************************************************************************/
  PROCEDURE commit_open_if(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'commit_open_if';       -- プログラム名
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
    lb_ret         NUMBER;
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
    COMMIT;
--
    -- 受入オープンIF登録あり
    IF (gn_proc_flg = 1) THEN
--
      -- コンカレントの起動
      lb_ret := FND_REQUEST.SUBMIT_REQUEST(
                    application  => gv_appl_name           -- アプリケーション短縮名
                   ,program      => gv_prg_name            -- プログラム名
                   ,argument1    => gv_exec_mode           -- 処理モード
                   ,argument2    => TO_CHAR(gn_group_id)   -- グループID
                  );
--
      -- エラー
      IF (lb_ret = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31g_04);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
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
  END commit_open_if;
--
  /**********************************************************************************
   * Procedure Name   : del_rcv_txns_if
   * Description      : 受入実績インターフェース(アドオン)の削除(F-14)
   ***********************************************************************************/
  PROCEDURE del_rcv_txns_if(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'del_rcv_txns_if';       -- プログラム名
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
    -- ***************************************
    -- ***       受入実績IF一括削除        ***
    -- ***************************************
    FORALL del_cnt IN 0 .. gn_org_txns_cnt-1
      DELETE
      FROM xxpo_rcv_txns_interface
      WHERE txns_id = gt_org_txns_id(del_cnt);
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
  END del_rcv_txns_if;
--
  /**********************************************************************************
   * Procedure Name   : term_proc
   * Description      : 終了処理(F-15)
   ***********************************************************************************/
  PROCEDURE term_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'term_proc';       -- プログラム名
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
-- 2009/01/27 v1.11 DELETE START
/*
    -- 妥当性チェックエラーあり
    IF (gn_proper_error = 1) THEN
--
      COMMIT;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31g_03);
      lv_errbuf := lv_errmsg;
      RAISE term_proc_expt;
    END IF;
*/
-- 2009/01/27 v1.11 DELETE END
--2008/09/25 Mod ↓
/*
--
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31g_11,
                                          gv_tkn_count,
                                          gt_master_tbl.COUNT);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
*/
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                          gv_tkn_number_31g_14,
                                          gv_tkn_cnt,
                                          gt_master_tbl.COUNT+gn_warn_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --成功件数出力
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                          gv_tkn_number_31g_15,
                                          gv_tkn_cnt,
                                          gt_master_tbl.COUNT);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --エラー件数出力
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                          gv_tkn_number_31g_16,
                                          gv_tkn_cnt,
                                          gn_warn_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--2008/09/25 Mod ↑
--
  EXCEPTION
    WHEN term_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := gv_status_error;
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
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    mst_rec           masters_rec;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2009/03/30 H.Iida ADD START 本番障害#1346
    --==========================
    -- ORG_ID取得
    --==========================
    gv_org_id := FND_PROFILE.VALUE(gv_prf_org_id);
-- 2009/03/30 H.Iida ADD END
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_proc_flg   := 0;
--
    gn_proper_error := 0;
    gn_org_txns_cnt := 0;
    gn_lot_count    := 0;
    gn_head_count   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ================================
    -- F-1.前処理
    -- ================================
    init_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- F-2.処理対象外受入実績情報取得
    -- ================================
    other_data_get(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- F-3.受入対象外情報出力
    -- ================================
    IF (gt_other_tbl.COUNT > 0) THEN
      disp_other_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ================================
    -- F-4.処理対象受入情報取得
    -- ================================
    master_data_get(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 件数が１件以上
    IF (gt_master_tbl.COUNT > 0) THEN
--
-- 2009/01/27 v1.11 DELETE START
/*
      -- ================================
      -- F-5.妥当性チェック
      -- ================================
      proper_check(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 妥当性チェックエラーなし
      IF (lv_retcode = gv_status_normal) THEN
--
*/
-- 2009/01/27 v1.11 DELETE END
        -- ================================
        -- F-6.受入オープンIFへの受入情報登録
        -- ================================
        insert_open_if(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ================================
        -- F-7.受入返品実績(アドオン)への受入情報登録
        -- ================================
        insert_rcv_and_rtn(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ================================
        -- F-8.発注明細更新
        -- ================================
        upd_po_lines(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        <<api_loop>>
        FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
          mst_rec := gt_master_tbl(i);
--
          -- ================================
          -- F-9.ロット更新
          -- ================================
          upd_lot_mst(
            mst_rec,
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 受入品目が「相手先在庫」
          IF (mst_rec.attribute11 = gv_po_type_rev) THEN
            -- ================================
            -- F-10.在庫取引に出庫情報登録
            -- ================================
            insert_tran(
              mst_rec,
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ================================
          -- F-11.処理完了発注情報出力
          -- ================================
          disp_report(
            mst_rec,
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP api_loop;
--
        -- ================================
        -- F-12.発注ステータス更新
        -- ================================
        upd_status(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ================================
        -- F-13.受入オープンIFに登録した内容の反映
        -- ================================
        commit_open_if(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
-- 2009/01/27 v1.11 DELETE START
/*
      ELSE
        gn_proper_error := 1;
      END IF;
*/
-- 2009/01/27 v1.11 DELETE END
--
      -- ================================
      -- F-14.受入実績IF(アドオン)の全データ削除
      -- ================================
      del_rcv_txns_if(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- 2008/07/09 Add ↓
    ELSE
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    -- 2008/07/09 Add ↑
    END IF;
--
    -- ================================
    -- F-15.終了処理
    -- ================================
    term_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/01/27 v1.11 ADD START
    -- 妥当性チェックエラーあり
    IF (gn_proper_error = 1) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
-- 2009/01/27 v1.11 ADD END
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT NOCOPY VARCHAR2)      --   リターン・コード    --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字取得
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
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
END xxpo310004c;
/
