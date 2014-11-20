CREATE OR REPLACE PACKAGE xxcsm_common_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcsm_common_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CSM_共通関数
 * Version                : 1.0
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
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-11-27    1.0  T.Tsukino       新規作成
 *****************************************************************************************/
--
    -- ==============================
    -- グローバルRECORD型
    -- =============================
   -- 拠点リストレコード
    TYPE g_kyoten_rtype IS RECORD(
      kyoten_cd           fnd_flex_values.flex_value%TYPE       -- 拠点コード
     ,kyoten_nm           fnd_flex_values_tl.description%TYPE   -- 拠点名称
       );
    --  拠点リストテーブル
    TYPE g_kyoten_ttype IS TABLE OF g_kyoten_rtype INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure  Name   : get_yearplan_calender
   * Description       : 年間計画カレンダ取得関数
   ***********************************************************************************/
  PROCEDURE get_yearplan_calender(
               id_comparison_date IN  DATE                                      -- 日付
              ,ov_status          OUT NOCOPY VARCHAR2                           -- 処理結果(0：正常、1：異常
              ,on_active_year     OUT NUMBER                                    -- 対象年度
              ,ov_retcode         OUT NOCOPY VARCHAR2                           -- リターンコード
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           -- エラーメッセージ
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           -- ユーザー・エラーメッセージ
              );
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
              ,ov_retcode         OUT NOCOPY VARCHAR2                           -- リターンコード
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           --エラーメッセージ
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           --ユーザー・エラーメッセージ
              );
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
              );
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
              );
--
  /**********************************************************************************
   * Procedure  Name   : year_item_plan_security
   * Description       : 年間商品計画セキュリティ制御用関数
   ***********************************************************************************/
  PROCEDURE year_item_plan_security(
               in_user_id          IN  NUMBER
              ,ov_lv6_kyoten_list  OUT NOCOPY VARCHAR2
              ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターンコード
              ,ov_errbuf           OUT NOCOPY VARCHAR2          --エラーメッセージ
              ,ov_errmsg           OUT NOCOPY VARCHAR2          --ユーザー・エラーメッセージ              
              );
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
              );              
--
  /**********************************************************************************
   * Procedure  Name   : get_kyoten_cd_lv6
   * Description       : 営業部門配布した拠点リストの取得
   ***********************************************************************************/
  PROCEDURE get_kyoten_cd_lv6(
               iv_kyoten_cd         IN VARCHAR2
              ,iv_kaisou            IN VARCHAR2
              ,o_kyoten_list_tab    OUT g_kyoten_ttype
              ,ov_retcode           OUT NOCOPY VARCHAR2
              ,ov_errbuf            OUT NOCOPY VARCHAR2
              ,ov_errmsg            OUT NOCOPY VARCHAR2
              );
END xxcsm_common_pkg;
/

