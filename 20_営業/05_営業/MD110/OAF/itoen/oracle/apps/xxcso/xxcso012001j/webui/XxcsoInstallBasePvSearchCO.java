/*============================================================================
* ファイル名 : XxcsoInstallBasePvSearchCO
* 概要説明   : 物件情報汎用検索画面コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS柳平直人  新規作成
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
import java.util.Hashtable;
import java.util.List;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADataBoundValueFireActionURL;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBeanData;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.cabo.ui.data.DictionaryData;

/*******************************************************************************
 * 物件情報汎用検索画面のコントローラクラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSearchCO extends OAControllerImpl
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

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    XxcsoUtils.debug(pageContext, "[START]");

    // URLからパラメータを取得します。
    String execMode
      =  pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // 遷移元画面からのメッセージを取得し、設定する
    XxcsoUtils.showDialogMessage(pageContext);

    // ポップリストの初期化を行う
    OAMessageChoiceBean choiceBean
      = (OAMessageChoiceBean) webBean.findChildRecursive("ViewName");
    if ( choiceBean != null) 
    {
      choiceBean.setPickListCacheEnabled(false);
    }

    // 実行区分により処理判別
    // 初期表示
    if ( execMode == null || "".equals(execMode.trim()) )
    {
      // 初期表示処理
      am.invokeMethod("initDetails");
    }
    // パーソナライズビュー作成画面「適用および検索実行」
    else if ( XxcsoPvCommonConstants.EXECUTE_MODE_QUERY.equals(execMode) )
    {
      Serializable[] param1 = { viewId };
      // 初期表示設定
      am.invokeMethod("initQueryDetails", param1);

      // 表示行数取得処理
      String viewSize = (String) am.invokeMethod("getViewSize", param1);

      Serializable[] param2 = { viewId, pvDisplayMode };
      // 検索実行
      List searchList
        = (ArrayList) am.invokeMethod("getInstallBaseData", param2);

      // メッセージ
      OAException msg = (OAException)am.invokeMethod("getMessage");
      if (msg != null)
      {
        pageContext.putDialogMessage(msg);
      }

      // 物件汎用検索情報生成
      this.createInstallBasePv(
        pageContext
       ,webBean
       ,searchList
       ,viewSize
      );

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

    XxcsoUtils.debug(pageContext, "[START]");

    // URLからパラメータを取得します。
    String execMode
      =  pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // ********************************
    // *****ボタン押下ハンドリング*****
    // ********************************
    // 「進む」ボタン
    if ( pageContext.getParameter("ForwardButton") != null )
    {
      String selViewId = (String) am.invokeMethod("handleForwardButton");

      // 取得したviewidをquerystringに設定し、自画面遷移
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_QUERY
           ,pvDisplayMode
           ,selViewId
          );

      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // 「パーソナライズ」ボタン
    if ( pageContext.getParameter("PersonalizeButton") != null )
    {
      String selViewId = (String) am.invokeMethod("handlePersonalizeButton");

      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,selViewId
          );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // ********************************
    // *****Icon(image)押下ハンドリング
    // ********************************
    // 更新アイコン
    if ( XxcsoPvCommonConstants.IMAGE_ACTION_NAME.equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
    )
    {
      String instanceId
        = pageContext.getParameter(
            XxcsoPvCommonConstants.IMAGE_FIRE_ACTION_NAME
          );

      HashMap paramMap = new HashMap(3);
      paramMap.put("CsietInstance_ID", instanceId);
      paramMap.put("CsifpbPageBeanMODE", "0");
      paramMap.put("CsifpbPageEvent", "0");

      // IB画面への遷移
      pageContext.forwardImmediately(
         XxcsoConstants.FUNC_CSI_SEARCH_PROD
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * 物件汎用検索情報表示列設定処理
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   * @param list        表示列情報 List->Map
   *****************************************************************************
   */
  private void createInstallBasePv(
    OAPageContext pageContext
   ,OAWebBean     webBean
   ,List          list
   ,String        viewSize
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");

    // Tableリージョンを作成する親リージョンの情報を取得
    // webBean -> cellformat
    OACellFormatBean cellformatBean
      = (OACellFormatBean)
          webBean.findChildRecursive(
            XxcsoPvCommonConstants.RN_TABLE_LAYOUT_CELL0301
          );

    // Tableリージョンの存在チェック
    OATableBean tableBeanOld
      = (OATableBean)
          cellformatBean.findChildRecursive(
            XxcsoPvCommonConstants.RN_TABLE
          );

    // 存在する場合は削除する
    if ( tableBeanOld != null ) 
    {
      int tableIndex
        = pageContext.findChildIndex(
            cellformatBean
           ,XxcsoPvCommonConstants.RN_TABLE
          );

      cellformatBean.removeIndexedChild(tableIndex);
    }

    // Tableリージョンの作成;
    OATableBean tableBean
      = (OATableBean)
          createWebBean(
            pageContext
           ,OAWebBeanConstants.TABLE_BEAN
           ,null
           ,XxcsoPvCommonConstants.RN_TABLE
          );

    // 表示行数の設定
    tableBean.setNumberOfRowsDisplayed(Integer.parseInt(viewSize));
    // 幅の設定
    tableBean.setWidth(XxcsoPvCommonConstants.TABLE_WIDTH);
    DictionaryData tableFormat = new DictionaryData();
    // Tableの書式設定
    if (tableFormat != null)
    {
      // bandingの設定
      tableFormat.put(TABLE_BANDING_KEY, ROW_BANDING);
      tableBean.setTableFormat(tableFormat);
    }

    // 表示列数文messageStyledTextを追加する
    int listSize = list.size();
    for (int i = 0; i < listSize; i++)
    {
      HashMap map = (HashMap) list.get(i);

      // *****************
      // messageStyledText
      // *****************
      OAMessageStyledTextBean msgStyledTxt
        = (OAMessageStyledTextBean)
             createWebBean(
                pageContext
               ,OAWebBeanConstants.MESSAGE_STYLED_TEXT_BEAN
               ,null
               ,(String)map.get(XxcsoPvCommonConstants.KEY_ID)
              );

      // プロンプト
      msgStyledTxt.setPrompt(
        (String) map.get(XxcsoPvCommonConstants.KEY_NAME)
      );
      // ビューインスタンス名
      msgStyledTxt.setViewUsageName(XxcsoPvCommonConstants.VIEW_NAME);
      // ビュー属性
      msgStyledTxt.setViewAttributeName(
        (String) map.get(XxcsoPvCommonConstants.KEY_ATTR_NAME)
      );
      // データ型
      msgStyledTxt.setDataType(
        (String) map.get(XxcsoPvCommonConstants.KEY_DATA_TYPE)
      );

      tableBean.addIndexedChild(msgStyledTxt);
    }

    // 詳細イメージの追加
    // *****************
    // image
    // *****************
    OAImageBean imageBean
      = (OAImageBean)
           createWebBean(
              pageContext
             ,OAWebBeanConstants.IMAGE_BEAN
             ,null
             ,"detail"
            );
    // ラベル名
    imageBean.setLabel(             XxcsoPvCommonConstants.IMAGE_LABEL );
    // ビューインスタンス名
    imageBean.setViewUsageName(     XxcsoPvCommonConstants.VIEW_NAME );
    // ビュー属性名
    imageBean.setViewAttributeName( XxcsoPvCommonConstants.IMAGE_VIEW_ATTR );
    // imageのソース
    imageBean.setSource(            XxcsoPvCommonConstants.IMAGE_SOURCE );
    // onmouseover時のバルーンヘルプ
    imageBean.setShortDesc(         XxcsoPvCommonConstants.IMAGE_SHORT_DESC );
    // imageの高さ
    imageBean.setHeight(            XxcsoPvCommonConstants.IMAGE_HEIGHT );
    // imageの幅
    imageBean.setWidth(             XxcsoPvCommonConstants.IMAGE_WIDTH );

    // fireActionの設定
    Hashtable params = new Hashtable(1);
    params.put("param1", pageContext.getRootRegionCode());

    Hashtable paramWithBinds = new Hashtable(1);
    paramWithBinds.put(
      XxcsoPvCommonConstants.IMAGE_FIRE_ACTION_NAME
     ,new OADataBoundValueFireActionURL(
        (OAWebBeanData) webBean
       ,XxcsoPvCommonConstants.IMAGE_FIRE_ACTION_PARAM
      )
    );
    imageBean.setFireActionForSubmit(
      XxcsoPvCommonConstants.IMAGE_ACTION_NAME
     ,params
     ,paramWithBinds
     ,false
     ,false
    );

    tableBean.addIndexedChild(imageBean);
      
    // 現在のページに追加する
    cellformatBean.addIndexedChild(tableBean);

    XxcsoUtils.debug(pageContext, "[END]");

  }
}
