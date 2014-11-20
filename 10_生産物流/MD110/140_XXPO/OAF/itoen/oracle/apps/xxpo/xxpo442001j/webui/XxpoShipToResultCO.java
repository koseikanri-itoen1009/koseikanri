/*============================================================================
* ファイル名 : XxpoShipToResultCO
* 概要説明   : 入庫実績要約コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  新藤義勝     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
/***************************************************************************
 * 入庫実績要約画面のコントローラクラスです。
 * @author  ORACLE 新藤 義勝
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShipToResultCO extends XxcmnOAControllerImpl
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
      // 通知ステータス項目制御
      OAMessageChoiceBean notifChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShNotifStatus");
      notifChoiceBean.setDisabled(true);

      // 起動タイプ取得
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // 起動タイプが「32：パッカー･外注工場用」の場合
      if (XxpoConstants.EXE_TYPE_32.equals(exeType)) 
      {
        // 入力不可設定(取引先)
        OAMessageLovInputBean vendorLovInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShVendorCode");
        vendorLovInputBean.setReadOnly(true);

      }

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 引数設定
      Serializable param[] = { exeType }; 
      // 初期化処理実行
      am.invokeMethod("initializeList",param);
      
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO442001J, true))
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

      // 進むボタン押下された場合
      if (pageContext.getParameter("Go") != null) 
      {
        // 検索処理実行
        // 起動タイプ取得
        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
        // 引数設定
        Serializable param[] = { exeType };
        am.invokeMethod("doSearchList", param);

      // ページング処理が行われた場合
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");

      // 消去ボタン押下された場合
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
          
        // 起動タイプ取得
        String exeType = pageContext.getParameter("ExeType");
        // パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);   

      // 全数入庫ボタン押下された場合    
      } else if (pageContext.getParameter("Decision") != null)
      {
        // 未選択チェック
        am.invokeMethod("chkBeforeDecision");
        // ダイアログメッセージを表示
        // メインメッセージ作成
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO
                                                   ,XxpoConstants.XXPO40033);
          // ダイアログ生成
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxpoConstants.URL_XXPO442001J,
            XxpoConstants.URL_XXPO442001J,
            "Yes",
            "No",
            "decisionYesBtn",
            "decisionNoBtn",
            null);
            
        // 全数入庫Yesボタンが押下された場合
      } else if (pageContext.getParameter("decisionYesBtn") != null) 
      {  
        // 起動タイプ取得
        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
        // 引数設定
        Serializable param[] = { exeType };
        // 全数入庫処理実行
        am.invokeMethod("doDecisionList",param);
        
      // 依頼Noリンクを押下された場合
      } else if ("RequestHeaderLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // 起動タイプ取得
        String exeType = pageContext.getParameter("ExeType");
        // 依頼No取得
        String reqNo   = pageContext.getParameter("REQ_NO");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ 
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);   // 依頼No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO442001J);   // 次画面のURL
        // 入庫実績入力ヘッダ画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}


