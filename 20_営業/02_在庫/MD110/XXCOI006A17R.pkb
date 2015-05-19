CREATE OR REPLACE PACKAGE BODY XXCOI006A17R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A17R(body)
 * Description      : 受払残高表（拠点別計）
 * MD.050           : 受払残高表（拠点別計） <MD050_XXCOI_006_A17>
 * Version          : V1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_svf_data           ワークテーブルデータ削除               (A-6)
 *  call_output_svf        SVF起動                                (A-5)
 *  ins_svf_data           ワークテーブルデータ登録               (A-4)
 *  valid_param_value      パラメータチェック                     (A-2)
 *  init                   初期処理                               (A-1)
 *  submain                メイン処理プロシージャ
 *                         データ取得                             (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   H.Sasaki         初版作成
 *  2009/02/19    1.1   H.Sasaki         [障害COI_021]顧客マスタのステータスを検索条件に追加
 *  2009/06/02    1.2   H.Sasaki         [T1_1293]棚卸減耗数量取得条件を追加
 *  2009/06/26    1.3   H.Sasaki         [0000258]T1_1293の対応を取り消し
 *                                                払出合計に基準在庫変更入庫を追加
 *  2009/07/21    1.4   H.Sasaki         [0000642]払出合計の金額算出方法を変更
 *  2015/03/03    1.5   Y.Koh            障害対応E_本稼動_12827
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOI006A17R';         -- パッケージ名
  -- メッセージ関連
  cv_short_name_xxcoi       CONSTANT VARCHAR2(5)  :=  'XXCOI';                  -- アプリケーション短縮名
  cv_msg_xxcoi1_00008       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00008';       -- 対象データ無しメッセージ
  cv_msg_xxcoi1_00011       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00011';       -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10107       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10107';       -- パラメータ受払年月値メッセージ
  cv_msg_xxcoi1_10108       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10108';       -- パラメータ原価区分値メッセージ
  cv_msg_xxcoi1_10110       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10110';       -- 受払年月型チェックエラーメッセージ
  cv_msg_xxcoi1_10111       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10111';       -- 受払年月未来日チェックエラーメッセージ
  cv_msg_xxcoi1_10114       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10114';       -- 原価区分名取得エラーメッセージ
  cv_msg_xxcoi1_10119       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10119';       -- SVF起動APIエラーメッセージ
-- == 2015/03/03 V1.5 Added START ===============================================================
  cv_msg_xxcoi1_00005       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00005';       -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00006';       -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00026       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00026';       -- 在庫会計期間取得エラーメッセージ
  cv_msg_xxcoi1_10451       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10451';       -- 在庫確定印字文字取得エラーメッセージ
-- == 2015/03/03 V1.5 Added END   ===============================================================
  cv_token_10107_1          CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';      -- APP-XXCOI1-10107用トークン
  cv_token_10108_1          CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';            -- APP-XXCOI1-10108用トークン
-- == 2015/03/03 V1.5 Added START ===============================================================
  cv_token_00005_1          CONSTANT VARCHAR2(12) := 'PRO_TOK';                 -- APP-XXCOI1-00026用トークン（トークンプロファイル名）
  cv_token_00006_1          CONSTANT VARCHAR2(12) := 'ORG_CODE_TOK';            -- APP-XXCOI1-00026用トークン（トークン在庫組織コード）
  cv_token_00026_1          CONSTANT VARCHAR2(12) := 'TARGET_DATE';             -- APP-XXCOI1-00026用トークン（トークン対象日）
  cv_token_10451_1          CONSTANT VARCHAR2(12) := 'PRO_TOK';                 -- APP-XXCOI1-10451用トークン（トークンプロファイル名）
-- == 2015/03/03 V1.5 Added END   ===============================================================
-- == 2015/03/03 V1.5 Added START ===============================================================
  --プロファイル
  cv_prf_org_code           CONSTANT VARCHAR2(24) := 'XXCOI1_ORGANIZATION_CODE';-- プロファイル名（在庫組織コード）
  cv_inv_cl_char            CONSTANT VARCHAR2(24) := 'XXCOI1_INV_CL_CHARACTER'; -- プロファイル名（在庫確定印字文字）
-- == 2015/03/03 V1.5 Added END   ===============================================================
  -- LOOKUP_TYPE
  cv_xxcoi_cost_price_div   CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';  -- LOOKUP_TYPE（原価区分）
  -- 棚卸区分（1:月中  2:月末）
  cv_inv_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  -- 顧客
  cv_cust_cls_1             CONSTANT VARCHAR2(1)  :=  '1';                      -- 顧客区分（1:拠点）
  cv_status_active          CONSTANT VARCHAR2(1)  :=  'A';                      -- ステータス：Active
  -- その他
  cv_type_month             CONSTANT VARCHAR2(6)  :=  'YYYYMM';                 -- DATE型 年月（YYYYMM）
  cv_type_date              CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';               -- DATE型 年月日（YYYYMMDD）
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                    -- コンカレントヘッダ出力先
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                      -- 半角スペース
-- == 2009/06/02 V1.2 Added START ===============================================================
  cv_9                      CONSTANT VARCHAR2(1)  :=  '9';                      -- 棚卸対象（9:対象外）
-- == 2009/06/02 V1.2 Added END   ===============================================================
  -- SVF起動関数パラメータ用
  cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A17R';           -- コンカレント名
  cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                   -- 拡張子（PDF）
  cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A17R';           -- 帳票ID
  cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                      -- 出力区分
  cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A17S.xml';       -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A17S.vrq';       -- クエリー様式ファイル名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_param_reception_date   VARCHAR2(6);                        -- 受払年月（YYYYMM）
  gv_param_cost_type        VARCHAR2(2);                        -- 原価区分（10:営業原価、20:標準原価）
  -- その他
  gd_f_process_date         DATE;                               -- 業務日付
  gt_cost_type_name         fnd_lookup_values.meaning%TYPE;     -- 原価区分名
-- == 2015/03/03 V1.5 Added START ===============================================================
  gd_target_date            DATE;
-- == 2015/03/03 V1.5 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  CURSOR  svf_data_cur
  IS
-- == 2009/06/26 V1.3 Mdified START ===============================================================
-- == 2009/06/02 V1.2 Mdified START ===============================================================
    SELECT  xirm.base_code                      base_code                 -- 拠点コード
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- 拠点名称
           ,xirm.month_begin_quantity           month_begin_quantity      -- 月首棚卸高
           ,xirm.factory_stock                  factory_stock             -- 工場入庫
           ,xirm.factory_stock_b                factory_stock_b           -- 工場入庫振戻
           ,xirm.change_stock                   change_stock              -- 倉替入庫
           ,xirm.goods_transfer_new             goods_transfer_new        -- 商品振替（新商品）
           ,xirm.inv_result                     inv_result                -- 棚卸結果
           ,xirm.inv_result_bad                 inv_result_bad            -- 棚卸結果(不良品)
           ,xirm.inv_wear                       inv_wear                  -- 棚卸減耗
           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
                 ELSE  xirm.standard_cost
            END                                 cost_amt                  -- 原価
           ,xirm.sales_shipped                  sales_shipped             -- 売上出庫
           ,xirm.sales_shipped_b                sales_shipped_b           -- 売上出庫振戻
           ,xirm.return_goods                   return_goods              -- 返品
           ,xirm.return_goods_b                 return_goods_b            -- 返品振戻
           ,xirm.change_ship                    change_ship               -- 倉替出庫
           ,xirm.goods_transfer_old             goods_transfer_old        -- 商品振替(旧商品)
           ,xirm.sample_quantity                sample_quantity           -- 見本出庫
           ,xirm.sample_quantity_b              sample_quantity_b         -- 見本出庫振戻
           ,xirm.customer_sample_ship           customer_sample_ship      -- 顧客見本出庫
           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- 顧客見本出庫振戻
           ,xirm.customer_support_ss            customer_support_ss       -- 顧客協賛見本出庫
           ,xirm.customer_support_ss_b          customer_support_ss_b     -- 顧客協賛見本出庫振戻
           ,xirm.ccm_sample_ship                ccm_sample_ship           -- 顧客広告宣伝費A自社商品
           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
           ,xirm.inventory_change_out           inventory_change_out      -- 基準在庫変更出庫
           ,xirm.inventory_change_in            inventory_change_in       -- 基準在庫変更入庫
           ,xirm.factory_return                 factory_return            -- 工場返品
           ,xirm.factory_return_b               factory_return_b          -- 工場返品振戻
           ,xirm.factory_change                 factory_change            -- 工場倉替
           ,xirm.factory_change_b               factory_change_b          -- 工場倉替振戻
           ,xirm.removed_goods                  removed_goods             -- 廃却
           ,xirm.removed_goods_b                removed_goods_b           -- 廃却振戻
    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
           ,hz_cust_accounts                    hca                       -- 顧客マスタ
    WHERE   xirm.practice_month     =   gv_param_reception_date
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1
    AND     hca.status              =   cv_status_active
    ORDER BY  xirm.base_code;
--
--    SELECT  xirm.base_code                      base_code                 -- 拠点コード
--           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- 拠点名称
--           ,xirm.month_begin_quantity           month_begin_quantity      -- 月首棚卸高
--           ,xirm.factory_stock                  factory_stock             -- 工場入庫
--           ,xirm.factory_stock_b                factory_stock_b           -- 工場入庫振戻
--           ,xirm.change_stock                   change_stock              -- 倉替入庫
--           ,xirm.goods_transfer_new             goods_transfer_new        -- 商品振替（新商品）
--           ,xirm.inv_result                     inv_result                -- 棚卸結果
--           ,xirm.inv_result_bad                 inv_result_bad            -- 棚卸結果(不良品)
--           ,DECODE(msi.attribute5, cv_9, 0
--                                       , xirm.inv_wear
--            )                                   inv_wear                  -- 棚卸減耗
--           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
--                 ELSE  xirm.standard_cost
--            END                                 cost_amt                  -- 原価
--           ,xirm.sales_shipped                  sales_shipped             -- 売上出庫
--           ,xirm.sales_shipped_b                sales_shipped_b           -- 売上出庫振戻
--           ,xirm.return_goods                   return_goods              -- 返品
--           ,xirm.return_goods_b                 return_goods_b            -- 返品振戻
--           ,xirm.change_ship                    change_ship               -- 倉替出庫
--           ,xirm.goods_transfer_old             goods_transfer_old        -- 商品振替(旧商品)
--           ,xirm.sample_quantity                sample_quantity           -- 見本出庫
--           ,xirm.sample_quantity_b              sample_quantity_b         -- 見本出庫振戻
--           ,xirm.customer_sample_ship           customer_sample_ship      -- 顧客見本出庫
--           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- 顧客見本出庫振戻
--           ,xirm.customer_support_ss            customer_support_ss       -- 顧客協賛見本出庫
--           ,xirm.customer_support_ss_b          customer_support_ss_b     -- 顧客協賛見本出庫振戻
--           ,xirm.ccm_sample_ship                ccm_sample_ship           -- 顧客広告宣伝費A自社商品
--           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
--           ,xirm.inventory_change_out           inventory_change_out      -- 基準在庫変更出庫
--           ,xirm.factory_return                 factory_return            -- 工場返品
--           ,xirm.factory_return_b               factory_return_b          -- 工場返品振戻
--           ,xirm.factory_change                 factory_change            -- 工場倉替
--           ,xirm.factory_change_b               factory_change_b          -- 工場倉替振戻
--           ,xirm.removed_goods                  removed_goods             -- 廃却
--           ,xirm.removed_goods_b                removed_goods_b           -- 廃却振戻
--    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
--           ,hz_cust_accounts                    hca                       -- 顧客マスタ
--           ,mtl_secondary_inventories           msi                       -- 保管場所マスタ
--    WHERE   xirm.practice_month     =   gv_param_reception_date
--    AND     xirm.inventory_kbn      =   cv_inv_kbn_2
--    AND     xirm.base_code          =   hca.account_number
--    AND     hca.customer_class_code =   cv_cust_cls_1
--    AND     hca.status              =   cv_status_active
--    AND     xirm.subinventory_code  =   msi.secondary_inventory_name
--    AND     xirm.organization_id    =   msi.organization_id
--    ORDER BY  xirm.base_code;
-- == 2009/06/02 V1.2 Mdified END   ===============================================================
-- == 2009/06/26 V1.3 Mdified END   ===============================================================
  --
  svf_data_rec    svf_data_cur%ROWTYPE;
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
    DELETE  FROM xxcoi_rep_base_rcpt
    WHERE   request_id  = cn_request_id;
    --
  EXCEPTION
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
  END del_svf_data;
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
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_type_date) || TO_CHAR(cn_request_id) || cv_type_pdf            -- 出力ファイル名
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
      -- SVF起動APIエラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10119
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF; 
--
  EXCEPTION
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data   IN  svf_data_cur%ROWTYPE,   -- 1.CSV出力対象データ
    in_slit_id    IN  NUMBER,                 -- 2.処理連番
    iv_message    IN  VARCHAR2,               -- 3.０件メッセージ
-- == 2015/03/03 V1.5 Added START ===============================================================
    iv_inv_cl_char IN  VARCHAR2,              -- 4.在庫確定印字文字
-- == 2015/03/03 V1.5 Added END   ===============================================================
    ov_errbuf     OUT VARCHAR2,               -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,               -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)               -- ユーザー・エラー・メッセージ        --# 固定 #
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
    lv_base_code              VARCHAR2(4);  -- 拠点コード
    lv_base_name              VARCHAR2(8);  -- 拠点名称
    ln_first_inventory_qty    NUMBER;       -- 月首棚卸高(数量)
    ln_factry_in_qty          NUMBER;       -- 工場入庫(数量)
    ln_kuragae_in_qty         NUMBER;       -- 倉替入庫(数量)
    ln_hurikae_in_qty         NUMBER;       -- 振替入庫(数量)
    ln_payment_total_qty      NUMBER;       -- 払出合計(数量)
    ln_inventory_total_qty    NUMBER;       -- 棚卸高計(数量)
    ln_inferior_goods_qty     NUMBER;       -- 不良品棚卸高(数量)
    ln_genmou_qty             NUMBER;       -- 棚卸減耗(数量)
    ln_first_inventory_money  NUMBER;       -- 月首棚卸高(金額)
    ln_factry_in_money        NUMBER;       -- 工場入庫(金額)
    ln_kuragae_in_money       NUMBER;       -- 倉替入庫(金額)
    ln_hurikae_in_money       NUMBER;       -- 振替入庫(金額)
    ln_payment_total_money    NUMBER;       -- 払出合計(金額)
    ln_inventory_total_money  NUMBER;       -- 棚卸高計(金額)
    ln_inferior_goods_money   NUMBER;       -- (不良品棚卸高)(金額)
    ln_genmou_money           NUMBER;       -- 棚卸減耗(金額)
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
    -- データ設定
    IF (iv_message IS NOT NULL) THEN
      lv_base_code              :=  NULL;     -- 05.拠点コード
      lv_base_name              :=  NULL;     -- 06.拠点名称
      ln_first_inventory_qty    :=  NULL;     -- 07.月首棚卸高(数量)
      ln_factry_in_qty          :=  NULL;     -- 08.工場入庫(数量)
      ln_kuragae_in_qty         :=  NULL;     -- 09.倉替入庫(数量)
      ln_hurikae_in_qty         :=  NULL;     -- 10.振替入庫(数量)
      ln_payment_total_qty      :=  NULL;     -- 11.払出合計(数量)
      ln_inventory_total_qty    :=  NULL;     -- 12.棚卸高計(数量)
      ln_inferior_goods_qty     :=  NULL;     -- 13.不良品棚卸高(数量)
      ln_genmou_qty             :=  NULL;     -- 14.棚卸減耗(数量)
      ln_first_inventory_money  :=  NULL;     -- 15.月首棚卸高(金額)
      ln_factry_in_money        :=  NULL;     -- 16.工場入庫(金額)
      ln_kuragae_in_money       :=  NULL;     -- 17.倉替入庫(金額)
      ln_hurikae_in_money       :=  NULL;     -- 18.振替入庫(金額)
      ln_payment_total_money    :=  NULL;     -- 19.払出合計(金額)
      ln_inventory_total_money  :=  NULL;     -- 20.棚卸高計(金額)
      ln_inferior_goods_money   :=  NULL;     -- 21.(不良品棚卸高)(金額)
      ln_genmou_money           :=  NULL;     -- 22.棚卸減耗(金額)
      --
    ELSE
      lv_base_code              :=    ir_svf_data.base_code;                          -- 05.拠点コード
      lv_base_name              :=    ir_svf_data.account_name;                       -- 06.拠点名称
      ln_first_inventory_qty    :=    ir_svf_data.month_begin_quantity;               -- 07.月首棚卸高(数量)
      ln_factry_in_qty          :=    ir_svf_data.factory_stock
                                    - ir_svf_data.factory_stock_b;                    -- 08.工場入庫(数量)
      ln_kuragae_in_qty         :=    ir_svf_data.change_stock;                       -- 09.倉替入庫(数量)
      ln_hurikae_in_qty         :=    ir_svf_data.goods_transfer_new;                 -- 10.振替入庫(数量)
      ln_payment_total_qty      :=    ir_svf_data.sales_shipped
                                    - ir_svf_data.sales_shipped_b
                                    - ir_svf_data.return_goods
                                    + ir_svf_data.return_goods_b
                                    + ir_svf_data.change_ship
                                    + ir_svf_data.goods_transfer_old
                                    + ir_svf_data.sample_quantity
                                    - ir_svf_data.sample_quantity_b
                                    + ir_svf_data.customer_sample_ship
                                    - ir_svf_data.customer_sample_ship_b
                                    + ir_svf_data.customer_support_ss
                                    - ir_svf_data.customer_support_ss_b
                                    + ir_svf_data.ccm_sample_ship
                                    - ir_svf_data.ccm_sample_ship_b
                                    + ir_svf_data.inventory_change_out
-- == 2009/06/26 V1.3 Added START ===============================================================
                                    - ir_svf_data.inventory_change_in
-- == 2009/06/26 V1.3 Added END   ===============================================================
                                    + ir_svf_data.factory_return
                                    - ir_svf_data.factory_return_b
                                    + ir_svf_data.factory_change
                                    - ir_svf_data.factory_change_b
                                    + ir_svf_data.removed_goods
                                    - ir_svf_data.removed_goods_b;                    -- 11.払出合計(数量)
      ln_inventory_total_qty    :=    ir_svf_data.inv_result
                                    + ir_svf_data.inv_result_bad;                     -- 12.棚卸高計(数量)
      ln_inferior_goods_qty     :=    ir_svf_data.inv_result_bad;                     -- 13.不良品棚卸高(数量)
      ln_genmou_qty             :=    ir_svf_data.inv_wear;                           -- 14.棚卸減耗(数量)
      ln_first_inventory_money  :=    ROUND(ir_svf_data.cost_amt * ln_first_inventory_qty);  -- 15.月首棚卸高(金額)
      ln_factry_in_money        :=    ROUND(ir_svf_data.cost_amt * ln_factry_in_qty);        -- 16.工場入庫(金額)
      ln_kuragae_in_money       :=    ROUND(ir_svf_data.cost_amt * ln_kuragae_in_qty);       -- 17.倉替入庫(金額)
      ln_hurikae_in_money       :=    ROUND(ir_svf_data.cost_amt * ln_hurikae_in_qty);       -- 18.振替入庫(金額)
-- == 2009/07/21 V1.4 Modified START ===============================================================
--      ln_payment_total_money    :=    ROUND(ir_svf_data.cost_amt * ln_payment_total_qty);    -- 19.払出合計(金額)
      ln_payment_total_money    :=    ROUND((  ir_svf_data.sales_shipped
                                             - ir_svf_data.sales_shipped_b
                                             - ir_svf_data.return_goods
                                             + ir_svf_data.return_goods_b
                                            )                    * ir_svf_data.cost_amt)
                                    + ROUND((  ir_svf_data.customer_support_ss
                                             - ir_svf_data.customer_support_ss_b
                                             + ir_svf_data.ccm_sample_ship
                                             - ir_svf_data.ccm_sample_ship_b
                                            )                    * ir_svf_data.cost_amt)
                                    + ROUND((  ir_svf_data.sample_quantity
                                             - ir_svf_data.sample_quantity_b
                                             + ir_svf_data.customer_sample_ship
                                             - ir_svf_data.customer_sample_ship_b
                                            )                    * ir_svf_data.cost_amt)
                                    + ROUND((  ir_svf_data.inventory_change_out
                                             - ir_svf_data.inventory_change_in
                                            )                    * ir_svf_data.cost_amt)
                                    + ROUND((  ir_svf_data.removed_goods
                                             - ir_svf_data.removed_goods_b
                                            )                    * ir_svf_data.cost_amt)
                                    + ROUND(ir_svf_data.change_ship
                                                                 * ir_svf_data.cost_amt)
                                    + ROUND(ir_svf_data.goods_transfer_old
                                                                 * ir_svf_data.cost_amt)
                                    + ROUND((  ir_svf_data.factory_change
                                             - ir_svf_data.factory_change_b
                                            )                    * ir_svf_data.cost_amt)
                                    + ROUND((  ir_svf_data.factory_return
                                             - ir_svf_data.factory_return_b
                                            )                    * ir_svf_data.cost_amt);    -- 19.払出合計(金額)
-- == 2009/07/21 V1.4 Modified END   ===============================================================
      ln_inventory_total_money  :=    ROUND(ir_svf_data.cost_amt * ln_inventory_total_qty);  -- 20.棚卸高計(金額)
      ln_inferior_goods_money   :=    ROUND(ir_svf_data.cost_amt * ln_inferior_goods_qty);   -- 21.(不良品棚卸高)(金額)
      ln_genmou_money           :=    ROUND(ir_svf_data.cost_amt * ln_genmou_qty);           -- 22.棚卸減耗(金額)
    END IF;
    --
    -- 挿入処理
    INSERT INTO xxcoi_rep_base_rcpt(
       slit_id                                  -- 01.受払残高情報ID
      ,in_out_year                              -- 02.年
      ,in_out_month                             -- 03.月
      ,cost_kbn                                 -- 04.原価区分
      ,base_code                                -- 05.拠点コード
      ,base_name                                -- 06.拠点名称
-- == 2015/03/03 V1.5 Added START ===============================================================
      ,inv_cl_char                              --    在庫確定印字文字
-- == 2015/03/03 V1.5 Added END   ===============================================================
      ,first_inventory_qty                      -- 07.月首棚卸高(数量)
      ,factry_in_qty                            -- 08.工場入庫(数量)
      ,kuragae_in_qty                           -- 09.倉替入庫(数量)
      ,hurikae_in_qty                           -- 10.振替入庫(数量)
      ,payment_total_qty                        -- 11.払出合計(数量)
      ,inventory_total_qty                      -- 12.棚卸高計(数量)
      ,inferior_goods_qty                       -- 13.不良品棚卸高(数量)
      ,genmou_qty                               -- 14.棚卸減耗(数量)
      ,first_inventory_money                    -- 15.月首棚卸高(金額)
      ,factry_in_money                          -- 16.工場入庫(金額)
      ,kuragae_in_money                         -- 17.倉替入庫(金額)
      ,hurikae_in_money                         -- 18.振替入庫(金額)
      ,payment_total_money                      -- 19.払出合計(金額)
      ,inventory_total_money                    -- 20.棚卸高計(金額)
      ,inferior_goods_money                     -- 21.(不良品棚卸高)(金額)
      ,genmou_money                             -- 22.棚卸減耗(金額)
      ,message                                  -- 23.メッセージ
      ,last_update_date                         -- 24.最終更新日
      ,last_updated_by                          -- 25.最終更新者
      ,creation_date                            -- 26.作成日
      ,created_by                               -- 27.作成者
      ,last_update_login                        -- 28.最終更新ユーザ
      ,request_id                               -- 29.要求ID
      ,program_application_id                   -- 30.プログラムアプリケーションID
      ,program_id                               -- 31.プログラムID
      ,program_update_date                      -- 32.プログラム更新日
    )VALUES(
       in_slit_id                               -- 01
      ,SUBSTRB(gv_param_reception_date, 3, 2)   -- 02
      ,SUBSTRB(gv_param_reception_date, 5, 2)   -- 03
      ,gt_cost_type_name                        -- 04
      ,lv_base_code                             -- 05
      ,lv_base_name                             -- 06
-- == 2015/03/03 V1.5 Added START ===============================================================
      ,iv_inv_cl_char                           --    在庫確定印字文字
-- == 2015/03/03 V1.5 Added END   ===============================================================
      ,ln_first_inventory_qty                   -- 07
      ,ln_factry_in_qty                         -- 08
      ,ln_kuragae_in_qty                        -- 09
      ,ln_hurikae_in_qty                        -- 10
      ,ln_payment_total_qty                     -- 11
      ,ln_inventory_total_qty                   -- 12
      ,ln_inferior_goods_qty                    -- 13
      ,ln_genmou_qty                            -- 14
      ,ln_first_inventory_money                 -- 15
      ,ln_factry_in_money                       -- 16
      ,ln_kuragae_in_money                      -- 17
      ,ln_hurikae_in_money                      -- 18
      ,ln_payment_total_money                   -- 19
      ,ln_inventory_total_money                 -- 20
      ,ln_inferior_goods_money                  -- 21
      ,ln_genmou_money                          -- 22
      ,iv_message                               -- 23
      ,SYSDATE                                  -- 24
      ,cn_last_updated_by                       -- 25
      ,SYSDATE                                  -- 26
      ,cn_created_by                            -- 27
      ,cn_last_update_login                     -- 28
      ,cn_request_id                            -- 29
      ,cn_program_application_id                -- 30
      ,cn_program_id                            -- 31
      ,SYSDATE                                  -- 32
    );
--
  EXCEPTION
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
  END ins_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : valid_param_value
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE valid_param_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'valid_param_value'; -- プログラム名
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
    ld_dummy    DATE;       -- ダミー変数
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
    --  1.受払年月チェック
    -- ===============================
-- == 2015/03/03 V1.5 Modified START ===============================================================
--    BEGIN
--      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_type_month);
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- 受払年月型チェックエラーメッセージ
--        lv_errmsg   := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_short_name_xxcoi
--                        ,iv_name         => cv_msg_xxcoi1_10110
--                       );
--        lv_errbuf   := lv_errmsg;
--        --
--        RAISE global_process_expt;
--    END;
      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_type_month);
-- == 2015/03/03 V1.5 Modified END   ===============================================================
    --
    IF (TO_CHAR(gd_f_process_date, cv_type_month) <= gv_param_reception_date) THEN
      -- 受払年月未来日チェックエラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10111
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
   --
-- == 2015/03/03 V1.5 Added START ===============================================================
    gd_target_date := LAST_DAY(ld_dummy);
-- == 2015/03/03 V1.5 Added END   ===============================================================
  EXCEPTION
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
  END valid_param_value;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- == 2015/03/03 V1.5 Added START ===============================================================
    ov_inv_cl_char    OUT VARCHAR2, --   在庫確定印字文字
-- == 2015/03/03 V1.5 Added END   ===============================================================
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
-- == 2015/03/03 V1.5 Added START ===============================================================
    lv_organization_code  VARCHAR2(4);                                            --在庫組織コード
    ln_organization_id    NUMBER;                                                 --在庫組織ID
    lb_chk_result         BOOLEAN;                                                --在庫会計期間チェック結果
-- == 2015/03/03 V1.5 Added END   ===============================================================
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===============================
    --  初期化
    -- ===============================
    gd_f_process_date   :=  NULL;                 -- 業務日付
    gt_cost_type_name   :=  NULL;                 -- 原価区分名
    --
    -- ===============================
    --  1.業務日付取得
    -- ===============================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF  (gd_f_process_date  IS NULL) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_00011
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  2.WHOカラム設定
    -- ===============================
    -- グローバル定数として、宣言部で設定しています。
    --
    -- ===============================
    --  3.原価区分名取得
    -- ===============================
    gt_cost_type_name   :=  xxcoi_common_pkg.get_meaning(cv_xxcoi_cost_price_div, gv_param_cost_type);
    --
    IF  (gt_cost_type_name  IS NULL) THEN
      -- 原価区分名取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10114
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  4.起動パラメータログ出力
    -- ===============================
    -- 受払年月
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10107
                    ,iv_token_name1  => cv_token_10107_1
                    ,iv_token_value1 => gv_param_reception_date
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 原価区分
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10108
                    ,iv_token_name1  => cv_token_10108_1
                    ,iv_token_value1 => gt_cost_type_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
    );
--
-- == 2015/03/03 V1.5 Added START ===============================================================
    --====================================
    --在庫組織コード取得
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
    --
    IF (lv_organization_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_00005
                    ,iv_token_name1  => cv_token_00005_1
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
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_00006
                    ,iv_token_name1  => cv_token_00006_1
                    ,iv_token_value1 => lv_organization_code
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      gd_target_date  :=  LAST_DAY(TO_DATE(gv_param_reception_date, cv_type_month));
    EXCEPTION
      WHEN OTHERS THEN
        -- 受払年月型チェックエラーメッセージ
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10110
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
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
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_00026
                    ,iv_token_name1  => cv_token_00026_1
                    ,iv_token_value1 => TO_CHAR(gd_target_date, 'YYYY/MM/DD')
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
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10451
                      ,iv_token_name1  => cv_token_10451_1
                      ,iv_token_value1 => cv_inv_cl_char
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
-- == 2015/03/03 V1.5 Added END   ===============================================================
  EXCEPTION
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_reception_date IN  VARCHAR2,     -- 1.受払年月
    iv_cost_type      IN  VARCHAR2,     -- 2.原価区分
    ov_errbuf         OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
-- == 2015/03/03 V1.5 Added START ===============================================================
    lv_inv_cl_char                      VARCHAR2(4);                            --在庫確定印字文字
-- == 2015/03/03 V1.5 Added END   ===============================================================
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
    lv_zero_message     VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --  初期化
    -- ===============================
    -- 入力パラメータ
    gv_param_reception_date   :=  iv_reception_date;    -- 受払年月
    gv_param_cost_type        :=  iv_cost_type;         -- 原価区分
    --
    lv_zero_message   :=  NULL;
    --
    -- ===============================
    --  A-1.初期処理
    -- ===============================
    init(
-- == 2015/03/03 V1.5 Modified START ===============================================================
--       ov_errbuf    =>  lv_errbuf     --   エラー・メッセージ           --# 固定 #
       ov_inv_cl_char =>  lv_inv_cl_char --   在庫確定印字文字
      ,ov_errbuf      =>  lv_errbuf      --   エラー・メッセージ           --# 固定 #
-- == 2015/03/03 V1.5 Modified END   ===============================================================
      ,ov_retcode   =>  lv_retcode    --   リターン・コード             --# 固定 #
      ,ov_errmsg    =>  lv_errmsg     --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-2.パラメータチェック
    -- ===============================
    valid_param_value(
       ov_errbuf    =>  lv_errbuf     --   エラー・メッセージ           --# 固定 #
      ,ov_retcode   =>  lv_retcode    --   リターン・コード             --# 固定 #
      ,ov_errmsg    =>  lv_errmsg     --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-3.データ取得（カーソル）
    -- ===============================
    OPEN  svf_data_cur;
    FETCH svf_data_cur  INTO  svf_data_rec;
    --
    IF (svf_data_cur%NOTFOUND) THEN
      -- 出力対象データ０件
      lv_zero_message := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name_xxcoi
                          ,iv_name         => cv_msg_xxcoi1_00008
                         );
      --
    END IF;
    --
    <<work_ins_loop>>
    LOOP
      -- 対象件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- ===============================
      --  A-4.ワークテーブルデータ登録
      -- ===============================
      ins_svf_data(
         ir_svf_data  =>  svf_data_rec    -- CSV出力用データ
        ,in_slit_id   =>  gn_target_cnt   -- 処理連番
        ,iv_message   =>  lv_zero_message -- ０件メッセージ
-- == 2015/03/03 V1.5 Added START ===============================================================
        ,iv_inv_cl_char => lv_inv_cl_char -- 在庫確定印字文字
-- == 2015/03/03 V1.5 Added END   ===============================================================
        ,ov_errbuf    =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
        ,ov_retcode   =>  lv_retcode      -- リターン・コード             --# 固定 #
        ,ov_errmsg    =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF (lv_retcode = cv_status_error) THEN
        -- エラー処理
        RAISE global_process_expt;
      END IF;
      --
      EXIT  work_ins_loop WHEN  lv_zero_message IS NOT NULL;
      FETCH svf_data_cur  INTO  svf_data_rec;
      EXIT  work_ins_loop WHEN  svf_data_cur%NOTFOUND;
      --
    END LOOP work_ins_loop;
    CLOSE svf_data_cur;
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
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      -- エラー処理
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  A-6.ワークテーブルデータ削除
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
    IF (lv_zero_message IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
    END IF;
    --
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
      --
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
    errbuf            OUT VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_reception_date IN  VARCHAR2,      -- 1.受払年月
    iv_cost_type      IN  VARCHAR2       -- 2.原価区分
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
       iv_reception_date  =>  iv_reception_date   -- 1.受払年月
      ,iv_cost_type       =>  iv_cost_type        -- 2.原価区分
      ,ov_errbuf          =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         =>  lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg          =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
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
    fnd_file.put_line(
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
END XXCOI006A17R;
/
