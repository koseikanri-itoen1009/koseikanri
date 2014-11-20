CREATE OR REPLACE PACKAGE BODY XXCOI004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI004A04R(body)
 * Description      : VD機内在庫表
 * MD.050           : MD050_COI_004_A04
 * Version          : 1.7
 *
 * Program List
 * ------------------------ --------------------------------------------------------
 *  Name                     Description
 * ------------------------ --------------------------------------------------------
 *  del_rep_table_data       ワークテーブルデータ削除(A-9)
 *  exec_svf_conc            SVFコンカレント起動(A-5)
 *  ins_vd_inv_wk            ワークテーブルデータ登録理(A-7)
 *  init                     初期処理(A-2)
 *  chk_param                パラメータ必須チェック(A-1)
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Wada           新規作成
 *  2009/03/05    1.1   H.Wada           障害番号 #032
 *                                         ・取得件数0件処理修正
 *                                         ・SVF共通関数呼出前コミット処理追加
 *  2009/05/19    1.2   T.Nakamura       [T1_0980]ワークテーブルデータ登録項目に出力期間を追加
 *                                       [T1_0991]VD機内在庫表のH/Cに出力する値を変更
 *  2009/06/26    1.3   H.Wada           [0000257]顧客抽出SQLの変更
 *  2009/07/09    1.4   H.Sasaki         [0000500]顧客抽出SQLの変更
 *  2009/08/13    1.5   N.Abe            [0000891]顧客抽出SQLの変更
 *                                       [0001033]在庫組織コードをプロファイルから取得するよう変更
 *  2009/09/08    1.6   N.Abe            [0001266]OPM品目アドオンの取得方法修正
 *  2009/10/21    1.7   N.Abe            [E_最終移行リハ_00502]物件マスタの機器区分を参照する修正
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
--  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  lock_expt                   EXCEPTION;   -- ロック取得エラー
  no_data_expt                EXCEPTION;   -- 取得件数0件例外
  exec_svfapi_expt            EXCEPTION;   -- SVF帳票共通関数エラー
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 ); -- ロック取得例外
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(15) := 'XXCOI004A04R';
  -- アプリケーション短縮名
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)  := 'XXCOI';
  -- メッセージ
  cv_msg_coi_00008            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008'; -- 0件メッセージ
  cv_msg_coi_00010            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010'; -- APIエラーメッセージ
  cv_msg_coi_10304            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10304'; -- 入力パラメータ必須チェックエラー(出力拠点)
  cv_msg_coi_10305            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10305'; -- 入力パラメータ必須チェックエラー(出力期間)
  cv_msg_coi_10306            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10306'; -- 入力パラメータ必須チェックエラー(出力対象)
  cv_msg_coi_10150            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10150'; -- パラメータ出力拠点メッセージ
  cv_msg_coi_10151            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10151'; -- パラメータ出力期間メッセージ
  cv_msg_coi_10152            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10152'; -- パラメータ出力対象メッセージ
  cv_msg_coi_10153            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10153'; -- パラメータ営業員メッセージ
  cv_msg_coi_10154            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10154'; -- パラメータ顧客メッセージ
  cv_msg_coi_10155            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10155'; -- ロック取得エラーメッセージ
-- == 2009/05/19 V1.2 Added START ==================================================================
  cv_msg_coi_10383            CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10383'; -- 出力期間内容取得エラーメッセージ
  cv_log                      CONSTANT VARCHAR2(3)  := 'LOG';              -- コンカレントヘッダ出力先
-- == 2009/05/19 V1.2 Added END   ==================================================================
-- == 2009/08/13 V1.5 Added START ==================================================================
  cv_msg_coi_00005            CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';
  cv_msg_coi_00006            CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';
-- == 2009/08/13 V1.5 Added END   ==================================================================
  -- トークン
  cv_tkn_name_p_base          CONSTANT VARCHAR2(6)  := 'P_BASE';
  cv_tkn_name_p_term          CONSTANT VARCHAR2(6)  := 'P_TERM';
  cv_tkn_name_p_subject       CONSTANT VARCHAR2(9)  := 'P_SUBJECT';
  cv_tkn_name_p_num           CONSTANT VARCHAR2(5)  := 'P_NUM';
  cv_tkn_name_p_employee      CONSTANT VARCHAR2(10) := 'P_EMPLOYEE';
  cv_tkn_name_p_customer      CONSTANT VARCHAR2(10) := 'P_CUSTOMER';
  cv_tkn_api_name             CONSTANT VARCHAR2(8)  := 'API_NAME';
  cv_val_submit_svf_request   CONSTANT VARCHAR2(18) := 'SUBMIT_SVF_REQUEST';
-- == 2009/08/13 V1.5 Added START ==================================================================
  cv_tkn_pro                  CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_tkn_org_code             CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
-- == 2009/08/13 V1.5 Added END   ==================================================================
-- == 2009/05/19 V1.2 Added START ==================================================================
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- 参照タイプ
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- 参照コード
-- == 2009/05/19 V1.2 Added END   ==================================================================
-- == 2009/06/26 V1.3 Added START ==================================================================
  cv_staff_prm_yes      CONSTANT VARCHAR2(1)  := 'Y';                -- 入力パラメータ:営業員 有り
  cv_staff_prm_no       CONSTANT VARCHAR2(1)  := 'N';                -- 入力パラメータ:営業員 無し
-- == 2009/06/26 V1.3 Added END   ==================================================================
-- == 2009/08/13 V1.5 Added START ==================================================================
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE';    -- プロファイル名（在庫組織コード）
-- == 2009/08/13 V1.5 Added END   ==================================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- VD機内在庫表格納用レコード変数
  TYPE vd_inv_wk_rec IS TABLE OF VARCHAR2(360) INDEX BY BINARY_INTEGER;
  -- VD機内在庫表格納用テーブル変数
  TYPE vd_inv_wk_ttype IS TABLE OF vd_inv_wk_rec INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ
  gv_output_base              VARCHAR2(5);                           --  1.出力拠点
  gv_output_period            VARCHAR2(1);                           --  2.出力期間
  gv_output_target            VARCHAR2(1);                           --  3.出力対象
  gv_sales_staff_1            VARCHAR2(10);                          --  4.営業員1
  gv_sales_staff_2            VARCHAR2(10);                          --  5.営業員2
  gv_sales_staff_3            VARCHAR2(10);                          --  6.営業員3
  gv_sales_staff_4            VARCHAR2(10);                          --  7.営業員4
  gv_sales_staff_5            VARCHAR2(10);                          --  8.営業員5
  gv_sales_staff_6            VARCHAR2(10);                          --  9.営業員6
  gv_customer_1               VARCHAR2(9);                           -- 10.顧客1
  gv_customer_2               VARCHAR2(9);                           -- 11.顧客2
  gv_customer_3               VARCHAR2(9);                           -- 12.顧客3
  gv_customer_4               VARCHAR2(9);                           -- 13.顧客4
  gv_customer_5               VARCHAR2(9);                           -- 14.顧客5
  gv_customer_6               VARCHAR2(9);                           -- 15.顧客6
  gv_customer_7               VARCHAR2(9);                           -- 16.顧客7
  gv_customer_8               VARCHAR2(9);                           -- 17.顧客8
  gv_customer_9               VARCHAR2(9);                           -- 18.顧客9
  gv_customer_10              VARCHAR2(9);                           -- 19.顧客10
  gv_customer_11              VARCHAR2(9);                           -- 20.顧客11
  gv_customer_12              VARCHAR2(9);                           -- 21.顧客12
-- == 2009/05/19 V1.2 Added START ==================================================================
  gv_output_period_meaning    VARCHAR2(4);                           -- 出力期間内容
-- == 2009/05/19 V1.2 Added END   ==================================================================
-- == 2009/06/26 V1.3 Added START ==================================================================
  gv_staff_prm_flg            VARCHAR2(1);                           -- 営業員入力有無フラグ
-- == 2009/06/26 V1.3 Added END   ==================================================================
-- == 2009/08/13 V1.5 Added START ==================================================================
  gv_f_organization_code      VARCHAR2(10);                          -- 在庫組織コード
  gn_f_organization_id        NUMBER;                                -- 在庫組織ID
-- == 2009/08/13 V1.5 Added END   ==================================================================
--
  gt_vd_inv_wk_tab   vd_inv_wk_ttype;   -- VD機内在庫表ワークテーブル格納用
--
  /**********************************************************************************
   * Procedure Name   : del_rep_table_data
   * Description      : ワークテーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE del_rep_table_data(
    ov_errbuf     OUT VARCHAR2,  -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,  -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)  -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_table_data'; -- プログラム名
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
    CURSOR get_vd_inv_wk_cur
    IS
      SELECT 'X'
      FROM   xxcoi_rep_vd_inventory   xrvi
      WHERE  xrvi.request_id = cn_request_id
      FOR UPDATE OF xrvi.request_id NOWAIT;
--
    -- *** ローカル・レコード ***
    get_vd_inv_wk_rec  get_vd_inv_wk_cur%ROWTYPE;
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
    --==============================================================
    --VD機内在庫表ワークテーブルロック取得
    --==============================================================
    -- カーソルオープン
    OPEN get_vd_inv_wk_cur;
    FETCH get_vd_inv_wk_cur INTO get_vd_inv_wk_rec;
    CLOSE get_vd_inv_wk_cur;
--
  --==============================================================
  --VD機内在庫表ワークテーブル削除
  --==============================================================
    DELETE FROM xxcoi_rep_vd_inventory xrbi
    WHERE xrbi.request_id = cn_request_id;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN                          --*** ワークテーブルロック取得エラー ***
      IF (get_vd_inv_wk_cur%ISOPEN) THEN
        CLOSE get_vd_inv_wk_cur;
      END IF;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10155);
      lv_errbuf := lv_errmsg;
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END del_rep_table_data;
--
  /**********************************************************************************
   * Procedure Name   : exec_svf_conc
   * Description      : SVFコンカレント起動(A-5)
   ***********************************************************************************/
  PROCEDURE exec_svf_conc(
     ov_errbuf     OUT VARCHAR2                                    -- 1.エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2                                    -- 2.リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2                                    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    ,iv_zero_msg   IN  VARCHAR2                                    -- 4.0件メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_svf_conc'; -- プログラム名
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
    cv_output_mode       CONSTANT VARCHAR2(1)  := '1';  
    cv_frm_nm            CONSTANT VARCHAR2(16) := 'XXCOI004A04S.xml';   -- フォーム用新規ファイル名
    cv_vrq_nm            CONSTANT VARCHAR2(16) := 'XXCOI004A04S.vrq';   -- クエリー様式ファイル名
    cv_format_date_ymd   CONSTANT VARCHAR2(8)  := 'YYYYMMDD';           -- 日付フォーマット（年月日）
--
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
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
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id );
--
    --==============================================================
    --SVF帳票共通関数(SVFコンカレントの起動)
    --==============================================================
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_retcode      => lv_retcode                                  -- リターンコード
      ,ov_errbuf       => lv_errbuf                                   -- エラーメッセージ
      ,ov_errmsg       => lv_errmsg                                   -- ユーザー・エラーメッセージ
      ,iv_conc_name    => cv_pkg_name                                 -- コンカレント名
      ,iv_file_name    => lv_svf_file_name                            -- 出力ファイル名
      ,iv_file_id      => cv_pkg_name                                 -- 帳票ID
      ,iv_output_mode  => cv_output_mode                              -- 出力区分
      ,iv_frm_file     => cv_frm_nm                                   -- フォーム様式ファイル名
      ,iv_vrq_file     => cv_vrq_nm                                   -- クエリー様式ファイル名
      ,iv_org_id       => fnd_global.org_id                           -- ORG_ID
      ,iv_user_name    => fnd_global.user_name                        -- ログイン・ユーザ名
      ,iv_resp_name    => fnd_global.resp_name                        -- ログイン・ユーザの職責名
      ,iv_doc_name     => NULL                                        -- 文書名
      ,iv_printer_name => NULL                                        -- プリンタ名
      ,iv_request_id   => cn_request_id                               -- 要求ID
      ,iv_nodata_msg   => iv_zero_msg                                 -- データなしメッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode <> cv_status_normal) THEN
      -- APIエラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_00010
                     ,iv_token_name1  => cv_tkn_api_name
                     ,iv_token_value1 => cv_val_submit_svf_request
                   );
      lv_errbuf := lv_errmsg;
      RAISE exec_svfapi_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN exec_svfapi_expt THEN                           --*** SVF帳票共通関数エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END exec_svf_conc;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_inv_wk
   * Description      : ワークテーブルデータ登録理(A-7)
   ***********************************************************************************/
  PROCEDURE ins_vd_inv_wk(
    ov_errbuf            OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT VARCHAR2       -- リターン・コード             --# 固定 #
   ,ov_errmsg            OUT VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
   ,ir_coi_vd_inv_wk_rec IN  vd_inv_wk_rec) -- VD機内在庫表格納用レコード変数
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_inv_wk'; -- プログラム名
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
    INSERT INTO xxcoi_rep_vd_inventory(
      vd_inv_wk_id                                          --   1.ベンダ機内在庫表ワークID
     ,base_code                                             --   2.拠点コード
     ,base_name                                             --   3.拠点名
     ,customer_code                                         --   4.顧客コード
     ,customer_name                                         --   5.顧客名
     ,model_code                                            --   6.機種コード
     ,sele_qnt                                              --   7.セレ数
     ,charge_business_member_code                           --   8.営業担当者コード
     ,charge_business_member_name                           --   9.営業担当者名
-- == 2009/05/19 V1.2 Added START ==================================================================
     ,output_period                                         --  出力期間
-- == 2009/05/19 V1.2 Added END   ==================================================================
     ,column_no1                                            --  10.コラム№1
     ,column_no2                                            --  11.コラム№2
     ,column_no3                                            --  12.コラム№3
     ,column_no4                                            --  13.コラム№4
     ,column_no5                                            --  14.コラム№5
     ,column_no6                                            --  15.コラム№6
     ,column_no7                                            --  16.コラム№7
     ,column_no8                                            --  17.コラム№8
     ,column_no9                                            --  18.コラム№9
     ,column_no10                                           --  19.コラム№10
     ,column_no11                                           --  20.コラム№11
     ,column_no12                                           --  21.コラム№12
     ,column_no13                                           --  22.コラム№13
     ,column_no14                                           --  23.コラム№14
     ,column_no15                                           --  24.コラム№15
     ,column_no16                                           --  25.コラム№16
     ,column_no17                                           --  26.コラム№17
     ,column_no18                                           --  27.コラム№18
     ,column_no19                                           --  28.コラム№19
     ,column_no20                                           --  29.コラム№20
     ,column_no21                                           --  30.コラム№21
     ,column_no22                                           --  31.コラム№22
     ,column_no23                                           --  32.コラム№23
     ,column_no24                                           --  33.コラム№24
     ,column_no25                                           --  34.コラム№25
     ,column_no26                                           --  35.コラム№26
     ,column_no27                                           --  36.コラム№27
     ,column_no28                                           --  37.コラム№28
     ,column_no29                                           --  38.コラム№29
     ,column_no30                                           --  39.コラム№30
     ,column_no31                                           --  40.コラム№31
     ,column_no32                                           --  41.コラム№32
     ,column_no33                                           --  42.コラム№33
     ,column_no34                                           --  43.コラム№34
     ,column_no35                                           --  44.コラム№35
     ,column_no36                                           --  45.コラム№36
     ,column_no37                                           --  46.コラム№37
     ,column_no38                                           --  47.コラム№38
     ,column_no39                                           --  48.コラム№39
     ,column_no40                                           --  49.コラム№40
     ,column_no41                                           --  50.コラム№41
     ,column_no42                                           --  51.コラム№42
     ,column_no43                                           --  52.コラム№43
     ,column_no44                                           --  53.コラム№44
     ,column_no45                                           --  54.コラム№45
     ,column_no46                                           --  55.コラム№46
     ,column_no47                                           --  56.コラム№47
     ,column_no48                                           --  57.コラム№48
     ,column_no49                                           --  58.コラム№49
     ,column_no50                                           --  59.コラム№50
     ,column_no51                                           --  60.コラム№51
     ,column_no52                                           --  61.コラム№52
     ,column_no53                                           --  62.コラム№53
     ,column_no54                                           --  63.コラム№54
     ,column_no55                                           --  64.コラム№55
     ,column_no56                                           --  65.コラム№56
     ,item_code1                                            --  66.品目コード1
     ,item_code2                                            --  67.品目コード2
     ,item_code3                                            --  68.品目コード3
     ,item_code4                                            --  69.品目コード4
     ,item_code5                                            --  70.品目コード5
     ,item_code6                                            --  71.品目コード6
     ,item_code7                                            --  72.品目コード7
     ,item_code8                                            --  73.品目コード8
     ,item_code9                                            --  74.品目コード9
     ,item_code10                                           --  75.品目コード10
     ,item_code11                                           --  76.品目コード11
     ,item_code12                                           --  77.品目コード12
     ,item_code13                                           --  78.品目コード13
     ,item_code14                                           --  79.品目コード14
     ,item_code15                                           --  80.品目コード15
     ,item_code16                                           --  81.品目コード16
     ,item_code17                                           --  82.品目コード17
     ,item_code18                                           --  83.品目コード18
     ,item_code19                                           --  84.品目コード19
     ,item_code20                                           --  85.品目コード20
     ,item_code21                                           --  86.品目コード21
     ,item_code22                                           --  87.品目コード22
     ,item_code23                                           --  88.品目コード23
     ,item_code24                                           --  89.品目コード24
     ,item_code25                                           --  90.品目コード25
     ,item_code26                                           --  91.品目コード26
     ,item_code27                                           --  92.品目コード27
     ,item_code28                                           --  93.品目コード28
     ,item_code29                                           --  94.品目コード29
     ,item_code30                                           --  95.品目コード30
     ,item_code31                                           --  96.品目コード31
     ,item_code32                                           --  97.品目コード32
     ,item_code33                                           --  98.品目コード33
     ,item_code34                                           --  99.品目コード34
     ,item_code35                                           -- 100.品目コード35
     ,item_code36                                           -- 101.品目コード36
     ,item_code37                                           -- 102.品目コード37
     ,item_code38                                           -- 103.品目コード38
     ,item_code39                                           -- 104.品目コード39
     ,item_code40                                           -- 105.品目コード40
     ,item_code41                                           -- 106.品目コード41
     ,item_code42                                           -- 107.品目コード42
     ,item_code43                                           -- 108.品目コード43
     ,item_code44                                           -- 109.品目コード44
     ,item_code45                                           -- 110.品目コード45
     ,item_code46                                           -- 111.品目コード46
     ,item_code47                                           -- 112.品目コード47
     ,item_code48                                           -- 113.品目コード48
     ,item_code49                                           -- 114.品目コード49
     ,item_code50                                           -- 115.品目コード50
     ,item_code51                                           -- 116.品目コード51
     ,item_code52                                           -- 117.品目コード52
     ,item_code53                                           -- 118.品目コード53
     ,item_code54                                           -- 119.品目コード54
     ,item_code55                                           -- 120.品目コード55
     ,item_code56                                           -- 121.品目コード56
     ,item_name1                                            -- 122.品目名1
     ,item_name2                                            -- 123.品目名2
     ,item_name3                                            -- 124.品目名3
     ,item_name4                                            -- 125.品目名4
     ,item_name5                                            -- 126.品目名5
     ,item_name6                                            -- 127.品目名6
     ,item_name7                                            -- 128.品目名7
     ,item_name8                                            -- 129.品目名8
     ,item_name9                                            -- 130.品目名9
     ,item_name10                                           -- 131.品目名10
     ,item_name11                                           -- 132.品目名11
     ,item_name12                                           -- 133.品目名12
     ,item_name13                                           -- 134.品目名13
     ,item_name14                                           -- 135.品目名14
     ,item_name15                                           -- 136.品目名15
     ,item_name16                                           -- 137.品目名16
     ,item_name17                                           -- 138.品目名17
     ,item_name18                                           -- 139.品目名18
     ,item_name19                                           -- 140.品目名19
     ,item_name20                                           -- 141.品目名20
     ,item_name21                                           -- 142.品目名21
     ,item_name22                                           -- 143.品目名22
     ,item_name23                                           -- 144.品目名23
     ,item_name24                                           -- 145.品目名24
     ,item_name25                                           -- 146.品目名25
     ,item_name26                                           -- 147.品目名26
     ,item_name27                                           -- 148.品目名27
     ,item_name28                                           -- 149.品目名28
     ,item_name29                                           -- 150.品目名29
     ,item_name30                                           -- 151.品目名30
     ,item_name31                                           -- 152.品目名31
     ,item_name32                                           -- 153.品目名32
     ,item_name33                                           -- 154.品目名33
     ,item_name34                                           -- 155.品目名34
     ,item_name35                                           -- 156.品目名35
     ,item_name36                                           -- 157.品目名36
     ,item_name37                                           -- 158.品目名37
     ,item_name38                                           -- 159.品目名38
     ,item_name39                                           -- 160.品目名39
     ,item_name40                                           -- 161.品目名40
     ,item_name41                                           -- 162.品目名41
     ,item_name42                                           -- 163.品目名42
     ,item_name43                                           -- 164.品目名43
     ,item_name44                                           -- 165.品目名44
     ,item_name45                                           -- 166.品目名45
     ,item_name46                                           -- 167.品目名46
     ,item_name47                                           -- 168.品目名47
     ,item_name48                                           -- 169.品目名48
     ,item_name49                                           -- 170.品目名49
     ,item_name50                                           -- 171.品目名50
     ,item_name51                                           -- 172.品目名51
     ,item_name52                                           -- 173.品目名52
     ,item_name53                                           -- 174.品目名53
     ,item_name54                                           -- 175.品目名54
     ,item_name55                                           -- 176.品目名55
     ,item_name56                                           -- 177.品目名56
     ,price1                                                -- 178.単価1
     ,price2                                                -- 179.単価2
     ,price3                                                -- 180.単価3
     ,price4                                                -- 181.単価4
     ,price5                                                -- 182.単価5
     ,price6                                                -- 183.単価6
     ,price7                                                -- 184.単価7
     ,price8                                                -- 185.単価8
     ,price9                                                -- 186.単価9
     ,price10                                               -- 187.単価10
     ,price11                                               -- 188.単価11
     ,price12                                               -- 189.単価12
     ,price13                                               -- 190.単価13
     ,price14                                               -- 191.単価14
     ,price15                                               -- 192.単価15
     ,price16                                               -- 193.単価16
     ,price17                                               -- 194.単価17
     ,price18                                               -- 195.単価18
     ,price19                                               -- 196.単価19
     ,price20                                               -- 197.単価20
     ,price21                                               -- 198.単価21
     ,price22                                               -- 199.単価22
     ,price23                                               -- 200.単価23
     ,price24                                               -- 201.単価24
     ,price25                                               -- 202.単価25
     ,price26                                               -- 203.単価26
     ,price27                                               -- 204.単価27
     ,price28                                               -- 205.単価28
     ,price29                                               -- 206.単価29
     ,price30                                               -- 207.単価30
     ,price31                                               -- 208.単価31
     ,price32                                               -- 209.単価32
     ,price33                                               -- 210.単価33
     ,price34                                               -- 211.単価34
     ,price35                                               -- 212.単価35
     ,price36                                               -- 213.単価36
     ,price37                                               -- 214.単価37
     ,price38                                               -- 215.単価38
     ,price39                                               -- 216.単価39
     ,price40                                               -- 217.単価40
     ,price41                                               -- 218.単価41
     ,price42                                               -- 219.単価42
     ,price43                                               -- 220.単価43
     ,price44                                               -- 221.単価44
     ,price45                                               -- 222.単価45
     ,price46                                               -- 223.単価46
     ,price47                                               -- 224.単価47
     ,price48                                               -- 225.単価48
     ,price49                                               -- 226.単価49
     ,price50                                               -- 227.単価50
     ,price51                                               -- 228.単価51
     ,price52                                               -- 229.単価52
     ,price53                                               -- 230.単価53
     ,price54                                               -- 231.単価54
     ,price55                                               -- 232.単価55
     ,price56                                               -- 233.単価56
     ,hot_cold1                                             -- 234.H/C1
     ,hot_cold2                                             -- 235.H/C2
     ,hot_cold3                                             -- 236.H/C3
     ,hot_cold4                                             -- 237.H/C4
     ,hot_cold5                                             -- 238.H/C5
     ,hot_cold6                                             -- 239.H/C6
     ,hot_cold7                                             -- 240.H/C7
     ,hot_cold8                                             -- 241.H/C8
     ,hot_cold9                                             -- 242.H/C9
     ,hot_cold10                                            -- 243.H/C10
     ,hot_cold11                                            -- 244.H/C11
     ,hot_cold12                                            -- 245.H/C12
     ,hot_cold13                                            -- 246.H/C13
     ,hot_cold14                                            -- 247.H/C14
     ,hot_cold15                                            -- 248.H/C15
     ,hot_cold16                                            -- 249.H/C16
     ,hot_cold17                                            -- 250.H/C17
     ,hot_cold18                                            -- 251.H/C18
     ,hot_cold19                                            -- 252.H/C19
     ,hot_cold20                                            -- 253.H/C20
     ,hot_cold21                                            -- 254.H/C21
     ,hot_cold22                                            -- 255.H/C22
     ,hot_cold23                                            -- 256.H/C23
     ,hot_cold24                                            -- 257.H/C24
     ,hot_cold25                                            -- 258.H/C25
     ,hot_cold26                                            -- 259.H/C26
     ,hot_cold27                                            -- 260.H/C27
     ,hot_cold28                                            -- 261.H/C28
     ,hot_cold29                                            -- 262.H/C29
     ,hot_cold30                                            -- 263.H/C30
     ,hot_cold31                                            -- 264.H/C31
     ,hot_cold32                                            -- 265.H/C32
     ,hot_cold33                                            -- 266.H/C33
     ,hot_cold34                                            -- 267.H/C34
     ,hot_cold35                                            -- 268.H/C35
     ,hot_cold36                                            -- 269.H/C36
     ,hot_cold37                                            -- 270.H/C37
     ,hot_cold38                                            -- 271.H/C38
     ,hot_cold39                                            -- 272.H/C39
     ,hot_cold40                                            -- 273.H/C40
     ,hot_cold41                                            -- 274.H/C41
     ,hot_cold42                                            -- 275.H/C42
     ,hot_cold43                                            -- 276.H/C43
     ,hot_cold44                                            -- 277.H/C44
     ,hot_cold45                                            -- 278.H/C45
     ,hot_cold46                                            -- 279.H/C46
     ,hot_cold47                                            -- 280.H/C47
     ,hot_cold48                                            -- 281.H/C48
     ,hot_cold49                                            -- 282.H/C49
     ,hot_cold50                                            -- 283.H/C50
     ,hot_cold51                                            -- 284.H/C51
     ,hot_cold52                                            -- 285.H/C52
     ,hot_cold53                                            -- 286.H/C53
     ,hot_cold54                                            -- 287.H/C54
     ,hot_cold55                                            -- 288.H/C55
     ,hot_cold56                                            -- 289.H/C56
     ,inventory_quantity1                                   -- 290.数量1
     ,inventory_quantity2                                   -- 291.数量2
     ,inventory_quantity3                                   -- 292.数量3
     ,inventory_quantity4                                   -- 293.数量4
     ,inventory_quantity5                                   -- 294.数量5
     ,inventory_quantity6                                   -- 295.数量6
     ,inventory_quantity7                                   -- 296.数量7
     ,inventory_quantity8                                   -- 297.数量8
     ,inventory_quantity9                                   -- 298.数量9
     ,inventory_quantity10                                  -- 299.数量10
     ,inventory_quantity11                                  -- 300.数量11
     ,inventory_quantity12                                  -- 301.数量12
     ,inventory_quantity13                                  -- 302.数量13
     ,inventory_quantity14                                  -- 303.数量14
     ,inventory_quantity15                                  -- 304.数量15
     ,inventory_quantity16                                  -- 305.数量16
     ,inventory_quantity17                                  -- 306.数量17
     ,inventory_quantity18                                  -- 307.数量18
     ,inventory_quantity19                                  -- 308.数量19
     ,inventory_quantity20                                  -- 309.数量20
     ,inventory_quantity21                                  -- 310.数量21
     ,inventory_quantity22                                  -- 311.数量22
     ,inventory_quantity23                                  -- 312.数量23
     ,inventory_quantity24                                  -- 313.数量24
     ,inventory_quantity25                                  -- 314.数量25
     ,inventory_quantity26                                  -- 315.数量26
     ,inventory_quantity27                                  -- 316.数量27
     ,inventory_quantity28                                  -- 317.数量28
     ,inventory_quantity29                                  -- 318.数量29
     ,inventory_quantity30                                  -- 319.数量30
     ,inventory_quantity31                                  -- 320.数量31
     ,inventory_quantity32                                  -- 321.数量32
     ,inventory_quantity33                                  -- 322.数量33
     ,inventory_quantity34                                  -- 323.数量34
     ,inventory_quantity35                                  -- 324.数量35
     ,inventory_quantity36                                  -- 325.数量36
     ,inventory_quantity37                                  -- 326.数量37
     ,inventory_quantity38                                  -- 327.数量38
     ,inventory_quantity39                                  -- 328.数量39
     ,inventory_quantity40                                  -- 329.数量40
     ,inventory_quantity41                                  -- 330.数量41
     ,inventory_quantity42                                  -- 331.数量42
     ,inventory_quantity43                                  -- 332.数量43
     ,inventory_quantity44                                  -- 333.数量44
     ,inventory_quantity45                                  -- 334.数量45
     ,inventory_quantity46                                  -- 335.数量46
     ,inventory_quantity47                                  -- 336.数量47
     ,inventory_quantity48                                  -- 337.数量48
     ,inventory_quantity49                                  -- 338.数量49
     ,inventory_quantity50                                  -- 339.数量50
     ,inventory_quantity51                                  -- 340.数量51
     ,inventory_quantity52                                  -- 341.数量52
     ,inventory_quantity53                                  -- 342.数量53
     ,inventory_quantity54                                  -- 343.数量54
     ,inventory_quantity55                                  -- 344.数量55
     ,inventory_quantity56                                  -- 345.数量56
     ,created_by                                            -- 346.作成者
     ,creation_date                                         -- 347.作成日
     ,last_updated_by                                       -- 348.最終更新者
     ,last_update_date                                      -- 349.最終更新日
     ,last_update_login                                     -- 350.最終更新ユーザ
     ,request_id                                            -- 351.要求ID
     ,program_application_id                                -- 352.プログラムアプリケーションID
     ,program_id                                            -- 353.プログラムID
     ,program_update_date                                   -- 354.プログラム更新日
    )
    VALUES(
      TO_NUMBER(ir_coi_vd_inv_wk_rec(1))                    --   1.ベンダ機内在庫表ワークID
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(2), 1, 4)                --   2.拠点コード
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(3), 1, 240)              --   3.拠点名
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(4), 1, 30)               --   4.顧客コード
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(5), 1, 240)              --   5.顧客名
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(6), 1, 25)               --   6.機種コード
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(7))                    --   7.セレ数
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(8), 1, 30)               --   8.営業担当者コード
     ,ir_coi_vd_inv_wk_rec(9)                               --   9.営業担当者名
-- == 2009/05/19 V1.2 Added START ==================================================================
     ,gv_output_period_meaning                              --  出力期間
-- == 2009/05/19 V1.2 Added END   ==================================================================
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(10))                   --  10.コラム№1
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(11))                   --  11.コラム№2
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(12))                   --  12.コラム№3
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(13))                   --  13.コラム№4
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(14))                   --  14.コラム№5
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(15))                   --  15.コラム№6
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(16))                   --  16.コラム№7
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(17))                   --  17.コラム№8
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(18))                   --  18.コラム№9
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(19))                   --  19.コラム№10
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(20))                   --  20.コラム№11
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(21))                   --  21.コラム№12
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(22))                   --  22.コラム№13
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(23))                   --  23.コラム№14
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(24))                   --  24.コラム№15
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(25))                   --  25.コラム№16
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(26))                   --  26.コラム№17
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(27))                   --  27.コラム№18
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(28))                   --  28.コラム№19
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(29))                   --  29.コラム№20
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(30))                   --  30.コラム№21
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(31))                   --  31.コラム№22
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(32))                   --  32.コラム№23
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(33))                   --  33.コラム№24
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(34))                   --  34.コラム№25
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(35))                   --  35.コラム№26
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(36))                   --  36.コラム№27
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(37))                   --  37.コラム№28
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(38))                   --  38.コラム№29
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(39))                   --  39.コラム№30
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(40))                   --  40.コラム№31
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(41))                   --  41.コラム№32
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(42))                   --  42.コラム№33
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(43))                   --  43.コラム№34
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(44))                   --  44.コラム№35
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(45))                   --  45.コラム№36
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(46))                   --  46.コラム№37
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(47))                   --  47.コラム№38
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(48))                   --  48.コラム№39
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(49))                   --  49.コラム№40
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(50))                   --  50.コラム№41
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(51))                   --  51.コラム№42
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(52))                   --  52.コラム№43
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(53))                   --  53.コラム№44
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(54))                   --  54.コラム№45
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(55))                   --  55.コラム№46
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(56))                   --  56.コラム№47
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(57))                   --  57.コラム№48
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(58))                   --  58.コラム№49
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(59))                   --  59.コラム№50
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(60))                   --  60.コラム№51
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(61))                   --  61.コラム№52
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(62))                   --  62.コラム№53
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(63))                   --  63.コラム№54
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(64))                   --  64.コラム№55
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(65))                   --  65.コラム№56
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(66), 1, 7)               --  66.品目コード1
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(67), 1, 7)               --  67.品目コード2
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(68), 1, 7)               --  68.品目コード3
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(69), 1, 7)               --  69.品目コード4
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(70), 1, 7)               --  70.品目コード5
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(71), 1, 7)               --  71.品目コード6
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(72), 1, 7)               --  72.品目コード7
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(73), 1, 7)               --  73.品目コード8
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(74), 1, 7)               --  74.品目コード9
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(75), 1, 7)               --  75.品目コード10
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(76), 1, 7)               --  76.品目コード11
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(77), 1, 7)               --  77.品目コード12
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(78), 1, 7)               --  78.品目コード13
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(79), 1, 7)               --  79.品目コード14
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(80), 1, 7)               --  80.品目コード15
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(81), 1, 7)               --  81.品目コード16
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(82), 1, 7)               --  82.品目コード17
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(83), 1, 7)               --  83.品目コード18
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(84), 1, 7)               --  84.品目コード19
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(85), 1, 7)               --  85.品目コード20
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(86), 1, 7)               --  86.品目コード21
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(87), 1, 7)               --  87.品目コード22
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(88), 1, 7)               --  88.品目コード23
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(89), 1, 7)               --  89.品目コード24
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(90), 1, 7)               --  90.品目コード25
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(91), 1, 7)               --  91.品目コード26
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(92), 1, 7)               --  92.品目コード27
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(93), 1, 7)               --  93.品目コード28
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(94), 1, 7)               --  94.品目コード29
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(95), 1, 7)               --  95.品目コード30
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(96), 1, 7)               --  96.品目コード31
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(97), 1, 7)               --  97.品目コード32
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(98), 1, 7)               --  98.品目コード33
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(99), 1, 7)               --  99.品目コード34
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(100), 1, 7)              -- 100.品目コード35
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(101), 1, 7)              -- 101.品目コード36
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(102), 1, 7)              -- 102.品目コード37
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(103), 1, 7)              -- 103.品目コード38
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(104), 1, 7)              -- 104.品目コード39
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(105), 1, 7)              -- 105.品目コード40
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(106), 1, 7)              -- 106.品目コード41
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(107), 1, 7)              -- 107.品目コード42
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(108), 1, 7)              -- 108.品目コード43
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(109), 1, 7)              -- 109.品目コード44
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(110), 1, 7)              -- 110.品目コード45
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(111), 1, 7)              -- 111.品目コード46
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(112), 1, 7)              -- 112.品目コード47
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(113), 1, 7)              -- 113.品目コード48
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(114), 1, 7)              -- 114.品目コード49
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(115), 1, 7)              -- 115.品目コード50
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(116), 1, 7)              -- 116.品目コード51
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(117), 1, 7)              -- 117.品目コード52
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(118), 1, 7)              -- 118.品目コード53
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(119), 1, 7)              -- 119.品目コード54
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(120), 1, 7)              -- 120.品目コード55
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(121), 1, 7)              -- 121.品目コード56
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(122), 1, 20)             -- 122.品目名1
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(123), 1, 20)             -- 123.品目名2
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(124), 1, 20)             -- 124.品目名3
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(125), 1, 20)             -- 125.品目名4
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(126), 1, 20)             -- 126.品目名5
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(127), 1, 20)             -- 127.品目名6
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(128), 1, 20)             -- 128.品目名7
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(129), 1, 20)             -- 129.品目名8
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(130), 1, 20)             -- 130.品目名9
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(131), 1, 20)             -- 131.品目名10
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(132), 1, 20)             -- 132.品目名11
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(133), 1, 20)             -- 133.品目名12
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(134), 1, 20)             -- 134.品目名13
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(135), 1, 20)             -- 135.品目名14
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(136), 1, 20)             -- 136.品目名15
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(137), 1, 20)             -- 137.品目名16
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(138), 1, 20)             -- 138.品目名17
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(139), 1, 20)             -- 139.品目名18
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(140), 1, 20)             -- 140.品目名19
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(141), 1, 20)             -- 141.品目名20
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(142), 1, 20)             -- 142.品目名21
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(143), 1, 20)             -- 143.品目名22
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(144), 1, 20)             -- 144.品目名23
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(145), 1, 20)             -- 145.品目名24
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(146), 1, 20)             -- 146.品目名25
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(147), 1, 20)             -- 147.品目名26
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(148), 1, 20)             -- 148.品目名27
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(149), 1, 20)             -- 149.品目名28
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(150), 1, 20)             -- 150.品目名29
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(151), 1, 20)             -- 151.品目名30
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(152), 1, 20)             -- 152.品目名31
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(153), 1, 20)             -- 153.品目名32
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(154), 1, 20)             -- 154.品目名33
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(155), 1, 20)             -- 155.品目名34
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(156), 1, 20)             -- 156.品目名35
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(157), 1, 20)             -- 157.品目名36
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(158), 1, 20)             -- 158.品目名37
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(159), 1, 20)             -- 159.品目名38
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(160), 1, 20)             -- 160.品目名39
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(161), 1, 20)             -- 161.品目名40
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(162), 1, 20)             -- 162.品目名41
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(163), 1, 20)             -- 163.品目名42
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(164), 1, 20)             -- 164.品目名43
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(165), 1, 20)             -- 165.品目名44
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(166), 1, 20)             -- 166.品目名45
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(167), 1, 20)             -- 167.品目名46
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(168), 1, 20)             -- 168.品目名47
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(169), 1, 20)             -- 169.品目名48
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(170), 1, 20)             -- 170.品目名49
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(171), 1, 20)             -- 171.品目名50
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(172), 1, 20)             -- 172.品目名51
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(173), 1, 20)             -- 173.品目名52
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(174), 1, 20)             -- 174.品目名53
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(175), 1, 20)             -- 175.品目名54
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(176), 1, 20)             -- 176.品目名55
     ,SUBSTRB(ir_coi_vd_inv_wk_rec(177), 1, 20)             -- 177.品目名56
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(178))                  -- 178.単価1
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(179))                  -- 179.単価2
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(180))                  -- 180.単価3
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(181))                  -- 181.単価4
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(182))                  -- 182.単価5
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(183))                  -- 183.単価6
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(184))                  -- 184.単価7
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(185))                  -- 185.単価8
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(186))                  -- 186.単価9
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(187))                  -- 187.単価10
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(188))                  -- 188.単価11
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(189))                  -- 189.単価12
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(190))                  -- 190.単価13
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(191))                  -- 191.単価14
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(192))                  -- 192.単価15
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(193))                  -- 193.単価16
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(194))                  -- 194.単価17
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(195))                  -- 195.単価18
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(196))                  -- 196.単価19
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(197))                  -- 197.単価20
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(198))                  -- 198.単価21
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(199))                  -- 199.単価22
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(200))                  -- 200.単価23
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(201))                  -- 201.単価24
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(202))                  -- 202.単価25
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(203))                  -- 203.単価26
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(204))                  -- 204.単価27
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(205))                  -- 205.単価28
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(206))                  -- 206.単価29
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(207))                  -- 207.単価30
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(208))                  -- 208.単価31
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(209))                  -- 209.単価32
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(210))                  -- 210.単価33
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(211))                  -- 211.単価34
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(212))                  -- 212.単価35
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(213))                  -- 213.単価36
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(214))                  -- 214.単価37
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(215))                  -- 215.単価38
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(216))                  -- 216.単価39
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(217))                  -- 217.単価40
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(218))                  -- 218.単価41
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(219))                  -- 219.単価42
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(220))                  -- 220.単価43
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(221))                  -- 221.単価44
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(222))                  -- 222.単価45
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(223))                  -- 223.単価46
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(224))                  -- 224.単価47
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(225))                  -- 225.単価48
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(226))                  -- 226.単価49
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(227))                  -- 227.単価50
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(228))                  -- 228.単価51
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(229))                  -- 229.単価52
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(230))                  -- 230.単価53
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(231))                  -- 231.単価54
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(232))                  -- 232.単価55
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(233))                  -- 233.単価56
-- == 2009/05/19 V1.2 Modified START ===============================================================
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(234), 1, 1)              -- 234.H/C1
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(235), 1, 1)              -- 235.H/C2
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(236), 1, 1)              -- 236.H/C3
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(237), 1, 1)              -- 237.H/C4
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(238), 1, 1)              -- 238.H/C5
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(239), 1, 1)              -- 239.H/C6
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(240), 1, 1)              -- 240.H/C7
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(241), 1, 1)              -- 241.H/C8
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(242), 1, 1)              -- 242.H/C9
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(243), 1, 1)              -- 243.H/C10
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(244), 1, 1)              -- 244.H/C11
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(245), 1, 1)              -- 245.H/C12
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(246), 1, 1)              -- 246.H/C13
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(247), 1, 1)              -- 247.H/C14
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(248), 1, 1)              -- 248.H/C15
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(249), 1, 1)              -- 249.H/C16
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(250), 1, 1)              -- 250.H/C17
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(251), 1, 1)              -- 251.H/C18
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(252), 1, 1)              -- 252.H/C19
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(253), 1, 1)              -- 253.H/C20
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(254), 1, 1)              -- 254.H/C21
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(255), 1, 1)              -- 255.H/C22
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(256), 1, 1)              -- 256.H/C23
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(257), 1, 1)              -- 257.H/C24
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(258), 1, 1)              -- 258.H/C25
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(259), 1, 1)              -- 259.H/C26
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(260), 1, 1)              -- 260.H/C27
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(261), 1, 1)              -- 261.H/C28
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(262), 1, 1)              -- 262.H/C29
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(263), 1, 1)              -- 263.H/C30
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(264), 1, 1)              -- 264.H/C31
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(265), 1, 1)              -- 265.H/C32
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(266), 1, 1)              -- 266.H/C33
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(267), 1, 1)              -- 267.H/C34
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(268), 1, 1)              -- 268.H/C35
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(269), 1, 1)              -- 269.H/C36
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(270), 1, 1)              -- 270.H/C37
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(271), 1, 1)              -- 271.H/C38
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(272), 1, 1)              -- 272.H/C39
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(273), 1, 1)              -- 273.H/C40
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(274), 1, 1)              -- 274.H/C41
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(275), 1, 1)              -- 275.H/C42
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(276), 1, 1)              -- 276.H/C43
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(277), 1, 1)              -- 277.H/C44
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(278), 1, 1)              -- 278.H/C45
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(279), 1, 1)              -- 279.H/C46
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(280), 1, 1)              -- 280.H/C47
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(281), 1, 1)              -- 281.H/C48
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(282), 1, 1)              -- 282.H/C49
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(283), 1, 1)              -- 283.H/C50
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(284), 1, 1)              -- 284.H/C51
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(285), 1, 1)              -- 285.H/C52
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(286), 1, 1)              -- 286.H/C53
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(287), 1, 1)              -- 287.H/C54
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(288), 1, 1)              -- 288.H/C55
--     ,SUBSTRB(ir_coi_vd_inv_wk_rec(289), 1, 1)              -- 289.H/C56
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(234), 1, 1), '3', 'H', '1', 'C', '')  -- 234.H/C1
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(235), 1, 1), '3', 'H', '1', 'C', '')  -- 235.H/C2
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(236), 1, 1), '3', 'H', '1', 'C', '')  -- 236.H/C3
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(237), 1, 1), '3', 'H', '1', 'C', '')  -- 237.H/C4
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(238), 1, 1), '3', 'H', '1', 'C', '')  -- 238.H/C5
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(239), 1, 1), '3', 'H', '1', 'C', '')  -- 239.H/C6
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(240), 1, 1), '3', 'H', '1', 'C', '')  -- 240.H/C7
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(241), 1, 1), '3', 'H', '1', 'C', '')  -- 241.H/C8
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(242), 1, 1), '3', 'H', '1', 'C', '')  -- 242.H/C9
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(243), 1, 1), '3', 'H', '1', 'C', '')  -- 243.H/C10
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(244), 1, 1), '3', 'H', '1', 'C', '')  -- 244.H/C11
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(245), 1, 1), '3', 'H', '1', 'C', '')  -- 245.H/C12
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(246), 1, 1), '3', 'H', '1', 'C', '')  -- 246.H/C13
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(247), 1, 1), '3', 'H', '1', 'C', '')  -- 247.H/C14
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(248), 1, 1), '3', 'H', '1', 'C', '')  -- 248.H/C15
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(249), 1, 1), '3', 'H', '1', 'C', '')  -- 249.H/C16
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(250), 1, 1), '3', 'H', '1', 'C', '')  -- 250.H/C17
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(251), 1, 1), '3', 'H', '1', 'C', '')  -- 251.H/C18
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(252), 1, 1), '3', 'H', '1', 'C', '')  -- 252.H/C19
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(253), 1, 1), '3', 'H', '1', 'C', '')  -- 253.H/C20
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(254), 1, 1), '3', 'H', '1', 'C', '')  -- 254.H/C21
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(255), 1, 1), '3', 'H', '1', 'C', '')  -- 255.H/C22
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(256), 1, 1), '3', 'H', '1', 'C', '')  -- 256.H/C23
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(257), 1, 1), '3', 'H', '1', 'C', '')  -- 257.H/C24
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(258), 1, 1), '3', 'H', '1', 'C', '')  -- 258.H/C25
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(259), 1, 1), '3', 'H', '1', 'C', '')  -- 259.H/C26
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(260), 1, 1), '3', 'H', '1', 'C', '')  -- 260.H/C27
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(261), 1, 1), '3', 'H', '1', 'C', '')  -- 261.H/C28
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(262), 1, 1), '3', 'H', '1', 'C', '')  -- 262.H/C29
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(263), 1, 1), '3', 'H', '1', 'C', '')  -- 263.H/C30
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(264), 1, 1), '3', 'H', '1', 'C', '')  -- 264.H/C31
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(265), 1, 1), '3', 'H', '1', 'C', '')  -- 265.H/C32
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(266), 1, 1), '3', 'H', '1', 'C', '')  -- 266.H/C33
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(267), 1, 1), '3', 'H', '1', 'C', '')  -- 267.H/C34
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(268), 1, 1), '3', 'H', '1', 'C', '')  -- 268.H/C35
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(269), 1, 1), '3', 'H', '1', 'C', '')  -- 269.H/C36
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(270), 1, 1), '3', 'H', '1', 'C', '')  -- 270.H/C37
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(271), 1, 1), '3', 'H', '1', 'C', '')  -- 271.H/C38
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(272), 1, 1), '3', 'H', '1', 'C', '')  -- 272.H/C39
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(273), 1, 1), '3', 'H', '1', 'C', '')  -- 273.H/C40
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(274), 1, 1), '3', 'H', '1', 'C', '')  -- 274.H/C41
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(275), 1, 1), '3', 'H', '1', 'C', '')  -- 275.H/C42
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(276), 1, 1), '3', 'H', '1', 'C', '')  -- 276.H/C43
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(277), 1, 1), '3', 'H', '1', 'C', '')  -- 277.H/C44
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(278), 1, 1), '3', 'H', '1', 'C', '')  -- 278.H/C45
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(279), 1, 1), '3', 'H', '1', 'C', '')  -- 279.H/C46
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(280), 1, 1), '3', 'H', '1', 'C', '')  -- 280.H/C47
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(281), 1, 1), '3', 'H', '1', 'C', '')  -- 281.H/C48
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(282), 1, 1), '3', 'H', '1', 'C', '')  -- 282.H/C49
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(283), 1, 1), '3', 'H', '1', 'C', '')  -- 283.H/C50
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(284), 1, 1), '3', 'H', '1', 'C', '')  -- 284.H/C51
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(285), 1, 1), '3', 'H', '1', 'C', '')  -- 285.H/C52
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(286), 1, 1), '3', 'H', '1', 'C', '')  -- 286.H/C53
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(287), 1, 1), '3', 'H', '1', 'C', '')  -- 287.H/C54
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(288), 1, 1), '3', 'H', '1', 'C', '')  -- 288.H/C55
     ,DECODE(SUBSTRB(ir_coi_vd_inv_wk_rec(289), 1, 1), '3', 'H', '1', 'C', '')  -- 289.H/C56
-- == 2009/05/19 V1.2 Modified END   ===============================================================
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(290))                  -- 290.数量1
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(291))                  -- 291.数量2
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(292))                  -- 292.数量3
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(293))                  -- 293.数量4
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(294))                  -- 294.数量5
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(295))                  -- 295.数量6
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(296))                  -- 296.数量7
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(297))                  -- 297.数量8
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(298))                  -- 298.数量9
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(299))                  -- 299.数量10
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(300))                  -- 300.数量11
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(301))                  -- 301.数量12
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(302))                  -- 302.数量13
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(303))                  -- 303.数量14
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(304))                  -- 304.数量15
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(305))                  -- 305.数量16
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(306))                  -- 306.数量17
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(307))                  -- 307.数量18
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(308))                  -- 308.数量19
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(309))                  -- 309.数量20
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(310))                  -- 310.数量21
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(311))                  -- 311.数量22
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(312))                  -- 312.数量23
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(313))                  -- 313.数量24
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(314))                  -- 314.数量25
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(315))                  -- 315.数量26
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(316))                  -- 316.数量27
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(317))                  -- 317.数量28
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(318))                  -- 318.数量29
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(319))                  -- 319.数量30
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(320))                  -- 320.数量31
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(321))                  -- 321.数量32
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(322))                  -- 322.数量33
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(323))                  -- 323.数量34
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(324))                  -- 324.数量35
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(325))                  -- 325.数量36
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(326))                  -- 326.数量37
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(327))                  -- 327.数量38
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(328))                  -- 328.数量39
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(329))                  -- 329.数量40
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(330))                  -- 330.数量41
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(331))                  -- 331.数量42
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(332))                  -- 332.数量43
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(333))                  -- 333.数量44
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(334))                  -- 334.数量45
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(335))                  -- 335.数量46
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(336))                  -- 336.数量47
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(337))                  -- 337.数量48
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(338))                  -- 338.数量49
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(339))                  -- 339.数量50
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(340))                  -- 340.数量51
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(341))                  -- 341.数量52
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(342))                  -- 342.数量53
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(343))                  -- 343.数量54
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(344))                  -- 344.数量55
     ,TO_NUMBER(ir_coi_vd_inv_wk_rec(345))                  -- 345.数量56
     ,cn_created_by                                         -- 346.作成者
     ,cd_creation_date                                      -- 347.作成日
     ,cn_last_updated_by                                    -- 348.最終更新者
     ,cd_last_update_date                                   -- 349.最終更新日
     ,cn_last_update_login                                  -- 350.最終更新ユーザ
     ,cn_request_id                                         -- 351.要求ID
     ,cn_program_application_id                             -- 352.プログラムアプリケーションID
     ,cn_program_id                                         -- 353.プログラムID
     ,cd_program_update_date                                -- 354.プログラム更新日
    );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_vd_inv_wk;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
-- == 2009/05/19 V1.2 Added START ==================================================================
    cv_lookup_type          CONSTANT VARCHAR2(30) := 'XXCOI1_VD_OUTPUT_PERIOD';  -- 参照タイプ
-- == 2009/05/19 V1.2 Added END   ==================================================================
--
    -- *** ローカル変数 ***
    lv_param_msg   VARCHAR2(5000);
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
    -- SYSDATE、WHOカラム取得(ヘッダーにて取得済み)
--
    --==============================================================
    --パラメータ・ログ出力
    --==============================================================
    -- 出力拠点
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10150
                     ,iv_token_name1  => cv_tkn_name_p_base
                     ,iv_token_value1 => gv_output_base);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 出力期間
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10151
                     ,iv_token_name1  => cv_tkn_name_p_term
                     ,iv_token_value1 => gv_output_period);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 出力対象
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10152
                     ,iv_token_name1  => cv_tkn_name_p_subject
                     ,iv_token_value1 => gv_output_target);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 営業員1
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '1'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_1);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 営業員2
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '2'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_2);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 営業員3
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '3'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_3);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 営業員4
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '4'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_4);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 営業員5
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '5'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_5);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 営業員6
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10153
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '6'
                     ,iv_token_name2  => cv_tkn_name_p_employee
                     ,iv_token_value2 => gv_sales_staff_6);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客1
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '1'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_1);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客2
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '2'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_2);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客3
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '3'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_3);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客4
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '4'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_4);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客5
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '5'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_5);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客6
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '6'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_6);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客7
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '7'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_7);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客8
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '8'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_8);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客9
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '9'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_9);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客10
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '10'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_10);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客11
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '11'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_11);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 顧客12
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10154
                     ,iv_token_name1  => cv_tkn_name_p_num
                     ,iv_token_value1 => '12'
                     ,iv_token_name2  => cv_tkn_name_p_customer
                     ,iv_token_value2 => gv_customer_12);
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_param_msg);
--
    -- 空行出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
-- == 2009/05/19 V1.2 Added START ==================================================================
    -- ===============================
    -- 出力期間内容取得
    -- ===============================
    gv_output_period_meaning := xxcoi_common_pkg.get_meaning(cv_lookup_type, gv_output_period);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( gv_output_period_meaning IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_coi
                     ,iv_name         => cv_msg_coi_10383
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_lookup_type
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => gv_output_period
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- == 2009/05/19 V1.2 Added END   ==================================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
-- == 2009/08/13 V1.5 Added START ==================================================================
    -- ===================================
    --  在庫組織コード取得
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- プロファイル:在庫組織コード( &PRO_TOK )の取得に失敗しました。
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_msg_coi_00005
                       ,iv_token_name1  => cv_tkn_pro
                       ,iv_token_value1 => cv_prf_name_orgcd
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===================================
    --  在庫組織ID取得
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- 在庫組織コード( &ORG_CODE_TOK )に対する在庫組織IDの取得に失敗しました。
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_msg_coi_00006
                       ,iv_token_name1  => cv_tkn_org_code
                       ,iv_token_value1 => gv_f_organization_code
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- == 2009/08/13 V1.5 Added END   ==================================================================
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータ必須チェック(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf  OUT VARCHAR2  --   エラー・メッセージ
   ,ov_retcode OUT VARCHAR2  --   リターン・コード
   ,ov_errmsg  OUT VARCHAR2) --   ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
    -- 出力拠点がNULLの場合
    IF (gv_output_base IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10304);
      RAISE global_api_expt;
    END IF;
--
    -- 出力期間がNULLの場合
    IF (gv_output_period IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10305);
      RAISE global_api_expt;
    END IF;
--
    -- 出力対象がNULLの場合
    IF (gv_output_target IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10306);
      RAISE global_api_expt;
    END IF;
--
-- == 2009/06/26 V1.3 Added START ==================================================================
    IF (    (gv_sales_staff_1 IS NULL)
        AND (gv_sales_staff_2 IS NULL)
        AND (gv_sales_staff_3 IS NULL)
        AND (gv_sales_staff_4 IS NULL)
        AND (gv_sales_staff_5 IS NULL)
        AND (gv_sales_staff_6 IS NULL)
       )
    THEN
      -- 営業員が指定されていない場合
      gv_staff_prm_flg := cv_staff_prm_no;
    ELSE
      -- 営業員が指定されている場合
      gv_staff_prm_flg := cv_staff_prm_yes;
    END IF;
-- == 2009/06/26 V1.3 Added END   ==================================================================
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode   := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2    --    エラー・バッファ
   ,ov_retcode OUT VARCHAR2    --    リターン・コード
   ,ov_errmsg  OUT VARCHAR2)   --    エラー・メッセージ
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
    cv_0               CONSTANT VARCHAR2(1) := '0';
    cv_1               CONSTANT VARCHAR2(1) := '1';
    -- *** ローカル変数 ***
    ln_vd_inv_wk_id    NUMBER;         -- ベンダ機内在庫表ワークID
    ln_cust_loop_cnt   NUMBER;         -- 顧客ループカウンター
    ln_column_cnt      NUMBER;         -- コラム列数カウンター
    ln_rack_cnt        NUMBER;         -- ラック数カウンター
    lv_is_next_rec_flg VARCHAR2(1);    -- 次レコード存在フラグ(無し:N、有り:Y)
    lv_zero_message    VARCHAR2(1000); -- 0件メッセージ
-- == 2009/06/26 V1.3 Added START ==================================================================
    lv_skip_flg        VARCHAR2(1);                              -- 対象顧客スキップフラグ
-- == 2009/06/26 V1.3 Added END   ==================================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 顧客情報抽出カーソル
    CURSOR get_customer_info_cur(
      lv_output_base     VARCHAR2    --  1.出力拠点
     ,lv_output_period   VARCHAR2    --  2.出力期間
     ,lv_output_target   VARCHAR2    --  3.出力対象
-- == 2009/06/26 V1.3 Delete START ==================================================================
--     ,lv_sales_staff_1   VARCHAR2    --  4.営業員1
--     ,lv_sales_staff_2   VARCHAR2    --  5.営業員2
--     ,lv_sales_staff_3   VARCHAR2    --  6.営業員3
--     ,lv_sales_staff_4   VARCHAR2    --  7.営業員4
--     ,lv_sales_staff_5   VARCHAR2    --  8.営業員5
--     ,lv_sales_staff_6   VARCHAR2    --  9.営業員6
-- == 2009/06/26 V1.3 Delete END   ==================================================================
     ,lv_customer_1      VARCHAR2    -- 10.顧客1
     ,lv_customer_2      VARCHAR2    -- 11.顧客2
     ,lv_customer_3      VARCHAR2    -- 12.顧客3
     ,lv_customer_4      VARCHAR2    -- 13.顧客4
     ,lv_customer_5      VARCHAR2    -- 14.顧客5
     ,lv_customer_6      VARCHAR2    -- 15.顧客6
     ,lv_customer_7      VARCHAR2    -- 16.顧客7
     ,lv_customer_8      VARCHAR2    -- 17.顧客8
     ,lv_customer_9      VARCHAR2    -- 18.顧客9
     ,lv_customer_10     VARCHAR2    -- 19.顧客10
     ,lv_customer_11     VARCHAR2    -- 20.顧客11
     ,lv_customer_12     VARCHAR2)   -- 21.顧客12
    IS
    SELECT hca1.cust_account_id              AS customer_id                        --  1.顧客ID
          ,DECODE(lv_output_period
            ,cv_0 ,xca1.sale_base_code
            ,cv_1 ,xca1.past_sale_base_code) AS base_code                          --  2.拠点コード
          ,hca2.account_name                 AS base_name                          --  3.拠点名
          ,hca1.account_number               AS customer_code                      --  4.顧客コード
          ,hca1.account_name                 AS customer_name                      --  5.顧客名
-- == 2009/08/13 V1.5 Modified START ===============================================================
--          ,punv.un_number                    AS model_code                         --  6.機種コード
--          ,TO_NUMBER(punv.attribute8)        AS sele_quantity                      --  7.セレ数
          ,NULL                              AS model_code                         --  6.機種コード
          ,NULL                              AS sele_quantity                      --  7.セレ数
-- == 2009/08/13 V1.5 Modified END   ===============================================================
-- == 2009/06/26 V1.3 Modified START ==================================================================
--          ,xmvc1.rack_quantity               AS rack_quantity                      --  8.ラック数
--          ,jrre.source_number                AS charge_business_member_code        --  9.担当営業員コード
--          ,jrre.source_name                  AS charge_business_member_name        -- 10.担当営業員名
          ,NULL                              AS rack_quantity                      --  8.ラック数
          ,NULL                              AS charge_business_member_code        --  9.担当営業員コード
          ,NULL                              AS charge_business_member_name        -- 10.担当営業員名
--    FROM   xxcoi_mst_vd_column                  xmvc1                         --  1.VDコラムマスタ
--          ,hz_cust_accounts                     hca1                          --  2.顧客アカウント
    FROM   hz_cust_accounts                     hca1                          --  顧客アカウント
-- == 2009/06/26 V1.3 Modified END   ==================================================================
          ,xxcmm_cust_accounts                  xca1                          --  3.顧客追加情報
          ,hz_parties                           hp1                           --  4.パーティマスタ
          ,hz_cust_accounts                     hca2                          --  5.顧客アカウント(拠点)
          ,hz_parties                           hp2                           --  6.パーティマスタ(拠点)
-- == 2009/08/13 V1.5 Deleted START ===============================================================
--          ,csi_item_instances                   cii                           --  7.物件マスタ
--          ,po_un_numbers_vl                     punv                          --  8.機種マスタ
-- == 2009/08/13 V1.5 Deleted END   ===============================================================
-- == 2009/06/26 V1.3 Delete START ==================================================================
--          ,hz_organization_profiles             hop                           --  9.組織プロファイルマスタ
--          ,ego_resource_agv                     era                           -- 10.リソースビュー
--          ,jtf_rs_resource_extns                jrre                          -- 11.リソース
--          ,(SELECT DISTINCT hca3.cust_account_id   AS cust_account_id
--            FROM   hz_cust_accounts      hca3  --  顧客アカウント
--            WHERE  EXISTS (
--              SELECT 'X'
--              FROM   xxcoi_mst_vd_column    xmvc2
--              WHERE  hca3.cust_account_id = xmvc2.customer_id 
--              AND    (lv_output_target = cv_1
--                   OR lv_output_target = cv_0
--                   AND NOT EXISTS (
--                     SELECT 'X'
--                     FROM   xxcoi_mst_vd_column  xmvc3   -- VDコラムマスタ
--                     WHERE  xmvc3.vd_column_mst_id    = xmvc2.vd_column_mst_id
--                     AND    xmvc3.customer_id         = xmvc2.customer_id  
--                     AND    NVL(xmvc3.item_id, -1)    = NVL(xmvc3.last_month_item_id, -1)
--                     AND    xmvc3.inventory_quantity  = xmvc3.last_month_inventory_quantity
--                     AND    NVL(xmvc3.price, -1)      = NVL(xmvc3.last_month_price, -1)
--                     AND    NVL(xmvc3.hot_cold, cv_0) = NVL(xmvc3.last_month_hot_cold, cv_0)))))  sub_quary -- 12.サブクエリー
-- == 2009/06/26 V1.3 Delete END   ==================================================================
-- == 2009/06/26 V1.3 Modified START ==================================================================
--    WHERE  sub_quary.cust_account_id            = xmvc1.customer_id
--    AND    xmvc1.column_no                      = 1
--    AND    xmvc1.customer_id                    = hca1.cust_account_id
--    AND    hp1.party_id                         = hca1.party_id
    WHERE  hp1.party_id                         = hca1.party_id
-- == 2009/06/26 V1.3 Modified END   ==================================================================
    AND    hca1.cust_account_id                 = xca1.customer_id
    AND    hp1.duns_number_c                    IN (30, 40, 50, 80)
    AND    hp2.party_id                         = hca2.party_id
-- == 2009/08/13 V1.5 Deleted START ===============================================================
--    AND    hca1.cust_account_id                 = cii.owner_party_account_id
--    AND    cii.instance_status_id               <> 1
--    AND    cii.attribute1                       = punv.un_number
--    AND    punv.attribute8                      IS NOT NULL
--    AND    punv.attribute8                      <> 0
-- == 2009/08/13 V1.5 Deleted END   ===============================================================
    AND    ((lv_output_period  = cv_0 AND hca2.account_number = xca1.sale_base_code)
           OR(lv_output_period = cv_1 AND hca2.account_number = xca1.past_sale_base_code))
    AND    lv_output_base                       = hca2.account_number
    AND    hp1.party_id                         = hca1.party_id
-- == 2009/06/26 V1.3 Delete START ==================================================================
--    AND    hca1.party_id                        = hop.party_id
--    AND    hop.organization_profile_id          = era.organization_profile_id(+)
--    AND    TRUNC(hop.effective_start_date) <= TRUNC(xxccp_common_pkg2.get_process_date)
--    AND    TRUNC(NVL(hop.effective_end_date, xxccp_common_pkg2.get_process_date)) >= TRUNC(xxccp_common_pkg2.get_process_date)
--    AND    TRUNC(NVL(era.resource_s_date, xxccp_common_pkg2.get_process_date)) <= TRUNC(xxccp_common_pkg2.get_process_date)
--    AND    TRUNC(NVL(era.resource_e_date, xxccp_common_pkg2.get_process_date)) >= TRUNC(xxccp_common_pkg2.get_process_date)
--    AND    era.resource_no                      = jrre.source_number(+)
-- == 2009/06/26 V1.3 Delete END   ==================================================================
-- == 2009/06/26 V1.3 Added START ==================================================================
    AND ((lv_output_target = cv_1)
         OR 
         (    lv_output_target = cv_0
          AND EXISTS (SELECT  1
                      FROM    (SELECT   xmvc2.customer_id
                               FROM     xxcoi_mst_vd_column xmvc2
                               WHERE    (         (xmvc2.inventory_quantity   !=  xmvc2.last_month_inventory_quantity)
                                         OR       (NVL(xmvc2.item_id, -1)     !=  NVL(xmvc2.last_month_item_id, -1))
                                         OR       (NVL(xmvc2.price, -1)       !=  NVL(xmvc2.last_month_price, -1))
                                         OR       (NVL(xmvc2.hot_cold, cv_0)  !=  NVL(xmvc2.last_month_hot_cold, cv_0))
                                        )
-- == 2009/07/09 V1.4 Delete START ==================================================================
--                               AND      ROWNUM = 1
-- == 2009/07/09 V1.4 Delete END   ==================================================================
                              )         sub_query
                      WHERE   sub_query.customer_id = hca1.cust_account_id
              )
         )
        )
-- == 2009/06/26 V1.3 Added END   ==================================================================
-- == 2009/06/26 V1.3 Modified START ==================================================================
--    AND    ((  lv_sales_staff_1 IS NULL
--           AND lv_sales_staff_2 IS NULL
--           AND lv_sales_staff_3 IS NULL
--           AND lv_sales_staff_4 IS NULL
--           AND lv_sales_staff_5 IS NULL
--           AND lv_sales_staff_6 IS NULL
--           AND lv_customer_1    IS NULL
--           AND lv_customer_2    IS NULL
--           AND lv_customer_3    IS NULL
--           AND lv_customer_4    IS NULL
--           AND lv_customer_5    IS NULL
--           AND lv_customer_6    IS NULL
--           AND lv_customer_7    IS NULL
--           AND lv_customer_8    IS NULL
--           AND lv_customer_9    IS NULL
--           AND lv_customer_10   IS NULL
--           AND lv_customer_11   IS NULL
--           AND lv_customer_12   IS NULL)
--           OR
--           (  NVL(lv_sales_staff_1, '#') = jrre.source_number
--           OR NVL(lv_sales_staff_2, '#') = jrre.source_number
--           OR NVL(lv_sales_staff_3, '#') = jrre.source_number
--           OR NVL(lv_sales_staff_4, '#') = jrre.source_number
--           OR NVL(lv_sales_staff_5, '#') = jrre.source_number
--           OR NVL(lv_sales_staff_6, '#') = jrre.source_number
--           OR NVL(lv_customer_1,    '#') = hca1.account_number
--           OR NVL(lv_customer_2,    '#') = hca1.account_number
--           OR NVL(lv_customer_3,    '#') = hca1.account_number
--           OR NVL(lv_customer_4,    '#') = hca1.account_number
--           OR NVL(lv_customer_5,    '#') = hca1.account_number
--           OR NVL(lv_customer_6,    '#') = hca1.account_number
--           OR NVL(lv_customer_7,    '#') = hca1.account_number
--           OR NVL(lv_customer_8,    '#') = hca1.account_number
--           OR NVL(lv_customer_9,    '#') = hca1.account_number
--           OR NVL(lv_customer_10,   '#') = hca1.account_number
--           OR NVL(lv_customer_11,   '#') = hca1.account_number
--           OR NVL(lv_customer_12,   '#') = hca1.account_number))
    AND    ((  lv_customer_1    IS NULL
           AND lv_customer_2    IS NULL
           AND lv_customer_3    IS NULL
           AND lv_customer_4    IS NULL
           AND lv_customer_5    IS NULL
           AND lv_customer_6    IS NULL
           AND lv_customer_7    IS NULL
           AND lv_customer_8    IS NULL
           AND lv_customer_9    IS NULL
           AND lv_customer_10   IS NULL
           AND lv_customer_11   IS NULL
           AND lv_customer_12   IS NULL)
           OR
           (  NVL(lv_customer_1,    '#') = hca1.account_number
           OR NVL(lv_customer_2,    '#') = hca1.account_number
           OR NVL(lv_customer_3,    '#') = hca1.account_number
           OR NVL(lv_customer_4,    '#') = hca1.account_number
           OR NVL(lv_customer_5,    '#') = hca1.account_number
           OR NVL(lv_customer_6,    '#') = hca1.account_number
           OR NVL(lv_customer_7,    '#') = hca1.account_number
           OR NVL(lv_customer_8,    '#') = hca1.account_number
           OR NVL(lv_customer_9,    '#') = hca1.account_number
           OR NVL(lv_customer_10,   '#') = hca1.account_number
           OR NVL(lv_customer_11,   '#') = hca1.account_number
           OR NVL(lv_customer_12,   '#') = hca1.account_number))
-- == 2009/06/26 V1.3 Modified END   ==================================================================
    ORDER BY customer_code;
--
    -- コラム情報抽出カーソル
    CURSOR get_column_info_cur(
      lv_output_period   VARCHAR2    --  1.出力期間
     ,lv_customer_id     VARCHAR2)   --  2.顧客ID
    IS
    SELECT xmvc.column_no                                                           AS column_no     -- 1.コラム№
          ,sub_query.item_code                                                      AS item_code     -- 2.品目コード
          ,sub_query.short_name                                                     AS item_name     -- 3.品目名(略称)
          ,DECODE(lv_output_period
            ,'0' ,xmvc.price ,'1' ,xmvc.last_month_price)                           AS price         -- 4.単価
          ,DECODE(lv_output_period
            ,'0' ,xmvc.hot_cold ,'1' ,xmvc.last_month_hot_cold)                     AS hot_cold      -- 5.H/C
          ,DECODE(lv_output_period
            ,'0' ,xmvc.inventory_quantity ,'1' ,xmvc.last_month_inventory_quantity) AS inventory_qnt -- 6.基準在庫数
    FROM   xxcoi_mst_vd_column                                                      xmvc        -- 1.VDコラムマスタ
         ,(SELECT msib.segment1          AS item_code   -- 1.品目コード
                 ,ximb.item_short_name   AS short_name  -- 2.品目名(略称)
                 ,msib.inventory_item_id AS item_id     -- 3.品目ID
           FROM   mtl_system_items_b     msib           -- 1.DISC品目マスタ
                 ,ic_item_mst_b          iimb           -- 2.OPM品目マスタ
                 ,xxcmn_item_mst_b       ximb           -- 3.OPOM品目マスタ
                 ,xxcmm_system_items_b   xsib           -- 4.DISC品目アドオン
           WHERE  msib.segment1        = iimb.item_no
-- == 2009/08/13 V1.5 Modified START ===============================================================
--           AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
           AND    msib.organization_id = gn_f_organization_id
-- == 2009/08/13 V1.5 Modified END   ===============================================================
           AND    iimb.item_id         = ximb.item_id
-- == 2009/09/08 V1.6 Added START ===============================================================
           AND    DECODE(lv_output_period
                   ,'0' ,TRUNC(xxccp_common_pkg2.get_process_date)
                   ,'1', TRUNC(ADD_MONTHS(xxccp_common_pkg2.get_process_date, -1))) BETWEEN TRUNC(ximb.start_date_active)
                                                                                    AND     TRUNC(ximb.end_date_active)
-- == 2009/09/08 V1.6 Added END   ===============================================================
           AND    iimb.item_id         = xsib.item_id 
           AND    iimb.attribute26 = '1')                                           sub_query   -- 2.品目情報サブクエリー
    WHERE  xmvc.customer_id  = lv_customer_id
    AND    sub_query.item_id = CASE lv_output_period
                                 WHEN '0' THEN xmvc.item_id
                                 WHEN '1' THEN xmvc.last_month_item_id
                               END
    ORDER BY xmvc.column_no;
--
-- == 2009/06/26 V1.3 Added START ==================================================================
    -- ===============================
    -- ローカル・タイプ・レコード
    -- ===============================
    TYPE get_customer_info_type IS RECORD(
      customer_id                 hz_cust_accounts.cust_account_id%TYPE
     ,base_code                   xxcmm_cust_accounts.sale_base_code%TYPE
     ,base_name                   hz_cust_accounts.account_name%TYPE
     ,customer_code               hz_cust_accounts.account_number%TYPE
     ,customer_name               hz_cust_accounts.account_name%TYPE
     ,model_code                  po_un_numbers_vl.un_number%TYPE
     ,sele_quantity               NUMBER
     ,rack_quantity               xxcoi_mst_vd_column.rack_quantity%TYPE
     ,charge_business_member_code jtf_rs_resource_extns.source_number%TYPE
     ,charge_business_member_name jtf_rs_resource_extns.source_name%TYPE
    );
-- == 2009/06/26 V1.3 Added END   ==================================================================
    -- ===============================
    -- ローカル・レコード
    -- ===============================
-- == 2009/06/26 V1.3 Modified START ==================================================================
--    get_customer_info_rec   get_customer_info_cur%ROWTYPE;   -- 顧客情報抽出レコード
    get_customer_info_rec   get_customer_info_type;   -- 顧客情報抽出レコード
-- == 2009/06/26 V1.3 Modified END   ==================================================================
    get_column_info_rec     get_column_info_cur%ROWTYPE;     -- コラム情報抽出レコード
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
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    -- ローカル変数の初期化
    ln_cust_loop_cnt    := 0;    -- 顧客ループカウンター
    ln_column_cnt       := 0;    -- コラム列数カウンター
    ln_rack_cnt         := 0;    -- ラック数カウンター
    gt_vd_inv_wk_tab.DELETE;
    lv_zero_message     := NULL; -- 0件メッセージ
-- == 2009/06/26 V1.3 Added START ==================================================================
    lv_skip_flg         := cv_staff_prm_no;
-- == 2009/06/26 V1.3 Added END   ==================================================================
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- パラメータ必須チェック(A-1)
    -- ===============================
    chk_param(
      ov_errbuf  => lv_errbuf     --    エラー・メッセージ
     ,ov_retcode => lv_retcode    --    リターン・コード
     ,ov_errmsg  => lv_errmsg);   --    ユーザー・エラー・メッセージ
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 初期処理(A-2)
    -- ===============================
    init(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ
     ,ov_retcode => lv_retcode  -- リターン・コード
     ,ov_errmsg  => lv_errmsg); -- ユーザー・エラー・メッセージ
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 顧客情報取得(A-3)
    -- ===============================
    OPEN get_customer_info_cur(
           gv_output_base
          ,gv_output_period
          ,gv_output_target
-- == 2009/06/26 V1.3 Delete START ==================================================================
--          ,gv_sales_staff_1
--          ,gv_sales_staff_2
--          ,gv_sales_staff_3
--          ,gv_sales_staff_4
--          ,gv_sales_staff_5
--          ,gv_sales_staff_6
-- == 2009/06/26 V1.3 Delete END   ==================================================================
          ,gv_customer_1
          ,gv_customer_2
          ,gv_customer_3
          ,gv_customer_4
          ,gv_customer_5
          ,gv_customer_6
          ,gv_customer_7
          ,gv_customer_8
          ,gv_customer_9
          ,gv_customer_10
          ,gv_customer_11
          ,gv_customer_12);
--
    <<get_customer_info_loop>>
    LOOP
      FETCH get_customer_info_cur INTO get_customer_info_rec;
      EXIT WHEN get_customer_info_cur%NOTFOUND;
-- == 2009/08/13 V1.5 Added START ===============================================================
      --機種コード、セレ数の取得  ※自販機のみ取得する(機器区分 = '1')
      BEGIN
        SELECT  punv.un_number              --  機種コード
               ,TO_NUMBER(punv.attribute8)  --  セレ数
        INTO    get_customer_info_rec.model_code
               ,get_customer_info_rec.sele_quantity
        FROM    csi_item_instances  cii     --  物件マスタ
               ,po_un_numbers_vl    punv    --  機種マスタ
        WHERE  cii.owner_party_account_id  = get_customer_info_rec.customer_id
        AND    cii.instance_status_id     <> 1
-- == 2009/10/21 V1.7 Added START ==================================================================
        AND    cii.instance_type_code     = '1'
-- == 2009/10/21 V1.7 Added END   ==================================================================
        AND    cii.attribute1              = punv.un_number
        AND    punv.attribute8            IS NOT NULL
        AND    punv.attribute8            <> 0
        AND    ROWNUM                      = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --データが存在しない場合はNULLを設定
          get_customer_info_rec.model_code     := NULL;
          get_customer_info_rec.sele_quantity  := NULL;
      END;
-- == 2009/08/13 V1.5 Added END   ===============================================================
-- == 2009/06/26 V1.3 Added START ==================================================================
      -- ラック数の取得
      BEGIN
        SELECT xmvc.rack_quantity AS rack_quantity   -- ラック数
        INTO   get_customer_info_rec.rack_quantity
        FROM   xxcoi_mst_vd_column xmvc              -- VDコラムマスタ
        WHERE  xmvc.customer_id = get_customer_info_rec.customer_id
        AND    xmvc.column_no   = 1;
--
        -- 担当営業員の取得
        BEGIN
          SELECT jrre.source_number       AS charge_business_member_code   --  担当営業員コード
                ,jrre.source_name         AS charge_business_member_name   --  担当営業員名
          INTO   get_customer_info_rec.charge_business_member_code
                ,get_customer_info_rec.charge_business_member_name
          FROM   hz_cust_accounts         hca                              --  顧客アカウント
                ,hz_parties               hp                               --  パーティマスタ
                ,hz_organization_profiles hop                              --  組織プロファイルマスタ
                ,ego_resource_agv         era                              --  リソースビュー
                ,jtf_rs_resource_extns    jrre                             --  リソース
          WHERE  hca.cust_account_id         = get_customer_info_rec.customer_id
          AND    hp.party_id                 = hca.party_id
          AND    hca.party_id                = hop.party_id
          AND    hop.organization_profile_id = era.organization_profile_id
          AND    TRUNC(hop.effective_start_date) <= TRUNC(xxccp_common_pkg2.get_process_date)
          AND    TRUNC(NVL(hop.effective_end_date, xxccp_common_pkg2.get_process_date)) >= TRUNC(xxccp_common_pkg2.get_process_date)
          AND    TRUNC(NVL(era.resource_s_date, xxccp_common_pkg2.get_process_date)) <= TRUNC(xxccp_common_pkg2.get_process_date)
          AND    TRUNC(NVL(era.resource_e_date, xxccp_common_pkg2.get_process_date)) >= TRUNC(xxccp_common_pkg2.get_process_date)
          AND    era.resource_no                      = jrre.source_number
          AND    ((  gv_sales_staff_1 IS NULL
                 AND gv_sales_staff_2 IS NULL
                 AND gv_sales_staff_3 IS NULL
                 AND gv_sales_staff_4 IS NULL
                 AND gv_sales_staff_5 IS NULL
                 AND gv_sales_staff_6 IS NULL)
                 OR
                 (  NVL(gv_sales_staff_1, '#') = jrre.source_number
                 OR NVL(gv_sales_staff_2, '#') = jrre.source_number
                 OR NVL(gv_sales_staff_3, '#') = jrre.source_number
                 OR NVL(gv_sales_staff_4, '#') = jrre.source_number
                 OR NVL(gv_sales_staff_5, '#') = jrre.source_number
                 OR NVL(gv_sales_staff_6, '#') = jrre.source_number));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 入力パラメータ:営業員が指定されている場合
            IF (gv_staff_prm_flg = cv_staff_prm_yes) THEN
              -- この顧客をスキップして次の顧客を取得します
              lv_skip_flg := cv_staff_prm_yes;
            -- 入力パラメータ:営業員が指定されていない場合
            ELSE
              -- この顧客の担当営業員にNULLを設定して後続の処理を実行します
              get_customer_info_rec.charge_business_member_code := NULL;
              get_customer_info_rec.charge_business_member_name := NULL;
              lv_skip_flg := cv_staff_prm_no;
            END IF;
          WHEN TOO_MANY_ROWS THEN
            RAISE global_process_expt;
        END;
--
      EXCEPTION
        -- ラック数取得エラーの場合(VDコラムマスタに存在しない場合)
        WHEN NO_DATA_FOUND THEN
          -- この顧客をスキップして次の顧客を取得します
          lv_skip_flg := cv_staff_prm_yes;
        WHEN TOO_MANY_ROWS THEN
          RAISE global_process_expt;
      END;
--
      -- 顧客スキップフラグが'N'の場合
      IF (lv_skip_flg = cv_staff_prm_no) THEN
-- == 2009/06/26 V1.3 Added END   ==================================================================
--
        -- 顧客ループカウンターのカウントアップ
        ln_cust_loop_cnt := ln_cust_loop_cnt + 1;
        -- 次レコード存在フラグの初期化
        lv_is_next_rec_flg  := 'N';
  --
        -- カラムの初期化
        FOR ln_test_cnt IN 1 .. 345 LOOP
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(ln_test_cnt) := NULL;
        END LOOP;
  --
        -- シーケンス番号取得
        SELECT xxcoi.xxcoi_rep_vd_inventory_s01.NEXTVAL
        INTO   ln_vd_inv_wk_id
        FROM   dual;
  --
        -- ヘッダー情報とWHOカラム情報をテーブル変数に格納
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(1) := ln_vd_inv_wk_id;                         -- ベンダ機内在庫表ワークID
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(2) := get_customer_info_rec.base_code;         -- 拠点コード
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(3) := get_customer_info_rec.base_name;         -- 拠点名
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(4) := get_customer_info_rec.customer_code;     -- 顧客コード
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(5) := get_customer_info_rec.customer_name;     -- 顧客名
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(6) := get_customer_info_rec.model_code;        -- 機種コード
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(7) := get_customer_info_rec.sele_quantity;     -- セレ数
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(8) := get_customer_info_rec.charge_business_member_code; -- 営業担当者コード
        gt_vd_inv_wk_tab(ln_cust_loop_cnt)(9) := get_customer_info_rec.charge_business_member_name; -- 営業担当者名
        -- ===============================
        -- カウンター初期化(A-4)
        -- ===============================
        ln_column_cnt := 1;   -- コラム列数カウンター
        ln_rack_cnt   := 0;   -- ラック数カウンター
        -- ===============================
        -- コラム情報取得(A-5)
        -- ===============================
        OPEN get_column_info_cur(
               gv_output_period
              ,get_customer_info_rec.customer_id);
  --
        <<get_column_info_loop>>
        LOOP
          FETCH get_column_info_cur INTO get_column_info_rec;
          EXIT WHEN get_column_info_cur%NOTFOUND;
  --
          -- 次レコード存在フラグが'Y'の場合
          IF (lv_is_next_rec_flg = 'Y') THEN
            -- 顧客ループカウンターのカウントアップ
            ln_cust_loop_cnt := ln_cust_loop_cnt + 1;
  --
            -- カラムの初期化
            FOR ln_test_cnt IN 1 .. 345 LOOP
              gt_vd_inv_wk_tab(ln_cust_loop_cnt)(ln_test_cnt) := NULL;
            END LOOP;
            -- シーケンス番号取得
            SELECT xxcoi.xxcoi_rep_vd_inventory_s01.NEXTVAL
            INTO   ln_vd_inv_wk_id
            FROM   dual;
  --
            -- ヘッダー情報とWHOカラム情報をテーブル変数に格納
            -- ベンダ機内在庫表ワークID
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(1) := ln_vd_inv_wk_id;
            -- 拠点コード
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(2) := get_customer_info_rec.base_code;
            -- 拠点名
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(3) := get_customer_info_rec.base_name;
            -- 顧客コード
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(4) := get_customer_info_rec.customer_code;
            -- 顧客名
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(5) := get_customer_info_rec.customer_name;
            -- 機種コード
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(6) := get_customer_info_rec.model_code;
            -- セレ数
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(7) := get_customer_info_rec.sele_quantity;
            -- 営業担当者コード
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(8) := get_customer_info_rec.charge_business_member_code;
            -- 営業担当者名
            gt_vd_inv_wk_tab(ln_cust_loop_cnt)(9) := get_customer_info_rec.charge_business_member_name;
            -- ===============================
            -- カウンター初期化(A-4)
            -- ===============================
            ln_column_cnt := 1;   -- コラム列数カウンター
            -- 次レコード存在フラグを初期値に再設定
            lv_is_next_rec_flg := 'N';
          END IF;
  --
          -- ====================================
          -- PL/SQL表ワークテーブル変数設定(A-6)
          -- ====================================
          -- 取得したデータをPL/SQL表ワークテーブル変数にセット
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(9   + ln_column_cnt) := get_column_info_rec.column_no;     -- コラム№
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(65  + ln_column_cnt) := get_column_info_rec.item_code;     -- 品目コード
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(121 + ln_column_cnt) := get_column_info_rec.item_name;     -- 品目名
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(177 + ln_column_cnt) := get_column_info_rec.price;         -- 単価
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(233 + ln_column_cnt) := get_column_info_rec.hot_cold;      -- HOT/COLD
          gt_vd_inv_wk_tab(ln_cust_loop_cnt)(289 + ln_column_cnt) := get_column_info_rec.inventory_qnt; -- 基準在庫
  --
          -- コラム列数カウンターをカウントアップ
          ln_column_cnt := ln_column_cnt + 1;
          -- ラック数カウンターにコラム列数カウンター÷8の余りを設定
          ln_rack_cnt := MOD(ln_column_cnt, 8);
          -- ラック数カウンター＞取得したラック数の場合
          IF (ln_rack_cnt > get_customer_info_rec.rack_quantity) THEN
            -- コラム列数カウンター＜９の場合
            IF (ln_column_cnt < 9) THEN
              ln_column_cnt := 9;
            -- ９＜コラム列数カウンター＜１７の場合
            ELSIF ((9 < ln_column_cnt) AND (ln_column_cnt < 17)) THEN
              ln_column_cnt := 17;
            -- １７＜コラム列数カウンター＜２５の場合
            ELSIF ((17 < ln_column_cnt) AND (ln_column_cnt < 25)) THEN
              ln_column_cnt := 25;
            -- ２５＜コラム列数カウンター＜３３の場合
            ELSIF ((25 < ln_column_cnt) AND (ln_column_cnt < 33)) THEN
              ln_column_cnt := 33;
            -- ３３＜コラム列数カウンター＜４１の場合
            ELSIF ((33 < ln_column_cnt) AND (ln_column_cnt < 41)) THEN
              ln_column_cnt := 41;
            -- ４１＜コラム列数カウンター＜４９の場合
            ELSIF ((41 < ln_column_cnt) AND (ln_column_cnt < 49)) THEN
              ln_column_cnt := 49;
            -- ４９＜コラム列数カウンター＜５７の場合
            ELSIF (49 < ln_column_cnt) THEN
              -- 次レコード存在フラグを設定
              lv_is_next_rec_flg := 'Y';
            END IF;
          END IF;
        END LOOP get_column_info_loop;
        CLOSE get_column_info_cur;
-- == 2009/06/26 V1.3 Added START ==================================================================
      END IF; -- 顧客スキップ終了位置
      lv_skip_flg :=  cv_staff_prm_no;
-- == 2009/06/26 V1.3 Added END   ==================================================================
    END LOOP get_customer_info_loop;
    CLOSE get_customer_info_cur;
--
    -- 対象件数の設定
    gn_target_cnt := ln_cust_loop_cnt;
--
    -- 顧客が1件も存在しない場合
    IF (ln_cust_loop_cnt = 0) THEN
      -- 0件出力メッセージ
      lv_zero_message := xxccp_common_pkg.get_msg(
                            iv_application => cv_msg_kbn_coi
                          , iv_name        => cv_msg_coi_00008);
-- del 2009/03/05 1.1 H.Wada #032 ↓
--      -- シーケンス番号取得
--      SELECT xxcoi.xxcoi_rep_vd_inventory_s01.NEXTVAL
--      INTO   ln_vd_inv_wk_id
--      FROM   dual;
--
--      -- ヘッダー情報とWHOカラム情報をテーブル変数に格納
--      gt_vd_inv_wk_tab(1)(1) := ln_vd_inv_wk_id; -- ベンダ機内在庫表ワークID
--      gt_vd_inv_wk_tab(1)(2) := NULL;            -- 拠点コード
--      gt_vd_inv_wk_tab(1)(3) := NULL;            -- 拠点名
--      gt_vd_inv_wk_tab(1)(4) := NULL;            -- 顧客コード
--      gt_vd_inv_wk_tab(1)(5) := NULL;            -- 顧客名
--      gt_vd_inv_wk_tab(1)(6) := NULL;            -- 機種コード
--      gt_vd_inv_wk_tab(1)(7) := NULL;            -- セレ数
--      gt_vd_inv_wk_tab(1)(8) := NULL;            -- 営業担当者コード
--      gt_vd_inv_wk_tab(1)(9) := NULL;            -- 営業担当者名
--
--      <<null_set_loop>>
--      FOR ln_vd_inv_wk_column_cnt IN 1 .. 336 LOOP
--        gt_vd_inv_wk_tab(1)(9 + ln_vd_inv_wk_column_cnt) := NULL; -- コラム№、品目コード、品目名、単価、H/C、数量
--      END LOOP null_set_loop;
--    END IF;
--
--    <<coi_vd_inv_wk_loop>>
--    FOR ln_vd_inv_wk_cnt IN gt_vd_inv_wk_tab.FIRST .. gt_vd_inv_wk_tab.LAST LOOP
--      -- ====================================
--      -- ワークテーブルデータ登録(A-7)
--      -- ====================================
--      ins_vd_inv_wk(
--        ov_errbuf            => lv_errbuf                             -- エラー・メッセージ
--       ,ov_retcode           => lv_retcode                            -- リターン・コード
--       ,ov_errmsg            => lv_errmsg                             -- ユーザー・エラー・メッセージ
--       ,ir_coi_vd_inv_wk_rec => gt_vd_inv_wk_tab(ln_vd_inv_wk_cnt)); -- VD機内在庫表格納用レコード変数
--      IF (lv_retcode = cv_status_error) THEN
--        RAISE global_process_expt;
--      END IF;
--    END LOOP coi_vd_inv_wk_loop;
--
-- del 2009/03/05 1.1 H.Wada #032 ↑
-- add 2009/03/05 1.1 H.Wada #032 ↓
    -- 顧客が1件以上存在する場合
    ELSE
      <<coi_vd_inv_wk_loop>>
      FOR ln_vd_inv_wk_cnt IN gt_vd_inv_wk_tab.FIRST .. gt_vd_inv_wk_tab.LAST LOOP
        -- ====================================
        -- ワークテーブルデータ登録(A-7)
        -- ====================================
        ins_vd_inv_wk(
          ov_errbuf            => lv_errbuf                             -- エラー・メッセージ
         ,ov_retcode           => lv_retcode                            -- リターン・コード
         ,ov_errmsg            => lv_errmsg                             -- ユーザー・エラー・メッセージ
         ,ir_coi_vd_inv_wk_rec => gt_vd_inv_wk_tab(ln_vd_inv_wk_cnt)); -- VD機内在庫表格納用レコード変数
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP coi_vd_inv_wk_loop;
--
      -- コミット処理
      COMMIT;
--
    END IF;
--
-- add 2009/03/05 1.1 H.Wada #032 ↑
--
    -- ==============================================
    -- SVF起動 (A-8)
    -- ==============================================
    exec_svf_conc(
       ov_errbuf   => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode       -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      ,iv_zero_msg => lv_zero_message  -- 0件メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ワークテーブルデータ削除(A-9)
    -- ==============================================
    del_rep_table_data(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf           OUT VARCHAR2             --   エラー・メッセージ
   ,retcode          OUT VARCHAR2             --   リターン・コード
   ,iv_output_base   IN  VARCHAR2             --  1.出力拠点
   ,iv_output_period IN  VARCHAR2 DEFAULT '0' --  2.出力期間
   ,iv_output_target IN  VARCHAR2             --  3.出力対象
   ,iv_sales_staff_1 IN  VARCHAR2             --  4.営業員1
   ,iv_sales_staff_2 IN  VARCHAR2             --  5.営業員2
   ,iv_sales_staff_3 IN  VARCHAR2             --  6.営業員3
   ,iv_sales_staff_4 IN  VARCHAR2             --  7.営業員4
   ,iv_sales_staff_5 IN  VARCHAR2             --  8.営業員5
   ,iv_sales_staff_6 IN  VARCHAR2             --  9.営業員6
   ,iv_customer_1    IN  VARCHAR2             -- 10.顧客1
   ,iv_customer_2    IN  VARCHAR2             -- 11.顧客2
   ,iv_customer_3    IN  VARCHAR2             -- 12.顧客3
   ,iv_customer_4    IN  VARCHAR2             -- 13.顧客4
   ,iv_customer_5    IN  VARCHAR2             -- 14.顧客5
   ,iv_customer_6    IN  VARCHAR2             -- 15.顧客6
   ,iv_customer_7    IN  VARCHAR2             -- 16.顧客7
   ,iv_customer_8    IN  VARCHAR2             -- 17.顧客8
   ,iv_customer_9    IN  VARCHAR2             -- 18.顧客9
   ,iv_customer_10   IN  VARCHAR2             -- 19.顧客10
   ,iv_customer_11   IN  VARCHAR2             -- 20.顧客11
   ,iv_customer_12   IN  VARCHAR2)            -- 21.顧客12
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END   #############################
--
  BEGIN
--
--###########################  固定部 START #############################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
-- == 2009/05/19 V1.2 Modified START ==================================================================
--       ov_retcode => lv_retcode
--      ,ov_errbuf  => lv_errbuf
--      ,ov_errmsg  => lv_errmsg);
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg);
-- == 2009/05/19 V1.2 Modified END   ==================================================================
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- 入力パラメータをグローバル変数に設定
    gv_output_base   := iv_output_base;
    gv_output_period := iv_output_period;
    gv_output_target := iv_output_target;
    gv_sales_staff_1 := iv_sales_staff_1;
    gv_sales_staff_2 := iv_sales_staff_2;
    gv_sales_staff_3 := iv_sales_staff_3;
    gv_sales_staff_4 := iv_sales_staff_4;
    gv_sales_staff_5 := iv_sales_staff_5;
    gv_sales_staff_6 := iv_sales_staff_6;
    gv_customer_1    := iv_customer_1;
    gv_customer_2    := iv_customer_2;
    gv_customer_3    := iv_customer_3;
    gv_customer_4    := iv_customer_4;
    gv_customer_5    := iv_customer_5;
    gv_customer_6    := iv_customer_6;
    gv_customer_7    := iv_customer_7;
    gv_customer_8    := iv_customer_8;
    gv_customer_9    := iv_customer_9;
    gv_customer_10   := iv_customer_10;
    gv_customer_11   := iv_customer_11;
    gv_customer_12   := iv_customer_12;
--
    -- *** submain呼び出し ***
    submain(
      ov_errbuf  => lv_errbuf    --    エラー・バッファ
     ,ov_retcode => lv_retcode   --    リターン・コード
     ,ov_errmsg  => lv_errmsg);  --    エラー・メッセージ
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    -- 空行出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- エラーの場合、対象件数と正常件数の初期化とエラー件数のセット
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_error_cnt  := 1;
    -- 正常の場合、対象件数と同様の件数を成功件数をセット
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,  buff   => ''
    );
--
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
--    ELSIF( lv_retcode = cv_status_warn ) THEN
--      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCOI004A04R;
/
