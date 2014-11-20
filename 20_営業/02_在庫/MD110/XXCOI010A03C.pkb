CREATE OR REPLACE PACKAGE BODY XXCOI010A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A03C(body)
 * Description      : VDコラムマスタHHT連携
 * MD.050           : VDコラムマスタHHT連携 MD050_COI_010_A03
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_last_coop_date     データ連携制御ワークテーブルの最終連携日時取得 (A-2)
 *  get_mst_vd_column      VDコラムマスタ情報抽出 (A-4)
 *  forecast_calculation          予測算出 (A-10)
 *  determine_sales_forecast_val  販売予測項目値決定 (A-9)
 *  create_csv_file        ベンダ在庫マスタCSV作成 (A-5)
 *  upd_last_coop_date     データ連携制御ワークテーブルの最終連携日時更新 (A-6)
 *  submain                メイン処理プロシージャ
 *                         UTLファイルオープン (A-3)
 *                         UTLファイルクローズ (A-7)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   T.Nakamura       新規作成
 *  2009/09/14    1.1   H.Sasaki         [0001348]PT対応
 *  2009/11/23    1.2   T.Kojima         [E_本稼動_00006]空コラムIF
 *  2010/05/13    1.3   H.Sasaki         [E_本稼動_02654]顧客移行情報のステータスを検索条件に追加
 *  2010/12/28    1.4   H.Sekine         [E_本稼動_05846]基準在庫数がNULLの場合、満タン数に'0'をセットするように変更
 *  2011/05/12    1.5   H.Sasaki         [E_本稼動_07319]一顧客の重複情報を排除
 *  2011/10/03    1.6   Y.Horikawa       [E_本稼動_08440]HHT2次開発（販売予測情報連携）
 *  2012/01/17    1.7   Y.Horikawa       [E_本稼動_08919]HHT2次開発（販売予測情報連携）追加対応：次回補充の出力制御対応
 *  2012/02/20    1.8   Y.Horikawa       [E_本稼動_09140]販売予測算出時にコラム変更日を考慮するように変更
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
-- == 2010/12/28 V1.4 ADD START  ===============================================================
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
-- == 2010/12/28 V1.4 ADD END    ===============================================================
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
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
-- == 2010/12/28 V1.4 ADD START  ===============================================================
  gn_warn_cnt      NUMBER;                    -- 警告件数
-- == 2010/12/28 V1.4 ADD END    ===============================================================
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A03C';     -- パッケージ名
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アプリケーション短縮名：XXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- アプリケーション短縮名：XXCOI
--
  -- メッセージ
  cv_para_night_exec_f_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10315'; -- パラメータ：夜間実行フラグ
  cv_file_name_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- ファイル名出力メッセージ
  cv_no_data_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- 対象データなしメッセージ
  cv_cal_code_get_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10297'; -- カレンダーコード取得エラーメッセージ
  cv_proc_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- 業務日付取得エラーメッセージ
  cv_next_sys_act_get_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10298'; -- 翌システム稼動日取得エラーメッセージ
  cv_dire_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- ディレクトリ名取得エラーメッセージ
  cv_dire_path_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_file_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- ファイル名取得エラーメッセージ
  cv_last_coop_d_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10010'; -- 最終連携日時取得エラーメッセージ
  cv_table_lock_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10001'; -- ロック取得エラーメッセージ
  cv_file_remain_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- ファイル存在チェックエラーメッセージ
-- == 2010/12/28 V1.4 ADD START  ===============================================================
  cv_qty_null_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10429'; -- 基準在庫数NULLメッセージ
-- == 2010/12/28 V1.4 ADD END    ===============================================================
-- 2011/10/03 V1.6 ADD START =======================================================================
  cv_sppl_lower_limit_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10440'; -- 補充指示率下限値取得エラーメッセージ
  cv_period_use_data_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10441'; -- 販売予測データ利用期間取得エラーメッセージ
  cv_unpredictable_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10442'; -- 販売予測不可メッセージ
  cv_get_supply_inst_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10443'; -- 補充指示取得エラーメッセージ
  cv_no_workday_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10444'; -- 稼働日日数なしエラーメッセージ
  cv_no_days_after_supply_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10445'; -- 前回納品後稼働日日数なしエラーメッセージ
-- 2011/10/03 V1.6 ADD END   =======================================================================
  -- トークン
  cv_tkn_p_flag               CONSTANT VARCHAR2(20)  := 'P_FLAG';           -- 夜間実行フラグ
  cv_tkn_program_id           CONSTANT VARCHAR2(20)  := 'PROGRAM_ID';       -- プログラムID
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- プロファイル名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- ファイル名
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- ディレクトリ名
-- == 2010/12/28 V1.4 ADD START  ===============================================================
  cv_tkn_cust_code            CONSTANT VARCHAR2(20)  := 'CUST_CODE';        -- 顧客コード
  cv_tkn_column_no            CONSTANT VARCHAR2(20)  := 'COLUMN_NO';        -- コラムNO
-- == 2010/12/28 V1.4 ADD END    ===============================================================
-- 2011/10/03 V1.6 ADD START =======================================================================
  cv_tkn_from_date            CONSTANT VARCHAR2(20)  := 'FROM_DATE';           -- 稼働日（自）
  cv_tkn_to_date              CONSTANT VARCHAR2(20)  := 'TO_DATE';             -- 稼働日（至）
  cv_tkn_calendar_code        CONSTANT VARCHAR2(20)  := 'CALENDAR_CODE';       -- カレンダーコード
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';         -- 参照タイプ
  cv_tkn_supply_instruction   CONSTANT VARCHAR2(20)  := 'SUPPLY_INSTRUCTION';  -- 補充指示
  cv_tkn_supply_inst_rate     CONSTANT VARCHAR2(20)  := 'SUPPLY_INST_RATE';    -- 補充指示率
-- 2011/10/03 V1.6 ADD END   =======================================================================
--
  cv_night_exec_flag_y        CONSTANT VARCHAR2(1)   := 'Y';                -- 夜間実行フラグ：'Y'
  cv_night_exec_flag_n        CONSTANT VARCHAR2(1)   := 'N';                -- 夜間実行フラグ：'N'
  cv_cust_status_reorg_crd    CONSTANT VARCHAR2(2)   := '80';               -- 顧客ステータス：更正債権
  cv_cust_status_stop_apr     CONSTANT VARCHAR2(2)   := '90';               -- 顧客ステータス：中止決裁済
  cv_del_flag_y               CONSTANT VARCHAR2(1)   := '1';                -- 削除フラグ：'1'
  cv_del_flag_n               CONSTANT VARCHAR2(1)   := '0';                -- 削除フラグ：'0'
-- == 2009/11/23 V1.2 ADD START  ===============================================================
  cn_price_dummy              CONSTANT NUMBER        := 0;                  -- 価格ダミー
  cv_hot_cold_dummy           CONSTANT VARCHAR2(1)   := '0';                -- H/Cダミー
  cv_item_code_dummy          CONSTANT VARCHAR2(7)   := '0000000';          -- 品目コードダミー
-- == 2009/11/23 V1.2 ADD END    ===============================================================
-- == 2010/05/13 V1.3 Added START ===============================================================
  cv_status_a                 CONSTANT VARCHAR2(1)   := 'A';                --  ステータスA:確定
-- == 2010/05/13 V1.3 Added END   ===============================================================
-- == 2010/12/28 V1.4 ADD START  ===============================================================
  cv_qty_zero                 CONSTANT VARCHAR2(1)   := '0';                -- 満タン数:'0'
-- == 2010/12/28 V1.4 ADD END    ===============================================================
-- 2011/10/03 V1.6 ADD START =======================================================================
  cv_forecast_cust_status     CONSTANT VARCHAR2(30) := 'XXCOS1_FORECAST_CUST_STATUS';
  cv_enable                   CONSTANT VARCHAR2(1)  := 'Y';
  cv_forecast_use_flag        CONSTANT VARCHAR2(1)  := 'Y';
-- 2011/10/03 V1.6 ADD END   =======================================================================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_night_exec_flag   VARCHAR2(1);           -- 夜間実行フラグ
  gd_sysdate           DATE;                  -- SYSDATE
  gd_process_date      DATE;                  -- 業務日付
  gd_next_sys_act_day  DATE;                  -- 翌システム稼動日
  gd_last_coop_date    DATE;                  -- 最終連携日時
  gv_dire_name         VARCHAR2(50);          -- ディレクトリ名
  gv_file_name         VARCHAR2(50);          -- ファイル名
  g_file_handle        UTL_FILE.FILE_TYPE;    -- ファイルハンドル
-- 2011/10/03 V1.6 ADD START =======================================================================
  gn_sppl_inst_lower_limit     NUMBER;  -- 補充指示率下限値
  gn_period_use_data_forecast  NUMBER;  -- 販売予測データ利用期間
-- 2011/10/03 V1.6 ADD END   =======================================================================
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- VDコラムマスタ情報抽出
-- == 2009/09/14 V1.1 Modified START ===============================================================
--  CURSOR get_xmvc_tbl_cur
--  IS
--    -- 最終連携日時以降、SYSDATEより前に更新されたVDコラムマスタのデータを抽出
--    SELECT   xmvc.column_no                AS column_no                   -- コラムNO.
--           , xmvc.price                    AS price                       -- 単価
--           , xmvc.inventory_quantity       AS inventory_quantity          -- 満タン数
--           , xmvc.hot_cold                 AS hot_cold                    -- H/C
--           , xmvc.last_update_date         AS last_update_date            -- 更新日時
--           , msib.segment1                 AS item_code                   -- 品目コード
--           , hca.account_number            AS cust_code                   -- 顧客コード
--           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- 顧客ステータスが「更正債権」
--                                           , cv_cust_status_stop_apr )    -- または、「中止決裁済」の場合
--                  THEN cv_del_flag_y                                      -- 削除フラグに'1'を設定
--                  ELSE cv_del_flag_n                                      -- それ以外の場合、削除フラグに'0'を設定
--             END                           AS del_flag                    -- 削除フラグ
--    FROM     xxcoi_mst_vd_column           xmvc                           -- VDコラムマスタ
--           , mtl_system_items_b            msib                           -- 品目マスタ
--           , hz_cust_accounts              hca                            -- 顧客マスタ
--           , hz_parties                    hp                             -- パーティ
--    WHERE    xmvc.last_update_date         >= gd_last_coop_date           -- 取得条件：最終更新日が最終連携日時以降
--    AND      xmvc.last_update_date         <  gd_sysdate                  -- 取得条件：最終更新日がSYSDATEより前
--    AND      msib.inventory_item_id        =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
--    AND      msib.organization_id          =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
--    AND      hca.cust_account_id           =  xmvc.customer_id            -- 結合条件：顧客マスタとVDコラムマスタ
--    AND      hp.party_id                   =  hca.party_id                -- 結合条件：パーティと顧客マスタ
--    UNION                                                                 -- マージ
--    -- 顧客移行日が前回最終連携日時より大きく、業務日付以前の顧客移行情報を抽出
--    SELECT   xmvc.column_no                AS column_no                   -- コラムNO.
--           , xmvc.price                    AS price                       -- 単価
--           , xmvc.inventory_quantity       AS inventory_quantity          -- 満タン数
--           , xmvc.hot_cold                 AS hot_cold                    -- H/C
--           , xmvc.last_update_date         AS last_update_date            -- 更新日時
--           , msib.segment1                 AS item_code                   -- 品目コード
--           , hca.account_number            AS cust_code                   -- 顧客コード
--           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- 顧客ステータスが「更正債権」
--                                           , cv_cust_status_stop_apr )    -- または、「中止決裁済」の場合
--                  THEN cv_del_flag_y                                      -- 削除フラグに'1'を設定
--                  ELSE cv_del_flag_n                                      -- それ以外の場合、削除フラグに'0'を設定
--             END                           AS del_flag                    -- 削除フラグ
--    FROM     xxcoi_mst_vd_column           xmvc                           -- VDコラムマスタ
--           , mtl_system_items_b            msib                           -- 品目マスタ
--           , hz_cust_accounts              hca                            -- 顧客マスタ
--           , xxcok_cust_shift_info         xcsi                           -- 顧客移行情報
--           , hz_parties                    hp                             -- パーティ
--    WHERE    xmvc.last_update_date         <  gd_last_coop_date           -- 取得条件：最終更新日が最終連携日時より前
--    AND      msib.inventory_item_id        =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
--    AND      msib.organization_id          =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
--    AND      hca.cust_account_id           =  xmvc.customer_id            -- 結合条件：顧客マスタとVDコラムマスタ
--    AND      xcsi.cust_code                =  hca.account_number          -- 結合条件：顧客移行情報と顧客マスタ
--    AND      xcsi.cust_shift_date          >= TRUNC( gd_last_coop_date )  -- 取得条件：顧客移行日が最終連携日日付以降
--    AND      xcsi.cust_shift_date          <=                             -- 取得条件：顧客移行日は、
--               CASE WHEN gv_night_exec_flag     =  cv_night_exec_flag_y   -- 夜間実行フラグが'Y'の場合、
--                    THEN gd_next_sys_act_day                              -- 翌システム稼動日以前
--                    ELSE gd_process_date                                  -- それ以外の場合、業務日付以前
--               END
--    AND      hp.party_id                   =  hca.party_id                -- 結合条件：パーティと顧客マスタ
--  ;
--
  CURSOR  get_xmvc_tbl_cur1
  IS
-- 2011/10/03 V1.6 MOD START =======================================================================
--    SELECT   /*+ use_nl(hp hca xmvc msib) */
    SELECT   /*+ push_subq(@a) push_subq(@b) leading(xmvc) */
-- 2011/10/03 V1.6 MOD END   =======================================================================
             xmvc.column_no                AS column_no                   -- コラムNO.
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.price                    AS price                       -- 単価
           , NVL( xmvc.price, cn_price_dummy )          AS price          -- 単価
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.inventory_quantity       AS inventory_quantity          -- 満タン数
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.hot_cold                 AS hot_cold                    -- H/C
           , NVL( xmvc.hot_cold, cv_hot_cold_dummy )    AS hot_cold       -- H/C
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.last_update_date         AS last_update_date            -- 更新日時
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , msib.segment1                 AS item_code                   -- 品目コード
           , NVL( msib.segment1, cv_item_code_dummy )   AS item_code      -- 品目コード
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , hca.account_number            AS cust_code                   -- 顧客コード
           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- 顧客ステータスが「更正債権」
                                           , cv_cust_status_stop_apr )    -- または、「中止決裁済」の場合
                  THEN cv_del_flag_y                                      -- 削除フラグに'1'を設定
                  ELSE cv_del_flag_n                                      -- それ以外の場合、削除フラグに'0'を設定
             END                           AS del_flag                    -- 削除フラグ
-- 2011/10/03 V1.6 ADD START =======================================================================
           , NULL                          AS dlv_date_1                  -- 納品日１
           , NULL                          AS quantity_1                  -- 本数１
           , NULL                          AS dlv_date_2                  -- 納品日２
           , NULL                          AS quantity_2                  -- 本数２
           , NULL                          AS dlv_date_3                  -- 納品日３
           , NULL                          AS quantity_3                  -- 本数３
           , NULL                          AS dlv_date_4                  -- 納品日４
           , NULL                          AS quantity_4                  -- 本数４
           , NULL                          AS dlv_date_5                  -- 納品日５
           , NULL                          AS quantity_5                  -- 本数５
           , NULL                          AS column_change_date          -- コラム変更日
           , NULL                          AS calendar_code               -- カレンダーコード
-- 2011/10/03 V1.6 ADD END   =======================================================================
    FROM     xxcoi_mst_vd_column           xmvc                           -- VDコラムマスタ
           , mtl_system_items_b            msib                           -- 品目マスタ
           , hz_cust_accounts              hca                            -- 顧客マスタ
           , hz_parties                    hp                             -- パーティ
-- 2011/10/03 V1.6 ADD START =======================================================================
           , xxcmm_cust_accounts           xca                            -- 顧客追加情報
-- 2011/10/03 V1.6 ADD END   =======================================================================
    WHERE    xmvc.last_update_date         >= gd_last_coop_date           -- 取得条件：最終更新日が最終連携日時以降
    AND      xmvc.last_update_date         <  gd_sysdate                  -- 取得条件：最終更新日がSYSDATEより前
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--  AND      msib.inventory_item_id        =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
--  AND      msib.organization_id          =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
    AND      msib.inventory_item_id (+)    =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
    AND      msib.organization_id   (+)    =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
-- == 2009/11/23 V1.2 MOD END    ===============================================================
    AND      hca.cust_account_id           =  xmvc.customer_id            -- 結合条件：顧客マスタとVDコラムマスタ
-- 2011/10/03 V1.6 MOD START =======================================================================
--    AND      hp.party_id                   =  hca.party_id;                -- 結合条件：パーティと顧客マスタ
    AND      hp.party_id                   =  hca.party_id                 -- 結合条件：パーティと顧客マスタ
-- 2011/10/03 V1.6 MOD END   =======================================================================
-- 2011/10/03 V1.6 ADD START =======================================================================
    AND      xca.customer_id               =  xmvc.customer_id            -- 結合条件：顧客追加情報とVDコラムマスタ
    AND      (NOT EXISTS (SELECT /*+ qb_name(a) */
                                 'X'
                          FROM bom_calendars bc                               -- 稼働日カレンダー
                          WHERE xca.calendar_code = bc.calendar_code          -- 結合条件：顧客追加情報と稼働日カレンダー
                          AND   bc.attribute1 = cv_forecast_use_flag)         -- 取得条件：販売予測利用フラグ
           OR NOT EXISTS (SELECT /*+ qb_name(b) */
                                 'X'
                          FROM fnd_lookup_values flv                          -- 販売予測対象顧客ステータス
                          WHERE flv.lookup_type = cv_forecast_cust_status     -- 取得条件：販売予測対象顧客ステータス（TYPE）
                          AND   flv.language = USERENV('LANG')                -- 取得条件：ログイン時使用言語
                          AND   gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                                AND NVL(flv.end_date_active, gd_process_date) -- 取得条件：有効日
                          AND   flv.enabled_flag = cv_enable                  -- 取得条件：有効フラグ
                          AND   hp.duns_number_c = flv.lookup_code)           -- 結合条件：パーティと販売予測対象顧客ステータス
              );
-- 2011/10/03 V1.6 ADD END   =======================================================================
  --
  CURSOR  get_xmvc_tbl_cur2
  IS
-- 2011/10/03 V1.6 MOD START =======================================================================
--    SELECT   /*+ use_nl(hp hca xcsi xmvc msib) */
    SELECT   /*+ push_subq(@a) push_subq(@b) leading(xcsi) */
-- 2011/10/03 V1.6 MOD END   =======================================================================
-- == 2011/05/12 V1.5 Added START ===============================================================
            DISTINCT
-- == 2011/05/12 V1.5 Added END   ===============================================================
             xmvc.column_no                AS column_no                   -- コラムNO.
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.price                    AS price                       -- 単価
           , NVL( xmvc.price, cn_price_dummy )          AS price          -- 単価
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.inventory_quantity       AS inventory_quantity          -- 満タン数
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.hot_cold                 AS hot_cold                    -- H/C
           , NVL( xmvc.hot_cold, cv_hot_cold_dummy )    AS hot_cold       -- H/C
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.last_update_date         AS last_update_date            -- 更新日時
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , msib.segment1                 AS item_code                   -- 品目コード
           , NVL( msib.segment1, cv_item_code_dummy )   AS item_code      -- 品目コード
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , hca.account_number            AS cust_code                   -- 顧客コード
           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- 顧客ステータスが「更正債権」
                                           , cv_cust_status_stop_apr )    -- または、「中止決裁済」の場合
                  THEN cv_del_flag_y                                      -- 削除フラグに'1'を設定
                  ELSE cv_del_flag_n                                      -- それ以外の場合、削除フラグに'0'を設定
             END                           AS del_flag                    -- 削除フラグ
-- 2011/10/03 V1.6 ADD START =======================================================================
           , NULL                          AS dlv_date_1                  -- 納品日１
           , NULL                          AS quantity_1                  -- 本数１
           , NULL                          AS dlv_date_2                  -- 納品日２
           , NULL                          AS quantity_2                  -- 本数２
           , NULL                          AS dlv_date_3                  -- 納品日３
           , NULL                          AS quantity_3                  -- 本数３
           , NULL                          AS dlv_date_4                  -- 納品日４
           , NULL                          AS quantity_4                  -- 本数４
           , NULL                          AS dlv_date_5                  -- 納品日５
           , NULL                          AS quantity_5                  -- 本数５
           , NULL                          AS column_change_date          -- コラム変更日
           , NULL                          AS calendar_code               -- カレンダーコード
-- 2011/10/03 V1.6 ADD END   =======================================================================
    FROM     xxcoi_mst_vd_column           xmvc                           -- VDコラムマスタ
           , mtl_system_items_b            msib                           -- 品目マスタ
           , hz_cust_accounts              hca                            -- 顧客マスタ
           , xxcok_cust_shift_info         xcsi                           -- 顧客移行情報
           , hz_parties                    hp                             -- パーティ
-- 2011/10/03 V1.6 ADD START =======================================================================
           , xxcmm_cust_accounts           xca                            -- 顧客追加情報
-- 2011/10/03 V1.6 ADD END   =======================================================================
    WHERE    xmvc.last_update_date         <  gd_last_coop_date           -- 取得条件：最終更新日が最終連携日時より前
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--  AND      msib.inventory_item_id        =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
--  AND      msib.organization_id          =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
    AND      msib.inventory_item_id (+)    =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
    AND      msib.organization_id   (+)    =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
-- == 2009/11/23 V1.2 MOD END    ===============================================================
    AND      hca.cust_account_id           =  xmvc.customer_id            -- 結合条件：顧客マスタとVDコラムマスタ
    AND      xcsi.cust_code                =  hca.account_number          -- 結合条件：顧客移行情報と顧客マスタ
    AND      xcsi.cust_shift_date          >= TRUNC( gd_last_coop_date )  -- 取得条件：顧客移行日が最終連携日日付以降
    AND      xcsi.cust_shift_date          <=                             -- 取得条件：顧客移行日は、
               CASE WHEN gv_night_exec_flag     =  cv_night_exec_flag_y   -- 夜間実行フラグが'Y'の場合、
                    THEN gd_next_sys_act_day                              -- 翌システム稼動日以前
                    ELSE gd_process_date                                  -- それ以外の場合、業務日付以前
               END
    AND      hp.party_id                   =  hca.party_id                -- 結合条件：パーティと顧客マスタ
-- == 2010/05/13 V1.3 Added START ===============================================================
    AND      xcsi.status                   =  cv_status_a                 --  ステータスA:確定
-- 2011/10/03 V1.6 ADD START =======================================================================
    AND      xca.customer_id               =  xmvc.customer_id            -- 結合条件：顧客追加情報とVDコラムマスタ
    AND      (NOT EXISTS (SELECT /*+ qb_name(a) */
                                 'X'
                          FROM bom_calendars bc                               -- 稼働日カレンダー
                          WHERE xca.calendar_code = bc.calendar_code          -- 結合条件：顧客追加情報と稼働日カレンダー
                          AND   bc.attribute1 = cv_forecast_use_flag)         -- 取得条件：販売予測利用フラグ
           OR NOT EXISTS (SELECT /*+ qb_name(b) */
                                 'X'
                          FROM fnd_lookup_values flv                          -- 販売予測対象顧客ステータス
                          WHERE flv.lookup_type = cv_forecast_cust_status     -- 取得条件：販売予測対象顧客ステータス（TYPE）
                          AND   flv.language = USERENV('LANG')                -- 取得条件：ログイン時使用言語
                          AND   gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                                AND NVL(flv.end_date_active, gd_process_date) -- 取得条件：有効日
                          AND   flv.enabled_flag = cv_enable                  -- 取得条件：有効フラグ
                          AND   hp.duns_number_c = flv.lookup_code)           -- 結合条件：パーティと販売予測対象顧客ステータス
              );

  CURSOR  get_xmvc_tbl_cur3
  IS
    SELECT   /*+ leading(@a bc) */
             xmvc.column_no                AS column_no                   -- コラムNO.
           , NVL( xmvc.price, cn_price_dummy )          AS price          -- 単価
           , xmvc.inventory_quantity       AS inventory_quantity          -- 満タン数
           , NVL( xmvc.hot_cold, cv_hot_cold_dummy )    AS hot_cold       -- H/C
           , xmvc.last_update_date         AS last_update_date            -- 更新日時
           , NVL( msib.segment1, cv_item_code_dummy )   AS item_code      -- 品目コード
           , hca.account_number            AS cust_code                   -- 顧客コード
           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- 顧客ステータスが「更正債権」
                                           , cv_cust_status_stop_apr )    -- または、「中止決裁済」の場合
                  THEN cv_del_flag_y                                      -- 削除フラグに'1'を設定
                  ELSE cv_del_flag_n                                      -- それ以外の場合、削除フラグに'0'を設定
             END                           AS del_flag                    -- 削除フラグ
           , xmvc.dlv_date_1               AS dlv_date_1                  -- 納品日１
           , xmvc.quantity_1               AS quantity_1                  -- 本数１
           , xmvc.dlv_date_2               AS dlv_date_2                  -- 納品日２
           , xmvc.quantity_2               AS quantity_2                  -- 本数２
           , xmvc.dlv_date_3               AS dlv_date_3                  -- 納品日３
           , xmvc.quantity_3               AS quantity_3                  -- 本数３
           , xmvc.dlv_date_4               AS dlv_date_4                  -- 納品日４
           , xmvc.quantity_4               AS quantity_4                  -- 本数４
           , xmvc.dlv_date_5               AS dlv_date_5                  -- 納品日５
           , xmvc.quantity_5               AS quantity_5                  -- 本数５
           , xmvc.column_change_date       AS column_change_date          -- コラム変更日
           , xca.calendar_code             AS calendar_code               -- カレンダーコード
    FROM     xxcoi_mst_vd_column           xmvc                           -- VDコラムマスタ
           , mtl_system_items_b            msib                           -- 品目マスタ
           , hz_cust_accounts              hca                            -- 顧客マスタ
           , hz_parties                    hp                             -- パーティ
           , xxcmm_cust_accounts           xca                            -- 顧客追加情報
    WHERE    msib.inventory_item_id (+)    =  xmvc.item_id                -- 結合条件：品目マスタとVDコラムマスタ
    AND      msib.organization_id   (+)    =  xmvc.organization_id        -- 結合条件：品目マスタとVDコラムマスタ
    AND      hca.cust_account_id           =  xmvc.customer_id            -- 結合条件：顧客マスタとVDコラムマスタ
    AND      hp.party_id                   =  hca.party_id                -- 結合条件：パーティと顧客マスタ
    AND      xca.customer_id               =  xmvc.customer_id            -- 結合条件：顧客追加情報とVDコラムマスタ
    AND      EXISTS (SELECT /*+ qb_name(a) */
                            'X'
                     FROM bom_calendars bc                               -- 稼働日カレンダー
                     WHERE xca.calendar_code = bc.calendar_code          -- 結合条件：顧客追加情報と稼働日カレンダー
                     AND   bc.attribute1 = cv_forecast_use_flag)         -- 取得条件：販売予測利用フラグ
    AND      EXISTS (SELECT 'X'
                     FROM fnd_lookup_values flv                          -- 販売予測対象顧客ステータス
                     WHERE flv.lookup_type = cv_forecast_cust_status     -- 取得条件：販売予測対象顧客ステータス（TYPE）
                     AND   flv.language = USERENV('LANG')                -- 取得条件：ログイン時使用言語
                     AND   gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                           AND NVL(flv.end_date_active, gd_process_date) -- 取得条件：有効日
                     AND   flv.enabled_flag = cv_enable                  -- 取得条件：有効フラグ
                     AND   hp.duns_number_c = flv.lookup_code)           -- 結合条件：パーティと販売予測対象顧客ステータス
-- 2011/10/03 V1.6 ADD END   =======================================================================
    ;
-- == 2010/05/13 V1.3 Added END   ===============================================================
-- == 2009/09/14 V1.1 Modified END   ===============================================================
--
  -- ==============================
  -- ユーザー定義グローバルテーブル
  -- ==============================
-- == 2009/09/14 V1.1 Modified START ===============================================================
--  TYPE g_get_xmvc_tbl_ttype IS TABLE OF get_xmvc_tbl_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--  g_get_xmvc_tbl_tab        g_get_xmvc_tbl_ttype;
-- 2011/10/03 V1.6 MOD START =======================================================================
--  get_xmvc_tbl_rec  get_xmvc_tbl_cur1%ROWTYPE;
  get_xmvc_tbl_rec  get_xmvc_tbl_cur3%ROWTYPE;
-- 2011/10/03 V1.6 MOD END   =======================================================================
-- == 2009/09/14 V1.1 Modified END   ===============================================================
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  get_last_coop_date_expt   EXCEPTION;     -- 最終連携日時取得エラー
  lock_expt                 EXCEPTION;     -- ロック取得エラー
  remain_file_expt          EXCEPTION;     -- ファイル存在エラー
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 ); -- ロック取得例外
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- プロファイル XXCOI:システム稼働日カレンダーコード
    cv_prf_sys_act_cal_code    CONSTANT VARCHAR2(30) := 'XXCOI1_SYS_ACT_CALENDAR_CODE';
    -- プロファイル XXCOI:HHT_OUTBOUND格納ディレクトリパス
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';
    -- プロファイル XXCOI:VDコラムマスタHHT連携ファイル名
    cv_prf_file_vdhht          CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_VDHHT';
-- 2011/10/03 V1.6 ADD START =======================================================================
    -- プロファイル XXCOI:補充指示率下限値
    cv_prf_sppl_lower_limit       CONSTANT VARCHAR2(30) := 'XXCOI1_SUPPLY_INST_LOWER_LIMIT';
    -- プロファイル XXCOI:販売予測データ利用期間
    cv_prf_period_use_data_fcast  CONSTANT VARCHAR2(40) := 'XXCOI1_PERIOD_USE_DATA_FORECAST';
-- 2011/10/03 V1.6 ADD END   =======================================================================
--
    cn_working_day             CONSTANT NUMBER       := 1;    -- 営業日数
    cv_slash                   CONSTANT VARCHAR2(1)  := '/';  -- スラッシュ
--
    -- *** ローカル変数 ***
    lv_sys_act_cal_code        VARCHAR2(50);                  -- システム稼動日カレンダーコード
    lv_dire_path               VARCHAR2(100);                 -- ディレクトリフルパス格納変数
    lv_file_name               VARCHAR2(100);                 -- ファイル名格納変数
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
    -- ===============================
    -- コンカレント入力パラメータ出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_para_night_exec_f_msg
                    , iv_token_name1  => cv_tkn_p_flag
                    , iv_token_value1 => gv_night_exec_flag
                  );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
-- 2011/10/03 V1.6 ADD START =======================================================================
    -- ==============================================================
    -- プロファイル：補充指示率下限値取得
    -- ==============================================================
    gn_sppl_inst_lower_limit := fnd_profile.value( cv_prf_sppl_lower_limit );
    -- 補充指示率下限値が取得できない場合
    IF ( gn_sppl_inst_lower_limit IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_sppl_lower_limit_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_sppl_lower_limit
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ==============================================================
    -- プロファイル：販売予測データ利用期間
    -- ==============================================================
    gn_period_use_data_forecast := fnd_profile.value( cv_prf_period_use_data_fcast );
    -- 販売予測データ利用期間が取得できない場合
    IF ( gn_period_use_data_forecast IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_period_use_data_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_period_use_data_fcast
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2011/10/03 V1.6 ADD END   =======================================================================
    -- ===============================
    -- SYSDATE取得
    -- ===============================
    gd_sysdate := SYSDATE;
--
    -- ==============================================================
    -- プロファイル：システム稼働日カレンダーコード取得
    -- ==============================================================
    lv_sys_act_cal_code := fnd_profile.value( cv_prf_sys_act_cal_code );
    -- システム稼働日カレンダーコードが取得できない場合
    IF ( lv_sys_act_cal_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_cal_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_sys_act_cal_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 業務日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_proc_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 翌システム稼動日取得
    -- ===============================
    gd_next_sys_act_day := xxccp_common_pkg2.get_working_day(
                               id_date          => gd_process_date
                             , in_working_day   => cn_working_day
                             , iv_calendar_code => lv_sys_act_cal_code
                           );
    -- 翌システム稼動日が取得できない場合
    IF ( gd_next_sys_act_day IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_next_sys_act_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル：ディレクトリ名取得
    -- ===============================
    -- ディレクトリ名取得
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- ディレクトリ名が取得できない場合
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_dire_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ディレクトリパス取得
    BEGIN
      SELECT directory_path
      INTO   lv_dire_path
      FROM   all_directories
      WHERE  directory_name    = gv_dire_name;
    EXCEPTION
      -- ディレクトリパスが取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_dire_path_get_err_msg
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- プロファイル：ファイル名取得
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_vdhht );
    -- ファイル名が取得できない場合
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_file_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_vdhht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- IFファイル名（IFファイルのフルパス情報）出力
    -- ==============================================================
    lv_file_name := lv_dire_path || cv_slash || gv_file_name;
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_name_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => lv_file_name
                    );
    -- メッセージ出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** 共通関数例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
   * Procedure Name   : get_last_coop_date
   * Description      : データ連携制御ワークテーブルの最終連携日時取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_last_coop_date(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_last_coop_date'; -- プログラム名
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
    -- ==============================================================
    -- データ連携制御ワークテーブルから前回の最終連携日時、ロックを取得
    -- ==============================================================
    BEGIN
--
      SELECT xcc.last_cooperation_date AS last_cooperation_date -- 最終連携日時
      INTO   gd_last_coop_date
      FROM   xxcoi_cooperation_control xcc                      -- データ連携制御ワークテーブル
      WHERE  xcc.program_id            = cn_program_id          -- 取得条件プログラムID
      FOR UPDATE NOWAIT;                                        -- ロック取得
--
    -- 前回の最終連携日時が取得できない場合
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_last_coop_date_expt;
--
      WHEN OTHERS THEN
        RAISE;
--
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 最終連携日時取得エラー
    WHEN get_last_coop_date_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_last_coop_d_get_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
    -- ロック取得エラー
    WHEN lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_table_lock_err_msg
                      , iv_token_name1  => cv_tkn_program_id
                      , iv_token_value1 => cn_program_id
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END get_last_coop_date;
--
-- == 2009/09/14 V1.1 Deleted START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : get_mst_vd_column
--   * Description      : VDコラムマスタ情報抽出(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_mst_vd_column(
--      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
--    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
--    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mst_vd_column'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- カーソルオープン
--    OPEN  get_xmvc_tbl_cur;
----
--    -- カーソルデータ取得
--    FETCH get_xmvc_tbl_cur BULK COLLECT INTO g_get_xmvc_tbl_tab;
----
--    -- カーソルのクローズ
--    CLOSE get_xmvc_tbl_cur;
----
--    -- ===============================
--    -- 対象件数カウント
--    -- ===============================
--    gn_target_cnt := g_get_xmvc_tbl_tab.COUNT;
----
--    -- ===============================
--    -- 抽出0件チェック
--    -- ===============================
--    IF ( gn_target_cnt = 0 ) THEN
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_appl_short_name_xxcoi
--                      , iv_name         => cv_no_data_msg
--                    );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => gv_out_msg
--      );
--    END IF;
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      -- カーソルがOPENしている場合
--      IF ( get_xmvc_tbl_cur%ISOPEN ) THEN
--        CLOSE get_xmvc_tbl_cur;
--      END IF;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      -- カーソルがOPENしている場合
--      IF ( get_xmvc_tbl_cur%ISOPEN ) THEN
--        CLOSE get_xmvc_tbl_cur;
--      END IF;
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      -- カーソルがOPENしている場合
--      IF ( get_xmvc_tbl_cur%ISOPEN ) THEN
--        CLOSE get_xmvc_tbl_cur;
--      END IF;
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END get_mst_vd_column;
-- == 2009/09/14 V1.1 Deleted END   ===============================================================
--
-- 2011/10/03 V1.6 ADD START =======================================================================
  /**********************************************************************************
   * Procedure Name   : forecast_calculation
   * Description      : 予測算出(A-10)
   ***********************************************************************************/
  PROCEDURE forecast_calculation(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    , on_sales_forecast_qty  OUT NUMBER    -- 販売予測数
    , ov_next_supply         OUT VARCHAR2  -- 次回補充
    , on_supply_inst_pct     OUT NUMBER    -- 補充指示率
    , in_total_qty           IN  NUMBER    -- 合計本数
    , in_workdays            IN  NUMBER    -- 稼働日日数
    , in_days_after_supply   IN  NUMBER    -- 前回納品後稼働日日数
    , in_inventory_quantity  IN  NUMBER)   -- 基準在庫数
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_calculation'; -- プログラム名
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
    cn_max_value_next_supply  CONSTANT NUMBER := 99;
    cn_min_value_next_supply  CONSTANT NUMBER := 1;
    cn_max_supply_inst_pct    CONSTANT NUMBER := 100;
    cn_max_sales_forecast_qty CONSTANT NUMBER := 99;
--
    -- *** ローカル変数 ***
    ln_sales_forecast_qty  NUMBER;
    ln_next_supply         NUMBER;
    ln_supply_inst_pct     NUMBER;
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
    -- 初期化
    on_sales_forecast_qty := NULL;
    ov_next_supply := NULL;
    on_supply_inst_pct := NULL;
--
    -- 販売予測数（小数点以下切り上げ）
    ln_sales_forecast_qty := CEIL((in_total_qty / in_workdays) * in_days_after_supply);
    -- 販売予測数（最大値を超えた場合は最大値に置き換え）
    ln_sales_forecast_qty := LEAST(ln_sales_forecast_qty, cn_max_sales_forecast_qty);
--
-- 2011/11/24 mod start Ver.1.6 対応中の変更
--    -- 次回補充（小数点以下切り上げ）
--    ln_next_supply := CEIL(gn_sppl_inst_lower_limit * in_inventory_quantity / (in_total_qty / in_workdays));
    -- 次回補充（小数点以下切捨て）
    ln_next_supply := FLOOR(gn_sppl_inst_lower_limit * in_inventory_quantity / ln_sales_forecast_qty);
    -- 次回補充（最小値より小さい場合は最小値に置き換え）
    ln_next_supply := GREATEST(ln_next_supply, cn_min_value_next_supply);
-- 2011/11/24 mod end Ver.1.6 対応中の変更
    -- 次回補充（最大値を超えた場合は最大値に置き換え）
    ln_next_supply := LEAST(ln_next_supply, cn_max_value_next_supply);
--
    -- 補充指示率（小数点1桁目を四捨五入）
    ln_supply_inst_pct := ROUND(ln_sales_forecast_qty / in_inventory_quantity * 100);
    -- 補充指示率（最大値を超えた場合は最大値に置き換え）
    ln_supply_inst_pct := LEAST(ln_supply_inst_pct, cn_max_supply_inst_pct);
--
    on_sales_forecast_qty := ln_sales_forecast_qty;
    ov_next_supply := TO_CHAR(ln_next_supply);
    on_supply_inst_pct := ln_supply_inst_pct;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END forecast_calculation;
--
  /**********************************************************************************
   * Procedure Name   : determine_sales_forecast_val
   * Description      : 販売予測項目値決定(A-9)
   ***********************************************************************************/
  PROCEDURE determine_sales_forecast_val(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    , ov_sales_forecast_qty  OUT VARCHAR2  -- 販売予測数
    , ov_supply_instruction  OUT VARCHAR2  -- 補充指示
    , ov_next_supply         OUT VARCHAR2  -- 次回補充
    , it_xmvc_tbl_rec        IN  get_xmvc_tbl_cur3%ROWTYPE)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'determine_sales_forecast_val'; -- プログラム名
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
    cv_change_column                CONSTANT VARCHAR2(30) := 'CHANGE COLUMN';
    cv_no_sales                     CONSTANT VARCHAR2(30) := 'NO SALES';
    cv_unpredictable                CONSTANT VARCHAR2(30) := 'UNPREDICTABLE';
    cv_supply_instruction           CONSTANT VARCHAR2(30) := 'SUPPLY INSTRUCTION';
    cn_default_supply_inst_pct      CONSTANT NUMBER       := 0;
    cv_lookup_type_supply_inst      CONSTANT VARCHAR2(30) := 'XXCOI1_SUPPLY_INSTRUCTION';
-- 2012/01/17 V1.7 Add Start =======================================================================
    cv_flag_value_output            CONSTANT VARCHAR2(1) := 'Y';
-- 2012/01/17 V1.7 Add End   =======================================================================
--
    -- *** ローカル変数 ***
    lv_msg                          VARCHAR2(2000);
    ln_supply_instruction_pct       NUMBER;
    lv_supply_inst_specific_cd      fnd_lookup_values.attribute4%TYPE;
    ld_recent_dlv_date              DATE;
    ld_past_dlv_date                DATE;
    ld_usable_min_dlv_date          DATE;
    ln_total_qty                    NUMBER;
    ld_dlv_date2                    DATE;
    ln_workdays                     NUMBER;
    ln_days_after_supply            NUMBER;
    ln_sales_forecast_qty           NUMBER;
    lv_next_supply                  VARCHAR2(10);
    lv_sales_forecast_fix_val       fnd_lookup_values.attribute5%TYPE;
    lv_supply_instruction           fnd_lookup_values.attribute1%TYPE;
-- 2012/01/17 V1.7 Add Start =======================================================================
    lv_next_supply_output_flag      fnd_lookup_values.attribute6%TYPE;
-- 2012/01/17 V1.7 Add End   =======================================================================
--
    -- *** ローカル・カーソル ***
    CURSOR get_workday_cur (
        iv_calendar_code  VARCHAR2
      , id_from_date      DATE
      , id_to_date        DATE)
    IS
      SELECT COUNT(1) workdays
      FROM  bom_calendar_dates bcd
      WHERE bcd.calendar_code = iv_calendar_code
      AND   bcd.calendar_date >= id_from_date
      AND   bcd.calendar_date <= id_to_date
      AND   bcd.seq_num IS NOT NULL;
--
    -- *** ローカル・レコード ***
    get_workday_rec  get_workday_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    ln_sales_forecast_qty := NULL;
    lv_supply_instruction := NULL;
    lv_next_supply        := NULL;
    ln_total_qty          := 0;

    IF (NVL(it_xmvc_tbl_rec.inventory_quantity, 0) = 0) THEN
      -- 基準在庫数無し（空コラム）
      RETURN;
    END IF;
--
    -- 販売予測に利用可能な納品日の判断用の閾値
    ld_usable_min_dlv_date := ADD_MONTHS(gd_process_date, gn_period_use_data_forecast * -1);

    -- 納品日１が販売予測に利用可能か判断
    IF (it_xmvc_tbl_rec.dlv_date_1 > ld_usable_min_dlv_date) THEN
      ld_past_dlv_date := it_xmvc_tbl_rec.dlv_date_1;
      ln_total_qty := ln_total_qty + GREATEST(NVL(it_xmvc_tbl_rec.quantity_1, 0), 0);
      ld_recent_dlv_date := it_xmvc_tbl_rec.dlv_date_1;
    END IF;

    -- 納品日２が販売予測に利用可能か判断
    IF (it_xmvc_tbl_rec.dlv_date_2 > ld_usable_min_dlv_date) THEN
      ld_past_dlv_date := it_xmvc_tbl_rec.dlv_date_2;
      ln_total_qty := ln_total_qty + GREATEST(NVL(it_xmvc_tbl_rec.quantity_2, 0), 0);
      ld_dlv_date2 := it_xmvc_tbl_rec.dlv_date_2;
    END IF;

    -- 納品日３が販売予測に利用可能か判断
    IF (it_xmvc_tbl_rec.dlv_date_3 > ld_usable_min_dlv_date) THEN
      ld_past_dlv_date := it_xmvc_tbl_rec.dlv_date_3;
      ln_total_qty := ln_total_qty + GREATEST(NVL(it_xmvc_tbl_rec.quantity_3, 0), 0);
    END IF;

    -- 納品日４が販売予測に利用可能か判断
    IF (it_xmvc_tbl_rec.dlv_date_4 > ld_usable_min_dlv_date) THEN
      ld_past_dlv_date := it_xmvc_tbl_rec.dlv_date_4;
      ln_total_qty := ln_total_qty + GREATEST(NVL(it_xmvc_tbl_rec.quantity_4, 0), 0);
    END IF;

    -- 納品日５が販売予測に利用可能か判断
    IF (it_xmvc_tbl_rec.dlv_date_5 > ld_usable_min_dlv_date) THEN
      ld_past_dlv_date := it_xmvc_tbl_rec.dlv_date_5;
-- 2012/02/20 V1.8 Add Start =======================================================================
    ELSIF (it_xmvc_tbl_rec.dlv_date_5 IS NULL) THEN
      IF (it_xmvc_tbl_rec.column_change_date > ld_usable_min_dlv_date) THEN
        -- 納品日５ の設定がなく、コラム変更日が利用可能である場合
        ld_past_dlv_date := it_xmvc_tbl_rec.column_change_date;
      END IF;
-- 2012/02/20 V1.8 Add End =======================================================================
    END IF;
--
    -- 稼働日日数
    <<workday>>
    FOR get_workday_rec IN get_workday_cur (it_xmvc_tbl_rec.calendar_code, ld_past_dlv_date, ld_recent_dlv_date) LOOP
      ln_workdays := GREATEST(get_workday_rec.workdays - 1, 0);
      EXIT workday;
    END LOOP workday;
--
    -- 前回納品後稼働日日数
    <<days_after_supply>>
    FOR get_workday_rec IN get_workday_cur (it_xmvc_tbl_rec.calendar_code, ld_recent_dlv_date, gd_process_date) LOOP
      ln_days_after_supply := get_workday_rec.workdays;
      EXIT days_after_supply;
    END LOOP days_after_supply;
--
    --
    -- 補充指示特定キー等の決定
    --
-- 2012/02/20 V1.8 Mod Start =======================================================================
--    IF ((it_xmvc_tbl_rec.column_change_date IS NOT NULL) AND (it_xmvc_tbl_rec.dlv_date_2 IS NULL)) THEN
    IF ((it_xmvc_tbl_rec.column_change_date IS NOT NULL) AND (it_xmvc_tbl_rec.dlv_date_1 IS NULL)) THEN
-- 2012/02/20 V1.8 Mod End   =======================================================================
      -- コラム替え時
      lv_supply_inst_specific_cd := cv_change_column;
      ln_supply_instruction_pct := cn_default_supply_inst_pct;

-- 2012/02/20 V1.8 Mod Start =======================================================================
--    ELSIF (ld_dlv_date2 IS NULL) THEN
    ELSIF ((it_xmvc_tbl_rec.column_change_date IS NULL) AND (ld_dlv_date2 IS NULL)) THEN
-- 2012/02/20 V1.8 Mod End   =======================================================================
      -- 販売予測不可（納品実績が2回以上無し）
      lv_supply_inst_specific_cd := cv_unpredictable;
      ln_supply_instruction_pct := cn_default_supply_inst_pct;
-- 2011/11/24 del start Ver.1.6 対応時のPTに伴い削除
--      -- 販売予測不可メッセージを出力
--      -- メッセージ取得
--      lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_appl_short_name_xxcoi
--                  , iv_name         => cv_unpredictable_msg
--                  , iv_token_name1  => cv_tkn_cust_code
--                  , iv_token_value1 => it_xmvc_tbl_rec.cust_code
--                  , iv_token_name2  => cv_tkn_column_no
--                  , iv_token_value2 => it_xmvc_tbl_rec.column_no
--                );
--      -- メッセージ出力
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.LOG
--        , buff   => lv_msg
--      );
-- 2011/11/24 del end Ver.1.6 対応時のPT実施に伴い削除

    ELSIF (ln_total_qty = 0) THEN
      -- 売上ゼロ時
      lv_supply_inst_specific_cd := cv_no_sales;
      ln_supply_instruction_pct := cn_default_supply_inst_pct;

    ELSIF (ln_workdays = 0) THEN
      -- 販売予測不可（稼働日日数が0）
      lv_supply_inst_specific_cd := cv_unpredictable;
      ln_supply_instruction_pct := cn_default_supply_inst_pct;
      ov_retcode := cv_status_warn;
      -- 稼働日日数なしエラーメッセージを出力
      -- メッセージ取得
      lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_xxcoi
                  , iv_name         => cv_no_workday_msg
                  , iv_token_name1  => cv_tkn_cust_code
                  , iv_token_value1 => it_xmvc_tbl_rec.cust_code
                  , iv_token_name2  => cv_tkn_column_no
                  , iv_token_value2 => it_xmvc_tbl_rec.column_no
                  , iv_token_name3  => cv_tkn_calendar_code
                  , iv_token_value3 => it_xmvc_tbl_rec.calendar_code
                  , iv_token_name4  => cv_tkn_from_date
                  , iv_token_value4 => TO_CHAR(ld_past_dlv_date, 'YYYY/MM/DD')
                  , iv_token_name5  => cv_tkn_to_date
                  , iv_token_value5 => TO_CHAR(ld_recent_dlv_date, 'YYYY/MM/DD')
                );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
      );

    ELSIF (ln_days_after_supply = 0) THEN
      -- 販売予測不可（前回納品後稼働日日数が0）
      lv_supply_inst_specific_cd := cv_unpredictable;
      ln_supply_instruction_pct := cn_default_supply_inst_pct;
      ov_retcode := cv_status_warn;
      -- 前回納品後稼働日日数なしエラーメッセージを出力
      -- メッセージ取得
      lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_xxcoi
                  , iv_name         => cv_no_days_after_supply_msg
                  , iv_token_name1  => cv_tkn_cust_code
                  , iv_token_value1 => it_xmvc_tbl_rec.cust_code
                  , iv_token_name2  => cv_tkn_column_no
                  , iv_token_value2 => it_xmvc_tbl_rec.column_no
                  , iv_token_name3  => cv_tkn_calendar_code
                  , iv_token_value3 => it_xmvc_tbl_rec.calendar_code
                  , iv_token_name4  => cv_tkn_from_date
                  , iv_token_value4 => TO_CHAR(ld_recent_dlv_date, 'YYYY/MM/DD')
                  , iv_token_name5  => cv_tkn_to_date
                  , iv_token_value5 => TO_CHAR(gd_process_date, 'YYYY/MM/DD')
                );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_msg
      );

    ELSE
      -- 補充指示
      lv_supply_inst_specific_cd := cv_supply_instruction;
--
      -- ===============================
      -- 予測算出 (A-10)
      -- ===============================
      forecast_calculation(
          ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
        , on_sales_forecast_qty => ln_sales_forecast_qty
        , ov_next_supply        => lv_next_supply
        , on_supply_inst_pct    => ln_supply_instruction_pct
        , in_total_qty          => ln_total_qty
        , in_workdays           => ln_workdays
        , in_days_after_supply  => ln_days_after_supply
        , in_inventory_quantity => it_xmvc_tbl_rec.inventory_quantity);
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    BEGIN
      -- 補充指示出力内容取得
      SELECT flv.attribute1 attribute1,    -- 補充指示
             flv.attribute5 attribute5     -- 販売予測数固定文字
-- 2012/01/17 V1.7 Add Start =======================================================================
            ,flv.attribute6 attribute6     -- 次回補充出力フラグ
-- 2012/01/17 V1.7 Add End   =======================================================================
      INTO  lv_supply_instruction,
            lv_sales_forecast_fix_val
-- 2012/01/17 V1.7 Add Start =======================================================================
           ,lv_next_supply_output_flag     -- 次回補充出力制御フラグ
-- 2012/01/17 V1.7 Add End   =======================================================================
      FROM  fnd_lookup_values flv
      WHERE flv.lookup_type = cv_lookup_type_supply_inst
      AND   flv.language = USERENV('LANG')
      AND   gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                            AND NVL(flv.end_date_active, gd_process_date)
      AND   flv.enabled_flag = cv_enable
      AND   flv.attribute4 = lv_supply_inst_specific_cd
      AND   ln_supply_instruction_pct BETWEEN flv.attribute2 AND flv.attribute3;
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_warn;
        -- メッセージ取得
        lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_get_supply_inst_err_msg
                    , iv_token_name1  => cv_tkn_cust_code
                    , iv_token_value1 => it_xmvc_tbl_rec.cust_code
                    , iv_token_name2  => cv_tkn_column_no
                    , iv_token_value2 => it_xmvc_tbl_rec.column_no
                    , iv_token_name3  => cv_tkn_lookup_type
                    , iv_token_value3 => cv_lookup_type_supply_inst
                    , iv_token_name4  => cv_tkn_supply_instruction
                    , iv_token_value4 => lv_supply_inst_specific_cd
                    , iv_token_name5  => cv_tkn_supply_inst_rate
                    , iv_token_value5 => ln_supply_instruction_pct
                  );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_msg
        );
    END;
--
    ov_sales_forecast_qty := NVL(lv_sales_forecast_fix_val, TO_CHAR(ln_sales_forecast_qty));
    ov_supply_instruction := lv_supply_instruction;
-- 2012/01/17 V1.7 Mod Start =======================================================================
--    ov_next_supply := lv_next_supply;
    IF (lv_next_supply_output_flag = cv_flag_value_output) THEN
      ov_next_supply := lv_next_supply;
    ELSE
      ov_next_supply := NULL;
    END IF;
-- 2012/01/17 V1.7 Mod End   =======================================================================
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END determine_sales_forecast_val;
--
-- 2011/10/03 V1.6 ADD END   =======================================================================
  /**********************************************************************************
   * Procedure Name   : create_csv_file
   * Description      : ベンダ在庫マスタCSV作成(A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_file(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_file'; -- プログラム名
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
    cv_delimiter             CONSTANT VARCHAR2(1) := ',';  -- 区切り文字
    cv_encloser              CONSTANT VARCHAR2(1) := '"';  -- 括り文字
--
    -- *** ローカル変数 ***
    lv_csv_file              VARCHAR2(1500);               -- CSVファイル
    lv_column_no             VARCHAR2(100);                -- コラムNO.
    lv_price                 VARCHAR2(100);                -- 単価
    lv_inventory_quantity    VARCHAR2(100);                -- 満タン数
    lv_last_update_date      VARCHAR2(100);                -- 最終更新日
-- 2011/10/03 V1.6 ADD START =======================================================================
    lv_sales_forecast_qty    fnd_lookup_values.attribute5%TYPE;  -- 販売予測数
    lv_next_supply           VARCHAR2(10);                       -- 次回補充
    lv_supply_instruction    fnd_lookup_values.attribute1%TYPE;  -- 補充指示
-- 2011/10/03 V1.6 ADD END   =======================================================================
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
    -- ===============================
    -- ループ開始
    -- ===============================
-- == 2009/09/14 V1.1 Modified START ===============================================================
--    <<create_file_loop>>
--    FOR i IN 1 .. g_get_xmvc_tbl_tab.COUNT LOOP
--      lv_column_no          := TO_CHAR( g_get_xmvc_tbl_tab(i).column_no );                                -- コラムNo.
--      lv_price              := TO_CHAR( g_get_xmvc_tbl_tab(i).price );                                    -- 単価
--      lv_inventory_quantity := TO_CHAR( g_get_xmvc_tbl_tab(i).inventory_quantity );                       -- 満タン数
--      lv_last_update_date   := TO_CHAR( g_get_xmvc_tbl_tab(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS' );-- 更新日時
----
--      -- CSVデータを作成
--      lv_csv_file := (
--        cv_encloser || g_get_xmvc_tbl_tab(i).cust_code || cv_encloser || cv_delimiter ||  -- 顧客コード
--        cv_encloser || lv_column_no                    || cv_encloser || cv_delimiter ||  -- コラムNo.
--        cv_encloser || g_get_xmvc_tbl_tab(i).item_code || cv_encloser || cv_delimiter ||  -- 品目コード
--                       lv_price                                       || cv_delimiter ||  -- 単価
--                       lv_inventory_quantity                          || cv_delimiter ||  -- 満タン数
--        cv_encloser || g_get_xmvc_tbl_tab(i).hot_cold  || cv_encloser || cv_delimiter ||  -- H/C
--        cv_encloser || g_get_xmvc_tbl_tab(i).del_flag  || cv_encloser || cv_delimiter ||  -- 削除フラグ
--        cv_encloser || lv_last_update_date             || cv_encloser                     -- 更新日時
--      );
----
--      -- ===============================
--      -- CSVデータを出力
--      -- ===============================
--      UTL_FILE.PUT_LINE(
--          file   => g_file_handle
--        , buffer => lv_csv_file
--      );
----
--      -- ===============================
--      -- 成功件数カウント
--      -- ===============================
--      gn_normal_cnt := gn_normal_cnt + 1;
----
--    END LOOP create_file_loop;
--
    OPEN  get_xmvc_tbl_cur1;
    OPEN  get_xmvc_tbl_cur2;
-- 2011/10/03 V1.6 ADD START =======================================================================
    OPEN  get_xmvc_tbl_cur3;
-- 2011/10/03 V1.6 ADD END   =======================================================================
    --
    <<cursor_loop>>
-- 2011/10/03 V1.6 MOD START =======================================================================
--    FOR i IN  1 .. 2  LOOP
    FOR i IN  1 .. 3  LOOP
-- 2011/10/03 V1.6 MOD END   =======================================================================
      <<create_file_loop>>
      LOOP
        IF (i = 1) THEN
          FETCH get_xmvc_tbl_cur1 INTO  get_xmvc_tbl_rec;
          EXIT WHEN get_xmvc_tbl_cur1%NOTFOUND;
-- 2011/10/03 V1.6 MOD START =======================================================================
--        ELSE
        ELSIF (i = 2) THEN
-- 2011/10/03 V1.6 MOD END   =======================================================================
          FETCH get_xmvc_tbl_cur2 INTO  get_xmvc_tbl_rec;
          EXIT WHEN get_xmvc_tbl_cur2%NOTFOUND;
-- 2011/10/03 V1.6 ADD START =======================================================================
        ELSE
          FETCH get_xmvc_tbl_cur3 INTO  get_xmvc_tbl_rec;
          EXIT WHEN get_xmvc_tbl_cur3%NOTFOUND;
          --
          -- 変数初期化
          lv_sales_forecast_qty := NULL;
          lv_next_supply        := NULL;
          lv_supply_instruction := NULL;
          -- ===============================
          -- 販売予測項目値決定 (A-9)
          -- ===============================
          determine_sales_forecast_val(
              ov_errbuf             => lv_errbuf
            , ov_retcode            => lv_retcode
            , ov_errmsg             => lv_errmsg
            , ov_sales_forecast_qty => lv_sales_forecast_qty
            , ov_supply_instruction => lv_supply_instruction
            , ov_next_supply        => lv_next_supply
            , it_xmvc_tbl_rec       => get_xmvc_tbl_rec);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_api_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            -- 販売予測項目値決定（A-9）が警告終了の場合、警告数カウントアップ
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
--
-- 2011/10/03 V1.6 ADD END   =======================================================================
        END IF;
        --
        lv_column_no          := TO_CHAR( get_xmvc_tbl_rec.column_no );                                -- コラムNo.
        lv_price              := TO_CHAR( get_xmvc_tbl_rec.price );                                    -- 単価
        lv_inventory_quantity := TO_CHAR( get_xmvc_tbl_rec.inventory_quantity );                       -- 満タン数
        lv_last_update_date   := TO_CHAR( get_xmvc_tbl_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS' );-- 更新日時
  --
-- == 2010/12/28 V1.4 ADD START  ===============================================================
        IF (lv_inventory_quantity IS NULL) THEN
          lv_inventory_quantity := cv_qty_zero;
          --
          gv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_xxcoi
                          , iv_name         => cv_qty_null_err_msg
                          , iv_token_name1  => cv_tkn_cust_code
                          , iv_token_value1 => get_xmvc_tbl_rec.cust_code
                          , iv_token_name2  => cv_tkn_column_no
                          , iv_token_value2 => lv_column_no
                        );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => gv_out_msg
          );
          --
          -- 警告件数カウント
          gn_warn_cnt := gn_warn_cnt + 1 ;
        END IF;
-- == 2010/12/28 V1.4 ADD END    ===============================================================
        -- CSVデータを作成
        lv_csv_file := (
          cv_encloser || get_xmvc_tbl_rec.cust_code || cv_encloser || cv_delimiter ||  -- 顧客コード
          cv_encloser || lv_column_no               || cv_encloser || cv_delimiter ||  -- コラムNo.
          cv_encloser || get_xmvc_tbl_rec.item_code || cv_encloser || cv_delimiter ||  -- 品目コード
                         lv_price                                  || cv_delimiter ||  -- 単価
                         lv_inventory_quantity                     || cv_delimiter ||  -- 満タン数
          cv_encloser || get_xmvc_tbl_rec.hot_cold  || cv_encloser || cv_delimiter ||  -- H/C
          cv_encloser || get_xmvc_tbl_rec.del_flag  || cv_encloser || cv_delimiter ||  -- 削除フラグ
          cv_encloser || lv_last_update_date        || cv_encloser                     -- 更新日時
-- 2011/10/03 V1.6 ADD START =======================================================================
                                                                   || cv_delimiter ||
          cv_encloser || lv_sales_forecast_qty      || cv_encloser || cv_delimiter ||  -- 販売予測数
          cv_encloser || lv_supply_instruction      || cv_encloser || cv_delimiter ||  -- 補充指示
          cv_encloser || lv_next_supply             || cv_encloser                     -- 次回補充
-- 2011/10/03 V1.6 ADD END   =======================================================================
        );
  --
        -- ===============================
        -- CSVデータを出力
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => g_file_handle
          , buffer => lv_csv_file
        );
  --
        -- ===============================
        -- 成功件数カウント
        -- ===============================
        gn_target_cnt :=  gn_target_cnt + 1;
        gn_normal_cnt :=  gn_normal_cnt + 1;
      END LOOP create_file_loop;
    END LOOP cursor_loop;
    --
    CLOSE  get_xmvc_tbl_cur1;
    CLOSE  get_xmvc_tbl_cur2;
-- 2011/10/03 V1.6 ADD START =======================================================================
    CLOSE  get_xmvc_tbl_cur3;
-- 2011/10/03 V1.6 ADD END   =======================================================================
    --
    -- ===============================
    -- 抽出0件チェック
    -- ===============================
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_no_data_msg
                    );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
    END IF;
-- == 2009/09/14 V1.1 Modified START ===============================================================
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- == 2009/09/14 V1.1 Added START ===============================================================
      IF (get_xmvc_tbl_cur1%ISOPEN) THEN
        CLOSE get_xmvc_tbl_cur1;
      END IF;
      --
      IF (get_xmvc_tbl_cur2%ISOPEN) THEN
-- 2011/10/03 V1.6 MOD START =======================================================================
--        CLOSE get_xmvc_tbl_cur1;
        CLOSE get_xmvc_tbl_cur2;
-- 2011/10/03 V1.6 MOD END   =======================================================================
      END IF;
-- == 2009/09/14 V1.1 Added END   ===============================================================
-- 2011/10/03 V1.6 ADD START =======================================================================
      IF (get_xmvc_tbl_cur3%ISOPEN) THEN
        CLOSE get_xmvc_tbl_cur3;
      END IF;
-- 2011/10/03 V1.6 ADD END   =======================================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : upd_last_coop_date
   * Description      : データ連携制御ワークテーブルの最終連携日時更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_last_coop_date(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_coop_date'; -- プログラム名
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
    -- ==============================================================
    -- データ連携制御ワークテーブル更新処理
    -- ==============================================================
    UPDATE   xxcoi_cooperation_control    xcc
    SET      xcc.last_cooperation_date  = gd_sysdate                 -- 最終連携日時
           , xcc.last_update_date       = cd_last_update_date        -- 最終更新日
           , xcc.last_updated_by        = cn_last_updated_by         -- 最終更新者
           , xcc.last_update_login      = cn_last_update_login       -- 最終更新者ログイン
           , xcc.request_id             = cn_request_id              -- 要求ID
           , xcc.program_application_id = cn_program_application_id  -- アプリケーションID
           , xcc.program_id             = cn_program_id              -- プログラムID
           , xcc.program_update_date    = cd_program_update_date     -- プログラム更新日時
    WHERE    xcc.program_id             = cn_program_id;             -- 更新条件：プログラムID
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END upd_last_coop_date;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_open_mode    CONSTANT VARCHAR2(1) := 'w';  -- オープンモード：書き込み
--
    -- *** ローカル変数 ***
    ln_file_length  NUMBER;                       -- ファイルの長さの変数
    ln_block_size   NUMBER;                       -- ブロックサイズの変数
    lb_fexists      BOOLEAN;                      -- ファイル存在チェック結果
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
-- == 2010/12/28 V1.4 ADD START  ===============================================================
    gn_warn_cnt   := 0;
-- == 2010/12/28 V1.4 ADD END    ===============================================================
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- データ連携制御ワークテーブルの最終連携日時取得 (A-2)
    -- ==============================================================
    get_last_coop_date(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTLファイルオープン (A-3)
    -- ===============================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR(
        location    => gv_dire_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    IF( lb_fexists = TRUE ) THEN
      RAISE remain_file_expt;
    END IF;
--
    -- ファイルのオープン
    g_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dire_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
-- == 2009/09/14 V1.1 Deleted START ===============================================================
--    -- ===============================
--    -- VDコラムマスタ情報抽出 (A-4)
--    -- ===============================
--    get_mst_vd_column(
--        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
--      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
--      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
--    );
----
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
-- == 2009/09/14 V1.1 Deleted END   ===============================================================
--
    -- ===============================
    -- ベンダ在庫マスタCSV作成 (A-5)
    -- ===============================
    create_csv_file(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が1件以上の場合
    IF ( gn_target_cnt > 0 ) THEN
--
      -- ==============================================================
      -- データ連携制御ワークテーブルの最終連携日時更新 (A-6)
      -- ==============================================================
      upd_last_coop_date(
          ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- UTLファイルクローズ (A-7)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
--
  EXCEPTION
--
    -- *** ファイル存在チェックエラー ***
    WHEN remain_file_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_remain_err_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => gv_file_name
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- ファイルがOPENしている場合
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
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
      errbuf              OUT VARCHAR2       --   エラー・メッセージ  --# 固定 #
    , retcode             OUT VARCHAR2       --   リターン・コード    --# 固定 #
    , iv_night_exec_flag  IN  VARCHAR2)      --   夜間実行フラグ
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
-- == 2010/12/28 V1.4 ADD START  ===============================================================
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
-- == 2010/12/28 V1.4 ADD END    ===============================================================
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- パラメータの夜間実行フラグをグローバル変数に格納
    SELECT DECODE( iv_night_exec_flag
                 , cv_night_exec_flag_y
                 , cv_night_exec_flag_y
                 , cv_night_exec_flag_n )
    INTO   gv_night_exec_flag
    FROM   DUAL;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラーの場合、成功件数の初期化とエラー件数のセット
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
-- 2011/10/03 V1.6 ADD START =======================================================================
      gn_target_cnt := 0;
      gn_warn_cnt   := 0;
-- 2011/10/03 V1.6 ADD END   =======================================================================
      --エラー出力
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg       -- ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf       -- エラーメッセージ
      );
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
-- == 2010/12/28 V1.4 MOD START  ===============================================================
--                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt - gn_warn_cnt )
-- == 2010/12/28 V1.4 MOD END    ===============================================================
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
-- == 2010/12/28 V1.4 ADD START  ===============================================================
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_warn_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
-- == 2010/12/28 V1.4 ADD END    ===============================================================
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
-- == 2010/12/28 V1.4 MOD START  ===============================================================
      IF ( gn_warn_cnt <> 0 ) THEN
        lv_message_code := cv_warn_msg;
        lv_retcode := cv_status_warn;
      ELSE
        lv_message_code := cv_normal_msg;
      END IF;
-- == 2010/12/28 V1.4 MOD END    ===============================================================
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
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
END XXCOI010A03C;
/
