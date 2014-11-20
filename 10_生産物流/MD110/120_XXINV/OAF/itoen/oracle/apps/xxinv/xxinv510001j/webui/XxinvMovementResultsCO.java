/*============================================================================
* ファイル名 : XxinvMovementResultsCO
* 概要説明   : 入出庫実績要約:検索コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  大橋孝郎     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.webui;

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
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 入出庫実績要約:検索コントローラです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementResultsCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // 入力パラメータ取得
      String actualFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG); // 実績データ区分
      String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // 製品識別区分

      // 検索パラメータ用HashMap設定
      HashMap searchParams = new HashMap();
      searchParams.put("actualFlag",          actualFlag);
      searchParams.put("productFlag",       productFlag);

      // 引数設定
      Serializable params[] = { searchParams };

      // initializeの引数型設定
      Class[] parameterTypes = { HashMap.class };

      // 初期化処理実行
      am.invokeMethod("initialize", params, parameterTypes);

    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if  (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510001J, true))
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
        String movNum              = pageContext.getParameter("TxtMovNum");              // 移動番号
        String movType             = pageContext.getParameter("TxtMovType");             // 移動タイプ
        String status              = pageContext.getParameter("TxtStatus");              // ステータス
        String shippedLocatId      = pageContext.getParameter("TxtShippedLocatId");      // 出庫元
        String shipToLocatId       = pageContext.getParameter("TxtShipToLocatId");       // 入庫先
        String shipDateFrom        = pageContext.getParameter("TxtShipDateFrom");        // 出庫日(開始)
        String shipDateTo          = pageContext.getParameter("TxtShipDateTo");          // 出庫日(終了)
        String arrivalDateFrom     = pageContext.getParameter("TxtArrivalDateFrom");     // 着日(開始)
        String arrivalDateTo       = pageContext.getParameter("TxtArrivalDateTo");       // 着日(終了)
        String instructionPostCode = pageContext.getParameter("TxtInstructionPostCode"); // 移動指示部署
        String deliveryNo          = pageContext.getParameter("TxtDeliveryNo");          // 配送No.
        String peopleCode          = pageContext.getParameter("Peoplecode");             // 従業員区分
        String actualFlag          = pageContext.getParameter("Actual");                 // 実績データ区分
        String productFlag         = pageContext.getParameter("Product");                // 製品識別区分

        // 検索パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put("movNum",              movNum);
        searchParams.put("movType",             movType);
        searchParams.put("status",              status);
        searchParams.put("shippedLocatId",      shippedLocatId);
        searchParams.put("shipToLocatId",       shipToLocatId);
        searchParams.put("shipDateFrom",        shipDateFrom);
        searchParams.put("shipDateTo",          shipDateTo);
        searchParams.put("arrivalDateFrom",     arrivalDateFrom);
        searchParams.put("arrivalDateTo",       arrivalDateTo);
        searchParams.put("instructionPostCode", instructionPostCode);
        searchParams.put("deliveryNo",          deliveryNo);
        searchParams.put("peopleCode",          peopleCode);
        searchParams.put("actualFlag",          actualFlag);
        searchParams.put("productFlag",         productFlag);

        // 引数設定
        Serializable params[] = { searchParams };

        // doSearchの引数型設定
        Class[] parameterTypes = { HashMap.class };

        // 検索項目チェック
        am.invokeMethod("doItemCheck", params, parameterTypes); 

        // 検索
        am.invokeMethod("doSearch", params, parameterTypes);

      // ************************* //
      // *   削除ボタン押下時    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // 再表示
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JS, // マージ確認
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
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // パラメータ取得
        String peopleCode  = pageContext.getParameter("Peoplecode");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");

        // パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);

        // 入出庫実績ヘッダ画面へ
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);


      // ************************* //
      // *   リンククリック時    * //
      // ************************* //
      } else if ("MovNumberClick".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

        // 検索条件(移動ヘッダID)取得
        String searchMovHdrId = pageContext.getParameter("searchMovHdrId");

        // パラメータ取得
        String peopleCode  = pageContext.getParameter("Peoplecode");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "1");

        // 入出庫実績ヘッダ画面へ
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // *********************************** //
      // *   出庫日FROMが変更された場合    * //
      // *********************************** //
      } else if ("shipDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // コピー処理
        am.invokeMethod("copyShipDate");

      // ********************************* //
      // *   着日FROMが変更された場合    * //
      // ********************************* //
      }  else if ("arrivalDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // コピー処理
        am.invokeMethod("copyArrivalDate");
      }
      
    // 例外が発生した場合    
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }

}
