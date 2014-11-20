CREATE OR REPLACE PACKAGE BODY APPS.XXCOP004A10R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A10R(body)
 * Description      : 引取計画実績対比表
 * MD.050           : MD050_COP_004_A10_引取計画実績対比表
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
 *  get_target_base_code        対象拠点取得（配下拠点）(A-2)
 *  get_forecast_info           引取計画数取得処理(A-3)
 *  get_stock_comp_info         入庫確認数(拠点入庫)取得処理(A-4)
 *  get_stock_order_comp_info   依頼済数(拠点入庫－拠点未入庫)取得処理(A-5)
 *  get_stock_fact_ship_info    依頼済数(拠点入庫－工場未出荷)取得処理(A-6)
 *  get_ship_comp_info          売上計上済数取得処理(A-7)
 *  get_ship_order_comp_info    依頼済数(直送)取得処理(A-8)
 *  svf_call                    SVF起動(A-9)
 *  del_rep_work_data           帳票ワークテーブル削除処理(A-10)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                              終了処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/12/10    1.0   S.Niki           新規作成
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
  -- 文字括り
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
  global_lock_expt          EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20)   := 'XXCOP004A10R';       -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)    := 'XXCOP';              -- アプリケーション:XXCOP
  -- プロファイル
  cv_itou_ou_mfg              CONSTANT VARCHAR2(30)   := 'XXCOI1_ITOE_OU_MFG';       -- 生産営業単位取得名称
  cv_sales_org_code           CONSTANT VARCHAR2(30)   := 'XXCOP1_SALES_ORG_CODE';    -- 営業組織コード
  cv_item_div_h               CONSTANT VARCHAR2(30)   := 'XXCOS1_ITEM_DIV_H';        -- カテゴリセット名(本社商品区分)
  cv_policy_group_code        CONSTANT VARCHAR2(30)   := 'XXCOS1_POLICY_GROUP_CODE'; -- カテゴリセット名(政策群コード)
  -- メッセージ
  cv_msg_xxcop_00065          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00065';   -- 業務日付取得エラーメッセージ
  cv_msg_xxcop_00002          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00002';   -- プロファイル値取得失敗エラー
  cv_msg_xxcop_00013          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00013';   -- マスタチェックエラー
  cv_msg_xxcop_00016          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00016';   -- API起動エラー
  cv_msg_xxcop_00027          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00027';   -- 登録処理エラーメッセージ
  cv_msg_xxcop_00028          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00028';   -- 更新処理エラーメッセージ
  cv_msg_xxcop_00042          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00042';   -- 削除処理エラーメッセージ
  cv_msg_xxcop_00080          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00080';   -- 組織コードノート
  cv_msg_xxcop_00081          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00081';   -- 組織パラメータノート
  cv_msg_xxcop_00094          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00094';   -- 生産営業単位ノート
  cv_msg_xxcop_00095          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00095';   -- 組織マスタノート
  cv_msg_xxcop_10072          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-10072';   -- 引取計画実績対比表帳票ワークテーブルノート
  cv_msg_xxcop_10073          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-10073';   -- 引取計画実績対比表パラメータ出力メッセージ
  -- トークンコード
  cv_tkn_profile              CONSTANT VARCHAR2(20)   := 'PROF_NAME';          -- プロファイル
  cv_tkn_table                CONSTANT VARCHAR2(20)   := 'TABLE';              -- テーブル名
  cv_tkn_item                 CONSTANT VARCHAR2(20)   := 'ITEM';               -- 項目
  cv_tkn_value                CONSTANT VARCHAR2(20)   := 'VALUE';              -- 項目値
  cv_tkn_prg_name             CONSTANT VARCHAR2(20)   := 'PRG_NAME';           -- プログラム名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)   := 'ERR_MSG';            -- エラー内容詳細
  cv_tkn_target_month         CONSTANT VARCHAR2(20)   := 'TARGET_MONTH';       -- 対象年月
  cv_tkn_forecast_type        CONSTANT VARCHAR2(20)   := 'FORECAST_TYPE';      -- 計画区分
  cv_tkn_prod_class_code      CONSTANT VARCHAR2(20)   := 'PROD_CLASS_CODE';    -- 商品区分
  cv_tkn_base_code            CONSTANT VARCHAR2(20)   := 'BASE_CODE';          -- 拠点
  cv_tkn_crowd_class_code     CONSTANT VARCHAR2(20)   := 'CROWD_CLASS_CODE';   -- 政策群コード
  cv_tkn_item_code            CONSTANT VARCHAR2(20)   := 'ITEM_CODE';          -- 品目コード
  -- クイックコード
  cv_flag_y                   CONSTANT VARCHAR2(1)    := 'Y';                  -- 有効
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                      := USERENV('LANG');
  -- 日付書式
  cv_format_yyyymmdd          CONSTANT VARCHAR2(10)   := 'YYYY/MM/DD';
  cv_format_yyyymm            CONSTANT VARCHAR2(6)    := 'YYYYMM';
  cv_format_yyyy              CONSTANT VARCHAR2(4)    := 'YYYY';
  cv_format_mm                CONSTANT VARCHAR2(2)    := 'MM';
  cv_format_dd                CONSTANT VARCHAR2(2)    := 'DD';
  cv_format_std               CONSTANT VARCHAR2(18)   := 'YYYY/MM/DD HH24:MI';
  cv_format_svf               CONSTANT VARCHAR2(8)    := 'YYYYMMDD';
  -- 値セット
  cv_flex_forecast_type       CONSTANT VARCHAR2(30)   := 'XXCOP1_FORECAST_TYPE';
  -- クイックコード
  cv_lkup_exc_order_type      CONSTANT VARCHAR2(30)   := 'XXCOI1_EXCLUDE_ORDER_TYPE';
  -- API名(メッセージトークン値)
  cv_api_err_msg_tkn_val      CONSTANT VARCHAR2(50)   := 'XXCCP_SVFCOMMON_PKG.SUBMIT_SVF_REQUEST';
  -- 数値
  cn_0                        CONSTANT NUMBER         := 0;
  cn_1                        CONSTANT NUMBER         := 1;
  cn_2                        CONSTANT NUMBER         := 2;
  cn_3                        CONSTANT NUMBER         := 3;
  cn_100                      CONSTANT NUMBER         := 100;
  cn_minus                    CONSTANT NUMBER         := -1;
  -- 商品区分
  cv_ctg_leaf                 CONSTANT VARCHAR2(1)    := '1';                  -- リーフ
  cv_ctg_drink                CONSTANT VARCHAR2(1)    := '2';                  -- ドリンク
  -- 入庫確認フラグ
  cv_store_check_y            CONSTANT VARCHAR2(1)    := 'Y';                  -- 入庫確認済
  cv_store_check_n            CONSTANT VARCHAR2(1)    := 'N';                  -- 入庫未確認
  -- サマリーデータフラグ
  cv_summary_data_y           CONSTANT VARCHAR2(1)    := 'Y';                  -- サマリーデータ
  -- 出荷ステータス
  cv_req_status_01            CONSTANT VARCHAR2(2)    := '01';                 -- 入力中
  cv_req_status_02            CONSTANT VARCHAR2(2)    := '02';                 -- 拠点確定
  cv_req_status_03            CONSTANT VARCHAR2(2)    := '03';                 -- 締め済み
  cv_req_status_04            CONSTANT VARCHAR2(2)    := '04';                 -- 出荷実績計上済
  -- 出荷支給区分
  cv_ship_order               CONSTANT VARCHAR2(1)    := '1';                  -- 出荷依頼
  -- 在庫調整区分
  cv_stock_etc                CONSTANT VARCHAR2(1)    := '1';                  -- 在庫調整以外
  cv_stock_adjm               CONSTANT VARCHAR2(1)    := '2';                  -- 在庫調整
  -- 受注カテゴリコード
  cv_order_ctg_return         CONSTANT VARCHAR2(6)    := 'RETURN';             -- 返品
  -- 顧客区分
  cv_customer_class_base      CONSTANT VARCHAR2(1)    := '1';                  -- 顧客区分（拠点）
  cv_customer_class_cust      CONSTANT VARCHAR2(2)    := '10';                 -- 顧客区分（顧客）
  -- 倉庫タイプ
  cv_wh_type_base             CONSTANT VARCHAR2(1)    := '0';                  -- 拠点倉庫
  -- 削除フラグ
  cv_delete_flag_n            CONSTANT VARCHAR2(1)    := 'N';                  -- 削除以外
  -- 最新フラグ
  cv_latest_ext_flag_y        CONSTANT VARCHAR2(1)    := 'Y';                  -- 最新
  -- 実績計上フラグ
  cv_act_conf_class_y         CONSTANT VARCHAR2(1)    := 'Y';                  -- 実績計上済
  -- 帳票出力関連
  cv_report_id                CONSTANT VARCHAR2(100)  := 'XXCOP004A10R';       -- 帳票ID
  cv_frm_file                 CONSTANT VARCHAR2(100)  := 'XXCOP004A10S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                 CONSTANT VARCHAR2(100)  := 'XXCOP004A10S.vrq';   -- クエリー様式ファイル名
  cv_output_mode              CONSTANT VARCHAR2(1)    := '1';                  -- 出力区分(PDF)
  cv_extension_pdf            CONSTANT VARCHAR2(100)  := '.pdf';               -- 拡張子(PDF)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 帳票出力対象拠点レコード型
  TYPE target_base_trec IS RECORD(
      base_code              hz_cust_accounts.account_number %TYPE  -- 拠点コード
    , base_name              xxcmn_parties.party_short_name  %TYPE  -- 拠点名
    );
--
  -- 帳票出力対象拠点PL/SQL表
  TYPE target_base_ttype IS
    TABLE OF target_base_trec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル値格納用
  gd_process_date             DATE         DEFAULT NULL;                       -- 業務日付
  gt_itou_ou_mfg              hr_organization_units.name%TYPE;                 -- 生産営業単位取得名称
  gt_itou_ou_id               hr_organization_units.organization_id%TYPE;      -- 生産組織ID
  gt_sales_org_code           mtl_parameters.organization_code%TYPE;           -- 営業組織コード
  gt_sales_org_id             mtl_parameters.organization_id%TYPE;             -- 営業組織ID
  gt_item_div_h               mtl_category_sets_vl.category_set_name%TYPE;     -- カテゴリセット名(本社商品区分)
  gt_policy_group_code        mtl_category_sets_vl.category_set_name%TYPE;     -- カテゴリセット名(政策群コード)
  -- 入力パラメータ格納用
  gv_target_month             VARCHAR2(6);                                     -- 対象年月
  gv_prod_class_code          VARCHAR2(1);                                     -- 商品区分
  gv_base_code                VARCHAR2(4);                                     -- 拠点コード
  gv_forecast_type            VARCHAR2(2);                                     -- 計画区分
  gv_crowd_class_code         VARCHAR2(4);                                     -- 政策群コード
  gv_item_code                VARCHAR2(7);                                     -- 品目コード
  gt_prod_class_name          xxcop_prod_categories1_v.prod_class_name%TYPE;   -- 商品区分名
  gt_forecast_type_name       fnd_flex_values_tl.description%TYPE;             -- 計画区分名
  -- トークン値格納用
  gv_tkn_vl1                  VARCHAR2(5000);    -- エラーメッセージ用トークン1
  gv_tkn_vl2                  VARCHAR2(5000);    -- エラーメッセージ用トークン2
  -- 出力対象データ格納用
  g_target_base_tbl           target_base_ttype; -- 帳票出力対象拠点
--
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  -- レコード定義
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル変数 ***
    lv_param_msg       VARCHAR2(5000);                 -- パラメーター出力用
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
    -- 1．計画区分名取得
    --==============================================================
    -- 入力パラメータから計画区分名を取得
    BEGIN
      SELECT ffvt.description  AS forecast_type_name  -- 計画区分名
      INTO   gt_forecast_type_name
      FROM   fnd_flex_values      ffv
           , fnd_flex_values_tl   ffvt
           , fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffvt.language            = ct_lang
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_flex_forecast_type
      AND    ffv.flex_value           = gv_forecast_type
      AND    ffv.enabled_flag         = cv_flag_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_forecast_type_name := NULL;
    END;
--
    --==============================================================
    -- 2．商品区分名取得
    --==============================================================
    -- 入力パラメータから商品区分名を取得
    BEGIN
      SELECT xpcv.prod_class_name  AS prod_class_name  -- 商品区分名
      INTO   gt_prod_class_name
      FROM   xxcop_prod_categories1_v  xpcv
      WHERE  xpcv.prod_class_code     = gv_prod_class_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_prod_class_name := NULL;
    END;
--
    --==============================================================
    -- 3．コンカレント入力パラメータメッセージ出力
    --==============================================================
    -- メッセージ編集
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_application            -- アプリケーション短縮名
                      ,iv_name          => cv_msg_xxcop_10073        -- メッセージコード
                      ,iv_token_name1   => cv_tkn_target_month       -- トークンコード1
                      ,iv_token_value1  => gv_target_month           -- トークン値1
                      ,iv_token_name2   => cv_tkn_forecast_type      -- トークンコード2
                      ,iv_token_value2  => gt_forecast_type_name     -- トークン値2
                      ,iv_token_name3   => cv_tkn_prod_class_code    -- トークンコード3
                      ,iv_token_value3  => gt_prod_class_name        -- トークン値3
                      ,iv_token_name4   => cv_tkn_base_code          -- トークンコード4
                      ,iv_token_value4  => gv_base_code              -- トークン値4
                      ,iv_token_name5   => cv_tkn_crowd_class_code   -- トークンコード5
                      ,iv_token_value5  => gv_crowd_class_code       -- トークン値5
                      ,iv_token_name6   => cv_tkn_item_code          -- トークンコード6
                      ,iv_token_value6  => gv_item_code              -- トークン値6
                    );
    --
    -- 入力パラメータをログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --
    -- 空行出力
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 4．業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application         -- アプリケーション短縮名
                     ,iv_name        => cv_msg_xxcop_00065     -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 5．プロファイル取得
    --==============================================================
    -------------------------
    -- 生産営業単位取得名称
    -------------------------
    BEGIN
      gt_itou_ou_mfg := fnd_profile.value(cv_itou_ou_mfg);
    EXCEPTION
      WHEN OTHERS THEN
        gt_itou_ou_mfg := NULL;
    END;
    -- 生産営業単位取得名称が取得出来ない場合
    IF ( gt_itou_ou_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_profile       -- トークンコード1
                     ,iv_token_value1 => cv_itou_ou_mfg       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ------------------
    -- 営業組織コード
    ------------------
    BEGIN
      gt_sales_org_code := fnd_profile.value(cv_sales_org_code);
    EXCEPTION
      WHEN OTHERS THEN
        gt_sales_org_code := NULL;
    END;
    -- 営業組織コードが取得出来ない場合
    IF ( gt_sales_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_profile       -- トークンコード1
                     ,iv_token_value1 => cv_sales_org_code    -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ----------------------------------
    -- カテゴリセット名(本社商品区分)
    ----------------------------------
    BEGIN
      gt_item_div_h := fnd_profile.value(cv_item_div_h);
    EXCEPTION
      WHEN OTHERS THEN
        gt_item_div_h := NULL;
    END;
    -- カテゴリセット名(本社商品区分)が取得出来ない場合
    IF ( gt_item_div_h IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_profile       -- トークンコード1
                     ,iv_token_value1 => cv_item_div_h        -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ----------------------------------
    -- カテゴリセット名(政策群コード)
    ----------------------------------
    BEGIN
      gt_policy_group_code := fnd_profile.value(cv_policy_group_code);
    EXCEPTION
      WHEN OTHERS THEN
        gt_policy_group_code := NULL;
    END;
    -- カテゴリセット名(政策群コード)が取得出来ない場合
    IF ( gt_policy_group_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00002   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_profile       -- トークンコード1
                     ,iv_token_value1 => cv_policy_group_code -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 6．生産組織ID取得
    --==============================================================
    BEGIN
      SELECT hou.organization_id AS organization_id
      INTO   gt_itou_ou_id
      FROM   hr_organization_units hou
      WHERE  hou.name = gt_itou_ou_mfg  -- 生産営業単位取得名称
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_itou_ou_id := NULL;
    END;
    -- 生産組織IDが取得出来ない場合
    IF ( gt_itou_ou_id IS NULL ) THEN
      -- トークン値を設定
      gv_tkn_vl1  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00094);
      gv_tkn_vl2  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00095);
      -- マスタチェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application        -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00013    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item           -- トークンコード1
                     ,iv_token_value1 => gv_tkn_vl1            -- トークン値1
                     ,iv_token_name2  => cv_tkn_value          -- トークンコード2
                     ,iv_token_value2 => gt_itou_ou_mfg        -- トークン値2
                     ,iv_token_name3  => cv_tkn_table          -- トークンコード3
                     ,iv_token_value3 => gv_tkn_vl2            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 7．営業組織ID取得
    --==============================================================
    BEGIN
      SELECT mp.organization_id  AS organization_id
      INTO   gt_sales_org_id
      FROM   mtl_parameters mp
      WHERE  mp.organization_code = gt_sales_org_code  -- 営業組織コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_sales_org_id := NULL;
    END;
    -- 営業組織IDが取得出来ない場合
    IF ( gt_sales_org_id IS NULL ) THEN
      -- トークン値を設定
      gv_tkn_vl1  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00080);
      gv_tkn_vl2  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00081);
      -- マスタチェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application        -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcop_00013    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item           -- トークンコード1
                     ,iv_token_value1 => gv_tkn_vl1            -- トークン値1
                     ,iv_token_name2  => cv_tkn_value          -- トークンコード2
                     ,iv_token_value2 => gt_sales_org_code     -- トークン値2
                     ,iv_token_name3  => cv_tkn_table          -- トークンコード3
                     ,iv_token_value3 => gv_tkn_vl2            -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_target_base_code
   * Description      : 対象拠点取得（配下拠点）（A-2）
   ***********************************************************************************/
  PROCEDURE get_target_base_code(
      ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_base_code'; -- プログラム名
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
    --==============================================================
    --  管理元拠点＋配下拠点抽出
    --==============================================================
    -- 顧客マスタから配下拠点を取得
    SELECT hca.account_number   AS base_code    -- 拠点コード
         , xp.party_short_name  AS base_name    -- 拠点名
    BULK COLLECT
    INTO   g_target_base_tbl
    FROM   hz_cust_accounts   hca   -- 顧客マスタ
    ,      xxcmn_parties      xp    -- パーティアドオンマスタ
    WHERE  hca.customer_class_code  =  cv_customer_class_base  -- 拠点
    AND (  hca.account_number       =  gv_base_code
      OR   hca.cust_account_id  IN (SELECT xca.customer_id  AS customer_id
                                    FROM   xxcmm_cust_accounts  xca -- 顧客追加情報
                                    WHERE  xca.management_base_code = gv_base_code  -- 管理元拠点コード
                                   )
        )
    AND    xp.party_id         (+)  =  hca.party_id
    AND    xp.start_date_active(+) <= gd_process_date
    AND    xp.end_date_active  (+) >= gd_process_date
    ORDER BY hca.account_number
    ;
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
  END get_target_base_code;
--
  /**********************************************************************************
   * Procedure Name   : get_forecast_info
   * Description      : 引取計画数取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_forecast_info(
      iv_base_code        IN  VARCHAR2  -- 拠点コード
    , iv_base_name        IN  VARCHAR2  -- 拠点名
    , ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_forecast_info'; -- プログラム名
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
    -- *** ローカルカーソル ***
    -- 引取計画情報カーソル
    CURSOR get_forecast_info_cur
    IS
      SELECT /*+
               LEADING(mfda mfde xic1v)
             */
             TO_CHAR(mfda.forecast_date ,cv_format_yyyymm)   AS target_date
           , mfde.attribute3                                 AS base_code
           , xic1v.item_no                                   AS item_code
           , item_short_name                                 AS item_name
           , xic1v.prod_class_code                           AS prod_class_code
           , xic1v.prod_class_name                           AS prod_class_name
           , xic1v.crowd_class_code                          AS crowd_class_code
           , SUBSTRB(xic1v.crowd_class_code ,cn_1 ,cn_3)     AS crowd_class_code3
           , SUM(TO_NUMBER(mfda.attribute6))                 AS forecast_qty
      FROM   mrp_forecast_dates       mfda  -- フォーキャスト日付
           , mrp_forecast_designators mfde  -- フォーキャスト名
           , xxcop_item_categories1_v xic1v -- 計画_品目カテゴリビュー1
      WHERE  mfde.forecast_designator = mfda.forecast_designator
      AND    mfde.organization_id     = mfda.organization_id
      AND    mfda.organization_id     = xic1v.organization_id
      AND    xic1v.inventory_item_id  = mfda.inventory_item_id
      AND    mfda.forecast_date      >= TO_DATE(gv_target_month ,cv_format_yyyymm)            -- 入力パラメータ.対象年月
      AND    mfda.forecast_date      <= LAST_DAY(TO_DATE(gv_target_month ,cv_format_yyyymm))  -- 入力パラメータ.対象年月
      AND    mfde.attribute3          = iv_base_code                                          -- 入力パラメータ.拠点コード
      AND    mfde.attribute1          = gv_forecast_type                                      -- 入力パラメータ.計画区分
      AND    xic1v.start_date_active <= gd_process_date
      AND    xic1v.end_date_active   >= gd_process_date
      AND    xic1v.prod_class_code    = NVL(gv_prod_class_code ,xic1v.prod_class_code)        -- 入力パラメータ.商品区分
      AND    xic1v.crowd_class_code   = NVL(gv_crowd_class_code ,xic1v.crowd_class_code)      -- 入力パラメータ.政策群コード
      AND    xic1v.item_no            = NVL(gv_item_code ,xic1v.item_no)                      -- 入力パラメータ.品目コード
      GROUP BY TO_CHAR(mfda.forecast_date ,cv_format_yyyymm)
             , mfde.attribute3
             , xic1v.item_no
             , xic1v.item_short_name
             , xic1v.prod_class_code
             , xic1v.prod_class_name
             , xic1v.crowd_class_code
             , SUBSTRB(xic1v.crowd_class_code ,cn_1 ,cn_3)
      ;
    -- レコード定義
    get_forecast_info_rec      get_forecast_info_cur%ROWTYPE;
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
    --  引取計画情報取得
    -- ===================================
    -- カーソルOPEN
    OPEN get_forecast_info_cur;
    LOOP
      FETCH get_forecast_info_cur INTO get_forecast_info_rec;
      EXIT WHEN get_forecast_info_cur%NOTFOUND;
      -- ===================================
      --  帳票発行用ワークテーブル登録
      -- ===================================
      BEGIN
        INSERT INTO xxcop_rep_forecast_comp_list(
          target_month                             -- 01：対象年月
        , process_date                             -- 02：業務日付
        , prod_class_code                          -- 03：商品区分
        , prod_class_name                          -- 04：商品区分名
        , base_code                                -- 05：拠点コード
        , base_name                                -- 06：拠点名
        , forecast_type                            -- 07：計画区分
        , forecast_type_name                       -- 08：計画区分名
        , crowd_class_code                         -- 09：政策群コード
        , crowd_class_code3                        -- 10：政策群コード(上3桁)
        , item_code                                -- 11：品目コード
        , item_name                                -- 12：品目名
        , forecast_qty                             -- 13：引取計画数
        , stock_comp_qty                           -- 14：入庫確認数（拠点入庫）
        , stock_order_comp_qty                     -- 15：依頼済数（拠点入庫）
        , ship_comp_qty                            -- 16：売上計上済数（直送）
        , ship_order_comp_qty                      -- 17：依頼済数（直送）
        , created_by                               -- 18：作成者
        , creation_date                            -- 19：作成日
        , last_updated_by                          -- 20：最終更新者
        , last_update_date                         -- 21：最終更新日
        , last_update_login                        -- 22：最終更新ログイン
        , request_id                               -- 23：要求ID
        , program_application_id                   -- 24：コンカレント・プログラム・アプリケーションID
        , program_id                               -- 25：コンカレント・プログラムID
        , program_update_date                      -- 26：プログラム更新日
        )VALUES(
          gv_target_month                          -- 01
        , gd_process_date                          -- 02
        , get_forecast_info_rec.prod_class_code    -- 03
        , get_forecast_info_rec.prod_class_name    -- 04
        , get_forecast_info_rec.base_code          -- 05
        , iv_base_name                             -- 06
        , gv_forecast_type                         -- 07
        , gt_forecast_type_name                    -- 08
        , get_forecast_info_rec.crowd_class_code   -- 09
        , get_forecast_info_rec.crowd_class_code3  -- 10
        , get_forecast_info_rec.item_code          -- 11
        , get_forecast_info_rec.item_name          -- 12
        , get_forecast_info_rec.forecast_qty       -- 13
        , cn_0                                     -- 14
        , cn_0                                     -- 15
        , cn_0                                     -- 16
        , cn_0                                     -- 17
        , cn_created_by                            -- 18
        , SYSDATE                                  -- 19
        , cn_last_updated_by                       -- 20
        , SYSDATE                                  -- 21
        , cn_last_update_login                     -- 22
        , cn_request_id                            -- 23
        , cn_program_application_id                -- 24
        , cn_program_id                            -- 25
        , SYSDATE                                  -- 26
        );
      --
      EXCEPTION
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- 登録処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
    END LOOP;
    CLOSE get_forecast_info_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルCLOSE
      IF (get_forecast_info_cur%ISOPEN) THEN
        CLOSE get_forecast_info_cur;
      END IF;
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
  END get_forecast_info;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_comp_info
   * Description      : 入庫確認数(拠点入庫)取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_stock_comp_info(
      iv_base_code        IN  VARCHAR2  -- 拠点コード
    , iv_base_name        IN  VARCHAR2  -- 拠点名
    , ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_comp_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy   NUMBER;         -- ダミー変数
--
    -- *** ローカルカーソル ***
    -- 入庫確認数(拠点入庫)取得カーソル
    CURSOR get_stock_comp_info_cur
    IS
      SELECT /*
              + LEADING(xsi)
             */
             TO_CHAR(xsi.slip_date ,cv_format_yyyymm)    AS target_month
           , xsi.base_code                               AS base_code
           , xsi.item_code                               AS item_code
           , ximb.item_short_name                        AS item_name
           , xacv1.segment1                              AS prod_class_code
           , xacv1.description                           AS prod_class_name
           , xacv2.segment1                              AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)         AS crowd_class_code3
           , CASE
               -- リーフの場合、確認数量総バラ数を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(xsi.check_summary_qty), cn_0)
               -- ドリンクの場合、確認数量ケース数を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(xsi.check_case_qty), cn_0)
             END                                         AS stock_comp_qty
      FROM   xxcoi_storage_information xsi   -- 入庫情報一時表
           , mtl_system_items_b        msib  -- Disc品目
           , xxcmn_item_mst_b          ximb  -- OPM品目アドオン
           , ic_item_mst_b             iimb  -- OPM品目
           , mtl_item_categories       mic1  -- カテゴリ割当
           , xxcop_all_categories_v    xacv1 -- 全品目カテゴリビュー
           , mtl_item_categories       mic2  -- カテゴリ割当
           , xxcop_all_categories_v    xacv2 -- 全品目カテゴリビュー
      WHERE  msib.segment1           = xsi.item_code
      AND    msib.organization_id    = gt_sales_org_id        -- 営業組織
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    ximb.start_date_active <= gd_process_date
      AND    ximb.end_date_active   >= gd_process_date
      AND    mic1.inventory_item_id  = msib.inventory_item_id
      AND    mic1.organization_id    = msib.organization_id
      AND    mic1.category_set_id    = xacv1.category_set_id
      AND    mic1.category_id        = xacv1.category_id
      AND    xacv1.category_set_name = gt_item_div_h          -- 本社商品区分
      AND    mic2.inventory_item_id  = msib.inventory_item_id
      AND    mic2.organization_id    = msib.organization_id
      AND    mic2.category_set_id    = xacv2.category_set_id
      AND    mic2.category_id        = xacv2.category_id
      AND    xacv2.category_set_name = gt_policy_group_code   -- 政策群コード
      AND    xsi.store_check_flag    = cv_store_check_y       -- 入庫確認済
      AND    xsi.summary_data_flag   = cv_summary_data_y      -- サマリーデータ
      AND    xsi.slip_date          >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- 入力パラメータ.対象年月
      AND    xsi.slip_date          <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- 入力パラメータ.対象年月
      AND    xsi.base_code           = iv_base_code                                         -- 入力パラメータ.拠点
      AND    xsi.item_code           = NVL(gv_item_code, xsi.item_code)                     -- 入力パラメータ.品目コード
      AND    xacv1.segment1          = NVL(gv_prod_class_code  ,xacv1.segment1)             -- 入力パラメータ.商品区分
      AND    xacv2.segment1          = NVL(gv_crowd_class_code ,xacv2.segment1)             -- 入力パラメータ.政策群コード
      GROUP BY TO_CHAR(xsi.slip_date, cv_format_yyyymm)
             , xsi.base_code
             , xsi.item_code
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
      ;
    -- レコード定義
    get_stock_comp_info_rec   get_stock_comp_info_cur%ROWTYPE;
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
    --  入庫確認数(拠点入庫)取得
    -- ===================================
    -- カーソルOPEN
    OPEN get_stock_comp_info_cur;
    LOOP
      FETCH get_stock_comp_info_cur INTO get_stock_comp_info_rec;
      EXIT WHEN get_stock_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  帳票発行用ワークテーブル存在チェック
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_stock_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_stock_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_stock_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  帳票発行用ワークテーブル更新
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.stock_comp_qty = xrfcl.stock_comp_qty
                                    + get_stock_comp_info_rec.stock_comp_qty
        WHERE  xrfcl.target_month   = get_stock_comp_info_rec.target_month
        AND    xrfcl.base_code      = get_stock_comp_info_rec.base_code
        AND    xrfcl.item_code      = get_stock_comp_info_rec.item_code
        AND    xrfcl.request_id     = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  帳票発行用ワークテーブル登録
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                               -- 01：対象年月
            , process_date                               -- 02：業務日付
            , prod_class_code                            -- 03：商品区分
            , prod_class_name                            -- 04：商品区分名
            , base_code                                  -- 05：拠点コード
            , base_name                                  -- 06：拠点名
            , forecast_type                              -- 07：計画区分
            , forecast_type_name                         -- 08：計画区分名
            , crowd_class_code                           -- 09：政策群コード
            , crowd_class_code3                          -- 10：政策群コード(上3桁)
            , item_code                                  -- 11：品目コード
            , item_name                                  -- 12：品目名
            , forecast_qty                               -- 13：引取計画数
            , stock_comp_qty                             -- 14：入庫確認数（拠点入庫）
            , stock_order_comp_qty                       -- 15：依頼済数（拠点入庫）
            , ship_comp_qty                              -- 16：売上計上済数（直送）
            , ship_order_comp_qty                        -- 17：依頼済数（直送）
            , created_by                                 -- 18：作成者
            , creation_date                              -- 19：作成日
            , last_updated_by                            -- 20：最終更新者
            , last_update_date                           -- 21：最終更新日
            , last_update_login                          -- 22：最終更新ログイン
            , request_id                                 -- 23：要求ID
            , program_application_id                     -- 24：コンカレント・プログラム・アプリケーションID
            , program_id                                 -- 25：コンカレント・プログラムID
            , program_update_date                        -- 26：プログラム更新日
            ) VALUES(
              gv_target_month                            -- 01
            , gd_process_date                            -- 02
            , get_stock_comp_info_rec.prod_class_code    -- 03
            , get_stock_comp_info_rec.prod_class_name    -- 04
            , get_stock_comp_info_rec.base_code          -- 05
            , iv_base_name                               -- 06
            , gv_forecast_type                           -- 07
            , gt_forecast_type_name                      -- 08
            , get_stock_comp_info_rec.crowd_class_code   -- 09
            , get_stock_comp_info_rec.crowd_class_code3  -- 10
            , get_stock_comp_info_rec.item_code          -- 11
            , get_stock_comp_info_rec.item_name          -- 12
            , cn_0                                       -- 13
            , get_stock_comp_info_rec.stock_comp_qty     -- 14
            , cn_0                                       -- 15
            , cn_0                                       -- 16
            , cn_0                                       -- 17
            , cn_created_by                              -- 18
            , SYSDATE                                    -- 19
            , cn_last_updated_by                         -- 20
            , SYSDATE                                    -- 21
            , cn_last_update_login                       -- 22
            , cn_request_id                              -- 23
            , cn_program_application_id                  -- 24
            , cn_program_id                              -- 25
            , SYSDATE                                    -- 26
            );
            -- 対象件数カウント
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- トークン値を設定
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- 登録処理エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                             , iv_token_name1  => cv_tkn_table          -- トークンコード1
                             , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- 更新処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00028    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_stock_comp_info_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルCLOSE
      IF (get_stock_comp_info_cur%ISOPEN) THEN
        CLOSE get_stock_comp_info_cur;
      END IF;
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
  END get_stock_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_order_comp_info
   * Description      : 依頼済数(拠点入庫－拠点未入庫)取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_stock_order_comp_info(
      iv_base_code        IN  VARCHAR2  -- 拠点コード
    , iv_base_name        IN  VARCHAR2  -- 拠点名
    , ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_order_comp_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy   NUMBER;         -- ダミー変数
--
    -- *** ローカルカーソル ***
    -- 依頼済数(拠点入庫－拠点未入庫)取得カーソル
    CURSOR get_stock_order_comp_info_cur
    IS
      SELECT /*+
               LEADING(xsi)
             */
             TO_CHAR(xsi.slip_date ,cv_format_yyyymm)    AS target_month
           , xsi.base_code                               AS base_code
           , xsi.item_code                               AS item_code
           , ximb.item_short_name                        AS item_name
           , xacv1.segment1                              AS prod_class_code
           , xacv1.description                           AS prod_class_name
           , xacv2.segment1                              AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)         AS crowd_class_code3
           , CASE
               -- リーフの場合、出庫数量総バラ数を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(xsi.ship_summary_qty), cn_0)
               -- ドリンクの場合、出庫数量ケース数を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(xsi.ship_case_qty), cn_0)
             END                                         AS stock_order_comp_qty
      FROM   xxcoi_storage_information xsi   -- 入庫情報一時表
           , mtl_system_items_b        msib  -- Disc品目
           , xxcmn_item_mst_b          ximb  -- OPM品目アドオン
           , ic_item_mst_b             iimb  -- OPM品目
           , mtl_item_categories       mic1  -- カテゴリ割当
           , xxcop_all_categories_v    xacv1 -- 全品目カテゴリビュー
           , mtl_item_categories       mic2  -- カテゴリ割当
           , xxcop_all_categories_v    xacv2 -- 全品目カテゴリビュー
      WHERE  msib.segment1           = xsi.item_code
      AND    msib.organization_id    = gt_sales_org_id        -- 営業組織
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    ximb.start_date_active <= gd_process_date
      AND    ximb.end_date_active   >= gd_process_date
      AND    mic1.inventory_item_id  = msib.inventory_item_id
      AND    mic1.organization_id    = msib.organization_id
      AND    mic1.category_set_id    = xacv1.category_set_id
      AND    mic1.category_id        = xacv1.category_id
      AND    xacv1.category_set_name = gt_item_div_h          -- 本社商品区分
      AND    mic2.inventory_item_id  = msib.inventory_item_id
      AND    mic2.organization_id    = msib.organization_id
      AND    mic2.category_set_id    = xacv2.category_set_id
      AND    mic2.category_id        = xacv2.category_id
      AND    xacv2.category_set_name = gt_policy_group_code   -- 政策群コード
      AND    xsi.store_check_flag    = cv_store_check_n       -- 入庫未確認
      AND    xsi.summary_data_flag   = cv_summary_data_y      -- サマリーデータ
      AND    xsi.req_status          = cv_req_status_04       -- 出荷実績計上済
      AND    xsi.slip_date          >= TO_DATE(gv_target_month ,cv_format_yyyymm)           -- 入力パラメータ.対象年月
      AND    xsi.slip_date          <= LAST_DAY(TO_DATE(gv_target_month ,cv_format_yyyymm)) -- 入力パラメータ.対象年月
      AND    xsi.base_code           = iv_base_code                                         -- 入力パラメータ.拠点
      AND    xsi.item_code           = NVL(gv_item_code ,xsi.item_code)                     -- 入力パラメータ.商品コード
      AND    xacv1.segment1          = NVL(gv_prod_class_code  ,xacv1.segment1)             -- 入力パラメータ.商品区分
      AND    xacv2.segment1          = NVL(gv_crowd_class_code ,xacv2.segment1)             -- 入力パラメータ.政策群コード
      GROUP BY TO_CHAR(xsi.slip_date, cv_format_yyyymm)
             , xsi.base_code
             , xsi.item_code
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
      ;
    -- レコード定義
    get_stock_order_comp_info_rec   get_stock_order_comp_info_cur%ROWTYPE;
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
    --  依頼済数(拠点入庫－拠点未入庫)取得
    -- ===================================
    -- カーソルOPEN
    OPEN get_stock_order_comp_info_cur;
    LOOP
      FETCH get_stock_order_comp_info_cur INTO get_stock_order_comp_info_rec;
      EXIT WHEN get_stock_order_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  帳票発行用ワークテーブル存在チェック
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_stock_order_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_stock_order_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_stock_order_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  帳票発行用ワークテーブル更新
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.stock_order_comp_qty = xrfcl.stock_order_comp_qty
                                          + get_stock_order_comp_info_rec.stock_order_comp_qty
        WHERE  xrfcl.target_month         = get_stock_order_comp_info_rec.target_month
        AND    xrfcl.base_code            = get_stock_order_comp_info_rec.base_code
        AND    xrfcl.item_code            = get_stock_order_comp_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  帳票発行用ワークテーブル登録
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                                        -- 01：対象年月
            , process_date                                        -- 02：業務日付
            , prod_class_code                                     -- 03：商品区分
            , prod_class_name                                     -- 04：商品区分名
            , base_code                                           -- 05：拠点コード
            , base_name                                           -- 06：拠点名
            , forecast_type                                       -- 07：計画区分
            , forecast_type_name                                  -- 08：計画区分名
            , crowd_class_code                                    -- 09：政策群コード
            , crowd_class_code3                                   -- 10：政策群コード(上3桁)
            , item_code                                           -- 11：品目コード
            , item_name                                           -- 12：品目名
            , forecast_qty                                        -- 13：引取計画数
            , stock_comp_qty                                      -- 14：入庫確認数（拠点入庫）
            , stock_order_comp_qty                                -- 15：依頼済数（拠点入庫）
            , ship_comp_qty                                       -- 16：売上計上済数（直送）
            , ship_order_comp_qty                                 -- 17：依頼済数（直送）
            , created_by                                          -- 18：作成者
            , creation_date                                       -- 19：作成日
            , last_updated_by                                     -- 20：最終更新者
            , last_update_date                                    -- 21：最終更新日
            , last_update_login                                   -- 22：最終更新ログイン
            , request_id                                          -- 23：要求ID
            , program_application_id                              -- 24：コンカレント・プログラム・アプリケーションID
            , program_id                                          -- 25：コンカレント・プログラムID
            , program_update_date                                 -- 26：プログラム更新日
            ) VALUES(
              gv_target_month                                     -- 01
            , gd_process_date                                     -- 02
            , get_stock_order_comp_info_rec.prod_class_code       -- 03
            , get_stock_order_comp_info_rec.prod_class_name       -- 04
            , get_stock_order_comp_info_rec.base_code             -- 05
            , iv_base_name                                        -- 06
            , gv_forecast_type                                    -- 07
            , gt_forecast_type_name                               -- 08
            , get_stock_order_comp_info_rec.crowd_class_code      -- 09
            , get_stock_order_comp_info_rec.crowd_class_code3     -- 10
            , get_stock_order_comp_info_rec.item_code             -- 11
            , get_stock_order_comp_info_rec.item_name             -- 12
            , cn_0                                                -- 13
            , cn_0                                                -- 14
            , get_stock_order_comp_info_rec.stock_order_comp_qty  -- 15
            , cn_0                                                -- 16
            , cn_0                                                -- 17
            , cn_created_by                                       -- 18
            , SYSDATE                                             -- 19
            , cn_last_updated_by                                  -- 20
            , SYSDATE                                             -- 21
            , cn_last_update_login                                -- 22
            , cn_request_id                                       -- 23
            , cn_program_application_id                           -- 24
            , cn_program_id                                       -- 25
            , SYSDATE                                             -- 26
            );
            -- 対象件数カウント
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- トークン値を設定
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- 登録処理エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                             , iv_token_name1  => cv_tkn_table          -- トークンコード1
                             , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- 更新処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00028    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_stock_order_comp_info_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルCLOSE
      IF (get_stock_order_comp_info_cur%ISOPEN) THEN
        CLOSE get_stock_order_comp_info_cur;
      END IF;
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
  END get_stock_order_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_fact_ship_info
   * Description      : 依頼済数(拠点入庫－工場未出荷)取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_stock_fact_ship_info(
      iv_base_code        IN  VARCHAR2  -- 拠点コード
    , iv_base_name        IN  VARCHAR2  -- 拠点名
    , ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_comp_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy   NUMBER;         -- ダミー変数
--
    -- *** ローカルカーソル ***
    -- 依頼済数(拠点入庫－工場未出荷)取得カーソル
    CURSOR get_stock_fact_ship_info_cur
    IS
      SELECT /*+
               LEADING(ottt otta xoha hps hca)
             */
             TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)  AS target_month
           , xca.sale_base_code                                     AS base_code
           , iimb.item_no                                           AS item_code
           , ximb.item_short_name                                   AS item_name
           , xacv1.segment1                                         AS prod_class_code
           , xacv1.description                                      AS prod_class_name
           , xacv2.segment1                                         AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)                    AS crowd_class_code3
           , CASE
               -- リーフの場合、数量を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0)
                             -- 受注カテゴリコードで正符号を設定
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURNの場合、マイナスを掛ける
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
               -- ドリンクの場合、数量をケース換算し小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0) / NVL(TO_NUMBER(iimb.attribute11) ,cn_1)
                             -- 受注カテゴリコードで正符号を設定
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURNの場合、マイナスを掛ける
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
             END                                                    AS stock_order_comp_qty
      FROM   xxwsh_order_headers_all   xoha  -- 受注ヘッダアドオン
           , xxwsh_order_lines_all     xola  -- 受注明細アドオン
           , mtl_system_items_b        msib  -- Disc品目マスタ
           , xxcmn_item_mst_b          ximb  -- OPM品目アドオンマスタ
           , ic_item_mst_b             iimb  -- OPM品目マスタ
           , mtl_item_categories       mic1  -- カテゴリ割当
           , xxcop_all_categories_v    xacv1 -- 全品目カテゴリビュー
           , mtl_item_categories       mic2  -- カテゴリ割当
           , xxcop_all_categories_v    xacv2 -- 全品目カテゴリビュー
           , oe_transaction_types_all  otta  -- 取引タイプ
           , oe_transaction_types_tl   ottt  -- 取引タイプ詳細
           , hz_party_sites            hps   -- パーティサイト
           , hz_cust_accounts          hca   -- 顧客マスタ
           , xxcmm_cust_accounts       xca   -- 顧客追加情報
           , hz_locations              hl    -- 事業所マスタ
      WHERE  xoha.order_header_id        = xola.order_header_id
      AND    xola.request_item_id        = msib.inventory_item_id
      AND    msib.segment1               = iimb.item_no
      AND    iimb.item_id                = ximb.item_id
      AND    xoha.order_type_id          = ottt.transaction_type_id
      AND    ottt.transaction_type_id    = otta.transaction_type_id
      AND    hps.party_id                = hca.party_id
      AND    hca.cust_account_id         = xca.customer_id
      AND    msib.organization_id        = gt_sales_org_id        -- 営業組織ID
      AND    mic1.inventory_item_id      = msib.inventory_item_id
      AND    mic1.organization_id        = msib.organization_id
      AND    mic1.category_set_id        = xacv1.category_set_id
      AND    mic1.category_id            = xacv1.category_id
      AND    xacv1.category_set_name     = gt_item_div_h          -- 本社商品区分
      AND    mic2.inventory_item_id      = msib.inventory_item_id
      AND    mic2.organization_id        = msib.organization_id
      AND    mic2.category_set_id        = xacv2.category_set_id
      AND    mic2.category_id            = xacv2.category_id
      AND    xacv2.category_set_name     = gt_policy_group_code   -- 政策群コード
      AND    otta.org_id                 = gt_itou_ou_id          -- 生産組織ID
      AND    otta.attribute1             = cv_ship_order          -- 出荷依頼
      AND    NVL(otta.attribute4 ,cv_stock_etc)
                                        <> cv_stock_adjm          -- 在庫調整以外
      AND    ottt.language               = ct_lang
      AND    hps.location_id             = hl.location_id
      AND    SUBSTRB(hl.province, cn_1, cn_1)
                                         = cv_wh_type_base        -- 拠点倉庫
      AND    hca.customer_class_code     = cv_customer_class_base -- 顧客区分：拠点
      AND    NVL(xola.delete_flag, cv_delete_flag_n)
                                         = cv_delete_flag_n       -- N：削除以外
      AND    xoha.latest_external_flag   = cv_latest_ext_flag_y   -- Y：最新
      AND    xca.sale_base_code          = iv_base_code           -- 入力パラメータ.拠点
      AND    iimb.item_no                = NVL(gv_item_code ,iimb.item_no) -- 入力パラメータ.品目コード
      AND    xoha.req_status             IN (cv_req_status_01      -- 01：入力中
                                           , cv_req_status_02      -- 02：拠点確定
                                           , cv_req_status_03)     -- 03：締め済み
      AND    xoha.deliver_to_id          = hps.party_site_id
      AND    ximb.start_date_active     <= gd_process_date
      AND    ximb.end_date_active       >= gd_process_date
      AND    xoha.schedule_arrival_date >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- 入力パラメータ.対象年月
      AND    xoha.schedule_arrival_date <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- 入力パラメータ.対象年月
      AND    xacv1.segment1              = NVL(gv_prod_class_code  ,xacv1.segment1)             -- 入力パラメータ.商品区分
      AND    xacv2.segment1              = NVL(gv_crowd_class_code ,xacv2.segment1)             -- 入力パラメータ.政策群コード
      AND NOT EXISTS ( SELECT '1'  AS dummy
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type        = cv_lkup_exc_order_type -- 入庫情報抽出対象外受注タイプ
                       AND    flv.enabled_flag       = cv_flag_y
                       AND    flv.language           = ct_lang
                       AND    flv.start_date_active <= gd_process_date
                       AND    NVL(flv.end_date_active ,gd_process_date)
                                                    >= gd_process_date
                       AND    ottt.name              = flv.meaning
                     )
      GROUP BY TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)
             , xca.sale_base_code
             , iimb.item_no
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
             , otta.order_category_code
      ;
    -- レコード定義
    get_stock_fact_ship_info_rec   get_stock_fact_ship_info_cur%ROWTYPE;
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
    --  依頼済数(拠点入庫－工場未出荷)取得
    -- ===================================
    -- カーソルOPEN
    OPEN get_stock_fact_ship_info_cur;
    LOOP
      FETCH get_stock_fact_ship_info_cur INTO get_stock_fact_ship_info_rec;
      EXIT WHEN get_stock_fact_ship_info_cur%NOTFOUND;
      --
      -- ======================================
      --  帳票発行用ワークテーブル存在チェック
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_stock_fact_ship_info_rec.target_month
        AND    xrfcl.base_code    = get_stock_fact_ship_info_rec.base_code
        AND    xrfcl.item_code    = get_stock_fact_ship_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  帳票発行用ワークテーブル更新
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.stock_order_comp_qty = xrfcl.stock_order_comp_qty
                                          + get_stock_fact_ship_info_rec.stock_order_comp_qty
        WHERE  xrfcl.target_month         = get_stock_fact_ship_info_rec.target_month
        AND    xrfcl.base_code            = get_stock_fact_ship_info_rec.base_code
        AND    xrfcl.item_code            = get_stock_fact_ship_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  帳票発行用ワークテーブル登録
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                                       -- 01：対象年月
            , process_date                                       -- 02：業務日付
            , prod_class_code                                    -- 03：商品区分
            , prod_class_name                                    -- 04：商品区分名
            , base_code                                          -- 05：拠点コード
            , base_name                                          -- 06：拠点名
            , forecast_type                                      -- 07：計画区分
            , forecast_type_name                                 -- 08：計画区分名
            , crowd_class_code                                   -- 09：政策群コード
            , crowd_class_code3                                  -- 10：政策群コード(上3桁)
            , item_code                                          -- 11：品目コード
            , item_name                                          -- 12：品目名
            , forecast_qty                                       -- 13：引取計画数
            , stock_comp_qty                                     -- 14：入庫確認数（拠点入庫）
            , stock_order_comp_qty                               -- 15：依頼済数（拠点入庫）
            , ship_comp_qty                                      -- 16：売上計上済数（直送）
            , ship_order_comp_qty                                -- 17：依頼済数（直送）
            , created_by                                         -- 18：作成者
            , creation_date                                      -- 19：作成日
            , last_updated_by                                    -- 20：最終更新者
            , last_update_date                                   -- 21：最終更新日
            , last_update_login                                  -- 22：最終更新ログイン
            , request_id                                         -- 23：要求ID
            , program_application_id                             -- 24：コンカレント・プログラム・アプリケーションID
            , program_id                                         -- 25：コンカレント・プログラムID
            , program_update_date                                -- 26：プログラム更新日
            ) VALUES(
              gv_target_month                                    -- 01
            , gd_process_date                                    -- 02
            , get_stock_fact_ship_info_rec.prod_class_code       -- 03
            , get_stock_fact_ship_info_rec.prod_class_name       -- 04
            , get_stock_fact_ship_info_rec.base_code             -- 05
            , iv_base_name                                       -- 06
            , gv_forecast_type                                   -- 07
            , gt_forecast_type_name                              -- 08
            , get_stock_fact_ship_info_rec.crowd_class_code      -- 09
            , get_stock_fact_ship_info_rec.crowd_class_code3     -- 10
            , get_stock_fact_ship_info_rec.item_code             -- 11
            , get_stock_fact_ship_info_rec.item_name             -- 12
            , cn_0                                               -- 13
            , cn_0                                               -- 14
            , get_stock_fact_ship_info_rec.stock_order_comp_qty  -- 15
            , cn_0                                               -- 16
            , cn_0                                               -- 17
            , cn_created_by                                      -- 18
            , SYSDATE                                            -- 19
            , cn_last_updated_by                                 -- 20
            , SYSDATE                                            -- 21
            , cn_last_update_login                               -- 22
            , cn_request_id                                      -- 23
            , cn_program_application_id                          -- 24
            , cn_program_id                                      -- 25
            , SYSDATE                                            -- 26
            );
            -- 対象件数カウント
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- トークン値を設定
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- 登録処理エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                             , iv_token_name1  => cv_tkn_table          -- トークンコード1
                             , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- 更新処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00028    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_stock_fact_ship_info_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルCLOSE
      IF (get_stock_fact_ship_info_cur%ISOPEN) THEN
        CLOSE get_stock_fact_ship_info_cur;
      END IF;
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
  END get_stock_fact_ship_info;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_comp_info
   * Description      : 売上計上済数取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_ship_comp_info(
      iv_base_code        IN  VARCHAR2  -- 拠点コード
    , iv_base_name        IN  VARCHAR2  -- 拠点名
    , ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_comp_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy   NUMBER;         -- ダミー変数
--
    -- *** ローカルカーソル ***
    -- 売上計上済数取得カーソル
    CURSOR get_ship_comp_info_cur
    IS
      SELECT /*+
               LEADING(ottt otta xoha hps hca)
             */
             TO_CHAR(xoha.arrival_date ,cv_format_yyyymm)  AS target_month
           , xca.sale_base_code                            AS base_code
           , iimb.item_no                                  AS item_code
           , ximb.item_short_name                          AS item_name
           , xacv1.segment1                                AS prod_class_code
           , xacv1.description                             AS prod_class_name
           , xacv2.segment1                                AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)           AS crowd_class_code3
           , CASE
               -- リーフの場合、出荷実績数量を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(NVL(xola.shipped_quantity, cn_0)
                             -- 受注カテゴリコードで正符号を設定
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURNの場合、マイナスを掛ける
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
               -- ドリンクの場合、出荷実績数量をケース換算し小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(NVL(xola.shipped_quantity, cn_0) / NVL(TO_NUMBER(iimb.attribute11) ,cn_1)
                             -- 受注カテゴリコードで正符号を設定
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURNの場合、マイナスを掛ける
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
             END                                           AS ship_comp_qty
      FROM   xxwsh_order_headers_all   xoha  -- 受注ヘッダアドオン
           , xxwsh_order_lines_all     xola  -- 受注明細アドオン
           , mtl_system_items_b        msib  -- Disc品目マスタ
           , xxcmn_item_mst_b          ximb  -- OPM品目アドオンマスタ
           , ic_item_mst_b             iimb  -- OPM品目マスタ
           , mtl_item_categories       mic1  -- カテゴリ割当
           , xxcop_all_categories_v    xacv1 -- 全品目カテゴリビュー
           , mtl_item_categories       mic2  -- カテゴリ割当
           , xxcop_all_categories_v    xacv2 -- 全品目カテゴリビュー
           , oe_transaction_types_all  otta  -- 取引タイプ
           , oe_transaction_types_tl   ottt  -- 取引タイプ詳細
           , hz_party_sites            hps   -- パーティサイト
           , hz_cust_accounts          hca   -- 顧客マスタ
           , xxcmm_cust_accounts       xca   -- 顧客追加情報
      WHERE  xoha.order_header_id        = xola.order_header_id
      AND    xola.request_item_id        = msib.inventory_item_id
      AND    msib.segment1               = iimb.item_no
      AND    iimb.item_id                = ximb.item_id
      AND    xoha.order_type_id          = ottt.transaction_type_id
      AND    ottt.transaction_type_id    = otta.transaction_type_id
      AND    hps.party_id                = hca.party_id
      AND    hca.cust_account_id         = xca.customer_id
      AND    msib.organization_id        = gt_sales_org_id         -- 営業組織ID
      AND    mic1.inventory_item_id      = msib.inventory_item_id
      AND    mic1.organization_id        = msib.organization_id
      AND    mic1.category_set_id        = xacv1.category_set_id
      AND    mic1.category_id            = xacv1.category_id
      AND    xacv1.category_set_name     = gt_item_div_h           -- 本社商品区分
      AND    mic2.inventory_item_id      = msib.inventory_item_id
      AND    mic2.organization_id        = msib.organization_id
      AND    mic2.category_set_id        = xacv2.category_set_id
      AND    mic2.category_id            = xacv2.category_id
      AND    xacv2.category_set_name     = gt_policy_group_code    -- 政策群コード
      AND    otta.org_id                 = gt_itou_ou_id           -- 生産組織ID
      AND    otta.attribute1             = cv_ship_order           -- 出荷依頼
      AND    NVL(otta.attribute4 ,cv_stock_etc)
                                        <> cv_stock_adjm           -- 在庫調整以外
      AND    ottt.language               = ct_lang
      AND    hca.customer_class_code     = cv_customer_class_cust  -- 顧客区分：顧客
      AND    NVL(xola.delete_flag, cv_delete_flag_n)
                                         = cv_delete_flag_n        -- N：削除以外
      AND    xoha.latest_external_flag   = cv_latest_ext_flag_y    -- Y：最新
      AND    xca.sale_base_code          = iv_base_code            -- 入力パラメータ.拠点
      AND    iimb.item_no                = NVL(gv_item_code ,iimb.item_no)
                                                                   -- 入力パラメータ.品目コード
      AND    xoha.req_status             = cv_req_status_04        -- 04：出荷実績計上済
      AND    xoha.actual_confirm_class   = cv_act_conf_class_y     -- Y：実績計上済
      AND    xoha.result_deliver_to_id   = hps.party_site_id
      AND    ximb.start_date_active     <= gd_process_date
      AND    ximb.end_date_active       >= gd_process_date
      AND    xoha.arrival_date          >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- 入力パラメータ.対象年月
      AND    xoha.arrival_date          <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- 入力パラメータ.対象年月
      AND    xacv1.segment1              = NVL(gv_prod_class_code  ,xacv1.segment1)             -- 入力パラメータ.商品区分
      AND    xacv2.segment1              = NVL(gv_crowd_class_code ,xacv2.segment1)             -- 入力パラメータ.政策群コード
      AND NOT EXISTS ( SELECT '1'  AS dummy
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type        = cv_lkup_exc_order_type -- 入庫情報抽出対象外受注タイプ
                       AND    flv.enabled_flag       = cv_flag_y
                       AND    flv.language           = ct_lang
                       AND    flv.start_date_active <= gd_process_date
                       AND    NVL(flv.end_date_active ,gd_process_date)
                                                    >= gd_process_date
                       AND    ottt.name              = flv.meaning
                     )
      GROUP BY TO_CHAR(xoha.arrival_date ,cv_format_yyyymm)
             , xca.sale_base_code
             , iimb.item_no
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
             , otta.order_category_code
      ;
    -- レコード定義
    get_ship_comp_info_rec   get_ship_comp_info_cur%ROWTYPE;
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
    --  売上計上済数取得
    -- ===================================
    -- カーソルOPEN
    OPEN get_ship_comp_info_cur;
    LOOP
      FETCH get_ship_comp_info_cur INTO get_ship_comp_info_rec;
      EXIT WHEN get_ship_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  帳票発行用ワークテーブル存在チェック
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_ship_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_ship_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_ship_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  帳票発行用ワークテーブル更新
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.ship_comp_qty        = xrfcl.ship_comp_qty
                                          + get_ship_comp_info_rec.ship_comp_qty
        WHERE  xrfcl.target_month         = get_ship_comp_info_rec.target_month
        AND    xrfcl.base_code            = get_ship_comp_info_rec.base_code
        AND    xrfcl.item_code            = get_ship_comp_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  帳票発行用ワークテーブル登録
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                              -- 01：対象年月
            , process_date                              -- 02：業務日付
            , prod_class_code                           -- 03：商品区分
            , prod_class_name                           -- 04：商品区分名
            , base_code                                 -- 05：拠点コード
            , base_name                                 -- 06：拠点名
            , forecast_type                             -- 07：計画区分
            , forecast_type_name                        -- 08：計画区分名
            , crowd_class_code                          -- 09：政策群コード
            , crowd_class_code3                         -- 10：政策群コード(上3桁)
            , item_code                                 -- 11：品目コード
            , item_name                                 -- 12：品目名
            , forecast_qty                              -- 13：引取計画数
            , stock_comp_qty                            -- 14：入庫確認数（拠点入庫）
            , stock_order_comp_qty                      -- 15：依頼済数（拠点入庫）
            , ship_comp_qty                             -- 16：売上計上済数（直送）
            , ship_order_comp_qty                       -- 17：依頼済数（直送）
            , created_by                                -- 18：作成者
            , creation_date                             -- 19：作成日
            , last_updated_by                           -- 20：最終更新者
            , last_update_date                          -- 21：最終更新日
            , last_update_login                         -- 22：最終更新ログイン
            , request_id                                -- 23：要求ID
            , program_application_id                    -- 24：コンカレント・プログラム・アプリケーションID
            , program_id                                -- 25：コンカレント・プログラムID
            , program_update_date                       -- 26：プログラム更新日
            ) VALUES(
              gv_target_month                           -- 01
            , gd_process_date                           -- 02
            , get_ship_comp_info_rec.prod_class_code    -- 03
            , get_ship_comp_info_rec.prod_class_name    -- 04
            , get_ship_comp_info_rec.base_code          -- 05
            , iv_base_name                              -- 06
            , gv_forecast_type                          -- 07
            , gt_forecast_type_name                     -- 08
            , get_ship_comp_info_rec.crowd_class_code   -- 09
            , get_ship_comp_info_rec.crowd_class_code3  -- 10
            , get_ship_comp_info_rec.item_code          -- 11
            , get_ship_comp_info_rec.item_name          -- 12
            , cn_0                                      -- 13
            , cn_0                                      -- 14
            , cn_0                                      -- 15
            , get_ship_comp_info_rec.ship_comp_qty      -- 16
            , cn_0                                      -- 17
            , cn_created_by                             -- 18
            , SYSDATE                                   -- 19
            , cn_last_updated_by                        -- 20
            , SYSDATE                                   -- 21
            , cn_last_update_login                      -- 22
            , cn_request_id                             -- 23
            , cn_program_application_id                 -- 24
            , cn_program_id                             -- 25
            , SYSDATE                                   -- 26
            );
            -- 対象件数カウント
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- トークン値を設定
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- 登録処理エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                             , iv_token_name1  => cv_tkn_table          -- トークンコード1
                             , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- 更新処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00028    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_ship_comp_info_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルCLOSE
      IF (get_ship_comp_info_cur%ISOPEN) THEN
        CLOSE get_ship_comp_info_cur;
      END IF;
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
  END get_ship_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_order_comp_info
   * Description      : 依頼済数(直送)取得処理(A-8)
   ***********************************************************************************/
  PROCEDURE get_ship_order_comp_info(
      iv_base_code        IN  VARCHAR2  -- 拠点コード
    , iv_base_name        IN  VARCHAR2  -- 拠点名
    , ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode          OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_order_comp_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_dummy   NUMBER;         -- ダミー変数
--
    -- *** ローカルカーソル ***
    -- 依頼済数(直送)取得カーソル
    CURSOR get_ship_order_comp_info_cur
    IS
      SELECT /*+
               LEADING(ottt otta xoha hps hca)
             */
             TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)  AS target_month
           , xca.sale_base_code                                     AS base_code
           , iimb.item_no                                           AS item_code
           , ximb.item_short_name                                   AS item_name
           , xacv1.segment1                                         AS prod_class_code
           , xacv1.description                                      AS prod_class_name
           , xacv2.segment1                                         AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)                    AS crowd_class_code3
           , CASE
               -- リーフの場合、数量を小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0)
                             -- 受注カテゴリコードで正符号を設定
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURNの場合、マイナスを掛ける
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
               -- ドリンクの場合、数量をケース換算し小数点以下1位で切り捨て
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0) / NVL(TO_NUMBER(iimb.attribute11) ,cn_1)
                             -- 受注カテゴリコードで正符号を設定
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURNの場合、マイナスを掛ける
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
             END                                                    AS ship_order_comp_qty
      FROM   xxwsh_order_headers_all   xoha  -- 受注ヘッダアドオン
           , xxwsh_order_lines_all     xola  -- 受注明細アドオン
           , mtl_system_items_b        msib  -- Disc品目マスタ
           , xxcmn_item_mst_b          ximb  -- OPM品目アドオンマスタ
           , ic_item_mst_b             iimb  -- OPM品目マスタ(子品目)
           , mtl_item_categories       mic1  -- カテゴリ割当
           , xxcop_all_categories_v    xacv1 -- 全品目カテゴリビュー
           , mtl_item_categories       mic2  -- カテゴリ割当
           , xxcop_all_categories_v    xacv2 -- 全品目カテゴリビュー
           , oe_transaction_types_all  otta  -- 取引タイプ
           , oe_transaction_types_tl   ottt  -- 取引タイプ詳細
           , hz_party_sites            hps   -- パーティサイト
           , hz_cust_accounts          hca   -- 顧客マスタ
           , xxcmm_cust_accounts       xca   -- 顧客追加情報
      WHERE  xoha.order_header_id        = xola.order_header_id
      AND    xola.request_item_id        = msib.inventory_item_id
      AND    msib.segment1               = iimb.item_no
      AND    iimb.item_id                = ximb.item_id
      AND    xoha.order_type_id          = ottt.transaction_type_id
      AND    ottt.transaction_type_id    = otta.transaction_type_id
      AND    hps.party_id                = hca.party_id
      AND    hca.cust_account_id         = xca.customer_id
      AND    msib.organization_id        = gt_sales_org_id         -- 営業組織ID
      AND    mic1.inventory_item_id      = msib.inventory_item_id
      AND    mic1.organization_id        = msib.organization_id
      AND    mic1.category_set_id        = xacv1.category_set_id
      AND    mic1.category_id            = xacv1.category_id
      AND    xacv1.category_set_name     = gt_item_div_h           -- 本社商品区分
      AND    mic2.inventory_item_id      = msib.inventory_item_id
      AND    mic2.organization_id        = msib.organization_id
      AND    mic2.category_set_id        = xacv2.category_set_id
      AND    mic2.category_id            = xacv2.category_id
      AND    xacv2.category_set_name     = gt_policy_group_code    -- 政策群コード
      AND    otta.org_id                 = gt_itou_ou_id           -- 生産組織ID
      AND    otta.attribute1             = cv_ship_order           -- 出荷依頼
      AND    NVL(otta.attribute4 ,cv_stock_etc)
                                        <> cv_stock_adjm           -- 在庫調整以外
      AND    ottt.language               = ct_lang
      AND    hca.customer_class_code     = cv_customer_class_cust  -- 顧客区分：顧客
      AND    NVL(xola.delete_flag, cv_delete_flag_n)
                                         = cv_delete_flag_n        -- N：削除以外
      AND    xoha.latest_external_flag   = cv_latest_ext_flag_y    -- Y：最新
      AND    xca.sale_base_code          = iv_base_code            -- 入力パラメータ.拠点
      AND    iimb.item_no                = NVL(gv_item_code ,iimb.item_no)
                                                                   -- 入力パラメータ.品目コード
      AND    xoha.req_status             IN (cv_req_status_01      -- 01：入力中
                                           , cv_req_status_02      -- 02：拠点確定
                                           , cv_req_status_03)     -- 03：締め済み
      AND    xoha.deliver_to_id          = hps.party_site_id
      AND    ximb.start_date_active     <= gd_process_date
      AND    ximb.end_date_active       >= gd_process_date
      AND    xoha.schedule_arrival_date >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- 入力パラメータ.対象年月
      AND    xoha.schedule_arrival_date <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- 入力パラメータ.対象年月
      AND    xacv1.segment1              = NVL(gv_prod_class_code  ,xacv1.segment1)             -- 入力パラメータ.商品区分
      AND    xacv2.segment1              = NVL(gv_crowd_class_code ,xacv2.segment1)             -- 入力パラメータ.政策群コード
      AND NOT EXISTS ( SELECT '1'  AS dummy
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type        = cv_lkup_exc_order_type -- 入庫情報抽出対象外受注タイプ
                       AND    flv.enabled_flag       = cv_flag_y
                       AND    flv.language           = ct_lang
                       AND    flv.start_date_active <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date)
                                                    >= gd_process_date
                       AND    ottt.name              = flv.meaning
                     )
      GROUP BY TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)
             , xca.sale_base_code
             , iimb.item_no
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
             , otta.order_category_code
      ;
    -- レコード定義
    get_ship_order_comp_info_rec   get_ship_order_comp_info_cur%ROWTYPE;
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
    --  依頼済数(直送)取得
    -- ===================================
    -- カーソルOPEN
    OPEN get_ship_order_comp_info_cur;
    LOOP
      FETCH get_ship_order_comp_info_cur INTO get_ship_order_comp_info_rec;
      EXIT WHEN get_ship_order_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  帳票発行用ワークテーブル存在チェック
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_ship_order_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_ship_order_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_ship_order_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  帳票発行用ワークテーブル更新
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.ship_order_comp_qty  = xrfcl.ship_order_comp_qty
                                          + get_ship_order_comp_info_rec.ship_order_comp_qty
        WHERE  xrfcl.target_month         = get_ship_order_comp_info_rec.target_month
        AND    xrfcl.base_code            = get_ship_order_comp_info_rec.base_code
        AND    xrfcl.item_code            = get_ship_order_comp_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  帳票発行用ワークテーブル登録
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                                      -- 01：対象年月
            , process_date                                      -- 02：業務日付
            , prod_class_code                                   -- 03：商品区分
            , prod_class_name                                   -- 04：商品区分名
            , base_code                                         -- 05：拠点コード
            , base_name                                         -- 06：拠点名
            , forecast_type                                     -- 07：計画区分
            , forecast_type_name                                -- 08：計画区分名
            , crowd_class_code                                  -- 09：政策群コード
            , crowd_class_code3                                 -- 10：政策群コード(上3桁)
            , item_code                                         -- 11：品目コード
            , item_name                                         -- 12：品目名
            , forecast_qty                                      -- 13：引取計画数
            , stock_comp_qty                                    -- 14：入庫確認数（拠点入庫）
            , stock_order_comp_qty                              -- 15：依頼済数（拠点入庫）
            , ship_comp_qty                                     -- 16：売上計上済数（直送）
            , ship_order_comp_qty                               -- 17：依頼済数（直送）
            , created_by                                        -- 18：作成者
            , creation_date                                     -- 19：作成日
            , last_updated_by                                   -- 20：最終更新者
            , last_update_date                                  -- 21：最終更新日
            , last_update_login                                 -- 22：最終更新ログイン
            , request_id                                        -- 23：要求ID
            , program_application_id                            -- 24：コンカレント・プログラム・アプリケーションID
            , program_id                                        -- 25：コンカレント・プログラムID
            , program_update_date                               -- 26：プログラム更新日
            ) VALUES(
              gv_target_month                                   -- 01
            , gd_process_date                                   -- 02
            , get_ship_order_comp_info_rec.prod_class_code      -- 03
            , get_ship_order_comp_info_rec.prod_class_name      -- 04
            , get_ship_order_comp_info_rec.base_code            -- 05
            , iv_base_name                                      -- 06
            , gv_forecast_type                                  -- 07
            , gt_forecast_type_name                             -- 08
            , get_ship_order_comp_info_rec.crowd_class_code     -- 09
            , get_ship_order_comp_info_rec.crowd_class_code3    -- 10
            , get_ship_order_comp_info_rec.item_code            -- 11
            , get_ship_order_comp_info_rec.item_name            -- 12
            , cn_0                                              -- 13
            , cn_0                                              -- 14
            , cn_0                                              -- 15
            , cn_0                                              -- 16
            , get_ship_order_comp_info_rec.ship_order_comp_qty  -- 17
            , cn_created_by                                     -- 18
            , SYSDATE                                           -- 19
            , cn_last_updated_by                                -- 20
            , SYSDATE                                           -- 21
            , cn_last_update_login                              -- 22
            , cn_request_id                                     -- 23
            , cn_program_application_id                         -- 24
            , cn_program_id                                     -- 25
            , SYSDATE                                           -- 26
            );
            -- 対象件数カウント
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- トークン値を設定
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- 登録処理エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcop_00027    -- メッセージコード
                             , iv_token_name1  => cv_tkn_table          -- トークンコード1
                             , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- トークン値を設定
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- 更新処理エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcop_00028    -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => gv_tkn_vl1            -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_ship_order_comp_info_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルCLOSE
      IF (get_ship_order_comp_info_cur%ISOPEN) THEN
        CLOSE get_ship_order_comp_info_cur;
      END IF;
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
  END get_ship_order_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : svf_call
   * Description      : SVF起動(A-9)
   ***********************************************************************************/
  PROCEDURE svf_call(
     ov_errbuf   OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
   , ov_retcode  OUT VARCHAR2            --   リターン・コード             --# 固定 #
   , ov_errmsg   OUT VARCHAR2            --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_call'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_nodata_msg    VARCHAR2(5000); -- 0件メッセージ
    lv_file_name     VARCHAR2(5000); -- ファイル名
    lv_api_errmsg    VARCHAR2(5000); -- APIメッセージ用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --出力ファイル名編集
    lv_file_name  := cv_pkg_name                                || -- プログラムID
                     TO_CHAR(cd_creation_date ,cv_format_svf)   || -- 日付
                     TO_CHAR(cn_request_id)                     || -- 要求ID
                     cv_extension_pdf                              -- 拡張子(PDF)
                     ;
--
    -- SVF帳票共通関数(SVFコンカレントの起動）
    xxccp_svfcommon_pkg.submit_svf_request(
          ov_retcode       =>  lv_retcode              -- リターンコード
        , ov_errbuf        =>  lv_api_errmsg           -- エラーメッセージ
        , ov_errmsg        =>  lv_errmsg               -- ユーザー・エラーメッセージ
        , iv_conc_name     =>  cv_pkg_name             -- コンカレント名
        , iv_file_name     =>  lv_file_name            -- 出力ファイル名
        , iv_file_id       =>  cv_pkg_name             -- 帳票ID
        , iv_output_mode   =>  cv_output_mode          -- 出力区分
        , iv_frm_file      =>  cv_frm_file             -- フォーム様式ファイル名
        , iv_vrq_file      =>  cv_vrq_file             -- クエリー様式ファイル名
        , iv_org_id        =>  fnd_global.org_id       -- ORG_ID
        , iv_user_name     =>  cn_created_by           -- ログイン・ユーザ名
        , iv_resp_name     =>  fnd_global.resp_name    -- ログイン・ユーザの職責名
        , iv_doc_name      =>  NULL                    -- 文書名
        , iv_printer_name  =>  NULL                    -- プリンタ名
        , iv_request_id    =>  cn_request_id           -- 要求ID
        , iv_nodata_msg    =>  NULL                    -- データなしメッセージ
        , iv_svf_param1    =>  NULL                    -- svf可変パラメータ1
        , iv_svf_param2    =>  NULL                    -- svf可変パラメータ2
        , iv_svf_param3    =>  NULL                    -- svf可変パラメータ3
        , iv_svf_param4    =>  NULL                    -- svf可変パラメータ4
        , iv_svf_param5    =>  NULL                    -- svf可変パラメータ5
        , iv_svf_param6    =>  NULL                    -- svf可変パラメータ6
        , iv_svf_param7    =>  NULL                    -- svf可変パラメータ7
        , iv_svf_param8    =>  NULL                    -- svf可変パラメータ8
        , iv_svf_param9    =>  NULL                    -- svf可変パラメータ9
        , iv_svf_param10   =>  NULL                    -- svf可変パラメータ10
        , iv_svf_param11   =>  NULL                    -- svf可変パラメータ11
        , iv_svf_param12   =>  NULL                    -- svf可変パラメータ12
        , iv_svf_param13   =>  NULL                    -- svf可変パラメータ13
        , iv_svf_param14   =>  NULL                    -- svf可変パラメータ14
        , iv_svf_param15   =>  NULL                    -- svf可変パラメータ15
        );
--
    -- エラーハンドリング
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_application
                   ,iv_name         => cv_msg_xxcop_00016
                   ,iv_token_name1  => cv_tkn_prg_name
                   ,iv_token_value1 => cv_api_err_msg_tkn_val
                   ,iv_token_name2  => cv_tkn_errmsg
                   ,iv_token_value2 => lv_api_errmsg
                   );
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
  END svf_call;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_data
   * Description      : 帳票発行用ワークテーブル削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE del_rep_work_data(
     ov_errbuf   OUT VARCHAR2            --   エラー・メッセージ           --# 固定 #
   , ov_retcode  OUT VARCHAR2            --   リターン・コード             --# 固定 #
   , ov_errmsg   OUT VARCHAR2            --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_data'; -- プログラム名
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
    BEGIN
      -- 帳票発行用ワークテーブルの削除
      DELETE
      FROM   xxcop_rep_forecast_comp_list   xrfcl
      WHERE  xrfcl.request_id = cn_request_id
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- トークン値を設定
        gv_tkn_vl1  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_10072);
        -- 削除エラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcop_00042  -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table        -- トークンコード1
                       ,iv_token_value1 => gv_tkn_vl1          -- トークン値1
                       );
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
  END del_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf            OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode           OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg            OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
    , iv_target_month      IN  VARCHAR2  -- 1.対象年月
    , iv_forecast_type     IN  VARCHAR2  -- 2.計画区分
    , iv_prod_class_code   IN  VARCHAR2  -- 3.商品区分
    , iv_base_code         IN  VARCHAR2  -- 4.拠点
    , iv_crowd_class_code  IN  VARCHAR2  -- 5.政策群コード
    , iv_item_code         IN  VARCHAR2  -- 6.品目コード
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
    lv_errbuf            VARCHAR2(5000)   DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode           VARCHAR2(1)      DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg            VARCHAR2(5000)   DEFAULT NULL;              -- ユーザー・エラー・メッセージ
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
    -- グローバル変数の初期化
    gn_target_cnt        := 0;
    gn_normal_cnt        := 0;
    gn_error_cnt         := 0;
--
    -- グローバル変数に入力パラメータを設定
    gv_target_month      := iv_target_month;      -- 対象年月
    gv_forecast_type     := iv_forecast_type;     -- 計画区分
    gv_prod_class_code   := iv_prod_class_code;   -- 商品区分
    gv_base_code         := iv_base_code;         -- 拠点
    gv_crowd_class_code  := iv_crowd_class_code;  -- 政策群コード
    gv_item_code         := iv_item_code;         -- 品目コード
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
        ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 対象拠点取得（配下拠点）（A-2）
    -- ===============================================
    get_target_base_code(
        ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
    );
    -- 終了パラメータ判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    <<get_target_base_loop>>
    FOR i IN 1..g_target_base_tbl.COUNT LOOP
--
      -- ===============================================
      -- 引取計画数取得処理（A-3）
      -- ===============================================
      get_forecast_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- 拠点コード
      , iv_base_name => g_target_base_tbl(i).base_name  -- 拠点名
      , ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 入庫確認数(拠点入庫)取得処理(A-4)
      -- ===============================================
      get_stock_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- 拠点コード
      , iv_base_name => g_target_base_tbl(i).base_name  -- 拠点名
      , ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 依頼済数(拠点入庫－拠点未入庫)取得処理(A-5)
      -- ===============================================
      get_stock_order_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- 拠点コード
      , iv_base_name => g_target_base_tbl(i).base_name  -- 拠点名
      , ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 依頼済数(拠点入庫－工場未出荷)取得処理(A-6)
      -- ===============================================
      get_stock_fact_ship_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- 拠点コード
      , iv_base_name => g_target_base_tbl(i).base_name  -- 拠点名
      , ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 売上計上済数取得処理(A-7)
      -- ===============================================
      get_ship_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- 拠点コード
      , iv_base_name => g_target_base_tbl(i).base_name  -- 拠点名
      , ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
----
      -- ===============================================
      -- 依頼済数(直送)取得処理(A-8)
      -- ===============================================
      get_ship_order_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- 拠点コード
      , iv_base_name => g_target_base_tbl(i).base_name  -- 拠点名
      , ov_errbuf    => lv_errbuf     -- エラー・メッセージ             --# 固定 #
      , ov_retcode   => lv_retcode    -- リターン・コード               --# 固定 #
      , ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ   --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP get_target_base_loop;
--
    -- SVF起動前にコミットを行なう
    COMMIT;
--
    -- ===============================================
    -- SVF起動(A-9)
    -- ===============================================
    svf_call(
       lv_errbuf                                     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                                    -- リターン・コード             --# 固定 #
      ,lv_errmsg                                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode <> cv_status_normal) THEN
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
      errbuf               OUT VARCHAR2  -- エラー・メッセージ #固定#
    , retcode              OUT VARCHAR2  -- リターン・コード   #固定#
    , iv_target_month      IN  VARCHAR2  -- 1.対象年月
    , iv_forecast_type     IN  VARCHAR2  -- 2.計画区分
    , iv_prod_class_code   IN  VARCHAR2  -- 3.商品区分
    , iv_base_code         IN  VARCHAR2  -- 4.拠点
    , iv_crowd_class_code  IN  VARCHAR2  -- 5.政策群コード
    , iv_item_code         IN  VARCHAR2  -- 6.品目コード
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    -- アプリケーション短縮名
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    -- メッセージ
    cv_target_rec_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- トークン
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
        ov_errbuf           => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      , ov_retcode          => lv_retcode         -- リターン・コード             --# 固定 #
      , ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      , iv_target_month     => iv_target_month    -- 1.対象年月
      , iv_forecast_type    => iv_forecast_type   -- 2.計画区分
      , iv_prod_class_code  => iv_prod_class_code -- 3.商品区分
      , iv_base_code        => iv_base_code       -- 4.拠点
      , iv_crowd_class_code => iv_crowd_class_code-- 5.政策群コード
      , iv_item_code        => iv_item_code       -- 6.品目コード
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- 帳票発行用ワークテーブル削除処理(A-10)
    -- ===============================================
    del_rep_work_data(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
    -- 帳票発行用ワークテーブル削除後COMMIT
    COMMIT;
    --
    -- エラー件数が存在する場合
    IF ( gn_error_cnt > 0 ) THEN
      -- エラー時の件数設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      -- 終了ステータスをエラーにする
      lv_retcode := cv_status_error;
    ELSE
      -- 正常件数設定
      gn_normal_cnt := gn_target_cnt;
      -- 終了ステータスを正常にする
      lv_retcode := cv_status_normal;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOP004A10R;
/
