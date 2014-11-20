/*============================================================================
* ファイル名 : XxpoSupplierResultsCO
* 概要説明   : 仕入先出荷実績入力:検索コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-06 1.0  吉元強樹     新規作成
* 2008-05-02 1.0  吉元強樹     変更要求対応(#12,36,90)、内部変更要求対応(#28,41)
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

/***************************************************************************
 * 仕入先出荷実績入力:検索コントローラです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsCO extends XxcmnOAControllerImpl
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

      // ********************************* //
      // * ダイアログ画面「Yes」押下時   * //
      // ********************************* //       
      if (pageContext.getParameter("Yes") != null) 
      {
        // 一括出庫処理
        am.invokeMethod("doBatchDelivery");

      // ********************************* //
      // * ダイアログ画面「No」押下時    * //
      // ********************************* //       
      } else if (pageContext.getParameter("No") != null) 
      {

      // ********************************* //
      // * 初期表示時                    * //
      // ********************************* //
      } else
      {
        // 初期化処理実行
        am.invokeMethod("initialize");
      }
      
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
      // *   進むボタン押下時    * //
      // ************************* //
      if (pageContext.getParameter("Go") != null) 
      {
        // 検索条件取得
        String headerNumber      = pageContext.getParameter("TxtHeaderNumber");        // 発注No.
        String requestNumber     = pageContext.getParameter("TxtRequestNumber");       // 支給No.
        String vendorCode        = pageContext.getParameter("TxtVendorCode");          // 取引先コード
        String vendorId          = pageContext.getParameter("TxtVendorId");            // 取引先ID     
        String mediationCode     = pageContext.getParameter("TxtMediationCode");       // 斡旋者コード
        String mediationId       = pageContext.getParameter("TxtMediationId");         // 斡旋者ID
        String deliveryDateFrom  = pageContext.getParameter("TxtDeliveryDateFrom");    // 納品日(開始)
        String deliveryDateTo    = pageContext.getParameter("TxtDeliveryDateTo");      // 納品日(終了) 
        String status            = pageContext.getParameter("TxtStatus");              // ステータス
        String location          = pageContext.getParameter("TxtLocation");            // 納品先コード
        String department        = pageContext.getParameter("TxtDepartment");          // 発注部署コード
        String approved          = pageContext.getParameter("TxtApproved");            // 承諾要
        String purchase          = pageContext.getParameter("TxtPurchase");            // 直送区分
        String orderApproved     = pageContext.getParameter("TxtOrderApproved");       // 発注承諾
        String cancelSearch      = pageContext.getParameter("TxtCancelSearch");        // 取消検索
        String purchaseApproved  = pageContext.getParameter("TxtPurchaseApproved");    // 仕入承諾

        // 検索パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put("headerNumber",     headerNumber);
        searchParams.put("requestNumber",    requestNumber);
        searchParams.put("vendorCode",       vendorCode);
        searchParams.put("vendorId",         vendorId);
        searchParams.put("mediationCode",    mediationCode);
        searchParams.put("mediationId",      mediationId);
        searchParams.put("deliveryDateFrom", deliveryDateFrom);
        searchParams.put("deliveryDateTo",   deliveryDateTo);
        searchParams.put("status",           status);
        searchParams.put("location",         location);
        searchParams.put("department",       department);
        searchParams.put("approved",         approved);
        searchParams.put("purchase",         purchase);
        searchParams.put("orderApproved",    orderApproved);
        searchParams.put("cancelSearch",     cancelSearch);
        searchParams.put("purchaseApproved", purchaseApproved);
        
        // 引数設定
        Serializable params[] = { searchParams };
        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };

        // 検索項目入力必須チェック
        am.invokeMethod("doRequiredCheck"); 

        // 検索
        am.invokeMethod("doSearch", params, parameterTypes);        


      // ************************* //
      // *   削除ボタン押下時    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // 再表示
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO320001JS, // マージ確認
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
      } else if ("HeaderNumberLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO320001J);
        
        // 検索条件(ヘッダーID)取得
        String searchHeaderId = pageContext.getParameter("searchHeaderId");
        // 検索条件(直送区分CODE)取得
        String searchDShipCode = pageContext.getParameter("searchDShipCode");
        
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID,  searchHeaderId);
        pageParams.put(XxpoConstants.URL_PARAM_UPDATE_FLAG, "1");

        // 仕入先出荷実績:登録画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO320001JM,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // ************************* //
      // *  ページング時         * //
      // ************************* //
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 選択チェックボックスをOFFにします。
        am.invokeMethod("checkBoxOff");

      // ************************* //
      // * 一括受入ボタン押下時  * //
      // ************************* //
      } else if (pageContext.getParameter("BatchDelivery") != null) 
      {
        // 発注情報未選択チェック
        am.invokeMethod("chkSelect");
        
        // メインメッセージ作成 
        OAException mainMessage = new OAException(
                                        XxcmnConstants.APPL_XXPO,
                                        XxpoConstants.XXPO10206,
                                        null,
                                        OAException.INFORMATION,
                                        null);

        // ダイアログメッセージを表示
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO320001JS,
          XxpoConstants.URL_XXPO320001JS,
          "Yes",
          "No",
          "Yes",
          "No",
          null);
      }

    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }

}
