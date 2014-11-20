CREATE OR REPLACE PACKAGE BODY XXCSM002A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A05C(body)
 * Description      : 商品計画単品別按分処理
 * MD.050           : 商品計画単品別按分処理 MD050_CSM_002_A05
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
 *  assign_kyoten_check         按分対象チェック(拠点チェック)(A-2)
 *  assign_deal_check           按分対象チェック(政策群チェック)(A-4)
 *  item_master_check           品目マスタチェック(A-5)
 *  item_month_data_select      商品別対象月データ取得(A-5)
 *  cost_price_select           商品単位計算(営業原価、定価、発売日取得)(A-6)
 *  sales_before_last_year_cal  商品単位計算(商品別前々年度売上金額年間計取得)(A-6)
 *  sales_last_year_cal         商品単位計算(商品別前年度販売実績データ取得)(A-6)
 *  new_item_single_year        新商品単年度実績比率算出(A-8)
 *  deal_this_month_plan        政策群単位での本年度対象月計画値(A-10)
 *  new_item_no_select          新商品計画値算出(新商品コード取得)(A-11)
 *  month_item_sales_sum        新商品計画値算出(月別単品売上金額合計取得)(A-11)
 *  get_item_lines_lock         商品計画明細テーブル既存データロック(A-12)
 *  item_lines_delete           商品計画明細テーブル既存データ削除(A-12)
 *  insert_data                 データ登録(A-12)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.0   S.Son            新規作成
 *  2008/02/06    1.1   M.Ohtsuki       ［障害CT_014］ 販売実績無しの対応
 *  2009/02/18    1.2   M.Ohtsuki       ［障害CT_033］ 予算差分チェック不具合の対応
 *  2009/03/02    1.3   M.Ohtsuki       ［障害CT_073］ 値引き用品目不具合の対応
 *  2009/05/07    1.4   T.Tsukino       ［障害T1_0792］チェックリストに出力される新商品予算の粗利益額が不正
 *  2009/05/19    1.5   T.Tsukino       ［障害T1_1069］T1_0792対応不良の対応
 *  2009/05/27    1.6   A.Sakawa         [障害T1_1173] T1_0069対応不良(0除算)対応
 *  2011/12/20    1.7   Y.Horikawa       [E_本稼動_08368、08369、08370] 営業原価の取得年度の変更
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
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; --運用日
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';
  --メッセージーコード
  cv_chk_err_00048          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';       --コンカレント入力パラメータメッセージ(拠点コード)
  cv_chk_err_00049          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00049';       --コンカレント入力パラメータメッセージ(政策群コード)
  cv_chk_err_00005          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';       --プロファイル取得エラーメッセージ
  cv_chk_err_00006          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00006';       --年間販売計画カレンダー未存在エラーメッセージ
  cv_chk_err_00004          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';       --予算年度チェックエラーメッセージ
  cv_chk_err_00024          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';       --部門マスタチェックエラーメッセージ
  cv_chk_err_00050          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00050';       --按分処理対象チェックエラーメッセージ
  cv_chk_err_00051          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00051';       --政策群予算差分エラーメッセージ
  cv_chk_err_00054          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00054';       --品目カテゴリマスタチェックエラーメッセージ
  cv_chk_err_00053          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00053';       --品目マスタチェックエラーメッセージ
  cv_chk_err_00056          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00056';       --対象データ無し
  cv_chk_err_00055          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00055';       --品目変更履歴テーブルチェックエラー
  cv_chk_err_00067          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00067';       --新商品コード抽出エラー
  cv_chk_err_00073          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00073';       --商品計画明細テーブルロック取得エラーメッセージ
  cv_chk_err_10001          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';       --対象データ0件メッセージ
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --想定外エラーメッセージ
  cv_chk_err_00110          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00110';       --発売日取得エラー
-- ADD Start 2011/12/20 Ver.1.7
  cv_chk_err_coi_00006      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006';       --在庫組織ID取得エラーメッセージ
  cv_xxcoi                  CONSTANT VARCHAR2(100) := 'XXCOI';                  --在庫領域短縮名
-- ADD End 2011/12/20 Ver.1.7

  --トークン
  cv_tkn_cd_prof            CONSTANT VARCHAR2(100) := 'PROF_NAME';               --カスタム・プロファイル・オプションの英名
  cv_tkn_cd_item            CONSTANT VARCHAR2(100) := 'ITEM';                    --必要に応じたテキスト項目
  cv_tkn_cd_kyoten          CONSTANT VARCHAR2(100) := 'KYOTEN_CD';               --入力パラメータの拠点コード
  cv_tkn_cd_deal            CONSTANT VARCHAR2(100) := 'DEAL_CD';                 --年間計画データの政策群コード
  cv_tkn_cd_year            CONSTANT VARCHAR2(100) := 'YYYY';                    --予算年度
  cv_tkn_cd_month           CONSTANT VARCHAR2(100) := 'MONTH';                   --差分存在する月
  cv_tkn_cd_item_cd         CONSTANT VARCHAR2(100) := 'ITEM_CD';                 --品目コード
-- ADD Start 2011/12/20 Ver.1.7
  cv_tkn_cd_org_cd          CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';            --在庫組織コード
-- ADD End 2011/12/20 Ver.1.7

  --
  cv_language_ja            CONSTANT VARCHAR2(2)   := USERENV('LANG');           --言語(日本語)
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                       --フラグY
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
  calendar_check_expt           EXCEPTION;     -- 年間販売計画カレンダー存在チェック
  department_check_expt         EXCEPTION;     -- 部門マスタチェックエラー
  kyoten_check_expt             EXCEPTION;     -- 按分対象チェック(拠点チェック)エラー
  no_date_expt                  EXCEPTION;     -- 対象データなしエラー
  opm_master_check_expt         EXCEPTION;     -- 品目マスタチェックエラー
  item_categories_check_expt    EXCEPTION;     -- 品目カテゴリマスタチェックエラー
  cost_price_check_expt         EXCEPTION;     -- 営業原価、定価存在チェックエラー
  check_lock_expt               EXCEPTION;     -- 販売計画テーブルロック取得エラー
  deal_check_expt               EXCEPTION;     --按分対象チェック(政策群チェック)
  new_item_select_expt          EXCEPTION;     --新商品コード抽出エラー
  deal_skip_expt                EXCEPTION;     --政策群単位でスキップ例外
  sale_start_day_expt           EXCEPTION;     --発売日取得エラー

  PRAGMA EXCEPTION_INIT(check_lock_expt,-54);   --ロック取得できないエラー

  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCSM002A05C';             -- パッケージ名
  gv_calendar_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER'; --年間販売計画カレンダープロファイル名
  gv_deal_profile      CONSTANT VARCHAR2(100) := 'XXCSM1_DEAL_CATEGORY';     --政策群品目カテゴリプロファイル名
  gv_bks_profile       CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';         --GL会計帳簿IDプロファイル名
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
  gv_disc_group_cd     CONSTANT VARCHAR2(100) := 'XXCSM1_DISCOUNT_GROUP4_CD';--値引き用品目政策群コードプロファイル名
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
-- ADD Start 2011/12/20 Ver.1.7
  cv_organization_cd   CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織コードプロファイル名
-- ADD End 2011/12/20 Ver.1.7
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_calendar_name     VARCHAR2(100);        --年間販売計画カレンダー名
  gv_deal_name         VARCHAR2(50);         --政策群コード名
  gv_bks_id            NUMBER;               --会計帳簿ID
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
  gv_discount_cd       VARCHAR2(10);         --値引き用品目政策群コードプロファイル名
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
  gt_active_year       xxcsm_item_plan_headers.plan_year%TYPE;       --対象年度
  gt_start_date        gl_periods.start_date%TYPE;                   --予算年度開始日
-- ADD Start 2011/12/20 Ver.1.7
  gn_organization_id   NUMBER;  -- 在庫組織ID
-- ADD End 2011/12/20 Ver.1.7
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    it_kyoten_cd     IN  xxcsm_item_plan_headers.location_cd%TYPE,  -- 拠点コード
    iv_deal_cd       IN  VARCHAR2,                                  --政策群コード
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- プログラム名
    cv_department_name  CONSTANT VARCHAR2(100) := 'XX03_DEPARTMENT'; -- 部門マスタ
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);     -- リターン・コード
    lv_errmsg         VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ln_carender_cnt   NUMBER;          --年間販売計画カレンダー取得数
    lv_tkn_value      VARCHAR2(4000);  --トークン値
    ln_kyoten_cnt     NUMBER;          --拠点コード取得数

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
    ln_retcode        NUMBER;            -- 年間販売計画カレンダーリターンコード
    lv_result         VARCHAR2(100);     -- 年間販売計画カレンダー有効年度処理結果(0:有効年度1の場合、1:有効年度が複数または0個の場合)
    ln_cnt            NUMBER;            -- カウンタ
    lv_pram_op_1      VARCHAR2(100);     -- パラメータメッセージ出力
    lv_pram_op_2      VARCHAR2(100);     -- パラメータメッセージ出力
-- ADD Start 2011/12/20 Ver.1.7
    lv_organization_cd  VARCHAR2(100);   -- 在庫組織コード
-- ADD End 2011/12/20 Ver.1.7
    -- *** ローカル・カーソル ***
--
      /**      年度開始日取得       **/
    CURSOR startdate_cur1
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT  gp.start_date
      SELECT  gp.start_date start_date
-- MOD End 2011/12/20 Ver.1.7
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
--①入力パラメータをメッセージ出力
    --拠点コード
    lv_pram_op_1 := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00048
                                            ,iv_token_name1  => cv_tkn_cd_kyoten
                                            ,iv_token_value1 => it_kyoten_cd
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_1);
    --政策群コード
    lv_pram_op_2 := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00049
                                           ,iv_token_name1  => cv_tkn_cd_deal
                                           ,iv_token_value1 => iv_deal_cd
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_2);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
--② プロファイル値取得
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
    --政策群コード名取得
    gv_deal_name := FND_PROFILE.VALUE(gv_deal_profile);

    IF gv_deal_name IS NULL THEN
        lv_tkn_value := gv_deal_profile;
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
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
    --値引き用品目政策群コード取得
    gv_discount_cd := FND_PROFILE.VALUE(gv_disc_group_cd);
    IF (gv_discount_cd IS NULL) THEN
       lv_tkn_value := gv_disc_group_cd;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
-- ADD Start 2011/12/20 Ver.1.7
    --在庫組織コード取得
    lv_organization_cd := FND_PROFILE.VALUE(cv_organization_cd);
    IF (lv_organization_cd IS NULL) THEN
      lv_tkn_value := cv_organization_cd;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00005
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => lv_tkn_value
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- ADD End 2011/12/20 Ver.1.7
--③ 年間販売計画カレンダー存在チェック
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT  COUNT(1)
      SELECT  COUNT(1) cnt
-- MOD End 2011/12/20 Ver.1.7
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
--④ 年間販売計画カレンダー有効年度取得
    xxcsm_common_pkg.get_yearplan_calender(
                                           id_comparison_date  => cd_creation_date
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--⑤ 拠点コード存在チェック
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT  COUNT(1)
      SELECT  COUNT(1) cnt
-- MOD End 2011/12/20 Ver.1.7
      INTO    ln_kyoten_cnt
      FROM    fnd_flex_value_sets  ffvs                                    -- 値セットヘッダ
             ,fnd_flex_values  ffv                                         -- 値セット明細
      WHERE   ffvs.flex_value_set_name =  cv_department_name               -- 部門マスタ
      AND     ffvs.flex_value_set_id = ffv.flex_value_set_id
      AND     ffv.flex_value = it_kyoten_cd;                               -- 入力パラメータ．拠点コード
      IF (ln_kyoten_cnt = 0) THEN                                          -- 拠点コード存在件数が0件の場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                                                iv_application  => cv_xxcsm
                                               ,iv_name         => cv_chk_err_00024
                                               ,iv_token_name1  => cv_tkn_cd_kyoten
                                               ,iv_token_value1 => it_kyoten_cd
                                               );
          lv_errbuf := lv_errmsg;
          RAISE department_check_expt;
      END IF;
    END;
--⑦ 予算作成年度の年度開始日を取得
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
-- ADD Start 2011/12/20 Ver.1.7
--⑧ 在庫組織IDを取得
    gn_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_cd);
    IF gn_organization_id IS NULL THEN
      lv_tkn_value := lv_organization_cd;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcoi
                                           ,iv_name         => cv_chk_err_coi_00006
                                           ,iv_token_name1  => cv_tkn_cd_org_cd
                                           ,iv_token_value1 => lv_tkn_value
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- ADD End 2011/12/20 Ver.1.7
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** 年間販売計画カレンダー未存在例外処理 ***
    WHEN calendar_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** 部門マスタチェック例外処理 ***
    WHEN department_check_expt THEN
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
  /**********************************************************************************
   * Procedure Name   : assign_kyoten_check
   * Description      : 按分対象チェック(拠点チェック)(A-2)
   ***********************************************************************************/
  PROCEDURE assign_kyoten_check(
    it_kyoten_cd     IN  xxcsm_item_plan_headers.location_cd%TYPE,       -- 拠点コード
    ov_errbuf        OUT NOCOPY VARCHAR2,                                --   エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                                --   リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                                --   ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'assign_kyoten_check'; -- プログラム名
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
    month_count  NUMBER;
--
  lt_month    xxcsm_item_plan_loc_bdgt.month_no%TYPE;   --差分存在月数

    -- *** ローカル・カーソル ***
--
  CURSOR kyoten_check_cur
  IS
      SELECT  count(xiplb.month_no) month_count                                          --月
      FROM    xxcsm_item_plan_loc_bdgt xiplb                          --商品計画拠点別予算テーブル
              ,(SELECT xipl.item_plan_header_id item_plan_header_id    --商品計画ヘッダID
                      ,xipl.month_no month_no                         --月
                      ,SUM(xipl.sales_budget) sales_budget            --売上金額
                FROM   xxcsm_item_plan_headers xiph                    --商品計画ヘッダテーブル
                      ,xxcsm_item_plan_lines xipl                     --商品計画明細テーブル
                WHERE  xiph.plan_year = gt_active_year                 --予算年度＝A-1で取得した有効年度
                AND    xiph.location_cd = it_kyoten_cd                 --拠点コード＝入力パラメータ拠点コード
                AND    xiph.item_plan_header_id = xipl.item_plan_header_id
                AND    xipl.year_bdgt_kbn = '0'                        --年間群予算区分(0：各月)
                AND    xipl.item_kbn = '0'
                GROUP BY xipl.item_plan_header_id
                        ,xipl.month_no
               ) xipl_view                                             --商品計画明細月別予算インラインビュー
      WHERE   xipl_view.item_plan_header_id = xiplb.item_plan_header_id
      AND     xipl_view.month_no = xiplb.month_no
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--        AND     (xiplb.sales_budget + xiplb.receipt_discount + xiplb.sales_discount) <> xipl_view.sales_budget
      AND     (xiplb.sales_budget + (xiplb.receipt_discount * -1) + (xiplb.sales_discount * -1)) <> xipl_view.sales_budget
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
      AND     ROWNUM = 1;

  kyoten_check_cur_rec kyoten_check_cur%ROWTYPE;
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
  lt_month := NULL;
  month_count := NULL;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      OPEN kyoten_check_cur;
      FETCH kyoten_check_cur INTO kyoten_check_cur_rec;
        month_count := kyoten_check_cur_rec.month_count;
      CLOSE kyoten_check_cur;
      IF month_count <> 0 THEN          -- 差分存在する場合
-- MOD Start 2011/12/20 Ver.1.7
--        SELECT  xiplb.month_no                                          --月
        SELECT  xiplb.month_no month_no                                 --月
-- MOD End 2011/12/20 Ver.1.7
        INTO    lt_month
        FROM    xxcsm_item_plan_loc_bdgt xiplb                          --商品計画拠点別予算テーブル
              ,(SELECT xipl.item_plan_header_id item_plan_header_id    --商品計画ヘッダID
                      ,xipl.month_no month_no                         --月
                      ,SUM(xipl.sales_budget) sales_budget            --売上金額
                FROM   xxcsm_item_plan_headers xiph                    --商品計画ヘッダテーブル
                      ,xxcsm_item_plan_lines xipl                     --商品計画明細テーブル
                WHERE  xiph.plan_year = gt_active_year                 --予算年度＝A-1で取得した有効年度
                AND    xiph.location_cd = it_kyoten_cd                 --拠点コード＝入力パラメータ拠点コード
                AND    xiph.item_plan_header_id = xipl.item_plan_header_id
                AND    xipl.year_bdgt_kbn = '0'                        --年間群予算区分(0：各月)
                AND    xipl.item_kbn = '0'
                GROUP BY xipl.item_plan_header_id
                        ,xipl.month_no
               ) xipl_view                                             --商品計画明細月別予算インラインビュー
        WHERE   xipl_view.item_plan_header_id = xiplb.item_plan_header_id
        AND     xipl_view.month_no = xiplb.month_no
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--        AND     (xiplb.sales_budget + xiplb.receipt_discount + xiplb.sales_discount) <> xipl_view.sales_budget
        AND     (xiplb.sales_budget + (xiplb.receipt_discount * -1) + (xiplb.sales_discount * -1)) <> xipl_view.sales_budget
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
        AND     ROWNUM = 1;

        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  =>  cv_xxcsm
                                             ,iv_name         =>  cv_chk_err_00050
                                             ,iv_token_name1  =>  cv_tkn_cd_year
                                             ,iv_token_value1 =>  gt_active_year
                                             ,iv_token_name2  =>  cv_tkn_cd_month
                                             ,iv_token_value2 =>  lt_month
                                             );
        lv_errbuf := lv_errmsg;
        RAISE kyoten_check_expt;
      END IF;
    END;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 按分対象チェック(拠点チェック)エラー ***
    WHEN kyoten_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END assign_kyoten_check;

  /**********************************************************************************
   * Procedure Name   : assign_deal_check
   * Description      : 按分対象チェック(政策群チェック)(A-4)
   ***********************************************************************************/
  PROCEDURE assign_deal_check(
    it_kyoten_cd        IN  xxcsm_item_plan_headers.location_cd%TYPE  -- 拠点コード
    ,it_item_group_cd   IN  xxcsm_item_plan_lines.item_group_no%TYPE  -- A-3で取得した政策群コード
    ,ov_errbuf          OUT NOCOPY VARCHAR2                           -- エラー・メッセージ
    ,ov_retcode         OUT NOCOPY VARCHAR2                           -- リターン・コード
    ,ov_errmsg          OUT NOCOPY VARCHAR2)                          -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'assign_deal_check'; -- プログラム名
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
    lt_month_deal_sales    xxcsm_item_plan_lines.sales_budget%TYPE;   --売上金額年間群計
    lt_year_deal_budget    xxcsm_item_plan_lines.sales_budget%TYPE;   --売上金額年間群予算
    -- *** ローカル・カーソル ***
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

    -- *** 按分対象チェック(政策群チェック)年間群予算取得 ***
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT xipl.sales_budget                --売上金額
      SELECT xipl.sales_budget sales_budget           --売上金額
-- MOD End 2011/12/20 Ver.1.7
      INTO   lt_year_deal_budget
      FROM   xxcsm_item_plan_headers  xiph            --商品計画ヘッダテーブル
            ,xxcsm_item_plan_lines   xipl             --商品計画明細テーブル
      WHERE  xiph.plan_year = gt_active_year          --対象年度
      AND    xiph.location_cd = it_kyoten_cd          --拠点コード
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no = it_item_group_cd    --政策群コード
      AND    xipl.item_kbn = '0'                      --商品区分(0：商品群)
      AND    xipl.year_bdgt_kbn = '1'                 --年間群予算区分(1：年間群予算)
      ;
    EXCEPTION
      WHEN no_data_found THEN
      lt_year_deal_budget := NULL;
    END;
    -- *** 按分対象チェック(政策群チェック)月別商品群別売上金額年間合計取得 ***
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT SUM(xipl.sales_budget)           --売上金額
      SELECT SUM(xipl.sales_budget) sales_budget       --売上金額
-- MOD End 2011/12/20 Ver.1.7
      INTO   lt_month_deal_sales
      FROM   xxcsm_item_plan_headers  xiph             --商品計画ヘッダテーブル
            ,xxcsm_item_plan_lines   xipl              --商品計画明細テーブル
      WHERE  xiph.plan_year = gt_active_year           --対象年度
      AND    xiph.location_cd = it_kyoten_cd           --拠点コード
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no = it_item_group_cd     --政策群コード
      AND    xipl.item_kbn = '0'                       --商品区分(0：商品群)
      AND    xipl.year_bdgt_kbn = '0'                  --年間群予算区分(0：各月)
      ;
    EXCEPTION
      WHEN no_data_found THEN
      lt_month_deal_sales := NULL;
    END;
    --按分対象チェック(政策群チェック)
    IF ((lt_year_deal_budget <> lt_month_deal_sales)
                    OR (lt_year_deal_budget IS NULL)
                    OR (lt_month_deal_sales IS NULL))THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  =>  cv_xxcsm
                                           ,iv_name         =>  cv_chk_err_00051
                                           ,iv_token_name1  =>  cv_tkn_cd_deal
                                           ,iv_token_value1 =>  it_item_group_cd
                                           );
       lv_errbuf := lv_errmsg;
       RAISE deal_check_expt;
    END IF;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 按分対象チェック(政策群チェック)エラー ***
    WHEN deal_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END assign_deal_check;

  /**********************************************************************************
   * Procedure Name   : item_master_check
   * Description      : 品目マスタチェック(A-5)
   ***********************************************************************************/
  PROCEDURE item_master_check(
    it_item_no       IN  ic_item_mst_b.item_no%TYPE,               -- 品目コード
    ov_errbuf        OUT NOCOPY VARCHAR2,                          -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                          -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                          -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_master_check'; -- プログラム名
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
    lt_item_cd  ic_item_mst_b.item_no%TYPE;  --品目コード
    lt_item_id  ic_item_mst_b.item_id%TYPE;  --品目ID

    -- *** ローカル・カーソル ***
    -- *** 品目マスタチェック ***
    CURSOR item_master_check_cur
    IS
      SELECT DISTINCT
-- MOD Start 2011/12/20 Ver.1.7
--             iimb.item_no                   --OPM品目コード
--             ,gic.item_id                   --カテゴリ品目ID
             iimb.item_no item_no           --OPM品目コード
             ,gic.item_id item_id           --カテゴリ品目ID
-- MOD End 2011/12/20 Ver.1.7
      FROM   gmi_item_categories     gic    --品目カテゴリ割当テーブル
             ,ic_item_mst_b          iimb   --OPM品目マスタ
      WHERE  iimb.item_no = it_item_no
      AND    iimb.item_id = gic.item_id(+)
      ;
    item_master_check_cur_rec item_master_check_cur%ROWTYPE;
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
      OPEN item_master_check_cur;
        FETCH item_master_check_cur INTO item_master_check_cur_rec;
        lt_item_cd := item_master_check_cur_rec.item_no;
        lt_item_id := item_master_check_cur_rec.item_id;
        IF item_master_check_cur%NOTFOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00053
                                              ,iv_token_name1  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value1 =>  it_item_no
                                              );
          lv_errbuf := lv_errmsg;
          RAISE opm_master_check_expt;
        END IF;
        IF lt_item_id IS NULL THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00054
                                              ,iv_token_name1  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value1 =>  it_item_no
                                              );
          lv_errbuf := lv_errmsg;
          RAISE item_categories_check_expt;
        END IF;
      CLOSE item_master_check_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 品目マスタチェックエラー ***
    WHEN opm_master_check_expt THEN
      IF item_master_check_cur%ISOPEN THEN
        CLOSE item_master_check_cur;
      END IF;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;  --警告
    -- *** 品目カテゴリマスタチェックエラー ***
    WHEN item_categories_check_expt THEN
      IF item_master_check_cur%ISOPEN THEN
        CLOSE item_master_check_cur;
      END IF;
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;  --警告
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
  END item_master_check;

  /**********************************************************************************
   * Procedure Name   : item_month_data_select
   * Description      : 商品別対象月データ取得(A-6)
   ***********************************************************************************/
  PROCEDURE item_month_data_select(
    it_kyoten_cd     IN  xxcsm_item_plan_result.location_cd%TYPE,    --拠点コード
    it_item_group_no IN  xxcsm_item_plan_result.item_group_no%TYPE,  --政策群コード
    it_item_no       IN  xxcsm_item_plan_result.item_no%TYPE,        --商品コード
    it_month_no      IN  xxcsm_item_plan_result.month_no%TYPE,       --月
    on_sales_budget  OUT NUMBER,                                     --売上
    on_amount        OUT NUMBER,                                     --数量
    ov_errbuf        OUT NOCOPY VARCHAR2,                                   -- エラー・メッセージ
    ov_retcode       OUT NOCOPY VARCHAR2,                                   -- リターン・コード
    ov_errmsg        OUT NOCOPY VARCHAR2)                                   -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_month_data_select'; -- プログラム名
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
    -- *** 対象月データ取得 ***
    CURSOR item_month_data_select_cur
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT xipr.sales_budget                          --売上金額
--            ,xipr.amount                                --数量
      SELECT xipr.sales_budget sales_budget             --売上金額
            ,xipr.amount       amount                   --数量
-- MOD End 2011/12/20 Ver.1.7
      FROM   xxcsm_item_plan_result xipr                --商品計画用販売実績
      WHERE  xipr.location_cd = it_kyoten_cd            --拠点コード
      AND    xipr.subject_year = (gt_active_year - 1)   --予算年度の前年度
      AND    xipr.item_group_no LIKE REPLACE (it_item_group_no,'*','_')
      AND    xipr.item_no = it_item_no                  --商品コード
      AND    xipr.month_no = it_month_no                --月
      ;
    item_month_data_select_cur_rec item_month_data_select_cur%ROWTYPE;
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
      OPEN item_month_data_select_cur;
          FETCH item_month_data_select_cur INTO item_month_data_select_cur_rec;
          on_sales_budget := item_month_data_select_cur_rec.sales_budget;
          on_amount       := item_month_data_select_cur_rec.amount;
      CLOSE item_month_data_select_cur;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END item_month_data_select;

  /**********************************************************************************
   * Procedure Name   : cost_price_select
   * Description      : 商品単位計算(営業原価、定価、発売日、単位取得)(A-6)
   ***********************************************************************************/
  PROCEDURE cost_price_select(
    it_item_group_cd  IN  xxcsm_item_plan_result.item_group_no%TYPE,         -- 政策群コード
    it_item_no        IN  xxcsm_item_plan_result.item_no%TYPE,               -- 商品コード
    on_discrete_cost  OUT NUMBER,                                            -- 営業原価
    on_fixed_price    OUT NUMBER,                                            -- 定価
    ov_sale_start_day OUT VARCHAR2,                                          -- 発売日
    on_unit_flg       OUT NUMBER,                                            -- 単位フラグ
    ov_errbuf         OUT NOCOPY VARCHAR2,                                   -- エラー・メッセージ
    ov_retcode        OUT NOCOPY VARCHAR2,                                   -- リターン・コード
    ov_errmsg         OUT NOCOPY VARCHAR2)                                   -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cost_price_select'; -- プログラム名
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
    cv_unit_kg     CONSTANT VARCHAR2(50) := 'XXCSM1_UNIT_KG_G';   --単位KG
    -- *** ローカル変数 ***
--

    -- *** ローカル・カーソル ***
-- DEL Start 2011/12/20 Ver.1.7
--    -- *** OPM品目マスタ抽出 ***
--    CURSOR opm_item_select_cur
--    IS
--      SELECT iimb.attribute8    discrete_cost    --営業原価(新)
--            ,iimb.attribute5   fixed_price       --定価(新)
--      FROM   ic_item_mst_b  iimb                 --OPM品目マスタ
--      WHERE  iimb.item_no = it_item_no           --品目コード
--      ;
--    opm_item_select_cur_rec opm_item_select_cur%ROWTYPE;
-- DEL End 2011/12/20 Ver.1.7
    -- *** 品目変更履歴営業原価抽出 ***
    CURSOR item_hst_cost_cur
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT xsibh.discrete_cost                         --営業原価
      SELECT xsibh.discrete_cost discrete_cost           --営業原価
-- MOD End 2011/12/20 Ver.1.7
      FROM   xxcmm_system_items_b_hst   xsibh            --品目変更履歴テーブル
-- MOD Start 2011/12/20 Ver.1.7
--            ,(SELECT MAX(apply_date) apply_date          --適用日
            ,(SELECT MAX(item_hst_id) item_hst_id          --品目履歴ID
-- MOD End 2011/12/20 Ver.1.7
              FROM   xxcmm_system_items_b_hst            --品目変更履歴
              WHERE  item_code = it_item_no              --品目コード
-- MOD Start 2011/12/20 Ver.1.7
--              AND    apply_date <= gt_start_date         --年度開始日以前
              AND    apply_date < gt_start_date         --年度開始日前
-- MOD End 2011/12/20 Ver.1.7
              AND    discrete_cost IS NOT NULL           --営業原価 IS NOT NULL
             ) xsibh_view
-- MOD Start 2011/12/20 Ver.1.7
--      WHERE  xsibh.apply_date = xsibh_view.apply_date    --適用日
      WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    --品目履歴ID
-- MOD End 2011/12/20 Ver.1.7
      AND    xsibh.item_code = it_item_no                --品目コード
      AND    xsibh.discrete_cost IS NOT NULL
      ;
    item_hst_cost_cur_rec item_hst_cost_cur%ROWTYPE;

    -- *** 品目変更履歴定価抽出 ***
    CURSOR item_hst_price_cur
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT xsibh.fixed_price                           --定価
      SELECT xsibh.fixed_price fixed_price               --定価
-- MOD End 2011/12/20 Ver.1.7
      FROM   xxcmm_system_items_b_hst   xsibh            --品目変更履歴テーブル
-- MOD Start 2011/12/20 Ver.1.7
--            ,(SELECT MAX(apply_date) apply_date          --適用日
            ,(SELECT MAX(item_hst_id) item_hst_id          --品目履歴ID
-- MOD End 2011/12/20 Ver.1.7
              FROM   xxcmm_system_items_b_hst            --品目変更履歴
              WHERE  item_code = it_item_no              --品目コード
-- MOD Start 2011/12/20 Ver.1.7
--              AND    apply_date <= gt_start_date         --年度開始日以前
              AND    apply_date < gt_start_date         --年度開始日前
-- MOD End 2011/12/20 Ver.1.7
              AND    fixed_price IS NOT NULL             --定価 IS NOT NULL
                ) xsibh_view
-- MOD Start 2011/12/20 Ver.1.7
--      WHERE  xsibh.apply_date = xsibh_view.apply_date    --適用日
      WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    --品目履歴ID
-- MOD End 2011/12/20 Ver.1.7
      AND    xsibh.item_code = it_item_no                --品目コード
      AND    xsibh.fixed_price IS NOT NULL
        ;
    item_hst_price_cur_rec item_hst_price_cur%ROWTYPE;
    --*** 発売日 ***
    CURSOR sale_start_day_cur
    IS
    SELECT iimb.attribute13  start_day               --発売日
      FROM   ic_item_mst_b    iimb          --OPM品目マスタ
      WHERE  iimb.item_no = it_item_no;     --品目ID
    sale_start_day_cur_rec sale_start_day_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--##################  出力変数初期化部 START   ###################
--
    on_discrete_cost         := NULL;    -- 営業原価
    on_fixed_price           := NULL;    -- 定価
    ov_sale_start_day        := NULL;    -- 発売日
    on_unit_flg              := 0;       -- 単位がkg、ｇ以外
--
--##################  出力変数初期化部 END     ###################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
-- DEL Start 2011/12/20 Ver.1.7
--    --*** 運用日＞年度開始日の時、OPM品目マスタから営業原価、定価取得 ***
--    IF cd_process_date > gt_start_date THEN
--      OPEN opm_item_select_cur;
--        FETCH opm_item_select_cur INTO opm_item_select_cur_rec;
--        on_discrete_cost := opm_item_select_cur_rec.discrete_cost; --営業原価
--        on_fixed_price := opm_item_select_cur_rec.fixed_price;     --定価
--        IF (on_discrete_cost IS NULL) OR (on_fixed_price IS NULL) THEN
--          RAISE cost_price_check_expt;
--        END IF;
--      CLOSE opm_item_select_cur;
--    ELSE
----    --*** 運用日≦年度開始日の時、品目変更履歴から、営業原価、定価を取得 ***
-- DEL End 2011/12/20 Ver.1.7
      --*** 品目変更履歴営業原価取得 ***
      OPEN item_hst_cost_cur;
        FETCH item_hst_cost_cur INTO item_hst_cost_cur_rec;
        on_discrete_cost := item_hst_cost_cur_rec.discrete_cost;   --営業原価
        IF item_hst_cost_cur%NOTFOUND THEN
          RAISE cost_price_check_expt;
        END IF;
      CLOSE item_hst_cost_cur;
      --*** 品目変更履歴定価取得 ***
      OPEN item_hst_price_cur;
        FETCH item_hst_price_cur INTO item_hst_price_cur_rec;
        on_fixed_price := item_hst_price_cur_rec.fixed_price;     --定価
        IF item_hst_price_cur%NOTFOUND THEN
          RAISE cost_price_check_expt;
        END IF;
      CLOSE item_hst_price_cur;
-- DEL Start 2011/12/20 Ver.1.7
--    END IF;
-- DEL End 2011/12/20 Ver.1.7
    ov_sale_start_day := NULL;
    -- *** 発売日取得 ***
    OPEN sale_start_day_cur;
      FETCH sale_start_day_cur INTO sale_start_day_cur_rec;
        ov_sale_start_day := sale_start_day_cur_rec.start_day;
      IF ov_sale_start_day IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00110
                                              ,iv_token_name1  =>  cv_tkn_cd_deal
                                              ,iv_token_value1 =>  it_item_group_cd
                                              ,iv_token_name2  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value2 =>  it_item_no
                                              );
        lv_errbuf := lv_errmsg;
        RAISE sale_start_day_expt;
      END IF;
   CLOSE sale_start_day_cur;

    -- *** 単位フラグ抽出 ***
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT COUNT(msib.unit_of_issue)                    --単位
      SELECT COUNT(msib.unit_of_issue) unit_flag   --単位
-- MOD End 2011/12/20 Ver.1.7
      INTO   on_unit_flg                                  --単位フラグ
      FROM    mtl_system_items_b  msib             --Disc品目マスタ
             ,fnd_lookup_values   flv              --クイックコード
      WHERE   msib.segment1 = it_item_no           --品目コード
      AND     flv.lookup_type = cv_unit_kg         --
      AND     NVL(flv.start_date_active,cd_process_date) <= cd_process_date          --開始日
      AND     NVL(flv.end_date_active,cd_process_date) >= cd_process_date            --終了日
      AND     flv.enabled_flag = cv_flg_y         --有効
      AND     flv.meaning = msib.unit_of_issue
-- MOD Start 2011/12/20 Ver.1.7
--      AND     ROWNUM = 1;
      AND     flv.language = cv_language_ja
      AND     msib.organization_id = gn_organization_id;
-- MOD End 2011/12/20 Ver.1.7
    END;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 品目変更履歴チェックエラー ***
    WHEN cost_price_check_expt THEN
-- DEL Start 2011/12/20 Ver.1.7
--      IF opm_item_select_cur%ISOPEN THEN
--        CLOSE opm_item_select_cur;
--      END IF;
-- DEL End 2011/12/20 Ver.1.7
      IF item_hst_cost_cur%ISOPEN THEN
        CLOSE item_hst_cost_cur;
      END IF;
      IF item_hst_price_cur%ISOPEN THEN
        CLOSE item_hst_price_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                               iv_application  =>  cv_xxcsm
                                              ,iv_name         =>  cv_chk_err_00055
                                              ,iv_token_name1  =>  cv_tkn_cd_deal
                                              ,iv_token_value1 =>  it_item_group_cd
                                              ,iv_token_name2  =>  cv_tkn_cd_item_cd
                                              ,iv_token_value2 =>  it_item_no
                                              );
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    WHEN sale_start_day_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END cost_price_select;

  /**********************************************************************************
   * Procedure Name   : sales_before_last_year_cal
   * Description      : 商品単位計算(商品別前々年度売上金額年間計取得)(A-6)
   ***********************************************************************************/
  PROCEDURE sales_before_last_year_cal(
    it_kyoten_cd              IN     xxcsm_item_plan_headers.location_cd%TYPE,  -- 拠点コード
    it_item_group_cd          IN     xxcsm_item_plan_lines.item_group_no%TYPE,  -- A-3で取得した政策群コード
    it_item_no                IN     xxcsm_item_plan_lines.item_no%TYPE,        -- 商品コード
    id_sale_start_date        IN     DATE,                                      -- 発売日
    on_before_last_year_sale  OUT    NUMBER,                                    -- 商品別前々年度売上金額年間計
    ov_errbuf                 OUT    NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode                OUT    NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg                 OUT    NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_before_last_year_cal'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--##################  出力変数初期化部 START   ###################
--
    on_before_last_year_sale := NULL;    -- 商品別前々年度売上金額合計
--
--##################  出力変数初期化部 END     ###################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT  SUM(xipr.sales_budget)                        --売上金額
      SELECT  SUM(xipr.sales_budget) sales_budget           --売上金額
-- MOD End 2011/12/20 Ver.1.7
      INTO    on_before_last_year_sale                      --前々年度売上金額年間計
      FROM    xxcsm_item_plan_result   xipr                 --商品計画用販売実績テーブル
      WHERE   xipr.location_cd = it_kyoten_cd               --拠点コード
      AND     xipr.item_group_no LIKE REPLACE(it_item_group_cd,'*','_')         --商品群コード
      AND     xipr.item_no = it_item_no                     --商品コード
      AND     xipr.subject_year = (gt_active_year - 2)      --前々年度
      AND     xipr.year_month >= TO_NUMBER(TO_CHAR(ADD_MONTHS(id_sale_start_date,3),'YYYYMM')) --発売日3ヶ月後の年月
      ;
    END;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END sales_before_last_year_cal;

  /**********************************************************************************
   * Procedure Name   : sales_last_year_cal
   * Description      : 商品単位計算(商品別前年度販売実績データ取得)(A-6)
   ***********************************************************************************/
  PROCEDURE sales_last_year_cal(
    it_kyoten_cd              IN      xxcsm_item_plan_headers.location_cd%TYPE, -- 拠点コード
    it_item_group_cd          IN      xxcsm_item_plan_lines.item_group_no%TYPE, -- A-3で取得した政策群コード
    it_item_no                IN      xxcsm_item_plan_lines.item_no%TYPE,       -- 商品コード
    id_start_date             IN      DATE,                                     -- 計算開始日
    on_last_year_sale         OUT     NUMBER,                                   -- 商品別前年度売上金額年間計
    on_last_year_amount       OUT     NUMBER,                                   -- 商品別前年度数量年間計
    ov_errbuf                 OUT     NOCOPY VARCHAR2,                          -- エラー・メッセージ
    ov_retcode                OUT     NOCOPY VARCHAR2,                          -- リターン・コード
    ov_errmsg                 OUT     NOCOPY VARCHAR2)                          -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_last_year_cal'; -- プログラム名
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
  CURSOR last_year_data_cur
  IS
    SELECT  SUM(xipr.sales_budget)  sales_budget         --売上金額
           ,SUM(xipr.amount)  amount                     --数量
    FROM    xxcsm_item_plan_result   xipr                --商品計画用販売実績テーブル
    WHERE   xipr.location_cd = it_kyoten_cd              --拠点コード
    AND     xipr.item_group_no LIKE REPLACE(it_item_group_cd,'*','_')        --商品群コード
    AND     xipr.item_no = it_item_no                    --商品コード
    AND     xipr.subject_year = (gt_active_year - 1)     --前年度
    AND     xipr.year_month >= TO_NUMBER(TO_CHAR(id_start_date,'YYYYMM')) --計算開始の年月
    ;
  last_year_data_cur_rec last_year_data_cur%ROWTYPE;

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################

--##################  出力変数初期化部 START   ###################
--
    on_last_year_sale        := NULL;    -- 商品別前年度売上金額合計
    on_last_year_amount      := NULL;    -- 商品別前年度数量合計
--
--##################  出力変数初期化部 END     ###################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    OPEN last_year_data_cur;
      FETCH last_year_data_cur INTO last_year_data_cur_rec;
      on_last_year_sale   := last_year_data_cur_rec.sales_budget;
      on_last_year_amount := last_year_data_cur_rec.amount;
    CLOSE last_year_data_cur;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END sales_last_year_cal;

  /**********************************************************************************
   * Procedure Name   : new_item_single_year
   * Description      : 新商品単年度実績比率算出(A-8)
   ***********************************************************************************/
  PROCEDURE new_item_single_year(
    it_kyoten_cd           IN  xxcsm_item_plan_headers.location_cd%TYPE,  -- 拠点コード
    it_item_group_cd       IN  xxcsm_item_plan_lines.item_group_no%TYPE,  -- A-3で取得した政策群コード
    on_single_result_rate  OUT  NUMBER,                                   -- 新商品単年度実績比率
    on_this_year_deal_plan OUT  NUMBER,                                   -- 商品群別本年度年間計画
    ov_errbuf              OUT NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode             OUT NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg              OUT NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_item_single_year'; -- プログラム名
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
    ln_last_year_deal_result            NUMBER;    --商品群別前年度売上実績
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
-- *** 本年度年間計画値取得 ***
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT SUM(xipl.sales_budget)                       --売上金額
      SELECT SUM(xipl.sales_budget) sales_budget          --売上金額
-- MOD End 2011/12/20 Ver.1.7
      INTO   on_this_year_deal_plan                       --本年度年間計画値
      FROM   xxcsm_item_plan_headers  xiph                --商品計画ヘッダテーブル
            ,xxcsm_item_plan_lines   xipl                 --商品計画明細テーブル
      WHERE  xiph.location_cd = it_kyoten_cd              --拠点コード
      AND    xiph.plan_year = gt_active_year              --有効年度
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no = it_item_group_cd        --商品群コード
      AND    xipl.item_kbn = '0'                          --商品区分(0：商品群)
      AND    xipl.year_bdgt_kbn = '0';                    --年間群予算区分(0：年間群予算取得できない)
    END;
    -- *** 前年度売上実績取得 ***
    BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT  SUM(sales_budget)                      --売上金額
      SELECT  SUM(sales_budget) sales_budget         --売上金額
-- MOD End 2011/12/20 Ver.1.7
      INTO    ln_last_year_deal_result               --前年度販売実績
      FROM    xxcsm_item_plan_result                 --商品計画用販売実績
      WHERE   subject_year = (gt_active_year - 1)    --対象年度＝前年度
      AND     location_cd = it_kyoten_cd             --拠点コード
      AND     item_group_no  LIKE REPLACE(it_item_group_cd,'*','_') ;      --商品群コード
    END;
    -- *** 新商品単年度実績比率算出 ***
    IF (ln_last_year_deal_result = 0) THEN
      on_single_result_rate := 1;
    ELSE
      on_single_result_rate := on_this_year_deal_plan / ln_last_year_deal_result;
    END IF;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END new_item_single_year;

  /**********************************************************************************
   * Procedure Name   : deal_this_month_plan
   * Description      : 政策群単位での本年度対象月計画値(A-10)
   ***********************************************************************************/
  PROCEDURE deal_this_month_plan(
    it_kyoten_cd           IN  xxcsm_item_plan_headers.location_cd%TYPE,  -- 拠点コード
    it_item_group_cd       IN  xxcsm_item_plan_lines.item_group_no%TYPE,  -- A-3で取得した政策群コード
    it_year_month          IN  xxcsm_item_plan_lines.year_month%TYPE,     -- 年月
    on_this_month_sale     OUT NUMBER,                                    -- 政策群単位での本年度対象月計画値
    ov_errbuf              OUT NOCOPY VARCHAR2,                           -- エラー・メッセージ
    ov_retcode             OUT NOCOPY VARCHAR2,                           -- リターン・コード
    ov_errmsg              OUT NOCOPY VARCHAR2)                           -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deal_this_month_plan'; -- プログラム名
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
  BEGIN
-- MOD Start 2011/12/20 Ver.1.7
--    SELECT  xipl.sales_budget                           --売上金額
    SELECT  xipl.sales_budget sales_budget              --売上金額
-- MOD End 2011/12/20 Ver.1.7
    INTO    on_this_month_sale                          --政策群単位での本年度対象月計画値
    FROM    xxcsm_item_plan_headers   xiph              --商品計画ヘッダテーブル
           ,xxcsm_item_plan_lines    xipl               --商品計画明細テーブル
    WHERE   xiph.plan_year = gt_active_year             --有効年度
    AND     xiph.location_cd = it_kyoten_cd             --拠点コード
    AND     xiph.item_plan_header_id = xipl.item_plan_header_id
    AND     xipl.item_group_no = it_item_group_cd       --商品群コード
    AND     xipl.year_month = it_year_month             --A-5で取得した年月
    AND     xipl.item_kbn = '0'                         --商品区分(0：商品群)
    AND     xipl.year_bdgt_kbn = '0'                    --年間群予算区分(0：年間群予算取得できない)
    ;
  END;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END deal_this_month_plan;

  /**********************************************************************************
   * Procedure Name   : new_item_no_select
   * Description      : 新商品計画値算出(新商品コード取得)(A-11)
   ***********************************************************************************/
  PROCEDURE new_item_no_select(
    it_item_group_cd     IN  xxcsm_item_plan_lines.item_group_no%TYPE,         -- A-3で取得した政策群コード
    ov_new_item_no       OUT NOCOPY VARCHAR2,                                  -- 新商品コード
--//ADD START 2009/05/19 T1_1069 T.Tsukino
    ov_new_item_cost     OUT NOCOPY VARCHAR2,                                  -- 営業原価
    ov_new_item_price    OUT NOCOPY VARCHAR2,                                  -- 定価
--//ADD END 2009/05/19 T1_1069 T.Tsukino
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- エラー・メッセージ
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- リターン・コード
    ov_errmsg            OUT NOCOPY VARCHAR2)                                  -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_item_no_select'; -- プログラム名
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
  ln_new_item_count     NUMBER;                                      --新商品コード存在数
    -- *** ローカル・カーソル ***
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
-- MOD Start 2011/12/20 Ver.1.7
--    SELECT   COUNT(DISTINCT xicv.attribute3)                          --新商品コード存在数
    SELECT   COUNT(DISTINCT xicv.attribute3) cnt                      --新商品コード存在数
-- MOD End 2011/12/20 Ver.1.7
    INTO     ln_new_item_count                                        --新商品コード存在数
    FROM     xxcsm_item_category_v        xicv                        --品目カテゴリビュー
    WHERE    xicv.segment1 LIKE REPLACE(it_item_group_cd,'*','_')     --商品群コード
    AND      xicv.attribute3 IS NOT NULL                              --新商品コード
    ;
    IF ln_new_item_count <> 1 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  =>  cv_xxcsm
                                           ,iv_name         =>  cv_chk_err_00067
                                           ,iv_token_name1  =>  cv_tkn_cd_deal
                                           ,iv_token_value1 =>  it_item_group_cd
                                           );
      lv_errbuf := lv_errmsg;
      RAISE new_item_select_expt;
    ELSE
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT   DISTINCT xicv.attribute3                                 --新商品コード
      SELECT   DISTINCT xicv.attribute3 attribute3                      --新商品コード
-- MOD End 2011/12/20 Ver.1.7
      INTO     ov_new_item_no                                           --新商品コード
      FROM     xxcsm_item_category_v        xicv                        --品目カテゴリビュー
      WHERE    xicv.segment1 LIKE REPLACE(it_item_group_cd,'*','_')     --商品群コード
      AND      xicv.attribute3 IS NOT NULL                              --新商品コード
      ;
--//ADD START 2009/05/19 T1_1069 T.Tsukino
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT xxcg3v.now_business_cost   -- 営業原価
--            ,xxcg3v.now_unit_price      -- 定価
      SELECT xxcg3v.now_business_cost now_business_cost  -- 営業原価
            ,xxcg3v.now_unit_price    now_unit_price     -- 定価
-- MOD End 2011/12/20 Ver.1.7
      INTO  ov_new_item_cost            -- 営業原価
           ,ov_new_item_price           -- 定価
      FROM  xxcsm_commodity_group3_v  xxcg3v
      WHERE xxcg3v.item_cd = ov_new_item_no
      AND   xxcg3v.group3_cd = it_item_group_cd
      ;
--//ADD END 2009/05/19 T1_1069 T.Tsukino
    END IF;
  END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --
    WHEN new_item_select_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END new_item_no_select;

  /**********************************************************************************
   * Procedure Name   : month_item_sales_sum
   * Description      : 新商品計画値算出(月別単品売上金額合計取得)(A-11)
   ***********************************************************************************/
  PROCEDURE month_item_sales_sum(
    it_header_id         IN  xxcsm_item_plan_lines.item_plan_header_id%TYPE,  -- ヘッダID
    it_item_group_cd     IN  xxcsm_item_plan_lines.item_group_no%TYPE,        -- A-3で取得した政策群コード
    it_year_month        IN  xxcsm_item_plan_lines.year_month%TYPE,           -- 年月
    on_sales_sum         OUT NUMBER,                                          -- 月別単品別売上金額合計
    on_gross_sum         OUT NUMBER,                                          -- 月別単品別粗利益額合計
    ov_errbuf            OUT NOCOPY VARCHAR2,                                 -- エラー・メッセージ
    ov_retcode           OUT NOCOPY VARCHAR2,                                 -- リターン・コード
    ov_errmsg            OUT NOCOPY VARCHAR2)                                 -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'month_item_sales_sum'; -- プログラム名
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
-- MOD Start 2011/12/20 Ver.1.7
--    SELECT   SUM(xipl.sales_budget)                    --売上金額合計
--            ,SUM(xipl.amount_gross_margin)             --粗利益額合計
    SELECT   SUM(xipl.sales_budget) sales_budget                   --売上金額合計
            ,SUM(xipl.amount_gross_margin) amount_gross_margin     --粗利益額合計
-- MOD End 2011/12/20 Ver.1.7
    INTO     on_sales_sum                              --月別単品売上金額合計
            ,on_gross_sum                              --月別単品粗利益額合計
    FROM     xxcsm_item_plan_lines   xipl              --商品計画明細テーブル
    WHERE    xipl.item_plan_header_id = it_header_id    --ヘッダID
    AND      xipl.item_group_no = it_item_group_cd  --商品群コード
    AND      xipl.year_month = it_year_month        --年月
    AND      xipl.item_kbn = '1'                    --商品区分(1：商品単品)
    ;
  END;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END month_item_sales_sum;

  /***********************************************************************************
   * Procedure Name   : get_item_lines_lock
   * Description      : 商品計画明細テーブル既存データロック(A-12)
   ***********************************************************************************/
  PROCEDURE get_item_lines_lock(
    it_kyoten_cd      IN   xxcsm_item_plan_headers.location_cd%TYPE,            -- 拠点コード
    it_header_id      IN   xxcsm_item_plan_headers.item_plan_header_id%TYPE,    -- 商品計画ヘッダID
    it_item_group_cd  IN   xxcsm_item_plan_lines.item_group_no%TYPE,            -- A-3で取得した政策群コード
    ov_errbuf         OUT  NOCOPY VARCHAR2,                                     -- エラー・メッセージ
    ov_retcode        OUT  NOCOPY VARCHAR2,                                     -- リターン・コード
    ov_errmsg         OUT  NOCOPY VARCHAR2)                                     -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_lines_lock'; -- プログラム名
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
    CURSOR get_item_lines_cur IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT xipl.item_plan_header_id                   --商品計画ヘッダID
--            ,xipl.item_group_no                         --商品群コード
      SELECT xipl.item_plan_header_id item_plan_header_id            --商品計画ヘッダID
            ,xipl.item_group_no item_group_no                        --商品群コード
-- MOD End 2011/12/20 Ver.1.7
      FROM   xxcsm_item_plan_lines xipl                 --商品計画明細テーブル
      WHERE  xipl.item_plan_header_id = it_header_id    --ヘッダID
      AND    xipl.item_group_no = it_item_group_cd      --商品群コード
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
    OPEN get_item_lines_cur;
    CLOSE get_item_lines_cur;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN check_lock_expt THEN
      IF get_item_lines_cur%ISOPEN THEN
        CLOSE get_item_lines_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  =>  cv_xxcsm
                                   ,iv_name         =>  cv_chk_err_00073
                                   ,iv_token_name1  =>  cv_tkn_cd_kyoten
                                   ,iv_token_value1 =>  it_kyoten_cd
                                   ,iv_token_name2  =>  cv_tkn_cd_deal
                                   ,iv_token_value2 =>  it_item_group_cd
                                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;

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
  END get_item_lines_lock;

  /***********************************************************************************
   * Procedure Name   : delete_item_lines
   * Description      : 商品計画明細テーブル既存データ削除(A-12)
   ***********************************************************************************/
  PROCEDURE delete_item_lines(
    it_header_id      IN   xxcsm_item_plan_headers.item_plan_header_id%TYPE,    -- 商品計画ヘッダID
    it_item_group_cd  IN   xxcsm_item_plan_lines.item_group_no%TYPE,            -- A-3で取得した政策群コード
    ov_errbuf         OUT  NOCOPY VARCHAR2,                                     -- エラー・メッセージ
    ov_retcode        OUT  NOCOPY VARCHAR2,                                     -- リターン・コード
    ov_errmsg         OUT  NOCOPY VARCHAR2)                                     -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_item_lines'; -- プログラム名
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
    DELETE xxcsm_item_plan_lines xipl                 -- 商品計画明細テーブル
    WHERE  xipl.item_plan_header_id = it_header_id    --ヘッダID
    AND    xipl.item_group_no = it_item_group_cd      --商品群コード
    AND    xipl.item_kbn <> '0';                       --商品区分(1：商品コード)
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
  END delete_item_lines;

  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録(A-12)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec        IN  xxcsm_item_plan_lines%ROWTYPE       -- 対象レコード
    ,ov_errbuf          OUT NOCOPY VARCHAR2                    -- エラー・メッセージ
    ,ov_retcode         OUT NOCOPY VARCHAR2                    -- リターン・コード
    ,ov_errmsg          OUT NOCOPY VARCHAR2)                   -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- プログラム名
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
      INSERT INTO xxcsm_item_plan_lines xxipl(     -- 商品計画明細テーブル
         xxipl.item_plan_header_id                  -- 商品計画ヘッダID
        ,xxipl.item_plan_lines_id                  -- 商品計画明細ID
        ,xxipl.year_month                          -- 年月
        ,xxipl.month_no                            -- 月
        ,xxipl.year_bdgt_kbn                       -- 年間群予算区分
        ,xxipl.item_kbn                            -- 商品区分
        ,xxipl.item_no                             -- 商品コード
        ,xxipl.item_group_no                       -- 商品群コード
        ,xxipl.amount                              -- 数量
        ,xxipl.sales_budget                        -- 売上金額
        ,xxipl.amount_gross_margin                 -- 粗利益(新)
        ,xxipl.credit_rate                         -- 掛率
        ,xxipl.margin_rate                         -- 粗利益率(新)
        ,xxipl.created_by                          -- 作成者
        ,xxipl.creation_date                       -- 作成日
        ,xxipl.last_updated_by                     -- 最終更新者
        ,xxipl.last_update_date                    -- 最終更新日
        ,xxipl.last_update_login                   -- 最終更新ログイン
        ,xxipl.request_id                          -- 要求ID
        ,xxipl.program_application_id              -- コンカレント・プログラム・アプリケーションID
        ,xxipl.program_id                          -- コンカレント・プログラムID
        ,xxipl.program_update_date)                -- プログラム更新日
      VALUES(
         ir_plan_rec.item_plan_header_id
        ,xxcsm_item_plan_lines_s01.NEXTVAL
        ,ir_plan_rec.year_month
        ,ir_plan_rec.month_no
        ,ir_plan_rec.year_bdgt_kbn
        ,ir_plan_rec.item_kbn
        ,ir_plan_rec.item_no
        ,ir_plan_rec.item_group_no
        ,NVL(ir_plan_rec.amount,0)
        ,NVL(ir_plan_rec.sales_budget,0)
        ,NVL(ir_plan_rec.amount_gross_margin,0)
        ,NVL(ir_plan_rec.credit_rate,0)
        ,NVL(ir_plan_rec.margin_rate,0)
        ,ir_plan_rec.created_by
        ,ir_plan_rec.creation_date
        ,ir_plan_rec.last_updated_by
        ,ir_plan_rec.last_update_date
        ,ir_plan_rec.last_update_login
        ,ir_plan_rec.request_id
        ,ir_plan_rec.program_application_id
        ,ir_plan_rec.program_id
        ,ir_plan_rec.program_update_date);
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
  END insert_data;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_kyoten_cd     IN  VARCHAR2,            --   拠点コード
    iv_deal_cd       IN  VARCHAR2,            --   政策群コード
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
    cv_item_status    CONSTANT VARCHAR2(100) := 'XXCMM_ITM_STATUS'; -- 品目ステータス

    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                     VARCHAR2(5000);                                 --エラー・メッセージ
    lv_retcode                    VARCHAR2(1);                                    --リターン・コード
    lv_errmsg                     VARCHAR2(5000);                                 --ユーザー・エラー・メッセージ
    lt_item_group_no              xxcsm_item_plan_lines.item_group_no%TYPE;       --商品群コード
    lt_year_month                 xxcsm_item_plan_result.year_month%TYPE;         --年月
    lt_month_no                   xxcsm_item_plan_result.month_no%TYPE;           --月
    lt_item_no                    xxcsm_item_plan_result.item_no%TYPE;            --商品コード
    ln_amount                     NUMBER;                                         --数量
    ln_sales_budget               NUMBER;                                         --売上金額
    lt_pre_item_group_no          xxcsm_item_plan_lines.item_group_no%TYPE;       --保存用商品群コード
    ln_discrete_cost              NUMBER;                                         --営業原価
    ln_fixed_price                NUMBER;                                         --定価
    ln_before_last_year_sale      NUMBER;                                         --商品別前々年度売上金額合計
    ln_last_year_sale             NUMBER;                                         --商品別前年度売上金額合計
    ln_last_year_amount           NUMBER;                                         --商品別前年度数量合計
    lv_sale_start_day             VARCHAR2(100);                                  --発売日
    ln_months                     NUMBER;                                         --発売日から年度開始日までの月数
    ln_entity_result_rate         NUMBER;                                         --既存商品の実績比率
    ln_new_two_result_rate        NUMBER;                                         --新商品2ヵ年度実績比率
    ln_single_result_rate         NUMBER;                                         --新商品単年度実績比率
    ln_month_average_sale         NUMBER;                                         --売上月平均実績
    ln_month_average_amount       NUMBER;                                         --数量月平均実績
    ln_this_year_deal_plan        NUMBER;                                         --政策群単位での本年度計画値
    ln_this_month_sale            NUMBER;                                         --政策群単位での本年度対象月計画値
    ln_deal_composition_rate      NUMBER;                                         --新商品単年度政策群構成比
    ld_start_day                  DATE;                                           --計算開始日
    ln_plan_sales_budget          NUMBER;                                         --計画データ売上金額
    ln_plan_gross_budget          NUMBER;                                         --計画データ粗利益額
    ln_plan_amount                NUMBER;                                         --計画データ数量
    ln_plan_amount_gross_margin   NUMBER;                                         --計画データ粗利益
    ln_plan_credit_rate           NUMBER;                                         --計画データ掛率
    ln_margin_rate                NUMBER;                                         --計画粗利益率
    ln_new_sales_budget           NUMBER;                                         --新商品売上金額
    ln_new_gross_budget           NUMBER;                                         --新商品粗利益額
    lv_new_item_no                VARCHAR2(10);                                   --新商品コード
    lt_new_year_month             xxcsm_item_plan_result.year_month%TYPE;         --新商品年月
    lt_new_month_no               xxcsm_item_plan_result.month_no%TYPE;           --新商品月
    lt_item_plan_header_id        xxcsm_item_plan_lines.item_plan_header_id%TYPE; --商品計画ヘッダID
    lr_plan_rec                   xxcsm_item_plan_lines%ROWTYPE;                  --テーブル型変数
    lr_new_plan_rec               xxcsm_item_plan_lines%ROWTYPE;                  --新商品登録用テーブル型変数
    ln_month_sales_sum            NUMBER;                                         --月別単品売上金額合計
    ln_month_gross_sum            NUMBER;                                         --月別単品粗利益額合計
    ln_new_plan_sales             NUMBER;                                         --新商品計画値
    ln_new_plan_gross             NUMBER;                                         --新商品計画値
    ln_unit_flg                   NUMBER;                                         --単位
    lt_kyoten_cd                  xxcsm_item_plan_headers.location_cd%TYPE;       --拠点コード
    ld_sale_start_day             DATE;                                           --発売日(日付)
    lv_no_data_msg                VARCHAR2(100);                                  --実績データ無しメッセージ
--//ADD START 2009/05/07 T1_0792 T.Tsukino
    ln_new_plan_amount            NUMBER;                                         --新商品数量
    ln_new_plan_credit            NUMBER;                                         --新商品掛率
--//ADD END 2009/05/07 T1_0792 T.Tsukino
--//ADD START 2009/05/19 T1_1069 T.Tsukino
    lv_new_item_cost              VARCHAR2(240);                                  --営業原価
    lv_new_item_price             VARCHAR2(240);                                  --定価
--//ADD END 2009/05/19 T1_1069 T.Tsukino

    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- *** A-3 商品群コード抽出 ***
    --商品計画明細テーブルに登録されている商品群コードは3桁(AAA*)を抽出する。
    CURSOR deal_select_cur
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT DISTINCT xipl.item_group_no          --商品群コード
--                     ,xipl.item_plan_header_id    --ヘッダID
      SELECT DISTINCT xipl.item_group_no item_group_no               --商品群コード
                     ,xipl.item_plan_header_id item_plan_header_id   --ヘッダID
-- MOD End 2011/12/20 Ver.1.7
      FROM   xxcsm_item_plan_headers  xiph        --商品計画ヘッダテーブル
            ,xxcsm_item_plan_lines   xipl         --商品計画明細テーブル
      WHERE  xiph.plan_year = gt_active_year      --予算年度＝A-1で取得した有効年度
      AND    xiph.location_cd = iv_kyoten_cd      --拠点コード＝パラメータ．拠点コード
      AND    xiph.item_plan_header_id = xipl.item_plan_header_id
      AND    xipl.item_group_no LIKE DECODE(iv_deal_cd,'1',xipl.item_group_no,REPLACE(iv_deal_cd,'*','_'))
      AND    xipl.item_kbn = '0'                  --商品区分(0：商品群)
                                 --入力パラメータ．政策群コードは全政策群の場合、全政策群コードを抽出
      ORDER BY xipl.item_plan_header_id           --ヘッダID
              ,xipl.item_group_no                 --商品群コード
      ;
    deal_select_cur_rec deal_select_cur%ROWTYPE;

    -- *** A-5 実績商品コード取得 ***
    CURSOR  sale_result_cur(
                           it_item_group_no  xxcsm_item_plan_lines.item_group_no%TYPE
                           )
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT   xsib.item_code                                                     --商品コード
      SELECT   xsib.item_code item_code                                         --商品コード
-- MOD End 2011/12/20 Ver.1.7
      FROM     xxcmm_system_items_b    xsib                                     --Disc品目アドオン
              ,fnd_lookup_values       flv                                      --クイックコード値
      WHERE    NVL(xsib.item_status_apply_date,cd_process_date) <= cd_process_date             --運用日
      AND      flv.lookup_code = xsib.item_status                               --品目ステータス紐付け
      AND      flv.lookup_type = cv_item_status                                 --品目ステータス
      AND      flv.language = cv_language_ja                                    --言語(日本語)
      AND      flv.attribute3 = cv_flg_y                                        --商品計画区分(Y：有効)
      AND      flv.enabled_flag = cv_flg_y                                      --有効フラグ(Y：有効)
      AND      NVL(flv.start_date_active,cd_process_date) <= cd_process_date    --開始日
      AND      NVL(flv.end_date_active,cd_process_date) >= cd_process_date      --終了日
-- MOD Start 2011/12/20 Ver.1.7
--      AND      EXISTS ( SELECT xipr.item_no
      AND      EXISTS ( SELECT xipr.item_no item_no
-- MOD End 2011/12/20 Ver.1.7
                        FROM   xxcsm_item_plan_result  xipr                     --商品計画用販売実績テーブル
                        WHERE  xipr.location_cd    = iv_kyoten_cd                               --拠点コード
                        AND    xipr.item_group_no LIKE REPLACE(it_item_group_no,'*','_')        --政策群コード
                        AND    xipr.subject_year = (gt_active_year - 1)                         --前年度
                        AND    xipr.item_no    = xsib.item_code                                 --品目コード紐付け
--//ADD START 2009/03/02 CT_073 M.Ohtsuki
                        AND    xipr.item_group_no <> gv_discount_cd                             --値引き用品目(DAAE)以外
--//ADD END   2009/03/02 CT_073 M.Ohtsuki
                      )
      ORDER BY xsib.item_code
      ;
    sale_result_cur_rec sale_result_cur%ROWTYPE;
    -- *** A-5 按分年月取得 ***
    CURSOR  year_month_select_cur(
                                 it_item_group_no xxcsm_item_plan_lines.item_group_no%TYPE
                                 )
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT   xipl.year_month                                       --年月
--               ,xipl.month_no                                        --月
      SELECT   xipl.year_month year_month                            --年月
               ,xipl.month_no month_no                               --月
-- MOD End 2011/12/20 Ver.1.7
      FROM     xxcsm_item_plan_headers  xiph                         --商品計画ヘッダテーブル
              ,xxcsm_item_plan_lines   xipl                          --商品計画明細テーブル
      WHERE    xiph.plan_year = gt_active_year                       --有効年度
      AND      xiph.location_cd = iv_kyoten_cd                       --拠点コード
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id   --ヘッダID(紐付け)
      AND      xipl.item_group_no = it_item_group_no                 --商品群コード
      AND      xipl.item_kbn = '0'
      AND      xipl.year_bdgt_kbn       = '0'
      ORDER BY xipl.year_month
      ;
    year_month_select_cur_rec year_month_select_cur%ROWTYPE;

    -- *** A-11 月別拠点別商品群別の計画データ抽出 ***
    CURSOR  kyoten_month_deal_plan_cur(
                                      it_item_group_no xxcsm_item_plan_lines.item_group_no%TYPE
                                      )
    IS
-- MOD Start 2011/12/20 Ver.1.7
--      SELECT   xipl.year_month                                       --年月
--               ,xipl.month_no                                        --月
--               ,xipl.sales_budget                                    --売上金額
--               ,xipl.amount_gross_margin                             --粗利益
      SELECT   xipl.year_month  year_month                           --年月
               ,xipl.month_no month_no                               --月
               ,xipl.sales_budget sales_budget                       --売上金額
               ,xipl.amount_gross_margin amount_gross_margin         --粗利益
-- MOD End 2011/12/20 Ver.1.7
      FROM     xxcsm_item_plan_headers  xiph                         --商品計画ヘッダテーブル
               ,xxcsm_item_plan_lines   xipl                         --商品計画明細テーブル
      WHERE    xiph.plan_year           = gt_active_year             --予算年度
      AND      xiph.location_cd         = iv_kyoten_cd               --拠点コード
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id   --商品計画ヘッダID(紐付け)
      AND      xipl.item_group_no       = it_item_group_no           --政策群コード
      AND      xipl.item_kbn            = '0'                        --商品区分(0：商品群)
      AND      xipl.year_bdgt_kbn       = '0'                        --年間群予算区分(0：年間群予算取得できない)
      ORDER BY xipl.year_month
      ;
    kyoten_month_deal_plan_cur_rec kyoten_month_deal_plan_cur%ROWTYPE;
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    -- ローカル変数初期化
    lt_pre_item_group_no := NULL;
    lt_item_no           := NULL;
    lt_kyoten_cd         := iv_kyoten_cd;
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
         lt_kyoten_cd       -- 拠点コード
         ,iv_deal_cd         --政策群コード
         ,lv_errbuf         -- エラー・メッセージ
         ,lv_retcode        -- リターン・コード
         ,lv_errmsg );
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;

    -- ===================================
    -- 按分対象チェック(拠点チェック)(A-2)
    -- ===================================
    assign_kyoten_check(
                        lt_kyoten_cd     -- 拠点コード
                       ,lv_errbuf        -- エラー・メッセージ
                       ,lv_retcode       -- リターン・コード
                       ,lv_errmsg );     -- ユーザー・エラー・メッセージ
    -- 例外処理
    IF (lv_retcode <> cv_status_normal) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    END IF;
--
    -- ===================================
    -- 処理対象政策群の抽出(A-3)
    -- ===================================
    BEGIN
      OPEN deal_select_cur;
      <<deal_check_loop>>
      LOOP
        FETCH deal_select_cur INTO deal_select_cur_rec;
        EXIT WHEN deal_select_cur%NOTFOUND;
        lt_item_group_no := deal_select_cur_rec.item_group_no;                  --商品群コード
        lt_item_plan_header_id := deal_select_cur_rec.item_plan_header_id;      --ヘッダID
        -- ===================================
        -- 按分対象チェック(政策群コード)(A-4)
        -- ===================================
        assign_deal_check(
                          lt_kyoten_cd        -- 入力パラメータ．拠点コード
                         ,lt_item_group_no    -- A-3で抽出した商品群コード
                         ,lv_errbuf           -- エラー・メッセージ
                         ,lv_retcode          -- リターン・コード
                         ,lv_errmsg);         -- ユーザー・エラー・メッセージ
        -- 例外処理
        IF (lv_retcode <> cv_status_normal) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
      END LOOP deal_check_loop;
      CLOSE deal_select_cur;
    END;
--
    --政策群コード単位で売上予算差分が存在しないと、もう一回抽出した政策群にLOOPします。
    OPEN deal_select_cur;
      <<deal_loop>>
      LOOP
      BEGIN
        FETCH deal_select_cur INTO deal_select_cur_rec;
        EXIT WHEN deal_select_cur%NOTFOUND;
        lt_item_no           := NULL;
        SAVEPOINT item_group_point;
        lt_item_group_no := deal_select_cur_rec.item_group_no;                  --商品群コード
        lt_item_plan_header_id := deal_select_cur_rec.item_plan_header_id;      --ヘッダID
        gn_target_cnt := gn_target_cnt + 1;                                     --処理件数
        -- ===================================
        -- 販売計画テーブルロック取得(A-12)
        -- ===================================
        get_item_lines_lock(
                            lt_kyoten_cd               -- 拠点コード
                           ,lt_item_plan_header_id     -- 商品計画ヘッダID
                           ,lt_item_group_no           -- A-3で取得した政策群コード
                           ,lv_errbuf                  -- エラー・メッセージ
                           ,lv_retcode                 -- リターン・コード
                           ,lv_errmsg);                -- ユーザー・エラー・メッセージ
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --警告処理
          gn_error_cnt := gn_error_cnt + 1;
          RAISE deal_skip_expt;
        END IF;

        -- ===================================
        -- 販売計画テーブル削除処理(A-12)
        -- ===================================
        delete_item_lines(
                          lt_item_plan_header_id     -- 商品計画ヘッダID
                         ,lt_item_group_no           -- A-3で取得した政策群コード
                         ,lv_errbuf                  -- エラー・メッセージ
                         ,lv_retcode                 -- リターン・コード
                         ,lv_errmsg);                -- ユーザー・エラー・メッセージ

        --例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --警告処理
          gn_error_cnt := gn_error_cnt + 1;
          RAISE deal_skip_expt;
        END IF;
--
        -- *** 商品群コード変わると、下記のデータを取得 ***
        IF (lt_pre_item_group_no IS NULL) OR (lt_pre_item_group_no <> lt_item_group_no) THEN
          -- ===================================
          -- 新商品単年度実績比率算出(A-8)
          -- ===================================
          new_item_single_year(
                             lt_kyoten_cd            -- 入力パラメータ．拠点コード
                             ,lt_item_group_no       -- A-3で抽出した商品群コード
                             ,ln_single_result_rate  -- 新商品単年度実績比率
                             ,ln_this_year_deal_plan -- 本年度年間計画値
                             ,lv_errbuf              -- エラー・メッセージ
                             ,lv_retcode             -- リターン・コード
                             ,lv_errmsg);            -- ユーザー・エラー・メッセージ
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            gn_error_cnt := gn_error_cnt +1;
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            --警告処理
            gn_error_cnt := gn_error_cnt + 1;
            RAISE deal_skip_expt;
          END IF;
        END IF;
--
        -- ===================================
        -- 集計実績商品コード取得(A-5)
        -- ===================================
        OPEN sale_result_cur(lt_item_group_no);
          <<item_loop>>
          LOOP
            FETCH sale_result_cur INTO sale_result_cur_rec;
            EXIT WHEN sale_result_cur%NOTFOUND;
            lt_item_no      :=  sale_result_cur_rec.item_code;
--
            -- =============================================
            -- 品目マスタチェック(A-5)
            -- =============================================
            item_master_check(
                              lt_item_no            -- 品目コード
                             ,lv_errbuf             -- エラー・メッセージ
                             ,lv_retcode            -- リターン・コード
                             ,lv_errmsg );          -- ユーザー・エラー・メッセージ
            -- 例外処理
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --警告処理
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;

            -- ===================================================
            -- 商品単位計算(営業原価、定価、発売日、単位取得)(A-6)
            -- ===================================================
            cost_price_select(
                            lt_item_group_no    --商品群コード
                           ,lt_item_no          --商品コード
                           ,ln_discrete_cost    -- 営業原価
                           ,ln_fixed_price      -- 定価
                           ,lv_sale_start_day   -- 発売日
                           ,ln_unit_flg         -- 単位フラグ(0：KG、G以外，1：KG、G)
                           ,lv_errbuf           -- エラー・メッセージ
                           ,lv_retcode          -- リターン・コード
                           ,lv_errmsg );        -- ユーザー・エラー・メッセージ

            -- 例外処理
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --警告処理
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
--
            -- *** 発売日から、年度開始日までの月数算出 ***
            ld_sale_start_day:=TO_DATE(lv_sale_start_day,'YYYY-MM-DD');

            ln_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(gt_start_date,'YYYYMM')||'01','YYYY-MM-DD'),
                                        TO_DATE(TO_CHAR(ld_sale_start_day,'YYYYMM')||'01','YYYY-MM-DD'));

            -- *** 既存商品或は新商品2ヵ年の場合、前々年度売上金額年間計取得 ***
            IF (ln_months > 15)  THEN
              -- =====================================================
              -- 商品単位計算(商品別前々年度売上金額年間計取得)(A-6)
              -- =====================================================
              sales_before_last_year_cal(
                                       lt_kyoten_cd               -- 拠点コード
                                       ,lt_item_group_no          -- 商品群コード
                                       ,lt_item_no                -- 商品コード
                                       ,ld_sale_start_day         -- 発売日
                                       ,ln_before_last_year_sale  -- 前々年度売上金額年間計
                                       ,lv_errbuf                 -- エラー・メッセージ
                                       ,lv_retcode                -- リターン・コード
                                       ,lv_errmsg);               -- ユーザー・エラー・メッセージ
              -- 例外処理
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              ELSIF (lv_retcode = cv_status_warn) THEN
                --警告処理
                gn_error_cnt := gn_error_cnt + 1;
                RAISE deal_skip_expt;
              END IF;
            END IF;
--
            -- *** 発売日によって、前年度売上金額年間計取得 ***
            IF (ln_months > 3)  THEN
              --新商品2ヵ年度実績の場合
              IF (ln_months > 15) AND (ln_months < 27) THEN
                ld_start_day := ADD_MONTHS(ld_sale_start_day,15);
              --既存商品或は新商品単年度の場合
              ELSE
                ld_start_day := ADD_MONTHS(ld_sale_start_day,3);
              END IF;
              -- =====================================================
              -- 商品単位計算(商品別前年度売上金額年間計取得)(A-6)
              -- =====================================================
              sales_last_year_cal(
                                lt_kyoten_cd        -- 拠点コード
                               ,lt_item_group_no    -- 商品群コード
                               ,lt_item_no          -- 商品コード
                               ,ld_start_day        -- 計算開始日
                               ,ln_last_year_sale   -- 前年度売上金額年間計
                               ,ln_last_year_amount -- 前年度数量年間計
                               ,lv_errbuf           -- エラー・メッセージ
                               ,lv_retcode          -- リターン・コード
                               ,lv_errmsg);         -- ユーザー・エラー・メッセージ
              -- 例外処理
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              ELSIF (lv_retcode = cv_status_warn) THEN
                --警告処理
                gn_error_cnt := gn_error_cnt + 1;
                RAISE deal_skip_expt;
              END IF;
            END IF;
--
            -- =============================================
            -- 按分年月取得(A-5)
            -- =============================================
            OPEN year_month_select_cur(lt_item_group_no);
              <<month_loop>>
              LOOP
                FETCH year_month_select_cur INTO year_month_select_cur_rec;
                EXIT WHEN year_month_select_cur%NOTFOUND;
                lt_year_month          := year_month_select_cur_rec.year_month;
                lt_month_no            := year_month_select_cur_rec.month_no;
                -- =====================================================
                -- 按分計算(A-10)
                -- =====================================================
                IF (ln_months >= 27) THEN
                  -- =====================================================
                  -- 対象月データ取得(A-6)
                  -- =====================================================
                  item_month_data_select(
                                        lt_kyoten_cd       --拠点コード
                                       ,lt_item_group_no   --政策群コード
                                       ,lt_item_no         --商品コード
                                       ,lt_month_no        --月
                                       ,ln_sales_budget    --売上
                                       ,ln_amount          --数量
                                       ,lv_errbuf          --エラー・メッセージ
                                       ,lv_retcode         --リターン・コード
                                       ,lv_errmsg);        --ユーザー・エラー・メッセージ
                  -- 例外処理
                  IF (lv_retcode = cv_status_error) THEN
                    --(エラー処理)
                    gn_error_cnt := gn_error_cnt +1;
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    --警告処理
                    gn_error_cnt := gn_error_cnt + 1;
                    RAISE deal_skip_expt;
                  END IF;

                  --①既存商品の計画データ作成
                  --既存商品実績比率算出

                  IF (ln_before_last_year_sale = 0) THEN
                    ln_entity_result_rate := 1;
                  ELSE
                    ln_entity_result_rate := ln_last_year_sale / ln_before_last_year_sale;
                  END IF;
                  IF (ln_entity_result_rate <= 0.5)
                    OR (ln_entity_result_rate >= 2)
                    OR (ln_entity_result_rate IS NULL)
                  THEN
                      ln_entity_result_rate := 1;
                  END IF;

                  --売上金額
                  ln_plan_sales_budget        := ROUND((ln_sales_budget * ln_entity_result_rate),-3);

                  --数量
                  IF ln_unit_flg = 0 THEN
                    ln_plan_amount              := ROUND((ln_amount * ln_entity_result_rate),0);
                  ELSE
                    ln_plan_amount              := ROUND((ln_amount * ln_entity_result_rate),1);
                  END IF;
                  --粗利益
                  ln_plan_amount_gross_margin := ROUND((ln_plan_sales_budget - (ln_plan_amount * ln_discrete_cost)),-3);
                  --掛率
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--                  IF (ln_plan_amount = 0) THEN
                  IF ((ln_plan_amount * ln_fixed_price) = 0) THEN
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
                    ln_plan_credit_rate := 0;
                  ELSE
                    ln_plan_credit_rate         := ROUND(((ln_plan_sales_budget / (ln_plan_amount * ln_fixed_price)) * 100),2);
                  END IF;

                  --粗利益率
                  IF (ln_plan_sales_budget = 0) THEN
                    ln_margin_rate := 0;
                  ELSE
                    ln_margin_rate              := ROUND(((ln_plan_amount_gross_margin / ln_plan_sales_budget) * 100),2);
                  END IF;

--
                ELSIF (ln_months > 3) and (ln_months <= 15) THEN
                  --②新商品単年度実績の計画データ作成
                  --売上月平均実績の算出
                  ln_month_average_sale := ln_last_year_sale / (ln_months - 3);
                  --数量月平均実績の算出
                  ln_month_average_amount := ln_last_year_amount / (ln_months - 3);
                  --新商品単年度実績比率
                  IF (ln_single_result_rate <= 0.5)
                    OR (ln_single_result_rate >= 2)
                    OR (ln_single_result_rate IS NULL)
                  THEN
                    ln_single_result_rate := 1;
                  END IF;

                  -- =====================================================
                  -- 政策群単位での本年度対象月計画値取得(A-10)
                  -- =====================================================
                  deal_this_month_plan(
                                     lt_kyoten_cd        -- 拠点コード
                                    ,lt_item_group_no    -- 商品群コード
                                    ,lt_year_month       -- 年月
                                    ,ln_this_month_sale  -- 政策群単位での本年度対象月計画値
                                    ,lv_errbuf           -- エラー・メッセージ
                                    ,lv_retcode          -- リターン・コード
                                    ,lv_errmsg);         -- ユーザー・エラー・メッセージ
                  -- 例外処理
                  IF (lv_retcode = cv_status_error) THEN
                    --(エラー処理)
                    gn_error_cnt := gn_error_cnt +1;
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    --警告処理
                    gn_error_cnt := gn_error_cnt + 1;
                    RAISE deal_skip_expt;
                  END IF;

                  --新商品単年度政策群構成比の算出
                  IF (ln_this_year_deal_plan = 0) THEN
                    ln_deal_composition_rate := 1;
                  ELSE
                    ln_deal_composition_rate := ln_this_month_sale / ln_this_year_deal_plan;
                  END IF;
                  --新商品単年度実績の計画データ作成
                  --売上金額
                  ln_plan_sales_budget        := ROUND((ln_month_average_sale * ln_single_result_rate * ln_deal_composition_rate * 12),-3);
                  --数量
                  IF ln_unit_flg = 0 THEN
                    ln_plan_amount              := ROUND((ln_month_average_amount * ln_single_result_rate * ln_deal_composition_rate * 12),0);
                  ELSE
                    ln_plan_amount              := ROUND((ln_month_average_amount * ln_single_result_rate * ln_deal_composition_rate * 12),1);
                  END IF;
                  --粗利益
                  ln_plan_amount_gross_margin := ROUND((ln_plan_sales_budget - (ln_plan_amount * ln_discrete_cost)),-3);
                  --掛率
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--                  IF (ln_plan_amount = 0) THEN
                  IF ((ln_plan_amount * ln_fixed_price) = 0) THEN
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
                    ln_plan_credit_rate := 0;
                  ELSE
                    ln_plan_credit_rate         := ROUND(((ln_plan_sales_budget / (ln_plan_amount * ln_fixed_price)) * 100),2);
                  END IF;
                  --粗利益率
                  IF (ln_plan_sales_budget = 0) THEN
                    ln_margin_rate := 0;
                  ELSE
                    ln_margin_rate              := ROUND(((ln_plan_amount_gross_margin / ln_plan_sales_budget) * 100),2);
                  END IF;
--
                ELSIF (ln_months <= 3) THEN
                --③新商品販売実績なしの計画データ作成
                  --売上金額
                  ln_plan_sales_budget        := 0;
                  --数量
                  ln_plan_amount              := 0;
                  --粗利益
                  ln_plan_amount_gross_margin := 0;
                  --掛率
                  ln_plan_credit_rate         := 0;
                  --粗利益率
                  ln_margin_rate              := 0;
--
                ELSIF (ln_months > 15) AND (ln_months < 27) THEN
                  --④新商品2ヵ年度実績の計画データ作成
                  -- =====================================================
                  -- 対象月データ取得(A-5)
                  -- =====================================================
                  item_month_data_select(
                                        lt_kyoten_cd       --拠点コード
                                       ,lt_item_group_no   --政策群コード
                                       ,lt_item_no         --商品コード
                                       ,lt_month_no        --月
                                       ,ln_sales_budget    --売上
                                       ,ln_amount          --数量
                                       ,lv_errbuf          --エラー・メッセージ
                                       ,lv_retcode         --リターン・コード
                                       ,lv_errmsg);        -- ユーザー・エラー・メッセージ

                  -- 例外処理
                  IF (lv_retcode = cv_status_error) THEN
                    --(エラー処理)
                    gn_error_cnt := gn_error_cnt +1;
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    --警告処理
                    gn_error_cnt := gn_error_cnt + 1;
                    RAISE deal_skip_expt;
                  END IF;

                  --新商品2ヵ年度実績比率算出
                  IF (ln_before_last_year_sale = 0) THEN
                    ln_new_two_result_rate := 1;
                  ELSE
                    ln_new_two_result_rate := ln_last_year_sale / ln_before_last_year_sale;
                  END IF;
                  IF (ln_new_two_result_rate <= 0.5)
                    OR (ln_new_two_result_rate >= 2)
                    OR (ln_new_two_result_rate IS NULL)
                  THEN
                    ln_new_two_result_rate := 1;
                  END IF;
                  --売上金額
                  ln_plan_sales_budget        := ROUND((ln_sales_budget * ln_new_two_result_rate),-3);
                  --数量
                  IF ln_unit_flg = 0 THEN
                  ln_plan_amount              := ROUND((ln_amount * ln_new_two_result_rate),0);
                  ELSE
                  ln_plan_amount              := ROUND((ln_amount * ln_new_two_result_rate),1);
                  END IF;
                  --粗利益
                  ln_plan_amount_gross_margin := ROUND((ln_plan_sales_budget - (ln_plan_amount * ln_discrete_cost)),-3);
                  --掛率
--//UPD START 2009/02/18 CT_033 M.Ohtsuki
--                  IF (ln_plan_amount = 0) THEN
                  IF ((ln_plan_amount * ln_fixed_price) = 0) THEN
--//UPD END   2009/02/18 CT_033 M.Ohtsuki
                    ln_plan_credit_rate := 0;
                  ELSE
                    ln_plan_credit_rate         := ROUND(((ln_plan_sales_budget / (ln_plan_amount * ln_fixed_price)) * 100),2);
                  END IF;
                  --粗利益率
                  IF (ln_plan_sales_budget = 0) THEN
                    ln_margin_rate := 0;
                  ELSE
                    ln_margin_rate              := ROUND(((ln_plan_amount_gross_margin / ln_plan_sales_budget) * 100),2);
                  END IF;
                END IF;
--
                --算出データ保存
                lr_plan_rec.item_plan_header_id    := lt_item_plan_header_id;      --商品計画ヘッダID
                lr_plan_rec.item_plan_lines_id     := NULL;
                lr_plan_rec.year_month             := lt_year_month;               --年月
                lr_plan_rec.month_no               := lt_month_no;                 --月
                lr_plan_rec.year_bdgt_kbn          := '0';                         --年間群予算区分(0：各月)
                lr_plan_rec.item_kbn               := '1';                         --商品区分(1：商品単品)
                lr_plan_rec.item_no                := lt_item_no;                  --商品コード
                lr_plan_rec.item_group_no          := lt_item_group_no;            --商品群コード
                lr_plan_rec.amount                 := ln_plan_amount;              --数量
                lr_plan_rec.sales_budget           := ln_plan_sales_budget;        --売上金額
                lr_plan_rec.amount_gross_margin    := ln_plan_amount_gross_margin; --粗利益(新)
                lr_plan_rec.credit_rate            := ln_plan_credit_rate;         --掛率
                lr_plan_rec.margin_rate            := ln_margin_rate;              --粗利益率(新)
                lr_plan_rec.created_by             := cn_created_by;               --作成者
                lr_plan_rec.creation_date          := cd_creation_date;            --作成日
                lr_plan_rec.last_updated_by        := cn_last_updated_by;          --最新更新者
                lr_plan_rec.last_update_date       := cd_last_update_date;         --最新更新日
                lr_plan_rec.last_update_login      := cn_last_update_login;        --最終更新ログインID
                lr_plan_rec.request_id             := cn_request_id;               --要求ID
                lr_plan_rec.program_application_id := cn_program_application_id;   --プログラムアプリケーションID
                lr_plan_rec.program_id             := cn_program_id;               --プログラムID
                lr_plan_rec.program_update_date    := cd_program_update_date;      --プログラム更新日
--
                -- =====================================================
                -- データ登録(A-12)
                -- =====================================================
                insert_data(
                            lr_plan_rec          -- 対象レコード
                           ,lv_errbuf            -- エラー・メッセージ
                           ,lv_retcode           -- リターン・コード
                           ,lv_errmsg);
                -- 例外処理
                IF (lv_retcode = cv_status_error) THEN
                  --(エラー処理)
                  gn_error_cnt := gn_error_cnt +1;
                  RAISE global_process_expt;
                ELSIF (lv_retcode = cv_status_warn) THEN
                  --警告処理
                  gn_error_cnt := gn_error_cnt + 1;
                  RAISE deal_skip_expt;
                END IF;
              END LOOP month_loop;
            CLOSE year_month_select_cur;
          END LOOP item_loop;
        CLOSE sale_result_cur;
        -- *** A-5商品コード取得できない場合、対象データ無しエラーになります ***
        IF lt_item_no IS NULL THEN
            lv_no_data_msg := xxccp_common_pkg.get_msg(
                                                  iv_application  =>  cv_xxcsm
                                                 ,iv_name         =>  cv_chk_err_00056
                                                 ,iv_token_name1  =>  cv_tkn_cd_deal
                                                 ,iv_token_value1 =>  lt_item_group_no
                                                 );
            fnd_file.put_line(
                            which  => FND_FILE.LOG
                           ,buff   => lv_no_data_msg
                           );
            fnd_file.put_line(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_no_data_msg
                           );
        END IF;
--
        -- =====================================================
        -- 新商品計画値算出(新商品コード取得)(A-11)
        -- =====================================================
        new_item_no_select(
                           lt_item_group_no       -- A-3で取得した政策群コード
                          ,lv_new_item_no         -- 新商品コード
--//ADD START 2009/05/19 T1_1069 T.Tsukino
                          ,lv_new_item_cost       -- 営業原価
                          ,lv_new_item_price      -- 定価
--//ADD END 2009/05/19 T1_1069 T.Tsukino
                          ,lv_errbuf              -- エラー・メッセージ
                          ,lv_retcode             -- リターン・コード
                          ,lv_errmsg);            -- ユーザー・エラー・メッセージ

        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --警告処理
          gn_error_cnt := gn_error_cnt + 1;
          RAISE deal_skip_expt;
        END IF;
--
        -- =====================================================
        -- 新商品計画値算出(A-11)
        -- =====================================================
        OPEN kyoten_month_deal_plan_cur(lt_item_group_no);
          <<new_month_loop>>
          LOOP
            FETCH kyoten_month_deal_plan_cur INTO kyoten_month_deal_plan_cur_rec;
            EXIT WHEN kyoten_month_deal_plan_cur%NOTFOUND;
            lt_new_year_month   := kyoten_month_deal_plan_cur_rec.year_month;
            lt_new_month_no     := kyoten_month_deal_plan_cur_rec.month_no;
            ln_new_sales_budget := kyoten_month_deal_plan_cur_rec.sales_budget;
            ln_new_gross_budget := kyoten_month_deal_plan_cur_rec.amount_gross_margin;

            -- =====================================================
            -- 新商品計画値算出(月別単品売上金額合計取得)(A-11)
            -- =====================================================
            month_item_sales_sum(
                                 lt_item_plan_header_id     -- ヘッダID
                                ,lt_item_group_no           -- A-3で取得した政策群コード
                                ,lt_new_year_month          -- 年月
                                ,ln_month_sales_sum         -- 月別単品売上金額合計
                                ,ln_month_gross_sum         -- 月別単品粗利益額合計
                                ,lv_errbuf                  -- エラー・メッセージ
                                ,lv_retcode                 -- リターン・コード
                                ,lv_errmsg);                -- ユーザー・エラー・メッセージ

            -- 例外処理
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --警告処理
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
--
            --③新商品計画値算出
            ln_new_plan_sales := ln_new_sales_budget - NVL(ln_month_sales_sum,0);
            ln_new_plan_gross := ln_new_gross_budget - NVL(ln_month_gross_sum,0);
            --//ADD START 2009/05/27 T1_1173 A.Sakawa
            IF ( lv_new_item_cost = 0 ) THEN
              -- 数量に0をセット
              ln_new_plan_amount := 0;
            ELSE
            --//ADD END 2009/05/27 T1_1173 A.Sakawa
              --//UPD START 2009/05/19 T1_1069 T.Tsukino
              -- 数量 = ( ( 売上 - 粗利益額 ) / 原価(1つあたり) )
              ln_new_plan_amount :=  ROUND(((ln_new_plan_sales - ln_new_plan_gross) / lv_new_item_cost),0);
              --//UPD END 2009/05/19 T1_1069 T.Tsukino
            --//ADD START 2009/05/27 T1_1173 A.Sakawa
            END IF;
            IF ( ln_new_plan_amount * lv_new_item_price = 0 ) THEN
              -- 掛率に0をセット
              ln_new_plan_credit := 0;
            ELSE
            --//ADD END 2009/05/27 T1_1173 A.Sakawa
              --//UPD START 2009/05/19 T1_1069 T.Tsukino
              -- 掛率 = ( 売上 / ( 数量 * 定価) ) * 100
              ln_new_plan_credit :=  ROUND((ln_new_plan_sales / (ln_new_plan_amount * lv_new_item_price)) * 100,2);
              --//UPD END 2009/05/19 T1_1069 T.Tsukino
            --//ADD START 2009/05/27 T1_1173 A.Sakawa
            END IF;
            --//ADD END 2009/05/27 T1_1173 A.Sakawa
            --新商品登録値保存
            lr_new_plan_rec.item_plan_header_id    := lt_item_plan_header_id;         --商品計画ヘッダID
            lr_new_plan_rec.item_plan_lines_id     := NULL;
            lr_new_plan_rec.year_month             := lt_new_year_month;              --年月
            lr_new_plan_rec.month_no               := lt_new_month_no;                --月
            lr_new_plan_rec.year_bdgt_kbn          := '0';                            --年間群予算区分(0：各月)
            lr_new_plan_rec.item_kbn               := '2';                            --商品区分(2：新商品)
            lr_new_plan_rec.item_no                := lv_new_item_no;                 --商品コード
            lr_new_plan_rec.item_group_no          := lt_item_group_no;               --商品群コード
            --//UPD START 2009/05/07 T1_0792 T.Tsukino
            --lr_new_plan_rec.amount                 := 0;                              --数量
            lr_new_plan_rec.amount                 := ln_new_plan_amount;               --数量
            --//UPD END 2009/05/07 T1_0792 T.Tsukino
            lr_new_plan_rec.sales_budget           := ln_new_plan_sales;              --売上金額
            lr_new_plan_rec.amount_gross_margin    := ln_new_plan_gross;              --粗利益(新)
            --//UPD START 2009/05/07 T1_0792 T.Tsukino
            --lr_new_plan_rec.credit_rate            := 0;                              --掛率
            lr_new_plan_rec.credit_rate            := ln_new_plan_credit;             --掛率
            --//UPD END 2009/05/07 T1_0792 T.Tsukino
            lr_new_plan_rec.margin_rate            := 0;                              --粗利益率(新)
            lr_new_plan_rec.created_by             := cn_created_by;                  --作成者
            lr_new_plan_rec.creation_date          := cd_creation_date;               --作成日
            lr_new_plan_rec.last_updated_by        := cn_last_updated_by;             --最新更新者
            lr_new_plan_rec.last_update_date       := cd_last_update_date;            --最新更新日
            lr_new_plan_rec.last_update_login      := cn_last_update_login;           --最終更新ログインID
            lr_new_plan_rec.request_id             := cn_request_id;                  --要求ID
            lr_new_plan_rec.program_application_id := cn_program_application_id;      --プログラムアプリケーションID
            lr_new_plan_rec.program_id             := cn_program_id;                  --プログラムID
            lr_new_plan_rec.program_update_date    := cd_program_update_date;         --プログラム更新日
--
            -- =====================================================
            -- データ登録(A-12)
            -- =====================================================
            insert_data(
                        lr_new_plan_rec          -- 対象レコード
                       ,lv_errbuf            -- エラー・メッセージ
                       ,lv_retcode           -- リターン・コード
                       ,lv_errmsg);
            -- 例外処理
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              --警告処理
              gn_error_cnt := gn_error_cnt + 1;
              RAISE deal_skip_expt;
            END IF;
--
          END LOOP new_month_loop;
        CLOSE kyoten_month_deal_plan_cur;
--
        --判断用商品群コード保存
        lt_pre_item_group_no := lt_item_group_no;
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN deal_skip_expt THEN
        IF year_month_select_cur%ISOPEN THEN
          CLOSE year_month_select_cur;
        END IF;
        IF sale_result_cur%ISOPEN THEN
          CLOSE sale_result_cur;
        END IF;
        IF kyoten_month_deal_plan_cur%ISOPEN THEN
          CLOSE kyoten_month_deal_plan_cur;
        END IF;
        fnd_file.put_line(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf
                       );
        fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_errmsg
                       );
        ov_retcode := cv_status_warn;  --警告
        ROLLBACK TO item_group_point;
      END;
      END LOOP deal_loop;
      IF (deal_select_cur%ROWCOUNT = 0) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                        iv_application  =>  cv_xxcsm
                                       ,iv_name         =>  cv_chk_err_10001
                                       );
        lv_errbuf := lv_errmsg;
        fnd_file.put_line(
                        which  => FND_FILE.LOG
                       ,buff   => lv_errbuf
                       );
        fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_errmsg
                       );
      END IF;
    CLOSE deal_select_cur;
--
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf        OUT NOCOPY VARCHAR2,      --   エラー・メッセージ
    retcode       OUT NOCOPY VARCHAR2,      --   リターン・コード
    iv_kyoten_cd     IN  VARCHAR2,          --   拠点コード
    iv_deal_cd       IN  VARCHAR2           --   政策群コード
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_kyoten_cd   --拠点コード
      ,iv_deal_cd     --政策群コード
      ,lv_errbuf   -- エラー・メッセージ
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
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
END XXCSM002A05C;
/