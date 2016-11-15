CREATE OR REPLACE PACKAGE BODY XXCFF003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A03C(body)
 * Description      : リース種類判定
 * MD.050           : MD050_CFF_003_A03_リース種類判定
 * Version          : 1.2
 *
 * Program List
 * ------------------------- ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * ------------------------- ---- ----- --------------------------------------------------
 *  check_in_param            P          入力項目チェック処理         (A-1)
 *  judge_lease_type          F    VAR   リース区分判定処理           (A-2)
 *  calc_discount_rate        P          現在価値割引率算定処理       (A-3)
 *  calc_present_value_re     F    NUM   再リース現在価値算定処理     (A-9)
 *  calc_debt_lease           P          リース負債額算定処理         (A-8)
 *  calc_present_value        F    NUM   現在価値算定処理             (A-4)
 *  judge_lease_kind          F    VAR   リース種類判定処理           (A-5)
 *  calc_original_cost        F    NUM   取得価額算定処理             (A-6)
 *  calc_interested_rate      P          計算利子率算定処理           (A-7)
 *  main                      P          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-04    1.0   SCS 増子 秀幸    新規作成
 *  2016-08-10    1.1   SCSK 仁木 重人   [E_本稼動_13658]自販機耐用年数変更対応
 *  2016-10-26    1.2   SCSK郭           E_本稼動_13658 自販機耐用年数変更対応・フェーズ3
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
--
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF003A03C';  -- パッケージ名
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';         -- アプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_cff_00005   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00005';  -- 必須チェックエラー
  cv_msg_cff_00059   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00059';  -- リース区分エラー
  cv_msg_cff_00088   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00088';  -- 計算エラー
  cv_msg_cff_00089   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00089';  -- 割引率取得エラー
  cv_msg_cff_00109   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00109';  -- 割引率未設定エラー
--
  -- トークン
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15) := 'INPUT';    -- 未入力項目名
--
  -- トークン値
  cv_msg_cff_50032   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50032';  -- 法定耐用年数
  cv_msg_cff_50033   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50033';  -- 支払回数
  cv_msg_cff_50108   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50108';  -- 初回月額リース料
  cv_msg_cff_50109   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50109';  -- ２回目以降月額リース料
  cv_msg_cff_50110   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50110';  -- 見積現金購入価額
  cv_msg_cff_50111   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50111';  -- 契約年月
-- Ver.1.1 ADD Start
  cv_msg_cff_50041   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50041';  -- リース種別
-- Ver.1.1 ADD End
--
  -- リース区分
  cv_lease_type_1    CONSTANT VARCHAR2(1)  := '1';        -- 1:原契約
  cv_lease_type_2    CONSTANT VARCHAR2(1)  := '2';        -- 2:再リース契約
--
  -- リース種類
  cv_lease_kind_0    CONSTANT VARCHAR2(1)  := '0';        -- 0:Fin
  cv_lease_kind_1    CONSTANT VARCHAR2(1)  := '1';        -- 1:Op
  cv_lease_kind_2    CONSTANT VARCHAR2(1)  := '2';        -- 2:旧Fin
--
  -- 計算利子率
  cn_calc_rate_max   CONSTANT NUMBER       := 0.5;        -- 計算利子率MAX値:50%
  cn_calc_rate_min   CONSTANT NUMBER       := 0.0000001;  -- 計算利子率MIN値:0.00001%
--
-- Ver.1.1 ADD Start
  -- リース種別
  cv_lease_class_11  CONSTANT VARCHAR2(2)  := '11';       -- 11:自動販売機
  -- 再リース分支払回数
  cn_first_freq      CONSTANT NUMBER       := 61;         -- 再リース１回目
  cn_second_freq     CONSTANT NUMBER       := 73;         -- 再リース２回目
  cn_third_freq      CONSTANT NUMBER       := 85;         -- 再リース３回目
-- Ver.1.1 ADD End
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
  cd_start_date      CONSTANT DATE := TO_DATE('2016/05/01','YYYY/MM/DD');
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : check_in_param
   * Description      : 入力項目チェック処理 (A-1)
   ***********************************************************************************/
  PROCEDURE check_in_param(
    in_lease_type           IN  VARCHAR2,    -- 1.リース区分
    in_payment_frequency    IN  NUMBER,      -- 2.支払回数
    in_first_charge         IN  NUMBER,      -- 3.初回月額リース料
    in_second_charge        IN  NUMBER,      -- 4.２回目以降月額リース料
    in_estimated_cash_price IN  NUMBER,      -- 5.見積現金購入価額
    in_life_in_months       IN  NUMBER,      -- 6.法定耐用年数
    id_contract_ym          IN  DATE,        -- 7.契約年月
-- Ver.1.1 ADD Start
    iv_lease_class          IN  VARCHAR2,    -- 8.リース種別
-- Ver.1.1 ADD End
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ
    ov_retcode              OUT VARCHAR2,    -- リターン・コード
    ov_errmsg               OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'check_in_param';  -- プログラム名
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
    -- 入力項目チェック
    -- 1.リース区分
    IF ( (in_lease_type IS NULL)
      OR (in_lease_type NOT IN(cv_lease_type_1, cv_lease_type_2) ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- アプリケーション短縮名
                     iv_name        => cv_msg_cff_00059  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2.支払回数
    IF (in_payment_frequency IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50033     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3.初回月額リース料
    IF ( (in_first_charge IS NULL) OR (in_first_charge <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50108     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 4.２回目以降月額リース料
    IF ( (in_second_charge IS NULL) OR (in_second_charge <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50109     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 5.見積現金購入価額
    IF ( (in_estimated_cash_price IS NULL) OR (in_estimated_cash_price <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50110     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 6.法定耐用年数
    IF ( (in_life_in_months IS NULL) OR (in_life_in_months <= 0) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50032     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 7.契約年月
    IF (id_contract_ym IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50111     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD Start
    -- 8.リース種別
    IF (iv_lease_class IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,      -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00005,    -- メッセージコード
                     iv_token_name1  => cv_tk_cff_00005_01,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50041     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD End
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END check_in_param;
--
  /**********************************************************************************
   * Function Name    : judge_lease_type
   * Description      : リース区分判定処理 (A-2)
   ***********************************************************************************/
  FUNCTION judge_lease_type(
    in_lease_type IN VARCHAR2)    -- 1.リース区分
  RETURN VARCHAR2                 -- リース種類 '1'(Op)/NULL
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_lease_type';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_lease_kind VARCHAR2(1);  -- リース種類
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    lv_lease_kind := NULL;
--
    -- リース区分判定
    -- リース区分が'2'(再リース)の場合、リース種類に「Op」を設定
    IF (in_lease_type = cv_lease_type_2) THEN
      lv_lease_kind := cv_lease_kind_1;
    END IF;
--
    RETURN lv_lease_kind;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END judge_lease_type;
  /**********************************************************************************
   * Procedure Name   : calc_discount_rate
   * Description      : 現在価値割引率算定処理 (A-3)
   ***********************************************************************************/
  PROCEDURE calc_discount_rate(
    in_payment_frequency           IN  NUMBER,      -- 1.支払回数
    id_contract_ym                 IN  DATE,        -- 2.契約年月
    on_present_value_discount_rate OUT NUMBER,      -- 3.現在価値割引率
    ov_errbuf                      OUT VARCHAR2,    -- エラー・メッセージ
    ov_retcode                     OUT VARCHAR2,    -- リターン・コード
    ov_errmsg                      OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_discount_rate';  -- プログラム名
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
    ln_payment_years NUMBER;  -- 支払回数から算定する年数
    ln_discount_rate NUMBER;  -- 割引率
--
    -- *** ローカル・カーソル ***
    CURSOR get_discount_rate_rec_cur(
      p_application_date DATE)
    IS
      SELECT xdrm.discount_rate_01 discount_rate_01,
             xdrm.discount_rate_02 discount_rate_02,
             xdrm.discount_rate_03 discount_rate_03,
             xdrm.discount_rate_04 discount_rate_04,
             xdrm.discount_rate_05 discount_rate_05,
             xdrm.discount_rate_06 discount_rate_06,
             xdrm.discount_rate_07 discount_rate_07,
             xdrm.discount_rate_08 discount_rate_08,
             xdrm.discount_rate_09 discount_rate_09,
             xdrm.discount_rate_10 discount_rate_10,
             xdrm.discount_rate_11 discount_rate_11,
             xdrm.discount_rate_12 discount_rate_12,
             xdrm.discount_rate_13 discount_rate_13,
             xdrm.discount_rate_14 discount_rate_14,
             xdrm.discount_rate_15 discount_rate_15,
             xdrm.discount_rate_16 discount_rate_16,
             xdrm.discount_rate_17 discount_rate_17,
             xdrm.discount_rate_18 discount_rate_18,
             xdrm.discount_rate_19 discount_rate_19,
             xdrm.discount_rate_20 discount_rate_20,
             xdrm.discount_rate_21 discount_rate_21,
             xdrm.discount_rate_22 discount_rate_22,
             xdrm.discount_rate_23 discount_rate_23,
             xdrm.discount_rate_24 discount_rate_24,
             xdrm.discount_rate_25 discount_rate_25,
             xdrm.discount_rate_26 discount_rate_26,
             xdrm.discount_rate_27 discount_rate_27,
             xdrm.discount_rate_28 discount_rate_28,
             xdrm.discount_rate_29 discount_rate_29,
             xdrm.discount_rate_30 discount_rate_30,
             xdrm.discount_rate_31 discount_rate_31,
             xdrm.discount_rate_32 discount_rate_32,
             xdrm.discount_rate_33 discount_rate_33,
             xdrm.discount_rate_34 discount_rate_34,
             xdrm.discount_rate_35 discount_rate_35,
             xdrm.discount_rate_36 discount_rate_36,
             xdrm.discount_rate_37 discount_rate_37,
             xdrm.discount_rate_38 discount_rate_38,
             xdrm.discount_rate_39 discount_rate_39,
             xdrm.discount_rate_40 discount_rate_40,
             xdrm.discount_rate_41 discount_rate_41,
             xdrm.discount_rate_42 discount_rate_42,
             xdrm.discount_rate_43 discount_rate_43,
             xdrm.discount_rate_44 discount_rate_44,
             xdrm.discount_rate_45 discount_rate_45,
             xdrm.discount_rate_46 discount_rate_46,
             xdrm.discount_rate_47 discount_rate_47,
             xdrm.discount_rate_48 discount_rate_48,
             xdrm.discount_rate_49 discount_rate_49,
             xdrm.discount_rate_50 discount_rate_50
      FROM   xxcff_discount_rate_mst xdrm
      WHERE  xdrm.application_date = p_application_date;
    lt_discount_rate_rec get_discount_rate_rec_cur%ROWTYPE;
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
    ln_discount_rate := NULL;
--
    -- 支払回数から年数を算定
    ln_payment_years := in_payment_frequency / 12;
--
    -- 割引率マスタ検索
    OPEN  get_discount_rate_rec_cur(id_contract_ym);
    FETCH get_discount_rate_rec_cur INTO lt_discount_rate_rec;
--
    -- レコードが存在しない場合、エラー
    IF (get_discount_rate_rec_cur%NOTFOUND) THEN
      CLOSE get_discount_rate_rec_cur;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,        -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00089       -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    CLOSE get_discount_rate_rec_cur;
--
    -- 適用年数に該当する割引率を取得
    CASE ln_payment_years
      WHEN  1 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_01;
      WHEN  2 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_02;
      WHEN  3 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_03;
      WHEN  4 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_04;
      WHEN  5 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_05;
      WHEN  6 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_06;
      WHEN  7 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_07;
      WHEN  8 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_08;
      WHEN  9 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_09;
      WHEN 10 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_10;
      WHEN 11 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_11;
      WHEN 12 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_12;
      WHEN 13 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_13;
      WHEN 14 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_14;
      WHEN 15 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_15;
      WHEN 16 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_16;
      WHEN 17 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_17;
      WHEN 18 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_18;
      WHEN 19 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_19;
      WHEN 20 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_20;
      WHEN 21 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_21;
      WHEN 22 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_22;
      WHEN 23 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_23;
      WHEN 24 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_24;
      WHEN 25 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_25;
      WHEN 26 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_26;
      WHEN 27 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_27;
      WHEN 28 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_28;
      WHEN 29 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_29;
      WHEN 30 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_30;
      WHEN 31 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_31;
      WHEN 32 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_32;
      WHEN 33 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_33;
      WHEN 34 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_34;
      WHEN 35 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_35;
      WHEN 36 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_36;
      WHEN 37 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_37;
      WHEN 38 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_38;
      WHEN 39 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_39;
      WHEN 40 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_40;
      WHEN 41 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_41;
      WHEN 42 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_42;
      WHEN 43 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_43;
      WHEN 44 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_44;
      WHEN 45 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_45;
      WHEN 46 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_46;
      WHEN 47 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_47;
      WHEN 48 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_48;
      WHEN 49 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_49;
      WHEN 50 THEN ln_discount_rate := lt_discount_rate_rec.discount_rate_50;
      ELSE NULL;
    END CASE;
--
    -- 割引率が未設定の場合、エラー
    IF (ln_discount_rate IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,        -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00109       -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    on_present_value_discount_rate := ln_discount_rate / 100;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
      IF (get_discount_rate_rec_cur%ISOPEN) THEN
        CLOSE get_discount_rate_rec_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END calc_discount_rate;
-- Ver.1.1 ADD Start
  /**********************************************************************************
   * Function Name    : calc_present_value_re
   * Description      : 再リース現在価値算定処理 (A-9)
   ***********************************************************************************/
  FUNCTION calc_present_value_re(
    in_second_charge               IN  NUMBER,      -- 1.２回目以降月額リース料
    in_calc_rate                   IN  NUMBER       -- 2.計算率
  )
  RETURN NUMBER                                     -- 再リース現在価値
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_present_value_re';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_first_charge_re  NUMBER;  -- 再リース１回目リース料
    ln_second_charge_re NUMBER;  -- 再リース２回目リース料
    ln_third_charge_re  NUMBER;  -- 再リース３回目リース料
    ln_re_lease_value   NUMBER;  -- 再リース分の現在価値
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- 初期化
    ln_re_lease_value := 0 ;
--
    -- 再リース分のリース料を算出
    ln_first_charge_re  := in_second_charge;                       -- 再リース１回目リース料
    ln_second_charge_re := TRUNC( in_second_charge * 12 / 14 );    -- 再リース２回目リース料
    ln_third_charge_re  := TRUNC( in_second_charge * 12 / 18 );    -- 再リース３回目リース料
--
    -- 再リース分の現在価値を算出
    ln_re_lease_value   := TRUNC( ln_first_charge_re  / POWER( (1 + in_calc_rate), cn_first_freq  ) )
                        +  TRUNC( ln_second_charge_re / POWER( (1 + in_calc_rate), cn_second_freq ) )
                        +  TRUNC( ln_third_charge_re  / POWER( (1 + in_calc_rate), cn_third_freq  ) )
    ;
--
    RETURN ln_re_lease_value;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END calc_present_value_re;
--
  /**********************************************************************************
   * Procedure Name   : calc_debt_lease
   * Description      : リース負債額算定処理 (A-8)
   ***********************************************************************************/
  PROCEDURE calc_debt_lease(
    in_estimated_cash_price   IN  NUMBER,      -- 1.見積現金購入価額
    in_present_value          IN  NUMBER,      -- 2.現在価値割引額
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
    id_contract_ym            IN  DATE,        -- 契約年月
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
    iv_lease_class            IN  VARCHAR2,    -- 3.リース種別
    in_second_charge          IN  NUMBER,      -- 4.２回目以降月額リース料
    in_calc_interested_rate   IN  NUMBER,      -- 5.計算利子率
    on_original_cost_type1    OUT NUMBER,      -- 6.リース負債額_原契約
    on_original_cost_type2    OUT NUMBER,      -- 7.リース負債額_再リース
    ov_errbuf                 OUT VARCHAR2,    -- エラー・メッセージ
    ov_retcode                OUT VARCHAR2,    -- リターン・コード
    ov_errmsg                 OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_debt_lease';  -- プログラム名
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
    ln_original_cost    NUMBER;  -- 取得価額
    ln_re_lease_value   NUMBER;  -- 再リース分の現在価値
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
    -- ローカル変数初期化
--
    -- リース種別が「自動販売機」以外の場合は処理スキップ
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--    IF ( iv_lease_class <> cv_lease_class_11 ) THEN
    IF ( iv_lease_class <> cv_lease_class_11 OR id_contract_ym < cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
      -- リース負債額_原契約
      on_original_cost_type1 := 0;
      -- リース負債額_再リース
      on_original_cost_type2 := 0;
      RETURN;
    END IF;
--
    -- 現在価値と見積現金購入価額を比較し、低い方を取得価額に設定
    IF (in_present_value <= in_estimated_cash_price) THEN
      ln_original_cost := in_present_value;
    ELSE
      ln_original_cost := in_estimated_cash_price;
    END IF;
--
    --========================================
    --  再リース現在価値算定処理 (A-9)
    --========================================
    ln_re_lease_value  := calc_present_value_re(
                            in_second_charge,                -- ２回目以降月額リース料
                            in_calc_interested_rate / 12     -- 計算利子率
                          );
--
    -- リース負債額_原契約
    on_original_cost_type1 := ln_original_cost - ln_re_lease_value;
    -- リース負債額_再リース
    on_original_cost_type2 := ln_re_lease_value;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END calc_debt_lease;
-- Ver.1.1 ADD End
  /**********************************************************************************
   * Function Name    : calc_present_value
   * Description      : 現在価値算定処理 (A-4)
   ***********************************************************************************/
  FUNCTION calc_present_value(
    in_payment_frequency           IN  NUMBER,      -- 1.支払回数
    in_first_charge                IN  NUMBER,      -- 2.初回月額リース料
    in_second_charge               IN  NUMBER,      -- 3.２回目以降月額リース料
-- Ver.1.1 MOD Start
--    in_present_value_discount_rate IN  NUMBER)      -- 4.現在価値割引率
    in_present_value_discount_rate IN  NUMBER,      -- 4.現在価値割引率
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
    id_contract_ym                 IN  DATE,        -- 契約年月
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
    iv_lease_class                 IN  VARCHAR2     -- 5.リース種別
  )
-- Ver.1.1 MOD End
  RETURN NUMBER                                     -- 現在価値
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_present_value';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_present_value   NUMBER;  -- 現在価値
    ln_second_value    NUMBER;  -- ２回目以降現在価値
-- Ver.1.1 ADD Start
    ln_re_lease_value  NUMBER;  -- 再リース分の現在価値
-- Ver.1.1 ADD End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- 初回月額リース料を初期設定
    ln_present_value  := in_first_charge;
-- Ver.1.1 ADD Start
    ln_re_lease_value := 0 ;
-- Ver.1.1 ADD End
--
    -- ２回目以降月額リース料を支払回数分加算
    <<present_value_calc_loop>>
    FOR i IN 2..in_payment_frequency LOOP
      -- ２回目以降月額リース料を支払回に応じた現在価値に換算
      ln_second_value := in_second_charge / POWER( (1 + in_present_value_discount_rate / 12), (i - 1) );
      -- 上記で換算した値を現在価値に加算
      ln_present_value := ln_present_value + ln_second_value;
    END LOOP present_value_calc_loop;
-- Ver.1.1 ADD Start
    -- リース種別が「自動販売機」の場合、再リース分の現在価値を算定
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--    IF ( iv_lease_class = cv_lease_class_11 ) THEN
    IF ( iv_lease_class = cv_lease_class_11 AND id_contract_ym >= cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
      --========================================
      --  再リース現在価値算定処理 (A-9)
      --========================================
      ln_re_lease_value  := calc_present_value_re(
                              in_second_charge,                    -- ２回目以降月額リース料
                              in_present_value_discount_rate / 12  -- 現在価値割引率
                            );
    END IF;
--
    -- 再リース分の現在価値を加算
    ln_present_value := ln_present_value + ln_re_lease_value;
-- Ver.1.1 ADD End
--
    RETURN ROUND(ln_present_value, 0);
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END calc_present_value;
  /**********************************************************************************
   * Function Name    : judge_lease_kind
   * Description      : リース種類判定処理 (A-5)
   ***********************************************************************************/
  FUNCTION judge_lease_kind(
    in_payment_frequency    IN NUMBER,    -- 1.支払回数
    in_estimated_cash_price IN NUMBER,    -- 2.見積現金購入価額
    in_life_in_months       IN NUMBER,    -- 3.法定耐用年数
    in_present_value        IN NUMBER)    -- 4.現在価値
  RETURN VARCHAR2                         -- リース種類 '0'(Fin)/'1'(Op)
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_lease_kind';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_lease_kind VARCHAR2(1);  -- リース種類
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- 現在価値が見積現金購入価額の90%以上である場合、または
    -- 支払回数(リース期間)が法定耐用年数の75%以上である場合、リース種類に「Fin」を設定
    IF ( (in_present_value >= in_estimated_cash_price * 0.9)
      OR (in_payment_frequency >= in_life_in_months * 12 * 0.75) )
    THEN
      lv_lease_kind := cv_lease_kind_0;
    -- それ以外の場合、リース種類に「Op」を設定
    ELSE
      lv_lease_kind := cv_lease_kind_1;
    END IF;
--
    RETURN lv_lease_kind;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END judge_lease_kind;
  /**********************************************************************************
   * Function Name    : calc_original_cost
   * Description      : 取得価額算定処理 (A-6)
   ***********************************************************************************/
  FUNCTION calc_original_cost(
    in_estimated_cash_price IN NUMBER,    -- 1.見積現金購入価額
    in_present_value        IN NUMBER)    -- 2.現在価値
  RETURN NUMBER                           -- 取得価額
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_original_cost';  -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_original_cost NUMBER;  -- 取得価額
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    -- 現在価値と見積現金購入価額を比較し、低い方を取得価額に設定
    IF (in_present_value <= in_estimated_cash_price) THEN
      ln_original_cost := in_present_value;
    ELSE
      ln_original_cost := in_estimated_cash_price;
    END IF;
--
    RETURN ln_original_cost;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,2000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END calc_original_cost;
  /**********************************************************************************
   * Procedure Name   : calc_interested_rate
   * Description      : 計算利子率算定処理 (A-7)
   ***********************************************************************************/
  PROCEDURE calc_interested_rate(
    in_payment_frequency    IN  NUMBER,      -- 1.支払回数
    in_first_charge         IN  NUMBER,      -- 2.初回月額リース料
    in_second_charge        IN  NUMBER,      -- 3.２回目以降月額リース料
    in_original_cost        IN  NUMBER,      -- 4.取得価額
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
    id_contract_ym          IN  DATE,        -- 契約年月
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
-- Ver.1.1 ADD Start
    iv_lease_class          IN  VARCHAR2,    -- 5.リース種別
-- Ver.1.1 ADD End
    on_calc_interested_rate OUT NUMBER,      -- 6.計算利子率
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ
    ov_retcode              OUT VARCHAR2,    -- リターン・コード
    ov_errmsg               OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_interested_rate';  -- プログラム名
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
    cn_a NUMBER := in_first_charge;       -- 初回月額リース料
    cn_b NUMBER := in_second_charge;      -- ２回目以降月額リース料
    cn_n NUMBER := in_payment_frequency;  -- 支払回数
--
    -- *** ローカル変数 ***
    ln_calc_interested_rate NUMBER;       -- 計算利子率
    ln_latest_rate          NUMBER;       -- 計算利子率算出中の退避用
    ln_latest_over_rate     NUMBER;       -- 直近で支払額 > 取得価額となった計算利子率
    ln_r                    NUMBER;       -- 計算式R値(1/(1+計算利子率))
    ln_i                    NUMBER;       -- 支払額
-- Ver.1.1 ADD Start
    ln_i_re                 NUMBER;       -- 支払額(再リース分)
-- Ver.1.1 ADD End
    ln_decrement            NUMBER;       -- 減分値
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
    -- ローカル変数初期化
    ln_calc_interested_rate := cn_calc_rate_max;  -- 計算利子率に最大値を設定
    ln_latest_over_rate     := cn_calc_rate_min;  -- 計算利子率が最小値未満の場合、最小値とする
    ln_decrement            := 0.1;               -- 最初の有効桁は小数点以下第１位
-- Ver.1.1 ADD Start
    ln_i_re                 := 0;                 -- 支払額(再リース分)
-- Ver.1.1 ADD End
--
    --========================================
    -- 計算利子率が最大値の場合の支払額算出
    --========================================
    -- 計算式R値の算出
    ln_r := 1 / (1 + ln_calc_interested_rate);
--
    -- 計算式により支払額を算出
    ln_i := cn_a * ln_r + (cn_b * POWER(ln_r, 2) - cn_b * POWER(ln_r, (cn_n + 1) ) ) / (1 - ln_r);
-- Ver.1.1 ADD Start
    -- リース種別が「自動販売機」の場合、再リース分の支払額を算定
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--    IF ( iv_lease_class = cv_lease_class_11 ) THEN
    IF ( iv_lease_class = cv_lease_class_11 AND id_contract_ym >= cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
      --========================================
      --  再リース現在価値算定処理 (A-9)
      --========================================
      ln_i_re := calc_present_value_re(
                   in_second_charge,             -- ２回目以降月額リース料
                   ln_calc_interested_rate       -- 計算利子率
                 );
    END IF;
--
    -- 再リース分の支払額を加算
    ln_i := ln_i + ln_i_re;
-- Ver.1.1 ADD End
--
    -- 上記支払額が取得価額より大きい場合、エラー
    IF (ln_i > in_original_cost) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,        -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00088       -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --========================================
    -- 支払額が取得価額と一致、または近似値となる時の計算利子率算出
    --========================================
    <<interested_rate_calc_loop>>
    LOOP
      -- 支払額 ＜ 取得価額の場合、計算利子率を変数に退避し、有効桁に応じて１差し引く
      IF (ln_i < in_original_cost) THEN
        ln_latest_rate := ln_calc_interested_rate;
        ln_calc_interested_rate := ln_calc_interested_rate - ln_decrement;
        -- 有効桁が0となる場合は有効桁を１右シフトして１差し引く
        IF (MOD(ln_calc_interested_rate, ln_decrement * 10) = 0) THEN
          ln_decrement := ln_decrement * 0.1;
          -- 有効桁が小数点以下７桁を下回った場合、直近で支払額 > 取得価額となった計算利子率を
          -- 設定し、ループを抜ける
          IF (ln_decrement < cn_calc_rate_min) THEN
            ln_calc_interested_rate := ln_latest_over_rate;
            EXIT interested_rate_calc_loop;
          END IF;
          ln_calc_interested_rate := ln_latest_rate - ln_decrement;
        END IF;
      -- 支払額 ＞ 取得価額の場合、計算利子率を変数に退避し、退避した計算利子率から有効桁を
      -- １右シフトして１差し引く
      ELSIF (ln_i > in_original_cost) THEN
        ln_latest_over_rate := ln_calc_interested_rate;
        ln_decrement := ln_decrement * 0.1;
        -- 減分対象桁が小数点以下７桁を下回った場合、ループを抜ける
        IF (ln_decrement < cn_calc_rate_min) THEN
          EXIT interested_rate_calc_loop;
        END IF;
        ln_calc_interested_rate := ln_latest_rate - ln_decrement;
      -- 支払額 ＝ 取得価額の場合、ループを抜ける
      ELSE
        EXIT interested_rate_calc_loop;
      END IF;
--
      -- 計算式R値の算出
      ln_r := 1 / (1 + ln_calc_interested_rate);
--
      -- 計算式により支払額を算出
      ln_i := cn_a * ln_r + (cn_b * POWER(ln_r, 2) - cn_b * POWER(ln_r, (cn_n + 1) ) ) / (1 - ln_r);
-- Ver.1.1 ADD Start
      -- リース種別が「自動販売機」の場合、再リース分の支払額を算定
-- 2016/10/26 Ver.1.2 Y.Koh MOD Start
--      IF ( iv_lease_class = cv_lease_class_11 ) THEN
      IF ( iv_lease_class = cv_lease_class_11 AND id_contract_ym >= cd_start_date ) THEN
-- 2016/10/26 Ver.1.2 Y.Koh MOD End
        --========================================
        --  再リース現在価値算定処理 (A-9)
        --========================================
        ln_i_re := calc_present_value_re(
                     in_second_charge,             -- ２回目以降月額リース料
                     ln_calc_interested_rate       -- 計算利子率
                   );
      END IF;
--
      -- 再リース分の支払額を加算
      ln_i := ln_i + ln_i_re;
-- Ver.1.1 ADD End
--
    END LOOP interested_rate_calc_loop;
--
    -- 算出した計算利子率を年率に変換し、アウトパラメータに設定
    on_calc_interested_rate := ln_calc_interested_rate * 12;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END calc_interested_rate;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   ***********************************************************************************/
  PROCEDURE main(
    iv_lease_type                  IN  VARCHAR2,    -- 1.リース区分
    in_payment_frequency           IN  NUMBER,      -- 2.支払回数
    in_first_charge                IN  NUMBER,      -- 3.初回月額リース料
    in_second_charge               IN  NUMBER,      -- 4.２回目以降月額リース料
    in_estimated_cash_price        IN  NUMBER,      -- 5.見積現金購入価額
    in_life_in_months              IN  NUMBER,      -- 6.法定耐用年数
    id_contract_ym                 IN  DATE,        -- 7.契約年月
-- Ver.1.1 ADD Start
    iv_lease_class                 IN  VARCHAR2,    -- 8.リース種別
-- Ver.1.1 ADD End
    ov_lease_kind                  OUT VARCHAR2,    -- 9.リース種類
    on_present_value_discount_rate OUT NUMBER,      -- 10.現在価値割引率
    on_present_value               OUT NUMBER,      -- 11.現在価値
    on_original_cost               OUT NUMBER,      -- 12.取得価額
    on_calc_interested_rate        OUT NUMBER,      -- 13.計算利子率
-- Ver.1.1 ADD Start
    on_original_cost_type1         OUT NUMBER,      -- 14.リース負債額_原契約
    on_original_cost_type2         OUT NUMBER,      -- 15.リース負債額_再リース
-- Ver.1.1 ADD End
    ov_errbuf                      OUT VARCHAR2,    -- エラー・メッセージ
    ov_retcode                     OUT VARCHAR2,    -- リターン・コード
    ov_errmsg                      OUT VARCHAR2     -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    lv_lease_kind                  VARCHAR2(1);  -- リース種類
    ln_present_value_discount_rate NUMBER;       -- 現在価値割引率
    ln_present_value               NUMBER;       -- 現在価値
    ln_original_cost               NUMBER;       -- 取得価額
    ln_calc_interested_rate        NUMBER;       -- 計算利子率
-- Ver.1.1 ADD Start
    ln_original_cost_type1         NUMBER;       -- リース負債額_原契約
    ln_original_cost_type2         NUMBER;       -- リース負債額_再リース
-- Ver.1.1 ADD End
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
    -- =====================================================
    --  入力項目チェック処理 (A-1)
    -- =====================================================
    check_in_param(
      iv_lease_type,            -- リース区分
      in_payment_frequency,     -- 支払回数
      in_first_charge,          -- 初回月額リース料
      in_second_charge,         -- ２回目以降月額リース料
      in_estimated_cash_price,  -- 見積現金購入価額
      in_life_in_months,        -- 法定耐用年数
      id_contract_ym,           -- 契約年月
-- Ver.1.1 ADD Start
      iv_lease_class,           -- リース種別
-- Ver.1.1 ADD End
      lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      lv_retcode,               -- リターン・コード             --# 固定 #
      lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  リース区分判定処理 (A-2)
    -- =====================================================
    lv_lease_kind := judge_lease_type(
                       iv_lease_type);  -- リース区分
    -- リース種類が'1'(Op)の場合は処理終了
    IF (lv_lease_kind = cv_lease_kind_1) THEN
      ov_lease_kind                  := lv_lease_kind;
      on_present_value_discount_rate := 0;
      on_present_value               := 0;
      on_original_cost               := 0;
      on_calc_interested_rate        := 0;
-- Ver.1.1 ADD Start
      on_original_cost_type1         := 0;   -- リース負債額_原契約
      on_original_cost_type2         := 0;   -- リース負債額_再リース
-- Ver.1.1 ADD End
      RETURN;
    END IF;
--
    -- =====================================================
    --  現在価値割引率算定処理 (A-3)
    -- =====================================================
    calc_discount_rate(
      in_payment_frequency,            -- 支払回数
      id_contract_ym,                  -- 契約年月
      ln_present_value_discount_rate,  -- 現在価値割引率
      lv_errbuf,                       -- エラー・メッセージ           --# 固定 #
      lv_retcode,                      -- リターン・コード             --# 固定 #
      lv_errmsg);                      -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  現在価値算定処理 (A-4)
    -- =====================================================
    ln_present_value := calc_present_value(
                          in_payment_frequency,             -- 支払回数
                          in_first_charge,                  -- 初回月額リース料
                          in_second_charge,                 -- ２回目以降月額リース料
-- Ver.1.1 MOD Start
--                          ln_present_value_discount_rate);  -- 現在価値割引率
                          ln_present_value_discount_rate,   -- 現在価値割引率
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
                          id_contract_ym,                   -- 契約年月
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
                          iv_lease_class                    -- リース種別
                        );
-- Ver.1.1 MOD End
--
    -- =====================================================
    --  リース種類判定処理 (A-5)
    -- =====================================================
    lv_lease_kind := judge_lease_kind(
                       in_payment_frequency,     -- 支払回数
                       in_estimated_cash_price,  -- 見積現金購入価額
                       in_life_in_months,        -- 法定耐用年数
                       ln_present_value);        -- 現在価値
--
    -- =====================================================
    --  取得価額算定処理 (A-6)
    -- =====================================================
    ln_original_cost := calc_original_cost(
                          in_estimated_cash_price,  -- 見積現金購入価額
                          ln_present_value);        -- 現在価値
--
    -- =====================================================
    --  計算利子率算定処理 (A-7)
    -- =====================================================
    calc_interested_rate(
      in_payment_frequency,     -- 支払回数
      in_first_charge,          -- 初回月額リース料
      in_second_charge,         -- ２回目以降月額リース料
      ln_original_cost,         -- 取得価額
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
      id_contract_ym,           -- 契約年月
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
-- Ver.1.1 ADD Start
      iv_lease_class,           -- リース種別
-- Ver.1.1 ADD End
      ln_calc_interested_rate,  -- 計算利子率
      lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      lv_retcode,               -- リターン・コード             --# 固定 #
      lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD Start
    -- =====================================================
    --  リース負債額算定処理 (A-8)
    -- =====================================================
    calc_debt_lease(
      in_estimated_cash_price,  -- 見積現金購入価額
      ln_present_value,         -- 現在価値割引額
-- 2016/10/26 Ver.1.2 Y.Koh ADD Start
      id_contract_ym,           -- 契約年月
-- 2016/10/26 Ver.1.2 Y.Koh ADD End
      iv_lease_class,           -- リース種別
      in_second_charge,         -- ２回目以降月額リース料
      ln_calc_interested_rate,  -- 計算利子率
      ln_original_cost_type1,   -- リース負債額_原契約
      ln_original_cost_type2,   -- リース負債額_再リース
      lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      lv_retcode,               -- リターン・コード             --# 固定 #
      lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.1 ADD End
--
    -- 正常終了時の戻り値設定
    ov_lease_kind                  := lv_lease_kind;
    on_present_value_discount_rate := ln_present_value_discount_rate;
    on_present_value               := ln_present_value;
    on_original_cost               := ln_original_cost;
    on_calc_interested_rate        := ln_calc_interested_rate;
-- Ver.1.1 ADD Start
    on_original_cost_type1         := ln_original_cost_type1;          -- リース負債額_原契約
    on_original_cost_type2         := ln_original_cost_type2;          -- リース負債額_再リース
-- Ver.1.1 ADD End
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END main;
--
END XXCFF003A03C
;
/
