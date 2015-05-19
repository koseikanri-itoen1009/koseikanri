CREATE OR REPLACE PACKAGE BODY XXCOI006A14R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A14R(body)
 * Description      : 受払残高表（営業員）
 * MD.050           : 受払残高表（営業員） <MD050_COI_A14>
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  ins_svf_data           ワークテーブルデータ登録(A-3)
 *  call_output_svf        SVF起動(A-4)
 *  del_svf_data           ワークテーブルデータ削除(A-5)
 *  submain                メイン処理プロシージャ
 *                         データ取得(A-2)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/26    1.0   N.Abe            新規作成
 *  2009/07/14    1.1   N.Abe            [0000462]群コード取得方法修正
 *  2009/07/22    1.2   H.Sasaki         [0000685]パラメータ日付項目のPT対応
 *  2009/08/04    1.3   H.Sasaki         [0000895]PT対応
 *  2009/08/18    1.4   N.Abe            [0001090]出力桁数の修正
 *  2009/09/08    1.5   H.Sasaki         [0001266]OPM品目アドオンの版管理対応
 *  2009/10/07    1.6   H.Sasaki         [E_T3_00465]棚卸月の型チェックを変更
 *  2015/03/03    1.7   Y.Koh            障害対応E_本稼動_12827
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
  inv_date_null_expt       EXCEPTION;     -- 棚卸日NULLチェックエラー
  inv_date_type_expt       EXCEPTION;     -- 棚卸日の型チェックエラー
  inv_month_null_expt      EXCEPTION;     -- 棚卸月NULLチェックエラー
  inv_month_type_expt      EXCEPTION;     -- 棚卸月の型チェックエラー
  get_base_expt            EXCEPTION;     -- 拠点有効チェックエラー
  get_employee_expt        EXCEPTION;     -- 営業員存在チェックエラー
  org_code_expt            EXCEPTION;     -- 在庫組織コード取得エラー
  org_id_expt              EXCEPTION;     -- 在庫組織ID取得エラー
  output_expt              EXCEPTION;     -- 帳票出力エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOI006A14R'; -- パッケージ名
--
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)  := 'XXCOI';        -- アドオン：販物・在庫領域
--
  --棚卸区分(10:日次 20:月中 30:月末)
  cv_10               CONSTANT VARCHAR2(2)   := '10';
  cv_20               CONSTANT VARCHAR2(2)   := '20';
  cv_30               CONSTANT VARCHAR2(2)   := '30';
  --日付変換
  cv_ymd              CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  --
  cv_1                CONSTANT VARCHAR2(1)   := '1';
  cv_2                CONSTANT VARCHAR2(1)   := '2';
  cv_y                CONSTANT VARCHAR2(1)   := 'Y';
  cv_type_emp         CONSTANT VARCHAR2(3)   := 'EMP';
-- == 2009/07/22 V1.2 Added START ===============================================================
  cv_replace_sign     CONSTANT VARCHAR2(1)   := '/';
-- == 2009/07/22 V1.2 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;                                   -- 業務処理日付
-- == 2009/07/14 V1.1 Added START ===============================================================
  gd_target_date        DATE;
-- == 2009/07/14 V1.1 Added END   ===============================================================
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  --受払残高表（日次）
  CURSOR daily_cur(
            iv_business         IN VARCHAR2
           ,iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT
-- == 2009/08/04 V1.3 Added START ===============================================================
              /*+ leading(msi papf xird) */
-- == 2009/08/04 V1.3 Added END   ===============================================================
              papf.employee_number                emp_no              -- 1.営業員コード
-- == 2009/08/18 V1.4 Modified START ===============================================================
--             ,papf.per_information18 || papf.per_information19
             ,SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)
-- == 2009/08/18 V1.4 Modified END   ===============================================================
                                                  emp_name            -- 2.営業員名称（漢字姓＋漢字名）
-- == 2009/07/14 V1.1 Modified START ===============================================================
--             ,SUBSTR(iimb.attribute2, 1, 3)       policy_group        -- 3.群コード
             ,SUBSTR(
                (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                        THEN iimb.attribute1                          --   群コード(旧)
                        ELSE iimb.attribute2                          --   群コード(新)
                      END
                ), 1, 3
              )                                   policy_group        -- 3.群コード
-- == 2009/07/14 V1.1 Modified END   ===============================================================
             ,iimb.item_no                        item_no             -- 4.品目コード
             ,ximb.item_short_name                item_short_name     -- 5.略称（商品）
             ,xird.operation_cost                 operation_cost      -- 6.営業原価
             ,xird.previous_inventory_quantity    month_begin_qty     -- 7.月首棚卸高
             ,xird.warehouse_stock          +                         --   倉庫より入庫
              xird.vd_supplement_stock                                --   消化VD補充入庫
                                                  vd_sp_stock         -- 8.倉庫より入庫
             ,xird.sales_shipped            -                         --   売上出庫
              xird.sales_shipped_b                                    --   売上出庫振戻
                                                  sales_shipped       -- 9.売上出庫
             ,xird.return_goods             -                         --   返品
              xird.return_goods_b                                     --   返品振戻
                                                  customer_return     --10.顧客返品
             ,xird.customer_sample_ship     -                         --   顧客見本出庫
              xird.customer_sample_ship_b   +                         --   顧客見本出庫振戻
              xird.customer_support_ss      -                         --   顧客協賛見本出庫
              xird.customer_support_ss_b    +                         --   顧客協賛見本出庫振戻
              xird.sample_quantity          -                         --   見本出庫
              xird.sample_quantity_b        +                         --   見本出庫振戻
              xird.ccm_sample_ship          -                         --   顧客広告宣伝費A自社商品
              xird.ccm_sample_ship_b                                  --   顧客広告宣伝費A自社商品振戻
                                                  support_sample      --11.協賛見本
             ,xird.inventory_change_out           inv_change_out      --12.VD出庫
             ,xird.inventory_change_in            inv_change_in       --13.VD入庫
             ,xird.warehouse_ship           +                         --   倉庫へ返庫
              xird.vd_supplement_ship                                 --   消化VD補充出庫
                                                  warehouse_ship      --14.倉庫へ返庫
             ,xird.book_inventory_quantity        tyoubo_stock        --15.帳簿在庫
             ,0                                   inventory           --16.棚卸高
             ,0                                   inv_wear            --17.棚卸減耗
    FROM      xxcoi_inv_reception_daily   xird                        --月次在庫受払表（日次）
             ,mtl_secondary_inventories   msi                         --保管場所マスタ
             ,per_all_people_f            papf                        --従業員マスタ
             ,mtl_system_items_b          msib                        --Disc品目
             ,ic_item_mst_b               iimb                        --OPM品目
             ,xxcmn_item_mst_b            ximb                        --OPM品目アドオン
    WHERE     papf.employee_number        = NVL(iv_business, msi.attribute3)
    AND       papf.effective_start_date  <= gd_process_date
    AND       (papf.effective_end_date   >= gd_process_date
    OR        (papf.effective_end_date   IS NULL))
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_2
    AND       msi.organization_id         = in_organization_id
    AND       xird.subinventory_code      = msi.secondary_inventory_name
-- == 2009/08/04 V1.3 Modified START ===============================================================
--    AND       xird.base_code              = iv_base_code
    AND       msi.attribute7              = iv_base_code
    AND       msi.attribute7              = xird.base_code
    AND       msi.organization_id         = xird.organization_id
-- == 2009/08/04 V1.3 Modified END   ===============================================================
    AND       xird.subinventory_type      = cv_2
    AND       xird.practice_date          = TO_DATE(iv_inventory_date, cv_ymd)
    AND       xird.organization_id        = msib.organization_id
    AND       xird.inventory_item_id      = msib.inventory_item_id
    AND       msib.segment1               = iimb.item_no
    AND       iimb.item_id                = ximb.item_id
-- == 2009/09/08 V1.5 Added START ===============================================================
    AND       xird.practice_date  BETWEEN ximb.start_date_active
                                  AND     NVL(ximb.end_date_active, xird.practice_date)
-- == 2009/09/08 V1.5 Added END   ===============================================================
-- == 2009/08/04 V1.3 Deleted START ===============================================================
--    ORDER BY  papf.employee_number
--             ,SUBSTR(iimb.attribute2, 1, 3)
--             ,iimb.item_no
-- == 2009/08/04 V1.3 Deleted END   ===============================================================
    ;
--
  --受払残高表（月次）
  CURSOR monthly_cur(
            iv_business         IN VARCHAR2
           ,iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,iv_inventory_month  IN VARCHAR2
           ,iv_inventory_kbn    IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT
-- == 2009/08/04 V1.3 Added START ===============================================================
              /*+ leading(msi papf xirm) */
-- == 2009/08/04 V1.3 Added END   ===============================================================
              papf.employee_number                emp_no              -- 1.営業員コード
-- == 2009/08/18 V1.4 Modified START ===============================================================
--             ,papf.per_information18 || papf.per_information19
             ,SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)
-- == 2009/08/18 V1.4 Modified END   ===============================================================
                                                  emp_name            -- 2.営業員名称（漢字姓＋漢字名）
-- == 2009/07/14 V1.1 Modified START ===============================================================
--             ,SUBSTR(iimb.attribute2, 1, 3)       policy_group        -- 3.群コード
             ,SUBSTR(
                (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                        THEN iimb.attribute1                          --   群コード(旧)
                        ELSE iimb.attribute2                          --   群コード(新)
                      END
                ), 1, 3
              )                                   policy_group        -- 3.群コード
-- == 2009/07/14 V1.1 Modified END   ===============================================================
             ,iimb.item_no                        item_no             -- 4.品目コード
             ,ximb.item_short_name                item_short_name     -- 5.略称（商品）
             ,xirm.operation_cost                 operation_cost      -- 6.営業原価
             ,xirm.month_begin_quantity           month_begin_qty     -- 7.月首棚卸高
             ,xirm.warehouse_stock          +                         --   倉庫より入庫
              xirm.vd_supplement_stock                                --   消化VD補充入庫
                                                  vd_sp_stock         -- 8.倉庫より入庫
             ,xirm.sales_shipped            -                         --   売上出庫
              xirm.sales_shipped_b                                    --   売上出庫振戻
                                                  sales_shipped       -- 9.売上出庫
             ,xirm.return_goods             -                         --   返品
              xirm.return_goods_b                                     --   返品振戻
                                                  customer_retuen     --10.顧客返品
             ,xirm.customer_sample_ship     -                         --   顧客見本出庫
              xirm.customer_sample_ship_b   +                         --   顧客見本出庫振戻
              xirm.customer_support_ss      -                         --   顧客協賛見本出庫
              xirm.customer_support_ss_b    +                         --   顧客協賛見本出庫振戻
              xirm.sample_quantity          -                         --   見本出庫
              xirm.sample_quantity_b        +                         --   見本出庫振戻
              xirm.ccm_sample_ship          -                         --   顧客広告宣伝費A自社商品
              xirm.ccm_sample_ship_b                                  --   顧客広告宣伝費A自社商品振戻
                                                  support_sample      --11.協賛見本
             ,xirm.inventory_change_out                               --12.VD出庫
             ,xirm.inventory_change_in                                --13.VD入庫
             ,xirm.warehouse_ship           +                         --   倉庫へ返庫
              xirm.vd_supplement_ship                                 --   消化VD補充出庫
                                                  warehouse_ship      --14.倉庫へ返庫
             ,xirm.inv_result               +                         --   棚卸結果
              xirm.inv_result_bad           +                         --   棚卸結果（不良品）
              xirm.inv_wear                                           --   棚卸減耗
                                                  tyoubo_stock        --15.帳簿在庫
             ,xirm.inv_result               +                         --   棚卸結果
              xirm.inv_result_bad                                     --   棚卸結果（不良品）
                                                  inventory           --16.棚卸高
             ,xirm.inv_wear                       inv_wear            --17.棚卸減耗
    FROM      xxcoi_inv_reception_monthly xirm                        --月次在庫受払表（月次）
             ,mtl_secondary_inventories   msi                         --保管場所マスタ
             ,per_all_people_f            papf                        --従業員マスタ
             ,mtl_system_items_b          msib                        --Disc品目
             ,ic_item_mst_b               iimb                        --OPM品目
             ,xxcmn_item_mst_b            ximb                        --OPM品目アドオン
    WHERE     papf.employee_number        = NVL(iv_business, msi.attribute3)
    AND       papf.effective_start_date  <= gd_process_date
    AND       (papf.effective_end_date   >= gd_process_date
    OR        (papf.effective_end_date   IS NULL))
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_2
    AND       msi.organization_id         = in_organization_id
    AND       xirm.subinventory_code      = msi.secondary_inventory_name
-- == 2009/08/04 V1.3 Modified START ===============================================================
--    AND       xirm.base_code              = iv_base_code
    AND       msi.attribute7              = iv_base_code
    AND       msi.attribute7              = xirm.base_code
    AND       msi.organization_id         = xirm.organization_id
-- == 2009/08/04 V1.3 Modified END   ===============================================================
    AND       xirm.subinventory_type      = cv_2
    AND       (xirm.practice_date         = TO_DATE(iv_inventory_date, cv_ymd)
    OR        xirm.practice_month         = iv_inventory_month)
    AND       xirm.inventory_kbn          = DECODE(iv_inventory_kbn, cv_20, cv_1, cv_2)
    AND       xirm.organization_id        = msib.organization_id
    AND       xirm.inventory_item_id      = msib.inventory_item_id
    AND       msib.segment1               = iimb.item_no
    AND       iimb.item_id                = ximb.item_id
-- == 2009/09/08 V1.5 Added START ===============================================================
    AND       xirm.practice_date  BETWEEN ximb.start_date_active
                                  AND     NVL(ximb.end_date_active, xirm.practice_date)
-- == 2009/09/08 V1.5 Added END   ===============================================================
-- == 2009/08/04 V1.3 Deleted START ===============================================================
--    ORDER BY  papf.employee_number
--             ,SUBSTR(iimb.attribute2, 1, 3)
--             ,iimb.item_no
-- == 2009/08/04 V1.3 Deleted END   ===============================================================
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
    iv_business         IN  VARCHAR2,                                       -- 5.営業員
    ov_account_name     OUT VARCHAR2,                                       -- 6.拠点略称
    ov_emp_name         OUT VARCHAR2,                                       -- 7.従業員名
    on_organization_id  OUT NUMBER,                                         -- 8.在庫組織ID
    ot_inv_kbn_name     OUT fnd_lookup_values.meaning%TYPE,                 -- 9.棚卸区分名称
-- == 2015/03/03 V1.7 Added START ===============================================================
    ov_inv_cl_char      OUT VARCHAR2,                                       -- 10.在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
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
    --LOOKUP
    cv_lk_list_out_div    CONSTANT  VARCHAR2(20)  := 'XXCOI1_INVENTORY_DIV';      --受払表出力区分
    --メッセージ
    cv_xxcoi1_msg_10330   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10330';          --パラメータ棚卸区分
    cv_xxcoi1_msg_10099   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10099';          --パラメータ棚卸日
    cv_xxcoi1_msg_10100   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10100';          --パラメータ棚卸月
    cv_xxcoi1_msg_10096   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10096';          --パラメータ拠点
    cv_xxcoi1_msg_10101   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10101';          --パラメータ営業員
    cv_xxcoi1_msg_00011   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00011';          --業務処理日付
    cv_xxcoi1_msg_10102   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10102';          --棚卸日NULLチェック
    cv_xxcoi1_msg_10103   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10103';          --棚卸月NULLチェック
    cv_xxcoi1_msg_10104   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10104';          --棚卸日の型チェック
    cv_xxcoi1_msg_10105   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10105';          --棚卸月の型チェック
    cv_xxcoi1_msg_10106   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10106';          --拠点有効チェック
    cv_xxcoi1_msg_10203   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10203';          --営業員存在チェック
    cv_xxcoi1_msg_00005   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00005';          --在庫組織コード
    cv_xxcoi1_msg_00006   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00006';          --在庫組織ID
-- == 2009/07/22 V1.2 Added START ===============================================================
    cv_xxcoi1_msg_10197   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10197';          --棚卸日未来日チェックエラーメッセージ
    cv_xxcoi1_msg_10198   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10198';          --棚卸月未来日チェックエラーメッセージ
-- == 2009/07/22 V1.2 Added END   ===============================================================
-- == 2015/03/03 V1.7 Added START ===============================================================
    cv_xxcoi1_msg_00026   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00026';          --在庫会計期間取得エラーメッセージ
    cv_xxcoi1_msg_10451   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10451';          --在庫確定印字文字取得エラーメッセージ
-- == 2015/03/03 V1.7 Added END   ===============================================================
    --トークン
    cv_tkn_inv_type       CONSTANT  VARCHAR2(16)  := 'P_INVENTORY_TYPE';          --トークン棚卸区分
    cv_tkn_inv_date       CONSTANT  VARCHAR2(16)  := 'P_INVENTORY_DATE';          --トークン棚卸日
    cv_tkn_inv_month      CONSTANT  VARCHAR2(17)  := 'P_INVENTORY_MONTH';         --トークン棚卸月
    cv_tkn_base_code      CONSTANT  VARCHAR2(11)  := 'P_BASE_CODE';               --トークン拠点
    cv_tkn_sales_staff    CONSTANT  VARCHAR2(18)  := 'P_SALES_STAFF_CODE';        --トークン営業員
    cv_tkn_pro            CONSTANT  VARCHAR2(7)   := 'PRO_TOK';                   --トークンプロファイル名
    cv_tkn_org_code       CONSTANT  VARCHAR2(12)  := 'ORG_CODE_TOK';              --トークン在庫組織コード
-- == 2015/03/03 V1.7 Added START ===============================================================
    cv_tkn_target         CONSTANT  VARCHAR2(12)  := 'TARGET_DATE';               --トークン対象日
-- == 2015/03/03 V1.7 Added END   ===============================================================
    --プロファイル
    cv_prf_org_code       CONSTANT  VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';  --在庫組織コード
-- == 2015/03/03 V1.7 Added START ===============================================================
    cv_inv_cl_char        CONSTANT  VARCHAR2(24)  := 'XXCOI1_INV_CL_CHARACTER';   --在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
    --日付変換
    cv_ymd_sla            CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';                --日付変換用
    cv_ym_sla             CONSTANT  VARCHAR2(7)   := 'YYYY/MM';                   --年月変換用
    cv_ym                 CONSTANT  VARCHAR2(6)   := 'YYYYMM';                    --年月変化用（区切りなし）
    -- *** ローカル変数 ***
    lv_organization_code  VARCHAR2(4);                                            --在庫組織コード
    ln_organization_id    NUMBER;                                                 --在庫組織ID
-- == 2015/03/03 V1.7 Added START ===============================================================
    lb_chk_result         BOOLEAN;                                                --在庫会計期間チェック結果
-- == 2015/03/03 V1.7 Added END   ===============================================================
--
    lt_meaning            fnd_lookup_values.meaning%TYPE;                         --項目名
    ld_inv_date           DATE;                                                   --日付チェック用
    lv_short_account_name VARCHAR2(20);                                           --拠点略称
    lv_emp_name           VARCHAR2(300);                                          --従業員名称
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
    --===================================
    --1.入力パラメータ出力
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
    --棚卸日出力
    IF (iv_inventory_date IS NOT NULL) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10099
                      ,iv_token_name1  => cv_tkn_inv_date
                      ,iv_token_value1 => TO_CHAR(TO_DATE(iv_inventory_date, cv_ymd), cv_ymd_sla)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    END IF;
--
    --不正な棚卸月の場合、
    --ログ出力時にORACLEエラーとなるため
    --ログ出力前にチェック
    --====================================
    --4.棚卸月チェック（型チェック）
    --====================================
    --棚卸区分が30:月次
    IF (iv_inventory_kbn = cv_30) THEN
      --棚卸月日付型チェック
      BEGIN
-- == 2009/10/07 V1.6 Added START ===============================================================
        -- 入力型のチェック
        ld_inv_date := TO_DATE(iv_inventory_month, cv_ym_sla);
-- == 2009/10/07 V1.6 Added END   ===============================================================
        --YYYYMM型に変換
        ld_inv_date := TO_DATE(iv_inventory_month, cv_ym);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE inv_month_type_expt;
      END;
    END IF;
--
    --棚卸月
    IF (iv_inventory_month IS NOT NULL) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10100
                      ,iv_token_name1  => cv_tkn_inv_month
                      ,iv_token_value1 => TO_CHAR(TO_DATE(iv_inventory_month, cv_ym), cv_ym_sla)
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
    --営業員
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_10101
                    ,iv_token_name1  => cv_tkn_sales_staff
                    ,iv_token_value1 => iv_business
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --====================================
    --2.業務処理日付取得
    --====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL) THEN
      RAISE process_date_expt;
    END IF;
--
    --====================================
    --3.棚卸日チェック
    --====================================
    --棚卸区分が10:日次、20:月中
    IF    (iv_inventory_kbn IN (cv_10, cv_20)) THEN
      --棚卸日NULLチェック
      IF (iv_inventory_date IS NULL) THEN
        RAISE inv_date_null_expt;
      END IF;
      --棚卸日日付型チェック
      BEGIN
        --YYYYMMDD型に変換
        ld_inv_date := TO_DATE(iv_inventory_date, cv_ymd);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE inv_date_type_expt;
      END;
-- == 2009/07/22 V1.2 Added START ===============================================================
      -- 未来日チェック
      IF (ld_inv_date > gd_process_date) THEN
        -- 棚卸日未来日チェックエラーメッセージ(APP-XXCOI1-10197)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10197
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        RAISE global_process_expt;
      END IF;
-- == 2009/07/22 V1.2 Added END   ===============================================================
-- == 2009/07/14 V1.1 Added START ===============================================================
      gd_target_date := ld_inv_date;
-- == 2009/07/14 V1.1 Added END   ===============================================================
    END IF;
    --====================================
    --4.棚卸月チェック（NULLチェック）
    --====================================
    --棚卸区分が30:月次
    IF (iv_inventory_kbn = cv_30) THEN
      --棚卸月NULLチェック
      IF (iv_inventory_month IS NULL) THEN
        RAISE inv_month_null_expt;
      END IF;
-- == 2009/07/22 V1.2 Added START ===============================================================
      -- 未来日チェック
      IF (ld_inv_date > gd_process_date) THEN
        -- 棚卸月未来日チェックエラーメッセージ(APP-XXCOI1-10198)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10198
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        RAISE global_process_expt;
      END IF;
-- == 2009/07/22 V1.2 Added END   ===============================================================
-- == 2009/07/14 V1.1 Added START ===============================================================
      gd_target_date := LAST_DAY(TO_DATE(iv_inventory_month, cv_ym_sla));
-- == 2009/07/14 V1.1 Added END   ===============================================================
    END IF;
    --====================================
    --5.拠点略称取得
    --====================================
    BEGIN
      SELECT  SUBSTRB(hca.account_name, 1, 8)  account_name
      INTO    lv_short_account_name
      FROM    hz_cust_accounts hca
      WHERE   hca.customer_class_code = cv_1
      AND     hca.account_number      = iv_base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_base_expt;
    END;
    --====================================
    --6.従業員名称取得
    --====================================
    IF (iv_business IS NOT NULL) THEN
      BEGIN
-- == 2009/08/18 V1.4 Modified START ===============================================================
--        SELECT  papf.per_information18 || papf.per_information19  emp_name
        SELECT  SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)  emp_name
-- == 2009/08/18 V1.4 Modified END   ===============================================================
        INTO    lv_emp_name
        FROM    per_all_people_f  papf
        WHERE   papf.employee_number       = iv_business
        AND     papf.effective_start_date <= gd_process_date
        AND     ((papf.effective_end_date >= gd_process_date)
        OR      (papf.effective_end_date  IS NULL))
        AND     ROWNUM  = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE get_employee_expt;
      END;
    END IF;
    --====================================
    --7.プロファイルから在庫組織コードを取得
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
--
    IF (lv_organization_code IS NULL) THEN
      RAISE org_code_expt;
    END IF;
--
    --====================================
    --8.在庫組織コードから在庫組織IDを取得
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
--
    IF (ln_organization_id IS NULL) THEN
      RAISE org_id_expt;
    END IF;
--
    --OUTパラメータに設定
    ov_account_name     := lv_short_account_name;
    ov_emp_name         := lv_emp_name;
    on_organization_id  := ln_organization_id;
    ot_inv_kbn_name     := lt_meaning;
--
-- == 2015/03/03 V1.7 Added START ===============================================================
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
      RAISE global_process_expt;
    END IF;
--
    --====================================
    --帳票印字文字取得
    --====================================
    IF NOT(lb_chk_result) THEN
      ov_inv_cl_char := fnd_profile.value(cv_inv_cl_char);
      --
      IF (ov_inv_cl_char IS NULL) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10451
                      ,iv_token_name1  => cv_tkn_pro
                      ,iv_token_value1 => cv_inv_cl_char
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
-- == 2015/03/03 V1.7 Added END   ===============================================================
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
    --*** 棚卸日NULLチェックエラー ***
    WHEN inv_date_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10102
                 ,iv_token_name1  => cv_tkn_inv_type
                 ,iv_token_value1 => lt_meaning
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 棚卸日の型チェックエラー ***
    WHEN inv_date_type_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10104
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 棚卸月NULLチェックエラー ***
    WHEN inv_month_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10103
                 ,iv_token_name1  => cv_tkn_inv_type
                 ,iv_token_value1 => lt_meaning
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 棚卸月の型チェックエラー ***
    WHEN inv_month_type_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10105
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 拠点有効チェックエラー ***
    WHEN get_base_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10106
                 ,iv_token_name1  => cv_tkn_base_code
                 ,iv_token_value1 => iv_base_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** 営業員存在チェックエラー ***
    WHEN get_employee_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10203
                 ,iv_token_name1  => cv_tkn_sales_staff
                 ,iv_token_value1 => iv_business
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : ワークテーブルデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data         IN  daily_cur%ROWTYPE,              -- 1.CSV出力対象データ
    in_slit_id          IN  NUMBER,                         -- 2.処理連番
    iv_message          IN  VARCHAR2,                       -- 3.０件メッセージ
    iv_inventory_kbn    IN  VARCHAR2,                       -- 4.棚卸区分
    it_inv_kbn_name     IN  fnd_lookup_values.meaning%TYPE, -- 5.棚卸区分名称
    iv_account_name     IN  VARCHAR2,                       -- 6.拠点略称
    iv_emp_name         IN  VARCHAR2,                       -- 7.従業員名
    iv_inventory_date   IN  VARCHAR2,                       -- 8.棚卸日
    iv_inventory_month  IN  VARCHAR2,                       -- 9.棚卸月
    iv_base_code        IN  VARCHAR2,                       --10.拠点コード
    iv_emp_no           IN  VARCHAR2,                       --11.営業員コード
-- == 2015/03/03 V1.7 Added START ===============================================================
    iv_inv_cl_char      IN  VARCHAR2,                       --12.在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
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
    lv_year                   VARCHAR2(4);                                -- 年
    lv_month                  VARCHAR2(2);                                -- 月
    lv_day                    VARCHAR2(2);                                -- 日
    lv_base_code              VARCHAR2(4);                                -- 拠点コード
    lt_emp_no                 per_all_people_f.employee_number%TYPE;      -- 営業員コード
    lv_emp_name               VARCHAR2(300);                              -- 営業員名称
    lt_policy_group           ic_item_mst_b.attribute2%TYPE;              -- 群コード
    lt_item_code              ic_item_mst_b.item_no%TYPE;                 -- 商品コード
    lt_item_short_name        xxcmn_item_mst_b.item_short_name%TYPE;      -- 略称（商品）
    ln_operation_cost         NUMBER;                                     -- 営業原価
    ln_month_begin_qty        NUMBER;                                     -- 月首棚卸高
    ln_vd_sp_stock            NUMBER;                                     -- 倉庫より入庫
    ln_sales_shipped          NUMBER;                                     -- 売上出庫
    ln_customer_return        NUMBER;                                     -- 顧客返品
    ln_support_sample         NUMBER;                                     -- 協賛見本
    ln_inv_change_out         NUMBER;                                     -- VD出庫
    ln_inv_change_in          NUMBER;                                     -- VD入庫
    ln_warehouse_ship         NUMBER;                                     -- 倉庫へ返庫
    ln_tyoubo_stock           NUMBER;                                     -- 帳簿在庫
    ln_inventory              NUMBER;                                     -- 棚卸高
    ln_wear                   NUMBER;                                     -- 棚卸減耗
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
    IF (iv_message IS NOT NULL) THEN
      -- 対象件数０件の場合
      lt_emp_no           :=  iv_emp_no;                    --営業員コード
      lv_emp_name         :=  iv_emp_name;                  --営業員名称
      lt_policy_group     :=  NULL;                         --群コード
      lt_item_code        :=  NULL;                         --商品コード
      lt_item_short_name  :=  NULL;                         --商品名称
      ln_operation_cost   :=  NULL;                         --営業原価
      ln_month_begin_qty  :=  NULL;                         --月首棚卸高
      ln_vd_sp_stock      :=  NULL;                         --倉庫より入庫
      ln_sales_shipped    :=  NULL;                         --売上出庫
      ln_customer_return  :=  NULL;                         --顧客返品
      ln_support_sample   :=  NULL;                         --協賛見本
      ln_inv_change_out   :=  NULL;                         --VD出庫
      ln_inv_change_in    :=  NULL;                         --VD入庫
      ln_warehouse_ship   :=  NULL;                         --倉庫へ返庫
      ln_tyoubo_stock     :=  NULL;                         --帳簿在庫
      ln_inventory        :=  NULL;                         --棚卸高
      ln_wear             :=  NULL;                         --棚卸減耗
    ELSE
      lt_emp_no           :=  ir_svf_data.emp_no;           --営業員コード
      lv_emp_name         :=  ir_svf_data.emp_name;         --営業員名称
      lt_policy_group     :=  ir_svf_data.policy_group;     --群コード
      lt_item_code        :=  ir_svf_data.item_no;          --商品コード
      lt_item_short_name  :=  ir_svf_data.item_short_name;  --商品名称
      ln_operation_cost   :=  ir_svf_data.operation_cost;   --営業原価
      ln_month_begin_qty  :=  ir_svf_data.month_begin_qty;  --月首棚卸高
      ln_vd_sp_stock      :=  ir_svf_data.vd_sp_stock;      --倉庫より入庫
      ln_sales_shipped    :=  ir_svf_data.sales_shipped;    --売上出庫
      ln_customer_return  :=  ir_svf_data.customer_return;  --顧客返品
      ln_support_sample   :=  ir_svf_data.support_sample;   --協賛見本
      ln_inv_change_out   :=  ir_svf_data.inv_change_out;   --VD出庫
      ln_inv_change_in    :=  ir_svf_data.inv_change_in;    --VD入庫
      ln_warehouse_ship   :=  ir_svf_data.warehouse_ship;   --倉庫へ返庫
      ln_tyoubo_stock     :=  ir_svf_data.tyoubo_stock;     --帳簿在庫
      ln_inventory        :=  ir_svf_data.inventory;        --棚卸高
      ln_wear             :=  ir_svf_data.inv_wear;         --棚卸減耗
    END IF;
    --
    -- 受払残高表帳票（営業員）帳票ワークテーブルへ挿入
    INSERT INTO xxcoi_rep_employee_rcpt(
       slit_id                    -- 1.受払残高情報ID
      ,inventory_kbn              -- 2.棚卸区分（内容）
      ,in_out_year                -- 3.年
      ,in_out_month               -- 4.月
      ,in_out_dat                 -- 5.日
      ,base_code                  -- 6.拠点コード
      ,base_name                  -- 7.拠点名称
-- == 2015/03/03 V1.7 Added START ===============================================================
      ,inv_cl_char                --   在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
      ,employee_code              -- 8.営業員コード
      ,employee_name              -- 9.営業員名称
      ,gun_code                   --10.群コード
      ,item_code                  --11.商品コード
      ,item_name                  --12.商品名称
      ,operation_cost             --13.営業原価
      ,first_inventory_qty        --14.月首棚卸高
      ,warehouse_stock            --15.倉庫より入庫
      ,sales_qty                  --16.売上出庫
      ,customer_return            --17.顧客返品
      ,support_qty                --18.協賛見本
      ,vd_ship_qty                --19.VD出庫
      ,vd_in_qty                  --20.VD入庫
      ,warehouse_ship             --21.倉庫へ返庫
      ,tyoubo_stock_qty           --22.帳簿在庫
      ,inventory_qty              --23.棚卸高
      ,genmou_qty                 --24.棚卸減耗
      ,message                    --25.メッセージ ※０件用
      ,last_update_date           --26.最終更新日
      ,last_updated_by            --27.最終更新者
      ,creation_date              --28.作成日
      ,created_by                 --29.作成者
      ,last_update_login          --30.最終更新ユーザ
      ,request_id                 --31.要求ID
      ,program_application_id     --32.プログラムアプリケーションID
      ,program_id                 --33.プログラムID
      ,program_update_date        --34.プログラム更新日
    )VALUES(
       in_slit_id                 -- 1.受払残高情報ID
      ,it_inv_kbn_name            -- 2.棚卸区分
      ,lv_year                    -- 3.年
      ,lv_month                   -- 4.月
      ,lv_day                     -- 5.日
      ,iv_base_code               -- 6.拠点コード
      ,iv_account_name            -- 7.拠点名称
-- == 2015/03/03 V1.7 Added START ===============================================================
      ,iv_inv_cl_char             --   在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
      ,lt_emp_no                  -- 8.営業員コード
      ,lv_emp_name                -- 9.営業員名称
      ,lt_policy_group            --10.群コード
      ,lt_item_code               --11.商品コード
      ,lt_item_short_name         --12.商品名称
      ,ln_operation_cost          --13.営業原価
      ,ln_month_begin_qty         --14.月首棚卸高
      ,ln_vd_sp_stock             --15.倉庫より入庫
      ,ln_sales_shipped           --16.売上出庫
      ,ln_customer_return         --17.顧客返品
      ,ln_support_sample          --18.協賛見本
      ,ln_inv_change_out          --19.VD出庫
      ,ln_inv_change_in           --20.VD入庫
      ,ln_warehouse_ship          --21.倉庫へ返庫
      ,ln_tyoubo_stock            --22.帳簿在庫
      ,ln_inventory               --23.棚卸高
      ,ln_wear                    --24.棚卸減耗
      ,iv_message                 --25.メッセージ ※０件用
      ,SYSDATE                    --26.最終更新日
      ,cn_last_updated_by         --27.最終更新者
      ,SYSDATE                    --28.作成日
      ,cn_created_by              --29.作成者
      ,cn_last_update_login       --30.最終更新ユーザ
      ,cn_request_id              --31.要求ID
      ,cn_program_application_id  --32.プログラムアプリケーションID
      ,cn_program_id              --33.プログラムID
      ,SYSDATE                    --34.プログラム更新日
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
   * Description      : SVF起動(A-4)
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
    --メッセージ
    cv_xxcoi1_msg_10088       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10088';       --帳票出力エラー
    -- SVF起動関数パラメータ用
    cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A14R';           -- コンカレント名
    cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                   -- 拡張子（PDF）
    cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A14R';           -- 帳票ID
    cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                      -- 出力区分
    cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A14S.xml';       -- フォーム様式ファイル名
    cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A14S.vrq';       -- クエリー様式ファイル名
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
    -- 終了パラメータ判定
    IF (lv_retcode  <>  cv_status_normal) THEN
      -- 帳票出力エラー
      RAISE output_expt;
    END IF; 
--
  EXCEPTION
    --*** 帳票出力エラー ***
    WHEN output_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10088
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ワークテーブルデータ削除(A-5)
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
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===============================
    --  1.ワークテーブル削除
    -- ===============================
    DELETE  FROM xxcoi_rep_employee_rcpt
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
    iv_business         IN  VARCHAR2,   -- 5.営業員
    ov_errbuf           OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
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
-- == 2015/03/03 V1.7 Added START ===============================================================
    lv_inv_cl_char                      VARCHAR2(4);                            --在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
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
    cv_xxcoi1_msg_00008   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00008';  --対象データなし
--
    -- *** ローカル変数 ***
--
    lv_zero_msg           VARCHAR2(5000);
    --
    lv_account_name       VARCHAR2(16);
    lv_emp_name           VARCHAR2(300);
    ln_organization_id    NUMBER;
    lt_inv_kbn_name       fnd_lookup_values.meaning%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
    inv_data_rec daily_cur%ROWTYPE;
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
    lv_zero_msg   := NULL;
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
      iv_inventory_kbn    =>  iv_inventory_kbn    -- 1.棚卸区分
     ,iv_inventory_date   =>  iv_inventory_date   -- 2.棚卸日
     ,iv_inventory_month  =>  iv_inventory_month  -- 3.棚卸月
     ,iv_base_code        =>  iv_base_code        -- 4.拠点コード
     ,iv_business         =>  iv_business         -- 5.営業員
     ,ov_account_name     =>  lv_account_name     -- 6.拠点略称
     ,ov_emp_name         =>  lv_emp_name         -- 7.従業員名
     ,on_organization_id  =>  ln_organization_id  -- 8.在庫組織コード
     ,ot_inv_kbn_name     =>  lt_inv_kbn_name     -- 9.棚卸区分名称
-- == 2015/03/03 V1.7 Added START ===============================================================
     ,ov_inv_cl_char      =>  lv_inv_cl_char      -- 10.在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
     ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <データ取得 A-2>
    -- ===============================
    --棚卸区分が日次
    IF (iv_inventory_kbn = cv_10) THEN
      OPEN  daily_cur(
              iv_business         => iv_business
             ,iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,in_organization_id  => ln_organization_id);
      FETCH daily_cur INTO inv_data_rec;
      --対象データ０件
      IF (daily_cur%NOTFOUND) THEN
        lv_zero_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                       );
      END IF;
    --棚卸区分が月中又は、月次
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      OPEN  monthly_cur(
              iv_business         => iv_business
             ,iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,iv_inventory_month  => iv_inventory_month
             ,iv_inventory_kbn    => iv_inventory_kbn
             ,in_organization_id  => ln_organization_id);
      FETCH monthly_cur INTO inv_data_rec;
      --対象データ０件
      IF (monthly_cur%NOTFOUND) THEN
        lv_zero_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                       );
      END IF;
    END IF;
--
    <<ins_work_loop>>
    LOOP
      -- 対象件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      -- ===============================
      --  A-3.ワークテーブルデータ登録
      -- ===============================
      ins_svf_data(
         ir_svf_data        =>  inv_data_rec        -- 1.CSV出力用データ
        ,in_slit_id         =>  gn_target_cnt       -- 2.処理連番
        ,iv_message         =>  lv_zero_msg         -- 3.０件メッセージ
        ,iv_inventory_kbn   =>  iv_inventory_kbn    -- 4.棚卸区分
        ,it_inv_kbn_name    =>  lt_inv_kbn_name     -- 5.棚卸区分名称
        ,iv_account_name    =>  lv_account_name     -- 6.拠点略称
        ,iv_emp_name        =>  lv_emp_name         -- 7.営業員名称
        ,iv_inventory_date  =>  iv_inventory_date   -- 8.棚卸日
        ,iv_inventory_month =>  iv_inventory_month  -- 9.棚卸月
        ,iv_base_code       =>  iv_base_code        --10.拠点コード
        ,iv_emp_no          =>  iv_business         --11.営業員コード
-- == 2015/03/03 V1.7 Added START ===============================================================
        ,iv_inv_cl_char     =>  lv_inv_cl_char      --12.在庫確定印字文字
-- == 2015/03/03 V1.7 Added END   ===============================================================
        ,ov_errbuf          =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,ov_retcode         =>  lv_retcode          -- リターン・コード             --# 固定 #
        ,ov_errmsg          =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        -- エラー処理
        RAISE global_process_expt;
      END IF;
      -- 対象データ０件の場合、ワークテーブル作成処理終了
      EXIT WHEN lv_zero_msg IS NOT NULL;
      -- 対象データ取得
      --棚卸区分 = 日次
      IF (iv_inventory_kbn =  cv_10)  THEN
        FETCH daily_cur INTO inv_data_rec;
        EXIT WHEN daily_cur%NOTFOUND;
      --棚卸区分 = 月中、月次
      ELSIF (iv_inventory_kbn IN (cv_20, cv_30))
      THEN
        FETCH monthly_cur INTO inv_data_rec;
        EXIT WHEN monthly_cur%NOTFOUND;
      END IF;
      --
    END LOOP ins_work_loop;
    -- カーソルクローズ
      --棚卸区分 = 日次
    IF (iv_inventory_kbn = cv_10) THEN
      CLOSE daily_cur;
      --棚卸区分 = 月中、月次
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      CLOSE monthly_cur;
    END IF;
    -- コミット処理
    COMMIT;
    -- ===============================
    --  A-4.SVF起動
    -- ===============================
    call_output_svf(
       ov_errbuf    =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   =>  lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg    =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  A-5.ワークテーブルデータ削除
    -- ===============================
    del_svf_data(
       ov_errbuf    =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   =>  lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg    =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
    --
    -- 正常終了件数
    IF (lv_zero_msg IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      --エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
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
    iv_inventory_kbn   IN   VARCHAR2,      -- 1.棚卸区分
    iv_inventory_date  IN   VARCHAR2,      -- 2.棚卸日
    iv_inventory_month IN   VARCHAR2,      -- 3.棚卸月
    iv_base_code       IN   VARCHAR2,      -- 4.拠点
    iv_business        IN   VARCHAR2       -- 5.営業員
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
       iv_inventory_kbn   =>  iv_inventory_kbn    -- 1.棚卸区分
-- == 2009/07/22 V1.2 Modified START ===============================================================
--      ,iv_inventory_date  =>  iv_inventory_date   -- 2.棚卸日
      ,iv_inventory_date  =>  REPLACE(SUBSTRB(iv_inventory_date, 1, 10), cv_replace_sign)   -- 2.棚卸日
-- == 2009/07/22 V1.2 Modified END   ===============================================================
      ,iv_inventory_month =>  iv_inventory_month  -- 3.棚卸月
      ,iv_base_code       =>  iv_base_code        -- 4.拠点
      ,iv_business        =>  iv_business         -- 5.営業員
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
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
       which  => FND_FILE.LOG
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
END XXCOI006A14R;
/
