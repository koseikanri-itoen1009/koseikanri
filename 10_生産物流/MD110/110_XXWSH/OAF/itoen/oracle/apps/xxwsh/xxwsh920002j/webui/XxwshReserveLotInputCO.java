/*============================================================================
* ファイル名 : XxwshReserveLotInputCO
* 概要説明   : 仮引当ロット入力画面コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  北寒寺   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

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

import oracle.jbo.domain.Date;

/***************************************************************************
 * 仮引当ロット入力画面コントローラクラスです。
 * @author  ORACLE 北寒寺 正夫
 * @version 1.0
 ***************************************************************************
 */
public class XxwshReserveLotInputCO extends XxcmnOAControllerImpl
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
      // AMの取得(ダイアログ画面のYESボタンが押下された場合使用するためここで取得)
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // 一括解除ボタンが押下された場合
      if (pageContext.getParameter("Cancel") != null)
      {
        // 処理を行わない。

      // 計算ボタンが押下された場合
      } else if (pageContext.getParameter("Calc") != null)
      {
        // 処理を行わない

      // 適用ボタンが押下された場合
      } else if (pageContext.getParameter("Apply") != null)
      {
        // 処理を行わない

      // 支給指示画面に戻るボタンが押下された場合
      } else if (pageContext.getParameter("Return") != null)
      {
        // 処理を行わない

      // ダイアログ画面のNOボタンが押下された場合
      } else if (pageContext.getParameter("No") != null)
      {
        //Noボタン押下処理（ロック解除処理を実行)
        am.invokeMethod("noBtn");

      // ダイアログ画面のYESボタンが押下された場合
      } else if (pageContext.getParameter("Yes") != null)
      {
        // 登録処理
        am.invokeMethod("yesBtn");
        
      // 初期表示の場合
      } else
      {
        // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
        TransactionUnitHelper.startTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920002J);

        // パラメータ取得      
        HashMap searchParams = new HashMap();
        searchParams.put("LineId",           pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID));           // 受注明細アドオンID
        searchParams.put("callPictureKbn",   pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN));  // 呼出画面区分
        searchParams.put("headerUpdateDate", pageContext.getParameter(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE));// ヘッダ更新日時
        searchParams.put("lineUpdateDate",   pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE));  // 明細更新日時
        searchParams.put("exeKbn",           pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN));           // 起動区分
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
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwshConstants.TXN_XXWSH920002J, true))
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
     
      // 支給指示画面へ戻るボタンが押下された場合
      if (pageContext.getParameter("Return") != null) 
      {
        String callPictureKbn = pageContext.getParameter(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN); // 呼出画面区分
        String exeKbn         = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);          // 起動区分
        String url            = XxpoConstants.URL_XXPO440001JL;                                      // 支給指示作成明細画面

        // 依頼No取得
        Serializable params[] = { pageContext.getParameter(XxwshConstants.URL_PARAM_LINE_ID) };
        String reqNo          = (String)am.invokeMethod("getReqNo"); // 依頼No
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,  exeKbn); // 起動区分
        pageParams.put(XxwshConstants.URL_PARAM_REQ_NO,   reqNo);  // 依頼No

        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwshConstants.TXN_XXWSH920002J);
          
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

      // 一括解除ボタンが押下された場合
      } else if ((pageContext.getParameter("Cancel") != null))    
      {
        // 一括解除処理実行
        am.invokeMethod("cancelBtn");

      // 計算ボタンが押下された場合
      } else if ((pageContext.getParameter("Calc") != null))    
      {
        // 計算処理実行
        am.invokeMethod("calcBtn");
      // 適用ボタンが押下された場合
      } else if (pageContext.getParameter("Apply") != null)
      {
        // 適用ボタン処理を実行
        am.invokeMethod("applyBtn");
       
        /*****************************************/
        /*    警告チェック処理                     */
        /*****************************************/
        HashMap msg = (HashMap)am.invokeMethod("checkWarning");
        // 取得した変数を格納
        String[] lotRevErrFlg   = (String[])msg.get("lotRevErrFlg");                       // ロット逆転防止チェックエラーフラグ
        String[] freshErrFlg    = (String[])msg.get("freshErrFlg");                        // 鮮度条件チェックエラーフラグ
        String[] shortageErrFlg = (String[])msg.get("shortageErrFlg");                     // 引当可能在庫数減数チェックエラーフラグ
        String[] exceedErrFlg   = (String[])msg.get("exceedErrFlg");                       // 引当可能在庫数超過チェックエラーフラグ
        String[] lotNo          = (String[])msg.get("lotNo");                              // ロットNo
        Date[] revDate          = (Date[])msg.get("revDate");                              // 逆転日付
        Date[] standardDate     = (Date[])msg.get("standardDate");                         // 基準日
        String[] shipType       = (String[])msg.get("shipType");                           // ShipType
        String[] itemShortName  = (String[])msg.get("itemShortName");                      // 品目名
        String[] deliverTo      = (String[])msg.get("deliverTo");                          // 出庫先
        String[] locationName   = (String[])msg.get("locationName");                       // 出庫元保管場所
        

        // ダイアログ画面表示用メッセージ
        StringBuffer pageHeaderText = new StringBuffer(100);

        // ロット逆転防止チェックエラーフラグの件数分ループ実行
        for (int i = 0 ; i < lotRevErrFlg.length ; i++)
        {
          // ロット逆転防止チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(lotRevErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // ロット逆転防止警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_ITEM,     itemShortName[i]),
                                      new MessageToken(XxwshConstants.TOKEN_LOT,      lotNo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_SHIP_TYPE,shipType[i]),
                                      new MessageToken(XxwshConstants.TOKEN_LOCATION, deliverTo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_ARRIVAL_DATE,  XxcmnUtility.stringValue(revDate[i]))};
            pageHeaderText.append(
              pageContext.getMessage(
              XxcmnConstants.APPL_XXWSH, 
              XxwshConstants.XXWSH32901,
              tokens));
          }

          // 鮮度条件チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(freshErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // ロット逆転防止警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_LOT,      lotNo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_SHIP_TO,  deliverTo[i]),
                                      new MessageToken(XxwshConstants.TOKEN_ARRIVAL_DATE,  XxcmnUtility.stringValue(standardDate[i]))};
            pageHeaderText.append(
              pageContext.getMessage(
              XxcmnConstants.APPL_XXWSH, 
              XxwshConstants.XXWSH32902,
              tokens));
          }

          // 引当可能在庫数減数チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(shortageErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // 引当可能在庫数減数チェック警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_LOCATION, locationName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_ITEM,  itemShortName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,   lotNo[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN10112,
                tokens));
          }

          // 引当可能在庫数超過チェックでエラーの場合
          if (XxcmnConstants.STRING_Y.equals(exceedErrFlg[i]))
          {
            // 警告メッセージが複数存在する場合、改行コードを追加
            XxcmnUtility.newLineAppend(pageHeaderText);

            // 引当可能在庫数超過チェック警告メッセージ取得
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_LOCATION,  locationName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_ITEM,      itemShortName[i]),
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
            XxwshConstants.URL_XXWSH920002JH,
            XxwshConstants.URL_XXWSH920002JH,
            "Yes",
            "No",
            "Yes",
            "No",
            null);          
        }
        // 登録処理
        am.invokeMethod("yesBtn");
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }

}
