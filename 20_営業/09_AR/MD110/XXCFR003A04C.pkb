CREATE OR REPLACE PACKAGE BODY XXCFR003A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A04C(body)
 * Description      : EDI請求書データ作成
 * MD.050           : MD050_CFR_003_A04_EDI請求書データ作成
 * MD.070           : MD050_CFR_003_A04_EDI請求書データ作成
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                   (A-1)
 *  get_fixed_value        p 固定値取得処理                             (A-2)
 *  get_edi_arcode         p EDI請求対象取得ループ処理                  (A-3)
 *  get_edi_date           p EDIデータ取得ループ処理                    (A-4)(A-5)(A-6)
 *                           EDI出力ファイル作成処理                    (A-7)(A-8)(A-9)
 *  pad_edi_char           f EDI書式変換関数
 *  set_edi_char           p EDI文字列整形処理
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/21    1.0   SCS 大川 恵      初回作成
 *  2009/02/16    1.1   SCS 大川 恵      [障害CFR_004] 対象・警告件数出力不具合対応,
 *                                       [障害CFR_005] 原単価出力不具合対応
 *  2009/02/25    1.2   SCS 大川 恵      [障害CFR_017] EDI固定桁数超データ不具合対応
 *  2009/05/07    1.3   SCS 萱原 伸哉    [障害T1_0757] エラー売掛コード1(請求書)設定顧客メッセージ追加
 *  2009/05/08    1.3   SCS 萱原 伸哉    [障害T1_0687] 予備エリア追加、フッタ取得処理修正
 *  2009/05/22    1.4   SCS 萱原 伸哉    [障害T1_1127] EDI請求書のチェーン店コードへの値の設定対応
 *  2009/05/26    1.4   SCS 萱原 伸哉    [障害T1_1128] EDI請求書の請求消費税額／支払消費税額処理修正
                                                       エラー売掛コード1(請求書)設定顧客メッセージ出力箇所変更
 *  2009/05/26    1.4   SCS 萱原 伸哉    [障害T1_1121] EDI請求書の仕入先コード／取引先コード取得処理修正  
 *  2009/06/16    1.5   SCS 萱原 伸哉    [障害T1_1337,T1_1338,T1_1339]
                                                       取引先コード設定処理修正
                                                       請求消費税額／支払消費税額出力処理修正
                                                       レコード順序修正
                                                       請求金額合計,値引き合計,返品合計,返品合計の集計単位修正 
                                                       取引先レコード通番設定処理修正   
                                                       税差額レコード出力処理修正
 *  2009/06/23    1.6   SCS 萱原 伸哉    [障害T1_1379] EDI請求書の伝票番号チェック処理対応
 *  2009/10/15    1.7   SCS 萱原 伸哉     AR仕様変更IE558対応
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  edi_func_h_expt  EXCEPTION;      -- EDIヘッダ付与関数エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A04C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
--
  cv_msg_003a04_001  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_003a04_002  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- 値取得エラーメッセージ
  cv_msg_003a04_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- 共通関数エラーメッセージ
  cv_msg_003a04_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; -- ファイル名出力メッセージ
  cv_msg_003a04_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- 対象データが0件メッセージ
  cv_msg_003a04_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; -- 業務処理日付取得エラーメッセージ
  cv_msg_003a04_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; -- ファイルの場所が無効メッセージ
  cv_msg_003a04_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; -- ファイルをオープンできないメッセージ
  cv_msg_003a04_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00049'; -- ファイルに書込みできないメッセー
  cv_msg_003a04_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00054'; -- ファイルが存在しているメッセージ
  cv_msg_003a04_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00053'; -- EDI設定エラーメッセージ
  cv_msg_003a04_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00069'; -- EDIファイル出力メッセージ
  cv_msg_003a04_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00035'; -- 出力ファイルレコード数メッセージ
  cv_msg_003a04_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00068'; -- EDIオーバーフローメッセージ
  cv_msg_003a04_022  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00070'; -- ファイル出力件数
-- Modify 2009.05.07 Ver1.3 Start
  cv_msg_003a04_023  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00073'; -- エラー売掛コード1(請求書)設定顧客ヘッダメッセージ
  cv_msg_003a04_024  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00074'; -- エラー売掛コード1(請求書)設定顧客明細メッセージ
-- Modify 2009.05.07 Ver1.3 End
-- Modify 2009.06.23 Ver1.6 Start
  cv_msg_003a04_025  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00075'; -- エラー伝票番号メッセージ
  cv_msg_003a04_026  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00076'; -- ファイル出力なしメッセージ  
-- Modify 2009.06.23 Ver1.6 End
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- 値名
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- 共通関数名
  cv_tkn_code        CONSTANT VARCHAR2(15) := 'CODE';             -- 売掛コード１（請求書）
  cv_tkn_name        CONSTANT VARCHAR2(15) := 'NAME';             -- 売掛コード１（請求書）名
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- ファイル名
  cv_tkn_rec         CONSTANT VARCHAR2(15) := 'REC_COUNT';        -- ファイル内レコード数
  cv_tkn_item        CONSTANT VARCHAR2(15) := 'ITEM';             -- 項目
  cv_tkn_rec_num     CONSTANT VARCHAR2(15) := 'FILE_REC_NUM';     -- オーバーフローレコード通番
  cv_tkn_slip_num    CONSTANT VARCHAR2(15) := 'SLIP_NUM';         -- 伝票番号
  cv_tkn_slip_rec    CONSTANT VARCHAR2(15) := 'SLIP_REC_NUM';     -- 伝票番号通番
--
  -- 日本語辞書
  cv_dict_date        CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- 日付パラメータ変換関数
  cv_dict_output_dept CONSTANT VARCHAR2(100) := 'CFR003A04001';    -- EDI出力拠点名
  cv_dict_data_code   CONSTANT VARCHAR2(100) := 'CFR003A04002';    -- データ種コード
  cv_dict_h_func      CONSTANT VARCHAR2(100) := 'CFR003A04003';    -- EDIヘッダ付与関数
  cv_dict_f_func      CONSTANT VARCHAR2(100) := 'CFR003A04004';    -- EDIフッタ付与関数
  cv_dict_arcode1     CONSTANT VARCHAR2(100) := 'CFR003A02003';    -- 売掛コード1(請求書)
  cv_dict_slip_type   CONSTANT VARCHAR2(100) := 'CFR003A04005';    -- 伝票区分
  cv_dict_chain_code  CONSTANT VARCHAR2(100) := 'CFR003A04006';    -- チェーン店コード
  cv_dict_chain_name  CONSTANT VARCHAR2(100) := 'CFR003A04007';    -- チェーン店名称
  cv_dict_file_name   CONSTANT VARCHAR2(100) := 'CFR003A04008';    -- ファイル名
--
  --プロファイル
  cv_org_id               CONSTANT VARCHAR2(30) := 'ORG_ID';                         -- 組織ID
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';               -- 会計帳簿ID
  cv_comp_kana_name       CONSTANT VARCHAR2(35) := 'XXCFR1_INVOICE_ITOEN_KANA_NAME'; -- XXCFR:請求書取引先カナ名
  cv_edi_data_filepath    CONSTANT VARCHAR2(35) := 'XXCFR1_EDI_FILEPATH';            -- XXCFR:EDIファイル格納パス
  cv_edi_output_dept      CONSTANT VARCHAR2(35) := 'XXCFR1_EDI_OUTPUT_DEPT';         -- XXCFR:EDI出力拠点
  cv_edi_data_type        CONSTANT VARCHAR2(35) := 'XXCFR1_INV_EDI_DATA_SET';        -- XXCFR:EDI請求出力項目
-- Modify 2009.05.26 Ver1.4 Start
  cv_comp_code            CONSTANT VARCHAR2(35) := 'XXCFR1_INVOICE_VENDER_CODE';     -- XXCFR:EDI請求書取引先コード
-- Modify 2009.05.26 Ver1.4 End
--
  -- 参照タイプ
  cv_invoice_grp_code     CONSTANT VARCHAR2(30) := 'XXCMM_INVOICE_GRP_CODE'; -- 売掛コード１（請求書）
  cv_discount_code        CONSTANT VARCHAR2(35) := 'XXCFR1_EDI_RETURN_CODE'; -- EDI値引コード
--
  -- 書式変換フォーマット判定用
  cv_str_format_n CONSTANT VARCHAR2(10) := 'N';  -- 数値
  cv_str_format_s CONSTANT VARCHAR2(10) := 'S'; -- 文字列半角
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';         -- フラグ（Ｙ）
  cv_flag_no         CONSTANT VARCHAR2(1)  := 'N';         -- フラグ（Ｎ）
--
  cv_line_type_l     CONSTANT VARCHAR2(4)  := 'LINE';     -- 明細タイプ(=LINE)
  cn_period_months   CONSTANT NUMBER       := 12;         -- 抽出対象期間（月）
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';         -- 日付フォーマット（年月日）
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';       -- 日付フォーマット（年月日スラッシュ付）
  cv_format_date_hms    CONSTANT VARCHAR2(6)  := 'HHMISS';           -- 時間フォーマット（HHMISS）
--
  cd_min_date           CONSTANT DATE         := TO_DATE('1900/01/01',cv_format_date_ymds);
  cd_max_date           CONSTANT DATE         := TO_DATE('9999/12/31',cv_format_date_ymds);
--
  cv_start_mode_b       CONSTANT VARCHAR2(1) := '0'; -- 夜間バッチ
  cv_start_mode_h       CONSTANT VARCHAR2(1) := '1'; -- 手動
--
  -- 請求書出力区分
  cv_inv_prt_type       CONSTANT VARCHAR2(1)  := '3';                       -- 3.EDI
--
  -- 売上返品区分（返品）
  cv_sold_return_type_r CONSTANT VARCHAR2(1)  := '2';                       -- 2.返品
--
    -- 消費税区分
    cv_syohizei_kbn_te  CONSTANT VARCHAR2(1)  := '1';                      -- 外税
--
-- Modify 2009.06.23 Ver1.6 Start
  cv_slip_no_chk_i      CONSTANT VARCHAR2(1)  := 'I';                      -- 納品伝票番号チェック用
-- Modify 2009.06.23 Ver1.6 End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_start_mode_flg           VARCHAR2(1) := '0'; -- 起動フラグ
  gn_org_id                   NUMBER;             -- 組織ID
  gn_set_of_bks_id            NUMBER;             -- 会計帳簿ID
  gv_comp_kana_name           VARCHAR2(100);      -- 請求書取引先カナ名
  gv_edi_data_filepath        VARCHAR2(500);      -- XXCFR:EDIファイル格納パス
  gv_edi_output_dept          VARCHAR2(10) ;      -- XXCFR:EDI出力拠点
  gv_discount_code            VARCHAR2(10);       -- XXCFR:EDI値引コード
-- Modify 2009.05.26 Ver1.4 Start  
  gv_comp_code                VARCHAR2(30);       -- XXCFR:EDI請求書取引先コード
-- Modify 2009.05.26 Ver1.4 End
--
  gv_edi_output_dept_name     VARCHAR2(100) := NULL;     -- EDI出力拠点名
  gv_edi_data_code            VARCHAR2(10)  := NULL;     -- データ種コード
  gv_edi_operation_code       VARCHAR2(10)  := NULL;     -- 業務系列コード
  gv_edi_chain_code           VARCHAR2(500);             -- チェーン店
  gv_edi_chain_name           VARCHAR2(500);             -- チェーン店名称
  gv_edi_data_filename        VARCHAR2(500);             -- EDIファイル名
  gv_ar_code_name             VARCHAR2(500);             -- 売掛コード１（請求書）名称
--
  gd_process_date             DATE;              -- 業務処理日付
  gd_target_date              DATE;              -- パラメータ．締日（データ型変換用）
  gn_output_cnt               NUMBER := '0';     -- ファイル出力件数
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- EDI項目情報取得カーソル
  CURSOR get_edi_item_cur
  IS
  SELECT flvv.attribute1 edi_length
        ,flvv.attribute2 data_type
        ,flvv.attribute3 err_msg_flg
        ,flvv.meaning data_name
  FROM   FND_LOOKUP_VALUES_VL flvv-- クイックコード(EDI請求出力項目)
  WHERE  flvv.lookup_type =cv_edi_data_type
  ORDER BY flvv.lookup_code;
  --===============================================================
  -- グローバルタイプ
  --===============================================================
  TYPE edi_item_ttype      IS TABLE OF get_edi_item_cur%ROWTYPE INDEX BY PLS_INTEGER; -- EDI請求出力項目情報
--
  gt_edi_item_tab              edi_item_ttype;                                       -- EDI請求出力項目情報
--
  /**********************************************************************************
   * Function Name    : pad_edi_char
   * Description      : EDI書式変換関数
   ***********************************************************************************/
  FUNCTION pad_edi_char(
    iv_string_data      IN VARCHAR2,  -- 変換対象文字列	
    iv_data_format      IN VARCHAR2,  -- フォーマット
    in_length           IN NUMBER   ) -- 桁数
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pad_edi_char'; -- プログラム名
--
    -- 空白補完文字列
    cv_trn_format_n CONSTANT VARCHAR2(1) := '0';  -- 数値
    cv_trn_format_s CONSTANT VARCHAR2(1) := ' ';  -- 文字列半角
    cv_minus        CONSTANT VARCHAR2(1) := '-';  -- マイナス記号
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_format    VARCHAR2(2)   := NULL ; -- 空白補完文字
    ln_data_num  NUMBER        := NULL ; -- 数値格納変数
    lv_in_str    VARCHAR2(500) := NULL ; 
    lv_ret_str   VARCHAR2(500) := NULL ; -- 戻り値
--
  BEGIN
--
    -- ====================================================
    -- EDI書式変換関数処理ロジックの記述
    -- ===================================================
--
    -- 空白補完文字の設定
    CASE
      WHEN iv_data_format = cv_str_format_n THEN
        lv_format := cv_trn_format_n;
      WHEN iv_data_format = cv_str_format_s THEN
        lv_format := cv_trn_format_s;
      ELSE
        NULL;
    END CASE;
--
    lv_in_str := NVL(iv_string_data,lv_format);
    lv_ret_str := lv_in_str;
--
    -- 文字列長判定
    IF (LENGTHB(lv_in_str) < in_length) THEN
--
      -- ①数値型の場合
      IF iv_data_format = cv_str_format_n THEN
        -- NUMBER型に変換
        ln_data_num := TO_NUMBER(NVL(lv_in_str,lv_format));
        lv_ret_str := LPAD(TO_CHAR(ABS(ln_data_num)),in_length,lv_format);
        IF ln_data_num < 0 THEN
          lv_ret_str := cv_minus || SUBSTR(lv_ret_str,2);
        END IF;
      -- ②文字列型の場合
      ELSIF iv_data_format = cv_str_format_s THEN
        lv_ret_str := lv_in_str;
        <<data_loop>>
        LOOP
          IF LENGTHB(lv_ret_str) < in_length THEN
            lv_ret_str := lv_ret_str || cv_trn_format_s;
          ELSE
            EXIT;
          END IF;
        END LOOP data_loop;
      ELSE
        NULL;
      END IF;
    END IF;
--
    RETURN lv_ret_str;
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
      RETURN NULL;
  END pad_edi_char;
--
  /**********************************************************************************
   * Procedure Name   : set_edi_char
   * Description      : EDI文字列整形処理
   ***********************************************************************************/
  PROCEDURE set_edi_char(
    iv_order_num   IN NUMBER,        -- 項目順
    iv_string_data IN VARCHAR2,      -- 変換対象文字列
    iv_rec_num     IN VARCHAR2,      -- レコード通番
    iv_slip_num    IN VARCHAR2,      -- 伝票番号
    iv_slip_rec    IN VARCHAR2,      -- 伝票行No
    ov_ret_str     OUT VARCHAR2,     -- 戻り値
    ov_errbuf      OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_edi_char'; -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_data_num        NUMBER        := NULL ; -- 数値格納変数
    lv_type            VARCHAR2(10)  := NULL ; -- データ型
    lv_flg             VARCHAR2(10)  := NULL ; -- メッセージ出力フラグ
    lv_in_str          VARCHAR2(5000) := NULL ; 
    ln_length          NUMBER        := NULL ; -- 文字列長
    lv_ret_str         VARCHAR2(500) := NULL ; -- 戻り値
    lv_overflow_msg    VARCHAR2(5000);         -- EDI出力ファイル桁数オーバーフローメッセージ
--
  BEGIN
--
    -- ====================================================
    -- EDI書式変換関数処理ロジックの記述
    -- ===================================================
--
    -- 文字列長取得処理
    ln_length := gt_edi_item_tab(iv_order_num).edi_length;
    IF ln_length IS NULL THEN
      -- 警告
      ov_retcode := cv_status_warn;
    END IF;
--
    -- データ型取得処理
    lv_type := gt_edi_item_tab(iv_order_num).data_type;
    IF lv_type IS NULL THEN
      lv_type := cv_str_format_s;
    END IF;
--
    -- 警告メッセージ出力フラグ取得処理
    lv_flg := gt_edi_item_tab(iv_order_num).err_msg_flg;
    IF lv_flg IS NULL THEN
      lv_flg := cv_flag_no;
    END IF;
--
    lv_in_str := iv_string_data;
    -- 文字列長判定
    IF (LENGTHB(lv_in_str) > ln_length) THEN
      -- 指定桁にて値切捨て
      ov_ret_str := SUBSTRB(lv_in_str
                           ,1
                           ,ln_length);
      IF lv_flg = cv_flag_yes THEN
        -- 終了ステータスを警告に変更
        ov_retcode := cv_status_warn;
        -- 警告メッセージ出力
        lv_overflow_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                            ,cv_msg_003a04_021    -- EDIオーバーフローメッセージ
                                                            ,cv_tkn_item          -- トークン'ITEM'
                                                            ,gt_edi_item_tab(iv_order_num).data_name
                                                            ,cv_tkn_file          -- トークン'FILE_NAME'
                                                            ,gv_edi_data_filename -- ファイル名
                                                            ,cv_tkn_rec_num       -- トークン'FILE_REC_NUM'
                                                            ,iv_rec_num           -- 集計ループカウンタ
                                                            ,cv_tkn_slip_num      -- トークン'SLIP_NUM'
                                                            ,iv_slip_num          -- 伝票番号
                                                            ,cv_tkn_slip_rec      -- トークン'SLIP_REC_NUM'
                                                            ,iv_slip_rec)         -- 伝票行No
                           ,1
                           ,5000);
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_overflow_msg
        );
      END IF;
    ELSE
      ov_ret_str := lv_in_str;
    END IF;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      ov_ret_str := NULL;
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
--
--###################################  固定部 END   #########################################
--
  END set_edi_char;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date          IN  VARCHAR2,     -- 締日
    iv_ar_code1             IN  VARCHAR2,     -- 売掛コード１(請求書)
    iv_start_mode           IN  VARCHAR2,     -- 起動区分
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入力パラメータ．起動区分をセット
    gv_start_mode_flg := iv_start_mode;
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- 手動起動の場合
    IF (iv_start_mode = cv_start_mode_h) THEN
      -- パラメータ．締日をDATE型に変換する
      gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
      IF (gd_target_date IS NULL) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a04_003 -- 共通関数エラー
                                                      ,cv_tkn_func       -- トークン'FUNC_NAME'
                                                      ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                         ,cv_dict_date))
                                                      -- 日付パラメータ変換関数
                            ,1
                            ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_out             -- メッセージ出力
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- 締日
                                   ,iv_conc_param2  => iv_ar_code1                  -- 売掛コード１（請求書）
                                   ,iv_conc_param3  => iv_start_mode                -- 起動区分
                                   ,ov_errbuf       => ov_errbuf                    -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode                   -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);                  -- ユーザー・エラー・メッセージ
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log             -- ログ出力
                                   ,iv_conc_param1  => TO_CHAR(gd_target_date
                                                              ,cv_format_date_ymds) -- 締日
                                   ,iv_conc_param2  => iv_ar_code1                  -- 売掛コード１（請求書）
                                   ,iv_conc_param3  => iv_start_mode                -- 起動区分
                                   ,ov_errbuf       => ov_errbuf                    -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode                   -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);                  -- ユーザー・エラー・メッセージ
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_fixed_value
   * Description      : 固定値取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_fixed_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fixed_value'; -- プログラム名
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
    cv_flex_value_set_name        CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT';
    cv_lookup_type                CONSTANT VARCHAR2(21) := 'XXCOS1_DATA_TYPE_CODE';
    cv_lookup_code                CONSTANT VARCHAR2(3)  := '110';
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
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- 会計帳簿ID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- 組織ID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:請求書取引先カナ名取得
    gv_comp_kana_name := FND_PROFILE.VALUE(cv_comp_kana_name);
    -- 取得エラー時
    IF (gv_comp_kana_name IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_comp_kana_name))
                                                       -- XXCFR:請求書取引先カナ名
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.05.26 Ver1.4 Start
    -- プロファイルからXXCFR:EDI請求書取引先コード取得
    gv_comp_code := FND_PROFILE.VALUE(cv_comp_code);
    -- 取得エラー時
    IF (gv_comp_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_comp_code))
                                                       -- XXCFR:EDI請求書取引先コード
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.05.26 Ver1.4 End
    -- プロファイルからXXCFR:EDIファイル格納パス取得
    gv_edi_data_filepath := FND_PROFILE.VALUE(cv_edi_data_filepath);
    -- 取得エラー時
    IF (gv_edi_data_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_edi_data_filepath))
                                                       -- XXCFR:EDIファイル格納パス
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:EDI出力拠点取得
    gv_edi_output_dept := FND_PROFILE.VALUE(cv_edi_output_dept);
    -- 取得エラー時
    IF (gv_edi_output_dept IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_001 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_edi_output_dept))
                                                       -- XXCFR:EDI出力拠点
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- EDI出力拠点名取得処理
    BEGIN
      SELECT ffvv.description   edi_output_dept_name             -- 摘要
      INTO gv_edi_output_dept_name
      FROM fnd_flex_value_sets  ffvs,                            -- 値セット
           fnd_flex_values_vl   ffvv                             -- 値セット値ビュー
      WHERE ffvs.flex_value_set_name = cv_flex_value_set_name
      AND   ffvs.flex_value_set_id   = ffvv.flex_value_set_id
      AND   ffvv.flex_value          = gv_edi_output_dept;
    EXCEPTION
      WHEN OTHERS THEN
        gv_edi_output_dept_name := NULL;
    END;
    -- 取得エラー時
    IF (gv_edi_output_dept_name IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_002 -- 値取得エラー
                                                    ,cv_tkn_data       -- トークン'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                        ,cv_dict_output_dept ))
                                                                                        -- XXCFR:EDI出力拠点名
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 業務処理日付取得処理
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
    -- 取得エラー時
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_013 -- 業務処理日付取得エラー
                                                    )
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- データ種コード取得処理
    BEGIN
      SELECT ffvv.meaning    data_code,                          -- データ種コード
             ffvv.attribute1 operation_code                      -- 業務系列コード
      INTO gv_edi_data_code,
           gv_edi_operation_code
      FROM fnd_lookup_values_vl  ffvv                            -- クイックコードビュー
      WHERE ffvv.lookup_type = cv_lookup_type
        AND ffvv.lookup_code = cv_lookup_code
        AND ffvv.enabled_flag = cv_flag_yes
        AND gd_process_date BETWEEN NVL(ffvv.start_date_active ,cd_min_date) AND
                                    NVL(ffvv.end_date_active ,cd_max_date);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- 取得エラー時
    IF (gv_edi_data_code IS NULL) OR (gv_edi_operation_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_002 -- 値取得エラー
                                                    ,cv_tkn_data       -- トークン'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                        ,cv_dict_data_code ))
                                                                                        -- XXCFR:EDI値引コード
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_fixed_value;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_date
   * Description      : EDIデータ取得ループ処理・EDI出力ファイル作成処理
                        (A-4)(A-5)(A-6)(A-7)(A-8)(A-9)
   ***********************************************************************************/
  PROCEDURE get_edi_date(
    iv_target_date IN  VARCHAR2,     -- 締日
    iv_ar_code1    IN  VARCHAR2,     -- 売掛コード１(請求書)
    iv_start_mode  IN  VARCHAR2,     -- 起動区分
    ov_errbuf      OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_date'; -- プログラム名
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
    cv_add_area_h     CONSTANT VARCHAR2(10) := 'H';     -- 付与区分（ヘッダ付与）
    cv_rec_type_d     CONSTANT VARCHAR2(1)  := 'D';     -- 付与区分（明細付与）
    cv_add_area_f     CONSTANT VARCHAR2(10) := 'F';     -- 付与区分（フッタ付与）
    cv_row_number     CONSTANT VARCHAR2(2)  := '01';    -- 並列処理番号
    cv_return_type    CONSTANT VARCHAR2(10) := '2';     -- 付与区分（フッタ付与）
--
    cv_nul_v_code     CONSTANT VARCHAR2(8)  := 'NUL_CODE';        -- NULL値補完文字（取引先コード）
    cv_nul_slip_num   CONSTANT VARCHAR2(12) := 'NUL_SLIP_NUM';    -- NULL値補完文字（伝票番号）
    cv_end_v_code     CONSTANT VARCHAR2(11) := '***END_C';        -- 終了判定（取引先コード）
    cv_end_inv_id     CONSTANT VARCHAR2(13) := '***END_I';        -- 終了判定（請求書ID）
    cv_end_slip_num   CONSTANT VARCHAR2(15) := '***END_S';        -- 終了判定（伝票番号）
--
    -- 空白補完（日付・時間）
    cv_trn_format_d   CONSTANT VARCHAR2(8)  := '00000000'; -- DATE型
    cv_trn_format_t   CONSTANT VARCHAR2(6)  := '000000';   -- TIME型
--
    -- 小数項目
    cv_num_format_t   CONSTANT VARCHAR2(10) := '9999.99';         -- 消費税率
    cv_num_format_u   CONSTANT VARCHAR2(25) := '99999999999999999999.99'; -- 原単価
--
    -- *** ローカル変数 ***
    -- 件数カウント
    ln_target_cnt   NUMBER;         -- EDIデータテーブルヒット件数
    ln_data_cnt     NUMBER;         -- 集計結果格納先レコードカウンタ
    ln_loop_cnt     NUMBER;         -- 集計ループカウンタ
    ln_rec_cnt      NUMBER;         -- 出力ループカウンタ
--
    ln_vend_cnt     NUMBER;         -- 取引先内レコードカウンタ
    ln_slip_num     NUMBER;         -- 伝票枚数（取引先コード単位）
--
    -- 金額合計変数
    ln_slip_amount  NUMBER;         -- 請求金額（伝票単位）
-- Modify 2009.06.08 Ver1.5 Start
    ln_slip_tax_amount  NUMBER;     -- 請求消費税額（伝票単位）
-- Modify 2009.06.08 Ver1.5 END
    ln_vend_amount  NUMBER;         -- 請求金額合計（取引先コード単位）
    ln_disc_amount  NUMBER;         -- 値引き合計（取引先コード単位）
    ln_retn_amount  NUMBER;         -- 返品合計（取引先コード単位）
--
    -- ブレイク変数
    lv_b_slip_num   VARCHAR2(300);   -- 伝票番号
    lv_b_inv_id     VARCHAR2(300);   -- 一括請求書ID
    lv_b_vend_cd    VARCHAR2(300);    -- 取引先コード
--
    -- 更新開始位置
    ln_slip_point   NUMBER;         -- 更新開始位置（伝票）
    ln_inv_point    NUMBER;         -- 更新開始位置（一括請求書ID）
    ln_vend_point   NUMBER;         -- 更新開始位置（取引先コード）
--
    -- ファイル出力関連
    lf_file_hand    UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_edi_text     VARCHAR2(32767) ;       -- 1行当たりの最大文字数
    lv_output       VARCHAR2(32767);        -- EDIヘッダ・フッタ共通関数出力値
--
    -- 
    lv_output_str          VARCHAR2(5000);  -- EDI出力項目格納変数
    lv_overflow_msg        VARCHAR2(5000);  -- EDI出力ファイル桁数オーバーフローメッセージ
    lv_output_file_msg     VARCHAR2(5000);  -- EDI出力ファイル名メッセージ
    lv_output_rec_num_msg  VARCHAR2(5000);  -- EDI出力ファイルレコード数メッセージ
--
-- Modify 2009.06.15 Ver1.5 Start
    lv_tax_gap_out_flg     VARCHAR2(1);     -- 税差額取引出力フラグ
-- Modify 2009.06.15 Ver1.5 End
-- Modify 2009.06.23 Ver1.6 Start
    -- 伝票番号チェック用変数
    lv_chk_bef_slip        VARCHAR2(300);   -- 伝票番号
    ln_chk_slip_buf        NUMBER;
    lv_chk_err_flg         VARCHAR(1);
    lv_slip_warn_msg       VARCHAR2(5000) := NULL; -- 伝票番号不正警告メッセージ
--
    num_err_expt           EXCEPTION;     -- 数値無効エラー
--
    PRAGMA EXCEPTION_INIT(num_err_expt, -06502);
-- Modify 2009.06.23 Ver1.6 End
    -- *** ローカル・カーソル ***
--
    -- EDI請求データ抽出
    CURSOR get_edi_data_cur(
      iv_ar_code1    VARCHAR2)
    IS
      SELECT cv_rec_type_d                            file_rec_type          -- レコード区分
            ,NULL                                     file_rec_num           -- レコード通番
-- Modify 2009.05.22 Ver1.4 Start
--            ,NULL                                     chain_st_code          -- チェーン店コード
            ,gv_edi_chain_code                        chain_st_code          -- チェーン店コード
-- Modify 2009.05.22 Ver1.4 End
            ,TO_CHAR(xih.inv_creation_date
                    ,cv_format_date_ymd)              inv_creation_day       -- データ作成日
            ,TO_CHAR(xih.inv_creation_date
                    ,cv_format_date_hms)              inv_creation_time      -- データ作成時刻
-- Modify 2009.06.05 Ver1.5 Start
-- Modify 2009.05.26 Ver1.4 Start                    
--            ,NVL(xih.vender_code,cv_nul_v_code)       vender_code            -- 仕入先コード／取引先コード
--            ,gv_comp_code                             vender_code            -- 仕入先コード／取引先コード
            ,NVL(xih.vender_code,gv_comp_code)        vender_code           -- 仕入先コード／取引先コード
-- Modify 2009.05.26 Ver1.4 End
-- Modify 2009.06.05 Ver1.5 End
            ,TO_CHAR(xih.invoice_id)                  invoice_id             -- 一括請求書ID
            ,xih.tax_gap_amount                       tax_gap_amount         -- 税差額
            ,SUBSTRB(xih.itoen_name,1,30)             itoen_name             -- 仕入先名称／取引先名称（漢字）
            ,gv_comp_kana_name                        itoen_kana_name        -- 仕入先名称／取引先名称（カナ）
            ,NULL                                     co_code                -- 社コード
            ,TO_CHAR(xih.object_date_from
                    ,cv_format_date_ymd)              object_date_from       -- 対象期間・自
            ,TO_CHAR(xih.object_date_to
                    ,cv_format_date_ymd)              object_date_to         -- 対象期間・至
            ,TO_CHAR(xih.cutoff_date
                    ,cv_format_date_ymd)              cutoff_date            -- 請求締年月日
            ,TO_CHAR(xih.payment_date
                    ,cv_format_date_ymd)              payment_date           -- 支払年月日
            ,xih.due_months_forword                   due_months_forword     -- サイト月数
            ,NULL                                     inv_slip_ttl           -- 伝票枚数
            ,NULL                                     cor_slip_ttl           -- 訂正伝票枚数
            ,NULL                                     n_ins_slip_ttl         -- 未検収伝票枚数
            ,NULL                                     vend_rec_num           -- 取引先内レコード通番
            ,NULL                                     inv_no                 -- 請求書No／請求番号
            ,xil.inv_type                             inv_type               -- 請求区分
            ,NULL                                     pay_type               -- 支払区分
            ,NULL                                     pay_meth_type          -- 支払方法区分
            ,NULL                                     iss_type               -- 発行区分
            ,xil.ship_shop_code                       ship_shop_code         -- 店コード
            ,xil.ship_cust_name                       ship_cust_name         -- 店舗名称（漢字）
            ,xil.ship_cust_kana_name                  ship_cust_kana_name    -- 店舗名称（カナ）
            ,NULL                                     inv_sign               -- 請求金額符号／請求消費税額符号
            ,xil.ship_amount + xil.tax_amount         inv_slip_amount        -- 請求金額／支払金額
            ,xih.tax_type                             tax_type               -- 消費税区分
            ,LTRIM(REPLACE(TO_CHAR(TRUNC(xil.tax_rate,2)
                                  ,cv_num_format_t)
                          ,cv_msg_cont))              tax_rate               -- 消費税率
            ,xil.tax_amount                           tax_amount             -- 請求消費税額／支払消費税額
            ,xih.tax_gap_trx_id                       tax_gap_trx_id         -- 税差額取引ID
            ,0                                        tax_gap_flg            -- 消費税差額フラグ
            ,NULL                                     mis_calc_type          -- 違算区分
            ,NULL                                     match_type             -- マッチ区分
            ,NULL                                     unmatch_pay_amount     -- アンマッチ買掛計上金額
            ,NULL                                     overlap_type           -- ダブリ区分
            ,TO_CHAR(xil.acceptance_date
                    ,cv_format_date_ymd)              acceptance_date        -- 検収日
            ,xih.month_remit                          month_remit            -- 月限
            ,NVL(xil.slip_num,cv_nul_slip_num)        slip_num               -- 伝票番号
            ,xil.note_line_id                         note_line_id           -- 行No
            ,xil.slip_type                            slip_type              -- 伝票区分
            ,xil.classify_type                        classify_type          -- 分類コード
            ,xil.customer_dept_code                   customer_dept_code     -- 相手先部門コード
            ,xil.customer_division_code               customer_division_code -- 課コード
            ,xil.sold_return_type                     sold_return_type       -- 売上返品区分
            ,xil.nichiriu_by_way_type                 nichiriu_by_way_type   -- ニチリウ経由区分
            ,xil.sale_type                            sale_type              -- 特売区分
            ,xil.direct_num                           direct_num             -- 便No
            ,TO_CHAR(xil.po_date
                    ,cv_format_date_ymd)              po_date                -- 発注日
            ,TO_CHAR(xil.delivery_date
                    ,cv_format_date_ymd)              delivery_date          -- 納品日／返品日
            ,xil.item_code                            item_code              -- 商品コード
            ,xil.item_name                            item_name              -- 商品名（漢字）
            ,xil.item_kana_name                       item_kana_name         -- 商品名(カナ)
            ,TRUNC(xil.quantity)                      quantity               -- 納品数量
            ,LTRIM(REPLACE(TO_CHAR(xil.unit_price,cv_num_format_u)
                  ,cv_msg_cont))                      unit_price             -- 原単価
            ,xil.sold_amount                          sold_amount            -- 原価金額
            ,xil.sold_location_code                   sold_location_code     -- 備考コード
            ,NULL                                     chain_st_area          -- チェーン店固有エリア
            ,xil.ship_amount + xil.tax_amount         inv_amount             -- 請求合計金額／支払合計金額
            ,CASE
               WHEN (SELECT COUNT(*)
                     FROM fnd_lookup_values_vl  ffvv -- クイックコードビュー
                     WHERE ffvv.lookup_type = cv_discount_code -- 'XXCFR1_EDI_RETURN_CODE' -- EDI値引コード
                       AND ffvv.lookup_code IN xil.item_code
                       AND ffvv.enabled_flag = cv_flag_yes --'Y'--
                       AND gd_process_date BETWEEN NVL(ffvv.start_date_active ,cd_min_date) AND
                                                   NVL(ffvv.end_date_active ,cd_max_date)
                    ) > 0 THEN xil.ship_amount + xil.tax_amount
               ELSE 0
             END                                      discount_amount        -- 値引合計金額
            ,CASE xil.sold_return_type
               WHEN cv_sold_return_type_r THEN xil.ship_amount + xil.tax_amount
               ELSE 0
             END                                      return_amount          -- 返品合計金額
-- Modify 2009.10.15 Ver1.7 Start
           ,xil.jan_code                              jan_code               -- JANコード
           ,xil.num_of_cases                          num_of_cases           -- ケース入数
           ,xil.medium_class                          medium_class           -- 受注ソース
-- Modify 2009.10.15 Ver1.7 End
      FROM xxcfr_invoice_headers          xih    -- 請求ヘッダ
          ,xxcfr_invoice_lines            xil    -- 請求明細
      WHERE xih.invoice_id = xil.invoice_id      -- 一括請求書ID
        AND EXISTS (SELECT 'X'
                    FROM  xxcfr_bill_customers_v xbcv
                    WHERE xih.bill_cust_code = xbcv.bill_customer_code
                      AND xbcv.receiv_code1  = iv_ar_code1
                      AND xbcv.inv_prt_type  = cv_inv_prt_type -- '3'(EDI)
                   )
        AND ((gv_start_mode_flg = cv_start_mode_b
              AND EXISTS (SELECT 'x'
                          FROM xxcfr_inv_info_transfer xiit  -- 請求情報引渡テーブル
                          WHERE xih.request_id = xiit.request_id
                            AND xiit.set_of_books_id = gn_set_of_bks_id
                            AND xiit.org_id = gn_org_id)) OR
             (gv_start_mode_flg = cv_start_mode_h
              AND xih.cutoff_date = gd_target_date ))        -- パラメータ．締日
        AND xih.set_of_books_id = gn_set_of_bks_id
        AND xih.org_id = gn_org_id
-- Modify 2009.06.05 Ver1.5 Start
--      ORDER BY xih.vender_code   -- 取引先コード
--              ,xih.invoice_id    -- 一括請求書ID
--              ,xil.slip_num      -- 伝票番号
--              ,xil.note_line_id  -- 行No
-- Modify 2009.06.16 Ver1.5 Start
--      ORDER BY xih.vender_code                                -- 取引先コード
      ORDER BY NVL(xih.vender_code, gv_comp_code)             -- 取引先コード
-- Modify 2009.06.16 Ver1.5 End      
              ,xil.ship_shop_code                             -- 店コード
              ,NVL(xil.acceptance_date, xil.delivery_date)    -- 検収日(納品日)
              ,xil.slip_num                                   -- 伝票番号
              ,xil.note_line_id                               -- 行No
-- Modify 2009.06.05 Ver1.5 End
      ;
--
    TYPE get_edi_data_tbl1 IS TABLE OF get_edi_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_get_edi_data_tbl1    get_edi_data_tbl1; -- 取得結果格納用
    lt_set_edi_data_tbl1    get_edi_data_tbl1; -- 集計結果格納用
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
    --===============================================================
    -- 
    --===============================================================
    -- カーソルオープン
    OPEN get_edi_data_cur(iv_ar_code1);
--
    -- データの一括取得
    FETCH get_edi_data_cur BULK COLLECT INTO lt_get_edi_data_tbl1;
--
    -- 処理件数のセット
    ln_target_cnt := lt_get_edi_data_tbl1.COUNT;
    -- カーソルクローズ
    CLOSE get_edi_data_cur;
--
-- Modify 2009.06.23 Ver1.6 Start
    -- エラーチェック用のフラグを初期化
    lv_chk_err_flg := cv_flag_no;
--
    <<check_loop>>
    FOR i IN 1..(ln_target_cnt) LOOP
      -- 前回レコードと伝票番号が異なる場合にエラーチェックを実行
      IF (i = 1) OR 
         (lt_get_edi_data_tbl1(i).slip_num != NVL(lv_chk_bef_slip,cv_end_slip_num)) OR
         (lt_get_edi_data_tbl1(i).slip_num != NULL)
      THEN
        -- 伝票番号が一桁で"I"の場合、エラー
        IF (lt_get_edi_data_tbl1(i).slip_num = cv_slip_no_chk_i) THEN
--
          --エラー伝票番号メッセージ
          lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                        cv_msg_kbn_cfr         -- 'XXCFR'
                                       ,cv_msg_003a04_025      -- エラー伝票番号メッセージ
                                       ,cv_tkn_slip_num        -- トークン'SLIP_NUM'
                                       ,lt_get_edi_data_tbl1(i).slip_num)
                                     ,1
                                     ,5000);
          FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_slip_warn_msg
          );
--
          -- エラーチェック用のフラグをセット
          lv_chk_err_flg := cv_flag_yes;
--        
        -- 伝票番号の一桁目が"I"の場合
        ELSIF (SUBSTRB(lt_get_edi_data_tbl1(i).slip_num, 1, 1) = cv_slip_no_chk_i) THEN
--
          BEGIN
            ln_chk_slip_buf := TO_NUMBER(SUBSTRB(lt_get_edi_data_tbl1(i).slip_num, 2));
          EXCEPTION
            -- *** 数値変換エラー ***  
            WHEN num_err_expt THEN
              -- エラー伝票番号メッセージ
              lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                            cv_msg_kbn_cfr         -- 'XXCFR'
                                           ,cv_msg_003a04_025      -- エラー伝票番号メッセージ
                                           ,cv_tkn_slip_num        -- トークン'SLIP_NUM'
                                           ,lt_get_edi_data_tbl1(i).slip_num)
                                         ,1
                                         ,5000);
              FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_slip_warn_msg
              );
--
              -- エラーチェック用のフラグをセット
              lv_chk_err_flg := cv_flag_yes;
--
           END;
--
         -- 伝票番号の一桁目が"I"以外の場合
         ELSE
--
           BEGIN
             ln_chk_slip_buf := TO_NUMBER(lt_get_edi_data_tbl1(i).slip_num);
           EXCEPTION
            -- *** 数値変換エラー ***
            WHEN num_err_expt THEN
              -- エラー伝票番号メッセージ
              lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                            cv_msg_kbn_cfr         -- 'XXCFR'
                                           ,cv_msg_003a04_025      -- エラー伝票番号メッセージ
                                           ,cv_tkn_slip_num        -- トークン'SLIP_NUM'
                                           ,lt_get_edi_data_tbl1(i).slip_num)
                                         ,1
                                         ,5000);
              FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_slip_warn_msg
              );
--
              -- エラーチェック用のフラグをセット
              lv_chk_err_flg := cv_flag_yes;
--
          END;
--
        END IF;
      END IF;
--
      -- 伝票番号を保管
      lv_chk_bef_slip := lt_get_edi_data_tbl1(i).slip_num;
--
    END LOOP check_loop;
-- Modify 2009.06.23 Ver1.6 End     
    -- 変数の初期化
    ln_vend_cnt := 1;
    ln_data_cnt := 1;
--
    ln_slip_num    := 0;
    ln_slip_amount := 0;
-- Modify 2009.06.08 Ver1.5 Start
    ln_slip_tax_amount := 0;
-- Modify 2009.06.08 Ver1.5 End
    ln_vend_amount := 0;
    ln_disc_amount := 0;
    ln_retn_amount := 0;
--
    ln_slip_point := 1;
    ln_inv_point  := 1;
    ln_vend_point := 1;
--
-- Modify 2009.06.23 Ver1.6 Start
--    IF (ln_target_cnt > 0) THEN
    -- 対象件数が存在するかつ、伝票番号チェックでエラーが存在しなかった場合
    IF (ln_target_cnt > 0)           AND
       (lv_chk_err_flg = cv_flag_no)
    THEN
-- Modify 2009.06.23 Ver1.6 End
--
      <<invoice_loop>>
      FOR i IN 1..(ln_target_cnt + 1) LOOP
        -- 一件目の処理である場合
        IF(i = 1) THEN
          lv_b_slip_num := lt_get_edi_data_tbl1(i).slip_num;
          lv_b_inv_id   := lt_get_edi_data_tbl1(i).invoice_id;
          lv_b_vend_cd  := lt_get_edi_data_tbl1(i).vender_code;
        -- 最終レコードの処理である場合
        ELSIF (i = ln_target_cnt + 1) THEN
          -- ダミーコードをブレイク変数に設定
          lt_get_edi_data_tbl1(i).vender_code := cv_end_v_code;
          lt_get_edi_data_tbl1(i).invoice_id  := cv_end_inv_id;
          lt_get_edi_data_tbl1(i).slip_num    := cv_end_slip_num;
        END IF;
--
        -- ブレイクごとに集計更新
--
        -- 前行伝票番号が現在行伝票番号でない場合、
        -- 伝票単位の集計処理を前行伝票番号レコードに対して行う
        IF (lv_b_slip_num <> lt_get_edi_data_tbl1(i).slip_num) THEN
          <<slip_loop>>
          FOR j IN ln_slip_point..(ln_data_cnt - 1) LOOP
            -- 請求金額符号の設定
            CASE
              -- マイナスである場合
              WHEN ln_slip_amount < 0 THEN
                lt_set_edi_data_tbl1(j).inv_sign := 1;
              -- プラスである場合
              ELSE
                lt_set_edi_data_tbl1(j).inv_sign := 0;
            END CASE;
            -- 請求金額（絶対値）の更新
            lt_set_edi_data_tbl1(j).inv_slip_amount := ABS(ln_slip_amount);
-- Modify 2009.06.08 Ver1.5 Start
            -- 消費税金額（絶対値）の更新
            lt_set_edi_data_tbl1(j).tax_amount := ABS(ln_slip_tax_amount);
-- Modify 2009.06.08 Ver1.5 End
          END LOOP slip_loop;
          -- 請求金額（伝票単位）変数クリア
          ln_slip_amount := 0;
-- Modify 2009.06.08 Ver1.5 Start
          -- 消費税金額（伝票単位）変数クリア
          ln_slip_tax_amount := 0;
-- Modify 2009.06.08 Ver1.5 End
          -- ブレイク変数更新
          lv_b_slip_num := lt_get_edi_data_tbl1(i).slip_num;
          -- 伝票枚数更新
          ln_slip_num := ln_slip_num + 1;
          -- 更新開始位置更新
          ln_slip_point := ln_data_cnt;
          -- 請求金額の初期化
          ln_slip_amount := 0;
        END IF;
--
        -- 前行一括請求書IDが現在行一括請求書IDでない場合
        IF (lv_b_inv_id <> lt_get_edi_data_tbl1(i).invoice_id) THEN
          -- 前行消費税区分=外税かつ前行税差額取引IDがNULLでない場合、税差額レコード挿入
          IF (lt_get_edi_data_tbl1(i-1).tax_type = cv_syohizei_kbn_te) AND
             (lt_get_edi_data_tbl1(i-1).tax_gap_trx_id IS NOT NULL) THEN
--
-- Modify 2009.06.15 Ver1.5 Start
            lv_tax_gap_out_flg := cv_flag_yes;
            -- 同一一括請求書IDが後続のレコードに存在するか確認
            <<tax_gap_out_loop>>
            FOR l IN i..(ln_target_cnt) LOOP
              IF (lv_b_inv_id = lt_get_edi_data_tbl1(l).invoice_id) THEN
                -- 税差額取引出力フラグをNに設定
                lv_tax_gap_out_flg := cv_flag_no;
              END IF;
            END LOOP tax_gap_out_loop;
--
            --税差額取引出力フラグがYの場合、税差額レコード挿入
            IF (lv_tax_gap_out_flg = cv_flag_yes) THEN
--
-- Modify 2009.06.15 Ver1.5 End
            lt_set_edi_data_tbl1(ln_data_cnt).file_rec_type
              := lt_get_edi_data_tbl1(i-1).file_rec_type;                      -- レコード区分
-- Modify 2009.05.22 Ver1.4 Start
--            lt_set_edi_data_tbl1(ln_data_cnt).chain_st_code := NULL ;          -- チェーン店コード
            lt_set_edi_data_tbl1(ln_data_cnt).chain_st_code  
              := lt_get_edi_data_tbl1(i-1).chain_st_code          ;            -- チェーン店コード
-- Modify 2009.05.22 Ver1.4 End
            lt_set_edi_data_tbl1(ln_data_cnt). inv_creation_day      
              := lt_get_edi_data_tbl1(i-1). inv_creation_day      ;            -- データ作成日
            lt_set_edi_data_tbl1(ln_data_cnt).inv_creation_time      
              := lt_get_edi_data_tbl1(i-1).inv_creation_time      ;            -- データ作成時刻
            lt_set_edi_data_tbl1(ln_data_cnt).vender_code            
              := lt_get_edi_data_tbl1(i-1).vender_code            ;            -- 仕入先コード／取引先コード
            lt_set_edi_data_tbl1(ln_data_cnt).itoen_name             
              := lt_get_edi_data_tbl1(i-1).itoen_name             ;            -- 仕入先名称／取引先名称（漢字）
            lt_set_edi_data_tbl1(ln_data_cnt).itoen_kana_name        
              := lt_get_edi_data_tbl1(i-1).itoen_kana_name        ;            -- 仕入先名称／取引先名称（カナ）
            lt_set_edi_data_tbl1(ln_data_cnt).co_code := NULL ;                -- 社コード
            lt_set_edi_data_tbl1(ln_data_cnt).object_date_from       
              := lt_get_edi_data_tbl1(i-1).object_date_from       ;            -- 対象期間・自
            lt_set_edi_data_tbl1(ln_data_cnt).object_date_to         
              := lt_get_edi_data_tbl1(i-1).object_date_to         ;            -- 対象期間・至
            lt_set_edi_data_tbl1(ln_data_cnt).cutoff_date            
              := lt_get_edi_data_tbl1(i-1).cutoff_date            ;            -- 請求締年月日
            lt_set_edi_data_tbl1(ln_data_cnt).payment_date           
              := lt_get_edi_data_tbl1(i-1).payment_date           ;            -- 支払年月日
            lt_set_edi_data_tbl1(ln_data_cnt).due_months_forword     
              := lt_get_edi_data_tbl1(i-1).due_months_forword     ;            -- サイト月数
            lt_set_edi_data_tbl1(ln_data_cnt).cor_slip_ttl           := NULL ; -- 訂正伝票枚数
            lt_set_edi_data_tbl1(ln_data_cnt).n_ins_slip_ttl         := NULL ; -- 未検収伝票枚数
            lt_set_edi_data_tbl1(ln_data_cnt).vend_rec_num
              := ln_vend_cnt           ;                                       -- 取引先内レコード通番
            lt_set_edi_data_tbl1(ln_data_cnt).inv_no                 := NULL ; -- 請求書No／請求番号
            lt_set_edi_data_tbl1(ln_data_cnt).inv_type               := NULL ; -- 請求区分
            lt_set_edi_data_tbl1(ln_data_cnt).pay_type               := NULL ; -- 支払区分
            lt_set_edi_data_tbl1(ln_data_cnt).pay_meth_type          := NULL ; -- 支払方法区分
            lt_set_edi_data_tbl1(ln_data_cnt).iss_type               := NULL ; -- 発行区分
            lt_set_edi_data_tbl1(ln_data_cnt).ship_shop_code         := NULL ; -- 店コード
            lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_name         := NULL ; -- 店舗名称（漢字）
            lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_kana_name    := NULL ; -- 店舗名称（カナ）
            -- 請求金額符号の設定
            CASE
              -- マイナスである場合
              WHEN lt_get_edi_data_tbl1(i-1).tax_gap_amount < 0 THEN
                lt_set_edi_data_tbl1(ln_data_cnt).inv_sign := 1;
              -- プラスである場合
              ELSE
                lt_set_edi_data_tbl1(ln_data_cnt).inv_sign := 0;
            END CASE;
            lt_set_edi_data_tbl1(ln_data_cnt).inv_slip_amount        
              := ABS(lt_get_edi_data_tbl1(i-1).tax_gap_amount)       ;         -- 請求金額／支払金額（絶対値）
            lt_set_edi_data_tbl1(ln_data_cnt).tax_type               
              := lt_get_edi_data_tbl1(i-1).tax_type               ;            -- 消費税区分
            lt_set_edi_data_tbl1(ln_data_cnt).tax_rate               := NULL ; -- 消費税率
-- Modify 2009.05.22 Ver1.4 Start
--            lt_set_edi_data_tbl1(ln_data_cnt).tax_amount             
--              := lt_get_edi_data_tbl1(i-1).tax_gap_amount       ;              -- 請求消費税額／支払消費税額
            lt_set_edi_data_tbl1(ln_data_cnt).tax_amount         
              := ABS(lt_get_edi_data_tbl1(i-1).tax_gap_amount)       ;         -- 請求消費税額／支払消費税額
-- Modify 2009.05.22 Ver1.4 End
            lt_set_edi_data_tbl1(ln_data_cnt).tax_gap_flg            := 1 ; -- 消費税差額フラグ
            lt_set_edi_data_tbl1(ln_data_cnt).mis_calc_type          := NULL ; -- 違算区分
            lt_set_edi_data_tbl1(ln_data_cnt).match_type             := NULL ; -- マッチ区分
            lt_set_edi_data_tbl1(ln_data_cnt).unmatch_pay_amount     := NULL ; -- アンマッチ買掛計上金額
            lt_set_edi_data_tbl1(ln_data_cnt).overlap_type           := NULL ; -- ダブリ区分
            lt_set_edi_data_tbl1(ln_data_cnt).acceptance_date        := NULL ; -- 検収日
            lt_set_edi_data_tbl1(ln_data_cnt).month_remit            
              := lt_get_edi_data_tbl1(i-1).month_remit                       ; -- 月限
            lt_set_edi_data_tbl1(ln_data_cnt).slip_num               := NULL ; -- 伝票番号
            lt_set_edi_data_tbl1(ln_data_cnt).note_line_id           := NULL ; -- 行No
            lt_set_edi_data_tbl1(ln_data_cnt).slip_type              := NULL ; -- 伝票区分
            lt_set_edi_data_tbl1(ln_data_cnt).classify_type          := NULL ; -- 分類コード
            lt_set_edi_data_tbl1(ln_data_cnt).customer_dept_code     := NULL ; -- 相手先部門コード
            lt_set_edi_data_tbl1(ln_data_cnt).customer_division_code := NULL ; -- 課コード
            lt_set_edi_data_tbl1(ln_data_cnt).sold_return_type       := NULL ; -- 売上返品区分
            lt_set_edi_data_tbl1(ln_data_cnt).nichiriu_by_way_type   := NULL ; -- ニチリウ経由区分
            lt_set_edi_data_tbl1(ln_data_cnt).sale_type              := NULL ; -- 特売区分
            lt_set_edi_data_tbl1(ln_data_cnt).direct_num             := NULL ; -- 便No
            lt_set_edi_data_tbl1(ln_data_cnt).po_date                := NULL ; -- 発注日
            lt_set_edi_data_tbl1(ln_data_cnt).delivery_date          := NULL ; -- 納品日／返品日
            lt_set_edi_data_tbl1(ln_data_cnt).item_code              := NULL ; -- 商品コード
            lt_set_edi_data_tbl1(ln_data_cnt).item_name              := NULL ; -- 商品名（漢字）
            lt_set_edi_data_tbl1(ln_data_cnt).item_kana_name         := NULL ; -- 商品名(カナ)
            lt_set_edi_data_tbl1(ln_data_cnt).quantity               := NULL ; -- 納品数量
            lt_set_edi_data_tbl1(ln_data_cnt).unit_price             := NULL ; -- 原単価
            lt_set_edi_data_tbl1(ln_data_cnt).sold_amount            := NULL ; -- 原価金額
            lt_set_edi_data_tbl1(ln_data_cnt).sold_location_code     := NULL ; -- 備考コード
            lt_set_edi_data_tbl1(ln_data_cnt).chain_st_area          := NULL ; -- チェーン店固有エリア
-- Modify 2009.10.15 Ver1.7 Start
            lt_set_edi_data_tbl1(ln_data_cnt).jan_code               := NULL ; -- JANコード
            lt_set_edi_data_tbl1(ln_data_cnt).num_of_cases           := NULL ; -- ケース入数
            lt_set_edi_data_tbl1(ln_data_cnt).medium_class           := NULL ; -- 受注ソース
-- Modify 2009.10.15 Ver1.7 End
            -- 請求額合計に税差額を加算
            ln_vend_amount := ln_vend_amount + lt_get_edi_data_tbl1(i-1).tax_gap_amount;
            -- 変数加算
            ln_data_cnt := ln_data_cnt + 1; -- 集計結果格納先レコードカウンタ
            ln_vend_cnt := ln_vend_cnt + 1; -- 取引先内レコードカウンタ
            -- 請求金額更新開始位置更新
            ln_slip_point := ln_data_cnt;
          END IF;
--
-- Modify 2009.06.15 Ver1.5 Start
          END IF;
-- Modify 2009.06.15 Ver1.5 End
          -- ブレイク変数更新
          lv_b_inv_id := lt_get_edi_data_tbl1(i).invoice_id;
        END IF;
--
        -- 前行取引先コードが現在行取引先コードでない場合、
        IF (lv_b_vend_cd <> lt_get_edi_data_tbl1(i).vender_code) THEN
-- Modify 2009.06.05 Ver1.5 Start
          -- 現在行取引先コードが最終レコード(ダミーコード)の場合、
          IF (lt_get_edi_data_tbl1(i).vender_code = cv_end_v_code) THEN
-- Modify 2009.06.05 Ver1.5 End
            -- 金額更新処理ループ
            <<vend_loop>>
            FOR k IN ln_vend_point..(ln_data_cnt - 1) LOOP
              -- 請求合計金額／支払合計金額の更新
              lt_set_edi_data_tbl1(k).inv_amount := ln_vend_amount;
              -- 値引き合計の更新
              lt_set_edi_data_tbl1(k).discount_amount := ABS(ln_disc_amount);
              -- 返品合計の更新
              lt_set_edi_data_tbl1(k).return_amount := ABS(ln_retn_amount);
              -- 伝票枚数の更新
              lt_set_edi_data_tbl1(k).inv_slip_ttl := ln_slip_num;
            END LOOP vend_loop;
--
          -- 変数の初期化
-- Modify 2009.06.05 Ver1.5 Start
--          ln_vend_cnt    := 1; -- 取引先内レコードカウンタ
-- Modify 2009.06.05 Ver1.5 End
            ln_vend_amount := 0; -- 請求金額合計
            ln_disc_amount := 0; -- 値引き合計
            ln_retn_amount := 0; -- 返品合計
            ln_slip_num    := 0; -- 伝票枚数
-- Modify 2009.06.10 Ver1.5 Start
--            -- ブレイク変数更新
--            lv_b_vend_cd := lt_get_edi_data_tbl1(i).vender_code;
-- Modify 2009.06.10 Ver1.5 End
            -- 更新開始位置更新
            ln_vend_point := ln_data_cnt;
-- Modify 2009.06.05 Ver1.5 Start
          END IF;
--
        -- ブレイク変数更新
        lv_b_vend_cd := lt_get_edi_data_tbl1(i).vender_code;
--
        -- 変数の初期化
        ln_vend_cnt  := 1; -- 取引先内レコードカウンタ
--
-- Modify 2009.06.05 Ver1.5 End
        END IF;
--
        -- 終了判定
        IF (i = ln_target_cnt + 1) THEN
          EXIT invoice_loop;
        END IF;
--
        -- 合計値加算
        ln_slip_amount := ln_slip_amount + lt_get_edi_data_tbl1(i).inv_slip_amount; -- 請求金額／支払金額
-- Modify 2009.06.05 Ver1.5 Start
        ln_slip_tax_amount := ln_slip_tax_amount + lt_get_edi_data_tbl1(i).tax_amount; -- 請求消費税額／支払消費税額
-- Modify 2009.06.05 Ver1.5 End        
        ln_vend_amount := ln_vend_amount + lt_get_edi_data_tbl1(i).inv_amount;      -- 請求合計金額／支払合計金額
        ln_disc_amount := ln_disc_amount + lt_get_edi_data_tbl1(i).discount_amount; -- 値引合計金額
        ln_retn_amount := ln_retn_amount + lt_get_edi_data_tbl1(i).return_amount;   -- 返品合計金額
--
        -- 出力用変数に設定
        lt_set_edi_data_tbl1(ln_data_cnt).file_rec_type
          := lt_get_edi_data_tbl1(i).file_rec_type          ; -- レコード区分
        lt_set_edi_data_tbl1(ln_data_cnt).chain_st_code          
          := lt_get_edi_data_tbl1(i).chain_st_code          ; -- チェーン店コード
        lt_set_edi_data_tbl1(ln_data_cnt). inv_creation_day      
          := lt_get_edi_data_tbl1(i). inv_creation_day      ;  -- データ作成日
        lt_set_edi_data_tbl1(ln_data_cnt).inv_creation_time      
          := lt_get_edi_data_tbl1(i).inv_creation_time      ; -- データ作成時刻
        lt_set_edi_data_tbl1(ln_data_cnt).vender_code            
          := lt_get_edi_data_tbl1(i).vender_code            ; -- 仕入先コード／取引先コード
        lt_set_edi_data_tbl1(ln_data_cnt).itoen_name             
          := lt_get_edi_data_tbl1(i).itoen_name             ; -- 仕入先名称／取引先名称（漢字）
        lt_set_edi_data_tbl1(ln_data_cnt).itoen_kana_name        
          := lt_get_edi_data_tbl1(i).itoen_kana_name        ; -- 仕入先名称／取引先名称（カナ）
        lt_set_edi_data_tbl1(ln_data_cnt).co_code                
          := lt_get_edi_data_tbl1(i).co_code                ; -- 社コード
        lt_set_edi_data_tbl1(ln_data_cnt).object_date_from       
          := lt_get_edi_data_tbl1(i).object_date_from       ; -- 対象期間・自
        lt_set_edi_data_tbl1(ln_data_cnt).object_date_to         
          := lt_get_edi_data_tbl1(i).object_date_to         ; -- 対象期間・至
        lt_set_edi_data_tbl1(ln_data_cnt).cutoff_date            
          := lt_get_edi_data_tbl1(i).cutoff_date            ; -- 請求締年月日
        lt_set_edi_data_tbl1(ln_data_cnt).payment_date           
          := lt_get_edi_data_tbl1(i).payment_date           ; -- 支払年月日
        lt_set_edi_data_tbl1(ln_data_cnt).due_months_forword     
          := lt_get_edi_data_tbl1(i).due_months_forword     ; -- サイト月数
        lt_set_edi_data_tbl1(ln_data_cnt).inv_slip_ttl           
          := ln_slip_num                                    ; -- 伝票枚数
        lt_set_edi_data_tbl1(ln_data_cnt).cor_slip_ttl           
          := lt_get_edi_data_tbl1(i).cor_slip_ttl           ; -- 訂正伝票枚数
        lt_set_edi_data_tbl1(ln_data_cnt).n_ins_slip_ttl         
          := lt_get_edi_data_tbl1(i).n_ins_slip_ttl         ; -- 未検収伝票枚数
        lt_set_edi_data_tbl1(ln_data_cnt).vend_rec_num           
          := ln_vend_cnt                                    ; -- 取引先内レコード通番
        lt_set_edi_data_tbl1(ln_data_cnt).inv_no                 
          := lt_get_edi_data_tbl1(i).inv_no                 ; -- 請求書No／請求番号
        lt_set_edi_data_tbl1(ln_data_cnt).inv_type               
          := lt_get_edi_data_tbl1(i).inv_type               ; -- 請求区分
        lt_set_edi_data_tbl1(ln_data_cnt).pay_type               
          := lt_get_edi_data_tbl1(i).pay_type               ; -- 支払区分
        lt_set_edi_data_tbl1(ln_data_cnt).pay_meth_type          
          := lt_get_edi_data_tbl1(i).pay_meth_type          ; -- 支払方法区分
        lt_set_edi_data_tbl1(ln_data_cnt).iss_type               
          := lt_get_edi_data_tbl1(i).iss_type               ; -- 発行区分
        lt_set_edi_data_tbl1(ln_data_cnt).ship_shop_code         
          := lt_get_edi_data_tbl1(i).ship_shop_code         ; -- 店コード
        lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_name         
          := lt_get_edi_data_tbl1(i).ship_cust_name         ; -- 店舗名称（漢字）
        lt_set_edi_data_tbl1(ln_data_cnt).ship_cust_kana_name    
          := lt_get_edi_data_tbl1(i).ship_cust_kana_name    ; -- 店舗名称（カナ）
        lt_set_edi_data_tbl1(ln_data_cnt).inv_sign               
          := lt_get_edi_data_tbl1(i).inv_sign               ; -- 請求金額符号／請求消費税額符号
        lt_set_edi_data_tbl1(ln_data_cnt).inv_slip_amount        
          := lt_get_edi_data_tbl1(i).inv_slip_amount        ; -- 請求金額／支払金額
        lt_set_edi_data_tbl1(ln_data_cnt).tax_type               
          := lt_get_edi_data_tbl1(i).tax_type               ; -- 消費税区分
        lt_set_edi_data_tbl1(ln_data_cnt).tax_rate               
          := lt_get_edi_data_tbl1(i).tax_rate               ; -- 消費税率
-- Modify 2009.05.22 Ver1.4 Start
--        lt_set_edi_data_tbl1(ln_data_cnt).tax_amount             
--          := lt_get_edi_data_tbl1(i).tax_amount             ; -- 請求消費税額／支払消費税額
        lt_set_edi_data_tbl1(ln_data_cnt).tax_amount
          := ABS(lt_get_edi_data_tbl1(i).tax_amount)        ; -- 請求消費税額／支払消費税額
-- Modify 2009.05.22 Ver1.4 End
        lt_set_edi_data_tbl1(ln_data_cnt).tax_gap_flg            
          := lt_get_edi_data_tbl1(i).tax_gap_flg            ; -- 消費税差額フラグ
        lt_set_edi_data_tbl1(ln_data_cnt).mis_calc_type          
          := lt_get_edi_data_tbl1(i).mis_calc_type          ; -- 違算区分
        lt_set_edi_data_tbl1(ln_data_cnt).match_type             
          := lt_get_edi_data_tbl1(i).match_type             ; -- マッチ区分
        lt_set_edi_data_tbl1(ln_data_cnt).unmatch_pay_amount     
          := lt_get_edi_data_tbl1(i).unmatch_pay_amount     ; -- アンマッチ買掛計上金額
        lt_set_edi_data_tbl1(ln_data_cnt).overlap_type           
          := lt_get_edi_data_tbl1(i).overlap_type           ; -- ダブリ区分
        lt_set_edi_data_tbl1(ln_data_cnt).acceptance_date        
          := lt_get_edi_data_tbl1(i).acceptance_date        ; -- 検収日
        lt_set_edi_data_tbl1(ln_data_cnt).month_remit            
          := lt_get_edi_data_tbl1(i).month_remit            ; -- 月限
        lt_set_edi_data_tbl1(ln_data_cnt).slip_num               
          := lt_get_edi_data_tbl1(i).slip_num               ; -- 伝票番号
        lt_set_edi_data_tbl1(ln_data_cnt).note_line_id           
          := lt_get_edi_data_tbl1(i).note_line_id           ; -- 行No
        lt_set_edi_data_tbl1(ln_data_cnt).slip_type              
          := lt_get_edi_data_tbl1(i).slip_type              ; -- 伝票区分
        lt_set_edi_data_tbl1(ln_data_cnt).classify_type          
          := lt_get_edi_data_tbl1(i).classify_type          ; -- 分類コード
        lt_set_edi_data_tbl1(ln_data_cnt).customer_dept_code     
          := lt_get_edi_data_tbl1(i).customer_dept_code     ; -- 相手先部門コード
        lt_set_edi_data_tbl1(ln_data_cnt).customer_division_code 
          := lt_get_edi_data_tbl1(i).customer_division_code ; -- 課コード
        lt_set_edi_data_tbl1(ln_data_cnt).sold_return_type       
          := lt_get_edi_data_tbl1(i).sold_return_type       ; -- 売上返品区分
        lt_set_edi_data_tbl1(ln_data_cnt).nichiriu_by_way_type   
          := lt_get_edi_data_tbl1(i).nichiriu_by_way_type   ; -- ニチリウ経由区分
        lt_set_edi_data_tbl1(ln_data_cnt).sale_type              
          := lt_get_edi_data_tbl1(i).sale_type              ; -- 特売区分
        lt_set_edi_data_tbl1(ln_data_cnt).direct_num             
          := lt_get_edi_data_tbl1(i).direct_num             ; -- 便No
        lt_set_edi_data_tbl1(ln_data_cnt).po_date                
          := lt_get_edi_data_tbl1(i).po_date                ; -- 発注日
        lt_set_edi_data_tbl1(ln_data_cnt).delivery_date          
          := lt_get_edi_data_tbl1(i).delivery_date          ; -- 納品日／返品日
        lt_set_edi_data_tbl1(ln_data_cnt).item_code              
          := lt_get_edi_data_tbl1(i).item_code              ; -- 商品コード
        lt_set_edi_data_tbl1(ln_data_cnt).item_name              
          := lt_get_edi_data_tbl1(i).item_name              ; -- 商品名（漢字）
        lt_set_edi_data_tbl1(ln_data_cnt).item_kana_name         
          := lt_get_edi_data_tbl1(i).item_kana_name         ; -- 商品名(カナ)
        lt_set_edi_data_tbl1(ln_data_cnt).quantity               
          := lt_get_edi_data_tbl1(i).quantity               ; -- 納品数量
        lt_set_edi_data_tbl1(ln_data_cnt).unit_price             
          := lt_get_edi_data_tbl1(i).unit_price             ; -- 原単価
        lt_set_edi_data_tbl1(ln_data_cnt).sold_amount            
          := lt_get_edi_data_tbl1(i).sold_amount            ; -- 原価金額
        lt_set_edi_data_tbl1(ln_data_cnt).sold_location_code     
          := lt_get_edi_data_tbl1(i).sold_location_code     ; -- 備考コード
        lt_set_edi_data_tbl1(ln_data_cnt).chain_st_area          
          := lt_get_edi_data_tbl1(i).chain_st_area          ; -- チェーン店固有エリア
-- Modify 2009.10.15 Ver1.7 Start
        lt_set_edi_data_tbl1(ln_data_cnt).jan_code               
          := lt_get_edi_data_tbl1(i).jan_code               ; -- JANコード
        lt_set_edi_data_tbl1(ln_data_cnt).num_of_cases           
          := lt_get_edi_data_tbl1(i).num_of_cases           ; -- ケース入数
        lt_set_edi_data_tbl1(ln_data_cnt).medium_class           
          := lt_get_edi_data_tbl1(i).medium_class           ; -- 受注ソース
-- Modify 2009.10.15 Ver1.7 End
--
        -- 変数加算
        ln_data_cnt := ln_data_cnt + 1; -- 集計結果格納先レコードカウンタ
        ln_vend_cnt := ln_vend_cnt + 1; -- 取引先内レコードカウンタ
--
      END LOOP invoice_loop;
--
    -- ====================================================
    -- ヘッダ出力処理(A-6)
    -- ====================================================
      -- EDIヘッダ取得処理
      xxccp_ifcommon_pkg.add_edi_header_footer( iv_add_area       => cv_add_area_h            -- 付与区分
                                               ,iv_from_series    => gv_edi_operation_code    -- ＩＦ元業務系列コード
                                               ,iv_base_code      => gv_edi_output_dept       -- 拠点コード
                                               ,iv_base_name      => gv_edi_output_dept_name  -- 拠点名称
                                               ,iv_chain_code     => gv_edi_chain_code        -- チェーン店コード
                                               ,iv_chain_name     => gv_edi_chain_name        -- チェーン店名称
                                               ,iv_data_kind      => gv_edi_data_code         -- データ種コード
                                               ,iv_row_number     => cv_row_number            -- 並列処理番号
                                               ,in_num_of_records => NULL                     -- レコード件数
                                               ,ov_retcode        => lv_retcode
                                               ,ov_output         => lv_output
                                               ,ov_errbuf         => lv_errbuf
                                               ,ov_errmsg         => lv_errmsg);
      IF (lv_retcode = cv_status_error) THEN
        -- ローカル定義例外発生。
        RAISE edi_func_h_expt;
      END IF;
--
    -- ====================================================
    -- EDI出力ファイルOPEN処理(A-5)
    -- ====================================================
      lf_file_hand := UTL_FILE.FOPEN
                        ( gv_edi_data_filepath
                         ,gv_edi_data_filename
                         ,cv_open_mode_w
                        ) ;
--
      -- ヘッダレコードの書き込み
      UTL_FILE.PUT_LINE( lf_file_hand, lv_output ) ;
--
      -- ====================================================
      -- 取得データ出力処理(A-7)
      -- ====================================================
--
        ln_rec_cnt := 0;
        <<out_loop>>
        FOR ln_loop_cnt IN lt_set_edi_data_tbl1.FIRST..lt_set_edi_data_tbl1.LAST LOOP
--
          -- 桁数チェック
          -- レコード区分
          set_edi_char(1                                                -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).file_rec_type  -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
          lt_set_edi_data_tbl1(ln_loop_cnt).file_rec_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- チェーン店コード
          set_edi_char(3                                                -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
          lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 仕入先コード／取引先コード
          set_edi_char(6                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).vender_code    -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
          lt_set_edi_data_tbl1(ln_loop_cnt).vender_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 取引先名称（漢字）
          set_edi_char(7                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).itoen_name    -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).itoen_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 取引先名称（カナ）
          set_edi_char(8                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).itoen_kana_name      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).itoen_kana_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 社コード
          set_edi_char(9                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).co_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).co_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
--
          -- サイト月数
          set_edi_char(14                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).due_months_forword      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).due_months_forword := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 伝票枚数
          set_edi_char(15                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_ttl      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_ttl := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 訂正伝票枚数
          set_edi_char(16                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).cor_slip_ttl      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).cor_slip_ttl := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 未検収伝票枚数
          set_edi_char(17                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).n_ins_slip_ttl      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).n_ins_slip_ttl := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 取引先内レコード通番
          set_edi_char(18                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).vend_rec_num      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).vend_rec_num := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 請求書No／請求番号
          set_edi_char(19                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_no      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_no := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 請求区分
          set_edi_char(20                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 支払区分
          set_edi_char(21                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).pay_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).pay_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 支払方法区分
          set_edi_char(22                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).pay_meth_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).pay_meth_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 発行区分
          set_edi_char(23                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).iss_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).iss_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 店コード
          set_edi_char(24                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).ship_shop_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).ship_shop_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 店舗名称（漢字）
          set_edi_char(25                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_name      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 店舗名称（カナ）
          set_edi_char(26                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_kana_name      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_kana_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 請求金額符号
          set_edi_char(27                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_sign      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_sign := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 請求金額／支払金額
          set_edi_char(28                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_amount      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
         -- 消費税区分
          set_edi_char(29                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 消費税率
          set_edi_char(30                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_rate      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_rate := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 請求消費税額
          set_edi_char(31                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_amount      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 消費税差額フラグ
          set_edi_char(32                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).tax_gap_flg      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).tax_gap_flg := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 違算区分
          set_edi_char(33                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).mis_calc_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).mis_calc_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- マッチ区分
          set_edi_char(34                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).match_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).match_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- アンマッチ買掛計上金額
          set_edi_char(35                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).unmatch_pay_amount      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).unmatch_pay_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ダブリ区分
          set_edi_char(36                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).overlap_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).overlap_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 月限
          set_edi_char(38                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).month_remit      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).month_remit := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 伝票番号
          set_edi_char(39                                               -- 項目順
                      ,CASE
                         WHEN lt_set_edi_data_tbl1(ln_loop_cnt).slip_num = cv_nul_slip_num THEN
                           NULL
                         ELSE
                           lt_set_edi_data_tbl1(ln_loop_cnt).slip_num
                         END                                            -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).slip_num := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 行No
          set_edi_char(40                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 伝票区分
          set_edi_char(41                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).slip_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 分類コード
          set_edi_char(42                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).classify_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).classify_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 相手先部門コード
          set_edi_char(43                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).customer_dept_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).customer_dept_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 課コード
          set_edi_char(44                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).customer_division_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).customer_division_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 売上返品区分
          set_edi_char(45                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).sold_return_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sold_return_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ニチリウ経由区分
          set_edi_char(46                                              -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).nichiriu_by_way_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).nichiriu_by_way_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 特売区分
          set_edi_char(47                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).sale_type      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sale_type := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 便No
          set_edi_char(48                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).direct_num      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).direct_num := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 商品コード
          set_edi_char(51                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).item_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).item_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 商品名（漢字）
          set_edi_char(52                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).item_name      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).item_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 商品名(カナ)
          set_edi_char(53                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).item_kana_name      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).item_kana_name := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 納品数量
          set_edi_char(54                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).quantity      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).quantity := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 原単価
          set_edi_char(55                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).unit_price      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).unit_price := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 原価金額
          set_edi_char(56                                               -- 項目順
                      ,TO_CHAR(lt_set_edi_data_tbl1(ln_loop_cnt).sold_amount)      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sold_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 備考コード
          set_edi_char(57                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).sold_location_code      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).sold_location_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- チェーン店固有エリア
          set_edi_char(58                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_area      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_area := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 請求合計金額／支払合計金額
          set_edi_char(59                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).inv_amount      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).inv_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 値引合計金額
          set_edi_char(60                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).discount_amount      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).discount_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 返品合計金額
          set_edi_char(61                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).return_amount      -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).return_amount := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
-- Modify 2009.10.15 Ver1.7 Start
          -- JANコード
          set_edi_char(62                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).jan_code       -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).jan_code := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- ケース入数
          set_edi_char(63                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).num_of_cases   -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).num_of_cases := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
          -- 受注ソース
          set_edi_char(64                                               -- 項目順
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).medium_class   -- 変換対象文字列
                      ,ln_loop_cnt                                      -- レコード通番
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).slip_num       -- 伝票番号
                      ,lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id   -- 伝票行No
                      ,lv_output_str                                    -- 戻り値
                      ,lv_overflow_msg
                      ,lv_retcode
                      ,lv_errmsg);
           lt_set_edi_data_tbl1(ln_loop_cnt).medium_class := lv_output_str;
          IF lv_retcode = cv_status_warn THEN
            ov_retcode := cv_status_warn;
          END IF;
-- Modify 2009.10.15 Ver1.7 End
--
          -- 出力文字列作成
          lv_edi_text := pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).file_rec_type
                                     ,gt_edi_item_tab(1).data_type
                                     ,gt_edi_item_tab(1).edi_length)                                                       -- レコード区分
                      || pad_edi_char(ln_loop_cnt
                                     ,gt_edi_item_tab(2).data_type
                                     ,gt_edi_item_tab(2).edi_length)                                                       -- レコード通番
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_code
                                     ,gt_edi_item_tab(3).data_type
                                     ,gt_edi_item_tab(3).edi_length)                                                       -- チェーン店コード
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt). inv_creation_day
                                     ,cv_trn_format_d)                                         -- データ作成日
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).inv_creation_time
                                     ,cv_trn_format_t)                                         -- データ作成時刻
                      || pad_edi_char(CASE
                                        WHEN lt_set_edi_data_tbl1(ln_loop_cnt).vender_code = cv_nul_v_code THEN
                                          NULL
                                        ELSE
                                          lt_set_edi_data_tbl1(ln_loop_cnt).vender_code
                                        END
                                     ,gt_edi_item_tab(6).data_type
                                     ,gt_edi_item_tab(6).edi_length)                           -- 取引先コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).itoen_name
                                     ,gt_edi_item_tab(7).data_type
                                     ,gt_edi_item_tab(7).edi_length)                           -- 取引先名称（漢字）
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).itoen_kana_name
                                     ,gt_edi_item_tab(8).data_type
                                     ,gt_edi_item_tab(8).edi_length)                           -- 取引先名称（カナ）
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).co_code
                                     ,gt_edi_item_tab(9).data_type
                                     ,gt_edi_item_tab(9).edi_length)                           -- 社コード
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).object_date_from
                                     ,cv_trn_format_d)                                         -- 対象期間・自
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).object_date_to
                                     ,cv_trn_format_d)                                         -- 対象期間・至
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).cutoff_date
                                     ,cv_trn_format_d)                                         -- 請求締年月日
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).payment_date
                                     ,cv_trn_format_d)                                         -- 支払年月日
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).due_months_forword
                                     ,gt_edi_item_tab(14).data_type
                                     ,gt_edi_item_tab(14).edi_length)                              -- サイト月数
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_ttl
                                     ,gt_edi_item_tab(15).data_type
                                     ,gt_edi_item_tab(15).edi_length)                              -- 伝票枚数
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).cor_slip_ttl
                                     ,gt_edi_item_tab(16).data_type
                                     ,gt_edi_item_tab(16).edi_length)                              -- 訂正伝票枚数
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).n_ins_slip_ttl
                                     ,gt_edi_item_tab(17).data_type
                                     ,gt_edi_item_tab(17).edi_length)                              -- 未検収伝票枚数
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).vend_rec_num
                                     ,gt_edi_item_tab(18).data_type
                                     ,gt_edi_item_tab(18).edi_length)                              -- 取引先内レコード通番
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_no
                                     ,gt_edi_item_tab(19).data_type
                                     ,gt_edi_item_tab(19).edi_length)                             -- 請求書No／請求番号
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_type
                                     ,gt_edi_item_tab(20).data_type
                                     ,gt_edi_item_tab(20).edi_length)                              -- 請求区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).pay_type
                                     ,gt_edi_item_tab(21).data_type
                                     ,gt_edi_item_tab(21).edi_length)                              -- 支払区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).pay_meth_type
                                     ,gt_edi_item_tab(22).data_type
                                     ,gt_edi_item_tab(22).edi_length)                              -- 支払方法区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).iss_type
                                     ,gt_edi_item_tab(23).data_type
                                     ,gt_edi_item_tab(23).edi_length)                              -- 発行区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).ship_shop_code
                                     ,gt_edi_item_tab(24).data_type
                                     ,gt_edi_item_tab(24).edi_length)                             -- 店コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_name
                                     ,gt_edi_item_tab(25).data_type
                                     ,gt_edi_item_tab(25).edi_length)                            -- 店舗名称（漢字）
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).ship_cust_kana_name
                                     ,gt_edi_item_tab(26).data_type
                                     ,gt_edi_item_tab(26).edi_length)                             -- 店舗名称（カナ）
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_sign
                                     ,gt_edi_item_tab(27).data_type
                                     ,gt_edi_item_tab(27).edi_length)                              -- 請求金額符号
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_slip_amount
                                     ,gt_edi_item_tab(28).data_type
                                     ,gt_edi_item_tab(28).edi_length)                             -- 請求金額／支払金額
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_type
                                     ,gt_edi_item_tab(29).data_type
                                     ,gt_edi_item_tab(29).edi_length)                              -- 消費税区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_rate
                                     ,gt_edi_item_tab(30).data_type
                                     ,gt_edi_item_tab(30).edi_length)                              -- 消費税率
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_amount
                                     ,gt_edi_item_tab(31).data_type
                                     ,gt_edi_item_tab(31).edi_length)                             -- 請求消費税額
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).tax_gap_flg
                                     ,gt_edi_item_tab(32).data_type
                                     ,gt_edi_item_tab(32).edi_length)                              -- 消費税差額フラグ
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).mis_calc_type
                                     ,gt_edi_item_tab(33).data_type
                                     ,gt_edi_item_tab(33).edi_length)                              -- 違算区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).match_type
                                     ,gt_edi_item_tab(34).data_type
                                     ,gt_edi_item_tab(34).edi_length)                              -- マッチ区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).unmatch_pay_amount
                                     ,gt_edi_item_tab(35).data_type
                                     ,gt_edi_item_tab(35).edi_length)                             -- アンマッチ買掛計上金額
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).overlap_type
                                     ,gt_edi_item_tab(36).data_type
                                     ,gt_edi_item_tab(36).edi_length)                              -- ダブリ区分
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).acceptance_date
                                     ,cv_trn_format_d)                                         -- 検収日
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).month_remit
                                     ,gt_edi_item_tab(38).data_type
                                     ,gt_edi_item_tab(38).edi_length)                                                       -- 月限
                      || pad_edi_char(CASE
                                        WHEN lt_set_edi_data_tbl1(ln_loop_cnt).slip_num = cv_nul_slip_num THEN
                                          NULL
-- Modify 2009.06.23 Ver1.6 Start
                                        WHEN SUBSTRB(lt_set_edi_data_tbl1(ln_loop_cnt).slip_num, 1, 1) = cv_slip_no_chk_i THEN
                                          SUBSTRB(lt_set_edi_data_tbl1(ln_loop_cnt).slip_num, 2)
-- Modify 2009.06.23 Ver1.6 End
                                        ELSE
                                          lt_set_edi_data_tbl1(ln_loop_cnt).slip_num
                                        END
                                     ,gt_edi_item_tab(39).data_type
                                     ,gt_edi_item_tab(39).edi_length)                                                      -- 伝票番号
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).note_line_id
                                     ,gt_edi_item_tab(40).data_type
                                     ,gt_edi_item_tab(40).edi_length)                                                       -- 行No
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).slip_type
                                     ,gt_edi_item_tab(41).data_type
                                     ,gt_edi_item_tab(41).edi_length)                                                       -- 伝票区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).classify_type
                                     ,gt_edi_item_tab(42).data_type
                                     ,gt_edi_item_tab(42).edi_length)                                                       -- 分類コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).customer_dept_code
                                     ,gt_edi_item_tab(43).data_type
                                     ,gt_edi_item_tab(43).edi_length)                                                       -- 相手先部門コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).customer_division_code
                                     ,gt_edi_item_tab(44).data_type
                                     ,gt_edi_item_tab(44).edi_length)                                                       -- 課コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sold_return_type
                                     ,gt_edi_item_tab(45).data_type
                                     ,gt_edi_item_tab(45).edi_length)                                                       -- 売上返品区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).nichiriu_by_way_type
                                     ,gt_edi_item_tab(46).data_type
                                     ,gt_edi_item_tab(46).edi_length)                                                       -- ニチリウ経由区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sale_type
                                     ,gt_edi_item_tab(47).data_type
                                     ,gt_edi_item_tab(47).edi_length)                                                       -- 特売区分
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).direct_num
                                     ,gt_edi_item_tab(48).data_type
                                     ,gt_edi_item_tab(48).edi_length)                                                       -- 便No
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).po_date
                                     ,cv_trn_format_d)                                         -- 発注日
                      || NVL(lt_set_edi_data_tbl1(ln_loop_cnt).delivery_date
                                     ,cv_trn_format_d)                                         -- 納品日／返品日
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).item_code
                                     ,gt_edi_item_tab(51).data_type
                                     ,gt_edi_item_tab(51).edi_length)                                                       -- 商品コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).item_name
                                     ,gt_edi_item_tab(52).data_type
                                     ,gt_edi_item_tab(52).edi_length)                                                      -- 商品名（漢字）
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).item_kana_name
                                     ,gt_edi_item_tab(53).data_type
                                     ,gt_edi_item_tab(53).edi_length)                                                      -- 商品名(カナ)
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).quantity
                                     ,gt_edi_item_tab(54).data_type
                                     ,gt_edi_item_tab(54).edi_length)                                                      -- 納品数量
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).unit_price
                                     ,gt_edi_item_tab(55).data_type
                                     ,gt_edi_item_tab(55).edi_length)                                                      -- 原単価
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sold_amount
                                     ,gt_edi_item_tab(56).data_type
                                     ,gt_edi_item_tab(56).edi_length)                                                      -- 原価金額
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).sold_location_code
                                     ,gt_edi_item_tab(57).data_type
                                     ,gt_edi_item_tab(57).edi_length)                                                       -- 備考コード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).chain_st_area
                                     ,gt_edi_item_tab(58).data_type
                                     ,gt_edi_item_tab(58).edi_length)                                                     -- チェーン店固有エリア
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).inv_amount
                                     ,gt_edi_item_tab(59).data_type
                                     ,gt_edi_item_tab(59).edi_length)                                                      -- 請求合計金額／支払合計金額
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).discount_amount
                                     ,gt_edi_item_tab(60).data_type
                                     ,gt_edi_item_tab(60).edi_length)                                                      -- 値引合計金額
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).return_amount
                                     ,gt_edi_item_tab(61).data_type
                                     ,gt_edi_item_tab(61).edi_length)                                                      -- 返品合計金額
-- Modify 2009.10.15 Ver1.7 Start
-- Modify 2009.05.08 Ver1.3 Start
--                      || pad_edi_char(null
--                                     ,gt_edi_item_tab(62).data_type
--                                     ,gt_edi_item_tab(62).edi_length)                                                      -- 予備エリア
-- Modify 2009.05.08 Ver1.3 End
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).jan_code
                                     ,gt_edi_item_tab(62).data_type
                                     ,gt_edi_item_tab(62).edi_length)                                                      -- JANコード
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).num_of_cases
                                     ,gt_edi_item_tab(63).data_type
                                     ,gt_edi_item_tab(63).edi_length)                                                      -- ケース入数
                      || pad_edi_char(lt_set_edi_data_tbl1(ln_loop_cnt).medium_class
                                     ,gt_edi_item_tab(64).data_type
                                     ,gt_edi_item_tab(64).edi_length)                                                      -- 受注ソース
                      || pad_edi_char(null
                                     ,gt_edi_item_tab(65).data_type
                                     ,gt_edi_item_tab(65).edi_length)                                                      -- 予備エリア
-- Modify 2009.10.15 Ver1.7 End
                      ;
--
          -- ====================================================
          -- ファイル書き込み
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_file_hand, lv_edi_text ) ;
--
          -- ====================================================
          -- 処理件数カウントアップ
          -- ====================================================
          ln_rec_cnt := ln_rec_cnt + 1;
--
        END LOOP out_loop;
--
      -- ====================================================
      -- トレイラ出力処理(A-8)
      -- ====================================================
      -- EDIフッタ取得処理
      xxccp_ifcommon_pkg.add_edi_header_footer( iv_add_area       => cv_add_area_f -- 付与区分
                                               ,iv_from_series    => NULL          -- ＩＦ元業務系列コード
                                               ,iv_base_code      => NULL          -- 拠点コード
                                               ,iv_base_name      => NULL          -- 拠点名称
                                               ,iv_chain_code     => NULL          -- チェーン店コード
                                               ,iv_chain_name     => NULL          -- チェーン店名称
-- Modify 2009.05.08 Ver1.3 Start
--                                               ,iv_data_kind      => NULL          -- データ種コード
                                               ,iv_data_kind      => gv_edi_data_code  -- データ種コード
-- Modify 2009.05.08 Ver1.3 End
                                               ,iv_row_number     => NULL          -- 並列処理番号
                                               ,in_num_of_records => ln_rec_cnt    -- レコード件数
                                               ,ov_retcode        => lv_retcode    -- リターンコード
                                               ,ov_output         => lv_output     -- 出力値
                                               ,ov_errbuf         => lv_errbuf     -- エラーメッセージ
                                               ,ov_errmsg         => lv_errmsg);   -- ユーザー・エラーメッセージ
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a04_003 -- 共通関数エラー
                                                      ,cv_tkn_func       -- トークン'FUNC_NAME'
                                                      ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                         ,cv_dict_f_func))
                                                      -- EDIフッタ付与関数
                            ,1
                            ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- フッタレコードの書き込み
      UTL_FILE.PUT_LINE( lf_file_hand, lv_output ) ;
--
      -- ====================================================
      -- ＵＴＬファイルクローズ
      -- ====================================================
      UTL_FILE.FCLOSE( lf_file_hand ) ;
-- 
      -- メッセージ出力
        lv_output_file_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr         -- 'XXCFR'
                                                               ,cv_msg_003a04_019      -- EDIファイル出力
                                                               ,cv_tkn_code            -- トークン'CODE'
                                                               ,iv_ar_code1            -- 売掛コード１（請求書）
                                                               ,cv_tkn_name            -- トークン'NAME'
                                                               ,gv_ar_code_name )      -- 売掛コード１（請求書）名称
                            ,1
                            ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_file_msg
        ); 
        lv_output_file_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr         -- 'XXCFR'
                                                               ,cv_msg_003a04_011      -- 出力ファイル名
                                                               ,cv_tkn_file            -- トークン'FILE_NAME'
                                                               ,gv_edi_data_filename ) -- ファイル名
                            ,1
                            ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_file_msg
        );
        lv_output_rec_num_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                                  ,cv_msg_003a04_020   -- EDI出力レコード数
                                                                  ,cv_tkn_rec          -- トークン'REC_COUNT'
                                                                  ,ln_rec_cnt         )-- ファイル内レコード数
                            ,1
                            ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_output_rec_num_msg
        );
        -- 空白行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      -- ファイル出力件数のカウント
      gn_output_cnt := gn_output_cnt + 1;
--
    END IF;
--
-- Modify 2009.06.23 Ver1.6 Start
    -- 伝票番号チェックエラーが存在した場合
    IF (lv_chk_err_flg != cv_flag_no) THEN
      -- ファイル出力なしメッセージを出力
      lv_slip_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                    cv_msg_kbn_cfr         -- 'XXCFR'
                                   ,cv_msg_003a04_026      -- ファイル出力なしメッセージ
                                   ,cv_tkn_code            -- トークン'CODE'
                                   ,iv_ar_code1            -- 売掛コード１（請求書）
                                   ,cv_tkn_name            -- トークン'NAME'
                                   ,gv_ar_code_name )      -- 売掛コード１（請求書）名称)
                                 ,1
                                 ,5000);
      FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_slip_warn_msg
      );
--
      -- 戻り値に警告のステータスをセット
      ov_retcode := cv_status_warn;
--
    END IF;
-- Modify 2009.06.23 Ver1.6 End
  EXCEPTION
    -- *** EDIヘッダ付与関数エラー ***
    WHEN edi_func_h_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_003 -- 共通関数エラー
                                                    ,cv_tkn_func       -- トークン'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_h_func))
                                                    -- EDIヘッダ付与関数
                           ||cv_msg_part||lv_errmsg -- EDIヘッダ付与関数にて発行されたエラーメッセージ
                          ,1
                          ,5000);
      lv_errbuf  := lv_errmsg;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 空白行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_output||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** ファイルの場所が無効です ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                    ,cv_msg_003a04_014 ) -- ファイルの場所が無効
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                    ,cv_msg_003a04_015 ) -- ファイルをオープンできない
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 書込み操作中にオペレーティング・システムのエラーが発生しました ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
--      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a04_016 -- ファイルに書込みできない                                                 
                                                   )
                                                   ,1
                                                   ,5000);      
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_edi_date;
--
  /**********************************************************************************
   * Procedure Name   : get_edi_arcode
   * Description      : EDI請求対象取得ループ処理 (A-3)
   ***********************************************************************************/
  PROCEDURE get_edi_arcode(
    iv_target_date IN  VARCHAR2,     -- 締日
    iv_ar_code1    IN  VARCHAR2,     -- 売掛コード１(請求書)
    iv_start_mode  IN  VARCHAR2,     -- 起動区分
    ov_errbuf      OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_arcode'; -- プログラム名
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
    ln_ar1_cnt          NUMBER;                 -- 売掛コード１（請求書）件数
    lv_ar_warn_msg      VARCHAR2(5000) := NULL; -- 売掛コード１（請求書）警告メッセージ
-- Modify 2009.05.07 Ver1.3 Start
    ln_cust_cnt         NUMBER;                 -- エラー売掛コード1（請求書）設定顧客情報件数
    iv_arcode1          VARCHAR2(5000);         -- 売掛コード１（請求書）inパラメータ
-- Modify 2009.05.07 Ver1.3 End    
    lv_msg              VARCHAR2(5000) := NULL; -- 対象件数メッセージ
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
    -- 売掛コード１（請求書）抽出
    CURSOR get_edi_arcode1_cur
    IS
      SELECT flvv.lookup_code ar_code1              -- 売掛コード１（請求書）
            ,flvv.meaning     ar_code1_name         -- 売掛コード１（請求書）名称
            ,flvv.attribute1  chain_code            -- チェーン店コード
            ,flvv.attribute2  chain_name            -- チェーン店名称
            ,flvv.attribute3  edi_file_name         -- ファイル名
      FROM fnd_lookup_values_vl flvv                -- クイックコード(売掛コード1(請求書))
      WHERE flvv.lookup_type = cv_invoice_grp_code
        AND ((gv_start_mode_flg = cv_start_mode_b
              AND EXISTS (SELECT 'x'
                          FROM xxcfr_inv_info_transfer xiit  -- 請求情報引渡テーブル
                              ,xxcfr_invoice_headers   xih
                              ,xxcfr_invoice_lines     xil
                              ,xxcfr_bill_customers_v  xbcv
                          WHERE flvv.lookup_code = xbcv.receiv_code1
                            AND xbcv.inv_prt_type = cv_inv_prt_type
                            AND xih.invoice_id = xil.invoice_id      -- 一括請求書	ID
                            AND xbcv.bill_customer_code = xih.bill_cust_code
                            AND xih.request_id = xiit.request_id
                            AND xiit.set_of_books_id = gn_set_of_bks_id
                            AND xiit.org_id = gn_org_id
                            )) OR
             (gv_start_mode_flg = cv_start_mode_h))
        AND flvv.lookup_code = NVL(iv_ar_code1,flvv.lookup_code)
        AND flvv.enabled_flag = cv_flag_yes
        AND gd_process_date BETWEEN NVL(flvv.start_date_active ,cd_min_date) AND
                                    NVL(flvv.end_date_active ,cd_max_date)
      ORDER BY flvv.lookup_code;
--
-- Modify 2009.05.07 Ver1.3 Start
    -- エラー売掛コード1(請求書)設定顧客取得カーソル
    CURSOR get_edi_cust_cur(iv_arcode1 IN VARCHAR2)
    IS
      SELECT xbcv.bill_customer_code  cust_code     -- 請求先顧客コード
            ,xbcv.bill_customer_name  cust_name     -- 請求先顧客名
      FROM   xxcfr_invoice_headers   xih            -- 請求ヘッダ情報
            ,xxcfr_bill_customers_v  xbcv           -- 請求先顧客ビュー
      WHERE  xbcv.receiv_code1 = iv_arcode1        -- 売掛コード1(請求書)
      AND    xbcv.inv_prt_type = cv_inv_prt_type              -- 請求書出力形式(3:EDI請求)
      AND    xbcv.bill_customer_code = xih.bill_cust_code 
      AND  ((gv_start_mode_flg = cv_start_mode_b     AND  -- 夜間バッチ起動時
             EXISTS (SELECT *
                     FROM   xxcfr_inv_info_transfer xiit  -- 請求情報引渡テーブル
                     WHERE  xiit.target_request_id = xih.request_id
                     AND    xiit.set_of_books_id = gn_set_of_bks_id
                     AND    xiit.org_id = gn_org_id
                    ))
           OR
            (gv_start_mode_flg = cv_start_mode_h  AND  -- 手動起動時
             xih.cutoff_date = gd_target_date))        -- 締日
      ORDER BY xbcv.bill_customer_code;
--
-- Modify 2009.05.07 Ver1.3 End
    -- *** ローカル・レコード ***
    TYPE g_edi_arcode1_ttype IS TABLE OF get_edi_arcode1_cur%ROWTYPE INDEX BY PLS_INTEGER;
-- Modify 2009.05.07 Ver1.3 Start
    TYPE g_edi_cust_ttype IS TABLE OF get_edi_cust_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_edi_cust              g_edi_cust_ttype;
-- Modify 2009.05.07 Ver1.3 End
    lt_arcode1_data          g_edi_arcode1_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN get_edi_arcode1_cur;
--
    -- データの一括取得
    FETCH get_edi_arcode1_cur BULK COLLECT INTO lt_arcode1_data;
--
    -- 処理件数のセット
    ln_ar1_cnt := lt_arcode1_data.COUNT;
    gn_target_cnt := ln_ar1_cnt;
--
    -- カーソルクローズ
    CLOSE get_edi_arcode1_cur;
--
    -- EDI項目情報を参照タイプより取得
    OPEN get_edi_item_cur;
    -- コレクション変数に代入
    FETCH get_edi_item_cur BULK COLLECT INTO gt_edi_item_tab;
    -- カーソルクローズ
    CLOSE get_edi_item_cur;
--
    -- ループ処理
    <<arcode1_loop>>
    FOR i IN 1..ln_ar1_cnt LOOP
--
      -- 必須チェック：チェーン店
      IF (lt_arcode1_data(i).chain_code IS NULL) THEN
        lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                      ,cv_msg_003a04_018      -- EDI設定エラーメッセージ
                                                      ,cv_tkn_code            -- トークン'CODE'
                                                      ,lt_arcode1_data(i).ar_code1
                                                      ,cv_tkn_name            -- トークン'NAME'
                                                      ,lt_arcode1_data(i).ar_code1_name
                                                      ,cv_tkn_item       -- トークン'ITEM'
                                                      ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                          ,cv_dict_chain_code ))
                                                                                        -- チェーン店コード
                                 ,1
                                 ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- 終了ステータスを警告に更新
        ov_retcode := cv_status_warn;
      END IF;
--
      -- 必須チェック：チェーン店名称
      IF (lt_arcode1_data(i).chain_name IS NULL) THEN
        lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr -- 'XXCFR'
                                                      ,cv_msg_003a04_018   -- EDI設定エラーメッセージ
                                                      ,cv_tkn_code         -- トークン'CODE'
                                                      ,lt_arcode1_data(i).ar_code1
                                                      ,cv_tkn_name         -- トークン'NAME'
                                                      ,lt_arcode1_data(i).ar_code1_name
                                                      ,cv_tkn_item       -- トークン'ITEM'
                                                      ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                          ,cv_dict_chain_name ))
                                                                                        -- チェーン店名称
                                 ,1
                                 ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- 終了ステータスを警告に更新
        ov_retcode := cv_status_warn;
      END IF;
--
      -- 必須チェック：ファイル名
      IF (lt_arcode1_data(i).edi_file_name IS NULL) THEN
        lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr -- 'XXCFR'
                                                      ,cv_msg_003a04_018   -- EDI設定エラーメッセージ
                                                      ,cv_tkn_code         -- トークン'CODE'
                                                      ,lt_arcode1_data(i).ar_code1
                                                      ,cv_tkn_name         -- トークン'NAME'
                                                      ,lt_arcode1_data(i).ar_code1_name
                                                      ,cv_tkn_item       -- トークン'ITEM'
                                                      ,xxcfr_common_pkg.lookup_dictionary( cv_msg_kbn_cfr  -- 'XXCFR'
                                                                                          ,cv_dict_file_name ))
                                                                                          -- ファイル名
                                  ,1
                                  ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- 終了ステータスを警告に更新
        ov_retcode := cv_status_warn;
      END IF;
--
-- Modify 2009.05.25 Ver1.4 Start
      IF (lv_ar_warn_msg IS NOT NULL) THEN
        -- エラー売掛コード1(請求書)設定顧客ヘッダメッセージ
         lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a04_023      -- エラー売掛コード1(請求書)設定顧客ヘッダメッセージ
                                                        ,cv_tkn_code            -- トークン'CODE'
                                                        ,lt_arcode1_data(i).ar_code1)                                                   
                                 ,1
                                 ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- カーソルオープン
        iv_arcode1 := lt_arcode1_data(i).ar_code1;
        OPEN get_edi_cust_cur(iv_arcode1);
--
        -- データの一括取得
        FETCH get_edi_cust_cur BULK COLLECT INTO lt_edi_cust;
--
        -- 処理件数のセット
        ln_cust_cnt := lt_edi_cust.COUNT;
--
        -- カーソルクローズ
        CLOSE get_edi_cust_cur;
--
        -- ループ処理
        <<cust_cur>>
        FOR i IN 1..ln_cust_cnt LOOP
-- 
        -- エラー売掛コード1(請求書)設定顧客明細メッセージ
          lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a04_024      -- エラー売掛コード1(請求書)設定顧客明細メッセージ
                                                        ,cv_tkn_code            -- トークン'CODE'
                                                        ,lt_edi_cust(i).cust_code
                                                        ,cv_tkn_name            -- トークン'NAME'
                                                        ,lt_edi_cust(i).cust_name)
                                 ,1
                                 ,5000);
          FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        END LOOP cust_cur;
      END IF;
-- Modify 2009.05.25 Ver1.4 End
      -- 警告メッセージに値がセットされていない場合
      IF (lv_ar_warn_msg IS NULL) THEN
        -- ファイル重複チェック
        UTL_FILE.FGETATTR(gv_edi_data_filepath,
                          lt_arcode1_data(i).edi_file_name,
                          lb_fexists,
                          ln_file_size,
                          ln_block_size);
        -- 前回ファイルが存在している場合
        IF lb_fexists THEN
          lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                             ,cv_msg_003a04_017 -- ファイルが存在している
                                                             ,cv_tkn_code       -- トークン'CODE'
                                                             ,lt_arcode1_data(i).ar_code1
                                                             ,cv_tkn_name       -- トークン'NAME'
                                                             ,lt_arcode1_data(i).ar_code1_name
                                                             ,cv_tkn_file       -- トークン'FILE_NAME'
                                                             ,lt_arcode1_data(i).edi_file_name )
                                   ,1
                                   ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_ar_warn_msg
        );
        -- 終了ステータスを警告に更新
        ov_retcode := cv_status_warn;
--
        ELSE
          -- グローバル変数にEDIファイル情報を設定
          gv_edi_chain_code := lt_arcode1_data(i).chain_code;
          gv_edi_chain_name := lt_arcode1_data(i).chain_name;
          gv_edi_data_filename := lt_arcode1_data(i).edi_file_name;
          gv_ar_code_name      := lt_arcode1_data(i).ar_code1_name;
--
          --===============================================================
          -- A-4．EDIデータ取得ループ処理
          --===============================================================
          get_edi_date( iv_target_date => iv_target_date              -- 締日
                       ,iv_ar_code1    => lt_arcode1_data(i).ar_code1 -- 売掛コード１(請求書)
                       ,iv_start_mode  => iv_start_mode               -- 起動区分
                       ,ov_errbuf      => lv_errbuf                   -- エラー・メッセージ
                       ,ov_retcode     => lv_retcode                  -- リターン・コード
                       ,ov_errmsg      => lv_errmsg );                -- ユーザー・エラー・メッセージ 
--
          -- 戻り値がエラーである場合
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          -- 戻り値が警告である場合
          ELSIF (lv_retcode = cv_status_warn) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            -- 終了ステータスを警告に更新
            ov_retcode := cv_status_warn;
          ELSE
            NULL;
          END IF;
        END IF;
--
      END IF;
--
      IF (lv_ar_warn_msg IS NOT NULL) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
-- Modify 2009.05.25 Ver1.4 Start
-- Modify 2009.05.07 Ver1.3 Start
--        -- エラー売掛コード1(請求書)設定顧客ヘッダメッセージ
--         lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                        ,cv_msg_003a04_023      -- エラー売掛コード1(請求書)設定顧客ヘッダメッセージ
--                                                        ,cv_tkn_code            -- トークン'CODE'
--                                                        ,lt_arcode1_data(i).ar_code1)                                                   
--                                 ,1
--                                 ,5000);
--        FND_FILE.PUT_LINE(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_ar_warn_msg
--        );
--        -- カーソルオープン
--        iv_arcode1 := lt_arcode1_data(i).ar_code1;
--        OPEN get_edi_cust_cur(iv_arcode1);
--
--        -- データの一括取得
--        FETCH get_edi_cust_cur BULK COLLECT INTO lt_edi_cust;
--
--        -- 処理件数のセット
--        ln_cust_cnt := lt_edi_cust.COUNT;
--
--        -- カーソルクローズ
--        CLOSE get_edi_cust_cur;
--
--        -- ループ処理
--        <<cust_cur>>
--        FOR i IN 1..ln_cust_cnt LOOP
-- 
--        -- エラー売掛コード1(請求書)設定顧客明細メッセージ
--          lv_ar_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                        ,cv_msg_003a04_024      -- エラー売掛コード1(請求書)設定顧客明細メッセージ
--                                                        ,cv_tkn_code            -- トークン'CODE'
--                                                        ,lt_edi_cust(i).cust_code
--                                                        ,cv_tkn_name            -- トークン'NAME'
--                                                        ,lt_edi_cust(i).cust_name)
--                                 ,1
--                                 ,5000);
--          FND_FILE.PUT_LINE(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_ar_warn_msg
--        );
--        END LOOP cust_cur;*/
-- Modify 2009.05.07 Ver1.3 End
-- Modify 2009.05.25 Ver1.4 End
        -- 最終レコードでない場合、空白行を挿入
        IF (i <> ln_ar1_cnt) THEN
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '');
        END IF;
      END IF;
--
      -- 変数の初期化
      lv_ar_warn_msg       := NULL;
      gv_edi_chain_code    := NULL;
      gv_edi_chain_name    := NULL;
      gv_edi_data_filename := NULL;
      gv_ar_code_name      := NULL;
--
    END LOOP arcode1_loop;
--
    -- 手動起動の場合かつ成功・警告件数が0である場合
    IF (gv_start_mode_flg = cv_start_mode_h AND ov_retcode = cv_status_normal AND gn_output_cnt = 0) THEN
      gn_target_cnt := 0;
    END IF;
--
    -- 対象件数が0である場合
    IF (ov_retcode = cv_status_normal) AND (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                    ,cv_msg_003a04_012 ) -- 対象データ0件メッセージ
                          ,1
                          ,5000);
      ov_errmsg  := lv_errmsg;
      -- 終了ステータスを警告に更新
      ov_retcode := cv_status_warn;
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
  END get_edi_arcode;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date IN  VARCHAR2,     -- 締日
    iv_ar_code1    IN  VARCHAR2,     -- 売掛コード１(請求書)
    iv_start_mode  IN  VARCHAR2,     -- 起動区分
    ov_errbuf      OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_retcode_out VARCHAR2(1);     -- リターン・コード（EDI請求対象取得ループ処理）
    lv_errmsg_out  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ（EDI請求対象取得ループ処理）
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

    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_target_date        -- 締日
      ,iv_ar_code1           -- 売掛コード１(請求書)
      ,iv_start_mode         -- 起動区分
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_fixed_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  EDI請求対象取得ループ処理 (A-3)
    -- =====================================================
    get_edi_arcode(
       iv_target_date        -- 締日
      ,iv_ar_code1           -- 売掛コード１(請求書)
      ,iv_start_mode         -- 起動区分
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 戻り値の復元
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
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
    errbuf         OUT     VARCHAR2,         -- エラー・メッセージ #固定#
    retcode        OUT     VARCHAR2,         -- エラーコード       #固定#
    iv_target_date IN      VARCHAR2,         -- 締日
    iv_ar_code1    IN      VARCHAR2,         -- 売掛コード１(請求書)
    iv_start_mode  IN      VARCHAR2          -- 起動区分
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバックメッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
       iv_target_date  -- 締日
      ,iv_ar_code1     -- 売掛コード１(請求書)
      ,iv_start_mode   -- 起動区分
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
    --エラーメッセージが設定されている場合、エラー出力
    IF (lv_errmsg IS NOT NULL) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
    -- ファイル総件数を出力
    gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr -- 'XXCFR'
                                                   ,cv_msg_003a04_022   -- ファイル出力件数
                                                   ,cv_cnt_token
                                                   ,gn_output_cnt)
                         ,1
                         ,5000);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
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
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt - gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
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
END XXCFR003A04C;
/
