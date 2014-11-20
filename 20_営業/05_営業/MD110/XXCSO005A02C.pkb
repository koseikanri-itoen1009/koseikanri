CREATE OR REPLACE PACKAGE BODY APPS.XXCSO005A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO005A02C(body)
 * Description      : 営業員リソースチェックCSV出力
 * MD.050           : 営業員リソースチェックCSV出力 (MD050_CSO_005A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_resource_data      営業員リソース情報取得(A-2)
 *  output_data            CSVファイル出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/10    1.0   S.Niki           新規作成
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
  global_warn_expt          EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCSO005A02C';      -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxcso    CONSTANT VARCHAR2(10)  := 'XXCSO';             -- XXCSO
  -- 日付書式
  cv_fmt_yyyymmdd       CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  -- 文字括り
  cv_dqu                CONSTANT VARCHAR2(1)   := '"';                 -- 文字列括り
  cv_comma              CONSTANT VARCHAR2(1)   := ',';                 -- カンマ
  -- メッセージコード
  cv_msg_cso_00130      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00130';  -- 拠点コード
  cv_msg_cso_00129      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00129';  -- 基準年月日
  cv_msg_cso_00224      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00224';  -- CSVファイル出力0件エラー
  cv_msg_cso_00656      CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00656';  -- 営業員リソースCSVヘッダ
--
  -- トークン
  cv_tkn_entry          CONSTANT VARCHAR2(20)  := 'ENTRY';             -- 入力値
  cv_tkn_count          CONSTANT VARCHAR2(20)  := 'COUNT';             -- 件数
--
  cv_yes                CONSTANT VARCHAR2(1)                          := 'Y';                -- YES
  cv_no                 CONSTANT VARCHAR2(1)                          := 'N';                -- NO
  ct_ctg_emp            jtf_rs_resource_extns_vl.category%TYPE        := 'EMPLOYEE';         -- カテゴリー
  ct_res_grm            jtf_rs_defresroles_vl.role_resource_type%TYPE := 'RS_GROUP_MEMBER';  -- RS_GROUP_MEMBER
  ct_res_idv            jtf_rs_role_relations.role_resource_type%TYPE := 'RS_INDIVIDUAL';    -- RS_INDIVIDUAL
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_base_code          jtf_rs_groups_vl.attribute1%TYPE;  -- パラメータ拠点コード
  gd_base_date          DATE;                              -- パラメータ基準年月日
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  CURSOR resorce_data_cur
  IS
    SELECT  r.resource_id                                     AS resource_id       -- リソースID
           ,r.source_number                                   AS source_number     -- 従業員番号
           ,r.source_name                                     AS source_name       -- 従業員名称
           ,r.attribute1                                      AS emp_form          -- 営業形態(DFF1)
           ,r.attribute2                                      AS renraku           -- 連絡先(DFF2)
           ,r.attribute3                                      AS vd_toitu          -- VD統一キーNO(DFF3)
           ,r.attribute4                                      AS emp_dash          -- 営業ダッシュボード使用可能フラグ(DFF4)
           ,g.attribute1                                      AS base_code         -- 拠点コード(DFF1)
           ,g.group_name                                      AS group_name        -- グループ名称(拠点名)
           ,rol.role_name                                     AS rol_name          -- グループメンバ役割名称
           ,TO_CHAR(rol.res_rl_start_date ,cv_fmt_yyyymmdd)   AS rol_start_date    -- グループメンバ役割開始日
           ,TO_CHAR(rol.res_rl_end_date   ,cv_fmt_yyyymmdd)   AS rol_end_date      -- グループメンバ役割終了日
           ,m.attribute1                                      AS group_leader      -- グループ長区分(DFF1)
           ,m.attribute2                                      AS group_num         -- グループ番号(DFF2)
           ,m.attribute3                                      AS group_order       -- グループ順位(DFF3)
    FROM    jtf_rs_resource_extns_vl  r    -- リソース
           ,jtf_rs_group_members      m    -- リソースグループメンバー
           ,jtf_rs_groups_vl          g    -- リソースグループ
           ,jtf_rs_defresroles_vl     rol  -- グループメンバ役割
    WHERE   r.category                      = ct_ctg_emp             -- カテゴリ'EMPLOYEE'
    AND     r.resource_id                   = m.resource_id
    AND     NVL(m.delete_flag(+) ,cv_no)    <> cv_yes
    AND     m.group_id                      = g.group_id
    AND     m.group_member_id               = rol.role_resource_id(+)
    AND     rol.role_resource_type(+)       = ct_res_grm             -- 'RS_GROUP_MEMBER'
    AND     NVL(rol.delete_flag(+) ,cv_no)  <> cv_yes
    AND     g.attribute1                    = gt_base_code           -- パラメータ.拠点コード
    AND    (
              ( gd_base_date       BETWEEN  r.start_date_active    -- パラメータ.基準年月日（リソース）
                                   AND      NVL(r.end_date_active, gd_base_date) )
            OR
              ( gd_base_date                < r.start_date_active )
           )
    AND    (
              ( gd_base_date       BETWEEN  rol.res_rl_start_date  -- パラメータ.基準年月日（リソース役割）
                                   AND      NVL(rol.res_rl_end_date, gd_base_date) )
            OR
              ( gd_base_date                < rol.res_rl_start_date )
            OR
              ( rol.res_rl_start_date       IS NULL )
           )
    ORDER BY
            r.source_number          -- 従業員番号
           ,rol.res_rl_start_date    -- グループメンバ役割開始日
    ;
--
  --取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF resorce_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code  IN  VARCHAR2,     -- 1.拠点コード
    iv_base_date  IN  VARCHAR2,     -- 2.基準年月日
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
    lv_msg_base_code        VARCHAR2(1000);  -- 拠点コード出力用
    lv_msg_base_date        VARCHAR2(1000);  -- 基準年月日出力用
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
    --==================================================
    -- 入力パラメータ格納
    --==================================================
    gt_base_code := iv_base_code;
    gd_base_date := TO_DATE(iv_base_date ,cv_fmt_yyyymmdd);
--
    -- 拠点コード
    lv_msg_base_code   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                          , iv_name         => cv_msg_cso_00130              -- メッセージコード
                          , iv_token_name1  => cv_tkn_entry                  -- トークンコード1
                          , iv_token_value1 => iv_base_code                  -- トークン値1
                          );
    -- 基準年月日
    lv_msg_base_date   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                          , iv_name         => cv_msg_cso_00129              -- メッセージコード
                          , iv_token_name1  => cv_tkn_entry                  -- トークンコード1
                          , iv_token_value1 => iv_base_date                  -- トークン値1
                          );
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''               || CHR(10) ||
                 lv_msg_base_code || CHR(10) ||   -- 拠点コード
                 lv_msg_base_date || CHR(10)      -- 基準年月日
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
   * Procedure Name   : get_resource_data
   * Description      : 営業員リソース情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_resource_data(
    ov_errbuf                       OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_resource_data'; -- プログラム名
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
    --対象データ取得
    OPEN  resorce_data_cur;
    FETCH resorce_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE resorce_data_cur;
--
    --処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    IF ( gn_target_cnt = 0 ) THEN
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
  END get_resource_data;
--
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSVファイル出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    lv_line_data            VARCHAR2(5000);         -- OUTPUTデータ編集用
    lv_out_process_time     VARCHAR2(10);           -- 編集後の処理時刻
    lv_csv_header           VARCHAR2(5000);         -- CSVヘッダ出力用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
    -- *** ローカル・テーブル ***
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------
    --CSVヘッダ出力
    ----------------------
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso
                    ,iv_name         => cv_msg_cso_00656
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
    ----------------------
    --データ出力
    ----------------------
    --データを取得
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --初期化
      lv_line_data := NULL;
      --データを編集
      lv_line_data :=                cv_dqu || gt_out_file_tab(i).resource_id     || cv_dqu  -- リソースID
                      || cv_comma || cv_dqu || gt_out_file_tab(i).source_number   || cv_dqu  -- 従業員番号
                      || cv_comma || cv_dqu || gt_out_file_tab(i).source_name     || cv_dqu  -- 従業員名称
                      || cv_comma || cv_dqu || gt_out_file_tab(i).emp_form        || cv_dqu  -- 営業形態
                      || cv_comma || cv_dqu || gt_out_file_tab(i).renraku         || cv_dqu  -- 連絡先
                      || cv_comma || cv_dqu || gt_out_file_tab(i).vd_toitu        || cv_dqu  -- VD統一キーNO
                      || cv_comma || cv_dqu || gt_out_file_tab(i).emp_dash        || cv_dqu  -- 営業ダッシュボード使用可能フラグ
                      || cv_comma || cv_dqu || gt_out_file_tab(i).base_code       || cv_dqu  -- 拠点コード
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_name      || cv_dqu  -- グループ名称（拠点名）
                      || cv_comma || cv_dqu || gt_out_file_tab(i).rol_name        || cv_dqu  -- グループ役割名称
                      || cv_comma || cv_dqu || gt_out_file_tab(i).rol_start_date  || cv_dqu  -- グループメンバ役割開始日
                      || cv_comma || cv_dqu || gt_out_file_tab(i).rol_end_date    || cv_dqu  -- グループメンバ役割終了日
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_leader    || cv_dqu  -- グループ長区分
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_num       || cv_dqu  -- グループ番号
                      || cv_comma || cv_dqu || gt_out_file_tab(i).group_order     || cv_dqu  -- グループ順位
                      ;
      --データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code  IN  VARCHAR2,     -- 1.拠点コード
    iv_base_date  IN  VARCHAR2,     -- 2.基準年月日
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
      iv_base_code,      -- 1.拠点コード
      iv_base_date,      -- 2.基準年月日
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 営業員リソース情報取得(A-2)
    -- ===============================
    get_resource_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告処理
      RAISE global_warn_expt;
    END IF;
    -- ===============================
    -- CSVファイル出力(A-3)
    -- ===============================
    output_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    --データなし警告
    WHEN global_warn_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := ov_errmsg;
      ov_retcode := lv_retcode;
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_base_code  IN  VARCHAR2,      -- 1.拠点コード
    iv_base_date  IN  VARCHAR2       -- 2.基準年月日
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
    cv_appl_name_xxccp CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
--
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
       iv_base_code   -- 拠点コード
      ,iv_base_date   -- 基準年月日
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- 終了処理(A-6)
    -- ===============================
    --ステータス判定
    IF (lv_retcode = cv_status_warn) THEN
      --CSVファイル出力0件エラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00224
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    ELSIF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;  --対象件数
      gn_normal_cnt := 0;  --成功件数
      gn_error_cnt  := 1;  --エラー件数
      --
      --エラー出力
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
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
                     iv_application  => cv_appl_name_xxccp
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
END XXCSO005A02C;
/