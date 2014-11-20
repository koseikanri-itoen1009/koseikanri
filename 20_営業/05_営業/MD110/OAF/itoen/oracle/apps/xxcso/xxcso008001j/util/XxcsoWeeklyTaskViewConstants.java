/*============================================================================
* ファイル名 : XxcsoWeeklyTaskViewConstants
* 概要説明   : 週次活動状況照会共通固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-07 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.util;

/*******************************************************************************
 * アドオン：週次活動状況照会の共通固定値クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoWeeklyTaskViewConstants 
{
  /*****************************************************************************
   * AM内共通定数
   *****************************************************************************
   */
  public static final String RESOURCE_ID    = "resourceId";
  public static final String EMP_NAME       = "empName";
  public static final int   MAX_SIZE_INT    = 10;
  public static final String MAX_SIZE_STR   = "10";

  /*****************************************************************************
   * URLパラメータ キー値
   *****************************************************************************
   */
  public static final String MODE_TRANSFER         = "1";
  public static final String PARAM_TASK_ID         = "cacTaskId";
  public static final String PARAM_TASK_RETURN_URL = "cacTaskReturnUrl";
  public static final String PARAM_TASK_USER_AUTH  = "cacTaskUsrAuth";
  public static final String PARAM_BASE_PAGE_REGION_CODE
                                                      = "CacBasePageRegionCode";
  public static final String PARAM_RETURN_LABEL    = "cacTaskReturnLabel";
  public static final String PARAM_VALUE_RETURN_LABEL
                                                   = "週次活動状況照会へ戻る";

  /*****************************************************************************
   * 確認・エラーメッセージ用文言
   *****************************************************************************
   */
  public static final String MSG_DISP_CSV       = "CSVファイル：";
  public static final String MSG_DISP_OUT       = "出力";
  public static final String MSG_DISP_DATE      = "日付";
  public static final String MSG_DISP_EMPSEL    = "担当者選択";

  /*****************************************************************************
   * CSVファイル名
   *****************************************************************************
   */
  public static final String CSV_NAME_DELIMITER = "_";
  public static final String CSV_EXTENSION      = ".csv";

  /*****************************************************************************
   * リージョン名
   *****************************************************************************
   */
  public static final String RN_EMP_SEL_ADV_TBL = "EmployeeSelectAdvTblRN";
  public static final String RN_TASK_ADV_TBL    = "TaskAdvTblRN";

}