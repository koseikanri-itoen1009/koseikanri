/*============================================================================
* ファイル名 : XxcsoSalesPlanBulkRegistConstants
* 概要説明   : 売上計画（複数顧客）　共通固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦    新規作成
* 2009-04-22 1.1  SCS柳平直人  [ST障害T1_0585]画面遷移セキュリティ不正対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.util;

/*******************************************************************************
 * 売上計画（複数顧客）　共通固定値クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistConstants 
{
  public static final String MODE_FIRE_ACTION        = "FireAction";

  public static final String[] CENTERING_OBJECTS =
  {
    "SearchPlanYearMonthLayout"
   ,"ResourceLayout"
   ,"TrgtRsrcMonthlyPlanLayout"
   ,"TrgtRsrcAcctMonthlyPlanSumLayout"
   ,"TrgtRsrcAcctDifferLayout"
   ,"NextRsrcMonthlyPlanLayout"
   ,"NextRsrcAcctMonthlyPlanSumLayout"
   ,"NextRsrcAcctDifferLayout"
  };

  /*****************************************************************************
   * トークン値
   *****************************************************************************
   */
  public static final String TOKEN_VALUE_EMPLOYEE_NUMBER            = "営業員";
  public static final String TOKEN_VALUE_TARGET_YEAR                = "対象年";
  public static final String TOKEN_VALUE_TARGET_MONTH               = "対象月";
  public static final String TOKEN_VALUE_ACCOUNT_NUMBER             = 
                                "顧客コード";
  public static final String TOKEN_VALUE_PARTY_NAME                 = "顧客";
  public static final String TOKEN_VALUE_TRGT_MONTH_SALES_PLAN_AMT  = 
                                "顧客別月別売上計画(対象月)";
  public static final String TOKEN_VALUE_NEXT_MONTH_SALES_PLAN_AMT  = 
                                "顧客別月別売上計画(対象翌月)";
  public static final String TOKEN_VALUE_NEXT_EMPLOYEE_NUMBER       = 
                                "顧客名(対象翌月)";

// 2009/04/22 [ST障害T1_0585] Add Start
  /*****************************************************************************
   * プロファイルオプション値
   *****************************************************************************
   */
  public static final String XXCSO1_SALES_PLAN_SECURITY             =
                                "XXCSO1_SALES_PLAN_SECURITY";
  /*****************************************************************************
   * セキュリティ値
   *****************************************************************************
   */
  public static final String SECURITY_EDIT                          = "0";
  public static final String SECURITY_REFERENCE                     = "1";

// 2009/04/22 [ST障害T1_0585] Add End

}