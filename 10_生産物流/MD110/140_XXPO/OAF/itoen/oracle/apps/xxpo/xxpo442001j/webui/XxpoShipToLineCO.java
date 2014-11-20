/*============================================================================
* ファイル名 : XxpoShipToLineCO
* 概要説明   : 入庫実績入力・明細コントローラ
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-28 1.0  新藤義勝     新規作成
* 2008-08-19 1.1  二瓶大輔     ST不具合#249対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

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

/***************************************************************************
 * 入庫実績入力明細画面のコントローラクラスです。
 * @author  ORACLE 新藤 義勝
 * @version 1.1
 ***************************************************************************
 */
public class XxpoShipToLineCO extends XxcmnOAControllerImpl
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

    // 【共通処理】「戻る」ボタンチェック
    if (!pageContext.isBackNavigationFired(false)) 
    {
      super.processRequest(pageContext, webBean);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 起動タイプ取得
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // 依頼No取得
      String reqNo   = pageContext.getParameter(XxpoConstants.URL_PARAM_REQ_NO);
      // 起動区分取得
      String exeKbn  = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);
      if (!XxcmnUtility.isBlankOrNull(exeKbn)) 
      {
        // 依頼Noに引当・入出庫実績画面から遷移してきた依頼Noをセット
        reqNo = pageContext.getParameter(XxwshConstants.URL_PARAM_REQ_NO);
        // 起動タイプに起動区分をセット
        exeType = exeKbn;
        // 引数設定
        Serializable paramHdr[] = { exeType, reqNo };
        // 初期化処理実行
        am.invokeMethod("initializeHdr", paramHdr);

      }
      // 引数設定
      Serializable param[] = { exeType, reqNo };  
      // 初期化処理実行
      am.invokeMethod("initializeLine", param);
      
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
      // 起動タイプ取得
      String exeType = pageContext.getParameter("ExeType");

     // 戻るボタン押下された場合
     if (pageContext.getParameter("Back") != null) 
     {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
          
        // 依頼No取得
        String reqNo   = pageContext.getParameter("ReqNo");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);
        // 支給指示作成ヘッダ画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

     // 取消ボタン押下された場合
     } else if (pageContext.getParameter("Cancel") != null) 
     {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
          
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        // 支給指示作成ヘッダ画面へ遷移
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

       // 入庫実績アイコンが選択された場合
      } else if ("shipToIcon".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
          
        // 明細ID取得
        String lineId           = pageContext.getParameter("ORDER_LINE_ID");
        // ヘッダ更新日時取得
        String xohaUpdateDate   = pageContext.getParameter("HDR_UPD_DATE");
        // 明細更新日時取得
        String xolaUpdateDate   = pageContext.getParameter("LINE_UPD_DATE");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN,   XxwshConstants.CALL_PIC_KBN_STOC ); //呼出画面区分「入庫実績画面」
        pageParams.put(XxwshConstants.URL_PARAM_LINE_ID,            lineId);
        pageParams.put(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE, xohaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE,   xolaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,            exeType);
        
        // 入庫実績ロット入力画面へ遷移
        pageContext.setForwardURL(
          XxwshConstants.URL_XXWSH920001J_2,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // 出荷実績アイコンが選択された場合
      } else if ("shippedIcon".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");

        // 明細ID取得
        String lineId           = pageContext.getParameter("ORDER_LINE_ID");
        // ヘッダ更新日時取得
        String xohaUpdateDate   = pageContext.getParameter("HDR_UPD_DATE");
        // 明細更新日時取得
        String xolaUpdateDate   = pageContext.getParameter("LINE_UPD_DATE");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN,   XxwshConstants.CALL_PIC_KBN_STOC); //呼出画面区分「入庫実績画面」
        pageParams.put(XxwshConstants.URL_PARAM_LINE_ID,            lineId);
        pageParams.put(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE, xohaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE,   xolaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,            exeType);
        
        // 出荷実績ロット入力画面へ遷移
        pageContext.setForwardURL(
          XxwshConstants.URL_XXWSH920001J_1,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);
          
      // 適用ボタン押下された場合
      } else if (pageContext.getParameter("Apply") != null) 
      {
        // 新規フラグ取得
        String newFlag = pageContext.getParameter("NewFlag");
        // 引数設定
        Serializable param[] = { exeType };
        // 適用処理実行
        HashMap retParams = (HashMap)am.invokeMethod("doApply", param);
        String  tokenName = (String)retParams.get("tokenName");
        if (!XxcmnUtility.isBlankOrNull(tokenName)) 
        {
          boolean isRetainAM = true;
          // 新規フラグが「Y」の場合
          if (XxcmnConstants.STRING_Y.equals(newFlag)) 
          {
            //パラメータ用HashMap生成
            HashMap pageParams = new HashMap();
            // 依頼No取得
            String reqNo   = (String)retParams.get("reqNo");
            //パラメータ用HashMap生成
            pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
            pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);
            MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                       tokenName) };
            pageParams.put(XxpoConstants.URL_PARAM_MAIN_MESSAGE, pageContext.getMessage(XxcmnConstants.APPL_XXCMN,
                                                                 XxcmnConstants.XXCMN05001, 
                                                                 tokens));   
                                                                 
          // 自画面 (入庫実績入力明細画面)へ遷移
          pageContext.setForwardURL(
            XxpoConstants.URL_XXPO442001JL,
            null,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            pageParams,
            isRetainAM, // Retain AM
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
            OAWebBeanConstants.IGNORE_MESSAGES);    
          }else 
          {
            MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                       tokenName) };
            // 処理成功メッセージ
            throw new OAException(XxcmnConstants.APPL_XXCMN,
                                  XxcmnConstants.XXCMN05001, 
                                  tokens,
                                  OAException.INFORMATION, 
                                  null);
          }
        }
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
