CREATE OR REPLACE PACKAGE BODY XXCSM002A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A10C(body)
 * Description      : 商品計画リスト（累計）出力
 * MD.050           : 商品計画リスト（累計）出力 MD050_CSM_002_A10
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_plandata           年間商品計画データ存在チェック(A-3)
 *  chk_propdata           按分処理済データ存在チェック(A-4)
 *  select_grp4_total_data データの抽出（商品群）(A-8)
 *  select_grp1_total_data データの抽出（商品区分）(A-11)
 *  select_com_total_data  データの抽出（商品合計）(A-14)
 *  select_discount_data   データの抽出（売上値引／入金値引）(A-17)
 *  select_kyot_total_data データの抽出（拠点合計）(A-19)
 *  insert_data            データ登録(A-7,10,13,16,18,21)
 *  output_check_list      チェックリストデータ出力(A-22)
 *  loop_kyoten            拠点ループ内処理
 *  loop_main              メインループ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-1-15      1.0   n.izumi         新規作成
 *  2009-02-09     1.1   M.Ohtsuki      ［障害CT_007］類似機能動作統一修正
 *  2009-02-20     1.2   M.Ohtsuki      ［障害CT_051］CSV出力フォーマットの修正
 *  2009-02-20     1.3   M.Ohtsuki      ［障害CT_053］マイナス商品の不具合の対応
 *  2009-03-09     1.4   M.Ohtsuki      ［障害CT_078］不要なSQLの削除対応
 *  2009-05-07     1.5   M.Ohtsuki      ［障害T1_0858］拠点コード抽出条件の不備の対応
 *  2009-07-15     1.6   M.Ohtsuki      ［0000678］対象データ0件時のステータス不具合の対応
 *  2011-01-05     1.7   SCS OuKou       [E_本稼動_05803]
 *  2012-12-10     1.8   SCSK K.Taniguchi[E_本稼動_09949] 新旧原価選択可能対応
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
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
--*** ADD TEMPLETE Start****************************************
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --想定外エラーメッセージ
--*** ADD TEMPLETE Start****************************************
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
  global_data_check_expt    EXCEPTION;     -- データ存在チェック
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSM002A10C';                    -- パッケージ名
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';                               -- フラグY
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_flg_n         CONSTANT VARCHAR2(1)   := 'N';                               -- フラグN
--//+ADD END E_本稼動_09949 K.Taniguchi
  --メッセージーコード
  cv_prof_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                -- プロファイル取得エラー
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_start_date_err_msg
                   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10168';                -- 年度開始日取得エラー
--//+ADD END E_本稼動_09949 K.Taniguchi
  cv_noplandt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';                -- 商品計画未設定
  cv_nopropdt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00088';                -- 商品計画単品別按分処理未完了
  cv_lst_head_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00077';                -- 年間商品計画リスト（累計）ヘッダ用
  cv_par_yyyy_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';                -- コンカレント入力パラメータ(対象年度)
  cv_par_kyotn_msg CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';                -- コンカレント入力パラメータ(拠点コード)
  cv_par_cost_kind_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10017';           -- コンカレント入力パラメータ(原価種別)
  cv_par_level_msg CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10004';                -- コンカレント入力パラメータ(階層)
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_par_new_old_cost_cls_msg
                   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10167';                -- コンカレント入力パラメータ(新旧原価区分)
--//+ADD END E_本稼動_09949 K.Taniguchi
--//+ADD START 2009/02/12   CT007 M.Ohtsuki
  cv_nodata_msg    CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';                -- 対象データ0件エラーメッセージ 
--//+ADD END   2009/02/12   CT007 M.Ohtsuki
  --トークン
  cv_tkn_cd_prof   CONSTANT VARCHAR2(100) := 'PROF_NAME';                       -- カスタム・プロファイル・オプションの英名
  cv_tkn_cd_yyyy   CONSTANT VARCHAR2(100) := 'YYYY';                            -- 対象年度
  cv_tkn_cd_tsym   CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                      -- 対象年度
  cv_tkn_cd_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                       -- 拠点コード
  cv_tkn_nm_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_NM';                       -- 拠点名
  cv_tkn_cost_kind CONSTANT VARCHAR2(100) := 'GENKA_CD';                        -- 原価種別
  cv_tkn_cost_kind_nm CONSTANT VARCHAR2(100) := 'GENKA_NM';                     -- 原価種別名
  cv_tkn_cd_level  CONSTANT VARCHAR2(100) := 'HIERARCHY_LEVEL';                 -- 階層
  cv_tkn_nichiji   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';                 -- 作成日時
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_tkn_new_old_cost_cls
                   CONSTANT VARCHAR2(100) := 'NEW_OLD_COST_CLASS';              -- 新旧原価区分
  cv_tkn_sobid     CONSTANT VARCHAR2(100) := 'SET_OF_BOOKS_ID';                 -- 会計帳簿ID
  cv_tkn_process_date
                   CONSTANT VARCHAR2(100) := 'PROCESS_DATE';                    -- 業務日付
--//+ADD END E_本稼動_09949 K.Taniguchi
  cv_chk1_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_1';         -- チェックリスト項目名（商品合計）プロファイル名
  cv_chk2_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';         -- チェックリスト項目名（売上値引）プロファイル名
  cv_chk3_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';         -- チェックリスト項目名（入金値引）プロファイル名
  cv_chk4_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_PLANLIST_ITEM_5';          -- 計画リスト項目名（拠点計）プロファイル名
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_gl_set_of_bks_id_profile
                   CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                -- 会計帳簿IDプロファイル名
--//+ADD END E_本稼動_09949 K.Taniguchi
--その他
  cv_kind_of_cost  CONSTANT VARCHAR2(100) := 'XXCSM1_KIND_OF_COST';             -- 原価種別名取得用
  cv_lookup_type   CONSTANT VARCHAR2(100) := 'XXCSM1_FORM_PARAMETER_VALUE';     -- 全拠点コード取得用
  cv_item_kbn      CONSTANT VARCHAR2(1)   := '0';                               -- 商品区分（商品群）按分しているもの
  cv_leaf          CONSTANT VARCHAR2(1)   := 'A';                               -- 商品区分（LEAF）
  cv_drink         CONSTANT VARCHAR2(1)   := 'C';                               -- 商品区分（DRINK）
  cv_sonota        CONSTANT VARCHAR2(1)   := 'D';                               -- 商品区分（その他）
  cv_nebiki        CONSTANT VARCHAR2(1)   := 'N';                               -- 商品区分（値引）
  cv_kyoten_kei    CONSTANT VARCHAR2(1)   := 'K';                               -- 商品区分（拠点計情報）
  cv_cost_base     CONSTANT VARCHAR2(2)   := '10';                              -- 原価種別（標準）
  cv_cost_bus      CONSTANT VARCHAR2(2)   := '20';                              -- 原価種別（営業）
--//+ADD START E_本稼動_09949 K.Taniguchi
  cv_whse_code     CONSTANT VARCHAR2(3)   := '000';                             -- 原価倉庫
  cv_new_cost      CONSTANT VARCHAR2(10)  := '10';                              -- パラメータ：新旧原価区分（新原価）
  cv_old_cost      CONSTANT VARCHAR2(10)  := '20';                              -- パラメータ：新旧原価区分（旧原価）
--//+ADD END E_本稼動_09949 K.Taniguchi

--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_sum_data_rtype IS RECORD(
       group_cd                xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE     -- 商品群コード
      ,group_nm                xxcsm_tmp_item_plan_sales_sum.group4_nm%TYPE     -- 商品群名称
      ,con_price               xxcsm_tmp_item_plan_sales_sum.con_price%TYPE     -- 定価
      ,amount                  xxcsm_tmp_item_plan_sales_sum.amount%TYPE        -- 数量
      ,price_multi_amount      xxcsm_tmp_item_plan_sales_sum.sales_budget%TYPE  -- 定価 * 数量
      ,sales_budget            xxcsm_tmp_item_plan_sales_sum.sales_budget%TYPE  -- 売上
      ,cost                    xxcsm_tmp_item_plan_sales_sum.cost%TYPE          -- 原価
      ,margin                  xxcsm_tmp_item_plan_sales_sum.margin%TYPE        -- 粗利益額
   );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate           DATE;
--//+ADD START E_本稼動_09949 K.Taniguchi
  gd_process_date      DATE;                                                    -- 業務処理日付
  gn_gl_set_of_bks_id  NUMBER;                                                  -- 会計帳簿ID
  gd_gl_start_date     DATE;                                                    -- 起動時の年度開始日
--//+ADD END E_本稼動_09949 K.Taniguchi
  gt_allkyoten_cd      fnd_lookup_values.lookup_code%TYPE;                      -- 全拠点コード
  gv_total_com_nm      xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- 計画リスト項目名（商品合計）
  gv_sales_disc_nm     xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- 計画リスト項目名（売上値引）
  gv_receipt_disc_nm   xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- 計画リスト項目名（入金値引）
  gv_kyoten_kei_nm     xxcsm_tmp_item_plan_sales_sum.item_nm%TYPE;              -- 計画リスト項目名（拠点計）
  gv_cost_kind_nm      VARCHAR2(100);                                           -- 原価種別名
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_yyyy       IN  VARCHAR2,            -- 1.対象年度
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード
    iv_cost_kind  IN  VARCHAR2,            -- 3.原価種別
    iv_level      IN  VARCHAR2,            -- 4.階層
--//+ADD START E_本稼動_09949 K.Taniguchi
    iv_p_new_old_cost_class
                  IN  VARCHAR2,            -- 5.新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ              --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード                --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ    --# 固定 #
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
    lv_pram_op      VARCHAR2(100);     -- パラメータメッセージ出力
    ld_process_date DATE;              -- 業務日付
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
    -- ===========================
    -- 原価種別名取得
    -- ===========================
    BEGIN
      SELECT ffvv.description                                                   --値セット名称.適用 
        INTO gv_cost_kind_nm
        FROM fnd_flex_values_vl  ffvv,                                          --値セット名称
             fnd_flex_values ffv,                                               --値セット明細
             fnd_flex_value_sets ffvs                                           --値セットヘッダ
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffv.flex_value_set_id = ffvv.flex_value_set_id
         AND ffv.flex_value_id = ffvv.flex_value_id
         AND ffvs.flex_value_set_name = cv_kind_of_cost
         AND ffv.flex_value = iv_cost_kind                                      --パラメータ原価種別
      ;
    EXCEPTION
      WHEN OTHERS THEN
        gv_cost_kind_nm := NULL;
    END;
    IF gv_cost_kind_nm IS NULL THEN                                             -- 原価種別名が取得できなかった場合、想定外エラーとする。  
      RAISE global_api_expt;
    END IF;    
    -- ===========================
    -- 入力パラメータメッセージ出力
    -- ===========================
    --対象年度
    lv_pram_op := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_par_yyyy_msg
                                            ,iv_token_name1  => cv_tkn_cd_yyyy
                                            ,iv_token_value1 => iv_yyyy
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    --拠点コード
    lv_pram_op := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_par_kyotn_msg
                                            ,iv_token_name1  => cv_tkn_cd_kyoten
                                            ,iv_token_value1 => iv_kyoten_cd
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    --原価種別
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_cost_kind_msg
                                           ,iv_token_name1  => cv_tkn_cost_kind
                                           ,iv_token_value1 => iv_cost_kind
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
    --階層
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_level_msg
                                           ,iv_token_name1  => cv_tkn_cd_level
                                           ,iv_token_value1 => iv_level
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
--//+ADD START E_本稼動_09949 K.Taniguchi
    --新旧原価区分
    lv_pram_op := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_par_new_old_cost_cls_msg
                                           ,iv_token_name1  => cv_tkn_new_old_cost_cls
                                           ,iv_token_value1 => iv_p_new_old_cost_class
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_pram_op);
--//+ADD END E_本稼動_09949 K.Taniguchi
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--//+ADD START E_本稼動_09949 K.Taniguchi
    gd_process_date := ld_process_date; -- グローバル変数に格納
--//+ADD END E_本稼動_09949 K.Taniguchi
--
    -- =====================
    -- プロファイル取得処理 
    -- =====================
    --計画リスト項目名（商品合計）取得
    gv_total_com_nm := FND_PROFILE.VALUE(cv_chk1_profile);
    IF (gv_total_com_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk1_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --計画リスト項目名（売上値引）取得
    gv_sales_disc_nm := FND_PROFILE.VALUE(cv_chk2_profile);
    IF (gv_sales_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk2_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --計画リスト項目名（入金値引）取得
    gv_receipt_disc_nm := FND_PROFILE.VALUE(cv_chk3_profile);
    IF (gv_receipt_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk3_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --計画リスト項目名（拠点計）取得
    gv_kyoten_kei_nm := FND_PROFILE.VALUE(cv_chk4_profile);
    IF (gv_kyoten_kei_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk4_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--//+ADD START E_本稼動_09949 K.Taniguchi
    -- 会計帳簿ID
    gn_gl_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_gl_set_of_bks_id_profile));
    IF (gn_gl_set_of_bks_id) IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_gl_set_of_bks_id_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
    -- =====================
    -- 起動時の年度開始日取得
    -- =====================
    BEGIN
      -- 年度開始日
      SELECT  gp.start_date             AS start_date           -- 年度開始日
      INTO    gd_gl_start_date                                  -- 起動時の年度開始日
      FROM    gl_sets_of_books          gsob                    -- 会計帳簿マスタ
             ,gl_periods                gp                      -- 会計カレンダ
      WHERE   gsob.set_of_books_id      = gn_gl_set_of_bks_id   -- 会計帳簿ID
      AND     gp.period_set_name        = gsob.period_set_name  -- カレンダ名
      AND     gp.period_year            = (
                                            -- 起動時の年度
                                            SELECT  gp2.period_year           AS period_year          -- 年度
                                            FROM    gl_sets_of_books          gsob2                   -- 会計帳簿マスタ
                                                   ,gl_periods                gp2                     -- 会計カレンダ
                                            WHERE   gsob2.set_of_books_id     = gn_gl_set_of_bks_id   -- 会計帳簿ID
                                            AND     gp2.period_set_name       = gsob2.period_set_name -- カレンダ名
                                            AND     gd_process_date           BETWEEN gp2.start_date  -- 業務日付時点
                                                                              AND     gp2.end_date
                                          )
      AND     gp.adjustment_period_flag = cv_flg_n              -- 調整会計期間外
      AND     gp.period_num             = 1                     -- 年度開始月
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_start_date_err_msg
                                             ,iv_token_name1  => cv_tkn_sobid
                                             ,iv_token_value1 => TO_CHAR(gn_gl_set_of_bks_id)     --会計帳簿ID
                                             ,iv_token_name2  => cv_tkn_process_date
                                             ,iv_token_value2 => TO_CHAR(gd_process_date, 'YYYY/MM/DD') --業務日付
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--//+ADD END E_本稼動_09949 K.Taniguchi
    -- =====================
    -- 全拠点コード取得処理 
    -- =====================
    SELECT
      flv.lookup_code     lookup_code
    INTO
      gt_allkyoten_cd
    FROM
      fnd_lookup_values  flv --クイックコード値
    WHERE
      flv.lookup_type = cv_lookup_type
    AND
      (flv.start_date_active <= ld_process_date OR flv.start_date_active IS NULL)
    AND
      (flv.end_date_active >= ld_process_date OR flv.end_date_active IS NULL)
    AND
      flv.enabled_flag = cv_flg_y
    AND
      ROWNUM = 1
    ;

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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_plandata
   * Description      : 年間商品計画データ存在チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_plandata(
    iv_yyyy       IN  VARCHAR2,            -- 1.対象年度
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_plandata'; -- プログラム名
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
    ln_cnt           NUMBER;
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
    SELECT
      COUNT(ipl.item_plan_header_id)    cnt
    INTO
      ln_cnt
    FROM
      xxcsm_item_plan_headers    iph,   --商品計画ヘッダテーブル
      xxcsm_item_plan_lines      ipl    --商品計画明細テーブル
    WHERE
        iph.item_plan_header_id = ipl.item_plan_header_id
    AND iph.plan_year           = TO_NUMBER(iv_yyyy)
    AND iph.location_cd         = iv_kyoten_cd
    AND ROWNUM = 1;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_noplandt_msg
                                           ,iv_token_name1  => cv_tkn_cd_tsym
                                           ,iv_token_value1 => iv_yyyy
                                           ,iv_token_name2  => cv_tkn_cd_kyoten
                                           ,iv_token_value2 => iv_kyoten_cd
                                           );
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
      RAISE global_data_check_expt;
    END IF;

--
  EXCEPTION
    -- *** データ存在チェックエラー ***
    WHEN global_data_check_expt THEN
      gn_warn_cnt := gn_warn_cnt +1;
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_plandata;
--
  /**********************************************************************************
   * Procedure Name   : chk_propdata
   * Description      : 按分処理済データ存在チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_propdata(
    iv_yyyy       IN  VARCHAR2,            -- 1.対象年度
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_propdata'; -- プログラム名
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
    ln_cnt           NUMBER;
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
    SELECT
      COUNT(ipl.item_plan_header_id)    cnt
    INTO
      ln_cnt
    FROM
      xxcsm_item_plan_headers    iph,   --商品計画ヘッダテーブル
      xxcsm_item_plan_lines      ipl    --商品計画明細テーブル
    WHERE
        iph.item_plan_header_id = ipl.item_plan_header_id
    AND iph.plan_year           = TO_NUMBER(iv_yyyy)
    AND iph.location_cd         = iv_kyoten_cd
    AND ipl.item_kbn           <> cv_item_kbn
    AND ROWNUM = 1;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_nopropdt_msg
                                           ,iv_token_name1  => cv_tkn_cd_tsym
                                           ,iv_token_value1 => iv_yyyy
                                           ,iv_token_name2  => cv_tkn_cd_kyoten
                                           ,iv_token_value2 => iv_kyoten_cd
                                           );
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errmsg);
      RAISE global_data_check_expt;
    END IF;

--
  EXCEPTION
    -- *** データ存在チェックエラー ***
    WHEN global_data_check_expt THEN
      gn_warn_cnt := gn_warn_cnt +1;
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_propdata;
--
  /**********************************************************************************
   * Procedure Name   : select_grp3_total_data
   * Description      : データの抽出（商品群）(A-8)
   ***********************************************************************************/
  PROCEDURE select_grp4_total_data(
    it_group_cd    IN  xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE,  -- 商品群コード４
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,                   -- 抽出レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_grp4_total_data'; -- プログラム名
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
    -- 抽出処理
    SELECT
       xti.group4_cd                          group4_cd                 -- 商品群コード４
      ,xti.group4_nm                          group4_nm                 -- 商品群名称４
      ,NVL(SUM(xti.con_price),0)              con_price                 -- 定価
      ,NVL(SUM(xti.amount),0)                 amount                    -- 数量
      ,NVL(SUM(xti.con_price * xti.amount),0) price_multi_amount        -- 定価 * 数量
      ,NVL(SUM(xti.sales_budget),0)           sales_budget              -- 売上
      ,NVL(SUM(xti.cost),0)                   cost                      -- 原価
      ,NVL(SUM(xti.margin),0)                 margin                    -- 粗利益額
    INTO
       or_sum_rec.group_cd
      ,or_sum_rec.group_nm
      ,or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
--      ,or_sum_rec.base_margin
    FROM
      xxcsm_tmp_item_plan_sales_sum   xti  -- 商品計画累計営業原価ワークテーブル
    WHERE
      xti.group4_cd  = it_group_cd    -- 商品群コード４
    GROUP BY
       xti.group4_cd                  -- 商品群コード４
      ,xti.group4_nm                  -- 商品群名称４
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 売上＜０の場合に登録されていないことがあるため
      or_sum_rec.group_cd           := it_group_cd;
      or_sum_rec.group_nm           := NULL;
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_grp4_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_grp1_total_data
   * Description      : データの抽出（商品区分）(A-11)
   ***********************************************************************************/
  PROCEDURE select_grp1_total_data(
    it_group_cd    IN  xxcsm_tmp_item_plan_sales_sum.group1_cd%TYPE,            -- 商品群コード１
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,                                 -- 抽出レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                                         -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                                         -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                                         -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_grp1_total_data'; -- プログラム名
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
    -- 抽出処理
    SELECT
       xti.group1_cd                          group1_cd                 -- 商品群コード１
      ,xti.group1_nm                          group1_nm                 -- 商品群名称１
      ,NVL(SUM(xti.con_price),0)              con_price                 -- 定価
      ,NVL(SUM(xti.amount),0)                 amount                    -- 数量
      ,NVL(SUM(xti.con_price * xti.amount),0) price_multi_amount        -- 定価 * 数量
      ,NVL(SUM(xti.sales_budget),0)           sales_budget              -- 売上
      ,NVL(SUM(xti.cost),0)                   cost                      -- 原価
      ,NVL(SUM(xti.margin),0)                 margin                    -- 粗利益額
    INTO
       or_sum_rec.group_cd
      ,or_sum_rec.group_nm
      ,or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
    FROM
      xxcsm_tmp_item_plan_sales_sum   xti  -- 商品計画累計営業原価ワークテーブル
    WHERE
      xti.group1_cd  = it_group_cd    -- 商品群コード１
    GROUP BY
       xti.group1_cd                  -- 商品群コード１
      ,xti.group1_nm                  -- 商品群名称１
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 売上＜０の場合に登録されていないことがあるため
      SELECT
        cgv.group1_nm    group1_nm      --商品群名称１
      INTO
        or_sum_rec.group_nm
      FROM
        xxcsm_commodity_group4_v  cgv   --商品群４ビュー
      WHERE
        cgv.group1_cd  = it_group_cd    --商品群コード１
      AND
        ROWNUM = 1
      ;

      or_sum_rec.group_cd           := it_group_cd;
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_grp1_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_com_total_data
   * Description      : データの抽出（商品合計）(A-14)
   ***********************************************************************************/
  PROCEDURE select_com_total_data(
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,            -- 抽出レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_com_total_data'; -- プログラム名
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
    -- 抽出処理
    SELECT
       NVL(SUM(xti.con_price), 0)              con_price                 -- 定価
      ,NVL(SUM(xti.amount), 0)                 amount                    -- 数量
      ,NVL(SUM(xti.con_price * xti.amount), 0) price_multi_amount        -- 定価 * 数量
      ,NVL(SUM(xti.sales_budget), 0)           sales_budget              -- 売上
      ,NVL(SUM(xti.cost), 0)                   cost                      -- 原価
      ,NVL(SUM(xti.margin), 0)                 margin                    -- 粗利益額
    INTO
       or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
    FROM
      xxcsm_tmp_item_plan_sales_sum   xti   -- 商品計画累計営業原価ワークテーブル
    WHERE
      xti.group1_cd  IN (cv_leaf, cv_drink)   -- 商品群コード１
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 売上＜０の場合に登録されていないことがあるため
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_com_total_data;
--
  /**********************************************************************************
   * Procedure Name   : select_discount_data
   * Description      : データの抽出（売上値引／入金値引）(A-17)
   ***********************************************************************************/
  PROCEDURE select_discount_data(
    iv_yyyy             IN  VARCHAR2,     -- 対象年度
    iv_kyoten_cd        IN  VARCHAR2,     -- 拠点コード
    ot_sales_discount   OUT xxcsm_item_plan_loc_bdgt.sales_discount%TYPE,     -- 売上値引
    ot_receipt_discount OUT xxcsm_item_plan_loc_bdgt.receipt_discount%TYPE,   -- 入金値引
    ov_errbuf           OUT NOCOPY VARCHAR2,                    -- エラー・メッセー
    ov_retcode          OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg           OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_discount_data'; -- プログラム名
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
    -- 抽出処理
    SELECT
       NVL(SUM(ipb.sales_discount),0)         sales_discount            -- 売上値引
      ,NVL(SUM(ipb.receipt_discount),0)       receipt_discount          -- 入金値引
    INTO
       ot_sales_discount
      ,ot_receipt_discount
    FROM
       xxcsm_item_plan_headers   iph    --商品計画ヘッダテーブル
      ,xxcsm_item_plan_loc_bdgt  ipb    --商品計画拠点別予算テーブル
    WHERE
      iph.item_plan_header_id = ipb.item_plan_header_id
    AND
      iph.plan_year = TO_NUMBER(iv_yyyy)
    AND
      iph.location_cd = iv_kyoten_cd
    AND
      EXISTS(
        SELECT 'X'   x
        FROM
          xxcsm_item_plan_lines  ipl    --商品計画明細テーブル
        WHERE
          iph.item_plan_header_id = ipl.item_plan_header_id
        AND
          ipl.item_kbn <> cv_item_kbn
      )
    ;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_discount_data;
--
  /**********************************************************************************
   * Procedure Name   : select_kyot_total_data
   * Description      : データの抽出（拠点合計）(A-19)
   ***********************************************************************************/
  PROCEDURE select_kyot_total_data(
    or_sum_rec     OUT NOCOPY g_sum_data_rtype,            -- 抽出レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_kyot_total_data'; -- プログラム名
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
    -- 抽出処理
    SELECT
       NVL(SUM(xti.con_price),0)              con_price                 -- 定価
      ,NVL(SUM(xti.amount),0)                 amount                    -- 数量
      ,NVL(SUM(xti.con_price * xti.amount),0) price_multi_amount        -- 定価 * 数量
      ,NVL(SUM(xti.sales_budget),0)           sales_budget              -- 売上
      ,NVL(SUM(xti.cost),0)                   cost                      -- 原価
      ,NVL(SUM(xti.margin),0)                 margin                    -- 粗利益額
    INTO
       or_sum_rec.con_price
      ,or_sum_rec.amount
      ,or_sum_rec.price_multi_amount
      ,or_sum_rec.sales_budget
      ,or_sum_rec.cost
      ,or_sum_rec.margin
    FROM
      xxcsm_tmp_item_plan_sales_sum    xti  -- 商品計画累計営業原価ワークテーブル
    WHERE
      xti.group1_cd  IN (cv_leaf, cv_drink, cv_sonota, cv_nebiki)   -- 商品群コード１
    ;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- 売上＜０の場合に登録されていないことがあるため
      or_sum_rec.con_price          := 0;
      or_sum_rec.amount             := 0;
      or_sum_rec.price_multi_amount := 0;
      or_sum_rec.sales_budget       := 0;
      or_sum_rec.cost               := 0;
      or_sum_rec.margin             := 0;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_kyot_total_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録(A-7,10,13,16,18,21)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec    IN  xxcsm_tmp_item_plan_sales_sum%ROWTYPE,  -- 対象レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
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
    -- 登録処理
    INSERT INTO xxcsm_tmp_item_plan_sales_sum(     -- 商品計画累計営業原価ワークテーブル
       toroku_no                  -- 出力順
      ,location_cd                -- 拠点コード
      ,location_nm                -- 拠点名
      ,group1_cd                  -- 商品群コード１
      ,group1_nm                  -- 商品群名称１
      ,group4_cd                  -- 商品群コード４
      ,group4_nm                  -- 商品群名称４
      ,item_cd                    -- 商品コード
      ,item_nm                    -- 商品名称
      ,con_price                  -- 定価
      ,amount                     -- 数量
      ,sales_budget               -- 売上
      ,cost                       -- 原価
      ,margin                     -- 粗利益額
      ,margin_rate                -- 粗利益率
      ,credit_rate                -- 掛率
    )VALUES(
       xxcsm_tmp_item_plan_salsum_s01.NEXTVAL
      ,ir_plan_rec.location_cd
      ,ir_plan_rec.location_nm
      ,ir_plan_rec.group1_cd
      ,ir_plan_rec.group1_nm
      ,ir_plan_rec.group4_cd
      ,ir_plan_rec.group4_nm
      ,ir_plan_rec.item_cd
      ,ir_plan_rec.item_nm
      ,ir_plan_rec.con_price
      ,ir_plan_rec.amount
      ,ir_plan_rec.sales_budget
      ,ir_plan_rec.cost
      ,ir_plan_rec.margin
      ,ir_plan_rec.margin_rate
      ,ir_plan_rec.credit_rate
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : output_check_list
   * Description      : チェックリストデータ出力(A-22)
   ***********************************************************************************/
  PROCEDURE output_check_list(
    iv_yyyy         IN  VARCHAR2,            -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード（パラメータ）
    iv_kyoten_cd    IN  VARCHAR2,            -- 3.拠点コード
    iv_kyoten_nm    IN  VARCHAR2,            -- 4.拠点名
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_check_list'; -- プログラム名
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
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    ln_cnt               NUMBER;              -- 件数
    lv_header            VARCHAR2(4000);      -- CSV出力用ヘッダ情報
    lv_csv_data          VARCHAR2(4000);      -- CSV出力用データ格納
--//+DEL START 2009/03/09   CT078 M.Ohtsuki
--    lv_kyoten_nm         VARCHAR2(100);       -- 全拠点
--//+DEL END   2009/03/09   CT078 M.Ohtsuki
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- CSV出力用全データ
    CURSOR output_all_cur
    IS
      SELECT
        -- toroku_no                  -- 出力順
           cv_sep_wquot || xti.location_cd || cv_sep_wquot                -- 拠点コード
        || cv_sep_com || cv_sep_wquot || xti.location_nm || cv_sep_wquot  -- 拠点名称
        || cv_sep_com || cv_sep_wquot || xti.item_cd || cv_sep_wquot      -- 商品コード
        || cv_sep_com || cv_sep_wquot || xti.item_nm || cv_sep_wquot      -- 商品名称
        || cv_sep_com || TO_CHAR(xti.amount)                              -- 数量
        || cv_sep_com || TO_CHAR(ROUND(xti.sales_budget/1000))            -- 売上
        || cv_sep_com || TO_CHAR(ROUND(xti.cost/1000))                    -- 原価
        || cv_sep_com || TO_CHAR(ROUND(xti.margin/1000))                  -- 粗利益額
        || cv_sep_com || TO_CHAR(xti.margin_rate)                         -- 粗利益率
        || cv_sep_com || TO_CHAR(xti.credit_rate)                         -- 掛率
        output_list
      FROM
        xxcsm_tmp_item_plan_sales_sum   xti  --商品計画累計営業原価ワークテーブル
      ORDER BY
        xti.toroku_no                   -- 出力順
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
    -- ヘッダ出力
    IF (gn_normal_cnt = 1) THEN
      -- 初回のみヘッダ出力
--//+DEL START 2009/03/09   CT078 M.Ohtsuki
--      SELECT
--        xlv.location_nm location_nm
--      INTO
--        lv_kyoten_nm
--      FROM
--        xxcsm_location_all_v  xlv
--      WHERE
--        xlv.location_cd = iv_p_kyoten_cd
--      ;
--//+DEL END   2009/03/09   CT078 M.Ohtsuki
      lv_header := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm
                   ,iv_name         => cv_lst_head_msg
                   ,iv_token_name1  => cv_tkn_cd_yyyy
                   ,iv_token_value1 => iv_yyyy
                   ,iv_token_name2  => cv_tkn_nichiji
                   ,iv_token_value2 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                   ,iv_token_name3  => cv_tkn_cost_kind_nm
                   ,iv_token_value3 => gv_cost_kind_nm
                 );      -- データ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_header
      );
    END IF;
--
    OPEN output_all_cur();
    <<output_all_loop>>
    LOOP
      FETCH output_all_cur INTO lv_csv_data;
      EXIT WHEN output_all_cur%NOTFOUND;
      -- データ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_data
      );
    END LOOP output_all_loop;
    CLOSE output_all_cur;
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (output_all_cur%ISOPEN) THEN
        CLOSE output_all_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
     IF (output_all_cur%ISOPEN) THEN
        CLOSE output_all_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_check_list;
--
  /**********************************************************************************
   * Procedure Name   : loop_kyoten
   * Description      : 拠点ループ内処理
   ***********************************************************************************/
  PROCEDURE loop_kyoten(
    iv_yyyy         IN  VARCHAR2,            -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード（パラメータ）
    iv_p_cost_kind  IN  VARCHAR2,            -- 3.原価種別
    iv_kyoten_cd    IN  VARCHAR2,            -- 4.拠点コード
    iv_kyoten_nm    IN  VARCHAR2,            -- 5.拠点名
--//+ADD START E_本稼動_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2,            -- 6.新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_kyoten'; -- プログラム名
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
    cv_exit_group1_cd  CONSTANT VARCHAR2(10)  := '!';            -- 最終商品群コード１
    cv_exit_group4_cd  CONSTANT VARCHAR2(10)  := '!!!!';         -- 最終商品群コード４
--
    cv_margin_rate_dis CONSTANT NUMBER := 100.00;                -- 値引の場合の粗利益率
--
    -- *** ローカル変数 ***
    lt_group1_cd           xxcsm_tmp_item_plan_sales_sum.group1_cd%TYPE;    --商品群コード１
    lt_group4_cd           xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE;    --商品群コード４
    lt_pre_group1_cd       xxcsm_tmp_item_plan_sales_sum.group1_cd%TYPE;    --商品群コード１（前レコード）
    lt_pre_group4_cd       xxcsm_tmp_item_plan_sales_sum.group4_cd%TYPE;    --商品群コード４（前レコード）
    lv_kyoten_cd           VARCHAR2(32);                                    --１行目設定用拠点コード
    lv_kyoten_nm           VARCHAR2(240);                                   --１行目設定用拠点名
    ln_cost                NUMBER;    --原価
    ln_margin              NUMBER;    --粗利益額
    ln_margin_rate         NUMBER;    --粗利益率
    ln_credit_rate         NUMBER;    --掛率
    ln_sales_discount      NUMBER;    --売上値引
    ln_receipt_discount    NUMBER;    --入金値引

    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--//+UPD START E_本稼動_09949 K.Taniguchi
--// SELECT句でCASE式を使用⇒GROUP BY句での2重の記述をさけるため
--// FROM句でのインラインビュー化を行います。
--    -- 年間商品計画データ
--    CURSOR item_plan_cur(
--      in_yyyy         IN  NUMBER,       -- 1.対象年度
--      iv_kyoten_cd    IN  VARCHAR2)     -- 2.拠点コード
--    IS
--      SELECT
--         cgv.group1_cd                  group1_cd      --商品群コード１
--        ,cgv.group1_nm                  group1_nm      --商品群名称１
--        ,cgv.group4_cd                  group4_cd      --商品群コード４
--        ,cgv.group4_nm                  group4_nm      --商品群名称４
--        ,cgv.item_cd                    item_cd        --品目コード
--        ,cgv.item_nm                    item_nm        --品目名称
--        ,NVL(cgv.now_item_cost, 0)      base_price     --標準原価
--        ,NVL(cgv.now_business_cost, 0)  bus_price      --営業原価
--        ,NVL(cgv.now_unit_price, 0)     con_price      --定価
--        ,NVL(SUM(ipl.amount), 0)        amount         --数量
--        ,NVL(SUM(ipl.sales_budget), 0)  sales_budget   --売上
--      FROM
--         xxcsm_item_plan_headers   iph   --商品計画ヘッダテーブル
--        ,xxcsm_item_plan_lines     ipl   --商品計画明細テーブル
--        ,xxcsm_commodity_group4_v  cgv   --商品群４ビュー
--      WHERE
--         iph.item_plan_header_id = ipl.item_plan_header_id
--      AND
--         ipl.item_no = cgv.item_cd
--      AND
--         iph.plan_year = in_yyyy
--      AND
--         iph.location_cd = iv_kyoten_cd
--      AND
--         ipl.item_kbn <> cv_item_kbn
--      GROUP BY
--         cgv.group1_cd                         --商品群コード１
--        ,cgv.group1_nm                         --商品群名称１
--        ,cgv.group4_cd                         --商品群コード４
--        ,cgv.group4_nm                         --商品群名称４
--        ,cgv.item_cd                           --品目コード
--        ,cgv.item_nm                           --品目名称
--        ,cgv.now_item_cost                     --標準原価
--        ,cgv.now_business_cost                 --営業原価
--        ,cgv.now_unit_price                    --定価
--      ORDER BY
--         cgv.group1_cd                         --商品群コード１
--        ,cgv.group4_cd                         --商品群コード４
--        ,cgv.item_cd                           --品目コード
--      ;
--
--
    -- 年間商品計画データ
    CURSOR item_plan_cur(
      in_yyyy                   IN  NUMBER,       -- 1.対象年度
      iv_kyoten_cd              IN  VARCHAR2,     -- 2.拠点コード
      iv_p_new_old_cost_class   IN  VARCHAR2)     -- 3.新旧原価区分
    IS
      SELECT
         sub.group1_cd                  group1_cd      --商品群コード１
        ,sub.group1_nm                  group1_nm      --商品群名称１
        ,sub.group4_cd                  group4_cd      --商品群コード４
        ,sub.group4_nm                  group4_nm      --商品群名称４
        ,sub.item_cd                    item_cd        --品目コード
        ,sub.item_nm                    item_nm        --品目名称
        ,NVL(sub.now_item_cost, 0)      base_price     --標準原価
        ,NVL(sub.now_business_cost, 0)  bus_price      --営業原価
        ,NVL(sub.now_unit_price, 0)     con_price      --定価
        ,NVL(SUM(sub.amount), 0)        amount         --数量
        ,NVL(SUM(sub.sales_budget), 0)  sales_budget   --売上
      FROM
      (
          SELECT
             cgv.group1_cd                  group1_cd      --商品群コード１
            ,cgv.group1_nm                  group1_nm      --商品群名称１
            ,cgv.group4_cd                  group4_cd      --商品群コード４
            ,cgv.group4_nm                  group4_nm      --商品群名称４
            ,cgv.item_cd                    item_cd        --品目コード
            ,cgv.item_nm                    item_nm        --品目名称
             --
             -- 標準原価
             -- パラメータ：新旧原価区分
            ,CASE iv_p_new_old_cost_class
               --
               -- 10：新原価 選択時
               WHEN cv_new_cost THEN
                 NVL(cgv.now_item_cost, 0)
               --
               -- 20：旧原価 選択時
               WHEN cv_old_cost THEN
                 NVL(
                       (
                         -- 標準原価マスタより前年度の標準原価を取得
                         SELECT SUM(ccmd.cmpnt_cost) AS cmpnt_cost                    -- 標準原価
                         FROM   cm_cmpt_dtl     ccmd                                  -- OPM標準原価マスタ
                               ,cm_cldr_dtl     ccld                                  -- 原価カレンダ明細
                         WHERE  ccmd.calendar_code = ccld.calendar_code               -- 原価カレンダコード
                         AND    ccmd.period_code   = ccld.period_code                 -- 期間コード
                         AND    ccmd.item_id       = cgv.opm_item_id                  -- 品目ID
                         AND    ccmd.whse_code     = cv_whse_code                     -- 原価倉庫
                         AND    ccld.start_date   <= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                         AND    ccld.end_date     >= ADD_MONTHS(gd_process_date, -12) -- 前年度時点
                       )
                   , 0
                 )
             END                            now_item_cost       --標準原価
             --
             -- 営業原価
             -- パラメータ：新旧原価区分
            ,CASE iv_p_new_old_cost_class
               --
               -- 10：新原価 選択時
               WHEN cv_new_cost THEN
                 NVL(cgv.now_business_cost, 0)
               --
               -- 20：旧原価 選択時
               WHEN cv_old_cost THEN
                 NVL(
                       (
                         -- 前年度の営業原価を品目変更履歴から取得
                         SELECT  TO_CHAR(xsibh.discrete_cost)  AS  discrete_cost   -- 営業原価
                         FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                         WHERE   xsibh.item_hst_id   =
                           (
                             -- 前年度の品目変更履歴ID
                             SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                             FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                             WHERE   xsibh2.item_code      =  cgv.item_cd          -- 品目コード
                             AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                             AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                             AND     xsibh2.discrete_cost  IS NOT NULL             -- 営業原価 IS NOT NULL
                           )
                       )
                   , 0
                 )
             END                            now_business_cost   --営業原価
             --
             -- 定価
             -- パラメータ：新旧原価区分
            ,CASE iv_p_new_old_cost_class
               --
               -- 10：新原価 選択時
               WHEN cv_new_cost THEN
                 NVL(cgv.now_unit_price, 0)
               --
               -- 20：旧原価 選択時
               WHEN cv_old_cost THEN
                 NVL(
                       (
                         -- 前年度の定価を品目変更履歴から取得
                         SELECT  TO_CHAR(xsibh.fixed_price)    AS  fixed_price     -- 定価
                         FROM    xxcmm_system_items_b_hst      xsibh               -- 品目変更履歴
                         WHERE   xsibh.item_hst_id   =
                           (
                             -- 前年度の品目変更履歴ID
                             SELECT  MAX(item_hst_id)      AS item_hst_id          -- 品目変更履歴ID
                             FROM    xxcmm_system_items_b_hst xsibh2               -- 品目変更履歴
                             WHERE   xsibh2.item_code      =  cgv.item_cd          -- 品目コード
                             AND     xsibh2.apply_date     <  gd_gl_start_date     -- 起動時の年度開始日
                             AND     xsibh2.apply_flag     =  cv_flg_y             -- 適用済み
                             AND     xsibh2.fixed_price    IS NOT NULL             -- 定価 IS NOT NULL
                           )
                       )
                   , 0
                 )
             END                            now_unit_price      --定価
            ,ipl.amount                     amount              --数量
            ,ipl.sales_budget               sales_budget        --売上
          FROM
             xxcsm_item_plan_headers   iph   --商品計画ヘッダテーブル
            ,xxcsm_item_plan_lines     ipl   --商品計画明細テーブル
            ,xxcsm_commodity_group4_v  cgv   --商品群４ビュー
          WHERE
             iph.item_plan_header_id = ipl.item_plan_header_id
          AND
             ipl.item_no = cgv.item_cd
          AND
             iph.plan_year = in_yyyy
          AND
             iph.location_cd = iv_kyoten_cd
          AND
             ipl.item_kbn <> cv_item_kbn
      ) sub
      GROUP BY
         sub.group1_cd                         --商品群コード１
        ,sub.group1_nm                         --商品群名称１
        ,sub.group4_cd                         --商品群コード４
        ,sub.group4_nm                         --商品群名称４
        ,sub.item_cd                           --品目コード
        ,sub.item_nm                           --品目名称
        ,sub.now_item_cost                     --標準原価
        ,sub.now_business_cost                 --営業原価
        ,sub.now_unit_price                    --定価
      ORDER BY
         sub.group1_cd                         --商品群コード１
        ,sub.group4_cd                         --商品群コード４
        ,sub.item_cd                           --品目コード
      ;
--//+UPD END E_本稼動_09949 K.Taniguchi
    -- 年間商品計画データレコード型
    item_plan_rec item_plan_cur%ROWTYPE;
    -- 商品計画累計営業原価ワークテーブルレコード型
    lr_plan_rec    xxcsm_tmp_item_plan_sales_sum%ROWTYPE;
    -- データ抽出用レコード型
    lr_sum_rec     g_sum_data_rtype;
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

    gn_target_cnt := gn_target_cnt + 1;

    -- =============================================
    -- 年間商品計画データ存在チェック(A-3)
    -- =============================================
    chk_plandata(
              iv_yyyy              -- 対象年度
             ,iv_kyoten_cd         -- 拠点コード
             ,lv_errbuf            -- エラー・メッセージ
             ,lv_retcode           -- リターン・コード
             ,lv_errmsg);
    -- 例外処理
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt +1;
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_normal) THEN
      -- =============================================
      -- 按分処理済データ存在チェック(A-4)
      -- =============================================
      chk_propdata(
                iv_yyyy              -- 対象年度
               ,iv_kyoten_cd         -- 拠点コード
               ,lv_errbuf            -- エラー・メッセージ
               ,lv_retcode           -- リターン・コード
               ,lv_errmsg);
      -- 例外処理
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_normal) THEN
        -- =============================================
        -- 年間商品計画データの抽出(A-5)
        -- =============================================
        -- １行目のみ拠点コード、名称を出力するための変数設定
        lv_kyoten_cd := iv_kyoten_cd;
        lv_kyoten_nm := iv_kyoten_nm;
--//+UPD START E_本稼動_09949 K.Taniguchi
--      OPEN item_plan_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd);
        OPEN item_plan_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd, iv_p_new_old_cost_class);
--//+UPD END E_本稼動_09949 K.Taniguchi
        <<item_plan_loop>>
        LOOP
          FETCH item_plan_cur INTO item_plan_rec;

          lt_pre_group1_cd := lt_group1_cd;
          lt_pre_group4_cd := lt_group4_cd;
          IF item_plan_cur%NOTFOUND THEN
            lt_group1_cd     := cv_exit_group1_cd;
            lt_group4_cd     := cv_exit_group4_cd;
          ELSE
            lt_group1_cd     := item_plan_rec.group1_cd;
            lt_group4_cd     := item_plan_rec.group4_cd;
          END IF;

          -- 商品群が変わったら商品群計を登録
          IF (lt_group4_cd <> lt_pre_group4_cd) THEN
            -- １件目はlt_pre_group4_cdがNULLのためここに入らない（NULLの比較はFALSE）
            -- =============================================
            -- データの抽出（商品群）(A-8)
            -- =============================================
            select_grp4_total_data(
                        lt_pre_group4_cd     -- 商品群コード４
                       ,lr_sum_rec           -- 抽出レコード
                       ,lv_errbuf            -- エラー・メッセージ
                       ,lv_retcode           -- リターン・コード
                       ,lv_errmsg);
            -- 例外処理
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              gn_error_cnt := gn_error_cnt + 1;
              RAISE global_process_expt;
            END IF;

            -- 売上金額＞０の場合に登録
--//+UPD START 2009/02/20   CT053 M.Ohtsuki
--            IF (lr_sum_rec.sales_budget > 0) THEN
-- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--            IF (lr_sum_rec.sales_budget <> 0) THEN
            IF lr_sum_rec.sales_budget <> 0 OR lr_sum_rec.amount <> 0 THEN
-- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--//+UPD END   2009/02/20   CT053 M.Ohtsuki
              -- =============================================
              -- データの算出（商品群）(A-9)
              -- =============================================
              --粗利益率
              IF (lr_sum_rec.sales_budget = 0) THEN
                ln_margin_rate := 0;
              ELSE
                ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
              END IF;
              --掛率
              IF (lr_sum_rec.price_multi_amount = 0) THEN
                ln_credit_rate := 0;
              ELSE
                ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
              END IF;

              -- =============================================
              -- データの登録（商品群）(A-10)
              -- =============================================
              lr_plan_rec.location_cd            := NULL;                       -- 拠点コード
              lr_plan_rec.location_nm            := NULL;                       -- 拠点名称
              lr_plan_rec.group1_cd              := NULL;                       -- 商品群コード１
              lr_plan_rec.group1_nm              := NULL;                       -- 商品群名称１
              lr_plan_rec.group4_cd              := NULL;                       -- 商品群コード４
              lr_plan_rec.group4_nm              := NULL;                       -- 商品群名称４
              lr_plan_rec.item_cd                := lr_sum_rec.group_cd;        -- 商品コード
              lr_plan_rec.item_nm                := lr_sum_rec.group_nm;        -- 商品名称
              lr_plan_rec.con_price              := lr_sum_rec.con_price;       -- 定価
              lr_plan_rec.amount                 := lr_sum_rec.amount;          -- 数量
              lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- 売上
              lr_plan_rec.cost                   := lr_sum_rec.cost;            -- 原価
              lr_plan_rec.margin                 := lr_sum_rec.margin;          -- 粗利益額
              lr_plan_rec.margin_rate            := ln_margin_rate;             -- 粗利益率
              lr_plan_rec.credit_rate            := ln_credit_rate;             -- 掛率

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
              END IF;
            END IF;
          END IF;
          -- 商品区分が変わったら商品区分計を登録
          IF (lt_group1_cd <> lt_pre_group1_cd) THEN
            -- １件目はlt_pre_group1_cdがNULLのためここに入らない（NULLの比較はFALSE）
            -- =============================================
            -- データの抽出（商品区分）(A-11)
            -- =============================================
            select_grp1_total_data(
                      lt_pre_group1_cd     -- 商品群コード１
                     ,lr_sum_rec           -- 抽出レコード
                     ,lv_errbuf            -- エラー・メッセージ
                     ,lv_retcode           -- リターン・コード
                     ,lv_errmsg);
            -- 例外処理
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              gn_error_cnt := gn_error_cnt +1;
              RAISE global_process_expt;
            END IF;

            -- =============================================
            -- データの算出（商品区分）(A-12)
            -- =============================================
            --粗利益率
            IF (lr_sum_rec.sales_budget = 0) THEN
              ln_margin_rate := 0;
            ELSE
              ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
            END IF;
            --掛率
            IF (lr_sum_rec.price_multi_amount = 0) THEN
              ln_credit_rate := 0;
            ELSE
              ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
            END IF;

            -- =============================================
            -- データの登録（商品区分）(A-13)
            -- =============================================
--//+UPD START 2009/02/20   CT051 M.Ohtsuki
--            lr_plan_rec.location_cd            := NULL;                       -- 拠点コード
--            lr_plan_rec.location_nm            := NULL;                       -- 拠点名称
            lr_plan_rec.location_cd            := lv_kyoten_cd;               -- 拠点コード
            lr_plan_rec.location_nm            := lv_kyoten_nm;               -- 拠点名称
--//+UPD END   2009/02/20   CT051 M.Ohtsuki
            lr_plan_rec.group1_cd              := NULL;                       -- 商品群コード１
            lr_plan_rec.group1_nm              := NULL;                       -- 商品群名称１
            lr_plan_rec.group4_cd              := NULL;                       -- 商品群コード４
            lr_plan_rec.group4_nm              := NULL;                       -- 商品群名称４
            lr_plan_rec.item_cd                := lr_sum_rec.group_cd;        -- 商品コード
            lr_plan_rec.item_nm                := lr_sum_rec.group_nm;        -- 商品名称
            lr_plan_rec.con_price              := lr_sum_rec.con_price;       -- 定価
            lr_plan_rec.amount                 := lr_sum_rec.amount;          -- 数量
            lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- 売上
            lr_plan_rec.cost                   := lr_sum_rec.cost;            -- 原価
            lr_plan_rec.margin                 := lr_sum_rec.margin;          -- 粗利益額
            lr_plan_rec.margin_rate            := ln_margin_rate;             -- 粗利益率
            lr_plan_rec.credit_rate            := ln_credit_rate;             -- 掛率

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
            END IF;
--//+ADD START 2009/02/12   CT051 M.Ohtsuki
            lv_kyoten_cd := NULL;
            lv_kyoten_nm := NULL;
--//+ADD END   2009/02/12   CT051 M.Ohtsuki
            -- 商品区分（DRINK）が終了したら
            IF (lt_pre_group1_cd = cv_drink) THEN
              -- =============================================
              -- データの抽出（商品合計）(A-14)
              -- =============================================
              select_com_total_data(
                      lr_sum_rec           -- 抽出レコード
                     ,lv_errbuf            -- エラー・メッセージ
                     ,lv_retcode           -- リターン・コード
                     ,lv_errmsg);
              -- 例外処理
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                gn_error_cnt := gn_error_cnt +1;
                RAISE global_process_expt;
              END IF;

              -- =============================================
              -- データの算出（商品合計）(A-15)
              -- =============================================
              --粗利益率
              IF (lr_sum_rec.sales_budget = 0) THEN
                ln_margin_rate := 0;
              ELSE
                ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
              END IF;
              --掛率
              IF (lr_sum_rec.price_multi_amount = 0) THEN
                ln_credit_rate := 0;
              ELSE
                ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
              END IF;

              -- =============================================
              -- データの登録（商品合計）(A-16)
              -- =============================================
              lr_plan_rec.location_cd            := NULL;                       -- 拠点コード
              lr_plan_rec.location_nm            := NULL;                       -- 拠点名称
              lr_plan_rec.group1_cd              := NULL;                       -- 商品群コード１
              lr_plan_rec.group1_nm              := NULL;                       -- 商品群名称１
              lr_plan_rec.group4_cd              := NULL;                       -- 商品群コード４
              lr_plan_rec.group4_nm              := NULL;                       -- 商品群名称４
              lr_plan_rec.item_cd                := NULL;                       -- 商品コード
              lr_plan_rec.item_nm                := gv_total_com_nm;            -- 商品名称
              lr_plan_rec.con_price              := NULL;                       -- 定価
              lr_plan_rec.amount                 := lr_sum_rec.amount;          -- 数量
              lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- 売上
              lr_plan_rec.cost                   := lr_sum_rec.cost;            -- 原価
              lr_plan_rec.margin                 := lr_sum_rec.margin;          -- 粗利益額
              lr_plan_rec.margin_rate            := ln_margin_rate;             -- 粗利益率
              lr_plan_rec.credit_rate            := ln_credit_rate;             -- 掛率

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
              END IF;
            END IF;

            --lt_pre_group1_cd := lt_group1_cd;

          END IF;

          EXIT WHEN item_plan_cur%NOTFOUND;

          -- 売上金額＞０の場合に商品明細を登録
--//+UPD START 2009/02/20   CT053 M.Ohtsuki
--          IF (item_plan_rec.sales_budget > 0) THEN
-- MODIFY  START  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--          IF (item_plan_rec.sales_budget <> 0) THEN
          IF item_plan_rec.sales_budget <> 0 OR item_plan_rec.amount <> 0 THEN
-- MODIFY  END  DATE:2011/01/05  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--//+UPD END   2009/02/20   CT053 M.Ohtsuki
            -- =============================================
            -- データの算出（商品）(A-6)
            -- =============================================
            --原価
            IF (iv_p_cost_kind = cv_cost_base) THEN
              ln_cost := item_plan_rec.base_price * item_plan_rec.amount;       --標準原価
            ELSIF (iv_p_cost_kind = cv_cost_bus) THEN
              ln_cost := item_plan_rec.bus_price * item_plan_rec.amount;        --営業原価
            END IF;
            --粗利益額
            ln_margin := item_plan_rec.sales_budget - ln_cost;
            --粗利益率
            IF (item_plan_rec.sales_budget = 0) THEN
              ln_margin_rate := 0;
            ELSE
              ln_margin_rate := ROUND(ln_margin / item_plan_rec.sales_budget * 100, 2);
            END IF;
            --掛率
            IF ((item_plan_rec.con_price = 0) OR (item_plan_rec.amount = 0)) THEN
              ln_credit_rate := 0;
            ELSE
              ln_credit_rate := ROUND(item_plan_rec.sales_budget / (item_plan_rec.con_price * item_plan_rec.amount) * 100, 2);
            END IF;

            -- =============================================
            -- データの登録（商品）(A-7)
            -- =============================================
            lr_plan_rec.location_cd            := lv_kyoten_cd;               -- 拠点コード
            lr_plan_rec.location_nm            := lv_kyoten_nm;               -- 拠点名称
            lr_plan_rec.group1_cd              := item_plan_rec.group1_cd;    -- 商品群コード１
            lr_plan_rec.group1_nm              := item_plan_rec.group1_nm;    -- 商品群名称１
            lr_plan_rec.group4_cd              := item_plan_rec.group4_cd;    -- 商品群コード４
            lr_plan_rec.group4_nm              := item_plan_rec.group4_nm;    -- 商品群名称４
            lr_plan_rec.item_cd                := item_plan_rec.item_cd;      -- 商品コード
            lr_plan_rec.item_nm                := item_plan_rec.item_nm;      -- 商品名称
            lr_plan_rec.con_price              := item_plan_rec.con_price;    -- 定価
            lr_plan_rec.amount                 := item_plan_rec.amount;       -- 数量
            lr_plan_rec.sales_budget           := item_plan_rec.sales_budget; -- 売上
            lr_plan_rec.cost                   := ln_cost;                    -- 原価
            lr_plan_rec.margin                 := ln_margin;                  -- 粗利益額
            lr_plan_rec.margin_rate            := ln_margin_rate;             -- 粗利益率
            lr_plan_rec.credit_rate            := ln_credit_rate;             -- 掛率

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
            END IF;
            -- １行目のみ拠点コード、名称を出力するためクリア
            lv_kyoten_cd := NULL;
            lv_kyoten_nm := NULL;

          END IF;

        END LOOP item_plan_loop;
        CLOSE item_plan_cur;

        -- =============================================
        -- データの抽出（売上値引／入金値引）(A-17)
        -- =============================================
        select_discount_data(
                    iv_yyyy              -- 対象年度
                   ,iv_kyoten_cd         -- 拠点コード
                   ,ln_sales_discount    -- 売上値引
                   ,ln_receipt_discount  -- 入金値引
                   ,lv_errbuf            -- エラー・メッセージ
                   ,lv_retcode           -- リターン・コード
                   ,lv_errmsg);
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- データの登録（売上値引／入金値引）(A-18)
        -- =============================================
        lr_plan_rec.location_cd            := NULL;                       -- 拠点コード
        lr_plan_rec.location_nm            := NULL;                       -- 拠点名称
        lr_plan_rec.group1_cd              := cv_nebiki;                  -- 商品群コード１
        lr_plan_rec.group1_nm              := NULL;                       -- 商品群名称１
        lr_plan_rec.group4_cd              := NULL;                       -- 商品群コード４
        lr_plan_rec.group4_nm              := NULL;                       -- 商品群名称４
        lr_plan_rec.item_cd                := NULL;                       -- 商品コード
        lr_plan_rec.item_nm                := gv_sales_disc_nm;           -- 商品名称
        lr_plan_rec.con_price              := NULL;                       -- 定価
        lr_plan_rec.amount                 := 0;                          -- 数量
        lr_plan_rec.sales_budget           := ln_sales_discount;          -- 売上値引
        lr_plan_rec.cost                   := 0;                          -- 原価
        lr_plan_rec.margin                 := ln_sales_discount;          -- 粗利益額
        lr_plan_rec.margin_rate            := cv_margin_rate_dis;         -- 粗利益率
        lr_plan_rec.credit_rate            := 0;                          -- 掛率
--
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
        END IF;
--
        lr_plan_rec.location_cd            := NULL;                       -- 拠点コード
        lr_plan_rec.location_nm            := NULL;                       -- 拠点名称
        lr_plan_rec.group1_cd              := cv_nebiki;                  -- 商品群コード１
        lr_plan_rec.group1_nm              := NULL;                       -- 商品群名称１
        lr_plan_rec.group4_cd              := NULL;                       -- 商品群コード４
        lr_plan_rec.group4_nm              := NULL;                       -- 商品群名称４
        lr_plan_rec.item_cd                := NULL;                       -- 商品コード
        lr_plan_rec.item_nm                := gv_receipt_disc_nm;         -- 商品名称
        lr_plan_rec.con_price              := NULL;                       -- 定価
        lr_plan_rec.amount                 := 0;                          -- 数量
        lr_plan_rec.sales_budget           := ln_receipt_discount;        -- 入金値引
        lr_plan_rec.cost                   := 0;                          -- 原価
        lr_plan_rec.margin                 := ln_receipt_discount;        -- 粗利益額
        lr_plan_rec.margin_rate            := cv_margin_rate_dis;         -- 粗利益率
        lr_plan_rec.credit_rate            := 0;                          -- 掛率
--
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
        END IF;
        -- =============================================
        -- データの抽出（拠点合計）(A-19)
        -- =============================================
        select_kyot_total_data(
                    lr_sum_rec           -- 抽出レコード
                   ,lv_errbuf            -- エラー・メッセージ
                   ,lv_retcode           -- リターン・コード
                   ,lv_errmsg);
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- データの算出（拠点合計）(A-20)
        -- =============================================
        --粗利益率
        IF (lr_sum_rec.sales_budget = 0) THEN
          ln_margin_rate := 0;
        ELSE
          ln_margin_rate := ROUND(lr_sum_rec.margin / lr_sum_rec.sales_budget * 100, 2);
        END IF;
        --掛率
        IF (lr_sum_rec.price_multi_amount = 0) THEN
          ln_credit_rate := 0;
        ELSE
          ln_credit_rate := ROUND(lr_sum_rec.sales_budget / lr_sum_rec.price_multi_amount * 100, 2);
        END IF;
        -- =============================================
        -- データの登録（拠点合計）(A-21)
        -- =============================================
        lr_plan_rec.location_cd            := NULL;                       -- 拠点コード
        lr_plan_rec.location_nm            := NULL;                       -- 拠点名称
        lr_plan_rec.group1_cd              := cv_kyoten_kei;              -- 商品群コード１
        lr_plan_rec.group1_nm              := NULL;                       -- 商品群名称１
        lr_plan_rec.group4_cd              := NULL;                       -- 商品群コード４
        lr_plan_rec.group4_nm              := NULL;                       -- 商品群名称４
        lr_plan_rec.item_cd                := NULL;                       -- 商品コード
        lr_plan_rec.item_nm                := gv_kyoten_kei_nm;           -- 商品名称
        lr_plan_rec.con_price              := NULL;                       -- 定価
        lr_plan_rec.amount                 := lr_sum_rec.amount;          -- 数量
        lr_plan_rec.sales_budget           := lr_sum_rec.sales_budget;    -- 売上
        lr_plan_rec.cost                   := lr_sum_rec.cost;            -- 原価
        lr_plan_rec.margin                 := lr_sum_rec.margin;          -- 粗利益額
        lr_plan_rec.margin_rate            := ln_margin_rate;             -- 粗利益率
        lr_plan_rec.credit_rate            := ln_credit_rate;             -- 掛率

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
        END IF;
        gn_normal_cnt := gn_normal_cnt + 1;
        -- =============================================
        -- チェックリストデータ出力(A-22)
        -- =============================================
        output_check_list(
                    iv_yyyy              -- 対象年度
                   ,iv_p_kyoten_cd       -- 拠点コード（パラメータ）
                   ,iv_kyoten_cd         -- 拠点コード
                   ,iv_kyoten_nm         -- 拠点名
                   ,lv_errbuf            -- エラー・メッセージ
                   ,lv_retcode           -- リターン・コード
                   ,lv_errmsg);
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt +1;
          RAISE global_process_expt;
        END IF;

      END IF;
    END IF;
    -- =============================================
    -- データ削除
    -- =============================================
    DELETE FROM xxcsm_tmp_item_plan_sales_sum;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_kyoten;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : メインループ
   ***********************************************************************************/
  PROCEDURE loop_main(
    iv_p_yyyy       IN  VARCHAR2,            -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード
    iv_p_cost_kind  IN  VARCHAR2,            -- 3.原価種別
    iv_p_level      IN  VARCHAR2,            -- 4.階層
--//+ADD START E_本稼動_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2,            -- 5.新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- プログラム名
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
    cv_lvl6   CONSTANT VARCHAR2(2) := 'L6'; -- 拠点階層
    cv_lvl2   CONSTANT VARCHAR2(2) := 'L2'; -- 拠点階層
    cv_lvl3   CONSTANT VARCHAR2(2) := 'L3'; -- 拠点階層
    cv_lvl4   CONSTANT VARCHAR2(2) := 'L4'; -- 拠点階層
    cv_lvl5   CONSTANT VARCHAR2(2) := 'L5'; -- 拠点階層
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 拠点データL6
    CURSOR kyoten_l6_cur(
      iv_p_kyoten_cd  IN  VARCHAR2,                                 -- 拠点コード（パラメータ）
      it_allkyoten_cd IN  fnd_lookup_values.lookup_code%TYPE)       -- 全拠点コード
    IS
      SELECT
         nmv.base_code    base_code   --部門コード
        ,nmv.base_name    base_name   --部門名
      FROM
         xxcsm_loc_level_list_v  lvv  --部門一覧ビュー
        ,xxcsm_loc_name_list_v   nmv  --部門名称ビュー
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,cv_lvl4, lvv.cd_level4
                  ,cv_lvl3, lvv.cd_level3
                  ,cv_lvl2, lvv.cd_level2) = nmv.base_code
      AND
         nmv.base_code = DECODE(iv_p_kyoten_cd, it_allkyoten_cd, nmv.base_code, iv_p_kyoten_cd)
--// ADD START 2009/05/07 T1_0858 M.Ohtsuki
-- DEL  START  DATE:2011/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--      AND EXISTS
--          (SELECT 'X'
--           FROM   xxcsm_item_plan_result   xipr                                                     -- 商品計画用販売実績
--           WHERE  (xipr.subject_year = (TO_NUMBER(iv_p_yyyy) - 1)                                   -- 入力パラメータの1年前のデータ
--                OR xipr.subject_year = (TO_NUMBER(iv_p_yyyy) - 2))                                  -- 入力パラメータの2年前のデータ
--           AND     xipr.location_cd  = nmv.base_code)
-- DEL  END  DATE:2010/01/06  AUTHOR:OUKOU  CONTENT:E-本稼動_05803
--// ADD END   2009/05/07 T1_0858 M.Ohtsuki
      ORDER BY
         nmv.base_code    --部門コード
      ;
    -- 拠点データL6レコード型
    kyoten_rec kyoten_l6_cur%ROWTYPE;

    -- 拠点データL2
    CURSOR kyoten_l2_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- 拠点コード（パラメータ）
    IS
      SELECT
         nmv.base_code    base_code   --部門コード
        ,nmv.base_name    base_name   --部門名
      FROM
         xxcsm_loc_level_list_v  lvv  --部門一覧ビュー
        ,xxcsm_loc_name_list_v   nmv  --部門名称ビュー
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,cv_lvl4, lvv.cd_level4
                  ,cv_lvl3, lvv.cd_level3
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level2 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --部門コード
      ;

    -- 拠点データL3
    CURSOR kyoten_l3_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- 拠点コード（パラメータ）
    IS
      SELECT
         nmv.base_code    base_code   --部門コード
        ,nmv.base_name    base_name   --部門名
      FROM
         xxcsm_loc_level_list_v  lvv  --部門一覧ビュー
        ,xxcsm_loc_name_list_v   nmv  --部門名称ビュー
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,cv_lvl4, lvv.cd_level4
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level3 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --部門コード
      ;

    -- 拠点データL4
    CURSOR kyoten_l4_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- 拠点コード（パラメータ）
    IS
      SELECT
         nmv.base_code    base_code   --部門コード
        ,nmv.base_name    base_name   --部門名
      FROM
         xxcsm_loc_level_list_v  lvv  --部門一覧ビュー
        ,xxcsm_loc_name_list_v   nmv  --部門名称ビュー
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,cv_lvl5, lvv.cd_level5
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level4 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --部門コード
      ;

    -- 拠点データL5
    CURSOR kyoten_l5_cur(
      iv_p_kyoten_cd  IN  VARCHAR2)     -- 拠点コード（パラメータ）
    IS
      SELECT
         nmv.base_code    base_code   --部門コード
        ,nmv.base_name    base_name   --部門名
      FROM
         xxcsm_loc_level_list_v  lvv  --部門一覧ビュー
        ,xxcsm_loc_name_list_v   nmv  --部門名称ビュー
      WHERE
         DECODE(lvv.location_level
                  ,cv_lvl6, lvv.cd_level6
                  ,NULL) = nmv.base_code
      AND
         lvv.cd_level5 = iv_p_kyoten_cd
      ORDER BY
         nmv.base_code    --部門コード
      ;

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =============================================
    -- データの抽出（拠点データ）取得(A-2)
    -- =============================================
    CASE iv_p_level
      WHEN cv_lvl6 THEN
        OPEN kyoten_l6_cur(iv_p_kyoten_cd, gt_allkyoten_cd);
        <<kyoten_l6_loop>>
        LOOP
          FETCH kyoten_l6_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l6_cur%NOTFOUND;
          -- ===============================
          -- 拠点ループ内処理
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- 対象年度
            iv_p_kyoten_cd,                                    -- 拠点コード（パラメータ）
            iv_p_cost_kind,                                    -- 原価種別
            kyoten_rec.base_code,                              -- 拠点コード
            kyoten_rec.base_name,                              -- 拠点名
--//+ADD START E_本稼動_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l6_loop;
        CLOSE kyoten_l6_cur;
      WHEN cv_lvl2 THEN
        OPEN kyoten_l2_cur(iv_p_kyoten_cd);
        <<kyoten_l2_loop>>
        LOOP
          FETCH kyoten_l2_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l2_cur%NOTFOUND;
          -- ===============================
          -- 拠点ループ内処理
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- 対象年度
            iv_p_kyoten_cd,                                    -- 拠点コード（パラメータ）
            iv_p_cost_kind,                                    -- 原価種別
            kyoten_rec.base_code,                              -- 拠点コード
            kyoten_rec.base_name,                              -- 拠点名
--//+ADD START E_本稼動_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l2_loop;
        CLOSE kyoten_l2_cur;
      WHEN cv_lvl3 THEN
        OPEN kyoten_l3_cur(iv_p_kyoten_cd);
        <<kyoten_l3_loop>>
        LOOP
          FETCH kyoten_l3_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l3_cur%NOTFOUND;
          -- ===============================
          -- 拠点ループ内処理
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- 対象年度
            iv_p_kyoten_cd,                                    -- 拠点コード（パラメータ）
            iv_p_cost_kind,                                    -- 原価種別
            kyoten_rec.base_code,                              -- 拠点コード
            kyoten_rec.base_name,                              -- 拠点名
--//+ADD START E_本稼動_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l3_loop;
        CLOSE kyoten_l3_cur;
      WHEN cv_lvl4 THEN
        OPEN kyoten_l4_cur(iv_p_kyoten_cd);
        <<kyoten_l4_loop>>
        LOOP
          FETCH kyoten_l4_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l4_cur%NOTFOUND;
          -- ===============================
          -- 拠点ループ内処理
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- 対象年度
            iv_p_kyoten_cd,                                    -- 拠点コード（パラメータ）
            iv_p_cost_kind,                                    -- 原価種別
            kyoten_rec.base_code,                              -- 拠点コード
            kyoten_rec.base_name,                              -- 拠点名
--//+ADD START E_本稼動_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l4_loop;
        CLOSE kyoten_l4_cur;
      WHEN cv_lvl5 THEN
        OPEN kyoten_l5_cur(iv_p_kyoten_cd);
        <<kyoten_l5_loop>>
        LOOP
          FETCH kyoten_l5_cur INTO kyoten_rec;
          EXIT WHEN kyoten_l5_cur%NOTFOUND;
          -- ===============================
          -- 拠点ループ内処理
          -- ===============================
          loop_kyoten(
            iv_p_yyyy,                                         -- 対象年度
            iv_p_kyoten_cd,                                    -- 拠点コード（パラメータ）
            iv_p_cost_kind,                                    -- 原価種別
            kyoten_rec.base_code,                              -- 拠点コード
            kyoten_rec.base_name,                              -- 拠点名
--//+ADD START E_本稼動_09949 K.Taniguchi
            iv_p_new_old_cost_class,                           -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP kyoten_l5_loop;
        CLOSE kyoten_l5_cur;
--
      ELSE
        NULL;
    END CASE;

--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (kyoten_l6_cur%ISOPEN) THEN
        CLOSE kyoten_l6_cur;
      END IF;
      IF (kyoten_l2_cur%ISOPEN) THEN
        CLOSE kyoten_l2_cur;
      END IF;
      IF (kyoten_l3_cur%ISOPEN) THEN
        CLOSE kyoten_l3_cur;
      END IF;
      IF (kyoten_l4_cur%ISOPEN) THEN
        CLOSE kyoten_l4_cur;
      END IF;
      IF (kyoten_l5_cur%ISOPEN) THEN
        CLOSE kyoten_l5_cur;
      END IF;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_p_yyyy       IN  VARCHAR2,     -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,     -- 2.拠点コード
    iv_p_cost_kind  IN  VARCHAR2,     -- 3.原価種別
    iv_p_level      IN  VARCHAR2,     -- 4.階層
--//+ADD START E_本稼動_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2,     -- 5.新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--//+ADD START 2009/02/12   CT007 M.Ohtsuki
    lv_nodata_msg          VARCHAR2(100);
    lv_header              VARCHAR2(4000);
--//+ADD END   2009/02/12   CT007 M.Ohtsuki
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(                                   -- initをコール
       iv_p_yyyy                            -- 対象年度
      ,iv_p_kyoten_cd                       -- 拠点コード
      ,iv_p_cost_kind                       -- 原価種別
      ,iv_p_level                           -- 階層
--//+ADD START E_本稼動_09949 K.Taniguchi
      ,iv_p_new_old_cost_class              -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
      ,lv_errbuf                            -- エラー・メッセージ
      ,lv_retcode                           -- リターン・コード
      ,lv_errmsg                            -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN  -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- メインループ
    -- ===============================
    loop_main(                              -- loop_mainをコール
       iv_p_yyyy                            -- 対象年度
      ,iv_p_kyoten_cd                       -- 拠点コード
      ,iv_p_cost_kind                       -- 原価種別
      ,iv_p_level                           -- 階層
--//+ADD START E_本稼動_09949 K.Taniguchi
      ,iv_p_new_old_cost_class              -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
      ,lv_errbuf                            -- エラー・メッセージ
      ,lv_retcode                           -- リターン・コード
      ,lv_errmsg                            -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN  -- 戻り値が以上の場合
      RAISE global_process_expt;
    END IF;
    -- 出力できなかったものがあった場合は警告終了
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
    END IF;
--//+ADD START 2009/02/12   CT007 M.Ohtsuki
    IF (gn_normal_cnt = 0) THEN
      lv_header := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm
                   ,iv_name         => cv_lst_head_msg
                   ,iv_token_name1  => cv_tkn_cd_yyyy
                   ,iv_token_value1 => iv_p_yyyy
                   ,iv_token_name2  => cv_tkn_nichiji
                   ,iv_token_value2 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                   ,iv_token_name3  => cv_tkn_cost_kind_nm
                   ,iv_token_value3 => gv_cost_kind_nm
                 );
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcsm
                         ,iv_name         => cv_nodata_msg
                        );
      -- データ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_header || CHR(10) ||
                   lv_nodata_msg
         );
--//+ADD START 2009/07/15   0000678 M.Ohtsuki
      ov_retcode := cv_status_warn;
--//+ADD END   2009/07/15   0000678 M.Ohtsuki
    END IF;
--//+ADD END   2009/02/12   CT007 M.Ohtsuki
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    errbuf          OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_p_yyyy       IN  VARCHAR2,      -- 1.対象年度
    iv_p_kyoten_cd  IN  VARCHAR2,      -- 2.拠点コード
    iv_p_cost_kind  IN  VARCHAR2,      -- 3.原価種別
    iv_p_level      IN  VARCHAR2,      -- 4.階層
--//+ADD START E_本稼動_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2       -- 5.新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
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
    cv_which_log       CONSTANT VARCHAR2(10)  := 'LOG';              -- 出力先
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
       iv_which   => cv_which_log
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
       iv_p_yyyy                                   -- 対象年度
      ,iv_p_kyoten_cd                              -- 拠点コード
      ,iv_p_cost_kind                              -- 原価種別
      ,iv_p_level                                  -- 階層
--//+ADD START E_本稼動_09949 K.Taniguchi
      ,iv_p_new_old_cost_class                     -- 新旧原価区分
--//+ADD END E_本稼動_09949 K.Taniguchi
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --件数の振替(エラーの場合、エラー件数を1件のみ表示させる。）
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
    --空行挿入
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
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
END XXCSM002A10C;
/
