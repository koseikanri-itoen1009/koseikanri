/*============================================================================
* ファイル名 : XxinvMovementShippedLotCO
* 概要説明   : 出庫ロット明細画面コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
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
/***************************************************************************
 * 出庫ロット明細画面コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementShippedLotCO extends XxcmnOAControllerImpl
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

      // ダイアログ画面のNOボタンが押下された場合
      } else if ((pageContext.getParameter("No") != null)) 
      {
        // 処理を行わない

      // ダイアログ画面のYESボタンが押下された場合
      } else if ((pageContext.getParameter("Yes") != null)) 
      {
        // 登録処理
        am.invokeMethod("entryDataShipped");
        
      // 初期表示の場合
      } else
      {
        // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
        TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510002J);

        // パラメータ取得      
        HashMap searchParams = new HashMap();
        searchParams.put("movLineId",      pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID)); // 移動明細ID
        searchParams.put("productFlg",     pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG));       // 製品識別区分
        searchParams.put("recordTypeCode", XxinvConstants.RECORD_TYPE_20);                                         // レコードタイプ  20：出庫実績
        searchParams.put("updateFlag", pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG));

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
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510002J, true))
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
        
      // 取消ボタンが押下された場合
      } else if (pageContext.getParameter("Return") != null) 
      {
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);        // 実績データ区分
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG);       // 製品識別区分
        String searchlinId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID); // 移動明細ID
        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID);      // 移動ヘッダID
        String peoplecode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);        // 従業員区分
        String updateFlag  = pageContext.getParameter("UpdateFlag");                                // 更新フラグ

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,        actualFlag);  // 実績データ区分
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,       productFlag); // 製品識別区分
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID, searchlinId); // 移動明細ID
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId);      // 移動ヘッダID
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peoplecode);         // 従業員区分
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, XxinvConstants.PROCESS_FLAG_U); // 更新フラグ
        pageParams.put(XxinvConstants.URL_PARAM_PREV_URL, XxinvConstants.URL_XXINV510002J_1); // 画面URL

        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510002J);
          
        // 入出庫実績明細画面へ
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JL,
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
        String retCode = (String)am.invokeMethod("checkError");

        // 警告チェック処理実行
        HashMap msg = (HashMap)am.invokeMethod("checkWarningShipped");

        String[] lotRevErrFlg     = (String[])msg.get("lotRevErrFlg");     // ロット逆転防止チェックエラーフラグ
        String[] minusErrFlg      = (String[])msg.get("minusErrFlg");      // マイナス在庫チェックエラーフラグ 
        String[] exceedErrFlg     = (String[])msg.get("exceedErrFlg");     // 引当可能在庫数超過チェックエラーフラグ
        String[] itemName         = (String[])msg.get("itemName");         // 品目名
        String[] lotNo            = (String[])msg.get("lotNo");            // ロットNo
        String[] shipToLocCode    = (String[])msg.get("shipToLocCode");    // 入庫先コード
        String[] revDate          = (String[])msg.get("revDate");          // 逆転日付
        String[] manufacturedDate = (String[])msg.get("manufacturedDate"); // 製造年月日
        String[] koyuCode         = (String[])msg.get("koyuCode");         // 固有記号
        String[] stock            = (String[])msg.get("stock");            // 手持数量
        String[] shippedLocName   = (String[])msg.get("shippedLocName");   // 出庫先保管倉庫名

        // ダイアログ画面表示用メッセージ
        StringBuffer pageHeaderText = new StringBuffer(100);

        for(int i = 0 ; i < lotRevErrFlg.length ; i++)
        {
          // ロット逆転防止チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(lotRevErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // ロット逆転防止警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_ITEM,     itemName[i]),
                                      new MessageToken(XxinvConstants.TOKEN_LOT,      lotNo[i]),
                                      new MessageToken(XxinvConstants.TOKEN_LOCATION, shipToLocCode[i]),
                                      new MessageToken(XxinvConstants.TOKEN_REVDATE,  revDate[i])};              
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXINV, 
                XxinvConstants.XXINV10130,
                tokens));
          }

          // マイナス在庫チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(minusErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // マイナス在庫チェック警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM,  itemName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,   lotNo[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_DATE,  manufacturedDate[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_MARK,  koyuCode[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_STOCK, stock[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN00026,
                tokens));
          }

          // 引当可能在庫数超過チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(exceedErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // 引当可能在庫数超過チェック警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_LOCATION,  shippedLocName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_ITEM,      itemName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,       lotNo[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN10110,
                tokens));
          }
        }

        // 警告メッセージのある場合、ダイアログを表示
        if (pageHeaderText.length() > 0)
        {
          // メインメッセージ作成 
          MessageToken[] mainTokens = new MessageToken[1];
          mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, pageHeaderText.toString());

          OAException mainMessage = new OAException(
                                          XxcmnConstants.APPL_XXCMN,
                                          XxcmnConstants.XXCMN00025,
                                          mainTokens);

                                            
          // ダイアログメッセージを表示
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxinvConstants.URL_XXINV510002J_1,
            XxinvConstants.URL_XXINV510002J_1,
            "Yes",
            "No",
            "Yes",
            "No",
            null);          
        }
        if (XxcmnConstants.STRING_TRUE.equals(retCode))
        {
          // 登録処理
          am.invokeMethod("entryDataShipped");
        }
      }

    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
