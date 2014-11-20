/*============================================================================
* ファイル名 : XxpoInspectLotRegistCO
* 概要説明   : 検査ロット:登録コントローラ
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者        修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  戸谷田 大輔    新規作成
* 2008-05-09 1.1  熊本 和郎      内部変更要求#28,41,43対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370002j.webui;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
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
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;

import oracle.jbo.domain.Number;
import java.sql.SQLException;

/***************************************************************************
 * 検査ロット:登録コントローラクラスです。
 * @author  ORACLE 戸谷田 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoInspectLotRegistCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistCO.java,v 1.11 2008/02/22 08:23:38 usr3149 Exp $";
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

    // 戻るボタンの判定に使用する。
    if (!pageContext.isBackNavigationFired(false))
    {
      // トランザクション開始
      TransactionUnitHelper.startTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370002J);

      // 変数定義
      String paramLotId = null;
      Number lotId = null;
      HashMap map = new HashMap();
      // 適用ボタン取得
      OASubmitButtonBean applyButton =
        (OASubmitButtonBean)webBean.findChildRecursive("Apply");

      // パラメータの取得
      paramLotId = pageContext.getParameter("pSearchLotId");
      if (!XxcmnUtility.isBlankOrNull(paramLotId))
      {
        try
        {
          lotId = new Number(paramLotId);
        } catch (SQLException expt)
        {
          // 不正なパラメータが渡ってきた場合。
          // 適用ボタンを使用不可にする
          applyButton.setDisabled(true);
          // メッセージの出力
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
        }
      } 
      
      // アプリケーションモジュールの取得
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // 取引先
      OAMessageLovInputBean lovAttribute8 =
        (OAMessageLovInputBean)webBean.findChildRecursive("Attribute8");
      // 品目
      OAMessageLovInputBean lovItemNo =
        (OAMessageLovInputBean)webBean.findChildRecursive("ItemNo");
      // 賞味期限
      OAMessageDateFieldBean inputAttribute3 =
        (OAMessageDateFieldBean)webBean.findChildRecursive("Attribute3");

      // 引数の設定(初期表示処理)
      Serializable[] params = { lotId };
      Class[] paramTypes = { Number.class };
      
      try
      {
        // 初期表示処理
        map = (HashMap)am.invokeMethod("initQuery", params, paramTypes);
      } catch (OAException expt)
      {
        // 適用ボタンを使用不可にする
        applyButton.setDisabled(true);
        // メッセージの出力
        throw expt;
      }

      // 内部ユーザで更新の場合、取引先と品目を固定する。
      if (("1".equals((String)map.get("PeopleCode")) &&
            (!XxcmnUtility.isBlankOrNull(lotId))))
      {
        // 取引先
        lovAttribute8.setReadOnly(true);
        lovAttribute8.setCSSClass("OraDataText");
        // 品目
        lovItemNo.setReadOnly(true);
        lovItemNo.setCSSClass("OraDataText");        
      }

      // 外部ユーザ、かつ新規の場合、取引先を固定し賞味期限を編集不可にする。
      if (("2".equals((String)map.get("PeopleCode")) &&
           (XxcmnUtility.isBlankOrNull(lotId))))
      {
        // 取引先
        lovAttribute8.setReadOnly(true);
        lovAttribute8.setCSSClass("OraDataText");
        // 賞味期限
        inputAttribute3.setReadOnly(true);
        inputAttribute3.setCSSClass("OraDataText");

      // 外部ユーザ、かつ更新の場合、取引先、品目、賞味期限を編集不可にする。
      } else if (("2".equals((String)map.get("PeopleCode")) &&
                    (!XxcmnUtility.isBlankOrNull(lotId))))
      {
        // 取引先
        lovAttribute8.setReadOnly(true);
        lovAttribute8.setCSSClass("OraDataText");
        // 品目
        lovItemNo.setReadOnly(true);
        lovItemNo.setCSSClass("OraDataText");        
        // 賞味期限
        inputAttribute3.setReadOnly(true);
        inputAttribute3.setCSSClass("OraDataText");
        
      }      
// add start 1.1
      // 完了メッセージ取得
      String mainMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_MAIN_MESSAGE);
      if (!XxcmnUtility.isBlankOrNull(mainMessage)) 
      {
        // メッセージボックス表示
        pageContext.putDialogMessage(new OAException(mainMessage, OAException.INFORMATION));
      }
// add end 1.1

    }else
    {
      // トランザクションチェック
      if (!TransactionUnitHelper.isTransactionUnitInProgress(
            pageContext, XxpoConstants.TXN_XXPO370002J, true))
      {
        // 戻るボタンが押された場合
        OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
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
    super.processFormRequest(pageContext, webBean);

    // 変数定義
    String lotNo = null;
    Number itemId = null;
    Number lotId = null;
    Number reqNo = null;

    // 例外格納用リスト定義
    List exptArray = new ArrayList();

    // パラメータの設定
    HashMap map = new HashMap();

    // アプリケーションモジュールの取得
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
// add start 1.1
    try
    {
// add end 1.1

// del start 1.1
//    // 適用ボタン取得(制御用)
//    OASubmitButtonBean applyButton =
//        (OASubmitButtonBean)webBean.findChildRecursive("Apply");
// del end 1.1

    // 「適用」ボタン押下時
    if (pageContext.getParameter("Apply") != null)
    {
// add start 1.1
      // メッセージの初期化
      pageContext.removeParameter(XxpoConstants.URL_PARAM_MAIN_MESSAGE);
// add end 1.1
      // 必須入力チェック
      am.invokeMethod("inputCheck");

      // 存在チェック
// del start 1.1
//      am.invokeMethod("existCheck");
// del end 1.1
      // ロットNoの取得
      lotNo = pageContext.getParameter("HiddenLotNo");      
      // 更新の場合
      if (!XxcmnUtility.isBlankOrNull(lotNo))
      {
        try
        {
          List list = (List)am.invokeMethod("doUpdate");
          OAException oae = OAException.getBundledOAException(list);
          pageContext.putDialogMessage(oae);

          String pLotId = (String)pageContext.getParameter("LotId");
          map.put("pSearchLotId", pLotId);

          // トランザクション終了
          TransactionUnitHelper.endTransactionUnit(
            pageContext, XxpoConstants.TXN_XXPO370002J);
          pageContext.forwardImmediatelyToCurrentPage(
            map, true, OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        } catch (OAException oae2)
        {

          // トランザクション終了
          TransactionUnitHelper.endTransactionUnit(
            pageContext, XxpoConstants.TXN_XXPO370002J);

          // エラーメッセージの設定
          pageContext.putDialogMessage(oae2);
        }
        
      // 新規の場合
      } else
      {
// del start 1.1
//        try
//        {
// del end 1.1
          // ロット情報、品質検査依頼情報作成処理呼び出し
          List result = (List)am.invokeMethod("doInsert");
          map.put("pSearchLotId", result.get(0));

          // メッセージをリストに追加
          // ロット情報作成成功メッセージ
// mod start 1.1
//          MessageToken[] tokens = {
//            new MessageToken("PROCESS",
//                             XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };

//          exptArray.add(new OAException(
//                          XxcmnConstants.APPL_XXCMN,
//                          XxcmnConstants.XXCMN05001,
//                          tokens,
//                          OAException.INFORMATION,
//                          null));
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS, XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };
          map.put(
            XxpoConstants.URL_PARAM_MAIN_MESSAGE,
            pageContext.getMessage(XxcmnConstants.APPL_XXCMN,
                                   XxcmnConstants.XXCMN05001,
                                   tokens));
// mod end 1.1

          if (result.size() > 1) 
          {
            // 品質検査依頼情報作成成功メッセージ
            MessageToken[] tokens2 =
              { new MessageToken("PROCESS",
                                 XxpoConstants.TOKEN_NAME_CREATE_QT_INSPECTION) };

            exptArray.add(new OAException(
                            XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN05001,
                            tokens2,
                            OAException.INFORMATION,
                            null));
          }
          // トランザクション終了
          TransactionUnitHelper.endTransactionUnit(
            pageContext, XxpoConstants.TXN_XXPO370002J);

          // 同一画面へ遷移
// mod start 1.1
//          pageContext.putDialogMessage(
//            OAException.getBundledOAException(exptArray));

//          pageContext.forwardImmediately(
//            "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG",
//            null,
//            OAWebBeanConstants.KEEP_MENU_CONTEXT,
//            null,
//            map,
//            true, // ratain AM
//            OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
          pageContext.setForwardURL(
            XxpoConstants.URL_XXPO370002J,
            null,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            map,
            false, // Retain AM
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
            OAWebBeanConstants.IGNORE_MESSAGES);    
// mod end 1.1

// del start 1.1
/*
        } catch (OAException oae)
        {
          map.put("pSearchLotId", null);
          exptArray.add(oae);

          // エラーメッセージの設定
          pageContext.putDialogMessage(
            OAException.getBundledOAException(exptArray));
        }
*/
// del end 1.1
      }

    // 「取消」ボタン押下時
    }else if (pageContext.getParameter("Cancel") != null)
    {
      // トランザクション終了
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370002J);
// add start 1.1
      // ロットNoの取得
      lotNo = pageContext.getParameter("HiddenLotNo");      
      boolean isRetainAM = true;
      if (XxcmnUtility.isBlankOrNull(lotNo)) 
      {
        // 新規の場合
        isRetainAM = false;
      }
// add end 1.1
      // ************************* //
      // * 検査ロット情報検索画面へ * //
      // ************************* //
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchPG",
        XxpoConstants.URL_XXPO370001J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
// mod start 1.1
//        false, // retain AM
        isRetainAM,
// mod end 1.1
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);

    // 製造日/仕入日が変更された場合
    } else if ("ProductDateChanged".equals(
                pageContext.getParameter(EVENT_PARAM)))
    {
      // 賞味期限を算出
      am.invokeMethod("getBestBeforeDate");

    // =============================== //
    // =    値リストが起動した場合      = //
    // =============================== //
    } else if (pageContext.isLovEvent())
    {
      // イベント発生LOVの取得
      String lovInputSourceId = pageContext.getLovInputSourceId();
      
      // 品目の場合
      if ("ItemNo".equals(lovInputSourceId))
      {
        if (!XxcmnUtility.isBlankOrNull(
              pageContext.getParameter("Attribute1")))
        {
          // 賞味期限を算出
          am.invokeMethod("getBestBeforeDate");
        }
      }
    }
// add start 1.1
    // 例外が発生した場合  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
// add end 1.1

  }
}
