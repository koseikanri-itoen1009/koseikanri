/*============================================================================
* ファイル名 : XxpoProvisionRtnSummaryCO
* 概要説明   : 支給返品要約:検索コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-17 1.0  熊本 和郎    新規作成
* 2008-06-06 1.0  二瓶 大輔    内部変更要求#137対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

/***************************************************************************
 * 支給返品要約:検索コントローラクラスです。
 * @author  ORACLE 熊本 和郎
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnSummaryCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

      // 入力不可設定(配送No)
      OAMessageTextInputBean shipToNoTextInputBean = (OAMessageTextInputBean)webBean.findChildRecursive("ShShipToNo");
      shipToNoTextInputBean.setDisabled(true);

      // 入力不可設定(入庫日From)
      OAMessageDateFieldBean  arvlDateFromTextInputBean = (OAMessageDateFieldBean )webBean.findChildRecursive("ShArvlDateFrom");
      arvlDateFromTextInputBean.setDisabled(true);

      // 入力不可設定(入庫日To)
      OAMessageDateFieldBean arvlDateToTextInputBean = (OAMessageDateFieldBean)webBean.findChildRecursive("ShArvlDateTo");
      arvlDateToTextInputBean.setDisabled(true);

      // 入力不可設定(通知ステータス)
      OAMessageChoiceBean notifStatusChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShNotifStatus");
      notifStatusChoiceBean.setDisabled(true);

      // 入力不可設定(指示部署コード)
      OAMessageLovInputBean instDeptCodeLovInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShInstDeptCode");
      instDeptCodeLovInputBean.setDisabled(true);

      // ポップリストのVO変更(発生区分)
      OAMessageChoiceBean orderTypeChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShOrderType");
      orderTypeChoiceBean.setPickListViewUsageName("OrderType2VO1");

      // ポップリストのVO変更(ステータス)
      OAMessageChoiceBean transStatusChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShTransStatus");
      transStatusChoiceBean.setPickListViewUsageName("TransStatus2VO1");

      // 起動タイプ取得
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // 引数設定
      Serializable param[] = { exeType };
      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 初期化処理実行
      am.invokeMethod("initializeList", param);
      // 完了メッセージ取得
      String cancelMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_CAN_MESSAGE);
      // 完了メッセージが存在する場合
      if (!XxcmnUtility.isBlankOrNull(cancelMessage))
      {
        // メッセージボックス表示
        pageContext.putDialogMessage(new OAException(cancelMessage, OAException.INFORMATION));
      }

    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO443001J, true))
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
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);

      // 進むボタン押下時の処理
      if (pageContext.getParameter("Go") != null)
      {
        // 検索処理実行
        am.invokeMethod("doSearchList");

      // ページング処理が行われた場合
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");        

      // 消去ボタン押下時の処理
      } else if (pageContext.getParameter("Delete") != null)
      {
        //【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

        // パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  //起動タイプ
        pageParams.put(XxpoConstants.URL_PARAM_CAN_MESSAGE, null); // メッセージ初期化

        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES
        );

      // 金額確定ボタン押下時の処理
      } else if (pageContext.getParameter("AmountFix") != null)
      {
        // 金額確定処理実行
        am.invokeMethod("doAmountFixList");

      // 新規ボタン押下時の処理
      } else if (pageContext.getParameter("New") != null)
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

        // パラメータ用HashMap生成
        HashMap pageParams = new HashMap();

        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // 起動タイプ
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO443001J);  // 次画面のURL

        // 支給返品作成画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false,   // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES
        );

      // 依頼Noリンク押下時の処理
      } else if ("RequestNoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
        // 依頼No取得
        String reqNo = pageContext.getParameter("REQ_NO");
        // パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // 起動タイプ
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO, reqNo);      // 依頼No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO443001J);  // 次画面URL

        // 支給返品作成画面ヘッダへ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true,   // RetainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES
        );
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
