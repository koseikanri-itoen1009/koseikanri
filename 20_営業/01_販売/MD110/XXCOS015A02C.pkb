CREATE OR REPLACE PACKAGE BODY APPS.XXCOS015A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOS015A02C(body)
 * Description      : 情報系システム向け受注情報の作成を行う
 * MD.050           : 受注情報の情報系連携 MD050_COS_015_A02
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
 *  file_open                   ファイルオープン(A-2)
 *  open_order_info_cur         受注情報抽出(A-3)
 *  output_for_order            受注情報CSV作成(A-4)
 *  file_colse                  ファイルクローズ(A-5)
 *  expt_proc                   例外処理(A-6)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/06/22    1.0   N.Koyama         [E_本稼動_16429]新規作成
 *  2021/01/12    1.1   N.Koyama         [E_本稼動_16897]対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100)    := 'XXCOS015A02C';       -- パッケージ名
  cv_xxcos_short_name         CONSTANT VARCHAR2(10)     := 'XXCOS';              -- アプリケーション短縮名:XXCOS
  cv_xxccp_short_name         CONSTANT VARCHAR2(10)     := 'XXCCP';              -- アプリケーション短縮名:XXCCP
  cv_xxcoi_short_name         CONSTANT VARCHAR2(10)     := 'XXCOI';              -- アプリケーション短縮名:XXCOI
  -- メッセージ
  cv_msg_non_parameter        CONSTANT VARCHAR2(20)     := 'APP-XXCCP1-90008';    -- 入力項目なし
  cv_msg_notfound_data        CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00003';    -- 処理対象データなし
  cv_msg_notfound_profile     CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00004';    -- プロファイル取得エラー
  cv_msg_file_open_error      CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00009';    -- ファイルオープンエラー
  cv_msg_data_extra_error     CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00013';    -- データ抽出エラー
  cv_msg_non_business_date    CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00014';    -- 業務日付取得エラー
  cv_msg_file_name            CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00044';    -- ファイル名
  cv_msg_org_id               CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-00047';    -- 営業単位
  cv_msg_sales_line           CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-13303';    -- 販売実績
  cv_msg_count                CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-15301';    -- 件数メッセージ
  cv_msg_details              CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-13322';    -- メッセージ用文字列:「詳細」
  cv_msg_org_cd_err           CONSTANT VARCHAR2(20)     := 'APP-XXCOI1-00005';    -- 在庫組織コード取得エラーメッセージ
  cv_msg_org_id_err           CONSTANT VARCHAR2(20)     := 'APP-XXCOI1-00006';    -- 在庫組織ID取得エラーメッセージ
  cv_msg_period_err           CONSTANT VARCHAR2(20)     := 'APP-XXCOS1-15302';    -- AR会計期間オープン期間取得エラー
  -- メッセージトークン
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)     := 'PROFILE';             -- プロファイル名
  cv_tkn_pro_tok1             CONSTANT VARCHAR2(20)     := 'PRO_TOK';             -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20)     := 'TABLE';               -- テーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20)     := 'KEY_DATA';            -- キー項目
  cv_tkn_table_name           CONSTANT VARCHAR2(20)     := 'TABLE_NAME';          -- テーブル名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)     := 'FILE_NAME';           -- ファイル名
  cv_tkn_nm_org_cd            CONSTANT  VARCHAR2(100)   := 'ORG_CODE_TOK';        --在庫組織コード
  cv_tkn_count                CONSTANT VARCHAR2(20)     := 'COUNT';               -- 件数
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)     := 'LOOKUP_TYPE';         -- 参照タイプ
  cv_tkn_meaning              CONSTANT VARCHAR2(20)     := 'MEANING';             -- 意味
  cv_tkn_count_1              CONSTANT VARCHAR2(20)     := 'COUNT1';              -- 件数1
  cv_tkn_count_2              CONSTANT VARCHAR2(20)     := 'COUNT2';              -- 件数2
  cv_tkn_count_3              CONSTANT VARCHAR2(20)     := 'COUNT3';              -- 件数3
  -- プロファイル
  cv_pf_output_directory      CONSTANT VARCHAR2(50)     := 'XXCOS1_OUTBOUND_ZYOHO_DIR';        -- ディレクトリパス
  cv_pf_company_code          CONSTANT VARCHAR2(50)     := 'XXCOI1_COMPANY_CODE';              -- 会社コード
  cv_pf_csv_file_name         CONSTANT VARCHAR2(50)     := 'XXCOS1_KB_ORDER_FILE_NAME';        -- 受注情報ファイル名
  cv_pf_month                 CONSTANT VARCHAR2(50)     := 'XXCOS1_KB_ORDER_MONTH';            -- 受注日対象期間月数
-- Ver1.1 Add Start
  cv_pf_month_to              CONSTANT VARCHAR2(50)     := 'XXCOS1_KB_ORDER_MONTH_TO';         -- 受注日対象期間月数(TO)
-- Ver1.1 Add End
  cv_pf_org_id                CONSTANT VARCHAR2(50)     := 'ORG_ID';                           -- MO:営業単位
  cv_pf_org                   CONSTANT VARCHAR2(50)     := 'XXCOI1_ORGANIZATION_CODE';         -- 在庫組織コード
  cv_pf_gl_set_of_bks_id      CONSTANT VARCHAR2(50)     := 'GL_SET_OF_BKS_ID';                 -- GL会計帳簿ID
  -- クイックコードタイプ
  cv_qck_typ_sale    CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';         -- 売上区分
  -- 日付フォーマット
  cv_date_format              CONSTANT VARCHAR2(20)     := 'YYYY/MM/DD';
  cv_date_format_non_sep      CONSTANT VARCHAR2(20)     := 'YYYYMMDD';
  cv_datetime_format          CONSTANT VARCHAR2(20)     := 'YYYYMMDDHH24MISS';
  -- 切捨て時間要素
  cv_trunc_fmt                CONSTANT VARCHAR2(2)      := 'MM';
  -- 有効無効フラグ
  cv_enabled_flag             CONSTANT VARCHAR2(1)      := 'Y';             -- 有効
  cv_enabled_flag_a           CONSTANT VARCHAR2(1)      := 'A';             -- 有効
  -- 言語
  cv_lang                     CONSTANT VARCHAR2(100)    :=  USERENV( 'LANG' );
  -- 文字
  cv_blank                    CONSTANT VARCHAR2(1)      := '';             -- ブランク
  cv_flag_no                  CONSTANT VARCHAR2(1)      := 'N';            -- フラグ:No
  cv_delimiter                CONSTANT VARCHAR2(1)      := ',';            -- デリミタ
  cv_val_y                    CONSTANT VARCHAR2(1)      := 'Y';            -- 値：Y
  cv_val_n                    CONSTANT VARCHAR2(1)      := 'N';            -- 値：N
  cv_d_cot                    CONSTANT VARCHAR2(1)      := '"';            -- ダブルクォーテーション
  -- 使用目的
  cv_site_ship_to             CONSTANT VARCHAR2(10)     := 'SHIP_TO';      -- 出荷先
  -- 会計期間
  cv_ar                       CONSTANT VARCHAR2(10)     := 'AR';           -- AR
  cv_open                     CONSTANT VARCHAR2(10)     := 'O';            -- O:オープン
  -- 従業員カテゴリ
  cv_category_employee        CONSTANT VARCHAR2(8)      := 'EMPLOYEE';     -- 従業員
  -- 受注ステータス
  cv_header_closed            CONSTANT VARCHAR2(10)      := 'CLOSED';       -- クローズ
  cv_header_cancelled         CONSTANT VARCHAR2(10)      := 'CANCELLED';    -- キャンセル
  cv_line_closed              CONSTANT VARCHAR2(10)      := 'CLOSED';       -- クローズ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_system_date        DATE;                                                     -- システム日付
  gd_business_date      DATE;                                                     -- 業務日付
  gd_date_from          DATE;                                                     -- 会計（FROM）
  gd_date_to            DATE;                                                     -- 会計（TO）
  gt_output_directory   fnd_profile_option_values.profile_option_value%TYPE;      -- ディレクトリパス
  gt_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;      -- 受注情報ファイル名
  gn_kb_month           NUMBER;                                                   -- 情報系受注連携対象月数
-- Ver1.1 Add Stasrt
  gn_kb_month_to        NUMBER;                                                   -- 情報系受注連携対象月数(TO)
-- Ver1.1 Add End
  gt_company_code       fnd_profile_option_values.profile_option_value%TYPE;      -- 会社コード
  gt_org_id             fnd_profile_option_values.profile_option_value%TYPE;      -- MO:営業単位
  gt_file_handle        UTL_FILE.FILE_TYPE;                                       -- ファイルハンドル
  gn_inv_org_id         NUMBER;                                                   -- 在庫組織ID
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    -- 受注情報取得
    CURSOR get_order_info_cur
      IS
        SELECT /*+ USE_NL(oeh oel oeht sel oelt oos selk ) */
                oeht.name                       AS   header_type_name              -- 受注ヘッダタイプ
               ,oos.name                        AS   source_name                   -- 受注ソース
               ,oeh.order_number                AS   order_number                  -- 受注番号
               ,hca.account_number              AS   account_number                -- 顧客コード
               ,xca.sale_base_code              AS   sale_base_code                -- 売上拠点
               ,xca.past_sale_base_code         AS   past_sale_base_code           -- 前月売上拠点
               ,xca.delivery_base_code          AS   delivery_base_code            -- 納品拠点
               ,pri_h.name                      AS   h_price_list_name             -- 価格表(ヘッダ)
               ,sel.salesrep_number             AS   salesrep_number               -- 営業担当番号
               ,res.resource_name               AS   resource_name                 -- 営業担当
               ,oeh.ordered_date                AS   ordered_date                  -- 受注日
               ,oeh.cust_po_number              AS   cust_po_number                -- 顧客発注番号 
               ,oeh.request_date                AS   h_request_date                -- 納品予定日(ヘッダ)
               ,oeh.flow_status_code            AS   flow_status_code              -- 受注ヘッダステータス
               ,oeh.booked_date                 AS   booked_date                   -- 記帳日
               ,oeh.global_attribute4           AS   h_global_attribute4           -- 受注No.(HHT)
               ,oeh.global_attribute5           AS   h_global_attribute5           -- 発生元区分
               ,oel.line_number                 AS   line_number                   -- 受注明番号
               ,oel.shipment_number             AS   shipment_number               -- 受注明細出荷番号
               ,itm.segment1                    AS   segment1                      -- 受注品目
               ,oel.attribute6                  AS   l_attribute6                  -- 子コード
               ,oelt.name                       AS   line_type_name                -- 受注明細タイプ
               ,oel.ordered_quantity            AS   ordered_quantity              -- 受注数
               ,oel.order_quantity_uom          AS   order_quantity_uom            -- 受注単位
               ,oel.unit_selling_price          AS   unit_selling_price            -- 販売単価
               ,pri_l.name                      AS   l_price_list_name             -- 価格表(明細)
               ,oel.schedule_ship_date          AS   schedule_ship_date            -- 予定出荷日
               ,oel.request_date                AS   l_request_date                -- 納品予定日(明細)
               ,oel.subinventory                AS   subinventory                  -- 保管場所
               ,oel.packing_instructions        AS   packing_instructions          -- 出荷依頼No
               ,oel.context                     AS   l_context                     -- コンテキスト値(明細)
               ,SUBSTRB(oel.attribute4,1,10)    AS   l_attribute4                  -- 検収予定日
               ,oel.attribute5                  AS   l_attribute5                  -- 売上区分
               ,selk.meaning                    AS   meaning                       -- 売上区分摘要
               ,oel.attribute10                 AS   l_attribute10                 -- 売単価
               ,oel.flow_status_code            AS   l_flow_status_code            -- 受注明細ステータス
        FROM    oe_order_lines_all              oel    -- 受注明細
               ,oe_order_headers_all            oeh    -- 受注ヘッダ
               ,mtl_system_items_b              itm    -- 品目
               ,oe_transaction_types_tl         oeht   -- 受注タイプ(ヘッダ)
               ,oe_transaction_types_tl         oelt   -- 受注タイプ(明細)
               ,hz_cust_accounts                hca    -- 顧客マスタ
               ,xxcmm_cust_accounts             xca    -- 顧客アドオン
               ,qp_list_headers_vl              pri_h  -- 価格表(ヘッダ)
               ,qp_list_headers_vl              pri_l  -- 価格表(明細)
               ,jtf_rs_salesreps                sel    -- 営業担当
               ,jtf_rs_resource_extns_vl        res    -- リソース
               ,fnd_lookup_values               selk   -- 売上区分
               ,oe_order_sources                oos    -- 受注ソース
        WHERE   oeh.header_id                   = oel.header_id
        AND     oeh.org_id                      = gt_org_id
        AND     oel.inventory_item_id           = itm.inventory_item_id
        AND     itm.organization_id             = gn_inv_org_id
        AND     oeh.order_type_id               = oeht.transaction_type_id
        AND     oeht.language                   = cv_lang
        AND     oel.line_type_id                = oelt.transaction_type_id
        AND     oelt.language                   = cv_lang
        AND     oeh.sold_to_org_id              = hca.cust_account_id
        AND     hca.cust_account_id             = xca.customer_id
        AND     pri_l.list_header_id(+)         = oel.price_list_id
        AND     pri_h.list_header_id(+)         = oeh.price_list_id
        AND     sel.salesrep_id                 = oeh.salesrep_id
        AND     res.resource_id                 = sel.resource_id 
        AND     res.category                    = cv_category_employee
        AND     oel.attribute5                  = selk.lookup_code(+)
        AND     selk.LOOKUP_TYPE(+)             = cv_qck_typ_sale
        AND     selk.language(+)                = cv_lang
        AND     oos.order_source_id             = oel.order_source_id
-- Ver1.1 Mod Start
--        AND     oeh.ordered_date BETWEEN ADD_MONTHS(gd_business_date,gn_kb_month * -1) AND gd_business_date + 86399/86400
        AND     oeh.ordered_date BETWEEN ADD_MONTHS(gd_business_date,gn_kb_month * -1) AND ADD_MONTHS(gd_business_date,gn_kb_month_to) + 86399/86400
-- Ver1.1 Mod End
        AND     oel.request_date BETWEEN gd_date_from                                  AND gd_date_to       + 86399/86400
        AND     oeh.flow_status_code       NOT IN (cv_header_closed,cv_header_cancelled)
        AND     oel.flow_status_code           <>  cv_line_closed
        ;
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  get_order_info_rec  get_order_info_cur%ROWTYPE;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- レコードロックエラー
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_directory_path            VARCHAR2(100);                          -- ディレクトリ・パス
    lt_inv_org_cd                mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
    ln_gl_set_of_bks_id          NUMBER;                                 -- 会計帳簿ID
    lv_status                    VARCHAR2(6);                            -- ステータス
    ld_date_from                 DATE;                                   -- 会計（FROM）
    ld_date_to                   DATE;                                   -- 会計（TO）
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル例外 ***
    non_business_date_expt       EXCEPTION;     -- 業務日付取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.入力項目なしのメッセージ作成
    --==================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_msg_non_parameter);
    --
    --==================================
    -- コンカレント・メッセージ出力
    --==================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --==================================
    -- コンカレント・ログ出力
    --==================================
    -- 空行出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
-- 
    -- メッセージログ 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => gv_out_msg
    ); 
-- 
    -- 空行出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
--
    --==================================
    -- システム日付取得
    --==================================
    gd_system_date := SYSDATE;
--
    --==================================
    -- 2.業務日付取得
    --==================================
    gd_business_date :=  xxccp_common_pkg2.get_process_date;
--
    IF ( gd_business_date IS NULL ) THEN
      -- 業務日付が取得できない場合
      RAISE non_business_date_expt;
    END IF;
--
    --==================================
    -- 3.MO:営業単位取得
    --==================================
    gt_org_id := FND_PROFILE.VALUE( cv_pf_org_id );
--
    IF ( gt_org_id IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
        ,iv_token_value1 => cv_pf_org_id);              -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 4.ディレクトリパス取得
    --==================================
    gt_output_directory := FND_PROFILE.VALUE( cv_pf_output_directory );
--
    IF ( gt_output_directory IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
        ,iv_token_value1 => cv_pf_output_directory);    -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 5.受注情報ファイル名取得
    --==================================
    gt_csv_file_name := FND_PROFILE.VALUE( cv_pf_csv_file_name );
--
    IF ( gt_csv_file_name IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
        ,iv_token_value1 => cv_pf_csv_file_name);       -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ファイル名出力
    --==================================
    SELECT ad.directory_path
    INTO   lv_directory_path
    FROM   all_directories  ad
    WHERE  ad.directory_name = gt_output_directory;
    --
    gv_out_msg :=  xxccp_common_pkg.get_msg(
       iv_application  => cv_xxcos_short_name           -- アプリケーション短縮名
      ,iv_name         => cv_msg_file_name              -- メッセージ
      ,iv_token_name1  => cv_tkn_file_name              -- トークン1名
      ,iv_token_value1 => lv_directory_path 
                          || '/' 
                          || gt_csv_file_name);         -- トークン1値
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
--
    --==================================
    -- 6.情報系受注連携対象月数取得
    --==================================
    gn_kb_month := TO_NUMBER(FND_PROFILE.VALUE( cv_pf_month ));
--
    IF ( gn_kb_month IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
        ,iv_token_value1 => cv_pf_month);               -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Ver1.1 Add Start
    gn_kb_month_to := TO_NUMBER(FND_PROFILE.VALUE( cv_pf_month_to ));
--
    IF ( gn_kb_month_to IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
        ,iv_token_value1 => cv_pf_month_to);               -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Ver1.1 Add End
--
    --==================================
    -- 7.会社コード取得
    --==================================
    gt_company_code := FND_PROFILE.VALUE( cv_pf_company_code );
--
    IF ( gt_company_code IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
        ,iv_token_value1 => cv_pf_company_code);        -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
    --========================================
    -- 8.在庫組織コード取得処理
    --========================================
    lt_inv_org_cd := FND_PROFILE.VALUE( cv_pf_org );
    IF ( lt_inv_org_cd IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   => cv_xxcoi_short_name        -- アプリケーション短縮名
        ,iv_name          => cv_msg_org_cd_err          -- メッセージ
        ,iv_token_name1   => cv_tkn_pro_tok1            -- トークン1名
        ,iv_token_value1  => cv_pf_org);                -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 在庫組織ID取得処理
    --========================================
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id( lt_inv_org_cd );
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   =>  cv_xxcoi_short_name       -- アプリケーション短縮名
        ,iv_name          =>  cv_msg_org_id_err         -- メッセージ
        ,iv_token_name1   =>  cv_tkn_nm_org_cd          -- トークン1名
        ,iv_token_value1  =>  lt_inv_org_cd);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 9.会計帳簿ID取得処理
    --========================================
    ln_gl_set_of_bks_id := FND_PROFILE.VALUE( cv_pf_gl_set_of_bks_id );
    IF ( lt_inv_org_cd IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   => cv_xxcoi_short_name        -- アプリケーション短縮名
        ,iv_name          => cv_msg_notfound_profile    -- メッセージ
        ,iv_token_name1   => cv_tkn_pro_tok             -- トークン1名
        ,iv_token_value1  => cv_pf_gl_set_of_bks_id);   -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 10．OPEN会計期間情報取得
    --==============================================================
    BEGIN
      SELECT  MIN(gps.start_date)  date_from,
              MAX(gps.end_date)    date_to
        INTO  ld_date_from,
              ld_date_to
        FROM  gl_period_statuses  gps,
              fnd_application_vl  fav
       WHERE   gps.application_id  = fav.application_id
         AND   gps.set_of_books_id = ln_gl_set_of_bks_id
         AND   gps.closing_status  = cv_open
         AND   gps.adjustment_period_flag = cv_val_n
         AND   fav.application_short_name = cv_ar;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
           iv_application   =>  cv_xxcoi_short_name       -- アプリケーション短縮名
          ,iv_name          =>  cv_msg_period_err);       -- メッセージ
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    --エラーチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --会計期間FROM-TO
    gd_date_from := ld_date_from;
    gd_date_to   := ld_date_to;
  EXCEPTION
    --*** 業務日付取得エラー ***
    WHEN non_business_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_non_business_date    -- メッセージ
      );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : ファイルオープン(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf      OUT NOCOPY VARCHAR2,             --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,             --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
    cv_file_mode_overwrite      CONSTANT VARCHAR2(1) := 'W';     -- 上書
--
    -- *** ローカル例外 ***
    file_open_expt              EXCEPTION;      -- ファイルオープンエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- ファイルオープン
    --==================================
    BEGIN
      gt_file_handle := UTL_FILE.FOPEN(
                          location  => gt_output_directory           -- ディレクトリ
                         ,filename  => gt_csv_file_name              -- ファイル名
                         ,open_mode => cv_file_mode_overwrite);      -- ファイルモード
    EXCEPTION
      WHEN OTHERS THEN
        RAISE file_open_expt;
    END;
    --
    --==================================
    -- ファイル番号のチェック
    --==================================
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = FALSE ) THEN
      RAISE file_open_expt;
    END IF;
--
  EXCEPTION
    --*** ファイルオープンエラー ***
    WHEN file_open_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_file_open_error      -- メッセージ
                     ,iv_token_name1  => cv_tkn_file_name            -- トークン1名
                     ,iv_token_value1 => gt_csv_file_name);          -- トークン1値
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : open_order_info_cur
   * Description      : 受注情報カーソルオープン(A-3)
   ***********************************************************************************/
  PROCEDURE open_order_info_cur(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_order_info_cur'; -- プログラム名
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
    lv_table_name      VARCHAR2(50);
    lv_type_name       VARCHAR2(50);
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    order_extra_expt       EXCEPTION;    -- 受注データ抽出エラー
    non_lookup_value_expt  EXCEPTION;    -- LOOKUP取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 受注情報カーソルオープン
    --==================================
    BEGIN
      OPEN get_order_info_cur;
    EXCEPTION
      -- データ抽出エラー
      WHEN OTHERS THEN
        RAISE order_extra_expt;
    END;
--
  EXCEPTION
    --
    --*** 受注情報カーソルオープンエラー ***
    WHEN order_extra_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
         ,iv_name        => cv_msg_sales_line               -- メッセージID
      );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_data_extra_error
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => lv_table_name
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => cv_blank);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000||SQLERRM);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_order_info_cur;
--
  /**********************************************************************************
   * Procedure Name   : output_for_order
   * Description      : CSVファイル出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_for_order(
    it_order  IN  get_order_info_cur%ROWTYPE, --   受注情報
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_for_order'; -- プログラム名
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
    lv_buffer               VARCHAR2(5000);             -- 出力データ
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
    -- CSVファイルデータ出力
    -- ===============================
    lv_buffer :=
      cv_d_cot    || gt_company_code                                              || cv_d_cot    || cv_delimiter    -- ヘッダタイプ
      || cv_d_cot || it_order.header_type_name                                    || cv_d_cot    || cv_delimiter    -- ヘッダタイプ
      || cv_d_cot || it_order.source_name                                         || cv_d_cot    || cv_delimiter    -- 受注ソース
      || cv_d_cot || it_order.order_number                                        || cv_d_cot    || cv_delimiter    -- 受注番号
      || cv_d_cot || it_order.account_number                                      || cv_d_cot    || cv_delimiter    -- 顧客コード
      || cv_d_cot || it_order.sale_base_code                                      || cv_d_cot    || cv_delimiter    -- 売上拠点
      || cv_d_cot || it_order.past_sale_base_code                                 || cv_d_cot    || cv_delimiter    -- 前月売上拠点
      || cv_d_cot || it_order.delivery_base_code                                  || cv_d_cot    || cv_delimiter    -- 納品拠点
      || cv_d_cot || it_order.h_price_list_name                                   || cv_d_cot    || cv_delimiter    -- 価格表(ヘッダ)
      || cv_d_cot || it_order.salesrep_number                                     || cv_d_cot    || cv_delimiter    -- 営業担当番号
      || cv_d_cot || it_order.resource_name                                       || cv_d_cot    || cv_delimiter    -- 営業担当
      || cv_d_cot || TO_CHAR(it_order.ordered_date,cv_date_format_non_sep)        || cv_d_cot    || cv_delimiter    -- 受注日
      || cv_d_cot || it_order.cust_po_number                                      || cv_d_cot    || cv_delimiter    -- 顧客発注番号 
      || cv_d_cot || TO_CHAR(it_order.h_request_date,cv_date_format_non_sep)      || cv_d_cot    || cv_delimiter    -- 納品予定日(ヘッダ)
      || cv_d_cot || it_order.flow_status_code                                    || cv_d_cot    || cv_delimiter    -- 受注ヘッダステータス
      || cv_d_cot || TO_CHAR(it_order.booked_date,cv_datetime_format)             || cv_d_cot    || cv_delimiter    -- 記帳日
      || cv_d_cot || it_order.h_global_attribute4                                 || cv_d_cot    || cv_delimiter    -- 受注No.(HHT)
      || cv_d_cot || it_order.h_global_attribute5                                 || cv_d_cot    || cv_delimiter    -- 発生元区分
      || cv_d_cot || it_order.line_number                                         || cv_d_cot    || cv_delimiter    -- 受注明番号
      || cv_d_cot || it_order.shipment_number                                     || cv_d_cot    || cv_delimiter    -- 受注明細出荷番号
      || cv_d_cot || it_order.segment1                                            || cv_d_cot    || cv_delimiter    -- 受注品目
      || cv_d_cot || it_order.l_attribute6                                        || cv_d_cot    || cv_delimiter    -- 子コード
      || cv_d_cot || it_order.line_type_name                                      || cv_d_cot    || cv_delimiter    -- 受注明細タイプ
      ||             it_order.ordered_quantity                                                   || cv_delimiter    -- 受注数
      ||             it_order.order_quantity_uom                                                 || cv_delimiter    -- 受注単位
      ||             it_order.unit_selling_price                                                 || cv_delimiter    -- 販売単価
      || cv_d_cot || it_order.l_price_list_name                                   || cv_d_cot    || cv_delimiter    -- 価格表(明細)
      || cv_d_cot || TO_CHAR(it_order.schedule_ship_date,cv_date_format_non_sep)  || cv_d_cot    || cv_delimiter    -- 予定出荷日
      || cv_d_cot || TO_CHAR(it_order.l_request_date,cv_date_format_non_sep)      || cv_d_cot    || cv_delimiter    -- 納品予定日(明細)
      || cv_d_cot || it_order.subinventory                                        || cv_d_cot    || cv_delimiter    -- 保管場所
      || cv_d_cot || it_order.packing_instructions                                || cv_d_cot    || cv_delimiter    -- 出荷依頼No
      || cv_d_cot || it_order.l_attribute4                                        || cv_d_cot    || cv_delimiter    -- 検収予定日
      || cv_d_cot || it_order.l_attribute5                                        || cv_d_cot    || cv_delimiter    -- 売上区分
      || cv_d_cot || it_order.meaning                                             || cv_d_cot    || cv_delimiter    -- 売上区分摘要
      ||             TO_NUMBER(NVL(it_order.l_attribute10,'0'))                                  || cv_delimiter    -- 売単価
      || cv_d_cot || it_order.l_flow_status_code                                  || cv_d_cot    || cv_delimiter    -- 受注明細ステータス
      || cv_d_cot || TO_CHAR(gd_system_date,'YYYYMMDDHH24MISS')                   || cv_d_cot                       -- 連携日時
      ;
--
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => 'Data Put Start'
--    );
    -- CSVファイル出力
    UTL_FILE.PUT_LINE(
       file   => gt_file_handle
      ,buffer => lv_buffer
    );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => 'Data Put End'
--    );
    -- 出力件数カウント
    gn_normal_cnt := gn_normal_cnt + 1;
    --
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
  END output_for_order;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : ファイルクローズ(A-8)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close'; -- プログラム名
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
    -- ===============================
    -- ファイルクローズ
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gt_file_handle
    );
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
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : expt_proc
   * Description      : 例外処理(A-6)
   ***********************************************************************************/
  PROCEDURE expt_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'expt_proc'; -- プログラム名
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
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
      -- ファイルがオープンされている場合
      UTL_FILE.FCLOSE(
        file => gt_file_handle
      );
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
  END expt_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_buffer  VARCHAR2(5000);  -- 出力データ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_errbuf_wk  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_wk VARCHAR2(1);     -- リターン・コード
    lv_errmsg_wk  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_index      VARCHAR2(30);    -- インデックス・キー
-- 2010/02/02 Ver.2.15 Add Start
    ld_pre_digestion_due_date     DATE;
    ld_digestion_due_date         DATE;
-- 2010/02/02 Ver.2.15 Add Start
--
    -- *** ローカル例外 ***
    sub_program_expt      EXCEPTION;
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
--
    BEGIN
      -- ===============================
      -- A-1.初期処理
      -- ===============================
      init(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-2.ファイルオープン
      -- ===============================
      file_open(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_buffer
    );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => 'Header Put End'
--    );
      -- ===============================
      -- A-3.受注情報カーソルオープン
      -- ===============================
      open_order_info_cur(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      <<order_loop>>
      LOOP
        FETCH get_order_info_cur INTO get_order_info_rec;
        EXIT WHEN get_order_info_cur%NOTFOUND;
        gn_target_cnt := gn_target_cnt + 1;
--
        --==================================
        -- A-4.CSVファイル出力処理
        --==================================
        output_for_order(
           it_order => get_order_info_rec     -- 売上実績レコード型
          ,ov_errbuf       => lv_errbuf              -- エラー・メッセージ
          ,ov_retcode      => lv_retcode             -- リターン・コード
          ,ov_errmsg       => lv_errmsg);            -- ユーザー・エラー・メッセージ
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_program_expt;
        END IF;
--
      END LOOP order_loop;
      --
      CLOSE get_order_info_cur;
--
      -- ===============================
      -- A-5.ファイルクローズ
      -- ===============================
      file_close(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
    EXCEPTION
      WHEN sub_program_expt THEN
        -- プロシージャが異常終了
        -- メッセージを退避
        lv_errbuf_wk := lv_errbuf;
        lv_retcode_wk := lv_retcode;
        lv_errmsg_wk := lv_errmsg;
--
        -- ===============================
        -- A-6.例外処理
        -- ===============================
        expt_proc(
           ov_errbuf   => lv_errbuf        -- エラー・メッセージ
          ,ov_retcode  => lv_retcode       -- リターン・コード
          ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
        IF ( lv_retcode = cv_status_error ) THEN
          IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
            -- ファイルがオープンされている場合
            UTL_FILE.FCLOSE(
              file => gt_file_handle
            );
          END IF;
        END IF;
        gn_error_cnt := 1;
--
        -- メッセージを戻す
        lv_errbuf  := lv_errbuf_wk;
        lv_retcode := lv_retcode_wk;
        lv_errmsg  := lv_errmsg_wk;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
          IF ( get_order_info_cur%ISOPEN ) THEN
        CLOSE get_order_info_cur;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
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
--
    --件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_count
                    ,iv_token_name1  => cv_tkn_count_1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                    ,iv_token_name2  => cv_tkn_count_2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name3  => cv_tkn_count_3
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCOS015A02C;
/
