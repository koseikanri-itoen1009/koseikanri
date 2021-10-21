CREATE OR REPLACE PACKAGE BODY xxinv990011c
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : xxinv990011(body)
 * Description      : 出荷依頼（依頼№自動採番）のアップロード
 * MD.050           : ファイルアップロード   T_MD050_BPO_990
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              関連データ取得 (O-1)
 *  get_upload_data_proc   ファイルアップロードインタフェースデータ取得 (O-2)
 *  check_proc             ヘッダ/明細妥当性チェック (O-3)
 *  set_data_proc          登録データ設定 (O-4)
 *  insert_header_proc     ヘッダデータ登録 (O-5)
 *  insert_details_proc    明細データ登録 (O-6)
 *  submit_request         顧客発注からの出荷依頼自動作成起動 (O-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/09/28    1.0   SCSK 二村        新規作成
 *  2021/10/19    1.1   SCSK 二村        [E_本稼動_17407] 出荷依頼アップロードの新規開発 追加対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  cv_status_normal CONSTANT VARCHAR2(1) := '0';
  cv_status_warn   CONSTANT VARCHAR2(1) := '1';
  cv_status_error  CONSTANT VARCHAR2(1) := '2';
  cv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  cv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  cv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
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
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
  no_data_if_expt           EXCEPTION;     -- 対象データなし
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxinv990011'; -- パッケージ名
--
  -- アプリケーション短縮名
  cv_app_name_xxinv  CONSTANT VARCHAR2(5)   := 'XXINV';
  cv_app_name_xxcmn  CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_app_name_xxwsh  CONSTANT VARCHAR2(5)   := 'XXWSH';
--
  -- メッセージ番号
  cv_c_msg_99o_025   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- プロファイル取得エラー
  cv_c_msg_99o_032   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ロックエラー
  cv_c_msg_99o_008   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- 対象データなし
  cv_c_msg_99o_024   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- フォーマットチェックエラーメッセージ
  cv_c_msg_99o_238   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10238'; -- 拠点エラー
  cv_c_msg_99o_239   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10239'; -- 物流担当確認依頼区分エラー
--
  cv_c_msg_99o_101   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- ファイル名
  cv_c_msg_99o_103   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- アップロード日時
  cv_c_msg_99o_104   CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- ファイルアップロード名称
--
  cv_c_msg_99o_220   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10220'; -- フォーマットパターン
  cv_c_msg_99o_221   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10221'; -- パージ対象期間:出荷依頼
  cv_c_msg_99o_222   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10222'; -- ファイルアップロードインタフェーステーブル
--
  -- ヘッダ項目名
  cv_c_msg_99o_223   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10223'; -- 配送先
  cv_c_msg_99o_224   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10224'; -- 出荷元
  cv_c_msg_99o_225   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10225'; -- 出荷日
  cv_c_msg_99o_226   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10226'; -- 着日
  cv_c_msg_99o_227   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10227'; -- 入力拠点
  cv_c_msg_99o_228   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10228'; -- 管轄拠点
  cv_c_msg_99o_229   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10229'; -- 依頼区分
  cv_c_msg_99o_230   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10230'; -- PO#（その１）
  cv_c_msg_99o_231   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10231'; -- 時間指定From
  cv_c_msg_99o_232   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10232'; -- 時間指定To
  cv_c_msg_99o_233   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10233'; -- 摘要
  cv_c_msg_99o_234   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10234'; -- パレット回収枚数
  cv_c_msg_99o_235   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10235'; -- 物流担当確認依頼区分
  -- 明細項目名
  cv_c_msg_99o_236   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10236'; -- 品目
  cv_c_msg_99o_237   CONSTANT VARCHAR2(15)  := 'APP-XXINV-10237'; -- 数量
--
  -- トークン
  cv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NAME';
  cv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  cv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  cv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
  cv_c_tkn_kyoten              CONSTANT VARCHAR2(15)   := 'KYOTEN';
  -- プロファイル
  cv_c_parge_term_003          CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_003';
  cv_c_user                    CONSTANT VARCHAR2(15)   := 'USER_ID';
  -- クイックコード タイプ
  cv_c_lookup_type             CONSTANT VARCHAR2(17)   := 'XXINV_FILE_OBJECT';
  -- 対象DB名
--
  cv_c_file_id_name             CONSTANT VARCHAR2(20)   := 'FILE_ID';
--
  -- *** ヘッダ項目桁数 ***
  cn_c_party_site_code_l        CONSTANT NUMBER         := 9;   -- 配送先
  cn_c_location_code_l          CONSTANT NUMBER         := 4;   -- 出荷元
  cn_c_input_sales_branch_l     CONSTANT NUMBER         := 4;   -- 入力拠点
  cn_c_head_sales_branch_l      CONSTANT NUMBER         := 4;   -- 管轄拠点
  cn_c_ordered_class_l          CONSTANT NUMBER         := 1;   -- 依頼区分
-- Ver1.1 Mod Start
--  cn_c_cust_po_number_l         CONSTANT NUMBER         := 9;   -- PO#（その1）
  cn_c_cust_po_number_l         CONSTANT NUMBER         := 16;   -- PO#（その1）
-- Ver1.1 Mod End
  cn_c_arrival_time_l           CONSTANT NUMBER         := 4;   -- 時間指定From/To
-- Ver1.1 Mod Start
--  cn_c_shipping_instructions_l  CONSTANT NUMBER         := 40;  -- 摘要
  cn_c_shipping_instructions_l  CONSTANT NUMBER         := 60;  -- 摘要
-- Ver1.1 Mod End
  cn_c_collected_pallet_qty_l   CONSTANT NUMBER         := 3;   -- パレット回収枚数
  cn_c_collected_pallet_qty_d   CONSTANT NUMBER         := 0;   -- パレット回収枚数（小数点以下）
  cn_c_confirm_request_class_l  CONSTANT NUMBER         := 1;   -- 物流担当確認依頼区分
  -- *** 明細項目桁数 ***
  cn_c_orderd_item_code_l       CONSTANT NUMBER         := 7;   -- 品目
  cn_c_orderd_quantity_l        CONSTANT NUMBER         := 11;  -- 数量
  cn_c_orderd_quantity_d        CONSTANT NUMBER         := 3;   -- 数量（小数点以下）
--
  -- データ区分
  cv_c_data_type_wsh            CONSTANT VARCHAR2(2)    := '10';  -- 出荷依頼
--
  cv_c_comma                    CONSTANT VARCHAR2(1)    := ',';      -- カンマ
  cv_c_space                    CONSTANT VARCHAR2(1)    := ' ';      -- スペース
  cv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      '; -- スペース（6byte）
--
  cv_0                          CONSTANT VARCHAR2(1)    := '0';
  cv_1                          CONSTANT VARCHAR2(1)    := '1';
  cv_start_date                 CONSTANT VARCHAR2(10)   := '19000101';
  cv_end_date                   CONSTANT VARCHAR2(10)   := '99991231';
  cv_rrrrmmdd                   CONSTANT VARCHAR2(10)   := 'RRRRMMDD';
--
  cv_z                          CONSTANT VARCHAR2(1)    := 'Z';
  cn_9999                       CONSTANT NUMBER         := 9999;
  cv_rrrr_mm_dd                 CONSTANT VARCHAR2(15)   := 'RRRR/MM/DD';
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSVを格納するレコード
  TYPE file_data_rec IS RECORD(
    party_site_code               VARCHAR2(32767), -- 配送先
    location_code                 VARCHAR2(32767), -- 出荷元
    schedule_ship_date            VARCHAR2(32767), -- 出荷日
    schedule_arrival_date         VARCHAR2(32767), -- 着日
    input_sales_branch            VARCHAR2(32767), -- 入力拠点
    head_sales_branch             VARCHAR2(32767), -- 管轄拠点
    ordered_class                 VARCHAR2(32767), -- 依頼区分
    cust_po_number                VARCHAR2(32767), -- PO#（その１）
    arrival_time_from             VARCHAR2(32767), -- 時間指定From
    arrival_time_to               VARCHAR2(32767), -- 時間指定To
    shipping_instructions         VARCHAR2(32767), -- 摘要
    collected_pallet_qty          VARCHAR2(32767), -- パレット回収枚数
    confirm_request_class         VARCHAR2(32767), -- 物流担当確認依頼区分
    orderd_item_code              VARCHAR2(32767), -- 品目
    orderd_quantity               VARCHAR2(32767), -- 数量
    line                          VARCHAR2(32767), -- 行内容全て（内部制御用）
    err_message                   VARCHAR2(32767)  -- エラーメッセージ（内部制御用）
  );
--
  -- CSVを格納する結合配列
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- 登録用PL/SQL表型（ヘッダ）
  TYPE header_id_type              IS TABLE OF  
      xxwsh_shipping_headers_if.header_id%TYPE             INDEX BY BINARY_INTEGER;  -- ヘッダID
  TYPE party_site_code_type        IS TABLE OF 
      xxwsh_shipping_headers_if.party_site_code%TYPE       INDEX BY BINARY_INTEGER;  -- 出荷先
  TYPE location_code_type          IS TABLE OF 
      xxwsh_shipping_headers_if.location_code%TYPE         INDEX BY BINARY_INTEGER;  -- 出荷元
  TYPE schedule_ship_date_type     IS TABLE OF 
      xxwsh_shipping_headers_if.schedule_ship_date%TYPE    INDEX BY BINARY_INTEGER;  -- 出荷予定日
  TYPE schedule_arrival_date_type  IS TABLE OF 
      xxwsh_shipping_headers_if.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;  -- 着荷予定日
  TYPE input_sales_branch_type     IS TABLE OF 
      xxwsh_shipping_headers_if.input_sales_branch%TYPE    INDEX BY BINARY_INTEGER;  -- 入力拠点
  TYPE head_sales_branch_type      IS TABLE OF 
      xxwsh_shipping_headers_if.head_sales_branch%TYPE     INDEX BY BINARY_INTEGER;  -- 管轄拠点
  TYPE ordered_class_type          IS TABLE OF 
      xxwsh_shipping_headers_if.ordered_class%TYPE         INDEX BY BINARY_INTEGER;  -- 依頼区分
  TYPE cust_po_number_type         IS TABLE OF 
      xxwsh_shipping_headers_if.cust_po_number%TYPE        INDEX BY BINARY_INTEGER;  -- 顧客発注
  TYPE arrival_time_from_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_from%TYPE     INDEX BY BINARY_INTEGER;  -- 着荷時間From
  TYPE arrival_time_to_type      IS TABLE OF 
      xxwsh_shipping_headers_if.arrival_time_to%TYPE       INDEX BY BINARY_INTEGER;  -- 着荷時間To
  TYPE shipping_instructions_type  IS TABLE OF 
      xxwsh_shipping_headers_if.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;  -- 出荷指示
  TYPE collected_pallet_qty_type      IS TABLE OF 
      xxwsh_shipping_headers_if.collected_pallet_qty%TYPE  INDEX BY BINARY_INTEGER;  -- パレット回収枚数
  TYPE confirm_request_class_type  IS TABLE OF 
      xxwsh_shipping_headers_if.confirm_request_class%TYPE INDEX BY BINARY_INTEGER;  -- 物流担当確認依頼区分
  TYPE order_source_ref_type       IS TABLE OF 
      xxwsh_shipping_headers_if.order_source_ref%TYPE      INDEX BY BINARY_INTEGER;  -- 受注ソース参照
--
  gt_header_id_tab              header_id_type;             -- ヘッダID
  gt_party_site_code_tab        party_site_code_type;       -- 出荷先
  gt_location_code_tab          location_code_type;         -- 出荷元
  gt_schedule_ship_date_tab     schedule_ship_date_type;    -- 出荷予定日
  gt_schedule_arrival_date_tab  schedule_arrival_date_type; -- 着荷予定日
  gt_input_sales_branch_tab     input_sales_branch_type;    -- 入力拠点
  gt_head_sales_branch_tab      head_sales_branch_type;     -- 管轄拠点
  gt_ordered_class_tab          ordered_class_type;         -- 依頼区分
  gt_cust_po_number_tab         cust_po_number_type;        -- 顧客発注
  gt_arrival_time_from_tab      arrival_time_from_type;     -- 着荷時間From
  gt_arrival_time_to_tab        arrival_time_to_type;       -- 着荷時間To
  gt_shipping_instructions_tab  shipping_instructions_type; -- 出荷指示
  gt_collected_pallet_qty_tab   collected_pallet_qty_type;  -- パレット回収枚数
  gt_confirm_request_class_tab  confirm_request_class_type; -- 物流担当確認依頼区分
  gt_order_source_ref_tab       order_source_ref_type;      -- 受注ソース参照
--
  -- 登録用PL/SQL表型（明細）
  TYPE line_header_id_type              IS TABLE OF
      xxwsh_shipping_lines_if.header_id%TYPE                  INDEX BY BINARY_INTEGER;  -- 明細ID
  TYPE line_id_type                     IS TABLE OF
      xxwsh_shipping_lines_if.line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- ヘッダID
  TYPE orderd_item_code_type            IS TABLE OF
      xxwsh_shipping_lines_if.orderd_item_code%TYPE           INDEX BY BINARY_INTEGER;  -- 受注品目
  TYPE orderd_quantity_type             IS TABLE OF
      xxwsh_shipping_lines_if.orderd_quantity%TYPE            INDEX BY BINARY_INTEGER;  -- 数量
--
  gt_line_header_id_tab                 line_header_id_type;              -- 明細ID
  gt_line_id_tab                        line_id_type;                     -- ヘッダID
  gt_orderd_item_code_tab               orderd_item_code_type;            -- 受注品目
  gt_orderd_quantity_tab                orderd_quantity_type;             -- 数量
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
  gn_xxinv_parge_term       NUMBER;           -- パージ対象期間
  gv_file_name              VARCHAR2(256);    -- ファイル名
  gv_file_up_name           VARCHAR2(256);    -- ファイルアップロード名称
  gn_created_by             NUMBER(15);       -- 作成者
  gd_creation_date          DATE;             -- 作成日
  gv_check_proc_retcode     VARCHAR2(1);      -- 妥当性チェックステータス
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 関連データ取得 (O-1)
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
    lv_format_type      VARCHAR2(30);     -- フォーマットパターン
    lv_parge_term_name  VARCHAR2(30);     -- パージ対象期間:出荷依頼
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    -- プロファイル「パージ対象期間」取得
    lv_parge_term := FND_PROFILE.VALUE(cv_c_parge_term_003);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_parge_term IS NULL) THEN
      lv_parge_term_name := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name_xxinv
                             ,iv_name         => cv_c_msg_99o_221    -- パージ対象期間:出荷依頼
                            );
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_025
                    ,iv_token_name1  => cv_c_tkn_ng_profile
                    ,iv_token_value1 => lv_parge_term_name
                   );
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
        lv_parge_term_name := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_221    -- パージ対象期間:出荷依頼
                              );
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxinv
                      ,iv_name         => cv_c_msg_99o_025
                      ,iv_token_name1  => cv_c_tkn_ng_profile
                      ,iv_token_value1 => lv_parge_term_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ファイルアップロード名称取得
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- クイックコードVIEW
      WHERE   xlvv.lookup_type = cv_c_lookup_type       -- タイプ
      AND     xlvv.lookup_code = in_file_format         -- コード
      AND     ROWNUM           = 1;
    EXCEPTION
      --*** データ取得エラー ***
      WHEN NO_DATA_FOUND THEN
        lv_format_type := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name_xxinv
                             ,iv_name         => cv_c_msg_99o_220    -- フォーマットパターン
                            );
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxinv
                      ,iv_name         => cv_c_msg_99o_008
                      ,iv_token_name1  => cv_c_tkn_item
                      ,iv_token_value1 => lv_format_type
                      ,iv_token_name2  => cv_c_tkn_value
                      ,iv_token_value2 => in_file_format
                     );
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : ファイルアップロードインタフェースデータ取得 (O-2)
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
    lv_line               VARCHAR2(32767);    -- 改行コード迄の情報
    ln_col                NUMBER;             -- カラム
    lb_col                BOOLEAN  := TRUE;   -- カラム作成継続
    ln_length             NUMBER;             -- 長さ保管用
    lv_xxinv_mrp_file_ul  VARCHAR2(50);       -- ファイルアップロードインタフェーステーブル
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
    ov_retcode := cv_status_normal;
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_008
                    ,iv_token_name1  => cv_c_tkn_item
                    ,iv_token_value1 => cv_c_file_id_name
                    ,iv_token_name2  => cv_c_tkn_value
                    ,iv_token_value2 => in_file_id
                   );
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
        ln_length := INSTR(lv_line, cv_c_comma);
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
        IF     (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).party_site_code           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).location_code             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).schedule_ship_date        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).schedule_arrival_date     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).input_sales_branch        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).head_sales_branch         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).ordered_class             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).cust_po_number            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).arrival_time_from         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).arrival_time_to           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).shipping_instructions     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).collected_pallet_qty      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN
          fdata_tbl(gn_target_cnt).confirm_request_class     := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN
          fdata_tbl(gn_target_cnt).orderd_item_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN
          fdata_tbl(gn_target_cnt).orderd_quantity           := SUBSTR(lv_line, 1, ln_length);
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
      ov_retcode := cv_status_warn;
--
    --*** ロック取得エラー ***
    WHEN check_lock_expt THEN
      -- エラーメッセージ取得
      lv_xxinv_mrp_file_ul := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_222    -- ファイルアップロードインタフェーステーブル
                              );
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_032
                    ,iv_token_name1  => cv_c_tkn_table
                    ,iv_token_value1 => lv_xxinv_mrp_file_ul
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    --*** データ取得エラー ***
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxinv
                    ,iv_name         => cv_c_msg_99o_008
                    ,iv_token_name1  => cv_c_tkn_item
                    ,iv_token_value1 => cv_c_file_id_name
                    ,iv_token_name2  => cv_c_tkn_value
                    ,iv_token_value2 => in_file_id
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
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
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : ヘッダ/明細妥当性チェック (O-3)
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
    lv_line_feed  VARCHAR2(1);      -- 改行コード
--
    -- 総項目数
    ln_c_col      CONSTANT NUMBER  := 15;
--
    -- *** ローカル変数 ***
    lv_log_data                 VARCHAR2(32767);  --  LOGデータ部退避用
    lv_party_site_code          VARCHAR2(20);     --  配送先
    lv_location_code            VARCHAR2(20);     --  出荷元
    lv_ship_date                VARCHAR2(20);     --  出荷日
    lv_arrival_date             VARCHAR2(20);     --  着日
    lv_input_sales_branch       VARCHAR2(20);     --  入力拠点
    lv_head_sales_branch        VARCHAR2(20);     --  管轄拠点
    lv_ordered_class            VARCHAR2(20);     --  依頼区分
    lv_cust_po_number           VARCHAR2(20);     --  PO#（その１）
    lv_arrival_time_from        VARCHAR2(20);     --  時間指定From
    lv_arrival_time_to          VARCHAR2(20);     --  時間指定To
    lv_shipping_instructions    VARCHAR2(20);     --  摘要
    lv_collected_pallet_qty     VARCHAR2(20);     --  パレット回収枚数
    lv_confirm_request_class    VARCHAR2(20);     --  物流担当確認依頼区分
    lv_orderd_item_code         VARCHAR2(20);     --  品目
    lv_orderd_quantity          VARCHAR2(20);     --  数量
    ln_input_sales_cnt          NUMBER DEFAULT 0; -- 入力拠点チェック用
    ln_head_sales_cnt           NUMBER DEFAULT 0; -- 管轄拠点チェック用
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
    -- 初期化
    gv_check_proc_retcode := cv_status_normal; -- 妥当性チェックステータス
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
      --       <> （正式な項目数－１＝正式なカンマの数）
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0) 
          - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,cv_c_comma,NULL)),0)) <> (ln_c_col - 1)) 
      THEN
--
        fdata_tbl(ln_index).err_message := cv_c_err_msg_space
                                           || cv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                                                       cv_c_msg_99o_024)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** 項目チェック（ヘッダ／明細）
        -- **************************************************
        -- ==============================
        -- 配送先
        -- ==============================
        lv_party_site_code := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_app_name_xxinv
                                 ,iv_name         => cv_c_msg_99o_223  -- 配送先
                              );
        xxcmn_common3_pkg.upload_item_check(lv_party_site_code,
                                            fdata_tbl(ln_index).party_site_code,
                                            cn_c_party_site_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 出荷元
        -- ==============================
        lv_location_code := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_224    -- 出荷元
                            );
        xxcmn_common3_pkg.upload_item_check(lv_location_code,
                                            fdata_tbl(ln_index).location_code,
                                            cn_c_location_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 出荷日
        -- ==============================
        lv_ship_date := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name_xxinv
                           ,iv_name         => cv_c_msg_99o_225    -- 出荷日
                        );
        xxcmn_common3_pkg.upload_item_check(lv_ship_date,
                                            fdata_tbl(ln_index).schedule_ship_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 着日
        -- ==============================
        lv_arrival_date := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_226    -- 着日
                            );
        xxcmn_common3_pkg.upload_item_check(lv_arrival_date,
                                            fdata_tbl(ln_index).schedule_arrival_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 入力拠点
        -- ==============================
        lv_input_sales_branch := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_227    -- 入力拠点
                            );
        xxcmn_common3_pkg.upload_item_check(lv_input_sales_branch,
                                            fdata_tbl(ln_index).input_sales_branch,
                                            cn_c_input_sales_branch_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        -- プロシージャー正常終了
        ELSIF (lv_retcode = cv_status_normal) THEN
          -- 整合性チェック
          BEGIN
            SELECT COUNT(1) 
            INTO   ln_input_sales_cnt
            FROM   fnd_user fu
                  ,per_all_people_f papf
                  ,per_all_assignments_f paaf
                  ,xxcmn_locations_v xlv
                  ,xxcmn_cust_accounts_v xcav
            WHERE fu.user_id = fnd_profile.VALUE( cv_c_user )
              AND fu.employee_id = papf.person_id
              AND papf.person_id = paaf.person_id
              AND NVL( papf.effective_start_date, TO_DATE( cv_start_date, cv_rrrrmmdd )) <= TRUNC( SYSDATE )
              AND NVL( papf.effective_end_date, TO_DATE( cv_end_date, cv_rrrrmmdd )) >= TRUNC( SYSDATE )
              AND NVL( paaf.effective_start_date, TO_DATE( cv_start_date, cv_rrrrmmdd )) <= TRUNC( SYSDATE )
              AND NVL( paaf.effective_end_date, TO_DATE( cv_end_date, cv_rrrrmmdd )) >= TRUNC( SYSDATE )
              AND paaf.location_id = xlv.location_id
              AND xlv.location_code = xcav.party_number
              AND xcav.customer_class_code = '1'
              AND xcav.party_number = fdata_tbl(ln_index).input_sales_branch
            ;
            IF (ln_input_sales_cnt = 0) THEN
              lv_retcode := cv_status_warn;
              lv_errmsg := cv_c_err_msg_space
                            || cv_c_err_msg_space
                            || xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_app_name_xxinv
                                ,iv_name         => cv_c_msg_99o_238       -- 拠点エラー
                                ,iv_token_name1  => cv_c_tkn_item
                                ,iv_token_value1 => lv_input_sales_branch  -- 入力拠点
                                ,iv_token_name2  => cv_c_tkn_kyoten
                                ,iv_token_value2 => fdata_tbl(ln_index).input_sales_branch);
              fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                  || lv_errmsg
                                                  || lv_line_feed;
            END IF;
          END;
        END IF;
--
        -- ==============================
        -- 管轄拠点
        -- ==============================
        lv_head_sales_branch := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_app_name_xxinv
                                 ,iv_name         => cv_c_msg_99o_228    -- 管轄拠点
                                );
        xxcmn_common3_pkg.upload_item_check(lv_head_sales_branch,
                                            fdata_tbl(ln_index).head_sales_branch,
                                            cn_c_head_sales_branch_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        -- プロシージャー正常終了
        ELSIF (lv_retcode = cv_status_normal) THEN
          -- 整合性チェック
          BEGIN
            SELECT COUNT(1)
            INTO   ln_head_sales_cnt
            FROM   xxwsh_head_branch_rf_dept_v xhbrd
            WHERE  xhbrd.user_id = FND_PROFILE.VALUE( cv_c_user )
              AND  xhbrd.party_number = fdata_tbl(ln_index).head_sales_branch
            ;
            IF (ln_head_sales_cnt = 0) THEN
              lv_retcode := cv_status_warn;
              lv_errmsg := cv_c_err_msg_space
                            || cv_c_err_msg_space
                            || xxcmn_common_pkg.get_msg(
                                 iv_application  => cv_app_name_xxinv
                                ,iv_name         => cv_c_msg_99o_238      -- 拠点エラー
                                ,iv_token_name1  => cv_c_tkn_item
                                ,iv_token_value1 => lv_head_sales_branch  -- 管轄拠点
                                ,iv_token_name2  => cv_c_tkn_kyoten
                                ,iv_token_value2 => fdata_tbl(ln_index).head_sales_branch);
              fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                  || lv_errmsg
                                                  || lv_line_feed;
            END IF;
          END;
        END IF;
--
        -- ==============================
        --  依頼区分
        -- ==============================
        lv_ordered_class := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_229    -- 依頼区分
                            );
        xxcmn_common3_pkg.upload_item_check(lv_ordered_class,
                                            fdata_tbl(ln_index).ordered_class,
                                            cn_c_ordered_class_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- PO#（その１）
        -- ==============================
        lv_cust_po_number := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_230    -- PO#（その１）
                            );
        xxcmn_common3_pkg.upload_item_check(lv_cust_po_number,
                                            fdata_tbl(ln_index).cust_po_number,
                                            cn_c_cust_po_number_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 時間指定From
        -- ==============================
        lv_arrival_time_from := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_231    -- 時間指定From
                            );
        xxcmn_common3_pkg.upload_item_check(lv_arrival_time_from,
                                            fdata_tbl(ln_index).arrival_time_from,
                                            cn_c_arrival_time_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 時間指定To
        -- ==============================
        lv_arrival_time_to := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_232    -- 時間指定To
                            );
        xxcmn_common3_pkg.upload_item_check(lv_arrival_time_to,
                                            fdata_tbl(ln_index).arrival_time_to,
                                            cn_c_arrival_time_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 摘要
        -- ==============================
        lv_shipping_instructions := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_233    -- 摘要
                            );
        xxcmn_common3_pkg.upload_item_check(lv_shipping_instructions,
                                            fdata_tbl(ln_index).shipping_instructions,
                                            cn_c_shipping_instructions_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        --  パレット回収枚数
        -- ==============================
        lv_collected_pallet_qty := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_234    -- パレット回収枚数
                            );
        xxcmn_common3_pkg.upload_item_check(lv_collected_pallet_qty,
                                            fdata_tbl(ln_index).collected_pallet_qty,
                                            cn_c_collected_pallet_qty_l,
                                            cn_c_collected_pallet_qty_d,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 物流担当確認依頼区分
        -- ==============================
        lv_confirm_request_class := xxccp_common_pkg.get_msg(
                                      iv_application  => cv_app_name_xxinv
                                     ,iv_name         => cv_c_msg_99o_235    -- 物流担当確認依頼区分
                                    );
        xxcmn_common3_pkg.upload_item_check(lv_confirm_request_class,
                                            fdata_tbl(ln_index).confirm_request_class,
                                            cn_c_confirm_request_class_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        -- プロシージャー正常終了
        ELSIF (lv_retcode = cv_status_normal) THEN
          -- 整合性チェック
          IF (fdata_tbl(ln_index).confirm_request_class IS NULL OR
              fdata_tbl(ln_index).confirm_request_class = cv_0 OR
              fdata_tbl(ln_index).confirm_request_class = cv_1) THEN
                NULL;
          ELSE
            lv_retcode := cv_status_warn;
            lv_errmsg := cv_c_err_msg_space
                          || cv_c_err_msg_space
                          || xxcmn_common_pkg.get_msg(
                               iv_application  => cv_app_name_xxinv
                              ,iv_name         => cv_c_msg_99o_239);  -- 物流担当確認依頼区分エラー
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || lv_errmsg
                                                || lv_line_feed;
          END IF;
        END IF;
--
        -- ==============================
        -- 品目
        -- ==============================
        lv_orderd_item_code := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_236    -- 品目
                            );
        xxcmn_common3_pkg.upload_item_check(lv_orderd_item_code,
                                            fdata_tbl(ln_index).orderd_item_code,
                                            cn_c_orderd_item_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ==============================
        -- 数量
        -- ==============================
        lv_orderd_quantity := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name_xxinv
                               ,iv_name         => cv_c_msg_99o_237    -- 数量
                            );
        xxcmn_common3_pkg.upload_item_check(lv_orderd_quantity,
                                            fdata_tbl(ln_index).orderd_quantity,
                                            cn_c_orderd_quantity_l,
                                            cn_c_orderd_quantity_d,
                                            xxcmn_common3_pkg.gv_null_ok,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- 項目チェックエラー
        IF (lv_retcode = cv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- プロシージャー異常終了
        ELSIF (lv_retcode = cv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
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
        lv_log_data := TO_CHAR(ln_index,'99999') || cv_c_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- エラーメッセージ部出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- 妥当性チェックステータス
        gv_check_proc_retcode := cv_status_error;
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
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
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc (O-4)
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
     cv_6              CONSTANT VARCHAR2(1) := '6';      -- 採番番号区分（依頼No.）
--
    -- *** ローカル変数 ***
    ln_header_id      NUMBER;   -- ヘッダID
    ln_line_id        NUMBER;   -- 明細ID
    lv_seq_no         xxwsh_shipping_headers_if.order_source_ref%TYPE;  -- 受注ソース参照
--
    -- ヘッダ項目比較用
    lt_party_site_code_bk          xxwsh_shipping_headers_if.party_site_code%TYPE;       -- 配送先
    lt_location_code_bk            xxwsh_shipping_headers_if.location_code%TYPE;         -- 出荷元
    lt_ship_date_bk                xxwsh_shipping_headers_if.schedule_ship_date%TYPE;    -- 出荷日
    lt_arrival_date_bk             xxwsh_shipping_headers_if.schedule_arrival_date%TYPE; -- 着日
    lt_input_sales_branch_bk       xxwsh_shipping_headers_if.input_sales_branch%TYPE;    -- 入力拠点
    lt_head_sales_branch_bk        xxwsh_shipping_headers_if.head_sales_branch%TYPE;     -- 管轄拠点
    lt_ordered_class_bk            xxwsh_shipping_headers_if.ordered_class%TYPE;         -- 依頼区分
    lt_cust_po_number_bk           xxwsh_shipping_headers_if.cust_po_number%TYPE;        -- PO#（その１）
    lt_arrival_time_from_bk        xxwsh_shipping_headers_if.arrival_time_from%TYPE;     -- 時間指定From
    lt_arrival_time_to_bk          xxwsh_shipping_headers_if.arrival_time_to%TYPE;       -- 時間指定To
    lt_shipping_instructions_bk    xxwsh_shipping_headers_if.shipping_instructions%TYPE; -- 摘要
    lt_collected_pallet_qty_bk     xxwsh_shipping_headers_if.collected_pallet_qty%TYPE;  -- パレット回収枚数
    lt_confirm_request_class_bk    xxwsh_shipping_headers_if.confirm_request_class%TYPE; -- 物流担当確認依頼区分
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
    -- 件数初期化
    gn_line_count     := 0;
    gn_header_count   := 0;
--
    -- ローカル変数初期化
    ln_header_id                 := NULL;
    ln_line_id                   := NULL;
    lt_party_site_code_bk        := NULL;
    lt_location_code_bk          := NULL;
    lt_ship_date_bk              := NULL;
    lt_arrival_date_bk           := NULL;
    lt_input_sales_branch_bk     := NULL;
    lt_head_sales_branch_bk      := NULL;
    lt_ordered_class_bk          := NULL;
    lt_cust_po_number_bk         := NULL;
    lt_arrival_time_from_bk      := NULL;
    lt_arrival_time_to_bk        := NULL;
    lt_shipping_instructions_bk  := NULL;
    lt_collected_pallet_qty_bk   := NULL;
    lt_confirm_request_class_bk  := NULL;
--
    -- **************************************************
    -- *** 登録用PL/SQL表編集（2行目から）
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- ヘッダ項目が前行とひとつでも異なる場合、ヘッダ登録
      IF (NVL(fdata_tbl(ln_index).party_site_code,cv_z)       <> NVL(lt_party_site_code_bk,cv_z)         OR
          NVL(fdata_tbl(ln_index).location_code,cv_z)         <> NVL(lt_location_code_bk,cv_z)           OR
          NVL(FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, cv_rrrr_mm_dd), FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))
            <> NVL(lt_ship_date_bk, FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))      OR
          NVL(FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, cv_rrrr_mm_dd), FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))
            <> NVL(lt_arrival_date_bk, FND_DATE.STRING_TO_DATE(cv_start_date,cv_rrrr_mm_dd))   OR
          NVL(fdata_tbl(ln_index).input_sales_branch,cv_z)    <> NVL(lt_input_sales_branch_bk,cv_z)      OR
          NVL(fdata_tbl(ln_index).head_sales_branch,cv_z)     <> NVL(lt_head_sales_branch_bk,cv_z)       OR
          NVL(fdata_tbl(ln_index).ordered_class,cv_z)         <> NVL(lt_ordered_class_bk,cv_z)           OR
          NVL(fdata_tbl(ln_index).cust_po_number,cv_z)        <> NVL(lt_cust_po_number_bk,cv_z)          OR
          NVL(fdata_tbl(ln_index).arrival_time_from,cv_z)     <> NVL(lt_arrival_time_from_bk,cv_z)       OR
          NVL(fdata_tbl(ln_index).arrival_time_to,cv_z)       <> NVL(lt_arrival_time_to_bk,cv_z)         OR
          NVL(fdata_tbl(ln_index).shipping_instructions,cv_z) <> NVL(lt_shipping_instructions_bk,cv_z)   OR
          NVL(fdata_tbl(ln_index).collected_pallet_qty,cn_9999)  <> NVL(lt_collected_pallet_qty_bk,cn_9999) OR
          NVL(fdata_tbl(ln_index).confirm_request_class,cv_0) <> NVL(lt_confirm_request_class_bk,cv_0))  THEN
--
        -- ヘッダ件数 インクリメント
        gn_header_count  := gn_header_count + 1;
--
        -- ヘッダID採番
        SELECT xxwsh_shipping_headers_if_s1.NEXTVAL 
        INTO ln_header_id 
        FROM dual;
--
        -- 受注ソース参照（依頼No.）初期化
        lv_seq_no         := NULL;
        -- 受注ソース参照（依頼No.）採番
        xxcmn_common_pkg.get_seq_no(
          cv_6                  -- 採番する番号を表す区分
         ,lv_seq_no             -- 採番した固定長12桁の番号
         ,lv_errbuf             -- エラー・メッセージ
         ,lv_retcode            -- リターン・コード
         ,lv_errmsg             -- ユーザー・エラー・メッセージ
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ヘッダ情報
        gt_header_id_tab(gn_header_count)             := ln_header_id;                              -- ヘッダID
        gt_party_site_code_tab(gn_header_count)       := fdata_tbl(ln_index).party_site_code;       -- 出荷先
        gt_location_code_tab(gn_header_count)         := fdata_tbl(ln_index).location_code;         -- 出荷元
        gt_schedule_ship_date_tab(gn_header_count) 
                 := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, cv_rrrr_mm_dd);    -- 出荷予定日
        gt_schedule_arrival_date_tab(gn_header_count) 
                 := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, cv_rrrr_mm_dd); -- 着荷予定日
        gt_input_sales_branch_tab(gn_header_count)    := fdata_tbl(ln_index).input_sales_branch;    -- 入力拠点
        gt_head_sales_branch_tab(gn_header_count)     := fdata_tbl(ln_index).head_sales_branch;     -- 管轄拠点
        gt_ordered_class_tab(gn_header_count)         := fdata_tbl(ln_index).ordered_class;         -- 依頼区分
        gt_cust_po_number_tab(gn_header_count)        := fdata_tbl(ln_index).cust_po_number;        -- 顧客発注
        gt_arrival_time_from_tab(gn_header_count)     := fdata_tbl(ln_index).arrival_time_from;     -- 着荷時間From
        gt_arrival_time_to_tab(gn_header_count)       := fdata_tbl(ln_index).arrival_time_to;       -- 着荷時間To
        gt_shipping_instructions_tab(gn_header_count) := fdata_tbl(ln_index).shipping_instructions; -- 出荷指示
        gt_collected_pallet_qty_tab(gn_header_count)  := fdata_tbl(ln_index).collected_pallet_qty;  -- パレット回収枚数
        gt_confirm_request_class_tab(gn_header_count) := fdata_tbl(ln_index).confirm_request_class; -- 物流担当確認依頼区分
        gt_order_source_ref_tab(gn_header_count)      := lv_seq_no;                                 -- 受注ソース参照
--
      END IF;
      -- 明細登録
      -- 明細件数 インクリメント
      gn_line_count   := gn_line_count + 1;
--
      -- 明細ID採番
      SELECT xxwsh_shipping_lines_if_s1.NEXTVAL
      INTO ln_line_id 
      FROM dual;
--
      -- 明細情報
      gt_line_id_tab(gn_line_count)            := ln_line_id;                                       -- 明細ID
      gt_line_header_id_tab(gn_line_count)     := ln_header_id;                                     -- ヘッダID
      gt_orderd_item_code_tab(gn_line_count)   := fdata_tbl(ln_index).orderd_item_code;             -- 受注品目
      gt_orderd_quantity_tab(gn_line_count)    := TO_NUMBER(fdata_tbl(ln_index).orderd_quantity);   -- 数量
--
      -- 比較用にヘッダ項目設定
      lt_party_site_code_bk       := fdata_tbl(ln_index).party_site_code;                     -- 出荷先
      lt_location_code_bk         := fdata_tbl(ln_index).location_code;                       -- 出荷元
      lt_ship_date_bk  
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_ship_date, cv_rrrr_mm_dd);    -- 出荷日
      lt_arrival_date_bk  
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).schedule_arrival_date, cv_rrrr_mm_dd); -- 着日
      lt_input_sales_branch_bk    := fdata_tbl(ln_index).input_sales_branch;                  -- 入力拠点
      lt_head_sales_branch_bk     := fdata_tbl(ln_index).head_sales_branch;                   -- 管轄拠点
      lt_ordered_class_bk         := fdata_tbl(ln_index).ordered_class;                       -- 依頼区分
      lt_cust_po_number_bk        := fdata_tbl(ln_index).cust_po_number;                      -- 顧客発注
      lt_arrival_time_from_bk     := fdata_tbl(ln_index).arrival_time_from;                   -- 時間指定From
      lt_arrival_time_to_bk       := fdata_tbl(ln_index).arrival_time_to;                     -- 時間指定To
      lt_shipping_instructions_bk := fdata_tbl(ln_index).shipping_instructions;               -- 摘要
      lt_collected_pallet_qty_bk  := fdata_tbl(ln_index).collected_pallet_qty;                -- パレット回収枚数
      lt_confirm_request_class_bk := fdata_tbl(ln_index).confirm_request_class;               -- 物流担当確認依頼区分
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
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_header_proc
   * Description      : ヘッダデータ登録 (O-5)
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
    ov_retcode := cv_status_normal;
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
      (   header_id                                 -- ヘッダID
        , order_type                                -- 受注タイプ
        , ordered_date                              -- 受注日
        , party_site_code                           -- 出荷先
        , shipping_instructions                     -- 出荷指示
        , cust_po_number                            -- 顧客発注
        , order_source_ref                          -- 受注ソース参照
        , schedule_ship_date                        -- 出荷予定日
        , schedule_arrival_date                     -- 着荷予定日
        , used_pallet_qty                           -- パレット使用枚数
        , collected_pallet_qty                      -- パレット回収枚数
        , location_code                             -- 出荷元
        , input_sales_branch                        -- 入力拠点
        , head_sales_branch                         -- 管轄拠点
        , arrival_time_from                         -- 着荷時間From
        , arrival_time_to                           -- 着荷時間To
        , data_type                                 -- データタイプ
        , freight_carrier_code                      -- 運送業者
        , shipping_method_code                      -- 配送区分
        , delivery_no                               -- 配送No
        , shipped_date                              -- 出荷日
        , arrival_date                              -- 着荷日
        , eos_data_type                             -- EOSデータ種別
        , tranceration_number                       -- 伝送用枝番
        , ship_to_location                          -- 入庫倉庫
        , rm_class                                  -- 倉替返品区分
        , ordered_class                             -- 依頼区分
        , report_post_code                          -- 報告部署
        , line_number                               -- 制御番号
        , confirm_request_class                     -- 物流担当確認依頼区分
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
        , NULL                                      -- 受注タイプ
        , NULL                                      -- 受注日
        , gt_party_site_code_tab(item_cnt)          -- 出荷先
        , gt_shipping_instructions_tab(item_cnt)    -- 出荷指示
        , gt_cust_po_number_tab(item_cnt)           -- 顧客発注
        , gt_order_source_ref_tab(item_cnt)         -- 受注ソース参照
        , gt_schedule_ship_date_tab(item_cnt)       -- 出荷予定日
        , gt_schedule_arrival_date_tab(item_cnt)    -- 着荷予定日
        , NULL                                      -- パレット使用枚数
        , gt_collected_pallet_qty_tab(item_cnt)     -- パレット回収枚数
        , gt_location_code_tab(item_cnt)            -- 出荷元
        , gt_input_sales_branch_tab(item_cnt)       -- 入力拠点
        , gt_head_sales_branch_tab(item_cnt)        -- 管轄拠点
        , gt_arrival_time_from_tab(item_cnt)        -- 着荷時間From
        , gt_arrival_time_to_tab(item_cnt)          -- 着荷時間To
        , cv_c_data_type_wsh                        -- データタイプ
        , NULL                                      -- 運送業者
        , NULL                                      -- 配送区分
        , NULL                                      -- 配送No
        , NULL                                      -- 出荷日
        , NULL                                      -- 着荷日
        , NULL                                      -- EOSデータ種別
        , NULL                                      -- 伝送用枝番
        , NULL                                      -- 入庫倉庫
        , NULL                                      -- 倉替返品区分
        , gt_ordered_class_tab(item_cnt)            -- 依頼区分
        , NULL                                      -- 報告部署
        , NULL                                      -- 制御番号
        , NVL(gt_confirm_request_class_tab(item_cnt),cv_0) -- 物流担当確認依頼区分
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
  END insert_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_details_proc
   * Description      : 明細データ登録 (O-6)
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
    ov_retcode := cv_status_normal;
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
      (   line_id                                   -- 明細ID
        , header_id                                 -- ヘッダID
        , line_number                               -- 明細番号
        , orderd_item_code                          -- 受注品目
        , case_quantity                             -- ケース数
        , orderd_quantity                           -- 数量
        , shiped_quantity                           -- 出荷実績数量
        , designated_production_date                -- 製造日(インタフェース用)
        , original_character                        -- 固有記号(インタフェース用)
        , use_by_date                               -- 賞味期限(インタフェース用)
        , detailed_quantity                         -- 内訳数量(インタフェース用)
        , ship_to_quantity                          -- 入庫実績数量
        , reserved_status                           -- 保留ステータス
        , lot_no                                    -- ロットNo
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
        , gt_line_header_id_tab(item_cnt)           -- ヘッダID
        , NULL                                      -- 明細番号
        , gt_orderd_item_code_tab(item_cnt)         -- 受注品目
        , NULL                                      -- ケース数
        , gt_orderd_quantity_tab(item_cnt)          -- 数量
        , NULL                                      -- 出荷実績数量
        , NULL                                      -- 製造日(インタフェース用)
        , NULL                                      -- 固有記号(インタフェース用)
        , NULL                                      -- 賞味期限(インタフェース用)
        , NULL                                      -- 内訳数量(インタフェース用)
        , NULL                                      -- 入庫実績数量
        , NULL                                      -- 保留ステータス
        , NULL                                      -- ロットNo
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
      -- 成功件数カウント
      gn_normal_cnt := gn_line_count;
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
  END insert_details_proc;
--
  /**********************************************************************************
   * Procedure Name   : submit_request
   * Description      : 顧客発注からの出荷依頼自動作成起動 (O-7)
   **********************************************************************************/
  PROCEDURE submit_request(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submit_request'; -- プログラム名
    cv_program     CONSTANT VARCHAR2(15)  := 'XXWSH400002C'; -- コンカレント：顧客発注からの出荷依頼自動作成
    cb_sub_request CONSTANT BOOLEAN       := FALSE;
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
  -- 入力拠点/管轄拠点取得用
    TYPE submit_request_rec IS RECORD(
      input_sales_branch        xxwsh_shipping_headers_if.input_sales_branch%TYPE
     ,head_sales_branch         xxwsh_shipping_headers_if.head_sales_branch%TYPE
    );
  -- 入力拠点/管轄拠点取得用
    TYPE submit_request_ttype  IS TABLE OF submit_request_rec INDEX BY BINARY_INTEGER;
      submit_request_tab        submit_request_ttype;
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_request_id NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR submit_request_cur
    IS
      SELECT xshi.input_sales_branch input_sales_branch -- 入力拠点
            ,xshi.head_sales_branch  head_sales_branch  -- 管轄拠点
      FROM   xxwsh_shipping_headers_if  xshi            -- 出荷依頼インタフェースヘッダ（アドオン）
      WHERE  xshi.request_id = gn_conc_request_id
      GROUP BY xshi.input_sales_branch
              ,xshi.head_sales_branch
      ;
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
    --カーソルオープン
    OPEN  submit_request_cur;
    FETCH submit_request_cur BULK COLLECT INTO submit_request_tab;
    CLOSE submit_request_cur;
--
    <<submit_request_loop>>
    FOR i IN 1..submit_request_tab.COUNT LOOP
      ln_request_id := fnd_request.submit_request(
                         application  => cv_app_name_xxwsh,
                         program      => cv_program,
                         description  => NULL,
                         start_time   => NULL,
                         sub_request  => cb_sub_request,
                         argument1    => submit_request_tab( i ).input_sales_branch, -- 入力拠点
                         argument2    => submit_request_tab( i ).head_sales_branch   -- 管轄拠点
                       );
      --コンカレント起動のためコミット
      COMMIT;
    END LOOP submit_request_loop;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (submit_request_cur%ISOPEN)THEN
        CLOSE submit_request_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  END submit_request;
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
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain';      -- プログラム名
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
    -- 妥当性チェックステータス 初期化
    gv_check_proc_retcode := cv_status_normal;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 関連データ取得 (O-1)
    -- ===============================
    init_proc(
      in_file_format,    -- フォーマットパターン
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ取得 (O-2)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- ファイルＩＤ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
--#################################  アップロード固定メッセージ START  ###################################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                              cv_c_msg_99o_101,
                                              cv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                              cv_c_msg_99o_103,
                                              cv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(cv_app_name_xxinv,
                                              cv_c_msg_99o_104,
                                              cv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  アップロード固定メッセージ END   ###################################
--
    -- ファイルアップロードインタフェースデータ取得結果を判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    END IF;
--
--
    -- ===============================
    -- 妥当性チェック (O-3)
    -- ===============================
    check_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    -- 妥当性チェックでエラーがなかった場合
    ELSIF (gv_check_proc_retcode = cv_status_normal) THEN
--
      -- ===============================
      -- 登録データセット (O-4)
      -- ===============================
      set_data_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ヘッダ登録 (O-5)
      -- ===============================
      insert_header_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 明細登録 (O-6)
      -- ===============================
      insert_details_proc(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 明細登録でエラーがなかった場合
      IF (lv_retcode = cv_status_normal) THEN
--
        -- ===============================
        -- 顧客発注からの出荷依頼自動作成起動 (O-7)
        -- ===============================
        submit_request(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    -- ===============================
    -- ファイルアップロードインタフェースデータ削除 (O-8)
    -- ===============================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- フォーマットパターン
      gd_sysdate,                     -- 対象日付
      gn_xxinv_parge_term,            -- パージ対象期間
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      -- 削除処理エラー時にRollBackをする為、妥当性チェックステータスを初期化
      gv_check_proc_retcode := cv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- チェック処理エラー
    IF (gv_check_proc_retcode = cv_status_error) THEN
      -- 固定のエラーメッセージの出力をしないようにする
      lv_errmsg := cv_c_space;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id     IN  VARCHAR2,      --   ファイルＩＤ
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    -- メッセージ
    cv_msg_xxcmn_00001 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';
    cv_msg_xxcmn_00002 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';
    cv_msg_xxcmn_10118 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';
    cv_msg_xxcmn_00003 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';
    cv_msg_xxcmn_10030 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';
    cv_msg_xxcmn_00008 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';
    cv_msg_xxcmn_00009 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';
    cv_msg_xxcmn_00010 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';
    cv_msg_xxcmn_00011 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';
    cv_msg_xxcmn_00012 CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';
--
    -- トークン
    cv_user            CONSTANT VARCHAR2(10) := 'USER';
    cv_conc            CONSTANT VARCHAR2(10) := 'CONC';
    cv_cnt             CONSTANT VARCHAR2(10) := 'CNT';
    cv_status          CONSTANT VARCHAR2(10) := 'STATUS';
--
    -- クイックコード
    cv_cp_status_code  CONSTANT VARCHAR2(20) := 'CP_STATUS_CODE';
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
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00001,cv_user,gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00002,cv_conc,gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_10118,
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00003);
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      TO_NUMBER(in_file_id),     -- ファイルＩＤ
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
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_10030);
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
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00008,cv_cnt,TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00009,cv_cnt,TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00010,cv_cnt,TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00011,cv_cnt,TO_CHAR(gn_warn_cnt));
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
    AND    flv.lookup_type         = cv_cp_status_code
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_app_name_xxcmn,cv_msg_xxcmn_00012,cv_status,gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) AND (gv_check_proc_retcode = cv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxinv990011c;
/
