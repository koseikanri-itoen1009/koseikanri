CREATE OR REPLACE PACKAGE BODY APPS.xxcsm_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcsm_common_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_CSM_共通関数
 * Version                : 1.5
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_yearplan_calender      P          年間計画カレンダ取得関数
 *  get_employee_info          P          従業員情報取得関数
 *  get_employee_foothold      P          従業員在籍拠点コード取得関数
 *  get_login_user_foothold    P          ログインユーザー在籍拠点コード取得関数
 *  year_item_plan_security    P          年間商品計画セキュリティ制御用関数
 *  get_year_month             P          年度算出関数
 *  get_kyoten_cd_lv6          P          拠点コードリスト取得関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-11-27    1.0  T.Tsukino       新規作成
 *  2009-04-09    1.1  M.Ohtsuki      ［障害T1_0416］業務日付とシステム日付比較の不具合
 *  2009-05-07    1.2  M.Ohtsuki      ［障害T1_0858］拠点コードリスト取得条件不備
 *  2009-07-01    1.3  M.Ohtsuki      ［SCS障害管理番号0000253］対応
 *  2009-08-18    1.4  T.Tsukino      ［SCS障害管理番号0001045］対応 
 *  2010-12-14    1.5  Y.Kanami       ［E_本稼動_05803］
 *****************************************************************************************/
  -- ===============================
  -- グローバル変数
  -- ===============================
  gv_msg_part         CONSTANT VARCHAR2(3)   := ' : ';
  gv_msg_cont         CONSTANT VARCHAR2(3)   := '.';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcsm_common_pkg';  -- パッケージ名
  gv_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;               -- (正常 = 0)
  gv_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;                 -- (警告 = 1)
  gv_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;                -- (異常 = 2)
  gv_xxcsm_msg10012   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10012';
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** NULLチェック   ***
  global_null_chk_expt      EXCEPTION;
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
  /**********************************************************************************
   * Procedure  Name   : get_yearplan_calender
   * Description       : 年間計画カレンダ取得関数
   ***********************************************************************************/
  PROCEDURE get_yearplan_calender(
               id_comparison_date IN  DATE                                      -- 日付
              ,ov_status          OUT NOCOPY VARCHAR2                           -- 処理結果(0：正常、1：異常)
              ,on_active_year     OUT NUMBER                                    -- 対象年度
              ,ov_retcode         OUT NOCOPY VARCHAR2                           -- リターンコード
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           -- エラーメッセージ
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           -- ユーザー・エラーメッセージ
              )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_yearplan_calender';
    cv_carender_name    CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER';   -- 年間販売計画カレンダー名
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_xxcsm_msg00005   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';
    cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_xxcsm_msg10005   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10005';
    cv_xxccp_msg10003   CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-10003';   --異常終了メッセージ
    cv_xxccp_msg10013   CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-10013';   --異常終了メッセージ
    cv_normal           CONSTANT VARCHAR2(1)   := '0';               -- 処理結果(正常 = 0)
    cv_warn             CONSTANT VARCHAR2(1)   := '1';               -- 処理結果(警告 = 1)
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_comparison_date  DATE;                        -- パラメータ格納用
    ld_process_date     DATE;                        -- 業務日付格納用
    lv_carender_name    VARCHAR2(100);               -- カレンダー名格納用
    ln_active_year      NUMBER;                      -- 対象年度取得用
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUTパラメータユーザー・エラーメッセージ格納用
--
    no_data_expt        EXCEPTION;
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
    --======================================================================
    -- INパラメータ:日付の値がNullの場合、業務日付を変数に格納
    -- その他の場合は、入力パラメータの日付を変数に格納し、処理に使用する。
    --======================================================================
    IF (id_comparison_date IS NULL) THEN
      ld_comparison_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_comparison_date := id_comparison_date;
    END IF;
--
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- カレンダー名の取得
    lv_carender_name := FND_PROFILE.VALUE(cv_carender_name);
    DBMS_OUTPUT.PUT_LINE(lv_carender_name);
    -- カレンダー名の取得ができなかった場合
    IF (lv_carender_name IS NULL) THEN   -- メッセージ取得関数よりエラーメッセージをセットする
      RAISE no_data_expt;
    END IF;
    -- =====================================
    -- 対象年度取得処理
    -- =====================================
    SELECT ffv.flex_value                                                       -- 対象年度
    INTO   ln_active_year
    FROM   fnd_flex_value_sets  ffvs                                            -- 値セット
          ,fnd_flex_values  ffv                                                 -- 値セット明細
    WHERE  ffvs.flex_value_set_name = lv_carender_name                          -- カレンダー名で紐付け
    AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--    AND   (ld_comparison_date BETWEEN  NVL(ffv.start_date_active, ld_process_date)
--                                          AND  NVL(ffv.end_date_active,ld_process_date))
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    AND   (ld_comparison_date BETWEEN  NVL(ffv.start_date_active,ld_comparison_date)
                                  AND  NVL(ffv.end_date_active,ld_comparison_date))
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
    AND  ffv.enabled_flag  = 'Y';
    -- 対象年度取得処理にて、対象年度が取得できなかった場合
    IF (ln_active_year IS NULL) THEN
      RAISE NO_DATA_FOUND;
    END IF;
    ov_status      := cv_normal;
    ov_retcode     := gv_normal;          -- 処理結果に正常を返す
    on_active_year := ln_active_year;     -- 対象年度を格納
--
  EXCEPTION
--
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => cv_xxccp_msg10013       -- メッセージコード
                            );
      ov_status      := cv_warn;
      on_active_year := NULL;
      ov_retcode     := gv_warn;
      ov_errbuf      := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg      := lv_errmsg;
    WHEN NO_DATA_FOUND THEN
      -- メッセージ取得関数よりエラーメッセージをセットする
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm               -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg10005      -- メッセージコード
                     );
      ov_status      := cv_warn;
      on_active_year := NULL;
      ov_retcode     := gv_warn;
      ov_errbuf      := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg      := lv_errmsg;
    WHEN no_data_expt THEN
      -- メッセージ取得関数よりエラーメッセージをセットする
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm            -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg00005   -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_name    -- トークンコード1
                     ,iv_token_value1 => cv_carender_name    -- トークン値1
                     );
      ov_status      := cv_warn;
      on_active_year := NULL;
      ov_retcode     := gv_warn;
      ov_errbuf      := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg      := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,4000);
      ov_retcode := gv_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,4000);
      ov_retcode := gv_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,4000);
      ov_retcode := gv_error;
--
--###################################  固定部 END   #########################################
--
  END get_yearplan_calender;
--
  /**********************************************************************************
   * Procedure Name   : get_employee_info
   * Description      : 従業員情報取得関数
   ***********************************************************************************/
  PROCEDURE get_employee_info(
               iv_employee_code   IN  VARCHAR2                                  --従業員コード
              ,id_comparison_date IN  DATE                                      --発令日と比較する日付
              ,ov_capacity_code   OUT NOCOPY VARCHAR2                           --資格コード
              ,ov_duty_code       OUT NOCOPY VARCHAR2                           --職務コード
              ,ov_job_code        OUT NOCOPY VARCHAR2                           --職種コード
              ,ov_new_old_type    OUT NOCOPY VARCHAR2                           --新旧フラグ（1：新、2：旧）
              ,ov_retcode         OUT NOCOPY VARCHAR2                           --リターンコード
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           --エラーメッセージ
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           --ユーザー・エラーメッセージ
              )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_employee_info';
    cv_xxcsm_msg10006   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10006';
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_new              CONSTANT VARCHAR2(1)   := '1';
    cv_old              CONSTANT VARCHAR2(1)   := '2';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_comparison_date                DATE;
    lv_errbuf                         VARCHAR2(4000);
    lv_retcode                        VARCHAR2(4000);
    lv_errmsg                         VARCHAR2(4000);              -- OUTパラメータユーザー・エラーメッセージ格納用
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <get_employee_info_cur>
    CURSOR get_employee_info_cur(
      iv_employee_code VARCHAR2
    )
    IS
      SELECT paas.ass_attribute2  hatsurei_date          -- 発令日
            ,ppf.attribute7       new_shikaku_code       -- 資格コード(新)
            ,ppf.attribute9       old_shikaku_code       -- 資格コード(旧)
            ,ppf.attribute15      new_syokumu_code       -- 職務コード(新)
            ,ppf.attribute17      old_shokumu_code       -- 職務コード(旧)
            ,ppf.attribute19      new_shokusyu_code      -- 職種コード(新)
            ,ppf.attribute21      old_shokusyu_code      -- 職種コード(旧)
      FROM  per_people_f  ppf            -- 従業員マスタ
           ,per_all_assignments_f  paas  -- 従業員アサインメントマスタ
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
           ,(SELECT   ippf.person_id                  person_id                                     -- 従業員ID
                     ,MAX(ippf.effective_start_date)  effective_start_date                          -- 最新(有効開始日)
             FROM     per_people_f      ippf                                                        -- 従業員マスタ
             WHERE    ippf.current_emp_or_apl_flag = 'Y'                                            -- 有効フラグ
             GROUP BY ippf.person_id)   ippf                                                        -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
      WHERE ppf.employee_number  =  iv_employee_code   --従業員コードで紐付け
      AND   ppf.person_id = paas.person_id
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
      AND   ippf.person_id = ppf.person_id                                                          -- 従業員ID紐付↓
      AND   ippf.effective_start_date = ppf.effective_start_date                                    -- 最新(有効開始日)紐付け
      AND   paas.effective_start_date = ppf.effective_start_date                                    -- 最新(有効開始日)紐付け
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
      ;
    -- <カーソル名>レコード型
    get_employee_info_rec get_employee_info_cur%ROWTYPE;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
    --==============================
    -- INパラメータ:NULLチェック
    --==============================
    IF (iv_employee_code IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    --======================================================================
    -- INパラメータ:日付の値がNullの場合、業務日付を変数に格納
    -- その他の場合は、入力パラメータの日付を変数に格納し、処理に使用する。
    --======================================================================
    IF (id_comparison_date IS NULL) THEN
      ld_comparison_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_comparison_date := id_comparison_date;
    END IF;
    -- =====================================
    -- 従業員情報取得処理
    -- =====================================
    OPEN get_employee_info_cur(iv_employee_code);
      FETCH get_employee_info_cur INTO get_employee_info_rec;
      IF get_employee_info_cur%NOTFOUND THEN
        RAISE NO_DATA_FOUND;
      END IF;
    CLOSE get_employee_info_cur;
    IF (get_employee_info_rec.hatsurei_date IS NULL)THEN
        RAISE NO_DATA_FOUND;
    END IF;
--
    --取得した「発令日」と入力パラメータ「発令日と比較する日付」の比較
    IF (get_employee_info_rec.hatsurei_date > TO_CHAR(ld_comparison_date, 'YYYYMMDD')) THEN
      ov_retcode       := gv_normal;                     -- リターンコードに0（正常）を返す
      ov_capacity_code := get_employee_info_rec.old_shikaku_code;                 -- 資格コードに上記で取得した資格コード（旧）を返す
      ov_duty_code     := get_employee_info_rec.old_shokumu_code;                 -- 職務コードに上記で取得した職務コード（旧）を返す
      ov_job_code      := get_employee_info_rec.old_shokusyu_code;                -- 職種コードに上記で取得した職種コード（旧）を返す
      ov_new_old_type  := cv_old;
    ELSE
      ov_retcode       := gv_normal;                     -- リターンコードに0（正常）を返す
      ov_capacity_code := get_employee_info_rec.new_shikaku_code;                -- 資格コードに上記で取得した資格コード（新）を返す
      ov_duty_code     := get_employee_info_rec.new_syokumu_code;                -- 職務コードに上記で取得した職務コード（新）を返す
      ov_job_code      := get_employee_info_rec.new_shokusyu_code;               -- 職種コードに上記で取得した職種コード（新）を返す
      ov_new_old_type  := cv_new;
    END IF;
--
  EXCEPTION
--
  --取得件数が0件の場合
    WHEN NO_DATA_FOUND THEN
      IF (get_employee_info_cur%ISOPEN) THEN
        CLOSE get_employee_info_cur;
      END IF;
       -- メッセージ取得関数よりエラーメッセージをセットする
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg10006       -- メッセージコード
                     );
      ov_retcode       := gv_warn;        --リターンコードに1（警告）を返す
      ov_capacity_code := NULL;            --資格コードにNULLを返す
      ov_duty_code     := NULL;            --職務コードにNULLを返す
      ov_job_code      := NULL;            --職種コードにNULLを返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULLチェック
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => gv_xxcsm_msg10012       -- メッセージコード
                            );
      ov_retcode       := gv_warn;        --リターンコードに1（警告）を返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_employee_info;
--
  /**********************************************************************************
   * Procedure Name   : get_employee_foothold
   * Description      : 従業員在籍拠点コード取得関数
   ***********************************************************************************/
  PROCEDURE get_employee_foothold(
               iv_employee_code   IN  VARCHAR2                    --従業員コード
              ,id_comparison_date IN  DATE                        --発令日と比較する日付
              ,ov_foothold_code   OUT NOCOPY VARCHAR2             --拠点コード
              ,ov_retcode         OUT NOCOPY VARCHAR2             -- リターンコード
              ,ov_errbuf          OUT NOCOPY VARCHAR2             --エラーメッセージ
              ,ov_errmsg          OUT NOCOPY VARCHAR2             --ユーザー・エラーメッセージ
              )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_employee_foothold';
    cv_xxcsm_msg10007   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10007';
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_employee_code              VARCHAR2(1000);
    ld_comparison_date            DATE;
    lv_errbuf                     VARCHAR2(4000);
    lv_retcode                    VARCHAR2(4000);
    lv_errmsg                     VARCHAR2(4000);              -- OUTパラメータユーザー・エラーメッセージ格納用
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <get_employee_foothold_cur>
    CURSOR get_employee_foothold_cur(
      iv_employee_code VARCHAR2
    )
    IS
    SELECT paaf.ass_attribute2  hatsurei_date       -- 発令日
          ,paaf.ass_attribute5  new_kyoten_code     -- 拠点コード（新）
          ,paaf.ass_attribute6  old_kyoten_code     -- 拠点コード（旧）
    FROM  per_people_f  ppf            -- 従業員マスタ
         ,per_all_assignments_f  paaf  -- 従業員アサインメントマスタ
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
         ,(SELECT   ippf.person_id                  person_id                                       -- 従業員ID
                   ,MAX(ippf.effective_start_date)  effective_start_date                            -- 最新(有効開始日)
           FROM     per_people_f      ippf                                                          -- 従業員マスタ
           WHERE    ippf.current_emp_or_apl_flag = 'Y'                                              -- 有効フラグ
           GROUP BY ippf.person_id)   ippf                                                          -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
    WHERE ppf.employee_number  =  iv_employee_code  -- 従業員コードで紐付け
    AND   ppf.person_id = paaf.person_id
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
    AND   ippf.person_id = ppf.person_id                                                            -- 従業員ID紐付↓
    AND   ippf.effective_start_date = ppf.effective_start_date                                      -- 最新(有効開始日)紐付け
    AND   paaf.effective_start_date = ppf.effective_start_date                                      -- 最新(有効開始日)紐付け
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
    ;
    -- <カーソル名>レコード型
    get_employee_foothold_rec get_employee_foothold_cur%ROWTYPE;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
    --==============================
    -- INパラメータ:NULLチェック
    --==============================
    IF (iv_employee_code IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    --======================================================================
    -- INパラメータ:日付の値がNullの場合、業務日付を変数に格納
    -- その他の場合は、入力パラメータの日付を変数に格納し、処理に使用する。
    --======================================================================
    IF (id_comparison_date IS NULL) THEN
      ld_comparison_date := xxccp_common_pkg2.get_process_date;
    ELSE
      ld_comparison_date := id_comparison_date;
    END IF;
--
    -- =====================================
    -- 従業員在籍拠点コード取得処理
    -- =====================================
    OPEN get_employee_foothold_cur(iv_employee_code);
      FETCH get_employee_foothold_cur INTO get_employee_foothold_rec;
      IF get_employee_foothold_cur%NOTFOUND THEN
        RAISE NO_DATA_FOUND;
      END IF;
    CLOSE get_employee_foothold_cur;
    IF (get_employee_foothold_rec.hatsurei_date IS NULL) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
    --取得した「発令日(YYYYMMDD)」と入力パラメータ「発令日と比較する日付」の比較
    IF (get_employee_foothold_rec.hatsurei_date > TO_CHAR(ld_comparison_date, 'YYYYMMDD')) THEN
      ov_retcode       := gv_normal;                  -- リターンコードに0（正常）を返す
      ov_foothold_code := get_employee_foothold_rec.old_kyoten_code;          -- 拠点コードに上記で取得した拠点コード（旧）を返す
    ELSE
      ov_retcode       := gv_normal;                  -- リターンコードに0（正常）を返す
      ov_foothold_code := get_employee_foothold_rec.new_kyoten_code;          -- 拠点コードに上記で取得した拠点コード（新）を返す
    END IF;
--
  EXCEPTION
--
  --取得件数が0件の場合
    WHEN NO_DATA_FOUND THEN
      IF (get_employee_foothold_cur%ISOPEN) THEN
        CLOSE get_employee_foothold_cur;
      END IF;
       -- メッセージ取得関数よりエラーメッセージをセットする
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm                -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg10007       -- メッセージコード
                     );
      ov_retcode       := gv_warn;    -- リターンコードに1（警告）を返す
      ov_foothold_code := NULL;        -- 拠点コードにNULLを返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULLチェック
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => gv_xxcsm_msg10012       -- メッセージコード
                            );
      ov_retcode       := gv_warn;        --リターンコードに1（警告）を返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
--
  END get_employee_foothold;
--
  /**********************************************************************************
   * Procedure Name   : get_login_user_foothold
   * Description      : ログインユーザー在籍拠点コード取得関数
   ***********************************************************************************/
  PROCEDURE get_login_user_foothold(
               in_user_id       IN NUMBER                                       --ユーザID
              ,ov_foothold_code OUT NOCOPY VARCHAR2                             --拠点コード
              ,ov_employee_code OUT NOCOPY VARCHAR2                             --従業員コード
              ,ov_retcode       OUT NOCOPY VARCHAR2                             -- リターンコード
              ,ov_errbuf        OUT NOCOPY VARCHAR2                             --エラーメッセージ
              ,ov_errmsg        OUT NOCOPY VARCHAR2                             --ユーザー・エラーメッセージ
              )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_login_user_foothold';
    cv_xxcsm_msg10008          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10008';
    cv_xxcsm_msg10011          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10011';
    cv_xxcsm                   CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_tkn_jugyoin_cd          CONSTANT VARCHAR2(20) := 'JUGYOIN_CD';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lt_employee_number  per_people_f.employee_number%TYPE;
    lv_foothold_code    VARCHAR2(4000);
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUTパラメータユーザー・エラーメッセージ格納用
    --
    no_employee_date_expt EXCEPTION;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
    --==============================
    -- INパラメータ:NULLチェック
    --==============================
    IF (in_user_id IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    -- =====================================
    -- 従業員コード取得処理
    -- =====================================
    SELECT  ppf.employee_number          -- 従業員コード
    INTO    lt_employee_number
    FROM    fnd_user  fu                 -- ユーザマスタ
           ,per_people_f  ppf            -- 従業員マスタ
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
           ,(SELECT   ippf.person_id                  person_id                                     -- 従業員ID
                     ,MAX(ippf.effective_start_date)  effective_start_date                          -- 最新(有効開始日)
             FROM     per_people_f      ippf                                                        -- 従業員マスタ
             WHERE    ippf.current_emp_or_apl_flag = 'Y'                                            -- 有効フラグ
             GROUP BY ippf.person_id)   ippf                                                        -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
    WHERE   fu.user_id     =  in_user_id
    AND     fu.employee_id = ppf.person_id
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
    AND     ppf.person_id = ippf.person_id                                                          -- 従業員ID紐付け
    AND     ppf.effective_start_date = ippf.effective_start_date                                    -- 最新(有効開始日)紐付け
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
    ;
    ov_employee_code := lt_employee_number;
    -- 取得が0件の場合
    IF (lt_employee_number IS NULL) THEN
      RAISE NO_DATA_FOUND;
    END IF;
  --
  --
    xxcsm_common_pkg.get_employee_foothold(
       iv_employee_code   => lt_employee_number      --従業員コード
      ,id_comparison_date => xxccp_common_pkg2.get_process_date   --業務日付をとってくる関数
      ,ov_foothold_code   => lv_foothold_code
      ,ov_retcode         => lv_retcode
      ,ov_errbuf          => lv_errbuf
      ,ov_errmsg          => lv_errmsg
      );
    -- 従業員在籍拠点コード取得関数にて、データが取得できたかをチェックする
    -- できていなかった場合、エラーを発生させる
    IF (lv_retcode <> gv_normal) THEN
      RAISE no_employee_date_expt;
    END IF;
    -- OUTパラメータに取得した値をセット
    ov_foothold_code := lv_foothold_code;
    ov_retcode       := lv_retcode;
    ov_errbuf        := lv_errbuf;
    ov_errmsg        := lv_errmsg;
  --
  EXCEPTION
--
  --取得件数が0件の場合
    WHEN NO_DATA_FOUND THEN
      -- メッセージ取得関数よりエラーメッセージをセットする
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm               -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg10008      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_jugyoin_cd
                     ,iv_token_value1 => in_user_id
                     );
      ov_retcode       := gv_warn;    --リターンコードに1（警告）を返す
      ov_foothold_code := NULL;        --拠点コードにNULLを返す
      ov_employee_code := NULL;        --従業員コードにNULLを返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
    WHEN no_employee_date_expt THEN
       -- メッセージ取得関数よりエラーメッセージをセットする
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => cv_xxcsm_msg10011       -- メッセージコード
                            );
      ov_retcode       := gv_warn;    --リターンコードに1（警告）を返す
      ov_foothold_code := NULL;        --拠点コードにNULLを返す
      ov_employee_code := NULL;        --従業員コードにNULLを返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULLチェック
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => gv_xxcsm_msg10012       -- メッセージコード
                            );
      ov_retcode       := gv_warn;        --リターンコードに1（警告）を返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,4000);
      ov_retcode := gv_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_login_user_foothold;
--
  /**********************************************************************************
   * Procedure  Name   : year_item_plan_security
   * Description       : 年間商品計画セキュリティ制御用関数
   ***********************************************************************************/
  PROCEDURE year_item_plan_security(
               in_user_id          IN  NUMBER
              ,ov_lv6_kyoten_list  OUT NOCOPY VARCHAR2     --所属（1:営業企画、2：営業管理部･課、3：その他）
              ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターンコード
              ,ov_errbuf           OUT NOCOPY VARCHAR2     --エラーメッセージ
              ,ov_errmsg           OUT NOCOPY VARCHAR2     --ユーザー・エラーメッセージ
              )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'year_item_plan_security';
    cv_no_flv_tag       CONSTANT VARCHAR2(100) := '3';
    cv_xxcsm_msg10009   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10009';
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';

--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_kyoten_cd        VARCHAR2(4000);
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUTパラメータユーザー・エラーメッセージ格納用
    --
    no_data_kyoten_expt EXCEPTION;
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <get_year_item_cur>
    CURSOR get_year_item_cur(
      in_user_id NUMBER
    )
    IS
      SELECT paaf.ass_attribute2  hatsurei_date   --発令日
            ,paaf.ass_attribute5  new_kyoten_code --拠点コード（新）
            ,paaf.ass_attribute6  old_kyoten_code --拠点コード（旧）
      FROM   fnd_user  fu
            ,per_all_assignments_f  paaf
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
           ,(SELECT   ipaf.person_id                  person_id                                     -- 従業員ID
                     ,MAX(ipaf.effective_start_date)  effective_start_date                          -- 最新(有効開始日)
             FROM     per_all_assignments_f      ipaf                                               -- 従業員アサイメントマスタ
             GROUP BY ipaf.person_id)   ipaf                                                        -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
      WHERE fu.user_id  =  in_user_id
      AND   fu.employee_id = paaf.person_id
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
      AND   paaf.person_id = ipaf.person_id                                                         -- 従業員ID紐付↓
      AND   paaf.effective_start_date = ipaf.effective_start_date                                   -- 最新(有効開始日)紐付け
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
      ;
    -- <カーソル名>レコード型
    get_year_item_rec get_year_item_cur%ROWTYPE;

--
    -- <get_dept_date_cur>
    CURSOR get_dept_date_cur(
      iv_kyoten_cd2 VARCHAR2
    )
    IS
      SELECT flv.tag
      FROM   fnd_lookup_values  flv
            ,xxcsm_loc_level_list_v  xlllv
      WHERE  flv.lookup_type  = 'XXCSM1_BUSINESS_DEPT'
      AND    flv.language     = USERENV('LANG')
      AND    flv.enabled_flag = 'Y'
      AND    NVL(flv.start_date_active,xxccp_common_pkg2.get_process_date)  <= xxccp_common_pkg2.get_process_date
      AND    NVL(flv.end_date_active,xxccp_common_pkg2.get_process_date)    >= xxccp_common_pkg2.get_process_date
--//+DEL START   2009/08/18 0001045 T.Tsukino
--      AND    flv.lookup_code  = DECODE(flv.attribute1 , 'L1' ,xlllv.cd_level1
--                                                     , 'L2' ,xlllv.cd_level2
--                                                     , 'L3' ,xlllv.cd_level3
--                                                     , 'L4' ,xlllv.cd_level4
--                                                     , 'L5' ,xlllv.cd_level5
--                                                            ,xlllv.cd_level6)
--//+DEL END   2009/08/18 0001045 T.Tsukino
--//+ADD START 2009/08/18 0001045 T.Tsukino
      AND   flv.lookup_code = iv_kyoten_cd2
--//+ADD END   2009/08/18 0001045 T.Tsukino
      AND   iv_kyoten_cd2 = DECODE(xlllv.location_level , 'L6' ,xlllv.cd_level6
                                                        , 'L5' ,xlllv.cd_level5
                                                        , 'L4' ,xlllv.cd_level4
                                                        , 'L3' ,xlllv.cd_level3
                                                               ,xlllv.cd_level2)
      ;
    -- <カーソル名>レコード型
    get_dept_date_rec get_dept_date_cur%ROWTYPE;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
    --==============================
    -- INパラメータ:NULLチェック
    --==============================
    IF (in_user_id IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    -- =====================================
    -- 拠点コード（新/旧）・発令日取得処理
    -- =====================================
    OPEN get_year_item_cur(in_user_id);
    FETCH get_year_item_cur INTO get_year_item_rec;
    IF get_year_item_cur%NOTFOUND THEN
      RAISE no_data_kyoten_expt;
    END IF;
    CLOSE get_year_item_cur;
    IF (get_year_item_rec.hatsurei_date IS NULL) THEN
      RAISE no_data_kyoten_expt;
    END IF;
    -- =====================================
    -- 拠点コード算出処理
    -- =====================================
    IF (get_year_item_rec.hatsurei_date > TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')) THEN
      lv_kyoten_cd := get_year_item_rec.old_kyoten_code;  --拠点コード（旧）
    ELSE
      lv_kyoten_cd := get_year_item_rec.new_kyoten_code;  --拠点コード（新)
    END IF;
    -- =====================================
    -- 部門情報取得処理
    -- =====================================
    OPEN get_dept_date_cur(lv_kyoten_cd);
    FETCH get_dept_date_cur INTO get_dept_date_rec;
    CLOSE get_dept_date_cur;
    --出力パラメータ処理
    IF (get_dept_date_rec.tag IS NULL) THEN
      ov_lv6_kyoten_list := cv_no_flv_tag;
    ELSE
      ov_lv6_kyoten_list  := get_dept_date_rec.tag;
    END IF;
    ov_retcode          := gv_normal;
--
  EXCEPTION
--
  -- 拠点コード・発令日の取得ができなかった場合
    WHEN no_data_kyoten_expt THEN
      IF (get_year_item_cur%ISOPEN) THEN
        CLOSE get_year_item_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcsm               -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg10009      -- メッセージコード
                     );
      ov_retcode         := gv_warn;           --リターンコードに1（警告）を返す
      ov_errbuf          := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg          := lv_errmsg;
--
    --NULLチェック
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => gv_xxcsm_msg10012       -- メッセージコード
                            );
      ov_retcode       := gv_warn;        --リターンコードに1（警告）を返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END year_item_plan_security;
--
  /**********************************************************************************
   * Procedure  Name   : get_year_month
   * Description       : 年度算出関数
   ***********************************************************************************/
  PROCEDURE get_year_month(
               iv_process_years IN VARCHAR2
              ,ov_year          OUT NOCOPY VARCHAR2
              ,ov_month         OUT NOCOPY VARCHAR2
              ,ov_retcode       OUT NOCOPY VARCHAR2
              ,ov_errbuf        OUT NOCOPY VARCHAR2
              ,ov_errmsg        OUT NOCOPY VARCHAR2
              )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_year_month';
    cv_gl_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';           -- 会計帳簿ID
    cv_xxcsm            CONSTANT VARCHAR2(100) := 'XXCSM';
    cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_xxcsm_msg00005   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';
    cv_xxcsm_msg10001   CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(4000);
    lv_retcode          VARCHAR2(4000);
    lv_errmsg           VARCHAR2(4000);              -- OUTパラメータユーザー・エラーメッセージ格納用
    lv_gl_id            VARCHAR2(100);
    no_data_gl_expt     EXCEPTION;
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <get_year_month_cur>
    CURSOR get_year_month_cur(
      in_gl_id        NUMBER
     ,iv_process_year VARCHAR2
    )
    IS
    SELECT DISTINCT gp.period_year                 period_year
          ,TO_NUMBER(TO_CHAR(gp.start_date, 'MM')) start_date
    FROM   gl_sets_of_books gsob
          ,gl_periods       gp
    WHERE  gsob.set_of_books_id = in_gl_id
    AND    gsob.period_set_name = gp.period_set_name
    AND    TO_CHAR(gp.start_date,'YYYYMM') <= iv_process_year
    AND    TO_CHAR(gp.end_date,'YYYYMM') >= iv_process_year
    ;
    -- <カーソル名>レコード型
    get_year_month_rec get_year_month_cur%ROWTYPE;
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
    --==============================
    -- INパラメータ:NULLチェック
    --==============================
    IF (iv_process_years IS NULL) THEN
      RAISE global_null_chk_expt;
    END IF;
    -- =====================================
    -- プロファイル値取得(FND_PROFILE.VALUE)
    -- =====================================
    lv_gl_id         := FND_PROFILE.VALUE(cv_gl_id);
    --
    --プロファイル値取得ができなかった場合
    IF (lv_gl_id IS NULL) THEN
      RAISE no_data_gl_expt;
    END IF;
    -- =====================================
    -- 年度・月取得処理
    -- =====================================
    OPEN get_year_month_cur(TO_NUMBER(lv_gl_id), iv_process_years);
    FETCH get_year_month_cur INTO get_year_month_rec;
    IF (get_year_month_cur%NOTFOUND) THEN
       RAISE NO_DATA_FOUND;
    END IF;
    CLOSE get_year_month_cur;
    IF (get_year_month_rec.period_year IS NULL
        OR get_year_month_rec.start_date IS NULL) THEN
        RAISE NO_DATA_FOUND;
    END IF;
    ov_year  := get_year_month_rec.period_year;
    ov_month := TO_CHAR(get_year_month_rec.start_date);
  EXCEPTION
--
  --プロファイルオプション値を取得できなかった場合
    WHEN no_data_gl_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                             -- アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg00005                     -- メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_name                     -- トークンコード1
                    ,iv_token_value1 => cv_gl_id                             -- トークン値1
                     );
      ov_year          := NULL;
      ov_month         := NULL;
      ov_retcode       := gv_warn;
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
  --取得件数が0件の場合
    WHEN NO_DATA_FOUND THEN
      IF (get_year_month_cur%ISOPEN) THEN
        CLOSE get_year_month_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                             -- アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg10001                          -- メッセージコード
                     );
      ov_year          := NULL;
      ov_month         := NULL;
      ov_retcode       := gv_warn;           --リターンコードに1（警告）を返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
    --NULLチェック
    WHEN global_null_chk_expt THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm                -- アプリケーション短縮名
                            ,iv_name         => gv_xxcsm_msg10012       -- メッセージコード
                            );
      ov_retcode       := gv_warn;        --リターンコードに1（警告）を返す
      ov_errbuf        := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg        := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_year_month;
--
  /**********************************************************************************
   * Procedure  Name   : get_kyoten_cd_lv6
   * Description       : 営業部門配下の拠点リスト取得
   ***********************************************************************************/
  PROCEDURE get_kyoten_cd_lv6(
               iv_kyoten_cd         IN VARCHAR2
              ,iv_kaisou            IN VARCHAR2
--//+ADD START 2009/05/07 T1_0858 M.Ohtsuki
              ,iv_subject_year      IN VARCHAR2
--//+ADD END   2009/05/07 T1_0858 M.Ohtsuki
              ,o_kyoten_list_tab    OUT g_kyoten_ttype
              ,ov_retcode           OUT NOCOPY VARCHAR2
              ,ov_errbuf            OUT NOCOPY VARCHAR2
              ,ov_errmsg            OUT NOCOPY VARCHAR2
              )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_kyoten_cd_lv6';     -- プログラム名
    cv_xxcsm            CONSTANT VARCHAR2(100)  := 'XXCSM';
    cv_xxcsm_msg00121   CONSTANT VARCHAR2(100)  := 'APP-XXCSM1-10121';
    cv_tkn_kyoten       CONSTANT VARCHAR2(100)  := 'KYOTEN';
    cv_tkn_kaisou       CONSTANT VARCHAR2(100)  := 'KAISOU';

--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_level_6               CONSTANT VARCHAR2(2)    := 'L6';                   -- 階層L6
    cv_level_5               CONSTANT VARCHAR2(2)    := 'L5';                   -- 階層L5
    cv_level_4               CONSTANT VARCHAR2(2)    := 'L4';                   -- 階層L4
    cv_level_3               CONSTANT VARCHAR2(2)    := 'L3';                   -- 階層L3
    cv_level_2               CONSTANT VARCHAR2(2)    := 'L2';                   -- 階層L2
    cv_level_1               CONSTANT VARCHAR2(2)    := 'L1';                   -- 階層L1
    cv_level_all             CONSTANT VARCHAR2(3)    := 'ALL';                  -- 全対象
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_kaisou     VARCHAR2(5);
    ln_all_flag   NUMBER;
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    -- **入力パラメータで全拠点が指定された場合、1が戻される。
    CURSOR all_loc_chk_cur(
      iv_all_loc_value   VARCHAR2
      )
    IS
      SELECT COUNT(1)
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type = 'XXCSM1_FORM_PARAMETER_VALUE'
      AND    flv.language = USERENV('LANG')
      AND    flv.enabled_flag = 'Y'
      AND    NVL(flv.start_date_active,xxccp_common_pkg2.get_process_date)  <= xxccp_common_pkg2.get_process_date
      AND    NVL(flv.end_date_active,xxccp_common_pkg2.get_process_date)    >= xxccp_common_pkg2.get_process_date
      AND    flv.lookup_code = iv_all_loc_value
      ;
    -- ============================
    -- ローカルテーブル定義
    -- ============================
    l_get_loc_tab g_kyoten_ttype;    --データ取得用変数
    -- ============================
    -- ローカル・例外
    -- ============================
    no_data_kyoten_expt     EXCEPTION;
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_normal;
--
--###########################  固定部 END   ############################
--
    ln_all_flag  :=  0;
    --入力パラメータの部門コード指定or全拠点対象か判定。
    IF (iv_kaisou = cv_level_6) THEN
      -- **全拠点が指定されるのは階層がL6の場合のみのため、その他の場合は、全拠点のチェックを行わない。
      OPEN all_loc_chk_cur(iv_kyoten_cd);
      FETCH all_loc_chk_cur INTO ln_all_flag;
      CLOSE all_loc_chk_cur;
    END IF;
--
    --部門コード指定の場合と全拠点対象とする場合で
    --SQLに渡すパラメータを制御
    IF (ln_all_flag > 0) THEN
      lv_kaisou  := cv_level_all;
    ELSE
      lv_kaisou  := iv_kaisou;
    END IF;
    --=======================================================================
    --入力パラメータの部門コードと階層から、配下の拠点を抽出。
    --全拠点の場合、全ての拠点コードを取得します。
    --配下に子を持つ部門コード指定の場合、その部門コード配下に紐付く拠点コードを取得します。
    --拠点コード指定の場合、指定された拠点コードのみを取得します。
    --=======================================================================
    SELECT xlnlv.base_code       AS kyoten_cd    --拠点コード
          ,xlnlv.base_name       AS kyoten_nm    --拠点名称
    BULK COLLECT INTO l_get_loc_tab
    FROM   xxcsm_loc_name_list_v     xlnlv       --部門名称ビュー
          ,xxcsm_loc_level_list_v    xlllv       --部門一覧ビュー
    WHERE  iv_kyoten_cd = DECODE(DECODE(lv_kaisou, cv_level_6, xlllv.location_level
                                                             , lv_kaisou)
                                ,cv_level_6,xlllv.cd_level6
                                ,cv_level_5,xlllv.cd_level5
                                ,cv_level_4,xlllv.cd_level4
                                ,cv_level_3,xlllv.cd_level3
                                ,cv_level_2,xlllv.cd_level2
                                ,cv_level_1,xlllv.cd_level1
                                ,cv_level_all,iv_kyoten_cd    --'ALL'の場合は、条件を無効化させる。
                                ,NULL)
    AND    xlnlv.base_code = DECODE(xlllv.location_level
                                   ,cv_level_6,xlllv.cd_level6
                                   ,cv_level_5,xlllv.cd_level5
                                   ,cv_level_4,xlllv.cd_level4
                                   ,cv_level_3,xlllv.cd_level3
                                   ,cv_level_2,xlllv.cd_level2
                                   ,cv_level_1,xlllv.cd_level1
                                   ,NULL)
--//DEL START 2012/12/14 E_本稼動_05803 Y.Kanami
----// ADD START 2009/05/07 T1_0858 M.Ohtsuki
--      AND EXISTS
--          (SELECT 'X'
--           FROM   xxcsm_item_plan_result   xipr                                                     -- 商品計画用販売実績
--           WHERE  (xipr.subject_year = (TO_NUMBER(iv_subject_year) - 1)                             -- 入力パラメータの1年前のデータ
--                OR xipr.subject_year = (TO_NUMBER(iv_subject_year) - 2))                            -- 入力パラメータの2年前のデータ
--           AND     xipr.location_cd  = xlnlv.base_code)
----// ADD END   2009/05/07 T1_0858 M.Ohtsuki
--// DEL START 2012/12/14 E_本稼動_05803 Y.Kanami
--// ADD START 2012/12/14 E_本稼動_05803 Y.Kanami
    ORDER BY xlnlv.main_dept_cd ASC              -- 本部コード
            ,xlnlv.base_code    ASC              -- 拠点コード
--// ADD START 2012/12/14 E_本稼動_05803 Y.Kanami
    ;
    -- 抽出コードの件数が0件の場合
    IF (l_get_loc_tab.COUNT = 0) THEN
      RAISE no_data_kyoten_expt;
    END IF;
--
    --OUTパラメータにデータを戻す。
    o_kyoten_list_tab   := l_get_loc_tab;
--
  EXCEPTION
    WHEN no_data_kyoten_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                             -- アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg00121                    -- メッセージコード
                    ,iv_token_name1  => cv_tkn_kyoten                        -- トークンコード1
                    ,iv_token_value1 => iv_kyoten_cd                         -- トークン値1
                    ,iv_token_name2  => cv_tkn_kaisou                        -- トークンコード2
                    ,iv_token_value2 => iv_kaisou                            -- トークン値2
                     );
      ov_retcode          := gv_warn;
      ov_errbuf           := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,4000);
      ov_errmsg           := lv_errmsg;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_kyoten_cd_lv6;
END xxcsm_common_pkg;
/
