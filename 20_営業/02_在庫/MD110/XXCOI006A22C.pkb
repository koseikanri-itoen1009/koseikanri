CREATE OR REPLACE PACKAGE BODY XXCOI006A22C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A22C(body)
 * Description      : 資材取引を元に、VD受払情報を作成します。
 * MD.050           : VD受払データ作成<MD050_COI_006_A22>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  finalize               終了処理                   (A-7)
 *  set_cooperation_data   処理済取引ID更新           (A-6)
 *  set_last_month_data    前月VD受払データ処理       (A-4, A-5)
 *  set_vd_reception_info  当日データVD受払情報出力   (A-2, A-3)
 *  init                   初期処理                   (A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/06    1.0   H.Sasaki         初版作成
 *  2009/07/31    1.1   N.Abe            [0000638]単位の取得項目修正
 *  2009/11/11    1.2   N.Abe            [E_最終移行リハ_00539]前月VD受払抽出SQLの修正
 *  2009/11/14    1.3   H.Sasaki         [E_最終移行リハ_00539]前月VD受払抽出SQLの修正
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
  zero_data_expt            EXCEPTION;
  lock_error_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A22C'; -- パッケージ名
  -- メッセージ関連
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00005   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';         -- 在庫組織コード取得エラーメッセージ
  cv_msg_xxcoi1_00006   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';         -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';         -- 業務処理日付取得エラー
  cv_msg_xxcoi1_10127   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10127';         -- 最大取引ID取得エラーメッセージ
  cv_msg_xxcoi1_10285   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10285';         -- 標準原価取得失敗エラーメッセージ
  cv_msg_xxcoi1_10293   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10293';         -- 営業原価取得失敗エラーメッセージ
  cv_msg_xxcoi1_10365   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10365';         -- コンカレント入力パラメータ
  cv_msg_xxcoi1_10366   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10366';         -- VD受払情報ロックエラーメッセージ
  cv_msg_xxcoi1_10367   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10367';         -- 起動フラグ名取得エラーメッセージ
  cv_token_00005_1      CONSTANT VARCHAR2(30) :=  'PRO_TOK';
  cv_token_00006_1      CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';
  cv_token_10365_1      CONSTANT VARCHAR2(30) :=  'EXEC_FLAG';
  cv_token_10367_1      CONSTANT VARCHAR2(30) :=  'LOOKUP_TYPE';
  cv_token_10367_2      CONSTANT VARCHAR2(30) :=  'LOOKUP_CODE';
  -- 受払集計キー（取引タイプ）
  cv_trans_type_160     CONSTANT VARCHAR2(3)  :=  '160';                      -- 基準在庫変更
  cv_trans_type_300     CONSTANT VARCHAR2(3)  :=  '300';                      -- 拠点分割VD在庫振替
  -- 保管場所分類
  cv_subinv_class_6     CONSTANT VARCHAR2(1)  :=  '6';                        -- 自販機（フル）
  cv_subinv_class_7     CONSTANT VARCHAR2(1)  :=  '7';                        -- 自販機（消化）
  -- 業態（小分類）
  cv_low_type_24        CONSTANT VARCHAR2(2)  :=  '24';                       -- フル（消化）VD
  cv_low_type_25        CONSTANT VARCHAR2(2)  :=  '25';                       -- フルVD
  cv_low_type_27        CONSTANT VARCHAR2(2)  :=  '27';                       -- 消化VD
  -- 参照表タイプ
  cv_lookup_type        CONSTANT VARCHAR2(30) :=  'XXCOI1_EXEC_FLAG_NAME';    -- 起動フラグ名称
  -- プロファイル
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE'; -- プロファイル名（在庫組織コード）
  -- その他
  cn_control_id         CONSTANT NUMBER       :=  60;
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
  cv_yes                CONSTANT VARCHAR2(1)  :=  'Y';
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';
  cv_pgsname_a22c       CONSTANT VARCHAR2(30) :=  'XXCOI006A22C';
  cv_exec_flag_2        CONSTANT VARCHAR2(1)  :=  '2';                        -- 起動フラグ２（月次起動）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE quantity_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_quantity           quantity_type;      -- 取引タイプ別数量
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_param_exec_flag          VARCHAR2(1);        -- 起動フラグ
  -- 初期処理設定値
  gd_f_process_date           DATE;               -- 業務処理日付
  gv_f_last_month             VARCHAR2(6);        -- 業務処理日付（前月）
  gv_f_organization_code      VARCHAR2(10);       -- 在庫組織コード
  gn_f_organization_id        NUMBER;             -- 在庫組織ID
  gv_f_inv_acct_period        VARCHAR2(6);        -- 在庫会計期間（年月 YYYYMM）
  gn_f_last_transaction_id    NUMBER;             -- 処理済取引ID
  gd_f_last_cooperation_date  DATE;               -- 処理日
  gn_f_max_transaction_id     NUMBER;             -- 最大取引ID
--
--
  /**********************************************************************************
   * Procedure Name   : finalize
   * Description      : 終了処理(A-7)
   ***********************************************************************************/
  PROCEDURE finalize(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'finalize'; -- プログラム名
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
    --  1.処理件数設定
    -- ===================================
    -- 対象件数設定
    SELECT  COUNT(1)
    INTO    gn_target_cnt
    FROM    xxcoi_vd_reception_info
    WHERE   request_id  = cn_request_id;
    --
    -- 成功件数設定
    gn_normal_cnt := gn_target_cnt;
    --
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END finalize;
--
  /**********************************************************************************
   * Procedure Name   : set_cooperation_data
   * Description      : 処理済取引ID更新(A-6)
   ***********************************************************************************/
  PROCEDURE set_cooperation_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_cooperation_data'; -- プログラム名
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
    --  1.データ連携制御情報作成
    -- ===================================
    IF (gn_f_last_transaction_id = 0) THEN
      -- データ連携制御情報が存在しない場合
      INSERT INTO xxcoi_cooperation_control(
        control_id                      -- 01.制御ID
       ,last_cooperation_date           -- 02.最終連携日時
       ,transaction_id                  -- 03.取引ID
       ,program_short_name              -- 04.プログラム略称
       ,last_update_date                -- 05.最終更新日
       ,last_updated_by                 -- 06.最終更新者
       ,creation_date                   -- 07.作成日
       ,created_by                      -- 08.作成者
       ,last_update_login               -- 09.最終更新ユーザ
       ,request_id                      -- 10.要求ID
       ,program_application_id          -- 11.プログラムアプリケーションID
       ,program_id                      -- 12.プログラムID
       ,program_update_date             -- 13.プログラム更新日
      )VALUES(
        cn_control_id                   -- 01
       ,gd_f_process_date               -- 02
       ,gn_f_max_transaction_id         -- 03
       ,cv_pgsname_a22c                 -- 04
       ,SYSDATE                         -- 05
       ,cn_last_updated_by              -- 06
       ,SYSDATE                         -- 07
       ,cn_created_by                   -- 08
       ,cn_last_update_login            -- 09
       ,cn_request_id                   -- 10
       ,cn_program_application_id       -- 11
       ,cn_program_id                   -- 12
       ,SYSDATE                         -- 13
      );
      --
    ELSE
      -- データ連携制御情報が存在する場合
      UPDATE  xxcoi_cooperation_control
      SET     last_cooperation_date   = gd_f_process_date           -- 02.最終連携日時
             ,transaction_id          = gn_f_max_transaction_id     -- 03.取引ID
             ,last_update_date        = SYSDATE                     -- 05.最終更新日
             ,last_updated_by         = cn_last_updated_by          -- 06.最終更新者
             ,last_update_login       = cn_last_update_login        -- 09.最終更新ユーザ
             ,request_id              = cn_request_id               -- 10.要求ID
             ,program_application_id  = cn_program_application_id   -- 11.プログラムアプリケーションID
             ,program_id              = cn_program_id               -- 12.プログラムID
             ,program_update_date     = SYSDATE                     -- 13.プログラム更新日
      WHERE   control_id    =   cn_control_id;
      --
    END IF;
    --
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END set_cooperation_data;
--
  /**********************************************************************************
   * Procedure Name   : set_last_month_data
   * Description      : 前月VD受払データ処理(A-4, A-5)
   ***********************************************************************************/
  PROCEDURE set_last_month_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_last_month_data'; -- プログラム名
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
    lt_standard_cost        xxcoi_vd_reception_info.standard_cost%TYPE;       -- 標準原価
    lt_operation_cost       xxcoi_vd_reception_info.operation_cost%TYPE;      -- 営業原価
    ln_dummy                NUMBER;                                           -- ダミー変数
--
    -- *** ローカル・カーソル ***
-- == 2009/11/14 V1.3 Modified START ===============================================================
--    CURSOR  vd_column_cur
--    IS
--      SELECT  xvri_lm.base_code                     base_code                       -- 拠点コード（前月）
--             ,xvri_lm.practice_date                 practice_date                   -- 年月
--             ,xvri_lm.inventory_item_id             inventory_item_id               -- 品目ID
--             ,xvri_lm.month_begin_quantity          month_begin_quantity            -- 月首在庫
--             ,  xvri_lm.vd_stock
--              + xvri_lm.vd_move_stock
--              - xvri_lm.vd_ship
--              - xvri_lm.vd_move_ship                vd_total_quantity               -- VD入出庫合計
--             ,xvri_tm.base_code                     this_month_base_code            -- 拠点コード（当月）
---- == 2009/11/11 V1.2 Modified START ===============================================================
----             ,vcm.last_month_inventory_quantity     last_month_inventory_quantity   -- 前月末基準在庫数
--             ,NVL(vcm.last_month_inventory_quantity, 0)
--                                                    last_month_inventory_quantity   -- 前月末基準在庫数
---- == 2009/11/11 V1.2 Modified END   ===============================================================
--      FROM    xxcoi_vd_reception_info   xvri_lm                                     -- VD受払情報（前月）
--             ,xxcoi_vd_reception_info   xvri_tm                                     -- VD受払情報（当月）
--             ,(SELECT   xca.past_sale_base_code                   base_code                         -- 前月売上拠点コード
--                       ,xmvc.last_month_item_id                   inventory_item_id                 -- 前月末品目ID
--                       ,SUM(xmvc.last_month_inventory_quantity)   last_month_inventory_quantity     -- 前月末基準在庫数
--               FROM     xxcoi_mst_vd_column     xmvc                                                -- VDコラムマスタ
--                       ,xxcmm_cust_accounts     xca                                                 -- 顧客追加情報
--               WHERE    xmvc.customer_id      =   xca.customer_id
--               AND      xca.business_low_type IN(cv_low_type_24, cv_low_type_25, cv_low_type_27)
--               GROUP BY xca.past_sale_base_code
--                       ,xmvc.last_month_item_id
--              )                         vcm                                         -- コラムマスタ情報
--      WHERE   xvri_lm.base_code           =   xvri_tm.base_code(+)
--      AND     xvri_lm.inventory_item_id   =   xvri_tm.inventory_item_id(+)
--      AND     xvri_lm.practice_date       =   gv_f_last_month
--      AND     xvri_tm.practice_date(+)    =   TO_CHAR(gd_f_process_date, cv_month)
---- == 2009/11/11 V1.2 Modified START ===============================================================
----      AND     xvri_lm.base_code           =   vcm.base_code
----      AND     xvri_lm.inventory_item_id   =   vcm.inventory_item_id;
--      AND     xvri_lm.base_code           =   vcm.base_code(+)
--      AND     xvri_lm.inventory_item_id   =   vcm.inventory_item_id(+);
---- == 2009/11/11 V1.2 Modified START ===============================================================
    CURSOR  vd_recp_cur
    IS
      SELECT  1
      FROM    xxcoi_vd_reception_info     xvri
      WHERE   xvri.practice_date          =   gv_f_last_month
      FOR UPDATE NOWAIT;
    --
    --
    CURSOR  vd_column_cur
    IS
      SELECT   xca.past_sale_base_code                    base_code                         -- 前月売上拠点コード
              ,xmvc.last_month_item_id                    inventory_item_id                 -- 前月末品目ID
              ,SUM(xmvc.last_month_inventory_quantity)    last_month_inventory_quantity     -- 前月末基準在庫数
      FROM     xxcoi_mst_vd_column      xmvc                                                -- VDコラムマスタ
              ,xxcmm_cust_accounts      xca                                                 -- 顧客追加情報
      WHERE    xmvc.customer_id       = xca.customer_id
      AND      xca.business_low_type  IN(cv_low_type_24, cv_low_type_25, cv_low_type_27)
      GROUP BY xca.past_sale_base_code
              ,xmvc.last_month_item_id;
-- == 2009/11/14 V1.3 Modified END   ===============================================================
--
    -- *** ローカル・レコード ***
    vd_column_rec   vd_column_cur%ROWTYPE;
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
-- == 2009/11/14 V1.3 Modified START ===============================================================
--    -- ===================================
--    --  1.前月VD受払データ追加（当月）
--    -- ===================================
--    --
--    <<set_vd_column_loop>>
--    FOR vd_column_rec IN vd_column_cur LOOP
--      IF (vd_column_rec.last_month_inventory_quantity = 0) THEN
--        -- 前月末基準在庫数が０の場合、登録を行わない
--        NULL;
--        --
--      ELSIF (vd_column_rec.this_month_base_code IS NULL) THEN
--        -- 当月分のVD受払情報が存在しない場合
--        
--        -- ===================================
--        --  標準原価取得
--        -- ===================================
--        xxcoi_common_pkg.get_cmpnt_cost(
--          in_item_id      =>  vd_column_rec.inventory_item_id                 -- 品目ID
--         ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
--         ,id_period_date  =>  gd_f_process_date                               -- 対象日
--         ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
--         ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
--         ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
--         ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
--        );
--        -- 終了パラメータ判定
--        IF (lt_standard_cost IS NULL) THEN
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10285
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
--        --
--        -- ===================================
--        --  営業原価取得
--        -- ===================================
--        xxcoi_common_pkg.get_discrete_cost(
--          in_item_id        =>  vd_column_rec.inventory_item_id                 -- 品目ID
--         ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
--         ,id_target_date    =>  gd_f_process_date                               -- 対象日
--         ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
--         ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
--         ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
--         ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
--        );
--        -- 終了パラメータ判定
--        IF (lt_operation_cost IS NULL) THEN
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10293
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
--        --
--        INSERT INTO xxcoi_vd_reception_info(
--          base_code                                     -- 01.拠点コード
--         ,organization_id                               -- 02.組織ID
--         ,practice_date                                 -- 03.年月
--         ,inventory_item_id                             -- 04.品目ID
--         ,operation_cost                                -- 05.営業原価
--         ,standard_cost                                 -- 06.標準原価
--         ,month_begin_quantity                          -- 07.月首在庫
--         ,vd_stock                                      -- 08.ベンダ入庫
--         ,vd_move_stock                                 -- 09.ベンダ-移動入庫
--         ,vd_ship                                       -- 10.ベンダ出庫
--         ,vd_move_ship                                  -- 11.ベンダ-移動出庫
--         ,month_end_book_remain_qty                     -- 12.月末帳簿残
--         ,month_end_quantity                            -- 13.月末在庫
--         ,inv_wear_account                              -- 14.棚卸減耗費
--         ,created_by                                    -- 15.作成者
--         ,creation_date                                 -- 16.作成日
--         ,last_updated_by                               -- 17.最終更新者
--         ,last_update_date                              -- 18.最終更新日
--         ,last_update_login                             -- 19.最終更新ログイン
--         ,request_id                                    -- 20.要求ID
--         ,program_application_id                        -- 21.コンカレント・プログラム・アプリケーションID
--         ,program_id                                    -- 22.コンカレント・プログラムID
--         ,program_update_date                           -- 23.プログラム更新日
--        )VALUES(
--          vd_column_rec.base_code                       -- 01
--         ,gn_f_organization_id                          -- 02
--         ,TO_CHAR(gd_f_process_date, cv_month)          -- 03
--         ,vd_column_rec.inventory_item_id               -- 04
--         ,lt_operation_cost                             -- 05
--         ,lt_standard_cost                              -- 06
--         ,vd_column_rec.last_month_inventory_quantity   -- 07
--         ,0                                             -- 08
--         ,0                                             -- 09
--         ,0                                             -- 10
--         ,0                                             -- 11
--         ,0                                             -- 12
--         ,0                                             -- 13
--         ,0                                             -- 14
--         ,cn_created_by                                 -- 15
--         ,SYSDATE                                       -- 16
--         ,cn_last_updated_by                            -- 17
--         ,SYSDATE                                       -- 18
--         ,cn_last_update_login                          -- 19
--         ,cn_request_id                                 -- 20
--         ,cn_program_application_id                     -- 21
--         ,cn_program_id                                 -- 22
--         ,SYSDATE                                       -- 23
--        );
--        --
--      ELSE
--        -- 当月分のVD受払情報が存在する場合
--        BEGIN
--          -- ロック取得
--          SELECT  1
--          INTO    ln_dummy
--          FROM    xxcoi_vd_reception_info
--          WHERE   base_code           = vd_column_rec.base_code
--          AND     practice_date       = TO_CHAR(gd_f_process_date, cv_month)
--          AND     inventory_item_id   = vd_column_rec.inventory_item_id
--          FOR UPDATE NOWAIT;
--          --
--        EXCEPTION
--          WHEN  lock_error_expt THEN
--            -- VD受払情報ロックエラーメッセージ
--            lv_errmsg   :=  xxccp_common_pkg.get_msg(
--                              iv_application  => cv_short_name
--                             ,iv_name         => cv_msg_xxcoi1_10366
--                            );
--            lv_errbuf   :=  lv_errmsg;
--            RAISE global_process_expt;
--            --
--        END;
--        --
--        UPDATE  xxcoi_vd_reception_info
--        SET     month_begin_quantity    = month_begin_quantity  +  vd_column_rec.last_month_inventory_quantity
--                                                                              -- 07.月首在庫
--               ,last_updated_by         = cn_last_updated_by                  -- 17.最終更新者
--               ,last_update_date        = SYSDATE                             -- 18.最終更新日
--               ,last_update_login       = cn_last_update_login                -- 19.最終更新ログイン
--               ,request_id              = cn_request_id                       -- 20.要求ID
--               ,program_application_id  = cn_program_application_id           -- 21.コンカレント・プログラム・アプリケーションID
--               ,program_id              = cn_program_id                       -- 22.コンカレント・プログラムID
--               ,program_update_date     = SYSDATE                             -- 23.プログラム更新日
--        WHERE   base_code               = vd_column_rec.base_code
--        AND     practice_date           = TO_CHAR(gd_f_process_date, cv_month)
--        AND     inventory_item_id       = vd_column_rec.inventory_item_id;
--        --
--      END IF;
--      --
--      -- ===================================
--      --  2.前月VD受払データ確定
--      -- ===================================
--      BEGIN
--        -- ロック取得
--        SELECT  1
--        INTO    ln_dummy
--        FROM    xxcoi_vd_reception_info
--        WHERE   base_code           = vd_column_rec.base_code
--        AND     practice_date       = gv_f_last_month
--        AND     inventory_item_id   = vd_column_rec.inventory_item_id
--        FOR UPDATE NOWAIT;
--        --
--      EXCEPTION
--        WHEN  lock_error_expt THEN
--          -- VD受払情報ロックエラーメッセージ
--          lv_errmsg   :=  xxccp_common_pkg.get_msg(
--                            iv_application  => cv_short_name
--                           ,iv_name         => cv_msg_xxcoi1_10366
--                          );
--          lv_errbuf   :=  lv_errmsg;
--          RAISE global_process_expt;
--          --
--      END;
--      --
--      UPDATE  xxcoi_vd_reception_info
--      SET     month_end_book_remain_qty =  month_end_book_remain_qty
--                                         + vd_column_rec.month_begin_quantity
--                                         + vd_column_rec.vd_total_quantity                  -- 12.月末帳簿残
--             ,month_end_quantity        =  vd_column_rec.last_month_inventory_quantity      -- 13.月末在庫
--             ,inv_wear_account          =  vd_column_rec.month_begin_quantity
--                                         + vd_column_rec.vd_total_quantity
--                                         - vd_column_rec.last_month_inventory_quantity      -- 14.棚卸減耗費
--             ,last_updated_by           =  cn_last_updated_by                               -- 17.最終更新者
--             ,last_update_date          =  SYSDATE                                          -- 18.最終更新日
--             ,last_update_login         =  cn_last_update_login                             -- 19.最終更新ログイン
--             ,request_id                =  cn_request_id                                    -- 20.要求ID
--             ,program_application_id    =  cn_program_application_id                        -- 21.コンカレント・プログラム・アプリケーションID
--             ,program_id                =  cn_program_id                                    -- 22.コンカレント・プログラムID
--             ,program_update_date       =  SYSDATE                                          -- 23.プログラム更新日
--      WHERE   base_code           = vd_column_rec.base_code
--      AND     practice_date       = gv_f_last_month
--      AND     inventory_item_id   = vd_column_rec.inventory_item_id;
--      --
--    END LOOP set_vd_column_loop;
    -- ===================================
    --  月末帳簿残確定
    -- ===================================
    -- 対象データロック処理
    OPEN  vd_recp_cur;
    CLOSE vd_recp_cur;
    --
    -- 帳簿残、棚卸減耗算出
    UPDATE  xxcoi_vd_reception_info
    SET     month_end_book_remain_qty =  month_end_book_remain_qty
                                       + month_begin_quantity
                                       + vd_stock
                                       + vd_move_stock
                                       - vd_ship
                                       - vd_move_ship                           -- 12.月末帳簿残
           ,inv_wear_account          =  month_begin_quantity
                                       + vd_stock
                                       + vd_move_stock
                                       - vd_ship
                                       - vd_move_ship                           -- 14.棚卸減耗費
           ,last_updated_by           =  cn_last_updated_by                     -- 17.最終更新者
           ,last_update_date          =  SYSDATE                                -- 18.最終更新日
           ,last_update_login         =  cn_last_update_login                   -- 19.最終更新ログイン
           ,request_id                =  cn_request_id                          -- 20.要求ID
           ,program_application_id    =  cn_program_application_id              -- 21.コンカレント・プログラム・アプリケーションID
           ,program_id                =  cn_program_id                          -- 22.コンカレント・プログラムID
           ,program_update_date       =  SYSDATE                                -- 23.プログラム更新日
    WHERE   practice_date         =   gv_f_last_month;
    --
    <<set_inv_qty_loop>>
    FOR vd_column_rec IN vd_column_cur LOOP
      IF( vd_column_rec.last_month_inventory_quantity <> 0) THEN
        -- ===================================
        --  月末在庫確定
        -- ===================================
        BEGIN
          SELECT  1
          INTO    ln_dummy
          FROM    xxcoi_vd_reception_info   xvri
          WHERE   xvri.base_code            =   vd_column_rec.base_code
          AND     xvri.inventory_item_id    =   vd_column_rec.inventory_item_id
          AND     xvri.practice_date        =   gv_f_last_month
          AND     ROWNUM  = 1;
          --
          -- -----------------------------------
          --  月末在庫確定
          -- -----------------------------------
          UPDATE  xxcoi_vd_reception_info
          SET     month_end_quantity        =   vd_column_rec.last_month_inventory_quantity     -- 13.月末在庫
                 ,inv_wear_account          =   inv_wear_account
                                              - vd_column_rec.last_month_inventory_quantity     -- 14.棚卸減耗費
                 ,last_updated_by           =  cn_last_updated_by                               -- 17.最終更新者
                 ,last_update_date          =  SYSDATE                                          -- 18.最終更新日
                 ,last_update_login         =  cn_last_update_login                             -- 19.最終更新ログイン
                 ,request_id                =  cn_request_id                                    -- 20.要求ID
                 ,program_application_id    =  cn_program_application_id                        -- 21.コンカレント・プログラム・アプリケーションID
                 ,program_id                =  cn_program_id                                    -- 22.コンカレント・プログラムID
                 ,program_update_date       =  SYSDATE                                          -- 23.プログラム更新日
          WHERE   base_code             =   vd_column_rec.base_code
          AND     inventory_item_id     =   vd_column_rec.inventory_item_id
          AND     practice_date         =   gv_f_last_month;
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- -----------------------------------
            --  標準原価取得
            -- -----------------------------------
            xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id      =>  vd_column_rec.inventory_item_id                 -- 品目ID
             ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
             ,id_period_date  =>  LAST_DAY(TO_DATE(gv_f_last_month, cv_month))    -- 対象日
             ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
             ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
             ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
             ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF (lt_standard_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10285
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            -- -----------------------------------
            --  営業原価取得
            -- -----------------------------------
            xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  vd_column_rec.inventory_item_id                 -- 品目ID
             ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
             ,id_target_date    =>  LAST_DAY(TO_DATE(gv_f_last_month, cv_month))    -- 対象日
             ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
             ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
             ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
             ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF (lt_operation_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10293
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            -- -----------------------------------
            --  月末在庫確定
            -- -----------------------------------
            INSERT INTO xxcoi_vd_reception_info(
              base_code                                         -- 01.拠点コード
             ,organization_id                                   -- 02.組織ID
             ,practice_date                                     -- 03.年月
             ,inventory_item_id                                 -- 04.品目ID
             ,operation_cost                                    -- 05.営業原価
             ,standard_cost                                     -- 06.標準原価
             ,month_begin_quantity                              -- 07.月首在庫
             ,vd_stock                                          -- 08.ベンダ入庫
             ,vd_move_stock                                     -- 09.ベンダ-移動入庫
             ,vd_ship                                           -- 10.ベンダ出庫
             ,vd_move_ship                                      -- 11.ベンダ-移動出庫
             ,month_end_book_remain_qty                         -- 12.月末帳簿残
             ,month_end_quantity                                -- 13.月末在庫
             ,inv_wear_account                                  -- 14.棚卸減耗費
             ,created_by                                        -- 15.作成者
             ,creation_date                                     -- 16.作成日
             ,last_updated_by                                   -- 17.最終更新者
             ,last_update_date                                  -- 18.最終更新日
             ,last_update_login                                 -- 19.最終更新ログイン
             ,request_id                                        -- 20.要求ID
             ,program_application_id                            -- 21.コンカレント・プログラム・アプリケーションID
             ,program_id                                        -- 22.コンカレント・プログラムID
             ,program_update_date                               -- 23.プログラム更新日
            )VALUES(
              vd_column_rec.base_code                           -- 01
             ,gn_f_organization_id                              -- 02
             ,gv_f_last_month                                   -- 03
             ,vd_column_rec.inventory_item_id                   -- 04
             ,lt_operation_cost                                 -- 05
             ,lt_standard_cost                                  -- 06
             ,0                                                 -- 07
             ,0                                                 -- 08
             ,0                                                 -- 09
             ,0                                                 -- 10
             ,0                                                 -- 11
             ,0                                                 -- 12
             ,vd_column_rec.last_month_inventory_quantity       -- 13
             ,vd_column_rec.last_month_inventory_quantity * -1  -- 14
             ,cn_created_by                                     -- 15
             ,SYSDATE                                           -- 16
             ,cn_last_updated_by                                -- 17
             ,SYSDATE                                           -- 18
             ,cn_last_update_login                              -- 19
             ,cn_request_id                                     -- 20
             ,cn_program_application_id                         -- 21
             ,cn_program_id                                     -- 22
             ,SYSDATE                                           -- 23
            );
        END;
        --
        -- ===================================
        --  次月の月首在庫確定
        -- ===================================
        BEGIN
          SELECT  1
          INTO    ln_dummy
          FROM    xxcoi_vd_reception_info   xvri
          WHERE   xvri.base_code            =   vd_column_rec.base_code
          AND     xvri.inventory_item_id    =   vd_column_rec.inventory_item_id
          AND     xvri.practice_date        =   TO_CHAR(gd_f_process_date, cv_month)
          AND     ROWNUM  = 1
          FOR UPDATE NOWAIT;
          --
          -- -----------------------------------
          --  次月の月首在庫確定
          -- -----------------------------------
          UPDATE  xxcoi_vd_reception_info
          SET     month_begin_quantity      =   month_begin_quantity
                                              + vd_column_rec.last_month_inventory_quantity     -- 07.月首在庫
                 ,last_updated_by           =   cn_last_updated_by                              -- 17.最終更新者
                 ,last_update_date          =   SYSDATE                                         -- 18.最終更新日
                 ,last_update_login         =   cn_last_update_login                            -- 19.最終更新ログイン
                 ,request_id                =   cn_request_id                                   -- 20.要求ID
                 ,program_application_id    =   cn_program_application_id                       -- 21.コンカレント・プログラム・アプリケーションID
                 ,program_id                =   cn_program_id                                   -- 22.コンカレント・プログラムID
                 ,program_update_date       =   SYSDATE                                         -- 23.プログラム更新日
          WHERE   base_code             =   vd_column_rec.base_code
          AND     inventory_item_id     =   vd_column_rec.inventory_item_id
          AND     practice_date         =   TO_CHAR(gd_f_process_date, cv_month);
          --
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            -- -----------------------------------
            --  標準原価取得
            -- -----------------------------------
            xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id      =>  vd_column_rec.inventory_item_id           -- 品目ID
             ,in_org_id       =>  gn_f_organization_id                      -- 組織ID
             ,id_period_date  =>  gd_f_process_date                         -- 対象日
             ,ov_cmpnt_cost   =>  lt_standard_cost                          -- 標準原価
             ,ov_errbuf       =>  lv_errbuf                                 -- エラーメッセージ
             ,ov_retcode      =>  lv_retcode                                -- リターン・コード
             ,ov_errmsg       =>  lv_errmsg                                 -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF (lt_standard_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10285
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            -- -----------------------------------
            --  営業原価取得
            -- -----------------------------------
            xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  vd_column_rec.inventory_item_id         -- 品目ID
             ,in_org_id         =>  gn_f_organization_id                    -- 組織ID
             ,id_target_date    =>  gd_f_process_date                       -- 対象日
             ,ov_discrete_cost  =>  lt_operation_cost                       -- 営業原価
             ,ov_errbuf         =>  lv_errbuf                               -- エラーメッセージ
             ,ov_retcode        =>  lv_retcode                              -- リターン・コード
             ,ov_errmsg         =>  lv_errmsg                               -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF (lt_operation_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10293
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            -- -----------------------------------
            --  次月の月首在庫確定
            -- -----------------------------------
            INSERT INTO xxcoi_vd_reception_info(
              base_code                                     -- 01.拠点コード
             ,organization_id                               -- 02.組織ID
             ,practice_date                                 -- 03.年月
             ,inventory_item_id                             -- 04.品目ID
             ,operation_cost                                -- 05.営業原価
             ,standard_cost                                 -- 06.標準原価
             ,month_begin_quantity                          -- 07.月首在庫
             ,vd_stock                                      -- 08.ベンダ入庫
             ,vd_move_stock                                 -- 09.ベンダ-移動入庫
             ,vd_ship                                       -- 10.ベンダ出庫
             ,vd_move_ship                                  -- 11.ベンダ-移動出庫
             ,month_end_book_remain_qty                     -- 12.月末帳簿残
             ,month_end_quantity                            -- 13.月末在庫
             ,inv_wear_account                              -- 14.棚卸減耗費
             ,created_by                                    -- 15.作成者
             ,creation_date                                 -- 16.作成日
             ,last_updated_by                               -- 17.最終更新者
             ,last_update_date                              -- 18.最終更新日
             ,last_update_login                             -- 19.最終更新ログイン
             ,request_id                                    -- 20.要求ID
             ,program_application_id                        -- 21.コンカレント・プログラム・アプリケーションID
             ,program_id                                    -- 22.コンカレント・プログラムID
             ,program_update_date                           -- 23.プログラム更新日
            )VALUES(
              vd_column_rec.base_code                       -- 01
             ,gn_f_organization_id                          -- 02
             ,TO_CHAR(gd_f_process_date, cv_month)          -- 03
             ,vd_column_rec.inventory_item_id               -- 04
             ,lt_operation_cost                             -- 05
             ,lt_standard_cost                              -- 06
             ,vd_column_rec.last_month_inventory_quantity   -- 07
             ,0                                             -- 08
             ,0                                             -- 09
             ,0                                             -- 10
             ,0                                             -- 11
             ,0                                             -- 12
             ,0                                             -- 13
             ,0                                             -- 14
             ,cn_created_by                                 -- 15
             ,SYSDATE                                       -- 16
             ,cn_last_updated_by                            -- 17
             ,SYSDATE                                       -- 18
             ,cn_last_update_login                          -- 19
             ,cn_request_id                                 -- 20
             ,cn_program_application_id                     -- 21
             ,cn_program_id                                 -- 22
             ,SYSDATE                                       -- 23
            );
        END;
      END IF;
    END LOOP  set_inv_qty_loop;
-- == 2009/11/14 V1.3 Modified END   ===============================================================
    --
  EXCEPTION
-- == 2009/11/14 V1.3 Added START ===============================================================
    WHEN  lock_error_expt THEN
      IF (vd_recp_cur%ISOPEN) THEN
        CLOSE vd_recp_cur;
      END IF;
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      -- VD受払情報ロックエラーメッセージ
      ov_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10366
                      );
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  := cv_status_error;
      --
-- == 2009/11/14 V1.3 Added END   ===============================================================
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_last_month_data;
--
  /**********************************************************************************
   * Procedure Name   : set_vd_reception_info
   * Description      : 当日データVD受払情報出力(A-2, A-3)
   ***********************************************************************************/
  PROCEDURE set_vd_reception_info(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_vd_reception_info'; -- プログラム名
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
    lt_base_code            xxcoi_vd_reception_info.base_code%TYPE;           -- 拠点コード
    lt_inventory_item_id    xxcoi_vd_reception_info.inventory_item_id%TYPE;   -- 品目ID
    lt_transaction_date     xxcoi_vd_reception_info.practice_date%TYPE;       -- 年月
    lt_xvri_base_code       xxcoi_vd_reception_info.base_code%TYPE;           -- VD拠点コード
    lt_vd_stock             xxcoi_vd_reception_info.vd_stock%TYPE;            -- ベンダ入庫
    lt_vd_move_stock        xxcoi_vd_reception_info.vd_move_stock%TYPE;       -- ベンダ-移動入庫
    lt_vd_ship              xxcoi_vd_reception_info.vd_ship%TYPE;             -- ベンダ出庫
    lt_vd_move_ship         xxcoi_vd_reception_info.vd_move_ship%TYPE;        -- ベンダ-移動出庫
    lt_standard_cost        xxcoi_vd_reception_info.standard_cost%TYPE;       -- 標準原価
    lt_operation_cost       xxcoi_vd_reception_info.operation_cost%TYPE;      -- 営業原価
    ld_object_date          DATE;                                             -- 原価取得用対象日
    ln_dummy                NUMBER;                                           -- ダミー変数
--
    -- *** ローカル・カーソル ***
    CURSOR  vd_rep_cur
    IS
      SELECT  mmt.base_code                 base_code               -- 拠点コード
             ,mmt.subinventory_class        subinventory_class      -- 保管場所分類
             ,mmt.inventory_item_id         inventory_item_id       -- 品目ID
             ,TO_CHAR(mmt.transaction_date, cv_month)
                                            transaction_date        -- 取引年月
             ,mmt.transaction_quantity      transaction_quantity    -- 取引数量
             ,mtt.attribute3                transaction_type        -- 受払集計キー
             ,xvri.base_code                xvri_base_code          -- VD拠点コード
      FROM    mtl_transaction_types         mtt                     -- 取引タイプマスタ
             ,xxcoi_vd_reception_info       xvri                    -- VD受払情報テーブル
             ,(SELECT   smsi.attribute7               base_code
                       ,smsi.attribute13              subinventory_class
                       ,smmt.inventory_item_id        inventory_item_id
                       ,smmt.transaction_date         transaction_date
-- == 2009/07/31 V1.1 Modified START ===============================================================
--                       ,smmt.transaction_quantity     transaction_quantity
                       ,smmt.primary_quantity         transaction_quantity
-- == 2009/07/31 V1.1 Modified END   ===============================================================
                       ,smmt.transaction_type_id      transaction_type_id
               FROM     mtl_material_transactions     smmt
                       ,mtl_secondary_inventories     smsi
               WHERE    smmt.organization_id      =   gn_f_organization_id
               AND      smmt.transaction_id       >   gn_f_last_transaction_id
               AND      smmt.transaction_id      <=   gn_f_max_transaction_id
               AND      smmt.subinventory_code    =   smsi.secondary_inventory_name
               AND      smmt.organization_id      =   smsi.organization_id
               AND      smsi.attribute13         IN(cv_subinv_class_6, cv_subinv_class_7)
              )                             mmt                     -- 資材取引、保管場所情報
      WHERE   mmt.transaction_type_id   =   mtt.transaction_type_id
      AND     mtt.attribute3           IN(cv_trans_type_160, cv_trans_type_300)
      AND     mmt.base_code             =   xvri.base_code(+)
      AND     mmt.inventory_item_id     =   xvri.inventory_item_id(+)
      AND     TO_CHAR(mmt.transaction_date, cv_month)
                                        =   xvri.practice_date(+)
      ORDER BY  mmt.base_code
               ,mmt.inventory_item_id
               ,mmt.transaction_date;
--
    -- *** ローカル・レコード ***
    vd_rep_rec    vd_rep_cur%ROWTYPE;
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
    -- 集計キー別取引数量累計を初期化
    FOR i IN  1 .. 4 LOOP
      gt_quantity(i)  :=  0;
    END LOOP;
    --
    OPEN  vd_rep_cur;
    FETCH vd_rep_cur  INTO  vd_rep_rec;
    --
    IF (vd_rep_cur%NOTFOUND) THEN
      -- 対象データが存在しない場合、本プロシージャを終了
      CLOSE vd_rep_cur;
      RAISE zero_data_expt;
    END IF;
    --
    <<set_vd_info_loop>>
    LOOP
    --
      IF (   (vd_rep_rec.base_code            <>  lt_base_code)
          OR (vd_rep_rec.inventory_item_id    <>  lt_inventory_item_id)
          OR (vd_rep_rec.transaction_date     <>  lt_transaction_date)
          OR (vd_rep_cur%NOTFOUND)
         )
      THEN
        -- ==========================
        --  更新用データ設定
        -- ==========================
        lt_vd_stock       :=  gt_quantity(1);             -- ベンダ入庫
        lt_vd_move_stock  :=  gt_quantity(3);             -- ベンダ-移動入庫
        lt_vd_ship        :=  gt_quantity(2)  * -1;       -- ベンダ出庫
        lt_vd_move_ship   :=  gt_quantity(4)  * -1;       -- ベンダ-移動出庫
        --
        -- 集計キー別取引数量累計を初期化
        FOR i IN  1 .. 4 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
        --
        IF (    (lt_transaction_date   = gv_f_last_month)
            AND (gv_f_inv_acct_period <> gv_f_last_month)
           )
        THEN
          -- 取引年月が前月で、前月の在庫会計期間がCLOSEしている場合、登録を行わない
          NULL;
        ELSE
          -- ===================================
          --  VD受払情報出力
          -- ===================================
          IF (lt_xvri_base_code IS NULL) THEN
            -- VD受払情報にデータが存在しない場合
            --
            -- ===================================
            -- 原価取得
            -- ===================================
            -- 対象日設定
            IF (lt_transaction_date = TO_CHAR(gd_f_process_date, cv_month)) THEN
              -- 受払日が当月の場合
              ld_object_date  :=  gd_f_process_date;
            ELSE
              -- 受払日が前月の場合
              ld_object_date  :=  LAST_DAY(ADD_MONTHS(gd_f_process_date, -1));
            END IF;
            --
            -- 標準原価取得
            xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id      =>  lt_inventory_item_id                            -- 品目ID
             ,in_org_id       =>  gn_f_organization_id                            -- 組織ID
             ,id_period_date  =>  ld_object_date                                  -- 対象日
             ,ov_cmpnt_cost   =>  lt_standard_cost                                -- 標準原価
             ,ov_errbuf       =>  lv_errbuf                                       -- エラーメッセージ
             ,ov_retcode      =>  lv_retcode                                      -- リターン・コード
             ,ov_errmsg       =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF (lt_standard_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10285
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            -- 営業原価取得
            xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  lt_inventory_item_id                            -- 品目ID
             ,in_org_id         =>  gn_f_organization_id                            -- 組織ID
             ,id_target_date    =>  ld_object_date                                  -- 対象日
             ,ov_discrete_cost  =>  lt_operation_cost                               -- 営業原価
             ,ov_errbuf         =>  lv_errbuf                                       -- エラーメッセージ
             ,ov_retcode        =>  lv_retcode                                      -- リターン・コード
             ,ov_errmsg         =>  lv_errmsg                                       -- ユーザー・エラーメッセージ
            );
            -- 終了パラメータ判定
            IF (lt_operation_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10293
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            --
            INSERT INTO xxcoi_vd_reception_info(
              base_code                       -- 01.拠点コード
             ,organization_id                 -- 02.組織ID
             ,practice_date                   -- 03.年月
             ,inventory_item_id               -- 04.品目ID
             ,operation_cost                  -- 05.営業原価
             ,standard_cost                   -- 06.標準原価
             ,month_begin_quantity            -- 07.月首在庫
             ,vd_stock                        -- 08.ベンダ入庫
             ,vd_move_stock                   -- 09.ベンダ-移動入庫
             ,vd_ship                         -- 10.ベンダ出庫
             ,vd_move_ship                    -- 11.ベンダ-移動出庫
             ,month_end_book_remain_qty       -- 12.月末帳簿残
             ,month_end_quantity              -- 13.月末在庫
             ,inv_wear_account                -- 14.棚卸減耗費
             ,created_by                      -- 15.作成者
             ,creation_date                   -- 16.作成日
             ,last_updated_by                 -- 17.最終更新者
             ,last_update_date                -- 18.最終更新日
             ,last_update_login               -- 19.最終更新ログイン
             ,request_id                      -- 20.要求ID
             ,program_application_id          -- 21.コンカレント・プログラム・アプリケーションID
             ,program_id                      -- 22.コンカレント・プログラムID
             ,program_update_date             -- 23.プログラム更新日
            )VALUES(
              lt_base_code                    -- 01
             ,gn_f_organization_id            -- 02
             ,lt_transaction_date             -- 03
             ,lt_inventory_item_id            -- 04
             ,lt_operation_cost               -- 05
             ,lt_standard_cost                -- 06
             ,0                               -- 07
             ,lt_vd_stock                     -- 08
             ,lt_vd_move_stock                -- 09
             ,lt_vd_ship                      -- 10
             ,lt_vd_move_ship                 -- 11
             ,0                               -- 12
             ,0                               -- 13
             ,0                               -- 14
             ,cn_created_by                   -- 15
             ,SYSDATE                         -- 16
             ,cn_last_updated_by              -- 17
             ,SYSDATE                         -- 18
             ,cn_last_update_login            -- 19
             ,cn_request_id                   -- 20
             ,cn_program_application_id       -- 21
             ,cn_program_id                   -- 22
             ,SYSDATE                         -- 23
            );
            --
          ELSE
            -- VD受払情報にデータが存在する場合
            BEGIN
              -- ロック取得
              SELECT  1
              INTO    ln_dummy
              FROM    xxcoi_vd_reception_info
              WHERE   base_code               = lt_base_code
              AND     practice_date           = lt_transaction_date
              AND     inventory_item_id       = lt_inventory_item_id
              FOR UPDATE NOWAIT;
              --
            EXCEPTION
              WHEN  lock_error_expt THEN
                -- VD受払情報ロックエラーメッセージ
                lv_errmsg   :=  xxccp_common_pkg.get_msg(
                                  iv_application  => cv_short_name
                                 ,iv_name         => cv_msg_xxcoi1_10366
                                );
                lv_errbuf   :=  lv_errmsg;
                RAISE global_process_expt;
                --
            END;
            --
            UPDATE  xxcoi_vd_reception_info
            SET     vd_stock                = vd_stock      + lt_vd_stock         -- 08.ベンダ入庫
                   ,vd_move_stock           = vd_move_stock + lt_vd_move_stock    -- 09.ベンダ-移動入庫
                   ,vd_ship                 = vd_ship       + lt_vd_ship          -- 10.ベンダ出庫
                   ,vd_move_ship            = vd_move_ship  + lt_vd_move_ship     -- 11.ベンダ-移動出庫
                   ,last_updated_by         = cn_last_updated_by                  -- 17.最終更新者
                   ,last_update_date        = SYSDATE                             -- 18.最終更新日
                   ,last_update_login       = cn_last_update_login                -- 19.最終更新ログイン
                   ,request_id              = cn_request_id                       -- 20.要求ID
                   ,program_application_id  = cn_program_application_id           -- 21.コンカレント・プログラム・アプリケーションID
                   ,program_id              = cn_program_id                       -- 22.コンカレント・プログラムID
                   ,program_update_date     = SYSDATE                             -- 23.プログラム更新日
            WHERE   base_code               = lt_base_code
            AND     practice_date           = lt_transaction_date
            AND     inventory_item_id       = lt_inventory_item_id;
            --
          END IF;
        END IF;
      END IF;
      --
      -- 対象データ無しの場合、LOOP処理終了
      EXIT set_vd_info_loop WHEN vd_rep_cur%NOTFOUND;
      --
      --
      -- ===================================
      --  受払集計キー別取引数量集計
      -- ===================================
      CASE vd_rep_rec.transaction_type
        WHEN  cv_trans_type_160 THEN        -- 基準在庫変更
          IF (vd_rep_rec.transaction_quantity >= 0) THEN
            -- 取引数量がプラスの場合、ベンダ入庫
            gt_quantity(1)  :=  gt_quantity(1) + vd_rep_rec.transaction_quantity;
            --
          ELSE
            -- 取引数量がマイナスの場合、ベンダ出庫
            gt_quantity(2)  :=  gt_quantity(2) + vd_rep_rec.transaction_quantity;
          END IF;
          --
        WHEN  cv_trans_type_300 THEN        -- 拠点分割VD在庫振替
          IF (vd_rep_rec.transaction_quantity >= 0) THEN
            -- 取引数量がプラスの場合、ベンダ移動入庫
            gt_quantity(3)  :=  gt_quantity(3) + vd_rep_rec.transaction_quantity;
            --
          ELSE
            -- 取引数量がマイナスの場合、ベンダ移動出庫
            gt_quantity(4)  :=  gt_quantity(4) + vd_rep_rec.transaction_quantity;
          END IF;
          --
        ELSE  NULL;
      END CASE;
      --
      --
      -- 対象データ保持
      lt_base_code          :=  vd_rep_rec.base_code;
      lt_inventory_item_id  :=  vd_rep_rec.inventory_item_id;
      lt_transaction_date   :=  vd_rep_rec.transaction_date;
      lt_xvri_base_code     :=  vd_rep_rec.xvri_base_code;
      --
      -- 対象データ取得
      FETCH vd_rep_cur  INTO  vd_rep_rec;
      --
    END LOOP set_vd_info_loop;
    --
    CLOSE vd_rep_cur;
    --
  EXCEPTION
    -- *** 処理対象なし ***
    WHEN zero_data_expt THEN
      NULL;
      --
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (vd_rep_cur%ISOPEN) THEN
        CLOSE vd_rep_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (vd_rep_cur%ISOPEN) THEN
        CLOSE vd_rep_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (vd_rep_cur%ISOPEN) THEN
        CLOSE vd_rep_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_vd_reception_info;
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
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_param_name   fnd_lookup_values.meaning%TYPE;       -- 入力パラメータ名称
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- ===================================
    --  1.起動パラメータログ出力
    -- ===================================
    -- 起動パラメータ名称取得
    lt_param_name :=  xxcoi_common_pkg.get_meaning(
                        iv_lookup_type      =>    cv_lookup_type
                       ,iv_lookup_code      =>    gv_param_exec_flag
                      );
    --
    IF (lt_param_name IS NULL) THEN
      --  起動フラグ名取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10367
                       ,iv_token_name1  => cv_token_10367_1
                       ,iv_token_value1 => cv_lookup_type
                       ,iv_token_name2  => cv_token_10367_2
                       ,iv_token_value2 => gv_param_exec_flag
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- コンカレント入力パラメータ
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_short_name
                     ,iv_name         =>  cv_msg_xxcoi1_10365
                     ,iv_token_name1  =>  cv_token_10365_1
                     ,iv_token_value1 =>  lt_param_name
                    );
    --
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  gv_out_msg
    );
    -- 空行出力
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  cv_space
    );
    --
    -- ===================================
    --  2.業務処理日付取得
    -- ===================================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    gv_f_last_month     :=  TO_CHAR(ADD_MONTHS(gd_f_process_date, -1), cv_month);
    --
    IF (gd_f_process_date IS NULL) THEN
      -- 業務処理日付取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.在庫組織コード取得
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- 在庫組織コード取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00005
                      ,iv_token_name1  => cv_token_00005_1
                      ,iv_token_value1 => cv_prf_name_orgcd
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  4.在庫組織ID取得
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00006
                      ,iv_token_name1  => cv_token_00006_1
                      ,iv_token_value1 => gv_f_organization_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  5.WHOカラム取得
    -- ===================================
    -- グローバル固定値の設定部で取得しています。
    --
    -- ===================================
    --  6.オープン在庫会計期間情報取得
    -- ===================================
    SELECT  MIN(TO_CHAR(oap.period_start_date, cv_month)) -- 最も古い会計年月
    INTO    gv_f_inv_acct_period
    FROM    org_acct_periods      oap                     -- 在庫会計期間テーブル
    WHERE   oap.organization_id   =   gn_f_organization_id
    AND     oap.open_flag         =   cv_yes;
    --
    -- ===================================
    --  7.前回連携時 取引ID取得
    -- ===================================
    BEGIN
      SELECT  xcc.transaction_id                              -- 処理済取引ID
      INTO    gn_f_last_transaction_id
      FROM    xxcoi_cooperation_control   xcc         -- データ連携制御テーブル
      WHERE   control_id    =   cn_control_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gn_f_last_transaction_id  :=  0;
    END;
    --
    -- ===================================
    --  8.最大取引ＩＤ取得（資材取引）
    -- ===================================
    BEGIN
      SELECT  MAX(mmt.transaction_id)
      INTO    gn_f_max_transaction_id
      FROM    mtl_material_transactions   mmt
      WHERE   mmt.organization_id   =   gn_f_organization_id
      AND     mmt.transaction_id   >=   gn_f_last_transaction_id;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 最大取引ID取得エラーメッセージ
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10127
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exec_flag      IN  VARCHAR2,     -- 1.起動フラグ
    ov_errbuf         OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- 入力パラメータ保持
    gv_param_exec_flag  :=  iv_exec_flag;
    --
    -- =====================================
    --  1.初期処理(A-1)
    -- =====================================
    init(
      ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータチェック
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
        -- =====================================
    --  2.当日データVD受払情報出力(A-2, A-3)
    -- =====================================
    set_vd_reception_info(
      ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータチェック
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    --  3.前月VD受払データ処理(A-4, A-5)
    -- =====================================
    IF (gv_param_exec_flag = cv_exec_flag_2) THEN
      -- 月次起動の場合のみ実行
      set_last_month_data(
        ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      -- リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータチェック
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
    -- =====================================
    --  4.処理済取引ID更新(A-6)
    -- =====================================
    set_cooperation_data(
      ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータチェック
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    --  5.終了処理(A-7)
    -- =====================================
    finalize(
      ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータチェック
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
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
    errbuf              OUT VARCHAR2,       -- エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       -- リターン・コード    --# 固定 #
    iv_exec_flag        IN  VARCHAR2        -- 1.起動フラグ
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
        iv_exec_flag        =>  iv_exec_flag        -- 1.起動フラグ
       ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ             --# 固定 #
       ,ov_retcode          =>  lv_retcode          -- リターン・コード               --# 固定 #
       ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      -- 処理件数設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      --
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行を出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
    fnd_file.put_line(
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
END XXCOI006A22C;
/
