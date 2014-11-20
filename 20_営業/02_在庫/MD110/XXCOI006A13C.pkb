CREATE OR REPLACE PACKAGE BODY XXCOI006A13C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A13C(body)
 * Description      : 棚卸減耗データ作成
 * MD.050           : 棚卸減耗データ作成 <MD050_COI_A13>
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_mst_data           マスタチェック(A-3)
 *  get_disposition_id     勘定科目別名ID取得(A-4)
 *  ins_tran_interface     資材取引OIF出力(A-5)
 *  upd_inv_control        棚卸管理更新(A-6)
 *  submain                メイン処理プロシージャ
 *                         棚卸減耗情報抽出(A-2)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   N.Abe            新規作成
 *  2009/05/08    1.1   T.Nakamura       [T1_0782]異常終了時に成功件数を0とするよう修正
 *  2009/06/03    1.2   H.Sasaki         [T1_1202]保管場所マスタの結合条件に在庫組織IDを追加
 *  2009/06/26    1.3   H.Sasaki         [0000258]棚卸対象外を処理対象とする
 *  2009/07/14    1.4   H.Sasaki         [0000679]棚卸減耗情報抽出カーソルのPT対応
 *  2009/07/29    1.5   N.Abe            [0000638]単位の取得項目修正
 *  2009/12/17    1.6   N.Abe            [E_本稼動_00508]品目ステータス、売上対象区分チェックの修正
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
  org_code_expt            EXCEPTION;     -- 在庫組織コード取得エラー
  org_id_expt              EXCEPTION;     -- 在庫組織ID取得エラー
  lock_expt                EXCEPTION;     -- ロック取得エラー
-- == 2009/12/17 V1.6 Deleted START ===============================================================
--  chk_item_expt            EXCEPTION;     -- 品目ステータス有効チェックエラー
--  chk_sales_item_expt      EXCEPTION;     -- 品目売上対象区分有効チェックエラー
-- == 2009/12/17 V1.6 Deleted END   ===============================================================
  genmou_son_expt          EXCEPTION;     -- 棚卸減耗損取引タイプ名取得エラー
  genmou_eki_expt          EXCEPTION;     -- 棚卸減耗益取引タイプ名取得エラー
  tran_id_expt             EXCEPTION;     -- 取引タイプ取得エラー
  dispo_id_expt            EXCEPTION;     -- 勘定科目別名ID取得エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100)  := 'XXCOI006A13C';        -- パッケージ名
--
  cv_xxcoi_short_name   CONSTANT VARCHAR2(10)   := 'XXCOI';               -- アドオン：販物・在庫領域
  --メッセージ
  cv_xxcoi1_msg_10144   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10144';    --棚卸管理ロックエラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    on_organization_id  OUT NUMBER,                                         -- 1.在庫組織ID
    ov_period_date      OUT VARCHAR2,                                       -- 2.会計期間
    ot_tran_id_son      OUT mtl_transaction_types.transaction_type_id%TYPE, -- 3.取引ID（棚卸減耗損）
    ot_tran_id_eki      OUT mtl_transaction_types.transaction_type_id%TYPE, -- 4.取引ID（棚卸減耗益）
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
    cv_xxcoi1_msg_00023   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00023';  --コンカレントパラメータなし
    cv_xxcoi1_msg_00005   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00005';  --在庫組織コード取得エラー
    cv_xxcoi1_msg_00006   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00006';  --在庫組織ID取得エラー
    cv_xxcoi1_msg_10301   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10301';  --棚卸減耗損取引タイプ名取得エラー
    cv_xxcoi1_msg_10302   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10302';  --棚卸減耗益取引タイプ名取得エラー
    cv_xxcoi1_msg_00012   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00012';  --取引タイプ取得エラー
    --トークン
    cv_tkn_pro            CONSTANT  VARCHAR2(7)   := 'PRO_TOK';
    cv_tkn_org_code       CONSTANT  VARCHAR2(12)  := 'ORG_CODE_TOK';
    cv_tkn_tran_type      CONSTANT  VARCHAR2(20)  := 'TRANSACTION_TYPE_TOK';
    --プロファイル
    cv_prf_org_code       CONSTANT  VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';    --在庫組織コード
    cv_prf_genmou_son     CONSTANT  VARCHAR2(27)  := 'XXCOI1_TRAN_NAME_GENMOU_SON'; --棚卸減耗損取引タイプ名
    cv_prf_genmou_eki     CONSTANT  VARCHAR2(27)  := 'XXCOI1_TRAN_NAME_GENMOU_EKI'; --棚卸減耗益取引タイプ名
--
    cv_ym                 CONSTANT  VARCHAR2(6)   := 'YYYYMM';
    cv_y                  CONSTANT  VARCHAR2(1)   := 'Y';
    -- *** ローカル変数 ***
    lv_organization_code  VARCHAR2(4);                                      --在庫組織コード
    ln_organization_id    NUMBER;                                           --在庫組織ID
    lt_tran_son           mtl_transaction_types.transaction_type_name%TYPE; --棚卸減耗損取引タイプ名
    lt_tran_eki           mtl_transaction_types.transaction_type_name%TYPE; --棚卸減耗益取引タイプ名
    lt_tran_name          mtl_transaction_types.transaction_type_name%TYPE; --エラー取引タイプ名
    lt_tran_id_son        mtl_transaction_types.transaction_type_id%TYPE;   --棚卸減耗損取引タイプID
    lt_tran_id_eki        mtl_transaction_types.transaction_type_id%TYPE;   --棚卸減耗益取引タイプID
--
    -- *** ローカル・カーソル ***
    --在庫会計期間取得
    CURSOR get_period_date_cur(in_organization_id IN NUMBER)
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
    --====================
    --1.入力パラメータ出力
    --====================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00023
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --====================================
    --2.プロファイルから在庫組織コードを取得
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
--
    IF (lv_organization_code IS NULL) THEN
      RAISE org_code_expt;
    END IF;
--
    --====================================
    --3.在庫組織コードから在庫組織IDを取得
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
--
    IF (ln_organization_id IS NULL) THEN
      RAISE org_id_expt;
    END IF;
--
    --====================================
    --4.オープン在庫会計期間取得
    --====================================
    OPEN get_period_date_cur(
            in_organization_id  => ln_organization_id);
    FETCH get_period_date_cur INTO get_period_date_rec;
    CLOSE get_period_date_cur;
--
    --====================================
    --5.WHO列取得
    --====================================
    --変数宣言時にデフォルトで取得
--
    --====================================
    --6.取引タイプ名取得
    --====================================
    --棚卸減耗損
    lt_tran_son := FND_PROFILE.VALUE(cv_prf_genmou_son);
--
    IF (lt_tran_son IS NULL) THEN
      RAISE genmou_son_expt;
    END IF;
    --棚卸減耗益
    lt_tran_eki := FND_PROFILE.VALUE(cv_prf_genmou_eki);
--
    IF (lt_tran_eki IS NULL) THEN
      RAISE genmou_eki_expt;
    END IF;
--
    --====================================
    --7.取引タイプID取得
    --====================================
    --棚卸減耗損
    lt_tran_id_son  :=  xxcoi_common_pkg.get_transaction_type_id(lt_tran_son);
--
    IF (lt_tran_id_son IS NULL) THEN
      lt_tran_name := lt_tran_son;
      RAISE tran_id_expt;
    END IF;
--
    --棚卸減耗益
    lt_tran_id_eki  :=  xxcoi_common_pkg.get_transaction_type_id(lt_tran_eki);
--
    IF (lt_tran_id_eki IS NULL) THEN
      lt_tran_name := lt_tran_eki;
      RAISE tran_id_expt;
    END IF;
--
    --OUTパラメータに設定
    on_organization_id := ln_organization_id;
    ov_period_date     := get_period_date_rec.period_date;
    ot_tran_id_son     := lt_tran_id_son;
    ot_tran_id_eki     := lt_tran_id_eki;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
    --*** 棚卸減耗損取引タイプ名取得エラー ***
    WHEN genmou_son_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10301
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_genmou_son
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 棚卸減耗益取引タイプ名取得エラー ***
    WHEN genmou_eki_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10302
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_genmou_eki
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 取引タイプ取得エラー ***
    WHEN tran_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00012
                 ,iv_token_name1  => cv_tkn_tran_type
                 ,iv_token_value1 => lt_tran_name
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
   * Procedure Name   : chk_mst_data
   * Description      : マスタチェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_mst_data(
    it_inventory_item_id  IN  mtl_system_items_b.inventory_item_id%TYPE,          -- 1.品目ID
    in_organization_id    IN  NUMBER,                                             -- 2.在庫組織ID
-- == 2009/07/29 V1.5 Modified START ===============================================================
--    ov_primary_unit       OUT VARCHAR2,                                           -- 3.基準単位
    ov_primary_uom_code   OUT VARCHAR2,                                           -- 3.基準単位コード
-- == 2009/07/29 V1.5 Modified END   ===============================================================
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ               --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード                 --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ     --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_mst_data'; -- プログラム名
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
-- == 2009/12/17 V1.6 Modified START ===============================================================
--    cv_xxcoi1_msg_10291   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10291';  --品目ステータス有効エラー
--    cv_xxcoi1_msg_10229   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10229';  --品目売上対象区分エラー
    cv_xxcoi1_msg_10409   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10409';  --品目ステータスチェックエラー
    cv_xxcoi1_msg_10410   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10410';  --売上対象区分チェックエラー
-- == 2009/12/17 V1.6 Modified END   ===============================================================
    --トークン
    cv_tkn_item_code      CONSTANT VARCHAR2(9)  := 'ITEM_CODE';
-- == 2009/12/17 V1.6 Added START ===============================================================
    cv_tkn_item_status    CONSTANT VARCHAR2(11) := 'ITEM_STATUS';
    cv_tkn_cust_order     CONSTANT VARCHAR2(10) := 'CUST_ORDER';
    cv_tkn_trn_enable     CONSTANT VARCHAR2(10) := 'TRN_ENABLE';
    cv_tkn_stock_enable   CONSTANT VARCHAR2(12) := 'STOCK_ENABLE';
    cv_tkn_return_enable  CONSTANT VARCHAR2(13) := 'RETURN_ENABLE';
-- == 2009/12/17 V1.6 Added END   ===============================================================
    --コード＆フラグ
    cv_inactive           CONSTANT VARCHAR2(8)  := 'Inactive';
    cv_n                  CONSTANT VARCHAR2(1)  := 'N';
    cv_1                  CONSTANT VARCHAR2(1)  := '1';
    cv_2                  CONSTANT VARCHAR2(1)  := '2';
--
    -- *** ローカル変数 ***
--
    --品目情報取得用
    lt_item_code          mtl_system_items_b.segment1%TYPE;                       --品目コード
    lt_item_status        mtl_system_items_b.inventory_item_status_code%TYPE;     --品目ステータス
    lt_cust_order_flg     mtl_system_items_b.customer_order_enabled_flag%TYPE;    --顧客受注可能フラグ
    lt_transaction_enable mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;  --取引可能
    lt_stock_enabled_flg  mtl_system_items_b.stock_enabled_flag%TYPE;             --在庫保有可能フラグ
    lt_return_enable      mtl_system_items_b.returnable_flag%TYPE;                --返品可能
    lt_sales_class        ic_item_mst_b.attribute26%TYPE;                         --売上対象区分
    lt_primary_unit       mtl_system_items_b.primary_unit_of_measure%TYPE;        --基準単位
-- == 2009/07/29 V1.5 Added START ===============================================================
    lt_inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE;              --品目ID
-- == 2009/07/29 V1.5 Added END   ===============================================================
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
    --=============================
    --1.品目コード取得
    --=============================
    BEGIN
      SELECT  msib.segment1
      INTO    lt_item_code
      FROM    mtl_system_items_b  msib
      WHERE   msib.organization_id    = in_organization_id
      AND     msib.inventory_item_id  = it_inventory_item_id
      AND     ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_item_code := NULL;
    END;
--
    --=============================
    --2.品目ステータス取得
    --=============================
-- == 2009/07/29 V1.5 Modified START ===============================================================
--    xxcoi_common_pkg.get_item_info(
--          iv_item_code            =>  lt_item_code          -- 1 .品目コード
--         ,in_org_id               =>  in_organization_id    -- 2 .在庫組織ID
--         ,ov_item_status          =>  lt_item_status        -- 3 .品目ステータス
--         ,ov_cust_order_flg       =>  lt_cust_order_flg     -- 4 .顧客受注可能フラグ
--         ,ov_transaction_enable   =>  lt_transaction_enable -- 5 .取引可能
--         ,ov_stock_enabled_flg    =>  lt_stock_enabled_flg  -- 6 .在庫保有可能フラグ
--         ,ov_return_enable        =>  lt_return_enable      -- 7 .返品可能
--         ,ov_sales_class          =>  lt_sales_class        -- 8 .売上対象区分
--         ,ov_primary_unit         =>  lt_primary_unit       -- 9 .基準単位
--         ,ov_errbuf               =>  lv_errbuf             -- 10.エラーメッセージ
--         ,ov_retcode              =>  lv_retcode            -- 11.リターン・コード
--         ,ov_errmsg               =>  lv_errmsg             -- 12.ユーザー・エラーメッセージ
--        );
    xxcoi_common_pkg.get_item_info2(
          iv_item_code            =>  lt_item_code          -- 1 .品目コード
         ,in_org_id               =>  in_organization_id    -- 2 .在庫組織ID
         ,ov_item_status          =>  lt_item_status        -- 3 .品目ステータス
         ,ov_cust_order_flg       =>  lt_cust_order_flg     -- 4 .顧客受注可能フラグ
         ,ov_transaction_enable   =>  lt_transaction_enable -- 5 .取引可能
         ,ov_stock_enabled_flg    =>  lt_stock_enabled_flg  -- 6 .在庫保有可能フラグ
         ,ov_return_enable        =>  lt_return_enable      -- 7 .返品可能
         ,ov_sales_class          =>  lt_sales_class        -- 8 .売上対象区分
         ,ov_primary_unit         =>  lt_primary_unit       -- 9 .基準単位
         ,on_inventory_item_id    =>  lt_inventory_item_id  -- 10.品目ID
         ,ov_primary_uom_code     =>  ov_primary_uom_code   -- 11.基準単位コード
         ,ov_errbuf               =>  lv_errbuf             -- 12.エラーメッセージ
         ,ov_retcode              =>  lv_retcode            -- 13.リターン・コード
         ,ov_errmsg               =>  lv_errmsg             -- 14.ユーザー・エラーメッセージ
        );
-- == 2009/07/29 V1.5 Modified END   ===============================================================
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --============================
    --3品目ステータスチェック
    --============================
    --品目ステータスが'Inactive'又は
    --顧客受注可能フラグ、取引可能フラグ、在庫保有可能フラグ、返品可能フラグ
    --いずれかが無効('N')に設定されていた場合
    IF ((lt_item_status           = cv_inactive)
      OR  (lt_cust_order_flg     = cv_n)
      OR  (lt_transaction_enable = cv_n)
      OR  (lt_stock_enabled_flg  = cv_n)
      OR  (lt_return_enable      = cv_n))
    THEN
      --品目ステータス有効チェックエラー
-- == 2009/12/17 V1.6 Modified START ===============================================================
--      RAISE chk_item_expt;
      --品目ステータスチェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10409
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => lt_item_code
                 ,iv_token_name2  => cv_tkn_item_status
                 ,iv_token_value2 => lt_item_status
                 ,iv_token_name3  => cv_tkn_cust_order
                 ,iv_token_value3 => lt_cust_order_flg
                 ,iv_token_name4  => cv_tkn_trn_enable
                 ,iv_token_value4 => lt_transaction_enable
                 ,iv_token_name5  => cv_tkn_stock_enable
                 ,iv_token_value5 => lt_stock_enabled_flg
                 ,iv_token_name6  => cv_tkn_return_enable
                 ,iv_token_value6 => lt_return_enable
                );
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg );
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errmsg );
      --
      ov_retcode := cv_status_warn;
-- == 2009/12/17 V1.6 Modified END   ===============================================================
    END IF;
--
    --=============================
    --4.品目売上対象区分チェック
    --=============================
    --NULLの場合もエラーとする。
    IF (NVL(lt_sales_class, cv_2) <> cv_1) THEN
-- == 2009/12/17 V1.6 Modified START ===============================================================
--      --品目売上対象区分有効チェックエラー
--      RAISE chk_sales_item_expt;
      --売上対象区分チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10410
                 ,iv_token_name1  => cv_tkn_item_code
                 ,iv_token_value1 => lt_item_code
                );
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg );
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errmsg );
      --
      ov_retcode := cv_status_warn;
-- == 2009/12/17 V1.6 Modified END   ===============================================================
    END IF;
--
-- == 2009/07/29 V1.5 Deleted START ===============================================================
--    --OUTパラメータに設定
--    ov_primary_unit := lt_primary_unit;
-- == 2009/07/29 V1.5 Deleted END   ===============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- == 2009/12/17 V1.6 Deleted START ===============================================================
--    --*** 品目ステータス有効チェックエラー ***
--    WHEN chk_item_expt THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcoi_short_name
--                 ,iv_name         => cv_xxcoi1_msg_10291
--                 ,iv_token_name1  => cv_tkn_item_code
--                 ,iv_token_value1 => lt_item_code
--                );
--      ov_errmsg  := lv_errmsg;
--      lv_errbuf  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                     --# 任意 #
----
--    --*** 品目売上対象区分有効チェックエラー ***
--    WHEN chk_sales_item_expt THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcoi_short_name
--                 ,iv_name         => cv_xxcoi1_msg_10229
--                 ,iv_token_name1  => cv_tkn_item_code
--                 ,iv_token_value1 => lt_item_code
--                );
--      ov_errmsg  := lv_errmsg;
--      lv_errbuf  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                     --# 任意 #
-- == 2009/12/17 V1.6 Deleted END   ===============================================================
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
  END chk_mst_data;
--
  /**********************************************************************************
   * Procedure Name   : get_disposition_id
   * Description      : 勘定科目別名ID取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_disposition_id(
    it_base_code          IN  xxcoi_inv_reception_monthly.base_code%TYPE,       -- 1.拠点コード
    in_organization_id    IN  NUMBER,                                           -- 2.在庫組織ID
    on_disposition_id     OUT NUMBER,                                           -- 3.勘定科目別名ID
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ             --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード               --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disposition_id'; -- プログラム名
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
    cv_31                 CONSTANT VARCHAR2(2)  := '31';
    --メッセージ
    cv_xxcoi1_msg_00013   CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00013';  --勘定科目別名ID取得エラー
--
    -- *** ローカル変数 ***
    ln_disposition_id     NUMBER;
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
    --1.勘定科目別名IDを共通関数より取得
    --==================================
    ln_disposition_id := xxcoi_common_pkg.get_disposition_id(
                              iv_inv_account_kbn  =>  cv_31
                             ,iv_dept_code        =>  it_base_code
                             ,in_organization_id  =>  in_organization_id
                            );
    IF (ln_disposition_id IS NULL) THEN
      RAISE dispo_id_expt;
    END IF;
    --OUTパラメータに設定
    on_disposition_id := ln_disposition_id;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** 勘定科目別名ID取得エラー ***
    WHEN dispo_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00013
                );
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                     --# 任意 #
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
  END get_disposition_id;
--
  /**********************************************************************************
   * Procedure Name   : ins_tran_interface
   * Description      : 資材取引OIF出力(A-5)
   ***********************************************************************************/
  PROCEDURE ins_tran_interface(
    it_inv_seq            IN  xxcoi_inv_reception_monthly.inv_seq%TYPE,             -- 1.棚卸SEQ
    it_inventory_item_id  IN  xxcoi_inv_reception_monthly.inventory_item_id%TYPE,   -- 2.品目ID
    in_organization_id    IN  NUMBER,                                               -- 3.組織
    in_inv_wear           IN  NUMBER,                                               -- 4.棚卸減耗数
-- == 2009/07/29 V1.4 Modified START ===============================================================
--    it_primary_unit       IN  mtl_system_items_b.primary_unit_of_measure%TYPE,      -- 5.棚卸区分
    it_primary_uom_code   IN  mtl_system_items_b.primary_uom_code%TYPE,             -- 5.基準単位コード
-- == 2009/07/29 V1.4 Modified END   ===============================================================
    iv_period_date        IN  VARCHAR2,                                             -- 6.棚卸日
    it_subinventory_code  IN  xxcoi_inv_reception_monthly.subinventory_code%TYPE,   -- 7.保管場所
    it_tran_id_eki        IN  mtl_transaction_types.transaction_type_id%TYPE,       -- 8.棚卸減耗益
    it_tran_id_son        IN  mtl_transaction_types.transaction_type_id%TYPE,       -- 9.棚卸減耗損
    in_disposition_id     IN  NUMBER,                                               --10.勘定科目別名ID
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ                 --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード                   --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ       --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_tran_interface'; -- プログラム名
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
    cv_1            CONSTANT VARCHAR2(1)  := '1';
    cv_3            CONSTANT VARCHAR2(1)  := '3';
    cv_source_code  CONSTANT VARCHAR2(12) := 'XXCOI006A13C';
    cv_ym           CONSTANT VARCHAR2(6)  := 'YYYYMM';
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
    --資材取引OIFへ登録
    INSERT INTO mtl_transactions_interface(
       process_flag             -- 1.プロセスフラグ
      ,transaction_mode         -- 2.取引モード
      ,source_code              -- 3.ソースコード
      ,source_header_id         -- 4.ソースヘッダID
      ,source_line_id           -- 5.ソースラインID
      ,inventory_item_id        -- 6.品目ID
      ,organization_id          -- 7.在庫組織ID
      ,transaction_quantity     -- 8.取引数量
      ,primary_quantity         -- 9.基準単位数量
      ,transaction_uom          --10.取引単位コード
      ,transaction_date         --11.取引日
      ,subinventory_code        --12.保管場所
      ,transaction_type_id      --13.取引タイプID
      ,transaction_source_id    --14.取引ソースID
      ,last_update_date         --15.最終更新日
      ,last_updated_by          --16.最終更新者
      ,creation_date            --17.作成日
      ,created_by               --18.作成者
      ,last_update_login        --19.最終更新ユーザ
      ,request_id               --20.要求ID
      ,program_application_id   --21.プログラム・アプリケーションID
      ,program_id               --22.プログラムID
      ,program_update_date      --23.プログラム更新日
    )VALUES(
       cv_1                                     -- 1.プロセスフラグ
      ,cv_3                                     -- 2.取引モード
      ,cv_source_code                           -- 3.ソースコード
      ,it_inv_seq                               -- 4.ソースヘッダID
      ,1                                        -- 5.ソースラインID
      ,it_inventory_item_id                     -- 6.品目ID
      ,in_organization_id                       -- 7.在庫組織ID
      ,in_inv_wear                              -- 8.取引数量
      ,in_inv_wear                              -- 9.基準単位数量
-- == 2009/07/29 V1.5 Modified START ===============================================================
--      ,it_primary_unit                          --10.取引単位
      ,it_primary_uom_code                      --10.基準単位コード
-- == 2009/07/29 V1.5 Modified END   ===============================================================
      ,LAST_DAY(TO_DATE(iv_period_date, cv_ym)) --11.取引日
      ,it_subinventory_code                     --12.保管場所
      ,DECODE(SIGN(in_inv_wear), -1, it_tran_id_son, it_tran_id_eki)
                                                --13.取引タイプID
      ,in_disposition_id                        --14.取引ソースID
      ,SYSDATE                                  --15.最終更新日
      ,cn_last_updated_by                       --16.最終更新者
      ,SYSDATE                                  --17.作成日
      ,cn_created_by                            --18.作成者
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
  END ins_tran_interface;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_control
   * Description      : 棚卸管理更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_inv_control(
    iv_period_date        IN  VARCHAR,      --   1.在庫会計期間(年月)
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_control'; -- プログラム名
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
    cv_2      CONSTANT VARCHAR2(1)  := '2';
    cv_9      CONSTANT VARCHAR2(1)  := '9';
--
    -- *** ローカル変数 ***
-- == 2009/07/14 V1.4 Added START ===============================================================
    ln_dummy  NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR  record_rock_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_control   xic
      WHERE   xic.inventory_year_month    = iv_period_date    --年月 = 会計期間の年月
      AND     xic.inventory_kbn           = cv_2              --棚卸区分 = 2(月末)
      FOR UPDATE NOWAIT;
-- == 2009/07/14 V1.4 Added END   ===============================================================
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
-- == 2009/07/14 V1.4 Added START ===============================================================
    -- ロック処理を実行
    OPEN  record_rock_cur;
-- == 2009/07/14 V1.4 Added END   ===============================================================
    --
    --棚卸管理テーブル更新
    UPDATE  xxcoi_inv_control xic
    SET     xic.inventory_status        = cv_9
           ,xic.last_update_date        = SYSDATE
           ,xic.last_updated_by         = cn_last_updated_by
           ,xic.last_update_login       = cn_last_update_login
           ,xic.request_id              = cn_request_id
           ,xic.program_application_id  = cn_program_application_id
           ,xic.program_id              = cn_program_id
           ,xic.program_update_date     = SYSDATE
    WHERE   xic.inventory_year_month    = iv_period_date    --年月 = 会計期間の年月
    AND     xic.inventory_kbn           = cv_2              --棚卸区分 = 2(月末)
    ;
-- == 2009/07/14 V1.4 Added START ===============================================================
    CLOSE record_rock_cur;
-- == 2009/07/14 V1.4 Added END   ===============================================================
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
-- == 2009/07/14 V1.4 Added START ===============================================================
    --*** 棚卸管理ロック取得エラー ***
    WHEN lock_expt THEN
      IF (record_rock_cur%ISOPEN) THEN
        CLOSE record_rock_cur;
      END IF;
      --メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10144
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
-- == 2009/07/14 V1.4 Added END   ===============================================================
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (record_rock_cur%ISOPEN) THEN
        CLOSE record_rock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (record_rock_cur%ISOPEN) THEN
        CLOSE record_rock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (record_rock_cur%ISOPEN) THEN
        CLOSE record_rock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    --
    cv_2                  CONSTANT  VARCHAR2(1)   := '2';
    cv_9                  CONSTANT  VARCHAR2(1)   := '9';
--
    -- *** ローカル変数 ***
--
    lt_old_base_code      xxcoi_inv_reception_monthly.base_code%TYPE;           --OLD拠点コード
    --
    ln_organization_id    NUMBER;                                               --在庫組織ID
    lv_period_date        VARCHAR2(6);                                          --在庫会計期間
    lt_tran_id_son        mtl_transaction_types.transaction_type_id%TYPE;       --取引タイプID（棚卸減耗損）
    lt_tran_id_eki        mtl_transaction_types.transaction_type_id%TYPE;       --取引タイプID（棚卸減耗益）
    --
-- == 2009/07/29 V1.5 Modified START ===============================================================
--    lt_primary_unit       mtl_system_items_b.primary_unit_of_measure%TYPE;      --基準単位
    lt_primary_uom_code   mtl_system_items_b.primary_uom_code%TYPE;             --基準単位コード
-- == 2009/07/29 V1.5 Modified END   ===============================================================
    ln_disposition_id     NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    --棚卸減耗情報抽出
    CURSOR get_month_data_cur(
                  in_organization_id  IN NUMBER
                 ,iv_period_date      IN VARCHAR2)
    IS
-- == 2009/07/14 V1.4 Modified START ===============================================================
--      SELECT
--                xirm.inv_seq                                  --棚卸SEQ
--               ,xirm.base_code                                --拠点コード
--               ,xirm.organization_id                          --組織ID
--               ,xirm.subinventory_code                        --保管場所コード
--               ,xirm.inventory_item_id                        --品目ID
--               ,(xirm.inv_wear * -1)  inv_wear                --棚卸減耗
--      FROM      xxcoi_inv_reception_monthly xirm              --月次在庫受払表
--               ,xxcoi_inv_control           xic               --棚卸管理
--               ,mtl_secondary_inventories   msi               --保管場所マスタ
--      WHERE     xirm.organization_id    = in_organization_id
--      AND       xirm.inventory_kbn      = cv_2                --棚卸区分 = '2'(月末)
--      AND       xirm.practice_month     = iv_period_date      --年月 = 会計期間年月
--      AND       xirm.inv_wear          <> 0                   --棚卸減耗 <> 0
--      AND       xirm.inv_seq            = xic.inventory_seq
--      AND       xirm.subinventory_code  = msi.secondary_inventory_name
---- == 2009/06/03 V1.2 Added START ===============================================================
--      AND       xirm.organization_id    = msi.organization_id
---- == 2009/06/03 V1.2 Added END   ===============================================================
---- == 2009/06/26 V1.3 Deleted START ===============================================================
----      AND       msi.attribute5         <> cv_9                --棚卸対象 <> '9'(対象外)
---- == 2009/06/26 V1.3 Deleted END   ===============================================================
--      ORDER BY  xirm.base_code
--               ,xirm.subinventory_code
--      FOR UPDATE OF xic.inventory_seq NOWAIT
--      ;
--
      SELECT
                xirm.inv_seq                                  --棚卸SEQ
               ,xirm.base_code                                --拠点コード
               ,xirm.organization_id                          --組織ID
               ,xirm.subinventory_code                        --保管場所コード
               ,xirm.inventory_item_id                        --品目ID
               ,(xirm.inv_wear * -1)  inv_wear                --棚卸減耗
      FROM      xxcoi_inv_reception_monthly xirm              --月次在庫受払表
      WHERE     xirm.organization_id    = in_organization_id
      AND       xirm.inventory_kbn      = cv_2                --棚卸区分 = '2'(月末)
      AND       xirm.practice_month     = iv_period_date      --年月 = 会計期間年月
      AND       xirm.inv_wear          <> 0                   --棚卸減耗 <> 0
      ORDER BY  xirm.base_code
               ,xirm.subinventory_code;
-- == 2009/07/14 V1.4 Modified END   ===============================================================
    -- <カーソル名>レコード型
    get_month_data_rec get_month_data_cur%ROWTYPE;
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
    -- <初期処理 A-1>
    -- ===============================
    init(
      on_organization_id  =>  ln_organization_id  -- 1.在庫組織コード
     ,ov_period_date      =>  lv_period_date      -- 2.在庫会計期間
     ,ot_tran_id_son      =>  lt_tran_id_son      -- 3.取引ID（棚卸減耗損）
     ,ot_tran_id_eki      =>  lt_tran_id_eki      -- 4.取引ID（棚卸減耗益）
     ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <棚卸減耗情報抽出 A-2>
    -- ===============================
    --棚卸減耗データ取得カーソルオープン
    OPEN get_month_data_cur(
          in_organization_id  => ln_organization_id
         ,iv_period_date      => lv_period_date);
    <<month_data_loop>>
    LOOP
      FETCH get_month_data_cur INTO get_month_data_rec;
      --次データがなくなったら終了
      EXIT WHEN get_month_data_cur%NOTFOUND;
      --対象件数加算
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- <マスタチェック A-3>
      -- ===============================
      chk_mst_data(
         it_inventory_item_id => get_month_data_rec.inventory_item_id -- 1.品目ID
        ,in_organization_id   => ln_organization_id                   -- 2.在庫組織ID
-- == 2009/07/29 V1.5 Modified START ===============================================================
--        ,ov_primary_unit      => lt_primary_unit                      -- 3.基準単位
        ,ov_primary_uom_code  => lt_primary_uom_code                  -- 3.基準単位コード
-- == 2009/07/29 V1.5 Modified END   ===============================================================
        ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 #
        ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
        ,ov_errmsg            => lv_errmsg);                          -- ユーザー・エラー・メッセージ --# 固定 #
-- == 2009/12/17 V1.6 Modified START ===============================================================
--      IF (lv_retcode <> cv_status_normal) THEN
--      -- 正常終了以外
--        RAISE global_process_expt;
--      END IF;
      IF (lv_retcode = cv_status_error) THEN
        -- 異常終了
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        --警告終了
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
-- == 2009/12/17 V1.6 Modified END ===============================================================
--
      --1件目のレコード又は、前レコードと拠点コードが違う場合
      IF    ((lt_old_base_code IS NULL)
        OR  (get_month_data_rec.base_code <> lt_old_base_code))
      THEN
        -- ===============================
        -- <勘定科目別名ID取得 A-4>
        -- ===============================
        get_disposition_id(
           it_base_code         => get_month_data_rec.base_code   -- 1.拠点コード
          ,in_organization_id   => ln_organization_id             -- 2.在庫組織ID
          ,on_disposition_id    => ln_disposition_id              -- 3.勘定科目別名ID
          ,ov_errbuf            => lv_errbuf                      -- エラー・メッセージ           --# 固定 #
          ,ov_retcode           => lv_retcode                     -- リターン・コード             --# 固定 #
          ,ov_errmsg            => lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> cv_status_normal) THEN
        --エラー終了時
          RAISE global_process_expt;
        END IF;
        --変数に値を格納
        lt_old_base_code    := get_month_data_rec.base_code;
      END IF;
--
      -- ===============================
      -- <資材取引OIF出力 A-5>
      -- ===============================
      ins_tran_interface(
         it_inv_seq           => get_month_data_rec.inv_seq           -- 1.棚卸SEQ
        ,it_inventory_item_id => get_month_data_rec.inventory_item_id -- 2.品目ID
        ,in_organization_id   => ln_organization_id                   -- 3.在庫組織ID
        ,in_inv_wear          => get_month_data_rec.inv_wear          -- 4.棚卸減耗
-- == 2009/07/29 V1.5 Modified START ===============================================================
--        ,it_primary_unit      => lt_primary_unit                      -- 5.基準単位
        ,it_primary_uom_code  => lt_primary_uom_code                  -- 5.基準単位コード
-- == 2009/07/29 V1.5 Modified END   ===============================================================
        ,iv_period_date       => lv_period_date                       -- 6.在庫会計期間
        ,it_subinventory_code => get_month_data_rec.subinventory_code -- 7.保管場所
        ,it_tran_id_eki       => lt_tran_id_eki                       -- 8.棚卸減耗益
        ,it_tran_id_son       => lt_tran_id_son                       -- 9.棚卸減耗損
        ,in_disposition_id    => ln_disposition_id                    --10.勘定科目別名ID
        ,ov_errbuf            => lv_errbuf                            -- エラー・メッセージ           --# 固定 #
        ,ov_retcode           => lv_retcode                           -- リターン・コード             --# 固定 #
        ,ov_errmsg            => lv_errmsg);                          -- ユーザー・エラー・メッセージ --# 固定 #
      --警告終了の場合
      IF (lv_retcode <> cv_status_normal) THEN
      --エラー終了時
        RAISE global_process_expt;
      END IF;
      --正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP month_data_loop;
    CLOSE get_month_data_cur;
--
    --対象件数0件なら棚卸管理を更新しない
    IF (gn_target_cnt <> 0) THEN
      -- ===============================
      -- <棚卸管理更新 A-6>
      -- ===============================
      upd_inv_control(
         iv_period_date       => lv_period_date   -- 1.在庫会計期間
        ,ov_errbuf            => lv_errbuf        -- エラー・メッセージ           --# 固定 #
        ,ov_retcode           => lv_retcode       -- リターン・コード             --# 固定 #
        ,ov_errmsg            => lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
      --===========================
      --終了処理 A-7はmainにて記述
      --===========================
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
-- == 2009/07/14 V1.4 Deleted START ===============================================================
--    --*** 棚卸管理ロック取得エラー ***
--    WHEN lock_expt THEN
--      IF (get_month_data_cur%ISOPEN) THEN
--        CLOSE get_month_data_cur;
--      END IF;
--      --エラー件数カウント
--      gn_error_cnt := gn_error_cnt + 1;
--      --メッセージ取得
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcoi_short_name
--                 ,iv_name         => cv_xxcoi1_msg_10144
--                );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                                            --# 任意 #
-- == 2009/07/14 V1.4 Deleted END   ===============================================================
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_month_data_cur%ISOPEN) THEN
        CLOSE get_month_data_cur;
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
    retcode           OUT   VARCHAR2       --   リターン・コード    --# 固定 #
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
       ov_errbuf          =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
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
-- == 2009/05/08 V1.1 Added START ==================================================================
      -- 成功件数をリセット
      gn_normal_cnt := 0;
-- == 2009/05/08 V1.1 Added END   ==================================================================
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
-- == 2009/12/17 V1.6 Added START ===============================================================
    IF    ( (gn_warn_cnt > 0)
      AND   (lv_retcode = cv_status_normal)
          )
    THEN
      lv_retcode := cv_status_warn;
    END IF;
-- == 2009/12/17 V1.6 Added END   ===============================================================
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
END XXCOI006A13C;
/
