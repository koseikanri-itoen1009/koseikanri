CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A03C (body)
 * Description      : 未発注リスト作成
 * MD.050           : 未発注リスト作成 (MD050_CSO_011A03)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             未発注情報取得(A-2)、CSVファイル出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/05/15    1.0   S.Niki           main新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  init_err_expt               EXCEPTION;      -- 初期処理エラー
  no_data_warn_expt           EXCEPTION;      -- 対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO011A03C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- 日付書式
  cv_format_std               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  -- 括り文字
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- 文字列括り
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  -- メッセージコード
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- 業務処理日付取得エラー
  cv_msg_cso_00014            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00014';          -- プロファイル取得エラー
  cv_msg_cso_00644            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00644';          -- 抽出対象期間大小チェックエラーメッセージ
  cv_msg_cso_00664            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00664';          -- メッセージ用文字列(発注作成部署)
  cv_msg_cso_00665            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00665';          -- メッセージ用文字列(発注作成者)
  cv_msg_cso_00666            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00666';          -- メッセージ用文字列(仕入先)
  cv_msg_cso_00667            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00667';          -- メッセージ用文字列(発注番号)
  cv_msg_cso_00668            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00668';          -- メッセージ用文字列(発注作成日FROM)
  cv_msg_cso_00669            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00669';          -- メッセージ用文字列(発注作成日TO)
  cv_msg_cso_00670            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00670';          -- メッセージ用文字列(リース区分)
  cv_msg_cso_00671            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00671';          -- 入力パラメータ用文字列
  cv_msg_cso_00672            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00672';          -- 未発注リストヘッダノート
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- 入力パラメータ名
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- 入力パラメータ値
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';                 -- プロファイル名
  cv_tkn_date_from            CONSTANT VARCHAR2(20)  := 'DATE_FROM';                 -- 抽出対象日(FROM)
  cv_tkn_date_to              CONSTANT VARCHAR2(20)  := 'DATE_TO';                   -- 抽出対象日(TO)
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
  -- プロファイル名
  cv_prof_org_id              CONSTANT VARCHAR2(30)  := 'ORG_ID';                    -- MO: 営業単位
  -- 参照タイプ名
  cv_lkup_lease_kbn           CONSTANT VARCHAR2(30)  := 'XXCSO1_LEASE_KBN';          -- リース区分
  -- 値セット名
  cv_flex_dclr_place          CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';          -- 申告地
  -- 情報テンプレート属性名
  cv_attr_inst_cust_nm        CONSTANT VARCHAR2(30)  := 'INSTALL_AT_CUSTOMER_NAME';  -- 設置先顧客名
  cv_attr_lease_type          CONSTANT VARCHAR2(30)  := 'LEASE_TYPE';                -- リース区分
  cv_attr_dclr_place          CONSTANT VARCHAR2(30)  := 'DECLARATION_PLACE';         -- 申告地
  cv_attr_inst_cust_cd        CONSTANT VARCHAR2(30)  := 'INSTALL_AT_CUSTOMER_CODE';  -- 設置先顧客
  -- フラグ
  cv_dummy                    CONSTANT VARCHAR2(2)   := 'XX';                        -- ダミー値
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- 有効
  cv_flag_a                   CONSTANT VARCHAR2(1)   := 'A';                         -- 有効
  cv_interface_no             CONSTANT VARCHAR2(1)   := 'N';                         -- 未連携
  cv_language_ja              CONSTANT VARCHAR2(2)   := 'JA';                        -- 日本語
  cv_aprv_status              CONSTANT VARCHAR2(8)   := 'APPROVED';                  -- 承認済
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;  -- 発注作成部署
  gt_created_by               per_all_people_f.employee_number%TYPE;    -- 発注作成者
  gt_vendor_code              po_vendors.segment1%TYPE;                 -- 仕入先
  gt_po_num                   po_headers_all.segment1%TYPE;             -- 発注番号
  gd_date_from                DATE;                                     -- 発注作成日FROM
  gd_date_to                  DATE;                                     -- 発注作成日TO
  gv_lease_kbn                VARCHAR2(1);                              -- リース区分
  gn_org_id                   NUMBER;                                   -- 営業組織ID
  gd_process_date             DATE;                                     -- 業務日付
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 未発注情報取得カーソル
  CURSOR get_po_info_cur
  IS
    SELECT  po_info.po_num               AS po_num              -- 発注番号
           ,po_info.po_line_num          AS po_line_num         -- 発注明細番号
           ,po_info.pr_num               AS pr_num              -- 購買依頼番号
           ,po_info.pr_line_num          AS pr_line_num         -- 購買依頼明細番号
           ,po_info.un_num               AS un_num              -- 機種コード
           ,po_info.un_lease_kbn         AS un_lease_kbn        -- 機種リース区分
           ,po_info.un_lease_kbn_name    AS un_lease_kbn_name   -- 機種リース区分名称
           ,po_info.un_get_price         AS un_get_price        -- 機種取得価格
           ,po_info.customer_code        AS customer_code       -- 顧客コード
           ,po_info.customer_name        AS customer_name       -- 顧客名
           ,po_info.address              AS address             -- 市区町村
           ,po_info.lease_kbn            AS lease_kbn           -- リース区分
           ,po_info.get_price            AS get_price           -- 取得価格
           ,po_info.dclr_place           AS dclr_place          -- 申告地
    FROM   (SELECT ph.segment1                       AS po_num             -- 発注番号
                  ,pl.line_num                       AS po_line_num        -- 発注明細番号
                  ,prh.segment1                      AS pr_num             -- 購買依頼番号
                  ,prl.line_num                      AS pr_line_num        -- 購買依頼明細番号
                  ,pun.un_number                     AS un_num             -- 機種コード
                  ,pun.attribute13                   AS un_lease_kbn       -- 機種リース区分
                  ,( SELECT flvv.meaning AS un_lease_kbn_name
                     FROM   fnd_lookup_values_vl flvv
                     WHERE  flvv.lookup_type  = cv_lkup_lease_kbn  -- リース区分
                     AND    flvv.enabled_flag = cv_flag_y
                     AND    gd_process_date  >= NVL(flvv.start_date_active, gd_process_date)
                     AND    gd_process_date  <= NVL(flvv.end_date_active  , gd_process_date)
                     AND    flvv.lookup_code  = pun.attribute13
                   )                                 AS un_lease_kbn_name  -- 機種リース区分名称
                  ,pun.attribute14                   AS un_get_price       -- 機種取得価格
                  ,hca.account_number                AS customer_code      -- 顧客コード
                  ,xxcso_ipro_common_pkg.get_temp_info(
                     prl.requisition_line_id
                   , cv_attr_inst_cust_nm )  -- 情報テンプレート：設置先顧客名
                                                     AS customer_name      -- 顧客名
                  ,hl.state || hl.city               AS address            -- 市区町村
                  ,NVL(
                     NVL( pd.attribute1
                         ,NVL( pun.attribute13
                              ,( SELECT flvv.lookup_code AS lease_kbn
                                 FROM   apps.fnd_lookup_values_vl flvv
                                 WHERE  flvv.lookup_type  = cv_lkup_lease_kbn  -- リース区分
                                 AND    flvv.enabled_flag = cv_flag_y
                                 AND    gd_process_date  >= NVL(flvv.start_date_active, gd_process_date)
                                 AND    gd_process_date  <= NVL(flvv.end_date_active  , gd_process_date)
                                 AND    flvv.attribute1   = xxcso_ipro_common_pkg.get_temp_info(
                                                              prl.requisition_line_id
                                                            , cv_attr_lease_type )  -- 情報テンプレート：リース区分
                                 AND    ROWNUM            = 1
                               )
                          )
                     )
                     ,cv_dummy
                   )                                 AS lease_kbn          -- リース区分
                  ,NVL( pd.attribute2
                      , pun.attribute14
                   )                                 AS get_price          -- 取得価格
                  ,NVL( pd.attribute3
                       ,( xxcso_ipro_common_pkg.get_temp_info(
                            prl.requisition_line_id
                          , cv_attr_dclr_place ) )  -- 情報テンプレート：申告地
                   )                                 AS dclr_place         -- 申告地
                  ,papf.attribute28                  AS base_code          -- 発注作成部署
                  ,papf.person_id                    AS created_by         -- 発注作成者
                  ,TRUNC(ph.creation_date)           AS creation_date      -- 発注作成日
                  ,pv.segment1                       AS vendor_code        -- 仕入先
            FROM   po_headers_all             ph    -- 発注ヘッダ
                  ,po_lines_all               pl    -- 発注明細
                  ,po_distributions_all       pd    -- 発注搬送
                  ,po_requisition_headers_all prh   -- 購買依頼ヘッダ
                  ,po_requisition_lines_all   prl   -- 購買依頼明細
                  ,po_req_distributions_all   prd   -- 購買依頼搬送
                  ,po_un_numbers_vl           pun   -- 機器マスタ
                  ,xxcso_wk_requisition_proc  xwrp  -- 作業依頼／発注情報連携対象テーブル
                  ,hz_cust_accounts           hca   -- 顧客マスタ
                  ,hz_parties                 hp    -- パーティマスタ
                  ,hz_cust_acct_sites_all     hcas  -- 顧客サイト
                  ,hz_party_sites             hps   -- パーティサイドマスタ
                  ,hz_locations               hl    -- 顧客事業所マスタ
                  ,per_all_people_f           papf  -- 従業員マスタ
                  ,po_vendors                 pv    -- 仕入先マスタ
            WHERE ph.po_header_id              = pl.po_header_id
            AND   ph.po_header_id              = pd.po_header_id
            AND   pl.po_line_id                = pd.po_line_id
            AND   pd.req_distribution_id       = prd.distribution_id
            AND   prd.requisition_line_id      = prl.requisition_line_id
            AND   prl.requisition_header_id    = prh.requisition_header_id
            AND   pl.un_number_id              = pun.un_number_id
            AND   prl.requisition_line_id      = xwrp.requisition_line_id
            AND   xwrp.interface_flag          = cv_interface_no -- 自販機システム未連携
            AND   hca.account_number           = xxcso_ipro_common_pkg.get_temp_info(
                                                   prl.requisition_line_id
                                                 , cv_attr_inst_cust_cd ) -- 情報テンプレート：設置先顧客
            AND   hca.party_id                 = hp.party_id
            AND   hca.cust_account_id          = hcas.cust_account_id
            AND   hcas.org_id                  = gn_org_id -- 営業組織ID
            AND   hcas.party_site_id           = hps.party_site_id
            AND   hcas.status                  = cv_flag_a -- 有効
            AND   hps.status                   = cv_flag_a -- 有効
            AND   hps.location_id              = hl.location_id
            AND   ph.agent_id                  = papf.person_id
            AND   gd_process_date             >= papf.effective_start_date
            AND   gd_process_date             <= papf.effective_end_date
            AND   ph.vendor_id                 = pv.vendor_id
            AND  (ph.authorization_status IS NULL
             OR   ph.authorization_status      <> cv_aprv_status
                 )                                    -- 承認済以外
            ) po_info
    WHERE po_info.base_code        = gt_base_code                               -- 1.発注作成部署
    AND   po_info.created_by       = NVL(gt_created_by  ,po_info.created_by)    -- 2.発注作成者
    AND   po_info.vendor_code      = NVL(gt_vendor_code ,po_info.vendor_code)   -- 3.仕入先
    AND   po_info.po_num           = NVL(gt_po_num      ,po_info.po_num)        -- 4.発注番号
    AND   po_info.creation_date   >= NVL(gd_date_from   ,po_info.creation_date) -- 5.発注作成日FROM
    AND   po_info.creation_date   <= NVL(gd_date_to     ,po_info.creation_date) -- 6.発注作成日TO
    AND   po_info.lease_kbn        = NVL(gv_lease_kbn   ,po_info.lease_kbn)     -- 7.リース区分
    ORDER BY po_info.po_num         -- 発注番号
            ,po_info.po_line_num    -- 発注明細番号
            ,po_info.pr_num         -- 購買依頼番号
            ,po_info.pr_line_num    -- 購買依頼明細番号
    ;
    -- 未発注情報カーソルレコード型
    get_po_info_rec get_po_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code    IN  VARCHAR2      -- 1.発注作成部署
   ,iv_created_by   IN  VARCHAR2      -- 2.発注作成者
   ,iv_vendor_code  IN  VARCHAR2      -- 3.仕入先
   ,iv_po_num       IN  VARCHAR2      -- 4.発注番号
   ,iv_date_from    IN  VARCHAR2      -- 5.発注作成日FROM
   ,iv_date_to      IN  VARCHAR2      -- 6.発注作成日TO
   ,iv_lease_kbn    IN  VARCHAR2      -- 7.リース区分
   ,ov_errbuf       OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_param_name1     VARCHAR2(1000);  -- 入力パラメータ名1
    lv_param_name2     VARCHAR2(1000);  -- 入力パラメータ名2
    lv_param_name3     VARCHAR2(1000);  -- 入力パラメータ名3
    lv_param_name4     VARCHAR2(1000);  -- 入力パラメータ名4
    lv_param_name5     VARCHAR2(1000);  -- 入力パラメータ名5
    lv_param_name6     VARCHAR2(1000);  -- 入力パラメータ名6
    lv_param_name7     VARCHAR2(1000);  -- 入力パラメータ名7
    lv_base_code       VARCHAR2(1000);  -- 1.発注作成部署
    lv_created_by      VARCHAR2(1000);  -- 2.発注作成者
    lv_vendor_code     VARCHAR2(1000);  -- 3.仕入先
    lv_po_num          VARCHAR2(1000);  -- 4.発注番号
    lv_date_from       VARCHAR2(1000);  -- 5.発注作成日FROM
    lv_date_to         VARCHAR2(1000);  -- 6.発注作成日TO
    lv_lease_kbn       VARCHAR2(1000);  -- 7.リース区分
    lv_csv_header      VARCHAR2(5000);  -- CSVヘッダ項目出力用
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
    -- 0.入力パラメータ格納
    --==============================================================
    gt_base_code   := iv_base_code;                         -- 1.発注作成部署
    gt_created_by  := iv_created_by;                        -- 2.発注作成者
    gt_vendor_code := iv_vendor_code;                       -- 3.仕入先
    gt_po_num      := iv_po_num;                            -- 4.発注番号
    gd_date_from   := TO_DATE(iv_date_from ,cv_format_std); -- 5.発注作成日FROM
    gd_date_to     := TO_DATE(iv_date_to   ,cv_format_std); -- 6.発注作成日TO
    gv_lease_kbn   := iv_lease_kbn;                         -- 7.リース区分
--
    --==============================================================
    -- 1.入力パラメータ出力
    --==============================================================
    -- 1.発注作成部署
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00664              -- メッセージコード
                      );
    lv_base_code   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name1                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_base_code                  -- トークン値2
                      );
    -- 2.発注作成者
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00665              -- メッセージコード
                      );
    lv_created_by  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name2                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_created_by                 -- トークン値2
                      );
    -- 3.仕入先
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00666              -- メッセージコード
                      );
    lv_vendor_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name3                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_vendor_code                -- トークン値2
                      );
    -- 4.発注番号
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00667              -- メッセージコード
                      );
    lv_po_num      := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name4                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_po_num                     -- トークン値2
                      );
    -- 5.発注作成日FROM
    lv_param_name5 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00668              -- メッセージコード
                      );
    lv_date_from   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name5                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_date_from                  -- トークン値2
                      );
    -- 6.発注作成日TO
    lv_param_name6 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00669              -- メッセージコード
                      );
    lv_date_to     := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name6                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_date_to                    -- トークン値2
                      );
    -- 7.リース区分
    lv_param_name7 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00670              -- メッセージコード
                      );
    lv_lease_kbn   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => lv_param_name7                -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_lease_kbn                  -- トークン値2
                      );
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''             || CHR(10) ||
                 lv_base_code   || CHR(10) ||      -- 1.発注作成部署
                 lv_created_by  || CHR(10) ||      -- 2.発注作成者
                 lv_vendor_code || CHR(10) ||      -- 3.仕入先
                 lv_po_num      || CHR(10) ||      -- 4.発注番号
                 lv_date_from   || CHR(10) ||      -- 5.発注作成日FROM
                 lv_date_to     || CHR(10) ||      -- 6.発注作成日TO
                 lv_lease_kbn   || CHR(10)         -- 7.リース区分
    );
--
    --==================================================
    -- 2.プロファイル値取得
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    -- プロファイルの取得に失敗した場合はエラー
    IF( gn_org_id IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso      -- アプリケーション短縮名
         ,iv_name         => cv_msg_cso_00014        -- メッセージコード
         ,iv_token_name1  => cv_tkn_prof_name        -- トークンコード1
         ,iv_token_value1 => cv_prof_org_id          -- トークン値1
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.業務日付取得
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date ;
    -- 業務日付の取得に失敗した場合はエラー
    IF( gd_process_date IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
         ,iv_name         => cv_msg_cso_00011     -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 4.入力パラメータの妥当性チェック
    --==================================================
    -- 発注作成日FROM、TOがともに指定されていた場合にチェック
    IF ( gd_date_from IS NOT NULL )
      AND ( gd_date_to IS NOT NULL )
    THEN
      -- 発注作成日FROM＞TOの場合はエラー
      IF ( gd_date_from > gd_date_to )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso      -- アプリケーション短縮名
         ,iv_name         => cv_msg_cso_00644        -- メッセージコード
         ,iv_token_name1  => cv_tkn_date_from        -- トークンコード1
         ,iv_token_value1 => lv_param_name5          -- トークン値1
         ,iv_token_name2  => cv_tkn_date_to          -- トークンコード2
         ,iv_token_value2 => lv_param_name6          -- トークン値2
        );
        lv_errbuf  := lv_errmsg;
        RAISE init_err_expt;
      END IF;
    END IF;
--
    --==================================================
    -- 5.CSVヘッダ項目出力
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
                    ,iv_name         => cv_msg_cso_00672     -- メッセージコード
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : 未発注情報取得(A-2)、CSVファイル出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    lv_op_str            VARCHAR2(5000)  := NULL;   -- 出力文字列格納用変数
    lv_lease_kbn         VARCHAR2(1)     := NULL;   -- リース区分
    lv_lease_kbn_name    VARCHAR2(100)   := NULL;   -- リース区分名称
    lv_dclr_place_name   VARCHAR2(500)   := NULL;   -- 申告地名称
--
    -- ===============================
    -- ユーザー定義例外
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
    -- ===============================
    -- 未発注情報取得(A-2)
    -- ===============================
    << po_info_loop >>
    FOR get_po_info_rec IN get_po_info_cur
    LOOP
      -- ===============================
      -- CSVファイル出力(A-3)
      -- ===============================
      -- 対象件数
      gn_target_cnt := gn_target_cnt + 1;
      -- ===============================
      -- 1-(1).リース区分取得
      -- ===============================
      IF (get_po_info_rec.lease_kbn = cv_dummy)
      THEN
        lv_lease_kbn := NULL;
      ELSE
        lv_lease_kbn := get_po_info_rec.lease_kbn;
      END IF;
      -- ===============================
      -- 1-(2).リース区分名称取得
      -- ===============================
      IF (lv_lease_kbn IS NOT NULL)
      THEN
        BEGIN
          SELECT flvv.meaning AS lease_kbn_name
          INTO   lv_lease_kbn_name
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type  = cv_lkup_lease_kbn -- リース区分
          AND    flvv.enabled_flag = cv_flag_y
          AND    gd_process_date  >= NVL(flvv.start_date_active ,gd_process_date)
          AND    gd_process_date  <= NVL(flvv.end_date_active   ,gd_process_date)
          AND    flvv.lookup_code  = lv_lease_kbn -- 上記で設定したリース区分
          ;
        EXCEPTION
          --*** 対象レコードなしエラー ***
          WHEN NO_DATA_FOUND THEN
            lv_lease_kbn_name := NULL;
        END;
      END IF;
--
      -- ===============================
      -- 1-(3).申告地名称取得
      -- ===============================
      IF (get_po_info_rec.dclr_place IS NOT NULL)
      THEN
        BEGIN
          SELECT ffvt.description AS dclr_place_name
          INTO   lv_dclr_place_name
          FROM   fnd_flex_values      ffv
               , fnd_flex_values_tl   ffvt
               , fnd_flex_value_sets  ffvs
          WHERE  ffv.flex_value_id        = ffvt.flex_value_id
          AND    ffvt.language            = cv_language_ja
          AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
          AND    ffvs.flex_value_set_name = cv_flex_dclr_place  -- 申告地
          AND    ffv.enabled_flag         = cv_flag_y
          AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
          AND    gd_process_date         <= NVL(ffv.end_date_active   ,gd_process_date)
          AND    ffv.flex_value           = get_po_info_rec.dclr_place
          ;
        EXCEPTION
          --*** 対象レコードなしエラー ***
          WHEN NO_DATA_FOUND THEN
            lv_dclr_place_name := NULL;
        END;
      END IF;
--
      --出力文字列作成
      lv_op_str :=                          cv_dqu || get_po_info_rec.po_num            || cv_dqu ;   -- 発注番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.po_line_num       || cv_dqu ;   -- 発注明細番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.pr_num            || cv_dqu ;   -- 購買依頼番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.pr_line_num       || cv_dqu ;   -- 購買依頼明細番号
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_num            || cv_dqu ;   -- 機種コード
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_lease_kbn      || cv_dqu ;   -- 機種リース区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_lease_kbn_name || cv_dqu ;   -- 機種リース区分名称
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_get_price      || cv_dqu ;   -- 機種取得価格
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.customer_code     || cv_dqu ;   -- 顧客コード
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.customer_name     || cv_dqu ;   -- 顧客名
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.address           || cv_dqu ;   -- 市区町村
      lv_op_str := lv_op_str || cv_comma || cv_dqu || lv_lease_kbn                      || cv_dqu ;   -- リース区分
      lv_op_str := lv_op_str || cv_comma || cv_dqu || lv_lease_kbn_name                 || cv_dqu ;   -- リース区分名称
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.get_price         || cv_dqu ;   -- 取得価格
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.dclr_place        || cv_dqu ;   -- 申告地
      lv_op_str := lv_op_str || cv_comma || cv_dqu || lv_dclr_place_name                || cv_dqu ;   -- 申告地名称
--
      -- ===============================
      -- 2.CSVファイル出力
      -- ===============================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
      -- 変数初期化
      lv_lease_kbn       := NULL;
      lv_lease_kbn_name  := NULL;
      lv_dclr_place_name := NULL;
--
    END LOOP po_info_loop;
--
    -- 対象データなし警告
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2     -- 1.発注作成部署
   ,iv_created_by      IN  VARCHAR2     -- 2.発注作成者
   ,iv_vendor_code     IN  VARCHAR2     -- 3.仕入先
   ,iv_po_num          IN  VARCHAR2     -- 4.発注番号
   ,iv_date_from       IN  VARCHAR2     -- 5.発注作成日FROM
   ,iv_date_to         IN  VARCHAR2     -- 6.発注作成日TO
   ,iv_lease_kbn       IN  VARCHAR2     -- 7.リース区分
   ,ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_base_code       => iv_base_code     -- 1.発注作成部署
     ,iv_created_by      => iv_created_by    -- 2.発注作成者
     ,iv_vendor_code     => iv_vendor_code   -- 3.仕入先
     ,iv_po_num          => iv_po_num        -- 4.発注番号
     ,iv_date_from       => iv_date_from     -- 5.発注作成日FROM
     ,iv_date_to         => iv_date_to       -- 6.発注作成日TO
     ,iv_lease_kbn       => iv_lease_kbn     -- 7.リース区分
     ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未発注情報取得(A-2)、CSVファイル出力(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE no_data_warn_expt;
    END IF;
--
  EXCEPTION
    -- 対象データなし警告
    WHEN no_data_warn_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := ov_errmsg;
      ov_retcode := lv_retcode;
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
    errbuf             OUT VARCHAR2     -- エラー・メッセージ  --# 固定 #
   ,retcode            OUT VARCHAR2     -- リターン・コード    --# 固定 #
   ,iv_base_code       IN  VARCHAR2     -- 1.発注作成部署
   ,iv_created_by      IN  VARCHAR2     -- 2.発注作成者
   ,iv_vendor_code     IN  VARCHAR2     -- 3.仕入先
   ,iv_po_num          IN  VARCHAR2     -- 4.発注番号
   ,iv_date_from       IN  VARCHAR2     -- 5.発注作成日FROM
   ,iv_date_to         IN  VARCHAR2     -- 6.発注作成日TO
   ,iv_lease_kbn       IN  VARCHAR2     -- 7.リース区分
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_base_code    => iv_base_code     -- 1.発注作成部署
      ,iv_created_by   => iv_created_by    -- 2.発注作成者
      ,iv_vendor_code  => iv_vendor_code   -- 3.仕入先
      ,iv_po_num       => iv_po_num        -- 4.発注番号
      ,iv_date_from    => iv_date_from     -- 5.発注作成日FROM
      ,iv_date_to      => iv_date_to       -- 6.発注作成日TO
      ,iv_lease_kbn    => iv_lease_kbn     -- 7.リース区分
      ,ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error)
    THEN
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
END XXCSO011A03C;
/
