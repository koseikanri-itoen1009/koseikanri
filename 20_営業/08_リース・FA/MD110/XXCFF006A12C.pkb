CREATE OR REPLACE PACKAGE BODY XXCFF006A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF006A12C(body)
 * Description      : リース契約情報連携
 * MD.050           : リース契約情報連携 MD050_CFF_006_A12
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-2．入力パラメータ値ログ出力処理
 *  get_profile_value      A-3．プロファイル取得
 *  chk_object_code        A-5．パラメータ範囲指定チェック処理
 *  get_lease_data         A-6. リース契約情報の取得
 *  put_lease_data         A-7．リース契約情報データCSV作成処理
 *  put_lease_data         A-8．リース契約明細更新処理
 *  submain                メイン処理プロシージャ
 *  main                   リース契約情報CSVファイル作成
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   SCS奥河          main新規作成
 *  2009/03/04    1.1   SCS松中          [障害CFF_069] 現契約リース料(税抜)不正出力不具合対応
 *  2009/05/21    1.2   SCS礒崎          [障害T1_1054] 不要なリース契約情報を作成してしまう。
 *  2009/05/28    1.3   SCS礒崎          [障害T1_1224] 連携機能がエラーの際にCSVファイルが削除される。
 *  2009/07/03    1.4   SCS萱原          [障害00000136]対象件数が0件の場合、CSV取込時にエラーとなる
 *  2009/08/28    1.5   SCS渡辺          [統合テスト障害0001059(PT対応)]
 *  2016/01/26    1.6   SCSK山下         E_本稼動_13456対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロック(ビジー)エラー
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFF006A12C';            -- パッケージ名
  cv_appl_short_name    CONSTANT VARCHAR2(100) := 'XXCFF';                   -- アプリケーション短縮名
  cv_log                CONSTANT VARCHAR2(100) := 'LOG';                     -- コンカレントログ出力先
  cv_which              CONSTANT VARCHAR2(100) := 'OUTPUT';                  -- コンカレントログ出力先
  -- メッセージ番号
  cv_msg_xxcff00003     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00003';         --FROM ≦ TO となるように指定してください。
  cv_msg_xxcff00007     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007';         --ロックエラー
  cv_msg_xxcff00062     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00062';         --対象データ無し
  cv_msg_xxcff00020     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020';         --プロファイル取得エラーメッセージ
  cv_msg_xxcff00168     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00168';         --ファイル名 : FILE_NAME
  cv_msg_xxcff00169     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00169';         --ファイル名か格納場所が無効です
  cv_msg_xxcff00170     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00170';         --ファイルをオープンできないメッセージ
  cv_msg_xxcff00171     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00171';         --ファイルに書込みできないメッセー
  cv_msg_xxcff00172     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00172';         --ファイルが存在しているメッセージ
  cv_msg_xxcff50030     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50030';         --リース契約明細テーブル
  --プロファイル
  cv_file_name_enter    CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_NAME_ENTER';   --XXCFF: リース契約情報ファイル名称
  cv_file_dir_enter     CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_DIR_ENTER';    --XXCFF: リース契約情報ファイル格納パス
-- E_本稼動_13456 2016/01/26 DEL START
--  cv_update_charge_code CONSTANT VARCHAR2(35) := 'XXCFF1_UPDATE_CHARGE_CODE';--XXCFF: 更新担当者コード
--  cv_update_post_code   CONSTANT VARCHAR2(35) := 'XXCFF1_UPDATE_POST_CODE';  --XXCFF: 担当部署コード
--  cv_update_program_id  CONSTANT VARCHAR2(35) := 'XXCFF1_UPDATE_PROGRAM_ID'; --XXCFF: 更新プログラムID
-- E_本稼動_13456 2016/01/26 DEL END
  -- トークン
  cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_prof           CONSTANT VARCHAR2(15) := 'PROF_NAME';                -- プロファイル名
  cv_tkn_file           CONSTANT VARCHAR2(15) := 'FILE_NAME';                -- ファイル名
  cv_token_from         CONSTANT VARCHAR2(15) := 'FROM';
  cv_token_to           CONSTANT VARCHAR2(15) := 'TO';  
  cv_object_code_f      CONSTANT VARCHAR2(37) := xxccp_common_pkg.get_msg(cv_appl_short_name,'APP-XXCFF1-50139');--物件コードFrom;
  cv_object_code_t      CONSTANT VARCHAR2(37) := xxccp_common_pkg.get_msg(cv_appl_short_name,'APP-XXCFF1-50140');--物件コードTo;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_name_enter    VARCHAR2(100) ;   --XXCFF: リース契約情報ファイル名称
  gn_file_dir_enter     VARCHAR2(500) ;   --XXCFF: リース契約情報ファイル格納パス
-- E_本稼動_13456 2016/01/26 DEL START
--  gn_update_charge_code VARCHAR2(30)  ;   --XXCFF: リース更新担当者コード
--  gn_update_post_code   VARCHAR2(30)  ;   --XXCFF: リース担当部署コード
--  gn_update_program_id  VARCHAR2(30)  ;   --XXCFF: リース更新プログラムID
-- E_本稼動_13456 2016/01/26 DEL END
  gd_sysdateb           DATE;             -- システム日付
  --
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    CURSOR get_lease_cur(i_object_code_from IN VARCHAR2,i_object_code_to IN VARCHAR2)
    IS
    SELECT
-- 0001059 2009/08/31 ADD START --
             /*+
               LEADING(XOH XCL1 XCH1 XCL0)
               INDEX(XOH  XXCFF_OBJECT_HEADERS_N03)
               INDEX(XCL1 XXCFF_CONTRACT_LINES_N03)
               INDEX(XCH1 XXCFF_CONTRACT_HEADERS_PK)
             */
-- 0001059 2009/08/31 ADD END --
             REPLACE(xoh.object_code,'-','')    AS object_code       --物件コード
            ,xch1.lease_company                 AS lease_company     --リース契約(現)リース会社
            ,xch1.lease_start_date              AS lease_start_date  --リース契約(現)リース開始日
            ,DECODE(xch1.lease_type,2,xcl1.gross_charge,1,xcl1.second_charge ) AS charge
            ,xcl0.contract_number               AS contract_number0  --契約番号(原)
            ,xcl0.contract_line_num             AS contract_line_num0--契約枝番(原)
-- E_本稼動_13456 2016/01/26 DEL START
--            ,xch1.contract_date                 AS contract_date     --契約日
-- E_本稼動_13456 2016/01/26 DEL END
            ,xch1.contract_number               AS contract_number1  --契約番号(現)
            ,xcl1.contract_line_num             AS contract_line_num1--契約枝番(現)
-- E_本稼動_13456 2016/01/26 DEL START
--            ,xcl1.vd_if_date                    AS vd_if_date        --リース契約情報連携日時
-- E_本稼動_13456 2016/01/26 DEL END
            ,xcl1.contract_line_id              AS contract_line_id  --契約明細内部id
-- E_本稼動_13456 2016/01/26 ADD START
            ,xch1.lease_type                    AS lease_type            --リース区分
            ,xcl1.estimated_cash_price          AS estimated_cash_price  --見積現金購入価額
            ,xcl0.lease_start_date              AS lease_start_date0     --リース契約(原)リース開始日
-- E_本稼動_13456 2016/01/26 ADD END
    FROM     xxcff_object_headers   xoh                              --リース物件
            ,xxcff_contract_headers xch1                             --リース契約リース契約(現)
            ,xxcff_contract_lines   xcl1                             --リース契約明細リース契約(現)
-- T1_1054 2009/05/21 ADD START --
            ,csi_item_instances     cii                              --インストールベースマスタ
-- T1_1054 2009/05/21 ADD END   --
            ,(
             SELECT
-- 0001059 2009/08/31 ADD START --
                     /*+
                       LEADING(XCH)
                       INDEX(XCH XXCFF_CONTRACT_HEADERS_N06)
                       INDEX(XCL XXCFF_CONTRACT_LINES_U01)
                     */
-- 0001059 2009/08/31 ADD END --
                     xch.contract_header_id AS contract_header_id
                    ,xcl.object_header_id   AS object_header_id
                    ,xch.contract_number    AS contract_number
                    ,xcl.contract_line_num  AS contract_line_num
-- E_本稼動_13456 2016/01/26 ADD START
                    ,xch.lease_start_date   AS lease_start_date
-- E_本稼動_13456 2016/01/26 ADD END
             FROM   xxcff_contract_headers  xch
                    ,xxcff_contract_lines   xcl                             --リース契約明細リース契約(原)
             WHERE  xch.contract_header_id = xcl.contract_header_id
-- 0001059 2009/08/31 ADD START --
             AND    xch.lease_type         =  1
-- 0001059 2009/08/31 ADD END --
             AND    xch.re_lease_times     =  0
             ) xcl0                                                  --リース契約リース契約(原)
    WHERE    xch1.contract_header_id = xcl1.contract_header_id
    AND      xoh.object_header_id    = xcl0.object_header_id(+)
    AND      xoh.object_header_id    = xcl1.object_header_id
    AND      xoh.re_lease_times      = xch1.re_lease_times
    AND      xoh.lease_class      IN (SELECT lease_class_code
                                      FROM   xxcff_lease_class_v
                                      WHERE  vdsh_flag = 'Y')
    AND      xcl1.contract_status IN ('202','203')
    AND      (xcl1.last_update_date > xcl1.vd_if_date OR xcl1.vd_if_date IS NULL)
    AND      (i_object_code_from IS NULL OR xoh.object_code >= i_object_code_from)
    AND      (i_object_code_to   IS NULL OR xoh.object_code <= i_object_code_to  )
-- T1_1054 2009/05/21 ADD START --
    AND      xoh.object_code     =  cii.external_reference
    AND      (cii.attribute5  IS NULL OR cii.attribute5  = 'N')
-- T1_1054 2009/05/21 ADD END   --
    ORDER BY  xoh.object_code
    ;
    TYPE g_lease_ttype IS TABLE OF get_lease_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_lease_data      g_lease_ttype;
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
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
    lv_errbuf     VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);       -- リターン・コード
    lv_errmsg     VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
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
    xxcff_common1_pkg.put_log_param
    (
     iv_which    => cv_which     -- 出力区分
    ,ov_retcode  => lv_retcode   --リターンコード
    ,ov_errbuf   => lv_errbuf    --エラーメッセージ
    ,ov_errmsg   => lv_errmsg    --ユーザー・エラーメッセージ
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
    xxcff_common1_pkg.put_log_param
    (
     iv_which    => cv_log       -- 出力区分
    ,ov_retcode  => lv_retcode   --リターンコード
    ,ov_errbuf   => lv_errbuf    --エラーメッセージ
    ,ov_errmsg   => lv_errmsg    --ユーザー・エラーメッセージ
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;

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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : A-3. プロファイル取得処理
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
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
    -- =====================================================
    -- プロファイルから XXCFF: リース契約情報データファイル名取得
    -- =====================================================
    gn_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    -- 取得エラー時
    IF (gn_file_name_enter IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- プロファイル取得エラー
      ,cv_tkn_prof         -- トークン'PROF_NAME'
      ,cv_file_name_enter  -- ファイル名
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================================
    -- プロファイルから XXCFF: リース契約情報データファイル格納パス名取得
    -- =====================================================
    gn_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    -- 取得エラー時
    IF (gn_file_dir_enter IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- プロファイル取得エラー
      ,cv_tkn_prof         -- トークン'PROF_NAME'
      ,cv_file_dir_enter   -- パス名
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- E_本稼動_13456 2016/01/26 DEL START
--    -- =====================================================
--    -- プロファイルから XXCFF: 更新担当者コード取得
--    -- =====================================================
--    gn_update_charge_code := FND_PROFILE.VALUE(cv_update_charge_code);
--    -- 取得エラー時
--    IF (gn_update_charge_code IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
--      (
--       cv_appl_short_name    -- 'XXCFF'
--      ,cv_msg_xxcff00020     -- プロファイル取得エラー
--      ,cv_tkn_prof           -- トークン'PROF_NAME'
--      ,cv_update_charge_code -- 更新担当者コード
--      )
--      ,1
--      ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    --
--    -- =====================================================
--    -- プロファイルから XXCFF: 担当部署コード取得
--    -- =====================================================
--    gn_update_post_code := FND_PROFILE.VALUE(cv_update_post_code);
--    -- 取得エラー時
--    IF (gn_update_post_code IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
--      (
--       cv_appl_short_name  -- 'XXCFF'
--      ,cv_msg_xxcff00020   -- プロファイル取得エラー
--      ,cv_tkn_prof         -- トークン'PROF_NAME'
--      ,cv_update_post_code -- 担当部署コード
--      )
--      ,1
--      ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    --
--    -- =====================================================
--    -- プロファイルから XXCFF: 更新プログラムID取得
--    -- =====================================================
--    gn_update_program_id := FND_PROFILE.VALUE(cv_update_program_id);
--    -- 取得エラー時
--    IF (gn_update_program_id IS NULL) THEN
--      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
--      (
--       cv_appl_short_name   -- 'XXCFF'
--      ,cv_msg_xxcff00020    -- プロファイル取得エラー
--      ,cv_tkn_prof          -- トークン'PROF_NAME'
--      ,cv_update_program_id -- 更新プログラムID
--      )
--      ,1
--      ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- E_本稼動_13456 2016/01/26 DEL END
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
  END get_profile_value;
  /**********************************************************************************
   * Procedure Name   : chk_object_code
   * Description      : A-5．パラメータ範囲指定チェック処理 
   ***********************************************************************************/
  PROCEDURE chk_object_code(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2,     --   ユーザー・エラー・メッセージ --# 固定 #
    iv_object_code_from     IN  VARCHAR2,     -- 1.物件コード(FROM)
    iv_object_code_to       IN  VARCHAR2      -- 2.物件コード(TO)
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object_code'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
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
    IF   iv_object_code_from IS NOT NULL
    AND  iv_object_code_to   IS NOT NULL THEN
      IF iv_object_code_from > iv_object_code_to THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
        (
        cv_appl_short_name,        -- 'XXCFF'
        cv_msg_xxcff00003,         -- 逆転エラー
        cv_token_from,             -- トークン'FROM'
        cv_object_code_f,          -- 物件コードFrom
        cv_token_to,               -- トークン'TO'
        cv_object_code_t           -- 物件コードTo
        )
        ,1
        ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
  END chk_object_code;
  /**********************************************************************************
   * Procedure Name   : get_lease_data
   * Description      : A-6. リース契約情報の取得
   ***********************************************************************************/
  PROCEDURE get_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2,     --   ユーザー・エラー・メッセージ --# 固定 #
    iv_object_code_from     IN  VARCHAR2,     -- 1.物件コード(FROM)
    iv_object_code_to       IN  VARCHAR2      -- 2.物件コード(TO)
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_data'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
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
    OPEN get_lease_cur(iv_object_code_from,iv_object_code_to);
    FETCH get_lease_cur BULK COLLECT INTO gt_lease_data;
    gn_target_cnt := gt_lease_data.COUNT;
    CLOSE get_lease_cur;
    --
  EXCEPTION
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
  END get_lease_data;
  /**********************************************************************************
   * Procedure Name   : put_lease_data
   * Description      : A-7．リース契約情報データCSV作成処理
   ***********************************************************************************/
  PROCEDURE put_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'put_lease_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf           VARCHAR2(5000);                   -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);                      -- リターン・コード
    lv_errmsg           VARCHAR2(5000);                   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';     -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';     -- 単語囲み文字
    cv_z                CONSTANT VARCHAR2(2)  := '00';    -- 固定値
-- E_本稼動_13456 2016/01/26 ADD START
    cv_minus            CONSTANT VARCHAR2(1)  := '-';     -- 固定値
    cv_1                CONSTANT VARCHAR2(1)  := '1';     -- 固定値
    cv_20               CONSTANT VARCHAR2(2)  := '20';    -- 固定値
-- E_本稼動_13456 2016/01/26 ADD END
    cv_null             CONSTANT VARCHAR2(2)  := NULL;    -- 固定値
    -- *** ローカル変数 ***
    ln_target_cnt       NUMBER := 0;                      -- 対象件数
    ln_loop_cnt         NUMBER;                           -- ループカウンタ
    in_contract_line_id NUMBER;
    in_charge           NUMBER;
-- E_本稼動_13456 2016/01/26 ADD START
    ln_cash_price       NUMBER;                           -- 本体価格
    lv_lease_no         VARCHAR2(20);                     -- リースNo
-- E_本稼動_13456 2016/01/26 MOD END
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;              -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32000) ;                 -- 出力１行分文字列変数
    lb_fexists          BOOLEAN;                          -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                           -- ファイルの長さ
    ln_block_size       NUMBER;                           -- ファイルシステムのブロックサイズ
    -- *** ローカル・カーソル ***
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
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
    (
    gn_file_dir_enter,
    gn_file_name_enter,
    cv_open_mode_w
    );
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    IF gn_target_cnt <> 0 THEN
        <<out_loop>>
        FOR ln_loop_cnt IN gt_lease_data.FIRST..gt_lease_data.LAST LOOP
          in_charge := NULL;
          IF         LENGTH(gt_lease_data(ln_loop_cnt).charge) <= 7 THEN
            in_charge := gt_lease_data(ln_loop_cnt).charge;
          ELSE
            in_charge := SUBSTRB(gt_lease_data(ln_loop_cnt).charge ,-7 );
          END IF;
-- E_本稼動_13456 2016/01/26 ADD START
          -- 本体価格
          ln_cash_price := NVL( gt_lease_data(ln_loop_cnt).estimated_cash_price , 0 );
          IF ( LENGTH(ln_cash_price) > 7 ) THEN
            ln_cash_price := SUBSTRB( ln_cash_price , -7 );
          END IF;
          -- リースNo
          lv_lease_no := NULL;
          IF ( gt_lease_data(ln_loop_cnt).lease_type = cv_1 ) THEN
            -- 原契約の場合
            lv_lease_no := gt_lease_data(ln_loop_cnt).contract_number0 || cv_minus || gt_lease_data(ln_loop_cnt).contract_line_num0;
          ELSE
            -- 再リースの場合
            lv_lease_no := gt_lease_data(ln_loop_cnt).contract_number1 || cv_minus || gt_lease_data(ln_loop_cnt).contract_line_num1;
          END IF;
-- E_本稼動_13456 2016/01/26 ADD END
-- E_本稼動_13456 2016/01/26 MOD START
--          --
--          -- 出力文字列作成
--          lv_csv_text := 
--             cv_enclosed ||  gt_lease_data(ln_loop_cnt).object_code       || cv_enclosed || cv_delimiter  -- 物件コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 機種
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 機番
--          || cv_null                                                                     || cv_delimiter  -- 機器区分
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- メーカ
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 年式
--          || cv_null                                                                     || cv_delimiter  -- セレ数
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 特殊機１
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 特殊機２
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 特殊機３
--          || cv_null                                                                     || cv_delimiter  -- 初回設定日
--          || cv_null                                                                     || cv_delimiter  -- カウンターNo
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 地区コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 拠点（部門）コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 作業会社コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 事業所コード
--          || cv_null                                                                     || cv_delimiter  -- 最終作業伝票No
--          || cv_null                                                                     || cv_delimiter  -- 最終作業区分
--          || cv_null                                                                     || cv_delimiter  -- 最終作業進捗
--          || cv_null                                                                     || cv_delimiter  -- 最終作業完了予定日
--          || cv_null                                                                     || cv_delimiter  -- 最終作業完了日
--          || cv_null                                                                     || cv_delimiter  -- 最終整備内容
--          || cv_null                                                                     || cv_delimiter  -- 最終設置伝票No
--          || cv_null                                                                     || cv_delimiter  -- 最終設置区分
--          || cv_null                                                                     || cv_delimiter  -- 最終設置予定日
--          || cv_null                                                                     || cv_delimiter  -- 最終設置進捗
--          || cv_null                                                                     || cv_delimiter  -- 機器状態1
--          || cv_null                                                                     || cv_delimiter  -- 機器状態2
--          || cv_null                                                                     || cv_delimiter  -- 機器状態3
--          || cv_null                                                                     || cv_delimiter  -- 入庫日
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 引揚会社コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 引揚事業所コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先名
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先担当者名
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先TEL1
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先TEL2
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先TEL3
--          || cv_null                                                                     || cv_delimiter  -- 設置先郵便番号
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先住所1
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先住所2
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先住所3
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先住所4
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 設置先住所5
--          || cv_null                                                                     || cv_delimiter  -- 廃棄決裁日
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 転売廃棄業者
--          || cv_null                                                                     || cv_delimiter  -- 転売廃棄伝票No
--          || cv_enclosed || cv_z||gt_lease_data(ln_loop_cnt).lease_company||cv_enclosed  || cv_delimiter  -- 所有者
--          ||        TO_CHAR(gt_lease_data(ln_loop_cnt).lease_start_date,'YYYYMMDD')      || cv_delimiter  -- リース開始日
--          ||                in_charge                                                    || cv_delimiter  -- リース料
--          || cv_enclosed || gt_lease_data(ln_loop_cnt).contract_number0   || cv_enclosed || cv_delimiter  -- 原契約番号
--          ||                gt_lease_data(ln_loop_cnt).contract_line_num0 ||                cv_delimiter  -- 原契約番号枝番
--          ||        TO_CHAR(gt_lease_data(ln_loop_cnt).contract_date   ,'YYYYMMDD')      || cv_delimiter  -- 現契約日
--          || cv_enclosed || gt_lease_data(ln_loop_cnt).contract_number1   || cv_enclosed || cv_delimiter  -- 現契約番号
--          ||                gt_lease_data(ln_loop_cnt).contract_line_num1                || cv_delimiter  -- 現契約番号枝番
--          || cv_null                                                                     || cv_delimiter  -- 転売廃業状況フラグ
--          || cv_null                                                                     || cv_delimiter  -- 転売完了区分
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 削除フラグ
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 作成担当者コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 作成部署コード
--          || cv_enclosed || cv_null                                       || cv_enclosed || cv_delimiter  -- 作成プログラムID
--          || cv_enclosed || gn_update_charge_code                         || cv_enclosed || cv_delimiter  -- 更新担当者コード
--          || cv_enclosed || gn_update_post_code                           || cv_enclosed || cv_delimiter  -- 更新部署コード
--          || cv_enclosed || gn_update_program_id                          || cv_enclosed || cv_delimiter  -- 更新プログラムID
--          || cv_null                                                                     || cv_delimiter  -- 作成日時分秒
--          || cv_null                                                                                      -- 更新日時分秒
--          ;
          --
          -- 出力文字列作成
          lv_csv_text :=
             cv_enclosed || gt_lease_data(ln_loop_cnt).object_code                         || cv_enclosed || cv_delimiter  -- 自販機CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 機種
          || cv_enclosed || gt_lease_data(ln_loop_cnt).lease_company                       || cv_enclosed || cv_delimiter  -- ﾘｰｽ会社区分
          || cv_enclosed || cv_z                                                           || cv_enclosed || cv_delimiter  -- ﾘｰｽ形態区分
          || cv_enclosed || cv_20                                                          || cv_enclosed || cv_delimiter  -- ﾘｰｽ方式区分
          || cv_enclosed || TO_CHAR(gt_lease_data(ln_loop_cnt).lease_start_date0,'YYYYMM') || cv_enclosed || cv_delimiter  -- ﾘｰｽ開始月
          || cv_enclosed || lv_lease_no                                                    || cv_enclosed || cv_delimiter  -- ﾘｰｽNO
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 受付番号
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 受付番号枝番
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 会社CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 支店CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 営業所CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 大業種CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 小業種CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 室内外区分
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ﾒｰｶｰ
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 機番
          ||                ln_cash_price                                                                 || cv_delimiter  -- 本体価格
          || cv_enclosed || TO_CHAR(gt_lease_data(ln_loop_cnt).lease_start_date,'YYYYMM')  || cv_enclosed || cv_delimiter  -- 新規契約年月
          ||                cv_null                                                                       || cv_delimiter  -- ﾘｰｽ料率
          ||                in_charge                                                                     || cv_delimiter  -- 月額ﾘｰｽ料
          ||                cv_null                                                                       || cv_delimiter  -- 再契約ﾘｰｽ料
          ||                cv_null                                                                       || cv_delimiter  -- 月額リース料金（変更前）
          ||                cv_null                                                                       || cv_delimiter  -- ﾘｰｽ残高
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 再契約年月
          ||                cv_null                                                                       || cv_delimiter  -- 再契約回数
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 再ﾘｰｽ開始月
          ||                cv_null                                                                       || cv_delimiter  -- 前年保険限度額
          ||                cv_null                                                                       || cv_delimiter  -- 保険限度額
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 前年保険決定日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 保険決定日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 初回設置日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 初回支店CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 初回営業所CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 中途解約フラグ
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 中途解約日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 確定日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先名（社名）
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先ｶﾅ
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先TEL
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先都道府県CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先市区郡CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先住所
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 廃棄フラグ
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 仕入先
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 卸CD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- デポCD
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 契約状態区分
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 除却フラグ
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先郵便番号
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先住所１
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先住所２
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 設置先住所３
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- リース代理店会社区分
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- 端数計算方法_帳合料
          ||                cv_null                                                                       || cv_delimiter  -- 帳合料率
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ﾚｺｰﾄﾞ作成日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ﾚｺｰﾄﾞ作成PG
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ﾚｺｰﾄﾞ作成者
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ﾚｺｰﾄﾞ更新日
          || cv_enclosed || cv_null                                                        || cv_enclosed || cv_delimiter  -- ﾚｺｰﾄﾞ更新PG
          || cv_enclosed || cv_null                                                        || cv_enclosed                  -- ﾚｺｰﾄﾞ更新者
          ;
-- E_本稼動_13456 2016/01/26 MOD END
          -- ====================================================
          -- ファイル書き込み
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
          -- ====================================================
          -- 処理件数カウントアップ
          -- ====================================================
          ln_target_cnt := ln_target_cnt + 1 ;
          -- ====================================================
          -- A-8．リース契約明細更新処理
          -- ====================================================
          SELECT   contract_line_id AS contract_line_id
          INTO     in_contract_line_id
          FROM     xxcff_contract_lines
          WHERE    contract_line_id = gt_lease_data(ln_loop_cnt).contract_line_id
          FOR UPDATE NOWAIT
          ;
          --
          UPDATE  xxcff_contract_lines
          SET     VD_IF_DATE             = gd_sysdateb
          WHERE   contract_line_id       = gt_lease_data(ln_loop_cnt).contract_line_id
          ;
          --
        END LOOP out_loop;
        --
    ELSE
        -- ====================================================
        -- ファイル書き込み
        -- ====================================================
-- 00000136 2009/07/03 DEL START 
--        UTL_FILE.PUT_LINE( lf_file_hand, cv_null ) ;
-- 00000136 2009/07/03 DEL END
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
        (
        cv_appl_short_name,    -- 'XXCFF'
        cv_msg_xxcff00062      -- 対象データが0件エラー
        )
        ,1
        ,5000);
        lv_errbuf  := lv_errmsg;
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
        --
    END IF;
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
    --
    gn_normal_cnt := ln_target_cnt;
    --
  EXCEPTION
    -- ====================================================
    -- *** ロック(ビジー)エラー
    -- ====================================================
    WHEN lock_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--      UTL_FILE.FREMOVE  (  gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
      (
       cv_appl_short_name   -- 'XXCFF'
      ,cv_msg_xxcff00007    -- テーブルロックエラー
      ,cv_tkn_table         -- トークン'TABLE'
      ,cv_msg_xxcff50030    -- リース契約明細
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** ファイルの場所が無効です ***
    -- ====================================================
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,    -- 'XXCFF'
      cv_msg_xxcff00169      -- ファイルの場所が無効
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    -- ====================================================
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,    -- 'XXCFF'
      cv_msg_xxcff00170      -- ファイルをオープンできない
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** 書込み操作中にオペレーティング・システムのエラーが発生しました ***
    -- ====================================================
    WHEN UTL_FILE.WRITE_ERROR THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--      UTL_FILE.FREMOVE  (  gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,   -- 'XXCFF'
      cv_msg_xxcff00171     -- ファイルに書込みできない
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
  END put_lease_data;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2,     --   ユーザー・エラー・メッセージ --# 固定 #
    iv_object_code_from     IN  VARCHAR2,     --   1.物件コード(FROM)
    iv_object_code_to       IN  VARCHAR2      --   2.物件コード(TO)
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
    -- *** ローカル変数 ***
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =====================================================
    --  A-1．初期処理
    -- =====================================================
    gd_sysdateb := SYSDATE;
    -- =====================================================
    --  A-2．入力パラメータ値ログ出力処理
    -- =====================================================
    init
    (
     lv_errbuf             -- エラー・メッセージ           --# 固定 #
    ,lv_retcode            -- リターン・コード             --# 固定 #
    ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-3．プロファイル取得
    -- =====================================================
    get_profile_value
    (
     lv_errbuf             -- エラー・メッセージ           --# 固定 #
    ,lv_retcode            -- リターン・コード             --# 固定 #
    ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-4．リース契約情報データファイル情報ログ処理
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
    (
     cv_appl_short_name     -- 'XXCFF'
    ,cv_msg_xxcff00168      -- ファイル名出力メッセージ
    ,cv_tkn_file            -- トークン'FILE_NAME'
    ,gn_file_name_enter     -- ファイル名
    )
    ,1
    ,5000);
    --
    FND_FILE.PUT_LINE
    (
     FND_FILE.OUTPUT
    ,lv_errmsg
    );
    --１行改行
    FND_FILE.PUT_LINE
    (
     which  => FND_FILE.OUTPUT
    ,buff   => '' 
    );
    --
    -- =====================================================
    --  A-5．パラメータ範囲指定チェック処理 
    -- =====================================================
    chk_object_code
    (
     lv_errbuf             -- エラー・メッセージ           --# 固定 #
    ,lv_retcode            -- リターン・コード             --# 固定 #
    ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    ,iv_object_code_from   -- 物件コード(FROM)
    ,iv_object_code_to     -- 物件コード(TO)
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- =====================================================
    --  A-6. リース契約情報の取得
    -- =====================================================
    get_lease_data
    (
     lv_errbuf             -- エラー・メッセージ           --# 固定 #
    ,lv_retcode            -- リターン・コード             --# 固定 #
    ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    ,iv_object_code_from   -- 物件コード(FROM)
    ,iv_object_code_to     -- 物件コード(TO)
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-7．リース契約情報データCSV作成処理
    -- =====================================================
    put_lease_data
    (
     lv_errbuf             -- エラー・メッセージ           --# 固定 #
    ,lv_retcode            -- リターン・コード             --# 固定 #
    ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- 正常件数の設定
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
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
    errbuf                OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_object_code_from   IN    VARCHAR2,        --   物件コード(FROM)
    iv_object_code_to     IN    VARCHAR2         --   物件コード(TO)
  )
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：XXCFF領域
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
    lv_errbuf          VARCHAR2(5000);                               -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                  -- リターン・コード
    lv_errmsg          VARCHAR2(5000);                               -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                -- メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header
    (
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
    submain
    (
     lv_errbuf             -- エラー・メッセージ           --# 固定 #
    ,lv_retcode            -- リターン・コード             --# 固定 #
    ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    ,iv_object_code_from   -- 1.物件コードFrom
    ,iv_object_code_to     -- 2.物件コードTo
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --エラー出力
    IF (lv_retcode IN( cv_status_error,cv_status_warn)) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
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
END XXCFF006A12C;
/