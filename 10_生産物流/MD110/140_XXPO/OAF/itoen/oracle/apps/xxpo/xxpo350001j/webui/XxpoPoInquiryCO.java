/*============================================================================
* ファイル名 : XxpoPoInquiryCO
* 概要説明   : 発注・受入照会画面:コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.webui;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/***************************************************************************
 * 発注・受入照会画面コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquiryCO extends XxcmnOAControllerImpl
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
        // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下していない場合
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // **************************** //
      // * サブタブリンククリック時 *
      // **************************** //
      if ("Line01Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line02Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line03Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line04Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line05Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line06Link".equals(pageContext.getParameter(EVENT_PARAM))
          )
      {
        // 処理を行わない。

      // ****************** //
      // *  エラー発生時  * //
      // ****************** //
      } else if (pageContext.getParameter("OrderApproving") != null) 
      {
        // 発注承諾ボタン押下時は処理は行わずに、再表示。
      
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // 仕入承諾ボタン押下時は処理は行わずに、再表示。

      // ****************** //
      // *  初期表示処理  * //
      // ****************** //
      } else
      {
        // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
        TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
      
        // 初期化処理実行
        am.invokeMethod("initialize2");

        // 検索処理
        String searchHeaderId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID); // 発注ヘッダID
        Serializable params[] = { searchHeaderId };
        am.invokeMethod("doSearch", params);
      }

      
    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO350001J, true))
      { 
        // 【共通処理】エラーダイアログ画面へ遷移
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
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
    try
    {
      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      
      // ************************* //
      // *   取消ボタン押下時    * //
      // ************************* //
      if (pageContext.getParameter("Reset") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
        
        // 発注確認画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO350001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);
      
      // ************************** //
      // *  発注承諾ボタン押下時  * //
      // ************************** //
      } else if (pageContext.getParameter("OrderApproving") != null) 
      {
        // 更新前チェック
        am.invokeMethod("doUpdateCheck2"); 

        // 発注承認処理
        am.invokeMethod("doOrderApproving2");       

        // 初期化処理実行
        am.invokeMethod("initialize2");

        // 検索処理
        String searchHeaderId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID); // 発注ヘッダID
        Serializable params[] = { searchHeaderId };
        am.invokeMethod("doSearch", params);
        
        // 更新完了メッセージ
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);

      // ************************** //
      // *  仕入承諾ボタン押下時  * //
      // ************************** //
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // 更新前チェック
        am.invokeMethod("doUpdateCheck2"); 

        // 仕入承認処理
        am.invokeMethod("doPurchaseApproving2"); 

        // 初期化処理実行
        am.invokeMethod("initialize2");

        // 検索処理
        String searchHeaderId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID); // 発注ヘッダID
        Serializable params[] = { searchHeaderId };
        am.invokeMethod("doSearch", params);
        
        // 更新完了メッセージ
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);
      }

    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
