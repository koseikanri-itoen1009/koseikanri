/*============================================================================
* ファイル名 : XxpoVendorSupplyMakeCO
* 概要説明   : 外注出来高報告:登録コントローラ
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-08 1.0  伊藤 ひとみ   新規作成
* 2008-05-07      伊藤 ひとみ   変更要求対応(#86,90)、内部変更要求対応(#28,29,41)
* 2016-05-11 1.1  山下 翔太     E_本稼動_13563対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

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
 * 出来高実績報告:登録コントローラクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyMakeCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

      // AMの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
      // ********************************* //
      // *      適用ボタン押下時         * //
      // ********************************* //
      if (pageContext.getParameter("Go") != null)
      {
        // 処理は行わない。画面を再表示

      // ********************************* //
      // * ダイアログ画面「Yes」押下時   * //
      // ********************************* //       
      } else if (pageContext.getParameter("Yes") != null) 
      {
          // 登録・更新処理
          String ret = (String)am.invokeMethod("mainProcess");        

          // 正常終了の場合
          if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
            
            // コミット
            am.invokeMethod("doCommit");
            // 終了処理
            am.invokeMethod("doEndOfProcess");

          // 正常終了でない場合、ロールバック
          } else
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

            // ロールバック
            am.invokeMethod("doRollBack");
          }        
      // ********************************* //
      // * ダイアログ画面「No」押下時    * //
      // ********************************* //
      } else if (pageContext.getParameter("No") != null) 
      {
        // 処理は行わない。画面を再表示

      // ********************************* //
      // *      前画面からの遷移時       * //
      // ********************************* //
      } else
      {
        // 前画面の値取得
        String searchTxnsId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_TXNS_ID); // 実績ID
        String updateFlag = pageContext.getParameter(XxpoConstants.URL_PARAM_UPDATE_FLAG); // 更新フラグ

        // VO初期化処理
        am.invokeMethod("initializeMake");

        // 更新フラグがNULLの場合
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // 新規行追加処理
          am.invokeMethod("addRow");        
        } else
        {
          // 引数設定
          Serializable params[] = { searchTxnsId };
          // 検索処理
          am.invokeMethod("doSearch", params);        
        }
      }
      
    // 【共通処理】ブラウザ「戻る」ボタンチェック　戻るボタンを押下した場合
    } else
    {
      // 【共通処理】トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO340001J, true))
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
    // AMの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    try
    {
      super.processFormRequest(pageContext, webBean);

      // ********************************* //
      // *      取消ボタン押下時         * //
      // ********************************* //
      if (pageContext.getParameter("Cancel") != null) 
      {
        // 【共通処理】トランザクション終了
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
        
        String updateFlag = pageContext.getParameter(XxpoConstants.URL_PARAM_UPDATE_FLAG); // 更新フラグ
        
        boolean retainAm = true;
        // 更新フラグがNULLの場合(新規の場合)
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // 画面内容を保持しない。
          retainAm = false;
        }
        // 外注出来高実績検索画面へ
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO340001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          retainAm, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // ********************************* //
      // *      適用ボタン押下時         * //
      // ********************************* //
      } else if (pageContext.getParameter("Go") != null) 
      {
        // 登録・更新チェック処理
        HashMap hashMapRet = (HashMap)am.invokeMethod("allCheck");
        // 戻り値取得
        String plSqlRet = (String)hashMapRet.get("PlSqlRet");

        // チェックが警告終了の場合
        if (XxcmnConstants.RETURN_WARN.equals(plSqlRet))
        {
          // 【共通処理】トランザクション終了
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);
        
          // トークン生成
          String itemName     = (String)hashMapRet.get("ItemName");
          String lotNumber    = (String)hashMapRet.get("LotNumber");
          String locationName = (String)hashMapRet.get("LocationName");
          MessageToken[] tokens = new MessageToken[3];
          tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, locationName); // 保管場所
          tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     itemName);     // 品目
          tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      lotNumber);    // ロット番号
          // メインメッセージ作成
          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXCMN,
                                                    XxcmnConstants.XXCMN10112,
                                                    tokens);
          // ダイアログメッセージを表示
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxpoConstants.URL_XXPO340001JM,
            XxpoConstants.URL_XXPO340001JM,
            "Yes",
            "No",
            "Yes",
            "No",
            null);
            
        // チェックが正常終了の場合
        } else
        {
          String ret = (String)am.invokeMethod("mainProcess");

          // 正常終了の場合、コミット処理
          if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

            // コミット
            am.invokeMethod("doCommit");

            // コンカレント：標準発注インポート発行
            ret = (String)am.invokeMethod("doImportPo");

            // 正常終了の場合、終了処理
            if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
            {        
              // 終了処理
              am.invokeMethod("doEndOfProcess");
            }

          // 正常終了でない場合、ロールバック
          } else
          {
            // 【共通処理】トランザクション終了
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO340001J);

            am.invokeMethod("doRollBack");
          }
        } 

      // ********************************* //
      // *      値リスト変更時           * //
      // ********************************* //
      } else if (pageContext.isLovEvent())
      {

        String lovInputSourceId = pageContext.getLovInputSourceId();// イベント発生LOV名

        // 取引先変更時
        if ("TxtVendorCode".equals(lovInputSourceId))
        {
          // 取引先変更時処理
          am.invokeMethod("vendorCodeChanged"); 

        // 工場変更時
        } else if ("TxtFactoryCode".equals(lovInputSourceId))
        {
          // 工場変更時処理
          am.invokeMethod("factoryCodeChanged"); 

        // 品目変更時
        } else if ("TxtItemCode".equals(lovInputSourceId))
        {
          // 品目変更時処理
          am.invokeMethod("itemCodeChanged"); 
        }
    
      // ********************************* //
      // *      生産日変更時             * //
      // ********************************* //
      } else if ("ManufacturedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 生産日変更時処理
        am.invokeMethod("manufacturedDateChanged");  

      // ********************************* //
      // *      製造日変更時             * //
      // ********************************* //
      } else if ("ProductedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 製造日変更時処理
        am.invokeMethod("productedDateChanged");  
 
      }
// 2016-05-11 v1.1 S.Yamashita Add Start
      else if ("ChangedUseByDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // 変更賞味期限変更時処理
        am.invokeMethod("changedUseByDateChanged");
      }
// 2016-05-11 v1.1 S.Yamashita Add End

    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
      am.invokeMethod("doRollBack");
    }
  }
}
