/*============================================================================
* ファイル名 : XxccpConstants
* 概要説明   : CCP共通定数
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.util;
/*import oracle.jbo.domain.Number;*/
/***************************************************************************
 * CCP共通定数クラスです。
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpConstants 
{
  /** アプリケーション短縮名：XXCCP */
  public static final String APPL_XXCCP           = "XXCCP";
  /** トランザクション名：Xxccp008A01jTxn */
  public static final String TXN_XXCCP008A01J     = "Xxccp008A01jTxn";
  /** クラス名：XxccpUtility */
  public static final String CLASS_XXCCP_UTILITY  = "itoen.oracle.apps.xxccp.util.XxccpUtility";
  /** クラス名２：XxccpUtility2 */
  public static final String CLASS_XXCCP_UTILITY2 = "itoen.oracle.apps.xxccp.util.XxccpUtility2";

  /** 起動パラメータ名 */
  public static final String XXCCP008A01J_PARAM   = "CONTENT_TYPE";
  /** 参照タイプ タイプ名称 */
  public static final String LOOKUP_TYPE          = "XXCCP1_FILE_UPLOAD_OBJ";
  /** 固定値：CSV */
  public static final String CSV_NM               = "CSV";
  /** 定数：ドット */
  public static final String DOT                  = ".";
  /** 定数：改行コード */
  public static final String CHANGING_LINE_CODE   = "<br>";

  /** メッセージ：APP-XXCCP1-91000 ファイル未指定エラー*/
  public static final String XXCCP191000        = "APP-XXCCP1-91000";
  /** メッセージ：APP-XXCCP1-91001 コンカレント起動エラー*/
  public static final String XXCCP191001        = "APP-XXCCP1-91001";
  /** メッセージ：APP-XXCCP1-91002 コンカレント起動正常メッセージ*/
  public static final String XXCCP191002        = "APP-XXCCP1-91002";
  /** メッセージ：APP-XXCCP1-91003 システムエラー*/
  public static final String XXCCP191003        = "APP-XXCCP1-91003";
  /** メッセージ：APP-XXCCP1-91004 処理成功*/
  public static final String XXCCP191004        = "APP-XXCCP1-91004";
  /** メッセージ：APP-XXCCP1-91005 処理失敗*/
  public static final String XXCCP191005        = "APP-XXCCP1-91005";

  /** トークン：TOKEN */
  public static final String TOKEN_PROCESS      = "PROCESS";

  /** API戻り値：0 */
  public static final String API_RETURN_NORMAL  = "0";
  /** API戻り値：1 */
  public static final String API_RETURN_WARN    = "1";
  /** API戻り値：2 */
  public static final String API_RETURN_ERROR   = "2";
  /** API戻り値：S */
  public static final String API_STATUS_SUCCESS = "S";
  /** API戻り値：E */
  public static final String API_STATUS_ERROR   = "E";
  /** API戻り値：1 パラメータチェックエラー */
  public static final String API_PARAM_ERROR    = "1";

  /** URL：ホーム画面 */
  public static final String URL_OAHOMEPAGE     = "OAHOMEPAGE";
  /** ページタイトルの固定部分 (「ファイルアップロード：　」)*/
  public static final String DISP_TEXT          = "ファイルアップロード：";
}