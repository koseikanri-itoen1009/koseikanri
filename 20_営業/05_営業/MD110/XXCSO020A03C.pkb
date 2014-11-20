CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A03C(body)
 * Description      : フルベンダー用ＳＰ専決・登録画面によって登録された新規顧客情報を顧客
 *                    マスタ、契約先マスタに登録します。また、フルベンダー用ＳＰ専決・登録
 *                    画面にて変更された既存顧客情報を顧客マスタに反映します。
 * MD.050           : MD050_CSO_020_A03_各種マスタ反映処理機能
 *
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc              初期処理(A-1)
 *  get_install_at_info     設置先情報抽出(A-2)
 *  regist_party            パーティマスタ登録更新(A-3)
 *  regist_locat_party_site 顧客事業所／パーティサイトマスタ登録更新(A-4)
 *  regist_cust_account     顧客マスタ登録更新(A-5)
 *  regist_cust_acct_site   顧客所在地マスタ登録(A-6)
 *  regist_cust_site_use    顧客使用目的マスタ登録(A-7)
 *  regist_account_addon    顧客アドオンマスタ登録更新(A-8)
 *  get_contract            契約先情報抽出(A-9)
 *  regist_contract         契約先登録(A-10)
 *  submain                 メイン処理プロシージャ
 *  main                    実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-09    1.0   Kazuo.Satomura   新規作成
 *  2008-12-16          Kazuo.Satomura   単体テストバグ修正
 *  2009-02-19          Kazuo.Satomura   仕様変更対応
 *                                       ・処理対象外の場合も設置先ＩＤ・契約先ＩＤを戻す
 *                                         よう修正
 *  2009-02-20          Kazuo.Satomura   仕様変更対応
 *                                       ・顧客ステータス、顧客区分を定数に変更
 *  2009-04-21          Kazuo.Satomura   システムテスト障害対応(T1_0685)
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2009-05-08    1.2   Kazuo.Satomura   システムテスト障害対応(T1_0913)
 *  2009-05-21    1.3   Kazuo.Satomura   システムテスト障害対応(T1_1092)
 *  2009-06-30    1.4   Kazuo.Satomura   統合テスト障害対応(0000209)
 *  2009-07-09    1.5   Kazuo.Satomura   統合テスト障害対応(0000341)
 *  2010-01-08    1.6   Kazuyo.Hosoi     E_本稼動_01017対応
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
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
  gn_target_cnt    NUMBER; -- 対象件数
  gn_normal_cnt    NUMBER; -- 正常件数
  gn_error_cnt     NUMBER; -- エラー件数
  gn_warn_cnt      NUMBER; -- スキップ件数
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO020A03C';  -- パッケージ名
  cv_sales_appl_short_name CONSTANT VARCHAR2(5)   := 'XXCSO';         -- 営業用アプリケーション短縮名
  cv_com_appl_short_name   CONSTANT VARCHAR2(5)   := 'XXCCP';         -- 共通用アプリケーション短縮名
  cv_proc_type_create      CONSTANT VARCHAR2(1)   := 'C';             -- 登録処理
  cv_proc_type_update      CONSTANT VARCHAR2(1)   := 'U';             -- 更新処理
  cv_proc_type_outside     CONSTANT VARCHAR2(1)   := 'O';             -- 処理対象外
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';
  cn_number_one            CONSTANT NUMBER        := 1;
  cv_customer_status       CONSTANT VARCHAR2(2)   := '25';            -- 顧客ステータス
  cv_customer_class_code   CONSTANT VARCHAR2(2)   := '10';            -- 顧客区分
  --
  -- メッセージコード
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382'; -- 入力パラメータチェックエラー
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014'; -- プロファイル取得エラー
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00323'; -- データ存在エラー
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00324'; -- データ抽出時例外エラー
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00387'; -- ＳＰ専決顧客情報不整合エラー
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00388'; -- 顧客マスタ登録時エラー
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00389'; -- 顧客マスタ更新時エラー
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00383'; -- シーケンス取得エラー
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042'; -- ＤＢ登録・更新エラー
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00386'; -- ロック失敗エラー
  --
  -- トークンコード
  cv_tkn_errmsg   CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_prof_nm  CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_item     CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_key      CONSTANT VARCHAR2(20) := 'KEY';
  cv_tkn_err_msg  CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_api_name CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg  CONSTANT VARCHAR2(20) := 'API_MSG';
  cv_tkn_sequence CONSTANT VARCHAR2(20) := 'SEQUENCE';
  cv_tkn_action   CONSTANT VARCHAR2(20) := 'ACTION';
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- マスタ登録情報用構造体
  TYPE g_mst_regist_info_rtype IS RECORD(
    -- ＳＰ専決ヘッダ情報
     application_code xxcso_sp_decision_headers.application_code%TYPE -- 申請者コード
    ,app_base_code    xxcso_sp_decision_headers.app_base_code%TYPE    -- 申請拠点コード
    -- ＳＰ専決顧客情報
    ,customer_id                  xxcso_sp_decision_custs.customer_id%TYPE                  -- 顧客ＩＤ
    ,party_name                   xxcso_sp_decision_custs.party_name%TYPE                   -- 顧客名
    ,party_name_alt               xxcso_sp_decision_custs.party_name_alt%TYPE               -- 顧客名カナ
    ,employee_number              xxcso_sp_decision_custs.employee_number%TYPE              -- 社員数
    ,representative_name          xxcso_sp_decision_custs.representative_name%TYPE          -- 代表者名
    ,postal_code                  xxcso_sp_decision_custs.postal_code%TYPE                  -- 郵便番号
    ,state                        xxcso_sp_decision_custs.state%TYPE                        -- 都道府県
    ,city                         xxcso_sp_decision_custs.city%TYPE                         -- 市・区
    ,address1                     xxcso_sp_decision_custs.address1%TYPE                     -- 住所１
    ,address2                     xxcso_sp_decision_custs.address2%TYPE                     -- 住所２
    ,address_lines_phonetic       xxcso_sp_decision_custs.address_lines_phonetic%TYPE       -- 電話番号
    ,business_condition_type      xxcso_sp_decision_custs.business_condition_type%TYPE      -- 業態（小分類）
    ,business_type                xxcso_sp_decision_custs.business_type%TYPE                -- 業種
    ,publish_base_code            xxcso_sp_decision_custs.publish_base_code%TYPE            -- 担当拠点コード
    ,install_name                 xxcso_sp_decision_custs.install_name%TYPE                 -- 設置先名
    ,install_location             xxcso_sp_decision_custs.install_location%TYPE             -- 設置ロケーション
    ,external_reference_opcl_type xxcso_sp_decision_custs.external_reference_opcl_type%TYPE -- 物件オープン・クローズ区分
    ,new_customer_flag            xxcso_sp_decision_custs.new_customer_flag%TYPE            -- 新規顧客フラグ
  );
  --
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,ot_mst_regist_info_rec   OUT NOCOPY g_mst_regist_info_rtype                              -- マスタ登録情報
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_proc'; -- プロシージャ名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_nm_sp_decision_header_id CONSTANT VARCHAR2(30)                          := 'ＳＰ専決ヘッダＩＤ';        -- ＳＰ専決ヘッダＩＤ和名
    ct_lookup_type_cust_status  CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'XXCMM_CUST_KOKYAKU_STATUS'; -- 顧客ステータス
    ct_lookup_type_cust_type    CONSTANT fnd_lookup_values_vl.lookup_type%TYPE := 'CUSTOMER CLASS';            -- 顧客区分
    cv_msg_const1               CONSTANT VARCHAR2(100)                         := 'タイプ：';
    cv_msg_const2               CONSTANT VARCHAR2(100)                         := '、コード：';
    cv_nm_table                 CONSTANT VARCHAR2(100)                         := 'クイックコードビュー';
    --
    -- プロファイルオプション名
    cv_profile_option_name1 CONSTANT VARCHAR2(40) := 'XXCSO1_CUST_STATUS_SP_DECISION';
    cv_profile_option_name2 CONSTANT VARCHAR2(40) := 'XXCSO1_CUST_TYPE_CUSTOMER';
    --
    -- *** ローカル変数 ***
    lt_cust_status_profile fnd_profile_option_values.profile_option_value%TYPE; -- プロファイルオプション値（顧客ステータス）
    lt_cust_type_profile   fnd_profile_option_values.profile_option_value%TYPE; -- プロファイルオプション値（顧客区分）
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    ot_mst_regist_info_rec := NULL;
    --
    -- ======================
    -- 入力パラメータチェック
    -- ======================
    IF (it_sp_decision_header_id IS NULL) THEN
      -- ＳＰ専決ヘッダＩＤが未入力の場合エラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                 -- トークコード1
                     ,iv_token_value1 => cv_nm_sp_decision_header_id -- トークン値1
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END start_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_install_at_info
   * Description      :  設置先情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_install_at_info(
     it_sp_decision_header_id IN            xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,iot_mst_regist_info_rec  IN OUT NOCOPY g_mst_regist_info_rtype                              -- マスタ登録情報
    ,ov_proc_type             OUT    NOCOPY VARCHAR2                                             -- 処理区分
    ,ov_errbuf                OUT    NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT    NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT    NOCOPY VARCHAR2                                             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_install_at_info'; -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_tkn_value_sp_dec_head    CONSTANT VARCHAR2(30) := 'ＳＰ専決ヘッダテーブル';         -- ＳＰ専決ヘッダテーブル和名
    cv_tkn_value_sp_dec_custs   CONSTANT VARCHAR2(30) := 'ＳＰ専決顧客テーブル（設置先）'; -- ＳＰ専決顧客テーブル和名
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(30) := 'ＳＰ専決ヘッダＩＤ';             -- ＳＰ専決ヘッダＩＤ和名
    --
    ct_sp_dec_cust_class_install CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1'; -- ＳＰ専決顧客区分=設置先
    --
    -- *** ローカル変数 ***
    lv_proc_type VARCHAR2(1); -- 処理区分
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ==============
    -- 変数初期化処理
    -- ==============
    lv_proc_type := NULL;
    --
    -- ============================
    -- 設置先情報（ヘッダ）取得処理
    -- ============================
    BEGIN
      SELECT xsd.application_code application_code -- 申請者コード
            ,xsd.app_base_code    app_base_code    -- 申請拠点コード
      INTO   iot_mst_regist_info_rec.application_code
            ,iot_mst_regist_info_rec.app_base_code
      FROM   xxcso_sp_decision_headers xsd -- ＳＰ専決ヘッダテーブル
      WHERE  xsd.sp_decision_header_id = it_sp_decision_header_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head_id ||
                                           cv_msg_part                 ||
                                           it_sp_decision_header_id  -- トークン値1
                       ,iv_token_name2  => cv_tkn_table              -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_head  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head -- トークン値1
                       ,iv_token_name2  => cv_tkn_key               -- トークンコード2
                       ,iv_token_value2 => it_sp_decision_header_id -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                       ,iv_token_value3 => SQLERRM                  -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ==========================
    -- 設置先情報（顧客）取得処理
    -- ==========================
    BEGIN
      SELECT xsd.customer_id                  customer_id                  -- 顧客ＩＤ
            ,xsd.party_name                   party_name                   -- 顧客名
            ,xsd.party_name_alt               party_name_alt               -- 顧客名カナ
            ,xsd.employee_number              employee_number              -- 社員数
            ,xsd.postal_code                  postal_code                  -- 郵便番号
            ,xsd.state                        state                        -- 都道府県
            ,xsd.city                         city                         -- 市・区
            ,xsd.address1                     address1                     -- 住所１
            ,xsd.address2                     address2                     -- 住所２
            ,xsd.address_lines_phonetic       address_lines_phonetic       -- 電話番号
            ,xsd.business_condition_type      business_condition_type      -- 業態（小分類）
            ,xsd.business_type                business_type                -- 業種
            ,xsd.publish_base_code            publish_base_code            -- 担当拠点コード
            ,xsd.install_name                 install_name                 -- 設置先名
            ,xsd.install_location             install_location             -- 設置ロケーション
            ,xsd.external_reference_opcl_type external_reference_opcl_type -- 物件オープン・クローズ区分
            ,xsd.new_customer_flag            new_customer_flag            -- 新規顧客フラグ
      INTO   iot_mst_regist_info_rec.customer_id
            ,iot_mst_regist_info_rec.party_name
            ,iot_mst_regist_info_rec.party_name_alt
            ,iot_mst_regist_info_rec.employee_number
            ,iot_mst_regist_info_rec.postal_code
            ,iot_mst_regist_info_rec.state
            ,iot_mst_regist_info_rec.city
            ,iot_mst_regist_info_rec.address1
            ,iot_mst_regist_info_rec.address2
            ,iot_mst_regist_info_rec.address_lines_phonetic
            ,iot_mst_regist_info_rec.business_condition_type
            ,iot_mst_regist_info_rec.business_type
            ,iot_mst_regist_info_rec.publish_base_code
            ,iot_mst_regist_info_rec.install_name
            ,iot_mst_regist_info_rec.install_location
            ,iot_mst_regist_info_rec.external_reference_opcl_type
            ,iot_mst_regist_info_rec.new_customer_flag
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
      WHERE  xsd.sp_decision_header_id      = it_sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_install
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head_id ||
                                           cv_msg_part                 ||
                                           it_sp_decision_header_id  -- トークン値1
                       ,iv_token_name2  => cv_tkn_table              -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_custs -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_custs -- トークン値1
                       ,iv_token_name2  => cv_tkn_key                -- トークンコード2
                       ,iv_token_value2 => it_sp_decision_header_id  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg            -- トークンコード3
                       ,iv_token_value3 => SQLERRM                   -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    -- ============
    -- 処理方法判定
    -- ============
    IF (iot_mst_regist_info_rec.customer_id IS NULL) THEN
      -- 顧客ＩＤがNULLの場合
      IF (iot_mst_regist_info_rec.new_customer_flag = cv_flag_yes) THEN
        -- 新規顧客フラグがYの場合
        lv_proc_type := cv_proc_type_create;
        --
      ELSE
        -- 新規顧客フラグがY以外の場合はエラー
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_key               -- トークンコード1
                       ,iv_token_value1 => it_sp_decision_header_id -- トークン値1
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    ELSIF (iot_mst_regist_info_rec.customer_id IS NOT NULL) THEN
      -- 顧客ＩＤがNOT NULLの場合
      IF (iot_mst_regist_info_rec.new_customer_flag = cv_flag_yes) THEN
        -- 新規顧客フラグがYの場合
        lv_proc_type := cv_proc_type_update;
        --
      ELSE
        -- 新規顧客フラグがY以外の場合
        lv_proc_type := cv_proc_type_outside;
        --
      END IF;
      --
    END IF;
    --
    ov_proc_type := lv_proc_type;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_install_at_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_party
   * Description      : パーティマスタ登録更新(A-3)
   ***********************************************************************************/
  PROCEDURE regist_party(
     iv_proc_type           IN         VARCHAR2                 -- 処理区分
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype  -- マスタ登録情報
    ,ot_party_id            OUT NOCOPY hz_parties.party_id%TYPE -- パーティＩＤ
    ,ov_errbuf              OUT NOCOPY VARCHAR2                 -- エラー・メッセージ --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                 -- リターン・コード   --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                 -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_party'; -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- トークン用定数
    cv_tkn_item_name          CONSTANT VARCHAR2(30) := '設置先ＩＤ：';
    cv_tkn_table_name         CONSTANT VARCHAR2(30) := 'パーティマスタ';
    cv_tkn_value_party_create CONSTANT VARCHAR2(30) := 'パーティマスタ登録';
    cv_tkn_value_party_update CONSTANT VARCHAR2(30) := 'パーティマスタ更新';
    --
    -- *** ローカル変数 ***
    -- パーティマスタ登録ＡＰＩ用変数
    lt_organization_rec      hz_party_v2pub.organization_rec_type;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_party_id              hz_parties.party_id%TYPE;
    lt_party_number          hz_parties.party_number%TYPE;
    lt_profile_id            hz_organization_profiles.organization_profile_id%TYPE;
    lt_object_version_number hz_parties.object_version_number%TYPE;
    --
    -- *** ローカル例外 ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- 処理区分がCの場合
      -- ==================
      -- パーティマスタ新規
      -- ==================
      lt_organization_rec.organization_name          := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 360);               -- 顧客名
      lt_organization_rec.organization_name_phonetic := SUBSTRB(it_mst_regist_info_rec.party_name_alt, 1, 320);           -- 顧客名カナ
      lt_organization_rec.duns_number_c              := SUBSTRB(cv_customer_status, 1, 30);                               -- 顧客ステータス
      lt_organization_rec.created_by_module          := SUBSTRB(cv_pkg_name, 1, 150);
      lt_organization_rec.party_rec.attribute2       := SUBSTRB(TO_CHAR(it_mst_regist_info_rec.employee_number), 1, 150); -- 社員数
      --
      hz_party_v2pub.create_organization(
         p_init_msg_list    => fnd_api.g_true
        ,p_organization_rec => lt_organization_rec
        ,x_return_status    => lv_return_status
        ,x_msg_count        => ln_msg_count
        ,x_msg_data         => lv_msg_data
        ,x_party_id         => lt_party_id
        ,x_party_number     => lt_party_number
        ,x_profile_id       => lt_profile_id
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name           -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_party_create -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg            -- トークンコード2
                       ,iv_token_value2 => lv_msg_data               -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    ELSIF (iv_proc_type = cv_proc_type_update) THEN
      -- 処理区分がUの場合
      -- ==================
      -- パーティマスタ更新
      -- ==================
      -- パーティ情報取得
      BEGIN
        SELECT hpa.party_id              party_id              -- パーティＩＤ
              ,hpa.object_version_number object_version_number -- オブジェクトバージョン番号
        INTO   lt_party_id
              ,lt_object_version_number
        FROM   hz_parties       hpa -- パーティマスタ
              ,hz_cust_accounts hca -- 顧客マスタ
        WHERE  hpa.party_id        = hca.party_id
        AND    hca.cust_account_id = it_mst_regist_info_rec.customer_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03                   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item                        -- トークンコード1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             it_mst_regist_info_rec.customer_id -- トークン値1
                         ,iv_token_name2  => cv_tkn_table                       -- トークンコード2
                         ,iv_token_value2 => cv_tkn_table_name                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04                   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                       -- トークンコード1
                         ,iv_token_value1 => cv_tkn_table_name                  -- トークン値1
                         ,iv_token_name2  => cv_tkn_key                         -- トークンコード2
                         ,iv_token_value2 => it_mst_regist_info_rec.customer_id -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード3
                         ,iv_token_value3 => SQLERRM                            -- トークン値3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_organization_rec.organization_name          := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 360);               -- 顧客名
      lt_organization_rec.organization_name_phonetic := SUBSTRB(it_mst_regist_info_rec.party_name_alt, 1, 320);           -- 顧客名カナ
      lt_organization_rec.duns_number_c              := SUBSTRB(cv_customer_status, 1, 30);                               -- 顧客ステータス
      lt_organization_rec.party_rec.attribute2       := SUBSTRB(TO_CHAR(it_mst_regist_info_rec.employee_number), 1, 150); -- 社員数
      lt_organization_rec.party_rec.party_id         := lt_party_id;                                                      -- パーティＩＤ
      --
      hz_party_v2pub.update_organization(
         p_init_msg_list               => fnd_api.g_true
        ,p_organization_rec            => lt_organization_rec
        ,p_party_object_version_number => lt_object_version_number
        ,x_profile_id                  => lt_profile_id
        ,x_return_status               => lv_return_status
        ,x_msg_count                   => ln_msg_count
        ,x_msg_data                    => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name           -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_party_update -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg            -- トークンコード2
                       ,iv_token_value2 => lv_msg_data               -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
    ot_party_id := lt_party_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
     -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_party;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_locat_party_site
   * Description      : 顧客事業所／パーティサイトマスタ登録更新(A-4)
   ***********************************************************************************/
  PROCEDURE regist_locat_party_site(
     iv_proc_type           IN         VARCHAR2                          -- 処理区分
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype           -- マスタ登録情報
    ,it_party_id            IN         hz_parties.party_id%TYPE          -- パーティＩＤ
    ,ot_party_site_id       OUT NOCOPY hz_party_sites.party_site_id%TYPE -- パーティサイトＩＤ
    ,ov_errbuf              OUT NOCOPY VARCHAR2                          -- エラー・メッセージ --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                          -- リターン・コード   --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_locat_party_site'; -- プロシージャ名
    --
    --#######################  固定ローカル変数宣言部 START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode VARCHAR2(1);    -- リターン・コード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    cv_territory_short_name        CONSTANT VARCHAR2(40) := '日本';
    cv_tkn_value_item              CONSTANT VARCHAR2(40) := '国コード：日本';
    cv_tkn_value_table_name        CONSTANT VARCHAR2(40) := 'テリトリビュー';
    cv_tkn_value_location_create   CONSTANT VARCHAR2(40) := '顧客事業所マスタ登録';
    cv_tkn_value_location_update   CONSTANT VARCHAR2(40) := '顧客事業所マスタ更新';
    cv_tkn_value_party_site_create CONSTANT VARCHAR2(40) := 'パーティサイトマスタ登録';
    cv_tkn_item_name               CONSTANT VARCHAR2(40) := '設置先ＩＤ：';
    cv_tkn_table_name              CONSTANT VARCHAR2(40) := 'パーティサイト／顧客事業所マスタ';
    --
    -- *** ローカル変数 ***
    -- 顧客事業所マスタ登録ＡＰＩ用変数
    lt_location_rec          hz_location_v2pub.location_rec_type;
    lt_location_id           hz_locations.location_id%TYPE;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_object_version_number hz_locations.object_version_number%TYPE;
    --
    -- パーティサイトマスタ登録ＡＰＩ用変数
    lt_party_site_rec    hz_party_site_v2pub.party_site_rec_type;
    lt_party_site_id     hz_party_sites.party_site_id%TYPE;
    lt_party_site_number hz_party_sites.party_site_number%TYPE;
    --
    lt_territory_code fnd_territories_vl.territory_code%TYPE;
    --
    -- *** ローカル例外 ***
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- 国コード取得
    BEGIN
      SELECT ftv.territory_code territory_code -- テリトリーコード
      INTO   lt_territory_code
      FROM   fnd_territories_vl ftv -- テリトリビュー
      WHERE  ftv.territory_short_name = cv_territory_short_name
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_item        -- トークン値1
                       ,iv_token_name2  => cv_tkn_table             -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_table_name  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- その他のエラーの場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_table_name  -- トークン値1
                       ,iv_token_name2  => cv_tkn_key               -- トークンコード2
                       ,iv_token_value2 => cv_territory_short_name  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                       ,iv_token_value3 => SQLERRM                  -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- 処理区分がCの場合
      -- ====================
      -- 顧客事業所マスタ新規
      -- ====================
      lt_location_rec.country                := SUBSTRB(lt_territory_code, 1, 60);                              -- 国コード
      lt_location_rec.postal_code            := SUBSTRB(it_mst_regist_info_rec.postal_code, 1, 60);             -- 郵便番号
      lt_location_rec.state                  := SUBSTRB(it_mst_regist_info_rec.state, 1, 60);                   -- 都道府県
      lt_location_rec.city                   := SUBSTRB(it_mst_regist_info_rec.city, 1, 60);                    -- 市・区
      lt_location_rec.address1               := SUBSTRB(it_mst_regist_info_rec.address1, 1, 240);               -- 住所１
      lt_location_rec.address2               := SUBSTRB(it_mst_regist_info_rec.address2, 1, 240);               -- 住所２
      lt_location_rec.address_lines_phonetic := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, 1, 560); -- 電話番号
      lt_location_rec.created_by_module      := SUBSTRB(cv_pkg_name, 1, 150);
     --
      hz_location_v2pub.create_location(
         p_init_msg_list => fnd_api.g_true
        ,p_location_rec  => lt_location_rec
        ,x_location_id   => lt_location_id
        ,x_return_status => lv_return_status
        ,x_msg_count     => ln_msg_count
        ,x_msg_data      => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name     -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_location_create -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg               -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      -- ========================
      -- パーティサイトマスタ新規
      -- ========================
      lt_party_site_rec.party_id          := it_party_id;    -- パーティＩＤ
      lt_party_site_rec.location_id       := lt_location_id; -- 顧客事業所ＩＤ
      lt_party_site_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_party_site_v2pub.create_party_site(
         p_init_msg_list     => fnd_api.g_true
        ,p_party_site_rec    => lt_party_site_rec
        ,x_party_site_id     => lt_party_site_id
        ,x_party_site_number => lt_party_site_number
        ,x_return_status     => lv_return_status
        ,x_msg_count         => ln_msg_count
        ,x_msg_data          => lv_msg_data
       );
       --
       IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name       -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name                -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_party_site_create -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg                 -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                    -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      ot_party_site_id := lt_party_site_id;
      --
    ELSIF (iv_proc_type = cv_proc_type_update) THEN
      -- 処理区分がUの場合
      -- ====================
      -- 顧客事業所マスタ更新
      -- ====================
      -- 顧客事業所情報取得
      BEGIN
        SELECT hlo.location_id           location_id           -- 事業所ＩＤ
              ,hlo.object_version_number object_version_number -- オブジェクトバージョン番号
        INTO   lt_location_id
              ,lt_object_version_number
        FROM   hz_locations   hlo -- 顧客事業所マスタ
              /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
              ,hz_cust_accounts   hca  -- 顧客マスタ
              ,hz_cust_acct_sites hcas -- 顧客サイトマスタ
              /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
              ,hz_party_sites hps -- パーティサイトマスタ
        /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
        --WHERE  hps.party_id    = it_party_id
        WHERE  hca.party_id        = it_party_id
        AND    hca.cust_account_id = hcas.cust_account_id
        AND    hcas.party_site_id  = hps.party_site_id
        /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
        AND    hps.location_id = hlo.location_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03                   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item                        -- トークンコード1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             it_mst_regist_info_rec.customer_id -- トークン値1
                         ,iv_token_name2  => cv_tkn_table                       -- トークンコード2
                         ,iv_token_value2 => cv_tkn_table_name                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04                   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                       -- トークンコード1
                         ,iv_token_value1 => cv_tkn_table_name                  -- トークン値1
                         ,iv_token_name2  => cv_tkn_key                         -- トークンコード2
                         ,iv_token_value2 => it_mst_regist_info_rec.customer_id -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード3
                         ,iv_token_value3 => SQLERRM                            -- トークン値3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_location_rec.location_id            := lt_location_id;                                                 -- 顧客事業所ＩＤ
      lt_location_rec.country                := SUBSTRB(lt_territory_code, 1, 60);                              -- 国コード
      lt_location_rec.postal_code            := SUBSTRB(it_mst_regist_info_rec.postal_code, 1, 60);             -- 郵便番号
      lt_location_rec.state                  := SUBSTRB(it_mst_regist_info_rec.state, 1, 60);                   -- 都道府県
      lt_location_rec.city                   := SUBSTRB(it_mst_regist_info_rec.city, 1, 60);                    -- 市・区
      lt_location_rec.address1               := SUBSTRB(it_mst_regist_info_rec.address1, 1, 240);               -- 住所１
      lt_location_rec.address2               := SUBSTRB(it_mst_regist_info_rec.address2, 1, 240);               -- 住所２
      lt_location_rec.address_lines_phonetic := SUBSTRB(it_mst_regist_info_rec.address_lines_phonetic, 1, 560); -- 電話番号
      --
      hz_location_v2pub.update_location(
         p_init_msg_list         => fnd_api.g_true
        ,p_location_rec          => lt_location_rec
        ,p_object_version_number => lt_object_version_number
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name     -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_location_update -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg               -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                  -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_locat_party_site;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_cust_account
   * Description      : 顧客マスタ登録更新(A-5)
   ***********************************************************************************/
  PROCEDURE regist_cust_account(
     iv_proc_type           IN         VARCHAR2                              -- 処理区分
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype               -- マスタ登録情報
    ,it_party_id            IN         hz_parties.party_id%TYPE              -- パーティＩＤ
    ,ot_cust_account_id     OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE -- 顧客ＩＤ
    ,ot_account_number      OUT NOCOPY hz_cust_accounts.account_number%TYPE  -- 顧客番号
    ,ov_errbuf              OUT NOCOPY VARCHAR2                              -- エラー・メッセージ --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                              -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                            -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_cust_account';  -- プログラム名
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
    -- トークン用定数
    cv_tkn_value_sequence       CONSTANT VARCHAR2(30) := '顧客番号シーケンス';
    cv_tkn_value_account_create CONSTANT VARCHAR2(30) := '顧客マスタ登録';
    cv_tkn_value_account_update CONSTANT VARCHAR2(30) := '顧客マスタ更新';
    cv_tkn_item_name            CONSTANT VARCHAR2(30) := '設置先ＩＤ：';
    cv_tkn_table_name           CONSTANT VARCHAR2(30) := '顧客マスタ';
    --
    -- *** ローカル変数 ***
    -- 顧客マスタ用ＡＰＩ変数
    lt_cust_account_rec      hz_cust_account_v2pub.cust_account_rec_type;
    lt_organization_rec      hz_party_v2pub.organization_rec_type;
    lt_customer_profile_rec  hz_customer_profile_v2pub.customer_profile_rec_type;
    lt_create_profile_amt    VARCHAR2(1);
    lt_cust_account_id       hz_cust_accounts.cust_account_id%TYPE;
    lt_account_number        hz_cust_accounts.account_number%TYPE;
    lt_party_id              hz_parties.party_id%TYPE;
    lt_party_number          hz_parties.party_number%TYPE;
    lt_profile_id            hz_organization_profiles.organization_profile_id%TYPE;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    lt_object_version_number hz_cust_accounts.object_version_number%TYPE;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- 処理区分がCの場合
      -- ====================
      -- 顧客事業所マスタ新規
      -- ====================
      /* 2009.04.21 K.Satomura T1_0685対応 START */
      ---- 顧客番号の取得
      --BEGIN
      --  SELECT hz_cust_accounts_s1.NEXTVAL account_number
      --  INTO   ot_account_number
      --  FROM   DUAL
      --  ;
      --  --
      --EXCEPTION
      --  WHEN OTHERS THEN
      --    -- その他のエラーの場合 
      --    lv_errbuf := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
      --                   ,iv_name         => cv_tkn_number_08         -- メッセージコード
      --                   ,iv_token_name1  => cv_tkn_sequence          -- トークンコード1
      --                   ,iv_token_value1 => cv_tkn_value_sequence    -- トークン値1
      --                   ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード2
      --                   ,iv_token_value2 => SQLERRM                  -- トークン値2
      --                );
      --    --
      --    RAISE global_api_expt;
      --    --
      --END;
      ----
      --lt_cust_account_rec.account_number      := SUBSTRB(ot_account_number, 1, 30);                  -- 顧客番号
      /* 2009.04.21 K.Satomura T1_0685対応 END */
      lt_cust_account_rec.account_name        := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 240); -- アカウント名
      lt_cust_account_rec.customer_class_code := SUBSTRB(cv_customer_class_code, 1, 30);             -- 顧客区分
      lt_organization_rec.party_rec.party_id  := it_party_id;                                        -- パーティＩＤ
      lt_cust_account_rec.created_by_module   := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_v2pub.create_cust_account(
         p_init_msg_list        => fnd_api.g_true
        ,p_cust_account_rec     => lt_cust_account_rec
        ,p_organization_rec     => lt_organization_rec
        ,p_customer_profile_rec => lt_customer_profile_rec
        ,p_create_profile_amt   => fnd_api.g_false
        ,x_cust_account_id      => lt_cust_account_id
        ,x_account_number       => lt_account_number
        ,x_party_id             => lt_party_id
        ,x_party_number         => lt_party_number
        ,x_profile_id           => lt_profile_id
        ,x_return_status        => lv_return_status
        ,x_msg_count            => ln_msg_count
        ,x_msg_data             => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_account_create -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg              -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                 -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      ot_cust_account_id := lt_cust_account_id;
      /* 2009.04.21 K.Satomura T1_0685対応 START */
      ot_account_number  := lt_account_number;
      /* 2009.04.21 K.Satomura T1_0685対応 END */
      --
    ELSIF (iv_proc_type = cv_proc_type_update) THEN
      -- 処理区分がUの場合
      -- ==============
      -- 顧客マスタ更新
      -- ==============
      -- 顧客マスタ情報取得
      BEGIN
        SELECT hca.account_number        account_number        -- 顧客番号
              ,hca.object_version_number object_version_number -- オブジェクトバージョン番号
        INTO   ot_account_number
              ,lt_object_version_number
        FROM   hz_cust_accounts hca -- 顧客マスタ
        WHERE  cust_account_id = it_mst_regist_info_rec.customer_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03                   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item                        -- トークンコード1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             it_mst_regist_info_rec.customer_id -- トークン値1
                         ,iv_token_name2  => cv_tkn_table                       -- トークンコード2
                         ,iv_token_value2 => cv_tkn_table_name                  -- トークン値2
                       );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04                   -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table                       -- トークンコード1
                         ,iv_token_value1 => cv_tkn_table_name                  -- トークン値1
                         ,iv_token_name2  => cv_tkn_key                         -- トークンコード2
                         ,iv_token_value2 => it_mst_regist_info_rec.customer_id -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード3
                         ,iv_token_value3 => SQLERRM                            -- トークン値3
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      lt_cust_account_rec.cust_account_id     := it_mst_regist_info_rec.customer_id;                 -- 顧客ＩＤ
      lt_cust_account_rec.account_name        := SUBSTRB(it_mst_regist_info_rec.party_name, 1, 240); -- アカウント名
      lt_cust_account_rec.customer_class_code := SUBSTRB(cv_customer_class_code, 1, 30);             -- 顧客区分
      --
      hz_cust_account_v2pub.update_cust_account(
         p_init_msg_list         => fnd_api.g_true
        ,p_cust_account_rec      => lt_cust_account_rec
        ,p_object_version_number => lt_object_version_number
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_account_update -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg              -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                 -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
      ot_cust_account_id := it_mst_regist_info_rec.customer_id;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_cust_account;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_cust_acct_site
   * Description      : 顧客所在地マスタ登録(A-6)
   ***********************************************************************************/
  PROCEDURE regist_cust_acct_site(
     iv_proc_type           IN         VARCHAR2                                      -- 処理区分
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype                       -- マスタ登録情報
    ,it_party_site_id       IN         hz_party_sites.party_site_id%TYPE             -- パーティサイトＩＤ
    ,it_cust_account_id     IN         hz_cust_accounts.cust_account_id%TYPE         -- 顧客ＩＤ
    ,ot_cust_acct_site_id   OUT NOCOPY hz_cust_acct_sites_all.cust_acct_site_id%TYPE -- 顧客所在地ＩＤ
    ,ov_errbuf              OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                                      -- リターン・コード   --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_cust_acct_site'; -- プロシージャ名
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
    -- トークン用定数
    cv_tkn_value_cust_acct_site CONSTANT VARCHAR2(30) := '顧客所在地マスタ登録';
    cv_tkn_item_name            CONSTANT VARCHAR2(30) := '設置先ＩＤ：';
    cv_tkn_table_name           CONSTANT VARCHAR2(30) := '顧客所在地マスタ';
   --
    -- *** ローカル変数 ***
    -- 顧客マスタ用ＡＰＩ変数
    lt_cust_acct_site_rec hz_cust_account_site_v2pub.cust_acct_site_rec_type;
    lt_cust_acct_site_id  hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    lv_return_status      VARCHAR2(1);
    ln_msg_count          NUMBER;
    lv_msg_data           VARCHAR2(5000);
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    IF (iv_proc_type = cv_proc_type_create) THEN
      -- 処理区分がCの場合
      -- ====================
      -- 顧客所在地マスタ新規
      -- ====================
      lt_cust_acct_site_rec.party_site_id     := it_party_site_id;   -- パーティサイトＩＤ
      lt_cust_acct_site_rec.cust_account_id   := it_cust_account_id; -- 顧客ＩＤ
      lt_cust_acct_site_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_site_v2pub.create_cust_acct_site(
         p_init_msg_list      => fnd_api.g_true
        ,p_cust_acct_site_rec => lt_cust_acct_site_rec
        ,x_cust_acct_site_id  => lt_cust_acct_site_id
        ,x_return_status      => lv_return_status
        ,x_msg_count          => ln_msg_count
        ,x_msg_data           => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06            -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_cust_acct_site -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg              -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                 -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    ELSE
      -- 処理区分がC以外の場合
      BEGIN
        SELECT hca.cust_acct_site_id cust_acct_site_id -- 顧客所在地ＩＤ
        INTO   lt_cust_acct_site_id
        FROM   hz_cust_acct_sites hca -- 顧客所在地マスタビュー
        WHERE  cust_account_id = it_cust_account_id
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             cv_msg_part      ||
                                             it_cust_account_id       -- トークン値1
                         ,iv_token_name2  => cv_tkn_table             -- トークンコード2
                         ,iv_token_value2 => cv_tkn_table_name        -- トークン値2
                       );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                         ,iv_token_value1 => cv_tkn_table_name        -- トークン値1
                         ,iv_token_name2  => cv_tkn_key               -- トークンコード2
                         ,iv_token_value2 => it_cust_account_id       -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                         ,iv_token_value3 => SQLERRM                  -- トークン値3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
    ot_cust_acct_site_id := lt_cust_acct_site_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_cust_acct_site;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_cust_site_use
   * Description      : 顧客使用目的マスタ登録(A-7)
   ***********************************************************************************/
  PROCEDURE regist_cust_site_use(
     iv_proc_type           IN         VARCHAR2                                      -- 処理区分
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype                       -- マスタ登録情報
    ,it_cust_acct_site_id   IN         hz_cust_acct_sites_all.cust_acct_site_id%TYPE -- 顧客所在地ＩＤ
    ,ov_errbuf              OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                                      -- リターン・コード   --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_cust_site_use';  -- プロシージャ名
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
    cv_ship_to_site_code CONSTANT VARCHAR2(30) := 'SHIP_TO';
    cv_bill_to_site_code CONSTANT VARCHAR2(30) := 'BILL_TO';
    /* 2009.05.08 K.Satomura T1_0913対応 START */
    cv_payment_name_promptly  CONSTANT VARCHAR2(8)  := '00_00_00';
    /* 2009.05.21 K.Satomura T1_1092対応 START */
    --cv_tkn_value_payment_term CONSTANT VARCHAR2(50) := '00_00_00（即時払い）';
    cv_tkn_value_payment_term CONSTANT VARCHAR2(50) := '支払条件：00_00_00（即時払い）';
    cv_tkn_item_name          CONSTANT VARCHAR2(50) := 'アカウントサイトＩＤ';
    cv_tkn_table_name_use     CONSTANT VARCHAR2(50) := '顧客使用目的マスタ';
    cv_business_cond_fv       CONSTANT VARCHAR2(50) := '25'; -- 業態（小分類）= フルサービスＶＤ
    /* 2009.05.21 K.Satomura T1_1092対応 END */
    cv_tkn_value_table_name   CONSTANT VARCHAR2(50) := '支払条件ビュー';
    /* 2009.05.08 K.Satomura T1_0913対応 END */
    /* 2009.07.09 K.Satomura 統合テスト障害対応(0000341) START */
    cv_tax_rouding_rule       CONSTANT hz_cust_site_uses_all.tax_rounding_rule%TYPE := 'DOWN';
    --
    /* 2009.07.09 K.Satomura 統合テスト障害対応(0000341) END */

    --
    -- トークン用定数
    cv_tkn_value_site_use_ship CONSTANT VARCHAR2(40) := '顧客使用目的マスタ登録（出荷先）';
    cv_tkn_value_site_use_bill CONSTANT VARCHAR2(40) := '顧客使用目的マスタ登録（請求先）';
    /* 2009.05.21 K.Satomura T1_1092対応 START */
    cv_tkn_value_use_bill_upd  CONSTANT VARCHAR2(40) := '顧客使用目的マスタ更新（請求先）';
    /* 2009.05.21 K.Satomura T1_1092対応 END */
    /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
    cv_active                  CONSTANT VARCHAR2(1)  := 'A'; -- 顧客使用目的マスタ ステータス
    /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
    --
    -- *** ローカル変数 ***
    -- 顧客使用目的用ＡＰＩ変数
    lt_cust_site_use_rec    hz_cust_account_site_v2pub.cust_site_use_rec_type;
    lt_customer_profile_rec hz_customer_profile_v2pub.customer_profile_rec_type;
    lt_site_use_id          hz_cust_site_uses_all.site_use_id%TYPE;
    lv_return_status        VARCHAR2(1);
    ln_msg_count            NUMBER;
    lv_msg_data             VARCHAR2(5000);
    /* 2009.05.08 K.Satomura T1_0913対応 START */
    ln_object_version_number NUMBER;
    /* 2009.05.08 K.Satomura T1_0913対応 END */
    --
    ln_count NUMBER;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- 顧客使用目的(SHIP_TO)の存在チェック
    IF (iv_proc_type = cv_proc_type_update) THEN
      -- 処理区分がUの場合
      SELECT COUNT(1)
      INTO   ln_count
      FROM   hz_cust_site_uses  hcs -- 顧客使用目的マスタビュー
      /* 2009.05.21 K.Satomura T1_1092対応 START */
            --,hz_cust_acct_sites hca -- 顧客所在地マスタビュー
      --WHERE  hca.cust_account_id   = it_mst_regist_info_rec.customer_id
      --AND    hca.cust_acct_site_id = hcs.cust_acct_site_id
      WHERE  hcs.cust_acct_site_id = it_cust_acct_site_id
      /* 2009.05.21 K.Satomura T1_1092対応 END */
      AND    hcs.site_use_code     = cv_ship_to_site_code
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
      AND    hcs.status            = cv_active
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
      ;
      --
    END IF;
    --
    IF ((iv_proc_type = cv_proc_type_create)
      OR ((ln_count <= 0)
      AND (iv_proc_type = cv_proc_type_update)))
    THEN
      -- 処理区分がC又は、顧客使用目的(SHIP_TO)が存在しない場合の場合
      -- ===============================
      -- 顧客使用目的(SHIP_TO)マスタ新規
      -- ===============================
      -- 出荷先の登録
      lt_cust_site_use_rec.cust_acct_site_id := it_cust_acct_site_id; -- 顧客所在地ＩＤ
      lt_cust_site_use_rec.site_use_code     := cv_ship_to_site_code; -- 使用目的
      lt_cust_site_use_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      --
      hz_cust_account_site_v2pub.create_cust_site_use(
         p_init_msg_list        => fnd_api.g_true
        ,p_cust_site_use_rec    => lt_cust_site_use_rec
        ,p_customer_profile_rec => lt_customer_profile_rec
        ,p_create_profile       => fnd_api.g_false
        ,p_create_profile_amt   => fnd_api.g_false
        ,x_site_use_id          => lt_site_use_id
        ,x_return_status        => lv_return_status
        ,x_msg_count            => ln_msg_count
        ,x_msg_data             => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_site_use_ship -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg             -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    END IF;
    --
    -- 顧客使用目的(BILL_TO)の存在チェック
    IF (iv_proc_type = cv_proc_type_update) THEN
      -- 処理区分がUの場合
      SELECT COUNT(1)
      INTO   ln_count
      FROM   hz_cust_site_uses  hcs -- 顧客使用目的マスタビュー
      /* 2009.05.21 K.Satomura T1_1092対応 START */
            --,hz_cust_acct_sites hca -- 顧客所在地マスタビュー
      --WHERE  hca.cust_account_id   = it_mst_regist_info_rec.customer_id
      --AND    hca.cust_acct_site_id = hcs.cust_acct_site_id
      WHERE  hcs.cust_acct_site_id = it_cust_acct_site_id
      /* 2009.05.21 K.Satomura T1_1092対応 END */
      AND    hcs.site_use_code     = cv_bill_to_site_code
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
      AND    hcs.status            = cv_active
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
      ;
      --
    END IF;
    --
    /* 2009.05.21 K.Satomura T1_1092対応 START */
    IF (it_mst_regist_info_rec.business_condition_type = cv_business_cond_fv) THEN
      -- 支払条件ＩＤの取得
      BEGIN
        SELECT rtv.term_id
        INTO   lt_cust_site_use_rec.payment_term_id
        FROM   ra_terms_vl rtv
        WHERE  rtv.name = cv_payment_name_promptly
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03          -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item               -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_payment_term -- トークン値1
                         ,iv_token_name2  => cv_tkn_table              -- トークンコード2
                         ,iv_token_value2 => cv_tkn_value_table_name   -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- その他の例外の場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04          -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_table_name   -- トークン値1
                         ,iv_token_name2  => cv_tkn_key                -- トークンコード2
                         ,iv_token_value2 => cv_tkn_value_payment_term -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg            -- トークンコード3
                         ,iv_token_value3 => SQLERRM                   -- トークン値3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
    /* 2009.05.21 K.Satomura T1_1092対応 END */
    IF ((iv_proc_type = cv_proc_type_create)
      OR ((ln_count <= 0)
      AND (iv_proc_type = cv_proc_type_update)))
    THEN
      -- 処理区分がC又は、顧客使用目的(BILL_TO)が存在しない場合の場合
      -- ===============================
      -- 顧客使用目的(BILL_TO)マスタ新規
      -- ===============================
      -- 請求先の登録
      lt_cust_site_use_rec.cust_acct_site_id := it_cust_acct_site_id; -- 顧客所在地ＩＤ
      lt_cust_site_use_rec.site_use_code     := cv_bill_to_site_code; -- 使用目的
      lt_cust_site_use_rec.created_by_module := SUBSTRB(cv_pkg_name, 1, 150);
      /* 2009.07.09 K.Satomura 統合テスト障害対応(0000341) START */
      lt_cust_site_use_rec.tax_rounding_rule := cv_tax_rouding_rule;
      /* 2009.07.09 K.Satomura 統合テスト障害対応(0000341) END */
      --
      /* 2009.05.21 K.Satomura T1_1092対応 START */
      --/* 2009.05.08 K.Satomura T1_0913対応 START */
      ---- 支払条件ＩＤの取得
      --BEGIN
      --  SELECT rtv.term_id
      --  INTO   lt_cust_site_use_rec.payment_term_id
      --  FROM   ra_terms_vl rtv
      --  WHERE  rtv.name = cv_payment_name_promptly
      --  ;
      --  --
      --EXCEPTION
      --  WHEN NO_DATA_FOUND THEN
      --    -- データが存在しない場合
      --    lv_errbuf := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
      --                   ,iv_name         => cv_tkn_number_03          -- メッセージコード
      --                   ,iv_token_name1  => cv_tkn_item               -- トークンコード1
      --                   ,iv_token_value1 => cv_tkn_value_payment_term -- トークン値1
      --                   ,iv_token_name2  => cv_tkn_table              -- トークンコード2
      --                   ,iv_token_value2 => cv_tkn_value_table_name   -- トークン値2
      --                );
      --    --
      --    RAISE global_api_expt;
      --    --
      --  WHEN OTHERS THEN
      --    -- その他の例外の場合
      --    lv_errbuf := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
      --                   ,iv_name         => cv_tkn_number_04          -- メッセージコード
      --                   ,iv_token_name1  => cv_tkn_table              -- トークンコード1
      --                   ,iv_token_value1 => cv_tkn_value_table_name   -- トークン値1
      --                   ,iv_token_name2  => cv_tkn_key                -- トークンコード2
      --                   ,iv_token_value2 => cv_tkn_value_payment_term -- トークン値2
      --                   ,iv_token_name3  => cv_tkn_err_msg            -- トークンコード3
      --                   ,iv_token_value3 => SQLERRM                   -- トークン値3
      --                );
      --    --
      --    RAISE global_api_expt;
      --    --
      --END;
      ----
      --/* 2009.05.08 K.Satomura T1_0913対応 END */
      /* 2009.05.21 K.Satomura T1_1092対応 END */
      hz_cust_account_site_v2pub.create_cust_site_use(
         p_init_msg_list        => fnd_api.g_true
        ,p_cust_site_use_rec    => lt_cust_site_use_rec
        ,p_customer_profile_rec => lt_customer_profile_rec
        ,p_create_profile       => fnd_api.g_false
        ,p_create_profile_amt   => fnd_api.g_false
        ,x_site_use_id          => lt_site_use_id
        ,x_return_status        => lv_return_status
        ,x_msg_count            => ln_msg_count
        ,x_msg_data             => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name            -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_site_use_bill -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg             -- トークンコード2
                       ,iv_token_value2 => lv_msg_data                -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    /* 2009.05.21 K.Satomura T1_1092対応 START */
    ELSE
      BEGIN
        SELECT hcs.site_use_id           -- 顧客使用目的ＩＤ
              ,hcs.object_version_number -- オブジェクトバージョン番号
        INTO   lt_cust_site_use_rec.site_use_id
              ,ln_object_version_number
        FROM   hz_cust_site_uses  hcs -- 顧客使用目的マスタビュー
        WHERE  hcs.cust_acct_site_id = it_cust_acct_site_id
        AND    hcs.site_use_code     = cv_bill_to_site_code
        /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
        AND    hcs.status            = cv_active
        /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- データが存在しない場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_03         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_item              -- トークンコード1
                         ,iv_token_value1 => cv_tkn_item_name ||
                                             cv_msg_part      ||
                                             it_cust_acct_site_id     -- トークン値1
                         ,iv_token_name2  => cv_tkn_table             -- トークンコード2
                         ,iv_token_value2 => cv_tkn_table_name_use    -- トークン値2
                       );
          --
          RAISE global_api_expt;
          --
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                         ,iv_token_value1 => cv_tkn_table_name_use    -- トークン値1
                         ,iv_token_name2  => cv_tkn_key               -- トークンコード2
                         ,iv_token_value2 => it_cust_acct_site_id     -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                         ,iv_token_value3 => SQLERRM                  -- トークン値3
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      /* 2009.07.09 K.Satomura 統合テスト障害対応(0000341) START */
      lt_cust_site_use_rec.tax_rounding_rule := cv_tax_rouding_rule;
      --
      /* 2009.07.09 K.Satomura 統合テスト障害対応(0000341) END */
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
      lt_cust_site_use_rec.site_use_code     := cv_bill_to_site_code; -- 使用目的
      lt_cust_site_use_rec.created_by_module := NULL;
      --
      /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
      hz_cust_account_site_v2pub.update_cust_site_use(
         p_init_msg_list         => fnd_api.g_true
        ,p_cust_site_use_rec     => lt_cust_site_use_rec
        ,p_object_version_number => ln_object_version_number
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      --
      IF (lv_return_status <> fnd_api.g_ret_sts_success) THEN
        -- リターンコードがS以外の場合
        IF (ln_msg_count > 1) THEN
          lv_msg_data := fnd_msg_pub.get(
                            p_msg_index => cn_number_one
                           ,p_encoded   => fnd_api.g_true
                         );
          --
        END IF;
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_api_name           -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_use_bill_upd -- トークン値1
                       ,iv_token_name2  => cv_tkn_api_msg            -- トークンコード2
                       ,iv_token_value2 => lv_msg_data               -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      END IF;
      --
    /* 2009.05.21 K.Satomura T1_1092対応 END */
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_cust_site_use;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_account_addon
   * Description      : 顧客アドオンマスタ登録更新(A-8)
   ***********************************************************************************/
  PROCEDURE regist_account_addon(
     iv_proc_type           IN         VARCHAR2                              -- 処理区分
    ,it_mst_regist_info_rec IN         g_mst_regist_info_rtype               -- マスタ登録情報
    ,it_cust_account_id     IN         hz_cust_accounts.cust_account_id%TYPE -- 顧客ＩＤ
    ,it_account_number      IN         hz_cust_accounts.account_number%TYPE  -- 顧客番号
    ,ov_errbuf              OUT NOCOPY VARCHAR2                              -- エラー・メッセージ --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                              -- リターン・コード   --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                              -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_account_addon';  -- プロシージャ名
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
    -- トークン用定数
    cv_tkn_value_action_create CONSTANT VARCHAR2(30) := '顧客アドオンマスタの登録';
    cv_tkn_value_action_update CONSTANT VARCHAR2(30) := '顧客アドオンマスタの更新';
    cv_tkn_value_table         CONSTANT VARCHAR2(30) := '顧客アドオンマスタ';
    /* 2009.05.08 K.Satomura T1_0913対応 START */
    cv_torihiki_form_direct CONSTANT xxcmm_cust_accounts.torihiki_form%TYPE := '1'; -- 直接納品
    cv_delivery_form_eigyo  CONSTANT xxcmm_cust_accounts.delivery_form%TYPE := '1'; -- 営業員配送
    cv_tax_div_included     CONSTANT xxcmm_cust_accounts.tax_div%TYPE       := '3'; -- 内税
    /* 2009.05.08 K.Satomura T1_0913対応 END */
    --
    ct_cust_update_flag CONSTANT xxcmm_cust_accounts.cust_update_flag%TYPE := '1';
    ct_vist_target_div  CONSTANT xxcmm_cust_accounts.vist_target_div%TYPE  := '1';
    --
    -- *** ローカル変数 ***
    lt_last_update_date xxcmm_cust_accounts.last_update_date%TYPE;
    ln_count            NUMBER;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- 顧客アドオンマスタ存在チェック
    IF (iv_proc_type = cv_proc_type_update) THEN
      SELECT COUNT(1)
      INTO   ln_count
      FROM   xxcmm_cust_accounts xca-- 顧客アドオンマスタ
      WHERE  xca.customer_id = it_cust_account_id
      ;
      --
    END IF;
    --
    IF ((iv_proc_type = cv_proc_type_create)
      OR ((ln_count <= 0)
      AND (iv_proc_type = cv_proc_type_update)))
    THEN
      -- 処理区分がC又は、顧客アドオンマスタが存在しない場合
      -- ======================
      -- 顧客アドオンマスタ新規
      -- ======================
      BEGIN
        INSERT INTO xxcmm_cust_accounts(
           customer_id            -- 顧客ＩＤ
          ,customer_code          -- 顧客コード
          ,business_low_type      -- 業態（小分類）
          ,industry_div           -- 業種
          ,sale_base_code         -- 売上拠点コード
          ,past_sale_base_code    -- 前月売上拠点コード
          ,delivery_base_code     -- 納品拠点コード
          ,established_site_name  -- 設置先名（相手先）
          ,establishment_location -- 設置ロケーション
          ,open_close_div         -- 物件オープン・クローズ区分
          ,cnvs_business_person   -- 獲得営業員
          ,cnvs_base_code         -- 獲得拠点コード
          ,cust_update_flag       -- 新規／更新フラグ
          ,vist_target_div        -- 訪問対象区分
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          /* 2009.05.08 K.Satomura T1_0913対応 START */
          --,last_update_login)     -- 最終更新ログイン
          ,last_update_login      -- 最終更新ログイン
          ,torihiki_form          -- 取引形態
          ,delivery_form          -- 配送形態
          ,tax_div                -- 消費税区分
        )
          /* 2009.05.08 K.Satomura T1_0913対応 END */
        VALUES (
           it_cust_account_id                                  -- 顧客ＩＤ
          ,it_account_number                                   -- 顧客コード
          ,it_mst_regist_info_rec.business_condition_type      -- 業態（小分類）
          ,it_mst_regist_info_rec.business_type                -- 業種
          ,it_mst_regist_info_rec.publish_base_code            -- 売上拠点コード
          ,it_mst_regist_info_rec.publish_base_code            -- 前月売上拠点コード
          ,it_mst_regist_info_rec.publish_base_code            -- 納品拠点コード
          ,it_mst_regist_info_rec.install_name                 -- 設置先名（相手先）
          ,it_mst_regist_info_rec.install_location             -- 設置ロケーション
          ,it_mst_regist_info_rec.external_reference_opcl_type -- 物件オープン・クローズ区分
          ,it_mst_regist_info_rec.application_code             -- 獲得営業員
          ,it_mst_regist_info_rec.app_base_code                -- 獲得拠点コード
          ,ct_cust_update_flag                                 -- 新規／更新フラグ
          ,ct_vist_target_div                                  -- 訪問対象区分
          ,cn_created_by                                       -- 作成者
          ,cd_creation_date                                    -- 作成日
          ,cn_last_updated_by                                  -- 最終更新者
          ,cd_last_update_date                                 -- 最終更新日
          ,cn_last_update_login                                -- 最終更新ログイン
          /* 2009.05.08 K.Satomura T1_0913対応 START */
          ,cv_torihiki_form_direct -- 取引形態
          ,cv_delivery_form_eigyo  -- 配送形態
          ,cv_tax_div_included     -- 消費税区分
          /* 2009.05.08 K.Satomura T1_0913対応 END */
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_09           -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action              -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_action_create -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg             -- トークンコード2
                         ,iv_token_value2 => SQLERRM                    -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    ELSIF ((iv_proc_type = cv_proc_type_update)
      AND (ln_count >= 1))
    THEN
      -- 処理区分がUの場合
      -- ======================
      -- 顧客アドオンマスタ更新
      -- ======================
      -- 顧客アドオンマスタのロック
      BEGIN
        SELECT xca.last_update_date last_update_date -- 最終更新日
        INTO   lt_last_update_date
        FROM   xxcmm_cust_accounts xca -- 顧客アドオンマスタ
        WHERE  xca.customer_id = it_cust_account_id
        FOR UPDATE NOWAIT
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_10         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_table       -- トークン値1
                         ,iv_token_name2  => cv_tkn_errmsg            -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- 顧客アドオンマスタの更新
      BEGIN
        UPDATE xxcmm_cust_accounts
        SET    business_low_type      = it_mst_regist_info_rec.business_condition_type      -- 業態（小分類）
              ,industry_div           = it_mst_regist_info_rec.business_type                -- 業種
              ,sale_base_code         = it_mst_regist_info_rec.publish_base_code            -- 売上拠点コード
              ,past_sale_base_code    = it_mst_regist_info_rec.publish_base_code            -- 前月売上拠点コード
              ,delivery_base_code     = it_mst_regist_info_rec.publish_base_code            -- 納品拠点コード
              ,established_site_name  = it_mst_regist_info_rec.install_name                 -- 設置先名（相手先）
              ,establishment_location = it_mst_regist_info_rec.install_location             -- 設置ロケーション
              ,open_close_div         = it_mst_regist_info_rec.external_reference_opcl_type -- 物件オープン・クローズ区分
              ,cnvs_business_person   = it_mst_regist_info_rec.application_code             -- 獲得営業員
              ,cnvs_base_code         = it_mst_regist_info_rec.app_base_code                -- 獲得拠点コード
              ,cust_update_flag       = ct_cust_update_flag                                 -- 新規／更新フラグ
              ,vist_target_div        = ct_vist_target_div                                  -- 訪問対象区分
              ,last_updated_by        = cn_last_updated_by                                  -- 最終更新者
              ,last_update_date       = cd_last_update_date                                 -- 最終更新日
              ,last_update_login      = cn_last_update_login                                -- 最終更新ログイン
              /* 2009.05.08 K.Satomura T1_0913対応 START */
              ,torihiki_form          = cv_torihiki_form_direct                             -- 取引形態
              ,delivery_form          = cv_delivery_form_eigyo                              -- 配送形態
              ,tax_div                = cv_tax_div_included                                 -- 消費税区分
              /* 2009.05.08 K.Satomura T1_0913対応 END */
        WHERE  customer_id = it_cust_account_id
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_09           -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action              -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_action_update -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg             -- トークンコード2
                         ,iv_token_value2 => SQLERRM                    -- トークン値2
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_account_addon;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_contract
   * Description      : 契約先情報抽出(A-9)
   ***********************************************************************************/
  PROCEDURE get_contract(
     it_sp_decision_header_id IN  xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,ot_mst_regist_info_rec   OUT NOCOPY g_mst_regist_info_rtype                       -- マスタ登録情報
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                      -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_contract';  -- プロシージャ名
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
    ct_sp_dec_cust_class_contract CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '2'; -- ＳＰ専決顧客区分=契約先
    --
    -- トークン用定数
    cv_tkn_value_sp_dec_head_id CONSTANT VARCHAR2(30) := 'ＳＰ専決ヘッダＩＤ';             -- ＳＰ専決ヘッダＩＤ和名
    cv_tkn_value_sp_dec_custs   CONSTANT VARCHAR2(30) := 'ＳＰ専決顧客テーブル（契約先）'; -- ＳＰ専決顧客テーブル和名
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
    -- ============================
    -- 設置先情報（契約先）取得処理
    -- ============================
    ot_mst_regist_info_rec := NULL;
    --
    BEGIN
      SELECT xsd.customer_id            customer_id            -- 顧客ＩＤ
            ,xsd.party_name             party_name             -- 顧客名
            ,xsd.party_name_alt         party_name_alt         -- 顧客名カナ
            ,xsd.representative_name    representative_name    -- 代表者名
            ,xsd.postal_code            postal_code            -- 郵便番号
            ,xsd.state                  state                  -- 都道府県
            ,xsd.city                   city                   -- 市・区
            ,xsd.address1               address1               -- 住所１
            ,xsd.address2               address2               -- 住所２
            ,xsd.address_lines_phonetic address_lines_phonetic -- 電話番号
      INTO   ot_mst_regist_info_rec.customer_id
            ,ot_mst_regist_info_rec.party_name
            ,ot_mst_regist_info_rec.party_name_alt
            ,ot_mst_regist_info_rec.representative_name
            ,ot_mst_regist_info_rec.postal_code
            ,ot_mst_regist_info_rec.state
            ,ot_mst_regist_info_rec.city
            ,ot_mst_regist_info_rec.address1
            ,ot_mst_regist_info_rec.address2
            ,ot_mst_regist_info_rec.address_lines_phonetic
      FROM   xxcso_sp_decision_custs xsd -- ＳＰ専決顧客テーブル
      WHERE  xsd.sp_decision_header_id      = it_sp_decision_header_id
      AND    xsd.sp_decision_customer_class = ct_sp_dec_cust_class_contract
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item               -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_head_id ||
                                           cv_msg_part                 ||
                                           it_sp_decision_header_id  -- トークン値1
                       ,iv_token_name2  => cv_tkn_table              -- トークンコード2
                       ,iv_token_value2 => cv_tkn_value_sp_dec_custs -- トークン値2
                    );
        --
        RAISE global_api_expt;
        --
      WHEN OTHERS THEN
        -- その他の例外の場合
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04          -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                       ,iv_token_value1 => cv_tkn_value_sp_dec_custs -- トークン値1
                       ,iv_token_name2  => cv_tkn_key                -- トークンコード2
                       ,iv_token_value2 => it_sp_decision_header_id  -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg            -- トークンコード3
                       ,iv_token_value3 => SQLERRM                   -- トークン値3
                    );
        --
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_contract;
  --
  --
  /**********************************************************************************
   * Procedure Name   : regist_contract
   * Description      : 契約先登録(A-10)
   ***********************************************************************************/
  PROCEDURE regist_contract(
     it_mst_regist_info_rec  IN         g_mst_regist_info_rtype                            -- マスタ登録情報
    ,ot_contract_customer_id OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE -- 契約先ＩＤ
    ,ov_errbuf               OUT NOCOPY VARCHAR2                                           -- エラー・メッセージ --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2                                           -- リターン・コード   --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2                                           -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'regist_contract';  -- プロシージャ名
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
    -- トークン用定数
    cv_tkn_value_sequence      CONSTANT VARCHAR2(30) := '契約先ＩＤシーケンス';
    cv_tkn_value_action_create CONSTANT VARCHAR2(30) := '契約先テーブルの登録';
    --
    -- *** ローカル変数 ***
    lt_contract_customer_id xxcso_contract_customers.contract_customer_id%TYPE;
    ln_count                NUMBER;
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ============================
    -- 設置先情報（契約先）取得処理
    -- ============================
    IF (it_mst_regist_info_rec.customer_id IS NULL) THEN
      -- 顧客ＩＤがNULLの場合
      -- 契約先ＩＤの取得
      BEGIN
        SELECT xxcso_contract_customers_s01.NEXTVAL contract_customer_id
        INTO   lt_contract_customer_id
        FROM   DUAL
        ;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- その他のエラーの場合 
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_08         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_sequence          -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_sequence    -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      BEGIN
        INSERT INTO xxcso_contract_customers(
           contract_customer_id -- 契約先ＩＤ
          ,contract_number      -- 契約先番号
          ,contract_name        -- 契約先名
          ,contract_name_kana   -- 契約先名カナ
          ,delegate_name        -- 代表者名
          ,post_code            -- 郵便番号
          ,prefectures          -- 都道府県
          ,city_ward            -- 市・区
          ,address_1            -- 住所１
          ,address_2            -- 住所２
          ,phone_number         -- 電話番号
          ,created_by           -- 作成者
          ,creation_date        -- 作成日
          ,last_updated_by      -- 最終更新者
          ,last_update_date     -- 最終更新日
          ,last_update_login)   -- 最終更新ログイン
        VALUES (
           lt_contract_customer_id                       -- 契約先ＩＤ
          ,TO_CHAR(xxcso_contract_customers_s02.NEXTVAL) -- 契約先番号
          ,it_mst_regist_info_rec.party_name             -- 契約先名
          ,it_mst_regist_info_rec.party_name_alt         -- 契約先名カナナ
          ,it_mst_regist_info_rec.representative_name    -- 代表者名
          ,it_mst_regist_info_rec.postal_code            -- 郵便番号
          ,it_mst_regist_info_rec.state                  -- 都道府県
          ,it_mst_regist_info_rec.city                   -- 市・区
          ,it_mst_regist_info_rec.address1               -- 住所１
          ,it_mst_regist_info_rec.address2               -- 住所２
          ,it_mst_regist_info_rec.address_lines_phonetic -- 電話番号
          ,cn_created_by                                 -- 作成者
          ,cd_creation_date                              -- 作成日
          ,cn_last_updated_by                            -- 最終更新者
          ,cd_last_update_date                           -- 最終更新日
          ,cn_last_update_login                          -- 最終更新ログイン
        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- その他のエラーの場合
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_09           -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action              -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_action_create -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg             -- トークンコード2
                         ,iv_token_value2 => SQLERRM                    -- トークン値2
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
    ELSE
      lt_contract_customer_id := it_mst_regist_info_rec.customer_id;
      --
    END IF;
    --
    ot_contract_customer_id := lt_contract_customer_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
     --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END regist_contract;
  --
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,ot_cust_account_id       OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE                -- 顧客ＩＤ
    ,ot_contract_customer_id  OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE   -- 契約先ＩＤ
    ,ov_errbuf                OUT NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,ov_retcode               OUT NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,ov_errmsg                OUT NOCOPY VARCHAR2                                             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プロシージャ名
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
    lv_proc_type            VARCHAR2(1);                                        -- 処理区分
    lt_mst_regist_info_rec  g_mst_regist_info_rtype;                            -- マスタ登録情報
    lt_party_id             hz_parties.party_id%TYPE;                           -- パーティＩＤ
    lt_party_site_id        hz_party_sites.party_site_id%TYPE;                  -- パーティサイトＩＤ
    lt_cust_account_id      hz_cust_accounts.cust_account_id%TYPE;              -- 顧客ＩＤ
    lt_account_number       hz_cust_accounts.account_number%TYPE;               -- 顧客番号
    lt_cust_acct_site_id    hz_cust_acct_sites_all.cust_acct_site_id%TYPE;      -- 顧客所在地ＩＤ
    lt_contract_customer_id xxcso_contract_customers.contract_customer_id%TYPE; -- 契約先ＩＤ
    --
    -- *** ローカル・カーソル ***
    --
    -- *** ローカル・レコード ***
    --
    -- *** ローカル例外 ***
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
    -- ============
    -- A-1.初期処理
    -- ============
    start_proc(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,ot_mst_regist_info_rec   => lt_mst_regist_info_rec   -- マスタ登録情報
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================
    -- A-2. 設置先情報抽出
    -- ===================
    get_install_at_info(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,iot_mst_regist_info_rec  => lt_mst_regist_info_rec   -- マスタ登録情報
      ,ov_proc_type             => lv_proc_type             -- 処理区分
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    IF (lv_proc_type <> cv_proc_type_outside) THEN
      -- 処理区分がO以外の場合
      -- ==========================
      -- A-3.パーティマスタ登録更新
      -- ==========================
      regist_party(
         iv_proc_type           => lv_proc_type           -- 処理区分
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
        ,ot_party_id            => lt_party_id            -- パーティＩＤ
        ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ --# 固定 #
        ,ov_retcode             => lv_retcode             -- リターン・コード   --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ============================================
      -- A-4.顧客事業所／パーティサイトマスタ登録更新
      -- ============================================
      regist_locat_party_site(
         iv_proc_type           => lv_proc_type           -- 処理区分
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
        ,it_party_id            => lt_party_id            -- パーティＩＤ
        ,ot_party_site_id       => lt_party_site_id       -- パーティサイトＩＤ
        ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ --# 固定 #
        ,ov_retcode             => lv_retcode             -- リターン・コード   --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ======================
      -- A-5.顧客マスタ登録更新
      -- ======================
      regist_cust_account(
         iv_proc_type           => lv_proc_type           -- 処理区分
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
        ,it_party_id            => lt_party_id            -- パーティＩＤ
        ,ot_cust_account_id     => lt_cust_account_id     -- 顧客ＩＤ
        ,ot_account_number      => lt_account_number      -- 顧客番号
        ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ --# 固定 #
        ,ov_retcode             => lv_retcode             -- リターン・コード   --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ========================
      -- A-6.顧客所在地マスタ登録
      -- ========================
      regist_cust_acct_site(
         iv_proc_type           => lv_proc_type           -- 処理区分
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
        ,it_party_site_id       => lt_party_site_id       -- パーティサイトＩＤ
        ,it_cust_account_id     => lt_cust_account_id     -- 顧客ＩＤ
        ,ot_cust_acct_site_id   => lt_cust_acct_site_id   -- 顧客所在地ＩＤ
        ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ --# 固定 #
        ,ov_retcode             => lv_retcode             -- リターン・コード   --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ==========================
      -- A-7.顧客使用目的マスタ登録
      -- ==========================
      regist_cust_site_use(
         iv_proc_type           => lv_proc_type           -- 処理区分
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
        ,it_cust_acct_site_id   => lt_cust_acct_site_id   -- 顧客所在地ＩＤ
        ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ --# 固定 #
        ,ov_retcode             => lv_retcode             -- リターン・コード   --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
      -- ==============================
      -- A-8.顧客アドオンマスタ登録更新
      -- ==============================
      regist_account_addon(
         iv_proc_type           => lv_proc_type           -- 処理区分
        ,it_mst_regist_info_rec => lt_mst_regist_info_rec -- マスタ登録情報
        ,it_cust_account_id     => lt_cust_account_id     -- 顧客ＩＤ
        ,it_account_number      => lt_account_number      -- 顧客番号
        ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ --# 固定 #
        ,ov_retcode             => lv_retcode             -- リターン・コード   --# 固定 #
        ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    ELSE
      lt_cust_account_id := lt_mst_regist_info_rec.customer_id;
      --
    END IF;
    --
    -- ==================
    -- A-9.契約先情報抽出
    -- ==================
    get_contract(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,ot_mst_regist_info_rec   => lt_mst_regist_info_rec   -- マスタ登録情報
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===============
    -- A-10.契約先登録
    -- ===============
    regist_contract(
       it_mst_regist_info_rec  => lt_mst_regist_info_rec  -- マスタ登録情報
      ,ot_contract_customer_id => lt_contract_customer_id -- 契約先ＩＤ
      ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ --# 固定 #
      ,ov_retcode              => lv_retcode              -- リターン・コード   --# 固定 #
      ,ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    ot_cust_account_id      := lt_cust_account_id;
    ot_contract_customer_id := lt_contract_customer_id;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** 処理部共通例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
   --
    --#####################################  固定部 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf                   OUT NOCOPY VARCHAR2                                             -- エラー・メッセージ --# 固定 #
    ,retcode                  OUT NOCOPY VARCHAR2                                             -- リターン・コード   --# 固定 #
    ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
    ,ot_cust_account_id       OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE                -- 顧客ＩＤ
    ,ot_contract_customer_id  OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE   -- 契約先ＩＤ
  )
  --
  --###########################  固定部 START   ###########################
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
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
--    xxccp_common_pkg.put_log_header(
--       ov_retcode => lv_retcode
--      ,ov_errbuf  => lv_errbuf
--    );
--    --
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_api_others_expt;
--    END IF;
    --
    --###########################  固定部 END   #############################
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       it_sp_decision_header_id => it_sp_decision_header_id -- ＳＰ専決ヘッダＩＤ
      ,ot_cust_account_id       => ot_cust_account_id       -- 顧客ＩＤ
      ,ot_contract_customer_id  => ot_contract_customer_id  -- 契約先ＩＤ
      ,ov_errbuf                => lv_errbuf                -- エラー・メッセージ --# 固定 #
      ,ov_retcode               => lv_retcode               -- リターン・コード   --# 固定 #
      ,ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
/*
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
    --
    -- =======================
    -- A-x.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    END IF;
*/
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      /* 2009.06.30 K.Satomura 統合テスト障害対応(0000209) START */
      --ROLLBACK;
      /* 2009.06.30 K.Satomura 統合テスト障害対応(0000209) END */
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      /* 2009.06.30 K.Satomura 統合テスト障害対応(0000209) START */
      --ROLLBACK;
      /* 2009.06.30 K.Satomura 統合テスト障害対応(0000209) END */
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO020A03C;
/
