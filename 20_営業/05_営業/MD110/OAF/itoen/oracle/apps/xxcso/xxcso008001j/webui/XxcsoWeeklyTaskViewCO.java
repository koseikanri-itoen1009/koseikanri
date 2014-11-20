/*============================================================================
* ファイル名 : XxcsoWeeklyTaskViewCO
* 概要説明   : 週次活動状況照会コントローラクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-07 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.webui;

import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso008001j.util.XxcsoWeeklyTaskViewConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.io.Serializable;

/*******************************************************************************
 * 週次活動状況照会画面のコントローラクラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoWeeklyTaskViewCO extends OAControllerImpl
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

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    String executeMode = pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String txnKey1 = pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);

    Serializable[] params =
    {
      txnKey1
    };
    
    if ( XxcsoWeeklyTaskViewConstants.MODE_TRANSFER.equals(executeMode) )
    {
      am.invokeMethod("initAfterHandleShowButton", params);
    }
    else
    {
      // 初期表示処理実行
      am.invokeMethod("initDetails");
    }

    // ****************************************
    // *****プロファイル・オプションの設定*****
    // ****************************************
    // リージョン名格納用配列
    String[] regionAdvTbl =
    {
      XxcsoWeeklyTaskViewConstants.RN_EMP_SEL_ADV_TBL
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "01"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "02"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "03"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "04"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "05"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "06"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "07"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "08"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "09"
      ,XxcsoWeeklyTaskViewConstants.RN_TASK_ADV_TBL + "10"
    };

    boolean errorMode = false;
    OAException oaeMsg = null;

    // **FND: ビュー・オブジェクト最大フェッチ・サイズの設定
    for (int i = 0; i < regionAdvTbl.length; i++)
    {
      oaeMsg =
        XxcsoUtils.setAdvancedTableRows(
          pageContext
          ,webBean
          ,regionAdvTbl[i]
          ,XxcsoConstants.VO_MAX_FETCH_SIZE
        );
      if (oaeMsg != null)
      {
        pageContext.putDialogMessage(oaeMsg);
        errorMode = true;
        break;
      }
    }

    // エラーモード設定
    if (errorMode)
    {
      webBean.findChildRecursive("MainSlRN").setRendered(false);
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

    XxcsoUtils.debug(pageContext, "[START]");

    // AMインスタンスの生成
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // ********************************
    // *****ボタン押下ハンドリング*****
    // ********************************
    // 「戻る」ボタン
    if ( pageContext.getParameter("BackButton") != null )
    {
      // メニュー画面へ遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,null
        ,true
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    // 「進む」ボタン
    if ( pageContext.getParameter("ForwardButton") != null )
    {
      am.invokeMethod("handleForwardButton");
    }

    // 「CSV作成」ボタン
    if ( pageContext.getParameter("CsvCreateButton") != null )
    {

      am.invokeMethod("handleCsvCreateButton");

      OAException msg = (OAException)am.invokeMethod("getMessage");
      pageContext.putDialogMessage(msg);

    }

    // 「表示」ボタン
    if ( pageContext.getParameter("ShowButton") != null )
    {
      String urlParam = (String)am.invokeMethod("handleShowButton");
      
      HashMap params = new HashMap(2);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoWeeklyTaskViewConstants.MODE_TRANSFER
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,urlParam
      );

      // AM保持をfalseで自画面遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_WEEKLY_TASK_VIEW_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
      
    }

    // ************************************
    // *****Link押下ハンドリング***********
    // ************************************
    if ( "TaskClick".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)) )
    {
      
      String taskId = pageContext.getParameter("SelectedTaskId");
      String taskOwnerId = pageContext.getParameter("SelectedTaskOwnerId");

      // ログインユーザーのリソースID取得
      String loginResourceId = (String)am.invokeMethod("getLoginResourceId");

      XxcsoUtils.debug(pageContext, "taskId=[" + taskId + "]");
      XxcsoUtils.debug(pageContext, "taskOwnerId=[" + taskOwnerId + "]");
      XxcsoUtils.debug(pageContext, "loginResourceId=[" + loginResourceId + "]");

      // URLパラメータの作成
      HashMap paramMap = new HashMap();
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_TASK_ID
        ,pageContext.encrypt(taskId)
      );
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_TASK_RETURN_URL
        ,pageContext.getCurrentUrlForRedirect()
      );
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_RETURN_LABEL
       ,XxcsoWeeklyTaskViewConstants.PARAM_VALUE_RETURN_LABEL
      );
      
      // 更新・参照モードの設定
      // リソースIDが一致しない場合のみcacTaskUsrAuthを設定
      // ※値はTaskSummと同様に"1"を設定
      if ( !loginResourceId.equals(taskOwnerId) )
      {
        paramMap.put(
          XxcsoWeeklyTaskViewConstants.PARAM_TASK_USER_AUTH
          ,pageContext.encrypt("1")
        );
      }
      paramMap.put(
        XxcsoWeeklyTaskViewConstants.PARAM_BASE_PAGE_REGION_CODE
        ,"/oracle/apps/jtf/cac/task/webui/TaskUpdatePG"
      );

      // タスク画面へ遷移
      pageContext.setForwardURL(
        XxcsoConstants.FUNC_TASK_UPDATE_PG
        ,OAWebBeanConstants.KEEP_MENU_CONTEXT
        ,null
        ,paramMap
        ,false
        ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        ,(byte) 99
      );

    }

    XxcsoUtils.debug(pageContext, "[END]");

  }

}
