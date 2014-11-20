CREATE OR REPLACE PACKAGE BODY XXCOI006A24R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI006A24R(body)
 * Description      : 受払残高表（営業員別計）
 * MD.050           : 受払残高表（営業員別計） <MD050_COI_A24>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  ins_work_data          ワークテーブルデータ登録(A-3)
 *  ins_svf_data           帳票用ワークテーブルデータ登録(A-4)
 *  call_output_svf        SVF起動(A-5)
 *  del_svf_data           ワークテーブルデータ削除(A-6)
 *  submain                メイン処理プロシージャ
 *                         ワークデータ取得(A-2)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/04/08    1.0   SCSK 中野        新規作成
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
  select_expt               EXCEPTION;  -- データ抽出例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOI006A24R'; -- パッケージ名
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アドオン：販物・在庫領域
  --日付変換用
  cv_ymd              CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_ymd_sla          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_ym_sla           CONSTANT VARCHAR2(7)   := 'YYYY/MM';
  cv_ym               CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_replace_sign     CONSTANT VARCHAR2(1)   := '/';
  --顧客区分用
  cv_class_code_1     CONSTANT VARCHAR2(1)   := '1';  --拠点
  --保管場所区分用
  cv_hkn_kbn_car      CONSTANT VARCHAR2(1)   := '2';  --営業車
  --棚卸区分用
  cv_1                CONSTANT VARCHAR2(1)   := '1';  --月中
  cv_2                CONSTANT VARCHAR2(1)   := '2';  --月末
  --棚卸区分用
  cv_10               CONSTANT VARCHAR2(2)   := '10'; --日次
  cv_20               CONSTANT VARCHAR2(2)   := '20'; --月中
  cv_30               CONSTANT VARCHAR2(2)   := '30'; --月末
  --メッセージ
  cv_xxcoi1_msg_00008 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00008';  --対象データなし
  cv_xxcoi1_msg_10330 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10330';  --パラメータ棚卸区分
  cv_xxcoi1_msg_10099 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10099';  --パラメータ棚卸日
  cv_xxcoi1_msg_10100 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10100';  --パラメータ棚卸月
  cv_xxcoi1_msg_10096 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10096';  --パラメータ拠点
  cv_xxcoi1_msg_00011 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00011';  --業務処理日付
  cv_xxcoi1_msg_10105 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10105';  --棚卸月の型チェック
  cv_xxcoi1_msg_10106 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10106';  --拠点有効チェック
  cv_xxcoi1_msg_00005 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00005';  --在庫組織コード
  cv_xxcoi1_msg_00006 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00006';  --在庫組織ID
  cv_xxcoi1_msg_10197 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10197';  --棚卸日未来日チェックエラーメッセージ
  cv_xxcoi1_msg_10198 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10198';  --棚卸月未来日チェックエラーメッセージ
  cv_xxcoi1_msg_00026 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00026';  --在庫会計期間取得エラーメッセージ
  cv_xxcoi1_msg_10451 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10451';  --在庫確定印字文字取得エラーメッセージ
  cv_xxcoi1_msg_10088 CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10088';  --帳票出力エラー
  --参照タイプ
  cv_lk_list_out_div  CONSTANT VARCHAR2(20)  := 'XXCOI1_INVENTORY_DIV';      --受払表棚卸区分
  --プロファイル
  cv_prf_org_code     CONSTANT VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';  --在庫組織コード
  cv_inv_cl_char      CONSTANT VARCHAR2(24)  := 'XXCOI1_INV_CL_CHARACTER';   --在庫確定印字文字
  -- SVF起動関数パラメータ用
  cv_conc_name        CONSTANT VARCHAR2(30)  := 'XXCOI006A24R';              --コンカレント名
  cv_type_pdf         CONSTANT VARCHAR2(4)   := '.pdf';                      --拡張子（PDF）
  cv_file_id          CONSTANT VARCHAR2(30)  := 'XXCOI006A24R';              --帳票ID
  cv_output_mode      CONSTANT VARCHAR2(30)  := '1';                         --出力区分
  cv_frm_file         CONSTANT VARCHAR2(30)  := 'XXCOI006A24S.xml';          --フォーム様式ファイル名
  cv_vrq_file         CONSTANT VARCHAR2(30)  := 'XXCOI006A24S.vrq';          --クエリー様式ファイル名
  --トークン
  cv_tkn_inv_type     CONSTANT VARCHAR2(16)  := 'P_INVENTORY_TYPE';          --トークン棚卸区分
  cv_tkn_inv_date     CONSTANT VARCHAR2(16)  := 'P_INVENTORY_DATE';          --トークン棚卸日
  cv_tkn_inv_month    CONSTANT VARCHAR2(17)  := 'P_INVENTORY_MONTH';         --トークン棚卸月
  cv_tkn_base_code    CONSTANT VARCHAR2(11)  := 'P_BASE_CODE';               --トークン拠点
  cv_tkn_pro          CONSTANT VARCHAR2(7)   := 'PRO_TOK';                   --トークンプロファイル名
  cv_tkn_org_code     CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';              --トークン在庫組織コード
  cv_tkn_target       CONSTANT VARCHAR2(11)  := 'TARGET_DATE';               --トークン対象日
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;                                   -- 業務処理日付
  gd_target_date        DATE;                                   -- 取得対象日付
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --受払残高表（日次）
  CURSOR daily_cur(
            iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT
              /*+ leading(msi papf xird) */
              papf.employee_number                emp_no              -- 営業員コード
             ,SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)
                                                  emp_name            -- 営業員名称（漢字姓＋漢字名）
             ,xird.operation_cost                 operation_cost      -- 営業原価
             ,xird.previous_inventory_quantity    month_begin_qty     -- 月首棚卸高
             ,xird.warehouse_stock          +                         -- 倉庫より入庫
              xird.vd_supplement_stock                                -- 消化VD補充入庫
                                                  vd_sp_stock         -- 倉庫より入庫
             ,xird.sales_shipped            -                         -- 売上出庫
              xird.sales_shipped_b                                    -- 売上出庫振戻
                                                  sales_shipped       -- 売上出庫
             ,xird.return_goods             -                         -- 返品
              xird.return_goods_b                                     -- 返品振戻
                                                  customer_return     -- 顧客返品
             ,xird.customer_sample_ship     -                         -- 顧客見本出庫
              xird.customer_sample_ship_b   +                         -- 顧客見本出庫振戻
              xird.customer_support_ss      -                         -- 顧客協賛見本出庫
              xird.customer_support_ss_b    +                         -- 顧客協賛見本出庫振戻
              xird.sample_quantity          -                         -- 見本出庫
              xird.sample_quantity_b        +                         -- 見本出庫振戻
              xird.ccm_sample_ship          -                         -- 顧客広告宣伝費A自社商品
              xird.ccm_sample_ship_b                                  -- 顧客広告宣伝費A自社商品振戻
                                                  support_sample      -- 協賛見本
             ,xird.inventory_change_out           inv_change_out      -- VD出庫
             ,xird.inventory_change_in            inv_change_in       -- VD入庫
             ,xird.warehouse_ship           +                         -- 倉庫へ返庫
              xird.vd_supplement_ship                                 -- 消化VD補充出庫
                                                  warehouse_ship      -- 倉庫へ返庫
             ,xird.book_inventory_quantity        tyoubo_stock        -- 帳簿在庫
             ,0                                   inventory           -- 棚卸高
             ,0                                   inv_wear            -- 棚卸減耗
    FROM      xxcoi_inv_reception_daily   xird                    -- 月次在庫受払表（日次）
             ,mtl_secondary_inventories   msi                     -- 保管場所マスタ
             ,per_all_people_f            papf                    -- 従業員マスタ
    WHERE     papf.effective_start_date  <= gd_process_date
    AND       papf.effective_end_date    >= gd_process_date
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_hkn_kbn_car
    AND       msi.organization_id         = in_organization_id
    AND       xird.subinventory_code      = msi.secondary_inventory_name
    AND       msi.attribute7              = iv_base_code
    AND       msi.attribute7              = xird.base_code
    AND       msi.organization_id         = xird.organization_id
    AND       xird.subinventory_type      = cv_hkn_kbn_car
    AND       xird.practice_date          = TO_DATE(iv_inventory_date, cv_ymd)
    ;
--
  --受払残高表（月次）
  CURSOR monthly_cur(
            iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,iv_inventory_month  IN VARCHAR2
           ,iv_inventory_kbn    IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT
              /*+ leading(msi papf xirm) */
              papf.employee_number                emp_no              -- 営業員コード
             ,SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)
                                                  emp_name            -- 営業員名称（漢字姓＋漢字名）
             ,xirm.operation_cost                 operation_cost      -- 営業原価
             ,xirm.month_begin_quantity           month_begin_qty     -- 月首棚卸高
             ,xirm.warehouse_stock          +                         -- 倉庫より入庫
              xirm.vd_supplement_stock                                -- 消化VD補充入庫
                                                  vd_sp_stock         -- 倉庫より入庫
             ,xirm.sales_shipped            -                         -- 売上出庫
              xirm.sales_shipped_b                                    -- 売上出庫振戻
                                                  sales_shipped       -- 売上出庫
             ,xirm.return_goods             -                         -- 返品
              xirm.return_goods_b                                     -- 返品振戻
                                                  customer_return     -- 顧客返品
             ,xirm.customer_sample_ship     -                         -- 顧客見本出庫
              xirm.customer_sample_ship_b   +                         -- 顧客見本出庫振戻
              xirm.customer_support_ss      -                         -- 顧客協賛見本出庫
              xirm.customer_support_ss_b    +                         -- 顧客協賛見本出庫振戻
              xirm.sample_quantity          -                         -- 見本出庫
              xirm.sample_quantity_b        +                         -- 見本出庫振戻
              xirm.ccm_sample_ship          -                         -- 顧客広告宣伝費A自社商品
              xirm.ccm_sample_ship_b                                  -- 顧客広告宣伝費A自社商品振戻
                                                  support_sample      -- 協賛見本
             ,xirm.inventory_change_out           inv_change_out      -- VD出庫
             ,xirm.inventory_change_in            inv_change_in       -- VD入庫
             ,xirm.warehouse_ship           +                         -- 倉庫へ返庫
              xirm.vd_supplement_ship                                 -- 消化VD補充出庫
                                                  warehouse_ship      -- 倉庫へ返庫
             ,xirm.inv_result               +                         -- 棚卸結果
              xirm.inv_result_bad           +                         -- 棚卸結果（不良品）
              xirm.inv_wear                                           -- 棚卸減耗
                                                  tyoubo_stock        -- 帳簿在庫
             ,xirm.inv_result               +                         -- 棚卸結果
              xirm.inv_result_bad                                     -- 棚卸結果（不良品）
                                                  inventory           -- 棚卸高
             ,xirm.inv_wear                       inv_wear            -- 棚卸減耗
    FROM      xxcoi_inv_reception_monthly xirm                    --月次在庫受払表（月次）
             ,mtl_secondary_inventories   msi                     --保管場所マスタ
             ,per_all_people_f            papf                    --従業員マスタ
    WHERE     papf.effective_start_date  <= gd_process_date
    AND       papf.effective_end_date    >= gd_process_date
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_hkn_kbn_car
    AND       msi.organization_id         = in_organization_id
    AND       xirm.subinventory_code      = msi.secondary_inventory_name
    AND       msi.attribute7              = iv_base_code
    AND       msi.attribute7              = xirm.base_code
    AND       msi.organization_id         = xirm.organization_id
    AND       xirm.subinventory_type      = cv_hkn_kbn_car
    AND       (xirm.practice_date         = TO_DATE(iv_inventory_date, cv_ymd)
    OR        xirm.practice_month         = iv_inventory_month)
    AND       xirm.inventory_kbn          = DECODE(iv_inventory_kbn, cv_20, cv_1, cv_2)
    ;
  --
  --SVF出力用受払残高表
  CURSOR svf_data_cur
  IS
    SELECT
              xret.employee_code                emp_no                  --営業員コード
             ,xret.employee_name                emp_name                --営業員名称
             ,SUM(xret.first_inventory_qty)   first_inv_qty_amt         --月首棚卸高数量
             ,SUM(xret.first_inventory_qty * xret.operation_cost)
                                                first_inv_qty_pr        --月首棚卸高金額
             ,SUM(xret.warehouse_stock)         warehouse_stock_amt     --倉庫より入庫数量
             ,SUM(xret.warehouse_stock     * xret.operation_cost)
                                                warehouse_stock_pr      --倉庫より入庫金額
             ,SUM(xret.sales_qty)               sales_qty_amt           --売上出庫数量
             ,SUM(xret.sales_qty           * xret.operation_cost)
                                                sales_qty_pr            --売上出庫金額
             ,SUM(xret.customer_return)         customer_return_amt     --顧客返品数量
             ,SUM(xret.customer_return     * xret.operation_cost)
                                                customer_return_pr      --顧客返品金額
             ,SUM(xret.support_qty)             support_qty_amt         --協賛見本数量
             ,SUM(xret.support_qty         * xret.operation_cost)
                                                support_qty_pr          --協賛見本金額
             ,SUM(xret.vd_ship_qty)             vd_ship_qty_amt         --VD出庫数量
             ,SUM(xret.vd_ship_qty         * xret.operation_cost)
                                                vd_ship_qty_pr          --VD出庫金額
             ,SUM(xret.vd_in_qty)               vd_in_qty_amt           --VD入庫数量
             ,SUM(xret.vd_in_qty           * xret.operation_cost)
                                                vd_in_qty_pr            --VD入庫金額
             ,SUM(xret.warehouse_ship)          warehouse_ship_amt      --倉庫へ返庫数量
             ,SUM(xret.warehouse_ship      * xret.operation_cost)
                                                warehouse_ship_pr       --倉庫へ返庫金額
             ,SUM(xret.tyoubo_stock_qty)        tyb_stock_qty_amt       --帳簿在庫数量
             ,SUM(xret.tyoubo_stock_qty    * xret.operation_cost)
                                                tyb_stock_qty_pr        --帳簿在庫金額
             ,SUM(xret.inventory_qty)           inventory_qty_amt       --棚卸高数量
             ,SUM(xret.inventory_qty       * xret.operation_cost)
                                                inventory_qty_pr        --棚卸高金額
             ,SUM(xret.genmou_qty)              genmou_qty_amt          --棚卸減耗数量
             ,SUM(xret.genmou_qty          * xret.operation_cost)
                                                genmou_qty_pr           --棚卸減耗金額
    FROM      xxcoi_tmp_rep_by_employee_rcpt  xret
    GROUP BY
              xret.employee_code
             ,xret.employee_name
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_inventory_kbn    IN  VARCHAR2,                                       -- 1.棚卸区分
    iv_inventory_date   IN  VARCHAR2,                                       -- 2.棚卸日
    iv_inventory_month  IN  VARCHAR2,                                       -- 3.棚卸月
    iv_base_code        IN  VARCHAR2,                                       -- 4.拠点コード
    ov_account_name     OUT VARCHAR2,                                       -- 6.拠点略称
    on_organization_id  OUT NUMBER,                                         -- 7.在庫組織ID
    ot_inv_kbn_name     OUT fnd_lookup_values.meaning%TYPE,                 -- 8.棚卸区分名称
    ov_inv_cl_char      OUT VARCHAR2,                                       -- 9.在庫確定印字文字
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
--
    -- *** ローカル変数 ***
    lv_organization_code  VARCHAR2(4);                                            --在庫組織コード
    ln_organization_id    NUMBER;                                                 --在庫組織ID
    lt_meaning            fnd_lookup_values.meaning%TYPE;                         --項目名
    ld_inv_date           DATE;                                                   --日付チェック用
    lv_short_account_name VARCHAR2(20);                                           --拠点略称
    lb_chk_result         BOOLEAN;                                                --在庫会計期間チェック結果
    lv_inv_cl_char        VARCHAR2(4);                                            --在庫確定印字文字
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
    -- ローカル変数の初期化
    lv_inv_cl_char := NULL;
    --
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --===================================
    --入力パラメータ出力
    --===================================
    --棚卸区分内容取得
    lt_meaning := xxcoi_common_pkg.get_meaning(
                    cv_lk_list_out_div
                   ,iv_inventory_kbn
                  );
    --棚卸区分出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_10330
                   ,iv_token_name1  => cv_tkn_inv_type
                   ,iv_token_value1 => lt_meaning
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => gv_out_msg
    );
    --棚卸日
    IF (iv_inventory_date IS NOT NULL) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10099
                     ,iv_token_name1  => cv_tkn_inv_date
                     ,iv_token_value1 => iv_inventory_date
                    );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => gv_out_msg
      );
    END IF;
    --棚卸月
    IF (iv_inventory_month IS NOT NULL) THEN
      BEGIN
        ld_inv_date := TO_DATE(iv_inventory_month, cv_ym);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_10105
                         )
                      ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      --
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10100
                     ,iv_token_name1  => cv_tkn_inv_month
                     ,iv_token_value1 => iv_inventory_month
                    );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => gv_out_msg
      );
    END IF;
    --拠点
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_10096
                   ,iv_token_name1  => cv_tkn_base_code
                   ,iv_token_value1 => iv_base_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => gv_out_msg
    );
--
    --====================================
    --業務処理日付取得
    --====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00011
                     )
                   ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --未来日チェック
    --====================================
    --棚卸区分が10:日次、20:月中
    IF (iv_inventory_kbn IN (cv_10, cv_20)) THEN
      ld_inv_date := TO_DATE(iv_inventory_date, cv_ymd);
      IF (ld_inv_date > gd_process_date) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10197
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      gd_target_date := ld_inv_date;
    --
    --棚卸区分が30:月次
    ELSIF (iv_inventory_kbn = cv_30) THEN
      IF (ld_inv_date > gd_process_date) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10198
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      gd_target_date := LAST_DAY(TO_DATE(iv_inventory_month, cv_ym_sla));
    END IF;
--
    --====================================
    --拠点略称取得
    --====================================
    BEGIN
      SELECT  SUBSTRB(hca.account_name, 1, 8)  account_name
      INTO    lv_short_account_name
      FROM    hz_cust_accounts hca
      WHERE   hca.customer_class_code = cv_class_code_1
      AND     hca.account_number      = iv_base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10106
                      ,iv_token_name1  => cv_tkn_base_code
                      ,iv_token_value1 => iv_base_code
                       )
                    ,1,5000);
      RAISE select_expt;
    END;
--
    --====================================
    --在庫組織コード取得
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
    --
    IF (lv_organization_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00005
                    ,iv_token_name1  => cv_tkn_pro
                    ,iv_token_value1 => cv_prf_org_code
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --在庫組織ID取得
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    --
    IF (ln_organization_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00006
                    ,iv_token_name1  => cv_tkn_org_code
                    ,iv_token_value1 => lv_organization_code
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --在庫会計期間チェック
    --====================================
    xxcoi_common_pkg.org_acct_period_chk(
      in_organization_id    => ln_organization_id  -- 組織ID
     ,id_target_date        => gd_target_date      -- 取得対象日付
     ,ob_chk_result         => lb_chk_result       -- チェック結果
     ,ov_errbuf             => lv_errbuf
     ,ov_retcode            => lv_retcode
     ,ov_errmsg             => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00026
                    ,iv_token_name1  => cv_tkn_target
                    ,iv_token_value1 => TO_CHAR(gd_target_date, cv_ymd_sla)
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --帳票印字文字取得
    --====================================
    IF NOT(lb_chk_result) THEN
      lv_inv_cl_char := fnd_profile.value(cv_inv_cl_char);
      --
      IF (lv_inv_cl_char IS NULL) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10451
                      ,iv_token_name1  => cv_tkn_pro
                      ,iv_token_value1 => cv_inv_cl_char
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --OUTパラメータに設定
    ov_account_name     := lv_short_account_name;
    on_organization_id  := ln_organization_id;
    ot_inv_kbn_name     := lt_meaning;
    ov_inv_cl_char      := lv_inv_cl_char;
--
  EXCEPTION
    -- *** データ抽出例外 ***
    WHEN select_expt THEN
      -- メッセージ取得
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_data
   * Description      : ワークテーブルデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_work_data(
    ir_work_data        IN  daily_cur%ROWTYPE,              -- CSV出力対象データ
    ov_errbuf           OUT VARCHAR2,                       -- エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,                       -- リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)                       -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_data'; -- プログラム名
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- ===============================
    --  1.ワークテーブル作成
    -- ===============================
    --
    -- 受払残高表（営業員別計）一時表へ挿入
    INSERT INTO xxcoi_tmp_rep_by_employee_rcpt(
       employee_code                    -- 営業員コード
      ,employee_name                    -- 営業員名称
      ,operation_cost                   -- 営業原価
      ,first_inventory_qty              -- 月首棚卸高
      ,warehouse_stock                  -- 倉庫より入庫
      ,sales_qty                        -- 売上出庫
      ,customer_return                  -- 顧客返品
      ,support_qty                      -- 協賛見本
      ,vd_ship_qty                      -- VD出庫
      ,vd_in_qty                        -- VD入庫
      ,warehouse_ship                   -- 倉庫へ返庫
      ,tyoubo_stock_qty                 -- 帳簿在庫
      ,inventory_qty                    -- 棚卸高
      ,genmou_qty                       -- 棚卸減耗
    )VALUES(
       ir_work_data.emp_no              -- 営業員コード
      ,ir_work_data.emp_name            -- 営業員名称
      ,ir_work_data.operation_cost      -- 営業原価
      ,ir_work_data.month_begin_qty     -- 月首棚卸高
      ,ir_work_data.vd_sp_stock         -- 倉庫より入庫
      ,ir_work_data.sales_shipped       -- 売上出庫
      ,ir_work_data.customer_return     -- 顧客返品
      ,ir_work_data.support_sample      -- 協賛見本
      ,ir_work_data.inv_change_out      -- VD出庫
      ,ir_work_data.inv_change_in       -- VD入庫
      ,ir_work_data.warehouse_ship      -- 倉庫へ返庫
      ,ir_work_data.tyoubo_stock        -- 帳簿在庫
      ,ir_work_data.inventory           -- 棚卸高
      ,ir_work_data.inv_wear            -- 棚卸減耗
    );
--
  EXCEPTION
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
  END ins_work_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : 帳票用ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data         IN  svf_data_cur%ROWTYPE,           -- 1.CSV出力対象データ
    in_slit_id          IN  NUMBER,                         -- 2.処理連番
    iv_message          IN  VARCHAR2,                       -- 3.０件メッセージ
    iv_inventory_kbn    IN  VARCHAR2,                       -- 4.棚卸区分
    it_inv_kbn_name     IN  fnd_lookup_values.meaning%TYPE, -- 5.棚卸区分名称
    iv_account_name     IN  VARCHAR2,                       -- 6.拠点略称
    iv_inventory_date   IN  VARCHAR2,                       -- 7.棚卸日
    iv_inventory_month  IN  VARCHAR2,                       -- 8.棚卸月
    iv_base_code        IN  VARCHAR2,                       -- 9.拠点コード
    iv_inv_cl_char      IN  VARCHAR2,                       -- 10.在庫確定印字文字
    ov_errbuf           OUT VARCHAR2,                       -- エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,                       -- リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)                       -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_svf_data'; -- プログラム名
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
    lv_year                   VARCHAR2(4);    -- 年
    lv_month                  VARCHAR2(2);    -- 月
    lv_day                    VARCHAR2(2);    -- 日
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- ===============================
    --  1.ワークテーブル作成
    -- ===============================
    -- 年月日設定
    -- 棚卸区分 = 日次、月中
    IF (iv_inventory_kbn IN (cv_10, cv_20)) THEN
      lv_year   := SUBSTRB(iv_inventory_date, 3, 2);
      lv_month  := SUBSTRB(iv_inventory_date, 5, 2);
      lv_day    := SUBSTRB(iv_inventory_date, 7, 2);
    -- 棚卸区分 = 月末
    ELSIF (iv_inventory_kbn = cv_30) THEN
      lv_year   := SUBSTRB(iv_inventory_month, 3, 2);
      lv_month  := SUBSTRB(iv_inventory_month, 5, 2);
      lv_day    :=  NULL;
    END IF;
    --
    -- 受払残高表（営業員別計）帳票ワークテーブルへ挿入
    INSERT INTO xxcoi_rep_by_employee_rcpt(
       slit_id                         -- 1.ID
      ,inventory_kbn                   -- 2.棚卸区分（内容）
      ,in_out_year                     -- 3.年
      ,in_out_month                    -- 4.月
      ,in_out_date                     -- 5.日
      ,base_code                       -- 6.拠点コード
      ,base_name                       -- 7.拠点名称
      ,inv_cl_char                     -- 8.在庫確定印字文字
      ,employee_code                   -- 9.営業員コード
      ,employee_name                   -- 10.営業員名称
      ,first_inv_qty_amt               -- 11.月首棚卸高数量
      ,first_inv_qty_pr                -- 12.月首棚卸高金額
      ,warehouse_stock_amt             -- 13.倉庫より入庫数量
      ,warehouse_stock_pr              -- 14.倉庫より入庫金額
      ,sales_qty_amt                   -- 15.売上出庫数量
      ,sales_qty_pr                    -- 16.売上出庫金額
      ,customer_return_amt             -- 17.顧客返品数量
      ,customer_return_pr              -- 18.顧客返品金額
      ,support_qty_amt                 -- 19.協賛見本数量
      ,support_qty_pr                  -- 20.協賛見本金額
      ,vd_ship_qty_amt                 -- 21.VD出庫数量
      ,vd_ship_qty_pr                  -- 22.VD出庫金額
      ,vd_in_qty_amt                   -- 23.VD入庫数量
      ,vd_in_qty_pr                    -- 24.VD入庫金額
      ,warehouse_ship_amt              -- 25.倉庫へ返庫数量
      ,warehouse_ship_pr               -- 26.倉庫へ返庫金額
      ,tyb_stock_qty_amt               -- 27.帳簿在庫数量
      ,tyb_stock_qty_pr                -- 28.帳簿在庫金額
      ,inventory_qty_amt               -- 29.棚卸高数量
      ,inventory_qty_pr                -- 30.棚卸高金額
      ,genmou_qty_amt                  -- 31.棚卸減耗数量
      ,genmou_qty_pr                   -- 32.棚卸減耗金額
      ,message                         -- 33.メッセージ ※０件用
      ,last_update_date                -- 34.最終更新日
      ,last_updated_by                 -- 35.最終更新者
      ,creation_date                   -- 36.作成日
      ,created_by                      -- 37.作成者
      ,last_update_login               -- 38.最終更新ユーザ
      ,request_id                      -- 39.要求ID
      ,program_application_id          -- 40.プログラムアプリケーションID
      ,program_id                      -- 41.プログラムID
      ,program_update_date             -- 42.プログラム更新日
    )VALUES(
       in_slit_id                      -- 1.ID
      ,it_inv_kbn_name                 -- 2.棚卸区分
      ,lv_year                         -- 3.年
      ,lv_month                        -- 4.月
      ,lv_day                          -- 5.日
      ,iv_base_code                    -- 6.拠点コード
      ,iv_account_name                 -- 7.拠点名称
      ,iv_inv_cl_char                  -- 8.在庫確定印字文字
      ,ir_svf_data.emp_no              -- 9.営業員コード
      ,ir_svf_data.emp_name            -- 10.営業員名称
      ,ir_svf_data.first_inv_qty_amt   -- 11.月首棚卸高数量
      ,ir_svf_data.first_inv_qty_pr    -- 12.月首棚卸高金額
      ,ir_svf_data.warehouse_stock_amt -- 13.倉庫より入庫数量
      ,ir_svf_data.warehouse_stock_pr  -- 14.倉庫より入庫金額
      ,ir_svf_data.sales_qty_amt       -- 15.売上出庫数量
      ,ir_svf_data.sales_qty_pr        -- 16.売上出庫金額
      ,ir_svf_data.customer_return_amt -- 17.顧客返品数量
      ,ir_svf_data.customer_return_pr  -- 18.顧客返品金額
      ,ir_svf_data.support_qty_amt     -- 19.協賛見本数量
      ,ir_svf_data.support_qty_pr      -- 20.協賛見本金額
      ,ir_svf_data.vd_ship_qty_amt     -- 21.VD出庫数量
      ,ir_svf_data.vd_ship_qty_pr      -- 22.VD出庫金額
      ,ir_svf_data.vd_in_qty_amt       -- 23.VD入庫数量
      ,ir_svf_data.vd_in_qty_pr        -- 24.VD入庫金額
      ,ir_svf_data.warehouse_ship_amt  -- 25.倉庫へ返庫数量
      ,ir_svf_data.warehouse_ship_pr   -- 26.倉庫へ返庫金額
      ,ir_svf_data.tyb_stock_qty_amt   -- 27.帳簿在庫数量
      ,ir_svf_data.tyb_stock_qty_pr    -- 28.帳簿在庫金額
      ,ir_svf_data.inventory_qty_amt   -- 29.棚卸高数量
      ,ir_svf_data.inventory_qty_pr    -- 30.棚卸高金額
      ,ir_svf_data.genmou_qty_amt      -- 31.棚卸減耗数量
      ,ir_svf_data.genmou_qty_pr       -- 32.棚卸減耗金額
      ,iv_message                      -- 33.メッセージ ※０件用
      ,SYSDATE                         -- 34.最終更新日
      ,cn_last_updated_by              -- 35.最終更新者
      ,SYSDATE                         -- 36.作成日
      ,cn_created_by                   -- 37.作成者
      ,cn_last_update_login            -- 38.最終更新ユーザ
      ,cn_request_id                   -- 39.要求ID
      ,cn_program_application_id       -- 40.プログラムアプリケーションID
      ,cn_program_id                   -- 41.プログラムID
      ,SYSDATE                         -- 42.プログラム更新日
    );
--
  EXCEPTION
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
  END ins_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : call_output_svf
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE call_output_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_output_svf'; -- プログラム名
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- ===============================
    --  1.SVF起動
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name         =>  cv_conc_name            -- コンカレント名
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_ymd) || TO_CHAR(cn_request_id) || cv_type_pdf
                                                        -- 出力ファイル名
      ,iv_file_id           =>  cv_file_id              -- 帳票ID
      ,iv_output_mode       =>  cv_output_mode          -- 出力区分
      ,iv_frm_file          =>  cv_frm_file             -- フォーム様式ファイル名
      ,iv_vrq_file          =>  cv_vrq_file             -- クエリー様式ファイル名
      ,iv_org_id            =>  fnd_global.org_id       -- ORG_ID
      ,iv_user_name         =>  fnd_global.user_name    -- ログイン・ユーザ名
      ,iv_resp_name         =>  fnd_global.resp_name    -- ログイン・ユーザの職責名
      ,iv_doc_name          =>  NULL                    -- 文書名
      ,iv_printer_name      =>  NULL                    -- プリンタ名
      ,iv_request_id        =>  cn_request_id           -- 要求ID
      ,iv_nodata_msg        =>  NULL                    -- データなしメッセージ
      ,ov_retcode           =>  lv_retcode              -- リターンコード
      ,ov_errbuf            =>  lv_errbuf               -- エラーメッセージ
      ,ov_errmsg            =>  lv_errmsg               -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode  <>  cv_status_normal) THEN
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10088
                      )
                   ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF; 
--
  EXCEPTION
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ワークテーブルデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_svf_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_svf_data'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- ===============================
    --  ワークテーブル削除
    -- ===============================
    --受払残高表（営業員別計）帳票ワークテーブル
    DELETE  FROM xxcoi_rep_by_employee_rcpt
    WHERE   request_id  = cn_request_id;
    --
  EXCEPTION
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
  END del_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_inventory_kbn    IN  VARCHAR2,   -- 1.棚卸区分
    iv_inventory_date   IN  VARCHAR2,   -- 2.棚卸日
    iv_inventory_month  IN  VARCHAR2,   -- 3.棚卸月
    iv_base_code        IN  VARCHAR2,   -- 4.拠点
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_zero_msg           VARCHAR2(5000);
    --
    lv_account_name       VARCHAR2(16);
    ln_organization_id    NUMBER;
    lt_inv_kbn_name       fnd_lookup_values.meaning%TYPE;
    lv_inv_cl_char        VARCHAR2(4);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- レコード型
    inv_data_rec  daily_cur%ROWTYPE;
    svf_data_rec  svf_data_cur%ROWTYPE;
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
    -- ローカル変数の初期化
    lv_zero_msg   := NULL;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理 A-1
    -- ===============================
    init(
      iv_inventory_kbn    =>  iv_inventory_kbn    -- 1.棚卸区分
     ,iv_inventory_date   =>  iv_inventory_date   -- 2.棚卸日
     ,iv_inventory_month  =>  iv_inventory_month  -- 3.棚卸月
     ,iv_base_code        =>  iv_base_code        -- 4.拠点コード
     ,ov_account_name     =>  lv_account_name     -- 6.拠点略称
     ,on_organization_id  =>  ln_organization_id  -- 7.在庫組織コード
     ,ot_inv_kbn_name     =>  lt_inv_kbn_name     -- 8.棚卸区分名称
     ,ov_inv_cl_char      =>  lv_inv_cl_char      -- 9.在庫確定印字文字
     ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ワークデータ取得 A-2
    -- ===============================
    --棚卸区分が日次
    IF (iv_inventory_kbn = cv_10) THEN
      OPEN  daily_cur(
              iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,in_organization_id  => ln_organization_id);
      FETCH daily_cur INTO inv_data_rec;
      --対象データ０件
      IF (daily_cur%NOTFOUND) THEN
        lv_zero_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                         )
                      ,1,5000);
      END IF;
    --棚卸区分が月中又は、月次
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      OPEN  monthly_cur(
              iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,iv_inventory_month  => iv_inventory_month
             ,iv_inventory_kbn    => iv_inventory_kbn
             ,in_organization_id  => ln_organization_id);
      FETCH monthly_cur INTO inv_data_rec;
      --対象データ０件
      IF (monthly_cur%NOTFOUND) THEN
        lv_zero_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                         )
                      ,1,5000);
      END IF;
    END IF;
--
    -- 対象データ０件の場合、ワークテーブル作成処理はなし
    IF (lv_zero_msg IS NULL) THEN
      --
      <<ins_work_loop>>
      LOOP
        -- ===============================
        --  A-3.ワークテーブルデータ登録
        -- ===============================
        ins_work_data(
           ir_work_data       =>  inv_data_rec        -- CSV出力用データ
          ,ov_errbuf          =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
          ,ov_retcode         =>  lv_retcode          -- リターン・コード             --# 固定 #
          ,ov_errmsg          =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- 対象データ取得
        IF (iv_inventory_kbn =  cv_10)  THEN
          FETCH daily_cur INTO inv_data_rec;
          EXIT WHEN daily_cur%NOTFOUND;
        ELSIF (iv_inventory_kbn IN (cv_20, cv_30))  THEN
          FETCH monthly_cur INTO inv_data_rec;
          EXIT WHEN monthly_cur%NOTFOUND;
        END IF;
        --
      END LOOP ins_work_loop;
    --
    END IF;
    -- カーソルクローズ
    IF (iv_inventory_kbn = cv_10) THEN
      CLOSE daily_cur;
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      CLOSE monthly_cur;
    END IF;
--
    --帳票用データ取得
    OPEN  svf_data_cur;
    FETCH svf_data_cur INTO svf_data_rec;
    --
    <<ins_svf_loop>>
    LOOP
      --
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- ===============================
      --  A-4.帳票用ワークテーブルデータ登録
      -- ===============================
      ins_svf_data(
         ir_svf_data        =>  svf_data_rec        -- 1.CSV出力用データ
        ,in_slit_id         =>  gn_target_cnt       -- 2.処理連番
        ,iv_message         =>  lv_zero_msg         -- 3.０件メッセージ
        ,iv_inventory_kbn   =>  iv_inventory_kbn    -- 4.棚卸区分
        ,it_inv_kbn_name    =>  lt_inv_kbn_name     -- 5.棚卸区分名称
        ,iv_account_name    =>  lv_account_name     -- 6.拠点略称
        ,iv_inventory_date  =>  iv_inventory_date   -- 7.棚卸日
        ,iv_inventory_month =>  iv_inventory_month  -- 8.棚卸月
        ,iv_base_code       =>  iv_base_code        -- 9.拠点コード
        ,iv_inv_cl_char     =>  lv_inv_cl_char      -- 10.在庫確定印字文字
        ,ov_errbuf          =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,ov_retcode         =>  lv_retcode          -- リターン・コード             --# 固定 #
        ,ov_errmsg          =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- 対象データ０件の場合、帳票用ワークテーブル作成処理終了
      EXIT WHEN lv_zero_msg IS NOT NULL;
      -- 対象データ取得
      FETCH svf_data_cur INTO svf_data_rec;
      EXIT WHEN svf_data_cur%NOTFOUND;
      --
    END LOOP ins_svf_loop;
    -- カーソルクローズ
    CLOSE svf_data_cur;
--
    -- コミット処理
    COMMIT;
--
    -- ===============================
    --  A-5.SVF起動
    -- ===============================
    call_output_svf(
       ov_errbuf    =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   =>  lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg    =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    --  A-6.ワークテーブルデータ削除
    -- ===============================
    del_svf_data(
       ov_errbuf    =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   =>  lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg    =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 正常終了件数
    IF (lv_zero_msg IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt;
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
      -- カーソルクローズ
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
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
    errbuf             OUT  VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode            OUT  VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_inventory_kbn   IN   VARCHAR2,      -- 1.棚卸区分
    iv_inventory_date  IN   VARCHAR2,      -- 2.棚卸日
    iv_inventory_month IN   VARCHAR2,      -- 3.棚卸月
    iv_base_code       IN   VARCHAR2       -- 4.拠点
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
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
    --
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';              -- コンカレントヘッダ出力先
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
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
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
       iv_inventory_kbn   =>  iv_inventory_kbn           -- 1.棚卸区分
      ,iv_inventory_date  =>  REPLACE(SUBSTRB(iv_inventory_date, 1, 10)
                                      ,cv_replace_sign)  -- 2.棚卸日
      ,iv_inventory_month =>  iv_inventory_month         -- 3.棚卸月
      ,iv_base_code       =>  iv_base_code               -- 4.拠点
      ,ov_errbuf          =>  lv_errbuf                  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         =>  lv_retcode                 -- リターン・コード             --# 固定 #
      ,ov_errmsg          =>  lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラーの場合、エラー件数のセット
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_warn_cnt   := 0;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
END XXCOI006A24R;
/
