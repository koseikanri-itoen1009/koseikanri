/*============================================================================
* ファイル名 : XxpoPoConfirmCO
* 概要説明   : 発注確認画面:検索コントローラ
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  伊藤ひとみ   新規作成
* 2008-05-07      伊藤ひとみ   内部変更要求対応(#41,48)
* 2009-02-24 1.1  二瓶　大輔   本番障害#6対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * 発注確認画面:検索コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.1
 ***************************************************************************
 */
public class XxpoPoConfirmCO extends XxcmnOAControllerImpl
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

      // ****************** //
      // *  エラー発生時  * //
      // ****************** //
      if (pageContext.getParameter("OrderApproving") != null) 
      {
        // 発注承諾ボタン押下時は処理は行わずに、再表示。
      
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // 仕入承諾ボタン押下時は処理は行わずに、再表示。

      // ******************************* // 
      // * 発注承諾ダイアログYes押下時 * //
      // ******************************* // 
      } else if (pageContext.getParameter("OrderApprovingYes") != null) 
      {
        // 更新前チェック
        am.invokeMethod("doUpdateCheck"); 

        // 発注承認処理
        am.invokeMethod("doOrderApproving");       

        // 初期化処理実行
        am.invokeMethod("initialize");

        // 検索項目入力必須チェック
        am.invokeMethod("doRequiredCheck"); 

        // 検索
        am.invokeMethod("doSearch");  

        // 更新完了メッセージ
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);

      // ******************************* // 
      // * 仕入承諾ダイアログYes押下時 * //
      // ******************************* // 
      } else if (pageContext.getParameter("PurchaseApprovingYes") != null) 
      {
        // 更新前チェック
        am.invokeMethod("doUpdateCheck"); 

        // 仕入承認処理
        am.invokeMethod("doPurchaseApproving"); 

        // 初期化処理実行
        am.invokeMethod("initialize");

        // 検索項目入力必須チェック
        am.invokeMethod("doRequiredCheck"); 

        // 検索
        am.invokeMethod("doSearch");  

        // 更新完了メッセージ
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);

      // ******************************* // 
      // * 発注承諾ダイアログNo押下時 * //
      // ******************************* //
      } else if (pageContext.getParameter("OrderApprovingNo") != null) 
      {
        // 発注承諾ボタン押下時は処理は行わずに、再表示。

      // ******************************* // 
      // * 仕入承諾ダイアログNo押下時 * //
      // ******************************* //
      } else if (pageContext.getParameter("PurchaseApprovingNo") != null) 
      {
        // 発注承諾ボタン押下時は処理は行わずに、再表示。

// 2008-02-24 D.Nihei Add Start 本番障害#6対応
      // *********************************** //
      // *   納入日FROMが変更された場合    * //
      // *********************************** //
      } else if ("deliveryDateFrom".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 納入日FROMが変更された場合は処理は行わずに、再表示。

// 2008-02-24 D.Nihei Add End
      // ****************** //
      // *  初期処理      * //
      // ****************** //
      } else
      {
        // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
        TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
      
        // 初期化処理実行
        am.invokeMethod("initialize");
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

    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    try
    {
      // ************************* //
      // *   進むボタン押下時    * //
      // ************************* //
      if (pageContext.getParameter("Go") != null) 
      {
        // 検索項目入力必須チェック
        am.invokeMethod("doRequiredCheck"); 

        // 検索
        am.invokeMethod("doSearch");  

      // ************************* //
      // *   削除ボタン押下時    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
        
        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO350001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // ************************** //
      // *  発注承諾ボタン押下時  * //
      // ************************** //
      } else if (pageContext.getParameter("OrderApproving") != null) 
      {
        // 選択チェック
        am.invokeMethod("doSelectCheck"); 

        // メインメッセージ作成
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO, XxpoConstants.XXPO40036);

        // ダイアログメッセージを表示
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO350001JS,
          XxpoConstants.URL_XXPO350001JS,
          "Yes",
          "No",
          "OrderApprovingYes",
          "OrderApprovingNo",
          null);

      // ************************** //
      // *  仕入承諾ボタン押下時  * //
      // ************************** //
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // 選択チェック
        am.invokeMethod("doSelectCheck"); 

        // メインメッセージ作成
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO, XxpoConstants.XXPO40035);
        
        // ダイアログメッセージを表示
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO350001JS,
          XxpoConstants.URL_XXPO350001JS,
          "Yes",
          "No",
          "PurchaseApprovingYes",
          "PurchaseApprovingNo",
          null);

      // ************************* //
      // *   リンククリック時    * //
      // ************************* //
      } else if ("HeaderNumberLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
        
        // 検索条件(ヘッダーID)取得
        String searchHeaderId = pageContext.getParameter("searchHeaderId");
        
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID,  searchHeaderId);
        pageParams.put(XxpoConstants.URL_PARAM_UPDATE_FLAG, "1");

        // 発注・受入照会画面画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO350001JI,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

// 2008-02-24 D.Nihei Add Start 本番障害#6対応
      // *********************************** //
      // *   納入日FROMが変更された場合    * //
      // *********************************** //
      } else if ("deliveryDateFrom".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // コピー処理
        am.invokeMethod("copyDeliveryDate");
// 2008-02-24 D.Nihei Add End
      // ******************* //
      // *  ページング時   * //
      // ******************* //
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 選択チェックボックスをOFFにします。
        am.invokeMethod("checkBoxOff");
      }

    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
