CREATE OR REPLACE PACKAGE BODY xxpo940002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940002c(body)
 * Description      : 出来高実績取込処理
 * MD.050           : 取引先オンライン T_MD050_BPO_940
 * MD.070           : 出来高実績取込処理 T_MD070_BPO_94B
 * Version          : 1.10
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init_proc                 初期処理(B-1)
 *  check_data                取得データチェック処理(B-3)
 *  get_other_data            関連データ取得処理(B-4)
 *  ins_ic_lot_mst            ロットマスタ登録処理(B-5)
 *  ins_vendor_suppry_txns    外注出来高実績(アドオン)登録処理(B-6)
 *  ins_inventory_data        相手先在庫計上処理(B-7)
 *  ins_po_data               発注自動作成処理(B-8)
 *  ins_qt_inspection         品質検査依頼情報作成処理(B-9)
 *  import_standard_po        標準発注インポートの呼出処理(B-10)
 *  del_vendor_supply_txns_if データ削除処理(B-11)
 *  put_dump_msg              データダンプ一括出力処理(B-12)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/06/06    1.0   Oracle 伊藤ひとみ   初回作成
 *  2008/07/08    1.1   Oracle 山根一浩     I_S_192対応
 *  2008/07/22    1.2   Oracle 伊藤ひとみ   内部課題#32対応
 *  2008/08/18    1.3   Oracle 伊藤ひとみ   T_S_595 品目情報VIEW2を製造日基準で抽出する
 *  2008/12/02    1.4   SCS    伊藤ひとみ   本番障害#171
 *  2008/12/24    1.5   SCS    山本 恭久    本番障害#743
 *  2008/12/26    1.6   SCS    伊藤 ひとみ  本番障害#809
 *  2009/02/09    1.7   SCS    吉田 夏樹    本番#15、#1178対応
 *  2009/03/13    1.8   SCS    伊藤 ひとみ  本番#32対応
 *  2009/03/24    1.9   SCS    飯田 甫      本番障害#1317対応
 *  2018/02/22    1.10  SCSK   佐々木宏之   賞味期限取得方法変更(E_本稼動_14859)
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  proc_err_expt              EXCEPTION;  -- プロシージャ例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxpo940002c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_xxpo                 CONSTANT VARCHAR2(5) := 'XXPO';   -- モジュール名略称:XXPO
  gv_xxcmn                CONSTANT VARCHAR2(5) := 'XXCMN';  -- モジュール名略称:XXCMN
--
  -- メッセージ
  gv_msg_xxcmn10002       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn10019       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- メッセージ:APP-XXCMN-10019 ロックエラー
  gv_msg_xxcmn10001       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- メッセージ:APP-XXCMN-10001 対象データなし
  gv_msg_xxcmn00005       CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- メッセージ:APP-XXCMN-00005 成功データ（見出し）
  gv_msg_xxcmn00007       CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007'; -- メッセージ:APP-XXCMN-00007 スキップデータ（見出し）
-- 2008/07/22 H.Itou Add Start
  gv_msg_xxcmn10603       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10603'; -- メッセージ:APP-XXCMN-10603 ケース入数エラー
-- 2008/07/22 H.Itou Add End
  gv_msg_xxpo10005        CONSTANT VARCHAR2(100) := 'APP-XXPO-10005';  -- メッセージ:APP-XXPO-10005 ロット登録済みエラー
  gv_msg_xxpo10110        CONSTANT VARCHAR2(100) := 'APP-XXPO-10110';  -- メッセージ:APP-XXPO-10110 ロット採番エラー
  gv_msg_xxpo10007        CONSTANT VARCHAR2(100) := 'APP-XXPO-10007';  -- メッセージ:APP-XXPO-10007 データ登録エラー
  gv_msg_xxpo10025        CONSTANT VARCHAR2(100) := 'APP-XXPO-10025';  -- メッセージ:APP-XXPO-10025 コンカレント登録エラー
  gv_msg_xxpo10226        CONSTANT VARCHAR2(100) := 'APP-XXPO-10226';  -- メッセージ:APP-XXPO-10226 処理タイプエラー
  gv_msg_xxpo10002        CONSTANT VARCHAR2(100) := 'APP-XXPO-10002';  -- メッセージ:APP-XXPO-10002 必須エラー
  gv_msg_xxpo10119        CONSTANT VARCHAR2(100) := 'APP-XXPO-10119';  -- メッセージ:APP-XXPO-10119 在庫クローズエラー3
  gv_msg_xxpo10255        CONSTANT VARCHAR2(100) := 'APP-XXPO-10255';  -- メッセージ:APP-XXPO-10255 数値0以下エラー2
  gv_msg_xxpo10256        CONSTANT VARCHAR2(100) := 'APP-XXPO-10256';  -- メッセージ:APP-XXPO-10256 製品必須エラー
  gv_msg_xxpo10215        CONSTANT VARCHAR2(100) := 'APP-XXPO-10215';  -- メッセージ:APP-XXPO-10215 取引先関連チェックエラー
  gv_msg_xxpo10257        CONSTANT VARCHAR2(100) := 'APP-XXPO-10257';  -- メッセージ:APP-XXPO-10257 ロット管理外品エラー
  gv_msg_xxpo30051        CONSTANT VARCHAR2(100) := 'APP-XXPO-30051';  -- メッセージ:APP-XXPO-30051 入力パラメータ(見出し)
-- 2009/03/24 H.Iida Add Start 本番障害#1317対応
  gv_msg_xxpo10288        CONSTANT VARCHAR2(100) := 'APP-XXPO-10288';  -- メッセージ:APP-XXPO-10288 未来日エラー
-- 2009/03/24 H.Iida Add End
--
  -- トークン
  gv_tkn_ng_profile       CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_table            CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_key              CONSTANT VARCHAR2(100) := 'KEY';
  gv_tkn_item_no          CONSTANT VARCHAR2(100) := 'ITEM_NO';
  gv_tkn_info_name        CONSTANT VARCHAR2(100) := 'INFO_NAME';
  gv_tkn_prg_name         CONSTANT VARCHAR2(100) := 'PRG_NAME';
  gv_tkn_item             CONSTANT VARCHAR2(100) := 'ITEM';
  gv_tkn_token            CONSTANT VARCHAR2(100) := 'TOKEN';
--
  -- トークン名称
  gv_tkn_ctpty_inv_rcv_rsn   CONSTANT VARCHAR2(100) := 'XXPO:相手先在庫計上事由';
  gv_tkn_ctpty_cost_rsn      CONSTANT VARCHAR2(100) := 'XXPO:相手先原価計上事由';
  gv_tkn_purchase_emp_id     CONSTANT VARCHAR2(100) := 'XXPO:購買担当者ID';
  gv_tkn_bill_to_location_id CONSTANT VARCHAR2(100) := 'XXPO:請求先事業所ID';
  gv_tkn_po_line_type_id     CONSTANT VARCHAR2(100) := 'XXPO:発注明細タイプID';
  gv_tkn_cost_cmpntcls_code  CONSTANT VARCHAR2(100) := 'XXPO:ロット原価-コンポーネント区分';
  gv_tkn_cost_mthd_code      CONSTANT VARCHAR2(100) := 'XXPO:ロット原価-ロット原価方法';
  gv_tkn_cost_analysis_code  CONSTANT VARCHAR2(100) := 'XXPO:ロット原価-分析';
  gv_tkn_org_id              CONSTANT VARCHAR2(100) := 'MO:営業単位';
  gv_tkn_vendor_sply_txns_if CONSTANT VARCHAR2(100) := '出来高実績情報インタフェース';
  gv_tkn_vendors             CONSTANT VARCHAR2(100) := '仕入先情報';
  gv_tkn_vendor_sites        CONSTANT VARCHAR2(100) := '仕入先サイト情報';
  gv_tkn_item_mst            CONSTANT VARCHAR2(100) := 'OPM品目情報';
  gv_tkn_ic_lot_mst          CONSTANT VARCHAR2(100) := 'OPMロットマスタ';
  gv_tkn_vendor_sply_txns    CONSTANT VARCHAR2(100) := '外注出来高実績(アドオン)';
  gv_tkn_xxpo_headers_all    CONSTANT VARCHAR2(100) := '発注ヘッダ(アドオン)';
  gv_tkn_po_headers_if       CONSTANT VARCHAR2(100) := '発注ヘッダオープンインタフェース';
  gv_tkn_po_lines_if         CONSTANT VARCHAR2(100) := '発注明細オープンインタフェース';
  gv_tkn_po_distributions_if CONSTANT VARCHAR2(100) := '搬送明細オープンインタフェース';
  gv_tkn_lc_adjustment       CONSTANT VARCHAR2(100) := 'ロット原価';
  gv_tkn_ic_tran_cmp         CONSTANT VARCHAR2(100) := '在庫取引';
  gv_tkn_qt_inspection       CONSTANT VARCHAR2(100) := '品質検査依頼情報';
  gv_tkn_vendor_code         CONSTANT VARCHAR2(100) := '仕入先コード:';
  gv_tkn_vendor_site_code    CONSTANT VARCHAR2(100) := '仕入先サイトコード:';
  gv_tkn_item_code           CONSTANT VARCHAR2(100) := '品目コード:';
  gv_tkn_conc_name           CONSTANT VARCHAR2(100) := '標準発注インポート';
  gv_tkn_producted_qty_name  CONSTANT VARCHAR2(100) := '出来高数量';
  gv_tkn_koyu_code_name      CONSTANT VARCHAR2(100) := '固有記号';
  gv_tkn_factory_code_name   CONSTANT VARCHAR2(100) := '工場';
-- 2008/12/02 H.Itou Add Start 本番障害#171
  gv_tkn_koyu_code           CONSTANT VARCHAR2(100) := '工場固有記号:';
-- 2008/12/02 H.Itou Add End
-- 2009/03/24 H.Iida Add Start 本番障害#1317対応
  gv_tkn_manufactured_date   CONSTANT VARCHAR2(100) := '生産日';
-- 2009/03/24 H.Iida Add End
--
  -- セキュリティ区分
  gv_security_kbn_in         CONSTANT VARCHAR2(1) := '1'; -- セキュリティ区分 伊藤園ユーザー
  gv_security_kbn_out        CONSTANT VARCHAR2(1) := '2'; -- セキュリティ区分 取引先ユーザー

  -- 日付書式
  gv_yyyymm                  CONSTANT VARCHAR2(10) := 'YYYYMM';
  gv_yyyymmdd                CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  gv_yyyymmddhh24miss        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- 処理タイプ
  gv_product_result_type_inv CONSTANT VARCHAR2(1) := '1'; -- 処理タイプ:相手先在庫
  gv_product_result_type_po  CONSTANT VARCHAR2(1) := '2'; -- 処理タイプ:即時仕入
--
  -- 品目区分
  gv_item_class_code_prod    CONSTANT VARCHAR2(1) := '5'; -- 品目区分:製品
--
  -- 商品区分
  gv_prod_class_code_drink   CONSTANT VARCHAR2(1) := '2'; -- 商品区分:ドリンク
--
  -- 単位
  gv_um_cs                   CONSTANT VARCHAR2(2) := 'CS'; -- ケース
--
  -- 原価管理区分
  gv_cost_manage_code_j      CONSTANT VARCHAR2(1) := '0'; -- 原価管理区分:実際原価
  gv_cost_manage_code_h      CONSTANT VARCHAR2(1) := '1'; -- 原価管理区分:標準原価
--
  -- 仕入単価導入日タイプ
  gv_unit_price_calc_code_prod  CONSTANT VARCHAR2(1) := '1'; -- 仕入単価導入日タイプ:製造日
  gv_unit_price_calc_code_loc   CONSTANT VARCHAR2(1) := '2'; -- 仕入単価導入日タイプ:納入日
--
  -- 付帯コード
  gv_futai_code_0            CONSTANT VARCHAR2(1) := '0'; -- 付帯コード:0
--
  -- マスタ区分
  gv_price_type_po           CONSTANT VARCHAR2(1) := '1'; -- マスタ区分:仕入
--
  -- 採番関数区分
  gv_seq_class_po            CONSTANT VARCHAR2(1) := '2'; -- 採番関数区分:発注番号
--
  -- 試験有無区分
  gv_test_code_y             CONSTANT VARCHAR2(1) := '1'; -- 試験有無区分:有
  gv_test_code_n             CONSTANT VARCHAR2(1) := '0'; -- 試験有無区分:無
--
  -- ロットステータス
  gv_lot_status_ok           CONSTANT VARCHAR2(2) := '50'; -- ロットステータス:合格
  gv_lot_status_nochk        CONSTANT VARCHAR2(2) := '10'; -- ロットステータス:未判定
--
  -- 作成区分
  insert_kbn_2               CONSTANT VARCHAR2(1) := '2';  -- 作成区分:2
  insert_kbn_3               CONSTANT VARCHAR2(1) := '3';  -- 作成区分:3
--
  -- APIリターン・コード
  gv_api_ret_cd_normal       CONSTANT VARCHAR2(1) := 'S';  -- APIリターン・コード:正常終了
--
  -- フラグ
  gv_flg_y     CONSTANT VARCHAR2(1) := 'Y';  -- フラグ:Y
  gv_flg_n     CONSTANT VARCHAR2(1) := 'N';  -- フラグ:N
--
  -- 取引タイプ
  gv_trans_type_sok          CONSTANT NUMBER      := 2;    -- 取引タイプ:即時調整
--
  -- 発注ステータス
  gv_po_status_m             CONSTANT VARCHAR2(2) := '20';  -- 発注ステータス:作成済
--
  -- 直送区分
  gv_direct_flg              CONSTANT VARCHAR2(1) := '1';  -- 直送区分:通常
--
  -- 発注区分
  gv_po_kbn                  CONSTANT VARCHAR2(1) := '1';  -- 発注区分:新規
--
  -- 口銭区分
  gv_kosen_kbn_n             CONSTANT VARCHAR2(1) := '3';  -- 口銭区分:なし
--
  -- 賦課金区分
  gv_fuka_kbn_n              CONSTANT VARCHAR2(1) := '3';  -- 賦課金区分:なし
--
  -- ロット管理区分
  gv_lot_ctl_y               CONSTANT VARCHAR2(1) := '1';  -- ロット管理区分:ロット管理品
--
  -- 区分
  gt_division_gme     CONSTANT xxwip_qt_inspection.division%TYPE := '1';  -- 区分  1:生産
  gt_division_po      CONSTANT xxwip_qt_inspection.division%TYPE := '2';  -- 区分  2:発注
  gt_division_lot     CONSTANT xxwip_qt_inspection.division%TYPE := '3';  -- 区分  3:ロット情報
  gt_division_spl     CONSTANT xxwip_qt_inspection.division%TYPE := '4';  -- 区分  4:外注出来高
  gt_division_tea     CONSTANT xxwip_qt_inspection.division%TYPE := '5';  -- 区分  5:荒茶製造
--
  -- 処理区分
  gv_disposal_div_ins CONSTANT VARCHAR2(1) := '1'; -- 処理区分  1:追加
  gv_disposal_div_upd CONSTANT VARCHAR2(1) := '2'; -- 処理区分  2:更新
  gv_disposal_div_del CONSTANT VARCHAR2(1) := '3'; -- 処理区分  3:削除
--
-- 2008/08/18 H.Itou Add Start T_S_595
  -- 無効フラグ
  gv_inactive_ind_y   CONSTANT VARCHAR2(1) := '1'; -- 無効フラグ 1:無効
--
  -- 廃止区分
  gv_obsolete_class_y CONSTANT VARCHAR2(1) := '1'; -- 廃止区分 1:廃止
-- 2008/08/18 H.Itou Add End
--
-- 2008/12/02 H.Itou Add Start 本番障害#171
  -- クイックコードタイプ
  gv_plant_uniqe_sign CONSTANT VARCHAR2(100) := 'XXCMN_PLANT_UNIQE_SIGN'; -- 工場固有記号
-- 2008/12/02 H.Itou Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- メッセージPL/SQL表型
  TYPE msg_ttype         IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- 出来高実績情報インタフェースID PL/SQL表型
  TYPE txns_if_id_ttype IS TABLE OF xxpo_vendor_supply_txns_if.txns_if_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- データダンプ用PL/SQL表
  warn_dump_tab          msg_ttype; -- 警告
  normal_dump_tab        msg_ttype; -- 正常
--
  -- 出来高実績情報インタフェースID PL/SQL表
  txns_if_id_tab         txns_if_id_ttype;
--
  -- PL/SQL表カウント
  gn_warn_msg_cnt        NUMBER := 0; -- 警告エラーメッセージPL/SQ表 カウント
  gn_po_cnt              NUMBER := 0; -- バッチID PL/SQL表 カウント
--
  -- プロファイル・オプション
  gv_ctpty_inv_rcv_rsn   VARCHAR2(100);          -- XXPO:相手先在庫計上事由
  gv_ctpty_cost_rsn      VARCHAR2(100);          -- XXPO:相手先原価計上事由
  gv_purchase_emp_id     VARCHAR2(100);          -- XXPO:購買担当者ID
  gv_bill_to_location_id VARCHAR2(100);          -- XXPO:請求先事業所ID
  gv_po_line_type_id     VARCHAR2(100);          -- XXPO:発注明細タイプID
  gv_cost_cmpntcls_code  VARCHAR2(100);          -- XXPO:ロット原価-コンポーネント区分
  gv_cost_mthd_code      VARCHAR2(100);          -- XXPO:ロット原価-ロット原価方法
  gv_cost_analysis_code  VARCHAR2(100);          -- XXPO:ロット原価-分析
  gv_org_id              VARCHAR2(100);          -- MO:営業単位
--
  -- 入力パラメータ
  gv_in_data_class             VARCHAR2(100);  -- データ種別
  gv_in_vendor_code            VARCHAR2(100);  -- 取引先
  gv_in_factory_code           VARCHAR2(100);  -- 工場
  gv_in_manufactured_date_from VARCHAR2(100);  -- 生産日FROM
  gv_in_manufactured_date_to   VARCHAR2(100);  -- 生産日TO
  gv_in_security_kbn           VARCHAR2(100);  -- セキュリティ区分
--
  gt_stock_value               xxpo_price_headers.total_amount%TYPE;              -- 在庫単価
  gt_unit_price                xxpo_price_headers.total_amount%TYPE;              -- 仕入単価
  gt_po_number                 xxpo_headers_all.po_header_number%TYPE;            -- 発注番号
  gt_location_id               xxcmn_item_locations_v.inventory_location_id%TYPE; -- 納入先ID(保管場所ID)
  gt_whse_code                 xxcmn_item_locations_v.whse_code%TYPE;             -- 倉庫コード
  gt_organization_id           xxcmn_item_locations_v.mtl_organization_id%TYPE;   -- 在庫組織ID
  gt_co_code                   sy_orgn_mst_b.co_code%TYPE;                        -- 会社コード
  gt_orgn_code                 sy_orgn_mst_b.orgn_code%TYPE;                      -- 組織コード
  gt_ship_to_location_id       hr_all_organization_units.location_id%TYPE;        -- 納入先事業所ID(事業所ID)
  gt_lot_no                    xxpo_vendor_supply_txns.lot_number%TYPE;           -- ロットNo
  gt_lot_id                    xxpo_vendor_supply_txns.lot_id%TYPE;               -- ロットID
  gt_txns_id                   xxpo_vendor_supply_txns.txns_id%TYPE;              -- 実績ID
  gt_batch_id                  po_headers_interface.batch_id%TYPE;                -- バッチID
--
  -- ===================================
  -- ユーザー定義グローバルカーソル
  -- ===================================
  CURSOR main_cur IS
    SELECT xvsti.txns_if_id               txns_if_id          -- 出来高実績情報インタフェースID
          ,xvsti.manufactured_date        manufactured_date   -- 生産日
          ,xvsti.vendor_code              vendor_code         -- 取引先コード
          ,xvsti.factory_code             factory_code        -- 工場コード
          ,xvsti.item_code                item_code           -- 品目コード
          ,xvsti.producted_date           producted_date      -- 製造日
          ,xvsti.koyu_code                koyu_code           -- 固有記号
          ,xvsti.producted_quantity       producted_quantity  -- 出来高数量
          ,xvsti.description              description         -- 摘要
          ,xvv.product_result_type        product_result_type -- 処理タイプ
          ,xvv.vendor_id                  vendor_id           -- 取引先ID
          ,xvv.department                 department          -- 部署
          ,xvsv.vendor_site_id            factory_id          -- 工場ID
          ,xvsv.vendor_id                 f_vendor_id         -- 工場コードの取引先ID
          ,xicv.item_class_code           item_class_code     -- 品目区分
          ,ximv.item_id                   item_id             -- OPM品目ID
          ,ximv.item_um                   uom                 -- 単位コード
          ,ximv.test_code                 test_code           -- 試験有無区分
          ,ximv.cost_manage_code          cost_manage_code    -- 原価管理区分
          ,ximv.lot_ctl                   lot_ctl             -- ロット管理区分
          ,ximv.inventory_item_id         inventory_item_id   -- INV品目ID
--  2018/02/22 V1.10 Modified START
--          ,xvsti.producted_date + TO_NUMBER(ximv.expiration_day)
--                                          expiration_date     -- 賞味期限
          , xxcmn_common5_pkg.get_use_by_date(
                id_producted_date     =>  xvsti.producted_date
              , iv_expiration_type    =>  ximv.expiration_type
              , in_expiration_day     =>  ximv.expiration_day
              , in_expiration_month   =>  ximv.expiration_month
            )                             expiration_date     -- 賞味期限
--  2018/02/22 V1.10 Modified END
          ,ximv.unit_price_calc_code      unit_price_calc_code-- 仕入単価導入日タイプ
          ,CASE -- 納入先コード(保管場所コード)
                --   処理タイプ1:相手先在庫→相手先在庫入庫先
                --   処理タイプ2:即時仕入→発注納入先
             WHEN (xvv.product_result_type = gv_product_result_type_inv) THEN
                  xvsv.vendor_stock_whse
             WHEN (xvv.product_result_type = gv_product_result_type_po) THEN
                  xvsv.delivery_whse
           END                            location_code
          ,CASE -- ロットステータス
                --   試験有無区分1:有→10:未判定
                --   試験有無区分0:無→50:合格
             WHEN (ximv.test_code = gv_test_code_y) THEN
                  gv_lot_status_nochk
             WHEN (ximv.test_code = gv_test_code_n) THEN
                  gv_lot_status_ok
           END                            lot_status
          ,CASE -- 出来高単位コード
                --   商品区分2:ドリンク 品目区分5:製品 入出庫換算単位がNULLでない→入出庫換算単位
                --   上記以外→品目基準単位
             WHEN ((xicv.prod_class_code = gv_prod_class_code_drink)
              AND  (xicv.item_class_code = gv_item_class_code_prod)
-- 2008/07/22 H.Itou Mod Start
--              AND  (ximv.conv_unit       = gv_um_cs)) THEN
              AND  (ximv.conv_unit       IS NOT NULL)) THEN
-- 2008/07/22 H.Itou Mod End
                  ximv.conv_unit
             ELSE ximv.item_um
           END                            producted_uom
          ,CASE -- 在庫入数
                --   品目区分5:製品→ケース入数
                --   上記以外→代表入数
             WHEN (xicv.item_class_code = gv_item_class_code_prod) THEN 
                  TO_NUMBER(ximv.num_of_cases) -- ケース入数
             ELSE TO_NUMBER(ximv.frequent_qty) -- 代表入数
           END                            stock_qty
          ,CASE -- 換算入数
                --   商品区分2:ドリンク 品目区分5:製品 入出庫換算単位がNULLでない→ケース入数
                --   上記以外→換算不要なので1
             WHEN ((xicv.prod_class_code = gv_prod_class_code_drink)
              AND  (xicv.item_class_code = gv_item_class_code_prod)
-- 2008/07/22 H.Itou Mod Start
--              AND  (ximv.conv_unit       = gv_um_cs)) THEN
              AND  (ximv.conv_unit       IS NOT NULL)) THEN
-- 2008/07/22 H.Itou Mod End
                  TO_NUMBER(ximv.num_of_cases)
             ELSE 1
           END                            conversion_factor
-- 2008/08/18 H.Itou Add Start T_S_595
          ,ximv.inactive_ind              inactive_ind        -- 無効フラグ
          ,ximv.obsolete_class            obsolete_class      -- 廃止区分
-- 2008/08/18 H.Itou Add End
          ,xvsti.corporation_name                         || gv_msg_comma ||
           xvsti.data_class                               || gv_msg_comma ||
           xvsti.transfer_branch_no                       || gv_msg_comma ||
           TO_CHAR(xvsti.manufactured_date, gv_yyyymmdd)  || gv_msg_comma ||
           xvsti.vendor_code                              || gv_msg_comma ||
           xvsti.factory_code                             || gv_msg_comma ||
           xvsti.item_code                                || gv_msg_comma ||
           TO_CHAR(xvsti.producted_date, gv_yyyymmdd)     || gv_msg_comma ||
           xvsti.koyu_code                                || gv_msg_comma ||
           TO_CHAR(xvsti.producted_quantity)              || gv_msg_comma ||
           TO_CHAR(xvsti.description)     data_dump           -- データダンプ
    FROM   xxpo_vendor_supply_txns_if     xvsti               -- 出来高実績情報インタフェース
          ,xxcmn_vendors_v                xvv                 -- 仕入先情報VIEW
          ,xxcmn_vendor_sites_v           xvsv                -- 仕入先サイト情報VIEW
-- 2008/08/18 H.Itou Mod Start T_S_595
--          ,xxcmn_item_mst_v              ximv                 -- OPM品目情報VIEW
          ,xxcmn_item_mst2_v              ximv                -- OPM品目情報VIEW2
-- 2008/08/18 H.Itou Mod End
          ,xxcmn_item_categories5_v       xicv                -- OPM品目カテゴリ割当情報VIEW5
    WHERE  -- ** 結合条件  仕入先情報VIEW  ** --
           xvsti.vendor_code         = xvv.segment1(+)                 -- 取引先コード
           -- ** 結合条件  仕入先情報VIEW  ** --
    AND    xvsti.factory_code         = xvsv.vendor_site_code(+)       -- 工場コード
           -- ** 結合条件  OPM品目情報VIEW  ** --
    AND    xvsti.item_code            = ximv.item_no(+)                -- 品目コード
-- 2008/08/18 H.Itou Add Start T_S_595
    AND    ximv.start_date_active(+) <= TRUNC(xvsti.producted_date)    -- 適用開始日 <= 製造日
    AND    ximv.end_date_active(+)   >= TRUNC(xvsti.producted_date)    -- 適用終了日 >= 製造日
-- 2008/08/18 H.Itou Add End
           -- ** 結合条件  OPM品目カテゴリ割当情報VIEW3  ** --
    AND    xvsti.item_code            = xicv.item_no(+)                -- 品目コード
           -- ** 抽出条件 ** --
    AND    xvsti.data_class           = gv_in_data_class               -- データ種別
    AND    xvsti.vendor_code          = gv_in_vendor_code              -- 取引先
    AND    xvsti.factory_code         = NVL(gv_in_factory_code, xvsti.factory_code) -- 工場(入力ありの場合、条件に追加)
    AND    xvsti.manufactured_date   >= FND_DATE.STRING_TO_DATE(gv_in_manufactured_date_from, gv_yyyymmddhh24miss) -- 生産日FROM
    AND    xvsti.manufactured_date   <= FND_DATE.STRING_TO_DATE(gv_in_manufactured_date_to, gv_yyyymmddhh24miss)   -- 生産日TO
    AND   ((gv_in_security_kbn        = gv_security_kbn_in)            -- セキュリティ区分 1:伊藤園ユーザー
      OR  (((gv_in_security_kbn       = gv_security_kbn_out)           -- セキュリティ区分 2:取引先ユーザーの場合、ログインユーザーの取引先コード
        AND (xvsti.vendor_code IN (
              SELECT papf.attribute4    vendor_code                  -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID))))) -- ユーザーID
  ;
--
  -- カーソル用レコード
  gr_main_data  main_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(B-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    cv_ctpty_inv_rcv_rsn   VARCHAR2(100) := 'XXPO_CTPTY_INV_RCV_RSN';   -- XXPO:相手先在庫計上事由
    cv_ctpty_cost_rsn      VARCHAR2(100) := 'XXPO_CTPTY_COST_RSN';      -- XXPO:相手先原価計上事由
    cv_purchase_emp_id     VARCHAR2(100) := 'XXPO_PURCHASE_EMP_ID';     -- XXPO:購買担当者ID
    cv_bill_to_location_id VARCHAR2(100) := 'XXPO_BILL_TO_LOCATION_ID'; -- XXPO:請求先事業所ID
    cv_po_line_type_id     VARCHAR2(100) := 'XXPO_PO_LINE_TYPE_ID';     -- XXPO:発注明細タイプID
    cv_cost_cmpntcls_code  VARCHAR2(100) := 'XXPO_COST_CMPNTCLS_CODE';  -- XXPO:ロット原価-コンポーネント区分
    cv_cost_mthd_code      VARCHAR2(100) := 'XXPO_COST_MTHD_CODE';      -- XXPO:ロット原価-ロット原価方法
    cv_cost_analysis_code  VARCHAR2(100) := 'XXPO_COST_ANALYSIS_CODE';  -- XXPO:ロット原価-分析
    cv_org_id              VARCHAR2(100) := 'ORG_ID';                   -- MO:営業単位
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 出来高実績情報インタフェースカーソル
    CURSOR xxpo_vendor_supply_txns_if_cur
    IS
      SELECT xvsti.txns_if_id            txns_if_id   -- 出来高実績情報インタフェースID
      FROM   xxpo_vendor_supply_txns_if  xvsti        -- 出来高実績情報インタフェース
      FOR UPDATE NOWAIT
    ;
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
    -- ===========================
    -- プロファイルオプション取得
    -- ===========================
    gv_ctpty_inv_rcv_rsn   := FND_PROFILE.VALUE(cv_ctpty_inv_rcv_rsn);   -- XXPO:相手先在庫計上事由
    gv_ctpty_cost_rsn      := FND_PROFILE.VALUE(cv_ctpty_cost_rsn);      -- XXPO:相手先原価計上事由
    gv_purchase_emp_id     := FND_PROFILE.VALUE(cv_purchase_emp_id);     -- XXPO:購買担当者ID
    gv_bill_to_location_id := FND_PROFILE.VALUE(cv_bill_to_location_id); -- XXPO:請求先事業所ID
    gv_po_line_type_id     := FND_PROFILE.VALUE(cv_po_line_type_id);     -- XXPO:発注明細タイプID
    gv_cost_cmpntcls_code  := FND_PROFILE.VALUE(cv_cost_cmpntcls_code);  -- XXPO:ロット原価-コンポーネント区分
    gv_cost_mthd_code      := FND_PROFILE.VALUE(cv_cost_mthd_code);      -- XXPO:ロット原価-ロット原価方法
    gv_cost_analysis_code  := FND_PROFILE.VALUE(cv_cost_analysis_code);  -- XXPO:ロット原価-分析
    gv_org_id              := FND_PROFILE.VALUE(cv_org_id);              -- MO:営業単位
--
    -- =========================================
    -- プロファイルオプション取得エラーチェック
    -- =========================================
    IF (gv_ctpty_inv_rcv_rsn IS NULL) THEN -- XXPO:相手先在庫計上事由プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_ctpty_inv_rcv_rsn)  -- XXPO:相手先在庫計上事由
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_ctpty_cost_rsn IS NULL) THEN -- XXPO:相手先原価計上事由プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_ctpty_cost_rsn)     -- XXPO:相手先原価計上事由
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_purchase_emp_id IS NULL) THEN -- XXPO:購買担当者IDプロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_purchase_emp_id)    -- XXPO:購買担当者ID
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_bill_to_location_id IS NULL) THEN -- XXPO:請求先事業所IDプロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_bill_to_location_id)-- XXPO:請求先事業所ID
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_po_line_type_id IS NULL) THEN -- XXPO:発注明細タイプIDプロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_po_line_type_id)    -- XXPO:発注明細タイプID
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_cmpntcls_code IS NULL) THEN -- XXPO:ロット原価-コンポーネント区分プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_cost_cmpntcls_code) -- XXPO:ロット原価-コンポーネント区分
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_mthd_code IS NULL) THEN -- XXPO:ロット原価-ロット原価方法プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_cost_mthd_code)     -- XXPO:ロット原価-ロット原価方法
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_cost_analysis_code IS NULL) THEN -- XXPO:ロット原価-分析プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_cost_analysis_code) -- XXPO:ロット原価-分析
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (gv_org_id IS NULL) THEN --  MO:営業単位
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_org_id)             --  MO:営業単位
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================
    -- 出来高実績情報インタフェースロック取得
    -- =========================================
    BEGIN
       <<lock_loop>>
      FOR lr_xxpo_vendor_supply_txns_if IN xxpo_vendor_supply_txns_if_cur
      LOOP
        EXIT;
      END LOOP lock_loop;
--
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- モジュール名略称:XXCMN
                         ,gv_msg_xxcmn10019      -- メッセージ:APP-XXCMN-10019 ロックエラー
                         ,gv_tkn_table           -- トークンTABLE
                         ,gv_tkn_vendor_sply_txns_if)    -- テーブル名:出来高実績情報インタフェース
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_data
   * Description      : 取得データチェック処理(B-3)
   ***********************************************************************************/
  PROCEDURE check_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- プログラム名
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
    ln_cnt NUMBER;
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
    -- ===========================
    -- 取引先コードチェック
    -- ===========================
    -- 取引先IDを抽出できていない場合、警告
    IF (gr_main_data.vendor_id IS NULL) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN 共通
                       ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_vendors         -- エラーテーブル名
                       ,gv_tkn_key             -- トークン:KEY
                       ,gv_tkn_vendor_code || gr_main_data.vendor_code)  -- エラーキー項目
                     ,1,5000);
--
      -- 警告ダンプPL/SQL表にダンプをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 工場コードチェック
    -- ===========================
    -- 工場IDを抽出できていない場合、警告
    IF (gr_main_data.factory_id IS NULL) THEN
--
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN 共通
                       ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_vendor_sites    -- エラーテーブル名
                       ,gv_tkn_key             -- トークン:KEY
                       ,gv_tkn_vendor_site_code || gr_main_data.factory_code)  -- エラーキー項目
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 取引先コード＆工場コード妥当性チェック
    -- ===========================
    -- 取引先コードの仕入先IDと、工場コードの仕入先IDが異なる場合、警告
    IF (gr_main_data.vendor_id <> gr_main_data.f_vendor_id) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                     -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10215            -- メッセージ:APP-XXPO-10215 取引先関連チェックエラー
                       ,gv_tkn_token                -- トークン:TOKEN
                       ,gv_tkn_factory_code_name)   -- 工場
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
    END IF;
--
    -- ===========================
    -- 品目コードチェック
    -- ===========================
-- 2008/08/18 H.Itou Mod Start T_S_595
--    -- 品目IDを抽出できていない場合、警告
--    IF (gr_main_data.item_id IS NULL) THEN
    -- 品目IDを抽出できていない場合、または無効の品目、または廃止の品目の場合、警告
    IF((gr_main_data.item_id IS NULL)
    OR (gr_main_data.inactive_ind   = gv_inactive_ind_y)            -- 無効フラグ
    OR (gr_main_data.obsolete_class = gv_obsolete_class_y)) THEN    -- 廃止区分
-- 2008/08/18 H.Itou Add End
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN 共通
                       ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_item_mst        -- エラーテーブル名
                       ,gv_tkn_key             -- トークン:KEY
                       ,gv_tkn_item_code || gr_main_data.item_code)  -- エラーキー項目
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
-- 2008/07/22 H.Itou Add Start
    -- 品目が抽出できて、換算入数がNULLまたは、0以下の場合、警告
    ELSIF ((gr_main_data.conversion_factor IS NULL)
    OR     (gr_main_data.conversion_factor <= 0)) THEN
            -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN 共通
                       ,gv_msg_xxcmn10603)     -- メッセージ:APP-XXCMN-10603 ケース入数エラー
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
-- 2008/07/22 H.Itou Add End
    END IF;
--
--
    -- ===========================
    -- ロット管理品チェック
    -- ===========================
    -- ロット管理区分が1以外の場合、警告
    IF (gr_main_data.lot_ctl <> gv_lot_ctl_y) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10257)      -- メッセージ:APP-XXPO-10257 ロット管理外品エラー
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 処理タイプチェック
    -- ===========================
    -- 処理タイプが1,2以外の場合、警告
    IF (gr_main_data.product_result_type NOT IN(gv_product_result_type_inv, gv_product_result_type_po)) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10226)      -- メッセージ:APP-XXPO-10226 処理タイプエラー
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 出来高数量チェック
    -- ===========================
    -- 0以下は警告
    IF (gr_main_data.producted_quantity <= 0) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                    -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10255           -- メッセージ:APP-XXPO-10255 数値0以下エラー2
                       ,gv_tkn_item                -- トークンITEM
                       ,gv_tkn_producted_qty_name) -- 出来高数量
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
    END IF;
--
    -- 品目区分が5:製品の場合
    IF (gr_main_data.item_class_code = gv_item_class_code_prod) THEN
      -- ===========================
      -- 固有記号チェック必須チェック
      -- ===========================
      IF (gr_main_data.koyu_code IS NULL) THEN
        -- 警告メッセージ出力
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10256       -- メッセージ:APP-XXPO-10256 製品必須エラー
                         ,gv_tkn_item            -- トークンITEM
                         ,gv_tkn_koyu_code_name) -- 固有記号
                       ,1,5000);
--
        -- すでに警告の場合は、ダンプ不要
        IF (ov_retcode <> gv_status_warn) THEN
          -- 警告ダンプPL/SQL表にダンプをセット
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
        END IF;
--
        -- 警告ダンプPL/SQL表に警告メッセージをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
        -- リターン・コードに警告をセット
        ov_retcode := gv_status_warn;
-- 2008/12/02 H.Itou Add Start 本番障害#171
      ELSE
        -- ===========================
        -- 固有記号マスタ存在チェック
        -- ===========================
-- 2009/02/10 v1.7 N.Yoshida Mod Start
--        SELECT COUNT(1) cnt
--        INTO   ln_cnt
--        FROM   xxcmn_lookup_values_v  xlvv            -- クイックコード情報V
--        WHERE  xlvv.lookup_type = gv_plant_uniqe_sign -- タイプ：XXCMN_PLANT_UNIQE_SIGN
--        AND    xlvv.lookup_code = gr_main_data.koyu_code
--        ;
        SELECT COUNT(1) cnt
        INTO   ln_cnt
        FROM   xxpo_price_headers  xph                           -- 仕入･標準単価ヘッダ
        WHERE  xph.item_id             = gr_main_data.item_id    -- 品目ID
        AND    xph.vendor_id           = gr_main_data.vendor_id  -- 取引先ID
        AND    xph.factory_id          = gr_main_data.factory_id -- 工場ID
        AND    xph.koyu_code           = gr_main_data.koyu_code  -- 固有記号
        AND    xph.futai_code          = gv_futai_code_0         -- 付帯コード
        AND    xph.price_type          = gv_price_type_po        -- マスタ区分1:仕入
        AND    xph.supply_to_code      IS NULL                   -- 支給先コード
        AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- 仕入単価導入日タイプが1:製造日の場合、条件が製造日
          AND  (xph.start_date_active <= gr_main_data.producted_date)      -- 適用開始日 <= 製造日
          AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- 適用終了日 >= 製造日
        OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- 仕入単価導入日タイプが2:納入日の場合、条件が生産日
          AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- 適用開始日 <= 生産日
          AND  (xph.end_date_active   >= gr_main_data.manufactured_date))) -- 適用終了日 >= 生産日
        ;
-- 2009/02/10 v1.7 N.Yoshida Mod End
--
        -- マスタに登録がない場合
        IF (ln_cnt = 0) THEN
          -- 警告メッセージ出力
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn               -- モジュール名略称:XXCMN 共通
                           ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                           ,gv_tkn_table           -- トークン:TABLE
                           ,gv_tkn_koyu_code_name  -- エラーテーブル名
                           ,gv_tkn_key             -- トークン:KEY
                           ,gv_tkn_koyu_code || gr_main_data.koyu_code)  -- エラーキー項目
                         ,1,5000);
--
          -- すでに警告の場合は、ダンプ不要
          IF (ov_retcode <> gv_status_warn) THEN
            -- 警告ダンプPL/SQL表にダンプをセット
            gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
            warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
          END IF;
--
          -- 警告ダンプPL/SQL表に警告メッセージをセット
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
          -- リターン・コードに警告をセット
          ov_retcode := gv_status_warn;
        END IF;
-- 2008/12/02 H.Itou Add End
      END IF;
--
-- 2008/12/02 H.Itou Add Start 本番障害#171
    -- 品目区分が5:製品以外の場合で、固有記号に入力がある場合
    ELSIF (gr_main_data.koyu_code IS NOT NULL) THEN
      -- ===========================
      -- 固有記号マスタ存在チェック
      -- ===========================
-- 2009/02/10 v1.7 N.Yoshida Mod Start
--      SELECT COUNT(1) cnt
--      INTO   ln_cnt
--      FROM   xxcmn_lookup_values_v  xlvv            -- クイックコード情報V
--      WHERE  xlvv.lookup_type = gv_plant_uniqe_sign -- タイプ：XXCMN_PLANT_UNIQE_SIGN
--      AND    xlvv.lookup_code = gr_main_data.koyu_code
--      ;
      SELECT COUNT(1) cnt
      INTO   ln_cnt
      FROM   xxpo_price_headers  xph                           -- 仕入･標準単価ヘッダ
      WHERE  xph.item_id             = gr_main_data.item_id    -- 品目ID
      AND    xph.vendor_id           = gr_main_data.vendor_id  -- 取引先ID
      AND    xph.factory_id          = gr_main_data.factory_id -- 工場ID
      AND    xph.koyu_code           = gr_main_data.koyu_code  -- 固有記号
      AND    xph.futai_code          = gv_futai_code_0         -- 付帯コード
      AND    xph.price_type          = gv_price_type_po        -- マスタ区分1:仕入
      AND    xph.supply_to_code      IS NULL                   -- 支給先コード
      AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- 仕入単価導入日タイプが1:製造日の場合、条件が製造日
        AND  (xph.start_date_active <= gr_main_data.producted_date)      -- 適用開始日 <= 製造日
        AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- 適用終了日 >= 製造日
      OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- 仕入単価導入日タイプが2:納入日の場合、条件が生産日
        AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- 適用開始日 <= 生産日
        AND  (xph.end_date_active   >= gr_main_data.manufactured_date))) -- 適用終了日 >= 生産日
      ;
-- 2009/02/10 v1.7 N.Yoshida Mod End
--
      -- マスタに登録がない場合
      IF (ln_cnt = 0) THEN
        -- 警告メッセージ出力
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- モジュール名略称:XXCMN 共通
                         ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                         ,gv_tkn_table           -- トークン:TABLE
                         ,gv_tkn_koyu_code_name  -- エラーテーブル名
                         ,gv_tkn_key             -- トークン:KEY
                         ,gv_tkn_koyu_code || gr_main_data.koyu_code)  -- エラーキー項目
                       ,1,5000);
--
        -- すでに警告の場合は、ダンプ不要
        IF (ov_retcode <> gv_status_warn) THEN
          -- 警告ダンプPL/SQL表にダンプをセット
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
        END IF;
--
        -- 警告ダンプPL/SQL表に警告メッセージをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
        -- リターン・コードに警告をセット
        ov_retcode := gv_status_warn;
      END IF;
-- 2008/12/02 H.Itou Add End
    END IF;
--
-- 2009/03/24 H.Iida Add Start 本番障害#1317対応
    -- ===========================
    -- 生産日未来日チェック
    -- ===========================
    -- 処理タイプが「1：相手先在庫管理」で且つ、生産日が未来日の場合、警告
    IF ((gr_main_data.product_result_type = gv_product_result_type_inv)
      AND (TRUNC(gr_main_data.manufactured_date) > TRUNC(SYSDATE)))
    THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                    -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10288           -- メッセージ:APP-XXPO-10288 未来日エラー
                       ,gv_tkn_item                -- トークン:ITEM
                       ,gv_tkn_manufactured_date)  -- 製造日
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
    END IF;
-- 2009/03/24 H.Iida Add End
--
    -- ===========================
    -- 生産日クローズチェック
    -- ===========================
    -- 生産日の年月が、在庫クローズ年月未満の場合、警告
    IF (TO_CHAR(gr_main_data.manufactured_date, gv_yyyymm) <= xxcmn_common_pkg.get_opminv_close_period) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10119)      -- メッセージ:APP-XXPO-10119 在庫クローズエラー3
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
    END IF;
--
    -- 品目区分が5:製品の場合
    IF (gr_main_data.item_class_code = gv_item_class_code_prod) THEN
      -- ===========================
      --ロットマスタ存在チェック
      -- ===========================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   ic_lots_mst ilm  -- OPMロットマスタ
      WHERE  ilm.attribute1 = TO_CHAR(gr_main_data.producted_date, gv_yyyymmdd)     -- 製造日
      AND    ilm.attribute2 = gr_main_data.koyu_code                                -- 固有記号
      AND    ilm.item_id    = gr_main_data.item_id                                  -- 品目ID
      AND    ROWNUM         = 1
      ;
      -- 1件の場合、警告
      IF (ln_cnt = 1) THEN
        -- 警告メッセージ出力
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10005)     -- メッセージ:APP-XXPO-10005 ロット登録済みエラー
                       ,1,5000);
--
        -- すでに警告の場合は、ダンプ不要
        IF (ov_retcode <> gv_status_warn) THEN
          -- 警告ダンプPL/SQL表にダンプをセット
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := gr_main_data.data_dump;
        END IF;
--
        -- 警告ダンプPL/SQL表に警告メッセージをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
        -- リターン・コードに警告をセット
        ov_retcode := gv_status_warn;
--
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
  END check_data;
--
  /**********************************************************************************
   * Procedure Name   : get_other_data
   * Description      : 関連データ取得処理(B-4)
   ***********************************************************************************/
  PROCEDURE get_other_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_data'; -- プログラム名
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
    -- ===========================
    -- 在庫単価取得
    -- ===========================
    -- 原価管理区分が1:標準原価の場合
    IF (gv_cost_manage_code_h = gr_main_data.cost_manage_code) THEN
      -- 在庫単価はNULL
      gt_stock_value := null;
--
    -- 原価管理区分が0:実際原価の場合
    ELSIF (gv_cost_manage_code_j = gr_main_data.cost_manage_code) THEN
      -- 処理タイプが1:相手先在庫の場合
      IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
        -- 在庫単価は0
        gt_stock_value := 0;
--
      -- 処理タイプが2:即時仕入の場合
      ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
        -- 仕入/標準単価ヘッダから取得
        BEGIN                                                    
          SELECT xph.total_amount    total_amount                  -- 内訳合計
          INTO   gt_stock_value                                 
          FROM   xxpo_price_headers  xph                           -- 仕入･標準単価ヘッダ
          WHERE  xph.item_id             = gr_main_data.item_id    -- 品目ID
          AND    xph.vendor_id           = gr_main_data.vendor_id  -- 取引先ID
          AND    xph.factory_id          = gr_main_data.factory_id -- 工場ID
          AND    xph.futai_code          = gv_futai_code_0         -- 付帯コード
          AND    xph.price_type          = gv_price_type_po        -- マスタ区分1:仕入
          AND    xph.supply_to_code      IS NULL                   -- 支給先コード
          AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- 仕入単価導入日タイプが1:製造日の場合、条件が製造日
            AND  (xph.start_date_active <= gr_main_data.producted_date)      -- 適用開始日 <= 製造日
            AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- 適用終了日 >= 製造日
          OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- 仕入単価導入日タイプが2:納入日の場合、条件が生産日
            AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- 適用開始日 <= 生産日
            AND  (xph.end_date_active   >= gr_main_data.manufactured_date)));-- 適用終了日 >= 生産日
        EXCEPTION
          -- データがない場合は0
          WHEN OTHERS THEN
            gt_stock_value := 0;
        END;
      END IF;
    END IF;
--
    -- 処理タイプが2:即時仕入の場合
    IF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
      -- ===========================
      -- 仕入単価取得
      -- ===========================
      BEGIN
        SELECT xph.total_amount    total_amount                  -- 内訳合計
        INTO   gt_unit_price
        FROM   xxpo_price_headers  xph                           -- 仕入･標準単価ヘッダ
        WHERE  xph.item_id             = gr_main_data.item_id    -- 品目ID
        AND    xph.vendor_id           = gr_main_data.vendor_id  -- 取引先ID
        AND    xph.factory_id          = gr_main_data.factory_id -- 工場ID
        AND    xph.futai_code          = gv_futai_code_0         -- 付帯コード
        AND    xph.price_type          = gv_price_type_po        -- マスタ区分1:仕入
        AND    xph.supply_to_code      IS NULL                   -- 支給先コード
        AND    (((gr_main_data.unit_price_calc_code = gv_unit_price_calc_code_prod)      -- 仕入単価導入日タイプが1:製造日の場合、条件が製造日
          AND  (xph.start_date_active <= gr_main_data.producted_date)      -- 適用開始日 <= 製造日
          AND  (xph.end_date_active   >= gr_main_data.producted_date))     -- 適用終了日 >= 製造日
        OR     ((gr_main_data.unit_price_calc_code  = gv_unit_price_calc_code_loc)       -- 仕入単価導入日タイプが2:納入日の場合、条件が生産日
          AND  (xph.start_date_active <= gr_main_data.manufactured_date)   -- 適用開始日 <= 生産日
          AND  (xph.end_date_active   >= gr_main_data.manufactured_date)));-- 適用終了日 >= 生産日
      EXCEPTION
        -- データがない場合は0
        WHEN OTHERS THEN
          gt_unit_price := 0;
      END;
--
      -- ===========================
      -- 発注番号取得
      -- ===========================
      xxcmn_common_pkg.get_seq_no(
        iv_seq_class  => gv_seq_class_po  -- 採番する番号を表す区分 2:発注番号
       ,ov_seq_no     => gt_po_number     -- 発注番号
       ,ov_errbuf     => lv_errbuf        -- エラーメッセージ
       ,ov_retcode    => lv_retcode       -- リターンコード
       ,ov_errmsg     => lv_errmsg );     -- ユーザー・エラー・メッセージ
--
      -- エラーの場合、処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ===========================
    -- 納入先情報取得取得
    -- ===========================
    SELECT xilv.inventory_location_id location_id           -- 納入先ID(倉庫ID)
          ,xilv.whse_code             whse_code             -- 倉庫コード
          ,xilv.mtl_organization_id   organization_id       -- 在庫組織ID
          ,somb.co_code               co_code               -- 会社コード
          ,somb.orgn_code             orgn_code             -- 組織コード
          ,haou.location_id           ship_to_location_id   -- 納入先事業所ID(事業所ID)
    INTO   gt_location_id
          ,gt_whse_code
          ,gt_organization_id
          ,gt_co_code
          ,gt_orgn_code
          ,gt_ship_to_location_id
    FROM   xxcmn_item_locations_v     xilv                  -- OPM保管場所情報V
          ,ic_whse_mst                iwm                   -- OPM倉庫マスタ
          ,sy_orgn_mst_b              somb                  -- OPMプラントマスタ
          ,hr_all_organization_units  haou                  -- 組織マスタ
    WHERE  xilv.whse_code  = iwm.whse_code                  -- 倉庫コード
    AND    iwm.orgn_code   = somb.orgn_code                 -- プラントコード
    AND    xilv.mtl_organization_id  = haou.organization_id -- 組織ID
    AND    xilv.segment1   = gr_main_data.location_code     -- 納入先コード(保管場所コード)
    AND    haou.date_from <= TRUNC(SYSDATE)                 -- 適用日 <= SYSDATE
    AND  ((haou.date_to   >= TRUNC(SYSDATE))                -- 適用日 >= SYSDATE
      OR  (haou.date_to IS NULL));
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
  END get_other_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_ic_lot_mst
   * Description      : ロットマスタ登録処理(B-5)
   ***********************************************************************************/
  PROCEDURE ins_ic_lot_mst(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ic_lot_mst'; -- プログラム名
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
    ln_api_version_number  CONSTANT NUMBER := 3.0; -- ロット作成API バージョンNo
--
    -- *** ローカル変数 ***
    lv_sublot_no         VARCHAR2(5000);
    lr_lot_in            gmigapi.lot_rec_typ;  -- INロット情報
    lr_lot_out           ic_lots_mst%ROWTYPE;  -- OUTロット情報
    lr_lot_cpg_out       ic_lots_cpg%ROWTYPE;
    lb_setup_return_sts  BOOLEAN;
    ln_msg_count         NUMBER;
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
    -- ===========================
    -- 初期化
    -- ===========================
    lr_lot_in      := NULL;
    lr_lot_out     := NULL;
    lr_lot_cpg_out := NULL;
    FND_MSG_PUB.INITIALIZE(); -- APIメッセージ
--
    -- ===========================
    -- ロットNo取得
    -- ===========================
    GMI_AUTOLOT.GENERATE_LOT_NUMBER(  
      p_item_id        => gr_main_data.item_id  -- IN:品目ID
     ,p_in_lot_no      => NULL
     ,p_orgn_code      => NULL
     ,p_doc_id         => NULL
     ,p_line_id        => NULL
     ,p_doc_type       => NULL
     ,p_out_lot_no     => gt_lot_no    -- OUT:ロット番号
     ,p_sublot_no      => lv_sublot_no -- OUT:サブロット番号
     ,p_return_status  => lv_retcode); -- OUT:リターンコード
--
    -- ロットNoを取得できなかった場合、エラー
    IF (gt_lot_no IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                 -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10110        -- メッセージ:APP-XXPO-10110 ロット採番エラー
                       ,gv_tkn_item_no          -- トークンITEM_NO
                       ,gr_main_data.item_code) -- 品目コード
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- GMI系APIグローバル定数の設定
    -- ===========================
    lb_setup_return_sts  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
--
    -- ===========================
    -- ロット作成API実行
    -- ===========================
    BEGIN
      -- レコードに値をセット
      lr_lot_in.item_no          := gr_main_data.item_code;        -- 品目
      lr_lot_in.lot_no           := gt_lot_no;                     -- ロット番号
      lr_lot_in.lot_created      := SYSDATE;                       -- 作成日
      lr_lot_in.strength         := 100;                           -- 強度
      lr_lot_in.inactive_ind     := 0;                             -- 有効
      lr_lot_in.origination_type := '0';                           -- 元タイプ
      lr_lot_in.attribute1       := TO_CHAR(gr_main_data.producted_date, gv_yyyymmdd);  -- 製造年月日
      lr_lot_in.attribute2       := gr_main_data.koyu_code;        -- 固有記号
      lr_lot_in.attribute3       := TO_CHAR(gr_main_data.expiration_date, gv_yyyymmdd); -- 賞味期限
      lr_lot_in.attribute7       := gt_stock_value;                -- 在庫単価
      lr_lot_in.attribute23      := gr_main_data.lot_status;       -- ロットステータス
      lr_lot_in.attribute8       := gr_main_data.vendor_code;      -- 取引先コード
--
      -- 処理タイプが1:相手先在庫の場合
      IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
        lr_lot_in.attribute24      := insert_kbn_2;                -- 作成区分:2
        lr_lot_in.attribute6       := NULL;                        -- 在庫入数
--
      -- 処理タイプが2:即時仕入の場合
      ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
        lr_lot_in.attribute24      := insert_kbn_3;                -- 作成区分:3
        lr_lot_in.attribute6       := gr_main_data.stock_qty;      -- 在庫入数
      END IF;
--
-- 2008/12/24 v1.5 Y.Yamamoto add start
      lr_lot_in.expaction_date   := TO_DATE('2099/12/31', 'YYYY/MM/DD');
      lr_lot_in.expire_date      := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/24 v1.5 Y.Yamamoto add end
      -- API実行
      GMIPAPI.CREATE_LOT(
        p_api_version      => ln_api_version_number       -- IN:APIのバージョン番号
       ,p_init_msg_list    => FND_API.G_FALSE             -- IN:メッセージ初期化フラグ
       ,p_commit           => FND_API.G_FALSE             -- IN:処理確定フラグ
       ,p_validation_level => FND_API.G_VALID_LEVEL_FULL  -- IN:検証レベル
       ,p_lot_rec          => lr_lot_in                   -- IN:作成するロット情報を指定
       ,x_ic_lots_mst_row  => lr_lot_out                  -- OUT:作成されたロット情報が返却
       ,x_ic_lots_cpg_row  => lr_lot_cpg_out              -- OUT:作成されたロット情報が返却
       ,x_return_status    => lv_retcode                  -- OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
       ,x_msg_count        => ln_msg_count                -- OUT:メッセージ・スタック数
       ,x_msg_data         => lv_errmsg);                 -- OUT:メッセージ
--
      -- 戻り値が正常以外の場合、エラー
      IF (lv_retcode <> gv_api_ret_cd_normal) THEN
        -- エラーログ出力
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     -- エラー・メッセージ
         ,ov_retcode    => lv_retcode    -- リターン・コード
         ,ov_errmsg     => lv_errmsg);   -- ユーザー・エラー・メッセージ
--
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007      -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name      -- トークン
                         ,gv_tkn_ic_lot_mst)    -- OPMロットマスタ
                       ,1,5000);
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007      -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name      -- トークン
                         ,gv_tkn_ic_lot_mst)    -- OPMロットマスタ
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ロットID取得
    gt_lot_id := lr_lot_out.lot_id;
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
  END ins_ic_lot_mst;
--
  /**********************************************************************************
   * Procedure Name   : ins_vendor_suppry_txns
   * Description      : 外注出来高実績(アドオン)登録処理(B-6)
   ***********************************************************************************/
  PROCEDURE ins_vendor_suppry_txns(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vendor_suppry_txns'; -- プログラム名
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
    lr_vendor_supply_txns   xxpo_vendor_supply_txns%ROWTYPE;
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
    -- ===========================
    -- 初期化
    -- ===========================
    lr_vendor_supply_txns := NULL;
--
    -- ===========================
    -- 外注出来高追加処理
    -- ===========================
    BEGIN
      -- レコードに値をセット
      SELECT xxpo_vendor_supply_txns_s1.NEXTVAL
      INTO   gt_txns_id                                                                   -- 実績ID
      FROM   DUAL;
      lr_vendor_supply_txns.txns_id                := gt_txns_id;                         -- 実績ID
      lr_vendor_supply_txns.txns_type              := gr_main_data.product_result_type;   -- 処理タイプ
      lr_vendor_supply_txns.manufactured_date      := gr_main_data.manufactured_date;     -- 生産日
      lr_vendor_supply_txns.vendor_id              := gr_main_data.vendor_id;             -- 取引先ID
      lr_vendor_supply_txns.vendor_code            := gr_main_data.vendor_code;           -- 取引先コード
      lr_vendor_supply_txns.factory_id             := gr_main_data.factory_id;            -- 工場ID
      lr_vendor_supply_txns.factory_code           := gr_main_data.factory_code;          -- 工場コード
      lr_vendor_supply_txns.location_id            := gt_location_id;                     -- 納入先ID
      lr_vendor_supply_txns.location_code          := gr_main_data.location_code;         -- 納入先コード
      lr_vendor_supply_txns.item_id                := gr_main_data.item_id;               -- 品目ID
      lr_vendor_supply_txns.item_code              := gr_main_data.item_code;             -- 品目コード
      lr_vendor_supply_txns.lot_id                 := gt_lot_id;                          -- ロットID
      lr_vendor_supply_txns.lot_number             := gt_lot_no;                          -- ロットNo
      lr_vendor_supply_txns.producted_date         := gr_main_data.producted_date;        -- 製造日
      lr_vendor_supply_txns.koyu_code              := gr_main_data.koyu_code;             -- 固有記号
      lr_vendor_supply_txns.producted_quantity     := gr_main_data.producted_quantity;    -- 出来高数量
      lr_vendor_supply_txns.conversion_factor      := gr_main_data.conversion_factor;     -- 換算入数
      lr_vendor_supply_txns.quantity               := gr_main_data.producted_quantity * 
                                                      gr_main_data.conversion_factor;     -- 数量
      lr_vendor_supply_txns.uom                    := gr_main_data.uom;                   -- 単位コード
      lr_vendor_supply_txns.producted_uom          := gr_main_data.producted_uom;         -- 出来高単位コード
      -- 処理タイプが1:相手先在庫の場合
      IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
        lr_vendor_supply_txns.order_created_flg    := gv_flg_n;                           -- 発注作成フラグ N
        lr_vendor_supply_txns.order_created_date   := NULL;                               -- 発注作成日
  --
      -- 処理タイプが2:即時仕入の場合
      ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
        lr_vendor_supply_txns.order_created_flg    := gv_flg_y;                           -- 発注作成フラグ Y
        lr_vendor_supply_txns.order_created_date   := SYSDATE;                            -- 発注作成日
      END IF;
      lr_vendor_supply_txns.description            := gr_main_data.description;           -- 摘要
      lr_vendor_supply_txns.created_by             := FND_GLOBAL.USER_ID;                 -- 作成者
      lr_vendor_supply_txns.creation_date          := SYSDATE;                            -- 作成日
      lr_vendor_supply_txns.last_updated_by        := FND_GLOBAL.USER_ID;                 -- 最終更新者
      lr_vendor_supply_txns.last_update_date       := SYSDATE;                            -- 最終更新日
      lr_vendor_supply_txns.last_update_login      := FND_GLOBAL.LOGIN_ID;                -- 最終更新ログイン
      lr_vendor_supply_txns.request_id             := FND_GLOBAL.CONC_REQUEST_ID;         -- 要求ID
      lr_vendor_supply_txns.program_application_id := FND_GLOBAL.PROG_APPL_ID;            -- コンカレント・プログラム・アプリケーションID
      lr_vendor_supply_txns.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;         -- コンカレント・プログラムID
      lr_vendor_supply_txns.program_update_date    := SYSDATE;                            -- プログラム更新日
--
      -- 追加処理
      INSERT INTO xxpo_vendor_supply_txns VALUES lr_vendor_supply_txns;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007        -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name        -- トークン
                         ,gv_tkn_vendor_sply_txns)-- 外注出来高実績アドオン
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
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
  END ins_vendor_suppry_txns;
--
  /**********************************************************************************
   * Procedure Name   : ins_inventory_data
   * Description      : 相手先在庫計上処理(B-7)
   ***********************************************************************************/
  PROCEDURE ins_inventory_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inventory_data'; -- プログラム名
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
    ln_api_version_number_adj  CONSTANT NUMBER := 1.0; -- ロット原価作成API用バージョン番号
    ln_api_version_number_inv  CONSTANT NUMBER := 3.0; -- 完了在庫トランザクション作成API用バージョン番号
--
    -- *** ローカル変数 ***
    lr_lc_adjustment_header  GMF_LOTCOSTADJUSTMENT_PUB.LC_ADJUSTMENT_HEADER_REC_TYPE; -- ロット原価ヘッダ
    lr_lc_adjustment_dtls    GMF_LOTCOSTADJUSTMENT_PUB.LC_ADJUSTMENT_DTLS_TBL_TYPE;   -- ロット原価明細
    lb_setup_return_sts      BOOLEAN;
    ln_msg_count             NUMBER;
--
    lr_qty_in                GMIGAPI.qty_rec_typ; -- 完了在庫トランザクション
    ic_jrnl_out              ic_jrnl_mst%ROWTYPE;
    ic_adjs_jnl_out1         ic_adjs_jnl%ROWTYPE;
    ic_adjs_jnl_out2         ic_adjs_jnl%ROWTYPE;
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
    -- ===========================
    -- 初期化
    -- ===========================
    lr_lc_adjustment_header  := NULL; -- ロット原価ヘッダ
    lr_lc_adjustment_dtls(0) := NULL; -- ロット原価明細
    lr_qty_in                := NULL; -- 完了在庫トランザクション
    ic_jrnl_out              := NULL;
    ic_adjs_jnl_out1         := NULL;
    ic_adjs_jnl_out2         := NULL;
    FND_MSG_PUB.INITIALIZE(); -- APIメッセージ
--
    -- ===========================
    -- GMI系APIグローバル定数の設定
    -- ===========================
    lb_setup_return_sts  :=  GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
--
    -- ===========================
    -- ロット原価作成API実行
    -- ===========================
    BEGIN
      -- ロット原価ヘッダレコードに値をセット
      lr_lc_adjustment_header.co_code             := gt_co_code;             -- 会社コード
      lr_lc_adjustment_header.whse_code           := gt_whse_code;           -- 倉庫コード
      lr_lc_adjustment_header.cost_mthd_code      := gv_cost_mthd_code;      -- ロット原価方法
      lr_lc_adjustment_header.item_id             := gr_main_data.item_id;   -- 品目ID
      lr_lc_adjustment_header.lot_id              := gt_lot_id;              -- ロットID
      lr_lc_adjustment_header.reason_code         := gv_ctpty_cost_rsn;      -- 事由コード
      lr_lc_adjustment_header.adjustment_date     := SYSDATE;                -- 調整日
      lr_lc_adjustment_header.delete_mark         := 0;                      -- 削除マーク
      lr_lc_adjustment_header.user_name           := FND_GLOBAL.USER_NAME;   -- ユーザー名
--
      -- ロット原価明細レコードに値をセット
      lr_lc_adjustment_dtls(0).cost_cmpntcls_code := gv_cost_cmpntcls_code;  -- コンポーネント区分
      lr_lc_adjustment_dtls(0).cost_analysis_code := gv_cost_analysis_code;  -- 分析区分
      lr_lc_adjustment_dtls(0).adjustment_cost    := 0;                      -- 原価
--
      -- API実行
      GMF_LOTCOSTADJUSTMENT_PUB.CREATE_LOTCOST_ADJUSTMENT(
         p_api_version      => ln_api_version_number_adj -- IN:APIのバージョン番号
        ,p_init_msg_list    => FND_API.G_FALSE           -- IN:メッセージ初期化フラグ
        ,p_commit           => FND_API.G_FALSE           -- IN:処理確定フラグ
        ,x_return_status    => lv_retcode                -- OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
        ,x_msg_count        => ln_msg_count              -- OUT:メッセージ・スタック数
        ,x_msg_data         => lv_errmsg                 -- OUT:メッセージ
        ,p_header_rec       => lr_lc_adjustment_header   -- IN OUT:登録するロット原価ヘッダ情報を指定、返却
        ,p_dtl_tbl          => lr_lc_adjustment_dtls);   -- IN OUT:登録するロット原価明細情報を指定、返却
--
      -- 戻り値が正常以外の場合、エラー
      IF (lv_retcode <> gv_api_ret_cd_normal) THEN
        -- エラーログ出力
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     -- エラー・メッセージ
         ,ov_retcode    => lv_retcode    -- リターン・コード
         ,ov_errmsg     => lv_errmsg);   -- ユーザー・エラー・メッセージ
--
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007      -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name      -- トークン
                         ,gv_tkn_lc_adjustment) -- ロット原価
                       ,1,5000);
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007      -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name      -- トークン
                         ,gv_tkn_lc_adjustment) -- ロット原価
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- 完了在庫トランザクション作成API実行
    -- =====================================
    BEGIN
      -- 完了在庫トランザクションレコードに値をセット
      lr_qty_in.trans_type     := gv_trans_type_sok;                  -- 取引タイプ 2:即時調整
      lr_qty_in.item_no        := gr_main_data.item_code;             -- 品目
      lr_qty_in.from_whse_code := gt_whse_code;                       -- 倉庫コード
      lr_qty_in.item_um        := gr_main_data.uom;                   -- 単位
      lr_qty_in.lot_no         := gt_lot_no;                          -- ロット
      lr_qty_in.from_location  := gr_main_data.location_code;         -- 納入先コード(保管場所コード)
      lr_qty_in.trans_qty      := gr_main_data.producted_quantity * 
                                  gr_main_data.conversion_factor;     -- 数量
      lr_qty_in.co_code        := gt_co_code;                         -- 会社コード
      lr_qty_in.orgn_code      := gt_orgn_code;                       -- 組織コード
      lr_qty_in.trans_date     := gr_main_data.manufactured_date;     -- 取引日
      lr_qty_in.reason_code    := gv_ctpty_inv_rcv_rsn;               -- 事由コード
      lr_qty_in.user_name      := FND_GLOBAL.USER_NAME;               -- ユーザー名
      lr_qty_in.attribute1     := TO_CHAR(gt_txns_id);                -- ソース文書ID
-- 2008/12/26 H.Itou Add Start 発注(相手先在庫仕入)と区別するため、外注出来高の場合はDFF4にYを立てる。
      lr_qty_in.attribute4     := gv_flg_y;                           -- 
-- 2008/12/26 H.Itou Add End
--
      -- API実行
      GMIPAPI.INVENTORY_POSTING(
         p_api_version      => ln_api_version_number_inv   -- IN:APIのバージョン番号
        ,p_init_msg_list    => FND_API.G_FALSE             -- IN:メッセージ初期化フラグ
        ,p_commit           => FND_API.G_FALSE             -- IN:処理確定フラグ
        ,p_validation_level => FND_API.G_VALID_LEVEL_FULL  -- IN:検証レベル
        ,p_qty_rec          => lr_qty_in                   -- IN:調整する在庫数量情報を指定
        ,x_ic_jrnl_mst_row  => ic_jrnl_out                 -- OUT:調整された在庫数量情報が返却
        ,x_ic_adjs_jnl_row1 => ic_adjs_jnl_out1            -- OUT:調整された在庫数量情報が返却
        ,x_ic_adjs_jnl_row2 => ic_adjs_jnl_out2            -- OUT:
        ,x_return_status    => lv_retcode                  -- OUT:終了ステータス( 'S'-正常終了, 'E'-例外発生, 'U'-システム例外発生)
        ,x_msg_count        => ln_msg_count                -- OUT:メッセージ・スタック数
        ,x_msg_data         => lv_errmsg);                 -- OUT:メッセージ
--
      -- 戻り値が正常以外の場合、エラー
      IF (lv_retcode <> gv_api_ret_cd_normal) THEN
        -- エラーログ出力
        xxcmn_common_pkg.put_api_log(
          ov_errbuf     => lv_errbuf     -- エラー・メッセージ
         ,ov_retcode    => lv_retcode    -- リターン・コード
         ,ov_errmsg     => lv_errmsg);   -- ユーザー・エラー・メッセージ
--
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007      -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name      -- トークン
                         ,gv_tkn_ic_tran_cmp)   -- 在庫取引
                       ,1,5000);
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo               -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007      -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name      -- トークン
                         ,gv_tkn_ic_tran_cmp)   -- 在庫取引
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
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
  END ins_inventory_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_po_data
   * Description      : 発注自動作成処理(B-8)
   ***********************************************************************************/
  PROCEDURE ins_po_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_po_data'; -- プログラム名
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
    lr_xxpo_headers_all      xxpo_headers_all%ROWTYPE;           -- 発注ヘッダ(アドオン)
    lr_po_headers_if         po_headers_interface%ROWTYPE;       -- 発注ヘッダオープンインタフェース
    lr_po_lines_if           po_lines_interface%ROWTYPE;         -- 発注明細オープンインタフェース
    lr_po_distributions_if   po_distributions_interface%ROWTYPE; -- 搬送明細オープンインタフェース
--  2018/02/22 V1.10 Add START
    ln_kobiki_price          NUMBER;                             -- 粉引後単価
    ln_kobiki_amount         NUMBER;                             -- 粉引後金額
--  2018/02/22 V1.10 Add END
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
    -- ===========================
    -- 初期化
    -- ===========================
    lr_xxpo_headers_all    := NULL;
    lr_po_headers_if       := NULL;
    lr_po_lines_if         := NULL;
    lr_po_distributions_if := NULL;
--  2018/02/22 V1.10 Add START
    ln_kobiki_price        := NULL;
    ln_kobiki_amount       := NULL;
--  2018/02/22 V1.10 Add END
--
    -- ===========================
    -- 発注ヘッダ(アドオン)追加
    -- ===========================
    BEGIN
      -- レコードに値をセット
      SELECT xxpo_headers_all_s1.NEXTVAL
      INTO   lr_xxpo_headers_all.xxpo_header_id                                     -- 発注ヘッダ(アドオンID)
      FROM   DUAL;
--
      SELECT papf.employee_number  employee_number
      INTO   lr_xxpo_headers_all.order_created_by_code                              -- 作成者コード
      FROM   per_all_people_f papf
      WHERE  papf.person_id  = TO_NUMBER(gv_purchase_emp_id)
      AND    papf.effective_start_date <= TRUNC(SYSDATE)
      AND    papf.effective_end_date   >= TRUNC(SYSDATE);
--
      lr_xxpo_headers_all.po_header_number       := gt_po_number;                   -- 発注番号
      lr_xxpo_headers_all.order_created_date     := gr_main_data.manufactured_date; -- 作成日
      lr_xxpo_headers_all.order_approved_flg     := gv_flg_n;                       -- 発注承諾フラグ:N
      lr_xxpo_headers_all.purchase_approved_flg  := gv_flg_n;                       -- 仕入承諾フラグ:N
      lr_xxpo_headers_all.created_by             := FND_GLOBAL.USER_ID;             -- 作成者
      lr_xxpo_headers_all.creation_date          := SYSDATE;                        -- 作成日
      lr_xxpo_headers_all.last_updated_by        := FND_GLOBAL.USER_ID;             -- 最終更新者
      lr_xxpo_headers_all.last_update_date       := SYSDATE;                        -- 最終更新日
      lr_xxpo_headers_all.last_update_login      := FND_GLOBAL.LOGIN_ID;            -- 最終更新ログイン
      lr_xxpo_headers_all.request_id             := FND_GLOBAL.CONC_REQUEST_ID;     -- 要求ID
      lr_xxpo_headers_all.program_application_id := FND_GLOBAL.PROG_APPL_ID;        -- コンカレント・プログラム・アプリケーションID
      lr_xxpo_headers_all.program_id             := FND_GLOBAL.CONC_PROGRAM_ID;     -- コンカレント・プログラムID
      lr_xxpo_headers_all.program_update_date    := SYSDATE;                        -- プログラム更新日
--
      -- 追加処理
      INSERT INTO xxpo_headers_all VALUES lr_xxpo_headers_all;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007        -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name        -- トークン
                         ,gv_tkn_xxpo_headers_all)-- 発注ヘッダ(アドオン)
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ======================================
    -- 発注ヘッダオープンインタフェース追加
    -- ======================================
    BEGIN
      -- 発注ヘッダオープンインタフェース
      SELECT po_headers_interface_s.NEXTVAL
      INTO   lr_po_headers_if.interface_header_id                                  -- IFヘッダID
      FROM   DUAL;
      lr_po_headers_if.batch_id                 := TO_CHAR(lr_po_headers_if.interface_header_id) ||
                                                   gt_po_number;                   -- バッチID 
      lr_po_headers_if.process_code             := 'PENDING';                      -- 処理コード
      lr_po_headers_if.action                   := 'ORIGINAL';                     -- 処理
      lr_po_headers_if.org_id                   := gv_org_id;                      -- 営業単位ID
      lr_po_headers_if.document_type_code       := 'STANDARD';                     -- 文書タイプ
      lr_po_headers_if.document_num             := gt_po_number;                   -- 文書番号
      lr_po_headers_if.agent_id                 := gv_purchase_emp_id;             -- 購買担当者ID
      lr_po_headers_if.vendor_id                := gr_main_data.vendor_id;         -- 仕入先ID
      lr_po_headers_if.vendor_site_id           := gr_main_data.factory_id;        -- 仕入先サイトID
      lr_po_headers_if.ship_to_location_id      := gt_ship_to_location_id;         -- 納入先事業所ID
      lr_po_headers_if.bill_to_location_id      := gv_bill_to_location_id;         -- 請求先事業所ID
      lr_po_headers_if.approval_status          := 'APPROVED';                     -- 承認ステータス
      lr_po_headers_if.attribute1               := gv_po_status_m;                 -- ステータス 20:作成済
      lr_po_headers_if.attribute2               := gv_flg_n;                       -- 仕入先承諾要フラグ N
      lr_po_headers_if.attribute4               := TO_CHAR(gr_main_data.manufactured_date, gv_yyyymmdd);  -- 納入日
      lr_po_headers_if.attribute5               := gr_main_data.location_code;     -- 納入先コード
      lr_po_headers_if.attribute6               := gv_direct_flg;                  -- 直送区分 1:通常
      lr_po_headers_if.attribute10              := gr_main_data.department;        -- 部署コード
      lr_po_headers_if.attribute11              := gv_po_kbn;                      -- 発注区分 1:新規
      lr_po_headers_if.load_sourcing_rules_flag := gv_flg_n;                       -- ソースルール作成フラグ N
      lr_po_headers_if.creation_date            := SYSDATE;                        -- 作成日
      lr_po_headers_if.last_updated_by          := FND_GLOBAL.USER_ID;             -- 最終更新者
      lr_po_headers_if.last_update_date         := SYSDATE;                        -- 最終更新日
      lr_po_headers_if.last_update_login        := FND_GLOBAL.LOGIN_ID;            -- 最終更新ログイン
      lr_po_headers_if.request_id               := FND_GLOBAL.CONC_REQUEST_ID;     -- 要求ID
      lr_po_headers_if.program_application_id   := FND_GLOBAL.PROG_APPL_ID;        -- コンカレント・プログラム・アプリケーションID
      lr_po_headers_if.program_id               := FND_GLOBAL.CONC_PROGRAM_ID;     -- コンカレント・プログラムID
      lr_po_headers_if.program_update_date      := SYSDATE;                        -- プログラム更新日
--
      -- 追加処理
      INSERT INTO po_headers_interface VALUES lr_po_headers_if;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007        -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name        -- トークン
                         ,gv_tkn_po_headers_if)   -- 発注ヘッダオープンインタフェース
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ======================================
    -- 発注明細オープンインタフェース追加
    -- ======================================
    BEGIN
--  2018/02/22 V1.10 Add START
      -- 粉引後単価・粉引後金額の算出
      ln_kobiki_price  := gt_unit_price  * (100 - 0) / 100;
      ln_kobiki_amount := ln_kobiki_price * ( gr_main_data.producted_quantity * gr_main_data.conversion_factor );  -- 粉引後単価×(出来高数量×換算入数)
--  2018/02/22 V1.10 Add END
      -- レコードに値をセット
      SELECT po_lines_interface_s.NEXTVAL
      INTO   lr_po_lines_if.interface_line_id                                         -- IF明細ID
      FROM   DUAL;
      lr_po_lines_if.interface_header_id     := lr_po_headers_if.interface_header_id; -- IFヘッダID
      lr_po_lines_if.line_num                := 1;                                    -- 明細番号
      lr_po_lines_if.shipment_num            := 1;                                    -- 納入番号
      lr_po_lines_if.line_type_id            := gv_po_line_type_id;                   -- 明細タイプID
      lr_po_lines_if.item_id                 := gr_main_data.inventory_item_id;       -- 品目ID
      lr_po_lines_if.uom_code                := gr_main_data.uom;                     -- 単位コード
      lr_po_lines_if.quantity                := gr_main_data.producted_quantity *
                                                gr_main_data.conversion_factor;       -- 出来高数量× 換算入数
      lr_po_lines_if.unit_price              := gt_unit_price;                        -- 価格
      lr_po_lines_if.promised_date           := gr_main_data.manufactured_date;       -- 納入日
      lr_po_lines_if.line_attribute1         := gt_lot_no;                            -- ロット番号
      lr_po_lines_if.line_attribute2         := gr_main_data.factory_code;            -- 工場コード
      lr_po_lines_if.line_attribute3         := gv_futai_code_0;                      -- 付帯コード
      lr_po_lines_if.line_attribute4         := gr_main_data.stock_qty;               -- 在庫入数
      lr_po_lines_if.line_attribute8         := gt_unit_price;                        -- 仕入単価
      lr_po_lines_if.line_attribute10        := gr_main_data.producted_uom;           -- 発注単位
      lr_po_lines_if.line_attribute11        := gr_main_data.producted_quantity;      -- 出来高数量
      lr_po_lines_if.line_attribute13        := gv_flg_n;                             -- 数量確定フラグ
      lr_po_lines_if.line_attribute14        := gv_flg_n;                             -- 金額確定フラグ
--  2018/02/22 V1.10 Add START
      lr_po_lines_if.shipment_attribute2     := ln_kobiki_price;                      -- 粉引後単価
--  2018/02/22 V1.10 Add END
      lr_po_lines_if.shipment_attribute3     := gv_kosen_kbn_n;                       -- 口銭区分
      lr_po_lines_if.shipment_attribute6     := gv_fuka_kbn_n;                        -- 賦課金区分
--  2018/02/22 V1.10 Add START
      lr_po_lines_if.shipment_attribute9     := ln_kobiki_amount;                     -- 粉引後金額
--  2018/02/22 V1.10 Add END
      lr_po_lines_if.ship_to_organization_id := gt_organization_id;                   -- 在庫組織ID(入庫)
      lr_po_lines_if.creation_date           := SYSDATE;                              -- 作成日
      lr_po_lines_if.last_updated_by         := FND_GLOBAL.USER_ID;                   -- 最終更新者
      lr_po_lines_if.last_update_date        := SYSDATE;                              -- 最終更新日
      lr_po_lines_if.last_update_login       := FND_GLOBAL.LOGIN_ID;                  -- 最終更新ログイン
      lr_po_lines_if.request_id              := FND_GLOBAL.CONC_REQUEST_ID;           -- 要求ID
      lr_po_lines_if.program_application_id  := FND_GLOBAL.PROG_APPL_ID;              -- コンカレント・プログラム・アプリケーションID
      lr_po_lines_if.program_id              := FND_GLOBAL.CONC_PROGRAM_ID;           -- コンカレント・プログラムID
      lr_po_lines_if.program_update_date     := SYSDATE;                              -- プログラム更新日
--
      -- 追加処理
      INSERT INTO po_lines_interface VALUES lr_po_lines_if;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                 -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007        -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name        -- トークン
                         ,gv_tkn_po_lines_if)     -- 発注明細オープンインタフェース
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- ======================================
    -- 搬送明細オープンインタフェース追加
    -- ======================================
    BEGIN
      -- レコードに値をセット
      SELECT po_distributions_interface_s.NEXTVAL
      INTO   lr_po_distributions_if.interface_distribution_id                                   -- IF搬送明細ID
      FROM   DUAL;
      lr_po_distributions_if.interface_header_id       := lr_po_headers_if.interface_header_id; -- IFヘッダID
      lr_po_distributions_if.interface_line_id         := lr_po_lines_if.interface_line_id;     -- IF明細ID
      lr_po_distributions_if.distribution_num          := 1;                                    -- 明細番号
      lr_po_distributions_if.quantity_ordered          := gr_main_data.producted_quantity *
                                                          gr_main_data.conversion_factor;       -- 出来高数量× 換算入数
      lr_po_distributions_if.recovery_rate             := 100;
      lr_po_distributions_if.creation_date             := SYSDATE;                              -- 作成日
      lr_po_distributions_if.last_updated_by           := FND_GLOBAL.USER_ID;                   -- 最終更新者
      lr_po_distributions_if.last_update_date          := SYSDATE;                              -- 最終更新日
      lr_po_distributions_if.last_update_login         := FND_GLOBAL.LOGIN_ID;                  -- 最終更新ログイン
      lr_po_distributions_if.request_id                := FND_GLOBAL.CONC_REQUEST_ID;           -- 要求ID
      lr_po_distributions_if.program_application_id    := FND_GLOBAL.PROG_APPL_ID;              -- コンカレント・プログラム・アプリケーションID
      lr_po_distributions_if.program_id                := FND_GLOBAL.CONC_PROGRAM_ID;           -- コンカレント・プログラムID
      lr_po_distributions_if.program_update_date       := SYSDATE;                              -- プログラム更新日
--
      -- 追加処理
      INSERT INTO po_distributions_interface VALUES lr_po_distributions_if;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                     -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10007            -- メッセージ:APP-XXPO-10007 データ登録エラー
                         ,gv_tkn_info_name            -- トークン
                         ,gv_tkn_po_distributions_if) -- 搬送明細オープンインタフェース
                       ,1,5000);
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- バッチIDをセット
    gt_batch_id := lr_po_headers_if.batch_id;
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
  END ins_po_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_qt_inspection
   * Description      : 品質検査依頼情報作成処理(B-9)
   ***********************************************************************************/
  PROCEDURE ins_qt_inspection(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_qt_inspection'; -- プログラム名
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
    lt_division            xxwip_qt_inspection.division%TYPE;         -- 区分
    lt_qty                 xxwip_qt_inspection.qty%TYPE;              -- 数量
    lt_prod_dely_date      xxwip_qt_inspection.prod_dely_date%TYPE;   -- 納入日
    lt_vendor_line         xxwip_qt_inspection.vendor_line%TYPE;      -- 仕入先コード
    lt_qt_inspect_req_no   xxwip_qt_inspection.qt_inspect_req_no%TYPE;-- 検査依頼No
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
    -- ===========================
    -- レコードに値をセット
    -- ===========================
     -- 処理タイプが1:相手先在庫の場合
    IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
      lt_division       := gt_division_spl; -- 区分 4:外注出来高
-- 2009/03/13 H.Itou Mod Start 本番障害#32 外注出来高も数量をパラメータで渡すように変更
--      lt_qty            := NULL;            -- 数量 NULL
      lt_qty            := gr_main_data.producted_quantity *
                           gr_main_data.conversion_factor;     -- 数量 出来高数量× 換算入数
-- 2009/03/13 H.Itou Mod End
      lt_prod_dely_date := NULL;            -- 生産日 NULL
      lt_vendor_line    := NULL;            -- 仕入先コード NULL
--
    -- 処理タイプが2:即時仕入の場合
    ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
      lt_division       := gt_division_po;                     -- 区分 2:発注
      lt_qty            := gr_main_data.producted_quantity *
                           gr_main_data.conversion_factor;     -- 数量 出来高数量× 換算入数
      lt_prod_dely_date := gr_main_data.manufactured_date;     -- 納入日 生産日
      lt_vendor_line    := gr_main_data.vendor_code;           -- 仕入先コード 取引先コード
    END IF;
--
    -- ===========================
    -- 品質検査依頼情報作成API実行
    -- ===========================
    xxwip_common_pkg.make_qt_inspection(
      it_division          => lt_division           -- IN  区分         必須（1:生産 2:発注 3:ロット情報 4:外注出来高 5:荒茶製造）
     ,iv_disposal_div      => gv_disposal_div_ins   -- IN  処理区分     必須（1:追加 2:更新 3:削除）
     ,it_lot_id            => gt_lot_id             -- IN  ロットID     必須
     ,it_item_id           => gr_main_data.item_id  -- IN  品目ID       必須
     ,iv_qt_object         => NULL                  -- IN  対象先       区分:5のみ必須（1:荒茶品目 2:副産物１ 3:副産物２ 4:副産物３）
     ,it_batch_id          => NULL                  -- IN  生産バッチID 処理区分3以外かつ区分:1のみ必須
     ,it_batch_po_id       => NULL                  -- IN  明細番号     常にNULL
     ,it_qty               => lt_qty                -- IN  数量         処理区分3以外かつ区分:2のみ必須
     ,it_prod_dely_date    => lt_prod_dely_date     -- IN  納入日       処理区分3以外かつ区分:2のみ必須
     ,it_vendor_line       => lt_vendor_line        -- IN  仕入先コード 処理区分3以外かつ区分:2のみ必須
     ,it_qt_inspect_req_no => NULL                  -- IN  検査依頼No   処理区分:2、3のみ必須
     ,ot_qt_inspect_req_no => lt_qt_inspect_req_no  -- OUT 検査依頼No
     ,ov_errbuf            => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg            => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 戻り値がエラー終了の場合、エラー
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                     -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10007            -- メッセージ:APP-XXPO-10007 データ登録エラー
                       ,gv_tkn_info_name            -- トークン
                       ,gv_tkn_qt_inspection)       -- 品質検査依頼情報
                     ,1,5000);
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
  END ins_qt_inspection;
--
  /**********************************************************************************
   * Procedure Name   : import_standard_po
   * Description      : 標準発注インポートの呼出処理(B-10)
   ***********************************************************************************/
  PROCEDURE import_standard_po(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'import_standard_po'; -- プログラム名
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
    ln_request_id NUMBER;
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
    -- ===========================
    -- 標準発注インポートの発行
    -- ===========================
    -- 標準発注インポート(コンカレント)呼び出し
    ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                       application  => 'PO'                           -- アプリケーション名
                      ,program      => 'POXPOPDOI'                    -- プログラム短縮名
                      ,argument1    => NULL                           -- 購買担当ID
                      ,argument2    => 'STANDARD'                     -- 文書タイプ
                      ,argument3    => NULL                           -- 文書サブタイプ
                      ,argument4    => 'N'                            -- 品目の作成 N:行わない
                      ,argument5    => NULL                           -- ソース・ルールの作成
                      ,argument6    => 'APPROVED'                     -- 承認ステータス APPROVAL:承認
                      ,argument7    => NULL                           -- リリース生成方法
                      ,argument8    => gt_batch_id                    -- バッチID = IFヘッダID || 発注番号
                      ,argument9    => NULL                           -- 営業単位
                      ,argument10   => NULL);                         -- グローバル契約
--
    -- 要求IDを取得できない場合、エラー
    IF (ln_request_id <= 0) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10025      -- メッセージ:APP-XXPO-10025 コンカレント登録エラー
                       ,gv_tkn_prg_name       -- トークン
                       ,gv_tkn_conc_name)     -- 標準発注インポート
                     ,1,5000);
      lv_errmsg := lv_errbuf;
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
  END import_standard_po;
--
  /**********************************************************************************
   * Procedure Name   : del_vendor_supply_txns_if
   * Description      : データ削除処理(B-11)
   ***********************************************************************************/
  PROCEDURE del_vendor_supply_txns_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_vendor_supply_txns_if'; -- プログラム名
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
    FORALL ln_count IN 1..txns_if_id_tab.COUNT
      DELETE xxpo_vendor_supply_txns_if xvsti      -- 出来高実績情報インタフェース
      WHERE  xvsti.txns_if_id = txns_if_id_tab(ln_count);
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
  END del_vendor_supply_txns_if;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : データダンプ一括出力処理(B-12)
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- プログラム名
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
    lv_msg  VARCHAR2(5000);  -- メッセージ
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
    -- ===============================
    -- データダンプ一括出力
    -- ===============================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 成功データ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00005)     -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 正常データダンプ
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- スキップデータデータ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00007)     -- メッセージ：APP-XXCMN-00007 スキップデータ（見出し）
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 警告データダンプ
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
  END put_dump_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2,     --   ユーザー・エラー・メッセージ --# 固定 #
    iv_data_class             IN  VARCHAR2,  --   データ種別(DEFAULT:出来高実績)
    iv_vendor_code            IN  VARCHAR2,  --   取引先
    iv_factory_code           IN  VARCHAR2,  --   工場
    iv_manufactured_date_from IN  VARCHAR2,  --   生産日FROM
    iv_manufactured_date_to   IN  VARCHAR2,  --   生産日TO
    iv_security_kbn           IN  VARCHAR2)  --   セキュリティ区分(DEFAULT「1:伊藤園ユーザータイプ」)
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
    lv_msg         VARCHAR2(5000); -- パラメータ出力用
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
    gn_target_cnt          := 0;
    gn_normal_cnt          := 0;
    gn_error_cnt           := 0;
    gn_warn_cnt            := 0;
    gn_warn_msg_cnt        := 0;
    gn_po_cnt              := 0;
    gt_stock_value         := NULL;
    gt_unit_price          := NULL;
    gt_po_number           := NULL;
    gt_location_id         := NULL;
    gt_whse_code           := NULL;
    gt_organization_id     := NULL;
    gt_co_code             := NULL;
    gt_orgn_code           := NULL;
    gt_ship_to_location_id := NULL;
    gt_lot_no              := NULL;
    gt_lot_id              := NULL;
    gt_txns_id             := NULL;
    gt_batch_id            := NULL;
--
    -- 入力パラメータ取得
    gv_in_data_class             := iv_data_class;              -- データ種別
    gv_in_vendor_code            := iv_vendor_code;             -- 取引先
    gv_in_factory_code           := iv_factory_code;            -- 工場
    gv_in_manufactured_date_from := iv_manufactured_date_from;  -- 生産日FROM
    gv_in_manufactured_date_to   := iv_manufactured_date_to;    -- 生産日TO
    gv_in_security_kbn           := iv_security_kbn;            -- セキュリティ区分
--
    -- ===============================
    -- 入力パラメータ出力
    -- ===============================
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 入力パラメータ(見出し)
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxpo              -- モジュール名略称：XXPO
                  ,gv_msg_xxpo30051)    -- メッセージ:APP-XXPO-30051 入力パラメータ(見出し)
                ,1,5000);
--
    -- 入力パラメータ見出し出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 入力パラメータ(カンマ区切り)
    lv_msg := gv_in_data_class             || gv_msg_comma || -- データ種別
              gv_in_vendor_code            || gv_msg_comma || -- 取引先
              gv_in_factory_code           || gv_msg_comma || -- 工場
              gv_in_manufactured_date_from || gv_msg_comma || -- 生産日FROM
              gv_in_manufactured_date_to   || gv_msg_comma || -- 生産日TO
              gv_in_security_kbn;                             -- セキュリティ区分
--
    -- 入力パラメータ出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- =========================================
    -- 初期処理(B-1)
    -- =========================================
    init_proc(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 対象データ取得処理(B-2)
    -- =========================================
    OPEN main_cur;
    FETCH main_cur INTO gr_main_data;
--
    WHILE (main_cur%FOUND)
    LOOP
      -- 処理件数カウント
      gn_target_cnt := gn_target_cnt + 1 ;
      -- 出来高実績情報インタフェースID PL/SQL表にIDをセット
      txns_if_id_tab(gn_target_cnt) := gr_main_data.txns_if_id;
--
      -- =========================================
      -- 取得データチェック処理(B-3)
      -- =========================================
      check_data(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合、出来高実績インタフェースを削除し、処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- リターン・コード 警告をセット
        ov_retcode := gv_status_warn;
        -- スキップ件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- 正常の場合
      ELSE
        -- =========================================
        -- 関連データ取得処理(B-4)
        -- =========================================
        get_other_data(
          ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合、出来高実績インタフェースを削除し、処理終了
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- =========================================
        -- ロットマスタ登録処理(B-5)
        -- =========================================
        ins_ic_lot_mst(
          ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合、出来高実績インタフェースを削除し、処理終了
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- =========================================
        -- 外注出来高(アドオン)登録処理(B-6)
        -- =========================================
        ins_vendor_suppry_txns(
          ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合、出来高実績インタフェースを削除し、処理終了
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- 処理タイプが1:相手先在庫の場合
        IF (gv_product_result_type_inv = gr_main_data.product_result_type) THEN
          -- =========================================
          -- 相手先在庫計上処理(B-7)
          -- =========================================
          ins_inventory_data(
            ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合、出来高実績インタフェースを削除し、処理終了
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
--
        -- 処理タイプが2:即時仕入の場合
        ELSIF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
          -- =========================================
          -- 発注自動作成処理(B-8)
          -- =========================================
          ins_po_data(
            ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合、出来高実績インタフェースを削除し、処理終了
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- 試験有無区分が1:有の場合
        IF (gv_test_code_y = gr_main_data.test_code) THEN
          -- =========================================
          -- 品質検査依頼情報作成処理(B-9)
          -- =========================================
          ins_qt_inspection(
            ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合、出来高実績インタフェースを削除し、処理終了
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- 処理タイプが2:即時仕入の場合
        IF (gv_product_result_type_po = gr_main_data.product_result_type) THEN
          -- =========================================
          -- 標準発注インポートの呼出処理(B-10)
          -- =========================================
          import_standard_po(
            ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合、出来高実績インタフェースを削除し、処理終了
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- 正常データダンプPL/SQL表投入
        gn_normal_cnt := gn_normal_cnt + 1;
        normal_dump_tab(gn_normal_cnt) := gr_main_data.data_dump;
--
      END IF;
--
      FETCH main_cur INTO gr_main_data;
--
    END LOOP;
--
    -- 2008/07/08 Add ↓
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/08 Add ↑
--
    -- =========================================
    -- データ削除処理(B-11)
    -- =========================================
    del_vendor_supply_txns_if(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- データダンプ一括出力処理(B-12)
    -- =========================================
    put_dump_msg(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
    -- エラーが発生し、インタフェースデータを削除する場合
    WHEN proc_err_expt THEN
--
      ROLLBACK; -- ロールバック
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
      -- =========================================
      -- データ削除処理(B-11)
      -- =========================================
      del_vendor_supply_txns_if(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> gv_status_error) THEN
        COMMIT;
      END IF;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_data_class             IN  VARCHAR2,   --   データ種別
    iv_vendor_code            IN  VARCHAR2,   --   取引先
    iv_factory_code           IN  VARCHAR2,   --   工場
    iv_manufactured_date_from IN  VARCHAR2,   --   生産日FROM
    iv_manufactured_date_to   IN  VARCHAR2,   --   生産日TO
    iv_security_kbn           IN  VARCHAR2    --   セキュリティ区分
  )
--
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
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg,   -- ユーザー・エラー・メッセージ --# 固定 #
      iv_data_class,              --   データ種別
      iv_vendor_code,             --   取引先
      iv_factory_code,            --   工場
      iv_manufactured_date_from,  --   生産日FROM
      iv_manufactured_date_to,    --   生産日TO
      iv_security_kbn             --   セキュリティ区分
      );
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
--###########################  固定部 END   #######################################################
--
END xxpo940002c;
/

