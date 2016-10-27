create or replace
PACKAGE BODY XXCFF009A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF009A15C(body)
 * Description      : リース管理情報連携
 * MD.050           : リース管理情報連携 MD050_CFF_009_A15
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-2．入力パラメータ値ログ出力処理
 *  get_profile_value      A-3．プロファイル取得
 *  get_lease_data         A-5. リース管理情報の取得
 *  get_lease_data         A-6. リース支払計画情報データ取得
 *  put_lease_data         A-7．リース管理情報データCSV作成処理
 *  put_lease_data         A-8．更新処理
 *  submain                メイン処理プロシージャ
 *  main                   リース管理情報CSVファイル作成
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   SCS奥河          main新規作成
 *  2009/03/17    1.1   SCS礒崎          [T1_0062]対応
 *                                       ①リース管理情報の出力で支払回数が72回以上の場合、
 *                                         出力しない制御がない。
 *                                       ②リース料、支払日の順番が逆になっている。
 *                                       ③リース種類の文字数は短縮名を設定する。
 *  2009/04/08    1.1   SCS大井          [T1_0354]対応
 *                                       ①連携CSVの出力時間のフォーマットを'YYYYMMDDHH24MISS'に変更
 *  2009/05/28    1.2   SCS礒崎          [障害T1_1224] 連携機能がエラーの際にCSVファイルが削除される。
 *  2009/07/03    1.3   SCS萱原          [障害00000136]対象件数が0件の場合、CSV取込時にエラーとなる
 *  2009/08/31    1.4   SCS渡辺          [統合テスト障害0001060(PT対応)]
 *  2016/10/04    1.5   SCSK 郭          E_本稼動_13658（自販機耐用年数変更対応）
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFF009A15C';            -- パッケージ名
  cv_appl_short_name    CONSTANT VARCHAR2(100) := 'XXCFF';                   -- アプリケーション短縮名
  cv_log                CONSTANT VARCHAR2(100) := 'LOG';                     -- コンカレントログ出力先
  cv_which              CONSTANT VARCHAR2(100) := 'OUTPUT';                  -- コンカレントログ出力先
  -- メッセージ番号
  cv_msg_xxcff00007     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007';         --ロックエラー
  cv_msg_xxcff00062     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00062';         --対象データ無し
  cv_msg_xxcff00020     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020';         --プロファイル取得エラーメッセージ
  cv_msg_xxcff00168     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00168';         --ファイル名出力メッセージ
  cv_msg_xxcff00169     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00169';         --ファイルの場所が無効メッセージ
  cv_msg_xxcff00170     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00170';         --ファイルをオープンできないメッセージ
  cv_msg_xxcff00171     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00171';         --ファイルに書込みできないメッセー
  cv_msg_xxcff50030     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50030';         --リース契約明細テーブル
  cv_msg_xxcff50014     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50014';         --リース物件テーブル
  --プロファイル
  cv_file_name_enter    CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_NAME_CONTROL'; --XXCFF:リース管理情報ファイル名称
  cv_file_dir_enter     CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_DIR_CONTROL';  --XXCFF:リース管理情報ファイル格納パス
  cv_file_com_code      CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CODE';      --XXCFF:リース会社コード
  -- トークン
  cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_prof           CONSTANT VARCHAR2(15) := 'PROF_NAME';                -- プロファイル名
  cv_tkn_file           CONSTANT VARCHAR2(15) := 'FILE_NAME';                -- ファイル名
-- 2016/10/04 Ver.1.5 Y.Koh ADD Start
  cv_match_flag_9       CONSTANT VARCHAR2(1)  := '9';                        -- 照合フラグ(対象外)
-- 2016/10/04 Ver.1.5 Y.Koh ADD END
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_name_enter    VARCHAR2(100) ;   --XXCFF:リース契約情報ファイル名称
  gn_file_dir_enter     VARCHAR2(500) ;   --XXCFF:リース契約情報ファイル格納パス
  gn_file_com_code      VARCHAR2(500) ;   --XXCFF:リース会社コード
  gd_sysdateb           DATE;             -- システム日付
  --
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    CURSOR get_lease_cur
    IS
    SELECT   
-- 0001060 2009/08/31 ADD START --
             /*+
               LEADING(XOH XCL XCH XPP)
               INDEX(XOH XXCFF_OBJECT_HEADERS_N03)
               INDEX(XCL XXCFF_CONTRACT_LINES_N03)
               INDEX(XCH XXCFF_CONTRACT_HEADERS_PK)
               INDEX(XPP XXCFF_PAY_PLANNING_PK)
             */
-- 0001060 2009/08/31 ADD END --
             xch.lease_company                           AS lease_company                     --02.リース会社
            ,xch.contract_number                         AS contract_number                   --03.契約番号
            ,TO_CHAR(xch.contract_date      ,'YYYYMMDD') AS contract_date                     --04.リース契約日
            ,xch.payment_frequency                       AS payment_frequency                 --05.支払回数
            ,TO_CHAR(xch.lease_start_date   ,'YYYYMMDD') AS lease_start_date                  --06.リース開始日
            ,TO_CHAR(xch.lease_end_date     ,'YYYYMMDD') AS lease_end_date                    --07.リース終了日
            ,TO_CHAR(xch.first_payment_date ,'YYYYMMDD') AS first_payment_date                --08.初回支払日
            ,TO_CHAR(xch.second_payment_date,'YYYYMMDD') AS second_payment_date               --09.2回目支払日
            ,xcl.contract_line_num                       AS contract_line_num                 --10.契約枝番
-- 0001060 2009/08/31 MOD START --
--            ,xcsv.contract_status_name                   AS contract_status_name              --11.契約ステータス名称
            ,xcl.contract_status                         AS contract_status
            ,(SELECT xcsv.contract_status_name
              FROM xxcff_contract_status_v xcsv
              WHERE xcl.contract_status = xcsv.contract_status_code)    AS contract_status_name
-- 0001060 2009/08/31 MOD END --
-- 0001060 2009/08/31 MOD START --
--            ,xltv.lease_type_name                        AS lease_type_name                   --12.リース区分名称
            ,xch.lease_type                              AS lease_type
            ,(SELECT xltv.lease_type_name
              FROM xxcff_lease_type_v      xltv
              WHERE xltv.lease_type_code = xch.lease_type)    AS lease_type_name
-- 0001060 2009/08/31 MOD END --
            ,xch.re_lease_times                          AS re_lease_times                    --13.再リース回数
            ,xcl.gross_total_charge                      AS gross_total_charge                --14.総額計_リース料
            ,xcl.second_charge                           AS second_charge                     --15.2回目以降月額リース料_リース料
            ,xcl.second_tax_charge                       AS second_tax_charge                 --16.2回目以降消費税額_リース料
            ,xcl.second_total_charge                     AS second_total_charge               --17.2回目以降計_リース料
          --,xlkv.lease_kind_name                        AS lease_kind_name                   --18.リース種類名称
-- 0001060 2009/08/31 MOD START --
--            ,xlkv.book_type_code_if                      AS lease_kind_name                   --18.リース種類名称
            ,xcl.lease_kind                              AS lease_kind
            ,(SELECT xlkv.book_type_code_if
              FROM xxcff_lease_kind_v      xlkv
              WHERE xlkv.lease_kind_code = xcl.lease_kind)    AS lease_kind_name
-- 0001060 2009/08/31 MOD END --
            ,xcl.original_cost                           AS original_cost                     --19.取得価額
-- 2016/10/04 Ver.1.5 Y.Koh MOD Start
--            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_debt,0)),0)         AS fin_debt          --20.ＦＩＮリース債務額
            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_debt,0) + NVL(xpp.debt_re,0)),0)
                                                                         AS fin_debt          --20.ＦＩＮリース債務額
--            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_interest_due,0)),0) AS fin_interest_due  --21.ＦＩＮリース支払利息
            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_interest_due,0) + NVL(xpp.interest_due_re,0)),0)
                                                                         AS fin_interest_due  --21.ＦＩＮリース支払利息
-- 2016/10/04 Ver.1.5 Y.Koh MOD End
            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_tax_debt,0)),0)     AS fin_tax_debt      --21.ＦＩＮリース支払利息
            ,xcl.calc_interested_rate                    AS calc_interested_rate              --23.計算利子率
            ,xoh.object_code                             AS object_code                       --24.物件コード
            ,xoh.quantity                                AS quantity                          --25.数量
            ,xoh.department_code                         AS department_code                   --26.管理部門コード
            ,TO_CHAR(xoh.cancellation_date ,'YYYYMMDD')  AS cancellation_date                 --27.中途解約日
            ,xoh.object_header_id             --28.物件内部id
            ,xcl.contract_line_id             --29.契約明細内部id
    FROM     xxcff_contract_headers  xch      --リース契約
            ,xxcff_contract_lines    xcl      --リース契約明細
            ,xxcff_object_headers    xoh      --リース物件
            ,xxcff_pay_planning      xpp      --リース支払計画
-- 0001060 2009/08/31 DEL START --
--            ,xxcff_contract_status_v xcsv     --契約ステータスビュー
--            ,xxcff_lease_type_v      xltv     --リース区分ビュー
--            ,xxcff_lease_kind_v      xlkv     --リース種類ビュー
-- 0001060 2009/08/31 DEL END --
    WHERE    xch.contract_header_id = xcl.contract_header_id
    AND      xcl.object_header_id   = xoh.object_header_id
    AND      xcl.contract_line_id   = xpp.contract_line_id(+)
-- 0001060 2009/08/31 MOD START --
--    AND      xch.lease_class        IN(SELECT lease_class_code
    AND      xoh.lease_class        IN(SELECT lease_class_code
-- 0001060 2009/08/31 MOD END --
                                       FROM   xxcff_lease_class_v
                                       WHERE  vdsh_flag = 'Y')
    AND      xoh.object_status      IN('102','104','107','108','110','111','112')
    AND    ((xoh.info_sys_if_date < xoh.last_update_date OR xoh.info_sys_if_date IS NULL) 
    OR      (xcl.info_sys_if_date < xcl.last_update_date OR xcl.info_sys_if_date IS NULL))
    AND      xch.re_lease_times        = xoh.re_lease_times
-- 0001060 2009/08/31 DEL START --
--    AND      xcsv.contract_status_code = xcl.contract_status
--    AND      xltv.lease_type_code      = xch.lease_type
--    AND      xlkv.lease_kind_code      = xcl.lease_kind
-- 0001060 2009/08/31 DEL END --
    GROUP BY 
             xch.lease_company          --02.リース会社
            ,xch.contract_number        --03.契約番号
            ,xch.contract_date          --04.リース契約日
            ,xch.payment_frequency      --05.支払回数
            ,xch.lease_start_date       --06.リース開始日
            ,xch.lease_end_date         --07.リース終了日
            ,xch.first_payment_date     --08.初回支払日
            ,xch.second_payment_date    --09.2回目支払日
            ,xcl.contract_line_num      --10.契約枝番
-- 0001060 2009/08/31 DEL START --
--            ,xcsv.contract_status_name  --11.契約ステータス名称
--            ,xltv.lease_type_name       --12.リース区分名称
-- 0001060 2009/08/31 DEL END --
            ,xch.re_lease_times         --13.再リース回数
            ,xcl.gross_total_charge     --14.総額計_リース料
            ,xcl.second_charge          --15.2回目以降月額リース料_リース料
            ,xcl.second_tax_charge      --16.2回目以降消費税額_リース料
            ,xcl.second_total_charge    --17.2回目以降計_リース料
         -- ,xlkv.lease_kind_name       --18.リース種類名称
-- 0001060 2009/08/31 DEL START --
--            ,xlkv.book_type_code_if     --18.リース種類名称
-- 0001060 2009/08/31 DEL END --
-- 0001060 2009/08/31 ADD START --
            ,xcl.contract_status
            ,xch.lease_type
-- 0001060 2009/08/31 ADD END --
            ,xcl.original_cost          --19.取得価額
            ,xcl.lease_kind
            ,xcl.calc_interested_rate   --23.計算利子率
            ,xoh.object_code            --24.物件コード
            ,xoh.quantity               --25.数量
            ,xoh.department_code        --26.管理部門コード
            ,xoh.cancellation_date      --27.中途解約日
            ,xoh.object_header_id       --28.物件内部id
            ,xcl.contract_line_id       --29.契約明細内部id
    ORDER BY
             xch.lease_company          --02.リース会社
            ,xch.contract_number        --03.契約番号
            ,xcl.contract_line_num      --10.契約枝番
    ;
    TYPE g_lease_ttype IS TABLE OF get_lease_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_lease_data      g_lease_ttype;
    --
    CURSOR get_payment_cur(i_contract_line_id IN VARCHAR2)
    IS
    SELECT   payment_frequency                             AS payment_frequency --支払回数
            ,TO_CHAR(payment_date ,'YYYYMMDD')             AS payment_date      --支払日
            ,NVL(lease_charge,0) + NVL(lease_tax_charge,0) AS lease_charge      --リース料＋リース料_消費税
    FROM     xxcff_pay_planning
    WHERE    contract_line_id  = i_contract_line_id
-- 2016/10/04 Ver.1.5 Y.Koh ADD Start
    AND      payment_match_flag != cv_match_flag_9
-- 2016/10/04 Ver.1.5 Y.Koh ADD END
    ORDER BY payment_frequency
    ;
    TYPE g_payment_ttype IS TABLE OF get_payment_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_payment_data      g_payment_ttype;
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
    -- プロファイルから XXCFF:リース管理情報データファイル名取得
    -- =====================================================
    gn_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
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
    -- プロファイルから XXCFF:リース管理情報データファイル格納パス名取得
    -- =====================================================
    gn_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
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
    -- =====================================================
    -- プロファイルから XXCFF:リース会社コード
    -- =====================================================
    gn_file_com_code := FND_PROFILE.VALUE(cv_file_com_code);
    IF (gn_file_com_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- プロファイル取得エラー
      ,cv_tkn_prof         -- トークン'PROF_NAME'
      ,cv_file_com_code    -- パス名
      )
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
  END get_profile_value;
  /**********************************************************************************
   * Procedure Name   : get_lease_data
   * Description      : A-6. リース契約情報の取得
   ***********************************************************************************/
  PROCEDURE get_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    OPEN  get_lease_cur;
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
    cv_null             CONSTANT VARCHAR2(2)  := NULL;    -- 固定値
    -- *** ローカル変数 ***
    ln_target_cnt       NUMBER := 0;                      -- 対象件数
    ln_loop_cnt         NUMBER;                           -- ループカウンタ
    ln_cnt              NUMBER;                           -- ループカウンタ
    in_contract_line_id NUMBER;
    in_object_header_id NUMBER;
    iv_table_name       VARCHAR2(20);
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;              -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32767) ;                 -- 出力１行分文字列変数
    lb_fexists          BOOLEAN;                          -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                           -- ファイルの長さ
    ln_block_size       NUMBER;                           -- ファイルシステムのブロックサイズ
    -- *** ローカル・カーソル ***
    gn_payment_cnt      NUMBER;
    ln_count            NUMBER;
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
    cv_open_mode_w,
    32767
    );
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    IF gn_target_cnt <> 0 THEN
        <<out_loop>>
        FOR ln_loop_cnt IN gt_lease_data.FIRST..gt_lease_data.LAST LOOP
          --
          -- 出力文字列作成
          lv_csv_text := 
             cv_enclosed ||  gn_file_com_code                               || cv_enclosed || cv_delimiter  -- 01.会社コード
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).lease_company       || cv_enclosed || cv_delimiter  -- 02.リース会社
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).contract_number     || cv_enclosed || cv_delimiter  -- 03.契約番号
          ||                 gt_lease_data(ln_loop_cnt).contract_date                      || cv_delimiter  -- 04.リース契約日
          ||                 gt_lease_data(ln_loop_cnt).payment_frequency                  || cv_delimiter  -- 05.支払回数
          ||                 gt_lease_data(ln_loop_cnt).lease_start_date                   || cv_delimiter  -- 06.リース開始日
          ||                 gt_lease_data(ln_loop_cnt).lease_end_date                     || cv_delimiter  -- 07.リース終了日
          ||                 gt_lease_data(ln_loop_cnt).first_payment_date                 || cv_delimiter  -- 08.初回支払日
          ||                 gt_lease_data(ln_loop_cnt).second_payment_date                || cv_delimiter  -- 09.2回目支払日
          ||                 gt_lease_data(ln_loop_cnt).contract_line_num                  || cv_delimiter  -- 10.契約枝番
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).contract_status_name|| cv_enclosed || cv_delimiter  -- 11.契約ステータス名称
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).lease_type_name     || cv_enclosed || cv_delimiter  -- 12.リース区分名称
          ||                 gt_lease_data(ln_loop_cnt).re_lease_times                     || cv_delimiter  -- 13.再リース回数
          ||                 gt_lease_data(ln_loop_cnt).gross_total_charge                 || cv_delimiter  -- 14.総額計_リース料
          ||                 gt_lease_data(ln_loop_cnt).second_charge                      || cv_delimiter  -- 15.2回目以降月額リース料_リース料
          ||                 gt_lease_data(ln_loop_cnt).second_tax_charge                  || cv_delimiter  -- 16.2回目以降消費税額_リース料
          ||                 gt_lease_data(ln_loop_cnt).second_total_charge                || cv_delimiter  -- 17.2回目以降計_リース料
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).lease_kind_name     || cv_enclosed || cv_delimiter  -- 18.リース種類名称
          ||                 gt_lease_data(ln_loop_cnt).original_cost                      || cv_delimiter  -- 19.取得価額
          ||                 gt_lease_data(ln_loop_cnt).fin_debt                           || cv_delimiter  -- 20.ＦＩＮリース債務額
          ||                 gt_lease_data(ln_loop_cnt).fin_interest_due                   || cv_delimiter  -- 21.ＦＩＮリース支払利息
          ||                 gt_lease_data(ln_loop_cnt).fin_tax_debt                       || cv_delimiter  -- 22.ＦＩＮリース債務額_消費税
          ||                 gt_lease_data(ln_loop_cnt).calc_interested_rate               || cv_delimiter  -- 23.計算利子率
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).object_code         || cv_enclosed || cv_delimiter  -- 24.物件コード
          ||                 gt_lease_data(ln_loop_cnt).quantity                           || cv_delimiter  -- 25.数量
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).department_code     || cv_enclosed || cv_delimiter  -- 26.管理部門コード
          ||                 gt_lease_data(ln_loop_cnt).cancellation_date                  || cv_delimiter  -- 27.中途解約日
          ;
          --支払計画抽出
          OPEN  get_payment_cur(gt_lease_data(ln_loop_cnt).contract_line_id);
          FETCH get_payment_cur BULK COLLECT INTO gt_payment_data;
                gn_payment_cnt := NVL(gt_payment_data.COUNT,0);
          CLOSE get_payment_cur;
          IF gn_payment_cnt = 0 THEN
              FOR ln_cnt IN 1..72 LOOP
                lv_csv_text       := lv_csv_text  ||  cv_delimiter;                                          -- リース料＋リース料_消費税
                lv_csv_text       := lv_csv_text  ||  cv_delimiter;                                          -- 支払日
              END LOOP;
          ELSE
              <<out_loop>>
              FOR ln_cnt IN gt_payment_data.FIRST..gt_payment_data.LAST LOOP
               -- lv_csv_text     := lv_csv_text  ||  gt_payment_data(ln_cnt).payment_date || cv_delimiter;  -- 支払日
               -- lv_csv_text     := lv_csv_text  ||  gt_payment_data(ln_cnt).lease_charge || cv_delimiter;  -- リース料＋リース料_消費税
                  IF ( ln_cnt <= 72 ) THEN 
                    lv_csv_text   := lv_csv_text  ||  gt_payment_data(ln_cnt).lease_charge || cv_delimiter;  -- リース料＋リース料_消費税
                    lv_csv_text   := lv_csv_text  ||  gt_payment_data(ln_cnt).payment_date || cv_delimiter;  -- 支払日
                  END IF;  
              END LOOP out_loop;
              IF  gn_payment_cnt < 72 THEN
                  ln_count := gn_payment_cnt + 1;
                  FOR ln_cnt IN ln_count..72 LOOP
                      lv_csv_text := lv_csv_text  ||  cv_delimiter;                                          -- リース料＋リース料_消費税
                      lv_csv_text := lv_csv_text  ||  cv_delimiter;                                          -- 支払日
                  END LOOP; 
              END IF;
          END IF;
          --
          lv_csv_text := lv_csv_text ||     TO_CHAR(gd_sysdateb,'YYYYMMDDHH24MISS');  --[T1_0354]対応                           -- 連携日時
--          lv_csv_text := lv_csv_text ||     TO_CHAR(gd_sysdateb,'YYYYMMDDHHMISS');                           -- 連携日時
          --
          -- ====================================================
          -- ファイル書き込み
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
          --
          -- ====================================================
          -- 処理件数カウントアップ
          -- ====================================================
          ln_target_cnt := ln_target_cnt + 1 ;
          -- ====================================================
          -- A-8．更新処理(リース契約明細)
          -- ====================================================
          iv_table_name  := cv_msg_xxcff50030;  --リース契約明細テーブル
          SELECT   contract_line_id AS contract_line_id
          INTO     in_contract_line_id
          FROM     xxcff_contract_lines
          WHERE    contract_line_id      = gt_lease_data(ln_loop_cnt).contract_line_id
          FOR UPDATE NOWAIT
          ;
          UPDATE  xxcff_contract_lines
          SET     info_sys_if_date       = gd_sysdateb
          WHERE   contract_line_id       = gt_lease_data(ln_loop_cnt).contract_line_id
          ;
          --
          -- ====================================================
          -- A-8．更新処理(リース物件)
          -- ====================================================
          iv_table_name  := cv_msg_xxcff50014;  --リース物件テーブル
          SELECT   object_header_id AS object_header_id
          INTO     in_object_header_id
          FROM     xxcff_object_headers
          WHERE    object_header_id      = gt_lease_data(ln_loop_cnt).object_header_id
          FOR UPDATE NOWAIT
          ;
          UPDATE  xxcff_object_headers
          SET     info_sys_if_date       = gd_sysdateb
          WHERE   object_header_id       = gt_lease_data(ln_loop_cnt).object_header_id
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
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--       UTL_FILE.FREMOVE  ( gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
      (
       cv_appl_short_name   -- 'XXCFF'
      ,cv_msg_xxcff00007    -- テーブルロックエラー
      ,cv_tkn_table         -- トークン'TABLE'
      ,iv_table_name        -- テーブル名
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
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
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--       UTL_FILE.FREMOVE  ( gn_file_dir_enter , gn_file_name_enter);
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
    ov_errmsg               OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    --  A-4．リース管理情報データファイル情報ログ処理
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
    --  A-5. リース管理情報の取得
    --  A-6. リース支払計画情報データ取得
    -- =====================================================
    get_lease_data
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
    --  A-7．リース管理情報データCSV作成処理
    --  A-8．更新処理
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
    retcode               OUT   VARCHAR2         --   エラーコード     #固定#
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
END XXCFF009A15C;
/