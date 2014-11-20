CREATE OR REPLACE PACKAGE BODY xxcmn810002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn810002c(body)
 * Description      : 品目マスタ更新(日次)
 * MD.050           : 品目マスタ T_MD050_BPO_810
 * MD.070           : 品目マスタ更新(日次)(81B) T_MD070_BPO_81B
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_mtl_categories    品目カテゴリ登録処理  2008/09/24 Add
 *  proc_item_category     品目割当登録処理      2008/09/24 Add
 *  parameter_check        パラメータ抽出処理                        (B-1)
 *  put_item_mst           OPM品目アドオンマスタ情報格納             (B-3)
 *  put_gmi_item_g         品目カテゴリマスタ情報格納(群コード)      (B-4)
 *  put_gmi_item_k         品目カテゴリマスタ情報格納(工場群コード)  (B-5)
 *  update_item_mst_b      OPM品目マスタ反映                         (B-6)
 *  update_categories      OPM品目カテゴリ割当反映                   (B-7)
 *  update_xxcmn_item      OPM品目アドオンマスタ反映                 (B-8)
 *  get_sysitems_b         品目マスタ取得                            (B-9)
 *  update_mtl_item_f      品目マスタ反映(予約可能)                  (B-10)
 *  disp_report            処理結果レポート出力
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/12    1.0   T.Iwasa          main新規作成
 *  2008/05/02    1.1   H.Marushita      内部変更要求No.81対応
 *  2008/05/20    1.2   H.Marushita      内部変更要求No.105対応
 *  2008/09/11    1.3   Oracle 山根一浩  指摘115対応
 *  2008/09/24    1.4   Oracle 山根一浩  T_S_421対応
 *  2008/09/29    1.5   Oracle 山根一浩  T_S_546,T_S_547対応
 *  2008/11/24    1.6   Oracle 大橋孝郎  本番環境問合せ_障害管理表220対応
 *  2009/01/28    1.7   Oracle 椎名昭圭  本番#1022対応
 *  2009/02/27    1.8   Oracle 椎名昭圭  本番#1212対応
 *  2009/11/25    1.9   SCS 伊藤ひとみ   本番障害#83対応
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  parameter_expt         EXCEPTION;               -- パラメータ例外
  lock_expt              EXCEPTION;               -- ロック取得例外
  profile_expt           EXCEPTION;               -- プロファイル取得エラー
  no_data                EXCEPTION;               -- ０件処理
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  -- 定数
  gv_pkg_name         CONSTANT VARCHAR2(15) := 'xxcmn810002c';      -- パッケージ名
  gv_app_name         CONSTANT VARCHAR2(5)  := 'XXCMN';             -- アプリケーション短縮名
                                                                    -- プロファイル：群コード
  gv_tkn_name_01      CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_OTGUN';
                                                                    -- プロファイル：工場群コード
  gv_tkn_name_02      CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_KJGUN';
                                                                    -- プロファイル：群コード
  gv_tkn_name_03      CONSTANT VARCHAR2(50) := '群コード';
                                                                    -- プロファイル：工場群コード
  gv_tkn_name_04      CONSTANT VARCHAR2(50) := '工場群コード';
--2008/09/24 Add
  gv_tkn_name_05      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_CROWD_CODE';
  gv_tkn_name_06      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_POLICY_CODE';
  gv_tkn_name_07      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_MARKET_CODE';
  gv_tkn_name_08      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_ACNT_CROWD_CODE';
  gv_tkn_name_09      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_FACTORY_CODE';
  gv_tkn_name_10      CONSTANT VARCHAR2(50) := '初期値：群コード';
  gv_tkn_name_11      CONSTANT VARCHAR2(50) := '初期値：政策群コード';
  gv_tkn_name_12      CONSTANT VARCHAR2(50) := '初期値：マーケ用群コード';
  gv_tkn_name_13      CONSTANT VARCHAR2(50) := '初期値：経理部用群コード';
  gv_tkn_name_14      CONSTANT VARCHAR2(50) := '初期値：工場群コード';
--
  -- メッセージ
  gv_msg_xxcmn10002   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';   -- プロファイル取得エラー
  gv_msg_xxcmn10019   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';   -- ロック取得エラー
  gv_msg_xxcmn10083   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10083';   -- パラメータ日付型チェックNG
  gv_msg_xxcmn10084   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10084';   -- パラメータNULLチェックNG
--2008/09/24 Add
  gv_msg_xxcmn10085   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';   --APIエラー(コンカレント)
--
  -- トークン
  gv_tkn_table        CONSTANT VARCHAR2(10) := 'TABLE';             -- トークン：テーブル名
  gv_tkn_profile      CONSTANT VARCHAR2(10) := 'NG_PROFILE';        -- トークン：プロファイル名
--2008/09/24 Add
  gv_tkn_api_name     CONSTANT VARCHAR2(15) := 'API_NAME';          -- トークン：API名
--
  gn_data_status_nomal  CONSTANT  NUMBER := 0;                      -- 正常
  gn_data_status_error  CONSTANT  NUMBER := 1;                      -- 異常
--2008/09/24 Add
  gn_proc_flg_01        CONSTANT  NUMBER := 1;                      -- 郡コード
  gn_proc_flg_02        CONSTANT  NUMBER := 2;                      -- 工場群コード
--
  gv_crowd_code         CONSTANT VARCHAR2(50) := '群コード';
  gv_policy_group_code  CONSTANT VARCHAR2(50) := '政策群コード';
  gv_marke_crowd_code   CONSTANT VARCHAR2(50) := 'マーケ用群コード';
  gv_acnt_crowd_code    CONSTANT VARCHAR2(50) := '経理部用群コード';
  gv_factory_code       CONSTANT VARCHAR2(50) := '工場群コード';
--2008/09/24 Add
--
-- 2009/02/27 v1.8 ADD START
  gv_start_batch        CONSTANT VARCHAR2(1) := '0';                -- バッチ
--
-- 2009/02/27 v1.8 ADD END
  -- xxcmn共通関数リターン・コード：1(エラー)
  gn_rel_code         CONSTANT NUMBER       := 1;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***************************************
  -- ***    取得情報格納レコード型定義   ***
  -- ***************************************
--
  -- OPM品目マスタ群取得レコード
  TYPE master_item01_rec IS RECORD(
    -- OPM品目マスタ
    item_id             ic_item_mst_b.item_id%TYPE,                     -- 品目ID(OPM品目マスタ)
    item_no             ic_item_mst_b.item_no%TYPE,                     -- 品目
    attribute2          ic_item_mst_b.attribute2%TYPE,                  -- 新・群コード
    -- OPM品目アドオンマスタ
    start_date_active   xxcmn_item_mst_b.start_date_active%TYPE,        -- 適用開始日
    item_name           xxcmn_item_mst_b.item_name%TYPE,                -- 正式名
    expiration_day      xxcmn_item_mst_b.expiration_day%TYPE,           -- 賞味期間
    whse_county_code    xxcmn_item_mst_b.whse_county_code%TYPE          -- 工場群コード
--2008/09/29 ↓
    ,cs_weigth_or_capacity xxcmn_item_mst_b.cs_weigth_or_capacity%TYPE  -- ケース重量容積
--2008/09/29 ↑
  );
--
  -- OPM品目カテゴリ割当取得レコード
  TYPE category_item02_rec IS RECORD(
    category_set_id     gmi_item_categories.category_set_id%TYPE,       -- カテゴリセットID
    category_id         gmi_item_categories.category_id%TYPE            -- カテゴリID
  );
--
  -- 処理結果出力用レコード
  TYPE report_item03_rec IS RECORD(
    item_no             ic_item_mst_b.item_no%TYPE,                     -- 品目
    attribute2          ic_item_mst_b.attribute2%TYPE,                  -- 新・群コード
    start_date_active   xxcmn_item_mst_b.start_date_active%TYPE,        -- 適用開始日
    expiration_day      xxcmn_item_mst_b.expiration_day%TYPE,           -- 賞味期間
    whse_county_code    xxcmn_item_mst_b.whse_county_code%TYPE,         -- 工場群コード
    item_name           xxcmn_item_mst_b.item_name%TYPE                 -- 正式名
  );
--
  -- ***************************************
  -- ***    更新項目格納テーブル型定義   ***
  -- ***************************************
  -- OPM品目マスタ項目のテーブル型定義
  -- 品目ID
  TYPE im_item_id           IS TABLE OF ic_item_mst_b.item_id           %TYPE INDEX BY BINARY_INTEGER;
  -- 摘要
  TYPE im_item_desc1        IS TABLE OF ic_item_mst_b.item_desc1        %TYPE INDEX BY BINARY_INTEGER;
  -- 保存期間
  TYPE im_shelf_life        IS TABLE OF ic_item_mst_b.shelf_life        %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE im_last_update_date  IS TABLE OF ic_item_mst_b.last_update_date  %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE im_last_updated_by   IS TABLE OF ic_item_mst_b.last_updated_by   %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE im_last_update_login IS TABLE OF ic_item_mst_b.last_update_login %TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE im_request_id        IS TABLE OF ic_item_mst_b.request_id        %TYPE INDEX BY BINARY_INTEGER;
  -- プログラムID
  TYPE im_program_id        IS TABLE OF ic_item_mst_b.program_id        %TYPE INDEX BY BINARY_INTEGER;
  -- プログラムアプリケーションID
  TYPE im_program_application_id IS TABLE OF ic_item_mst_b.program_application_id %TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE im_program_update_date    IS TABLE OF ic_item_mst_b.program_update_date    %TYPE INDEX BY BINARY_INTEGER;
--
  -- OPM品目アドオンマスタ項目のテーブル型定義
  -- 品目ID
  TYPE xm_item_id           IS TABLE OF xxcmn_item_mst_b.item_id            %TYPE INDEX BY BINARY_INTEGER;
  -- 適用開始日
  TYPE xm_start_date_active IS TABLE OF xxcmn_item_mst_b.start_date_active  %TYPE INDEX BY BINARY_INTEGER;
  -- 適用済フラグ
  TYPE xm_active_flag       IS TABLE OF xxcmn_item_mst_b.active_flag        %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE xm_last_update_date  IS TABLE OF xxcmn_item_mst_b.last_update_date   %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE xm_last_updated_by   IS TABLE OF xxcmn_item_mst_b.last_updated_by    %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE xm_last_update_login IS TABLE OF xxcmn_item_mst_b.last_update_login  %TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE xm_request_id        IS TABLE OF xxcmn_item_mst_b.request_id         %TYPE INDEX BY BINARY_INTEGER;
  -- プログラムID
  TYPE xm_program_id        IS TABLE OF xxcmn_item_mst_b.program_id         %TYPE INDEX BY BINARY_INTEGER;
  -- プログラムアプリケーションID
  TYPE xm_program_application_id IS TABLE OF xxcmn_item_mst_b.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE xm_program_update_date    IS TABLE OF xxcmn_item_mst_b.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--2008/09/29 Add ↓
  -- ケース重量容積
  TYPE xm_cs_weigth_or_capacity IS TABLE OF xxcmn_item_mst_b.cs_weigth_or_capacity%TYPE INDEX BY BINARY_INTEGER;
--2008/09/29 Add ↑
--
  -- OPM品目カテゴリ割当項目のテーブル型定義
  -- 品目ID
  TYPE gm_item_id           IS TABLE OF gmi_item_categories.item_id           %TYPE INDEX BY BINARY_INTEGER;
  -- カテゴリセットID
  TYPE gm_category_set_id   IS TABLE OF gmi_item_categories.category_set_id   %TYPE INDEX BY BINARY_INTEGER;
  -- カテゴリID
  TYPE gm_category_id       IS TABLE OF gmi_item_categories.category_id       %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE gm_last_updated_by   IS TABLE OF gmi_item_categories.last_updated_by   %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE gm_last_update_date  IS TABLE OF gmi_item_categories.last_update_date  %TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE gm_last_update_login IS TABLE OF gmi_item_categories.last_update_login %TYPE INDEX BY BINARY_INTEGER;
  -- 品目マスタ(予約可能フラグ)のテーブル型定義
  TYPE mt_inv_item_id       IS TABLE OF mtl_system_items_b.inventory_item_id  %TYPE INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***      項目格納テーブル型定義     ***
  -- ***************************************
--
  -- OPM品目マスタ群格納用テーブル型定義
  TYPE master_item01_tbl    IS TABLE OF master_item01_rec   INDEX BY PLS_INTEGER;
  -- OPM品目カテゴリ割当格納用テーブル型定義
  TYPE master_item02_tbl    IS TABLE OF category_item02_rec INDEX BY PLS_INTEGER;
  -- 処理結果レポート用テーブル
  TYPE report_item03_tbl    IS TABLE OF report_item03_rec   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_max_date               DATE;                 -- MAX日付
  gv_applied_date           DATE;                 -- 適用日付
  gv_group_code             VARCHAR2(20);         -- プロファイル(カテゴリ名)：群コード
  gv_whse_county_code       VARCHAR2(20);         -- プロファイル(カテゴリ名)：工場群コード
  gt_im_item_id             im_item_id;           -- OPM品目マスタ：品目ID
  gt_im_item_desc1          im_item_desc1;        -- OPM品目マスタ：摘要
  gt_im_shelf_life          im_shelf_life;        -- OPM品目マスタ：保存期間
  gt_xm_item_id             xm_item_id;           -- OPM品目アドオンマスタ：品目ID
  gt_xm_start_date_active   xm_start_date_active; -- OPM品目アドオンマスタ：適用開始日
  gt_xm_active_flag         xm_active_flag;       -- OPM品目アドオンマスタ：適用済みフラグ
--2008/09/29 Add ↓
  gt_xm_cs_wc               xm_cs_weigth_or_capacity; -- OPM品目アドオンマスタ：ケース重量容積
--2008/09/29 Add ↑
  gt_gm_item_id_g           gm_item_id;           -- OPM品目カテゴリ割当：カテゴリID(群コード用)
  gt_gm_category_set_id_g   gm_category_set_id;   -- OPM品目カテゴリ割当：カテゴリセットID
  gt_gm_category_id_g       gm_category_id;       -- OPM品目カテゴリ割当：カテゴリID
  gt_gm_item_id_k           gm_item_id;           -- OPM品目カテゴリ割当：カテゴリID(工場群コード用)
  gt_gm_category_set_id_k   gm_category_set_id;   -- OPM品目カテゴリ割当：カテゴリセットID
  gt_gm_category_id_k       gm_category_id;       -- OPM品目カテゴリ割当：カテゴリID
  gt_mt_invflg_item_id      mt_inv_item_id;       -- 品目マスタ：品目ID(予約可能フラグ)
  gd_last_update_date       DATE;                 -- 最終更新日
  gv_last_update_by         VARCHAR2(100);        -- 最終更新者
  gv_last_update_login      VARCHAR2(100);        -- 最終更新ログイン
  gv_request_id             VARCHAR2(100);        -- 要求ID
  gv_program_application_id VARCHAR2(100);        -- プログラムアプリケーションID
  gv_program_id             VARCHAR2(100);        -- プログラムID
  gd_program_update_date    DATE;                 -- プログラム更新日
--2008/09/11 Add
  -- 郡コード初期値
  gv_def_crowd_code         VARCHAR2(20);         -- 初期値：群コード
  gv_def_policy_code        VARCHAR2(20);         -- 初期値：政策群コード
  gv_def_market_code        VARCHAR2(20);         -- 初期値：マーケ用群コード
  gv_def_acnt_crowd_code    VARCHAR2(20);         -- 初期値：経理部用群コード
  gv_def_factory_code       VARCHAR2(20);         -- 初期値：工場群コード
--
-- 2008/09/24 Add ↓
  /***********************************************************************************
   * Procedure Name   : proc_mtl_categories
   * Description      : 品目カテゴリの登録処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_mtl_categories(
    ir_item01_rec   IN     master_item01_rec,   -- OPM品目マスタレコード
    in_proc_flg     IN     NUMBER,              -- 処理フラグ
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_mtl_categories'; -- プログラム名
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
    cv_lang                 CONSTANT VARCHAR2(5)    := USERENV('LANG');                    -- 日本語
--
    -- *** ローカル変数 ***
    ln_category_set_id     mtl_category_sets_b.category_set_id%TYPE;
    ln_structure_id        mtl_category_sets_b.structure_id%TYPE;
    lv_category_set_name   mtl_category_sets_tl.category_set_name%TYPE;
    lr_category_rec        INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
    ln_category_id         NUMBER;
    lv_return_status       VARCHAR2(30);
    ln_errorcode           NUMBER;
    ln_msg_count           NUMBER;
    lv_msg_data            VARCHAR2(2000);
    lv_api_name            VARCHAR2(200);
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
    -- 郡コード
    IF (in_proc_flg = gn_proc_flg_01) THEN
      lv_category_set_name := gv_group_code;
--
    -- 工場郡コード
    ELSIF (in_proc_flg = gn_proc_flg_02) THEN
      lv_category_set_name := gv_whse_county_code;
    END IF;
--
    BEGIN
      SELECT mcsb.category_set_id,                  -- カテゴリセットID
             mcsb.structure_id                      -- 構造ID
      INTO   ln_category_set_id,
             ln_structure_id
      FROM   mtl_category_sets_b   mcsb,
             mtl_category_sets_tl  mcst
      WHERE  mcsb.category_set_id   = mcst.category_set_id
      AND    mcst.language          = cv_lang
      AND    mcst.source_lang       = cv_lang
      AND    mcst.category_set_name = lv_category_set_name;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_others_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    lr_category_rec.structure_id := ln_structure_id;
--
    -- 郡コード
    IF (in_proc_flg = 1) THEN
      lr_category_rec.segment1     := ir_item01_rec.attribute2;
    -- 工場郡コード
    ELSIF (in_proc_flg = 2) THEN
      lr_category_rec.segment1     := ir_item01_rec.whse_county_code;
    END IF;
--
    lr_category_rec.summary_flag := 'N';
    lr_category_rec.enabled_flag := 'Y';
--
    lr_category_rec.web_status := NULL;
    lr_category_rec.supplier_enabled_flag := NULL;
--
    -- 品目カテゴリマスタ登録
    INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY(
       P_API_VERSION      => 1.0
      ,P_INIT_MSG_LIST    => FND_API.G_FALSE
      ,P_COMMIT           => FND_API.G_FALSE
      ,X_RETURN_STATUS    => lv_return_status
      ,X_ERRORCODE        => ln_errorcode
      ,X_MSG_COUNT        => ln_msg_count
      ,X_MSG_DATA         => lv_msg_data
      ,P_CATEGORY_REC     => lr_category_rec
      ,X_CATEGORY_ID      => ln_category_id
    );
--
    -- 失敗
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_msg_xxcmn10085,
                                            gv_tkn_api_name,
                                            lv_api_name);
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
--
      lv_errmsg := lv_msg_data;
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    -- 郡コード
    IF (in_proc_flg = gn_proc_flg_01) THEN
      gt_gm_item_id_g(gn_target_cnt)         := ir_item01_rec.item_id;
      gt_gm_category_set_id_g(gn_target_cnt) := ln_category_set_id;
      gt_gm_category_id_g(gn_target_cnt)     := ln_category_id;
--
    -- 工場郡コード
    ELSIF (in_proc_flg = gn_proc_flg_02) THEN
      gt_gm_item_id_k(gn_target_cnt)         := ir_item01_rec.item_id;
      gt_gm_category_set_id_k(gn_target_cnt) := ln_category_set_id;
      gt_gm_category_id_k(gn_target_cnt)     := ln_category_id;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END proc_mtl_categories;
--
  /***********************************************************************************
   * Procedure Name   : proc_item_category
   * Description      : 品目割当の登録処理を行います。
   ***********************************************************************************/
  PROCEDURE proc_item_category(
    ir_item01_rec   IN     master_item01_rec,   -- OPM品目マスタレコード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_item_category'; -- プログラム名
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
    cv_lang                 CONSTANT VARCHAR2(5)    := USERENV('LANG');             -- 日本語
--
    -- *** ローカル変数 ***
    ln_cnt            NUMBER;
    ln_category_id    mtl_categories_b.category_id%TYPE;
    lv_segment1       mtl_categories_b.segment1%TYPE;
    lt_category_rec   INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_errorcode      NUMBER;
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_api_name       VARCHAR2(200);
--
    -- *** ローカル・カーソル ***
    CURSOR category_cur
    IS
       SELECT mcsb.category_set_id,
              mcst.description,
              mcsb.structure_id
       FROM   mtl_category_sets_tl mcst,
              mtl_category_sets_b  mcsb
       WHERE  mcsb.category_set_id = mcst.category_set_id
       AND    mcst.language        = cv_lang
       AND    mcst.source_lang     = cv_lang
       AND    mcst.description IN (
                                   gv_crowd_code,              -- 群コード
                                   gv_policy_group_code,       -- 政策群コード
                                   gv_marke_crowd_code,        -- マーケ用群コード
                                   gv_acnt_crowd_code          -- 経理部用群コード
--2008/09/29 Mod ↓
/*
                                   gv_acnt_crowd_code,         -- 経理部用群コード
                                   gv_factory_code             -- 工場群コード
*/
--2008/09/29 Mod ↑
                                  )
       ;
--
    -- *** ローカル・レコード ***
    lr_category_rec category_cur%ROWTYPE;
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
    OPEN category_cur;
--
    <<category_loop>>
    LOOP
      FETCH category_cur INTO lr_category_rec;
      EXIT WHEN category_cur%NOTFOUND;
--
      BEGIN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   gmi_item_categories  gic
        WHERE  gic.item_id         = ir_item01_rec.item_id
        AND    gic.category_set_id = lr_category_rec.category_set_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_cnt := 0;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 存在しない
      IF (ln_cnt = 0) THEN
--
        lt_category_rec.structure_id := lr_category_rec.structure_id;
--
        -- 群コード
        IF (lr_category_rec.description = gv_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_crowd_code;
--
        -- 政策群コード
        ELSIF (lr_category_rec.description = gv_policy_group_code) THEN
          lt_category_rec.segment1 := gv_def_policy_code;
--
        -- マーケ用群コード
        ELSIF (lr_category_rec.description = gv_marke_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_market_code;
--
        -- 経理部用群コード
        ELSIF (lr_category_rec.description = gv_acnt_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_acnt_crowd_code;
--2008/09/29 Mod ↓
/*
--
        -- 工場群コード
        ELSIF (lr_category_rec.description = gv_factory_code) THEN
          lt_category_rec.segment1 := gv_def_factory_code;
*/
--2008/09/29 Mod ↑
        END IF;
--
        lt_category_rec.summary_flag := 'N';
        lt_category_rec.enabled_flag := 'Y';
--
        lt_category_rec.web_status := NULL;
        lt_category_rec.supplier_enabled_flag := NULL;
--
        BEGIN
          SELECT COUNT(1)
          INTO   ln_cnt
          FROM   mtl_categories_b mcb
          WHERE  mcb.structure_id = lt_category_rec.structure_id
          AND    mcb.segment1     = lt_category_rec.segment1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_cnt := 0;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        -- 存在しない
        IF (ln_cnt = 0) THEN
--
          -- 品目カテゴリマスタ登録
          INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY(
             P_API_VERSION      => 1.0
            ,P_INIT_MSG_LIST    => FND_API.G_FALSE
            ,P_COMMIT           => FND_API.G_FALSE
            ,X_RETURN_STATUS    => lv_return_status
            ,X_ERRORCODE        => ln_errorcode
            ,X_MSG_COUNT        => ln_msg_count
            ,X_MSG_DATA         => lv_msg_data
            ,P_CATEGORY_REC     => lt_category_rec
            ,X_CATEGORY_ID      => ln_category_id
          );
--
          -- 失敗
          IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            lv_api_name := 'INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY';
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_msg_xxcmn10085,
                                                  gv_tkn_api_name,
                                                  lv_api_name);
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
--
            lv_errmsg := lv_msg_data;
            lv_errbuf := lv_msg_data;
            RAISE global_api_expt;
          END IF;
--
        -- 存在する
        ELSE
          BEGIN
            SELECT mcb.category_id
            INTO   ln_category_id
            FROM   mtl_categories_b mcb
            WHERE  mcb.structure_id = lt_category_rec.structure_id
            AND    mcb.segment1     = lt_category_rec.segment1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        -- 存在チェック
        BEGIN
          SELECT COUNT(1)
          INTO   ln_cnt
          FROM   gmi_item_categories
          WHERE  item_id         = ir_item01_rec.item_id
          AND    category_set_id = lr_category_rec.category_set_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_cnt := 0;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        -- 存在しない
        IF (ln_cnt = 0) THEN
          INSERT INTO gmi_item_categories
             (item_id
             ,category_set_id
             ,category_id
             ,created_by
             ,creation_date
             ,last_updated_by
             ,last_update_date
             ,last_update_login)
          VALUES (
              ir_item01_rec.item_id
             ,lr_category_rec.category_set_id
             ,ln_category_id
             ,TO_NUMBER(gv_last_update_by)
             ,gd_last_update_date
             ,TO_NUMBER(gv_last_update_by)
             ,gd_last_update_date
             ,TO_NUMBER(gv_last_update_login)
          );
        END IF;
--
--        gt_gm_item_id_g(gn_target_cnt)         := ir_item01_rec.item_id;
--        gt_gm_category_set_id_g(gn_target_cnt) := lr_category_rec.category_set_id;
--        gt_gm_category_id_g(gn_target_cnt)     := ln_category_id;
      END IF;
--
    END LOOP category_loop;
--
    CLOSE category_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルが開いていれば
      IF (category_cur%ISOPEN) THEN
        -- カーソルのクローズ
        CLOSE category_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END proc_item_category;
--
-- 2008/09/24 Add ↑
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータ抽出処理(B-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_applied_date     IN     VARCHAR2,                -- 適用日付
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_applied_date         CONSTANT VARCHAR2(20)   := '適用日付';              -- パラメータ名：適用日付
--
    -- *** ローカル変数 ***
    lv_applied_date         VARCHAR2(10)            := iv_applied_date;         -- 適用日付
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
    -- ***         日付NULLチェック        ***
    -- ***************************************
    -- 適用日付
    IF (lv_applied_date IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10084   -- メッセージ：APP-XXCMN-10084 パラメータNULLチェックNG
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
    END IF;
--
    -- ***************************************
    -- ***          日付型チェック         ***
    -- ***************************************
    -- 適用日付
    IF (lv_applied_date IS NOT NULL) THEN
      IF (xxcmn_common_pkg.check_param_date_yyyymmdd(lv_applied_date) = gn_rel_code) THEN
        -- エラーメッセージ取得
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_app_name,      -- アプリケーション短縮名：XXCMN 共通
                              gv_msg_xxcmn10083 -- メッセージ：APP-XXCMN-10083 パラメータ日付型チェックNG
                            ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
--
      ELSE
        gv_applied_date := FND_DATE.STRING_TO_DATE(lv_applied_date,'YYYY/MM/DD HH24:MI:SS');
      END IF;
--
    END IF;
--
    -- プロファイル：群コードの取得
    gv_group_code := FND_PROFILE.VALUE(gv_tkn_name_01);
    -- 取得エラー時
    IF (gv_group_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_03      -- 群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- プロファイル：工場群コードの取得
    gv_whse_county_code := FND_PROFILE.VALUE(gv_tkn_name_02);
    -- 取得エラー時
    IF (gv_whse_county_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_04      -- 工場群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
--2008/09/24 Add ↓
--
    -- プロファイル：初期値：群コードの取得
    gv_def_crowd_code := FND_PROFILE.VALUE(gv_tkn_name_05);
    -- 取得エラー時
    IF (gv_def_crowd_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_10      -- 初期値：群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- プロファイル：初期値：政策群コードの取得
    gv_def_policy_code := FND_PROFILE.VALUE(gv_tkn_name_06);
    -- 取得エラー時
    IF (gv_def_policy_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_11      -- 初期値：政策群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- プロファイル：初期値：マーケ用群コードの取得
    gv_def_market_code := FND_PROFILE.VALUE(gv_tkn_name_07);
    -- 取得エラー時
    IF (gv_def_market_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_12      -- 初期値：マーケ用群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- プロファイル：初期値：経理部用群コードの取得
    gv_def_acnt_crowd_code := FND_PROFILE.VALUE(gv_tkn_name_08);
    -- 取得エラー時
    IF (gv_def_acnt_crowd_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_13      -- 初期値：経理部用群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- プロファイル：初期値：工場群コードの取得
    gv_def_factory_code := FND_PROFILE.VALUE(gv_tkn_name_09);
    -- 取得エラー時
    IF (gv_def_factory_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,  -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                            gv_tkn_profile,     -- トークン：NG_PROFILE
                            gv_tkn_name_14      -- 初期値：工場群コード
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--2008/09/24 Add ↑
--
    -- WHOカラムの取得
    gd_last_update_date       :=  SYSDATE;
    gv_last_update_by         :=  fnd_global.user_id;
    gv_last_update_login      :=  fnd_global.login_id;
    gv_request_id             :=  fnd_global.conc_request_id;
    gv_program_application_id :=  fnd_global.prog_appl_id;
    gv_program_id             :=  fnd_global.conc_program_id;
    gd_program_update_date    :=  SYSDATE;
--
  EXCEPTION
    WHEN parameter_expt THEN                            --*** パラメータ例外 ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN profile_expt THEN                              --*** プロファイル取得エラー ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_sysitems_b
   * Description      : 品目マスタ取得(B-9)
   ***********************************************************************************/
  PROCEDURE get_sysitems_b(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_sysitems_b';        -- プログラム名
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
    cv_reservable_type_def  CONSTANT VARCHAR2(1)    := '1';                     -- 予約フラグON
    cv_tbl_name             CONSTANT VARCHAR2(50)   := '品目マスタ';            -- テーブル名
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
    -- ***          品目マスタ取得         ***
    -- ***************************************
    SELECT msib.inventory_item_id                 -- 品目ID
    BULK COLLECT INTO gt_mt_invflg_item_id
    FROM mtl_system_items_b msib
    WHERE msib.reservable_type = TO_NUMBER(cv_reservable_type_def)
    FOR UPDATE NOWAIT;
--
    -- 品目マスタの取得件数チェック
    IF (gt_mt_invflg_item_id.count = 0) THEN
      ov_retcode := gv_status_warn;
    END IF;

  EXCEPTION
    WHEN lock_expt THEN                                 --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10019,  -- メッセージ：APP-XXCMN-10019 ロックエラー
                            gv_tkn_table,       -- トークンTABLE
                            cv_tbl_name         -- テーブル名：品目マスタ
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
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
  END get_sysitems_b;
--
  /**********************************************************************************
   * Procedure Name   : put_item_mst
   * Description      : OPM品目アドオンマスタ情報格納(B-3)
   ***********************************************************************************/
  PROCEDURE put_item_mst(
    ir_item01_rec       IN     master_item01_rec,       -- OPM品目マスタレコード
    ir_report_tbl       IN OUT NOCOPY report_item03_tbl,-- OPM品目マスタレポート用テーブル
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_item_mst';          -- プログラム名
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
    cv_active_flag_y        CONSTANT VARCHAR2(1)    := 'Y';                     -- 適用済フラグ
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
    -- ***        OPM品目マスタ格納        ***
    -- ***************************************
    IF (ir_item01_rec.item_id IS NOT NULL) THEN
      gt_im_item_id(gn_target_cnt)    := ir_item01_rec.item_id;
      gt_im_item_desc1(gn_target_cnt) := ir_item01_rec.item_name;
      gt_im_shelf_life(gn_target_cnt) := ir_item01_rec.expiration_day;
      -- OPM品目マスタレポート用格納
      ir_report_tbl(gn_target_cnt).item_no    := ir_item01_rec.item_no;
      ir_report_tbl(gn_target_cnt).attribute2 := ir_item01_rec.attribute2;
--
    -- ***************************************
    -- ***    OPM品目アドオンマスタ格納    ***
    -- ***************************************
      gt_xm_item_id(gn_target_cnt)           := ir_item01_rec.item_id;
      gt_xm_start_date_active(gn_target_cnt) := ir_item01_rec.start_date_active;
      gt_xm_active_flag(gn_target_cnt)       := cv_active_flag_y;
--2008/09/29 Add ↓
      gt_xm_cs_wc(gn_target_cnt)             := ir_item01_rec.cs_weigth_or_capacity;
--2008/09/29 Add ↑
      -- OPM品目アドオンマスタレポート用格納
      ir_report_tbl(gn_target_cnt).start_date_active := ir_item01_rec.start_date_active;
      ir_report_tbl(gn_target_cnt).item_name         := ir_item01_rec.item_name;
      ir_report_tbl(gn_target_cnt).expiration_day    := ir_item01_rec.expiration_day;
      ir_report_tbl(gn_target_cnt).whse_county_code  := ir_item01_rec.whse_county_code;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END put_item_mst;
--
  /**********************************************************************************
   * Procedure Name   : put_gmi_item_g
   * Description      : 品目カテゴリマスタ情報格納(群コード)(B-4)
   ***********************************************************************************/
  PROCEDURE put_gmi_item_g(
    ir_item01_rec       IN     master_item01_rec,       -- OPM品目マスタレコード
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_gmi_item_g';        -- プログラム名
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
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'OPM品目カテゴリ割当';   -- テーブル名
    cv_lang                 CONSTANT VARCHAR2(5)    := 'JA';                    -- 日本語
    cv_enabled_flag         CONSTANT VARCHAR2(5)    := 'Y';                     -- 有効
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_categ_off_rec        category_item02_rec;            -- OPM品目カテゴリ割当反映用テーブル
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
    -- ***  OPM品目カテゴリ割当(群コード)  ***
    -- ***************************************
    SELECT mcsb.category_set_id,                  -- カテゴリセットID
           mcb.category_id                        -- カテゴリID
    INTO lr_categ_off_rec
    FROM mtl_category_sets_b   mcsb,
         mtl_category_sets_tl  mcst,
         mtl_categories_b      mcb,
         mtl_categories_tl     mct
    WHERE mcsb.category_set_id   = mcst.category_set_id
    AND   mcst.language          = cv_lang
    AND   mcst.source_lang       = cv_lang
    AND   mcst.category_set_name = gv_group_code
    AND   mcsb.structure_id      = mcb.structure_id
    AND   mcb.category_id        = mct.category_id
    AND   mct.language           = cv_lang
    AND   mct.source_lang        = cv_lang
    AND   mcb.segment1           = ir_item01_rec.attribute2
    AND   mcb.enabled_flag       = cv_enabled_flag
    AND   mcb.disable_date IS NULL
    FOR UPDATE NOWAIT;
--
    -- カテゴリ情報設定
    gt_gm_item_id_g(gn_target_cnt)         := ir_item01_rec.item_id;
    gt_gm_category_set_id_g(gn_target_cnt) := lr_categ_off_rec.category_set_id;
    gt_gm_category_id_g(gn_target_cnt)     := lr_categ_off_rec.category_id;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10019,  -- メッセージ：APP-XXCMN-10019 ロックエラー
                            gv_tkn_table,       -- トークンTABLE
                            cv_tbl_name         -- テーブル名：OPM品目カテゴリ割当
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
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
  END put_gmi_item_g;
--
  /**********************************************************************************
   * Procedure Name   : put_gmi_item_k
   * Description      : 品目カテゴリマスタ情報格納(工場群コード)(B-5)
   ***********************************************************************************/
  PROCEDURE put_gmi_item_k(
    ir_item01_rec       IN     master_item01_rec,       -- OPM品目マスタレコード
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_gmi_item_k';        -- プログラム名
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
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'OPM品目カテゴリ割当';   -- テーブル名
    cv_lang                 CONSTANT VARCHAR2(5)    := 'JA';                    -- 日本語
    cv_enabled_flag         CONSTANT VARCHAR2(5)    := 'Y';                     -- 有効
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_categ_off_rec        category_item02_rec;            -- OPM品目カテゴリ割当反映用テーブル
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
    -- ***OPM品目カテゴリ割当(工場群コード)***
    -- ***************************************
    SELECT mcsb.category_set_id,                  -- カテゴリセットID
           mcb.category_id                        -- カテゴリID
    INTO lr_categ_off_rec
    FROM mtl_category_sets_b   mcsb,
         mtl_category_sets_tl  mcst,
         mtl_categories_b      mcb,
         mtl_categories_tl     mct
    WHERE mcsb.category_set_id   = mcst.category_set_id
    AND   mcst.language          = cv_lang
    AND   mcst.source_lang       = cv_lang
    AND   mcst.category_set_name = gv_whse_county_code
    AND   mcsb.structure_id      = mcb.structure_id
    AND   mcb.category_id        = mct.category_id
    AND   mct.language           = cv_lang
    AND   mct.source_lang        = cv_lang
    AND   mcb.segment1           = ir_item01_rec.whse_county_code
    AND   mcb.enabled_flag       = cv_enabled_flag
    AND   mcb.disable_date IS NULL
    FOR UPDATE NOWAIT;
--
    -- カテゴリ情報設定
    gt_gm_item_id_k(gn_target_cnt)         := ir_item01_rec.item_id;
    gt_gm_category_set_id_k(gn_target_cnt) := lr_categ_off_rec.category_set_id;
    gt_gm_category_id_k(gn_target_cnt)     := lr_categ_off_rec.category_id;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10019,  -- メッセージ：APP-XXCMN-10019 ロックエラー
                            gv_tkn_table,       -- トークンTABLE
                            cv_tbl_name         -- テーブル名：OPM品目カテゴリ割当
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
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
  END put_gmi_item_k;
--
  /**********************************************************************************
   * Procedure Name   : update_item_mst_b
   * Description      : OPM品目マスタ反映(B-6)
   ***********************************************************************************/
  PROCEDURE update_item_mst_b(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_item_mst_b';     -- プログラム名
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
    -- ***      OPM品目マスタ一括更新      ***
    -- ***************************************
    FORALL item_cnt IN 1 .. gt_im_item_id.COUNT
      -- OPM品目マスタ更新
      UPDATE ic_item_mst_b iimb
      SET iimb.item_desc1             = gt_im_item_desc1(item_cnt),
          iimb.shelf_life             = NVL(gt_im_shelf_life(item_cnt),iimb.shelf_life),
          iimb.last_updated_by        = TO_NUMBER(gv_last_update_by),
          iimb.last_update_date       = gd_last_update_date,
          iimb.last_update_login      = TO_NUMBER(gv_last_update_login),
          iimb.request_id             = TO_NUMBER(gv_request_id),
          iimb.program_application_id = TO_NUMBER(gv_program_application_id),
          iimb.program_id             = TO_NUMBER(gv_program_id),
          iimb.program_update_date    = gd_program_update_date
      WHERE iimb.item_id = gt_im_item_id(item_cnt);
--
    -- 1.1 内部変更要求No.81対応
    FORALL item_cnt IN 1 .. gt_im_item_id.COUNT
      -- OPM品目マスタ（TL）更新
      UPDATE ic_item_mst_tl iimt
      SET iimt.item_desc1             = gt_im_item_desc1(item_cnt),
          iimt.last_updated_by        = TO_NUMBER(gv_last_update_by),
          iimt.last_update_date       = gd_last_update_date,
          iimt.last_update_login      = TO_NUMBER(gv_last_update_login)
      WHERE iimt.item_id = gt_im_item_id(item_cnt)
-- mod start ver1.6
--      AND   iimt.language = USERENV('LANG');
      AND   iimt.source_lang = USERENV('LANG');
-- mod end ver1.6
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END update_item_mst_b;
--
  /**********************************************************************************
   * Procedure Name   : update_categories
   * Description      : OPM品目カテゴリ割当反映(B-7)
   ***********************************************************************************/
  PROCEDURE update_categories(
    iv_ret_g            IN     VARCHAR2,
    iv_ret_k            IN     VARCHAR2,
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_categories';     -- プログラム名
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
    -- ***   OPM品目カテゴリ割当一括更新   ***
    -- ***************************************
    -- 群コードのカテゴリ更新
    IF (iv_ret_g = gv_status_normal) THEN
      FORALL gun_cnt IN INDICES OF gt_gm_item_id_g
        -- 群コード更新
        UPDATE gmi_item_categories gic
        SET gic.category_id       = gt_gm_category_id_g(gun_cnt),
            gic.last_updated_by   = TO_NUMBER(gv_last_update_by),
            gic.last_update_date  = gd_last_update_date,
            gic.last_update_login = TO_NUMBER(gv_last_update_login)
        WHERE gic.item_id         = gt_gm_item_id_g(gun_cnt)
        AND   gic.category_set_id = gt_gm_category_set_id_g(gun_cnt);
    END IF;
--2008/09/29 Mod ↓
/*
--
    -- 工場群コードのカテゴリ更新
    IF (iv_ret_k = gv_status_normal) THEN
      FORALL kgun_cnt IN INDICES OF gt_gm_item_id_k
        -- 工場群コード更新
        UPDATE gmi_item_categories gic
        SET gic.category_id       = gt_gm_category_id_k(kgun_cnt),
            gic.last_updated_by   = TO_NUMBER(gv_last_update_by),
            gic.last_update_date  = gd_last_update_date,
            gic.last_update_login = TO_NUMBER(gv_last_update_login)
        WHERE gic.item_id         = gt_gm_item_id_k(kgun_cnt)
        AND   gic.category_set_id = gt_gm_category_set_id_k(kgun_cnt);
    END IF;
*/
--2008/09/29 Mod ↑
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END update_categories;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcmn_item
   * Description      : OPM品目アドオンマスタ反映(B-8)
   ***********************************************************************************/
  PROCEDURE update_xxcmn_item(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_xxcmn_item';     -- プログラム名
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
    -- ***  OPM品目アドオンマスタ一括更新  ***
    -- ***************************************
    -- OPM品目アドオンマスタ情報チェック
    FORALL item_cnt IN 1 .. gt_xm_item_id.COUNT
      -- OPM品目アドオンマスタ更新
      UPDATE xxcmn_item_mst_b ximb
      SET ximb.active_flag            = gt_xm_active_flag(item_cnt),
--2008/09/29 Add ↓
          ximb.cs_weigth_or_capacity  = gt_xm_cs_wc(item_cnt),
--2008/09/29 Add ↑
          ximb.last_updated_by        = TO_NUMBER(gv_last_update_by),
          ximb.last_update_date       = gd_last_update_date,
          ximb.last_update_login      = TO_NUMBER(gv_last_update_login),
          ximb.request_id             = TO_NUMBER(gv_request_id),
          ximb.program_application_id = TO_NUMBER(gv_program_application_id),
          ximb.program_id             = TO_NUMBER(gv_program_id),
          ximb.program_update_date    = gd_program_update_date
      WHERE ximb.item_id           = gt_xm_item_id(item_cnt)
      AND   ximb.start_date_active = gt_xm_start_date_active(item_cnt);
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END update_xxcmn_item;
--
  /**********************************************************************************
   * Procedure Name   : update_mtl_item_f
   * Description      : 品目マスタ反映(予約可能)(B-10)
   ***********************************************************************************/
  PROCEDURE update_mtl_item_f(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_mtl_item_f';     -- プログラム名
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
-- 2008/09/11 Mod ↓
/*
    cv_reservable_type_def  CONSTANT VARCHAR2(1)    := '0';                     -- 予約フラグOFF
*/
    cv_reservable_type_on   CONSTANT NUMBER    := 1;                     -- 予約フラグON
-- 2009/01/28 v1.7 UPDATE START
--    cv_reservable_type_off  CONSTANT NUMBER    := 0;                     -- 予約フラグOFF
    cv_reservable_type_off  CONSTANT NUMBER    := 2;                     -- 予約フラグOFF
-- 2009/01/28 v1.7 UPDATE END
-- 2008/09/11 Mod ↑
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
    -- ***        品目マスタ一括更新       ***
    -- ***************************************
-- 2008/09/11 Mod ↓
/*
      <<update_item_loop>>
      FORALL item_cnt IN 1 .. gt_mt_invflg_item_id.COUNT
        -- 品目マスタ更新(予約フラグOFF)
        UPDATE mtl_system_items_b msib
        SET msib.reservable_type        = cv_reservable_type_def,
            msib.last_updated_by        = TO_NUMBER(gv_last_update_by),
            msib.last_update_date       = gd_last_update_date,
            msib.last_update_login      = TO_NUMBER(gv_last_update_login),
            msib.request_id             = TO_NUMBER(gv_request_id),
            msib.program_application_id = TO_NUMBER(gv_program_application_id),
            msib.program_id             = TO_NUMBER(gv_program_id),
            msib.program_update_date    = gd_program_update_date
        WHERE msib.inventory_item_id = gt_mt_invflg_item_id(item_cnt);
*/
    -- 品目マスタ更新(予約フラグOFF)
    UPDATE mtl_system_items_b msib
-- 2009/11/25 H.Itou Mod Start 本番障害#83
    SET msib.reservable_type        = cv_reservable_type_off
--    SET msib.reservable_type        = cv_reservable_type_off,
--        msib.last_updated_by        = TO_NUMBER(gv_last_update_by),
--        msib.last_update_date       = gd_last_update_date,
--        msib.last_update_login      = TO_NUMBER(gv_last_update_login),
--        msib.request_id             = TO_NUMBER(gv_request_id),
--        msib.program_application_id = TO_NUMBER(gv_program_application_id),
--        msib.program_id             = TO_NUMBER(gv_program_id),
--        msib.program_update_date    = gd_program_update_date
-- 2009/11/25 H.Itou Mod End
    WHERE msib.reservable_type = 1;
--    WHERE msib.reservable_type = cv_reservable_type_on;   -- 2008/09/11 Del
-- 2008/09/11 Mod ↑
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END update_mtl_item_f;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : 処理結果レポート出力
   ***********************************************************************************/
  PROCEDURE disp_report(
    ir_report_tbl       IN     report_item03_tbl,       -- OPM品目マスタレポート用テーブル
    disp_kbn            IN     NUMBER,                  -- 区分(0:正常,1:異常)
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_dspbuf               VARCHAR2(5000);                                     -- エラー・メッセージ
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
    -- 処理結果レポートの出力
    <<disp_report_loop>>
    FOR report_cnt IN ir_report_tbl.first .. ir_report_tbl.last
    LOOP
--
      --入力データの再構成
      lv_dspbuf := ir_report_tbl(report_cnt).item_no||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).attribute2||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||TO_CHAR(ir_report_tbl(report_cnt).start_date_active,'YYYY/MM/DD')||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).expiration_day||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).whse_county_code||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).item_name;
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
    END LOOP disp_report_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
--#####################################  固定部 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_applied_date     IN     VARCHAR2,                -- 適用日付
-- 2009/02/27 v1.8 ADD START
    iv_start_class      IN     VARCHAR2,                -- 起動区分
-- 2009/02/27 v1.8 ADD END
    ov_errbuf           OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2)                -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_ret     VARCHAR2(1);     -- 品目マスタ取得のリターン・コード
    lv_ret_g   VARCHAR2(1);     -- OPM品目カテゴリ割当(群コード)取得のリターン・コード
    lv_ret_k   VARCHAR2(1);     -- OPM品目カテゴリ割当(工場群コード)取得のリターン・コード
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_applied_date         CONSTANT VARCHAR2(20)   := '適用日付';              -- パラメータ名：適用日付
    cv_active_flag_def      CONSTANT VARCHAR2(1)    := 'N';                     -- 適用済フラグ
    cv_inactive_ind         CONSTANT VARCHAR2(1)    := '1';                     -- 無効フラグ
    cv_obsolete_class       CONSTANT VARCHAR2(1)    := '1';                     -- 廃止区分
                                                                                -- テーブル名
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'OPM品目-OPM品目アドオンマスタ';
--
    -- *** ローカル変数 ***
    lr_report_tbl           report_item03_tbl;                                  -- OPM品目マスタレポート
    lr_item01_rec           master_item01_rec;                                  -- OPM品目マスタ格納用レコード
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- OPM品目マスタ
    CURSOR item_mst_b_cur
    IS
    SELECT   iimb.item_id,                        -- 品目ID(OPM品目マスタ)
             iimb.item_no,                        -- 品目
             iimb.attribute2,                     -- 新・群コード
             ximb.start_date_active,              -- 適用開始日
             ximb.item_name,                      -- 正式名
             ximb.expiration_day,                 -- 賞味期間
             ximb.whse_county_code                -- 工場群コード
--2008/09/29 Add ↓
             ,DECODE(iimb.attribute10,
                     NULL,0,
                     '1',TO_NUMBER(NVL(iimb.attribute11,'0')) *
                     TO_NUMBER(NVL(iimb.attribute25,'0')),  --ケース入数*重量
                     '2',TO_NUMBER(NVL(iimb.attribute11,'0')) *
                     TO_NUMBER(NVL(iimb.attribute16,'0'))   --ケース入数*容積
                    ) cs_weigth_or_capacity
--2008/09/29 Add ↑
      FROM ic_item_mst_b iimb,
           xxcmn_item_mst_b ximb
      WHERE iimb.item_id = ximb.item_id
      AND   iimb.inactive_ind <> TO_NUMBER(cv_inactive_ind)
      AND   ximb.obsolete_class <>  cv_obsolete_class
      AND   ximb.start_date_active <= TO_DATE(iv_applied_date,'YYYY/MM/DD')
      AND   ximb.end_date_active >= TO_DATE(iv_applied_date,'YYYY/MM/DD')
      AND   ximb.active_flag = cv_active_flag_def
      ORDER BY iimb.item_no,
               ximb.start_date_active
      FOR UPDATE NOWAIT;
--
    item_mst_b_rec    item_mst_b_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
    lv_ret     := gv_status_normal;
    lv_ret_g   := gv_status_normal;
    lv_ret_k   := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- B-1.パラメータ抽出処理
    -- ===============================
    parameter_check(
      iv_applied_date,    -- 適用日付
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-2.OPM品目アドオンマスタ取得
    -- ===============================
    <<item_mst_loop>>
    FOR lr_item01_rec IN item_mst_b_cur LOOP
--
      -- 処理件数のカウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- =================================
      -- B-3.OPM品目アドオンマスタ情報格納
      -- =================================
      put_item_mst(
        lr_item01_rec,      -- OPM品目マスタ群取得レコード
        lr_report_tbl,      -- OPM品目マスタレポート用テーブル
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- B-4.品目カテゴリマスタ情報格納(群コード)
      -- ========================================
      IF (lr_item01_rec.attribute2 IS NOT NULL) THEN
        put_gmi_item_g(
          lr_item01_rec,        -- OPM品目マスタレコード
          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          lv_retcode,           -- リターン・コード             --# 固定 #
          lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
-- 2008/09/24 Mod ↓
          -- 品目カテゴリ作成
          proc_mtl_categories(
            lr_item01_rec,        -- OPM品目マスタレコード
            gn_proc_flg_01,       -- 処理区分
            lv_errbuf,            -- エラー・メッセージ           --# 固定 #
            lv_retcode,           -- リターン・コード             --# 固定 #
            lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
/*
          lv_ret_g   := lv_retcode;
          lv_retcode := gv_status_normal;
*/
-- 2008/09/24 Mod ↑
        END IF;
      END IF;
--2008/09/29 Mod ↓
/*
--
      -- ============================================
      -- B-5.品目カテゴリマスタ情報格納(工場群コード)
      -- ============================================
      IF (lr_item01_rec.whse_county_code IS NOT NULL) THEN
        put_gmi_item_k(
          lr_item01_rec,        -- OPM品目マスタレコード
          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          lv_retcode,           -- リターン・コード             --# 固定 #
          lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
-- 2008/09/24 Mod ↓
          -- 品目カテゴリ作成
          proc_mtl_categories(
            lr_item01_rec,        -- OPM品目マスタレコード
            gn_proc_flg_02,       -- 処理区分
            lv_errbuf,            -- エラー・メッセージ           --# 固定 #
            lv_retcode,           -- リターン・コード             --# 固定 #
            lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
*/
--2008/09/29 Mod ↑
/*
          lv_ret_k   := lv_retcode;
          lv_retcode := gv_status_normal;
*/
-- 2008/09/24 Mod ↑
--2008/09/29 Mod ↓
/*
        END IF;
      END IF;
*/
--2008/09/29 Mod ↑
--2008/09/24 Add ↓
      -- 品目割当作成
      proc_item_category(
        lr_item01_rec,        -- OPM品目マスタレコード
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--2008/09/24 Add ↑
--
    END LOOP item_mst_loop;
--
    -- ===============================
    -- B-6.OPM品目マスタ反映
    -- ===============================
    update_item_mst_b(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-7.OPM品目カテゴリ割当反映
    -- ===============================
    update_categories(
      lv_ret_g,               -- 群コード取得可否
      lv_ret_k,               -- 工場群コード取得可否
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-8.OPM品目アドオンマスタ反映
    -- ===============================
    update_xxcmn_item(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/09/11 Del ↓
/*
    -- ===============================
    -- B-9.品目マスタ取得
    -- ===============================
    get_sysitems_b(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      lv_ret     := lv_retcode;
      lv_retcode := gv_status_normal;
    END IF;
*/
-- 2008/09/11 Del ↑
--
-- 2009/02/27 v1.8 ADD START
   IF (iv_start_class = gv_start_batch) THEN
-- 2009/02/27 v1.8 ADD END
    -- ===============================
    -- B-10.品目マスタ反映(予約可能)
    -- ===============================
/* 2008/09/11 Del ↓
    IF (lv_ret = gv_status_normal) THEN
2008/09/11 Del ↑ */
    IF (lv_retcode = gv_status_normal) THEN
      update_mtl_item_f(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
-- 2009/02/27 v1.8 ADD START
   END IF;
--
-- 2009/02/27 v1.8 ADD END
    -- 処理件数
    gn_normal_cnt := gn_target_cnt;
--
    -- 正常終了件数取得
    IF (gn_normal_cnt > 0) THEN
      -- ログ出力処理
      disp_report(lr_report_tbl, gn_data_status_nomal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10019,  -- メッセージ：APP-XXCMN-10019 ロックエラー
                            gv_tkn_table,       -- トークンTABLE
                            cv_tbl_name         -- テーブル名：OPM品目-OPM品目アドオンマスタ
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
    errbuf              OUT    VARCHAR2,                -- エラー・メッセージ           --# 固定 #
    retcode             OUT    VARCHAR2,                -- リターン・コード             --# 固定 #
-- 2009/02/27 v1.8 UPDATE START
--    iv_applied_date     IN     VARCHAR2)                -- 適用日付
    iv_applied_date     IN     VARCHAR2,                -- 適用日付
    iv_start_class      IN     VARCHAR2)                -- 起動区分
-- 2009/02/27 v1.8 UPDATE END
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
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_applied_date,       -- 1.適用日付
-- 2009/02/27 v1.8 ADD START
      iv_start_class,        -- 2.起動区分
-- 2009/02/27 v1.8 ADD END
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
END xxcmn810002c;
/
