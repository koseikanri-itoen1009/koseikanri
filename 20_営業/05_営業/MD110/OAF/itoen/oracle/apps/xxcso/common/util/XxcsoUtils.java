/*============================================================================
* ファイル名 : XxcsoUtils
* 概要説明   : 【アドオン：営業・営業領域】共通関数クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-24 1.0  SCS柳平直人  新規作成
* 2008-12-07 1.0  SCS小川浩    デバッグ出力（ローカル用）追加
* 2008-12-10 1.0  SCS小川浩    最大件数チェック関数追加
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAFwkConstants;

/*******************************************************************************
 * アドオン：共通関数クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUtils 
{
  /*****************************************************************************
   * デバッグレベル
   *****************************************************************************
   */
  private static final int DEBUG_LEVEL = OAFwkConstants.EXCEPTION;
  
  /*****************************************************************************
   * ページ間メッセージ設定
   * @param pageContext       ページコンテキスト
   * @param OAException       メッセージ
   *****************************************************************************
   */
  public static void setDialogMessage(
    OAPageContext pageContext
   ,OAException   message
  )
  {
    pageContext.putParameter("XXCSO_DURING_PAGE_MESSAGE", message);
  }

  /*****************************************************************************
   * ページ間メッセージ表示
   * @param pageContext       ページコンテキスト
   *****************************************************************************
   */
  public static void showDialogMessage(
    OAPageContext pageContext
  )
  {
    OAException message
      = (OAException)
          pageContext.getParameterObject("XXCSO_DURING_PAGE_MESSAGE");

    if ( message != null )
    {
      pageContext.putDialogMessage(message);
      pageContext.removeParameter("XXCSO_DURING_PAGE_MESSAGE");
    }
  }

  /*****************************************************************************
   * 最大件数チェック
   * @param voRow             ビュー行インスタンス
   * @param objectName        オブジェクト名
   *****************************************************************************
   */
  public static void checkRowSize(
    OAViewRowImpl voRow
   ,String        objectName
  )
  {
    OAApplicationModule am = (OAApplicationModule)voRow.getApplicationModule();
    if ( am == null )
    {
      throw XxcsoMessage.createInstanceLostError("OAApplicationModule");
    }

    OADBTransaction txn = am.getOADBTransaction();
    String maxSize = txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    
    OAViewObjectImpl vo = (OAViewObjectImpl)voRow.getViewObject();
    if ( vo == null )
    {
      throw XxcsoMessage.createInstanceLostError("OAViewObjectImpl");
    }

    int lineCount = vo.getRowCount();

    if ( lineCount >= Integer.parseInt(maxSize) )
    {
      throw
        XxcsoMessage.createMaxRowException(
          objectName
         ,maxSize
        );
    }
  }

  /*****************************************************************************
   * アドバンステーブルリージョンへの最大行件数の設定
   * @param pageContext       画面のOAPageContext
   * @param webBean           画面のOAWebBean
   * @param reginName         リージョン名
   * @param profileOptionName プロファイルオプション名
   *****************************************************************************
   */
  public static OAException setAdvancedTableRows(
    OAPageContext pageContext
    ,OAWebBean    webBean
    ,String       reginName
    ,String       profileOptionName
    )
  {
    OAException oae = null;

    String lineNumStr = pageContext.getProfile(profileOptionName);
    if ( lineNumStr == null || "".equals(lineNumStr.trim()) )
    {
      oae = XxcsoMessage.createProfileNotFoundError(profileOptionName);
      return oae;
    }

    int lineNum = 0;
    try
    {
      lineNum = Integer.parseInt(lineNumStr);
    }
    catch ( NumberFormatException nfe )
    {
      oae =
        XxcsoMessage.createProfileOptionValueError(
          profileOptionName
          ,lineNumStr
        );
      return oae;
    }

    OAAdvancedTableBean advTbl
      = (OAAdvancedTableBean) webBean.findChildRecursive(reginName);
    advTbl.setNumberOfRowsDisplayed(lineNum);

    return oae;
  }

  /*****************************************************************************
   * 異常系ログ書き込み
   * @param logger            OADBTransaction/OAPageContextインスタンス
   * @param exception         Exceptionインスタンス/Stringメッセージ
   *****************************************************************************
   */
  public static void unexpected(Object logger, Object exception)
  {
    Throwable t = new Throwable();
    StackTraceElement[] e = t.getStackTrace();

    StringBuffer sb = new StringBuffer();
    sb.append(e[2].toString());

    if ( logger instanceof OAPageContext )
    {
      ((OAPageContext)logger).writeDiagnostics(
        sb.toString()
       ,exception.toString()
       ,OAFwkConstants.UNEXPECTED
      );
    }

    if ( logger instanceof OADBTransaction )
    {
      ((OADBTransaction)logger).writeDiagnostics(
        sb.toString()
       ,exception.toString()
       ,OAFwkConstants.UNEXPECTED
      );
    }
  }

  /*****************************************************************************
   * デバッグ文（Object型）
   * @param context           OAPageContextインスタンス
   * @param obj               デバッグ文
   *****************************************************************************
   */
  public static void debug(OAPageContext context, Object  obj)
  {
    if ( context.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(context, obj);
    }
  }

  /*****************************************************************************
   * デバッグ文（Object型）
   * @param txn               OADBTransactionインスタンス
   * @param obj               デバッグ文
   *****************************************************************************
   */
  public static void debug(OADBTransaction txn, Object  obj)
  {
    if ( txn.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(txn, obj);
    }
  }

  /*****************************************************************************
   * デバッグ文（int型）
   * @param context           OAPageContextインスタンス
   * @param i                 デバッグ文
   *****************************************************************************
   */
  public static void debug(OAPageContext context, int  i)
  {
    if ( context.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(context, String.valueOf(i));
    }
  }

  /*****************************************************************************
   * デバッグ文（Object型）
   * @param txn               OADBTransactionインスタンス
   * @param i                 デバッグ文
   *****************************************************************************
   */
  public static void debug(OADBTransaction txn, int  i)
  {
    if ( txn.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(txn, String.valueOf(i));
    }
  }

  /*****************************************************************************
   * デバッグ文（Object型）
   * @param context           OAPageContextインスタンス
   * @param b                 デバッグ文
   *****************************************************************************
   */
  public static void debug(OAPageContext context, boolean  b)
  {
    if ( context.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(context, String.valueOf(b));
    }
  }

  /*****************************************************************************
   * デバッグ文（Object型）
   * @param txn               OADBTransactionインスタンス
   * @param b                 デバッグ文
   *****************************************************************************
   */
  public static void debug(OADBTransaction txn, boolean  b)
  {
    if ( txn.isLoggingEnabled(DEBUG_LEVEL) )
    {
      print(txn, String.valueOf(b));
    }
  }

  /*****************************************************************************
   * URLパラメータ取得
   * @param pageContext       OAPageContextインスタンス
   * @param name              パラメータ名
   *****************************************************************************
   */
  public static String getUrlParameter(OAPageContext pageContext, String name)
  {
    String searchStatement = "&" + name + "=";
    String url = pageContext.getCurrentUrl();
    int index = url.indexOf(searchStatement);
    if ( index < 0 )
    {
      return null;
    }
    String valueStatement = url.substring(index + searchStatement.length());
    int nextIndex = valueStatement.indexOf("&");
    if ( nextIndex < 0 )
    {
      return valueStatement;
    }
    String value = valueStatement.substring(0, nextIndex);
    return value;
  }
  
  /*****************************************************************************
   * デバッグ出力
   * @param logger            OADBTransaction/OAPageContext
   * @param obj               デバッグ文
   *****************************************************************************
   */
  private static void print(Object logger, Object obj)
  {
    Throwable t = new Throwable();
    StackTraceElement[] e = t.getStackTrace();

    StringBuffer sb = new StringBuffer();
    sb.append(e[2].getClassName());
    sb.append(".");
    sb.append(e[2].getMethodName());
    sb.append("()");
    sb.append(" [");
    sb.append(e[2].getLineNumber());
    sb.append("]");

    String msg = null;
    
    if ( obj != null )
    {
      msg = obj.toString();
    }
    else
    {
      msg = "null";
    }

    if ( logger instanceof OADBTransaction )
    {
      ((OADBTransaction)logger).writeDiagnostics(
          sb.toString()
         ,msg
         ,DEBUG_LEVEL
      );
    }

    if ( logger instanceof OAPageContext )
    {
      ((OAPageContext)logger).writeDiagnostics(
          sb.toString()
         ,msg
         ,DEBUG_LEVEL
      );
    }
  }
}