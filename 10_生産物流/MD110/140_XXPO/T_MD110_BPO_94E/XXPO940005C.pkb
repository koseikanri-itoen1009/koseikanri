CREATE OR REPLACE PACKAGE BODY xxpo940005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940005C(body)
 * Description      : 支給依頼アップロード処理
 * MD.050           : 取引先オンライン   T_MD050_BPO_940
 * MD.070           : 支給依頼アップロード処理 T_MD070_BPO_94E
 * Version          : 1.2
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
 *  2008/06/09    1.0   Oracle 椎名       初回作成
 *  2008/07/08    1.1   Oracle 山根一浩   I_S_192対応
 *  2008/07/17    1.2   Oracle 椎名       MD050指摘事項#13対応
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
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxpo940005c'; -- パッケージ名
--
  gv_c_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXINV';
  gv_c_msg_kbn_xxpo CONSTANT VARCHAR2(5)   := 'XXPO';
--
  -- メッセージ番号
  -- テーブルロックエラー
  gv_c_msg_94e_001   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10216';
  -- データ取得エラー
  gv_c_msg_94e_002   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10217';
  -- 伝送用枝番エラー
  gv_c_msg_94e_003   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10218';
  -- フォーマットチェックエラー
  gv_c_msg_94e_004   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10219';
  -- プロファイル取得エラー
  gv_c_msg_94e_005   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10220';
--
  -- ファイル名
  gv_c_msg_99e_101   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10222';
  -- アップロード日時
  gv_c_msg_99e_103   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10223';
  -- ファイルアップロード名称
  gv_c_msg_99e_104   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10224';
  -- フォーマットパターン
  gv_c_msg_99e_105   CONSTANT VARCHAR2(15)  := 'APP-XXPO-10225';
--
  -- トークン
  gv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NG_PROFILE';
  gv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
  -- プロファイル
  gv_c_parge_term_002          CONSTANT VARCHAR2(20)   := 'XXPO_PURGE_TERM_002';
  gv_c_parge_term_name         CONSTANT VARCHAR2(36)   := 'パージ対象期間:支給依頼';
  -- クイックコード タイプ
  gv_c_lookup_type             CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_c_format_type             CONSTANT VARCHAR2(20)  := 'フォーマットパターン';
  -- 対象DB名
  gv_c_xxpo_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                                  := 'ファイルアップロードインタフェーステーブル';
--
  -- *** ヘッダ項目名 ***
  gv_c_file_id_name               CONSTANT VARCHAR2(24)   := 'FILE_ID';
  gv_c_corporation_name           CONSTANT VARCHAR2(24)   := '会社名';
  gv_c_data_class                 CONSTANT VARCHAR2(24)   := 'データ種別';
  gv_c_transfer_branch_no         CONSTANT VARCHAR2(24)   := '伝送用枝番';
  gv_c_trans_type                 CONSTANT VARCHAR2(24)   := '発生区分';
  gv_c_weight_capacity_class      CONSTANT VARCHAR2(24)   := '重量容積区分';
  gv_c_requested_department_code  CONSTANT VARCHAR2(24)   := '依頼部署コード';
  gv_c_instruction_post_code      CONSTANT VARCHAR2(24)   := '指示部署コード';
  gv_c_vendor_code                CONSTANT VARCHAR2(24)   := '取引先コード';
  gv_c_ship_to_code               CONSTANT VARCHAR2(24)   := '配送先コード';
  gv_c_shipped_locat_code         CONSTANT VARCHAR2(24)   := '出庫倉庫コード';
  gv_c_freight_carrier_code       CONSTANT VARCHAR2(24)   := '運送業者コード';
  gv_c_ship_date                  CONSTANT VARCHAR2(24)   := '出庫日';
  gv_c_arvl_date                  CONSTANT VARCHAR2(24)   := '入庫日';
  gv_c_freight_charge_class       CONSTANT VARCHAR2(24)   := '運賃区分';
  gv_c_takeback_class             CONSTANT VARCHAR2(24)   := '引取区分';
  gv_c_arrival_time_from          CONSTANT VARCHAR2(24)   := '着荷時間FROM';
  gv_c_arrival_time_to            CONSTANT VARCHAR2(24)   := '着荷時間TO';
  gv_c_product_date               CONSTANT VARCHAR2(24)   := '製造日';
  gv_c_producted_item_code        CONSTANT VARCHAR2(24)   := '製造品目コード';
  gv_c_product_number             CONSTANT VARCHAR2(24)   := '製造番号';
  gv_c_header_description         CONSTANT VARCHAR2(24)   := 'ヘッダ摘要';
  gv_c_update_date                CONSTANT VARCHAR2(24)   := '更新日時';
--
  -- *** 明細項目名 ***
  gv_c_item_code                  CONSTANT VARCHAR2(24)   := '品目コード';
  gv_c_futai_code                 CONSTANT VARCHAR2(24)   := '付帯';
  gv_c_request_qty                CONSTANT VARCHAR2(24)   := '依頼数量';
  gv_c_line_description           CONSTANT VARCHAR2(24)   := '明細摘要';
--
  -- *** ヘッダ項目桁数 ***
  gn_c_corporation_name           CONSTANT NUMBER   := 5;   -- 会社名
  gn_c_data_class                 CONSTANT NUMBER   := 3;   -- データ種別
  gn_c_transfer_branch_no         CONSTANT NUMBER   := 2;   -- 伝送用枝番
  gn_c_weight_capacity_class      CONSTANT NUMBER   := 1;   -- 重量容積区分
  gn_c_requested_department_code  CONSTANT NUMBER   := 4;   -- 依頼部署コード
  gn_c_instruction_post_code      CONSTANT NUMBER   := 4;   -- 指示部署コード
  gn_c_vendor_code                CONSTANT NUMBER   := 4;   -- 取引先コード
  gn_c_ship_to_code               CONSTANT NUMBER   := 4;   -- 配送先コード
  gn_c_shipped_locat_code         CONSTANT NUMBER   := 4;   -- 出庫倉庫コード
  gn_c_freight_carrier_code       CONSTANT NUMBER   := 4;   -- 運送業者コード
  gn_c_freight_charge_class       CONSTANT NUMBER   := 1;   -- 運賃区分
  gn_c_takeback_class             CONSTANT NUMBER   := 1;   -- 引取区分
  gn_c_arrival_time_from          CONSTANT NUMBER   := 4;   -- 着荷時間FROM
  gn_c_arrival_time_to            CONSTANT NUMBER   := 4;   -- 着荷時間TO
  gn_c_producted_item_code        CONSTANT NUMBER   := 7;   -- 製造品目コード
  gn_c_product_number             CONSTANT NUMBER   := 10;  -- 製造番号
  gn_c_header_description         CONSTANT NUMBER   := 60;  -- ヘッダ摘要
--
  -- *** 明細項目桁数 ***
  gn_c_item_code                  CONSTANT NUMBER   := 7;   -- 品目コード
  gn_c_futai_code                 CONSTANT NUMBER   := 1;   -- 付帯
  gn_c_request_qty                CONSTANT NUMBER   := 12;  -- 依頼数量
  gn_c_few_request_qty            CONSTANT NUMBER   := 3;   -- 依頼数量(小数部)
  gn_c_line_description           CONSTANT NUMBER   := 20;  -- 明細摘要
--                                                                 
  -- *** ヘッダ明細区分 ***
  gn_c_tranc_header             CONSTANT VARCHAR2(2)    := '10';  -- ヘッダ
  gn_c_tranc_details            CONSTANT VARCHAR2(2)    := '20';  -- 明細
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
    corporation_name            VARCHAR2(32767), -- 会社名
    data_class                  VARCHAR2(32767), -- データ種別
    transfer_branch_no          VARCHAR2(32767), -- 伝送用枝番
    trans_type                  VARCHAR2(32767), -- 発生区分
    weight_capacity_class       VARCHAR2(32767), -- 重量容積区分
    requested_department_code   VARCHAR2(32767), -- 依頼部署コード
    instruction_post_code       VARCHAR2(32767), -- 指示部署コード
    vendor_code                 VARCHAR2(32767), -- 取引先コード
    ship_to_code                VARCHAR2(32767), -- 配送先コード
    shipped_locat_code          VARCHAR2(32767), -- 出庫倉庫コード
    freight_carrier_code        VARCHAR2(32767), -- 運送業者コード
    ship_date                   VARCHAR2(32767), -- 出庫日
    arvl_date                   VARCHAR2(32767), -- 入庫日
    freight_charge_class        VARCHAR2(32767), -- 運賃区分
    takeback_class              VARCHAR2(32767), -- 引取区分
    arrival_time_from           VARCHAR2(32767), -- 着荷時間FROM
    arrival_time_to             VARCHAR2(32767), -- 着荷時間TO
    product_date                VARCHAR2(32767), -- 製造日
    producted_item_code         VARCHAR2(32767), -- 製造品目コード
    product_number              VARCHAR2(32767), -- 製造番号
    header_description          VARCHAR2(32767), -- ヘッダ摘要
    item_code                   VARCHAR2(32767), -- 品目コード
    futai_code                  VARCHAR2(32767), -- 付帯
    request_qty                 VARCHAR2(32767), -- 依頼数量
    line_description            VARCHAR2(32767), -- 明細摘要
    update_date                 VARCHAR2(32767), -- 更新日時
    line                        VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message                 VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- 登録用PL/SQL表型（ヘッダ）
  -- ヘッダID
  TYPE  header_id_type                  IS TABLE OF  
      xxpo_supply_req_headers_if.supply_req_headers_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- 会社名
  TYPE  h_corporation_name_type         IS TABLE OF
      xxpo_supply_req_headers_if.corporation_name%TYPE                INDEX BY BINARY_INTEGER;
  -- データ種別
  TYPE  h_data_class_type               IS TABLE OF
      xxpo_supply_req_headers_if.data_class%TYPE                INDEX BY BINARY_INTEGER;
  -- 伝送用枝番
  TYPE  h_transfer_branch_no_type       IS TABLE OF
      xxpo_supply_req_headers_if.transfer_branch_no%TYPE        INDEX BY BINARY_INTEGER;
  -- 発生区分
  TYPE  trans_type_type                 IS TABLE OF
      xxpo_supply_req_headers_if.trans_type%TYPE                INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE  weight_capacity_class_type      IS TABLE OF
      xxpo_supply_req_headers_if.weight_capacity_class%TYPE     INDEX BY BINARY_INTEGER;
  -- 依頼部署コード
  TYPE  requested_department_code_type  IS TABLE OF
      xxpo_supply_req_headers_if.requested_department_code%TYPE INDEX BY BINARY_INTEGER;
  -- 指示部署コード
  TYPE  instruction_post_code_type      IS TABLE OF
      xxpo_supply_req_headers_if.instruction_post_code%TYPE     INDEX BY BINARY_INTEGER;
  -- 取引先コード
  TYPE  vendor_code_type                IS TABLE OF
      xxpo_supply_req_headers_if.vendor_code%TYPE               INDEX BY BINARY_INTEGER;
  -- 配送先コード
  TYPE  ship_to_code_type               IS TABLE OF
      xxpo_supply_req_headers_if.ship_to_code%TYPE              INDEX BY BINARY_INTEGER;
  -- 出庫倉庫コード
  TYPE  shipped_locat_code_type         IS TABLE OF
      xxpo_supply_req_headers_if.shipped_locat_code%TYPE        INDEX BY BINARY_INTEGER;
  -- 運送業者コード
  TYPE  freight_carrier_code_type       IS TABLE OF
      xxpo_supply_req_headers_if.freight_carrier_code%TYPE      INDEX BY BINARY_INTEGER;
  -- 出庫日
  TYPE  ship_date_type                  IS TABLE OF
      xxpo_supply_req_headers_if.ship_date%TYPE                 INDEX BY BINARY_INTEGER;
  -- 入庫日
  TYPE  arvl_date_type                  IS TABLE OF
      xxpo_supply_req_headers_if.arvl_date%TYPE                 INDEX BY BINARY_INTEGER;
  -- 運賃区分
  TYPE  freight_charge_class_type       IS TABLE OF
      xxpo_supply_req_headers_if.freight_charge_class%TYPE      INDEX BY BINARY_INTEGER;
  -- 引取区分
  TYPE  takeback_class_type             IS TABLE OF
      xxpo_supply_req_headers_if.takeback_class%TYPE            INDEX BY BINARY_INTEGER;
  -- 着荷時間FROM
  TYPE  arrival_time_from_type          IS TABLE OF
      xxpo_supply_req_headers_if.arrival_time_from%TYPE         INDEX BY BINARY_INTEGER;
  -- 着荷時間TO
  TYPE  arrival_time_to_type            IS TABLE OF
      xxpo_supply_req_headers_if.arrival_time_to%TYPE           INDEX BY BINARY_INTEGER;
  -- 製造日
  TYPE  product_date_type               IS TABLE OF
      xxpo_supply_req_headers_if.product_date%TYPE              INDEX BY BINARY_INTEGER;
  -- 製造品目コード
  TYPE  producted_item_code_type        IS TABLE OF
      xxpo_supply_req_headers_if.producted_item_code%TYPE       INDEX BY BINARY_INTEGER;
  -- 製造番号
  TYPE  product_number_type             IS TABLE OF
      xxpo_supply_req_headers_if.product_number%TYPE            INDEX BY BINARY_INTEGER;
  -- ヘッダ摘要
  TYPE  header_description_type         IS TABLE OF
      xxpo_supply_req_headers_if.header_description%TYPE        INDEX BY BINARY_INTEGER;
  -- 更新日時
  TYPE  h_update_date_type              IS TABLE OF
      xxpo_supply_req_headers_if.last_update_date%TYPE          INDEX BY BINARY_INTEGER;
--
  gt_header_id_tab                  header_id_type;
  gt_h_corporation_name_tab         h_corporation_name_type;
  gt_h_data_class_tab               h_data_class_type;
  gt_h_transfer_branch_no_tab       h_transfer_branch_no_type;
  gt_trans_type_tab                 trans_type_type;
  gt_weight_capacity_class_tab      weight_capacity_class_type;
  gt_requested_dep_code_tab         requested_department_code_type;
  gt_instruction_post_code_tab      instruction_post_code_type;
  gt_vendor_code_tab                vendor_code_type;
  gt_ship_to_code_tab               ship_to_code_type;
  gt_shipped_locat_code_tab         shipped_locat_code_type;
  gt_freight_carrier_code_tab       freight_carrier_code_type;
  gt_ship_date_tab                  ship_date_type;
  gt_arvl_date_tab                  arvl_date_type;
  gt_freight_charge_class_tab       freight_charge_class_type;
  gt_takeback_class_tab             takeback_class_type;
  gt_arrival_time_from_tab          arrival_time_from_type;
  gt_arrival_time_to_tab            arrival_time_to_type;
  gt_product_date_tab               product_date_type;
  gt_producted_item_code_tab        producted_item_code_type;
  gt_product_number_tab             product_number_type;
  gt_header_description_tab         header_description_type;
  gt_h_update_date_tab              h_update_date_type;
--
  -- 登録用PL/SQL表型（明細）
  -- 明細ID
  TYPE  line_id_type                    IS TABLE OF
      xxpo_supply_req_lines_if.supply_req_lines_if_id%TYPE    INDEX BY BINARY_INTEGER;
  -- 会社名
  TYPE  l_corporation_name_type         IS TABLE OF
      xxpo_supply_req_lines_if.corporation_name%TYPE          INDEX BY BINARY_INTEGER;
  -- データ種別
  TYPE  l_data_class_type               IS TABLE OF
      xxpo_supply_req_lines_if.data_class%TYPE                INDEX BY BINARY_INTEGER;
  -- 伝送用枝番
  TYPE  l_transfer_branch_no_type       IS TABLE OF
      xxpo_supply_req_lines_if.transfer_branch_no%TYPE        INDEX BY BINARY_INTEGER;
  -- ヘッダID
  TYPE  line_header_id_type             IS TABLE OF
      xxpo_supply_req_lines_if.supply_req_headers_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE  line_number_type                IS TABLE OF
      xxpo_supply_req_lines_if.line_number%TYPE               INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE  item_code_type                  IS TABLE OF
      xxpo_supply_req_lines_if.item_code%TYPE                 INDEX BY BINARY_INTEGER;
  -- 付帯
  TYPE  futai_code_type                 IS TABLE OF
      xxpo_supply_req_lines_if.futai_code%TYPE                INDEX BY BINARY_INTEGER;
  -- 依頼数量
  TYPE  request_qty_type                IS TABLE OF
      xxpo_supply_req_lines_if.request_qty%TYPE               INDEX BY BINARY_INTEGER;
  -- 明細摘要
  TYPE  line_description_type           IS TABLE OF
      xxpo_supply_req_lines_if.line_description%TYPE          INDEX BY BINARY_INTEGER;
  -- 更新日時
  TYPE  l_update_date_type              IS TABLE OF
      xxpo_supply_req_lines_if.last_update_date%TYPE          INDEX BY BINARY_INTEGER;
--
  gt_line_id_tab                    line_id_type;
  gt_l_corporation_name_tab         l_corporation_name_type;
  gt_l_data_class_tab               l_data_class_type;
  gt_l_transfer_branch_no_tab       l_transfer_branch_no_type;
  gt_line_header_id_tab             line_header_id_type;
  gt_line_number_tab                line_number_type;
  gt_item_code_tab                  item_code_type;
  gt_futai_code_tab                 futai_code_type;
  gt_request_qty_tab                request_qty_type;
  gt_line_description_tab           line_description_type;
  gt_l_update_date_tab              l_update_date_type;
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
  gn_xxpo_parge_term        NUMBER;                          -- パージ対象期間
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
    in_file_format  IN  VARCHAR2,     --  フォーマットパターン
    ov_errbuf       OUT VARCHAR2,     --  エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --  リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --  ユーザー・エラー・メッセージ --# 固定 #
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
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_002);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_005,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル値チェック
    BEGIN
      -- TO_NUMBERできなければエラー
      gn_xxpo_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_005,
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
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_94e_002,
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
      lv_retcode,         -- リターン ・コード              --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ   --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、又は、2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_002,
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
          fdata_tbl(gn_target_cnt).corporation_name           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).data_class                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).transfer_branch_no         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).trans_type                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).weight_capacity_class      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).requested_department_code  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).instruction_post_code      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).vendor_code                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).ship_to_code               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).shipped_locat_code         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).freight_carrier_code       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).ship_date                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).arvl_date                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).freight_charge_class       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN
          fdata_tbl(gn_target_cnt).takeback_class             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 16) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 17) THEN
          fdata_tbl(gn_target_cnt).arrival_time_to            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 18) THEN
          fdata_tbl(gn_target_cnt).product_date               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 19) THEN
          fdata_tbl(gn_target_cnt).producted_item_code        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 20) THEN
          fdata_tbl(gn_target_cnt).product_number             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 21) THEN
          fdata_tbl(gn_target_cnt).header_description         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 22) THEN
          fdata_tbl(gn_target_cnt).item_code                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 23) THEN
          fdata_tbl(gn_target_cnt).futai_code                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 24) THEN
          fdata_tbl(gn_target_cnt).request_qty                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 25) THEN
          fdata_tbl(gn_target_cnt).line_description           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 26) THEN
          fdata_tbl(gn_target_cnt).update_date                := SUBSTR(lv_line, 1, ln_length);
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_001,
                                            gv_c_tkn_table,
                                            gv_c_xxpo_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                            gv_c_msg_94e_002,
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
--
    lv_line_feed        VARCHAR2(1);                  -- 改行コード
--
    -- 総項目数
    ln_c_col         CONSTANT NUMBER      := 26;
--
    -- *** ローカル変数 ***
    lv_log_data                                      VARCHAR2(32767);  -- LOGデータ部退避用
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
      -- （行全体の長さ－行からカンマを抜いた長さ＝カンマの数）
      --    <> （正式な項目数－１＝正式なカンマの数）
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0)
           - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_c_comma,NULL)),0))
             <> (ln_c_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                           || gv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                                                       gv_c_msg_94e_004)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** 項目チェック（ヘッダ／明細）
        -- **************************************************
        -- ヘッダーの場合
        IF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_header) THEN
          -- ==============================
          --  会社名
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_corporation_name,
                                              fdata_tbl(ln_index).corporation_name,
                                              gn_c_corporation_name,
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
          --  データ種別
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_data_class,
                                              fdata_tbl(ln_index).data_class,
                                              gn_c_data_class,
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
          -- 発生区分
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_trans_type,
                                              fdata_tbl(ln_index).trans_type,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
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
          -- 重量容積区分
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_weight_capacity_class,
                                              fdata_tbl(ln_index).weight_capacity_class,
                                              gn_c_weight_capacity_class,
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
          -- 依頼部署コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_requested_department_code,
                                              fdata_tbl(ln_index).requested_department_code,
                                              gn_c_requested_department_code,
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
          -- 指示部署コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_instruction_post_code,
                                              fdata_tbl(ln_index).instruction_post_code,
                                              gn_c_instruction_post_code,
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
          -- 取引先コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_vendor_code,
                                              fdata_tbl(ln_index).vendor_code,
                                              gn_c_vendor_code,
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
          -- 配送先コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_to_code,
                                              fdata_tbl(ln_index).ship_to_code,
                                              gn_c_ship_to_code,
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
          xxcmn_common3_pkg.upload_item_check(gv_c_shipped_locat_code,
                                              fdata_tbl(ln_index).shipped_locat_code,
                                              gn_c_shipped_locat_code,
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
          -- 運送業者コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_freight_carrier_code,
                                              fdata_tbl(ln_index).freight_carrier_code,
                                              gn_c_freight_carrier_code,
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
          -- 出庫日
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_ship_date,
                                              fdata_tbl(ln_index).ship_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
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
          -- 入庫日
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arvl_date,
                                              fdata_tbl(ln_index).arvl_date,
                                              NULL,
                                              NULL,
                                              xxcmn_common3_pkg.gv_null_ng,
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
          -- 運賃区分
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_freight_charge_class,
                                              fdata_tbl(ln_index).freight_charge_class,
                                              gn_c_freight_charge_class,
                                              NULL,
-- 2008/07/17 v1.6 Update Start
--                                              xxcmn_common3_pkg.gv_null_ok,
                                              xxcmn_common3_pkg.gv_null_ng,
-- 2008/07/17 v1.6 Update End
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
          -- 引取区分
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_takeback_class,
                                              fdata_tbl(ln_index).takeback_class,
                                              gn_c_takeback_class,
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
          -- 着荷時間FROM
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_from,
                                              fdata_tbl(ln_index).arrival_time_from,
                                              gn_c_arrival_time_from,
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
          -- 着荷時間TO
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_arrival_time_to,
                                              fdata_tbl(ln_index).arrival_time_to,
                                              gn_c_arrival_time_to,
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
          xxcmn_common3_pkg.upload_item_check(gv_c_product_date,
                                              fdata_tbl(ln_index).product_date,
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
          -- 製造品目コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_producted_item_code,
                                              fdata_tbl(ln_index).producted_item_code,
                                              gn_c_producted_item_code,
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
          -- 製造番号
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_product_number,
                                              fdata_tbl(ln_index).product_number,
                                              gn_c_product_number,
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
          -- ヘッダ摘要
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_header_description,
                                              fdata_tbl(ln_index).header_description,
                                              gn_c_header_description,
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
        ELSIF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_details) THEN
          -- ==============================
          --  会社名
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_corporation_name,
                                              fdata_tbl(ln_index).corporation_name,
                                              gn_c_corporation_name,
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
          --  データ種別
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_data_class,
                                              fdata_tbl(ln_index).data_class,
                                              gn_c_data_class,
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
          -- 品目コード
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_item_code,
                                              fdata_tbl(ln_index).item_code,
                                              gn_c_item_code,
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
          -- 付帯
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_futai_code,
                                              fdata_tbl(ln_index).futai_code,
                                              gn_c_futai_code,
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
          -- 依頼数量
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_request_qty,
                                              fdata_tbl(ln_index).request_qty,
                                              gn_c_request_qty,
                                              gn_c_few_request_qty,
                                              xxcmn_common3_pkg.gv_null_ng,
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
          -- 明細摘要
          -- ==============================
          xxcmn_common3_pkg.upload_item_check(gv_c_line_description,
                                              fdata_tbl(ln_index).line_description,
                                              gn_c_line_description,
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
        -- 伝送用枝番が不正な場合
        ELSE
          fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                             || gv_c_err_msg_space
                                             || xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                                                         gv_c_msg_94e_003)
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
      IF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_header) THEN
--
        -- ヘッダ件数 インクリメント
        gn_header_count  := gn_header_count + 1;
--
        -- ヘッダID採番
        SELECT xxpo_supply_req_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- ヘッダ情報
        -- ヘッダID
        gt_header_id_tab(gn_header_count)
          := ln_header_id;
        -- 会社名
        gt_h_corporation_name_tab(gn_header_count)
          := fdata_tbl(ln_index).corporation_name;
        -- データ種別
        gt_h_data_class_tab(gn_header_count)
          := fdata_tbl(ln_index).data_class;
        -- 伝送用枝番
        gt_h_transfer_branch_no_tab(gn_header_count)
          := fdata_tbl(ln_index).transfer_branch_no;
        -- 発生区分
        gt_trans_type_tab(gn_header_count)
          := fdata_tbl(ln_index).trans_type;
        -- 重量容積区分
        gt_weight_capacity_class_tab(gn_header_count)
          := fdata_tbl(ln_index).weight_capacity_class;
        -- 依頼部署コード
        gt_requested_dep_code_tab(gn_header_count)
          := fdata_tbl(ln_index).requested_department_code;
        -- 指示部署コード
        gt_instruction_post_code_tab(gn_header_count)
          := fdata_tbl(ln_index).instruction_post_code;
        -- 取引先コード
        gt_vendor_code_tab(gn_header_count)
          := fdata_tbl(ln_index).vendor_code;
        -- 配送先コード
        gt_ship_to_code_tab(gn_header_count)
          := fdata_tbl(ln_index).ship_to_code;
        -- 出庫倉庫コード
        gt_shipped_locat_code_tab(gn_header_count)
          := fdata_tbl(ln_index).shipped_locat_code;
        -- 運送業者コード
        gt_freight_carrier_code_tab(gn_header_count)
          := fdata_tbl(ln_index).freight_carrier_code;
        -- 出庫日
        gt_ship_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).ship_date, 'YYYY/MM/DD');
        -- 入庫日
        gt_arvl_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).arvl_date, 'YYYY/MM/DD');
        -- 運賃区分
        gt_freight_charge_class_tab(gn_header_count)
          := fdata_tbl(ln_index).freight_charge_class;
        -- 引取区分
        gt_takeback_class_tab(gn_header_count)
          := fdata_tbl(ln_index).takeback_class;
        -- 着荷時間FROM
        gt_arrival_time_from_tab(gn_header_count)
          := fdata_tbl(ln_index).arrival_time_from;
        -- 着荷時間TO
        gt_arrival_time_to_tab(gn_header_count)
          := fdata_tbl(ln_index).arrival_time_to;
        -- 製造日
        gt_product_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).product_date, 'YYYY/MM/DD');
        -- 製造品目コード
        gt_producted_item_code_tab(gn_header_count)
          := fdata_tbl(ln_index).producted_item_code;
        -- 製造番号
        gt_product_number_tab(gn_header_count)
          := fdata_tbl(ln_index).product_number;
        -- ヘッダ摘要
        gt_header_description_tab(gn_header_count)
          := fdata_tbl(ln_index).header_description;
        -- 更新日時
        gt_h_update_date_tab(gn_header_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).update_date, 'YYYY/MM/DD HH24:MI:SS');
--
      -- 明細登録
      ELSIF (fdata_tbl(ln_index).transfer_branch_no = gn_c_tranc_details) THEN
--
        -- 明細件数 インクリメント
        gn_line_count   := gn_line_count + 1;
--
        -- 最初のレコードが明細の場合、ヘッダIDを採番
        IF (ln_header_id IS NULL) THEN
          -- ヘッダID採番
          SELECT xxpo_supply_req_headers_if_s1.NEXTVAL 
          INTO ln_header_id 
          FROM dual;
        END IF;
--
        -- 明細ID採番
        SELECT xxpo_supply_req_lines_if_s1.NEXTVAL
        INTO ln_line_id 
        FROM dual;
--
        -- 明細情報
        -- 明細ID
        gt_line_id_tab(gn_line_count)
          := ln_line_id;
        -- ヘッダID
        gt_line_header_id_tab(gn_line_count)
          := ln_header_id;
        -- 会社名
        gt_l_corporation_name_tab(gn_line_count)
          := fdata_tbl(ln_index).corporation_name;
        -- データ種別
        gt_l_data_class_tab(gn_line_count)
          := fdata_tbl(ln_index).data_class;
        -- 伝送用枝番
        gt_l_transfer_branch_no_tab(gn_line_count)
          := fdata_tbl(ln_index).transfer_branch_no;
        -- 品目コード
        gt_item_code_tab(gn_line_count)
          := fdata_tbl(ln_index).item_code;
        -- 付帯
        gt_futai_code_tab(gn_line_count)
          := fdata_tbl(ln_index).futai_code;
        -- 依頼数量量
        gt_request_qty_tab(gn_line_count)
          := TO_NUMBER(fdata_tbl(ln_index).request_qty);
        -- 明細摘要
        gt_line_description_tab(gn_line_count)
          := fdata_tbl(ln_index).line_description;
        -- 更新日時
        gt_l_update_date_tab(gn_line_count)
          := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).update_date, 'YYYY/MM/DD HH24:MI:SS');
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
    -- *** 支給依頼情報インタフェース（アドオン）登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_header_count
      INSERT INTO xxpo_supply_req_headers_if
      (   supply_req_headers_if_id                  -- 支給依頼情報インタフェースヘッダID
        , corporation_name                          -- 会社名
        , data_class                                -- データ種別
        , transfer_branch_no                        -- 伝送用枝番
        , trans_type                                -- 発生区分
        , weight_capacity_class                     -- 重量容積区分
        , requested_department_code                 -- 依頼部署コード
        , instruction_post_code                     -- 指示部署コード
        , vendor_code                               -- 取引先コード
        , ship_to_code                              -- 配送先コード
        , shipped_locat_code                        -- 出庫倉庫コード
        , freight_carrier_code                      -- 運送業者コード
        , ship_date                                 -- 出庫日
        , arvl_date                                 -- 入庫日
        , freight_charge_class                      -- 運賃区分
        , takeback_class                            -- 引取区分
        , arrival_time_from                         -- 着荷時間FROM
        , arrival_time_to                           -- 着荷時間TO
        , product_date                              -- 製造日
        , producted_item_code                       -- 製造品目コード
        , product_number                            -- 製造番号
        , header_description                        -- ヘッダ摘要
        , created_by                                -- 作成者
        , creation_date                             -- 作成日
        , last_updated_by                           -- 最終更新者
        , last_update_date                          -- 最終更新日
        , last_update_login                         -- 最終更新ログイン
        , request_id                                -- 要求ID
        , program_application_id                    -- コンカレント・プログラム・アプリケーションID
        , program_id                                -- コンカレント・プログラムID
        , program_update_date                       -- プログラム更新日
      ) VALUES (
          gt_header_id_tab(item_cnt)                -- ヘッダID
        , gt_l_corporation_name_tab(item_cnt)       -- 会社名
        , gt_h_data_class_tab(item_cnt)             -- データ種別
        , gt_h_transfer_branch_no_tab(item_cnt)     -- 伝送用枝番
        , gt_trans_type_tab(item_cnt)               -- 発生区分
        , gt_weight_capacity_class_tab(item_cnt)    -- 重量容積区分
        , gt_requested_dep_code_tab(item_cnt)       -- 依頼部署コード
        , gt_instruction_post_code_tab(item_cnt)    -- 指示部署コード
        , gt_vendor_code_tab(item_cnt)              -- 取引先コード
        , gt_shipped_locat_code_tab(item_cnt)       -- 配送先コード
        , gt_shipped_locat_code_tab(item_cnt)       -- 出庫倉庫コード
        , gt_freight_carrier_code_tab(item_cnt)     -- 運送業者コード
        , gt_ship_date_tab(item_cnt)                -- 出庫日
        , gt_arvl_date_tab(item_cnt)                -- 入庫日
        , gt_freight_charge_class_tab(item_cnt)     -- 運賃区分
        , gt_takeback_class_tab(item_cnt)           -- 引取区分
        , gt_arrival_time_from_tab(item_cnt)        -- 着荷時間FROM
        , gt_arrival_time_to_tab(item_cnt)          -- 着荷時間TO
        , gt_product_date_tab(item_cnt)             -- 製造日
        , gt_producted_item_code_tab(item_cnt)      -- 製造品目コード
        , gt_product_number_tab(item_cnt)           -- 製造番号
        , gt_header_description_tab(item_cnt)       -- ヘッダ摘要
        , gn_user_id                                -- 作成者
        , gd_sysdate                                -- 作成日
        , gn_user_id                                -- 最終更新者
        , gd_sysdate                                -- 最終更新日
        , gn_login_id                               -- 最終更新ログイン
        , gn_conc_request_id                        -- 要求ID
        , gn_prog_appl_id                           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                        -- コンカレント・プログラムID
        , gd_sysdate                                -- プログラムによる更新日
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
    -- *** 支給依頼情報インタフェース明細（アドオン）登録
    -- **************************************************
    FORALL item_cnt IN 1 .. gn_line_count
      INSERT INTO xxpo_supply_req_lines_if
      (   supply_req_lines_if_id                    -- 支給依頼情報インタフェース明細ID
        , corporation_name                          -- 会社名
        , data_class                                -- データ種別
        , transfer_branch_no                        -- 伝送用枝番
        , supply_req_headers_if_id                  -- 支給依頼情報インタフェースヘッダID
        , line_number                               -- 明細番号
        , item_code                                 -- 品目コード
        , futai_code                                -- 付帯
        , request_qty                               -- 依頼数量
        , line_description                          -- 明細摘要
        , created_by                                -- 作成者
        , creation_date                             -- 作成日
        , last_updated_by                           -- 最終更新者
        , last_update_date                          -- 最終更新日
        , last_update_login                         -- 最終更新ログイン
        , request_id                                -- 要求ID
        , program_application_id                    -- コンカレント・プログラム・アプリケーションID
        , program_id                                -- コンカレント・プログラムID
        , program_update_date                       -- プログラム更新日
      ) VALUES (
          gt_line_id_tab(item_cnt)                  -- 明細ID
        , gt_l_corporation_name_tab(item_cnt)       -- 会社名
        , gt_l_data_class_tab(item_cnt)             -- データ種別
        , gt_l_transfer_branch_no_tab(item_cnt)     -- 伝送用枝番
        , gt_line_header_id_tab(item_cnt)           -- ヘッダID
        , NULL                                      -- 明細番号
        , gt_item_code_tab(item_cnt)                -- 品目コード
        , gt_futai_code_tab(item_cnt)               -- 付帯
        , gt_request_qty_tab(item_cnt)              -- 依頼数量量
        , gt_line_description_tab(item_cnt)         -- 明細摘要
        , gn_user_id                                -- 作成者
        , gd_sysdate                                -- 作成日
        , gn_user_id                                -- 最終更新者
        , gd_sysdate                                -- 最終更新日
        , gn_login_id                               -- 最終更新ログイン
        , gn_conc_request_id                        -- 要求ID
        , gn_prog_appl_id                           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
        , gn_conc_program_id                        -- コンカレント・プログラムID
        , gd_sysdate                                -- プログラムによる更新日
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
--
-- 処理結果にかかわらず処理結果レポートを出力する
--#################################  アップロード固定メッセージ START  #############################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_101,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_104,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- フォーマットパターン
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_xxpo,
                                              gv_c_msg_99e_105,
                                              gv_c_tkn_value,
                                              in_file_format);
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
      gn_xxpo_parge_term,             -- パージ対象期間
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
    in_file_id     IN  VARCHAR2,      --   ファイルID
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
      TO_NUMBER(in_file_id),
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
END xxpo940005c;
/
