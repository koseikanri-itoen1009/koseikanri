CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A06R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A06R(body)
 * Description      : 自販機販売報告書
 * MD.050           : 自販機販売報告書 <MD050_COS_002_A06>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_relation_data      関連データ取得処理(A-2)
 *  get_cust_info_data     顧客情報取得処理(A-3)
 *  get_sales_exp_data     販売情報取得処理(A-4)
 *  ins_rep_work_data      帳票ワークテーブル作成処理(A-5)
 *  execute_svf            SVF起動処理(A-6)
 *  del_rep_work_data      帳票ワークテーブル削除処理(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2012/02/16    1.0   K.Kiriu          新規作成
 * 2012/12/19    1.1   K.Onotsuka       E_本稼働_10275対応[入力パラメータ.顧客コード(仕入先コード)で重複しているデータは、
 *                                                         配列格納処理から除外する]
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
  select_expt          EXCEPTION;         -- データ抽出例外
  insert_expt          EXCEPTION;         -- データ登録例外
  delete_proc_expt     EXCEPTION;         -- データ削除例外
  lock_expt            EXCEPTION;         -- ロック例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCOS002A06R';              -- パッケージ名
--
  cv_application           CONSTANT VARCHAR2(5)   := 'XXCOS';                     -- アプリケーション
--
  --SVF用引数
  cv_frm_name              CONSTANT VARCHAR2(16)  := 'XXCOS002A06S.xml';          -- フォーム様式名
  cv_vrq_name              CONSTANT VARCHAR2(16)  := 'XXCOS002A06S.vrq';          -- クエリー名
  cv_extension_pdf         CONSTANT VARCHAR2(4)   := '.pdf';                      -- 拡張子(PDF)
  cv_output_mode_pdf       CONSTANT VARCHAR2(1)   := '1';                         -- 出力区分
--
  --条件等で使用
  cv_bus_low_type_24       CONSTANT VARCHAR2(2)   := '24';                        -- 業態小分類(フルVD消化)
  cv_bus_low_type_25       CONSTANT VARCHAR2(2)   := '25';                        -- 業態小分類(フルVD)
  cv_1                     CONSTANT VARCHAR2(1)   := '1';                         -- VARCHAR型汎用固定値1
  cv_2                     CONSTANT VARCHAR2(1)   := '2';                         -- VARCHAR型汎用固定値2
  cv_3                     CONSTANT VARCHAR2(1)   := '3';                         -- VARCHAR型汎用固定値3
  cv_30                    CONSTANT VARCHAR2(2)   := '30';                        -- VARCHAR型汎用固定値30
  cv_y                     CONSTANT VARCHAR2(1)   := 'Y';                         -- VARCHAR型汎用固定値Y
  cv_n                     CONSTANT VARCHAR2(1)   := 'N';                         -- VARCHAR型汎用固定値N
--
  --書式
  cv_date_yyyymm           CONSTANT VARCHAR2(8)   := 'RRRR/MM/';                  -- 日付書式'RRRR/MM/'
  cv_date_yyyymmdd         CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                -- 日付書式'RRRR/MM/DD'
  cv_date_yyyymmdd2        CONSTANT VARCHAR2(8)   := 'RRRRMMDD';                  -- 日付書式'RRRRMMDD'
  cv_date_dd               CONSTANT VARCHAR2(2)   := 'DD';                        -- 日付書式'DD'
  cv_slash                 CONSTANT VARCHAR2(1)   := '/';                         -- 日付書式で使用
  cv_date_time             CONSTANT VARCHAR2(21)  := 'RRRR/MM/DD HH24:MI:SS';     -- 日付書式'日時'(ログ用)
--
  --メッセージコード
  cv_msg_param_cust_1      CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14351';          -- メッセージ出力(顧客)--10param迄
  cv_msg_param_cust_2      CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14352';          -- メッセージ出力(顧客)--11param以降
  cv_msg_param_vend        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14353';          -- メッセージ出力(仕入先)
  cv_msg_prf_err           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00004';          -- プロファイル取得エラー
  cv_msg_organization_err  CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00091';          -- 在庫組織ID取得エラー
  cv_msg_select_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00013';          -- データ抽出エラー
  cv_msg_insert_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00010';          -- データ登録エラー
  cv_msg_lock_err          CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00001';          -- データロックエラー
  cv_msg_delete_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00012';          -- データ削除エラー
  cv_msg_nodata_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00018';          -- 明細0件エラーメッセージ
  cv_msg_api_err           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00017';          -- APIエラーメッセージ
  cv_msg_price_wrn         CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14359';          -- 売価小数点メッセージ
  --メッセージトークン用
  cv_msg_tkn_org           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00047';          -- MO:営業単位
  cv_msg_tkn_organization  CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00048';          -- XXCOI:在庫組織コード
  cv_msg_tkn_app_mst       CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14354';          -- アプリケーションマスタ
  cv_msg_tkn_ct_set_mst    CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14355';          -- カテゴリセットマスタ(政策群)
  cv_msg_tkn_policy_group  CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14356';          -- XXCOS:政策群
  cv_msg_tkn_tmp_table     CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14357';          -- 自販機販売報告書顧客情報一時表
  cv_msg_tkn_rep_table     CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14358';          -- 自販機販売報告書帳票ワークテーブル
  cv_msg_tkn_emp_table     CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14360';          -- 担当営業
  cv_msg_tkn_svf_api       CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00041';          -- SVF起動API
--
  --トークンコード
  cv_tkn_manager_flag      CONSTANT VARCHAR2(12)  := 'MANAGER_FLAG';              -- 管理者フラグ
  cv_tkn_proc_type         CONSTANT VARCHAR2(12)  := 'EXECUTE_TYPE';              -- 実行区分
  cv_tkn_trget_date        CONSTANT VARCHAR2(11)  := 'TARGET_DATE';               -- 年月
  cv_tkn_sales_base        CONSTANT VARCHAR2(15)  := 'SALES_BASE_CODE';           -- 売上拠点コード
  cv_tkn_cust_01           CONSTANT VARCHAR2(12)  := 'CUST_CODE_01';              -- 顧客コード1
  cv_tkn_cust_02           CONSTANT VARCHAR2(12)  := 'CUST_CODE_02';              -- 顧客コード2
  cv_tkn_cust_03           CONSTANT VARCHAR2(12)  := 'CUST_CODE_03';              -- 顧客コード3
  cv_tkn_cust_04           CONSTANT VARCHAR2(12)  := 'CUST_CODE_04';              -- 顧客コード4
  cv_tkn_cust_05           CONSTANT VARCHAR2(12)  := 'CUST_CODE_05';              -- 顧客コード5
  cv_tkn_cust_06           CONSTANT VARCHAR2(12)  := 'CUST_CODE_06';              -- 顧客コード6
  cv_tkn_cust_07           CONSTANT VARCHAR2(12)  := 'CUST_CODE_07';              -- 顧客コード7
  cv_tkn_cust_08           CONSTANT VARCHAR2(12)  := 'CUST_CODE_08';              -- 顧客コード8
  cv_tkn_cust_09           CONSTANT VARCHAR2(12)  := 'CUST_CODE_09';              -- 顧客コード9
  cv_tkn_cust_10           CONSTANT VARCHAR2(12)  := 'CUST_CODE_10';              -- 顧客コード10
  cv_tkn_vend_01           CONSTANT VARCHAR2(12)  := 'VEND_CODE_01';              -- 仕入先コード1
  cv_tkn_vend_02           CONSTANT VARCHAR2(12)  := 'VEND_CODE_02';              -- 仕入先コード2
  cv_tkn_vend_03           CONSTANT VARCHAR2(12)  := 'VEND_CODE_03';              -- 仕入先コード3
  cv_tkn_prf               CONSTANT VARCHAR2(7)   := 'PROFILE';                   -- プロファイル
  cv_tkn_organization      CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';              -- 在庫組織コード
  cv_tkn_table_name        CONSTANT VARCHAR2(10)  := 'TABLE_NAME';                -- テーブル名
  cv_tkn_key_data          CONSTANT VARCHAR2(8)   := 'KEY_DATA';                  -- エラー内容
  cv_tkn_api_name          CONSTANT VARCHAR2(8)   := 'API_NAME';                  -- API名称
  cv_tkn_table             CONSTANT VARCHAR2(5)   := 'TABLE';                     -- テーブル
  cv_tkn_cust              CONSTANT VARCHAR2(9)   := 'CUST_CODE';                 -- 顧客コード
  cv_tkn_item              CONSTANT VARCHAR2(9)   := 'ITEM_CODE';                 -- 品目コード
  cv_tkn_dlv_price         CONSTANT VARCHAR2(9)   := 'DLV_PRICE';                 -- 売価
--
  --プロファイル
  cv_prf_org               CONSTANT VARCHAR2(6)   := 'ORG_ID';                    -- MO:営業単位
  cv_prf_organization      CONSTANT VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_prf_policy_group      CONSTANT VARCHAR2(24)  := 'XXCOS1_POLICY_GROUP_CODE';  -- XXCOS:政策群コード
  --ログ用
  cv_proc_end              CONSTANT VARCHAR2(3)   := 'END';
--
  --LANGUAGE
  ct_lang                  CONSTANT mtl_category_sets_tl.language%TYPE := USERENV( 'LANG' );
  --業務日付
  gd_proc_date             CONSTANT DATE := TRUNC( xxccp_common_pkg2.get_process_date );
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ情報(共通)
  TYPE g_input_rtype IS RECORD (
     manager_flag      VARCHAR2(1)                             -- 管理者フラグ
    ,execute_type      VARCHAR2(1)                             -- 実行区分
    ,target_date       VARCHAR2(7)                             -- 対象年月
    ,sales_base_code   xxcmm_cust_accounts.sale_base_code%TYPE -- 売上拠点コード
  );
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  g_input_rec  g_input_rtype;  --入力パラメータ情報
--
  -- ===============================
  -- ユーザー定義グローバルテーブル
  -- ===============================
  TYPE g_cust_ttype  IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER; -- 顧客指定で実行時用
  TYPE g_vend_ttype  IS TABLE OF po_vendors.segment1%TYPE             INDEX BY BINARY_INTEGER; -- 仕入先指定で実行時用
  TYPE g_sales_ttype IS TABLE OF xxcos_rep_vd_sales_list%ROWTYPE      INDEX BY BINARY_INTEGER; -- 帳票ワークテーブル
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
  TYPE g_chk_ttype   IS TABLE OF NUMBER INDEX BY VARCHAR2(30); --パラメータチェック用
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
  -- ===============================
  -- ユーザー定義グローバル配列
  -- ===============================
  g_cust_tab       g_cust_ttype;
  g_vend_tab       g_vend_ttype;
  g_sales_tab      g_sales_ttype;
  g_sales_tab_work g_sales_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id            NUMBER;                                    --営業単位ID
  gn_organization_id   NUMBER;                                    --在庫組織ID
  gt_apprication_id    fnd_application.application_id%TYPE;       --アプリケーションID
  gt_category_set_id   mtl_category_sets_tl.category_set_id%TYPE; --カテゴリセットID
  gn_warn              NUMBER;                                    --処理警告終了用
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --クイックコード
    cv_lk_proc_type    CONSTANT VARCHAR2(29)  := 'XXCOS1_REP_VD_SALES_EXEC_TYPE';  -- 実行区分
--
    -- *** ローカル変数 ***
    lv_param_msg       VARCHAR2(5000);                 -- パラメーター出力用
    lv_proc_type_name  fnd_lookup_values.meaning%TYPE; -- クイックコード内容
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
    --=========================================
    -- パラメータの出力
    --=========================================
    --実行区分の名称取得
    lv_proc_type_name := xxcos_common_pkg.get_specific_master(
                           cv_lk_proc_type
                          ,g_input_rec.execute_type
                         );
--
    --実行区分が1（顧客指定で実行時）の場合
    IF ( g_input_rec.execute_type = cv_1 ) THEN
      --メッセージ編集(10parameter迄)
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application               -- アプリケーション
                        ,iv_name          => cv_msg_param_cust_1          -- メッセージコード
                        ,iv_token_name1   => cv_tkn_manager_flag          -- トークンコード１
                        ,iv_token_value1  => g_input_rec.manager_flag     -- 管理者フラグ
                        ,iv_token_name2   => cv_tkn_proc_type             -- トークンコード２
                        ,iv_token_value2  => lv_proc_type_name            -- 実行区分
                        ,iv_token_name3   => cv_tkn_trget_date            -- トークンコード３
                        ,iv_token_value3  => g_input_rec.target_date      -- 年月
                        ,iv_token_name4   => cv_tkn_sales_base            -- トークンコード４
                        ,iv_token_value4  => g_input_rec.sales_base_code  -- 売上拠点
                        ,iv_token_name5   => cv_tkn_cust_01               -- トークンコード５
                        ,iv_token_value5  => g_cust_tab(1)                -- 顧客コード1
                        ,iv_token_name6   => cv_tkn_cust_02               -- トークンコード６
                        ,iv_token_value6  => g_cust_tab(2)                -- 顧客コード2
                        ,iv_token_name7   => cv_tkn_cust_03               -- トークンコード７
                        ,iv_token_value7  => g_cust_tab(3)                -- 顧客コード3
                        ,iv_token_name8   => cv_tkn_cust_04               -- トークンコード８
                        ,iv_token_value8  => g_cust_tab(4)                -- 顧客コード4
                        ,iv_token_name9   => cv_tkn_cust_05               -- トークンコード９
                        ,iv_token_value9  => g_cust_tab(5)                -- 顧客コード5
                        ,iv_token_name10  => cv_tkn_cust_06               -- トークンコード１０
                        ,iv_token_value10 => g_cust_tab(6)                -- 顧客コード6
                      );
      --1～10のパラメータをログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
      --メッセージ編集(10parameter以降)
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application                -- アプリケーション
                        ,iv_name          => cv_msg_param_cust_2           -- メッセージコード
                        ,iv_token_name1   => cv_tkn_cust_07                -- トークンコード１
                        ,iv_token_value1  => g_cust_tab(7)                 -- 顧客コード7
                        ,iv_token_name2   => cv_tkn_cust_08                -- トークンコード２
                        ,iv_token_value2  => g_cust_tab(8)                 -- 顧客コード8
                        ,iv_token_name3   => cv_tkn_cust_09                -- トークンコード３
                        ,iv_token_value3  => g_cust_tab(9)                 -- 顧客コード9
                        ,iv_token_name4   => cv_tkn_cust_10                -- トークンコード３
                        ,iv_token_value4  => g_cust_tab(10)                -- 顧客コード10
                      );
      --11～13のパラメータをログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
    --実行区分が2（仕入先指定で実行時）の場合
    ELSIF ( g_input_rec.execute_type = cv_2 ) THEN
      --メッセージ編集
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application                -- アプリケーション
                        ,iv_name          => cv_msg_param_vend             -- メッセージコード
                        ,iv_token_name1   => cv_tkn_manager_flag           -- トークンコード１
                        ,iv_token_value1  => g_input_rec.manager_flag      -- 管理者フラグ
                        ,iv_token_name2   => cv_tkn_proc_type              -- トークンコード２
                        ,iv_token_value2  => lv_proc_type_name             -- 実行区分
                        ,iv_token_name3   => cv_tkn_trget_date             -- トークンコード３
                        ,iv_token_value3  => g_input_rec.target_date       -- 年月
                        ,iv_token_name4   => cv_tkn_vend_01                -- トークンコード４
                        ,iv_token_value4  => g_vend_tab(1)                 -- 仕入先コード1
                        ,iv_token_name5   => cv_tkn_vend_02                -- トークンコード５
                        ,iv_token_value5  => g_vend_tab(2)                 -- 仕入先コード2
                        ,iv_token_name6   => cv_tkn_vend_03                -- トークンコード６
                        ,iv_token_value6  => g_vend_tab(3)                 -- 仕入先コード3
                      );
      --ログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
    END IF;
--
    --ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
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
   * Procedure Name   : get_relation_data
   * Description      : 関連データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_relation_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relation_data'; -- プログラム名
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
    cv_application_ar     CONSTANT fnd_application.application_short_name%TYPE := 'AR';              -- アプリケーション名
--
    -- *** ローカル変数 ***
    lv_msg_tnk            VARCHAR2(100);                                        -- メッセージトークン用
    lv_err_msg            VARCHAR2(5000);                                       -- メッセージ用
    lt_organization_code  mtl_parameters.organization_code%TYPE;                -- 在庫組織コード
    lt_policy_group_code  fnd_profile_option_values.profile_option_value%TYPE;  -- アプリケーション名(政策群)
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
    --=========================================
    -- プロファイルの取得
    --=========================================
    ------------------------
    -- 営業単位の取得
    ------------------------
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org ) );  -- 営業単位
    IF ( gn_org_id IS NULL ) THEN
      -- トークン取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_org        -- MO:営業単位
                    );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prf_err  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_prf
                      ,iv_token_value1 => lv_msg_tnk      -- プロファイル名
                    );
      --ログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --リターンコードにエラーを設定
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------
    --在庫組織コードの取得
    ------------------------
    lt_organization_code := FND_PROFILE.VALUE( cv_prf_organization );
    IF ( lt_organization_code IS NULL ) THEN
      -- プロファイル名取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_organization  -- XXCOI:在庫組織コード
                    );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prf_err           -- メッセージコード
                      ,iv_token_name1  => cv_tkn_prf
                      ,iv_token_value1 => lv_msg_tnk               -- プロファイル名
                    );
      --ログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --リターンコードにエラーを設定
      ov_retcode := cv_status_error;
    END IF;
--
    --------------------------------
    --カテゴリセット名(政策群)の取得
    --------------------------------
    lt_policy_group_code := FND_PROFILE.VALUE( cv_prf_policy_group );
    IF ( lt_policy_group_code IS NULL ) THEN
      -- プロファイル名取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_policy_group  -- XXCOS:政策群
                    );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prf_err           -- メッセージコード
                      ,iv_token_name1  => cv_tkn_prf
                      ,iv_token_value1 => lv_msg_tnk               -- プロファイル名
                    );
      --ログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --リターンコードにエラーを設定
      ov_retcode := cv_status_error;
    END IF;
--
    --=========================================
    -- 在庫組織IDの取得
    --=========================================
    gn_organization_id :=xxcoi_common_pkg.get_organization_id( lt_organization_code );
    IF ( gn_organization_id IS NULL ) THEN
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_organization_err  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_organization
                      ,iv_token_value1 => lt_organization_code     -- 在庫組織コード
                    );
      --ログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --リターンコードにエラーを設定
      ov_retcode := cv_status_error;
    END IF;
--
    --=========================================
    -- アプリケーションIDの取得
    --=========================================
    BEGIN
      SELECT fa.application_id application_id
      INTO   gt_apprication_id
      FROM   fnd_application fa
      WHERE  fa.application_short_name = cv_application_ar
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- テーブル名取得
        lv_msg_tnk := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_tkn_app_mst   -- アプリケーションマスタ
                      );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_select_err    --メッセージコード
                        ,iv_token_name1  => cv_tkn_table_name
                        ,iv_token_value1 => lv_msg_tnk           -- テーブル名
                        ,iv_token_name2  => cv_tkn_key_data
                        ,iv_token_value2 => SQLERRM              -- SQLERRM
                      );
        --ログへ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_err_msg
        );
        --リターンコードにエラーを設定
        ov_retcode := cv_status_error;
    END;
--
    --=========================================
    -- カテゴリセットIDの取得
    --=========================================
    BEGIN
      SELECT  mcst.category_set_id category_set_id
      INTO    gt_category_set_id
      FROM    mtl_category_sets_tl   mcst
      WHERE   mcst.category_set_name = lt_policy_group_code
      AND     mcst.language          = ct_lang
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- テーブル名取得
        lv_msg_tnk := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_tkn_ct_set_mst  -- アプリケーションマスタ
                      );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_select_err      --メッセージコード
                        ,iv_token_name1  => cv_tkn_table_name
                        ,iv_token_value1 => lv_msg_tnk             -- テーブル名
                        ,iv_token_name2  => cv_tkn_key_data
                        ,iv_token_value2 => SQLERRM                -- SQLERRM
                      );
        --ログへ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_err_msg
        );
        --リターンコードにエラーを設定
        ov_retcode := cv_status_error;
    END;
--
    --エラーの場合、ログ出力用にERRBUFを設定
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_relation_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_info_data
   * Description      : 顧客情報取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_info_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_info_data'; -- プログラム名
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
    -- *** ローカル配列 ***
    l_cust_tab  g_cust_ttype;        -- 顧客指定用
    l_vend_tab  g_vend_ttype;        -- 仕入先指定用
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
    l_chk_tab   g_chk_ttype;         -- パラメータチェック用
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
--
    -- *** ローカル変数 ***
    ln_cnt        BINARY_INTEGER := 0; -- 配列添え字
    lv_sqlerrm    VARCHAR2(5000);      -- SQLERRM格納用
    lv_msg_tnk    VARCHAR2(100);       -- メッセージトークン用
    ld_first_date DATE;                -- パラメータ指定日の1日
    ld_last_date  DATE;                -- パラメター指定日の末日
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    -- 1日と末日の取得
    ld_first_date := TO_DATE( g_input_rec.target_date, cv_date_yyyymm );
    ld_last_date  := LAST_DAY( TO_DATE( g_input_rec.target_date, cv_date_yyyymm ) );
--
    -- =======================================
    -- 実行区分が1（顧客指定で実行）の場合
    -- =======================================
    IF ( g_input_rec.execute_type = cv_1 ) THEN
--
      -----------------------------------------
      -- 指定がある顧客コードのみ格納(配列：疎⇒密)
      -----------------------------------------
      << cust_loop >>
      FOR i IN 1.. g_cust_tab.COUNT LOOP
        IF ( g_cust_tab(i) IS NOT NULL ) THEN
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
          --パラメータに同一顧客が2つ以上設定されていないかチェック
          IF ( l_chk_tab.EXISTS( g_cust_tab(i) ) ) THEN
            --同一顧客が既に存在する場合、設定しない
            NULL;
          ELSE
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
            ln_cnt             := ln_cnt + 1;
            l_cust_tab(ln_cnt) := g_cust_tab(i);
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
            l_chk_tab( g_cust_tab(i) ) := 1; --チェック用配列にダミー値設定
          END IF;
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
        END IF;
      END LOOP cust_loop;
      -- グローバル配列削除
      g_cust_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
      -- チェック用の配列削除
      l_chk_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
--
      BEGIN
        -----------------------------------------
        -- 自販機販売報告書顧客情報一時表作成
        -----------------------------------------
        FORALL i IN 1.. l_cust_tab.COUNT
          INSERT INTO xxcos_tmp_vd_cust_info (
             customer_code        -- 顧客コード
            ,customer_name        -- 顧客名称
            ,party_id             -- パーティID
            ,sales_base_name      -- 売上拠点名称
            ,sales_base_city      -- 都道府県市区（売上拠点
            ,sales_base_address1  -- 住所１（売上拠点）
            ,sales_base_address2  -- 住所２（売上拠点）
            ,sales_base_tel       -- 電話番号（売上拠点）
            ,vendor_code          -- 仕入先コード
            ,vendor_name          -- 仕入先名称（送付先）
            ,vendor_zip           -- 郵便番号（送付先）
            ,vendor_address1      -- 住所１（送付先）
            ,vendor_address2      -- 住所２（送付先）
            ,date_from            -- 対象期間開始日
            ,date_to              -- 対象期間終了日
          )
          SELECT /*+
                   USE_NL(hca xca hp)
                   USE_NL(xac hcab hpb)
                 */
                 hca.account_number         customer_code       -- 顧客コード
                ,hp.party_name              customer_name       -- 顧客名称
                ,hp.party_id                party_id            -- パーティID
                ,hpb.party_name             sales_base_name     -- 売上拠点名称
                ,hlb.state || hlb.city      sales_base_city     -- 都道府県市区(売上拠点)
                ,hlb.address1               sales_base_address1 -- 住所１(売上拠点)
                ,hlb.address2               sales_base_address2 -- 住所２(売上拠点)
                ,hlb.address_lines_phonetic sales_base_tel      -- 電話番号(売上拠点)
                ,pv.segment1                vendor_code         -- 仕入先コード
                ,CASE
                  -- 仕入先がある場合
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.attribute1
                  -- 仕入先がなく、業態小分類が25の場合
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    SUBSTRB( hp.party_name, 1, 240 )
                  ELSE
                    NULL
                 END                        vendor_name         -- 仕入先名称
                ,CASE
                  -- 仕入先がある場合
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.zip
                  -- 仕入先がなく、業態小分類が25の場合
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    hl.postal_code
                  ELSE
                    NULL
                 END                        zip                 -- 郵便番号
                ,CASE
                  -- 仕入先がある場合
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.address_line1
                  -- 仕入先がなく、業態小分類が25の場合
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    SUBSTRB( hl.state || hl.city || hl.address1 , 1, 240 )
                  ELSE
                    NULL
                 END                        address_line1       -- 住所１
                ,CASE
                  -- 仕入先がある場合
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.address_line2
                  -- 仕入先がなく、業態小分類が25の場合
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    hl.address2
                  ELSE
                    NULL
                 END                        address_line2       -- 住所２
                ,CASE
                   -- 末締の場合(NULL=販売手数料なしの場合も)
                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                     -- 指定月の1日
                     ld_first_date
                   -- 2月の28日,29日締考慮
                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
                     TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
                              || xcm.close_day_code, cv_date_yyyymmdd) + 1
                   -- 末締以外
                   ELSE
                     -- 前月締日+1日
                     ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
                 END                        date_from           -- 対象期間開始日
                ,CASE
                   -- 末締の場合(NULL=販売手数料なしの場合も)
                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                     -- 指定月の最終日
                     ld_last_date
                   --2月の28日,29日締考慮
                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
                     -- 指定月の最終日(2月28 or 29)
                     ld_last_date
                   -- 末締以外
                   ELSE
                     --指定月の締日
                     TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
                 END                        date_to             -- 対象期間終了日
          FROM   hz_cust_accounts           hca       -- 顧客マスタ(顧客)
                ,xxcmm_cust_accounts        xca       -- 顧客追加情報(顧客)
                ,hz_parties                 hp        -- パーティマスタ(顧客)
                ,hz_cust_acct_sites_all     hcasa     -- 顧客所在地マスタ(顧客)
                ,hz_party_sites             hps       -- パーティサイトマスタ(顧客)
                ,hz_locations               hl        -- 顧客事業所マスタ(顧客)
                ,xxcso_contract_managements xcm       -- 契約管理
                ,hz_cust_accounts           hcab      -- 顧客マスタ(売上拠点)
                ,hz_parties                 hpb       -- パーティマスタ(売上拠点)
                ,hz_cust_acct_sites_all     hcasab    -- 顧客所在地マスタ(売上拠点)
                ,hz_party_sites             hpsb      -- パーティサイトマスタ(売上拠点)
                ,hz_locations               hlb       -- 顧客事業所マスタ(売上拠点)
                ,po_vendors                 pv        -- 仕入先マスタ(送付先)
                ,po_vendor_sites_all        pvs       -- 仕入先サイト(送付先)
          WHERE  hca.account_number            = l_cust_tab(i)      --指定された顧客
          AND    hca.cust_account_id           = xca.customer_id
          AND    hca.party_id                  = hp.party_id
          AND    hca.cust_account_id           = hcasa.cust_account_id
          AND    hcasa.party_site_id           = hps.party_site_id
          AND    hcasa.org_id                  = gn_org_id
          AND    hps.location_id               = hl.location_id
          AND    hca.cust_account_id           = xcm.install_account_id
          AND    xcm.contract_management_id    = (
                   SELECT /*+
                            INDEX( xcms xxcso_contract_managements_n06 )
                          */
                          MAX(xcms.contract_management_id) contract_management_id
                   FROM   xxcso_contract_managements xcms
                   WHERE  xcms.install_account_id     = hca.cust_account_id
                   AND    xcms.status                 = cv_1
                   AND    xcms.cooperate_flag         = cv_1
                 )                                   --確定済・マスタ連携済の最新契約
          AND    xca.sale_base_code            = hcab.account_number
          AND    hcab.party_id                 = hpb.party_id
          AND    hcab.cust_account_id          = hcasab.cust_account_id
          AND    hcasab.party_site_id          = hpsb.party_site_id
          AND    hcasab.org_id                 = gn_org_id
          AND    hpsb.location_id              = hlb.location_id
          AND    xca.contractor_supplier_code  = pv.segment1(+)
          AND    pv.vendor_id                  = pvs.vendor_id(+)
          AND    pv.segment1                   = pvs.vendor_site_code(+)
          AND    pvs.org_id(+)                 = gn_org_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 );  --SQLERRM格納
          RAISE insert_expt;
      END;
--
      --配列を削除
      l_cust_tab.DELETE;
--
    -- =======================================
    -- 実行区分が2（仕入先指定で実行）の場合
    -- =======================================
    ELSIF ( g_input_rec.execute_type = cv_2 ) THEN
--
      -------------------------------------------
      -- 指定がある仕入先コードのみ格納(配列：疎⇒密)
      -------------------------------------------
      << vend_loop >>
      FOR i IN 1.. g_vend_tab.COUNT LOOP
        IF ( g_vend_tab(i) IS NOT NULL ) THEN
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
          --パラメータに同一仕入先が2つ以上設定されていないかチェック
          IF ( l_chk_tab.EXISTS( g_vend_tab(i) ) ) THEN
            --同一仕入先が既に存在する場合、設定しない
            NULL;
          ELSE
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
            ln_cnt             := ln_cnt + 1;
            l_vend_tab(ln_cnt) := g_vend_tab(i);
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
            l_chk_tab( g_vend_tab(i) ) := 1; --チェック用配列にダミー値設定
          END IF;
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
        END IF;
      END LOOP vend_loop;
      -- グローバル配列削除
      g_vend_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD START
      -- チェック用の配列削除
      l_chk_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_本稼動_10275 ADD END
--
      BEGIN
        -----------------------------------------
        -- 自販機販売報告書顧客情報一時表作成
        -----------------------------------------
        FORALL i IN 1.. l_vend_tab.COUNT
          INSERT INTO xxcos_tmp_vd_cust_info (
             customer_code        -- 顧客コード
            ,customer_name        -- 顧客名称
            ,party_id             -- パーティID
            ,sales_base_name      -- 売上拠点名称
            ,sales_base_city      -- 都道府県市区（売上拠点
            ,sales_base_address1  -- 住所１（売上拠点）
            ,sales_base_address2  -- 住所２（売上拠点）
            ,sales_base_tel       -- 電話番号（売上拠点）
            ,vendor_code          -- 仕入先コード
            ,vendor_name          -- 仕入先名称（送付先）
            ,vendor_zip           -- 郵便番号（送付先）
            ,vendor_address1      -- 住所１（送付先）
            ,vendor_address2      -- 住所２（送付先）
            ,date_from            -- 対象期間開始日
            ,date_to              -- 対象期間終了日
          )
          SELECT /*+
                   USE_NL(hca xca hp)
                   USE_NL(xac hcab hpb)
                 */
                 hca.account_number         customer_code       -- 顧客コード
                ,hp.party_name              customer_name       -- 顧客名称
                ,hp.party_id                party_id            -- パーティID
                ,hpb.party_name             sales_base_name     -- 売上拠点名称
                ,hlb.state || hlb.city      sales_base_city     -- 都道府県市区(売上拠点)
                ,hlb.address1               sales_base_address1 -- 住所１(売上拠点)
                ,hlb.address2               sales_base_address2 -- 住所２(売上拠点)
                ,hlb.address_lines_phonetic sales_base_tel      -- 電話番号(売上拠点)
                ,pv.segment1                vendor_code         -- 仕入先コード
                ,pvs.attribute1             vendor_name         -- 仕入先名称
                ,pvs.zip                    vendor_zip          -- 郵便番号
                ,pvs.address_line1          address_line1       -- 住所１
                ,pvs.address_line2          address_line2       -- 住所２
                ,CASE
                   -- 末締の場合
                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                     -- 指定月の1日
                     ld_first_date
                   -- 2月の28日,29日締考慮
                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
                     TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
                              || xcm.close_day_code, cv_date_yyyymmdd) + 1
                   -- 末締以外
                   ELSE
                     -- 前月締日+1日
                     ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
                 END                        date_from           -- 対象期間開始日
                ,CASE
                   -- 末締の場合
                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                     -- 指定月の最終日
                     ld_last_date
                   --2月の28日,29日締考慮
                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
                     -- 指定月の最終日(2月28 or 29)
                     ld_last_date
                   -- 末締以外
                   ELSE
                     --指定月の締日
                     TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
                 END                        date_to             -- 対象期間終了日
          FROM   hz_cust_accounts           hca       -- 顧客マスタ(顧客)
                ,xxcmm_cust_accounts        xca       -- 顧客追加情報(顧客)
                ,hz_parties                 hp        -- パーティマスタ(顧客)
                ,xxcso_contract_managements xcm       -- 契約管理
                ,hz_cust_accounts           hcab      -- 顧客マスタ(売上拠点)
                ,hz_parties                 hpb       -- パーティマスタ(売上拠点)
                ,hz_cust_acct_sites_all     hcasab    -- 顧客所在地マスタ(売上拠点)
                ,hz_party_sites             hpsb      -- パーティサイトマスタ(売上拠点)
                ,hz_locations               hlb       -- 顧客事業所マスタ(売上拠点)
                ,po_vendors                 pv        -- 仕入先マスタ(送付先)
                ,po_vendor_sites_all        pvs       -- 仕入先サイト(送付先)
          WHERE  pv.segment1                   = l_vend_tab(i)      --指定された仕入先
          AND    hca.account_number            = xca.customer_code
          AND    hca.party_id                  = hp.party_id
          AND    hca.cust_account_id           = xcm.install_account_id
          AND    xcm.contract_management_id    = (
                   SELECT /*+
                            INDEX( xcms xxcso_contract_managements_n06 )
                          */
                          MAX(xcms.contract_management_id) contract_management_id
                   FROM   xxcso_contract_managements xcms
                   WHERE  xcms.install_account_id     = hca.cust_account_id
                   AND    xcms.status                 = cv_1
                   AND    xcms.cooperate_flag         = cv_1
                 )                                   --確定済・マスタ連携済の最新契約
          AND    xca.sale_base_code            = hcab.account_number
          AND    hcab.party_id                 = hpb.party_id
          AND    hcab.cust_account_id          = hcasab.cust_account_id
          AND    hcasab.party_site_id          = hpsb.party_site_id
          AND    hcasab.org_id                 = gn_org_id
          AND    hpsb.location_id              = hlb.location_id
          AND    xca.contractor_supplier_code  = pv.segment1
          AND    pv.vendor_id                  = pvs.vendor_id
          AND    pv.segment1                   = pvs.vendor_site_code
          AND    pvs.org_id                    = gn_org_id
          AND    (
                   (
                        ( g_input_rec.manager_flag = cv_n )
                    AND ( pvs.attribute5     NOT IN ( SELECT xlbiv1.base_code base_code
                                                      FROM   xxcos_login_base_info_v xlbiv1
                                                    )
                        )
                    AND (
                          xca.sale_base_code  IN    ( SELECT xlbiv2.base_code base_code
                                                      FROM   xxcos_login_base_info_v xlbiv2
                                                    )
                        )
                   )                                                -- 問合せ担当拠点で無い場合、自拠点分のみ
                   OR
                   (
                        ( g_input_rec.manager_flag = cv_n )
                    AND 
                        (
                          pvs.attribute5      IN    ( SELECT xlbiv3.base_code base_code
                                                      FROM   xxcos_login_base_info_v xlbiv3
                                                    )
                        )
                   )                                                -- 問合せ担当拠点の場合、配下の全て
                   OR
                   (
                      g_input_rec.manager_flag = cv_y
                   )                                                -- 管理者の場合全て
                 )
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 ); --SQLERRM格納
          RAISE insert_expt;
      END;
--
      --配列を削除
      l_vend_tab.DELETE;
--
    END IF;
--
    --処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_date_time )
    );
    --ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** データ登録例外 ***
    WHEN insert_expt THEN
      -- テーブル名取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_tmp_table   -- 自販機販売報告書顧客情報一時表
                    );
      -- メッセージ取得
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_insert_err      -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lv_msg_tnk             -- テーブル名
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_cust_info_data;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_data
   * Description      : 販売情報取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_data'; -- プログラム名
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
    cv_prof_group   CONSTANT VARCHAR2(21) := 'HZ_ORG_PROFILES_GROUP';   -- プロファイルグループ
    cv_resource     CONSTANT VARCHAR2(8)  := 'RESOURCE';                -- リソース
    cv_no_item      CONSTANT VARCHAR2(23) := 'XXCOS1_NO_INV_ITEM_CODE'; -- クイックコード(非在庫品)
--
    -- *** ローカル変数 ***
    lv_sqlerrm        VARCHAR2(5000);                                  -- SQLERRM格納用
    lv_msg_tnk        VARCHAR2(100);                                   -- メッセージトークン用
    lv_wrnmsg         VARCHAR2(5000);                                  -- チェックメッセージ用
    lv_salesrep_name  VARCHAR2(300);                                   -- 顧客担当者名称
    lv_output_flag    VARCHAR2(1);                                     -- 出力対象フラグ
    lt_cust_code      hz_cust_accounts.account_number%TYPE;            -- 顧客ブレーク用
    lt_party_id       hz_parties.party_id%TYPE;                        -- 顧客ブレーク時の担当営業取得用
    ln_work_ind       BINARY_INTEGER;                                  -- 一時格納データ用の索引
    ln_create_ind     BINARY_INTEGER;                                  -- 作成データ用の索引
    lt_dlv_date       xxcos_sales_exp_headers.delivery_date%TYPE;      -- 顧客別期間最大納品日取得用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 販売実績取得カーソル
    CURSOR get_vd_sales_cur
    IS
      SELECT /*+
               LEADING(xtvci)
               USE_NL(xseh)
               USE_NL(iimb)
               USE_NL(ximb)
               INDEX( xseh xxcos_sales_exp_headers_n08 )
               INDEX( mcb mtl_categories_b_u1)
             */
             xtvci.vendor_zip                     vendor_zip              -- 郵便番号（送付先）
            ,xtvci.vendor_address1                vendor_address1         -- 住所１（送付先）
            ,xtvci.vendor_address2                vendor_address2         -- 住所２（送付先）
            ,xtvci.vendor_name                    vendor_name             -- 仕入先名称（送付先）
            ,xtvci.customer_code                  customer_code           -- 顧客コード
            ,xtvci.vendor_code                    vendor_code             -- 仕入先コード
            ,xtvci.sales_base_city                sales_base_city         -- 都道府県市区（売上拠点）
            ,xtvci.sales_base_address1            sales_base_address1     -- 住所１（売上拠点）
            ,xtvci.sales_base_address2            sales_base_address2     -- 住所２（売上拠点）
            ,xtvci.sales_base_name                sales_base_name         -- 売上拠点名称
            ,xtvci.sales_base_tel                 sales_base_tel          -- 電話番号（売上拠点）
            ,xtvci.date_from                      date_from               -- 対象期間開始日
            ,xtvci.date_to                        date_to                 -- 対象期間終了日
            ,xtvci.customer_name                  customer_name           -- 顧客名称
            ,ximb.item_short_name                 item_short_name         -- 略称
            ,xsel.dlv_unit_price                  dlv_unit_price          -- 納品単価
            ,SUM( xsel.dlv_qty )                  sum_dlv_qty             -- 納品数量合計
            ,SUM( xsel.sale_amount )              sum_sale_amount         -- 売上金額合計
            ,xtvci.party_id                       party_id                -- パーティID(担当営業取得条件)
            ,MAX(xseh.delivery_date )             delivery_date           -- 納品日
            ,iimb.item_no                         item_no                 -- 品目コード(メッセージ出力用)
      FROM   xxcos_tmp_vd_cust_info      xtvci --自販機販売報告書顧客情報一時表
            ,xxcos_sales_exp_headers     xseh  --販売実績ヘッダ
            ,xxcos_sales_exp_lines       xsel  --販売実績明細
            ,ic_item_mst_b               iimb  --OPM品目マスタ
            ,xxcmn_item_mst_b            ximb  --OPM品目アドオン
            ,mtl_system_items_b          msib  --Disc品目マスタ
            ,mtl_item_categories         mic   --品目カテゴリ
            ,mtl_categories_b            mcb   --カテゴリ
      WHERE xtvci.customer_code                        = xseh.ship_to_customer_code
      AND   xseh.delivery_date                        >= xtvci.date_from                             -- 顧客毎の締日の範囲
      AND   xseh.delivery_date                        <= xtvci.date_to                               -- 顧客毎の締日の範囲
      AND   xseh.cust_gyotai_sho                      IN ( cv_bus_low_type_24, cv_bus_low_type_25 )  -- 業態小分類
      AND   xseh.sales_exp_header_id                   = xsel.sales_exp_header_id
      AND   NOT EXISTS (
              SELECT 1
              FROM   fnd_lookup_values flv
              WHERE  flv.lookup_type  = cv_no_item
              AND    flv.lookup_code  = xsel.item_code
              AND    flv.language     = ct_lang
              AND    flv.enabled_flag = cv_y
              AND    gd_proc_date BETWEEN flv.start_date_active
                                  AND     NVL(  flv.end_date_active, gd_proc_date )
            )                                                                                       -- 非在庫品以外
      AND   xsel.sales_class                         IN ( cv_1, cv_3 )                              -- 通常とベンダ売上のみ
      AND   xsel.item_code                            = iimb.item_no
      AND   iimb.item_id                              = ximb.item_id
      AND   ximb.start_date_active                   <= gd_proc_date                                -- 業務日付時点で有効
      AND   NVL(ximb.end_date_active, gd_proc_date)  >= gd_proc_date                                -- 業務日付時点で有効
      AND   iimb.item_no                              = msib.segment1
      AND   msib.organization_id                      = gn_organization_id
      AND   msib.inventory_item_id                    = mic.inventory_item_id
      AND   mic.category_set_id                       = gt_category_set_id
      AND   mic.organization_id                       = gn_organization_id
      AND   mic.category_id                           = mcb.category_id
      GROUP BY
             xtvci.vendor_zip              --郵便番号（送付先）
            ,xtvci.vendor_address1         --住所１（送付先）
            ,xtvci.vendor_address2         --住所２（送付先）
            ,xtvci.vendor_name             --仕入先名称（送付先）
            ,xtvci.customer_code           --顧客コード
            ,xtvci.vendor_code             --仕入先コード
            ,xtvci.sales_base_city         --都道府県市区（売上拠点）
            ,xtvci.sales_base_address1     --住所１（売上拠点）
            ,xtvci.sales_base_address2     --住所２（売上拠点）
            ,xtvci.sales_base_name         --売上拠点名称
            ,xtvci.sales_base_tel          --電話番号（売上拠点）
            ,xtvci.date_from               --対象期間開始日
            ,xtvci.date_to                 --対象期間終了日
            ,xtvci.customer_name           --顧客名称
            ,mcb.segment1                  --政策群コード
            ,iimb.item_no                  --品目コード
            ,ximb.item_short_name          --略称
            ,xsel.dlv_unit_price           --納品単価
            ,xtvci.party_id                --パーティID
      HAVING
            ( SUM( xsel.dlv_qty ) <> 0 OR SUM( xsel.sale_amount ) <> 0 )  --サマリ数量かサマリ金額が0以外
      ORDER BY
            xtvci.vendor_code    --仕入先コード
           ,xtvci.customer_code  --顧客コード
           ,mcb.segment1         --政策群コード
           ,iimb.item_no         --品目コード
      ;
    -- *** ローカルテーブル ***
    TYPE l_vd_sales_ttype IS TABLE OF get_vd_sales_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    -- *** ローカル配列 ***
    l_vd_sales_tab l_vd_sales_ttype;
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
    -- 処理単位の初期化
    gn_warn       := cv_status_normal;  --警告終了用変数
    ln_work_ind   := 0;                 --一時配列用索引初期化
    ln_create_ind := 0;                 --作成用索引初期化
--
    -- オープン
    OPEN get_vd_sales_cur;
    -- データ取得
    FETCH get_vd_sales_cur BULK COLLECT INTO l_vd_sales_tab;
    -- クローズ
    CLOSE get_vd_sales_cur;
    -- 対象件数取得
    gn_target_cnt := l_vd_sales_tab.COUNT;
--
    --------------------------------
    -- データの取得、及び、編集処理
    --------------------------------
    <<sales_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
--
      -- 1レコード単位の初期化
      lv_output_flag := cv_y;  -- 出力対象
      lv_wrnmsg      := NULL;  -- チェックメッセージ用
--
      --最初の1件の場合、ブレーク変数に値を設定
      IF ( lt_party_id IS NULL ) THEN
        lt_cust_code := l_vd_sales_tab(i).customer_code;
        lt_party_id  := l_vd_sales_tab(i).party_id;
      END IF;
      -----------------------------
      -- 納品単価の小数点チェック
      -----------------------------
      IF ( TRUNC( l_vd_sales_tab(i).dlv_unit_price ) <> l_vd_sales_tab(i).dlv_unit_price ) THEN
        -- 出力対象外とする
        lv_output_flag := cv_n;
        -- メッセージ出力
        lv_wrnmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_price_wrn                  --メッセージコード
                        ,iv_token_name1  => cv_tkn_cust
                        ,iv_token_value1 => l_vd_sales_tab(i).customer_code   --顧客コード
                        ,iv_token_name2  => cv_tkn_item
                        ,iv_token_value2 => l_vd_sales_tab(i).item_no         --品目コード
                        ,iv_token_name3  => cv_tkn_dlv_price
                        ,iv_token_value3 => l_vd_sales_tab(i).dlv_unit_price  --売価
                      );
        -- ログへ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_wrnmsg
        );
        -- 警告終了用のグローバル変数に警告を設定
        gn_warn     := cv_status_warn;
        -- 警告件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      -- 出力対象のみ出力する
      IF ( lv_output_flag = cv_y ) THEN
--
        -- 一時格納用索引のインクリメント
        ln_work_ind := ln_work_ind + 1;
--
        -- レコードID取得
        SELECT xxcos_rep_vd_sales_list_s01.NEXTVAL
        INTO   g_sales_tab_work(ln_work_ind).record_id
        FROM   dual
        ;
--
        -- 最大納品日取得用の変数に値を設定
        IF ( lt_dlv_date IS NULL ) OR ( lt_dlv_date < l_vd_sales_tab(i).delivery_date ) THEN
          lt_dlv_date := l_vd_sales_tab(i).delivery_date;
        END IF;
--
        -- 一時用配列に値を設定
        g_sales_tab_work(ln_work_ind).vendor_zip              :=  l_vd_sales_tab(i).vendor_zip;            -- 郵便番号（送付先）
        g_sales_tab_work(ln_work_ind).vendor_address1         :=  l_vd_sales_tab(i).vendor_address1;       -- 住所１（送付先）
        g_sales_tab_work(ln_work_ind).vendor_address2         :=  l_vd_sales_tab(i).vendor_address2;       -- 住所２（送付先）
        g_sales_tab_work(ln_work_ind).vendor_name             :=  l_vd_sales_tab(i).vendor_name;           -- 仕入先名称（送付先）
        g_sales_tab_work(ln_work_ind).customer_code           :=  l_vd_sales_tab(i).customer_code;         -- 顧客コード
        g_sales_tab_work(ln_work_ind).vendor_code             :=  l_vd_sales_tab(i).vendor_code;           -- 仕入先コード
        g_sales_tab_work(ln_work_ind).sales_base_city         :=  l_vd_sales_tab(i).sales_base_city;       -- 都道府県市区（売上拠点
        g_sales_tab_work(ln_work_ind).sales_base_address1     :=  l_vd_sales_tab(i).sales_base_address1;   -- 住所１（売上拠点）
        g_sales_tab_work(ln_work_ind).sales_base_address2     :=  l_vd_sales_tab(i).sales_base_address2;   -- 住所２（売上拠点）
        g_sales_tab_work(ln_work_ind).sales_base_name         :=  l_vd_sales_tab(i).sales_base_name;       -- 売上拠点名称
        g_sales_tab_work(ln_work_ind).sales_base_tel          :=  l_vd_sales_tab(i).sales_base_tel;        -- 電話番号（売上拠点）
        g_sales_tab_work(ln_work_ind).date_from               :=  l_vd_sales_tab(i).date_from;             -- 対象期間開始日
        g_sales_tab_work(ln_work_ind).date_to                 :=  l_vd_sales_tab(i).date_to;               -- 対象期間終了日
        g_sales_tab_work(ln_work_ind).install_location        :=  l_vd_sales_tab(i).customer_name;         -- 設置先場所
        g_sales_tab_work(ln_work_ind).item_name               :=  l_vd_sales_tab(i).item_short_name;       -- 商品名
        g_sales_tab_work(ln_work_ind).sales_price             :=  l_vd_sales_tab(i).dlv_unit_price;        -- 売価
        g_sales_tab_work(ln_work_ind).sales_qty               :=  l_vd_sales_tab(i).sum_dlv_qty;           -- 販売本数
        g_sales_tab_work(ln_work_ind).sales_amount            :=  l_vd_sales_tab(i).sum_sale_amount;       -- 販売金額
        g_sales_tab_work(ln_work_ind).created_by              :=  cn_created_by;                           -- WHOカラム
        g_sales_tab_work(ln_work_ind).creation_date           :=  cd_creation_date;                        -- WHOカラム
        g_sales_tab_work(ln_work_ind).last_updated_by         :=  cn_last_updated_by;                      -- WHOカラム
        g_sales_tab_work(ln_work_ind).last_update_date        :=  cd_last_update_date;                     -- WHOカラム
        g_sales_tab_work(ln_work_ind).last_update_login       :=  cn_last_update_login;                    -- WHOカラム
        g_sales_tab_work(ln_work_ind).request_id              :=  cn_request_id;                           -- WHOカラム
        g_sales_tab_work(ln_work_ind).program_application_id  :=  cn_program_application_id;               -- WHOカラム
        g_sales_tab_work(ln_work_ind).program_id              :=  cn_program_id;                           -- WHOカラム
        g_sales_tab_work(ln_work_ind).program_update_date     :=  cd_program_update_date;                  -- WHOカラム
--
      END IF;
--
      -- 前レコードと異なる場合、もしくは、最終レコードの場合
      IF (
           ( lt_cust_code <> l_vd_sales_tab(i).customer_code )
           OR
           (
                 ( i = gn_target_cnt )
             AND ( g_sales_tab_work.COUNT <> 0 )
           )
         ) THEN
        ----------------------------------------------
        --顧客担当者名称取得(範囲内で最大の納品日時点)
        ----------------------------------------------
        BEGIN
          SELECT ppf.per_information18 || ppf.per_information19  salesrep_name -- 担当営業員名称
          INTO   lv_salesrep_name
          FROM   hz_organization_profiles   hop       -- 組織プロファイル(営業担当)
                ,ego_fnd_dsc_flx_ctx_ext    efdfce    -- 拡張付加フレックスコンテキスト(営業担当)
                ,hz_org_profiles_ext_b      hopeb     -- 組織プロファイル拡張テーブル(営業担当)
                ,per_all_people_f           ppf       -- 従業員マスタ(営業担当)
          WHERE  hop.party_id                               = lt_party_id
          AND    hop.effective_end_date                     IS NULL
          AND    hop.organization_profile_id                = hopeb.organization_profile_id
          AND    hopeb.attr_group_id                        = efdfce.attr_group_id
          AND    efdfce.application_id                      = gt_apprication_id
          AND    efdfce.descriptive_flexfield_name          = cv_prof_group
          AND    efdfce.descriptive_flex_context_code       = cv_resource
          AND    hopeb.d_ext_attr1                         <= lt_dlv_date
          AND    NVL( hopeb.d_ext_attr2, lt_dlv_date )     >= lt_dlv_date
          AND    hopeb.c_ext_attr1                          = ppf.employee_number
          AND    ppf.effective_start_date                  <= lt_dlv_date
          AND    ppf.effective_end_date                    >= lt_dlv_date
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_salesrep_name := NULL;  --取得できない場合はNULLを設定
          WHEN OTHERS THEN
            lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 ); --SQLERRM格納
            -- テーブル名取得
            lv_msg_tnk := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_tkn_emp_table   -- 従業員マスタ
                          );
            RAISE select_expt;
        END;
--
        -- 作成用配列にセット
        <<ins_set_loop>>
        FOR i2 IN 1.. g_sales_tab_work.COUNT LOOP
--
          --作成用配列の索引のインクリメント
          ln_create_ind := ln_create_ind + 1;
--
          g_sales_tab(ln_create_ind).record_id               :=  g_sales_tab_work(i2).record_id;               -- レコードID
          g_sales_tab(ln_create_ind).vendor_zip              :=  g_sales_tab_work(i2).vendor_zip;              -- 郵便番号（送付先）
          g_sales_tab(ln_create_ind).vendor_address1         :=  g_sales_tab_work(i2).vendor_address1;         -- 住所１（送付先）
          g_sales_tab(ln_create_ind).vendor_address2         :=  g_sales_tab_work(i2).vendor_address2;         -- 住所２（送付先）
          g_sales_tab(ln_create_ind).vendor_name             :=  g_sales_tab_work(i2).vendor_name;             -- 仕入先名称（送付先）
          g_sales_tab(ln_create_ind).customer_code           :=  g_sales_tab_work(i2).customer_code;           -- 顧客コード
          g_sales_tab(ln_create_ind).vendor_code             :=  g_sales_tab_work(i2).vendor_code;             -- 仕入先コード
          g_sales_tab(ln_create_ind).sales_base_city         :=  g_sales_tab_work(i2).sales_base_city;         -- 都道府県市区（売上拠点
          g_sales_tab(ln_create_ind).sales_base_address1     :=  g_sales_tab_work(i2).sales_base_address1;     -- 住所１（売上拠点）
          g_sales_tab(ln_create_ind).sales_base_address2     :=  g_sales_tab_work(i2).sales_base_address2;     -- 住所２（売上拠点）
          g_sales_tab(ln_create_ind).sales_base_name         :=  g_sales_tab_work(i2).sales_base_name;         -- 売上拠点名称
          g_sales_tab(ln_create_ind).sales_base_tel          :=  g_sales_tab_work(i2).sales_base_tel;          -- 電話番号（売上拠点）
          g_sales_tab(ln_create_ind).salesrep_name           :=  lv_salesrep_name;                             -- 顧客担当者名称
          g_sales_tab(ln_create_ind).date_from               :=  g_sales_tab_work(i2).date_from;               -- 対象期間開始日
          g_sales_tab(ln_create_ind).date_to                 :=  g_sales_tab_work(i2).date_to;                 -- 対象期間終了日
          g_sales_tab(ln_create_ind).install_location        :=  g_sales_tab_work(i2).install_location;        -- 設置先場所
          g_sales_tab(ln_create_ind).item_name               :=  g_sales_tab_work(i2).item_name;               -- 商品名
          g_sales_tab(ln_create_ind).sales_price             :=  g_sales_tab_work(i2).sales_price;             -- 売価
          g_sales_tab(ln_create_ind).sales_qty               :=  g_sales_tab_work(i2).sales_qty;               -- 販売本数
          g_sales_tab(ln_create_ind).sales_amount            :=  g_sales_tab_work(i2).sales_amount;            -- 販売金額
          g_sales_tab(ln_create_ind).created_by              :=  g_sales_tab_work(i2).created_by;              -- WHOカラム
          g_sales_tab(ln_create_ind).creation_date           :=  g_sales_tab_work(i2).creation_date;           -- WHOカラム
          g_sales_tab(ln_create_ind).last_updated_by         :=  g_sales_tab_work(i2).last_updated_by;         -- WHOカラム
          g_sales_tab(ln_create_ind).last_update_date        :=  g_sales_tab_work(i2).last_update_date;        -- WHOカラム
          g_sales_tab(ln_create_ind).last_update_login       :=  g_sales_tab_work(i2).last_update_login;       -- WHOカラム
          g_sales_tab(ln_create_ind).request_id              :=  g_sales_tab_work(i2).request_id;              -- WHOカラム
          g_sales_tab(ln_create_ind).program_application_id  :=  g_sales_tab_work(i2).program_application_id;  -- WHOカラム
          g_sales_tab(ln_create_ind).program_id              :=  g_sales_tab_work(i2).program_id;              -- WHOカラム
          g_sales_tab(ln_create_ind).program_update_date     :=  g_sales_tab_work(i2).program_update_date;     -- WHOカラム
--
        END LOOP ins_set_loop;
--
        -- ブレーク用変数に値を設定
        lt_cust_code := l_vd_sales_tab(i).customer_code;
        -- 顧客取得用にパーティID保持
        lt_party_id  := l_vd_sales_tab(i).party_id;
        -- 最大納品日取得の変数を初期化
        lt_dlv_date  := NULL;
        -- 一時用配列索引初期化
        ln_work_ind  := 0;
        -- 一時配列の削除
        g_sales_tab_work.DELETE;
--
      END IF;
--
    END LOOP sales_loop;
--
    --ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_date_time )
    );
    --ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** データ抽出例外 ***
    WHEN select_expt THEN
      -- メッセージ取得
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_select_err      -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lv_msg_tnk             -- テーブル名
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
      -- カーソルクローズ
      IF ( get_vd_sales_cur%ISOPEN ) THEN
        CLOSE get_vd_sales_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_work_data
   * Description      : 帳票ワークテーブル作成処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_rep_work_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rep_work_data'; -- プログラム名
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
    lv_sqlerrm  VARCHAR2(5000);      -- SQLERRM格納用
    lv_msg_tnk  VARCHAR2(100);       -- メッセージトークン用
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
    BEGIN
      --=================================================
      -- 自販機販売報告書帳票ワークテーブルデータ挿入処理
      --=================================================
      FORALL i IN 1..g_sales_tab.COUNT
        INSERT INTO xxcos_rep_vd_sales_list
        VALUES g_sales_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 ); -- SQLERRM格納
        RAISE insert_expt;
    END;
--
    -- 成功件数カウント
    gn_normal_cnt := g_sales_tab.COUNT;
    -- 配列を削除
    g_sales_tab.DELETE;
--
    -- SVF発行の為、ここでCOMMIT
    COMMIT;
--
  EXCEPTION
    -- *** データ登録例外 ***
    WHEN insert_expt THEN
      -- テーブル名取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_rep_table   -- 自販機販売報告書帳票ワークテーブル
                    );
      -- メッセージ取得
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_insert_err      -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lv_msg_tnk             -- テーブル名
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg  := lv_errmsg;
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
  END ins_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動処理(A-6)
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
    lv_nodata_msg    VARCHAR2(5000); -- 0件メッセージ
    lv_file_name     VARCHAR2(5000); -- ファイル名
    lv_msg_tnk       VARCHAR2(100);  -- メッセージトークン用
    lv_err_msg       VARCHAR2(5000); -- メッセージ用
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
    -- 明細0件用メッセージ取得
    lv_nodata_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_nodata_err --メッセージコード
                      );
    --出力ファイル名編集
    lv_file_name  := cv_pkg_name                                    || -- プログラムID(パッケージ名)
                     TO_CHAR( cd_creation_date, cv_date_yyyymmdd2 ) || -- 日付
                     TO_CHAR( cn_request_id )                       || -- 要求ID
                     cv_extension_pdf                                  -- 拡張子(PDF)
                     ;
    --==================================
    -- SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_retcode         => lv_retcode                -- リターンコード
      ,ov_errbuf          => lv_errbuf                 -- エラーメッセージ
      ,ov_errmsg          => lv_errmsg                 -- ユーザー・エラーメッセージ
      ,iv_conc_name       => cv_pkg_name               -- コンカレント名
      ,iv_file_name       => lv_file_name              -- 出力ファイル名
      ,iv_file_id         => cv_pkg_name               -- 帳票ID
      ,iv_output_mode     => cv_output_mode_pdf        -- 出力区分
      ,iv_frm_file        => cv_frm_name               -- フォーム様式ファイル名
      ,iv_vrq_file        => cv_vrq_name               -- クエリー様式ファイル名
      ,iv_org_id          => NULL                      -- ORG_ID
      ,iv_user_name       => NULL                      -- ログイン・ユーザ名
      ,iv_resp_name       => NULL                      -- ログイン・ユーザの職責名
      ,iv_doc_name        => NULL                      -- 文書名
      ,iv_printer_name    => NULL                      -- プリンタ名
      ,iv_request_id      => TO_CHAR( cn_request_id )  -- 要求ID
      ,iv_nodata_msg      => lv_nodata_msg             -- データなしメッセージ
      ,iv_svf_param1      => NULL                      -- svf可変パラメータ1
      ,iv_svf_param2      => NULL                      -- svf可変パラメータ2
      ,iv_svf_param3      => NULL                      -- svf可変パラメータ3
      ,iv_svf_param4      => NULL                      -- svf可変パラメータ4
      ,iv_svf_param5      => NULL                      -- svf可変パラメータ5
      ,iv_svf_param6      => NULL                      -- svf可変パラメータ6
      ,iv_svf_param7      => NULL                      -- svf可変パラメータ7
      ,iv_svf_param8      => NULL                      -- svf可変パラメータ8
      ,iv_svf_param9      => NULL                      -- svf可変パラメータ9
      ,iv_svf_param10     => NULL                      -- svf可変パラメータ10
      ,iv_svf_param11     => NULL                      -- svf可変パラメータ11
      ,iv_svf_param12     => NULL                      -- svf可変パラメータ12
      ,iv_svf_param13     => NULL                      -- svf可変パラメータ13
      ,iv_svf_param14     => NULL                      -- svf可変パラメータ14
      ,iv_svf_param15     => NULL                      -- svf可変パラメータ15
    );
    --SVF処理結果確認
    IF  ( lv_retcode  <> cv_status_normal ) THEN
      -- トークン取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_svf_api  -- SVF起動API
                    );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_api_err      -- メッセージコード
                      ,iv_token_name1  => cv_tkn_api_name
                      ,iv_token_value1 => lv_msg_tnk          -- プロファイル名
                    );
      -- ログ出力用メッセージ(SVFのエラーメッセージ)
      lv_errbuf := SUBSTRB( lv_errmsg || cv_msg_part || lv_errbuf, 1, 5000 );
      -- ユーザ用メッセージ
      lv_errmsg := lv_err_msg;
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_data
   * Description      : 帳票ワークテーブル削除処理(A-7)
   ***********************************************************************************/
  PROCEDURE del_rep_work_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_data'; -- プログラム名
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
    lv_sqlerrm  VARCHAR2(5000); -- SQLERRM格納用
    lv_msg_tnk  VARCHAR2(100);  -- メッセージトークン用
    lv_msg_code VARCHAR2(16);   -- メッセージ切り替え用
    lv_tkn_code VARCHAR2(10);   -- トークン切り替え用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機販売報告書帳票ワークテーブル削除用カーソル
    CURSOR del_rep_table_cur
    IS
      SELECT 1
      FROM   xxcos_rep_vd_sales_list xrvsl
      WHERE  xrvsl.request_id = cn_request_id
      FOR UPDATE NOWAIT
      ;
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
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    BEGIN
     --=========================================
     -- 自販機販売報告書帳票ワークテーブルロック
     --=========================================
      -- オープン
      OPEN del_rep_table_cur;
      -- クローズ
      CLOSE del_rep_table_cur;
    EXCEPTION
      WHEN lock_expt THEN
        lv_sqlerrm   := SUBSTRB( SQLERRM, 1, 5000 );  -- SQLERRM格納
        lv_msg_code  := cv_msg_lock_err;              -- メッセージコード(ロックエラー)
        lv_tkn_code  := cv_tkn_table;                 -- トークン(TABLE)
        RAISE delete_proc_expt;
    END;
--
   BEGIN
     --=========================================
     -- 自販機販売報告書帳票ワークテーブル削除
     --=========================================
     DELETE
     FROM   xxcos_rep_vd_sales_list xrvsl
     WHERE  xrvsl.request_id = cn_request_id
     ;
   EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm   := SUBSTRB( SQLERRM, 1, 5000 );  -- SQLERRM格納
        lv_msg_code  := cv_msg_delete_err;            -- メッセージコード(削除エラー)
        lv_tkn_code  := cv_tkn_table_name;            -- トークン(TABLE_NAME)
        RAISE delete_proc_expt;
   END;
--
   --SVFがエラーとなったとき、ROLLBACKされるのでここでコミット
   COMMIT;
--
  EXCEPTION
    --*** 削除処理汎用例外 ***
    WHEN delete_proc_expt THEN
      -- テーブル名取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_rep_table   -- 自販機販売報告書帳票ワークテーブル
                    );
      -- メッセージ取得
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => lv_msg_code            -- メッセージコード(ロックor削除)
                      ,iv_token_name1  => lv_tkn_code            -- トークン
                      ,iv_token_value1 => lv_msg_tnk             -- テーブル名
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END del_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_manager_flag     IN  VARCHAR2  --  1.管理者フラグ(Y:管理者 N:拠点)
    ,iv_execute_type     IN  VARCHAR2  --  2.実行区分(1:顧客指定 2:仕入先指定)
    ,iv_target_date      IN  VARCHAR2  --  3.対象年月
    ,iv_sales_base_code  IN  VARCHAR2  --  4.売上拠点コード(顧客指定時のみ)
    ,iv_customer_code_01 IN  VARCHAR2  --  5.顧客コード1(顧客指定時のみ)
    ,iv_customer_code_02 IN  VARCHAR2  --  6.顧客コード2(顧客指定時のみ)
    ,iv_customer_code_03 IN  VARCHAR2  --  7.顧客コード3(顧客指定時のみ)
    ,iv_customer_code_04 IN  VARCHAR2  --  8.顧客コード4(顧客指定時のみ)
    ,iv_customer_code_05 IN  VARCHAR2  --  9.顧客コード5(顧客指定時のみ)
    ,iv_customer_code_06 IN  VARCHAR2  -- 10.顧客コード6(顧客指定時のみ)
    ,iv_customer_code_07 IN  VARCHAR2  -- 11.顧客コード7(顧客指定時のみ)
    ,iv_customer_code_08 IN  VARCHAR2  -- 12.顧客コード8(顧客指定時のみ)
    ,iv_customer_code_09 IN  VARCHAR2  -- 13.顧客コード9(顧客指定時のみ)
    ,iv_customer_code_10 IN  VARCHAR2  -- 14.顧客コード10(顧客指定時のみ)
    ,iv_vendor_code_01   IN  VARCHAR2  -- 15.仕入先コード1(仕入先指定時のみ)
    ,iv_vendor_code_02   IN  VARCHAR2  -- 16.仕入先コード2(仕入先指定時のみ)
    ,iv_vendor_code_03   IN  VARCHAR2  -- 17.仕入先コード3(仕入先指定時のみ)
    ,ov_errbuf           OUT VARCHAR2  --    エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2  --    リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2  --    ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVFエラー時退避用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVFエラー時退避用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVFエラー時退避用)
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
    -------------------------------------------------
    -- 入力パラメータをグローバルレコード・配列に保持
    -------------------------------------------------
    g_input_rec.manager_flag     := iv_manager_flag;     --  1.管理者フラグ(Y:管理者 N:拠点)
    g_input_rec.execute_type     := iv_execute_type;     --  2.実行区分(1:顧客指定 2:仕入先指定)
    g_input_rec.target_date      := iv_target_date;      --  3.対象年月
    g_input_rec.sales_base_code  := iv_sales_base_code;  --  4.売上拠点コード(顧客指定時のみ)
--
    --実行区分が1(顧客指定で実行）の場合
    IF ( g_input_rec.execute_type = cv_1 ) THEN
      g_cust_tab(1)  := iv_customer_code_01; --  4.顧客コード1(顧客指定時のみ)
      g_cust_tab(2)  := iv_customer_code_02; --  5.顧客コード2(顧客指定時のみ)
      g_cust_tab(3)  := iv_customer_code_03; --  6.顧客コード3(顧客指定時のみ)
      g_cust_tab(4)  := iv_customer_code_04; --  7.顧客コード4(顧客指定時のみ)
      g_cust_tab(5)  := iv_customer_code_05; --  8.顧客コード5(顧客指定時のみ)
      g_cust_tab(6)  := iv_customer_code_06; --  9.顧客コード6(顧客指定時のみ)
      g_cust_tab(7)  := iv_customer_code_07; -- 10.顧客コード7(顧客指定時のみ)
      g_cust_tab(8)  := iv_customer_code_08; -- 11.顧客コード8(顧客指定時のみ)
      g_cust_tab(9)  := iv_customer_code_09; -- 12.顧客コード9(顧客指定時のみ)
      g_cust_tab(10) := iv_customer_code_10; -- 13.顧客コード10(顧客指定時のみ)
    --実行区分が2(仕入先指定で実行）の場合
    ELSIF ( g_input_rec.execute_type = cv_2 ) THEN
      g_vend_tab(1)  := iv_vendor_code_01;   -- 14.仕入先コード1(仕入先指定時のみ)
      g_vend_tab(2)  := iv_vendor_code_02;   -- 15.仕入先コード2(仕入先指定時のみ)
      g_vend_tab(3)  := iv_vendor_code_03;   -- 16.仕入先コード3(仕入先指定時のみ)
    END IF;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 関連データ取得処理(A-2)
    -- ===============================
    get_relation_data(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 顧客情報取得処理(A-3)
    -- ===============================
    get_cust_info_data(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 販売情報取得処理(A-4)
    -- ===============================
    get_sales_exp_data(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 帳票用ワークテーブル作成(A-5)
    -- ===============================
    ins_rep_work_data(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- SVF起動処理(A-6)
    -- ===============================
    execute_svf(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --ワーク削除の為、ここで例外とせず結果を退避
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
    END IF;
--
    -- ===============================
    -- 帳票ワークテーブル削除処理(A-7)
    -- ===============================
    del_rep_work_data(
      lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,lv_retcode        -- リターン・コード             --# 固定 #
     ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf     := lv_errbuf_svf;
      lv_errmsg_svf := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
--
    --明細0件時ステータス制御処理
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    --出力対象外データが存在する場合のステータス制御処理
    ELSIF ( gn_warn = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
     errbuf              OUT VARCHAR2  --    エラー・メッセージ  --# 固定 #
    ,retcode             OUT VARCHAR2  --    リターン・コード    --# 固定 #
    ,iv_manager_flag     IN  VARCHAR2  --  1.管理者フラグ(Y:管理者 N:拠点)
    ,iv_execute_type     IN  VARCHAR2  --  2.実行区分(1:顧客指定 2:仕入先指定)
    ,iv_target_date      IN  VARCHAR2  --  3.対象年月
    ,iv_sales_base_code  IN  VARCHAR2  --  4.売上拠点コード(顧客指定時のみ)
    ,iv_customer_code_01 IN  VARCHAR2  --  5.顧客コード1(顧客指定時のみ)
    ,iv_customer_code_02 IN  VARCHAR2  --  6.顧客コード2(顧客指定時のみ)
    ,iv_customer_code_03 IN  VARCHAR2  --  7.顧客コード3(顧客指定時のみ)
    ,iv_customer_code_04 IN  VARCHAR2  --  8.顧客コード4(顧客指定時のみ)
    ,iv_customer_code_05 IN  VARCHAR2  --  9.顧客コード5(顧客指定時のみ)
    ,iv_customer_code_06 IN  VARCHAR2  -- 10.顧客コード6(顧客指定時のみ)
    ,iv_customer_code_07 IN  VARCHAR2  -- 11.顧客コード7(顧客指定時のみ)
    ,iv_customer_code_08 IN  VARCHAR2  -- 12.顧客コード8(顧客指定時のみ)
    ,iv_customer_code_09 IN  VARCHAR2  -- 13.顧客コード9(顧客指定時のみ)
    ,iv_customer_code_10 IN  VARCHAR2  -- 14.顧客コード10(顧客指定時のみ)
    ,iv_vendor_code_01   IN  VARCHAR2  -- 15.仕入先コード1(仕入先指定時のみ)
    ,iv_vendor_code_02   IN  VARCHAR2  -- 16.仕入先コード2(仕入先指定時のみ)
    ,iv_vendor_code_03   IN  VARCHAR2  -- 17.仕入先コード3(仕入先指定時のみ)
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
    cv_log_header_log  CONSTANT VARCHAR2(3)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_which   => cv_log_header_log
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
       iv_manager_flag     --管理者フラグ
      ,iv_execute_type     --実行区分
      ,iv_target_date      --対象年月
      ,iv_sales_base_code  --売上拠点コード
      ,iv_customer_code_01 --顧客コード1
      ,iv_customer_code_02 --顧客コード2
      ,iv_customer_code_03 --顧客コード3
      ,iv_customer_code_04 --顧客コード4
      ,iv_customer_code_05 --顧客コード5
      ,iv_customer_code_06 --顧客コード6
      ,iv_customer_code_07 --顧客コード7
      ,iv_customer_code_08 --顧客コード8
      ,iv_customer_code_09 --顧客コード9
      ,iv_customer_code_10 --顧客コード10
      ,iv_vendor_code_01   --仕入先コード1
      ,iv_vendor_code_02   --仕入先コード2
      ,iv_vendor_code_03   --仕入先コード3
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
END XXCOS002A06R;
/
