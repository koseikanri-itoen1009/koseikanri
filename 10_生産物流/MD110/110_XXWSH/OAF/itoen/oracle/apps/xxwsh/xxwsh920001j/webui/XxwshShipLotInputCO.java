/*============================================================================
* ファイル名 : XxwshShipLotInputCO
* 概要説明   : 入出荷実績ロット入力画面(出荷実績)コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.webui;

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
/***************************************************************************
 * 入出荷実績ロット入力画面(出荷実績)コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxwshShipLotInputCO extends XxcmnOAControllerImpl
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
        am.invokeMethod("entryShipData");
        
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
        searchParams.put("recordTypeCode",   XxwshConstants.RECORD_TYPE_DELI);                                      // レコードタイプ 20:出庫実績

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

        // 呼出画面区分が6:支給返品画面の場合
        } else if (XxwshConstants.CALL_PIC_KBN_RETURN.equals(callPictureKbn))
        {
          url = XxpoConstants.URL_XXPO443001JL; // 支給返品明細画面
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
          // 警告チェック処理実行
          HashMap msg = (HashMap)am.invokeMethod("checkWarning");

          String[] lotRevErrFlg     = (String[])msg.get("lotRevErrFlg");     // ロット逆転防止チェックエラーフラグ
          String[] minusErrFlg      = (String[])msg.get("minusErrFlg");      // マイナス在庫チェックエラーフラグ 
          String[] exceedErrFlg     = (String[])msg.get("exceedErrFlg");     // 引当可能在庫数超過チェックエラーフラグ
          String[] itemName         = (String[])msg.get("itemName");         // 品目名
          String[] lotNo            = (String[])msg.get("lotNo");            // ロットNo
          String[] delivery         = (String[])msg.get("delivery");         // 出荷先(コード)
          String[] revDate          = (String[])msg.get("revDate");          // 逆転日付
          String[] manufacturedDate = (String[])msg.get("manufacturedDate"); // 製造年月日
          String[] koyuCode         = (String[])msg.get("koyuCode");         // 固有記号
          String[] stock            = (String[])msg.get("stock");            // 手持数量
          String[] warehouseName    = (String[])msg.get("warehouseName");    // 保管場所

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
              MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_ITEM,     itemName[i]),
                                        new MessageToken(XxwshConstants.TOKEN_LOT,      lotNo[i]),
                                        new MessageToken(XxwshConstants.TOKEN_LOCATION, delivery[i]),
                                        new MessageToken(XxwshConstants.TOKEN_REVDATE,  revDate[i])};              
              pageHeaderText.append(
                pageContext.getMessage(
                  XxcmnConstants.APPL_XXWSH, 
                  XxwshConstants.XXWSH33301,
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
              MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_LOCATION,  warehouseName[i]),
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
              XxwshConstants.URL_XXWSH920001J_1,
              XxwshConstants.URL_XXWSH920001J_1,
              "Yes",
              "No",
              "Yes",
              "No",
              null);          
          }
        
          // 登録処理
          am.invokeMethod("entryShipData"); 
        }
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}

