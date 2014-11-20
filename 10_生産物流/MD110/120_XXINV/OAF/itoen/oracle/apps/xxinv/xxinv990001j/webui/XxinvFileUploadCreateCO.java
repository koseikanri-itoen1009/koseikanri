/*============================================================================
* ファイル名 : XxinvFileUploadCreateCO
* 概要説明   : CSVファイルアップロードコントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-23 1.0  高梨雅史     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv990001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;

import oracle.cabo.ui.data.DataObject;


/**
 * ファイルアップロードコントローラ。
 * @author  ORACLE 高梨　雅史
 * @version 1.0
 */
public class XxinvFileUploadCreateCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxinv/xxinv990001j/webui/XxinvFileUploadCreateCO.java,v 1.3 2008/02/21 04:51:01 usr3149 Exp $";
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
    // ブラウザ「戻る」ボタンの対応
    if (!pageContext.isBackNavigationFired(false))
    {
      TransactionUnitHelper.startTransactionUnit(pageContext, 
                                                XxinvConstants.TXN_XXINV990001J);
      // パラメータ取得(ファイル交換方式コード)
      String contentType = pageContext.getParameter(XxinvConstants.XXINV990001J_PARAM);

      if (contentType == null)
      {
        // システムエラー
        // 設定の不備によって発生するエラー。エラー画面に遷移させる。
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      // アプリケーションモジュールの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      String meaning = null;
      try {
        // 参照タイプよりコンカレント名称およびフォーマットパターンを取得する。
        Serializable[] params = {XxinvConstants.LOOKUP_TYPE, contentType};
        meaning = (String)am.invokeMethod("getLookUpValue", params);
        // 格納用レコード作成
        am.invokeMethod("createXxinvMrpFileUlInterfaceRec");
      } catch (OAException ex) 
      {
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
        // DBエラーが発生した場合は、エラー画面に遷移する。
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      // ヘッダー項目タイトル
      OAPageLayoutBean plRN = (OAPageLayoutBean)webBean;
      // Window Titleおよびページ名称の設定。
      StringBuffer dispBuf = new StringBuffer();
      dispBuf.append(XxinvConstants.DISP_TEXT);
      dispBuf.append(meaning);
      plRN.setTitle(dispBuf.toString());
      plRN.setWindowTitle(dispBuf.toString());

    } else
    {
      // ブラウザ「戻る」ボタンに対応
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, 
                                                             XxinvConstants.TXN_XXINV990001J, 
                                                             true))
      {
        // 戻るボタンが押下されている場合の処理。
        OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
    }
  } // end processRequest

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    // ApplicationModuleの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    // 適用ボタンの判断
    if (pageContext.getParameter("Apply") != null)
    {
      // コンテントタイプの取得
      String contentType = pageContext.getParameter("LookupCode");
       // コンカレントプログラム名称の取得
      String programName = pageContext.getParameter("Description");
      // ファイル名称の取得
      String fileName = pageContext.getParameter("FileData");
      if (fileName == null || programName == null || contentType == null)
      {
        // ファイル名が指定されていない。
        throw new OAException(XxcmnConstants.APPL_XXINV,
                              "APP-XXINV-10048",
                              null,
                              OAException.ERROR,
                              null);
      }
      // ファイル名の指定の有無をチェックする。
      DataObject data = (DataObject)pageContext.getNamedDataObject("FileData");
      if (data == null)
      {
        // ロールバックする。
        am.invokeMethod("rollbackXxinvMrpFileUlInterface");
        throw new OAException(XxcmnConstants.APPL_XXINV,
                              "APP-XXINV-10048",
                              null,
                              OAException.ERROR,
                              null);
      }
      // 引数設定
      Serializable params[] = {fileName, contentType};
      // 引数型設定
      Class[] parameterTypes = {String.class, String.class};
      // 戻り値定義
      long retVal = 0;
      try {
        // VOに設定。
        am.invokeMethod("setUlFileInfo", params, parameterTypes);
        // コミット。
        am.invokeMethod("apply");
        // コンカレントを起動する。
        params = new Serializable[] {programName, contentType};
        Serializable[] returnObj = {am.invokeMethod("concRun", params)};
        retVal = ((Long)returnObj[0]).longValue();
      } catch (OAException ex) 
      {
        // ロールバックする。
        am.invokeMethod("rollbackXxinvMrpFileUlInterface");
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
        // DBエラーが発生した場合は、エラー画面に遷移する。
        OADialogPage dialogPage = new OADialogPage(FAILOVER_STATE_LOSS_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }
      if (retVal == 0)
      {
        TransactionUnitHelper.endTransactionUnit(pageContext, 
          XxinvConstants.TXN_XXINV990001J);
        // コンカレントを起動できない場合の処理を記述する。
        MessageToken[] tokens = { new MessageToken("PROGRAM", programName)};
        OAException ex1 = new OAException(XxcmnConstants.APPL_XXINV,
                                          "APP-XXINV-10005",
                                          tokens,
                                          OAException.ERROR,
                                          null);
        // エラーメッセージを設定する。
        pageContext.putDialogMessage(ex1);
        HashMap map = new HashMap();
        map.put(XxinvConstants.XXINV990001J_PARAM, contentType);
        // 同一ページへ遷移する。
        pageContext.forwardImmediately(
          APPLICATION_JSP + "?page=/itoen/oracle/apps/xxinv/xxinv990001j/webui/XxinvFileUploadPG",
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          map,
          true, // retain AM 
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

      } else
      {
        // コミット。
        am.invokeMethod("apply");
      }
      TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV990001J);
      // 完了メッセージ作成
      MessageToken[] tokens = { new MessageToken("PROGRAM", programName),
                                new MessageToken("ID",      String.valueOf(retVal))};
      OAException confirmMess = new OAException(XxcmnConstants.APPL_XXINV,
                                                "APP-XXINV-10006",
                                                tokens,
                                                OAException.CONFIRMATION,
                                                null);
      pageContext.putDialogMessage(confirmMess);
      HashMap map = new HashMap();
      map.put(XxinvConstants.XXINV990001J_PARAM, contentType);
      // 同一ページに遷移する。
      pageContext.forwardImmediately(
        APPLICATION_JSP + "?page=/itoen/oracle/apps/xxinv/xxinv990001j/webui/XxinvFileUploadPG",
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        map,
        true, // retain AM
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    } else if (pageContext.getParameter("Cancel") != null)
    {
      TransactionUnitHelper.endTransactionUnit(pageContext,
                                               XxinvConstants.TXN_XXINV990001J);
      // ロールバックする。
      am.invokeMethod("rollbackXxinvMrpFileUlInterface");
      // ホームへ遷移する。
      pageContext.forwardImmediately(XxcmnConstants.URL_OAHOMEPAGE,
                                     GUESS_MENU_CONTEXT,
                                     null,
                                     null,
                                     false, // Do not retain AM
                                     ADD_BREAD_CRUMB_NO);
    }
  } // end processFormRequest
}
