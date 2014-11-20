/*============================================================================
* ファイル名 : XxinvMovementResultsLnCO
* 概要説明   : 入出庫実績明細:検索コントローラ
* バージョン : 1.7
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-18 1.0  大橋孝郎     新規作成
* 2008-06-11 1.2  大橋孝郎     不具合指摘事項修正
* 2008-06-18 1.3  大橋孝郎     不具合指摘事項修正
* 2008-08-18 1.4  山本恭久     内部変更#157対応、ST#249対応
* 2008-09-24 1.5  伊藤ひとみ   内部変更#157バグ修正
* 2009-02-26 1.6  二瓶大輔     本番障害#855対応
* 2009-12-28 1.7  伊藤ひとみ   本稼動障害#695
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.webui;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

import java.io.Serializable;

import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.domain.Number;

/***************************************************************************
 * 入出庫実績明細:検索コントローラです。
 * @author  ORACLE 大橋 孝郎
 * @version 1.7
 ***************************************************************************
 */
public class XxinvMovementResultsLnCO extends XxcmnOAControllerImpl
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
      // 【共通処理】ブラウザ「戻る」ボタンチェック　トランザクション作成
      TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // 前画面URL取得
      String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);

// mod start ver1.3
//      // 前画面が出庫ロット明細、入庫ロット明細以外の場合、初期化を実施
//      if (!XxinvConstants.URL_XXINV510002J_1.equals(prevUrl)
//             && !XxinvConstants.URL_XXINV510002J_2.equals(prevUrl))
//      {
      // 前画面の値取得
      String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // 従業員区分
      String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // 実績データ区分
      String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG);  // 製品識別区分
      String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // ヘッダID
      String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG);   // 更新フラグ

      // パラメータ用HashMap設定
      HashMap searchParams = new HashMap();
      searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,    peopleCode);
      searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,    actualFlag);
      searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,   productFlag);
      searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID,  searchHdrId);
      searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,    updateFlag);

// 2008/08/18 v1.4 Y.Yamamoto Mod Start
      // 商品区分の取得
      String itemClass  = pageContext.getProfile("XXCMN_ITEM_DIV_SECURITY");

      // パラメータ用HashMap設定
      HashMap searchParamsHd = new HashMap();
      searchParamsHd.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,  peopleCode);
      searchParamsHd.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,  actualFlag);
      searchParamsHd.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
      searchParamsHd.put(XxinvConstants.URL_PARAM_ITEM_CLASS,   itemClass);
      searchParamsHd.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,  updateFlag);

      // 引数設定
      Serializable setParamsHd[] = { searchParamsHd };
      // initializeの引数型設定
      Class[] parameterTypesHd = { HashMap.class };
// 2008/08/18 v1.4 Y.Yamamoto Mod End

      // 引数設定
      Serializable setParams[] = { searchParams };
      // initializeの引数型設定
      Class[] parameterTypes = { HashMap.class };

      // 適用ボタン押下時
      if (pageContext.getParameter("Go") != null)
      {
        // 何も処理しない
// 2008/09/24 v1.5 H.Itou Del Start エラーの場合も検索してしまうのでprocessFormRequestで再検索を行う。
//// 2008/08/18 v1.4 Y.Yamamoto Mod Start
//        // 引数設定
//        // VO初期化処理
//        am.invokeMethod("initializeHdr", setParamsHd, parameterTypesHd);
//        Serializable paramsHd[] = { searchHdrId };
//        // 検索処理
//        am.invokeMethod("doSearchHdr", paramsHd);
//
//        // VO初期化処理
//        am.invokeMethod("initializeLine", setParams, parameterTypes);
//        // 検索処理
//        am.invokeMethod("doSearchLine", setParams, parameterTypes);
//// 2008/08/18 v1.4 Y.Yamamoto Mod End
// 2008/09/24 v1.5 H.Itou Del End
// 2009-02-26 v1.6 D.Nihei Add Start 本番障害#855対応 削除処理追加
      // ******************************************************* //
      // 削除アイコン・削除Yesボタン・Noボタンが押下された場合 * //
      // ******************************************************* //
      } else if ("deleteLine".equals(pageContext.getParameter(EVENT_PARAM))
              || pageContext.getParameter("deleteYesBtn") != null
              || pageContext.getParameter("deleteNoBtn")  != null)
      {
        // 何もしない
// 2009-02-26 v1.6 D.Nihei Add End
      } else
      {
        // VO初期化処理
// 2008/08/18 v1.4 Y.Yamamoto Mod Start
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // 更新フラグがNULLの場合、VO初期化処理
          am.invokeMethod("initializeLine", setParams, parameterTypes);
        }
// 2008/08/18 v1.4 Y.Yamamoto Mod End
      }

// 2008/08/18 v1.4 Y.Yamamoto Mod Start
//      // 更新フラグがNULL以外の場合
//      if (!XxcmnUtility.isBlankOrNull(updateFlag))
//      {
//        // 検索処理
//        am.invokeMethod("doSearchLine", setParams, parameterTypes);
//      }
// 2008/08/18 v1.4 Y.Yamamoto Mod End
//      }
// mod start ver1.3
// 2008/08/26 v1.4 Y.Yamamoto Mod Start
      // 前画面が出庫ロット明細、入庫ロット明細の場合、再検索を実施
      if (XxinvConstants.URL_XXINV510002J_1.equals(prevUrl)
       || XxinvConstants.URL_XXINV510002J_2.equals(prevUrl))
      {
        // VO初期化処理
        am.invokeMethod("initializeHdr", setParamsHd, parameterTypesHd);
        Serializable paramsHd[] = { searchHdrId };
        // 検索処理
        am.invokeMethod("doSearchHdr", paramsHd);

        // VO初期化処理
        am.invokeMethod("initializeLine", setParams, parameterTypes);
        // 検索処理
        am.invokeMethod("doSearchLine",   setParams, parameterTypes);
      }
// 2008/08/26 v1.4 Y.Yamamoto Mod Start

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

      // ******************************** //
      // *       取消ボタン押下時       * //
      // ******************************** //
      if (pageContext.getParameter("Cancel") != null)
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

// 2008/08/20 v1.4 Y.Yamamoto Mod Start
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
// 2008/08/20 v1.4 Y.Yamamoto Mod End
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

      // ******************************** //
      // *       戻るボタン押下時       * //
      // ******************************** //
      } else if (pageContext.getParameter("Back") != null)
      {
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // 従業員区分
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // 実績データ区分
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG);  // 製品識別区分
        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // ヘッダID
        String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG);   // 更新フラグ

        // パラメータ用HashMap設定
        HashMap searchParams = new HashMap();
        searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID,  searchHdrId);
        searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,    peopleCode);
        searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,    actualFlag);
        searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,   productFlag);
        searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,    updateFlag);
        searchParams.put(XxinvConstants.URL_PARAM_PREV_URL,       XxinvConstants.URL_XXINV510001JL);
        
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
        // 入出庫実績ヘッダ画面へ
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          searchParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ******************************** //
      // *       適用ボタン押下時       * //
      // ******************************** //
      } else if (pageContext.getParameter("Go") != null)
      {
        // 登録・更新時のチェック(品目重複チェック)
        am.invokeMethod("checkLine");

        // 登録・更新処理(正常(更新有)：MovHdrId、正常(更新無)：TRUE、エラー：FALSE)
        String retCode = (String)am.invokeMethod("doExecute");

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
//              tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID,      retParams.get("requestId").toString());
//              exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
//                                                XxinvConstants.XXINV10006,
//                                                tokens,
//                                                OAException.INFORMATION,
//                                                null));
//            }
// 2009-12-28 H.Itou Del End
            // 登録完了MSGを設定し、自画面遷移
            exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                   XxinvConstants.XXINV10161, 
                                   null, 
                                   OAException.INFORMATION, 
                                   null));

// 2008/09/24 v1.5 H.Itou Add Start エラーの場合も検索してしまうのでprocessFormRequestで再検索を行う。
            // ****************************** //
            // *       パラメータ取得       * //
            // ****************************** //
            String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);  // 従業員区分
            String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);  // 実績データ区分
            String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // 製品識別区分
            Number searchHdrId = (Number)am.invokeMethod("getHdrId");// ヘッダID
            String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG);  // 更新フラグ

            // AM引数型設定
            Class[] pTypeHashMap   = { HashMap.class }; // 引数型設定(HashMap)
      
            // ****************************** //
            // *  ヘッダVO初期化・検索処理  * //
            // ****************************** //
            // 商品区分の取得
            String itemClass = pageContext.getProfile("XXCMN_ITEM_DIV_SECURITY");
            
            HashMap pHdr = new HashMap(); // initializeHdrの引数
            pHdr.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,  peopleCode);
            pHdr.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,  actualFlag);
            pHdr.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
            pHdr.put(XxinvConstants.URL_PARAM_ITEM_CLASS,   itemClass);
            pHdr.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,  updateFlag);

            Serializable pInitializeHdr[] = { pHdr }; // initializeHdrの引数設定
            Serializable pDoSearchHdr[] = { searchHdrId.toString() }; // doSearchHdrの引数設定
            
            am.invokeMethod("initializeHdr", pInitializeHdr, pTypeHashMap); // ヘッダVO初期化実行
            am.invokeMethod("doSearchHdr",   pDoSearchHdr);  // ヘッダVO検索処理

            // ****************************** //
            // *  明細VO初期化・検索処理    * //
            // ****************************** //
            // パラメータ用HashMap設定
            HashMap pLine = new HashMap(); // initializeLine/doSearchLineの引数
            pLine.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,   peopleCode);
            pLine.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,   actualFlag);
            pLine.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,  productFlag);
            pLine.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId.toString());
            pLine.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,   updateFlag);

            Serializable pInitializeLine[] = { pLine }; // initializeLineの引数設定
            Serializable pdoSearchLine[]   = { pLine }; // doSearchLineの引数設定
            
            am.invokeMethod("initializeLine", pInitializeLine, pTypeHashMap); // 明細VO初期化実行
            am.invokeMethod("doSearchLine",   pdoSearchLine,   pTypeHashMap);     // 明細VO検索実行
// 2008/09/24 v1.5 H.Itou Add End

            // メッセージを出力し、処理終了
            if (exceptions.size() > 0)
            {
// 2008/09/24 v1.5 H.Itou Del Start VO再検索時に取得するため不要
//              try
//              {
// 2008/09/24 v1.5 H.Itou Del End
              OAException.raiseBundledOAException(exceptions);
// 2008/09/24 v1.5 H.Itou Del Start VO再検索時に取得するため不要
//              } catch(OAException oe)
//              {
//                String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // 従業員区分
//                String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // 実績データ区分
//                String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // 製品識別区分
//                String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG); // 更新フラグ
//
//                // パラメータ用HashMap設定
//                HashMap searchParams = new HashMap();
//                searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
//                searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
//                searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
//                searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, am.invokeMethod("getHdrId"));
//                searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, XxinvConstants.PROCESS_FLAG_U);
//
//                pageContext.putDialogMessage(oe);
//
//                pageContext.forwardImmediatelyToCurrentPage(
//                  searchParams,
//                  true,
//                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
//              }
// 2008/09/24 v1.5 H.Itou Del End
            }
          }

        // 正常終了でない場合、ロールバック
        } else
        {
          //【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          am.invokeMethod("doRollBack");
        }

      // ******************************** //
      // *      行挿入ボタン押下時      * //
      // ******************************** //
      } else if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("addRowLine");
// 2008/08/20 v1.4 Y.Yamamoto Mod Start
        // 変更に関する警告を設定
         am.invokeMethod("setWarnAboutChanges");  
// 2008/08/20 v1.4 Y.Yamamoto Mod End

      // ********************************** //
      // *  出庫ロット明細アイコン押下時  * //
      // ********************************** //
      } else if ("shippedLot".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
// 2008/08/20 v1.4 Y.Yamamoto Mod Start
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
// 2008/08/20 v1.4 Y.Yamamoto Mod End
        // 移動明細ID取得
        String movLineId   = pageContext.getParameter("MOV_LINE_ID");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
        String peoplecode  = pageContext.getParameter("Peoplecode");
        String hdrId       = pageContext.getParameter("HdrId");
        String updateFlag  = pageContext.getParameter("Update");

        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID, movLineId);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,        actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,       productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,        peoplecode);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID,      hdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,        updateFlag);
        // 出庫ロット詳細画面へ遷移
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510002J_1,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ********************************** //
      // *  入庫ロット明細アイコン押下時  * //
      // ********************************** //
      } else if ("shipToLot".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
// 2008/08/20 v1.4 Y.Yamamoto Mod Start
        // 変更に関する警告クリア処理実行
        am.invokeMethod("clearWarnAboutChanges");
// 2008/08/20 v1.4 Y.Yamamoto Mod End
        // 移動明細ID取得
        String movLineId   = pageContext.getParameter("MOV_LINE_ID");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
        String peoplecode  = pageContext.getParameter("Peoplecode");
        String hdrId       = pageContext.getParameter("HdrId");
        String updateFlag  = pageContext.getParameter("Update");
        //パラメータ用HashMap生成
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID, movLineId);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,        actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,       productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,        peoplecode);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID,      hdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,        updateFlag);
        // 出庫ロット詳細画面へ遷移
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510002J_2,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);
// 2009-02-26 v1.6 D.Nihei Add Start 本番障害#855対応 削除処理追加
      // ********************************** //
      // *  削除アイコン押下時            * //
      // ********************************** //
      } else if ("deleteLine".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        //パラメータ用HashMap生成
        Hashtable pageParams = new Hashtable();
        // 各種情報取得
        String movLineId   = pageContext.getParameter("DEL_MOV_LINE_ID");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
        String peoplecode  = pageContext.getParameter("Peoplecode");
        String hdrId       = pageContext.getParameter("HdrId");
        String updateFlag  = pageContext.getParameter("Update");

        // 各種情報設定
        pageParams.put(XxinvConstants.URL_PARAM_DEL_MOV_LINE_ID, movLineId);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,     actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,    productFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,     peoplecode);
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID,   hdrId);
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,     updateFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PREV_URL,        XxinvConstants.URL_XXINV510001JL);

        // 引数設定
        Serializable param[] = { movLineId };
        // 削除処理
        am.invokeMethod("chkDeleteLine", param);

        // ダイアログメッセージを表示
        // メインメッセージ作成
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXINV,
                                                  XxinvConstants.XXINV40001);
        // ダイアログ生成
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxinvConstants.URL_XXINV510001JL,
          XxinvConstants.URL_XXINV510001JL,
          "Yes",
          "No",
          "deleteYesBtn",
          "deleteNoBtn",
          pageParams);

      // ********************************** //
      // 削除Yesボタンが押下された場合    * //
      // ********************************** //
      } else if (pageContext.getParameter("deleteYesBtn") != null) 
      {
        // ****************************** //
        // *       パラメータ取得       * //
        // ****************************** //
        String movLineId   = pageContext.getParameter(XxinvConstants.URL_PARAM_DEL_MOV_LINE_ID); // 移動明細ID
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);     // 従業員区分
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);     // 実績データ区分
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG);    // 製品識別区分
        Number searchHdrId = (Number)am.invokeMethod("getHdrId");                                // ヘッダID
        String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG);     // 更新フラグ
        String itemClass   = pageContext.getProfile("XXCMN_ITEM_DIV_SECURITY");                  // 商品区分

        // ****************************** //
        // *  ヘッダVO初期化・検索処理  * //
        // ****************************** //
        HashMap pHdr = new HashMap(); // initializeHdrの引数
        pHdr.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,  peopleCode);
        pHdr.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,  actualFlag);
        pHdr.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        pHdr.put(XxinvConstants.URL_PARAM_ITEM_CLASS,   itemClass);
        pHdr.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,  updateFlag);

        // ****************************** //
        // *  明細VO初期化・検索処理    * //
        // ****************************** //
        // パラメータ用HashMap設定
        HashMap pLine = new HashMap(); // initializeLine/doSearchLineの引数
        pLine.put(XxinvConstants.URL_PARAM_PEOPLE_CODE,   peopleCode);
        pLine.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,   actualFlag);
        pLine.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,  productFlag);
        pLine.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId.toString());
        pLine.put(XxinvConstants.URL_PARAM_UPDATE_FLAG,   updateFlag);

        // 引数設定
        Serializable param[] = { movLineId, pHdr, pLine };
        // AM引数型設定
        Class[] paramTypes   = { String.class, HashMap.class, HashMap.class }; // 引数型設定(HashMap)
        // 削除処理
        am.invokeMethod("doDeleteLine", param, paramTypes);

// 2009-02-26 v1.6 D.Nihei Add End
      }

    // 例外が発生した場合
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
    
  }

}
