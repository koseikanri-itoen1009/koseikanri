/*============================================================================
* ファイル名 : XxpoProvisionInstMakeHeaderCO
* 概要説明   : 支給指示作成ヘッダコントローラ
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-07 1.0  二瓶大輔     新規作成
* 2008-06-09 1.1  二瓶大輔     変更要求#42対応
* 2008-08-13 1.2  二瓶大輔     ST不具合#249対応
* 2018-07-19 1.3  小路恭弘     E_本稼動_15135対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
// 2018-07-19 [E_本稼動_15135] Add Start
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
// 2018-07-19 [E_本稼動_15135] Add End
/***************************************************************************
 * 支給指示作成ヘッダ画面のコントローラクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.3
 ***************************************************************************
 */
public class XxpoProvisionInstMakeHeaderCO extends XxcmnOAControllerImpl
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

      // 前画面URL取得
      String prevUrl = pageContext.getParameter(XxpoConstants.URL_PARAM_PREV_URL);
      // 元依頼No取得
      String baseReqNo = pageContext.getParameter(XxpoConstants.URL_PARAM_BASE_REQ_NO);
      
// 2018-07-19 [E_本稼動_15135] Add Start
      // 起動タイプ取得
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
// 2018-07-19 [E_本稼動_15135] Add End
      if (!XxcmnUtility.isBlankOrNull(baseReqNo)) 
      {
        // AMの取得
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
// 2018-07-19 [E_本稼動_15135] Del Start
//        // 起動タイプ取得
//        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
// 2018-07-19 [E_本稼動_15135] Del End
        // 引数設定
        Serializable param[] = { exeType, baseReqNo };
        am.invokeMethod("initializeCopy", param);
      // 前画面が有償支給要約画面の場合、初期化処理を実施
      } else if (XxpoConstants.URL_XXPO440001J.equals(prevUrl)
              && pageContext.getParameter("Next") == null)
      {
        // AMの取得
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
// 2018-07-19 [E_本稼動_15135] Del Start
//        // 起動タイプ取得
//        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
// 2018-07-19 [E_本稼動_15135] Del End
        // 依頼No取得
        String reqNo   = pageContext.getParameter(XxpoConstants.URL_PARAM_REQ_NO);
        // 引数設定
        Serializable param[] = { exeType, reqNo };
        // 初期化処理実行
        am.invokeMethod("initializeHdr", param);
      }
// 2018-07-19 [E_本稼動_15135] Add Start
      // 起動タイプによって値リストを変更(出庫倉庫)
      // 東洋埠頭の場合
      if (XxpoConstants.EXE_TYPE_13.equals(exeType))
      {
        OAMessageLovInputBean shipWhseCodeTextInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShipWhseCode");
        shipWhseCodeTextInputBean.setLovRegion(pageContext, "/itoen/oracle/apps/xxpo/lov/webui/ShipWhseCode13LovRN");
      }
// 2018-07-19 [E_本稼動_15135] Add End
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

      // 取消ボタン押下された場合
      if (pageContext.getParameter("Cancel") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);
          
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
        // 起動タイプ取得
        String exeType = pageContext.getParameter("ExeType");
        // 依頼No取得
        String reqNo   = pageContext.getParameter("ReqNo");
        // 新規フラグ取得
        String newFlag = pageContext.getParameter("NewFlag");
        boolean isRetainAM = true;
        // 新規フラグが「Y」の場合、retainAMをfalseで遷移
        if (XxcmnConstants.STRING_Y.equals(newFlag)) 
        {
          isRetainAM = false;
        }
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ
        // 支給要約画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          isRetainAM, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // 確定ボタン押下された場合
      } else if (pageContext.getParameter("Fix") != null) 
      {
        // 確定処理実行
        am.invokeMethod("doFix");

      // 受領ボタン押下された場合
      } else if (pageContext.getParameter("Rcv") != null) 
      {
        // 受領処理実行
        am.invokeMethod("doRcv");

      // 手動指示確定ボタン押下された場合
      } else if (pageContext.getParameter("ManualFix") != null) 
      {
        // 手動指示確定処理実行
        am.invokeMethod("doManualFix");

      // 価格設定ボタン押下された場合
      } else if (pageContext.getParameter("PriceSet") != null) 
      {
        // 価格設定処理実行
        am.invokeMethod("doPriceSet");

      // 支給取消ボタン押下された場合
      } else if (pageContext.getParameter("ProvCancel") != null) 
      {
        // 支給取消処理実行
        am.invokeMethod("doProvCancel");
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
        // 起動タイプ取得
        String exeType = pageContext.getParameter("ExeType");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ
        MessageToken[] tokens = null;
        pageParams.put(XxpoConstants.URL_PARAM_CAN_MESSAGE, pageContext.getMessage(XxcmnConstants.APPL_XXPO,
                                                                                   XxpoConstants.XXPO30050, 
                                                                                   tokens));
        // 支給要約画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // 次へボタン押下された場合
      } else if (pageContext.getParameter("Next") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);
        // 起動タイプ取得
        String exeType = pageContext.getParameter("ExeType");
        // 依頼No取得
        String reqNo   = pageContext.getParameter("ReqNo");
        // 次へチェック
        am.invokeMethod("doNext");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // 起動タイプ
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);   // 依頼No
        // 支給指示作成画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO440001JL,
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
