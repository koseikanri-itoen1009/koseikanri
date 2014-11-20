create or replace PACKAGE BODY xxpo310001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310001c(body)
 * Description      : 仕入実績作成処理
 * MD.050           : 受入実績            T_MD050_BPO_310
 * MD.070           : 仕入実績作成        T_MD070_BPO_31D
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_location           倉庫、組織、会社の取得
 *  get_lot_mst            OPMロットマスタの取得
 *  init_proc              前処理                                       (D-1)
 *  parameter_check        パラメータチェック                           (D-2)
 *  get_mast_data          発注情報取得                                 (D-3)
 *  insert_opif            受入実績登録処理                             (D-4)
 *  upd_po_lines           発注明細更新                                 (D-5)
 *  upd_lot_mst            ロットマスタ更新                             (D-6)
 *  insert_tran            相手先出庫取引情報登録                       (D-7)
 *  disp_report            処理完了発注情報出力                         (D-8)
 *  upd_po_headrs          発注ステータス更新                           (D-9)
 *  commit_opif            受入オープンIFデータ反映                     (D-10)
 *  disp_count             処理件数出力                                 (D-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/10    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/21    1.1   Oracle 山根 一浩 変更要求No43対応
 *  2008/04/30    1.2   Oracle 山根 一浩 変更要求No69対応
 *  2008/05/14    1.3   Oracle 山根 一浩 変更要求No90対応
 *  2008/05/21    1.4   Oracle 山根 一浩 変更要求No109対応
 *                                       結合テスト不具合ログ#300_3対応
 *  2008/10/27    1.5   Oracle 吉元 強樹 内部変更No216対応
 *  2008/12/04    1.6   Oracle 吉元 強樹 本番障害No420対応
 *  2008/12/06    1.7   Oracle 伊藤 ひとみ 本番障害No528対応
 *  2009/12/02    1.8   SCS    吉元 強樹 本稼動障害#263
 *  2011/06/07    1.9   SCSK   窪 和重   本稼動障害#1786対応
 *  2012/03/06    1.10  SCSK   中村 健一 本稼動障害#9118対応
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
  lock_expt             EXCEPTION;              -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxpo310001c';       -- パッケージ名
  gv_app_name         CONSTANT VARCHAR2(5)   := 'XXPO';              -- アプリケーション短縮名
  gv_com_name         CONSTANT VARCHAR2(5)   := 'XXCMN';             -- アプリケーション短縮名
--
  -- トークン
  gv_tkn_para_name       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  gv_tkn_po_num          CONSTANT VARCHAR2(20) := 'PO_NUM';
  gv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';
  gv_tkn_table_name      CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  gv_tkn_api_name        CONSTANT VARCHAR2(20) := 'API_NAME';
  gv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';
  gv_tkn_m_no            CONSTANT VARCHAR2(20) := 'M_NO';
  gv_tkn_item_no         CONSTANT VARCHAR2(20) := 'ITEM_NO';
  gv_tkn_nonyu_date      CONSTANT VARCHAR2(20) := 'NONYU_DATE';
  gv_tkn_conc_id         CONSTANT VARCHAR2(20) := 'CONC_ID';
  gv_tkn_conc_name       CONSTANT VARCHAR2(20) := 'CONC_NAME';
--
  gv_tkn_number_31d_01   CONSTANT VARCHAR2(15) := 'APP-XXPO-10027'; -- ロック失敗エラー
  gv_tkn_number_31d_02   CONSTANT VARCHAR2(15) := 'APP-XXPO-10056'; -- 受入取引処理起動エラー2
  gv_tkn_number_31d_03   CONSTANT VARCHAR2(15) := 'APP-XXPO-10076'; -- 相手先在庫出庫事由取得エラー
  gv_tkn_number_31d_04   CONSTANT VARCHAR2(15) := 'APP-XXPO-10091'; -- 発注のステータスエラー
  gv_tkn_number_31d_05   CONSTANT VARCHAR2(15) := 'APP-XXPO-10094'; -- 発注番号未入力エラー
  gv_tkn_number_31d_06   CONSTANT VARCHAR2(15) := 'APP-XXPO-10107'; -- 不正な発注番号
  gv_tkn_number_31d_07   CONSTANT VARCHAR2(15) := 'APP-XXPO-30024'; -- 実績作成済発注情報
  gv_tkn_number_31d_08   CONSTANT VARCHAR2(15) := 'APP-XXPO-30027'; -- 処理件数
  gv_tkn_number_31d_09   CONSTANT VARCHAR2(15) := 'APP-XXPO-30039'; -- 入力パラメータ情報5
--
  gv_tbl_name_po_head    CONSTANT VARCHAR2(50) := '発注ヘッダ';
  gv_tbl_name_po_line    CONSTANT VARCHAR2(50) := '発注明細';
  gv_tbl_name_lot_mast   CONSTANT VARCHAR2(50) := 'OPMロットマスタ';
--
  -- 受入取引処理
  gv_appl_name           CONSTANT VARCHAR2(50) := 'PO';
  gv_prg_name            CONSTANT VARCHAR2(50) := 'RVCTP';
--
  gv_add_status_zmi      CONSTANT VARCHAR2(5)  := '20';              -- 発注作成済
  gv_add_status_num_zmi  CONSTANT VARCHAR2(5)  := '30';              -- 数量確定済
  gv_po_type_rev         CONSTANT VARCHAR2(1)  := '3';               -- 相手先在庫
--
  gv_flg_on              CONSTANT VARCHAR2(1)  := 'Y';
  gn_lot_ctl_on          CONSTANT NUMBER       := 1;
--
  gv_prod_class_code     CONSTANT VARCHAR2(1)  := '2';               -- 商品区分:ドリンク
  gv_item_class_code     CONSTANT VARCHAR2(1)  := '5';               -- 品目区分:製品
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- D-3:発注情報取得対象データ
  TYPE masters_rec IS RECORD(
    h_segment1            po_headers_all.segment1%TYPE,                        -- 発注番号
    po_header_id          po_headers_all.po_header_id%TYPE,                    -- 発注ヘッダID
    h_attribute11         po_headers_all.attribute11%TYPE,                     -- 発注区分
    vendor_id             po_headers_all.vendor_id%TYPE,                       -- 仕入先ID
    h_attribute4          po_headers_all.attribute4%TYPE,                      -- 納入日
    h_attribute5          po_headers_all.attribute5%TYPE,                      -- 納入先コード
    h_attribute6          po_headers_all.attribute6%TYPE,                      -- 直送区分
    h_attribute10         po_headers_all.attribute10%TYPE,                     -- 部署コード
    po_line_id            po_lines_all.po_line_id%TYPE,                        -- 発注明細ID
-- 2009/12/02 v1.8 T.Yoshimoto Add Start 本稼動障害#263
    po_line_location_id   po_line_locations_all.line_location_id%TYPE,        -- 発注明細ID
-- 2009/12/02 v1.8 T.Yoshimoto Add End 本稼動障害#263
    line_num              po_lines_all.line_num%TYPE,                          -- 明細番号
    item_id               po_lines_all.item_id%TYPE,                           -- 品目ID
    lot_no                po_lines_all.attribute1%TYPE,                        -- ロットNO
    unit_price            po_lines_all.unit_price%TYPE,                        -- 単価
    quantity              po_lines_all.quantity%TYPE,                          -- 数量
    unit_code             po_lines_all.unit_meas_lookup_code%TYPE,             -- 単位
    l_attribute4          po_lines_all.attribute4%TYPE,                        -- 在庫入数
    l_attribute10         po_lines_all.attribute10%TYPE,                       -- 発注単位
    l_attribute11         po_lines_all.attribute11%TYPE,                       -- 発注数量
    lot_id                ic_lots_mst.lot_id%TYPE,                             -- ロットID
    attribute4            ic_lots_mst.attribute4%TYPE,                         -- 納入日(初回)
    attribute5            ic_lots_mst.attribute5%TYPE,                         -- 納入日(最終)
--
    item_no               xxcmn_item_mst_v.item_no%TYPE,                       -- 品目コード
--
    segment1              xxcmn_vendors_v.segment1%TYPE,                       -- 仕入先番号
    vendor_stock_whse     xxcmn_vendor_sites_v.vendor_stock_whse%TYPE,         -- 相手先在庫入庫先
--
    lot_ctl               xxcmn_item_mst_v.lot_ctl%TYPE,                       -- ロット
    item_idv              xxcmn_item_mst_v.item_id%TYPE,                       -- 品目ID
--
    prod_class_code       xxcmn_item_categories3_v.prod_class_code%TYPE,       -- 商品区分
    item_class_code       xxcmn_item_categories3_v.prod_class_code%TYPE,       -- 品目区分
--
    from_whse_code        ic_tran_cmp.whse_code%TYPE,                          -- 倉庫
    co_code               ic_tran_cmp.co_code%TYPE,                            -- 会社
    orgn_code             ic_tran_cmp.orgn_code%TYPE,                          -- 組織
--
    organization_id       mtl_item_locations.organization_id%TYPE,
    subinventory_code     mtl_item_locations.subinventory_code%TYPE,
    inventory_location_id mtl_item_locations.inventory_location_id%TYPE,
--
    h_def4_date           DATE,                                                -- 納入日
    def4_date             DATE,                                                -- 納入日(初回)
    def5_date             DATE,                                                -- 納入日(最終)
    def11_qty             NUMBER,                                              -- 発注数量
    def5_num              NUMBER,                                              -- 納入先コード
--
    exec_flg              NUMBER                                    -- 処理フラグ
  );
  -- 各マスタへ反映するデータを格納する結合配列
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      登録用項目テーブル型       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;  -- 各マスタへ登録するデータ
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
  -- 元文書番号
  TYPE reg_src_doc_num       IS TABLE OF xxpo_rcv_txns_interface.source_document_number   %TYPE INDEX BY BINARY_INTEGER;
  -- 元文書明細番号
  TYPE reg_src_doc_line_num  IS TABLE OF xxpo_rcv_txns_interface.source_document_line_num %TYPE INDEX BY BINARY_INTEGER;
  -- 受入返品明細番号
  TYPE reg_rtn_line_num      IS TABLE OF xxpo_rcv_and_rtn_txns.rcv_rtn_line_number        %TYPE INDEX BY BINARY_INTEGER;
-- 2008/10/27 v1.5 T.Yoshimoto Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_header_number            VARCHAR2(20);
  gv_inv_ship_rsn             VARCHAR2(100);              -- 相手先在庫出庫事由
  gn_group_id                 NUMBER;                     -- グループID
  gn_proc_flg                 NUMBER;
  gn_txns_id                  xxpo_rcv_and_rtn_txns.txns_id%TYPE;
  gv_defaultlot               VARCHAR2(100);              -- デフォルトロット 2008/04/30 追加
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
--
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
  -- 項目テーブル型定義
  gt_src_doc_num       reg_src_doc_num;       -- 元文書番号
  gt_src_doc_line_num  reg_src_doc_line_num;  -- 元文書明細番号
  gt_rtn_line_num      reg_rtn_line_num;      -- 受入返品明細番号
-- 2008/10/27 v1.5 T.Yoshimoto Add End
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
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
   * Description      : 前処理(D-1)
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
    l_setup_return_sts        BOOLEAN;
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
    -- 相手先在庫出庫事由
    gv_inv_ship_rsn := FND_PROFILE.VALUE('XXPO_CTPTY_INV_SHIP_RSN');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_inv_ship_rsn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name, 
                                            gv_tkn_number_31d_03);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- デフォルトロット 2008/04/30 追加
    gv_defaultlot := FND_PROFILE.VALUE('IC$DEFAULT_LOT');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_defaultlot IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name, 
                                            gv_tkn_number_31d_03);
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
    -- GMI系API呼出のセットアップ
    l_setup_return_sts  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    IF NOT (l_setup_return_sts) THEN
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック(D-2)
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
    ln_cnt        NUMBER;
    lv_status     po_headers_all.attribute1%TYPE;
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
                                            gv_tkn_number_31d_05);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    -- 発注番号入力あり
    ELSE
--
      gv_header_number := iv_po_number;
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31d_09,
                                            gv_tkn_po_num,
                                            iv_po_number);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- 発注ヘッダの存在チェック
    BEGIN
      SELECT pha.attribute1
      INTO   lv_status
      FROM   po_headers_all pha
      WHERE  pha.segment1   = gv_header_number
      AND    ROWNUM         = 1;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31d_06);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ステータスのチェック
    IF (lv_status <> gv_add_status_zmi) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31d_04);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- グループIDの取得
    SELECT rcv_interface_groups_s.NEXTVAL
    INTO   gn_group_id
    FROM   DUAL;
--
-- 2008/05/14 削除
--    gn_group_id := gn_group_id || TO_NUMBER(gv_header_number);
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
  /***********************************************************************************
   * Procedure Name   : get_mast_data
   * Description      : 発注情報取得(D-3)
   ***********************************************************************************/
  PROCEDURE get_mast_data(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mast_data'; -- プログラム名
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
    ln_po_header_id   po_headers_all.po_header_id%TYPE;
    ln_po_line_id     po_lines_all.po_line_id%TYPE;
    ln_lot_id         ic_lots_mst.lot_id%TYPE;
    mst_rec           masters_rec;
    ln_cnt            NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR base_data_cur
    IS
      SELECT xxpo.h_segment1              -- 発注番号
            ,xxpo.po_header_id            -- 発注ヘッダID
            ,xxpo.h_attribute11           -- 発注区分
            ,xxpo.vendor_id               -- 仕入先ID
            ,xxpo.h_attribute4            -- 納入日
            ,xxpo.h_attribute5            -- 納入先コード
            ,xxpo.h_attribute6            -- 直送区分
            ,xxpo.h_attribute10           -- 部署コード
            ,xxpo.po_line_id              -- 発注明細ID
-- 2009/12/02 v1.8 T.Yoshimoto Add Start 本稼動障害#263
            ,xxpo.line_location_id     -- 発注納入明細ID
-- 2009/12/02 v1.8 T.Yoshimoto Add End 本稼動障害#263
            ,xxpo.line_num                -- 明細番号
            ,xxpo.item_id                 -- 品目ID
            ,xxpo.l_attribute1            -- ロットNO
            ,xxpo.unit_price              -- 単価
            ,xxpo.quantity                -- 数量
            ,xxpo.unit_meas_lookup_code   -- 単位
            ,xxpo.l_attribute4            -- 在庫入数
            ,xxpo.l_attribute10           -- 発注単位
            ,xxpo.l_attribute11           -- 発注数量
            ,ilm.lot_id                   -- ロットID
            ,ilm.attribute4               -- 納入日(初回)
            ,ilm.attribute5               -- 納入日(最終)
            ,xiv.item_no                  -- 品目コード
            ,xvv.segment1                 -- 仕入先番号
            ,xsv.vendor_stock_whse        -- 相手先在庫入庫先
            ,xiv.lot_ctl                  -- ロット
            ,xiv.item_id as item_idv      -- OPM品目ID
            ,xcv.prod_class_code          -- 商品区分
            ,xcv.item_class_code          -- 品目区分
      FROM  (SELECT pha.segment1 as h_segment1        -- 発注番号
                   ,pha.po_header_id                  -- 発注ヘッダID
                   ,pha.vendor_id                     -- 仕入先ID
                   ,pha.attribute4  as h_attribute4   -- 納入日
                   ,pha.attribute5  as h_attribute5   -- 納入先コード
                   ,pha.attribute6  as h_attribute6   -- 直送区分
                   ,pha.attribute10 as h_attribute10  -- 部署コード
                   ,pha.attribute11 as h_attribute11  -- 発注区分
                   ,pla.po_line_id                    -- 発注明細ID
-- 2009/12/02 v1.8 T.Yoshimoto Add Start 本稼動障害#263
                   ,plla.line_location_id          -- 発注納入明細ID
-- 2009/12/02 v1.8 T.Yoshimoto Add End 本稼動障害#263
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
-- 2008/12/06 H.Itou Add Start
                   ,pla.cancel_flag as cancel_flag    -- 削除フラグ
-- 2008/12/06 H.Itou Add End
             FROM   po_headers_all pha                -- 発注ヘッダ
                   ,po_lines_all pla                  -- 発注明細
-- 2009/12/02 v1.8 T.Yoshimoto Add Start 本稼動障害#263
                   ,po_line_locations_all plla
-- 2009/12/02 v1.8 T.Yoshimoto Add End 本稼動障害#263
             WHERE  pha.po_header_id  = pla.po_header_id
-- 2009/12/02 v1.8 T.Yoshimoto Add Start 本稼動障害#263
             AND    plla.po_header_id = pha.po_header_id
             AND    plla.po_line_id   = pla.po_line_id
-- 2009/12/02 v1.8 T.Yoshimoto Add End 本稼動障害#263
             ) xxpo
            ,xxcmn_item_mst_v xiv                      -- OPM品目情報VIEW
            ,ic_lots_mst ilm                           -- OPMロットマスタ
            ,xxcmn_vendors_v xvv                       -- 仕入先情報VIEW
            ,xxcmn_vendor_sites_v xsv                  -- 仕入先サイト情報VIEW
            ,xxcmn_item_categories3_v xcv              -- OPM品目カテゴリ割当情報VIEW3
      WHERE xxpo.item_id      = xiv.inventory_item_id
      AND   NVL(xxpo.l_attribute1,gv_defaultlot) = ilm.lot_no              -- 2008/04/30 修正
      AND   xiv.item_id       = ilm.item_id
      AND   xiv.item_id       = xcv.item_id
      AND   xxpo.vendor_id    = xvv.vendor_id
      AND   xxpo.vendor_id    = xsv.vendor_id(+)
      AND   xxpo.l_attribute2 = xsv.vendor_site_code(+)
      AND   xxpo.h_segment1   = gv_header_number
-- 2008/12/06 H.Itou Add Start
      AND   NVL(xxpo.cancel_flag,'N')  = 'N'     -- 削除フラグ
-- 2008/12/06 H.Itou Add End
      ORDER BY xxpo.line_num;
--
    -- *** ローカル・レコード ***
    lr_base_data_rec base_data_cur%ROWTYPE;
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
    ln_cnt          := 0;
    ln_po_header_id := NULL;
    ln_po_line_id   := NULL;
    ln_lot_id       := NULL;
--
    OPEN base_data_cur;
--
    <<base_data_loop>>
    LOOP
      FETCH base_data_cur INTO lr_base_data_rec;
      EXIT WHEN base_data_cur%NOTFOUND;
--
      mst_rec.h_segment1          := lr_base_data_rec.h_segment1;
      mst_rec.po_header_id        := lr_base_data_rec.po_header_id;
      mst_rec.h_attribute11       := lr_base_data_rec.h_attribute11;
      mst_rec.vendor_id           := lr_base_data_rec.vendor_id;
      mst_rec.h_attribute4        := lr_base_data_rec.h_attribute4;
      mst_rec.h_attribute5        := lr_base_data_rec.h_attribute5;
      mst_rec.h_attribute6        := lr_base_data_rec.h_attribute6;
      mst_rec.h_attribute10       := lr_base_data_rec.h_attribute10;
      mst_rec.po_line_id          := lr_base_data_rec.po_line_id;
-- 2009/12/02 v1.8 T.Yoshimoto Add Start 本稼動障害#263
      mst_rec.po_line_location_id := lr_base_data_rec.line_location_id;
-- 2009/12/02 v1.8 T.Yoshimoto Add End 本稼動障害#263
      mst_rec.line_num            := lr_base_data_rec.line_num;
      mst_rec.item_id             := lr_base_data_rec.item_id;
      mst_rec.lot_no              := lr_base_data_rec.l_attribute1;
      mst_rec.unit_price          := lr_base_data_rec.unit_price;
      mst_rec.quantity            := lr_base_data_rec.quantity;
      mst_rec.unit_code           := lr_base_data_rec.unit_meas_lookup_code;
      mst_rec.l_attribute4        := lr_base_data_rec.l_attribute4;
      mst_rec.l_attribute10       := lr_base_data_rec.l_attribute10;
      mst_rec.l_attribute11       := lr_base_data_rec.l_attribute11;
      mst_rec.lot_id              := lr_base_data_rec.lot_id;
      mst_rec.attribute4          := lr_base_data_rec.attribute4;
      mst_rec.attribute5          := lr_base_data_rec.attribute5;
      mst_rec.item_no             := lr_base_data_rec.item_no;
      mst_rec.segment1            := lr_base_data_rec.segment1;
      mst_rec.vendor_stock_whse   := lr_base_data_rec.vendor_stock_whse;
      mst_rec.lot_ctl             := lr_base_data_rec.lot_ctl;
      mst_rec.item_idv            := lr_base_data_rec.item_idv;
      mst_rec.prod_class_code     := lr_base_data_rec.prod_class_code;
      mst_rec.item_class_code     := lr_base_data_rec.item_class_code;
--
      mst_rec.h_def4_date         := 
                             FND_DATE.STRING_TO_DATE(lr_base_data_rec.h_attribute4,'YYYY/MM/DD');
      mst_rec.def4_date           := 
                             FND_DATE.STRING_TO_DATE(lr_base_data_rec.attribute4,'YYYY/MM/DD');
      mst_rec.def5_date           := 
                             FND_DATE.STRING_TO_DATE(lr_base_data_rec.attribute5,'YYYY/MM/DD');
      mst_rec.def11_qty           := TO_NUMBER(lr_base_data_rec.l_attribute11);
      mst_rec.def5_num            := TO_NUMBER(lr_base_data_rec.h_attribute5);
--
      IF ((ln_po_header_id IS NULL) OR (ln_po_header_id <> mst_rec.po_header_id)) THEN
--
        -- ロック処理(発注ヘッダ)
        BEGIN
          SELECT pha.po_header_id
          INTO   ln_po_header_id
          FROM   po_headers_all pha
          WHERE  pha.po_header_id = mst_rec.po_header_id
          FOR UPDATE OF pha.po_header_id NOWAIT;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
--
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_tkn_number_31d_01,
                                                  gv_tkn_table,
                                                  gv_tbl_name_po_head);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      IF ((ln_po_line_id IS NULL) OR (ln_po_line_id <> mst_rec.po_line_id)) THEN
--
        -- ロック処理(発注明細)
        BEGIN
          SELECT pla.po_line_id
          INTO   ln_po_line_id
          FROM   po_lines_all pla
          WHERE  pla.po_line_id = mst_rec.po_line_id
          FOR UPDATE OF pla.po_line_id NOWAIT;
  --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
  --
          WHEN lock_expt THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_tkn_number_31d_01,
                                                  gv_tkn_table,
                                                  gv_tbl_name_po_line);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
  --
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
--
      -- ロック処理(OPMロットマスタ)
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
        WHEN NO_DATA_FOUND THEN
          NULL;
--
        WHEN lock_expt THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                gv_tkn_number_31d_01,
                                                gv_tkn_table,
                                                gv_tbl_name_lot_mast);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      BEGIN
        SELECT mil.organization_id
              ,mil.subinventory_code
              ,mil.inventory_location_id
        INTO   mst_rec.organization_id
              ,mst_rec.subinventory_code
              ,mst_rec.inventory_location_id
        FROM  mtl_item_locations mil
        WHERE mil.segment1 = mst_rec.h_attribute5;           -- 納入先コード
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
      gt_master_tbl(ln_cnt)  := mst_rec;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP base_data_loop;
--
    CLOSE base_data_cur;
--
    -- 存在しない
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31d_06);
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
      IF (base_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE base_data_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (base_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE base_data_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- カーソルが開いていれば
      IF (base_data_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE base_data_cur;
      END IF;
--
--#####################################  固定部 END   #############################################
--
  END get_mast_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_opif
   * Description      : 受入実績登録処理(D-4)
   ***********************************************************************************/
  PROCEDURE insert_opif(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
    ir_rtn_line_num IN            xxpo_rcv_txns_interface.source_document_line_num%TYPE, -- 受入返品明細番号
-- 2008/10/27 v1.5 T.Yoshimoto Add End
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_opif'; -- プログラム名
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
    ln_factor         xxpo_rcv_and_rtn_txns.conversion_factor%TYPE;
    ln_lot_id         xxpo_rcv_and_rtn_txns.lot_id%TYPE;
    lv_lot_no         xxpo_rcv_and_rtn_txns.lot_number%TYPE;
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
    -- 受入返品実績(アドオン)の取引ID
    SELECT xxpo_rcv_and_rtn_txns_s1.NEXTVAL
    INTO   gn_txns_id
    FROM   DUAL;
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
        ,ir_mst_rec.vendor_id                            -- vendor_id
        ,ir_mst_rec.h_def4_date                          -- expected_receipt_date
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
        ,'RECEIVE'                                       -- transaction_type
-- 2008/12/04 v1.6 T.Yoshimoto Mod Start 本番#420
        --,SYSDATE                                         -- transaction_date
        ,TO_DATE(ir_mst_rec.h_attribute4, 'YYYY/MM/DD')  -- transaction_date(発注ヘッダ.納入日)
-- 2008/12/04 v1.6 T.Yoshimoto Mod End 本番#420
        ,'PENDING'                                       -- processing_status_code
        ,'BATCH'                                         -- processing_mode_code
        ,'PENDING'                                       -- transaction_status_code
        ,ir_mst_rec.quantity                             -- quantity
        ,ir_mst_rec.unit_code                            -- unit_of_measure
        ,ir_mst_rec.item_id                              -- item_id
        ,'DELIVER'                                       -- auto_transact_code
        ,'VENDOR'                                        -- receipt_source_code
        ,ir_mst_rec.organization_id                      -- to_organization_id
        ,'PO'                                            -- source_document_code
        ,ir_mst_rec.po_header_id                         -- po_header_id
        ,ir_mst_rec.po_line_id                           -- po_line_id
-- 2009/12/02 v1.8 T.Yoshimoto Mod Start 本稼動障害#263
        --,ir_mst_rec.po_line_id                           -- po_line_location_id
        ,ir_mst_rec.po_line_location_id                  -- po_line_location_id
-- 2009/12/02 v1.8 T.Yoshimoto Mod End 本稼動障害#263
        ,'INVENTORY'                                     -- destination_type_code
        ,ir_mst_rec.subinventory_code                    -- subinventory
        ,ir_mst_rec.inventory_location_id                -- locator_id
        ,ir_mst_rec.h_def4_date                          -- expected_receipt_date
        ,TO_CHAR(gn_txns_id)                             -- ship_line_attribute1
        ,rcv_headers_interface_s.CURRVAL                 -- header_interface_id
        ,gv_flg_on                                       -- validation_flag
    FROM DUAL;
--
    -- ロット管理品
    IF (ir_mst_rec.lot_ctl = gn_lot_ctl_on) THEN
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
          ,ir_mst_rec.lot_no                             -- lot_number
          ,ABS(ir_mst_rec.quantity)                      -- transaction_quantity
          ,ABS(ir_mst_rec.quantity)                      -- primary_quantity
          ,'RCV'                                         -- product_code
          ,rcv_transactions_interface_s.CURRVAL          -- product_transaction_id
      FROM DUAL;
    END IF;
--
    ln_factor := 1;
--
    -- 「商品区分」が「ドリンク」
    -- 「品目区分」が「製品」
    IF ((ir_mst_rec.prod_class_code = gv_prod_class_code)
    AND (ir_mst_rec.item_class_code = gv_item_class_code)) THEN
--
      -- 「発注単位」<>「単位」
      IF (ir_mst_rec.unit_code <> ir_mst_rec.l_attribute10) THEN
        ln_factor := TO_NUMBER(ir_mst_rec.l_attribute4);
      END IF;
    END IF;
--
    -- ロット管理品 2008/04/30 追加
    IF (ir_mst_rec.lot_ctl = gn_lot_ctl_on) THEN
      ln_lot_id := ir_mst_rec.lot_id;
      lv_lot_no := ir_mst_rec.lot_no;
    ELSE
      ln_lot_id := NULL;
      lv_lot_no := NULL;
    END IF;
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
        ,drop_ship_type
        ,vendor_id
        ,vendor_code
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
        ,'1'                                             -- txns_type
        ,ir_mst_rec.h_segment1                           -- rcv_rtn_number
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
        --,ir_mst_rec.line_num                             -- rcv_rtn_line_number
        ,ir_rtn_line_num                                 -- rcv_rtn_line_number
-- 2008/10/27 v1.5 T.Yoshimoto Add End
        ,ir_mst_rec.h_segment1                           -- source_document_number
        ,ir_mst_rec.line_num                             -- source_document_line_num
        ,ir_mst_rec.h_attribute6                         -- drop_ship_type
        ,ir_mst_rec.vendor_id                            -- vendor_id
        ,ir_mst_rec.segment1                             -- vendor_code
        ,ir_mst_rec.h_attribute5                         -- location_code
        ,ir_mst_rec.h_def4_date                          -- txns_date
-- 2008/05/21 v1.4 Changed
--        ,ir_mst_rec.item_id                              -- item_id
        ,ir_mst_rec.item_idv                              -- item_idv
-- 2008/05/21 v1.4 Changed
        ,ir_mst_rec.item_no                              -- item_code
        ,ln_lot_id                                       -- lot_id
        ,lv_lot_no                                       -- lot_number
        ,ir_mst_rec.def11_qty                            -- rcv_rtn_quantity
        ,ir_mst_rec.l_attribute10                        -- rcv_rtn_uom
        ,ir_mst_rec.quantity                             -- quantity
        ,ir_mst_rec.unit_code                            -- uom
        ,ln_factor                                       -- conversion_factor
        ,ir_mst_rec.unit_price                           -- unit_price
        ,ir_mst_rec.h_attribute10                        -- department_code
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
    gn_proc_flg := 1;
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
  END insert_opif;
--
  /***********************************************************************************
   * Procedure Name   : upd_po_lines
   * Description      : 発注明細更新(D-5)
   ***********************************************************************************/
  PROCEDURE upd_po_lines(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_po_lines'; -- プログラム名
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
      UPDATE po_lines_all
      SET    attribute7             = ir_mst_rec.l_attribute11             -- 受入数量
            ,attribute13            = gv_flg_on                            -- 数量確定フラグ
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE po_line_id = ir_mst_rec.po_line_id;
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
  END upd_po_lines;
--
  /***********************************************************************************
   * Procedure Name   : upd_lot_mst
   * Description      : ロットマスタ更新(D-6)
   ***********************************************************************************/
  PROCEDURE upd_lot_mst(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_mst'; -- プログラム名
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
    ln_flg            NUMBER;
    lv_return_status  VARCHAR2(1);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lr_lot_rec        ic_lots_mst%ROWTYPE;
    lr_lot_cpg_rec    ic_lots_cpg%ROWTYPE;
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
    -- 納入日(初回)がNULL
    -- 納入日(初回) > 納入日
    IF ((lr_lot_rec.attribute4 IS NULL)
     OR (ir_mst_rec.def4_date > ir_mst_rec.h_def4_date)) THEN
      lr_lot_rec.attribute4 := ir_mst_rec.h_attribute4;                   -- 納入日(初回)
      ln_flg := 1;
    END IF;
--
    -- 納入日(最終)がNULL
    -- 納入日(最終) < 納入日
    IF ((lr_lot_rec.attribute5 IS NULL)
     OR (ir_mst_rec.def5_date < ir_mst_rec.h_def4_date)) THEN
      lr_lot_rec.attribute5 := ir_mst_rec.h_attribute4;                   -- 納入日(最終)
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
  END upd_lot_mst;
--
  /***********************************************************************************
   * Procedure Name   : insert_tran
   * Description      : 相手先出庫取引情報登録(D-7)
   ***********************************************************************************/
  PROCEDURE insert_tran(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_tran'; -- プログラム名
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
    -- 発注区分が「相手先在庫」のみ
    IF (ir_mst_rec.h_attribute11 = gv_po_type_rev) THEN
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
      lr_qty_rec.item_no        := ir_mst_rec.item_no;             -- 品目NO
      lr_qty_rec.from_whse_code := ir_mst_rec.from_whse_code;      -- 倉庫
      lr_qty_rec.item_um        := ir_mst_rec.unit_code;           -- 単位
      lr_qty_rec.lot_no         := ir_mst_rec.lot_no;              -- ロットNO
      lr_qty_rec.from_location  := ir_mst_rec.vendor_stock_whse;   -- 出庫元
      lr_qty_rec.trans_qty      := ir_mst_rec.quantity * (-1);     -- 数量
      lr_qty_rec.co_code        := ir_mst_rec.co_code;             -- 会社
      lr_qty_rec.orgn_code      := ir_mst_rec.orgn_code;           -- 組織
      lr_qty_rec.trans_date     := ir_mst_rec.h_def4_date;         -- 取引日
      lr_qty_rec.reason_code    := gv_inv_ship_rsn;                -- 事由コード
      lr_qty_rec.user_name      := gv_user_name;                   -- ユーザ名
      lr_qty_rec.attribute1     := TO_CHAR(gn_txns_id);            -- 文書ソースID
--
      -- 在庫トランザクションの作成
      GMIPAPI.INVENTORY_POSTING(
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
  END insert_tran;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 受入実績登録処理(D-8)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ir_mst_rec      IN OUT NOCOPY masters_rec,  -- 対象レコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- プログラム名
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
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31d_07,
                                          gv_tkn_m_no,
                                          ir_mst_rec.line_num,
                                          gv_tkn_item_no,
                                          ir_mst_rec.item_no,
                                          gv_tkn_nonyu_date,
                                          SUBSTR(ir_mst_rec.h_attribute4,1,10));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : upd_po_headrs
   * Description      : 発注ステータス更新(D-9)
   ***********************************************************************************/
  PROCEDURE upd_po_headrs(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_po_headrs'; -- プログラム名
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
    mst_rec         masters_rec;
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
    mst_rec := gt_master_tbl(0);
--
    BEGIN
      UPDATE po_headers_all
      SET    attribute1             = gv_add_status_num_zmi                 -- ステータス
            ,last_update_date       = gd_last_update_date
            ,last_updated_by        = gn_last_update_by
            ,last_update_login      = gn_last_update_login
            ,request_id             = gn_request_id
            ,program_application_id = gn_program_application_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_program_update_date
      WHERE po_header_id = mst_rec.po_header_id;
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
  END upd_po_headrs;
--
  /***********************************************************************************
   * Procedure Name   : commit_opif
   * Description      : 受入オープンIFデータ反映(D-10)
   ***********************************************************************************/
  PROCEDURE commit_opif(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'commit_opif'; -- プログラム名
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
    lb_ret         NUMBER ;
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
    COMMIT;
--
    -- 受入オープンIF登録あり
    IF (gn_proc_flg = 1) THEN
--
      -- コンカレントの起動
      lb_ret := FND_REQUEST.SUBMIT_REQUEST(
                    application  => gv_appl_name         -- アプリケーション短縮名
                   ,program      => gv_prg_name          -- プログラム名
                   ,argument1    => 'BATCH'              -- 処理モード
                   ,argument2    => TO_CHAR(gn_group_id) -- グループID
                  );
--
      -- エラー
      IF (lb_ret = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31d_02);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
  END commit_opif;
--
  /***********************************************************************************
   * Procedure Name   : disp_count
   * Description      : 処理結果レポート出力(D-11)
   ***********************************************************************************/
  PROCEDURE disp_count(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_count';           -- プログラム名
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
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31d_08,
                                          gv_tkn_count,
                                          TO_CHAR(gt_master_tbl.COUNT));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END disp_count;
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
    mst_rec         masters_rec;
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
    ln_count      NUMBER;
    lv_doc_num    xxpo_rcv_and_rtn_txns.source_document_number%TYPE;
    ln_line_num   xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE;
-- 2008/10/27 v1.5 T.Yoshimoto Add End
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_proc_flg   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ================================
    -- D-1.前処理
    -- ================================
    init_proc(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- D-2.パラメータチェック
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
    -- D-3.発注情報取得
    -- ================================
    get_mast_data(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
    <<number_get_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
--
      mst_rec := gt_master_tbl(i);
--
      IF ((i = 0)
       OR (lv_doc_num <> mst_rec.h_segment1)
       OR (ln_line_num <> mst_rec.line_num)) THEN
--
        lv_doc_num  := mst_rec.h_segment1;
        ln_line_num := mst_rec.line_num;
--
        -- 件数取得
        SELECT COUNT(xrrt.txns_id)
        INTO   ln_count
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.source_document_number   = mst_rec.h_segment1
        AND    xrrt.source_document_line_num = mst_rec.line_num
        AND    ROWNUM = 1;
      END IF;
--
      ln_count := ln_count + 1;
      gt_rtn_line_num(i) := ln_count;
    END LOOP number_get_loop;
-- 2008/10/27 v1.5 T.Yoshimoto Add End
--
    <<main_proc_loop>>
    FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
      mst_rec := gt_master_tbl(i);
--
      -- ================================
      -- D-4.受入実績登録処理
      -- ================================
      insert_opif(
        mst_rec,            -- 対象データ
-- 2008/10/27 v1.5 T.Yoshimoto Add Start
        gt_rtn_line_num(i), -- 元文書明細番号
-- 2008/10/27 v1.5 T.Yoshimoto Add End
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ================================
      -- D-5.発注明細更新
      -- ================================
      upd_po_lines(
        mst_rec,            -- 対象データ
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ロット管理品のみ実行 2008/04/30 修正
      IF (mst_rec.lot_ctl = gn_lot_ctl_on) THEN
--
        -- ================================
        -- D-6.ロットマスタ更新
        -- ================================
        upd_lot_mst(
          mst_rec,            -- 対象データ
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ================================
      -- D-7.相手先出庫取引情報登録
      -- ================================
      insert_tran(
        mst_rec,            -- 対象データ
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ================================
      -- D-8.処理完了発注情報出力
      -- ================================
      disp_report(
        mst_rec,            -- 対象データ
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP main_proc_loop;
--
    -- ================================
    -- D-9.発注ステータス更新
    -- ================================
    upd_po_headrs(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2011/06/07 v1.9 K.Kubo Add Start
    -- ================================
    -- D-12.仕入実績作成処理管理TBLの削除
    -- ================================
    -- 仕入実績情報削除 関数実施
    xxpo_common3_pkg.delete_result(
                       mst_rec.po_header_id  -- 発注ヘッダID
                      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
                      ,lv_retcode            -- リターン・コード             --# 固定 #
                      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                     );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2011/06/07 v1.9 K.Kubo Add End
--
    -- ================================
    -- D-10.受入オープンIFのデータ反映
    -- ================================
    commit_opif(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- D-11.処理件数出力
    -- ================================
    disp_count(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
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
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_po_number  IN            VARCHAR2)         -- 1.発注番号
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
-- 2012/03/06 v1.10 K.Nakamura Add Start
    ln_po_header_id  po_headers_all.po_header_id%TYPE;  -- 発注ヘッダID
    ln_xsrm_cnt      NUMBER;                            -- 仕入実績作成処理管理TBL件数
-- 2012/03/06 v1.10 K.Nakamura Add End
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
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
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
/*
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
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
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
*/
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
-- 2012/03/06 v1.10 K.Nakamura Add Start
      -- ================================
      -- D-13.仕入実績作成処理管理TBLの削除(エラー発生時)
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
          -- メッセージは出力済みのため
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
-- 2012/03/06 v1.10 K.Nakamura Add End
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
END xxpo310001c;
/
