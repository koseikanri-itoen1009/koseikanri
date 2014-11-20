/*============================================================================
* ファイル名 : XxcsoContractSearchCO
* 概要説明   : 契約書情報検索コントローラクラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS及川領    新規作成
* 2009-02-17 1.1  SCS柳平直人  [CT1内部]確認ダイアログパラメータ修正
* 2009-06-10 1.2  SCS柳平直人  [ST障害T1_1317]明細チェック最大件数対応
* 2010-02-09 1.3  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010001j.util.XxcsoContractConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/*******************************************************************************
 * 契約書情報を検索する画面のコントローラクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractSearchCO extends OAControllerImpl
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

    //Tableリージョンの表示行数設定関数
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,XxcsoContractConstants.REGION_NAME
         ,XxcsoContractConstants.VIEW_SIZE
        );

    if ( oaeMsg != null )
    {
      pageContext.putDialogMessage(oaeMsg);
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
    XxcsoUtils.debug(pageContext, "[START]");

    super.processFormRequest(pageContext, webBean);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }
    //戻るボタン
    if ( pageContext.getParameter("ReturnButton") != null )
    {
      //メニュー画面に遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,null
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    //進むボタン
    if ( pageContext.getParameter("SearchButton") != null )
    {
// 2009-06-10 [ST障害T1_1317] Mod Start
//      am.invokeMethod("executeSearch");
      OAException oaMessage
        = (OAException) am.invokeMethod("executeSearch");
      if (oaMessage != null)
      {
        pageContext.putDialogMessage(oaMessage);
      }
// 2009-06-10 [ST障害T1_1317] Mod End

    }

    //消去ボタン
    if ( pageContext.getParameter("ClearButton") != null )
    {
      am.invokeMethod("handleClearButton");
    }

    //契約書作成ボタン
    if ( pageContext.getParameter("CreateButton") != null )
    {
      //参照ＳＰ専決番号チェック
      Boolean returnValue = (Boolean)am.invokeMethod("spHeaderCheck");

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
        //パラメータ値取得
        HashMap params = (HashMap)am.invokeMethod("getUrlParamNew");
        //登録更新画面に遷移
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_CONTRACT_REGIST_PG
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,params
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }

    //コピー作成ボタン
    if ( pageContext.getParameter("CopyButton") != null )
    {
      // AMへ渡す引数を作成します。
      Serializable[] mode =
      {
        XxcsoContractConstants.CONSTANT_COM_KBN1
      };
      //明細選択チェック
      Boolean returnValue = (Boolean)am.invokeMethod("selCheck",mode);

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
// 2010-02-09 [E_本稼動_01538] Mod Start
        // 取消済契約書チェック
        returnValue = (Boolean)am.invokeMethod("cancelContractCheck");
        if ( ! returnValue.booleanValue() )
        {
          OAException msg = (OAException)am.invokeMethod("getMessage");
          pageContext.putDialogMessage(msg);
        }
        else
        {
// 2010-02-09 [E_本稼動_01538] Mod End
          //パラメータ値取得
          HashMap params = (HashMap)am.invokeMethod("getUrlParamCopy");
          //登録更新画面に遷移
          pageContext.forwardImmediately(
            XxcsoConstants.FUNC_CONTRACT_REGIST_PG
           ,OAWebBeanConstants.KEEP_MENU_CONTEXT
           ,null
           ,params
           ,true
           ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
          );
// 2010-02-09 [E_本稼動_01538] Mod Start
        }
// 2010-02-09 [E_本稼動_01538] Mod End
      }
    }

    //詳細ボタン
    if ( pageContext.getParameter("DetailsButton") != null )
    {
      // AMへ渡す引数を作成します。
      Serializable[] mode =
      {
        XxcsoContractConstants.CONSTANT_COM_KBN2
      };
      //明細選択チェック
      Boolean returnValue = (Boolean)am.invokeMethod("selCheck", mode);

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
// 2010-02-09 [E_本稼動_01538] Mod Start
        // 取消済契約書チェック
        returnValue = (Boolean)am.invokeMethod("cancelContractCheck");
        if ( ! returnValue.booleanValue() )
        {
          OAException msg = (OAException)am.invokeMethod("getMessage");
          pageContext.putDialogMessage(msg);
        }
        else
        {
// 2010-02-09 [E_本稼動_01538] Mod End
          // マスタ連携チェック
          returnValue = (Boolean)am.invokeMethod("cooperateCheck");
          if ( ! returnValue.booleanValue() )
          {
            OAException confirmMsg = (OAException)am.invokeMethod("getMessage");

            this.createConfirmDetailsDialog(
              pageContext
             ,confirmMsg
            );
          }
          else
          {
// 2010-02-09 [E_本稼動_01538] Mod Start
            // 最新契約書チェック
            returnValue = (Boolean)am.invokeMethod("latestContractCheck");
            if ( ! returnValue.booleanValue() )
            {
              OAException confirmMsg = (OAException)am.invokeMethod("getMessage");

              this.createConfirmLatestContractDialog(
                pageContext
               ,confirmMsg
              );
            }
            else
            {
// 2010-02-09 [E_本稼動_01538] Mod End
              //パラメータ値取得
              HashMap params = (HashMap)am.invokeMethod("getUrlParamDetails");
              //登録更新画面に遷移
              pageContext.forwardImmediately(
                XxcsoConstants.FUNC_CONTRACT_REGIST_PG
               ,OAWebBeanConstants.KEEP_MENU_CONTEXT
               ,null
               ,params
               ,true
               ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
              );
// 2010-02-09 [E_本稼動_01538] Mod Start
            }
          }
// 2010-02-09 [E_本稼動_01538] Mod End
        }
      }
    }

    //PDF作成ボタン
    if ( pageContext.getParameter("PdfButton") != null )
    {
      // AMへ渡す引数を作成します。
      Serializable[] mode =
      {
        XxcsoContractConstants.CONSTANT_COM_KBN3
      };
      //明細選択チェック
      Boolean returnValue = (Boolean)am.invokeMethod("selCheck",mode);

      if ( ! returnValue.booleanValue() )
      {
        OAException msg = (OAException)am.invokeMethod("getMessage");
        pageContext.putDialogMessage(msg);
      }
      else
      {
// 2010-02-09 [E_本稼動_01538] Mod Start
        // 取消済契約書チェック
        returnValue = (Boolean)am.invokeMethod("cancelContractCheck");
        if ( ! returnValue.booleanValue() )
        {
          OAException msg = (OAException)am.invokeMethod("getMessage");
          pageContext.putDialogMessage(msg);
        }
        else
        {
// 2010-02-09 [E_本稼動_01538] Mod End
          // マスタ連携チェック
          returnValue = (Boolean)am.invokeMethod("cooperateCheck");
          if ( ! returnValue.booleanValue() )
          {
            OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
          
            this.createConfirmPdfDialog(
              pageContext
             ,confirmMsg
            );
          }
          else
          {
            // PDF処理をCALL
            am.invokeMethod("handlePdfCreateButton");
          }
// 2010-02-09 [E_本稼動_01538] Mod Start
        }
// 2010-02-09 [E_本稼動_01538] Mod End
      }
    }

    // 確認ダイアログでのOKボタン（PDF）
    if ( pageContext.getParameter("ConfirmPdfOkButton") != null )
    {
      am.invokeMethod("handleConfirmPdfOkButton");
    }

    // 確認ダイアログでのOKボタン（詳細）
    if ( pageContext.getParameter("ConfirmDetailsOkButton") != null )
    {
      //パラメータ値取得
      HashMap params = (HashMap)am.invokeMethod("getUrlParamDetails");
      //登録更新画面に遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_CONTRACT_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
// 2010-02-09 [E_本稼動_01538] Mod Start
    // 確認ダイアログでのOKボタン（最新契約書）
    if ( pageContext.getParameter("ConfirmLatestContractOkButton") != null )
    {
      //パラメータ値取得
      HashMap params = (HashMap)am.invokeMethod("getUrlParamDetails");
      //登録更新画面に遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_CONTRACT_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
// 2010-02-09 [E_本稼動_01538] Mod End
    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * 確認ダイアログ生成処理（PDF）
   * @param pageContext ページコンテキスト
   * @param confirmMsg  確認画面表示用メッセージ
   *****************************************************************************
   */
  private void createConfirmPdfDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");
    // ダイアログを生成
    OADialogPage confirmPdfDialog
      = new OADialogPage(
          OAException.CONFIRMATION
         ,confirmMsg
         ,null
         ,""
         ,""
        );
          
    String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
    String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

    confirmPdfDialog.setOkButtonItemName("ConfirmPdfOkButton");
    confirmPdfDialog.setOkButtonToPost(true);
    confirmPdfDialog.setNoButtonToPost(true);
    confirmPdfDialog.setPostToCallingPage(true);
    confirmPdfDialog.setOkButtonLabel(ok);
    confirmPdfDialog.setNoButtonLabel(no);

    pageContext.redirectToDialogPage(confirmPdfDialog);

    XxcsoUtils.debug(pageContext, "[END]");
  }
  /*****************************************************************************
   * 確認ダイアログ生成処理（詳細）
   * @param pageContext ページコンテキスト
   * @param confirmMsg  確認画面表示用メッセージ
   *****************************************************************************
   */
  private void createConfirmDetailsDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");
    // ダイアログを生成
    OADialogPage confirmDetailsDialog
      = new OADialogPage(
          OAException.CONFIRMATION
         ,confirmMsg
         ,null
         ,""
         ,""
        );
          
    String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
    String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

    confirmDetailsDialog.setOkButtonItemName("ConfirmDetailsOkButton");
    confirmDetailsDialog.setOkButtonToPost(true);
    confirmDetailsDialog.setNoButtonToPost(true);
    confirmDetailsDialog.setPostToCallingPage(true);
    confirmDetailsDialog.setOkButtonLabel(ok);
    confirmDetailsDialog.setNoButtonLabel(no);

    pageContext.redirectToDialogPage(confirmDetailsDialog);

    XxcsoUtils.debug(pageContext, "[END]");
  }
// 2010-02-09 [E_本稼動_01538] Mod Start
  /*****************************************************************************
   * 確認ダイアログ生成処理（最新契約書）
   * @param pageContext ページコンテキスト
   * @param confirmMsg  確認画面表示用メッセージ
   *****************************************************************************
   */
  private void createConfirmLatestContractDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");
    // ダイアログを生成
    OADialogPage confirmLatestContractDialog
      = new OADialogPage(
          OAException.CONFIRMATION
         ,confirmMsg
         ,null
         ,""
         ,""
        );
          
    String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
    String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

    confirmLatestContractDialog.setOkButtonItemName("ConfirmLatestContractOkButton");
    confirmLatestContractDialog.setOkButtonToPost(true);
    confirmLatestContractDialog.setNoButtonToPost(true);
    confirmLatestContractDialog.setPostToCallingPage(true);
    confirmLatestContractDialog.setOkButtonLabel(ok);
    confirmLatestContractDialog.setNoButtonLabel(no);

    pageContext.redirectToDialogPage(confirmLatestContractDialog);

    XxcsoUtils.debug(pageContext, "[END]");
  }
// 2010-02-09 [E_本稼動_01538] Mod End

}
