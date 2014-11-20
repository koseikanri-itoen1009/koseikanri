CREATE OR REPLACE
PACKAGE BODY XXCOI006A15R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A15R(body)
 * Description      : 倉庫毎に日次または月中、月末の受払残高情報を受払残高表に出力します。
 *                    預け先毎に月末の受払残高情報を受払残高表に出力します。
 * MD.050           : 受払残高表(倉庫・預け先)    MD050_COI_006_A15
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  final_svf              SVF起動         (A-4)
 *                         ﾜｰｸﾃｰﾌﾞﾙﾃﾞｰﾀ削除(A-5)
 *  get_daily_data         日次データ取得  (A-3)
 *  get_month_data         月次データ取得  (A-3)
 *  init                   初期処理        (A-1)
 *                         ﾊﾟﾗﾒｰﾀﾁｪｯｸ      (A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0   Sai.u            新規作成
 *  2009/03/05    1.1   T.Nakamura       [障害COI_036] 件数出力の不具合対応
 *  2009/04/12    1.2   H.Sasaki         [T1_0842]倉替入出庫の帳票への出力を修正
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
  ov_cost_errbuf              VARCHAR2(5000);               -- エラー・メッセージ
  ov_cost_retcode             VARCHAR2(1);                  -- リターンコード
  ov_cost_errmsg              VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(99) := 'XXCOI006A15R';     -- パッケージ名
  cv_xxcoi_sn        CONSTANT VARCHAR2(9)  := 'XXCOI';            -- SHORT_NAME_FOR_XXCOI
  -- メッセージID
  cv_msg_00005       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
  cv_msg_00006       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';
  cv_msg_00008       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
  cv_msg_00011       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011';
  cv_msg_10094       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10094';
  cv_msg_10102       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10102';
  cv_msg_10103       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10103';
  cv_msg_10104       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10104';
  cv_msg_10105       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10105';
  cv_msg_10113       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10113';
  cv_msg_10115       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10115';
  cv_msg_10116       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10116';
  cv_msg_10119       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10119';
  cv_msg_10197       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10197';
  cv_msg_10198       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10198';
  cv_msg_10264       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10264';
  cv_msg_10314       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10314';
  -- 棚卸区分(10:日次 20:月中 30:月末)
  cv_inv_kbn1        CONSTANT VARCHAR2(20) := '10';
  cv_inv_kbn2        CONSTANT VARCHAR2(20) := '20';
  cv_inv_kbn3        CONSTANT VARCHAR2(20) := '30';
  cv_inv_kbn4        CONSTANT VARCHAR2(20) := '1';
  cv_inv_kbn5        CONSTANT VARCHAR2(20) := '2';
  -- 出力区分(10:倉庫 20:預け先)
  cv_out_kbn1        CONSTANT VARCHAR2(20) := '10';
  cv_out_kbn2        CONSTANT VARCHAR2(20) := '20';
  -- 保管場所区分(1:倉庫  2:営業車  3:預け先  4:専門店  5:自販機  8:直送)
  cv_subinv_1        CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2        CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3        CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4        CONSTANT VARCHAR2(1)  :=  '4';
  cv_subinv_5        CONSTANT VARCHAR2(1)  :=  '5';
  cv_subinv_8        CONSTANT VARCHAR2(1)  :=  '8';
  -- 保管場所分類  7:自販機(消化)
  cv_subinv_7        CONSTANT VARCHAR2(1)  :=  '7';
  --
  cv_protok_sn       CONSTANT VARCHAR2(20) := 'PRO_TOK';
  cv_orgcode_sn      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';
  cv_org_code_p      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
  cv_output_div      CONSTANT VARCHAR2(30) := 'XXCOI1_IN_OUT_LIST_OUTPUT_DIV';
  cv_inv_div         CONSTANT VARCHAR2(30) := 'XXCOI1_INVENTORY_DIV';
  cv_p_token1        CONSTANT VARCHAR2(30) := 'P_OUTPUT_TYPE';
  cv_p_token2        CONSTANT VARCHAR2(30) := 'P_INVENTORY_TYPE';
  cv_p_token3        CONSTANT VARCHAR2(30) := 'P_INVENTORY_DATE';
  cv_p_token4        CONSTANT VARCHAR2(30) := 'P_INVENTORY_MONTH';
  cv_p_token5        CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_p_token6        CONSTANT VARCHAR2(30) := 'P_STORE_CODE';
  cv_p_token7        CONSTANT VARCHAR2(30) := 'P_CUSTOMER_CODE';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  cv_inv_kbn         fnd_lookup_values.description%TYPE;    -- 棚卸区分
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_out_msg                  VARCHAR2(5000);               -- パラメータメッセージ
  gv_user_base                VARCHAR2(4);                  -- ログインユーザー拠点コード
  gv_base_short_name          VARCHAR2(8);                  -- 拠点略称
  gv_focus_base_flag          VARCHAR2(1);                  -- 管理課拠点フラグ
  gv_organization_code        VARCHAR2(30);                 -- 在庫組織コード
  gn_organization_id          NUMBER;                       -- 在庫組織ID
  gn_target_cnt               NUMBER;                       -- 対象件数
  gn_normal_cnt               NUMBER;                       -- 成功件数
  gn_error_cnt                NUMBER;                       -- エラー件数
  gn_warn_cnt                 NUMBER;                       -- スキップ件数
  gd_business_date            DATE;                         -- 業務日付
  gd_target_date              DATE;                         -- 対象日
  gd_inventory_date           DATE;                         -- 棚卸日
  gd_inventory_month          DATE;                         -- 棚卸月
  gv_inventory_date           VARCHAR2(8);                  -- 棚卸日(CAHR)
  gv_inventory_month          VARCHAR2(6);                  -- 棚卸月(CHAR)
  gv_out_kbn                  VARCHAR2(99);                 -- 出力区分
  gv_inv_kbn                  VARCHAR2(99);                 -- 棚卸区分
  gv_warehouse                VARCHAR2(99);                 -- 倉庫/預け先名称

--
  /**********************************************************************************
   * Procedure Name   : final_svf
   * Description      : SVF起動(A-4)
   ***********************************************************************************/
  PROCEDURE final_svf(
    ov_errbuf             OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'final_svf'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);     -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);        -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);     -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_frm_file      CONSTANT VARCHAR2(100) := 'XXCOI006A15S.xml';
    lv_vrq_file      CONSTANT VARCHAR2(100) := 'XXCOI006A15S.vrq';
    lv_output_mode   CONSTANT VARCHAR2(100) := '1';
--
    -- *** ローカル変数 ***
    lv_file_name              VARCHAR2(100);      -- 帳票ファイル名
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
    lv_file_name := cv_pkg_name
                 || TO_CHAR(SYSDATE,'YYYYMMDD')
                 || TO_CHAR(cn_request_id)
                 || '.pdf';
    -- A-5.SVF起動
    xxccp_svfcommon_pkg.submit_svf_request(
         ov_retcode      => lv_retcode              -- リターンコード
        ,ov_errbuf       => lv_errbuf               -- エラーメッセージ
        ,ov_errmsg       => lv_errmsg               -- ユーザー・エラーメッセージ
        ,iv_conc_name    => cv_pkg_name             -- コンカレント名
        ,iv_file_name    => lv_file_name            -- 出力ファイル名
        ,iv_file_id      => cv_pkg_name             -- 帳票ID
        ,iv_output_mode  => lv_output_mode          -- 出力区分
        ,iv_frm_file     => lv_frm_file             -- フォーム様式ファイル名
        ,iv_vrq_file     => lv_vrq_file             -- クエリー様式ファイル名
        ,iv_org_id       =>  fnd_global.org_id      -- ORG_ID
        ,iv_user_name    =>  fnd_global.user_name   -- ログイン・ユーザ名
        ,iv_resp_name    =>  fnd_global.resp_name   -- ログイン・ユーザの職責名
        ,iv_doc_name     => NULL                    -- 文書名
        ,iv_printer_name => NULL                    -- プリンタ名
        ,iv_request_id   => cn_request_id           -- 要求ID
        ,iv_nodata_msg   => NULL);                  -- データなしメッセージ
    -- 戻り値判定
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10119
                       );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- A-6.ワークテーブルデータ削除
    DELETE
    FROM  xxcoi_rep_warehouse_rcpt
    WHERE request_id = cn_request_id;
    IF (gn_target_cnt <> 0) THEN
      gn_normal_cnt := SQL%ROWCOUNT;
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END final_svf;
--
  /**********************************************************************************
   * Procedure Name   : get_daily_data
   * Description      : 日次データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_daily_data(
    iv_output_kbn         IN  VARCHAR2,      -- 出力区分
    iv_inventory_kbn      IN  VARCHAR2,      -- 棚卸区分
    iv_inventory_date     IN  VARCHAR2,      -- 棚卸日
    iv_inventory_month    IN  VARCHAR2,      -- 棚卸月
    iv_base_code          IN  VARCHAR2,      -- 拠点
    iv_warehouse          IN  VARCHAR2,      -- 倉庫
    iv_left_base          IN  VARCHAR2,      -- 預け先
    ov_errbuf             OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_daily_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message                VARCHAR2(500) := NULL;   -- メッセージ
    ln_check_num              NUMBER        := 0;      -- 受払残高票ID
--
    -- *** ローカル・カーソル(A-2-2) ***
    CURSOR daily_cur
    IS
    SELECT ird.practice_date           ird_practice_date             -- 年月日
          ,ird.base_code               ird_base_code                 -- 拠点コード
          ,biv.base_short_name         biv_base_short_name           -- 拠点名称
          ,SUBSTR(msi.secondary_inventory_name,6,2)
                                       msi_warehouse_code            -- 倉庫コード
          ,msi.attribute4              msi_left_base_code            -- 預け先コード
          ,msi.description             msi_warehouse_name            -- 倉庫名称
          ,hca.account_name            hca_left_base_name            -- 預け先名称
          ,SUBSTR((CASE                                              -- 群ｺｰﾄﾞ適用開始日
                   WHEN TRUNC(TO_DATE(iib.attribute3,'YYYY/MM/DD')) > TRUNC(gd_target_date)
                   THEN iib.attribute1                               -- 群コード(旧)
                   ELSE iib.attribute2                               -- 群コード(新)
                   END),1,3)           iib_gun_code                  -- 群コード
          ,iib.item_no                 iib_item_no                   -- 商品コード
          ,imb.item_short_name         imb_item_short_name           -- 商品名称
          ,ird.operation_cost          ird_operation_cost            -- 営業原価
          ,ird.previous_inventory_quantity
                                       ird_previous_inv_qua          -- 前日在庫数
          ,ird.standard_cost           ird_standard_cost             -- 標準原価
          ,ird.sales_shipped           ird_sales_shipped             -- 売上出庫
          ,ird.sales_shipped_b         ird_sales_shipped_b           -- 売上出庫振戻
          ,ird.return_goods            ird_return_goods              -- 返品
          ,ird.return_goods_b          ird_return_goods_b            -- 返品振戻
          ,ird.warehouse_ship          ird_warehouse_ship            -- 倉庫へ返庫
          ,ird.truck_ship              ird_truck_ship                -- 営業車へ出庫
          ,ird.others_ship             ird_others_ship               -- 入出庫＿その他出庫
          ,ird.warehouse_stock         ird_warehouse_stock           -- 倉庫より入庫
          ,ird.truck_stock             ird_truck_stock               -- 営業車より入庫
          ,ird.others_stock            ird_others_stock              -- 入出庫＿その他入庫
-- == 2009/05/12 V1.2 Modified START ===============================================================
--          ,ird.change_stock            ird_change_stock              -- 倉替入庫
--          ,ird.change_ship             ird_change_ship               -- 倉替出庫
          ,DECODE(msi.attribute1, cv_subinv_2, 0
                                      , ird.change_stock
           )                           ird_change_stock              -- 倉替入庫
          ,DECODE(msi.attribute1, cv_subinv_2, 0
                                      , ird.change_ship
           )                           ird_change_ship               -- 倉替出庫
-- == 2009/05/12 V1.2 Modified END   ===============================================================
          ,ird.goods_transfer_old      ird_goods_transfer_old        -- 商品振替(旧商品)
          ,ird.goods_transfer_new      ird_goods_transfer_new        -- 商品振替(新商品)
          ,ird.sample_quantity         ird_sample_quantity           -- 見本出庫
          ,ird.sample_quantity_b       ird_sample_quantity_b         -- 見本出庫振戻
          ,ird.customer_sample_ship    ird_customer_sample_ship      -- 顧客見本出庫
          ,ird.customer_sample_ship_b  ird_customer_sample_ship_b    -- 顧客見本出庫振戻
          ,ird.customer_support_ss     ird_customer_support_ss       -- 顧客協賛見本出庫
          ,ird.customer_support_ss_b   ird_customer_support_ss_b     -- 顧客協賛見本出庫振戻
          ,ird.ccm_sample_ship         ird_ccm_sample_ship           -- 顧客広告宣伝費A自社商品
          ,ird.ccm_sample_ship_b       ird_ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
          ,ird.vd_supplement_stock     ird_vd_supplement_stock       -- 消化VD補充入庫
          ,ird.vd_supplement_ship      ird_vd_supplement_ship        -- 消化VD補充出庫
          ,ird.inventory_change_in     ird_inventory_change_in       -- 基準在庫変更入庫
          ,ird.inventory_change_out    ird_inventory_change_out      -- 基準在庫変更出庫
          ,ird.factory_return          ird_factory_return            -- 工場返品
          ,ird.factory_return_b        ird_factory_return_b          -- 工場返品振戻
          ,ird.factory_change          ird_factory_change            -- 工場倉替
          ,ird.factory_change_b        ird_factory_change_b          -- 工場倉替振戻
          ,ird.removed_goods           ird_removed_goods             -- 廃却
          ,ird.removed_goods_b         ird_removed_goods_b           -- 廃却振戻
          ,ird.factory_stock           ird_factory_stock             -- 工場入庫
          ,ird.factory_stock_b         ird_factory_stock_b           -- 工場入庫振戻
          ,ird.wear_decrease           ird_wear_decrease             -- 棚卸減耗増
          ,ird.wear_increase           ird_wear_increase             -- 棚卸減耗減
          ,ird.selfbase_ship           ird_selfbase_ship             -- 保管場所移動＿自拠点出庫
          ,ird.selfbase_stock          ird_selfbase_stock            -- 保管場所移動＿自拠点入庫
          ,ird.book_inventory_quantity ird_book_inventory_quantity   -- 帳簿在庫数
-- == 2009/05/12 V1.2 Added START ===============================================================
          ,DECODE(msi.attribute1, cv_subinv_2, ird.change_stock
                                      , 0
           )                           ird_truck_change_stock        -- 倉替入庫（営業員）
          ,DECODE(msi.attribute1, cv_subinv_2, ird.change_ship
                                      , 0
           )                           ird_truck_change_ship         -- 倉替出庫（営業員）
-- == 2009/05/12 V1.2 Added END   ===============================================================
    FROM   xxcoi_inv_reception_daily   ird                           -- 月次在庫受払表(日次)
          ,xxcoi_base_info2_v          biv                           -- 拠点情報ビュー
          ,mtl_secondary_inventories   msi                           -- 保管場所マスタ (INV)
          ,hz_cust_accounts            hca                           -- 顧客マスタ
          ,mtl_system_items_b          sib                           -- Disc品目マスタ
          ,xxcmn_item_mst_b            imb                           -- OPM品目アドオン(XXCMN)
          ,ic_item_mst_b               iib                           -- OPM品目        (GMI)
    WHERE  biv.focus_base_code       = NVL(iv_base_code,gv_user_base)
    AND    biv.base_code             = ird.base_code
    AND    ird.organization_id       = msi.organization_id
    AND    ird.subinventory_code     = msi.secondary_inventory_name
    AND    ird.practice_date         = gd_inventory_date
    AND    ird.inventory_item_id     = sib.inventory_item_id
    AND    sib.organization_id       = ird.organization_id
    AND    sib.segment1              = iib.item_no                    -- OPM品目コード
    AND    iib.item_id               = imb.item_id
    AND  ((iv_output_kbn             = cv_out_kbn1
    AND    SUBSTR(msi.secondary_inventory_name,6,2)
                                     = NVL(iv_warehouse,SUBSTR(msi.secondary_inventory_name,6,2)))
    OR    (iv_output_kbn            <> cv_out_kbn1
    AND    msi.attribute4            = NVL(iv_left_base, msi.attribute4)))
    AND (     (
                    (    iv_output_kbn   =  cv_out_kbn1
                     AND msi.attribute1  =  cv_subinv_1
                    )
               OR   (    iv_output_kbn  <>  cv_out_kbn1
                     AND msi.attribute1  =  cv_subinv_3
                    )
              )                                                       -- 保管場所区分(預け先)
              OR
              (    (    (    iv_output_kbn   =  cv_out_kbn1
                         AND msi.attribute1  =  cv_subinv_1
                        )
                        OR
                        (    iv_output_kbn  <>  cv_out_kbn1
                         AND msi.attribute1  =  cv_subinv_4
                        )
                   )                                                  -- 保管場所区分(専門店)
                   AND
                   (    (    msi.attribute13  <>  cv_subinv_7         -- 保管場所分類(消化VD)
                         AND iv_left_base IS NULL
                        )
                        OR
                        (iv_left_base IS NOT NULL)
                   )
              )
-- == 2009/05/12 V1.2 Added START ===============================================================
              OR
              (msi.attribute1 = cv_subinv_2)
-- == 2009/05/12 V1.2 Added END   ===============================================================
        )
    AND    msi.attribute4            = hca.account_number(+)
    AND    msi.attribute7            = ird.base_code
    ORDER BY
           ird_base_code
          ,DECODE(iv_output_kbn
          ,cv_out_kbn1
          ,msi_warehouse_code
          ,msi_left_base_code)
          ,iib_gun_code
          ,iib_item_no;
--
    -- *** ローカル・レコード ***
    daily_rec daily_cur%ROWTYPE;
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
  -- カーソルオープン
  OPEN daily_cur;
  LOOP
    FETCH daily_cur INTO daily_rec;
    EXIT WHEN daily_cur%NOTFOUND;
    -- 受払残高票IDをカウント
    ln_check_num  := ln_check_num  + 1;
    -- 対象件数をカウント
    gn_target_cnt := gn_target_cnt + 1;
    -- A-3.ワークテーブルデータ登録
    INSERT INTO xxcoi_rep_warehouse_rcpt(
                slit_id                           -- 受払残高情報ID
               ,inventory_kbn                     -- 棚卸区分
               ,output_kbn                        -- 出力区分
               ,in_out_year                       -- 年
               ,in_out_month                      -- 月
               ,in_out_dat                        -- 日
               ,base_code                         -- 拠点コード
               ,base_name                         -- 拠点名称
               ,warehouse_code                    -- 倉庫/預け先コード
               ,warehouse_name                    -- 倉庫/預け先名称
               ,gun_code                          -- 群コード
               ,item_code                         -- 商品コード
               ,item_name                         -- 商品名称
               ,first_inventory_qty               -- 月首棚卸高(数量)
               ,factory_in_qty                    -- 工場入庫(数量)
               ,kuragae_in_qty                    -- 倉替入庫(数量)
               ,car_in_qty                        -- 営業車より入庫(数量)
               ,hurikae_in_qty                    -- 振替入庫(数量)
               ,car_ship_qty                      -- 営業車へ出庫(数量)
               ,sales_qty                         -- 売上出庫(数量)
               ,support_qty                       -- 協賛見本(数量)
               ,kuragae_ship_qty                  -- 倉替出庫(数量)
               ,factory_return_qty                -- 工場返品(数量)
               ,disposal_qty                      -- 廃却出庫(数量)
               ,hurikae_ship_qty                  -- 振替出庫(数量)
               ,tyoubo_stock_qty                  -- 帳簿在庫(数量)
               ,inventory_qty                     -- 棚卸高(数量)
               ,genmou_qty                        -- 棚卸減耗(数量)
               ,first_inventory_money             -- 月首棚卸高(金額)
               ,factory_in_money                  -- 工場入庫(金額)
               ,kuragae_in_money                  -- 倉替入庫(金額)
               ,car_in_money                      -- 営業車より入庫(金額)
               ,hurikae_in_money                  -- 振替入庫(金額)
               ,car_ship_money                    -- 営業車へ出庫(金額)
               ,sales_money                       -- 売上出庫(金額)
               ,support_money                     -- 協賛見本(金額)
               ,kuragae_ship_money                -- 倉替出庫(金額)
               ,factory_return_money              -- 工場返品(金額)
               ,disposal_money                    -- 廃却出庫(金額)
               ,hurikae_ship_money                -- 振替出庫(金額)
               ,tyoubo_stock_money                -- 帳簿在庫(金額)
               ,inventory_money                   -- 棚卸高(金額)
               ,genmou_money                      -- 棚卸減耗(金額)
               ,message                           -- メッセージ
               ,last_update_date                  -- 最終更新日
               ,last_updated_by                   -- 最終更新者
               ,creation_date                     -- 作成日
               ,created_by                        -- 作成者
               ,last_update_login                 -- 最終更新ユーザ
               ,request_id                        -- 要求ID
               ,program_application_id            -- プログラムアプリケーションID
               ,program_id                        -- プログラムID
               ,program_update_date)              -- プログラム更新日
        VALUES (ln_check_num                                              -- 受払残高情報ID
               ,gv_inv_kbn                                                -- 棚卸区分
               ,gv_out_kbn                                                -- 出力区分
               ,SUBSTR(TO_CHAR(daily_rec.ird_practice_date
                              ,'YYYYMMDD'),3,2)                           -- 年
               ,SUBSTR(TO_CHAR(daily_rec.ird_practice_date
                              ,'YYYYMMDD'),5,2)                           -- 月
               ,SUBSTR(TO_CHAR(daily_rec.ird_practice_date
                              ,'YYYYMMDD'),7,2)                           -- 日
               ,daily_rec.ird_base_code                                   -- 拠点コード
               ,daily_rec.biv_base_short_name                             -- 拠点名称
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,daily_rec.msi_warehouse_code
               ,daily_rec.msi_left_base_code)                             -- 倉庫/預け先コード
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,daily_rec.msi_warehouse_name
               ,daily_rec.hca_left_base_name)                             -- 倉庫/預け先名称
               ,daily_rec.iib_gun_code                                    -- 群コード
               ,daily_rec.iib_item_no                                     -- 商品コード
               ,daily_rec.imb_item_short_name                             -- 商品名称
               ,daily_rec.ird_previous_inv_qua                            -- 月首棚卸高(数量)
               ,daily_rec.ird_factory_stock                 -
                daily_rec.ird_factory_stock_b                             -- 工場入庫(数量)
               ,daily_rec.ird_change_stock                  +
                daily_rec.ird_selfbase_stock                +
                daily_rec.ird_others_stock                  +
                daily_rec.ird_vd_supplement_stock           +
                daily_rec.ird_inventory_change_in                         -- 倉替入庫(数量)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,daily_rec.ird_truck_stock                                 -- 営業車より入庫(数量)
               ,daily_rec.ird_truck_stock                   +
                daily_rec.ird_truck_change_stock                          -- 営業車より入庫(数量)
-- == 2009/05/12 V1.2 Modified END   ===============================================================
               ,daily_rec.ird_goods_transfer_new                          -- 振替入庫(数量)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,daily_rec.ird_truck_ship                                  -- 営業車へ出庫(数量)
               ,daily_rec.ird_truck_ship                    +
                daily_rec.ird_truck_change_ship                           -- 営業車へ出庫(数量)
-- == 2009/05/12 V1.2 Modified END   ===============================================================
               ,daily_rec.ird_sales_shipped                 -
                daily_rec.ird_sales_shipped_b               -
                daily_rec.ird_return_goods                  +
                daily_rec.ird_return_goods_b                              -- 売上出庫(数量)
               ,daily_rec.ird_customer_sample_ship          -
                daily_rec.ird_customer_sample_ship_b        +
                daily_rec.ird_customer_support_ss           -
                daily_rec.ird_customer_support_ss_b         +
                daily_rec.ird_sample_quantity               -
                daily_rec.ird_sample_quantity_b             +
                daily_rec.ird_ccm_sample_ship               -
                daily_rec.ird_ccm_sample_ship_b                           -- 協賛見本(数量)
               ,daily_rec.ird_change_ship                   +
                daily_rec.ird_selfbase_ship                 +
                daily_rec.ird_others_ship                   +
                daily_rec.ird_vd_supplement_ship            +
                daily_rec.ird_inventory_change_out          +
                daily_rec.ird_factory_change                -
                daily_rec.ird_factory_change_b                            -- 倉替出庫(数量)
               ,daily_rec.ird_factory_return                -
                daily_rec.ird_factory_return_b                            -- 工場返品(数量)
               ,daily_rec.ird_removed_goods                 -
                daily_rec.ird_removed_goods_b                             -- 廃却出庫(数量)
               ,daily_rec.ird_goods_transfer_old                          -- 振替出庫(数量)
               ,daily_rec.ird_book_inventory_quantity                     -- 帳簿在庫(数量)
               ,0                                                         -- 棚卸高(数量)
               ,0                                                         -- 棚卸減耗(数量)
               ,ROUND( daily_rec.ird_previous_inv_qua
                     * daily_rec.ird_operation_cost)                      -- 月首棚卸高(金額)
               ,ROUND((daily_rec.ird_factory_stock          -
                       daily_rec.ird_factory_stock_b)
                     * daily_rec.ird_operation_cost)                      -- 工場入庫(金額)
               ,ROUND((daily_rec.ird_change_stock           +
                       daily_rec.ird_selfbase_stock         +
                       daily_rec.ird_others_stock           +
                       daily_rec.ird_vd_supplement_stock    +
                       daily_rec.ird_inventory_change_in)
                     * daily_rec.ird_operation_cost)                      -- 倉替入庫(金額)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,ROUND( daily_rec.ird_truck_stock
--                     * daily_rec.ird_operation_cost)                      -- 営業車より入庫(金額)
               ,ROUND((daily_rec.ird_truck_stock            +
                       daily_rec.ird_truck_change_stock
                      ) * daily_rec.ird_operation_cost)                   -- 営業車より入庫(金額)
-- == 2009/05/12 V1.2 Modified END   ===============================================================
               ,ROUND( daily_rec.ird_goods_transfer_new
                     * daily_rec.ird_operation_cost)                      -- 振替入庫(金額)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,ROUND( daily_rec.ird_truck_ship
--                     * daily_rec.ird_operation_cost)                      -- 営業車へ出庫(金額)
               ,ROUND((daily_rec.ird_truck_ship             +
                       daily_rec.ird_truck_change_ship
                      ) * daily_rec.ird_operation_cost)                   -- 営業車へ出庫(金額)
-- == 2009/05/12 V1.2 Modified START ===============================================================
               ,ROUND((daily_rec.ird_sales_shipped          -
                       daily_rec.ird_sales_shipped_b        -
                       daily_rec.ird_return_goods           +
                       daily_rec.ird_return_goods_b)
                     * daily_rec.ird_operation_cost)                      -- 売上出庫(金額)
               ,ROUND((daily_rec.ird_customer_sample_ship   -
                       daily_rec.ird_customer_sample_ship_b +
                       daily_rec.ird_customer_support_ss    -
                       daily_rec.ird_customer_support_ss_b  +
                       daily_rec.ird_sample_quantity        -
                       daily_rec.ird_sample_quantity_b      +
                       daily_rec.ird_ccm_sample_ship        -
                       daily_rec.ird_ccm_sample_ship_b)
                     * daily_rec.ird_operation_cost)                      -- 協賛見本(金額)
               ,ROUND((daily_rec.ird_change_ship            +
                       daily_rec.ird_selfbase_ship          +
                       daily_rec.ird_others_ship            +
                       daily_rec.ird_vd_supplement_ship     +
                       daily_rec.ird_inventory_change_out   +
                       daily_rec.ird_factory_change         -
                       daily_rec.ird_factory_change_b)
                     * daily_rec.ird_operation_cost)                      -- 倉替出庫(金額)
               ,ROUND((daily_rec.ird_factory_return         -
                       daily_rec.ird_factory_return_b)
                     * daily_rec.ird_operation_cost)                      -- 工場返品(金額)
               ,ROUND((daily_rec.ird_removed_goods          -
                       daily_rec.ird_removed_goods_b)
                     * daily_rec.ird_operation_cost)                      -- 廃却出庫(金額)
               ,ROUND( daily_rec.ird_goods_transfer_old
                     * daily_rec.ird_operation_cost)                      -- 振替出庫(金額)
               ,ROUND( daily_rec.ird_book_inventory_quantity
                     * daily_rec.ird_operation_cost)                      -- 帳簿在庫(金額)
               ,0                                                         -- 棚卸高(金額)
               ,0                                                         -- 棚卸減耗(金額)
               ,NULL                                                      -- メッセージ
               ,SYSDATE                                                   -- 最終更新日
               ,cn_last_updated_by                                        -- 最終更新者
               ,SYSDATE                                                   -- 作成日
               ,cn_created_by                                             -- 作成者
               ,cn_last_update_login                                      -- 最終更新ユーザ
               ,cn_request_id                                             -- 要求ID
               ,cn_program_application_id                                 -- プログラムアプリケーションID
               ,cn_program_id                                             -- プログラムID
               ,SYSDATE);                                                 -- プログラム更新日
  --
  END LOOP;
  CLOSE daily_cur;
  -- 結果0件の場合
  IF (ln_check_num = 0) THEN
    -- 結果0件メッセージ取得
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    BEGIN
      IF (iv_output_kbn = cv_out_kbn1 AND iv_warehouse IS NOT NULL) THEN
        SELECT msi.description
        INTO   gv_warehouse
        FROM   mtl_secondary_inventories  msi     -- 保管場所マスタ(INV)
        WHERE  msi.organization_id = gn_organization_id
        AND    SUBSTR(msi.secondary_inventory_name,6,2) = iv_warehouse
        AND    msi.attribute1 = cv_subinv_1
        AND    msi.attribute7 = iv_base_code;
      ELSIF (iv_output_kbn = cv_out_kbn2 AND iv_left_base IS NOT NULL) THEN
        SELECT hca.account_name
        INTO   gv_warehouse
        FROM   hz_cust_accounts     hca           -- 顧客マスタ
        WHERE  hca.account_number = iv_left_base;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        gv_warehouse := NULL;
    END;
    --
    BEGIN
      SELECT SUBSTRB(account_name,1,8)            -- 拠点略称
      INTO   gv_base_short_name
      FROM   xxcoi_user_base_info_v               -- 拠点ビュー
      WHERE  account_number = iv_base_code
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        gv_base_short_name := NULL;
    END;
    -- 結果0件メッセージ出力
    INSERT INTO xxcoi_rep_warehouse_rcpt(
                slit_id                           -- 受払残高情報ID
               ,inventory_kbn                     -- 棚卸区分
               ,output_kbn                        -- 出力区分
               ,in_out_year                       -- 年
               ,in_out_month                      -- 月
               ,in_out_dat                        -- 日
               ,base_code                         -- 拠点コード
               ,base_name                         -- 拠点名称
               ,warehouse_code                    -- 倉庫/預け先コード
               ,warehouse_name                    -- 倉庫/預け先名称
               ,message                           -- メッセージ
               ,last_update_date                  -- 最終更新日
               ,last_updated_by                   -- 最終更新者
               ,creation_date                     -- 作成日
               ,created_by                        -- 作成者
               ,last_update_login                 -- 最終更新ユーザ
               ,request_id                        -- 要求ID
               ,program_application_id            -- プログラムアプリケーションID
               ,program_id                        -- プログラムID
               ,program_update_date)              -- プログラム更新日
        VALUES (ln_check_num                      -- 受払残高情報ID
               ,gv_inv_kbn                        -- 棚卸区分
               ,gv_out_kbn                        -- 出力区分
               ,SUBSTR(gv_inventory_date,3,2)     -- 年
               ,SUBSTR(gv_inventory_date,5,2)     -- 月
               ,SUBSTR(gv_inventory_date,7,2)     -- 日
               ,iv_base_code                      -- 拠点コード
               ,gv_base_short_name                -- 拠点名称
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,iv_warehouse
               ,iv_left_base)                     -- 倉庫/預け先コード
               ,gv_warehouse                      -- 倉庫/預け先名称
               ,lv_message                        -- メッセージ
               ,SYSDATE                           -- 最終更新日
               ,cn_last_updated_by                -- 最終更新者
               ,SYSDATE                           -- 作成日
               ,cn_created_by                     -- 作成者
               ,cn_last_update_login              -- 最終更新ユーザ
               ,cn_request_id                     -- 要求ID
               ,cn_program_application_id         -- プログラムアプリケーションID
               ,cn_program_id                     -- プログラムID
               ,SYSDATE);                         -- プログラム更新日
  END IF;
  -- コミット
  COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN                                 --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : get_month_data
   * Description      : 月次データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_month_data(
    iv_output_kbn         IN  VARCHAR2,      -- 出力区分
    iv_inventory_kbn      IN  VARCHAR2,      -- 棚卸区分
    iv_inventory_date     IN  VARCHAR2,      -- 棚卸日
    iv_inventory_month    IN  VARCHAR2,      -- 棚卸月
    iv_base_code          IN  VARCHAR2,      -- 拠点
    iv_warehouse          IN  VARCHAR2,      -- 倉庫
    iv_left_base          IN  VARCHAR2,      -- 預け先
    ov_errbuf             OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_month_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message                VARCHAR2(500) := NULL;   -- メッセージ
    ln_check_num              NUMBER        := 0;      -- 受払残高票ID
--
    -- *** ローカル・カーソル(A-2-2) ***
    CURSOR month_cur
    IS
    SELECT irm.practice_month          irm_practice_month            -- 年月
          ,irm.practice_date           irm_practice_date             -- 年月日
          ,irm.base_code               irm_base_code                 -- 拠点コード
          ,biv.base_short_name         biv_base_short_name           -- 拠点名称
          ,SUBSTR(msi.secondary_inventory_name,6,2)
                                       msi_warehouse_code            -- 倉庫コード
          ,msi.attribute4              msi_left_base_code            -- 預け先コード
          ,msi.description             msi_warehouse_name            -- 倉庫名称
          ,hca.account_name            hca_left_base_name            -- 預け先名称
          ,SUBSTR((CASE                                              -- 群ｺｰﾄﾞ適用開始日
                   WHEN TRUNC(TO_DATE(iib.attribute3,'YYYY/MM/DD')) > TRUNC(gd_target_date)
                   THEN iib.attribute1                               -- 群コード(旧)
                   ELSE iib.attribute2                               -- 群コード(新)
                   END),1,3)           iib_gun_code                  -- 群コード
          ,iib.item_no                 iib_item_no                   -- 商品コード
          ,imb.item_short_name         imb_item_short_name           -- 商品名称
          ,irm.operation_cost          irm_operation_cost            -- 営業原価
          ,irm.standard_cost           irm_standard_cost             -- 標準原価
          ,irm.sales_shipped           irm_sales_shipped             -- 売上出庫
          ,irm.sales_shipped_b         irm_sales_shipped_b           -- 売上出庫振戻
          ,irm.return_goods            irm_return_goods              -- 返品
          ,irm.return_goods_b          irm_return_goods_b            -- 返品振戻
          ,irm.warehouse_ship          irm_warehouse_ship            -- 倉庫へ返庫
          ,irm.truck_ship              irm_truck_ship                -- 営業車へ出庫
          ,irm.others_ship             irm_others_ship               -- 入出庫＿その他出庫
          ,irm.warehouse_stock         irm_warehouse_stock           -- 倉庫より入庫
          ,irm.truck_stock             irm_truck_stock               -- 営業車より入庫
          ,irm.others_stock            irm_others_stock              -- 入出庫＿その他入庫
-- == 2009/05/12 V1.2 Modified START ===============================================================
--          ,irm.change_stock            irm_change_stock              -- 倉替入庫
--          ,irm.change_ship             irm_change_ship               -- 倉替出庫
          ,DECODE(msi.attribute1, cv_subinv_2, 0
                                      , irm.change_stock
           )                           irm_change_stock              -- 倉替入庫
          ,DECODE(msi.attribute1, cv_subinv_2, 0
                                      , irm.change_ship
           )                           irm_change_ship               -- 倉替出庫
-- == 2009/05/12 V1.2 Modified END   ===============================================================
          ,irm.goods_transfer_old      irm_goods_transfer_old        -- 商品振替(旧商品)
          ,irm.goods_transfer_new      irm_goods_transfer_new        -- 商品振替(新商品)
          ,irm.sample_quantity         irm_sample_quantity           -- 見本出庫
          ,irm.sample_quantity_b       irm_sample_quantity_b         -- 見本出庫振戻
          ,irm.customer_sample_ship    irm_customer_sample_ship      -- 顧客見本出庫
          ,irm.customer_sample_ship_b  irm_customer_sample_ship_b    -- 顧客見本出庫振戻
          ,irm.customer_support_ss     irm_customer_support_ss       -- 顧客協賛見本出庫
          ,irm.customer_support_ss_b   irm_customer_support_ss_b     -- 顧客協賛見本出庫振戻
          ,irm.ccm_sample_ship         irm_ccm_sample_ship           -- 顧客広告宣伝費A自社商品
          ,irm.ccm_sample_ship_b       irm_ccm_sample_ship_b         -- 顧客広告宣伝費A自社商品振戻
          ,irm.vd_supplement_stock     irm_vd_supplement_stock       -- 消化VD補充入庫
          ,irm.vd_supplement_ship      irm_vd_supplement_ship        -- 消化VD補充出庫
          ,irm.inventory_change_in     irm_inventory_change_in       -- 基準在庫変更入庫
          ,irm.inventory_change_out    irm_inventory_change_out      -- 基準在庫変更出庫
          ,irm.factory_return          irm_factory_return            -- 工場返品
          ,irm.factory_return_b        irm_factory_return_b          -- 工場返品振戻
          ,irm.factory_change          irm_factory_change            -- 工場倉替
          ,irm.factory_change_b        irm_factory_change_b          -- 工場倉替振戻
          ,irm.removed_goods           irm_removed_goods             -- 廃却
          ,irm.removed_goods_b         irm_removed_goods_b           -- 廃却振戻
          ,irm.factory_stock           irm_factory_stock             -- 工場入庫
          ,irm.factory_stock_b         irm_factory_stock_b           -- 工場入庫振戻
          ,irm.wear_decrease           irm_wear_decrease             -- 棚卸減耗増
          ,irm.wear_increase           irm_wear_increase             -- 棚卸減耗減
          ,irm.selfbase_ship           irm_selfbase_ship             -- 保管場所移動＿自拠点出庫
          ,irm.selfbase_stock          irm_selfbase_stock            -- 保管場所移動＿自拠点入庫
          ,irm.inv_result              irm_inv_result                -- 棚卸結果
          ,irm.inv_result_bad          irm_inv_result_bad            -- 棚卸結果(不良品)
          ,irm.inv_wear                irm_inv_wear                  -- 棚卸減耗
          ,irm.month_begin_quantity    irm_month_begin_quantity      -- 月首棚卸高
-- == 2009/05/12 V1.2 Added START ===============================================================
          ,DECODE(msi.attribute1, cv_subinv_2, irm.change_stock
                                      , 0
           )                           irm_truck_change_stock        -- 倉替入庫（営業員）
          ,DECODE(msi.attribute1, cv_subinv_2, irm.change_ship
                                      , 0
           )                           irm_truck_change_ship         -- 倉替出庫（営業員）
-- == 2009/05/12 V1.2 Added END   ===============================================================
    FROM   xxcoi_inv_reception_monthly irm                           -- 月次在庫受払表(月次)
          ,xxcoi_base_info2_v          biv                           -- 拠点情報ビュー
          ,mtl_secondary_inventories   msi                           -- 保管場所マスタ (INV)
          ,hz_cust_accounts            hca                           -- 顧客マスタ
          ,mtl_system_items_b          sib                           -- Disc品目マスタ
          ,xxcmn_item_mst_b            imb                           -- OPM品目アドオン(XXCMN)
          ,ic_item_mst_b               iib                           -- OPM品目        (GMI)
    WHERE  biv.focus_base_code       = NVL(iv_base_code,gv_user_base)
    AND    biv.base_code             = irm.base_code
    AND    irm.organization_id       = msi.organization_id
    AND    irm.subinventory_code     = msi.secondary_inventory_name
    AND  ((iv_inventory_kbn          = cv_inv_kbn3
    AND    irm.practice_month        = gv_inventory_month)
    OR    (iv_inventory_kbn         <> cv_inv_kbn3
    AND    irm.practice_date         = gd_inventory_date))
    AND  ((iv_inventory_kbn          = cv_inv_kbn2
    AND    irm.inventory_kbn         = cv_inv_kbn4)
    OR    (iv_inventory_kbn         <> cv_inv_kbn2
    AND    irm.inventory_kbn         = cv_inv_kbn5))
    AND    irm.inventory_item_id     = sib.inventory_item_id
    AND    sib.organization_id       = irm.organization_id
    AND    sib.segment1              = iib.item_no                   -- OPM品目コード
    AND    iib.item_id               = imb.item_id
    AND  ((iv_output_kbn             = cv_out_kbn1
    AND    SUBSTR(msi.secondary_inventory_name,6,2)
                                     = NVL(iv_warehouse,SUBSTR(msi.secondary_inventory_name,6,2)))
    OR    (iv_output_kbn            <> cv_out_kbn1
    AND    msi.attribute4            = NVL(iv_left_base,msi.attribute4)))
    AND (     (    (    iv_output_kbn             = cv_out_kbn1
                    AND msi.attribute1            = cv_subinv_1
                   )
                   OR
                   (    iv_output_kbn            <> cv_out_kbn1
                    AND msi.attribute1            = cv_subinv_3
                   )
              )                 -- 保管場所区分(預け先)
              OR
              (    (    (    iv_output_kbn             = cv_out_kbn1
                         AND msi.attribute1            = cv_subinv_1
                        )
                        OR
                        (    iv_output_kbn            <> cv_out_kbn1
                         AND msi.attribute1            = cv_subinv_4
                        )
                   )                 -- 保管場所区分(専門店)
                   AND
                   (    (    msi.attribute13          <> cv_subinv_7                   -- 保管場所分類(消化VD)
                         AND iv_left_base IS NULL
                        )
                        OR
                        (iv_left_base IS NOT NULL)
                   )
              )
-- == 2009/05/12 V1.2 Added START ===============================================================
              OR
              (msi.attribute1 = cv_subinv_2)
-- == 2009/05/12 V1.2 Added END   ===============================================================
        )
    AND    msi.attribute4            = hca.account_number(+)
    AND    msi.attribute7            = irm.base_code
    ORDER BY
           irm_base_code
          ,DECODE(iv_output_kbn
          ,cv_out_kbn1
          ,msi_warehouse_code
          ,msi_left_base_code)
          ,iib_gun_code
          ,iib_item_no;
--
    -- *** ローカル・レコード ***
    month_rec month_cur%ROWTYPE;
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
  -- カーソルオープン
  OPEN month_cur;
  LOOP
    FETCH month_cur INTO month_rec;
    EXIT WHEN month_cur%NOTFOUND;
    -- 受払残高票IDをカウント
    ln_check_num  := ln_check_num  + 1;
    -- 対象件数をカウント
    gn_target_cnt := gn_target_cnt + 1;
    -- A-3.ワークテーブルデータ登録
    INSERT INTO xxcoi_rep_warehouse_rcpt(
                slit_id                           -- 受払残高情報ID
               ,inventory_kbn                     -- 棚卸区分
               ,output_kbn                        -- 出力区分
               ,in_out_year                       -- 年
               ,in_out_month                      -- 月
               ,in_out_dat                        -- 日
               ,base_code                         -- 拠点コード
               ,base_name                         -- 拠点名称
               ,warehouse_code                    -- 倉庫/預け先コード
               ,warehouse_name                    -- 倉庫/預け先名称
               ,gun_code                          -- 群コード
               ,item_code                         -- 商品コード
               ,item_name                         -- 商品名称
               ,first_inventory_qty               -- 月首棚卸高(数量)
               ,factory_in_qty                    -- 工場入庫(数量)
               ,kuragae_in_qty                    -- 倉替入庫(数量)
               ,car_in_qty                        -- 営業車より入庫(数量)
               ,hurikae_in_qty                    -- 振替入庫(数量)
               ,car_ship_qty                      -- 営業車へ出庫(数量)
               ,sales_qty                         -- 売上出庫(数量)
               ,support_qty                       -- 協賛見本(数量)
               ,kuragae_ship_qty                  -- 倉替出庫(数量)
               ,factory_return_qty                -- 工場返品(数量)
               ,disposal_qty                      -- 廃却出庫(数量)
               ,hurikae_ship_qty                  -- 振替出庫(数量)
               ,tyoubo_stock_qty                  -- 帳簿在庫(数量)
               ,inventory_qty                     -- 棚卸高(数量)
               ,genmou_qty                        -- 棚卸減耗(数量)
               ,first_inventory_money             -- 月首棚卸高(金額)
               ,factory_in_money                  -- 工場入庫(金額)
               ,kuragae_in_money                  -- 倉替入庫(金額)
               ,car_in_money                      -- 営業車より入庫(金額)
               ,hurikae_in_money                  -- 振替入庫(金額)
               ,car_ship_money                    -- 営業車へ出庫(金額)
               ,sales_money                       -- 売上出庫(金額)
               ,support_money                     -- 協賛見本(金額)
               ,kuragae_ship_money                -- 倉替出庫(金額)
               ,factory_return_money              -- 工場返品(金額)
               ,disposal_money                    -- 廃却出庫(金額)
               ,hurikae_ship_money                -- 振替出庫(金額)
               ,tyoubo_stock_money                -- 帳簿在庫(金額)
               ,inventory_money                   -- 棚卸高(金額)
               ,genmou_money                      -- 棚卸減耗(金額)
               ,message                           -- メッセージ
               ,last_update_date                  -- 最終更新日
               ,last_updated_by                   -- 最終更新者
               ,creation_date                     -- 作成日
               ,created_by                        -- 作成者
               ,last_update_login                 -- 最終更新ユーザ
               ,request_id                        -- 要求ID
               ,program_application_id            -- プログラムアプリケーションID
               ,program_id                        -- プログラムID
               ,program_update_date)              -- プログラム更新日
        VALUES (ln_check_num                                              -- 受払残高情報ID
               ,gv_inv_kbn                                                -- 棚卸区分
               ,gv_out_kbn                                                -- 出力区分
               ,DECODE(iv_inventory_kbn,cv_inv_kbn3
               ,SUBSTR(month_rec.irm_practice_month,3,2)
               ,SUBSTR(TO_CHAR(month_rec.irm_practice_date
                              ,'YYYYMMDD'),3,2))                          -- 年
               ,DECODE(iv_inventory_kbn,cv_inv_kbn3
               ,SUBSTR(month_rec.irm_practice_month,5,2)
               ,SUBSTR(TO_CHAR(month_rec.irm_practice_date
                              ,'YYYYMMDD'),5,2))                          -- 月
               ,DECODE(iv_inventory_kbn,cv_inv_kbn3
               ,NULL
               ,SUBSTR(TO_CHAR(month_rec.irm_practice_date
                              ,'YYYYMMDD'),7,2))                          -- 日
               ,month_rec.irm_base_code                                   -- 拠点コード
               ,month_rec.biv_base_short_name                             -- 拠点名称
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,month_rec.msi_warehouse_code
               ,month_rec.msi_left_base_code)                             -- 倉庫/預け先コード
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,month_rec.msi_warehouse_name
               ,month_rec.hca_left_base_name)                             -- 倉庫/預け先名称
               ,month_rec.iib_gun_code                                    -- 群コード
               ,month_rec.iib_item_no                                     -- 商品コード
               ,month_rec.imb_item_short_name                             -- 商品名称
               ,month_rec.irm_month_begin_quantity                        -- 月首棚卸高(数量)
               ,month_rec.irm_factory_stock                 -
                month_rec.irm_factory_stock_b                             -- 工場入庫(数量)
               ,month_rec.irm_change_stock                  +
                month_rec.irm_selfbase_stock                +
                month_rec.irm_others_stock                  +
                month_rec.irm_vd_supplement_stock           +
                month_rec.irm_inventory_change_in                         -- 倉替入庫(数量)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,month_rec.irm_truck_stock                                 -- 営業車より入庫(数量)
               ,month_rec.irm_truck_stock                   +
                month_rec.irm_truck_change_stock                          -- 営業車より入庫(数量)
-- == 2009/05/12 V1.2 Modified END ===============================================================
               ,month_rec.irm_goods_transfer_new                          -- 振替入庫(数量)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,month_rec.irm_truck_ship                                  -- 営業車へ出庫(数量)
               ,month_rec.irm_truck_ship                    +
                month_rec.irm_truck_change_ship                           -- 営業車へ出庫(数量)
-- == 2009/05/12 V1.2 Modified END   ===============================================================
               ,month_rec.irm_sales_shipped                 -
                month_rec.irm_sales_shipped_b               -
                month_rec.irm_return_goods                  +
                month_rec.irm_return_goods_b                              -- 売上出庫(数量)
               ,month_rec.irm_customer_sample_ship          -
                month_rec.irm_customer_sample_ship_b        +
                month_rec.irm_customer_support_ss           -
                month_rec.irm_customer_support_ss_b         +
                month_rec.irm_sample_quantity               -
                month_rec.irm_sample_quantity_b             +
                month_rec.irm_ccm_sample_ship               -
                month_rec.irm_ccm_sample_ship_b                           -- 協賛見本(数量)
               ,month_rec.irm_change_ship                   +
                month_rec.irm_selfbase_ship                 +
                month_rec.irm_others_ship                   +
                month_rec.irm_vd_supplement_ship            +
                month_rec.irm_inventory_change_out          +
                month_rec.irm_factory_change                -
                month_rec.irm_factory_change_b                            -- 倉替出庫(数量)
               ,month_rec.irm_factory_return                -
                month_rec.irm_factory_return_b                            -- 工場返品(数量)
               ,month_rec.irm_removed_goods                 -
                month_rec.irm_removed_goods_b                             -- 廃却出庫(数量)
               ,month_rec.irm_goods_transfer_old                          -- 振替出庫(数量)
               ,month_rec.irm_inv_result                    +
                month_rec.irm_inv_result_bad                +
                month_rec.irm_inv_wear                                    -- 帳簿在庫(数量)
               ,month_rec.irm_inv_result                    +
                month_rec.irm_inv_result_bad                              -- 棚卸高(数量)
               ,month_rec.irm_inv_wear                                    -- 棚卸減耗(数量)
               ,ROUND( month_rec.irm_month_begin_quantity
                     * month_rec.irm_operation_cost)                      -- 月首棚卸高(金額)
               ,ROUND((month_rec.irm_factory_stock          -
                       month_rec.irm_factory_stock_b)
                     * month_rec.irm_operation_cost)                      -- 工場入庫(金額)
               ,ROUND((month_rec.irm_change_stock           +
                       month_rec.irm_selfbase_stock         +
                       month_rec.irm_others_stock           +
                       month_rec.irm_vd_supplement_stock    +
                       month_rec.irm_inventory_change_in)
                     * month_rec.irm_operation_cost)                      -- 倉替入庫(金額)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,ROUND( month_rec.irm_truck_stock
--                     * month_rec.irm_operation_cost)                      -- 営業車より入庫(金額)
               ,ROUND((month_rec.irm_truck_stock            +
                       month_rec.irm_truck_change_stock
                      ) * month_rec.irm_operation_cost)                   -- 営業車より入庫(金額)
-- == 2009/05/12 V1.2 Modified END   ===============================================================
               ,ROUND( month_rec.irm_goods_transfer_new
                     * month_rec.irm_operation_cost)                      -- 振替入庫(金額)
-- == 2009/05/12 V1.2 Modified START ===============================================================
--               ,ROUND( month_rec.irm_truck_ship
--                     * month_rec.irm_operation_cost)                      -- 営業車へ出庫(金額)
               ,ROUND((month_rec.irm_truck_ship             +
                       month_rec.irm_truck_change_ship
                      ) * month_rec.irm_operation_cost)                   -- 営業車へ出庫(金額)
-- == 2009/05/12 V1.2 Modified END   ===============================================================
               ,ROUND((month_rec.irm_sales_shipped          -
                       month_rec.irm_sales_shipped_b        -
                       month_rec.irm_return_goods           +
                       month_rec.irm_return_goods_b)
                     * month_rec.irm_operation_cost)                      -- 売上出庫(金額)
               ,ROUND((month_rec.irm_customer_sample_ship   -
                       month_rec.irm_customer_sample_ship_b +
                       month_rec.irm_customer_support_ss    -
                       month_rec.irm_customer_support_ss_b  +
                       month_rec.irm_sample_quantity        -
                       month_rec.irm_sample_quantity_b      +
                       month_rec.irm_ccm_sample_ship        -
                       month_rec.irm_ccm_sample_ship_b)
                     * month_rec.irm_operation_cost)                      -- 協賛見本(金額)
               ,ROUND((month_rec.irm_change_ship            +
                       month_rec.irm_selfbase_ship          +
                       month_rec.irm_others_ship            +
                       month_rec.irm_vd_supplement_ship     +
                       month_rec.irm_inventory_change_out   +
                       month_rec.irm_factory_change         -
                       month_rec.irm_factory_change_b)
                     * month_rec.irm_operation_cost)                      -- 倉替出庫(金額)
               ,ROUND((month_rec.irm_factory_return         -
                       month_rec.irm_factory_return_b)
                     * month_rec.irm_operation_cost)                      -- 工場返品(金額)
               ,ROUND((month_rec.irm_removed_goods          -
                       month_rec.irm_removed_goods_b)
                     * month_rec.irm_operation_cost)                      -- 廃却出庫(金額)
               ,ROUND( month_rec.irm_goods_transfer_old
                     * month_rec.irm_operation_cost)                      -- 振替出庫(金額)
               ,ROUND((month_rec.irm_inv_result             +
                       month_rec.irm_inv_result_bad         +
                       month_rec.irm_inv_wear)
                     * month_rec.irm_operation_cost)                      -- 帳簿在庫(金額)
               ,ROUND((month_rec.irm_inv_result             +
                       month_rec.irm_inv_result_bad)
                     * month_rec.irm_operation_cost)                      -- 棚卸高(金額)
               ,ROUND( month_rec.irm_inv_wear
                     * month_rec.irm_operation_cost)                      -- 棚卸減耗(金額)
               ,NULL                                                      -- メッセージ
               ,SYSDATE                                                   -- 最終更新日
               ,cn_last_updated_by                                        -- 最終更新者
               ,SYSDATE                                                   -- 作成日
               ,cn_created_by                                             -- 作成者
               ,cn_last_update_login                                      -- 最終更新ユーザ
               ,cn_request_id                                             -- 要求ID
               ,cn_program_application_id                                 -- プログラムアプリケーションID
               ,cn_program_id                                             -- プログラムID
               ,SYSDATE);                                                 -- プログラム更新日
  --
  END LOOP;
  CLOSE month_cur;
  -- 結果0件の場合
  IF (ln_check_num = 0) THEN
    -- 結果0件メッセージ取得
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    BEGIN
      IF (iv_output_kbn = cv_out_kbn1 AND iv_warehouse IS NOT NULL) THEN
        SELECT msi.description
        INTO   gv_warehouse
        FROM   mtl_secondary_inventories  msi     -- 保管場所マスタ(INV)
        WHERE  msi.organization_id = gn_organization_id
        AND    SUBSTR(msi.secondary_inventory_name,6,2) = iv_warehouse
        AND    msi.attribute1 = cv_subinv_1
        AND    msi.attribute7 = iv_base_code;
      ELSIF (iv_output_kbn = cv_out_kbn2 AND iv_left_base IS NOT NULL) THEN
        SELECT hca.account_name
        INTO   gv_warehouse
        FROM   hz_cust_accounts     hca           -- 顧客マスタ
        WHERE  hca.account_number = iv_left_base;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        gv_warehouse := NULL;
    END;
    --
    BEGIN
      SELECT SUBSTRB(account_name,1,8)            -- 拠点略称
      INTO   gv_base_short_name
      FROM   xxcoi_user_base_info_v               -- 拠点ビュー
      WHERE  account_number = iv_base_code
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        gv_base_short_name := NULL;
    END;
    -- 結果0件メッセージ出力
    INSERT INTO xxcoi_rep_warehouse_rcpt(
                slit_id                           -- 受払残高情報ID
               ,inventory_kbn                     -- 棚卸区分
               ,output_kbn                        -- 出力区分
               ,in_out_year                       -- 年
               ,in_out_month                      -- 月
               ,in_out_dat                        -- 日
               ,base_code                         -- 拠点コード
               ,base_name                         -- 拠点名称
               ,warehouse_code                    -- 倉庫/預け先コード
               ,warehouse_name                    -- 倉庫/預け先名称
               ,message                           -- メッセージ
               ,last_update_date                  -- 最終更新日
               ,last_updated_by                   -- 最終更新者
               ,creation_date                     -- 作成日
               ,created_by                        -- 作成者
               ,last_update_login                 -- 最終更新ユーザ
               ,request_id                        -- 要求ID
               ,program_application_id            -- プログラムアプリケーションID
               ,program_id                        -- プログラムID
               ,program_update_date)              -- プログラム更新日
        VALUES (ln_check_num                      -- 受払残高情報ID
               ,gv_inv_kbn                        -- 棚卸区分
               ,gv_out_kbn                        -- 出力区分
               ,DECODE(iv_inventory_kbn,cv_inv_kbn3
               ,SUBSTR(gv_inventory_month,3,2)
               ,SUBSTR(gv_inventory_date,3,2))    -- 年
               ,DECODE(iv_inventory_kbn,cv_inv_kbn3
               ,SUBSTR(gv_inventory_month,5,2)
               ,SUBSTR(gv_inventory_date,5,2))    -- 月
               ,DECODE(iv_inventory_kbn,cv_inv_kbn3
               ,NULL
               ,SUBSTR(gv_inventory_date,7,2))    -- 日
               ,iv_base_code                      -- 拠点コード
               ,gv_base_short_name                -- 拠点名称
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,iv_warehouse
               ,iv_left_base)                     -- 倉庫/預け先コード
               ,gv_warehouse                      -- 倉庫/預け先名称
               ,lv_message                        -- メッセージ
               ,SYSDATE                           -- 最終更新日
               ,cn_last_updated_by                -- 最終更新者
               ,SYSDATE                           -- 作成日
               ,cn_created_by                     -- 作成者
               ,cn_last_update_login              -- 最終更新ユーザ
               ,cn_request_id                     -- 要求ID
               ,cn_program_application_id         -- プログラムアプリケーションID
               ,cn_program_id                     -- プログラムID
               ,SYSDATE);                         -- プログラム更新日
  END IF;
  -- コミット
  COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN                                 --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      IF (month_cur%ISOPEN) THEN
        CLOSE month_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF (month_cur%ISOPEN) THEN
        CLOSE month_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_month_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理
   **********************************************************************************/
  PROCEDURE init(
    iv_output_kbn         IN  VARCHAR2,    -- 出力区分
    iv_inventory_kbn      IN  VARCHAR2,    -- 棚卸区分
    iv_inventory_date     IN  VARCHAR2,    -- 棚卸日
    iv_inventory_month    IN  VARCHAR2,    -- 棚卸月
    iv_base_code          IN  VARCHAR2,    -- 拠点
    iv_warehouse          IN  VARCHAR2,    -- 倉庫
    iv_left_base          IN  VARCHAR2,    -- 預け先
    ov_errbuf             OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- A-1-1.共通関数(業務処理日付取得)より業務日付を取得します。
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_business_date IS NULL) THEN
      -- 業務日付の取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00011
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-3.パラメータの名称を以下のように取得します。
    -- 出力区分名称(倉庫/預け先)
    gv_out_kbn := xxcoi_common_pkg.get_meaning(cv_output_div,iv_output_kbn);
    --
    IF (gv_out_kbn IS NULL) THEN
      -- パラメータ.出力区分名取得エラーメッセージ(APP-XXCOI1-10113)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10113
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- 棚卸区分名称(日次/月中/月末)
    gv_inv_kbn := xxcoi_common_pkg.get_meaning(cv_inv_div,iv_inventory_kbn);
    --
    IF (gv_inv_kbn IS NULL) THEN
      -- パラメータ.棚卸区分名取得エラーメッセージ(APP-XXCOI1-10264)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10264
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- 出力区分は倉庫の場合、月末対象外になり
    IF (iv_output_kbn = cv_out_kbn1 AND iv_inventory_kbn = cv_inv_kbn3) THEN
      -- 出力区分チェックエラーメッセージ(APP-XXCOI1-10314)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10314
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-2-2.棚卸月チェック
    IF (iv_inventory_kbn = cv_inv_kbn3) THEN
      -- NULLチェック
      IF (iv_inventory_month IS NULL) THEN
        -- 棚卸月Nullチェックエラーメッセージ(APP-XXCOI1-10103)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10103
                     ,iv_token_name1  => cv_p_token2   -- 棚卸区分
                     ,iv_token_value1 => gv_inv_kbn
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- 型チェック
      IF (LENGTH(iv_inventory_month) <> 6) THEN
        -- 棚卸月の型(YYYYMM)チェックエラーメッセージ(APP-XXCOI1-10105)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10105
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      BEGIN
        gd_inventory_month := TO_DATE(iv_inventory_month,'YYYYMM');
        gv_inventory_month := TO_CHAR(gd_inventory_month,'YYYYMM');
      EXCEPTION
        WHEN OTHERS THEN
          -- 棚卸月の型(YYYYMM)チェックエラーメッセージ(APP-XXCOI1-10105)
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10105
                       );
          lv_errbuf := lv_errmsg;
          lv_retcode := cv_status_error;    -- 異常:2
          gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END;
      -- 未来日チェック
      IF (TO_CHAR(gd_inventory_month,'YYYYMM') > TO_CHAR(gd_business_date,'YYYYMM')) THEN
        -- 棚卸月未来日チェックエラーメッセージ(APP-XXCOI1-10198)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10198
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- 対象日設定
      gd_target_date := LAST_DAY(gd_inventory_month);   -- 年月の末日
    -- A-2-1.棚卸日チェック
    ELSE
      -- NULLチェック
      IF (iv_inventory_date IS NULL) THEN
        -- 棚卸日Nullチェックエラーメッセージ(APP-XXCOI1-10102)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10102
                     ,iv_token_name1  => cv_p_token2   -- 棚卸区分
                     ,iv_token_value1 => gv_inv_kbn
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- 型チェック
      IF (LENGTH(iv_inventory_date) <> 8) THEN
        -- 棚卸日の型(YYYYMMDD)チェックエラーメッセージ(APP-XXCOI1-10104)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10104
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      BEGIN
        gd_inventory_date := TO_DATE(iv_inventory_date,'YYYYMMDD');
        gv_inventory_date := TO_CHAR(gd_inventory_date,'YYYYMMDD');
      EXCEPTION
        WHEN OTHERS THEN
          -- 棚卸日の型(YYYYMMDD)チェックエラーメッセージ(APP-XXCOI1-10104)
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10104
                       );
          lv_errbuf := lv_errmsg;
          lv_retcode := cv_status_error;    -- 異常:2
          gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END;
      -- 未来日チェック
      IF (gd_inventory_date > gd_business_date) THEN
        -- 棚卸日未来日チェックエラーメッセージ(APP-XXCOI1-10197)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10197
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- 異常:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- 対象日設定
      gd_target_date := gd_inventory_date;
    END IF;
    -- A-1-4.ログインユーザ拠点コードを取得します。
    gv_user_base := xxcoi_common_pkg.get_base_code(cn_created_by,cd_creation_date);
    --
    IF (gv_user_base IS NULL) THEN
      -- ログインユーザ拠点コード抽出エラーメッセージ(APP-XXCOI1-10116)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10116
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-5.コンカレント入力パラメータをログに出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_sn
                    ,iv_name         => cv_msg_10094
                    ,iv_token_name1  => cv_p_token1   -- 出力区分
                    ,iv_token_value1 => gv_out_kbn
                    ,iv_token_name2  => cv_p_token2   -- 棚卸区分
                    ,iv_token_value2 => gv_inv_kbn
                    ,iv_token_name3  => cv_p_token3   -- 棚卸日
                    ,iv_token_value3 => gv_inventory_date
                    ,iv_token_name4  => cv_p_token4   -- 棚卸月
                    ,iv_token_value4 => gv_inventory_month
                    ,iv_token_name5  => cv_p_token5   -- 拠点
                    ,iv_token_value5 => iv_base_code
                    ,iv_token_name6  => cv_p_token6   -- 倉庫
                    ,iv_token_value6 => iv_warehouse
                    ,iv_token_name7  => cv_p_token7   -- 預け先
                    ,iv_token_value7 => iv_left_base
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 共通関数(在庫組織コード取得)を使用しプロファイルより在庫組織コードを取得します。
    gv_organization_code := FND_PROFILE.VALUE(cv_org_code_p);
    --
    IF (gv_organization_code IS NULL) THEN
      -- プロファイル:在庫組織コード( &PRO_TOK )の取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00005
                   ,iv_token_name1  => cv_protok_sn
                   ,iv_token_value1 => cv_org_code_p
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- 上記で取得した在庫組織コードをもとに共通部品(在庫組織ID取得)より在庫組織ID取得します。
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
    --
    IF (gn_organization_id IS NULL) THEN
      -- 在庫組織コード( &ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00006
                   ,iv_token_name1  => cv_orgcode_sn
                   ,iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-2-3.拠点チェック(管理課以外必須)
    SELECT management_base_flag                 -- 管理元拠点フラグ
    INTO   gv_focus_base_flag
    FROM   xxcoi_user_base_info_v               -- 拠点ビュー
    WHERE  account_number = gv_user_base
    AND    ROWNUM = 1;
    --
    IF (gv_focus_base_flag <> '1' AND iv_base_code IS NULL) THEN
      -- 拠点コードNullチェックエラーメッセージ(APP-XXCOI1-10115)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10115
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- 異常:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_kbn         IN  VARCHAR2,     -- 出力区分
    iv_inventory_kbn      IN  VARCHAR2,     -- 棚卸区分
    iv_inventory_date     IN  VARCHAR2,     -- 棚卸日
    iv_inventory_month    IN  VARCHAR2,     -- 棚卸月
    iv_base_code          IN  VARCHAR2,     -- 拠点
    iv_warehouse          IN  VARCHAR2,     -- 倉庫
    iv_left_base          IN  VARCHAR2,     -- 預け先
    ov_errbuf             OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_inv_name          VARCHAR2(200) := NULL;   -- 棚卸場所名
    lv_base_code         VARCHAR2(200) := NULL;   -- 拠点コード
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(init)
    -- ===============================
    init(
      iv_output_kbn      => iv_output_kbn         -- 出力区分
     ,iv_inventory_kbn   => iv_inventory_kbn      -- 棚卸区分
     ,iv_inventory_date  => iv_inventory_date     -- 棚卸日
     ,iv_inventory_month => iv_inventory_month    -- 棚卸月
     ,iv_base_code       => iv_base_code          -- 拠点
     ,iv_warehouse       => iv_warehouse          -- 倉庫
     ,iv_left_base       => iv_left_base          -- 預け先
     ,ov_errbuf          => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- データ取得(A-2)
    -- ===============================
    IF (iv_inventory_kbn = cv_inv_kbn1) THEN
      -- 日次データ取得
      get_daily_data(
        iv_output_kbn      => iv_output_kbn         -- 出力区分
       ,iv_inventory_kbn   => iv_inventory_kbn      -- 棚卸区分
       ,iv_inventory_date  => iv_inventory_date     -- 棚卸日
       ,iv_inventory_month => iv_inventory_month    -- 棚卸月
       ,iv_base_code       => iv_base_code          -- 拠点
       ,iv_warehouse       => iv_warehouse          -- 倉庫
       ,iv_left_base       => iv_left_base          -- 預け先
       ,ov_errbuf          => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
    ELSE
      -- 月次データ取得
      get_month_data(
        iv_output_kbn      => iv_output_kbn         -- 出力区分
       ,iv_inventory_kbn   => iv_inventory_kbn      -- 棚卸区分
       ,iv_inventory_date  => iv_inventory_date     -- 棚卸日
       ,iv_inventory_month => iv_inventory_month    -- 棚卸月
       ,iv_base_code       => iv_base_code          -- 拠点
       ,iv_warehouse       => iv_warehouse          -- 倉庫
       ,iv_left_base       => iv_left_base          -- 預け先
       ,ov_errbuf          => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      ov_retcode := lv_retcode;
    END IF;
    -- ===============================
    -- SVF起動処理を呼出し(final_svf)
    -- ===============================
    final_svf(
        ov_errbuf  => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode                  -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    errbuf             OUT VARCHAR2,     -- エラーメッセージ #固定#
    retcode            OUT VARCHAR2,     -- エラーコード     #固定#
    iv_output_kbn      IN  VARCHAR2,     -- 出力区分
    iv_inventory_kbn   IN  VARCHAR2,     -- 棚卸区分
    iv_inventory_date  IN  VARCHAR2,     -- 棚卸日
    iv_inventory_month IN  VARCHAR2,     -- 棚卸月
    iv_base_code       IN  VARCHAR2,     -- 拠点
    iv_warehouse       IN  VARCHAR2,     -- 倉庫
    iv_left_base       IN  VARCHAR2      -- 預け先
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
    cv_log_name        CONSTANT VARCHAR2(100) := 'LOG';               -- ヘッダメッセージ出力関数パラメータ
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);     -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);        -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);     -- ユーザー・エラー・メッセージ
    lv_message_code           VARCHAR2(100);
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_name
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
       iv_output_kbn      => iv_output_kbn        -- 出力区分
      ,iv_inventory_kbn   => iv_inventory_kbn     -- 棚卸区分
      ,iv_inventory_date  => iv_inventory_date    -- 棚卸日
      ,iv_inventory_month => iv_inventory_month   -- 棚卸月
      ,iv_base_code       => iv_base_code         -- 拠点
      ,iv_warehouse       => iv_warehouse         -- 倉庫
      ,iv_left_base       => iv_left_base         -- 預け先
      ,ov_errbuf          => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
END XXCOI006A15R;
/
