CREATE OR REPLACE PACKAGE BODY APPS.XXCOI010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A04C(body)
 * Description      : 拠点で扱う品目の組合せ情報を抽出しCSVファイルを作成して連携する。
 * MD.050           : 拠点品目情報HHT連携 MD050_COI_010_A04
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_item_record        拠点品目取得処理(A-3),拠点品目CSV作成処理(A-4)
 *  submain                メイン処理プロシージャ
 *                           ・ファイルのオープン処理(A-2)
 *                           ・終了処理(A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/04/05    1.0   H.Sekine         main新規作成
 *  2011/09/05    1.1   K.Nakamura       [E_本稼動_08224]管理元拠点の取得判定追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################

--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                                            -- 対象件数
  gn_normal_cnt    NUMBER;                                            -- 正常件数
  gn_error_cnt     NUMBER;                                            -- エラー件数
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
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOI010A04C';               -- パッケージ名
  cv_application             CONSTANT VARCHAR2(10)  := 'XXCCP';                      -- アプリケーション名
  cv_xxcos_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOI';                      -- 在庫短縮アプリ名
  -- メッセージ
  cv_target_rec_msg          CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';           -- 対象件数メッセージ
  cv_success_rec_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';           -- 成功件数メッセージ
  cv_error_rec_msg           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';           -- エラー件数メッセージ
  cv_normal_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';           -- 正常終了メッセージ
  cv_error_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';           -- エラー終了全ロールバック
  cv_msg_parameter_note      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10316';           -- パラメータ出力メッセージ
  cv_conc_not_parm_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- コンカレント入力パラメータなし
  cv_not_found_data_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';           -- 対象データ無し
  cv_date_err_msg            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10240';           -- 日付パラメータエラー
  cv_future_date_err_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10400';           -- 対象日未来日メッセージ
  cv_prf_org_err_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';           -- 在庫組織コード取得エラーメッセージ
  cv_prf_ship_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10168';           -- 出荷依頼ステータスコード取得エラーメッセージ
  cv_bulk_cnt_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00032';           -- プロファイル値取得エラーメッセージ
  cv_org_id_err_msg          CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';           -- 在庫組織ID取得エラーメッセージ
  cv_prf_itou_ou_mfg_err_msg CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10338';           -- 生産営業単位取得名称取得エラーメッセージ
  cv_prf_no_file_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';           -- ファイル存在チェックエラー
  cv_prf_file_name_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';           -- ファイル名出力メッセージ
  cv_prf_dire_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';           -- ディレクトリ名取得エラー
  cv_prf_file_name_err_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';           -- ファイル名取得エラー
  cv_full_path_err_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';           -- ディレクトリフルパス取得エラー
  cv_prf_notice_err_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10169';           -- 通知ステータスコード取得エラーメッセージ
  cv_process_date_expt_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';           -- 業務日付取得エラーメッセージ
  --トークン
  cv_cnt_token               CONSTANT VARCHAR2(20)  := 'COUNT';                      -- 件数
  cv_tkn_para_date           CONSTANT VARCHAR2(20)  := 'P_DATE';                     -- 業務日付
  cv_tkn_pro                 CONSTANT VARCHAR2(20)  := 'PRO_TOK';                    -- プロファイル名
  cv_tkn_org                 CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';               -- 在庫組織
  cv_tkn_dir                 CONSTANT VARCHAR2(20)  := 'DIR_TOK';                    -- ディレクトリ名
  cv_tkn_file_name           CONSTANT VARCHAR2(20)  := 'FILE_NAME';                  -- ファイル名
  -- プロファイルオプション
  cv_prf_org                 CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:在庫組織コード
  cv_prf_ship_status_close   CONSTANT VARCHAR2(30)  := 'XXCOI1_SHIP_STATUS_CLOSE';   -- XXCOI:出荷依頼ステータス_締め済み
  cv_prf_ship_status_result  CONSTANT VARCHAR2(30)  := 'XXCOI1_SHIP_STATUS_RESULTS'; -- XXCOI:出荷依頼ステータス_出荷実績計上済
  cv_prf_notice_status       CONSTANT VARCHAR2(30)  := 'XXCOI1_NOTICE_STATUS_CLOSE'; -- XXCOI:通知ステータス_確定通知済
  cv_prf_itou_ou_mfg         CONSTANT VARCHAR2(30)  := 'XXCOI1_ITOE_OU_MFG';         -- XXCOI:生産営業単位取得名称
  cv_prf_dire_out_hht        CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_HHT';        -- XXCOI:HHT_OUTBOUND格納ディレクトリパス
  cv_prf_file_base_item      CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_BASE_ITEM';      -- XXCOI:拠点品目IF出力ファイル名
  cv_base_code_item_bulk_cnt CONSTANT VARCHAR2(30)  := 'XXCOI1_BASE_CODE_ITEM_BULK_CNT';
                                                                                     -- XXCOI:拠点品目情報取得件数(バルク)
  --
  cv_y                       CONSTANT VARCHAR2(1)   := 'Y';                          -- フラグ値:Y
  cv_n                       CONSTANT VARCHAR2(1)   := 'N';                          -- フラグ値:N
  cv_status_a                CONSTANT VARCHAR2(1)   := 'A';                          -- フラグ値:A
  cv_class_code_1            CONSTANT VARCHAR2(1)   := '1';                          -- 顧客区分:1（拠点）
  cv_shukka_shikyuu_kbn_1    CONSTANT VARCHAR2(1)   := '1';                          -- 出荷支給区分:1
  cv_zaiko_chousei_kbn_1     CONSTANT VARCHAR2(1)   := '1';                          -- 在庫調整区分:1
-- == 2011/09/05 V1.1 Added START    ===============================================================
  cv_dept_hht_div_1          CONSTANT VARCHAR2(1)   := '1';                          -- 百貨店HHT区分:1（拠点複）
-- == 2011/09/05 V1.1 Added END      ===============================================================
  cv_date_mask_1             CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';      -- 日付書式マスク(YYYY/MM/DD HH24:MM:SS)
  cv_date_mask_2             CONSTANT VARCHAR2(10)  := 'YYYYMM';                     -- 日付書式マスク(YYYYMM)
  cv_file_slash              CONSTANT VARCHAR2(1)   := '/';                          -- ファイル区切り用
  cv_csv_com                 CONSTANT VARCHAR2(1)   := ',';                          -- CSVデータ区切り用
  cv_csv_encloser            CONSTANT VARCHAR2(1)   := '"';                          -- CSVデータ括り用
  cv_file_mode_w             CONSTANT VARCHAR2(1)   := 'W';                          -- オープンモード:W
--
  -- ===============================
  -- ユーザー定義グローバル変数
  
  -- ===============================
  gt_org_code                 mtl_parameters.organization_code%TYPE;      -- 在庫組織コード
  gt_org_id                   mtl_parameters.organization_id%TYPE;        -- 在庫組織ID
  gt_ship_status_close        xxwsh_order_headers_all.req_status%TYPE;    -- 出荷依頼ステータス_締め済み
  gt_ship_status_result       xxwsh_order_headers_all.req_status%TYPE;    -- 出荷依頼ステータス_出荷実績計上済
  gt_notice_status            xxwsh_order_headers_all.notif_status%TYPE;  -- 通知ステータス_確定通知済;
  gt_seisan_org_name          hr_organization_units.name%TYPE;            -- 生産営業単位名称
  gt_itou_ou_id               hr_organization_units.organization_id%TYPE; -- 生産組織ID
  gv_dire_name                VARCHAR2(100);                              -- ディレクトリ名称
  gv_dire_out_hht             VARCHAR2(150);                              -- HHT_OUTBOUND格納ディレクトリパス
  gv_file_base_item           VARCHAR2(100);                              -- 拠点品目IF出力ファイル名
  gv_full_path                VARCHAR2(150);                              -- ファイルパス名取得用
  gf_activ_file_h             UTL_FILE.FILE_TYPE;                         -- ファイルハンドル取得用
  gd_process_date             DATE;                                       -- 業務日付
  gd_target_date              DATE;                                       -- 処理対象日
  gv_limit_num                VARCHAR2(100);                              -- バルク用リミット件数(ダミー)
  gn_limit_num                NUMBER;                                     -- バルク用リミット件数
--
  /**********************************************************************************
   * Procedure Name   : get_item_record
   * Description      : 拠点品目取得処理(A-3),拠点品目CSV作成処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_record(
      ov_errbuf      OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode     OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg      OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_record';                   -- プログラム名
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
    lv_base_code_item_csv     VARCHAR2(500);                          -- CSV出力用変数
    lv_sysdate                VARCHAR2(30);                           -- SYSDATE(CSV用)
--
    -- *** ローカル・カーソル ***
    -- 拠点品目情報取得
    CURSOR base_code_item_cur
    IS
      -- 月次在庫受払表(累計)
-- == 2011/09/05 V1.1 Modified START ===============================================================
--      SELECT   xirs.base_code                  base_code              -- 拠点コード
      SELECT   DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, xirs.base_code)
                                               base_code              -- 拠点コード
-- == 2011/09/05 V1.1 Modified END   ===============================================================
             , msib.segment1                   item_no                -- 品目コード
      FROM     xxcoi_inv_reception_sum         xirs                   -- 月次在庫受払表（累計）
             , mtl_system_items_b              msib                   -- Disc品目マスタ
-- == 2011/09/05 V1.1 Added START    ===============================================================
             , hz_cust_accounts                hca                    -- 顧客マスタ
             , xxcmm_cust_accounts             xca                    -- 顧客追加情報マスタ
-- == 2011/09/05 V1.1 Added END      ===============================================================
      WHERE    msib.inventory_item_id = xirs.inventory_item_id
      AND      msib.organization_id   = xirs.organization_id
      AND      xirs.organization_id   = gt_org_id
      AND      xirs.practice_date     = TO_CHAR(gd_target_date, cv_date_mask_2 )
-- == 2011/09/05 V1.1 Added START    ===============================================================
      AND      hca.cust_account_id     = xca.customer_id
      AND      hca.customer_class_code = cv_class_code_1
      AND      hca.account_number      = xirs.base_code
-- == 2011/09/05 V1.1 Added END      ===============================================================
-- == 2011/09/05 V1.1 Modified START ===============================================================
--      GROUP by xirs.base_code
      GROUP by DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, xirs.base_code)
-- == 2011/09/05 V1.1 Modified END   ===============================================================
             , msib.segment1
      --
      UNION
      --
      -- 出荷依頼/実績
-- == 2011/09/05 V1.1 Modified START ===============================================================
--      SELECT  hca.account_number               base_code              -- 拠点コード
      SELECT  DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number)
                                               base_code              -- 拠点コード
-- == 2011/09/05 V1.1 Modified END   ===============================================================
            , imbp.item_no                     item_no                -- 品目コード
      FROM    xxwsh_order_headers_all          xoha                   -- 受注ヘッダアドオン
            , xxwsh_order_lines_all            xola                   -- 受注明細アドオン
            , ic_item_mst_b                    imbc                   -- OPM品目マスタ（子）
            , ic_item_mst_b                    imbp                   -- OPM品目マスタ（親）
            , xxcmn_item_mst_b                 ximb                   -- OPM品目アドオンマスタ
            , mtl_system_items_b               msib                   -- Disc品目マスタ
            , hz_cust_accounts                 hca                    -- 顧客マスタ
-- == 2011/09/05 V1.1 Added START    ===============================================================
            , xxcmm_cust_accounts              xca                    -- 顧客追加情報マスタ
-- == 2011/09/05 V1.1 Added END      ===============================================================
            , oe_transaction_types_all         otta                   -- 受注タイプマスタ
            , hz_party_sites                   hps                    -- パーティサイトマスタ
      WHERE  xoha.order_header_id   =   xola.order_header_id
      AND    xola.request_item_id   =   msib.inventory_item_id
      AND    imbc.item_no           =   msib.segment1
      AND    imbc.item_id           =   ximb.item_id
      AND    imbp.item_id           =   ximb.parent_item_id
      AND    msib.organization_id   =   gt_org_id
      AND ( (  -- 締め済み、確定通知済出荷依頼
                  xoha.req_status            = gt_ship_status_close
              AND xoha.notif_status          = gt_notice_status
              AND xoha.schedule_arrival_date = gd_target_date + 1
              AND xoha.deliver_to_id         = hps.party_site_id
              AND 
              xoha.schedule_arrival_date BETWEEN ximb.start_date_active
                                         AND     NVL(ximb.end_date_active, xoha.schedule_arrival_date )
            )
         OR (  -- 出荷実績計上済出荷実績
                  xoha.req_status            = gt_ship_status_result
              AND xoha.actual_confirm_class  = cv_y
              AND xoha.arrival_date          = gd_target_date + 1
              AND xoha.result_deliver_to_id  = hps.party_site_id
              AND
              xoha.arrival_date BETWEEN ximb.start_date_active
                                         AND     NVL(ximb.end_date_active, xoha.arrival_date )
            ) )
      AND     NVL(xola.delete_flag, cv_n ) = cv_n
      AND     otta.attribute1              = cv_shukka_shikyuu_kbn_1
      AND     NVL(otta.attribute4, cv_zaiko_chousei_kbn_1 ) = cv_zaiko_chousei_kbn_1
      AND     hps.party_id                 = hca.party_id
      AND     otta.org_id                  = gt_itou_ou_id 
      AND     xoha.order_type_id           = otta.transaction_type_id
      AND     hca.customer_class_code      = cv_class_code_1
      AND     hca.status                   = cv_status_a
      AND     xoha.latest_external_flag    = cv_y
-- == 2011/09/05 V1.1 Added START    ===============================================================
      AND     hca.cust_account_id          = xca.customer_id
-- == 2011/09/05 V1.1 Added END      ===============================================================
-- == 2011/09/05 V1.1 Modified START ===============================================================
--      GROUP BY hca.account_number
      GROUP BY DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number)
-- == 2011/09/05 V1.1 Modified END   ===============================================================
             , imbp.item_no
      ORDER BY base_code
             , item_no;
--
    -- *** ローカル・レコード ***
    --
    TYPE l_base_code_item_ttype IS TABLE OF base_code_item_cur%ROWTYPE INDEX BY PLS_INTEGER;
    l_base_code_item_tab        l_base_code_item_ttype;
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
    -- SYSDATE(CSV用)変数にSYSDATEを設定する
    lv_sysdate := TO_CHAR(SYSDATE, cv_date_mask_1 );
    --
    -- CSV出力用変数を初期化
    lv_base_code_item_csv := NULL;
    --
    -- 拠点品目情報カーソルオープン
    OPEN base_code_item_cur;
    --
    LOOP
      --
      EXIT WHEN base_code_item_cur%NOTFOUND;
      --
      --テーブル変数の初期化
      l_base_code_item_tab.DELETE;
      --
      --レコード読み込み
      FETCH base_code_item_cur BULK COLLECT INTO l_base_code_item_tab LIMIT gn_limit_num;
      --
      --ループの開始
      <<base_code_item_loop>>
      FOR ln_index IN 1..l_base_code_item_tab.COUNT LOOP
        -- ===============================
        -- A-4.拠点品目CSV作成処理
        -- ===============================
        --
        -- 対象件数取得
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- カーソルで取得した値をCSVファイルに格納
        lv_base_code_item_csv :=                cv_csv_encloser || l_base_code_item_tab( ln_index ).base_code || cv_csv_encloser ||
                                 cv_csv_com ||  cv_csv_encloser || l_base_code_item_tab( ln_index ).item_no   || cv_csv_encloser ||
                                 cv_csv_com ||  cv_csv_encloser || lv_sysdate                                 || cv_csv_encloser;
        --
        -- CSVファイルを出力
        UTL_FILE.PUT_LINE(
            gf_activ_file_h       -- ファイルハンドル
          , lv_base_code_item_csv -- CSV出力項目
          );
        --
        -- 正常件数に加算
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      --ループの終了
      END LOOP base_code_item_loop;
    --
    END LOOP;
    --
    --カーソルのクローズ
    CLOSE base_code_item_cur;
    --
    -- 対象データが0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      --
      -- 対象データ無しメッセージ
      gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                      , iv_name         => cv_not_found_data_msg
                      );
      --
      -- 空行を出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => NULL
      );
      --
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
    --
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
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
  END get_item_record;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_target_date IN  VARCHAR2      --   処理対象日
    , ov_errbuf      OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode     OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg      OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                   -- プログラム名
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
    lv_para_msg               VARCHAR2(1000);                         -- メッセージ用
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
    --==================================
    -- 各変数の初期化
    --==================================
    gt_org_code           := NULL;
    gt_seisan_org_name    := NULL;
    gv_dire_out_hht       := NULL;
    gt_ship_status_close  := NULL;
    gt_ship_status_result := NULL;
    gt_notice_status      := NULL;
    gt_itou_ou_id         := NULL;
    gt_org_id             := NULL;
    gd_process_date       := NULL;
--
    --
    --==================================
    -- 業務日付取得
    --==================================
    -- 共通関数より、業務日付を取得します。
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    --
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_name
                        , iv_name        => cv_process_date_expt_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==================================
    -- パラメータ出力
    --==================================
    IF ( iv_target_date IS NOT NULL ) THEN
      --入力パラメータ「処理対象日」が設定されている場合、入力パラメータ「処理対象日」をメッセージ出力
      lv_para_msg  :=  xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_xxcos_appl_short_name
                          , iv_name          =>  cv_msg_parameter_note
                          , iv_token_name1   =>  cv_tkn_para_date
                          , iv_token_value1  =>  iv_target_date  -- 処理対象日
                         );
      -- 空行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      --
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.OUTPUT
        ,buff   =>  lv_para_msg
      );
      --
      BEGIN
        -- 入力パラメータ「処理対象日」を処理対象日とする。
        gd_target_date := TO_DATE(iv_target_date , cv_date_mask_1);
      EXCEPTION
        WHEN OTHERS THEN
          -- 日付型に変換できなかった場合は、日付パラメータエラーとする。
          lv_errmsg   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_xxcos_appl_short_name
                          , iv_name         => cv_date_err_msg
                         );
          lv_errbuf   := lv_errmsg;
          --
          RAISE global_api_expt;
      END;
      --
      -- 入力パラメータ「処理対象日」が業務日付より未来日の場合
      IF (TO_DATE(iv_target_date, cv_date_mask_1 ) > gd_process_date) THEN
        lv_errbuf   :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_xxcos_appl_short_name
                          , iv_name         => cv_future_date_err_msg
                        );
        lv_errmsg   :=  lv_errbuf;
        RAISE global_api_expt;
      END IF;
    --
    ELSE
      -- 入力パラメータ「処理対象日」が設定されていない場合、コンカレント入力パラメータなしメッセージを出力
      gv_out_msg   :=  xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_application
                          , iv_name          =>  cv_conc_not_parm_msg
                          );
      --
      -- 空行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      --
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.OUTPUT
        ,buff   =>  gv_out_msg
      );
      --
      -- 業務日付を処理対象日とします。
      gd_target_date := gd_process_date;
    END IF;
--
    --==============================================================
    --プロファイルより在庫組織コード取得
    --==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    -- プロファイルが取得できない場合
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_org_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより生産営業単位名称取得
    --==============================================================
    gt_seisan_org_name := fnd_profile.value( cv_prf_itou_ou_mfg );
    -- プロファイルが取得できない場合
    IF ( gt_seisan_org_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_itou_ou_mfg_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_itou_ou_mfg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルよりHHT_OUTBOUND格納ディレクトリパス取得
    --==============================================================
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- プロファイルが取得できない場合
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_dire_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより拠点品目IF出力ファイル名取得
    --==============================================================
    gv_file_base_item := fnd_profile.value( cv_prf_file_base_item );
    -- プロファイルが取得できない場合
    IF ( gv_file_base_item IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_file_name_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_file_base_item
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより出荷依頼ステータス_締め済み取得
    --==============================================================
    gt_ship_status_close := fnd_profile.value( cv_prf_ship_status_close );
    -- プロファイルが取得できない場合
    IF ( gt_ship_status_close IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_close
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより出荷依頼ステータス_出荷実績計上済取得
    --==============================================================
    gt_ship_status_result := fnd_profile.value( cv_prf_ship_status_result );
    -- プロファイルが取得できない場合
    IF ( gt_ship_status_result IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_result
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより通知ステータス_確定通知済取得
    --==============================================================
    gt_notice_status := fnd_profile.value( cv_prf_notice_status );
    -- プロファイルが取得できない場合
    IF ( gt_notice_status IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_notice_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_notice_status
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより拠点品目情報取得件数(バルク)取得
    --==============================================================
    gv_limit_num := fnd_profile.value( cv_base_code_item_bulk_cnt );
    --
    -- プロファイルが取得できない場合
    IF ( gv_limit_num IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_bulk_cnt_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_base_code_item_bulk_cnt
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      --
      -- 数値型に変換
      gn_limit_num := TO_NUMBER( gv_limit_num );
    --
    EXCEPTION
      WHEN OTHERS THEN
        --
        -- 数値型に変換できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_appl_short_name
                       , iv_name         => cv_bulk_cnt_err_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_base_code_item_bulk_cnt
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --共通関数より在庫組織ID取得
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_org_id_err_msg
                     , iv_token_name1  => cv_tkn_org
                     , iv_token_value1 => gt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --生産営業単位名称より生産組織ID取得
    --==============================================================
    BEGIN
      SELECT hou.organization_id   organization_id
      INTO   gt_itou_ou_id 
      FROM   hr_organization_units hou
      WHERE  hou.name = gt_seisan_org_name;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_itou_ou_mfg_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_itou_ou_mfg
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --ディレクトリを取得
    --==============================================================
    BEGIN
      SELECT ad.directory_path   directory_path
      INTO   gv_dire_out_hht
      FROM   all_directories     ad   -- ディレクトリ情報
      WHERE  directory_name = gv_dire_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ディレクトリフルパス取得エラーメッセージ
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_appl_short_name
                        , iv_name         => cv_full_path_err_msg
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_api_expt;
    END;
    --
    -- IFファイル名（IFファイルのフルパス情報）を出力
    -- 'ディレクトリパス'と'/'と‘ファイル名'を結合
    gv_full_path  := gv_dire_out_hht || cv_file_slash || gv_file_base_item;
    --
    --ファイル名出力メッセージ
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_file_name_msg
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_full_path
                    );
    --
    -- 1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
    --
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_target_date    IN  VARCHAR2      --  処理日付
    , ov_errbuf         OUT VARCHAR2      --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2      --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2      --  ユーザー・エラー・メッセージ --# 固定 #
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
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767; -- ファイルサイズ
--
    -- *** ローカル変数 ***
    -- ファイルの存在チェック用変数
    lb_exists       BOOLEAN         DEFAULT NULL;       -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;       -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;       -- ブロックサイズ
    lv_message_code VARCHAR2(100);                      -- 終了メッセージコード
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル例外       ***
    remain_file_expt           EXCEPTION;
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
        iv_target_date                                  -- 処理対象日
      , lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
      , lv_retcode                                      -- リターン・コード             --# 固定 #
      , lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.ファイルのオープン処理
    -- ========================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_name
      , filename     =>  gv_file_base_item
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    --
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
    --
    ELSE
      -- ファイルオープン処理実行
      gf_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_name        -- ディレクトリパス
                          , filename     => gv_file_base_item      -- ファイル名
                          , open_mode    => cv_file_mode_w         -- オープンモード
                          , max_linesize => cn_max_linesize        -- ファイルサイズ
                         );
    END IF;
--
    -- ========================================
    -- A-3.拠点品目取得処理,A-4.拠点品目CSV作成処理
    -- ========================================
    get_item_record(
        lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
      , lv_retcode                                      -- リターン・コード             --# 固定 #
      , lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-5.終了処理
    -- ========================================
    --
    -- ファイルのクローズ処理
    UTL_FILE.FCLOSE(
      file => gf_activ_file_h
      );
--
  EXCEPTION
    -- ファイル存在チェックエラー
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_appl_short_name
                        , iv_name         => cv_prf_no_file_msg
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_full_path
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
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
      errbuf          OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    , retcode         OUT VARCHAR2       --   リターン・コード    --# 固定 #
    , iv_target_date  IN  VARCHAR2       --   【任意】処理対象日
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        iv_target_date      --  【任意】処理対象日
      , lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , lv_retcode          --  リターン・コード             --# 固定 #
      , lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    -- エラー時は成功件数出力を0にセット
    --           エラー件数出力を1にセット
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      fnd_file.put_line(
          which => fnd_file.output
        , buff  => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
          which => fnd_file.log
        , buff  => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                    , iv_name        => lv_message_code
                   );
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => gv_out_msg
    );
    --
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI010A04C;
/
