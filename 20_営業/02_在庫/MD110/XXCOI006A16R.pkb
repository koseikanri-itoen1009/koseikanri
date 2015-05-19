CREATE OR REPLACE PACKAGE BODY XXCOI006A16R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A16R(body)
 * Description      : 受払残高表（拠点別・合計）
 * MD.050           : 受払残高表（拠点別・合計） <MD050_XXCOI_006_A16>
 * Version          : V1.10
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
 *  2008/12/01    1.0   Y.Kobayashi      初版作成
 *  2009/05/13    1.1   T.Nakamura       [障害T1_0960]参照するカテゴリを商品製品区分に変更
 *  2009/06/26    1.2   H.Sasaki         [0000258]払出合計に基準在庫変更入庫を追加
 *  2009/07/13    1.3   N.Abe            [0000282]百貨店計、専門店計の名称出力を修正
 *  2009/07/14    1.4   N.Abe            [0000462]群コード取得方法修正
 *  2009/07/21    1.5   H.Sasaki         [0000642]払出合計の金額算出方法を変更
 *  2009/09/11    1.6   N.Abe            [0001266]OPM品目アドオンの取得方法修正
 *  2009/10/06    1.7   H.Sasaki         [E_T3_00531]商品部のデータ抽出条件変更
 *  2010/02/02    1.8   N.Abe            [E_本稼動_01411]商品部のPT対応
 *  2010/05/06    1.9   N.Abe            [E_本稼動_02562]拠点別のPT対応
 *  2015/03/03    1.10  Y.Koh            障害対応E_本稼動_12827
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
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOI006A16R';           -- パッケージ名
  -- メッセージ関連
  cv_short_name_xxcoi       CONSTANT VARCHAR2(5)  :=  'XXCOI';                    -- アプリケーション短縮名
  cv_msg_xxcoi1_00008       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00008';         -- 対象データ無しメッセージ
  cv_msg_xxcoi1_00011       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00011';         -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10098       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10098';         -- パラメータ出力区分値エラーメッセージ
  cv_msg_xxcoi1_10107       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10107';         -- パラメータ受払年月値メッセージ
  cv_msg_xxcoi1_10108       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10108';         -- パラメータ原価区分値メッセージ
  cv_msg_xxcoi1_10109       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10109';         -- パラメータ拠点値メッセージ
  cv_msg_xxcoi1_10110       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10110';         -- 受払年月型チェックエラーメッセージ
  cv_msg_xxcoi1_10111       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10111';         -- 受払年月未来日チェックエラーメッセージ
  cv_msg_xxcoi1_10113       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10113';         -- 出力区分名取得エラーメッセージ
  cv_msg_xxcoi1_10114       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10114';         -- 原価区分名取得エラーメッセージ
  cv_msg_xxcoi1_10115       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10115';         -- 拠点コードNULLチェックエラーメッセージ
  cv_msg_xxcoi1_10116       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10116';         -- ログインユーザ拠点コード抽出エラーメッセージ
  cv_msg_xxcoi1_10117       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10117';         -- 専門店計拠点コード取得エラーメッセージ
  cv_msg_xxcoi1_10118       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10118';         -- 百貨店計拠点コード取得エラーメッセージ
  cv_msg_xxcoi1_10296       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10296';         -- 百貨店計拠点コード取得エラーメッセージ
  cv_msg_xxcoi1_10119       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10119';         -- SVF起動APIエラーメッセージ
-- == 2009/05/13 V1.1 Modified START ===============================================================
--  cv_msg_xxcoi1_10146       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10146';         -- 品目区分カテゴリセット名取得エラーメッセージ
  cv_msg_xxcoi1_10382       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10382';         -- 商品製品区分カテゴリセット名取得エラーメッセージ
-- == 2009/05/13 V1.1 Modified END   ===============================================================
-- == 2015/03/03 V1.10 Added START ===============================================================
  cv_msg_xxcoi1_00005       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00005';         -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00006';         -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00026       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00026';         -- 在庫会計期間取得エラーメッセージ
  cv_msg_xxcoi1_10451       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10451';         -- 在庫確定印字文字取得エラーメッセージ
-- == 2015/03/03 V1.10 Added END   ===============================================================
  cv_token_10098_1          CONSTANT VARCHAR2(30) :=  'P_OUT_TYPE';               -- APP-XXCOI1-10098用トークン（出力区分）
  cv_token_10107_1          CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';        -- APP-XXCOI1-10107用トークン（受払年月）
  cv_token_10108_1          CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';              -- APP-XXCOI1-10108用トークン（原価区分）
  cv_token_10109_1          CONSTANT VARCHAR2(30) :=  'P_BASE_CODE';              -- APP-XXCOI1-10109用トークン（拠点コード）
  cv_token_10146_1          CONSTANT VARCHAR2(30) :=  'PRO_TOK';                  -- APP-XXCOI1-10146用トークン（プロファイル名）
-- == 2015/03/03 V1.10 Added START ===============================================================
  cv_token_00005_1          CONSTANT VARCHAR2(12) := 'PRO_TOK';                   -- APP-XXCOI1-00005用トークン（トークンプロファイル名）
  cv_token_00006_1          CONSTANT VARCHAR2(12) := 'ORG_CODE_TOK';              -- APP-XXCOI1-00006用トークン（トークン在庫組織コード）
  cv_token_00026_1          CONSTANT VARCHAR2(12) := 'TARGET_DATE';               -- APP-XXCOI1-00026用トークン（トークン対象日）
  cv_token_10451_1          CONSTANT VARCHAR2(12) := 'PRO_TOK';                   -- APP-XXCOI1-10451用トークン（トークンプロファイル名）
-- == 2015/03/03 V1.10 Added END   ===============================================================
  cv_prf_name_sp_manage     CONSTANT VARCHAR2(30) :=  'XXCOI1_SP_MANAGEMENT';         -- プロファイル名（専門店計拠点コード）
  cv_prf_name_dp_manage     CONSTANT VARCHAR2(30) :=  'XXCOI1_DEPT_MANAGEMENT';       -- プロファイル名（百貨店計拠点コード）
  cv_prf_name_item_dept     CONSTANT VARCHAR2(30) :=  'XXCOI1_ITEM_DEPT_BASE_CODE';   -- プロファイル名（商品部拠点コード）
-- == 2009/05/13 V1.1 Modified START ===============================================================
--  cv_prf_name_category      CONSTANT VARCHAR2(30) :=  'XXCOI1_ITEM_CATEGORY_CLASS';   -- プロファイル名（品目区分カテゴリセット名）
  cv_prf_name_category      CONSTANT VARCHAR2(30) :=  'XXCOI1_GOODS_PRODUCT_CLASS';   -- プロファイル名（商品製品区分カテゴリセット名）
-- == 2009/05/13 V1.1 Modified END   ===============================================================
-- == 2015/03/03 V1.10 Added START ===============================================================
  cv_prf_org_code           CONSTANT VARCHAR2(24) :=  'XXCOI1_ORGANIZATION_CODE';     -- プロファイル名（在庫組織コード）
  cv_inv_cl_char            CONSTANT VARCHAR2(24) :=  'XXCOI1_INV_CL_CHARACTER';      -- プロファイル名（在庫確定印字文字）
-- == 2015/03/03 V1.10 Added END   ===============================================================
  -- 出力区分（30:拠点別 40:専門店別 50:百貨店別 60:専門店計 70:百貨店計 80:直営店計 90:全社計）
  cv_output_kbn_30          CONSTANT VARCHAR2(2)  :=  '30';
  cv_output_kbn_40          CONSTANT VARCHAR2(2)  :=  '40';
  cv_output_kbn_50          CONSTANT VARCHAR2(2)  :=  '50';
  cv_output_kbn_60          CONSTANT VARCHAR2(2)  :=  '60';
  cv_output_kbn_70          CONSTANT VARCHAR2(2)  :=  '70';
  cv_output_kbn_80          CONSTANT VARCHAR2(2)  :=  '80';
  cv_output_kbn_90          CONSTANT VARCHAR2(2)  :=  '90';
  -- LOOKUP_TYPE
  cv_xxcoi1_output_div      CONSTANT VARCHAR2(30) :=  'XXCOI1_IN_OUT_LIST_OUTPUT_DIV';  -- LOOKUP_TYPE（出力区分）
  cv_xxcoi_cost_price_div   CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';          -- LOOKUP_TYPE（原価区分）
  -- 保管場所区分（4:専門店）
  cv_subinv_type_4          CONSTANT VARCHAR2(1)  :=  '4';
  -- 棚卸区分（1:月中  2:月末）
  cv_inv_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  -- 顧客区分（1:拠点）
  cv_cust_cls_1             CONSTANT VARCHAR2(1)  :=  '1';
  -- 顧客マスタ．ステータス
  cv_status_a               CONSTANT VARCHAR2(1)  :=  'A';
  -- その他
  cv_type_month             CONSTANT VARCHAR2(6)  :=  'YYYYMM';                -- DATE型 年月（YYYYMM）
  cv_type_date              CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';              -- DATE型 年月日（YYYYMMDD）
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                   -- コンカレントヘッダ出力先
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                     -- 半角スペース
  --カーソル判定区分
  cv_cur_kbn_1              CONSTANT VARCHAR2(1)  :=  '1';
  cv_cur_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  cv_cur_kbn_3              CONSTANT VARCHAR2(1)  :=  '3';
  cv_cur_kbn_4              CONSTANT VARCHAR2(1)  :=  '4';
  -- SVF起動関数パラメータ用
  cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A16R';          -- コンカレント名
  cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                  -- 拡張子（PDF）
  cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A16R';          -- 帳票ID
  cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                     -- 出力区分
  cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A16S.xml';      -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A16S.vrq';      -- クエリー様式ファイル名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_param_output_kbn       VARCHAR2(2);                        -- 出力区分（30:拠点別 40:専門店別 50:百貨店別 60:専門店計 70:百貨店計 80:直営店計 90:全社計）
  gv_param_reception_date   VARCHAR2(6);                        -- 受払年月（YYYYMM）
  gv_param_cost_type        VARCHAR2(2);                        -- 原価区分（10:営業原価、20:標準原価）
  gv_param_base_code        VARCHAR2(4);                        -- 拠点
  -- 初期処理設定値
  gd_f_process_date         DATE;                               -- 業務日付
  gv_user_basecode          VARCHAR2(4);                        -- 所属拠点
  gt_output_kbn_type_name   fnd_lookup_values.meaning%TYPE;     -- 出力区分名
  gt_cost_type_name         fnd_lookup_values.meaning%TYPE;     -- 原価区分名
  gv_item_dept_base_code    VARCHAR2(4);                        -- 商品部拠点コード
-- == 2009/05/13 V1.1 Modified START ===============================================================
--  gv_item_category          VARCHAR2(10);                       -- カテゴリー名
  gv_item_category          VARCHAR2(12);                       -- カテゴリー名
-- == 2009/05/13 V1.1 Modified END   ===============================================================
-- == 2009/07/14 V1.4 Added START ===============================================================
  gd_target_date            DATE;
-- == 2009/07/14 V1.4 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  -- 拠点別、専門店別、百貨店別のいづれか、かつ、拠点が設定されている場合
  CURSOR  svf_data_cur1
  IS
-- == 2010/05/06 V1.9 Modified START ===============================================================
--    SELECT  xirm.base_code                      base_code                 -- 拠点コード
    SELECT  /*+ USE_NL(mic mcb msib iimb xirm xsib) */
            xirm.base_code                      base_code                 -- 拠点コード
-- == 2010/05/06 V1.9 Modified END   ===============================================================
           ,SUBSTRB(sca.account_name, 1, 8)     account_name              -- 拠点名称
           ,mcb.segment1                        item_type                 -- 商品製品区分（カテゴリコード）
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- 群コード
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- 群コード(旧)
                      ELSE iimb.attribute2                                -- 群コード(新)
                    END
              ), 1, 3
            )                                   policy_group              -- 群コード
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- 品目コード
           ,xsib.item_short_name                item_short_name           -- 商品名称（略称）
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
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- 基準在庫変更入庫
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- 工場返品
           ,xirm.factory_return_b               factory_return_b          -- 工場返品振戻
           ,xirm.factory_change                 factory_change            -- 工場倉替
           ,xirm.factory_change_b               factory_change_b          -- 工場倉替振戻
           ,xirm.removed_goods                  removed_goods             -- 廃却
           ,xirm.removed_goods_b                removed_goods_b           -- 廃却振戻
    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
           ,mtl_categories_b                    mcb                       -- カテゴリ
           ,mtl_item_categories                 mic                       -- 品目カテゴリ割当
           ,ic_item_mst_b                       iimb                      -- OPM品目
           ,xxcmn_item_mst_b                    xsib                      -- OPM品目アドオン
           ,mtl_system_items_b                  msib                      -- Disc品目
-- == 2010/05/06 V1.9 Modified START ===============================================================
--           ,(SELECT   CASE  WHEN  xca.customer_id IS NULL THEN  hca1.account_number
           ,(SELECT   /*+ USE_NL(xca hca2) */
                      CASE  WHEN  xca.customer_id IS NULL THEN  hca1.account_number
-- == 2010/05/06 V1.9 Modified END   ===============================================================
                      ELSE  hca2.account_number
                      END   base_code
                     ,CASE  WHEN  xca.customer_id IS NULL THEN  hca1.account_name
                      ELSE  hca2.account_name
                      END   account_name
             FROM     hz_cust_accounts      hca1
                     ,hz_cust_accounts      hca2
                     ,xxcmm_cust_accounts   xca
             WHERE    hca1.account_number           =   gv_param_base_code
             AND      hca1.account_number           =   xca.management_base_code(+)
             AND      xca.customer_id               =   hca2.cust_account_id(+)
             AND      hca1.customer_class_code      =   cv_cust_cls_1
             AND      hca1.status                   =   cv_status_a
             AND      hca2.customer_class_code(+)   =   cv_cust_cls_1
             AND      hca2.status(+)                =   cv_status_a
-- == 2009/10/06 V1.7 Added START ===============================================================
             AND    ((    (gv_param_output_kbn      =   cv_output_kbn_50)
                      AND (dept_hht_div             =   '1')
                     )
                     OR
                     (gv_param_output_kbn           <>  cv_output_kbn_50)
                    )
-- == 2009/10/06 V1.7 Added END   ===============================================================
            )         sca                                                 -- 顧客情報
    WHERE   xirm.base_code          =   sca.base_code
    AND     xirm.practice_month     =   gv_param_reception_date           -- パラメータ.受払年月
    AND     xirm.inventory_item_id  =   msib.inventory_item_id
    AND     xirm.organization_id    =   msib.organization_id
    AND     msib.segment1           =   iimb.item_no
    AND     iimb.item_id            =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id  =   mic.inventory_item_id
    AND     xirm.organization_id    =   mic.organization_id
    AND     mic.category_id         =   mcb.category_id
    AND     mcb.attribute_category  =   gv_item_category
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2                      -- 棚卸区分='2'（月末）
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
  -- 直営店計の場合
  CURSOR  svf_data_cur2
  IS
    SELECT  xirm.base_code                      base_code                 -- 拠点コード
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- 拠点名称
           ,mcb.segment1                        item_type                 -- 商品製品区分（カテゴリコード）
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- 群コード
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- 群コード(旧)
                      ELSE iimb.attribute2                                -- 群コード(新)
                    END
              ), 1, 3
            )                                   policy_group              -- 群コード
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- 品目コード
           ,xsib.item_short_name                item_short_name           -- 商品名称（略称）
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
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- 基準在庫変更入庫
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- 工場返品
           ,xirm.factory_return_b               factory_return_b          -- 工場返品振戻
           ,xirm.factory_change                 factory_change            -- 工場倉替
           ,xirm.factory_change_b               factory_change_b          -- 工場倉替振戻
           ,xirm.removed_goods                  removed_goods             -- 廃却
           ,xirm.removed_goods_b                removed_goods_b           -- 廃却振戻
    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
           ,hz_cust_accounts                    hca                       -- 顧客マスタ
           ,mtl_categories_b                    mcb                       -- カテゴリ
           ,mtl_item_categories                 mic                       -- 品目カテゴリ割当
           ,ic_item_mst_b                       iimb                      -- OPM品目
           ,xxcmn_item_mst_b                    xsib                      -- OPM品目アドオン
           ,mtl_system_items_b                  msib                      -- Disc品目
    WHERE   xirm.subinventory_type  =   cv_subinv_type_4                  -- 保管場所マスタ.保管場所区分='4'（専門店）
    AND     xirm.practice_month     =   gv_param_reception_date           -- パラメータ.受払年月
    AND     xirm.inventory_item_id  =   msib.inventory_item_id
    AND     xirm.organization_id    =   msib.organization_id
    AND     msib.segment1           =   iimb.item_no
    AND     iimb.item_id            =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id  =   mic.inventory_item_id
    AND     xirm.organization_id    =   mic.organization_id
    AND     mic.category_id         =   mcb.category_id
    AND     mcb.attribute_category  =   gv_item_category
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2                      -- 棚卸区分='2'（月末）
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1                     -- 顧客区分='1'（拠点）
    AND     hca.status              =   cv_status_a                       -- ステータス='A'
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
  -- 専門店計、百貨店計、又は、
  -- 拠点別（商品部以外）、専門店別、百貨店別のいづれか、かつ、拠点が設定されていない場合
  CURSOR  svf_data_cur3
  IS
    SELECT  xirm.base_code                      base_code                 -- 拠点コード
           ,SUBSTRB(sca.account_name, 1, 8)     account_name              -- 拠点名称
           ,mcb.segment1                        item_type                 -- 商品製品区分（カテゴリコード）
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- 群コード
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- 群コード(旧)
                      ELSE iimb.attribute2                                -- 群コード(新)
                    END
              ), 1, 3
            )                                   policy_group              -- 群コード
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- 品目コード
           ,xsib.item_short_name                item_short_name           -- 商品名称（略称）
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
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- 基準在庫変更入庫
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- 工場返品
           ,xirm.factory_return_b               factory_return_b          -- 工場返品振戻
           ,xirm.factory_change                 factory_change            -- 工場倉替
           ,xirm.factory_change_b               factory_change_b          -- 工場倉替振戻
           ,xirm.removed_goods                  removed_goods             -- 廃却
           ,xirm.removed_goods_b                removed_goods_b           -- 廃却振戻
    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
           ,mtl_categories_b                    mcb                       -- カテゴリ
           ,mtl_item_categories                 mic                       -- 品目カテゴリ割当
           ,ic_item_mst_b                       iimb                      -- OPM品目
           ,xxcmn_item_mst_b                    xsib                      -- OPM品目アドオン
           ,mtl_system_items_b                  msib                      -- Disc品目
           ,(SELECT   hca2.account_number   base_code
                     ,hca2.account_name     account_name
             FROM     hz_cust_accounts      hca1
                     ,hz_cust_accounts      hca2
                     ,xxcmm_cust_accounts   xca
             WHERE    hca1.account_number       =   CASE  WHEN  gv_param_output_kbn IN(cv_output_kbn_60, cv_output_kbn_70)
                                                          THEN  gv_param_base_code
                                                          ELSE  gv_user_basecode
                                                    END
             AND      hca1.account_number       =   xca.management_base_code
             AND      xca.customer_id           =   hca2.cust_account_id
             AND      hca1.customer_class_code  =   cv_cust_cls_1
             AND      hca1.status               =   cv_status_a
             AND      hca2.customer_class_code  =   cv_cust_cls_1
             AND      hca2.status               =   cv_status_a
-- == 2009/10/06 V1.7 Added START ===============================================================
             AND    ((    (gv_param_output_kbn  IN(cv_output_kbn_50, cv_output_kbn_70))
                      AND (dept_hht_div             =   '1')
                     )
                     OR
                     (gv_param_output_kbn       NOT IN(cv_output_kbn_50, cv_output_kbn_70))
                    )
-- == 2009/10/06 V1.7 Added END   ===============================================================
            )         sca                                                 -- 顧客情報
    WHERE   xirm.practice_month       =   gv_param_reception_date         -- パラメータ.受払年月
    AND     xirm.inventory_item_id    =   msib.inventory_item_id
    AND     xirm.organization_id      =   msib.organization_id
    AND     msib.segment1             =   iimb.item_no
    AND     iimb.item_id              =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id    =   mic.inventory_item_id
    AND     xirm.organization_id      =   mic.organization_id
    AND     mic.category_id           =   mcb.category_id
    AND     mcb.attribute_category    =   gv_item_category
    AND     xirm.base_code            =   sca.base_code
    AND     xirm.inventory_kbn        =   cv_inv_kbn_2                    -- 棚卸区分='2'（月末）
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
  -- 全社計、又は
  -- 拠点別（商品部）、かつ、拠点が設定されていない場合
  CURSOR  svf_data_cur4
  IS
-- == 2010/02/02 V1.8 Modified START ===============================================================
--    SELECT  xirm.base_code                      base_code                 -- 拠点コード
    SELECT  /*+ use_nl(xirm mcb mic iimb xsib msib)
                index(xirm xxcoi_inv_reception_month_n02) */
            xirm.base_code                      base_code                 -- 拠点コード
-- == 2010/02/02 V1.8 Modified END   ===============================================================
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- 拠点名称
           ,mcb.segment1                        item_type                 -- 商品製品区分（カテゴリコード）
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- 群コード
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- 群コード(旧)
                      ELSE iimb.attribute2                                -- 群コード(新)
                    END
              ), 1, 3
            )                                   policy_group              -- 群コード
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- 品目コード
           ,xsib.item_short_name                item_short_name           -- 商品名称（略称）
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
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- 基準在庫変更入庫
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- 工場返品
           ,xirm.factory_return_b               factory_return_b          -- 工場返品振戻
           ,xirm.factory_change                 factory_change            -- 工場倉替
           ,xirm.factory_change_b               factory_change_b          -- 工場倉替振戻
           ,xirm.removed_goods                  removed_goods             -- 廃却
           ,xirm.removed_goods_b                removed_goods_b           -- 廃却振戻
    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
           ,hz_cust_accounts                    hca                       -- 顧客マスタ
           ,mtl_categories_b                    mcb                       -- カテゴリ
           ,mtl_item_categories                 mic                       -- 品目カテゴリ割当
           ,ic_item_mst_b                       iimb                      -- OPM品目
           ,xxcmn_item_mst_b                    xsib                      -- OPM品目アドオン
           ,mtl_system_items_b                  msib                      -- Disc品目
    WHERE   xirm.practice_month     =   gv_param_reception_date           -- パラメータ.受払年月
    AND     xirm.inventory_item_id  =   msib.inventory_item_id
    AND     xirm.organization_id    =   msib.organization_id
    AND     msib.segment1           =   iimb.item_no
    AND     iimb.item_id            =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id  =   mic.inventory_item_id
    AND     xirm.organization_id    =   mic.organization_id
    AND     mic.category_id         =   mcb.category_id
    AND     mcb.attribute_category  =   gv_item_category
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2                      -- 棚卸区分='2'（月末）
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1                     -- 顧客区分='1'（拠点）
    AND     hca.status              =   cv_status_a                       -- ステータス='A'
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
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
    DELETE  FROM xxcoi_rep_base_detail_rcpt
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
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_type_date) || TO_CHAR(cn_request_id) || cv_type_pdf     -- 出力ファイル名
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
    ir_svf_data   IN  svf_data_cur1%ROWTYPE,   -- 1.CSV出力対象データ
    in_slit_id    IN  NUMBER,                 -- 2.処理連番
    iv_message    IN  VARCHAR2,               -- 3.０件メッセージ
-- == 2015/03/03 V1.10 Added START ===============================================================
    iv_inv_cl_char IN  VARCHAR2,              -- 4.在庫確定印字文字
-- == 2015/03/03 V1.10 Added END   ===============================================================
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
    lv_base_code              VARCHAR2(4);                                -- 拠点コード
    lv_base_name              VARCHAR2(8);                                -- 拠点名称
    lt_item_type              mtl_categories_b.segment1%TYPE;             -- 商品区分
    lt_policy_group           ic_item_mst_b.attribute2%TYPE;              -- 群コード
    lt_item_code              mtl_system_items_b.segment1%TYPE;           -- 商品コード
    lt_item_short_name        xxcmn_item_mst_b.item_short_name%TYPE;      -- 商品名称
    ln_first_inventory_qty    NUMBER;                                     -- 月首棚卸高(数量)
    ln_factry_in_qty          NUMBER;                                     -- 工場入庫(数量)
    ln_kuragae_in_qty         NUMBER;                                     -- 倉替入庫(数量)
    ln_hurikae_in_qty         NUMBER;                                     -- 振替入庫(数量)
    ln_payment_total_qty      NUMBER;                                     -- 払出合計(数量)
    ln_inventory_total_qty    NUMBER;                                     -- 棚卸高計(数量)
    ln_inferior_goods_qty     NUMBER;                                     -- 不良品棚卸高(数量)
    ln_genmou_qty             NUMBER;                                     -- 棚卸減耗(数量)
    ln_first_inventory_money  NUMBER;                                     -- 月首棚卸高(金額)
    ln_factry_in_money        NUMBER;                                     -- 工場入庫(金額)
    ln_kuragae_in_money       NUMBER;                                     -- 倉替入庫(金額)
    ln_hurikae_in_money       NUMBER;                                     -- 振替入庫(金額)
    ln_payment_total_money    NUMBER;                                     -- 払出合計(金額)
    ln_inventory_total_money  NUMBER;                                     -- 棚卸高計(金額)
    ln_inferior_goods_money   NUMBER;                                     -- (不良品棚卸高)(金額)
    ln_genmou_money           NUMBER;                                     -- 棚卸減耗(金額)
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
    -- 05.拠点コード
    IF (gv_param_output_kbn IN(cv_output_kbn_60, cv_output_kbn_70)) THEN
      -- 専門店計、百貨店計の場合
      lv_base_code  :=  SUBSTRB(gv_param_base_code, 1, 4);
    ELSIF (gv_param_output_kbn IN(cv_output_kbn_80, cv_output_kbn_90)) THEN
      -- 直営店計、全社計
      lv_base_code  :=  NULL;
    ELSE
      lv_base_code  :=  SUBSTRB(ir_svf_data.base_code, 1, 4);
    END IF;
    --
    -- 06.拠点名称
-- == 2009/07/13 V1.3 Modified START ===============================================================
--    IF (gv_param_output_kbn IN(cv_output_kbn_80, cv_output_kbn_90)) THEN
    IF (gv_param_output_kbn IN(cv_output_kbn_60, cv_output_kbn_70, cv_output_kbn_80, cv_output_kbn_90)) THEN
-- == 2009/07/13 V1.3 Modified END   ===============================================================
      -- 直営店計、全社計、百貨店計、専門店計
      lv_base_name  :=  SUBSTRB(gt_output_kbn_type_name, 1, 8);
    ELSE
      lv_base_name  :=  SUBSTRB(ir_svf_data.account_name, 1, 8);
    END IF;
    --
    IF (iv_message IS NOT NULL) THEN
      -- 対象件数０件の場合
      lt_item_type              :=  NULL;     -- 08.商品区分
      lt_policy_group           :=  NULL;     -- 09.群コード
      lt_item_code              :=  NULL;     -- 10.商品コード
      lt_item_short_name        :=  NULL;     -- 11.商品名称
      ln_first_inventory_qty    :=  NULL;     -- 12.月首棚卸高(数量)
      ln_factry_in_qty          :=  NULL;     -- 13.工場入庫(数量)
      ln_kuragae_in_qty         :=  NULL;     -- 14.倉替入庫(数量)
      ln_hurikae_in_qty         :=  NULL;     -- 15.振替入庫(数量)
      ln_payment_total_qty      :=  NULL;     -- 16.払出合計(数量)
      ln_inventory_total_qty    :=  NULL;     -- 17.棚卸高計(数量)
      ln_inferior_goods_qty     :=  NULL;     -- 18.不良品棚卸高(数量)
      ln_genmou_qty             :=  NULL;     -- 19.棚卸減耗(数量)
      ln_first_inventory_money  :=  NULL;     -- 20.月首棚卸高(金額)
      ln_factry_in_money        :=  NULL;     -- 21.工場入庫(金額)
      ln_kuragae_in_money       :=  NULL;     -- 22.倉替入庫(金額)
      ln_hurikae_in_money       :=  NULL;     -- 23.振替入庫(金額)
      ln_payment_total_money    :=  NULL;     -- 24.払出合計(金額)
      ln_inventory_total_money  :=  NULL;     -- 25.棚卸高計(金額)
      ln_inferior_goods_money   :=  NULL;     -- 26.(不良品棚卸高)(金額)
      ln_genmou_money           :=  NULL;     -- 27.棚卸減耗(金額)
      --
    ELSE
      lt_item_type              :=   SUBSTRB(ir_svf_data.item_type, 1, 1);            -- 08.商品区分
      lt_policy_group           :=   ir_svf_data.policy_group;                        -- 09.群コード
      lt_item_code              :=   SUBSTRB(ir_svf_data.item_code, 1, 7);            -- 10.商品コード
      lt_item_short_name        :=   SUBSTRB(ir_svf_data.item_short_name, 1, 20);     -- 11.商品名称
      ln_first_inventory_qty    :=   ir_svf_data.month_begin_quantity;  -- 12.月首棚卸高(数量)
      ln_factry_in_qty          :=   ir_svf_data.factory_stock
                                   - ir_svf_data.factory_stock_b;       -- 13.工場入庫(数量)
      ln_kuragae_in_qty         :=   ir_svf_data.change_stock;          -- 14.倉替入庫(数量)
      ln_hurikae_in_qty         :=   ir_svf_data.goods_transfer_new;    -- 15.振替入庫(数量)
      ln_payment_total_qty      :=   ir_svf_data.sales_shipped
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
-- == 2009/06/26 V1.2 Added START ===============================================================
                                   - ir_svf_data.inventory_change_in
-- == 2009/06/26 V1.2 Added END   ===============================================================
                                   + ir_svf_data.factory_return
                                   - ir_svf_data.factory_return_b
                                   + ir_svf_data.factory_change
                                   - ir_svf_data.factory_change_b
                                   + ir_svf_data.removed_goods
                                   - ir_svf_data.removed_goods_b;       -- 16.払出合計(数量)
      ln_inventory_total_qty    :=   ir_svf_data.inv_result
                                   + ir_svf_data.inv_result_bad;        -- 17.棚卸高計(数量)
      ln_inferior_goods_qty     :=   ir_svf_data.inv_result_bad;        -- 18.(不良品棚卸高)(数量)
      ln_genmou_qty             :=   ir_svf_data.inv_wear;              -- 19.棚卸減耗(数量)
      ln_first_inventory_money  :=   ROUND(ln_first_inventory_qty  * ir_svf_data.cost_amt);                -- 20.月首棚卸高(金額)
      ln_factry_in_money        :=   ROUND(ln_factry_in_qty        * ir_svf_data.cost_amt);                -- 21.工場入庫(金額)
      ln_kuragae_in_money       :=   ROUND(ln_kuragae_in_qty       * ir_svf_data.cost_amt);                -- 22.倉替入庫(金額)
      ln_hurikae_in_money       :=   ROUND(ln_hurikae_in_qty       * ir_svf_data.cost_amt);                -- 23.振替入庫(金額)
-- == 2009/07/21 V1.5 Modified START ===============================================================
--      ln_payment_total_money    :=   ROUND(ln_payment_total_qty    * ir_svf_data.cost_amt);
      ln_payment_total_money    :=   ROUND((  ir_svf_data.sales_shipped
                                            - ir_svf_data.sales_shipped_b
                                            - ir_svf_data.return_goods
                                            + ir_svf_data.return_goods_b
                                           )                       * ir_svf_data.cost_amt)
                                   + ROUND((  ir_svf_data.customer_support_ss
                                            - ir_svf_data.customer_support_ss_b
                                            + ir_svf_data.ccm_sample_ship
                                            - ir_svf_data.ccm_sample_ship_b
                                           )                       * ir_svf_data.cost_amt)
                                   + ROUND((  ir_svf_data.sample_quantity
                                            - ir_svf_data.sample_quantity_b
                                            + ir_svf_data.customer_sample_ship
                                            - ir_svf_data.customer_sample_ship_b
                                           )                       * ir_svf_data.cost_amt)
                                   + ROUND((  ir_svf_data.inventory_change_out
                                            - ir_svf_data.inventory_change_in
                                           )                       * ir_svf_data.cost_amt)
                                   + ROUND((  ir_svf_data.removed_goods
                                            - ir_svf_data.removed_goods_b
                                           )                       * ir_svf_data.cost_amt)
                                   + ROUND(ir_svf_data.change_ship * ir_svf_data.cost_amt)
                                   + ROUND(ir_svf_data.goods_transfer_old
                                                                   * ir_svf_data.cost_amt)
                                   + ROUND((  ir_svf_data.factory_change
                                            - ir_svf_data.factory_change_b
                                           )                       * ir_svf_data.cost_amt)
                                   + ROUND((  ir_svf_data.factory_return
                                            - ir_svf_data.factory_return_b
                                           )                       * ir_svf_data.cost_amt);                -- 24.払出合計(金額)
-- == 2009/07/21 V1.5 Modified END   ===============================================================
      ln_inventory_total_money  :=   ROUND(ln_inventory_total_qty  * ir_svf_data.cost_amt);                -- 25.棚卸高計(金額)
      ln_inferior_goods_money   :=   ROUND(ln_inferior_goods_qty   * ir_svf_data.cost_amt);                -- 26.(不良品棚卸高)(金額)
      ln_genmou_money           :=   ROUND(ln_genmou_qty           * ir_svf_data.cost_amt);                -- 27.棚卸減耗(金額)
    END IF;
    --
    -- 挿入処理
    INSERT INTO xxcoi_rep_base_detail_rcpt(
       slit_id                                  -- 01.受払残高情報ID
      ,output_kbn                               -- 02.出力区分
      ,in_out_year                              -- 03.年
      ,in_out_month                             -- 04.月
      ,base_code                                -- 05.拠点コード
      ,base_name                                -- 06.拠点名称
-- == 2015/03/03 V1.10 Added START ===============================================================
      ,inv_cl_char                              --    在庫確定印字文字
-- == 2015/03/03 V1.10 Added END   ===============================================================
      ,cost_kbn                                 -- 07.原価区分
      ,item_kbn                                 -- 08.商品区分
      ,gun_code                                 -- 09.群コード
      ,item_code                                -- 10.商品コード
      ,item_name                                -- 11.商品名称
      ,first_inventory_qty                      -- 12.月首棚卸高(数量)
      ,factry_in_qty                            -- 13.工場入庫(数量)
      ,kuragae_in_qty                           -- 14.倉替入庫(数量)
      ,hurikae_in_qty                           -- 15.振替入庫(数量)
      ,payment_total_qty                        -- 16.払出合計(数量)
      ,inventory_total_qty                      -- 17.棚卸高計(数量)
      ,inferior_goods_qty                       -- 18.(不良品棚卸高)(数量)
      ,genmou_qty                               -- 19.棚卸減耗(数量)
      ,first_inventory_money                    -- 20.月首棚卸高(金額)
      ,factry_in_money                          -- 21.工場入庫(金額)
      ,kuragae_in_money                         -- 22.倉替入庫(金額)
      ,hurikae_in_money                         -- 23.振替入庫(金額)
      ,payment_total_money                      -- 24.払出合計(金額)
      ,inventory_total_money                    -- 25.棚卸高計(金額)
      ,inferior_goods_money                     -- 26.(不良品棚卸高)(金額)
      ,genmou_money                             -- 27.棚卸減耗(金額)
      ,message                                  -- 28.メッセージ
      ,last_update_date                         -- 29.最終更新日
      ,last_updated_by                          -- 30.最終更新者
      ,creation_date                            -- 31.作成日
      ,created_by                               -- 32.作成者
      ,last_update_login                        -- 33.最終更新ユーザ
      ,request_id                               -- 34.要求ID
      ,program_application_id                   -- 35.プログラムアプリケーションID
      ,program_id                               -- 36.プログラムID
      ,program_update_date                      -- 37.プログラム更新日
    )VALUES(
       in_slit_id                               -- 01
      ,SUBSTRB(gt_output_kbn_type_name, 1, 8)   -- 02
      ,SUBSTRB(gv_param_reception_date, 3, 2)   -- 03
      ,SUBSTRB(gv_param_reception_date, 5, 2)   -- 04
      ,lv_base_code                             -- 05
      ,lv_base_name                             -- 06
-- == 2015/03/03 V1.10 Added START ===============================================================
      ,iv_inv_cl_char                           --    在庫確定印字文字
-- == 2015/03/03 V1.10 Added END   ===============================================================
      ,SUBSTRB(gt_cost_type_name, 1, 8)         -- 07
      ,lt_item_type                             -- 08
      ,lt_policy_group                          -- 09
      ,lt_item_code                             -- 10
      ,lt_item_short_name                       -- 11
      ,ln_first_inventory_qty                   -- 12
      ,ln_factry_in_qty                         -- 13
      ,ln_kuragae_in_qty                        -- 14
      ,ln_hurikae_in_qty                        -- 15
      ,ln_payment_total_qty                     -- 16
      ,ln_inventory_total_qty                   -- 17
      ,ln_inferior_goods_qty                    -- 18
      ,ln_genmou_qty                            -- 19
      ,ln_first_inventory_money                 -- 20
      ,ln_factry_in_money                       -- 21
      ,ln_kuragae_in_money                      -- 22
      ,ln_hurikae_in_money                      -- 23
      ,ln_payment_total_money                   -- 24
      ,ln_inventory_total_money                 -- 25
      ,ln_inferior_goods_money                  -- 26
      ,ln_genmou_money                          -- 27
      ,iv_message                               -- 28
      ,SYSDATE                                  -- 29
      ,cn_last_updated_by                       -- 30
      ,SYSDATE                                  -- 31
      ,cn_created_by                            -- 32
      ,cn_last_update_login                     -- 33
      ,cn_request_id                            -- 34
      ,cn_program_application_id                -- 35
      ,cn_program_id                            -- 36
      ,SYSDATE                                  -- 37
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
    ld_dummy    DATE;           -- ダミー変数
    ln_dummy    NUMBER;         -- ダミー変数
    ln_cnt      NUMBER;         -- LOOPカウンタ
--
    -- *** ローカル・カーソル ***
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
-- == 2015/03/03 V1.10 Modified START ===============================================================
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
-- == 2015/03/03 V1.10 Modified END   ===============================================================
    --
    IF (TO_CHAR(gd_f_process_date, cv_type_month) <= gv_param_reception_date) THEN
      -- 受払年月が業務日付以降の場合
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
-- == 2009/07/14 V1.4 Added START ===============================================================
    gd_target_date := LAST_DAY(ld_dummy);
-- == 2009/07/14 V1.4 Added START ===============================================================
    -- ============================
    --  2.パラメータ.拠点チェック
    -- ============================
    IF  (gv_user_basecode  <>  gv_item_dept_base_code) THEN
      -- ユーザの所属拠点が商品部以外の場合
      BEGIN
        SELECT  1
        INTO    ln_dummy
        FROM    hz_cust_accounts      hca                               -- 顧客マスタ
               ,xxcmm_cust_accounts   xca                               -- 顧客追加情報
        WHERE   hca.account_number        =   xca.management_base_code
        AND     hca.customer_class_code   =   cv_cust_cls_1
        AND     hca.status                =   cv_status_a
        AND     hca.account_number        =   gv_user_basecode          -- ユーザ所属拠点
        AND     ROWNUM  = 1;
        --
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- 管理課以外の場合
          IF (gv_param_base_code IS NULL) THEN
            -- パラメータ.拠点NULLチェックエラーメッセージ
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_10115
                           );
            lv_errbuf   := lv_errmsg;
            --
            RAISE global_process_expt;
          END IF;
      END;
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
  END valid_param_value;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- == 2015/03/03 V1.10 Added START ===============================================================
    ov_inv_cl_char OUT VARCHAR2,    --   在庫確定印字文字
-- == 2015/03/03 V1.10 Added END   ===============================================================
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
-- == 2015/03/03 V1.10 Added START ===============================================================
    lv_organization_code  VARCHAR2(4);                                            --在庫組織コード
    ln_organization_id    NUMBER;                                                 --在庫組織ID
    lb_chk_result         BOOLEAN;                                                --在庫会計期間チェック結果
-- == 2015/03/03 V1.10 Added END   ===============================================================
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
    gd_f_process_date          :=  NULL;                 -- 業務日付
    gt_output_kbn_type_name    :=  NULL;                 -- 出力区分名
    gt_cost_type_name          :=  NULL;                 -- 原価区分名
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
    --  3.専門店計拠点コード取得
    -- ===============================
    IF (gv_param_output_kbn = cv_output_kbn_60) THEN
      -- 出力区分が専門店計の場合
      gv_param_base_code  :=  fnd_profile.value(cv_prf_name_sp_manage);
      --
      IF (gv_param_base_code IS NULL) THEN
        -- 専門店計拠点コード取得エラーメッセージ
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10117
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- ===============================
    --  4.百貨店計拠点コード取得
    -- ===============================
    IF (gv_param_output_kbn = cv_output_kbn_70) THEN
      -- 出力区分が百貨店計の場合
      gv_param_base_code  :=  fnd_profile.value(cv_prf_name_dp_manage);
      --
      IF (gv_param_base_code IS NULL) THEN
        -- 百貨店計拠点コード取得エラーメッセージ
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10118
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- ===============================
    --  5.商品部拠点コード取得
    -- ===============================
    -- 出力区分が拠点別の場合
    gv_item_dept_base_code  :=  fnd_profile.value(cv_prf_name_item_dept);
    --
    IF (gv_item_dept_base_code IS NULL) THEN
      -- 商品部拠点コード取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10296
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  6.パラメータ名称取得
    -- ===============================
    --出力区分名称取得
     gt_output_kbn_type_name   :=  xxcoi_common_pkg.get_meaning(cv_xxcoi1_output_div, gv_param_output_kbn);
    --
    IF  (gt_output_kbn_type_name  IS NULL) THEN
      -- 区分名取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10113
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    --原価区分名称取得
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
    -- ================================
    --  7.ログインユーザ拠点コード取得
    -- ================================
-- == 2015/03/03 V1.10 Modified START ===============================================================
--    gv_user_basecode := xxcoi_common_pkg.get_base_code(cn_created_by, LAST_DAY(TO_DATE(gv_param_reception_date, cv_type_month)));
    BEGIN
      gv_user_basecode := xxcoi_common_pkg.get_base_code(cn_created_by, LAST_DAY(TO_DATE(gv_param_reception_date, cv_type_month)));
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
-- == 2015/03/03 V1.10 Modified END   ===============================================================
    IF (gv_user_basecode IS NULL) THEN
      -- ユーザーの所属拠点データが取得できませんでした。
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name_xxcoi
                       ,iv_name         => cv_msg_xxcoi1_10116
                      );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  8.起動パラメータログ出力
    -- ===============================
    --出力区分
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10098
                    ,iv_token_name1  => cv_token_10098_1
                    ,iv_token_value1 => gt_output_kbn_type_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
     --拠点
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10109
                    ,iv_token_name1  => cv_token_10109_1
                    ,iv_token_value1 => gv_param_base_code
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
    -- ===============================
    --  9.品目カテゴリ名取得
    -- ===============================
      gv_item_category  :=  fnd_profile.value(cv_prf_name_category);
      --
      IF (gv_item_category IS NULL) THEN
        -- 商品製品区分カテゴリセット名取得エラーメッセージ
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
-- == 2009/05/13 V1.1 Modified START ===============================================================
--                        ,iv_name         => cv_msg_xxcoi1_10146
                        ,iv_name         => cv_msg_xxcoi1_10382
-- == 2009/05/13 V1.1 Modified END   ===============================================================
                        ,iv_token_name1  => cv_token_10146_1
                        ,iv_token_value1 => cv_prf_name_category
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
      END IF;
 --
-- == 2015/03/03 V1.10 Added START ===============================================================
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
    gd_target_date  :=  LAST_DAY(TO_DATE(gv_param_reception_date, cv_type_month));
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
-- == 2015/03/03 V1.10 Added END   ===============================================================
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
    iv_output_kbn       IN  VARCHAR2,     -- 1.出力区分
    iv_reception_date   IN  VARCHAR2,     -- 2.受払年月
    iv_cost_type        IN  VARCHAR2,     -- 3.原価区分
    iv_base_code        IN  VARCHAR2,     -- 4.拠点コード
    ov_errbuf           OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
-- == 2015/03/03 V1.10 Added START ===============================================================
    lv_inv_cl_char                      VARCHAR2(4);                            --在庫確定印字文字
-- == 2015/03/03 V1.10 Added END   ===============================================================
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
    -- カーソル判定区分用
    lv_cur_kbn          VARCHAR2(1);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
    svf_data_rec    svf_data_cur1%ROWTYPE;
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
    gv_param_output_kbn       :=  iv_output_kbn;        -- 出力区分
    gv_param_reception_date   :=  iv_reception_date;    -- 受払年月
    gv_param_cost_type        :=  iv_cost_type;         -- 原価区分
    gv_param_base_code        :=  iv_base_code;         -- 拠点
    --
    lv_zero_message   :=  NULL;
    --
    -- ===============================
    --  A-1.初期処理
    -- ===============================
    init(
-- == 2015/03/03 V1.10 Modified START ===============================================================
--       ov_errbuf    =>  lv_errbuf     --   エラー・メッセージ           --# 固定 #
       ov_inv_cl_char =>  lv_inv_cl_char --   在庫確定印字文字
      ,ov_errbuf      =>  lv_errbuf      --   エラー・メッセージ           --# 固定 #
-- == 2015/03/03 V1.10 Modified END   ===============================================================
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
    -- カーソル判定
    IF (    (gv_param_output_kbn IN(cv_output_kbn_30, cv_output_kbn_40, cv_output_kbn_50))
        AND (gv_param_base_code  IS NOT NULL)
       )
    THEN
      -- 拠点別、専門店別、百貨店別のいづれか、かつ、拠点が設定されている場合
      lv_cur_kbn  :=  cv_cur_kbn_1;
      --
    ELSIF (gv_param_output_kbn  = cv_output_kbn_80) THEN
      -- 直営店計の場合
      lv_cur_kbn  :=  cv_cur_kbn_2;
      --
    ELSIF (   (gv_param_output_kbn  IN(cv_output_kbn_60, cv_output_kbn_70))
           OR (    (   (gv_param_output_kbn IN(cv_output_kbn_40, cv_output_kbn_50))
                    OR (     gv_param_output_kbn = cv_output_kbn_30
                        AND  gv_user_basecode <> gv_item_dept_base_code
                       )
                   )
               AND (gv_param_base_code  IS NULL)
              )
          )
    THEN
      -- 専門店計、百貨店計、又は、
      -- 拠点別（商品部以外）、専門店別、百貨店別のいづれか、かつ、拠点が設定されていない場合
      lv_cur_kbn  :=  cv_cur_kbn_3;
      --
    ELSIF (   (gv_param_output_kbn  = cv_output_kbn_90)
           OR (     gv_param_output_kbn = cv_output_kbn_30
               AND  gv_user_basecode = gv_item_dept_base_code
               AND  gv_param_base_code IS NULL
              )
          )
    THEN
      -- 全社計、又は
      -- 拠点別（商品部）、かつ、拠点が設定されていない場合
      lv_cur_kbn  :=  cv_cur_kbn_4;
      --
    END IF;
    --
    IF (lv_cur_kbn  = cv_cur_kbn_1) THEN      -- データ取得パターン１
      OPEN  svf_data_cur1;
      FETCH svf_data_cur1  INTO  svf_data_rec;
      -- 出力対象データ０件
      IF (svf_data_cur1%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    ELSIF (lv_cur_kbn  = cv_cur_kbn_2) THEN      -- データ取得パターン２
      OPEN  svf_data_cur2;
      FETCH svf_data_cur2  INTO  svf_data_rec;
      -- 出力対象データ０件
      IF (svf_data_cur2%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    ELSIF (lv_cur_kbn  = cv_cur_kbn_3) THEN      -- データ取得パターン３
      OPEN  svf_data_cur3;
      FETCH svf_data_cur3  INTO  svf_data_rec;
      -- 出力対象データ０件
      IF (svf_data_cur3%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    ELSIF (lv_cur_kbn  = cv_cur_kbn_4) THEN      -- データ取得パターン４
      OPEN  svf_data_cur4;
      FETCH svf_data_cur4  INTO  svf_data_rec;
      -- 出力対象データ０件
      IF (svf_data_cur4%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
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
-- == 2015/03/03 V1.10 Added START ===============================================================
        ,iv_inv_cl_char =>  lv_inv_cl_char -- 在庫確定印字文字
-- == 2015/03/03 V1.10 Added END   ===============================================================
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
      -- 対象データ０件の場合、ワークテーブル作成処理終了
      EXIT  work_ins_loop WHEN  lv_zero_message IS NOT NULL;
      --
      -- 対象データ取得
      IF (lv_cur_kbn  =  cv_cur_kbn_1)  THEN
        FETCH svf_data_cur1  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur1%NOTFOUND;
        --
      ELSIF (lv_cur_kbn  =  cv_cur_kbn_2)  THEN
        FETCH svf_data_cur2  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur2%NOTFOUND;
        --
      ELSIF (lv_cur_kbn  =  cv_cur_kbn_3)  THEN
        FETCH svf_data_cur3  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur3%NOTFOUND;
        --
      ELSIF (lv_cur_kbn  =  cv_cur_kbn_4)  THEN
        FETCH svf_data_cur4  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur4%NOTFOUND;
        --
      END IF;
      --
    END LOOP work_ins_loop;
    --
    -- カーソルクローズ
    IF (lv_cur_kbn  =  cv_cur_kbn_1)  THEN
      CLOSE svf_data_cur1;
      --
    ELSIF (lv_cur_kbn  =  cv_cur_kbn_2)  THEN
      CLOSE svf_data_cur2;
      --
    ELSIF (lv_cur_kbn  =  cv_cur_kbn_3)  THEN
      CLOSE svf_data_cur3;
      --
    ELSIF (lv_cur_kbn  =  cv_cur_kbn_4)  THEN
      CLOSE svf_data_cur4;
      --
    END IF;
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
      IF (svf_data_cur1%ISOPEN) THEN
         CLOSE svf_data_cur1;
      ELSIF (svf_data_cur2%ISOPEN) THEN
         CLOSE svf_data_cur2;
      ELSIF (svf_data_cur3%ISOPEN) THEN
         CLOSE svf_data_cur3;
      ELSIF (svf_data_cur4%ISOPEN) THEN
         CLOSE svf_data_cur4;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur1%ISOPEN) THEN
         CLOSE svf_data_cur1;
      ELSIF (svf_data_cur2%ISOPEN) THEN
         CLOSE svf_data_cur2;
      ELSIF (svf_data_cur3%ISOPEN) THEN
         CLOSE svf_data_cur3;
      ELSIF (svf_data_cur4%ISOPEN) THEN
         CLOSE svf_data_cur4;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur1%ISOPEN) THEN
         CLOSE svf_data_cur1;
      ELSIF (svf_data_cur2%ISOPEN) THEN
         CLOSE svf_data_cur2;
      ELSIF (svf_data_cur3%ISOPEN) THEN
         CLOSE svf_data_cur3;
      ELSIF (svf_data_cur4%ISOPEN) THEN
         CLOSE svf_data_cur4;
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
    errbuf              OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       -- リターン・コード    --# 固定 #
    iv_output_kbn       IN  VARCHAR2,       -- 1.出力区分
    iv_reception_date   IN  VARCHAR2,       -- 2.受払年月
    iv_cost_type        IN  VARCHAR2,       -- 3.原価区分
    iv_base_code        IN  VARCHAR2        -- 4.拠点コード
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
       iv_output_kbn      =>  iv_output_kbn       -- 1.出力区分
      ,iv_reception_date  =>  iv_reception_date   -- 2.受払年月
      ,iv_cost_type       =>  iv_cost_type        -- 3.原価区分
      ,iv_base_code       =>  iv_base_code        -- 4.拠点コード
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
END XXCOI006A16R;
/
