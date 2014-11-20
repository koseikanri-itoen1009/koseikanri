/*============================================================================
* ファイル名 : XxccpOAControllerImpl
* 概要説明   : 共通コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxccp.util.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * 共通コントローラクラスです。
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpOAControllerImpl extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);    
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
  }

  public void initializeMessages(OAPageContext pageContext, OAException oae)
  {
    // 蓄積メッセージをクリアし、新しいメッセージを残す為、自画面遷移を行う。
    pageContext.putDialogMessage(oae);
    pageContext.forwardImmediatelyToCurrentPage(
      null,
      true,
      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
  }
}
