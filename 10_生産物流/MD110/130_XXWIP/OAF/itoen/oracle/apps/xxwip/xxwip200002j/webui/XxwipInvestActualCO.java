/*============================================================================
* ファイル名 : XxwipInvestActualCO
* 概要説明   : 投入実績入力コントローラ
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-22 1.0  二瓶大輔     新規作成
* 2008-09-10 1.1  二瓶大輔     結合テスト指摘対応No30
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;

import java.io.Serializable;

import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
/***************************************************************************
 * 投入実績入力コントローラクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.1
 ***************************************************************************
 */
public class XxwipInvestActualCO extends XxcmnOAControllerImpl
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
// 2008/09/10 v1.1 D.Nihei Add Start
      if (pageContext.getParameter("InstClearYes") != null) 
      {
        // パラメータ取得
        String batchId       = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_BATCH_ID);
        String mtlDtlId      = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ID);
        String mtlDtlAddonId = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ADDON_ID);
        String transId       = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_TRANS_ID);

        // 引数設定
        Serializable params[] = { batchId, mtlDtlId, mtlDtlAddonId, transId };
        // AMの取得
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        // 初期化・検索処理
        am.invokeMethod("cancelAllocation", params);
        
        MessageToken[] mainTokens = new MessageToken[1];
        throw new OAException(XxcmnConstants.APPL_XXWIP,
                              XxwipConstants.XXWIP30011, 
                              null, 
                              OAException.INFORMATION, 
                              null);

      }
// 2008/09/10 v1.1 D.Nihei Add End
      // 【共通処理】「戻る」ボタンチェック
      TransactionUnitHelper.startTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
      // タブを取得
      OASubTabLayoutBean subTabLayout = (OASubTabLayoutBean)webBean.findChildRecursive("LotSubTab");
      if (!subTabLayout.isSubTabClicked(pageContext) &&
          (pageContext.getParameter(XxwipConstants.CHANGE_INVEST_BTN) == null &&
           pageContext.getParameter(XxwipConstants.CHANGE_RE_INVEST_BTN) == null) &&
           pageContext.getParameter(XxwipConstants.GO_BTN) == null)  
      {
        // AMの取得
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        // 検索条件取得
        String searchBatchId  = pageContext.getParameter(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID);
        String searchMtlDtlId = pageContext.getParameter(XxwipConstants.URL_PARAM_SEARCH_MTL_DTL_ID);

        // 引数設定
        Serializable params[] = { searchBatchId, searchMtlDtlId };
        // 初期化・検索処理
        am.invokeMethod("initialize", params);
      }
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwipConstants.TXN_XXWIP200002J, true))
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
      if (pageContext.getParameter(XxwipConstants.CANCEL_BTN) != null) 
      {
        String batchId = (String)pageContext.getParameter("BatchId");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId);
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
        // 前画面遷移
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // 適用ボタン押下された場合
      } else if (pageContext.getParameter(XxwipConstants.GO_BTN) != null) 
      {
        // タブを取得
        OASubTabLayoutBean subTabLayout = (OASubTabLayoutBean)webBean.findChildRecursive("LotSubTab");
        String tabType = String.valueOf(subTabLayout.getSelectedIndex(pageContext));
        String searchBatchId  = (String)pageContext.getParameter("BatchId");
        String searchMtlDtlId = null;
        if (XxcmnUtility.isBlankOrNull(tabType) || XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
        {
          searchMtlDtlId = pageContext.getParameter("InvestMtlDtlId");
        } else
        {
          searchMtlDtlId = pageContext.getParameter("ReInvestMtlDtlId");       
        }
        // 引数設定
        Serializable params[] = { tabType };
        // 変更処理
        String exeType = (String)am.invokeMethod("apply", params);
        // 正常終了の場合
        if (XxcmnConstants.RETURN_SUCCESS.equals(exeType)) 
        {
          // 【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
          // 引数設定
          Serializable param[] = { searchBatchId, searchMtlDtlId, tabType };
          am.invokeMethod("doCommit", param);          
        } else
        {
          // 【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
          am.invokeMethod("doRollBack");
        }

      // 投入情報タブの進むボタンが押下された場合
      } else if (pageContext.getParameter(XxwipConstants.CHANGE_INVEST_BTN) != null) 
      {
        String searchMtlDtlId = pageContext.getParameter("InvestMtlDtlId");
        // タブを設定
        String tabType = XxwipConstants.TAB_TYPE_INVEST;
        // 引数設定
        Serializable params[] = { searchMtlDtlId, tabType };
        // 変更処理
        am.invokeMethod("doChange", params);

      // 打込情報タブの進むボタンが押下された場合
      } else if (pageContext.getParameter(XxwipConstants.CHANGE_RE_INVEST_BTN) != null) 
      {
        String searchMtlDtlId = pageContext.getParameter("ReInvestMtlDtlId");
        // タブを設定
        String tabType = XxwipConstants.TAB_TYPE_REINVEST;
        // 引数設定
        Serializable params[] = { searchMtlDtlId, tabType };
        // 変更処理
        am.invokeMethod("doChange", params);
// 2008/09/10 v1.1 D.Nihei Add Start
      // 引当解除アイコンが押下された場合
      } else if ("InvestInstClear".equals(pageContext.getParameter(EVENT_PARAM))
              || "ReInvestInstClear".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // パラメータ取得
        String batchId       = pageContext.getParameter("BATCH_ID");
        String mtlDtlId      = pageContext.getParameter("MTL_DTL_ID");
        String mtlDtlAddonId = pageContext.getParameter("MTL_DTL_ADDON_ID");
        String transId       = pageContext.getParameter("TRANS_ID");

        //パラメータ用HashMap生成
        Hashtable pageParams = new Hashtable();
        pageParams.put(XxwipConstants.URL_PARAM_CAN_BATCH_ID,         batchId);
        pageParams.put(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ID,       mtlDtlId);
        pageParams.put(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ADDON_ID, mtlDtlAddonId);
        pageParams.put(XxwipConstants.URL_PARAM_CAN_TRANS_ID,         transId);
        // メインメッセージ作成 
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXWIP,
                                                  XxwipConstants.XXWIP40002);
                                            
        // ダイアログメッセージを表示
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxwipConstants.URL_XXWIP200002J,
          XxwipConstants.URL_XXWIP200002J,
          "Yes",
          "No",
          "InstClearYes",
          "InstClearNo",
          pageParams);          
// 2008/09/10 v1.1 D.Nihei Add End
      }

    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
