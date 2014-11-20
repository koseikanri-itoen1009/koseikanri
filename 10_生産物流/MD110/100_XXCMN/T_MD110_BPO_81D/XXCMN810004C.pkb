CREATE OR REPLACE PACKAGE BODY XXCMN810004C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMN810004C(body)
 * Description      : CSVアップロードから品目マスタを一括登録します。
 * MD.050           : 品目マスタ一括アップロード T_MD050_BPO_810
 * Version          : Issue1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_exists_category    カテゴリ存在チェック
 *  chk_exists_lookup      LOOKUP表存在チェック
 *  proc_comp              終了処理 (D-8)
 *  ins_data               データ登録 (D-5)
 *  proc_disc_categ_ref    Disc品目カテゴリ割当 (D-7)
 *  get_disc_item_data     Disc品目情報取得 (D-6)
 *                            ・proc_disc_categ_ref
 *  validate_item          品目マスタ一括アップロードワークデータ妥当性チェック (D-4)
 *                            ・chk_exists_lookup
 *                            ・chk_exists_category
 *  loop_main              品目マスタ一括アップロードワークデータ取得 (D-3)
 *                            ・validate_item
 *                            ・ins_data
 *                            ・get_disc_item_data
 *  get_if_data            ファイルアップロードIFデータ取得 (D-2)
 *  proc_init              初期処理 (D-1)
 *  submain                メイン処理プロシージャ
 *                            ・proc_init
 *                            ・get_if_data
 *                            ・loop_main
 *                            ・proc_comp
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/11/20    1.0   K.Boku           main新規作成
 *  2013/04/18    1.1   S.Niki           [E_本稼動_10588]  倉庫品目チェック、設定値修正
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1'; --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2'; --異常:2
  cv_sts_cd_normal          CONSTANT VARCHAR2(1) := 'C';
  cv_sts_cd_warn            CONSTANT VARCHAR2(1) := 'G';
  cv_sts_cd_error           CONSTANT VARCHAR2(1) := 'E';
  --WHOカラム
  gn_created_by             CONSTANT NUMBER  := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE    := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER  := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE    := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER  := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER  := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER  := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER  := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE    := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  lock_expt                EXCEPTION;      -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCMN810004C';     -- パッケージ名
--
  -- メッセージ
  cv_msg_xxcmn_10002       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10002';  -- プロファイルエラー
  cv_msg_xxcmn_10617       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10617';  -- マスタ存在チェックエラー
  cv_msg_xxcmn_10618       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10618';  -- 品目重複エラー
  cv_msg_xxcmn_10619       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10619';  -- 品目7桁必須エラー
  cv_msg_xxcmn_10620       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10620';  -- 倉庫品目7桁必須エラー
  cv_msg_xxcmn_10621       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10621';  -- 基準単位エラー
  cv_msg_xxcmn_10622       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10622';  -- データ抽出エラー
  cv_msg_xxcmn_10623       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10623';  -- 必須エラー
  cv_msg_xxcmn_10624       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10624';  -- 出荷換算単位チェックエラー
  cv_msg_xxcmn_10625       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10625';  -- 入力制限チェックエラー
  cv_msg_xxcmn_10626       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10626';  -- データ登録エラー
  cv_msg_xxcmn_10627       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10627';  -- OPM品目トリガー起動ノート
  cv_msg_xxcmn_10628       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10628';  -- 業務日付取得失敗エラー
  cv_msg_xxcmn_10629       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10629';  -- 入出庫換算単位エラー
  cv_msg_xxcmn_10630       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10630';  -- データ削除エラー
  cv_msg_xxcmn_10631       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10631';  -- ファイルアップロード名称ノート
  cv_msg_xxcmn_10632       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10632';  -- CSVファイル名ノート
  cv_msg_xxcmn_10633       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10633';  -- FILE_IDノート
  cv_msg_xxcmn_10634       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10634';  -- フォーマットパターンノート
  cv_msg_xxcmn_10635       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10635';  -- 入力パラメータNULLエラー
  cv_msg_xxcmn_10636       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10636';  -- データ抽出エラー
  cv_msg_xxcmn_10637       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10637';  -- ロックエラー
  cv_msg_xxcmn_10638       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10638';  -- 項目数エラー
  cv_msg_xxcmn_10639       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10639';  -- ファイル項目チェックエラー
  cv_msg_xxcmn_10640       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10640';  -- BLOBデータ変換エラー
-- Ver.1.1 S.Niki ADD START
  cv_msg_xxcmn_10641       CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10641';  -- 倉庫品目コード存在チェックエラー
-- Ver.1.1 S.Niki ADD END
--
  -- トークン
  cv_tkn_value             CONSTANT VARCHAR2(20)  := 'VALUE';            -- 値
  cv_tkn_table             CONSTANT VARCHAR2(20)  := 'TABLE';            -- テーブル名
  cv_tkn_errmsg            CONSTANT VARCHAR2(20)  := 'ERR_MSG';          -- エラー内容
  cv_tkn_input_item_code   CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';  -- WKの品目コード
  cv_tkn_item_um           CONSTANT VARCHAR2(20)  := 'ITEM_UM';          -- 基準単位
  cv_tkn_msg               CONSTANT VARCHAR2(20)  := 'MSG';              -- コンカレント終了メッセージ
  cv_tkn_col_name          CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';   -- 項目名
  cv_tkn_req_id            CONSTANT VARCHAR2(20)  := 'REQ_ID';           -- 要求ID
  cv_tkn_up_name           CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';      -- ファイルアップロード名称
  cv_tkn_file_id           CONSTANT VARCHAR2(20)  := 'FILE_ID';          -- ファイルID
  cv_tkn_file_format       CONSTANT VARCHAR2(20)  := 'FORMAT';           -- フォーマット
  cv_tkn_file_name         CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- ファイル名
  cv_tkn_count             CONSTANT VARCHAR2(20)  := 'COUNT';            -- 処理件数
  cv_tkn_ng_profile        CONSTANT VARCHAR2(20)  := 'NG_PROFILE';       -- プロファイルNG
  cv_tkn_input_line_no     CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';    -- 行番号
--
  -- アプリケーション短縮名
  cv_appl_name_xxcmn       CONSTANT VARCHAR2(5)   := 'XXCMN';            -- XXCMN
--
  -- プロファイル
  cv_prf_item_num          CONSTANT VARCHAR2(60)  := 'XXCMN_ITEM_NUM';                 -- アップロード項目数
  cv_prf_ctg_item_prod     CONSTANT VARCHAR2(60)  := 'XXCMN_PRODUCT_DIV_CODE';         -- 商品製品区分
  cv_prf_ctg_hon_prod      CONSTANT VARCHAR2(60)  := 'XXCMN_ARTI_DIV_CODE';            -- 本社商品区分
  cv_prf_ctg_mark_pg       CONSTANT VARCHAR2(60)  := 'XXCMN_MARKE_CROWD_CODE';         -- マーケ用群コード
  cv_prf_ctg_gun_code      CONSTANT VARCHAR2(60)  := 'XXCMN_CATEGORY_NAME_OTGUN';      -- 群コード
  cv_prf_ctg_item_div      CONSTANT VARCHAR2(60)  := 'XXCMN_ITEM_CLASS';               -- 品目区分
  cv_prf_ctg_inout_class   CONSTANT VARCHAR2(60)  := 'XXCMN_IN_OUT_CLASS';             -- 内外区分
  cv_prf_ctg_fact_pg       CONSTANT VARCHAR2(60)  := 'XXCMN_CATEGORY_NAME_KJGUN';      -- 工場群コード
  cv_prf_ctg_acnt_pg       CONSTANT VARCHAR2(60)  := 'XXCMN_ACNT_CROWD_CODE';          -- 経理部用群コード
  cv_prf_ctg_seisakugun    CONSTANT VARCHAR2(60)  := 'XXCMN_POLICY_GROUP_CODE';        -- 政策群コード
  cv_prf_ctg_baracha_class CONSTANT VARCHAR2(60)  := 'XXCMN_DIV_TEA_CODE';             -- バラ茶区分
  cv_prf_ctg_product_div   CONSTANT VARCHAR2(60)  := 'XXCMN_PROD_CLASS';               -- 商品区分
  cv_prf_ctg_quality_class CONSTANT VARCHAR2(60)  := 'XXCMN_QUALITY_CLASS';            -- 品質区分
  cv_prf_mst_org_code      CONSTANT VARCHAR2(60)  := 'XXCMN_MST_ORG_CODE';             -- マスタ在庫組織コード
--
  -- LOOKUP
  cv_lookup_need_test      CONSTANT VARCHAR2(30)  := 'XXCMN_NEED_TEST';                -- 試験有無区分
  cv_lookup_type           CONSTANT VARCHAR2(30)  := 'XXCMN_D01';                      -- 型種別
  cv_lookup_product_class  CONSTANT VARCHAR2(30)  := 'XXCMN_D02';                      -- 商品分類
  cv_lookup_uom_class      CONSTANT VARCHAR2(30)  := 'XXCMN_UOM_CLASS';                -- 単位区分
  cv_lookup_trace_class    CONSTANT VARCHAR2(30)  := 'XXCMN_TRACE_CLASS';              -- トレース区分
  cv_lookup_rate           CONSTANT VARCHAR2(30)  := 'XXCMN_RATE';                     -- 率区分
  cv_lookup_item_def       CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DEF';                 -- 登録項目定義
  cv_lookup_product_type   CONSTANT VARCHAR2(30)  := 'XXCMN_D03';                      -- 商品種別
  cv_lookup_bottle_class   CONSTANT VARCHAR2(30)  := 'XXCMN_BOTTLE_CLASS';             -- 容器区分
  cv_lookup_inventory_chk_class
                           CONSTANT VARCHAR2(30)  := 'XXCMN_INVENTORY_CHK_CLASS';      -- 棚卸区分
  cv_lookup_we_ca_class    CONSTANT VARCHAR2(30)  := 'XXCMN_WEIGHT_CAPACITY_CLASS';    -- 重量容積区分
  cv_lookup_vendor_deriday_ty
                           CONSTANT VARCHAR2(30)  := 'XXCMN_VENDOR_PRICE_DERI_DAY_TY'; -- 導出日タイプ
  cv_lookup_shelf_life_class
                           CONSTANT VARCHAR2(30)  := 'XXCMN_SHELF_LIFE_CLASS';         -- 賞味期間区分
  cv_lookup_destination_diy
                           CONSTANT VARCHAR2(30)  := 'XXCMN_DESTINATION_DIV';          -- 仕向区分
  cv_lookup_cost_management
                           CONSTANT VARCHAR2(30)  := 'XXCMN_COST_MANAGEMENT';          -- 原価管理区分
--
  -- テーブル名
  cv_table_flv             CONSTANT VARCHAR2(30)  := 'LOOKUP表';
  cv_table_mcv             CONSTANT VARCHAR2(30)  := 'カテゴリ';
  cv_table_iimb            CONSTANT VARCHAR2(30)  := 'OPM品目マスタ';
  cv_table_ximb            CONSTANT VARCHAR2(30)  := 'OPM品目アドオン';
  cv_table_mic             CONSTANT VARCHAR2(30)  := 'Disc品目カテゴリ割当';
  cv_table_xwibr           CONSTANT VARCHAR2(60)  := '品目マスタ一括アップロードワーク';
  cv_table_xmfui           CONSTANT VARCHAR2(60)  := 'ファイルアップロードIF';
  cv_table_def             CONSTANT VARCHAR2(60)  := '品目マスタ一括アップロードワーク定義情報';
  -- フォーマット
  cv_file_id               CONSTANT VARCHAR2(20)  := 'FILE_ID';                     -- ファイルID
  cv_format_check          CONSTANT VARCHAR2(20)  := 'フォーマットパターン';        -- フォーマット
  cv_upload_name           CONSTANT VARCHAR2(30)  := '品目マスタ一括アップロード';  -- オブジェクト
--
  -- 項目
  cv_judge_times_num       CONSTANT VARCHAR2(30)  := '判定回数';
  cv_order_judge_times_num CONSTANT VARCHAR2(30)  := '発注可能判定回数';
  cv_inspection_lt         CONSTANT VARCHAR2(30)  := '検査L/T';
  cv_item_batch_regist     CONSTANT VARCHAR2(30)  := '品目マスタ一括アップロード'; 
  cv_mst_org_id            CONSTANT VARCHAR2(30)  := 'マスタ在庫組織ID'; 
  cv_null_ok               CONSTANT VARCHAR2(10)  := 'NULL_OK';           -- 任意項目
  cv_null_ng               CONSTANT VARCHAR2(10)  := 'NULL_NG';           -- 必須項目
  cv_varchar               CONSTANT VARCHAR2(10)  := 'VARCHAR2';          -- 文字列
  cv_number                CONSTANT VARCHAR2(10)  := 'NUMBER';            -- 数値
  cv_date                  CONSTANT VARCHAR2(10)  := 'DATE';              -- 日付
  cv_varchar_cd            CONSTANT VARCHAR2(1)   := '0';                 -- 文字列項目
  cv_number_cd             CONSTANT VARCHAR2(1)   := '1';                 -- 数値項目
  cv_date_cd               CONSTANT VARCHAR2(1)   := '2';                 -- 日付項目
  cv_not_null              CONSTANT VARCHAR2(1)   := '1';                 -- 必須
  cv_msg_comma             CONSTANT VARCHAR2(1)   := ',';                 -- カンマ
  cv_msg_comma_double      CONSTANT VARCHAR2(2)   := '、';                -- カンマ(全角)
--
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                 -- YES
  cv_0                     CONSTANT VARCHAR2(1)   := '0';                 -- 0
  cv_max_date              CONSTANT VARCHAR2(10)  := '9999/12/31';        -- MAX日付
  cv_date_fmt_std          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- 日付
--
  -- ステータス
  cv_status_val_normal     CONSTANT VARCHAR2(10)  := '正常';              -- 正常:0
  cv_status_val_warn       CONSTANT VARCHAR2(10)  := '警告';              -- 警告:1
  cv_status_val_error      CONSTANT VARCHAR2(10)  := 'エラー';            -- エラー:2
--
  cv_prog_opmitem_trigger  CONSTANT VARCHAR2(20)  := 'XXCMN810003C';      -- OPM品目トリガー起動
--
-- Ver.1.1 S.Niki ADD START
  -- 品目コード桁数
  cn_item_code_length      CONSTANT NUMBER        := 7;     -- 品目コード桁数
-- Ver.1.1 S.Niki ADD END
  -- 基準単位
  cv_item_um_0             CONSTANT VARCHAR2(2)   := '0';   -- 基準単位チェック条件
  cv_item_um_space         CONSTANT VARCHAR2(2)   := ' ';   -- 基準単位チェック条件
  -- 重量容積区分
  cv_weight                CONSTANT VARCHAR2(1)   := '1';   -- 重量
  cv_volume                CONSTANT VARCHAR2(1)   := '2';   -- 容積
  -- 試験有無区分
  cv_exam_class_0          CONSTANT NUMBER        := '0';   -- 「無」
  cv_exam_class_1          CONSTANT NUMBER        := '1';   -- 「有」
  -- ロット管理区分
  cv_lot_ctl_class_yes     CONSTANT VARCHAR2(3)   := '1';   -- 有
  cv_lot_ctl_class_no      CONSTANT VARCHAR2(3)   := '0';   -- 無
  -- 自動ロット採番有効
  cv_autolot_active_indicate_1
                           CONSTANT VARCHAR2(1)   := '1';   -- 有
  cv_autolot_active_indicate_0   
                           CONSTANT VARCHAR2(1)   := '0';   -- 無
  -- ロット・サフィックス
  cv_lot_suffix_0          CONSTANT VARCHAR2(1)   := '0';
  -- 判定回数
  cn_judge_times_num_1     CONSTANT VARCHAR2(1)   := 1;   -- 1回
  cn_judge_times_num_2     CONSTANT VARCHAR2(1)   := 2;   -- 2回
  cn_judge_times_num_3     CONSTANT VARCHAR2(1)   := 3;   -- 3回
  -- 二重管理
  cv_dualum                CONSTANT VARCHAR2(1)   := '0';   -- 非二重
  -- 保管場所
  cv_loct_ctl              CONSTANT VARCHAR2(1)   := '1';   -- 検証済み
  -- 照合
  cv_match_type            CONSTANT VARCHAR2(1)   := '3';   -- 請求書購買オーダー受入
  -- 出荷区分
  cv_shipping_class        CONSTANT VARCHAR2(1)   := '0';   -- 出荷不可
  -- 品目区分
  cv_item_class            CONSTANT VARCHAR2(1)   := '2';   -- 資材
  -- 入出庫換算単位
  cv_mtl_units_of_measure
                           CONSTANT VARCHAR2(2)   := 'CS';  -- CS
  -- 廃止区分
  cv_inactive_class        CONSTANT VARCHAR2(1)   := '0';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目定義
  TYPE g_item_def_rtype    IS RECORD                                    -- レコード型を宣言
      (item_name             VARCHAR2(100)                              -- 項目名
      ,item_attribute        VARCHAR2(100)                              -- 項目属性
      ,item_essential        VARCHAR2(100)                              -- 必須フラグ
      ,item_length           NUMBER                                     -- 項目の長さ(整数部分)
      ,decim                 NUMBER                                     -- 項目の長さ(小数点以下)
      );
  -- カテゴリ情報
  TYPE g_item_ctg_rtype    IS RECORD                                    -- レコード型を宣言
      (segment1              xxcmn_categories_v.segment1%TYPE           -- segment1
      ,category_set_name     xxcmn_categories_v.category_set_name%TYPE  -- カテゴリセット名
      ,category_val          VARCHAR2(240)                              -- カテゴリセット値
      ,item_code             VARCHAR2(240)                              -- 品目コード
      ,ssk_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(商品製品区分)
      ,ssk_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(商品製品区分)
      ,hsk_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(本社商品区分)
      ,hsk_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(本社商品区分)
      ,sg_category_id        mtl_categories_b.category_id%TYPE          -- カテゴリID(政策群)
      ,sg_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(政策群)
      ,bd_category_id        mtl_categories_b.category_id%TYPE          -- カテゴリID(バラ茶区分)
      ,bd_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(バラ茶区分)
      ,mgc_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(マーケ用群コード)
      ,mgc_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(マーケ用群コード)
      ,pg_category_id        mtl_categories_b.category_id%TYPE          -- カテゴリID(群コード)
      ,pg_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(群コード)
      ,itd_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(品目区分)
      ,itd_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(品目区分)
      ,ind_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(内外区分)
      ,ind_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(内外区分)
      ,pd_category_id        mtl_categories_b.category_id%TYPE          -- カテゴリID(商品区分)
      ,pd_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(商品区分)
      ,qd_category_id        mtl_categories_b.category_id%TYPE          -- カテゴリID(品質区分)
      ,qd_category_set_id    mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(品質区分)
      ,fpg_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(工場群コード)
      ,fpg_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(工場群コード)
      ,apg_category_id       mtl_categories_b.category_id%TYPE          -- カテゴリID(経理部用群コード)
      ,apg_category_set_id   mtl_category_sets_b.category_set_id%TYPE   -- カテゴリセットID(経理部用群コード)
      );
  -- Disc品目情報
  TYPE g_disc_item_rtype IS RECORD                                      -- レコード型を宣言
      (item_id               ic_item_mst_b.item_id%TYPE                 -- OPM品目ID
      ,item_no               ic_item_mst_b.item_no%TYPE                 -- 品目コード
      ,inventory_item_id     mtl_system_items_b.inventory_item_id%TYPE  -- Disc品目ID
      ,line_no               xxcmn_wk_item_batch_regist.line_no%TYPE    -- 行番号
      );
  -- コンカレントパラメータ レコードタイプ
  TYPE g_conc_argument_rtype IS RECORD
  ( argument                 VARCHAR2(100)
  );
  -- チェック用情報
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)     INDEX BY BINARY_INTEGER;
  -- コンカレントパラメータ テーブルタイプ
  TYPE g_conc_argument_ttype   IS TABLE OF g_conc_argument_rtype   INDEX BY BINARY_INTEGER;
  -- 項目定義情報  
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;                                                 -- 業務日付
  gd_apply_date         DATE;                                                 -- 適用開始日：日付型変換後
  gn_file_id            NUMBER;                                               -- パラメータ格納用変数
  gn_item_num           NUMBER;                                               -- 品目マスタ一括アップロードデータ項目数格納用
  -- 品目カテゴリ情報
  gt_ctg_item_prod      fnd_profile_option_values.profile_option_value%TYPE;  -- 商品製品区分
  gt_ctg_hon_prod       fnd_profile_option_values.profile_option_value%TYPE;  -- 本社商品区分
  gt_ctg_mark_pg        fnd_profile_option_values.profile_option_value%TYPE;  -- マーケ用群コード
  gt_ctg_gun_code       fnd_profile_option_values.profile_option_value%TYPE;  -- 群コード
  gt_ctg_item_class     fnd_profile_option_values.profile_option_value%TYPE;  -- 品目区分
  gt_ctg_inout_class    fnd_profile_option_values.profile_option_value%TYPE;  -- 内外区分
  gt_ctg_fact_pg        fnd_profile_option_values.profile_option_value%TYPE;  -- 工場群コード
  gt_ctg_acnt_pg        fnd_profile_option_values.profile_option_value%TYPE;  -- 経理部用群コード
  gt_ctg_seisakugun     fnd_profile_option_values.profile_option_value%TYPE;  -- 政策群コード
  gt_ctg_baracha_class  fnd_profile_option_values.profile_option_value%TYPE;  -- バラ茶区分
  gt_ctg_product_div    fnd_profile_option_values.profile_option_value%TYPE;  -- 商品区分
  gt_ctg_quality_class  fnd_profile_option_values.profile_option_value%TYPE;  -- 品質区分
  gt_master_org_code    fnd_profile_option_values.profile_option_value%TYPE;  -- マスター在庫組織コード
  --
  gn_master_org_id      mtl_parameters.master_organization_id%TYPE;           -- マスター在庫組織ID
  g_item_def_tab        g_item_def_ttype;                                     -- テーブル型変数の宣言
  gv_format             VARCHAR2(100);                                        -- パラメータ格納用変数
-- Ver.1.1 S.Niki ADD START
  gt_whse_item_id       ic_item_mst_b.whse_item_id%TYPE;                      -- 倉庫品目ID
-- Ver.1.1 S.Niki ADD END
--
  -- 処理件数カウント用
  gn_get_normal_cnt     NUMBER;                                               -- 型/サイズ/必須チェックOK件数
  gn_get_error_cnt      NUMBER;                                               -- 型/サイズ/必須チェックNG件数
  gn_val_normal_cnt     NUMBER;                                               -- 妥当性チェックOK件数
  gn_val_error_cnt      NUMBER;                                               -- 妥当性チェックNG件数
  gn_ins_normal_cnt     NUMBER;                                               -- データ登録OK件数
  gn_ins_error_cnt      NUMBER;                                               -- データ登録NG件数
--
  -- ===============================
  -- ユーザー定義カーソル型
  -- ===============================
  -- 品目マスタ一括アップロードデータ取得カーソル
  CURSOR get_data_cur
  IS
    SELECT   xwibr.file_id                            AS file_id                  -- ファイルID
            ,xwibr.file_seq                           AS file_seq                 -- ファイルSEQ
            ,xwibr.line_no                            AS line_no                  -- 行番号
            ,TRIM(xwibr.item_no)                      AS item_no                  -- 品目
            ,TRIM(xwibr.item_desc)                    AS item_desc                -- 摘要
            ,TRIM(xwibr.item_short_name)              AS item_short_name          -- 略称
            ,TRIM(xwibr.item_name_alt)                AS item_name_alt            -- カナ名
            ,TRIM(xwibr.warehouse_item)               AS warehouse_item           -- 倉庫品目
            ,TRIM(xwibr.item_um)                      AS item_um                  -- 単位（在庫単位）
            ,TRIM(xwibr.old_crowd)                    AS old_crowd                -- 旧群コード
            ,TRIM(xwibr.new_crowd)                    AS new_crowd                -- 新群コード
            ,TRIM(xwibr.crowd_start_date)             AS crowd_start_date         -- 群コード適用開始日
            ,TRIM(xwibr.old_price)                    AS old_price                -- 旧・定価
            ,TRIM(xwibr.new_price)                    AS new_price                -- 新・定価
            ,TRIM(xwibr.price_start_date)             AS price_start_date         -- 定価適用開始日
            ,TRIM(xwibr.old_business_cost)            AS old_business_cost        -- 旧・営業原価 
            ,TRIM(xwibr.new_business_cost)            AS new_business_cost        -- 新・営業原価 
            ,TRIM(xwibr.business_start_date)          AS business_start_date      -- 営業原価開始日 
            ,TRIM(xwibr.sale_start_date)              AS sale_start_date          -- 発売開始日
            ,TRIM(xwibr.jan_code)                     AS jan_code                 -- JANコード
            ,TRIM(xwibr.itf_code)                     AS itf_code                 -- ITFコード
            ,TRIM(xwibr.case_num)                     AS case_num                 -- ケース入数
            ,TRIM(xwibr.net)                          AS net                      -- NET
            ,TRIM(xwibr.weight_volume_class)          AS weight_volume_class      -- 重量容積区分
            ,TRIM(xwibr.weight)                       AS weight                   -- 重量
            ,TRIM(xwibr.volume)                       AS volume                   -- 容積
            ,TRIM(xwibr.destination_class)            AS destination_class        -- 仕向区分
            ,TRIM(xwibr.cost_management_class)        AS cost_management_class    -- 原価管理区分
            ,TRIM(xwibr.vendor_price_deriday_ty)      AS vendor_price_deriday_ty  -- 単価導出日タイプ
            ,TRIM(xwibr.represent_num)                AS represent_num            -- 代表入数
            ,TRIM(xwibr.mtl_units_of_measure_tl)      AS mtl_units_of_measure_tl  -- 入出庫換算単位
            ,TRIM(xwibr.need_test_class)              AS need_test_class          -- 試験有無区分
            ,TRIM(xwibr.inspection_lt)                AS inspection_lt            -- 検査L/T
            ,TRIM(xwibr.judgment_times_num)           AS judgment_times_num       -- 判定回数
            ,TRIM(xwibr.order_judge_times_num)        AS order_judge_times_num    -- 発注可能判定回数
            ,TRIM(xwibr.crowd_code)                   AS crowd_code               -- 群コード
            ,TRIM(xwibr.policy_group_code)            AS policy_group_code        -- 政策群コード
            ,TRIM(xwibr.mark_crowd_code)              AS mark_crowd_code          -- マーケ用群コード
            ,TRIM(xwibr.acnt_crowd_code)              AS acnt_crowd_code          -- 経理部用群コード
            ,TRIM(xwibr.item_product_class)           AS item_product_class       -- 商品製品区分
            ,TRIM(xwibr.hon_product_class)            AS hon_product_class        -- 本社商品区分
            ,TRIM(xwibr.product_div)                  AS product_div              -- 商品区分
            ,TRIM(xwibr.item_class)                   AS item_class               -- 品目区分
            ,TRIM(xwibr.inout_class)                  AS inout_class              -- 内外区分
            ,TRIM(xwibr.baracha_class)                AS baracha_class            -- バラ茶区分
            ,TRIM(xwibr.quality_class)                AS quality_class            -- 品質区分
            ,TRIM(xwibr.fact_crowd_code)              AS fact_crowd_code          -- 工場群コード
            ,TRIM(xwibr.start_date_active)            AS start_date_active        -- 適用開始日
            ,TRIM(xwibr.expiration_day_class)         AS expiration_day_class     -- 賞味期間区分
            ,TRIM(xwibr.expiration_day)               AS expiration_day           -- 賞味期間
            ,TRIM(xwibr.shelf_life)                   AS shelf_life               -- 消費期間
            ,TRIM(xwibr.delivery_lead_time)           AS delivery_lead_time       -- 納入期間
            ,TRIM(xwibr.case_weight_volume)           AS case_weight_volume       -- ケース重量容積
            ,TRIM(xwibr.raw_material_consumpe)        AS raw_material_consumpe    -- 原料使用量
            ,TRIM(xwibr.standard_yield)               AS standard_yield           -- 標準歩留
            ,TRIM(xwibr.model_type)                   AS model_type               -- 型種別
            ,TRIM(xwibr.product_class)                AS product_class            -- 商品分類
            ,TRIM(xwibr.product_type)                 AS product_type             -- 商品種別
            ,TRIM(xwibr.shipping_cs_unit_qty)         AS shipping_cs_unit_qty     -- 出荷入数
            ,TRIM(xwibr.palette_max_cs_qty)           AS palette_max_cs_qty       -- パレ配数
            ,TRIM(xwibr.palette_max_step_qty)         AS palette_max_step_qty     -- パレ段数
            ,TRIM(xwibr.palette_step_qty)             AS palette_step_qty         -- パレット段
            ,TRIM(xwibr.bottle_class)                 AS bottle_class             -- 容器区分
            ,TRIM(xwibr.uom_class)                    AS uom_class                -- 単位区分
            ,TRIM(xwibr.inventory_chk_class)          AS inventory_chk_class      -- 棚卸区分
            ,TRIM(xwibr.trace_class)                  AS trace_class              -- トレース区分
            ,TRIM(xwibr.rate_class)                   AS rate_class               -- 率区分
            ,TRIM(xwibr.shipping_end_date)            AS shipping_end_date        -- 出荷停止日
            ,xwibr.created_by                         AS created_by               -- 作成者
            ,xwibr.creation_date                      AS creation_date            -- 作成日
            ,xwibr.last_updated_by                    AS last_updated_by          -- 最終更新者
            ,xwibr.last_update_date                   AS last_update_date         -- 最終更新日
            ,xwibr.last_update_login                  AS last_update_login        -- 最終ログインID
            ,xwibr.request_id                         AS request_id               -- 要求ID
            ,xwibr.program_application_id             AS program_application_id   -- アプリケーションID
            ,xwibr.program_id                         AS program_id               -- プログラムID
            ,xwibr.program_update_date                AS program_update_date      -- 更新日
    FROM     xxcmn_wk_item_batch_regist  xwibr                                    -- 品目マスタ一括アップロードワーク
    WHERE    xwibr.request_id = gn_request_id                                     -- 要求ID
    ORDER BY file_seq                                                             -- ファイルSEQ
    ;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** ロックエラー例外 ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_category
   * Description      : カテゴリ存在チェック
   ***********************************************************************************/
  PROCEDURE chk_exists_category(
    iv_category_set_name IN  VARCHAR2          -- カテゴリセット名
   ,iv_category_val      IN  VARCHAR2          -- カテゴリ値
   ,iv_item_code         IN  VARCHAR2          -- 品目コード
   ,on_catregory_id      OUT NUMBER            -- カテゴリID
   ,on_catregory_set_id  OUT NUMBER            -- カテゴリセットID
   ,ov_errbuf            OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg            OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_category'; -- プログラム名
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
    lv_sqlerrm                VARCHAR2(5000);                     -- SQLERRM変数退避用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_data_expt             EXCEPTION;                          -- データ抽出エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- カテゴリVIEW存在チェック
    --==============================================================
    BEGIN
      SELECT xcv.category_id      AS category_id      -- カテゴリID
            ,xcv.category_set_id  AS category_set_id  -- カテゴリセットID
      INTO   on_catregory_id
            ,on_catregory_set_id
      FROM   xxcmn_categories_v xcv  -- カテゴリVIEW
      WHERE  xcv.category_set_name = iv_category_set_name  -- カテゴリセット名
      AND    xcv.segment1          = iv_category_val       -- カテゴリ値
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
    END;
--
  EXCEPTION
    -- *** データ抽出例外ハンドラ ***
    WHEN get_data_expt THEN
      -- データ抽出エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10622            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_table_mcv
                                        || '(' || iv_category_set_name || ')'
                                                                      -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code        -- トークンコード2
                    ,iv_token_value2 => iv_item_code                  -- トークン値2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- トークンコード3
                    ,iv_token_value3 => lv_sqlerrm                    -- トークン値3
                   );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
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
  END chk_exists_category;
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_lookup
   * Description      : LOOKUP表存在チェック
   ***********************************************************************************/
  PROCEDURE chk_exists_lookup(
    iv_lookup_type   IN  VARCHAR2  -- 参照タイプ
   ,iv_lookup_code   IN  VARCHAR2  -- 参照タイプコード
   ,iv_item_code     IN  VARCHAR2  -- 品目コード
   ,ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_lookup'; -- プログラム名
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
    lt_lookup_code            fnd_lookup_values.lookup_code%TYPE; -- 抽出LOOKUP_CODE
    lv_sqlerrm                VARCHAR2(5000);                     -- SQLERRM変数退避用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_data_expt             EXCEPTION;                          -- データ抽出エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- LOOKUP表存在チェック
    BEGIN
      SELECT xlvv.lookup_code  AS lookup_code
      INTO   lt_lookup_code
      FROM   xxcmn_lookup_values_v xlvv  -- クイックコード情報VIEW
      WHERE  xlvv.lookup_type  = iv_lookup_type
      AND    xlvv.lookup_code  = iv_lookup_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE get_data_expt;
    END;
--
  EXCEPTION
    -- *** データ抽出例外ハンドラ ***
    WHEN get_data_expt THEN
      -- データ抽出エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10622            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_table_flv
                                        || '(' || iv_lookup_type || ')'
                                                                      -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code        -- トークンコード2
                    ,iv_token_value2 => iv_item_code                  -- トークン値2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- トークンコード3
                    ,iv_token_value3 => lv_sqlerrm                    -- トークン値3
                   );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_error;
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
  END chk_exists_lookup;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : 終了処理 (D-8)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- プログラム名
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
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    -- D-8.1 品目マスタ一括アップロードデータ削除
    --==============================================================
    BEGIN
      DELETE
      FROM  xxcmn_wk_item_batch_regist  xwibr
      ;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        --
        lv_errmsg  := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmn         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmn_10630         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table               -- トークンコード1
                       ,iv_token_value1 => cv_table_xwibr             -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg              -- トークンコード2
                       ,iv_token_value2 => SQLERRM                    -- トークン値2
                      );
        -- メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        --
        ov_retcode := cv_status_error;
    END;
    --
    --==============================================================
    -- D-8.2 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      DELETE
      FROM  xxinv_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = gn_file_id
      ;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        --
        lv_errmsg  := xxcmn_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmn         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmn_10630         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table               -- トークンコード1
                       ,iv_token_value1 => cv_table_xmfui             -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg              -- トークンコード2
                       ,iv_token_value2 => SQLERRM                    -- トークン値2
                      );
        -- メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        --
        ov_retcode := cv_status_error;
    END;
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
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : データ登録 (D-5)
   ***********************************************************************************/
  PROCEDURE ins_data(
    i_wk_item_rec  IN  get_data_cur%ROWTYPE      -- 品目マスタ一括アップロード情報
   ,i_item_ctg_rec IN  g_item_ctg_rtype          -- カテゴリ情報
   ,ov_errbuf      OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2                  -- リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_conc_cnt               NUMBER;           -- 行カウンタ(コンカレント)
    --
    l_opm_item_rec            ic_item_mst_b%ROWTYPE;
    l_opm_category_rec        xxcmm_004common_pkg.opmitem_category_rtype;  -- OPM品目カテゴリ割当登録用
    ln_item_id                ic_item_mst_b.item_id%TYPE;                  -- シーケンスGET用品目ID
    lv_tkn_table              VARCHAR2(60);
-- Ver.1.1 S.Niki ADD START
    lt_whse_item_id           ic_item_mst_b.whse_item_id%TYPE;             -- 倉庫品目ID
-- Ver.1.1 S.Niki ADD END
--
    -- *** ローカル・カーソル ***
    --
    -- *** ローカル・レコード ***
    --
    -- *** ローカルユーザー定義例外 ***
    ins_err_expt              EXCEPTION;                              -- データ登録エラー
    concurrent_expt           EXCEPTION;                              -- コンカレント実行エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- D-5.1 OPM品目ID取得
    --==============================================================
    -- 初期化
    l_opm_item_rec := NULL;
    --
    SELECT gem5_item_id_s.NEXTVAL  AS item_id
    INTO   ln_item_id
    FROM   DUAL
    ;
-- Ver.1.1 S.Niki ADD START
    --==============================================================
    -- 倉庫品目ID取得
    --==============================================================
    -- 品目コードと倉庫品目の値が異なる場合
    IF ( i_wk_item_rec.item_no <> i_wk_item_rec.warehouse_item ) THEN
      -- D-4で取得した倉庫品目IDをセット
      lt_whse_item_id := gt_whse_item_id;
    ELSE
      -- 上記で取得したOPM品目IDをセット
      lt_whse_item_id := ln_item_id;
    END IF;
-- Ver.1.1 S.Niki ADD END
    --
    --==============================================================
    -- D-5.2 OPM品目マスタ登録用の値を設定
    --==============================================================
    l_opm_item_rec.item_id                  := ln_item_id;                               -- 品目ID
    l_opm_item_rec.item_no                  := i_wk_item_rec.item_no;                    -- 品目コード
    l_opm_item_rec.item_desc1               := i_wk_item_rec.item_desc;                  -- 摘要
    l_opm_item_rec.item_um                  := i_wk_item_rec.item_um;                    -- 基準単位
    l_opm_item_rec.dualum_ind               := cv_dualum;                                -- 二重管理
    l_opm_item_rec.deviation_lo             := cv_0;                                     -- 偏差係数-
    l_opm_item_rec.deviation_hi             := cv_0;                                     -- 偏差係数+
    -- 品目区分が「2：資材」の場合、「No」を設定。それ以外の場合、「Yes」を設定
    IF ( i_wk_item_rec.item_class = cv_item_class ) THEN
      l_opm_item_rec.lot_ctl                := cv_lot_ctl_class_no;                      -- ロット管理区分
    ELSE
      l_opm_item_rec.lot_ctl                := cv_lot_ctl_class_yes;                     -- ロット管理区分
    END IF;
    l_opm_item_rec.lot_indivisible          := cv_0;                                     -- 分割不可
    l_opm_item_rec.sublot_ctl               := cv_0;                                     -- サブロット
    l_opm_item_rec.loct_ctl                 := cv_loct_ctl;                              -- 保管場所
    l_opm_item_rec.noninv_ind               := cv_0;                                     -- 非在庫
    l_opm_item_rec.match_type               := cv_match_type;                            -- 照合
    l_opm_item_rec.inactive_ind             := cv_0;                                     -- 無効区分
    l_opm_item_rec.shelf_life               := i_wk_item_rec.expiration_day;             -- 保存期間
    l_opm_item_rec.retest_interval          := cv_0;                                     -- 再テスト間隔
    l_opm_item_rec.grade_ctl                := cv_0;                                     -- グレード
    l_opm_item_rec.status_ctl               := cv_0;                                     -- ステータス
    l_opm_item_rec.fill_qty                 := cv_0;                                     --
    l_opm_item_rec.expaction_interval       := cv_0;                                     --
    l_opm_item_rec.phantom_type             := cv_0;                                     --
-- Ver.1.1 S.Niki MOD START
--    l_opm_item_rec.whse_item_id             := l_opm_item_rec.item_id;                   --
    l_opm_item_rec.whse_item_id             := lt_whse_item_id;                          -- 倉庫品目
-- Ver.1.1 S.Niki MOD END
    l_opm_item_rec.experimental_ind         := cv_0;                                     -- 試作
    l_opm_item_rec.exported_date            := gd_process_date;                          --
    l_opm_item_rec.delete_mark              := cv_0;                                     --
    l_opm_item_rec.attribute1               := i_wk_item_rec.old_crowd;                  -- 旧群コード
    l_opm_item_rec.attribute2               := i_wk_item_rec.new_crowd;                  -- 新群コード
    l_opm_item_rec.attribute3               := i_wk_item_rec.crowd_start_date;           -- 群コード開始日
    l_opm_item_rec.attribute4               := i_wk_item_rec.old_price;                  -- 旧・定価
    l_opm_item_rec.attribute5               := i_wk_item_rec.new_price;                  -- 新・定価
    l_opm_item_rec.attribute6               := i_wk_item_rec.price_start_date;           -- 定価開始日
    l_opm_item_rec.attribute7               := i_wk_item_rec.old_business_cost;          -- 旧・営業原価 
    l_opm_item_rec.attribute8               := i_wk_item_rec.new_business_cost;          -- 新・営業原価 
    l_opm_item_rec.attribute9               := i_wk_item_rec.business_start_date;        -- 営業原価開始日
    l_opm_item_rec.attribute10              := i_wk_item_rec.weight_volume_class;        -- 重量容積区分
    l_opm_item_rec.attribute11              := i_wk_item_rec.case_num;                   -- ケース入数
    l_opm_item_rec.attribute12              := i_wk_item_rec.net;                        -- NET
    l_opm_item_rec.attribute13              := i_wk_item_rec.sale_start_date;            -- 発売（製造）開始日
    l_opm_item_rec.attribute14              := i_wk_item_rec.inspection_lt;              -- 検査L/T
    l_opm_item_rec.attribute15              := i_wk_item_rec.cost_management_class;      -- 原価管理区分
    l_opm_item_rec.attribute16              := i_wk_item_rec.volume;                     -- 容積
    l_opm_item_rec.attribute17              := i_wk_item_rec.represent_num;              -- 代表入数
    l_opm_item_rec.attribute18              := cv_shipping_class;                        -- 出荷区分
    l_opm_item_rec.attribute20              := i_wk_item_rec.vendor_price_deriday_ty;    -- 導出日タイプ
    l_opm_item_rec.attribute21              := i_wk_item_rec.jan_code;                   -- JANコード
    l_opm_item_rec.attribute22              := i_wk_item_rec.itf_code;                   -- ITFコード
    l_opm_item_rec.attribute23              := i_wk_item_rec.need_test_class;            -- 試験有無区分
    l_opm_item_rec.attribute24              := i_wk_item_rec.mtl_units_of_measure_tl;    -- 入出庫換算単位
    l_opm_item_rec.attribute25              := i_wk_item_rec.weight;                     -- 重量
    l_opm_item_rec.attribute26              := cv_0;                                     -- 売上対象区分
    l_opm_item_rec.attribute27              := i_wk_item_rec.judgment_times_num;         -- 判定回数
    l_opm_item_rec.attribute28              := i_wk_item_rec.destination_class;          -- 仕向区分
    l_opm_item_rec.attribute29              := i_wk_item_rec.order_judge_times_num;      -- 発注可能判定回数
    --ロット管理区分が「有」の場合、自動ロット採番有効に「1」を設定。上記以外の場合は「0」を設定
    --ロット管理区分が「有」の場合、ロット・サフィックスに「0」を設定。
    IF ( l_opm_item_rec.lot_ctl = cv_lot_ctl_class_yes ) THEN
      l_opm_item_rec.autolot_active_indicator   := cv_autolot_active_indicate_1;         -- 自動ロット採番有効
      l_opm_item_rec.lot_suffix                 := cv_lot_suffix_0;                      -- ロット・サフィックス
    ELSE
      l_opm_item_rec.autolot_active_indicator   := cv_autolot_active_indicate_0;         -- 自動ロット採番有効
    END IF;
    l_opm_item_rec.created_by               := gn_created_by;                            -- 作成者
    l_opm_item_rec.creation_date            := gd_creation_date;                         -- 作成日
    l_opm_item_rec.last_updated_by          := gn_last_updated_by;                       -- 最終更新者
    l_opm_item_rec.last_update_date         := gd_last_update_date;                      -- 最終更新日
    l_opm_item_rec.last_update_login        := gn_last_update_login;                     -- ログインID
    l_opm_item_rec.request_id               := gn_request_id;                            -- 要求ID
    l_opm_item_rec.program_application_id   := gn_program_application_id;                -- アプリケーション
    l_opm_item_rec.program_id               := gn_program_id;                            -- プログラムID
    l_opm_item_rec.program_update_date      := gd_program_update_date;                   -- 更新日
    --
    --==============================================================
    -- D-5.3 OPM品目マスタ登録
    --==============================================================
    xxcmm_004common_pkg.ins_opm_item(
      i_opm_item_rec => l_opm_item_rec
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_iimb;
      RAISE ins_err_expt;     -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.4 OPM品目アドオンマスタ登録
    --==============================================================
    BEGIN
      INSERT INTO xxcmn_item_mst_b(
        item_id                                                      -- 品目ID
       ,start_date_active                                            -- 適用開始日
       ,end_date_active                                              -- 適用終了日
       ,active_flag                                                  -- 適用済フラグ
       ,item_name                                                    -- 正式名
       ,item_short_name                                              -- 略称
       ,item_name_alt                                                -- カナ名
       ,parent_item_id                                               -- 親品目ID
       ,obsolete_class                                               -- 廃止区分
       ,obsolete_date                                                -- 廃止日（製造中止日）
       ,model_type                                                   -- 型種別
       ,product_class                                                -- 商品分類 
       ,product_type                                                 -- 商品種別
       ,expiration_day                                               -- 賞味期間
       ,delivery_lead_time                                           -- 納入期間
       ,whse_county_code                                             -- 工場群コード
       ,standard_yield                                               -- 標準歩留
       ,shipping_end_date                                            -- 出荷停止日
       ,rate_class                                                   -- 率区分
       ,shelf_life                                                   -- 消費期間
       ,shelf_life_class                                             -- 賞味期間区分
       ,bottle_class                                                 -- 容器区分
       ,uom_class                                                    -- 単位区分
       ,inventory_chk_class                                          -- 棚卸区分
       ,trace_class                                                  -- トレース区分
       ,shipping_cs_unit_qty                                         -- 出荷入数
       ,palette_max_cs_qty                                           -- 配数
       ,palette_max_step_qty                                         -- パレット当り最大段数
       ,palette_step_qty                                             -- パレット段
       ,cs_weigth_or_capacity                                        -- ケース重量容積
       ,raw_material_consumption                                     -- 原料使用量
       ,attribute1                                                   -- 予備１
       ,attribute2                                                   -- 予備２
       ,attribute3                                                   -- 予備３
       ,attribute4                                                   -- 予備４
       ,attribute5                                                   -- 予備５
       ,created_by                                                   -- 作成者
       ,creation_date                                                -- 作成日
       ,last_updated_by                                              -- 最終更新者
       ,last_update_date                                             -- 最終更新日
       ,last_update_login                                            -- 最終更新ログイン
       ,request_id                                                   -- 要求ID
       ,program_application_id                                       -- アプリケーションID
       ,program_id                                                   -- プログラムID
       ,program_update_date                                          -- プログラムによる更新日
      ) VALUES (
        ln_item_id                                                   -- 品目ID
       ,TO_DATE(i_wk_item_rec.start_date_active, cv_date_fmt_std)    -- 適用開始日
       ,TO_DATE(cv_max_date, cv_date_fmt_std)                        -- 適用終了日
       ,cv_yes                                                       -- 適用済フラグ
       ,i_wk_item_rec.item_desc                                      -- 正式名
       ,i_wk_item_rec.item_short_name                                -- 略称
       ,i_wk_item_rec.item_name_alt                                  -- カナ名
       ,ln_item_id                                                   -- 親品目ID
       ,cv_inactive_class                                            -- 廃止区分
       ,NULL                                                         -- 廃止日（製造中止日）
       ,i_wk_item_rec.model_type                                     -- 型種別
       ,i_wk_item_rec.product_class                                  -- 商品分類 
       ,i_wk_item_rec.product_type                                   -- 商品種別
       ,i_wk_item_rec.expiration_day                                 -- 賞味期間
       ,i_wk_item_rec.delivery_lead_time                             -- 納入期間
       ,i_wk_item_rec.fact_crowd_code                                -- 工場群コード
       ,i_wk_item_rec.standard_yield                                 -- 標準歩留
       ,TO_DATE(i_wk_item_rec.shipping_end_date, cv_date_fmt_std)    -- 出荷停止日
       ,i_wk_item_rec.rate_class                                     -- 率区分
       ,i_wk_item_rec.shelf_life                                     -- 消費期間
       ,i_wk_item_rec.expiration_day_class                           -- 賞味期間区分
       ,i_wk_item_rec.bottle_class                                   -- 容器区分
       ,i_wk_item_rec.uom_class                                      -- 単位区分
       ,i_wk_item_rec.inventory_chk_class                            -- 棚卸区分
       ,i_wk_item_rec.trace_class                                    -- トレース区分
       ,i_wk_item_rec.shipping_cs_unit_qty                           -- 出荷入数
       ,i_wk_item_rec.palette_max_cs_qty                             -- 配数
       ,i_wk_item_rec.palette_max_step_qty                           -- パレット当り最大段数
       ,i_wk_item_rec.palette_step_qty                               -- パレット段
       ,i_wk_item_rec.case_weight_volume                             -- ケース重量容積
       ,i_wk_item_rec.raw_material_consumpe                          -- 原料使用量
       ,NULL                                                         -- 予備１
       ,NULL                                                         -- 予備２
       ,NULL                                                         -- 予備３
       ,NULL                                                         -- 予備４
       ,NULL                                                         -- 予備５
       ,gn_created_by                                                -- 作成者
       ,gd_creation_date                                             -- 作成日
       ,gn_last_updated_by                                           -- 最終更新者
       ,gd_last_update_date                                          -- 最終更新日
       ,gn_last_update_login                                         -- 最終更新ログイン
       ,gn_request_id                                                -- 要求ID
       ,gn_program_application_id                                    -- アプリケーションID
       ,gn_program_id                                                -- プログラムID
       ,gd_program_update_date                                       -- プログラムによる更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_ximb;
        RAISE ins_err_expt;   -- データ登録例外
    END;
    --
    --==============================================================
    -- D-5.5 OPM品目カテゴリ割当(商品製品区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.ssk_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.ssk_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_item_prod;
      RAISE ins_err_expt;     -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.6 OPM品目カテゴリ割当(本社商品区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.hsk_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.hsk_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_hon_prod;
      RAISE ins_err_expt;     -- データ登録例外
    END IF;
    --
    --
    --==============================================================
    -- D-5.7 OPM品目カテゴリ割当(政策群コード)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.sg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.sg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_seisakugun;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.8 OPM品目カテゴリ割当(バラ茶区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.bd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.bd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_baracha_class;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.9 OPM品目カテゴリ割当(マーケ用群コード)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.mgc_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.mgc_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_mark_pg;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.10 OPM品目カテゴリ割当(群コード)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.pg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.pg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_gun_code;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.11 OPM品目カテゴリ割当(品目区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.itd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.itd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_item_class;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.12 OPM品目カテゴリ割当(内外区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.ind_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.ind_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_inout_class;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.13 OPM品目カテゴリ割当(商品区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.pd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.pd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_product_div;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.14 OPM品目カテゴリ割当(品質区分)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.qd_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.qd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_quality_class;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.15 OPM品目カテゴリ割当(工場群コード)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.fpg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.fpg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_fact_pg;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- D-5.16 OPM品目カテゴリ割当(経理部用群コード)
    --==============================================================
    l_opm_category_rec                 := NULL;
    l_opm_category_rec.item_id         := ln_item_id;
    l_opm_category_rec.category_set_id := i_item_ctg_rec.apg_category_set_id;
    l_opm_category_rec.category_id     := i_item_ctg_rec.apg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_opm_category_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := gt_ctg_acnt_pg;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
  --
  EXCEPTION
    -- *** データ登録例外ハンドラ ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10626         -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table               -- トークンコード1
                    ,iv_token_value1 => lv_tkn_table               -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no       -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no      -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code     -- トークンコード3
                    ,iv_token_value3 => i_wk_item_rec.item_no      -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg              -- トークンコード4
                    ,iv_token_value4 => lv_errbuf                  -- トークン値4
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      --
      ov_retcode := cv_status_error;
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
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_disc_categ_ref
   * Description      : Disc品目カテゴリ割当 (D-7)
   ***********************************************************************************/
  PROCEDURE proc_disc_categ_ref(
    i_disc_item_rec  IN  g_disc_item_rtype  -- 1.Disc品目情報
   ,ov_errbuf        OUT VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg        OUT VARCHAR2)          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_disc_categ_ref'; -- プログラム名
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
    lv_tkn_table          VARCHAR2(30);    -- メッセージトークン用
--
    -- *** ローカル・レコード ***
    l_disc_category_rec   xxcmm_004common_pkg.discitem_category_rtype;
                                                                      -- 品目カテゴリ割当登録用
--
    -- *** ローカルカーソル ***
--
    -- OPM品目カテゴリ割当取得カーソル
    CURSOR opm_item_categ_cur
    IS
      SELECT gic.category_set_id   AS category_set_id  -- カテゴリセットID
            ,gic.category_id       AS category_id      -- カテゴリID
      FROM   gmi_item_categories   gic      -- OPM品目カテゴリ割当
            ,mtl_category_sets_vl  mcs      -- カテゴリセット
      WHERE  gic.item_id           = i_disc_item_rec.item_id         -- 品目ID
      AND    gic.category_set_id   = mcs.category_set_id
      AND    mcs.category_set_name IN ( gt_ctg_item_prod       -- 商品製品区分
                                      , gt_ctg_hon_prod        -- 本社商品区分
                                      , gt_ctg_mark_pg         -- マーケ群コード
                                      , gt_ctg_gun_code        -- 群コード
                                      , gt_ctg_item_class      -- 品目区分
                                      , gt_ctg_inout_class     -- 内外区分
                                      , gt_ctg_fact_pg         -- 工場群コード
                                      , gt_ctg_acnt_pg         -- 経理部用群コード
                                      , gt_ctg_seisakugun      -- 政策群コード
                                      , gt_ctg_baracha_class   -- バラ茶区分
                                      , gt_ctg_product_div     -- 商品区分
                                      , gt_ctg_quality_class   -- 品質区分
                                      )
      ;
    -- OPM品目カテゴリ割当取得カーソルレコード型
    opm_item_categ_rec   opm_item_categ_cur%ROWTYPE;
--
    -- *** ローカルユーザー定義例外 ***
    ins_err_expt              EXCEPTION;                              -- データ登録エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- D-7.1 OPM品目カテゴリ割当情報取得
    --==============================================================
    OPEN opm_item_categ_cur;
    LOOP
      FETCH opm_item_categ_cur INTO opm_item_categ_rec;
      IF (opm_item_categ_cur%NOTFOUND) THEN
        CLOSE opm_item_categ_cur;
        EXIT;
      END IF;
--
      -- 取得したカテゴリ毎に設定
      l_disc_category_rec                   := NULL;
      l_disc_category_rec.inventory_item_id := i_disc_item_rec.inventory_item_id;    -- Disc品目ID
      l_disc_category_rec.category_set_id   := opm_item_categ_rec.category_set_id;   -- カテゴリセットID
      l_disc_category_rec.category_id       := opm_item_categ_rec.category_id;       -- カテゴリID
--
      --==============================================================
      -- D-7.2 Disc品目カテゴリ割当
      --==============================================================
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec => l_disc_category_rec  -- 品目カテゴリ割当レコードタイプ
       ,ov_errbuf           => lv_errbuf
       ,ov_retcode          => lv_retcode
       ,ov_errmsg           => lv_errmsg
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        CLOSE opm_item_categ_cur;
        lv_tkn_table := cv_table_mic;
        RAISE ins_err_expt;
      END IF;
    END LOOP disc_categ_loop;
--
  EXCEPTION
    -- *** データ登録例外ハンドラ ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10626         -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table               -- トークンコード1
                    ,iv_token_value1 => lv_tkn_table               -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no       -- トークンコード2
                    ,iv_token_value2 => i_disc_item_rec.line_no    -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code     -- トークンコード3
                    ,iv_token_value3 => i_disc_item_rec.item_no    -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg              -- トークンコード4
                    ,iv_token_value4 => lv_errbuf                  -- トークン値4
                   );
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      --
      ov_retcode := cv_status_error;
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
  END proc_disc_categ_ref;
--
  /**********************************************************************************
   * Procedure Name   : get_disc_item_data
   * Description      : Disc品目情報取得 (D-6)
   ***********************************************************************************/
  PROCEDURE get_disc_item_data(
    ov_errbuf            OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disc_item_data'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- Disc品目情報取得カーソル
    CURSOR get_disc_item_cur
    IS
      SELECT iimb.item_id            AS item_id            -- 品目ID
            ,iimb.item_no            AS item_no            -- 品目コード
            ,msib.inventory_item_id  AS inventory_item_id  -- Disc品目ID
            ,xwibr.line_no           AS line_no            -- 行番号
      FROM   xxcmn_wk_item_batch_regist xwibr  -- 品目マスタ一括アップロードワーク
            ,ic_item_mst_b              iimb   -- OPM品目マスタ
            ,mtl_system_items_b         msib   -- Disc品目マスタ
      WHERE  xwibr.item_no         = iimb.item_no
      AND    iimb.item_no          = msib.segment1
      AND    msib.organization_id  = gn_master_org_id
      ORDER BY xwibr.line_no
      ;
    -- Disc品目情報取得カーソルレコード型
    get_disc_item_rec   get_disc_item_cur%ROWTYPE;
    --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- D-6 Disc品目情報取得
    --==============================================================
    <<disc_item_loop>>
    FOR get_disc_item_rec IN get_disc_item_cur LOOP
      --==============================================================
      -- D-7 Disc品目カテゴリ割当
      --==============================================================
      proc_disc_categ_ref(
        i_disc_item_rec  => get_disc_item_rec        -- Disc品目情報
       ,ov_errbuf        => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode       => lv_retcode               -- リターン・コード
       ,ov_errmsg        => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP disc_item_loop;
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
  END get_disc_item_data;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : 品目マスタ一括アップロードデータ妥当性チェック (D-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_wk_item_rec  IN  get_data_cur%ROWTYPE    -- 品目マスタインタフェース情報
   ,o_item_ctg_rec OUT g_item_ctg_rtype        -- カテゴリ情報
   ,ov_errbuf      OUT VARCHAR2                -- エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2                -- リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item';              -- プログラム名
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
    lv_tkn_value              VARCHAR2(100);           -- トークン値
    ln_cnt                    NUMBER;                  -- カウント用
    lv_val_check_flag         VARCHAR2(1);             -- チェックフラグ
    l_validate_item_tab       g_check_data_ttype;      -- チェック用変数
    l_item_ctg_rec            g_item_ctg_rtype;        -- カテゴリ情報
    ln_dummy_cat_id           NUMBER;                  -- ダミーカテゴリID
    ln_dummy_cat_set_id       NUMBER;                  -- ダミーカテゴリセットID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- チェックフラグの初期化
    lv_val_check_flag  := cv_status_normal;
    --
    -- カテゴリ情報初期化
    l_item_ctg_rec := NULL;
    --
    -- 業務日付のフォーマット変換
    gd_apply_date  := TO_DATE(i_wk_item_rec.start_date_active, cv_date_fmt_std);
--
    --==============================================================
    -- D-4.1 品目コード存在チェック
    --==============================================================
    SELECT  COUNT(1)  AS cnt
    INTO    ln_cnt
    FROM    ic_item_mst_b iimb
    WHERE   iimb.item_no = i_wk_item_rec.item_no  -- 品目コード
    AND     ROWNUM       = 1
    ;
    -- 処理結果チェック
    IF ( ln_cnt > 0 ) THEN
      -- マスタ存在チェックエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn          -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10617          -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_item_code      -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.item_no       -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no        -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no       -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.2 品目コード重複チェック
    --==============================================================
    SELECT COUNT(1)  AS cnt
    INTO   ln_cnt
    FROM   xxcmn_wk_item_batch_regist xwibr
    WHERE  xwibr.item_no    = i_wk_item_rec.item_no  -- 品目コード
    AND    xwibr.request_id = gn_request_id
    ;
    -- 処理結果チェック
    IF ( ln_cnt > 1 ) THEN
      -- 品目重複エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10618             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_line_no           -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.item_no          -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.3 品目コード7桁チェック
    --==============================================================
    -- 品目コード7桁チェック
-- Ver.1.1 S.Niki MOD START
--    IF ( LENGTHB( i_wk_item_rec.item_no ) <> 7 ) THEN
    IF ( LENGTHB( i_wk_item_rec.item_no ) <> cn_item_code_length ) THEN
-- Ver.1.1 S.Niki ADD END
      -- 品目コード7桁必須エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10619             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_line_no           -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.item_no          -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
-- Ver.1.1 S.Niki MOD START
--    --==============================================================
--    -- D-4.4 倉庫品目コード7桁チェック
--    --==============================================================
--    -- 倉庫品目コード7桁チェック
--    IF ( LENGTHB( i_wk_item_rec.warehouse_item ) <> 7 ) THEN
--
    --==============================================================
    -- D-4.4 倉庫品目チェック
    --==============================================================
    IF ( LENGTHB( i_wk_item_rec.warehouse_item ) <> cn_item_code_length ) THEN
-- Ver.1.1 S.Niki MOD END
      -- 倉庫品目7桁必須エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10620             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_line_no           -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.warehouse_item   -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
-- Ver.1.1 S.Niki ADD START
    -- 品目コードおよび倉庫品目ともに7桁かつ、値が異なる場合
    ELSIF ( ( LENGTHB( i_wk_item_rec.item_no )        = cn_item_code_length )
      AND   ( LENGTHB( i_wk_item_rec.warehouse_item ) = cn_item_code_length )
      AND   ( i_wk_item_rec.item_no <> i_wk_item_rec.warehouse_item ) ) THEN
        BEGIN
          -- 倉庫品目存在チェック
          SELECT  item_id            AS whse_item_id
          INTO    gt_whse_item_id
          FROM    ic_item_mst_b iimb
          WHERE   iimb.item_no = i_wk_item_rec.warehouse_item  -- 倉庫品目
          ;
        EXCEPTION
          -- 取得エラー時
          WHEN NO_DATA_FOUND THEN
            -- 倉庫品目コード存在チェックエラー
            lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmn_10641             -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input_line_no           -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.line_no          -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_item_code         -- トークンコード2
                          ,iv_token_value2 => i_wk_item_rec.warehouse_item   -- トークン値2
                         );
            -- メッセージ出力
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
            lv_val_check_flag := cv_status_error;
        END;
-- Ver.1.1 S.Niki ADD END
    END IF;
    --==============================================================
    -- D-4.5 単位（在庫単位）チェック
    --==============================================================
    SELECT COUNT(1)  AS cnt
    INTO   ln_cnt
    FROM   sy_uoms_mst sum
    WHERE  sum.delete_mark = cv_item_um_0
    AND    sum.um_code     > cv_item_um_space
    AND    sum.um_code     = i_wk_item_rec.item_um  -- 単位（在庫単位）
    ;
    -- 基準単位が存在しない場合
    IF ( ln_cnt = 0 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10621             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_item_um                 -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.item_um          -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no           -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no          -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code         -- トークンコード3
                    ,iv_token_value3 => i_wk_item_rec.item_no          -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.6 旧群コードチェック
    --==============================================================
    IF ( i_wk_item_rec.old_crowd IS NOT NULL ) THEN
      -- カテゴリ存在チェック
      chk_exists_category(
        iv_category_set_name => gt_ctg_gun_code
       ,iv_category_val      => i_wk_item_rec.old_crowd  -- 旧群コード
       ,iv_item_code         => i_wk_item_rec.item_no
       ,on_catregory_id      => ln_dummy_cat_id
       ,on_catregory_set_id  => ln_dummy_cat_set_id
       ,ov_errbuf            => lv_errbuf
       ,ov_retcode           => lv_retcode
       ,ov_errmsg            => lv_errmsg
      ) ;
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        lv_val_check_flag := cv_status_error;
      END IF;
    END IF;
    --
    --==============================================================
    -- D-4.7 新群コードチェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_gun_code
     ,iv_category_val      => i_wk_item_rec.new_crowd  -- 新群コード
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => ln_dummy_cat_id
     ,on_catregory_set_id  => ln_dummy_cat_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.8 重量容積区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_we_ca_class
     ,iv_lookup_code => i_wk_item_rec.weight_volume_class  -- 重量容積区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.9 仕向区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_destination_diy
     ,iv_lookup_code => i_wk_item_rec.destination_class  -- 仕向区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.10 原価管理区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_cost_management
     ,iv_lookup_code => i_wk_item_rec.cost_management_class -- 原価管理区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.11 仕入単価導出日タイプチェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_vendor_deriday_ty
     ,iv_lookup_code => i_wk_item_rec.vendor_price_deriday_ty  -- 仕入単価導出日
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.12 入出庫換算単位チェック
    --==============================================================
    -- 入出庫換算単位チェック
    IF ( i_wk_item_rec.mtl_units_of_measure_tl IS NOT NULL )
      AND ( i_wk_item_rec.mtl_units_of_measure_tl <> cv_mtl_units_of_measure ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10629             -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_line_no           -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.line_no          -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code         -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.item_no          -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.13 試験有無区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_need_test
     ,iv_lookup_code => i_wk_item_rec.need_test_class -- 試験有無区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.14 検査L/Tチェック
    --==============================================================
    -- 試験有無区分が「1：有」の場合は必須
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.inspection_lt IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn           -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10623           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_col_name              -- トークンコード1
                    ,iv_token_value1 => cv_inspection_lt             -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no         -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no        -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code       -- トークンコード3
                    ,iv_token_value3 => i_wk_item_rec.item_no        -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.15 判定回数チェック
    --==============================================================
    -- 試験有無区分が「1：有」の場合は必須
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.judgment_times_num IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn           -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10623           -- メッセージコード
                    ,iv_token_name1  => cv_tkn_col_name              -- トークンコード1
                    ,iv_token_value1 => cv_judge_times_num           -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no         -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no        -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code       -- トークンコード3
                    ,iv_token_value3 => i_wk_item_rec.item_no        -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.16 発注可能判定回数チェック
    --==============================================================
    -- 試験有無区分が「1：有」の場合は必須
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.order_judge_times_num IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn                    -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10623                    -- メッセージコード
                    ,iv_token_name1  => cv_tkn_col_name                       -- トークンコード1
                    ,iv_token_value1 => cv_order_judge_times_num              -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no                  -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no                 -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code                -- トークンコード3
                    ,iv_token_value3 => i_wk_item_rec.item_no                 -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.17 群コードチェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_gun_code
     ,iv_category_val      => i_wk_item_rec.crowd_code  -- 群コード
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.pg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.pg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.18 政策群コードチェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_seisakugun
     ,iv_category_val      => i_wk_item_rec.policy_group_code  -- 政策群コード
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.sg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.sg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.19 マーケ用群コードチェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_mark_pg
     ,iv_category_val      => i_wk_item_rec.mark_crowd_code  -- マーケ用群コード
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.mgc_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.mgc_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.20 経理部用群コードチェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_acnt_pg
     ,iv_category_val      => i_wk_item_rec.acnt_crowd_code  -- 経理部用群コード
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.apg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.apg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.21 商品製品区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_item_prod
     ,iv_category_val      => i_wk_item_rec.item_product_class  -- 商品製品区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.ssk_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.ssk_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.22 本社商品区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_hon_prod
     ,iv_category_val      => i_wk_item_rec.hon_product_class  -- 本社商品区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.hsk_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.hsk_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.23 商品区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_product_div
     ,iv_category_val      => i_wk_item_rec.product_div  -- 商品区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.pd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.pd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.24 品目区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_item_class
     ,iv_category_val      => i_wk_item_rec.item_class  -- 品目区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.itd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.itd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.25 内外区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_inout_class
     ,iv_category_val      => i_wk_item_rec.inout_class  -- 内外区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.ind_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.ind_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.26 バラ茶区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_baracha_class
     ,iv_category_val      => i_wk_item_rec.baracha_class  -- バラ茶区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.bd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.bd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.27 品質区分チェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_quality_class
     ,iv_category_val      => i_wk_item_rec.quality_class  -- 品質区分
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.qd_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.qd_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.28 工場群コードチェック
    --==============================================================
    -- カテゴリ存在チェック
    chk_exists_category(
      iv_category_set_name => gt_ctg_fact_pg
     ,iv_category_val      => i_wk_item_rec.fact_crowd_code  -- 工場群コード
     ,iv_item_code         => i_wk_item_rec.item_no
     ,on_catregory_id      => l_item_ctg_rec.fpg_category_id
     ,on_catregory_set_id  => l_item_ctg_rec.fpg_category_set_id
     ,ov_errbuf            => lv_errbuf
     ,ov_retcode           => lv_retcode
     ,ov_errmsg            => lv_errmsg
    ) ;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.29 賞味期間区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_shelf_life_class
     ,iv_lookup_code => i_wk_item_rec.expiration_day_class  -- 賞味期間区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.30 型種別チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_type
     ,iv_lookup_code => i_wk_item_rec.model_type  -- 型種別
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.31 商品分類チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_product_class
     ,iv_lookup_code => i_wk_item_rec.product_class  -- 商品分類
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.32 商品種別チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_product_type
     ,iv_lookup_code => i_wk_item_rec.product_type  -- 商品種別
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.33 容器区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_bottle_class
     ,iv_lookup_code => i_wk_item_rec.bottle_class  -- 容器区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.34 単位区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_uom_class
     ,iv_lookup_code => i_wk_item_rec.uom_class  -- 単位区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.35 棚卸区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_inventory_chk_class
     ,iv_lookup_code => i_wk_item_rec.inventory_chk_class  -- 棚卸区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.36 トレース区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_trace_class
     ,iv_lookup_code => i_wk_item_rec.trace_class  -- トレース区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.37 率区分チェック
    --==============================================================
    -- LOOKUP表存在チェック
    chk_exists_lookup(
      iv_lookup_type => cv_lookup_rate
     ,iv_lookup_code => i_wk_item_rec.rate_class  -- 率区分
     ,iv_item_code   => i_wk_item_rec.item_no
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.38 出荷換算単位チェック
    --==============================================================
    -- 出荷換算単位が設定されている場合、ケース入数は1以上
    IF ( i_wk_item_rec.mtl_units_of_measure_tl IS NOT NULL )
      AND ( NVL( i_wk_item_rec.case_num ,0 ) <= 0 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn          -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10624          -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.item_no       -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- D-4.39 発注可能判定回数入力制限チェック
    --==============================================================
    -- 試験有無区分が「1：有」の場合は「1」「2」「3」のいずれか設定
    IF ( i_wk_item_rec.need_test_class = cv_exam_class_1 )
      AND ( i_wk_item_rec.order_judge_times_num NOT IN ( cn_judge_times_num_1
                                                       , cn_judge_times_num_2
                                                       , cn_judge_times_num_3 )
         ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn          -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10625          -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                    ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.item_no       -- トークン値2
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      lv_val_check_flag := cv_status_error;
    END IF;
    --
    -- カテゴリ情報を戻します
    o_item_ctg_rec := l_item_ctg_rec;
    -- チェックフラグの値を返却
    ov_retcode := lv_val_check_flag;
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
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 品目マスタ一括アップロードワークデータ取得 (D-3)
   *                    品目マスタ一括アップロードワークデータ妥当性チェック(D-4)
   *                    データ登録(D-5)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- プログラム名
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
    ln_line_cnt               NUMBER;                  -- 行カウンタ
    lv_check_flag             VARCHAR2(1);             -- チェックフラグ
    lv_val_check_flag         VARCHAR2(1);             -- D-4妥当性チェックフラグ
    lv_ins_check_flag         VARCHAR2(1);             -- D-5.16までの登録チェックフラグ
    lv_conc_check_flag        VARCHAR2(1);             -- D-5.17登録チェックフラグ
    l_item_code_tab           g_check_data_ttype;      -- テーブル型変数を宣言(品目コード保持)
    ln_request_id             NUMBER;                  -- 要求ID
    l_conc_argument_tab       xxcmm_004common_pkg.conc_argument_ttype;
                                                       -- コンカレント(argument)
    l_item_ctg_rec            g_item_ctg_rtype;        -- カテゴリ情報
    lv_status_val             VARCHAR2(5000);          -- ステータス値
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    -- チェックフラグ初期化
    lv_check_flag      := cv_status_normal;
    lv_val_check_flag  := cv_status_normal;
    lv_ins_check_flag  := cv_status_normal;
    lv_conc_check_flag := cv_status_normal;
    --
    --==============================================================
    -- D-3  品目マスタ一括アップロードワークデータ取得
    --==============================================================
    -- 行カウンタアップ
    ln_line_cnt   := 0;
    --
    <<main_loop>>
    FOR get_data_rec IN get_data_cur LOOP
      -- 行カウンタアップ
      ln_line_cnt  := ln_line_cnt + 1;
      --
      --==============================================================
      -- D-4  品目マスタ一括アップロードワークデータ妥当性チェック
      --==============================================================
      validate_item(
        i_wk_item_rec  => get_data_rec             -- 品目マスタ一括アップロード情報
       ,o_item_ctg_rec => l_item_ctg_rec           -- カテゴリ情報
       ,ov_errbuf      => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode     => lv_retcode               -- リターン・コード
       ,ov_errmsg      => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 正常件数加算
        gn_val_normal_cnt := gn_val_normal_cnt + 1;
      ELSE
        -- エラー件数加算
        gn_val_error_cnt  := gn_val_error_cnt + 1;
        lv_val_check_flag := cv_status_error;
        lv_check_flag     := cv_status_error;
      END IF;
      --
      -- D-4処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        -- D-5  データ登録
        --==============================================================
        ins_data(
          i_wk_item_rec  => get_data_rec           -- 品目マスタ一括アップロード情報
         ,i_item_ctg_rec => l_item_ctg_rec         -- カテゴリ情報
         ,ov_errbuf      => lv_errbuf              -- エラー・メッセージ
         ,ov_retcode     => lv_retcode             -- リターン・コード
         ,ov_errmsg      => lv_errmsg              -- ユーザー・エラー・メッセージ
        );
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          gn_ins_normal_cnt := gn_ins_normal_cnt + 1;
          -- D-5.17にて使用する品目コードを格納
          l_item_code_tab(ln_line_cnt) := get_data_rec.item_no;
        ELSE
          gn_ins_error_cnt  := gn_ins_error_cnt + 1;
          lv_ins_check_flag := cv_status_error;
          lv_check_flag     := cv_status_error;
        END IF;
      END IF;
    --
    END LOOP main_loop;
    --
    -- 処理結果チェック
    IF ( lv_val_check_flag = cv_status_error ) THEN
      -- D-4の処理結果をセット
      gn_normal_cnt := gn_val_normal_cnt;
      gn_error_cnt  := gn_val_error_cnt;
    ELSE
      -- D-5の処理結果をセット
      gn_normal_cnt := gn_ins_normal_cnt;
      gn_error_cnt  := gn_ins_error_cnt;
    END IF;
    --
    -- D-5.16までの処理結果チェック
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- D-5.17 Disc品目マスタ登録
      -- 全ての登録処理が完了したら品目マスタ一括アップロードワークのレコード分、
      -- コンカレントを起動します。
      --==============================================================
      COMMIT;
      --
      -- Disc品目登録LOOP
      <<loop_conc>>
      FOR ln_conc_cnt IN 1..l_item_code_tab.COUNT LOOP
        -- 初期化
        lv_status_val := cv_status_val_normal;
        -- argument設定
        l_conc_argument_tab(1).argument := l_item_code_tab(ln_conc_cnt);
        <<loop_arg>>
        FOR ln_cnt IN 2..100 LOOP
          l_conc_argument_tab(ln_cnt).argument := CHR(0);
        END LOOP loop_arg;
        --
        -- OPM品目トリガー起動コンカレント実行
        xxcmm_004common_pkg.proc_conc_request(
          iv_appl_short_name => cv_appl_name_xxcmn
         ,iv_program         => cv_prog_opmitem_trigger  -- OPM品目トリガー起動コンカレント
         ,iv_description     => NULL
         ,iv_start_time      => NULL
         ,ib_sub_request     => FALSE
         ,i_argument_tab     => l_conc_argument_tab
         ,iv_wait_flag       => cv_yes
         ,on_request_id      => ln_request_id
         ,ov_errbuf          => lv_errbuf
         ,ov_retcode         => lv_retcode
         ,ov_errmsg          => lv_errmsg
        );
        --==============================================================
        -- XXCMM_004_品目共通関数からの返却値(lv_errmsg)
        --==============================================================
        -- コンカレント起動エラー時 ⇒ "コンカレントの起動に失敗しました。"
        -- コンカレント待機エラー時 ⇒ "コンカレントの待機処理に失敗しました。"
        -- コンカレント処理エラー時 ⇒ "コンカレント処理はエラー終了しました。[フェーズ、ステータス]"
        --
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_normal ) THEN
          -- OPM品目トリガー起動コンカレントを「正常」で返却
          lv_status_val      := cv_status_val_normal;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- OPM品目トリガー起動コンカレントを「警告」で返却
          lv_status_val      := SUBSTRB(cv_status_val_warn  || cv_msg_part || lv_errmsg, 1, 5000);
          lv_conc_check_flag := cv_status_error;
          lv_check_flag      := cv_status_error;
        ELSE
          -- OPM品目トリガー起動コンカレントを「エラー」で返却
          lv_status_val      := SUBSTRB(cv_status_val_error || cv_msg_part || lv_errmsg, 1, 5000);
          lv_conc_check_flag := cv_status_error;
          lv_check_flag      := cv_status_error;
        END IF;
        --
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn             -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmn_10627             -- メッセージコード
                      ,iv_token_name1  => cv_tkn_req_id                  -- トークンコード1
                      ,iv_token_value1 => ln_request_id                  -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code         -- トークンコード2
                      ,iv_token_value2 => l_item_code_tab(ln_conc_cnt)   -- トークン値2
                      ,iv_token_name3  => cv_tkn_msg                     -- トークンコード3
                      ,iv_token_value3 => lv_status_val                  -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      END LOOP loop_conc;
    END IF;
    --
    -- D-5.17処理結果チェック
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- D-6  Disc品目情報取得
      -- D-7  Disc品目カテゴリ割当
      -- Disc品目登録処理が完了したら、Disc品目カテゴリ割当を行ないます。
      --==============================================================
      get_disc_item_data(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        lv_check_flag := cv_status_error;
      END IF;
    END IF;
    -- チェックフラグの値を返却
    ov_retcode := lv_check_flag;
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
  END loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(D-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';     -- プログラム名
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
    lv_step                   VARCHAR2(10);                       -- ステップ
    lv_check_flag             VARCHAR2(1);                        -- チェックフラグ
    lv_get_check_flag         VARCHAR2(1);                        -- STEPチェックフラグ
    --
    ln_line_cnt               NUMBER;                             -- 行カウンタ
    ln_item_num               NUMBER;                             -- 項目数
    ln_item_cnt               NUMBER;                             -- 項目数カウンタ
    lv_file_name              VARCHAR2(100);                      -- ファイル名格納用
    ln_ins_item_cnt           NUMBER;                             -- 登録件数カウンタ
--
    lt_wk_item_tab            g_check_data_ttype;                 --  テーブル型変数を宣言(項目分割)
    lt_if_data_tab            xxcmn_common3_pkg.g_file_data_tbl;  --  テーブル型変数を宣言
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    blob_expt                 EXCEPTION;                          -- BLOBデータ変換エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    ln_ins_item_cnt := 0;
    --
    --==============================================================
    -- D-2.1 ファイルアップロードIFデータ取得
    --==============================================================
    xxcmn_common3_pkg.blob_to_varchar2(    -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id           -- ファイルＩＤ
     ,ov_file_data => lt_if_data_tab       -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- エラー件数をカウント
      gn_error_cnt := 1;
      RAISE blob_expt;
    END IF;
    --
    -- チェックフラグの初期化
    lv_check_flag     := cv_status_normal;
    --
    -- ワークテーブル登録LOOP
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..lt_if_data_tab.COUNT LOOP
      -- STEPチェックフラグの初期化
      lv_get_check_flag := cv_status_normal;
      --
      --==============================================================
      -- D-2.2 項目数のチェック
      --==============================================================
      -- 対象件数取得
      gn_target_cnt := gn_target_cnt + 1;
      -- データ項目数を格納
      ln_item_num := ( LENGTHB(lt_if_data_tab(ln_line_cnt))
                   - ( LENGTHB(REPLACE(lt_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- 項目数が一致しない場合
      IF ( gn_item_num <> ln_item_num ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmn_10638            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                      ,iv_token_value1 => cv_item_batch_regist          -- トークン値1
                      ,iv_token_name2  => cv_tkn_count                  -- トークンコード2
                      ,iv_token_value2 => ln_item_num                   -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no          -- トークンコード2
                      ,iv_token_value3 => ln_line_cnt                   -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
        --
        lv_get_check_flag := cv_status_error;
        lv_check_flag     := cv_status_error;
        --
      ELSE
        --
        --==============================================================
        -- D-2.3 対象データの分割
        --==============================================================
        <<get_column_loop>>
        FOR ln_item_cnt IN 1..gn_item_num LOOP
          -- 変数に項目の値を格納
          lt_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(
                                          iv_char     => lt_if_data_tab(ln_line_cnt)  -- 分割元文字列
                                         ,iv_delim    => cv_msg_comma                 -- デリミタ文字
                                         ,in_part_num => ln_item_cnt                  -- 返却対象INDEX
                                        );
          --==============================================================
          -- D-2.4 必須/型/サイズチェック
          --==============================================================
          xxccp_common_pkg2.upload_item_check(
            iv_item_name    => g_item_def_tab(ln_item_cnt).item_name          -- 項目名称
           ,iv_item_value   => lt_wk_item_tab(ln_item_cnt)                    -- 項目の値
           ,in_item_len     => g_item_def_tab(ln_item_cnt).item_length        -- 項目の長さ(整数部分)
           ,in_item_decimal => g_item_def_tab(ln_item_cnt).decim              -- 項目の長さ（小数点以下）
           ,iv_item_nullflg => g_item_def_tab(ln_item_cnt).item_essential     -- 必須フラグ
           ,iv_item_attr    => g_item_def_tab(ln_item_cnt).item_attribute     -- 項目の属性
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN                          -- 戻り値が正常以外の場合
            lv_errmsg  := xxcmn_common_pkg.get_msg(
                            iv_application   =>  cv_appl_name_xxcmn          -- アプリケーション短縮名
                           ,iv_name          =>  cv_msg_xxcmn_10639          -- メッセージコード
                           ,iv_token_name1   =>  cv_tkn_input_line_no        -- トークンコード1
                           ,iv_token_value1  =>  ln_line_cnt                 -- トークン値1
                           ,iv_token_name2   =>  cv_tkn_errmsg               -- トークンコード2
                           ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- トークン値2
                          );
            -- メッセージ出力
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
            --
            lv_get_check_flag := cv_status_error;
            lv_check_flag     := cv_status_error;
            --
          END IF;
        END LOOP get_column_loop;
        --==============================================================
        -- D-2.5 品目マスタ一括アップロードワーク登録
        --==============================================================
        -- 上記までのSTEPチェックが正常の場合
        IF ( lv_get_check_flag = cv_status_normal ) THEN 
          BEGIN
            ln_ins_item_cnt := ln_ins_item_cnt + 1;
            --
            INSERT INTO xxcmn_wk_item_batch_regist(
                file_id                     -- ファイルID
              , file_seq                    -- ファイルシーケンス
              , line_no                     -- 行番号
              , item_no                     -- 品目
              , item_desc                   -- 摘要
              , item_short_name             -- 略称
              , item_name_alt               -- カナ名
              , warehouse_item              -- 倉庫品目
              , item_um                     -- 単位（在庫単位）
              , old_crowd                   -- 旧群コード
              , new_crowd                   -- 新群コード
              , crowd_start_date            -- 群コード適用開始日
              , old_price                   -- 旧・定価
              , new_price                   -- 新・定価
              , price_start_date            -- 定価適用開始日
              , old_business_cost           -- 旧・営業原価 
              , new_business_cost           -- 新・営業原価 
              , business_start_date         -- 営業原価適用開始日 
              , sale_start_date             -- 発売開始日（製造開始日）
              , jan_code                    -- JANコード
              , itf_code                    -- ITFコード
              , case_num                    -- ケース入数
              , net                         -- NET
              , weight_volume_class         -- 重量容積区分
              , weight                      -- 重量
              , volume                      -- 容積
              , destination_class           -- 仕向区分
              , cost_management_class       -- 原価管理区分
              , vendor_price_deriday_ty     -- 仕入単価導出日タイプ
              , represent_num               -- 代表入数
              , mtl_units_of_measure_tl     -- 入出庫換算単位
              , need_test_class             -- 試験有無区分
              , inspection_lt               -- 検査L/T
              , judgment_times_num          -- 判定回数
              , order_judge_times_num       -- 発注可能判定回数
              , crowd_code                  -- 群コード
              , policy_group_code           -- 政策群コード
              , mark_crowd_code             -- マーケ用群コード
              , acnt_crowd_code             -- 経理部用群コード
              , item_product_class          -- 商品製品区分
              , hon_product_class           -- 本社商品区分
              , product_div                 -- 商品区分
              , item_class                  -- 品目区分
              , inout_class                 -- 内外区分
              , baracha_class               -- バラ茶区分
              , quality_class               -- 品質区分
              , fact_crowd_code             -- 工場群コード
              , start_date_active           -- 適用開始日
              , expiration_day_class        -- 賞味期間区分
              , expiration_day              -- 賞味期間
              , shelf_life                  -- 消費期間
              , delivery_lead_time          -- 納入期間
              , case_weight_volume          -- ケース重量容積
              , raw_material_consumpe       -- 原料使用量
              , standard_yield              -- 標準歩留
              , model_type                  -- 型種別
              , product_class               -- 商品分類
              , product_type                -- 商品種別
              , shipping_cs_unit_qty        -- 出荷入数
              , palette_max_cs_qty          -- パレ配数
              , palette_max_step_qty        -- パレ段数
              , palette_step_qty            -- パレット段
              , bottle_class                -- 容器区分
              , uom_class                   -- 単位区分
              , inventory_chk_class         -- 棚卸区分
              , trace_class                 -- トレース区分
              , rate_class                  -- 率区分
              , shipping_end_date           -- 出荷停止日
              , created_by                  -- 作成者
              , creation_date               -- 作成日
              , last_updated_by             -- 最終更新者
              , last_update_date            -- 最終更新日
              , last_update_login           -- 最終更新ログイン
              , request_id                  -- 要求ID
              , program_application_id      -- コンカレント・プログラム・アプリケーションID
              , program_id                  -- コンカレント・プログラムID
              , program_update_date         -- プログラム更新日
             ) VALUES (
               gn_file_id                   -- ファイルID
             , ln_ins_item_cnt              -- ファイルシーケンス
             , lt_wk_item_tab(1)            -- 行番号
             , lt_wk_item_tab(2)            -- 品目
             , lt_wk_item_tab(3)            -- 摘要
             , lt_wk_item_tab(4)            -- 略称
             , lt_wk_item_tab(5)            -- カナ名
             , lt_wk_item_tab(6)            -- 倉庫品目
             , lt_wk_item_tab(7)            -- 単位（在庫単位）
             , lt_wk_item_tab(8)            -- 旧群コード
             , lt_wk_item_tab(9)            -- 新群コード
             , lt_wk_item_tab(10)           -- 群コード適用開始日
             , lt_wk_item_tab(11)           -- 旧・定価
             , lt_wk_item_tab(12)           -- 新・定価
             , lt_wk_item_tab(13)           -- 定価適用開始日
             , lt_wk_item_tab(14)           -- 旧・営業原価 
             , lt_wk_item_tab(15)           -- 新・営業原価 
             , lt_wk_item_tab(16)           -- 営業原価適用開始日 
             , lt_wk_item_tab(17)           -- 発売開始日（製造開始日）
             , lt_wk_item_tab(18)           -- JANコード
             , lt_wk_item_tab(19)           -- ITFコード
             , lt_wk_item_tab(20)           -- ケース入数
             , lt_wk_item_tab(21)           -- NET
             , lt_wk_item_tab(22)           -- 重量容積区分
             , lt_wk_item_tab(23)           -- 重量
             , lt_wk_item_tab(24)           -- 容積
             , lt_wk_item_tab(25)           -- 仕向区分
             , lt_wk_item_tab(26)           -- 原価管理区分
             , lt_wk_item_tab(27)           -- 仕入単価導出日タイプ
             , lt_wk_item_tab(28)           -- 代表入数
             , lt_wk_item_tab(29)           -- 入出庫換算単位
             , lt_wk_item_tab(30)           -- 試験有無区分
             , lt_wk_item_tab(31)           -- 検査L/T
             , lt_wk_item_tab(32)           -- 判定回数
             , lt_wk_item_tab(33)           -- 発注可能判定回数
             , lt_wk_item_tab(34)           -- 群コード
             , lt_wk_item_tab(35)           -- 政策群コード
             , lt_wk_item_tab(36)           -- マーケ用群コード
             , lt_wk_item_tab(37)           -- 経理部用群コード
             , lt_wk_item_tab(38)           -- 商品製品区分
             , lt_wk_item_tab(39)           -- 本社商品区分
             , lt_wk_item_tab(40)           -- 商品区分
             , lt_wk_item_tab(41)           -- 品目区分
             , lt_wk_item_tab(42)           -- 内外区分
             , lt_wk_item_tab(43)           -- バラ茶区分
             , lt_wk_item_tab(44)           -- 品質区分
             , lt_wk_item_tab(45)           -- 工場群コード
             , lt_wk_item_tab(46)           -- 適用開始日
             , lt_wk_item_tab(47)           -- 賞味期間区分
             , lt_wk_item_tab(48)           -- 賞味期間
             , lt_wk_item_tab(49)           -- 消費期間
             , lt_wk_item_tab(50)           -- 納入期間
             , lt_wk_item_tab(51)           -- ケース重量容積
             , lt_wk_item_tab(52)           -- 原料使用量
             , lt_wk_item_tab(53)           -- 標準歩留
             , lt_wk_item_tab(54)           -- 型種別
             , lt_wk_item_tab(55)           -- 商品分類
             , lt_wk_item_tab(56)           -- 商品種別
             , lt_wk_item_tab(57)           -- 出荷入数
             , lt_wk_item_tab(58)           -- パレ配数
             , lt_wk_item_tab(59)           -- パレ段数
             , lt_wk_item_tab(60)           -- パレット段
             , lt_wk_item_tab(61)           -- 容器区分
             , lt_wk_item_tab(62)           -- 単位区分
             , lt_wk_item_tab(63)           -- 棚卸区分
             , lt_wk_item_tab(64)           -- トレース区分
             , lt_wk_item_tab(65)           -- 率区分
             , lt_wk_item_tab(66)           -- 出荷停止日
             , gn_created_by                -- 作成者
             , gd_creation_date             -- 作成日
             , gn_last_updated_by           -- 最終更新者
             , gd_last_update_date          -- 最終更新日
             , gn_last_update_login         -- 最終更新ログインID
             , gn_request_id                -- 要求ID
             , gn_program_application_id    -- コンカレント・プログラムのアプリケーションID
             , gn_program_id                -- コンカレント・プログラムID
             , gd_program_update_date       -- プログラムによる更新日
            );
          --
          EXCEPTION
            -- *** データ登録例外ハンドラ ***
            WHEN OTHERS THEN
              lv_errmsg  := xxcmn_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcmn       -- アプリケーション短縮名
                             ,iv_name         => cv_msg_xxcmn_10626       -- メッセージコード
                             ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                             ,iv_token_value1 => cv_table_xwibr           -- トークン値1
                             ,iv_token_name2  => cv_tkn_input_line_no     -- トークンコード2
                             ,iv_token_value2 => lt_wk_item_tab(1)        -- トークン値2
                             ,iv_token_name3  => cv_tkn_input_item_code   -- トークンコード3
                             ,iv_token_value3 => lt_wk_item_tab(2)        -- トークン値3
                             ,iv_token_name4  => cv_tkn_errmsg            -- トークンコード4
                             ,iv_token_value4 => SQLERRM                  -- トークン値4
                            );
              -- エラー件数加算
              gn_get_error_cnt := gn_get_error_cnt + 1;
              lv_errbuf  := lv_errmsg;
              RAISE global_api_expt;
          END;
        END IF;
      END IF;
      --
      -- STEPチェック判定
      IF ( lv_get_check_flag = cv_status_normal ) THEN
        -- 正常件数加算
        gn_get_normal_cnt := gn_get_normal_cnt + 1;
      ELSE
        -- エラー件数加算
        gn_get_error_cnt  := gn_get_error_cnt + 1;
      END IF;
    END LOOP ins_wk_loop;
--
  -- チェックフラグの値を返却
  ov_retcode := lv_check_flag;
  --
  EXCEPTION
    -- *** BLOBデータ変換エラー例外ハンドラ ***
    WHEN blob_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10640            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_file_id                -- トークンコード1
                    ,iv_token_value1 => gn_file_id                    -- トークン値1
                   );
      RAISE global_api_expt;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(D-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';              -- プログラム名
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
    lv_tkn_value              VARCHAR2(100);   -- トークン値
    lv_sqlerrm                VARCHAR2(5000);  -- SQLERRMを退避
    --
    lv_up_name                VARCHAR2(1000);  -- アップロード名称出力用
    lv_file_id                VARCHAR2(1000);  -- ファイルID出力用
    lv_file_format            VARCHAR2(1000);  -- フォーマット出力用
    lv_file_name              VARCHAR2(1000);  -- ファイル名出力用
    lv_value_name             VARCHAR2(1000);  -- 項目名
    lv_table_name             VARCHAR2(1000);  -- テーブル名
    ln_cnt                    NUMBER;          -- カウンタ
    lv_csv_file_name          xxinv_mrp_file_ul_interface.file_name%TYPE;      -- ファイル名格納用
    ln_created_by             xxinv_mrp_file_ul_interface.created_by%TYPE;     -- 作成者格納用
    ld_creation_date          xxinv_mrp_file_ul_interface.creation_date%TYPE;  -- 作成日格納用
--
    -- *** ローカル・カーソル ***
    -- データ項目定義取得用カーソル
    CURSOR     get_def_info_cur
    IS
      SELECT   xlvv.meaning                     AS item_name       -- 内容
              ,DECODE(xlvv.attribute1, cv_varchar, cv_varchar_cd
                                     , cv_number , cv_number_cd
                                     , cv_date_cd
                     )                          AS item_attribute  -- 項目属性
              ,DECODE(xlvv.attribute2, cv_not_null, cv_null_ng
                                                  , cv_null_ok
                     )                          AS item_essential  -- 必須フラグ
              ,TO_NUMBER(xlvv.attribute3)       AS item_length     -- 長さ(整数)
              ,TO_NUMBER(xlvv.attribute4)       AS decim           -- 長さ(小数点以下)
      FROM     xxcmn_lookup_values_v  xlvv  -- クイックコードVIEW
      WHERE    xlvv.lookup_type        = cv_lookup_item_def
      ORDER BY xlvv.lookup_code
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_param_expt            EXCEPTION;       -- パラメータNULLエラー
    get_profile_expt          EXCEPTION;       -- プロファイル取得例外
    get_process_date_expt     EXCEPTION;       -- 業務日付取得失敗エラー
    get_data_expt             EXCEPTION;       -- データ取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- D-1.1 入力パラメータ（FILE_ID、フォーマット）のNULLチェック
    --==============================================================
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_format_check;
      RAISE get_param_expt;
    END IF;
    --
    -- INパラメータを格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- D-1.2 業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULLチェック
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
    --
    --==============================================================
    -- D-1.3 プロファイル値取得
    --==============================================================
    -- 品目マスタ一括アップロード項目数の取得
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num));
    -- 取得エラー時
    IF ( gn_item_num IS NULL ) THEN
      lv_tkn_value := cv_prf_item_num;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（商品製品区分）の取得
    gt_ctg_item_prod := FND_PROFILE.VALUE(cv_prf_ctg_item_prod);
    -- 取得エラー時
    IF ( gt_ctg_item_prod IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_item_prod;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（本社商品区分）の取得
    gt_ctg_hon_prod := FND_PROFILE.VALUE(cv_prf_ctg_hon_prod);
    -- 取得エラー時
    IF ( gt_ctg_hon_prod IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_hon_prod;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（マーケ群コード）の取得
    gt_ctg_mark_pg := FND_PROFILE.VALUE(cv_prf_ctg_mark_pg);
    -- 取得エラー時
    IF ( gt_ctg_mark_pg IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_mark_pg;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（群コード）の取得
    gt_ctg_gun_code := FND_PROFILE.VALUE(cv_prf_ctg_gun_code);
    -- 取得エラー時
    IF ( gt_ctg_gun_code IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_gun_code;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（品目区分）の取得
    gt_ctg_item_class := FND_PROFILE.VALUE(cv_prf_ctg_item_div);
    -- 取得エラー時
    IF ( gt_ctg_item_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_item_div;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（内外区分）の取得
    gt_ctg_inout_class := FND_PROFILE.VALUE(cv_prf_ctg_inout_class);
    -- 取得エラー時
    IF ( gt_ctg_inout_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_inout_class;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（工場群コード）の取得
    gt_ctg_fact_pg := FND_PROFILE.VALUE(cv_prf_ctg_fact_pg);
    -- 取得エラー時
    IF ( gt_ctg_fact_pg IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_fact_pg;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（経理部用群コード）の取得
    gt_ctg_acnt_pg := FND_PROFILE.VALUE(cv_prf_ctg_acnt_pg);
    -- 取得エラー時
    IF ( gt_ctg_acnt_pg IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_acnt_pg;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（政策群コード）の取得
    gt_ctg_seisakugun := FND_PROFILE.VALUE(cv_prf_ctg_seisakugun);
    -- 取得エラー時
    IF ( gt_ctg_seisakugun IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_seisakugun;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（バラ茶区分）の取得
    gt_ctg_baracha_class := FND_PROFILE.VALUE(cv_prf_ctg_baracha_class);
    -- 取得エラー時
    IF ( gt_ctg_baracha_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_baracha_class;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（商品区分）の取得
    gt_ctg_product_div := FND_PROFILE.VALUE(cv_prf_ctg_product_div);
    -- 取得エラー時
    IF ( gt_ctg_product_div IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_product_div;
      RAISE get_profile_expt;
    END IF;
    --
    -- 品目カテゴリセット名（品質区分）の取得
    gt_ctg_quality_class := FND_PROFILE.VALUE(cv_prf_ctg_quality_class);
    -- 取得エラー時
    IF ( gt_ctg_quality_class IS NULL ) THEN
      lv_tkn_value := cv_prf_ctg_quality_class;
      RAISE get_profile_expt;
    END IF;
    --
    -- マスタ在庫組織コードの取得
    gt_master_org_code := FND_PROFILE.VALUE(cv_prf_mst_org_code);
    -- 取得エラー時
    IF ( gt_master_org_code IS NULL ) THEN
      lv_tkn_value := cv_prf_mst_org_code;
      RAISE get_profile_expt;
    END IF;
    --
    --==============================================================
    -- D-1.4 マスタ在庫組織ID取得
    --==============================================================
    BEGIN
      SELECT  mp.organization_id  AS master_org_id       -- マスタ在庫組織ID
      INTO    gn_master_org_id
      FROM    mtl_parameters  mp  -- 組織パラメータ
      WHERE   mp.organization_code = gt_master_org_code  -- 上記で取得したマスタ在庫組織コード
      ;
    --
    EXCEPTION
      -- 取得エラー時
      WHEN NO_DATA_FOUND THEN
        lv_value_name := cv_mst_org_id;
        RAISE get_data_expt;
    END;
    --
    --==============================================================
    -- D-1.5 ファイルアップロードIFデータ取得
    --==============================================================
    BEGIN
      SELECT  fui.file_name          AS file_name           -- ファイル名
             ,fui.created_by         AS created_by          -- 作成者
             ,fui.creation_date      AS creation_date       -- 作成日
      INTO    lv_csv_file_name
             ,ln_created_by
             ,ld_creation_date
      FROM    xxinv_mrp_file_ul_interface  fui              -- ファイルアップロードIFテーブル
      WHERE   fui.file_id = gn_file_id                      -- ファイルID
      FOR UPDATE NOWAIT
      ;
    --
    EXCEPTION
      -- 取得エラー時
      WHEN NO_DATA_FOUND THEN
        lv_value_name := cv_table_xmfui;
        RAISE get_data_expt;
      -- ロック取得エラー時
      WHEN global_check_lock_expt THEN
        lv_table_name := cv_table_xmfui;
        RAISE global_check_lock_expt;
    END;
    --
    --==============================================================
    -- D-1.6 品目マスタ一括アップロードワーク定義情報の取得
    --==============================================================
    -- 変数の初期化
    ln_cnt := 0;
    -- テーブル定義取得LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_item_def_tab(ln_cnt).item_name       := get_def_info_rec.item_name;       -- 項目名
      g_item_def_tab(ln_cnt).item_attribute  := get_def_info_rec.item_attribute;  -- 項目属性
      g_item_def_tab(ln_cnt).item_essential  := get_def_info_rec.item_essential;  -- 必須フラグ
      g_item_def_tab(ln_cnt).item_length     := get_def_info_rec.item_length;     -- 長さ(整数部分)
      g_item_def_tab(ln_cnt).decim           := get_def_info_rec.decim;           -- 長さ(小数点以下)
    END LOOP def_info_loop;
    -- 定義情報が取得できない場合はエラー
    IF ( ln_cnt = 0 ) THEN
      lv_value_name := cv_table_def;
      RAISE get_data_expt;
    END IF;
    --
    --==============================================================
    -- D-1.7 INパラメータの出力
    --==============================================================
    lv_up_name     := xxcmn_common_pkg.get_msg(                -- アップロード名称の出力
                        iv_application  => cv_appl_name_xxcmn  -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmn_10631  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_up_name      -- トークンコード1
                       ,iv_token_value1 => cv_upload_name      -- トークン値1
                      );
    lv_file_name   := xxcmn_common_pkg.get_msg(                -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmn  -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmn_10632  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_name    -- トークンコード1
                       ,iv_token_value1 => lv_csv_file_name    -- トークン値1
                      );
    lv_file_id     := xxcmn_common_pkg.get_msg(                -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmn  -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmn_10633  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id      -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(gn_file_id) -- トークン値1
                      );
    lv_file_format := xxcmn_common_pkg.get_msg(                -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcmn   -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmn_10634   -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_format   -- トークンコード1
                      ,iv_token_value1 => gv_format            -- トークン値1
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                -- 出力に表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                   -- ログに表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** 業務日付取得失敗エラー ***
    WHEN get_process_date_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10628            -- メッセージ
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# 任意 #
    --*** パラメータNULLエラー ***
    WHEN get_param_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10635            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# 任意 #
    --
    --*** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10002            -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile             -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# 任意 #
    --
    --*** データ取得エラー ***
    WHEN get_data_expt THEN
      lv_errmsg   := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmn_10636            -- メッセージコード
                      ,iv_token_name1  => cv_tkn_value
                      ,iv_token_value1 => lv_value_name
                     );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# 任意 #
    --
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmn_10637            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_table_name
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                        --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                  --# 任意 #
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ         --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード           --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_loop_errbuf   VARCHAR2(5000);    -- D-2～D-7時のエラー・メッセージ
    lv_loop_retcode  VARCHAR2(1);       -- D-2～D-7時のリターン・コード
    lv_loop_errmsg   VARCHAR2(5000);    -- D-2～D-7時のユーザー・エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
    --
    gn_get_normal_cnt := 0;  -- 型/サイズ/必須チェックOK件数
    gn_get_error_cnt  := 0;  -- 型/サイズ/必須チェックNG件数
    gn_val_normal_cnt := 0;  -- 妥当性チェックOK件数
    gn_val_error_cnt  := 0;  -- 妥当性チェックNG件数
    gn_ins_normal_cnt := 0;  -- データ登録OK件数
    gn_ins_error_cnt  := 0;  -- データ登録NG件数
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    -- D-1.  初期処理
    --==============================================================
    proc_init(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode = cv_status_normal ) THEN
      --==============================================================
      -- D-2.  ファイルアップロードIFデータ取得
      --==============================================================
      get_if_data(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        --  D-3  品目マスタ一括アップロードワークデータ取得
        --  D-4  品目マスタ一括アップロードワークデータ妥当性チェック
        --  D-5  データ登録
        --  D-6  Disc品目情報取得
        --  D-7  Disc品目カテゴリ割当
        --==============================================================
        loop_main(
          ov_errbuf  => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode => lv_retcode          -- リターン・コード
         ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
        );
        -- 処理結果チェック
        IF ( lv_retcode = cv_status_error ) THEN
          ROLLBACK;
        END IF;
      ELSE
        -- D-2でエラーの場合、D-2の処理結果をセット
        gn_normal_cnt := gn_get_normal_cnt;
        gn_error_cnt  := gn_get_error_cnt;
      END IF;
    ELSE
      -- D-1でエラーの場合、エラー1件をセット
      gn_error_cnt := 1;
    END IF;
--
    -- D-1～D-7の処理結果を設定
    lv_loop_errbuf  := lv_errbuf;
    lv_loop_retcode := lv_retcode;
    lv_loop_errmsg  := lv_errmsg;
--
    --==============================================================
    -- D-8  終了処理
    --==============================================================
    proc_comp(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
--
    -- D-1～D-7の処理でエラーが発生している場合
    IF ( lv_loop_retcode = cv_status_error ) THEN
      ov_errmsg  := lv_loop_errmsg;
      ov_errbuf  := lv_loop_errbuf;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- 処理結果チェック
    IF ( lv_retcode = cv_status_normal ) THEN
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
    --
  EXCEPTION
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
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT    VARCHAR2       --   エラー・メッセージ  --# 固定 #
   ,retcode       OUT    VARCHAR2       --   エラーコード     #固定#
   ,iv_file_id    IN     VARCHAR2       --   ファイルID
   ,iv_format     IN     VARCHAR2       --   フォーマット
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
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
--###########################  固定部 START   #################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
--
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name  AS conc_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1
    ;
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
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
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
    --ステータス出力
    SELECT flv.meaning  AS conc_status
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type
                                                                    , flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode
                                          , cv_status_normal ,cv_sts_cd_normal
                                          , cv_status_warn   ,cv_sts_cd_warn
                                          , cv_sts_cd_error)
    AND    ROWNUM                  = 1
    ;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMN810004C;
/
