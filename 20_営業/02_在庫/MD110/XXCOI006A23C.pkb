CREATE OR REPLACE PACKAGE BODY XXCOI006A23C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A23C(body)
 * Description      : VD受払情報を元に、CSVデータを作成します。
 * MD.050           : VD受払CSV作成<MD050_COI_006_A23>
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  out_csv_company_total  VD受払CSVデータ抽出                  (A-3)
 *                         VD受払CSV編集・要求出力              (A-4)
 *  out_csv_base_total     VD受払CSVデータ抽出                  (A-3)
 *                         VD受払CSV編集・要求出力              (A-4)
 *  out_csv_base           VD受払CSVデータ抽出                  (A-3)
 *                         VD受払CSV編集・要求出力              (A-4)
 *  chk_parameter          パラメータチェック                   (A-2)
 *  init                   初期処理                             (A-1)
 *  submain                メイン処理プロシージャ
 *                         終了処理                             (A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/10    1.0   H.Sasaki         初版作成
 *  2009/07/14    1.1   N.Abe            [0000462]群コード取得方法修正
 *  2009/09/08    1.2   H.Sasaki         [0001266]OPM品目アドオンの版管理対応
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
  csv_no_data_expt          EXCEPTION;      -- CSV対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A23C'; -- パッケージ名
  -- 日付型
  cv_date               CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
  -- 参照タイプ
  cv_type_output_div    CONSTANT VARCHAR2(30) :=  'XXCOI1_VD_REP_OUTPUT_DIV';       -- VD受払表出力区分
  cv_type_cost_price    CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';          -- 原価区分
  cv_type_list_header   CONSTANT VARCHAR2(30) :=  'XXCOI1_VD_IN_OUT_LIST_HEADER';   -- VD受払表見出し
  -- VD受払表出力区分（1:拠点別、2：拠点別計、3：全社計）
  cv_output_div_1       CONSTANT VARCHAR2(3)  :=  '1';
  cv_output_div_2       CONSTANT VARCHAR2(3)  :=  '2';
  cv_output_div_3       CONSTANT VARCHAR2(3)  :=  '3';
  -- 原価区分（10:営業原価、20：標準原価）
  cv_cost_price_10      CONSTANT VARCHAR2(2)  :=  '10';
  cv_cost_price_20      CONSTANT VARCHAR2(2)  :=  '20';
  -- VD受払表見出し
  cv_list_header_1      CONSTANT VARCHAR2(1)  :=  '1';
  -- メッセージ関連
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00008   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00008';     -- 対象データ無しメッセージ
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';     -- 業務日付取得エラーメッセージ
  cv_msg_xxcoi1_10098   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10098';     -- パラメータ出力区分値メッセージ
  cv_msg_xxcoi1_10107   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10107';     -- パラメータ受払年月値メッセージ
  cv_msg_xxcoi1_10108   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10108';     -- パラメータ原価区分値メッセージ
  cv_msg_xxcoi1_10109   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10109';     -- パラメータ拠点値メッセージ
  cv_msg_xxcoi1_10110   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10110';     -- 受払年月の型（YYYYMM）チェックエラーメッセージ
  cv_msg_xxcoi1_10111   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10111';     -- 受払年月未来日チェックエラーメッセージ
  cv_msg_xxcoi1_10113   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10113';     -- パラメータ.出力区分名取得エラーメッセージ
  cv_msg_xxcoi1_10114   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10114';     -- パラメータ.原価区分名取得エラーメッセージ
  cv_msg_xxcoi1_10370   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10370';     -- 見出し情報取得エラーメッセージ
  cv_token_10098_1      CONSTANT VARCHAR2(30) :=  'P_OUT_TYPE';
  cv_token_10107_1      CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';
  cv_token_10108_1      CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';
  cv_token_10109_1      CONSTANT VARCHAR2(30) :=  'P_BASE_CODE';
  -- その他
  cv_log                CONSTANT VARCHAR2(3)  :=  'LOG';                  -- コンカレントヘッダ出力先
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';                    -- 半角スペース１桁
  cv_class_base         CONSTANT VARCHAR2(1)  :=  '1';                    -- 顧客区分：拠点
  cv_status_active      CONSTANT VARCHAR2(1)  :=  'A';                    -- 顧客ステータス：Active
  cv_separate_code      CONSTANT VARCHAR2(1)  :=  ',';                    -- 区切り文字（カンマ）
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE csv_data_type  IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;
  gt_csv_data         csv_data_type;                  -- CSVデータ
  TYPE csv_total_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_key_total        csv_total_type;                 -- キー項目計
  gt_key2_total       csv_total_type;                 -- キー項目計2
  gt_total            csv_total_type;                 -- 合計
  gr_lookup_values   xxcoi_common_pkg.lookup_rec;     -- クイックコードマスタ情報格納レコード
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 起動パラメータ
  gv_param_output_kbn         VARCHAR2(3);        -- 受払表出力区分
  gv_param_reception_date     VARCHAR2(6);        -- 受払年月
  gv_param_cost_kbn           VARCHAR2(2);        -- 原価区分
  gv_param_base_code          VARCHAR2(4);        -- 拠点
  -- 初期処理設定値
  gd_f_process_date           DATE;               -- 業務処理日付
  gt_output_name              fnd_lookup_values.meaning%TYPE;     -- 受払表出力区分名
  gt_cost_kbn_name            fnd_lookup_values.meaning%TYPE;     -- 原価区分名
-- == 2009/07/13 V1.1 Added START ===============================================================
  gd_target_date              DATE;
-- == 2009/07/13 V1.1 Added END   ===============================================================
--
  -- ===============================
  -- カーソル定義
  -- ===============================
  -- VD受払CSVデータ抽出（拠点別、拠点別計）
  CURSOR  base_cur
  IS
    SELECT  xvri.base_code                    base_code                         -- 拠点コード
           ,xvri.practice_date                practice_date                     -- 年月
           ,xvri.month_begin_quantity         month_begin_quantity              -- 月首在庫
           ,xvri.vd_stock                     vd_stock                          -- ベンダ入庫
           ,xvri.vd_move_stock                vd_move_stock                     -- ベンダ移動入庫
           ,xvri.vd_ship                      vd_ship                           -- ベンダ出庫
           ,xvri.vd_move_ship                 vd_move_ship                      -- ベンダ移動出庫
           ,xvri.month_end_book_remain_qty    month_end_book_remain_qty         -- 月末帳簿残
           ,xvri.month_end_quantity           month_end_quantity                -- 月末在庫
           ,xvri.inv_wear_account             inv_wear_account                  -- 棚卸減耗費
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_begin_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_begin_quantity)
            END                               month_begin_money                 -- 月首在庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_stock)
            END                               vd_stock_money                    -- ベンダ入庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_stock)
            END                               vd_move_stock_money               -- ベンダ移動入庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_ship)
            END                               vd_ship_money                     -- ベンダ出庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_ship)
            END                               vd_move_ship_money                -- ベンダ移動出庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_book_remain_qty)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_book_remain_qty)
            END                               month_end_book_remain_money       -- 月末帳簿残（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_quantity)
            END                               month_end_money                   -- 月末在庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.inv_wear_account)
              ELSE ROUND(xvri.standard_cost  * xvri.inv_wear_account)
            END                               inv_wear_account_money            -- 棚卸減耗費（金額）
           ,hca.account_name                  account_name                      -- 拠点名
-- == 2009/07/13 V1.1 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)     gun_code                          -- 群コード
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                      -- 群コード(旧)
                      ELSE iimb.attribute2                                      -- 群コード(新)
                    END
              ), 1, 3
            )                                 gun_code                          -- 群コード
-- == 2009/07/13 V1.1 Modified END   ===============================================================
           ,msib.segment1                     segment1                          -- 商品コード
           ,ximb.item_short_name              item_short_name                   -- 品名
    FROM    xxcoi_vd_reception_info       xvri                                  -- VD受払情報テーブル
           ,hz_cust_accounts              hca                                   -- 顧客マスタ
           ,mtl_system_items_b            msib                                  -- Disc品目マスタ
           ,ic_item_mst_b                 iimb                                  -- OPM品目
           ,xxcmn_item_mst_b              ximb                                  -- OPM品目アドオン
    WHERE   ((    (gv_param_base_code IS NOT NULL)
              AND (xvri.base_code = gv_param_base_code)
             )
             OR
             (gv_param_base_code IS NULL)
            )
    AND     xvri.practice_date        =   gv_param_reception_date
    AND     xvri.base_code            =   hca.account_number
    AND     hca.customer_class_code   =   cv_class_base
    AND     hca.status                =   cv_status_active
    AND     xvri.inventory_item_id    =   msib.inventory_item_id
    AND     xvri.organization_id      =   msib.organization_id
    AND     msib.segment1             =   iimb.item_no
    AND     iimb.item_id              =   ximb.item_id
-- == 2009/09/08 V1.2 Added START ===============================================================
    AND     gd_target_date  BETWEEN ximb.start_date_active
                            AND     NVL(ximb.end_date_active, gd_target_date)
-- == 2009/09/08 V1.2 Added END   ===============================================================
    ORDER BY  xvri.base_code
             ,iimb.attribute2
             ,msib.segment1;
  --
  -- VD受払CSVデータ抽出（全社計）
  CURSOR  company_cur
  IS
    SELECT  xvri.base_code                    base_code                         -- 拠点コード
           ,xvri.practice_date                practice_date                     -- 年月
           ,xvri.month_begin_quantity         month_begin_quantity              -- 月首在庫
           ,xvri.vd_stock                     vd_stock                          -- ベンダ入庫
           ,xvri.vd_move_stock                vd_move_stock                     -- ベンダ移動入庫
           ,xvri.vd_ship                      vd_ship                           -- ベンダ出庫
           ,xvri.vd_move_ship                 vd_move_ship                      -- ベンダ移動出庫
           ,xvri.month_end_book_remain_qty    month_end_book_remain_qty         -- 月末帳簿残
           ,xvri.month_end_quantity           month_end_quantity                -- 月末在庫
           ,xvri.inv_wear_account             inv_wear_account                  -- 棚卸減耗費
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_begin_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_begin_quantity)
            END                               month_begin_money                 -- 月首在庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_stock)
            END                               vd_stock_money                    -- ベンダ入庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_stock)
            END                               vd_move_stock_money               -- ベンダ移動入庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_ship)
            END                               vd_ship_money                     -- ベンダ出庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_ship)
            END                               vd_move_ship_money                -- ベンダ移動出庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_book_remain_qty)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_book_remain_qty)
            END                               month_end_book_remain_money       -- 月末帳簿残（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_quantity)
            END                               month_end_money                   -- 月末在庫（金額）
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.inv_wear_account)
              ELSE ROUND(xvri.standard_cost  * xvri.inv_wear_account)
            END                               inv_wear_account_money            -- 棚卸減耗費（金額）
           ,hca.account_name                  account_name                      -- 拠点名
-- == 2009/07/14 V1.1 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)     gun_code                          -- 群コード
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                      -- 群コード(旧)
                      ELSE iimb.attribute2                                      -- 群コード(新)
                    END
              ), 1, 3
            )                                 gun_code                          -- 群コード
-- == 2009/07/14 V1.1 Modified END   ===============================================================
           ,msib.segment1                     segment1                          -- 商品コード
           ,ximb.item_short_name              item_short_name                   -- 品名
    FROM    xxcoi_vd_reception_info       xvri                                  -- VD受払情報テーブル
           ,hz_cust_accounts              hca                                   -- 顧客マスタ
           ,mtl_system_items_b            msib                                  -- Disc品目マスタ
           ,ic_item_mst_b                 iimb                                  -- OPM品目
           ,xxcmn_item_mst_b              ximb                                  -- OPM品目アドオン
    WHERE   ((    (gv_param_base_code IS NOT NULL)
              AND (xvri.base_code = gv_param_base_code)
             )
             OR
             (gv_param_base_code IS NULL)
            )
    AND     xvri.practice_date        =   gv_param_reception_date
    AND     xvri.base_code            =   hca.account_number
    AND     hca.customer_class_code   =   cv_class_base
    AND     hca.status                =   cv_status_active
    AND     xvri.inventory_item_id    =   msib.inventory_item_id
    AND     xvri.organization_id      =   msib.organization_id
    AND     msib.segment1             =   iimb.item_no
    AND     iimb.item_id              =   ximb.item_id
-- == 2009/09/08 V1.2 Added START ===============================================================
    AND     gd_target_date  BETWEEN ximb.start_date_active
                            AND     NVL(ximb.end_date_active, gd_target_date)
-- == 2009/09/08 V1.2 Added END   ===============================================================
    ORDER BY  iimb.attribute2
             ,msib.segment1;
    --
    --
  vd_data_rec      base_cur%ROWTYPE;
  --
  --
  /**********************************************************************************
   * Procedure Name   : out_csv_company_total
   * Description      : VD受払CSV編集・要求出力（全社計）(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_company_total(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_company_total'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt              NUMBER;                                 -- CSVレコード行番号
    lt_segment1         mtl_system_items_b.segment1%TYPE;       -- レコード変更チェックキー項目（品目コード）
    lv_gun_code         VARCHAR2(3);                            -- レコード変更チェックキー項目（群コード）
    lt_item_short_name  xxcmn_item_mst_b.item_short_name%TYPE;  -- 品名
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --
    OPEN  company_cur;
    FETCH company_cur  INTO  vd_data_rec;
    --
    IF (company_cur%NOTFOUND) THEN
      -- 対象データ無しメッセージ
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- 対象データが取得されなかった場合、処理を終了
      CLOSE company_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  １行目編集（ヘッダ情報）
    -- ===================================
    gt_csv_data(1)  :=     SUBSTRB(gv_param_reception_date, 3, 2)     -- 受払年月（年）
                        || gr_lookup_values.attribute1                -- 見出し１
                        || SUBSTRB(gv_param_reception_date, 5, 2)     -- 受払年月（月）
                        || gr_lookup_values.attribute2                -- 見出し２
                        || cv_separate_code
                        || gr_lookup_values.attribute3                -- 見出し３
                        || cv_separate_code
                        || gt_output_name                             -- 受払出力区分名
                        || cv_separate_code
                        || gt_cost_kbn_name;                          -- 原価区分名
    --
    -- ===================================
    --  ２行目編集（項目名）
    -- ===================================
    gt_csv_data(2)  :=      gr_lookup_values.attribute8               -- 見出し８
                        ||  gr_lookup_values.attribute9               -- 見出し９
                        ||  gr_lookup_values.attribute10              -- 見出し１０
                        ||  gr_lookup_values.attribute11;             -- 見出し１１
    --
    -- ===================================
    --  ３行目以降編集（数値データ）
    -- ===================================
    ln_cnt  :=  3;
    --
    <<set_csv_base_loop>>
    LOOP
      -- 品目計設定
      IF (    (lt_segment1 IS NOT NULL)
          AND (    (vd_data_rec.segment1 <>  lt_segment1)
               OR  (company_cur%NOTFOUND)
              )
         )
      THEN
        -- 品目コードが変った場合、又は最終レコードの場合
        gt_csv_data(ln_cnt) :=     lv_gun_code                      -- 群コード
                                || cv_separate_code
                                || lt_segment1                      -- 品目コード
                                || cv_separate_code
                                || lt_item_short_name               -- 品名
                                || cv_separate_code
                                || gt_key_total(1)                  -- 月首在庫
                                || cv_separate_code
                                || gt_key_total(2)                  -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_key_total(3)                  -- ベンダ入庫
                                || cv_separate_code
                                || gt_key_total(4)                  -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_key_total(5)                  -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_key_total(6)                  -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_key_total(7)                  -- ベンダ出庫
                                || cv_separate_code
                                || gt_key_total(8)                  -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_key_total(9)                  -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_key_total(10)                 -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_key_total(11)                 -- 月末帳簿残
                                || cv_separate_code
                                || gt_key_total(12)                 -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_key_total(13)                 -- 月末在庫
                                || cv_separate_code
                                || gt_key_total(14)                 -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_key_total(15)                 -- 棚卸減耗費
                                || cv_separate_code
                                || gt_key_total(16);                -- 棚卸減耗費（金額）
        --
        -- 変数カウントアップ
        ln_cnt  :=  ln_cnt + 1;
        --
        -- 拠点計初期化
        FOR i IN 1 .. 16 LOOP
          gt_key_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 群計設定
      IF (    (lv_gun_code IS NOT NULL)
          AND (    (vd_data_rec.gun_code <>  lv_gun_code)
               OR  (company_cur%NOTFOUND)
              )
         )
      THEN
        -- 群コードが変った場合、又は最終レコードの場合
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute4      -- 見出し４
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_key2_total(1)                 -- 月首在庫
                                || cv_separate_code
                                || gt_key2_total(2)                 -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_key2_total(3)                 -- ベンダ入庫
                                || cv_separate_code
                                || gt_key2_total(4)                 -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_key2_total(5)                 -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_key2_total(6)                 -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_key2_total(7)                 -- ベンダ出庫
                                || cv_separate_code
                                || gt_key2_total(8)                 -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_key2_total(9)                 -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_key2_total(10)                -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_key2_total(11)                -- 月末帳簿残
                                || cv_separate_code
                                || gt_key2_total(12)                -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_key2_total(13)                -- 月末在庫
                                || cv_separate_code
                                || gt_key2_total(14)                -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_key2_total(15)                -- 棚卸減耗費
                                || cv_separate_code
                                || gt_key2_total(16);               -- 棚卸減耗費（金額）
        --
        -- 変数カウントアップ
        ln_cnt  :=  ln_cnt + 1;
        --
        -- 拠点計初期化
        FOR i IN 1 .. 16 LOOP
          gt_key2_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 合計設定
      IF (company_cur%NOTFOUND) THEN
        -- 最終レコードの場合
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute5      -- 見出し５
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_total(1)                      -- 月首在庫
                                || cv_separate_code
                                || gt_total(2)                      -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_total(3)                      -- ベンダ入庫
                                || cv_separate_code
                                || gt_total(4)                      -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_total(5)                      -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_total(6)                      -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_total(7)                      -- ベンダ出庫
                                || cv_separate_code
                                || gt_total(8)                      -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_total(9)                      -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_total(10)                     -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_total(11)                     -- 月末帳簿残
                                || cv_separate_code
                                || gt_total(12)                     -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_total(13)                     -- 月末在庫
                                || cv_separate_code
                                || gt_total(14)                     -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_total(15)                     -- 棚卸減耗費
                                || cv_separate_code
                                || gt_total(16);                    -- 棚卸減耗費（金額）
        --
      END IF;
      --
      -- 終了判定
      EXIT set_csv_base_loop  WHEN  company_cur%NOTFOUND;
      --
      -- 品目計取得
      gt_key_total(1)   :=  gt_key_total(1)   +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_key_total(2)   :=  gt_key_total(2)   +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_key_total(3)   :=  gt_key_total(3)   +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_key_total(4)   :=  gt_key_total(4)   +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_key_total(5)   :=  gt_key_total(5)   +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_key_total(6)   :=  gt_key_total(6)   +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_key_total(7)   :=  gt_key_total(7)   +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_key_total(8)   :=  gt_key_total(8)   +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_key_total(9)   :=  gt_key_total(9)   +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_key_total(10)  :=  gt_key_total(10)  +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_key_total(11)  :=  gt_key_total(11)  +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_key_total(12)  :=  gt_key_total(12)  +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_key_total(13)  :=  gt_key_total(13)  +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_key_total(14)  :=  gt_key_total(14)  +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_key_total(15)  :=  gt_key_total(15)  +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_key_total(16)  :=  gt_key_total(16)  +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- 群計取得
      gt_key2_total(1)  :=  gt_key2_total(1)  +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_key2_total(2)  :=  gt_key2_total(2)  +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_key2_total(3)  :=  gt_key2_total(3)  +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_key2_total(4)  :=  gt_key2_total(4)  +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_key2_total(5)  :=  gt_key2_total(5)  +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_key2_total(6)  :=  gt_key2_total(6)  +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_key2_total(7)  :=  gt_key2_total(7)  +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_key2_total(8)  :=  gt_key2_total(8)  +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_key2_total(9)  :=  gt_key2_total(9)  +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_key2_total(10) :=  gt_key2_total(10) +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_key2_total(11) :=  gt_key2_total(11) +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_key2_total(12) :=  gt_key2_total(12) +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_key2_total(13) :=  gt_key2_total(13) +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_key2_total(14) :=  gt_key2_total(14) +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_key2_total(15) :=  gt_key2_total(15) +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_key2_total(16) :=  gt_key2_total(16) +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- 合計取得
      gt_total(1)       :=  gt_total(1)       +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_total(2)       :=  gt_total(2)       +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_total(3)       :=  gt_total(3)       +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_total(4)       :=  gt_total(4)       +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_total(5)       :=  gt_total(5)       +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_total(6)       :=  gt_total(6)       +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_total(7)       :=  gt_total(7)       +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_total(8)       :=  gt_total(8)       +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_total(9)       :=  gt_total(9)       +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_total(10)      :=  gt_total(10)      +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_total(11)      :=  gt_total(11)      +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_total(12)      :=  gt_total(12)      +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_total(13)      :=  gt_total(13)      +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_total(14)      :=  gt_total(14)      +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_total(15)      :=  gt_total(15)      +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_total(16)      :=  gt_total(16)      +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- レコード変更チェック用変数保持
      lt_segment1         :=  vd_data_rec.segment1;
      lv_gun_code         :=  vd_data_rec.gun_code;
      lt_item_short_name  :=  vd_data_rec.item_short_name;
      --
      -- 処理件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- データ取得
      FETCH company_cur  INTO  vd_data_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE company_cur;
    --
    -- ===================================
    --  CSV出力
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** CSV対象データなし例外 ***
    WHEN csv_no_data_expt THEN
      -- 正常で、本プロシージャを終了
      NULL;
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
      IF (company_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END out_csv_company_total;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_base_total
   * Description      : VD受払CSV編集・要求出力（拠点別計）(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_base_total(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_base_total'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt        NUMBER;                                 -- CSVレコード行番号
    lt_base_code  xxcoi_vd_reception_info.base_code%TYPE; -- レコード変更チェックキー項目（拠点コード）
    lt_base_name  hz_cust_accounts.account_name%TYPE;     -- 拠点名
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --
    OPEN  base_cur;
    FETCH base_cur  INTO  vd_data_rec;
    --
    IF (base_cur%NOTFOUND) THEN
      -- 対象データ無しメッセージ
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- 対象データが取得されなかった場合、処理を終了
      CLOSE base_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  １行目編集（ヘッダ情報）
    -- ===================================
    gt_csv_data(1)  :=     SUBSTRB(gv_param_reception_date, 3, 2)     -- 受払年月（年）
                        || gr_lookup_values.attribute1                -- 見出し１
                        || SUBSTRB(gv_param_reception_date, 5, 2)     -- 受払年月（月）
                        || gr_lookup_values.attribute2                -- 見出し２
                        || cv_separate_code
                        || gr_lookup_values.attribute3                -- 見出し３
                        || cv_separate_code
                        || gt_output_name                             -- 受払出力区分名
                        || cv_separate_code
                        || gt_cost_kbn_name;                          -- 原価区分名
    --
    -- ===================================
    --  ２行目編集（項目名）
    -- ===================================
    gt_csv_data(2)  :=      gr_lookup_values.attribute7               -- 見出し７
                        ||  gr_lookup_values.attribute9               -- 見出し９
                        ||  gr_lookup_values.attribute10              -- 見出し１０
                        ||  gr_lookup_values.attribute11;             -- 見出し１１
    --
    -- ===================================
    --  ３行目以降編集（数値データ）
    -- ===================================
    ln_cnt  :=  3;
    --
    <<set_csv_base_loop>>
    LOOP
      -- 拠点計設定
      IF (    (lt_base_code IS NOT NULL)
          AND (    (vd_data_rec.base_code <>  lt_base_code)
               OR  (base_cur%NOTFOUND)
              )
         )
      THEN
        -- 拠点コードが変った場合、又は最終レコードの場合
        gt_csv_data(ln_cnt) :=     lt_base_code                     -- 拠点コード
                                || cv_separate_code
                                || lt_base_name                     -- 拠点名
                                || cv_separate_code
                                || gt_key_total(1)                  -- 月首在庫
                                || cv_separate_code
                                || gt_key_total(2)                  -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_key_total(3)                  -- ベンダ入庫
                                || cv_separate_code
                                || gt_key_total(4)                  -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_key_total(5)                  -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_key_total(6)                  -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_key_total(7)                  -- ベンダ出庫
                                || cv_separate_code
                                || gt_key_total(8)                  -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_key_total(9)                  -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_key_total(10)                 -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_key_total(11)                 -- 月末帳簿残
                                || cv_separate_code
                                || gt_key_total(12)                 -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_key_total(13)                 -- 月末在庫
                                || cv_separate_code
                                || gt_key_total(14)                 -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_key_total(15)                 -- 棚卸減耗費
                                || cv_separate_code
                                || gt_key_total(16);                -- 棚卸減耗費（金額）
        --
        -- 変数カウントアップ
        ln_cnt  :=  ln_cnt + 1;
        --
        -- 拠点計初期化
        FOR i IN 1 .. 16 LOOP
          gt_key_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 合計設定
      IF (base_cur%NOTFOUND) THEN
        -- 最終レコードの場合
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute5      -- 見出し５
                                || cv_separate_code
                                || cv_separate_code
                                || gt_total(1)                      -- 月首在庫
                                || cv_separate_code
                                || gt_total(2)                      -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_total(3)                      -- ベンダ入庫
                                || cv_separate_code
                                || gt_total(4)                      -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_total(5)                      -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_total(6)                      -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_total(7)                      -- ベンダ出庫
                                || cv_separate_code
                                || gt_total(8)                      -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_total(9)                      -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_total(10)                     -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_total(11)                     -- 月末帳簿残
                                || cv_separate_code
                                || gt_total(12)                     -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_total(13)                     -- 月末在庫
                                || cv_separate_code
                                || gt_total(14)                     -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_total(15)                     -- 棚卸減耗費
                                || cv_separate_code
                                || gt_total(16);                    -- 棚卸減耗費（金額）
        --
      END IF;
      --
      -- 終了判定
      EXIT set_csv_base_loop  WHEN  base_cur%NOTFOUND;
      --
      -- 拠点計取得
      gt_key_total(1)   :=  gt_key_total(1)  +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_key_total(2)   :=  gt_key_total(2)  +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_key_total(3)   :=  gt_key_total(3)  +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_key_total(4)   :=  gt_key_total(4)  +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_key_total(5)   :=  gt_key_total(5)  +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_key_total(6)   :=  gt_key_total(6)  +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_key_total(7)   :=  gt_key_total(7)  +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_key_total(8)   :=  gt_key_total(8)  +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_key_total(9)   :=  gt_key_total(9)  +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_key_total(10)  :=  gt_key_total(10) +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_key_total(11)  :=  gt_key_total(11) +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_key_total(12)  :=  gt_key_total(12) +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_key_total(13)  :=  gt_key_total(13) +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_key_total(14)  :=  gt_key_total(14) +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_key_total(15)  :=  gt_key_total(15) +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_key_total(16)  :=  gt_key_total(16) +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- 合計取得
      gt_total(1)       :=  gt_total(1)      +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_total(2)       :=  gt_total(2)      +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_total(3)       :=  gt_total(3)      +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_total(4)       :=  gt_total(4)      +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_total(5)       :=  gt_total(5)      +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_total(6)       :=  gt_total(6)      +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_total(7)       :=  gt_total(7)      +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_total(8)       :=  gt_total(8)      +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_total(9)       :=  gt_total(9)      +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_total(10)      :=  gt_total(10)     +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_total(11)      :=  gt_total(11)     +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_total(12)      :=  gt_total(12)     +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_total(13)      :=  gt_total(13)     +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_total(14)      :=  gt_total(14)     +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_total(15)      :=  gt_total(15)     +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_total(16)      :=  gt_total(16)     +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- レコード変更チェック用変数保持
      lt_base_code  :=  vd_data_rec.base_code;
      lt_base_name  :=  vd_data_rec.account_name;
      --
      -- 処理件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- データ取得
      FETCH base_cur  INTO  vd_data_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE base_cur;
    --
    -- ===================================
    --  CSV出力
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** CSV対象データなし例外 ***
    WHEN csv_no_data_expt THEN
      -- 正常で、本プロシージャを終了
      NULL;
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
      IF (base_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END out_csv_base_total;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_base
   * Description      : VD受払CSV編集・要求出力（拠点別）(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_base(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_base'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt        NUMBER;                                 -- CSVレコード行番号
    lt_base_code  xxcoi_vd_reception_info.base_code%TYPE; -- レコード変更チェックキー項目（拠点コード）
    lv_gun_code   VARCHAR2(3);                            -- レコード変更チェックキー項目（群コード）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --
    OPEN  base_cur;
    FETCH base_cur  INTO  vd_data_rec;
    --
    IF (base_cur%NOTFOUND) THEN
      -- 対象データ無しメッセージ
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- 対象データが取得されなかった場合、処理を終了
      CLOSE base_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  １行目編集（ヘッダ情報）
    -- ===================================
    gt_csv_data(1)  :=     SUBSTRB(gv_param_reception_date, 3, 2)     -- 受払年月（年）
                        || gr_lookup_values.attribute1                -- 見出し１
                        || SUBSTRB(gv_param_reception_date, 5, 2)     -- 受払年月（月）
                        || gr_lookup_values.attribute2                -- 見出し２
                        || cv_separate_code
                        || gr_lookup_values.attribute3                -- 見出し３
                        || cv_separate_code
                        || gt_output_name                             -- 受払出力区分名
                        || cv_separate_code
                        || gt_cost_kbn_name;                          -- 原価区分名
    --
    -- ===================================
    --  ２行目編集（項目名）
    -- ===================================
    gt_csv_data(2)  :=      gr_lookup_values.attribute6               -- 見出し６
                        ||  gr_lookup_values.attribute9               -- 見出し９
                        ||  gr_lookup_values.attribute10              -- 見出し１０
                        ||  gr_lookup_values.attribute11;             -- 見出し１１
    --
    -- ===================================
    --  ３行目以降編集（数値データ）
    -- ===================================
    ln_cnt  :=  3;
    --
    <<set_csv_base_loop>>
    LOOP
      -- 群計設定
      IF (    (lt_base_code IS NOT NULL)
          AND (    (vd_data_rec.base_code <>  lt_base_code)
               OR  (vd_data_rec.gun_code  <>  lv_gun_code)
               OR  (base_cur%NOTFOUND)
              )
         )
      THEN
        -- 拠点、群コードの何れかが変った場合、又は最終レコードの場合
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute4      -- 見出し４
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_key_total(1)                  -- 月首在庫
                                || cv_separate_code
                                || gt_key_total(2)                  -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_key_total(3)                  -- ベンダ入庫
                                || cv_separate_code
                                || gt_key_total(4)                  -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_key_total(5)                  -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_key_total(6)                  -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_key_total(7)                  -- ベンダ出庫
                                || cv_separate_code
                                || gt_key_total(8)                  -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_key_total(9)                  -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_key_total(10)                 -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_key_total(11)                 -- 月末帳簿残
                                || cv_separate_code
                                || gt_key_total(12)                 -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_key_total(13)                 -- 月末在庫
                                || cv_separate_code
                                || gt_key_total(14)                 -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_key_total(15)                 -- 棚卸減耗費
                                || cv_separate_code
                                || gt_key_total(16);                -- 棚卸減耗費（金額）
        --
        -- 変数カウントアップ
        ln_cnt  :=  ln_cnt + 1;
        --
        -- 群計初期化
        FOR i IN 1 .. 16 LOOP
          gt_key_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 合計設定
      IF (    (lt_base_code IS NOT NULL)
          AND (    (vd_data_rec.base_code <>  lt_base_code)
               OR  (base_cur%NOTFOUND)
              )
         )
      THEN
        -- 拠点コードが変った場合、又は最終レコードの場合
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute5      -- 見出し５
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_total(1)                      -- 月首在庫
                                || cv_separate_code
                                || gt_total(2)                      -- 月首在庫（金額）
                                || cv_separate_code
                                || gt_total(3)                      -- ベンダ入庫
                                || cv_separate_code
                                || gt_total(4)                      -- ベンダ入庫（金額）
                                || cv_separate_code
                                || gt_total(5)                      -- ベンダ移動入庫
                                || cv_separate_code
                                || gt_total(6)                      -- ベンダ移動入庫（金額）
                                || cv_separate_code
                                || gt_total(7)                      -- ベンダ出庫
                                || cv_separate_code
                                || gt_total(8)                      -- ベンダ出庫（金額）
                                || cv_separate_code
                                || gt_total(9)                      -- ベンダ移動出庫
                                || cv_separate_code
                                || gt_total(10)                     -- ベンダ移動出庫（金額）
                                || cv_separate_code
                                || gt_total(11)                     -- 月末帳簿残
                                || cv_separate_code
                                || gt_total(12)                     -- 月末帳簿残（金額）
                                || cv_separate_code
                                || gt_total(13)                     -- 月末在庫
                                || cv_separate_code
                                || gt_total(14)                     -- 月末在庫（金額）
                                || cv_separate_code
                                || gt_total(15)                     -- 棚卸減耗費
                                || cv_separate_code
                                || gt_total(16);                    -- 棚卸減耗費（金額）
        --
        -- 変数カウントアップ
        ln_cnt  :=  ln_cnt + 1;
        --
        -- 合計初期化
        FOR i IN 1 .. 16 LOOP
          gt_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- 終了判定
      EXIT set_csv_base_loop  WHEN  base_cur%NOTFOUND;
      --
      -- 明細レコード設定
      gt_csv_data(ln_cnt) :=     vd_data_rec.base_code                    -- 拠点コード
                              || cv_separate_code
                              || vd_data_rec.account_name                 -- 拠点名称
                              || cv_separate_code
                              || vd_data_rec.gun_code                     -- 群コード
                              || cv_separate_code
                              || vd_data_rec.segment1                     -- 品目コード
                              || cv_separate_code
                              || vd_data_rec.item_short_name              -- 品名
                              || cv_separate_code
                              || vd_data_rec.month_begin_quantity         -- 月首在庫
                              || cv_separate_code
                              || vd_data_rec.month_begin_money            -- 月首在庫（金額）
                              || cv_separate_code
                              || vd_data_rec.vd_stock                     -- ベンダ入庫
                              || cv_separate_code
                              || vd_data_rec.vd_stock_money               -- ベンダ入庫（金額）
                              || cv_separate_code
                              || vd_data_rec.vd_move_stock                -- ベンダ移動入庫
                              || cv_separate_code
                              || vd_data_rec.vd_move_stock_money          -- ベンダ移動入庫（金額）
                              || cv_separate_code
                              || vd_data_rec.vd_ship                      -- ベンダ出庫
                              || cv_separate_code
                              || vd_data_rec.vd_ship_money                -- ベンダ出庫（金額）
                              || cv_separate_code
                              || vd_data_rec.vd_move_ship                 -- ベンダ移動出庫
                              || cv_separate_code
                              || vd_data_rec.vd_move_ship_money           -- ベンダ移動出庫（金額）
                              || cv_separate_code
                              || vd_data_rec.month_end_book_remain_qty    -- 月末帳簿残
                              || cv_separate_code
                              || vd_data_rec.month_end_book_remain_money  -- 月末帳簿残（金額）
                              || cv_separate_code
                              || vd_data_rec.month_end_quantity           -- 月末在庫
                              || cv_separate_code
                              || vd_data_rec.month_end_money              -- 月末在庫（金額）
                              || cv_separate_code
                              || vd_data_rec.inv_wear_account             -- 棚卸減耗費
                              || cv_separate_code
                              || vd_data_rec.inv_wear_account_money;      -- 棚卸減耗費（金額）
      --
      -- 群計取得
      gt_key_total(1)   :=  gt_key_total(1)  +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_key_total(2)   :=  gt_key_total(2)  +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_key_total(3)   :=  gt_key_total(3)  +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_key_total(4)   :=  gt_key_total(4)  +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_key_total(5)   :=  gt_key_total(5)  +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_key_total(6)   :=  gt_key_total(6)  +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_key_total(7)   :=  gt_key_total(7)  +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_key_total(8)   :=  gt_key_total(8)  +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_key_total(9)   :=  gt_key_total(9)  +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_key_total(10)  :=  gt_key_total(10) +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_key_total(11)  :=  gt_key_total(11) +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_key_total(12)  :=  gt_key_total(12) +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_key_total(13)  :=  gt_key_total(13) +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_key_total(14)  :=  gt_key_total(14) +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_key_total(15)  :=  gt_key_total(15) +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_key_total(16)  :=  gt_key_total(16) +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- 合計取得
      gt_total(1)       :=  gt_total(1)      +  vd_data_rec.month_begin_quantity;           -- 月首在庫
      gt_total(2)       :=  gt_total(2)      +  vd_data_rec.month_begin_money;              -- 月首在庫（金額）
      gt_total(3)       :=  gt_total(3)      +  vd_data_rec.vd_stock;                       -- ベンダ入庫
      gt_total(4)       :=  gt_total(4)      +  vd_data_rec.vd_stock_money;                 -- ベンダ入庫（金額）
      gt_total(5)       :=  gt_total(5)      +  vd_data_rec.vd_move_stock;                  -- ベンダ移動入庫
      gt_total(6)       :=  gt_total(6)      +  vd_data_rec.vd_move_stock_money;            -- ベンダ移動入庫（金額）
      gt_total(7)       :=  gt_total(7)      +  vd_data_rec.vd_ship;                        -- ベンダ出庫
      gt_total(8)       :=  gt_total(8)      +  vd_data_rec.vd_ship_money;                  -- ベンダ出庫（金額）
      gt_total(9)       :=  gt_total(9)      +  vd_data_rec.vd_move_ship;                   -- ベンダ移動出庫
      gt_total(10)      :=  gt_total(10)     +  vd_data_rec.vd_move_ship_money;             -- ベンダ移動出庫（金額）
      gt_total(11)      :=  gt_total(11)     +  vd_data_rec.month_end_book_remain_qty;      -- 月末帳簿残
      gt_total(12)      :=  gt_total(12)     +  vd_data_rec.month_end_book_remain_money;    -- 月末帳簿残（金額）
      gt_total(13)      :=  gt_total(13)     +  vd_data_rec.month_end_quantity;             -- 月末在庫
      gt_total(14)      :=  gt_total(14)     +  vd_data_rec.month_end_money;                -- 月末在庫（金額）
      gt_total(15)      :=  gt_total(15)     +  vd_data_rec.inv_wear_account;               -- 棚卸減耗費
      gt_total(16)      :=  gt_total(16)     +  vd_data_rec.inv_wear_account_money;         -- 棚卸減耗費（金額）
      --
      -- レコード変更チェック用変数保持
      lt_base_code  :=  vd_data_rec.base_code;
      lv_gun_code   :=  vd_data_rec.gun_code;
      --
      -- 変数カウントアップ
      ln_cnt  :=  ln_cnt + 1;
      --
      -- 処理件数カウント
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- データ取得
      FETCH base_cur  INTO  vd_data_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE base_cur;
    --
    -- ===================================
    --  CSV出力
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** CSV対象データなし例外 ***
    WHEN csv_no_data_expt THEN
      -- 正常で、本プロシージャを終了
      NULL;
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
      IF (base_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END out_csv_base;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf         OUT VARCHAR2,                     -- エラー・メッセージ                  --# 固定 #
    ov_retcode        OUT VARCHAR2,                     -- リターン・コード                    --# 固定 #
    ov_errmsg         OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter'; -- プログラム名
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
    -- *** ローカル変数 ***
    ld_dummy    DATE;       -- DATE型ダミー変数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --
    -- ===================================
    --  1.日付型チェック
    -- ===================================
    BEGIN
      -- 日付型チェック
      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_month);
    EXCEPTION
      WHEN  OTHERS  THEN
        -- 業務処理日付取得エラーメッセージ
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_short_name
                         ,iv_name         => cv_msg_xxcoi1_10110
                        );
        lv_errbuf   :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===================================
    --  2.未来日チェック
    -- ===================================
    IF(gv_param_reception_date  >=  TO_CHAR(gd_f_process_date, cv_month)) THEN
      -- パラメータ.受払日が、業務処理日付以降の場合
      -- 受払年月未来日チェックエラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10111
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- == 2009/07/14 V1.1 Added START ===============================================================
    gd_target_date := LAST_DAY(ld_dummy);
-- == 2009/07/14 V1.1 Added END   ===============================================================
    --
    -- ===================================
    --  3.拠点コード置換
    -- ===================================
    IF (gv_param_output_kbn IN(cv_output_div_2, cv_output_div_3)) THEN
      -- 出力区分が拠点別計、全社計の場合、パラメータ.拠点をNULLとします
      gv_param_base_code  :=  NULL;
    END IF;
  --
  EXCEPTION
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
  END chk_parameter;
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
    --  1.業務処理日付取得
    -- ===================================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
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
    --  2.起動パラメータ名取得
    -- ===================================
    -- 受払出力区分名
    gt_output_name  :=  xxcoi_common_pkg.get_meaning(cv_type_output_div, gv_param_output_kbn);
    --
    IF (gt_output_name IS NULL) THEN
      -- パラメータ.出力区分名取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10113
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 原価区分名
    gt_cost_kbn_name  :=  xxcoi_common_pkg.get_meaning(cv_type_cost_price, gv_param_cost_kbn);
    --
    IF (gt_cost_kbn_name IS NULL) THEN
      -- パラメータ.原価区分名取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10114
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.パラメータログ出力
    -- ===================================
    -- パラメータ出力区分値メッセージ
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10098
                    ,iv_token_name1  => cv_token_10098_1
                    ,iv_token_value1 => gt_output_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- パラメータ受払年月値メッセージ
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10107
                    ,iv_token_name1  => cv_token_10107_1
                    ,iv_token_value1 => gv_param_reception_date
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- パラメータ原価区分値メッセージ
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10108
                    ,iv_token_name1  => cv_token_10108_1
                    ,iv_token_value1 => gt_cost_kbn_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- パラメータ拠点値メッセージ
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10109
                    ,iv_token_name1  => cv_token_10109_1
                    ,iv_token_value1 => gv_param_base_code
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行を出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
    );
    --
    -- ===================================
    --  4.見出し情報取得
    -- ===================================
    gr_lookup_values  :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_1
                           ,id_enabled_date   =>  SYSDATE
                          );
    --
    IF (gr_lookup_values.meaning IS NULL) THEN
      -- 見出し情報取得エラーメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_kbn     IN  VARCHAR2,     -- 出力区分
    iv_reception_date IN  VARCHAR2,     -- 受払年月
    iv_cost_kbn       IN  VARCHAR2,     -- 原価区分
    iv_base_code      IN  VARCHAR2,     -- 拠点
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
    -- ===============================
    --  0.入力パラメータ設定
    -- ===============================
    gv_param_output_kbn     :=  iv_output_kbn;
    gv_param_reception_date :=  iv_reception_date;
    gv_param_cost_kbn       :=  iv_cost_kbn;
    gv_param_base_code      :=  iv_base_code;
    --
    -- 合計初期化
    FOR i IN 1 .. 16 LOOP
      gt_key_total(i)   :=  0;
    END LOOP;
    FOR i IN 1 .. 16 LOOP
      gt_key2_total(i)  :=  0;
    END LOOP;
    FOR i IN 1 .. 16 LOOP
      gt_total(i)       :=  0;
    END LOOP;
    --
    -- ===============================
    --  1.初期処理(A-1)
    -- ===============================
    init(
      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  2.パラメータチェック(A-2)
    -- ===============================
    chk_parameter(
      ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    --  3.VD受払CSV編集・要求出力(A-3, A-4)
    -- ====================================
    IF (gv_param_output_kbn = cv_output_div_1) THEN
      -- 受払出力区分「拠点別」の場合
      out_csv_base(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
    ELSIF (gv_param_output_kbn  = cv_output_div_2)  THEN
      -- 受払出力区分「拠点別計」の場合
      out_csv_base_total(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
    ELSE
      -- 受払出力区分「全社計」の場合
      out_csv_company_total(
        ov_errbuf     =>  lv_errbuf       --   エラー・メッセージ           --# 固定 #
       ,ov_retcode    =>  lv_retcode      --   リターン・コード             --# 固定 #
       ,ov_errmsg     =>  lv_errmsg       --   ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  4.終了処理(A-5)
    -- ===============================
    -- 正常件数を設定
    gn_normal_cnt := gn_target_cnt;
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
    iv_output_kbn       IN  VARCHAR2,       -- 【必須】出力区分
    iv_reception_date   IN  VARCHAR2,       -- 【必須】受払年月
    iv_cost_kbn         IN  VARCHAR2,       -- 【必須】原価区分
    iv_base_code        IN  VARCHAR2        -- 【任意】拠点
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
        iv_output_kbn       =>  iv_output_kbn       -- 出力区分
       ,iv_reception_date   =>  iv_reception_date   -- 受払年月
       ,iv_cost_kbn         =>  iv_cost_kbn         -- 原価区分
       ,iv_base_code        =>  iv_base_code        -- 拠点
       ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ             --# 固定 #
       ,ov_retcode          =>  lv_retcode          -- リターン・コード               --# 固定 #
       ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      -- 処理件数
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行を出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
END XXCOI006A23C;
/
