/*============================================================================
* ファイル名 : XxpoSupplierResultsMakeCO
* 概要説明   : 仕入先出荷実績入力:登録コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-08 1.0  吉元強樹     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.webui;

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
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;


/***************************************************************************
 * 仕入先出荷実績入力:登録コントローラです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsMakeCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);
      
      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // 前画面の値取得
      String searchHeaderId  = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID);  // ヘッダーID
      String updateFlag      = pageContext.getParameter(XxpoConstants.URL_PARAM_UPDATE_FLAG);       // 更新フラグ

      // 検索パラメータ用HashMap設定
      HashMap searchParams = new HashMap();
      searchParams.put("searchHeaderId",  searchHeaderId);

      // 引数設定
      Serializable params[] = { searchParams };
      // doSearchの引数型設定
      Class[] parameterTypes = { HashMap.class };
      
      // 初期化処理実行(再描画時は処理しない)
      am.invokeMethod("initialize2", params, parameterTypes);      
      
    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO320001J, true))
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
      // *   取消ボタン押下時    * //
      // ************************* //
      if (pageContext.getParameter("Cancel") != null) 
      {

        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);

        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO320001JS, // マージ確認
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
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
 

      // ********************************* //
      // *      適用ボタン押下時         * //
      // ********************************* //
      } else if (pageContext.getParameter("Apply") != null) 
      {
    
        // 登録・更新チェック処理
        am.invokeMethod("allCheck");

        // 更新処理(正常(更新有)：HeaderID、正常(更新無)：TRUE、エラー：FALSE)
        String retCode = (String)am.invokeMethod("Apply");

        // 正常終了の場合、コミット処理
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;

          // 正常終了(更新有)の場合(HeaderId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode)) 
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }
        
          // 正常終了時に取得したヘッダーIDを退避
          //String headerId = retCode;

          // 【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);

          // コミット
          am.invokeMethod("doCommit");

          // コンカレント：標準発注インポート発行
          retCode = (String)am.invokeMethod("doDSResultsMake2");

          if (XxcmnConstants.RETURN_SUCCESS.equals(retCode))
          {
            am.invokeMethod("doCommit");          
          }

          // 終了処理：
          // 検索パラメータ用HashMap設定
          //HashMap searchParams = new HashMap();
          //searchParams.put(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID,  headerId);

          // 正常終了(更新有)の場合
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag)) 
          {
            // 更新処理完了MSGを設定し、自画面遷移
            throw new OAException(
                         XxcmnConstants.APPL_XXPO,
                         XxpoConstants.XXPO30042, 
                         null, 
                         OAException.INFORMATION, 
                         null);
          }
        // 正常終了でない場合、ロールバック
        } else
        {
          // 【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);

          am.invokeMethod("doRollBack");
        }

      }

    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }

  }

}
