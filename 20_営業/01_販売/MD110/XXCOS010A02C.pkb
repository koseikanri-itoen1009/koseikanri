CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A02C(body)
 * Description      : 受注OIFへの取込機能
 * MD.050           : 受注OIFへの取込(MD050_COS_010_A02)
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              初期処理(A-1)
 *  proc_get_edi_headers   EDIヘッダ情報テーブルデータ抽出(A-2)
 *  proc_data_validate_1   データ妥当性チェック1(A-3)
 *  proc_set_oif_headers   受注ヘッダOIF用変数格納(A-4)
 *  proc_get_edi_lines     EDI明細情報テーブルデータ抽出(A-5)
 *  proc_data_validate_2   データ妥当性チェック2(A-6)
 *  proc_set_oif_lines     受注明細OIF用変数格納(A-7)
 *  proc_set_oif_actions   受注処理OIF用変数格納(A-8)
 *  proc_upd_edi_headers   EDIヘッダ情報テーブル更新(A-9)
 *  proc_ins_oif_headers   受注ヘッダOIFテーブル登録(A-10)
 *  proc_ins_oif_lines     受注明細OIFテーブル登録(A-11)
 *  proc_ins_oif_actions   受注処理OIFテーブル登録(A-12)
 *  proc_end               終了処理(A-13)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   T.Oura           新規作成
 *  2009/02/05    1.1   M.Yamaki         [COS_033]通過在庫型区分参照バグの対応
 *                                       [COS_044]受注インポート連携不具合対応
 *  2009/02/10    1.2   T.Oura           [COS_046]受注OIF(ヘッダ、明細)のCONTEXT値設定対応
 *  2009/02/24    1.3   T.Nakamura       [COS_133]メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/04/15    1.4   T.Kitajima       [T1_0484]検索用拠点取得方法変更
 *                                       [T1_0469]受注明細OIF.顧客発注番号の編集修正
 *  2009/05/08    1.5   T.Kitajima       [T1_0780]価格計算フラグ設定方法変更
 *  2009/06/17    1.6   K.Kiriu          [T1_1462]ロック不備対応
 *  2009/07/01    1.7   M.Sano           [0000064]受注DFF項目追加に伴う、連携項目追加
 *  2009/08/04    1.7   M.Sano           [0000923]情報区分がNULL、01、02のみ対象とするように変更
 *  2009/11/05    1.8   N.Maeda          [E_T4_00081] 予定出荷日セット内容をNULLに変更
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  lock_expt                 EXCEPTION;       -- ロックエラー
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  data_lock_expt            EXCEPTION;       -- ロックエラー
  get_data_expt             EXCEPTION;       -- データ抽出エラー
  non_data_expt             EXCEPTION;       -- 対象データなしエラー
  ue_no_data_found          EXCEPTION;       -- 対象データ0件エラー
  upd_edi_headers_expt      EXCEPTION;       -- データ更新エラー
  ins_data_expt             EXCEPTION;       -- データ登録エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS010A02C';                 -- パッケージ名
  cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';                        -- アプリケーション名
  -- プロファイル
  cv_prf_operation_unit     CONSTANT VARCHAR2(50)  := 'XXCOS1_ITOE_OU_MFG';           -- MO:営業単位（ITOE-OU-MFG）
  -- 参照コード
  cv_order_class            CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ORDER_CLASS';       -- 受注データ(受注納品確定区分11,12,24)
  cv_delivered_class        CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DELIVERED_CLASS';   -- 納品確定データ(受注納品確定区分13)
  cv_err_item_type          CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';     -- EDI品目エラータイプ
  -- エラーコード
  cv_msg_order_source       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12004';             -- 受注ソース取得エラーメッセージ
  cv_msg_transaction_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12005';             -- 受注タイプ取得エラーメッセージ
  cv_msg_trans_line_type    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12006';             -- 受注明細タイプ取得エラーメッセージ
  cv_msg_sales_type         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12007';             -- 対象売上区分取得エラーメッセージ
  cv_msg_profile            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';             -- プロファイル取得エラーメッセージ
  cv_msg_getdata            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';             -- データ抽出エラーメッセージ
  cv_msg_nodata             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';             -- 対象データなしメッセージ
  cv_msg_lock               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';             -- ロックエラーメッセージ
  cv_msg_shop_code          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12001';             -- 店コードNULLメッセージ
  cv_msg_order_qty          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12002';             -- 発注数量NULLメッセージ
  cv_msg_order_price        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12003';             -- 発注単価NULLメッセージ
  cv_msg_insert             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';             -- データ登録エラーメッセージ
  cv_msg_update             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';             -- データ更新エラーメッセージ
  cv_msg_targetcnt          CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';             -- 対象件数メッセージ
  cv_msg_successcnt         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';             -- 成功件数メッセージ
  cv_msg_errorcnt           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';             -- エラー件数メッセージ
  cv_msg_normal             CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';             -- 正常終了メッセージ
  cv_msg_warning            CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';             -- 警告終了メッセージ
  cv_msg_error              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';             -- エラー終了全ロールバックメッセージ
  cv_msg_no_param           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';             -- コンカレント入力パラメータなし
--
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(20)  := 'PROFILE';                      -- プロファイル
  cv_tkn_column             CONSTANT VARCHAR2(20)  := 'COLUMN';                       -- 項目名
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';                        -- テーブル名
  cv_tkn_order_no           CONSTANT VARCHAR2(20)  := 'ORDER_NO';                     -- 伝票番号
  cv_tkn_line_no            CONSTANT VARCHAR2(20)  := 'LINE_NO';                      -- 行番号
  cv_tkn_table_name         CONSTANT VARCHAR2(20)  := 'TABLE_NAME';                   -- テーブル名
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';                     -- キー情報
  cv_tkn_count              CONSTANT VARCHAR2(20)  := 'COUNT';                        -- 対象件数
--
  cv_edi_header_tab         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';             -- EDIヘッダ情報テーブル
  cv_oif_headers_tab        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00132';             -- 受注ヘッダーOIF
  cv_oif_lines_tab          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00133';             -- 受注明細OIF
  cv_oif_actions_tab        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00134';             -- 受注処理OIF
  -- クイックコードタイプ
  cv_qck_type               CONSTANT VARCHAR2(50)  := 'XXCOS1_ODR_SRC_MST_010_A02';   -- タイプ
  cv_qck_code               CONSTANT VARCHAR2(50)  := 'XXCOS_010_A02_01';             -- コード
  cv_qck_type_2             CONSTANT VARCHAR2(50)  := 'XXCOS1_TXN_TYPE_MST_010_A02';  -- タイプ
  cv_qck_code_3             CONSTANT VARCHAR2(50)  := 'XXCOS_010_A02_02';             -- コード
  cv_qck_type_3             CONSTANT VARCHAR2(50)  := 'XXCOS1_SALE_CLASS';            -- タイプ
  cv_qck_code_2             CONSTANT VARCHAR2(50)  := '1';                              -- コード
  cv_qck_type_4             CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_CREATE_CLASS';      -- タイプ
  cv_qck_code_4             CONSTANT VARCHAR2(50)  := '10';                             -- コード
  cv_qck_code_5             CONSTANT VARCHAR2(50)  := '20';                             -- コード
  -- その他定数
  cv_order_forward_flag     CONSTANT VARCHAR2(10)  := 'N';                            -- 受注連携済フラグ(N)
  cv_cust_class_18          CONSTANT VARCHAR2(10)  := '18';                             -- 顧客区分(チェーン店)
  cv_cust_class_10          CONSTANT VARCHAR2(10)  := '10';                             -- 顧客区分(顧客)
-- 2009/08/04 Ver.1.7 M.Sano add Start
--  cv_info_class_10          CONSTANT VARCHAR2(10)  := '10';                             -- 情報区分
  cv_info_class_01          CONSTANT VARCHAR2(10)  := '01';                             -- 情報区分(作成対象)
  cv_info_class_02          CONSTANT VARCHAR2(10)  := '02';                             -- 情報区分(作成対象)
-- 2009/08/04 Ver.1.7 M.Sano add End
  cv_creat_class_order      CONSTANT VARCHAR2(10)  := '01';                             -- 作成元区分(受注データ)
  cv_tsukagatazaiko_11      CONSTANT VARCHAR2(10)  := '11';                             -- 通貨在庫型区分
  cv_tsukagatazaiko_12      CONSTANT VARCHAR2(10)  := '12';                             -- 通貨在庫型区分
  cv_tsukagatazaiko_24      CONSTANT VARCHAR2(10)  := '24';                             -- 通貨在庫型区分
  cv_data_type_code_11      CONSTANT VARCHAR2(10)  := '11';                             -- データ種コード
  cv_creat_class_deliv      CONSTANT VARCHAR2(10)  := '02';                             -- 作成元区分(納品確定データ)
  cv_tsukagatazaiko_13      CONSTANT VARCHAR2(10)  := '13';                             -- 通貨在庫型区分
  cv_data_type_code_31      CONSTANT VARCHAR2(10)  := '31';                             -- データ種コード
--
  cv_trans_type_code        CONSTANT VARCHAR2(50)  := 'ORDER';                        -- 取引タイプコード
  cv_order_category         CONSTANT VARCHAR2(50)  := 'MIXED';                        -- 受注カテゴリ
  cv_book_order             CONSTANT VARCHAR2(50)  := 'BOOK_ORDER';                   -- オペレーションコード「記帳」
  cv_language               CONSTANT VARCHAR2(50)  := USERENV('lang');                -- 言語 
  cv_trans_type_code_2      CONSTANT VARCHAR2(50)  := 'LINE';                         -- 取引タイプコード(明細)
  cv_order_category_2       CONSTANT VARCHAR2(50)  := 'ORDER';                        -- 受注カテゴリ
--
  cv_order_forward_flag_y   CONSTANT VARCHAR2(10)  := 'Y';                            -- 受注連携済フラグ(Y)
  cv_dummy_item_flg_n       CONSTANT VARCHAR2(10)  := 'N';                            -- ダミー品目コード
--
  cv_no_target_cnt          CONSTANT NUMBER        :=  0;                             -- 抽出対象データ0件
  cv_flg_y                  CONSTANT VARCHAR2(10)  := 'Y';                            -- 'Y'
  cv_flg_n                  CONSTANT VARCHAR2(10)  := 'N';                            -- 'N'
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  gv_operation_unit                  fnd_profile_option_values.profile_option_value%TYPE;   -- 営業単位
  gv_order_source_id                 VARCHAR2(100);                                         -- 受注インポートソース
  gv_transaction_type_id             VARCHAR2(100);                                         -- 取引タイプID
  gv_name_h                          VARCHAR2(100);                                         -- 取引タイプ名称（ヘッダ）
  gv_trans_line_type_id              VARCHAR2(100);                                         -- 取引明細タイプID
  gv_name_l                          VARCHAR2(100);                                         -- 取引明細タイプ名称（明細）
  gv_sales_type                      VARCHAR2(100);                                         -- 売上区分
  gn_idx                             NUMBER;                                                -- カーソル変数（ヘッダ用）
  gn_l_idx                           NUMBER;                                                -- カーソル変数（明細用）
  gn_ac_idx                          NUMBER;                                                -- カーソル変数（受注処理用）
  gv_dummy_item_flg                  VARCHAR2(100);                                         -- ダミー品目
  gn_org_id                          NUMBER;                                                -- 営業単位ID
  gn_l_target_cnt                    NUMBER;                                                -- 対象件数（明細用）
  gn_l_idx_all                       NUMBER;                                                -- 対象件数（明細用）
  -- メッセージ用
  gv_edi_header_tab                  VARCHAR2(100);                                         -- APP-XXCOS1-00114
  -- EDIヘッダ連携済フラグ更新用変数
  gv_edi_forward_flag                VARCHAR2(100);
--
  -- EDIヘッダ情報テーブルカーソル
  CURSOR edi_headers_cur
  IS
  SELECT   xeh.edi_header_info_id            edi_header_info_id             -- EDIヘッダ情報ID
         , xeh.conv_customer_code            conv_customer_code             -- 変換後顧客コード
         , xeh.edi_chain_code                edi_chain_code                 -- EDIチェーン店コード
         , xeh.shop_code                     shop_code                      -- 店コード
         , xeh.invoice_number                invoice_number                 -- 伝票番号
         , xeh.order_date                    order_date                     -- 発注日
         , xeh.price_list_header_id          price_list_header_id           -- 価格表ヘッダID
         , xeh.order_connection_number       order_connection_number        -- 受注関連番号
         , xeh.order_forward_flag            order_forward_flag             -- 受注連携済フラグ
         , xeh.shop_delivery_date            shop_delivery_date             -- 店舗納品日
         , xeh.creation_date                 creation_date                  -- 作成日
         , xeh.center_delivery_date          center_delivery_date           -- センター納品日
         , xeh.creation_class                creation_class                 -- 作成元区分
         , xca.ship_storage_code             ship_storage_code              -- 出荷元保管場所(EDI)
         , CASE
--****************************** 2009/04/15 1.4 T.Kitajima ADD START ******************************--
             WHEN (xca.rsv_sale_base_act_date IS NULL ) THEN
               xca.sale_base_code
--****************************** 2009/04/15 1.4 T.Kitajima ADD  END  ******************************--
             WHEN (xca.rsv_sale_base_act_date <= xeh.order_date ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
             END                             sale_base_code                 -- 売上拠点コード
         , xca.tsukagatazaiko_div            tsukagatazaiko_div             -- 通過在庫型区分（EDI）
-- 2009/07/01 Ver.1.7 M.Sano add Start
         , xeh.info_class                    info_class                     -- 情報区分
         , xeh.invoice_class                 invoice_class                  -- 伝票区分
         , xeh.big_classification_code       big_classification_code        -- 大分類コード
-- 2009/07/01 Ver.1.7 M.Sano add End
  FROM     xxcos_edi_headers     xeh                                        -- EDIヘッダ情報テーブル
         , hz_cust_accounts      hca                                        -- 顧客マスタ
         , xxcmm_cust_accounts   xca                                        -- 顧客追加情報
         , xxcos_lookup_values_v xlvv                                       -- クイックコード
         , xxcos_lookup_values_v xlvv2                                      -- クイックコード
  WHERE    xeh.order_forward_flag    =  cv_order_forward_flag
  AND     (( xeh.info_class          IS NULL )
-- 2009/08/04 Ver.1.7 M.Sano mod Start
--  OR       ( xeh.info_class          = cv_info_class_10  ))
  OR       ( xeh.info_class          IN (cv_info_class_01,
                                         cv_info_class_02 ) ) )
-- 2009/08/04 Ver.1.7 M.Sano mod End
  AND      hca.account_number        =  xeh.conv_customer_code
  AND      hca.cust_account_id       =  xca.customer_id
  AND      hca.customer_class_code   = cv_cust_class_10
  AND     ((    xeh.creation_class        = xlvv2.meaning
          AND  xlvv.lookup_type           = cv_order_class
          AND  xca.tsukagatazaiko_div     = xlvv.meaning                    -- 参照タイプコード
          AND  xeh.data_type_code         = cv_data_type_code_11
          AND  xlvv2.lookup_type          = cv_qck_type_4
          AND  xlvv2.lookup_code          = cv_qck_code_4)
          OR
          (    xeh.creation_class         = xlvv2.meaning
          AND  xlvv.lookup_type           = cv_delivered_class
          AND  xca.tsukagatazaiko_div     = xlvv.meaning                    -- 参照タイプコード
          AND  xeh.data_type_code         = cv_data_type_code_31
          AND  xlvv2.lookup_type          = cv_qck_type_4
          AND  xlvv2.lookup_code          = cv_qck_code_5))
    ORDER BY
      xeh.invoice_number
/* 2009/06/17 Ver1.6 Mod Start */
--    FOR UPDATE NOWAIT;
    FOR UPDATE OF
      xeh.edi_header_info_id NOWAIT;
/* 2009/06/17 Ver1.6 Mod End   */
--
  -- EDIヘッダ情報テーブル テーブルタイプ定義
  TYPE  g_tab_edi_headers                IS TABLE OF edi_headers_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- EDIヘッダ情報テーブル用変数（カーソルレコード型）
  gt_edi_headers                          g_tab_edi_headers;
--
    -- EDI明細情報テーブルカーソル
    CURSOR edi_lines_cur ( gn_l_idx NUMBER )
    IS
      SELECT   xel.line_no            line_no                  -- 行No
             , xel.item_code          item_code                -- 品目コード
             , xel.line_uom           line_uom                 -- 明細単位
             , xel.sum_order_qty      sum_order_qty            -- 発注数量(合計、バラ)
             , xel.order_unit_price   order_unit_price         -- 原単価(発注)
             , NVL2(xlvv.lookup_code
                  , cv_flg_y
                  , cv_flg_n        ) err_item_flg             -- エラー品目フラグ
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
             , xel.taking_unit_price  taking_unit_price        -- 取込時原単価（発注）
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
      FROM     xxcos_edi_lines       xel                       -- EDI明細情報テーブル
             , xxcos_lookup_values_v xlvv                      -- クイックコード(エラー品目)
      WHERE    xel.edi_header_info_id    =  gt_edi_headers ( gn_idx ).edi_header_info_id
        AND    xel.item_code             =  xlvv.lookup_code (+)
        AND    cv_err_item_type          =  xlvv.lookup_type (+);
--
  -- EDI明細情報テーブル テーブルタイプ定義
  TYPE  g_tab_edi_lines                  IS TABLE OF edi_lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
--
  -- EDI明細情報テーブル用変数（カーソルレコード型）
  gt_edi_lines                            g_tab_edi_lines;
--
  -- 受注ヘッダOIFテーブルレコードタイプ定義
  TYPE g_rec_order_oif_header  IS RECORD
    (
      order_source_id               oe_headers_iface_all.order_source_id%TYPE,            -- インポートソースID
      order_source                  oe_headers_iface_all.order_source%TYPE,               -- インポートソース名
      orig_sys_document_ref         oe_headers_iface_all.orig_sys_document_ref%TYPE,      -- 外部システム受注番号
      customer_po_number            oe_headers_iface_all.customer_po_number%TYPE,         -- 顧客発注番号
      ordered_date                  oe_headers_iface_all.ordered_date%TYPE,               -- 受注日
      order_type_id                 oe_headers_iface_all.order_type_id%TYPE,              -- 受注タイプID
      order_type                    oe_headers_iface_all.order_type%TYPE,                 -- 受注タイプ名
      org_id                        oe_headers_iface_all.org_id%TYPE,                     -- 営業単位ID
      order_category                oe_headers_iface_all.order_category%TYPE,             -- 受注カテゴリ
      price_list_id                 oe_headers_iface_all.price_list_id%TYPE,              -- 価格表ID
      price_list                    oe_headers_iface_all.price_list%TYPE,                 -- 価格表名
      salesrep                      oe_headers_iface_all.salesrep%TYPE,                   -- 営業担当
      payment_term_id               oe_headers_iface_all.payment_term_id%TYPE,            -- 支払方法ID
      payment_term                  oe_headers_iface_all.payment_term%TYPE,               -- 支払方法
      customer_id                   oe_headers_iface_all.customer_id%TYPE,                -- 顧客ID
      customer_number               oe_headers_iface_all.customer_number%TYPE,            -- 顧客コード
      customer_name                 oe_headers_iface_all.customer_name%TYPE,              -- 顧客名
      context                       oe_headers_iface_all.context%TYPE                    -- コンテキスト
    );
--
  -- 受注明細OIFテーブルレコードタイプ定義
  TYPE g_rec_order_oif_line  IS RECORD
    (
      order_source_id               oe_lines_iface_all.order_source_id%TYPE,              -- インポートソースID
      inventory_item                oe_lines_iface_all.inventory_item%TYPE,               -- 受注品目
      ordered_quantity              oe_lines_iface_all.ordered_quantity%TYPE,             -- 受注数量
      order_quantity_uom            oe_lines_iface_all.order_quantity_uom%TYPE,           -- 受注単位
      unit_selling_price            oe_lines_iface_all.unit_selling_price%TYPE,           -- 販売単価
      request_date                  oe_lines_iface_all.request_date%TYPE,                 -- 要求日
      schedule_ship_date            oe_lines_iface_all.schedule_ship_date%TYPE,           -- 予定出荷日
      customer_po_number            oe_lines_iface_all.customer_po_number%TYPE,           -- 顧客発注番号
      customer_line_number          oe_lines_iface_all.customer_line_number%TYPE,         -- 顧客発注明細番号
      orig_sys_document_ref         oe_lines_iface_all.orig_sys_document_ref%TYPE,        -- 外部システム受注番号
      orig_sys_line_ref             oe_lines_iface_all.orig_sys_line_ref%TYPE,            -- 外部システム受注明細番号
      line_type_id                  oe_lines_iface_all.line_type_id%TYPE,                 -- 明細タイプID
      attribute5                    oe_lines_iface_all.attribute5%TYPE,                   -- 売上区分
      context                       oe_lines_iface_all.context%TYPE                       -- コンテキスト
      );
--
  -- 受注処理OIFテーブルレコードタイプ定義
  TYPE g_rec_order_oif_actions  IS RECORD
    (
      order_source_id               oe_actions_iface_all.order_source_id%TYPE,            -- インポートソースID
      orig_sys_document_ref         oe_actions_iface_all.orig_sys_document_ref%TYPE,      -- 外部システム受注番号
      operation_code                oe_actions_iface_all.operation_code%TYPE              -- オペレーションコード
      );
--
  -- EDIヘッダ情報テーブルレコードタイプ定義(EDIヘッダ情報ID)
  TYPE g_rec_edi_forward_flag  IS RECORD
    (
      edi_header_info_id                 xxcos_edi_headers.edi_header_info_id%TYPE             -- EDIヘッダ情報ID
      );
--
  TYPE g_order_oif_header                IS TABLE OF g_rec_order_oif_header;
--
  TYPE g_order_oif_line                  IS TABLE OF g_rec_order_oif_line;
--
  TYPE g_order_oif_actions               IS TABLE OF g_rec_order_oif_actions;
--
  TYPE g_edi_forward_flag                IS TABLE OF g_rec_edi_forward_flag;
--
  -- 受注ヘッダOIFテーブル用変数
  gt_order_oif_header                     g_order_oif_header;
  -- 受注明細OIFテーブル用変数
  gt_order_oif_line                       g_order_oif_line;
  -- 受注処理OIFテーブル用変数
  gt_order_oif_actions                    g_order_oif_actions;
  -- EDI連携フラグ更新用変数
  gt_edi_forward_flag                     g_edi_forward_flag;
--
  -- 受注ヘッダOIF テーブルタイプ定義
  TYPE  g_tab_order_source_id            IS TABLE OF oe_headers_iface_all.order_source_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- インポートソースID
  TYPE  g_tab_orig_sys_document_ref      IS TABLE OF oe_headers_iface_all.orig_sys_document_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 外部システム受注番号
  TYPE  g_tab_customer_po_number_h       IS TABLE OF oe_headers_iface_all.customer_po_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 顧客発注番号
  TYPE  g_tab_ordered_date               IS TABLE OF oe_headers_iface_all.ordered_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 受注日
  TYPE  g_tab_order_type_id              IS TABLE OF oe_headers_iface_all.order_type_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 受注タイプID
  TYPE  g_tab_org_id                     IS TABLE OF oe_headers_iface_all.org_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 営業単位ID
  TYPE  g_tab_price_list_id              IS TABLE OF oe_headers_iface_all.price_list_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 価格表ID
  TYPE  g_tab_customer_number            IS TABLE OF oe_headers_iface_all.customer_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 顧客コード
  TYPE  g_tab_request_date               IS TABLE OF oe_headers_iface_all.request_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 要求日
  TYPE  g_tab_sale_base_code             IS TABLE OF oe_headers_iface_all.attribute12%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 売上拠点コード
  TYPE  g_tab_name_h                     IS TABLE OF oe_headers_iface_all.context%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 取引タイプ名称
-- 2009/07/01 Ver.1.7 M.Sano mod Start
  TYPE  g_tab_h_global_attribute3        IS TABLE OF oe_headers_iface_all.global_attribute3%TYPE  -- 情報区分
    INDEX BY PLS_INTEGER;
  TYPE  g_tab_h_attribute5               IS TABLE OF oe_headers_iface_all.attribute5%TYPE  -- 伝票区分
    INDEX BY PLS_INTEGER;
  TYPE  g_tab_h_attribute20              IS TABLE OF oe_headers_iface_all.attribute20%TYPE -- 分類区分
    INDEX BY PLS_INTEGER;
-- 2009/07/01 Ver.1.7 M.Sano mod End
  -- 受注明細OIF テーブルタイプ定義
  TYPE  g_tab_order_source_id_l          IS TABLE OF oe_lines_iface_all.order_source_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- インポートソースID
  TYPE  g_tab_inventory_item             IS TABLE OF oe_lines_iface_all.inventory_item%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 受注品目
  TYPE  g_tab_ordered_quantity           IS TABLE OF oe_lines_iface_all.ordered_quantity%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 受注数量
  TYPE  g_tab_order_quantity_uom         IS TABLE OF oe_lines_iface_all.order_quantity_uom%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 受注単位
  TYPE  g_tab_unit_selling_price         IS TABLE OF oe_lines_iface_all.unit_selling_price%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 販売単価
  TYPE  g_tab_request_date_l             IS TABLE OF oe_lines_iface_all.request_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 要求日
  TYPE  g_tab_schedule_ship_date         IS TABLE OF oe_lines_iface_all.schedule_ship_date%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 予定出荷日
  TYPE  g_tab_customer_po_number_l       IS TABLE OF oe_lines_iface_all.customer_po_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 顧客発注番号
  TYPE  g_tab_customer_line_number       IS TABLE OF oe_lines_iface_all.customer_line_number%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 顧客発注明細番号
  TYPE  g_tab_orig_sys_document_ref_l    IS TABLE OF oe_lines_iface_all.orig_sys_document_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 外部システム受注番号
  TYPE  g_tab_orig_sys_line_ref          IS TABLE OF oe_lines_iface_all.orig_sys_line_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 外部システム受注明細番号
  TYPE  g_tab_line_type_id               IS TABLE OF oe_lines_iface_all.line_type_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 明細タイプID
  TYPE  g_tab_attribute5                 IS TABLE OF oe_lines_iface_all.attribute5%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 売上区分
  TYPE  g_tab_name_l                     IS TABLE OF oe_lines_iface_all.context%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 取引明細タイプ名称
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
  TYPE  g_tab_calculate_price_flag       IS TABLE OF oe_lines_iface_all.calculate_price_flag%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 価格計算フラグ
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
  -- 受注処理OIF テーブルタイプ定義
  TYPE  g_tab_order_source_id_ac         IS TABLE OF oe_actions_iface_all.order_source_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- インポートソースID
  TYPE  g_tab_orig_sys_document_ref_ac   IS TABLE OF oe_actions_iface_all.orig_sys_document_ref%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- 外部システム受注番号
  TYPE  g_tab_operation_code_ac          IS TABLE OF oe_actions_iface_all.operation_code%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- オペレーションコード
  -- EDIヘッダ情報テーブル テーブルタイプ定義
  TYPE  g_tab_edi_header_info_id         IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE
    INDEX BY PLS_INTEGER;                                                                         -- EDIヘッダ情報ID
--
  -- 受注ヘッダOIFインサート用変数
  gt_order_source_id                      g_tab_order_source_id;             -- インポートソースID
  gt_orig_sys_document_ref                g_tab_orig_sys_document_ref;       -- 外部システム受注番号
  gt_customer_po_number_h                 g_tab_customer_po_number_h;        -- 顧客発注明細番号
  gt_ordered_date                         g_tab_ordered_date;                -- 受注日
  gt_order_type_id                        g_tab_order_type_id;               -- 受注タイプID
  gt_org_id                               g_tab_org_id;                      -- 営業単位ID
  gt_price_list_id                        g_tab_price_list_id;               -- 価格表ID
  gt_customer_number                      g_tab_customer_number;             -- 顧客コード
  gt_request_date                         g_tab_request_date;                -- 要求日
  gt_sale_base_code                       g_tab_sale_base_code;              -- 売上拠点コード
  gt_name_h                               g_tab_name_h;                      -- 取引タイプ名称
-- 2009/07/01 Ver.1.7 M.Sano mod Start
  gt_h_global_attribute3                   g_tab_h_global_attribute3;         -- 情報区分
  gt_h_attribute5                          g_tab_h_attribute5;                -- 伝票区分
  gt_h_attribute20                         g_tab_h_attribute20;               -- 大分類コード
-- 2009/07/01 Ver.1.7 M.Sano mod End
--
  -- 受注明細OIFインサート用変数
  gt_order_source_id_l                    g_tab_order_source_id_l;           -- インポートソースID
  gt_inventory_item                       g_tab_inventory_item;              -- 受注品目
  gt_ordered_quantity                     g_tab_ordered_quantity;            -- 受注数量
  gt_order_quantity_uom                   g_tab_order_quantity_uom;          -- 受注単位
  gt_unit_selling_price                   g_tab_unit_selling_price;          -- 販売単価
  gt_request_date_l                       g_tab_request_date_l;              -- 要求日
  gt_schedule_ship_date                   g_tab_schedule_ship_date;          -- 予定出荷日
  gt_customer_po_number_l                 g_tab_customer_po_number_l;        -- 顧客発注番号
  gt_customer_line_number                 g_tab_customer_line_number;        -- 顧客発注明細番号
  gt_orig_sys_document_ref_l              g_tab_orig_sys_document_ref_l;     -- 外部システム受注番号
  gt_orig_sys_line_ref                    g_tab_orig_sys_line_ref;           -- 外部システム受注明細番号
  gt_line_type_id                         g_tab_line_type_id;                -- 明細タイプID
  gt_attribute5                           g_tab_attribute5;                  -- 売上区分
  gt_name_l                               g_tab_name_l;                      -- 取引明細タイプ名称
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
  gt_calculate_price_flag                 g_tab_calculate_price_flag;        -- 価格計算フラグ
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
--
  -- 受注処理OIFインサート用変数
  gt_order_source_id_ac                   g_tab_order_source_id_ac;          -- インポートソースID
  gt_orig_sys_document_ref_ac             g_tab_orig_sys_document_ref_ac;    -- 外部システム受注番号
  gt_operation_code_ac                    g_tab_operation_code_ac;           -- オペレーションコード
--
  -- 受注連携フラグ更新用変数
  gt_edi_header_info_id                   g_tab_edi_header_info_id;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_msg_output
   * Description      : メッセージ、ログ出力
   ***********************************************************************************/
  PROCEDURE proc_msg_output(
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
  END proc_msg_output;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';           -- プログラム名
    cv_appl_short_name_ccp CONSTANT VARCHAR2(10)  := 'XXCCP';      -- アドオン：共通・IF領域
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
    lv_order_source_id        VARCHAR2(100);   -- インポートソースID
    lv_name                   VARCHAR2(100);   -- インポートソース名
    lv_transaction_type_id    VARCHAR2(100);   -- 取引タイプID
    lv_name_h                 VARCHAR2(100);   -- 取引タイプ名称（ヘッダ）
    lv_trans_line_type_id     VARCHAR2(100);   -- 取引明細タイプID
    lv_name_l                 VARCHAR2(100);   -- 取引明細タイプ名称（明細）
    lv_sales_type             VARCHAR2(100);   -- 売上区分 
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    -- 変数初期化
    gv_operation_unit      := NULL;
--
   -- ==============================================================
    -- コンカレント入力パラメータなしメッセージ出力
   -- ==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name_ccp
                    , iv_name        => cv_msg_no_param
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
    );
--
    -- ==============================================================
    -- 受注インポートソース情報取得
    -- ==============================================================
    BEGIN
--
      SELECT   oos.order_source_id  order_source_id      -- インポートソースID
             , oos.name             name                 -- インポートソース名
      INTO     lv_order_source_id
             , lv_name
      FROM     oe_order_sources      oos                 -- 受注ソース
             , xxcos_lookup_values_v flv                 -- クイックコード
      WHERE    oos.name          =  flv.meaning
      AND      flv.lookup_type   =  cv_qck_type
      AND      flv.lookup_code   =  cv_qck_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_source
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_order_source_id  :=  lv_order_source_id;
--
    -- ==============================================================
    -- 受注タイプ情報取得
    -- ==============================================================
    BEGIN
--
      SELECT   otta.transaction_type_id  transaction_type_id      -- 取引タイプID
             , ottt.name                 name_h                   -- 取引タイプ名称
      INTO     lv_transaction_type_id
             , lv_name_h
      FROM     oe_transaction_types_all  otta                     -- 受注取引タイプ
             , oe_transaction_types_tl   ottt                     -- 受注取引タイプ（摘要）
             , xxcos_lookup_values_v     flv                      -- クイックコード
      WHERE    otta.transaction_type_id     =  ottt.transaction_type_id
      AND      otta.transaction_type_code   =  cv_trans_type_code
      AND      otta.order_category_code     =  cv_order_category
      AND      ottt.name                    =  flv.meaning
      AND      ottt.language                =  cv_language
      AND      flv.lookup_type              =  cv_qck_type_2
      AND      flv.lookup_code              =  cv_qck_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_transaction_type
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_transaction_type_id  :=  lv_transaction_type_id;
    gv_name_h               :=  lv_name_h;
--
    -- ==============================================================
    -- 受注明細タイプ情報取得
    -- ==============================================================
    BEGIN
--
      SELECT   otta.transaction_type_id  trans_line_type_id       -- 取引明細タイプID
             , ottt.name                 name_l                   -- 取引明細タイプ名称
      INTO     lv_trans_line_type_id
             , lv_name_l
      FROM     oe_transaction_types_all  otta                     -- 受注取引タイプ
             , oe_transaction_types_tl   ottt                     -- 受注取引タイプ（摘要）
             , xxcos_lookup_values_v     flv                      -- クイックコード
      WHERE    otta.transaction_type_id     =  ottt.transaction_type_id
      AND      otta.transaction_type_code   =  cv_trans_type_code_2
      AND      otta.order_category_code     =  cv_order_category_2
      AND      ottt.name                    =  flv.meaning
      AND      ottt.language                =  cv_language
      AND      flv.lookup_type              =  cv_qck_type_2
      AND      flv.lookup_code              =  cv_qck_code_3;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_trans_line_type
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_trans_line_type_id  :=  lv_trans_line_type_id;
    gv_name_l              :=  lv_name_l;
--
    -- ==============================================================
    -- 売上区分情報取得
    -- ==============================================================
    BEGIN
--
      SELECT   flv.lookup_code    sales_type                     -- 売上区分
      INTO     lv_sales_type
      FROM     xxcos_lookup_values_v  flv                        -- クイックコード
      WHERE    flv.lookup_type      =  cv_qck_type_3
      AND      flv.lookup_code      =  cv_qck_code_2;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_sales_type
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
--
    END;
--
    gv_sales_type  :=  lv_sales_type;
--
    -- ==============================================================
    -- プロファイルの取得(MO:営業単位)
    -- ==============================================================
    gv_operation_unit := FND_PROFILE.VALUE(cv_prf_operation_unit);
--
    -- プロファイルが取得できなかった場合
    IF ( gv_operation_unit IS NULL ) THEN
      -- プロファイル（営業単位）取得エラーを出力
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_profile
                       , iv_token_name1  => cv_tkn_profile
                       , iv_token_value1 => cv_prf_operation_unit
                      );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    gn_org_id := fnd_global.org_id;
--
    -- 「APP-XXCOS1-00114」(EDIヘッダ情報テーブル)メッセージの取得
    lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_edi_header_tab
                      );
    gv_edi_header_tab := cv_edi_header_tab;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_headers
   * Description      : EDIヘッダ情報テーブルデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_headers(
    on_target_cnt OUT NOCOPY NUMBER,       --   対象データ件数
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_headers'; -- プログラム名
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
--
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
    -- OUTパラメータ初期化
    on_target_cnt := 0;
--
    BEGIN
      -- カーソルオープン
      OPEN edi_headers_cur;
      -- バルクフェッチ
      FETCH edi_headers_cur BULK COLLECT INTO gt_edi_headers;
      -- 抽出件数セット
      on_target_cnt := edi_headers_cur%ROWCOUNT;
      -- カーソルクローズ
      CLOSE edi_headers_cur;
--
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_lock
                       , iv_token_name1  => cv_tkn_table
                       , iv_token_value1 => gv_edi_header_tab
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      -- データ抽出エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_getdata
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => gv_edi_header_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 対象データなしの場合
    IF ( on_target_cnt = cv_no_target_cnt ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_nodata
                    );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_normal;
-- 2009/02/24 T.Nakamura Ver.1.1 add start
      --空行挿入
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_get_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_data_validate_1
   * Description      : データ妥当性チェック1(A-3)
   ***********************************************************************************/
  PROCEDURE proc_data_validate_1(
    ov_errbuf        OUT NOCOPY VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_validate_1'; -- プログラム名
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
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
--
  BEGIN
--
    -- A-2で取得した作成元区分が納品確定データかつ通過在庫型区分が11(通過型受注)の場合
    IF ( gt_edi_headers ( gn_idx ).creation_class = cv_creat_class_deliv )
      AND ( gt_edi_headers ( gn_idx ).tsukagatazaiko_div != cv_tsukagatazaiko_11 )
      AND ( gt_edi_headers ( gn_idx ).shop_code IS NULL )
    THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                   , iv_name         => cv_msg_shop_code
                   , iv_token_name1  => cv_tkn_order_no
                   , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                  );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_data_validate_1;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_oif_headers
   * Description      : 受注ヘッダOIF用変数格納(A-4)
   ***********************************************************************************/
  PROCEDURE proc_set_oif_headers(
    ov_errbuf          OUT NOCOPY VARCHAR2,           -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,           -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数 
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_oif_headers'; -- プログラム名
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
--
    gt_order_source_id ( gn_idx )        :=  gv_order_source_id;                       -- インポートソースID
    gt_orig_sys_document_ref ( gn_idx )  :=  gt_edi_headers ( gn_idx ).order_connection_number;
                                                                                       -- 外部システム受注番号
    gt_customer_po_number_h ( gn_idx )   :=  gt_edi_headers ( gn_idx ).invoice_number; -- 顧客発注番号
    gt_ordered_date ( gn_idx )           :=  gt_edi_headers ( gn_idx ).order_date;     -- 受注日
    gt_order_type_id ( gn_idx )          :=  gv_transaction_type_id;                   -- 受注タイプID
    gt_org_id ( gn_idx )                 :=  gn_org_id;                                -- 営業単位ID
    gt_price_list_id ( gn_idx )          :=  gt_edi_headers ( gn_idx ).price_list_header_id;
                                                                                       -- 価格表ID
    gt_customer_number ( gn_idx )        :=  gt_edi_headers ( gn_idx ).conv_customer_code;
                                                                                       -- 変換後顧客コード
    gt_request_date ( gn_idx )           :=  NVL( gt_edi_headers ( gn_idx ).shop_delivery_date, 
                                               NVL( gt_edi_headers ( gn_idx ).center_delivery_date,
                                                  NVL( gt_edi_headers ( gn_idx ).order_date,
                                                    gt_edi_headers ( gn_idx ).creation_date )));
                                                                                       -- 要求日
    gt_sale_base_code ( gn_idx )         :=  gt_edi_headers ( gn_idx ).sale_base_code; -- 売上拠点コード
    gt_name_h ( gn_idx )                 :=  gv_name_h;                                -- 取引タイプ名称
--
    -- EDI連携フラグ更新用変数に格納
    gt_edi_header_info_id ( gn_idx )     :=  gt_edi_headers ( gn_idx ).edi_header_info_id;  -- EDIヘッダ情報ID
-- 2009/07/01 Ver.1.7 M.Sano add Start
    gt_h_global_attribute3 ( gn_idx )    :=  gt_edi_headers ( gn_idx ).info_class;                -- 情報区分
    gt_h_attribute5 ( gn_idx )           :=  gt_edi_headers ( gn_idx ).invoice_class;             -- 伝票区分
    gt_h_attribute20 ( gn_idx )          :=  gt_edi_headers ( gn_idx ).big_classification_code;   -- 大分類コード
-- 2009/07/01 Ver.1.7 M.Sano add End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_set_oif_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_lines
   * Description      : EDI明細情報テーブルデータ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_lines(
    on_l_target_cnt OUT NOCOPY NUMBER,       --   対象データ件数
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_lines'; -- プログラム名
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
    ln_l_target_cnt NUMBER;
--
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
--
    -- OUTパラメータ初期化
    on_l_target_cnt := 0;
--
    -- カーソルオープン
    OPEN edi_lines_cur( gn_l_idx ) ;
    -- バルクフェッチ
    FETCH edi_lines_cur BULK COLLECT INTO gt_edi_lines;
    -- 抽出件数セット
    on_l_target_cnt := edi_lines_cur%ROWCOUNT;
    -- カーソルクローズ
    CLOSE edi_lines_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_get_edi_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_data_validate_2
   * Description      : データ妥当性チェック2(A-6)
   ***********************************************************************************/
  PROCEDURE proc_data_validate_2(
    ov_errbuf        OUT NOCOPY VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_validate_2'; -- プログラム名
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
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
  BEGIN
--
    -- A-2で取得した作成元区分が受注データの場合
    IF ( gt_edi_headers ( gn_idx ).creation_class = cv_creat_class_order ) THEN
--
      -- A-5で取得した発注数量(合計・バラ)がNULLの場合
      IF ( gt_edi_lines ( gn_l_idx ).sum_order_qty IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_qty
                       , iv_token_name1  => cv_tkn_order_no
                       , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                       , iv_token_name2  => cv_tkn_line_no
                       , iv_token_value2 => gt_edi_lines( gn_l_idx ).line_no
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_warn;
      END IF;
--
    -- A-2で取得した作成元区分が納品確定データの場合
    ELSIF   ( gt_edi_headers ( gn_idx ).creation_class = cv_creat_class_deliv ) THEN
--
      -- A-5で取得した発注数量(合計・バラ)がNULLの場合
      IF ( gt_edi_lines ( gn_l_idx ).sum_order_qty IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_qty
                       , iv_token_name1  => cv_tkn_order_no
                       , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                       , iv_token_name2  => cv_tkn_line_no
                       , iv_token_value2 => gt_edi_lines( gn_l_idx ).line_no
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_warn;
--
      -- A-5で取得した原単価(発注)がNULLの場合
      ELSIF ( gt_edi_lines ( gn_l_idx ).order_unit_price IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_order_price
                       , iv_token_name1  => cv_tkn_order_no
                       , iv_token_value1 => gt_edi_headers( gn_idx ).invoice_number
                       , iv_token_name2  => cv_tkn_line_no
                       , iv_token_value2 => gt_edi_lines( gn_l_idx ).line_no
                      );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_warn;
      END IF;
--
    END IF;
--
    -- A-5で取得した「品目コード」にダミー品目コードが設定されていた場合
    -- または、原単価(発注)がNULLの場合(EDI受注のみ。EDI納品確定はエラーになる)
    IF  (( gt_edi_lines ( gn_l_idx ).err_item_flg     = cv_flg_y)
      OR ( gt_edi_lines ( gn_l_idx ).order_unit_price IS NULL ))
    THEN
      gv_dummy_item_flg := cv_dummy_item_flg_n;
    END IF;
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_data_validate_2;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_oif_lines
   * Description      : 受注明細OIF用変数格納(A-7)
   ***********************************************************************************/
  PROCEDURE proc_set_oif_lines(
    ov_errbuf          OUT NOCOPY VARCHAR2,           -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,           -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数 
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_oif_lines'; -- プログラム名
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
    CV_1     CONSTANT NUMBER  := 1;
--
    -- *** ローカル変数 ***
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
    gt_order_source_id_l( gn_l_idx_all )           :=  gv_order_source_id;                        -- インポートソースID
    gt_inventory_item( gn_l_idx_all )              :=  gt_edi_lines( gn_l_idx ).item_code;        -- 受注品目
    gt_ordered_quantity( gn_l_idx_all )            :=  gt_edi_lines( gn_l_idx ).sum_order_qty;    -- 受注数量
    gt_order_quantity_uom( gn_l_idx_all )          :=  gt_edi_lines( gn_l_idx ).line_uom;         -- 受注単位
    gt_request_date_l( gn_l_idx_all )              :=  NVL( gt_edi_headers ( gn_idx ).shop_delivery_date,
                                                         NVL( gt_edi_headers ( gn_idx ).center_delivery_date,
                                                           NVL( gt_edi_headers ( gn_idx ).order_date,
                                                             gt_edi_headers ( gn_idx ).creation_date ))); 
                                                                                                  -- 要求日
-- ************** 2009/11/05 1.8 N.Maeda MOD START ************** --
--    gt_schedule_ship_date( gn_l_idx_all )          :=  NVL( gt_edi_headers ( gn_idx ).shop_delivery_date,
--                                                         NVL( gt_edi_headers ( gn_idx ).center_delivery_date,
--                                                           NVL( gt_edi_headers ( gn_idx ).order_date,
--                                                             gt_edi_headers ( gn_idx ).creation_date ))); 
    gt_schedule_ship_date( gn_l_idx_all )          := NULL;
                                                                                                  -- 予定出荷日
-- ************** 2009/11/05 1.8 N.Maeda MOD  END  ************** --
--****************************** 2009/04/15 1.4 T.Kitajima MOD START ******************************--
--    gt_customer_po_number_l( gn_l_idx_all )        :=  gt_edi_headers ( gn_idx ).conv_customer_code;   -- 顧客発注番号
    gt_customer_po_number_l( gn_l_idx_all )        :=  gt_edi_headers ( gn_idx ).invoice_number;  -- 顧客発注番号
--****************************** 2009/04/15 1.4 T.Kitajima MOD START ******************************--
    gt_customer_line_number( gn_l_idx_all )        :=  gt_edi_lines( gn_l_idx ).line_no;          -- 顧客発注明細番号
    gt_orig_sys_document_ref_l( gn_l_idx_all )     :=  gt_edi_headers ( gn_idx ).order_connection_number;
                                                                                                  -- 外部システム受注番号
    gt_orig_sys_line_ref( gn_l_idx_all )           :=  gt_edi_lines( gn_l_idx ).line_no;          -- 外部システム受注明細番号
    gt_line_type_id( gn_l_idx_all )                :=  gv_trans_line_type_id;                     -- 明細タイプID
    gt_attribute5( gn_l_idx_all )                  :=  gv_sales_type;                             -- 売上区分
    gt_name_l( gn_l_idx_all )                      :=  gv_name_l;                                 -- 取引明細タイプ名称
    -- A-5で取得した原単価(発注)が0の場合
    IF ( gt_edi_lines( gn_l_idx ).order_unit_price  =  0 ) THEN                                   -- 販売単価
      gt_unit_selling_price ( gn_l_idx_all )       := CV_1;
    -- 上記以外の場合
    ELSE
      gt_unit_selling_price ( gn_l_idx_all )       := gt_edi_lines( gn_l_idx ).order_unit_price;
    END IF;
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
    --EDI明細 「取込時原単価（発注）」がNULLならば
    IF ( gt_edi_lines( gn_l_idx ).taking_unit_price IS NULL ) THEN
      --受注明細OIF「価格計算フラグ」を「Y」
      gt_calculate_price_flag( gn_l_idx_all )      := cv_flg_y;
    ELSE
      --それ以外は「N」
      gt_calculate_price_flag( gn_l_idx_all )      := cv_flg_n;
    END IF;
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_set_oif_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_oif_actions
   * Description      : 受注処理OIF用変数格納(A-8)
   ***********************************************************************************/
  PROCEDURE proc_set_oif_actions(
    ov_errbuf          OUT NOCOPY VARCHAR2,           -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,           -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数 
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_oif_actions'; -- プログラム名
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
--
    -- *** ローカル変数 ***
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
    gt_order_source_id_ac( gn_ac_idx )        :=  gv_order_source_id;                       -- インポートソースID
    gt_orig_sys_document_ref_ac( gn_ac_idx )  :=  gt_edi_headers ( gn_idx ).order_connection_number;
                                                                                            -- 外部システム受注明細番号
    gt_operation_code_ac( gn_ac_idx )         :=  cv_book_order;                            -- オペレーションコード
    
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
  END proc_set_oif_actions;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_edi_headers
   * Description      : EDIヘッダ情報テーブル更新(A-9)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_headers(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_headers'; -- プログラム名
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
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    ln_upd_cnt NUMBER;
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
    --EDIヘッダ情報テーブル更新処理
    BEGIN
      FORALL ln_upd_cnt IN 1..gn_target_cnt
        UPDATE  xxcos_edi_headers  xeh
        SET     xeh.order_forward_flag       =  cv_order_forward_flag_y,           -- 受注連携済フラグ「Y」
                xeh.last_updated_by          =  cn_last_updated_by,                -- 最終更新者
                xeh.last_update_date         =  cd_last_update_date,               -- 最終更新日
                xeh.last_update_login        =  cn_last_update_login,              -- 最終更新ﾛｸﾞｲﾝ
                xeh.request_id               =  cn_request_id,                     -- 要求ID
                xeh.program_application_id   =  cn_program_application_id,         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                xeh.program_id               =  cn_program_id,                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                xeh.program_update_date      =  cd_program_update_date             -- ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE   xeh.edi_header_info_id       =  gt_edi_header_info_id ( ln_upd_cnt );
--
    EXCEPTION
      WHEN OTHERS THEN
        RAISE upd_edi_headers_expt;
--
    END;
--
  EXCEPTION
--
    -- データ更新エラー
    WHEN upd_edi_headers_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_update
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => gv_edi_header_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_upd_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_oif_headers
   * Description      : 受注ヘッダOIFテーブル登録(A-10)
   ***********************************************************************************/
  PROCEDURE proc_ins_oif_headers(
    on_normal_cnt OUT NOCOPY NUMBER,         --   正常件数
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_oif_headers'; -- プログラム名
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
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
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
    -- OUTパラメータ初期化
    on_normal_cnt := 0;
--
    -- 受注ヘッダOIFテーブルへ登録
    BEGIN
      -- バルクインサート処理
      FORALL gn_idx IN 1 .. gt_order_source_id.COUNT 
       INSERT INTO oe_headers_iface_all(
           order_source_id                                              -- インポートソースID
         , orig_sys_document_ref                                        -- 外部システム受注番号
         , customer_po_number                                           -- 顧客発注番号
         , ordered_date                                                 -- 受注日
         , order_type_id                                                -- 受注タイプID
         , org_id                                                       -- 営業単位ID
         , price_list_id                                                -- 価格表ID
         , customer_number                                              -- 顧客コード
         , request_date                                                 -- 要求日
         , context                                                      -- コンテキスト
         , attribute12                                                  -- 検索用拠点コード(DFF12)
-- 2009/07/01 Ver.1.7 M.Sano add Start
         , global_attribute3                                            -- 情報区分
         , attribute5                                                   -- 伝票区分(DFF5)
         , attribute20                                                  -- 分類区分(DFF20)
-- 2009/07/01 Ver.1.7 M.Sano add End
         , created_by                                                   -- 作成者
         , creation_date                                                -- 作成日
         , last_updated_by                                              -- 最終更新者
         , last_update_date                                             -- 最終更新日
         , last_update_login                                            -- 最終更新ﾛｸﾞｲﾝ
         , request_id                                                   -- 要求ID
         , program_application_id                                       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , program_id                                                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , program_update_date                                          -- ﾌﾟﾛｸﾞﾗﾑ更新日
       )
       VALUES(
           gt_order_source_id ( gn_idx )                                -- インポートソースID
         , gt_orig_sys_document_ref ( gn_idx )                          -- 外部システム受注番号
         , gt_customer_po_number_h ( gn_idx )                           -- 顧客発注番号
         , gt_ordered_date ( gn_idx )                                   -- 受注日
         , gt_order_type_id ( gn_idx )                                  -- 受注タイプID
         , gt_org_id ( gn_idx )                                         -- 営業単位ID
         , gt_price_list_id ( gn_idx )                                  -- 価格表ID
         , gt_customer_number ( gn_idx )                                -- 顧客コード
         , gt_request_date ( gn_idx )                                   -- 要求日
         , gt_name_h ( gn_idx )                                         -- コンテキスト
         , gt_sale_base_code ( gn_idx )                                 -- 検索用拠点コード(DFF12)
-- 2009/07/01 Ver.1.7 M.Sano add Start
         , gt_h_global_attribute3 (gn_idx)                              -- 情報区分
         , gt_h_attribute5 (gn_idx)                                     -- 伝票区分(DFF5)
         , gt_h_attribute20 (gn_idx)                                    -- 分類区分(DFF20)
-- 2009/07/01 Ver.1.7 M.Sano add End
         , cn_created_by                                                -- 作成者
         , cd_creation_date                                             -- 作成日
         , cn_last_updated_by                                           -- 最終更新者
         , cd_last_update_date                                          -- 最終更新日
         , cn_last_update_login                                         -- 最終更新ﾛｸﾞｲﾝ
         , NULL                                                         -- 要求ID
         , cn_program_application_id                                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
         , cn_program_id                                                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
         , cd_program_update_date                                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
       );
--
      EXCEPTION
        -- データ登録エラー
        WHEN OTHERS THEN
          RAISE ins_data_expt;
--
    END;
--
    -- 登録件数を設定
    on_normal_cnt := gt_order_source_id.COUNT;
--
  EXCEPTION
--
    -- データ登録エラー
    WHEN ins_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_insert
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => cv_oif_headers_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_ins_oif_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_oif_lines
   * Description      : 受注明細OIFテーブル登録(A-11)
   ***********************************************************************************/
  PROCEDURE proc_ins_oif_lines(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_oif_lines'; -- プログラム名
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
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    ln_ins_idx NUMBER;
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
    -- 受注明細OIFテーブルへ登録
    BEGIN
      -- バルクインサート処理
      FORALL ln_ins_idx IN 1 ..gn_l_idx_all 
        INSERT INTO oe_lines_iface_all(
            order_source_id                                               -- インポートソースID
          , inventory_item                                                -- 受注品目
          , ordered_quantity                                              -- 受注数量
          , order_quantity_uom                                            -- 受注単位
          , unit_selling_price                                            -- 販売単価
          , unit_list_price                                               -- 定価
          , calculate_price_flag                                          -- 価格計算フラグ
          , request_date                                                  -- 要求日
          , schedule_ship_date                                            -- 予定出荷日
          , customer_po_number                                            -- 顧客発注番号
          , customer_line_number                                          -- 顧客発注明細番号
          , orig_sys_document_ref                                         -- 外部システム受注番号
          , orig_sys_line_ref                                             -- 外部システム受注明細番号
          , line_type_id                                                  -- 明細タイプID
          , attribute5                                                    -- 売上区分
          , context                                                       -- コンテキスト
          , created_by                                                    -- 作成者
          , creation_date                                                 -- 作成日
          , last_updated_by                                               -- 最終更新者
          , last_update_date                                              -- 最終更新日
          , last_update_login                                             -- 最終更新ﾛｸﾞｲﾝ
          , request_id                                                    -- 要求ID
          , program_application_id                                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          , program_id                                                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          , program_update_date                                           -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
        VALUES(
            gt_order_source_id_l( ln_ins_idx )                            -- インポートソースID
          , gt_inventory_item( ln_ins_idx )                               -- 受注品目
          , gt_ordered_quantity( ln_ins_idx )                             -- 受注数量
          , gt_order_quantity_uom( ln_ins_idx )                           -- 受注単位
          , gt_unit_selling_price( ln_ins_idx )                           -- 販売単価
          , gt_unit_selling_price( ln_ins_idx )                           -- 定価
--****************************** 2009/05/08 1.5 T.Kitajima ADD START ******************************--
--          , cv_flg_n                                                      -- 価格計算フラグ
          , gt_calculate_price_flag( ln_ins_idx )                         -- 価格計算フラグ
--****************************** 2009/05/08 1.5 T.Kitajima ADD  END  ******************************--
          , gt_request_date_l( ln_ins_idx )                               -- 要求日
          , gt_schedule_ship_date( ln_ins_idx )                           -- 予定出荷日
          , gt_customer_po_number_l( ln_ins_idx )                         -- 顧客発注番号
          , gt_customer_line_number( ln_ins_idx )                         -- 顧客発注明細番号
          , gt_orig_sys_document_ref_l( ln_ins_idx )                      -- 外部システム受注番号
          , gt_orig_sys_line_ref( ln_ins_idx )                            -- 外部システム受注明細番号
          , gt_line_type_id( ln_ins_idx )                                 -- 明細タイプID
          , gt_attribute5( ln_ins_idx )                                   -- 売上区分
          , gt_name_l( gn_l_idx_all )                                     -- コンテキスト
          , cn_created_by                                                 -- 作成者
          , cd_creation_date                                              -- 作成日
          , cn_last_updated_by                                            -- 最終更新者
          , cd_last_update_date                                           -- 最終更新日
          , cn_last_update_login                                          -- 最終更新ﾛｸﾞｲﾝ
          , NULL                                                          -- 要求ID
          , cn_program_application_id                                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          , cn_program_id                                                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          , cd_program_update_date                                        -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
    EXCEPTION
      -- データ登録エラー
      WHEN OTHERS THEN
        RAISE ins_data_expt;
--
    END;
--
  EXCEPTION
--
    WHEN ins_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_insert
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => cv_oif_lines_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_ins_oif_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_oif_actions
   * Description      : 受注処理OIFテーブル登録(A-12)
   ***********************************************************************************/
  PROCEDURE proc_ins_oif_actions(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_oif_actions'; -- プログラム名
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
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
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
    -- 受注処理OIFテーブルへ登録
    BEGIN
      -- バルクインサート処理
      FORALL gn_ac_idx IN 1 .. gt_order_source_id_ac.COUNT 
        INSERT INTO oe_actions_iface_all(
            order_source_id                                             -- インポートソースID
          , orig_sys_document_ref                                       -- 外部システム受注番号
          , operation_code                                              -- オペレーションコード
        )
        VALUES(
            gt_order_source_id_ac( gn_ac_idx )                          -- インポートソースID
          , gt_orig_sys_document_ref_ac( gn_ac_idx )                    -- 外部システム受注番号
          , gt_operation_code_ac( gn_ac_idx )                           -- オペレーションコード
        );
--
    EXCEPTION
      -- データ登録エラー
      WHEN OTHERS THEN
        RAISE ins_data_expt;
--
    END;
--
  EXCEPTION
--
    WHEN ins_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_insert
                     , iv_token_name1  => cv_tkn_table_name
                     , iv_token_value1 => cv_oif_actions_tab
                     , iv_token_name2  => cv_tkn_key_data
                     , iv_token_value2 => NULL
                     );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
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
  END proc_ins_oif_actions;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg     OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_ins_normal_cnt         NUMBER;             -- 正常件数（登録用）
    ln_upd_normal_cnt         NUMBER;             -- 正常件数（更新用）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    -- グローバル変数の初期化
    gn_target_cnt     := 0;
    gn_l_target_cnt   := 0;
    gn_normal_cnt     := 0;
    gn_warn_cnt       := 0;
    gn_error_cnt      := 0;
    gv_dummy_item_flg := 'Y';
    gn_idx            := 0;
    gn_l_idx          := 0;
    gn_ac_idx         := 0;
    gn_l_idx_all      := 0;
--
    -- ============================================
    -- 初期処理(A-1)
    -- ============================================
    proc_init(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_retcode := lv_retcode;
      -- エラー件数
      gn_error_cnt := gn_error_cnt + 1;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDIヘッダ情報テーブルデータ抽出(A-2)
    -- ============================================
    proc_get_edi_headers(
      on_target_cnt => gn_target_cnt,
      ov_errbuf     => lv_errbuf,
      ov_retcode    => lv_retcode,
      ov_errmsg     => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- 抽出したデータが0件だった場合
    IF ( gn_target_cnt = 0 ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    <<edi_headers_loop>>
    FOR ln_cnt IN 1..gn_target_cnt LOOP
--
      -- ============================================
      -- データ妥当性チェック1(A-3)
      -- ============================================
--
      -- グローバル変数へ格納
      gn_idx := ln_cnt;
--
      proc_data_validate_1(
        ov_errbuf   => lv_errbuf,
        ov_retcode  => lv_retcode,
        ov_errmsg   => lv_errmsg
      );
--
      -- 警告の場合
      IF ( lv_retcode = cv_status_warn ) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      -- エラーの場合
      IF ( lv_retcode = cv_status_error ) THEN
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
        -- エラー件数
        gn_error_cnt := gn_error_cnt + 1;
        RETURN;
      END IF;
--
      -- ============================================
      --受注ヘッダOIF用変数格納(A-4)
      -- ============================================
      proc_set_oif_headers(
        ov_errbuf      => lv_errbuf,
        ov_retcode     => lv_retcode,
        ov_errmsg      => lv_errmsg
      );
--
      -- エラーの場合
      IF ( lv_retcode = cv_status_error ) THEN
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
        -- エラー件数
        gn_error_cnt := gn_error_cnt + 1;
        RETURN;
      END IF;
--
      -- ============================================
      --EDI明細情報テーブルデータ抽出(A-5)
      -- ============================================
      proc_get_edi_lines(
        on_l_target_cnt  => gn_l_target_cnt,
        ov_errbuf      => lv_errbuf,
        ov_retcode     => lv_retcode,
        ov_errmsg      => lv_errmsg
        );
--
      -- エラーの場合
      IF ( lv_retcode = cv_status_error ) THEN
        ov_errbuf  := lv_errbuf;
        ov_retcode := lv_retcode;
        ov_errmsg  := lv_errmsg;
        -- エラー件数
        gn_error_cnt := gn_error_cnt + 1;
        RETURN;
      END IF;
--
      -- 変数の初期化
      gv_dummy_item_flg  := 'Y';
--
      <<edi_lines_loop>>
      FOR ln_l_cnt IN 1..gn_l_target_cnt LOOP
--
        -- ============================================
        --データ妥当性チェック2(A-6)
        -- ============================================
--
        -- グローバル変数へ格納
        gn_l_idx := ln_l_cnt;
        gn_l_idx_all := gn_l_idx_all + 1;
--
        proc_data_validate_2(
          ov_errbuf   => lv_errbuf,
          ov_retcode  => lv_retcode,
          ov_errmsg   => lv_errmsg
        );
--
        -- 警告の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
        -- エラーの場合
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
        -- ============================================
        -- 受注明細OIF用変数格納(A-7)
        -- ============================================
        proc_set_oif_lines(
          ov_errbuf   => lv_errbuf,
          ov_retcode  => lv_retcode,
          ov_errmsg   => lv_errmsg
        );
--
        -- エラーの場合
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
      END LOOP edi_lines_loop;
--
      -- ダミー品目コードが設定されていない場合
      IF ( gv_dummy_item_flg != cv_dummy_item_flg_n ) THEN
--
        -- ============================================
        -- 受注処理OIF用変数格納(A-8)
        -- ============================================
--
        -- グローバル変数へ格納
        gn_ac_idx := gn_ac_idx + 1;
--
        proc_set_oif_actions(
          ov_errbuf   => lv_errbuf,
          ov_retcode  => lv_retcode,
          ov_errmsg   => lv_errmsg
        );
--
        -- エラーの場合
        IF ( lv_retcode = cv_status_error ) THEN
          ov_errbuf  := lv_errbuf;
          ov_retcode := lv_retcode;
          ov_errmsg  := lv_errmsg;
          -- エラー件数
          gn_error_cnt := gn_error_cnt + 1;
          RETURN;
        END IF;
--
      END IF; 
--
    END LOOP edi_headers_loop;
--
    -- ============================================
    -- EDIヘッダ情報テーブル更新(A-9)
    -- ============================================
    proc_upd_edi_headers(
      ov_errbuf      => lv_errbuf,
      ov_retcode     => lv_retcode,
      ov_errmsg      => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      -- エラー件数
      gn_error_cnt := gn_error_cnt + 1;
      RETURN;
    END IF;
--
    -- ============================================
    -- 受注ヘッダOIFテーブル登録(A-10)
    -- ============================================
    proc_ins_oif_headers(
      on_normal_cnt  => ln_ins_normal_cnt,
      ov_errbuf      => lv_errbuf,
      ov_retcode     => lv_retcode,
      ov_errmsg      => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- 正常件数を設定
    gn_normal_cnt := ln_ins_normal_cnt;
--
    -- ============================================
    -- 受注明細OIFテーブル登録(A-11)
    -- ============================================
    proc_ins_oif_lines(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- 受注処理OIFテーブル登録(A-12)
    -- ============================================
    proc_ins_oif_actions(
      ov_errbuf   => lv_errbuf,
      ov_retcode  => lv_retcode,
      ov_errmsg   => lv_errmsg
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
--####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,              --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2               --   リターン・コード    --# 固定 #
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- 警告件数メッセージ（商品コードエラー）
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
    IF (lv_retcode = cv_status_error) THEN
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
--
    -- 警告件数が1件以上ある場合、終了ステータスを警告に設定
    IF ( gn_warn_cnt != 0 ) THEN
      lv_retcode  := cv_status_warn;
    END IF;
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
END XXCOS010A02C;
/
