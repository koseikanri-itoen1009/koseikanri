/*============================================================================
* ファイル名 : XxpoOrderReceiptMakeCO
* 概要説明   : 受入実績作成:発注受入入力コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-04 1.0  吉元強樹     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;

import itoen.oracle.apps.xxpo.util.XxpoConstants;
import oracle.apps.fnd.common.MessageToken;

/***************************************************************************
 * 受入実績作成:発注受入入力コントローラです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderReceiptMakeCO extends XxcmnOAControllerImpl
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
      // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // ********************************* //
      // * ダイアログ画面「Yes」押下時   * //
      // ********************************* //       
      if (pageContext.getParameter("Yes") != null) 
      {

          // URLパラメータを削除
          pageContext.removeParameter("Yes");

          // 登録・更新処理
          HashMap retHash = (HashMap)am.invokeMethod("apply2");

          String ret = (String)retHash.get("RetFlag");
          Object requestId = retHash.get("RequestId");

          // 正常終了の場合
          if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);
            
            // コミット
            am.invokeMethod("doCommit");

            // ********************************** //
            // *     URLパラメータ設定          * //
            // ********************************** //
            // URLパラメータ(起動条件)
            // (1:メニューから起動, 2:検索画面から遷移)
            String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

            // URLパラメータ(発注番号)
            String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

            // URLパラメータ(発注明細番号を取得)
            String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

            // 検索パラメータ用HashMap設定
            HashMap params = new HashMap();
          
            params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
            params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
            params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);  

            // 引数設定
            Serializable searchParams[] = { params };
            // doSearchの引数型設定
            Class[] parameterTypes = { HashMap.class };
      
            // 終了処理
            am.invokeMethod("doEndOfProcess", searchParams, parameterTypes);

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

          // 正常終了でない場合、ロールバック
          } else
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

            // ロールバック
            am.invokeMethod("doRollBack");

            // ********************************** //
            // *     URLパラメータ設定          * //
            // ********************************** //
            // URLパラメータ(起動条件)
            // (1:メニューから起動, 2:検索画面から遷移)
            String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

            // URLパラメータ(発注番号)
            String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

            // URLパラメータ(発注明細番号を取得)
            String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

            // 検索パラメータ用HashMap設定
            HashMap params = new HashMap();
          
            params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
            params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
            params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);         
        
            pageContext.forwardImmediately(XxpoConstants.URL_XXPO310001JM,
                                           null,
                                           OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                           null,
                                           params,
                                           true, // retain AM
                                           OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

          }


      // ********************************* //
      // * ダイアログ画面「No」押下時    * //
      // ********************************* //
      } else if (pageContext.getParameter("No") != null) 
      {

        // 処理は行わない。画面を再表示

      // ********************************* //
      // *      前画面からの遷移時       * //
      // ********************************* //
      } else
      {

        // ********************************** //
        // *     URLパラメータ取得          * //
        // ********************************** //
        // URLパラメータ(起動条件)
        // (1:メニューから起動, 2:検索画面から遷移)
        String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);
      
        // URLパラメータ(発注番号)
        String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

        // URLパラメータ(発注明細番号を取得)
        String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);
    
        // 検索パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put("startCondition",  startCondition);
        searchParams.put("headerNumber",    headerNumber);
        searchParams.put("lineNumber",      lineNumber);

        // 引数設定
        Serializable params[] = { searchParams };
        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };
      
        // 初期化処理実行
        am.invokeMethod("initialize3", params, parameterTypes);      
 
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
      // *   削除ボタン押下時    * //
      // ************************* //
      if (pageContext.getParameter("Cancel") != null) 
      {
        // URLパラメータ(起動条件)
        // (1:メニューから起動, 2:検索画面から遷移)
        String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_START_CONDITION, startCondition);

        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JD,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);        
      
      // ***************************** //
      // *   行挿入押下時            * //
      // ***************************** //
      } else if (pageContext.getParameter("AddRow") != null)
      {
        am.invokeMethod("addRow");

      // ***************************** //
      // *   適用ボタン押下時        * //
      // ***************************** //
      } else if (pageContext.getParameter("Apply") != null)
      {
        // 必須項目入力チェック回避の為、空行の削除を実施
        String rowCount = (String)am.invokeMethod("deleteRow");

        // 受入明細数が0行となっている場合は、適用処理は行わない。
        if (!rowCount.equals(XxcmnConstants.STRING_ZERO)) 
        {

          // 登録・更新前チェック処理
          HashMap messageCode = (HashMap)am.invokeMethod("dataCheck2");

          // 引当可能数において警告があった場合、確認ダイアログを生成
          if (messageCode.size() > 0)
          {
            // ダイアログ画面表示用メッセージ
            StringBuffer pageHeaderText = new StringBuffer();
          
            // 『受入日後倒し』または、『受入減数計上』のメッセージが格納されている場合
            if (messageCode.get(XxcmnConstants.XXCMN10112) != null) 
            {
              // 発注明細VOに紐付く、納入先名/品目名/ロットNOを取得
              Serializable params[] = { XxcmnConstants.STRING_ZERO };
              HashMap hashTokens = (HashMap)am.invokeMethod("getToken2", params);

              MessageToken[] tokens = new MessageToken[3];
              tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, (String)hashTokens.get(XxcmnConstants.TOKEN_LOCATION));
              tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     (String)hashTokens.get(XxcmnConstants.TOKEN_ITEM));
              tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      (String)hashTokens.get(XxcmnConstants.TOKEN_LOT));


              pageHeaderText = pageHeaderText.append(pageContext.getMessage(
                                                       XxcmnConstants.APPL_XXCMN, 
                                                       XxcmnConstants.XXCMN10112,
                                                       tokens));
            }
            
            // 『受入増数』のメッセージが格納されている場合
            if (messageCode.get(XxcmnConstants.XXCMN10110) != null) 
            {
              // 発注明細VOに紐付く、相手先在庫入庫先名/品目名/ロットNOを取得
              Serializable params[] = { XxcmnConstants.STRING_ONE };
              HashMap hashTokens = (HashMap)am.invokeMethod("getToken2", params);

              MessageToken[] tokens = new MessageToken[3];
              tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, (String)hashTokens.get(XxcmnConstants.TOKEN_LOCATION));
              tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     (String)hashTokens.get(XxcmnConstants.TOKEN_ITEM));
              tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      (String)hashTokens.get(XxcmnConstants.TOKEN_LOT));

              // メッセージが複数存在する場合
              if (pageHeaderText.length() > 0)
              {
                // 改行コードを追加
                pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);
                pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);
              }
              
              pageHeaderText = pageHeaderText.append(pageContext.getMessage(
                                                       XxcmnConstants.APPL_XXCMN, 
                                                       XxcmnConstants.XXCMN10110,
                                                       tokens));              
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
              XxpoConstants.URL_XXPO310001JM,
              XxpoConstants.URL_XXPO310001JM,
              "Yes",
              "No",
              "Yes",
              "No",
              null);
              
          // 引当可能数において警告が無かった場合              
          } else
          {

            // 登録・更新処理
            HashMap retHash = (HashMap)am.invokeMethod("apply2");

            String ret = (String)retHash.get("RetFlag");
            Object requestId = retHash.get("RequestId");

            // 正常終了の場合
            if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
            {

              // 【共通処理】トランザクション終了
              TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);
            
              // コミット
              am.invokeMethod("doCommit");

              // ********************************** //
              // *     URLパラメータ設定          * //
              // ********************************** //
              // URLパラメータ(起動条件)
              // URLパラメータ(発注番号)
              String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

              // URLパラメータ(発注明細番号を取得)
              String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

              // 検索パラメータ用HashMap設定
              HashMap params = new HashMap();
          
              params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,        headerNumber);
              params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  lineNumber);  

              // 引数設定
              Serializable searchParams[] = { params };
              // doSearchの引数型設定
              Class[] parameterTypes = { HashMap.class };
      
              // 終了処理
              am.invokeMethod("doEndOfProcess", searchParams, parameterTypes);

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

            // 正常終了でない場合、ロールバック
            } else
            {

              // 【共通処理】トランザクション終了
              TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

              // ロールバック
              am.invokeMethod("doRollBack");

              // ********************************** //
              // *     URLパラメータ設定          * //
              // ********************************** //
              // URLパラメータ(起動条件)
              // (1:メニューから起動, 2:検索画面から遷移)
              String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

              // URLパラメータ(発注番号)
              String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

              // URLパラメータ(発注明細番号を取得)
              String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

              // 検索パラメータ用HashMap設定
              HashMap params = new HashMap();
          
              params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
              params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
              params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);         
        
              pageContext.forwardImmediately(XxpoConstants.URL_XXPO310001JM,
                                             null,
                                             OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                             null,
                                             params,
                                             true, // retain AM
                                             OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

            }
          }
        // 受入明細数が0行となっている場合は、自画面遷移
        } else
        {

          // ********************************** //
          // *     URLパラメータ設定          * //
          // ********************************** //
          // URLパラメータ(起動条件)
          // (1:メニューから起動, 2:検索画面から遷移)
          String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

          // URLパラメータ(発注番号)
          String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

          // URLパラメータ(発注明細番号を取得)
          String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

          // 検索パラメータ用HashMap設定
          HashMap params = new HashMap();
          
          params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
          params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
          params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);         
        
          pageContext.forwardImmediately(XxpoConstants.URL_XXPO310001JM,
                                         null,
                                         OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                         null,
                                         params,
                                         true, // retain AM
                                         OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        }
      }
      
    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }

  }

}
