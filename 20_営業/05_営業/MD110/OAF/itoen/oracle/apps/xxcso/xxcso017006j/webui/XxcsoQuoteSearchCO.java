/*============================================================================
* ファイル名 : XxcsoQuoteSearchCO
* 概要説明   : 見積検索コントローラクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS張吉      新規作成
* 2012-09-10 1.1  SCSK穆宏旭  【E_本稼動_09945】見積書の照会方法の変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.webui;

import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso017006j.util.XxcsoQuoteSearchConstants;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * 見積を検索する画面のコントローラクラスです。
 * @author  SCS張吉
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearchCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * 画面起動時の処理を行います。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");
    
    super.processRequest(pageContext, webBean);

    // お決まり
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }
    //初期化処理
    am.invokeMethod("initDetails");
    
    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * 画面イベントの処理を行います。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");
    
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    // 2012-09-10 Ver1.1 [E_本稼動_09945] Add Start
    // プロファイル(XXCSO:見積検索基準)値を取得
    String profileSearchStandard = pageContext.getProfile(
      XxcsoQuoteSearchConstants.XXCSO1_QUOTE_STANDARD);
    // 2012-09-10 Ver1.1 [E_本稼動_09945] Add End

    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // 進むボタン
    if ( pageContext.getParameter("SearchButton") != null )
    {
      XxcsoUtils.debug(pageContext, "[SearchButton]");
      // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod Start
      //HashMap retMap = (HashMap)am.invokeMethod("executeSearch");
      String[] params = {profileSearchStandard};
      HashMap retMap = (HashMap)am.invokeMethod("executeSearch", params);
      // 2012-09-10 Ver1.1 [E_本稼動_09945] Mod End
      XxcsoUtils.debug(pageContext, 
        "QuoteHeaderID : " + retMap.get(XxcsoConstants.TRANSACTION_KEY1));

      // 見積種別を取得
      String quoteType = (String)am.invokeMethod("getQuoteType");
      // 遷移先
      String forwardId = null;

      // 販売先用見積入力画面に遷移
      if ( XxcsoQuoteSearchConstants.QUOTE_TYPE_1.equals(quoteType) ) 
      {
        forwardId = XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG;
      }
      // 帳合問屋先用見積入力画面に遷移
      else 
      {
        forwardId = XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG;
      }
      
      // 見積入力画面に遷移
      pageContext.forwardImmediately(
        forwardId,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        retMap,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // 消去ボタン
    if ( pageContext.getParameter("ClearButton") != null )
    {
      XxcsoUtils.debug(pageContext, "[ClearButton]");
      am.invokeMethod("ClearBtn");
    }

    // 戻るボタン
    if ( pageContext.getParameter("ReturnButton") != null )
    {
      XxcsoUtils.debug(pageContext, "[ReturnButton]");
      
      //メニュー画面に遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    XxcsoUtils.debug(pageContext, "[END]");
  }
}
