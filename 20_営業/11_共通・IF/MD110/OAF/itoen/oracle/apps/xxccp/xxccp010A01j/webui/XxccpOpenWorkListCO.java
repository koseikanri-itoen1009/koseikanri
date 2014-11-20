/*============================================================================
* ファイル名 : XxccpOpenWorkListCO
* 概要説明   : オープンワークリストコントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

/*******************************************************************************
 * オープンワークリスト（ポータルホームページ画面）のコントローラクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxccpOpenWorkListCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * 画面起動時の処理を行います。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    pageContext.putParameter("WFEBizWorklist", "Y");

    String userName = pageContext.getUserName();
    Serializable[] params =
    {
      userName
    };

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    am.invokeMethod("initDetails", params);
  }

  /*****************************************************************************
   * 画面イベントの処理を行います。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    if ( pageContext.getParameter("XxccpSalesAllListButton") != null )
    {
      // 職責切替
      pageContext.changeResponsibility("XXCCP_SALES_WORK_LIST","ICX");

      // 画面遷移
      pageContext.forwardImmediately(
        "XXCCP010A01J"
       ,OAWebBeanConstants.RESET_MENU_CONTEXT
       ,"XXCCP_SALES_WORK_LIST"
       ,null
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
      );
    }
  }

}
