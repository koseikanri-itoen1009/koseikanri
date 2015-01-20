CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A01C(body)
 * Description      : HHT向け納品予定データ作成
 * MD.050           : HHT向け納品予定データ作成 MD050_COS_003_A01
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  proc_break_process     受注ヘッダ情報IDブレイク後の処理（ファイル出力、ステータス更新）
 *  proc_main_loop         ループ部 A-2データ抽出
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/26   1.0    K.Okaguchi       新規作成
 *  2009/02/24   1.1    T.Nakamura       [障害COS_130] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/04/15   1.2    N.Maeda          [ST障害No.T1_0067対応] ファイル出力時のCHAR型VARCHAR型以外への｢"｣付加の削除
 *  2009/05/01   1.3    T.Kitajima       [T1_0678]マッピング不正対応
 *  2009/07/08   1.4    K.Kiriu          [0000063]情報区分の課題対応
 *                                       [0000064]受注ヘッダDFF項目漏れ対応
 *  2009/08/06   1.4    M.Sano           [0000426]『HHT向け納品予定データ作成』PTの考慮
 *  2009/09/01   1.5    M.Sano           [0001066]『HHT向け納品予定データ作成』PTの考慮
 *  2010/03/30   1.6    S.Miyakoshi      [E_本稼動_02058]単位換算処理の追加
 *  2014/03/04   1.7    T.Nakano         [E_本稼動_11551]パフォーマンス対応
 *  2015/01/08   1.8    H.Wajima         [E_本稼動_12806]単位換算処理の修正
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
  gn_set_cnt       NUMBER;                    -- 設定カウンタ
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
  global_data_check_expt    EXCEPTION;     -- データチェック時のエラー
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
  global_change_err_expt    EXCEPTION;     -- 単位換算エラー
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A01C'; -- パッケージ名
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーション名
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- アドオン：共通・IF領域
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- 区切り文字
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- コーテーション
--
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_order                CONSTANT VARCHAR2(20) := 'ORDER';
  cv_brank                CONSTANT VARCHAR2(1)  := ' ';
  cv_minus                CONSTANT VARCHAR2(1)  := '-';
--
  cv_booked               CONSTANT VARCHAR2(10) := 'BOOKED';
  cv_sales_car            CONSTANT VARCHAR2(1)  := '5';
  cv_non_tran             CONSTANT VARCHAR2(1)  := 'N';
  cv_customer             CONSTANT VARCHAR2(1)  := '1';
  cv_output_flag          CONSTANT VARCHAR2(1)  := 'Y';
  cv_error_status         CONSTANT VARCHAR2(1)  := '1';
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';                     -- ロックエラー
  cv_tkn_order_number     CONSTANT VARCHAR2(20) := 'ORDER_NUMBER';
  cv_tkn_line_number      CONSTANT VARCHAR2(20) := 'LINE_NUMBER';
  cv_tkn_item_name        CONSTANT VARCHAR2(20) := 'ITEM_NAME';
  cv_tkn_item_value       CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';                   -- エラー内容
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';          -- ロックエラー
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';          -- 
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';          -- 
  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';          -- ファイル名（タイトル）
  cv_msg_notnull          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10651';          -- 必須エラー
  cv_msg_overflow         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10652';          -- 桁あふれエラー
  cv_delivery_base_code   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10653';          -- 拠点コード
  cv_order_number         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10654';          -- 受注番号
  cv_line_number          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10655';          -- 明細番号
  cv_ordered_item         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10656';          -- 品目コード
  cv_customer_item_number CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10657';          -- 顧客品目コード
  cv_customer_item_desc   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10658';          -- 顧客品目摘要
  cv_ordered_quantity     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10659';          -- 受注数量
  cv_unit_selling_price   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10660';          -- 販売単価
  cv_selling_price        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10661';          -- 売単価
  cv_tkn_lock_table       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00115';          -- EDI明細情報テーブル
  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';          -- HHTアウトバウンド用ディレクトリパス
  cv_tkn_h_filename       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10663';          -- EOSヘッダファイル名
  cv_tkn_l_filename       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10664';          -- EOS明細ファイル名
  cv_tkn_h_file           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10665';          -- EOSヘッダファイル
  cv_tkn_l_file           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10666';          -- EOS明細ファイル
  cv_tkn_org_id           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10667';          -- MO:営業単位
  cv_tkn_organization_cd  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';          -- XXCOI:在庫組織コード
  cv_tkn_update_table     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10668';          -- EDI明細情報テーブル
  cv_edi_line_id          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10669';          -- 受注明細情報ID
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
  cv_msg_change_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10670';          -- 単位換算エラー
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
/* 2014/03/04 Ver1.7 Add Start */
  cv_msg_proc_date_err    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';         -- 業務日付取得エラーメッセージ
  cv_msg_ord_keep_day     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10671';         -- HHT納品用受注保持日数
/* 2014/03/04 Ver1.7 Add End */
  -- その他
  cv_file_access_mode     CONSTANT VARCHAR2(10) := 'W';                         -- ファイルアクセスモード
  cv_cust_class_cust      CONSTANT VARCHAR2(10) := '10';                        -- 顧客区分（顧客）
  cv_cust_class_chain     CONSTANT VARCHAR2(10) := '18';                        -- 顧客区分（チェーン店）
  cv_enabled              CONSTANT VARCHAR2(10) := 'Y';                         -- 有効フラグ
  cv_default_language     CONSTANT VARCHAR2(10) := USERENV('LANG');             -- 標準言語タイプ
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--  cv_number_format8       CONSTANT VARCHAR2(20) := 'FM99999999.00';             -- 数値フォーマット８桁
--  cv_number_format7       CONSTANT VARCHAR2(20) := 'FM9999999.00';              -- 数値フォーマット７桁
  cv_number_format8       CONSTANT VARCHAR2(20) := 'FM99999990.00';             -- 数値フォーマット８桁
  cv_number_format7       CONSTANT VARCHAR2(20) := 'FM9999990.00';              -- 数値フォーマット７桁
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
/* 2009/07/08 Ver1.4 Add Start */
  --情報区分
  cv_target_order_01      CONSTANT  VARCHAR2(2) := '01';                        -- 受注作成対象01
/* 2009/07/08 Ver1.4 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id                   NUMBER;
  gv_organization_code        mtl_parameters.organization_code%TYPE         ;--在庫組織コード
  gv_delivery_base_code       xxcmm_cust_accounts.delivery_base_code%TYPE   ;--納品拠点コード
  gv_order_number             oe_order_headers_all.order_number%TYPE        ;--受注No
  gv_conv_customer_code       xxcos_edi_headers.conv_customer_code%TYPE     ;--顧客コード
  gv_invoice_number           xxcos_edi_headers.invoice_number%TYPE         ;--伝票番号
  gd_request_date             oe_order_headers_all.request_date%TYPE        ;--納品日
  gv_big_classification_code  xxcos_edi_headers.big_classification_code%TYPE;--売上分類区分
  gv_invoice_class            xxcos_edi_headers.invoice_class%TYPE          ;--売上伝票区分
  gv_company_name_alt         xxcos_edi_headers.company_name_alt%TYPE       ;--社名（カナ）
  gv_shop_name_alt            xxcos_edi_headers.shop_name_alt%TYPE          ;--店名（カナ）
  gv_edi_chain_code           xxcos_edi_headers.edi_chain_code%TYPE         ;--チェーン店コード
  gn_edi_header_info_id       xxcos_edi_headers.edi_header_info_id%TYPE     ;--受注ヘッダ情報ID
  gv_customer_item_number     mtl_customer_items.customer_item_number%TYPE  ;--顧客品目番号
  gv_customer_item_desc       mtl_customer_items.customer_item_desc%TYPE    ;--顧客品目摘要
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--メッセージ出力用キー情報
  gv_msg_delivery_base_code   fnd_new_messages.message_text%TYPE   ;--'拠点コード'
  gv_msg_order_number         fnd_new_messages.message_text%TYPE   ;--'受注番号'
  gv_msg_line_number          fnd_new_messages.message_text%TYPE   ;--'明細番号'
  gv_msg_ordered_item         fnd_new_messages.message_text%TYPE   ;--'品目コード'
  gv_msg_customer_item_number fnd_new_messages.message_text%TYPE   ;--'顧客品目コード'
  gv_msg_customer_item_desc   fnd_new_messages.message_text%TYPE   ;--'顧客品目摘要'
  gv_msg_ordered_quantity     fnd_new_messages.message_text%TYPE   ;--'受注数量'
  gv_msg_unit_selling_price   fnd_new_messages.message_text%TYPE   ;--'販売単価'
  gv_msg_selling_price        fnd_new_messages.message_text%TYPE   ;--'売単価'
  gv_msg_tkn_lock_table       fnd_new_messages.message_text%TYPE   ;--'EDI明細情報テーブル
  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--'HHTアウトバウンド用ディレクトリパス'
  gv_msg_tkn_h_filename       fnd_new_messages.message_text%TYPE   ;--'EOSヘッダファイル名'
  gv_msg_tkn_l_filename       fnd_new_messages.message_text%TYPE   ;--'EOS明細ファイル名'
  gv_msg_tkn_h_file           fnd_new_messages.message_text%TYPE   ;--'EOSヘッダファイル'
  gv_msg_tkn_l_file           fnd_new_messages.message_text%TYPE   ;--'EOS明細ファイル'
  gv_msg_tkn_org_id           fnd_new_messages.message_text%TYPE   ;--'MO:営業単位'
  gv_msg_tkn_organization_cd  fnd_new_messages.message_text%TYPE   ;--'XXCOI:在庫組織コード'
  gv_msg_tkn_update_table     fnd_new_messages.message_text%TYPE   ;--'EDI明細情報テーブル'
  gv_msg_edi_line_id          fnd_new_messages.message_text%TYPE   ;--'受注明細情報ID'
  gv_h_file_data              VARCHAR2(2000);
  gv_l_file_data              VARCHAR2(2000);
  gv_edi_order_source         fnd_lookup_values.meaning%TYPE;       -- 受注ソース
  gv_transaction_status       VARCHAR2(1);                          -- チェックステータス
/* 2014/03/04 Ver1.7 Add Start */
  gd_proc_date                DATE;                                 -- 業務日付
  gn_hht_deli_ord_keep_day    NUMBER;                               -- HHT納品用受注保持日数
  gv_msg_tkn_ord_keep_day     fnd_new_messages.message_text%TYPE;   -- 'HHT納品用受注保持日数'
/* 2014/03/04 Ver1.7 Add End */
--
  --カーソル
  CURSOR main_cur
  IS
/* 2009/08/06 Ver1.4 Add Start */
--    SELECT ooha.order_number               order_number               --受注ヘッダテーブル．受注番号
/* 2009/09/01 Ver1.5 Mod Start */
--    SELECT /*+ leading(ooha)
--               use_nl(xieh)
--               index(ooha xxcos_oe_order_headers_all_n12)
--               index(xiel xxcos_edi_lines_n01) */
/* 2014/03/04 Ver1.7 Mod Start */
--      SELECT /*+ leading(oosa)
--                 use_nl(ooha)
--                 use_nl(xieh)
--                 use_nl(xiel)
--                 use_nl(msiv)
--                 index(ooha xxcos_oe_order_headers_all_n12)
--                 index(oola oe_order_lines_n1)
--                 index(xiel xxcos_edi_lines_n01)
--              */
    SELECT /*+   leading(ooha)
                 index(ooha xxcos_oe_order_headers_all_n10)
                 use_nl(xieh xiel ooha oola oosc msiv xcac)
                 index(oola oe_order_lines_n1)
              */
/* 2014/03/04 Ver1.7 Mod End */
/* 2009/09/01 Ver1.5 Mod End   */
           ooha.order_number               order_number               --受注ヘッダテーブル．受注番号
/* 2009/08/06 Ver1.4 Add End   */
         , ooha.request_date               request_date               --受注ヘッダテーブル．要求日
         , xieh.edi_chain_code             edi_chain_code             --EDIヘッダ情報テーブル．EDIチェーン店コード
         , xieh.conv_customer_code         conv_customer_code         --EDIヘッダ情報テーブル．変換後顧客コード
         , xieh.shop_name_alt              shop_name_alt              --EDIヘッダ情報テーブル．店名（カナ）
         , xcac.delivery_base_code         delivery_base_code         --顧客追加情報．納品拠点コード
         , xieh.company_name_alt           company_name_alt           --EDIヘッダ情報テーブル．社名（カナ）
/* 2009/07/08 Ver1.4 Mod Start */
--         , xieh.big_classification_code    big_classification_code    --EDIヘッダ情報テーブル．大分類コード
--         , xieh.invoice_class              invoice_class              --EDIヘッダ情報テーブル．伝票区分
         , ooha.attribute20                big_classification_code    --受注ヘッダテーブル．分類区分
         , ooha.attribute5                 invoice_class              --受注ヘッダテーブル．伝票区分
/* 2009/07/08 Ver1.4 Mod End   */
         , xieh.invoice_number             invoice_number             --EDIヘッダ情報テーブル．伝票番号の下9桁
         , xieh.edi_header_info_id         edi_header_info_id         --EDIヘッダ情報テーブル．受注ヘッダ情報ID
         , xiel.selling_price              selling_price              --EDI明細情報テーブル．売価単価
         , xiel.edi_line_info_id           edi_line_info_id           --EDI明細情報テーブル．EDI明細情報ID
--******************************* 2009/05/01 1.3 T.Kitajima ADD START *******************************--
         , xiel.product_code2              product_code2              --EDI明細情報テーブル．商品コード２
         , NVL(  xiel.product_name2_alt
                ,xiel.product_name1_alt 
              )                            product_name_alt           --EDI明細情報テーブル．商品名２（カナ）or 商品名１（カナ）
--******************************* 2009/05/01 1.3 T.Kitajima ADD  END  *******************************--
         , oola.ordered_quantity           ordered_quantity           --受注明細テーブル．数量
         , oola.unit_selling_price         unit_selling_price         --受注明細テーブル．販売単価
         , oola.line_number                line_number                --受注明細テーブル．明細番号
         , oola.ordered_item               ordered_item               --受注明細テーブル．受注品目
         , oola.line_category_code         line_category_code         --受注明細テーブル．受注カテゴリ明細カテゴリコード
         , oola.order_quantity_uom         order_quantity_uom         --受注明細テーブル．単位
         , oola.inventory_item_id          inventory_item_id          --品目ID
         , oola.ship_from_org_id           ship_from_org_id           --出荷先顧客
         , ooha.sold_to_org_id             sold_to_org_id             --売上先顧客
    FROM   oe_order_headers_all            ooha                       --受注ヘッダテーブル
         , oe_order_lines_all              oola                       --受注明細テーブル
         , xxcos_edi_headers               xieh                       --EDIヘッダ情報テーブル
         , xxcos_edi_lines                 xiel                       --EDI明細情報テーブル
         , oe_order_sources                oosc                       --受注ソーステーブル
         , mtl_secondary_inventories       msiv                       --保管場所マスタ
         , xxcmm_cust_accounts             xcac                       --顧客追加情報
    WHERE
          ooha.order_source_id              =  oosc.order_source_id
    AND   oosc.name                         =  gv_edi_order_source
    AND   ooha.org_id                       =  gn_org_id
    AND   ooha.flow_status_code             =  cv_booked
    AND   ooha.header_id                    =  oola.header_id
    AND   oola.subinventory                 =  msiv.secondary_inventory_name
    AND   oola.ship_from_org_id             =  msiv.organization_id
    AND   msiv.attribute13                  =  cv_sales_car
    AND   xieh.order_connection_number      =  ooha.orig_sys_document_ref
    AND   xiel.edi_header_info_id           =  xieh.edi_header_info_id
    AND   xiel.order_connection_line_number =  oola.orig_sys_line_ref
    AND   xiel.hht_delivery_schedule_flag   =  cv_non_tran
    AND   xcac.customer_id(+)               =  oola.sold_to_org_id
/* 2009/07/08 Ver1.4 Add Start */
    AND   (
            ooha.global_attribute3          IS NULL
          OR
            ooha.global_attribute3          = cv_target_order_01
          )
/* 2009/07/08 Ver1.4 Add End   */
/* 2014/03/04 Ver1.7 Add Start */
    AND   ooha.ordered_date >=  gd_proc_date - gn_hht_deli_ord_keep_day + 1
    AND   ooha.ordered_date <   gd_proc_date + 1
/* 2014/03/04 Ver1.7 Add End */
    ORDER BY
          xieh.edi_header_info_id
        , xiel.line_no
    ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  g_h_handle       UTL_FILE.FILE_TYPE;
  g_l_handle       UTL_FILE.FILE_TYPE;
--
  TYPE g_rec_vndor_deli_l_rtype IS RECORD
    (
      delivery_base_code   xxcmm_cust_accounts.delivery_base_code%TYPE,    -- 拠点コード
      order_number         oe_order_headers_all.order_number%TYPE,         -- 受注No
      line_number          oe_order_lines_all.line_number%TYPE,            -- 行No
      conv_customer_code   xxcos_edi_headers.conv_customer_code%TYPE,      -- 顧客コード
      invoice_number       xxcos_edi_headers.invoice_number%TYPE,          -- 伝票番号
      ordered_item         oe_order_lines_all.ordered_item%TYPE,           -- 自社品名コード
      customer_item_number mtl_customer_items.customer_item_number%TYPE,   -- 他社品名コード
      customer_item_desc   mtl_customer_items.customer_item_desc%TYPE,     -- 他社品名
      quantity_sign        VARCHAR2(1),                                    -- 数量サイン（明細カテゴリコード）
      ordered_quantity     oe_order_lines_all.ordered_quantity%TYPE,       -- 数量
      unit_selling_price   oe_order_lines_all.unit_selling_price%TYPE,     -- 卸単価
      selling_price        xxcos_edi_lines.selling_price%TYPE,             -- 売単価
      edi_line_info_id     xxcos_edi_lines.edi_line_info_id%TYPE           -- 受注明細情報ID
    );
--
  TYPE g_tab_vndor_deli_l_ttype IS TABLE OF g_rec_vndor_deli_l_rtype INDEX BY PLS_INTEGER;
--
  gt_vndor_deli_lines         g_tab_vndor_deli_l_ttype; -- 納品明細ワークテーブル抽出データ
--
  /**********************************************************************************
   * Procedure Name   : log_output
   * Description      : ログ出力
   ***********************************************************************************/
  PROCEDURE log_output(
    iv_program      IN  VARCHAR2,            -- プログラム名
    iv_message      IN  VARCHAR2)            -- ユーザー・エラーメッセージ
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => iv_message
    );
--
    -- ログメッセージ生成
    lv_errbuf := SUBSTRB( cv_pkg_name||cv_msg_cont||iv_program||cv_msg_part||iv_message, 1, 5000 );
--
    -- ログ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
--
  END log_output;
--
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
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- プロファイル
    cv_prf_dir_path          CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';    -- HHTアウトバウンド用ディレクトリパス
    cv_prf_h_filename        CONSTANT VARCHAR2(50) := 'XXCOS1_EOS_HEADER_FILE_NAME';-- EOSヘッダファイル名
    cv_prf_l_filename        CONSTANT VARCHAR2(50) := 'XXCOS1_EOS_LINE_FILE_NAME';  -- EOS明細ファイル名
    cv_prf_org_id            CONSTANT VARCHAR2(50) := 'ORG_ID';                     -- MO:営業単位
    cv_prf_organization_code CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:在庫組織コード
/* 2014/03/04 Ver1.7 Add Start */
    cv_prof_ord_keep_day     CONSTANT VARCHAR2(50) := 'XXCOS1_HHT_DELI_ORD_KEEP_DAY';  -- XXCOS:HHT納品用受注保持日数
/* 2014/03/04 Ver1.7 Add End */
    -- クイックコードタイプ
    cv_qck_odr_src_mst_type  CONSTANT VARCHAR2(50) := 'XXCOS1_ODR_SRC_MST_003_A01'; -- 受注ソース特定タイプ
    cv_qck_odr_src_mst_code  CONSTANT VARCHAR2(50) := 'XXCOS_003_A01_01';           -- 受注ソース特定コード
    -- メッセージID
    cv_msg_no_parameter      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';           -- パラメータなし
    cv_msg_pro               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';           -- プロファイル取得エラー
    cv_msgfile_open          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';           -- ファイルオープンエラー
    cv_msg_mst_notfound      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10002';           -- マスタチェックエラーメッセージ
    cv_msg_lookup_value      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00046';           -- クイックコード
    cv_msg_order_source      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00158';           -- 受注ソース
    -- トークン
    cv_tkn_profile           CONSTANT VARCHAR2(20) := 'PROFILE';                    -- プロファイル名
    cv_tkn_file_name         CONSTANT VARCHAR2(20) := 'FILE_NAME';                  -- ファイル名
    cv_tkn_table             CONSTANT VARCHAR2(20) := 'TABLE';                      -- テーブル名
    cv_tkn_column            CONSTANT VARCHAR2(20) := 'COLMUN';                     -- カラム名
--
    -- *** ローカル変数 ***
    lv_dir_path              VARCHAR2(100);                                         -- HHTアウトバウンド用ディレクトリパス
    lv_h_filename            VARCHAR2(100);                                         -- EOSヘッダファイル名
    lv_l_filename            VARCHAR2(100);                                         -- EOS明細ファイル名
--
    -- *** ローカル・カーソル ***
    -- 受注ソースカーソル
    CURSOR order_source_cur
    IS
      SELECT  lup_values.meaning       meaning
      FROM    fnd_lookup_values        lup_values
      WHERE   lup_values.language      = cv_default_language
      AND     lup_values.enabled_flag  = cv_enabled
      AND     lup_values.lookup_type   = cv_qck_odr_src_mst_type
      AND     lup_values.lookup_code   = cv_qck_odr_src_mst_code
      AND     TRUNC(SYSDATE)
      BETWEEN lup_values.start_date_active
      AND     NVL(lup_values.end_date_active, TRUNC(SYSDATE));
--
    -- *** ローカル・レコード ***
    lt_order_source_rec      order_source_cur%ROWTYPE;                              -- EDI作成元区分カーソル レコード変数
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
--
    --==============================================================
    -- マルチバイトの固定値をメッセージより取得
    --==============================================================
    gv_msg_delivery_base_code   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_delivery_base_code
                                                           );
    gv_msg_order_number         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_order_number
                                                           );
    gv_msg_ordered_item         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_ordered_item
                                                           );
    gv_msg_customer_item_number := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_customer_item_number
                                                           );
    gv_msg_customer_item_desc   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_customer_item_desc
                                                           );
    gv_msg_ordered_quantity     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_ordered_quantity
                                                           );
    gv_msg_unit_selling_price   := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_unit_selling_price
                                                           );
    gv_msg_selling_price        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_selling_price
                                                           );
    gv_msg_tkn_lock_table       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lock_table
                                                           );
    gv_msg_tkn_dir_path         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );
    gv_msg_tkn_h_filename       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_h_filename
                                                           );
    gv_msg_tkn_l_filename       := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_l_filename
                                                           );
    gv_msg_tkn_h_file           := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_h_file
                                                           );
    gv_msg_tkn_l_file           := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_l_file
                                                           );
    gv_msg_tkn_org_id           := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_org_id
                                                           );
    gv_msg_tkn_organization_cd  := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_organization_cd
                                                           );
    gv_msg_tkn_update_table     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_update_table
                                                           );
    gv_msg_edi_line_id          := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_edi_line_id
                                                           );
/* 2014/03/04 Ver1.7 Add Start */
    gv_msg_tkn_ord_keep_day := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                       ,iv_name         => cv_msg_ord_keep_day
                                                           );
/* 2014/03/04 Ver1.7 Add End */
--
    --==============================================================
    -- プロファイルの取得(XXCOS:HHTアウトバウンド用ディレクトリパス)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);
--
    -- プロファイル取得エラーの場合
    IF (lv_dir_path IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:EOSヘッダファイル名)
    --==============================================================
    lv_h_filename := FND_PROFILE.VALUE(cv_prf_h_filename);
--
    -- プロファイル取得エラーの場合
    IF (lv_h_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_h_filename
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:EOS明細ファイル名)
    --==============================================================
    lv_l_filename := FND_PROFILE.VALUE(cv_prf_l_filename);
--
    -- プロファイル取得エラーの場合
    IF (lv_l_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_l_filename);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ファイル名のログ出力
    --==============================================================
    --EOSヘッダファイル名
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_h_filename
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
--
    --EOS明細ファイル名
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_l_filename
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
--
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
--
    --==============================================================
    -- EOSヘッダファイル ファイルオープン
    --==============================================================
    BEGIN
      g_h_handle := UTL_FILE.FOPEN(lv_dir_path
                                 , lv_h_filename
                                 , cv_file_access_mode);
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , gv_msg_tkn_h_file);
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- EOS明細ファイル ファイルオープン
    --==============================================================
    BEGIN
      g_l_handle := UTL_FILE.FOPEN(lv_dir_path, lv_l_filename, cv_file_access_mode);
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , gv_msg_tkn_l_file);
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- プロファイルの取得(MO:営業単位)
    --==============================================================
    gn_org_id := FND_PROFILE.VALUE(cv_prf_org_id);
--
    -- プロファイル取得エラーの場合
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_org_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(在庫組織コード)
    --==============================================================
    gv_organization_code := FND_PROFILE.VALUE(cv_prf_organization_code);
--
    -- プロファイル取得エラーの場合
    IF (gv_organization_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_organization_cd);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 受注ソース取得
    --==============================================================
    gv_edi_order_source := NULL;
    -- クイックコードから受注ソースを取得
    <<loop_set_order_source>>
    FOR lt_order_source_rec IN order_source_cur LOOP
      gv_edi_order_source := lt_order_source_rec.meaning;
    END LOOP;
--
    -- 受注ソースが取得できなかった場合
    IF ( gv_edi_order_source IS NULL ) THEN
      -- マスタチェックエラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_order_source );
      lv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_value );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application
                                           , cv_msg_mst_notfound
                                           , cv_tkn_column
                                           , lv_tkn1
                                           , cv_tkn_table
                                           , lv_tkn2 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2014/03/04 Ver1.7 Add Start */
    --==============================================================
    -- 業務日付取得
    --==============================================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    -- 業務日付が取得できない場合はエラー
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(cv_application
                                           , cv_msg_proc_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- HHT納品用受注保持日数
    --==============================================================
    gn_hht_deli_ord_keep_day := FND_PROFILE.VALUE( cv_prof_ord_keep_day );
    -- プロファイルが取得できない場合はエラー
    IF ( gn_hht_deli_ord_keep_day IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_ord_keep_day );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2014/03/04 Ver1.7 Add End */
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : proc_break_process
   * Description      : 受注ヘッダ情報IDブレイク後の処理（ファイル出力、ステータス更新）
   ***********************************************************************************/
  PROCEDURE proc_break_process(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_break_process'; -- プログラム名
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
    cn_lock_error_code   CONSTANT NUMBER := -54;
--
    -- *** ローカル変数 ***
    lv_edi_line_info_id      xxcos_edi_lines.edi_line_info_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** 例外処理 ***
    break_process_expt EXCEPTION;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- Loop2 明細
    -- ===============================
    <<lines_update_loop>>
    FOR i IN 1..gt_vndor_deli_lines.COUNT LOOP
      -- ===============================
      -- A-3 EDI明細情報テーブルレコードロック
      -- ===============================
      BEGIN
        SELECT xels.edi_line_info_id
        INTO   lv_edi_line_info_id
        FROM   xxcos_edi_lines xels
        WHERE  xels.edi_line_info_id = gt_vndor_deli_lines(i).edi_line_info_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_msg_tkn_lock_table
                                                 );
            -- ログ出力
            log_output( cv_prg_name, lv_errmsg );
          ELSE
            lv_errmsg  := NULL;
          END IF;
          RAISE break_process_expt;
      END;
--
      -- ===============================
      -- A-4 EDI明細情報テーブル出力済フラグ更新
      -- ===============================
      BEGIN
        UPDATE xxcos_edi_lines
        SET    hht_delivery_schedule_flag = cv_output_flag
              ,last_updated_by            = cn_last_updated_by
              ,last_update_date           = cd_last_update_date
              ,last_update_login          = cn_last_update_login
              ,request_id                 = cn_request_id
              ,program_application_id     = cn_program_application_id
              ,program_id                 = cn_program_id
              ,program_update_date        = cd_program_update_date
        WHERE  edi_line_info_id           = gt_vndor_deli_lines(i).edi_line_info_id
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                              -- エラー・メッセージ
                                          ,ov_retcode     => lv_retcode                             -- リターン・コード
                                          ,ov_errmsg      => lv_errmsg                              -- ユーザー・エラー・メッセージ
                                          ,ov_key_info    => gv_key_info                            -- キー情報
                                          ,iv_item_name1  => gv_msg_edi_line_id                     -- 項目名称1
                                          ,iv_data_value1 => gt_vndor_deli_lines(i).edi_line_info_id-- データの値1
                                          );
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                              , cv_msg_update_err
                                              , cv_tkn_table_name
                                              , gv_msg_tkn_update_table
                                              , cv_tkn_key_data
                                              , gv_key_info
                                              );
          -- ログ出力
          log_output( cv_prg_name, lv_errmsg );
          RAISE break_process_expt;
      END;
    END LOOP lines_update_loop;
--
      -- ===============================
      -- A-5 EOSヘッダファイルデータ出力
      -- ===============================
    BEGIN
      --データ編集
      gv_h_file_data :=        cv_quot || gv_delivery_base_code               || cv_quot--納品拠点コード
              || cv_delimit ||  TO_CHAR(gv_order_number)                                --受注No
              || cv_delimit || cv_quot || gv_conv_customer_code               || cv_quot--顧客コード
              || cv_delimit || cv_quot || gv_invoice_number                   || cv_quot--伝票番号
              || cv_delimit ||  TO_CHAR(gd_request_date,'YYYYMMDD')                     --納品日
              || cv_delimit || cv_quot || gv_big_classification_code          || cv_quot--売上分類区分
              || cv_delimit || cv_quot || gv_invoice_class                    || cv_quot--売上伝票区分
              || cv_delimit || cv_quot || gv_company_name_alt                 || cv_quot--社名（カナ）
              || cv_delimit || cv_quot || gv_shop_name_alt                    || cv_quot--店名（カナ）
              || cv_delimit || cv_quot || gv_edi_chain_code                   || cv_quot--チェーン店コード
      ;
      UTL_FILE.PUT_LINE(g_h_handle
                       ,gv_h_file_data
                       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        RAISE;
    END;
--
   --   ===============================
   --   Loop3 明細(ファイル)
   --   ===============================
    <<lins_out_loop>>
    FOR i IN 1..gt_vndor_deli_lines.COUNT LOOP
--
      -- ===============================
      -- A-6 EOS明細ファイルデータ出力
      -- ===============================
      BEGIN
        --データ編集
        gv_l_file_data :=        cv_quot || gt_vndor_deli_lines(i).delivery_base_code    || cv_quot --納品拠点コード
                || cv_delimit ||  gt_vndor_deli_lines(i).order_number                               --受注No
                || cv_delimit ||  gt_vndor_deli_lines(i).line_number                                --行No
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).conv_customer_code    || cv_quot --顧客コード
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).invoice_number        || cv_quot --伝票番号
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).ordered_item          || cv_quot --自社品名コード
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).customer_item_number  || cv_quot --他社品名コード
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).customer_item_desc    || cv_quot --他社品名
                || cv_delimit || cv_quot || gt_vndor_deli_lines(i).quantity_sign         || cv_quot --数量サイン
                || cv_delimit || TO_CHAR(gt_vndor_deli_lines(i).ordered_quantity, cv_number_format8)--数量
                || cv_delimit || TO_CHAR(gt_vndor_deli_lines(i).unit_selling_price, cv_number_format7)  --卸単価
                || cv_delimit || TO_CHAR(gt_vndor_deli_lines(i).selling_price)                      --売単価
        ;
        UTL_FILE.PUT_LINE(g_l_handle
                         ,gv_l_file_data
                         );
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          RAISE;
      END;
    END LOOP lins_out_loop;
--
    -- ===============================
    -- A-7 トランザクション制御
    -- ===============================
    COMMIT;
--
  EXCEPTION
    WHEN break_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ROLLBACK;
      -- 警告件数に明細数を加算
      gn_warn_cnt := gn_warn_cnt + gt_vndor_deli_lines.COUNT;
      ov_retcode  := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- 警告件数に明細数を加算
      gn_warn_cnt := gn_warn_cnt + gt_vndor_deli_lines.COUNT;
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  固定部 END   ##########################################
--
  END proc_break_process;
--
  /**********************************************************************************
   * Procedure Name   : proc_main_loop（ループ部）
   * Description      : A-2データ抽出
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- メインループ処理
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
    cn_max_val_order_number       NUMBER := 999999999;      -- 受注番号最大値
    cn_max_val_line_number        NUMBER := 999;            -- 明細番号最大値
    cn_max_len_ordered_item       NUMBER := 7;              -- 受注品目最大桁数
    cn_max_len_customer_item_num  NUMBER := 13;             -- 顧客品目コード最大桁数
    cn_max_len_customer_item_desc NUMBER := 15;             -- 顧客品目摘要最大桁数
    cn_max_val_ordered_quantity   NUMBER := 99999999.99;    -- 受注数量最大値
    cn_max_val_unit_selling_price NUMBER := 9999999.99;     -- 販売単価最大値
    cn_max_val_selling_price      NUMBER := 9999999;        -- 売単価最大値
    cn_max_len_invoice_number     NUMBER := 9;              -- 伝票番号最大桁数
    cn_cut_len_invoice_number     NUMBER := -9;             -- 伝票番号切り出し桁数（後ろ9桁）
--
    -- *** ローカル変数 ***
    lv_sign                VARCHAR2(1);
    lv_invoice_number      VARCHAR2(9);
    lv_item_name           VARCHAR2(20);
    lv_message_code        VARCHAR2(20);
    lv_item_value          VARCHAR2(100);
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
    lv_organization_id     VARCHAR2(10);                    -- 在庫組織ＩＤ
    lv_after_uom_code      VARCHAR2(10);                    -- 換算後単位コード
    ln_after_quantity      NUMBER;                          -- 換算後数量
    ln_content             NUMBER;                          -- 入数
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
/* 2015/01/08 Ver1.8 Add Start */
    ln_tmp_selling_price      xxcos_edi_lines.selling_price%TYPE;          -- 売単価(一時)
    ln_tmp_unit_selling_price oe_order_lines_all.unit_selling_price%TYPE;  -- 卸単価(一時)
/* 2015/01/08 Ver1.8 Add End */
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
    -- チェックステータス初期化
    gv_transaction_status := NULL;
    gn_edi_header_info_id := NULL;
--
    <<main_loop>>
    FOR main_rec in main_cur LOOP
--
      -- 対象件数をインクリメント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================
      -- 受注ヘッダ情報IDブレイク判定
      -- ===============================
      IF (gn_edi_header_info_id IS NULL                          -- メインループ初回
      OR main_rec.edi_header_info_id = gn_edi_header_info_id)    -- ブレイクしてない
      THEN
        NULL;
      ELSE
        -- 受注ヘッダ情報ID内にエラー無し
        IF (gv_transaction_status IS NULL) THEN
          proc_break_process(
             lv_errbuf   -- エラー・メッセージ           --# 固定 #
            ,lv_retcode  -- リターン・コード             --# 固定 #
            ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            --警告処理
            ov_retcode := lv_retcode;
          END IF;
--
        ELSE
          -- 警告件数にエラー明細数を加算
          gn_warn_cnt := gn_warn_cnt + gn_set_cnt;
--
        END IF;
--
        -- 設定カウンタ初期化
        gn_set_cnt := 0;
        -- PL/SQL表クリア
        gt_vndor_deli_lines.DELETE;
        -- 受注ヘッダ情報ID内のエラー判定ステータスの初期化
        gv_transaction_status := NULL;
      END IF;
--
--****************************** 2009/05/01 1.3 T.Kitajima MOD START ******************************--
--      BEGIN
--        SELECT mcis.customer_item_number
--              ,mcis.customer_item_desc
--        INTO   gv_customer_item_number
--              ,gv_customer_item_desc
--        FROM   mtl_customer_items              mcis                   -- 顧客品目
--              ,mtl_customer_item_xrefs         mcix                   -- 顧客品目相互参照
--              ,mtl_parameters                  mtpa
--              ,hz_cust_accounts                cust_acct              -- 顧客マスタ（10：顧客）
--              ,hz_cust_accounts                chain_acct             -- 顧客マスタ（18：チェーン店）
--              ,xxcmm_cust_accounts             cust_addon             -- 顧客アドオン（10：顧客）
--              ,xxcmm_cust_accounts             chain_addon            -- 顧客アドオン（18：チェーン店）
--        WHERE  mcix.inventory_item_id          =  main_rec.inventory_item_id
--        AND    mcix.customer_item_id           =  mcis.customer_item_id
--        AND    mcix.master_organization_id     =  mtpa.master_organization_id
--        AND    cust_addon.customer_id          =  main_rec.sold_to_org_id
--        AND    cust_addon.customer_id          =  cust_acct.cust_account_id
--        AND    cust_acct.customer_class_code   =  cv_cust_class_cust
--        AND    cust_addon.chain_store_code     =  chain_addon.chain_store_code
--        AND    chain_acct.cust_account_id      =  chain_addon.customer_id
--        AND    chain_acct.customer_class_code  =  cv_cust_class_chain
--        AND    mcis.customer_id                =  chain_addon.customer_id
--        AND    mcis.attribute1                 =  main_rec.order_quantity_uom
--        AND    mcis.item_definition_level      =  cv_customer
--        AND    mtpa.organization_code          =  gv_organization_code
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          gv_customer_item_number := NULL;
--          gv_customer_item_desc   := NULL;
--      END;
      gv_customer_item_number := main_rec.product_code2;
      gv_customer_item_desc   := main_rec.product_name_alt;
--****************************** 2009/05/01 1.3 T.Kitajima MOD  END  ******************************--
--
      -- ===============================
      -- A-10 データチェック
      -- ===============================
      BEGIN
        --------------------
        -- 必須チェック
        --------------------
        --拠点コード
        IF ( main_rec.delivery_base_code IS NULL ) THEN
          lv_message_code := cv_msg_notnull;
          lv_item_name    := gv_msg_delivery_base_code;
          lv_item_value   := main_rec.delivery_base_code; --必ずnullになるが、桁数チェックとパラメータを揃える為。
          RAISE global_data_check_expt;
        END IF;
--
        --------------------
        -- 桁数チェック
        --------------------
        -- 受注ヘッダテーブル：受注番号
        IF ( main_rec.order_number > cn_max_val_order_number ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_order_number;
          lv_item_value   := main_rec.order_number;
          RAISE global_data_check_expt;
        END IF;
--
        -- 受注明細テーブル：明細番号
        IF  (main_rec.line_number > cn_max_val_line_number ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_line_number;
          lv_item_value   := main_rec.line_number;
          RAISE global_data_check_expt;
        END IF;
--
        -- 受注明細テーブル：受注品目
        IF ( LENGTHB(main_rec.ordered_item) > cn_max_len_ordered_item ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_ordered_item;
          lv_item_value   := main_rec.ordered_item;
          RAISE global_data_check_expt;
        END IF;
--
        -- 顧客品目：顧客品目コード
        IF ( LENGTHB(gv_customer_item_number) > cn_max_len_customer_item_num ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_customer_item_number;
          lv_item_value   := gv_customer_item_number;
          RAISE global_data_check_expt;
        END IF;
--
        -- 顧客品目：顧客品目摘要
        IF ( LENGTHB(gv_customer_item_desc) > cn_max_len_customer_item_desc ) THEN
          lv_message_code := cv_msg_overflow;
          lv_item_name    := gv_msg_customer_item_desc;
          lv_item_value   := gv_customer_item_desc;
          RAISE global_data_check_expt;
        END IF;
--
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
        -- 受注数量の単位換算
        lv_organization_id := NULL;  --NULLを設定（共通関数内で導出）
        lv_after_uom_code  := NULL;  --換算後単位コードの初期化
/* 2015/01/08 Ver1.8 Add Start */
        ln_tmp_unit_selling_price := NULL;  --卸単価の初期化
        ln_tmp_selling_price      := NULL;  --売単価の初期化
/* 2015/01/08 Ver1.8 Add End */
        xxcos_common_pkg.get_uom_cnv(
                                     main_rec.order_quantity_uom,   -- 換算前単位コード
                                     main_rec.ordered_quantity,     -- 換算前数量
                                     main_rec.ordered_item,         -- 品目コード
                                     gv_organization_code,          -- 在庫組織コード
                                     main_rec.inventory_item_id,    -- 品目ID
                                     lv_organization_id,            -- 在庫組織ＩＤ
                                     lv_after_uom_code,             -- 換算後単位コード
                                     ln_after_quantity,             -- 換算後数量
                                     ln_content,                    -- 入数
                                     lv_errbuf,                     -- エラー･メッセージ
                                     lv_retcode,                    -- リターンコード
                                     lv_errmsg                      -- ユーザ･エラー･メッセージ
                                    );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_change_err_expt;
        END IF;
/* 2015/01/08 Ver1.8 Add Start */
        -- 換算前数量と換算後数量が異なる場合
        IF ( main_rec.ordered_quantity <> ln_after_quantity ) THEN
           ln_tmp_unit_selling_price := TRUNC(main_rec.unit_selling_price / ln_content, 2);--卸単価
           ln_tmp_selling_price      := TRUNC(main_rec.selling_price      / ln_content);   --売単価
        -- 換算前後で数量が等しい場合
        ELSE
           ln_tmp_unit_selling_price   := main_rec.unit_selling_price   ;--卸単価
           ln_tmp_selling_price        := main_rec.selling_price        ;--売単価
        END IF;
/* 2015/01/08 Ver1.8 Add End */
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
--
        -- 受注明細テーブル：受注数量
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--        IF ( main_rec.ordered_quantity > cn_max_val_ordered_quantity ) THEN
        IF ( ln_after_quantity > cn_max_val_ordered_quantity ) THEN
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
          lv_message_code := cv_msg_overflow;
          lv_item_name := gv_msg_ordered_quantity;
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--          lv_item_value   := main_rec.ordered_quantity;
          lv_item_value   := ln_after_quantity;
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
          RAISE global_data_check_expt;
        END IF;
--
        -- 受注明細テーブル：販売単価
/* 2015/01/08 Ver1.8 Mod Start */
--        IF ( main_rec.unit_selling_price > cn_max_val_unit_selling_price ) THEN
        IF ( ln_tmp_unit_selling_price > cn_max_val_unit_selling_price ) THEN
/* 2015/01/08 Ver1.8 Mod End */
          lv_message_code := cv_msg_overflow;
          lv_item_name := gv_msg_unit_selling_price;
          lv_item_value   := main_rec.unit_selling_price;
          RAISE global_data_check_expt;
        END IF;
--
        -- EDI明細情報テーブル：売単価
/* 2015/01/08 Ver1.8 Mod Start */
--        IF ( main_rec.selling_price > cn_max_val_selling_price ) THEN
        IF ( ln_tmp_selling_price > cn_max_val_selling_price ) THEN
/* 2015/01/08 Ver1.8 Mod End */
          lv_message_code := cv_msg_overflow;
          lv_item_name := gv_msg_selling_price;
          lv_item_value   := main_rec.selling_price;
          RAISE global_data_check_expt;
        END IF;
--
      EXCEPTION
        WHEN global_data_check_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                               ,lv_message_code
                                               ,cv_tkn_order_number
                                               ,main_rec.order_number
                                               ,cv_tkn_line_number
                                               ,main_rec.line_number
                                               ,cv_tkn_item_name
                                               ,lv_item_name
                                               ,cv_tkn_item_value
                                               ,lv_item_value
                                               );
                                               
          -- ログ出力
          log_output( cv_prg_name, lv_errmsg );
          ov_errmsg := lv_errmsg;
          ov_errbuf := lv_errmsg;
          gv_transaction_status := cv_error_status;
          ov_retcode  := cv_status_warn;
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD START ************************ --
        WHEN global_change_err_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                               ,cv_msg_change_err
                                               ,cv_tkn_order_number
                                               ,main_rec.order_number
                                               ,cv_tkn_line_number
                                               ,main_rec.line_number
                                               ,cv_tkn_err_msg
                                               ,lv_errmsg
                                               );
--
          -- ログ出力
          log_output( cv_prg_name, lv_errmsg );
          ov_errmsg := lv_errmsg;
          ov_errbuf := lv_errmsg;
          gv_transaction_status := cv_error_status;
          ov_retcode  := cv_status_warn;
--
          --空行
          FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                           ,buff   => ''
                           );
          FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                           ,buff   => ''
                           );
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 ADD  END  ************************ --
      END;
--
      -- ===============================
      -- A-8 EOS明細ファイル出力用に変数設定
      -- ===============================
      -- 数量サインの編集
      IF ( main_rec.line_category_code = cv_order ) THEN
        lv_sign := cv_brank;
      ELSE
        lv_sign := cv_minus;
      END IF;
--
      -- 伝票番号の編集
      IF ( LENGTHB(main_rec.invoice_number) > cn_max_len_invoice_number ) THEN
        -- 伝票番号が9桁超の場合は、末尾9桁分を出力
        lv_invoice_number := SUBSTRB( main_rec.invoice_number, cn_cut_len_invoice_number );
      ELSE
        -- 伝票番号が9桁以下の場合は、そのまま出力
        lv_invoice_number := main_rec.invoice_number;
      END IF;
--
      -- 設定カウンタをインクリメント
      gn_set_cnt := gn_set_cnt + 1;
--
      gt_vndor_deli_lines(gn_set_cnt).delivery_base_code   := main_rec.delivery_base_code   ;--拠点コード
      gt_vndor_deli_lines(gn_set_cnt).order_number         := main_rec.order_number         ;--受注No
      gt_vndor_deli_lines(gn_set_cnt).line_number          := main_rec.line_number          ;--行No
      gt_vndor_deli_lines(gn_set_cnt).conv_customer_code   := main_rec.conv_customer_code   ;--顧客コード
      gt_vndor_deli_lines(gn_set_cnt).invoice_number       := lv_invoice_number             ;--伝票番号
      gt_vndor_deli_lines(gn_set_cnt).ordered_item         := main_rec.ordered_item         ;--自社品名コード
      gt_vndor_deli_lines(gn_set_cnt).customer_item_number := gv_customer_item_number       ;--他社品名コード
      gt_vndor_deli_lines(gn_set_cnt).customer_item_desc   := gv_customer_item_desc         ;--他社品名
      gt_vndor_deli_lines(gn_set_cnt).quantity_sign        := lv_sign                       ;--数量サイン（明細カテゴリコード）
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD START ************************ --
--      gt_vndor_deli_lines(gn_set_cnt).ordered_quantity     := main_rec.ordered_quantity     ;--数量
      gt_vndor_deli_lines(gn_set_cnt).ordered_quantity     := ln_after_quantity             ;--数量
-- ************************ 2010/03/30 S.Miyakoshi Var1.6 MOD  END  ************************ --
/* 2015/01/08 Ver1.8 Mod Start */
--      gt_vndor_deli_lines(gn_set_cnt).unit_selling_price   := main_rec.unit_selling_price   ;--卸単価
--      gt_vndor_deli_lines(gn_set_cnt).selling_price        := main_rec.selling_price        ;--売単価
      gt_vndor_deli_lines(gn_set_cnt).unit_selling_price   := ln_tmp_unit_selling_price     ;--卸単価
      gt_vndor_deli_lines(gn_set_cnt).selling_price        := ln_tmp_selling_price          ;--売単価
/* 2015/01/08 Ver1.8 Mod End */
      gt_vndor_deli_lines(gn_set_cnt).edi_line_info_id     := main_rec.edi_line_info_id     ;--EDI明細情報ID
--
      --次ループ時に使用するためにヘッダファイル出力用に変数設定
      gv_delivery_base_code      := main_rec.delivery_base_code     ;--納品拠点コード
      gv_order_number            := main_rec.order_number           ;--受注No
      gv_conv_customer_code      := main_rec.conv_customer_code     ;--顧客コード
      gv_invoice_number          := lv_invoice_number               ;--伝票番号
      gd_request_date            := main_rec.request_date           ;--納品日
      gv_big_classification_code := main_rec.big_classification_code;--売上分類区分
      gv_invoice_class           := main_rec.invoice_class          ;--売上伝票区分
      gv_company_name_alt        := main_rec.company_name_alt       ;--社名（カナ）
      gv_shop_name_alt           := main_rec.shop_name_alt          ;--店名（カナ）
      gv_edi_chain_code          := main_rec.edi_chain_code         ;--チェーン店コード
      gn_edi_header_info_id      := main_rec.edi_header_info_id     ;--受注ヘッダ情報ID
    END LOOP main_loop;
--
  EXCEPTION
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_main_loop;

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
--
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
    gn_set_cnt    := 0;
--
    -- ===============================================
    -- 初期処理
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- Loop1 メイン A-2データ抽出
    -- ===============================
--
    proc_main_loop(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (gn_target_cnt > 0) THEN
--
      IF (lv_retcode != cv_status_normal) THEN
        -- リターンコード設定
        ov_retcode := lv_retcode;
      END IF;
--
      -- 受注ヘッダ情報ID内にエラー無し
      IF (gv_transaction_status IS NULL) THEN
--
        --(警告処理または正常処理)
        proc_break_process(
           lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,lv_retcode  -- リターン・コード             --# 固定 #
          ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        IF (lv_retcode != cv_status_normal) THEN
          -- リターンコード設定
          ov_retcode := lv_retcode;
        END IF;
--
      ELSE
          -- 警告件数にエラー明細数を加算
          gn_warn_cnt := gn_warn_cnt + gn_set_cnt;
--
      END IF;
--
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- 終了処理
    -- ===============================================
    --ファイルのクローズ
    UTL_FILE.FCLOSE(g_h_handle);
    UTL_FILE.FCLOSE(g_l_handle);
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
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
    --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
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
END XXCOS003A01C;
/
