CREATE OR REPLACE PACKAGE BODY XXCSM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A01C(body)
 * Description      : 商品計画用過年度販売実績集計
 * MD.050           : 商品計画用過年度販売実績集計 MD050_CSM_002_A01
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
-- == 2010/03/08 V1.10 Added START ===============================================================
 *  ins_sum_record              専門店、百貨店集約処理(A-8)
-- == 2010/03/08 V1.10 Added END   ===============================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
 *  lock_plan_result            商品計画用販売実績テーブル既存データロック(A-2)
 *  delete_plan_result          商品計画用販売実績テーブル既存データ削除(A-2)
 *  sales_result_select         販売実績抽出処理(A-3)
 *                              仮データ作成用データ抽出処理(A-4)
 *  year_data_select            仮データ作成(対象年度の年間実績抽出)(A-5)
 *  obj_month_data_select       仮データ作成(対象月のデータ抽出)(A-5)
 *  temp_2months_data           仮データ作成(直近2ヶ月分データを使う場合)(A-5)
 *  temp_data_make              仮データ作成(A-5)
 *  insert_plan_result          実績情報登録処理(A-6)
 *                              終了処理(A-7)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   S.Son            新規作成
 *  2009/02/23    1.1   SCS S.Son       [障害CT_057] 既存データが削除される不具合対応
 *  2009/03/03    1.2   M.Ohtsuki       [障害CT_074] ログと出力の表示の不一致の対応
 *  2009/03/04    1.3   S.Son           [障害CT_075] 値引用品目不具合の対応
 *  2009/03/18    1.4   S.Son            仕様変更対応
 *  2009/05/01    1.5   M.Ohtsuki       [障害T1_0861] 特殊品目の処理対象除外 
 *  2009/06/03    1.6   M.Ohtsuki       [障害T1_1174] センター納品の不具合の対応 
 *  2009/08/03    1.7   T.Tsukino       [障害管理番号0000479] 性能改善対応
 *  2009/09/11    1.8   T.Tsukino       [障害管理番号0001180] 性能改善対応
 *  2010/02/09    1.9   S.Karikomi      [E_本稼動_01247] 性能改善対応
 *  2010/03/08    1.10  N.Abe           [E_本稼動_01628] 性能改善対応
                                        [E_本稼動_01629] 百貨店、専門店での集計対応
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
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; --運用日
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
  cv_xxccp                  CONSTANT VARCHAR2(100) := 'XXCCP';
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
  --メッセージーコード
  cv_chk_err_00004          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';       --予算年度チェックエラーメッセージ
  cv_chk_err_00005          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';       --プロファイル取得エラーメッセージ
  cv_chk_err_00006          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00006';       --年間販売計画カレンダー未存在エラーメッセージ
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  cv_msg_00048              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';       --コンカレント入力パラメータメッセージ(拠点コード)
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
  cv_chk_err_00053          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00053';       --品目マスタチェックエラーメッセージ
  cv_chk_err_00085          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00085';       --対象データなしエラーメッセージ
  cv_chk_err_00095          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00095';       --商品計画用販売実績テーブルロックエラー
  cv_chk_err_00110          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00110';       --発売日取得エラー
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --想定外エラーメッセージ
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  cv_msg_00112              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00112';       --コンカレント入力パラメータメッセージ(パラレル番号)
--  cv_msg_00113              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00113';       --コンカレント入力パラメータメッセージ(パラレル数)
--  cv_chk_err_00114          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00114';       --入力パラメータ不正メッセージ
--  cv_msg_00116              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00116';       --コンカレント入力パラメータメッセージ(品目コード)
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
  cv_xxccp_msg_90008        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';       -- コンカレント入力パラメータなし
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
-- == 2010/03/08 V1.10 Added START ===============================================================
  cv_xxcsm_msg_10160        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10160';       -- 商品計画用販売実績ワークテーブルロックエラー
-- == 2010/03/08 V1.10 Added END   ===============================================================
  --トークン
  cv_tkn_cd_colmun          CONSTANT VARCHAR2(100) := 'COLMUN';                 --テーブル列名
  cv_tkn_cd_prof            CONSTANT VARCHAR2(100) := 'PROF_NAME';              --カスタム・プロファイル・オプションの英名
  cv_tkn_cd_item            CONSTANT VARCHAR2(100) := 'ITEM';                   --必要に応じたテキスト項目
  cv_tkn_cd_year            CONSTANT VARCHAR2(100) := 'YYYY';                   --予算年度
  cv_tkn_cd_item_cd         CONSTANT VARCHAR2(100) := 'ITEM_CD';                --品目コード
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  cv_tkn_cd_parallel_no     CONSTANT VARCHAR2(100) := 'PARALLEL_NO';            --パラレル番号
--  cv_tkn_cd_parallel_cnt    CONSTANT VARCHAR2(100) := 'PARALLEL_CNT';           --パラレル数
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
  cv_tkn_cd_deal            CONSTANT VARCHAR2(100) := 'DEAL_CD';                --商品群コード
  cv_tkn_cd_kyoten          CONSTANT VARCHAR2(100) := 'KYOTEN_CD';              --拠点コード
  cv_tkn_year_month         CONSTANT VARCHAR2(100) := 'YYYYMM';                 --年月
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  cv_language_ja            CONSTANT VARCHAR2(2)   := USERENV('LANG');           --言語(日本語)
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                       --フラグY
--
--//+ADD START 2009/08/03 0000479 T.Tsukino
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';
--  cv_lookup_type_01         CONSTANT VARCHAR2(30)  := 'XXCSM1_SUM_PASS_SALES_THREAD'; -- 商品計画用過年度販売実績集計パラレルリスト
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
  cv_lookup_type_02         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_STATUS';             -- 品目ステータスリスト
  cn_inv_application_id     CONSTANT NUMBER        := 401;                            -- アプリケーションID（INV）
  cv_id_flex_code_mcat      CONSTANT VARCHAR2(30)  := 'MCAT';                         -- KFFコード（品目カテゴリ）
  cv_id_flex_str_code_sgum  CONSTANT VARCHAR2(30)  := 'XXCMN_SGUN_CODE';              -- 体系コード（政策群）
--//+ADD END 2009/08/03 0000479 T.Tsukino
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
----//+ADD START 2009/09/11 0001180 T.Tsukino
--  cv_sales_pl_item          CONSTANT VARCHAR2(20)  :='XXCSM1_SALES_PL_ITEM';           --政策群1群
----//+ADD START 2009/09/11 0001180 T.Tsukino
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
-- == 2010/03/08 V1.10 Added START ===============================================================
  cv_lookup_dept_sum        CONSTANT VARCHAR2(30)  := 'XXCSM1_ITEM_PLAN_DEPT_SUM';    -- 百貨店集計拠点
  cv_lookup_sp_sum          CONSTANT VARCHAR2(30)  := 'XXCSM1_ITEM_PLAN_SP_SUM';      -- 専門店集計拠点
  cv_prf_sp                 CONSTANT VARCHAR2(30)  := 'XXCSM1_SP_MANAGEMENT';         -- 専門店管理課拠点コードプロファイル名
-- == 2010/03/08 V1.10 Added END   ===============================================================
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
--
  calendar_check_expt           EXCEPTION;     --カレンダーチェックエラー
  no_date_expt                  EXCEPTION;     --対象データなしエラー
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  parameter_expt                EXCEPTION;     --パラメータチェックエラー
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
  check_lock_expt               EXCEPTION;     --テーブルロックエラー
  item_skip_expt                EXCEPTION;     --品目単位でスキップエラー
  group_cd_expt                 EXCEPTION;     --商品群コード取得例外
  temp_skip_expt                EXCEPTION;     --仮データ作成例外
  no_data_skip_expt             EXCEPTION;     --仮データ作成スキップ

  PRAGMA EXCEPTION_INIT(check_lock_expt,-54);   --ロック取得できないエラー
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCSM002A01C';             -- パッケージ名
  gv_calendar_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER'; --年間販売計画カレンダープロファイル名
  gv_bks_profile       CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';         --GL会計帳簿IDプロファイル名
--//ADD START 2009/03/04 CT_075 S.Son
  gv_disc_group_cd     CONSTANT VARCHAR2(100) := 'XXCSM1_DISCOUNT_GROUP4_CD';--値引き用品目政策群コードプロファイル名
--//ADD END   2009/03/04 CT_075 S.Son
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_calendar_name         VARCHAR2(100);                                --年間販売計画カレンダー名
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  gv_parallel_value_no     VARCHAR2(100);                                --入力パラメータパラレル番号
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2009/08/03 0000479 T.Tsukino
--  gv_parallel_cnt          VARCHAR2(100);                                --入力パラメータパラレル数
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  gv_location_cd           VARCHAR2(4);                                  --入力パラメータ拠点コード
--  gv_item_no               VARCHAR2(32);                                 --入力パラメータ品目コード
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
  gv_bks_id                NUMBER;                                       --会計帳簿ID
  gt_active_year           xxcsm_item_plan_headers.plan_year%TYPE;       --対象年度
  gt_start_date            gl_periods.start_date%TYPE;                   --予算年度開始日
  gn_temp_normal_cnt       NUMBER;                                       --仮データ作成正常件数
  gn_temp_error_cnt        NUMBER;                                       --仮データ作成エラー件数
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
----//ADD START 2009/03/04 CT_075 S.Son
--  gv_discount_cd           VARCHAR2(10);                                 --値引き用品目政策群コードプロファイル名
----//ADD END   2009/03/04 CT_075 S.Son
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
-- == 2010/03/08 V1.10 Added START ===============================================================
  gt_sp_code               xxcsm_item_plan_result.location_cd%TYPE;      -- 専門店管理課拠点コード
-- == 2010/03/08 V1.10 Added END   ===============================================================
--  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    lv_errmsg         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ln_carender_cnt   NUMBER;          --年間販売計画カレンダー取得数
    lv_tkn_value      VARCHAR2(4000);  --トークン値
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_parallel_value_no CONSTANT NUMBER      := 0;
--
    -- *** ローカル変数 ***
--
    ln_retcode           NUMBER;            -- 年間販売計画カレンダーリターンコード
    lv_result            VARCHAR2(100);     -- 年間販売計画カレンダー有効年度処理結果(0:有効年度1の場合、1:有効年度が複数または0個の場合)
    ln_cnt               NUMBER;            -- カウンタ
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--    lv_pram_op_1         VARCHAR2(100);     -- パラメータメッセージ出力(パラレル番号)
--    lv_pram_op_2         VARCHAR2(100);     -- パラメータメッセージ出力(パラレル数)
--    lv_pram_op_3         VARCHAR2(100);     -- パラメータメッセージ出力(拠点コード)
--    lv_pram_op_4         VARCHAR2(100);     -- パラメータメッセージ出力(品目コード)
    lv_prm_msg           VARCHAR2(100);     -- パラメータメッセージ出力(入力パラメータなし)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    -- *** ローカル・カーソル ***
--
      /**      年度開始日取得       **/
    CURSOR startdate_cur1
    IS
      SELECT  gp.start_date
      FROM    gl_sets_of_books gsob
             ,gl_periods gp
      WHERE   gsob.set_of_books_id = gv_bks_id
      AND     gsob.period_set_name = gp.period_set_name
      AND     gp.period_year = gt_active_year
      AND     gp.period_num = 1
      ;
    startdate_cur1_rec startdate_cur1%ROWTYPE;
    
    CURSOR startdate_cur2
    IS
      SELECT  TO_DATE(gt_active_year||TO_CHAR(gp.start_date,'MMDD'),'YYYYMMDD') start_date
      FROM    gl_periods gp
             ,(SELECT  gp.period_year period_year
                      ,gp.period_set_name period_set_name
               FROM    gl_periods gp
                      ,gl_sets_of_books gsob
               WHERE   gsob.set_of_books_id = gv_bks_id
               AND     gsob.period_set_name = gp.period_set_name
               AND     gp.start_date <= cd_process_date
               AND     gp.end_date   >= cd_process_date
              ) year_view
      WHERE   gp.period_num = 1
      AND     gp.period_year = year_view.period_year
      AND     year_view.period_set_name = gp.period_set_name
      ;
      startdate_cur2_rec startdate_cur2%ROWTYPE;
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    /** 顧客コード抽出 **/
--    CURSOR cust_select_cur
--    IS
--      SELECT hca.account_number
--      FROM   hz_cust_accounts    hca
--      WHERE  hca.customer_class_code = '1'
--      ORDER  BY hca.account_number
--      ;
--    TYPE cust_tbl_type IS TABLE OF cust_select_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--    cust_tbl  cust_tbl_type;
--//+DEL END 2009/08/03 0000479 T.Tsukino
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--ローカル変数初期化
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--①入力パラメータをメッセージ出力
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--    --パラレル番号
--    lv_pram_op_1 := xxccp_common_pkg.get_msg(
--                                             iv_application  => cv_xxcsm
--                                            ,iv_name         => cv_msg_00112
--                                            ,iv_token_name1  => cv_tkn_cd_parallel_no
--                                            ,iv_token_value1 => gv_parallel_value_no
--                                            );
--    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_1);
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_1);
----//+DEL START 2009/08/03 0000479 T.Tsukino
----    --パラレル数
----    lv_pram_op_2 := xxccp_common_pkg.get_msg(
----                                            iv_application  => cv_xxcsm
----                                           ,iv_name         => cv_msg_00113
----                                           ,iv_token_name1  => cv_tkn_cd_parallel_cnt
----                                           ,iv_token_value1 => gv_parallel_cnt
----                                           );
----    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_2);
----    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_2);
----//+DEL END 2009/08/03 0000479 T.Tsukino
--    --拠点コード
--    lv_pram_op_3 := xxccp_common_pkg.get_msg(
--                                            iv_application  => cv_xxcsm
--                                           ,iv_name         => cv_msg_00048
--                                           ,iv_token_name1  => cv_tkn_cd_kyoten
--                                           ,iv_token_value1 => gv_location_cd
--                                           );
--    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_3);
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_3);
--    --品目コード
--    lv_pram_op_4 := xxccp_common_pkg.get_msg(
--                                            iv_application  => cv_xxcsm
--                                           ,iv_name         => cv_msg_00116
--                                           ,iv_token_name1  => cv_tkn_cd_item_cd
--                                           ,iv_token_value1 => gv_item_no
--                                           );
--    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_4);
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_4);
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    -- コンカレント入力パラメータなしメッセージ
    lv_prm_msg := xxccp_common_pkg.get_msg(
                                          iv_application  => cv_xxccp            --アプリケーション短縮名
                                         ,iv_name         => cv_xxccp_msg_90008  --メッセージコード
                                         );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_prm_msg
    );
    --ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_prm_msg
    );
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
----//+UPD START 2009/08/03 0000479 T.Tsukino
----    IF (gv_parallel_value_no IS NULL) AND (gv_parallel_cnt IS NOT NULL) THEN
--    IF (gv_parallel_value_no IS NULL) THEN
--      IF(gv_location_cd IS NULL) AND (gv_item_no IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                                              iv_application  => cv_xxcsm
--                                             ,iv_name         => cv_chk_err_00114
--                                             );
--      lv_errbuf := lv_errmsg;
--      RAISE parameter_expt;
----    ELSIF (gv_parallel_value_no IS NOT NULL) AND (gv_parallel_cnt IS NULL) THEN
----      lv_errmsg := xxccp_common_pkg.get_msg(
----                                              iv_application  => cv_xxcsm
----                                             ,iv_name         => cv_chk_err_00114
----                                             );
----      lv_errbuf := lv_errmsg;
----      RAISE parameter_expt;
----    ELSIF (gv_parallel_value_no >= gv_parallel_cnt) THEN
----      lv_errmsg := xxccp_common_pkg.get_msg(
----                                              iv_application  => cv_xxcsm
----                                             ,iv_name         => cv_chk_err_00114
----                                             );
----      lv_errbuf := lv_errmsg;
----      RAISE parameter_expt;
--      END IF;
--      gv_parallel_value_no := cv_parallel_value_no;
--      INSERT INTO xxcsm_tmp_cust_accounts(
--        cust_account_id
--       ,account_number
--      )
--      SELECT  TO_NUMBER(gv_parallel_value_no)
--             ,xabv.base_code
--      FROM   xxcso_aff_base_v2	     xabv
--      WHERE  xabv.summary_flag  = cv_flg_n
--      ;
--    ELSIF (gv_parallel_value_no IS NOT NULL) THEN
--      INSERT INTO xxcsm_tmp_cust_accounts(
--        cust_account_id
--       ,account_number
--      )
--      SELECT  TO_NUMBER(gv_parallel_value_no)
--             ,xabv.base_code
--      FROM    fnd_lookup_values_vl  flvv
--             ,xxcso_aff_base_v2     xabv
--      WHERE   flvv.lookup_type   = cv_lookup_type_01
--        AND   flvv.enabled_flag  = cv_flg_y
--        AND   cd_process_date    BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                     AND NVL(flvv.end_date_active,cd_process_date)
--        AND   flvv.attribute1    = gv_parallel_value_no
--        AND   xabv.base_code     = flvv.lookup_code
--        AND   xabv.summary_flag  = cv_flg_n
--      UNION ALL
--      SELECT  TO_NUMBER(gv_parallel_value_no)
--             ,xablv.child_base_code
--      FROM    xxcso_aff_base_level_v2  xablv
--             ,xxcso_aff_base_v2        xabv
--      WHERE   xabv.base_code     = xablv.child_base_code
--        AND   xabv.summary_flag  = cv_flg_n
--      START WITH
--              xablv.base_code IN
--              (
--               SELECT  flvv.lookup_code
--               FROM    fnd_lookup_values_vl  flvv
--               WHERE   flvv.lookup_type   = cv_lookup_type_01
--                 AND   flvv.enabled_flag  = cv_flg_y
--                 AND   cd_process_date    BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                              AND NVL(flvv.end_date_active,cd_process_date)
--                 AND   flvv.attribute1    = gv_parallel_value_no
--              )
--      CONNECT BY PRIOR
--              xablv.child_base_code = xablv.base_code
--      ;
--    END IF;
----//+UPD END 2009/08/03 0000479 T.Tsukino
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    IF (gv_parallel_value_no IS NULL) AND (gv_parallel_cnt IS NULL) THEN
--      gv_parallel_value_no := 0;
--      gv_parallel_cnt := 1;
--    END IF;
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--② プロファイル値取得
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    --年間販売計画カレンダー名取得
    gv_calendar_name := FND_PROFILE.VALUE(gv_calendar_profile);
    IF gv_calendar_name IS NULL THEN
        lv_tkn_value := gv_calendar_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_cd_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --会計帳簿ID取得
    gv_bks_id := FND_PROFILE.VALUE(gv_bks_profile);
    IF gv_bks_id IS NULL THEN
       lv_tkn_value := gv_bks_profile;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
-- == 2010/03/08 V1.10 Added START ===============================================================
    --専門店管理課拠点コード取得
    gt_sp_code := FND_PROFILE.VALUE(cv_prf_sp);
    IF gt_sp_code IS NULL THEN
       lv_tkn_value := cv_prf_sp;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
-- == 2010/03/08 V1.10 Added END   ===============================================================
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
----//ADD START 2009/03/04 CT_075 S.Son
--    --値引き用品目政策群コード取得
--    gv_discount_cd := FND_PROFILE.VALUE(gv_disc_group_cd);
--    IF (gv_discount_cd IS NULL) THEN
--       lv_tkn_value := gv_disc_group_cd;
--       lv_errmsg := xxccp_common_pkg.get_msg(
--                                             iv_application  => cv_xxcsm
--                                            ,iv_name         => cv_chk_err_00005
--                                            ,iv_token_name1  => cv_tkn_cd_prof
--                                            ,iv_token_value1 => lv_tkn_value
--                                            );
--       lv_errbuf := lv_errmsg;
--       RAISE global_api_expt;
--    END IF;
----//ADD END   2009/03/04 CT_075 S.Son
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--③ 年間販売計画カレンダー存在チェック
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    BEGIN
      SELECT  COUNT(1)
      INTO    ln_carender_cnt
      FROM    fnd_flex_value_sets  ffv                                      -- 値セットヘッダ
      WHERE   ffv.flex_value_set_name = gv_calendar_name;                   -- 年間販売カレンダー名      
      IF (ln_carender_cnt = 0) THEN                                         -- カレンダー存在件数が0件の場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00006
                                             ,iv_token_name1  => cv_tkn_cd_item
                                             ,iv_token_value1 => gv_calendar_name
                                             );
        lv_errbuf := lv_errmsg;
        RAISE calendar_check_expt;
      END IF;  
    END;
--//+UPD START 2009/08/03 0000479 T.Tsukino
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--④ 年間販売計画カレンダー有効年度取得
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    xxcsm_common_pkg.get_yearplan_calender(
--                                           id_comparison_date  => cd_creation_date
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                                           id_comparison_date  => cd_process_date  -- 業務日付
--//+UPD END 2009/08/03 0000479 T.Tsukino                                           
                                          ,ov_status           => lv_result
                                          ,on_active_year      => gt_active_year
                                          ,ov_retcode          => ln_retcode
                                          ,ov_errbuf           => lv_errbuf
                                          ,ov_errmsg           => lv_errmsg
                                          );
    IF (ln_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00004
                                           ,iv_token_name1  => cv_tkn_cd_item
                                           ,iv_token_value1 => gv_calendar_name
                                           );
--//+ADD START 2009/03/03 CT074 M.Ohtsuki
      lv_errbuf := lv_errmsg;
--//+ADD END   2009/03/03 CT074 M.Ohtsuki
      RAISE global_api_expt;
    END IF;
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--⑥ 予算作成年度の年度開始日を取得
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    OPEN startdate_cur1;
      FETCH startdate_cur1 INTO startdate_cur1_rec;
      IF startdate_cur1%NOTFOUND THEN
        OPEN startdate_cur2;
          FETCH startdate_cur2 INTO startdate_cur2_rec;
          gt_start_date := startdate_cur2_rec.start_date;
        CLOSE startdate_cur2;
      ELSE
        gt_start_date := startdate_cur1_rec.start_date;
      END IF;
    CLOSE startdate_cur1;
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    OPEN cust_select_cur;
--      FETCH cust_select_cur BULK COLLECT INTO cust_tbl;
--      FOR i IN 1..cust_tbl.COUNT LOOP
--        INSERT INTO xxcsm_tmp_cust_accounts(
--          cust_account_id
--         ,account_number
--        )
--        VALUES(
--//+UPD START 2009/02/26 CT057 S.Son
--        --i
--          MOD(i,TO_NUMBER(gv_parallel_cnt)) 
----//+UPD END 2009/02/26 CT057 S.Son
--         ,cust_tbl(i).account_number
--        );
--      END LOOP;
--    CLOSE cust_select_cur;
--//+DEL END 2009/08/03 0000479 T.Tsukino
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    --*** 入力パラメータチェック例外処理 ***
--    WHEN parameter_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    --*** 年間販売計画カレンダー未存在例外処理 ***
    WHEN calendar_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /***********************************************************************************
   * Procedure Name   : lock_plan_result
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 商品計画用販売実績テーブル既存データロック(A-2)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE lock_plan_result(
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    iv_location_cd      IN   VARCHAR2,                        -- 拠点コード
--    iv_item_no          IN   VARCHAR2,                        --品目コード
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    ov_errbuf           OUT  NOCOPY VARCHAR2,                 -- エラー・メッセージ
    ov_retcode          OUT  NOCOPY VARCHAR2,                 -- リターン・コード
    ov_errmsg           OUT  NOCOPY VARCHAR2)                 -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_plan_result'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR lock_plan_result_cur 
    IS
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--      SELECT xipr.location_cd                              --拠点コード
--            ,xipr.subject_year                             --対象年度
      SELECT ROWID
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
      FROM   xxcsm_item_plan_result xipr                   --商品計画用販売実績
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--      WHERE  xipr.location_cd = iv_location_cd             --拠点コード
--      AND    xipr.item_no = iv_item_no                     --品目コード
--      AND    xipr.subject_year >= (gt_active_year - 2)
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ロック取得処理
    OPEN lock_plan_result_cur;
    CLOSE lock_plan_result_cur;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN check_lock_expt THEN
      IF lock_plan_result_cur%ISOPEN THEN
        CLOSE lock_plan_result_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  =>  cv_xxcsm
                                   ,iv_name         =>  cv_chk_err_00095
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--                                   ,iv_token_name1  => cv_tkn_cd_kyoten
--                                   ,iv_token_value1 => iv_location_cd
--                                   ,iv_token_name2  => cv_tkn_cd_item_cd
--                                   ,iv_token_value2 => iv_item_no
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
                                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ############################################
--
  END lock_plan_result;
  
  /***********************************************************************************
   * Procedure Name   : delete_plan_result
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 商品計画用販売実績テーブル既存データ削除(A-2)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE delete_plan_result(
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    iv_location_cd      IN   VARCHAR2,                       -- 商品計画ヘッダID
--    iv_item_no          IN   VARCHAR2,                       -- 品目コード
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- エラー・メッセージ
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- リターン・コード
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_plan_result'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 削除処理
    DELETE xxcsm_item_plan_result xipr                         --商品計画用販売実績テーブル
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    WHERE  xipr.location_cd = iv_location_cd                   --拠点コード
--    AND    xipr.item_no = iv_item_no                           --品目コード
--    AND    xipr.subject_year >= (gt_active_year - 2)
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ############################################
--
  END delete_plan_result;
--
  /**********************************************************************************
   * Procedure Name   : insert_plan_result
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 実績情報登録処理(A-6)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE insert_plan_result(
     in_subject_year           IN  NUMBER                       -- 対象年度
    ,in_year_month             IN  NUMBER                       -- 年月
    ,in_month_no               IN  NUMBER                       -- 月
    ,iv_location_cd            IN  VARCHAR2                     -- 拠点コード
    ,iv_item_no                IN  VARCHAR2                     -- 商品コード
    ,iv_item_group_no          IN  VARCHAR2                     -- 商品群コード
    ,in_amount                 IN  NUMBER                       -- 数量
    ,in_sales_budget           IN  NUMBER                       -- 売上金額
    ,in_amount_gross_margin    IN  NUMBER                       -- 粗利益
    ,ov_errbuf                 OUT NOCOPY VARCHAR2              -- エラー・メッセージ
    ,ov_retcode                OUT NOCOPY VARCHAR2              -- リターン・コード
    ,ov_errmsg                 OUT NOCOPY VARCHAR2)             -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_plan_result'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 登録処理
      INSERT INTO xxcsm_item_plan_result xipr(    -- 商品計画用販売実績テーブル
         xipr.subject_year                        -- 対象年度
        ,xipr.year_month                          -- 年月
        ,xipr.month_no                            -- 月
        ,xipr.location_cd                         -- 拠点コード
        ,xipr.item_no                             -- 商品コード
        ,xipr.item_group_no                       -- 商品群コード
        ,xipr.amount                              -- 数量
        ,xipr.sales_budget                        -- 売上金額
        ,xipr.amount_gross_margin                 -- 粗利益
        ,xipr.created_by                          -- 作成者
        ,xipr.creation_date                       -- 作成日
        ,xipr.last_updated_by                     -- 最終更新者
        ,xipr.last_update_date                    -- 最終更新日
        ,xipr.last_update_login                   -- 最終更新ログイン
        ,xipr.request_id                          -- 要求ID
        ,xipr.program_application_id              -- コンカレント・プログラム・アプリケーションID
        ,xipr.program_id                          -- コンカレント・プログラムID
        ,xipr.program_update_date)                -- プログラム更新日
      VALUES(
         in_subject_year                          -- 対象年度
        ,in_year_month                            -- 年月
        ,in_month_no                              -- 月
        ,iv_location_cd                           -- 拠点コード
        ,iv_item_no                               -- 商品コード
        ,iv_item_group_no                         -- 商品群コード
        ,in_amount                                -- 数量
        ,in_sales_budget                          -- 売上金額
        ,in_amount_gross_margin                   -- 粗利益
        ,cn_created_by                            -- 作成者
        ,cd_creation_date                         -- 作成日
        ,cn_last_updated_by                       -- 最終更新者
        ,cd_last_update_date                      -- 最終更新日
        ,cn_last_update_login                     -- 最終更新ログイン
        ,cn_request_id                            -- 要求ID
        ,cn_program_application_id                -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                            -- コンカレント・プログラムID
        ,cd_program_update_date                   -- プログラム更新日
        );
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_plan_result;
--
  /***********************************************************************************
   * Procedure Name   : year_data_select
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 仮データ作成(対象年度の年間実績抽出)(A-5)
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE year_data_select(
    iv_location_cd      IN   VARCHAR2,                       --拠点コード
    iv_item_no          IN   VARCHAR2,                       --品目コード
    in_start_yyyymm     IN   NUMBER,                         --開始年月
    in_end_yyyymm       IN   NUMBER,                         --終了年月
    on_amount           OUT  NUMBER,                         --対象年度年間数量計
    on_sales_budget     OUT  NUMBER,                         --対象年度年間売上計
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- エラー・メッセージ
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- リターン・コード
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'year_data_select'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
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
    CURSOR year_amount_cur
    IS
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--      SELECT  SUM(xipr.amount)         amount                 --対象年度数量年間計
--             ,SUM(xipr.sales_budget)   sales_budget           --対象年度売上年間計
--      FROM    xxcsm_item_plan_result  xipr                    --商品計画用販売実績テーブル
--      WHERE   xipr.location_cd = iv_location_cd               --拠点コード
--      AND     xipr.item_no = iv_item_no                       --品目コード
--      AND     (xipr.year_month >= in_start_yyyymm             --年月
--              AND xipr.year_month < in_end_yyyymm)
      SELECT  SUM(xwipr.amount)         amount                --対象年度数量年間計
             ,SUM(xwipr.sales_budget)   sales_budget          --対象年度売上年間計
      FROM    xxcsm_wk_item_plan_result  xwipr                --商品計画用販売実績ワークテーブル
      WHERE   xwipr.location_cd    =  iv_location_cd          --拠点コード
      AND     xwipr.item_no        =  iv_item_no              --品目コード
      AND     (xwipr.year_month    >= in_start_yyyymm         --年月
              AND xwipr.year_month <  in_end_yyyymm)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    ;
    year_amount_cur_rec year_amount_cur%ROWTYPE;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    --ローカル変数初期化
    
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    OPEN year_amount_cur;
      FETCH year_amount_cur INTO year_amount_cur_rec;
      on_amount := year_amount_cur_rec.amount;                  --数量年間計
      on_sales_budget := year_amount_cur_rec.sales_budget;      --売上年間計
    CLOSE year_amount_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ############################################
--
  END year_data_select;
--
  /***********************************************************************************
   * Procedure Name   : obj_month_data_select
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 仮データ作成(対象月のデータ抽出)(A-5)
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE obj_month_data_select(
    iv_location_cd      IN   VARCHAR2,                       --拠点コード
    iv_item_no          IN   VARCHAR2,                       --品目コード
    in_year             IN   NUMBER,                         --対象年
    in_month            IN   NUMBER,                         --対象月
    on_amount           OUT  NUMBER,                         --対象年月数量
    on_sales_budget     OUT  NUMBER,                         --対象年月売上
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- エラー・メッセージ
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- リターン・コード
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'obj_month_data_select'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
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
    CURSOR obj_month_amount_cur
    IS
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--      SELECT  xipr.amount                                     --対象年度数量年間計
--             ,xipr.sales_budget                               --対象年度売上年間計
--      FROM    xxcsm_item_plan_result  xipr                    --商品計画用販売実績テーブル
--      WHERE   xipr.location_cd = iv_location_cd               --拠点コード
--      AND     xipr.item_no = iv_item_no                       --品目コード
--      AND     xipr.subject_year = in_year                     --年度
--      AND     xipr.month_no    = in_month                     --月
      SELECT  xwipr.amount                                    --対象年度数量年間計
             ,xwipr.sales_budget                              --対象年度売上年間計
      FROM    xxcsm_wk_item_plan_result  xwipr                --商品計画用販売実績ワークテーブル
      WHERE   xwipr.location_cd  = iv_location_cd             --拠点コード
      AND     xwipr.item_no      = iv_item_no                 --品目コード
      AND     xwipr.subject_year = in_year                    --年度
      AND     xwipr.month_no     = in_month                   --月
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    ;
    obj_month_amount_cur_rec obj_month_amount_cur%ROWTYPE;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    --ローカル変数初期化
    
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    OPEN obj_month_amount_cur;
      FETCH obj_month_amount_cur INTO obj_month_amount_cur_rec;
      on_amount       := obj_month_amount_cur_rec.amount;                  --数量年間計
      on_sales_budget := obj_month_amount_cur_rec.sales_budget;            --売上年間計
    CLOSE obj_month_amount_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ############################################
--
  END obj_month_data_select;
--
  /***********************************************************************************
   * Procedure Name   : temp_2months_data
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 仮データ作成(直近2ヶ月分のデータを使う場合)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE temp_2months_data(
    iv_location_cd      IN   VARCHAR2,                       --拠点コード
    iv_item_no          IN   VARCHAR2,                       --品目コード
    in_discrete_cost    IN   NUMBER,                         --営業原価
    on_amount           OUT  NUMBER,                         --数量
    on_sales_budget     OUT  NUMBER,                         --売上
    on_margin           OUT  NUMBER,                         --粗利益
    ov_errbuf           OUT  NOCOPY VARCHAR2,                --エラー・メッセージ
    ov_retcode          OUT  NOCOPY VARCHAR2,                --リターン・コード
    ov_errmsg           OUT  NOCOPY VARCHAR2)                --ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'temp_2months_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    lv_location_cd                 VARCHAR2(9);           --拠点コード
    lv_item_no                     VARCHAR2(32);          --品目コード
    ln_discrete_cost               NUMBER;                --営業原価
    ln_start_yyyymm                NUMBER;                --直近2ヶ月分データ集計開始日
    ln_end_yyyymm                  NUMBER;                --直近2ヶ月分データ集計終了日
    ln_near_2months_amount         NUMBER;                --直近2ヶ月分データ数量集計
    ln_near_2months_budget         NUMBER;                --直近2ヶ月分データ売上集計
    ln_year_average_amount         NUMBER;                --数量年間平均
    ln_year_average_budget         NUMBER;                --売上年間平均
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    --ローカル変数初期化
    lv_location_cd        := iv_location_cd;           --拠点コード
    lv_item_no            := iv_item_no;               --品目コード
    ln_discrete_cost      := in_discrete_cost;         --営業原価
    on_amount             := NULL;                     --数量
    on_sales_budget       := NULL;                     --売上
    on_margin             := NULL;                     --粗利益
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--直近2ヶ月分のデータを取得
    ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-2),'YYYYMM'));
    ln_end_yyyymm   := TO_NUMBER(TO_CHAR(cd_process_date,'YYYYMM'));
    -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
    -- 仮データ作成(対象年度の年間実績抽出)(前年度)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    -- 直近2ヶ月分のデータ集計
    -- ==================================================
    year_data_select(
                    lv_location_cd                   --拠点コード
                   ,lv_item_no                       --品目コード
                   ,ln_start_yyyymm                  --開始年月
                   ,ln_end_yyyymm                    --終了年月
                   ,ln_near_2months_amount           --前年度年間数量計
                   ,ln_near_2months_budget           --前年度年間売上計
                   ,lv_errbuf                        --エラー・メッセージ
                   ,lv_retcode                       --リターン・コード
                   ,lv_errmsg                        --ユーザー・エラー・メッセージ
                  );
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_others_expt;
    END IF;
    --数量年間平均を算出
    ln_year_average_amount := ln_near_2months_amount/2;
    --売上年間平均を算出
    ln_year_average_budget := ln_near_2months_budget/2;
    --仮データの売上を算出
    on_sales_budget := ROUND(ln_year_average_budget,0);
    --仮データの数量を算出
    on_amount := ROUND(ln_year_average_amount,0);
    --仮データの粗利益を算出
    on_margin := ROUND((on_sales_budget - (on_amount * ln_discrete_cost)),0);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ############################################
--
  END temp_2months_data;
--
  /***********************************************************************************
   * Procedure Name   : temp_data_make
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   *  Description      : 仮データ作成(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE temp_data_make(
    iv_location         IN  VARCHAR2,                          -- 前拠点コード
    iv_item_no          IN  VARCHAR2,                          -- 前品目コード
    iv_group_cd         IN  VARCHAR2,                          -- 前商品群コード
    iv_sales_start      IN  VARCHAR2,                          -- 前発売日
    in_discrete_cost    IN  NUMBER,                            -- 前営業原価
    ov_errbuf           OUT  NOCOPY VARCHAR2,                  -- エラー・メッセージ
    ov_retcode          OUT  NOCOPY VARCHAR2,                  -- リターン・コード
    ov_errmsg           OUT  NOCOPY VARCHAR2)                  -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'temp_data_make'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   ############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_subject_year                NUMBER;               --仮データ作成対象年度
    ln_year_month                  NUMBER;               --仮データ作成年月
    ln_month_no                    NUMBER;               --仮データ作成月
    lv_location_cd                 VARCHAR2(4);          --仮データ作成拠点コード
    lv_group_cd                    VARCHAR2(4);          --仮データ作成商品群コード
    lv_item_no                     VARCHAR2(32);         --仮データ作成品目コード
    ln_amount                      NUMBER;               --仮データ作成数量
    ln_sales_budget                NUMBER;               --仮データ作成売上
    ln_margin                      NUMBER;               --仮データ作成粗利益
    ln_months                      NUMBER;               --コンカレント起動日付から、予算年度開始日までの月数
    ln_start_months                NUMBER;               --発売日から、予算年度開始日までの月数
    ln_process_months              NUMBER;               --発売日から、コンカレント起動までの月数
    ln_start_yyyymm                NUMBER;               --年間集計開始日
    ln_end_yyyymm                  NUMBER;               --年間集計終了日
    ld_sales_start                 DATE;                 --発売日
    ln_befor_last_year_amount      NUMBER;               --前々年度数量年間計
    ln_befor_last_year_budget      NUMBER;               --前々年度売上年間計
    ln_last_year_amount            NUMBER;               --前年度数量年間計
    ln_last_year_budget            NUMBER;               --前年度売上年間計
    ln_obj_year                    NUMBER;               --仮データ作成用対象年
    ln_obj_month                   NUMBER;               --仮データ作成用対象月
    ln_obj_amount                  NUMBER;               --仮データ作成用対象月数量
    ln_obj_sales_budget            NUMBER;               --仮データ作成用対象月売上
    ln_discrete_cost               NUMBER;               --仮データ作成用営業原価
    ln_result_budget_rate          NUMBER;               --売上実績比率
    ln_result_amount_rate          NUMBER;               --数量実績比率
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END   #############################################
--
--ローカル変数初期化
    lv_location_cd     := iv_location;                                --拠点コード
    lv_item_no         := iv_item_no;                                 --品目コード
    lv_group_cd        := iv_group_cd;                                --商品群コード
    ld_sales_start     := TO_DATE(iv_sales_start,'YYYY-MM-DD');       --発売日
    ln_discrete_cost   := in_discrete_cost;                           --営業原価
    ln_subject_year    := gt_active_year - 1;                         --対象年度
    ln_obj_year        := gt_active_year - 2;                         --対象月データ取得対象年度
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --コンカレント起動日付から、予算年度開始日までの月数算出
    ln_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(gt_start_date,'YYYYMM')||'01','YYYYMMDD'),
                                TO_DATE(TO_CHAR(cd_process_date,'YYYYMM')||'01','YYYYMMDD'));
    --発売日から、予算年度開始日までの月数。(実績存在月数)
    ln_start_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(gt_start_date,'YYYYMM')||'01','YYYYMMDD'),
                                TO_DATE(TO_CHAR(ld_sales_start,'YYYYMM')||'01','YYYYMMDD'));
    --発売日から、コンカレント起動までの月数
    ln_process_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(cd_process_date,'YYYYMM')||'01','YYYYMMDD'),
                                TO_DATE(TO_CHAR(ld_sales_start,'YYYYMM')||'01','YYYYMMDD'));
    --月数より繰り返し
    FOR j IN 0..ln_months LOOP
      EXIT WHEN j = ln_months;
      BEGIN
        --仮データの年月を算出
        ln_year_month := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,j),'YYYYMM'));
        --仮データの月を算出
        ln_month_no := SUBSTR(ln_year_month,5,2);
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
        -- *****************************************************
        -- *＜仮データ作成例＞
        -- * 例)予算開始年月：2010/05,コンカレント起動：2010/02
        -- * 1.販売年月：～2008/02
        -- * 2.販売年月：2008/03～2008/12
        -- * 3.販売年月：2009/01～2010/01
        -- * 4.販売年月：2010/02
        -- *****************************************************
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
        --1．既存商品(発売年月は予算年度開始年月から27ヶ月前のデータ)の仮データ作成
        IF ln_start_months >= 27 THEN
          --前々年度の実績抽出
          ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(gt_start_date,-24),'YYYYMM'));
          ln_end_yyyymm   := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-12),'YYYYMM'));
          -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 仮データ作成(対象年度の年間実績抽出)(前々年度)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ==================================================
          year_data_select(
                            lv_location_cd                --拠点コード
                           ,lv_item_no                    --品目コード
                           ,ln_start_yyyymm               --開始年月
                           ,ln_end_yyyymm                 --終了年月
                           ,ln_befor_last_year_amount     --前々年度年間数量計
                           ,ln_befor_last_year_budget     --前々年度年間売上計
                           ,lv_errbuf                     --エラー・メッセージ
                           ,lv_retcode                    --リターン・コード
                           ,lv_errmsg                     --ユーザー・エラー・メッセージ
                          );
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_others_expt;
          END IF;
          IF (ln_befor_last_year_amount IS NULL) OR (ln_befor_last_year_amount = 0) THEN
            -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- 仮データ作成(直近2ヶ月の場合)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
            temp_2months_data(
                              lv_location_cd,                  --拠点コード
                              lv_item_no,                      --品目コード
                              ln_discrete_cost,                --営業原価
                              ln_amount,                       --数量
                              ln_sales_budget,                 --売上
                              ln_margin,                       --粗利益
                              lv_errbuf,                       --エラー・メッセージ
                              lv_retcode,                      --リターン・コード
                              lv_errmsg);                      --ユーザー・エラー・メッセージ
            -- 例外処理
            IF (lv_retcode <> cv_status_normal) THEN
              --(エラー処理)
              RAISE global_api_others_expt;
            END IF;
            IF ln_sales_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
          ELSE
            --前年度の実績抽出
            ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(gt_start_date,-12),'YYYYMM'));
            ln_end_yyyymm   := TO_NUMBER(TO_CHAR(cd_process_date,'YYYYMM'));
            -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- 仮データ作成(対象年度の年間実績抽出)(前年度)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
            year_data_select(
                            lv_location_cd                --拠点コード
                           ,lv_item_no                    --品目コード
                           ,ln_start_yyyymm               --開始年月
                           ,ln_end_yyyymm                 --終了年月
                           ,ln_last_year_amount           --前年度年間数量計
                           ,ln_last_year_budget           --前年度年間売上計
                           ,lv_errbuf                     --エラー・メッセージ
                           ,lv_retcode                    --リターン・コード
                           ,lv_errmsg                     --ユーザー・エラー・メッセージ
                          );
            -- 例外処理
            IF (lv_retcode <> cv_status_normal) THEN
              --(エラー処理)
              RAISE global_api_others_expt;
            END IF;
            IF ln_last_year_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
            --実績比率の算出(前年度実績÷前々年度実績)
--//+ADD START 2010/1/26 E_本稼動_00616 T.Nakano
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
            IF (ln_befor_last_year_budget <> 0) THEN
              ln_result_budget_rate := ln_last_year_budget/ln_befor_last_year_budget;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
              ln_result_amount_rate := ln_last_year_amount/ln_befor_last_year_amount;
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
              obj_month_data_select(
                                    lv_location_cd               --拠点コード
                                   ,lv_item_no                   --品目コード
                                   ,ln_obj_year                  --対象年
                                   ,ln_month_no                  --対象月
                                   ,ln_obj_amount                --対象年月数量
                                   ,ln_obj_sales_budget          --対象年月売上
                                   ,lv_errbuf                    --エラー・メッセージ
                                   ,lv_retcode                   --リターン・コード
                                   ,lv_errmsg);                  --ユーザー・エラー・メッセージ
              -- 例外処理
              IF (lv_retcode <> cv_status_normal) THEN
                --(エラー処理)
                RAISE global_api_others_expt;
              END IF;
              IF ln_obj_sales_budget IS NULL THEN
                RAISE no_data_skip_expt;
              END IF;
            ELSIF (ln_befor_last_year_budget = 0) THEN
              --対象月算出(直近1ヶ月分)
              ln_obj_year  := ln_subject_year;
              ln_obj_month := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-1),'MM'));
              ln_result_budget_rate := 1;
              ln_result_amount_rate := 1;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- 仮データ作成(対象月のデータ抽出)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
              obj_month_data_select(
                                    lv_location_cd               --拠点コード
                                   ,lv_item_no                   --品目コード
                                   ,ln_obj_year                  --対象年
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--                                   ,ln_month_no                  --対象月
                                   ,ln_obj_month                 --対象月(直近1ヶ月)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
                                   ,ln_obj_amount                --対象年月数量
                                   ,ln_obj_sales_budget          --対象年月売上
                                   ,lv_errbuf                    --エラー・メッセージ
                                   ,lv_retcode                   --リターン・コード
                                   ,lv_errmsg);                  --ユーザー・エラー・メッセージ
              -- 例外処理
              IF (lv_retcode <> cv_status_normal) THEN
                --(エラー処理)
                RAISE global_api_others_expt;
              END IF;
              IF ln_obj_sales_budget IS NULL THEN
                RAISE no_data_skip_expt;
              END IF;
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
            END IF;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--            IF (ln_befor_last_year_budget <> 0) THEN
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+ADD END 2010/1/26 E_本稼動_00616 T.Nakano
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--              ln_result_budget_rate := ln_last_year_budget/ln_befor_last_year_budget;
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2010/1/26 E_本稼動_00616 T.Nakano
--              ln_result_amount_rate := ln_last_year_amount/ln_befor_last_year_amount;
--              -- ==================================================
--              -- 仮データ作成(対象月のデータ抽出)(A-8)
--              -- ==================================================
--              obj_month_data_select(
--                                    lv_location_cd               --拠点コード
--                                   ,lv_item_no                   --品目コード
--                                   ,ln_obj_year                  --対象年
--                                   ,ln_month_no                  --対象月
--                                   ,ln_obj_amount                --対象年月数量
--                                   ,ln_obj_sales_budget          --対象年月売上
--                                   ,lv_errbuf                    --エラー・メッセージ
--                                   ,lv_retcode                   --リターン・コード
--                                   ,lv_errmsg);                  --ユーザー・エラー・メッセージ
--              -- 例外処理
--              IF (lv_retcode <> cv_status_normal) THEN
--                --(エラー処理)
--                RAISE global_api_others_expt;
--              END IF;
--              IF ln_obj_sales_budget IS NULL THEN
--                RAISE no_data_skip_expt;
--              END IF;
--//+DEL END 2010/1/26 E_本稼動_00616 T.Nakano
            --仮データの売上を算出
            ln_sales_budget := ROUND((ln_obj_sales_budget * ln_result_budget_rate),0);
            --仮データの数量を算出
            ln_amount := ROUND((ln_obj_amount * ln_result_amount_rate),0);
            --仮データの粗利益を算出
            ln_margin :=ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
----//+ADD START 2010/1/26 E_本稼動_00616 T.Nakano
--            ELSIF (ln_befor_last_year_budget = 0) THEN
--              ln_result_budget_rate := 0;
--             --仮データの売上を算出
--              ln_sales_budget := ROUND((ln_obj_sales_budget * ln_result_budget_rate),0);
--              --仮データの数量を算出
--              ln_amount := ROUND((ln_obj_amount * ln_result_amount_rate),0);
--              --仮データの粗利益を算出
--              ln_margin :=ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
--            END IF;
----//+ADD END 2010/1/26 E_本稼動_00616 T.Nakano
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
          END IF;
        --2．新商品2ヵ年度実績(運用年月の12ヶ月前までに、発売年月から3ヶ月間内のデータが存在する場合)の仮データ作成
        ELSIF ln_start_months < 27 AND ln_process_months > 15 THEN
          --前々年度の実績抽出
          ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(ld_sales_start,3),'YYYYMM'));
          ln_end_yyyymm   := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-12),'YYYYMM'));
          -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 仮データ作成(対象年度の年間実績抽出)(前々年度)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ==================================================
          year_data_select(
                            lv_location_cd                --拠点コード
                           ,lv_item_no                    --品目コード
                           ,ln_start_yyyymm               --開始年月
                           ,ln_end_yyyymm                 --終了年月
                           ,ln_befor_last_year_amount     --前々年度年間数量計
                           ,ln_befor_last_year_budget     --前々年度年間売上計
                           ,lv_errbuf                     --エラー・メッセージ
                           ,lv_retcode                    --リターン・コード
                           ,lv_errmsg                     --ユーザー・エラー・メッセージ
                          );
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_others_expt;
          END IF;
          IF (ln_befor_last_year_amount IS NULL) OR (ln_befor_last_year_amount = 0) THEN
            -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- 仮データ作成(直近2ヶ月の場合)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
            temp_2months_data(
                              lv_location_cd,                  --拠点コード
                              lv_item_no,                      --品目コード
                              ln_discrete_cost,                --営業原価
                              ln_amount,                       --数量
                              ln_sales_budget,                 --売上
                              ln_margin,                       --粗利益
                              lv_errbuf,                       --エラー・メッセージ
                              lv_retcode,                      --リターン・コード
                              lv_errmsg);                      --ユーザー・エラー・メッセージ
            -- 例外処理
            IF (lv_retcode <> cv_status_normal) THEN
              --(エラー処理)
              RAISE global_api_others_expt;
            END IF;
            IF ln_sales_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
          ELSE
            --前年度の実績抽出
            ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(ld_sales_start,15),'YYYYMM'));
            ln_end_yyyymm   := TO_NUMBER(TO_CHAR(cd_process_date,'YYYYMM'));
            -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- 仮データ作成(対象年度の年間実績抽出)(前年度)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
            year_data_select(
                            lv_location_cd                --拠点コード
                           ,lv_item_no                    --品目コード
                           ,ln_start_yyyymm               --開始年月
                           ,ln_end_yyyymm                 --終了年月
                           ,ln_last_year_amount           --前年度年間数量計
                           ,ln_last_year_budget           --前年度年間売上計
                           ,lv_errbuf                     --エラー・メッセージ
                           ,lv_retcode                    --リターン・コード
                           ,lv_errmsg                     --ユーザー・エラー・メッセージ
                          );
            -- 例外処理
            IF (lv_retcode <> cv_status_normal) THEN
              --(エラー処理)
              RAISE global_api_others_expt;
            END IF;
            IF ln_last_year_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
            --実績比率の算出(前年度実績÷前々年度実績)
--//+ADD START 2010/1/26 E_本稼動_00616 T.Nakano
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
            IF (ln_befor_last_year_budget <> 0) THEN
              ln_result_budget_rate := ln_last_year_budget/ln_befor_last_year_budget;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
              ln_result_amount_rate := ln_last_year_amount/ln_befor_last_year_amount;
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
              obj_month_data_select(
                                    lv_location_cd               --拠点コード
                                   ,lv_item_no                   --品目コード
                                   ,ln_obj_year                  --対象年
                                   ,ln_month_no                  --対象月
                                   ,ln_obj_amount                --対象年月数量
                                   ,ln_obj_sales_budget          --対象年月売上
                                   ,lv_errbuf                    --エラー・メッセージ
                                   ,lv_retcode                   --リターン・コード
                                   ,lv_errmsg);                  --ユーザー・エラー・メッセージ
              -- 例外処理
              IF (lv_retcode <> cv_status_normal) THEN
                --(エラー処理)
                RAISE global_api_others_expt;
              END IF;
              IF ln_last_year_budget IS NULL THEN
                RAISE no_data_skip_expt;
              END IF;
            ELSIF (ln_befor_last_year_budget = 0) THEN
              --対象月算出(直近1ヶ月分)
              ln_obj_year  := ln_subject_year;
              ln_obj_month  := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-1),'MM'));
              ln_result_budget_rate := 1;
              ln_result_amount_rate := 1;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- 仮データ作成(対象月のデータ抽出)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ==================================================
              obj_month_data_select(
                                    lv_location_cd               --拠点コード
                                   ,lv_item_no                   --品目コード
                                   ,ln_obj_year                  --対象年
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--                                   ,ln_month_no                  --対象月
                                   ,ln_obj_month                 --対象月(直近1ヶ月)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
                                   ,ln_obj_amount                --対象年月数量
                                   ,ln_obj_sales_budget          --対象年月売上
                                   ,lv_errbuf                    --エラー・メッセージ
                                   ,lv_retcode                   --リターン・コード
                                   ,lv_errmsg);                  --ユーザー・エラー・メッセージ
              -- 例外処理
              IF (lv_retcode <> cv_status_normal) THEN
                --(エラー処理)
                RAISE global_api_others_expt;
              END IF;
              IF ln_obj_sales_budget IS NULL THEN
                RAISE no_data_skip_expt;
              END IF;
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
            END IF;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--            IF (ln_befor_last_year_budget <> 0) THEN
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+ADD END 2010/1/26 E_本稼動_00616 T.Nakano
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--              ln_result_budget_rate := ln_last_year_budget/ln_befor_last_year_budget;
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2010/1/26 E_本稼動_00616 T.Nakano
--              ln_result_amount_rate := ln_last_year_amount/ln_befor_last_year_amount;
--              -- ==================================================
--              -- 仮データ作成(対象月のデータ抽出)(A-8)
--              -- ==================================================
--              obj_month_data_select(
--                                    lv_location_cd               --拠点コード
--                                   ,lv_item_no                   --品目コード
--                                   ,ln_obj_year                  --対象年度
--                                   ,ln_month_no                  --対象月
--                                   ,ln_obj_amount                --対象年月数量
--                                   ,ln_obj_sales_budget          --対象年月売上
--                                   ,lv_errbuf                    --エラー・メッセージ
--                                   ,lv_retcode                   --リターン・コード
--                                   ,lv_errmsg);                  --ユーザー・エラー・メッセージ
--              -- 例外処理
--              IF (lv_retcode <> cv_status_normal) THEN
--                --(エラー処理)
--                RAISE global_api_others_expt;
--              END IF;
--              IF ln_obj_sales_budget IS NULL THEN
--                RAISE no_data_skip_expt;
--              END IF;
--//+DEL END 2010/1/26 E_本稼動_00616 T.Nakano
              --仮データの売上を算出
              ln_sales_budget := ROUND((ln_obj_sales_budget * ln_result_budget_rate),0);
              --仮データの数量を算出
              ln_amount := ROUND((ln_obj_amount * ln_result_amount_rate),0);
              --仮データの粗利益を算出
              ln_margin := ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
----//+ADD START 2010/1/26 E_本稼動_00616 T.Nakano
--            ELSIF (ln_befor_last_year_budget = 0) THEN
--              ln_result_budget_rate := 0;
--              --仮データの売上を算出
--              ln_sales_budget := ROUND((ln_obj_sales_budget * ln_result_budget_rate),0);
--              --仮データの数量を算出
--              ln_amount := ROUND((ln_obj_amount * ln_result_amount_rate),0);
--              --仮データの粗利益を算出
--              ln_margin :=ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
--            END IF;
----//+ADD END 2010/1/26 E_本稼動_00616 T.Nakano
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
          END IF;
        --3．新商品単年度(発売年月から運用年月まで15ヶ月以降2ヶ月分以上のデータが存在する場合)の仮データ作成
        ELSIF ln_start_months < 27 AND (ln_process_months <= 15 AND ln_process_months > 1) THEN
          -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 仮データ作成(直近2ヶ月の場合)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ==================================================
          temp_2months_data(
                              lv_location_cd,                  --拠点コード
                              lv_item_no,                      --品目コード
                              ln_discrete_cost,                --営業原価
                              ln_amount,                       --数量
                              ln_sales_budget,                 --売上
                              ln_margin,                       --粗利益
                              lv_errbuf,                       --エラー・メッセージ
                              lv_retcode,                      --リターン・コード
                              lv_errmsg);                      --ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_others_expt;
          END IF;
          IF ln_sales_budget IS NULL THEN
            RAISE no_data_skip_expt;
          END IF;
        --4．新商品単年度(発売年月から運用年月まで、一ヶ月分のデータのみ存在する場合)の仮データ作成
        ELSIF ln_process_months = 1 THEN
          --対象月算出
          ln_obj_year  := ln_subject_year;
          ln_obj_month := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-1),'MM'));
          -- ==================================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 仮データ作成(対象月のデータ抽出)(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ==================================================
          obj_month_data_select(
                                lv_location_cd               --拠点コード
                               ,lv_item_no                   --品目コード
                               ,ln_obj_year                  --対象年度
                               ,ln_obj_month                 --対象月
                               ,ln_obj_amount                --対象年月数量
                               ,ln_obj_sales_budget          --対象年月売上
                               ,lv_errbuf                    --エラー・メッセージ
                               ,lv_retcode                   --リターン・コード
                               ,lv_errmsg);                  --ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_others_expt;
          END IF;
          IF ln_obj_sales_budget IS NULL THEN
            RAISE no_data_skip_expt;
          END IF;
          --仮データの売上を算出
          ln_sales_budget := ln_obj_sales_budget;
          --仮データの数量を算出
          ln_amount := ln_obj_amount;
          --仮データの粗利益を算出
          ln_margin := ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
        END IF;
--
        --仮データ存在する場合だけ、データを登録
        IF ln_sales_budget IS NOT NULL THEN
          -- ===================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 実績情報登録処理(A-6)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ===================================
          insert_plan_result(
                             ln_subject_year                -- 対象年度
                            ,ln_year_month                  -- 年月
                            ,ln_month_no                    -- 月
                            ,lv_location_cd                 -- 拠点コード
                            ,lv_item_no                     -- 商品コード
                            ,lv_group_cd                    -- 商品群コード
                            ,ln_amount                      -- 数量
                            ,ln_sales_budget                -- 売上金額
                            ,ln_margin                      -- 粗利益
                            ,lv_errbuf                      -- エラー・メッセージ
                            ,lv_retcode                     -- リターン・コード
                            ,lv_errmsg);                    -- ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_others_expt;
          END IF;
          gn_temp_normal_cnt := gn_temp_normal_cnt + 1;
        END IF;
      EXCEPTION
        WHEN temp_skip_expt THEN
          gn_temp_error_cnt := gn_temp_error_cnt + 1;
          fnd_file.put_line(
                             which  => FND_FILE.LOG
                            ,buff   => lv_errbuf
                            );
          fnd_file.put_line(
                          which  => FND_FILE.OUTPUT
                         ,buff   => lv_errmsg
                         );
        WHEN no_data_skip_expt THEN
          --何もしない
          NULL;
      END;
    END LOOP;
--
  EXCEPTION
--#################################  固定例外処理部 START   ######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ############################################
--
  END temp_data_make;
  
  /**********************************************************************************
   * Procedure Name   : sales_result_select
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
   * Description      : 販売実績抽出処理(A-3)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
   ***********************************************************************************/
  PROCEDURE sales_result_select(
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'sales_result_select';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    lv_errmsg         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    cv_sales_class   CONSTANT VARCHAR2(100) := 'XXCSM1_EXCLUSION_SALES_CLASS';     --販売実績集計除外売上区分
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//ADD START 2009/05/01 T1_0861 M.Ohtsuki
    cv_sp_item_cd        CONSTANT VARCHAR2(100) := 'XXCSM1_SPECIAL_ITEM';          --特殊品目コード
--//ADD END   2009/05/01 T1_0861 M.Ohtsuki
--//ADD START 2009/06/03 T1_1174 M.Ohtsuki
    cv_flg_on            CONSTANT VARCHAR2(1) := '1';                              --フラグON
    cv_flg_off           CONSTANT VARCHAR2(1) := '0';                              --フラグOFF
    
--//ADD END   2009/06/03 T1_1174 M.Ohtsuki
    -- *** ローカル変数 ***
--
    ln_result_cnt                 NUMBER;                      --販売実績抽出件数
    ln_subject_year               NUMBER;                      --対象年度
    ln_year_month                 NUMBER;                      --年月
    ln_month_no                   NUMBER;                      --月
    lv_location_cd                VARCHAR2(9);                 --拠点コード
    lv_item_no                    VARCHAR2(32);                --品目コード
    ln_amount                     NUMBER;                      --数量月計
    ln_sales_budget               NUMBER;                      --売上月計
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    ln_margin_you                 NUMBER;                      --粗利益算出用データ
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    ln_margin                     NUMBER;                      --粗利益月計
    lv_group_cd                   VARCHAR2(100);               --商品群コード
    lv_opm_item_no                VARCHAR2(32);                --OPM品目マスタ品目コード
    lv_start_date                 VARCHAR2(100);               --発売日
    lv_location_pre               VARCHAR2(9);                 --保存用拠点コード
    lv_item_no_pre                VARCHAR2(32);                --保存用品目コード
    lv_group_cd_pre               VARCHAR2(100);               --保存用商品群コード
    lv_start_date_pre             VARCHAR2(100);               --保存用発売日
    ln_discrete_cost_pre          NUMBER;                      --保存用営業原価
    ln_discrete_cost              NUMBER;                      --営業原価
    lb_create_data                BOOLEAN;                     --仮データ作成フラグ
    lb_skip_flg                   BOOLEAN;                     --品目単位でスキップフラグ
    lb_group_skip_flg             BOOLEAN;                     --商品群取得できないスキップフラグ
    opm_item_count                number;
    -- *** ローカル・カーソル ***
      /**      販売実績データ抽出       **/
    CURSOR sales_result_cur
    IS
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
----//+UPD START   2009/03/18  仕様変更  S.Son
----      SELECT  xsh.year_month                               year_month                 --納品年月
----             ,xsh.month                                    month                      --納品月
----             ,xsh.sale_base_code                           sale_base_code             --売上拠点コード
----             ,xselv.item_code                               item_code                 --品目コード
----             ,SUM(xselv.standard_qty)                       month_sumary_qty          --基準数量
----             ,SUM(xselv.pure_amount)                        month_sumary_pure_amount  --本体金額
----             ,SUM(xselv.standard_qty * NVL(xselv.business_cost,0))  month_sumary_margin       --粗利益算出用
----      FROM   (SELECT xsehv.sales_exp_header_id              sales_exp_header_id       --販売実績ヘッダID
----                    ,TO_CHAR(xsehv.delivery_date,'YYYYMM')  year_month                --納品年月
----                    ,TO_CHAR(xsehv.delivery_date,'MM')      month                     --納品月
----                    ,DECODE(xca.rsv_sale_base_act_date                                --予約売上拠点有効開始日
----                           ,gt_start_date                                             --予算年度開始日
----                           ,xca.rsv_sale_base_code                                    --予約売上拠点コード
----                           ,xca.sale_base_code                                        --売上拠点コード
----                           )  sale_base_code                 --年次切替拠点の場合、対象年度に適用される拠点を導出
----              FROM   xxcsm_sales_exp_headers_v   xsehv                                --販売実績ヘッダテーブルビュー
----                     ,xxcmm_cust_accounts      xca                                    --顧客追加情報
----              WHERE  TRUNC(xsehv.delivery_date,'MM') >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')      --予算作成年度開始月－24ヶ月
----              AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(gt_start_date,'MM')
----              AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(cd_process_date,'MM')    --コンカレント起動年月前のデータを対象とする
----              AND    xsehv.ship_to_customer_code = xca.customer_code                  --顧客【納品先】=顧客コード(顧客追加情報)
----             ) xsh                                                                    --販売実績インラインビュー
----             ,xxcsm_sales_exp_lines_v    xselv                                        --販売実績明細テーブルビュー
----             ,xxcsm_tmp_cust_accounts         xtca                                     --顧客情報ワークテーブル（拠点のデータのみ）
----//+ADD START 2009/03/04 CT075 S.Son
----             ,xxcsm_commodity_group4_v   xcg4v                                         --商品群４ビュー
----//+ADD END 2009/03/04 CT075 S.Son
----      WHERE  xsh.sales_exp_header_id = xselv.sales_exp_header_id                      --販売実績ヘッダIDの紐付け
----      AND    xsh.sale_base_code = xtca.account_number                                 --売上拠点コード=顧客コード
----//+UPD START 2009/02/26 CT057 S.Son
----    --AND    MOD(xtca.cust_account_id,TO_NUMBER(gv_parallel_cnt)) 
----      AND    xtca.cust_account_id 
----                  = TO_NUMBER(gv_parallel_value_no)                                   --拠点のIDにてパラレル
----//+UPD START 2009/02/26 CT057 S.Son
----      AND    xsh.sale_base_code = NVL(gv_location_cd,xsh.sale_base_code)              --入力パラメータ拠点コードNULLの場合
----                                                                                      --パラレルより、拠点コードを取得
----      AND    xselv.item_code     = NVL(gv_item_no,xselv.item_code)                    --入力パラメータ品目コードNULLの場合
----                                                                                      --対象品目コードすべてを取得
----//+ADD START 2009/03/04 CT075 S.Son
----      AND    xcg4v.item_cd  =  xselv.item_code                                        --商品群４ビューを紐付く
----      AND    xcg4v.group4_cd <> gv_discount_cd                                        --値引用品目(DAAE)以外
----//+ADD END 2009/03/04 CT075 S.Son
----      AND    NOT EXISTS (SELECT 'X'
----                         FROM   fnd_lookup_values flv                                            --クイックコード値
----                         WHERE  flv.lookup_type = cv_sales_class                                 --販売実績集計除外売上区分
----                         AND    flv.enabled_flag = cv_flg_y                                      --有効フラグ
----                         AND    flv.language = cv_language_ja                                    --言語
----                         AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date   --開始日
----                         AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date   --終了日
----                         AND    flv.lookup_code = xselv.sales_class)                             --ルックアップコード=売上区分
----      GROUP BY  xsh.sale_base_code                 --売上拠点コード
----               ,xselv.item_code                    --品目コード
----               ,xsh.year_month                     --納品年月
----               ,xsh.month                          --納品月
----      ORDER BY  xsh.sale_base_code                 --売上拠点コード
----              ,xselv.item_code                    --品目コード
----	               ,xsh.year_month                     --納品年月
----    ;
----↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
----//+UPD START 2009/06/03 T1_1174 M.Ohtsuki
----   SELECT  xse.year_month                                        year_month                         -- 年月
----          ,xse.month                                             month                              -- 月
----          ,xse.sale_base_code                                    sale_base_code                     -- 売上拠点コード
----          ,xse.item_code                                         item_code                          -- 品目コード
----          ,SUM(xse.month_sumary_qty)                             month_sumary_qty                   -- 売上金額
----          ,SUM(xse.month_sumary_pure_amount)                     month_sumary_pure_amount           -- 数量
----          ,SUM(xse.month_sumary_margin)                          month_sumary_margin                -- 粗利益算出用
----   FROM   (SELECT  TO_CHAR(xsti.selling_date,'YYYYMM')           year_month                         -- 売上計上日(年月)
----                  ,TO_CHAR(xsti.selling_date,'MM')               month                              -- 売上計上日(月)
----                  ,xcai.sale_base_code                            sale_base_code                    -- 売上拠点コード
----                  ,xsti.item_code                                item_code                          -- 品目コード
----                  ,SUM(xsti.qty)                                 month_sumary_qty                   -- 基準数量
----                  ,SUM(xsti.selling_amt)                         month_sumary_pure_amount           -- 本体金額
----                  ,SUM(xsti.qty * NVL(xsti.trading_cost,0))      month_sumary_margin                -- 粗利益算出用
----          FROM    (SELECT  DISTINCT xsti.slip_no                 slip_no                            -- 伝票番号
----                   FROM    xxcok_selling_trns_info               xsti                               -- 実績振替テーブル
----                          ,xxcmm_cust_accounts                   xca                                -- 追加顧客情報テーブル
----                          ,xxcsm_sales_exp_headers_v             xsehv                              -- 販売実績ヘッダビュー
----                   WHERE  xsehv.ship_to_customer_code = xca.customer_code                           -- 顧客コードで紐付け
----                   AND    xsehv.ship_to_customer_code = xsti.cust_code                              -- 顧客コードで紐付け
----                   )                                             sti
----                  ,(SELECT      DISTINCT xsti.cust_code          cust_code
----                               ,DECODE(xca.rsv_sale_base_act_date                                   -- 予約売上拠点有効開始日
----                                       ,gt_start_date                                               -- 予算年度開始日
----                                       ,xca.rsv_sale_base_code                                      -- 予約売上拠点コード
----                                       ,xca.sale_base_code                                          -- 売上拠点コード
----                                       )                         sale_base_code
----                   FROM    xxcok_selling_trns_info               xsti                               -- 実績振替テーブル
----                          ,xxcmm_cust_accounts                   xca                                -- 追加顧客情報テーブル
----                   WHERE  xsti.cust_code = xca.customer_code                                        -- 顧客コードで紐付け
----                   )   xcai
----                  ,xxcok_selling_trns_info                       xsti                               -- 実績振替テーブル
----                  ,xxcsm_tmp_cust_accounts                       xtca                               -- 顧客情報ワークテーブル（拠点のデータのみ）
----                  ,xxcsm_commodity_group4_v                      xcg4v                              -- 商品群４ビュー
----          WHERE   xcai.sale_base_code  = xtca.account_number                                        -- 売上拠点コード = 顧客コード
----          AND     xtca.cust_account_id = TO_NUMBER(gv_parallel_value_no)                            -- 拠点のIDにてパラレル
----          AND     xcai.sale_base_code  = NVL(gv_location_cd,xcai.sale_base_code)                    -- 入力パラメータ拠点コードNULLの場合
----          AND     xsti.item_code       = NVL(gv_item_no,xsti.item_code)                             -- 入力パラメータ品目コードNULLの場合
----          AND     sti.slip_no          = xsti.slip_no                                               -- 伝票番号紐付け
----          AND     xcai.cust_code       = xsti.cust_code                                             -- 顧客コード紐付け
----          AND     TRUNC(xsti.selling_date,'MM')   >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')      -- 予算作成年度開始月－24ヶ月
----          AND     TRUNC(xsti.selling_date,'MM')   <  TRUNC(gt_start_date,'MM')                      -- 年度開始日より前のデータ
----          AND     TRUNC(xsti.selling_date,'MM')   <  TRUNC(cd_process_date,'MM')                    -- コンカレント起動年月前のデータを対象とする
----          AND     (xsti.report_decision_flag = 1                                                    -- 速報確定フラグ = 確定
----                  OR 
----                  (TRUNC(xsti.selling_date,'MM')   = TRUNC(ADD_MONTHS(cd_process_date,-1),'MM')     -- 業務日付前月
----                     AND xsti.report_decision_flag = 0                                              -- 速報確定フラグ = 速報
----                     AND xsti.correction_flag      = 0)                                             -- 振戻フラグ = 0 (最新のデータ)
----                   )
----          AND      xsti.item_code   = xcg4v.item_cd                                                 -- 品目コード紐付け
----          AND      xcg4v.group4_cd <> gv_discount_cd                                                -- 値引用品目(DAAE)以外
----//+ADD START 2009/05/01 T1_0861 M.Ohtsuki
----          AND    NOT EXISTS (SELECT 'X'
----                             FROM   fnd_lookup_values flv                                           --クイックコード値
----                             WHERE  flv.lookup_type = cv_sp_item_cd                                 --処理対象外特殊品目
----                             AND    flv.enabled_flag = cv_flg_y                                     --有効フラグ
----                             AND    flv.language = cv_language_ja                                   --言語
----                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  --開始日
----                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  --終了日
----                             AND    flv.lookup_code = xsti.item_code)                               --ルックアップコード=品目コード
----//+ADD END   2009/05/01 T1_0861 M.Ohtsuki
----          GROUP BY xcai.sale_base_code                                                              -- 売上拠点コード
----                  ,xsti.item_code                                                                   -- 品目コード
----                  ,TO_CHAR(xsti.selling_date,'YYYYMM')                                              -- 納品年月
----                  ,TO_CHAR(xsti.selling_date,'MM')                                                  -- 納品月
----        UNION ALL
----          SELECT  xsh.year_month                                 year_month                         -- 年月
----                 ,xsh.month                                      month                              -- 月
----                 ,xsh.sale_base_code                             sale_base_code                     -- 売上拠点コード
----                 ,xselv.item_code                                item_code                          -- 品目コード
----                 ,SUM(xselv.standard_qty)                        month_sumary_qty                   -- 基準数量
----                 ,SUM(xselv.pure_amount)                         month_sumary_pure_amount           -- 本体金額
----                 ,SUM(xselv.standard_qty * NVL(xselv.business_cost,0))
----                                                                 month_sumary_margin                -- 粗利益算出用
----          FROM   (SELECT xsehv.sales_exp_header_id               sales_exp_header_id                -- 販売実績ヘッダID
----                        ,xsehv.ship_to_customer_code             ship_to_customer_code              -- 顧客コード
----                        ,TO_CHAR(xsehv.delivery_date,'YYYYMM')   year_month                         -- 納品日(年月)
----                        ,TO_CHAR(xsehv.delivery_date,'MM')       month                              -- 納品日(月)
----                        ,DECODE(xca.rsv_sale_base_act_date                                          -- 予約売上拠点有効開始日
----                               ,gt_start_date                                                       -- 予算年度開始日
----                               ,xca.rsv_sale_base_code                                              -- 予約売上拠点コード
----                               ,xca.sale_base_code                                                  -- 売上拠点コード
----                               )                                 sale_base_code                     -- 年次切替拠点の場合、対象年度に適用される拠点を導出
----                  FROM   xxcsm_sales_exp_headers_v               xsehv                              -- 販売実績ヘッダテーブルビュー
----                        ,xxcmm_cust_accounts      xca                                               -- 顧客追加情報
----                  WHERE  TRUNC(xsehv.delivery_date,'MM') >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')-- 予算作成年度開始月－24ヶ月
----                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(gt_start_date,'MM')                -- 年度開始日前のデータが対象
----                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(cd_process_date,'MM')              -- コンカレント起動年月前のデータを対象とする
----                  AND    xsehv.ship_to_customer_code = xca.customer_code                            -- 顧客【納品先】=顧客コード(顧客追加情報)
----                 )                                               xsh                                -- 販売実績インラインビュー
----                 ,xxcsm_sales_exp_lines_v                        xselv                              -- 販売実績明細テーブルビュー
----                 ,xxcsm_tmp_cust_accounts                        xtca                               -- 顧客情報ワークテーブル（拠点のデータのみ）
----                 ,xxcsm_commodity_group4_v                       xcg4v                              -- 商品群４ビュー
----          WHERE   xsh.sales_exp_header_id = xselv.sales_exp_header_id                               -- 販売実績ヘッダIDの紐付け
----          AND     xsh.sale_base_code      = xtca.account_number                                     -- 売上拠点コード=顧客コード
----          AND     xtca.cust_account_id    = TO_NUMBER(gv_parallel_value_no)                         -- 拠点のIDにてパラレル
----          AND     xsh.sale_base_code      = NVL(gv_location_cd,xsh.sale_base_code)                  -- 入力パラメータ拠点コードNULLの場合全件
----          AND     xselv.item_code         = NVL(gv_item_no,xselv.item_code)                         -- 入力パラメータ品目コードNULLの場合全件
----          AND     xcg4v.item_cd           =  xselv.item_code                                        -- 商品群４ビューを紐付く
----          AND     xcg4v.group4_cd        <> gv_discount_cd                                          -- 値引用品目(DAAE)以外
----          AND     NOT EXISTS (SELECT xsti.base_code                                                 -- 実績振替テーブルに存在しない
----                              FROM   xxcok_selling_trns_info     xsti                               -- 実績振替テーブル
----                              WHERE  TO_CHAR(xsti.selling_date,'YYYYMM') = xsh.year_month           -- 売上計上日 = 納品日
----                              AND    xsti.cust_code     = xsh.ship_to_customer_code                 -- 顧客コード
----                              AND    xsti.item_code     = xselv.item_code                           -- 品目コード
----                              )
----//+ADD START 2009/05/01 T1_0861 M.Ohtsuki
----          AND    NOT EXISTS (SELECT 'X'
----                             FROM   fnd_lookup_values flv                                           --クイックコード値
----                             WHERE  flv.lookup_type = cv_sp_item_cd                                 --処理対象外特殊品目
----                             AND    flv.enabled_flag = cv_flg_y                                     --有効フラグ
----                             AND    flv.language = cv_language_ja                                   --言語
----                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  --開始日
----                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  --終了日
----                             AND    flv.lookup_code = xselv.item_code)                              --ルックアップコード=品目コード
----//+ADD END   2009/05/01 T1_0861 M.Ohtsuki
----          GROUP BY  xsh.sale_base_code                                                              -- 売上拠点コード
----                   ,xselv.item_code                                                                 -- 品目コード
----                   ,xsh.year_month                                                                  -- 納品年月
----                   ,xsh.month                                                                       -- 納品月
----          ) xse
----   GROUP BY  xse.year_month                                                                         -- 年月
----            ,xse.sale_base_code                                                                     -- 売上拠点コード
----            ,xse.item_code                                                                          -- 品目コード
----            ,xse.month                                                                              -- 月
----   ORDER BY  xse.sale_base_code                                                                     -- 売上拠点コード
----            ,xse.item_code                                                                          -- 品目コード
----            ,xse.year_month;                                                                        -- 年月
----//+UPD END   2009/03/18  仕様変更  S.Son
----↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
----//+UPD START 2009/08/03 0000479 T.Tsukino
----//+DEL START 2009/08/03 0000479 T.Tsukino
----↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
----   SELECT  xse.year_month                                        year_month                         -- 年月
----          ,xse.month                                             month                              -- 月
----          ,xse.sale_base_code                                    sale_base_code                     -- 売上拠点コード
----          ,xse.item_code                                         item_code                          -- 品目コード
----          ,SUM(xse.month_sumary_qty)                             month_sumary_qty                   -- 売上金額
----          ,SUM(xse.month_sumary_pure_amount)                     month_sumary_pure_amount           -- 数量
----          ,SUM(xse.month_sumary_margin)                          month_sumary_margin                -- 粗利益算出用
----   FROM   (
----          --実績振替
----          SELECT  xcai.selling_date                              year_month                         -- 売上計上日(年月)
----                 ,substrb(xcai.selling_date,5,2)                 month                              -- 売上計上日(月)
----                 ,xcai.sale_base_code                            sale_base_code                     -- 売上拠点コード
----                 ,xcai.item_code                                 item_code                          -- 品目コード
----                 ,SUM(xcai.qty)                                  month_sumary_qty                   -- 基準数量
----                 ,SUM(xcai.selling_amt)                          month_sumary_pure_amount           -- 本体金額
----                 ,SUM(xcai.qty * NVL(xcai.trading_cost,0))       month_sumary_margin                -- 粗利益算出用
----          FROM   (SELECT DISTINCT xsti.cust_code                 cust_code                          -- 顧客コード
----                        ,xsti.item_code                          item_code                          -- 品目コード
----                        ,TO_CHAR(xsti.selling_date,'YYYYMM')     selling_date                       -- 売上計上日
----                        ,DECODE(xca.rsv_sale_base_act_date                                          -- 予約売上拠点有効開始日
----                               ,gt_start_date                                                       -- 予算年度開始日
----                               ,xca.rsv_sale_base_code                                              -- 予約売上拠点コード
----                              ,xca.sale_base_code                                                  -- 売上拠点コード
----                               )                                 sale_base_code
----                        ,xsti.qty                                qty                                -- 数量
----                        ,xsti.selling_amt                        selling_amt                        -- 本体金額
----                        ,xsti.trading_cost                       trading_cost                       -- 営業原価
----                  FROM   xxcok_selling_trns_info                 xsti                               -- 実績振替テーブル
----                        ,xxcmm_cust_accounts                     xca                                -- 追加顧客情報テーブル
----                  WHERE  xsti.cust_code = xca.customer_code                                         -- 顧客コードで紐付け
----                  AND    xsti.item_code = NVL(gv_item_no,xsti.item_code)                            -- 入力パラメータ品目コードNULLの場合
----                  AND   (xsti.report_decision_flag = cv_flg_on                                         -- 速報確定フラグ = 確定
----                    OR  (TRUNC(xsti.selling_date,'MM')   = TRUNC(ADD_MONTHS(cd_process_date,-1),'MM')  -- 業務日付前月
----                           AND xsti.report_decision_flag = cv_flg_off                                           -- 速報確定フラグ = 速報
----                           AND xsti.correction_flag      = cv_flg_off)                                          -- 振戻フラグ = 0 (最新のデータ)
----                        )
----                  AND    TRUNC(xsti.selling_date,'MM')   >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')  -- 予算作成年度開始月－24ヶ月
----                  AND    TRUNC(xsti.selling_date,'MM')   <  TRUNC(gt_start_date,'MM')                  -- 年度開始日より前のデータ
----                  AND    TRUNC(xsti.selling_date,'MM')   <  TRUNC(cd_process_date,'MM')                -- コンカレント起動年月前のデータを対象とする
----                  )   xcai                                                                          -- 実績振替インラインビュー
----                 ,xxcsm_tmp_cust_accounts                       xtca                                -- 顧客情報ワークテーブル（拠点のデータのみ）
----                 ,xxcsm_commodity_group4_v                      xcg4v                               -- 商品群４ビュー
----          WHERE   xcai.sale_base_code  = xtca.account_number                                        -- 売上拠点コード = 顧客コード
----          AND     xtca.cust_account_id = TO_NUMBER(gv_parallel_value_no)                            -- 拠点のIDにてパラレル
----          AND     xcai.sale_base_code  = NVL(gv_location_cd,xcai.sale_base_code)                    -- 入力パラメータ拠点コードNULLの場合
----          AND     xcai.item_code       = xcg4v.item_cd                                              -- 品目コード紐付け
----          AND     xcg4v.group4_cd     <> gv_discount_cd                                             -- 値引用品目(DAAE)以外
----          AND     NOT EXISTS (SELECT 'X'
----                             FROM   fnd_lookup_values flv                                           -- クイックコード値
----                             WHERE  flv.lookup_type = cv_sp_item_cd                                 -- 処理対象外特殊品目
----                             AND    flv.enabled_flag = cv_flg_y                                     -- 有効フラグ
----                             AND    flv.language = cv_language_ja                                   -- 言語
----                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  -- 開始日
----                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  -- 終了日
----                             AND    flv.lookup_code = xcai.item_code)                               -- ルックアップコード=品目コード
----          GROUP BY xcai.sale_base_code                                                              -- 売上拠点コード
----                  ,xcai.item_code                                                                   -- 品目コード
----                 ,xcai.selling_date                                                                -- 納品年月
----                  ,substrb(xcai.selling_date,5,2)                                                   -- 納品月
----        UNION ALL
----          --販売実績
----          SELECT  xsh.year_month                                 year_month                         -- 年月
----                 ,xsh.month                                      month                              -- 月
----                 ,xsh.sale_base_code                             sale_base_code                     -- 売上拠点コード
----                 ,xselv.item_code                                item_code                          -- 品目コード
----                 ,SUM(xselv.standard_qty)                        month_sumary_qty                   -- 基準数量
----                 ,SUM(xselv.pure_amount)                         month_sumary_pure_amount           -- 本体金額
----                 ,SUM(xselv.standard_qty * NVL(xselv.business_cost,0))
----                                                                 month_sumary_margin                -- 粗利益算出用
----          FROM   (SELECT xsehv.sales_exp_header_id               sales_exp_header_id                -- 販売実績ヘッダID
----                        ,xsehv.ship_to_customer_code             ship_to_customer_code              -- 顧客コード
----                        ,TO_CHAR(xsehv.delivery_date,'YYYYMM')   year_month                         -- 納品日(年月)
----                        ,TO_CHAR(xsehv.delivery_date,'MM')       month                              -- 納品日(月)
----                        ,DECODE(xca.rsv_sale_base_act_date                                          -- 予約売上拠点有効開始日
----                               ,gt_start_date                                                       -- 予算年度開始日
----                               ,xca.rsv_sale_base_code                                              -- 予約売上拠点コード
----                               ,xca.sale_base_code                                                  -- 売上拠点コード
----                               )                                 sale_base_code                     -- 年次切替拠点の場合、対象年度に適用される拠点を導出
----                  FROM   xxcsm_sales_exp_headers_v               xsehv                              -- 販売実績ヘッダテーブルビュー
----                        ,xxcmm_cust_accounts      xca                                               -- 顧客追加情報
----                  WHERE  TRUNC(xsehv.delivery_date,'MM') >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')  -- 予算作成年度開始月－24ヶ月
----                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(gt_start_date,'MM')                -- 年度開始日前のデータが対象
----                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(cd_process_date,'MM')              -- コンカレント起動年月前のデータを対象とする
----                  AND    xsehv.ship_to_customer_code = xca.customer_code                            -- 顧客【納品先】=顧客コード(顧客追加情報)
----                 )                                               xsh                                -- 販売実績インラインビュー
----                 ,xxcsm_sales_exp_lines_v                        xselv                              -- 販売実績明細テーブルビュー
----                 ,xxcsm_tmp_cust_accounts                        xtca                               -- 顧客情報ワークテーブル（拠点のデータのみ）
----                 ,xxcsm_commodity_group4_v                       xcg4v                              -- 商品群４ビュー
----          WHERE   xsh.sales_exp_header_id = xselv.sales_exp_header_id                               -- 販売実績ヘッダIDの紐付け
----          AND     xsh.sale_base_code      = xtca.account_number                                     -- 売上拠点コード=顧客コード
----          AND     xtca.cust_account_id    = TO_NUMBER(gv_parallel_value_no)                         -- 拠点のIDにてパラレル
----          AND     xsh.sale_base_code      = NVL(gv_location_cd,xsh.sale_base_code)                  -- 入力パラメータ拠点コードNULLの場合全件
----          AND     xselv.item_code         = NVL(gv_item_no,xselv.item_code)                         -- 入力パラメータ品目コードNULLの場合全件
----          AND     xcg4v.item_cd           =  xselv.item_code                                        -- 商品群４ビューを紐付く
----          AND     xcg4v.group4_cd        <> gv_discount_cd                                          -- 値引用品目(DAAE)以外
----          AND    NOT EXISTS (SELECT 'X'
----                             FROM   fnd_lookup_values flv                                           --クイックコード値
----                             WHERE  flv.lookup_type = cv_sp_item_cd                                 --処理対象外特殊品目
----                             AND    flv.enabled_flag = cv_flg_y                                     --有効フラグ
----                             AND    flv.language = cv_language_ja                                   --言語
----                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  --開始日
----                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  --終了日
----                             AND    flv.lookup_code = xselv.item_code)                              --ルックアップコード=品目コード
----          GROUP BY  xsh.sale_base_code                                                              -- 売上拠点コード
----                   ,xselv.item_code                                                                 -- 品目コード
----                   ,xsh.year_month                                                                  -- 納品年月
----                   ,xsh.month                                                                       -- 納品月
----          ) xse
----   GROUP BY  xse.year_month                                                                         -- 年月
----            ,xse.sale_base_code                                                                     -- 売上拠点コード
----            ,xse.item_code                                                                          -- 品目コード
----            ,xse.month                                                                              -- 月
----   ORDER BY  xse.sale_base_code                                                                     -- 売上拠点コード
----            ,xse.item_code                                                                          -- 品目コード
----            ,xse.year_month;                                                                        -- 年月
----//+DEL END 2009/08/03 0000479 T.Tsukino
----↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--    SELECT  inn_v.year_month         year_month                                   --納品年月
--           ,inn_v.month              month                                        --納品月
--           ,inn_v.sale_base_code     sale_base_code                               --売上拠点コード
--           ,inn_v.item_code          item_code                                    --品目コード
--           ,SUM(inn_v.qty)           month_sumary_qty                             --基準数量
--           ,SUM(inn_v.pure_amount)   month_sumary_pure_amount                     --本体金額
--           ,SUM(inn_v.trading_cost)  month_sumary_margin                          --粗利益算出用
--    FROM    (
--             --------------------------------------
--             -- 実績振替（売上拠点）
--             --------------------------------------
--             SELECT  /*+ LEADING(xtca) USE_NL(xca xsti) */
--                     TO_CHAR(xsti.selling_date,'YYYYMM')     year_month           --納品年月
--                    ,TO_CHAR(xsti.selling_date,'MM')         month                --納品月
--                    ,xca.sale_base_code                      sale_base_code       --売上拠点コード
--                    ,xsti.item_code                          item_code            --品目コード
--                    ,xsti.qty                                qty                  --基準数量
--                    ,xsti.selling_amt                        pure_amount          --本体金額
--                    ,xsti.trading_cost                       trading_cost         --粗利益算出用
--             FROM    xxcsm_tmp_cust_accounts  xtca
--                    ,xxcmm_cust_accounts      xca
--                    ,xxcok_selling_trns_info  xsti
--             WHERE   xca.sale_base_code              = xtca.account_number
--               AND   (
--                      (xca.rsv_sale_base_act_date IS NULL)
--                      OR
--                      (xca.rsv_sale_base_act_date <> gt_start_date)
--                     )
--               AND   xsti.cust_code                  = xca.customer_code
--               AND   xsti.selling_date  >= ADD_MONTHS(gt_start_date,-24)
--               AND   xsti.selling_date   < gt_start_date
----//+UPD START 2009/09/11 0001180 K.Kubo
----               AND   xsti.selling_date   < cd_process_date
--               AND   xsti.selling_date   < TRUNC(cd_process_date,'MM')
----//+UPD END   2009/09/11 0001180 K.Kubo
--               AND   (
--                      (xsti.report_decision_flag   = cv_flg_on)                                --速報確定フラグ = 確定
--                      OR
----//+UPD START 2009/09/11 0001180 K.Kubo
----                      (    (xsti.selling_date = (cd_process_date-1))
--                      (    (xsti.selling_date = TRUNC(ADD_MONTHS(cd_process_date, -1),'MM'))   --業務日付前月
----//+UPD END   2009/09/11 0001180 K.Kubo
--                       AND (xsti.report_decision_flag     = cv_flg_off)                        --速報確定フラグ = 速報
--                       AND (xsti.correction_flag          = cv_flg_off)                        --振戻フラグ = 0 (最新のデータ)
--                      )
--                     )
--               AND   (
--                      (gv_location_cd IS NULL)
--                      OR
--                      (    (gv_location_cd IS NOT NULL)
--                       AND (xca.sale_base_code = gv_location_cd)
--                      )
--                     )
--               AND   (
--                      (gv_item_no IS NULL)
--                      OR
--                      (
--                       (gv_item_no IS NOT NULL)
--                       AND
--                       (xsti.item_code = gv_item_no)
--                      )
--                     )
--               AND   EXISTS (
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                       -- 値引用品目以外
----                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
----                               'X'
----                       FROM    ic_item_mst_b           iimb
----                              ,fnd_lookup_values_vl    flvv
----                              ,xxcmm_system_items_b    xsib
----                              ,gmi_item_categories     gic
----                              ,mtl_categories_b        mcb
----                              ,mtl_category_sets_b     mcsb
----                              ,fnd_id_flex_structures  fifs
----                              ,xxcsm_item_group_1_nm_v   xig1v    --商品群1桁名称
--                       SELECT /*+ LEADING(iimb) 
--                                  ORDERED
--                                  USE_NL(fifs mcsb gic mcb)
--                                  USE_NL(iimb xsib fifs mcsb gic mcb)
--                                  INDEX(mcb MTL_CATEGORIES_B_U1) 
--                               */
--                               'X'
--                       FROM    ic_item_mst_b           iimb
--                              ,xxcmm_system_items_b    xsib
--                              ,fnd_lookup_values_vl    flvv
--                              ,fnd_id_flex_structures  fifs
--                              ,mtl_category_sets_b     mcsb
--                              ,gmi_item_categories     gic
--                              ,mtl_categories_b        mcb
--                              ,fnd_lookup_values       flv
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                       WHERE   iimb.item_no                           = xsti.item_code
--                         AND   flvv.lookup_type                       = cv_lookup_type_02
--                         AND   flvv.enabled_flag                      = cv_flg_y
--                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                                          AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.attribute3                        = cv_flg_y
--                         AND   xsib.item_code                         = iimb.item_no
--                         AND   xsib.item_status                       = flvv.lookup_code
--                         AND   gic.item_id                            = iimb.item_id
--                         AND   mcb.category_id                        = gic.category_id
--                         AND   mcb.enabled_flag                       = cv_flg_y
--                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
--                         AND   mcb.segment1                          <> gv_discount_cd
--                         AND   mcsb.category_set_id                   = gic.category_set_id
--                         AND   mcsb.structure_id                      = mcb.structure_id
--                         AND   fifs.application_id                    = cn_inv_application_id
--                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
--                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
--                         AND   mcsb.structure_id                      = fifs.id_flex_num
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
--                         AND   mcb.segment1           LIKE flv.lookup_code
--                         AND   flv.lookup_type        = cv_sales_pl_item
--                         AND   flv.language           = USERENV('LANG') 
--                         AND   flv.enabled_flag       = 'Y'             
--                         AND   NVL(flv.start_date_active,cd_process_date) <= cd_process_date    -- 適用開始日
--                         AND   NVL(flv.end_date_active,cd_process_date)   >= cd_process_date    -- 適用終了日
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                         AND   ROWNUM                                 = 1
--                     )
--               AND   NOT EXISTS (
--                       -- 特殊品目は対象外
--                       SELECT  'X'
--                       FROM    fnd_lookup_values_vl flvv
--                       WHERE   flvv.lookup_type          = cv_sp_item_cd
--                         AND   flvv.enabled_flag         = cv_flg_y
--                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                             AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.lookup_code          = xsti.item_code
--                         AND   ROWNUM                    = 1
--                     )
--             --------------------------------------
--             -- 実績振替（予約売上拠点）
--             --------------------------------------
--             UNION ALL
--             SELECT  /*+ LEADING(xtca) USE_NL(xca xsti) */
--                     TO_CHAR(xsti.selling_date,'YYYYMM')     year_month
--                    ,TO_CHAR(xsti.selling_date,'MM')         month
--                    ,xca.rsv_sale_base_code                  sale_base_code
--                    ,xsti.item_code                          item_code
--                    ,xsti.qty                                qty
--                    ,xsti.selling_amt                        pure_amount
--                    ,xsti.trading_cost                       trading_cost
--             FROM    xxcsm_tmp_cust_accounts  xtca
--                    ,xxcmm_cust_accounts      xca
--                    ,xxcok_selling_trns_info  xsti
--             WHERE   xca.rsv_sale_base_code          = xtca.account_number
--               AND   xca.rsv_sale_base_act_date      = gt_start_date
--               AND   xsti.cust_code                  = xca.customer_code
--               AND   xsti.selling_date  >= ADD_MONTHS(gt_start_date,-24)
--               AND   xsti.selling_date   < gt_start_date
----//+UPD START 2009/09/11 0001180 K.Kubo
----               AND   xsti.selling_date   < cd_process_date
--               AND   xsti.selling_date   < TRUNC(cd_process_date,'MM')
----//+UPD END   2009/09/11 0001180 K.Kubo
--               AND   (
--                      (xsti.report_decision_flag   = cv_flg_on)                                --速報確定フラグ = 確定
--                      OR
----//+UPD START 2009/09/11 0001180 K.Kubo
----                      (    (xsti.selling_date = (cd_process_date-1))
--                      (    (xsti.selling_date = TRUNC(ADD_MONTHS(cd_process_date, -1),'MM'))   --業務日付前月
----//+UPD END   2009/09/11 0001180 K.Kubo
--                       AND (xsti.report_decision_flag     = cv_flg_off)                        --速報確定フラグ = 速報
--                       AND (xsti.correction_flag          = cv_flg_off)                        --振戻フラグ = 0 (最新のデータ)
--                      )
--                     )
--               AND   (
--                      (gv_location_cd IS NULL)
--                      OR
--                      (    (gv_location_cd IS NOT NULL)
--                       AND (xca.rsv_sale_base_code = gv_location_cd)
--                      )
--                     )
--               AND   (
--                      (gv_item_no IS NULL)
--                      OR
--                      (
--                       (gv_item_no IS NOT NULL)
--                       AND
--                       (xsti.item_code = gv_item_no)
--                      )
--                     )
--               AND   EXISTS (
--                       -- 値引用品目以外
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
----                               'X'
----                       FROM    ic_item_mst_b           iimb
----                              ,fnd_lookup_values_vl    flvv
----                              ,xxcmm_system_items_b    xsib
----                              ,gmi_item_categories     gic
----                              ,mtl_categories_b        mcb
----                              ,mtl_category_sets_b     mcsb
----                              ,fnd_id_flex_structures  fifs
----                              ,xxcsm_item_group_1_nm_v   xig1v    --商品群1桁名称
--                       SELECT /*+ LEADING(iimb) 
--                                  ORDERED
--                                  USE_NL(fifs mcsb gic mcb)
--                                  USE_NL(iimb xsib fifs mcsb gic mcb)
--                                  INDEX(mcb MTL_CATEGORIES_B_U1) 
--                               */
--                               'X'
--                       FROM    ic_item_mst_b           iimb
--                              ,xxcmm_system_items_b    xsib
--                              ,fnd_lookup_values_vl    flvv
--                              ,fnd_id_flex_structures  fifs
--                              ,mtl_category_sets_b     mcsb
--                              ,gmi_item_categories     gic
--                              ,mtl_categories_b        mcb
--                              ,fnd_lookup_values       flv
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                       WHERE   iimb.item_no                           = xsti.item_code
--                         AND   flvv.lookup_type                       = cv_lookup_type_02
--                         AND   flvv.enabled_flag                      = cv_flg_y
--                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                                          AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.attribute3                        = cv_flg_y
--                         AND   xsib.item_code                         = iimb.item_no
--                         AND   xsib.item_status                       = flvv.lookup_code
--                         AND   gic.item_id                            = iimb.item_id
--                         AND   mcb.category_id                        = gic.category_id
--                         AND   mcb.enabled_flag                       = cv_flg_y
--                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
--                         AND   mcb.segment1                          <> gv_discount_cd
--                         AND   mcsb.category_set_id                   = gic.category_set_id
--                         AND   mcsb.structure_id                      = mcb.structure_id
--                         AND   fifs.application_id                    = cn_inv_application_id
--                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
--                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
--                         AND   mcsb.structure_id                      = fifs.id_flex_num
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
--                         AND   mcb.segment1           LIKE flv.lookup_code
--                         AND   flv.lookup_type        = cv_sales_pl_item
--                         AND   flv.language           = USERENV('LANG') 
--                         AND   flv.enabled_flag       = 'Y'             
--                         AND   NVL(flv.start_date_active,cd_process_date) <= cd_process_date    -- 適用開始日
--                         AND   NVL(flv.end_date_active,cd_process_date)   >= cd_process_date    -- 適用終了日
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                         AND   ROWNUM                                 = 1
--                     )
--               AND   NOT EXISTS (
--                       -- 特殊品目は対象外
--                       SELECT  'X'
--                       FROM    fnd_lookup_values_vl flvv
--                       WHERE   flvv.lookup_type          = cv_sp_item_cd
--                         AND   flvv.enabled_flag         = cv_flg_y
--                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                             AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.lookup_code          = xsti.item_code
--                         AND   ROWNUM                    = 1
--                     )
--             --------------------------------------
--             -- 販売実績（売上拠点）
--             --------------------------------------
--             UNION ALL
--             SELECT  /*+ LEADING(xtca) USE_NL(xca xseh xsel) */
--                     TO_CHAR(xseh.delivery_date,'YYYYMM')             year_month
--                    ,TO_CHAR(xseh.delivery_date,'MM')                 month
--                    ,xca.sale_base_code                               sale_base_code
--                    ,xsel.item_code                                   item_code
--                    ,xsel.standard_qty                                qty
--                    ,xsel.pure_amount                                 pure_amount
--                    ,(xsel.standard_qty * NVL(xsel.business_cost,0))  trading_cost
--             FROM    xxcsm_tmp_cust_accounts  xtca
--                    ,xxcmm_cust_accounts      xca
--                    ,xxcos_sales_exp_headers  xseh
--                    ,xxcos_sales_exp_lines    xsel
--             WHERE   xca.sale_base_code              = xtca.account_number
--               AND   (
--                      (xca.rsv_sale_base_act_date IS NULL)
--                      OR
--                      (xca.rsv_sale_base_act_date <> gt_start_date)
--                     )
--               AND   xseh.ship_to_customer_code       = xca.customer_code
--               AND   xseh.delivery_date  >= ADD_MONTHS(gt_start_date,-24)
--               AND   xseh.delivery_date   < gt_start_date
----//+UPD START 2009/09/11 0001180 K.Kubo
----               AND   xseh.delivery_date   < cd_process_date
--               AND   xseh.delivery_date   < TRUNC(cd_process_date,'MM')                        --コンカレント起動年月前のデータを対象
----//+UPD END   2009/09/11 0001180 K.Kubo
--               AND   xsel.sales_exp_header_id         = xseh.sales_exp_header_id
--               AND   (
--                      (gv_location_cd IS NULL)
--                      OR
--                      (    (gv_location_cd IS NOT NULL)
--                       AND (xca.sale_base_code = gv_location_cd)
--                      )
--                     )
--               AND   (
--                      (gv_item_no IS NULL)
--                      OR
--                      (
--                       (gv_item_no IS NOT NULL)
--                       AND
--                       (xsel.item_code = gv_item_no)
--                      )
--                     )
--               AND   EXISTS (
--                       -- 値引用品目以外
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
----                               'X'
----                       FROM    ic_item_mst_b           iimb
----                              ,fnd_lookup_values_vl    flvv
----                              ,xxcmm_system_items_b    xsib
----                              ,gmi_item_categories     gic
----                              ,mtl_categories_b        mcb
----                              ,mtl_category_sets_b     mcsb
----                              ,fnd_id_flex_structures  fifs
----                              ,xxcsm_item_group_1_nm_v   xig1v    --商品群1桁名称
--                       SELECT /*+ LEADING(iimb) 
--                                  ORDERED
--                                  USE_NL(fifs mcsb gic mcb)
--                                  USE_NL(iimb xsib fifs mcsb gic mcb)
--                                  INDEX(mcb MTL_CATEGORIES_B_U1) 
--                               */
--                               'X'
--                       FROM    ic_item_mst_b           iimb
--                              ,xxcmm_system_items_b    xsib
--                              ,fnd_lookup_values_vl    flvv
--                              ,fnd_id_flex_structures  fifs
--                              ,mtl_category_sets_b     mcsb
--                              ,gmi_item_categories     gic
--                              ,mtl_categories_b        mcb
--                              ,fnd_lookup_values       flv
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                       WHERE   iimb.item_no                           = xsel.item_code
--                         AND   flvv.lookup_type                       = cv_lookup_type_02
--                         AND   flvv.enabled_flag                      = cv_flg_y
--                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                                          AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.attribute3                        = cv_flg_y
--                         AND   xsib.item_code                         = iimb.item_no
--                         AND   xsib.item_status                       = flvv.lookup_code
--                         AND   gic.item_id                            = iimb.item_id
--                         AND   mcb.category_id                        = gic.category_id
--                         AND   mcb.enabled_flag                       = cv_flg_y
--                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
--                         AND   mcb.segment1                          <> gv_discount_cd
--                         AND   mcsb.category_set_id                   = gic.category_set_id
--                         AND   mcsb.structure_id                      = mcb.structure_id
--                         AND   fifs.application_id                    = cn_inv_application_id
--                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
--                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
--                         AND   mcsb.structure_id                      = fifs.id_flex_num
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
--                         AND   mcb.segment1           LIKE flv.lookup_code
--                         AND   flv.lookup_type        = cv_sales_pl_item
--                         AND   flv.language           = USERENV('LANG') 
--                         AND   flv.enabled_flag       = 'Y'             
--                         AND   NVL(flv.start_date_active,cd_process_date) <= cd_process_date    -- 適用開始日
--                         AND   NVL(flv.end_date_active,cd_process_date)   >= cd_process_date    -- 適用終了日
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                         AND   ROWNUM                                 = 1
--                     )
--               AND   NOT EXISTS (
--                       -- 特殊品目は対象外
--                       SELECT  'X'
--                       FROM    fnd_lookup_values_vl flvv
--                       WHERE   flvv.lookup_type          = cv_sp_item_cd
--                         AND   flvv.enabled_flag         = cv_flg_y
--                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                             AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.lookup_code          = xsel.item_code
--                         AND   ROWNUM                    = 1
--                     )
--             --------------------------------------
--             -- 販売実績（予約売上拠点）
--             --------------------------------------
--             UNION ALL
--             SELECT  /*+ LEADING(xtca) USE_NL(xca xseh xsel) */
--                     TO_CHAR(xseh.delivery_date,'YYYYMM')             year_month
--                    ,TO_CHAR(xseh.delivery_date,'MM')                 month
--                    ,xca.rsv_sale_base_code                           sale_base_code
--                    ,xsel.item_code                                   item_code
--                    ,xsel.standard_qty                                qty
--                    ,xsel.pure_amount                                 pure_amount
--                    ,(xsel.standard_qty * NVL(xsel.business_cost,0))  trading_cost
--             FROM    xxcsm_tmp_cust_accounts  xtca
--                    ,xxcmm_cust_accounts      xca
--                    ,xxcos_sales_exp_headers  xseh
--                    ,xxcos_sales_exp_lines    xsel
--             WHERE   xca.rsv_sale_base_code           = xtca.account_number
--               AND   xca.rsv_sale_base_act_date       = gt_start_date
--               AND   xseh.ship_to_customer_code       = xca.customer_code
--               AND   xseh.delivery_date  >= ADD_MONTHS(gt_start_date,-24)
--               AND   xseh.delivery_date   < gt_start_date
----//+UPD START 2009/09/11 0001180 K.Kubo
----               AND   xseh.delivery_date   < cd_process_date
--               AND   xseh.delivery_date   < TRUNC(cd_process_date,'MM')                        --コンカレント起動年月前のデータを対象
----//+UPD END   2009/09/11 0001180 K.Kubo
--               AND   xsel.sales_exp_header_id         = xseh.sales_exp_header_id
--               AND   (
--                      (gv_location_cd IS NULL)
--                      OR
--                      (    (gv_location_cd IS NOT NULL)
--                       AND (xca.rsv_sale_base_code = gv_location_cd)
--                      )
--                     )
--               AND   (
--                      (gv_item_no IS NULL)
--                      OR
--                      (
--                       (gv_item_no IS NOT NULL)
--                       AND
--                       (xsel.item_code = gv_item_no)
--                      )
--                     )
--               AND   EXISTS (
--                       -- 値引用品目以外
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
----                               'X'
----                       FROM    ic_item_mst_b           iimb
----                              ,fnd_lookup_values_vl    flvv
----                              ,xxcmm_system_items_b    xsib
----                              ,gmi_item_categories     gic
----                              ,mtl_categories_b        mcb
----                              ,mtl_category_sets_b     mcsb
----                              ,fnd_id_flex_structures  fifs
----                              ,xxcsm_item_group_1_nm_v   xig1v    --商品群1桁名称
--                       SELECT /*+ LEADING(iimb) 
--                                  ORDERED
--                                  USE_NL(fifs mcsb gic mcb)
--                                  USE_NL(iimb xsib fifs mcsb gic mcb)
--                                  INDEX(mcb MTL_CATEGORIES_B_U1) 
--                               */
--                               'X'
--                       FROM    ic_item_mst_b           iimb
--                              ,xxcmm_system_items_b    xsib
--                              ,fnd_lookup_values_vl    flvv
--                              ,fnd_id_flex_structures  fifs
--                              ,mtl_category_sets_b     mcsb
--                              ,gmi_item_categories     gic
--                              ,mtl_categories_b        mcb
--                              ,fnd_lookup_values       flv
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                       WHERE   iimb.item_no                           = xsel.item_code
--                         AND   flvv.lookup_type                       = cv_lookup_type_02
--                         AND   flvv.enabled_flag                      = cv_flg_y
--                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                                          AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.attribute3                        = cv_flg_y
--                         AND   xsib.item_code                         = iimb.item_no
--                         AND   xsib.item_status                       = flvv.lookup_code
--                         AND   gic.item_id                            = iimb.item_id
--                         AND   mcb.category_id                        = gic.category_id
--                         AND   mcb.enabled_flag                       = cv_flg_y
--                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
--                         AND   mcb.segment1                          <> gv_discount_cd
--                         AND   mcsb.category_set_id                   = gic.category_set_id
--                         AND   mcsb.structure_id                      = mcb.structure_id
--                         AND   fifs.application_id                    = cn_inv_application_id
--                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
--                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
--                         AND   mcsb.structure_id                      = fifs.id_flex_num
----//+UPD START 2009/09/11 0001180 T.Tsukino
----                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
--                         AND   mcb.segment1           LIKE flv.lookup_code
--                         AND   flv.lookup_type        = cv_sales_pl_item
--                         AND   flv.language           = USERENV('LANG') 
--                         AND   flv.enabled_flag       = 'Y'             
--                         AND   NVL(flv.start_date_active,cd_process_date) <= cd_process_date    -- 適用開始日
--                         AND   NVL(flv.end_date_active,cd_process_date)   >= cd_process_date    -- 適用終了日
----//+UPD END 2009/09/11 0001180 T.Tsukino
--                         AND   ROWNUM                                 = 1
--                     )
--               AND   NOT EXISTS (
--                       -- 特殊品目は対象外
--                       SELECT  'X'
--                       FROM    fnd_lookup_values_vl flvv
--                       WHERE   flvv.lookup_type          = cv_sp_item_cd
--                         AND   flvv.enabled_flag         = cv_flg_y
--                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
--                                                             AND NVL(flvv.end_date_active,cd_process_date)
--                         AND   flvv.lookup_code          = xsel.item_code
--                         AND   ROWNUM                    = 1
--                     )
--             ) inn_v
--    GROUP BY inn_v.year_month
--            ,inn_v.month
--            ,inn_v.sale_base_code
--            ,inn_v.item_code
--    ORDER BY inn_v.sale_base_code
--            ,inn_v.item_code
--            ,inn_v.year_month
--    ;
----↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
----//+UPD END 2009/08/03 0000479 T.Tsukino
----//+UPD END   2009/06/03 T1_1174 M.Ohtsuki
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      SELECT   xwipr.subject_year         subject_year             --対象年度
              ,xwipr.month_no             month_no                 --月
              ,xwipr.year_month           year_month               --年月
              ,xwipr.location_cd          location_cd              --拠点コード
              ,xwipr.item_no              item_no                  --商品コード
              ,xwipr.item_group_no        item_group_no            --商品群コード
              ,xwipr.amount               amount                   --数量
              ,xwipr.sales_budget         sales_budget             --売上金額
              ,xwipr.amount_gross_margin  amount_gross_margin      --粗利益額
              ,xwipr.discrete_cost        discrete_cost            --営業原価
      FROM     xxcsm_wk_item_plan_result  xwipr                    --商品計画用販売実績ワークテーブル
      WHERE    NOT EXISTS (
                  -- 特殊品目は対象外
                  SELECT  'X'
                  FROM    fnd_lookup_values_vl flvv
                  WHERE   flvv.lookup_type          = cv_sp_item_cd
                    AND   flvv.enabled_flag         = cv_flg_y
                    AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                    AND NVL(flvv.end_date_active,cd_process_date)
                    AND   flvv.lookup_code          = xwipr.item_no
                    AND   ROWNUM                    = 1
               )
      ORDER BY xwipr.location_cd                                   --拠点コード
              ,xwipr.item_no                                       --商品コード
              ,xwipr.year_month                                    --年月
      ;
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    --テーブル型を定義
    TYPE sales_result_type IS TABLE OF sales_result_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    --テーブル型変数を定義
    sales_result_cur_rec  sales_result_type;
--
    --*** 対象品目の商品群コード、発売日の抽出 ***
    CURSOR group4v_start_date_cur(
                                 it_item_no  xxcsm_item_plan_result.item_no%TYPE
                                 )
    IS
--//+UPD START 2009/08/03 0000479 T.Tsukino
--//+DEL START 2009/08/03 0000479 T.Tsukino
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--      SELECT   xcg4v.group4_cd           group_cd                  --商品群コード(4桁)
--              ,xcg4v.now_business_cost   now_business_cost         --営業原価
--              ,iimb.item_no              opm_item_no               --OPM品目マスタ品目コード
--              ,iimb.attribute13          start_day                 --発売日
--      FROM     xxcsm_commodity_group4_v  xcg4v                     --商品群４ビュー
--              ,ic_item_mst_b             iimb                      --OPM品目マスタ
--      WHERE   xcg4v.item_cd(+) = iimb.item_no
--      AND     iimb.item_no = it_item_no                         --OPM品目マスタの品目コード紐付け
--↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
--//+DEL END 2009/08/03 0000479 T.Tsukino
      SELECT  /*+ LEADING(iimb) USE_NL(flvv xsib gic mcb mcsb fifs) */
              mcb.segment1                 group_cd
             ,NVL(iimb.attribute8,0)       now_business_cost
             ,iimb.item_no                 opm_item_no
             ,iimb.attribute13             start_day
      FROM    ic_item_mst_b           iimb
             ,fnd_lookup_values_vl    flvv
             ,xxcmm_system_items_b    xsib
             ,gmi_item_categories     gic
             ,mtl_categories_b        mcb
             ,mtl_category_sets_b     mcsb
             ,fnd_id_flex_structures  fifs
      WHERE   iimb.item_no                           = it_item_no
        AND   flvv.lookup_type                       = cv_lookup_type_02
        AND   flvv.enabled_flag                      = cv_flg_y
        AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                         AND NVL(flvv.end_date_active,cd_process_date)
        AND   flvv.attribute3                        = cv_flg_y
        AND   xsib.item_code                         = iimb.item_no
        AND   xsib.item_status                       = flvv.lookup_code
        AND   gic.item_id                            = iimb.item_id
        AND   mcb.category_id                        = gic.category_id
        AND   mcb.enabled_flag                       = cv_flg_y
        AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
        AND   mcsb.category_set_id                   = gic.category_set_id
        AND   mcsb.structure_id                      = mcb.structure_id
        AND   fifs.application_id                    = cn_inv_application_id
        AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
        AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
        AND   mcsb.structure_id                      = fifs.id_flex_num
--//+UPD END 2009/08/03 0000479 T.Tsukino
    ;
    group4v_start_date_cur_rec group4v_start_date_cur%ROWTYPE;
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


--ローカル変数初期化
    lv_location_cd     := NULL;         --拠点コード
    lv_item_no         := NULL;         --品目コード
    lv_location_pre    := NULL;         --前拠点コード
    lv_item_no_pre     := NULL;         --前品目コード
    lv_group_cd        := NULL;         --商品群コード
    lv_opm_item_no     := NULL;         --OPM品目マスタ品目コード
    lv_start_date      := NULL;         --発売日
    ln_amount          := 0;            --数量月計
    ln_sales_budget    := 0;            --売上月計
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    ln_margin_you      := 0;            --粗利益算出用データ
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    ln_margin          := 0;            --粗利益
    ln_result_cnt      := 0;            --販売実績抽出件数
    lb_skip_flg        := FALSE;        --スキップフラグ
    lb_group_skip_flg  := FALSE;        --商品群コード取得できないとき、スキップフラグ
    opm_item_count     := 0;
    --コンカレント起動の時期より、仮データ作るか判断します。
    IF cd_process_date >= gt_start_date THEN
    --コンカレント起動は予算年度開始日以降の場合、仮データを作らない。
      lb_create_data := FALSE;	
    ELSE
    --コンカレント起動は予算年度開始日以前の場合、仮データを作る。
      lb_create_data := TRUE;
    END IF;
    
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN sales_result_cur;
-- == 2010/03/08 V1.10 Modified START ===============================================================
--      FETCH sales_result_cur BULK COLLECT INTO sales_result_cur_rec;
--      --対象件数
--      gn_target_cnt := sales_result_cur_rec.COUNT;
--      
      <<bulk_loop>>
      LOOP
      --
      FETCH sales_result_cur BULK COLLECT INTO sales_result_cur_rec LIMIT 500000;
      --対象件数
      gn_target_cnt := gn_target_cnt + sales_result_cur_rec.COUNT;
      --
      EXIT WHEN sales_result_cur_rec.COUNT = 0;
      --
      <<sales_loop>>
-- == 2010/03/08 V1.10 Modified END   ===============================================================
      FOR i IN 1..sales_result_cur_rec.COUNT  LOOP
      EXIT WHEN gn_target_cnt = 0;
        BEGIN
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
          ln_subject_year  := sales_result_cur_rec(i).subject_year;                  --対象年度
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
          ln_year_month    := sales_result_cur_rec(i).year_month;                    --年月
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--          ln_month_no      := sales_result_cur_rec(i).month;                         --月
--          lv_location_cd   := sales_result_cur_rec(i).sale_base_code;                --拠点コード
--          lv_item_no       := sales_result_cur_rec(i).item_code;                     --品目コード
--          ln_amount        := sales_result_cur_rec(i).month_sumary_qty;              --数量月計
--          ln_sales_budget  := sales_result_cur_rec(i).month_sumary_pure_amount;      --売上月計
          ln_month_no      := sales_result_cur_rec(i).month_no;                      --月
          lv_location_cd   := sales_result_cur_rec(i).location_cd;                   --拠点コード
          lv_item_no       := sales_result_cur_rec(i).item_no;                       --品目コード
          ln_amount        := sales_result_cur_rec(i).amount;                        --数量月計
          ln_sales_budget  := sales_result_cur_rec(i).sales_budget;                  --売上月計
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--          ln_margin_you    := sales_result_cur_rec(i).month_sumary_margin;           --粗利益算出用データ
--          --粗利益の算出
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
--          ln_margin    := ln_sales_budget - ln_margin_you;                           --粗利益
          ln_margin        := sales_result_cur_rec(i).amount_gross_margin;             --粗利益額
--
          --予算年度にコンカレント起動の場合、仮データを作成
          IF lb_skip_flg = FALSE AND lb_group_skip_flg = FALSE THEN
            IF lb_create_data THEN
              --前品目データをインサートしたら、前品目コード単位で、仮データを作成
              IF (lv_location_pre IS NOT NULL AND lv_location_pre <> lv_location_cd) OR
                  (lv_item_no_pre IS NOT NULL AND lv_item_no_pre <> lv_item_no) THEN
                -- ===================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
                -- 仮データ作成処理(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
                -- ===================================
                temp_data_make(
                              lv_location_pre,              -- 前拠点コード
                              lv_item_no_pre,               -- 前品目コード
                              lv_group_cd_pre,              -- 前商品群コード
                              lv_start_date_pre,            -- 前発売日
                              ln_discrete_cost_pre,         -- 前営業原価
                              lv_errbuf,                    -- エラー・メッセージ
                              lv_retcode,                   -- リターン・コード
                              lv_errmsg);                   -- ユーザー・エラー・メッセージ
                -- 例外処理
                IF (lv_retcode <> cv_status_normal) THEN
                  --(エラー処理)
                  RAISE global_api_expt;
                END IF;
              END IF;
            END IF;
          END IF;
          --一品目目の時、品目コードが変わったとき
          IF (lv_location_pre IS NULL OR lv_location_pre <> lv_location_cd) OR 
              (lv_item_no_pre IS NULL OR lv_item_no_pre <> lv_item_no) THEN
            SAVEPOINT item_no_point;
            lb_skip_flg := FALSE;
            lb_group_skip_flg := FALSE;
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--            -- ===========================================
--            -- 商品計画用販売実績テーブルロック処理(A-9)
--            -- ===========================================
--            lock_plan_result(
--                            lv_location_cd,                     -- 拠点コード
--                            lv_item_no,                         -- 品目コード
--                            lv_errbuf,                          -- エラー・メッセージ
--                            lv_retcode,                         -- リターン・コード
--                            lv_errmsg );
--            -- 例外処理
--            IF (lv_retcode <> cv_status_normal) THEN
--              --(エラー処理)
--              RAISE item_skip_expt;
--            END IF;
----
--            -- ===========================================
--            -- 商品計画用販売実績テーブル削除処理(A-9)
--            -- ===========================================
--            delete_plan_result(
--                            lv_location_cd,                    -- 拠点コード
--                            lv_item_no,                        -- 品目コード
--                            lv_errbuf,                         -- エラー・メッセージ
--                            lv_retcode,                        -- リターン・コード
--                            lv_errmsg );
--            -- 例外処理
--            IF (lv_retcode <> cv_status_normal) THEN
--              --(エラー処理)
--              RAISE global_api_others_expt;
--            END IF;	
--            --対象品目の商品群コード、発売日を抽出
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
            -- ===================================
            -- 仮データ作成用データ抽出処理(A-4)
            -- ===================================
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
            OPEN group4v_start_date_cur(lv_item_no);
              FETCH group4v_start_date_cur INTO group4v_start_date_cur_rec;
              lv_group_cd      := group4v_start_date_cur_rec.group_cd;             --商品群コード(4桁)
              ln_discrete_cost := group4v_start_date_cur_rec.now_business_cost;    --営業原価
              lv_opm_item_no   := group4v_start_date_cur_rec.opm_item_no;          --OPM品目コード
              lv_start_date    := group4v_start_date_cur_rec.start_day;            --発売日
              IF group4v_start_date_cur%NOTFOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_xxcsm
                                                 ,iv_name         => cv_chk_err_00053
                                                 ,iv_token_name1  => cv_tkn_cd_item_cd
                                                 ,iv_token_value1 => lv_item_no
                                                 );
                lv_errbuf := lv_errmsg;
                RAISE item_skip_expt;
              END IF;
              IF lv_opm_item_no IS NOT NULL AND lv_start_date IS NULL THEN
              --発売日取得エラーメッセージ
                lv_errmsg := xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_xxcsm
                                                 ,iv_name         => cv_chk_err_00110
                                                 ,iv_token_name1  => cv_tkn_cd_deal
                                                 ,iv_token_value1 => lv_group_cd
                                                 ,iv_token_name2  => cv_tkn_cd_item_cd
                                                 ,iv_token_value2 => lv_item_no
                                                 );
                lv_errbuf := lv_errmsg;
                RAISE item_skip_expt;
              END IF;
              --商品群コードが取得できない場合、品目コード単位でスキップします。
              IF lv_group_cd IS NULL THEN 
                RAISE group_cd_expt;
              END IF;
            CLOSE group4v_start_date_cur; 
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--            --ワークテーブルにデータを登録
--            INSERT INTO xxcsm_tmp_sales_result xtsr(    -- 販売実績ワークテーブル
--               xtsr.location_cd                         -- 拠点コード
--              ,xtsr.item_no)                            -- 品目コード
--            VALUES(
--               lv_location_cd                          -- 拠点コード
--              ,lv_item_no);                             -- 品目コード
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
          END IF;
--
          --エラー発生時は、品目コード単位でスキップさせる。
          IF lb_skip_flg THEN
            RAISE item_skip_expt;
          END IF;
          IF lb_group_skip_flg THEN
            RAISE group_cd_expt;
          END IF;
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--          --対象年度算出
--          IF ln_year_month < TO_NUMBER(TO_CHAR(ADD_MONTHS(gt_start_date,-12),'YYYYMM')) THEN
--            ln_subject_year := gt_active_year - 2;
--          ELSE
--            ln_subject_year := gt_active_year - 1;
--          END IF;
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ========================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 実績情報登録処理(A-6)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ========================================
          insert_plan_result(
                             ln_subject_year              -- 対象年度
                            ,ln_year_month                -- 年月
                            ,ln_month_no                  -- 月
                            ,lv_location_cd               -- 拠点コード
                            ,lv_item_no                   -- 商品コード
                            ,lv_group_cd                  -- 商品群コー
                            ,ln_amount                    -- 数量
                            ,ln_sales_budget              -- 売上金額
                            ,ln_margin                    -- 粗利益
                            ,lv_errbuf                    -- エラー・メッセージ
                            ,lv_retcode                   -- リターン・コード
                            ,lv_errmsg);                  -- ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_others_expt;
          END IF;
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          WHEN item_skip_expt THEN
            --エラー発生データのみ
            IF group4v_start_date_cur%ISOPEN THEN
              CLOSE group4v_start_date_cur;
            END IF;
            IF (lb_skip_flg = FALSE) THEN
              fnd_file.put_line(
                              which  => FND_FILE.LOG
                             ,buff   => lv_errbuf
                             );
              fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_errmsg
                             );
              lb_skip_flg := TRUE;
              ROLLBACK TO item_no_point;
            END IF;
            gn_error_cnt := gn_error_cnt + 1;
          --商品群コード取得例外
          WHEN group_cd_expt THEN
            IF group4v_start_date_cur%ISOPEN THEN
              CLOSE group4v_start_date_cur;
            END IF;
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_group_skip_flg := TRUE;
        END;
        --前レコード保存
        lv_item_no_pre        := lv_item_no;         --品目コード保存
        lv_location_pre       := lv_location_cd;     --拠点コード保存
        lv_group_cd_pre       := lv_group_cd;        --商品群コード保存
        lv_start_date_pre     := lv_start_date;      --発売日保存
        ln_discrete_cost_pre  := ln_discrete_cost;   --営業原価保存
-- == 2010/03/08 V1.10 Modified START ===============================================================
--      END LOOP;
      END LOOP sales_loop;
      --
      END LOOP bulk_loop;
-- == 2010/03/08 V1.10 Modified END   ===============================================================
--
      --対象データ無しエラー処理
      IF gn_target_cnt = 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  => cv_xxcsm
                                              ,iv_name         => cv_chk_err_00085
                                              ,iv_token_name1  => cv_tkn_cd_year
                                              ,iv_token_value1 => gt_active_year
                                              );
        lv_errbuf := lv_errmsg;
        fnd_file.put_line(
                                which  => FND_FILE.OUTPUT
                               ,buff   => lv_errbuf
                               );
        RAISE no_date_expt;
      END IF;
      --最後の品目コードに対して、仮データを作成
      --予算年度にコンカレント起動の場合、仮データを作成
      IF lb_skip_flg = FALSE AND lb_group_skip_flg = FALSE THEN
        IF lb_create_data THEN
          -- ===================================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
          -- 仮データ作成処理(A-5)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
          -- ===================================
          temp_data_make(
                         lv_location_pre,                   -- 前拠点コード
                         lv_item_no_pre,                    -- 前品目コード
                         lv_group_cd_pre,                   -- 前商品群コード
                         lv_start_date_pre,                 -- 前発売日
                         ln_discrete_cost_pre,              -- 前営業原価
                         lv_errbuf,                         -- エラー・メッセージ
                         lv_retcode,                        -- リターン・コード
                         lv_errmsg);                        -- ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode <> cv_status_normal) THEN
            --(エラー処理)
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    CLOSE sales_result_cur;
--
  EXCEPTION
    -- *** 対象データ無しエラー ***
     WHEN no_date_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_normal;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END sales_result_select;
--
-- == 2010/03/08 V1.10 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : ins_sum_record
   * Description      : 専門店、百貨店集約処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_sum_record(
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'ins_sum_record';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    lv_errmsg         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    ln_cnt                        NUMBER;
    ln_sum_cnt                    NUMBER;
--
    -- *** ローカル・カーソル ***
    /**      拠点集約データロックカーソル       **/
    CURSOR lock_wk_item_cur
    IS
      SELECT xwipr.location_cd
      FROM   xxcsm_wk_item_plan_result  xwipr
      WHERE  xwipr.location_cd IN (--百貨店
                                   SELECT DECODE(xlllv.location_level, 'L1', xlllv.cd_level1
                                                                     , 'L2', xlllv.cd_level2
                                                                     , 'L3', xlllv.cd_level3
                                                                     , 'L4', xlllv.cd_level4
                                                                     , 'L5', xlllv.cd_level5
                                                                     , 'L6', xlllv.cd_level6) location_id
                                   FROM   xxcsm_loc_level_list_v    xlllv
                                         ,fnd_lookup_values_vl      flvv
                                   WHERE  xlllv.cd_level4    = flvv.lookup_code
                                   AND    flvv.lookup_type   = cv_lookup_dept_sum
                                   AND    flvv.enabled_flag  = cv_flg_y
                                   AND    cd_process_date    BETWEEN NVL(flvv.start_date_active, cd_process_date)
                                                             AND     NVL(flvv.end_date_active, cd_process_date)
                                   UNION
                                   --専門店
                                   SELECT DECODE(xlllv.location_level, 'L1', xlllv.cd_level1
                                                                     , 'L2', xlllv.cd_level2
                                                                     , 'L3', xlllv.cd_level3
                                                                     , 'L4', xlllv.cd_level4
                                                                     , 'L5', xlllv.cd_level5
                                                                     , 'L6', xlllv.cd_level6) location_id
                                   FROM   xxcsm_loc_level_list_v    xlllv
                                         ,fnd_lookup_values_vl      flvv
                                   WHERE  xlllv.cd_level3    = flvv.lookup_code
                                   AND    flvv.lookup_type   = cv_lookup_sp_sum
                                   AND    flvv.enabled_flag  = cv_flg_y
                                   AND    cd_process_date    BETWEEN NVL(flvv.start_date_active, cd_process_date)
                                                             AND     NVL(flvv.end_date_active, cd_process_date)
                                  )
      FOR UPDATE OF xwipr.location_cd NOWAIT
    ;
--
    /**      拠点集約データ抽出       **/
    CURSOR get_wk_item_cur
    IS
      --百貨店系
      SELECT   xwipr.subject_year               subject_year             --対象年度
              ,xwipr.month_no                   month_no                 --月
              ,xwipr.year_month                 year_month               --年月
              ,xlllv.cd_level4                  location_cd              --拠点コード
              ,xwipr.item_no                    item_no                  --商品コード
              ,xwipr.item_group_no              item_group_no            --商品群コード
              ,SUM(xwipr.amount)                amount                   --数量
              ,SUM(xwipr.sales_budget)          sales_budget             --売上金額
              ,SUM(xwipr.amount_gross_margin)   amount_gross_margin      --粗利益額
              ,xwipr.discrete_cost              discrete_cost            --営業原価
              ,cn_created_by                    created_by
              ,SYSDATE                          creation_date
              ,cn_last_updated_by               last_updated_by
              ,SYSDATE                          last_update_date
              ,cn_last_update_login             last_update_login
      FROM     xxcsm_wk_item_plan_result        xwipr
              ,xxcsm_loc_level_list_v           xlllv
              ,fnd_lookup_values_vl             flvv
      WHERE    xwipr.location_cd = DECODE(xlllv.location_level, 'L1', xlllv.cd_level1
                                                              , 'L2', xlllv.cd_level2
                                                              , 'L3', xlllv.cd_level3
                                                              , 'L4', xlllv.cd_level4
                                                              , 'L5', xlllv.cd_level5
                                                              , 'L6', xlllv.cd_level6)
      AND      xlllv.cd_level4    = flvv.lookup_code
      AND      flvv.lookup_type   = cv_lookup_dept_sum
      AND      flvv.enabled_flag  = cv_flg_y
      AND      cd_process_date    BETWEEN NVL(flvv.start_date_active, cd_process_date)
                                  AND     NVL(flvv.end_date_active, cd_process_date)
      GROUP BY xlllv.cd_level4
              ,xwipr.subject_year
              ,xwipr.month_no
              ,xwipr.year_month
              ,xwipr.item_no
              ,xwipr.item_group_no
              ,xwipr.discrete_cost
      --専門店系
      UNION ALL
      SELECT   sub.subject_year               subject_year             --対象年度
              ,sub.month_no                   month_no                 --月
              ,sub.year_month                 year_month               --年月
              ,sub.location_cd                location_cd              --拠点コード
              ,sub.item_no                    item_no                  --商品コード
              ,sub.item_group_no              item_group_no            --商品群コード
              ,SUM(sub.amount)                amount                   --数量
              ,SUM(sub.sales_budget)          sales_budget             --売上金額
              ,SUM(sub.amount_gross_margin)   amount_gross_margin      --粗利益額
              ,sub.discrete_cost              discrete_cost            --営業原価
              ,cn_created_by                  created_by
              ,SYSDATE                        creation_date
              ,cn_last_updated_by             last_updated_by
              ,SYSDATE                        last_update_date
              ,cn_last_update_login           last_update_login
      FROM     (SELECT   xwipr.subject_year               subject_year             --対象年度
                        ,xwipr.month_no                   month_no                 --月
                        ,xwipr.year_month                 year_month               --年月
                        ,gt_sp_code                       location_cd              --拠点コード
                        ,xwipr.item_no                    item_no                  --商品コード
                        ,xwipr.item_group_no              item_group_no            --商品群コード
                        ,xwipr.amount                     amount                   --数量
                        ,xwipr.sales_budget               sales_budget             --売上金額
                        ,xwipr.amount_gross_margin        amount_gross_margin      --粗利益額
                        ,xwipr.discrete_cost              discrete_cost            --営業原価
                FROM     xxcsm_wk_item_plan_result        xwipr
                        ,xxcsm_loc_level_list_v           xlllv
                        ,fnd_lookup_values_vl             flvv
                WHERE    xwipr.location_cd = DECODE(xlllv.location_level, 'L1', xlllv.cd_level1
                                                                        , 'L2', xlllv.cd_level2
                                                                        , 'L3', xlllv.cd_level3
                                                                        , 'L4', xlllv.cd_level4
                                                                        , 'L5', xlllv.cd_level5
                                                                        , 'L6', xlllv.cd_level6)
                AND      xlllv.cd_level3    = flvv.lookup_code
                AND      flvv.lookup_type   = cv_lookup_sp_sum
                AND      flvv.enabled_flag  = cv_flg_y
                AND      cd_process_date    BETWEEN NVL(flvv.start_date_active, cd_process_date)
                                                AND NVL(flvv.end_date_active, cd_process_date)
               ) sub
      GROUP BY sub.subject_year
              ,sub.month_no
              ,sub.year_month
              ,sub.location_cd
              ,sub.item_no
              ,sub.item_group_no
              ,sub.discrete_cost
    ;
    --テーブル型を定義
    TYPE get_wk_item_type IS TABLE OF get_wk_item_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    --テーブル型変数を定義
    get_wk_item_rec  get_wk_item_type;
    sum_wk_item_rec  get_wk_item_type;
    --レコード型変数を定義
    lock_wk_item_rec lock_wk_item_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --ローカル変数初期化
    ln_cnt             := 0;
    ln_sum_cnt         := 0;
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --対象レコードをロック
    OPEN  lock_wk_item_cur;
    CLOSE lock_wk_item_cur;
--
    OPEN get_wk_item_cur;
--
      <<bulk_loop>>
      LOOP
--
        FETCH get_wk_item_cur BULK COLLECT INTO get_wk_item_rec LIMIT 500000;
        --対象件数
        ln_sum_cnt := ln_sum_cnt + get_wk_item_rec.COUNT;
--
        EXIT WHEN get_wk_item_rec.COUNT = 0;
--
        <<sum_loop>>
        FOR i IN 1..get_wk_item_rec.COUNT  LOOP
--
          ln_cnt := ln_cnt + 1;
--
          sum_wk_item_rec(ln_cnt).subject_year         := get_wk_item_rec(i).subject_year;            -- 対象年度
          sum_wk_item_rec(ln_cnt).month_no             := get_wk_item_rec(i).month_no;                -- 月
          sum_wk_item_rec(ln_cnt).year_month           := get_wk_item_rec(i).year_month;              -- 年月
          sum_wk_item_rec(ln_cnt).location_cd          := get_wk_item_rec(i).location_cd;             -- 拠点コード
          sum_wk_item_rec(ln_cnt).item_no              := get_wk_item_rec(i).item_no;                 -- 品目コード
          sum_wk_item_rec(ln_cnt).item_group_no        := get_wk_item_rec(i).item_group_no;           -- 商品群コード
          sum_wk_item_rec(ln_cnt).amount               := get_wk_item_rec(i).amount;                  -- 数量月計
          sum_wk_item_rec(ln_cnt).sales_budget         := get_wk_item_rec(i).sales_budget;            -- 売上月計
          sum_wk_item_rec(ln_cnt).amount_gross_margin  := get_wk_item_rec(i).amount_gross_margin;     -- 粗利益額
          sum_wk_item_rec(ln_cnt).discrete_cost        := get_wk_item_rec(i).discrete_cost;           -- 営業原価
          sum_wk_item_rec(ln_cnt).created_by           := get_wk_item_rec(ln_cnt).created_by;         -- 作成者
          sum_wk_item_rec(ln_cnt).creation_date        := get_wk_item_rec(ln_cnt).creation_date;      -- 作成日
          sum_wk_item_rec(ln_cnt).last_updated_by      := get_wk_item_rec(ln_cnt).last_updated_by;    -- 最終更新者
          sum_wk_item_rec(ln_cnt).last_update_date     := get_wk_item_rec(ln_cnt).last_update_date;   -- 最終更新日
          sum_wk_item_rec(ln_cnt).last_update_login    := get_wk_item_rec(ln_cnt).last_update_login;  -- 最終ログインID
--
        END LOOP sum_loop;
--
      END LOOP bulk_loop;
--
    CLOSE get_wk_item_cur;
--
    IF (ln_sum_cnt > 0) THEN
      -- 集約した拠点のレコードを削除
      DELETE xxcsm_wk_item_plan_result xwipr
      WHERE  xwipr.location_cd IN (SELECT DECODE(xlllv.location_level, 'L1', xlllv.cd_level1
                                                                     , 'L2', xlllv.cd_level2
                                                                     , 'L3', xlllv.cd_level3
                                                                     , 'L4', xlllv.cd_level4
                                                                     , 'L5', xlllv.cd_level5
                                                                     , 'L6', xlllv.cd_level6)
                                   FROM   xxcsm_loc_level_list_v  xlllv
                                         ,fnd_lookup_values_vl    flvv
                                   WHERE  xlllv.cd_level4    = flvv.lookup_code
                                   AND    flvv.lookup_type   = cv_lookup_dept_sum
                                   AND    flvv.enabled_flag  = cv_flg_y
                                   AND    cd_process_date    BETWEEN NVL(flvv.start_date_active, cd_process_date)
                                                             AND     NVL(flvv.end_date_active, cd_process_date)
                                   UNION
                                   SELECT DECODE(xlllv.location_level, 'L1', xlllv.cd_level1
                                                                     , 'L2', xlllv.cd_level2
                                                                     , 'L3', xlllv.cd_level3
                                                                     , 'L4', xlllv.cd_level4
                                                                     , 'L5', xlllv.cd_level5
                                                                     , 'L6', xlllv.cd_level6)
                                   FROM   xxcsm_loc_level_list_v  xlllv
                                         ,fnd_lookup_values_vl    flvv
                                   WHERE  xlllv.cd_level3    = flvv.lookup_code
                                   AND    flvv.lookup_type   = cv_lookup_sp_sum
                                   AND    flvv.enabled_flag  = cv_flg_y
                                   AND    cd_process_date    BETWEEN NVL(flvv.start_date_active, cd_process_date)
                                                                 AND NVL(flvv.end_date_active, cd_process_date)
                                  )
      ;
--
      --集約データをインサート
      FORALL j IN 1..ln_cnt
        INSERT INTO xxcsm_wk_item_plan_result VALUES sum_wk_item_rec(j);
--
  END IF;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN check_lock_expt THEN
      IF (lock_wk_item_cur%ISOPEN) THEN
        CLOSE lock_wk_item_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  =>  cv_xxcsm
                                   ,iv_name         =>  cv_xxcsm_msg_10160
                                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_wk_item_cur%ISOPEN) THEN
        CLOSE get_wk_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_sum_record;
--
-- == 2010/03/08 V1.10 Added END   ===============================================================
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--  /***********************************************************************************
--   * Procedure Name   : delete_no_result
--   * Description      : 拠点遷移の既存データ削除(A-)
--   ***********************************************************************************/
--  PROCEDURE delete_no_result(
--    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- エラー・メッセージ
--    ov_retcode          OUT  NOCOPY VARCHAR2,                -- リターン・コード
--    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ユーザー・エラー・メッセージ
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_no_result'; -- プログラム名
----
----##############################  固定ローカル変数宣言部 START   #################################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----#####################################  固定部 END   ############################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
--  BEGIN
----
----################################  固定ステータス初期化部 START   ################################
----
--    ov_retcode := cv_status_normal;
----
----#####################################  固定部 END   #############################################
----
--    -- ***************************************
--    -- ***        実処理の記述             ***
--    -- ***       共通関数の呼び出し        ***
--    -- ***************************************
----
--    -- 削除処理
--    DELETE xxcsm_item_plan_result xipr                         --商品計画用販売実績テーブル
--    WHERE  NOT EXISTS ( SELECT 'X'
--                        FROM   xxcsm_tmp_sales_result   xtsr
--                        WHERE  xtsr.location_cd = xipr.location_cd
--                        AND    xtsr.item_no = xipr.item_no
--                      )
--    AND    xipr.subject_year >= (gt_active_year - 2)
----//+ADD START 2009/02/23 CT057 S.Son
--    AND    xipr.location_cd = NVL(gv_location_cd,xipr.location_cd)
--    AND    xipr.item_no     = NVL(gv_item_no,xipr.item_no)
--    AND    xipr.location_cd IN (SELECT  xtca.account_number
--                                FROM    xxcsm_tmp_cust_accounts   xtca                              --売上拠点コード=顧客コード
--                                WHERE   xtca.cust_account_id = TO_NUMBER(gv_parallel_value_no)      --拠点のIDにてパラレル
--                               );
----//+ADD END 2009/02/23 CT057 S.Son
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ######################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ############################################
----
--  END delete_no_result;
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ 
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';          -- プログラム名
    
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                     VARCHAR2(5000);                                 --エラー・メッセージ
    lv_retcode                    VARCHAR2(1);                                    --リターン・コード
    lv_errmsg                     VARCHAR2(5000);                                 --ユーザー・エラー・メッセージ

    -- ===============================
    -- ローカル・カーソル
    -- ===============================

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
    gn_temp_normal_cnt := 0;                    --仮データ作成成功件数
    gn_temp_error_cnt  := 0;                    --仮データ作成エラー件数
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
          lv_errbuf         -- エラー・メッセージ
         ,lv_retcode        -- リターン・コード
         ,lv_errmsg );      -- ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
--
-- == 2010/03/08 V1.10 Added START ===============================================================
    -- ===============================
    -- 専門店、百貨店集約処理(A-8)
    -- ===============================
    ins_sum_record(
          ov_errbuf  => lv_errbuf         -- エラー・メッセージ
         ,ov_retcode => lv_retcode        -- リターン・コード
         ,ov_errmsg  => lv_errmsg         -- ユーザー・エラー・メッセージ
    );
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
-- == 2010/03/08 V1.10 Added END   ===============================================================
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
    -- ===============================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
    -- 商品計画用販売実績データ削除処理(A-2)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    -- ===============================
    -- 商品計画用販売実績テーブル既存データロック処理
    lock_plan_result(
          lv_errbuf         -- エラー・メッセージ
         ,lv_retcode        -- リターン・コード
         ,lv_errmsg );      -- ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
    
    -- 商品計画用販売実績テーブル既存データ削除処理
    delete_plan_result(
          lv_errbuf         -- エラー・メッセージ
         ,lv_retcode        -- リターン・コード
         ,lv_errmsg );      -- ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
--
    -- ===============================
--//+UPD START 2010/02/09 E_本稼動_01247 S.Karikomi
    -- 販売実績抽出処理(A-3)
--//+UPD END 2010/02/09 E_本稼動_01247 S.Karikomi
    -- ===============================
    sales_result_select(
                        lv_errbuf,                         -- エラー・メッセージ
                        lv_retcode,                        -- リターン・コード
                        lv_errmsg );                       -- ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_api_expt;
    END IF;
--
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    -- ===============================
--    -- 拠点遷移既存データ削除(A-)
--    -- ===============================
--    delete_no_result(
--          lv_errbuf         -- エラー・メッセージ
--         ,lv_retcode        -- リターン・コード
--         ,lv_errmsg );      -- ユーザー・エラー・メッセージ
--    -- 例外処理
--    IF (lv_retcode <> cv_status_normal) THEN
--      --(エラー処理)
--      RAISE global_api_expt;
--    END IF;
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--
    IF gn_error_cnt > 0 OR gn_temp_error_cnt > 0 THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    errbuf                   OUT NOCOPY VARCHAR2,      -- エラー・メッセージ
    retcode                  OUT NOCOPY VARCHAR2       -- リターン・コード
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    iv_parallel_value_no     IN  VARCHAR2,             -- パラレル番号
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    iv_parallel_cnt          IN  VARCHAR2,             -- パラレル数
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    iv_location_cd           IN  VARCHAR2,             -- 拠点コード
--    iv_item_no               IN  VARCHAR2              -- 品目コード
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
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
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token               CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_temp_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00115'; -- 仮データ作成終了メッセージ
    cv_temp_success_cnt_token  CONSTANT VARCHAR2(50)  := 'TEMP_SUCCESS_COUNT';--仮データ作成成功件数
    cv_temp_error_cnt_token    CONSTANT VARCHAR2(50)  := 'TEMP_ERROR_COUNT'; -- 仮データ作成エラー件数

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
    --入力パラメータ
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    gv_parallel_value_no := iv_parallel_value_no;       --パラレル番号
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    gv_parallel_cnt      := iv_parallel_cnt;            --パラレル数
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//+DEL START 2010/02/09 E_本稼動_01247 S.Karikomi
--    gv_location_cd       := iv_location_cd;             --拠点コード
--    gv_item_no           := iv_item_no;                 --品目コード
--//+DEL END 2010/02/09 E_本稼動_01247 S.Karikomi
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ 
      ,lv_retcode  -- リターン・コード  
      ,lv_errmsg   -- ユーザー・エラー・メッセージ 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
--
    --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
      gn_temp_normal_cnt := 0;
      gn_temp_error_cnt := 0;
    END IF;
--//+ADD START 2010/02/09 E_本稼動_01247 S.Karikomi
    -- =======================
    -- 終了処理(A-7)
    -- =======================
--//+ADD END 2010/02/09 E_本稼動_01247 S.Karikomi
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    --仮データ処理件数出力
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm
                    ,iv_name         => cv_temp_rec_msg
                    ,iv_token_name1  => cv_temp_success_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_temp_normal_cnt)
                    ,iv_token_name2  => cv_temp_error_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_temp_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

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
    fnd_file.put_line(
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
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSM002A01C;
/
