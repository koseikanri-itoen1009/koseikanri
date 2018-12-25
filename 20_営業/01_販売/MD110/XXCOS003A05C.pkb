CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A05C(body)
 * Description      : 単価マスタIF出力（ファイル作成）
 * MD.050           : 単価マスタIF出力（ファイル作成） MD050_COS_003_A05
 * Version          : 1.6
 *
 * Program List     
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  proc_main_loop         ループ部 A-2データ抽出
 *  proc_get_price_list    価格表情報取得(A-6)
 *  proc_put_price_list    価格表情報出力(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05   1.0    K.Okaguchi       新規作成
 *  2009/01/17   1.1    K.Okaguchi       [障害COS_124] ファイル出力編集のバグを修正
 *  2009/02/24   1.2    T.Nakamura       [障害COS_130] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/04/15   1.3    N.Maeda          [ST障害No.T1_0067対応] ファイル出力時のCHAR型VARCHAR型以外への｢"｣付加の削除
 *  2009/04/22   1.4    N.Maeda          [ST障害No.T1_0754対応]ファイル出力時の｢"｣付加修正
 *  2009/08/31   1.5    M.Sano           [SCS障害No.0000428対応]PT対応
 *  2017/03/27   1.6    S.Niki           [E_本稼動_14024対応]統一価格表情報を連携データに追加
 *  2018/11/22   1.7    Y.Sasaki         [E_本稼動_15411対応]納品日が1年以上過ぎた各履歴の数量サインにブランクを設定
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
  gn_target_cnt    NUMBER DEFAULT 0;                    -- 対象件数
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- 正常件数
  gn_error_cnt     NUMBER DEFAULT 0;                    -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- スキップ件数
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
  global_data_check_expt    EXCEPTION;     -- データチェック時のエラー
  file_open_expt            EXCEPTION;     -- ファイルオープンエラー
  update_expt               EXCEPTION;     -- 更新エラー
-- Ver.1.6 Add Start
  insert_expt               EXCEPTION;     -- 登録エラー
-- Ver.1.6 Add End
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A05C'; -- パッケージ名
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- アプリケーション名
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- アドオン：共通・IF領域
  cv_delimit              CONSTANT VARCHAR2(1)  := ',';            -- 区切り文字
  cv_quot                 CONSTANT VARCHAR2(1)  := '"';            -- コーテーション
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_brank                CONSTANT VARCHAR2(1)  := ' ';
  cv_minus                CONSTANT VARCHAR2(1)  := '-';
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ロックエラー
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
  cv_tkn_filename         CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    --ロック取得エラー
  cv_msg_pro              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    --プロファイル取得エラー
  cv_msg_file_open        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    --ファイルオープンエラーメッセージ
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    --データ更新エラーメッセージ
  cv_msg_filename         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    --ファイル名（タイトル）
-- Ver.1.6 Add Start
  cv_msg_org_id_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00091';    -- 在庫組織ID取得エラー
  cv_msg_proc_date_err    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';    -- 業務日付取得エラー
  cv_msg_insert_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';    -- データ登録エラーメッセージ
  cv_msg_price_list_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10855';    -- 価格表未設定エラーメッセージ
  cv_msg_plst_cnt_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10856';    -- 統一価格表件数メッセージ
-- Ver.1.6 Add End
  cv_tkn_dir_path         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10662';    -- HHTアウトバウンド用ディレクトリパス
  cv_tkn_tm_filename      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10851';    -- 単価マスタファイル名
  cv_tkn_tm_w_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10852';    -- 単価マスタワークテーブル  
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- 顧客コード
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- 品名コード
-- Ver.1.6 Add Start
  cv_tkn_org              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';    -- MO:営業単位
  cv_tkn_organization     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00048';    -- XXCOI:在庫組織コード
  cv_tkn_pl_t_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10857';    -- 価格表HHT連携一時表
  cv_tkn_target_from      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10858';    -- XXCOS:統一価格表対象期間FROM
  cv_tkn_target_to        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10859';    -- XXCOS:統一価格表対象期間TO
-- Ver.1.6 Add End
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- パラメータなし
  cv_prf_dir_path         CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_HHT_DIR';      -- HHTアウトバウンド用ディレクトリパス
  cv_prf_tm_filename      CONSTANT VARCHAR2(50) := 'XXCOS1_UNIT_PRICE_M_FILE_NAME';-- 単価マスタファイル名
-- Ver.1.6 Add Start
  cv_prf_org              CONSTANT VARCHAR2(50) := 'ORG_ID';                    -- MO:営業単位
  cv_prf_target_from      CONSTANT VARCHAR2(50) := 'XXCOS1_003A05_TARGET_FROM'; -- XXCOS:統一価格表対象期間FROM
  cv_prf_target_to        CONSTANT VARCHAR2(50) := 'XXCOS1_003A05_TARGET_TO';   -- XXCOS:統一価格表対象期間TO
  cv_prf_organization     CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
-- Ver.1.6 Add End
  cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';                -- プロファイル名
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';              -- ファイル名
-- Ver.1.6 Add Start
  cv_tkn_org_code_tok     CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';           -- 在庫組織コード
  cv_tkn_cnt1             CONSTANT VARCHAR2(20) := 'COUNT1';                 -- 件数1
  cv_tkn_cnt2             CONSTANT VARCHAR2(20) := 'COUNT2';                 -- 件数2
  cv_tkn_cnt3             CONSTANT VARCHAR2(20) := 'COUNT3';                 -- 件数3
  cv_tkn_cnt4             CONSTANT VARCHAR2(20) := 'COUNT4';                 -- 件数4
  cv_tkn_cnt5             CONSTANT VARCHAR2(20) := 'COUNT5';                 -- 件数5
  cv_qck_typ_cust_sts     CONSTANT VARCHAR2(30) := 'XXCOS1_CUS_STATUS_MST_001_A01';
                                                                             -- 顧客ステータス
  cv_qck_typ_item_sts     CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_STATUS_MST_001_A01';
                                                                             -- 品目ステータス
  cv_qck_typ_a01          CONSTANT VARCHAR2(30) := 'XXCOS_001_A01_%';
  cv_date_fmt_yyyymmdd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';               -- 日付書式：YYYYMMDD
  cv_date_fmt_full        CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';  -- 日付書式：YYYY/MM/DD HH24:MI:SS
  cv_site_use_ship        CONSTANT VARCHAR2(7)  := 'SHIP_TO';                -- 顧客使用目的：出荷先
  cv_status_active        CONSTANT VARCHAR2(1)  := 'A';                      -- 有効フラグ：有効
  cv_prdct_attribute1     CONSTANT VARCHAR2(18) := 'PRICING_ATTRIBUTE1';     -- 製品属性：品目番号
  cv_sales_target_on      CONSTANT VARCHAR2(1)  := '1';                      -- 売上対象区分：売上対象
  cv_p_list_div_nml       CONSTANT VARCHAR(1)   := '1';                      -- 価格表区分：通常
  cv_p_list_div_sls       CONSTANT VARCHAR(1)   := '2';                      -- 価格表区分：特売
  cv_s_date_dummy         CONSTANT VARCHAR(8)   := '00000000';               -- 適用開始年月日ダミー
  cv_e_date_dummy         CONSTANT VARCHAR(8)   := '99999999';               -- 適用終了年月日ダミー
  cn_zero                 CONSTANT NUMBER       := 0;                        -- 数値：0
  ct_lang                 CONSTANT fnd_lookup_values.language%TYPE
                                                := USERENV( 'LANG' );        -- 言語
-- Ver.1.6 Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--メッセージ出力用キー情報
  gv_msg_tkn_dir_path         fnd_new_messages.message_text%TYPE   ;--'HHTアウトバウンド用ディレクトリパス'
  gv_msg_tkn_tm_filename      fnd_new_messages.message_text%TYPE   ;--'単価マスタファイル名'☆
  gv_msg_tkn_tm_w_tbl         fnd_new_messages.message_text%TYPE   ;--'単価マスタワークテーブル'☆
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ;--'顧客コード'☆
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ;--'品名コード'☆
-- Ver.1.6 Add Start
  gv_msg_tkn_org              fnd_new_messages.message_text%TYPE   ;--'MO:営業単位'
  gv_msg_tkn_target_from      fnd_new_messages.message_text%TYPE   ;--'XXCOS:統一価格表対象期間FROM'
  gv_msg_tkn_target_to        fnd_new_messages.message_text%TYPE   ;--'XXCOS:統一価格表対象期間TO'
  gv_msg_tkn_organization     fnd_new_messages.message_text%TYPE   ;--'XXCOI:在庫組織コード'
  gv_msg_tkn_pl_t_tbl         fnd_new_messages.message_text%TYPE   ;--'価格表HHT連携一時表'
-- Ver.1.6 Add End
  gv_tm_file_data             VARCHAR2(2000);
  gd_process_date             DATE;
-- Ver.1.6 Add Start
  gd_process_date2            DATE;              -- 業務日付
  gd_target_date_from         DATE;              -- 対象日FROM
  gd_target_date_to           DATE;              -- 対象日TO
  gn_org_id                   NUMBER;            -- 営業単位ID
  gn_target_from              NUMBER;            -- 統一価格表対象期間FROM
  gn_target_to                NUMBER;            -- 統一価格表対象期間TO
  gn_organization_id          NUMBER;            -- 在庫組織ID
  gn_tgt_cust_cnt             NUMBER DEFAULT 0;  -- 統一価格表対象顧客件数
  gn_skp_cust_cnt             NUMBER DEFAULT 0;  -- 警告顧客件数
  gn_nml_plst_cnt             NUMBER DEFAULT 0;  -- 標準価格表取得件数
  gn_sls_plst_cnt             NUMBER DEFAULT 0;  -- 特売価格表取得件数
  gn_csv_plst_cnt             NUMBER DEFAULT 0;  -- 統一価格表出力件数
-- Ver.1.6 Add End
--
--カーソル
  CURSOR main_cur
  IS
    SELECT 
-- 2009/08/31 Ver.1.5 Add Start
           /*+ index(xupw xxcos_unit_price_mst_work_n01) */
-- 2009/08/31 Ver.1.5 Add End
           xupw.customer_number          customer_number            --顧客コード
         , xupw.item_code                item_code                  --品名コード
         , xupw.nml_prev_unit_price      nml_prev_unit_price        --通常　前回　単価　
         , xupw.nml_prev_dlv_date        nml_prev_dlv_date          --通常　前回　納品年月日　
         , xupw.nml_prev_qty             nml_prev_qty               --通常　前回　数量　
         , xupw.nml_bef_prev_dlv_date    nml_bef_prev_dlv_date      --通常　前々回　納品年月日　
         , xupw.nml_bef_prev_qty         nml_bef_prev_qty           --通常　前々回　数量　
         , xupw.sls_prev_unit_price      sls_prev_unit_price        --特売　前回　単価　
         , xupw.sls_prev_dlv_date        sls_prev_dlv_date          --特売　前回　納品年月日　
         , xupw.sls_prev_qty             sls_prev_qty               --特売　前回　数量　
         , xupw.sls_bef_prev_dlv_date    sls_bef_prev_dlv_date      --特売　前々回　納品年月日　
         , xupw.sls_bef_prev_qty         sls_bef_prev_qty           --特売　前々回　数量　
    FROM   xxcos_unit_price_mst_work     xupw                       --単価マスタワークテーブル
    WHERE 
          xupw.file_output_flag           =  cv_flag_off            --未出力
    ORDER BY 
          xupw.customer_number 
        , xupw.item_code
    FOR UPDATE NOWAIT
    ;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  g_tm_handle       UTL_FILE.FILE_TYPE;
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

    -- *** ローカル変数 ***
--
    lv_dir_path                 VARCHAR2(100);                -- HHTアウトバウンド用ディレクトリパス
    lv_tm_filename              VARCHAR2(100);                -- 単価マスタファイル名
-- Ver.1.6 Add Start
    lt_organization_code        mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
-- Ver.1.6 Add End

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

-- 2009/02/24 T.Nakamura Ver.1.2 add start
    --空行
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
                     

    --==============================================================
    -- マルチバイトの固定値をメッセージより取得
    --==============================================================
    gv_msg_tkn_dir_path         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_dir_path
                                                           );
    gv_msg_tkn_tm_filename      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_filename
                                                           );
    gv_msg_tkn_tm_w_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_w_tbl
                                                           );
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
-- Ver.1.6 Add Start
    -- MO:営業単位
    gv_msg_tkn_org              := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_org
                                                           );
    -- XXCOS:統一価格表対象期間FROM
    gv_msg_tkn_target_from      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_target_from
                                                           );
    -- XXCOS:統一価格表対象期間TO
    gv_msg_tkn_target_to        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_target_to
                                                           );
    -- XXCOI:在庫組織コード
    gv_msg_tkn_organization     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_organization
                                                           );
    -- 価格表HHT連携一時表
    gv_msg_tkn_pl_t_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_pl_t_tbl
                                                           );
-- Ver.1.6 Add End
--
    --==============================================================
    -- プロファイルの取得(XXCOS:HHTアウトバウンド用ディレクトリパス)
    --==============================================================
    lv_dir_path := FND_PROFILE.VALUE(cv_prf_dir_path);
    
--
    -- プロファイル取得エラーの場合
    IF (lv_dir_path IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_dir_path
                                           );

      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:単価マスタファイル名)
    --==============================================================
    lv_tm_filename := FND_PROFILE.VALUE(cv_prf_tm_filename);
--
    -- プロファイル取得エラーの場合
    IF (lv_tm_filename IS NULL) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                          , cv_msg_pro
                                          , cv_tkn_profile
                                          , gv_msg_tkn_tm_filename
                                           );

      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- ファイル名のログ出力
    --==============================================================
    --単価マスタファイル名
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                          ,iv_name         => cv_msg_filename
                                          ,iv_token_name1  => cv_tkn_filename
                                          ,iv_token_value1 => lv_tm_filename
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
                     
    --空行
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );

-- Ver.1.6 Add Start
    --==============================================================
    -- プロファイルの取得(MO:営業単位)
    --==============================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org ) );
--
    -- プロファイル取得エラーの場合
    IF ( gn_org_id IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application            -- アプリケーション短縮名
                                           , cv_msg_pro                -- メッセージコード
                                           , cv_tkn_profile            -- トークンコード1
                                           , gv_msg_tkn_org            -- トークン値1
                                           );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:統一価格表対象期間FROM)
    --==============================================================
    gn_target_from := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_target_from ) );
--
    -- プロファイル取得エラーの場合
    IF ( gn_target_from IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application            -- アプリケーション短縮名
                                           , cv_msg_pro                -- メッセージコード
                                           , cv_tkn_profile            -- トークンコード1
                                           , gv_msg_tkn_target_from    -- トークン値1
                                           );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:統一価格表対象期間TO)
    --==============================================================
    gn_target_to := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_target_to ) );
--
    -- プロファイル取得エラーの場合
    IF ( gn_target_to IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application            -- アプリケーション短縮名
                                           , cv_msg_pro                -- メッセージコード
                                           , cv_tkn_profile            -- トークンコード1
                                           , gv_msg_tkn_target_to      -- トークン値1
                                           );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    lt_organization_code := FND_PROFILE.VALUE( cv_prf_organization );
--
    -- プロファイル取得エラーの場合
    IF ( lt_organization_code IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application            -- アプリケーション短縮名
                                           , cv_msg_pro                -- メッセージコード
                                           , cv_tkn_profile            -- トークンコード1
                                           , gv_msg_tkn_organization   -- トークン値1
                                           );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- 在庫組織IDの取得
    --==============================================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( lt_organization_code );
--
    -- 在庫組織ID取得エラーの場合
    IF ( gn_organization_id IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application            -- アプリケーション短縮名
                                           , cv_msg_org_id_err         -- メッセージコード
                                           , cv_tkn_org_code_tok       -- トークンコード1
                                           , lt_organization_code      -- トークン値1
                                           );
      RAISE global_api_others_expt;
    END IF;
-- Ver.1.6 Add End
    --==============================================================
    -- 単価マスタファイル　ファイルオープン
    --==============================================================
    BEGIN
      g_tm_handle := UTL_FILE.FOPEN(lv_dir_path
                                  , lv_tm_filename
                                  , 'w');
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_file_open
                                            , cv_tkn_file_name
                                            , lv_tm_filename);
        RAISE file_open_expt;
    END;
    
    --==============================================================
    -- 業務日付取得より一年前を取得
    --==============================================================
-- Ver.1.6 Mod Start
--    gd_process_date := ADD_MONTHS(xxccp_common_pkg2.get_process_date,-12);
    gd_process_date2 := xxccp_common_pkg2.get_process_date;
    -- 業務日付取得エラーの場合
    IF ( gd_process_date2 IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg( cv_application            -- アプリケーション短縮名
                                           , cv_msg_proc_date_err      -- メッセージコード
                                           );
      RAISE global_api_others_expt;
    END IF;
    -- 業務日付より一年前を取得
    gd_process_date     := ADD_MONTHS( gd_process_date2 ,-12 );
    -- 対象日FROMを取得
    gd_target_date_from := gd_process_date2 - gn_target_from;
    -- 対象日TOを取得
    gd_target_date_to   := gd_process_date2 + gn_target_to;
-- Ver.1.6 Mod End
--
  EXCEPTION
    WHEN file_open_expt THEN
      ov_errbuf := ov_errbuf || ov_errmsg;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
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
   * Procedure Name   : proc_main_loop（ループ部）
   * Description      : A-2データ抽出
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- メインループ処理
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
    lv_message_code          VARCHAR2(20);
    lv_nml_prev_unit_price   VARCHAR2(7);--通常前回単価
    lv_nml_prev_qty_sign     VARCHAR2(1);--通常前回数量サイン
    lv_nml_prev_qty          VARCHAR2(5);--通常前回数量
    lv_nml_prev_dlv_date     VARCHAR2(8);--通常前回納品年月日
    lv_nml_bef_prev_qty_sign VARCHAR2(1);--通常前々回数量サイン
    lv_nml_bef_prev_qty      VARCHAR2(5);--通常前々回数量
    lv_nml_bef_prev_dlv_date VARCHAR2(8);--通常前々回納品年月日
    lv_sls_prev_unit_price   VARCHAR2(7);--特売前回単価
    lv_sls_prev_qty_sign     VARCHAR2(1);--特売前回数量サイン
    lv_sls_prev_qty          VARCHAR2(5);--特売前回数量
    lv_sls_prev_dlv_date     VARCHAR2(8);--特売前回納品年月日
    lv_sls_bef_prev_qty_sign VARCHAR2(1);--特売前々回数量サイン
    lv_sls_bef_prev_qty      VARCHAR2(5);--特売前々回数量
    lv_sls_bef_prev_dlv_date VARCHAR2(8);--特売前々回納品年月日
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    <<main_loop>>
    FOR main_rec in main_cur LOOP
      -- ===============================
      -- A-3 単価マスタファイル出力
      -- ===============================
  --データ編集
     --通常　前回　数量サイン
      IF (main_rec.nml_prev_qty < 0) THEN
        lv_nml_prev_qty_sign := cv_minus;
        lv_nml_prev_qty      := TO_CHAR(main_rec.nml_prev_qty * -1);
      ELSE
        lv_nml_prev_qty_sign := cv_brank;
        lv_nml_prev_qty      := TO_CHAR(main_rec.nml_prev_qty);
      END IF;
     --通常　前々回　数量サイン
      IF (main_rec.nml_bef_prev_qty < 0) THEN
        lv_nml_bef_prev_qty_sign := cv_minus;
        lv_nml_bef_prev_qty      := TO_CHAR(main_rec.nml_bef_prev_qty * -1);
      ELSE
        lv_nml_bef_prev_qty_sign := cv_brank;
        lv_nml_bef_prev_qty      := TO_CHAR(main_rec.nml_bef_prev_qty);
      END IF;
     --特売　前回　数量サイン
      IF (main_rec.sls_prev_qty < 0) THEN
        lv_sls_prev_qty_sign := cv_minus;
        lv_sls_prev_qty      := TO_CHAR(main_rec.sls_prev_qty * -1);
      ELSE
        lv_sls_prev_qty_sign := cv_brank;        
        lv_sls_prev_qty      := TO_CHAR(main_rec.sls_prev_qty);
      END IF;
     --特売　前々回　数量サイン
      IF (main_rec.sls_bef_prev_qty < 0) THEN
        lv_sls_bef_prev_qty_sign := cv_minus;
        lv_sls_bef_prev_qty      := TO_CHAR(main_rec.sls_bef_prev_qty * -1);
      ELSE
        lv_sls_bef_prev_qty_sign := cv_brank;        
        lv_sls_bef_prev_qty      := TO_CHAR(main_rec.sls_bef_prev_qty);
      END IF;
     --通常　前回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF gd_process_date > main_rec.nml_prev_dlv_date THEN
        lv_nml_prev_unit_price := NULL;--通常前回単価
-- 2018/11/22 Ver1.7 Modified START
--        lv_nml_prev_qty_sign   := NULL;--通常前回数量サイン
        lv_nml_prev_qty_sign   := cv_brank;--通常前回数量サイン
-- 2018/11/22 Ver1.7 Modified END
        lv_nml_prev_qty        := NULL;--通常前回数量
        lv_nml_prev_dlv_date   := NULL;--通常前回納品年月日
      ELSE
        lv_nml_prev_unit_price := TO_CHAR(main_rec.nml_prev_unit_price); --通常前回単価
        lv_nml_prev_dlv_date   := TO_CHAR(main_rec.nml_prev_dlv_date ,'YYYYMMDD');   --通常前回納品年月日
    
      END IF;
     --通常　前々回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF (gd_process_date > main_rec.nml_bef_prev_dlv_date) THEN
-- 2018/11/22 Ver1.7 Modified START
--        lv_nml_bef_prev_qty_sign := NULL;--通常前々回数量サイン
        lv_nml_bef_prev_qty_sign := cv_brank;--通常前々回数量サイン
-- 2018/11/22 Ver1.7 Modified END
        lv_nml_bef_prev_qty      := NULL;--通常前々回数量
        lv_nml_bef_prev_dlv_date := NULL;--通常前々回納品年月日
      ELSE
        lv_nml_bef_prev_dlv_date := TO_CHAR(main_rec.nml_bef_prev_dlv_date ,'YYYYMMDD') ;--通常前々回納品年月日
      END IF;

     --特売　前回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF (gd_process_date > main_rec.sls_prev_dlv_date) THEN
        lv_sls_prev_unit_price := NULL;--特売前回単価
-- 2018/11/22 Ver1.7 Modified START
--        lv_sls_prev_qty_sign   := NULL;--特売前回数量サイン
        lv_sls_prev_qty_sign   := cv_brank;--特売前回数量サイン
-- 2018/11/22 Ver1.7 Modified END
        lv_sls_prev_qty        := NULL;--特売前回数量
        lv_sls_prev_dlv_date   := NULL;--特売前回納品年月日
      ELSE
      
        lv_sls_prev_unit_price := TO_CHAR(main_rec.sls_prev_unit_price);--特売前回単価
        lv_sls_prev_dlv_date   := TO_CHAR(main_rec.sls_prev_dlv_date ,'YYYYMMDD');--特売前回納品年月日
      END IF;
     --特売　前々回　納品年月日が処理日（バッチ日付）より一年を過ぎている場合は設定を行いません。
      IF (gd_process_date > main_rec.sls_bef_prev_dlv_date) THEN
-- 2018/11/22 Ver1.7 Modified START
--        lv_sls_bef_prev_qty_sign := NULL;--特売前々回数量サイン
        lv_sls_bef_prev_qty_sign := cv_brank;--特売前々回数量サイン
-- 2018/11/22 Ver1.7 Modified END
        lv_sls_bef_prev_qty      := NULL;--特売前々回数量
        lv_sls_bef_prev_dlv_date := NULL;--特売前々回納品年月日
      ELSE
        lv_sls_bef_prev_dlv_date := TO_CHAR(main_rec.sls_bef_prev_dlv_date ,'YYYYMMDD');--特売前々回納品年月日
      END IF;

      IF lv_nml_prev_dlv_date     IS NULL AND
         lv_nml_bef_prev_dlv_date IS NULL AND
         lv_sls_prev_dlv_date     IS NULL AND
         lv_sls_bef_prev_dlv_date IS NULL 
      THEN
        NULL;
      ELSE
        gn_target_cnt := gn_target_cnt + 1;
        SELECT             cv_quot || main_rec.customer_number || cv_quot -- 顧客コード
          || cv_delimit || cv_quot || main_rec.item_code       || cv_quot -- 品名コード
          || cv_delimit || lv_nml_prev_unit_price                         -- 通常前回単価
          || cv_delimit || lv_nml_prev_dlv_date                           -- 通常前回納品年月日
          || cv_delimit || cv_quot || lv_nml_prev_qty_sign     || cv_quot -- 通常前回数量サイン
          || cv_delimit || lv_nml_prev_qty                                -- 通常前回数量
          || cv_delimit || lv_nml_bef_prev_dlv_date                       -- 通常前々回納品年月日
          || cv_delimit || cv_quot || lv_nml_bef_prev_qty_sign || cv_quot -- 通常前々回数量サイン
          || cv_delimit || lv_nml_bef_prev_qty                            -- 通常前々回数量
          || cv_delimit || lv_sls_prev_unit_price                         -- 特売前回単価
          || cv_delimit || lv_sls_prev_dlv_date                           -- 特売前回納品年月日
          || cv_delimit || cv_quot || lv_sls_prev_qty_sign     || cv_quot -- 特売前回数量サイン
          || cv_delimit || lv_sls_prev_qty                                -- 特売前回数量
          || cv_delimit || lv_sls_bef_prev_dlv_date                       -- 特売前々回納品年月日
          || cv_delimit || cv_quot || lv_sls_bef_prev_qty_sign || cv_quot -- 特売前々回数量サイン
          || cv_delimit || lv_sls_bef_prev_qty                            -- 特売前々回数量
          || cv_delimit                                                   -- 値引単価　前回
          || cv_delimit || cv_quot || TO_CHAR(SYSDATE , 'YYYY/MM/DD HH24:MI:SS') || cv_quot     -- 処理日時
        INTO gv_tm_file_data
        FROM DUAL
        ;
        UTL_FILE.PUT_LINE(g_tm_handle
                         ,gv_tm_file_data
                         );
        gn_normal_cnt := gn_normal_cnt + 1;
        
      -- ===============================
      -- A-4 単価マスタワークテーブルステータス更新
      -- ===============================
        BEGIN
          UPDATE xxcos_unit_price_mst_work
          SET    file_output_flag           = cv_flag_on
                ,last_updated_by            = cn_last_updated_by       
                ,last_update_date           = cd_last_update_date      
                ,last_update_login          = cn_last_update_login     
                ,request_id                 = cn_request_id            
                ,program_application_id     = cn_program_application_id
                ,program_id                 = cn_program_id            
                ,program_update_date        = cd_program_update_date   
          WHERE  CURRENT OF main_cur
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                -- エラー・メッセージ
                                            ,ov_retcode     => lv_retcode               -- リターン・コード
                                            ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
                                            ,ov_key_info    => gv_key_info              --キー情報
                                            ,iv_item_name1  => gv_msg_tkn_cust_code     --項目名称1
                                            ,iv_data_value1 => main_rec.customer_number --データの値1
                                            ,iv_item_name2  => gv_msg_tkn_item_code     --項目名称2
                                            ,iv_data_value2 => main_rec.item_code       --データの値2                                            
                                            );
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_tm_w_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            ov_errbuf := ov_errbuf || CHR(10) || ov_errmsg;  
            RAISE update_expt;
        END;
      END IF;
    END LOOP main_loop;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN update_expt THEN
      ov_retcode := cv_status_error;
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
      IF (SQLCODE = cn_lock_error_code) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_lock
                                            , cv_tkn_lock
                                            , gv_msg_tkn_tm_w_tbl
                                             );
      END IF;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_main_loop;

-- Ver.1.6 Add Start
  /**********************************************************************************
   * Procedure Name   : proc_get_price_list
   * Description      : 価格表情報取得(A-6)
   ***********************************************************************************/
  PROCEDURE proc_get_price_list(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
  , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
  , ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_price_list'; -- プログラム名
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
    lt_s_date_active   xxcos_tmp_hht_price_lists.start_date_active%TYPE;
                                        -- 適用開始年月日
    lt_e_date_active   xxcos_tmp_hht_price_lists.end_date_active%TYPE;
                                        -- 適用終了年月日
    ln_plst_cnt        NUMBER;          -- 価格表取得件数
--
    -- *** ローカル・カーソル ***
    -- 顧客情報取得カーソル
    CURSOR get_cust_info_cur
    IS
      SELECT DISTINCT
             hca.account_number    AS customer_number   -- 顧客コード
           , xspl.customer_id      AS customer_id       -- 顧客ID
           , hcsua.price_list_id   AS price_list_id     -- 価格表ID
        FROM xxcos_sale_price_lists  xspl      -- 特売価格表
           , hz_cust_accounts        hca       -- 顧客マスタ
           , hz_parties              hp        -- パーティ
           , hz_cust_acct_sites_all  hcasa     -- 顧客サイト
           , hz_cust_site_uses_all   hcsua     -- 顧客使用目的
           , ( SELECT flv.meaning     AS meaning
                 FROM fnd_lookup_values flv
                WHERE flv.lookup_type = cv_qck_typ_cust_sts
                  AND flv.lookup_code LIKE cv_qck_typ_a01
                  AND flv.language       = ct_lang
                  AND gd_process_date2  >= NVL( flv.start_date_active ,gd_process_date2 )
                  AND gd_process_date2  <= NVL( flv.end_date_active ,gd_process_date2 )
                  AND flv.enabled_flag   = cv_flag_on
             )                       flv_cs    -- 顧客ステータス
       WHERE xspl.customer_id         = hca.cust_account_id
         AND hp.party_id              = hca.party_id
         AND hp.duns_number_c         = flv_cs.meaning
         AND hcasa.cust_account_id    = hca.cust_account_id
         AND hcasa.org_id             = gn_org_id
         AND hcasa.status             = cv_status_active
         AND hcsua.cust_acct_site_id  = hcasa.cust_acct_site_id
         AND hcsua.org_id             = gn_org_id
         AND hcsua.status             = cv_status_active
         AND hcsua.site_use_code      = cv_site_use_ship
      ORDER BY
             hca.account_number
      ;
    -- 顧客情報取得カーソルレコード型
    get_cust_info_rec    get_cust_info_cur%ROWTYPE;
--
    -- 標準価格表取得カーソル
    CURSOR get_nml_prc_lst_cur(
             it_price_list_id   qp_list_headers_b.list_header_id%TYPE
           )
    IS
      SELECT /*+
               USE_NL( qlhb qll )
             */
             iimb.item_no            AS item_code          -- 商品コード
           , qll.operand             AS unit_price         -- 単価
           , TO_CHAR( qll.start_date_active ,cv_date_fmt_yyyymmdd )
                                     AS start_date_active  -- 適用開始年月日
           , TO_CHAR( qll.end_date_active ,cv_date_fmt_yyyymmdd )
                                     AS end_date_active    -- 適用終了年月日
        FROM qp_list_headers_b     qlhb    -- 価格表ヘッダ
           , qp_list_lines         qll     -- 価格表明細
           , qp_pricing_attributes qpa     -- 価格表詳細
           , ic_item_mst_b         iimb    -- OPM品目マスタ
           , mtl_system_items_b    msib    -- DISC品目マスタ
           , xxcmm_system_items_b  xsib    -- DISC品目アドオンマスタ
           , ( SELECT flv.meaning    AS meaning
                 FROM fnd_lookup_values flv
                WHERE flv.lookup_type    = cv_qck_typ_item_sts
                  AND flv.lookup_code    LIKE cv_qck_typ_a01
                  AND flv.language       = ct_lang
                  AND gd_process_date2  >= NVL( flv.start_date_active ,gd_process_date2 )
                  AND gd_process_date2  <= NVL( flv.end_date_active ,gd_process_date2 )
                  AND flv.enabled_flag   = cv_flag_on
             )                     flv_is  -- 品目ステータス
       WHERE qlhb.list_header_id    = qll.list_header_id
         AND qll.list_line_id       = qpa.list_line_id
         AND qpa.product_attribute  = cv_prdct_attribute1
         AND msib.inventory_item_id = TO_NUMBER( qpa.product_attr_value )
         AND msib.primary_uom_code  = qpa.product_uom_code
         AND gd_target_date_from   <= NVL( qlhb.end_date_active ,gd_target_date_from )
         AND gd_target_date_to     >= NVL( qlhb.start_date_active ,gd_target_date_to )
         AND gd_target_date_from   <= NVL( qll.end_date_active ,gd_target_date_from )
         AND gd_target_date_to     >= NVL( qll.start_date_active ,gd_target_date_to )
         AND msib.organization_id   = gn_organization_id
         AND msib.segment1          = iimb.item_no
         AND iimb.item_no           = xsib.item_code
         AND iimb.attribute26       = cv_sales_target_on
         AND xsib.item_status       = flv_is.meaning
         AND qlhb.list_header_id    = it_price_list_id
      ;
    -- 標準価格表取得カーソルレコード型
    get_nml_prc_lst_rec  get_nml_prc_lst_cur%ROWTYPE;
--
    -- 特売価格表取得カーソル
    CURSOR get_sls_prc_lst_cur(
             it_customer_id   xxcos_sale_price_lists.customer_id%TYPE
           )
    IS
      SELECT iimb.item_no            AS item_code          -- 商品コード
           , xspl.price              AS unit_price         -- 単価
           , TO_CHAR( xspl.start_date_active ,cv_date_fmt_yyyymmdd )
                                     AS start_date_active  -- 適用開始年月日
           , TO_CHAR( xspl.end_date_active ,cv_date_fmt_yyyymmdd )
                                     AS end_date_active    -- 適用終了年月日
        FROM xxcos_sale_price_lists  xspl    -- 特売価格表
           , ic_item_mst_b           iimb    -- OPM品目マスタ
           , mtl_system_items_b      msib    -- DISC品目マスタ
           , xxcmm_system_items_b    xsib    -- DISC品目アドオンマスタ
           , ( SELECT flv.meaning    AS meaning
                 FROM fnd_lookup_values flv
                WHERE flv.lookup_type    = cv_qck_typ_item_sts
                  AND flv.lookup_code    LIKE cv_qck_typ_a01
                  AND flv.language       = ct_lang
                  AND gd_process_date2  >= NVL( flv.start_date_active ,gd_process_date2 )
                  AND gd_process_date2  <= NVL( flv.end_date_active ,gd_process_date2 )
                  AND flv.enabled_flag   = cv_flag_on
             )                       flv_is  -- 品目ステータス
       WHERE xspl.item_id          = msib.inventory_item_id
         AND msib.organization_id  = gn_organization_id
         AND msib.segment1         = iimb.item_no
         AND iimb.item_no          = xsib.item_code
         AND iimb.attribute26      = cv_sales_target_on
         AND gd_target_date_from  <= NVL( xspl.end_date_active ,gd_target_date_from )
         AND gd_target_date_to    >= NVL( xspl.start_date_active ,gd_target_date_to )
         AND xsib.item_status      = flv_is.meaning
         AND xspl.customer_id      = it_customer_id
      ;
    -- 特売価格表取得カーソルレコード型
    get_sls_prc_lst_rec  get_sls_prc_lst_cur%ROWTYPE;
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
    -- 顧客情報取得
    -- ===============================
    -- カーソルOPEN
    <<get_cust_info_loop>>
    OPEN get_cust_info_cur;
    LOOP
      FETCH get_cust_info_cur INTO get_cust_info_rec;
      EXIT WHEN get_cust_info_cur%NOTFOUND;
--
      -- ローカル変数の初期化
      lt_s_date_active := NULL;
      lt_e_date_active := NULL;
      ln_plst_cnt      := 0;
      -- 統一価格表対象顧客件数カウント
      gn_tgt_cust_cnt := gn_tgt_cust_cnt + 1;
--
      -- 価格表IDがNULL以外の場合
      IF ( get_cust_info_rec.price_list_id IS NOT NULL ) THEN
--
        -- ===============================
        -- 標準価格表情報取得
        -- ===============================
        <<get_nml_prc_lst_loop>>
        FOR get_nml_prc_lst_rec IN get_nml_prc_lst_cur(
                                     it_price_list_id => get_cust_info_rec.price_list_id  -- 価格表ID
                                   )
        LOOP
--
          -- 適用開始年月日
          IF ( get_nml_prc_lst_rec.start_date_active IS NOT NULL ) THEN
            -- 適用開始年月日
            lt_s_date_active := get_nml_prc_lst_rec.start_date_active;
          ELSE
            -- 適用開始年月日ダミー
            lt_s_date_active := cv_s_date_dummy;
          END IF;
--
          -- 適用終了年月日
          IF ( get_nml_prc_lst_rec.end_date_active IS NOT NULL ) THEN
            -- 適用終了年月日
            lt_e_date_active := get_nml_prc_lst_rec.end_date_active;
          ELSE
            -- 適用終了年月日ダミー
            lt_e_date_active := cv_e_date_dummy;
          END IF;
--
          BEGIN
            -- 価格表HHT連携一時表へのINSERT
            INSERT INTO xxcos_tmp_hht_price_lists(
              customer_number     -- 01:顧客コード
            , item_code           -- 02:商品コード
            , unit_price          -- 03:単価
            , start_date_active   -- 04:適用開始年月日
            , end_date_active     -- 05:適用終了年月日
            , price_list_div      -- 06:価格表区分
            ) VALUES (
              get_cust_info_rec.customer_number        -- 01:顧客コード
            , get_nml_prc_lst_rec.item_code            -- 02:商品コード
            , get_nml_prc_lst_rec.unit_price           -- 03:単価
            , lt_s_date_active                         -- 04:適用開始年月日
            , lt_e_date_active                         -- 05:適用終了年月日
            , cv_p_list_div_nml                        -- 06:価格表区分：通常
            );
--
          -- 価格表取得件数カウント
          ln_plst_cnt := ln_plst_cnt + 1;
          -- 標準価格表取得件数カウント
          gn_nml_plst_cnt := gn_nml_plst_cnt + 1;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- キー情報の編集
              xxcos_common_pkg.makeup_key_info(
                ov_errbuf       => lv_errbuf                           -- エラー・メッセージ
              , ov_retcode      => lv_retcode                          -- リターン・コード
              , ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ
              , ov_key_info     => gv_key_info                         -- キー情報
              , iv_item_name1   => gv_msg_tkn_cust_code                -- 項目名称1
              , iv_data_value1  => get_cust_info_rec.customer_number   -- データの値1
              , iv_item_name2   => gv_msg_tkn_item_code                -- 項目名称2
              , iv_data_value2  => get_nml_prc_lst_rec.item_code       -- データの値2
              );
              -- エラーメッセージ設定
              lv_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              lv_errmsg := xxccp_common_pkg.get_msg(
                             cv_application            -- アプリケーション短縮名
                           , cv_msg_insert_err         -- メッセージコード
                           , cv_tkn_table_name         -- トークンコード1
                           , gv_msg_tkn_pl_t_tbl       -- トークン値1
                           , cv_tkn_key_data           -- トークンコード2
                           , gv_key_info               -- トークン値2
                           );
              RAISE insert_expt;
          END;
--
        END LOOP get_nml_prc_lst_loop;
--
      END IF;
--
      -- ===============================
      -- 特売価格表取得
      -- ===============================
      -- カーソルOPEN
      <<get_sls_prc_lst_loop>>
      FOR get_sls_prc_lst_rec IN get_sls_prc_lst_cur(
                                   it_customer_id  => get_cust_info_rec.customer_id   -- 顧客ID
                                 )
      LOOP
--
        BEGIN
          -- 価格表HHT連携一時表へのINSERT
          INSERT INTO xxcos_tmp_hht_price_lists(
            customer_number     -- 01:顧客コード
          , item_code           -- 02:商品コード
          , unit_price          -- 03:単価
          , start_date_active   -- 04:適用開始年月日
          , end_date_active     -- 05:適用終了年月日
          , price_list_div      -- 06:価格表区分
          ) VALUES (
            get_cust_info_rec.customer_number        -- 01:顧客コード
          , get_sls_prc_lst_rec.item_code            -- 02:商品コード
          , get_sls_prc_lst_rec.unit_price           -- 03:単価
          , get_sls_prc_lst_rec.start_date_active    -- 04:適用開始年月日
          , get_sls_prc_lst_rec.end_date_active      -- 05:適用終了年月日
          , cv_p_list_div_sls                        -- 06:価格表区分：特売
          );
--
          -- 価格表取得件数カウント
          ln_plst_cnt := ln_plst_cnt + 1;
          -- 特売価格表取得件数カウント
          gn_sls_plst_cnt := gn_sls_plst_cnt + 1;
--
        EXCEPTION
          WHEN OTHERS THEN
            -- キー情報の編集
            xxcos_common_pkg.makeup_key_info(
              ov_errbuf       => lv_errbuf                                 -- エラー・メッセージ
            , ov_retcode      => lv_retcode                                -- リターン・コード
            , ov_errmsg       => lv_errmsg                                 -- ユーザー・エラー・メッセージ
            , ov_key_info     => gv_key_info                               -- キー情報
            , iv_item_name1   => gv_msg_tkn_cust_code                      -- 項目名称1
            , iv_data_value1  => get_cust_info_rec.customer_number         -- データの値1
            , iv_item_name2   => gv_msg_tkn_item_code                      -- 項目名称2
            , iv_data_value2  => get_sls_prc_lst_rec.item_code             -- データの値2
            );
            -- エラーメッセージ設定
            lv_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            lv_errmsg := xxccp_common_pkg.get_msg(
                           cv_application            -- アプリケーション短縮名
                         , cv_msg_insert_err         -- メッセージコード
                         , cv_tkn_table_name         -- トークンコード1
                         , gv_msg_tkn_pl_t_tbl       -- トークン値1
                         , cv_tkn_key_data           -- トークンコード2
                         , gv_key_info               -- トークン値2
                         );
            RAISE insert_expt;
        END;
--
      END LOOP get_sls_prc_lst_loop;
--
      -- ===============================
      -- 価格表情報取得結果の確認
      -- ===============================
      IF ( ln_plst_cnt = 0 ) THEN
        -- キー情報の編集
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf       => lv_errbuf                           -- エラー・メッセージ
        , ov_retcode      => lv_retcode                          -- リターン・コード
        , ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ
        , ov_key_info     => gv_key_info                         -- キー情報
        , iv_item_name1   => gv_msg_tkn_cust_code                -- 項目名称1
        , iv_data_value1  => get_cust_info_rec.customer_number   -- データの値1
        );
        -- エラーメッセージ設定
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application            -- アプリケーション短縮名
                     , cv_msg_price_list_err     -- メッセージコード
                     , cv_tkn_key_data           -- トークンコード1
                     , gv_key_info               -- トークン値1
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        -- 警告顧客件数カウント
        gn_skp_cust_cnt := gn_skp_cust_cnt + 1;
--
      END IF;
--
    END LOOP get_cust_info_loop;
--
  EXCEPTION
    -- *** 登録エラー例外ハンドラ ***
    WHEN insert_expt THEN
      -- カーソルCLOSE
      IF ( get_cust_info_cur%ISOPEN ) THEN
        CLOSE get_cust_info_cur;
      END IF;
      -- カーソルCLOSE
      IF ( get_nml_prc_lst_cur%ISOPEN ) THEN
        CLOSE get_nml_prc_lst_cur;
      END IF;
      -- カーソルCLOSE
      IF ( get_sls_prc_lst_cur%ISOPEN ) THEN
        CLOSE get_sls_prc_lst_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf||CHR(10)||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルCLOSE
      IF ( get_cust_info_cur%ISOPEN ) THEN
        CLOSE get_cust_info_cur;
      END IF;
      --
      IF ( get_nml_prc_lst_cur%ISOPEN ) THEN
        CLOSE get_nml_prc_lst_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_price_list;
--
  /**********************************************************************************
   * Procedure Name   : proc_put_price_list
   * Description      : 価格表情報出力(A-7)
   ***********************************************************************************/
  PROCEDURE proc_put_price_list(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
  , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
  , ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_price_list'; -- プログラム名
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
    -- 一時表情報取得カーソル
    CURSOR get_tmp_data_cur
    IS
      SELECT xthpl.customer_number     AS customer_number      -- 顧客コード
           , xthpl.item_code           AS item_code            -- 商品コード
           , xthpl.unit_price          AS unit_price           -- 単価
           , xthpl.start_date_active   AS start_date_active    -- 適用開始年月日
           , xthpl.end_date_active     AS end_date_active      -- 適用終了年月日
           , xthpl.price_list_div      AS price_list_div       -- 価格表区分
        FROM xxcos_tmp_hht_price_lists  xthpl  -- 価格表HHT連携一時表
      ORDER BY
             xthpl.customer_number    -- 顧客コード
           , xthpl.item_code          -- 商品コード
           , xthpl.price_list_div     -- 価格表区分
           , xthpl.start_date_active  -- 適用開始年月日
      ;
    -- 一時表取得カーソルレコード型
    get_tmp_data_rec  get_tmp_data_cur%ROWTYPE;
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
    -- カーソルOPEN
    OPEN get_tmp_data_cur;
    LOOP
      FETCH get_tmp_data_cur INTO get_tmp_data_rec;
      EXIT WHEN get_tmp_data_cur%NOTFOUND;
--
      -- CSV出力用文字列の編集
      SELECT             cv_quot || get_tmp_data_rec.customer_number     || cv_quot   -- 顧客コード
        || cv_delimit || cv_quot || get_tmp_data_rec.item_code           || cv_quot   -- 商品コード
        || cv_delimit || get_tmp_data_rec.unit_price                                  -- 単価
        || cv_delimit || get_tmp_data_rec.start_date_active                           -- 適用開始年月日
        || cv_delimit || cv_quot || get_tmp_data_rec.price_list_div      || cv_quot   -- 価格表区分
        || cv_delimit || cn_zero                                                      -- 数量
        || cv_delimit || get_tmp_data_rec.end_date_active                             -- 適用終了年月日
-- 2018/11/22 Ver1.7 Modified START
--        || cv_delimit || cv_quot || NULL                                 || cv_quot   -- 数量サイン
        || cv_delimit || cv_quot || cv_brank                             || cv_quot   -- 数量サイン
-- 2018/11/22 Ver1.7 Modified END
        || cv_delimit || cn_zero                                                      -- 数量予備１
        || cv_delimit || cn_zero                                                      -- 単価予備１
        || cv_delimit || NULL                                                         -- 年月日予備１
-- 2018/11/22 Ver1.7 Modified START
--        || cv_delimit || cv_quot || NULL                                 || cv_quot   -- 数量サイン予備１
        || cv_delimit || cv_quot || cv_brank                             || cv_quot   -- 数量サイン予備１
-- 2018/11/22 Ver1.7 Modified END
        || cv_delimit || cn_zero                                                      -- 数量予備２
        || cv_delimit || NULL                                                         -- 年月日予備２
-- 2018/11/22 Ver1.7 Modified START
--        || cv_delimit || cv_quot || NULL                                 || cv_quot   -- 数量サイン予備２
        || cv_delimit || cv_quot || cv_brank                             || cv_quot   -- 数量サイン予備２
-- 2018/11/22 Ver1.7 Modified END
        || cv_delimit || cn_zero                                                      -- 数量予備３
        || cv_delimit || cn_zero                                                      -- 単価予備２
        || cv_delimit || cv_quot || TO_CHAR( SYSDATE ,cv_date_fmt_full ) || cv_quot   -- 処理日時
      INTO gv_tm_file_data
      FROM DUAL
      ;
      -- CSVファイル出力
      UTL_FILE.PUT_LINE( g_tm_handle
                       , gv_tm_file_data
                       );
--
      -- 統一価格表出力件数カウント
      gn_csv_plst_cnt := gn_csv_plst_cnt + 1;
--
    END LOOP;
--
    CLOSE get_tmp_data_cur;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルCLOSE
      IF ( get_tmp_data_cur%ISOPEN ) THEN
        CLOSE get_tmp_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_put_price_list;
-- Ver.1.6 Add End
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
-- Ver.1.6 Add Start
    gn_tgt_cust_cnt := 0;  -- 統一価格表対象顧客件数
    gn_skp_cust_cnt := 0;  -- 警告顧客件数
    gn_nml_plst_cnt := 0;  -- 標準価格表取得件数
    gn_sls_plst_cnt := 0;  -- 特売価格表取得件数
    gn_csv_plst_cnt := 0;  -- 統一価格表出力件数
-- Ver.1.6 Add End
--
    -- ===============================
    -- Loop1 メイン　A-2データ抽出
    -- ===============================

    proc_main_loop(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
    END IF;
-- Ver.1.6 Add Start
    -- ===============================
    -- 価格表情報取得(A-6)
    -- ===============================
    proc_get_price_list(
        lv_errbuf  -- エラー・メッセージ           --# 固定 #
       ,lv_retcode -- リターン・コード             --# 固定 #
       ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 価格表情報出力(A-7)
    -- ===============================
    proc_put_price_list(
        lv_errbuf  -- エラー・メッセージ           --# 固定 #
       ,lv_retcode -- リターン・コード             --# 固定 #
       ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.6 Add End
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
       iv_which   => cv_log_header_out    
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
    -- A-1．初期処理
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submainの呼び出し（実際の処理はsubmainで行う）
      -- ===============================================
      submain(
         lv_errbuf   -- エラー・メッセージ           --# 固定 #
        ,lv_retcode  -- リターン・コード             --# 固定 #
        ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
       --ファイルのクローズ
      UTL_FILE.FCLOSE(g_tm_handle);
    END IF;

--
    -- ===============================================
    -- A-5．終了処理
    -- ===============================================
-- Ver.1.6 Mod Start
--    --エラー出力
--    IF (lv_retcode != cv_status_normal) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --エラーメッセージ
--      );
---- 2009/02/24 T.Nakamura Ver.1.2 mod start
----    END IF;
----    --空行挿入
----    FND_FILE.PUT_LINE(
----       which  => FND_FILE.OUTPUT
----      ,buff   => ''
----    );
--      --空行挿入
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => ''
--      );
--    END IF;
    -- エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_errbuf --エラーメッセージ
      );
--
      -- 空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
      );
    ELSE
      -- 警告顧客件数が1件以上の場合
      IF ( gn_skp_cust_cnt > 0 ) THEN
        -- 終了ステータスに警告をセット
        lv_retcode := cv_status_warn;
        -- 空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
        );
      END IF;
    END IF;
-- Ver.1.6 Mod End
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- Ver.1.6 Add Start
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    --価格表処理件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application             -- アプリケーション短縮名
                   , iv_name         => cv_msg_plst_cnt_msg        -- メッセージコード
                   , iv_token_name1  => cv_tkn_cnt1                -- トークンコード1
                   , iv_token_value1 => TO_CHAR(gn_tgt_cust_cnt)   -- トークン値1
                   , iv_token_name2  => cv_tkn_cnt2                -- トークンコード2
                   , iv_token_value2 => TO_CHAR(gn_skp_cust_cnt)   -- トークン値2
                   , iv_token_name3  => cv_tkn_cnt3                -- トークンコード3
                   , iv_token_value3 => TO_CHAR(gn_nml_plst_cnt)   -- トークン値3
                   , iv_token_name4  => cv_tkn_cnt4                -- トークンコード4
                   , iv_token_value4 => TO_CHAR(gn_sls_plst_cnt)   -- トークン値4
                   , iv_token_name5  => cv_tkn_cnt5                -- トークンコード5
                   , iv_token_value5 => TO_CHAR(gn_csv_plst_cnt)   -- トークン値5
                   );
    --価格表処理件数出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
-- Ver.1.6 Add End
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
END XXCOS003A05C;
/
