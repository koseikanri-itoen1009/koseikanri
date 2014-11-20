/*============================================================================
* ファイル名 : XxpoOrderReceiptDetailsCO
* 概要説明   : 発注受入入力画面:受入詳細コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-26 1.0  吉元強樹     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.Iterator;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.jbo.domain.Number;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

/***************************************************************************
 * 発注受入入力画面:受入詳細コントローラです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderReceiptDetailsCO extends XxcmnOAControllerImpl
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
      
    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下していない場合
    if (!pageContext.isBackNavigationFired(false)) 
    {


      // **************************** //
      // * サブタブリンククリック時 *
      // **************************** //
      if ("OrderDetails1Link".equals(pageContext.getParameter(EVENT_PARAM))
        || "OrderDetails2Link".equals(pageContext.getParameter(EVENT_PARAM))
        || "OrderDetails3Link".equals(pageContext.getParameter(EVENT_PARAM))
        || "LotInfoLink".equals(pageContext.getParameter(EVENT_PARAM))
        || "GreenTeaInfoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
      
        // 処理無し

      // ********************************* //
      // * ダイアログ画面「Yes」押下時   * //
      // ********************************* //       
      } else if (pageContext.getParameter("Yes") != null) 
      {

        boolean updFlag = false;
        
        // 更新処理
        String ret = (String)am.invokeMethod("apply");
        
        // 正常終了の場合
        if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
        {

          // 更新処理があった場合は、フラグを立てる
          if (XxcmnConstants.STRING_TRUE.equals(ret)) 
          {
            updFlag = true;
          }
          
          // 登録・更新処理
          HashMap retHash = (HashMap)am.invokeMethod("doAllReceipt");

          ret = (String)retHash.get("RetFlag");
          Object requestId = retHash.get("RequestId");
            
          // 正常終了の場合
          if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
          {
            
            // 更新処理があった場合
            if (updFlag || !XxcmnUtility.isBlankOrNull(requestId))
            {
              // 【共通処理】トランザクション終了
              TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

              // コミット
              am.invokeMethod("doCommit");

              HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");
              HashMap params = new HashMap();
              params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER, retHashMap.get("HeaderNumber"));
              params.put(XxpoConstants.URL_PARAM_START_CONDITION, retHashMap.get("pStartCondition"));

              // 更新処理完了MSGを設定し、自画面遷移            
              pageContext.putDialogMessage(new OAException(
                                                  XxcmnConstants.APPL_XXPO,
                                                  XxpoConstants.XXPO30041, 
                                                  null, 
                                                  OAException.INFORMATION, 
                                                  null));

              // URLパラメータを削除
              pageContext.removeParameter("Yes");

              // 再表示
              pageContext.forwardImmediatelyToCurrentPage(
                            params,
                            true,
                            OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
                          
            }
          }
        }
        
        // 正常終了でない、又は、更新処理が無かった場合はロールバック
        if (XxcmnConstants.RETURN_NOT_EXE.equals(ret) || !updFlag)
        {
          // 【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

          // ロールバック
          am.invokeMethod("doRollBack");
        }

      // ********************************* //
      // * ダイアログ画面「No」押下時    * //
      // ********************************* //
      } else if (pageContext.getParameter("No") != null) 
      {

        // ロールバック
        am.invokeMethod("doRollBack");
        
      // **************************** //
      // * 初期表示時               * //
      // **************************** //      
      } else
      {
        // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
        TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // *************************** //  
        // * パラメータ初期化    * //
        // *************************** //
        String startCondition = XxpoConstants.START_CONDITION_1; // デフォルト:メニューから起動(1)
        String headerNumber   = "-1";                            // デフォルト: 

        // *************************** //  
        // * URLパラメータの取得     * //
        // *************************** //      
        String pStartCondition = pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);
        String pHeaderNumber   = pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

        // 検索画面から起動
        if (!XxcmnUtility.isBlankOrNull(pStartCondition)
          && (XxpoConstants.START_CONDITION_2.equals(pStartCondition)))
        {
          startCondition = pStartCondition;  // URLパラメータを設定
          headerNumber   = pHeaderNumber;    // URLパラメータを設定
        } else 
        {
          if (!XxcmnUtility.isBlankOrNull(pHeaderNumber))
          {
            headerNumber   = pHeaderNumber;    // URLパラメータを設定            
          }
        }

        // 各種パラメータを設定
        HashMap hashParams = new HashMap();
        hashParams.put("StartCondition", startCondition);
        hashParams.put("HeaderNumber", headerNumber);

        // 引数設定
        Serializable params[] = { hashParams };
        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };

        // 自画面エラー遷移の場合は、初期化処理を実施しない
        if (!XxcmnUtility.isBlankOrNull(headerNumber))
        {
          // 初期化処理実行
          am.invokeMethod("initialize2", params, parameterTypes);
        }
        
      }
      
    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO310001J, true))
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
        // 検索条件取得
        String headerNumber  = pageContext.getParameter("TxtHeaderNumber");  // 発注No
        String requestNumber = pageContext.getParameter("TxtRequestNumber"); // 支給No

        // 検索パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put("HeaderNumber",  headerNumber);
        searchParams.put("RequestNumber", requestNumber);
        
        // 引数設定
        Serializable params[] = { searchParams };
        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };

        // 検索項目入力必須チェック
        am.invokeMethod("doRequiredCheck2", params, parameterTypes); 

        // 検索
        am.invokeMethod("doSearch2", params, parameterTypes);

      // ************************* //
      // *   消去ボタン押下時    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {

        // URLパラメータ(発注番号)を削除
        pageContext.removeParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JD,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES);


      // ************************* //
      // *   リンククリック時    * //
      // ************************* //
      } else if ("LineNumberLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // 検索条件(発注番号)取得
        String searchHeaderNumber = pageContext.getParameter("searchHeaderNumber");
        // 検索条件(発注明細番号)取得
        String searchLineNumber = pageContext.getParameter("searchLineNumber");

        // PVO内のURLパラメータを取得
        HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");

        String startCondition = (String)retHashMap.get("pStartCondition");
        
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,        searchHeaderNumber);
        pageParams.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  searchLineNumber);
        pageParams.put(XxpoConstants.URL_PARAM_START_CONDITION,      startCondition);

        // 発注受入:入力画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JM,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

        
      // ********************************* //
      // *      製造日変更時             * //
      // ********************************* //
      } else if ("ProductedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {

        // 値取得
        String changedLineNum  = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);  // LineNumber

        // 検索パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  changedLineNum);

        // 引数設定
        Serializable params[] = { searchParams };
        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };
      
        // 製造日変更時処理
        am.invokeMethod("productedDateChanged", params, parameterTypes);
        

      // ************************** //
      // * 取消ボタン押下時       * //
      // ************************** //
      } else if (pageContext.getParameter("Cancel") != null)
      {
      
        // PVO内のURLパラメータを取得
        HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");

        String startCondition = (String)retHashMap.get("pStartCondition");

        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // ロールバック
        am.invokeMethod("doRollBack");
            
        // 取得した起動条件が "1"(メニューから起動)の場合
        if (XxpoConstants.START_CONDITION_1.equals(startCondition))
        {

          // ホームへ遷移
          pageContext.setForwardURL(XxcmnConstants.URL_OAHOMEPAGE,
                                    GUESS_MENU_CONTEXT,
                                    null,
                                    null,
                                    false, // Do not retain AM
                                    ADD_BREAD_CRUMB_NO,
                                    OAWebBeanConstants.IGNORE_MESSAGES); 

        // 取得した起動条件が "2"(発注受入検索画面)の場合          
        } else 
        {
          
          // 発注受入検索画面へ遷移
          pageContext.setForwardURL(
            XxpoConstants.URL_XXPO310001JS,
            null,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            null,
            true, // Retain AM
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
            OAWebBeanConstants.IGNORE_MESSAGES);         
        }

      // ***************************** //
      // *   適用ボタン押下時        * //
      // ***************************** //
      } else if (pageContext.getParameter("Apply") != null)
      {

        // 登録・更新前チェック処理
        am.invokeMethod("dataCheck");

        // 全受チェック処理
        ArrayList lineIdList = (ArrayList)am.invokeMethod("chkAllReceipt");

        // 引当可能数において警告があった場合、確認ダイアログを生成
        if (lineIdList.size() > 0)
        {

          // ダイアログ画面表示用メッセージ
          StringBuffer pageHeaderText = new StringBuffer();

          // ArrayListをIteratorへ変換
          Iterator iteLineIdList = lineIdList.iterator();
          
          // 『受入日後倒し』発注明細が存在する間
          while (iteLineIdList.hasNext())
          {

            // 発注明細IDを取得
            Number lineId = (Number)iteLineIdList.next();

            // 引数設定
            Serializable params[] = { lineId };
            // getTokenの引数型設定
            Class[] parameterTypes = { Number.class };
            
            // 発注明細VOに紐付く、納入先名/品目名/ロットNOを取得
            HashMap hashTokens = (HashMap)am.invokeMethod("getToken", params, parameterTypes);

            MessageToken[] tokens = new MessageToken[3];
            tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, (String)hashTokens.get(XxcmnConstants.TOKEN_LOCATION));
            tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     (String)hashTokens.get(XxcmnConstants.TOKEN_ITEM));
            tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      (String)hashTokens.get(XxcmnConstants.TOKEN_LOT));

            pageHeaderText = pageHeaderText.append(pageContext.getMessage(
                                                      XxcmnConstants.APPL_XXCMN,
                                                      XxcmnConstants.XXCMN10112,
                                                      tokens));

            // 改行コードを追加
            pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);
            pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);

          }

          // メインメッセージ作成 
          MessageToken[] mainTokens = new MessageToken[1];
          mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, pageHeaderText.toString());

          OAException mainMessage = new OAException(
                                          XxcmnConstants.APPL_XXCMN,
                                          XxcmnConstants.XXCMN00025,
                                          mainTokens);

          // ダイアログメッセージを表示
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxpoConstants.URL_XXPO310001JD,
            XxpoConstants.URL_XXPO310001JD,
            "Yes",
            "No",
            "Yes",
            "No",
            null);

        // 引当可能数において警告が無かった場合
        } else
        {

          boolean updFlag = false;
        
          // 更新処理
          String ret = (String)am.invokeMethod("apply");
        
          // 正常終了の場合
          if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
          {

            // 更新処理があった場合は、フラグを立てる
            if (XxcmnConstants.STRING_TRUE.equals(ret)) 
            {
              updFlag = true;
            }
          
            // 登録・更新処理
            HashMap retHash = (HashMap)am.invokeMethod("doAllReceipt");

            ret = (String)retHash.get("RetFlag");
            Object requestId = retHash.get("RequestId");

            // 正常終了の場合
            if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
            {
            
              // 更新処理があった場合
              if (updFlag || !XxcmnUtility.isBlankOrNull(requestId))
              {
                // 【共通処理】トランザクション終了
                TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

                // コミット
                am.invokeMethod("doCommit");

                HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");
                HashMap params = new HashMap();
                params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER, retHashMap.get("HeaderNumber"));
                params.put(XxpoConstants.URL_PARAM_START_CONDITION, retHashMap.get("pStartCondition"));

                // 更新処理完了MSGを設定し、自画面遷移            
                pageContext.putDialogMessage(new OAException(
                                                    XxcmnConstants.APPL_XXPO,
                                                    XxpoConstants.XXPO30041, 
                                                    null, 
                                                    OAException.INFORMATION, 
                                                    null));

                pageContext.forwardImmediatelyToCurrentPage(
                              params,
                              true,
                              OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
                          
              }
            }
          }
          
          // 正常終了でない、又は、更新処理が無かった場合はロールバック
          if (XxcmnConstants.RETURN_NOT_EXE.equals(ret) || !updFlag)
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

            // ロールバック
            am.invokeMethod("doRollBack");
          }
        }
      }
      
    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }

  }

}
