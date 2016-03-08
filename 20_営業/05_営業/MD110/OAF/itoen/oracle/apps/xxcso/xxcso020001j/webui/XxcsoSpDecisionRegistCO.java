/*============================================================================
* ファイル名 : XxcsoSpDecisionSearchCO
* 概要説明   : SP専決登録画面コントローラクラス
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS小川浩    新規作成
* 2009-03-23 1.1  SCS柳平直人  [ST障害T1_0163]課題No.115取り込み
* 2009-08-24 1.2  SCS阿部大輔  [SCS障害0001104]申請区分チェック対応
* 2015-01-30 1.3  SCSK桐生和幸 [E_本稼動_12565]SP・契約書画面改修対応
* 2016-01-07 1.4  SCSK山下翔太 [E_本稼動_13456]自販機管理システム代替対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.domain.BlobDomain;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.cabo.ui.data.DataObject;

/*******************************************************************************
 * SP専決登録画面のコントローラクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionRegistCO extends OAControllerImpl
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

    String executeMode
      = XxcsoUtils.getUrlParameter(pageContext, XxcsoConstants.EXECUTE_MODE);
    String spDecisionHeaderId
      = XxcsoUtils.getUrlParameter(
          pageContext, XxcsoConstants.TRANSACTION_KEY1
        );

    XxcsoUtils.debug(pageContext, "ExecuteMode     = " + executeMode);
    XxcsoUtils.debug(pageContext, "TransactionKey1 = " + spDecisionHeaderId);

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // ポップリストの初期化
    am.invokeMethod("initPopList");

    Serializable[] params =
    {
      spDecisionHeaderId
    };

    if ( XxcsoSpDecisionConstants.COPY_MODE.equals(executeMode) )
    {
      am.invokeMethod("initCopyDetails", params);
    }
    else
    {
      // 機能の初期化
      am.invokeMethod("initDetails", params);
    }

    // 表示／非表示、入力可能／不可能の設定
    am.invokeMethod("setAttributeProperty");
    
    // レイアウト調整
    adjustLayout(pageContext, webBean);

    XxcsoUtils.setAdvancedTableRows(
      pageContext
     ,webBean
     ,"SalesConditionAdvTblRN"
     ,"XXCSO1_VIEW_SIZE_020_A01_01"
    );
    
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

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
    XxcsoUtils.debug(pageContext, "EVENT = " + event);

    ////////////////////////////////////////
    // ボタンイベント
    ////////////////////////////////////////
    if ( pageContext.getParameter("ApplyButton") != null )
    {
      // 摘用ボタン押下イベント
      HashMap returnValue = (HashMap)am.invokeMethod("handleApplyButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());

      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
          XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,params
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    if ( pageContext.getParameter("CancelButton") != null )
    {
      // 取消ボタン押下イベント
      String searchClass
        = pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

      if ( searchClass == null || "".equals(searchClass) )
      {
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_OA_HOME_PAGE
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,null
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
      else
      {
        String forwardPage = XxcsoConstants.FUNC_SP_DECISION_SEARCH_PG1;
        if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(searchClass) )
        {
          forwardPage = XxcsoConstants.FUNC_SP_DECISION_SEARCH_PG2;
        }
        
        pageContext.forwardImmediately(
          forwardPage
         ,OAWebBeanConstants.KEEP_MENU_CONTEXT
         ,null
         ,null
         ,true
         ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }

    }

    if ( pageContext.getParameter("SubmitButton") != null )
    {
      // 提出ボタン押下イベント
      HashMap returnValue = (HashMap)am.invokeMethod("handleSubmitButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("RejectButton") != null )
    {
      // 否決ボタン押下イベント
      HashMap returnValue = (HashMap)am.invokeMethod("handleRejectButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ApproveButton") != null )
    {
      // 承認ボタン押下イベント
      HashMap returnValue = (HashMap)am.invokeMethod("handleApproveButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ReturnButton") != null )
    {
      // 返却ボタン押下イベント
      HashMap returnValue = (HashMap)am.invokeMethod("handleReturnButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    if ( pageContext.getParameter("ConfirmButton") != null )
    {
      // 確認ボタン押下イベント
      HashMap returnValue = (HashMap)am.invokeMethod("handleConfirmButton");

      HashMap params
        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
      OAException msg
        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);

      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
      );

      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
      
      pageContext.putDialogMessage(msg);
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
// 2016-01-07 [E_本稼動_13456] Del Start
//    if ( pageContext.getParameter("RequestButton") != null )
//    {
//      // 発注依頼ボタン押下イベント
//      HashMap returnValue = (HashMap)am.invokeMethod("handleRequestButton");
//
//      HashMap params
//        = (HashMap)returnValue.get(XxcsoSpDecisionConstants.PARAM_URL_PARAM);
//      OAException msg
//        = (OAException)returnValue.get(XxcsoSpDecisionConstants.PARAM_MESSAGE);
//
//      params.put(
//        XxcsoConstants.TRANSACTION_KEY2
//        ,pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2)
//      );
//
//      XxcsoUtils.debug(pageContext, "URL PARAM = " + params.toString());
//      
//      pageContext.putDialogMessage(msg);
//      pageContext.forwardImmediately(
//        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
//       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
//       ,null
//       ,params
//       ,true
//       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
//      );
//    }
// 2016-01-07 [E_本稼動_13456] Del End
    
    if ( pageContext.getParameter("ScCalcButton") != null )
    {
      // 定価換算率計算（売価別条件）ボタン押下イベント
      am.invokeMethod("handleScCalcButton");
    }
    
    if ( pageContext.getParameter("ScAddRowButton") != null )
    {
      // 行追加（売価別条件）ボタン押下イベント
      am.invokeMethod("handleScAddRowButton");
    }
    
    if ( pageContext.getParameter("ScDelRowButton") != null )
    {
      // 行削除（売価別条件）ボタン押下イベント
      am.invokeMethod("handleScDelRowButton");
    }

    if ( pageContext.getParameter("AllCcCalcButton") != null )
    {
      // 定価換算率計算（全容器）ボタン押下イベント
      am.invokeMethod("handleAllCcCalcButton");
    }
    
    if ( pageContext.getParameter("SelCcCalcButton") != null )
    {
      // 定価換算率計算（全容器以外）ボタン押下イベント
      am.invokeMethod("handleSelCcCalcButton");
    }

    if ( pageContext.getParameter("ReflectContractButton") != null )
    {
      // 情報反映ボタン押下イベント
      am.invokeMethod("handleReflectContractButton");
    }
    
    if ( pageContext.getParameter("CalcProfitButton") != null )
    {
      // 概算年間損益計算ボタン押下イベント
      am.invokeMethod("handleCalcProfitButton");
    }
    
    if ( pageContext.getParameter("AttachAddButton") != null )
    {
      // 添付追加ボタン押下イベント
      DataObject fileUploadData = 
        (DataObject)pageContext.getNamedDataObject("AttachFileUp");

      if ( fileUploadData == null )
      {
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00005
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_FILE_NAME
          );
      }
      
      String fileName
        = (String)fileUploadData.selectValue(null, "UPLOAD_FILE_NAME");

      if ( fileName == null || "".equals(fileName.trim()) )
      {
        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00005
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_FILE_NAME
          );
      }

      BlobDomain fileData
        = (BlobDomain)fileUploadData.selectValue(null, fileName);

      Serializable[] params =
      {
        fileName
       ,fileData
      };
      Class[] classes =
      {
        String.class
       ,BlobDomain.class
      };

      am.invokeMethod("handleAttachAddButton", params, classes);

      // 2009-08-24 [障害0001104] Add Start
      // 添付の初期化
      fileUploadData = null;
      pageContext.putNamedDataObject("AttachFileUp",fileUploadData);
      // 2009-08-24 [障害0001104] Add End
    }

    if ( pageContext.getParameter("AttachDelButton") != null )
    {
      // 添付削除ボタン押下イベント
      am.invokeMethod("handleAttachDelButton");
    }
    
    ////////////////////////////////////////
    // 部分ページレンダリングイベント
    ////////////////////////////////////////
    if ( "ApplicationTypeChange".equals(event) )
    {
      // 申請区分変更イベント
      // レンダリングのみ
    }

    if ( "NewoldTypeChange".equals(event) )
    {
      // 新台／旧台変更イベント
      // レンダリングのみ
    }

// 2015-01-30 [E_本稼動_12565] Del Start
//    if ( "ElectricityTypeChange".equals(event) )
//    {
//      // 電気代区分変更イベント
//// 2009-03-23 [ST障害T1_0163] Mod Start
////      // レンダリングのみ
////      am.invokeMethod("handleElectricityTypeChange");
//// 2009-03-23 [ST障害T1_0163] Mod End
//    }
// 2015-01-30 [E_本稼動_12565] Del End

// 2015-01-30 [E_本稼動_12565] Add Start
    if ( "AdAssetsTypeChange".equals(event) )
    {
      // 行政財産使用変更イベント
      am.invokeMethod("handleAdAssetsTypeChange");
    }

    if ( "InstallSuppTypeChange".equals(event) )
    {
      // 支払区分（設置協賛金）変更イベント
      am.invokeMethod("handleInstallSuppTypeChange");
    }

    if ( "InstallSuppPaymentTypeChange".equals(event) )
    {
      // 支払方法（設置協賛金）変更イベント
      am.invokeMethod("handleInstallSuppPaymentTypeChange");
    }

    if ( "ElectricTypeChange".equals(event) )
    {
      // 支払区分（電気代区分）変更更イベント
      am.invokeMethod("handleElectricTypeChange");
    }

    if ( "ElectricPaymentTypeChange".equals(event) )
    {
      // 支払方法（電気代）変更イベント
      am.invokeMethod("handleElectricPaymentTypeChange");
    }

    if ( "IntroChgTypeChange".equals(event) )
    {
      // 支払区分（紹介手数料）変更イベント
      am.invokeMethod("handleIntroChgTypeChange");
    }

    if ( "IntroChgPaymentTypeChange".equals(event) )
    {
      // 支払方法（紹介手数料）変更イベント
      am.invokeMethod("handleIntroChgPaymentTypeChange");
    }

// 2015-01-30 [E_本稼動_12565] Add End

    if ( "BusinessConditionTypeChange".equals(event) )
    {
      // 業態（小分類）変更イベント
      // レンダリングのみ
    }
    
    if ( "SameInstallAccountFlagChange".equals(event) )
    {
      // 設置先と同じチェックボックス変更イベント
      am.invokeMethod("handleSameInstallAccountFlagChange");
    }

    if ( "ConditionBusinessTypeChange".equals(event) )
    {
      // 取引条件選択変更イベント
      am.invokeMethod("handleConditionBusinessTypeChange");
    }

    if ( "AllContainerTypeChange".equals(event) )
    {
      // 全容器区分変更イベント
      am.invokeMethod("handleConditionBusinessTypeChange");
    }

    if ( "Bm1SendTypeChange".equals(event) )
    {
      // 送付先変更イベント
      am.invokeMethod("handleBm1SendTypeChange");
    }
    
    if ( "Bm1PaymentTypeChange".equals(event) )
    {
      // 支払条件・明細書（BM1）変更イベント
      am.invokeMethod("handleBm1PaymentTypeChange");
    }

    if ( "Bm2PaymentTypeChange".equals(event) )
    {
      // 支払条件・明細書（BM2）変更イベント
      am.invokeMethod("handleBm2PaymentTypeChange");
    }

    if ( "Bm3PaymentTypeChange".equals(event) )
    {
      // 支払条件・明細書（BM3）変更イベント
      am.invokeMethod("handleBm3PaymentTypeChange");
    }

    ////////////////////////////////////////
    // 後処理
    ////////////////////////////////////////
    am.invokeMethod("afterProcess");
    
    // 表示／非表示、入力可能／不可能の設定
    am.invokeMethod("setAttributeProperty");
    
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
    String[] objects = XxcsoSpDecisionConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findIndexedChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("middle");
      }
    }

    objects = XxcsoSpDecisionConstants.REQUIRED_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findIndexedChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setRequired("uiOnly");
      }
    }

    objects = XxcsoSpDecisionConstants.READONLY_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findIndexedChildRecursive(objects[i]);
      if ( bean instanceof OAMessageTextInputBean )
      {
        ((OAMessageTextInputBean)bean).setReadOnlyTextArea(true);
        ((OAMessageTextInputBean)bean).setReadOnly(true);
      }
    }
  }
}
