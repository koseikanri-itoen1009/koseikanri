/*============================================================================
* ファイル名 : XxwshStockLotInputCO
* 概要説明   : 入出荷実績ロット入力画面(入庫実績)コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-09 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * 入出荷実績ロット入力画面(入庫実績)コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxwshStockLotInputCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
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

    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下していない場合
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // チェックボタンが押下された場合
      if ((pageContext.getParameter("Check") != null) ||
          (pageContext.getParameter("Check1") != null)) 
      {
        // 処理を行わない。

      // 適用ボタンが押下された場合
      } else if ((pageContext.getParameter("Go") != null)) 
      {
        // 処理を行わない
        
      // 初期表示の場合
      } else
      {
        // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
        TransactionUnitHelper.startTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920001J);

        // パラメータ取得      
        HashMap searchParams = new HashMap();
        searchParams.put("orderLineId",      pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID));           // 受注明細アドオンID
        searchParams.put("callPictureKbn",   pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN));  // 呼出画面区分
        searchParams.put("headerUpdateDate", pageContext.getParameter(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE));// ヘッダ更新日時
        searchParams.put("lineUpdateDate",   pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE));  // 明細更新日時
        searchParams.put("exeKbn",           pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN));           // 起動区分
        searchParams.put("recordTypeCode",   XxwshConstants.RECORD_TYPE_STOC);                                      // レコードタイプ 30:入庫実績

        // 引数設定
        Serializable params[] = { searchParams };
        // 引数型設定
        Class[] parameterTypes = { HashMap.class };
        // 初期処理実行
        am.invokeMethod("initialize", params, parameterTypes);
      }
            
    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwshConstants.TXN_XXWSH920001J, true))
      { 
        // 【共通処理】エラーダイアログ画面へ遷移
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {

    try
    {     
      super.processFormRequest(pageContext, webBean);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
     
      // 行挿入ボタン押下された場合
      if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 行追加処理実行
        am.invokeMethod("addRow");

      // 支給指示画面へ戻るボタンが押下された場合
      } else if (pageContext.getParameter("Return") != null) 
      {
        String callPictureKbn = pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN); // 呼出画面区分
        String exeKbn         = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);          // 起動区分
        String url            = null;

        // 依頼No取得
        Serializable params[] = { pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID) };
        String reqNo          = (String)am.invokeMethod("getReqNo", params); // 依頼No
        
        // URL決定
        // 呼出画面区分が2:支給指示作成画面の場合
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO440001JL; // 支給指示作成明細画面          

        // 呼出画面区分が4:出庫実績画面の場合
        } else if (XxwshConstants.CALL_PIC_KBN_DELI.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO441001JL; // 出庫実績入力明細画面

        // 呼出画面区分が5:入庫実績画面の場合
        } else if (XxwshConstants.CALL_PIC_KBN_STOC.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO442001JL; // 入庫実績入力明細画面
        }
        
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,  exeKbn); // 起動区分
        pageParams.put(XxwshConstants.URL_PARAM_REQ_NO,   reqNo);  // 依頼No

        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920001J);
          
        // 支給指示画面へ
        pageContext.setForwardURL(
          url,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // チェックボタンが押下された場合
      } else if ((pageContext.getParameter("Check") != null) ||
                  (pageContext.getParameter("Check1") != null)) 
      {
        // ロットチェック処理実行
        am.invokeMethod("checkLot");

      // 適用ボタンが押下された場合
      } else if (pageContext.getParameter("Go") != null)
      {
        // ロットチェック処理実行
        am.invokeMethod("checkLot");
        
        // エラーチェック処理実行
        String entryFlag = (String)am.invokeMethod("checkError");

        // 処理対象行がある場合、処理続行
        if ("1".equals(entryFlag))
        {
          // 登録処理
          am.invokeMethod("entryStockData");
        }
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}

