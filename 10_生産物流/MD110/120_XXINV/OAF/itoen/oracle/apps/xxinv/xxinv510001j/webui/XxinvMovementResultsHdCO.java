/*============================================================================
* ファイル名 : XxinvMovementResultsHdCO
* 概要説明   : 入出庫実績ヘッダ:検索コントローラ
* バージョン : 1.6
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  大橋孝郎     新規作成
* 2008-07-25 1.1  山本恭久     不具合指摘事項修正
* 2008-08-18 1.2  山本恭久     内部変更#157対応、ST#249対応
* 2008-09-24 1.3  伊藤ひとみ   内部変更#157のバグ対応
* 2008-10-21 1.4  伊藤ひとみ   統合テスト 指摘353対応
* 2009-12-28 1.5  伊藤ひとみ   本稼動障害#695
* 2010-02-18 1.6  伊藤ひとみ   E_本稼動_01612
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.common.MessageToken;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import java.util.Hashtable;
import java.io.Serializable;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * 入出庫実績ヘッダ:検索コントローラです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.6
 ***************************************************************************
 */
public class XxinvMovementResultsHdCO extends XxcmnOAControllerImpl
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

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
    // 前画面URL取得
    String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);
    String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // ヘッダID
// 2008/08/18 v1.2 Y.Yamamoto Mod End
    
    // 【共通処理】ブラウザ「戻る」ボタンチェック 戻るボタンを押下していない場合
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
      TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
      // 前画面URL取得
//      String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);
// 2008/08/18 v1.2 Y.Yamamoto Mod End

      // ダイアログYESボタン押下時
      if (pageContext.getParameter("yesBtn") != null)
      {
        // 更新処理(正常(更新有)：MovHdrId、正常(更新無)：TRUE、エラー：FALSE)
        String retCode = (String)am.invokeMethod("UpdateHdr");

        // 正常終了の場合、コミット処理
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;
          // 正常終了(更新有)の場合(MovHdrId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode))
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }
          
          //【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
          // コミット
          am.invokeMethod("doCommit");

// 2008/09/24 H.Itou Add Start
          // ****************** //
          // * ヘッダVO再検索 * //
          // ****************** //
          Serializable pDoSearchHdr[] = { searchHdrId }; // doSearchHdrの引数設定

          am.invokeMethod("doSearchHdr", pDoSearchHdr);  // ヘッダVO検索実行
// 2008/09/24 H.Itou Add End
          // 正常終了(更新有)の場合
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag))
          {
            // OA例外リストを生成します。
            ArrayList exceptions = new ArrayList(100);
// 2009-12-28 H.Itou Del Start 本稼動障害#695
//            // コンカレント：移動入出庫実績登録処理発行
//            HashMap retParams = new HashMap();
//            retParams = (HashMap)am.invokeMethod("doMovActualMake");
//
//            // コンカレントが正常終了した場合
//            if (XxcmnConstants.RETURN_SUCCESS.equals((String)retParams.get("retFlag")))
//            {
//              // メッセージトークン取得
//              MessageToken[] tokens = new MessageToken[2];
//              tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
//              tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID, retParams.get("requestId").toString());
//              exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
//                                              XxinvConstants.XXINV10006,
//                                              tokens,
//                                              OAException.INFORMATION,
//                                              null));
//  
//            }
// 2009-12-28 H.Itou Del Start 本稼動障害#695
            // 更新処理完了MSGを設定し、自画面遷移
            exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                   XxinvConstants.XXINV10158, 
                                   null, 
                                   OAException.INFORMATION, 
                                   null));
            // メッセージを出力し、処理終了
            if (exceptions.size() > 0)
            {
              OAException.raiseBundledOAException(exceptions);
            }
          }

        // 正常終了でない場合、ロールバック
        } else
        {
          //【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
          am.invokeMethod("doRollBack");
        }

      // ダイアログNOボタン押下時
      } else if (pageContext.getParameter("noBtn") != null)
      {
        // 何もしない(再表示)
      // ダイアログYESボタン押下時
      } else if (pageContext.getParameter("yesNextBtn") != null)
      {
        // 何もしない(再表示)
      
      } else if (pageContext.getParameter("noNextBtn") != null)
      {
        // 何もしない(再表示)

      // 次へボタン押下時
      } else if (pageContext.getParameter("Next") != null)
      {
        // 何もしない(再表示)
// 2010-02-18 H.Itou ADD START E_本稼動_01612 ロックエラー時に入力項目をリフレッシュしてしまうので処理追加。
      // ********************************* //
      // *      適用ボタン押下時         * //
      // ********************************* //
      } else if (pageContext.getParameter("Go") != null)
      {
        // 何もしない(再表示)
// 2010-02-18 H.Itou ADD END
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//      } else if (!XxinvConstants.URL_XXINV510001JL.equals(prevUrl))
      } else if (XxinvConstants.URL_XXINV510001JS.equals(prevUrl))
// 2008/08/18 v1.2 Y.Yamamoto Mod End
      {

        // 前画面の値取得
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // 従業員区分
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // 実績データ区分
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // 製品識別区分
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // ヘッダID
// 2008/08/18 v1.2 Y.Yamamoto Mod End
        String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG); // 更新フラグ

        // 商品区分の取得
        String itemClass  = pageContext.getProfile("XXCMN_ITEM_DIV_SECURITY");

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
        HashMap searchParamsHd = new HashMap();
        searchParamsHd.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        searchParamsHd.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        searchParamsHd.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        searchParamsHd.put(XxinvConstants.URL_PARAM_ITEM_CLASS, itemClass);
        searchParamsHd.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);

        // 引数設定
        Serializable setParamsHd[] = { searchParamsHd };
        // initializeの引数型設定
        Class[] parameterTypesHd = { HashMap.class };
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//        searchParams.put(XxinvConstants.URL_PARAM_ITEM_CLASS, itemClass);
//        searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);
        searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId);
        searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2");
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // 引数設定
        Serializable setParams[] = { searchParams };
        // initializeの引数型設定
        Class[] parameterTypes = { HashMap.class };

        // VO初期化処理
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//        am.invokeMethod("initializeHdr", setParams, parameterTypes);
        am.invokeMethod("initializeHdr", setParamsHd, parameterTypesHd);
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // 更新フラグがNULLの場合
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // 新規行追加処理
          am.invokeMethod("addRow");
        } else 
        {
          // 引数設定
          Serializable params[] = { searchHdrId };
          // 検索処理
          am.invokeMethod("doSearchHdr", params);

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
          // 検索処理
          am.invokeMethod("doSearchLine", setParams, parameterTypes);
// 2008/08/18 v1.2 Y.Yamamoto Mod End
        }
      }

    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else 
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510001J, true))
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

      // 処理フラグの取得
      String updateFlag  = pageContext.getParameter("ProcessFlag");

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
      // 前画面URL取得
      String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);
// 2008/08/18 v1.2 Y.Yamamoto Mod End

      // ********************************* //
      // *      取消ボタン押下時         * //
      // ********************************* //
      if (pageContext.getParameter("Cancel") != null)
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

// 2008/08/20 v1.2 Y.Yamamoto Mod Start
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
// 2008/08/20 v1.2 Y.Yamamoto Mod End
        // 入出庫実績要約画面へ
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ********************************* //
      // *      次へボタン押下時         * //
      // ********************************* //
      } else if (pageContext.getParameter("Next") != null)
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
// 2008/08/20 v1.6 Y.Yamamoto Mod Start
        // 変更に関する警告処理
        am.invokeMethod("doWarnAboutChanges");
// 2008/08/20 v1.6 Y.Yamamoto Mod End

        // 検索条件(移動ヘッダID)取得
        String searchMovHdrId = pageContext.getParameter("HdrId");

        // 次へチェック
// 2008-10-21 H.Itou Mod Start 統合テスト指摘353
        Serializable checkHdrParams[] = { "1" };
//        am.invokeMethod("checkHdr");
        am.invokeMethod("checkHdr", checkHdrParams);
// 2008-10-21 H.Itou Mod End

        // パレット枚数のチェック
        am.invokeMethod("chckPallet");

        // 稼動日チェック
        String returnCode = (String)am.invokeMethod("oprtnDayCheck");

        // ダイアログ作成
        if (!XxcmnConstants.STRING_TRUE.equals(returnCode))
        {
          // ダイアログメッセージを表示
          MessageToken[] tokens = new MessageToken[1];
          if ("1".equals(returnCode))
          {
            // エラーメッセージトークン取得
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          } else if ("2".equals(returnCode))
          {
            // エラーメッセージトークン取得
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          }
          // メインメッセージ作成
          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXINV
                                                    ,XxinvConstants.XXINV10058
                                                    ,tokens);
          //パラメータ用HashMap生成
          Hashtable pageParams = new Hashtable();
          // 検索条件(移動ヘッダID)取得
          pageParams.put("pHdrId", searchMovHdrId);

          // ダイアログ生成
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxinvConstants.URL_XXINV510001JL,
            XxinvConstants.URL_XXINV510001JH,
            "YES",
            "NO",
            "yesNextBtn",
            "noNextBtn",
            pageParams);
        }

        // パラメータ取得
        String peopleCode  = pageContext.getParameter("Peoplecode");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // ヘッダID
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);

        // ヘッダIDが入力されていた場合
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
        if (!XxcmnUtility.isBlankOrNull(searchMovHdrId))
        {
          //パラメータ用HashMap生成
          pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2");

// 2008/08/25 v1.2 Y.Yamamoto Mod Start
          HashMap searchParams = new HashMap();
          searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
          searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
          searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
          searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
          searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2");

          // 引数設定
          Serializable setParams[] = { searchParams };
          // initializeの引数型設定
          Class[] parameterTypes = { HashMap.class };

          // 検索処理
          am.invokeMethod("doLotSwitcher", setParams, parameterTypes);
// 2008/08/25 v1.2 Y.Yamamoto Mod End
        } else if (XxinvConstants.URL_XXINV510001JL.equals(prevUrl))
        { // 前の画面が明細画面のときは更新フラグをセット
          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "1");
        }
// 2008/08/18 v1.2 Y.Yamamoto Mod End

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

      // ダイアログYESボタン押下時
      } else if (pageContext.getParameter("yesNextBtn") != null)
      {
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();

        // パラメータ取得
        String searchMovHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // ヘッダID
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // 従業員区分
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // 実績データ区分
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // 製品識別区分
        // ダイアログ画面より明細画面へ遷移するため、パラメータ再設定
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
// 2008/08/18 v1.2 Y.Yamamoto Mod Start

        // ヘッダIDが入力されていた場合
//        if (!XxcmnUtility.isBlankOrNull(searchMovHdrId))
//        {
//          //パラメータ用HashMap生成
//          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2"); // 更新フラグ
//        }
        if (XxinvConstants.URL_XXINV510001JL.equals(prevUrl))
        { // 前の画面が明細画面のときは更新フラグをセット
          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "1");
        }
// 2008/08/18 v1.2 Y.Yamamoto Mod End


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

      // ダイアログNOボタン押下時
      } else if (pageContext.getParameter("noNextBtn") != null)
      {
        // 何も処理しない

      // ********************************* //
      // *      適用ボタン押下時         * //
      // ********************************* //
      } else if (pageContext.getParameter("Go") != null)
      {

        // 登録・更新時のチェック
// 2008-10-21 H.Itou Mod Start 統合テスト指摘353
        Serializable checkHdrParams[] = { "2" };
//        am.invokeMethod("checkHdr");
        am.invokeMethod("checkHdr", checkHdrParams);
// 2008-10-21 H.Itou Mod End

        // パレット枚数のチェック
        am.invokeMethod("chckPallet");

        // 稼動日チェック
        String returnCode = (String)am.invokeMethod("oprtnDayCheck");

        // ダイアログ作成
        if (!XxcmnConstants.STRING_TRUE.equals(returnCode))
        {
          // ダイアログメッセージを表示
          MessageToken[] tokens = new MessageToken[1];
          if ("1".equals(returnCode))
          {
            // エラーメッセージトークン取得
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          } else if ("2".equals(returnCode))
          {
            // エラーメッセージトークン取得
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          }
          // メインメッセージ作成
          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXINV
                                                    ,XxinvConstants.XXINV10058
                                                    ,tokens);
          //パラメータ用HashMap生成
          Hashtable pageParams = new Hashtable();
          // 検索条件(移動ヘッダID)取得
          String searchMovHdrId = pageContext.getParameter("HdrId");
          pageParams.put("pHdrId", searchMovHdrId);

          // ダイアログ生成
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxinvConstants.URL_XXINV510001JH,
            XxinvConstants.URL_XXINV510001JH,
            "YES",
            "NO",
            "yesBtn",
            "noBtn",
            pageParams);
        }

        // 更新処理(正常(更新有)：MovHdrId、正常(更新無)：TRUE、エラー：FALSE)
        String retCode = (String)am.invokeMethod("UpdateHdr");

        // 正常終了の場合、コミット処理
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;

          // 正常終了(更新有)の場合(MovHdrId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode))
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }

          //【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          // コミット
          am.invokeMethod("doCommit");

// 2008/09/24 H.Itou Add Start
          // ****************** //
          // * ヘッダVO再検索 * //
          // ****************** //
          String searchHdrId = pageContext.getParameter("HdrId");
          Serializable pDoSearchHdr[] = { searchHdrId }; // doSearchHdrの引数設定

          am.invokeMethod("doSearchHdr", pDoSearchHdr);  // ヘッダVO検索実行
// 2008/09/24 H.Itou Add End

          // 正常終了(更新有)の場合
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag))
          {
            // OA例外リストを生成します。
            ArrayList exceptions = new ArrayList(100);
// 2009-12-28 H.Itou Del Start 本稼動障害#695
//            // コンカレント：移動入出庫実績登録処理発行
//            HashMap retParams = new HashMap();
//            retParams = (HashMap)am.invokeMethod("doMovActualMake");
//
//            // コンカレントが正常終了した場合
//            if (XxcmnConstants.RETURN_SUCCESS.equals((String)retParams.get("retFlag")))
//            {
//              // メッセージトークン取得
//              MessageToken[] tokens = new MessageToken[2];
//              tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
//              tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID, retParams.get("requestId").toString());
//              exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
//                                              XxinvConstants.XXINV10006,
//                                              tokens,
//                                              OAException.INFORMATION,
//                                              null));
//  
//            }
// 2009-12-28 H.Itou Del End
            // 更新処理完了MSGを設定し、自画面遷移
            exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                   XxinvConstants.XXINV10158, 
                                   null, 
                                   OAException.INFORMATION, 
                                   null));
            // メッセージを出力し、処理終了
            if (exceptions.size() > 0)
            {
              OAException.raiseBundledOAException(exceptions);
            }
          }

        // 正常終了でない場合、ロールバック
        } else
        {
          //【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          am.invokeMethod("doRollBack");
        }
        
      // ********************************** //
      // *         新規作成の場合         * //
      // ********************************** //
      } else if (XxinvConstants.PROCESS_FLAG_I.equals(updateFlag))
      {
        // 出庫日(実績)が変更された場合
        if ("actualShipDate".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // コピー処理
          am.invokeMethod("copyActualShipDate");

        // 着日(実績)が変更された場合
        } else if ("actualArrivalDate".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // コピー処理
          am.invokeMethod("copyActualArrivalDate");

        // 運賃区分が変更された場合
        } else if ("frtChargeClass".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // 運賃区分取得
          String freightChargeClass = pageContext.getParameter("freightChargeClass");

          // 運賃区分がOFFの場合
          if (XxinvConstants.FREIGHT_CHARGE_CLASS_1.equals(freightChargeClass))
          {
            // クリア処理
            am.invokeMethod("clearValue");
    // mod start ver1.1
//          } else
//          {
            // 運送業者入力制御処理
//            am.invokeMethod("inputFreightCarrier");
    // mod end ver1.1
          }

        }

      // ********************************** //
      // *           更新の場合           * //
      // ********************************** //
      } else if (XxinvConstants.PROCESS_FLAG_U.equals(updateFlag))
      {
        // 運賃区分が変更された場合
        if ("frtChargeClass".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // クリア処理
          am.invokeMethod("clearValue");
        }
      }

    // 例外が発生した場合
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
    
  }

}
