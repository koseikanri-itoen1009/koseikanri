CREATE OR REPLACE PACKAGE BODY XXCOS019A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS019A02C(body)
 * Description      : クローズされていない受注のクローズ情報を作成します。
 * MD.050           : 未クローズ受注自動クローズ (MD050_COS_019_A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_data               対象情報取得(A-2)
 *  ins_order_close        受注クローズ対象情報登録(A-3)
 *  upd_flag               販売実績連携済フラグ更新(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/04/17    1.0   SCSK K.Nakamura  新規作成
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
  global_lock_expt          EXCEPTION; -- ロック例外
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  warn_expt                 EXCEPTION; -- 警告
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS019A02C'; -- パッケージ名
  cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';        -- アプリケーション名
  cv_appl_short_name        CONSTANT VARCHAR2(5)   := 'XXCCP';        -- アドオン：共通・IF領域
  -- メッセージ
  cv_msg_no_param           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなし
  cv_msg_lock_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001'; -- ロックエラー
  cv_msg_no_data            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003'; -- 対象データ無し
  cv_msg_profile_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  cv_msg_insert_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010'; -- データ登録エラー
  cv_msg_update_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011'; -- データ更新エラー
  cv_msg_process_date_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  cv_msg_profile_miss1_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14401'; -- プロファイル設定値不備エラー1
  cv_msg_profile_miss2_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14402'; -- プロファイル設定値不備エラー2
  cv_msg_order_source_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14403'; -- 受注ソース取得エラー
  -- メッセージ文字列
  cv_edi_order_source       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00157'; -- XXCOS:EDI受注ソース
  cv_org                    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047'; -- MO:営業単位
  cv_order_close_from       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14404'; -- XXCOS:受注CLOSED対象期間FROM
  cv_order_close_to         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14405'; -- XXCOS:受注CLOSED対象期間TO
  cv_order_lines_all        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14406'; -- 受注明細テーブル
  cv_xxcos_order_close      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14407'; -- 受注クローズ対象情報テーブル
  cv_line_id                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14408'; -- 受注明細ID：
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(20)  := 'PROFILE';           -- プロファイル名
  cv_tkn_profile1           CONSTANT VARCHAR2(20)  := 'PROFILE1';          -- プロファイル名
  cv_tkn_profile2           CONSTANT VARCHAR2(20)  := 'PROFILE2';          -- プロファイル名
  cv_tkn_order_source_name  CONSTANT VARCHAR2(20)  := 'ORDER_SOURCE_NAME'; -- 受注ソース名
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';             -- テーブル名
  cv_tkn_table_name         CONSTANT VARCHAR2(20)  := 'TABLE_NAME';        -- テーブル名
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';          -- キー項目
  -- プロファイル
  cv_prf_order_close_from   CONSTANT VARCHAR2(30)  := 'XXCOS1_OM_CLOSED_FROM';   -- XXCOS:受注CLOSED対象期間FROM
  cv_prf_order_close_to     CONSTANT VARCHAR2(30)  := 'XXCOS1_OM_CLOSED_TO';     -- XXCOS:受注CLOSED対象期間TO
  cv_prf_edi_order_source   CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_ORDER_SOURCE'; -- XXCOS:EDI受注ソース
  cv_prf_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                  -- MO:営業単位
  -- クイックコードタイプ
  cv_lookup_hokan_type      CONSTANT VARCHAR2(30)  := 'XXCOS1_HOKAN_TYPE_MST_019_A02'; -- 保管場所分類特定マスタ_019_A02
  -- クイックコード
  cv_lookup_hokan_code      CONSTANT VARCHAR2(30)  := 'XXCOS_019_A02%';
  -- ステータス
  cv_yes                    CONSTANT VARCHAR2(1)   := 'Y';      -- フラグ：Y
  cv_order_close_status     CONSTANT VARCHAR2(1)   := 'N';      -- 受注クローズテーブルステータス：未処理
  cv_global_attribute5      CONSTANT VARCHAR2(1)   := 'Z';      -- 販売実績連携済フラグ：未連携
  cv_booked                 CONSTANT VARCHAR2(10)  := 'BOOKED'; -- 受注ステータス：記帳済
  --言語コード
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_edi_order_source_id    NUMBER         DEFAULT NULL; -- XXCOS:EDI受注ソース
  gn_org_id                 NUMBER         DEFAULT NULL; -- 営業単位
  gd_process_date           DATE           DEFAULT NULL; -- 業務日付
  gd_order_close_date_max   DATE           DEFAULT NULL; -- XXCOS:受注CLOSED対象期間FROM
  gd_order_close_date_min   DATE           DEFAULT NULL; -- XXCOS:受注CLOSED対象期間TO
  gv_msg1                   VARCHAR2(2000) DEFAULT NULL; -- メッセージ用1
  gv_msg2                   VARCHAR2(2000) DEFAULT NULL; -- メッセージ用2
--
  -- ===============================
  -- ユーザー定義グローバルレコード定義
  -- ===============================
  TYPE line_id_ttype IS TABLE OF oe_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  gt_line_id_tab            line_id_ttype;
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
    -- *** ローカル変数 ***
    lv_edi_order_source     VARCHAR2(10) DEFAULT NULL; -- XXCOS:EDI受注ソース
    ln_order_close_from     NUMBER       DEFAULT NULL; -- XXCOS:受注CLOSED対象期間FROM
    ln_order_close_to       NUMBER       DEFAULT NULL; -- XXCOS:受注CLOSED対象期間TO
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    -- =====================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_msg_no_param
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- =====================================================
    -- 業務処理日付取得
    -- =====================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- 業務処理日付取得に失敗した場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application
                    ,iv_name        => cv_msg_process_date_err
                   );
      RAISE warn_expt;
      --
    END IF;
--
    -- =====================================================
    -- プロファイルの取得(XXCOS:受注CLOSED対象期間FROM)
    -- =====================================================
    BEGIN
      ln_order_close_from := TO_NUMBER( FND_PROFILE.VALUE(cv_prf_order_close_from) );
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_order_close_from
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => gv_msg1
                     );
        RAISE warn_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( ln_order_close_from IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_from
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
    -- プロファイル値がマイナス値の場合
    IF ( ln_order_close_from < 0 ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_from
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_miss1_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- プロファイルの取得(XXCOS:受注CLOSED対象期間TO)
    -- =====================================================
    BEGIN
      ln_order_close_to := TO_NUMBER( FND_PROFILE.VALUE(cv_prf_order_close_to) );
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_order_close_to
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => gv_msg1
                     );
        RAISE warn_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( ln_order_close_to IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_to
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
    -- プロファイル値がマイナス値の場合
    IF ( ln_order_close_to < 0 ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_to
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_miss1_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- プロファイル値が不正の場合
    IF ( ln_order_close_from < ln_order_close_to ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_to
                   );
      gv_msg2   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_from
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_miss2_err
                     ,iv_token_name1  => cv_tkn_profile1
                     ,iv_token_value1 => gv_msg1
                     ,iv_token_name2  => cv_tkn_profile2
                     ,iv_token_value2 => gv_msg2
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- プロファイルの取得(XXCOS:EDI受注ソース)
    -- =====================================================
    lv_edi_order_source := FND_PROFILE.VALUE(cv_prf_edi_order_source);
    -- プロファイル値がNULLの場合
    IF ( lv_edi_order_source IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_edi_order_source
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- プロファイルの取得(MO:営業単位)
    -- =====================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE(cv_prf_org_id) );
    -- プロファイル値がNULLの場合
    IF ( gn_org_id IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_org
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- 受注クローズ対象年月日の取得
    -- =====================================================
    gd_order_close_date_max := gd_process_date - ln_order_close_from;
    gd_order_close_date_min := gd_process_date - ln_order_close_to;
--
    -- =====================================================
    -- 受注ソースIDの取得
    -- =====================================================
    BEGIN
      SELECT oos.order_source_id  order_source_id -- 受注ソースID
      INTO   gn_edi_order_source_id
      FROM   oe_order_sources     oos             -- 受注ソース
      WHERE  oos.name = lv_edi_order_source       -- 名称
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_order_source_err
                       ,iv_token_name1  => cv_tkn_order_source_name
                       ,iv_token_value1 => lv_edi_order_source
                     );
        RAISE warn_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 警告例外ハンドラ ****
    WHEN warn_expt THEN
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
   * Procedure Name   : get_data
   * Description      : 対象情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 対象取得
    -- =====================================================
    SELECT /*+ USE_NL(ooha oola msi)
            */
           oola.line_id               line_id  -- 受注明細ID
    BULK COLLECT INTO gt_line_id_tab
    FROM   oe_order_headers_all       ooha     -- 受注ヘッダテーブル
         , oe_order_lines_all         oola     -- 受注明細テーブル
         , mtl_secondary_inventories  msi      -- 保管場所マスタ
    WHERE  ooha.header_id          = oola.header_id
    AND    ooha.org_id             = oola.org_id
    AND    oola.subinventory       = msi.secondary_inventory_name
    AND    oola.ship_from_org_id   = msi.organization_id
    AND    ooha.org_id             = gn_org_id
    AND    ooha.order_source_id    = gn_edi_order_source_id
    AND    ooha.flow_status_code   = cv_booked
    AND    oola.flow_status_code   = cv_booked
    AND    oola.request_date      >= gd_order_close_date_max
    AND    oola.request_date      <= gd_order_close_date_min
    AND EXISTS (
           SELECT 1                   attribute13
           FROM   fnd_lookup_values   flv      -- クイックコード
           WHERE  flv.lookup_type  = cv_lookup_hokan_type
           AND    flv.lookup_code  LIKE cv_lookup_hokan_code
           AND    flv.meaning      = msi.attribute13
           AND    gd_process_date >= NVL( flv.start_date_active, gd_process_date )
           AND    gd_process_date <= NVL( flv.end_date_active, gd_process_date )
           AND    flv.enabled_flag = cv_yes
           AND    flv.language     = ct_lang
               )
    FOR UPDATE OF oola.line_id NOWAIT
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application
                      ,iv_name        => cv_order_lines_all
                    );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_lock_err
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => gv_out_msg
                   );
      --
      lv_errbuf := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_order_close
   * Description      : 受注クローズ対象情報登録(A-3)
   ***********************************************************************************/
  PROCEDURE ins_order_close(
    it_line_id    IN  oe_order_lines_all.line_id%TYPE,  -- 受注明細ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_order_close'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
      -- =====================================================
      -- 受注クローズ対象情報登録
      -- =====================================================
      INSERT INTO xxcos_order_close(
         order_line_id              -- 受注明細ID
        ,process_status             -- 処理ステータス
        ,process_date               -- 処理日
        ,created_by                 -- 作成者
        ,creation_date              -- 作成日
        ,last_updated_by            -- 最終更新者
        ,last_update_date           -- 最終更新日
        ,last_update_login          -- 最終更新ログイン
        ,request_id                 -- 要求ID
        ,program_application_id     -- コンカレント・プログラム・アプリケーションID
        ,program_id                 -- コンカレント・プログラムID
        ,program_update_date        -- プログラム更新日
      )VALUES(
         it_line_id                 -- 受注明細ID
        ,cv_order_close_status      -- 処理ステータス
        ,gd_process_date            -- 処理日
        ,cn_created_by              -- 作成者
        ,cd_creation_date           -- 作成日
        ,cn_last_updated_by         -- 最終更新者
        ,cd_last_update_date        -- 最終更新日
        ,cn_last_update_login       -- 最終更新ログイン
        ,cn_request_id              -- 要求ID
        ,cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id              -- コンカレント・プログラムID
        ,cd_program_update_date     -- プログラム更新日
      );
    EXCEPTION
      -- *** 登録例外ハンドラ ****
      WHEN OTHERS THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_xxcos_order_close
                     );
        gv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_line_id
                       ,iv_token_name1  => cv_tkn_key_data
                       ,iv_token_value1 => TO_CHAR( it_line_id )
                     );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_insert_err
                       ,iv_token_name1  => cv_tkn_table_name
                       ,iv_token_value1 => gv_msg1
                       ,iv_token_name2  => cv_tkn_key_data
                       ,iv_token_value2 => gv_msg2
                     );
        --
        ov_errmsg   := lv_errmsg;
        ov_errbuf   := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ov_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ov_errbuf
        );
    END;
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
  END ins_order_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_flag
   * Description      : 販売実績連携済フラグ更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_flag(
    it_line_id    IN  oe_order_lines_all.line_id%TYPE,  -- 受注明細ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_flag'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
      -- =====================================================
      -- 販売実績連携済フラグ更新
      -- =====================================================
      UPDATE oe_order_lines_all oola
      SET    oola.global_attribute5 = cv_global_attribute5
      WHERE  oola.line_id           = it_line_id
      ;
    EXCEPTION
      -- *** 更新例外ハンドラ ****
      WHEN OTHERS THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_order_lines_all
                     );
        gv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_line_id
                       ,iv_token_name1  => cv_tkn_key_data
                       ,iv_token_value1 => TO_CHAR( it_line_id )
                     );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_update_err
                       ,iv_token_name1  => cv_tkn_table_name
                       ,iv_token_value1 => gv_msg1
                       ,iv_token_name2  => cv_tkn_key_data
                       ,iv_token_value2 => gv_msg2
                     );
        --
        ov_errmsg   := lv_errmsg;
        ov_errbuf   := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ov_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ov_errbuf
        );
    END;
--
  EXCEPTION
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
      ov_retcode := cv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
--
--#####################################  固定部 END   ##########################################
--
  END upd_flag;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.対象情報取得
    -- ===============================
    get_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    <<ins_upd_loop>>
    FOR i IN 1..gt_line_id_tab.COUNT LOOP
      -- セーブポイント発行
      SAVEPOINT order_close;
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
      -- 初期化
      lv_retcode := cv_status_normal;
      -- ===============================
      -- A-3.受注クローズ対象情報登録
      -- ===============================
      ins_order_close(
        gt_line_id_tab(i), -- 受注明細ID
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================
        -- A-4.販売実績作成済フラグ更新
        -- ===============================
        upd_flag(
          gt_line_id_tab(i), -- 受注明細ID
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --
        IF ( lv_retcode = cv_status_normal ) THEN
          -- 成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイントまでロールバック
          ROLLBACK TO SAVEPOINT order_close;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
    --
    END LOOP ins_upd_loop;
--
    -- 対象件数なし
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_no_data
                   );
      --
      lv_errbuf := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
    -- 警告件数が存在する場合、終了ステータスを警告へ
    ELSIF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN warn_expt THEN
      ov_retcode := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- 警告件数メッセージ
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt    := 0;
      gn_normal_cnt    := 0;
      gn_warn_cnt      := 0;
      gn_error_cnt     := 1;
      --
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
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
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
END XXCOS019A02C;
/
