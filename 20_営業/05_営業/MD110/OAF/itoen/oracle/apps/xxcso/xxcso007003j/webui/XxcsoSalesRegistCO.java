/*============================================================================
* ファイル名 : XxcsoSalesRegistCO
* 概要説明   : 商談決定情報入力コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso007003j.util.XxcsoSalesRegistConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

/*******************************************************************************
 * 商談決定情報入力画面のコントローラクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRegistCO extends OAControllerImpl
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

    // 登録系お決まり
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.debug(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URLからパラメータを取得します。
    String leadId = pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
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

    ArrayList errorList = new ArrayList();
    OAException error = null;
    
    error
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"SalesDecisionInfoAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_007_A03_01"
        );

    if ( error != null )
    {
      errorList.add(error);
    }
    
    error
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"NotifyListAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_007_A03_02"
        );

    if ( error != null )
    {
      errorList.add(error);
    }

    if ( errorList.size() > 0 )
    {
      error = OAException.getBundledOAException(errorList);
      pageContext.putDialogMessage(error);
      OAWebBean bean = null;
      bean = webBean.findChildRecursive("MainSlRN");
      bean.setRendered(false);
      bean = webBean.findChildRecursive("SubmitButton");
      bean.setRendered(false);
    }
    
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

    if ( pageContext.getParameter("AddRowButton") != null )
    {
      am.invokeMethod("handleAddRowButton");
    }

    if ( "SalesClassChange".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
       )
    {
      String lineId = pageContext.getParameter("SelectedLineId");
      Serializable[] params =
      {
        lineId
      };
      
      am.invokeMethod("handleSalesClassChangeEvent", params);
    }

    if ( "DeleteIconClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
       )
    {
      String lineId = pageContext.getParameter("SelectedLineId");
      Serializable[] params =
      {
        lineId
      };
      
      am.invokeMethod("handleDeleteIconClickEvent", params);
    }

    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");
      
      HashMap params = new HashMap(1);
      params.put(
        XxcsoSalesRegistConstants.RETURN_URL_PARAM
       ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1)
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.ASN_OPPTYDETPG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,XxcsoConstants.ASN_MAIN_MENU
       ,params
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("SubmitButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleSubmitButton");

      HashMap params = new HashMap(1);
      params.put(
        XxcsoSalesRegistConstants.RETURN_URL_PARAM
       ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1)
      );
      
      // メッセージ設定
      XxcsoUtils.setDialogMessage(pageContext, msg);

      pageContext.setForwardURL(
        XxcsoConstants.ASN_OPPTYDETPG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,XxcsoConstants.ASN_MAIN_MENU
       ,params
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
       ,OAException.CONFIRMATION
      );
    }

    if ( pageContext.getParameter("RequestButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleRequestButton");

      HashMap params = new HashMap(1);
      params.put(
        XxcsoSalesRegistConstants.RETURN_URL_PARAM
       ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1)
      );
      
      // メッセージ設定
      XxcsoUtils.setDialogMessage(pageContext, msg);

      pageContext.setForwardURL(
        XxcsoConstants.ASN_OPPTYDETPG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,XxcsoConstants.ASN_MAIN_MENU
       ,params
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
       ,OAException.CONFIRMATION
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }
}
