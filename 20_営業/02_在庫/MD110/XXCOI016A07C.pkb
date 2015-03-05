CREATE OR REPLACE PACKAGE BODY XXCOI016A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI016A07C(body)
 * Description      : ロット別引当情報をいずれかのステータスにてCSV出力を行います。
 * MD.050           : ロット別出荷情報CSV出力<MD050_COI_016_A07>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                             (A-1)
 *  chk_parameter          パラメータチェック                   (A-2)
 *  out_csv_base           ロット別引当情報データ抽出           (A-3)
 *                         ロット別引当情報CSV編集・要求出力    (A-4)
 *  submain                メイン処理プロシージャ
 *                         終了処理                             (A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/28    1.0   Y.Koh            初版作成
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
  cv_msg_sla                CONSTANT VARCHAR2(3) := '／';
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
  -- ユーザー定義例外
  -- ===============================
  csv_no_data_expt          EXCEPTION;      -- CSV対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI016A07C'; -- パッケージ名
  -- 参照タイプ
  cv_type_list_header   CONSTANT VARCHAR2(30) :=  'XXCOI1_LOT_SHIP_INF_LISTHEADER';-- ロット別出荷情報見出し
  -- 参照タイプコード
  cv_list_header_1      CONSTANT VARCHAR2(1)  :=  '1';                              -- ロット別出荷情報CSV見出し1
  cv_list_header_2      CONSTANT VARCHAR2(1)  :=  '2';                              -- ロット別出荷情報CSV見出し2
  cv_list_header_3      CONSTANT VARCHAR2(1)  :=  '3';                              -- ロット別出荷情報CSV見出し3
  -- メッセージ関連
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';                -- アプリケーション短縮名(在庫)
  cv_short_name_S       CONSTANT VARCHAR2(30) :=  'XXCOS';                -- アプリケーション短縮名(販売)
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';     -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10471   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10471';     -- パラメータ. 定番特売区分名取得エラーメッセージ
  cv_msg_xxcoi1_10472   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10472';     -- パラメータ. ステータス名取得エラーメッセージ
  ct_msg_parameter      CONSTANT VARCHAR2(30) :=  'APP-XXCOS1-14801';     -- パラメータ出力メッセージ
  ct_msg_bace_code      CONSTANT VARCHAR2(30) :=  'APP-XXCOS1-00035';     -- 拠点情報取得エラーメッセージ
  ct_msg_chain_code     CONSTANT VARCHAR2(30) :=  'APP-XXCOS1-00036';     -- チェーン店情報取得エラーメッセージ
  cv_msg_xxcoi1_10474   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10474';     -- 着日（From）の型チェックエラーメッセージ
  cv_msg_xxcoi1_10475   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10475';     -- 着日（To）の型チェックエラーメッセージ
  cv_msg_xxcoi1_10606   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10606';     -- EDI受信日の型チェックエラーメッセージ
  cv_msg_xxcoi1_10370   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10370';     -- 見出し情報取得エラーメッセージ
  cv_msg_xxcoi1_10476   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10476';     -- 着日整合性チェックエラーメッセージ
  cv_msg_xxcoi1_00008   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00008';     -- 対象データ無しメッセージ
  --トークン
  cv_tkn_code           CONSTANT VARCHAR2(100) := 'CODE';                   --拠点コード
  cv_tkn_chain_code     CONSTANT VARCHAR2(100) := 'CHAIN_SHOP_CODE';        --チェーン店コード
  cv_tkn_param1         CONSTANT VARCHAR2(100) := 'PARAM1';                 --第１入力パラメータ／内容
  cv_tkn_param2         CONSTANT VARCHAR2(100) := 'PARAM2';                 --第２入力パラメータ／内容
  cv_tkn_param3         CONSTANT VARCHAR2(100) := 'PARAM3';                 --第３入力パラメータ
  cv_tkn_param4         CONSTANT VARCHAR2(100) := 'PARAM4';                 --第４入力パラメータ
  cv_tkn_param5         CONSTANT VARCHAR2(100) := 'PARAM5';                 --第５入力パラメータ／内容
  cv_tkn_param6         CONSTANT VARCHAR2(100) := 'PARAM6';                 --第６入力パラメータ
  cv_tkn_param7         CONSTANT VARCHAR2(100) := 'PARAM7';                 --第７入力パラメータ／内容
  cv_tkn_param8         CONSTANT VARCHAR2(100) := 'PARAM8';                 --第８入力パラメータ
--
  --クイックコードタイプ
  ct_qct_bargain_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_BARGAIN_CLASS';
  ct_qct_sales_class        CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SALE_CLASS';
  ct_qct_shipping_staus     CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOI1_SHIPPING_STATUS';
  --使用可能フラグ定数
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                                  --使用可能
  -- 言語コード
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  --定番特売区分
  cv_bargain_class_all      CONSTANT VARCHAR2(2)  := '00';                    --全て
  cv_bargain_class_teiban   CONSTANT VARCHAR2(2)  := '01';                    --定番
  cv_bargain_class_tokubai  CONSTANT VARCHAR2(2)  := '02';                    --特売
  --フォーマット
  cv_fmt_date               CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  cv_fmt_datetime           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  -- その他
  cv_cust_cls_cd_base       CONSTANT VARCHAR2(1)  := '1';                     -- 顧客クラスコード(1:拠点)
  cv_cust_cls_cd_chain      CONSTANT VARCHAR2(2)  := '18';                    -- 顧客クラスコード(18:チェーン店)
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                  -- コンカレントヘッダ出力先
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                    -- 半角スペース１桁
  cv_separate_code          CONSTANT VARCHAR2(1)  :=  ',';                    -- 区切り文字（カンマ）
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期処理設定値
  gd_process_date           DATE;               -- 業務処理日付
--
  TYPE csv_data_type  IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;
  gt_csv_data         csv_data_type;                  -- CSVデータ
--
  gr_lookup_values1   xxcoi_common_pkg.lookup_rec;    -- クイックコードマスタ情報格納レコード
  gr_lookup_values2   xxcoi_common_pkg.lookup_rec;    -- クイックコードマスタ情報格納レコード
  gr_lookup_values3   xxcoi_common_pkg.lookup_rec;    -- クイックコードマスタ情報格納レコード
--
  --パラメータ
  gv_login_base_code                  VARCHAR2(4);                    -- 拠点
  gv_login_chain_store_code           VARCHAR2(4);                    -- チェーン店
  gd_request_date_from                DATE;                           -- 着日(From)
  gd_request_date_to                  DATE;                           -- 着日(To)
  gt_bargain_class                    fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定番特売区分
  gt_bargain_class_name               fnd_lookup_values.meaning%TYPE; -- 定番特売区分名称
  gd_edi_received_date                DATE;                           -- EDI受信日
  gt_shipping_sts_cd1                 fnd_lookup_values.attribute1%TYPE;
                                                                      -- 出荷情報ステータスコード1
  gt_shipping_sts_cd2                 fnd_lookup_values.attribute2%TYPE;
                                                                      -- 出荷情報ステータスコード2
  gt_shipping_sts_cd3                 fnd_lookup_values.attribute3%TYPE;
                                                                      -- 出荷情報ステータスコード3
  gv_order_number                     VARCHAR2(10);                   -- 受注番号
--
  gv_regular_sale_class_name          VARCHAR2(100);                  -- 定番特売区分名
--
  -- ===============================
  -- カーソル定義
  -- ===============================
  -- ロット別引当情報データ抽出
  CURSOR  base_cur
  IS
    SELECT  xlri.slip_num                     slip_num
           ,xlri.order_number                 order_number
           ,xlri.parent_shipping_status       parent_shipping_status
           ,xlri.parent_shipping_status_name  parent_shipping_status_name
           ,xlri.base_code                    base_code
           ,xlri.base_name                    base_name
           ,xlri.whse_code                    whse_code
           ,xlri.whse_name                    whse_name
           ,xlri.location_code                location_code
           ,xlri.location_name                location_name
           ,xlri.shipping_status              shipping_status
           ,xlri.shipping_status_name         shipping_status_name
           ,xlri.chain_code                   chain_code
           ,xlri.chain_name                   chain_name
           ,xlri.shop_code                    shop_code
           ,xlri.shop_name                    shop_name
           ,xlri.customer_code                customer_code
           ,xlri.customer_name                customer_name
           ,xlri.center_code                  center_code
           ,xlri.center_name                  center_name
           ,xlri.area_code                    area_code
           ,xlri.area_name                    area_name
           ,xlri.shipped_date                 shipped_date
           ,xlri.arrival_date                 arrival_date
           ,xlri.item_div                     item_div
           ,xlri.item_div_name                item_div_name
           ,xlri.parent_item_code             parent_item_code
           ,xlri.parent_item_name             parent_item_name
           ,xlri.item_code                    item_code
           ,xlri.item_name                    item_name
           ,xlri.lot                          lot
           ,xlri.difference_summary_code      difference_summary_code
           ,xlri.case_in_qty                  case_in_qty
           ,xlri.case_qty                     case_qty
           ,xlri.singly_qty                   singly_qty
           ,xlri.summary_qty                  summary_qty
           ,xlri.before_ordered_quantity      before_ordered_quantity
           ,xlri.regular_sale_class_line      regular_sale_class_line
           ,xlri.regular_sale_class_name_line regular_sale_class_name_line
           ,xlri.edi_received_date            edi_received_date
           ,xlri.delivery_order_edi           delivery_order_edi
           ,xlri.reserve_performer_code       reserve_performer_code
           ,xlri.reserve_performer_name       reserve_performer_name
    FROM    xxcoi_lot_reserve_info  xlri
    WHERE   xlri.base_code = gv_login_base_code
    AND     ( xlri.chain_code  = gv_login_chain_store_code OR  gv_login_chain_store_code IS NULL )
    AND     TRUNC(xlri.arrival_date) BETWEEN gd_request_date_from  AND gd_request_date_to
    AND     ( xlri.regular_sale_class_line = gt_bargain_class  OR  gt_bargain_class = cv_bargain_class_all )
    AND     ( TRUNC(xlri.edi_received_date) = gd_edi_received_date OR  gd_edi_received_date IS NULL )
    AND     xlri.parent_shipping_status IN (gt_shipping_sts_cd1,gt_shipping_sts_cd2,gt_shipping_sts_cd3) 
    AND     ( xlri.order_number  = gv_order_number OR  gv_order_number IS NULL )
    ORDER BY  xlri.slip_num
             ,xlri.order_number
             ,xlri.base_code
             ,xlri.whse_code
             ,xlri.location_code
             ,xlri.parent_item_code
             ,xlri.item_code;
  --
  g_lot_reserve_info_rec      base_cur%ROWTYPE;
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理                             (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_login_base_code        IN  VARCHAR2        -- 1.拠点
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.チェーン店
   ,iv_request_date_from      IN  VARCHAR2        -- 3.着日（From）
   ,iv_request_date_to        IN  VARCHAR2        -- 4.着日（To）
   ,iv_bargain_class          IN  VARCHAR2        -- 5.定番特売区分
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI受信日
   ,iv_shipping_status        IN  VARCHAR2        -- 7.ステータス
   ,iv_order_number           IN  VARCHAR2        -- 8.受注番号
   ,ov_errbuf                 OUT VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_login_base_name        VARCHAR2(40);
    lv_login_chain_store_name VARCHAR2(40);
    lt_shipping_sts_name      fnd_lookup_values.meaning%TYPE;  -- 出荷情報ステータス摘要
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ===================================
    --  1.業務処理日付取得
    -- ===================================
    gd_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      -- 業務処理日付取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --==================================
    -- 2.拠点、チェーン店名称取得
    --==================================
--
    --拠点名
    BEGIN
      SELECT
        hp.party_name         base_name
      INTO
        lv_login_base_name
      FROM
        hz_parties hp
       ,hz_cust_accounts hca
      WHERE
        hca.customer_class_code = cv_cust_cls_cd_base
      AND
        hca.account_number      = iv_login_base_code
      AND
        hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_login_base_name := NULL;
    END;
--
    --パラメータのチェーン店コードが設定されている場合、名称を取得する
    IF ( iv_login_chain_store_code IS NOT NULL )THEN
      BEGIN
        SELECT
          hp.party_name       chain_store_name
        INTO
          lv_login_chain_store_name
        FROM
          hz_parties          hp
         ,hz_cust_accounts    hca
         ,xxcmm_cust_accounts xca
        WHERE
          xca.chain_store_code    = iv_login_chain_store_code
        AND
          hca.cust_account_id     = xca.customer_id
        AND
          hca.customer_class_code = cv_cust_cls_cd_chain
        AND
          hp.party_id             = hca.party_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_login_chain_store_name := NULL;
      END;
    END IF;
--
    --==================================
    -- 3.定番特売区分名称取得
    --==================================
--
    gt_bargain_class_name :=  xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type  =>  ct_qct_bargain_class  -- 参照タイプ
                                 ,iv_lookup_code  =>  iv_bargain_class      -- 参照コード
                              );
--
    --==================================
    -- 4.出荷情報ステータス名称取得
    --==================================
--
    gr_lookup_values1 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  ct_qct_shipping_staus
                           ,iv_lookup_code    =>  iv_shipping_status
                           ,id_enabled_date   =>  gd_process_date
                          );
--
    lt_shipping_sts_name  :=  gr_lookup_values1.meaning;
    gt_shipping_sts_cd1   :=  gr_lookup_values1.attribute1;
    gt_shipping_sts_cd2   :=  gr_lookup_values1.attribute2;
    gt_shipping_sts_cd3   :=  gr_lookup_values1.attribute3;
--
     --==================================
    -- 5.パラメータ出力
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => cv_short_name_S
                                  ,iv_name               => ct_msg_parameter
                                  ,iv_token_name1        => cv_tkn_param1
                                  ,iv_token_value1       => iv_login_base_code || cv_msg_sla || lv_login_base_name
                                  ,iv_token_name2        => cv_tkn_param2
                                  ,iv_token_value2       => iv_login_chain_store_code || cv_msg_sla || lv_login_chain_store_name
                                  ,iv_token_name3        => cv_tkn_param3
                                  ,iv_token_value3       => iv_request_date_from
                                  ,iv_token_name4        => cv_tkn_param4
                                  ,iv_token_value4       => iv_request_date_to
                                  ,iv_token_name5        => cv_tkn_param5
                                  ,iv_token_value5       => iv_bargain_class || cv_msg_sla || gt_bargain_class_name
                                  ,iv_token_name6        => cv_tkn_param6
                                  ,iv_token_value6       => iv_edi_received_date
                                  ,iv_token_name7        => cv_tkn_param7
                                  ,iv_token_value7       => iv_shipping_status || cv_msg_sla || lt_shipping_sts_name
                                  ,iv_token_name8        => cv_tkn_param8
                                  ,iv_token_value8       => iv_order_number
                                 );
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => NULL
    );
--
    -- 名称取得エラーハンドリング
--
    -- 拠点名取得エラー時
    IF (lv_login_base_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name_S
                        ,iv_name          => ct_msg_bace_code
                        ,iv_token_name1   => cv_tkn_code
                        ,iv_token_value1  => iv_login_base_code
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- チェーン店名取得エラー時
    IF (iv_login_chain_store_code IS NOT NULL AND lv_login_chain_store_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name_S
                        ,iv_name          => ct_msg_chain_code
                        ,iv_token_name1   => cv_tkn_chain_code
                        ,iv_token_value1  => iv_login_chain_store_code
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 定番特売区分名取得エラー時
    IF (gt_bargain_class_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name
                        ,iv_name          => cv_msg_xxcoi1_10471
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 出荷情報ステータス名取得エラー時
    IF (lt_shipping_sts_name IS NULL) THEN
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                         iv_application   => cv_short_name
                        ,iv_name          => cv_msg_xxcoi1_10472
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 6.パラメータ変換
    --==================================
    gv_login_base_code        := iv_login_base_code;
    gv_login_chain_store_code := iv_login_chain_store_code;
    gt_bargain_class          := iv_bargain_class;
    gv_order_number           := iv_order_number;
--
    BEGIN
      gd_request_date_from      := TO_DATE(iv_request_date_from,  cv_fmt_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                           iv_application   => cv_short_name
                          ,iv_name          => cv_msg_xxcoi1_10474
                        );
        lv_errbuf   :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    BEGIN
      gd_request_date_to        := TO_DATE(iv_request_date_to,    cv_fmt_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                           iv_application   => cv_short_name
                          ,iv_name          => cv_msg_xxcoi1_10475
                        );
        lv_errbuf   :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF ( iv_edi_received_date IS NOT NULL )THEN
      BEGIN
        gd_edi_received_date    := TO_DATE(iv_edi_received_date,  cv_fmt_datetime);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg   :=  xxccp_common_pkg.get_msg(
                             iv_application   => cv_short_name
                            ,iv_name          => cv_msg_xxcoi1_10606
                          );
          lv_errbuf   :=  lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    -- ===================================
    --  7.見出し情報取得
    -- ===================================
    gr_lookup_values1 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_1
                           ,id_enabled_date   =>  gd_process_date
                          );
    --
    IF (gr_lookup_values1.meaning IS NULL) THEN
      -- 見出し情報取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    gr_lookup_values2 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_2
                           ,id_enabled_date   =>  gd_process_date
                          );
    --
    IF (gr_lookup_values2.meaning IS NULL) THEN
      -- 見出し情報取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    gr_lookup_values3 :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_3
                           ,id_enabled_date   =>  gd_process_date
                          );
    --
    IF (gr_lookup_values3.meaning IS NULL) THEN
      -- 見出し情報取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : パラメータチェック                   (A-2)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter'; -- プログラム名
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
    --==================================
    -- 日付逆転チェック
    --==================================
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      -- 見出し情報取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10476
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
  END chk_parameter;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_base
   * Description      : ロット別引当情報データ抽出           (A-3)
   *                    ロット別引当情報CSV編集・要求出力    (A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_base(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_base'; -- プログラム名
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
    ln_cnt        NUMBER;                                 -- CSVレコード行番号
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
    OPEN  base_cur;
    FETCH base_cur  INTO  g_lot_reserve_info_rec;
    --
    IF (base_cur%NOTFOUND) THEN
      -- 対象データ無しメッセージ
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- 空行を出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- 対象データが取得されなかった場合、処理を終了
      CLOSE base_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  １行目編集（見出し）
    -- ===================================
    gt_csv_data(1)  :=     gr_lookup_values1.attribute1                -- 見出し１
                        || cv_separate_code
                        || gr_lookup_values1.attribute2                -- 見出し２
                        || cv_separate_code
                        || gr_lookup_values1.attribute3                -- 見出し３
                        || cv_separate_code
                        || gr_lookup_values1.attribute4                -- 見出し４
                        || cv_separate_code
                        || gr_lookup_values1.attribute5                -- 見出し５
                        || cv_separate_code
                        || gr_lookup_values1.attribute6                -- 見出し６
                        || cv_separate_code
                        || gr_lookup_values1.attribute7                -- 見出し７
                        || cv_separate_code
                        || gr_lookup_values1.attribute8                -- 見出し８
                        || cv_separate_code
                        || gr_lookup_values1.attribute9                -- 見出し９
                        || cv_separate_code
                        || gr_lookup_values1.attribute10               -- 見出し１０
                        || cv_separate_code
                        || gr_lookup_values1.attribute11               -- 見出し１１
                        || cv_separate_code
                        || gr_lookup_values1.attribute12               -- 見出し１２
                        || cv_separate_code
                        || gr_lookup_values1.attribute13               -- 見出し１３
                        || cv_separate_code
                        || gr_lookup_values1.attribute14               -- 見出し１４
                        || cv_separate_code
                        || gr_lookup_values1.attribute15               -- 見出し１５
                        || cv_separate_code
                        || gr_lookup_values2.attribute1                -- 見出し１６
                        || cv_separate_code
                        || gr_lookup_values2.attribute2                -- 見出し１７
                        || cv_separate_code
                        || gr_lookup_values2.attribute3                -- 見出し１８
                        || cv_separate_code
                        || gr_lookup_values2.attribute4                -- 見出し１９
                        || cv_separate_code
                        || gr_lookup_values2.attribute5                -- 見出し２０
                        || cv_separate_code
                        || gr_lookup_values2.attribute6                -- 見出し２１
                        || cv_separate_code
                        || gr_lookup_values2.attribute7                -- 見出し２２
                        || cv_separate_code
                        || gr_lookup_values2.attribute8                -- 見出し２３
                        || cv_separate_code
                        || gr_lookup_values2.attribute9                -- 見出し２４
                        || cv_separate_code
                        || gr_lookup_values2.attribute10               -- 見出し２５
                        || cv_separate_code
                        || gr_lookup_values2.attribute11               -- 見出し２６
                        || cv_separate_code
                        || gr_lookup_values2.attribute12               -- 見出し２７
                        || cv_separate_code
                        || gr_lookup_values2.attribute13               -- 見出し２８
                        || cv_separate_code
                        || gr_lookup_values2.attribute14               -- 見出し２９
                        || cv_separate_code
                        || gr_lookup_values2.attribute15               -- 見出し３０
                        || cv_separate_code
                        || gr_lookup_values3.attribute1                -- 見出し３１
                        || cv_separate_code
                        || gr_lookup_values3.attribute2                -- 見出し３２
                        || cv_separate_code
                        || gr_lookup_values3.attribute3                -- 見出し３３
                        || cv_separate_code
                        || gr_lookup_values3.attribute4                -- 見出し３４
                        || cv_separate_code
                        || gr_lookup_values3.attribute5                -- 見出し３５
                        || cv_separate_code
                        || gr_lookup_values3.attribute6                -- 見出し３６
                        || cv_separate_code
                        || gr_lookup_values3.attribute7                -- 見出し３７
                        || cv_separate_code
                        || gr_lookup_values3.attribute8                -- 見出し３８
                        || cv_separate_code
                        || gr_lookup_values3.attribute9                -- 見出し３９
                        || cv_separate_code
                        || gr_lookup_values3.attribute10               -- 見出し４０
                        || cv_separate_code
                        || gr_lookup_values3.attribute11               -- 見出し４１
                        || cv_separate_code
                        || gr_lookup_values3.attribute12               -- 見出し４２
                        || cv_separate_code
                        || gr_lookup_values3.attribute13;              -- 見出し４３
    --
    -- ===================================
    --  ２行目以降編集（ロット別出荷情報）
    -- ===================================
    ln_cnt  :=  2;
    --
    <<set_csv_base_loop>>
    LOOP
      -- 終了判定
      EXIT set_csv_base_loop WHEN base_cur%NOTFOUND;
      --
      -- 定番特売区分が'01'、'02'の場合は前'0'を削除し、DB値を出力する。
      IF( g_lot_reserve_info_rec.regular_sale_class_line IN( cv_bargain_class_teiban,cv_bargain_class_tokubai ) )THEN
        g_lot_reserve_info_rec.regular_sale_class_line 
          := SUBSTRB( g_lot_reserve_info_rec.regular_sale_class_line, 2, 1 );
        gv_regular_sale_class_name := g_lot_reserve_info_rec.regular_sale_class_name_line;
      -- 上記以外の場合は、名称を取得する
      ELSE
        gv_regular_sale_class_name
          := xxcoi_common_pkg.get_meaning( iv_lookup_type  => ct_qct_sales_class                              -- 参照タイプ
                                          ,iv_lookup_code  => g_lot_reserve_info_rec.regular_sale_class_line  -- 参照コード
                                          );
      END IF;
      --
      -- 明細レコード設定
      gt_csv_data(ln_cnt) :=  g_lot_reserve_info_rec.slip_num                     -- 伝票No
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.order_number                 -- 受注番号
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_shipping_status       -- 出荷情報ステータス(受注番号単位)
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_shipping_status_name  -- 出荷情報ステータス名(受注番号単位)
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.base_code                    -- 拠点コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.base_name                    -- 拠点名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.whse_code                    -- 保管場所コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.whse_name                    -- 保管場所名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.location_code                -- ロケーションコード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.location_name                -- ロケーション名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shipping_status              -- 出荷情報ステータス
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shipping_status_name         -- 出荷情報ステータス名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.chain_code                   -- チェーン店コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.chain_name                   -- チェーン店名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shop_code                    -- 店舗コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.shop_name                    -- 店舗名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.customer_code                -- 顧客コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.customer_name                -- 顧客名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.center_code                  -- センターコード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.center_name                  -- センター名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.area_code                    -- 地区コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.area_name                    -- 地区名称
                          ||  cv_separate_code
                          ||  TO_CHAR(g_lot_reserve_info_rec.shipped_date,cv_fmt_date)
                                                                                  -- 出荷日
                          ||  cv_separate_code
                          ||  TO_CHAR(g_lot_reserve_info_rec.arrival_date,cv_fmt_date)
                                                                                  -- 着日
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_div                     -- 商品区分
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_div_name                -- 商品区分名
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_item_code             -- 親品目コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.parent_item_name             -- 親品目名称
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_code                    -- 子品目コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.item_name                    -- 子品目名称
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.lot                          -- 賞味期限
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.difference_summary_code      -- 固有記号
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.case_in_qty                  -- 入数
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.case_qty                     -- ケース数
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.singly_qty                   -- バラ数
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.summary_qty                  -- 数量
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.before_ordered_quantity      -- 訂正前受注数量
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.regular_sale_class_line      -- 定番特売区分
                          ||  cv_separate_code
                          ||  gv_regular_sale_class_name                          -- 定番特売区分名
                          ||  cv_separate_code
                          ||  TO_CHAR(g_lot_reserve_info_rec.edi_received_date,cv_fmt_date)
                                                                                  -- EDI受信日
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.delivery_order_edi           -- 配送順(EDI)
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.reserve_performer_code       -- 引当実行者コード
                          ||  cv_separate_code
                          ||  g_lot_reserve_info_rec.reserve_performer_name;      -- 引当実行者名
      --
      -- 変数カウントアップ
      ln_cnt  :=  ln_cnt + 1;
      --
      -- 処理件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- データ取得
      FETCH base_cur  INTO  g_lot_reserve_info_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE base_cur;
    --
    -- ===================================
    --  CSV出力
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--
    -- *** CSV対象データなし例外 ***
    WHEN csv_no_data_expt THEN
      -- 正常で、本プロシージャを終了
      NULL;
--
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
      IF (base_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END out_csv_base;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   *                    終了処理                             (A-5)
   **********************************************************************************/
  PROCEDURE submain(
    iv_login_base_code        IN  VARCHAR2        -- 1.拠点
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.チェーン店
   ,iv_request_date_from      IN  VARCHAR2        -- 3.着日（From）
   ,iv_request_date_to        IN  VARCHAR2        -- 4.着日（To）
   ,iv_bargain_class          IN  VARCHAR2        -- 5.定番特売区分
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI受信日
   ,iv_shipping_status        IN  VARCHAR2        -- 7.ステータス
   ,iv_order_number           IN  VARCHAR2        -- 8.受注番号
   ,ov_errbuf                 OUT VARCHAR2        -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2        -- リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  1.初期処理(A-1)
    -- ===============================
    init(
      iv_login_base_code        =>  iv_login_base_code        -- 1.拠点
     ,iv_login_chain_store_code =>  iv_login_chain_store_code -- 2.チェーン店
     ,iv_request_date_from      =>  iv_request_date_from      -- 3.着日（From）
     ,iv_request_date_to        =>  iv_request_date_to        -- 4.着日（To）
     ,iv_bargain_class          =>  iv_bargain_class          -- 5.定番特売区分
     ,iv_edi_received_date      =>  iv_edi_received_date      -- 6.EDI受信日
     ,iv_shipping_status        =>  iv_shipping_status        -- 7.ステータス
     ,iv_order_number           =>  iv_order_number           -- 8.受注番号
     ,ov_errbuf                 =>  lv_errbuf                 --   エラー・メッセージ           --# 固定 #
     ,ov_retcode                =>  lv_retcode                --   リターン・コード             --# 固定 #
     ,ov_errmsg                 =>  lv_errmsg                 --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  2.パラメータチェック(A-2)
    -- ===============================
    chk_parameter(
      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    --  3.ロット別引当情報CSV編集・要求出力(A-3, A-4)
    -- ====================================
    out_csv_base(
      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  4.終了処理(A-5)
    -- ===============================
    -- 正常件数を設定
    gn_normal_cnt := gn_target_cnt;
    --
  EXCEPTION
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
    errbuf                    OUT VARCHAR2        -- エラー・メッセージ  --# 固定 #
   ,retcode                   OUT VARCHAR2        -- リターン・コード    --# 固定 #
   ,iv_login_base_code        IN  VARCHAR2        -- 1.拠点
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.チェーン店
   ,iv_request_date_from      IN  VARCHAR2        -- 3.着日（From）
   ,iv_request_date_to        IN  VARCHAR2        -- 4.着日（To）
   ,iv_bargain_class          IN  VARCHAR2        -- 5.定番特売区分
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI受信日
   ,iv_shipping_status        IN  VARCHAR2        -- 7.ステータス
   ,iv_order_number           IN  VARCHAR2        -- 8.受注番号
  )
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
        iv_login_base_code        =>  iv_login_base_code        -- 1.拠点
       ,iv_login_chain_store_code =>  iv_login_chain_store_code -- 2.チェーン店
       ,iv_request_date_from      =>  iv_request_date_from      -- 3.着日（From）
       ,iv_request_date_to        =>  iv_request_date_to        -- 4.着日（To）
       ,iv_bargain_class          =>  iv_bargain_class          -- 5.定番特売区分
       ,iv_edi_received_date      =>  iv_edi_received_date      -- 6.EDI受信日
       ,iv_shipping_status        =>  iv_shipping_status        -- 7.ステータス
       ,iv_order_number           =>  iv_order_number           -- 8.受注番号
       ,ov_errbuf                 =>  lv_errbuf                 -- エラー・メッセージ             --# 固定 #
       ,ov_retcode                =>  lv_retcode                -- リターン・コード               --# 固定 #
       ,ov_errmsg                 =>  lv_errmsg                 -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      -- 処理件数
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --
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
    -- 空行を出力
    FND_FILE.PUT_LINE(
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
END XXCOI016A07C;
/
