/*============================================================================
* ファイル名 : XxcsoPvRegistCO
* 概要説明   : パーソナライズビュー作成画面コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonUtils;

import java.io.Serializable;

import java.util.ArrayList;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;


/*******************************************************************************
 * パーソナライズビュー作成画面のコントローラクラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvRegistCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");

    // 登録系お決まり
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    Boolean returnValue = Boolean.TRUE;

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URLからパラメータを取得します。
    String execMode
      =  pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // 初期表示用引数の設定
    Serializable[] params = { viewId, pvDisplayMode };
    // **********************
    // 実行区分により処理分岐
    // **********************
    // 新規作成***************
    if ( XxcsoPvCommonConstants.EXECUTE_MODE_CREATE.equals(execMode) )
    {      
      am.invokeMethod("initCreateDetails", params);
    }
    // 複製***************
    else if ( XxcsoPvCommonConstants.EXECUTE_MODE_COPY.equals(execMode) )
    {
      returnValue = (Boolean) am.invokeMethod("initCopyDetails", params);
    }
    // 更新***************
    else if ( XxcsoPvCommonConstants.EXECUTE_MODE_UPDATE.equals(execMode) )
    {
      returnValue = (Boolean) am.invokeMethod("initUpdateDetails", params);
    }
    // 上記以外はエラーモードとする
    else
    {
      returnValue = Boolean.FALSE;
    }

    // 初期表示設定状態によりエラーモード設定
    if ( !returnValue.booleanValue() )
    {
      this.setErrorMode(pageContext, webBean);
    }

    // ****************************************
    // *****プロファイル・オプションの設定*****
    // ****************************************
    boolean errorMode = false;

    // **FND: ビュー・オブジェクト最大フェッチ・サイズの設定
    OAException oaeMsg =
      XxcsoUtils.setAdvancedTableRows(
        pageContext
        ,webBean
        ,XxcsoPvCommonConstants.EXTRACT_CONDITION_ADV_TBL_RN
        ,XxcsoConstants.VO_MAX_FETCH_SIZE
      );
    if (oaeMsg != null)
    {
      pageContext.putDialogMessage(oaeMsg);
      errorMode = true;
    }

    if ( errorMode )
    {
      this.setErrorMode(pageContext, webBean);
    }

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
    super.processFormRequest(pageContext, webBean);

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // 汎用検索表示区分
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);

    // ********************************
    // *****ボタン押下ハンドリング*****
    // ********************************
    // 「取消」ボタン
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // パーソナライズビュー表示画面へ遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    // 「適用および検索実行」ボタン
    if ( pageContext.getParameter("AppliAndSearchButton") != null )
    {
      // AM呼び出しの引数を生成
      ArrayList trailingList = this.getTrailingListValues(pageContext, webBean);
      Serializable[] params    = { trailingList };
      Class[]        paramType = { ArrayList.class };

      // AMの実行
      // 登録／複製／更新対象のviewIDを取得する
      String targetViewId
        = (String)
            am.invokeMethod("handleAppliAndSearchButton", params, paramType);

      // メッセージ
      OAException msg = (OAException)am.invokeMethod("getMessage");
      // 遷移先画面へのメッセージの設定
      XxcsoUtils.setDialogMessage(pageContext, msg);

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_QUERY
           ,pvDisplayMode
           ,targetViewId
          );

      // 物件情報汎用検索表示画面へ遷移
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // 「適用」ボタン
    if ( pageContext.getParameter("ApplicationButton") != null )
    {
      // AM呼び出しの引数を生成
      ArrayList trailingList = this.getTrailingListValues(pageContext, webBean);
      Serializable[] params    = { trailingList };
      Class[]        paramType = { ArrayList.class };

      am.invokeMethod("handleApplicationButton", params, paramType);

      // メッセージの取得
      OAException msg = (OAException)am.invokeMethod("getMessage");
      // 遷移先画面へのメッセージの設定
      XxcsoUtils.setDialogMessage(pageContext, msg);

      // URLパラメータの作成
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,null
          );

      // 物件情報汎用検索表示画面へ遷移
      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // 「追加」ボタン
    if ( pageContext.getParameter("AddtionButton") != null )
    {
      am.invokeMethod("handleAddtionButton");
    }

    // 「削除」ボタン
    if ( pageContext.getParameter("DeleteButton") != null )
    {
      am.invokeMethod("handleDeleteButton");
    }

  }

  /*****************************************************************************
   * 画面をエラーモードに設定します。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  private void setErrorMode(OAPageContext pageContext, OAWebBean webBean)
  {
    webBean.findChildRecursive("AppliAndSearchButton").setRendered(false);
    webBean.findChildRecursive("Spacer").setRendered(false);
    webBean.findChildRecursive("ApplicationButton").setRendered(false);
    webBean.findChildRecursive("MainSlRN").setRendered(false);
  }

  /*****************************************************************************
   * shuttleリージョンのtrailingの値を取得します。
   * @param  pageContext ページコンテキスト
   * @param  webBean     画面情報
   * @return trailingのvalue値(画面で選択された順序)
   *****************************************************************************
   */
  private ArrayList getTrailingListValues(
    OAPageContext pageContext
    ,OAWebBean webBean
  )
  {
    String value = pageContext.getParameter("LineOrderStlRN:trailing:items");
    String[] valArr = value.split(";");
    ArrayList list = new ArrayList(200);
    for (int i = 0; i < valArr.length; i++)
    {
      // 0件時を考慮しnull・空文字チェック
      if (valArr[i] != null && !"".equals(valArr[i])) 
      {
        list.add(valArr[i]);
      }
    }

    return list;
  }

}
