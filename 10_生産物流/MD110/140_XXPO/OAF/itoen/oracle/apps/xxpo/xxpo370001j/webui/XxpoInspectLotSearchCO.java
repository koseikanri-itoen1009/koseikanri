/*============================================================================
* ファイル名 : XxpoInspectLotSearchCO
* 概要説明   : 検査ロット情報検索コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  戸谷田 大輔    新規作成
* 2008-05-09 1.1  熊本 和郎      内部変更要求#28,41,43対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Map;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;

/***************************************************************************
 * 検査ロット:検索コントローラクラスです。
 * @author  ORACLE 戸谷田 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoInspectLotSearchCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchCO.java,v 1.5 2008/02/22 06:25:20 usr3149 Exp $";
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

    // 「戻る」ボタンチェック
    if (!pageContext.isBackNavigationFired(false))
    {
      // トランザクション開始
      TransactionUnitHelper.startTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // 初期化処理
      am.invokeMethod("initialize");
      // ユーザー情報取得 
      Map retHashMap = new HashMap();
      retHashMap = (Map)am.invokeMethod("getUserData");

      // 従業員区分が"2":外部ユーザの場合
      String peopleCode = (String)retHashMap.get("PeopleCode");

      // 画面制御のために取得
      OAMessageLovInputBean searchVendorCode =
        (OAMessageLovInputBean)webBean.findChildRecursive(
          "SearchVendorNo");

      if ("2".equals(peopleCode))
      {   
        //項目「取引先」を入力不可に設定
        searchVendorCode.setReadOnly(true);
        searchVendorCode.setCSSClass("OraDataText");
      }
    } else
    {
      // トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(
            pageContext, XxpoConstants.TXN_XXPO370001J, true))
      {
        pageContext.redirectToDialogPage(new OADialogPage(NAVIGATION_ERROR));
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

    // 変数定義
    String vendorCode = null;         // 取引先
    String vendorName = null;         // 取引先名
    String itemCode = null;           // 品目
    String itemName = null;           // 品目名
    String itemId = null;             // 品目ID
    String lotNo = null;              // ロット番号
    String productFactory = null;     // 製造工場
    String productLotNo = null;       // 製造ロット番号
    String productDateFrom = null;    // 製造日/仕入日(自)
    String productDateTo = null;      // 製造日/仕入日(至)
    String creationDateFrom = null;   // 入力日(自)
    String creationDateTo = null;     // 入力日(至)
    String qtInspectReqNo = null;     // 検査依頼No

    String apiName = "ProcessFormRequest";

    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
// del start 1.1
//    // 画面制御のために取得
//    OAMessageStyledTextBean prompt =
//      (OAMessageStyledTextBean)webBean.findChildRecursive("PromptVendor");
// del end 1.1
    // =============================== //
    // =   進むボタンが押下された場合   = //
    // =============================== //
    if (pageContext.getParameter("Go") != null)
    {
      // 必須項目チェック
      am.invokeMethod("searchInputCheck");
      // ********************* //
      // *      検索実行      * //
      // ********************* //
      try
      {
        am.invokeMethod("doSearch");
      } catch (OAException expt) 
      {
        // DBエラーが発生した場合は、エラー画面に遷移する。
        OADialogPage dialogPage =
          new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);      
      }

      // トランザクション終了
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

    // =============================== //
    // =   消去ボタンが押下された場合   = //
    // =============================== //
    } else if (pageContext.getParameter("Clear") != null)
    {
      // トランザクション終了
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // 自画面に遷移(検索画面の再表示)
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchPG",
        XxpoConstants.URL_XXPO370001J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        false,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);

    // =============================== //
    // =   新規ボタンが押下された場合   = //
    // =============================== //
    } else if (pageContext.getParameter("New") != null)
    {
      // トランザクション終了
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // ************************* //
      // * 検査ロット情報登録画面へ * //
      // ************************* //
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG",
        XxpoConstants.URL_XXPO370002J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        false, //retainAM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);

    // =============================== //
    // =  ロット番号をクリックした場合   = //
    // =============================== //
    } else if ("LotNoClick".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      // トランザクション終了
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370001J);

      // ************************* //
      // * 検査ロット情報登録画面へ * //
      // ************************* //
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG",
        XxpoConstants.URL_XXPO370002J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true, //retainAM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);
        
    }
  }
}
