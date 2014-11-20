/*============================================================================
* ファイル名 : XxcsoContractRegistCO
* 概要説明   : 自販機設置契約情報登録コントローラクラス
* バージョン : 1.5
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2009-04-09 1.1  SCS柳平直人  [ST障害T1_0327]レイアウト調整処理修正
* 2010-02-09 1.2  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
* 2011-06-06 1.3  SCS桐生和幸  [E_本稼動_01963]新規仕入先作成チェック対応
* 2012-06-12 1.4  SCSK桐生和幸 [E_本稼動_09602]契約取消ボタン追加対応
* 2013-04-01 1.5  SCSK桐生和幸 [E_本稼動_10413]銀行口座マスタ変更チェック追加対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;

import java.io.Serializable;

import java.util.Hashtable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

/*******************************************************************************
 * 契約書検索から受けるパラメータ確認をする画面のコントローラクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRegistCO extends OAControllerImpl
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

    // ダイアログページからの遷移時は即終了
    if ( pageContext.getParameter(XxcsoConstants.TOKEN_ACTION) != null)
    {
// 2009-04-09 [ST障害T1_0327] Add Start
      adjustLayout(pageContext, webBean);

      OAMessageTextInputBean bean
        = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
      bean.setReadOnlyTextArea(true);
      bean.setReadOnly(true);
// 2009-04-09 [ST障害T1_0327] Add End
      return;
    }

    // URLからパラメータを取得します。
    String modeType =
        pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String spDecisionHeaderId = 
        pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String contractManagementId = 
        pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // AMへ渡す引数を作成します。
    Serializable[] params =
    {
       spDecisionHeaderId
      ,contractManagementId
    };

    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    if ( modeType == null || "".equals(modeType) )
    {
      am.invokeMethod("initDetailsCreate", params);
    }
    else if ( XxcsoContractRegistConstants.MODE_UPDATE.equals(modeType) )
    {
      am.invokeMethod("initDetailsUpdate", params);
    }
    else if ( XxcsoContractRegistConstants.MODE_COPY.equals(modeType) )
    {
      am.invokeMethod("initDetailsCopy", params);
    }
    am.invokeMethod("initPopList");
    am.invokeMethod("afterProcess");
    
    am.invokeMethod("setAttributeProperty");

    // レイアウト調整
    adjustLayout(pageContext, webBean);

    OAMessageTextInputBean bean
      = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
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

    // AMインスタンスを取得します。
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
    XxcsoUtils.debug(pageContext, "EVENT = " + event);

    /////////////////////////////////////
    // 取消ボタン
    /////////////////////////////////////
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      //検索画面に遷移
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_CONTRACT_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,null
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    /////////////////////////////////////
    // 適用ボタン
    /////////////////////////////////////
    if ( pageContext.getParameter("ApplyButton") != null )
    {
      am.invokeMethod("handleApplyButton");

      // メッセージの取得
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_SAVE
        );
      }
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add Start

      // 銀行口座存在チェック
      am.invokeMethod("bankAccountCheck");
      // メッセージの取得
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_SAVE2
        );
      }

      // 仕入先存在チェック
      am.invokeMethod("supplierCheck");
      // メッセージの取得
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_SAVE3
        );
      }
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add End

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
      // 銀行口座変更チェック
      am.invokeMethod("bankAccountChangeCheck");
      // メッセージの取得
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN1
        );
      }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
      else
      {
        // AMへのパラメータ作成
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
    }

    /////////////////////////////////////
    // 確定ボタン
    /////////////////////////////////////
    if ( pageContext.getParameter("SubmitButton") != null )
    {
      am.invokeMethod("handleSubmitButton");

      // メッセージの取得
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_DECISION
        );
      }
      else
      {
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add Start

        // 銀行口座存在チェック
        am.invokeMethod("bankAccountCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION2
          );
        }

        // 仕入先存在チェック
        am.invokeMethod("supplierCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION3
          );
        }
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add End

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End

// 2010-02-09 [E_本稼動_01538] Mod Start
        // マスタ連携待ちチェック
        am.invokeMethod("cooperateWaitCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
// 2010-02-09 [E_本稼動_01538] Mod End
          // AMへのパラメータ作成
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
// 2010-02-09 [E_本稼動_01538] Mod Start
        }
// 2010-02-09 [E_本稼動_01538] Mod End
         
      }
    }

    /////////////////////////////////////
    // PDF作成ボタン
    /////////////////////////////////////
    if ( pageContext.getParameter("PrintPdfButton") != null )
    {

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
      // 銀行口座変更チェック
      am.invokeMethod("bankAccountChangeCheck");
      // メッセージの取得
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN3
        );
      }
      else
      {
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End

        HashMap returnMap = (HashMap) am.invokeMethod("handlePrintPdfButton");

        this.redirect(pageContext, returnMap);

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
      }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End

    }
// 2012-06-12 Ver1.4 [E_本稼動_09602] Add Start
    /////////////////////////////////////
    // 契約取消ボタン
    /////////////////////////////////////
    if ( pageContext.getParameter("RejectButton") != null )
    {
      // 契約取消確認
      am.invokeMethod("RejectContract");
      // 確認メッセージの取得
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      //確認メッセージを表示
      this.createConfirmDialog(
        pageContext
       ,confirmMsg
       ,XxcsoConstants.TOKEN_VALUE_REJECT
      );
    }
// 2012-06-12 Ver1.4 [E_本稼動_09602] Add End

    /////////////////////////////////////
    // 確認ダイアログでのOKボタン
    /////////////////////////////////////
    if ( pageContext.getParameter("ConfirmOkButton") != null )
    {
      String actionValue
        = pageContext.getParameter(XxcsoConstants.TOKEN_ACTION);

// 2010-02-09 [E_本稼動_01538] Mod Start
      // 確定ボタン押下処理の場合
      if ( XxcsoConstants.TOKEN_VALUE_DECISION.equals(actionValue) )
      {
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add Start

        // 銀行口座存在チェック
        am.invokeMethod("bankAccountCheck");
        // メッセージの取得
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION2
          );
        }

        // 仕入先存在チェック
        am.invokeMethod("supplierCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION3
          );
        }
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add End

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
         confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End

        // マスタ連携待ちチェック
        am.invokeMethod("cooperateWaitCheck");
        // メッセージの取得
// 2011-06-06 Ver1.3 [E_本稼動_01963] Mod Start
//        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
// 2011-06-06 Ver1.3 [E_本稼動_01963] Mod End
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AMへのパラメータ作成
          Serializable[] params    = { actionValue };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }
      }
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add Start
      // 確定ボタン(銀行口座存在チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_DECISION2.equals(actionValue) )
      {

        // 仕入先存在チェック
        am.invokeMethod("supplierCheck");
        // メッセージの取得
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION3
          );
        }

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End

        // マスタ連携待ちチェック
        am.invokeMethod("cooperateWaitCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AMへのパラメータ作成
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }      
      }
      // 確定ボタン(仕入先存在チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_DECISION3.equals(actionValue) )
      {

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
         OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End

        // マスタ連携待ちチェック
        am.invokeMethod("cooperateWaitCheck");
        // メッセージの取得
// 2013-04-01 Ver1.5 [E_本稼動_10413] Mod Start
//        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
// 2013-04-01 Ver1.5 [E_本稼動_10413] Mod End
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AMへのパラメータ作成
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }      
      }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
      // 確定ボタン(銀行口座変更チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_WARN2.equals(actionValue) )
      {

        // マスタ連携待ちチェック
        am.invokeMethod("cooperateWaitCheck");
        // メッセージの取得
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AMへのパラメータ作成
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }

      }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
      // 適用ボタン(複数顧客指定送付先)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_SAVE.equals(actionValue) )
      {
        // 銀行口座存在チェック
        am.invokeMethod("bankAccountCheck");
        // メッセージの取得
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_SAVE2
          );
        }

        // 仕入先存在チェック
        am.invokeMethod("supplierCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_SAVE3
          );
        }

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN1
          );
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
        else
        {
          // AMへのパラメータ作成
          Serializable[] params    = { actionValue };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);          
        }
      }
      // 適用ボタン(銀行口座存在チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_SAVE2.equals(actionValue) )
      {
        // 仕入先存在チェック
        am.invokeMethod("supplierCheck");
        // メッセージの取得
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_SAVE3
          );
        }

// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN1
          );
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
        else
        {
          // AMへのパラメータ作成
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }
      }
      // 適用ボタン(仕入先存在チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_SAVE3.equals(actionValue) )
      {
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        // 銀行口座変更チェック
        am.invokeMethod("bankAccountChangeCheck");
        // メッセージの取得
         OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN1
          );
        }
        else
        {
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
          // AMへのパラメータ作成
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
        }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
      }
// 2011-06-06 Ver1.3 [E_本稼動_01963] Add End
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
      //適用ボタン(銀行口座変更チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_WARN1.equals(actionValue) )
      {
        // AMへのパラメータ作成
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
      // PDF作成ボタン(銀行口座変更チェック)の場合
      else if ( XxcsoConstants.TOKEN_VALUE_WARN3.equals(actionValue) )
      {

        HashMap returnMap
          = (HashMap) am.invokeMethod("handlePrintPdfButton");

        this.redirect(pageContext, returnMap);

      }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
// 2012-06-12 Ver1.4 [E_本稼動_09602] Add Start
      else if ( XxcsoConstants.TOKEN_VALUE_REJECT.equals(actionValue) )
      {
        // AMへのパラメータ作成
        Serializable[] params    = { actionValue };

        //契約取消処理実行
        HashMap returnMap
          = (HashMap) am.invokeMethod("handleRejectOkButton", params);

        this.redirect(pageContext, returnMap);
      }
// 2012-06-12 Ver1.4[E_本稼動_09602] Add End
      else
      {
// 2010-02-09 [E_本稼動_01538] Mod End
        // AMへのパラメータ作成
        Serializable[] params    = { actionValue };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
// 2010-02-09 [E_本稼動_01538] Mod Start
      }
// 2010-02-09 [E_本稼動_01538] Mod End
    }

// 2010-02-09 [E_本稼動_01538] Mod Start
    /////////////////////////////////////
    // 確認ダイアログでのOKボタン(マスタ連携待ち)
    /////////////////////////////////////
    if ( pageContext.getParameter("ConfirmOkButtonCooperate") != null )
    {
      String actionValue
        = pageContext.getParameter(XxcsoConstants.TOKEN_ACTION);

      // AMへのパラメータ作成
      Serializable[] params    = { actionValue };

      HashMap returnMap
        = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

      this.redirect(pageContext, returnMap);
    }
// 2010-02-09 [E_本稼動_01538] Mod End
    /////////////////////////////////////
    // オーナー変更チェックボックス押下
    /////////////////////////////////////
    if ( "OwnerChangeFlagChange".equals(event) )
    {
      // オーナー変更チェックボックス変更イベント
      am.invokeMethod("handleOwnerChangeFlagChange");
    }

    am.invokeMethod("afterProcess");

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * レイアウトの調整を行います。
   * @param pageContext ページコンテキスト
   * @param webBean     画面情報
   *****************************************************************************
   */
  public void adjustLayout(OAPageContext pageContext, OAWebBean webBean)
  {
    String[] objects = XxcsoContractRegistConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("center");
      }
    }

    objects = XxcsoContractRegistConstants.REQUIRED_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setRequired("uiOnly");
      }
    }
  }

  /*****************************************************************************
   * 確認ダイアログ生成処理
   * @param pageContext ページコンテキスト
   * @param confirmMsg  確認画面表示用メッセージ
   *****************************************************************************
   */
  private void createConfirmDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
   ,String        actionValue
  )
  {
      // ダイアログを生成
      OADialogPage confirmDialog
        = new OADialogPage(
            OAException.CONFIRMATION
           ,confirmMsg
           ,null
           ,""
           ,""
          );
          
      String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
      String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

      confirmDialog.setOkButtonItemName("ConfirmOkButton");
      confirmDialog.setOkButtonToPost(true);
      confirmDialog.setNoButtonToPost(true);
      confirmDialog.setPostToCallingPage(true);
      confirmDialog.setOkButtonLabel(ok);
      confirmDialog.setNoButtonLabel(no);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoConstants.TOKEN_ACTION, actionValue);

      confirmDialog.setFormParameters(param);

      pageContext.redirectToDialogPage(confirmDialog);
  }
// 2010-02-09 [E_本稼動_01538] Mod Start
  /*****************************************************************************
   * 確認ダイアログ生成処理(マスタ連携待ち)
   * @param pageContext ページコンテキスト
   * @param confirmMsg  確認画面表示用メッセージ
   *****************************************************************************
   */
  private void createConfirmDialogCooperate(
    OAPageContext pageContext
   ,OAException   confirmMsg
   ,String        actionValue
  )
  {
      // ダイアログを生成
      OADialogPage confirmDialogCooperate
        = new OADialogPage(
            OAException.CONFIRMATION
           ,confirmMsg
           ,null
           ,""
           ,""
          );
          
      String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
      String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

      confirmDialogCooperate.setOkButtonItemName("ConfirmOkButtonCooperate");
      confirmDialogCooperate.setOkButtonToPost(true);
      confirmDialogCooperate.setNoButtonToPost(true);
      confirmDialogCooperate.setPostToCallingPage(true);
      confirmDialogCooperate.setOkButtonLabel(ok);
      confirmDialogCooperate.setNoButtonLabel(no);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoConstants.TOKEN_ACTION, actionValue);

      confirmDialogCooperate.setFormParameters(param);

      pageContext.redirectToDialogPage(confirmDialogCooperate);
  }
// 2010-02-09 [E_本稼動_01538] Mod End
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add Start
  /*****************************************************************************
   * 警告ダイアログ生成処理(銀行口座変更)
   * @param pageContext ページコンテキスト
   * @param confirmMsg  確認画面表示用メッセージ
   *****************************************************************************
   */
  private void createConfirmDialogWarn(
    OAPageContext pageContext
   ,OAException   confirmMsg
   ,String        actionValue
  )
  {
      // ダイアログを生成
      OADialogPage confirmDialogWarn
        = new OADialogPage(
            OAException.WARNING
           ,confirmMsg
           ,null
           ,""
           ,null //NOボタンの表示なし
          );
          
      String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);

      confirmDialogWarn.setOkButtonItemName("ConfirmOkButton");
      confirmDialogWarn.setOkButtonToPost(true);
      confirmDialogWarn.setPostToCallingPage(true);
      confirmDialogWarn.setOkButtonLabel(ok);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoConstants.TOKEN_ACTION, actionValue);

      confirmDialogWarn.setFormParameters(param);

      pageContext.redirectToDialogPage(confirmDialogWarn);
  }
// 2013-04-01 Ver1.5 [E_本稼動_10413] Add End
  /*****************************************************************************
   * 再表示時処理
   * @param pageContext ページコンテキスト
   * @param HashMap     param設定値
   *****************************************************************************
   */
  private void redirect(
    OAPageContext pageContext
   ,HashMap map
  )
  {

    // 成功メッセージ
    OAException msg
      = (OAException) map.get(XxcsoContractRegistConstants.PARAM_MESSAGE);

    // 次画面遷移するためのパラメータ(値はAM内で設定)
    HashMap urlParams
      = (HashMap) map.get(XxcsoContractRegistConstants.PARAM_URL_PARAM);

    pageContext.removeParameter(XxcsoConstants.TOKEN_ACTION);
    pageContext.putDialogMessage(msg);

    // 画面の再表示を行う
    pageContext.forwardImmediately(
      XxcsoConstants.FUNC_CONTRACT_REGIST_PG
     ,OAWebBeanConstants.KEEP_MENU_CONTEXT
     ,null
     ,urlParams
     ,true
     ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
    );
  }
}
