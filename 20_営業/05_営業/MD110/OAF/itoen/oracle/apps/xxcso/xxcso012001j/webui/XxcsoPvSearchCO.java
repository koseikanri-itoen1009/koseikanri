/*============================================================================
* ファイル名 : XxcsoPvRegistCO
* 概要説明   : パーソナライズビュー表示画面コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonUtils;

import java.io.Serializable;
import java.util.Hashtable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;


/*******************************************************************************
 * パーソナライズビュー作成画面のコントローラクラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvSearchCO extends OAControllerImpl
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

    XxcsoUtils.debug(pageContext, "[START]");
    // 登録系お決まり
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

    // URLからパラメータを取得します。
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    Serializable[] params = { viewId };

    // 初期表示処理実行
    am.invokeMethod("initDetails" , params);

    // ****************************************
    // *****プロファイル・オプションの設定*****
    // ****************************************
    boolean errorMode = false;

    // **FND: ビュー・オブジェクト最大フェッチ・サイズの設定
    OAException oaeMsg =
      XxcsoUtils.setAdvancedTableRows(
        pageContext
       ,webBean
       ,XxcsoPvCommonConstants.SELECT_VIEW_ADV_TBL_RN
       ,XxcsoConstants.VO_MAX_FETCH_SIZE
      );

    if (oaeMsg != null)
    {
      pageContext.putDialogMessage(oaeMsg);
      errorMode = true;
    }

    if ( errorMode )
    {
      webBean.findChildRecursive("ApplicationButton").setRendered(false);
      webBean.findChildRecursive("MainSlRN").setRendered(false);
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
    super.processFormRequest(pageContext, webBean);

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // 汎用検索表示区分
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);

    // ********************************
    // *****ボタン押下ハンドリング*****
    // ********************************
    // 「取消」ボタン
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // 物件情報汎用検索画面へ遷移
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // 「適用」ボタン
    if ( pageContext.getParameter("ApplicationButton") != null )
    {
      am.invokeMethod("handleApplicationButton");

      // メッセージの取得
      OAException msg = (OAException)am.invokeMethod("getMessage");
      // 遷移先画面へのメッセージの設定
      XxcsoUtils.setDialogMessage(pageContext, msg);

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // 物件情報汎用検索画面へ遷移
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // 「複製」ボタン
    if ( pageContext.getParameter("CopyButton") != null )
    {
      // 複製時のパラメータはAMより取得する
      HashMap retMap = (HashMap) am.invokeMethod("handleCopyButton");

      // メッセージ
      OAException msg = (OAException)am.invokeMethod("getMessage");
      if (msg != null)
      {
        pageContext.putDialogMessage(msg);
      }
      else
      {
        // URLパラメータの作成
        HashMap paramMap
          = XxcsoPvCommonUtils.createParam(
              (String) retMap.get(XxcsoPvCommonConstants.KEY_EXEC_MODE)
             ,pvDisplayMode
             ,(String) retMap.get(XxcsoPvCommonConstants.KEY_VIEW_ID)
            );

        // パーソナライズビュー作成画面へ遷移
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_PV_REGIST_PG
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,paramMap
         ,false
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }

    // 「ビューの作成」ボタン
    if ( pageContext.getParameter("CreateViewButton") != null )
    {
      am.invokeMethod("handleCreateViewButton");

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_CREATE, pvDisplayMode, "");

      // パーソナライズビュー作成画面へ遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // ********************************
    // *****Icon(image)押下ハンドリング
    // ********************************
    // 更新アイコン
    if ( "UpdateIconClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
    )
    {
      String viewId = pageContext.getParameter("SelectedViewId");

      am.invokeMethod("handleUpdateIconClick");

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_UPDATE
           ,pvDisplayMode
           ,viewId
          );

      // パーソナライズビュー作成画面へ遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_REGIST_PG
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,paramMap
        ,false
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // 削除アイコン
    if ( "DeleteIconClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
    )
    {
      String viewId = pageContext.getParameter("SelectedViewId");
      String viewName = pageContext.getParameter("SelectedViewName");

      // 削除確認ダイアログを生成
      OAException mainMsg
        = XxcsoMessage.createDeleteWarningMessage(
            XxcsoPvCommonConstants.MSG_VIEW_NAME
           ,viewName
          );
      OADialogPage deleteDialog
        = new OADialogPage(
            OAException.WARNING
           ,mainMsg
           ,null
           ,""
           ,""
          );
          
      String yes = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
      String no  = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

      deleteDialog.setOkButtonItemName("DeleteYesButton");
      deleteDialog.setOkButtonToPost(true);
      deleteDialog.setNoButtonToPost(true);
      deleteDialog.setPostToCallingPage(true);
      deleteDialog.setOkButtonLabel(yes);
      deleteDialog.setNoButtonLabel(no);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoPvCommonConstants.KEY_VIEW_ID, viewId);
      param.put(XxcsoPvCommonConstants.KEY_VIEW_NAME, viewName);

      deleteDialog.setFormParameters(param);

      pageContext.redirectToDialogPage(deleteDialog);
    }

    // 削除確認画面でのOKボタン押下
    if ( pageContext.getParameter("DeleteYesButton") != null )
    {
      String viewId
        = pageContext.getParameter(XxcsoPvCommonConstants.KEY_VIEW_ID);
      String viewName
        = pageContext.getParameter(XxcsoPvCommonConstants.KEY_VIEW_NAME);

      // AMへのパラメータ作成
      Serializable[] params    = { viewId, pvDisplayMode};
      am.invokeMethod("handleDeleteYesButton", params);

      // メッセージ
      OAException msg = (OAException)am.invokeMethod("getMessage");
      pageContext.putDialogMessage(msg);

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // パーソナライズビュー表示画面へ遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }
  }
}
