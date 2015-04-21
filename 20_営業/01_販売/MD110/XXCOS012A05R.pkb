CREATE OR REPLACE PACKAGE BODY APPS.XXCOS012A05R
AS
 /*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCOS012A05R(body)
 * Description      : ロット別ピックリスト（チェーン・製品別トータル）
 * MD.050           : MD050_COS_012_A05_ロット別ピックリスト（チェーン・製品別トータル）
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_parameter        パラメータチェック処理(A-2)
 *  get_data               データ取得(A-3)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-4)
 *  execute_svf            ＳＶＦ起動(A-5)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/07    1.0   S.Itou           新規作成
 *  2015/04/10    1.1   S.Yamashita      【E_本稼動_13004】対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_sla                CONSTANT VARCHAR2(3) := '／';
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
  global_proc_date_err_expt EXCEPTION;
  global_call_api_expt      EXCEPTION;
  global_date_reversal_expt EXCEPTION;
  global_insert_data_expt   EXCEPTION;
  global_delete_data_expt   EXCEPTION;
  global_get_profile_expt   EXCEPTION;
  global_lookup_code_expt   EXCEPTION;
  global_data_lock_expt     EXCEPTION;
  global_get_basecode_expt  EXCEPTION;
  global_get_chaincode_expt EXCEPTION;
--  Add Ver1.1 S.Yamashita Start
  global_get_custcode_expt  EXCEPTION;
--  Add Ver1.1 S.Yamashita End
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS012A05R';          -- パッケージ名
--
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS012A05R';          -- コンカレント名
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS012A05R';          -- 帳票ＩＤ
  cv_extension_pdf          CONSTANT VARCHAR2(100) := '.pdf';                  -- 拡張子（ＰＤＦ）
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS012A05S.xml';      -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS012A05S.vrq';      -- クエリー様式ファイル名
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                     -- 出力区分（ＰＤＦ）
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOS';                      --販物短縮アプリ名
  cv_xxcoi_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOI';                      --在庫領域短縮アプリ名
  --販物メッセージ
  ct_msg_lock_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';           --ロック取得エラーメッセージ
  ct_msg_get_profile_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';           --プロファイル取得エラー
  ct_msg_date_reversal_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00005';           --日付逆転エラー
  ct_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';           --データ登録エラーメッセージ
  ct_msg_delete_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';           --データ削除エラーメッセージ
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';           --データ取得エラーメッセージ
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00014';           --業務日付取得エラー
  ct_msg_call_api_err       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00017';           --API呼出エラーメッセージ
  ct_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';           --明細0件用メッセージ
  ct_msg_bace_code          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00035';           --拠点情報取得エラーメッセージ
  ct_msg_chain_code         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00036';           --EDIチェーン店情報取得エラーメッセージ
  ct_msg_svf_api            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00041';           --ＳＶＦ起動ＡＰＩ
  ct_msg_request            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00042';           --要求ＩＤ
  ct_msg_max_date           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00056';           --XXCOS:MAX日付
  ct_msg_parameter          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14801';           --パラメータ出力メッセージ
  ct_msg_req_dt_from        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12652';           --着日(From)
  ct_msg_req_dt_to          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12653';           --着日(To)
  ct_msg_rpt_wrk_tbl        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14803';           --帳票ワークテーブル
  ct_msg_bargain_cls_tblnm  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12655';           --定番特売区分クイックコードマスタ
  ct_msg_shipping_sts_tblnm CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14802';           --出荷情報ステータスクイックコードマスタ
--  Add Ver1.1 S.Yamashita Start
  ct_msg_customer_tblnm     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00049';           --顧客マスタ
--  Add Ver1.1 S.Yamashita End
  --トークン
  cv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';                  --テーブル
  cv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';              --日付（From)
  cv_tkn_date_to            CONSTANT VARCHAR2(100) := 'DATE_TO';                --日付（To)
  cv_tkn_profile            CONSTANT VARCHAR2(100) := 'PROFILE';                --プロファイル
  cv_tkn_table_name         CONSTANT VARCHAR2(100) := 'TABLE_NAME';             --テーブル名称
  cv_tkn_key_data           CONSTANT VARCHAR2(100) := 'KEY_DATA';               --キーデータ
  cv_tkn_code               CONSTANT VARCHAR2(100) := 'CODE';                   --拠点コード
  cv_tkn_chain_code         CONSTANT VARCHAR2(100) := 'CHAIN_SHOP_CODE';        --チェーン店コード
  cv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';               --ＡＰＩ名称
  cv_tkn_param1             CONSTANT VARCHAR2(100) := 'PARAM1';                 --第１入力パラメータ／内容
  cv_tkn_param2             CONSTANT VARCHAR2(100) := 'PARAM2';                 --第２入力パラメータ／内容
  cv_tkn_param3             CONSTANT VARCHAR2(100) := 'PARAM3';                 --第３入力パラメータ／内容
  cv_tkn_param4             CONSTANT VARCHAR2(100) := 'PARAM4';                 --第４入力パラメータ
  cv_tkn_param5             CONSTANT VARCHAR2(100) := 'PARAM5';                 --第５入力パラメータ
  cv_tkn_param6             CONSTANT VARCHAR2(100) := 'PARAM6';                 --第６入力パラメータ／内容
  cv_tkn_param7             CONSTANT VARCHAR2(100) := 'PARAM7';                 --第７入力パラメータ
  cv_tkn_param8             CONSTANT VARCHAR2(100) := 'PARAM8';                 --第８入力パラメータ／内容
--  Add Ver1.1 S.Yamashita Start
  cv_tkn_param9             CONSTANT VARCHAR2(100) := 'PARAM9';                 --第９入力パラメータ
--  Add Ver1.1 S.Yamashita End

  cv_tkn_request            CONSTANT VARCHAR2(100) := 'REQUEST';                --要求ＩＤ
  --プロファイル名称
  ct_prof_max_date          CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_MAX_DATE';
  --クイックコードタイプ
  ct_qct_bargain_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_BARGAIN_CLASS';
  ct_qct_shipping_staus     CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOI1_SHIPPING_STATUS';
  --使用可能フラグ定数
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                          --使用可能
  --定番特売区分
  cv_bargain_class_all      CONSTANT VARCHAR2(2)   := '00';           --全て
  --フォーマット
  cv_fmt_date8              CONSTANT VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT VARCHAR2(30)  := 'RRRR/MM/DD';
  cv_fmt_datetime           CONSTANT VARCHAR2(30)  := 'RRRR/MM/DD HH24:MI:SS';
  -- 言語コード
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  -- 時間（最小、最大)
  cv_time_min               CONSTANT VARCHAR2(8)  := '00:00:00';
  cv_time_max               CONSTANT VARCHAR2(8)  := '23:59:59';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --帳票ワーク用テーブル型定義
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_lot_pick_chain_pro%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --パラメータ
  gv_login_base_code                  VARCHAR2(4);                    -- 拠点
  gv_login_chain_store_code           VARCHAR2(4);                    -- チェーン店
--  Add Ver1.1 S.Yamashita Start
  gv_login_customer_code              VARCHAR2(9);                    -- 顧客
--  Add Ver1.1 S.Yamashita End
  gd_request_date_from                DATE;                           -- 着日(From)
  gd_request_date_to                  DATE;                           -- 着日(To)
  gd_edi_received_date                DATE := NULL;                   -- EDI受信日
  gt_bargain_class                    fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定番特売区分
  gt_bargain_class_name               fnd_lookup_values.meaning%TYPE; -- 定番特売区分（ヘッダ）名称
  gv_order_number                     VARCHAR2(10);                   -- 受注番号
  --初期取得
  gd_process_date                     DATE;                           -- 業務日付
  gd_max_date                         DATE;                           -- MAX日付
  gt_shipping_sts_cd1                 fnd_lookup_values.attribute1%TYPE;
                                                                      -- 出荷情報ステータスコード1
  gt_shipping_sts_cd2                 fnd_lookup_values.attribute2%TYPE;
                                                                      -- 出荷情報ステータスコード2
  gt_shipping_sts_cd3                 fnd_lookup_values.attribute3%TYPE;
                                                                      -- 出荷情報ステータスコード3
--  Add Ver1.1 S.Yamashita Start
  gv_login_customer_name              VARCHAR2(40);                   -- 顧客名
--  Add Ver1.1 S.Yamashita End
  --帳票ワーク内部テーブル
  g_rpt_data_tab                      g_rpt_data_ttype;
--
  -- ===============================
  -- ユーザー定義関数
  -- ===============================
  --数値比較
  FUNCTION comp_num(
    in_arg1                   IN      NUMBER,
    in_arg2                   IN      NUMBER)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( in_arg1 IS NULL ) AND ( in_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( in_arg1 IS NULL ) AND ( in_arg2 IS NOT NULL ) ) THEN
        RETURN  FALSE;
    ELSIF ( ( in_arg1 IS NOT NULL ) AND ( in_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( in_arg1 = in_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --文字列比較
  FUNCTION comp_char(
    iv_arg1                   IN      VARCHAR2
   ,iv_arg2                   IN      VARCHAR2
  )
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( iv_arg1 IS NOT NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( iv_arg1 = iv_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --日付比較
  FUNCTION comp_date(
    id_arg1                   IN      DATE
   ,id_arg2                   IN      DATE
  )
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( id_arg1 IS NOT NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( id_arg1 = id_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_login_base_code        IN  VARCHAR2    -- 1.拠点
   ,iv_login_chain_store_code IN  VARCHAR2    -- 2.チェーン店
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN  VARCHAR2    -- 3.顧客
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN  VARCHAR2    -- 4.着日（From）
   ,iv_request_date_to        IN  VARCHAR2    -- 5.着日（To）
   ,iv_bargain_class          IN  VARCHAR2    -- 6.定番特売区分
   ,iv_edi_received_date      IN  VARCHAR2    -- 7.EDI受信日
   ,iv_shipping_status        IN  VARCHAR2    -- 8.ステータス
   ,iv_order_number           IN  VARCHAR2    -- 9.受注番号
   ,ov_errbuf                 OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2    --   リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_cust_cls_cd_base       CONSTANT VARCHAR2(1) := '1';
    cv_cust_cls_cd_chain      CONSTANT VARCHAR2(2) := '18';
--
    -- *** ローカル変数 ***
    lv_profile_name           VARCHAR2(5000);
    lv_table_name             VARCHAR2(5000);
    lv_max_date               VARCHAR2(5000);
    lt_shipping_sts_name      fnd_lookup_values.meaning%TYPE;  -- 出荷情報ステータス摘要
    lv_login_base_name        VARCHAR2(40);
    lv_login_chain_store_name VARCHAR2(40);
--  Add Ver1.1 S.Yamashita Start
    lt_customer_name          hz_parties.party_name%TYPE  DEFAULT NULL; -- 顧客名
--  Add Ver1.1 S.Yamashita End
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
    --==================================
    -- 1.業務日付取得
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX日付取得
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 3.拠点、チェーン店名称取得
    --==================================
--
    --拠点名
    BEGIN
      SELECT
        hp.party_name         base_name
      INTO
        lv_login_base_name
      FROM
        xxcmm_cust_accounts xca
       ,hz_cust_accounts hca
       ,hz_parties hp
      WHERE
        hca.cust_account_id     = xca.customer_id
      AND
        hca.party_id            = hp.party_id
      AND
        hca.account_number      = iv_login_base_code
      AND
        hca.customer_class_code = cv_cust_cls_cd_base
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_login_base_name := NULL;
    END;
    
    --パラメータのチェーン店コードが設定されている場合、名称を取得する
    IF ( iv_login_chain_store_code IS NOT NULL )THEN
      BEGIN
        SELECT
          hp.party_name       chain_store_name
        INTO
          lv_login_chain_store_name
        FROM
          xxcmm_cust_accounts xca
         ,hz_cust_accounts hca
         ,hz_parties hp
        WHERE
          hca.cust_account_id     = xca.customer_id
        AND
          hca.party_id            = hp.party_id
        AND
          xca.chain_store_code    = iv_login_chain_store_code
        AND
          hca.customer_class_code = cv_cust_cls_cd_chain
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_login_chain_store_name := NULL;
      END;
    END IF;
--
--  Add Ver1.1 S.Yamashita Start
    --パラメータの顧客コードが設定されている場合、名称を取得する
    IF ( iv_login_customer_code IS NOT NULL ) THEN
      BEGIN
        SELECT hp.party_name       AS customer_name
        INTO   lt_customer_name
        FROM   hz_cust_accounts    hca
             , hz_parties          hp
             , xxcmm_cust_accounts xca
        WHERE  hca.party_id            = hp.party_id
        AND    hca.account_number      = iv_login_customer_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lt_customer_name := NULL;
      END;
    END IF;
--  Add Ver1.1 S.Yamashita End
--
    --==================================
    -- 4.定番特売区分（ヘッダ）チェック
    --==================================
--
    BEGIN
      SELECT
        flv.meaning                     bargain_class_name
      INTO
        gt_bargain_class_name
      FROM
        fnd_lookup_values               flv
      WHERE
          flv.lookup_type               = ct_qct_bargain_class
      AND flv.lookup_code               = iv_bargain_class
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
      AND flv.language                  = ct_lang
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        gt_bargain_class_name := NULL;
    END;
--
    --==================================
    -- 5.出荷情報ステータス取得
    --==================================
--
    BEGIN
      SELECT
        flv.attribute1                  shipping_status_code1         --出荷情報ステータスコード1
       ,flv.attribute2                  shipping_status_code2         --出荷情報ステータスコード2
       ,flv.attribute3                  shipping_status_code3         --出荷情報ステータスコード3
       ,flv.meaning                     shipping_status_name          --出荷情報ステータス摘要
      INTO
        gt_shipping_sts_cd1
       ,gt_shipping_sts_cd2
       ,gt_shipping_sts_cd3
       ,lt_shipping_sts_name
      FROM
        fnd_lookup_values               flv
      WHERE
          flv.lookup_type               = ct_qct_shipping_staus
      AND flv.lookup_code               = iv_shipping_status         --パラメータ_出荷情報ステータス
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
      AND flv.language                  = ct_lang
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_shipping_sts_name := NULL;
    END;
--
     --==================================
    -- 6.パラメータ出力
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_parameter
                                  ,iv_token_name1        => cv_tkn_param1
                                  ,iv_token_value1       => iv_login_base_code || cv_msg_sla || lv_login_base_name
                                  ,iv_token_name2        => cv_tkn_param2
                                  ,iv_token_value2       => iv_login_chain_store_code || cv_msg_sla || lv_login_chain_store_name
--  Mod Ver1.1 S.Yamashita Start
--                                  ,iv_token_name3        => cv_tkn_param3
--                                  ,iv_token_value3       => iv_request_date_from
--                                  ,iv_token_name4        => cv_tkn_param4
--                                  ,iv_token_value4       => iv_request_date_to
--                                  ,iv_token_name5        => cv_tkn_param5
--                                  ,iv_token_value5       => iv_bargain_class || cv_msg_sla || gt_bargain_class_name
--                                  ,iv_token_name6        => cv_tkn_param6
--                                  ,iv_token_value6       => iv_edi_received_date
--                                  ,iv_token_name7        => cv_tkn_param7
--                                  ,iv_token_value7       => iv_shipping_status || cv_msg_sla || lt_shipping_sts_name
--                                  ,iv_token_name8        => cv_tkn_param8
--                                  ,iv_token_value8       => iv_order_number
                                  ,iv_token_name3        => cv_tkn_param3
                                  ,iv_token_value3       => iv_login_customer_code || cv_msg_sla || lt_customer_name
                                  ,iv_token_name4        => cv_tkn_param4
                                  ,iv_token_value4       => iv_request_date_from
                                  ,iv_token_name5        => cv_tkn_param5
                                  ,iv_token_value5       => iv_request_date_to
                                  ,iv_token_name6        => cv_tkn_param6
                                  ,iv_token_value6       => iv_bargain_class || cv_msg_sla || gt_bargain_class_name
                                  ,iv_token_name7        => cv_tkn_param7
                                  ,iv_token_value7       => iv_edi_received_date
                                  ,iv_token_name8        => cv_tkn_param8
                                  ,iv_token_value8       => iv_shipping_status || cv_msg_sla || lt_shipping_sts_name
--  Mod Ver1.1 S.Yamashita End
--  Add Ver1.1 S.Yamashita Start
                                  ,iv_token_name9        => cv_tkn_param9
                                  ,iv_token_value9       => iv_order_number
--  Add Ver1.1 S.Yamashita End
                                 );
    --
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
    --1行空白
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => NULL
    );
--
    -- 名称取得エラーハンドリング
    CASE
      -- 拠点名取得エラー時
      WHEN lv_login_base_name IS NULL
        THEN
          RAISE global_get_basecode_expt;
      -- チェーン店名取得エラー時
      WHEN iv_login_chain_store_code IS NOT NULL
      AND  lv_login_chain_store_name IS NULL
        THEN
          RAISE global_get_chaincode_expt;
--  Add Ver1.1 S.Yamashita Start
      -- 顧客名取得エラー時
      WHEN iv_login_customer_code IS NOT NULL
      AND  lt_customer_name       IS NULL
        THEN
          lv_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_customer_tblnm
                                 );
          RAISE global_get_custcode_expt;
--  Add Ver1.1 S.Yamashita End
      -- 定番特売区分（ヘッダ）取得エラー時
      WHEN gt_bargain_class_name IS NULL
        THEN
          lv_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_bargain_cls_tblnm
                                 );
          RAISE global_lookup_code_expt;
      -- 出荷情報ステータス取得エラー時
      WHEN lt_shipping_sts_name IS NULL
        THEN
          lv_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_shipping_sts_tblnm
                                 );
          RAISE global_lookup_code_expt;
      ELSE
        NULL;
    END CASE ;
--
    --==================================
    -- 7.パラメータ変換
    --==================================
    gv_login_base_code        := iv_login_base_code;
    gv_login_chain_store_code := iv_login_chain_store_code;
--  Add Ver1.1 S.Yamashita Start
    gv_login_customer_code    := iv_login_customer_code;
    gv_login_customer_name    := SUBSTRB(lt_customer_name,1,40);
--  Add Ver1.1 S.Yamashita End
    gt_bargain_class          := iv_bargain_class;
    gv_order_number           := iv_order_number;
    --時分秒付与
    gd_request_date_from      := TO_DATE( TO_CHAR( TO_DATE(iv_request_date_from, cv_fmt_date)
                                                  ,cv_fmt_date) || cv_time_min
                                         ,cv_fmt_datetime );
    gd_request_date_to        := TO_DATE( TO_CHAR( TO_DATE(iv_request_date_to,   cv_fmt_date)
                                                  ,cv_fmt_date) || cv_time_max
                                         ,cv_fmt_datetime );
    IF ( iv_edi_received_date IS NOT NULL )THEN
      gd_edi_received_date    := TO_DATE( TO_CHAR( TO_DATE(iv_edi_received_date,   cv_fmt_date)
                                                  ,cv_fmt_date) || cv_time_min
                                         ,cv_fmt_datetime );
    END IF;
    --パラメータの定番特売区分が「全て」の場合、名称をNULLクリアする。
    IF ( gt_bargain_class = cv_bargain_class_all ) THEN
      gt_bargain_class_name   := NULL;
    END IF;
--
  EXCEPTION
--
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_get_profile_err
                                  ,iv_token_name1        => cv_tkn_profile
                                  ,iv_token_value1       => lv_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 拠点コード取得例外ハンドラ ***
    WHEN global_get_basecode_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_bace_code
                                  ,iv_token_name1        => cv_tkn_code
                                  ,iv_token_value1       => iv_login_base_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** チェーン店コード取得例外ハンドラ ***
    WHEN global_get_chaincode_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_chain_code
                                  ,iv_token_name1        => cv_tkn_chain_code
                                  ,iv_token_value1       => iv_login_chain_store_code
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--  Add Ver1.1 S.Yamashita Start
    -- *** 顧客コード取得例外ハンドラ ***
    WHEN global_get_custcode_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_select_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--  Add Ver1.1 S.Yamashita End
    -- *** クイックコードマスタ例外ハンドラ ***
    WHEN global_lookup_code_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_select_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter';        -- プログラム名
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
    lv_req_dt_from   VARCHAR2(5000);
    lv_req_dt_to     VARCHAR2(5000);
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
    --==================================
    -- 日付逆転チェック
    --==================================
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
  EXCEPTION
    -- *** 日付逆転例外ハンドラ ***
    WHEN global_date_reversal_expt THEN
      lv_req_dt_from          := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_req_dt_from
                                 );
      lv_req_dt_to            := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_req_dt_to
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_date_reversal_err
                                  ,iv_token_name1        => cv_tkn_date_from
                                  ,iv_token_value1       => lv_req_dt_from
                                  ,iv_token_name2        => cv_tkn_date_to
                                  ,iv_token_value2       => lv_req_dt_to
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
    --集計用変数
    ln_case_qty      NUMBER;
    ln_singly_qty    NUMBER;
    ln_summary_qty   NUMBER;
--
    --キーブレイク変数
    lt_key_base_code               xxcoi_lot_reserve_info.base_code%TYPE;
    lt_key_base_name               xxcoi_lot_reserve_info.base_name%TYPE;
    lt_key_whse_code               xxcoi_lot_reserve_info.whse_code%TYPE;
    lt_key_whse_name               xxcoi_lot_reserve_info.whse_name%TYPE;
    lt_key_chain_code              xxcoi_lot_reserve_info.chain_code%TYPE;
    lt_key_chain_name              xxcoi_lot_reserve_info.chain_name%TYPE;
    lt_key_center_code             xxcoi_lot_reserve_info.center_code%TYPE;
    lt_key_center_name             xxcoi_lot_reserve_info.center_name%TYPE;
    lt_key_area_code               xxcoi_lot_reserve_info.area_code%TYPE;
    lt_key_area_name               xxcoi_lot_reserve_info.area_name%TYPE;
    lt_key_shipped_date            xxcoi_lot_reserve_info.shipped_date%TYPE;
    lt_key_arrival_date            xxcoi_lot_reserve_info.arrival_date%TYPE;
    lt_key_item_code               xxcoi_lot_reserve_info.item_code%TYPE;
    lt_key_item_name               xxcoi_lot_reserve_info.item_name%TYPE;
    lt_key_content                 xxcoi_lot_reserve_info.case_in_qty%TYPE;
    lt_key_reg_sal_cls_name_line   xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE;
    lt_key_item_div                xxcoi_lot_reserve_info.item_div%TYPE;
    lt_key_item_div_name           xxcoi_lot_reserve_info.item_div_name%TYPE;
    lt_key_location_code           xxcoi_lot_reserve_info.location_code%TYPE;
    lt_key_location_name           xxcoi_lot_reserve_info.location_name%TYPE;
    lt_key_lot                     xxcoi_lot_reserve_info.lot%TYPE;
    lt_key_difference_summary_code xxcoi_lot_reserve_info.difference_summary_code%TYPE;
    lt_key_shipping_sts_name       xxcoi_lot_reserve_info.shipping_status_name%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur
    IS
      SELECT
        xlri.base_code                  base_code                     --拠点コード
       ,xlri.base_name                  base_name                     --拠点名称
       ,xlri.whse_code                  whse_code                     --保管場所コード（倉庫）
       ,xlri.whse_name                  whse_name                     --保管場所名（倉庫名）
       ,xlri.chain_code                 chain_code                    --チェーン店コード
       ,xlri.chain_name                 chain_name                    --チェーン店名
       ,xlri.center_code                center_code                   --センターコード
       ,xlri.center_name                center_name                   --センター名
       ,xlri.area_code                  area_code                     --地区コード
       ,xlri.area_name                  area_name                     --地区名
       ,xlri.shipped_date               shipped_date                  --出荷日
       ,xlri.arrival_date               arrival_date                  --着日
       ,xlri.item_code                  item_code                     --商品コード
       ,xlri.item_name                  item_name                     --商品名
       ,xlri.case_in_qty                case_in_qty                   --入数
       ,xlri.case_qty                   case_qty                      --ケース
       ,xlri.singly_qty                 singly_qty                    --バラ
       ,xlri.summary_qty                summary_qty                   --数量
       ,xlri.regular_sale_class_line    regular_sale_class_line       --定番特売区分(明細)
       ,xlri.regular_sale_class_name_line regular_sale_class_name_line --定番特売区分名(明細)
       ,xlri.item_div                   item_div                      --商品区分
       ,xlri.item_div_name              item_div_name                 --商品区分名
       ,xlri.location_code              location_code                 --ロケーションコード
       ,xlri.location_name              location_name                 --ロケーション名称
       ,xlri.lot                        lot                           --ロット（賞味期限）
       ,xlri.difference_summary_code    difference_summary_code       --固有記号
       ,xlri.shipping_status            shipping_status               --出荷情報ステータス
       ,xlri.shipping_status_name       shipping_sts_name             --出荷情報ステータス名称
      FROM
        xxcoi_lot_reserve_info          xlri                          --ロット別引当情報
      WHERE
        xlri.base_code                  = gv_login_base_code 
      AND  ( gv_login_chain_store_code  IS NULL
        OR   xlri.chain_code            = gv_login_chain_store_code
           )
--  Add Ver1.1 S.Yamashita Start
      AND  ( gv_login_customer_code     IS NULL
        OR   xlri.customer_code         = gv_login_customer_code
           )
--  Add Ver1.1 S.Yamashita End
      AND    xlri.arrival_date    BETWEEN gd_request_date_from AND gd_request_date_to
      AND  ( gt_bargain_class           =  cv_bargain_class_all
        OR   xlri.regular_sale_class_line = gt_bargain_class
           )
      AND  ( gd_edi_received_date      IS NULL
        OR  ( xlri.edi_received_date   >= gd_edi_received_date
          AND xlri.edi_received_date    < gd_edi_received_date + 1
            )
          )
      AND  xlri.parent_shipping_status IN ( gt_shipping_sts_cd1
                                           ,gt_shipping_sts_cd2
                                           ,gt_shipping_sts_cd3
                                          )
      AND  ( gv_order_number           IS NULL
        OR   xlri.order_number          = gv_order_number
           )
      ORDER BY
        xlri.base_code                                                --拠点コード
       ,xlri.whse_code                                                --倉庫
       ,xlri.chain_code                                               --チェーン店コード
       ,xlri.center_code                                              --センターコード
       ,xlri.area_code                                                --地区コード
       ,xlri.shipped_date                                             --出荷日
       ,xlri.arrival_date                                             --着日
       ,xlri.regular_sale_class_line                                  --定番特売区分(明細)
       ,xlri.item_div                                                 --商品区分
       ,xlri.location_code                                            --ロケーションコード
       ,xlri.item_code                                                --商品コード
       ,xlri.lot                                                      --賞味期限
       ,xlri.difference_summary_code                                  --固有記号
      ;
--
    -- *** ローカル・レコード ***
    l_data_rec                          data_cur%ROWTYPE;
--
    -- *** ローカル・プロシージャ ***
    --==================================
    --キーブレイク項目セット
    --==================================
    PROCEDURE set_key_item
    IS
    BEGIN
      lt_key_base_code               := l_data_rec.base_code;
      lt_key_base_name               := l_data_rec.base_name;
      lt_key_whse_code               := l_data_rec.whse_code;
      lt_key_whse_name               := l_data_rec.whse_name ;
      lt_key_chain_code              := l_data_rec.chain_code;
      lt_key_chain_name              := l_data_rec.chain_name;
      lt_key_center_code             := l_data_rec.center_code;
      lt_key_center_name             := l_data_rec.center_name;
      lt_key_area_code               := l_data_rec.area_code;
      lt_key_area_name               := l_data_rec.area_name ;
      lt_key_shipped_date            := l_data_rec.shipped_date;
      lt_key_arrival_date            := l_data_rec.arrival_date;
      lt_key_item_code               := l_data_rec.item_code;
      lt_key_item_name               := l_data_rec.item_name;
      lt_key_content                 := l_data_rec.case_in_qty;
      lt_key_reg_sal_cls_name_line   := l_data_rec.regular_sale_class_name_line;
      lt_key_item_div                := l_data_rec.item_div;
      lt_key_item_div_name           := l_data_rec.item_div_name;
      lt_key_location_code           := l_data_rec.location_code;
      lt_key_location_name           := l_data_rec.location_name;
      lt_key_lot                     := l_data_rec.lot;
      lt_key_difference_summary_code := l_data_rec.difference_summary_code;
      lt_key_shipping_sts_name       := l_data_rec.shipping_sts_name;
    END;
--
    --==================================
    --内部テーブルセット
    --==================================
    PROCEDURE set_internal_table
    IS
    BEGIN
      -- レコードIDの取得
      BEGIN
        SELECT
          xxcos_rep_l_pick_chain_pro_s01.NEXTVAL          record_id
        INTO
          ln_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx := ln_idx + 1;
      --
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;
      g_rpt_data_tab(ln_idx).base_code                    := lt_key_base_code;
      g_rpt_data_tab(ln_idx).base_name                    := lt_key_base_name;
      g_rpt_data_tab(ln_idx).whse_code                    := lt_key_whse_code;
      g_rpt_data_tab(ln_idx).whse_name                    := lt_key_whse_name;
      g_rpt_data_tab(ln_idx).chain_code                   := lt_key_chain_code;
      g_rpt_data_tab(ln_idx).chain_name                   := lt_key_chain_name;
--  Add Ver1.1 S.Yamashita Start
      g_rpt_data_tab(ln_idx).customer_code                := gv_login_customer_code;
      g_rpt_data_tab(ln_idx).customer_name                := gv_login_customer_name;
--  Add Ver1.1 S.Yamashita End
      g_rpt_data_tab(ln_idx).center_code                  := lt_key_center_code;
      g_rpt_data_tab(ln_idx).center_name                  := lt_key_center_name;
      g_rpt_data_tab(ln_idx).area_code                    := lt_key_area_code;
      g_rpt_data_tab(ln_idx).area_name                    := lt_key_area_name;
      g_rpt_data_tab(ln_idx).shipped_date                 := lt_key_shipped_date;
      g_rpt_data_tab(ln_idx).arrival_date                 := lt_key_arrival_date;
      g_rpt_data_tab(ln_idx).item_code                    := lt_key_item_code;
      g_rpt_data_tab(ln_idx).item_name                    := lt_key_item_name;
      g_rpt_data_tab(ln_idx).content                      := lt_key_content;
      g_rpt_data_tab(ln_idx).case_num                     := ln_case_qty;
      g_rpt_data_tab(ln_idx).indivi                       := ln_singly_qty;
      g_rpt_data_tab(ln_idx).quantity                     := ln_summary_qty;
      g_rpt_data_tab(ln_idx).regular_sale_class_head      := gt_bargain_class_name;
      g_rpt_data_tab(ln_idx).regular_sale_class_line      := lt_key_reg_sal_cls_name_line;
      g_rpt_data_tab(ln_idx).edi_received_date            := gd_edi_received_date;
      g_rpt_data_tab(ln_idx).item_class                   := lt_key_item_div;
      g_rpt_data_tab(ln_idx).item_class_name              := lt_key_item_div_name;
      g_rpt_data_tab(ln_idx).location_code                := lt_key_location_code;
      g_rpt_data_tab(ln_idx).location_name                := lt_key_location_name;
      g_rpt_data_tab(ln_idx).lot                          := lt_key_lot;
      g_rpt_data_tab(ln_idx).difference_summary_code      := lt_key_difference_summary_code;
      g_rpt_data_tab(ln_idx).shipping_status              := lt_key_shipping_sts_name;
      g_rpt_data_tab(ln_idx).order_number                 := gv_order_number;
      g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
      g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
      g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
      g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
      g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
      g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
      g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
      g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
      g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
    END;
--
    --==================================
    --数量集計
    --==================================
    PROCEDURE add_quantity
    IS
    BEGIN
      --集計
      ln_case_qty    := ln_case_qty    + l_data_rec.case_qty;
      ln_singly_qty  := ln_singly_qty  + l_data_rec.singly_qty;
      ln_summary_qty := ln_summary_qty + l_data_rec.summary_qty;
    END;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 0.項目初期化
    --==================================
    ln_idx         := 0;
    ln_case_qty    := 0;
    ln_singly_qty  := 0;
    ln_summary_qty := 0;
    --
    lt_key_base_code               := NULL;                 --拠点コード
    lt_key_base_name               := NULL;                 --拠点名称
    lt_key_whse_code               := NULL;                 --倉庫
    lt_key_whse_name               := NULL;                 --倉庫名
    lt_key_chain_code              := NULL;                 --チェーン店コード
    lt_key_chain_name              := NULL;                 --チェーン店名
    lt_key_center_code             := NULL;                 --センターコード
    lt_key_center_name             := NULL;                 --センター名
    lt_key_area_code               := NULL;                 --地区コード
    lt_key_area_name               := NULL;                 --地区名
    lt_key_shipped_date            := NULL;                 --出荷日
    lt_key_arrival_date            := NULL;                 --着日
    lt_key_item_code               := NULL;                 --商品コード
    lt_key_item_name               := NULL;                 --商品名
    lt_key_content                 := NULL;                 --入数
    lt_key_reg_sal_cls_name_line   := NULL;                 --定番特売区分
    lt_key_item_div                := NULL;                 --商品区分
    lt_key_item_div_name           := NULL;                 --商品区分名
    lt_key_location_code           := NULL;                 --ロケーションコード
    lt_key_location_name           := NULL;                 --ロケーション名
    lt_key_lot                     := NULL;                 --賞味期限
    lt_key_difference_summary_code := NULL;                 --固有記号
    lt_key_shipping_sts_name       := NULL;                 --出荷情報ステータス
--
    --==================================
    -- 1.データ取得
    --==================================
    <<loop_get_data>>
    FOR l_get_data_rec IN data_cur
    LOOP
      l_data_rec := l_get_data_rec;
      IF ( (  lt_key_base_code               IS NULL )      --拠点コード
        AND ( lt_key_base_name               IS NULL )      --拠点名称
        AND ( lt_key_whse_code               IS NULL )      --倉庫
        AND ( lt_key_whse_name               IS NULL )      --倉庫名
        AND ( lt_key_chain_code              IS NULL )      --チェーン店コード
        AND ( lt_key_chain_name              IS NULL )      --チェーン店名
        AND ( lt_key_center_code             IS NULL )      --センターコード
        AND ( lt_key_center_name             IS NULL )      --センター名
        AND ( lt_key_area_code               IS NULL )      --地区コード
        AND ( lt_key_area_name               IS NULL )      --地区名
        AND ( lt_key_shipped_date            IS NULL )      --出荷日
        AND ( lt_key_arrival_date            IS NULL )      --着日
        AND ( lt_key_item_code               IS NULL )      --商品コード
        AND ( lt_key_item_name               IS NULL )      --商品名
        AND ( lt_key_content                 IS NULL )      --入数
        AND ( lt_key_reg_sal_cls_name_line   IS NULL )      --定番特売区分
        AND ( lt_key_item_div                IS NULL )      --商品区分
        AND ( lt_key_item_div_name           IS NULL )      --商品区分名
        AND ( lt_key_location_code           IS NULL )      --ロケーションコード
        AND ( lt_key_location_name           IS NULL )      --ロケーション名
        AND ( lt_key_lot                     IS NULL )      --賞味期限
        AND ( lt_key_difference_summary_code IS NULL )      --固有記号
        AND ( lt_key_shipping_sts_name       IS NULL ) )    --出荷情報ステータス
      THEN
        --キーブレイク項目セット
        set_key_item;
        --数量集計
        add_quantity;
      ELSE
        IF ( (  comp_char(lt_key_base_code               , l_data_rec.base_code))               --拠点コード
          AND ( comp_char(lt_key_base_name               , l_data_rec.base_name))               --拠点名称
          AND ( comp_char(lt_key_whse_code               , l_data_rec.whse_code))               --倉庫
          AND ( comp_char(lt_key_whse_name               , l_data_rec.whse_name))               --倉庫名
          AND ( comp_char(lt_key_chain_code              , l_data_rec.chain_code))              --チェーン店コード
          AND ( comp_char(lt_key_chain_name              , l_data_rec.chain_name))              --チェーン店名
          AND ( comp_char(lt_key_center_code             , l_data_rec.center_code))             --センターコード
          AND ( comp_char(lt_key_center_name             , l_data_rec.center_name))             --センター名
          AND ( comp_char(lt_key_area_code               , l_data_rec.area_code))               --地区コード
          AND ( comp_char(lt_key_area_name               , l_data_rec.area_name))               --地区名
          AND ( comp_date(lt_key_shipped_date            , l_data_rec.shipped_date))            --出荷日
          AND ( comp_date(lt_key_arrival_date            , l_data_rec.arrival_date))            --着日
          AND ( comp_char(lt_key_item_code               , l_data_rec.item_code))               --商品コード
          AND ( comp_char(lt_key_item_name               , l_data_rec.item_name))               --商品名
          AND ( comp_num (lt_key_content                 , l_data_rec.case_in_qty))             --入数
          AND ( comp_char(lt_key_reg_sal_cls_name_line   , l_data_rec.regular_sale_class_name_line)) --定番特売区分
          AND ( comp_char(lt_key_item_div                , l_data_rec.item_div))                --商品区分
          AND ( comp_char(lt_key_item_div_name           , l_data_rec.item_div_name))           --商品区分名
          AND ( comp_char(lt_key_location_code           , l_data_rec.location_code))           --ロケーションコード
          AND ( comp_char(lt_key_location_name           , l_data_rec.location_name))           --ロケーション名
          AND ( comp_char(lt_key_lot                     , l_data_rec.lot))                     --賞味期限
          AND ( comp_char(lt_key_difference_summary_code , l_data_rec.difference_summary_code)) --固有記号
          AND ( comp_char(lt_key_shipping_sts_name       , l_data_rec.shipping_sts_name)))      --出荷情報ステータス
        THEN
          --数量集計
          add_quantity;
        ELSE
          --内部テーブルセット
          set_internal_table;
          --初期化
          lt_key_content := NULL;
          ln_case_qty    := 0;
          ln_singly_qty  := 0;
          ln_summary_qty := 0;
          --キーブレイク項目セット
          set_key_item;
          --換算数量
          add_quantity;
        END IF;
--
      END IF;
--
    END LOOP loop_get_data;
--
    --==================================
    -- 2.キーブレイク項目のチェック
    --==================================
    IF ( (  lt_key_base_code               IS NULL )      --拠点コード
      AND ( lt_key_base_name               IS NULL )      --拠点名称
      AND ( lt_key_whse_code               IS NULL )      --倉庫
      AND ( lt_key_whse_name               IS NULL )      --倉庫名
      AND ( lt_key_chain_code              IS NULL )      --チェーン店コード
      AND ( lt_key_chain_name              IS NULL )      --チェーン店名
      AND ( lt_key_center_code             IS NULL )      --センターコード
      AND ( lt_key_center_name             IS NULL )      --センター名
      AND ( lt_key_area_code               IS NULL )      --地区コード
      AND ( lt_key_area_name               IS NULL )      --地区名
      AND ( lt_key_shipped_date            IS NULL )      --出荷日
      AND ( lt_key_arrival_date            IS NULL )      --着日
      AND ( lt_key_item_code               IS NULL )      --商品コード
      AND ( lt_key_item_name               IS NULL )      --商品名
      AND ( lt_key_content                 IS NULL )      --入数
      AND ( lt_key_reg_sal_cls_name_line   IS NULL )      --定番特売区分
      AND ( lt_key_item_div                IS NULL )      --商品区分
      AND ( lt_key_item_div_name           IS NULL )      --商品区分名
      AND ( lt_key_location_code           IS NULL )      --ロケーションコード
      AND ( lt_key_location_name           IS NULL )      --ロケーション名
      AND ( lt_key_lot                     IS NULL )      --賞味期限
      AND ( lt_key_difference_summary_code IS NULL )      --固有記号
      AND ( lt_key_shipping_sts_name       IS NULL ) )    --出荷情報ステータス
    THEN
      --初回取得データなし
      NULL;
    ELSE
      --最終取得レコードの内部テーブルセット
      set_internal_table;
    END IF;
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --対象件数
      gn_target_cnt := g_rpt_data_tab.COUNT;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-4)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    --==================================
    -- 1.帳票ワークテーブル登録処理
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT
      INSERT INTO
        xxcos_rep_lot_pick_chain_pro
      VALUES
        g_rpt_data_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- 正常件数
    gn_normal_cnt := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_insert_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : ＳＶＦ起動(A-5)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_svf_api       VARCHAR2(5000);
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
    --==================================
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg             := xxccp_common_pkg.get_msg(
                                   iv_application          => ct_xxcos_appl_short_name
                                  ,iv_name                 => ct_msg_nodata_err
                                 );
--
    lv_file_name              := cv_file_id ||
                                   TO_CHAR( SYSDATE, cv_fmt_date8 ) ||
                                   TO_CHAR( cn_request_id ) ||
                                   cv_extension_pdf
                                 ;
    --==================================
    -- 2.SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode
     ,ov_errbuf               => lv_errbuf
     ,ov_errmsg               => lv_errmsg
     ,iv_conc_name            => cv_conc_name
     ,iv_file_name            => lv_file_name
     ,iv_file_id              => cv_file_id
     ,iv_output_mode          => cv_output_mode_pdf
     ,iv_frm_file             => cv_frm_file
     ,iv_vrq_file             => cv_vrq_file
     ,iv_org_id               => NULL
     ,iv_user_name            => NULL
     ,iv_resp_name            => NULL
     ,iv_doc_name             => NULL
     ,iv_printer_name         => NULL
     ,iv_request_id           => TO_CHAR( cn_request_id )
     ,iv_nodata_msg           => lv_nodata_msg
     ,iv_svf_param1           => NULL
     ,iv_svf_param2           => NULL
     ,iv_svf_param3           => NULL
     ,iv_svf_param4           => NULL
     ,iv_svf_param5           => NULL
     ,iv_svf_param6           => NULL
     ,iv_svf_param7           => NULL
     ,iv_svf_param8           => NULL
     ,iv_svf_param9           => NULL
     ,iv_svf_param10          => NULL
     ,iv_svf_param11          => NULL
     ,iv_svf_param12          => NULL
     ,iv_svf_param13          => NULL
     ,iv_svf_param14          => NULL
     ,iv_svf_param15          => NULL
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt THEN
      lv_svf_api              := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_call_api_err
                                  ,iv_token_name1        => cv_tkn_api_name
                                  ,iv_token_value1       => lv_svf_api
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-6)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT
        xrlpcp.record_id                record_id
      FROM
        xxcos_rep_lot_pick_chain_pro    xrlpcp              --ロット別ピックリスト_チェーン・製品別トータル帳票ワークテーブル
      WHERE
        xrlpcp.request_id               = cn_request_id     --要求ID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.帳票ワークテーブルデータロック
    --==================================
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.帳票ワークテーブル削除
    --==================================
    BEGIN
      DELETE FROM
        xxcos_rep_lot_pick_chain_pro    xrlpcp
      WHERE
        xrlpcp.request_id               = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --要求ID文字列取得
        lv_key_info           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_request
                                  ,iv_token_name1        => cv_tkn_request
                                  ,iv_token_value1       => TO_CHAR( cn_request_id )
                                 );
--
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_lock_err
                                  ,iv_token_name1        => cv_tkn_table
                                  ,iv_token_value1       => lv_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name
                                  ,iv_name               => ct_msg_delete_data_err
                                  ,iv_token_name1        => cv_tkn_table_name
                                  ,iv_token_value1       => lv_table_name
                                  ,iv_token_name2        => cv_tkn_key_data
                                  ,iv_token_value2       => lv_key_info
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_login_base_code        IN    VARCHAR2         -- 1.拠点
   ,iv_login_chain_store_code IN    VARCHAR2         -- 2.チェーン店
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN    VARCHAR2         -- 3.顧客
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN    VARCHAR2         -- 4.着日（From）
   ,iv_request_date_to        IN    VARCHAR2         -- 5.着日（To）
   ,iv_bargain_class          IN    VARCHAR2         -- 6.定番特売区分
   ,iv_edi_received_date      IN    VARCHAR2         -- 7.EDI受信日
   ,iv_shipping_status        IN    VARCHAR2         -- 8.ステータス
   ,iv_order_number           IN    VARCHAR2         -- 9.受注番号
   ,ov_errbuf                 OUT   VARCHAR2         -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT   VARCHAR2         -- リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT   VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
--
--###########################  固定部 END   ####################################
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
      iv_login_base_code        => iv_login_base_code          -- 1.拠点
     ,iv_login_chain_store_code => iv_login_chain_store_code   -- 2.チェーン店
--  Add Ver1.1 S.Yamashita Start
     ,iv_login_customer_code    => iv_login_customer_code      -- 3.顧客
--  Add Ver1.1 S.Yamashita End
     ,iv_request_date_from      => iv_request_date_from        -- 4.着日（From）
     ,iv_request_date_to        => iv_request_date_to          -- 5.着日（To）
     ,iv_bargain_class          => iv_bargain_class            -- 6.定番特売区分
     ,iv_edi_received_date      => iv_edi_received_date        -- 7.EDI受信日
     ,iv_shipping_status        => iv_shipping_status          -- 8.ステータス
     ,iv_order_number           => iv_order_number             -- 9.受注番号
     ,ov_errbuf                 => lv_errbuf                   -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                  -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  パラメータチェック処理
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf                   -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                  -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  データ取得
    -- ===============================
    get_data(
      ov_errbuf                 => lv_errbuf                   -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                  -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  帳票ワークテーブル登録
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf                   -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                  -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-5  ＳＶＦ起動
    -- ===============================
    execute_svf(
      ov_errbuf                 => lv_errbuf                   -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                  -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
--
    -- ===============================
    -- A-6  帳票ワークテーブル削除
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf                   -- エラー・メッセージ
     ,ov_retcode                => lv_retcode                  -- リターン・コード
     ,ov_errmsg                 => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
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
    errbuf                    OUT     VARCHAR2     --   エラー・メッセージ  --# 固定 #
   ,retcode                   OUT     VARCHAR2     --   リターン・コード    --# 固定 #
   ,iv_login_base_code        IN      VARCHAR2     -- 1.拠点
   ,iv_login_chain_store_code IN      VARCHAR2     -- 2.チェーン店
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN      VARCHAR2     -- 3.顧客
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN      VARCHAR2     -- 4.着日（From）
   ,iv_request_date_to        IN      VARCHAR2     -- 5.着日（To）
   ,iv_bargain_class          IN      VARCHAR2     -- 6.定番特売区分
   ,iv_edi_received_date      IN      VARCHAR2     -- 7.EDI受信日
   ,iv_shipping_status        IN      VARCHAR2     -- 8.ステータス
   ,iv_order_number           IN      VARCHAR2     -- 9.受注番号
  )
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
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
      iv_which    => cv_log_header_log
     ,ov_retcode  => lv_retcode
     ,ov_errbuf   => lv_errbuf
     ,ov_errmsg   => lv_errmsg
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
       iv_login_base_code                  -- 1.拠点
      ,iv_login_chain_store_code           -- 2.チェーン店
--  Add Ver1.1 S.Yamashita Start
      ,iv_login_customer_code              -- 3.顧客
--  Add Ver1.1 S.Yamashita End
      ,iv_request_date_from                -- 4.着日（From）
      ,iv_request_date_to                  -- 5.着日（To）
      ,iv_bargain_class                    -- 6.定番特売区分
      ,iv_edi_received_date                -- 7.EDI受信日
      ,iv_shipping_status                  -- 8.ステータス
      ,iv_order_number                     -- 9.受注番号
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      gn_error_cnt := 1;
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
       ,buff    => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
       ,buff    => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG
     ,buff    => NULL
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => gv_out_msg
    );
    --
    --1行空白
    fnd_file.put_line(
      which => FND_FILE.LOG
     ,buff  => NULL
    );
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
END XXCOS012A05R;
/
