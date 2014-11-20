create or replace PACKAGE BODY XXCOS011A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A10C (body)
 * Description      : 入庫予定データの抽出を行う
 * MD.050           : 入庫予定データ抽出 (MD050_COS_011_A10)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0,A-1)
 *  get_req_order_data     移動オーダー情報抽出 (A-2)
 *  chk_edi_stc_data       入庫予定存在チェック (A-3)
 *  ins_edi_stc_line       入庫予定明細作成 (A-4,A-5)
 *  ins_edi_stc_header     入庫予定ヘッダー作成 (A-5)
 *  chk_item_status        品目ステータスチェック (A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   K.Kiriu         新規作成
 *  2009/03/13    1.1   N.Maeda         【障害No.T1_0021】Min-Max計画で作成の移動オーダーデータ対応
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
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  --ロックエラー
  no_target_expt EXCEPTION; --処理対象なし
  item_chk_expt  EXCEPTION; --顧客受注可能品目以外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS011A10C'; -- パッケージ名
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';        -- アプリケーション名
  -- プロファイル
  cv_prf_orga_code   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_prf_case_uom    CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:ケース単位コード
  cv_prf_ball_uom    CONSTANT VARCHAR2(50)  := 'XXCOS1_BALL_UOM_CODE';      -- XXCOS:ボール単位コード

  -- メッセージコード
  cv_msg_param       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12552';  -- パラメーター出力
  cv_msg_param_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- パラメーター必須エラー
  cv_msg_prf_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- プロファイル取得エラー
  cv_msg_orga_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12551';  -- 在庫組織ID取得エラー
  cv_msg_orga_tkn    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';  -- 在庫組織プロファイル名
  cv_msg_table_tkn1  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12553';  -- 移動オーダーヘッダ
  cv_msg_table_tkn2  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12554';  -- 入庫予定ヘッダ
  cv_msg_table_tkn3  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12558';  -- 入庫予定明細
  cv_msg_lock_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_no_target   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データなし
  cv_msg_uom_tkn1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';  -- ケース単位プロファイル名
  cv_msg_uom_tkn2    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00059';  -- ボール単位プロファイル名
  cv_msg_param_tkn1  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12555';  -- 搬送先保管場所
  cv_msg_param_tkn2  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12556';  -- EDIチェーン店コード
  cv_msg_param_tkn3  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12557';  -- 移動オーダー番号
  cv_msg_ins_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- データ登録エラー
  cv_msg_del_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';  -- データ削除エラー
  cv_msg_cust_o_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12559';  -- 顧客受注可能品以外エラー
  -- トークンコード
  cv_tkn_pram1       CONSTANT VARCHAR2(6)   := 'PARAM1';            -- パラメーター１
  cv_tkn_pram2       CONSTANT VARCHAR2(6)   := 'PARAM2';            -- パラメーター２
  cv_tkn_pram3       CONSTANT VARCHAR2(6)   := 'PARAM3';            -- パラメーター３
  cv_tkn_in_param    CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- パラメータ名称
  cv_tkn_prf         CONSTANT VARCHAR2(7)   := 'PROFILE';           -- プロファイル名称
  cv_tkn_orga        CONSTANT VARCHAR2(8)   := 'ORG_CODE';          -- 在庫組織コード
  cv_tkn_table       CONSTANT VARCHAR2(5)   := 'TABLE';             -- テーブル名
  cv_tkn_key         CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- キーデータ
  cv_tkn_item        CONSTANT VARCHAR2(9)   := 'ITEM_CODE';         -- 品名コード
  -- データ取得用固定値
  cn_status_cancel   CONSTANT NUMBER        := 6;                   -- 移動オーダーステータス(取消)
  cv_cust_status     CONSTANT VARCHAR2(2)   := '90';                -- 顧客ステータス(中止決裁済)
  cv_cust_code_cust  CONSTANT VARCHAR2(2)   := '10';                -- 顧客区分(顧客)
  cv_cust_code_chain CONSTANT VARCHAR2(2)   := '18';                -- 顧客区分(チェーン店)
  -- その他固定値
  cn_0               CONSTANT NUMBER        := 0;                   -- 固定値:0
  cn_1               CONSTANT NUMBER        := 1;                   -- 固定値:1
  cv_n               CONSTANT VARCHAR2(1)   := 'N';                 -- 固定値:N
  cv_status          CONSTANT VARCHAR2(1)   := 'A';                 -- 顧客マスタステータス
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_orga_id         NUMBER;      -- 在庫組織ID
  gv_case_uom_code   VARCHAR2(6); -- ケース単位
  gv_ball_uom_code   VARCHAR2(6); -- ボール単位
--
  -- ===============================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===============================
  --移動オーダーデータレコード型
  TYPE g_req_order_data_rtype IS RECORD(
    header_id             mtl_txn_request_headers.header_id%TYPE,
    request_number        mtl_txn_request_headers.request_number%TYPE,
    to_subinventory_code  mtl_txn_request_headers.to_subinventory_code%TYPE,
    h_organization_id     mtl_txn_request_headers.organization_id%TYPE,
    account_number        hz_cust_accounts.account_number%TYPE,
    chain_store_code      xxcmm_cust_accounts.chain_store_code%TYPE,
    line_id               mtl_txn_request_lines.line_id%TYPE,
    line_number           mtl_txn_request_lines.line_number%TYPE,
    inventory_item_id     mtl_txn_request_lines.inventory_item_id%TYPE,
    l_organization_id     mtl_txn_request_lines.organization_id%TYPE,
    case_qty              xxcos_edi_stc_lines.case_qty%TYPE,
    indv_qty              xxcos_edi_stc_lines.indv_qty%TYPE
  );
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  --移動オーダーデータ テーブル型
  TYPE g_req_order_data_ttype IS TABLE OF g_req_order_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_order_date  g_req_order_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0,A-1)
   ***********************************************************************************/
  PROCEDURE init(
    it_to_s_code        IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --   搬送先保管場所
    it_edi_c_code       IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --   EDIチェーン店コード
    it_request_number   IN  mtl_txn_request_headers.request_number%TYPE,        --   移動オーダー番号
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_param_msg VARCHAR2(5000);  --パラメーター出力用
    lv_err_msg   VARCHAR2(5000);  --プロファイルエラー出力用(プロファイルは取得エラーごとに出力する為)
    lv_orga_code VARCHAR2(10);    --在庫組織コード
    lv_tkn_name  VARCHAR2(50);    --トークン取得用
    ln_err_chk   NUMBER(1);       --プロファイルエラーチェック用
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
    --パラメーターの出力
    --==============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --メッセージ取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_param       --パラメーター出力
                     ,iv_token_name1  => cv_tkn_pram1       --トークンコード１
                     ,iv_token_value1 => it_to_s_code       --搬送先保管場所
                     ,iv_token_name2  => cv_tkn_pram2       --トークンコード２
                     ,iv_token_value2 => it_edi_c_code      --EDIチェーン店コード
                     ,iv_token_name3  => cv_tkn_pram3       --トークンコード３
                     ,iv_token_value3 => it_request_number  --移動オーダー番号
                    );
    --メッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --ログに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==============================================================
    --パラメーターの必須チェック
    --==============================================================
    -- 搬送先保管場所
    IF ( it_to_s_code IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_param_tkn1  --搬送先保管場所
                     );
    -- EDIチェーン店コード
    ELSIF ( it_edi_c_code IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_param_tkn2  --EDIチェーン店コード
                     );
    -- 移動オーダー番号
    ELSIF ( it_request_number IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_param_tkn3  --移動オーダー番号
                     );
    END IF;
    --メッセージ設定
    IF ( it_to_s_code IS NULL )
      OR ( it_edi_c_code IS NULL )
      OR ( it_request_number IS NULL )
    THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --アプリケーション
                     ,iv_name         => cv_msg_param_err --パラメーター必須エラー
                     ,iv_token_name1  => cv_tkn_in_param  --トークンコード１
                     ,iv_token_value1 => lv_tkn_name      --パラメータ名
                   );
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --プロファイルの取得
    --==============================================================
    ln_err_chk       := 0;  --エラーチェック用変数の初期化
    --在庫組織情報の取得
    lv_orga_code     := FND_PROFILE.VALUE( cv_prf_orga_code );  --在庫組織コード
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom );   --ケース単位
    gv_ball_uom_code := FND_PROFILE.VALUE( cv_prf_ball_uom );   --ボール単位
--
    --在庫コード取得チェック
    IF ( lv_orga_code IS NULL ) THEN
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_orga_tkn    --在庫組織コード
                     );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application  --アプリケーション
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                     ,iv_token_value1 => lv_tkn_name     --プロファイル名
                   );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --エラー有り
    END IF;
    --ケース単位取得チェック
    IF ( gv_case_uom_code IS NULL ) THEN
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_uom_tkn1    --ケース単位プロファイル名
                     );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application --アプリケーション
                     ,iv_name         => cv_msg_prf_err --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf     --トークンコード１
                     ,iv_token_value1 => lv_tkn_name    --プロファイル名
                   );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --エラー有り
    END IF;
    --取得チェック
    IF ( gv_ball_uom_code IS NULL ) THEN
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_uom_tkn2    --ボール単位プロファイル名
                     );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application --アプリケーション
                     ,iv_name         => cv_msg_prf_err --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf     --トークンコード１
                     ,iv_token_value1 => lv_tkn_name    --プロファイル名
                   );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      ln_err_chk := 1;  --エラー有り
    END IF;
    --プロファイル取得のいづれかでエラーの場合
    IF ( ln_err_chk = 1 ) THEN
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --在庫組織IDの取得
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( lv_orga_code );
    --取得チェック
    IF ( gn_orga_id  IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --アプリケーション
                     ,iv_name         => cv_msg_orga_err  --在庫組織ID取得エラー
                     ,iv_token_name1  => cv_tkn_orga      --トークンコード１
                     ,iv_token_value1 => lv_orga_code     --在庫組織コード
                   );
      RAISE global_api_others_expt;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_req_order_data
   * Description      : 移動オーダー情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_req_order_data(
    it_to_s_code        IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --   搬送先保管場所
    it_edi_c_code       IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --   EDIチェーン店コード
    it_request_number   IN  mtl_txn_request_headers.request_number%TYPE,        --   移動オーダー番号
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_req_order_data'; -- プログラム名
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
    lv_table_name  VARCHAR2(50);  --テーブル名
--
    -- *** ローカル・カーソル ***
--
    --移動オーダー
    CURSOR req_order_cur
    IS
      SELECT  mtrh.header_id             header_id             --移動オーダーヘッダID
             ,mtrh.request_number        request_number        --移動オーダー番号
             ,mtrh.to_subinventory_code  to_subinventory_code  --搬送先保管場所
             ,mtrh.organization_id       organization_id       --組織ID
             ,hca2.account_number        account_number        --顧客コード
             ,hca2.chain_store_code      chain_store_code      --EDIチェーン店コード
             ,mtrl.line_id               line_id               --移動オーダー明細ID
             ,mtrl.line_number           line_number           --明細行No
             ,mtrl.inventory_item_id     inventory_item_id     --品目ID
             ,mtrl.organization_id       organization_id       --組織ID
             ,DECODE( mtrl.uom_code
                     ,gv_case_uom_code, mtrl.quantity      --ケース単位の場合は数量
                     ,cn_0                                 --それ以外は0
              )                          case_qty              --ケース数量
             ,DECODE( mtrl.uom_code
                     ,gv_case_uom_code, cn_0               --ケース単位の場合は0
                     ,gv_ball_uom_code, NVL(
                                              ( SELECT  xsib.bowl_inc_num
                                                FROM    mtl_system_items_b   msib
                                                       ,xxcmm_system_items_b xsib
                                                WHERE   xsib.item_code         = msib.segment1
                                                AND     msib.inventory_item_id = mtrl.inventory_item_id
                                                AND     msib.organization_id   = mtrl.organization_id
                                              )
                                             ,cn_1
                                           ) * mtrl.quantity  --ボール単位の場合はボール入数*数量
                     ,mtrl.quantity                           --それ以外は数量
              )                          indv_qty              --バラ数量
      FROM    mtl_txn_request_headers mtrh  --移動オーダーヘッダ
             ,mtl_txn_request_lines   mtrl  --移動オーダー明細
             ,( SELECT  hca.account_number     account_number     --顧客コード
                       ,xca.ship_storage_code  ship_storage_code  --出荷元保管場所(EDI)
                       ,xca.chain_store_code   chain_store_code   --チェーン店コード(EDI)
                FROM    hz_cust_accounts    hca  --顧客
                       ,xxcmm_cust_accounts xca  --顧客追加情報
                       ,hz_parties          hp   --パーティ
                WHERE   hca.customer_class_code =  cv_cust_code_cust   --顧客区分(顧客)
                AND     hca.status              =  cv_status           --ステータス(A)
                AND     hca.cust_account_id     =  xca.customer_id
                AND     xca.ship_storage_code   =  it_to_s_code
                AND     hca.party_id            =  hp.party_id
                AND     hp.duns_number_c        <> cv_cust_status      --顧客ステータス(中止決裁済以外)
              )                       hca1   --顧客
             ,( SELECT  xca.chain_store_code  chain_store_code    --チェーン店コード(EDI)
                       ,hca.account_number    account_number      --顧客コード
                FROM    hz_cust_accounts    hca  --顧客
                       ,xxcmm_cust_accounts xca  --顧客追加情報
                WHERE   hca.customer_class_code =  cv_cust_code_chain  --顧客区分(チェーン店)
                AND     hca.cust_account_id     =  xca.customer_id
                AND     hca.status              =  cv_status           --ステータス(A)
              )                       hca2   --顧客(チェーン店)
      WHERE   mtrl.line_status          <> cn_status_cancel        --明細ステータス(取消以外)
      AND     mtrh.header_id            =  mtrl.header_id          --結合(移動H = 移動L)
      AND     hca1.chain_store_code     =  hca2.chain_store_code   --結合(顧客 = チェーン店)
      AND     hca1.chain_store_code     =  it_edi_c_code           --EDIチェーン店コード
      AND     mtrh.to_subinventory_code =  hca1.ship_storage_code  --結合(移動H = 顧客)
      AND     NVL( mtrh.attribute1 , cv_n ) =  cv_n                    --EDI送信済みフラグ(未送信)
      AND     mtrh.header_status        <> cn_status_cancel        --ヘッダステータス(取消以外)
      AND     mtrh.organization_id      =  gn_orga_id              --組織ID
      AND     mtrh.to_subinventory_code =  it_to_s_code            --搬送先保管場所
      AND     mtrh.request_number       =  it_request_number       --移動オーダー番号
      AND     hca1.account_number =
               ( SELECT  MAX(hca.account_number)
                 FROM    hz_cust_accounts    hca  --顧客
                        ,xxcmm_cust_accounts xca  --顧客追加情報
                        ,hz_parties          hp   --パーティ
                 WHERE   hp.duns_number_c        <> cv_cust_status
                 AND     hca.party_id            =  hp.party_id
                 AND     hca.customer_class_code =  cv_cust_code_cust
                 AND     hca.status              =  cv_status
                 AND     xca.customer_id         =  hca.cust_account_id
                 AND     xca.ship_storage_code   =  mtrh.to_subinventory_code
                 AND     xca.chain_store_code    =  hca2.chain_store_code
               )    --顧客が複数件ある為1件に絞る
      FOR UPDATE OF
        mtrh.header_id
       ,mtrl.line_id NOWAIT
      ;
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
    OPEN req_order_cur;
    FETCH req_order_cur BULK COLLECT INTO gt_req_order_date;
    --対象件数取得
    gn_target_cnt := req_order_cur%ROWCOUNT;
    CLOSE req_order_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN                           --*** ロックエラー ***
      --カーソルクローズ
      IF ( req_order_cur%ISOPEN ) THEN
        CLOSE req_order_cur;
      END IF;
      --トークン取得
      lv_table_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --アプリケーション
                         ,iv_name         => cv_msg_table_tkn1  --移動オーダーヘッダ
                       );
      --メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_lock_err    --ロックエラー
                     ,iv_token_name1  => cv_tkn_table       --トークンコード１
                     ,iv_token_value1 => lv_table_name      --移動オーダーヘッダ
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SQLERRM;
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
  END get_req_order_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_edi_stc_data
   * Description      : 入庫予定存在チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_edi_stc_data(
    it_request_number    IN  mtl_txn_request_headers.request_number%TYPE,  --移動オーダー番号
    ot_edi_sts_header_id OUT xxcos_edi_stc_headers.header_id%TYPE,         --入庫予定ヘッダID
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_edi_stc_data'; -- プログラム名
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
    ln_data_cnt    NUMBER;        --抽出件数取得用
    lv_table_name  VARCHAR2(50);  --テーブル名(トークン取得用)
--
    -- *** ローカル・カーソル ***
--
    --入庫予定
    CURSOR edi_sts_cur
    IS
      SELECT xesh.header_id  header_id
      FROM   xxcos_edi_stc_headers xesh
            ,xxcos_edi_stc_lines   xesl
      WHERE  xesh.move_order_num   = it_request_number
      AND    xesh.organization_id  = gn_orga_id
      AND    xesh.header_id        = xesl.header_id
      FOR UPDATE OF  xesh.header_id
                    ,xesl.line_id
      NOWAIT
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・TABLE型 ***
    TYPE g_edi_sts_data_ttype IS TABLE OF xxcos_edi_stc_headers.header_id%TYPE INDEX BY PLS_INTEGER;   -- ロック用
    gt_edi_sts_data g_edi_sts_data_ttype;
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
    --初期化
    ln_data_cnt := 0;
    --入庫予定データロック
    OPEN edi_sts_cur;
    FETCH edi_sts_cur BULK COLLECT INTO gt_edi_sts_data;
    ln_data_cnt := edi_sts_cur%ROWCOUNT;
    CLOSE edi_sts_cur;
    --データの存在チェック
    IF ( ln_data_cnt <> 0 ) THEN
      --入庫予定ヘッダIDセット
      ot_edi_sts_header_id := gt_edi_sts_data(1);
    END IF;
--
    --入庫予定データが存在する場合
    IF ( ot_edi_sts_header_id IS NOT NULL ) THEN
      BEGIN
        --入庫予定明細の削除
        DELETE FROM xxcos_edi_stc_lines xesl
        WHERE  xesl.header_id = ot_edi_sts_header_id
        ;
      EXCEPTION
      -- *** DELETE OTHERS例外 ***
      WHEN OTHERS THEN
        --トークン取得
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     --アプリケーション
                          ,iv_name         => cv_msg_table_tkn3  --入庫予定明細
                         );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --アプリケーション
                      ,iv_name         => cv_msg_del_err     --データ削除エラー'
                      ,iv_token_name1  => cv_tkn_table       --トークンコード１
                      ,iv_token_value1 => lv_table_name      --入庫予定明細
                      ,iv_token_name2  => cv_tkn_key         --トークンコード２
                      ,iv_token_value2 => it_request_number  --移動オーダー番号
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;

    END IF;
--
  EXCEPTION
--
    WHEN lock_expt THEN                           --*** ロックエラー ***
      --カーソルクローズ
      IF ( edi_sts_cur%ISOPEN ) THEN
        CLOSE edi_sts_cur;
      END IF;
      --トークン取得
      lv_table_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --アプリケーション
                         ,iv_name         => cv_msg_table_tkn2  --入庫予定ヘッダ
                       );
      --メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_lock_err    --ロックエラー
                     ,iv_token_name1  => cv_tkn_table       --トークンコード１
                     ,iv_token_value1 => lv_table_name      --入庫予定ヘッダ
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SQLERRM;
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
  END chk_edi_stc_data;
--
--
  /**********************************************************************************
   * Procedure Name   : 
   
   * Description      : 入庫予定明細作成(A-4,A-5)
   ***********************************************************************************/
  PROCEDURE ins_edi_stc_line(
    it_edi_stc_line    IN  xxcos_edi_stc_lines%ROWTYPE,                  --1.入庫予定明細
    it_request_number  IN  mtl_txn_request_headers.request_number%TYPE,  --2.移動オーダー番号
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_edi_stc_line'; -- プログラム名
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
    lv_tkn_name  VARCHAR2(50);    --トークン取得用
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
    BEGIN
      --入庫予定明細データ挿入処理
      INSERT INTO xxcos_edi_stc_lines(
         line_id                 --明細ID
        ,header_id               --ヘッダID
        ,move_order_line_id      --移動オーダー明細ID
        ,move_order_header_id    --移動オーダーヘッダID
        ,organization_id         --組織ID
        ,inventory_item_id       --品目ID
        ,case_qty                --ケース数
        ,indv_qty                --バラ数
        ,created_by              --作成者
        ,creation_date           --作成日
        ,last_updated_by         --最終更新者
        ,last_update_date        --最終更新日
        ,last_update_login       --最終更新ログイン
        ,request_id              --要求ID
        ,program_application_id  --コンカレント・プログラム・アプリケーションID
        ,program_id              --コンカレント・プログラムID
        ,program_update_date     --プログラム更新日
      )VALUES(
         xxcos_edi_stc_lines_s01.NEXTVAL       --明細ID
        ,it_edi_stc_line.header_id             --ヘッダID
        ,it_edi_stc_line.move_order_line_id    --移動オーダー明細ID
        ,it_edi_stc_line.move_order_header_id  --移動オーダーヘッダID
        ,it_edi_stc_line.organization_id       --組織ID
        ,it_edi_stc_line.inventory_item_id     --品目ID
        ,it_edi_stc_line.case_qty              --ケース数
        ,it_edi_stc_line.indv_qty              --バラ数
        ,cn_created_by                         --作成者
        ,cd_creation_date                      --作成日
        ,cn_last_updated_by                    --最終更新者
        ,cd_last_update_date                   --最終更新日
        ,cn_last_update_login                  --最終更新ログイン
        ,cn_request_id                         --要求ID
        ,cn_program_application_id             --コンカレント・プログラム・アプリケーションID
        ,cn_program_id                         --コンカレント・プログラムID
        ,cd_program_update_date                --プログラム更新日
       );
--
      --正常処理件数取得
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      -- *** INESRT OTHERS例外 ***
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_table_tkn3  --入庫予定明細
                       );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --アプリケーション
                      ,iv_name         => cv_msg_ins_err     --データ登録エラー'
                      ,iv_token_name1  => cv_tkn_table       --トークンコード１
                      ,iv_token_value1 => lv_tkn_name        --入庫予定明細
                      ,iv_token_name2  => cv_tkn_key         --トークンコード２
                      ,iv_token_value2 => it_request_number  --移動オーダー番号
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END ins_edi_stc_line;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_edi_stc_header
   * Description      : 入庫予定ヘッダ作成(A-5)
   ***********************************************************************************/
  PROCEDURE ins_edi_stc_header(
    it_edi_stc_header IN  xxcos_edi_stc_headers%ROWTYPE,        --入庫予定ヘッダー
    ot_header_id      OUT xxcos_edi_stc_headers.header_id%TYPE, --入庫予定ヘッダーID
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_edi_stc_header'; -- プログラム名
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
    lv_tkn_name  VARCHAR2(50);    --トークン取得用
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
    -- シーケンス取得
    SELECT xxcos_edi_stc_headers_s01.NEXTVAL
    INTO   ot_header_id
    FROM   DUAL;
--
    BEGIN
      --入庫予定ヘッダデータ挿入処理
      INSERT INTO xxcos_edi_stc_headers(
         header_id                    --ヘッダID
        ,move_order_header_id         --移動オーダーヘッダID
        ,move_order_num               --移動オーダー番号
        ,to_subinventory_code         --搬送先保管場所
        ,customer_code                --顧客コード
        ,edi_chain_code               --EDIチェーン店コード
        ,shop_code                    --店コード
        ,center_code                  --センターコード
        ,invoice_number               --伝票番号
        ,other_party_department_code  --相手先部門コード
        ,schedule_shipping_date       --出荷予定日
        ,schedule_arrival_date        --入庫予定日
        ,rcpt_possible_date           --受入可能日
        ,inspect_schedule_date        --検品予定日
        ,invoice_class                --伝票区分
        ,classification_class         --分類区分
        ,whse_class                   --倉庫区分
        ,regular_ar_sale_class        --定番特売区分
        ,opportunity_code             --便コード
        ,fix_flag                     --確定フラグ
        ,edi_send_date                --EDI送信日時
        ,edi_send_flag                --EDI送信済みフラグ
        ,prev_edi_send_date           --前回EDI送信日時
        ,prev_edi_send_request_id     --前回EDI送信要求ID
        ,organization_id              --組織ID
        ,created_by                   --作成者
        ,creation_date                --作成日
        ,last_updated_by              --最終更新者
        ,last_update_date             --最終更新日
        ,last_update_login            --最終更新ログイン
        ,request_id                   --要求ID
        ,program_application_id       --コンカレント・プログラム・アプリケーションID
        ,program_id                   --コンカレント・プログラムID
        ,program_update_date          --プログラム更新日
      )VALUES(
         ot_header_id                                   --ヘッダID
        ,it_edi_stc_header.move_order_header_id         --移動オーダーヘッダID
        ,it_edi_stc_header.move_order_num               --移動オーダー番号
        ,it_edi_stc_header.to_subinventory_code         --搬送先保管場所
        ,it_edi_stc_header.customer_code                --顧客コード
        ,it_edi_stc_header.edi_chain_code               --EDIチェーン店コード
        ,it_edi_stc_header.shop_code                    --店コード
        ,it_edi_stc_header.center_code                  --センターコード
        ,it_edi_stc_header.invoice_number               --伝票番号
        ,it_edi_stc_header.other_party_department_code  --相手先部門コード
        ,it_edi_stc_header.schedule_shipping_date       --出荷予定日
        ,it_edi_stc_header.schedule_arrival_date        --入庫予定日
        ,it_edi_stc_header.rcpt_possible_date           --受入可能日
        ,it_edi_stc_header.inspect_schedule_date        --検品予定日
        ,it_edi_stc_header.invoice_class                --伝票区分
        ,it_edi_stc_header.classification_class         --分類区分
        ,it_edi_stc_header.whse_class                   --倉庫区分
        ,it_edi_stc_header.regular_ar_sale_class        --定番特売区分
        ,it_edi_stc_header.opportunity_code             --便コード
        ,it_edi_stc_header.fix_flag                     --確定フラグ
        ,it_edi_stc_header.edi_send_date                --EDI送信日時
        ,it_edi_stc_header.edi_send_flag                --EDI送信済みフラグ
        ,it_edi_stc_header.prev_edi_send_date           --前回EDI送信日時
        ,it_edi_stc_header.prev_edi_send_request_id     --前回EDI送信要求ID
        ,it_edi_stc_header.organization_id              --組織ID
        ,cn_created_by                                  --作成者
        ,cd_creation_date                               --作成日
        ,cn_last_updated_by                             --最終更新者
        ,cd_last_update_date                            --最終更新日
        ,cn_last_update_login                           --最終更新ログイン
        ,cn_request_id                                  --要求ID
        ,cn_program_application_id                      --コンカレント・プログラム・アプリケーションID
        ,cn_program_id                                  --コンカレント・プログラムID
        ,cd_program_update_date                         --プログラム更新日
       );
    EXCEPTION
      -- *** INESRT OTHERS例外 ***
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_table_tkn2  --入庫予定ヘッダ
                       );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application                    --アプリケーション
                      ,iv_name         => cv_msg_ins_err                    --データ登録エラー'
                      ,iv_token_name1  => cv_tkn_table                      --トークンコード１
                      ,iv_token_value1 => lv_tkn_name                       --入庫予定ヘッダ
                      ,iv_token_name2  => cv_tkn_key                        --トークンコード２
                      ,iv_token_value2 => it_edi_stc_header.move_order_num  --移動オーダー番号
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END ins_edi_stc_header;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_item_status
   * Description      : 品目ステータスチェック(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item_status(
    it_inventory_item_id   IN  mtl_txn_request_lines.inventory_item_id%TYPE,  -- 1.品目ID
    ov_chk_status          OUT VARCHAR2,                                      -- 2.チェックステータス
    ov_errbuf              OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg              OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_status'; -- プログラム名
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
    lv_err_msg                  VARCHAR2(5000);                                       --メッセージ出力用
    lt_cust_order_enabled_flag  mtl_system_items_b.customer_order_enabled_flag%TYPE;  --顧客受注可能フラグ
    lt_segment1                 mtl_system_items_b.segment1%TYPE;                     --品名コード
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
    ov_retcode    := cv_status_normal;
    ov_chk_status := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --顧客受注可能フラグの取得
    SELECT   msib.customer_order_enabled_flag  --顧客受注可能フラグ
            ,msib.segment1                     --品名コード
    INTO     lt_cust_order_enabled_flag
            ,lt_segment1
    FROM     mtl_system_items_b  msib
    WHERE    msib.inventory_item_id  = it_inventory_item_id
    AND      msib.organization_id    = gn_orga_id
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --顧客受注可能品以外の品目の場合(品目ステータス30と40のみYとなっている)
    IF ( lt_cust_order_enabled_flag = cv_n ) THEN
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_cust_o_err  --顧客受注可能品以外エラー
                       ,iv_token_name1  => cv_tkn_item        --トークンコード１
                       ,iv_token_value1 => lt_segment1        --品名コード
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        --チェックステータス変更(チェックエラー)
        ov_chk_status := cv_status_error;
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
  END chk_item_status;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_to_s_code      IN  VARCHAR2,     --   1.搬送先保管場所
    iv_edi_c_code     IN  VARCHAR2,     --   2.EDIチェーン店コード
    iv_request_number IN  VARCHAR2,     --   3.移動オーダー番号
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_no_target_msg      VARCHAR2(5000);                        --対象なしメッセージ取得用
    lv_item_s_chk_retcode VARCHAR2(1);                           --品目ステータスチェックの戻り値格納用
    lv_item_stauts_chk    VARCHAR2(1);                           --品目ステータスチェックの処理判定用
    lt_edi_stc_header_id  xxcos_edi_stc_headers.header_id%TYPE;  --入庫予定ヘッダID取得用(条件用)
    lt_header_id          xxcos_edi_stc_headers.header_id%TYPE;  --入庫予定ヘッダID取得用(作成用)
--
    -- *** ローカル・レコード ***
    lt_edi_stc_line       xxcos_edi_stc_lines%ROWTYPE;
    lt_edi_stc_header     xxcos_edi_stc_headers%ROWTYPE;
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
    -- ローカル変数の初期化
    lv_item_stauts_chk := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-0,A-1)
    -- ===============================
    init(
      iv_to_s_code,      -- 搬送先保管場所
      iv_edi_c_code,     -- EDIチェーン店コード
      iv_request_number, -- 移動オーダー番号
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- 移動オーダー情報抽出(A-2)
    -- ===============================
    get_req_order_data(
      iv_to_s_code,      -- 搬送先保管場所
      iv_edi_c_code,     -- EDIチェーン店コード
      iv_request_number, -- 移動オーダー番号
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --処理対象判定
    IF ( gn_target_cnt <> 0 ) THEN
--
      <<item_chk_loop>>
      FOR i IN 1.. gn_target_cnt  LOOP
        -- ===============================
        -- 品目ステータスチェック(A-7)
        -- ===============================
        chk_item_status(
          gt_req_order_date(i).inventory_item_id,            --品目ID(IN)
          lv_item_s_chk_retcode,                             --品目ステータス(OUT)
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --処理対象判定(例外)
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --処理対象判定(品目ステータス)
        IF ( lv_item_s_chk_retcode <> cv_status_normal ) THEN
          lv_item_stauts_chk := cv_status_error;
        END IF;
      END LOOP item_chk_loop;
      --処理対象判定(品目ステータス)
      IF ( lv_item_stauts_chk <> cv_status_normal ) THEN
        --移動オーダー内に1件でもエラーがある場合
        RAISE item_chk_expt;
      END IF;
--
      <<req_order_loop>>
      FOR i IN 1.. gn_target_cnt  LOOP
        --最初の1件のみ
        IF ( i = 1 ) THEN
          -- ===============================
          -- 入庫予定存在チェック(A-3)
          -- ===============================
          chk_edi_stc_data(
            gt_req_order_date(i).request_number,  -- 移動オーダー番号(IN)
            lt_edi_stc_header_id,                 -- 入庫予定ヘッダID(OUT)
            lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
            lv_retcode,                           -- リターン・コード             --# 固定 #
            lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
         IF (lv_retcode <> cv_status_normal) THEN
           RAISE global_process_expt;
         END IF;
        END IF;
--
        --入庫予定明細共通項目編集
        lt_edi_stc_line.move_order_line_id   := gt_req_order_date(i).line_id;
        lt_edi_stc_line.move_order_header_id := gt_req_order_date(i).header_id;
        lt_edi_stc_line.organization_id      := gt_req_order_date(i).l_organization_id;
        lt_edi_stc_line.inventory_item_id    := gt_req_order_date(i).inventory_item_id;
        lt_edi_stc_line.case_qty             := gt_req_order_date(i).case_qty;
        lt_edi_stc_line.indv_qty             := gt_req_order_date(i).indv_qty;
--
        --入庫予定ヘッダにデータがある場合
        IF ( lt_edi_stc_header_id IS NOT NULL ) THEN
          -- ===============================
          -- 入庫予定更新(A-4)
          -- ===============================
          --入庫予定明細データ編集
          lt_edi_stc_line.header_id := lt_edi_stc_header_id;
          --入庫予定明細作成
          ins_edi_stc_line(
            lt_edi_stc_line,                      -- 入庫予定明細(IN)
            gt_req_order_date(i).request_number,  -- 移動オーダー番号(IN)
            lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
            lv_retcode,                           -- リターン・コード             --# 固定 #
            lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        --入庫予定ヘッダにデータがない場合
        ELSE
          -- ===============================
          -- 入庫予定登録(A-5)
          -- ===============================
          --最初の1件のみ
          IF ( i = 1 ) THEN
            --入庫予定ヘッダデータ編集
            lt_edi_stc_header.move_order_header_id        := gt_req_order_date(i).header_id;
            lt_edi_stc_header.move_order_num              := gt_req_order_date(i).request_number;
            lt_edi_stc_header.to_subinventory_code        := gt_req_order_date(i).to_subinventory_code;
            lt_edi_stc_header.customer_code               := gt_req_order_date(i).account_number;
            lt_edi_stc_header.edi_chain_code              := gt_req_order_date(i).chain_store_code;
            lt_edi_stc_header.shop_code                   := NULL;
            lt_edi_stc_header.center_code                 := NULL;
            lt_edi_stc_header.invoice_number              := NULL;
            lt_edi_stc_header.other_party_department_code := NULL;
            lt_edi_stc_header.schedule_shipping_date      := NULL;
            lt_edi_stc_header.schedule_arrival_date       := NULL;
            lt_edi_stc_header.rcpt_possible_date          := NULL;
            lt_edi_stc_header.inspect_schedule_date       := NULL;
            lt_edi_stc_header.invoice_class               := NULL;
            lt_edi_stc_header.classification_class        := NULL;
            lt_edi_stc_header.whse_class                  := NULL;
            lt_edi_stc_header.regular_ar_sale_class       := NULL;
            lt_edi_stc_header.opportunity_code            := NULL;
            lt_edi_stc_header.fix_flag                    := cv_n;
            lt_edi_stc_header.edi_send_date               := NULL;
            lt_edi_stc_header.edi_send_flag               := cv_n;
            lt_edi_stc_header.prev_edi_send_date          := NULL;
            lt_edi_stc_header.prev_edi_send_request_id    := NULL;
            lt_edi_stc_header.organization_id             := gt_req_order_date(i).h_organization_id;
            --入庫予定ヘッダ作成
            ins_edi_stc_header(
              lt_edi_stc_header,  -- 入庫予定ヘッダ(IN)
              lt_header_id,       -- 作成した入庫予定ヘッダID(OUT)
              lv_errbuf,          -- エラー・メッセージ           --# 固定 #
              lv_retcode,         -- リターン・コード             --# 固定 #
              lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          --入庫予定明細データ編集
          lt_edi_stc_line.header_id := lt_header_id;
          --入庫予定明細作成
          ins_edi_stc_line(
            lt_edi_stc_line,                      -- 入庫予定明細(IN)
            gt_req_order_date(i).request_number,  -- 移動オーダー番号(IN)
            lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
            lv_retcode,                           -- リターン・コード             --# 固定 #
            lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END LOOP req_order_loop;
    --処理対象なし
    ELSE
      --メッセージ取得
      lv_no_target_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     --アプリケーション
                           ,iv_name         => cv_msg_no_target   --パラメーター出力(処理対象なし)
                          );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_no_target_msg
      );
    END IF;
--
  EXCEPTION
    -- *** 受注可能品目以外エラー ****
    WHEN item_chk_expt THEN
      ov_retcode := cv_status_error;
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
    errbuf             OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode            OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_to_s_code       IN  VARCHAR2,      --   1.搬送先保管場所
    iv_edi_c_code      IN  VARCHAR2,      --   2.EDIチェーン店コード
    iv_request_number  IN  VARCHAR2       --   3.移動オーダー番号
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
       iv_to_s_code       -- 搬送先保管場所
      ,iv_edi_c_code      -- EDIチェーン店コード
      ,iv_request_number  -- 移動オーダー番号
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
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
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
END XXCOS011A10C;
/