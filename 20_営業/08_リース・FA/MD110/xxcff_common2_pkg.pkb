create or replace
PACKAGE BODY XXCFF_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON2_PKG(body)
 * Description      : FAリース共通処理
 * MD.050           : なし
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  payment_match_chk      支払照合済チェック
 *  get_lease_key          リースキーの取得
 *  get_object_info        物件コードリース区分、リース種別チェック
 *  chk_object_term        物件コード解約チェック
 *  get_lease_class_info   リース種別DFF情報取得
 *  <program name>         <説明> (処理番号)
 *  作成順に記述していくこと
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0    SCS大井          新規作成
 *  2008/12/05    1.1    SCS嶋田          追加：物件コード解約チェック
 *  2009/02/18    1.2    SCS礒崎          支払照合済チェックの検索条件を変更
 *  2018/03/27    1.3    SCSK大塚         「リース種別DFF情報取得」機能追加
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
  object_comp_type          EXCEPTION;     -- 物件の属性比較例外(リース区分)
  object_comp_class         EXCEPTION;     -- 物件の属性比較例外(リース種別)
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF_COMMON2_PKG'; -- パッケージ名
  cv_appl_name     CONSTANT VARCHAR2(100) := 'XXCFF'; -- アプリケーション名
-- 2018/03/27 Ver1.3 Otsuka ADD Start
  cd_od_sysdate    CONSTANT DATE          := SYSDATE; -- システム日付
-- 2018/03/27 Ver1.3 Otsuka ADD End
--
  --エラーメッセージ名
  cv_msg_name1     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00157'; -- パラメータ必須エラー
  cv_msg_name6     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00161'; -- 解約チェックエラー
  cv_msg_name7     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00162'; -- 解約申請チェックエラー
  cv_msg_name2     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00186'; -- 会計期間取得エラー
-- 2018/03/27 Ver1.3 Otsuka ADD Start
  cv_msg_name8     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00189';  -- 参照タイプ取得エラー
-- 2018/03/27 Ver1.3 Otsuka ADD End
--
  --トークン名
  cv_tkn_name1     CONSTANT VARCHAR2(100) := 'INPUT';
-- 2018/03/27 Ver1.3 Otsuka ADD Start
  cv_tkn_name2     CONSTANT VARCHAR2(100) := 'LOOKUP_TYPE';    -- ルックアップタイプ
-- 2018/03/27 Ver1.3 Otsuka ADD End
--
  --トークン値
  cv_tkn_val2      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50016'; -- 物件内部ID
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : payment_match_chk
   * Description      : 支払照合済チェック
   ***********************************************************************************/
 PROCEDURE payment_match_chk(
    in_line_id    IN  NUMBER,          --   1.契約明細内部ID
    ov_errbuf     OUT NOCOPY VARCHAR2, --   エラー・メッセージ         --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, --   リターン・コード           --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
)  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_match_chk'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    ln_check_count   NUMBER(1);
    ld_process_date  DATE;
    lv_period_name   gl_periods_v.period_name%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    init_rtype_rec                 XXCFF_COMMON1_PKG.init_rtype;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --業務日付取得 2009/2/9 開発環境のみの一時対応 
    XXCFF_COMMON1_PKG.init(or_init_rec => init_rtype_rec
      ,ov_retcode    => lv_retcode
      ,ov_errbuf     => lv_errbuf
      ,ov_errmsg     => lv_errmsg);
--    ld_process_date           := xxccp_common_pkg2.get_process_date;
    ld_process_date           := init_rtype_rec.process_date;
    --業務日付取得 2009/2/9 開発環境のみの一時対応 ここまで
    BEGIN
      --業務日付に対応する会計期間名取得
      SELECT
             period_name
      INTO
             lv_period_name
      FROM
             gl_periods_v
      WHERE
             period_set_name        = 'SALES_CALENDAR'
        AND  adjustment_period_flag = 'N'
        AND  start_date            <= ld_process_date
        AND  end_date              >= ld_process_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                      --*** 会計期間が取得できなければ異常 ***
        -- *** 任意で例外処理を記述する ****
        lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name2);
        RAISE global_api_others_expt;
    END;
    --照合済データの存在を確認
    SELECT
           COUNT(contract_line_id)
     INTO
           ln_check_count
     FROM
           xxcff_pay_planning
    WHERE
           contract_line_id   = in_line_id
     AND   period_name       >= lv_period_name
--   AND NOT(payment_match_flag = '0'       --支払照合未照合
--       AND accounting_if_flag = '1')      --未送信
     AND  ((payment_match_flag = '1')       --支払照合済
     OR    (payment_match_flag = '0'        --支払照合未照合
       AND  accounting_if_flag = '3'))      --照合できず
     AND   ROWNUM             = 1;
    --==============================================================
    --照合済のレコードが1件以上存在しているのでチェックエラーとする
    --==============================================================
--★DEBUG
    IF (ln_check_count <> 0) THEN
      --エラーメッセージを取得
      ov_retcode := cv_status_warn;                                            --# 任意 #
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                           --*** 照合済の支払計画がない場合正常 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := NULL;                                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END payment_match_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_key
   * Description      : リースキー情報取得
   ***********************************************************************************/
  PROCEDURE get_lease_key(
    iv_objectcode IN  VARCHAR2,        --   1.物件コード(必須)
    on_object_id  OUT NUMBER,          --   2.物件内部ＩＤ
    on_contact_id OUT NUMBER,          --   3.契約内部ＩＤ
    on_line_id    OUT NUMBER,          --   4.契約明細内部ＩＤ
    ov_errbuf     OUT NOCOPY VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
)  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_key'; -- プログラム名
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
    ln_object_id      xxcff_object_headers.object_header_id%TYPE    := NULL;  --   物件内部ＩＤ
    ln_line_id        xxcff_contract_lines.contract_line_id%TYPE    := NULL;  --   契約明細内部ＩＤ
    ln_cont_id        xxcff_contract_lines.contract_header_id%TYPE  := NULL;  --   契約内部ＩＤ
    ln_re_lease_times xxcff_object_headers.re_lease_times%TYPE;
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
    --物件内部ID取得
    SELECT xoh.object_header_id
          ,xoh.re_lease_times
    INTO
           ln_object_id         --   物件内部ＩＤ
          ,ln_re_lease_times    --   再リース回数
    FROM
           xxcff_object_headers xoh
    WHERE
           object_code        = iv_objectcode;
    --契約内部ID,契約明細内部ID取得
    SELECT
           xcl.contract_header_id
          ,xcl.contract_line_id
    INTO
           ln_cont_id           --   契約内部ＩＤ
          ,ln_line_id           --   契約明細内部ＩＤ
    FROM
           xxcff_contract_headers xch
          ,xxcff_contract_lines xcl
    WHERE
           xcl.object_header_id    = ln_object_id
      AND  xch.contract_header_id  = xcl.contract_header_id
      AND  xch.re_lease_times      = ln_re_lease_times;
    -- 取得内容をOUTパラメータに設定
    on_object_id  := ln_object_id; --   2.物件内部ＩＤ
    on_contact_id := ln_cont_id;   --   3.契約内部ＩＤ
    on_line_id    := ln_line_id;   --   4.契約明細内部ＩＤ
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                           --*** 情報が取得できなくても正常終了
      -- *** 任意で例外処理を記述する ****
      on_object_id  := ln_object_id; --   2.物件内部ＩＤ
      on_contact_id := ln_cont_id;   --   3.契約内部ＩＤ
      on_line_id    := ln_line_id;   --   4.契約明細内部ＩＤ
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
  END get_lease_key;
--
--
  /**********************************************************************************
   * Procedure Name   : get_object_info
   * Description      : 物件コードリース区分、リース種別チェック
   ***********************************************************************************/
  PROCEDURE get_object_info(
    in_object_id   IN  NUMBER,          --   1.物件コード(必須)
    iv_lease_type  IN  VARCHAR2,        --   2.リース区分(必須)
    iv_lease_class IN  VARCHAR2,        --   3.リース種別(必須)
    in_re_lease_times IN  NUMBER,       --   4.再リース回数（必須）
    ov_errbuf      OUT NOCOPY VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
)  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_info'; -- プログラム名
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
    lv_err_item       VARCHAR2(1000);  --   エラー項目
    ln_rec_cnt        NUMBER(10);  --   エラー項目
    lv_lease_type     xxcff_object_headers.lease_type%type;     --   リース区分
    lv_lease_class    xxcff_object_headers.lease_class%type;    --   リース種別
    ln_re_lease_times xxcff_object_headers.re_lease_times%type; --   再リース回数
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
    --データ取得処理
    --==============================================================
    --物件内部IDに対応するレコードをカウントする
    --==============================================================
    SELECT
           COUNT(object_header_id)
    INTO
           ln_rec_cnt
    FROM
           xxcff_object_headers xoh
    WHERE
           xoh.object_header_id   = in_object_id
    ;
    --==============================================================
    --物件内部IDに対応するレコードが存在するか確認
    --==============================================================
    IF (ln_rec_cnt = 0) THEN
      ov_retcode := cv_status_error;
      return;
    END IF;
    --==============================================================
    --物件内部IDと再リース回数を指定してレコードを検索
    --==============================================================
    SELECT
           XOH.lease_type
          ,XOH.lease_class
          ,XOH.re_lease_times
    INTO
           lv_lease_type         --   リース区分
          ,lv_lease_class        --   リース種別
          ,ln_re_lease_times
    FROM
           XXCFF_OBJECT_HEADERS XOH
    WHERE
           XOH.OBJECT_HEADER_ID   = in_object_id
      AND  XOH.re_lease_times     = in_re_lease_times
    ;
    --==============================================================
    --リース区分を比較確認する
    --==============================================================
    IF (lv_lease_type <> iv_lease_type) THEN
        RAISE  object_comp_type;
    END IF;
    --==============================================================
    --リース種別を比較確認する
    --==============================================================
    IF (lv_lease_class <> iv_lease_class) THEN
        RAISE  object_comp_class;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN                      --リース回数が不一致
        ov_retcode := cv_status_warn;
    WHEN object_comp_type THEN                   --*** リース区分が不一致の場合はエラー ***
        ov_retcode := cv_status_warn;
    WHEN object_comp_class THEN                  --*** リース種別が不一致の場合はエラー ***
        ov_retcode := cv_status_warn;
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
  END get_object_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_object_term
   * Description      : 物件コード解約チェック
   ***********************************************************************************/
  PROCEDURE chk_object_term(
    in_object_header_id  IN  NUMBER,                --   1.物件内部ID(必須)
    iv_term_appl_chk_flg IN  VARCHAR2 DEFAULT 'N',  --   2.解約申請チェックフラグ(デフォルト値：'N')
    ov_errbuf            OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object_term'; -- プログラム名
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
    ln_check_count   PLS_INTEGER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    term_check_expt       EXCEPTION;  --物件コード解約チェックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --必須項目チェック
    IF ( in_object_header_id IS NULL ) THEN
      --必須パラメータ「 物件内部ID 」が未入力です。
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name1
                                            ,cv_tkn_name1,cv_tkn_val2);
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --解約済み/満了チェック
    IF ( iv_term_appl_chk_flg = 'N' ) THEN
      --データ取得処理
      SELECT
             COUNT( ROWNUM )
      INTO
             ln_check_count
      FROM
             xxcff_object_headers  xoh  -- リース物件
           , xxcff_object_status_v xos  -- 物件ステータスビュー
      WHERE
             xoh.object_header_id   = in_object_header_id
        AND  xos.object_status_code = xoh.object_status
        AND  xos.no_adjusts_flag    = 'Y';      --修正不可(解約済み/満了)
--
      --===================================================================================
      --解約済み、もしくは満了の状態のレコードが1件以上存在しているのでチェックエラーとする
      --===================================================================================
      IF ( ln_check_count <> 0 ) THEN
        --エラーメッセージを取得
        --該当の物件は、解約済み、もしくは満了の状態です。
        lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name6);
        lv_errbuf  := lv_errmsg;
        RAISE term_check_expt;
      END IF;
--
    --解約済み/満了/解約申請中チェック
    ELSIF ( iv_term_appl_chk_flg = 'Y' ) THEN
      --データ取得処理
      SELECT
             COUNT( ROWNUM )
      INTO
             ln_check_count
      FROM
             xxcff_object_headers  xoh  -- リース物件
           , xxcff_object_status_v xos  -- 物件ステータスビュー
      WHERE
             xoh.object_header_id   = in_object_header_id
        AND  xos.object_status_code = xoh.object_status
        AND  xos.bond_accept_flag   = 'Y';      --証書受領可能(解約済み/満了/解約申請中)
--
      --=========================================================================
      --解約申請以降の状態のレコードが1件以上存在しているのでチェックエラーとする
      --=========================================================================
      IF ( ln_check_count <> 0 ) THEN
        --エラーメッセージを取得
        --該当の物件は、解約申請以降の状態です。
        lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name7);
        lv_errbuf  := lv_errmsg;
        RAISE term_check_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                    --*** 物件が解約済み、満了、解約申請中でない場合正常 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := NULL;                                                  --# 任意 #
    -- *** 物件コード解約チェックエラーハンドラ ***
    WHEN term_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;  --警告(業務エラー)
--
--###############################  固定例外処理部 START   ###################################
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
--###################################  固定部 END   #########################################
--
  END chk_object_term;
--
-- 2018/03/27 Ver1.3 Otsuka ADD Start
  /**********************************************************************************
   * Procedure Name   : get_lease_class_info
   * Description      : リース種別DFF情報取得
   ***********************************************************************************/
  PROCEDURE get_lease_class_info(
    iv_lease_class IN  VARCHAR2,              -- リース種別
    ov_ret_dff4    OUT VARCHAR2,              -- DFF4のデータ格納用
    ov_ret_dff5    OUT VARCHAR2,              -- DFF5のデータ格納用
    ov_ret_dff6    OUT VARCHAR2,              -- DFF6のデータ格納用
    ov_ret_dff7    OUT VARCHAR2,              -- DFF7のデータ格納用
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_lease_class_info';     -- プログラム名
    cv_lease_class_check CONSTANT VARCHAR2(24)  := 'XXCFF1_LEASE_CLASS_CHECK';
    cv_lang_ja           CONSTANT VARCHAR2(2)   := USERENV('LANG');
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
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
    lv_lease_cls_DFF4 VARCHAR2(1);    -- 日本基準連携
    lv_lease_cls_DFF5 VARCHAR2(1);    -- IFRS連携
    lv_lease_cls_DFF6 VARCHAR2(1);    -- 仕訳作成
    lv_lease_cls_DFF7 VARCHAR2(1);    -- リース判定処理結果
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
    --初期化
    lv_lease_cls_DFF4 := NULL;
    lv_lease_cls_DFF5 := NULL;
    lv_lease_cls_DFF6 := NULL;
    lv_lease_cls_DFF7 := NULL;
--
    -- 参照タイプ：リース種別チェックから、各DFFを取得
    SELECT
            flv.attribute4 Att4, -- 日本基準連携
            flv.attribute5 Att5, -- IFRS連携
            flv.attribute6 Att6, -- 仕訳作成
            flv.attribute7 Att7  -- リース判定処理
    INTO
            lv_lease_cls_DFF4,   -- 日本基準連携
            lv_lease_cls_DFF5,   -- IFRS連携
            lv_lease_cls_DFF6,   -- 仕訳作成
            lv_lease_cls_DFF7    -- リース判定処理
    FROM
            fnd_lookup_values  flv
    WHERE
            flv.lookup_type  = cv_lease_class_check
      AND   flv.lookup_code  = iv_lease_class
      AND   flv.language     = cv_lang_ja
      AND   flv.enabled_flag = cv_yes
      AND   TRUNC(cd_od_sysdate) BETWEEN TRUNC(NVL(flv.start_date_active, cd_od_sysdate)) 
                                 AND     TRUNC(NVL(flv.end_date_active,   cd_od_sysdate));
    -- 取得内容をOUTパラメータに設定
    IF (lv_lease_cls_DFF4 IS NOT NULL) THEN
      ov_ret_dff4 := lv_lease_cls_DFF4;
    ELSE
      RAISE global_api_expt;
    END IF;
    IF (lv_lease_cls_DFF5 IS NOT NULL) THEN
      ov_ret_dff5 := lv_lease_cls_DFF5;
    ELSE
      RAISE global_api_expt;
    END IF;
    IF (lv_lease_cls_DFF6 IS NOT NULL) THEN
      ov_ret_dff6 := lv_lease_cls_DFF6;
    ELSE
      RAISE global_api_expt;
    END IF;
    IF (lv_lease_cls_DFF7 IS NOT NULL) THEN
      ov_ret_dff7 := lv_lease_cls_DFF7;
    ELSE
      RAISE global_api_expt;
    END IF;
--
    EXCEPTION
--
    WHEN NO_DATA_FOUND THEN                      --*** 参照タイプが取得できなければ異常 ***
      lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name
                                            ,cv_msg_name8
                                            ,cv_tkn_name2
                                            ,cv_lease_class_check);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--###############################  固定例外処理部 START   ###################################
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  固定部 END   #########################################
--
  END get_lease_class_info;
-- 2018/03/27 Ver1.3 Otsuka ADD End
--###########################  固定部 END   #######################################################
--
END XXCFF_COMMON2_PKG;
/