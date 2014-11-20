/*============================================================================
* ファイル名 : XxcsoQuoteStoreRegistCO
* 概要説明   : 帳合問屋用見積入力画面コントローラクラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS及川領    新規作成
* 2009-07-23 1.1  SCS阿部大輔 【0000806】マージン額／マージン率の計算対象変更
* 2009-09-10 1.2  SCS阿部大輔  【0001331】マージン額の計算時にページ遷移を指定
* 2011-04-18 1.3  SCS吉元強樹  【E_本稼動_01373】通常NET価格自動導出対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OADialogPage;
import itoen.oracle.apps.xxcso.xxcso017002j.util.XxcsoQuoteConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
/*******************************************************************************
 * 帳合問屋用見積入力画面のコントローラクラス
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreRegistCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * 画面起動時処理
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    boolean errorMode = false;
    super.processRequest(pageContext, webBean);

    // 登録系お決まり
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URLからパラメータを取得します。
    String quoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String referenceQuoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);
    String tranDiv = 
      pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // AMへ渡す引数を作成します。
    Serializable[] params = {
      quoteHeaderId
     ,referenceQuoteHeaderId
     ,tranDiv
    };

    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    // 第一引数に設定したメソッド名のメソッドをCallします。
    Boolean returnValue = Boolean.TRUE;
    // ***実行区分：コピー
    if ( XxcsoQuoteConstants.TRANDIV_COPY.equals(tranDiv) )
    {
      am.invokeMethod("initDetailsCopy", params);
    }
    // ***実行区分：版の改訂
    else if ( XxcsoQuoteConstants.TRANDIV_REVISION_UP.equals(tranDiv) )
    {
      am.invokeMethod("initDetailsRevisionUp", params);
    }
    // ***実行区分：見積検索画面／販売用見積画面／メニューから遷移
    else
    {
      am.invokeMethod("initDetails", params);      
    }

    // 販売用見積情報設定
    am.invokeMethod("setAttributeProperty");

    // 税区分設定
    am.invokeMethod("setAttributeTaxType", params);

    // ポップリスト初期化
    am.invokeMethod("initPoplist");

/* 20090723_abe_0000806 START*/
    // 問屋明細行表示属性プロパティ設定
    am.invokeMethod("setLineProperty");
/* 20090723_abe_0000806 END*/

    //Tableリージョンの表示行数設定関数    
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"QuoteLineAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_017_A02_01"
        );

    if ( oaeMsg != null )
    {
      pageContext.putDialogMessage(oaeMsg);
      setErrorMode(pageContext, webBean);
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * 画面イベント発生時処理
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");
    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    // URLからパラメータを取得します。
    String quoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String referenceQuoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);
    String returnPgName = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY3);
    String tranDiv = 
      pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // 戻り先画面の設定
    if ( returnPgName == null || "".equals(returnPgName.trim()) )
    {
     // メニュー画面
     if ( tranDiv == null )
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_MENU
       );
     }
     // 見積検索画面
     else if ( XxcsoQuoteConstants.TRANDIV_UPDATE.equals(tranDiv) )
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_SEARCH
       );
     }
     // 販売用見積画面
     else if ( XxcsoQuoteConstants.TRANDIV_CREATE.equals(tranDiv) )
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_SALES
       );
     }
    }
    XxcsoUtils.debug(
      pageContext,
      "戻り先："
      + pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY3)
    );

    // URLからパラメータを再取得します。
    returnPgName = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY3);

    // AMへ渡す引数を作成します。
    Serializable[] pgnameparams = {
      referenceQuoteHeaderId
     ,returnPgName
    };

    // ********************************
    // *****ボタン押下ハンドリング*****
    // ********************************
    // 「取消」ボタン
    if ( pageContext.getParameter("CancelButton") != null )
    {
      //パラメータ値取得
      HashMap params
        = (HashMap)am.invokeMethod("handleCancelButton", pgnameparams);

      if ( XxcsoQuoteConstants.PARAM_MENU.equals(returnPgName) )
      {
        // メニュー画面へ遷移
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_OA_HOME_PAGE,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }

      if ( XxcsoQuoteConstants.PARAM_SEARCH.equals(returnPgName) )
      {
        // 見積検索画面へ遷移
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_QUOTE_SEARCH_PG,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }

      if ( XxcsoQuoteConstants.PARAM_SALES.equals(returnPgName) )
      {

        // 販売用見積画面へ遷移
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          params,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }
    // 「コピーの作成」ボタン
    if ( pageContext.getParameter("CopyCreateButton") != null )
    {
      //パラメータ値取得
      HashMap params
        = (HashMap)am.invokeMethod("handleCopyCreateButton", pgnameparams);
      // 自画面遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // 「無効にする」ボタン
    if ( pageContext.getParameter("InvalidityButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleInvalidityButton");

      // メッセージ設定
      pageContext.putDialogMessage(msg);

      // 自画面遷移
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // 「適用」ボタン
    if ( pageContext.getParameter("ApplicableButton") != null )
    {
      HashMap returnValue
        = (HashMap)am.invokeMethod("handleApplicableButton", pgnameparams);
      HashMap params
        = (HashMap)returnValue.get(XxcsoQuoteConstants.RETURN_PARAM_URL);
      OAException msg
        = (OAException)returnValue.get(XxcsoQuoteConstants.RETURN_PARAM_MSG);

      // メッセージ設定
      pageContext.putDialogMessage(msg);

      // 自画面遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }
    // 「版の改訂」ボタン
    if ( pageContext.getParameter("RevisionButton") != null )
    {
      HashMap params
        = (HashMap)am.invokeMethod("handleRevisionButton", pgnameparams);

      // 自画面遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // 「確定」ボタン
    if ( pageContext.getParameter("FixedButton") != null )
    {
      OAException msg
        = (OAException)am.invokeMethod("handleFixedButton");

      // メッセージ設定
      pageContext.putDialogMessage(msg);

      // 自画面遷移
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // 「見積書印刷」ボタン
    if ( pageContext.getParameter("QuoteSheetPrintButton") != null )
    {
      OAException msg
        = (OAException)am.invokeMethod("handlePdfCreateButton");

      // メッセージ設定
      pageContext.putDialogMessage(msg);

      // 自画面遷移
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // 「CSV作成」ボタン
    if ( pageContext.getParameter("CsvCreateButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleCsvCreateButton");

      // メッセージ設定
      pageContext.putDialogMessage(msg);

      // 自画面遷移
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // ＮＥＴ価格が変更された場合、マージンの算出を行う
    if ( "NetPriceChangeEvent".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
       )
    {
      // URLからパラメータを取得します。
      String quoteLineId = 
        pageContext.getParameter("EventLineId");

      // AMへ渡す引数を作成します。
      Serializable[] params = {
        quoteLineId
      };

      am.invokeMethod("handleMarginCalculation" ,params);
    }
    /* 20090910_abe_0001331 START*/
    else
    {
      // 建値の算出を行う
      am.invokeMethod("handleValidateReference");

      // 販売用見積情報設定
      am.invokeMethod("setAttributeProperty");
      /* 20090723_abe_0000806 START*/
      // 問屋明細行表示属性プロパティ設定
      am.invokeMethod("setLineProperty");
      /* 20090723_abe_0000806 END*/

    }

// 2010-04-18 v1.3 T.Yoshimoto Add Start E_本稼動_01373
    // 「通常NET価格取得」ボタン押下時
    if ( pageContext.getParameter("UsuallNetPriceButton" ) != null )
    {
      // 通常NET価格の取得を行う
      am.invokeMethod("handleUsuallNetPriceButton");

    }
// 2010-04-18 v1.3 T.Yoshimoto Add End E_本稼動_01373

    /* 20090910_abe_0001331 END*/
      String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
      XxcsoUtils.debug(pageContext, "event = " + event);
    XxcsoUtils.debug(pageContext, "[END]");
  }
  /*****************************************************************************
   * 画面をエラーモードに設定します。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  private void setErrorMode(OAPageContext pageContext, OAWebBean webBean)
  {
    webBean.findChildRecursive("CopyCreateButton").setRendered(false);
    webBean.findChildRecursive("InvalidityButton").setRendered(false);
    webBean.findChildRecursive("ApplicableButton").setRendered(false);
    webBean.findChildRecursive("RevisionButton").setRendered(false);
    webBean.findChildRecursive("FixedButton").setRendered(false);
    webBean.findChildRecursive("QuoteSheetPrintButton").setRendered(false);
    webBean.findChildRecursive("CsvCreateButton").setRendered(false);
    webBean.findChildRecursive("MainSlRN").setRendered(false);
  }
}
