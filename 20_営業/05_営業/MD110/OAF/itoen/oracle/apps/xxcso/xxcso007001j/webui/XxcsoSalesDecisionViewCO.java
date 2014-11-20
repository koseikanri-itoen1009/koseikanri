/*============================================================================
* ファイル名 : XxcsoSalesDecisionViewCO
* 概要説明   : 商談決定情報表示コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-08 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007001j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * 商談決定情報表示画面のコントローラクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesDecisionViewCO extends OAControllerImpl
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

    // URLからパラメータを取得します。
    String leadId = pageContext.getParameter("ASNReqFrmOpptyId");
    if(leadId == null || "".equals(leadId))
        leadId = pageContext.getParameter("PRPObjectId");
    if(leadId == null)
    {
      leadId = (String)pageContext.getTransactionValue("ASNTxnOppId");
    }
    
    XxcsoUtils.debug(pageContext, "lead_id = " + leadId);
    if (leadId == null || "".equals(leadId))
    {
      XxcsoUtils.debug(pageContext, "Transaction key not exist");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // AMへ渡す引数を作成します。
    Serializable[] params =
    {
      leadId
    };

    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    
    // 第一引数に設定したメソッド名のメソッドをCallします。
    am.invokeMethod("initDetails", params);

    OAException error
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"XxcsoSalesDecisionAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_007_A01_01"
        );

    if ( error != null )
    {
      pageContext.putDialogMessage(error);
      OAWebBean bean = null;
      bean = webBean.findChildRecursive("MainSlRN");
      bean.setRendered(false);
    }

    // ページ間メッセージ表示
    XxcsoUtils.showDialogMessage(pageContext);

    OAMessageTextInputBean bean = null;
    bean
      = (OAMessageTextInputBean)
          webBean.findChildRecursive("XxcsoOtherContent");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
    bean
      = (OAMessageTextInputBean)
          webBean.findChildRecursive("XxcsoIntroduceTerms");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);

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

    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    if ( pageContext.getParameter("XxcsoForwardButton") != null )
    {
      HashMap params = (HashMap)am.invokeMethod("handleForwardButton");
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SALES_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }
}
