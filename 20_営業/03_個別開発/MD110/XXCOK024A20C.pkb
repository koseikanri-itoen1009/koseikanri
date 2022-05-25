CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A20C(body)
 * Description      : 控除データアップロード
 * MD.050           : 控除データアップロード MD050_COK_024_A20
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                                       (A-1)
 *  get_if_data                  IFデータ取得                                   (A-2)
 *  delete_if_data               IFデータ削除                                   (A-3)
 *  divide_item                  アップロードファイル項目分割                   (A-4)
 *  error_check                  エラーチェック処理                             (A-5)
 *  deduction_date_register      販売控除データ登録処理                         (A-6)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/04/27    1.0   Y.Nakajima       新規作成
 *  2022/05/20    1.1   SCSK Y.Koh       E_本稼動_18280対応
 *  2022/05/25    1.2   SCSK Y.Koh       E_本稼動_18280対応(不具合対応)
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
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
  gn_error_cnt     NUMBER;                    -- エラー件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
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
  -- ロックエラー
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOK024A20C'; -- パッケージ名
--
  cv_csv_delimiter              CONSTANT VARCHAR2(1)  := ',';   -- カンマ
  cv_period                     CONSTANT VARCHAR2(1)  := '.';   -- ピリオド
  cv_const_y                    CONSTANT VARCHAR2(1)  := 'Y';   -- 'Y'
  cv_const_n                    CONSTANT VARCHAR2(1)  := 'N';   -- 'N'
  cv_const_u                    CONSTANT VARCHAR2(1)  := 'U';   -- 'U'
--
  -- 数値
  cn_zero                       CONSTANT NUMBER := 0;   -- 0
  cn_one                        CONSTANT NUMBER := 1;   -- 1
--
  -- 分割データ用
  cn_customer_code              CONSTANT NUMBER := 1;   -- 顧客コード
  cn_introduction_chain_code    CONSTANT NUMBER := 2;   -- チェーン店コード
  cn_corp_code                  CONSTANT NUMBER := 3;   -- 企業コード
  cn_base_code                  CONSTANT NUMBER := 4;   -- 拠点コード
  cn_record_date                CONSTANT NUMBER := 5;   -- 計上日
  cn_data_type                  CONSTANT NUMBER := 6;   -- データ種類
  cn_item_code                  CONSTANT NUMBER := 7;   -- 品目コード
  cn_deduction_uom_code         CONSTANT NUMBER := 8;   -- 控除単位
  cn_deduction_unit_price       CONSTANT NUMBER := 9;   -- 控除単価
  cn_deduction_quantity         CONSTANT NUMBER := 10;  -- 控除数量
  cn_deduction_amount           CONSTANT NUMBER := 11;  -- 控除額
-- 2022/05/20 Ver1.1 MOD Start
  cn_compensation               CONSTANT NUMBER := 12;  -- 補填
  cn_margin                     CONSTANT NUMBER := 13;  -- 問屋マージン
  cn_sales_promotion_expenses   CONSTANT NUMBER := 14;  -- 拡売
  cn_margin_reduction           CONSTANT NUMBER := 15;  -- 問屋マージン減額
  cn_tax_code                   CONSTANT NUMBER := 16;  -- 税コード
  cn_deduction_tax_amount       CONSTANT NUMBER := 17;  -- 控除税額
  cn_remarks                    CONSTANT NUMBER := 18;  -- 備考
  cn_application_no             CONSTANT NUMBER := 19;  -- 申請書No
  cn_paid_flag                  CONSTANT NUMBER := 20;  -- 支払済フラグ
  cn_c_header                   CONSTANT NUMBER := 20;  -- CSVファイル項目数（取得対象）
  cn_c_header_all               CONSTANT NUMBER := 20;  -- CSVファイル項目数（全項目）
--  cn_tax_code                   CONSTANT NUMBER := 12;  -- 税コード
--  cn_deduction_tax_amount       CONSTANT NUMBER := 13;  -- 控除税額
--  cn_remarks                    CONSTANT NUMBER := 14;  -- 備考
--  cn_application_no             CONSTANT NUMBER := 15;  -- 申請書No
--  cn_c_header                   CONSTANT NUMBER := 15;  -- CSVファイル項目数（取得対象）
--  cn_c_header_all               CONSTANT NUMBER := 15;  -- CSVファイル項目数（全項目）
-- 2022/05/20 Ver1.1 MOD End
--
  cv_condition_type_ws_fix      CONSTANT VARCHAR2(3)  :=  '030';  -- 控除タイプ(問屋未収（定額）)
  cv_condition_type_ws_add      CONSTANT VARCHAR2(3)  :=  '040';  -- 控除タイプ(問屋未収（追加）)
  cv_condition_type_fix_con     CONSTANT VARCHAR2(3)  :=  '070';  -- 控除タイプ(定額控除)
--
  cv_uom_book                   CONSTANT VARCHAR2(3)  :=  '本';   -- 単位（本）
  cv_uom_cs                     CONSTANT VARCHAR2(2)  :=  'CS';   -- 単位（CS）
  cv_uom_bl                     CONSTANT VARCHAR2(2)  :=  'BL';   -- 単位（BL）
--
  cv_month_jan                  CONSTANT VARCHAR2(2)  :=  '01';   -- 1月
  cv_month_feb                  CONSTANT VARCHAR2(2)  :=  '02';   -- 2月
  cv_month_mar                  CONSTANT VARCHAR2(2)  :=  '03';   -- 3月
  cv_month_apr                  CONSTANT VARCHAR2(2)  :=  '04';   -- 4月
--
  -- 出力タイプ
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';        -- 出力(ユーザメッセージ用出力先)
--
  -- 書式マスク
  cv_date_format        CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';    -- 日付書式
  cv_date_year          CONSTANT VARCHAR2(4)  := 'YYYY';          -- 年
  cv_date_month         CONSTANT VARCHAR2(2)  := 'MM';            -- 月
--
  -- アプリケーション短縮名
  cv_msg_kbn_cok        CONSTANT VARCHAR2(5)  := 'XXCOK'; -- アドオン：個別開発
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)  := 'XXCOS'; -- アドオン：販売
--
--
  -- 参照タイプ
  cv_type_upload_obj      CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';      -- ファイルアップロードオブジェクト
  cv_type_deduction_data  CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- 控除データ種類
  cv_type_chain_code      CONSTANT VARCHAR2(30) := 'XXCMM_CHAIN_CODE';            -- チェーンコード
  cv_type_business_type   CONSTANT VARCHAR2(30) := 'XX03_BUSINESS_TYPE';          -- 企業コード
  cv_type_departmen       CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT';             -- 拠点コード
--
  -- 言語コード
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- メッセージ名
  cv_msg_ccp_10534      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10534';  -- 警告件数メッセージ
--
  cv_msg_cok_00016      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00016';  -- ファイルID出力用メッセージ
  cv_msg_cok_00017      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00017';  -- ファイルパターン出力用メッセージ
  cv_msg_cok_00028      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';  -- 業務日付取得エラー
  cv_msg_cok_00006      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00006';  -- ファイル名出力用メッセージ
  cv_msg_cok_00061      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00061';  -- ファイルアップロードI/Fテーブルロック取得エラーメッセージ
  cv_msg_cok_00106      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00106';  -- ファイルアップロード名称出力用メッセージ
  cv_msg_coi_00062      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00062';  -- ファイルアップロードIF削除エラー
  cv_msg_cok_00041      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00041';  -- BLOBデータ変換エラーメッセージ
  cv_msg_cok_10634      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10634';  -- ファイルレコード不一致エラーメッセージ
  cv_msg_cok_10618      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10618';  -- マスタ未登録エラー
  cv_msg_cok_10699      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10699';  -- 入力必須エラー
  cv_msg_cok_10621      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10621';  -- 日付項目エラー
  cv_msg_cok_10620      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10620';  -- 小数項目型エラー
  cv_msg_cok_10619      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10619';  -- 整数項目型エラー
  cv_msg_cok_10667      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10667';  -- 控除単位不正エラー1
  cv_msg_cok_10668      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10668';  -- 控除単位不正エラー2
  cv_msg_cok_10676      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10676';  -- 控除番号シーケンスエラー
  cv_msg_cok_00039      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00039';  -- CSVファイルデータなしエラーメッセージ
  cv_msg_cos_11294      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11294';  -- CSVファイル名取得エラー
  cv_msg_cok_10706      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10706';  -- 計上日未来日エラー
--
  -- トークン名
  cv_file_id_tok        CONSTANT VARCHAR2(20) := 'FILE_ID';           -- ファイルID
  cv_format_tok         CONSTANT VARCHAR2(20) := 'FORMAT';            -- フォーマット
  cv_file_name_tok      CONSTANT VARCHAR2(20) := 'FILE_NAME';         -- ファイル名
  cv_upload_object_tok  CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';     -- アップロードファイル名
  cv_data_tok           CONSTANT VARCHAR2(20) := 'DATA';              -- データ
  cv_col_name_tok       CONSTANT VARCHAR2(20) := 'COLUMN_NAME';       -- 項目名
  cv_col_value_tok      CONSTANT VARCHAR2(20) := 'COLUMN_VALUE';      -- 項目値
  cv_line_no_tok        CONSTANT VARCHAR2(20) := 'LINE_NO';           -- 行番号
  cv_deduction_type_tok CONSTANT VARCHAR2(20) := 'DEDUCTION_TYPE';    -- 控除タイプ
  cv_key_data_tok       CONSTANT VARCHAR2(20) := 'KEY_DATA';          -- 特定できるキー内容をコメントをつけてセットします。
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 配列退避用販売控除ワークテーブル定義
  TYPE  gr_sales_deduction_work IS RECORD(
      customer_code_from        xxcok_sales_deduction.customer_code_from%TYPE             -- 顧客コード
     ,introduction_chain_code   xxcok_sales_deduction.deduction_chain_code%TYPE           -- チェーン店コード
     ,corp_code                 xxcok_sales_deduction.corp_code%TYPE                      -- 企業コード
     ,base_code                 xxcok_sales_deduction.base_code_from%TYPE                 -- 拠点コード
     ,record_date               xxcok_sales_deduction.record_date%TYPE                    -- 計上日
     ,data_type                 xxcok_sales_deduction.data_type%TYPE                      -- データ種類
     ,item_code                 xxcok_sales_deduction.item_code%TYPE                      -- 品目コード
     ,deduction_uom_code        xxcok_sales_deduction.deduction_uom_code%TYPE             -- 控除単位
     ,deduction_unit_price      xxcok_sales_deduction.deduction_unit_price%TYPE           -- 控除単価
     ,deduction_quantity        xxcok_sales_deduction.deduction_quantity%TYPE             -- 控除数量
     ,deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- 控除額
     ,tax_code                  xxcok_sales_deduction.tax_code%TYPE                       -- 税コード
     ,deduction_tax_amount      xxcok_sales_deduction.deduction_tax_amount%TYPE           -- 控除税額
     ,remarks                   xxcok_sales_deduction.remarks%TYPE                        -- 備考
     ,application_no            xxcok_sales_deduction.application_no%TYPE                 -- 申請書No.
     ,tax_rate                  xxcok_sales_deduction.tax_rate%TYPE                       -- 税率
-- 2022/05/20 Ver1.1 ADD Start
     ,compensation              xxcok_sales_deduction.compensation%TYPE                   -- 補填
     ,margin                    xxcok_sales_deduction.margin%TYPE                         -- 問屋マージン
     ,sales_promotion_expenses  xxcok_sales_deduction.sales_promotion_expenses%TYPE       -- 拡売
     ,margin_reduction          xxcok_sales_deduction.margin_reduction%TYPE               -- 問屋マージン減額
     ,paid_flag                 VARCHAR2(1)                                               -- 支払済フラグ
-- 2022/05/20 Ver1.1 ADD End
  );
--
  -- ワークテーブル型定義
  TYPE g_sales_deduction_work_ttype  IS TABLE OF gr_sales_deduction_work INDEX BY BINARY_INTEGER;
    gt_sales_deduction_work_tbl  g_sales_deduction_work_ttype;
--
  -- 文字項目分割後データ格納用
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;   -- 1次元配列
  g_if_data_tab             g_var_data_ttype;                                     -- 分割用変数
  gt_file_line_data_tab     xxccp_common_pkg2.g_file_data_tbl;                    -- CSVデータ（1行）
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_deduction_type     VARCHAR(3);       -- 控除タイプ
  gv_sale_base_code     VARCHAR2(10);
  gv_tax_rate           VARCHAR2(10);
  gd_process_date       DATE;             -- 業務日付
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER     --   ファイルID
   ,iv_file_format IN  VARCHAR2   --   ファイルフォーマット
   ,ov_errbuf      OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_out_msg              VARCHAR2(1000); -- メッセージ
    lb_retcode              BOOLEAN;        -- 判定結果
    lt_file_name            xxccp_mrp_file_ul_interface.file_name%TYPE;
    lt_file_upload_name     fnd_lookup_values.meaning%TYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lt_file_name        :=  NULL;               -- ファイル名
    lt_file_upload_name :=  NULL;               -- ファイルアップロード名称
    lb_retcode          :=  false;
--
    -- 1.ファイルIDメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cok
                    , iv_name         => cv_msg_cok_00016
                    , iv_token_name1  => cv_file_id_tok
                    , iv_token_value1 => in_file_id
                  );
    -- 1.ファイルIDメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_zero         -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_zero         -- 改行
                  );
    -- 1.フォーマットパターンメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cok
                    , iv_name         => cv_msg_cok_00017
                    , iv_token_name1  => cv_format_tok
                    , iv_token_value1 => iv_file_format
                  );
    -- 1.フォーマットパターンメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_one          -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_one          -- 改行
                  );
--
    -- 2.業務日付取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得できない場合
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00028 -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3.ファイルアップロード名称・ファイル名の取得とロック
    BEGIN
      SELECT  xfu.file_name   AS file_name        -- ファイル名
             ,flv.meaning     AS file_upload_name -- ファイルアップロード名称
      INTO    lt_file_name                        -- ファイル名
             ,lt_file_upload_name                 -- ファイルアップロード名称
      FROM    xxccp_mrp_file_ul_interface  xfu    -- ファイルアップロードIF
             ,fnd_lookup_values            flv    -- クイックコード
      WHERE   xfu.file_id = in_file_id            -- ファイルID
      AND     flv.lookup_type  = cv_type_upload_obj
      AND     flv.lookup_code  = xfu.file_content_type
      AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                  AND NVL(flv.end_date_active, gd_process_date)
      AND     flv.enabled_flag = cv_const_y
      AND     flv.language     = ct_lang
      FOR UPDATE OF xfu.file_name
      ;
    EXCEPTION
      -- ロックが取得できない場合
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cok
                       ,iv_name         =>  cv_msg_cok_00061  -- ファイルアップロードI/Fテーブルロック取得エラーメッセージ
                       ,iv_token_name1  =>  cv_file_id_tok    -- ファイルID
                       ,iv_token_value1 =>  in_file_id        -- ファイルID
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      -- ファイルアップロード名称・ファイル名が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cos
                       ,iv_name         =>  cv_msg_cos_11294  -- ファイルアップロード名称取得エラーメッセージ
                       ,iv_token_name1  =>  cv_key_data_tok
                       ,iv_token_value1 =>  iv_file_format    -- フォーマットパターン
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 4.取得したファイル名、ファイルアップロード名称を出力
    -- ファイル名を出力（ログ）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- ファイル名
                  )
    );
    -- ファイル名を出力（出力）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- ファイル名
                  )
    );
--
    -- ファイルアップロード名称を出力（ログ）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- ファイルアップロード名称出力メッセージ
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- ファイルアップロード名称
                  )
    );
    -- ファイルアップロード名称を出力（出力）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- ファイルアップロード名称出力メッセージ
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- ファイルアップロード名称
                  )
    );
--
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
    );
--
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
    /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : IFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id     IN  NUMBER     --   ファイルID
   ,iv_file_format IN  VARCHAR2   --   ファイルフォーマット
   ,ov_errbuf      OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;        -- ファイル名
    lt_file_upload_name fnd_lookup_values.description%TYPE;                -- ファイルアップロード名称
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
    -- ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- ファイルID
     ,ov_file_data => gt_file_line_data_tab -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数エラーの場合
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00041  -- BLOBデータ変換エラーメッセージ
                     ,iv_token_name1  =>  cv_file_id_tok
                     ,iv_token_value1 =>  in_file_id        -- ファイルID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数を設定
    gn_target_cnt := gt_file_line_data_tab.COUNT -1;
--
--#################################  固定例外処理部 START   ####################################
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IFデータ削除(A-3)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER     --   ファイルID
   ,ov_errbuf        OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg        OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_if_data'; -- プログラム名
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
    -- ファイルアップロードIFデータ削除
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface  xfu -- ファイルアップロードIF
      WHERE xfu.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        -- 削除に失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cok
                       ,iv_name         =>  cv_msg_coi_00062  -- ファイルアップロードIF削除エラー
                       ,iv_token_name1  =>  cv_file_id_tok
                       ,iv_token_value1 =>  in_file_id        -- ファイルID
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- データが見出しのみの場合エラー
    IF gn_target_cnt = cn_zero THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00039  -- CSVファイルデータなしエラーメッセージ
                     ,iv_token_name1  =>  cv_file_id_tok
                     ,iv_token_value1 =>  in_file_id        -- ファイルID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : アップロードファイル項目分割(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt   IN  NUMBER    --   IFループカウンタ
   ,ov_errbuf             OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- プログラム名
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
    lv_rec_data         VARCHAR2(32765);  -- レコードデータ
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
    -- ローカル変数初期化--
    lv_rec_data  := NULL; -- レコードデータ
--
    -- 項目数チェック
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- 項目数不一致の場合
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_10634  -- ファイルレコード項目数不一致エラーメッセージ
                     ,iv_token_name1  =>  cv_line_no_tok
                     ,iv_token_value1 =>  (in_file_if_loop_cnt - 1)
                     ,iv_token_name2  =>  cv_data_tok
                     ,iv_token_value2 =>  lv_rec_data
                   );
      RAISE global_process_expt;
    END IF;
--
    -- 分割ループ
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     =>  gt_file_line_data_tab(in_file_if_loop_cnt)
                                   ,iv_delim    =>  cv_csv_delimiter
                                   ,in_part_num =>  i
                                  );
    END LOOP data_split_loop;
--
--
--#################################  固定例外処理部 START   ####################################
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
  END divide_item;
--
  /**********************************************************************************
  * Procedure Name   : error_check
  * Description      : エラーチェック処理(A-5)
  ***********************************************************************************/
  PROCEDURE error_check(
    in_file_if_loop_cnt   IN  NUMBER    -- IFループカウンタ
   ,ov_errbuf             OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_check'; -- プログラム名
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
    cv_customer_code              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10635';  -- 顧客コード
    cv_introduction_chain_code    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10636';  -- チェーン店コード
    cv_corp_code                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10637';  -- 企業コード
    cv_base_code                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10638';  -- 拠点コード
    cv_record_date                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10639';  -- 計上日
    cv_data_type                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10640';  -- データ種類
    cv_item_code                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10641';  -- 品目コード
    cv_deduction_uom_code         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10642';  -- 控除単位
    cv_deduction_unit_price       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10643';  -- 控除単価
    cv_deduction_quantity         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10644';  -- 控除数量
    cv_deduction_amount           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10645';  -- 控除額
    cv_tax_code                   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10646';  -- 税コード
    cv_deduction_tax_amount       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10647';  -- 控除税額
    cv_cust_chain_corp            CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10648';  -- 顧客、チェーン店、企業いずれか
-- 2022/05/20 Ver1.1 ADD Start
    cv_compensation               CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10836';  -- 補填
    cv_margin                     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10837';  -- 問屋マージン
    cv_sales_promotion_expenses   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10838';  -- 拡売
    cv_margin_reduction           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10839';  -- 問屋マージン減額
-- 2022/05/20 Ver1.1 ADD End
--
    -- *** ローカル変数 ***
    lv_token_name              VARCHAR(1000);
    lv_dummy                   VARCHAR(30);                 -- ダミー
    ld_record_date             DATE;                        -- 計上日
    ln_uom_conversion          NUMBER;
    ln_loop_cnt                NUMBER;                      -- ワークテーブル登録件数用
    lv_data_type               VARCHAR2(10);                -- データ種類
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    lv_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --========================================
    -- 1.データ種類チェック
    --========================================
    --
    BEGIN
    --
      SELECT flv.attribute2       AS deduction_type         -- 控除タイプ
      INTO   gv_deduction_type                              -- 控除タイプ
      FROM   fnd_lookup_values    flv                       -- データ種類
      WHERE 1 = 1
      AND flv.lookup_type       = cv_type_deduction_data
      AND flv.meaning           = g_if_data_tab(cn_data_type)
      AND flv.language          = ct_lang
      AND flv.enabled_flag      = cv_const_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode    := cv_status_warn;
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10618     -- マスタ未登録エラー
                         , iv_token_name1  => cv_line_no_tok
                         , iv_token_value1 => in_file_if_loop_cnt
                         , iv_token_name2  => cv_col_name_tok
                         , iv_token_value2 => cv_data_type
                         , iv_token_name3  => cv_col_value_tok
                         , iv_token_value3 => g_if_data_tab(cn_data_type)
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
    END;
--
    --========================================
    -- 2.入力必須・入力不可チェック
    --========================================
--
    -- 2.1アップロードされたデータがNULLの場合
--
        -- 拠点コードチェック
        IF g_if_data_tab(cn_base_code) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_base_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- 上記項目
                       , iv_token_value2 => lv_token_name
                       );
    --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
        END IF;
    --
        -- 計上日チェック
        IF g_if_data_tab(cn_record_date) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_record_date;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- 上記項目
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- データ種類チェック
        IF g_if_data_tab(cn_data_type) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_data_type;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- 上記項目
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- 控除額チェック
        IF g_if_data_tab(cn_deduction_amount) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_deduction_amount;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- 上記項目
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- 税コードチェック
        IF g_if_data_tab(cn_tax_code) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_tax_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- 上記項目
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- 控除税額チェック
        IF g_if_data_tab(cn_deduction_tax_amount) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_deduction_tax_amount;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- 上記項目
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
    -- 2.3 入力重複チェック
--
    -- 顧客コード、チェーン店コード、企業コードのいずれか２つ以上が入力されているもしくは、いずれも入力されていない場合
    IF    (g_if_data_tab(cn_customer_code) IS NOT NULL AND g_if_data_tab(cn_introduction_chain_code) IS     NULL AND g_if_data_tab(cn_corp_code) IS     NULL) THEN
      NULL;
    ELSIF (g_if_data_tab(cn_customer_code) IS     NULL AND g_if_data_tab(cn_introduction_chain_code) IS NOT NULL AND g_if_data_tab(cn_corp_code) IS     NULL) THEN
      NULL;
    ELSIF (g_if_data_tab(cn_customer_code) IS     NULL AND g_if_data_tab(cn_introduction_chain_code) IS     NULL AND g_if_data_tab(cn_corp_code) IS NOT NULL) THEN
      NULL;
    ELSIF (g_if_data_tab(cn_customer_code) IS     NULL AND g_if_data_tab(cn_introduction_chain_code) IS     NULL AND g_if_data_tab(cn_corp_code) IS     NULL) THEN
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_cust_chain_corp;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok       -- いずれかひとつ
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
--
    ELSE
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_cust_chain_corp;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10699      -- 入力必須エラー
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok       -- いずれかひとつ
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
--
    END IF;
--
    --========================================
    -- 3.項目書式チェック
    --========================================
--
    -- 3.1 計上日書式チェック
--
    BEGIN
      ld_record_date := TO_DATE(g_if_data_tab(cn_record_date), cv_date_format);
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode    := cv_status_warn;
        lv_token_name := cv_record_date;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cok
                     , iv_name         => cv_msg_cok_10621
                     , iv_token_name1  => cv_line_no_tok
                     , iv_token_value1 => in_file_if_loop_cnt
                     , iv_token_name2  => cv_col_name_tok
                     , iv_token_value2 => lv_token_name
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
    END;
--
    -- 3.2 小数桁数チェック
--
    -- 控除単価が入力されている場合書式チェック
    IF g_if_data_tab(cn_deduction_unit_price) IS NOT NULL THEN
      -- 小数2桁以上の場合エラー
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_deduction_unit_price),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_deduction_unit_price),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
-- 2022/05/20 Ver1.1 MOD Start
        IF ((LENGTH(g_if_data_tab(cn_deduction_unit_price)) - INSTR(g_if_data_tab(cn_deduction_unit_price),cv_period)) > 2) THEN
--        IF ((LENGTH(g_if_data_tab(cn_deduction_unit_price)) - INSTR(g_if_data_tab(cn_deduction_unit_price),cv_period)) >= 2) THEN
-- 2022/05/20 Ver1.1 MOD End
            lv_retcode    := cv_status_warn;
            lv_token_name := cv_deduction_unit_price;
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10620
                         , iv_token_name1  => cv_line_no_tok
                         , iv_token_value1 => in_file_if_loop_cnt
                         , iv_token_name2  => cv_col_name_tok
                         , iv_token_value2 => lv_token_name
                         );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        END IF;
      ELSE
        NULL;
      END IF;
    END IF;
--
    -- 控除数量が入力されている場合書式チェック
    IF g_if_data_tab(cn_deduction_quantity) IS NOT NULL THEN
      -- 小数2桁以上の場合エラー
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_deduction_quantity),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_deduction_quantity),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
-- 2022/05/20 Ver1.1 MOD Start
        IF ((LENGTH(g_if_data_tab(cn_deduction_quantity)) - INSTR(g_if_data_tab(cn_deduction_quantity),cv_period)) > 2) THEN
--        IF ((LENGTH(g_if_data_tab(cn_deduction_quantity)) - INSTR(g_if_data_tab(cn_deduction_quantity),cv_period)) >= 2) THEN
-- 2022/05/20 Ver1.1 MOD End
            lv_retcode    := cv_status_warn;
            lv_token_name := cv_deduction_quantity;
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10620
                         , iv_token_name1  => cv_line_no_tok
                         , iv_token_value1 => in_file_if_loop_cnt
                         , iv_token_name2  => cv_col_name_tok
                         , iv_token_value2 => lv_token_name
                         );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        END IF;
      ELSE
        NULL;
      END IF;
    END IF;
--
    -- 3.3 整数チェック
--
    -- 控除額整数チェック
    IF (INSTR(g_if_data_tab(cn_deduction_amount),cv_period) > 0) THEN
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_deduction_amount;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10619
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
    END IF;
--
-- 2022/05/20 Ver1.1 ADD Start
    -- 補填が入力されている場合の書式チェック
    IF g_if_data_tab(cn_compensation) IS NOT NULL THEN
      -- 小数2桁以上の場合エラー
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_compensation),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_compensation),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_compensation)) - INSTR(g_if_data_tab(cn_compensation),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_compensation
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
    -- 問屋マージンが入力されている場合の書式チェック
    IF g_if_data_tab(cn_margin) IS NOT NULL THEN
      -- 小数2桁以上の場合エラー
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_margin),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_margin),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_margin)) - INSTR(g_if_data_tab(cn_margin),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_margin
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
    -- 拡売が入力されている場合の書式チェック
    IF g_if_data_tab(cn_sales_promotion_expenses) IS NOT NULL THEN
      -- 小数2桁以上の場合エラー
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_sales_promotion_expenses),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_sales_promotion_expenses),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_sales_promotion_expenses)) - INSTR(g_if_data_tab(cn_sales_promotion_expenses),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_sales_promotion_expenses
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
    -- 問屋マージン減額が入力されている場合の書式チェック
    IF g_if_data_tab(cn_margin_reduction) IS NOT NULL THEN
      -- 小数2桁以上の場合エラー
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_margin_reduction),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_margin_reduction),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_margin_reduction)) - INSTR(g_if_data_tab(cn_margin_reduction),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_margin_reduction
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
-- 2022/05/20 Ver1.1 ADD End
    -- 控除税額整数チェック
    IF (INSTR(g_if_data_tab(cn_deduction_tax_amount),cv_period) > 0) THEN
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_deduction_tax_amount;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10619
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );

--
    END IF;
--
    --========================================
    -- 4.マスタチェック
    --========================================
--  
    -- 顧客コードが指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_customer_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  xca.sale_base_code      AS sale_base_code
        INTO    gv_sale_base_code
        FROM    xxcmm_cust_accounts     xca
        WHERE   xca.customer_code    =  g_if_data_tab(cn_customer_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_customer_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_customer_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- チェーンコードが指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_introduction_chain_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  flv.lookup_code       AS chain_code
        INTO    lv_dummy
        FROM    fnd_lookup_values     flv
        WHERE   1 = 1
        AND     flv.lookup_type    =  cv_type_chain_code
        AND     flv.language       =  ct_lang
        AND     flv.lookup_code    =  g_if_data_tab(cn_introduction_chain_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_introduction_chain_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_introduction_chain_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- 企業コードが指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_corp_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  ffv.flex_value      AS corp_code
        INTO    lv_dummy
        FROM    fnd_flex_values     ffv
               ,fnd_flex_value_sets ffvs
        WHERE   1 = 1
        AND     ffvs.flex_value_set_name    =  cv_type_business_type
        AND     ffvs.flex_value_set_id      =  ffv.flex_value_set_id
        AND     ffv.flex_value              =  g_if_data_tab(cn_corp_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_corp_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_corp_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- 拠点コードが指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_base_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  ffv.flex_value      AS base_code
        INTO    lv_dummy
        FROM    fnd_flex_values     ffv
               ,fnd_flex_value_sets ffvs
        WHERE   1 = 1
        AND     ffvs.flex_value_set_name    =  cv_type_departmen
        AND     ffvs.flex_value_set_id      =  ffv.flex_value_set_id
        AND     ffv.flex_value              =  g_if_data_tab(cn_base_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_base_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_base_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- 品目コードが指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_item_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  xsib.item_code         AS item_code
        INTO    lv_dummy
        FROM    xxcmm_system_items_b   xsib
        WHERE   1 = 1
        AND     xsib.item_code         =  g_if_data_tab(cn_item_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_item_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_item_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- 控除単位が指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_deduction_uom_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  muomt.uom_code            AS uom_code
        INTO    lv_dummy
        FROM    mtl_units_of_measure_tl   muomt
        WHERE   1 = 1
        AND     muomt.uom_code  =  g_if_data_tab(cn_deduction_uom_code)
        AND     muomt.language  =  ct_lang
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_deduction_uom_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_deduction_uom_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;

--
    END IF;
--
    -- 税コードが指定されており、マスタに存在しない場合エラー
    IF g_if_data_tab(cn_tax_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  avtab.tax_rate            AS tax_rate
        INTO    gv_tax_rate
        FROM    ar_vat_tax_all_b          avtab
        WHERE   1 = 1
        AND     avtab.set_of_books_id                                         = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
        AND     avtab.tax_code                                                = g_if_data_tab(cn_tax_code)
        AND     TO_DATE(g_if_data_tab(cn_record_date), cv_date_format)  BETWEEN avtab.start_date
                                                                            AND NVL(avtab.end_date,TO_DATE(g_if_data_tab(cn_record_date), cv_date_format))
        AND     avtab.org_id                                                  = FND_PROFILE.VALUE( 'ORG_ID' )
        AND     avtab.validate_flag                                           = cv_const_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_tax_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_tax_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    --========================================
    -- 5.項目関連チェック
    --========================================
--
    -- 計上日_業務処理日付チェック
    IF TO_DATE(g_if_data_tab(cn_record_date), cv_date_format) > gd_process_date THEN
      lv_retcode := cv_status_warn;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cok
                    , iv_name         => cv_msg_cok_10706
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    -- 控除単位NULLチェック
    IF g_if_data_tab(cn_deduction_uom_code) IS NOT NULL THEN
--
    -- 控除タイプ_控除単位チェック
      -- 控除タイプが030または040の場合
      IF (gv_deduction_type = cv_condition_type_ws_fix OR gv_deduction_type = cv_condition_type_ws_add) THEN
        -- 単位が「本」「CS」「BL」以外の場合エラー
        IF (g_if_data_tab(cn_deduction_uom_code)  NOT IN (cv_uom_book, cv_uom_cs, cv_uom_bl)) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10667
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_deduction_type_tok
                       , iv_token_value2 => gv_deduction_type
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
        END IF;
      END IF;
--
    -- 品目コード_控除単位チェック
    IF g_if_data_tab(cn_item_code) IS NOT NULL THEN
      -- 基準単位換算数取得関数呼び出し
      ln_uom_conversion := xxcok_common_pkg.get_uom_conversion_qty_f(
                              iv_item_code  => g_if_data_tab(cn_item_code)
                            , iv_uom_code   => g_if_data_tab(cn_deduction_uom_code)
                            , in_quantity   => cn_zero
                            );
      -- 基準単位換算後数量がNULLの場合
      IF ln_uom_conversion IS NULL THEN
        lv_retcode    := cv_status_warn;
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10668
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END IF;
    END IF;
--
    END IF;
--
    -- 警告が１件でもあった場合
    IF lv_retcode = cv_status_warn THEN
      ov_retcode    := lv_retcode;
      gn_warn_cnt   := gn_warn_cnt + 1;
    END IF;
--
    ln_loop_cnt := in_file_if_loop_cnt - 1;
--
    -- データ種類変換
    SELECT flv.lookup_code
    INTO   lv_data_type
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_type_deduction_data
    AND    flv.meaning      = g_if_data_tab(6)
    AND    flv.language     = ct_lang
    AND    flv.enabled_flag = cv_const_y
    ;
--
    -- ワークテーブルに分割した値を退避
    gt_sales_deduction_work_tbl(ln_loop_cnt).customer_code_from      := g_if_data_tab(1);   -- 顧客コード
    gt_sales_deduction_work_tbl(ln_loop_cnt).introduction_chain_code := g_if_data_tab(2);   -- チェーン店コード
    gt_sales_deduction_work_tbl(ln_loop_cnt).corp_code               := g_if_data_tab(3);   -- 企業コード
    gt_sales_deduction_work_tbl(ln_loop_cnt).base_code               := g_if_data_tab(4);   -- 計上拠点
    gt_sales_deduction_work_tbl(ln_loop_cnt).record_date             := TO_DATE(g_if_data_tab(5),cv_date_format);   -- 計上日
    gt_sales_deduction_work_tbl(ln_loop_cnt).data_type               := lv_data_type;       -- データ種類
    gt_sales_deduction_work_tbl(ln_loop_cnt).item_code               := g_if_data_tab(7);   -- 品目コード
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_uom_code      := g_if_data_tab(8);   -- 控除単位
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_unit_price    := g_if_data_tab(9);   -- 控除単価
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_quantity      := g_if_data_tab(10);  -- 控除数量
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_amount        := g_if_data_tab(11);  -- 控除額
-- 2022/05/20 Ver1.1 MOD Start
    gt_sales_deduction_work_tbl(ln_loop_cnt).compensation             := g_if_data_tab(cn_compensation);              -- 補填
    gt_sales_deduction_work_tbl(ln_loop_cnt).margin                   := g_if_data_tab(cn_margin);                    -- 問屋マージン
    gt_sales_deduction_work_tbl(ln_loop_cnt).sales_promotion_expenses := g_if_data_tab(cn_sales_promotion_expenses);  -- 拡売
    gt_sales_deduction_work_tbl(ln_loop_cnt).margin_reduction         := g_if_data_tab(cn_margin_reduction);          -- 問屋マージン減額
    gt_sales_deduction_work_tbl(ln_loop_cnt).tax_code                 := g_if_data_tab(cn_tax_code);                  -- 税コード
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_tax_amount     := g_if_data_tab(cn_deduction_tax_amount);      -- 控除税額
    gt_sales_deduction_work_tbl(ln_loop_cnt).remarks                  := g_if_data_tab(cn_remarks);                   -- 備考
    gt_sales_deduction_work_tbl(ln_loop_cnt).application_no           := g_if_data_tab(cn_application_no);            -- 申請書No.
    gt_sales_deduction_work_tbl(ln_loop_cnt).paid_flag                := g_if_data_tab(cn_paid_flag);                 -- 支払済フラグ
--    gt_sales_deduction_work_tbl(ln_loop_cnt).tax_code                := g_if_data_tab(12);  -- 税コード
--    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_tax_amount    := g_if_data_tab(13);  -- 控除税額
--    gt_sales_deduction_work_tbl(ln_loop_cnt).remarks                 := g_if_data_tab(14);  -- 備考
--    gt_sales_deduction_work_tbl(ln_loop_cnt).application_no          := g_if_data_tab(15);  -- 申請書No.
-- 2022/05/20 Ver1.1 MOD End
    gt_sales_deduction_work_tbl(ln_loop_cnt).tax_rate                := gv_tax_rate;        -- 税率
--
  -- 成功件数カウント
  IF lv_retcode = cv_status_normal THEN
    ov_retcode    := lv_retcode;
    gn_normal_cnt := gn_normal_cnt + 1;
  END IF;
--
--#################################  固定例外処理部 START   ####################################
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
  END error_check;
--
  /**********************************************************************************
  * Procedure Name   : deduction_date_register
  * Description      : 販売控除データ登録処理(A-6)
  ***********************************************************************************/
  PROCEDURE deduction_date_register(
    ov_errbuf             OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deduction_date_register'; -- プログラム名
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
    lt_condition_no               xxcok_condition_header.condition_no%TYPE;
--
    -- 控除番号生成用
    lt_sql_str                    VARCHAR2(100);
    lv_process_year               VARCHAR2(4);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --  年度を取得
    lv_process_year   :=  CASE  WHEN  TO_CHAR( gd_process_date, cv_date_month ) IN( cv_month_jan, cv_month_feb, cv_month_mar, cv_month_apr )
                                  THEN  TO_CHAR( TO_NUMBER( TO_CHAR( gd_process_date, cv_date_year ) ) - 1 )
                                  ELSE  TO_CHAR( gd_process_date, cv_date_year )
                          END;
--
    FOR i IN 1..gt_sales_deduction_work_tbl.COUNT LOOP
--
      --  控除番号生成（年度ごとに異なるシーケンスを使用する）
      DECLARE
        lt_sql_str      VARCHAR2(100);
        --
        TYPE  cur_type  IS  REF CURSOR;
        condition_no_cur  cur_type;
        --
        TYPE  rec_type  IS RECORD(
          condition_no        xxcok_condition_header.condition_no%TYPE
        );
        condition_no_rec  rec_type;
      BEGIN
        lt_sql_str  :=    'SELECT XXCOK.XXCOK_UP_CONDITION_NO_' || lv_process_year || '_S01.NEXTVAL  AS  condition_no FROM DUAL';
        OPEN  condition_no_cur FOR lt_sql_str;
        FETCH condition_no_cur INTO condition_no_rec;
        CLOSE condition_no_cur;
        --
        IF ( LENGTHB( condition_no_rec.condition_no ) > 6 ) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cok
                          , iv_name         => cv_msg_cok_10676
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSE
          lt_condition_no               :=  lv_process_year || 'UP' || LPAD( condition_no_rec.condition_no, 6, '0' );
        END IF;
      END;
--
      -- 販売控除データを登録処理
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                         -- 販売控除ID
          ,base_code_from                                             -- 振替元拠点
          ,base_code_to                                               -- 振替先拠点
          ,customer_code_from                                         -- 振替元顧客コード
          ,customer_code_to                                           -- 振替先顧客コード
          ,deduction_chain_code                                       -- チェーン店コード
          ,corp_code                                                  -- 企業コード
          ,record_date                                                -- 計上日
          ,source_category                                            -- 作成元区分
          ,source_line_id                                             -- 作成元明細ID
          ,condition_id                                               -- 控除条件ID
          ,condition_no                                               -- 控除番号
          ,condition_line_id                                          -- 控除詳細ID
          ,data_type                                                  -- データ種類
          ,status                                                     -- ステータス
          ,item_code                                                  -- 品目コード
          ,sales_uom_code                                             -- 販売単位
          ,sales_unit_price                                           -- 販売単価
          ,sales_quantity                                             -- 販売数量
          ,sale_pure_amount                                           -- 売上本体金額
          ,sale_tax_amount                                            -- 売上消費税額
          ,deduction_uom_code                                         -- 控除単位
          ,deduction_unit_price                                       -- 控除単価
          ,deduction_quantity                                         -- 控除数量
          ,deduction_amount                                           -- 控除額
-- 2022/05/20 Ver1.1 ADD Start
          ,compensation                                               -- 補填
          ,margin                                                     -- 問屋マージン
          ,sales_promotion_expenses                                   -- 拡売
          ,margin_reduction                                           -- 問屋マージン減額
-- 2022/05/20 Ver1.1 ADD End
          ,tax_code                                                   -- 税コード
          ,tax_rate                                                   -- 税率
          ,recon_tax_code                                             -- 消込時税コード
          ,recon_tax_rate                                             -- 消込時税率
          ,deduction_tax_amount                                       -- 控除税額
          ,remarks                                                    -- 備考
          ,application_no                                             -- 申請書No.
          ,gl_if_flag                                                 -- GL連携フラグ
          ,gl_base_code                                               -- GL計上拠点
          ,gl_date                                                    -- GL記帳日
          ,recovery_date                                              -- リカバリー日付
          ,cancel_flag                                                -- 取消フラグ
          ,cancel_base_code                                           -- 取消時計上拠点
          ,cancel_gl_date                                             -- 取消GL記帳日
          ,cancel_user                                                -- 取消実施ユーザ
          ,recon_base_code                                            -- 消込時計上拠点
          ,recon_slip_num                                             -- 支払伝票番号
          ,carry_payment_slip_num                                     -- 繰越時支払伝票番号
          ,report_decision_flag                                       -- 速報確定フラグ
          ,gl_interface_id                                            -- GL連携ID
          ,cancel_gl_interface_id                                     -- 取消GL連携ID
          ,created_by                                                 -- 作成者
          ,creation_date                                              -- 作成日
          ,last_updated_by                                            -- 最終更新者
          ,last_update_date                                           -- 最終更新日
          ,last_update_login                                          -- 最終更新ログイン
          ,request_id                                                 -- 要求ID
          ,program_application_id                                     -- コンカレント・プログラム・アプリケーションID
          ,program_id                                                 -- コンカレント・プログラムID
          ,program_update_date                                        -- プログラム更新日
        )VALUES(
           xxcok_sales_deduction_s01.nextval                          -- 販売控除ID
          ,gt_sales_deduction_work_tbl(i).base_code                   -- 振替元拠点
          ,gt_sales_deduction_work_tbl(i).base_code                   -- 振替先拠点
          ,gt_sales_deduction_work_tbl(i).customer_code_from          -- 振替元顧客コード
          ,gt_sales_deduction_work_tbl(i).customer_code_from          -- 振替先顧客コード
          ,gt_sales_deduction_work_tbl(i).introduction_chain_code     -- チェーン店コード
          ,gt_sales_deduction_work_tbl(i).corp_code                   -- 企業コード
          ,gt_sales_deduction_work_tbl(i).record_date                 -- 計上日
          ,cv_const_u                                                 -- 作成元区分
          ,NULL                                                       -- 作成元明細ID
          ,NULL                                                       -- 控除条件ID
          ,lt_condition_no                                            -- 控除番号
          ,NULL                                                       -- 控除詳細ID
          ,gt_sales_deduction_work_tbl(i).data_type                   -- データ種類
          ,cv_const_n                                                 -- ステータス
          ,gt_sales_deduction_work_tbl(i).item_code                   -- 品目コード
          ,NULL                                                       -- 販売単位
          ,NULL                                                       -- 販売単価
          ,NULL                                                       -- 販売数量
          ,NULL                                                       -- 売上本体金額
          ,NULL                                                       -- 売上消費税額
          ,gt_sales_deduction_work_tbl(i).deduction_uom_code          -- 控除単位
          ,gt_sales_deduction_work_tbl(i).deduction_unit_price        -- 控除単価
          ,gt_sales_deduction_work_tbl(i).deduction_quantity          -- 控除数量
          ,gt_sales_deduction_work_tbl(i).deduction_amount            -- 控除額
-- 2022/05/20 Ver1.1 ADD Start
          ,gt_sales_deduction_work_tbl(i).compensation                -- 補填
          ,gt_sales_deduction_work_tbl(i).margin                      -- 問屋マージン
          ,gt_sales_deduction_work_tbl(i).sales_promotion_expenses    -- 拡売
          ,gt_sales_deduction_work_tbl(i).margin_reduction            -- 問屋マージン減額
-- 2022/05/20 Ver1.1 ADD End
          ,gt_sales_deduction_work_tbl(i).tax_code                    -- 税コード
          ,gt_sales_deduction_work_tbl(i).tax_rate                    -- 税率
          ,NULL                                                       -- 消込時税コード
          ,NULL                                                       -- 消込時税率
          ,gt_sales_deduction_work_tbl(i).deduction_tax_amount        -- 控除税額
          ,gt_sales_deduction_work_tbl(i).remarks                     -- 備考
          ,gt_sales_deduction_work_tbl(i).application_no              -- 申請書No.
          ,cv_const_n                                                 -- GL連携フラグ
          ,NULL                                                       -- GL計上拠点
          ,NULL                                                       -- GL記帳日
          ,NULL                                                       -- リカバリー日付
          ,cv_const_n                                                 -- 取消フラグ
          ,NULL                                                       -- 取消時計上拠点
          ,NULL                                                       -- 取消GL記帳日
          ,NULL                                                       -- 取消実施ユーザ
          ,cv_const_n                                                 -- 消込時計上拠点
-- 2022/05/20 Ver1.1 MOD Start
          ,DECODE(gt_sales_deduction_work_tbl(i).paid_flag, 'Y', '-', NULL)
                                                                      -- 支払伝票番号
--          ,NULL                                                       -- 支払伝票番号
          ,DECODE(gt_sales_deduction_work_tbl(i).paid_flag, 'Y', '-', NULL)
                                                                      -- 繰越時支払伝票番号
--          ,NULL                                                       -- 繰越時支払伝票番号
-- 2022/05/20 Ver1.1 MOD End
          ,NULL                                                       -- 速報確定フラグ
          ,NULL                                                       -- GL連携ID
          ,NULL                                                       -- 取消GL連携ID
          ,cn_created_by                                              -- 作成者
          ,cd_creation_date                                           -- 作成日
          ,cn_last_updated_by                                         -- 最終更新者
          ,cd_last_update_date                                        -- 最終更新日
          ,cn_last_update_login                                       -- 最終更新ログイン
          ,cn_request_id                                              -- 要求ID
          ,cn_program_application_id                                  -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                              -- コンカレント・プログラムID
          ,cd_program_update_date                                     -- プログラム更新日
        );
    END LOOP;
--
--#################################  固定例外処理部 START   ####################################
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
  END deduction_date_register;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER     --   ファイルID
   ,iv_file_format  IN   VARCHAR2   --   ファイルフォーマット
   ,ov_errbuf       OUT  VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT  VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT  VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ループ時のカウント
    ln_file_if_loop_cnt  NUMBER; -- ファイルIFループカウンタ
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
    gn_target_cnt        := 0; -- 対象件数
    gn_normal_cnt        := 0; -- 正常件数
    gn_warn_cnt          := 0; -- 警告件数
    gn_error_cnt         := 0; -- エラー件数
--
    -- ローカル変数の初期化
    ln_file_if_loop_cnt  := 0; -- ファイルIFループカウンタ
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       in_file_id        -- ファイルID
      ,iv_file_format    -- ファイルフォーマット
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．IFデータ取得
    -- ============================================
    get_if_data(
       in_file_id        -- ファイルID
      ,iv_file_format    -- ファイルフォーマット
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_api_warn_expt;
    END IF;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．IFデータ削除
    -- ============================================
    delete_if_data(
       in_file_id        -- ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      -- 正常終了の場合はコミット
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロードIFループ
    <<file_if_loop>>
    --１行目はカラム行の為、２行目から処理する
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
      -- ============================================
      -- A-4．アップロードファイル項目分割
      -- ============================================
--
      divide_item(
         ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-5．エラーチェック処理
      -- ============================================
      error_check(
         ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP file_if_loop;
    -- 警告が１件でもあった場合警告処理
    IF ( gn_warn_cnt >= 1 ) THEN
      RAISE global_api_warn_expt;
    END IF;
--
    -- ============================================
    -- A-6．販売控除データ登録処理
    -- ============================================
    IF ( lv_retcode = cv_status_normal ) THEN
      deduction_date_register(
         lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2 --   エラーメッセージ #固定#
   ,retcode          OUT   VARCHAR2 --   エラーコード     #固定#
   ,iv_file_id       IN    VARCHAR2 --   1.ファイルID(必須)
   ,iv_file_format   IN    VARCHAR2 --   2.ファイルフォーマット(必須)
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg   CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg  CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg    CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_const_normal_msg CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg         CONSTANT VARCHAR2(100)  :=  'APP-XXCOK1-10649'; -- 警告終了全ロールバック
    cv_error_msg        CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token        CONSTANT VARCHAR2(10)   :=  'COUNT';            -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      ov_retcode  =>  lv_retcode
     ,ov_errbuf   =>  lv_errbuf
     ,ov_errmsg   =>  lv_errmsg
     ,iv_which    =>  cv_file_type_out
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
       TO_NUMBER(iv_file_id)  -- 1.ファイルID
      ,iv_file_format         -- 2.ファイルフォーマット
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (  lv_retcode = cv_status_error
       OR lv_retcode = cv_status_warn ) THEN
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
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 正常終了以外の場合、ロールバックを発行
      ROLLBACK;
    END IF;
--
    -- エラー発生時
    IF lv_retcode = cv_status_error THEN
      gn_target_cnt := 0; -- 対象件数
      gn_normal_cnt := 0; -- 成功件数
      gn_error_cnt  := 1; -- エラー件数
    ELSIF lv_retcode = cv_status_warn THEN
      gn_normal_cnt := 0; -- 成功件数
    END IF;
    -- ===============================================================
    -- 共通のログメッセージの出力
    -- ===============================================================
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    -- 警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_ccp_10534
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --共通のログメッセージの出力終了
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --終了メッセージの設定、出力
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_const_normal_msg;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_kbn_cok
                   ,iv_name         => lv_message_code
                  );
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    END IF;
    --
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOK024A20C;
/
