/*============================================================================
* ファイル名 : XxcsoSalesPlanOutCO
* 概要説明   : 売上計画出力コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-12 1.0  SCS丸山美緒  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.webui;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/*******************************************************************************
 * 売上計画出力画面のコントローラクラスです。
 * @author  SCS丸山美緒
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanOutCO extends OAControllerImpl
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
    XxcsoUtils.debug(pageContext, "[START]");

    super.processRequest(pageContext, webBean);

    // お決まり
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }
    // 初期表示処理実行
    am.invokeMethod("initDetails");

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * 画面イベントの処理を行います。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");
    
    super.processFormRequest(pageContext, webBean);

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // ********************************
    // *****ボタン押下ハンドリング*****
    // ********************************
    // 「戻る」ボタン
    if ( pageContext.getParameter("BackButton") != null )
    {
      // メニュー画面へ遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,null
        ,true
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    // 「進む」ボタン
    if ( pageContext.getParameter("CsvCreateButton") != null )
    {

      am.invokeMethod("handleCsvCreateButton");

      OAException msg = (OAException)am.invokeMethod("getMessage");
      pageContext.putDialogMessage(msg);

    }
    
    XxcsoUtils.debug(pageContext, "[END]");
  }
}
