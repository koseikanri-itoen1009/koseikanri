CREATE OR REPLACE PACKAGE BODY XXCOI006A19R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A19R(body)
 * Description      : 払出明細表（拠点別計）
 * MD.050           : 払出明細表（拠点別計） <MD050_XXCOI_006_A19>
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_svf_data           ワークテーブルデータ削除             (A-6)
 *  call_output_svf        SVF起動                              (A-5)
 *  ins_svf_data           ワークテーブルデータ登録             (A-4)
 *  valid_param_value      パラメータチェック                   (A-2)
 *  init                   初期処理                             (A-1)
 *  submain                メイン処理プロシージャ
 *                         データ取得                           (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.0   H.Sasaki         初版作成
 *  2009/02/19    1.1   H.Sasaki         [障害COI_022]顧客マスタのステータスを検索条件に追加
 *                                                    月次在庫の検索条件に棚卸ステータスを追加
 *  2009/06/26    1.2   H.Sasaki         [0000258]数量計算に棚卸減耗数を加算しない
 *                                                払出合計に基準在庫変更入庫を追加
 *  2009/07/21    1.3   H.Sasaki         [0000807]VD出庫数量より、基準在庫変更入庫数量を減算
 *  2015/03/16    1.4   K.Nakamura       [E_本稼動_12906]在庫確定文字の追加
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI006A19R'; -- パッケージ名
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
-- == 2015/03/16 V1.4 Added START =================================================================
  cv_msg_xxcoi1_00005       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00005';       -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00006';       -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00026       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00026';       -- 在庫会計期間ステータス取得エラーメッセージ
  cv_msg_xxcoi1_10451       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10451';       -- 在庫確定印字文字取得エラーメッセージ
-- == 2015/03/16 V1.4 Added END   =================================================================
  cv_token_10107_1          CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';      -- APP-XXCOI1-10107用トークン
  cv_token_10108_1          CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';            -- APP-XXCOI1-10108用トークン
-- == 2015/03/16 V1.4 Added START =================================================================
  cv_token_protok           CONSTANT VARCHAR2(30) :=  'PRO_TOK';                -- プロファイル名
  cv_token_orgcode          CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';           -- 在庫組織コード
  cv_token_target           CONSTANT VARCHAR2(30) :=  'TARGET_DATE';            -- 対象日
-- == 2015/03/16 V1.4 Added END   =================================================================
  -- 棚卸区分（1:月中  2:月末）
  cv_inv_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  -- 顧客
  cv_cust_cls_1             CONSTANT VARCHAR2(1)  :=  '1';                      -- 顧客区分（1:拠点）
  cv_status_active          CONSTANT VARCHAR2(1)  :=  'A';                      -- ステータス：Active
  -- 日付型
  cv_type_month             CONSTANT VARCHAR2(6)  :=  'YYYYMM';                 -- DATE型 年月（YYYYMM）
  cv_type_date              CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';               -- DATE型 年月日（YYYYMMDD）
-- == 2015/03/16 V1.4 Added START =================================================================
  cv_format_yyyymmdd        CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD';             -- DATE型 年月日（YYYY/MM/DD）
  -- プロファイル
  cv_prf_name_org_code      CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE'; -- プロファイル名（在庫組織コード）
  cv_prf_name_inv_cl_char   CONSTANT VARCHAR2(30) :=  'XXCOI1_INV_CL_CHARACTER';  -- プロファイル名（在庫確定印字文字）
-- == 2015/03/16 V1.4 Added END   =================================================================
  -- LOOKUP_TYPE
  cv_xxcoi_cost_price_div   CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';  -- LOOKUP_TYPE（原価区分）
  -- その他
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                    -- コンカレントヘッダ出力先
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                      -- 半角スペース
  -- SVF起動関数パラメータ用
  cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A19R';           -- コンカレント名
  cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                   -- 拡張子（PDF）
  cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A19R';           -- 帳票ID
  cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                      -- 出力区分
  cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A19S.xml';       -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A19S.vrq';       -- クエリー様式ファイル名
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
-- == 2015/03/16 V1.4 Added START =================================================================
  gt_organization_id        mtl_parameters.organization_id%TYPE                 DEFAULT NULL; -- 在庫組織ID
  gt_inv_cl_char            fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 在庫確定印字文字
-- == 2015/03/16 V1.4 Added END   =================================================================
--
  -- ===============================
  -- ユーザー定義カーソル
  -- ===============================
  CURSOR  svf_data_cur
  IS
    SELECT  xirm.base_code                      base_code                 -- 拠点コード
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- 拠点名称
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
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--           ,xirm.wear_increase                  wear_increase             -- 棚卸減耗減
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
    FROM    xxcoi_inv_reception_monthly         xirm                      -- 月次在庫受払表（月次）
           ,hz_cust_accounts                    hca                       -- 顧客マスタ
    WHERE   xirm.practice_month     =   gv_param_reception_date
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1
    AND     hca.status              =   cv_status_active
    ORDER BY  xirm.base_code;
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
    DELETE  FROM xxcoi_rep_base_expend
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
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_type_date) || TO_CHAR(cn_request_id) || cv_type_pdf       -- 出力ファイル名
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
    ov_errbuf     OUT VARCHAR2,               --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,               --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)               --   ユーザー・エラー・メッセージ        --# 固定 #
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
    lv_base_code              VARCHAR2(4);    -- 拠点コード
    lv_base_name              VARCHAR2(8);    -- 拠点名称
    ln_sales_ship_qty         NUMBER;         -- 売上出庫数量
    ln_sales_ship_money       NUMBER;         -- 売上出庫金額
    ln_vd_ship_qty            NUMBER;         -- VD出庫数量
    ln_vd_ship_money          NUMBER;         -- VD出庫金額
    ln_support_qty            NUMBER;         -- 協賛見本数量
    ln_support_money          NUMBER;         -- 協賛見本金額
    ln_sample_qty             NUMBER;         -- 見本出庫数量
    ln_sample_money           NUMBER;         -- 見本出庫金額
    ln_disposal_qty           NUMBER;         -- 廃却出庫数量
    ln_disposal_money         NUMBER;         -- 廃却出庫金額
    ln_kuragae_ship_qty       NUMBER;         -- 倉替出庫数量
    ln_kuragae_ship_money     NUMBER;         -- 倉替出庫金額
    ln_hurikae_ship_qty       NUMBER;         -- 振替出庫数量
    ln_hurikae_ship_money     NUMBER;         -- 振替出庫金額
    ln_factry_change_qty      NUMBER;         -- 工場倉替数量
    ln_factry_change_money    NUMBER;         -- 工場倉替金額
    ln_factry_return_qty      NUMBER;         -- 工場返品数量
    ln_factry_return_money    NUMBER;         -- 工場返品金額
    ln_payment_total_qty      NUMBER;         -- 払出合計数量
    ln_payment_total_money    NUMBER;         -- 払出合計金額
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
      ln_sales_ship_qty         :=  NULL;     -- 07.売上出庫数量
      ln_sales_ship_money       :=  NULL;     -- 08.売上出庫金額
      ln_vd_ship_qty            :=  NULL;     -- 09.VD出庫数量
      ln_vd_ship_money          :=  NULL;     -- 10.VD出庫金額
      ln_support_qty            :=  NULL;     -- 11.協賛見本数量
      ln_support_money          :=  NULL;     -- 12.協賛見本金額
      ln_sample_qty             :=  NULL;     -- 13.見本出庫数量
      ln_sample_money           :=  NULL;     -- 14.見本出庫金額
      ln_disposal_qty           :=  NULL;     -- 15.廃却出庫数量
      ln_disposal_money         :=  NULL;     -- 16.廃却出庫金額
      ln_kuragae_ship_qty       :=  NULL;     -- 17.倉替出庫数量
      ln_kuragae_ship_money     :=  NULL;     -- 18.倉替出庫金額
      ln_hurikae_ship_qty       :=  NULL;     -- 19.振替出庫数量
      ln_hurikae_ship_money     :=  NULL;     -- 20.振替出庫金額
      ln_factry_change_qty      :=  NULL;     -- 21.工場倉替数量
      ln_factry_change_money    :=  NULL;     -- 22.工場倉替金額
      ln_factry_return_qty      :=  NULL;     -- 23.工場返品数量
      ln_factry_return_money    :=  NULL;     -- 24.工場返品金額
      ln_payment_total_qty      :=  NULL;     -- 25.払出合計数量
      ln_payment_total_money    :=  NULL;     -- 26.払出合計金額
      --
    ELSE
      lv_base_code              :=   ir_svf_data.base_code;                               -- 05.拠点コード
      lv_base_name              :=   ir_svf_data.account_name;                            -- 06.拠点名称
      ln_sales_ship_qty         :=   ir_svf_data.sales_shipped
                                   - ir_svf_data.sales_shipped_b
                                   - ir_svf_data.return_goods
                                   + ir_svf_data.return_goods_b;                          -- 07.売上出庫数量
      ln_sales_ship_money       :=  ROUND(ir_svf_data.cost_amt * ln_sales_ship_qty);      -- 08.売上出庫金額
-- == 2009/07/21 V1.3 Modified START ===============================================================
--      ln_vd_ship_qty            :=   ir_svf_data.inventory_change_out;
      ln_vd_ship_qty            :=   ir_svf_data.inventory_change_out
                                   - ir_svf_data.inventory_change_in;                     -- 09.VD出庫数量
-- == 2009/07/21 V1.3 Modified END   ===============================================================
      ln_vd_ship_money          :=  ROUND(ir_svf_data.cost_amt * ln_vd_ship_qty);         -- 10.VD出庫金額
      ln_support_qty            :=   ir_svf_data.customer_support_ss
                                   - ir_svf_data.customer_support_ss_b
                                   + ir_svf_data.ccm_sample_ship
                                   - ir_svf_data.ccm_sample_ship_b;                       -- 11.協賛見本数量
      ln_support_money          :=  ROUND(ir_svf_data.cost_amt * ln_support_qty);         -- 12.協賛見本金額
      ln_sample_qty             :=   ir_svf_data.customer_sample_ship
                                   - ir_svf_data.customer_sample_ship_b
                                   + ir_svf_data.sample_quantity
                                   - ir_svf_data.sample_quantity_b;                       -- 13.見本出庫数量
      ln_sample_money           :=  ROUND(ir_svf_data.cost_amt * ln_sample_qty);          -- 14.見本出庫金額
      ln_disposal_qty           :=   ir_svf_data.removed_goods
                                   - ir_svf_data.removed_goods_b;                         -- 15.廃却出庫数量
      ln_disposal_money         :=  ROUND(ir_svf_data.cost_amt * ln_disposal_qty);        -- 16.廃却出庫金額
-- == 2009/06/26 V1.2 Modified START ===============================================================
--      ln_kuragae_ship_qty       :=   ir_svf_data.change_ship + ir_svf_data.wear_increase; -- 17.倉替出庫数量
      ln_kuragae_ship_qty       :=   ir_svf_data.change_ship;                             -- 17.倉替出庫数量
-- == 2009/06/26 V1.2 Modified END ===============================================================
      ln_kuragae_ship_money     :=  ROUND(ir_svf_data.cost_amt * ln_kuragae_ship_qty);    -- 18.倉替出庫金額
      ln_hurikae_ship_qty       :=   ir_svf_data.goods_transfer_old;                      -- 19.振替出庫数量
      ln_hurikae_ship_money     :=  ROUND(ir_svf_data.cost_amt * ln_hurikae_ship_qty);    -- 20.振替出庫金額
      ln_factry_change_qty      :=   ir_svf_data.factory_change
                                   - ir_svf_data.factory_change_b;                        -- 21.工場倉替数量
      ln_factry_change_money    :=  ROUND(ir_svf_data.cost_amt * ln_factry_change_qty);   -- 22.工場倉替金額
      ln_factry_return_qty      :=   ir_svf_data.factory_return
                                   - ir_svf_data.factory_return_b;                        -- 23.工場返品数量
      ln_factry_return_money    :=  ROUND(ir_svf_data.cost_amt * ln_factry_return_qty);   -- 24.工場返品金額
      ln_payment_total_qty      :=   ir_svf_data.sales_shipped
                                   - ir_svf_data.sales_shipped_b
                                   - ir_svf_data.return_goods
                                   + ir_svf_data.return_goods_b
                                   + ir_svf_data.change_ship
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--                                   + ir_svf_data.wear_increase
-- == 2009/06/26 V1.2 Deleted START ===============================================================
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
                                   - ir_svf_data.removed_goods_b;                         -- 25.払出合計数量
      ln_payment_total_money    :=  ROUND(ir_svf_data.cost_amt * ln_payment_total_qty);   -- 26.払出合計金額
    END IF;
    --
    -- 挿入処理
    INSERT INTO xxcoi_rep_base_expend(
       slit_id                                  -- 01.払出残高情報ID
      ,in_out_year                              -- 02.年
      ,in_out_month                             -- 03.月
      ,cost_kbn                                 -- 04.原価区分
      ,base_code                                -- 05.拠点コード
      ,base_name                                -- 06.拠点名称
-- == 2015/03/16 V1.4 Added START =================================================================
      ,inv_cl_char                              -- 在庫確定印字文字
-- == 2015/03/16 V1.4 Added END   =================================================================
      ,sales_ship_qty                           -- 07.売上出庫数量
      ,sales_ship_money                         -- 08.売上出庫金額
      ,vd_ship_qty                              -- 09.VD出庫数量
      ,vd_ship_money                            -- 10.VD出庫金額
      ,support_qty                              -- 11.協賛見本数量
      ,support_money                            -- 12.協賛見本金額
      ,sample_qty                               -- 13.見本出庫数量
      ,sample_money                             -- 14.見本出庫金額
      ,disposal_qty                             -- 15.廃却出庫数量
      ,disposal_money                           -- 16.廃却出庫金額
      ,kuragae_ship_qty                         -- 17.倉替出庫数量
      ,kuragae_ship_money                       -- 18.倉替出庫金額
      ,hurikae_ship_qty                         -- 19.振替出庫数量
      ,hurikae_ship_money                       -- 20.振替出庫金額
      ,factry_change_qty                        -- 21.工場倉替数量
      ,factry_change_money                      -- 22.工場倉替金額
      ,factry_return_qty                        -- 23.工場返品数量
      ,factry_return_money                      -- 24.工場返品金額
      ,payment_total_qty                        -- 25.払出合計数量
      ,payment_total_money                      -- 26.払出合計金額
      ,message                                  -- 27.メッセージ
      ,created_by                               -- 28.作成者
      ,creation_date                            -- 29.作成日
      ,last_updated_by                          -- 30.最終更新者
      ,last_update_date                         -- 31.最終更新日
      ,last_update_login                        -- 32.最終更新ユーザ
      ,request_id                               -- 33.要求ID
      ,program_application_id                   -- 34.プログラムアプリケーションID
      ,program_id                               -- 35.プログラムID
      ,program_update_date                      -- 36.プログラム更新日
    )VALUES(
       in_slit_id                               -- 01
      ,SUBSTRB(gv_param_reception_date, 3, 2)   -- 02
      ,SUBSTRB(gv_param_reception_date, 5, 2)   -- 03
      ,gt_cost_type_name                        -- 04
      ,lv_base_code                             -- 05
      ,lv_base_name                             -- 06
-- == 2015/03/16 V1.4 Added START =================================================================
      ,gt_inv_cl_char                           -- 在庫確定印字文字
-- == 2015/03/16 V1.4 Added END   =================================================================
      ,ln_sales_ship_qty                        -- 07
      ,ln_sales_ship_money                      -- 08
      ,ln_vd_ship_qty                           -- 09
      ,ln_vd_ship_money                         -- 10
      ,ln_support_qty                           -- 11
      ,ln_support_money                         -- 12
      ,ln_sample_qty                            -- 13
      ,ln_sample_money                          -- 14
      ,ln_disposal_qty                          -- 15
      ,ln_disposal_money                        -- 16
      ,ln_kuragae_ship_qty                      -- 17
      ,ln_kuragae_ship_money                    -- 18
      ,ln_hurikae_ship_qty                      -- 19
      ,ln_hurikae_ship_money                    -- 20
      ,ln_factry_change_qty                     -- 21
      ,ln_factry_change_money                   -- 22
      ,ln_factry_return_qty                     -- 23
      ,ln_factry_return_money                   -- 24
      ,ln_payment_total_qty                     -- 25
      ,ln_payment_total_money                   -- 26
      ,iv_message                               -- 27
      ,cn_created_by                            -- 28
      ,SYSDATE                                  -- 29
      ,cn_last_updated_by                       -- 30
      ,SYSDATE                                  -- 31
      ,cn_last_update_login                     -- 32
      ,cn_request_id                            -- 33
      ,cn_program_application_id                -- 34
      ,cn_program_id                            -- 35
      ,SYSDATE                                  -- 36
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
-- == 2015/03/16 V1.4 Added START =================================================================
    lb_chk_result             BOOLEAN DEFAULT TRUE; -- 在庫会計期間チェック結果
-- == 2015/03/16 V1.4 Added END   =================================================================
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
    BEGIN
      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_type_month);
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
    IF (TO_CHAR(gd_f_process_date, 'YYYYMM') <= gv_param_reception_date) THEN
      -- 受払年月未来日チェックエラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10111
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
-- == 2015/03/16 V1.4 Added START =================================================================
    --====================================
    -- 在庫会計期間チェック
    --====================================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_organization_id
      , id_target_date     => LAST_DAY(ld_dummy)
      , ob_chk_result      => lb_chk_result
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                     , iv_name         => cv_msg_xxcoi1_00026
                     , iv_token_name1  => cv_token_target
                     , iv_token_value1 => TO_CHAR(LAST_DAY(ld_dummy), cv_format_yyyymmdd)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --====================================
    -- 帳票印字文字取得
    --====================================
    IF NOT(lb_chk_result) THEN
      gt_inv_cl_char := FND_PROFILE.VALUE(cv_prf_name_inv_cl_char);
      --
      IF ( gt_inv_cl_char IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                       , iv_name         => cv_msg_xxcoi1_10451
                       , iv_token_name1  => cv_token_protok
                       , iv_token_value1 => cv_prf_name_inv_cl_char
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
-- == 2015/03/16 V1.4 Added END   =================================================================
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
-- == 2015/03/16 V1.4 Added START =================================================================
    lt_organization_code      fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 在庫組織コード
-- == 2015/03/16 V1.4 Added END   =================================================================
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
    ov_retcode          :=  cv_status_normal;     -- 終了パラメータ
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
-- == 2015/03/16 V1.4 Added START =================================================================
    --====================================
    -- 在庫組織コード取得
    --====================================
    lt_organization_code := FND_PROFILE.VALUE(cv_prf_name_org_code);
    --
    IF ( lt_organization_code IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                     , iv_name         => cv_msg_xxcoi1_00005
                     , iv_token_name1  => cv_token_protok
                     , iv_token_value1 => cv_prf_name_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --====================================
    -- 在庫組織ID取得
    --====================================
    gt_organization_id := xxcoi_common_pkg.get_organization_id(lt_organization_code);
    --
    IF ( gt_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                     , iv_name         => cv_msg_xxcoi1_00006
                     , iv_token_name1  => cv_token_orgcode
                     , iv_token_value1 => lt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- == 2015/03/16 V1.4 Added END   =================================================================
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
    --
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
        ,buff => lv_errbuf --エラーメッセージ
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
END XXCOI006A19R;
/
