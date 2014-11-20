/*============================================================================
* ファイル名 : XxcsoVisitSalesPlanConstants
* 概要説明   : 訪問・売上計画画面　共通固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.util;

/*******************************************************************************
 * 訪問・売上計画画面　共通固定値クラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoVisitSalesPlanConstants 
{
  public static final String MODE_FIRE_ACTION        = "FireAction";

  public static final String[] CENTERING_OBJECTS =
  {
    "SearchAccountLayout"
   ,"SearchPlanYearMonthLayout"
   ,"TargetMonthSalesPlanAmtLayout"
   ,"AcctDailyPlanSumLayout"
   ,"AcctDailyPlanDifferLayout"
  };

  /*****************************************************************************
   * トークン値
   *****************************************************************************
   */
  public static final String TOKEN_VALUE_ACCOUNT_NUMBER   = "顧客コード";
  public static final String TOKEN_VALUE_PLAN_YEAR        = "計画年";
  public static final String TOKEN_VALUE_PLAN_MONTH       = "計画月";
  public static final String TOKEN_VALUE_TRGT_ROUTENO     = "ルートNo(当月)";
  public static final String TOKEN_VALUE_NEXT_ROUTENO     = "ルートNo(翌月以降)";
  public static final String TOKEN_VALUE_TARGET_MONTH_SALES_PLAN_AMT
                                                          = "月間売上計画";
}