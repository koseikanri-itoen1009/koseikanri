CREATE OR REPLACE PACKAGE BODY XXCMM003A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A28C(body)
 * Description      : 顧客一括更新用ＣＳＶダウンロード
 * MD.050           : MD050_CMM_003_A28_顧客一括更新用CSVダウンロード
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  output_cust_data       処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   中村 祐基        新規作成
 *  2009/03/09    1.1   中村 祐基        ファイル出力先プロファイル名称変更
 *  2009/10/08    1.2   仁木 重人        障害I_E_542、E_T3_00469対応
 *  2009/10/20    1.3   久保島 豊        障害0001350対応
 *  2010/04/16    1.4   久保島 豊        障害E_本稼動_02295対応 出荷元保管場所の項目追加
 *  2011/11/28    1.5   窪 和重          障害E_本稼動_07553対応 EDI関連の項目追加
 *  2012/03/13    1.6   仁木 重人        障害E_本稼動_009272対応 訪問対象区分の項目追加
 *                                                               情報欄を最終項目に修正
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --メッセージ区分
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --メッセージ区分
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_out_file_dir  VARCHAR2(100);
  gv_out_file_file VARCHAR2(100);
  gv_org_id        NUMBER(15)   :=  fnd_global.org_id; --org_id
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
  init_err_expt                  EXCEPTION; --初期処理エラー
  fopen_err_expt                 EXCEPTION; --ファイルオープンエラー
  no_date_err_expt               EXCEPTION; --対象データ0件
  write_failure_expt             EXCEPTION; --CSVデータ出力エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A28C';      --パッケージ名
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  --
  cv_header_str_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00332';            --CSVファイルヘッダ文字列
  cv_no_data_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00301';            --対象データ0件メッセージ
  cv_parameter_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';            --入力パラメータノート
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';            --ファイル名ノート
  cv_param                   CONSTANT VARCHAR2(5)   := 'PARAM';                       --パラメータトークン
  cv_value                   CONSTANT VARCHAR2(5)   := 'VALUE';                       --パラメータ値トークン
  cv_cust_class              CONSTANT VARCHAR2(8)   := '顧客区分';                    --パラメータ・顧客区分
  cv_ar_invoice_code         CONSTANT VARCHAR2(22)  := '売掛コード１（請求書）';      --パラメータ・売掛コード１
  cv_ar_location_code        CONSTANT VARCHAR2(22)  := '売掛コード２（事業所）';      --パラメータ・売掛コード２
  cv_ar_others_code          CONSTANT VARCHAR2(22)  := '売掛コード３（その他）';      --パラメータ・売掛コード３
  cv_kigyou_code             CONSTANT VARCHAR2(10)  := '企業コード';                  --パラメータ・企業コード
  cv_sales_chain_code        CONSTANT VARCHAR2(26)  := 'チェーン店コード（販売先）';  --パラメータ・チェーン店コード（販売先）
  cv_delivery_chain_code     CONSTANT VARCHAR2(26)  := 'チェーン店コード（納品先）';  --パラメータ・チェーン店コード（納品先）
  cv_policy_chain_code       CONSTANT VARCHAR2(26)  := 'チェーン店コード（政策用）';  --パラメータ・チェーン店コード（政策用）
  cv_chain_store_code        CONSTANT VARCHAR2(26)  := 'チェーン店コード（ＥＤＩ）';  --パラメータ・チェーン店コード（ＥＤＩ）
  cv_gyotai_sho              CONSTANT VARCHAR2(14)  := '業態（小分類）';              --パラメータ・業態（小分類）
  cv_chiku_code              CONSTANT VARCHAR2(10)  := '地区コード';                  --パラメータ・地区コード
  cv_file_name               CONSTANT VARCHAR2(9)   := 'FILE_NAME';                   --ファイル名トークン
--
  --エラーメッセージ
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';  --プロファイル取得エラー
  cv_file_path_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00004';  --ファイルパスNULLエラー
  cv_file_name_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-10104';  --ファイル名NULLエラー
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';  --ファイルパス不正エラー
  cv_file_access_denied_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-10110';  --ファイルアクセス権限エラー
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00009';  --CSVデータ出力エラー
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- 2009/10/08 Ver1.2 add start by Shigeto.Niki
  gv_process_date           VARCHAR2(8);                                               -- 業務日付(YYYYMMDD)
-- 2009/10/08 Ver1.2 add end by Shigeto.Niki
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
--ver.1.1 2009/03/09 modify start
--    cv_out_file_dir  CONSTANT VARCHAR2(26) := 'XXCMM1_003A28_OUT_FILE_DIR';   -- XXCMM:顧客一括更新用CSVファイル出力先プロファイル名
    cv_out_file_dir  CONSTANT VARCHAR2(26) := 'XXCMM1_TMP_OUT';               -- XXCMM:顧客一括更新用CSVファイル出力先プロファイル名
--ver.1.1 2009/03/09 modify end
    cv_out_file_file CONSTANT VARCHAR2(27) := 'XXCMM1_003A28_OUT_FILE_FILE';  -- XXCMM:顧客一括更新用CSVファイル名プロファイル名
    cv_ng_profile    CONSTANT VARCHAR2(10) := 'NG_PROFILE';                   -- プロファイル取得失敗トークン
    cv_invalid_path  CONSTANT VARCHAR2(19) := 'CSV出力ディレクトリ';          -- プロファイル取得失敗（ディレクトリ）
    cv_invalid_name  CONSTANT VARCHAR2(17) := 'CSV出力ファイル名';            -- プロファイル取得失敗（ファイル名）
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
    --CSV出力ディレクトリをプロファイルより取得。失敗時はエラー
    gv_out_file_dir := FND_PROFILE.VALUE(cv_out_file_dir);
    IF (gv_out_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_path);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --CSV出力ファイル名をプロファイルより取得。失敗時はエラー
    gv_out_file_file := FND_PROFILE.VALUE(cv_out_file_file);
    IF (gv_out_file_file IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_name);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
-- 2009/10/08 Ver1.2 add start by Shigeto.Niki
      -- 業務日付をYYYYMMDD形式で取得します
      gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD');
-- 2009/10/08 Ver1.2 add end by Shigeto.Niki
--
  EXCEPTION
    WHEN init_err_expt THEN                           --*** 初期処理例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --初期処理例外時、対象件数、エラー件数は1件固定とする
      gn_target_cnt := 1;
      gn_error_cnt  := 1;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : file_open
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf       OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
    cn_record_byte CONSTANT NUMBER      := 2047;  --ファイル読み込み文字数
    cv_file_mode   CONSTANT VARCHAR2(1) := 'W';   --書き込みモードで開く
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      --ファイルオープン
      of_file_handler := UTL_FILE.FOPEN(gv_out_file_dir,
                                        gv_out_file_file,
                                        cv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --ファイルパスエラー
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_path_invalid_msg);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      --アクセス権限エラー
      WHEN UTL_FILE.ACCESS_DENIED THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxccp_msg_kbn,
                                              cv_file_access_denied_msg);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN fopen_err_expt THEN                           --*** ファイルオープンエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --ファイルオープンエラー時、対象件数、エラー件数は1件固定とする
      gn_target_cnt := 1;
      gn_error_cnt  := 1;
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : output_cust_data
   * Description      : 処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    if_file_handler         IN  UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    iv_customer_class       IN  VARCHAR2,            --   顧客区分
    iv_ar_invoice_grp_code  IN  VARCHAR2,            --   売掛コード１（請求書）
    iv_ar_location_code     IN  VARCHAR2,            --   売掛コード２（事業所）
    iv_ar_others_code       IN  VARCHAR2,            --   売掛コード３（その他）
    iv_kigyou_code          IN  VARCHAR2,            --   企業コード
    iv_sales_chain_code     IN  VARCHAR2,            --   チェーン店コード（販売先）
    iv_delivery_chain_code  IN  VARCHAR2,            --   チェーン店コード（納品先）
    iv_policy_chain_code    IN  VARCHAR2,            --   チェーン店コード（政策用）
    iv_chain_store_edi      IN  VARCHAR2,            --   チェーン店コード（ＥＤＩ）
    iv_gyotai_sho           IN  VARCHAR2,            --   業態（小分類）
    iv_chiku_code           IN  VARCHAR2,            --   地区コード
    ov_errbuf               OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_cust_data'; -- プログラム名
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
    cv_bill_to            CONSTANT VARCHAR2(7)     := 'BILL_TO';                --使用目的・請求先
    cv_other_to           CONSTANT VARCHAR2(8)     := 'OTHER_TO';               --使用目的・その他
    cv_aff_dept           CONSTANT VARCHAR2(15)    := 'XX03_DEPARTMENT';        --AFF部門マスタ参照タイプ
    cv_chain_code         CONSTANT VARCHAR2(16)    := 'XXCMM_CHAIN_CODE';       --参照コード：チェーン店参照タイプ
    cv_null_x             CONSTANT VARCHAR2(1)     := 'X';                      --NVL用ダミー文字列
    cn_zero               CONSTANT NUMBER(1)       := 0;                        --NVL用ダミー数値
    cv_customer           CONSTANT VARCHAR2(2)     := '10';                     --顧客区分・顧客
    cv_su_customer        CONSTANT VARCHAR2(2)     := '12';                     --顧客区分・上様顧客
    cv_trust_corp         CONSTANT VARCHAR2(2)     := '13';                     --顧客区分・法人管理先
    cv_ar_manage          CONSTANT VARCHAR2(2)     := '14';                     --顧客区分・売掛管理先顧客
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
    cv_kyoten_kbn         CONSTANT VARCHAR2(2)     := '1';                      --顧客区分・拠点
    cv_tenpo_kbn          CONSTANT VARCHAR2(2)     := '15';                     --顧客区分・店舗営業
    cv_tonya_kbn          CONSTANT VARCHAR2(2)     := '16';                     --顧客区分・問屋帳合先
    cv_keikaku_kbn        CONSTANT VARCHAR2(2)     := '17';                     --顧客区分・計画立案様
    cv_seikyusho_kbn      CONSTANT VARCHAR2(2)     := '20';                     --顧客区分・請求書用
    cv_tokatu_kbn         CONSTANT VARCHAR2(2)     := '21';                     --顧客区分・統括請求書用
    cv_language_ja        CONSTANT VARCHAR2(2)     := 'JA';                     --言語・日本語
    cv_ship_to            CONSTANT VARCHAR2(7)     := 'SHIP_TO';                --使用目的・出荷先
    cv_list_type_prl      CONSTANT VARCHAR2(3)     := 'PRL';                    --価格表リストタイプ・PRL
    cv_a_flag             CONSTANT VARCHAR2(2)     := 'A';                      --ステータス・A
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
    cv_yes_output         CONSTANT VARCHAR2(1)     := 'Y';                      --出力有無・有
    cv_no_output          CONSTANT VARCHAR2(1)     := 'N';                      --出力有無・無
    cv_corp_no_data       CONSTANT VARCHAR2(20)    := '顧客法人情報未登録。';   --顧客法人情報未設定
    cv_addon_cust_no_data CONSTANT VARCHAR2(20)    := '顧客追加情報未登録。';   --顧客追加情報未設定
    cv_sales_base_class   CONSTANT VARCHAR2(1)     := '1';                      --顧客区分・拠点
    cv_ng_word            CONSTANT VARCHAR2(7)     := 'NG_WORD';                --CSV出力エラートークン・NG_WORD
    cv_err_cust_code_msg  CONSTANT VARCHAR2(16)    := 'エラー顧客コード';       --CSV出力エラー文字列
    cv_ng_data            CONSTANT VARCHAR2(7)     := 'NG_DATA';                --CSV出力エラートークン・NG_DATA
--
    -- *** ローカル変数 ***
    lv_header_str                  VARCHAR2(2000)  := NULL;                     --ヘッダメッセージ格納用変数
    lv_output_str                  VARCHAR2(2047)  := NULL;                     --出力文字列格納用変数
    ln_output_cnt                  NUMBER          := 0;                        --出力件数
    lv_sales_kigyou_code           fnd_flex_values.attribute1%TYPE;             --企業コード（販売先）格納用変数
    lv_delivery_kigyou_code        fnd_flex_values.attribute1%TYPE;             --企業コード（納品先）格納用変数
    lv_output_excute               VARCHAR2(1)     := 'Y';                      --出力有無
    ln_credit_limit                xxcmm_mst_corporate.credit_limit%TYPE;       --顧客法人情報.与信限度額
    lv_decide_div                  xxcmm_mst_corporate.decide_div%TYPE;         --顧客法人情報.判定区分
    lv_information                 VARCHAR2(100)   := NULL;
    lv_sales_base_name             VARCHAR2(50)    := NULL;
    lv_payment_term                VARCHAR2(100)   := NULL;                     --ローカル変数・支払条件
    lv_payment_term_second         VARCHAR2(100)   := NULL;                     --ローカル変数・第2支払条件
    lv_payment_term_third          VARCHAR2(100)   := NULL;                     --ローカル変数・第3支払条件
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
    lv_price_list                  qp_list_headers_tl.name%TYPE;                --ローカル変数・価格表
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 顧客一括更新情報カーソル
    CURSOR cust_data_cur
    IS
      SELECT   hca.cust_account_id                    customer_id,          --顧客ＩＤ
               hca.customer_class_code                customer_class_code,  --顧客区分
               hca.account_number                     customer_code,        --顧客コード
               hp.party_name                          customer_name,        --顧客名称
               hp.organization_name_phonetic          customer_name_kana,   --顧客名称カナ
               hca.account_name                       customer_name_ryaku,  --略称
               hl.postal_code                         postal_code,          --郵便番号
               hl.state                               state,                --都道府県
               hl.city                                city,                 --市・区
               hl.address1                            address1,             --住所1
               hl.address2                            address2,             --住所2
               hl.address3                            address3,             --地区コード
               hcsu.payment_term_id                   payment_term_id,      --支払条件
               hcsu.attribute2                        payment_term_second,  --第2支払条件
               hcsu.attribute3                        payment_term_third,   --第3支払条件
-- 2009/10/20 Ver1.3 modify start by Y.Kuboshima
--               hcsu.attribute1                        invoice_class,        --請求書発行区分
               xca.invoice_printing_unit              invoice_class,        --請求書印刷単位
-- 2009/10/20 Ver1.3 modify end by Y.Kuboshima
               hcsu.attribute8                        invoice_sycle,        --請求書発行サイクル
               hcsu.attribute7                        invoice_form,         --請求書出力形式
               hcsu.attribute4                        ar_invoice_code,      --売掛コード１（請求書）
               hcsu.attribute5                        ar_location_code,     --売掛コード２（事業所）
               hcsu.attribute6                        ar_others_code,       --売掛コード３（その他）
-- 2009/10/08 Ver1.2 modify start by Shigeto.Niki
--                CONCAT(ff.attribute7, ff.attribute6)   main_base_code,       --本部コード
               -- 最新本部コードを取得
               CASE
                 WHEN (ff.attribute6 <= gv_process_date) THEN ff.attribute9  --新本部コード
                 ELSE                                         ff.attribute7  --旧本部コード
               END                                AS  main_base_code,       --本部コード
-- 2009/10/08 Ver1.2 modify end by Shigeto.Niki
               xca.customer_id                        addon_customer_id,    --顧客追加情報.顧客ＩＤ
               xca.sale_base_code                     sale_base_code,       --売上拠点コード
               hp.duns_number_c                       customer_status,      --顧客ステータス
               xca.stop_approval_reason               approval_reason,      --中止理由
               xca.stop_approval_date                 approval_date,        --中止決済日
               xca.sales_chain_code                   sales_chain_code,     --チェーン店コード（販売先）
               xca.delivery_chain_code                delivery_chain_code,  --チェーン店コード（納品先）
               xca.policy_chain_code                  policy_chain_code,    --チェーン店コード（営業政策用）
               xca.chain_store_code                   chain_store_code,     --チェーン店コード（ＥＤＩ）
               xca.store_code                         store_code,           --店舗コード
               xca.business_low_type                  business_low_type     --業態（小分類）
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
              ,xca.invoice_code                       invoice_code          --請求書用コード
              ,xca.industry_div                       industry_div          --業種
              ,xca.bill_base_code                     bill_base_code        --請求拠点
              ,xca.receiv_base_code                   receiv_base_code      --入金拠点
              ,xca.delivery_base_code                 delivery_base_code    --納品拠点
              ,xca.selling_transfer_div               selling_transfer_div  --売上実績振替
              ,xca.card_company                       card_company          --カード会社
              ,xca.wholesale_ctrl_code                wholesale_ctrl_code   --問屋管理コード
              ,hcas.cust_acct_site_id                 cust_acct_site_id     --顧客所在地ＩＤ
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
-- 2010/04/16 Ver1.4 E_本稼動_02295 add start by Y.Kuboshima
              ,xca.ship_storage_code                  ship_storage_code     --出荷元保管場所
-- 2010/04/16 Ver1.4 E_本稼動_02295 add end by Y.Kuboshima
-- 2011/11/28 Ver1.5 add start by K.Kubo
              ,xca.delivery_order                     delivery_order        --配送順（EDI）
              ,xca.edi_district_code                  edi_district_code     --EDI地区コード（EDI)
              ,xca.edi_district_name                  edi_district_name     --EDI地区名（EDI）
              ,xca.edi_district_kana                  edi_district_kana     --EDI地区名カナ（EDI）
              ,xca.tsukagatazaiko_div                 tsukagatazaiko_div    --通過在庫型区分（EDI）
              ,xca.deli_center_code                   deli_center_code      --EDI納品センターコード
              ,xca.deli_center_name                   deli_center_name      --EDI納品センター名
              ,xca.edi_forward_number                 edi_forward_number    --EDI伝送追番
              ,xca.cust_store_name                    cust_store_name       --顧客店舗名称
              ,xca.torihikisaki_code                  torihikisaki_code     --取引先コード
-- 2011/11/28 Ver1.5 add end by K.Kubo
-- 2012/03/13 Ver1.6 E_本稼動_09272 add start by S.Niki
              ,xca.vist_target_div                    vist_target_div       --訪問対象区分
-- 2012/03/13 Ver1.6 E_本稼動_09272 add end by S.Niki
      FROM     hz_cust_accounts     hca,
               hz_cust_acct_sites   hcas,
               hz_cust_site_uses    hcsu,
               hz_parties           hp,
               hz_party_sites       hps,
               hz_locations         hl,
               xxcmm_cust_accounts  xca,
               (SELECT ffv.flex_value fv,
                       ffv.attribute6 attribute6,
-- 2009/10/08 Ver1.2 add start by Shigeto.Niki
                       ffv.attribute9 attribute9,
-- 2009/10/08 Ver1.2 add end by Shigeto.Niki
                       ffv.attribute7 attribute7
                FROM   fnd_flex_value_sets  ffvs,
                       fnd_flex_values      ffv
                WHERE  ffvs.flex_value_set_name = cv_aff_dept
                AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
               ) ff
      WHERE    hca.customer_class_code   = NVL(iv_customer_class, hca.customer_class_code)
      AND      hca.cust_account_id       = hcas.cust_account_id
      AND      hcas.cust_acct_site_id    = hcsu.cust_acct_site_id
      AND      ((hcsu.site_use_code      = cv_bill_to
               AND hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage))
      OR       (hcsu.site_use_code       = cv_other_to
               AND hca.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)))
      AND      hca.party_id              = hp.party_id
      AND      hp.party_id               = hps.party_id
      AND      hps.location_id           = hl.location_id
      AND      xca.customer_id (+)       = hca.cust_account_id
      AND      ff.fv (+)                 = NVL(xca.sale_base_code, cv_null_x)
      AND      (hcsu.attribute4          = iv_ar_invoice_grp_code OR iv_ar_invoice_grp_code IS NULL)
      AND      (hcsu.attribute5          = iv_ar_location_code    OR iv_ar_location_code    IS NULL)
      AND      (hcsu.attribute6          = iv_ar_others_code      OR iv_ar_others_code      IS NULL)
-- 2009/10/20 Ver1.3 modify start by Y.Kuboshima
--      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.sales_chain_code    = iv_sales_chain_code))
--      OR       (iv_sales_chain_code    IS NULL))
--      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.delivery_chain_code = iv_delivery_chain_code))
--      OR       (iv_delivery_chain_code IS NULL))
      -- 顧客区分'12','15','16'追加
      AND      (((hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn))
        AND      (xca.sales_chain_code    = iv_sales_chain_code))
      OR       (iv_sales_chain_code    IS NULL))
      -- 顧客区分'12','15','16'追加
      AND      (((hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn))
        AND      (xca.delivery_chain_code = iv_delivery_chain_code))
      OR       (iv_delivery_chain_code IS NULL))
-- 2009/10/20 Ver1.3 modify end by Y.Kuboshima
      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.policy_chain_code   = iv_policy_chain_code))
      OR       (iv_policy_chain_code   IS NULL))
      AND      (((hca.customer_class_code IN (cv_customer, cv_ar_manage)) AND (xca.chain_store_code    = iv_chain_store_edi))
      OR       (iv_chain_store_edi     IS NULL))
      AND      ((xca.business_low_type   = iv_gyotai_sho) OR (iv_gyotai_sho IS NULL))
      AND      ((hl.address3             = iv_chiku_code) OR (iv_chiku_code IS NULL))
      AND      hcas.org_id = gv_org_id
      AND      hcsu.org_id = gv_org_id
      AND      hcas.party_site_id        = hps.party_site_id
      AND      hps.location_id           = (SELECT MIN(hpsiv.location_id)
                                            FROM   hz_cust_acct_sites hcasiv,
                                                   hz_party_sites     hpsiv
                                            WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                            AND    hcasiv.party_site_id   = hpsiv.party_site_id)
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
      AND      hca.customer_class_code <> cv_kyoten_kbn
      AND      hcsu.status               = cv_a_flag
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
      ORDER BY main_base_code, customer_code
      ;
--
    -- 顧客一括更新情報カーソルレコード型
    cust_data_rec cust_data_cur%ROWTYPE;
--
    -- 企業コード取得カーソル
    CURSOR get_kigyou_cur(
      iv_chain_code  IN VARCHAR2)
    IS
      SELECT flvv.attribute1       kigyou_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_chain_code
      AND    flvv.lookup_code = iv_chain_code
      ;
    -- 企業コード取得カーソルレコード型
    get_kigyou_rec get_kigyou_cur%ROWTYPE;
--
    -- 売上拠点名称取得カーソル
    CURSOR get_sales_base_name_cur(
      iv_base_code  IN VARCHAR2)
    IS
      SELECT hp.party_name     sales_base_name
      FROM   hz_cust_accounts  hca,
             hz_parties        hp
      WHERE  hca.party_id            = hp.party_id
      AND    hca.customer_class_code = cv_sales_base_class
      AND    hca.account_number      = iv_base_code
      ;
    -- 売上拠点名称取得カーソルレコード型
    get_sales_base_name_rec get_sales_base_name_cur%ROWTYPE;
--
    -- 支払条件取得カーソル
    CURSOR get_payment_term_cur(
      iv_payment_term_id IN VARCHAR2)
    IS
      SELECT rt.name     payment_name
      FROM   ra_terms    rt
      WHERE  rt.term_id  = iv_payment_term_id
      ;
    -- 支払条件チェックカーソルレコード型
    get_payment_term_rec  get_payment_term_cur%ROWTYPE;
--
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
    -- 価格表取得カーソル
    CURSOR get_price_list_cur(
      in_cust_acct_site_id IN NUMBER)
    IS
      SELECT qlht.name price_list
      FROM   hz_cust_site_uses  hcsu
            ,qp_list_headers_tl qlht
            ,qp_list_headers_b  qlhb
      WHERE  hcsu.price_list_id     = qlhb.list_header_id
      AND    qlht.list_header_id    = qlhb.list_header_id
      AND    qlht.source_lang       = cv_language_ja
      AND    qlht.language          = cv_language_ja
      AND    qlhb.orig_org_id       = fnd_global.org_id
      AND    qlhb.list_type_code    = cv_list_type_prl
      AND    hcsu.site_use_code     = cv_ship_to
      AND    hcsu.cust_acct_site_id = in_cust_acct_site_id
      ;
    -- 価格表チェックカーソルレコード型
    get_price_list_rec  get_price_list_cur%ROWTYPE;
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_header_str := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_header_str_msg);
    UTL_FILE.PUT_LINE(if_file_handler,lv_header_str);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_header_str);
--
    --顧客一括更新情報カーソルループ
    << cust_for_loop >>
    FOR cust_data_rec IN cust_data_cur
    LOOP
      IF (iv_kigyou_code IS NOT NULL) THEN
        --企業コード入力時は判定外のレコードは出力しない
        lv_output_excute := cv_no_output;
      END IF;
      -- ===============================
      -- 企業コード取得・パラメータチェック
      -- ===============================
      IF   (cust_data_rec.customer_class_code = cv_customer
        OR  cust_data_rec.customer_class_code = cv_ar_manage
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        OR  cust_data_rec.customer_class_code = cv_su_customer
        OR  cust_data_rec.customer_class_code = cv_tenpo_kbn
        OR  cust_data_rec.customer_class_code = cv_tonya_kbn)
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
      THEN
        IF (cust_data_rec.sales_chain_code IS NOT NULL) THEN
          << sales_kigyou_loop >>
          FOR get_kigyou_rec IN get_kigyou_cur( cust_data_rec.sales_chain_code )
          LOOP
            lv_sales_kigyou_code := get_kigyou_rec.kigyou_code;
          END LOOP sales_kigyou_loop;
        END IF;
        IF (cust_data_rec.delivery_chain_code IS NOT NULL) THEN
          << delivery_kigyou_loop >>
          FOR get_kigyou_rec IN get_kigyou_cur( cust_data_rec.delivery_chain_code )
          LOOP
            lv_delivery_kigyou_code := get_kigyou_rec.kigyou_code;
          END LOOP delivery_kigyou_loop;
        END IF;
        IF    (iv_kigyou_code = lv_sales_kigyou_code)
          OR  (iv_kigyou_code = lv_delivery_kigyou_code)
        THEN
          lv_output_excute := cv_yes_output;
        END IF;
      END IF;
--
      --企業コードチェックの出力実行判定がYのときのみ、出力文字列を作成、出力
      IF (lv_output_excute = cv_yes_output) THEN
--
        --顧客区分が法人管理先顧客の場合
        IF (cust_data_rec.customer_class_code = cv_trust_corp) THEN
          -- ===============================
          -- 顧客法人情報マスタ取得
          -- ===============================
          BEGIN
            SELECT xmc.credit_limit  credit_limit,
                   xmc.decide_div    decide_div
            INTO   ln_credit_limit,
                   lv_decide_div
            FROM   xxcmm_mst_corporate xmc
            WHERE  xmc.customer_id = cust_data_rec.customer_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_information := cv_corp_no_data;
          END;
        END IF;
--
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        --顧客区分'10','12'の場合
        IF (cust_data_rec.customer_class_code IN (cv_customer, cv_su_customer)) THEN
          -- ===============================
          -- 価格表マスタ取得
          -- ===============================
          << price_list_loop >>
          FOR get_price_list_rec IN get_price_list_cur( cust_data_rec.cust_acct_site_id )
          LOOP
            lv_price_list := get_price_list_rec.price_list;
          END LOOP price_list_loop;
        END IF;
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
        -- ===============================
        -- 出力値設定
        -- ===============================
        --顧客追加情報未設定時、情報欄に文言追加
        IF (cust_data_rec.addon_customer_id IS NULL) THEN
          lv_information := lv_information || cv_addon_cust_no_data;
        END IF;
--
        --顧客区分によって、特定項目にNULL設定
        IF   (cust_data_rec.customer_class_code <> cv_customer
          AND cust_data_rec.customer_class_code <> cv_su_customer
          AND cust_data_rec.customer_class_code <> cv_ar_manage)
        THEN
          cust_data_rec.ar_invoice_code      := NULL;
          cust_data_rec.ar_location_code     := NULL;
          cust_data_rec.ar_others_code       := NULL;
-- 2009/10/20 Ver1.3 delete start by Y.Kuboshima
--          cust_data_rec.invoice_class        := NULL;
-- 2009/10/20 Ver1.3 delete end by Y.Kuboshima
          cust_data_rec.invoice_sycle        := NULL;
          cust_data_rec.invoice_form         := NULL;
          cust_data_rec.payment_term_id      := NULL;
          cust_data_rec.payment_term_second  := NULL;
          cust_data_rec.payment_term_third   := NULL;
        END IF;
        IF   (cust_data_rec.customer_class_code <> cv_customer
          AND cust_data_rec.customer_class_code <> cv_ar_manage)
        THEN
-- 2009/10/20 Ver1.3 delete start by Y.Kuboshima
--          cust_data_rec.sales_chain_code     := NULL;
--          lv_sales_kigyou_code               := NULL;
--          cust_data_rec.delivery_chain_code  := NULL;
--          lv_delivery_kigyou_code            := NULL;
-- 2009/10/20 Ver1.3 delete end by Y.Kuboshima
          cust_data_rec.policy_chain_code    := NULL;
          cust_data_rec.chain_store_code     := NULL;
          cust_data_rec.store_code           := NULL;
        END IF;
        --
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        -- 顧客区分'10','12','14','15','16'以外の場合
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn)) THEN
          -- チェーン店コード（販売先）,企業コード（販売先）,チェーン店コード（納品先）,企業コード（納品先）にNULLをセット
          cust_data_rec.sales_chain_code     := NULL;
          lv_sales_kigyou_code               := NULL;
          cust_data_rec.delivery_chain_code  := NULL;
          lv_delivery_kigyou_code            := NULL;
        END IF;
        --
        -- 顧客区分'10','12','13','14','15','16','17'以外の場合
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_trust_corp, cv_ar_manage, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          -- 業態(小分類),業種,売上実績振替,問屋管理コードにNULLをセット
          cust_data_rec.business_low_type    := NULL;
          cust_data_rec.industry_div         := NULL;
          cust_data_rec.selling_transfer_div := NULL;
          cust_data_rec.wholesale_ctrl_code  := NULL;
-- 2010/04/16 Ver1.4 E_本稼動_02295 add start by Y.Kuboshima
          cust_data_rec.ship_storage_code    := NULL;
-- 2010/04/16 Ver1.4 E_本稼動_02295 add end by Y.Kuboshima
        END IF;
        --
        -- 顧客区分'10','12','14','20','21'以外の場合
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage, cv_seikyusho_kbn, cv_tokatu_kbn)) THEN
          -- 請求拠点にNULLをセット
          cust_data_rec.bill_base_code       := NULL;
        END IF;
        --
        -- 顧客区分'10','12','14'以外の場合
        IF (cust_data_rec.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)) THEN
          -- 入金拠点,納品拠点にNULLをセット
          cust_data_rec.receiv_base_code     := NULL;
          cust_data_rec.delivery_base_code   := NULL;
        END IF;
        --
        -- 顧客区分'10'以外の場合
        IF (cust_data_rec.customer_class_code <> cv_customer) THEN
          -- カード会社,請求書用コードにNULLをセット
          cust_data_rec.card_company         := NULL;
          cust_data_rec.invoice_code         := NULL;
        END IF;
        --
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
        --売上拠点名称取得
        << seles_base_name_loop >>
        FOR get_sales_base_name_rec IN get_sales_base_name_cur( cust_data_rec.sale_base_code )
        LOOP
          lv_sales_base_name := get_sales_base_name_rec.sales_base_name;
        END LOOP seles_base_name_loop;
--
      --顧客区分'10'(顧客)、'12'(上様顧客)、'14'(売掛管理先顧客)のときのみ、支払条件・第2支払条件・第3支払条件取得・設定
      IF (cust_data_rec.customer_class_code   = cv_customer)
        OR (cust_data_rec.customer_class_code = cv_su_customer)
        OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
        --支払条件取得
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_id )
        LOOP
          lv_payment_term := get_payment_term_rec.payment_name;
        END LOOP get_payment_term_loop;
        --第2支払条件取得
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_second )
        LOOP
          lv_payment_term_second := get_payment_term_rec.payment_name;
        END LOOP get_payment_term_loop;
        --第3支払条件取得
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_third )
        LOOP
          lv_payment_term_third := get_payment_term_rec.payment_name;
        END LOOP get_payment_term_loop;
      END IF;
--
        --出力文字列作成
        lv_output_str := SUBSTRB(cust_data_rec.customer_class_code,1,2);                               --顧客区分
-- 2009/10/08 Ver1.2 modify start by Shigeto.Niki        
--        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.main_base_code,1,7);       --本部コード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.main_base_code,1,6);       --本部コード
-- 2009/10/08 Ver1.2 modify end by Shigeto.Niki
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.sale_base_code,1,4);       --売上拠点コード
        lv_output_str := lv_output_str || cv_comma || lv_sales_base_name;                              --売上拠点名称
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_code,1,9);        --顧客コード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_name,1,100);      --顧客名称
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_name_kana,1,50);  --顧客名称カナ
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_name_ryaku,1,80); --略称
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.customer_status,1,2);      --顧客ステータス
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.approval_reason,1,1);      --中止決済理由
        lv_output_str := lv_output_str || cv_comma || TO_CHAR(cust_data_rec.approval_date,'YYYY/MM/DD');  --中止決済日
        lv_output_str := lv_output_str || cv_comma || TO_CHAR(ln_credit_limit);                        --与信限度額
        lv_output_str := lv_output_str || cv_comma || lv_decide_div;                                   --判定区分
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ar_invoice_code,1,12);     --売掛コード１（請求書）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ar_location_code,1,12);    --売掛コード２（事業所）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ar_others_code,1,12);      --売掛コード３（その他）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_class,1,1);        --請求書印刷区分
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_sycle,1,1);        --請求書発行サイクル
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_form,1,1);         --請求書出力形式
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_payment_term,1,8);                    --支払条件
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_payment_term_second,1,8);             --第2支払条件
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_payment_term_third,1,8);              --第3支払条件
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.sales_chain_code,1,9);     --チェーン店コード（販売先）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_sales_kigyou_code,1,6);               --企業コード（販売先）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.delivery_chain_code,1,9);  --チェーン店コード（納品先）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_delivery_kigyou_code,1,6);            --企業コード（納品先）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.policy_chain_code,1,30);   --チェーン店コード（営業政策用）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.chain_store_code,1,4);     --チェーン店コード（ＥＤＩ）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.store_code,1,10);          --店舗コード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.business_low_type,1,2);    --業態（小分類）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.postal_code,1,7);          --郵便番号
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.state,1,30);               --都道府県
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.city,1,30);                --市・区
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.address1,1,240);           --住所1
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.address2,1,240);           --住所2
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.address3,1,5);             --地区コード
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.invoice_code,1,9);         --請求書用コード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.industry_div,1,2);         --業種
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.bill_base_code,1,4);       --請求拠点
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.receiv_base_code,1,4);     --入金拠点
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.delivery_base_code,1,4);   --納品拠点
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.selling_transfer_div,1,4); --売上実績振替
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.card_company,1,9);         --カード会社
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.wholesale_ctrl_code,1,9);  --問屋管理コード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_price_list,1,240);                    --価格表
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
-- 2010/04/16 Ver1.4 E_本稼動_02295 add start by Y.Kuboshima
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.ship_storage_code,1,10);   --出荷元保管場所
-- 2010/04/16 Ver1.4 E_本稼動_02295 add end by Y.Kuboshima
-- 2012/03/13 Ver1.6 E_本稼動_09272 del start by S.Niki
--        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_information,1,100);                   --情報欄
-- 2012/03/13 Ver1.6 E_本稼動_09272 del end by S.Niki
-- 2011/11/28 Ver1.5 add start by K.Kubo
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.delivery_order,1,14);      --配送順（EDI）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_district_code,1,8);    --EDI地区コード（EDI)
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_district_name,1,40);   --EDI地区名（EDI）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_district_kana,1,20);   --EDI地区名カナ（EDI）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.tsukagatazaiko_div,1,2);   --通過在庫型区分（EDI）
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.deli_center_code,1,8);     --EDI納品センターコード
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.deli_center_name,1,20);    --EDI納品センター名
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.edi_forward_number,1,2);   --EDI伝送追番
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.cust_store_name,1,30);     --顧客店舗名称
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.torihikisaki_code,1,8);    --取引先コード
-- 2011/11/28 Ver1.5 add end by K.Kubo
-- 2012/03/13 Ver1.6 E_本稼動_09272 add start by S.Niki
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(cust_data_rec.vist_target_div,1,1);      --訪問対象区分
        lv_output_str := lv_output_str || cv_comma || SUBSTRB(lv_information,1,100);                   --情報欄
-- 2012/03/13 Ver1.6 E_本稼動_09272 add end by S.Niki
--
        --文字列出力
        BEGIN
          --csvファイル出力
          UTL_FILE.PUT_LINE(if_file_handler,lv_output_str);
          --コンカレント出力
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_output_str);
        EXCEPTION
          WHEN UTL_FILE.WRITE_ERROR THEN  --*** ファイル書き込みエラー ***
            lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                  cv_write_err_msg,
                                                  cv_ng_word,
                                                  cv_err_cust_code_msg,
                                                  cv_ng_data,
                                                  cust_data_rec.customer_code);
            lv_errbuf  := lv_errmsg;
          RAISE write_failure_expt;
        END;
        --出力件数カウント
        ln_output_cnt := ln_output_cnt + 1;
      END IF;
--
      --変数初期化
      lv_output_str           := NULL;
      lv_sales_kigyou_code    := NULL;
      lv_delivery_kigyou_code := NULL;
      lv_output_excute        := cv_yes_output;
      ln_credit_limit         := NULL;
      lv_decide_div           := NULL;
      lv_information          := NULL;
      lv_sales_base_name      := NULL;
      lv_payment_term         := NULL;
      lv_payment_term_second  := NULL;
      lv_payment_term_third   := NULL;
-- 2009/10/20 Ver1.3 add start by Y.Kuboshima
      lv_price_list           := NULL;
-- 2009/10/20 Ver1.3 add end by Y.Kuboshima
--
    END LOOP cust_for_loop;
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --対象データ0件時、メッセージを出力しRAISEする。非エラー扱い
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_msg);
      lv_errbuf := lv_errmsg;
      --csvファイル出力
      UTL_FILE.PUT_LINE(if_file_handler,'');
      UTL_FILE.PUT_LINE(if_file_handler,lv_errmsg);
      --コンカレント出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RAISE no_date_err_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_err_expt THEN                         --*** 対象データ0件 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_normal;
    WHEN write_failure_expt THEN                       --*** CSVデータ出力エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --CSVデータ出力エラー時、対象件数、エラー件数は1件固定とする
      gn_target_cnt := 1;
      gn_error_cnt  := 1;
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
  END output_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_customer_class         IN  VARCHAR2,     --顧客区分
    iv_ar_invoice_grp_code    IN  VARCHAR2,     --売掛コード１（請求書）
    iv_ar_location_code       IN  VARCHAR2,     --売掛コード２（事業所）
    iv_ar_others_code         IN  VARCHAR2,     --売掛コード３（その他）
    iv_kigyou_code            IN  VARCHAR2,     --企業コード
    iv_sales_chain_code       IN  VARCHAR2,     --チェーン店コード（販売先）
    iv_delivery_chain_code    IN  VARCHAR2,     --チェーン店コード（納品先）
    iv_policy_chain_code      IN  VARCHAR2,     --チェーン店コード（政策用）
    iv_chain_store_edi        IN  VARCHAR2,     --チェーン店コード（ＥＤＩ）
    iv_gyotai_sho             IN  VARCHAR2,     --業態（小分類）
    iv_chiku_code             IN  VARCHAR2,     --地区コード
    ov_errbuf                 OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
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
    lf_file_handler   UTL_FILE.FILE_TYPE;  --ファイルハンドラ
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
    --パラメータ出力
    --顧客区分
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_cust_class
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_customer_class
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --売掛コード１
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_ar_invoice_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_ar_invoice_grp_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --売掛コード２
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_ar_location_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_ar_location_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --売掛コード３
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_ar_others_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_ar_others_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --企業コード
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_kigyou_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_kigyou_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --チェーン店コード（販売先）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_sales_chain_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_sales_chain_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --チェーン店コード（納品先）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_delivery_chain_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_delivery_chain_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --チェーン店コード（政策用）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_policy_chain_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_policy_chain_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --チェーン店コード（ＥＤＩ）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_chain_store_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_chain_store_edi
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --業態（小分類）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_gyotai_sho
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_gyotai_sho
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --地区コード
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_chiku_code
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_chiku_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    --初期処理エラー時は処理を中断
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
--
    --I/Fファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxccp_msg_kbn
                    ,iv_name         => cv_file_name_msg
                    ,iv_token_name1  => cv_file_name
                    ,iv_token_value1 => gv_out_file_file
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- ファイルオープン処理(A-2)
    -- ===============================
    file_open(
       lf_file_handler    -- ファイルハンドラ
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
    -- ===============================
    output_cust_data(
       lf_file_handler         -- ファイルハンドラ
      ,iv_customer_class       -- 顧客区分
      ,iv_ar_invoice_grp_code  -- 売掛コード１（請求書）
      ,iv_ar_location_code     -- 売掛コード２（事業所）
      ,iv_ar_others_code       -- 売掛コード３（その他）
      ,iv_kigyou_code          -- 企業コード
      ,iv_sales_chain_code     -- チェーン店コード（販売先）
      ,iv_delivery_chain_code  -- チェーン店コード（納品先）
      ,iv_policy_chain_code    -- チェーン店コード（政策用）
      ,iv_chain_store_edi      -- チェーン店コード（ＥＤＩ）
      ,iv_gyotai_sho           -- 業態（小分類）
      ,iv_chiku_code           -- 地区コード
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    --ファイルクローズ処理
    IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
      --ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_handler);
    END IF;
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
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
    errbuf                    OUT VARCHAR2,     --エラー・メッセージ  --# 固定 #
    retcode                   OUT VARCHAR2,     --リターン・コード    --# 固定 #
    iv_customer_class         IN  VARCHAR2,     --顧客区分
    iv_ar_invoice_grp_code    IN  VARCHAR2,     --売掛コード１（請求書）
    iv_ar_location_code       IN  VARCHAR2,     --売掛コード２（事業所）
    iv_ar_others_code         IN  VARCHAR2,     --売掛コード３（その他）
    iv_kigyou_code            IN  VARCHAR2,     --企業コード
    iv_sales_chain_code       IN  VARCHAR2,     --チェーン店コード（販売先）
    iv_delivery_chain_code    IN  VARCHAR2,     --チェーン店コード（納品先）
    iv_policy_chain_code      IN  VARCHAR2,     --チェーン店コード（政策用）
    iv_chain_store_edi        IN  VARCHAR2,     --チェーン店コード（ＥＤＩ）
    iv_gyotai_sho             IN  VARCHAR2,     --業態（小分類）
    iv_chiku_code             IN  VARCHAR2      --地区コード
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
       iv_customer_class         --顧客区分
      ,iv_ar_invoice_grp_code    --売掛コード１（請求書）
      ,iv_ar_location_code       --売掛コード２（事業所）
      ,iv_ar_others_code         --売掛コード３（その他）
      ,iv_kigyou_code            --企業コード
      ,iv_sales_chain_code       --チェーン店コード（販売先）
      ,iv_delivery_chain_code    --チェーン店コード（納品先）
      ,iv_policy_chain_code      --チェーン店コード（政策用）
      ,iv_chain_store_edi        --チェーン店コード（ＥＤＩ）
      ,iv_gyotai_sho             --業態（小分類）
      ,iv_chiku_code             --地区コード
      ,lv_errbuf                 --エラー・メッセージ           --# 固定 #
      ,lv_retcode                --リターン・コード             --# 固定 #
      ,lv_errmsg                 --ユーザー・エラー・メッセージ --# 固定 #
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
END XXCMM003A28C;
/
