CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS001A10C(body)
 * Description      : HHT受注データの取込を行う
 * MD.050           : HHT受注データ取込(MD050_COS_001_A10)
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_work_data          ワークテーブルデータ抽出(A-2)
 *  ins_hht_order_header   HHT受注ヘッダデータ一括登録(A-3)
 *  ins_hht_order_line     HHT受注明細データ一括登録(A-4)
 *  ins_oif_order_header   受注ヘッダOIFデータ一括登録(A-5)
 *  ins_oif_order_line     受注明細OIFデータ一括登録(A-6)
 *  ins_oif_order_process  受注処理OIFデータ一括登録(A-7)
 *  call_import            受注インポートエラー検知起動(A-8)
 *  del_work_date          HHT受注ワークデータ削除(A-9)
 *  del_order_date         保持期間超過HHT受注データ削除(A-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/12/08    1.0   K.Kiriu          main新規作成(E_本稼動_14486)
 *  2018/01/18    1.1   K.Nara           E_本稼動_14486(追加対応：受注品目数量の単位を品目の基準単位とする)
 *  2018/04/12    1.2   K.Kiriu          E_本稼動_15006(伝票区分の頭1桁を削除し受注OIFを作成する)
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
  -- HHT受注明細ワークなしエラー
  no_line_data_expt  EXCEPTION;
  -- 対象削除エラー
  del_target_expt    EXCEPTION;
  -- ロックエラー
  lock_err_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS001A10C';      -- パッケージ名
--
  --アプリケーション短縮名
  cv_xxcos_appl_short_name  CONSTANT VARCHAR2(5)   := 'XXCOS';             -- 販物短縮アプリ名
  -- メッセージ
  cv_msg_15251              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15251';  -- パラメータ出力
  cv_msg_00004              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- プロファイル取得エラー
  cv_msg_00091              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- 在庫組織ID取得エラー
  cv_msg_15260              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15260';  -- 受注ソース取得エラー
  cv_msg_15261              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15261';  -- 受注タイプ取得エラー
  cv_msg_00122              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00122';  -- 00_通常受注（文言）
  cv_msg_00121              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00121';  -- 10_通常出荷（文言）
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データ無し
  cv_msg_00001              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_15259              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15259';  -- 納品者コードなし
  cv_msg_15254              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15254';  -- 保管場所コードなし
  cv_msg_15255              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15255';  -- 明細なしエラー
  cv_msg_15256              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15256';  -- 品目コードなし
  cv_msg_15257              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15257';  -- 売上対象外品目
  cv_msg_15258              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15258';  -- 顧客受注不可品目
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';  -- データ登録エラー
  cv_msg_15275              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15275';  -- HHT受注ヘッダ（文言）
  cv_msg_15276              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15276';  -- HHT受注明細（文言）
  cv_msg_15252              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15252';  -- HHT受注ヘッダワーク（文言）
  cv_msg_15253              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15253';  -- HHT受注明細ワーク（文言）
  cv_msg_00132              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00132';  -- 受注ヘッダーOIF（文言）
  cv_msg_00133              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00133';  -- 受注明細OIF（文言）
  cv_msg_00134              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00134';  -- 受注処理OIF（文言）
  cv_msg_15262              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15262';  -- コンカレントエラー
  cv_msg_15263              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15263';  -- コンカレント待機エラー
  cv_msg_15264              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15264';  -- コンカレント待機警告
  cv_msg_15277              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15267';  -- HHT受注用ワーク用ロックエラー
  cv_msg_15278              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15278';  -- HHT受注ワーク用削除エラー
  cv_msg_15265              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15265';  -- HHT受注用ロックエラー
  cv_msg_15266              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15266';  -- HHT受注用削除エラー
  cv_msg_15267              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15267';  -- ヘッダ対象件数
  cv_msg_15268              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15268';  -- 明細対象件数
  cv_msg_15269              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15269';  -- ヘッダ挿入件数
  cv_msg_15270              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15270';  -- 明細挿入件数
  cv_msg_15271              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15271';  -- ヘッダ警告件数
  cv_msg_15272              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15272';  -- 明細警告件数
  cv_msg_15273              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15273';  -- ヘッダ削除件数
  cv_msg_15274              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15274';  -- 明細削除件数
  cv_msg_00147              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00147';  -- 20_協賛（文言）
  -- トークン
  cv_tkn_param              CONSTANT VARCHAR2(6)   := 'PARAME';
  cv_tkn_profile            CONSTANT VARCHAR2(7)   := 'PROFILE';
  cv_tkn_org_code_tok       CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';
  cv_tkn_err_msg            CONSTANT VARCHAR2(7)   := 'ERR_MSG';
  cv_tkn_order_type         CONSTANT VARCHAR2(10)  := 'ORDER_TYPE';
  cv_tkn_key_data           CONSTANT VARCHAR2(8)   := 'KEY_DATA';
  cv_tkn_key_data1          CONSTANT VARCHAR2(9)   := 'KEY_DATA1';
  cv_tkn_key_data2          CONSTANT VARCHAR2(9)   := 'KEY_DATA2';
  cv_tkn_emp_code           CONSTANT VARCHAR2(8)   := 'EMP_CODE';
  cv_tkn_base_code          CONSTANT VARCHAR2(9)   := 'BASE_CODE';
  cv_tkn_item_code          CONSTANT VARCHAR2(9)   := 'ITEM_CODE';
  cv_tkn_table              CONSTANT VARCHAR2(5 )  := 'TABLE';
  cv_tkn_table_name         CONSTANT VARCHAR2(10)  := 'TABLE_NAME';
  cv_tkn_request_id         CONSTANT VARCHAR2(10)  := 'REQUEST_ID';
  cv_tkn_status             CONSTANT VARCHAR2(10)  := 'STATUS';
  -- プロファイル
  cv_prof_interval          CONSTANT VARCHAR2(27)  := 'XXCOS1_INTERVAL_XXCOS001A10';  -- XXCOS:待機間隔（HHT受注インポート）
  cv_prof_max_wait          CONSTANT VARCHAR2(27)  := 'XXCOS1_MAX_WAIT_XXCOS001A10';  -- XXCOS:最大待機時間（HHT受注インポート）
-- Ver.1.1 E_本稼動_14486(追加対応) DEL START
--  cv_prof_hon_uom           CONSTANT VARCHAR2(19)  := 'XXCOS1_HON_UOM_CODE';          -- XXCOS:本単位コード
-- Ver.1.1 E_本稼動_14486(追加対応) DEL END
  cv_prof_organization      CONSTANT VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';     -- XXCOI:在庫組織コード
  cv_prof_parge_date        CONSTANT VARCHAR2(27)  := 'XXCOS1_HHT_ORDER_PURGE_DATE';  -- XXCOS:HHT受注データ取込パージ処理日算出基準日数
  cv_org_id                 CONSTANT VARCHAR2(6)   := 'ORG_ID';                       -- MO:営業単位
  -- パラメータ
  cv_mode_day               CONSTANT VARCHAR2(1)   := '1';                            -- 日中処理
  cv_mode_night             CONSTANT VARCHAR2(1)   := '2';                            -- 夜間処理
  cv_mode_parge             CONSTANT VARCHAR2(1)   := '3';                            -- ワークテーブルパージ処理
  -- 参照タイプコード
  cv_odr_src_mst_001_a10    CONSTANT VARCHAR2(26)  := 'XXCOS1_ODR_SRC_MST_001_A10';   -- 受注ソース
  cv_txn_type_mst_001_a10   CONSTANT VARCHAR2(27)  := 'XXCOS1_TXN_TYPE_MST_001_A10';  -- 受注タイプ
  cv_001_a10_01             CONSTANT VARCHAR2(16)  := 'XXCOS_001_A10_01';             -- 参照タイプコード（00_通常受注）
  cv_001_a10_02             CONSTANT VARCHAR2(16)  := 'XXCOS_001_A10_02';             -- 参照タイプコード（10_通常出荷）
  cv_001_a10_03             CONSTANT VARCHAR2(16)  := 'XXCOS_001_A10_03';             -- 参照タイプコード（20_協賛）
  cv_edi_item_err_type      CONSTANT VARCHAR2(24)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';     -- エラー品目
  -- 言語
  cv_language               CONSTANT VARCHAR2(10)  := USERENV( 'LANG' );
  -- 日付形式
  cv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  -- システム日付
  cd_sysdate                CONSTANT DATE          := SYSDATE;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 受注処理OIFテーブルレコードタイプ定義
  TYPE g_order_oif_actions_rtype  IS RECORD
    (
       order_source_id        oe_actions_iface_all.order_source_id%TYPE        -- インポートソースID
      ,orig_sys_document_ref  oe_actions_iface_all.orig_sys_document_ref%TYPE  -- 外部システム受注番号
      ,operation_code         oe_actions_iface_all.operation_code%TYPE         -- オペレーションコード
      );
  -- 受注ヘッダOIFテーブルレコードタイプ定義
  TYPE g_order_oif_header_rtype  IS RECORD (
     order_source_id        oe_headers_iface_all.order_source_id%TYPE        -- インポートソースID
    ,order_type_id          oe_headers_iface_all.order_type_id%TYPE          -- 受注タイプID
    ,orig_sys_document_ref  oe_headers_iface_all.orig_sys_document_ref%TYPE  -- 外部システム受注番号
    ,org_id                 oe_headers_iface_all.org_id%TYPE                 -- 組織ID
    ,salesrep_id            oe_headers_iface_all.salesrep_id%TYPE            -- 担当営業ID
    ,ordered_date           oe_headers_iface_all.ordered_date%TYPE           -- 受注日
    ,customer_po_number     oe_headers_iface_all.customer_po_number%TYPE     -- 顧客発注番号
    ,customer_number        oe_headers_iface_all.customer_number%TYPE        -- 顧客コード
    ,request_date           oe_headers_iface_all.request_date%TYPE           -- 要求日
    ,context                oe_headers_iface_all.context%TYPE                -- コンテキスト
    ,attribute12            oe_headers_iface_all.attribute12%TYPE            -- 検索用拠点
    ,attribute19            oe_headers_iface_all.attribute19%TYPE            -- オーダーNo
    ,attribute5             oe_headers_iface_all.attribute5%TYPE             -- 伝票区分
    ,attribute20            oe_headers_iface_all.attribute20%TYPE            -- 分類区分
    ,global_attribute4      oe_headers_iface_all.global_attribute4%TYPE      -- 受注No.(HHT)
    ,global_attribute5      oe_headers_iface_all.global_attribute5%TYPE      -- 発生元区分
  );
  -- 受注明細OIFテーブルレコードタイプ定義
  TYPE g_order_oif_line_rtype   IS RECORD (
     order_source_id        oe_lines_iface_all.order_source_id%TYPE        -- インポートソースID
    ,line_type_id           oe_lines_iface_all.line_type_id%TYPE           -- 明細タイプID
    ,orig_sys_document_ref  oe_lines_iface_all.orig_sys_document_ref%TYPE  -- 外部システム受注番号
    ,orig_sys_line_ref      oe_lines_iface_all.orig_sys_line_ref%TYPE      -- 外部システム受注明細番号
    ,org_id                 oe_lines_iface_all.org_id%TYPE                 -- 組織ID
    ,line_number            oe_lines_iface_all.line_number%TYPE            -- 明細番号
    ,inventory_item         oe_lines_iface_all.inventory_item%TYPE         -- 受注品目
    ,ordered_quantity       oe_lines_iface_all.ordered_quantity%TYPE       -- 受注数量
    ,order_quantity_uom     oe_lines_iface_all.order_quantity_uom%TYPE     -- 受注単位
    ,customer_po_number     oe_lines_iface_all.customer_po_number%TYPE     -- 顧客発注番号
    ,customer_line_number   oe_lines_iface_all.customer_line_number%TYPE   -- 顧客発注明細番号
    ,request_date           oe_lines_iface_all.request_date%TYPE           -- 要求日
    ,unit_list_price        oe_lines_iface_all.unit_selling_price%TYPE     -- 標準単価
    ,unit_selling_price     oe_lines_iface_all.unit_selling_price%TYPE     -- 販売単価
    ,subinventory           oe_lines_iface_all.subinventory%TYPE           -- 保管場所
    ,context                oe_lines_iface_all.context%TYPE                -- コンテキスト
    ,attribute5             oe_lines_iface_all.attribute5%TYPE             -- 売上区分
    ,attribute10            oe_lines_iface_all.attribute10%TYPE            -- 売単価
    ,calculate_price_flag   oe_lines_iface_all.calculate_price_flag%TYPE   -- 価格計算フラグ
  );
--
  TYPE g_hht_order_header_ttype   IS TABLE OF xxcos_hht_order_headers%ROWTYPE INDEX BY BINARY_INTEGER; -- HHT受注ヘッダテーブル
  TYPE g_hht_order_line_ttype     IS TABLE OF xxcos_hht_order_lines%ROWTYPE   INDEX BY BINARY_INTEGER; -- HHT受注明細テーブル
  TYPE g_order_oif_actions_ttype  IS TABLE OF g_order_oif_actions_rtype       INDEX BY BINARY_INTEGER; -- 受注処理OIF
  TYPE g_order_oif_header_ttype   IS TABLE OF g_order_oif_header_rtype        INDEX BY BINARY_INTEGER; -- 受注ヘッダOIF
  TYPE g_order_oif_line_ttype     IS TABLE OF g_order_oif_line_rtype          INDEX BY BINARY_INTEGER; -- 受注明細OIF
--
  gt_hht_order_header   g_hht_order_header_ttype;
  gt_hht_order_line     g_hht_order_line_ttype;
  gt_order_oif_actions  g_order_oif_actions_ttype;
  gt_order_oif_header   g_order_oif_header_ttype;
  gt_order_oif_line     g_order_oif_line_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル
  gn_interval           NUMBER;       -- XXCOS:待機間隔（HHT受注インポート）
  gn_max_wait           NUMBER;       -- XXCOS:最大待機時間（HHT受注インポート）
-- Ver.1.1 E_本稼動_14486(追加対応) DEL START
--  gv_hon_uom            VARCHAR2(50); -- XXCOS:本単位コード
-- Ver.1.1 E_本稼動_14486(追加対応) DEL END
  gv_organization       VARCHAR2(50); -- XXCOI:在庫組織コード
  gn_parge_date         NUMBER;       -- XXCOS:HHT受注データ取込パージ処理日算出基準日数
  gn_org_id             NUMBER;       -- MO:営業単位
  gn_organization_id    NUMBER;       -- 在庫組織ID
  -- 受注OIF用
  gt_order_source_id    oe_order_sources.order_source_id%TYPE;             -- 受注ソースID
  gt_order_source_name  oe_order_sources.name%TYPE;                        -- インポートソース名称
  gt_order_type_id_h    oe_transaction_types_all.transaction_type_id%TYPE; -- 取引タイプID（ヘッダ）
  gt_order_type_id_l    oe_transaction_types_all.transaction_type_id%TYPE; -- 取引タイプID（明細）
  gt_order_type_name_h  oe_transaction_types_tl.name%TYPE;                 -- 取引タイプ名称（ヘッダ）
  gt_order_type_name_l  oe_transaction_types_tl.name%TYPE;                 -- 取引タイプ名称（明細）
  gt_order_type_id_l_20 oe_transaction_types_all.transaction_type_id%TYPE; -- 取引タイプID（20_協賛）
  gt_order_type_name_l_20 oe_transaction_types_tl.name%TYPE;               -- 取引タイプ名称（20_協賛）
  -- 受注インポートエラー検知用
  gv_import_status VARCHAR2(1);  --受注インポートエラー検知の警告時ステータス保持用
  -- 各処理件数用
  gn_h_target_cnt  NUMBER;  -- ヘッダ対象件数
  gn_l_target_cnt  NUMBER;  -- 明細対象件数
  gn_h_insert_cnt  NUMBER;  -- ヘッダ挿入件数
  gn_l_insert_cnt  NUMBER;  -- 明細挿入件数
  gn_h_warn_cnt    NUMBER;  -- ヘッダ警告件数
  gn_l_warn_cnt    NUMBER;  -- 明細警告件数
  gn_h_delete_cnt  NUMBER;  -- ヘッダ削除件数
  gn_l_delete_cnt  NUMBER;  -- 明細警告件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_mode       IN  VARCHAR2,     -- 1.起動モード（1:日中 2:夜間 3:ワークテーブルパージ）
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------
    -- パラメータ出力
    ------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   => cv_xxcos_appl_short_name
                   ,iv_name          => cv_msg_15251
                   ,iv_token_name1   => cv_tkn_param               -- パラメータ
                   ,iv_token_value1  => iv_mode                    -- 起動モード
                  );
    -- 出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 出力(空行)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    ------------------------------------
    -- プロファイル取得
    ------------------------------------
    -- 日中処理の場合
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- XXCOS:待機間隔（HHT受注インポート）
      gn_interval := TO_NUMBER( fnd_profile.value( cv_prof_interval ) );
      --
      IF ( gn_interval IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- プロファイル
                      ,iv_token_value1  => cv_prof_interval           -- プロファイル名
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- XXCOS:最大待機時間（HHT受注インポート）
      gn_max_wait := TO_NUMBER( fnd_profile.value( cv_prof_max_wait ) );
--
      IF ( gn_max_wait IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- プロファイル
                      ,iv_token_value1  => cv_prof_max_wait           -- プロファイル名
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
-- Ver.1.1 E_本稼動_14486(追加対応) DEL START
--      -- XXCOS:本単位コード
--      gv_hon_uom := fnd_profile.value( cv_prof_hon_uom );
----
--      IF ( gv_hon_uom IS NULL ) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application   => cv_xxcos_appl_short_name
--                      ,iv_name          => cv_msg_00004
--                      ,iv_token_name1   => cv_tkn_profile             -- プロファイル
--                      ,iv_token_value1  => cv_prof_hon_uom            -- プロファイル名
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END IF;
-- Ver.1.1 E_本稼動_14486(追加対応) DEL END
--
      -- XXCOI:在庫組織コード
      gv_organization := fnd_profile.value( cv_prof_organization );
--
      IF ( gv_organization IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- プロファイル
                      ,iv_token_value1  => cv_prof_organization       -- プロファイル名
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    -- 夜間処理の場合
    ELSIF ( iv_mode = cv_mode_night ) THEN
--
      -- XXCOS: HHT受注データ取込パージ処理日算出基準日数
      gn_parge_date := fnd_profile.value( cv_prof_parge_date );
--
      IF ( gn_parge_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00004
                      ,iv_token_name1   => cv_tkn_profile             -- プロファイル
                      ,iv_token_value1  => cv_prof_parge_date         -- プロファイル名
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    ------------------------------------
    -- 営業単位IDの取得
    ------------------------------------
    -- 日中処理の場合のみ
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- MO:営業単位
      gn_org_id  := TO_NUMBER( fnd_profile.value( cv_org_id ) );
--
    END IF;
--
    ------------------------------------
    -- 在庫組織IDの取得
    ------------------------------------
    -- 日中処理の場合のみ
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- 在庫組織ID
      gn_organization_id := xxcoi_common_pkg.get_organization_id(
                              iv_organization_code  => gv_organization
                            );
--
      IF ( gn_organization_id IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00091
                       ,iv_token_name1        => cv_tkn_org_code_tok  -- 在庫組織コード
                       ,iv_token_value1       => gv_organization      -- 在庫組織コード
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    ------------------------------------
    -- 受注OIFに設定する内容の取得
    ------------------------------------
    -- 日中処理の場合のみ
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- 受注ソース
      BEGIN
        SELECT oos.order_source_id  order_source_id    -- 受注ソースID
              ,oos.name             order_source_name  -- インポートソース名称
        INTO   gt_order_source_id
              ,gt_order_source_name
        FROM   oe_order_sources     oos  -- 受注ソース
              ,fnd_lookup_values_vl flvv -- 参照タイプ
        WHERE  flvv.lookup_type = cv_odr_src_mst_001_a10
        AND    flvv.lookup_code = cv_001_a10_01
        AND    flvv.meaning     = oos.name
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15260
                         ,iv_token_name1        => cv_tkn_err_msg
                         ,iv_token_value1       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 受注ヘッダタイプ
      BEGIN
        SELECT otl.transaction_type_id  transaction_type_id  --取引タイプID
              ,ott.name                 order_type_name      --取引タイプ名称
        INTO   gt_order_type_id_h
              ,gt_order_type_name_h
        FROM   oe_transaction_types_all otl -- 受注取引タイプ
              ,oe_transaction_types_tl  ott -- 受注取引タイプ（摘要）
              ,fnd_lookup_values_vl     flv -- 参照タイプ
        WHERE  flv.lookup_type           = cv_txn_type_mst_001_a10
        AND    flv.lookup_code           = cv_001_a10_01
        AND    flv.meaning               = ott.name
        AND    ott.language              = cv_language
        AND    ott.transaction_type_id   = otl.transaction_type_id
       ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15261
                         ,iv_token_name1        => cv_tkn_order_type
                         ,iv_token_value1       => cv_msg_00122
                         ,iv_token_name2        => cv_tkn_err_msg
                         ,iv_token_value2       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 受注明細タイプ（10_通常出荷）
      BEGIN
        SELECT otl.transaction_type_id  transaction_type_id  -- 取引タイプID
              ,ott.name                 order_type_name      -- 取引タイプ名称
        INTO   gt_order_type_id_l
              ,gt_order_type_name_l
        FROM   oe_transaction_types_all otl -- 受注取引タイプ
              ,oe_transaction_types_tl  ott -- 受注取引タイプ（摘要）
              ,fnd_lookup_values_vl     flv -- 参照タイプ
        WHERE  flv.lookup_type           = cv_txn_type_mst_001_a10
        AND    flv.lookup_code           = cv_001_a10_02
        AND    flv.meaning               = ott.name
        AND    ott.language              = cv_language
        AND    ott.transaction_type_id   = otl.transaction_type_id
       ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15261
                         ,iv_token_name1        => cv_tkn_order_type
                         ,iv_token_value1       => cv_msg_00121
                         ,iv_token_name2        => cv_tkn_err_msg
                         ,iv_token_value2       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 受注明細タイプ（20_協賛）
      BEGIN
        SELECT otl.transaction_type_id  transaction_type_id  -- 取引タイプID
              ,ott.name                 order_type_name      -- 取引タイプ名称
        INTO   gt_order_type_id_l_20
              ,gt_order_type_name_l_20
        FROM   oe_transaction_types_all otl -- 受注取引タイプ
              ,oe_transaction_types_tl  ott -- 受注取引タイプ（摘要）
              ,fnd_lookup_values_vl     flv -- 参照タイプ
        WHERE  flv.lookup_type           = cv_txn_type_mst_001_a10
        AND    flv.lookup_code           = cv_001_a10_03
        AND    flv.meaning               = ott.name
        AND    ott.language              = cv_language
        AND    ott.transaction_type_id   = otl.transaction_type_id
       ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15261
                         ,iv_token_name1        => cv_tkn_order_type
                         ,iv_token_value1       => cv_msg_00147
                         ,iv_token_name2        => cv_tkn_err_msg
                         ,iv_token_value2       => SQLERRM
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : get_work_data
   * Description      : ワークテーブルデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_work_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_work_data'; -- プログラム名
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
    cv_delete_flag_n         CONSTANT VARCHAR2(1)  := 'N';
    cv_category_employee     CONSTANT VARCHAR2(8)  := 'EMPLOYEE';
    cv_resource_group_number CONSTANT VARCHAR2(15) := 'RS_GROUP_MEMBER';
    cv_person_type           CONSTANT VARCHAR2(3)  := 'EMP';
    cv_active_flag_y         CONSTANT VARCHAR2(1)  := 'Y';
    cd_last_day              CONSTANT DATE         :=  TO_DATE( '9999/12/31', cv_date_format );
    cv_orig_sys_doc_ref      CONSTANT VARCHAR2(29) := 'OE_ORDER_HEADERS_XXCOS001A10_';
    cv_err_item_1            CONSTANT VARCHAR2(1)  := '1';
    cv_err_item_2            CONSTANT VARCHAR2(1)  := '2';
    cv_err_item_3            CONSTANT VARCHAR2(1)  := '3';
    cv_y                     CONSTANT VARCHAR2(1)  := 'Y';
    cv_n                     CONSTANT VARCHAR2(1)  := 'N';
    cv_sales_target_flag     CONSTANT VARCHAR2(1)  := '1';
    cv_create_hht            CONSTANT VARCHAR2(1)  := '1';
    cv_operation_code        CONSTANT VARCHAR2(10) := 'BOOK_ORDER';
    cv_sale_class_5          CONSTANT VARCHAR2(1)  := '5';                      -- 売上区分「5（協賛）」
--
    -- *** ローカル変数 ***
    lt_customer_id        xxcmm_cust_accounts.customer_id%TYPE;                 -- 顧客ID
    lt_ship_storage_code  xxcmm_cust_accounts.ship_storage_code%TYPE;           -- 出荷元保管場所
    lt_salesrep_id        jtf_rs_salesreps.salesrep_id%TYPE;                    -- 営業担当ID
    lt_salesrep_number    jtf_rs_salesreps.salesrep_number%TYPE;                -- 従業員コード
    lv_storage_location   VARCHAR2(10);                                         -- 保管場所
    lt_orig_sys_doc_ref   oe_order_headers_all.orig_sys_document_ref%TYPE;      -- 外部システム番号
    ln_orig_sys_seq       NUMBER;                                               -- 外部システム番号の連番
    ln_line_data_cnt      NUMBER;                                               -- 明細件数
    lt_item_code          mtl_system_items_b.segment1%TYPE;                     -- 品目コード
    lt_cust_order_e_flag  mtl_system_items_b.customer_order_enabled_flag%TYPE;  -- 顧客受注可能フラグ
-- Ver.1.1 E_本稼動_14486(追加対応) ADD START
    lt_primary_uom_code   mtl_system_items_b.primary_uom_code%TYPE;             -- 品目基準単位コード
-- Ver.1.1 E_本稼動_14486(追加対応) ADD END
    lt_sales_target_class ic_item_mst_b.attribute26%TYPE;                       -- 売上対象区分
    lv_item_err_flag      VARCHAR2(1);                                          -- 品目のエラー制御用フラグ
    cn_h_cnt              NUMBER;                                               -- ヘッダ配列用カウンタ
    cn_l_cnt              NUMBER;                                               -- 明細配列用カウンタ
    cv_warn_flag          VARCHAR2(1);                                          -- 警告フラグ（件数出力制御用）
--
    -- *** ローカル・カーソル ***
    -- HHT受注ヘッダワークテーブル
    CURSOR get_header_data_cur
    IS
      SELECT xhohw.order_no_hht           order_no_hht           -- 受注No.(HHT)
            ,xhohw.base_code              base_code              -- 拠点コード
            ,xhohw.dlv_by_code            dlv_by_code            -- 納品者コード
            ,xhohw.invoice_no             invoice_no             -- 伝票No.
            ,xhohw.dlv_date               dlv_date               -- 納品予定日
            ,xhohw.sales_classification   sales_classification   -- 売上分類区分
            ,xhohw.sales_invoice          sales_invoice          -- 売上伝票区分
            ,xhohw.dlv_time               dlv_time               -- 時間
            ,xhohw.customer_number        customer_number        -- 顧客コード
            ,xhohw.consumption_tax_class  consumption_tax_class  -- 消費税区分
            ,xhohw.total_amount           total_amount           -- 合計金額
            ,xhohw.sales_consumption_tax  sales_consumption_tax  -- 売上消費税額
            ,xhohw.tax_include            tax_include            -- 税込金額
            ,xhohw.system_date            system_date            -- システム日付
            ,xhohw.order_no               order_no               -- オーダーNo
            ,xhohw.received_date          received_date          -- 受信日時
      FROM   xxcos_hht_order_headers_work xhohw  -- HHT受注ヘッダワークテーブル
      FOR UPDATE NOWAIT
      ;
--
    -- HHT受注明細ワークテーブル
    CURSOR get_line_data_cur(
      it_order_no_hht IN xxcos_hht_order_lines_work.order_no_hht%TYPE
    )
    IS
      SELECT xholw.order_no_hht          order_no_hht         -- 受注No.(HHT)
            ,xholw.line_no_hht           line_no_hht          -- 行No.(HHT)
            ,xholw.item_code_self        item_code_self       -- 品名コード(自社)
            ,xholw.case_number           case_number          -- ケース数
            ,xholw.quantity              quantity             -- 数量
            ,xholw.sale_class            sale_class           -- 売上区分
            ,xholw.wholesale_unit_plice  wholesale_unit_plice -- 卸単価
            ,xholw.selling_price         selling_price        -- 売単価
            ,xholw.received_date         received_date        -- 受信日時
      FROM   xxcos_hht_order_lines_work xholw  -- HHT受注明細ワークテーブル
      WHERE  xholw.order_no_hht = it_order_no_hht
      FOR UPDATE NOWAIT
      ;
--
    -- 拠点の最上位営業担当取得
    CURSOR get_top_emp_code(
       it_sales_base_code IN jtf_rs_groups_b.attribute1%TYPE
      ,id_target_date     IN DATE
    )
    IS
      SELECT jrs.salesrep_id           salesrep_id            --担当営業員ID
            ,jrs.salesrep_number       salesrep_number        --従業員コード
      FROM   per_person_types          pept_n                 --従業員タイプ
            ,per_periods_of_service    ppos_n                 --従業員サービス
            ,per_all_assignments_f     paaf_n                 --アサイメント
            ,per_all_people_f          papf_n                 --従業員
            ,jtf_rs_resource_extns     jrrx_n                 --リソース
            ,jtf_rs_group_members      jrgm_n                 --グループメンバー
            ,jtf_rs_groups_b           jrgb_n                 --リソースグループ
            ,jtf_rs_role_relations     jrrr                   --役割
            ,jtf_rs_salesreps          jrs                    --営業担当
      WHERE  jrgb_n.attribute1            = it_sales_base_code  --拠点コード
      AND    jrgb_n.group_id              = jrgm_n.group_id
      AND    jrgm_n.delete_flag           = cv_delete_flag_n
      AND    jrgm_n.resource_id           = jrrx_n.resource_id
      AND    jrrx_n.category              = cv_category_employee
      AND    jrrr.role_resource_id        = jrgm_n.group_member_id
      AND    jrrr.role_resource_type      = cv_resource_group_number
      AND    jrrr.delete_flag             = cv_delete_flag_n
      AND    jrrr.start_date_active      <= id_target_date
      AND    NVL( jrrr.end_date_active, id_target_date ) >= id_target_date
      AND    jrrx_n.source_id             = papf_n.person_id
      AND    papf_n.person_id             = paaf_n.person_id
      AND    paaf_n.period_of_service_id  = ppos_n.period_of_service_id
      AND    ppos_n.actual_termination_date IS NULL
      AND    papf_n.person_type_id        = pept_n.person_type_id
      AND    id_target_date BETWEEN papf_n.effective_start_date
                            AND     NVL( papf_n.effective_end_date, cd_last_day )
      AND    pept_n.system_person_type    = cv_person_type
      AND    pept_n.active_flag           = cv_active_flag_y
      AND    jrrx_n.resource_id           = jrs.resource_id
      AND    jrs.org_id                   = gn_org_id
      AND    TRUNC( jrs.start_date_active ) <= TRUNC( id_target_date )
      AND    TRUNC( NVL( jrs.end_date_active, id_target_date ) )
                                            >= TRUNC( id_target_date )
      ORDER BY
            paaf_n.ass_attribute11   -- 職位順
           ,ppos_n.date_start        -- 入社日
           ,papf_n.employee_number   -- 従業員番号
      ;
--
    -- *** ローカル・レコード ***
    l_header_data_rec  get_header_data_cur%ROWTYPE;
    l_line_data_rec    get_line_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 配列用カウンタの初期化
    cn_h_cnt := 0;
    cn_l_cnt := 0;
--
    ------------------------------------
    -- ヘッダデータ取得
    ------------------------------------
    BEGIN
      OPEN get_header_data_cur;
    EXCEPTION
      WHEN lock_err_expt THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00001
                       ,iv_token_name1        => cv_tkn_table  -- テーブル
                       ,iv_token_value1       => cv_msg_15252  -- テーブル名
                      );
        lv_errbuf := lv_errmsg;
        RAISE lock_err_expt;
    END;
--
    <<header_loop>>
    LOOP
--
      FETCH get_header_data_cur INTO l_header_data_rec;
      EXIT WHEN get_header_data_cur%NOTFOUND;
--
      -- 初期化
      lt_customer_id       := NULL;
      lt_ship_storage_code := NULL;
      lt_salesrep_id       := NULL;
      lt_salesrep_number   := NULL;
      lv_storage_location  := NULL;
      lt_orig_sys_doc_ref  := NULL;
      ln_orig_sys_seq      := NULL;
      ln_line_data_cnt     := 0;
      cv_warn_flag         := cv_n;
      -- ヘッダ対象件数カウント
      gn_h_target_cnt      := gn_h_target_cnt + 1;
--
      ------------------------------------
      -- 顧客コードより情報を取得
      ------------------------------------
      SELECT xca.customer_id        customer_id        -- 顧客ID
            ,xca.ship_storage_code  ship_storage_code  -- 出荷元保管場所
      INTO   lt_customer_id
            ,lt_ship_storage_code
      FROM   xxcmm_cust_accounts  xca
      WHERE  xca.customer_code = l_header_data_rec.customer_number
      ;
--
      ------------------------------------
      -- 納品者コードのチェック
      ------------------------------------
      BEGIN
        SELECT jrs.salesrep_id      salesrep_id      -- 営業担当ID
              ,jrs.salesrep_number  salesrep_number  -- 従業員コード
        INTO   lt_salesrep_id
              ,lt_salesrep_number
        FROM   jtf_rs_salesreps  jrs --営業担当
        WHERE  jrs.salesrep_number  = l_header_data_rec.dlv_by_code
        AND    jrs.org_id           = gn_org_id
        AND    TRUNC( jrs.start_date_active ) <= TRUNC( l_header_data_rec.dlv_date )
        AND    TRUNC( NVL(jrs.end_date_active, l_header_data_rec.dlv_date ) )
                                              >= TRUNC( l_header_data_rec.dlv_date )
        ;
      EXCEPTION
        -- 存在しない場合
        WHEN NO_DATA_FOUND THEN
          -- メッセージを出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15259
                         ,iv_token_name1        => cv_tkn_key_data1                -- キーデータ
                         ,iv_token_value1       => l_header_data_rec.order_no_hht  -- 受注No.(HHT)
                         ,iv_token_name2        => cv_tkn_emp_code                 -- 営業担当
                         ,iv_token_value2       => l_header_data_rec.dlv_by_code   -- 納品者コード
                        );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
         );
         -- 拠点の最上位者の営業担当を取得
         OPEN get_top_emp_code(
                l_header_data_rec.base_code
               ,l_header_data_rec.dlv_date
              );
         FETCH get_top_emp_code INTO lt_salesrep_id
                                    ,lt_salesrep_number;
         CLOSE get_top_emp_code;
         -- 件数制御の為のフラグを立てる
         cv_warn_flag := cv_y;
      END;
--
      ------------------------------------
      -- 保管場所の存在をチェック
      ------------------------------------
      BEGIN
        SELECT msi.secondary_inventory_name
        INTO   lv_storage_location
        FROM   mtl_secondary_inventories msi
        WHERE  msi.attribute3      = lt_salesrep_number
        AND    msi.attribute7      = l_header_data_rec.base_code
        AND    msi.organization_id = gn_organization_id
        AND    ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- メッセージを出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_15254
                         ,iv_token_name1        => cv_tkn_key_data1                 -- キーデータ
                         ,iv_token_value1       => l_header_data_rec.order_no_hht   -- 受注No.(HHT)
                         ,iv_token_name2        => cv_tkn_base_code                 -- 拠点
                         ,iv_token_value2       => l_header_data_rec.base_code      -- 拠点コード
                         ,iv_token_name3        => cv_tkn_emp_code                  -- 営業担当
                         ,iv_token_value3       => lt_salesrep_number               -- 営業担当コード
                        );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
         );
         -- 保管場所として顧客の出荷元保管場所を設定
         lv_storage_location := lt_ship_storage_code;
         -- 件数制御の為のフラグを立てる
         cv_warn_flag := cv_y;
      END;
--
      -- ヘッダ警告件数のカウント
      IF ( cv_warn_flag = cv_y ) THEN
        gn_h_warn_cnt := gn_h_warn_cnt + 1;
      END IF;
--
      ------------------------------------
      -- 外部システム受注番号を編集
      ------------------------------------
      SELECT xxcos_orig_sys_doc_ref_s02.NEXTVAL
      INTO   ln_orig_sys_seq
      FROM   DUAL
      ;
      lt_orig_sys_doc_ref := cv_orig_sys_doc_ref || ln_orig_sys_seq;
--
      ------------------------------------
      -- 明細データ取得
      ------------------------------------
      BEGIN
        OPEN get_line_data_cur(
               l_header_data_rec.order_no_hht
             );
      EXCEPTION
        WHEN lock_err_expt THEN
          -- メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application        => cv_xxcos_appl_short_name
                         ,iv_name               => cv_msg_00001
                         ,iv_token_name1        => cv_tkn_table  -- テーブル
                         ,iv_token_value1       => cv_msg_15253  -- テーブル名
                        );
          lv_errbuf := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
      <<line_loop>>
      LOOP
--
        FETCH get_line_data_cur INTO l_line_data_rec;
        EXIT WHEN get_line_data_cur%NOTFOUND;
--
        -- 1伝票に紐づく明細件数取得
        ln_line_data_cnt      := ln_line_data_cnt + 1;
        -- 初期化
        lt_item_code          := NULL;
        lt_cust_order_e_flag  := NULL;
        lt_sales_target_class := NULL;
        lv_item_err_flag      := cv_n;
        cv_warn_flag          := cv_n;
        -- 明細対象件数カウント
        gn_l_target_cnt       := gn_l_target_cnt + 1;
--
        ------------------------------------
        -- 品目コード（自社）の存在をチェック
        ------------------------------------
        BEGIN
          SELECT msib.segment1                     item_code
                ,msib.customer_order_enabled_flag  customer_order_enabled_flag
-- Ver.1.1 E_本稼動_14486(追加対応) ADD START
                ,msib.primary_uom_code             primary_uom_code
-- Ver.1.1 E_本稼動_14486(追加対応) ADD END
                ,iimb.attribute26                  sales_target_class
          INTO   lt_item_code
                ,lt_cust_order_e_flag
-- Ver.1.1 E_本稼動_14486(追加対応) ADD START
                ,lt_primary_uom_code
-- Ver.1.1 E_本稼動_14486(追加対応) ADD END
                ,lt_sales_target_class
          FROM   mtl_system_items_b msib  -- Disc品目
                ,ic_item_mst_b      iimb  -- OPM品目
          WHERE  msib.segment1         = l_line_data_rec.item_code_self  -- 品目コード
          AND    msib.organization_id  = gn_organization_id              -- 在庫組織ID
          AND    msib.segment1         = iimb.item_no                    -- 品目コード
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- メッセージを出力
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application        => cv_xxcos_appl_short_name
                           ,iv_name               => cv_msg_15256
                           ,iv_token_name1        => cv_tkn_key_data1                -- キーデータ1
                           ,iv_token_value1       => l_header_data_rec.order_no_hht  -- 受注No.(HHT)
                           ,iv_token_name2        => cv_tkn_key_data2                -- キーデータ
                           ,iv_token_value2       => l_line_data_rec.line_no_hht     -- 行No.(HHT)
                           ,iv_token_name3        => cv_tkn_item_code                -- 品目
                           ,iv_token_value3       => l_line_data_rec.item_code_self  -- 品目コード
                          );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           -- エラー品目を取得（マスター未登録エラー品目）
          SELECT msib.segment1  item_code
          INTO   lt_item_code
          FROM   mtl_system_items_b msib  -- Disc品目
                ,ic_item_mst_b      iimb  -- OPM品目
          WHERE  msib.segment1         = (
                   SELECT  flvv.lookup_code
                   FROM    fnd_lookup_values_vl flvv
                   WHERE   flvv.lookup_type = cv_edi_item_err_type
                   AND     flvv.attribute1  = cv_err_item_1
                 )                                           -- 品目コード
          AND    msib.organization_id  = gn_organization_id  -- 在庫組織ID
          AND    msib.segment1         = iimb.item_no        -- 品目コード
          ;
          -- エラーフラグを立てる
          lv_item_err_flag := cv_y;
          -- 件数制御の為のフラグを立てる
          cv_warn_flag     := cv_y;
        END;
--
        -- 顧客受注可能フラグのチェック（品目が取得できて、受注可能フラグがN）
        IF ( lv_item_err_flag = cv_n AND lt_cust_order_e_flag = cv_n ) THEN
            -- メッセージを出力
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application        => cv_xxcos_appl_short_name
                           ,iv_name               => cv_msg_15258
                           ,iv_token_name1        => cv_tkn_key_data1                -- キーデータ1
                           ,iv_token_value1       => l_header_data_rec.order_no_hht  -- 受注No.(HHT)
                           ,iv_token_name2        => cv_tkn_key_data2                -- キーデータ
                           ,iv_token_value2       => l_line_data_rec.line_no_hht     -- 行No.(HHT)
                           ,iv_token_name3        => cv_tkn_item_code                -- 品目
                           ,iv_token_value3       => l_line_data_rec.item_code_self  -- 品目コード
                          );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
           );
           -- エラー品目を取得（品目ステータスエラー）
          SELECT msib.segment1  item_code
          INTO   lt_item_code
          FROM   mtl_system_items_b msib  -- Disc品目
                ,ic_item_mst_b      iimb  -- OPM品目
          WHERE  msib.segment1         = (
                   SELECT  flvv.lookup_code
                   FROM    fnd_lookup_values_vl flvv
                   WHERE   flvv.lookup_type = cv_edi_item_err_type
                   AND     flvv.attribute1  = cv_err_item_2
                 )                                           -- 品目コード
          AND    msib.organization_id  = gn_organization_id  -- 在庫組織ID
          AND    msib.segment1         = iimb.item_no        -- 品目コード
          ;
          -- エラーフラグを立てる
          lv_item_err_flag := cv_y;
          -- 件数制御の為のフラグを立てる
          cv_warn_flag     := cv_y;
        END IF;
--
        -- 売上区分のチェック（品目が取得できて、受注可能フラグがY、売上区分が1以外）
        IF ( lv_item_err_flag = cv_n AND lt_sales_target_class <> cv_sales_target_flag ) THEN
            -- メッセージを出力
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application        => cv_xxcos_appl_short_name
                           ,iv_name               => cv_msg_15257
                           ,iv_token_name1        => cv_tkn_key_data1                -- キーデータ1
                           ,iv_token_value1       => l_header_data_rec.order_no_hht  -- 受注No.(HHT)
                           ,iv_token_name2        => cv_tkn_key_data2                -- キーデータ
                           ,iv_token_value2       => l_line_data_rec.line_no_hht     -- 行No.(HHT)
                           ,iv_token_name3        => cv_tkn_item_code                -- 品目
                           ,iv_token_value3       => l_line_data_rec.item_code_self  -- 品目コード
                          );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
           -- エラー品目を取得（売上区分エラー）
          SELECT msib.segment1  item_code
          INTO   lt_item_code
          FROM   mtl_system_items_b msib  -- Disc品目
                ,ic_item_mst_b      iimb  -- OPM品目
          WHERE  msib.segment1         = (
                   SELECT  flvv.lookup_code
                   FROM    fnd_lookup_values_vl flvv
                   WHERE   flvv.lookup_type = cv_edi_item_err_type
                   AND     flvv.attribute1  = cv_err_item_3
                 )                                           -- 品目コード
          AND    msib.organization_id  = gn_organization_id  -- 在庫組織ID
          AND    msib.segment1         = iimb.item_no        -- 品目コード
          ;
          -- 件数制御の為のフラグを立てる
          cv_warn_flag := cv_y;
        END IF;
--
        -- 明細警告件数のカウント
        IF ( cv_warn_flag = cv_y ) THEN
          gn_l_warn_cnt := gn_l_warn_cnt + 1;
        END IF;
--
        -- 明細配列用のカウントアップ
        cn_l_cnt := cn_l_cnt + 1;
--
        ------------------------------------
        -- HHT受注明細テーブルの配列設定
        ------------------------------------
        gt_hht_order_line(cn_l_cnt).order_no_hht           := l_line_data_rec.order_no_hht;         -- 受注No.(HHT)
        gt_hht_order_line(cn_l_cnt).line_no_hht            := l_line_data_rec.line_no_hht;          -- 行No.(HHT)
        gt_hht_order_line(cn_l_cnt).item_code_self         := l_line_data_rec.item_code_self;       -- 品名コード(自社)
        gt_hht_order_line(cn_l_cnt).item_code_conv         := lt_item_code;                         -- 変換後品目コード
        gt_hht_order_line(cn_l_cnt).subinventory_code      := lv_storage_location;                  -- 保管場所コード
        gt_hht_order_line(cn_l_cnt).case_number            := l_line_data_rec.case_number;          -- ケース数
        gt_hht_order_line(cn_l_cnt).quantity               := l_line_data_rec.quantity;             -- 数量
        gt_hht_order_line(cn_l_cnt).sale_class             := l_line_data_rec.sale_class;           -- 売上区分
        gt_hht_order_line(cn_l_cnt).wholesale_unit_plice   := l_line_data_rec.wholesale_unit_plice; -- 卸単価
        gt_hht_order_line(cn_l_cnt).selling_price          := l_line_data_rec.selling_price;        -- 売単価
        gt_hht_order_line(cn_l_cnt).received_date          := l_line_data_rec.received_date;        -- 受信日時
        gt_hht_order_line(cn_l_cnt).created_by             := cn_created_by;                        -- 作成者
        gt_hht_order_line(cn_l_cnt).creation_date          := cd_creation_date;                     -- 作成日
        gt_hht_order_line(cn_l_cnt).last_updated_by        := cn_last_updated_by;                   -- 最終更新者
        gt_hht_order_line(cn_l_cnt).last_update_date       := cd_last_update_date;                  -- 最終更新日
        gt_hht_order_line(cn_l_cnt).last_update_login      := cn_last_update_login;                 -- 最終更新ログイン
        gt_hht_order_line(cn_l_cnt).request_id             := cn_request_id;                        -- 要求ID
        gt_hht_order_line(cn_l_cnt).program_application_id := cn_program_application_id;            -- コンカレント・プログラム・アプリケーションID
        gt_hht_order_line(cn_l_cnt).program_id             := cn_program_id;                        -- コンカレント・プログラムID
        gt_hht_order_line(cn_l_cnt).program_update_date    := cd_program_update_date;               -- プログラム更新日
--
        ------------------------------------
        -- 受注明細OIFの配列設定
        ------------------------------------
        gt_order_oif_line(cn_l_cnt).order_source_id        := gt_order_source_id;                   -- インポートソースID
        IF l_line_data_rec.sale_class = cv_sale_class_5 THEN
          gt_order_oif_line(cn_l_cnt).line_type_id           := gt_order_type_id_l_20;              -- 明細タイプID（20_協賛）
        ELSE
          gt_order_oif_line(cn_l_cnt).line_type_id           := gt_order_type_id_l;                 -- 明細タイプID（10_通常出荷）
        END IF;
        gt_order_oif_line(cn_l_cnt).orig_sys_document_ref  := lt_orig_sys_doc_ref;                  -- 外部システム受注番号
        gt_order_oif_line(cn_l_cnt).orig_sys_line_ref      := l_line_data_rec.line_no_hht;          -- 外部システム受注明細番号
        gt_order_oif_line(cn_l_cnt).org_id                 := gn_org_id;                            -- 組織ID
        gt_order_oif_line(cn_l_cnt).line_number            := l_line_data_rec.line_no_hht;          -- 明細番号
        gt_order_oif_line(cn_l_cnt).inventory_item         := lt_item_code;                         -- 受注品目
        gt_order_oif_line(cn_l_cnt).ordered_quantity       := l_line_data_rec.quantity;             -- 受注数量
-- Ver.1.1 E_本稼動_14486(追加対応) MOD START
--        gt_order_oif_line(cn_l_cnt).order_quantity_uom     := gv_hon_uom;                           -- 受注単位
        gt_order_oif_line(cn_l_cnt).order_quantity_uom     := lt_primary_uom_code;                  -- 受注単位
-- Ver.1.1 E_本稼動_14486(追加対応) MOD END
        gt_order_oif_line(cn_l_cnt).customer_po_number     := l_header_data_rec.invoice_no;         -- 顧客発注番号
        gt_order_oif_line(cn_l_cnt).customer_line_number   := l_line_data_rec.line_no_hht;          -- 顧客発注明細番号
        gt_order_oif_line(cn_l_cnt).request_date           := l_header_data_rec.dlv_date;           -- 要求日
        gt_order_oif_line(cn_l_cnt).unit_list_price        := l_line_data_rec.wholesale_unit_plice; -- 標準単価
        gt_order_oif_line(cn_l_cnt).unit_selling_price     := l_line_data_rec.wholesale_unit_plice; -- 販売単価
        gt_order_oif_line(cn_l_cnt).subinventory           := lv_storage_location;                  -- 保管場所
        IF l_line_data_rec.sale_class = cv_sale_class_5 THEN
          gt_order_oif_line(cn_l_cnt).context                := gt_order_type_name_l_20;            -- コンテキスト（30_協賛）
        ELSE
          gt_order_oif_line(cn_l_cnt).context                := gt_order_type_name_l;               -- コンテキスト（10_通常出荷）
        END IF;
        gt_order_oif_line(cn_l_cnt).attribute5             := l_line_data_rec.sale_class;           -- 売上区分
        gt_order_oif_line(cn_l_cnt).attribute10            := l_line_data_rec.selling_price;        -- 売単価
        gt_order_oif_line(cn_l_cnt).calculate_price_flag   := cv_n;                                 -- 価格計算フラグ
--
      END LOOP line_loop;
--
      CLOSE get_line_data_cur;
--
      -- ヘッダに紐づく明細が1件も無い伝票が存在する場合はエラーとする。
      IF ( ln_line_data_cnt = 0 ) THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_15255
                       ,iv_token_name1        => cv_tkn_key_data1
                       ,iv_token_value1       => l_header_data_rec.order_no_hht
                      );
        lv_errbuf  := lv_errmsg;
        RAISE no_line_data_expt;
      END IF;
--
      -- ヘッダ配列用のカウントアップ
      cn_h_cnt := cn_h_cnt + 1;
--
      ------------------------------------
      -- HHT受注ヘッダテーブルの配列設定
      ------------------------------------
      gt_hht_order_header(cn_h_cnt).order_no_hht            := l_header_data_rec.order_no_hht;          -- 受注No.(HHT)
      gt_hht_order_header(cn_h_cnt).base_code               := l_header_data_rec.base_code;             -- 拠点コード
      gt_hht_order_header(cn_h_cnt).dlv_by_code             := l_header_data_rec.dlv_by_code;           -- 納品者コード
      gt_hht_order_header(cn_h_cnt).dlv_by_code_conv        := lt_salesrep_number;                      -- 変換後納品者コード
      gt_hht_order_header(cn_h_cnt).invoice_no              := l_header_data_rec.invoice_no;            -- 伝票No.
      gt_hht_order_header(cn_h_cnt).dlv_date                := l_header_data_rec.dlv_date;              -- 納品予定日
      gt_hht_order_header(cn_h_cnt).sales_classification    := l_header_data_rec.sales_classification;  -- 売上分類区分
      gt_hht_order_header(cn_h_cnt).sales_invoice           := l_header_data_rec.sales_invoice;         -- 売上伝票区分
      gt_hht_order_header(cn_h_cnt).dlv_time                := l_header_data_rec.dlv_time;              -- 時間
      gt_hht_order_header(cn_h_cnt).customer_number         := l_header_data_rec.customer_number;       -- 顧客コード
      gt_hht_order_header(cn_h_cnt).consumption_tax_class   := l_header_data_rec.consumption_tax_class; -- 消費税区分
      gt_hht_order_header(cn_h_cnt).total_amount            := l_header_data_rec.total_amount;          -- 合計金額
      gt_hht_order_header(cn_h_cnt).sales_consumption_tax   := l_header_data_rec.sales_consumption_tax; -- 売上消費税額
      gt_hht_order_header(cn_h_cnt).tax_include             := l_header_data_rec.tax_include;           -- 税込金額
      gt_hht_order_header(cn_h_cnt).system_date             := l_header_data_rec.system_date;           -- システム日付
      gt_hht_order_header(cn_h_cnt).order_no                := l_header_data_rec.order_no;              -- オーダーNo
      gt_hht_order_header(cn_h_cnt).received_date           := l_header_data_rec.received_date;         -- 受信日時
      gt_hht_order_header(cn_h_cnt).orig_sys_document_ref   := lt_orig_sys_doc_ref;                     -- 受注関連番号
      gt_hht_order_header(cn_h_cnt).created_by              := cn_created_by;                           -- 作成者
      gt_hht_order_header(cn_h_cnt).creation_date           := cd_creation_date;                        -- 作成日
      gt_hht_order_header(cn_h_cnt).last_updated_by         := cn_last_updated_by;                      -- 最終更新者
      gt_hht_order_header(cn_h_cnt).last_update_date        := cd_last_update_date;                     -- 最終更新日
      gt_hht_order_header(cn_h_cnt).last_update_login       := cn_last_update_login;                    -- 最終更新ログイン
      gt_hht_order_header(cn_h_cnt).request_id              := cn_request_id;                           -- 要求ID
      gt_hht_order_header(cn_h_cnt).program_application_id  := cn_program_application_id;               -- コンカレント・プログラム・アプリケーションID
      gt_hht_order_header(cn_h_cnt).program_id              := cn_program_id;                           -- コンカレント・プログラムID
      gt_hht_order_header(cn_h_cnt).program_update_date     := cd_program_update_date;                  -- プログラム更新日
--
      ------------------------------------
      -- 受注ヘッダOIFの配列設定
      ------------------------------------
      gt_order_oif_header(cn_h_cnt).order_source_id         := gt_order_source_id;                     -- インポートソースID
      gt_order_oif_header(cn_h_cnt).order_type_id           := gt_order_type_id_h;                     -- 受注タイプID
      gt_order_oif_header(cn_h_cnt).orig_sys_document_ref   := lt_orig_sys_doc_ref;                    -- 外部システム受注番号
      gt_order_oif_header(cn_h_cnt).org_id                  := gn_org_id;                              -- 組織ID
      gt_order_oif_header(cn_h_cnt).salesrep_id             := lt_salesrep_id;                         -- 担当営業ID
      gt_order_oif_header(cn_h_cnt).ordered_date            := l_header_data_rec.system_date;          -- 受注日
      gt_order_oif_header(cn_h_cnt).customer_po_number      := l_header_data_rec.invoice_no;           -- 顧客発注番号
      gt_order_oif_header(cn_h_cnt).customer_number         := l_header_data_rec.customer_number;      -- 顧客コード
      gt_order_oif_header(cn_h_cnt).request_date            := l_header_data_rec.dlv_date;             -- 要求日
      gt_order_oif_header(cn_h_cnt).context                 := gt_order_type_name_h;                   -- コンテキスト
      gt_order_oif_header(cn_h_cnt).attribute12             := l_header_data_rec.base_code;            -- 検索用拠点
      gt_order_oif_header(cn_h_cnt).attribute19             := l_header_data_rec.order_no;             -- オーダーNo
-- Ver.1.2 Mod Start
--      gt_order_oif_header(cn_h_cnt).attribute5              := l_header_data_rec.sales_invoice;        -- 伝票区分
      gt_order_oif_header(cn_h_cnt).attribute5              := SUBSTRB( l_header_data_rec.sales_invoice, 2,2 );  -- 伝票区分(頭1桁削除)
-- Ver.1.2 Mod End
      gt_order_oif_header(cn_h_cnt).attribute20             := l_header_data_rec.sales_classification; -- 分類区分
      gt_order_oif_header(cn_h_cnt).global_attribute4       := l_header_data_rec.order_no_hht;         -- 受注No.(HHT)
      gt_order_oif_header(cn_h_cnt).global_attribute5       := cv_create_hht;                          -- 発生元区分
--
      ------------------------------------
      -- 受注処理OIFの配列設定
      ------------------------------------
      gt_order_oif_actions(cn_h_cnt).order_source_id        := gt_order_source_id;  -- インポートソースID
      gt_order_oif_actions(cn_h_cnt).orig_sys_document_ref  := lt_orig_sys_doc_ref; -- 外部システム受注番号
      gt_order_oif_actions(cn_h_cnt).operation_code         := cv_operation_code;   -- オペレーションコード
--
    END LOOP header_loop;
--
    CLOSE get_header_data_cur;
--
  EXCEPTION
    -- *** HHT受注明細なしエラー ***
    WHEN no_line_data_expt THEN
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_header_data_cur%ISOPEN ) THEN
        CLOSE get_header_data_cur;
      END IF;
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_line_data_cur%ISOPEN ) THEN
        CLOSE get_line_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** ロックエラー ***
    WHEN lock_err_expt THEN
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_header_data_cur%ISOPEN ) THEN
        CLOSE get_header_data_cur;
      END IF;
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_line_data_cur%ISOPEN ) THEN
        CLOSE get_line_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
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
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_header_data_cur%ISOPEN ) THEN
        CLOSE get_header_data_cur;
      END IF;
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_line_data_cur%ISOPEN ) THEN
        CLOSE get_line_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_work_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_order_header
   * Description      : HHT受注ヘッダデータ一括登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_hht_order_header(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_order_header'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    BEGIN
--
      -- HHT受注ヘッダデータ一括登録
      FORALL i IN 1..gt_hht_order_header.COUNT
        INSERT INTO xxcos_hht_order_headers VALUES gt_hht_order_header(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
                lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00010
                       ,iv_token_name1        => cv_tkn_table_name  -- テーブル
                       ,iv_token_value1       => cv_msg_15275       -- テーブル名
                       ,iv_token_name2        => cv_tkn_key_data    -- キーデータ
                       ,iv_token_value2       => SQLERRM            -- SQLエラーメッセージ
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_hht_order_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_order_line
   * Description      : HHT受注明細データ一括登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_hht_order_line(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_order_line'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    BEGIN
--
      -- HHT受注明細データ一括登録
      FORALL i IN 1..gt_hht_order_line.COUNT
        INSERT INTO xxcos_hht_order_lines VALUES gt_hht_order_line(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
                lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_00010
                       ,iv_token_name1        => cv_tkn_table_name  -- テーブル
                       ,iv_token_value1       => cv_msg_15276       -- テーブル名
                       ,iv_token_name2        => cv_tkn_key_data    -- キーデータ
                       ,iv_token_value2       => SQLERRM            -- SQLエラーメッセージ
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_hht_order_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_header
   * Description      : 受注ヘッダOIFデータ一括登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_header(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_header'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    BEGIN
--
      -- 受注ヘッダOIFデータ一括登録
      FORALL i IN 1..gt_order_oif_header.COUNT
        INSERT INTO oe_headers_iface_all(
           order_source_id        -- インポートソースID
          ,order_type_id          -- 受注タイプID
          ,orig_sys_document_ref  -- 外部システム受注番号
          ,org_id                 -- 組織ID
          ,salesrep_id            -- 担当営業ID
          ,ordered_date           -- 受注日
          ,customer_po_number     -- 顧客発注番号
          ,customer_number        -- 顧客コード
          ,request_date           -- 要求日
          ,context                -- コンテキスト
          ,attribute12            -- 検索用拠点
          ,attribute19            -- オーダーNo
          ,attribute5             -- 伝票区分
          ,attribute20            -- 分類区分
          ,global_attribute4      -- 受注No.(HHT)
          ,global_attribute5      -- 発生元区分
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
        )
        VALUES
        (
           gt_order_oif_header(i).order_source_id        -- インポートソースID
          ,gt_order_oif_header(i).order_type_id          -- 受注タイプID
          ,gt_order_oif_header(i).orig_sys_document_ref  -- 外部システム受注番号
          ,gt_order_oif_header(i).org_id                 -- 組織ID
          ,gt_order_oif_header(i).salesrep_id            -- 担当営業ID
          ,gt_order_oif_header(i).ordered_date           -- 受注日
          ,gt_order_oif_header(i).customer_po_number     -- 顧客発注番号
          ,gt_order_oif_header(i).customer_number        -- 顧客コード
          ,gt_order_oif_header(i).request_date           -- 要求日
          ,gt_order_oif_header(i).context                -- コンテキスト
          ,gt_order_oif_header(i).attribute12            -- 検索用拠点
          ,gt_order_oif_header(i).attribute19            -- オーダーNo
          ,gt_order_oif_header(i).attribute5             -- 伝票区分
          ,gt_order_oif_header(i).attribute20            -- 分類区分
          ,gt_order_oif_header(i).global_attribute4      -- 受注No.(HHT)
          ,gt_order_oif_header(i).global_attribute5      -- 発生元区分
          ,cn_created_by                                 -- 作成者
          ,cd_creation_date                              -- 作成日
          ,cn_last_updated_by                            -- 最終更新者
          ,cd_last_update_date                           -- 最終更新日
          ,cn_last_update_login                          -- 最終更新ログイン
          ,NULL                                          -- 要求ID
          ,cn_program_application_id                     -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                 -- コンカレント・プログラムID
          ,cd_program_update_date                        -- プログラム更新日
        )
        ;
--
        -- ヘッダ挿入件数をカウント
        gn_h_insert_cnt := gt_order_oif_header.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_00010
               ,iv_token_name1        => cv_tkn_table_name  -- テーブル
               ,iv_token_value1       => cv_msg_00132       -- テーブル名
               ,iv_token_name2        => cv_tkn_key_data    -- キーデータ
               ,iv_token_value2       => SQLERRM            -- SQLエラーメッセージ
              );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_oif_order_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_line
   * Description      : 受注明細OIFデータ一括登録(A-6)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_line(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_line'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    BEGIN
--
      -- 受注明細OIFデータ一括登録
      FORALL i IN 1..gt_order_oif_line.COUNT
        INSERT INTO oe_lines_iface_all(
           order_source_id        -- インポートソースID
          ,line_type_id           -- 明細タイプID
          ,orig_sys_document_ref  -- 外部システム受注番号
          ,orig_sys_line_ref      -- 外部システム受注明細番号
          ,org_id                 -- 組織ID
          ,line_number            -- 明細番号
          ,inventory_item         -- 受注品目
          ,ordered_quantity       -- 受注数量
          ,order_quantity_uom     -- 受注単位
          ,customer_po_number     -- 顧客発注番号
          ,customer_line_number   -- 顧客発注明細番号
          ,request_date           -- 要求日
          ,unit_list_price        -- 標準単価
          ,unit_selling_price     -- 販売単価
          ,subinventory           -- 保管場所
          ,context                -- コンテキスト
          ,attribute5             -- 売上区分
          ,attribute10            -- 売単価
          ,calculate_price_flag   -- 価格計算フラグ
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
        )
        VALUES
        (
           gt_order_oif_line(i).order_source_id        -- インポートソースID
          ,gt_order_oif_line(i).line_type_id           -- 明細タイプID
          ,gt_order_oif_line(i).orig_sys_document_ref  -- 外部システム受注番号
          ,gt_order_oif_line(i).orig_sys_line_ref      -- 外部システム受注明細番号
          ,gt_order_oif_line(i).org_id                 -- 組織ID
          ,gt_order_oif_line(i).line_number            -- 明細番号
          ,gt_order_oif_line(i).inventory_item         -- 受注品目
          ,gt_order_oif_line(i).ordered_quantity       -- 受注数量
          ,gt_order_oif_line(i).order_quantity_uom     -- 受注単位
          ,gt_order_oif_line(i).customer_po_number     -- 顧客発注番号
          ,gt_order_oif_line(i).customer_line_number   -- 顧客発注明細番号
          ,gt_order_oif_line(i).request_date           -- 要求日
          ,gt_order_oif_line(i).unit_list_price        -- 標準単価
          ,gt_order_oif_line(i).unit_selling_price     -- 販売単価
          ,gt_order_oif_line(i).subinventory           -- 保管場所
          ,gt_order_oif_line(i).context                -- コンテキスト
          ,gt_order_oif_line(i).attribute5             -- 売上区分
          ,gt_order_oif_line(i).attribute10            -- 売単価
          ,gt_order_oif_line(i).calculate_price_flag   -- 価格計算フラグ
          ,cn_created_by                               -- 作成者
          ,cd_creation_date                            -- 作成日
          ,cn_last_updated_by                          -- 最終更新者
          ,cd_last_update_date                         -- 最終更新日
          ,cn_last_update_login                        -- 最終更新ログイン
          ,NULL                                        -- 要求ID
          ,cn_program_application_id                   -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                               -- コンカレント・プログラムID
          ,cd_program_update_date                      -- プログラム更新日
        )
        ;
--
        -- 明細挿入件数をカウント
        gn_l_insert_cnt := gt_order_oif_line.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_00010
               ,iv_token_name1        => cv_tkn_table_name  -- テーブル
               ,iv_token_value1       => cv_msg_00133       -- テーブル名
               ,iv_token_name2        => cv_tkn_key_data    -- キーデータ
               ,iv_token_value2       => SQLERRM            -- SQLエラーメッセージ
              );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_oif_order_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif_order_process
   * Description      : 受注処理OIFデータ一括登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_oif_order_process(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif_order_process'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    BEGIN
--
      -- 受注ヘッダOIFデータ一括登録
      FORALL i IN 1..gt_order_oif_actions.COUNT
        INSERT INTO oe_actions_iface_all(
           order_source_id        -- インポートソースID
          ,orig_sys_document_ref  -- 外部システム受注番号
          ,operation_code         -- オペレーションコード
        )
        VALUES
        (
           gt_order_oif_actions(i).order_source_id        -- インポートソースID
          ,gt_order_oif_actions(i).orig_sys_document_ref  -- 外部システム受注番号
          ,gt_order_oif_actions(i).operation_code         -- オペレーションコード
        )
        ;
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_00010
               ,iv_token_name1        => cv_tkn_table_name  -- テーブル
               ,iv_token_value1       => cv_msg_00134       -- テーブル名
               ,iv_token_name2        => cv_tkn_key_data    -- キーデータ
               ,iv_token_value2       => SQLERRM            -- SQLエラーメッセージ
              );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_oif_order_process;
--
  /**********************************************************************************
   * Procedure Name   : call_import
   * Description      : 受注インポートエラー検知起動(A-8)
   ***********************************************************************************/
  PROCEDURE call_import(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_import'; -- プログラム名
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
    --要求の発行
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';          -- Application
    cv_program                CONSTANT VARCHAR2(13)  := 'XXCOS010A062C';  -- 受注インポートエラー検知(Online用）
    cv_description            CONSTANT VARCHAR2(9)   := NULL;             -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;             -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;            -- Sub_request
    --要求の待機
    cv_wait_error             CONSTANT VARCHAR2(5)   := 'ERROR';          -- ステータス（異常）
    cv_wait_warning           CONSTANT VARCHAR2(7)   := 'WARNING';        -- ステータス（警告）
    -- *** ローカル変数 ***
    --要求の発行
    ln_request_id             NUMBER;          -- 要求ID
    --要求の待機
    ln_process_set            NUMBER;          -- 処理セット
    lb_wait_result            BOOLEAN;         -- コンカレント待機成否
    lv_phase                  VARCHAR2(50);    -- フェーズ（ユーザ）
    lv_status                 VARCHAR2(50);    -- ステータス（ユーザ）
    lv_dev_phase              VARCHAR2(50);    -- フェーズ（プログラム）
    lv_dev_status             VARCHAR2(50);    -- ステータス（プログラム）
    lv_message                VARCHAR2(5000);  -- メッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- データ確定の為コミット
    COMMIT;
--
    ------------------------------------
    -- コンカレント起動
    ------------------------------------
    ln_request_id := fnd_request.submit_request(
                        application  => cv_application        -- アプリケーション
                       ,program      => cv_program            -- プログラム
                       ,description  => cv_description        -- 適用
                       ,start_time   => cv_start_time         -- 開始時間
                       ,sub_request  => cb_sub_request        -- サブ要求
                       ,argument1    => gt_order_source_name  -- 受注ソース名
                     );
--
    -- 要求の発行に失敗した場合
    IF ( ln_request_id = 0 ) THEN
      -- メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_name
                     ,iv_name         => cv_msg_15262
                     ,iv_token_name1  => cv_tkn_request_id         -- 要求ID
                     ,iv_token_value1 => TO_CHAR( ln_request_id )  -- 要求ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    ------------------------------------
    --コンカレントの終了待機
    ------------------------------------
    lb_wait_result := fnd_concurrent.wait_for_request(
                         request_id   => ln_request_id  -- 要求ID
                        ,interval     => gn_interval    -- 待機間隔
                        ,max_wait     => gn_max_wait    -- 最大待機時間
                        ,phase        => lv_phase       -- フェーズ（ユーザ）
                        ,status       => lv_status      -- ステータス（ユーザ）
                        ,dev_phase    => lv_dev_phase   -- フェーズ（プログラム）
                        ,dev_status   => lv_dev_status  -- ステータス（プログラム）
                        ,message      => lv_message     -- メッセージ
                      );
--
    -- 待機結果がFALSE、もしくは、要求ステータスがERRORの場合
    IF (
         ( lb_wait_result = FALSE ) 
         OR
         ( lv_dev_status = cv_wait_error )
    ) THEN
      -- メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_name
                     ,iv_name         => cv_msg_15263
                     ,iv_token_name1  => cv_tkn_request_id         -- 要求ID
                     ,iv_token_value1 => TO_CHAR( ln_request_id )  -- 要求ID
                     ,iv_token_name2  => cv_tkn_status             -- ステータス
                     ,iv_token_value2 => lv_dev_status             -- ステータスコード
                     ,iv_token_name3  => cv_tkn_err_msg            -- エラーメッセージ
                     ,iv_token_value3 => lv_message                -- APIから返却されたメッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    -- 要求ステータスがWARNINGの場合
    ELSIF ( lv_dev_status = cv_wait_warning ) THEN
      -- メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_name
                     ,iv_name         => cv_msg_15264
                     ,iv_token_name1  => cv_tkn_request_id         -- 要求ID
                     ,iv_token_value1 => TO_CHAR( ln_request_id )  -- 要求ID)
                     ,iv_token_name2  => cv_tkn_status             -- ステータス
                     ,iv_token_value2 => lv_dev_status             -- ステータスコード
                     ,iv_token_name3  => cv_tkn_err_msg            -- エラーメッセージ
                     ,iv_token_value3 => lv_message                -- APIから返却されたメッセージ
                     );
--
      -- メッセージ出力
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
      );
      -- 終了ステータスの制御用変数の設定
      gv_import_status := cv_status_warn;
--
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
  END call_import;
--
  /**********************************************************************************
   * Procedure Name   : del_work_date
   * Description      : HHT受注ワークデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE del_work_date(
     iv_mode       IN  VARCHAR2     --   1.起動モード（1:日中 3:ワークテーブルパージ）
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work_date'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    -- HHT受注ヘッダワークテーブル
    CURSOR get_del_header_cur
    IS
      SELECT xhohw.order_no_hht  order_no_hht    -- 受注No.(HHT)
      FROM   xxcos_hht_order_headers_work xhohw  -- HHT受注ヘッダワークテーブル
      FOR UPDATE NOWAIT
    ;
    -- HHT受注明細ワークテーブル
    CURSOR get_del_line_cur
    IS
      SELECT xholw.order_no_hht  order_no_hht  -- 受注No.(HHT)
      FROM   xxcos_hht_order_lines_work xholw  -- HHT受注明細ワークテーブル
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ---------------------------------------------------------------
    -- 削除対象件数を取得
    ---------------------------------------------------------------
    -- HHT受注ヘッダワークテーブル
    SELECT COUNT(1)
    INTO   gn_h_delete_cnt
    FROM   xxcos_hht_order_headers_work xhohw
    ;
    -- HHT受注明細ワークテーブル
    SELECT COUNT(1)
    INTO   gn_l_delete_cnt
    FROM   xxcos_hht_order_lines_work xholw
    ;
--
    ---------------------------------------------------------------
    -- 起動モードがワークテーブルパージ処理の場合、テーブルのロック
    ---------------------------------------------------------------
    IF ( iv_mode = cv_mode_parge) THEN
--
      -- HHT受注ヘッダワークテーブルのロック
      BEGIN
        OPEN  get_del_header_cur;
        CLOSE get_del_header_cur;
      EXCEPTION
        WHEN lock_err_expt THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15277
                 ,iv_token_name1        => cv_tkn_table  --テーブル
                 ,iv_token_value1       => cv_msg_15252  --テーブル名
                );
          lv_errbuf  := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
      -- HHT受注明細ワークテーブルのロック
      BEGIN
        OPEN  get_del_line_cur;
        CLOSE get_del_line_cur;
      EXCEPTION
        WHEN lock_err_expt THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15277
                 ,iv_token_name1        => cv_tkn_table  --テーブル
                 ,iv_token_value1       => cv_msg_15253  --テーブル名
                );
          lv_errbuf  := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
    END IF;
--
    ---------------------------------------------------------------
    -- テーブルのパージ
    ---------------------------------------------------------------
    BEGIN
--
      -- HHT受注ヘッダワークテーブルの削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_hht_order_headers_work';
--
    EXCEPTION
      WHEN OTHERS THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15278
                 ,iv_token_name1        => cv_tkn_table    -- テーブル
                 ,iv_token_value1       => cv_msg_15252    -- テーブル名
                 ,iv_token_name2        => cv_tkn_err_msg  -- エラーメッセージ
                 ,iv_token_value2       => SQLERRM         -- SQLエラーメッセージ
                );
          lv_errbuf  := lv_errmsg;
          RAISE del_target_expt;
    END;
--
    BEGIN
--
      -- HHT受注明細ワークテーブルの削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_hht_order_lines_work';
--
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                iv_application        => cv_xxcos_appl_short_name
               ,iv_name               => cv_msg_15278
               ,iv_token_name1        => cv_tkn_table      -- テーブル
               ,iv_token_value1       => cv_msg_15253      -- テーブル名
               ,iv_token_name2        => cv_tkn_err_msg    -- エラーメッセージ
               ,iv_token_value2       => SQLERRM           -- SQLエラーメッセージ
              );
        lv_errbuf  := lv_errmsg;
        RAISE del_target_expt;
    END;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_err_expt THEN
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_del_header_cur%ISOPEN ) THEN
        CLOSE get_del_header_cur;
      END IF;
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_del_line_cur%ISOPEN ) THEN
        CLOSE get_del_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 対象削除エラー ***
    WHEN del_target_expt THEN
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_del_header_cur%ISOPEN ) THEN
        CLOSE get_del_header_cur;
      END IF;
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_del_line_cur%ISOPEN ) THEN
        CLOSE get_del_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END del_work_date;
--
  /**********************************************************************************
   * Procedure Name   : del_order_date
   * Description      : 保持期間超過HHT受注データ削除(A-10)
   ***********************************************************************************/
  PROCEDURE del_order_date(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_order_date'; -- プログラム名
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
    -- *** ローカル・変数 ***
    ld_process_date  DATE; --業務日付
--
    -- *** ローカル・カーソル ***
    -- HHT受注ヘッダテーブル
    CURSOR get_del_order_h_cur
    IS
      SELECT xhoh.order_no_hht  order_no_hht    -- 受注No.(HHT)
      FROM   xxcos_hht_order_headers xhoh       -- HHT受注ヘッダテーブル
      WHERE  xhoh.received_date < ld_process_date - gn_parge_date  -- 受信日 < 業務日付-保持期間
      FOR UPDATE NOWAIT
    ;
    -- HHT受注明細テーブル
    CURSOR get_del_order_l_cur(
      it_order_no_hht IN xxcos_hht_order_lines.order_no_hht%TYPE
    )
    IS
      SELECT xhol.order_no_hht  order_no_hht  -- 受注No.(HHT)
      FROM   xxcos_hht_order_lines xhol       -- HHT受注明細ワークテーブル
      WHERE  xhol.order_no_hht = it_order_no_hht
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
    l_del_order_h_rec  get_del_order_h_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務日付取得
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- HHT受注ヘッダテーブルのロック
    BEGIN
      OPEN get_del_order_h_cur;
    EXCEPTION
      WHEN lock_err_expt THEN
        -- メッセージ編集
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application        => cv_xxcos_appl_short_name
                       ,iv_name               => cv_msg_15265
                       ,iv_token_name1        => cv_tkn_table  -- テーブル
                       ,iv_token_value1       => cv_msg_15275  -- テーブル名
                      );
        lv_errbuf := lv_errmsg;
        RAISE lock_err_expt;
    END;
--
    <<del_header_loop>>
    LOOP
--
      FETCH get_del_order_h_cur INTO l_del_order_h_rec;
      EXIT WHEN get_del_order_h_cur%NOTFOUND;
--
      -- HHT受注明細テーブルのロック
      BEGIN
        OPEN get_del_order_l_cur(
              l_del_order_h_rec.order_no_hht
        );
        CLOSE get_del_order_l_cur;
      EXCEPTION
        WHEN lock_err_expt THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15265
                 ,iv_token_name1        => cv_tkn_table  -- テーブル
                 ,iv_token_value1       => cv_msg_15276  -- テーブル名
                );
          lv_errbuf  := lv_errmsg;
          RAISE lock_err_expt;
      END;
--
        -- HHT受注明細テーブルの削除(受注No.(HHT)単位)
      BEGIN
--
        DELETE FROM xxcos_hht_order_lines xhol
        WHERE  xhol.order_no_hht = l_del_order_h_rec.order_no_hht
        ;
--
        -- 明細削除件数のカウント
        gn_l_delete_cnt := gn_l_delete_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15266
                 ,iv_token_name1        => cv_tkn_table    -- テーブル
                 ,iv_token_value1       => cv_msg_15276    -- テーブル名
                 ,iv_token_name2        => cv_tkn_err_msg  -- エラーメッセージ
                 ,iv_token_value2       => SQLERRM         -- SQLエラーメッセージ
                );
          lv_errbuf  := lv_errmsg;
          RAISE del_target_expt;
      END;
--
      BEGIN
--
        -- HHT受注ヘッダテーブルの削除
        DELETE FROM xxcos_hht_order_headers xhol
        WHERE  xhol.order_no_hht = l_del_order_h_rec.order_no_hht
        ;
--
        -- ヘッダ削除件数のカウント
        gn_h_delete_cnt := gn_h_delete_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
        WHEN OTHERS THEN
          --メッセージ編集
          lv_errmsg  := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcos_appl_short_name
                 ,iv_name               => cv_msg_15266
                 ,iv_token_name1        => cv_tkn_table    -- テーブル
                 ,iv_token_value1       => cv_msg_15275    -- テーブル名
                 ,iv_token_name2        => cv_tkn_err_msg  -- エラーメッセージ
                 ,iv_token_value2       => SQLERRM         -- SQLエラーメッセージ
                );
          lv_errbuf  := lv_errmsg;
          RAISE del_target_expt;
      END;
--
    END LOOP del_header_loop;
--
    CLOSE get_del_order_h_cur;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_err_expt THEN
      -- HHT受注ヘッダカーソルクローズ
      IF ( get_del_order_h_cur%ISOPEN ) THEN
        CLOSE get_del_order_h_cur;
      END IF;
      -- HHT受注明細カーソルクローズ
      IF ( get_del_order_l_cur%ISOPEN ) THEN
        CLOSE get_del_order_l_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 対象削除エラー ***
    WHEN del_target_expt THEN
      -- HHT受注ヘッダカーソルクローズ
      IF ( get_del_order_h_cur%ISOPEN ) THEN
        CLOSE get_del_order_h_cur;
      END IF;
      -- HHT受注明細カーソルクローズ
      IF ( get_del_order_l_cur%ISOPEN ) THEN
        CLOSE get_del_order_l_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_del_order_h_cur%ISOPEN ) THEN
        CLOSE get_del_order_h_cur;
      END IF;
      -- HHT受注ヘッダワークカーソルクローズ
      IF ( get_del_order_l_cur%ISOPEN ) THEN
        CLOSE get_del_order_l_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_order_date;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_mode       IN  VARCHAR2,     -- 1.起動モード（1:日中 2:夜間 3:ワークテーブルパージ）
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
    gn_h_target_cnt := 0;  -- ヘッダ対象件数
    gn_l_target_cnt := 0;  -- 明細対象件数
    gn_h_insert_cnt := 0;  -- ヘッダ挿入件数
    gn_l_insert_cnt := 0;  -- 明細挿入件数
    gn_h_warn_cnt   := 0;  -- ヘッダ警告件数
    gn_l_warn_cnt   := 0;  -- 明細警告件数
    gn_h_delete_cnt := 0;  -- ヘッダ削除件数
    gn_l_delete_cnt := 0;  -- 明細削除件数
--
    gv_import_status := cv_status_normal; --受注インポートエラー検知
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_mode    => iv_mode    -- 1.起動モード（1:日中 2:夜間 3:ワークテーブルパージ）
      ,ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 日中処理の場合
    IF ( iv_mode = cv_mode_day ) THEN
--
      -- ===============================
      -- ワークテーブルデータ抽出(A-2)
      -- ===============================
      get_work_data(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- HHT受注ヘッダデータ一括登録(A-3)
      -- ===============================
      ins_hht_order_header(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --不要となった配列を削除
      gt_hht_order_header.DELETE;
--
      -- ===============================
      -- HHT受注明細データ一括登録(A-4)
      -- ===============================
      ins_hht_order_line(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --不要となった配列を削除
      gt_hht_order_line.DELETE;
--
      -- ===============================
      -- 受注ヘッダOIFデータ一括登録(A-5)
      -- ===============================
      ins_oif_order_header(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --不要となった配列を削除
      gt_order_oif_header.DELETE;
--
      -- ===============================
      -- 受注明細OIFデータ一括登録(A-6)
      -- ===============================
      ins_oif_order_line(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --不要となった配列を削除
      gt_order_oif_line.DELETE;
--
      -- ===============================
      -- 受注処理OIFデータ一括登録(A-7)
      -- ===============================
      ins_oif_order_process(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      --不要となった配列を削除
      gt_order_oif_actions.DELETE;
--
      -- 対象が存在する場合（HHT受注ヘッダワークにデータがある場合）
      IF ( gn_h_target_cnt <> 0 ) THEN
--
        -- ===============================
        -- 受注インポートエラー検知起動(A-8)
        -- ===============================
        call_import(
           ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
          ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
          ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ===============================
      -- HHT受注ワークデータ削除(A-9)
      -- ===============================
      del_work_date(
         iv_mode    => iv_mode     -- 1.起動モード（1:日中）
        ,ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 対象が存在しない場合、処理を警告終了とする
      IF ( gn_h_target_cnt = 0 ) THEN
        -- メッセージを出力
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_00003
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
      -- ヘッダ・明細の警告件数が存在する場合、処理を警告終了とする
      ELSIF ( gn_h_warn_cnt <> 0 OR gn_l_warn_cnt <> 0 ) THEN
        ov_retcode := cv_status_warn;
      -- 受注インポートエラー検知が警告の場合、処理を警告終了とする
      ELSIF ( gv_import_status = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
    -- 夜間処理の場合
    ELSIF ( iv_mode = cv_mode_night ) THEN
--
      -- ===============================
      -- 保持期間超過HHT受注データ削除(A-10)
      -- ===============================
      del_order_date(
         ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ワークテーブルパージの場合
    ELSIF ( iv_mode = cv_mode_parge ) THEN
--
      -- ===============================
      -- HHT受注ワークデータ削除(A-9)
      -- ===============================
      del_work_date(
         iv_mode    => iv_mode     -- 1.起動モード（3:ワークテーブルパージ）
        ,ov_errbuf  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,ov_retcode => lv_retcode  -- リターン・コード             --# 固定 #
        ,ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_mode       IN  VARCHAR2       -- 1.起動モード（1:日中 2:夜間 3:ワークテーブルパージ）
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
       iv_mode     -- 1.起動モード（1:日中 2:夜間 3:ワークテーブルパージ）
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 件数の設定
      gn_h_target_cnt := 0;
      gn_l_target_cnt := 0;
      gn_h_insert_cnt := 0;
      gn_l_insert_cnt := 0;
      gn_h_warn_cnt   := 0;
      gn_l_warn_cnt   := 0;
      gn_h_delete_cnt := 0;
      gn_l_delete_cnt := 0;
      gn_error_cnt    := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 日中処理の件数出力
    IF ( iv_mode = cv_mode_day ) THEN
--
      --ヘッダ対象件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15267
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細対象件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15268
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --ヘッダ挿入件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15269
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_insert_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細挿入件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15270
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_insert_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --ヘッダ警告件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15271
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_warn_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細警告件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15272
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_warn_cnt)
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
    -- 夜間処理・ワークテーブルパージ処理の場合
    ELSE
      --
      --ヘッダ削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15273
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_h_delete_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --明細削除件数出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_15274
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_l_delete_cnt)
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
END XXCOS001A10C;
/
