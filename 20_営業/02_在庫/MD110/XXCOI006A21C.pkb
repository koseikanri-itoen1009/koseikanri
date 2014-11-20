CREATE OR REPLACE PACKAGE BODY XXCOI006A21C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A21C(body)
 * Description      : 棚卸結果作成
 * MD.050           : HHT棚卸結果データ取込 <MD050_COI_A21>
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(B-1)
 *  chk_if_data            IFデータチェック(B-3)
 *  ins_hht_err            HHT情報取込エラー処理(B-4)
 *  ins_inv_control        棚卸管理出力(B-5)
 *  ins_hht_result         HHT棚卸結果出力(B-6)
 *  del_inv_result_file    棚卸結果ファイルIF削除(B-8)
 *  chk_file_data          ファイルデータチェック(B-11)
 *  ins_result_file        棚卸結果ファイルIF出力(B-12)
 *  get_uplode_data        ファイルアップロードI/Fデータ取得(B-10)
 *  del_uplode_data        ファイルアップロードI/Fデータ削除(B-13)
 *  submain                メイン処理プロシージャ
 *                         棚卸結果ファイルIF抽出(B-2)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(B-9、B-14)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   N.Abe            新規作成
 *  2009/02/18    1.1   N.Abe            [障害COI_014] ログ出力不備対応
 *  2009/02/18    1.2   N.Abe            [障害COI_018] 良品区分値の不備対応
 *  2009/04/21    1.3   H.Sasaki         [T1_0654]取込データの前後スペース削除
 *  2009/05/07    1.4   T.Nakamura       [T1_0556]品目存在チェックエラー処理を追加
 *  2009/06/02    1.5   H.Sasaki         [T1_1300]棚卸場所の編集処理を追加
 *  2009/07/14    1.6   H.Sasaki         [0000461]棚卸しデータ取込順の採番方法修正
 *  2009/11/18    1.7   N.Abe            [E_T4_00199]ケース数、入数、本数がNULLの場合、0に変換
 *  2009/11/29    1.8   N.Abe            [E_本稼動_00134]棚卸しデータ取込順の採番方法修正
 *  2009/12/01    1.9   H.Sasaki         [E_本稼動_00245]データソート順の変更
 *  2010/03/23    1.10  Y.Goto           [E_本稼動_01943]拠点の有効チェックを追加
 *  2010/05/12    1.11  N.Abe            [E_本稼動_02076]棚卸しデータ取込順の採番方法修正
 *  2011/04/27    1.12  N.Horigome       [E_本稼動_06884]一時表取込エラー時のメッセージ出力追加
 *  2011/10/18    1.13  K.Nakamura       [E_T4_00223]ケース数の半角チェックを共通関数を使用しないよう修正
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
  process_date_expt        EXCEPTION;     -- 業務日付取得エラー
  org_code_expt            EXCEPTION;     -- 在庫組織コード取得エラー
  org_id_expt              EXCEPTION;     -- 在庫組織ID取得エラー
  lock_expt                EXCEPTION;     -- ロック取得エラー
  inventory_kbn_expt       EXCEPTION;     -- 棚卸区分範囲エラー
  warehouse_kbn_expt       EXCEPTION;     -- 倉庫区分範囲エラー
  quality_kbn_expt         EXCEPTION;     -- 良品区分範囲エラー
  inventory_date_expt      EXCEPTION;     -- 棚卸日妥当性エラー
  inventory_status_expt    EXCEPTION;     -- 棚卸ステータスエラー
  get_subinventory_expt    EXCEPTION;     -- 保管場所マスタ取得エラー
  get_result_col_expt      EXCEPTION;     -- 棚卸結果ファイルIF項目取得エラー
  required_expt            EXCEPTION;     -- 必須チェックエラー
  harf_number_expt         EXCEPTION;     -- 半角数字エラー
  hht_name_expt            EXCEPTION;     -- HHTエラー用棚卸データ名取得エラー
  chk_item_expt            EXCEPTION;     -- 品目ステータス有効チェックエラー
  chk_sales_item_expt      EXCEPTION;     -- 品目売上対象区分有効チェックエラー
  blob_expt                EXCEPTION;     -- BLOBデータ変換エラー
  file_expt                EXCEPTION;     -- ファイルエラー
  pre_month_expt           EXCEPTION;     -- 前月棚卸データ取得エラー
  date_expt                EXCEPTION;     -- 日付変換エラー
  subinv_div_expt          EXCEPTION;     -- 保管場所棚卸対象外エラー
-- == 2009/05/07 V1.4 Added START ==================================================================
  chk_item_exist_expt      EXCEPTION;     -- 品目存在チェックエラー
-- == 2009/05/07 V1.4 Added END   ==================================================================
-- == 2010/03/23 V1.10 Added START ===============================================================
  get_aff_dept_date_expt   EXCEPTION;     -- AFF部門取得エラー
  aff_dept_inactive_expt   EXCEPTION;     -- AFF部門無効エラー
-- == 2010/03/23 V1.10 Added END   ===============================================================
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100)  := 'XXCOI006A21C'; -- パッケージ名
--
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)   := 'XXCOI';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;                                     -- 業務処理日付
  gv_hht_err_data_name  VARCHAR2(20);                             -- HHTエラー用棚卸データ名
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id          IN  NUMBER,       --   1.ファイルID
    iv_format_pattern   IN  VARCHAR2,     --   2.フォーマットパターン
    on_organization_id  OUT NUMBER,       --   3.在庫組織ID
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'init';             -- プログラム名
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
    --メッセージ番号
    cv_xxcoi1_msg_10232   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10232';
    cv_xxcoi1_msg_00011   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00011';
    cv_xxcoi1_msg_00005   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00005';
    cv_xxcoi1_msg_00006   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00006';
    cv_xxcoi1_msg_10289   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10289';
    --トークン
    cv_tkn_file_id        CONSTANT  VARCHAR2(7)   := 'FILE_ID';
    cv_tkn_format_ptn     CONSTANT  VARCHAR2(10)  := 'FORMAT_PTN';
    cv_tkn_pro            CONSTANT  VARCHAR2(7)   := 'PRO_TOK';
    cv_tkn_org_code       CONSTANT  VARCHAR2(12)  := 'ORG_CODE_TOK';
    --プロファイル
    cv_prf_org_code       CONSTANT  VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';
    cv_prf_err_name       CONSTANT  VARCHAR2(28)  := 'XXCOI1_HHT_ERR_DATA_NAME_INV';
--
    -- *** ローカル変数 ***
    lv_organization_code    VARCHAR2(4);    --在庫組織コード
    ln_organization_id      NUMBER;         --在庫組織ID
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --====================
    --1.入力パラメータ出力
    --====================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_10232
                    ,iv_token_name1  => cv_tkn_file_id
                    ,iv_token_value1 => in_file_id
                    ,iv_token_name2  => cv_tkn_format_ptn
                    ,iv_token_value2 => iv_format_pattern
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --===============
    --2.業務日付取得
    --===============
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      RAISE process_date_expt;
    END IF;
--
    --====================================
    --3.プロファイルから在庫組織コードを取得
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
--
    IF (lv_organization_code IS NULL) THEN
      RAISE org_code_expt;
    END IF;
--
    --====================================
    --4.在庫組織コードから在庫組織IDを取得
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
--
    IF (ln_organization_id IS NULL) THEN
      RAISE org_id_expt;
    END IF;
--
    --==================================================
    --追加.プロファイルからHHTエラー用棚卸データ名を取得
    --==================================================
    gv_hht_err_data_name  := fnd_profile.value(cv_prf_err_name);
--
    IF (gv_hht_err_data_name IS NULL) THEN
      RAISE hht_name_expt;
    END IF;
--
    on_organization_id := ln_organization_id;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** 業務日付取得エラー ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00011
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 在庫組織コード取得エラー ***
    WHEN org_code_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00005
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_org_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 在庫組織ID取得エラー ***
    WHEN org_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00006
                 ,iv_token_name1  => cv_tkn_org_code
                 ,iv_token_value1 => lv_organization_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** HTエラー用棚卸データ名取得エラー ***
    WHEN hht_name_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10289
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_err_name
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
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
   * Procedure Name   : chk_if_data
   * Description      : IFデータチェック(B-3)
   ***********************************************************************************/
  PROCEDURE chk_if_data(
    it_base_code          IN  xxcoi_in_inv_result_file_if.base_code%TYPE,         -- 1.拠点コード
    it_inventory_kbn      IN  xxcoi_in_inv_result_file_if.inventory_kbn%TYPE,     -- 2.棚卸区分
    it_inventory_date     IN  xxcoi_in_inv_result_file_if.inventory_date%TYPE,    -- 3.棚卸日
    it_warehouse_kbn      IN  xxcoi_in_inv_result_file_if.warehouse_kbn%TYPE,     -- 4.倉庫区分
    it_inventory_place    IN  xxcoi_in_inv_result_file_if.inventory_place%TYPE,   -- 5.棚卸場所
    it_item_code          IN  xxcoi_in_inv_result_file_if.item_code%TYPE,         -- 6.品目コード
    it_quality_goods_kbn  IN  xxcoi_in_inv_result_file_if.quality_goods_kbn%TYPE, -- 7.良品区分  
    iv_inventory_status   IN  VARCHAR2,                                           -- 8.棚卸ステータス
    in_organization_id    IN  NUMBER,                                             -- 9.在庫組織ID
-- == 2010/03/23 V1.10 Added START ===============================================================
    it_slip_no            IN  xxcoi_in_inv_result_file_if.slip_no%TYPE,           --12.伝票No
-- == 2010/03/23 V1.10 Added END   ===============================================================
    ov_subinventory_code  OUT VARCHAR2,                                           --10.保管場所
    ov_fiscal_date        OUT VARCHAR2,                                           --11.在庫会計期間
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ               --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード                 --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ     --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_if_data'; -- プログラム名
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
    cv_ym                 CONSTANT VARCHAR2(7)  := 'YYYY/MM';     --年月変換用
    cv_ym2                CONSTANT VARCHAR2(6)  := 'YYYYMM';      --年月変換用(区切りなし)
    cv_slash              CONSTANT VARCHAR2(6)  := '/';           --区切り文字(年月変換用)
    --メッセージ
    cv_xxcoi1_msg_10133   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10133';  --棚卸区分範囲エラー
    cv_xxcoi1_msg_10134   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10134';  --倉庫区分範囲エラー
    cv_xxcoi1_msg_10135   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10135';  --良品区分範囲エラー
    cv_xxcoi1_msg_10291   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10291';  --品目ステータス有効エラー
    cv_xxcoi1_msg_10229   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10229';  --品目売上対象区分エラー
    cv_xxcoi1_msg_10136   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10136';  --棚卸日妥当性エラー
    cv_xxcoi1_msg_10137   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10137';  --棚卸ステータスエラー
    cv_xxcoi1_msg_10129   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10129';  --保管場所マスタ取得エラー
    cv_xxcoi1_msg_10299   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10299';  --前月棚卸データ取得エラー
    cv_xxcoi1_msg_10356   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10356';  --保管場所棚卸対象外エラー
-- == 2009/05/07 V1.4 Added START ==================================================================
    cv_xxcoi1_msg_10227   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10227';  -- 品目存在チェックエラー
-- == 2009/05/07 V1.4 Added END   ==================================================================
-- == 2010/03/23 V1.10 Added START ===============================================================
    cv_xxcoi1_msg_10417   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10417';  -- AFF部門取得エラー
    cv_xxcoi1_msg_10418   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10418';  -- AFF部門無効エラー
-- == 2010/03/23 V1.10 Added END   ===============================================================
    --トークン
    cv_tkn_item_code      CONSTANT VARCHAR2(9)  := 'ITEM_CODE';
    cv_tkn_ivt_type       CONSTANT VARCHAR2(8)  := 'IVT_TYPE';
    cv_tkn_whse_type      CONSTANT VARCHAR2(9)  := 'WHSE_TYPE';
    cv_tkn_qlty_type      CONSTANT VARCHAR2(9)  := 'QLTY_TYPE';
    cv_tkn_status         CONSTANT VARCHAR2(6)  := 'STATUS';
-- == 2010/03/23 V1.10 Added START ===============================================================
    cv_tkn_base_code      CONSTANT VARCHAR2(9)  := 'BASE_CODE';
    cv_tkn_slip_num       CONSTANT VARCHAR2(17) := 'SLIP_NUM';
-- == 2010/03/23 V1.10 Added END   ===============================================================
    --クイックコード
    cv_lk_inv_dv          CONSTANT VARCHAR2(20) := 'XXCOI1_INVENTORY_KBN';          --棚卸区分
    cv_lk_ware_dv         CONSTANT VARCHAR2(25) := 'XXCOI1_WAREHOUSE_DIVISION';     --倉庫区分
    cv_lk_qual_good_dv    CONSTANT VARCHAR2(29) := 'XXCOI1_QUALITY_GOODS_DIVISION'; --HHT用良品区分
    cv_lk_inv_stat        CONSTANT VARCHAR2(23) := 'XXCOI1_INVENTORY_STATUS';       --棚卸ステータス
    --コード＆フラグ
    cv_inactive           CONSTANT VARCHAR2(8)  := 'Inactive';
    cv_n                  CONSTANT VARCHAR2(1)  := 'N';
    cv_s                  CONSTANT VARCHAR2(1)  := 'S';
    cv_y                  CONSTANT VARCHAR2(1)  := 'Y';
    cv_1                  CONSTANT VARCHAR2(1)  := '1';
    cv_2                  CONSTANT VARCHAR2(1)  := '2';
    cv_3                  CONSTANT VARCHAR2(1)  := '3';
    cv_4                  CONSTANT VARCHAR2(1)  := '4';
    cv_9                  CONSTANT VARCHAR2(1)  := '9';
    cv_90                 CONSTANT VARCHAR2(2)  := '90';            --レコード種別
--
    -- *** ローカル変数 ***
    lt_lookup_meaning     fnd_lookup_values.meaning%TYPE;           --区分値妥当性チェック用
    lt_inv_status         xxcoi_inv_control.inventory_status%TYPE;  --棚卸ステータス
-- == 2010/03/23 V1.10 Added START ===============================================================
    lt_start_date_active  fnd_flex_values.start_date_active%TYPE;   -- AFF部門適用開始日
-- == 2010/03/23 V1.10 Added END   ===============================================================
--
    --品目情報取得用
    lv_item_status        VARCHAR2(5);                              --品目ステータス
    lv_cust_order_flg     VARCHAR2(5);                              --顧客受注可能フラグ
    lv_transaction_enable VARCHAR2(5);                              --取引可能
    lv_stock_enabled_flg  VARCHAR2(5);                              --在庫保有可能フラグ
    lv_return_enable      VARCHAR2(5);                              --返品可能
    lv_sales_class        VARCHAR2(5);                              --売上対象区分
    lv_primary_unit       VARCHAR2(5);                              --基準単位
--
    --倉庫保管場所変換用
    lt_subinv_code        mtl_secondary_inventories.secondary_inventory_name%TYPE;  --保管場所コード
    lt_base_code          mtl_secondary_inventories.attribute7%TYPE;                --拠点コード
    lt_subinv_div         mtl_secondary_inventories.attribute5%TYPE;                --棚卸区分
--
    lt_business_low_type  xxcmm_cust_accounts.business_low_type%TYPE;               --業態小分類
    -- *** ローカル・カーソル ***
    CURSOR get_period_date_cur
    IS
      SELECT   TO_CHAR(gp.period_start_date, cv_ym) period_date --開始日
      FROM     org_acct_periods gp                              --在庫会計期間テーブル
      WHERE    gp.organization_id = in_organization_id
      AND      gp.open_flag       = cv_y                        --オープンフラグ'Y'
      ORDER BY gp.period_start_date
      ;
--
    -- *** ローカル・レコード ***
    get_period_date_rec get_period_date_cur%ROWTYPE;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --=============================
    --1-1.棚卸区分の妥当性チェック
    --=============================
    lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                         cv_lk_inv_dv
                        ,it_inventory_kbn
                      );
--
    --棚卸区分の内容が取得できなかった場合
    IF (lt_lookup_meaning IS NULL) THEN
      --棚卸区分範囲エラー
      RAISE inventory_kbn_expt;
    END IF;
--
    --=============================
    --1-2.倉庫区分の妥当性チェック
    --=============================
    lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                        cv_lk_ware_dv
                       ,it_warehouse_kbn
                      );
--
    --倉庫区分の内容が取得できなかった場合
    IF (lt_lookup_meaning IS NULL) THEN
      --倉庫区分範囲エラー
      RAISE warehouse_kbn_expt;
    END IF;
--
    --============================
    --1-3良品区分の妥当性チェック
    --============================
    IF NOT ((it_inventory_kbn = cv_1) 
       AND (it_quality_goods_kbn IS NULL))
    THEN
      lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                          cv_lk_qual_good_dv
                         ,it_quality_goods_kbn
                        );
--
      --良品区分の内容が取得できなかった場合
      IF (lt_lookup_meaning IS NULL) THEN
        --良品区分範囲エラー
        RAISE quality_kbn_expt;
      END IF;
    END IF;
--
    --===========================
    --2-1.品目コードのマスタチェック
    --===========================
    xxcoi_common_pkg.get_item_info(
          iv_item_code            =>  it_item_code          -- 1 .品目コード
         ,in_org_id               =>  in_organization_id    -- 2 .在庫組織ID
         ,ov_item_status          =>  lv_item_status        -- 3 .品目ステータス
         ,ov_cust_order_flg       =>  lv_cust_order_flg     -- 4 .顧客受注可能フラグ
         ,ov_transaction_enable   =>  lv_transaction_enable -- 5 .取引可能
         ,ov_stock_enabled_flg    =>  lv_stock_enabled_flg  -- 6 .在庫保有可能フラグ
         ,ov_return_enable        =>  lv_return_enable      -- 7 .返品可能
         ,ov_sales_class          =>  lv_sales_class        -- 8 .売上対象区分
         ,ov_primary_unit         =>  lv_primary_unit       -- 9 .基準単位
         ,ov_errbuf               =>  lv_errbuf             -- 10.エラーメッセージ
         ,ov_retcode              =>  lv_retcode            -- 11.リターン・コード
         ,ov_errmsg               =>  lv_errmsg             -- 12.ユーザー・エラーメッセージ
        );
    IF (lv_retcode <> cv_status_normal) THEN
-- == 2009/05/07 V1.4 Modified START ===============================================================
--      RAISE global_api_others_expt;
      RAISE chk_item_exist_expt;
-- == 2009/05/07 V1.4 Modified END   ===============================================================
    END IF;
--
    --===========================
    --2-2.品目ステータスチェック
    --===========================
    --品目ステータスが'Inactive'又は
    --顧客受注可能フラグ、取引可能フラグ、在庫保有可能フラグ、返品可能フラグ
    --いずれかが無効('N')に設定されていた場合
    IF ((lv_item_status           = cv_inactive)
      OR  (lv_cust_order_flg     = cv_n)
      OR  (lv_transaction_enable = cv_n)
      OR  (lv_stock_enabled_flg  = cv_n)
      OR  (lv_return_enable      = cv_n))
    THEN
      --品目ステータス有効チェックエラー
      RAISE chk_item_expt;
    END IF;
--
    --=============================
    --2-3.品目売上対象区分チェック
    --=============================
    --NULLの場合もエラーとする。
    IF (NVL(lv_sales_class, cv_2) <> cv_1) THEN
      --品目売上対象区分有効チェックエラー
      RAISE chk_sales_item_expt;
    END IF;
--
    --============================
    --3.オープン在庫会計期間情報
    --============================
    OPEN get_period_date_cur;
    FETCH get_period_date_cur INTO get_period_date_rec;
    CLOSE get_period_date_cur;
--
    --===========================
    --3-1.棚卸区分【月末】の場合
    --===========================
    IF (it_inventory_kbn = cv_2) THEN
      --取得した会計年月の年月とIFの棚卸日の年月を比較
      IF (get_period_date_rec.period_date <> TO_CHAR(it_inventory_date, cv_ym)) THEN
        --棚卸日妥当性エラー
        RAISE inventory_date_expt;
      END IF;
--
    --==========================
    --3-2.棚卸区分【月中】の場合
    --==========================
    ELSE
      --IFの棚卸年月と業務処理日付の年月が一致
      IF (TO_CHAR(it_inventory_date, cv_ym) = TO_CHAR(gd_process_date, cv_ym)) THEN
        --棚卸管理からIF.棚卸日の前月に一致する棚卸ステータスを取得する
        BEGIN
          SELECT xic.inventory_status
          INTO   lt_inv_status
          FROM   xxcoi_inv_control xic
          WHERE  xic.base_code            = it_base_code        --拠点コード
          AND    xic.inventory_place      = it_inventory_place  --棚卸場所
          AND    xic.inventory_kbn        = cv_2                --棚卸区分 = '2'(月末)
          AND    xic.inventory_year_month = TO_CHAR(ADD_MONTHS(it_inventory_date, -1), cv_ym2)
                                                                --棚卸年月 = 棚卸日 - 1ヶ月
          AND    ROWNUM = 1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --データが存在しない場合はステータスチェックを無視する
            lt_inv_status := cv_9;
        END;
        --棚卸ステータスが確定かをチェックする。
        IF (lt_inv_status <> cv_9) THEN
          --前月棚卸データ取得エラー
          RAISE pre_month_expt;
        END IF;
      --IFの棚卸年月と業務処理日付の年月が一致しない
      ELSE
        --棚卸日妥当性エラー
        RAISE inventory_date_expt;
      END IF;
    END IF;
--
    --==============================
    --4-1.倉庫区分 = '1'(倉庫)の場合
    --==============================
    IF (it_warehouse_kbn = cv_1) THEN 
      --倉庫保管場所コード変換(共通関数)
      xxcoi_common_pkg.convert_whouse_subinv_code(
            iv_base_code        =>  it_base_code        -- 1.拠点コード
           ,iv_warehouse_code   =>  it_inventory_place  -- 2.倉庫コード
           ,in_organization_id  =>  in_organization_id  -- 3.在庫組織ID
           ,ov_subinv_code      =>  lt_subinv_code      -- 4.保管場所コード
           ,ov_base_code        =>  lt_base_code        -- 5.拠点コード
           ,ov_subinv_div       =>  lt_subinv_div       -- 6.保管場所区分
           ,ov_errbuf           =>  lv_errbuf           -- 7.エラーメッセージ
           ,ov_retcode          =>  lv_retcode          -- 8.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           =>  lv_errmsg           -- 9.ユーザー・エラーメッセージ
          );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE get_subinventory_expt;
      END IF;
      --保管場所対象外エラー
      IF (lt_subinv_div = cv_9) THEN
        RAISE subinv_div_expt;
      END IF;
--
    --================================
    --4-2.倉庫区分 = '2'(営業員)の場合
    --================================
    ELSIF (it_warehouse_kbn = cv_2) THEN
      --営業者保管場所コード変換(共通関数)
      xxcoi_common_pkg.convert_emp_subinv_code(
            iv_base_code        =>  it_base_code        -- 1.拠点コード
           ,iv_employee_number  =>  it_inventory_place  -- 2.従業員コード
           ,id_transaction_date =>  it_inventory_date   -- 3.伝票日付
           ,in_organization_id  =>  in_organization_id  -- 4.在庫組織ID
           ,ov_subinv_code      =>  lt_subinv_code      -- 5.保管場所コード
           ,ov_base_code        =>  lt_base_code        -- 6.拠点コード
           ,ov_subinv_div       =>  lt_subinv_div       -- 7.保管場所区分
           ,ov_errbuf           =>  lv_errbuf           -- 8.エラーメッセージ
           ,ov_retcode          =>  lv_retcode          -- 9.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg           =>  lv_errmsg           --10.ユーザー・エラーメッセージ
          );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE get_subinventory_expt;
      END IF;
      --保管場所対象外エラー
      IF (lt_subinv_div = cv_9) THEN
        RAISE subinv_div_expt;
      END IF;
--
    --=========================================
    --4-3.倉庫区分 = 3(預け先)、4(専門店)の場合
    --=========================================
    ELSIF ((it_warehouse_kbn = cv_3)
      OR  (it_warehouse_kbn = cv_4))
    THEN
      --預け先保管場所コード変換(共通関数)
      xxcoi_common_pkg.convert_cust_subinv_code(
            iv_base_code          =>  it_base_code          -- 1.拠点コード
           ,iv_cust_code          =>  it_inventory_place    -- 2.顧客コード
           ,id_transaction_date   =>  it_inventory_date     -- 3.伝票日付
           ,in_organization_id    =>  in_organization_id    -- 4.在庫組織ID
           ,iv_record_type        =>  cv_90                 -- 5.レコード種別
           ,iv_hht_form_flag      =>  cv_n                  -- 6.HHT取引入力画面フラグ
           ,ov_subinv_code        =>  lt_subinv_code        -- 7.保管場所コード
           ,ov_base_code          =>  lt_base_code          -- 8.拠点コード
           ,ov_subinv_div         =>  lt_subinv_div         -- 9.保管場所区分
           ,ov_business_low_type  =>  lt_business_low_type  --10.業態小分類
           ,ov_errbuf             =>  lv_errbuf             --11.エラーメッセージ
           ,ov_retcode            =>  lv_retcode            --12.リターン・コード(1:正常、2:エラー)
           ,ov_errmsg             =>  lv_errmsg             --13.ユーザー・エラーメッセージ
          );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE get_subinventory_expt;
      END IF;
      --保管場所対象外エラー
      IF (lt_subinv_div = cv_9) THEN
        RAISE subinv_div_expt;
      END IF;
--
    END IF;
--
    --======================================
    --5.以下の条件に一致した場合エラーとなる
    --======================================
    --B-2で棚卸管理のデータ(棚卸ステータス)が取得できない場合はチェックしない
    IF  ((iv_inventory_status IS NOT NULL)              --棚卸ステータスがNULLではない
      AND (SUBSTRB(lt_subinv_code, 1, 1) <> cv_s)       --保管場所コード先頭1桁が'S'
      AND (it_inventory_kbn     = cv_2)                 --棚卸区分='2'(月末)
      AND ((iv_inventory_status = cv_2)                 --棚卸ステータス='2'(受払作成済)
        OR (iv_inventory_status = cv_3)                 --棚卸ステータス='3'(消化計算済)
        OR (iv_inventory_status = cv_9)))               --棚卸ステータス='9'(確定)
    THEN
      lt_lookup_meaning := xxcoi_common_pkg.get_meaning(
                          cv_lk_inv_stat
                         ,iv_inventory_status
                        );
      --棚卸ステータスエラー
      RAISE inventory_status_expt;
    END IF;
--
-- == 2010/03/23 V1.10 Added START ===============================================================
    --======================================
    --6.拠点の有効チェック
    --======================================
    xxcoi_common_pkg.get_subinv_aff_active_date(
        in_organization_id     => in_organization_id                                -- 在庫組織ID
      , iv_subinv_code         => lt_subinv_code                                    -- 保管場所コード
      , od_start_date_active   => lt_start_date_active                              -- 適用開始日
      , ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
    );
    -- 適用開始日の取得に失敗した場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE get_aff_dept_date_expt;
    END IF;
    -- 棚卸日がAFF部門適用開始日以前の場合
    IF ( it_inventory_date < NVL( lt_start_date_active, it_inventory_date ) ) THEN
      RAISE aff_dept_inactive_expt;
    END IF;
--
-- == 2010/03/23 V1.10 Added END   ===============================================================
    --在庫会計期間を戻り値に設定
    ov_fiscal_date := REPLACE(get_period_date_rec.period_date, cv_slash);
    --保管場所を戻り値に設定
    ov_subinventory_code := lt_subinv_code;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** 棚卸区分範囲エラー ***
    WHEN inventory_kbn_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10133
                 ,iv_token_name1  => cv_tkn_ivt_type
                 ,iv_token_value1 => it_inventory_kbn
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 倉庫区分範囲エラー ***
    WHEN warehouse_kbn_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10134
                 ,iv_token_name1  => cv_tkn_whse_type
                 ,iv_token_value1 => it_warehouse_kbn
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 良品区分範囲エラー ***
    WHEN quality_kbn_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10135
                 ,iv_token_name1  => cv_tkn_qlty_type
                 ,iv_token_value1 => it_quality_goods_kbn
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
-- == 2009/05/07 V1.4 Added START ==================================================================
    --*** 品目存在チェックエラー ***
    WHEN chk_item_exist_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10227
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => it_item_code
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
-- == 2009/05/07 V1.4 Added END   ==================================================================
    --*** 品目ステータス有効チェックエラー ***
    WHEN chk_item_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10291
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => it_item_code
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 品目売上対象区分有効チェックエラー ***
    WHEN chk_sales_item_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10229
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => it_item_code
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 棚卸日妥当性エラー ***
    WHEN inventory_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10136
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 棚卸ステータスエラー ***
    WHEN inventory_status_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10137
                 ,iv_token_name1  => cv_tkn_status
                 ,iv_token_value1 => lt_lookup_meaning
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 保管場所マスタ取得エラー ***
    WHEN get_subinventory_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10129
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 前月棚卸データ取得エラー ***
    WHEN pre_month_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10299
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 保管場所棚卸対象外エラー ***
    WHEN subinv_div_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10356
                );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
-- == 2010/03/23 V1.10 Added START ===============================================================
    --*** AFF部門取得エラー ***
    WHEN get_aff_dept_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                     , iv_name         => cv_xxcoi1_msg_10417
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => lt_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => it_slip_no
                   );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** AFF部門無効エラー ***
    WHEN aff_dept_inactive_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                     , iv_name         => cv_xxcoi1_msg_10418
                     , iv_token_name1  => cv_tkn_base_code
                     , iv_token_value1 => lt_base_code
                     , iv_token_name2  => cv_tkn_slip_num
                     , iv_token_value2 => it_slip_no
                   );
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;                     --# 任意 #
--
-- == 2010/03/23 V1.10 Added END   ===============================================================
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
  END chk_if_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_control
   * Description      : 棚卸管理出力(B-5)
   ***********************************************************************************/
  PROCEDURE ins_inv_control(
    it_inventory_seq      IN  xxcoi_inv_control.inventory_seq%TYPE,                     -- 1.棚卸SEQ
    it_inventory_kbn      IN  xxcoi_in_inv_result_file_if.inventory_kbn%TYPE,           -- 2.棚卸区分
    it_base_code          IN  xxcoi_in_inv_result_file_if.base_code%TYPE,               -- 3.拠点コード
    it_warehouse_kbn      IN  xxcoi_in_inv_result_file_if.warehouse_kbn%TYPE,           -- 4.倉庫区分
    it_inventory_place    IN  xxcoi_in_inv_result_file_if.inventory_place%TYPE,         -- 5.棚卸場所
    it_inventory_date     IN  xxcoi_in_inv_result_file_if.inventory_date%TYPE,          -- 6.棚卸日
    it_subinventory_code  IN  mtl_secondary_inventories.secondary_inventory_name%TYPE,  -- 7.保管場所
    iv_fiscal_date        IN  VARCHAR2,                                                 -- 8.会計期間
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ             --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード               --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_control'; -- プログラム名
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
    cv_1    CONSTANT VARCHAR2(1)  := '1';
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==================================
    --処理1.2.3は呼び元(submain)にて記述
    --==================================
--
    --棚卸管理テーブルへ登録
    INSERT INTO xxcoi_inv_control(
       inventory_seq              -- 1.棚卸SEQ
      ,inventory_kbn              -- 2.棚卸区分
      ,base_code                  -- 3.拠点コード
      ,subinventory_code          -- 4.保管場所
      ,warehouse_kbn              -- 5.倉庫区分
      ,inventory_place            -- 6.棚卸場所
      ,inventory_year_month       -- 7.年月
      ,inventory_date             -- 8.棚卸日
      ,inventory_status           -- 9.棚卸ステータス
      ,created_by                 --10.作成者
      ,creation_date              --11.作成日
      ,last_updated_by            --12.最終更新者
      ,last_update_date           --13.最終更新日
      ,last_update_login          --14.最終更新ユーザ
      ,request_id                 --15.要求ID
      ,program_application_id     --16.プログラム・アプリケーションID
      ,program_id                 --17.プログラムID
      ,program_update_date        --18.プログラム更新日
    )VALUES(
       it_inventory_seq           -- 1.棚卸SEQ
      ,it_inventory_kbn           -- 2.棚卸区分
      ,it_base_code               -- 3.拠点コード
      ,it_subinventory_code       -- 4.保管場所
      ,it_warehouse_kbn           -- 5.倉庫区分
      ,it_inventory_place         -- 6.棚卸場所
      ,iv_fiscal_date             -- 7.年月
      ,it_inventory_date          -- 8.棚卸日
      ,cv_1                       -- 9.棚卸ステータス
      ,cn_created_by              --10.作成者
      ,SYSDATE                    --11.作成日
      ,cn_last_updated_by         --12.最終更新者
      ,SYSDATE                    --13.最終更新日
      ,cn_last_update_login       --14.最終更新ユーザ
      ,cn_request_id              --15.要求ID
      ,cn_program_application_id  --16.プログラム・アプリケーションID
      ,cn_program_id              --17.プログラムID
      ,SYSDATE                    --18.プログラム更新日
     );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_result
   * Description      : HHT棚卸結果出力(B-6)
   ***********************************************************************************/
  PROCEDURE ins_hht_result(
    it_inventory_seq      IN  xxcoi_inv_result.inventory_seq%TYPE,     -- 1.棚卸SEQ
    it_interface_id       IN  xxcoi_inv_result.interface_id%TYPE,      -- 2.インターフェースID
    it_input_order        IN  xxcoi_inv_result.input_order%TYPE,       -- 3.取込順
    it_base_code          IN  xxcoi_inv_result.base_code%TYPE,         -- 4.拠点コード
    it_inventory_kbn      IN  xxcoi_inv_result.inventory_kbn%TYPE,     -- 5.棚卸区分
    it_inventory_date     IN  xxcoi_inv_result.inventory_date%TYPE,    -- 6.棚卸日
    it_warehouse_kbn      IN  xxcoi_inv_result.warehouse_kbn%TYPE,     -- 7.倉庫区分
    it_inventory_place    IN  xxcoi_inv_result.inventory_place%TYPE,   -- 8.棚卸場所
    it_item_code          IN  xxcoi_inv_result.item_code%TYPE,         -- 9.品目コード
    it_case_qty           IN  xxcoi_inv_result.case_qty%TYPE,          --10.ケース数
    it_case_in_qty        IN  xxcoi_inv_result.case_in_qty%TYPE,       --11.入り数
    it_quantity           IN  xxcoi_inv_result.quantity%TYPE,          --12.本数
    it_slip_no            IN  xxcoi_inv_result.slip_no%TYPE,           --13.伝票№
    it_quality_goods_kbn  IN  xxcoi_inv_result.quality_goods_kbn%TYPE, --14.良品区分
    it_receive_date       IN  xxcoi_inv_result.receive_date%TYPE,      --15.受信日時
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_result'; -- プログラム名
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
    cv_0    CONSTANT VARCHAR2(1)  := '0';
    cv_n    CONSTANT VARCHAR2(1)  := 'N';
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --HHT棚卸結果テーブルへ登録
    INSERT INTO xxcoi_inv_result(
       inventory_seq            -- 1.棚卸SEQ
      ,interface_id             -- 2.インターフェースID
      ,input_order              -- 3.取込順
      ,base_code                -- 4.拠点コード
      ,inventory_kbn            -- 5.棚卸区分
      ,inventory_date           -- 6.棚卸日
      ,warehouse_kbn            -- 7.倉庫区分
      ,inventory_place          -- 8.棚卸場所
      ,process_flag             -- 9.処理済フラグ
      ,item_code                --10.品目コード
      ,case_qty                 --11.ケース数
      ,case_in_qty              --12.入り数
      ,quantity                 --13.本数
      ,slip_no                  --14.伝票№
      ,quality_goods_kbn        --15.良品区分
      ,receive_date             --16.受信日時
      ,created_by               --17.作成者
      ,creation_date            --18.作成日
      ,last_updated_by          --19.最終更新者
      ,last_update_date         --20.最終更新日
      ,last_update_login        --21.最終更新ユーザ
      ,request_id               --22.要求ID
      ,program_application_id   --23.プログラム・アプリケーションID
      ,program_id               --24.プログラムID
      ,program_update_date      --25.プログラム更新日
    )VALUES(
       it_inventory_seq                 -- 1.棚卸SEQ
      ,it_interface_id                  -- 2.インターフェースID
      ,it_input_order                   -- 3.取込順
      ,it_base_code                     -- 4.拠点コード
      ,it_inventory_kbn                 -- 5.棚卸区分
      ,it_inventory_date                -- 6.棚卸日
      ,it_warehouse_kbn                 -- 7.倉庫区分
      ,it_inventory_place               -- 8.棚卸場所
      ,cv_n                             -- 9.処理済フラグ
      ,it_item_code                     --10.品目コード
      ,it_case_qty                      --11.ケース数
      ,it_case_in_qty                   --12.入り数
      ,it_quantity                      --13.本数
      ,it_slip_no                       --14.伝票№
      ,NVL(it_quality_goods_kbn, cv_0)  --15.良品区分
      ,it_receive_date                  --16.受信日時
      ,cn_created_by                    --17.作成者
      ,SYSDATE                          --18.作成日
      ,cn_last_updated_by               --19.最終更新者
      ,SYSDATE                          --20.最終更新日
      ,cn_last_update_login             --21.最終更新ユーザ
      ,cn_request_id                    --22.要求ID
      ,cn_program_application_id        --23.プログラム・アプリケーションID
      ,cn_program_id                    --24.プログラムID
      ,SYSDATE                          --25.プログラム更新日
     );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_hht_result;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_result_file
   * Description      : 棚卸結果ファイルIF削除(B-8)
   ***********************************************************************************/
  PROCEDURE del_inv_result_file(
    it_interface_id       IN  xxcoi_in_inv_result_file_if.interface_id%TYPE,   -- 1.インターフェースID
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_result_file'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --棚卸結果ファイルIFから削除
    DELETE xxcoi_in_inv_result_file_if xirfi
    WHERE  xirfi.interface_id = it_interface_id
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END del_inv_result_file;
--
  /**********************************************************************************
   * Procedure Name   : get_uplode_data
   * Description      : ファイルアップロードI/Fデータ取得(B-10)
   ***********************************************************************************/
  PROCEDURE get_uplode_data(
    in_file_id          IN  NUMBER,       -- 1.ファイルID
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uplode_data'; -- プログラム名
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
    cv_xxcoi1_msg_10142 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10142';   --ファイルアップロードロック取得エラー
    cv_xxcoi1_msg_10290 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10290';   --BLOBデータ変換エラー
    cv_xxcoi1_msg_00020 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00020';   --空ファイルエラー
    cv_xxcoi1_msg_00028 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00028';   --ファイル名出力
-- == 2011/04/25 V1.12 Added START ===============================================================
    cv_xxcoi1_msg_10430 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10437';   --HHT棚卸結果データ取込エラーメッセージ
-- == 2011/04/25 V1.12 Added END   ===============================================================
--
    cv_tkn_file_id      CONSTANT VARCHAR2(30)  := 'FILE_ID';            --トークン名(FILE_ID)
    cv_tkn_file_name    CONSTANT VARCHAR2(39)  := 'FILE_NAME';          --トークン名(FILE_NAME)
-- == 2011/04/25 V1.12 Added START ===============================================================
    cv_tkn_row_num      CONSTANT VARCHAR2(10)  := 'ROW_NUM';            --トークン名(ROW_NUM)
-- == 2011/04/25 V1.12 Added END   ===============================================================
--
    cv_comma            CONSTANT VARCHAR2(1)   := ',';                  --カンマ
    cn_line_num         CONSTANT NUMBER        := 2;                    --行数
    cn_length_zero      CONSTANT NUMBER        := 0;                    --文字列のカンマなしの場合
    cn_first_char       CONSTANT NUMBER        := 1;                    --1文字目
    cn_add_value        CONSTANT NUMBER        := 2;                    --文字列への加算値
--
    -- *** ローカル変数 ***
--
    lb_retcode              BOOLEAN         DEFAULT NULL;   --メッセージ出力の戻り値
    lv_msg                  VARCHAR2(500)   DEFAULT NULL;   --メッセージ取得変数
    lv_file_name            VARCHAR2(256)   DEFAULT NULL;   --ファイル名
--
    lv_base_code            VARCHAR2(4)     DEFAULT NULL;   --拠点コード
    lv_inventory_kbn        VARCHAR2(1)     DEFAULT NULL;   --棚卸区分
    lv_inventory_date       VARCHAR2(8)     DEFAULT NULL;   --棚卸日
    lv_warehouse_kbn        VARCHAR2(1)     DEFAULT NULL;   --倉庫区分
    lv_inventory_place      VARCHAR2(9)     DEFAULT NULL;   --棚卸場所
    lv_item_code            VARCHAR2(7)     DEFAULT NULL;   --品目コード(品名コード)
    lv_case_qty             VARCHAR2(7)     DEFAULT NULL;   --ケース数
    lv_case_in_qty          VARCHAR2(5)     DEFAULT NULL;   --入数
    lv_quantity             VARCHAR2(10)    DEFAULT NULL;   --本数
    lv_slip_no              VARCHAR2(12)    DEFAULT NULL;   --伝票№
    lv_quality_goods_kbn    VARCHAR2(1)     DEFAULT NULL;   --良品区分
    lv_receive_date         VARCHAR2(19)    DEFAULT NULL;   --受信日時
--
    lv_line                 VARCHAR2(32767) DEFAULT NULL;   --1行のデータ
    lb_col                  BOOLEAN         DEFAULT TRUE;   --カラム作成継続
    ln_col                  NUMBER          DEFAULT 0;      --カラム
    ln_loop_cnt             NUMBER          DEFAULT 0;      --LOOPカウンタ
    ln_length               NUMBER;                         --カンマの位置
    lb_file_data            BLOB;                           --ファイルデータ
-- == 2011/04/25 V1.12 Added START ===============================================================
    ln_row_num              NUMBER          DEFAULT 0;      --取込行数
-- == 2011/04/25 V1.12 Added END   ===============================================================
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
     -- 行テーブル格納領域
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;
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
    -- ===================================================
    -- 1.ファイルアップロードIF表のデータ・ロックを取得
    -- ===================================================
    SELECT xmfui.file_name AS file_name
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = in_file_id
    FOR UPDATE NOWAIT;
    -- =============================================================================
    -- 2.ファイル名メッセージ出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcoi_short_name
              , iv_name         => cv_xxcoi1_msg_00028
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => lv_file_name
              );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    --
    -- ======================
    -- 3.BLOBデータ変換
    -- ======================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id
    , ov_file_data => l_file_data_tab
    , ov_errbuf    => lv_errbuf
    , ov_retcode   => lv_retcode
    , ov_errmsg    => lv_errmsg
    );
    --
    -- *** リターンコードが0(正常)以外の場合、例外処理 ***
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE blob_expt;
    END IF;
--
    -- ======================================
    -- 4.取得したデータの件数をチェック
    -- ======================================
    -- *** 件数が1件(タイトル行のみ)の場合、例外処理 ***
    IF ( l_file_data_tab.LAST < cn_line_num ) THEN
      RAISE file_expt;
    END IF;
    --
    -- *** 取得した情報を、行ごとに処理(2行目以降) ***
    <<for_loop>>
    FOR ln_index IN 2 .. l_file_data_tab.LAST LOOP
      --LOOPカウンタ
      ln_loop_cnt := ln_loop_cnt + 1;
      --1行毎のデータを格納
      lv_line := l_file_data_tab(ln_index);
-- == 2011/04/25 V1.12 Added START ===============================================================
      --取込行数を格納
      ln_row_num := ln_index;
-- == 2011/04/25 V1.12 Added END   ===============================================================
      --変数を初期化
      lb_col := TRUE;
      ln_col := 0;
      --
      lv_base_code         := NULL;
      lv_inventory_kbn     := NULL;
      lv_inventory_date    := NULL;
      lv_warehouse_kbn     := NULL;
      lv_inventory_place   := NULL;
      lv_item_code         := NULL;
      lv_case_qty          := NULL;
      lv_case_in_qty       := NULL;
      lv_quantity          := NULL;
      lv_slip_no           := NULL;
      lv_quality_goods_kbn := NULL;
      lv_receive_date      := NULL;
      -- *** 区切り文字単位(カンマ)で分解 ***
      <<comma_loop>>
      LOOP
      --lv_lineの長さが0なら終了
      EXIT WHEN( (lb_col = FALSE) OR (lv_line IS NULL) );
      --
        --カラム番号をカウント
        ln_col := ln_col + 1;
        --
        --カンマの位置を取得
        ln_length := INSTR(lv_line, cv_comma);
        --カンマがなし
        IF ( ln_length = cn_length_zero ) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        --カンマがあり
        ELSE
          ln_length := ln_length - 1;
          lb_col    := TRUE;
        END IF;
        --
        -- *** CSV形式を項目ごとに分解し変数に格納 ***
        --col = 1,6,14は不使用項目の為除外
        --項目1(拠点コード)
        IF ( ln_col = 2 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--           lv_base_code        := SUBSTR(lv_line, cn_first_char, ln_length);
           lv_base_code        := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目2(棚卸区分)
        ELSIF ( ln_col = 3 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_inventory_kbn     := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_inventory_kbn     := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目3(棚卸日)
        ELSIF ( ln_col = 4 ) THEN
          lv_inventory_date    := SUBSTR (lv_line, cn_first_char, ln_length);
        --項目4(倉庫区分)
        ELSIF ( ln_col = 5 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_warehouse_kbn     := SUBSTR (lv_line, cn_first_char, ln_length);
          lv_warehouse_kbn     := TRIM(SUBSTR (lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目5(棚卸場所)
        ELSIF ( ln_col = 7) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_inventory_place   := SUBSTR (lv_line, cn_first_char, ln_length);
          lv_inventory_place   := TRIM(SUBSTR (lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目6(品目コード)
        ELSIF ( ln_col = 8 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_item_code         := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_item_code         := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目7(ケース数)
        ELSIF ( ln_col = 9 ) THEN
          lv_case_qty          := SUBSTR(lv_line, cn_first_char, ln_length);
        --項目8(入数)
        ELSIF ( ln_col = 10 ) THEN
          lv_case_in_qty       := SUBSTR(lv_line, cn_first_char, ln_length);
        --項目9(本数)
        ELSIF ( ln_col = 11 ) THEN
          lv_quantity          := SUBSTR(lv_line, cn_first_char, ln_length);
        --項目10(伝票№)
        ELSIF ( ln_col = 12 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_slip_no           := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_slip_no           := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目11(良品区分)
        ELSIF ( ln_col = 13 ) THEN
-- == 2009/04/21 V1.3 Modified START ===============================================================
--          lv_quality_goods_kbn := SUBSTR(lv_line, cn_first_char, ln_length);
          lv_quality_goods_kbn := TRIM(SUBSTR(lv_line, cn_first_char, ln_length));
-- == 2009/04/21 V1.3 Modified END   ===============================================================
        --項目12(受信日時)
        ELSIF ( ln_col = 15 ) THEN
          lv_receive_date      := SUBSTR(lv_line, cn_first_char, ln_length);
        END IF;
        --
        -- *** 取得した項目を除く(カンマはのぞくため、ln_length + 2) ***
        IF ( lb_col = TRUE ) THEN
          lv_line := SUBSTR(lv_line, ln_length + cn_add_value);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
      --
      END LOOP comma_loop;
      --
      -- =======================
      -- 5.一時表へ取り込む
      -- =======================
      --
      INSERT INTO xxcoi_tmp_inv_result(
         sort_no              -- 1.取込順
        ,base_code            -- 2.拠点コード
        ,inventory_kbn        -- 3.棚卸区分
        ,inventory_date       -- 4.棚卸日
        ,warehouse_kbn        -- 5.倉庫区分
        ,inventory_place      -- 6.棚卸場所
        ,item_code            -- 7.品目コード
        ,case_qty             -- 8.ケース数
        ,case_in_qty          -- 9.入数
        ,quantity             --10.本数
        ,slip_no              --11.伝票№
        ,quality_goods_kbn    --12.良品区分
        ,receive_date         --13.受信日時
        ,file_id              --14.ファイルID
      )VALUES(
         ln_loop_cnt          -- 1.取込順(LOOPカウンタ)
        ,lv_base_code         -- 2.拠点コード
        ,lv_inventory_kbn     -- 3.棚卸区分
        ,lv_inventory_date    -- 4.棚卸日
        ,lv_warehouse_kbn     -- 5.倉庫区分
        ,lv_inventory_place   -- 6.棚卸場所
        ,lv_item_code         -- 7.品目コード
-- == 2009/11/18 V1.7 Modified START ==================================================================
--        ,lv_case_qty          -- 8.ケース数
--        ,lv_case_in_qty       -- 9.入数
--        ,lv_quantity          --10.本数
        ,NVL(lv_case_qty, 0)    -- 8.ケース数
        ,NVL(lv_case_in_qty, 0) -- 9.入数
        ,NVL(lv_quantity, 0)    --10.本数
-- == 2009/11/18 V1.7 Modified END   ==================================================================
        ,lv_slip_no           --11.伝票№
        ,lv_quality_goods_kbn --12.良品区分
        ,lv_receive_date      --13.受信日時
        ,in_file_id           --14.ファイルID
      );
    --
    END LOOP for_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    --*** ファイルアップロードロック取得エラー ***
    WHEN lock_expt THEN
      --メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10142
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** BLOBデータ変換エラー ***
    WHEN blob_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                , iv_name         => cv_xxcoi1_msg_10290
                , iv_token_name1  => cv_tkn_file_id
                , iv_token_value1 => in_file_id
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 空ファイルエラー ***
    WHEN file_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                , iv_name         => cv_xxcoi1_msg_00020
                , iv_token_name1  => cv_tkn_file_id
                , iv_token_value1 => in_file_id
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
-- == 2011/04/25 V1.12 Added START ===============================================================
     lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                , iv_name         => cv_xxcoi1_msg_10430
                , iv_token_name1  => cv_tkn_row_num
                , iv_token_value1 => ln_row_num
                );
      ov_errmsg  := lv_errmsg;
-- == 2011/04/25 V1.12 Added END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_uplode_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_file_data
   * Description      : ファイルデータチェック(B-11)
   ***********************************************************************************/
  PROCEDURE chk_file_data(
    it_order_no           IN  xxcoi_tmp_inv_result.sort_no%TYPE,               -- 1.取込順
    it_base_code          IN  xxcoi_tmp_inv_result.base_code%TYPE,             -- 2.拠点コード
    it_inventory_kbn      IN  xxcoi_tmp_inv_result.inventory_kbn%TYPE,         -- 3.棚卸区分
    it_inventory_date     IN  xxcoi_tmp_inv_result.inventory_date%TYPE,        -- 4.棚卸日
    it_inventory_place    IN  xxcoi_tmp_inv_result.inventory_place%TYPE,       -- 5.棚卸場所
    it_warehouse_kbn      IN  xxcoi_tmp_inv_Result.warehouse_kbn%TYPE,         -- 6.倉庫区分
    it_item_code          IN  xxcoi_tmp_inv_result.item_code%TYPE,             -- 7.品目コード
    it_receive_date       IN  xxcoi_tmp_inv_result.receive_date%TYPE,          -- 8.受信日次
    it_case_qty           IN  xxcoi_tmp_inv_result.case_qty%TYPE,              -- 9.ケース数
    it_case_in_qty        IN  xxcoi_tmp_inv_result.case_in_qty%TYPE,           --10.入数
    it_quantity           IN  xxcoi_tmp_inv_result.quantity%TYPE,              --11.本数
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_file_data'; -- プログラム名
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
    --メッセージ
    cv_xxcoi1_msg_10140 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10140';
    cv_xxcoi1_msg_10186 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10186';
    cv_xxcoi1_msg_10138 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10138';
    cv_xxcoi1_msg_10139 CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10139';
    --トークン
    cv_tkn_ord_no       CONSTANT VARCHAR2(8)  := 'ORDER_NO';
    cv_tkn_col          CONSTANT VARCHAR2(6)  := 'COLUMN';
    cv_tkn_val          CONSTANT VARCHAR2(5)  := 'VALUE';
    cv_tkn_loc_cd       CONSTANT VARCHAR2(11) := 'LOCATION_CD';
    cv_tkn_ivt_cd       CONSTANT VARCHAR2(6)  := 'IVT_CD';
    --クイックコード
    cv_lk_reslt_col     CONSTANT VARCHAR2(29) := 'XXCOI1_INV_RESULT_FILE_COLUMN'; --拠点コード
    --項目名称
    cv_input_order      CONSTANT VARCHAR2(11) := 'INPUT_ORDER';
    cv_base_code        CONSTANT VARCHAR2(9)  := 'BASE_CODE';
    cv_inv_kbn          CONSTANT VARCHAR2(13) := 'INVENTORY_KBN';
    cv_inv_place        CONSTANT VARCHAR2(15) := 'INVENTORY_PLACE';
    cv_item_code        CONSTANT VARCHAR2(9)  := 'ITEM_CODE';
    cv_receive_dt       CONSTANT VARCHAR2(12) := 'RECEIVE_DATE';
    cv_case_qty         CONSTANT VARCHAR2(8)  := 'CASE_QTY';
    cv_case_in_qty      CONSTANT VARCHAR2(11) := 'CASE_IN_QTY';
    cv_qty              CONSTANT VARCHAR2(8)  := 'QUANTITY';
    cv_inv_dt           CONSTANT VARCHAR2(14) := 'INVENTORY_DATE';
    cv_ware_kbn         CONSTANT VARCHAR2(13) := 'WAREHOUSE_KBN';
--
    cv_ymd              CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
    cv_ymdhms           CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
-- == 2011/10/18 V1.13 Added START ============================================================== ==
    cv_period           CONSTANT VARCHAR2(1)  := '.';
    cv_space            CONSTANT VARCHAR2(1)  := ' ';
    cv_plus             CONSTANT VARCHAR2(1)  := '+';
-- == 2011/10/18 V1.13 Added END   ============================================================== ==
    -- *** ローカル変数 ***
    lt_column           fnd_lookup_values.meaning%TYPE;   --項目名
    lv_value            VARCHAR2(50);                     --項目値
    ld_chk_date         DATE;                             --日付変換用
--
    ln_num              NUMBER;                           --数値変換用
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --===============
    --必須チェック
    --===============
    --取込順
    IF (it_order_no IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_input_order
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    --拠点コード
    ELSIF (it_base_code IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_base_code
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    --棚卸区分
    ELSIF (it_inventory_kbn IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_inv_kbn
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    --棚卸場所
    ELSIF (it_inventory_place IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_inv_place
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    --品目コード
    ELSIF (it_item_code IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_item_code
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    --受信日時
    ELSIF (it_receive_date IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_receive_dt
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    --倉庫区分
    ELSIF (it_warehouse_kbn IS NULL) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_ware_kbn
                );
      --取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
      --必須チェックエラー
      RAISE required_expt;
    END IF;
--
    --================
    --半角数字チェック
    --================
    --ケース数
-- == 2011/10/18 V1.13 Modified START ==============================================================
--    IF (xxccp_common_pkg.chk_number(it_case_qty) = FALSE) THEN
    --マイナスの場合、共通関数ではエラーとなるため、共通関数を使用しない
    BEGIN
      ln_num := TO_NUMBER(it_case_qty);
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_case_qty
                  );
        --名称が取得できなかった場合エラー
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := TO_CHAR(it_case_qty);
        --半角数字チェックエラー
        RAISE harf_number_expt;
    END;
    -- ピリオド、前後の空白、プラスチェック
    IF  ((INSTRB(it_case_qty,cv_period) > 0)
      OR (INSTRB(it_case_qty,cv_space) > 0)
      OR (INSTRB(it_case_qty,cv_plus) > 0)) THEN
-- == 2011/10/18 V1.13 Modified END   ==============================================================
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_case_qty
                );
      --名称が取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
--
      lv_value := TO_CHAR(it_case_qty);
      --半角数字チェックエラー
      RAISE harf_number_expt;
    --入数
    ELSIF (xxccp_common_pkg.chk_number(it_case_in_qty) = FALSE) THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_case_in_qty
                );
      --名称が取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
--
      lv_value := TO_CHAR(it_case_in_qty);
      --半角数字チェックエラー
      RAISE harf_number_expt;
    END IF;
--
    --本数
    --小数点つきなので共通関数ではチェック不可
    BEGIN
      ln_num := TO_NUMBER(it_quantity);
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_qty
                  );
        --名称が取得できなかった場合エラー
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := TO_CHAR(it_quantity);
        --半角数字チェックエラー
        RAISE harf_number_expt;
    END;
--
    --===============
    --桁数チェック
    --===============
    --本数
    IF ((INSTRB(it_quantity, '.') > 8)
      OR  ((INSTRB(it_quantity, '.') > 0)
      AND (LENGTHB(SUBSTRB(it_quantity, INSTRB(it_quantity, '.') + 1)) > 2))
      OR  ((INSTRB(it_quantity, '.') = 0)
      AND (LENGTHB(it_quantity) > 7)))
    THEN
      lt_column := xxcoi_common_pkg.get_meaning(
                   cv_lk_reslt_col
                  ,cv_qty
                );
      --名称が取得できなかった場合エラー
      IF (lt_column IS NULL) THEN
        RAISE get_result_col_expt;
      END IF;
--
      lv_value := it_quantity;
      --半角数字チェックエラー
      RAISE harf_number_expt;
    END IF;
--
    --===============
    --日付チェック
    --===============
    --棚卸日
    BEGIN
      SELECT TO_DATE(it_inventory_date, cv_ymd)
      INTO   ld_chk_date
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_inv_dt
                  );
        --名称が取得できなかった場合エラー
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := it_inventory_date;
--
        --日付チェックエラー
        RAISE date_expt;
    END;
--
    --受信日時
    BEGIN
      SELECT TO_DATE(it_receive_date, cv_ymdhms)
      INTO   ld_chk_date
      FROM   DUAL
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_column := xxcoi_common_pkg.get_meaning(
                     cv_lk_reslt_col
                    ,cv_receive_dt
                  );
        --名称が取得できなかった場合エラー
        IF (lt_column IS NULL) THEN
          RAISE get_result_col_expt;
        END IF;
--
        lv_value := it_receive_date;
--
        RAISE date_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** 棚卸結果ファイルIF項目取得エラー ***
    WHEN get_result_col_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10186);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                     --# 任意 #
--
    --*** 必須チェックエラー ***
    WHEN required_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10138
                 ,iv_token_name1  => cv_tkn_ord_no
                 ,iv_token_value1 => TO_CHAR(it_order_no)
                 ,iv_token_name2  => cv_tkn_col
                 ,iv_token_value2 => lt_column
                 ,iv_token_name3  => cv_tkn_loc_cd
                 ,iv_token_value3 => it_base_code
                 ,iv_token_name4  => cv_tkn_ivt_cd
                 ,iv_token_value4 => it_inventory_place
                );
      IF (gn_warn_cnt = 0) THEN
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      --メッセージ出力
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 半角数字チェックエラー ***
    WHEN harf_number_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10139
                 ,iv_token_name1  => cv_tkn_ord_no
                 ,iv_token_value1 => TO_CHAR(it_order_no)
                 ,iv_token_name2  => cv_tkn_col
                 ,iv_token_value2 => lt_column
                 ,iv_token_name3  => cv_tkn_val
                 ,iv_token_value3 => lv_value
                 ,iv_token_name4  => cv_tkn_loc_cd
                 ,iv_token_value4 => it_base_code
                 ,iv_token_name5  => cv_tkn_ivt_cd
                 ,iv_token_value5 => it_inventory_place
                );
      IF (gn_warn_cnt = 0) THEN
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      --メッセージ出力
      FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;                     --# 任意 #
--
    --*** 日付チェックエラー ***
    WHEN date_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_10140
                   ,iv_token_name1  => cv_tkn_ord_no
                   ,iv_token_value1 => TO_CHAR(it_order_no)
                   ,iv_token_name2  => cv_tkn_col
                   ,iv_token_value2 => lt_column
                   ,iv_token_name3  => cv_tkn_val
                   ,iv_token_value3 => lv_value
                   ,iv_token_name4  => cv_tkn_loc_cd
                   ,iv_token_value4 => it_base_code
                   ,iv_token_name5  => cv_tkn_ivt_cd
                   ,iv_token_value5 => it_inventory_place
                  );
        IF (gn_warn_cnt = 0) THEN
          --空行挿入
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END IF;
        --メッセージ出力
        FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;                     --# 任意 #
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
  END chk_file_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_result_file
   * Description      : 棚卸結果ファイルIF出力(B-12)
   ***********************************************************************************/
  PROCEDURE ins_result_file(
    it_order_no           IN  xxcoi_tmp_inv_result.sort_no%TYPE,               -- 1.取込順
    it_base_code          IN  xxcoi_tmp_inv_result.base_code%TYPE,             -- 2.拠点コード
    it_inventory_kbn      IN  xxcoi_tmp_inv_result.inventory_kbn%TYPE,         -- 3.棚卸区分
    it_inventory_date     IN  xxcoi_tmp_inv_result.inventory_date%TYPE,        -- 4.棚卸日
    it_warehouse_kbn      IN  xxcoi_tmp_inv_result.warehouse_kbn%TYPE,         -- 5.倉庫区分
    it_inventory_place    IN  xxcoi_tmp_inv_result.inventory_place%TYPE,       -- 6.棚卸場所
    it_item_code          IN  xxcoi_tmp_inv_result.item_code%TYPE,             -- 7.品目コード
    it_case_qty           IN  xxcoi_tmp_inv_result.case_qty%TYPE,              -- 8.ケース数
    it_case_in_qty        IN  xxcoi_tmp_inv_result.case_in_qty%TYPE,           -- 9.入数
    it_quantity           IN  xxcoi_tmp_inv_result.quantity%TYPE,              --10.本数
    it_slip_no            IN  xxcoi_tmp_inv_result.slip_no%TYPE,               --11.伝票№
    it_quality_goods_kbn  IN  xxcoi_tmp_inv_result.quality_goods_kbn%TYPE,     --12.良品区分
    it_receive_date       IN  xxcoi_tmp_inv_result.receive_date%TYPE,          --13.受信日時
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_result_file'; -- プログラム名
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
    cv_fmt_ymdhms     CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS'; -- 年月日時分秒変換用
    cv_fmt_ymd        CONSTANT VARCHAR2(8)  := 'YYYYMMDD';              -- 年月日変換用
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --棚卸結果ファイルIFへ登録
    INSERT INTO xxcoi_in_inv_result_file_if(
       interface_id               -- 1.インターフェースID
      ,input_order                -- 2.取込順
      ,base_code                  -- 3.拠点コード
      ,inventory_kbn              -- 4.棚卸区分
      ,inventory_date             -- 5.棚卸日
      ,warehouse_kbn              -- 6.倉庫区分
      ,inventory_place            -- 7.棚卸場所
      ,item_code                  -- 8.品目コード
      ,case_qty                   -- 9.ケース数
      ,case_in_qty                --10.入数
      ,quantity                   --11.本数
      ,slip_no                    --12.伝票№
      ,quality_goods_kbn          --13.良品区分
      ,receive_date               --14.受信日時
      ,created_by                 --15.作成者
      ,creation_date              --16.作成日
      ,last_updated_by            --17.最終更新者
      ,last_update_date           --18.最終更新日
      ,last_update_login          --19.最終更新ユーザ
      ,request_id                 --20.要求ID
      ,program_application_id     --21.プログラム・アプリケーションID
      ,program_id                 --22.プログラムID
      ,program_update_date        --23.プログラム更新日
    )VALUES(
       xxcoi_inv_result_s01.nextval             -- 1.インターフェースID
      ,it_order_no                              -- 2.取込順
      ,it_base_code                             -- 3.拠点コード
      ,it_inventory_kbn                         -- 4.棚卸区分
      ,TO_DATE(it_inventory_date, cv_fmt_ymd)   -- 5.棚卸日
      ,it_warehouse_kbn                         -- 6.倉庫区分
      ,it_inventory_place                       -- 7.棚卸場所
      ,it_item_code                             -- 8.品目コード
      ,TO_NUMBER(it_case_qty)                   -- 9.ケース数
      ,TO_NUMBER(it_case_in_qty)                --10.入数
      ,TO_NUMBER(it_quantity)                   --11.本数
      ,it_slip_no                               --12.伝票№
      ,it_quality_goods_kbn                     --13.良品区分
      ,TO_DATE(it_receive_date, cv_fmt_ymdhms)  --14.受信日時
      ,cn_created_by                            --15.作成者
      ,SYSDATE                                  --16.作成日
      ,cn_last_updated_by                       --17.最終更新者
      ,SYSDATE                                  --18.最終更新日
      ,cn_last_update_login                     --19.最終更新ユーザ
      ,cn_request_id                            --20.要求ID
      ,cn_program_application_id                --21.プログラム・アプリケーションID
      ,cn_program_id                            --22.プログラムID
      ,SYSDATE                                  --23.プログラム更新日
     );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_result_file;
--
  /**********************************************************************************
   * Procedure Name   : del_uplode_data
   * Description      : ファイルアップロードIFデータ削除(B-13)
   ***********************************************************************************/
  PROCEDURE del_uplode_data(
    in_file_id            IN  NUMBER,       -- 1.ファイルID
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_uplode_data'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ======================================
    -- ファイルアップロードIF表の削除処理
    -- ======================================
    DELETE xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = in_file_id
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END del_uplode_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id        IN  NUMBER,     -- 1.FILE_ID
    iv_format_pattern IN  VARCHAR2,   -- 2.フォーマットパターン
    ov_errbuf         OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
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
    --メッセージ
    cv_xxcoi1_msg_00008     CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00008';            --0件メッセージ
    cv_xxcoi1_msg_10141     CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10141';            --棚卸結果ファイルIFロックエラー
-- == 2009/06/02 V1.5 Added START ===============================================================
    cv_1                    CONSTANT  VARCHAR2(1)   := '1';
    cv_2                    CONSTANT  VARCHAR2(1)   := '2';
-- == 2009/06/02 V1.5 Added END   ===============================================================
--
    -- *** ローカル変数 ***
    ln_organization_id      NUMBER;                                                   --在庫組織ID
--
    lt_old_base_code        xxcoi_in_inv_result_file_if.base_code%TYPE;               --OLD拠点コード
    lt_old_inventory_place  xxcoi_in_inv_result_file_if.inventory_place%TYPE;         --OLD棚卸場所
    ld_old_inventory_date   xxcoi_in_inv_result_file_if.inventory_date%TYPE;          --OLD棚卸日
    lt_old_inventory_kbn    xxcoi_in_inv_result_file_if.inventory_kbn%TYPE;           --OLD棚卸区分
    lt_subinventory_code    mtl_secondary_inventories.secondary_inventory_name%TYPE;  --保管場所
    lv_fiscal_date          VARCHAR2(6);                                              --在庫会計期間
    lt_inventory_seq        xxcoi_inv_control.inventory_seq%TYPE;                     --棚卸SEQ
-- == 2010/05/12 V1.11 Added START ===============================================================
    lt_pre_base_code        xxcoi_in_inv_result_file_if.base_code%TYPE;
    lt_pre_inventory_kbn    xxcoi_in_inv_result_file_if.inventory_kbn%TYPE;
    lt_pre_inventory_place  xxcoi_in_inv_result_file_if.inventory_place%TYPE;
    lt_input_order          xxcoi_inv_result.input_order%TYPE;
-- == 2010/05/12 V1.11 Added END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    --棚卸結果ファイルIF抽出
    CURSOR get_inv_data_cur
    IS
-- == 2009/06/02 V1.5 Modified START ===============================================================
--      SELECT    xirfi.interface_id                  -- 1.インターフェースID
--               ,xirfi.input_order                   -- 2.取込順
--               ,xirfi.base_code                     -- 3.拠点コード
--               ,xirfi.inventory_kbn                 -- 4.棚卸区分
--               ,xirfi.inventory_date                -- 5.棚卸日
--               ,xirfi.warehouse_kbn                 -- 6.倉庫区分
--               ,xirfi.inventory_place               -- 7.棚卸場所
--               ,xirfi.item_code                     -- 8.品目コード
--               ,xirfi.case_qty                      -- 9.ケース数
--               ,xirfi.case_in_qty                   --10.入数
--               ,xirfi.quantity                      --11.本数
--               ,xirfi.slip_no                       --12.伝票№
--               ,xirfi.quality_goods_kbn             --13.良品区分
--               ,xirfi.receive_date                  --14.受信日時
--               ,xic.inventory_seq                   --15.棚卸SEQ
--               ,xic.inventory_status                --16.棚卸ステータス
--      FROM      xxcoi_in_inv_result_file_if  xirfi  --棚卸結果ファイルIF
--               ,xxcoi_inv_control         xic       --棚卸管理
--      WHERE     xirfi.base_code       = xic.base_code(+)          --拠点コード
--      AND       xirfi.inventory_place = xic.inventory_place(+)    --棚卸場所
--      AND       xirfi.inventory_date  = xic.inventory_date(+)     --棚卸日
--      AND       xirfi.inventory_kbn   = xic.inventory_kbn(+)      --棚卸区分
--      ORDER BY  xirfi.base_code
--               ,xirfi.inventory_place
--               ,xirfi.inventory_date
--               ,xirfi.inventory_kbn
--      FOR UPDATE OF xirfi.interface_id NOWAIT
--      ;
--
      SELECT    ilv.interface_id                  --  1.インターフェースID
-- == 2009/12/01 V1.9 Modified START ===============================================================
---- == 2009/07/14 V1.6 Modified START ===============================================================
----               ,ilv.input_order                   --  2.取込順
--               ,ROW_NUMBER() OVER
--                          (PARTITION BY ilv.base_code, ilv.inventory_place
---- == 2009/11/29 V1.8 Modified START ===============================================================
----                           ORDER BY     ilv.base_code, ilv.inventory_place, ilv.creation_date
--                           ORDER BY     ilv.base_code, ilv.inventory_place, ilv.interface_id
---- == 2009/11/29 V1.8 Modified END   ===============================================================
--                          ) input_order           --  2.取込順
---- == 2009/07/14 V1.6 Modified END   ===============================================================
               ,ROW_NUMBER() OVER
                          (PARTITION BY ilv.base_code, ilv.inventory_place, ilv.inventory_kbn
                           ORDER BY     ilv.interface_id
                          ) input_order           --  2.取込順
-- == 2009/12/01 V1.9 Modified START ===============================================================
               ,ilv.base_code                     --  3.拠点コード
               ,ilv.inventory_kbn                 --  4.棚卸区分
               ,ilv.inventory_date                --  5.棚卸日
               ,ilv.warehouse_kbn                 --  6.倉庫区分
               ,ilv.inventory_place               --  7.棚卸場所
               ,ilv.item_code                     --  8.品目コード
               ,ilv.case_qty                      --  9.ケース数
               ,ilv.case_in_qty                   -- 10.入数
               ,ilv.quantity                      -- 11.本数
               ,ilv.slip_no                       -- 12.伝票№
               ,ilv.quality_goods_kbn             -- 13.良品区分
               ,ilv.receive_date                  -- 14.受信日時
               ,xic.inventory_seq                 -- 15.棚卸SEQ
               ,xic.inventory_status              -- 16.棚卸ステータス
      FROM      (SELECT   xirfi.interface_id                    -- インターフェースID
                         ,xirfi.input_order                     -- 取込順
                         ,xirfi.base_code                       -- 拠点コード
                         ,xirfi.inventory_kbn                   -- 棚卸区分
                         ,xirfi.inventory_date                  -- 棚卸日
                         ,xirfi.warehouse_kbn                   -- 倉庫区分
                         ,DECODE(xirfi.warehouse_kbn, cv_1, SUBSTRB(xirfi.inventory_place, -2, 2)
                                                    , cv_2, SUBSTRB(xirfi.inventory_place, -5, 5)
                                                         , xirfi.inventory_place
                          )               inventory_place       -- 棚卸場所
                         ,xirfi.item_code                       -- 品目コード
                         ,xirfi.case_qty                        -- ケース数
                         ,xirfi.case_in_qty                     -- 入数
                         ,xirfi.quantity                        -- 本数
                         ,xirfi.slip_no                         -- 伝票№
                         ,xirfi.quality_goods_kbn               -- 良品区分
                         ,xirfi.receive_date                    -- 受信日時
-- == 2009/07/14 V1.6 Added START ===============================================================
                         ,xirfi.creation_date                   -- 作成日
-- == 2009/07/14 V1.6 Added END   ===============================================================
                 FROM     xxcoi_in_inv_result_file_if  xirfi    -- 棚卸結果ファイルIF
                )                         ilv                   -- 棚卸結果ファイルIF情報
               ,xxcoi_inv_control         xic                   -- 棚卸管理
      WHERE     ilv.base_code       = xic.base_code(+)          -- 拠点コード
      AND       ilv.inventory_place = xic.inventory_place(+)    -- 棚卸場所
      AND       ilv.inventory_date  = xic.inventory_date(+)     -- 棚卸日
      AND       ilv.inventory_kbn   = xic.inventory_kbn(+)      -- 棚卸区分
      ORDER BY  ilv.base_code
               ,ilv.inventory_place
-- == 2009/12/01 V1.9 Deleted START ===============================================================
---- == 2009/11/29 V1.8 Added START ===============================================================
--               ,ilv.interface_id
---- == 2009/11/29 V1.8 Added END   ===============================================================
-- == 2009/12/01 V1.9 Deleted END   ===============================================================
               ,ilv.inventory_date
               ,ilv.inventory_kbn
      FOR UPDATE OF ilv.interface_id NOWAIT
      ;
-- == 2009/06/02 V1.5 Modified END   ===============================================================
--
    --ファイルアップロード一時表データ抽出
    CURSOR get_tmp_cur(in_file_id IN NUMBER)
    IS
      SELECT    xirt.sort_no            sort_no             -- 1.取込順
               ,xirt.base_code          base_code           -- 2.拠点コード
               ,xirt.inventory_kbn      inventory_kbn       -- 3.棚卸区分
               ,xirt.inventory_date     inventory_date      -- 4.棚卸日
               ,xirt.warehouse_kbn      warehouse_kbn       -- 5.倉庫区分
               ,xirt.inventory_place    inventory_place     -- 6.棚卸場所
               ,xirt.item_code          item_code           -- 7.品目コード
               ,xirt.case_qty           case_qty            -- 8.ケース数
               ,xirt.case_in_qty        case_in_qty         -- 9.入数
               ,xirt.quantity           quantity            --10.本数
               ,xirt.slip_no            slip_no             --11.伝票№
               ,xirt.quality_goods_kbn  quality_goods_kbn   --12.良品区分
               ,xirt.receive_date       receive_date        --13.受信日時
      FROM      xxcoi_tmp_inv_result  xirt                  --ファイルアップロード一時表
      WHERE     xirt.file_id = in_file_id
      ORDER BY  xirt.sort_no
      ;
    -- <カーソル名>レコード型
    get_inv_data_rec get_inv_data_cur%ROWTYPE;
    get_tmp_rec      get_tmp_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
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
    -- ===============================
    -- <初期処理 B-1>
    -- ===============================
    init(
      in_file_id          =>  in_file_id          -- FILE_ID
     ,iv_format_pattern   =>  iv_format_pattern   -- フォーマットパターン
     ,on_organization_id  =>  ln_organization_id  -- 在庫組織コード
     ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --JP1定期起動
    IF (in_file_id IS NULL) THEN
--
      -- ===============================
      -- <棚卸結果ファイルIF抽出 B-2>
      -- ===============================
      --棚卸結果データ取得カーソルオープン
      OPEN get_inv_data_cur;
      <<inv_data_loop>>
      LOOP
        FETCH get_inv_data_cur INTO get_inv_data_rec;
        --次データがなくなったら終了
        EXIT WHEN get_inv_data_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- <IFデータチェック B-3>
        -- ===============================
        chk_if_data(
           it_base_code         => get_inv_data_rec.base_code         -- 1.拠点コード
          ,it_inventory_kbn     => get_inv_data_rec.inventory_kbn     -- 2.棚卸区分
          ,it_inventory_date    => get_inv_data_rec.inventory_date    -- 3.棚卸日
          ,it_warehouse_kbn     => get_inv_data_rec.warehouse_kbn     -- 4.倉庫区分
          ,it_inventory_place   => get_inv_data_rec.inventory_place   -- 5.棚卸場所
          ,it_item_code         => get_inv_data_rec.item_code         -- 6.品目コード
          ,it_quality_goods_kbn => get_inv_data_rec.quality_goods_kbn -- 7.良品区分
          ,iv_inventory_status  => get_inv_data_rec.inventory_status  -- 8.棚卸ステータス
          ,in_organization_id   => ln_organization_id                 -- 9.在庫組織ID
-- == 2010/03/23 V1.10 Added START ===============================================================
          ,it_slip_no           => get_inv_data_rec.slip_no           --12.伝票No
-- == 2010/03/23 V1.10 Added END   ===============================================================
          ,ov_subinventory_code => lt_subinventory_code               --10.保管場所
          ,ov_fiscal_date       => lv_fiscal_date                     --11.在庫会計期間
          ,ov_errbuf            => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
          ,ov_retcode           => lv_retcode                         -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
        --正常終了の場合
        IF (lv_retcode = cv_status_normal) THEN
          --棚卸SEQがNULL且つ、拠点コード、棚卸場所、棚卸日、棚卸区分がNULL、又は
          --棚卸SEQがNULL且つ、前レコードの値と一つでも違っていたらB-5の処理を行う
          IF ((get_inv_data_rec.inventory_seq IS NULL)
            AND (((lt_old_base_code IS NULL)
              OR (get_inv_data_rec.base_code       <> lt_old_base_code))
            OR ((lt_old_inventory_place IS NULL)
              OR (get_inv_data_rec.inventory_place <> lt_old_inventory_place))
            OR ((ld_old_inventory_date IS NULL)
              OR (get_inv_data_rec.inventory_date  <> ld_old_inventory_date))
            OR ((lt_old_inventory_kbn IS NULL)
              OR (get_inv_data_rec.inventory_kbn   <> lt_old_inventory_kbn))))
          THEN
            --レコードの値をOLD変数に格納
            lt_old_base_code       := get_inv_data_rec.base_code;
            lt_old_inventory_place := get_inv_data_rec.inventory_place;
            ld_old_inventory_date  := get_inv_data_rec.inventory_date;
            lt_old_inventory_kbn   := get_inv_data_rec.inventory_kbn;
--
            --棚卸SEQがNULLの場合はシーケンスから取得
            IF (get_inv_data_rec.inventory_seq IS NULL) THEN
              SELECT  xxcoi_inv_control_s01.nextval
              INTO    lt_inventory_seq
              FROM    dual
              ;
            END IF;
            -- ===============================
            -- <棚卸管理出力 B-5>
            -- ===============================
            ins_inv_control(
               it_inventory_seq     => lt_inventory_seq                 -- 1.棚卸SEQ
              ,it_inventory_kbn     => get_inv_data_rec.inventory_kbn   -- 2.棚卸区分
              ,it_base_code         => get_inv_data_rec.base_code       -- 3.拠点コード
              ,it_warehouse_kbn     => get_inv_data_rec.warehouse_kbn   -- 4.倉庫区分
              ,it_inventory_place   => get_inv_data_rec.inventory_place -- 5.棚卸場所
              ,it_inventory_date    => get_inv_data_rec.inventory_date  -- 6.棚卸日
              ,it_subinventory_code => lt_subinventory_code             -- 7.保管場所
              ,iv_fiscal_date       => lv_fiscal_date                   -- 8.会計期間
              ,ov_errbuf            => lv_errbuf                        -- エラー・メッセージ           --# 固定 #
              ,ov_retcode           => lv_retcode                       -- リターン・コード             --# 固定 #
              ,ov_errmsg            => lv_errmsg);                      -- ユーザー・エラー・メッセージ --# 固定 #
            --正常終了以外の場合
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
          --棚卸SEQチェック(NULLの場合代入してないのでここで行なう。)
          IF (get_inv_data_rec.inventory_seq IS NOT NULL) THEN
            lt_inventory_seq := get_inv_data_rec.inventory_seq;
          END IF;
--
-- == 2010/05/12 V1.11 Added START ===============================================================
          -- 拠点、棚卸区分、棚卸場所が変わったら、取込順の最大値を取得する。
          IF     (((lt_pre_base_code                IS NULL)
              OR  (get_inv_data_rec.base_code       <> lt_pre_base_code))
            OR   ((lt_pre_inventory_kbn             IS NULL)
              OR  (get_inv_data_rec.inventory_kbn   <> lt_pre_inventory_kbn))
            OR   ((lt_pre_inventory_place           IS NULL)
              OR  (get_inv_data_rec.inventory_place <> lt_pre_inventory_place)))
          THEN
            --変数へ格納
            lt_pre_base_code        := get_inv_data_rec.base_code;
            lt_pre_inventory_kbn    := get_inv_data_rec.inventory_kbn;
            lt_pre_inventory_place  := get_inv_data_rec.inventory_place;
            --取込順の最大値取得
            BEGIN
              SELECT NVL(MAX(xir.input_order),0) input_order
              INTO   lt_input_order
              FROM   xxcoi_inv_control xic
                    ,xxcoi_inv_result  xir
              WHERE  xic.base_code            = get_inv_data_rec.base_code
              AND    xic.inventory_kbn        = get_inv_data_rec.inventory_kbn
              AND    xic.inventory_year_month = TO_CHAR(get_inv_data_rec.inventory_date, 'YYYYMM')
              AND    xic.inventory_place      = get_inv_data_rec.inventory_place
              AND    xic.inventory_seq        = xir.inventory_seq
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lt_input_order := 0;
            END;
          END IF;
--
          --取込順に最大値を加算
          get_inv_data_rec.input_order := get_inv_data_rec.input_order + lt_input_order;
-- == 2010/05/12 V1.11 Added END   ===============================================================
          -- ===============================
          -- <HHT棚卸結果出力 B-6>
          -- ===============================
          ins_hht_result(
             it_inventory_seq     => lt_inventory_seq                   -- 1.棚卸SEQ
            ,it_interface_id      => get_inv_data_rec.interface_id      -- 2.インターフェースID
            ,it_input_order       => get_inv_data_rec.input_order       -- 3.取込順
            ,it_base_code         => get_inv_data_rec.base_code         -- 4.拠点コード
            ,it_inventory_kbn     => get_inv_data_rec.inventory_kbn     -- 5.棚卸区分
            ,it_inventory_date    => get_inv_data_rec.inventory_date    -- 6.棚卸日
            ,it_warehouse_kbn     => get_inv_data_rec.warehouse_kbn     -- 7.倉庫区分
            ,it_inventory_place   => get_inv_data_rec.inventory_place   -- 8.棚卸場所
            ,it_item_code         => get_inv_data_rec.item_code         -- 9.品目コード
            ,it_case_qty          => get_inv_data_rec.case_qty          --10.ケース数
            ,it_case_in_qty       => get_inv_data_rec.case_in_qty       --11.入り数
            ,it_quantity          => get_inv_data_rec.quantity          --12.本数
            ,it_slip_no           => get_inv_data_rec.slip_no           --13.伝票№
            ,it_quality_goods_kbn => get_inv_data_rec.quality_goods_kbn --14.良品区分
            ,it_receive_date      => get_inv_data_rec.receive_date      --15.受信日時
            ,ov_errbuf            => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
            ,ov_retcode           => lv_retcode                         -- リターン・コード             --# 固定 #
            ,ov_errmsg            => lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
          --正常終了以外の場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          --正常件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        ELSIF (lv_retcode = cv_status_warn) THEN
          -- ===============================
          -- <HHT情報取込エラー出力 B-4>(共通関数)
          -- ===============================
          xxcoi_common_pkg.add_hht_err_list_data(
            iv_base_code            =>  get_inv_data_rec.base_code        -- 1.拠点コード
           ,iv_origin_shipment      =>  get_inv_data_rec.inventory_place  -- 2.出庫側データ
           ,iv_data_name            =>  gv_hht_err_data_name              -- 3.データ名称
           ,id_transaction_date     =>  get_inv_data_rec.inventory_date   -- 4.取引日
           ,iv_entry_number         =>  get_inv_data_rec.slip_no          -- 5.伝票№
           ,iv_party_num            =>  NULL                              -- 6.入庫側データ
           ,iv_performance_by_code  =>  NULL                              -- 7.営業員コード
           ,iv_item_code            =>  get_inv_data_rec.item_code        -- 8.品目コード
           ,iv_error_message        =>  lv_errmsg                         -- 9.エラー内容
           ,ov_errbuf               =>  lv_errbuf                         -- エラー・メッセージ           --# 固定 #
           ,ov_retcode              =>  lv_retcode                        -- リターン・コード             --# 固定 #
           ,ov_errmsg               =>  lv_errmsg);                       -- ユーザー・エラー・メッセージ --# 固定 #
          --正常終了以外の場合
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          --警告(スキップ)件数カウント
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- <棚卸結果ファイルIF削除 B-8>
        -- ===============================
        del_inv_result_file(
           it_interface_id  => get_inv_data_rec.interface_id      --1.インターフェースID
          ,ov_errbuf        => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
          ,ov_retcode       => lv_retcode                         -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
        --正常終了以外の場合
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP inv_data_loop;
      CLOSE get_inv_data_cur;
--
      --対象件数が0件の場合メッセージ出力
      IF (gn_target_cnt = 0) THEN
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_00008
                  );
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
--
      --スキップ件数が１件でもある場合は、リターンコードを警告で返す。
      IF (gn_warn_cnt > 0) THEN
        ov_retcode := cv_status_warn;
      END IF;
      --==================
      --B-9はmainにて記述
      --==================
--
    --ファイルアップロード画面起動
    ELSE
      -- =======================================
      -- <ファイルアップロードI/Fデータ取得 B-10>
      -- =======================================
      get_uplode_data(
        in_file_id  =>  in_file_id          -- ファイルID
       ,ov_errbuf   =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  =>  lv_retcode          -- リターン・コード             --# 固定 #
       ,ov_errmsg   =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      --ファイルアップロード一時表取得カーソルオープン
      OPEN get_tmp_cur(in_file_id);
      <<tmp_data_loop>>
      LOOP
        FETCH get_tmp_cur INTO get_tmp_rec;
        --次データがなくなったら終了
        EXIT WHEN get_tmp_cur%NOTFOUND;
        --対象件数加算
        gn_target_cnt := gn_target_cnt + 1;
        -- ===============================
        -- <ファイルデータチェック B-11>
        -- ===============================
        chk_file_data(
           it_order_no        => get_tmp_rec.sort_no                -- 1.取込順
          ,it_base_code       => get_tmp_rec.base_code              -- 2.拠点コード
          ,it_inventory_kbn   => get_tmp_rec.inventory_kbn          -- 3.棚卸区分
          ,it_inventory_date  => get_tmp_rec.inventory_date         -- 4.棚卸日
          ,it_inventory_place => get_tmp_rec.inventory_place        -- 5.棚卸場所
          ,it_warehouse_kbn   => get_tmp_rec.warehouse_kbn          -- 6.倉庫区分
          ,it_item_code       => get_tmp_rec.item_code              -- 7.品目コード
          ,it_receive_date    => get_tmp_rec.receive_date           -- 8.受信日時
          ,it_case_qty        => get_tmp_rec.case_qty               -- 9.ケース数
          ,it_case_in_qty     => get_tmp_rec.case_in_qty            --10.入数
          ,it_quantity        => get_tmp_rec.quantity               --11.本数
          ,ov_errbuf          => lv_errbuf                          -- エラー・メッセージ           --# 固定 #
          ,ov_retcode         => lv_retcode                         -- リターン・コード             --# 固定 #
          ,ov_errmsg          => lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
--
        --正常終了(エラーなし)なら実施
        IF (lv_retcode = cv_status_normal) THEN
          -- ===============================
          -- <棚卸結果ファイルIF出力 B-12>
          -- ===============================
          ins_result_file(
             it_order_no            => get_tmp_rec.sort_no            -- 1.取込順
            ,it_base_code           => get_tmp_rec.base_code          -- 2.拠点コード
            ,it_inventory_kbn       => get_tmp_rec.inventory_kbn      -- 3.棚卸区分
            ,it_inventory_date      => get_tmp_rec.inventory_date     -- 4.棚卸日
            ,it_warehouse_kbn       => get_tmp_rec.warehouse_kbn      -- 5.倉庫区分
            ,it_inventory_place     => get_tmp_rec.inventory_place    -- 6.棚卸場所
            ,it_item_code           => get_tmp_rec.item_code          -- 7.品目コード
            ,it_case_qty            => get_tmp_rec.case_qty           -- 8.ケース数
            ,it_case_in_qty         => get_tmp_rec.case_in_qty        -- 9.入数
            ,it_quantity            => get_tmp_rec.quantity           --10.本数
            ,it_slip_no             => get_tmp_rec.slip_no            --11.伝票№
            ,it_quality_goods_kbn   => get_tmp_rec.quality_goods_kbn  --12.良品区分
            ,it_receive_date        => get_tmp_rec.receive_date       --13.受信日時
            ,ov_errbuf              => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
            ,ov_retcode             => lv_retcode                     -- リターン・コード             --# 固定 #
            ,ov_errmsg              => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          --正常件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        ELSIF (lv_retcode = cv_status_warn) THEN
          --警告件数カウント
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP tmp_data_loop;
      CLOSE get_tmp_cur;
--
      -- ========================================
      -- <ファイルアップロードI/Fデータ削除 B-13>
      -- ========================================
      del_uplode_data(
        in_file_id  => in_file_id          -- ファイルID
       ,ov_errbuf   => lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode          -- リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      --スキップ件数が１件でもある場合は、リターンコードを警告で返す。
      IF (gn_warn_cnt > 0) THEN
        ov_retcode := cv_status_warn;
      END IF;
      --==================
      --B-14はmainにて記述
      --==================
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    --*** 棚卸結果ファイルIFロック取得エラー ***
    WHEN lock_expt THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10141
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_inv_data_cur%ISOPEN) THEN
        CLOSE get_inv_data_cur;
      END IF;
      --
      IF (get_tmp_cur%ISOPEN) THEN
        CLOSE get_tmp_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf            OUT   VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode           OUT   VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_id        IN    VARCHAR2,      -- 1.FILE_ID
    iv_format_pattern IN    VARCHAR2       -- 2.フォーマットパターン
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
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_file_id         NUMBER;
    --
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
    ln_file_id  := TO_NUMBER(iv_file_id);
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       in_file_id         =>  ln_file_id          -- 1.FILE_ID
      ,iv_format_pattern  =>  iv_format_pattern   -- 2.フォーマットパターン
      ,ov_errbuf          =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         =>  lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg          =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NOT NULL) THEN
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
                     iv_application  => cv_appl_short_name
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
END XXCOI006A21C;
/
