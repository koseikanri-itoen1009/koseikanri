/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateCO
* 概要説明   : ルートNo/担当営業員一括更新画面コントローラクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-16 1.0  SCS富尾和基  新規作成
* 2010-03-23 1.1  SCS阿部大輔  [E_本稼動_01942]管理元拠点対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso019009j.util.XxcsoRtnRsrcBulkUpdateConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * ルートNo/担当営業員一括更新画面のコントローラクラス
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");

    // 登録系お決まり
    if (pageContext.isBackNavigationFired(false))
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URLパラメータより実行モードを取得
    String mode = pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    Serializable[] params =
    {
      mode
    };
    
    // 第一引数に設定したメソッド名のメソッドをCallします。
    am.invokeMethod("initDetails", params);

    // ポップリストの初期化
    am.invokeMethod("initPopList");

// 2010-03-23 [E_本稼動_01942] Add Start
    am.invokeMethod("afterProcess");
// 2010-03-23 [E_本稼動_01942] Add End

    // レイアウト調整
    setVAlignMiddle(webBean);

    //Tableリージョンの表示行数設定関数    
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"ResultAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_019_A09_01"
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
    
    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    //進むボタン押下時
    if ( pageContext.getParameter("SearchButton") != null )
    {
      am.invokeMethod("handleSearchButton");
    }

    //消去ボタン押下時
    if ( pageContext.getParameter("ClearButton") != null )
    {
      am.invokeMethod("handleClearButton");
    }

    //追加ボタン押下時
    if ( pageContext.getParameter("AddCustomerButton") != null )
    {
      am.invokeMethod("handleAddCustomerButton");
    }

    //適用ボタン押下時
    if ( pageContext.getParameter("SubmitButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleSubmitButton");
      pageContext.putDialogMessage(msg);

      HashMap params = new HashMap(1);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoRtnRsrcBulkUpdateConstants.MODE_FIRE_ACTION
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_RTN_RSRC_BULK_UPDATE_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    //取消ボタン押下時
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,null
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

// 2010-03-23 [E_本稼動_01942] Add Start
    am.invokeMethod("afterProcess");
// 2010-03-23 [E_本稼動_01942] Add End
    XxcsoUtils.debug(pageContext, "[END]");

  }

  /*****************************************************************************
   * 画面レイアウト調整処理
   * @param webBean     画面情報
   *****************************************************************************
   */
  private void setVAlignMiddle(OAWebBean webBean)
  {
    String[] objects = XxcsoRtnRsrcBulkUpdateConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);

      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("middle");
      }
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
    webBean.findChildRecursive("SearchButton").setRendered(false);
    webBean.findChildRecursive("ClearButton").setRendered(false);
    webBean.findChildRecursive("AddCustomerButton").setRendered(false);
    webBean.findChildRecursive("SubmitButton").setRendered(false);
    webBean.findChildRecursive("CancelButton").setRendered(false);
  }
}
