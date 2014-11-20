/*============================================================================
* ファイル名 : XxpoVendorSupplyCO
* 概要説明   : 外注出来高報告:検索コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2007-12-26 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.webui;

import com.sun.java.util.collections.HashMap;

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
/***************************************************************************
 * 出来高実績報告:検索コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
      
      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 初期化処理実行
      am.invokeMethod("initialize");

    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO340001J, true))
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
        String lotNumber            = pageContext.getParameter("TxtLotNumber");            //ロット番号
        String manufacturedDateFrom = pageContext.getParameter("TxtManufacturedDateFrom"); //生産日FROM
        String manufacturedDateTo   = pageContext.getParameter("TxtManufacturedDateTo");   //生産日TO
        String vendorCode           = pageContext.getParameter("TxtVendorCode");           //取引先
        String factoryCode          = pageContext.getParameter("TxtFactoryCode");          //工場
        String itemCode             = pageContext.getParameter("TxtItemCode");             //品目
        String productedDateFrom    = pageContext.getParameter("TxtProductedDateFrom");    //製造日FROM
        String productedDateTo      = pageContext.getParameter("TxtProductedDateTo");      //製造日TO
        String koyuCode             = pageContext.getParameter("TxtKoyuCode");             //固有記号
        String corrected            = pageContext.getParameter("TxtCorrected");            //訂正有
        // 検索パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put("lotNumber"           , lotNumber);
        searchParams.put("manufacturedDateFrom", manufacturedDateFrom);
        searchParams.put("manufacturedDateTo"  , manufacturedDateTo);
        searchParams.put("vendorCode"          , vendorCode);
        searchParams.put("factoryCode"         , factoryCode);
        searchParams.put("itemCode"            , itemCode);
        searchParams.put("productedDateFrom"   , productedDateFrom);
        searchParams.put("productedDateTo"     , productedDateTo);
        searchParams.put("koyuCode"            , koyuCode);
        searchParams.put("corrected"           , corrected);
        // 引数設定
        Serializable params[] = { searchParams };
        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };

        // 検索
        am.invokeMethod("doSearch", params, parameterTypes);
      
      // ************************* //
      // *   消去ボタン押下時    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
          
        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // ************************* //
      // *   新規ボタン押下時    * //
      // ************************* //
      } else if (pageContext.getParameter("New") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
          
        // 外注出来高報告:登録画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JM,
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
      } else if ("LotNumberClick".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
        
        // 検索条件(実績ID)取得
        String searchTxnsId = pageContext.getParameter("searchTxnsId");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_SEARCH_TXNS_ID, searchTxnsId);
        pageParams.put(XxpoConstants.URL_PARAM_UPDATE_FLAG, "1");

        // 外注出来高報告:登録画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JM,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 
      }

    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
