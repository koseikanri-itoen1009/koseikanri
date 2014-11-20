CREATE OR REPLACE PACKAGE BODY XXCOI003A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A15C(body)
 * Description      : 保管場所転送取引データOIF更新(基準在庫)
 * MD.050           : 保管場所転送取引データOIF更新(基準在庫) MD050_COI_003_A15
 * Version          : 1.5
 *
 * Program List
 * ---------------------------  ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------  ----------------------------------------------------------
 *  init                         初期処理                                    (A-1)
 *  chk_vd_column_mst_info       基準在庫変更データ妥当性チェック            (A-3)
 *  ins_tmp_svd_tran_date        基準在庫変更ワークテーブルの追加            (A-4)
 *  upd_xxcoi_mst_vd_column      VDコラムマスタの更新                        (A-5)
 *  upd_hht_inv_transactions     HHT入出庫一時表の処理ステータス更新         (A-6)
 *  ins_standard_inv_err_list    基準在庫変更データのエラーリスト表追加      (A-7)
 *  del_hht_inv_transactions     HHT入出庫一時表のエラーレコード削除         (A-8)
 *  ins_mtl_transactions_if      基準在庫変更データの資材取引OIF追加         (A-9)
 *  ins_vd_column                VDコラムマスタの登録                        (A-12)
 *  chk_new_vd_data              新規ベンダ基準在庫妥当性チェック            (A-14)
 *  put_warning_msg              エラー情報編集処理                          (A-15)
 *  new_vd_column_create         新規ベンダ基準在庫
 *                                    コラム上限値チェック                   (A-11)
 *                                    登録コラム情報初期化                   (A-13)
 *  submain                      メイン処理プロシージャ                      (A-2)
 *  main                         コンカレント実行ファイル登録プロシージャ    (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2009/01/14    1.0   SCS H.Wada       main新規作成
 *  2009/02/19    1.1   SCS H.Wada       障害番号 #015
 *  2009/04/06    1.2   SCS T.Nakamura   障害番号 T1_0004
 *                                         VDコラムマスタの更新処理の修正
 *  2009/12/15    1.3   SCS N.Abe        [E_本稼動_00402]VDコラムマスタ更新処理の修正
 *  2010/04/19    1.4   SCS H.Sasaki     [E_本稼動_06588]HHTからのVDコラムマスタ登録
 *  2011/12/07    1.5   SCSK K.Nakamura  [E_本稼動_08842]同一顧客で伝票日付が不一致の場合のエラー処理追加
 *                                       [E_本稼動_08843]VDコラムマスタ存在チェックフラグの初期化を修正
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lock_expt            EXCEPTION;                           -- ロック取得エラー
  chk_err_expt         EXCEPTION;                           -- 妥当性チェックエラー
  PRAGMA               EXCEPTION_INIT( lock_expt, -54 );    -- ロックエラー例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI003A15C'; -- パッケージ名
--
-- == 2011/04/19 V1.4 Added START ===============================================================
  cv_prf_max_column_no  CONSTANT VARCHAR2(30) :=  'XXCOI1_MAX_COLUMN_NO';     --  XXCOI:登録コラム上限値
  cv_prf_default_rack   CONSTANT VARCHAR2(30) :=  'XXCOI1_DEFAULT_RACK';      --  XXCOI:ラック数初期値
  cv_hht_program_div_6  CONSTANT VARCHAR2(1)  :=  '6';                        --  入出庫ジャーナル処理区分（新規ベンダ基準在庫）
  cv_day_form_m         CONSTANT VARCHAR2(6)  :=  'YYYYMM';                   --  日付型(年月)
  cv_month_type_0       CONSTANT VARCHAR2(1)  :=  '0';                        --  月区分（前月）
  cv_month_type_1       CONSTANT VARCHAR2(1)  :=  '1';                        --  月区分（当月）
  cv_dummy_value        CONSTANT VARCHAR2(11) :=  'dummy_value';              --  NVL用ダミー値
  cv_inst_type_1        CONSTANT VARCHAR2(1)  :=  '1';                        --  機器区分（自販機）
  cv_yes                CONSTANT VARCHAR2(1)  :=  'Y';                        --  固定値 Y
-- == 2011/04/19 V1.4 Added END   ===============================================================
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- アプリケーション短縮名
  gv_msg_kbn_ccp       CONSTANT VARCHAR2(5)   := 'XXCCP';
  gv_msg_kbn_coi       CONSTANT VARCHAR2(5)   := 'XXCOI';
--
  -- メッセージ番号
  gv_msg_ccp_90008     CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  gv_msg_coi_00005     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00005'; -- 在庫組織コード取得エラーメッセージ
  gv_msg_coi_00006     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  gv_msg_coi_00008     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00008'; -- 対象データ無しメッセージ
  gv_msg_coi_00011     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  gv_msg_coi_00012     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00012'; -- 取引タイプID取得エラーメッセージ
  gv_msg_coi_10027     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10027'; -- データ名称取得エラーメッセージ
  gv_msg_coi_10055     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10055'; -- ロックエラーメッセージ(HHT入出庫一時表)
  gv_msg_coi_10056     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10056'; -- 基準在庫更新（品目不一致）エラー
  gv_msg_coi_10057     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10057'; -- 基準在庫更新（基準在庫不整合）エラー
  gv_msg_coi_10058     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10058'; -- 基準在庫更新（品目・基準在庫更新不可）エラー
  gv_msg_coi_10059     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10059'; -- 基準在庫更新（単価不整合）エラー
  gv_msg_coi_10062     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10062'; -- 基準在庫更新（前月当月不一致）エラー
  gv_msg_coi_10241     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10241'; -- 取引タイプ名取得エラーメッセージ
  gv_msg_coi_10024     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10024'; -- ロックエラーメッセージ(VDコラムマスタ)
  gv_msg_coi_10335     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10335'; -- 取引作成件数メッセージ
  gv_msg_coi_10342     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10342'; -- HHT入出庫データ用KEY情報
  gv_msg_coi_10353     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10353'; -- 基準在庫更新（単価未設定エラー）エラー
  gv_msg_coi_10354     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10354'; -- 基準在庫更新（H/C未設定エラー）エラー
  gv_msg_coi_10359     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10359'; -- 対象データ無しメッセージ（VDコラムマスタ）
-- Add 2009/02/18 #015 ↓
  gv_msg_coi_10371     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10371'; -- 基準在庫更新（基準在庫上限値）エラー
  gv_mst_coi_10372     CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10372'; -- 基準在庫更新（基準在庫少数点）エラー
-- Add 2009/02/18 #015 ↑
-- == 2011/04/19 V1.4 Added START ===============================================================
  cv_msg_coi_00032      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00032';       --  プロファイル値取得エラー
  cv_msg_coi_10430      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10430';       --  VDコラム登録済みエラーメッセージ
  cv_msg_coi_10431      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10431';       --  基準在庫更新（コラム上限値）エラー
  cv_msg_coi_10432      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10432';       --  基準在庫更新（顧客情報未取得）エラー
  cv_msg_coi_10433      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10433';       --  メッセージヘッダ（ベンダ初回）
  cv_msg_coi_10434      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10434';       --  メッセージヘッダ（新規ベンダ基準在庫）
  cv_msg_coi_10435      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10435';       --  基準在庫更新（顧客移行）エラー
  cv_msg_coi_10436      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10436';       --  新規ベンダ基準在庫コラム重複
-- == 2011/04/19 V1.4 Added END   ===============================================================
-- == 2011/12/07 V1.5 Added START ===============================================================
  cv_msg_coi_10449      CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10449';       --  新規ベンダ基準在庫コラム登録日不一致
-- == 2011/12/07 V1.5 Added END   ===============================================================
--
  -- トークン
  gv_tkn_pro_tok       CONSTANT VARCHAR2(7)   := 'PRO_TOK';              -- プロファイル名
  gv_tkn_column_no     CONSTANT VARCHAR2(9)   := 'COLUMN_NO';            -- コラム№
  gv_tkn_item_code     CONSTANT VARCHAR2(9)   := 'ITEM_CODE';            -- 品目コード
  gv_tkn_base_code     CONSTANT VARCHAR2(9)   := 'BASE_CODE';            -- 拠点コード
  gv_tkn_dept_flag     CONSTANT VARCHAR2(9)   := 'DEPT_FLAG';            -- 百貨店フラグ
-- Add 2009/02/18 #015 ↓
  gv_tkn_total_qnt     CONSTANT VARCHAR2(9)   := 'TOTAL_QNT';            -- 総数量
-- Add 2009/02/18 #015 ↑
  gv_tkn_unit_price    CONSTANT VARCHAR2(10)  := 'UNIT_PRICE';           -- 単価
  gv_tkn_invoice_no    CONSTANT VARCHAR2(10)  := 'INVOICE_NO';           -- 伝票№
  gv_tkn_lookup_type   CONSTANT VARCHAR2(11)  := 'LOOKUP_TYPE';          -- 参照タイプ
  gv_tkn_lookup_code   CONSTANT VARCHAR2(11)  := 'LOOKUP_CODE';          -- 参照コード
  gv_tkn_record_type   CONSTANT VARCHAR2(11)  := 'RECORD_TYPE';          -- レコード種別
  gv_tkn_org_code_tok  CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';         -- 在庫組織コード
  gv_tkn_invoice_type  CONSTANT VARCHAR2(12)  := 'INVOICE_TYPE';         -- 伝票区分
  gv_tkn_tran_type_tok CONSTANT VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK'; -- 取引タイプ名
-- == 2011/04/19 V1.4 Added START ===============================================================
  cv_tkn_cust_code      CONSTANT VARCHAR2(30) :=  'CUSTOMER_CODE';        --  顧客コード
  cv_tkn_max_column     CONSTANT VARCHAR2(30) :=  'MAX_COLUMN';           --  コラム上限値
-- == 2011/04/19 V1.4 Added END   ===============================================================
--
  gv_pro_div_chg_inv   CONSTANT VARCHAR2(1)   := '1';                    -- 入出庫ジャーナル処理区分(基準在庫変更)
  gn_xhit_status_0     CONSTANT NUMBER        := 0;                      -- HHT入出庫一時表ステータス 0(未処理)
  gv_vd_get_lock       CONSTANT VARCHAR2(1)   := 'Y';                    -- VDコラムマスタロック取得成功
  gv_vd_miss_lock      CONSTANT VARCHAR2(1)   := 'N';                    -- VDコラムマスタロック取得失敗
-- == 2011/04/19 V1.4 Added START ===============================================================
  gb_customer_chk       BOOLEAN;                                          --  顧客情報存在チェックフラグ
  gb_vd_column_chk      BOOLEAN;                                          --  VDコラムマスタ存在チェックフラグ
  gb_sale_base_chk      BOOLEAN;                                          --  前月当月売上拠点チェックフラグ
  gb_cust_grp_chk       BOOLEAN;                                          --  顧客内有効データ有無フラグ
  gn_target_cnt2        NUMBER;                                           --  対象件数（新規ベンダ基準在庫用）
  gn_normal_cnt2        NUMBER;                                           --  正常件数（新規ベンダ基準在庫用）
  gn_warn_cnt2          NUMBER;                                           --  スキップ件数（新規ベンダ基準在庫用）
  gt_max_column_no      xxcoi_mst_vd_column.column_no%TYPE;               --  コラムNo上限値
  gt_default_rack       xxcoi_mst_vd_column.rack_quantity%TYPE;           --  ラック数初期値
  gv_ins_vd_type        VARCHAR2(1);                                      --  当月前月区分
-- == 2011/04/19 V1.4 Added END   ===============================================================
-- == 2011/12/07 V1.5 Added START ===============================================================
  gb_cust_date_chk      BOOLEAN;                                          --  顧客内伝票日付不一致チェックフラグ
-- == 2011/12/07 V1.5 Added END   ===============================================================
--
  -- VDコラムマスタ情報レコード型
  TYPE gr_mst_vd_column_type IS RECORD(
    row_id        ROWID                                                  -- 1.ROWID
   ,item_id       xxcoi_mst_vd_column.item_id%TYPE                       -- 2.当月品目ID
   ,inv_qnt       xxcoi_mst_vd_column.inventory_quantity%TYPE            -- 3.当月基準在庫数
   ,price         xxcoi_mst_vd_column.price%TYPE                         -- 4.当月単価
   ,hot_cold      xxcoi_mst_vd_column.hot_cold%TYPE                      -- 5.当月H/C
   ,lm_item_id    xxcoi_mst_vd_column.last_month_item_id%TYPE            -- 6.前月品目ID
   ,lm_inv_qnt    xxcoi_mst_vd_column.last_month_inventory_quantity%TYPE -- 7.前月基準在庫数
   ,lm_price      xxcoi_mst_vd_column.last_month_price%TYPE              -- 8.前月単価
   ,lm_hot_cold   xxcoi_mst_vd_column.last_month_hot_cold%TYPE           -- 9.前月H/C
  );
--
  -- VDコラムマスタ情報カーソルレコード型
  gr_mst_vd_column_rec   gr_mst_vd_column_type;
-- == 2011/04/19 V1.4 Added START ===============================================================
  --  新規ベンダ基準在庫登録用変数設定
  TYPE new_vd_data_rtype IS RECORD(
      customer_id           xxcoi_mst_vd_column.customer_id%TYPE
    , column_no             xxcoi_mst_vd_column.column_no%TYPE
    , item_id               xxcoi_mst_vd_column.item_id%TYPE
    , inventory_quantity    xxcoi_mst_vd_column.inventory_quantity%TYPE
    , price                 xxcoi_mst_vd_column.price%TYPE
    , hot_cold              xxcoi_mst_vd_column.hot_cold%TYPE
  );
  --
  TYPE new_vd_data_ttype IS TABLE OF new_vd_data_rtype INDEX BY BINARY_INTEGER;
  gt_new_vd_data    new_vd_data_ttype;
-- == 2011/04/19 V1.4 Added END   ===============================================================
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_cre_tran_cnt      NUMBER;                                         -- 取引作成件数
  gt_inv_org_id        mtl_parameters.organization_id%TYPE;            -- 在庫組織ID
  gv_hht_err_date_name VARCHAR2(30);                                   -- HHTエラーリストデータ名称
  gd_process_date      DATE;                                           -- 業務日付
  gt_tran_type_id      mtl_transaction_types.transaction_type_id%TYPE; -- 取引タイプID
  gv_vd_is_lock_flg    VARCHAR2(1);                                    -- VDコラムマスタロック取得有無フラグ(取得:Y,未取得:N)
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 基準在庫変更抽出カーソル
  CURSOR hht_inv_tran_cur
  IS
    SELECT xhit.rowid               AS row_id            --  1.ROWID
          ,xhit.inventory_item_id   AS item_id           --  2.品目ID
          ,xhit.item_code           AS item_code         --  3.品目コード
          ,xhit.total_quantity      AS total_qnt         --  4.総数量
          ,xhit.primary_uom_code    AS prim_uom_code     --  5.基準単位
          ,xhit.invoice_date        AS invoice_date      --  6.伝票日付
          ,xhit.outside_subinv_code AS out_inv_code      --  7.出庫側保管場所
          ,xhit.inside_subinv_code  AS in_inv_code       --  8.入庫側保管場所
          ,xhit.outside_code        AS outside_code      --  9.出庫側コード
          ,xhit.inside_code         AS customer_code     -- 10.顧客コード
          ,xhit.invoice_no          AS invoice_no        -- 11.伝票№
          ,xhit.column_no           AS column_no         -- 12.コラム№
          ,xhit.unit_price          AS unit_price        -- 13.単価
          ,xhit.hot_cold_div        AS hot_cold_div      -- 14.H/C
          ,xhit.employee_num        AS employee_num      -- 15.営業員コード
          ,xhit.base_code           AS base_code         -- 16.拠点コード
          ,xhit.record_type         AS record_type       -- 17.レコード種別
          ,xhit.invoice_type        AS invoice_type      -- 18.伝票区分
          ,xhit.department_flag     AS department_flag   -- 19.百貨店フラグ
    FROM   xxcoi_hht_inv_transactions  xhit              -- HHT入出庫一時表
    WHERE  xhit.status          = gn_xhit_status_0
    AND    xhit.hht_program_div = gv_pro_div_chg_inv
    ORDER BY xhit.interface_id                           -- 1.インターフェースID
    FOR UPDATE NOWAIT;
--
-- == 2011/04/19 V1.4 Added START ===============================================================
  --  新規ベンダ基準在庫情報抽出カーソル
  CURSOR hht_inv_tran2_cur
  IS
    SELECT  xhit.rowid                AS  row_id            --  1.ROWID
          , xhit.inventory_item_id    AS  item_id           --  2.品目ID
          , xhit.item_code            AS  item_code         --  3.品目コード
          , xhit.total_quantity       AS  total_qnt         --  4.総数量
          , xhit.primary_uom_code     AS  prim_uom_code     --  5.基準単位
          , xhit.invoice_date         AS  invoice_date      --  6.伝票日付
          , xhit.outside_subinv_code  AS  out_inv_code      --  7.出庫側保管場所
          , xhit.inside_subinv_code   AS  in_inv_code       --  8.入庫側保管場所
          , xhit.outside_code         AS  outside_code      --  9.出庫側コード
          , xhit.inside_code          AS  customer_code     -- 10.顧客コード
          , xhit.invoice_no           AS  invoice_no        -- 11.伝票№
          , xhit.column_no            AS  column_no         -- 12.コラム№
          , xhit.unit_price           AS  unit_price        -- 13.単価
          , xhit.hot_cold_div         AS  hot_cold_div      -- 14.H/C
          , xhit.employee_num         AS  employee_num      -- 15.営業員コード
          , xhit.base_code            AS  base_code         -- 16.拠点コード
          , xhit.record_type          AS  record_type       -- 17.レコード種別
          , xhit.invoice_type         AS  invoice_type      -- 18.伝票区分
          , xhit.department_flag      AS  department_flag   -- 19.百貨店フラグ
    FROM    xxcoi_hht_inv_transactions    xhit              -- HHT入出庫一時表
    WHERE   xhit.status           =   gn_xhit_status_0
    AND     xhit.hht_program_div  =   cv_hht_program_div_6
    ORDER BY  xhit.inside_code    ASC
            , xhit.column_no      DESC
            , xhit.interface_id   DESC
    FOR UPDATE NOWAIT;
-- == 2011/04/19 V1.4 Added END   ===============================================================
  -- 基準在庫変更抽出カーソルレコード型
  hht_inv_tran_rec hht_inv_tran_cur%ROWTYPE;
-- == 2011/12/07 V1.5 Added START ===============================================================
  --  顧客内伝票日付不一致チェック用カーソル
  CURSOR chk_cust_date_cur(iv_customer_code VARCHAR2)
  IS
    SELECT  xhit.invoice_date         AS  invoice_date      -- 伝票日付
    FROM    xxcoi_hht_inv_transactions    xhit              -- HHT入出庫一時表
    WHERE   xhit.status           =   gn_xhit_status_0
    AND     xhit.hht_program_div  =   cv_hht_program_div_6
    AND     xhit.inside_code      =   iv_customer_code
    ORDER BY  xhit.column_no      DESC
            , xhit.interface_id   DESC
    ;
  -- 顧客内伝票日付不一致チェック用カーソルレコード型
  chk_cust_date_rec chk_cust_date_cur%ROWTYPE;
-- == 2011/12/07 V1.5 Added END   ===============================================================

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    cv_prf_org_code     CONSTANT VARCHAR2(24) := 'XXCOI1_ORGANIZATION_CODE';     -- XXCOI:在庫組織コード
    cv_prf_hht_err_dt   CONSTANT VARCHAR2(24) := 'XXCOI1_HHT_ERR_DATA_NAME';     -- XXCOI:HHTエラーリスト用入出庫データ名
    cv_lookup_type_tran CONSTANT VARCHAR2(28) := 'XXCOI1_TRANSACTION_TYPE_NAME'; -- 参照タイプ
    cv_lookup_code_80   CONSTANT VARCHAR2(2)  := '80';                           -- 参照コード(基準在庫変更)
--
    -- *** ローカル変数 ***
    lv_message          VARCHAR2(5000);                                   -- メッセージ出力用
    lt_inv_org_code     mtl_parameters.organization_code%TYPE;            -- 在庫組織コード
    lt_tra_type_name    mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名 基準在庫変更
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===================================
    -- コンカレントプログラム入力項目出力
    -- ===================================
    -- 入力パラメータ無しメッセージ
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_kbn_ccp
                   ,iv_name         => gv_msg_ccp_90008
                  );
    -- ファイルに出力
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_message
    );
    -- 空行をファイルに出力
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => ''
    );
--
    -- ===================================
    -- WHOカラム取得
    -- ===================================
    -- 固定グローバル定数宣言部にて取得済み
--
    -- ===================================
    -- 在庫組織ID取得
    -- ===================================
    -- 在庫組織コードの取得
    lt_inv_org_code := FND_PROFILE.VALUE(cv_prf_org_code);
    -- 在庫組織コードがNULLの場合
    IF (lt_inv_org_code IS NULL) THEN
      -- 在庫組織コード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00005
                    ,iv_token_name1  => gv_tkn_pro_tok
                    ,iv_token_value1 => cv_prf_org_code);
      RAISE global_api_expt;
    END IF;
    -- 在庫組織IDの取得
    gt_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => lt_inv_org_code);
--
    IF (gt_inv_org_id IS NULL) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00006
                    ,iv_token_name1  => gv_tkn_org_code_tok
                    ,iv_token_value1 => lt_inv_org_code);
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- HHTエラーリスト帳票用 データ名称取得
    -- ====================================
    gv_hht_err_date_name := FND_PROFILE.VALUE(cv_prf_hht_err_dt);
--
    IF (gv_hht_err_date_name IS NULL) THEN
      -- データ名称取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10027
                    ,iv_token_name1  => gv_tkn_pro_tok
                    ,iv_token_value1 => cv_prf_hht_err_dt);
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- 業務日付取得
    -- ====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL) THEN
      --業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00011);
      RAISE global_api_expt;
    END IF;
--
    -- ====================================
    -- 取引タイプ取得
    -- ====================================
    -- 取引タイプ名の取得
    lt_tra_type_name := xxcoi_common_pkg.get_meaning(
                          iv_lookup_type => cv_lookup_type_tran
                         ,iv_lookup_code => cv_lookup_code_80);
--
    IF (lt_tra_type_name IS NULL) THEN
      --取引タイプ名取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10241
                    ,iv_token_name1  => gv_tkn_lookup_type
                    ,iv_token_value1 => cv_lookup_type_tran
                    ,iv_token_name2  => gv_tkn_lookup_code
                    ,iv_token_value2 => cv_lookup_code_80);
      RAISE global_api_expt;
    END IF;
--
    -- 取引タイプIDの取得
    gt_tran_type_id := xxcoi_common_pkg.get_transaction_type_id(
                         iv_transaction_type_name => lt_tra_type_name);
    IF (gt_tran_type_id IS NULL) THEN
      --取引タイプID取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_00012
                    ,iv_token_name1  => gv_tkn_tran_type_tok
                    ,iv_token_value1 => lt_tra_type_name);
      RAISE global_api_expt;
    END IF;
--
-- == 2011/04/19 V1.4 Added START ===============================================================
    -- ====================================
    --  登録コラム上限値取得
    -- ====================================
    gt_max_column_no  :=  TO_NUMBER(fnd_profile.value(cv_prf_max_column_no));
    --
    IF (gt_max_column_no IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_00032
                        , iv_token_name1    =>  gv_tkn_pro_tok
                        , iv_token_value1   =>  cv_prf_max_column_no
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ====================================
    --  ラック数初期値取得
    -- ====================================
    gt_default_rack   :=  TO_NUMBER(fnd_profile.value(cv_prf_default_rack));
    --
    IF (gt_default_rack IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_00032
                        , iv_token_name1    =>  gv_tkn_pro_tok
                        , iv_token_value1   =>  cv_prf_default_rack
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- == 2011/04/19 V1.4 Added END   ===============================================================
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_vd_column_mst_info
   * Description      : 基準在庫変更データ妥当性チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_vd_column_mst_info(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_vd_column_mst_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cn_dummy_item_price      CONSTANT NUMBER := -1;   -- 品目ID比較時のダミー値
--
    -- *** ローカル変数 ***
    lv_key_msg            VARCHAR2(1000);          -- HHT入出庫データ用KEY情報
    ln_disagreement_count NUMBER;                  -- 不一致件数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- リターン・コードの初期化
    lv_retcode := cv_status_normal;
--
    -- =========================================
    -- VDコラムマスタ情報の取得
    -- =========================================
--
    -- VDコラムマスタロック取得有無フラグをVDコラムマスタロック取得成功に初期化
    gv_vd_is_lock_flg := gv_vd_get_lock;
--
    BEGIN
      SELECT xmvc.rowid                         AS row_id      --  1.ROWID
            ,xmvc.item_id                       AS item_id     --  2.当月品目ID
            ,xmvc.inventory_quantity            AS inv_qnt     --  3.当月基準在庫数
            ,xmvc.price                         AS price       --  4.当月単価
            ,xmvc.hot_cold                      AS hot_cold    --  5.当月H/C
            ,xmvc.last_month_item_id            AS lm_item_id  --  6.前月品目ID
            ,xmvc.last_month_inventory_quantity AS lm_inv_qnt  --  7.前月基準在庫数
            ,xmvc.last_month_price              AS lm_price    --  8.前月単価
            ,xmvc.last_month_hot_cold           AS lm_hot_cold --  9.前月H/C
      INTO   gr_mst_vd_column_rec
      FROM   xxcoi_mst_vd_column                xmvc           -- VDコラムマスタ
            ,hz_cust_accounts                   hca            -- 顧客アカウント
      WHERE  xmvc.customer_id   = hca.cust_account_id 
      AND    hca.account_number = hht_inv_tran_rec.customer_code
      AND    xmvc.column_no     = hht_inv_tran_rec.column_no
-- == 2009/12/15 V1.3 Added START ===============================================================
--      FOR UPDATE NOWAIT;
      FOR UPDATE OF xmvc.vd_column_mst_id NOWAIT;
-- == 2009/12/15 V1.3 Added END   ===============================================================
    EXCEPTION
      -- 対象データ無し
      WHEN NO_DATA_FOUND THEN
        -- 対象データ無しメッセージ（VDコラムマスタ）の取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_coi
                      ,iv_name         => gv_msg_coi_10359);
        -- 妥当性チェックエラー
        RAISE chk_err_expt;
--
      -- ロック取得エラー
      WHEN lock_expt THEN
        -- VDコラムマスタロック取得有無フラグに失敗を設定
        gv_vd_is_lock_flg := gv_vd_miss_lock;
--
        -- ロックエラーメッセージ(VDコラムマスタ)取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_coi
                      ,iv_name         => gv_msg_coi_10024);
        -- 妥当性チェックエラー
        RAISE chk_err_expt;
    END;
--
    -- =====================================
    -- VDコラムマスタ更新の妥当性チェック
    -- =====================================
    -- 取得した伝票日付と業務日付を比較
    -- 当月の場合
    IF (TRUNC(hht_inv_tran_rec.invoice_date) >= TRUNC(gd_process_date, 'MM')) THEN
--
      -- 総数量が0より大きい場合で且つ、
      IF (hht_inv_tran_rec.total_qnt > 0) THEN
--
-- Add 2009/02/18 #015 ↓
        -- 総数量が小数を含む場合
        IF ((hht_inv_tran_rec.total_qnt - ROUND(hht_inv_tran_rec.total_qnt)) <> 0) THEN
          -- 基準在庫更新（基準在庫小数点）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_mst_coi_10372
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 総数量が4桁以上の場合
        ELSIF (LENGTH(hht_inv_tran_rec.total_qnt) > 3) THEN
          -- 基準在庫更新（基準在庫上限値）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10371
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
-- Add 2009/02/18 #015 ↑
        -- VDコラムマスタの当月基準在庫数 <> 0の場合
        IF (gr_mst_vd_column_rec.inv_qnt <> 0) THEN
          -- 基準在庫更新（品目・基準在庫更新不可）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10058);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 取得した単価がNULLの場合
        ELSIF (hht_inv_tran_rec.unit_price IS NULL) THEN
          -- 基準在庫更新（単価未設定エラー）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10353);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 取得した単価が0未満の場合
        ELSIF (hht_inv_tran_rec.unit_price < 0) THEN
          -- 基準在庫更新（単価不整合）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 取得したH/CがNULLの場合
        ELSIF (hht_inv_tran_rec.hot_cold_div IS NULL) THEN
          -- 基準在庫更新（H/C未設定エラー）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10354);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
--
      -- 総数量が0以下の場合
      ELSE
--
        -- 取得した品目ID <> VDコラムマスタの当月品目IDの場合
        IF (hht_inv_tran_rec.item_id <> NVL(gr_mst_vd_column_rec.item_id, cn_dummy_item_price)) THEN
          -- 基準在庫更新（品目不一致）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10056);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
--
        -- 総数量が0の場合且つ、取得した単価が0未満の場合
        IF (hht_inv_tran_rec.total_qnt = 0)
          AND (hht_inv_tran_rec.unit_price < 0) THEN
          -- 基準在庫更新（単価不整合）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 総数量がマイナスの場合且つ、
        -- (取得した総数量 + VDコラムマスタの当月基準在庫数) <> 0の場合
        ELSIF (hht_inv_tran_rec.total_qnt < 0)
          AND ((hht_inv_tran_rec.total_qnt + gr_mst_vd_column_rec.inv_qnt) <> 0) THEN
          -- 基準在庫更新（基準在庫不整合）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10057);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
      END IF;
--
    -- 前月の場合
    ELSE
--
      -- =================================
      -- 当月-前月 顧客レベル不一致情報
      -- =================================
      -- 不一致件数カウンターの初期化
      ln_disagreement_count := 0;
--
      BEGIN
        -- 不一致件数の取得
        SELECT COUNT(xmvc1.rowid)     AS row_count  -- 不一致件数
        INTO   ln_disagreement_count
        FROM   xxcoi_mst_vd_column   xmvc1  -- VDコラムマスタ(当月情報)
              ,hz_cust_accounts      hca    -- 顧客アカウント
        WHERE  hca.account_number  = hht_inv_tran_rec.customer_code
        AND    hca.cust_account_id = xmvc1.customer_id
-- == 2009/12/15 V1.3 Added START ===============================================================
        AND    xmvc1.column_no     = hht_inv_tran_rec.column_no
-- == 2009/12/15 V1.3 Added END   ===============================================================
        AND    NOT EXISTS (
          SELECT ROWID
          FROM   xxcoi_mst_vd_column xmvc2   -- VDコラムマスタ(前月情報)
          WHERE  xmvc2.customer_id                                  = xmvc1.customer_id
          AND    xmvc2.column_no                                    = xmvc1.column_no
          AND    NVL(xmvc2.last_month_item_id, cn_dummy_item_price) = NVL(xmvc1.item_id, cn_dummy_item_price)
          AND    xmvc2.last_month_inventory_quantity                = xmvc1.inventory_quantity
          AND    NVL(xmvc2.last_month_price, cn_dummy_item_price)   = NVL(xmvc1.price, cn_dummy_item_price)
        )
        AND    ROWNUM <= 1;
      EXCEPTION
        -- 想定外エラーが発生した場合
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 不一致件数が1以上の場合
      IF (ln_disagreement_count >= 1) THEN
        -- 基準在庫更新（前月当月不一致）エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_coi
                      ,iv_name         => gv_msg_coi_10062);
        -- 妥当性チェックエラー
        RAISE chk_err_expt;
--
      -- 総数量が0より大きい場合
      ELSIF (hht_inv_tran_rec.total_qnt > 0) THEN
--
-- Add 2009/02/18 #015 ↓
        -- 総数量が小数を含む場合
        IF ((hht_inv_tran_rec.total_qnt - ROUND(hht_inv_tran_rec.total_qnt)) <> 0) THEN
          -- 基準在庫更新（基準在庫小数点）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_mst_coi_10372
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 総数量が4桁以上の場合
        ELSIF (LENGTH(hht_inv_tran_rec.total_qnt) > 3) THEN
          -- 基準在庫更新（基準在庫上限値）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10371
                        ,iv_token_name1  => gv_tkn_total_qnt
                        ,iv_token_value1 => hht_inv_tran_rec.total_qnt);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
-- Add 2009/02/18 #015 ↑
        -- VDコラムマスタの前月基準在庫数 <> 0の場合
        IF (gr_mst_vd_column_rec.inv_qnt <> 0) THEN
          -- 基準在庫更新（品目・基準在庫更新不可）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10058);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 取得した単価がNULLの場合
        ELSIF (hht_inv_tran_rec.unit_price IS NULL) THEN
          -- 基準在庫更新（単価未設定エラー）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10353);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 取得した単価が0未満の場合
        ELSIF (hht_inv_tran_rec.unit_price < 0) THEN
          -- 基準在庫更新（単価不整合）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;        -- 取得したH/CがNULLの場合
--
        ELSIF (hht_inv_tran_rec.hot_cold_div IS NULL) THEN
          -- 基準在庫更新（H/C未設定エラー）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10354);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
--
      -- 総数量がマイナスまたは0の場合
      ELSE
--
        -- 取得した品目ID <> VDコラムマスタの前月品目IDの場合
        IF (hht_inv_tran_rec.item_id <> NVL(gr_mst_vd_column_rec.lm_item_id, cn_dummy_item_price)) THEN
          -- 基準在庫更新（品目不一致）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10056);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
--
        -- 総数量が0の場合で且つ、取得した単価が0未満の場合
        IF (hht_inv_tran_rec.total_qnt = 0)
          AND (hht_inv_tran_rec.unit_price < 0) THEN
          -- 基準在庫更新（単価不整合）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10059
                        ,iv_token_name1  => gv_tkn_unit_price
                        ,iv_token_value1 => hht_inv_tran_rec.unit_price);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
--
        -- 総数量がマイナス値の場合で且つ、
        -- (取得した総数量 + VDコラムマスタの前月基準在庫数) <> 0の場合
        ELSIF (hht_inv_tran_rec.total_qnt < 0)
          AND ((hht_inv_tran_rec.total_qnt + gr_mst_vd_column_rec.lm_inv_qnt) <> 0) THEN
          -- 基準在庫更新（基準在庫不整合）エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => gv_msg_kbn_coi
                        ,iv_name         => gv_msg_coi_10057);
          -- 妥当性チェックエラー
          RAISE chk_err_expt;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- 妥当性チェックエラー
    WHEN chk_err_expt THEN
      -- HHT入出庫データ用KEY情報メッセージの取得
      lv_key_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10342
                    ,iv_token_name1  => gv_tkn_base_code                   -- 拠点コード
                    ,iv_token_value1 => hht_inv_tran_rec.base_code
                    ,iv_token_name2  => gv_tkn_record_type                 -- レコード種別
                    ,iv_token_value2 => hht_inv_tran_rec.record_type
                    ,iv_token_name3  => gv_tkn_invoice_type                -- 伝票区分
                    ,iv_token_value3 => hht_inv_tran_rec.invoice_type
                    ,iv_token_name4  => gv_tkn_dept_flag                   -- 百貨店フラグ
                    ,iv_token_value4 => hht_inv_tran_rec.department_flag
                    ,iv_token_name5  => gv_tkn_invoice_no                  -- 伝票№
                    ,iv_token_value5 => hht_inv_tran_rec.invoice_no
                    ,iv_token_name6  => gv_tkn_column_no                   -- コラム№
                    ,iv_token_value6 => hht_inv_tran_rec.column_no
                    ,iv_token_name7  => gv_tkn_item_code                   -- 品目コード
                    ,iv_token_value7 => hht_inv_tran_rec.item_code);
--
      -- VDコラムマスタロック取得有無フラグが成功の場合
      IF (gv_vd_is_lock_flg = gv_vd_get_lock) THEN
        -- エラー・バッファを設定
        lv_errbuf := lv_key_msg || lv_errmsg;
--
        -- HHT入出庫データ用KEY情報メッセージの出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf);
--
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errbuf);
--
-- == 2011/04/19 V1.4 Modified START ===============================================================
        -- エラー件数のカウントアップ
--        gn_error_cnt := gn_error_cnt + 1;
        gn_warn_cnt :=  gn_warn_cnt + 1;
-- == 2011/04/19 V1.4 Modified END   ===============================================================
--
      -- VDコラムマスタロック取得有無フラグが失敗の場合
      ELSE
        -- エラー・バッファを設定(改行コード挿入)
        lv_errbuf := lv_key_msg || chr(10) || lv_errmsg;
--
        -- HHT入出庫データ用KEY情報メッセージの出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf);
--
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errbuf);
--
        -- スキップ件数のカウントアップ
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      -- リターン・コードに警告を設定
      ov_retcode   := cv_status_warn;
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_vd_column_mst_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_tmp_svd_tran_date
   * Description      : 基準在庫変更ワークテーブルの追加(A-4)
   ***********************************************************************************/
  PROCEDURE ins_tmp_svd_tran_date(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_tmp_svd_tran_date'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 基準在庫変更データ挿入処理
    INSERT INTO xxcoi_tmp_standard_inv(
      item_id                         -- 1.品目ID
     ,primary_uom_code                -- 2.基準単位
     ,invoice_date                    -- 3.伝票日付
     ,outside_subinv_code             -- 4.出庫側保管場所
     ,inside_subinv_code              -- 5.入庫側保管場所
     ,total_quantity                  -- 6.総数量
    )
    VALUES(
      hht_inv_tran_rec.item_id        -- 1.品目ID
     ,hht_inv_tran_rec.prim_uom_code  -- 2.基準単位
     ,hht_inv_tran_rec.invoice_date   -- 3.伝票日付
     ,hht_inv_tran_rec.out_inv_code   -- 4.出庫側保管場所
     ,hht_inv_tran_rec.in_inv_code    -- 5.入庫側保管場所
     ,hht_inv_tran_rec.total_qnt      -- 6.総数量
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_tmp_svd_tran_date;
--
  /**********************************************************************************
   * Procedure Name   : upd_xxcoi_mst_vd_column
   * Description      : VDコラムマスタの更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_xxcoi_mst_vd_column(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxcoi_mst_vd_column'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 伝票日付が当月の場合
    IF (TRUNC(hht_inv_tran_rec.invoice_date) >= TRUNC(gd_process_date, 'MM')) THEN
--
      -- 総数量 > 0の場合
      IF (hht_inv_tran_rec.total_qnt > 0) THEN
        -- 当月の品目ID、基準在庫数を更新
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.item_id                = hht_inv_tran_rec.item_id                                    -- 1.品目ID
              ,xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt) -- 2.基準在庫数
              ,xmvc.price                  = hht_inv_tran_rec.unit_price                                 -- 3.単価
              ,xmvc.hot_cold               = hht_inv_tran_rec.hot_cold_div                               -- 4.H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              --  5.最終更新者
              ,xmvc.last_update_date       = cd_last_update_date                             --  6.最終更新日
              ,xmvc.last_update_login      = cn_last_update_login                            --  7.最終更新ログイン
              ,xmvc.request_id             = cn_request_id                                   --  8.要求ID
              ,xmvc.program_id             = cn_program_id                                   --  9.プログラムID
              ,xmvc.program_application_id = cn_program_application_id                       -- 10.プログラム・アプリケーションID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 11.プログラム更新日
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
--
      -- 総数量 < 0の場合
      ELSIF (hht_inv_tran_rec.total_qnt < 0) THEN
        -- 当月の品目ID、基準在庫数を更新
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt)       -- 1.基準在庫数
-- == 2009/12/15 V1.3 Added START ===============================================================
              ,xmvc.item_id                = NULL                                            -- 9.品目ID
              ,xmvc.price                  = NULL                                            --10.単価
              ,xmvc.hot_cold               = NULL                                            --11.H/C
-- == 2009/12/15 V1.3 Added END   ===============================================================
              ,xmvc.last_updated_by        = cn_last_updated_by                              -- 2.最終更新者
              ,xmvc.last_update_date       = cd_last_update_date                             -- 3.最終更新日
              ,xmvc.last_update_login      = cn_last_update_login                            -- 4.最終更新ログイン
              ,xmvc.request_id             = cn_request_id                                   -- 5.要求ID
              ,xmvc.program_id             = cn_program_id                                   -- 6.プログラムID
              ,xmvc.program_application_id = cn_program_application_id                       -- 7.プログラム・アプリケーションID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 8.プログラム更新日
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
--
      -- 総数量 = 0の場合
      ELSIF (hht_inv_tran_rec.total_qnt = 0) THEN
        -- 当月の単価、H/Cを更新
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.price                  = NVL(hht_inv_tran_rec.unit_price, gr_mst_vd_column_rec.price)      -- 1.単価
              ,xmvc.hot_cold               = NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.hot_cold) -- 2.H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              -- 3.最終更新者
              ,xmvc.last_update_date       = cd_last_update_date                             -- 4.最終更新日
              ,xmvc.last_update_login      = cn_last_update_login                            -- 5.最終更新ログイン
              ,xmvc.request_id             = cn_request_id                                   -- 6.要求ID
              ,xmvc.program_id             = cn_program_id                                   -- 7.プログラムID
              ,xmvc.program_application_id = cn_program_application_id                       -- 8.プログラム・アプリケーションID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 9.プログラム更新日
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
      END IF;
--
    -- 伝票日付が前月の場合
    ELSE
      -- 総数量 > 0 の場合
      IF (hht_inv_tran_rec.total_qnt > 0) THEN
        -- 当月の品目ID、基準在庫数を更新
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.item_id                = hht_inv_tran_rec.item_id                                              -- 1.品目ID
              ,xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt)           -- 2.基準在庫数
              ,xmvc.price                  = hht_inv_tran_rec.unit_price                                           -- 3.単価
-- == 2009/04/06 V1.2 Moded START ===============================================================
--              ,xmvc.hot_cold               = hht_inv_tran_rec.hot_cold_div                                         -- 4.H/C
              ,xmvc.hot_cold               = DECODE( gr_mst_vd_column_rec.hot_cold
                                               ,gr_mst_vd_column_rec.lm_hot_cold
                                               ,hht_inv_tran_rec.hot_cold_div
                                               ,gr_mst_vd_column_rec.hot_cold )                                    -- 4.H/C
-- == 2009/04/06 V1.2 Moded END   ===============================================================
              ,xmvc.last_month_item_id     = hht_inv_tran_rec.item_id                                              -- 5.前月末品目ID
              ,xmvc.last_month_inventory_quantity = (gr_mst_vd_column_rec.lm_inv_qnt + hht_inv_tran_rec.total_qnt) -- 6.前月末基準在庫数
              ,xmvc.last_month_price       = hht_inv_tran_rec.unit_price                                           -- 7.前月末単価
              ,xmvc.last_month_hot_cold    = hht_inv_tran_rec.hot_cold_div                                         -- 8.前月末H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              --  9.最終更新者
              ,xmvc.last_update_date       = cd_last_update_date                             -- 10.最終更新日
              ,xmvc.last_update_login      = cn_last_update_login                            -- 11.最終更新ログイン
              ,xmvc.request_id             = cn_request_id                                   -- 12.要求ID
              ,xmvc.program_id             = cn_program_id                                   -- 13.プログラムID
              ,xmvc.program_application_id = cn_program_application_id                       -- 14.プログラム・アプリケーションID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 15.プログラム更新日
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;--
--
      -- 総数量 < 0 の場合
      ELSIF (hht_inv_tran_rec.total_qnt < 0) THEN
        -- 当月の品目ID、基準在庫数を更新
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.inventory_quantity     = (gr_mst_vd_column_rec.inv_qnt + hht_inv_tran_rec.total_qnt)           -- 1.基準在庫数
              ,xmvc.last_month_inventory_quantity = (gr_mst_vd_column_rec.lm_inv_qnt + hht_inv_tran_rec.total_qnt) -- 2.前月末基準在庫数
-- == 2009/12/15 V1.3 Added START ===============================================================
              ,xmvc.item_id                = NULL                                            --10.品目ID
              ,xmvc.price                  = NULL                                            --11.単価
              ,xmvc.hot_cold               = NULL                                            --12.H/C
              ,xmvc.last_month_item_id     = NULL                                            --13.前月末品目ID
              ,xmvc.last_month_price       = NULL                                            --14.前月末単価
              ,xmvc.last_month_hot_cold    = NULL                                            --15.前月末H/C
-- == 2009/12/15 V1.3 Added END   ===============================================================
              ,xmvc.last_updated_by        = cn_last_updated_by                              -- 3.最終更新者
              ,xmvc.last_update_date       = cd_last_update_date                             -- 4.最終更新日
              ,xmvc.last_update_login      = cn_last_update_login                            -- 5.最終更新ログイン
              ,xmvc.request_id             = cn_request_id                                   -- 6.要求ID
              ,xmvc.program_id             = cn_program_id                                   -- 7.プログラムID
              ,xmvc.program_application_id = cn_program_application_id                       -- 8.プログラム・アプリケーションID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 9.プログラム更新日
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
--
      -- 総数量が0の場合
      ELSIF (hht_inv_tran_rec.total_qnt = 0) THEN
        -- 当月及び前月の単価、H/Cを更新
        UPDATE xxcoi_mst_vd_column xmvc
        SET    xmvc.price                  = NVL(hht_inv_tran_rec.unit_price, gr_mst_vd_column_rec.price)          -- 1.単価
-- == 2009/04/06 V1.2 Moded START ===============================================================
--              ,xmvc.hot_cold               = NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.hot_cold)     -- 2.H/C
              ,xmvc.hot_cold               = DECODE( gr_mst_vd_column_rec.hot_cold
                                               ,gr_mst_vd_column_rec.lm_hot_cold
                                               ,NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.hot_cold)
                                               ,gr_mst_vd_column_rec.hot_cold )                                    -- 2.H/C
-- == 2009/04/06 V1.2 Moded END   ===============================================================
              ,xmvc.last_month_price       = NVL(hht_inv_tran_rec.unit_price, gr_mst_vd_column_rec.lm_price)       -- 3.前月末単価
              ,xmvc.last_month_hot_cold    = NVL(hht_inv_tran_rec.hot_cold_div, gr_mst_vd_column_rec.lm_hot_cold)  -- 4.前月末H/C
              ,xmvc.last_updated_by        = cn_last_updated_by                              --  5.最終更新者
              ,xmvc.last_update_date       = cd_last_update_date                             --  6.最終更新日
              ,xmvc.last_update_login      = cn_last_update_login                            --  7.最終更新ログイン
              ,xmvc.request_id             = cn_request_id                                   --  8.要求ID
              ,xmvc.program_id             = cn_program_id                                   --  9.プログラムID
              ,xmvc.program_application_id = cn_program_application_id                       -- 10.プログラム・アプリケーションID
              ,xmvc.program_update_date    = cd_program_update_date                          -- 11.プログラム更新日
        WHERE  xmvc.rowid                  = gr_mst_vd_column_rec.row_id;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_xxcoi_mst_vd_column;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_inv_transactions
   * Description      : HHT入出庫一時表の処理ステータス更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_hht_inv_transactions(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_inv_transactions'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    UPDATE xxcoi_hht_inv_transactions xhit
    SET    xhit.status                 = 1                          -- 1.処理ステータス(1:処理済み)
          ,xhit.last_updated_by        = cn_last_updated_by         -- 2.最終更新者
          ,xhit.last_update_date       = cd_last_update_date        -- 3.最終更新日
          ,xhit.last_update_login      = cn_last_update_login       -- 4.最終更新ログイン
          ,xhit.request_id             = cn_request_id              -- 5.要求ID
          ,xhit.program_id             = cn_program_id              -- 6.プログラムID
          ,xhit.program_application_id = cn_program_application_id  -- 7.プログラム・アプリケーションID
          ,xhit.program_update_date    = cd_program_update_date     -- 8.プログラム更新日
    WHERE  xhit.rowid = hht_inv_tran_rec.row_id;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_hht_inv_transactions;
--
  /**********************************************************************************
   * Procedure Name   : ins_standard_inv_err_list
   * Description      : 基準在庫変更データのエラーリスト表追加(A-7)
   ***********************************************************************************/
  PROCEDURE ins_standard_inv_err_list(
    ov_errbuf     OUT    VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT    VARCHAR2     --   リターン・コード                    --# 固定 #
   ,iov_errmsg    IN OUT VARCHAR2)    --   ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_standard_inv_err_list'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- HHT情報取込エラー出力関数
    xxcoi_common_pkg.add_hht_err_list_data(
      ov_errbuf              => lv_errbuf                      --  1.エラー・メッセージ
     ,ov_retcode             => lv_retcode                     --  2.リターン・コード
     ,ov_errmsg              => lv_errmsg                      --  3.ユーザー・エラー・メッセージ
     ,iv_base_code           => hht_inv_tran_rec.base_code     --  4.拠点コード
     ,iv_origin_shipment     => hht_inv_tran_rec.outside_code  --  5.出庫側コード
     ,iv_data_name           => gv_hht_err_date_name           --  6.データ名称
     ,id_transaction_date    => hht_inv_tran_rec.invoice_date  --  7.取引日
     ,iv_entry_number        => hht_inv_tran_rec.invoice_no    --  8.伝票NO
     ,iv_party_num           => hht_inv_tran_rec.customer_code --  9.入庫側コード
     ,iv_performance_by_code => hht_inv_tran_rec.employee_num  -- 10.営業員コード
     ,iv_item_code           => hht_inv_tran_rec.item_code     -- 11.品目コード
     ,iv_error_message       => iov_errmsg                     -- 12.エラー内容
    );
--
    -- 共通関数:HHT情報取込エラー出力関数が正常以外の場合
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    -- 共通関数:HHT情報取込エラー出力関数が正常に終了した場合
    ELSE
      ov_errbuf  := lv_errbuf;   -- エラー・メッセージの設定
      ov_retcode := lv_retcode;  -- リターン・コードの設定
      iov_errmsg := lv_errmsg;   -- ユーザー・エラー・メッセージの設定
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      iov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      iov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_standard_inv_err_list;
--
  /**********************************************************************************
   * Procedure Name   : del_hht_inv_transactions
   * Description      : HHT入出庫一時表のエラーレコード削除(A-8)
   ***********************************************************************************/
  PROCEDURE del_hht_inv_transactions(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_hht_inv_transactions'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- HHT入出庫一時表のエラーデータ削除
    DELETE FROM xxcoi_hht_inv_transactions xhit
    WHERE xhit.rowid = hht_inv_tran_rec.row_id;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_hht_inv_transactions;
--
  /**********************************************************************************
   * Procedure Name   : ins_mtl_transactions_if
   * Description      : 基準在庫変更データの資材取引OIF追加(A-9)
   ***********************************************************************************/
  PROCEDURE ins_mtl_transactions_if(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mtl_transactions_if'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_process_flag       CONSTANT VARCHAR2(1) := '1';   -- プロセスフラグ
    cv_source_code        CONSTANT VARCHAR2(1) := '3';   -- 取引モード
    cn_source_header_id   CONSTANT NUMBER      := 1;     -- ソースヘッダID
    cn_source_line_id     CONSTANT NUMBER      := 1;     -- ソースラインID
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================================
    -- 資材取引OIFの登録処理
    -- ========================================
    INSERT INTO mtl_transactions_interface(
      process_flag                                                     --  1.プロセスフラグ
     ,transaction_mode                                                 --  2.取引モード
     ,source_code                                                      --  3.ソースコード
     ,source_header_id                                                 --  4.ソースヘッダID
     ,source_line_id                                                   --  5.ソースラインID
     ,inventory_item_id                                                --  6.品目ID
     ,organization_id                                                  --  7.在庫組織ID
     ,transaction_quantity                                             --  8.取引数量
     ,primary_quantity                                                 --  9.基準単位数量
     ,transaction_uom                                                  -- 10.取引単位
     ,transaction_date                                                 -- 11.取引日
     ,subinventory_code                                                -- 12.保管場所
     ,transaction_type_id                                              -- 13.取引タイプID
     ,transfer_subinventory                                            -- 14.相手先保管場所
     ,transfer_organization                                            -- 15.相手先在庫組織
     ,created_by                                                       -- 16.作成者
     ,creation_date                                                    -- 17.作成日
     ,last_updated_by                                                  -- 18.最終更新者
     ,last_update_date                                                 -- 19.最終更新日
     ,last_update_login                                                -- 20.最終更新ユーザ
     ,request_id                                                       -- 21.要求ID
     ,program_application_id                                           -- 22.プログラムアプリケーションID
     ,program_id                                                       -- 23.プログラムID
     ,program_update_date                                              -- 24.プログラム更新日
    )
    SELECT cv_process_flag                                             --  1.プロセスフラグ
          ,cv_source_code                                              --  2.取引モード
          ,cv_pkg_name                                                 --  3.ソースコード
          ,cn_source_header_id                                         --  4.ソースヘッダID
          ,cn_source_line_id                                           --  5.ソースラインID
          ,xtsi.item_id                                                --  6.品目ID
          ,gt_inv_org_id                                               --  7.在庫組織ID
          ,SIGN(SUM(xtsi.total_quantity)) * SUM(xtsi.total_quantity)   --  8.取引数量
          ,SIGN(SUM(xtsi.total_quantity)) * SUM(xtsi.total_quantity)   --  9.基準単位数量
          ,xtsi.primary_uom_code                                       -- 10.取引単位
          ,xtsi.invoice_date                                           -- 11.取引日
          ,DECODE(SIGN(SUM(xtsi.total_quantity))
            ,'1'  ,xtsi.outside_subinv_code
            ,'-1' ,xtsi.inside_subinv_code)                            -- 12.保管場所
          ,gt_tran_type_id                                             -- 13.取引タイプID
          ,DECODE(SIGN(SUM(xtsi.total_quantity))
            ,'1'  ,xtsi.inside_subinv_code
            ,'-1' ,xtsi.outside_subinv_code)                            -- 14.相手先保管場所
          ,gt_inv_org_id                                                -- 15.相手先在庫組織
          ,cn_created_by                                                -- 16.作成者
          ,cd_creation_date                                             -- 17.作成日
          ,cn_last_updated_by                                           -- 18.最終更新者
          ,cd_last_update_date                                          -- 19.最終更新日
          ,cn_last_update_login                                         -- 20.最終更新ユーザ
          ,cn_request_id                                                -- 21.要求ID
          ,cn_program_application_id                                    -- 22.プログラムアプリケーションID
          ,cn_program_id                                                -- 23.プログラムID
          ,cd_program_update_date                                       -- 24.プログラム更新日
    FROM   xxcoi_tmp_standard_inv   xtsi                                --  1.基準在庫変更ワークテーブル
    HAVING SUM(xtsi.total_quantity) <> 0
    GROUP BY xtsi.item_id
            ,xtsi.primary_uom_code
            ,xtsi.invoice_date
            ,xtsi.outside_subinv_code
            ,xtsi.inside_subinv_code;
--
    -- 取引作成件数の取得
    gn_cre_tran_cnt := sql%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_mtl_transactions_if;
--
-- == 2011/04/19 V1.4 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : ins_vd_column
   * Description      : VDコラムマスタの登録(A-12)
   ***********************************************************************************/
  PROCEDURE ins_vd_column(
      ov_errbuf     OUT VARCHAR2      --  エラー・メッセージ            --# 固定 #
    , ov_retcode    OUT VARCHAR2      --  リターン・コード              --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --  ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_column'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --  伝票日付が当月(gv_ins_vd_type = '1')の場合、前月項目は初期値を設定
    --  前月の場合は、当月情報と同値を設定
    <<ins_vd_clm_loop>>
    FOR ln_count IN  1 .. gt_new_vd_data.COUNT  LOOP
      INSERT  INTO  xxcoi_mst_vd_column(
          vd_column_mst_id                                              --   1.VDコラムマスタID
        , customer_id                                                   --   2.顧客ID
        , column_no                                                     --   3.コラムNo
        , item_id                                                       --   4.品目ID
        , organization_id                                               --   5.在庫組織ID
        , inventory_quantity                                            --   6.基準在庫数
        , price                                                         --   7.単価
        , hot_cold                                                      --   8.H/C
        , last_month_item_id                                            --   9.(前月)品目ID
        , last_month_inventory_quantity                                 --  10.(前月)基準在庫数
        , last_month_price                                              --  11.(前月)単価
        , last_month_hot_cold                                           --  12.(前月)H/C
        , rack_quantity                                                 --  13.ラック数
        , created_by                                                    --  14.作成者
        , creation_date                                                 --  15.作成日時
        , last_updated_by                                               --  16.最終更新者
        , last_update_date                                              --  17.最終更新日時
        , last_update_login                                             --  18.最終更新ログイン者
        , request_id                                                    --  19.要求ID
        , program_application_id                                        --  20.プログラム・アプリケーションID
        , program_id                                                    --  21.プログラムID
        , program_update_date                                           --  22.プログラム更新日時
      )VALUES(
          xxcoi_mst_vd_column_s01.NEXTVAL                               --  1
        , gt_new_vd_data(ln_count).customer_id                          --  2
        , gt_new_vd_data(ln_count).column_no                            --  3
        , gt_new_vd_data(ln_count).item_id                              --  4
        , gt_inv_org_id                                                 --  5
        , gt_new_vd_data(ln_count).inventory_quantity                   --  6
        , gt_new_vd_data(ln_count).price                                --  7
        , gt_new_vd_data(ln_count).hot_cold                             --  8
        , CASE  WHEN  gv_ins_vd_type = cv_month_type_1  THEN  NULL
                                                        ELSE  gt_new_vd_data(ln_count).item_id
          END                                                           --  9
        , CASE  WHEN  gv_ins_vd_type = cv_month_type_1  THEN  0
                                                        ELSE  gt_new_vd_data(ln_count).inventory_quantity
          END                                                           --  10
        , CASE  WHEN  gv_ins_vd_type = cv_month_type_1  THEN  NULL
                                                        ELSE  gt_new_vd_data(ln_count).price
          END                                                           --  11
        , CASE  WHEN  gv_ins_vd_type = cv_month_type_1  THEN  NULL
                                                        ELSE  gt_new_vd_data(ln_count).hot_cold
          END                                                           --  12
        , gt_default_rack                                               --  13
        , cn_created_by                                                 --  14
        , SYSDATE                                                       --  15
        , cn_last_updated_by                                            --  16
        , SYSDATE                                                       --  17
        , cn_last_update_login                                          --  18
        , cn_request_id                                                 --  19
        , cn_program_application_id                                     --  20
        , cn_program_id                                                 --  21
        , SYSDATE                                                       --  22
      );
    END LOOP ins_vd_clm_loop;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_vd_column;
--
  /**********************************************************************************
   * Procedure Name   : chk_new_vd_data
   * Description      : 新規ベンダ基準在庫妥当性チェック(A-14)
   ***********************************************************************************/
  PROCEDURE chk_new_vd_data(
      it_chk_customer   IN  hz_cust_accounts.account_number%TYPE    --  顧客コード（切替確認用）
    , ov_msg_code       OUT VARCHAR2                                --  メッセージコード
    , ov_errbuf         OUT VARCHAR2                                --  エラー・メッセージ            --# 固定 #
    , ov_retcode        OUT VARCHAR2                                --  リターン・コード              --# 固定 #
    , ov_errmsg         OUT VARCHAR2                                --  ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_new_vd_data'; -- プログラム名
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
    ln_dummy      NUMBER;
--
    chk_vd_data_expt  EXCEPTION;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF (  (it_chk_customer IS NULL)
          OR
          (it_chk_customer <> hht_inv_tran_rec.customer_code)
       )
    THEN
      --  １レコード目、または、顧客が変更された場合のみチェック
      BEGIN
        --  VDコラムマスタの存在チェック
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_mst_vd_column     xmvc
              , xxcmm_cust_accounts     xca
        WHERE   xmvc.customer_id        =   xca.customer_id
        AND     xca.customer_code       =   hht_inv_tran_rec.customer_code
        AND     xmvc.column_no          =   1
        AND     ROWNUM  = 1;
        --
        --  データが存在する場合、エラー
        gb_vd_column_chk  :=  FALSE;
        ov_msg_code       :=  cv_msg_coi_10430;
        RAISE chk_vd_data_expt;
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          gb_vd_column_chk  :=  TRUE;
      END;
    END IF;
    --
    --  基準在庫数に少数点が含まれる場合エラー
    IF ((hht_inv_tran_rec.total_qnt - ROUND(hht_inv_tran_rec.total_qnt)) <> 0) THEN
      ov_msg_code   :=  gv_mst_coi_10372;
      RAISE chk_vd_data_expt;
    END IF;
    --
    --  基準在庫数が４桁以上の場合エラー
    IF (LENGTH(hht_inv_tran_rec.total_qnt) > 3) THEN
      ov_msg_code   :=  gv_msg_coi_10371;
      RAISE chk_vd_data_expt;
    END IF;
    --
    --  単価がNULLの場合エラー
    IF  (hht_inv_tran_rec.unit_price IS NULL) THEN
      ov_msg_code   :=  gv_msg_coi_10353;
      RAISE chk_vd_data_expt;
    END IF;
    --
    --  単価がマイナス値の場合エラー
    IF (hht_inv_tran_rec.unit_price < 0) THEN
      ov_msg_code   :=  gv_msg_coi_10059;
      RAISE chk_vd_data_expt;
    END IF;
    --
    --  H/C区分がNULLの場合エラー
    IF (hht_inv_tran_rec.hot_cold_div IS NULL) THEN
      ov_msg_code   :=  gv_msg_coi_10354;
      RAISE chk_vd_data_expt;
    END IF;
    --
  EXCEPTION
    -- *** VDコラムマスタ登録用データチェック例外ハンドラ ***
    WHEN chk_vd_data_expt THEN
      ov_retcode  :=  cv_status_warn;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_new_vd_data;
--
  /**********************************************************************************
   * Procedure Name   : put_warning_msg
   * Description      : エラー情報編集処理(A-15)
   ***********************************************************************************/
  PROCEDURE put_warning_msg(
      iv_msg_code   IN  VARCHAR2      --  メッセージコード
    , ov_errbuf     OUT VARCHAR2      --  エラー・メッセージ            --# 固定 #
    , ov_retcode    OUT VARCHAR2      --  リターン・コード              --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --  ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_warning_msg'; -- プログラム名
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
    lv_key_msg  VARCHAR2(5000);   --  キー情報
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --  警告件数カウント
    gn_warn_cnt2  :=  gn_warn_cnt2  + 1;
    --
    --  メッセージ生成（キー情報）
    lv_key_msg    :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_msg_coi_10342
                        , iv_token_name1    =>  gv_tkn_base_code
                        , iv_token_value1   =>  hht_inv_tran_rec.base_code
                        , iv_token_name2    =>  gv_tkn_record_type
                        , iv_token_value2   =>  hht_inv_tran_rec.record_type
                        , iv_token_name3    =>  gv_tkn_invoice_type
                        , iv_token_value3   =>  hht_inv_tran_rec.invoice_type
                        , iv_token_name4    =>  gv_tkn_dept_flag
                        , iv_token_value4   =>  hht_inv_tran_rec.department_flag
                        , iv_token_name5    =>  gv_tkn_invoice_no
                        , iv_token_value5   =>  hht_inv_tran_rec.invoice_no
                        , iv_token_name6    =>  gv_tkn_column_no
                        , iv_token_value6   =>  hht_inv_tran_rec.column_no
                        , iv_token_name7    =>  gv_tkn_item_code
                        , iv_token_value7   =>  hht_inv_tran_rec.item_code
                      );
    --
    --  メッセージ生成（エラー内容）
    IF    (iv_msg_code = cv_msg_coi_10430) THEN
      --  VDコラム登録済みエラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10430
                      );
    ELSIF (iv_msg_code = cv_msg_coi_10431) THEN
      --  基準在庫更新（コラム上限値）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10431
                        , iv_token_name1    =>  cv_tkn_max_column
                        , iv_token_value1   =>  TO_CHAR(gt_max_column_no)
                        , iv_token_name2    =>  gv_tkn_column_no
                        , iv_token_value2   =>  TO_CHAR(hht_inv_tran_rec.column_no)
                      );
    ELSIF (iv_msg_code = cv_msg_coi_10432) THEN
      --  基準在庫更新（顧客情報未取得）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10432
                      );
    ELSIF (iv_msg_code = cv_msg_coi_10435) THEN
      --  基準在庫更新（顧客移行）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10435
                      );
    ELSIF (iv_msg_code = cv_msg_coi_10436) THEN
      --  新規ベンダ基準在庫コラム重複
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10436
                        , iv_token_name1    =>  cv_tkn_cust_code
                        , iv_token_value1   =>  TO_CHAR(hht_inv_tran_rec.customer_code)
                        , iv_token_name2    =>  gv_tkn_column_no
                        , iv_token_value2   =>  TO_CHAR(hht_inv_tran_rec.column_no)
                      );
    ELSIF (iv_msg_code = gv_mst_coi_10372) THEN
      --  基準在庫更新（基準在庫小数点）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_mst_coi_10372
                        , iv_token_name1    =>  gv_tkn_total_qnt
                        , iv_token_value1   =>  TO_CHAR(hht_inv_tran_rec.total_qnt)
                      );
    ELSIF (iv_msg_code = gv_msg_coi_10371) THEN
      --  基準在庫更新（基準在庫上限値）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_msg_coi_10371
                        , iv_token_name1    =>  gv_tkn_total_qnt
                        , iv_token_value1   =>  TO_CHAR(hht_inv_tran_rec.total_qnt)
                      );
    ELSIF (iv_msg_code = gv_msg_coi_10353) THEN
      --  基準在庫更新（単価未設定エラー）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_msg_coi_10353
                      );
    ELSIF (iv_msg_code = gv_msg_coi_10059) THEN
      --  基準在庫更新（単価不整合）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_msg_coi_10059
                        , iv_token_name1    =>  gv_tkn_unit_price
                        , iv_token_value1   =>  TO_CHAR(hht_inv_tran_rec.unit_price)
                      );
    ELSIF (iv_msg_code = gv_msg_coi_10354) THEN
      --  基準在庫更新（H/C未設定エラー）エラー
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_msg_coi_10354
                      );
-- == 2011/12/07 V1.5 Added START ===============================================================
    ELSIF (iv_msg_code = cv_msg_coi_10449) THEN
      --  新規ベンダ基準在庫コラム登録日不一致
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10449
                      );
-- == 2011/12/07 V1.5 Added END   ===============================================================
    END IF;
    --
    --  メッセージの出力
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_key_msg || lv_errmsg
    );
    --
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_key_msg || lv_errmsg
    );
    --
    IF (iv_msg_code <> cv_msg_coi_10436) THEN
      --  HHTエラーリストに登録
      --  コラム番号重複による、データ破棄に関してはエラーリストに出力しない
      -- ===========================================
      -- 基準在庫変更データのエラーリスト表追加(A-7)
      -- ===========================================
      ins_standard_inv_err_list(
          ov_errbuf     =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
        , ov_retcode    =>  lv_retcode        --  リターン・コード              --# 固定 #
        , iov_errmsg    =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    --  HHT一時表を削除
    -- ===========================================
    -- HHT入出庫一時表のエラーレコード削除(A-8)
    -- ===========================================
    del_hht_inv_transactions(
        ov_errbuf     =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
      , ov_retcode    =>  lv_retcode        --  リターン・コード              --# 固定 #
      , ov_errmsg     =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_warning_msg;
--
  /**********************************************************************************
   * Procedure Name   : new_vd_column_create
   * Description      : 新規ベンダ基準在庫
   ***********************************************************************************/
  PROCEDURE new_vd_column_create(
      ov_errbuf     OUT VARCHAR2      --  エラー・メッセージ            --# 固定 #
    , ov_retcode    OUT VARCHAR2      --  リターン・コード              --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --  ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_vd_column_create'; -- プログラム名
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
    cv_target_rec_msg   CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90000';   --  対象件数メッセージ
    cv_success_rec_msg  CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90001';   --  成功件数メッセージ
    cv_skip_rec_msg     CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90003';   --  スキップ件数メッセージ
    cv_cnt_token        CONSTANT VARCHAR2(10)   :=  'COUNT';              --  件数メッセージ用トークン名
--
    -- *** ローカル変数 ***
    lv_message                VARCHAR2(5000);                                 --  メッセージ
    lt_msg_code               fnd_new_messages.message_name%TYPE;             --  警告メッセージコード
    lt_customer_id            hz_cust_accounts.cust_account_id%TYPE;          --  顧客ID
    lt_chk_customer           hz_cust_accounts.account_number%TYPE;           --  顧客コード（切替確認用）
    lt_chk_column             xxcoi_mst_vd_column.column_no%TYPE;             --  コラムNo（切替確認用）
    lt_sale_base_code         xxcmm_cust_accounts.sale_base_code%TYPE;        --  当月売上拠点
    lt_past_sale_base_code    xxcmm_cust_accounts.past_sale_base_code%TYPE;   --  前月売上拠点
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- #####################################################################################
    --  HHTからのVDコラムマスタ登録
    -- #####################################################################################
    --  初期化
    gn_target_cnt2  :=  0;
    gn_normal_cnt2  :=  0;
    gn_warn_cnt2    :=  0;
    --
    gb_customer_chk   :=  TRUE;
    gb_vd_column_chk  :=  TRUE;
    gb_sale_base_chk  :=  TRUE;
    gb_cust_grp_chk   :=  FALSE;
-- == 2011/12/07 V1.5 Added START ===============================================================
    gb_cust_date_chk  :=  TRUE;
    lt_msg_code       :=  NULL;
    lt_chk_customer   :=  NULL;
-- == 2011/12/07 V1.5 Added END   ===============================================================
    lt_chk_column     :=  0;
    --
    --  メッセージヘッダの出力（新規ベンダ基準在庫）
    lv_message  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  gv_msg_kbn_coi
                      , iv_name           =>  cv_msg_coi_10434
                    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_message
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_message
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- ===============================
    --  基準在庫変更データ抽出(A-2)
    -- ===============================
    OPEN  hht_inv_tran2_cur;
    --
    <<vd_create_loop>>
    LOOP
      --
      FETCH hht_inv_tran2_cur INTO  hht_inv_tran_rec;
      --
      -- ===============================
      --  コラム上限値チェック(A-11)
      -- ===============================
      IF  ( (hht_inv_tran_rec.column_no > gt_max_column_no)
            AND
            (hht_inv_tran2_cur%FOUND)
          )
      THEN
        --  データが取得された場合のみ
        --  終了ステータス警告
        ov_retcode  :=  cv_status_warn;
        --
        --  登録可能コラム数の上限を超えている場合、上限値以上の全データをエラーとする
        <<chk_max_clm_loop>>
        LOOP
          --  対象件数カウント
          gn_target_cnt2  :=  gn_target_cnt2 + 1;
          --
          --  警告メッセージ、HHTエラーリストの出力と、HHT入出庫一時表の削除
          put_warning_msg(
              iv_msg_code     =>  cv_msg_coi_10431
            , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
            , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
            , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
          );
          --  処理完了ステータス正常以外の場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          --
          --  次データ取得（上限値以下になるか、対象データがなくなるまで継続）
          FETCH hht_inv_tran2_cur INTO  hht_inv_tran_rec;
          EXIT WHEN ((hht_inv_tran_rec.column_no  <=  gt_max_column_no) OR (hht_inv_tran2_cur%NOTFOUND));
          --
        END LOOP chk_max_clm_loop;
      END IF;
      --
      --
      IF  ( (lt_chk_customer IS NULL)
            OR
            (lt_chk_customer <> hht_inv_tran_rec.customer_code)
            OR
            (hht_inv_tran2_cur%NOTFOUND)
          )
      THEN
        --  １レコード目、顧客コードが変更、全データ処理済のいずれかの場合以下を実行
        --
        -- ===============================
        --  VDコラムマスタの登録(A-12)
        -- ===============================
        IF  ( (lt_chk_customer IS NOT NULL)
              AND
              (gb_customer_chk)
              AND
              (gb_vd_column_chk)
              AND
              (gb_sale_base_chk)
              AND
              (gb_cust_grp_chk)
            )
        THEN
          --  １レコード目以外、かつ、顧客が取得されている、VDコラムマスタが存在しない、
          --  売上拠点不整合がない、１顧客で最低１コラム有効なデータが存在する場合
          ins_vd_column(
              ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
            , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
            , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
          );
          --  処理完了ステータス正常以外の場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        --
        -- ===============================
        --  登録コラム情報初期化(A-13)
        -- ===============================
        --  顧客情報が変わった場合、VDコラム情報を保持する変数を初期化
        gt_new_vd_data.DELETE;
        --  顧客内有効データ有無フラグ
        gb_cust_grp_chk :=  FALSE;
-- == 2011/12/07 V1.5 Added START ===============================================================
        --  VDコラムマスタ存在チェックフラグ
        gb_vd_column_chk := TRUE;
        --  顧客内伝票日付不一致チェックフラグ
        gb_cust_date_chk := TRUE;
-- == 2011/12/07 V1.5 Added END   ===============================================================
        --
        IF  (hht_inv_tran2_cur%FOUND) THEN
          BEGIN
            --  伝票日付の前月、当月を設定
            gv_ins_vd_type  :=  CASE  WHEN  TO_CHAR(hht_inv_tran_rec.invoice_date, cv_day_form_m) = TO_CHAR(gd_process_date, cv_day_form_m)
                                        THEN  cv_month_type_1
                                        ELSE  cv_month_type_0
                                END;
            --
            --  顧客ID取得
            SELECT  hca.cust_account_id       customer_id
                  , xca.sale_base_code        sale_base_code
                  , xca.past_sale_base_code   past_sale_base_code
            INTO    lt_customer_id
                  , lt_sale_base_code
                  , lt_past_sale_base_code
            FROM    hz_cust_accounts        hca
                  , xxcmm_cust_accounts     xca
            WHERE   hca.account_number            =   hht_inv_tran_rec.customer_code
            AND     hca.cust_account_id           =   xca.customer_id
            AND     hht_inv_tran_rec.base_code    =   CASE  WHEN  gv_ins_vd_type = cv_month_type_1
                                                              THEN  NVL(xca.sale_base_code,      cv_dummy_value)
                                                              ELSE  NVL(xca.past_sale_base_code, cv_dummy_value)
                                                      END
            AND     xxcoi_common_pkg.chk_aff_active(NULL, hht_inv_tran_rec.base_code, NULL, hht_inv_tran_rec.invoice_date) = cv_yes
            AND     ROWNUM  = 1;
            --
            --  売上拠点チェック（顧客移行対応）
            IF  ( (gv_ins_vd_type = cv_month_type_0)
                  AND
                  (lt_sale_base_code <> lt_past_sale_base_code)
                )
            THEN
              --  前月伝票で、顧客の当月、前月売上拠点が不一致の場合
              gb_sale_base_chk  :=  FALSE;
              ov_retcode        :=  cv_status_warn;
            ELSE
              gb_sale_base_chk  :=  TRUE;
            END IF;
            --
            --  顧客情報が取得された場合
            gb_customer_chk   :=  TRUE;
-- == 2011/12/07 V1.5 Added START ===============================================================
            --  今回対象顧客の伝票日付チェック
            OPEN chk_cust_date_cur(iv_customer_code => hht_inv_tran_rec.customer_code);
            --
            <<chk_cust_date_loop>>
            LOOP
              FETCH chk_cust_date_cur INTO chk_cust_date_rec;
              EXIT WHEN ( chk_cust_date_cur%NOTFOUND );
                --  顧客内で伝票日付が不一致の場合
                IF ( hht_inv_tran_rec.invoice_date <> chk_cust_date_rec.invoice_date ) THEN
                  --  顧客内伝票日付不一致チェックフラグ
                  gb_cust_date_chk := FALSE;
                  ov_retcode       := cv_status_warn;
                END IF;
            END LOOP chk_cust_date_loop;
            --
            CLOSE chk_cust_date_cur;
-- == 2011/12/07 V1.5 Added END   ===============================================================
            --
            --  コラムNo1から、今回対象の有効最大コラムNoまでを初期化
            <<vd_format_loop>>
            FOR ln_cnt  IN  1 .. hht_inv_tran_rec.column_no LOOP
              gt_new_vd_data(ln_cnt).customer_id          :=  lt_customer_id;
              gt_new_vd_data(ln_cnt).column_no            :=  ln_cnt;
              gt_new_vd_data(ln_cnt).item_id              :=  NULL;
              gt_new_vd_data(ln_cnt).inventory_quantity   :=  0;
              gt_new_vd_data(ln_cnt).price                :=  NULL;
              gt_new_vd_data(ln_cnt).hot_cold             :=  NULL;
            END LOOP  vd_format_loop;
            --
          EXCEPTION
            WHEN  NO_DATA_FOUND THEN
              --  顧客情報取得エラー
              gb_customer_chk   :=  FALSE;
              ov_retcode        :=  cv_status_warn;
          END;
          --
        END IF;
      END IF;
      --
      --
      --  処理の終了
      EXIT  WHEN  hht_inv_tran2_cur%NOTFOUND;
      gn_target_cnt2  :=  gn_target_cnt2 + 1;
      --
      --
      IF NOT(gb_customer_chk) THEN
        --  顧客IDが取得できなかった場合（同一顧客のスキップ）
        --  警告メッセージ、HHTエラーリストの出力と、HHT入出庫一時表の削除
        put_warning_msg(
            iv_msg_code     =>  cv_msg_coi_10432
          , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
          , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
          , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
        );
        --  処理完了ステータス正常以外の場合
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
      ELSIF NOT(gb_vd_column_chk) THEN
        --  VDコラムマスタが登録済みの場合（同一顧客のスキップ）
        put_warning_msg(
            iv_msg_code     =>  cv_msg_coi_10430
          , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
          , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
          , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
        );
        --  処理完了ステータス正常以外の場合
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2011/12/07 V1.5 Added START ===============================================================
      ELSIF NOT(gb_cust_date_chk) THEN
        --  同一顧客内での伝票日付の不一致（同一顧客のスキップ）
        put_warning_msg(
            iv_msg_code     =>  cv_msg_coi_10449
          , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
          , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
          , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
        );
        --  処理完了ステータス正常以外の場合
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2011/12/07 V1.5 Added END   ===============================================================
      ELSIF NOT(gb_sale_base_chk) THEN
        --  前月、当月売上拠点の不一致（同一顧客のスキップ）
        put_warning_msg(
            iv_msg_code     =>  cv_msg_coi_10435
          , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
          , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
          , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
        );
        --  処理完了ステータス正常以外の場合
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
      ELSIF ( (NVL(lt_chk_customer, cv_dummy_value) = hht_inv_tran_rec.customer_code)
              AND
              (lt_chk_column = hht_inv_tran_rec.column_no)
            )
      THEN
        --  １レコード前と同一顧客、同一コラムNoの場合（同一コラムのスキップ）
        put_warning_msg(
            iv_msg_code     =>  cv_msg_coi_10436
          , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
          , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
          , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
        );
        --  本処理はデータスキップするが正常終了扱いとする。（警告ステータスを立てない）
        --  メッセージ出力処理でカウントされた警告件数をクリア
        gn_warn_cnt2 := gn_warn_cnt2 - 1;
        --
        --  処理完了ステータス正常以外の場合
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
      ELSE
        -- =======================================
        -- 新規ベンダ基準在庫妥当性チェック(A-14)
        -- =======================================
        chk_new_vd_data(
            it_chk_customer =>  lt_chk_customer   --  顧客コード（切替確認用）
          , ov_msg_code     =>  lt_msg_code       --  メッセージコード
          , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
          , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
          , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF  (lv_retcode = cv_status_normal)  THEN
          --  有効な登録データが取得されたためTRUEを設定
          gb_cust_grp_chk   :=  TRUE;
          --
          --  チェック処理で問題がなかった場合
          --  資材取引一時表に追加
          -- =====================================
          -- 基準在庫変更ワークテーブルの追加(A-4)
          -- =====================================
          ins_tmp_svd_tran_date(
              ov_errbuf       =>  lv_errbuf       --  エラー・メッセージ            --# 固定 #
            , ov_retcode      =>  lv_retcode      --  リターン・コード              --# 固定 #
            , ov_errmsg       =>  lv_errmsg       --  ユーザー・エラー・メッセージ  --# 固定 #
          );
          --
          --  HHT入出庫一時表の更新
          -- ========================================
          -- HHT入出庫一時表の処理ステータス更新(A-6)
          -- ========================================
          upd_hht_inv_transactions(
              ov_errbuf       =>  lv_errbuf       --  エラー・メッセージ            --# 固定 #
            , ov_retcode      =>  lv_retcode      --  リターン・コード              --# 固定 #
            , ov_errmsg       =>  lv_errmsg       --  ユーザー・エラー・メッセージ  --# 固定 #
          );
          --
          IF (hht_inv_tran_rec.total_qnt > 0) THEN
            --  VDコラムマスタ作成用変数にデータを保持（顧客IDとコラムNoは初期化時に設定済み）
            --  0の場合は、初期化時の設定のままとする
            gt_new_vd_data(hht_inv_tran_rec.column_no).item_id              :=  hht_inv_tran_rec.item_id;
            gt_new_vd_data(hht_inv_tran_rec.column_no).inventory_quantity   :=  hht_inv_tran_rec.total_qnt;
            gt_new_vd_data(hht_inv_tran_rec.column_no).price                :=  hht_inv_tran_rec.unit_price;
            gt_new_vd_data(hht_inv_tran_rec.column_no).hot_cold             :=  hht_inv_tran_rec.hot_cold_div;
          END IF;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --  チェック処理A-14警告時
          ov_retcode  :=  cv_status_warn;
          --  HHT入出庫一時表の削除
          put_warning_msg(
              iv_msg_code     =>  lt_msg_code       --  チェック処理で発生したエラーのメッセージコード
            , ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
            , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
            , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
          );
          --
          --  処理完了ステータス正常以外の場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        ELSE
          --  チェック処理A-14エラー時
          RAISE global_process_expt;
        END IF;
      END IF;
      --
      lt_chk_customer   :=  hht_inv_tran_rec.customer_code;
      lt_chk_column     :=  hht_inv_tran_rec.column_no;
    END LOOP  vd_create_loop;
    --
    CLOSE hht_inv_tran2_cur;
    --
    IF (gn_target_cnt2 = 0) THEN
      --  対象データなしメッセージ
      lv_message  :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  gv_msg_kbn_coi
                        , iv_name           =>  gv_msg_coi_00008
                      );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      --
    END IF;
    --
    --  成功件数 = 対象件数 - 警告件数
    gn_normal_cnt2  :=  gn_target_cnt2 - gn_warn_cnt2;
    --
    -- ===========================================
    -- 終了処理(A-10)
    -- ===========================================
    --  空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  gv_msg_kbn_ccp
                      , iv_name           =>  cv_target_rec_msg
                      , iv_token_name1    =>  cv_cnt_token
                      , iv_token_value1   =>  TO_CHAR(gn_target_cnt2)
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  gv_msg_kbn_ccp
                      , iv_name           =>  cv_success_rec_msg
                      , iv_token_name1    =>  cv_cnt_token
                      , iv_token_value1   =>  TO_CHAR(gn_normal_cnt2)
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- スキップ件数出力
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_msg_kbn_ccp
                    , iv_name           =>  cv_skip_rec_msg
                    , iv_token_name1    =>  cv_cnt_token
                    , iv_token_value1   =>  TO_CHAR(gn_warn_cnt2)
                    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
--
  EXCEPTION
    -- *** ロック取得例外ハンドラ ***
    WHEN lock_expt THEN
       -- 対象件数のカウントアップ
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ロックエラーメッセージ(HHT入出庫一時表)
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  gv_msg_kbn_coi
                        , iv_name         =>  gv_msg_coi_10055
                      );
      lv_errbuf :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;                                                    --# 任意 #
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  :=  cv_status_error;                                              --# 任意 #
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END new_vd_column_create;
-- == 2011/04/19 V1.4 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ(A-2)
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_message          VARCHAR2(5000);                                   -- メッセージ出力用
    lt_item_code        mtl_system_items_b.segment1%TYPE;   -- 品目コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- 取引作成件数の初期化
    gn_cre_tran_cnt := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
-- == 2011/04/19 V1.4 Added START ===============================================================
    -- ===============================
    -- 新規ベンダ基準在庫
    -- ===============================
    new_vd_column_create(
        ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
      , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
      , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
    );
    IF (lv_retcode = cv_status_warn) THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    --  メッセージヘッダの出力（ベンダ初回）
    lv_message  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  gv_msg_kbn_coi
                      , iv_name           =>  cv_msg_coi_10433
                    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_message
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_message
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- == 2011/04/19 V1.4 Added END   ===============================================================
    -- ===============================
    -- 基準在庫変更データ抽出(A-2)
    -- ===============================
    -- カーソルオープン
    OPEN hht_inv_tran_cur;
--
    -- 基準在庫変更抽出ループ
    <<hht_inv_tran_loop>>
    LOOP
      FETCH hht_inv_tran_cur INTO hht_inv_tran_rec;
      EXIT hht_inv_tran_loop WHEN hht_inv_tran_cur%NOTFOUND;
--
      -- 対象件数のカウントアップ
      gn_target_cnt := gn_target_cnt + 1;
--
      -- =====================================
      -- 基準在庫変更データ妥当性チェック(A-3)
      -- =====================================
      chk_vd_column_mst_info(
        lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,lv_retcode         -- リターン・コード             --# 固定 #
       ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- リターン・コードが正常の場合
      IF (lv_retcode = cv_status_normal) THEN
        -- =====================================
        -- 基準在庫変更ワークテーブルの追加(A-4)
        -- =====================================
        ins_tmp_svd_tran_date(
          lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,lv_retcode        -- リターン・コード             --# 固定 #
         ,lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================
        -- VDコラムマスタの更新(A-5)
        -- =====================================
        upd_xxcoi_mst_vd_column(
          lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,lv_retcode        -- リターン・コード             --# 固定 #
         ,lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ========================================
        -- HHT入出庫一時表の処理ステータス更新(A-6)
        -- ========================================
        upd_hht_inv_transactions(
          lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,lv_retcode        -- リターン・コード             --# 固定 #
         ,lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      -- リターン・コードが警告で且つ、VDコラムマスタのロック取得成功の場合
      ELSIF (lv_retcode = cv_status_warn)
        AND (gv_vd_is_lock_flg = gv_vd_get_lock) THEN
        -- ===========================================
        -- 基準在庫変更データのエラーリスト表追加(A-7)
        -- ===========================================
        ins_standard_inv_err_list(
          lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,lv_retcode        -- リターン・コード             --# 固定 #
         ,lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===========================================
        -- HHT入出庫一時表のエラーレコード削除(A-8)
        -- ===========================================
        del_hht_inv_transactions(
          lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,lv_retcode        -- リターン・コード             --# 固定 #
         ,lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      -- リターン・コードがエラーの場合
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP hht_inv_tran_loop;
--
    -- カーソルクローズ
    CLOSE hht_inv_tran_cur;
--
    -- 対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- 対象データ無しメッセージ
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_kbn_coi
                     ,iv_name         => gv_msg_coi_00008);
      -- ファイルに出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_message);
--
-- == 2011/04/19 V1.4 Deleted START ===============================================================
--    -- 対象件数が1件以上存在する場合
--    ELSE
--      -- ===========================================
--      -- 基準在庫変更データの資材取引OIF追加(A-9)
--      -- ===========================================
--      ins_mtl_transactions_if(
--        lv_errbuf         -- エラー・メッセージ           --# 固定 #
--       ,lv_retcode        -- リターン・コード             --# 固定 #
--       ,lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
----
--      IF (lv_retcode <> cv_status_normal) THEN
--        RAISE global_process_expt;
--      END IF;
-- == 2011/04/19 V1.4 Deleted END   ===============================================================
    END IF;
-- == 2011/04/19 V1.4 Added START ===============================================================
    --
    IF (gn_target_cnt <> 0 OR gn_target_cnt2 <> 0) THEN
      --  新規ベンダ基準在庫、ベンダ初回のいずれかに対象が１レコードでも存在する場合
      --
      -- ===========================================
      -- 基準在庫変更データの資材取引OIF追加(A-9)
      -- ===========================================
      ins_mtl_transactions_if(
          ov_errbuf       =>  lv_errbuf         --  エラー・メッセージ            --# 固定 #
        , ov_retcode      =>  lv_retcode        --  リターン・コード              --# 固定 #
        , ov_errmsg       =>  lv_errmsg         --  ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- == 2011/04/19 V1.4 Added END   ===============================================================
--
    -- 警告件数またはスキップ件数が1件以上存在する場合
    IF (gn_error_cnt > 0)
      OR (gn_warn_cnt > 0) THEN
      -- リターン・コードを警告に再設定する
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- ロック取得エラー
    WHEN lock_expt THEN
       -- 対象件数のカウントアップ
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ロックエラーメッセージ(HHT入出庫一時表)
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10055);
-- == 2011/04/19 V1.4 Added START ===============================================================
      lv_errbuf :=  lv_errmsg;
-- == 2011/04/19 V1.4 Added END   ===============================================================
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ(A-10)
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode       OUT VARCHAR2      --   リターン・コード    --# 固定 #
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_err_cnt_1       CONSTANT NUMBER        := 1;                  -- エラー時取得件数設定用
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数の設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
--
    -- リターン・コードが「エラー」以外の場合
    ELSE
      -- 成功件数の設定
      gn_normal_cnt := gn_target_cnt - gn_error_cnt - gn_warn_cnt;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===========================================
    -- 終了処理(A-10)
    -- ===========================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- == 2011/04/19 V1.4 Modified START ===============================================================
--    --エラー件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => gv_msg_kbn_ccp
--                    ,iv_name         => cv_error_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_kbn_ccp
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- == 2011/04/19 V1.4 Modified END   ===============================================================
--
    --取引作成件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_coi
                    ,iv_name         => gv_msg_coi_10335
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_cre_tran_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,  buff   => ''
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_msg_kbn_ccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOI003A15C;
/
