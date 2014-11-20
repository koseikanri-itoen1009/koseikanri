CREATE OR REPLACE PACKAGE BODY xxinv990004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990004c(body)
 * Description      : 入出庫実績のアップロード
 * MD.050           : ファイルアップロード   T_MD050_BPO_990
 * MD.070           : 入出庫実績のアップロード T_MD070_BPO_99E
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              関連データ取得 (E-1)
 *  get_upload_data_proc   ファイルアップロードインタフェースデータ取得 (E-2)
 *  check_proc             妥当性チェック (E-3,4,5)
 *  set_data_proc          登録データ設定
 *  insert_header_proc     ヘッダ登録 (E-6)
 *  insert_details_proc    明細登録 (E-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/28    1.0   Oracle 野村       初回作成
 *  2008/04/18    1.1   Oracle 山根 一浩  変更要求No63対応
 *  2008/05/07    1.2   Oracle 河野       内部変更要求No82対応
 *  2008/05/28    1.3   Oracle 山根 一浩  変更要求No87対応
 *  2008/07/08    1.4   Oracle 山根 一浩  I_S_192対応
 *  2009/06/29    1.5   SCS    伊藤       本番障害#1550
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
  no_data_if_expt           EXCEPTION;     -- 対象データなし
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv990004c'; -- パッケージ名
--
  gv_c_msg_kbn   CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- メッセージ番号
  gv_c_msg_99e_001   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- プロファイル取得エラー
  gv_c_msg_99e_002   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ロックエラー
  gv_c_msg_99e_003   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- 対象データなし
  gv_c_msg_99e_004   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10026'; -- ヘッダ明細区分エラー
  gv_c_msg_99e_005   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- フォーマットチェックエラーメッセージ
-- 2009/06/29 H.Itou Add Start 本番障害#1550
  gv_c_msg_99e_006   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10190'; -- ヘッダなしエラー
-- 2009/06/29 H.Itou Add End
--
  gv_c_msg_99e_101   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- ファイル名
  gv_c_msg_99e_103   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- アップロード日時
  gv_c_msg_99e_104   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- ファイルアップロード名称
--
  -- トークン
  gv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NAME';
  gv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
-- 2009/06/29 H.Itou Add Start 本番障害#1550
  gv_c_tkn_request_no          CONSTANT VARCHAR2(15)   := 'REQUEST_NO';
-- 2009/06/29 H.Itou Add End
  -- プロファイル
  gv_c_parge_term_004          CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_004';
  gv_c_parge_term_name         CONSTANT VARCHAR2(36)   := 'パージ対象期間:入出庫実績';
  -- クイックコード タイプ
  gv_c_lookup_type             CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_c_format_type             CONSTANT VARCHAR2(20)  := 'フォーマットパターン';
  -- 対象DB名
  gv_c_xxinv_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                            := 'ファイルアップロードインタフェーステーブル';
--
  -- *** ヘッダ項目名 ***
  gv_c_file_id_name             CONSTANT VARCHAR2(24)   := 'FILE_ID';
  gv_c_data_type                CONSTANT VARCHAR2(24)   := 'データ種別';
  gv_c_tranceration_number      CONSTANT VARCHAR2(24)   := '伝送用枝番';
  gv_c_delivery_no              CONSTANT VARCHAR2(24)   := '配送No';
  gv_c_order_source_ref         CONSTANT VARCHAR2(24)   := '依頼No';
  gv_c_location_code            CONSTANT VARCHAR2(24)   := '出庫倉庫コード';
  gv_c_ship_to_location         CONSTANT VARCHAR2(24)   := '入庫倉庫コード';
  gv_c_freight_carrier_code     CONSTANT VARCHAR2(24)   := '運送業者コード';
  gv_c_party_site_code          CONSTANT VARCHAR2(24)   := '配送先コード';
  gv_c_shipped_date             CONSTANT VARCHAR2(24)   := '発日';
  gv_c_arrival_date             CONSTANT VARCHAR2(24)   := '着日';
  gv_c_shipping_method_code     CONSTANT VARCHAR2(24)   := '配送区分';
  gv_c_collected_pallet_qty     CONSTANT VARCHAR2(24)   := 'パレット回収枚数';
  gv_c_arrival_time_from        CONSTANT VARCHAR2(24)   := '着荷時間指定(FROM)';
  gv_c_arrival_time_to          CONSTANT VARCHAR2(24)   := '着荷時間指定(TO)';
  gv_c_cust_po_number           CONSTANT VARCHAR2(24)   := '顧客発注番号';
  gv_c_used_pallet_qty          CONSTANT VARCHAR2(24)   := 'パレット使用枚数';
  gv_c_report_post_code         CONSTANT VARCHAR2(24)   := '報告部署';
  -- *** 明細項目名 ***
  gv_c_orderd_item_code         CONSTANT VARCHAR2(24)   := '品目コード';
  gv_c_orderd_quantity          CONSTANT VARCHAR2(24)   := '品目数量';
  gv_c_lot_no                   CONSTANT VARCHAR2(24)   := 'ロット番号';
  gv_c_designated_prod_date     CONSTANT VARCHAR2(24)   := '製造日';
  gv_c_original_character       CONSTANT VARCHAR2(24)   := '固有記号';
  gv_c_use_by_date              CONSTANT VARCHAR2(24)   := '賞味期限';
  gv_c_detailed_quantity        CONSTANT VARCHAR2(24)   := 'ロット数量';
--
  -- *** ヘッダ項目桁数 ***
  gn_c_data_type_l              CONSTANT NUMBER         := 3;   -- データ種別
  gn_c_delivery_no_l            CONSTANT NUMBER         := 12;  -- 配送No
  gn_c_order_source_ref_l       CONSTANT NUMBER         := 12;  -- 依頼No
  gn_c_location_code_l          CONSTANT NUMBER         := 4;   -- 出庫倉庫コード
  gn_c_ship_to_location_l       CONSTANT NUMBER         := 4;   -- 入庫倉庫コード
  gn_c_freight_carrier_code_l   CONSTANT NUMBER         := 4;   -- 運送業者コード
  gn_c_party_site_code_l        CONSTANT NUMBER         := 9;   -- 配送先コード
  gn_c_shipping_method_code_l   CONSTANT NUMBER         := 2;   -- 配送区分
  gn_c_arrival_time_from_l      CONSTANT NUMBER         := 4;   -- 着荷時間指定(FROM)
  gn_c_arrival_time_to_l        CONSTANT NUMBER         := 4;   -- 着荷時間指定(TO)
  gn_c_cust_po_number_l         CONSTANT NUMBER         := 20;  -- 顧客発注番号
  gn_c_report_post_code_l       CONSTANT NUMBER         := 4;   -- 報告部署
  -- *** 明細項目桁数 ***
  gn_c_orderd_item_code_l       CONSTANT NUMBER         := 7;   -- 品目コード
  gn_c_lot_no_l                 CONSTANT NUMBER         := 10;  -- ロット番号
  gn_c_original_character_l     CONSTANT NUMBER         := 6;   -- 固有記号
--
  -- *** ヘッダ明細区分 ***
--2008.05.07 Y.Kawano modify start
--  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '01';  -- ヘッダ
--  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '02';  -- 明細
  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '10';  -- ヘッダ
  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '20';  -- 明細
--2008.05.07 Y.Kawano modify end
  -- データ区分
  gv_c_data_type_wsh            CONSTANT VARCHAR2(2)    := '30';  -- 外部倉庫入出庫実績
--
  gv_c_period                   CONSTANT VARCHAR2(1)    := '.';           -- ピリオド
  gv_c_comma                    CONSTANT VARCHAR2(1)    := ',';           -- カンマ
  gv_c_space                    CONSTANT VARCHAR2(1)    := ' ';           -- スペース
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      ';      -- スペース（6byte）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSVを格納するレコード
  TYPE file_data_rec IS RECORD(
    corporation_name              VARCHAR2(32767), -- 会社名
    eos_data_type                 VARCHAR2(32767), -- データ種別
    tranceration_number           VARCHAR2(32767), -- 伝送用枝番
    delivery_no                   VARCHAR2(32767), -- 配送No
    order_source_ref              VARCHAR2(32767), -- 依頼No
    spare                         VARCHAR2(32767), -- 予備
    head_sales_branch             VARCHAR2(32767), -- 拠点コード
    head_sales_branch_name        VARCHAR2(32767), -- 管轄拠点名称
    location_code                 VARCHAR2(32767), -- 出庫倉庫コード
    location_code_name            VARCHAR2(32767), -- 出庫倉庫名称
    ship_to_location              VARCHAR2(32767), -- 入庫倉庫コード
    ship_to_location_name         VARCHAR2(32767), -- 入庫倉庫名称
    freight_carrier_code          VARCHAR2(32767), -- 運送業者コード
    freight_carrier_code_name     VARCHAR2(32767), -- 運送業者名
    party_site_code               VARCHAR2(32767), -- 配送先コード
    party_site_code_name          VARCHAR2(32767), -- 配送先名
    shipped_date                  VARCHAR2(32767), -- 発日
    arrival_date                  VARCHAR2(32767), -- 着日
    shipping_method_code          VARCHAR2(32767), -- 配送区分
    weight                        VARCHAR2(32767), -- 重量
    mixed_no                      VARCHAR2(32767), -- 混載元依頼No
    collected_pallet_qty          VARCHAR2(32767), -- パレット回収枚数
    arrival_time_from             VARCHAR2(32767), -- 着荷時間指定（FROM）
    arrival_time_to               VARCHAR2(32767), -- 着荷時間指定（TO）
    cust_po_number                VARCHAR2(32767), -- 顧客発注番号
    summary                       VARCHAR2(32767), -- 摘要
    status                        VARCHAR2(32767), -- ステータス
    freight_charge_class          VARCHAR2(32767), -- 運賃区分
    used_pallet_qty               VARCHAR2(32767), -- パレット使用枚数
    spare1                        VARCHAR2(32767), -- 予備１
    spare2                        VARCHAR2(32767), -- 予備２
    spare3                        VARCHAR2(32767), -- 予備３
    spare4                        VARCHAR2(32767), -- 予備４
    report_post_code              VARCHAR2(32767), -- 報告部署
    orderd_item_code              VARCHAR2(32767), -- 品目コード
    orderd_item_code_name         VARCHAR2(32767), -- 品目名
    item_uom_code                 VARCHAR2(32767), -- 品目単位
    orderd_quantity               VARCHAR2(32767), -- 品目数量
    lot_no                        VARCHAR2(32767), -- ロット番号
    designated_production_date    VARCHAR2(32767), -- 製造日
    original_character            VARCHAR2(32767), -- 固有記号
    use_by_date                   VARCHAR2(32767), -- 賞味期限
    detailed_quantity             VARCHAR2(32767), -- ロット数量
    new_modify_del_class          VARCHAR2(32767), -- データ区分
    update_date                   VARCHAR2(32767), -- 更新日時
    line                          VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message                   VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- 登録用PL/SQL表型（ヘッダ）
  TYPE header_id_type             IS TABLE OF  
      xxwsh_shipping_headers_if.header_id%TYPE            INDEX BY BINARY_INTEGER;  -- ヘッダID
  TYPE  party_site_code_type      IS TABLE OF 
      xxwsh_shipping_headers_if.party_site_code%TYPE      INDEX BY BINARY_INTEGER;  -- 出荷先
  TYPE cust_po_number_type        IS TABLE OF 
      xxwsh_shipping_headers_if.cust_po_number%TYPE       INDEX BY BINARY_INTEGER;  -- 顧客発注
  TYPE  order_source_ref_type     IS TABLE OF 
      xxwsh_shipping_headers_if.order_source_ref%TYPE     INDEX BY BINARY_INTEGER;  -- 受注ソース参照
  TYPE  used_pallet_qty_type      IS TABLE OF 
      xxwsh_shipping_headers_if.used_pallet_qty%TYPE      INDEX BY BINARY_INTEGER;  -- パレット使用枚数
  TYPE  collected_pallet_qty_type IS TABLE OF 
      xxwsh_shipping_headers_if.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER;  -- パレット回収枚数
  TYPE  location_code_type        IS TABLE OF 
      xxwsh_shipping_headers_if.location_code%TYPE        INDEX BY BINARY_INTEGER;  -- 出荷元
  TYPE  arrival_time_from_type    IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_from%TYPE    INDEX BY BINARY_INTEGER;  -- 着荷時間From
  TYPE  arrival_time_to_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_to%TYPE      INDEX BY BINARY_INTEGER;  -- 着荷時間To
  TYPE freight_carrier_code_type  IS TABLE OF 
      xxwsh_shipping_headers_if.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;  -- 運送業者
  TYPE shipping_method_code_type  IS TABLE OF 
      xxwsh_shipping_headers_if.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;  -- 配送区分
  TYPE delivery_no_type           IS TABLE OF 
      xxwsh_shipping_headers_if.delivery_no%TYPE          INDEX BY BINARY_INTEGER;  -- 配送No
  TYPE shipped_date_type          IS TABLE OF 
      xxwsh_shipping_headers_if.shipped_date%TYPE         INDEX BY BINARY_INTEGER;  -- 出荷日
  TYPE arrival_date_type          IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_date%TYPE         INDEX BY BINARY_INTEGER;  -- 着荷日
  TYPE eos_data_type_type         IS TABLE OF 
      xxwsh_shipping_headers_if.eos_data_type%TYPE        INDEX BY BINARY_INTEGER;  -- EOSデータ種別
  TYPE tranceration_number_type   IS TABLE OF 
      xxwsh_shipping_headers_if.tranceration_number%TYPE  INDEX BY BINARY_INTEGER;  -- 伝送用枝版
  TYPE ship_to_location_type      IS TABLE OF 
      xxwsh_shipping_headers_if.ship_to_location%TYPE     INDEX BY BINARY_INTEGER;  -- 入庫倉庫
  TYPE  report_post_code_type     IS TABLE OF 
      xxwsh_shipping_headers_if.report_post_code%TYPE     INDEX BY BINARY_INTEGER;  -- 報告部署
  TYPE  filler14_type             IS TABLE OF 
      xxwsh_shipping_headers_if.filler14%TYPE             INDEX BY BINARY_INTEGER;  -- 運賃区分
--
  gt_header_id_tab              header_id_type;             -- ヘッダID
  gt_party_site_code_tab        party_site_code_type;       -- 出荷先
  gt_cust_po_number_tab         cust_po_number_type;        -- 顧客発注
  gt_order_source_ref_tab       order_source_ref_type;      -- 受注ソース参照
  gt_used_pallet_qty_tab        used_pallet_qty_type;       -- パレット使用枚数
  gt_collected_pallet_qty_tab   collected_pallet_qty_type;  -- パレット回収枚数
  gt_location_code_tab          location_code_type;         -- 出荷元
  gt_arrival_time_from_tab      arrival_time_from_type;     -- 着荷時間From
  gt_arrival_time_to_tab        arrival_time_to_type;       -- 着荷時間To
  gt_freight_carrier_code_tab   freight_carrier_code_type;  -- 運送業者
  gt_shipping_method_code_tab   shipping_method_code_type;  -- 配送区分
  gt_delivery_no_tab            delivery_no_type;           -- 配送No
  gt_shipped_date_tab           shipped_date_type;          -- 出荷日
  gt_arrival_date_tab           arrival_date_type;          -- 着荷日
  gt_eos_data_tab               eos_data_type_type;         -- EOSデータ種別
  gt_ship_to_location_tab       ship_to_location_type;      -- 入庫倉庫
  gt_report_post_code_tab       report_post_code_type;      -- 報告部署
  gt_filler14_tab               filler14_type;              -- 運賃区分
--
  -- 登録用PL/SQL表型（明細）
  TYPE line_header_id_type              IS TABLE OF
      xxwsh_shipping_lines_if.header_id%TYPE                  INDEX BY BINARY_INTEGER;  -- 明細ID
  TYPE line_id_type                     IS TABLE OF
      xxwsh_shipping_lines_if.line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- ヘッダID
  TYPE orderd_item_code_type            IS TABLE OF
      xxwsh_shipping_lines_if.orderd_item_code%TYPE           INDEX BY BINARY_INTEGER;  -- 受注品目
  TYPE orderd_quantity_type             IS TABLE OF
      xxwsh_shipping_lines_if.orderd_quantity%TYPE            INDEX BY BINARY_INTEGER;  -- 品目数量
  TYPE designated_prod_date_type        IS TABLE OF
      xxwsh_shipping_lines_if.designated_production_date%TYPE INDEX BY BINARY_INTEGER;  -- 製造日
  TYPE original_character_type          IS TABLE OF
      xxwsh_shipping_lines_if.original_character%TYPE         INDEX BY BINARY_INTEGER;  -- 固有記号
  TYPE use_by_date_type                 IS TABLE OF
      xxwsh_shipping_lines_if.use_by_date%TYPE                INDEX BY BINARY_INTEGER;  -- 賞味期限
  TYPE detailed_quantity_type           IS TABLE OF
      xxwsh_shipping_lines_if.detailed_quantity%TYPE          INDEX BY BINARY_INTEGER;  -- 内訳数量
  TYPE lot_no_type                      IS TABLE OF
      xxwsh_shipping_lines_if.lot_no%TYPE                     INDEX BY BINARY_INTEGER;  -- ロットNo
--
  gt_line_header_id_tab                 line_header_id_type;              -- 明細ID
  gt_line_id_tab                        line_id_type;                     -- 明細ID
  gt_orderd_item_code_tab               orderd_item_code_type;            -- 受注品目
  gt_orderd_quantity_tab                orderd_quantity_type;             -- 品目数量
  gt_designated_prod_date_tab           designated_prod_date_type;        -- 製造日
  gt_original_character_tab             original_character_type;          -- 固有記号
  gt_use_by_date_tab                    use_by_date_type;                 -- 賞味期限
  gt_detailed_quantity_tab              detailed_quantity_type;           -- 内訳数量
  gt_lot_no_tab                         lot_no_type;                      -- ロットNo
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_header_count           NUMBER;           -- ヘッダデータ件数
  gn_line_count             NUMBER;           -- 明細データ件数
--
  gd_sysdate                DATE;             -- システム日付
  gn_user_id                NUMBER;           -- ユーザID
  gn_login_id               NUMBER;           -- 最終更新ログイン
  gn_conc_request_id        NUMBER;           -- 要求ID
  gn_prog_appl_id           NUMBER;           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id        NUMBER;           -- コンカレント・プログラムID
--
  gn_xxinv_parge_term       NUMBER;                          -- パージ対象期間
  gv_file_name              VARCHAR2(256);                   -- ファイル名
  gv_file_up_name           VARCHAR2(256);                   -- ファイルアップロード名称
  gn_created_by             NUMBER(15);                      -- 作成者
  gd_creation_date          DATE;                            -- 作成日
  gv_check_proc_retcode     VARCHAR2(1);                     -- 妥当性チェックステータス
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 関連データ取得 (E-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,     -- フォーマットパターン
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    lv_parge_term       VARCHAR2(100);    -- プロファイル格納場所
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- コンカレント・プログラムID
--
    -- プロファイル「パージ対象期間」取得
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_004);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_001,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値チェック
    BEGIN
      -- TO_NUMBERできなければエラー
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_001,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- ファイルアップロード名称取得
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- クイックコードVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- タイプ
      AND     xlvv.lookup_code = in_file_format         -- コード
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_003,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : ファイルアップロードインタフェースデータ取得 (E-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,       --   ファイルＩＤ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data_proc'; -- プログラム名
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
    lv_line       VARCHAR2(32767);    -- 改行コード迄の情報
    ln_col        NUMBER;             -- カラム
    lb_col        BOOLEAN  := TRUE;   -- カラム作成継続
    ln_length     NUMBER;             -- 長さ保管用
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- 行テーブル格納領域
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ファイルアップロードインタフェースデータ取得
    -- 行ロック処理
    SELECT xmf.file_name,    -- ファイル名
           xmf.created_by,   -- 作成者
           xmf.creation_date -- 作成日
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- **************************************************
    -- *** ファイルアップロードインターフェースデータ取得
    -- **************************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,         -- ファイルＩＤ
      lt_file_line_data,  -- 変換後VARCHAR2データ
      lv_errbuf,          -- エラー・メッセージ             --# 固定 #
      lv_retcode,         -- リターン・コード               --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ   --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、又は、2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_003,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- **************************************************
    -- *** 取得したデータを行毎のループ（2行目から）
    -- **************************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 行毎に作業領域に格納
      lv_line := lt_file_line_data(ln_index);
--
      -- 1行の内容を line に格納
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- カラム番号初期化
      ln_col := 0;    --カラム
      lb_col := TRUE; --カラム作成継続
--
      -- **************************************************
      -- *** 1行をカンマ毎に分解
      -- **************************************************
      <<comma_loop>>
      LOOP
        --lv_lineの長さが0なら終了
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- カラム番号をカウント
        ln_col := ln_col + 1;
--
        -- カンマの位置を取得
        ln_length := instr(lv_line, gv_c_comma);
        -- カンマがない
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- カンマがある
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- CSV形式を項目ごとにレコードに格納
        IF (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).corporation_name          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).eos_data_type             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).tranceration_number       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).delivery_no               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).order_source_ref          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).spare                     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch_name    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).location_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).location_code_name        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).ship_to_location          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).ship_to_location_name     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).freight_carrier_code      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).freight_carrier_code_name := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN
          fdata_tbl(gn_target_cnt).party_site_code           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 16) THEN
          fdata_tbl(gn_target_cnt).party_site_code_name      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 17) THEN
          fdata_tbl(gn_target_cnt).shipped_date              := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 18) THEN
          fdata_tbl(gn_target_cnt).arrival_date              := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 19) THEN
          fdata_tbl(gn_target_cnt).shipping_method_code      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 20) THEN
          fdata_tbl(gn_target_cnt).weight                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 21) THEN
          fdata_tbl(gn_target_cnt).mixed_no                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 22) THEN
          fdata_tbl(gn_target_cnt).collected_pallet_qty      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 23) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 24) THEN
          fdata_tbl(gn_target_cnt).arrival_time_to           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 25) THEN
          fdata_tbl(gn_target_cnt).cust_po_number            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 26) THEN
          fdata_tbl(gn_target_cnt).summary                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 27) THEN
          fdata_tbl(gn_target_cnt).status                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 28) THEN
          fdata_tbl(gn_target_cnt).freight_charge_class      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 29) THEN
          fdata_tbl(gn_target_cnt).used_pallet_qty           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 30) THEN
          fdata_tbl(gn_target_cnt).spare1                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 31) THEN
          fdata_tbl(gn_target_cnt).spare2                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 32) THEN
          fdata_tbl(gn_target_cnt).spare3                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 33) THEN
          fdata_tbl(gn_target_cnt).spare4                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 34) THEN
          fdata_tbl(gn_target_cnt).report_post_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 35) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 36) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code_name     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 37) THEN
          fdata_tbl(gn_target_cnt).item_uom_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 38) THEN
          fdata_tbl(gn_target_cnt).orderd_quantity           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 39) THEN
          fdata_tbl(gn_target_cnt).lot_no                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 40) THEN
          fdata_tbl(gn_target_cnt).designated_production_date:= SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 41) THEN
          fdata_tbl(gn_target_cnt).use_by_date               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 42) THEN
          fdata_tbl(gn_target_cnt).original_character        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 43) THEN
          fdata_tbl(gn_target_cnt).detailed_quantity         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 44) THEN
          fdata_tbl(gn_target_cnt).new_modify_del_class      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 45) THEN
          fdata_tbl(gn_target_cnt).update_date               := SUBSTR(lv_line, 1, ln_length);
        END IF;
--
        -- strは今回取得した行を除く（カンマはのぞくため、ln_length + 2）
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_002,
                                            gv_c_tkn_table,
                                            gv_c_xxinv_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_99e_003,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
                                            in_file_id);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : 妥当性チェック (E-3,4,5)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- プログラム名
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
-- 2009/06/29 H.Itou Add Start 本番障害#1550
    cv_cnst_err_msg_space   CONSTANT VARCHAR2(6)   := '      ';   -- スペース
-- 2009/06/29 H.Itou Add End
--
    lv_line_feed        VARCHAR2(1);                  -- 改行コード
--
    -- 総項目数
    ln_c_col         CONSTANT NUMBER      := 45;
--
    -- *** ローカル変数 ***
    lv_log_data                                      VARCHAR2(32767);  -- LOGデータ部退避用
-- 2009/06/29 H.Itou Add Start 本番障害#1550
    lt_order_source_ref xxwsh_shipping_headers_if.order_source_ref%TYPE;    -- ヘッダの依頼No
-- 2009/06/29 H.Itou Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 初期化
    gv_check_proc_retcode := gv_status_normal; -- 妥当性チェックステータス
    lv_line_feed := CHR(10);                   -- 改行コード
--
    -- **************************************************
    -- *** 取得したレコード毎に項目チェックを行う。
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** 項目数チェック
      -- **************************************************
      -- （行全体の長さ－行からカンマを抜いた長さ＝カンマの数） <> （正式な項目数－１＝正式なカンマの数）
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0) - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_c_comma,NULL)),0))
          <> (ln_c_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                           || gv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                       gv_c_msg_99e_005)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** 項目チェック（ヘッダ／明細）
        -- **************************************************
        -- ヘッダーの場合
        IF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_header) THEN
-- 2009/06/29 H.Itou Add Start 本番障害#1550
          -- ヘッダの依頼Noを取得
          lt_order_source_ref := fdata_tbl(ln_index).order_source_ref;
-- 2009/06/29 H.Itou Add End
          -- ==============================
          --  データ種別
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_data_type,
                                              fdata_tbl(ln_index).eos_data_type,
                                              gn_c_data_type_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 配送No
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_delivery_no,
                                              fdata_tbl(ln_index).delivery_no,
                                              gn_c_delivery_no_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 依頼No
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_order_source_ref,
                                              fdata_tbl(ln_index).order_source_ref,
                                              gn_c_order_source_ref_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 出庫倉庫コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_location_code,
                                              fdata_tbl(ln_index).location_code,
                                              gn_c_location_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 入庫倉庫コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_to_location,
                                              fdata_tbl(ln_index).ship_to_location,
                                              gn_c_ship_to_location_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 運送業者コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_freight_carrier_code,
                                              fdata_tbl(ln_index).freight_carrier_code,
                                              gn_c_freight_carrier_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 配送先コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_party_site_code,
                                              fdata_tbl(ln_index).party_site_code,
                                              gn_c_party_site_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 発日
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_shipped_date,
                                              fdata_tbl(ln_index).shipped_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 着日
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_date,
                                              fdata_tbl(ln_index).arrival_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 配送区分
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_shipping_method_code,
                                              fdata_tbl(ln_index).shipping_method_code,
                                              gn_c_shipping_method_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- パレット回収枚数
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_collected_pallet_qty,
                                              fdata_tbl(ln_index).collected_pallet_qty,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 着荷時間指定（FROM）
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_from,
                                              fdata_tbl(ln_index).arrival_time_from,
                                              gn_c_arrival_time_from_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 着荷時間指定（TO）
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_to,
                                              fdata_tbl(ln_index).arrival_time_to,
                                              gn_c_arrival_time_to_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 顧客発注番号
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_cust_po_number,
                                              fdata_tbl(ln_index).cust_po_number,
                                              gn_c_cust_po_number_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- パレット使用枚数
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_used_pallet_qty,
                                              fdata_tbl(ln_index).used_pallet_qty,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 報告部署
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_report_post_code,
                                              fdata_tbl(ln_index).report_post_code,
                                              gn_c_report_post_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        -- 明細の場合
        ELSIF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_details) THEN
-- 2009/06/29 H.Itou Add Start 本番障害#1550
          -- ヘッダと依頼Noが異なる場合はエラー
          IF ((lt_order_source_ref IS NULL)
          OR  (lt_order_source_ref <> fdata_tbl(ln_index).order_source_ref)) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                 || cv_cnst_err_msg_space
                                                 || cv_cnst_err_msg_space
                                                 || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                             gv_c_msg_99e_006,
                                                                             gv_c_tkn_request_no,
                                                                             fdata_tbl(ln_index).order_source_ref)
                                                 || lv_line_feed;
          END IF;
-- 2009/06/29 H.Itou Add End
          -- ==============================
          -- 品目コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_orderd_item_code,
                                              fdata_tbl(ln_index).orderd_item_code,
                                              gn_c_orderd_item_code_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 品目数量
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_orderd_quantity,
                                              fdata_tbl(ln_index).orderd_quantity,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ロット番号
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_lot_no,
                                              fdata_tbl(ln_index).lot_no,
                                              gn_c_lot_no_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 製造日
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_designated_prod_date,
                                              fdata_tbl(ln_index).designated_production_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 固有記号
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_original_character,
                                              fdata_tbl(ln_index).original_character,
                                              gn_c_original_character_l,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_vc2,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- 賞味期限
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_use_by_date,
                                              fdata_tbl(ln_index).use_by_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_dat,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- ==============================
          -- ロット数量
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_detailed_quantity,
                                              fdata_tbl(ln_index).detailed_quantity,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_attr_num,
                                              lv_errbuf,
                                              lv_retcode,
                                              lv_errmsg);
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        -- ヘッダ明細区分が不正な場合
        ELSE
          fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                             || gv_c_err_msg_space
                                             || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                         gv_c_msg_99e_004)
                                             || lv_line_feed;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** エラー制御
      -- **************************************************
      -- チェックエラーありの場合
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** データ部出力準備（行数 + SPACE + 行全体のデータ）
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_c_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- エラーメッセージ部出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- 妥当性チェックステータス
        gv_check_proc_retcode := gv_status_error;
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
      -- チェックエラーなしの場合
      ELSE
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : 登録データ設定
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- プログラム名
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
    ln_header_id      NUMBER;   -- ヘッダID
    ln_line_id        NUMBER;   -- 明細ID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 件数初期化
    gn_line_count     := 0;
    gn_header_count   := 0;
--
    -- ローカル変数初期化
    ln_header_id      := NULL;
    ln_line_id        := NULL;
--
    -- **************************************************
    -- *** 登録用PL/SQL表編集（2行目から）
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- ヘッダ登録
      IF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_header) THEN
--
        -- ヘッダ件数 インクリメント
        gn_header_count  := gn_header_count + 1;
--
        -- ヘッダID採番
        SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- ヘッダ情報
        gt_header_id_tab(gn_header_count)             := ln_header_id;                                             -- ヘッダID
        gt_party_site_code_tab(gn_header_count)       := fdata_tbl(ln_index).party_site_code;                      -- 出荷先
        gt_cust_po_number_tab(gn_header_count)        := fdata_tbl(ln_index).cust_po_number;                       -- 顧客発注
        gt_order_source_ref_tab(gn_header_count)      := fdata_tbl(ln_index).order_source_ref;                     -- 受注ソース参照
        gt_used_pallet_qty_tab(gn_header_count)       := TO_NUMBER(fdata_tbl(ln_index).used_pallet_qty);           -- パレット使用枚数
        gt_collected_pallet_qty_tab(gn_header_count)  := TO_NUMBER(fdata_tbl(ln_index).collected_pallet_qty);      -- パレット回収枚数
        gt_location_code_tab(gn_header_count)         := fdata_tbl(ln_index).location_code;                        -- 出荷元
        gt_arrival_time_from_tab(gn_header_count)     := fdata_tbl(ln_index).arrival_time_from;                    -- 着荷時間From
        gt_arrival_time_to_tab(gn_header_count)       := fdata_tbl(ln_index).arrival_time_to;                      -- 着荷時間To
        gt_freight_carrier_code_tab(gn_header_count)  := fdata_tbl(ln_index).freight_carrier_code;                 -- 運送業者
        gt_shipping_method_code_tab(gn_header_count)  := fdata_tbl(ln_index).shipping_method_code;                 -- 配送区分
        gt_delivery_no_tab(gn_header_count)           := fdata_tbl(ln_index).delivery_no;                          -- 配送No
        gt_shipped_date_tab(gn_header_count)          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).shipped_date, 'RR/MM/DD');  -- 出荷日
        gt_arrival_date_tab(gn_header_count)          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).arrival_date, 'RR/MM/DD');  -- 着荷日
        gt_eos_data_tab(gn_header_count)              := fdata_tbl(ln_index).eos_data_type;                        -- EOSデータ種別
        gt_ship_to_location_tab(gn_header_count)      := fdata_tbl(ln_index).ship_to_location;                     -- 入庫倉庫
        gt_report_post_code_tab(gn_header_count)      := fdata_tbl(ln_index).report_post_code;                     -- 報告部署
        gt_filler14_tab(gn_header_count)              := fdata_tbl(ln_index).freight_charge_class;                 -- 運賃区分
--
      -- 明細登録
      ELSIF (fdata_tbl(ln_index).tranceration_number = gn_c_tranc_details) THEN
--
        -- 明細件数 インクリメント
        gn_line_count   := gn_line_count + 1;
--
        -- 最初のレコードが明細の場合、ヘッダIDを採番
        IF (ln_header_id IS NULL) THEN
          -- ヘッダID採番
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
          INTO ln_header_id 
          FROM dual;
        END IF;
--
        -- 明細ID採番
        SELECT xxwsh_shipping_lines_if_s1.NEXTVAL
        INTO ln_line_id 
        FROM dual;
--
        -- 明細情報
        gt_line_id_tab(gn_line_count)               := ln_line_id;                                               -- 明細ID
        gt_line_header_id_tab(gn_line_count)        := ln_header_id;                                             -- ヘッダID
        gt_orderd_item_code_tab(gn_line_count)      := fdata_tbl(ln_index).orderd_item_code;                     -- 受注品目
        gt_orderd_quantity_tab(gn_line_count)       := TO_NUMBER(fdata_tbl(ln_index).orderd_quantity);           -- 品目数量
        gt_designated_prod_date_tab(gn_line_count)  := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).designated_production_date, 'RR/MM/DD');  -- 製造日
        gt_original_character_tab(gn_line_count)    := fdata_tbl(ln_index).original_character;                   -- 固有記号
        gt_use_by_date_tab(gn_line_count)           := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).use_by_date, 'RR/MM/DD'); -- 賞味期限
        gt_detailed_quantity_tab(gn_line_count)     := TO_NUMBER(fdata_tbl(ln_index).detailed_quantity);         -- 内訳数量
        gt_lot_no_tab(gn_line_count)                := fdata_tbl(ln_index).lot_no;                               -- ロットNo
      END IF;
--
    END LOOP fdata_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_header_proc
   * Description      : ヘッダ登録 (E-6)
   ***********************************************************************************/
  PROCEDURE insert_header_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_header_proc'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- *** 出荷依頼インタフェースヘッダ（アドオン）登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_header_count
      INSERT INTO xxwsh_shipping_headers_if
      (   header_id                                         -- ヘッダID
        , order_type                                        -- 受注タイプ
        , ordered_date                                      -- 受注日
        , party_site_code                                   -- 出荷先
        , shipping_instructions                             -- 出荷指示
        , cust_po_number                                    -- 顧客発注
        , order_source_ref                                  -- 受注ソース参照
        , schedule_ship_date                                -- 出荷予定日
        , schedule_arrival_date                             -- 着荷予定日
        , used_pallet_qty                                   -- パレット使用枚数
        , collected_pallet_qty                              -- パレット回収枚数
        , location_code                                     -- 出荷元
        , head_sales_branch                                 -- 管轄拠点
        , arrival_time_from                                 -- 着荷時間From
        , arrival_time_to                                   -- 着荷時間To
        , data_type                                         -- データタイプ
        , freight_carrier_code                              -- 運送業者
        , shipping_method_code                              -- 配送区分
        , delivery_no                                       -- 配送No
        , shipped_date                                      -- 出荷日
        , arrival_date                                      -- 着荷日
        , eos_data_type                                     -- EOSデータ種別
        , tranceration_number                               -- 伝送用枝番
        , ship_to_location                                  -- 入庫倉庫
        , rm_class                                          -- 倉替返品区分
        , ordered_class                                     -- 依頼区分
        , report_post_code                                  -- 報告部署
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終更新ログイン
        , request_id                                        -- 要求ID
        , program_application_id                            -- コンカレント・プログラム・アプリケーションID
        , program_id                                        -- コンカレント・プログラムID
        , program_update_date                               -- プログラム更新日
        , filler14                                          -- 運賃区分
      ) VALUES (
          gt_header_id_tab(item_cnt)                        -- ヘッダID
        , NULL                                              -- 受注タイプ
        , NULL                                              -- 受注日
        , gt_party_site_code_tab(item_cnt)                  -- 出荷先
        , NULL                                              -- 出荷指示
        , gt_cust_po_number_tab(item_cnt)                   -- 顧客発注
        , gt_order_source_ref_tab(item_cnt)                 -- 受注ソース参照
        , NULL                                              -- 出荷予定日
        , NULL                                              -- 着荷予定日
        , gt_used_pallet_qty_tab(item_cnt)                  -- パレット使用枚数
        , gt_collected_pallet_qty_tab(item_cnt)             -- パレット回収枚数
        , gt_location_code_tab(item_cnt)                    -- 出荷元
        , NULL                                              -- 管轄拠点
        , gt_arrival_time_from_tab(item_cnt)                -- 着荷時間From
        , gt_arrival_time_to_tab(item_cnt)                  -- 着荷時間To
        , gv_c_data_type_wsh                                -- データタイプ
        , gt_freight_carrier_code_tab(item_cnt)             -- 運送業者
        , gt_shipping_method_code_tab(item_cnt)             -- 配送区分
        , gt_delivery_no_tab(item_cnt)                      -- 配送No
        , gt_shipped_date_tab(item_cnt)                     -- 出荷日
        , gt_arrival_date_tab(item_cnt)                     -- 着荷日
        , gt_eos_data_tab(item_cnt)                         -- EOSデータ種別
        , NULL                                              -- 伝送用枝番
        , gt_ship_to_location_tab(item_cnt)                 -- 入庫倉庫
        , NULL                                              -- 倉替返品区分
        , NULL                                              -- 依頼区分
        , gt_report_post_code_tab(item_cnt)                 -- 報告部署
        , gn_user_id                                        -- 作成者
        , gd_sysdate                                        -- 作成日
        , gn_user_id                                        -- 最終更新者
        , gd_sysdate                                        -- 最終更新日
        , gn_login_id                                       -- 最終更新ログイン
        , gn_conc_request_id                                -- 要求ID
        , gn_prog_appl_id                                   -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                                -- コンカレント・プログラムID
        , gd_sysdate                                        -- プログラムによる更新日
        , gt_filler14_tab(item_cnt)                         -- 運賃区分
      );
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_details_proc
   * Description      : 明細登録 (E-7)
   ***********************************************************************************/
  PROCEDURE insert_details_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_details_proc'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- **************************************************
    -- *** 出荷依頼インタフェース明細（アドオン）登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_line_count
      INSERT INTO xxwsh_shipping_lines_if
      (   line_id                                           -- 明細ID
        , header_id                                         -- ヘッダID
        , line_number                                       -- 明細番号
        , orderd_item_code                                  -- 受注品目
        , case_quantity                                     -- ケース数
        , orderd_quantity                                   -- 数量
        , shiped_quantity                                   -- 出荷実績数量
        , designated_production_date                        -- 製造日(インタフェース用)
        , original_character                                -- 固有記号(インタフェース用)
        , use_by_date                                       -- 賞味期限(インタフェース用)
        , detailed_quantity                                 -- 内訳数量(インタフェース用)
        , ship_to_quantity                                  -- 入庫実績数量
        , reserved_status                                   -- 保留ステータス
        , lot_no                                            -- ロットNo
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終更新ログイン
        , request_id                                        -- 要求ID
        , program_application_id                            -- コンカレント・プログラム・アプリケーションID
        , program_id                                        -- コンカレント・プログラムID
        , program_update_date                               -- プログラム更新日
      ) VALUES (
          gt_line_id_tab(item_cnt)                          -- 明細ID
        , gt_line_header_id_tab(item_cnt)                   -- ヘッダID
        , NULL                                              -- 明細番号
        , gt_orderd_item_code_tab(item_cnt)                 -- 受注品目
        , NULL                                              -- ケース数
        , gt_orderd_quantity_tab(item_cnt)                  -- 数量
        , NULL                                              -- 出荷実績数量
        , gt_designated_prod_date_tab(item_cnt)             -- 製造日(インタフェース用)
        , gt_original_character_tab(item_cnt)               -- 固有記号(インタフェース用)
        , gt_use_by_date_tab(item_cnt)                      -- 賞味期限(インタフェース用)
        , gt_detailed_quantity_tab(item_cnt)                -- 内訳数量(インタフェース用)
        , NULL                                              -- 入庫実績数量
        , NULL                                              -- 保留ステータス
        , gt_lot_no_tab(item_cnt)                           -- ロットNo
        , gn_user_id                                        -- 作成者
        , gd_sysdate                                        -- 作成日
        , gn_user_id                                        -- 最終更新者
        , gd_sysdate                                        -- 最終更新日
        , gn_login_id                                       -- 最終更新ログイン
        , gn_conc_request_id                                -- 要求ID
        , gn_prog_appl_id                                   -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                                -- コンカレント・プログラムID
        , gd_sysdate                                        -- プログラムによる更新日
      );
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_details_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       --   ファイルＩＤ
    in_file_format IN  VARCHAR2,     --   フォーマットパターン
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_out_rep VARCHAR2(1000);  -- レポート出力
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 妥当性チェックステータス 初期化
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 関連データ取得 (E-1)
    -- ===============================
    init_proc(
      in_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ取得 (E-2,3)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- ファイルＩＤ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
-- 処理結果にかかわらず処理結果レポートを出力する
--#################################  アップロード固定メッセージ START  ###################################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_99e_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  アップロード固定メッセージ END   ###################################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 2008/07/08 Add ↓
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    -- 2008/07/08 Add ↑
    END IF;
--
    -- ===============================
    -- 妥当性チェック (E-4,5)
    -- ===============================
    check_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- 妥当性チェックでエラーがなかった場合
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
--
      -- ===============================
      -- 登録データセット
      -- ===============================
      set_data_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ヘッダ登録 (E-6)
      -- ===============================
      insert_header_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 明細登録 (E-7)
      -- ===============================
      insert_details_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ削除 (E-8)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- フォーマットパターン
      gd_sysdate,                     -- 対象日付
      gn_xxinv_parge_term,            -- パージ対象期間
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      -- 削除処理エラー時にRollBackをする為、妥当性チェックステータスを初期化
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- チェック処理エラー
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- 固定のエラーメッセージの出力をしないようにする
      lv_errmsg := gv_c_space;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id     IN  VARCHAR2,      --   ファイルＩＤ 2008/04/18 変更
    in_file_format IN  VARCHAR2       --   フォーマットパターン
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      TO_NUMBER(in_file_id),     -- ファイルＩＤ 2008/04/18 変更
      in_file_format, -- フォーマットパターン
      lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      lv_retcode,     -- リターン・コード             --# 固定 #
      lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxinv990004c;
/
