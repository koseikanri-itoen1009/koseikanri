/*============================================================================
* ファイル名 : XxcsoSalesPlanConstants
* 概要説明   : 売上計画出力共通固定値クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS朴邦彦  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.util;

/*******************************************************************************
 * アドオン：売上計画出力の共通固定値クラスです。
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanConstants 
{
  /*****************************************************************************
   * AM内共通定数
   *****************************************************************************
   */

  /*****************************************************************************
	* プロファイルオプション値（共通）
   *****************************************************************************
   */
  public static final String XXCSO1_EXCEL_VER_SLSPLN_ROUTE = "XXCSO1_EXCEL_VER_SLSPLN_ROUTE";
  public static final String XXCSO1_EXCEL_VER_SLSPLN_HONBU = "XXCSO1_EXCEL_VER_SLSPLN_HONBU";

  /*****************************************************************************
   * 確認・エラーメッセージ用文言
   *****************************************************************************
   */
  public static final String MSG_DISP_BASECODE  = "拠点コード";
  public static final String MSG_DISP_BIZYEAR   = "年度";
  public static final String MSG_DISP_CSV       = "CSVファイル：";
  public static final String MSG_DISP_OUT       = "出力";
  public static final String MSG_DISP_DATE      = "日付";

  /*****************************************************************************
   * CSVファイル
   *****************************************************************************
   */
  public static final String CSV_ITEM_QUOTATION = "\"";
  public static final String CSV_ITEM_DELIMITER = ",";
  public static final String CSV_NAME_DELIMITER = "_";
  public static final String CSV_NAME_KEY       = "_download_";
  public static final String CSV_EXTENSION      = ".csv";
  public static final String CSV_CRLF = "\r\n";
  public static final int CSV_MAX_ITEM_ID = 47;
  public static final int CSV_ITEM_ID_BASE_CODE = 5;
  public static final int CSV_ITEM_ID_BASE_NAME = 6;

}
