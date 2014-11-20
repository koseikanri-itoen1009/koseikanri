/*============================================================================
* ファイル名 : XxwipVolumeActualCO
* 概要説明   : 出来高実績入力コントローラ
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  二瓶大輔     新規作成
* 2008-05-12      二瓶大輔     変更要求対応(#75)
* 2009-01-15 1.1  二瓶大輔     本番障害#836恒久対応Ⅱ
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200001j.webui;
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
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
/***************************************************************************
 * 出来高実績入力コントローラクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.1
 ***************************************************************************
 */
public class XxwipVolumeActualCO extends XxcmnOAControllerImpl
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
      // 【共通処理】「戻る」ボタンチェック
      TransactionUnitHelper.startTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);

      // クイック検索パネルの生成
      OAPageLayoutBean pageLayout = pageContext.getPageLayoutBean();
      // quickSearchRNの生成
      OATableLayoutBean qsRN = (OATableLayoutBean)createWebBean(pageContext,
                               "/itoen/oracle/apps/xxwip/util/webui/BatchNoQuickSearchRN",
                               "QuickSearchRN",
                               true);
      // quickSearchRNの設定
      pageLayout.setQuickSearch(qsRN);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 初期化処理
      am.invokeMethod("initialize");
      // 検索バッチID
      String searchBatchId = null;
      // 検索ボタン押下された場合
      if (pageContext.getParameter(XxwipConstants.QS_SEARCH_BTN) != null) 
      {
        // 検索条件取得
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID);
        // 引数設定
        Serializable params[] = { searchBatchId };
        // 検索処理
        am.invokeMethod("doSearch", params);
      // ダイアログ画面から「Yes」が押下された場合
      } else if (pageContext.getParameter("Yes") != null) 
      {
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        // 引数設定
        Serializable param[] = { searchBatchId };
        am.invokeMethod("doCommit", param);
        // 引数設定
        Serializable params[] = { searchBatchId };
        // 検索処理
        am.invokeMethod("doSearch", params);
      // ダイアログ画面から「No」が押下された場合
      } else if (pageContext.getParameter("No") != null) 
      {
        am.invokeMethod("doRollBack");
      // 引当ダイアログ画面から「Yes」が押下された場合
      } else if (pageContext.getParameter("ReserveYes") != null) 
      {
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        // 適用処理を行います。
        apply(pageContext, webBean, am, searchBatchId);
      // 引当ダイアログ画面から「No」が押下された場合
      } else if (pageContext.getParameter("ReserveNo") != null) 
      {
        // 何もしない
// 2009-01-15 v1.1 D.Nihei Add Start 本番障害#836恒久対応Ⅱ
      // 廃止ダイアログ画面から「Yes」が押下された場合
      } else if (pageContext.getParameter("CloseYes") != null) 
      {
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        // 引数設定
        Serializable params[] = { searchBatchId };
        // 廃止処理を行います。
        am.invokeMethod("doClose");
        // メインメッセージ作成 
        MessageToken[] mainTokens = new MessageToken[1];
        mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, "該当の手配は、廃止されました。");

        throw new OAException(XxcmnConstants.APPL_XXCMN,
                                                  XxcmnConstants.XXCMN00025,
                                                  mainTokens,
                                                  OAException.INFORMATION,
                                                  null);
      // 廃止ダイアログ画面から「No」が押下された場合
      } else if (pageContext.getParameter("CloseNo") != null) 
      {
        // 何もしない
// 2009-01-15 v1.1 D.Nihei Add End
      } else if (pageContext.getParameter("LotDetailInvest") == null &&
                 pageContext.getParameter("LotDetailReInvest") == null)
      {
        // 検索条件取得
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        if (!XxcmnUtility.isBlankOrNull(searchBatchId))
        {
          // 引数設定
          Serializable params[] = { searchBatchId };
          // 検索処理
          am.invokeMethod("doSearch", params);
        }
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
      // 検索ボタン押下された場合
      if (pageContext.getParameter(XxwipConstants.QS_SEARCH_BTN) != null) 
      {
        // 検索条件取得
        String searchBatchId = pageContext.getParameter(XxwipConstants.PARAM_SC_BATCH_ID);
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID, searchBatchId);
        // 自画面遷移
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

// 2009-01-15 v1.1 D.Nihei Add Start 本番障害#836恒久対応Ⅱ
      // 廃止ボタン押下された場合
      } else if (pageContext.getParameter("Close") != null) 
      {
        // 検索条件取得
        String batchId = pageContext.getParameter(XxwipConstants.PARAM_SC_BATCH_ID);
        //パラメータ用HashMap生成
        Hashtable pageParams = new Hashtable();
        pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId.toString());
        // メインメッセージ作成 
        MessageToken[] mainTokens = new MessageToken[1];
        mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, "該当の手配を廃止します。よろしいですか？");

        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXCMN,
                                                  XxcmnConstants.XXCMN00025,
                                                  mainTokens);
                                            
        // ダイアログメッセージを表示
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxwipConstants.URL_XXWIP200001J,
          XxwipConstants.URL_XXWIP200001J,
          "Yes",
          "No",
          "CloseYes",
          "CloseNo",
          pageParams);          
// 2009-01-15 v1.1 D.Nihei Add End
      // 適用ボタン押下された場合
      } else if (pageContext.getParameter(XxwipConstants.GO_BTN) != null) 
      {
        // 引当数量チェック
        String mainMsg = (String)am.invokeMethod("checkLotQty");
        // バッチIDを取得
        String batchId = pageContext.getParameter("BatchId");
        if (!XxcmnUtility.isBlankOrNull(mainMsg)) 
        {
          //パラメータ用HashMap生成
          Hashtable pageParams = new Hashtable();
          pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId.toString());
          // メインメッセージ作成 
          MessageToken[] mainTokens = new MessageToken[1];
          mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, mainMsg);

          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXCMN,
                                                    XxcmnConstants.XXCMN00025,
                                                    mainTokens);
                                            
          // ダイアログメッセージを表示
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxwipConstants.URL_XXWIP200001J,
            XxwipConstants.URL_XXWIP200001J,
            "Yes",
            "No",
            "ReserveYes",
            "ReserveNo",
            pageParams);          
        } else
        {
          // 適用処理
          apply(pageContext, webBean, am, batchId);
        }
      // 行挿入ボタン押下された場合
      } else if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // SOURCE_PARAMを取得
        String sourceParam = pageContext.getParameter(SOURCE_PARAM);
        // タブのタイプ用の変数
        String tabType = "";
        // 行挿入ボタン項目制御(投入)
        OAAdvancedTableBean investTtableBean = 
          (OAAdvancedTableBean)webBean.findChildRecursive("InvestRN");
        // 行挿入ボタン項目制御(打込)
        OAAdvancedTableBean reInvestTableBean = 
          (OAAdvancedTableBean)webBean.findChildRecursive("ReInvestRN");
        // 行挿入ボタン項目制御(副産物)
        OAAdvancedTableBean coProdTableBean = 
          (OAAdvancedTableBean)webBean.findChildRecursive("CoProdRN");
        if (sourceParam != null && sourceParam.equals(investTtableBean.getName()))
        {
          // 投入
          tabType = XxwipConstants.TAB_TYPE_INVEST;
        }
        if (sourceParam != null && sourceParam.equals(reInvestTableBean.getName()))
        {
          // 打込
          tabType = XxwipConstants.TAB_TYPE_REINVEST;
        }
        if (sourceParam != null && sourceParam.equals(coProdTableBean.getName()))
        {
          // 副産物
          tabType = XxwipConstants.TAB_TYPE_CO_PROD;
        }
        // 引数設定
        Serializable[] params = { tabType };
        // 行挿入処理
        am.invokeMethod("addRow", params);

      // 取消ボタン押下された場合
      } else if (pageContext.getParameter(XxwipConstants.CANCEL_BTN) != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
        // ホームへ遷移
        pageContext.setForwardURL(XxcmnConstants.URL_OAHOMEPAGE,
                                  GUESS_MENU_CONTEXT,
                                  null,
                                  null,
                                  false, // Do not retain AM
                                  ADD_BREAD_CRUMB_NO,
                                  OAWebBeanConstants.IGNORE_MESSAGES);
      // 生産日が変更された場合
      } else if ("productDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // コピー処理
        am.invokeMethod("copyProductDate");
      // 製造日が変更された場合
      } else if ("makerDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // コピー処理
        am.invokeMethod("copyMakerDate");
      // 削除アイコンが押下された場合
      } else if (XxwipConstants.DELETE_ICON.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        String tabType  = (String)pageContext.getParameter(XxwipConstants.PARAM_TAB_TYPE);
        String mtlDtlId = (String)pageContext.getParameter(XxwipConstants.PARAM_MTL_DTL_ID);
        String batchId  = (String)pageContext.getParameter(XxwipConstants.PARAM_BATCH_ID);
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
        // 引数設定
        Serializable[] params = { tabType, batchId, mtlDtlId };
        am.invokeMethod("deleteMaterialLine", params);

      // 投入情報：ロット明細ボタン押下された場合
      } else if (pageContext.getParameter("LotDetailInvest") != null) 
      {
        // 引数設定
        Serializable[] params = { XxwipConstants.TAB_TYPE_INVEST };
        //パラメータ用HashMap生成
        HashMap pageParams = (HashMap)am.invokeMethod("doDetail", params);
        // 次画面へフォワード
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200002J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    
     
      // 打込情報：ロット明細ボタン押下された場合
      } else if (pageContext.getParameter("LotDetailReInvest") != null) 
      {
        // 引数設定
        Serializable[] params = { XxwipConstants.TAB_TYPE_REINVEST };
        //パラメータ用HashMap生成
        HashMap pageParams = (HashMap)am.invokeMethod("doDetail", params);
        // 次画面へフォワード
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200002J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
  /***************************************************************************
   * 適用処理を行うメソッドです。
   * @param pageContext - コンテキスト
   * @param webBean     - ウェブビーン
   * @param pageContext - アプリケーションモジュール
   * @param batchId     - バッチID
   * @throws OAException - OA例外
   ***************************************************************************
   */
  public void apply(
    OAPageContext pageContext, 
    OAWebBean webBean, 
    OAApplicationModule am, 
    String batchId
    ) throws OAException
  {
    // タブを取得
    OASubTabLayoutBean subTabLayout =
      (OASubTabLayoutBean)webBean.findChildRecursive("MaterialSubTab");
    int tabType = subTabLayout.getSelectedIndex(pageContext);
    // 引数設定
    Serializable params[] = { batchId, String.valueOf(tabType) };
    // 登録処理
    String exeType = (String)am.invokeMethod("apply", params);
    // 正常終了の場合
    if (XxcmnConstants.RETURN_SUCCESS.equals(exeType)) 
    {
      // 【共通処理】トランザクション終了
      TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
      // 引数設定
      Serializable param[] = { batchId };
      am.invokeMethod("doCommit", param);
    // 警告終了の場合
    } else if (XxcmnConstants.RETURN_WARN.equals(exeType))
    {
      // ダイアログメッセージを表示
      // メインメッセージ作成
      // トークンを生成します。
      OAException mainMessage = new OAException(XxcmnConstants.APPL_XXWIP
                                               ,XxwipConstants.XXWIP00007);
      //パラメータ用HashMap生成
      Hashtable pageParams = new Hashtable();
      pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId.toString());
      // ダイアログ生成
      XxcmnUtility.createDialog(
        OAException.CONFIRMATION,
        pageContext,
        mainMessage,
        null,
        XxwipConstants.URL_XXWIP200001J,
        XxwipConstants.URL_XXWIP200001J,
        "Yes",
        "No",
        "Yes",
        "No",
        pageParams);
          
    } else 
    {
      // 【共通処理】トランザクション終了
      TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
      am.invokeMethod("doRollBack");
    }
  } // apply
}