/*============================================================================
* ファイル名 : XxpoProvisionRequestCO
* 概要説明   : 支給依頼要約コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  二瓶大輔     新規作成
* 2008-06-06 1.0  二瓶 大輔    内部変更要求#137対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
/***************************************************************************
 * 支給依頼要約画面のコントローラクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRequestCO extends XxcmnOAControllerImpl
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

    // 【共通処理】「戻る」ボタンチェック
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // 起動タイプ取得
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      
      // 起動タイプが「12：パッカー･外注工場用」の場合
      if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
      {
        // 入力不可設定(取引先)
        OAMessageLovInputBean vendorLovInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShVendorCode");
        vendorLovInputBean.setReadOnly(true);

      }
      // 引数設定
      Serializable param[] = { exeType };
      // 初期化処理実行
      am.invokeMethod("initializeList", param);
      // 支給取消完了メッセージ取得
      String mainMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_CAN_MESSAGE);
      // 支給取消完了メッセージが存在する場合
      if (!XxcmnUtility.isBlankOrNull(mainMessage))
      {
        // メッセージボックス表示
        pageContext.putDialogMessage(new OAException(mainMessage, OAException.INFORMATION));

      }
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO440001J, true))
      { 
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
    try
    {
      super.processFormRequest(pageContext, webBean);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 起動タイプ取得
      String exeType = pageContext.getParameter("ExeType");

      // 進むボタン押下された場合
      if (pageContext.getParameter("Go") != null) 
      {
        // 検索処理実行
        am.invokeMethod("doSearchList");

      // 消去ボタン押下された場合
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);
          
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ
        pageParams.put(XxpoConstants.URL_PARAM_CAN_MESSAGE, null); // メッセージ初期化

        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // 確定ボタン押下された場合
      } else if (pageContext.getParameter("Fix") != null) 
      {
        // 確定処理実行
        am.invokeMethod("doFixList");

      // 受領ボタン押下された場合
      } else if (pageContext.getParameter("Rcv") != null) 
      {
        // 受領処理実行
        am.invokeMethod("doRcvList");

      // 手動指示確定ボタン押下された場合
      } else if (pageContext.getParameter("ManualFix") != null) 
      {
        // 手動指示確定処理実行
        am.invokeMethod("doManualFixList");

      // 価格設定ボタン押下された場合
      } else if (pageContext.getParameter("PriceSet") != null) 
      {
        // 価格設定処理実行
        am.invokeMethod("doPriceSetList");

      // 金額確定ボタン押下された場合
      } else if (pageContext.getParameter("AmountFix") != null) 
      {
        // 金額確定処理実行
        am.invokeMethod("doAmountFixList");

      // 依頼Noリンク押下された場合
      } else if ("ReqestNoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);

        // 依頼No取得
        String reqNo   = pageContext.getParameter("REQ_NO");

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ 
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);   // 依頼No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO440001J);   // 次画面のURL

        // 支給指示作成画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // 新規ボタン押下された場合
      } else if (pageContext.getParameter("New") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO440001J);   // 次画面のURL

        // 支給指示作成画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // ページング処理が行われた場合
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
