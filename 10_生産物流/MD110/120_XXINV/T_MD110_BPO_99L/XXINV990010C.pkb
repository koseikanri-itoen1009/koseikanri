CREATE OR REPLACE PACKAGE BODY XXINV990010C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXINV990010C(body)
 * Description      : 移動指示のアップロード
 * MD.050           : ファイルアップロード   T_MD050_BPO_990
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   関連データ取得(L-1)
 *  get_upload_data        ファイルアップロードインタフェースデータ取得 (L-2)
 *  validity_check         妥当性チェック(L-3,4,5)
 *  set_data               登録データ設定
 *  insert_header          ヘッダデータ登録(L-6)
 *  insert_lines           明細データ登録(L-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/02/24    1.0   SCS Y.Kanami     新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal  CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn    CONSTANT VARCHAR2(1)  := '1';
  gv_status_error   CONSTANT VARCHAR2(1)  := '2';
--
  gv_sts_cd_normal  CONSTANT VARCHAR2(1)  := 'C';
  gv_sts_cd_warn    CONSTANT VARCHAR2(1)  := 'G';
  gv_sts_cd_error   CONSTANT VARCHAR2(1)  := 'E';
  gv_msg_part       CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont       CONSTANT VARCHAR2(3)  := '.';
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
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
  no_data_if_expt           EXCEPTION;     -- 対象データなし
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100)  := 'XXINV990010C';     -- パッケージ名
--
  gv_c_msg_kbn          CONSTANT VARCHAR2(5)    := 'XXINV';
--
  -- メッセージ番号
  gv_c_msg_ng_profile   CONSTANT VARCHAR2(15)   := 'APP-XXINV-10025';  -- プロファイル取得エラー
  gv_c_msg_ng_rock      CONSTANT VARCHAR2(15)   := 'APP-XXINV-10032';  -- ロックエラー
  gv_c_msg_ng_data      CONSTANT VARCHAR2(15)   := 'APP-XXINV-10008';  -- 対象データなし
  gv_c_msg_ng_format    CONSTANT VARCHAR2(15)   := 'APP-XXINV-10024';  -- フォーマットチェックエラーメッセージ
  gv_c_msg_ng_head_item CONSTANT VARCHAR2(15)   := 'APP-XXINV-10192';  -- 同一ヘッダ項目エラー
--
  gv_c_msg_file_name    CONSTANT VARCHAR2(15)   := 'APP-XXINV-00001';  -- ファイル名
  gv_c_msg_upload_date  CONSTANT VARCHAR2(15)   := 'APP-XXINV-00003';  -- アップロード日時
  gv_c_msg_upload_name  CONSTANT VARCHAR2(15)   := 'APP-XXINV-00004';  -- ファイルアップロード名称
--
  -- トークン
  gv_c_tkn_ng_profile   CONSTANT VARCHAR2(10)   := 'NAME';
  gv_c_tkn_table        CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item         CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value        CONSTANT VARCHAR2(15)   := 'VALUE';
--
  -- プロファイル
  gv_c_purge_term_010   CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_010';
  gv_c_purge_term_name  CONSTANT VARCHAR2(36)   := 'パージ対象期間:移動指示';
--
  -- クイックコード タイプ
  gv_c_lookup_type      CONSTANT VARCHAR2(17)   := 'XXINV_FILE_OBJECT';
  gv_c_format_type      CONSTANT VARCHAR2(20)   := 'フォーマットパターン';
--
  -- 対象DB名
  gv_c_xxinv_mrp_file_ul_name   CONSTANT VARCHAR2(100)
                                                := 'ファイルアップロードインタフェーステーブル';
--
  -- 入力パラメータ
  gv_c_file_id_name             CONSTANT VARCHAR2(24) := 'FILE_ID';
  -- ヘッダ項目名
  gv_c_tmp_ship_number          CONSTANT VARCHAR2(20) := '仮伝票番号';
  gv_c_product_flg              CONSTANT VARCHAR2(20) := '製品識別区分';
  gv_c_instr_post_cd            CONSTANT VARCHAR2(20) := '移動指示部署コード';
  gv_c_mov_type                 CONSTANT VARCHAR2(20) := '移動タイプコード';
  gv_c_shipped_locat_cd         CONSTANT VARCHAR2(20) := '出庫元コード';
  gv_c_ship_to_locat_cd         CONSTANT VARCHAR2(20) := '入庫先コード';
  gv_c_schedule_ship_date       CONSTANT VARCHAR2(20) := '出庫日';
  gv_c_schedule_arrival_date    CONSTANT VARCHAR2(20) := '着日';
  gv_c_freight_charge_cls       CONSTANT VARCHAR2(20) := '運賃区分';
  gv_c_freight_carrier_cd       CONSTANT VARCHAR2(20) := '運送業者コード';
  gv_c_weight_capacity_cls      CONSTANT VARCHAR2(20) := '重量容積区分';
  -- 明細項目名
  gv_c_item_cd                  CONSTANT VARCHAR2(20) := '品目コード';
  gv_c_designated_prod_date     CONSTANT VARCHAR2(20) := '指定製造日';
  gv_c_first_instruct_qty       CONSTANT VARCHAR2(20) := '指示総数';
--
  -- ヘッダ項目桁数
  gn_c_tmp_ship_number_len      CONSTANT NUMBER       := 256; -- 仮伝票番号
  gn_c_product_flg_len          CONSTANT NUMBER       := 1;   -- 製品識別区分
  gn_c_instr_post_cd_len        CONSTANT NUMBER       := 4;   -- 移動指示部署コード
  gn_c_mov_type_len             CONSTANT NUMBER       := 1;   -- 移動タイプコード
  gn_c_shipped_locat_cd_len     CONSTANT NUMBER       := 4;   -- 出庫元コード
  gn_c_ship_to_locat_cd_len     CONSTANT NUMBER       := 4;   -- 入庫先コード
  gn_c_freight_charge_cls_len   CONSTANT NUMBER       := 1;   -- 運賃区分
  gn_c_freight_carrier_cd_len   CONSTANT NUMBER       := 4;   -- 運送業者コード
  gn_c_weight_capacity_cls_len  CONSTANT NUMBER       := 1;   -- 重量容積区分
  -- 明細項目桁数
  gn_c_item_cd_len              CONSTANT VARCHAR2(20) := 7;   -- 品目コード
--
  gv_c_period                   CONSTANT VARCHAR2(1)  := '.';      -- ピリオド
  gv_c_comma                    CONSTANT VARCHAR2(1)  := ',';      -- カンマ
  gv_c_space                    CONSTANT VARCHAR2(1)  := ' ';      -- スペース
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)  := '      '; -- スペース（6byte）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 移動指示ＩＦ情報格納用レコード
  TYPE file_data_rtype IS RECORD(
      temp_ship_no                VARCHAR2(32767) -- 仮伝票番号
    , product_flg                 VARCHAR2(32767) -- 製品識別区分
    , instr_post_cd               VARCHAR2(32767) -- 移動指示部署コード
    , mov_type                    VARCHAR2(32767) -- 移動タイプコード
    , shipped_locat_cd            VARCHAR2(32767) -- 出庫元コード
    , ship_to_locat_cd            VARCHAR2(32767) -- 入庫先コード
    , schedule_ship_date          VARCHAR2(32767) -- 出庫日
    , schedule_arrival_date       VARCHAR2(32767) -- 着日
    , freight_charge_cls          VARCHAR2(32767) -- 運賃区分
    , freight_carrier_cd          VARCHAR2(32767) -- 運送業者コード
    , weight_capacity_cls         VARCHAR2(32767) -- 重量容積区分
    , item_cd                     VARCHAR2(32767) -- 品目コード
    , designated_production_date  VARCHAR2(32767) -- 指定製造日
    , first_instruct_qty          VARCHAR2(32767) -- 指示総数
    , err_message                 VARCHAR2(32767) -- エラーメッセージ(内部制御用)
    , line                        VARCHAR2(32767) -- 行内容(内部制御用)
  );
--
  -- 移動指示ＩＦ情報格納用配列
  TYPE file_data_ttype IS TABLE OF file_data_rtype INDEX BY BINARY_INTEGER;
  g_file_data_tab file_data_ttype; 
--
  -- 登録用PL/SQL表(ヘッダ)
  TYPE mov_hdr_if_id_type         IS TABLE OF
    xxinv_mov_instr_headers_if.mov_hdr_if_id%type INDEX BY BINARY_INTEGER;            -- 移動ヘッダIF_ID
  TYPE tmp_ship_number_type       IS TABLE OF
    xxinv_mov_instr_headers_if.temp_ship_num%type INDEX BY BINARY_INTEGER;            -- 仮伝票番号
  TYPE mov_type_type              IS TABLE OF
    xxinv_mov_instr_headers_if.mov_type%type INDEX BY BINARY_INTEGER;                 -- 移動タイプ
  TYPE instr_post_cd_type         IS TABLE OF
    xxinv_mov_instr_headers_if.instruction_post_code%type INDEX BY BINARY_INTEGER;    -- 指示部署
  TYPE shipped_locat_cd_type      IS TABLE OF
    xxinv_mov_instr_headers_if.shipped_locat_code%type INDEX BY BINARY_INTEGER;       -- 出庫元保管場所
  TYPE ship_to_locat_cd_type      IS TABLE OF
    xxinv_mov_instr_headers_if.ship_to_locat_code%type INDEX BY BINARY_INTEGER;       -- 入庫先保管場所
  TYPE schedule_ship_date_type    IS TABLE OF
    xxinv_mov_instr_headers_if.schedule_ship_date%type INDEX BY BINARY_INTEGER;       -- 出庫予定日
  TYPE schedule_arrival_date_type IS TABLE OF
    xxinv_mov_instr_headers_if.schedule_arrival_date%type INDEX BY BINARY_INTEGER;    -- 入庫予定日
  TYPE freight_charge_cls_type    IS TABLE OF
    xxinv_mov_instr_headers_if.freight_charge_class%type INDEX BY BINARY_INTEGER;     -- 運賃区分
  TYPE freight_carrier_cd_type    IS TABLE OF
    xxinv_mov_instr_headers_if.freight_carrier_code%type INDEX BY BINARY_INTEGER;     -- 運送業者
  TYPE weight_capacity_cls_type   IS TABLE OF
    xxinv_mov_instr_headers_if.weight_capacity_class%type INDEX BY BINARY_INTEGER;    -- 重量容積区分
  TYPE product_flg_type           IS TABLE OF
    xxinv_mov_instr_headers_if.product_flg%type INDEX BY BINARY_INTEGER;              -- 製品識別区分
--
  g_mov_hdr_if_id_tab         mov_hdr_if_id_type;         -- 移動ヘッダIF_ID
  g_tmp_ship_number_tab       tmp_ship_number_type;       -- 仮伝票番号
  g_mov_type_tab              mov_type_type;              -- 移動タイプ
  g_instr_post_cd_tab         instr_post_cd_type;         -- 指示部署
  g_shipped_locat_cd_tab      shipped_locat_cd_type;      -- 出庫元保管場所
  g_ship_to_locat_cd_tab      ship_to_locat_cd_type;      -- 入庫先保管場所
  g_schedule_ship_date_tab    schedule_ship_date_type;    -- 出庫予定日
  g_schedule_arrival_date_tab schedule_arrival_date_type; -- 入庫予定日
  g_freight_charge_cls_tab    freight_charge_cls_type;    -- 運賃区分
  g_freight_carrier_cd_tab    freight_carrier_cd_type;    -- 運送業者
  g_weight_capacity_cls_tab   weight_capacity_cls_type;   -- 重量容積区分
  g_product_flg_tab           product_flg_type;           -- 製品識別区分
--
  -- 登録用PL/SQL表(明細)
  TYPE mov_line_if_id_type        IS TABLE OF
    xxinv_mov_instr_lines_if.mov_line_if_id%type INDEX BY BINARY_INTEGER;             -- 移動明細IF_ID
  TYPE mov_line_hdr_if_id_type         IS TABLE OF
    xxinv_mov_instr_lines_if.mov_hdr_if_id%type INDEX BY BINARY_INTEGER;              -- 移動ヘッダIF_ID
  TYPE item_cd_type               IS TABLE OF
    xxinv_mov_instr_lines_if.item_code%type INDEX BY BINARY_INTEGER;                  -- 品目
  TYPE designated_prod_date_type  IS TABLE OF
    xxinv_mov_instr_lines_if.designated_production_date%type INDEX BY BINARY_INTEGER; -- 指定製造日
  TYPE first_instruct_qty_type    IS TABLE OF
    xxinv_mov_instr_lines_if.first_instruct_qty%type INDEX BY BINARY_INTEGER;         -- 初回指示数量
--
  g_mov_line_if_id_tab        mov_line_if_id_type;        -- 移動明細IF_ID
  g_mov_line_hdr_if_id_tab    mov_line_hdr_if_id_type;    -- 移動ヘッダIF_ID
  g_item_cd_tab               item_cd_type;               -- 品目
  g_designated_prod_date_tab  designated_prod_date_type;  -- 指定製造日
  g_first_instruct_qty_tab    first_instruct_qty_type;    -- 初回指示数量
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
  gn_prog_appl_id           NUMBER;           -- コンカレントのアプリケーションID
  gn_conc_program_id        NUMBER;           -- コンカレント・プログラムID
--
  gn_xxinv_purge_term       NUMBER;           -- パージ対象期間
  gv_file_name              VARCHAR2(256);    -- ファイル名
  gv_file_up_name           VARCHAR2(256);    -- ファイルアップロード名称
  gn_created_by             NUMBER(15);       -- 作成者
  gd_creation_date          DATE;             -- 作成日
  gv_check_proc_retcode     VARCHAR2(1);      -- 妥当性チェックステータス
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 関連データ取得(L-1)
   ***********************************************************************************/
  PROCEDURE init(
      in_file_format  IN  VARCHAR2     -- フォーマットパターン  
    , ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_purge_term       VARCHAR2(100);    -- プロファイル格納場所
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --------------------
    -- システム日付取得
    --------------------
    gd_sysdate := SYSDATE;
--
    ---------------------
    -- WHOカラム情報取得
    ---------------------
    gn_user_id          := FND_GLOBAL.USER_ID;          -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;         -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- コンカレント・アプリケーションID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- コンカレント・プログラムID
--
    --------------------------------------
    -- プロファイル「パージ対象期間」取得
    --------------------------------------
    lv_purge_term := FND_PROFILE.VALUE(gv_c_purge_term_010);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_purge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gv_c_msg_kbn
                                            , gv_c_msg_ng_profile
                                            , gv_c_tkn_ng_profile
                                            , gv_c_purge_term_name
                                            );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --------------------------
    -- プロファイル値チェック
    --------------------------
    BEGIN
      -- 数値変換できなければエラー
      gn_xxinv_purge_term := TO_NUMBER(lv_purge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg ( gv_c_msg_kbn
                                              , gv_c_msg_ng_profile
                                              , gv_c_tkn_ng_profile
                                              , gv_c_purge_term_name
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --------------------------------
    -- ファイルアップロード名称取得
    --------------------------------
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv
      WHERE   xlvv.lookup_type = gv_c_lookup_type
      AND     xlvv.lookup_code = in_file_format
      AND     xlvv.start_date_active <= gd_sysdate
      AND     ((xlvv.end_date_active IS NULL)
              OR  (xlvv.end_date_active >= gd_sysdate))
      AND     ROWNUM           = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_ng_data,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードインタフェースデータ取得(L-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
      in_file_id      IN  VARCHAR2     -- ファイルID
    , ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    ln_target_cnt NUMBER;             -- 一時表格納用
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- 行テーブル格納領域
--
    -- 一時表格納用
    TYPE l_line_type                  IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
    TYPE l_record_id_type             IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE l_tmp_ship_number_type       IS TABLE OF VARCHAR2(512) INDEX BY BINARY_INTEGER;
    TYPE l_mov_type_type              IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_instr_post_cd_type         IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_shipped_locat_cd_type      IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_ship_to_locat_cd_type      IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_schedule_ship_date_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_schedule_arrival_date_type IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_freight_charge_cls_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_freight_carrier_cd_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_weight_capacity_cls_type   IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_product_flg_type           IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_mov_line_if_id_type        IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_mov_line_hdr_if_id_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_item_cd_type               IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_designated_prod_date_type  IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
    TYPE l_first_instruct_qty_type    IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;
--
    l_tmp_ship_number_tab             l_tmp_ship_number_type;       -- 仮伝票番号
    l_mov_type_tab                    l_mov_type_type;              -- 移動タイプ
    l_instr_post_cd_tab               l_instr_post_cd_type;         -- 指示部署
    l_shipped_locat_cd_tab            l_shipped_locat_cd_type;      -- 出庫元保管場所
    l_ship_to_locat_cd_tab            l_ship_to_locat_cd_type;      -- 入庫先保管場所
    l_schedule_ship_date_tab          l_schedule_ship_date_type;    -- 出庫予定日
    l_schedule_arrival_date_tab       l_schedule_arrival_date_type; -- 入庫予定日
    l_freight_charge_cls_tab          l_freight_charge_cls_type;    -- 運賃区分
    l_freight_carrier_cd_tab          l_freight_carrier_cd_type;    -- 運送業者
    l_weight_capacity_cls_tab         l_weight_capacity_cls_type;   -- 重量容積区分
    l_product_flg_tab                 l_product_flg_type;           -- 製品識別区分
    l_mov_line_if_id_tab              l_mov_line_if_id_type;        -- 移動明細IF_ID
    l_mov_line_hdr_if_id_tab          l_mov_line_hdr_if_id_type;    -- 移動ヘッダIF_ID
    l_item_cd_tab                     l_item_cd_type;               -- 品目
    l_designated_prod_date_tab        l_designated_prod_date_type;  -- 指定製造日
    l_first_instruct_qty_tab          l_first_instruct_qty_type;    -- 初回指示数量
    l_line_tab                        l_line_type;                  -- 行内容
    l_record_id_tab                   l_record_id_type;             -- レコードID
--
    -- *** ローカル・カーソル ***
    -- 移動指示インタフェース一時表取得
    CURSOR xxinv_tmp_mov_instr_if_cur IS
      SELECT  REPLACE(xtmif.temp_ship_num, 'NULL', '')                temp_ship_num               -- 仮伝票番号
            , REPLACE(xtmif.product_flg, 'NULL', '')                  product_flg                 -- 製品識別区分
            , REPLACE(xtmif.instruction_post_code, 'NULL', '')        instruction_post_code       -- 移動指示部署コード
            , REPLACE(xtmif.mov_type, 'NULL', '')                     mov_type                    -- 移動タイプコード
            , REPLACE(xtmif.shipped_locat_code, 'NULL', '')           shipped_locat_code          -- 出庫元コード
            , REPLACE(xtmif.ship_to_locat_code, 'NULL', '')           ship_to_locat_code          -- 入庫先コード
            , REPLACE(xtmif.schedule_ship_date, 'NULL', '')           schedule_ship_date          -- 出庫日
            , REPLACE(xtmif.schedule_arrival_date, 'NULL', '')        schedule_arrival_date       -- 着日
            , REPLACE(xtmif.freight_charge_class, 'NULL', '')         freight_charge_class        -- 運賃区分
            , REPLACE(xtmif.freight_carrier_code, 'NULL', '')         freight_carrier_code        -- 運送業者コード
            , REPLACE(xtmif.weight_capacity_class, 'NULL', '')        weight_capacity_class       -- 重量容積区分
            , REPLACE(xtmif.item_code, 'NULL', '')                    item_code                   -- 品目コード
            , REPLACE(xtmif.designated_production_date, 'NULL', '')   designated_production_date  -- 指定製造日
            , REPLACE(xtmif.first_instruct_qty, 'NULL', '')           first_instruct_qty          -- 指示総数
            , xtmif.line                                              line                        -- 行内容
      FROM  xxinv_tmp_mov_instr_if xtmif
      WHERE xtmif.file_id = in_file_id
      ORDER BY xtmif.temp_ship_num
             , xtmif.item_code
      ;             
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
    -- 変数初期化
    ln_target_cnt := 0;
--
    ------------------------------------
    -- ファイルアップロードIFデータ取得
    ------------------------------------
    -- 行ロック処理
    SELECT  xmf.file_name     -- ファイル名
          , xmf.created_by    -- 作成者
          , xmf.creation_date -- 作成日
    INTO    gv_file_name
          , gn_created_by
          , gd_creation_date
    FROM  xxinv_mrp_file_ul_interface xmf
    WHERE xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT
    ;
--
    -- データ取得
    xxcmn_common3_pkg.blob_to_varchar2(
        in_file_id          -- ファイルID
      , lt_file_line_data   -- VARCHAR2変換後データ
      , lv_errbuf           -- エラー・メッセージ         (固定)
      , lv_retcode          -- リターン・コード           (固定)
      , lv_errmsg           -- ユーザ・エラー・メッセージ (固定)
      );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- タイトル行のみ、または2行目が改行のみの場合
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                            , gv_c_msg_ng_data
                                            , gv_c_tkn_item
                                            , gv_c_file_id_name
                                            , gv_c_tkn_value
                                            , in_file_id
                                            );
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    ---------------------------------------------------
    -- PL/SQL表格納処理(2行目以降)
    ---------------------------------------------------
    <<line_loop>>
    FOR ln_index IN 2..lt_file_line_data.LAST LOOP
--
      -- 対象件数カウント
      ln_target_cnt := ln_target_cnt + 1;
--
      -- 行毎に作業領域に格納
      lv_line := lt_file_line_data(ln_index);
--
      -- 行内容をlineに格納
      l_line_tab(ln_target_cnt)       := lv_line;
--
      -- レコードID格納
      l_record_id_tab(ln_target_cnt)  := ln_target_cnt;
--
      -- カラム番号初期化
      ln_col  := 0;     -- カラム
      lb_col  := TRUE;  -- カラム作成継続
--
      -------------------------------------
      -- カンマ毎に分解する
      -------------------------------------
      <<comma_loop>>
      LOOP
--
        -- 最後の項目が空の場合終了しない
        IF (ln_col = 13) AND (lv_line IS NULL) THEN
          NULL;
        ELSE
          -- lv_lineの長さが0なら終了
          EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
        END IF;
--
        -- カラム番号をカウント
        ln_col := ln_col + 1;
--
        -- カンマの位置を取得
        ln_length := INSTR(lv_line, gv_c_comma);
--
        -- カンマがない
        IF (ln_length = 0) THEN
          IF (ln_col <= 13) THEN
            lb_col    := TRUE;
          ELSE
            ln_length := LENGTH(lv_line);
            lb_col    := FALSE;
          END IF;
        -- カンマがある
        ELSE
          ln_length := ln_length - 1;
          lb_col    := TRUE;
        END IF;
--
        -- PL/SQL表の各項目及び一時表用配列に格納
        IF (ln_col = 1) THEN
          -- 仮伝票番号
          l_tmp_ship_number_tab(ln_target_cnt)        := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 2) THEN
          -- 製品識別区分
          l_product_flg_tab(ln_target_cnt)            := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 3) THEN
          -- 移動指示部署コード
          l_instr_post_cd_tab(ln_target_cnt)          := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 4) THEN
          -- 移動タイプコード
          l_mov_type_tab(ln_target_cnt)               := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 5) THEN
          -- 出庫元コード
          l_shipped_locat_cd_tab(ln_target_cnt)       := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 6) THEN
          -- 入庫先コード
          l_ship_to_locat_cd_tab(ln_target_cnt)       := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 7) THEN
          -- 出庫日
          l_schedule_ship_date_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 8) THEN
          -- 着日
          l_schedule_arrival_date_tab(ln_target_cnt)  := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 9) THEN
          -- 運賃区分
          l_freight_charge_cls_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 10) THEN
          -- 運送業者コード
          l_freight_carrier_cd_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 11) THEN
          -- 重量容積区分
          l_weight_capacity_cls_tab(ln_target_cnt)    := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 12) THEN
          -- 品目コード
          l_item_cd_tab(ln_target_cnt)                := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 13) THEN
          -- 指定製造日
          l_designated_prod_date_tab(ln_target_cnt)   := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
        ELSIF (ln_col = 14) THEN
          -- 指示総数
          l_first_instruct_qty_tab(ln_target_cnt)     := NVL(SUBSTR(lv_line, 1, ln_length),'NULL');
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
--
    END LOOP line_loop;
--
    --------------------------------------
    -- 移動指示インタフェース一時表に格納
    --------------------------------------
    FORALL rec_cnt IN 1..ln_target_cnt
    INSERT INTO xxinv.xxinv_tmp_mov_instr_if(
        file_id                   
      , record_id                 
      , temp_ship_num             
      , product_flg               
      , instruction_post_code     
      , mov_type                  
      , shipped_locat_code        
      , ship_to_locat_code        
      , schedule_ship_date        
      , schedule_arrival_date     
      , freight_charge_class      
      , freight_carrier_code      
      , weight_capacity_class     
      , item_code                 
      , designated_production_date
      , first_instruct_qty        
      , line
    ) VALUES (
        in_file_id                            -- ファイルID
      , l_record_id_tab(rec_cnt)              -- レコードID
      , l_tmp_ship_number_tab(rec_cnt)        -- 仮伝票番号
      , l_product_flg_tab(rec_cnt)            -- 製品識別区分
      , l_instr_post_cd_tab(rec_cnt)          -- 指示部署
      , l_mov_type_tab(rec_cnt)               -- 移動タイプ
      , l_shipped_locat_cd_tab(rec_cnt)       -- 出庫元保管場所
      , l_ship_to_locat_cd_tab(rec_cnt)       -- 入庫先保管場所
      , l_schedule_ship_date_tab(rec_cnt)     -- 出庫予定日
      , l_schedule_arrival_date_tab(rec_cnt)  -- 入庫予定日
      , l_freight_charge_cls_tab(rec_cnt)     -- 運賃区分
      , l_freight_carrier_cd_tab(rec_cnt)     -- 運送業者
      , l_weight_capacity_cls_tab(rec_cnt)    -- 重量容積区分
      , l_item_cd_tab(rec_cnt)                -- 品目
      , l_designated_prod_date_tab(rec_cnt)   -- 指定製造日
      , l_first_instruct_qty_tab(rec_cnt)     -- 初回指示数量
      , l_line_tab(rec_cnt)                   -- 行内容
    );
--
    --------------------------------------
    -- PL/SQL表に格納
    --------------------------------------
    <<set_data_loop>>
    FOR cur_rec IN xxinv_tmp_mov_instr_if_cur LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 仮伝票番号
      g_file_data_tab(gn_target_cnt).temp_ship_no               := cur_rec.temp_ship_num;
      -- 製品識別区分
      g_file_data_tab(gn_target_cnt).product_flg                := cur_rec.product_flg;
      -- 移動指示部署コード
      g_file_data_tab(gn_target_cnt).instr_post_cd              := cur_rec.instruction_post_code;
      -- 移動タイプコード
      g_file_data_tab(gn_target_cnt).mov_type                   := cur_rec.mov_type;
      -- 出庫元コード
      g_file_data_tab(gn_target_cnt).shipped_locat_cd           := cur_rec.shipped_locat_code;
      -- 入庫先コード
      g_file_data_tab(gn_target_cnt).ship_to_locat_cd           := cur_rec.ship_to_locat_code;
      -- 出庫日
      g_file_data_tab(gn_target_cnt).schedule_ship_date         := cur_rec.schedule_ship_date;
      -- 着日
      g_file_data_tab(gn_target_cnt).schedule_arrival_date      := cur_rec.schedule_arrival_date;
      -- 運賃区分
      g_file_data_tab(gn_target_cnt).freight_charge_cls         := cur_rec.freight_charge_class;
      -- 運送業者コード
      g_file_data_tab(gn_target_cnt).freight_carrier_cd         := cur_rec.freight_carrier_code;
      -- 重量容積区分
      g_file_data_tab(gn_target_cnt).weight_capacity_cls        := cur_rec.weight_capacity_class;
      -- 品目コード
      g_file_data_tab(gn_target_cnt).item_cd                    := cur_rec.item_code;
      -- 指定製造日
      g_file_data_tab(gn_target_cnt).designated_production_date := cur_rec.designated_production_date;
      -- 指示総数
      g_file_data_tab(gn_target_cnt).first_instruct_qty       := cur_rec.first_instruct_qty;
      -- 行内容
      g_file_data_tab(gn_target_cnt).line                       := cur_rec.line;
--
    END LOOP set_data_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                            , gv_c_msg_ng_rock
                                            , gv_c_tkn_table
                                            , gv_c_xxinv_mrp_file_ul_name
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
      lv_errmsg := xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                            , gv_c_msg_ng_data
                                            , gv_c_tkn_item
                                            , gv_c_file_id_name
                                            , gv_c_tkn_value
                                            , in_file_id
                                            );
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : validity_check
   * Description      : 妥当性チェック(L-3,4,5)
   ***********************************************************************************/
  PROCEDURE validity_check(
      ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validity_check'; -- プログラム名
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
    cn_c_col          CONSTANT NUMBER       := 14;  -- 総項目数
    cv_continues      CONSTANT VARCHAR2(1)  := '0'; -- チェック継続
    cv_skip           CONSTANT VARCHAR2(1)  := '1'; -- チェックスキップ
    cn_first          CONSTANT NUMBER       := 1;   -- 項目の最初
--
    -- *** ローカル変数 ***
    lv_line_feed                  VARCHAR2(1);      -- 改行コード
    lv_log_data                   VARCHAR2(32767);  -- LOGデータ部退避用
    ln_item_cnt                   NUMBER;           -- 同一ヘッダチェック用
    -- 同一ヘッダチェック用変数
    lv_pre_temp_ship_no           VARCHAR2(32767);  -- 仮伝票番号
    lv_pre_product_flg            VARCHAR2(32767);  -- 製品識別区分
    lv_pre_instr_post_cd          VARCHAR2(32767);  -- 移動指示部署コード
    lv_pre_mov_type               VARCHAR2(32767);  -- 移動タイプコード
    lv_pre_shipped_locat_cd       VARCHAR2(32767);  -- 出庫元コード
    lv_pre_ship_to_locat_cd       VARCHAR2(32767);  -- 入庫先コード
    lv_pre_schedule_ship_date     VARCHAR2(32767);  -- 出庫日
    lv_pre_schedule_arrival_date  VARCHAR2(32767);  -- 着日
    lv_pre_freight_charge_cls     VARCHAR2(32767);  -- 運賃区分
    lv_pre_freight_carrier_cd     VARCHAR2(32767);  -- 運送業者コード
    lv_pre_weight_capacity_cls    VARCHAR2(32767);  -- 重量容積区分
--
    lv_continues_flag             VARCHAR2(1);
    lv_header_item                VARCHAR2(32767);  -- ヘッダー項目
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
    -- 初期化
    gv_check_proc_retcode := gv_status_normal;  -- 妥当性チェックステータス
    lv_line_feed          := CHR(10);           -- 改行コード
    -- 同一ヘッダチェック用
    ln_item_cnt                   := 0;
    lv_pre_temp_ship_no           := NULL;
    lv_pre_product_flg            := NULL;
    lv_pre_instr_post_cd          := NULL;
    lv_pre_mov_type               := NULL;
    lv_pre_shipped_locat_cd       := NULL;
    lv_pre_ship_to_locat_cd       := NULL;
    lv_pre_schedule_ship_date     := NULL;
    lv_pre_schedule_arrival_date  := NULL;
    lv_pre_freight_charge_cls     := NULL;
    lv_pre_freight_carrier_cd     := NULL;
    lv_pre_weight_capacity_cls    := NULL;
    -- 処理継続フラグ
    lv_continues_flag             := cv_continues;  -- 継続
--
    -- ========================================
    --  取得したレコード毎に項目チェックを行う
    -- ========================================
    <<check_loop>>
    FOR ln_index IN 1..g_file_data_tab.LAST LOOP
--
      -- ==================
      --  項目数チェック
      -- ==================
      -- (行全体の長さ－行からカンマを抜いた長さ＝カンマの数) <> (正式な項目数－１＝正式なカンマの数)
      IF ((NVL(LENGTH(g_file_data_tab(ln_index).line), 0) 
          - NVL(LENGTH(REPLACE(g_file_data_tab(ln_index).line, gv_c_comma, NULL)), 0))
          <> (cn_c_col - 1))
      THEN
--
        g_file_data_tab(ln_index).err_message :=    gv_c_err_msg_space
                                                ||  gv_c_err_msg_space
                                                ||  xxcmn_common_pkg.get_msg( gv_c_msg_kbn
                                                                            , gv_c_msg_ng_format
                                                                            )
                                                ||  lv_line_feed;
      ELSE
--
        -- ====================
        --  同一ヘッダチェック
        -- ====================
        -- 仮伝票番号が同一
        IF  (lv_pre_temp_ship_no = g_file_data_tab(ln_index).temp_ship_no) THEN
--
          IF    (lv_pre_product_flg           = g_file_data_tab(ln_index).product_flg)
            AND (lv_pre_instr_post_cd         = g_file_data_tab(ln_index).instr_post_cd)
            AND (lv_pre_mov_type              = g_file_data_tab(ln_index).mov_type)
            AND (lv_pre_shipped_locat_cd      = g_file_data_tab(ln_index).shipped_locat_cd)
            AND (lv_pre_ship_to_locat_cd      = g_file_data_tab(ln_index).ship_to_locat_cd)
            AND (lv_pre_schedule_ship_date    = g_file_data_tab(ln_index).schedule_ship_date)
            AND (lv_pre_schedule_arrival_date = g_file_data_tab(ln_index).schedule_arrival_date)
            AND (lv_pre_freight_charge_cls    = g_file_data_tab(ln_index).freight_charge_cls)
            AND (
                  (lv_pre_freight_carrier_cd IS NULL AND g_file_data_tab(ln_index).freight_carrier_cd IS NULL)
                OR 
                  (lv_pre_freight_carrier_cd = g_file_data_tab(ln_index).freight_carrier_cd)
                )
            AND (lv_pre_weight_capacity_cls   = g_file_data_tab(ln_index).weight_capacity_cls)
          THEN
--
            -- ヘッダ情報の全ての項目が同一の場合
            -- チェック処理継続
            lv_continues_flag := cv_continues;
--
          ELSE
--
            -- ヘッダ情報の項目が一つでも異なる場合
            -- チェック処理SKIP
            lv_continues_flag := cv_skip;
--
            -- 出力用変数を初期化
            lv_header_item  := NULL;
            ln_item_cnt     := 0;
--
            -- 製品識別区分が異なる場合
            IF (lv_pre_product_flg <> g_file_data_tab(ln_index).product_flg) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              lv_header_item := gv_c_product_flg;
--
            END IF;
--
            -- 移動指示部署コードが異なる場合
            IF (lv_pre_instr_post_cd <> g_file_data_tab(ln_index).instr_post_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_instr_post_cd;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_instr_post_cd;
--
              END IF;
--
            END IF;
--
            -- 移動タイプコードが異なる場合
            IF (lv_pre_mov_type <> g_file_data_tab(ln_index).mov_type) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_mov_type;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma ||gv_c_mov_type;
--
              END IF;
--
            END IF;
--
            -- 出庫元コードが異なる場合
            IF (lv_pre_shipped_locat_cd <> g_file_data_tab(ln_index).shipped_locat_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_shipped_locat_cd;
--
              ELSE  
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_shipped_locat_cd;
--
              END IF;
--
            END IF;
--
            -- 入庫先コードが異なる場合
            IF (lv_pre_ship_to_locat_cd <> g_file_data_tab(ln_index).ship_to_locat_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_ship_to_locat_cd;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma ||gv_c_ship_to_locat_cd;
--
              END IF;
--
            END IF;
--
            -- 出庫日が異なる場合
            IF (lv_pre_schedule_ship_date <> g_file_data_tab(ln_index).schedule_ship_date) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_schedule_ship_date;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_schedule_ship_date;
--
              END IF;
--
            END IF;
--
            -- 着日が異なる場合
            IF (lv_pre_schedule_arrival_date <> g_file_data_tab(ln_index).schedule_arrival_date) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_schedule_arrival_date;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_schedule_arrival_date;
--
              END IF;
--
            END IF;
--
            -- 運賃区分が異なる場合
            IF (lv_pre_freight_charge_cls <> g_file_data_tab(ln_index).freight_charge_cls) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_freight_charge_cls;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_freight_charge_cls;
--
              END IF;
--
            END IF;
--
            -- 運送業者コードが異なる場合
            IF (lv_pre_freight_carrier_cd <> g_file_data_tab(ln_index).freight_carrier_cd) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_freight_carrier_cd;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_freight_carrier_cd;
--
              END IF;
--
            END IF;
--
            -- 重量容積区分が異なる場合
            IF (lv_pre_weight_capacity_cls <> g_file_data_tab(ln_index).weight_capacity_cls) THEN
--
              ln_item_cnt := ln_item_cnt + 1;
--
              IF (ln_item_cnt = cn_first) THEN
--
                lv_header_item := gv_c_weight_capacity_cls;
--
              ELSE
--
                lv_header_item := lv_header_item || gv_c_comma || gv_c_weight_capacity_cls;
--
              END IF;
--
            END IF;
--
            -- エラー出力
            g_file_data_tab(ln_index).err_message :=    gv_c_err_msg_space
                                                    ||  gv_c_err_msg_space
                                                    ||  xxcmn_common_pkg.get_msg(  gv_c_msg_kbn
                                                            , gv_c_msg_ng_head_item
                                                            , gv_c_tkn_item
                                                            , lv_header_item
                                                        )
                                                    ||  lv_line_feed
                                                   ;
--
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
--
          END IF;
--
        -- 仮伝票番号が異なる、もしくは最初のレコード
        ELSIF ((lv_pre_temp_ship_no IS NULL) 
            OR (lv_pre_temp_ship_no <> g_file_data_tab(ln_index).temp_ship_no))
        THEN
--
          -- チェック継続
          lv_continues_flag := cv_continues;
--
        END IF;
--
        -- 同一ヘッダチェックでチェック継続になった場合
        -- チェック処理継続
        IF (lv_continues_flag = cv_continues) THEN
--
          --------------
          -- 仮伝票番号
          --------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_tmp_ship_number                    -- 仮伝票番号
                                              , g_file_data_tab(ln_index).temp_ship_no  -- CSVデータ
                                              , gn_c_tmp_ship_number_len                -- 項目の長さ
                                              , NULL                                    -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng            -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2           -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- 製品識別区分
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_product_flg                        -- 製品識別区分
                                              , g_file_data_tab(ln_index).product_flg   -- CSVデータ
                                              , gn_c_product_flg_len                    -- 項目の長さ
                                              , NULL                                    -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng            -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2           -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------------
          -- 移動指示部署コード
          ----------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_instr_post_cd                        -- 移動指示部署コード
                                              , g_file_data_tab(ln_index).instr_post_cd   -- CSVデータ
                                              , gn_c_instr_post_cd_len                    -- 項目の長さ
                                              , NULL                                      -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng              -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2             -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          --------------------
          -- 移動タイプコード
          --------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_mov_type                       -- 移動タイプコード
                                              , g_file_data_tab(ln_index).mov_type  -- CSVデータ
                                              , gn_c_mov_type_len                   -- 項目の長さ
                                              , NULL                                -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng        -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2       -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- 出庫元コード
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_shipped_locat_cd                       -- 出庫元コード
                                              , g_file_data_tab(ln_index).shipped_locat_cd  -- CSVデータ
                                              , gn_c_shipped_locat_cd_len                   -- 項目の長さ
                                              , NULL                                        -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2               -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- 入庫先コード
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_ship_to_locat_cd                       -- 入庫先コード
                                              , g_file_data_tab(ln_index).ship_to_locat_cd  -- CSVデータ
                                              , gn_c_ship_to_locat_cd_len                   -- 項目の長さ
                                              , NULL                                        -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2               -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ---------------
          -- 出庫日
          ---------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_schedule_ship_date                       -- 出庫日
                                              , g_file_data_tab(ln_index).schedule_ship_date  -- CSVデータ
                                              , NULL                                          -- 項目の長さ
                                              , NULL                                          -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                  -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_dat                 -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ---------------
          -- 着日
          ---------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_schedule_arrival_date                      -- 着日
                                              , g_file_data_tab(ln_index).schedule_arrival_date -- CSVデータ
                                              , NULL                                            -- 項目の長さ
                                              , NULL                                            -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                    -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_dat                   -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ---------------
          -- 運賃区分
          ---------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_freight_charge_cls                       -- 運賃区分
                                              , g_file_data_tab(ln_index).freight_charge_cls  -- CSVデータ
                                              , gn_c_freight_charge_cls_len                   -- 項目の長さ
                                              , NULL                                          -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                  -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2                 -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -------------------
          -- 運送業者コード
          -------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_freight_carrier_cd                       -- 運送業者コード
                                              , g_file_data_tab(ln_index).freight_carrier_cd  -- CSVデータ
                                              , gn_c_freight_carrier_cd_len                   -- 項目の長さ
                                              , NULL                                          -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ok                  -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2                 -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -----------------
          -- 重量容積区分
          -----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_weight_capacity_cls                      -- 重量容積区分
                                              , g_file_data_tab(ln_index).weight_capacity_cls -- CSVデータ
                                              , gn_c_weight_capacity_cls_len                  -- 項目の長さ
                                              , NULL                                          -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                  -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2                 -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          ----------------
          -- 品目コード
          ----------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_item_cd                      -- 品目コード
                                              , g_file_data_tab(ln_index).item_cd -- CSVデータ
                                              , gn_c_item_cd_len                  -- 項目の長さ
                                              , NULL                              -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng      -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_vc2     -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -------------------
          -- 指定製造日
          -------------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_designated_prod_date                             -- 指定製造日
                                              , g_file_data_tab(ln_index).designated_production_date  -- CSVデータ
                                              , NULL                                                  -- 項目の長さ
                                              , NULL                                                  -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                          -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_dat                         -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          --------------
          -- 指示総数
          --------------
          xxcmn_common3_pkg.upload_item_check(  gv_c_first_instruct_qty                               -- 指示総数
                                              , g_file_data_tab(ln_index).first_instruct_qty          -- CSVデータ
                                              , NULL                                                  -- 項目の長さ
                                              , NULL                                                  -- 項目の長さ(小数点)
                                              , xxcmn_common3_pkg.gv_null_ng                          -- 必須(ng:必須、ok:任意)
                                              , xxcmn_common3_pkg.gv_attr_num                         -- 属性
                                              , lv_errbuf
                                              , lv_retcode
                                              , lv_errmsg
                                              );
          -- 項目チェックエラー
          IF (lv_retcode = gv_status_warn) THEN
            g_file_data_tab(ln_index).err_message :=  g_file_data_tab(ln_index).err_message
                                                   || lv_errmsg
                                                   || lv_line_feed;
          -- プロシージャー異常終了
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** エラー制御
      -- **************************************************
      -- チェックエラーありの場合
      IF (g_file_data_tab(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** データ部出力準備（行数 + SPACE + 行全体のデータ）
        -- **************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_c_space || g_file_data_tab(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- エラーメッセージ部出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(g_file_data_tab(ln_index).err_message, lv_line_feed));
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
      -- 同一ヘッダチェック用にデータを格納
      lv_pre_temp_ship_no           := g_file_data_tab(ln_index).temp_ship_no;
      lv_pre_product_flg            := g_file_data_tab(ln_index).product_flg;
      lv_pre_instr_post_cd          := g_file_data_tab(ln_index).instr_post_cd;
      lv_pre_mov_type               := g_file_data_tab(ln_index).mov_type;
      lv_pre_shipped_locat_cd       := g_file_data_tab(ln_index).shipped_locat_cd;
      lv_pre_ship_to_locat_cd       := g_file_data_tab(ln_index).ship_to_locat_cd;
      lv_pre_schedule_ship_date     := g_file_data_tab(ln_index).schedule_ship_date;
      lv_pre_schedule_arrival_date  := g_file_data_tab(ln_index).schedule_arrival_date;
      lv_pre_freight_charge_cls     := g_file_data_tab(ln_index).freight_charge_cls;
      lv_pre_freight_carrier_cd     := g_file_data_tab(ln_index).freight_carrier_cd;
      lv_pre_weight_capacity_cls    := g_file_data_tab(ln_index).weight_capacity_cls;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END validity_check;
--
  /**********************************************************************************
   * Procedure Name   : set_data
   * Description      : 登録データ設定
   ***********************************************************************************/
  PROCEDURE set_data(
      ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data'; -- プログラム名
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
    ln_header_id        NUMBER;           -- ヘッダID
    ln_line_id          NUMBER;           -- 明細ID
    lv_pre_temp_ship_no VARCHAR2(32767);  -- 仮伝票番号
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --------------------
    -- 件数初期化
    --------------------
    gn_header_count :=  0;
    gn_line_count   :=  0;
--
    -----------------------
    -- ローカル変数初期化
    -----------------------
    ln_header_id        :=  0;
    ln_line_id          :=  0;
    lv_pre_temp_ship_no :=  NULL;
--
    ------------------------
    -- 登録用PL/SQL表編集
    ------------------------
    <<data_loop>>
    FOR ln_index IN 1..g_file_data_tab.LAST LOOP
--
      --------------------
      -- ヘッダ項目設定
      --------------------
      -- 最初のレコード及び仮伝票番号がブレイクした場合、ヘッダ項目を登録する
      IF ((lv_pre_temp_ship_no IS NULL) 
          OR (lv_pre_temp_ship_no <> g_file_data_tab(ln_index).temp_ship_no)) 
      THEN
--
        -- ヘッダ件数インクリメント
        gn_header_count := gn_header_count + 1;
--
        -- ヘッダ採番
        SELECT  xxinv_mov_instr_hdr_if_s1.NEXTVAL
        INTO    ln_header_id
        FROM    dual
        ;
--
        -- ヘッダ情報設定
        g_mov_hdr_if_id_tab(gn_header_count)         := ln_header_id;                                     -- 移動ヘッダIF_ID
        g_tmp_ship_number_tab(gn_header_count)       := g_file_data_tab(ln_index).temp_ship_no;           -- 仮伝票番号
        g_mov_type_tab(gn_header_count)              := g_file_data_tab(ln_index).mov_type;               -- 移動タイプ
        g_instr_post_cd_tab(gn_header_count)         := g_file_data_tab(ln_index).instr_post_cd;          -- 指示部署
        g_shipped_locat_cd_tab(gn_header_count)      := g_file_data_tab(ln_index).shipped_locat_cd;       -- 出庫元保管場所
        g_ship_to_locat_cd_tab(gn_header_count)      := g_file_data_tab(ln_index).ship_to_locat_cd;       -- 入庫先保管場所
        g_schedule_ship_date_tab(gn_header_count)    
          := FND_DATE.STRING_TO_DATE(g_file_data_tab(ln_index).schedule_ship_date, 'YYYY/MM/DD');         -- 出庫予定日
        g_schedule_arrival_date_tab(gn_header_count) 
          := FND_DATE.STRING_TO_DATE(g_file_data_tab(ln_index).schedule_arrival_date, 'YYYY/MM/DD');      -- 入庫予定日
        g_freight_charge_cls_tab(gn_header_count)    := g_file_data_tab(ln_index).freight_charge_cls;     -- 運賃区分
        g_freight_carrier_cd_tab(gn_header_count)    := g_file_data_tab(ln_index).freight_carrier_cd;     -- 運送業者
        g_weight_capacity_cls_tab(gn_header_count)   := g_file_data_tab(ln_index).weight_capacity_cls;    -- 重量容積区分
        g_product_flg_tab(gn_header_count)           := g_file_data_tab(ln_index).product_flg;            -- 製品識別区分
--
      END IF;
--
      -----------------
      -- 明細項目設定
      -----------------
--
      -- 明細件数インクリメント
      gn_line_count := gn_line_count + 1;
--
      -- 明細ID採番
      SELECT  xxinv_mov_instr_line_if_s1.NEXTVAL
      INTO    ln_line_id
      FROM    dual
      ;
--
      -- 明細情報設定
      g_mov_line_if_id_tab(gn_line_count)       := ln_line_id;                                              -- 移動明細IF_ID
      g_mov_line_hdr_if_id_tab(gn_line_count)   := ln_header_id;                                            -- 移動ヘッダIF_ID
      g_item_cd_tab(gn_line_count)              := g_file_data_tab(ln_index).item_cd;                       -- 品目
      g_designated_prod_date_tab(gn_line_count) 
        := FND_DATE.STRING_TO_DATE(g_file_data_tab(ln_index).designated_production_date, 'YYYY/MM/DD');     -- 指定製造日
      g_first_instruct_qty_tab(gn_line_count)   := TO_NUMBER(g_file_data_tab(ln_index).first_instruct_qty); -- 初回指示数量
--
      -- 仮伝票番号を判定用変数に格納
      lv_pre_temp_ship_no := g_file_data_tab(ln_index).temp_ship_no;
--
    END LOOP data_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END set_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_header
   * Description      : ヘッダデータ登録(L-6)
   ***********************************************************************************/
  PROCEDURE insert_header(
      ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_header'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -----------------------------------------------
    -- 移動指示ヘッダインタフェース(アドオン) 登録
    -----------------------------------------------
    FORALL rec_cnt IN 1..gn_header_count
      INSERT INTO xxinv_mov_instr_headers_if(
          mov_hdr_if_id                         -- 移動ヘッダIF_ID
        , temp_ship_num                         -- 仮伝票番号
        , mov_type                              -- 移動タイプ
        , instruction_post_code                 -- 指示部署
        , shipped_locat_code                    -- 出庫元保管場所
        , ship_to_locat_code                    -- 入庫先保管場所
        , schedule_ship_date                    -- 出庫予定日
        , schedule_arrival_date                 -- 入庫予定日
        , freight_charge_class                  -- 運賃区分
        , freight_carrier_code                  -- 運送業者
        , weight_capacity_class                 -- 重量容積区分
        , product_flg                           -- 製品識別区分
        , created_by                            -- 作成者
        , creation_date                         -- 作成日
        , last_updated_by                       -- 最終更新者
        , last_update_date                      -- 最終更新日
        , last_update_login                     -- 最終更新ログイン
        , request_id                            -- 要求ID
        , program_application_id                -- コンカレント・プログラム・アプリケーションID
        , program_id                            -- コンカレント・プログラムID
        , program_update_date                   -- プログラム更新日
      ) VALUES (
          g_mov_hdr_if_id_tab(rec_cnt)          -- 移動ヘッダIF_ID
        , g_tmp_ship_number_tab(rec_cnt)        -- 仮伝票番号
        , g_mov_type_tab(rec_cnt)               -- 移動タイプ
        , g_instr_post_cd_tab(rec_cnt)          -- 指示部署
        , g_shipped_locat_cd_tab(rec_cnt)       -- 出庫元保管場所
        , g_ship_to_locat_cd_tab(rec_cnt)       -- 入庫先保管場所
        , g_schedule_ship_date_tab(rec_cnt)     -- 出庫予定日
        , g_schedule_arrival_date_tab(rec_cnt)  -- 入庫予定日
        , g_freight_charge_cls_tab(rec_cnt)     -- 運賃区分
        , g_freight_carrier_cd_tab(rec_cnt)     -- 運送業者
        , g_weight_capacity_cls_tab(rec_cnt)    -- 重量容積区分
        , g_product_flg_tab(rec_cnt)            -- 製品識別区分
        , gn_user_id                            -- 作成者
        , gd_sysdate                            -- 作成日
        , gn_user_id                            -- 最終更新者
        , gd_sysdate                            -- 最終更新日
        , gn_login_id                           -- 最終更新ログイン
        , gn_conc_request_id                    -- 要求ID
        , gn_prog_appl_id                       -- コンカレント・プログラム・アプリケーションID
        , gn_conc_program_id                    -- コンカレント・プログラムID
        , gd_sysdate                            -- プログラム更新日
      );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END insert_header;
--
  /**********************************************************************************
   * Procedure Name   : insert_lines
   * Description      : 明細データ登録(L-7)
   ***********************************************************************************/
  PROCEDURE insert_lines(
      ov_errbuf       OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_lines'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -----------------------------------------------
    -- 移動指示明細インタフェース(アドオン) 登録
    -----------------------------------------------
    FORALL rec_cnt IN 1..gn_line_count
      INSERT INTO xxinv_mov_instr_lines_if(
          mov_line_if_id                        -- 移動明細IF_ID
        , mov_hdr_if_id                         -- 移動ヘッダIF_ID
        , item_code                             -- 品目
        , designated_production_date            -- 指定製造日
        , first_instruct_qty                    -- 初回指示数量
        , created_by                            -- 作成者
        , creation_date                         -- 作成日
        , last_updated_by                       -- 最終更新者
        , last_update_date                      -- 最終更新日
        , last_update_login                     -- 最終更新ログイン
        , request_id                            -- 要求ID
        , program_application_id                -- コンカレント・プログラム・アプリケーションID
        , program_id                            -- コンカレント・プログラムID
        , program_update_date                   -- プログラム更新日
      ) VALUES (
          g_mov_line_if_id_tab(rec_cnt)         -- 移動明細IF_ID
        , g_mov_line_hdr_if_id_tab(rec_cnt)     -- 移動ヘッダIF_ID
        , g_item_cd_tab(rec_cnt)                -- 品目
        , g_designated_prod_date_tab(rec_cnt)   -- 指定製造日
        , g_first_instruct_qty_tab(rec_cnt)     -- 初回指示数量
        , gn_user_id                            -- 作成者
        , gd_sysdate                            -- 作成日
        , gn_user_id                            -- 最終更新者
        , gd_sysdate                            -- 最終更新日
        , gn_login_id                           -- 最終更新ログイン
        , gn_conc_request_id                    -- 要求ID
        , gn_prog_appl_id                       -- コンカレント・プログラム・アプリケーションID
        , gn_conc_program_id                    -- コンカレント・プログラムID
        , gd_sysdate                            -- プログラム更新日
      );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END insert_lines;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      in_file_id      IN  NUMBER      --   ファイルＩＤ
    , in_file_format  IN  VARCHAR2    --   フォーマットパターン
    , ov_errbuf       OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2    --   リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 関連データ取得（L-1）
    -- ===============================
    init(
        in_file_format  -- フォーマットパターン
      , lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , lv_retcode      -- リターン・コード             --# 固定 #
      , lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- ファイルアップロードインタフェースデータ取得（L-2）
    -- ===================================================
    get_upload_data(
        in_file_id      -- ファイルID
      , lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , lv_retcode      -- リターン・コード             --# 固定 #
      , lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--#################################  アップロード固定メッセージ START  ###################################
    --処理結果レポート出力（上部）
    -- ファイル名
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_file_name,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- アップロード日時
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_upload_date,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- ファイルアップロード名称
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_upload_name,
                                              gv_c_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  アップロード固定メッセージ END   ###################################
--
    -- ファイルアップロードインタフェースデータ取得結果を判定
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    END IF;
--
    -- =========================
    -- 妥当性チェック(L-3,4,5)
    -- =========================
    validity_check(
        lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , lv_retcode      -- リターン・コード             --# 固定 #
      , lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
--
      RAISE global_process_expt;
--
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
      -- 妥当性チェックでエラーが無かった場合
      -- ==================
      -- 登録データ設定
      -- ==================
      set_data(
        lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , lv_retcode      -- リターン・コード             --# 固定 #
      , lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =======================
      -- ヘッダデータ登録(L-6)
      -- =======================
      insert_header(
        lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , lv_retcode      -- リターン・コード             --# 固定 #
      , lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ======================
      -- 明細データ登録(L-7)
      -- ======================
      insert_lines(
        lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , lv_retcode      -- リターン・コード             --# 固定 #
      , lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===================================================
    -- ファイルアップロードインタフェースデータ削除(L-8)
    -- ===================================================
    xxcmn_common3_pkg.delete_fileup_proc(
        in_file_format        -- フォーマットパターン
      , gd_sysdate            -- 対象日付
      , gn_xxinv_purge_term   -- パージ対象期間
      , lv_errbuf             -- エラー・メッセージ           --# 固定 #
      , lv_retcode            -- リターン・コード             --# 固定 #
      , lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    IF (lv_retcode = gv_status_error) THEN
      -- 削除処理エラー時にRollBackをする為、妥当性チェックステータスを初期化
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- 一時表データ削除(L-9)
    -- ===================================================
    DELETE FROM xxinv_tmp_mov_instr_if
    WHERE file_id = in_file_id
    ;
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
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id      IN  VARCHAR2,      --   ファイルＩＤ
    in_file_format  IN  VARCHAR2       --   フォーマットパターン
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
    cv_prg_name         CONSTANT  VARCHAR2(100) :=  'main';             -- プログラム名
    cv_status_code      CONSTANT  VARCHAR2(14)  :=  'CP_STATUS_CODE';   -- ステータスコード
    cv_userenv          CONSTANT  VARCHAR2(4)   :=  userenv('LANG');    -- USERENV
    cv_msg_kbn          CONSTANT  VARCHAR2(5)   :=  'XXCMN';            -- メッセージ
    cv_appl_id          CONSTANT  NUMBER        :=  0;                  -- アプリケーションID
--
    cv_msg_user_name    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00001';  -- ユーザ名
    cv_msg_conc_name    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00002';  -- コンカレント名
    cv_msg_start_time   CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10118';  -- 起動時間
    cv_msg_separater    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00003';  -- セパレータ
    cv_msg_standard     CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10030';  -- コンカレント定型メッセージ
    cv_msg_process_cnt  CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00008';  -- 処理件数
    cv_msg_success_cnt  CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00009';  -- 成功件数
    cv_msg_error_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00010';  -- エラー件数
    cv_msg_skip_cnt     CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00011';  -- スキップ件数
    cv_msg_proc_status  CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00012';  -- 処理ステータス
--
    -- トークン
    cv_tkn_user         CONSTANT  VARCHAR2(4)   :=  'USER';
    cv_tkn_conc         CONSTANT  VARCHAR2(4)   :=  'CONC';
    cv_tkn_time         CONSTANT  VARCHAR2(4)   :=  'TIME';
    cv_tkn_count        CONSTANT  VARCHAR2(3)   :=  'CNT';
    cv_tkn_status       CONSTANT  VARCHAR2(6)   :=  'STATUS';
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
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_user_name, cv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_conc_name, cv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_start_time,
                                           cv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_separater);
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        TO_NUMBER(in_file_id)   -- ファイルＩＤ
      , in_file_format          -- フォーマットパターン
      , lv_errbuf               -- エラー・メッセージ           --# 固定 #
      , lv_retcode              -- リターン・コード             --# 固定 #
      , lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_standard);
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
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_process_cnt, cv_tkn_count, TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_success_cnt, cv_tkn_count, TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_error_cnt, cv_tkn_count, TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_skip_cnt, cv_tkn_count, TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = cv_userenv
    AND    flv.view_application_id = cv_appl_id
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_status_code
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn, cv_msg_proc_status, cv_tkn_status,gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
--
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal)THEN
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
END XXINV990010C;
/
